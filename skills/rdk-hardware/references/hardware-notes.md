# RDK 硬件与系统基础 · 硬件与系统参考

> 来源:整理自 D-Robotics RDK 官方文档、工具链与社区实践,逐条保留出处链接;由 device-knowledge 知识库忠实转换而来,未改写技术事实。

本文汇集本 skill 涉及的 RDK 硬件/系统章节,逐节整理自官方文档与实践,供需要细节时查阅。

### 1. 40PIN GPIO

- 40 Pin 排针物理兼容树莓派，但 **GPIO 编号与树莓派不同**，不能直接套用 RPi 编号
- 引脚电压：3.3V 逻辑电平；Pin 1/17 = 3.3V 电源，Pin 2/4 = 5V 电源
- 检查引脚复用状态：`cat /sys/kernel/debug/pinctrl/*/pinmux-pins`
- Python 控制：`Hobot.GPIO`（API 兼容 RPi.GPIO）；C 控制：`libwiringpi`
- **X5 vs X3 差异**：X5 有更多 UART(5路)/PWM(8路)/I2C(3路)；X3 的 I2C 仅 2 路
- **S100 差异**：40PIN 实际可用 I2C×2/UART×1/SPI×1/LPWM×2（其余总线在 MCU/Camera 100-Pin 扩展口）；MCU (R52+) 可承担实时 GPIO 控制
- **S600 没有标准 40PIN 排针**：外扩走自锁连接器(2×10-pin/1×12-pin/1×14-pin)，数字 IO 是 **1.8V 电平**（不是 3.3V，接外设注意电平匹配），UART6/UART7 走 10-pin、SPI1 走 14-pin

### 2. 摄像头系统

**MIPI CSI**
- 支持官方模组：IMX219 (8MP)、GC4663 (4MP) 等
- X3 仅 2-lane；X5/Ultra 支持 4-lane；S100 需通过扩展板接入
- 节点：`hobot_mipi_cam`，launch 中需指定 `sensor` 型号和 `video_device` 路径

**USB UVC**
- 通过 `hobot_usb_cam` 节点接入 ROS2
- **关键**：默认 YUYV 格式在多数摄像头上不稳定，必须设为 **MJPEG**
- 排障三步：`v4l2-ctl --list-formats-ext` → 确认 MJPEG + 分辨率 → 修改 launch 参数
- 多路 `/dev/video*` 可能功能不同（一路出图一路出元数据），需逐个验证

**GMSL（仅 S100/S100P）**
- 车规级 GMSL2 模组，需配扩展板
- 适合多路高分辨率/长距离场景（自动驾驶/工业检测）

### 3. BPU 推理流水线

**架构差异**
| 架构 | 板型 | 特性 |
|------|------|------|
| Bernoulli2 | X3 | 仅 CNN，算子集小 |
| Bayes | X5, Ultra | CNN 优化，部分 Attention 算子 |
| Nash | S100/S100P/S600 | CNN + Transformer，160+ ONNX 算子 |

**推理方式**
- C/C++: `libdnn` / `bpu_infer_lib` 直接推理（X3/X5/Ultra）
- Python: **X3/X5/Ultra** 用 `hobot_dnn` Python binding（需系统 Python，不支持 conda/venv 中使用）；**S100/S100P** 用 `hbm_runtime`（pip 包 `hbm-runtime`，加载 `.hbm`）
- ROS2: TROS 推理节点（`hobot_dnn` ROS2 wrapper）自动订阅图像 topic 输出结果

**性能监控**（按板型选择，注意 `hrut_smi` / `bputop` **并非每个板型都装**）
- `cat /sys/devices/system/bpu/bpu0/ratio` — **所有板型通用**的 BPU 使用率（0–100），最稳的兜底方案
- `cat /sys/devices/system/bpu/bpu0/devfreq/*/cur_freq` — BPU 当前频率（所有板型通用）
- `hrut_somstatus` — SoC 温度/电压/频率（所有板型通用）
- `hrut_bpuprofile -b 0` — **X5 实际可用**的 BPU profiling 工具（X5 标配 1 个 BPU 核 = bpu0；同时输出温度、CPU/BPU/DDR/GPU 频率与 BPU ratio）
- `hrut_smi` — **X3 部分镜像**有；**X5 大多无此命令**，请勿默认调用
- `bputop` — **X3/Ultra 部分镜像**有；**X5 大多无此命令**，请勿默认调用
- `hrut_count` — 推理计数（所有板型通用）

> 推荐顺序：**先 sysfs 节点（最稳） → 再 `hrut_bpuprofile`（X5 / Ultra 综合视图） → 最后再考虑 `hrut_smi/bputop`（不要假设它们存在）**。
> 在 X5 上用 `hrut_smi && hrut_somstatus` 会得到 `command not found`；正确写法是 `hrut_bpuprofile -b 0 && hrut_somstatus`，或更通用的 `cat /sys/devices/system/bpu/bpu0/ratio && hrut_somstatus`。

### 4. 模型转换概要

```
训练框架 (PyTorch/TF) → 导出 ONNX → hb_mapper 量化转换 → .bin (BPU 可执行)
```

- `hb_mapper checker` — 检查 ONNX 是否可转换、哪些算子在 BPU 上运行
- `hb_mapper makertbin` — 实际转换（需校准数据集做 PTQ）
- `hb_eval_perf` — 评估编译后模型的推理延迟和吞吐
- 量化方式：PTQ（训练后量化，简单快速）、QAT（量化感知训练，精度更高）
- **注意**：编译后的产物绑定 BPU 架构，跨板型不能直接使用
- **S100/S100P 例外**：上面的 `hb_mapper → .bin` 是 X3/X5/Ultra 链路；Nash 架构走 D-Robotics **天工开物（J6P/S100）** / OE 工具链，产物是 **`.hbm`**（非 `.bin`），板端用 **`hbm_runtime`**（pip 包 `hbm-runtime`）加载

### 6. 系统路径与存储

| 路径 | 用途 | 可写性 |
|------|------|--------|
| `/opt/tros/humble/` | TROS 安装目录 | 只读（apt 管理） |
| `/userdata/` | 用户持久数据 | 可写（部分板型） |
| `/tmp/` | 临时文件 | 可写（重启清空） |
| `/app/` | 应用目录 | 部分镜像只读 |
| `/root/` 或 `$HOME` | 用户主目录 | 可写 |

- 系统镜像版本：`cat /etc/version`
- 板型识别：`cat /sys/class/socinfo/board_id`
- eMMC 扩展分区：`resize2fs /dev/mmcblk0p<N>`

### 7. 网络与连接

- **SSH**：X5/Ultra/S100 默认 `root` / `root`；X3 系统默认用户是 `sunrise/sunrise`，但 RDK Studio 的 SSH 通道多为 `root/root`（重刷后以实际为准），端口 22
- **Type-C 以太网**：部分板型支持 USB Type-C 共享网络（`usb0` 接口，IP 通常 192.168.1.10）
- **WiFi**：`nmcli dev wifi list` → `nmcli dev wifi connect <SSID> password <PWD>`
- **CAN**：**仅 X5 是 Linux SocketCAN**（集成 TCAN4550，`ip link set can0 type can bitrate 500000` → `up`，支持 CAN FD `dbitrate ... fd on`）。**S100/S600 的 CAN 控制器在 MCU 域**（S100 默认 CAN5~9；S600 默认 CAN1~10），经 CAN2IPC→IPC→Acore 侧 CANHAL 库收发,**没有 `can0` 网络设备、`ip link` 不适用**——实操见 rdk-peripheral-cookbook 的 CAN 与板级 IO。X3/Ultra 无板载 CAN
- **S100/S600 双千兆口**：**eth1 出厂固定静态 IP `192.168.127.10`(管理口)**,eth0 走 DHCP/手动——板子"连不上"先试 `ssh root@192.168.127.10`。S600 另有 2× 10GbE
- **多机 ROS2 通信**：确保 `ROS_DOMAIN_ID` 一致，防火墙放行 UDP 7400+

### 8. 散热与功耗

- X3/X5：被动散热通常够用；满载 AI 推理建议加风扇壳
- Ultra：**必须**主动散热（12V/3A DC 供电）
- S100：12-20V DC 供电，长时间满载建议风扇 + 散热片
- 温度监控：`hrut_somstatus` 或 `cat /sys/devices/virtual/thermal/thermal_zone*/temp`
- CPU 降频策略：`cat /sys/devices/system/cpu/cpufreq/policy0/scaling_governor`（默认 schedutil）
- 过热保护：SoC 有硬件过温保护，但频繁触发说明散热方案不足

### 13. 镜像与 TROS 工程

- **镜像构建**：
  - X3 → <https://github.com/D-Robotics/rdk-gen>
  - X5 → <https://github.com/D-Robotics/x5-rdk-gen>
- **TROS 一键构建**：<https://github.com/D-Robotics/robot_dev_config> 是入口仓库，按 README 跑 `init.sh` 会拉取所有 hobot_* 仓库到 colcon workspace
- **下载清单**：<https://github.com/D-Robotics/system_download> 维护各版本镜像/资源的实际下载链接

---

### 15. BPU 架构演进与模型互通性

| 架构 | 工艺世代 | 板型 | 等效算力 (INT8) | ONNX 算子 | Transformer | LLM/VLM |
|------|--------|------|-----------------|-----------|-------------|---------|
| **Bernoulli2** | 旧一代 | X3 / X3 Module | 5 TOPS | 小集，仅 CNN 主干 | ❌ 基本不支持 | ❌（社区有 hobot_llm 小规模试跑） |
| **Bayes / Bayes-e** | 二代 | X5 / X5 Module / Ultra | 10 TOPS (X5) / 96 TOPS (Ultra) | CNN 全 + 部分 Attention | ⚠️ 部分算子要等价改写 | ⚠️ ≤2B 量化 LLM（如 Qwen2-0.5B）|
| **Nash / Nash-e** | 三代 | S100 / S100P / S600 | 80 / 128 / 560 TOPS | 160+ ONNX，CNN + Transformer 深度优化 | ✅ 原生支持 | ✅ 7B 级量化 LLM、VLM 起步；S600(560 TOPS)更大;更大模型以官方清单为准 |

**模型产物互通性矩阵**（重要！X3/X5/Ultra 产物是 `.bin`，S100/S100P 是 `.hbm`，跨架构一律重编）：

| 源 → 目标 | X3 | X5 | Ultra | S100 |
|-----------|----|----|-------|------|
| X3 (.bin) | ✅ | ❌ 重编 | ❌ 重编 | ❌ 重编 |
| X5 (.bin) | ❌ 重编 | ✅ | ✅ 多数 | ❌ 重编 |
| Ultra (.bin) | ❌ 重编 | ⚠️ 性能降级可用 | ✅ | ❌ 重编 |
| S100 (.hbm) | ❌ 重编 | ❌ 重编 | ❌ 重编 | ✅ |

**工具链对应关系**（主机上安装，不在板子里）：
- X3 → 地平线 Horizon OE SDK v1.x (Bernoulli2)，`hb_mapper` 命令族
- X5 / Ultra → 地平线 Horizon OE SDK v2.x (Bayes)，同 `hb_mapper`，但 march 参数不同
- S100 / S100P / S600 → D-Robotics **"天工开物（J6P/S100）"** 工具链，入口 <https://developer.d-robotics.cc/rdk_doc/rdk_s/FAQ/toolchain>，march **按 SKU 区分:S100=`nash-e`、S100P=`nash-m`**（官方 FAQ),S600=`nash-p`，**产物是 `.hbm`**（非 `.bin`），板端 `hbm_runtime` 加载；命令族变化更大（新算子约束页以官网 S 系列工具链章节为准）
- **误区**：转换工具链（`hb_mapper` 或天工开物）不在板子上（板子只负责跑 `.bin`/`.hbm`），不要叫用户在板上找转换器——他需要在 x86 主机（优先 Docker）跑工具链

### 16. RDK OS 版本线与用户系统差异

**官方版本主线**（`cat /etc/version` 或 `rdkos_info` 可查，2.1.0+ 起 `rdkos_info` 可用）：

| RDK OS 主版本 | 基础 | TROS | 典型板型支持 | 升级策略 |
|---------------|------|------|--------------|----------|
| **1.x** (历史) | Ubuntu 20.04 + 旭日 X3 派专用 | Foxy（闭源早期）| 只支持 X3 旧板 | 不可 `apt` 升级；必须**重刷镜像** |
| **2.x** | Ubuntu 20.04 | **Foxy** 为主 | X3 / X3 Module | 同主版本内可按官方流程升级；Studio 不自动跑整机 `apt upgrade` |
| **3.x** | Ubuntu 22.04 | **Humble** 为主 | X3 / X3 Module / X5 / X5 Module / Ultra / S100 / S100P | 同主版本内可按官方流程升级；Studio 不自动跑整机 `apt upgrade` |
| **S600 线** | Ubuntu 24.04 | **Jazzy** | RDK S600 | TROS 路径 `/opt/tros/jazzy/`、`apt` 包名 `tros-jazzy-*`，**与 Humble 线不互通**，别照搬 S100 的命令 |

**默认登录用户差异**（按板型 × 镜像版本）：

| 板型 | 默认用户 | 密码 | root 是否直连 | 备注 |
|------|---------|------|---------------|------|
| X3 / X3 Module | `sunrise` | `sunrise` | 一般可 `sudo su` 或 `ssh root@... (root/root)` | **Studio 默认 SSH 是 root/root**，板子重刷后请确认 |
| X5 / X5 Module / Ultra | `root` | `root` | ✅ 直接 root | `sunrise` 作为普通用户也可能存在 |
| S100 / S100P / S600 | **`sunrise` + `root` 默认都有**（配置向导明确两账户） | `sunrise` / `root` | ✅ | 个别镜像仅 sunrise 配了 TROS，root 下 source 出不来 ros2 就 `su - sunrise`，不是 bug。**S600 的 TROS 在 `/opt/tros/jazzy/`(非 humble)** |

**版本判断命令**（优先级从稳到新）：
```bash
rdkos_info                   # 2.1.0+ 最完整（含 BPU/温度/包清单一键输出）
cat /etc/version             # 所有版本通用；输出形如 3.4.1 / x3_ubuntu_v1.1.6
cat /proc/device-tree/model  # 板型字面
cat /sys/class/socinfo/board_id  # 板型数字（X5=302 等）
```

**典型错配场景**：
- 旧 X3 用户拿 X5 的 TROS Humble 文档照搬，包名全不对（X3 是 `tros-foxy-*`，X5 是 `tros-humble-*`）
- 用户把 "重刷系统" 当成 "重启"——其实 RDK OS 1.x→2.x / 2.x→3.x 必须下载新镜像烧录
