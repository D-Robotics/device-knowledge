# RDK 端侧 LLM / VLM / 语音栈参考

> 来源:[D-Robotics/hobot_llamacpp](https://github.com/D-Robotics/hobot_llamacpp)、[hobot_llm](https://github.com/D-Robotics/hobot_llm)、[sensevoice_ros2](https://github.com/D-Robotics/sensevoice_ros2)、[hobot_tts](https://github.com/D-Robotics/hobot_tts)、[xiaozhi-in-rdk](https://github.com/D-Robotics/xiaozhi-in-rdk) README,逐条保留出处;清单/版本以仓库与 HuggingFace 当前状态为准。

## 1. hobot_llamacpp — GGUF LLM/VLM(X5 / S100)

### 支持的 BPU 量化模型(HuggingFace `D-Robotics`,`-GGUF-BPU`)

完整 repo slug(直接可在 `huggingface.co/D-Robotics/<slug>` 打开,简写名搜不到):

| 板型 | VLM 模型(HuggingFace `D-Robotics` 下的完整 repo) |
| --- | --- |
| X5 | `InternVL2_5-1B-GGUF-BPU`、`InternVL3-1B-Instruct-GGUF-BPU`、`InternVL3-2B-Instruct-GGUF-BPU`、`SmolVLM2-256M-Video-Instruct-GGUF-BPU`、`SmolVLM2-500M-Video-Instruct-GGUF-BPU` |
| S100 | 上述全部 + `InternVL3-8B-Instruct-GGUF-BPU` |

纯 LLM:HuggingFace 上的 gguf 模型(`https://huggingface.co/models?search=gguf`)。

### 编译(板上或 PC 交叉编译)

```bash
# 1. 拉 llama.cpp 指定 tag 并构建
git clone https://github.com/ggml-org/llama.cpp -b b4749
cmake -B build && cmake --build build --config Release
# 2. 在工程内 link
cd hobot_llamacpp && ln -s ../llama.cpp llama.cpp
# 3. colcon 编译(按板型选平台宏)
colcon build --merge-install --cmake-args -DPLATFORM_X5=ON   --packages-select hobot_llamacpp   # X5
colcon build --merge-install --cmake-args -DPLATFORM_S100=ON --packages-select hobot_llamacpp   # S100
```

- 环境:C/C++,Ubuntu 22.04,Linaro GCC 11.4.0,OpenCV 3.4.5。
- 依赖 ROS 包:`dnn_node`、`cv_bridge`、`sensor_msgs`、`hbm_img_msgs`、`ai_msgs`(`hbm_img_msgs` 定义在 `hobot_msgs`,共享内存传图时需要)。
- 交互:LLM 设 system prompt + prompt 文本 → 文本对话;VLM 文本 + 图像(本地图或订阅 image 话题)→ 文本。输入可参数配置或运行时经 string 话题动态控制,输出经 string 话题发布。

### 运行(模型准备 + 启动)

每个 VLM 要下**两个文件**:图像编码器 + 语言 GGUF(X5 编码器是 `.bin`,S100 是 `.hbm`)。以 InternVL2.5-1B(X5)为例:

```bash
# 1. 下模型(放到包内 config/ 或自定义目录),来源 huggingface.co/D-Robotics/InternVL2_5-1B-GGUF-BPU
#    图像编码器: rdkx5/vit_model_int16_v2.bin   语言: Qwen2.5-0.5B-Instruct-Q4_0.gguf
#    S100 改用编码器 vit_model_int16.hbm,并加 -p model_file_name:=vit_model_int16.hbm
# 2. 配环境 + 拷 config
source ./install/setup.bash
cp -r install/lib/hobot_llamacpp/config/ .
# 3. 最小启动:本地图 + 文本提问(feed_type=0 本地 VLM;model_type=0 internvl,SmolVLM 用 1)
ros2 run hobot_llamacpp hobot_llamacpp --ros-args \
  -p feed_type:=0 -p image:=config/image2.jpg -p image_type:=0 \
  -p user_prompt:="描述一下这张图片."
```

- 关键参数(默认值取自 README):`feed_type`(0=本地VLM/1=订阅VLM/2=订阅LLM)、`model_type`(0=internvl/1=smolvlm)、`model_file_name`(默认 `vit_model_int16_v2.bin`)、`llm_model_name`(默认 `Qwen2.5-0.5B-Instruct-Q4_0.gguf`)、`user_prompt`/`system_prompt`。
- 验证:`ros2 topic echo /llama_cpp_node`(文本输出),接 TTS 时看 `/tts_text`。详见 hobot_llamacpp README 的 Model Prepare / Running 段。

## 2. hobot_llm — X3 端侧 LLM(legacy)

- **仅 RDK X3 4GB RAM 版**,Ubuntu 20.04/22.04。
- 准备:`pip3 install transformers`;`sudo apt install -y tros-humble-dnn-node`(更新 hobot-dnn)。
- 安装:`sudo apt install -y tros-humble-hobot-llm`(humble)/ `tros-hobot-llm`(foxy)。
- 模型:`wget http://archive.d-robotics.cc/llm-model/llm_model.tar.gz` → 解压到 `/opt/tros/${TROS_DISTRO}/lib/hobot_llm/`。
- 两种用法:终端直接文本对话;或订阅文本话题、发布文本结果。
- X5/S100 新项目优先 hobot_llamacpp,不要默认 hobot_llm。

## 3. sensevoice_ros2 — 离线 ASR / 命令词

- 算法:[SenseVoice.cpp](https://github.com/lovemefan/SenseVoice.cpp),本地离线;模型用 [sense-voice-gguf](https://huggingface.co/lovemefan/sense-voice-gguf)。
- 安装:`sudo apt install -y tros-humble-sensevoice-ros2`。
- 启动:
  ```bash
  source /opt/tros/humble/setup.bash
  ros2 launch sensevoice_ros2 sensevoice_ros2.launch.py \
    audio_asr_model:="sense-voice-small-fp16.gguf" language:="zh" micphone_name:="plughw:0,0"
  ```
- 输入:麦克风阵列原始音频(去噪后 ASR;`micphone_name` 默认 `plughw:0,0`)。支持 RDK X3/X5/S100/S100P/S600。
- 输出话题:唤醒事件/命令词 → **`/audio_smart`**(`audio_msg/msg/SmartAudioData`);ASR 结果 → **`/asr_text`**(`std_msgs/msg/String`,可直接喂给 hobot_llamacpp 的 `/prompt_text`)。
- **命令词配置:`config/cmd_word.json`**(`config` 根目录,**不是** `config/hrsc/`),默认 5 条:`向前走 / 向后退 / 向左转 / 向右转 / 停止运动`——**不含「地平线你好」**;「地平线你好」是唤醒词,由 `wakeup_name` 参数(默认「你好」)单独配置。命令词可自定义,建议中文、易发音、3–5 字。

## 4. hobot_tts — 文本转语音

- 功能:订阅文本 → TTS 软件接口转 PCM → ALSA 播放。
- 前置:确认音频设备,`ls /dev/snd/` 应出现 `pcmC0D1p` 一类播放设备。
- 模型:`wget http://archive.d-robotics.cc/tts-model/tts_model.tar.gz` → 解压到 `/opt/tros/${TROS_DISTRO}/lib/hobot_tts/`。
- 运行:
  ```bash
  source /opt/tros/setup.bash
  export GLOG_minloglevel=1
  ros2 run hobot_tts hobot_tts
  ```
- 参数:`topic_sub`(默认 `/tts_text`,`std_msgs/msg/String`)、`playback_device`(默认 `hw:0,1`;设备非 `pcmC0D1p` 时需指定,如 `pcmC1D1p`)。

## 5. xiaozhi-in-rdk — 小智 AI 语音助手(一体方案)

- 支持 RDK X3 / X5 / S100,端到端实时语音交互(致谢 py-xiaozhi 项目)。
- 技术点:16/24kHz 采样、Opus 编解码、空格键交互、状态显示、USB/MIPI 双摄切换。
- 通信:**MQTT 控制 + UDP 音频**,**AES-128-CTR** 加密。
- 视觉:集成 YOLOv8 目标检测,经 **MCP 协议** 供 AI 调用。
- 要求:OS rdkos 3.0.0+、Python 3.10+、ALSA + PulseAudio;建议 USB 麦克风 + USB 音箱(X5 板载音频接口亦可,需配默认设备)。

## 6. 相关生成/多模态仓与模型源

| 仓库 / 资源 | 用途 |
| --- | --- |
| [hobot_llamacpp](https://github.com/D-Robotics/hobot_llamacpp) | llama.cpp LLM/VLM(X5/S100,当前主路径) |
| [hobot_llm](https://github.com/D-Robotics/hobot_llm) | X3 端侧 LLM(legacy) |
| [sensevoice_ros2](https://github.com/D-Robotics/sensevoice_ros2) | 离线 ASR / 命令词 |
| [hobot_tts](https://github.com/D-Robotics/hobot_tts) | TTS |
| [xiaozhi-in-rdk](https://github.com/D-Robotics/xiaozhi-in-rdk) | 小智一体语音助手 |
| [hobot_clip](https://github.com/D-Robotics/hobot_clip) | 文本-图像特征检索 |
| [hobot_xlm](https://github.com/D-Robotics/hobot_xlm) / [oellm_server](https://github.com/D-Robotics/oellm_server) | LLM(LeapLLM)/ OE-LLM server |
| [PTQ_MiniCPM](https://github.com/D-Robotics/PTQ_MiniCPM) / [PTQ_InternVL2](https://github.com/D-Robotics/PTQ_InternVL2) | LLM/VLM 训练后量化示例 |
| [huggingface.co/D-Robotics](https://huggingface.co/D-Robotics) | GGUF-BPU 量化模型托管 |
| `archive.d-robotics.cc/llm-model` · `/tts-model` | apt 路径的模型 tar 包 |

## 官方文档

- [端侧大模型部署 hobot_llm(RDK X3 系列,Bloom 1.4B)](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/generate/hobot_llm)
- [hobot_llm 文档(rdk_s 文档区镜像,内容同为 X3 系列 hobot_llm,非 S100 专属)](https://developer.d-robotics.cc/rdk_doc/rdk_s/Robot_development/boxs/generate/hobot_llm)
- [TTS/ASR 语音 (hobot_audio)](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/audio/hobot_audio)
- [S100 文本图片特征检索 (hobot_clip)](https://developer.d-robotics.cc/rdk_doc/rdk_s/Robot_development/boxs/function/hobot_clip)
