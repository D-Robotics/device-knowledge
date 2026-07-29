
> Sources: `sysroot_docker` repo (README + Dockerfile), `cross_compile` repo, and `robot_dev_config` README's "ubuntu20.04 docker" cross-compile section (which actually loads `pc_tros_ubuntu22.04_v1.0.0`). Verified against the repos' current default branches.

## What is the sysroot Docker and why you need it

A bare cross-compiler (gcc-arm-11.2) can compile standalone C/C++ code, but it **cannot** resolve TROS/ROS2 headers (`rclcpp.hpp`, `hobot_dnn`, `sensor_msgs`, etc.) or board-specific shared libraries (`libdnn.so`, `libhobot*.so`). These live on the board's rootfs, not in the toolchain's bundled libc.

The **sysroot Docker** solves this by packaging the board's rootfs (or a TROS-equipped Ubuntu rootfs) into a Docker image. When you run the cross-compiler inside this Docker, it finds all the headers and libraries it needs.

## A. The sysroot Docker image

### A.1 What's inside

The sysroot Docker image typically contains:
- **Ubuntu 22.04** base (matching board OS for X3/X5/S100) or **Ubuntu 24.04** for S600
- **TROS headers + libs** at `/opt/tros/humble` (or `/opt/tros/jazzy` for S600)
- **Board system libs** (`/usr/lib/aarch64-linux-gnu/`) — glibc, libstdc++, libopencv, etc.
- **The cross-compiler toolchain** at `/opt/gcc-arm-11.2-...`
- **The CMake toolchain file** at `/robot_dev_config/aarch64_toolchainfile.cmake`

### A.2 Building the image

```bash
git clone https://github.com/D-Robotics/sysroot_docker.git
cd sysroot_docker

# Build (the Dockerfile pulls the base image + installs TROS debs)
docker build -t rdk-sysroot .
```

> The `sysroot_docker` README references the official image `pc_tros_ubuntu22.04_v1.0.0`. If a prebuilt image is available on the D-Robotics registry, you may `docker pull` it directly instead of building — check the repo README for the current pull command.

### A.3 S600 (Jazzy) variant

For S600, you need a **Jazzy** sysroot, not Humble:

```bash
# If building a Jazzy variant, modify the Dockerfile or use a different base:
# - Base: ubuntu:24.04 (S600 = Ubuntu 24.04)
# - TROS: tros-jazzy-* packages (not tros-humble-*)
# - TROS path: /opt/tros/jazzy
```

Key difference: S600's TROS distro is **Jazzy** (`tros-jazzy-*` packages, `/opt/tros/jazzy`), while X3/X5/S100 use **Humble** (`tros-humble-*` packages, `/opt/tros/humble`). Mixing them will cause header/library mismatches.

## B. Using the sysroot Docker for cross-compilation

### B.1 Basic flow

```bash
# From your host (where the TROS source workspace lives):
docker run -it --rm \
  -v /path/to/tros_ws:/tros_ws \
  rdk-sysroot bash

# Inside the Docker container:
cd /tros_ws
bash robot_dev_config/x5_build.sh    # X5
# OR: bash robot_dev_config/s100_build.sh  # S100/S100P/S600
# OR: bash robot_dev_config/all_build.sh   # X3
# OR: bash robot_dev_config/rdkultra_build.sh  # Ultra
```

### B.2 What the build script does

The board-specific build script (`x5_build.sh`, `s100_build.sh`, etc.) typically:
1. Sources the TROS environment (`source /opt/tros/humble/setup.bash`)
2. Sets `CMAKE_TOOLCHAIN_FILE` to `aarch64_toolchainfile.cmake`
3. Runs `colcon build` with cross-compile flags
4. Outputs to `install/` directory

### B.3 Mounting a real board rootfs (alternative)

If you have a board's rootfs dump (e.g., from `dd if=/dev/mmcblk0` or the official image), you can mount it directly instead of using a pre-built Docker image:

```bash
# Create a Docker image from the board's rootfs
docker import board-rootfs.tar.gz rdk-board-rootfs:latest

# Run with the rootfs as the sysroot
docker run -it --rm \
  -v /path/to/tros_ws:/tros_ws \
  -v /opt/gcc-arm-11.2-2022.02-x86_64-aarch64-none-linux-gnu:/opt/toolchain:ro \
  rdk-board-rootfs bash

# Inside, set up the cross-compiler:
export PATH=/opt/toolchain/bin:$PATH
export CMAKE_TOOLCHAIN_FILE=/tros_ws/robot_dev_config/aarch64_toolchainfile.cmake
cd /tros_ws && bash robot_dev_config/x5_build.sh
```

## C. The `cross_compile` repo

The `cross_compile` repo provides additional cross-compilation helpers and scripts that complement `sysroot_docker`:

- **Sysroot preparation scripts** — automate downloading and packaging a board rootfs into a Docker image
- **CMake wrappers** — set up the toolchain file + sysroot automatically
- **Package dependency resolvers** — find which TROS debs provide a given header/library

> Check the repo README for the current script list — it evolves as the cross-compile tooling improves.

## D. Troubleshooting sysroot issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| `fatal error: rclcpp/hpp: No such file` | TROS headers not in sysroot | Ensure Docker image has `tros-humble-*` (or `tros-jazzy-*` for S600) installed |
| `cannot find -lhobot_dnn` | Board-specific lib missing | Mount the real board rootfs (§B.3), or install the corresponding `hobot_*` deb in the Docker |
| `error while loading shared libraries: libc.so.6` | Wrong architecture sysroot | Don't mix x86 and aarch64 rootfs; the sysroot must be aarch64 |
| `colcon build` succeeds but binary won't run on board | Missing runtime libs on board | `ldd <binary>` on the board to find missing libs; install via `apt` |
| Docker `no space left on device` | Build artifacts are large | Use `docker system prune`; mount a large external volume |
| Build works for Humble but fails for S600/Jazzy | Wrong TROS distro in sysroot | Build a separate Jazzy Docker image (Ubuntu 24.04 + `tros-jazzy-*`) |

## E. Related repos

| Repo | Purpose |
|------|---------|
| [sysroot_docker](https://github.com/D-Robotics/sysroot_docker) | Docker image with board rootfs for cross-compile |
| [cross_compile](https://github.com/D-Robotics/cross_compile) | Cross-compile helper scripts and sysroot preparation |
| [robot_dev_config](https://github.com/D-Robotics/robot_dev_config) | TROS compile entry — toolchain file + build scripts |
| [ros2_crosscompile](https://github.com/D-Robotics/ros2_crosscompile) | ROS2 cross-compile utilities (if exists) |
| [tros_arm_build](https://github.com/D-Robotics/tros_arm_build) | TROS ARM build scripts (if exists) |

> Some repos may be archived or renamed — always check the current org listing with `gh api orgs/D-Robotics/repos --jq '.[].name' | grep -i cross`.
