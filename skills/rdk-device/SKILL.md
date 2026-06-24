---
name: rdk-device
description: 当用户要在 RDK 板上把自己的模型走工具链端到端部署(.pt/.onnx→.bin/.hbm BPU 量化转换)、首次开箱联网、跑摄像头/视觉推理(完整排障+推理闭环;只查报错对照走 rdk-board-knowledge)、或从 0 到 1 上手时使用;含端到端工作流。本 skill 特指"自己量化转换后端到端跑通";直接取官方预编译现成模型跑→rdk-model-zoo;把推理跑成 ROS 节点/双目深度/激光雷达→rdk-ros;具身策略(ACT/VLA/Pi0)的 BPU 编译与 export_bpu_actpolicy.py→rdk-embodied-lerobot。
---

# RDK 设备控制与模型部署

> 来源:整理自 D-Robotics RDK 官方文档、工具链与社区实践,逐条保留出处链接;由 device-knowledge 知识库忠实转换而来,未改写技术事实。

最高频痛点是把 .pt/原生 .onnx 直接拷上板(只走 CPU)——先打断纠正,再走 BPU 工具链闭环。

**最高频误区 — 直接把 `.pt` / 原生 `.onnx` 拷上 RDK 板跑（社区 60% 卡壳在这）**：
- **现象**：用户说"部署 YOLOv5"、"我把 pt 拷上去"、"推理很慢 / 1-2 FPS / 视频流很卡"、"帧率上不去"——几乎都是没走 BPU 工具链。
- **立即打断**：不要顺着他调性能，**先告诉他** `.pt` / 原生 `.onnx` 在 RDK 板上**只走 CPU**，BPU 完全没参与，慢是预期。
- **正解流程**（三段式话术）：
  1) **主机 x86 + Docker**：克隆**官方 `ultralytics/yolov5` 仓**,按 D-Robotics model_zoo 文档**改 Detect 输出头**(去掉非 BPU 友好算子、改 4 维 NHWC 输出)再导 `.onnx`;`checkout v2.0`(LeakyReLU 版)或 **`v7.0`(Sigmoid 版,按文档改输出头)**都支持——不是"只能 v2.0",别误导
  2) **量化转换(主机 Docker 内)**——两条链路命令不同,别混:
     - **X3/X5/Ultra**:`hb_mapper checker` 验证算子 → 准备 ~50-100 张校准图片 → `hb_mapper makertbin --config x.yaml` 产 `.bin`
     - **S100/S100P/S600(天工开物/OE)**:工具是 **`hb_compile`**(不是 hb_mapper)——`hb_compile --model x.onnx --march nash-e` 快速验证 → 准备 ~100 张校准图(`horizon_tc_ui` transformer 预处理存 `.npy`)→ `hb_compile --config x.yaml` 产 `.hbm`(同时产 `*_quantized_model.bc` HBIR 可在 x86 比对精度)
     命令、march、config.yaml 模板见 [BPU 工具链对照](references/toolchain-workflow.md)。
  3) 产物（`.bin`/`.hbm`）scp 到板上 `/userdata/models/` → X3/X5/Ultra 用 `hobot_dnn` / TROS ROS2 节点加载（例如 `dnn_node_example`），S100/S100P/S600 用 `hbm_runtime`
- **`march` 参数对照**（官方 FAQ 按板型区分）：X3=`bernoulli2`、Ultra=`bayes`、X5=`bayes-e`、**S100=`nash-e`、S100P=`nash-m`**、S600=`nash`(具体后缀以工具链最新文档为准)。**产物格式按架构**:X3/X5/Ultra=`.bin`,S100/S100P/S600=`.hbm`。
- **不要**让用户在**板上** `apt install hb_mapper`——工具链在**主机 Docker** 里跑，板上只有 runtime（X3/X5/Ultra 是 `hobot-dnn`,S100/S100P 是 `hbm_runtime`）。
- 若用户目的只是"想看效果"而非严肃部署，**引导他先跑预装的 `/app/pydev_demo/`**(X5 3.5.0+ 是 `02_detection_sample/` 或 `09_web_display_camera_sample/`;以板上 `ls /app/pydev_demo/` 为准)验证板卡正常，再谈自训模型。

**新手"从 0 到 1"应对口径**（用户说"怎么开始 / 新手 / 刚拿到板 / 开箱 / 入门"）：
- **不要**一上来就讲 BPU 架构 / 工具链，按这个顺序引导：
  1) 烧录 → 2) 供电（**必须官方电源**，5V/5A；电脑 USB 口会反复重启）→ 3) 指示灯（橙色状态灯**闪烁**=系统正常,3.1.0+ 才有）→ 4) `srpi-config` 首配 Wi-Fi/SSH → 5) 获取 IP → 6) SSH(各板 **root/root 与 sunrise/sunrise 都有**;S100/S600 管理口 eth1 固定 `192.168.127.10`)→ 7) 跑 `/app/pydev_demo/`(X5 3.5.0+ 用 `02_detection_sample/`)→ 8) 跑 `09_web_display_camera_sample/` 看浏览器实时画面
- **预装示例**都在 `/app/pydev_demo/` 下:X5 3.5.0+ 是 9 个**按任务命名**目录(分类/检测/分割/姿态…,用 `hbm_runtime`);旧 X5/X3 是编号清单(`pyeasy_dnn`)。**先 `ls /app/pydev_demo/` 看实际**,别背编号。演示优先推 `09_web_display_camera_sample`(Web 实时)。详见 references。
- 用户烧录失败 / 橙灯不亮 → 先怀疑**镜像校验**和**SD 卡质量**（≥ 8GB Class 10），再怀疑烧录工具。
- 已连设备后想自训模型 → **不要急着转换**，先让他在预装 demo 上跑通一遍，确认板卡正常；再进入模型转换全流程。

**摄像头排障流程**（必须按顺序）：
1. 探测: `ls /dev/video*` + `lsusb`（USB）或 `dmesg | grep -i mipi`（MIPI）
2. 验证: `v4l2-ctl -d /dev/video0 --list-formats-ext` → 找 MJPEG 支持的分辨率+fps
3. 配置: launch 参数设为 MJPEG + 精确匹配的分辨率，先用 640x480 验证
4. 确认图像 topic 正常后，再挂推理/检测节点
同一错误重复 2 次须先查 rdk_doc，不要反复尝试同一参数

**模型部署流程**：
1. `cat /sys/class/socinfo/board_id` 确认板型和 BPU 架构 → 选对应工具链版本（X3=Bernoulli2 / X5/Ultra=Bayes / S100=Nash）
2. ONNX → 量化转换:X3/X5/Ultra 用 `hb_mapper checker`→`hb_mapper makertbin` 出 `.bin`;S100/S100P/S600 用天工开物/OE 的 **`hb_compile`**(`--model x.onnx --march nash-e` 验证 → `--config x.yaml` 出 `.hbm`)。详见 [BPU 工具链对照](references/toolchain-workflow.md)
3. `hb_eval_perf` 评估推理性能 → 确认 fps/latency 满足需求
4. 部署到 `/userdata/models/` 或 TROS 包内 `config/` 目录
5. 转换失败查算子支持列表；Transformer 算子仅 S100 Nash 部分支持

## 工作流:首次启动、联网并接入 RDK Studio

**触发场景**:快速上手 / first boot / RDK Studio 连接 / SSH 登录 / 烧录后连接不上

**前置条件**:
- 已准备匹配板型的官方镜像、电源、存储介质和主机端 RDK Studio。

**步骤**:

1. **确认供电和启动状态** 
   优先排除电源不足、镜像不匹配和存储介质质量问题。
   预期:板卡稳定启动，指示灯和串口/屏幕日志没有反复重启迹象。

2. **确认网络地址** `[safe]`
   通过路由器、串口、屏幕或 Studio 设备发现流程找到板端 IP。
   ```bash
   ip addr
   ```
   预期:能看到 eth0/wlan0 等接口地址；没有地址时先处理网络配置。

3. **验证远程登录** `[safe]`
   按板型和镜像确认默认用户，再通过 SSH 或 Studio 终端进入设备。
   ```bash
   ssh root@<device-ip>
   ```
   预期:成功进入 shell；认证失败时先核对镜像、用户和网络，不直接建议重刷。

4. **在 Studio 中确认设备资源** 
   使用 RDK Studio 设备管理页查看硬件资源、终端、文件和集成工具是否可用。
   预期:Studio 侧能显示设备资源，并能打开终端或文件管理能力。

**验证**:
- 端到端连通 — `hostname && cat /etc/version`:终端命令能返回设备名和系统版本。
- Studio 连接状态:RDK Studio 设备管理页显示在线，核心集成工具可进入。

**安全注意**:
- 刷机和重置网络都属于确认型操作；先完成只读诊断，再让用户确认是否继续。

**预期结果**:用户能从新板开箱进入一个可被 Studio 管理、可执行命令的稳定状态。

来源:<https://developer.d-robotics.cc/rdk_doc/Quick_start/RDK_Studio/flashing> <https://developer.d-robotics.cc/rdk_doc/Quick_start/RDK_Studio/Device_management/integration_tools> <https://developer.d-robotics.cc/rdk_doc/Quick_start/remote_login>

## 工作流:BPU 模型转换与部署闭环

**触发场景**:部署模型 / YOLO 转换 / hb_mapper / pt 直接跑很慢 / BPU 推理

**前置条件**:
- 已确认板型和 BPU 架构。
- 模型训练产物可导出 ONNX。
- 主机侧具备官方工具链环境或 Docker。

**步骤**:

1. **确认目标 BPU 架构** `[safe]`
   X3=Bernoulli2，X5/Ultra=Bayes，S100/S100P=Nash；跨架构产物不能复用（X3/X5/Ultra=`.bin`，S100/S100P=`.hbm`）。
   ```bash
   cat /sys/class/socinfo/board_id
   ```
   预期:板型能映射到正确工具链 march 参数。

2. **在主机工具链中检查 ONNX** `[moderate]`
   先做算子支持检查，避免把不支持的模型拷到板上才排障。
   ```bash
   hb_mapper checker --model-type onnx --model <model.onnx>
   ```
   预期:checker 通过；失败时根据不支持算子调整导出或模型结构。

3. **准备校准数据并生成产物（X3/X5/Ultra=`.bin`，S100/S100P=`.hbm`）** `[moderate]`
   用覆盖真实输入分布的校准图片完成量化转换。
   ```bash
   hb_mapper makertbin --config <model-config.yaml>   # X3/X5/Ultra;S100/S100P 用天工开物/OE 工具链产 .hbm
   ```
   预期:生成匹配目标架构的产物（`.bin`/`.hbm`）和转换报告。

4. **拷贝模型并接入 runtime/TROS 节点** `[moderate]`
   把产物放入项目模型目录，X3/X5/Ultra 用 hobot_dnn 或对应 TROS 节点加载，S100/S100P 用 `hbm_runtime`。
   ```bash
   scp <model.bin|model.hbm> root@<device-ip>:/userdata/models/
   ```
   预期:板端能读取模型文件，launch/config 指向绝对存在的路径。

**验证**:
- 转换性能评估 — `hb_eval_perf --model <model.bin>`:输出 latency/fps，且结果满足项目目标或给出明确瓶颈。
- 板端 BPU 参与推理 — `hrut_bpuprofile -b 0`:推理时 BPU 利用率有变化；若没有变化，优先检查是否仍在 CPU 路径运行。

**安全注意**:
- .pt 或原生 ONNX 拷到板上直接跑通常只走 CPU，不应当作为 BPU 部署成功。
- 不要建议用户在板上安装 hb_mapper；转换链路属于主机侧工具链任务。

**预期结果**:用户得到一个经过 checker、量化、性能评估、板端加载验证的 BPU 部署闭环。

来源:<https://developer.d-robotics.cc/rdk_doc/Advanced_development/toolchain_development/expert/user_guide> <https://developer.d-robotics.cc/rdk_doc/Advanced_development/toolchain_development/expert/api_reference> <https://github.com/D-Robotics/rdk_model_zoo> <https://github.com/D-Robotics/rdk_model_zoo_s>

## 工作流:USB/MIPI 摄像头排障闭环

**触发场景**:摄像头无画面 / camera timeout / USB 摄像头 / MIPI 摄像头 / v4l2

**前置条件**:
- 已确认板型和摄像头类型。
- 已连接摄像头并能访问设备 shell。

**步骤**:

1. **枚举视频设备** `[safe]`
   先确认内核是否暴露 video 节点。
   ```bash
   ls /dev/video*
   ```
   预期:存在 /dev/videoN；没有节点时先看 dmesg 和连接/供电。

2. **USB 摄像头先看总线** `[safe]`
   USB 摄像头需要确认设备枚举和带宽，再谈 ROS/TROS launch 参数。
   ```bash
   lsusb
   ```
   预期:能看到摄像头设备；看不到时排查线缆、供电和 USB 口。

3. **列出格式和帧率** `[safe]`
   launch 参数必须匹配摄像头真实支持的 pixel format、分辨率和 fps。
   ```bash
   v4l2-ctl -d /dev/video0 --list-formats-ext
   ```
   预期:记录 MJPEG/YUYV 等格式及可用分辨率。

4. **MIPI 摄像头查看驱动日志** `[safe]`
   MIPI/CSI 问题通常先从驱动 probe、sensor id、lane 配置和扩展板连接排查。
   ```bash
   dmesg | grep -i mipi
   ```
   预期:能看到相关 probe 或错误日志；没有日志时扩大 grep 到 sensor 型号。

**验证**:
- 低分辨率画面验证:先用 640x480 或文档推荐配置拿到稳定画面，再逐步提高分辨率或接入推理。
- ROS/TROS topic 验证 — `ros2 topic list`:摄像头节点启动后能看到图像 topic；没有 topic 时回到 launch 日志。

**安全注意**:
- 不要在没有确认设备节点和格式前反复修改 launch 参数；同一错误连续两次应回到官方文档和板端日志。

**预期结果**:用户能定位问题属于硬件枚举、驱动、格式参数、ROS 节点还是推理链路。

来源:<https://developer.d-robotics.cc/rdk_doc/Basic_Application/vision/mipi_camera> <https://developer.d-robotics.cc/rdk_doc/Robot_development/quick_demo/demo_sensor>

## 硬件参考主题

以下主题详见 [硬件与系统参考](references/hardware-notes.md):

- 新手"从 0 到 1"标准路径（X5 为主，覆盖 90% 社区咨询）
- 模型部署全流程与高频踩坑（**最核心的用户痛点**）

## 参考资料

- [摄像头命令](references/camera-commands.md)
- [BPU 工具链对照:X 系列 hb_mapper→.bin vs S 系列 hb_compile→.hbm](references/toolchain-workflow.md)（含 OE/天工开物 Docker、hb_compile 命令、config.yaml 模板、hbm_runtime 板端加载、Nash 算子约束）
- [硬件与系统参考(详细章节)](references/hardware-notes.md)
