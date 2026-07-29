
> Sources: `robot_dev_config` repo (`aarch64_toolchainfile.cmake`, `x5_build.sh`, `s100_build.sh`, `all_build.sh`, `rdkultra_build.sh`), the `sysroot_docker` and `cross_compile` repos, the toolchain file server at `archive.d-robotics.cc/toolchain/`, and the `os-image-build.md` reference in rdk-source-map. All commands verified against the repos' current default branches.

## When to cross-compile (and when NOT to)

| Scenario | Use cross-compile? | Correct skill |
|----------|-------------------|---------------|
| Compile a C/C++ binary for the board's CPU | ✅ Yes — Workflow 1 below | rdk-cross-compilation |
| Compile a ROS2/TROS package (needs rclcpp headers) | ✅ Yes — Workflow 2 + sysroot Docker | rdk-cross-compilation |
| Convert a neural network model for the BPU | ❌ No — use hb_mapper/hb_compile | rdk-device |
| Build a full OS image from source | ❌ No — use rdk-gen + manifest | rdk-source-map |
| Build all of TROS from source | ⚠️ Overlaps — `robot_dev_config` is shared | rdk-source-map (os-image-build.md §B) + this skill |
| Just install a prebuilt package | ❌ No — `apt install tros-*` on the board | rdk-board-knowledge |

## A. Toolchain download and installation

### A.1 The official aarch64 cross-compiler

The D-Robotics file server hosts a prebuilt GCC toolchain targeting aarch64:

```bash
# Download (~200 MB)
curl -fO http://archive.d-robotics.cc/toolchain/gcc-arm-11.2-2022.02-x86_64-aarch64-none-linux-gnu.tar.xz

# Extract to /opt (standard location referenced by build scripts)
sudo tar -xvf gcc-arm-11.2-2022.02-x86_64-aarch64-none-linux-gnu.tar.xz -C /opt
```

After extraction, the toolchain lives at:
```
/opt/gcc-arm-11.2-2022.02-x86_64-aarch64-none-linux-gnu/
├── bin/
│   ├── aarch64-none-linux-gnu-gcc
│   ├── aarch64-none-linux-gnu-g++
│   └── aarch64-none-linux-gnu-ld  (and other binutils)
├── aarch64-none-linux-gnu/
│   └── libc/  (the target sysroot — glibc, libstdc++, etc.)
└── lib/
```

Verify the compiler works:
```bash
/opt/gcc-arm-11.2-2022.02-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-gcc --version
# → gcc 11.2.1 ...
```

> **Why /opt?** The `aarch64_toolchainfile.cmake` in `robot_dev_config` and the build scripts reference `/opt/gcc-arm-11.2-...` as the default toolchain path. If you extract elsewhere, update the toolchain file or pass `-DCMAKE_TOOLCHAIN_ROOT=<your-path>`.

### A.2 Host prerequisites

```bash
sudo apt-get install -y build-essential cmake docker.io python3-pip git
sudo pip install -U vcstool colcon-common-extensions
```

Ubuntu 22.04 is the recommended host OS — it matches the target board's system version (X3/X5/S100 = Ubuntu 22.04, S600 = Ubuntu 24.04), reducing dependency drift.

## B. The CMake toolchain file (`aarch64_toolchainfile.cmake`)

### B.1 What it does

The toolchain file tells CMake to use the aarch64 cross-compiler instead of the host's x86 gcc. It sets:
- `CMAKE_C_COMPILER` / `CMAKE_CXX_COMPILER` → `aarch64-none-linux-gnu-gcc` / `-g++`
- `CMAKE_SYSROOT` → the toolchain's bundled libc sysroot
- `CMAKE_FIND_ROOT_PATH_MODE_*` → `ONLY` for programs/libraries (don't fall back to host x86 libs)

### B.2 Getting the file

```bash
git clone https://github.com/D-Robotics/robot_dev_config.git -b develop
# → robot_dev_config/aarch64_toolchainfile.cmake
```

The file is shared across all boards — **it is NOT board-specific.** The board specificity comes from the **build script** (`x5_build.sh`, `s100_build.sh`, etc.) and the **TROS distro** (Humble vs Jazzy) in the sysroot.

### B.3 Using it with CMake (bare C/C++ project)

```bash
mkdir build && cd build
cmake .. \
  -DCMAKE_TOOLCHAIN_FILE=/path/to/robot_dev_config/aarch64_toolchainfile.cmake \
  -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
```

Verify the output is aarch64:
```bash
file my_app
# Expected: ELF 64-bit LSB pie, ARM aarch64, ...

# If you see "x86-64" instead, the toolchain file wasn't picked up — check the cmake output
# for "CMAKE_C_COMPILER: /opt/gcc-arm-11.2-.../bin/aarch64-none-linux-gnu-gcc"
```

## C. Board → build-script → TROS-distro mapping

This table is the single source of truth for TROS cross-compile. When a user asks "which build script for my board," match this table:

| Board | `robot_dev_config` build script | TROS distro | TROS path on board | Notes |
|-------|-------------------------------|-------------|--------------------|------|
| RDK X3 | `all_build.sh` | Humble | `/opt/tros/humble` | Default `ros2.repos` |
| RDK X5 | `x5_build.sh` | Humble | `/opt/tros/humble` | X5-specific package selection |
| RDK Ultra | `rdkultra_build.sh` | Foxy/Humble | `/opt/tros/foxy` or `/humble` | Ultra supports both |
| RDK S100 | `s100_build.sh` | Humble | `/opt/tros/humble` | Nash-e |
| RDK S100P | `s100_build.sh` | Humble | `/opt/tros/humble` | Nash-m, same build config |
| RDK S600 | `s100_build.sh` | **Jazzy** | `/opt/tros/jazzy` | Nash-p, **different distro** |
| x86 (host dev) | `x86_build.sh` | Humble/Jazzy | `/opt/tros/*` | Native x86, not cross-compile |
| Minimal | `minimal_build.sh` | — | — | Trimmed build (subset of packages) |

> **S600 caveat:** S600 shares `s100_build.sh` (same Nash-family build config), but the TROS distro is **Jazzy**, not Humble. Ensure your sysroot Docker image has Jazzy TROS headers (`/opt/tros/jazzy`), not Humble.

### C.1 `robot_dev_config` key files

| File | Purpose |
|------|---------|
| `aarch64_toolchainfile.cmake` | CMake cross-compile toolchain file (shared) |
| `ros2.repos` | vcstool manifest — the full TROS package list (release) |
| `ros2_alpha.repos` | Alpha/pre-release variant |
| `ros2_release.repos` | Stable release variant |
| `build.sh` | Generic compile entry (used by board-specific scripts) |
| `x5_build.sh` / `s100_build.sh` / `all_build.sh` / `rdkultra_build.sh` | Board-specific build configs |
| `x86_build.sh` | Native x86 build (not cross-compile) |
| `minimal_build.sh` / `minimal_deploy.sh` | Minimal build + trimmed deployment |
| `bloom_script/` | App deb packaging |

## D. TROS cross-compile workflow (full step-by-step)

### D.1 Fetch source

```bash
mkdir -p /mnt/data/tros_ws/src
cd /mnt/data/tros_ws
git clone https://github.com/D-Robotics/robot_dev_config.git -b develop
sudo pip install -U vcstool
vcs import src < ./robot_dev_config/ros2.repos
# During import: . = repo pulled OK, E = failed pull (failing repo named in log)
```

### D.2 Build inside the sysroot Docker

The sysroot Docker provides the board's rootfs (TROS headers, system libs) so the cross-compiler can resolve all dependencies. See [sysroot-docker-setup.md](sysroot-docker-setup.md) for Docker setup details.

```bash
# Enter the sysroot Docker (mounts TROS headers + board libs)
docker run -it --rm -v /mnt/data/tros_ws:/tros_ws rdk-sysroot bash

# Inside Docker:
cd /tros_ws
bash robot_dev_config/x5_build.sh   # or s100_build.sh / all_build.sh / rdkultra_build.sh
```

> The `robot_dev_config` README's cross-compile section is headed "ubuntu20.04 docker," but the official image it loads is `pc_tros_ubuntu22.04_v1.0.0` (Ubuntu 22.04). Don't be confused by the section title.

### D.3 Deploy to board

```bash
# The compiled workspace lands in install/ (or build/install/)
scp -r /mnt/data/tros_ws/install/* root@<board-ip>:/opt/tros/humble/

# On the board:
source /opt/tros/humble/setup.bash
ros2 run <your_pkg> <your_node>
```

## E. Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `aarch64-none-linux-gnu-gcc: command not found` | Toolchain not extracted | Re-run A.1 extraction to `/opt` |
| `CMake Error: CMAKE_C_COMPILER not found` | Toolchain file path wrong | Verify `-DCMAKE_TOOLCHAIN_FILE` path and toolchain extraction |
| `fatal error: ros2/rclcpp.hpp: No such file` | Sysroot missing TROS headers | Use sysroot Docker (Workflow 2), not bare toolchain |
| `cannot execute binary file: Exec format error` | Compiled for x86, not aarch64 | Pass `CMAKE_TOOLCHAIN_FILE` to cmake; verify with `file` |
| `undefined reference to libdnn.so` | Linking board-specific lib without sysroot | Mount board's `/usr/lib` via sysroot Docker |
| `vcs import` shows `E` for some repos | Network or repo access issue | Check the log for the failing repo name; retry `vcs import` |
| `docker build` fails on sysroot | Base image pull failure | Check Docker daemon; try `docker pull ubuntu:22.04` first |
| Build script `not found` | Wrong `robot_dev_config` branch | Use `-b develop`; check `ls robot_dev_config/*build.sh` |

## Related links

- [robot_dev_config (TROS compile entry)](https://github.com/D-Robotics/robot_dev_config)
- [sysroot_docker (Docker sysroot for cross-compile)](https://github.com/D-Robotics/sysroot_docker)
- [OS image build from source (rdk-source-map skill)](https://github.com/D-Robotics/rdk-gen)
- [Toolchain download](http://archive.d-robotics.cc/toolchain/)
