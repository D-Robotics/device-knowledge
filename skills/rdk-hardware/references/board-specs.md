# RDK 板型规格对照

> 来源:整理自 D-Robotics RDK 官方文档、工具链与社区实践,逐条保留出处链接;由 device-knowledge 知识库忠实转换而来,未改写技术事实。

6 款 RDK 板型的硬件规格与探测标识,供选型、命令适配与设备识别参考。

## RDK X3 (`rdk-x3`)

- **SoC**:Sunrise 3 (X3J3)
- **算力**:5 TOPS (BPU)
- **CPU**:Quad-core Cortex-A53 @1.5GHz
- **内存**:2 GB
- **模型格式**:.bin (Bernoulli2)
- **诊断命令**:`hrut_smi`
- **运行时路径**:/opt/tros/humble
- **系统 Python**:/usr/bin/python3.8
- **推理库**:bpu_infer_lib_x3
- **GPIO**:40 针,28 路 GPIO,I2C×2/SPI×1/UART×3/PWM×2,3.3V
- **摄像头**:X3 **主板 mipi×1**(1 路 MIPI CSI,接口2,2-lane);**X3 Module 载板 mipi×3**(CAM0 2lane / CAM1 4lane / CAM2 2lane)
- **USB**:主板 USB3.0 Type-A×1 + USB2.0 Type-A×2 + Micro USB2.0 Device×1(芯片 1 路 USB 经 HUB 扩展)
- **探测标识**:`x3`、`X3`、`sunrise3`、`j3`、`xj3`、`X3J3`
- **已知限制**:Max 5 TOPS — heavy models (YOLOv5x, large transformers) will be very slow;2 GB RAM — models larger than ~500 MB will OOM;Only one USB 3.0 host port on the development kit — multi-camera USB bandwidth is limited;Bernoulli2 BPU — limited operator support, no Transformer/Attention ops

## RDK X5 (`rdk-x5`)

- **SoC**:Sunrise 5
- **算力**:10 TOPS (BPU)
- **CPU**:Octa-core Cortex-A55 @1.5GHz
- **内存**:4 GB / 8 GB(两个 SKU)
- **模型格式**:.bin (Bayes)
- **诊断命令**:`hrut_bpuprofile -b 0`
- **运行时路径**:/opt/tros/humble
- **系统 Python**:/usr/bin/python3.10
- **推理库**:bpu_infer_lib_x5
- **GPIO**:40 针,28 路 GPIO,I2C×3/SPI×2/UART×5/PWM×8,3.3V
- **摄像头**:mipi×2(2 x 4-lane MIPI CSI-2)、usb×4(USB 3.0)
- **探测标识**:`x5`、`X5`、`sunrise5`、`Sunrise 5`
- **已知限制**:LLM limited to ≤2B parameter quantized models on-device;Bayes BPU — partial Attention op support, some Transformer models may fail conversion

## RDK Ultra (`rdk-ultra`)

- **SoC**:Sunrise 5 Ultra
- **算力**:96 TOPS (BPU)
- **CPU**:Octa-core Cortex-A55
- **内存**:8 GB
- **模型格式**:.bin (Bayes)
- **诊断命令**:`hrut_bpuprofile -b 0`
- **运行时路径**:/opt/tros/humble
- **系统 Python**:/usr/bin/python3.10
- **推理库**:bpu_infer_lib_x5
- **GPIO**:40 针,28 路 GPIO,I2C×3/SPI×2/UART×5/PWM×8,3.3V
- **摄像头**:mipi×4(4-lane MIPI CSI-2)、usb×4(USB 3.0)
- **探测标识**:`ultra`、`Ultra`、`RDK Ultra`
- **已知限制**:Higher power consumption — needs active cooling (12V/3A DC);Same Bayes architecture as X5 — model .bin compatible but performance scaled up

## RDK S100 (`rdk-s100`)

- **SoC**:S100 (Nash)
- **算力**:80 TOPS (BPU)
- **CPU**:Hexa-core Cortex-A78AE @1.5GHz + Quad-core Cortex-R52+ MCU (1× DCLS, 1× Split-Lock)
- **内存**:12 GB
- **模型格式**:.hbm (Nash;板端 hbm_runtime 加载)
- **诊断命令**:`hrut_bpuprofile`
- **运行时路径**:/opt/tros/humble
- **系统 Python**:/usr/bin/python3.10
- **推理库**:hbm_runtime(pip 包 `hbm-runtime`,加载 `.hbm` 模型)
- **40PIN 实际可用**:I2C×2(I2C5 脚3/5、I2C4 脚27/28)、UART×1(UART2 脚8/10,与 I2C5 拨码复用)、SPI×1(SPI0,2 片选)、LPWM×2,3.3V。注:I2C×4/SPI×2/UART×6 是 SoC 级总数,更多总线在 MCU/Camera 100-Pin 扩展口
- **电源**:12~20V DC,Max 150W(典型 70W@12V/5.5A,极限 150W@20V/7.5A),随附 90W 适配器
- **摄像头**:mipi(3 x 4-lane MIPI CSI-2 via the camera expansion board)、gmsl×4(Fakra-Mini 4-in-1 GMSL2 on the camera expansion board)、usb×4(USB 3.0)
- **存储**:板载 64GB eMMC + M.2 Key M(PCIe Gen3×1)NVMe SSD
- **显示**:HDMI 最高 2K@60Hz(2560×1440)
- **网络**:双千兆 RJ45;**eth1 出厂固定静态 IP `192.168.127.10`(管理口)**,eth0 走 DHCP/手动
- **默认用户**:官方镜像默认同时存在 `sunrise/sunrise`(普通)与 `root/root`(超级)
- **探测标识**:`s100`、`S100`、`RDK S100`、`rdk_s100`
- **已知限制**:12-20V DC 供电，功耗高于 X5;Nash BPU 模型格式与 Bayes(X5) 不兼容，需重新编译;MIPI/GMSL 相机需配扩展板

## RDK S100P (`rdk-s100p`)

- **SoC**:S100P (Nash)
- **算力**:128 TOPS (BPU)
- **CPU**:Hexa-core Cortex-A78AE @2.0GHz + Quad-core Cortex-R52+ MCU (1× DCLS, 1× Split-Lock)
- **内存**:24 GB
- **模型格式**:.hbm (Nash;板端 hbm_runtime 加载)
- **诊断命令**:`hrut_bpuprofile`
- **运行时路径**:/opt/tros/humble
- **系统 Python**:/usr/bin/python3.10
- **推理库**:hbm_runtime(pip 包 `hbm-runtime`,加载 `.hbm` 模型)
- **40PIN 实际可用**:I2C×2(I2C5 脚3/5、I2C4 脚27/28)、UART×1(UART2 脚8/10,与 I2C5 拨码复用)、SPI×1(SPI0,2 片选)、LPWM×2,3.3V。注:I2C×4/SPI×2/UART×6 是 SoC 级总数,更多总线在 MCU/Camera 100-Pin 扩展口
- **电源**:12~20V DC,Max 150W(典型 70W@12V/5.5A,极限 150W@20V/7.5A),随附 90W 适配器
- **摄像头**:mipi(3 x 4-lane MIPI CSI-2 via the camera expansion board)、gmsl×4(Fakra-Mini 4-in-1 GMSL2 on the camera expansion board)、usb×4(USB 3.0)
- **存储**:板载 64GB eMMC + M.2 Key M(PCIe Gen3×1)NVMe SSD
- **显示**:HDMI 最高 2K@60Hz(2560×1440)
- **网络**:双千兆 RJ45;**eth1 出厂固定静态 IP `192.168.127.10`(管理口)**,eth0 走 DHCP/手动
- **默认用户**:官方镜像默认同时存在 `sunrise/sunrise`(普通)与 `root/root`(超级)
- **探测标识**:`s100p`、`S100P`、`RDK S100P`、`rdk_s100p`
- **已知限制**:Nash BPU 模型格式与 Bernoulli2/Bayes 不兼容，需重新编译;高负载供电和散热要求高于 X 系列，长时间满载必须留足电源余量;MIPI/GMSL 相机需配扩展板

## RDK S600 (`rdk-s600`)

- **SoC**:S600 (Nash)
- **算力**:最高 **560 TOPS**(4× BPU Nash core)
- **CPU**:18× Cortex-A78AE @2.0GHz
- **MCU**:6× Cortex-R52+(1× DCLS + 2× Split-Lock)
- **内存**:32 GB / 64 GB LPDDR5(256-bit，up to 6400MT/s)
- **存储**:64/256 GB UFS 3.1 + M.2 Key M（NVMe SSD）
- **模型格式**:.hbm (Nash;板端 hbm_runtime 加载)
- **系统**:**Ubuntu 24.04 + TROS Jazzy**(`/opt/tros/jazzy/`、`/opt/ros/jazzy/`;**注意不是 Humble**)
- **诊断命令**:`hrut_bpuprofile`(以实际镜像为准);通用兜底 `cat /sys/devices/system/bpu/bpu0/ratio`
- **推理库**:hbm_runtime(pip 包 `hbm-runtime`，加载 `.hbm` 模型)
- **电源**:12~28V DC,4-pin Microfit,最大电流 16A;官方适配器 24V/最高 8A
- **存储接口**:UFS 3.1 + M.2 Key M(PCIe **Gen4×2**)NVMe SSD
- **显示**:HDMI 最高 2K@60Hz(2560×1440)
- **网络**:2× 1GbE + **2× 10GbE** + 1× 1GbE(MCU 域)RJ45。**eth1 出厂固定静态 IP `192.168.127.10`(管理口)**,eth0 走 DHCP/手动
- **摄像头**:mipi×2(2× 22-pin MIPI，J11/J13)、usb×6(USB 3.2 Gen1 Type-A，Host)
- **CAN**:Main 域 CAN×4(J17) + MCU 域 CAN×5(J16)
- **数字 IO**:**无标准 40PIN 排针**;外扩走自锁连接器(2×10-pin、1×12-pin、1×14-pin),数字 IO **1.8V 电平**(注意非 3.3V),UART6/UART7 走 10-pin、SPI1 走 14-pin
- **型号**:RDK S600 32G(`KS6X032064C`，32GB/64GB UFS)、RDK S600 64G(`KS6X064256C`，64GB/256GB UFS)
- **探测标识**:`s600`、`S600`、`RDK S600`、`rdk_s600`
- **已知限制**:Nash BPU 产物 `.hbm` 与 X 系列(`.bin`)不兼容，需对应工具链重编;**系统是 Ubuntu 24.04 / ROS2 Jazzy，TROS 路径(`/opt/tros/jazzy/`)、`apt` 包名(`tros-jazzy-*`)与命令与 S100(22.04/Humble)不同，别照搬**;高算力高功耗，需外接电源 + 良好散热
