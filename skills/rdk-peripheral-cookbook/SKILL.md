---
name: rdk-peripheral-cookbook
description: 当用户要在 RDK 上驱动 GPIO/I2C/SPI/UART、PWM 舵机、直流/步进/无刷电机、LED/WS2812、音频(ALSA),或做外设接线时的跨平台引脚参照、libgpiod、零驱动诊断时使用。本 skill 给外设实操驱动;纯 GPIO 引脚编号事实/各板差异走 rdk-hardware(本 skill 接线时引用它),设备报错排查走 rdk-board-knowledge。
---

# RDK 外设驱动食谱

> 来源:整理自 D-Robotics RDK 官方文档、工具链与社区实践,逐条保留出处链接;由 device-knowledge 知识库忠实转换而来,未改写技术事实。

## 何时用

要在 RDK 上**真正驱动一个外设**(点灯、转电机、读传感器、播放/录音、接舵机)、做跨平台引脚对照,或外设插上去**板子不识别/没驱动**需要排查时用本 skill。它给的是"怎么接、怎么发命令、怎么定位"的实操路径,不是子系统概念介绍。

外设操作按"先扫描确认地址/设备存在,再低频低占空比试探"的安全顺序;含可直接套用的驱动范式。详细接线表、代码与跨平台对照见 [硬件与系统参考](references/hardware-notes.md)。

## 安全铁律(每次外设供电前必查)

- **舵机/电机/WS2812 灯带绝不从 40PIN Pin 2/4 取 5V**——哪怕单个 SG90,堵转/满载电流可拉低板子 5V 导致重启。一律外接 5V/6V 电源,信号线与板子**共 GND**。
- I2C 先 `i2cdetect -y <bus>` 确认地址出现再读写;PWM 先低频低占空比试探;改动持久化内核/启动链(`/boot`、设备树、MCU 固件)风险最高,RDK 上非必要不碰。
- RDK 特有坑:同一 40PIN 引脚可能默认配成 GPIO,需先用 **`sudo srpi-config` → `3 Interface Options` → 总线配置**(或板上 `/app/40pin_samples/` 脚本)切到 I2C/PWM/UART 模式,`/dev/i2c-X`、`pwmchip` 才出现。S100 上 I2C5/UART2 还要拨**拨码开关**二选一。**RDK S600 没有标准 40PIN**(自锁口、1.8V 电平),本食谱的 40PIN 接法不适用 S600,引脚事实见 rdk-hardware。

## 外设范式决策速查

| 需求 | 首选方案 |
| --- | --- |
| 跨板 GPIO / 不确定编号 | **`libgpiod`**(`gpiodetect`/`gpioinfo`/`gpiofind "GPIO17"`),勿猜 BCM 号 |
| 单舵机(1–2 路) | 板载硬件 PWM(50Hz/20ms,1.0–2.0ms 脉宽),外接电源 |
| 多舵机(≥3 路) | **PCA9685 + I2C**(默认 `0x40`),舵机电源走 PCA9685 的 V+ 端子 |
| 直流电机 | H 桥(TB6612/DRV8833/BTS7960)+ PWM 调速 + GPIO 控方向 |
| 步进电机 | 专用驱动(A4988/DRV8825/**TMC2209** 静音)+ STEP/DIR 两线 |
| 无刷 BLDC | 航模 ESC(50Hz PWM,可复用 PCA9685)或 ODrive/VESC(UART/CAN 闭环);S100 走 MCU 实时 |
| WS2812 RGB 灯带 | **SPI MOSI 模拟 800kHz 时序**(2.4MHz,`NeoPixel-SPI`),RPi 的 `rpi_ws281x` 不适用 RDK |
| 音频(无 TROS) | 标准 **ALSA**(`aplay -l`/`arecord`/`alsamixer`);**USB 声卡是万能兜底** |
| CAN(RDK 强项) | X5/S100 板载 CAN FD,`ip link set can0 type can bitrate 500000` |

## 零驱动诊断 SOP(设备不识别时,9 步通用,勿猜)

`dmesg | tail -50` → `lsusb` → `ls /dev/`(tty*/video*/i2c-*/spidev*/snd/) → `i2cdetect -l && i2cdetect -y <bus>` → `v4l2-ctl --list-devices` → `aplay -l`/`arecord -l` → `lsmod | grep` → `modinfo`/`modprobe` → `cat /proc/device-tree/…`。完整"症状→诊断"对表与应答模板见 references。

> 应答模板:先问清**板型 + 接口(USB / 40PIN I2C / UART / MIPI)+ 设备型号** → 跑 dmesg/lsusb/ls /dev 让用户贴回 → 按症状表定位 → 给最小可验证命令 → 验证后再谈封装 ROS2 节点/开机自启。

## 硬件参考主题

以下主题详见 [硬件与系统参考](references/hardware-notes.md):

- X5 板端 IO 加速库（x5-hobot-io / x5-hobot-utils）
- 40PIN 跨平台引脚与接口深度对照（外设驱动第一步）
- libgpiod：跨平台通用 GPIO 统一 API（强烈推荐）
- 舵机控制：单舵机到多路 PCA9685 标准方案
- 电机驱动三大范式
- LED：从单色到 WS2812 灯带
- 音频：ALSA 兜底链路（没装 TROS 时怎么播音 / 录音）
- 零驱动诊断 SOP（9 步通用外设探测流程）

## 参考资料

- [GPIO / 外设命令](references/gpio-commands.md)
- [硬件与系统参考(详细章节)](references/hardware-notes.md)
