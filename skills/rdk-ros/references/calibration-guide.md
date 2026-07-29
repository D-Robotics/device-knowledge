# RDK Stereo & IMU Calibration Guide

> Sources: D-Robotics official docs — [tros_doc](https://github.com/D-Robotics/tros_doc) (hobot_stereonet, mipi_cam, hobot_vio), [hobot_stereonet](https://github.com/D-Robotics/hobot_stereonet) repo README, [accessories_doc](https://github.com/D-Robotics/accessories_doc) (GS130W/Wi, IMU module SDK), and `rdk_x_doc` `docs/06_Application_case/amr.md` (kalibr calibration flow). Facts re-verified 2026-06; only what the docs/repos state.

## Table of contents

- [When to calibrate (and when not to)](#when-to-calibrate-and-when-not-to)
- [1. Stereo camera calibration (hobot_stereonet)](#1-stereo-camera-calibration-hobot_stereonet)
- [2. IMU configuration & intrinsic parameters](#2-imu-configuration--intrinsic-parameters)
- [3. Camera–IMU extrinsic calibration (kalibr)](#3-cameraimu-extrinsic-calibration-kalibr)
- [4. VIO (hobot_vio) prerequisites](#4-vio-hobot_vio-prerequisites)
- [5. Timestamp synchronization](#5-timestamp-synchronization)
- [6. Common pitfalls](#6-common-pitfalls)
- [Quick lookup: which calibration, which scenario](#quick-lookup-which-calibration-which-scenario)

---

## When to calibrate (and when not to)

| Scenario | Calibrate? | What to produce |
|----------|-----------|-----------------|
| Stereo depth via `hobot_stereonet` | ✅ Yes — §1 | `left.yaml`, `right.yaml`, `extrinsics.yaml` |
| VIO via `hobot_vio` (camera + IMU fusion) | ✅ Yes — §1 + §2 + §3 | Camera intrinsics/extrinsics + IMU params + cam↔IMU extrinsics |
| AMR / SLAM (official app case) | ✅ Yes — full kalibr flow (§3) | All of the above + lidar–camera extrinsics |
| Single-camera object detection (YOLO etc.) | ❌ No | No calibration needed; the model handles raw images |
| Audio / speech recognition | ❌ No | No camera/IMU involved |
| Livox lidar standalone | ❌ No | Lidar is factory-calibrated; just configure networking |

> **Rule of thumb:** calibration is needed when you fuse multiple sensors (stereo pair, camera+IMU, camera+lidar) or when depth accuracy matters. For single-sensor AI inference, skip it.

---

## 1. Stereo camera calibration (hobot_stereonet)

> Source: [hobot_stereonet](https://github.com/D-Robotics/hobot_stereonet) repo README (calibration section), TROS docs `boxs/spatial/hobot_stereonet`. Board support: X5 / X5 Module / S100 / S100P.

### 1.1 Why calibration matters

`hobot_stereonet` computes disparity from a left/right stereo pair. Without accurate intrinsics (focal length, distortion coefficients) and extrinsics (rotation + translation between the two cameras), the disparity-to-depth conversion produces noisy or meaningless results. **An uncalibrated stereo pair is the #1 cause of "depth map is all noise."**

### 1.2 Checkerboard requirements

- **Pattern:** a standard checkerboard (alternating black/white squares). The official AMR case also mentions **AprilGrid** as an alternative.
- **Size:** square side length should be **known precisely** (measure with calipers). A common choice is 30–50 mm per square.
- **Coverage:** capture **≥15–20 images** at varying angles, distances, and positions covering the full field of view. More coverage → better calibration.
- **Lighting:** even, non-glare lighting. Avoid reflections off the checkerboard surface (matte material preferred).

### 1.3 Capturing calibration images

**Prerequisite:** the stereo camera must be bringing up both eyes. Verify with:

```bash
source /opt/tros/humble/setup.bash    # S600: /opt/tros/jazzy/setup.bash
ros2 launch mipi_cam mipi_cam_dual_channel.launch.py mipi_image_width:=1280 mipi_image_height:=1088
# Verify both eyes are publishing:
ros2 topic list | grep -E "image_left|image_right"
```

For the GS130W / GS130Wi stereo cameras, the `mipi_cam` dual-channel launch produces left and right raw images. For a ZED camera, use `hobot_zed_cam` instead.

**Capture approach:**
1. Hold the checkerboard at various poses (tilt, pan, different distances, cover all corners of the FOV).
2. For each pose, save the left and right frames **simultaneously** (they must be timestamp-aligned).
3. A simple capture script or `ros2 bag record` can grab synchronized left/right pairs.

### 1.4 Producing calibration files

The calibration produces three YAML files:

| File | Contents | Format |
|------|----------|--------|
| `left.yaml` | Left camera intrinsics (K matrix, distortion coeffs) | ROS2 `sensor_msgs/CameraInfo`-style or Kalibr format |
| `right.yaml` | Right camera intrinsics (same structure) | Same |
| `extrinsics.yaml` | Left↔Right extrinsics: rotation matrix R (3×3) + translation vector T (3×1) | Kalimir-style `T_cn_cnm` or a custom YAML |

**Tools for generating these files:**
- **Kalibr** (officially recommended for the AMR case) — runs in a Docker container, takes ROS bags as input, outputs the full calibration including cam–IMU extrinsics (see §3).
- **OpenCV `cv2.calibrateCamera` / `cv2.stereoCalibrate`** — for a pure stereo-only workflow; lighter weight, no Docker needed.
- **Community calibration scripts** — some users share board-specific scripts; verify the output format matches what `hobot_stereonet`'s launch expects.

### 1.5 Pointing the launch at the calibration files

After calibration, pass the file paths to `hobot_stereonet`'s launch:

```bash
source /opt/tros/humble/setup.bash    # S600: jazzy
ros2 launch hobot_stereonet hobot_stereonet.launch.py \
    left_camera_intrinsic_file:=/path/to/left.yaml \
    right_camera_intrinsic_file:=/path/to/right.yaml \
    extrinsic_file:=/path/to/extrinsics.yaml
```

> The exact parameter names may vary by version — check with `ros2 launch hobot_stereonet hobot_stereonet.launch.py --show-args` on your board. The repo README documents the expected file paths and formats.

### 1.6 Verifying calibration quality

```bash
# Check that depth is publishing and non-trivial:
ros2 topic echo /StereoNetNode/stereonet_depth --once

# Visual check — the depth visualization should show structure, not noise:
ros2 topic echo /StereoNetNode/stereonet_visual --once
```

A well-calibrated stereo pair produces a depth map where:
- Edges of objects are sharp (not smeared)
- Flat surfaces have smooth depth (not speckled)
- The depth values are reasonable for the scene (e.g. a wall at 2 m reads ~2000 mm)

---

## 2. IMU configuration & intrinsic parameters

> Source: [accessories_doc](https://github.com/D-Robotics/accessories_doc) IMU module docs, [rdk-imu-module-sdk](https://github.com/D-Robotics/rdk-imu-module-sdk) repo. Two IMU chips are in the RDK ecosystem: **BMI088** (standalone RDK IMU Module + S100/S600 MCU boards) and **ICM-42688-P** (built into GS130Wi stereo camera).

### 2.1 BMI088 (RDK IMU Module)

The BMI088 is **factory-calibrated** — you do not run a traditional checkerboard-style intrinsic calibration. Instead, you configure the operating parameters (range, ODR, bandwidth) to match your application:

| Parameter | Options | Default (SDK) | Notes |
|-----------|---------|---------------|-------|
| Accel range | ±3/6/12/24 g | ±12 g | Higher range = lower sensitivity |
| Gyro range | ±125/250/500/1000/2000 dps | ±1000 dps | |
| Accel ODR | 12.5–1600 Hz | 800 Hz | |
| Gyro ODR | 100–2000 Hz | 1000 Hz | |
| FIFO mode | — | 256, OVERWRITE | |
| Noise density (accel) | — | 70 µg/√Hz | From datasheet |
| Noise density (gyro) | — | 2.8 mdps/√Hz (ICM) / 0.5 dps offset (BMI) | |

**Key fact:** the BMI088's accel and gyro are two **independent, unsynchronized** devices. The SDK's `read_fused()` function does linear interpolation to time-align the 6 axes. For ROS2, the `rdk_imu_module` node handles this fusion internally and publishes `sensor_msgs/Imu`.

**ROS2 node configuration** — the node maps all config parameters to ROS2 params:

```bash
ros2 launch rdk_imu_module rdk_imu.launch.py
# Key params (check --show-args for the full list):
#   frame_id (default: imu_link)
#   fuse_by (reference side for fusion)
#   max_age_ns (fusion time tolerance, recommended ≥3× ODR period)
#   publish_rate
#   imu_topic (default: /rdkimu/data)
```

### 2.2 ICM-42688-P (GS130Wi built-in)

The GS130Wi stereo camera has a built-in ICM-42688-P 6-axis IMU. It is accessed through the right-eye MIPI connector (pins 20/21 multiplex SCL/SDA with the camera). Key specs:

| Parameter | Value |
|-----------|-------|
| Gyro noise | 2.8 mdps/√Hz |
| Gyro range | ±15.625–2000 dps (8 steps) |
| Accel noise | 70 µg/√Hz |
| Accel range | ±2/4/8/16 g |

The GS130Wi has an **IMU interrupt-select switch** (LPWM / EXT):
- **LPWM mode:** IMU INT2 → right-eye TRIGL/FSYNC → **camera–IMU hardware sync** (enables timestamp-aligned camera + IMU data — critical for VIO).
- **EXT mode:** IMU INT2 → external connector (for external triggering).

> For VIO (hobot_vio) or any camera+IMU fusion, set the switch to **LPWM** to get hardware-synchronized timestamps.

### 2.3 IMU intrinsic calibration (advanced, rarely needed)

For high-precision applications, you may need to calibrate:
- **Bias (zero-rate offset):** the BMI088 datasheet specifies 20 mg (accel) / 0.5 dps (gyro) zero offset. The SDK reads raw values; if the sensor is stationary and readings are non-zero, that's bias.
- **Scale factor:** typically factory-calibrated; rarely needs user correction.
- **Allan variance analysis:** for characterizing noise (random walk) — use tools like `imu_utils` or `kalibr_allan`.

> For most RDK robot applications, the factory calibration + correct range/ODR configuration is sufficient. Full IMU intrinsic calibration is needed only for high-precision SLAM or long-duration dead reckoning.

---

## 3. Camera–IMU extrinsic calibration (kalibr)

> Source: `rdk_x_doc` `docs/06_Application_case/amr.md` (calibration step). The official AMR case uses **Kalibr** in a Docker container.

### 3.1 What kalibr does

[Kalibr](https://github.com/ethz-asl/kalibr) is the ETH Zürich calibration toolbox that solves for:
- Camera intrinsics (pinhole + distortion)
- Camera–IMU extrinsics (rotation + translation camera↔IMU)
- IMU intrinsics (bias, scale factor — optionally)

It takes **ROS bags** as input (synchronized camera + IMU streams recorded while moving a calibration target).

### 3.2 The official AMR calibration flow

From the AMR app case ([app-cases.md](app-cases.md)):

1. **Capture** — record synchronized camera + IMU data while moving a checkerboard/AprilGrid in front of the sensors. The official case uses `ros1_bridge` to convert ROS2 topics into a **ROS1 bag** (Kalibr runs on ROS1).

2. **Calibration order** (important — each step builds on the previous):
   | Step | What | Tool/Method |
   |------|------|-------------|
   | ① | Stereo intrinsics (left + right) | Kalibr `calibration_cameras` |
   | ② | Monocular intrinsics (ToF / RGB) | Kalibr (if separate camera) |
   | ③ | IMU parameters | Kalibr `calibration_imu` (or factory defaults) |
   | ④ | Camera↔IMU extrinsics | Kalibr `calibration_camera_imu` |

3. **Output** — Kalibr produces a `calibration_result_*.yaml` containing all intrinsics/extrinsics in a unified format.

### 3.3 Running kalibr (official Docker)

The official AMR documentation provides a Docker image with Kalibr pre-installed. The general flow:

```bash
# On a PC (not the board) — Kalibr needs x86 + ROS1 environment
# 1. Record a ROS bag on the board:
ros2 bag record -o calibration.bag /image_left_raw /image_right_raw /imu_data

# 2. Convert to ROS1 bag (needs Ubuntu 20.04 with both ROS1 + ROS2):
ros2 run ros1_bridge bag_converter --ros2-bag calibration.bag --ros1-bag calibration_ros1.bag

# 3. Run Kalibr in Docker (official image):
docker run -it --rm -v $(pwd):/data kalibr:latest
# Inside the container:
kalibr_calibrate_cameras --bag /data/calibration_ros1.bag --models pinhole-radtan pinhole-radtan --target checkerboard
kalibr_calibrate_imu --bag /data/calibration_ros1.bag --cam calibration_result_cam.yaml --imu calibration_result_imu.yaml
```

> **Prerequisite:** the recording must have **synchronized timestamps** (§5). If the camera and IMU clocks drift, Kalibr will fail or produce garbage extrinsics.

### 3.4 When to skip kalibr

- **Pure stereo depth (no IMU):** you only need §1 (stereo intrinsics + extrinsics). OpenCV's `stereoCalibrate` is sufficient.
- **Factory self-calibrated stereo:** the `stereo_imu_cam` (hobot_mipi_cam) node is documented as "self-calibrated" — some stereo modules ship with pre-calibrated intrinsics. Check if your module already includes calibration files before running a full Kalibr flow.
- **Single-camera AI (no depth/VIO):** no calibration needed at all.

---

## 4. VIO (hobot_vio) prerequisites

> Source: TROS docs `boxs/spatial/hobot_vio`. Board support: X3 / X5 / X5 Module.

`hobot_vio` is a visual-inertial odometry node that fuses camera + IMU data to estimate motion trajectory. Its prerequisites:

| Requirement | Detail |
|-------------|--------|
| Camera intrinsics | Must be calibrated (§1 or Kalibr §3) |
| IMU params | Must be configured (§2) — correct range/ODR, low bias |
| Cam↔IMU extrinsics | Must be calibrated (§3) — Kalibr `calibration_camera_imu` |
| Timestamp sync | Camera and IMU must be hardware-synchronized (§5) |
| Default topics | `/camera/infra1/image_rect_raw` (image) + `/camera/imu` (IMU) — RealSense by default |
| Launch | `ros2 launch hobot_vio hobot_vio.launch.py` |

> hobot_vio defaults to RealSense (which has built-in calibrated camera+IMU). For D-Robotics stereo cameras (GS130W/Wi + BMI088/ICM-42688-P), you must provide the calibration files and ensure hardware timestamp sync via the FSYNC/INT2 mechanism.

---

## 5. Timestamp synchronization

> Source: [hobot_stereonet](https://github.com/D-Robotics/hobot_stereonet) repo (timestamp skew warning), [accessories_doc](https://github.com/D-Robotics/accessories_doc) GS130Wi docs (FSYNC/INT2 hardware sync).

Timestamp alignment between sensors is the **second most common cause of bad stereo depth / VIO** (after uncalibrated intrinsics).

### 5.1 Stereo left/right timestamp skew

`hobot_stereonet` explicitly warns: **left/right timestamp skew > 30 ms badly degrades disparity accuracy.** The stereo pair must capture frames at the same instant.

**Solutions:**
- **Hardware FSYNC:** the GS130W/Wi camera supports FSYNC (frame sync) — both sensors share the same trigger pulse. The `mipi_cam` dual-channel launch should be configured to use hardware sync, not software-triggered capture.
- **PTP/gPTP time sync:** on the S-series, use PTP (§5 PTP in [s-advanced.md](../../rdk-board-delegate/references/s-advanced.md)) to align clocks across multiple boards/sensors.

### 5.2 Camera–IMU timestamp sync (for VIO)

For VIO (`hobot_vio`) or any camera+IMU fusion, the camera frame timestamp and the IMU sample timestamp must be aligned.

**GS130Wi's built-in solution:** the IMU interrupt-select switch set to **LPWM** routes the IMU's INT2 to the camera's FSYNC pin, creating **hardware-synchronized camera + IMU timestamps**. This is the recommended configuration for VIO with GS130Wi.

**BMI088 standalone module:** the SDK uses CLOCK_MONOTONIC timestamps captured via GPIO interrupts. The ROS2 node publishes these directly. If the camera is also using CLOCK_MONOTONIC (not hardware time), there may be software-level skew — use Kalibr's time-sync estimation to correct for constant offset.

### 5.3 Verifying timestamp alignment

```bash
# Record a short bag and check the timestamps:
ros2 bag record -o sync_test.bag /image_left_raw /image_right_raw /imu_data
ros2 bag info sync_test.bag

# Inspect message timestamps:
ros2 bag play sync_test.bag
ros2 topic echo /image_left_raw --field header.stamp
ros2 topic echo /image_right_raw --field header.stamp
# The two stamps should be within ~1 ms of each other
```

---

## 6. Common pitfalls

| ❌ Don't | ✅ Do |
|---------|------|
| Run hobot_stereonet without calibration files | Generate `left.yaml`/`right.yaml`/`extrinsics.yaml` first (§1) |
| Use a blurry or poorly-lit checkerboard | Matte surface, even lighting, precise square measurement |
| Capture too few calibration images | ≥15–20 images covering all FOV corners and angles |
| Ignore left/right timestamp skew | Verify < 30 ms; use FSYNC hardware sync or PTP |
| Set GS130Wi IMU switch to EXT for VIO | Use LPWM for camera–IMU hardware sync |
| Skip Kalibr for VIO/SLAM | Cam↔IMU extrinsics are essential — full Kalibr flow (§3) |
| Assume BMI088 needs no config | Set range/ODR/bandwidth to match your app (§2) |
| Forget `ros1_bridge` for Kalibr | Kalibr runs on ROS1 — convert ROS2 bags (Ubuntu 20.04 dual-ROS) |
| Mix BMI088 and ICM-42688-P configs | They are different chips with different specs and drivers |
| Use unverified community calibration scripts | Verify output format matches the launch's expected params |

---

## Quick lookup: which calibration, which scenario

| Robot scenario | Calibration needed | Key files | Tool |
|----------------|-------------------|-----------|------|
| Stereo depth only | Stereo intrinsics + extrinsics | `left.yaml`, `right.yaml`, `extrinsics.yaml` | OpenCV `stereoCalibrate` or Kalibr |
| VIO (hobot_vio) | Stereo + IMU + cam↔IMU extrinsics | All of the above + `calibration_result.yaml` | Kalibr (full flow) |
| AMR / SLAM | Everything + lidar–camera extrinsics | All of the above + lidar extrinsics | Kalibr + manual lidar–camera |
| Line-follower (CNN) | None | — | No calibration (model handles raw images) |
| Object detection (YOLO) | None | — | No calibration needed |
