# RDK CAN 与板级 IO 实操（X5 SocketCAN / S100·S600 MCU 域 CAN / S100 40PIN 拨码 / S600 自锁口）

> 来源:整理自 D-Robotics 官方文档,逐条保留出处;由 device-knowledge 知识库忠实转换而来,未改写技术事实。
> 主要出处:
> - rdk_doc `docs/07_Advanced_development/01_hardware_development/rdk_x5/can.md`(X5 CAN/CAN FD)
> - rdk_s_doc `docs/07_Advanced_development/05_mcu_development/09_mcu_can.md`(S100/S600 MCU 域 CAN)
> - rdk_s_doc `docs/03_Basic_Application/03_40pin_user_guide/01_s100/{01_40pin_define,04_uart,05_i2c}.md`(S100 40PIN)
> - rdk_s_doc `docs/03_Basic_Application/03_40pin_user_guide/02_s600/{01_ext_io,02_gpio,02_uart,04_spi}.md`(S600 自锁口)
> - 通道-连接器-120Ω 对照另见 `../../rdk-accessories/references/accessories-catalog.md` 第 7 节(MCU 端口扩展板)。

## 0. 先分清:哪块板的 CAN 是 SocketCAN,哪块是 MCU 域

| 板型 | CAN 形态 | 用什么操作 | 有没有 `can0` 网络设备 |
|------|----------|------------|------------------------|
| **RDK X5** | Linux **SocketCAN**(集成 TI TCAN4550,挂 SPI5) | `ip link` + `can-utils`(`cansend`/`candump`) | **有**,`ip link show can0` |
| **RDK S100** | CAN 控制器在 **MCU 域**(CAN0~9,默认 CAN5~9) | **CANHAL 库 + IPC** + `/app/Can` sample | **没有**,`ip link set canX` 不适用 |
| **RDK S600** | CAN 控制器在 **MCU 域**(CAN0~15,默认 CAN1~10) | 同 S100 | **没有** |
| RDK X3 / Ultra | 无板载 CAN(官方文档未提供) | — | — |

> **铁律**:看到有人在 S100/S600 上敲 `ip link set can0 type can ...` —— 那是 X5 的路子,S100/S600 上不存在该网络设备,得走 MCU 域 CANHAL。

---

## 1. RDK X5:标准 SocketCAN / CAN FD 完整 bringup

X5 集成 **TI TCAN4550**(CAN FD 控制器 + 收发器,挂在 SPI5,内核驱动 `ti,tcan4x5x`,`m_can/tcan4x5x-core.c`),支持经典 CAN 与 CAN FD。模块标称:经典 CAN 1Mbps、CAN FD 数据段 2Mbps。硬件端子 **SH1.0 1×3P**,板载一个 **120Ω 终端电阻开关**(闭合=接入)。

> **终端电阻**:距离 >1m 或速率 >125Kbps 时,闭合 X5 的 120Ω 开关,且对端设备也使能 120Ω,消除信号反射。

### 1.1 经典 CAN 回环自测(最快验证)

```bash
ip link set can0 down
ip link set can0 type can bitrate 125000
ip link set can0 type can loopback on
ip link set can0 up
ip -details link show can0          # 查配置确认 bitrate / loopback
candump can0 -L &                    # 后台收(别阻塞当前终端)
cansend can0 123#1122334455667788    # 发,立即应能收到
```

### 1.2 CAN FD 回环(仲裁域 + 数据域两段速率)

仲裁段 500K、数据段 2M:

```bash
ip link set can0 down
ip link set can0 type can bitrate 500000 dbitrate 2000000 fd on   # 仲裁域 + 数据域
ip link set can0 type can loopback on
ip link set can0 up
candump can0 -L &
cansend can0 123##300112233445566778899aabbccddeeff   # 注意是 ## :FD 帧,中间一位是 FD flags
```

> **语法点**:`cansend` 里 `#` 是经典帧、`##` 是 FD 帧(`##` 后第一字节是 FD flags,如 `3` = BRS|ESI)。`bitrate` 是仲裁域,`dbitrate` 是数据域,`fd on` 必带否则数据域速率不生效。

### 1.3 双机通信

两台设备配相同 `bitrate`,接线 **GND-GND / CAN_L-CAN_L / CAN_H-CAN_H**:

```bash
# 两端都先:
ip link set can0 down
ip link set can0 type can bitrate 125000
ip link set can0 up
# 一端收
candump can0 -L
# 另一端发
cansend can0 123#1122334455667788
```

### 1.4 can-utils 常用工具

| 工具 | 用途 | 示例 |
|------|------|------|
| `candump` | 抓包/过滤/记录 | `candump can0`;过滤 `candump can0,123:7FF`;记录 `candump -l can0`(生成 candump-日期.log) |
| `cansend` | 发单帧 | `cansend can0 123#1122334455667788` |
| `canplayer` | 回放 candump 日志 | `canplayer -I candump.log` |
| `cangen` | 生成测试流量 | `cangen can0 -I 1A -L 8 -D i -g 10 -n 100` |
| `cansequence` | 递增载荷+丢帧检测 | `cansequence can0` |
| `cansniffer` | 看数据变化 | `cansniffer can0` |

> 应用层用 Linux **SocketCAN**(`PF_CAN`/`SOCK_RAW`/`CAN_RAW`),写法与 TCP/IP 套接字近似,官方 can.md 末尾给了一段 C 收发例程可直接套。

---

## 2. RDK S100 / S600:MCU 域 CAN(不是 SocketCAN)

S100/S600 的 CAN 控制器在 **MCU 域**,负责物理收发;Acore(跑感知/应用的 Linux 侧)拿不到原始 CAN 外设,要靠 **CAN2IPC(MCU 侧)→ IPC 核间通信 → CANHAL(Acore 侧动态库)** 这条链路,应用通过 CANHAL 的 `canInit/canSendMsgFrame/canRecvMsgFrame/canDeInit` API 收发。**因此 `ip link`、`cansend`、`candump` 在 S100/S600 上不适用。**

### 2.1 容量与默认使能

| | S100 | S600 |
|---|------|------|
| 最多 controller | 10(CAN0~9) | 16(CAN0~15) |
| 默认使能 | CAN5~CAN9 | CAN1~CAN10(共引出 10 路) |
| 最高速率 | 8M(收发器实测验证到 5M) | 8M(同) |
| 扩展帧 | 支持 | **软件当前不支持扩展帧** |

### 2.2 S100 CAN:通道 ↔ 连接器 ↔ 120Ω 跳帽(MCU 扩展板)

5 路引到 MCU 扩展板的绿色 **3PIN 螺丝端子**(三角标=GND,中间=CAN_L,余 1 脚=CAN_H):

| CAN | 端子 | 120Ω 跳帽 |
|-----|------|-----------|
| CAN5 | J2 | J3 |
| CAN6 | J4 | J5 |
| CAN7 | J6 | J7 |
| CAN8 | J8 | J9 |
| CAN9 | J10 | J11 |

- 闭环网络需且**仅需插 2 个** 120Ω 跳帽(严禁 >2 个);开环不插。
- 双节点内部闭环(如 CAN5↔CAN6):两端各插一个跳帽 = 共 2 个。
- RDK 的某路与外部 CAN 设备组外部闭环:RDK 端插一个跳帽,外部设备端接一个 120Ω。

### 2.3 S600 CAN:MCU 扩展板 + 底板,拨码开关选 120Ω

S600 共 10 路:MCU 扩展板 5 路 + 底板 5 路。**120Ω 用拨码开关**:拨到 **ON** = 接入电阻(闭环);拨到数字编码端 = 断开(开环/中继)。

**MCU 扩展板**(CAN 与拨码 DPI 对应):

| CAN | DPI | CAN | DPI |
|-----|-----|-----|-----|
| can1 | 1 | can4 | 4 |
| can2 | 2 | can10 | 5 |
| can3 | 3 | | |

**底板**(BP 连接器 J16,拨码在底板背面):

| CAN | DPI | CAN | DPI |
|-----|-----|-----|-----|
| can5 | 1 | can8 | 4 |
| can6 | 2 | can9 | 5 |
| can7 | 3 | | |

底板 J16 信号序(从上到下):GND / CAN5_H / CAN5_L / CAN6_H / CAN6_L / GND / CAN7_H / CAN7_L / CAN8_H / CAN8_L / CAN9_H / CAN9_L。

### 2.4 Acore 侧怎么收发(CANHAL sample)

- 前提:先启动 MCU1(参考 MCU 文档 `01_basic_information.md` 的 MCU1 启动流程)。
- sample 源码:`/app/Can`(`can_send` / `can_get` / `can_multi_ch`),板上直接 `make` 编译。
- 每个 sample 的 `config/` 下有 3 个 JSON:`nodes.json`(建虚拟 CAN 设备,字段 `target` 是 CANHAL 访问名,如 `can6_ins0ch6`)、`ipcf_channel.json`(把节点映射到具体 IPC instance/channel)、`channels.json`(指 IPC 配置,一般不改)。
- **关键约束**:单个 IPC channel 只能被一个线程读写,互联测试要按 mcu_can.md『软件架构』表里的 CAN↔instance/channel 对应关系改配置(S100:CAN5→ins0/ch4、CAN6→ins0/ch6、CAN7→ins4/ch7、CAN8→ins4/ch2、CAN9→ins0/ch3)。
- 简单回环(S100 CAN5↔CAN6):接线后 `./canhal_get bypass &` 收,`./canhal_send bypass 6` 发;S100 用跳帽、S600 把对应拨码拨 ON 接入 120Ω。
- 多通道:`./can_multi_ch -t 2 -l 64 -n 5`(`-t` 0标准/1扩展/2 FD标准/3 FD扩展,`-l` 8 或 64 字节,`-n` 帧数)。
- 波特率与硬件过滤器(ONE_ID/RANGE_ID/TWO_ID)在 MCU SDK 的 `Can/src/Can_PBcfg.c` 配置;S100 内置 6 组波特率(`u16DefaultBaudrateID` 0~5,如 3 = 仲裁 1M / 数据 5M 短距、5 = 1M/8M)。

---

## 3. RDK S100 40PIN:I2C5 / UART2 拨码开关二选一

S100 有标准 40PIN(数字 IO **3.3V**)。默认使能 **I2C5**(物理脚 3/5)与 **I2C4**(脚 27/28);**UART2**(脚 8/10)默认**未使能**。**I2C5 与 UART2 在 40PIN 上经一颗拨码开关二选一复用**。

### 3.1 用 I2C5(默认态,直接用)

```bash
python3 /app/40pin_samples/test_i2c.py
# 脚本先 ls /dev/i2c*,可见 /dev/i2c-0 .. /dev/i2c-5;输入总线号后内部跑 i2cdetect -y -r <bus>
```

常规探测同标准流程:`i2cdetect -y -r 5`(I2C5)确认从机地址出现再读写。

### 3.2 切到 UART2(官方两步,缺一不可)

1. **拨动 40PIN 上的拨码开关**,从 I2C5 切到 UART2(开关位置见官方图 `image-rdk_100_funcreuse_40pin.png`,正文未给文字编号)。
2. **修改设备树**让 uart2 生效:编辑 `kernel/arch/arm64/boot/dts/hobot/drobot-s100-soc.dtsi` 的 `uart2` 节点,把 `status` 改为 `"okay"`(官方原文给了完整节点片段,核心是 `compatible = "snps,dw-apb-uart"`、`pinctrl-0 = <&peri_uart2>`、`status = "okay"`),编译生效后再测。

```bash
python3 /app/40pin_samples/test_serial.py
# S100 选测 /dev/ttyS2(注意 /dev/ttyS0 是系统调试口,不要动)
```

> **二选一提醒**:I2C5 与 UART2 物理复用同一组脚的功能,**同一时刻只能用其一**;切到 UART2 后 I2C5 不可用,反之亦然。改设备树属于持久化内核链改动,按本 skill 安全铁律谨慎操作。

---

## 4. RDK S600:无标准 40PIN,自锁口外设实操

S600 **没有标准 40PIN**,改为 **2 个 10-pin 自锁口 + 1 个 12-pin + 1 个 14-pin 自锁口**,**数字 IO 为 1.8V 电平**(接外设务必确认对端能吃 1.8V,3.3V/5V 器件需电平转换)。

### 4.1 GPIO(Hobot.GPIO,按物理脚号)

```python
import Hobot.GPIO as GPIO         # GPIO.model == 'RDK_S600'
GPIO.setmode(GPIO.BOARD)          # 推荐 BOARD(物理脚号);另支持 BCM/CVM/SOC
# 官方 button_led.py 例:4 号脚作输入、3 号脚作输出,按 4 号电平驱动 3 号
```

- 试电平:用杜邦线把目标脚接 **1.8V 或 GND**(不是 3.3V)。
- 跑示例:`sudo python3 /app/40pin_samples/button_led.py`。

### 4.2 UART6 / UART7(10-pin 自锁口,3.3V)

S600 在 10-pin 自锁口上支持 **UART6、UART7**(IO 电压 3.3V),对应设备 **`/dev/ttyS6` 或 `/dev/ttyS7`**:

```bash
python3 /app/40pin_samples/test_serial.py
# 选 /dev/ttyS6 或 /dev/ttyS7;回环测试把该口 TXD/RXD 短接
```

### 4.3 SPI1(14-pin 自锁口,1.8V,需先用 dtbo 使能)

SPI1 在 14-pin 自锁口引出,**1.8V**,单片选,默认未使能,需挂 overlay:

```bash
# 1) 在 /boot/config.txt 写入(文件不存在则 sudo nano 创建)
dtbo_file_path=/overlays/s600_v0p2_enable_spi1.dtbo
# 2) 重启
sudo reboot
# 3) 回环:MISO/MOSI 短接后跑
python3 /app/40pin_samples/test_spi.py
# 官方示例选 bus 1 / cs 0;持续打印 0x55 0xAA 即通,0x00 0x00 即失败
```

> 注:官方 SPI 文档同页里列出的控制器为 `/dev/spidev0.0 /dev/spidev0.1`,而示例又让选 bus 1/cs 0(spidev1.0)——以板上 `test_spi.py` 实际打印的控制器列表为准。

### 4.4 自锁口连接器与配件

S600 自锁口具体脚序、连接器型号见官方图 `image-rdk_s600_mainboard_pin.png`;MCU 扩展板(BMI088 走 SPI-13)/相机扩展板等配件清单见 `../../rdk-accessories/references/accessories-catalog.md` 第 6、7 节。

---

## 5. 应答模板(CAN / S100 拨码 / S600 自锁口)

1. **先认板型**:X5 → SocketCAN(`ip link`+can-utils);S100/S600 → MCU 域 CANHAL(`/app/Can`);X3 → 无板载 CAN。
2. **CAN 接线**先确认 GND/L/H 与终端电阻(X5 是 120Ω 开关;S100 是跳帽;S600 是拨码 ON)。
3. **S100 要用 UART2** → 提醒『拨码 + 改设备树 status=okay』两步,且会顶掉 I2C5。
4. **S600 接外设** → 先核对是不是 1.8V 电平、SPI1 要不要先挂 dtbo、自锁口脚序查官方图。
5. 给**最小可验证命令**(X5:回环 `candump`/`cansend` 自收自发;S600:`test_spi.py` 看 0x55 0xAA),验证通过再谈封装。
