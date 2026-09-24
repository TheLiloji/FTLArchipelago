
import logging
import os
import sys
import types

AP = os.path.expanduser("~/.local/opt/Archipelago")

os.chdir(AP)

_stub = types.ModuleType("bsdiff4.core")
_stub.diff = _stub.patch = lambda *a, **k: b""
sys.modules["bsdiff4.core"] = _stub

sys.path.append(os.path.join(AP, "lib", "library.zip"))
sys.path.append(os.path.join(AP, "lib"))

logging.disable(logging.ERROR)
