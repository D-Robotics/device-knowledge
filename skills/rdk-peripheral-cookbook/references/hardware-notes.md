# RDK 外设驱动食谱 · 硬件与系统参考

> 来源:整理自 D-Robotics RDK 官方文档、工具链与社区实践,逐条保留出处链接;由 device-knowledge 知识库忠实转换而来,未改写技术事实。

本文汇集本 skill 涉及的 RDK 硬件/系统章节,逐节整理自官方文档与实践,供需要细节时查阅。

### 12. X5 板端 IO 加速库（x5-hobot-io / x5-hobot-utils）

- **x5-hobot-io**：<https://github.com/D-Robotics/x5-hobot-io>，C 语言绑定 X5 的 GPIO/I2C/SPI/PWM/UART，比 Python `Hobot.GPIO` 延迟低 ~10x
  - 适用于实时控制（电机、舵机、传感器轮询）
  - 编译需 RDK X5 工具链；交叉编译看 README
- **x5-hobot-utils**：<https://github.com/D-Robotics/x5-hobot-utils>，X5 平台诊断/刷机辅助工具集

### 23. 40PIN 跨平台引脚与接口深度对照（外设驱动第一步）

> 用户问"怎么接 XX"时，先问清**板型**再回答；各板 40PIN 物理位置虽然一致，但电源能力 / GPIO 编号 / I2C 总线号 / PWM 路径**全都不一样**。

**40PIN 物理布局四家一致**（抄自 RPi 3B+）：`Pin 1 = 3.3V`，`Pin 2/4 = 5V`，`Pin 6/9/14/20/25/30/34/39 = GND`。物理**没差异**，差异在电气与编号。

**电源承载能力对照（驱舵机/灯带必看）**：

| 平台 | 40PIN 5V 上限 | 舵机/灯带取电建议 |
|------|----------------|------------------|
| RPi 5 | ~600mA 共享 | **必须外接 5V 电源**，共 GND 回板 |
| Jetson Orin Nano | ~1A | 单舵机勉强可，多舵机必外接 |
| RK3588（Orange Pi 5）| ~800mA | 同 Jetson |
| **RDK X5 / S100** | X5 官方 40PIN 标注为 1A @ 3.3V / 1A @ 5V；S100 需按扩展板电源预算核对 | **舵机/电机/灯带一律外接 5V/6V 电源，共 GND** |

> Moss 看到 "从 Pin 2 取 5V 驱动一个 SG90 舵机" → 可接；"驱动 4 个舵机 / WS2812 灯带 30 颗以上" → **必须警告外接电源**，否则掉电重启。

**GPIO 编号方案对照（同一物理 Pin 11，名字四家不一样）**：

| 平台 | 编号方案 | Pin 11 叫什么 | 用户态主 API |
|------|---------|---------------|--------------|
| RPi | BCM | `GPIO17` | `RPi.GPIO` / `gpiozero` / **`libgpiod`** |
| Jetson Orin Nano | tegra-gpio | `PQ.05`（chip0 line 144） | `Jetson.GPIO` / **`libgpiod`** |
| RK3588 | `GPIOx_yZ`（bank_group_pin） | `GPIO3_C6`（= 3×32 + 2×8 + 6 = 118） | `OPi.GPIO` / **`libgpiod`** |
| **RDK X3** | Hobot 自定义编号 | 查 X3 pinout 表 | `Hobot.GPIO` / `libwiringpi` / **`libgpiod`** |
| **RDK X5** | Hobot 自定义编号 | 查 X5 pinout 表 | `Hobot.GPIO` / `x5-hobot-io` / **`libgpiod`** |

> **唯一跨四家通用的底层 API = `libgpiod`**（见下一节）；Moss 写跨板脚本**优先推 libgpiod**，不要去猜 BCM 号。

**I2C 总线号对照（做传感器 / PCA9685 必查）**：

| 平台 | 40PIN 对外可用 I2C | 设备节点 | 激活方式 |
|------|-------------------|----------|----------|
| RPi | I2C1（Pin3/5） | `/dev/i2c-1` | `raspi-config` → Interface → I2C |
| Jetson Orin Nano | I2C1（Pin3/5）、I2C8（Pin27/28） | `/dev/i2c-7`（Orin 实际编号）| 默认开 |
| RK3588 | I2C3/7/8 对外 | `/dev/i2c-3` 等 | 需 `overlay` 使能 |
| **RDK X3** | 40PIN 实际 **2 路**(I2C0 Pin3/5) | `/dev/i2c-0/1` | 用 `srpi-config` 切复用 |
| **RDK X5** | 40PIN 实际 **2 路**(I2C5 Pin3/5 + I2C0 Pin27/28) | `/dev/i2c-*` 系统列更多 | 同上;注:旧表"3路"是系统级控制器数 |
| **RDK S100** | 40PIN 实际 **2 路**(I2C5 Pin3/5 + I2C4 Pin27/28) | `/dev/i2c-0..5` | I2C5 与 UART2 经**拨码开关**二选一;"4路"是 SoC 级 |
| **RDK S600** | **无标准 40PIN**(自锁口,1.8V) | — | 数字 IO 走 10/12/14-pin 自锁口,见 rdk-hardware |

> **RDK 特有坑**：① 同一 40PIN 引脚可能默认配成 GPIO,先用 **`sudo srpi-config` → `3 Interface Options` → 总线配置**(或板上 `/app/40pin_samples/` 脚本)切到 I2C/SPI/UART/PWM 模式,`/dev/i2c-X`、`pwmchip` 才出现。② 上表 RDK 行是 **40PIN 对外实际可用数**;SoC 级总线更多(在 MCU/相机扩展口上)。排查:`ls /dev/i2c-*` → 不见想要的总线 → 跑 srpi-config/脚本 → 再看。

**PWM 路数与 `pwmchip` 路径对照（舵机 / 电机调速命门）**：

| 平台 | 硬件 PWM 路数 | 控制路径 | 激活动作 |
|------|--------------|----------|----------|
| RPi | 2（PWM0 / PWM1） | `/sys/class/pwm/pwmchip0/pwm{0,1}/` | `dtoverlay=pwm-2chan` |
| Jetson Orin Nano | 3 | `/sys/class/pwm/pwmchip*/` | **必须先 `sudo /opt/nvidia/jetson-io/jetson-io.py`** 改 Pinmux |
| RK3588 | 多路（PWM14/15 常用） | `/sys/class/pwm/pwmchipN/` | 需 overlay |
| **RDK X3** | 40PIN 2 路 | `/sys/class/pwm/pwmchipN/pwmM/` | `srpi-config` 切复用 |
| **RDK X5** | 40PIN 实际几路(SoC 级 8) | 同上 | `srpi-config` 切复用 |
| **RDK S100** | 40PIN 实际 **2 路 LPWM**(Pin32/33,48KHz~192MHz) | Hobot.GPIO 控制 | "8 路"是 SoC 级;MCU 域 PWM 走固件不在 40PIN |

> **多舵机（≥3 路）结论**：**四家都推 PCA9685 + I2C**，理由是省板子 PWM / 跨板可移植 / Python 库成熟（见第 25 节）。

**UART / 串口对照**：

| 平台 | 40PIN 对外 UART | 节点 | 坑 |
|------|-----------------|------|----|
| RPi | Pin 8/10 | `/dev/ttyS0`（mini UART）/ `/dev/ttyAMA0` | 要 `dtoverlay=disable-bt` 让主 UART 出来 |
| Jetson Orin Nano | Pin 8/10 | `/dev/ttyTHS1` | 默认 root 占用，要 `systemctl disable nvgetty` |
| RK3588 | Pin 8/10 | `/dev/ttyS0/3` | 需 overlay |
| **RDK X5** | 40PIN 实际 **1 路**(UART1 Pin8/10,`/dev/ttyS1`) | `ttyS0` 是系统调试口 | "5 路"是 SoC 级;`ttyS` 普通 / `ttyHS` 高速 |
| **RDK S100** | 40PIN 实际 **1 路**(UART2 Pin8/10,默认未使能,与 I2C5 拨码复用) + **独立 MCU Domain UART 调试口** | 同上 | "6 路"是 SoC 级;Main/MCU 两调试口别弄混(见 MCU 章节)|

> **万能兜底**：USB 转 TTL（`/dev/ttyUSB0`）跨所有平台**一样用**；Dynamixel / Feetech 总线舵机、GPS、LoRa 模块几乎都直接 USB 接入，不用纠结板载 UART。

**SPI / CAN / 音频 / CSI 要点**：

| 能力 | 说明 |
|------|------|
| SPI | RDK X3 仅 1 路 / X5 两路；路径 `/dev/spidev0.0`；**WS2812 灯带靠 SPI MOSI 模拟时序**（见第 27 节）|
| **CAN**（RDK 强项）| RPi 无板载（需 MCP2515 HAT）；**X5 / S100 直接板载 CAN FD**，用 `ip link set can0 type can bitrate 500000` 起来 |
| 音频 | **Jetson 无板载音频**（这是 Jetson 名梗）；RPi 4 有 3.5mm，RPi 5 砍掉；RDK 多数型号通过 40PIN I2S 接 HAT 或走 USB 声卡（见第 28 节） |
| CSI 相机 | RPi / Jetson 走 22Pin 排线；RDK X5 4-lane、X3 仅 2-lane；**S100 独占 GMSL2 车规相机**，需扩展板 |

### 24. libgpiod：跨平台通用 GPIO 统一 API（强烈推荐）

> 四家板子（RPi / Jetson / RK / RDK）**都支持** `libgpiod`，这是 Linux 4.8+ 内核推荐的 GPIO 用户态 API，取代已废弃的 `/sys/class/gpio`。Moss 写跨板脚本或不确定编号时，**首选这套**。

**安装**（所有平台一致）：
```bash
sudo apt install gpiod python3-libgpiod   # 命令行工具 + Python 绑定
```

**4 个核心命令**：
```bash
gpiodetect                    # 列出所有 gpiochip（如 gpiochip0, gpiochip1...）
gpioinfo gpiochip0            # 看每条 line 的名字（有名字的可直接按名操作）
gpioset gpiochip0 17=1        # 置高（line 17）
gpioget gpiochip0 17          # 读电平
```

**用名字操作**（最优写法，跨板最稳）：
```bash
gpiofind "GPIO17"                          # 反查所在 chip 与 line
gpioset $(gpiofind "GPIO17")=1             # 置高，一行搞定
```

**Python 最小示例**（RPi / Jetson / RK / RDK 都能跑）：
```python
import gpiod, time
chip = gpiod.Chip('gpiochip0')
line = chip.get_line(17)
line.request(consumer='blink', type=gpiod.LINE_REQ_DIR_OUT)
for _ in range(10):
    line.set_value(1); time.sleep(0.5)
    line.set_value(0); time.sleep(0.5)
line.release()
```

**libgpiod vs 其他 API 选择矩阵**：

| 场景 | 推荐 |
|------|------|
| 要和树莓派现有教学代码兼容 | `Hobot.GPIO`（RDK）/ `Jetson.GPIO`（Jetson）——API 都抄 `RPi.GPIO` |
| 写一份脚本跑多个平台 | **`libgpiod`** |
| 实时 / 低延迟（< 1ms 抖动敏感）| C 直接调 `libgpiod` 或 `x5-hobot-io`（X5 专用，见第 12 节）|
| 简单闪灯 / 按键读取 | `gpioset` / `gpioget` 命令一行搞定 |

> **Moss 遇到"GPIO 不工作"类问题**：先 `gpiodetect` → `gpioinfo <chip>`，直接用**名字**定位，不要让用户翻 BCM 表；这是对四平台都通用的方法。

### 25. 舵机控制：单舵机到多路 PCA9685 标准方案

**单舵机（1–2 路）走板载硬件 PWM**：

舵机信号本质 = **50Hz（周期 20ms）+ 1.0ms(0°) ~ 2.0ms(180°) 正脉宽**（SG90 等标准）。RDK / RPi / Jetson / RK 通用 sysfs 控制代码（先切 Pinmux，得到 `/sys/class/pwm/pwmchipN/`）：

```bash
cd /sys/class/pwm/pwmchip0              # 板型不同 N 不同，用 ls 确认
echo 0 > export
echo 20000000 > pwm0/period             # 20ms = 50Hz
echo 1500000  > pwm0/duty_cycle         # 1.5ms = 90°（中位）
echo 1        > pwm0/enable
```

角度 → duty_cycle 公式（ns 单位）：
```
duty_cycle = 1_000_000 + (angle / 180) * 1_000_000   # 1ms ~ 2ms
```

> **安全铁律**：舵机**绝不能从 40PIN Pin 2/4 取 5V 供电**，哪怕只有 1 个 SG90 —— 瞬时堵转电流可达 1A，会拉低板子 5V 导致重启。**始终用外部 5V/6V 电源，信号线和板子共 GND**。

**多舵机（≥3 路）一律用 PCA9685 + I2C**（四平台事实标准）：

| 参数 | 值 |
|------|----|
| 硬件 | PCA9685 16 通道 PWM 扩展板（常见低成本模块，通常内置 5V LDO） |
| 接线 | I2C SDA/SCL/VCC/GND + 独立电源 V+ 给舵机 |
| I2C 默认地址 | **`0x40`**（A0–A5 可跳线改地址，多片级联最多 62 个） |
| 频率 | `set_pwm_freq(50)` 标准舵机；LED 调光用 1000 |
| 分辨率 | 12 位（0–4095） |

**Python 最小脚本**（RDK / RPi / Jetson / RK 同一份代码，只改总线号）：

```bash
sudo apt install python3-smbus2
pip3 install adafruit-circuitpython-servokit   # 或裸 Adafruit_PCA9685
```

```python
import board, busio
from adafruit_pca9685 import PCA9685
from adafruit_motor import servo

i2c = busio.I2C(board.SCL, board.SDA)          # 默认 i2c-1；RDK X5 按实际总线号换
pca = PCA9685(i2c); pca.frequency = 50
ch0 = servo.Servo(pca.channels[0], min_pulse=500, max_pulse=2500)
ch0.angle = 90                                  # 90 度
```

**PCA9685 排障三步**：
1. `i2cdetect -y <bus>` → 确认 `0x40` 出现；不出现 = 接线 / I2C 总线未使能
2. 舵机抖动严重 = 供电不够（PCA9685 的 V+ 只带信号电平不带功率，**舵机电源必须走 PCA9685 的 V+ 螺丝端子，不从 40PIN 取**）
3. 多舵机同时动卡顿 = 外部电源 5V/3A 不够，升到 5V/5A 或用航模 BEC

**总线舵机另一条路**（Dynamixel / Feetech STS / LX-16A）：
- 走 **TTL 串口或 RS-485**，`/dev/ttyUSB0`（USB 转 TTL 最稳）
- Python：`dynamixel-sdk` / `feetech-servo-sdk`
- 优势：**一条线接几十个舵机**，每个有 ID，可读当前角度/电流/温度
- 劣势：相对更贵，采购成本需按实时渠道确认
- **RDK 场景**：双足/四足 / 机械臂用这种，SG90 等 PWM 舵机只适合玩具级

### 26. 电机驱动三大范式

遇到"电机怎么转"时，**先问是哪种电机 + 用什么驱动器**，再落到板级：

**范式 1：直流电机（DC） = H 桥驱动器 + PWM 调速 + GPIO 控方向**

| 驱动器 | 适用 | 接线摘要 |
|--------|------|----------|
| **TB6612FNG** | 小车两轮，单路 ~1.2A | PWMA/PWMB 给 PWM，AIN1/AIN2/BIN1/BIN2 给方向（4 个 GPIO），STBY 置高 |
| **DRV8833** | 更小电流（~1.5A 峰值）| 类似 TB6612 |
| **BTS7960** | 大电流（43A）| R_EN/L_EN + RPWM/LPWM |

最小跑车代码（伪码，跨平台适用）：
```python
# 一个轮子：GPIO17/18 定方向 + pwmchip0/pwm0 给速度
gpio.set(17, 1); gpio.set(18, 0)    # 正转
set_pwm_duty("pwmchip0/pwm0", 50)   # 50% 占空比
```

**范式 2：步进电机 = 专用驱动器 + STEP/DIR 两根线**

| 驱动器 | 特点 |
|--------|------|
| A4988 | 最便宜，1.5A，噪声大 |
| DRV8825 | 2.2A，32 细分 |
| **TMC2209** | 静音（重要！），UART 可配参数，3D 打印机主流 |

接线仅需 2 个 GPIO（STEP + DIR）+ 3.3V EN，**不需要 PWM**（STEP 用软件打脉冲即可）：

```python
for _ in range(200):                  # 200 步 = 一圈（1.8°/步步进电机）
    gpio.set(STEP, 1); time.sleep(0.001)
    gpio.set(STEP, 0); time.sleep(0.001)
```

**范式 3：无刷（BLDC）= ESC 或智能驱动器**

| 方式 | 说明 |
|------|------|
| 航模 ESC | 跟舵机一样 50Hz PWM（1.0ms 停 ~ 2.0ms 全速），可直接复用 PCA9685 |
| **ODrive / VESC** | 带编码器闭环、通过 UART/USB/CAN 下发命令，Python 有 `odrive` / `pyvesc` 库 |
| D-Robotics S100 特殊路径 | MCU (R52+) 直接驱动，走 IPC；kHz 级回路，比 Linux RT 线程稳（见第 17 节）|

> **Moss 对"机器人关节电机"类问题**：
> - 玩具 / 教学 → 直流 + TB6612 或 PWM 舵机
> - 桌面机械臂 / 四足 → **总线舵机（Feetech STS3215 / Dynamixel XL）**
> - 双足 / 工业关节 → BLDC + ODrive/VESC 或厂商一体化关节模组
> - 这不是 RDK 特殊性的问题，是**电机类别决定的行业标准**。

### 27. LED：从单色到 WS2812 灯带

**分三种，做法完全不同**：

| 类型 | 接法 | 控制方式 |
|------|------|----------|
| 单色 LED | 330Ω 限流电阻 + GPIO | GPIO 高低电平，`gpioset`；PWM 调亮度同舵机章节 |
| **WS2812 / WS2815 RGB 灯带** | 5V + GND + DIN | **严格 800kHz 时序**，GPIO bitbang 不稳，**走 SPI MOSI 模拟** |
| I2C LED 矩阵（HT16K33 / MAX7219）| I2C 4 线 | `luma.led_matrix` 跨平台 Python 库 |

**WS2812 跨平台通用方案 —— SPI 模拟时序**（RDK / RPi / Jetson / RK 都用这招）：

核心技巧：**用 4 个 SPI bit 编码 1 个 WS2812 bit**
- WS2812 的 "1" = 高电平 ~0.8µs + 低电平 ~0.45µs → SPI 输出 `1110`
- WS2812 的 "0" = 高电平 ~0.4µs + 低电平 ~0.85µs → SPI 输出 `1000`
- SPI 速率设 **2.4 MHz**（= 800kHz × 3；实验上 3.2MHz 也行）

跨平台 Python 包：
```bash
pip3 install Adafruit-CircuitPython-NeoPixel-SPI
```

```python
import board, neopixel_spi
pixels = neopixel_spi.NeoPixel_SPI(board.SPI(), 30, pixel_order=neopixel_spi.GRB)
pixels[0] = (255, 0, 0)    # 第 0 颗红色
pixels.show()
```

> **供电坑**：30 颗 WS2812 满亮白光 ≈ 1.8A，**绝对不能从 40PIN Pin 2/4 取 5V**，必须外接 5V 电源 + 共 GND；数据线 DIN 从 40PIN 的 MOSI 引脚出来即可（信号电流很小）。

**RPi 原生 `rpi_ws281x` 方案**：需要 root + PWM0 引脚（物理 Pin 12 / GPIO18），**该方案只适用于 RPi**，RDK / Jetson / RK **不适用**，一律走 SPI 模拟法。

### 28. 音频：ALSA 兜底链路（没装 TROS 时怎么播音 / 录音）

> RDK 的 `hobot_audio` 只有装了 TROS 且插了官方麦克风阵列板时才可用。**当这些条件不具备**时，Moss 应该走标准 Linux ALSA 链路——这在 RPi / Jetson / RK / RDK 上**完全通用**。

**音频硬件在不在 —— 3 步通用探测**：

```bash
# 1. 看声卡列表（输出设备 / 输入设备）
aplay -l       # 列出所有输出设备：card X, device Y
arecord -l     # 列出所有输入设备
# 2. 一个都没有 = 内核根本没识别到
lsusb          # 看 USB 声卡 / USB 麦克风有没有
dmesg | grep -i "audio\|sound\|snd"
# 3. 有声卡但播不响 = 音量被静音 / 选错 channel
alsamixer      # 图形化调音量，按 M 解静音（MM 标红 = 静音）
```

**播放 WAV / MP3**：

```bash
aplay test.wav                              # 播 WAV，用默认声卡
aplay -D plughw:1,0 test.wav                # 指定 card 1 device 0
aplay -D plughw:CARD=UAC1,DEV=0 test.wav    # 按 USB 声卡名字指定

# MP3 / Opus 要先解码
sudo apt install mpg123 sox
mpg123 song.mp3
sox song.mp3 -d                             # 自动播放任意格式
```

**录音**：

```bash
arecord -D plughw:1,0 -f S16_LE -r 16000 -c 1 -d 5 test.wav   # 5 秒 16kHz 单声道
# 验证麦克风工作（实时看电平）
arecord -vv -f S16_LE -r 16000 -c 1 /dev/null
```

**PulseAudio / PipeWire 场景**：
```bash
pactl list short sinks                      # 列出播放设备
pactl list short sources                    # 列出录音设备
paplay test.wav                             # 通过 PulseAudio 播放
parecord -d 5 test.wav                      # 录音
```

**USB 声卡 = 万能兜底**：不管哪块板，插 **USB 声卡（带 3.5mm）或 USB 麦克风**，内核自动加载 `snd-usb-audio`，`aplay -l` 立刻可见。**Jetson 无板载音频，这是唯一推荐路径**；RDK 没有 I2S HAT 时也推这条。

**典型错误 → 判断**：

| 报错 / 现象 | 判断 |
|-------------|------|
| `aplay -l` 返回 "no soundcards found" | 硬件未识别，先看 USB 声卡是否插好 / I2S 是否 overlay |
| `ALSA lib pcm.c ... unable to open slave` | 设备被占用，`sudo fuser /dev/snd/*` 看是谁，或 `systemctl stop pulseaudio` 临时释放 |
| 播放有声但极小 / 失真 | `alsamixer` 加音量；或 `amixer sset Master 80%` |
| 麦克风录音全是噪声 | `arecord -l` 确认选对设备，避开板载底噪；USB 麦克风质量更稳 |
| `aplay: Dac failed: Device or resource busy` | 其他进程（PulseAudio / TROS）持有 → `pactl suspend-sink 0` 或切用 PulseAudio API |

### 29. 零驱动诊断 SOP（9 步通用外设探测流程）

> 用户说 "我插了个 XXX 但不知道怎么用 / 板子不识别 / 没驱动"——**不要猜，按下面 9 步走**。这套流程在 RDK / RPi / Jetson / RK 上 **100% 通用**，不依赖厂商工具。

```
┌─ Step 1. dmesg | tail -50                  内核最近识别了什么（插拔时看这里）
├─ Step 2. lsusb                              USB 设备枚举（USB 声卡/麦/摄像头/转 TTL）
├─ Step 3. ls /dev/                           设备节点全览：
│          /dev/tty*       串口类（ttyUSB0 / ttyACM0 / ttyS* / ttyHS*）
│          /dev/video*     V4L2 摄像头
│          /dev/i2c-*      I2C 总线
│          /dev/spidev*    SPI
│          /dev/snd/       音频（card0 / pcmC0D0p 等）
│          /dev/input/     输入（按键 / 游戏手柄）
├─ Step 4. i2cdetect -l 列所有 I2C 总线，再 i2cdetect -y <bus> 扫地址
├─ Step 5. v4l2-ctl --list-devices            摄像头
├─ Step 6. aplay -l / arecord -l              音频
├─ Step 7. lsmod | grep <keyword>             内核模块是否加载
├─ Step 8. modinfo <mod> / modprobe <mod>     查模块信息 / 手动加载
└─ Step 9. cat /proc/device-tree/…            设备树节点（RPi/RK/RDK 都有）
```

**按"症状 → 诊断"对表**：

| 症状 | 优先查 | 常见原因 |
|------|-------|----------|
| 设备插上板子不识别 | Step 1 (dmesg) + Step 2 (lsusb) | 供电不够 / USB 口坏 / USB 3.0 兼容性 |
| "No such device" 打开 /dev/i2c-X | Step 3 + Step 4 | I2C 总线未使能 / Pinmux 未切（RDK 特有）|
| `permission denied: /dev/ttyUSB0` | `ls -l /dev/ttyUSB0` | 用户没在 `dialout` 组 → `sudo usermod -aG dialout $USER` |
| `ALSA lib ... unable to open slave` | Step 6 + `fuser` | 设备被其他进程占用 |
| PWM 没反应 | `ls /sys/class/pwm/` | Pinmux 未切 / 板子 PWM 路数超了 |
| Python 导入 `Hobot.GPIO` 报错 | `which python3` | 用了 conda/venv，`Hobot.GPIO` 只认系统 Python |

**修复的三条正交路径**（按风险从低到高）：

1. **用户态装包**（最安全）：`apt install` / `pip install` / `git clone + colcon build`
2. **临时加载内核模块**（中等）：`modprobe <mod>` / `insmod ./xxx.ko` / `rmmod <mod>`，只做当前会话验证，随后看 `dmesg`
3. **持久化内核/启动链**（最高风险，破坏性）：`/etc/modules-load.d/*.conf` 开机加载、`/boot` 设备树、`/lib/modules` 安装、initramfs / miniboot / bootloader / MCU 固件——**RDK 上不到万不得已不建议用户碰**，保留给官方流程和人工恢复方案

**Moss 的应答模板**（遇到外设问题时）：
1. 先问清 **板型 + 接口（USB / 40PIN I2C / 40PIN UART / MIPI）+ 设备型号**
2. 跑 Step 1–3 的三条命令，让用户贴回输出
3. 根据输出走"症状 → 诊断"表，定位到具体一条
4. 给出**最小可验证命令**（`i2cdetect -y 1` 看到 0x40 / `aplay -l` 看到 card 1 / `gpioinfo gpiochip0`）
5. 成功验证后再谈"写成 ROS2 节点 / 封装 Python 脚本 / 开机自启"
