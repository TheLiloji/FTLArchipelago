"""Fake TrapLink client for testing FTL Archipelago without a second game. Python 3 stdlib only.

python traplink_helper.py <slot name> [host:port]

It joins the slot as an FTL client with the TrapLink tag, answers the FTL hello, and prints every Bounce it gets.
Commands typed while it runs:
  pact <slot number>   send "Archipelago Deal" to that slot alone (like another FTL would)
  trap <name>          send a TrapLink trap to the whole link as another game would (e.g. trap Ice Trap)
  quiet                stop answering the FTL hello (the FTL then sees no FTL partner)
  quit
"""
import base64, json, os, socket, struct, sys, threading, time

name = sys.argv[1]
host, _, port = (sys.argv[2] if len(sys.argv) > 2 else "127.0.0.1:38281").partition(":")
GAMES = ["FTL: Faster Than Light", "FTL Multiverse"]
sock = socket.create_connection((host, int(port or 38281)))
key = base64.b64encode(os.urandom(16)).decode()
sock.sendall(("GET / HTTP/1.1\r\nHost: %s\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n"
              "Sec-WebSocket-Key: %s\r\nSec-WebSocket-Version: 13\r\n\r\n" % (host, key)).encode())
buf = b""
while b"\r\n\r\n" not in buf:
    buf += sock.recv(4096)
buf = buf.split(b"\r\n\r\n", 1)[1]
lock = threading.Lock()
state = {"slot": None, "quiet": False}


def log(text):
    print(time.strftime("%H:%M:%S"), text, flush=True)


def send(obj, opcode=1):
    data = json.dumps([obj]).encode() if opcode == 1 else obj
    mask = os.urandom(4)
    n = len(data)
    if n < 126:
        head = bytes([0x80 | opcode, 0x80 | n])
    elif n < 65536:
        head = bytes([0x80 | opcode, 0xFE]) + struct.pack(">H", n)
    else:
        head = bytes([0x80 | opcode, 0xFF]) + struct.pack(">Q", n)
    with lock:
        sock.sendall(head + mask + bytes(c ^ mask[i % 4] for i, c in enumerate(data)))


def need(n):
    global buf
    while len(buf) < n:
        chunk = sock.recv(65536)
        if not chunk:
            log("connection closed")
            os._exit(0)
        buf += chunk


def frame():
    global buf
    need(2)
    op, n, o = buf[0] & 15, buf[1] & 127, 2
    if n == 126:
        need(4); n = struct.unpack(">H", buf[2:4])[0]; o = 4
    elif n == 127:
        need(10); n = struct.unpack(">Q", buf[2:10])[0]; o = 10
    need(o + n)
    payload, buf = buf[o:o + n], buf[o + n:]
    return op, payload


def reader():
    while True:
        op, payload = frame()
        if op == 9:
            send(payload, opcode=10)
            continue
        if op != 1:
            continue
        for msg in json.loads(payload):
            cmd = msg.get("cmd")
            if cmd == "RoomInfo":
                send({"cmd": "Connect", "password": "", "name": name, "uuid": name, "game": GAMES[0],
                      "version": {"major": 0, "minor": 6, "build": 7, "class": "Version"},
                      "tags": ["TrapLink"], "items_handling": 0, "slot_data": False})
            elif cmd == "Connected":
                state["slot"] = msg["slot"]
                log("%s connected, slot %d. Players: %s" % (name, msg["slot"], ", ".join(
                    "%d=%s" % (p["slot"], p["name"]) for p in msg.get("players", []))))
                send({"cmd": "Bounce", "games": GAMES,
                      "data": {"source": name, "slot": msg["slot"], "ftl_traplink": "hello"}})
            elif cmd == "ConnectionRefused":
                log("refused: %s" % msg.get("errors"))
                os._exit(1)
            elif cmd == "Bounced":
                data = msg.get("data", {})
                if data.get("source") == name:
                    continue
                if "ftl_trap" in data:
                    log("RECEIVED AIMED TRAP '%s' from %s (only this slot got it)" % (data["ftl_trap"], data.get("source")))
                elif "TrapLink" in msg.get("tags", []):
                    log("RECEIVED LINK TRAP '%s' from %s" % (data.get("trap_name"), data.get("source")))
                elif data.get("ftl_traplink") == "hello":
                    log("FTL hello from %s (slot %s)" % (data.get("source"), data.get("slot")))
                    if not state["quiet"]:
                        send({"cmd": "Bounce", "games": GAMES,
                              "data": {"source": name, "slot": state["slot"], "ftl_traplink": "reply"}})
                elif data.get("ftl_traplink") == "reply":
                    log("FTL reply from %s (slot %s)" % (data.get("source"), data.get("slot")))
                else:
                    log("bounce: %s" % json.dumps(msg)[:200])


threading.Thread(target=reader, daemon=True).start()
for line in sys.stdin:
    word, _, rest = line.strip().partition(" ")
    if word == "pact" and rest.isdigit():
        send({"cmd": "Bounce", "slots": [int(rest)], "data": {"source": name, "ftl_trap": "Archipelago Deal"}})
        log("pact sent to slot %s" % rest)
    elif word == "trap" and rest:
        send({"cmd": "Bounce", "tags": ["TrapLink"],
              "data": {"source": name, "trap_name": rest, "time": time.time()}})
        log("link trap '%s' sent" % rest)
    elif word == "quiet":
        state["quiet"] = True
        log("no more answers to the FTL hello")
    elif word == "quit":
        break
    else:
        log("commands: pact <slot> | trap <name> | quiet | quit")
