# RDK 具身智能部署工作流参考

> 来源:[D-Robotics/rdk_LeRobot_tools](https://github.com/D-Robotics/rdk_LeRobot_tools)(`stable` 分支)、[D-Robotics/lerobot](https://github.com/D-Robotics/lerobot)、[D-Robotics/openpi_runtime](https://github.com/D-Robotics/openpi_runtime) README,逐条保留出处;命令以仓库当前版本为准。

## A. LeRobot ACT 完整流程

### A.1 开发机环境(模型转换)

强烈建议用 D-Robotics fork 以保证兼容(已锁 `datasets` 版本,兼容 v2.1 数据集):

```bash
git clone https://github.com/D-Robotics/lerobot.git
cd lerobot
git clone https://github.com/D-Robotics/rdk_LeRobot_tools.git
pip install -e ".[feetech]"
pip install onnx onnxsim termcolor tqdm   # ONNX 导出依赖
```

用上游官方仓的替代方案(自担兼容风险):

```bash
git clone https://github.com/huggingface/lerobot.git
cd lerobot
git checkout 8cfab3882480bdde38e42d93a9752de5ed42cae2   # v2.1 对应 commit
git clone https://github.com/D-Robotics/rdk_LeRobot_tools.git
pip install -e ".[feetech]"
# 仍报兼容错时:pip install datasets==2.19.0
```

### A.2 导出 ONNX + 配置

编辑 `bpu_export_config.yaml`:

| 字段 | 含义 |
| --- | --- |
| `dataset.root` | 训练所用数据集根目录(顶层字段) |
| `act_path` | 训练好的 ACT checkpoint 目录(顶层字段;含 `config.json` + `model.safetensors`) |
| `type` | **顶层字段**·BPU 芯片类型:`nash-e`/`nash-m`/`nash-p`(RDK S100/S100P);`bayes`/`bayes-e`(RDK X5)。脚本据此自动调编译参数。**勿与 `policy.type:"act"` 混淆**(那是策略类型,不是芯片) |

```bash
python export_bpu_actpolicy.py --config bpu_export_config.yaml
# 产出 bpu_export_output/:ONNX 模型、校准数据、build_all.sh
```

### A.3 编译 ONNX → BPU 模型

- 在 D-Robotics **OpenExplorer Docker 工具链**(非板上)里执行生成的 `build_all.sh`。
- S100/S100P(Nash)产物为 **`.hbm`**;X5(Bayes-e)为 `.bin`(脚本含真实 bayes 编译分支,但官方仅在 S100/S100P 验证过 ACT,X5/bayes 路径未充分验证——能编出 `.bin` ≠ X5 端到端可用,投入前先告知用户)。

### A.4 板端部署与控制

```bash
# 1. 板端 LeRobot(D-Robotics fork,已锁 datasets)
git clone https://github.com/D-Robotics/lerobot.git
cd lerobot && pip install -e .
# 2. 板端 BPU 推理库
pip install hbm-runtime
# 3. 加载编译好的 BPU 模型并控制机器人
python bpu_control_robot.py --bpu-act-path ./bpu_output
#   --bpu-act-path  BPU 模型目录(须含 .hbm 与 .npy)
#   --fps           控制循环频率(默认 30Hz)
#   --inference-time 自动运行时长(秒)
# 默认连 so101 机器人;换臂改代码里的 make_robot("so101")
```

> 验证转换正确性:比对 `bpu_output` 里的 `new_actions.npy`(转换前 PyTorch 推理结果)与板端 BPU 输出。

`rdk_LeRobot_tools` 关键文件:

| 文件 | 运行位置 | 作用 |
| --- | --- | --- |
| `export_bpu_actpolicy.py` | 开发机/训练服务器 | PyTorch 权重 → ONNX + 编译配置/脚本 |
| `bpu_export_config.yaml` | 开发机 | 导出配置 |
| `bpu_control_robot.py` | RDK 板 | 加载 BPU 模型、控制机器人 |
| `damo/` | — | DAMO 开发者矩阵·LeYun(乐云)具身智能开发平台适配(`damo/replace.py` 改 `folder_path` 后 `python damo/replace.py` 改键,再导出) |

> 边界:`stable` 分支当前**仅验证 ACT 模型 + RDK S100/S100P(+ SO-101 机械臂)**;v2.1 数据集兼容。README 写 S100、WORKFLOW_GUIDE 写 S100/S100P,以后者为准。更新版 LeRobot 需切对应分支。

## B. VLA / Pi0(openpi_runtime)

基于 Pi0 量化部署的视觉-语言-动作运行时,**跑在 RDK S600 板(Ubuntu 24.04 / ROS2 Jazzy)上**控制双臂机械臂(S600 是开发板,不是机械臂),client-server 架构。

### B.1 数据规格

| 项 | 形状 | 类型 | 说明 |
| --- | --- | --- | --- |
| 图像 ×3 | `[3,224,224]` | uint8 | 头部 / 左腕 / 右腕(右腕用黑图占位) |
| 状态 | `[14]` | float32 | 左右臂各关节 + 夹爪 |
| 指令 | — | string | 如 "put the yellow mango on the blue plate" |
| 动作输出 | `[50,14]` | float32 | 50 步,每步左右臂各 6 关节 + 夹爪 |

### B.2 架构与时延

- 多相机 ROS2 话题**时间同步**(`TopicTimeSynchronizer`,100ms 窗)。
- 流水线:数据采集 → 前处理 → 推理 → 后处理 → 执行,全链路监控。
- Pi0 推理在 **server(OE-LLM)**;`piper_node` 控制机械臂;动作做插值(首步从当前状态插入、末步平滑收敛)+ 一阶低通滤波。

| 阶段 | 平均时延 |
| --- | --- |
| 数据采集 | 0.1ms |
| 前处理 | 3.2ms |
| 推理(server) | 192.5ms |
| 后处理 | 0.1ms |

### B.3 最小可跑清单(以官方 develop README 为准)

```bash
# 1. 模型:从 huggingface.co/D-Robotics/openpi 取对应任务的 HBM 量化模型 + norm_stats.json
#    (norm_stats.json 在 .../<task>/torch/assets/trossen/ 下,须与所用模型匹配)
# 2. 环境(Python 3.12)
conda create -n s600_pi0 python=3.12 && conda activate s600_pi0
pip install -r resource/requirements.txt        # colcon build 见 README
# 3. 启动顺序
ros2 launch realsense2_camera rs_launch.py ...   # 头部 + 左腕相机
python3 install/lib/openpi_runtime/piper_node ... --publish_topic /piper/qpos
ros2 run ... s600_inference_node --ros-args \
  -p norm_stats_path:=norm_stats.json -p num_steps:=1250   # num_steps 默认 1250
```

> 完整 colcon build、各节点参数、相机话题名以 [openpi_runtime](https://github.com/D-Robotics/openpi_runtime) develop README 为准;这里只给最小落地骨架。

## C. 相关具身生态仓

| 仓库 | 用途 |
| --- | --- |
| [rdk_LeRobot_tools](https://github.com/D-Robotics/rdk_LeRobot_tools) | LeRobot ACT → BPU 导出/部署工具 |
| [lerobot](https://github.com/D-Robotics/lerobot) | D-Robotics fork,policy on BPU,锁版本 |
| [openpi_runtime](https://github.com/D-Robotics/openpi_runtime) | Pi0 VLA 推理运行时(S600) |
| [openpi](https://github.com/D-Robotics/openpi) | openpi + x86 server/训练配置 |
| [RoboTwin](https://github.com/D-Robotics/RoboTwin) | 双臂仿真/数据 |
| [embodied_ai_robots](https://github.com/D-Robotics/embodied_ai_robots) | 具身机器人示例 |
| [Alicia-D-SDK](https://github.com/D-Robotics/Alicia-D-SDK) | 机械臂 SDK |

> S100 的 CPU(6×A78AE)/BPU(Nash)/MCU(4×R52+ 实时控制)三块异构算力分工、固件烧录、向板端 agent 交接任务,见 rdk-board-delegate。
