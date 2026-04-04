# libdmdutil-python

`libdmdutil-python` is a small Python wrapper around `libdmdutil` for sending images and animations to:

- ZeDMD over USB
- ZeDMD over Wi-Fi
- Pixelcade
- PIN2DMD

This repo is meant to be embedded into another Python project. The intended output is a small `libdmdutil-python/` folder containing only the runtime files your app needs.

## What It Provides

The root-level module is:

- [libdmdutil_wrapper.py](/home/superhac/repos/vpindmd-send/libdmdutil_wrapper.py)
- [dmdutil_backend.py](/home/superhac/repos/vpindmd-send/dmdutil_backend.py)
- [media.py](/home/superhac/repos/vpindmd-send/media.py)

Import this class from another project with:

```python
from libdmdutil_wrapper import DMDController
```

The main methods are:

- `load()`
- `unload()`
- `hold_image(path)`
- `stop(clear=False)`
- `play_video(path, loop=True)`
- `clear()`
- `info()`

## Build

The build flow is shell-script based.

### 1. Fetch the latest libdmdutil release

```bash
./fetch_libdmdutil.sh
```

This downloads the latest GitHub release source into:

```bash
libdmdutil
```

### 2. Build libdmdutil

```bash
./build_libdmdutil.sh
```

### 3. Build the wrapper bridge

```bash
./build_wrapper.sh
```

### 4. Stage a minimal runtime bundle

```bash
./stage_runtime.sh
```

That produces:

```bash
libdmdutil-python
```

This is the folder you would copy into another project.

If you already have a local `libdmdutil` tree:

```bash
./build_libdmdutil.sh /path/to/libdmdutil /path/to/libdmdutil/build
./build_wrapper.sh /path/to/libdmdutil /path/to/libdmdutil/build
./stage_runtime.sh /path/to/libdmdutil /path/to/libdmdutil/build /path/to/output
```

If `third_party/libdmdutil` already exists and you want to rebuild from it:

```bash
./build_libdmdutil.sh
./build_wrapper.sh
./stage_runtime.sh
```

## Third-Party Layout

The target runtime layout is intentionally small:

```text
libdmdutil-python/
  libdmdutil_wrapper.py
  dmdutil_backend.py
  media.py
  libdmdutil_python_bridge.so|dylib|dll
  libdmdutil runtime libraries...
```

That is the minimum bundle this project is trying to produce for a third-party app.

## Python Dependency

Still images and animated image playback use Pillow.

Install it with:

```bash
python3 -m pip install --user Pillow
```

## Basic Example

```python
from libdmdutil_wrapper import DMDController
import time

dmd = DMDController(device="/dev/ttyACM0")
info = dmd.load()
print(info)

dmd.hold_image("logo.png", fit_mode="contain")
time.sleep(3)

dmd.play_video("attract.gif", loop=True, fit_mode="contain")
time.sleep(10)

dmd.stop(clear=True)
dmd.unload()
```

For Wi-Fi:

```python
from libdmdutil_wrapper import DMDController

dmd = DMDController(host="192.168.6.219")
dmd.load()
dmd.hold_image("logo.png")
```

For Pixelcade:

```python
from libdmdutil_wrapper import DMDController

dmd = DMDController(pixelcade_device="/dev/ttyUSB0")
dmd.load()
dmd.hold_image("logo.png")
```

For PIN2DMD:

```python
from libdmdutil_wrapper import DMDController

dmd = DMDController(pin2dmd=True)
dmd.load()
dmd.play_video("attract.gif", loop=True)
```

## Notes

- `play_video()` currently uses Pillow frame iteration, so the supported animated formats are whatever Pillow can read well. GIF is the primary target right now.
- The underlying low-level transport is handled by `libdmdutil`, not by Python code in this repo.
- The bridge source is:
  - [dmdutil_bridge.cpp](/home/superhac/repos/vpindmd-send/native/dmdutil_bridge.cpp)
  - [dmdutil_bridge.h](/home/superhac/repos/vpindmd-send/native/dmdutil_bridge.h)
- The built bridge library is intended to live next to the Python files in the bundled third-party folder.
- A GitHub Actions cross-platform build workflow is included at:
  - [.github/workflows/build.yml](/home/superhac/repos/vpindmd-send/.github/workflows/build.yml)

## Example Script

There is also a simple standalone example:

- [test.py](/home/superhac/repos/vpindmd-send/test.py)

Example usage:

```bash
python3 test.py --device /dev/ttyACM0
python3 test.py --device /dev/ttyACM0 --image dmd.png
python3 test.py --host 192.168.6.219 --gif attract.gif
python3 test.py --pixelcade-device /dev/ttyUSB0 --image dmd.png
python3 test.py --pin2dmd --gif attract.gif
```
