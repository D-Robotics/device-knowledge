---
name: rdk-cross-compilation
description: Cross-compile generic C/C++ applications and ROS2/TROS packages for RDK boards (aarch64) from an x86 Linux host — sysroot Docker setup, aarch64 toolchain download, CMake toolchain file usage, and colcon cross-compile workflow. Use whenever the user wants to compile native C/C++ code or ROS2 packages ON THE HOST for deployment TO THE BOARD, NOT on the board itself. 触发词:交叉编译、cross-compile、cross compile、sysroot、aarch64_toolchainfile.cmake、toolchain file、CMake 交叉编译、colcon cross-compile、ROS2 交叉编译、TROS 编译、robot_dev_config、x5_build.sh、s100_build.sh、gcc-arm-11.2、在主机上编译给板子用。Routing — BPU model conversion (hb_mapper/hb_compile → .bin/.hbm) → rdk-device; building the full OS image from source (rdk-gen/manifest → *.img) → rdk-source-map; running a ready-made model → rdk-model-zoo.
---

# RDK Cross-Compilation (Host → Board)

Cross-compile generic C/C++ applications and ROS2/TROS packages for RDK's aarch64 target from an x86 Linux host. The single most common failure is attempting to compile directly on the board — the board lacks the compiler, the sysroot headers, and the CPU horsepower. **Get the host toolchain + sysroot right first, then cross-compile.**

> Sources: official D-Robotics docs (rdk_doc / rdk_x_doc), the `robot_dev_config` repo (`aarch64_toolchainfile.cmake`, `x5_build.sh`, `s100_build.sh`), the `sysroot_docker` and `cross_compile` repos, and the toolchain file server at `archive.d-robotics.cc/toolchain/`. Facts are carried over with provenance; nothing is invented.

## The one rule that matters most

**Don't compile on the board.** RDK boards are aarch64 SBCs with limited CPU and no full build toolchain for large projects. The correct workflow is: install the **aarch64 cross-compiler on an x86 host** (Ubuntu 22.04 recommended), point CMake at `aarch64_toolchainfile.cmake`, and deploy the compiled binary to the board via `scp`. When someone says *"I'm trying to `make` on the board and it's taking forever"* — interrupt and set up the cross-compile environment.

## Board → cross-compile config cheat-sheet

Confirm the target board first (`cat /sys/class/socinfo/board_id` on the board), then everything follows:

| Board | Target arch | TROS distro | Toolchain | Build script (robot_dev_config) |
|-------|-------------|-------------|-----------|---------------------------------|
| RDK X3 | aarch64 | Humble (`/opt/tros/humble`) | gcc-arm-11.2 | `all_build.sh` |
| RDK X5 | aarch64 | Humble (`/opt/tros/humble`) | gcc-arm-11.2 | `x5_build.sh` |
| RDK Ultra | aarch64 | Foxy/Humble (`/opt/tros/foxy` or `/humble`) | gcc-arm-11.2 | `rdkultra_build.sh` |
| RDK S100 | aarch64 | Humble (`/opt/tros/humble`) | gcc-arm-11.2 | `s100_build.sh` |
| RDK S100P | aarch64 | Humble (`/opt/tros/humble`) | gcc-arm-11.2 | `s100_build.sh` |
| RDK S600 | aarch64 | Jazzy (`/opt/tros/jazzy`) | gcc-arm-11.2 | `s100_build.sh` (S600 shares S100 build) |

**Two iron rules:**
- ✅ The cross-compiler runs on an **x86 Linux host** (Ubuntu 22.04). The board only receives the compiled binary.
- ❌ Never tell the user to `apt install gcc` on the board and compile there — it wastes time and the board lacks the full sysroot for complex projects.

## Correct the misconception first

When a user opens with a wrong premise, **clarify in one line before continuing.** Common premises to catch: "I'll just `make` on the board" (no — cross-compile on x86 host), "cross-compiling is the same as BPU model conversion" (no — hb_mapper/hb_compile produces BPU artifacts, not native binaries; that's rdk-device), "I need to build the whole OS image" (no — that's `rdk-gen` + `manifest`, see rdk-source-map), "the toolchain file is board-specific" (no — `aarch64_toolchainfile.cmake` is shared; the **build script** and **TROS distro** differ by board).

## Failure quick-routing: symptom → cause

- **`aarch64-none-linux-gnu-gcc: command not found`** — toolchain not downloaded/extracted; see Workflow 1 step 1.
- **`CMake Error: CMAKE_C_COMPILER not found`** — toolchain file path wrong or toolchain not in PATH; check `CMAKE_TOOLCHAIN_FILE` points to the extracted toolchain.
- **`fatal error: ros2/rclcpp.hpp: No such file`** — sysroot missing TROS headers; you need the TROS sysroot (Workflow 2), not just the bare toolchain.
- **`cannot execute binary file: Exec format error`** — you compiled for x86, not aarch64; verify the toolchain file was passed to CMake/colcon.
- **`undefined reference to libdnn.so`** — linking against board-specific libs (hobot-dnn, etc.) without the board sysroot; mount the board's `/usr/lib` via sysroot Docker.

## Workflows

### Workflow 1 — Bare C/C++ application cross-compile (CMake)

**Use when:** compiling a standalone C/C++ binary (no ROS2 dependency) for the board.
**Precondition:** x86 Ubuntu 22.04 host, ~10 GB free space.

1. **Download the toolchain** `[safe]`:
   ```bash
   curl -fO http://archive.d-robotics.cc/toolchain/gcc-arm-11.2-2022.02-x86_64-aarch64-none-linux-gnu.tar.xz
   sudo tar -xvf gcc-arm-11.2-2022.02-x86_64-aarch64-none-linux-gnu.tar.xz -C /opt
   # → /opt/gcc-arm-11.2-2022.02-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-gcc
   ```

2. **Get the toolchain file** `[safe]` — clone `robot_dev_config` (or copy just the file):
   ```bash
   git clone https://github.com/D-Robotics/robot_dev_config.git -b develop
   # → robot_dev_config/aarch64_toolchainfile.cmake
   ```

3. **Build with CMake** `[safe]`:
   ```bash
   mkdir build && cd build
   cmake .. \
     -DCMAKE_TOOLCHAIN_FILE=../robot_dev_config/aarch64_toolchainfile.cmake \
     -DCMAKE_BUILD_TYPE=Release
   make -j$(nproc)
   file your_app   # → "ELF 64-bit LSB ... ARM aarch64" — confirms cross-compile succeeded
   ```

4. **Deploy** `[safe]` — `scp your_app root@<board-ip>:/userdata/` then `ssh root@<board-ip> /userdata/your_app`.

Full details + sysroot setup: [cross-compile-workflow.md](references/cross-compile-workflow.md).

**验证:** `file <binary>` shows `ARM aarch64`; the binary runs on the board without `Exec format error`; `ldd` on the board resolves all shared libs.

### Workflow 2 — TROS / ROS2 package cross-compile (colcon + sysroot Docker)

**Use when:** compiling ROS2/TROS packages (need TROS headers + rclcpp sysroot), or building all of TROS from source.
**Precondition:** x86 Ubuntu 22.04 host, Docker installed.

1. **Set up the sysroot Docker** `[safe]` — the `sysroot_docker` repo provides a Docker image with the board's rootfs (TROS headers, libs) mounted for cross-compilation:
   ```bash
   git clone https://github.com/D-Robotics/sysroot_docker.git
   cd sysroot_docker
   # Build the sysroot image (contains /opt/tros + board system libs)
   docker build -t rdk-sysroot .
   ```

2. **Pull TROS source** `[safe]` — use `robot_dev_config` + `vcstool`:
   ```bash
   mkdir -p tros_ws/src && cd tros_ws
   git clone https://github.com/D-Robotics/robot_dev_config.git -b develop
   sudo pip install -U vcstool
   vcs import src < ./robot_dev_config/ros2.repos   # . = OK, E = failed pull
   ```

3. **Cross-compile inside the Docker sysroot** `[safe]` — use the board-specific build script:
   ```bash
   # Enter the sysroot Docker (mounts TROS headers + board libs)
   docker run -it --rm -v $(pwd):/tros_ws rdk-sysroot bash
   # Inside Docker, source the toolchain file + build
   cd /tros_ws
   bash robot_dev_config/x5_build.sh        # X5; use s100_build.sh for S100/S100P/S600;
                                            # all_build.sh for X3; rdkultra_build.sh for Ultra
   ```

4. **Deploy** `[safe]` — the compiled workspace lands in `install/`; `scp -r install/ root@<board-ip>:/opt/tros/` and source `setup.bash` on the board.

Full Docker sysroot details: [sysroot-docker-setup.md](references/sysroot-docker-setup.md).

**验证:** compiled `.so`/node shows `ARM aarch64` via `file`; `ros2 run <pkg> <node>` works on the board; `ldd` on the board resolves all TROS + system libs.

## Worked examples

**Example 1 — "我想在板子上直接 `make` 我的 C++ 项目,但是太慢了"**
Don't suggest optimizations. Respond: *"The board is an aarch64 SBC — compiling on it wastes time and may lack headers. Set up the cross-compiler on your x86 host: download `gcc-arm-11.2` from `archive.d-robotics.cc/toolchain/`, grab `aarch64_toolchainfile.cmake` from `robot_dev_config`, and `cmake -DCMAKE_TOOLCHAIN_FILE=...` on your host. Verify with `file <binary>` showing 'ARM aarch64', then `scp` it to the board."* Then point to Workflow 1.

**Example 2 — "我需要编译一个依赖 rclcpp 的 ROS2 包,但交叉编译一直找不到头文件"**
The bare toolchain doesn't have TROS headers. You need the **sysroot Docker** — it mounts the board's `/opt/tros` (rclcpp, hobot_* headers) so the cross-compiler can resolve them. Clone `sysroot_docker`, build the image, then run the build script (`x5_build.sh` / `s100_build.sh`) inside the Docker. See Workflow 2 and [sysroot-docker-setup.md](references/sysroot-docker-setup.md).

**Example 3 — "S600 的 TROS 该怎么编译?"**
S600 uses **Jazzy** (`/opt/tros/jazzy`), not Humble. In `robot_dev_config`, use `s100_build.sh` (S600 shares the S100 build config — both are Nash-family). Make sure your sysroot Docker image has the Jazzy TROS headers, not Humble. See [cross-compile-workflow.md](references/cross-compile-workflow.md) for the board → build-script → TROS-distro mapping.

**Example 4 — "交叉编译和 hb_mapper 有什么区别?"**
They're completely different. `hb_mapper`/`hb_compile` (skill rdk-device) converts neural network models (`.pt`→`.onnx`→`.bin`/`.hbm`) for the **BPU**. Cross-compilation (this skill) compiles **native C/C++/ROS2 code** into regular aarch64 Linux binaries that run on the board's CPU. A project can need both: cross-compile the C++ inference app (this skill) + convert the model with hb_mapper (rdk-device).

## Common pitfalls

| ❌ Don't | ✅ Do |
|---------|------|
| Compile on the board (`make` / `colcon build` directly) | Cross-compile on an x86 host with the aarch64 toolchain |
| Confuse cross-compile with BPU model conversion | hb_mapper/hb_compile → BPU artifacts (rdk-device); cross-compile → native aarch64 binaries (this skill) |
| Use the bare toolchain for ROS2 packages | Set up the sysroot Docker (TROS headers + board libs) |
| Forget to pass `CMAKE_TOOLCHAIN_FILE` to CMake | Always pass `-DCMAKE_TOOLCHAIN_FILE=aarch64_toolchainfile.cmake` |
| Use Humble build script for S600 | S600 = Jazzy; use `s100_build.sh` with a Jazzy sysroot |
| Build the whole OS image when you just need one binary | OS image build (`rdk-gen`) is for system customization (rdk-source-map); cross-compile is for apps |

## Anti-hallucination guardrails

When answering from this skill, follow these rules — never fabricate facts, commands, or file paths:

1. **Report only observed data.** Quote what scripts/commands actually return, not what you remember. If the probe says `board_id: X5`, answer for X5 — even if the user insists it's an S100.
2. **No fabrication when tools are missing.** If a script or reference doesn't exist, say "not found" — don't invent from memory. Route to the appropriate skill or doc instead.
3. **Preserve null/false/empty on failure.** If a probe returns `null` or `false`, report that — don't substitute a plausible value. Empty output is data, not an error to "fix".
4. **No substitution off-platform.** If `off_platform: true`, say "probe didn't run on an RDK board" — don't guess what it would have returned. Ask for on-board logs.
5. **No hand-editing JSON.** Scripts emit structured JSON; never hand-craft output. If the contract says `{ok,off_platform,reason,fields}`, that's what goes to the user.
6. **Acknowledge sandbox limits.** If you can't run a command, say so — don't pretend you did. Offer the command for the user to run.
7. **Read-only boundary.** Never modify the system — no `dd`, `mkfs`, `rm -rf`, `apt install`, `reboot`, or GPIO output without explicit user confirmation.

## Reference map

| Read this | When |
|-----------|------|
| [cross-compile-workflow.md](references/cross-compile-workflow.md) | Full step-by-step: toolchain download, CMake toolchain file, bare C/C++ cross-compile, board → build-script → TROS-distro mapping |
| [sysroot-docker-setup.md](references/sysroot-docker-setup.md) | Setting up the sysroot Docker image for ROS2/TROS cross-compile — Dockerfile, mounting board rootfs, TROS header resolution |
| `scripts/cross_compile_lookup.py` | Quick board → toolchain/build-script/TROS-distro lookup (text output; run `python3 cross_compile_lookup.py s600` or no args for the full table) |
