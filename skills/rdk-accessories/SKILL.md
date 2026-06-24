---
name: rdk-accessories
description: 当用户使用 D-Robotics **官方成品配件**——GS130W/GS130Wi 双目深度相机、RDK IMU 模组(BMI088)、RDK S100/S600 的相机扩展板与 MCU 端口扩展板——做选型/接线/安装/驱动点亮时使用。这些是即插即用、配官方 SDK/IIO 驱动的成品模组,**区别于** rdk-peripheral-cookbook(用户自己 DIY 通用外设:裸 GPIO/I2C/电机/舵机/WS2812 接线驱动)与 rdk-hardware(板载接口本身的事实:40PIN/CAN/网口/算力)。问"GS130 怎么接""RDK IMU 模组怎么读数""S100 相机/MCU 扩展板有几路 CAN/GMSL"走本 skill;问"我自己买的某传感器怎么接 I2C"走 rdk-peripheral-cookbook;问"板子本身 40PIN 定义"走 rdk-hardware。
---

# RDK 官方配件

> 来源:整理自 D-Robotics 官方文档 accessories_doc(`docs/01_stereo_camera_gs130w/**`、`docs/02_stereo_camera_gs130wi/**`、`docs/03_imu_module/**`)、rdk_s_doc(`docs/01_Quick_start/01_hardware_introduction/01_rdk_s100/`、`02_rdk_s600/` 下相机/MCU 扩展板)、rdk_doc(`docs/03_Basic_Application/07_accessory_instructions/rdk_x5/imu/**`),以及 developer.d-robotics.cc。逐条保留出处,未改写技术事实。

本 skill 只覆盖 **D-Robotics 官方出的成品配件**:成品双目相机、成品 IMU 模组、官方扩展板。它们有官方线序定义、官方 SDK/IIO 驱动,接法和软件用法都有据可查——这是与"用户自己 DIY 接外设"的根本区别。

## 何时用 / 不用(先分流)

| 用户场景 | 用哪个 skill |
| --- | --- |
| GS130W/GS130Wi 双目相机怎么接、跑哪个 launch、22pin 线序 | **本 skill** |
| RDK IMU 模组(BMI088)怎么装、用 SDK 还是 IIO 驱动读数 | **本 skill** |
| S100/S600 相机扩展板有几路 MIPI/GMSL、MCU 扩展板几路 CAN | **本 skill** |
| 我自己买的某传感器/电机/灯带怎么接 GPIO/I2C/PWM | rdk-peripheral-cookbook |
| 板子**本身**的 40PIN 定义、CAN/网口、算力内存 | rdk-hardware |
| 模型部署、TROS 节点开发 | rdk-device / rdk-ros |

## 配件全景速查

| 配件 | 类型 | 核心芯片 | 接口 | 适用板 | 备注 |
| --- | --- | --- | --- | --- | --- |
| **GS130W** | 双目深度相机 | 2× SC132GS 全局快门 | 2× 22pin MIPI CSI-2 | X5 / X5M / S100(S100P) / S600 | **不支持 X3**(仅单路 MIPI);基线 80mm;无 IMU |
| **GS130Wi** | 双目+IMU | 2× SC132GS + ICM-42688-P | 2× 22pin MIPI + 3pin IMU 时间戳 | 同上 | 基线 70mm;比 GS130W 多内置 6 轴 IMU 与外部中断接口 |
| **RDK IMU 模组** | 6 轴 IMU 模组 | **Bosch BMI088** | 40PIN(I2C 或 SPI,跳线选) | X5 / X5M 直插;S100/S100P/S600 需跳线 | 含 3 LED+蜂鸣器+DS18B20 温度;**不支持 X3** |
| **S100 相机扩展板** | 扩展板 | MAX96712 解串器 | 2× MIPI + 4× GMSL | 仅 S100 系列 | SW2200/SW2201 切 MCLK-LPWM / 电平 |
| **S600 相机扩展板** | 扩展板 | 2× MAX96712 | **8× GMSL(无 MIPI)** | 仅 S600 系列 | 与 S100 不同,纯 GMSL |
| **S100/S600 MCU 端口扩展板** | 扩展板 | 板载 BMI088 | 5× CAN FD + 30pin + (S100 才有)RJ45 | 各自系列 | CAN 带 120Ω 终端电阻 |

详细规格、22pin 线序、IMU SDK/IIO 用法、扩展板接口表见 [配件总表](references/accessories-catalog.md)。

## 安全与接线铁律(每次插拔前必看)

- **接 FFC/FPC 排线必须先给开发板断电**——带电插拔易因接触打火或触点错位烧设备(官方反复强调)。FFC 是柔性导线,勿大力拉扯。
- **GS130W 与 GS130Wi 的 FFC 接入方向相反**,切勿照搬另一款的方向反接。
- **扩展板只配自家板**:S100 扩展板禁止接 S600,反之亦然;非兼容设备造成损坏不保修。安装时保持开发板与子板平行、均匀受力扣合、上固定螺丝。
- **GMSL 供电**:每路相机 12V 需求 ≤700mA 时由主板供;>700mA 必须外接 12V DC 适配器(S100 头规格内 2.5/外 6mm;S600 内 2.5/外 5.5mm)。每路扩展板最大 550mA@12V。
- **MIPI 相机电平要对**:S100 相机扩展板先用 SW2201 把目标接口切到相机要的 1.8V 或 3.3V,再插相机,否则可能通讯异常或损坏。

## 三条最常走的路径

**(1) 点亮 GS130W/GS130Wi 双目(TROS)**:升级 tros.b → `source /opt/tros/humble/setup.bash` → `ros2 launch mipi_cam mipi_cam_dual_channel.launch.py mipi_image_width:=1280 mipi_image_height:=1088`,再起 `mipi_cam_dual_channel_websocket.launch.py`,PC 浏览器开 `http://<RDK-IP>:8000` 看双目画面。背后是 hobot_mipi_cam(github.com/D-Robotics/hobot_mipi_cam)。

**(2) RDK IMU 模组(BMI088)读数**——两条路二选一:
- **官方 SDK**(推荐,不依赖 IIO 驱动):`git clone https://github.com/D-Robotics/rdk-imu-module-sdk` → `core` 下 `make test` 跑 C 示例(自动探测 I2C/SPI 与地址,400Hz 输出);Python `make install` 后 `sudo python3 examples/test_imu.py`;ROS2 `colcon build` 后 `ros2 launch rdk_imu_module rdk_imu.launch.py`,话题 `/rdkimu/data`(sensor_msgs/Imu)。
- **RDK OS IIO 驱动**(仅 X5/X5M):`sudo srpi-config` → `3 Interface Options` → `I6 IMU` → 选 `BMI088-I2C-Interface`(或 SPI)→ 重启 → 读 `/sys/bus/iio/devices/`。I2C 自检 `i2cdetect -y -r 5`。

**(3) 看扩展板能力**:直接查 [配件总表](references/accessories-catalog.md) 的扩展板接口表——别凭印象,S100 与 S600 的相机/MCU 扩展板接口数与供电规格不同。

## 易错点

- **两种 IMU 别混**:**RDK IMU 模组用 BMI088**(走 40PIN);**GS130Wi 内置的是 ICM-42688-P**(走相机 MIPI 接口复用的 I2C),X5 上还有单独的 **ICM42688 IMU 配件**。芯片不同 → 驱动名、IIO 设备名、寄存器都不同,别套用。
- **S100 MCU 扩展板的板载 IMU** 文档注明 `RDKS100_LNX_SDK_V4.0.2 暂未实现对应功能`,别假设开箱即用。
- GS130W/Wi 官方仅列 **SC132GS**(及 SC230ai)在 X5/S100/S100P 支持表,其他板"需用户自行开发驱动"。
- 文档里 launch 名/总线号(如 I2C-5)/IIO device 序号都可能与实际不符——**先 `ls`/`i2cdetect`/`cat name` 确认再用**。
