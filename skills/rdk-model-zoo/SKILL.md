---
name: rdk-model-zoo
description: 当用户想用 RDK Model Zoo 的现成 BPU 模型(分类/检测/分割/姿态/OCR/感知类多模态)、问某模型有没有官方转好的 .bin/.hbm、怎么跑 Model Zoo 示例、用哪个分支、hbm_runtime 怎么调、或从哪下预编译模型时使用。本 skill 讲"取现成模型直接跑";自己从 .pt/.onnx 走工具链量化转换走 rdk-device,把模型跑成 ROS 节点走 rdk-ros,对话式 LLM/VLM(InternVL/SmolVLM 聊天问答)走 rdk-llm-deployment,选型/能不能跑某模型走 rdk-ecosystem。
---

# RDK Model Zoo 现成模型部署

> 来源:[D-Robotics/rdk_model_zoo](https://github.com/D-Robotics/rdk_model_zoo)、[rdk_model_zoo_s](https://github.com/D-Robotics/rdk_model_zoo_s) 官方仓库 README 与目录结构,逐条保留出处;技术事实未改写,具体清单以仓库当前分支为准。

## 何时用

用户想**直接拿官方转好的 BPU 模型跑起来**(而不是自己从头量化),或问"YOLO/分类/分割/OCR/多模态有没有现成 `.bin`/`.hbm`""Model Zoo 示例怎么跑""用哪个分支""下载在哪"时用本 skill。
要自己把私有 `.pt`/`.onnx` 走 `hb_mapper` 量化成 `.bin` → rdk-device;要把模型封装成 TROS/ROS2 节点跑 → rdk-ros;只是想知道"我这块板能不能跑 X" → rdk-ecosystem。

**一句话定位**:Model Zoo 是"出厂即用的 BPU 模型仓 + 全链路转换教程",覆盖 `原始模型(PyTorch/ONNX) → 定点量化 → 板端推理 → 后处理 → 示例验证` 全过程,让你用最小成本跑通 BPU。

## 最高频要点 — 选对分支(分支 = 你的板型)

Model Zoo **按硬件分分支**,克隆错分支是第一坑。先确认板型(`cat /sys/class/socinfo/board_id`)再选分支:

| 板型 | 分支 | 说明 |
| --- | --- | --- |
| RDK X5 | `rdk_x5` | **主交付分支**(推荐)。要求 RDK OS ≥ 3.5.0(Ubuntu 22.04 aarch64 + TROS-Humble) |
| RDK X5 旧 demo | `rdk_x5_legacy` | 原 `main` 改名而来,仅作历史归档,新项目别用 |
| RDK X3 | `rdk_x3` | X3 设备分支 |
| RDK S100 / S100P | 两处并存,**都含完整可跑 sample**:① 独立仓 [rdk_model_zoo_s](https://github.com/D-Robotics/rdk_model_zoo_s) 的 `s100` 分支(`samples/Vision/`+`samples/Speech/`);② `rdk_model_zoo` 的 `rdk_s` 分支(`samples/vision/<m>/` 含 conversion+evaluator+model+runtime,同样下了能跑,型号更全) | 产物 `.hbm`。**口径有矛盾**:rdk_model_zoo 主 README 把 rdk_model_zoo_s 称为"历史归档",但 rdk_model_zoo_s 又是 S100 默认分支且 model_zoo_doc 附录据其出。**两处都看,以板型分支实际 `ls samples/` 为准** |
| RDK S600 | `rdk_model_zoo` 仓 `feat/add-samples-s600-support`(开发中) | S600 视觉/语音 sample 在此开发分支(S100/S600 共用);model_zoo_doc 附录目前只给 S600 的 LLM benchmark。取用前确认是否已合入正式分支 |

```bash
# 例:X5 取主交付分支
git clone -b rdk_x5 https://github.com/D-Robotics/rdk_model_zoo.git
```

## 模型格式与运行时(按板型不通用)

- **X5(Bayes-e)** → 产物 `.bin`,当前 `rdk_x5` 分支 Python 用 `hbm_runtime`(`hbm_runtime.HB_HBMRuntime`),也有 C/C++ 接口;旧 demo(`rdk_x5_legacy`)用 `hobot_dnn`/`pyeasy_dnn`。
- **S100(Nash)** → 产物 **`.hbm`**(不是 `.bin`!),Python 用 **`hbm_runtime`**。S 系列用 `.hbm` 是与 X3/X5 最容易混淆的点。
- **X3(Bernoulli2)** → `.bin`,经典 `pyeasy_dnn`/`hobot_dnn`。
- 即便是以 BPU 为主的模型,**输入/输出端通常仍有 CPU 参与的量化/反量化转换**;无法映射到 BPU 的算子也回落 CPU——这是正常现象,不是 bug。

## 快速跑通(以 X5 检测为例)

注意两个 CWD 不同:模型下到 `model/`,脚本在 `runtime/python/` 下跑,入口固定是 `main.py`(别用 `python3 *.py`,该目录有 5 个 .py 会命中错文件)。

```bash
# 1. 在 model/ 目录下载官方预编译模型
cd samples/vision/ultralytics_yolo/model
wget -nc https://archive.d-robotics.cc/downloads/rdk_model_zoo/rdk_x5/ultralytics_YOLO/yolo11x_detect_bayese_640x640_nv12.bin
# 2. 到 runtime/python/ 用 main.py 推理
cd ../runtime/python
python3 main.py --task detect \
  --model-path ../../model/yolo11x_detect_bayese_640x640_nv12.bin \
  --test-img ../../../../../datasets/coco/assets/bus.jpg \
  --img-save-path ../../test_data/inference_yolo11x.jpg
```

成功标志:生成 `../../test_data/inference_yolo11x.jpg`。`main.py` 不带参数也能跑(默认 yolo11n + bus.jpg);此处显式传 `--model-path` 是因为下载的是 yolo11x。预编译模型下载根:`https://archive.d-robotics.cc/downloads/rdk_model_zoo/<分支>/<模型族>/`。

## 覆盖的模型类别

视觉:图像分类、目标检测、实例/语义分割、姿态估计、OCR(PaddleOCR/LPRNet)、抠图(MODNet);多模态:CLIP 图文匹配。
检测主力是 `ultralytics_yolo` / `ultralytics_yolo26`(检测/分割/姿态/分类多任务),另含 `yolov5`、`yoloworld`(开放词汇检测)、`yoloe`(实例分割)、`vargconvnet`(分类)等。

### 逐板型支持矩阵(各板官方实测了哪些型号)

- **X5(`.bin`/`rdk_x5` 分支)**:分类/检测/分割/姿态/OCR/抠图全覆盖,附录给量化前后精度(Float vs Quant Top-1、PyTorch vs Python AP)。
- **X3(`.bin`/`rdk_x3` 分支,目录是 `demos/`)**:分类/检测/分割/OCR;无姿态/抠图/LLM。
- **S100/S100P(`.hbm`/`rdk_model_zoo_s` 仓 `s100` 分支)**:分类/检测(含 YOLO26 Obb)/分割(含 YOLOE 开放词汇)/姿态/OCR/深度估计 + S100P LLM benchmark。
- **S600(`.hbm`,新旗舰 Nash)**:model_zoo_doc 附录**目前只给 LLM benchmark**(DeepSeek-R1-Distill-Qwen-1.5B、Qwen3-0.6B/1.7B/4B/8B);**视觉/语音 sample 在 `rdk_model_zoo` 仓 `feat/add-samples-s600-support` 开发分支**(README 写明同时支持 RDKS100/RDKS600);S600 上跑对话式 LLM 的部署见 rdk-llm-deployment。

完整目录、各 sample 用法、运行时接口见 [model-zoo-catalog](references/model-zoo-catalog.md);**每块板逐型号的实测清单(精度/帧率/分支路径)见 [per-board-model-catalog](references/per-board-model-catalog.md)**。

## 与工具链的边界

- Model Zoo 既提供**预编译模型**(下了就跑),也提供**全链路转换教程**(教你把原始模型转成 BPU);两条路都在仓里。
- 但**通用的私有模型量化**(`hb_mapper checker`/`makertbin`、校准图、`march` 参数)主流程在 rdk-device;Model Zoo 是"有现成的就别自己造"的捷径,以及"照着 sample 学转换"的范例。
