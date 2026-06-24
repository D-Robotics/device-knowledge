---
name: rdk-hardware
description: 当用户问 RDK 板子的硬件事实——各板引脚是否相同/40PIN 怎么接、默认用户名密码、模型目录在哪、摄像头/CAN/网口等接口、各板算力内存差异、要不要散热、系统路径与 OS 版本线时使用。本 skill 给硬件子系统的事实底座:要排报错故障→rdk-board-knowledge;要动手驱动外设(点灯/转电机)→rdk-peripheral-cookbook;要端到端部署模型→rdk-device;要选型买哪块板→rdk-ecosystem。
---

# RDK 硬件与系统基础

> 来源:整理自 D-Robotics RDK 官方文档、工具链与社区实践,逐条保留出处链接;由 device-knowledge 知识库忠实转换而来,未改写技术事实。

操作 RDK 前必须先确认板型;本 skill 覆盖各硬件子系统与系统底座的事实性知识。

**板型感知（操作前必须确认）**：
- 用 `cat /sys/class/socinfo/board_id` 或 `cat /etc/version` 确认板型（**通用，所有板型都装**），不要假设
- BPU 监控请按板型选命令：X5 用 `hrut_bpuprofile -b 0`；X3 才有 `hrut_smi`/`bputop`；最稳的兜底是 `cat /sys/devices/system/bpu/bpu0/ratio`（所有板型都通用）
- 模型格式**不通用**：X3=Bernoulli2(.bin), X5/Ultra=Bayes(.bin), **S100/S100P/S600=Nash(.hbm，由 hbm_runtime 加载)**，跨板型必须重新编译
- 算力(INT8 TOPS)/内存(GB)对照：X3(5/2) → X5(10/4 或 8，两个 SKU) → Ultra(96/8) → S100(80/12) → S100P(128/24) → **S600(560/32 或 64，4× Nash core)**；方案选择须匹配硬件能力，规格以 [board-specs](references/board-specs.md) 为单一事实源
- S100/S600 特有：MCU(R52+)实时控制、Nash 架构支持 Transformer 算子;X3 仅适合轻量模型和教学
- **S600 是 S 系列新旗舰板(非机械臂)**:18× A78AE + 6× R52+ + 4× Nash BPU(560 TOPS),系统 **Ubuntu 24.04 + TROS Jazzy**(`/opt/tros/jazzy/`,包名 `tros-jazzy-*`),与 S100(22.04/Humble)的路径/包名不同,**别照搬**
- 默认用户：官方 RDK 镜像普遍**同时提供 `sunrise/sunrise`(普通)+ `root/root`(超级)**两个账户。**X3** 主登录 sunrise（RDK Studio SSH 多为 root，重刷后确认）；**X5/Ultra** root 直连、sunrise 也在；**S100/S100P/S600** 官方配置向导默认两者都有(个别镜像仅 sunrise 配了 TROS,出不来 ros2 就 `su - sunrise`)
- 模型目录：**X5 在 `/opt/hobot/model/x5/`（无 rdk 前缀）**；X3 在 `/opt/hobot/model/rdkx3/`（有 rdk 前缀，历史遗留）；S100 在 `/opt/hobot/model/s100/`（以实际 `ls` 为准）

**先验证再执行**：
- 文档/示例中的路径、包名、端口号可能与实际不符 — 先 `ls`/`find`/`ros2 pkg prefix` 确认再执行
- 相对路径（如 `config/xxx.hbm`）可能依赖特定工作目录 — 改用 `find /opt/tros -name "*.hbm"` 定位绝对路径
- 搜索 RDK 内容：优先 `site:developer.d-robotics.cc/rdk_doc` 或 `site:forum.d-robotics.cc`，官方文档 > GitHub > 社区帖子
- 按文档执行连续失败 2 次：停下来重新审视，可能文档过时或板型不同
- 不同板型信息**禁止混用**（X3 的 pinout 不能给 X5 用户）

**硬件操作安全**：
- GPIO: 3.3V 逻辑电平，不同板型 pinout 不同 — 操作前查当前板型文档
- I2C: 先 `i2cdetect -y <bus>` 扫描确认地址存在再读写
- PWM: 控制舵机/电机先低频低占空比测试，避免硬件损坏
- 散热: Ultra/S100 长时间满载需主动散热 — `hrut_somstatus` 监控温度
- 网络排障: `ip addr` → `ping 8.8.8.8` → `ping <gateway>` → `nmcli`

## 硬件参考主题

以下主题各带一句导航要点,细节详见 [硬件与系统参考](references/hardware-notes.md):

- **40PIN GPIO** — 物理兼容树莓派但 GPIO 编号不同,不能套用 RPi 编号;Python 用 `Hobot.GPIO`,C 用 `libwiringpi`
- **摄像头系统** — MIPI 用 `hobot_mipi_cam`(指定 sensor 与 video_device);USB UVC 用 `hobot_usb_cam`,默认 YUYV 不稳必须设 **MJPEG**(先 `v4l2-ctl --list-formats-ext` 确认);GMSL 仅 S100/S100P 且需扩展板
- **BPU 推理流水线** — C/C++ 用 `libdnn`/`bpu_infer_lib`,Python 在 X3/X5/Ultra 用 `hobot_dnn`(需系统 Python,不支持 conda/venv)、在 S100/S100P 用 `hbm_runtime`,ROS2 用 TROS 推理节点;监控优先级:sysfs 节点(最稳) → `hrut_bpuprofile`(X5/Ultra) → 最后才 `hrut_smi`/`bputop`(勿假设存在)
- **模型转换概要** — X3/X5/Ultra 链路 `ONNX → hb_mapper checker → hb_mapper makertbin → .bin`;**S100/S100P 走天工开物/OE 工具链,产物 `.hbm`**;均在 x86 主机(优先 Docker)跑,不在板子上;PTQ 需校准数据集
- **系统路径与存储** — `/opt/tros/humble/` 只读;`/userdata/`、`/tmp/`、`$HOME` 可写;板型识别 `cat /sys/class/socinfo/board_id`
- **网络与连接** — 排障顺序 `ip addr` → `ping`;WiFi 用 `nmcli dev wifi connect`;CAN **仅 X5 是 SocketCAN**(`ip link set can0 ...`),**S100/S600 的 CAN 在 MCU 域走 CANHAL,不能用 `ip link`**(详见 rdk-peripheral-cookbook);多机 ROS2 须 `ROS_DOMAIN_ID` 一致 + 放行 UDP 7400+
- **散热与功耗** — X3/X5 被动通常够;Ultra **必须**主动散热(12V/3A);S100 12-20V 供电;温度查 `hrut_somstatus`
- **镜像与 TROS 工程** — TROS 一键构建入口 `robot_dev_config`(跑 `init.sh`);镜像构建 `rdk-gen`(X3)/`x5-rdk-gen`(X5)
- **BPU 架构演进与模型互通性** — Bernoulli2(X3,仅 CNN) → Bayes(X5/Ultra,部分 Attention) → Nash(S100,CNN+Transformer);产物跨架构不互通必须重编(X3/X5/Ultra=`.bin`,S100/S100P=`.hbm`);S100 用「天工开物」工具链,命令族与 `hb_mapper` 不同
- **RDK OS 版本线与用户系统差异** — 1.x/2.x(Foxy) vs 3.x(Humble);跨主版本须**重刷镜像**不能 `apt` 升级;版本判断优先 `rdkos_info`(2.1.0+) → `cat /etc/version`

## 参考资料

- [RDK 板型规格对照](references/board-specs.md)（查阅时机:需核对某块板的 RAM/算力/接口数量/探测标识时）
- [硬件与系统参考(详细章节)](references/hardware-notes.md)（查阅时机:确认板型后,需要某子系统的展开细节时）
