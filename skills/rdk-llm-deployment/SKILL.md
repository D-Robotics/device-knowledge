---
name: rdk-llm-deployment
description: 当用户要在 RDK 板上跑端侧 LLM/VLM 对话(llama.cpp BPU、GGUF 模型、InternVL/SmolVLM)、语音助手(小智 xiaozhi)、语音识别 ASR(sensevoice)、语音合成 TTS、或端侧聊天机器人时使用。本 skill 讲"在板上把大模型对话/语音跑起来",对话式/生成式 VLM(InternVL/SmolVLM 跑成聊天/问答)归本 skill。机器人动作策略 VLA/Pi0/LeRobot 走 rdk-embodied-lerobot;视觉检测/分类/分割与 CLIP 类感知多模态的现成模型走 rdk-model-zoo;"这块板能不能跑 LLM"的选型与期待走 rdk-ecosystem;ROS2 环境初始化走 rdk-ros。
---

# RDK 端侧 LLM / VLM / 语音部署

> 来源:[D-Robotics/hobot_llamacpp](https://github.com/D-Robotics/hobot_llamacpp)、[hobot_llm](https://github.com/D-Robotics/hobot_llm)、[sensevoice_ros2](https://github.com/D-Robotics/sensevoice_ros2)、[hobot_tts](https://github.com/D-Robotics/hobot_tts)、[xiaozhi-in-rdk](https://github.com/D-Robotics/xiaozhi-in-rdk) 官方仓库 README,逐条保留出处;模型清单/版本以仓库与 HuggingFace 当前状态为准。

## 何时用

用户要在 RDK 板上**跑大模型对话或语音交互**:端侧 LLM 聊天、VLM 看图问答、语音助手、ASR/TTS、聊天机器人。
要跑机器人**动作**策略(VLA/Pi0/LeRobot)→ rdk-embodied-lerobot;要跑视觉检测/分类**现成模型** → rdk-model-zoo;只问"我这板算力够不够跑 LLM" → rdk-ecosystem。

## 当前主路径 — hobot_llamacpp(X5 / S100)

基于 [llama.cpp](https://github.com/ggml-org/llama.cpp) 的 LLM + VLM ROS 示例,是 **X5/S100/S100P 上端侧大模型的当前推荐路径**(官方编译宏只有 `-DPLATFORM_X5`/`-DPLATFORM_S100`,**S600 不走 hobot_llamacpp**——S600 端侧 LLM/VLM 由另一条官方栈承载,见下方「S600 路径 — D-Robotics_LLM_S600 / oellm_runtime」):

- **模型**:GGUF 格式,**BPU 量化版托管在 HuggingFace `D-Robotics` 组织**(`-GGUF-BPU` 后缀)。
  - **X5**:InternVL2.5-1B、InternVL3-1B/2B、SmolVLM2-256M/500M。
  - **S100**:以上 + **InternVL3-8B**(S100 内存更大,能上更大 VLM)。
  - 纯 LLM:HuggingFace 上任意 gguf 模型。
- **能力**:LLM(设 system prompt + 文本输入 → 文本对话)与 VLM(文本 + 图像输入 → 文本);输入可走参数或 ROS string 话题动态控制,输出以 string 话题发布。
- **编译**:C/C++,Ubuntu 22.04 + Linaro GCC 11.4.0;link `llama.cpp` **tag `b4749`**;`colcon build` 加 `-DPLATFORM_X5=ON` 或 `-DPLATFORM_S100=ON`。依赖 `dnn_node`/`cv_bridge`/`hbm_img_msgs`/`ai_msgs`。

详细编译/运行步骤见 [llm-voice-stack](references/llm-voice-stack.md)。

## S600 路径 — D-Robotics_LLM_S600 / oellm_runtime

RDK S600 跑端侧 LLM/VLM **不用 hobot_llamacpp**(平台宏不含 S600),而是用官方「天工开物 OE / OE-LLM」体系下的 **D-Robotics_LLM_S600 大模型工具链 SDK**:

- **运行时**:SDK 内的 **`oellm_runtime`**(核心库 `libxlm.so`,即 D-Robotics OE-LLM/LeapLLM 推理栈);S600 模型产物 `.hbm`(Nash,**march `nash-p`**)。
- **官方支持模型(D-Robotics_LLM_S600 1.0.2)**:LLM = DeepSeek-R1-Distill-Qwen-1.5B、Qwen3-0.6B/1.7B/4B/8B;VLM = Qwen2.5-VL-3B/7B-Instruct、Qwen3-VL-2B/4B/8B-Instruct、InternVL2-2B;VLA = Pi0;ASR = whisper-medium。
- **怎么拿**:
  ```bash
  wget https://d-robotics-aitoolchain.oss-cn-beijing.aliyuncs.com/llm_s600/1.0.2/D-Robotics_LLM_S600_1.0.2_SDK.tar.gz
  wget https://d-robotics-aitoolchain.oss-cn-beijing.aliyuncs.com/llm_s600/1.0.2/D-Robotics_LLM_S600_1.0.2_Doc.zip   # 端侧逐条运行步骤在用户手册
  ```
  已编译模型链接在 SDK 内 `oellm_runtime/model/resolve_model_nash-p.md`(`nash-p` 即 S600)。
- **OpenAI 兼容服务(可选)**:[`oellm_server`](https://github.com/D-Robotics/oellm_server) 在 `oellm_runtime` 上加 HTTP(`/v1/chat/completions` 支持 SSE 流式):`export LD_LIBRARY_PATH=<...>/oellm_runtime/lib:$LD_LIBRARY_PATH` 后 `python3 openai_server.py --model-type <0/1/4/7> --hbm-path <model.hbm> --tokenizer-dir <dir> --host 0.0.0.0 --port 8000`(README 现以 S100 SDK 示例,S600 沿用同套接口,正式联调以 S600 手册为准)。

> S600 的 model_zoo benchmark(TTFT/TPS/内存)只是**性能数据**不是运行时;实际怎么跑以 D-Robotics_LLM_S600 工具链为准。

## 旧路径 — hobot_llm(仅 RDK X3 4GB)

`apt` 装的 X3 端侧 LLM 节点,**仅 X3 4GB RAM 版**:

```bash
sudo apt install -y tros-humble-hobot-llm        # 或 tros-hobot-llm(foxy)
wget http://archive.d-robotics.cc/llm-model/llm_model.tar.gz   # 下模型
sudo tar -xf llm_model.tar.gz -C /opt/tros/${TROS_DISTRO}/lib/hobot_llm/
```

支持终端直接对话或订阅文本话题发布结果。X5/S100 新项目优先用 hobot_llamacpp,不要默认 hobot_llm。

## 语音交互闭环(ASR → LLM → TTS)

三段拼成完整语音助手,模型多为离线本地:

1. **ASR / 命令词 — sensevoice_ros2**:SenseVoice.cpp 离线识别,接麦克风阵列;`apt install tros-humble-sensevoice-ros2`。唤醒/命令词发 `audio_msg::msg::SmartAudioData`,ASR 结果发 `std_msgs::msg::String`。默认**命令词**(`config/cmd_word.json`,注意是 `config` 根目录、不是 `config/hrsc/`)共 5 条:`向前走/向后退/向左转/向右转/停止运动`,**不含「地平线你好」**;唤醒词是另一概念,由 `wakeup_name` 参数(默认「你好」)配置。命令词可自定义(建议中文 3–5 字)。支持 X3/X5/S100/S100P/S600。
2. **LLM** — 把 ASR 文本喂给 hobot_llamacpp / hobot_llm 生成回复。
3. **TTS — hobot_tts**:订阅 `/tts_text`(`std_msgs/msg/String`)→ PCM → ALSA 播放。先 `wget http://archive.d-robotics.cc/tts-model/tts_model.tar.gz` 解压到 `lib/hobot_tts/`;`playback_device` 参数指定播放设备(默认 `hw:0,1`)。

## 一体方案 — xiaozhi-in-rdk(小智语音助手)

D-Robotics 官方适配的**小智 AI 语音助手**,RDK X3/X5/S100 通吃,端到端实时语音:

- 16/24kHz 实时语音、Opus 编解码、空格键交互、双摄(USB/MIPI)切换。
- 双协议:**MQTT 控制 + UDP 音频传输**,AES-128-CTR 加密。
- 集成 YOLOv8 目标检测(经 **MCP 协议**供 AI 调用视觉)。
- 要求:rdkos 3.0.0+、Python 3.10+、ALSA + PulseAudio,建议接 USB 麦克风/音箱(X5 板载音频也可)。

## 选型口径

- **X5**:1–2B VLM(InternVL3-1B/2B、SmolVLM2)流畅,走 hobot_llamacpp。
- **S100/S100P**:内存大,能上 InternVL3-8B 这类更大 VLM。
- **X3**:仅适合 hobot_llm 这类轻量端侧 LLM(4GB 版)。
- 模型两大来源:[huggingface.co/D-Robotics](https://huggingface.co/D-Robotics)(GGUF-BPU 量化版)、`archive.d-robotics.cc`(`llm-model`/`tts-model` tar 包)。完整模型清单与命令见 [llm-voice-stack](references/llm-voice-stack.md)。
