# RDK 官方配件总表

> 来源:D-Robotics accessories_doc(`docs/01_stereo_camera_gs130w/**`、`docs/02_stereo_camera_gs130wi/**`、`docs/03_imu_module/**` 含 `05_software/**`)、rdk_s_doc(`docs/01_Quick_start/01_hardware_introduction/01_rdk_s100/{02_camera,03_mcu_port}_expansion_board.md`、`02_rdk_s600/` 同名两文件)、rdk_doc(`docs/03_Basic_Application/07_accessory_instructions/rdk_x5/imu/{icm42688,rdk_imu_module}.md`),以及 archive.d-robotics.cc 下载件。逐节忠实整理,未改写技术事实;规格以官方规格书/pinlist 为单一事实源。

---

## 1. GS130W 双目深度相机

> 来源:`accessories_doc/docs/01_stereo_camera_gs130w/{01_product_overview,02_installation,03_quick_start,04_hardware,06_downloads}.md`

### 关键参数

| 名称 | 描述 |
| --- | --- |
| 传感器 | 2× SC132GS 全局快门(global shutter) |
| 分辨率 | 130 万,单路 1280×1080 |
| 最大帧率 | 120 fps |
| 典型配置 | 1280×1080@30fps 10-bit / @60fps 10-bit |
| 输出格式 | RAW RGB 12/10/8 bit |
| 双目基线 | 80 mm |
| FOV | H 115.6° / V 96.8° / D 157.2° |
| 视频接口 | MIPI CSI-2(2-lane),最大 2.4 Gbps |
| 特性 | HDR、40dB 信噪比、850/940nm 近红外增强、支持双目同步曝光与外部触发 |
| **无 IMU** | GS130W 不含 IMU(带 IMU 的是 GS130Wi) |

### 适用板卡

| 板卡 | 支持 | 说明 |
| --- | --- | --- |
| RDK X3 / X3 Module | **不支持** | 仅支持单路 MIPI |
| RDK X5 | 支持 | - |
| RDK X5 Module | 支持 | 需官方载板或其他载板 |
| RDK S100 / S100P | 支持 | **需安装 Camera 扩展板** |
| RDK S600 | 支持 | - |
| 其他双 MIPI 且线序相符的板 | 支持 | 需用户自行开发驱动 |

### 安装物料与接法

- 物料:GS130W 模组 + **2× FFC/FPC 线缆(22pin,0.5mm 间距,同面触点)**。
- 接 FFC 前**务必断电**;模组主 PCB 裸露,防金属异物短路。
- 模组侧:线缆触点朝向 PCB 板**反**方向,水平插入,锁紧。
- 开发板侧(X5):触点朝向网口方向,垂直插入。
- ⚠️ **GS130W 与 GS130Wi 接 FFC 方向相反,切勿混用反接。**
- 结构:两端各 2 个安装孔,4× M3 螺栓固定;装时垫圈+交替锁紧,防金属支架变形改变外参。

### 22pin MIPI Camera 接口线序(左右目相同)

连接器型号 AFC24-S22FIA-00(钜硕电子)。

| PIN | Name | PIN | Name |
| --- | --- | --- | --- |
| 1 | GND | 12 | N/A |
| 2 | MDN0 | 13 | GND |
| 3 | MDP0 | 14 | N/A |
| 4 | GND | 15 | N/A |
| 5 | MDN1 | 16 | GND |
| 6 | MDP1 | 17 | RESET(接 Sensor XSHUTDN,硬件复位) |
| 7 | GND | 18 | FSYNC(接 TRIGL/FSYNC,Slave 模式曝光使能) |
| 8 | MCN | 19 | GND |
| 9 | MCP | 20 | SCL(Sensor 配置) |
| 10 | GND | 21 | SDA(Sensor 配置) |
| 11 | N/A | 22 | 3V3 |

### 软件(TROS)

- 升级:`sudo apt update && sudo apt upgrade`;查版本 `apt show tros-humble`。
- 启动双目采集:`source /opt/tros/humble/setup.bash` → `ros2 launch mipi_cam mipi_cam_dual_channel.launch.py mipi_image_width:=1280 mipi_image_height:=1088`。
- Web 预览:再起 `ros2 launch mipi_cam mipi_cam_dual_channel_websocket.launch.py`,PC 浏览器开 `http://<RDK-IP>:8000`。
- hobot_sensor 抽象支持的相机型号(X5/X5M/S100/S100P):SC230ai(200W)、SC132gs(200W)。代码仓:<https://github.com/D-Robotics/hobot_mipi_cam>。

### 资料下载

- 3D STEP 图纸:archive.d-robotics.cc/downloads/hardware/accessories/gs130w/RDK Stereo Camera GS130W Community.STEP

---

## 2. GS130Wi 双目深度相机(带 IMU)

> 来源:`accessories_doc/docs/02_stereo_camera_gs130wi/{01,02,04,06}.md`

相对 GS130W 的差异:**内置 ICM-42688-P 六轴 IMU**,基线 70mm,单路像素 1080×1280。

### 关键参数(差异部分)

| 名称 | 描述 |
| --- | --- |
| 传感器 | 2× SC132GS + **ICM-42688-P 六轴 IMU** |
| 像素大小 | 1080×1280 |
| 双目基线 | 70 mm |
| FOV | H 96.8° / V 115.6° / D 157.2° |
| 陀螺仪 | 噪声 2.8 mdps/√Hz;量程 ±15.625 ~ 2000 dps(多档) |
| 加速度计 | 噪声 70 µg/√Hz;量程 ±2/4/8/16 g |
| 其余(分辨率/帧率/接口/速率) | 同 GS130W |

### 硬件接口(比 GS130W 多 3 项)

1. 右目 MIPI 接口:相机 + **IMU** 数据;2. 左目 MIPI 接口:仅相机;3. **外部中断接口**(3pin);4. **IMU 中断选择开关**(LPWM / EXT)。

- 安装物料多一根 **3PIN 线缆(1.25mm 超薄端子-杜邦)**,用于 IMU 硬件时间戳(是否接由软件程序决定)。连接器 5063-3AWB(文章济美)。
- 结构:两端各 1 安装孔,2× M2.5 螺栓。
- FFC 模组侧触点朝向 PCB **正**方向(与 GS130W 相反)。

### 右目 22pin 线序的 IMU 复用(与 GS130W 不同处)

| PIN | Name | 复用说明 |
| --- | --- | --- |
| 18 | FSYNC | 相机 TRIGL/FSYNC;**若 IMU 开关选 LPWM:接 IMU INT2,输入 Fsync 沿信号** |
| 20 | SCL | 相机 SCL **+ IMU SCL**(设置/读 IMU) |
| 21 | SDA | 相机 SDA **+ IMU SDA** |

左目接口线序与 GS130W 一致(无 IMU 复用)。

### 外部中断接口(3pin)与开关

| PIN | Name | 说明 |
| --- | --- | --- |
| 1 | INT1 | 引出 IMU INT1 |
| 2 | INT2 | 开关选 LPWM:N/A;选 EXT:引出 IMU INT2 |
| 3 | GND | - |

- **IMU 中断选择开关**切 INT2(PIN9)走向:**LPWM** = INT2 接右目 TRIGL/FSYNC(相机-IMU 硬同步),外部接口 PIN2 悬空;**EXT** = INT2 接外部中断接口 PIN2。

### 资料下载

- 规格书(中文 PDF)、3D STEP:archive.d-robotics.cc/downloads/hardware/accessories/gs130wi/

---

## 3. RDK IMU 模组(Bosch BMI088)

> 来源:`accessories_doc/docs/03_imu_module/{01,02,03,04,06}.md` + `05_software/{01_overview,02_c_api,03_python_api,04_ros2,05_iio}.md`;rdk_doc `rdk_x5/imu/rdk_imu_module.md`

**注意:这是官方独立 IMU 模组,芯片是 BMI088,走 40PIN;与 GS130Wi 内置的 ICM-42688-P 是两回事。**

### 关键参数

| 名称 | 描述 |
| --- | --- |
| 核心 | Bosch Sensortec **BMI088** 六轴(3 轴陀螺 + 3 轴加速度,16bit,出厂校准,低 TCO/TCS) |
| 加速度计量程 | ±3/6/12/24 g(零偏 20 mg) |
| 陀螺仪量程 | ±125/250/500/1000/2000 dps(零偏 0.5 dps) |
| 加速度采样 | 12.5/25/50/100/200/400/800/1600 Hz |
| 陀螺采样 | 100/200/400/1000/2000 Hz |
| 通信 | I2C / SPI(跳线选) |

### 板上器件

40PIN 接口(唯一对接口,PIN1 定义同 RDK X5)、3×5 排针(I2C/SPI 跳线帽切换)、2×7 核心板接口、3 颗 0603 LED(R/G/B,40PIN GPIO 驱动)、有源蜂鸣器(YS-SBZ9650DYB05)、**DS18B20 1-Wire 温度传感器**。

### 适用板卡

| 板卡 | 支持 | 说明 |
| --- | --- | --- |
| RDK X3 / X3M | **不支持** | - |
| RDK X5 / X5M | 支持 | 直插 40PIN |
| RDK S100 / S100P | 支持 | **无法直接安装,需跳线** |
| RDK S600 | 支持 | **无法直接安装,需跳线** |
| 其他 40PIN 板 | 支持 | 需自行适配驱动 |

### 通信方式切换

3×5 排针用 5 个跳线帽:中间 5PIN 接 "I2C" 丝印侧 → I2C;接 "SPI" 丝印侧 → SPI。

### 软件路线 A:官方 rdk-imu-module-sdk(不依赖 IIO,跨平台)

仓库 <https://github.com/D-Robotics/rdk-imu-module-sdk>(MIT)。原理:用户态 Linux I2C/SPI + 软件 FIFO + 高优先级子线程捕获 GPIO 用户态中断 + `gpiod.h` 硬件触发时间戳(CLOCK_MONOTONIC)实现精确时间戳。要求内核 >5.10 的 aarch64,有标准用户态 I2C/SPI 即可。

依赖:`sudo apt install build-essential cmake libgpiod-dev python3-pip`。

- **C**:`cd core && make`(产物 `out/test`,自动探测 I2C/SPI 与地址,400Hz 输出);`sudo ./out/test` 或 `make test`;`make install/uninstall` 装/卸库头。
- **Python**:先建过 `core`,再 `cd python && make` 出 `dist/*.whl`,`pip install dist/rdkimu-*.whl` 或 `make install`;`sudo python3 examples/test_imu.py`。
- **ROS2**:`source /opt/tros/*/setup.bash` → `cd ros2 && colcon build` → `source install/setup.bash` → `ros2 launch rdk_imu_module rdk_imu.launch.py`。

**API 调用顺序**(C/Python 一致):bus init → device init → enable → read_* → disable → deinit/destroy。
- 总线 init 三式:AUTO 自动搜 I2C/SPI 与地址(多 IMU 场景不可用)/ 指定 I2C(总线号+地址)/ 指定 SPI(总线号+片选+速率)。
- 设备 config 有整套量程/带宽/ODR/中断/FIFO 参数;提供 `RDK_IMU_X5_DEFAULT_CONFIG` 模板可改部分项(默认 accel 中断 INT1→gpiochip4 line2,gyro INT3→gpiochip3 line12,FIFO 256 OVERWRITE)。
- 读数:`fifo_available()` 查余量;`read_indep()` 读独立包(BMI088 accel/gyro 是两个独立设备、不同步,需看 `data.accel.valid`/`data.gyro.valid` 判哪侧有效);`read_fused(fuse_by, max_age_ns)` 一维线性插值出时间对齐 6 轴,`fuse_by` 指基准侧,`max_age_ns` 建议 ≥3× ODR 周期。
- 数据 `x,y,z`(accel m/s²,**gyro rad/s** —— SDK `gyro_data_scale` 含 `M_PI/180` 因子)+ `timestamp_ns`(CLOCK_MONOTONIC)+ **`valid==1` 表示有效**(SDK 成功读到数据时显式置 1,见 `core/src/rdkimu.c`)。

**ROS2 节点**:话题默认 `/rdkimu/data`(`sensor_msgs/msg/Imu`,frame_id 默认 `imu_link`,angular_velocity 单位 rad/s,orientation 未提供恒 (0,0,0,1) 且姿态协方差置 -1)。提供 `~/enable`、`~/disable` 两个 `std_srvs/srv/Trigger` 服务运行时暂停/恢复。可配参数 frame_id/fuse_by/max_age_ns/publish_rate/imu_topic/各 ODR 量程带宽/gpio chip-line 等,与 `rdk_imu_config_t` 一一对应。

### 软件路线 B:RDK OS BMI088 IIO 驱动(仅 X5/X5M,镜像 3.4.x,兼容 3.5.x)

`sudo srpi-config` → `3 Interface Options` → `I6 IMU`:
- I2C:选 `BMI088-I2C-Interface`;SPI:选 BMI088 的 SPI 项 → `Finish` → 重启。
- I2C 自检:`i2cdetect -y -r 5`(若一个 `UU` 一个 `69`,断电重启后再扫)。
- 读数:`ls /sys/bus/iio/devices/` → `cat /sys/bus/iio/devices/iio:deviceN/gyr_val`(N 以实际为准)。SPI 注册检查 `dmesg | grep BS_LOG`。
- 卸载:`srpi-config → I6 IMU → UNSET`,断电取下。

### 资料下载

BMI088/DS18B20 Datasheet、规格书、连接器说明、3D STEP:archive.d-robotics.cc/downloads/hardware/accessories/imu/

---

## 4. X5 上的 ICM42688 IMU 配件

> 来源:rdk_doc `rdk_x5/imu/icm42688.md`

- 6 轴 IMU(ICM42688),I2C 接入;驱动注册为独立陀螺仪 + 加速度计两个 IIO 设备。适用 X5/X5M,镜像 3.4.1+。
- 文档示例从 RDK 双目相机模组上引出("用模组上的传感器")。
- 配置:`sudo srpi-config` → `3 Interface Options` → `I6 IMU` → 选 ICM42688 → Finish 重启。
- 验证:`ls /sys/bus/iio/devices/`;`cat .../name` 应见 `icm42688-gyro` / `icm42688-accel`;读 `in_accel_x_raw`、`in_anglvel_x_raw`。
- device 序号以实际注册为准,先 `cat name` 确认再替换命令里的 device1/device2。

---

## 5. RDK S100 相机扩展板

> 来源:rdk_s_doc `01_rdk_s100/02_rdk_s100_camera_expansion_board.md`

仅适配 RDK S100 系列。提供 **2 路 MIPI 相机接口 + 4 路 GMSL**。

### 规格

| 名称 | 参数 |
| --- | --- |
| 解串器 | Maxim **MAX96712** |
| MIPI 连接器 | 2× 22-Pin MIPI CSI-2(J2200/J2201,4-Lane D-PHY) |
| GMSL 连接器 | Fakra-Mini 4in1(J2100,4 路 GMSL2) |
| 外部供电 | 12V DC,>700mA 时用,最大 2.4A |
| 工作温度 | 0~45℃ |

### 关键接口

- **J2000** 100Pin 连接器:与 S100 对接(MIPI CSI + GPIO + 12V/3.3V),需扣合并上固定螺丝。
- **J2001** DC 输入:GMSL 总需求 >700mA 时接(头内 2.5mm/外 6mm,12V)。
- **J2100** GMSL:4 路 GMSL2,同轴线供 12V,每路最大 550mA@12V;mini Fakra 4-in-1 z code,用官方推荐线缆。
- **J2200/J2201** MIPI:支持 1.8V/3.3V 逻辑电平;第 5 脚可选 LPWM 或 24MHz MCLK(板载有源晶体)。3V3 单路最大 500mA(light/deep sleep 时关断)。
- **SW2201** 电平切换:开关 1=MIPI 相机 1、2=相机 2,各切 3V3/1V8。
- **SW2200** 功能切换:第 5 脚切 LPWM / MCLK(每相机一位)。
- **D2000** 电源灯:绿常亮=已连且 3.3V 正常;熄灭=连接/3.3V 异常。

### 相机安装对照(官方表)

| 型号 | 硬件接口 | SW2200 | SW2201 电平 |
| --- | --- | --- | --- |
| IMX219(兼容树莓派5) | J2200/J2201 | lpwm | 亚博 1.8V / 微雪 3.3V |
| SC230AI 双目(V3) | J2200 & J2201 | lpwm | 3.3V |
| **SC132GS 双目** | J2200 & J2201 | lpwm | 3.3V |
| SG8S-AR0820C-5300-G2A | J2100 | - | - |
| LEC28736A11(X3C 模组) | J2100 | - | - |
| Intel RealSense D457 | J2100 | - | - |
| Intel RealSense D435i | USB | - | - |

接口定义 pinlist:archive.d-robotics.cc/downloads/hardware/rdk_s100/rdk_s100_camera_expansion_board/...pinlist_v1p0_0924.xlsx

---

## 6. RDK S600 相机扩展板

> 来源:rdk_s_doc `02_rdk_s600/02_rdk_s600_camera_expansion_board.md`(文档对应 V1P0)

仅适配 RDK S600 系列。与 S100 扩展板不同:**纯 8 路 GMSL,无 MIPI 接口**。

### 规格

| 名称 | 参数 |
| --- | --- |
| 解串器 | **2× MAX96712** |
| GMSL 连接器 | 2× FAKRA-Mini 4in1(共 8 路 GMSL2) |
| 外部供电 | 12V DC,>2.4A 时用,最大 4.8A |
| 工作温度 | 0~65℃ |

### 接口

- **J402** 板对板连接器:MIPI CSI+GPIO+12V/3.3V/1.8V。
- **J401** DC 输入:头内 2.5mm/外 **5.5mm**(注意与 S100 的 6mm 不同),12V。
- **J501/J601** GMSL:每个 4 路,共 8 路;每路最大 550mA@12V;同上 >700mA 需外接 DC。
- **D2000** 电源灯:绿常亮=已连且 3.3V 正常。
- 连接器:J401 DC-044B-D025、J402 DY11-080SB-1(KEL)、J501/J601 112038-161410(信翰)。

---

## 7. RDK S100 / S600 MCU 端口扩展板

> 来源:rdk_s_doc `01_rdk_s100/03_*`、`02_rdk_s600/03_*`(均对应 V1P0)

两块都板载 **BMI088 IMU**,以 CAN FD 为主。

### 规格对比

| 项 | **S100 MCU 扩展板** | **S600 MCU 扩展板** |
| --- | --- | --- |
| CAN FD | 5 路(最高 8Mbps,CAN5~9) | 5 路(CAN1~4,CAN10) |
| 30-pin | 最多 7×ADC / 2×IIC / 2×SPI | 同(7×ADC/2×IIC/2×SPI) |
| **RJ45 千兆网口** | **有**(U4,MCU 域) | **无** |
| 板载 IMU | BMI088,**SPI-5**(注:V4.0.2 SDK 暂未实现) | BMI088,**SPI-13** |
| CAN 120Ω 终端 | 各路跳帽选通(J3/J5/J7/J9/J11) | 单个开关 SW401 切换 |
| 100/80pin 对接 | J1(100-pin,配 FPC,丝印 MAIN↔主板 J23/SUB↔J1) | J301(80-pin,FPC 丝印 CB↔主板 J15/SUB↔J301) |
| 工作温度 / 尺寸 | 0~45℃ / 70×70×17mm | 0~65℃ / 70×70×17mm |
| 指示灯 | 绿"CONNECT"=5V 正常 | 绿"LINK"=5V 正常 |

### S100 CAN 通道-接口对照

| CAN | 连接器 | 120Ω 跳线 |
| --- | --- | --- |
| CAN5 | J2 | J3 |
| CAN6 | J4 | J5 |
| CAN7 | J6 | J7 |
| CAN8 | J8 | J9 |
| CAN9 | J10 | J11 |

### 30-pin 注意

- S100:light/deep sleep 时 VDD_5V/3V3/1V8 保持供电(最大 300/600/300mA);I2C9_SDA/SCL_3V3 作 GPIO 时禁接外部下拉。
- S600:30-pin 中 PIN11/13/15/16/19/20 等 IO 上电默认高/低须与 pinlist 的 Pull Up/Down 一致,禁加额外上下拉。
- pinlist:archive.d-robotics.cc/downloads/hardware/rdk_s100(或 rdk_s600)/.../mcu_port_expansion_board/...pinlist_v1p0*.xlsx
