import os
import pty
import subprocess
import sys
import threading
from pathlib import Path

SERVER = Path(os.environ.get("AP_SERVER", "~/.local/opt/Archipelago/ArchipelagoServer")).expanduser()


def drive(seed, fifo, log):
    if not os.path.exists(fifo):
        os.mkfifo(fifo)
    master, slave = pty.openpty()
    process = subprocess.Popen([str(SERVER), seed], stdin=slave, stdout=slave,
                                stderr=slave, close_fds=True)
    os.close(slave)

    def read_loop():
        with open(log, "wb", buffering=0) as out:
            while True:
                try:
                    chunk = os.read(master, 4096)
                except OSError:
                    return
                if not chunk:
                    return
                out.write(chunk)

    threading.Thread(target=read_loop, daemon=True).start()
    try:
        while process.poll() is None:
            with open(fifo, "r") as input_file:
                for line in input_file:
                    os.write(master, (line.rstrip("\n") + "\n").encode())
    finally:
        if process.poll() is None:
            process.terminate()


if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("usage: server_driver.py <seed.archipelago> <fifo> <log>", file=sys.stderr)
        raise SystemExit(2)
    drive(*sys.argv[1:])
