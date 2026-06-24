---
name: rdk-embodied-lerobot
description: 当用户要在 RDK 板(尤其 S100/S100P/S600)上部署具身智能策略——LeRobot ACT 模仿学习策略、VLA 视觉-语言-动作模型(Pi0/openpi)、机械臂(SO-101/piper)动作控制、把训练好的 policy 编译到 BPU、用 export_bpu_actpolicy.py / hbm-runtime / bpu_control_robot.py 时使用。S100 三块异构算力(CPU/BPU/MCU)的硬件分工与板端任务委派走 rdk-board-delegate;通用模型量化工具链走 rdk-device;ROS2 环境走 rdk-ros;板端 LLM/VLM 对话与语音走 rdk-llm-deployment。
---

# RDK 具身智能:LeRobot 与 VLA 部署

> 来源:[D-Robotics/rdk_LeRobot_tools](https://github.com/D-Robotics/rdk_LeRobot_tools)、[D-Robotics/lerobot](https://github.com/D-Robotics/lerobot)、[D-Robotics/openpi_runtime](https://github.com/D-Robotics/openpi_runtime) 官方仓库 README,逐条保留出处;技术事实未改写,版本/分支以仓库当前状态为准。

## 何时用

用户要把**机器人动作策略**跑到 RDK 上:LeRobot 训练的 ACT 策略、Pi0/openpi 这类 VLA 模型、机械臂"看图听指令→输出关节动作"。本 skill 给软件部署路径。
S100 的 CPU/BPU/MCU 谁干什么、固件烧录、向板端 agent 交接任务 → rdk-board-delegate;通用 `.onnx→.bin/.hbm` 量化细节 → rdk-device;`ros2` 命令/环境 → rdk-ros。

**两条主路径**:① LeRobot **ACT**(模仿学习,`rdk_LeRobot_tools`);② **VLA / Pi0**(视觉-语言-动作,`openpi_runtime`)。

## 铁律 — 用 D-Robotics fork,锁死依赖版本

具身这套对环境极敏感,**不要直接用 HuggingFace 上游 LeRobot**:

- 开发机与板端都克隆 **[D-Robotics/lerobot](https://github.com/D-Robotics/lerobot)**(已锁 `datasets` 版本,兼容 v2.1 数据集)。
- 若坚持用上游官方仓:`git checkout 8cfab3882480bdde38e42d93a9752de5ed42cae2`(v2.1 对应 commit),遇兼容报错手动 `pip install datasets==2.19.0`。
- `rdk_LeRobot_tools` 当前为 **stable 分支**,**目前只验证过 ACT 模型在 RDK S100/S100P(+ SO-101 机械臂)上的部署**;其他板型/架构(如 X5)未充分验证,先告知用户这条边界,别夸大。

## 路径 ① — LeRobot ACT 部署(三段式)

> 详细命令、`bpu_export_config.yaml` 字段、板端运行见 [lerobot-workflow](references/lerobot-workflow.md)。

1. **开发机:导出 ONNX + 配置**
   - 克隆 `D-Robotics/lerobot` → `pip install -e ".[feetech]"` → 仓内再 `git clone rdk_LeRobot_tools`;`pip install onnx onnxsim termcolor tqdm`。
   - 改 `bpu_export_config.yaml`:`dataset.root`(训练数据根)、`act_path`(ACT checkpoint 目录,含 `config.json`+`model.safetensors`)、`type`(平台:S100 用 `nash-e`/`nash-m`/`nash-p`,X5 用 `bayes`/`bayes-e`)。
   - `python export_bpu_actpolicy.py --config bpu_export_config.yaml` → 产出 `bpu_export_output/`(ONNX、校准数据、`build_all.sh`)。
2. **开发机:编译 ONNX → BPU 模型**
   - 在 D-Robotics **OpenExplorer Docker 工具链**里跑 `build_all.sh`,S100 产物为 **`.hbm`**(Nash 架构;这点与 X3/X5 的 `.bin` 不同)。
3. **板端:加载并控制机器人**
   - 克隆 `D-Robotics/lerobot` → `pip install -e .` → `pip install hbm-runtime`(板端 BPU 推理库)。
   - `python bpu_control_robot.py --bpu-act-path ./bpu_output`(目录须含 `.hbm` + `.npy`)加载编译好的 BPU 模型 → 控制机械臂;`--fps` 默认 30Hz,默认连 `so101` 机械臂。
   - `damo/` 是面向 DAMO 开发者矩阵·LeYun(乐云)具身智能开发平台的适配工具集(`damo/replace.py` 改键后再导出)。

## 路径 ② — VLA / Pi0(openpi_runtime)

基于 [Pi0](https://github.com/Physical-Intelligence/openpi) 量化部署的 **视觉-语言-动作** 运行时,**跑在 RDK S600 板(Ubuntu 24.04 / ROS2 Jazzy)上**控制双臂机械臂(S600 是开发板,不是机械臂),采用 **client-server**:

- **S600 推理节点(client,运行在 RDK S600 板上)**:多相机(头部 + 左腕,右腕用黑图占位)ROS2 话题**时间同步**(100ms 窗)→ 采集/前处理/动作执行。
- **Pi0 推理(server,OE-LLM)**:负责动作预测;`piper_node` 执行机械臂控制。
- **输入**:图像 `[3,224,224] uint8`×3 + 状态 `[14] float32` + 文本指令(如 "put the yellow mango on the blue plate")。
- **输出**:动作序列 `[50,14] float32`(50 步,每步左右臂各 6 关节 + 夹爪)。
- **时延参考**:采集 0.1ms / 前处理 3.2ms / 推理 192.5ms(server 端)/ 后处理 0.1ms;动作做插值 + 一阶低通滤波平滑。
- **环境 / 模型 / 启动**(Python 3.12 + ROS2):HBM 模型与 `norm_stats.json` 取自 [huggingface.co/D-Robotics/openpi](https://huggingface.co/D-Robotics/openpi);最小可跑清单见 [lerobot-workflow](references/lerobot-workflow.md) B.3。

## 高频坑

- **直接用上游 LeRobot / 新版 datasets** → 加载历史 v2.1 数据集报错。用 fork 或 `datasets==2.19.0`。
- **`type` 填错 march** → S100=`nash-e`、S100P=`nash-m`,X5 用 `bayes*`;`bpu_export_config.yaml` 的 `type` 枚举为 `nash-e/nash-m/nash-p/bayes-e/bayes`(`nash-p` 是真实变体)。
- **以为 ACT 工具链能直接上 X5/S600** → `rdk_LeRobot_tools`(stable)**官方只验证过 S100/S100P + SO-101**;**S600 的 ACT 未在该工具链文档验证**(S600 是 4× Nash,具体 march 以工具链最新文档为准),投入前先告知用户。VLA/Pi0 路径才是 S600 的已知场景。
- **VLA 当成纯板端单机** → openpi 是 client-server,Pi0 推理在 server(OE-LLM),板端是采集 + 执行 + 同步。
- **以为本 skill 覆盖机械臂"从零"** → ❌ 本 skill 只管"**已训练 policy → BPU 部署**"。SO-101/piper 物理接线、舵机 ID/零点标定、串口波特率、遥操作采集、ACT 训练超参等**前半程在上游 [huggingface/lerobot](https://github.com/huggingface/lerobot) 与 [D-Robotics/lerobot](https://github.com/D-Robotics/lerobot)**(本仓 fork),不在本仓覆盖。

## 相关生态仓

`rdk_LeRobot_tools`、`lerobot`(BPU)、`openpi_runtime`、`openpi`、`RoboTwin`、`embodied_ai_robots`、`Alicia-D-SDK`(机械臂 SDK)。完整清单见 [lerobot-workflow](references/lerobot-workflow.md)。
