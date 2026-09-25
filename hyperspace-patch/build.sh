#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
IMAGE="ghcr.io/ftl-hyperspace/hs-devcontainer:v2"

TARGET="${1:-}"
case "$TARGET" in
    linux)
        TRIPLET=amd64-linux-ftl
        STEAM_1_6_13=ON
        LIBRARY=Hyperspace.1.6.13.amd64.so
        ;;
    windows)
        TRIPLET=x86-windows-ftl
        STEAM_1_6_13=OFF
        LIBRARY=Hyperspace.dll
        ;;
    *)
        echo "usage: $0 linux|windows [--install]" >&2
        exit 1
        ;;
esac
shift

SRC_DIR="$HERE/build/src-$TARGET"
OUT_DIR="$HERE/build/$TARGET"
VOLUME="ftl-archipelago-build-$TARGET"

on_windows() {
    case "$(uname -s)" in MINGW* | MSYS* | CYGWIN*) return 0 ;; esac
    return 1
}

host_path() {
    if on_windows; then cygpath -w "$1"; else echo "$1"; fi
}

if on_windows; then
    export MSYS_NO_PATHCONV=1
fi

[ -d "$ROOT/vendor/FTL-Hyperspace" ] || { echo "Hyperspace clone missing" >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "docker not found: the build runs in Hyperspace's container" >&2; exit 1; }

echo "== 1. copy source (without .git) =="
rm -rf "$SRC_DIR"
mkdir -p "$SRC_DIR" "$OUT_DIR"
tar -C "$ROOT/vendor/FTL-Hyperspace" --exclude=.git --exclude=build -cf - . | tar -C "$SRC_DIR" -xf -

echo "== 2. the four integration points =="
cp "$HERE/src/Archipelago.cpp" "$HERE/src/Archipelago.h" "$SRC_DIR/"

mkdir -p "$SRC_DIR/vendor-ap"
for dep in apclientpp wswrap websocketpp; do
    tar -C "$ROOT/vendor" --exclude=.git -cf - "$dep" | tar -C "$SRC_DIR/vendor-ap" -xf -
done

PATCH_FILE="$HERE/patches/apclientpp-cxx11.patch"
if (cd "$SRC_DIR/vendor-ap/apclientpp" && patch -p1 --forward --dry-run < "$PATCH_FILE" >/dev/null 2>&1); then
    (cd "$SRC_DIR/vendor-ap/apclientpp" && patch -p1 --forward < "$PATCH_FILE" >/dev/null)
    echo "   apclientpp: C++11 patch applied"
elif (cd "$SRC_DIR/vendor-ap/apclientpp" && patch -p1 --reverse --dry-run < "$PATCH_FILE" >/dev/null 2>&1); then
    echo "   apclientpp: C++11 patch already present"
else
    echo "FAIL: the C++11 patch does not apply to this apclientpp (different version?)" >&2
    exit 1
fi

python3 - "$(host_path "$SRC_DIR")" "$(host_path "$HERE")" <<'PY'
import json, sys
from pathlib import Path

hs, patch = Path(sys.argv[1]), Path(sys.argv[2])

def write(path, text):
    path.write_text(text, encoding="utf-8", newline="\n")

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
write(vj, json.dumps(data, indent=4, ensure_ascii=False) + "\n")
print("   vcpkg.json: openssl + overrides")

si = hs / "lua" / "modules" / "hyperspace.i"
text = si.read_text(encoding="utf-8")
if "ArchipelagoFTL" not in text:
    facade = (patch / "src" / "Archipelago.i").read_text(encoding="utf-8")
    marker = '%ignore "";'
    if marker not in text:
        raise SystemExit("   FAIL: `%ignore \"\";` not found in hyperspace.i")
    write(si, text.replace(marker, facade + "\n" + marker, 1))
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
    write(misc, t)
    print("   Misc.cpp: Poll() wired into the loop")
else:
    print("   Misc.cpp: already wired")

# OpenSSL is C, and clang picks up mingw's GCC <stdatomic.h>, which it cannot compile. Without C11
# atomics OpenSSL falls back to the __atomic builtins, which clang handles.
overlay = hs / "ap-vcpkg"
(overlay / "triplets").mkdir(parents=True, exist_ok=True)
triplet = (hs / ".devcontainer" / "triplets" / "x86-windows-ftl.cmake").read_text(encoding="utf-8")
write(overlay / "triplets" / "x86-windows-ftl.cmake", triplet.rstrip("\n") + '''

if(PORT STREQUAL "openssl")
    set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE "/ftl/ap-vcpkg/openssl-toolchain.cmake")
endif()
''')
write(overlay / "openssl-toolchain.cmake", '''include("/vcpkg/scripts/toolchains/x86-windows-ftl.cmake")
string(APPEND CMAKE_C_FLAGS_INIT " -D__STDC_NO_ATOMICS__")
''')

cm = hs / "CMakeLists.txt"
c = cm.read_text(encoding="utf-8")
if "ARCHIPELAGO_MODULE" not in c:
    block = '''
# ARCHIPELAGO_MODULE
find_package(OpenSSL REQUIRED)
find_path(AP_ASIO_INCLUDE_DIR asio.hpp REQUIRED)
target_compile_definitions(Hyperspace PRIVATE ASIO_STANDALONE _WEBSOCKETPP_CPP11_STL_ _WEBSOCKETPP_CPP11_THREAD_ AP_NO_SCHEMA)
target_include_directories(Hyperspace PRIVATE
    ${AP_ASIO_INCLUDE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/vendor-ap/websocketpp
    ${CMAKE_CURRENT_SOURCE_DIR}/vendor-ap/apclientpp
    ${CMAKE_CURRENT_SOURCE_DIR}/vendor-ap/wswrap/include)
target_link_libraries(Hyperspace PRIVATE OpenSSL::SSL OpenSSL::Crypto)
if(WIN32)
    target_link_libraries(Hyperspace PRIVATE ws2_32 mswsock crypt32)
    # mingw's malloc is 8-byte aligned on x86 while asio's connection objects ask for 16: without
    # aligned new they land misaligned and the first SSE store into them crashes.
    set_source_files_properties(Archipelago.cpp PROPERTIES
        COMPILE_OPTIONS "-faligned-allocation;-fnew-alignment=8")
endif()
# end ARCHIPELAGO_MODULE
'''
    write(cm, c.rstrip("\n") + "\n" + block)
    print("   CMakeLists.txt: headers and OpenSSL given to the target")
else:
    print("   CMakeLists.txt: already done")
PY

echo "== 3. build inside the container (long the first time) =="
DNS_ARGS=()
if ! docker run --rm "$IMAGE" getent hosts github.com >/dev/null 2>&1; then
    echo "   container DNS unusable: forcing public resolvers."
    DNS_ARGS=(--dns 1.1.1.1 --dns 8.8.8.8)
fi

FIXES=""
OVERLAY=""
if [ "$TARGET" = windows ]; then
    FIXES="bash .devcontainer/devcontainer-fixes.sh windows >/dev/null"
    OVERLAY="-DVCPKG_OVERLAY_TRIPLETS=/ftl/ap-vcpkg/triplets"
fi

rm -f "$OUT_DIR/$LIBRARY"
docker run --rm "${DNS_ARGS[@]}" \
    -v "$VOLUME":/ftl \
    -v ftl-archipelago-vcpkg-cache:/root/.cache/vcpkg \
    -v "$(host_path "$SRC_DIR")":/src:ro \
    -v "$(host_path "$OUT_DIR")":/out \
    "$IMAGE" bash -lc "
set -e
command -v make >/dev/null || { apt-get update -qq >/dev/null 2>&1; apt-get install -y -qq make >/dev/null 2>&1; }
cp -a /src/. /ftl/
cd /ftl
$FIXES
cmake -DCMAKE_TOOLCHAIN_FILE=/vcpkg/scripts/buildsystems/vcpkg.cmake \
    -DVCPKG_HOST_TRIPLET=$TRIPLET \
    -DVCPKG_TARGET_TRIPLET=$TRIPLET \
    -DVCPKG_CHAINLOAD_TOOLCHAIN_FILE=/vcpkg/scripts/toolchains/$TRIPLET.cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DSTEAM_1_6_13_BUILD=$STEAM_1_6_13 \
    -DVCPKG_INSTALL_OPTIONS=--x-buildtrees-root=/ftl/vcpkg-buildtrees $OVERLAY \
    -S . -B build -G Ninja
ninja -C build
cp build/$LIBRARY /out/
"

built="$OUT_DIR/$LIBRARY"
[ -f "$built" ] || { echo "no $LIBRARY produced" >&2; exit 1; }
echo
echo "================================================================"
echo "  built: $built"
echo "  size : $(wc -c < "$built") bytes"

if [ "${1:-}" = "--install" ]; then
    if [ "$TARGET" = windows ]; then
        FTL_DIR="${FTL_DIR:-$(bash "$ROOT/mod/install.sh" --print-game-dir)}"
        target="$FTL_DIR/$LIBRARY"
    else
        FTL_DIR="${FTL_DIR:-$HOME/.steam/steam/steamapps/common/FTL Faster Than Light}"
        target="$FTL_DIR/data/$LIBRARY"
    fi
    backup="$target.before-archipelago"
    [ -f "$backup" ] || cp "$target" "$backup"
    cp "$built" "$target"
    echo "  installed into the game. Old copy: $backup"
fi
echo "================================================================"
