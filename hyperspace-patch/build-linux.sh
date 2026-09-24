#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
IMAGE="ghcr.io/ftl-hyperspace/hs-devcontainer:v2"
BUILD_DIR="$HERE/build/hs"
FTL_DIR="${FTL_DIR:-$HOME/.steam/steam/steamapps/common/FTL Faster Than Light}"

[ -d "$ROOT/vendor/FTL-Hyperspace" ] || { echo "Hyperspace clone missing" >&2; exit 1; }

echo "== 1. copy source (without .git) =="
if [ -d "$BUILD_DIR" ]; then
    docker run --rm -v "$HERE/build":/cleanup "$IMAGE" rm -rf /cleanup/hs >/dev/null 2>&1 || true
fi
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
tar -C "$ROOT/vendor/FTL-Hyperspace" --exclude=.git --exclude=build -cf - . | tar -C "$BUILD_DIR" -xf -

echo "== 2. the four integration points =="
cp "$HERE/src/Archipelago.cpp" "$HERE/src/Archipelago.h" "$BUILD_DIR/"

mkdir -p "$BUILD_DIR/vendor-ap"
cp -r "$ROOT/vendor/apclientpp" "$ROOT/vendor/wswrap" "$ROOT/vendor/websocketpp" "$BUILD_DIR/vendor-ap/"

PATCH_FILE="$HERE/patches/apclientpp-cxx11.patch"
if (cd "$BUILD_DIR/vendor-ap/apclientpp" && patch -p1 --forward --dry-run < "$PATCH_FILE" >/dev/null 2>&1); then
    (cd "$BUILD_DIR/vendor-ap/apclientpp" && patch -p1 --forward < "$PATCH_FILE" >/dev/null)
    echo "   apclientpp: C++11 patch applied"
elif (cd "$BUILD_DIR/vendor-ap/apclientpp" && patch -p1 --reverse --dry-run < "$PATCH_FILE" >/dev/null 2>&1); then
    echo "   apclientpp: C++11 patch already present"
else
    echo "FAIL: the C++11 patch does not apply to this apclientpp (different version?)" >&2
    exit 1
fi

python3 - "$BUILD_DIR" "$HERE" <<'PY'
import json, re, sys
from pathlib import Path

hs, patch = Path(sys.argv[1]), Path(sys.argv[2])

vj = hs / "vcpkg.json"
data = json.loads(vj.read_text(encoding="utf-8"))
deps = data.setdefault("dependencies", [])
names = {(d if isinstance(d, str) else d.get("name")) for d in deps}
for needed in ("openssl", "asio", "nlohmann-json"):
    if needed not in names:
        deps.append(needed)
over = data.setdefault("overrides", [])
if not any(o.get("name") == "asio" for o in over):
    over.append({"name": "asio", "version": "1.18.2"})
if not any(o.get("name") == "openssl" for o in over):
    over.append({"name": "openssl", "version": "1.1.1n"})
vj.write_text(json.dumps(data, indent=4, ensure_ascii=False) + "\n", encoding="utf-8")
print("   vcpkg.json: openssl + overrides")

si = hs / "lua" / "modules" / "hyperspace.i"
text = si.read_text(encoding="utf-8")
if "ArchipelagoFTL" not in text:
    facade = (patch / "src" / "Archipelago.i").read_text(encoding="utf-8")
    marker = '%ignore "";'
    if marker not in text:
        raise SystemExit("   FAIL: `%ignore \"\";` not found in hyperspace.i")
    text = text.replace(marker, facade + "\n" + marker, 1)
    si.write_text(text, encoding="utf-8")
    print("   hyperspace.i: Lua facade inserted")
else:
    print("   hyperspace.i: already present")

misc = hs / "Misc.cpp"
t = misc.read_text(encoding="utf-8")
if "ArchipelagoFTL::Instance().Poll()" not in t:
    anchor = 'call_on_internal_event_callbacks(InternalEvents::ON_TICK'
    idx = t.find(anchor)
    if idx < 0:
        raise SystemExit("   FAIL: the ON_TICK hook was not found in Misc.cpp")
    end = t.find("\n", idx)
    t = t[:end + 1] + "    ArchipelagoFTL::Instance().Poll();\n" + t[end + 1:]
    if '#include "Archipelago.h"' not in t:
        t = t.replace('#include "Global.h"', '#include "Global.h"\n#include "Archipelago.h"', 1)
    misc.write_text(t, encoding="utf-8")
    print("   Misc.cpp: Poll() wired into the loop")
else:
    print("   Misc.cpp: already wired")

cm = hs / "CMakeLists.txt"
c = cm.read_text(encoding="utf-8")
if "ARCHIPELAGO_MODULE" not in c:
    block = '''
# ARCHIPELAGO_MODULE
find_package(OpenSSL REQUIRED)
find_path(AP_ASIO_INCLUDE_DIR asio.hpp REQUIRED)
target_compile_definitions(Hyperspace PRIVATE ASIO_STANDALONE _WEBSOCKETPP_CPP11_STL_ AP_NO_SCHEMA)
target_include_directories(Hyperspace PRIVATE
    ${AP_ASIO_INCLUDE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/vendor-ap/websocketpp
    ${CMAKE_CURRENT_SOURCE_DIR}/vendor-ap/apclientpp
    ${CMAKE_CURRENT_SOURCE_DIR}/vendor-ap/wswrap/include)
target_link_libraries(Hyperspace PRIVATE OpenSSL::SSL OpenSSL::Crypto)
# end ARCHIPELAGO_MODULE
'''
    cm.write_text(c.rstrip("\n") + "\n" + block, encoding="utf-8")
    print("   CMakeLists.txt: headers and OpenSSL given to the target")
else:
    print("   CMakeLists.txt: already done")
PY

echo "== 3. build inside the container (long) =="
DNS_ARGS=()
if ! docker run --rm "$IMAGE" getent hosts github.com >/dev/null 2>&1; then
    echo "   container DNS unusable: forcing public resolvers."
    DNS_ARGS=(--dns 1.1.1.1 --dns 8.8.8.8)
fi

docker run --rm "${DNS_ARGS[@]}" -v "$BUILD_DIR":/ftl "$IMAGE" bash -lc '
set -e
command -v make >/dev/null || { apt-get update -qq >/dev/null 2>&1; apt-get install -y -qq make >/dev/null 2>&1; }
cd /ftl
cmake -DCMAKE_TOOLCHAIN_FILE=/vcpkg/scripts/buildsystems/vcpkg.cmake \
    -DVCPKG_HOST_TRIPLET=amd64-linux-ftl \
    -DVCPKG_TARGET_TRIPLET=amd64-linux-ftl \
    -DVCPKG_CHAINLOAD_TOOLCHAIN_FILE=/vcpkg/scripts/toolchains/amd64-linux-ftl.cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DSTEAM_1_6_13_BUILD=ON \
    -S . -B build -G Ninja
ninja -C build
'

so="$(find "$BUILD_DIR/build" -name "*.so" -newer "$BUILD_DIR/CMakeLists.txt" | head -1)"
[ -n "$so" ] || { echo "no .so produced" >&2; exit 1; }
echo
echo "================================================================"
echo "  built: $so"
ls -l "$so" | awk '{print "  size     :", $5, "bytes"}'

if [ "${1:-}" = "--install" ]; then
    target="$FTL_DIR/data/Hyperspace.1.6.13.amd64.so"
    backup="$target.before-archipelago"
    [ -f "$backup" ] || cp "$target" "$backup"
    cp "$so" "$target"
    echo "  installed into the game. Old copy: $backup"
fi
echo "================================================================"
