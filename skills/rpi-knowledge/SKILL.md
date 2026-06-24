---
name: rpi-knowledge
description: 当用户询问树莓派(Raspberry Pi 5/4B/CM4)的生态、GPIO、libcamera、AI HAT+ 时使用;本 skill 只讲树莓派平台本身,涉及与 RDK 的选型对比参见 rdk-ecosystem。
---

# 树莓派知识

> 来源:整理自 Raspberry Pi 官方文档与社区实践,逐条保留出处链接;具体规格与版本以官方为准。

树莓派起步知识:生态、板型规格与官方资料入口。

## 树莓派要点

- AI 推理:有 AI HAT+ 时用 Hailo 的 **HEF** 格式(按 13 TOPS / 26 TOPS 的 Hailo-8L/Hailo-8 变体选);无 HAT+ 时 Pi 5/4B/CM4 本身无 NPU,走 CPU / ONNX Runtime / PyTorch aarch64 builds。
- 摄像头:Pi 5 与新镜像走 **libcamera/rpicam**(旧 `raspistill`/`raspivid` 已废弃);显示栈随 OS 代际变化大,以当前 `/boot/firmware` 与 libcamera 状态为准。
- GPIO:用 BCM 编号。**Pi 5 引入 RP1 I/O 芯片,GPIO 寄存器在 RP1 不在主 SoC,经典 `RPi.GPIO`(直接 /dev/mem)在 Pi 5 上不可用** → Pi 5 用 **`gpiozero`(官方推荐)/ `lgpio` / `rpi-lgpio`**;Pi 4B/老板仍可用 RPi.GPIO。`libgpiod` 通用。
- 摄像头命令:新 OS(Bookworm+)工具已从 `libcamera-*` **更名为 `rpicam-*`**(`rpicam-still`/`rpicam-vid`/`rpicam-hello`),旧 `raspistill`/`raspivid` 早已废弃;底层仍是 libcamera。
- 发行版多为 Raspberry Pi OS / Debian / Ubuntu;包管理与内核固件路径以当前镜像为准。官方文档见 raspberrypi.com/documentation。

## 设备规格

- **Raspberry Pi 5** (`rpi-5`):BCM2712 (Cortex-A76 @2.4GHz) / 0 TOPS(无 NPU) / **2/4/8/16GB LPDDR4X**(16GB 已发售) / onnx
- **Raspberry Pi 4 Model B** (`rpi-4b`):BCM2711 (Cortex-A72 @1.8GHz) / 0 TOPS / **最高 8GB**(1/2/4/8GB) / onnx
- **Raspberry Pi Compute Module 4** (`rpi-cm4`):BCM2711 (Cortex-A72 @1.5GHz) / 0 TOPS / **最高 8GB**(1/2/4/8GB) / onnx
- 注:更新板型 **CM5 / Pi 500** 已发布,规格以 raspberrypi.com 为准。

## 官方资料

- [Raspberry Pi Documentation](https://www.raspberrypi.com/documentation/)
- [Raspberry Pi 5 Product Page](https://www.raspberrypi.com/products/raspberry-pi-5/)
- [Raspberry Pi AI HAT+](https://www.raspberrypi.com/products/ai-hat/)
