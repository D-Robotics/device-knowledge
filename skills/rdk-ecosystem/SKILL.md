---
name: rdk-ecosystem
description: 当用户询问 RDK 产品生态、买哪块板(X3/X5/Ultra/S100/S100P/S600)、能否跑某模型、与 Jetson/树莓派/RK3588 的跨平台对比、LLM/VLM 期待、或去哪找官方资料时使用。跨平台对比以 RDK 为锚点(RDK vs X 选哪个)归本 skill;纯单平台规格/工具链分别走 jetson-knowledge / rpi-knowledge / rk-knowledge;硬件子系统事实走 rdk-hardware;板上部署走 rdk-device;端侧 LLM/VLM 实际怎么跑走 rdk-llm-deployment;定位 GitHub 仓库/源码导航走 rdk-source-map,官方文档站具体章节定位/给权威 URL 走 rdk-doc-finder,某条命令语法走 rdk-command-manual(本 skill 的官方资料特指生态/选型层面的入口:产品页/Model Zoo/NodeHub/社区)。
---

# RDK 生态与产品选型

> 来源:整理自 D-Robotics RDK 官方文档、工具链与社区实践,逐条保留出处链接;由 device-knowledge 知识库忠实转换而来,未改写技术事实。

建立 RDK 产品线认知与选型判断,回答"买哪块板 / 能不能跑 X / 和别的平台比怎么样 / 资料在哪查"。

## RDK 产品生态
- **D-Robotics**：RDK 开发者套件的制造商
- **RDK Studio**：AI Native 开发工作台
- **RDK 文档**：developer.d-robotics.cc/rdk_doc
- **D-Robotics 开发者社区**：developer.d-robotics.cc/forum
- **NodeHub**：developer.d-robotics.cc/en/nodehub — RDK 应用中心

**用户问"买哪块板 / 能不能跑 X"的决策口径**：
- **一句话推荐**：新手/教学 → X3；机器人视觉主力 → **X5 8GB**（也能跑 1-2B VLM）；具身/实时关节控制 + 1.5-3B LLM/VLM → S100/S100P；多路 GMSL → S100P；**要顺滑跑 7-8B 大模型 / 顶级算力(560 TOPS) / 双臂具身 / 多路 10GbE → S600（S100P 7B 实测仅 ≈6.7 TPS,偏慢）**（价格和模型清单以官方渠道为准）。
- **能不能跑 X 的判据**：
  1) **LLM 对话**：X3 ❌；X5 ⚠️ ≤2B 量化（走 hobot_llamacpp）；S100/S100P ✅ 1.5-3B 流畅、7B 能跑但慢（**S100P 实测 7B q8 ≈ 6.7 TPS**）；**S600 ✅ 才真正顺滑跑 7-8B（Qwen3-8B w4 ≈ 31 TPS）**
  2) **YOLO v5/v8**：X3 仅 v5s；X5 主力（实时）；S100/S100P 高帧率 + YOLO-World
  3) **DOSOD 开放词汇**：X5 ~12 fps；S100 ~45 fps
  4) **多路相机 / GMSL 车规**：仅 S100/S100P（配扩展板）
  5) **实时关节 / 电机 kHz 回路**：**S 系列(S100 4×R52+ / S600 6×R52+)的 MCU 域**能硬实时；X 系列只能 Linux RT 线程，有抖动
- **用户未说板型 / 未连设备**时：先追问一句"你手上是哪块板（X3/X5/S100/P）"，不要盲选 X5 模板回复；已连设备以 `boardPlatform` 字段为准。
- **价格口径**：价格信息仅作参考区间；具体报价**以淘宝/京东实时页面为准**，不要把参考价当准确值写给用户。

**用户做跨平台对比（RDK vs Jetson / 树莓派 / RK3588 / OrangePi）时的回答纪律**：
- **不要**简单说"RDK 更好"——先反问用户**用途（ROS2 机器人？LLM？纯视觉？）+ 预算 + 英文/中文文档偏好**。
- **承认短板**：RDK 在"纯 CUDA 代码迁移"、"大 LLM 本地跑（7B 以上）"、"英文深度资料"上不如 Jetson；在"Linux 桌面生态 / 外设 HAT 数量"上不如树莓派。
- **RDK 的客观侧重**(按事实陈述,是否算优势取决于用户用途)：预装 TROS(ROS2)、板载 CAN/MIPI、40pin 接口、面向机器人的 BPU 工具链与中文资料。
- **典型定位口径**（每个都要一句话）：
  · RDK X5 与 Jetson Nano/Orin Nano 同属入门到中端区间：X5 10 TOPS 是 INT8 BPU 算力、Jetson Nano 472 GFLOPS 是 FP16 通用算力，**量纲不同不能直接换算谁更强**；X5 面向量化检测模型、Jetson 面向 CUDA 通用计算，按用途和生态选，不只比单一数字。
  · RDK S100 ≈ "类 Orin NX 的国产具身智能平台"（不是 Jetson Orin 国产替代，架构差异大）
  · RDK vs 树莓派 5 + AI HAT+：价格随渠道变化；RDK 预装 TROS(ROS2)，树莓派需自行安装 ROS2、但 Linux 桌面与 HAT 生态更广；按"要不要开箱即用 ROS2 / 要不要 Pi 生态"选。
  · RDK vs RK3588（OrangePi 5 Plus）：两者都是国产 NPU 平台；RDK 侧重机器人/TROS 工具链与官方应用，RK3588 是 A76×4 CPU 的通用 SBC、AI 走 RKNN；按"机器人开箱生态 vs 通用算力"选。
- **共性踩坑（跨平台都有）**：`.pt` 不能直跑 NPU、导出 ONNX 要用 vendor fork、校准数据集决定精度——这些 Jetson/RK/RDK 都一样，可以类比讲给用户听。
- **不确定 / 争议**（如精确 FPS 基准）：直说"看具体模型和版本，官方对比页的数字要配合自己测试"；不要把某一篇博客的数字当权威。

**LLM/VLM 在 RDK 上的期待校准**（用户问"能不能跑 DeepSeek / Qwen / Llama"时反复发生）：
- **分档现实**（用 model_zoo_doc 官方实测,不要含糊）：X3 ❌；X5 4GB ≤1B 玩具级；X5 8GB ≤2B 可用（且**能跑 VLM**,见下）；**S100/S100P：1.5B 流畅(S100P q4≈39 / q8≈27 TPS)、7B 能跑但慢(q8≈6.7 TPS,7.4GB)**；**S600（32/64GB,560 TOPS）才是 7-8B 顺滑档(Qwen3-8B w4≈31 TPS、4B≈46、1.5B≈92)**——要端侧大模型对话首选 S600。
- **关键告警**：用户装 **Ollama / llama.cpp** 原生跑 GGUF 时，**模型走 CPU，BPU 完全没用上**，X5 跑 7B 会比桌面 CPU 还慢。想用 BPU：**X5/S100 优先 `tros-humble-hobot-llamacpp`**（llama.cpp + GGUF-BPU 当前主路径），`hobot_llm` 是旧路径(主要面向 X3 4GB);落地命令走 rdk-llm-deployment。
- **"能跑" ≠ "好用"**：CSDN 社区博客原话"只能当玩具测试着玩，不太能解决大问题"—— 如实转述这种现实反馈，别给用户画饼。
- **实用建议**：想做"AI 对话机器人"又买的是 X5 → 推荐 **云 API（OpenAI / 通义 / DeepSeek API）+ 板上做 TTS/STT/唤醒词** 的混合架构，比端侧硬塞 7B 体验好 10 倍。
- **VLM**：**X5 现已官方支持端侧 VLM**（hobot_llamacpp 跑 InternVL2.5-1B、InternVL3-1B/2B、SmolVLM2-256M/500M 的 BPU 量化版,X5 InternVL2.5-1B 解码 ≈51.6ms/token）；S100/S100P 同款 + `.hbm` 编码器、可上 InternVL3-8B；落地走 rdk-llm-deployment。

**RDK 资料三层来源（优先级递减）**：
1. **板上实际**：`apt show tros-humble-<pkg>` / `dpkg -l | grep <pkg>` / `find /opt/tros -name "*launch.py"`（通配 `_launch.py` 与 `.launch.py`）/ `ros2 pkg prefix <pkg>`，永远是真相
2. **官方文档**：developer.d-robotics.cc/rdk_doc（用 `rdk_doc_search_local` 优先命中本地缓存，再 `web_fetch` 核对最新）
3. **GitHub 源码**：github.com/D-Robotics/<repo>（用 `rdk-source-map` 技能定位仓库——D-Robotics 327+ 仓库地图，再拉 raw 文件）
三方一致再回；不一致**以板上实际为准**，文档/GitHub 差异作为「可能版本不同」提示用户。
社区/踩坑案例去 developer.d-robotics.cc/forum 或 forum.d-robotics.cc（`forum_drobotics_search`）。

**社区发帖默认带图 + 必先列分类**：`forum_drobotics_create_post` 现在原生支持 `attachmentIds`——把会话里的截图/设备拍照/报错图/日志直接写进数组，工具会自动 `POST /uploads.json` 拿 short_url 并把 `![…](upload://…)` 内联到正文。
- **新主题强制流程**：`auth_status` → `attachment_list`（如有图）→ **`forum_drobotics_list_categories`**（拿真实 category id）→ `forum_drobotics_create_post {title, raw, category, attachmentIds}`
- **禁止猜分类 id**：不知道的不要试 1/2/5/6，调 `list_categories`
- **禁止用户说"发新帖"时偷偷改成"回复别人的帖子"**绕过分类问题——失败要如实告诉用户
- 报错/求助类帖：必带「错误截图 + 关键日志」
- 分享/项目类帖：必带「主图 + 1–3 张关键场景图」
- 含 IP/序列号/密码的截图必须先打码或裁剪后再上传

## 硬件参考主题

以下主题详见 [硬件与系统参考](references/hardware-notes.md):

- 板型世代与定位（选型决策树）
- 跨平台对比：树莓派 / Jetson / RK 与 RDK 的横向定位
- LLM / VLM 在 RDK 上的期待校准（避免过度承诺）

## 参考资料

- [RDK 官方资料导航](references/official-docs.md)
- [硬件与系统参考(详细章节)](references/hardware-notes.md)
