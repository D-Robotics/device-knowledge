# RDK 生态与产品选型 · 硬件与系统参考

> 来源:整理自 D-Robotics RDK 官方文档、工具链与社区实践,逐条保留出处链接;由 device-knowledge 知识库忠实转换而来,未改写技术事实。

本文汇集本 skill 涉及的 RDK 硬件/系统章节,逐节整理自官方文档与实践,供需要细节时查阅。

### 14. 板型世代与定位（选型决策树）

| 代次 | 代表板 | 定位 | 采购口径 | 选它的理由 |
|------|--------|------|---------------------|------------|
| 一代 | **RDK X3** / X3 Module | 入门 / 教学 / 替代树莓派 + AI | 入门档，实时价格以官方渠道为准 | 只做轻量检测 / GPIO / ROS2 入门 |
| 二代 | **RDK X5** / X5 Module | 主力 / 机器人视觉 / 端侧 AI | 主力档，实时价格以官方渠道为准 | 性价比高；主推 TROS + DOSOD + 小 LLM |
| 二代+ | RDK Ultra | 高算力工业 | 项目/分销口径，以官方渠道为准 | 上量客户；个人开发者优先 X5/S100 |
| 三代 | **RDK S100 / S100P** | 具身智能 / 人形机器人 / 大模型 | 以官方渠道实时价格为准 | 算控一体；要 LLM/VLM/MCU 实时控制 |
| 三代+ | **RDK S600** | 顶级算力具身 / 双臂 / 多路高速网络 | 以官方渠道实时价格为准 | 560 TOPS(4× Nash)、18× A78AE、6× R52+ MCU、32/64GB、2× 10GbE；系统 Ubuntu 24.04 + TROS Jazzy |

**选型"一句话"决策**：
1. 学生 / 教学 / 预算敏感 → **X3**（但知道轻量模型上限）
2. 机器人 / SLAM / YOLO / 小 LLM / ROS2 主开发 → **X5**（8GB 版优先，实际 SKU/价格以官方渠道为准）
3. 要跑 LLM 对话 / VLM 多模态 / 端侧 7B 级量化模型 / 实时关节控制 → **S100**（12GB）
4. 想跑更大模型/VLM 或多路 GMSL 相机 → **S100P**（24GB，具体模型清单以官方 Model Zoo / hobot_llm 文档为准）
5. 要**顶级算力(560 TOPS)/ 双臂具身 / 多路 10GbE** → **S600**（32 或 64GB，4× Nash core；系统 Ubuntu 24.04 + ROS2 Jazzy，TROS 路径/包名与 Humble 线不同）
6. **不知道买哪个**：默认推 **X5 8GB 套餐**——覆盖 90% 个人开发者需求，报错踩坑最少（社区样本最多）。

**跨代**的硬约束（反复跟用户强调，不要心存侥幸）：
- 模型产物跨代次**不通用**：Bernoulli2(X3)/Bayes(X5/Ultra) 产 `.bin`，Nash(S100/S100P) 产 `.hbm`（工具链绑死架构）
- 40PIN 电气兼容，但 GPIO 编号 / I2C 总线数 / PWM 通道数都不同，驱动代码**须按板型适配**
- TROS 大版本（Foxy / Humble）与 RDK OS 主版本绑定，**不要指望同一个 apt 源能跨板型装完整栈**

### 21. 跨平台对比：树莓派 / Jetson / RK 与 RDK 的横向定位

> 用户问 "RDK 和 X 比哪个好" 时非常高频，**不要**回避 —— 但也**不要**抬高 RDK。每个板都有适合的场景。

| 维度 | **RDK X5** | Jetson Nano / Orin Nano | 树莓派 5 + AI HAT+ | Orange Pi 5 Plus (RK3588) |
|------|-----------------------|-------------------------|---------------------|----------------------------|
| AI 算力 | 10 TOPS (BPU) | Nano(老): 472 GFLOPS / **Orin Nano Super: 67 TOPS**(2024-12 软件升级,原 Orin Nano 40 TOPS) | Hailo-8L: 13 TOPS / Hailo-8: 26 TOPS | 6 TOPS (NPU RK3588) |
| CPU | 8x A55 @1.5GHz | A57×4 / A78AE×6 | BCM2712 A76×4 @2.4GHz | A76×4 + A55×4 |
| 模型后端 | `.bin` (Bayes) | TensorRT / ONNX | Hailo `.hef` / IMX500 `.rpk` | RKNN `.rknn` |
| 工具链成熟度 | 中（Horizon OE 稳定，文档中文齐全）| **高**（TensorRT 生态最成熟，英文文档首选）| 中（Hailo Model Zoo 英文为主）| 中（rknn-toolkit2 开源，但版本跳跃频繁）|
| ROS2 原生支持 | **预装 TROS (Humble)** | 手动装 ROS2 | 手动装 ROS2 | 手动装 ROS2 |
| 中文社区 / 文档 | **强**（D-Robotics论坛 + CSDN 博客多）| 中（NVIDIA 官方中文翻译 + 博客）| 中 | 弱（Orange Pi 文档较少） |
| 典型踩坑 | 默认 YUYV 相机、v2.0 tag 卡版本 | Jetpack 版本绑定、Docker ARM 镜像 | 模型+标签没配套、H8/H10 HEF 不通 | 内核 5.10 锁死、vendor fork、librknnrt 版本 |
| 采购口径 | 以官方渠道实时价格为准 | 以 NVIDIA 官方/渠道实时价格为准 | 以 Raspberry Pi 与 Hailo/IMX500 渠道实时价格为准 | 以厂商/渠道实时价格为准 |
| 选它的理由 | **中文开发者 + ROS2 机器人 + 性价比** | 大 LLM / CUDA 生态迁移 / 全英文工作流 | 想要"完整 Pi 生态 + 加 AI 做课题" | 纯算力堆 + 极客折腾 / 走 Android 生态 |
| 不适合 | 纯 CUDA 代码迁移 / PyTorch 直跑 | 中文学生 + 预算紧 | ROS2 密集项目（生态弱）| 想要开箱即用 |

**回答框架**（Moss 给用户做对比时）：
1. **不要简单说"RDK 更好"**，先问用户**用途 + 预算 + 英文/中文文档偏好**
2. **承认短板**：RDK 在**纯 CUDA 迁移** / **大 LLM 本地跑** / **英文资料深度**上不如 Jetson
3. **突出强项**：RDK 在**中文生态 + TROS 预装 + 接口丰富（40pin + CAN + MIPI）+ 性价比**上很有竞争力
4. **承认类比**：RDK X5 ≈ 中文文档/ROS2 机器人场景下的 **"Jetson 入门替代"** 或 **"Raspberry Pi 5 + AI HAT+ 的一体化版本"**；S100 ≈ 类 Orin NX 的**国产具身智能平台**

### 22. LLM / VLM 在 RDK 上的期待校准（避免过度承诺）

> 2025-2026 "DeepSeek / Ollama 热"之后，大量用户直接问"RDK X5 能跑 DeepSeek 吗"。真实答案需要**校准期待**，不能一句"能跑"忽悠用户。

**分档现实**：

> 数据取自 model_zoo_doc 官方 benchmark(S100 行实测板为 **S100P**;S600 单独一页)。

| 板型 | 能跑什么级别的模型 | 实际体验(官方实测) | 推荐使用方式 |
|------|---------------------|----------|--------------|
| **X3** | ❌ LLM 基本不可用 | 2GB 内存就放不下 | 放弃在板上跑，用云 API 即可 |
| **X5 (4GB)** | ≤1B 量化 | token/s 个位数，只能当"玩具" | 体验 / 教学；**已能跑 1B 级 VLM** |
| **X5 (8GB)** | ≤2B 量化 + **1-2B VLM**（InternVL/SmolVLM 走 hobot_llamacpp） | VLM 解码 ≈51.6ms/token | 离线对话、语音小助手、轻量多模态 |
| **S100 / S100P (12/24GB)** | 1.5-3B 流畅；7B 能跑但慢 | **S100P 实测**:1.5B q4≈39/q8≈27 TPS;7B q8≈**6.7 TPS**(7.4GB);Qwen2.5-Omni-3B≈14 TPS | 1.5-3B 端侧对话 + 多模态;7B 仅"能跑" |
| **S600 (32/64GB,560 TOPS)** | **7-8B 顺滑** | Qwen3-8B w4≈**31 TPS**、4B≈46、1.7B≈75、1.5B≈92(DeepSeek-R1-Distill) | **端侧大模型对话首选** |

**RDK 上跑 LLM 的三条路线**（社区里真有人用过，给用户讲清差别）：

| 路线 | 适合 | 优缺点 |
|------|------|--------|
| **`tros-humble-hobot-llamacpp`** | **X5/S100 当前推荐**，llama.cpp + GGUF-BPU(InternVL/SmolVLM) | ✅ 模型生态大、走 BPU；❌ 要自己配模型 |
| `tros-humble-hobot-llm` | **旧路径，主要面向 X3 4GB** | ✅ 直接 `apt install`；❌ 模型选择受限,X5/S100 别默认用它 |
| **原生 Ollama / llama.cpp**（用户自己装）| 追新模型（DeepSeek R1 等） | ✅ 跑 GGUF 什么都能试；❌ **不走 BPU**，只走 CPU，速度慢很多 |

**遇到"X5 跑 DeepSeek" 类问题的应对**（结合社区博客 "只能当玩具测试着玩，不太能解决大问题"）：
1. 先问**哪个 DeepSeek**（1.5B / 7B / 14B+ 差别巨大）
2. 跑 1.5B 量化在 X5 8GB 上**能跑但慢**，可以演示；7B 在 S100/S100P 上 ≈6.7 TPS 偏慢，**要顺滑 7-8B 建议 S600**(≈31 TPS)
3. 明确告诉用户：**X5 上的 Ollama/llama.cpp 不走 BPU，BPU 算力没用上**，要用 BPU 要走 `hobot_llm` 或 `hobot_llamacpp` 的 ROS2 节点
4. 如果用户只是想要"AI 对话"功能，**推荐走云 API（OpenAI 兼容）** + 板上做感知层；端侧只做**轻量 TTS/STT + 关键词唤醒**更实用

**VLM（视觉语言）现实**：**X5 现已官方支持端侧 VLM**——hobot_llamacpp 提供 InternVL2.5-1B、InternVL3-1B/2B、SmolVLM2-256M/500M 的 BPU 量化版(`.bin` 图像编码器 + GGUF),X5 InternVL2.5-1B 解码 ≈51.6ms/token;S100/S100P 同款且可上 InternVL3-8B(`.hbm` 编码器)。落地命令见 rdk-llm-deployment。（旧说法"X5 跑不动 VLM"已过时。）
