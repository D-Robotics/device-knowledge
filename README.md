# RDK 设备知识 Skills

D-Robotics RDK 及周边设备(Jetson / 树莓派 / Rockchip)的 **source-backed 知识**,按
[Claude 官方 skill 格式](https://github.com/anthropics/skills)组织。本仓库是数据为主、运行时中立的知识来源,
可被任意支持 skill 的 agent 宿主直接扫描 `skills/**` 加载——无需再经过 TS 数据包、适配层或构建产物。

## 为什么是 skill

每个 skill 就是一个 `skills/<name>/SKILL.md`:YAML frontmatter 只需 `name` + `description`,正文是 markdown 指令,
详细查表放 `references/`。这一极简格式:

- **通用**:Claude Code、Moss、RDK Studio 以及任何按目录扫描 skill 的宿主都能直接消费。
- **兼容 Moss**:Moss 的 `mergeSkillFrontmatterDefaults` 会为"仅含 name/description 的外部 skill"自动补齐运行时必填字段,
  因此本仓库的极简 skill 导入 Moss/RDK Studio 时天然可用。
- **可发现**:`description` 描述"何时触发",宿主据此按需加载对应知识,正文保持精简、加载轻。

## Skill 清单

| Skill | 何时触发 |
| --- | --- |
| [`rdk-ecosystem`](skills/rdk-ecosystem/) | RDK 生态、产品选型(买哪块板)、能否跑某模型、与 Jetson/树莓派/RK3588 跨平台对比、LLM/VLM 期待、官方资料来源 |
| [`rdk-hardware`](skills/rdk-hardware/) | RDK 硬件子系统与系统底座:40PIN GPIO、摄像头、BPU 推理流水线、系统路径、网络、散热、BPU 架构演进、OS 版本线、板型感知 |
| [`rdk-board-knowledge`](skills/rdk-board-knowledge/) | 板型基线确认、常见报错诊断、高频误区纠正(附 55 条故障速查、诊断命令库与官方 FAQ) |
| [`rdk-system-config`](skills/rdk-system-config/) | 系统级配置:Wi-Fi/蓝牙/有线网、config.txt 启动配置、CPU/BPU 调频与温控风扇、开机自启、Samba/NFS 文件共享、srpi-config TUI(X 与 S 差异) |
| [`rdk-doc-finder`](skills/rdk-doc-finder/) | "去哪查":把任意问题指到官方文档站(rdk_x_doc/rdk_s_doc/tros_doc/model_zoo_doc/rdk_studio_doc/accessories_doc)的章节 + URL,含 URL 推导规则与全量主题索引 |
| [`rdk-command-manual`](skills/rdk-command-manual/) | 查某条 RDK 专属命令/系统命令的语法/选项/适用板型:hrut_*、srpi-config、rdkos_info、rdk-miniboot-update、devmem 等(命令为锚点) |
| [`rdk-source-map`](skills/rdk-source-map/) | 在 D-Robotics GitHub 组织(327+ 仓)里定位/区分仓库:某仓是干嘛的/哪层/哪块板、任务该去哪个仓、hobot- vs hobot_、从源码构建 OS 镜像/TROS(repo/manifest/rdk-gen/vcstool) |
| [`rdk-device`](skills/rdk-device/) | 模型部署闭环(.pt/.onnx→.bin BPU 工具链)、首次开箱联网、摄像头/视觉推理、从 0 到 1 上手 |
| [`rdk-model-zoo`](skills/rdk-model-zoo/) | 取 Model Zoo 现成 BPU 模型(分类/检测/分割/姿态/OCR/多模态)、选对硬件分支、hbm_runtime 运行、预编译 .bin/.hbm 下载、各板逐型号实测清单 |
| [`rdk-embodied-lerobot`](skills/rdk-embodied-lerobot/) | 具身智能策略部署:LeRobot ACT、VLA(Pi0/openpi)、机械臂动作控制、policy 编译到 BPU(S100/S600) |
| [`rdk-llm-deployment`](skills/rdk-llm-deployment/) | 端侧 LLM/VLM 对话(llama.cpp BPU、GGUF、InternVL/SmolVLM)、语音助手(小智)、ASR(sensevoice)/TTS 闭环 |
| [`rdk-ros`](skills/rdk-ros/) | TROS/ROS2 环境初始化、ros2 命令、节点排障、包定位、双目深度/Livox 感知节点(附九大类 TROS 节点目录) |
| [`rdk-multimedia`](skills/rdk-multimedia/) | 硬件多媒体流水线:H264/H265/JPEG 编解码、VIN/ISP 取流、VPS/PYM 缩放、HDMI 显示,sp_dev / HB_* / MediaCodec 接口(区别于模型推理与 ROS 节点) |
| [`rdk-peripheral-cookbook`](skills/rdk-peripheral-cookbook/) | 外设驱动食谱:GPIO/I2C/SPI/UART、PWM 舵机、电机、LED/WS2812、音频(ALSA)、**CAN(X5 SocketCAN / S100·S600 MCU 域 CANHAL)**、跨平台引脚、libgpiod、S100 拨码/S600 自锁口、零驱动诊断 |
| [`rdk-accessories`](skills/rdk-accessories/) | D-Robotics 官方成品配件:GS130W/GS130Wi 双目相机、RDK IMU 模组(BMI088)、S100/S600 相机/MCU 端口扩展板——选型/接线/安装/官方 SDK 驱动 |
| [`rdk-board-delegate`](skills/rdk-board-delegate/) | 板端委派、OpenClaw 交接信息结构、S100/S600"大小脑异构"协同、S 系列 MCU(R52+)固件开发(remoteproc/IPC/编译烧录) |
| [`jetson-knowledge`](skills/jetson-knowledge/) | NVIDIA Jetson(Orin 系列)生态、选型、JetPack/TensorRT 工具链 |
| [`rpi-knowledge`](skills/rpi-knowledge/) | 树莓派(Pi 5/4B/CM4)生态、GPIO、libcamera、AI HAT+ |
| [`rk-knowledge`](skills/rk-knowledge/) | Rockchip RK3588(Rock5 / OrangePi 5)NPU、RKNN 工具链部署 |
| [`host-software-dev`](skills/host-software-dev/) | RDK Studio 桌面客户端本体开发(Electron/React/Vite/Node/TS、打包、IPC、HMR),区别于板端设备操作 |

## 目录结构

```text
device-knowledge/
├── skills/
│   └── <skill-name>/
│       ├── SKILL.md            # frontmatter(name + description) + 正文指令
│       └── references/*.md     # 详细查表:命令、故障速查、规格、硬件章节
├── scripts/validate-skills.mjs # 校验 frontmatter 与 references 链接
├── docs/architecture.md        # 仓库架构说明
├── LICENSE
└── README.md
```

## 如何使用

- **Claude Code**:把需要的 skill 目录放进 skill 搜索路径(如复制到 `~/.claude/skills/` 或项目的 `.claude/skills/`)。
- **Moss / RDK Studio**:宿主从 `<workspace>/skills/**` 扫描;skill 目录名即 skill id,与 frontmatter `name` 一致。

## 内容与出处

所有内容 **source-backed**,忠实转换自原 device-knowledge 知识库,**未改写技术事实**:

- 每个 `SKILL.md` 正文开头有 `> 来源:` 声明。
- `references/` 中的命令、故障、文档逐条保留官方出处链接(`developer.d-robotics.cc/rdk_doc`、D-Robotics GitHub 等)。
- 优先官方 D-Robotics 文档、工具链、Model Zoo / NodeHub;社区/经验性内容如实标注。

## 校验

```bash
node scripts/validate-skills.mjs
```

校验每个 `SKILL.md` 的 frontmatter 含 `name`(与目录名一致)+ `description`,且正文引用的 `references/` 文件真实存在。

## 推荐搭配的官方 Claude Skill

以下 [anthropics/skills](https://github.com/anthropics/skills) 的官方 skill 对 RDK 开发有互补价值。
为保持本仓库聚焦于设备知识,**不内置**它们,按需在你的 skill 环境中引入即可:

- **`skill-creator`** — 持续创建/维护本仓库的 RDK skill。
- **`frontend-design`、`webapp-testing`** — 开发与验证 RDK Studio 桌面端 UI。
- **`mcp-builder`** — 若要为 RDK 设备知识构建只读 MCP server。

## 新增或修改 skill

1. 在 `skills/<name>/` 下建 `SKILL.md`,frontmatter 写 `name`(= 目录名)与精准的 `description`(描述何时触发,避免与既有 skill 抢触发)。
2. 详细查表/长内容放 `references/*.md`,在正文中链接。
3. 标注来源,保持技术事实可追溯。
4. 运行 `node scripts/validate-skills.mjs` 确认通过。

## License

[MIT](LICENSE)
