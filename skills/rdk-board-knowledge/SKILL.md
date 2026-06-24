---
name: rdk-board-knowledge
description: 当需要确认 RDK 板型运行基线、排查常见报错(摄像头/模型/TROS/GPIO/APT 等)、或纠正用户高频误区时使用;附完整故障速查与诊断命令库。本 skill 是报错诊断入口:纯硬件事实/引脚定义走 rdk-hardware,部署闭环走 rdk-device,外设驱动走 rdk-peripheral-cookbook。
---

# RDK 板型基线与故障诊断

> 来源:整理自 D-Robotics RDK 官方文档、工具链与社区实践,逐条保留出处链接;由 device-knowledge 知识库忠实转换而来,未改写技术事实。

## 何时用

确认 RDK 板型与运行基线(是哪块板 / 系统版本)、排查板上常见报错(摄像头、模型/BPU、TROS·ROS2、APT·公钥、GPIO·I2C·串口、供电、网络等)、或纠正用户高频误区(跨板兼容、工具链位置、Studio≠板子等)时使用。模型部署闭环走 rdk-device,外设驱动食谱走 rdk-peripheral-cookbook,产品选型走 rdk-ecosystem。

先用板上事实确认基线,再按"现象→建议→文档"排障;遇到误区先一句澄清再继续。

**遇到以下用户误区时，先用一句话澄清再继续**（不要顺着错误前提走）：
- "X3 的 .bin 拷 X5 能跑" → ❌ 不能，BPU 架构不同（Bernoulli2 vs Bayes），必须用对应工具链重编；X5 与 Ultra 同 Bayes 架构（march 同 `bayes-e`），`.bin` 原则上可互跑，但 Ultra 算力/内存更高，跨板务必各自做性能/精度验证。S100/S100P 是 Nash 架构、产物 `.hbm`，与 X 系列互不通用。
- "`hb_mapper` 在板上 apt install" → ❌ 工具链在**主机 Docker**里用，板上只装 runtime；用户找不到就是正常的。
- "RDK Studio = 板子" → ❌ RDK Studio 是**桌面 IDE**（你就在里面）；板子是 RDK X3/X5/S100 等硬件，靠 SSH/Studio 协作。
- "RDK 是地平线的" → 现品牌是 D-Robotics；旧资料里的 "Horizon/地平线" 指同一条产品线，口径统一回 D-Robotics。
- "Ultra 是 X5 超频版" → ❌ 同 Bayes 架构但算力 ×9.6（96 TOPS）、8GB RAM、需主动散热，定位工业/科研，不是"加强 X5"。
- "hobot_dnn 放 venv/conda 里" → ❌ 只认系统 Python（`/usr/bin/python3`），虚拟环境导入必失败。
- "RDK OS 1.x apt 升到 3.x" → ❌ 跨主版本**必须重刷镜像**；同主版本（如 3.0→3.4）也必须按官方流程评估升级，Studio 不自动跑整机 `apt upgrade`。
- "NodeHub = Model Zoo" → 两个不同仓库：NodeHub 是 ROS2 节点级应用，Model Zoo（`rdk_model_zoo` / `rdk_model_zoo_s`）是模型 + 推理样例。
- "S100 国产 Jetson" → 定位接近，但走 BPU + ONNX 工具链，**不是** CUDA；Jetson 代码不能直接迁移，必须走模型转换。
- **纠正原则**：先一句澄清 → 再问用户"你实际想达成什么"（可能底层需求与板型选择都要改），不要只纠正术语就完事。

## 工作流:确认 RDK 板型与运行基线

**触发场景**:确认板型 / identify board / board profile / 连接新设备 / 不知道是哪块 RDK

**前置条件**:
- 已经通过 SSH、串口或 RDK Studio 打开设备 shell。

**步骤**:

1. **读取板型标识** `[safe]`
   先用板上事实确认硬件，不要根据用户描述猜测 X3/X5/Ultra/S100/S600。
   ```bash
   cat /sys/class/socinfo/board_id      # X5/S 系列(srpi-config、hobot_mipi_cam 都读它)
   cat /sys/class/socinfo/som_name      # X3 文档用 som_name;两者按板型择一
   cat /proc/device-tree/model          # 板型字面;再不行查 /etc/board_config.json
   ```
   预期:输出能映射到 X3、X5、Ultra、S100、S100P 或 S600；未知输出需要继续收集日志。

2. **读取系统镜像版本** `[safe]`
   记录 OS/RDK 版本，后续包名、TROS 路径和工具链建议都要以版本为前提。
   ```bash
   cat /etc/version
   ```
   预期:输出镜像版本；如果文件不存在，改用系统 release 文件和 RDK Studio 设备信息交叉确认。

3. **按板型选择 BPU 监控命令** `[safe]`
   X3 使用 hrut_smi；X5/Ultra 使用 hrut_bpuprofile -b 0；S100/S100P/S600 使用 hrut_bpuprofile；通用兜底 `cat /sys/devices/system/bpu/bpu0/ratio`。
   ```bash
   hrut_bpuprofile -b 0
   ```
   预期:X5/Ultra 能看到 BPU profile 输出；X3 或 S100 系列需要换对应命令。

**验证**:
- 回答中先列出已确认基线:面向用户的下一步建议必须先说明板型、SoC/BPU 架构、系统版本和仍未知的信息。
- 未知板型不套模板:无法确认时追问或请求命令输出，不默认套用 RDK X5 路径。

**安全注意**:
- 本流程只使用只读命令；不要在确认板型前执行刷机、升级或 GPIO 输出类操作。

**预期结果**:助手能把后续安装、模型部署、摄像头、TROS 建议限定到正确板型。

来源:<https://developer.d-robotics.cc/rdk_doc/Quick_start/hardware_introduction/rdk_x3> <https://developer.d-robotics.cc/rdk_doc/Quick_start/hardware_introduction/rdk_ultra> <https://developer.d-robotics.cc/rdk_doc/rdk_s/Quick_start/hardware_introduction/rdk_s100>

## 故障速查:现象 → 切入点

按报错关键词归类,先用下表定位方向,再到 [常见故障速查(55 条)](references/failure-hints.md) 取具体命令与文档:

- **摄像头**(`SIGABRT`/`exit code -6`/`No image data`/`VIDIOC_*`/`timeout`):USB 摄像头 99% 是 YUYV→改 MJPEG,分辨率先用 640x480;`v4l2-ctl -d /dev/video0 --list-formats-ext` 查支持档位,宽高/fps 必须精确匹配。
- **模型/BPU**(`No such file *.bin/.hbm`/`OOM`/`model incompatible`/`unsupported op`):模型路径用 `find /opt/tros -name "*.bin"` 定位别靠相对路径;OOM 看 `cat /sys/devices/system/bpu/bpu0/ratio && free -h`;跨架构(X3=Bernoulli2 / X5·Ultra=Bayes / S100=Nash)hbm/bin 不通用,须用对应工具链重编。
- **TROS/ROS2**(`command not found ros2`/`tros 包找不到`/`NO_PUBKEY`/`setup.bash No such file`):X3/X5/Ultra/S100/S100P 先 `source /opt/tros/humble/setup.bash`(humble);**RDK S600 是 Jazzy → `source /opt/tros/jazzy/setup.bash`**(Ubuntu 24.04,包名 `tros-jazzy-*`,别找 humble);APT 公钥失效按官方 TROS 文档重配 keyring;S100/S600 部分镜像需 `su - sunrise` 再 source。
- **GPIO/I2C/串口/PWM**(`Permission denied`/`gpiochip not found`/`/dev/i2c`/`ttyUSB`):引脚缺总线多半未做 Pinmux 复用;gpiochip 编号各板不同别照抄 RPi,用 `gpiofind`;串口权限把用户加入 `dialout` 组后重新登录。
- **供电/挂死**(`under-voltage`/`throttled`/`kernel panic`/`System halted`):首查供电(5V/3A 起,Ultra·S100 推荐 5V/5A),再查温度(>85°C 需散热),用官方电源避免 USB-A→USB-C 转接。
- **网络/SSH**(`Connection refused`/`timeout`/`Host key verification failed`):`ip addr`+`ping`;重刷系统后 `ssh-keygen -R <ip>` 清旧密钥。
- **设备未识别**(`No such device`/`ENODEV`):跑通用诊断 `dmesg | tail -50 && lsusb && ls /dev/tty* /dev/video* /dev/i2c-* /dev/snd/`,定位接口再针对性排查。

## 诊断命令安全分级

诊断命令按风险分 safe / moderate / dangerous([完整命令库](references/diagnostic-commands.md)):

- **safe(只读,可直接用)**:BPU/SoC 监控、`free`/`df`/`dmesg`/`journalctl`、`cat /sys/...`、`ip addr`。全板通用兜底:`cat /sys/devices/system/bpu/bpu0/ratio`(BPU 占用)、`hrut_somstatus`(温度/电压/频率)。
- **moderate(改系统状态,先确认意图)**:`apt`/`pip`/`npm install`、`systemctl`、`nmcli`、`docker run`、`insmod`/`modprobe`、kernel headers 编译。
- **dangerous(可毁系统/需明确授权)**:`dd`、`mkfs`、`rm -rf /`、`fdisk`/`parted`、flash 擦写、`modules_install`/`depmod`、`/boot`·`/lib/modules`·`/etc/fstab` 写入、bootloader/initramfs 变更。确认板型前不执行刷机、升级或 GPIO 输出类操作。

## 硬件参考主题

以下主题详见 [硬件与系统参考](references/hardware-notes.md):

- 常见开发陷阱
- 用户高频误区与一句话纠正

## 参考资料

- [常见故障速查(55 条)](references/failure-hints.md)（含摄像头/模型/TROS/GPIO/供电/网络/设备识别等子类;遇具体报错时查）
- [官方 FAQ 速查(按主题分组)](references/official-faq.md)（D-Robotics 官方 rdk_doc/rdk_s_doc 的 08_FAQ 全文要点 + 官方 URL + 覆盖板型;S 系列特有条目单列。failure-hints 是经验性"现象→建议",这里是官方"问题→答案要点",互补使用）
- [诊断与系统命令](references/diagnostic-commands.md)
- [硬件与系统参考(详细章节)](references/hardware-notes.md)
