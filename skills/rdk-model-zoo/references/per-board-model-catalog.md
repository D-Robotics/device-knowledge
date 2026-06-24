# RDK 各板型逐型号模型清单(Model Zoo Benchmark 附录)

> 来源:[D-Robotics/model_zoo_doc](https://github.com/D-Robotics/model_zoo_doc) 仓 `main` 分支 `docs/appendix/<board>/` 下的逐板型 Benchmark 附录,以及对应 sample 仓的分支/目录。线上同款文档:[developer.d-robotics.cc rdk_doc 附录章节](https://developer.d-robotics.cc/rdk_doc)。性能/精度均为官方实测,随仓库与固件演进,以仓库当前分支实际为准;本表只收录附录里**确有条目**的型号,未列出的不代表不能跑,只代表附录暂未给数。

本表回答两类问题:**“这块板官方给了哪些现成模型 + 实测多少”** 和 **“去哪个仓的哪个分支取 sample”**。先按板型选对仓库与分支(下表),再到对应章节查具体型号。

## 板型 → 仓库 / 分支 / 目录 / 产物(单一事实源)

| 板型 | BPU 架构 | sample 仓库 | 分支 | sample 目录 | 模型产物 |
| --- | --- | --- | --- | --- | --- |
| RDK X3 | Bernoulli2 | [rdk_model_zoo](https://github.com/D-Robotics/rdk_model_zoo) | `rdk_x3` | `demos/<task>/`(注意是 `demos/` 不是 `samples/`) | `.bin` |
| RDK X5 | Bayes-e | [rdk_model_zoo](https://github.com/D-Robotics/rdk_model_zoo) | `rdk_x5` | `samples/vision/<model>/` | `.bin` |
| RDK S100 / S100P | Nash | [rdk_model_zoo_s](https://github.com/D-Robotics/rdk_model_zoo_s) | `s100`(默认分支) | `samples/Vision/<Model>/` | `.hbm` |
| RDK S600 | Nash | [rdk_model_zoo](https://github.com/D-Robotics/rdk_model_zoo) | `feat/add-samples-s600-support`(开发中,见下文 S600 说明) | `samples/vision/`、`samples/speech/` | `.hbm` |

附录章节文件分布:X3 有分类/检测/分割/OCR;X5 有分类/检测/分割/姿态/OCR/抠图;S100 有分类/检测/分割/姿态/OCR/深度估计/LLM;S600 **目前只有 LLM**。

---

## RDK S600 —— 重点确认

> 来源:`docs/appendix/rdk_s600/01_llm.md`(LLM 实测);[rdk_model_zoo `feat/add-samples-s600-support` 分支 README](https://github.com/D-Robotics/rdk_model_zoo/tree/feat/add-samples-s600-support)(视觉/语音 sample)。

**结论先行:**
- model_zoo_doc 的 S600 附录**当前只给了 LLM benchmark**,没有视觉模型条目。
- S600 的**视觉 / 语音 sample 在 `rdk_model_zoo` 仓的 `feat/add-samples-s600-support` 分支**,该分支 README 明确写“当前主要支持的平台:RDKS100、RDKS600”。**这是开发中(feat/*)分支,尚未见稳定的 `rdk_s600` 分支**——取用前确认分支是否已合入正式分支。
- S600 与 S100 同为 **Nash 架构 → 产物 `.hbm`**,运行时 `hbm_runtime`(与 rdk-llm-deployment / rdk-device 一致)。

### LLM 实测(测试板 RDK S600,Linux)

指标:BPU core num = prefill/decode 各占核数;qtype = 量化精度(w4/w8);max context = 累计可处理 token 上限;TTFT = 首字延迟(ms);Decode(TPS) = 解码阶段每秒 token;memory = 内存占用(GB)。

| model | BPU core(prefill/decode) | qtype(prefill/decode) | max context | TTFT(ms) | Decode(TPS) | memory(GB) |
| --- | --- | --- | --- | --- | --- | --- |
| DeepSeek-R1-Distill-Qwen-1.5B | 2 / 2 | w4 / w4 | 4096 | 68.9 | 92.4 | 2.2 |
| Qwen3-0.6B | 4 / 4 | w8 / w8 | 4096 | 75.4 | 92.9 | 3.0 |
| Qwen3-1.7B | 4 / 4 | w4 / w4 | 4096 | 91.2 | 75.0 | 3.7 |
| Qwen3-4B | 4 / 4 | w4 / w4 | 4096 | 232.1 | 45.8 | 6.6 |
| Qwen3-4B | 4 / 4 | w8 / w8 | 4096 | 235.3 | 32.3 | 8.3 |
| Qwen3-8B | 4 / 4 | w4 / w4 | 4096 | 283.6 | 31.4 | 9.1 |

> 在 S600 上跑这些对话式 LLM 的部署流程见 **rdk-llm-deployment**;本表只给“附录里有哪些 + 实测多少”。

### 视觉 / 语音 sample(`feat/add-samples-s600-support` 分支,S100+S600 共用)

按 README 与目录,该分支 `samples/` 下含(每个 sample 采用 `conversion/`(转换)+`evaluator/`(评测)+`model/`(下载)+`runtime/cpp|python`+`test_data/` 分层,C/C++ 与 Python 双接口):

- **视觉**:`yolo11`(检测)、`yolo11_pose`(姿态)、`yolo11_seg`(实例分割)、`yoloe11_seg`(开放词汇分割)、`yolov5`(检测)、`mobilenetv2`(分类)、`resnet18`(分类)、`paddle_ocr`(OCR)、`unetmobilenet`(分割)、`lanenet`(车道线)。
- **语音**:`speech/asr`(语音识别)。

该分支附录暂未提供逐型号性能数,具体精度/帧率以 sample README 与后续正式发布为准。

---

## RDK S100 / S100P(Nash · `rdk_model_zoo_s` 仓 `s100` 分支 · 产物 `.hbm`)

> 来源:`docs/appendix/rdk_s100/01~07`。所有 sample 路径形如 `https://github.com/D-Robotics/rdk_model_zoo_s/tree/s100/samples/Vision/<Model>`。S100 与 S100P 是同芯不同档,附录两档并列,**S100P 普遍更快**;下表为节省篇幅多以 S100 为代表,S100P 数据见原附录。性能列:单线程延迟(ms) / 单线程 FPS / 双线程 FPS。

### 图像分类(`samples/Vision/EfficientNet`、`MobileNet`、`ResNet`、`ultralytics_yolo`、`ultralytics_yolo26`)

| Model | 输入 | 类别 | S100 单线程延迟(ms) | S100 单线程FPS | S100 双线程FPS |
| --- | --- | --- | --- | --- | --- |
| EfficientNet_lite0 | 224 | 1000 | 0.448 | 2107.8 | 4827.9 |
| EfficientNet_lite1 | 240 | 1000 | 0.489 | 1949.0 | 4086.5 |
| EfficientNet_lite2/3/4 | 260/300/380 | 1000 | 0.565/0.668/0.915 | - | - |
| MobileNetV1 | 224 | 1000 | - | - | - |
| MobileNetV2 | 224 | 1000 | 0.405 | 2345.4 | 5026.5 |
| ResNet152 | 224 | 1000 | 2.131 | 463.0 | 539.0 |
| YOLO11 n/s/m/l/x CLS | 640 | 80 | 0.53 / 0.68 / 1.02 / 1.21 / 1.97 | 1827.9 / 1416.0 / 955.3 / 805.5 / 501.5 | 3115.7 / 2554.0 / 1445.2 / 1139.5 / 612.3 |
| YOLOv8 n/s/m/l/x CLS | 640 | 80 | 0.49 / 0.62 / 1.00 / 1.98 / 2.77 | 1928.2 / 1562.8 / 970.0 / 497.6 / 357.0 | 3399.9 / 2712.5 / 1500.9 / 614.9 / 412.6 |
| YOLO26 n/s/m/l/x Cls | 224 | 1000 | 0.56 / 0.74 / 1.13 / 1.34 / 2.08 | 1659.7 / 1293.2 / 853.0 / 723.5 / 471.9 | 3112.1 / 2333.0 / 1266.7 / 999.8 / 573.3 |

(S100P 同型号更快,如 YOLO11n CLS 单线程 0.40ms / 2368.8 FPS。)

### 目标检测(`ultralytics_yolo`、`ultralytics_yolo26`、`YOLOv13_iMoonLab`)

覆盖系列:**YOLO11、YOLO12、YOLO26(含 Obb 旋转框,15 类)、YOLOv5u(nu/su/mu/lu/xu)、YOLOv8、YOLOv9(t/s/m/c/e)、YOLOv10(n/s/m/b/l/x)、YOLOv13(n/s/l/x)**,均 640×640、80 类(Obb 除外)。代表性 S100 实测(单线程延迟ms / 单线程FPS / 双线程FPS):

| Model | S100 延迟 | S100 FPS | S100 双线程FPS |
| --- | --- | --- | --- |
| YOLO11n / s / m / l / x Detect | 1.62 / 2.63 / 5.63 / 6.96 / 13.13 | 596.5 / 371.4 / 175.7 / 142.4 / 75.8 | 813.9 / 448.2 / 191.6 / 152.4 / 78.8 |
| YOLO12n / s / m / l / x Detect | 2.65 / 4.48 / 9.27 / 14.66 / 24.72 | 368.5 / 220.1 / 107.1 / 67.9 / 40.3 | 443.3 / 244.7 / 113.1 / 70.3 / 41.3 |
| YOLO26n / s / m / l / x Detect | 1.70 / 2.87 / 6.06 / 7.35 / 13.91 | 499.3 / 314.8 / 157.1 / 130.6 / 70.3 | 779.3 / 409.8 / 177.6 / 144.9 / 74.4 |
| YOLO26 n/s/m/l/x **Obb**(15 类) | 1.64 / 2.80 / 6.16 / 7.46 / 13.81 | 548.8 / 337.5 / 157.6 / 130.7 / 71.3 | 842.2 / 418.3 / 175.0 / 143.3 / 73.7 |
| YOLOv5 nu/su/mu/lu/xu Detect | 1.42 / 2.31 / 4.50 / 8.96 / 15.97 | 674.9 / 420.8 / 218.8 / 110.8 / 62.3 | 959.1 / 519.2 / 244.1 / 117.2 / 64.4 |
| YOLOv8 n/s/m/l/x Detect | 1.53 / 2.63 / 5.18 / 9.97 / 15.77 | 632.1 / 371.2 / 190.6 / 99.7 / 63.2 | 868.9 / 446.5 / 209.8 / 104.7 / 65.2 |
| YOLOv9 t/s/m/c/e Detect | 1.77 / 2.74 / 5.52 / 6.98 / 17.75 | 546.0 / 357.9 / 179.2 / 142.0 / 56.2 | 730.7 / 426.0 / 195.3 / 152.0 / 57.9 |
| YOLOv10 n/s/m/b/l/x Detect | 1.58 / 2.53 / 4.49 / 6.28 / 7.95 / 10.83 | 608.9 / 385.5 / 220.0 / 157.6 / 124.7 / 91.8 | 837.0 / 471.1 / 244.2 / 170.3 / 132.5 / 96.2 |
| YOLOv13 n/s/l/x | 3.8 / 5.8 / 16.6 / 26.9 | 262.0 / 169.5 / 59.8 / 37.1 | 378.3 / 204.9 / 63.9 / 38.6 |

(S100P 同型号更快,如 YOLO11n Detect 单线程 1.16ms / 816.5 FPS。附录中 S100P 的 YOLO26 Detect 一档只给了参数量/FLOPs、延迟为空。)

### 实例分割(`ultralytics_yolo`、`ultralytics_yolo26`、`ultralytics_YOLOE_Seg`)

| Model | 输入 | 类别 | S100 延迟 | S100 FPS |
| --- | --- | --- | --- | --- |
| YOLO11 n/s/m/l/x Seg | 640 | 80 | 2.06 / 3.34 / 7.86 / 9.17 / 17.74 | 463.9 / 291.2 / 125.6 / 108.0 / 56.1 |
| YOLOv8 n/s/m/l/x Seg | 640 | 80 | 1.93 / 3.37 / 6.65 / 12.21 / 19.51 | 495.4 / 288.7 / 148.3 / 81.3 / 51.0 |
| YOLOv9 c / e Seg | 640 | 80 | 9.07 / 20.15 | 109.2 / 49.4 |
| YOLO26 n/s/m/l/x Seg | 640 | 80 | 2.23 / 3.80 / 9.08 / 10.48 / 19.90 | 354.2 / 234.1 / 103.2 / 90.1 / 48.7 |
| YOLOE-11 s/m/l-Seg(开放词汇) | 640 | **4585** | 33.7 / 34.7 / 36.1 | 29.3 / 28.5 / 27.3 |
| YOLOE-v8 s/m/l-Seg(开放词汇) | 640 | **4585** | 33.6 / 36.8 / 52.7 | 29.4 / 26.9 / 18.8 |

### 姿态估计(`ultralytics_yolo`、`ultralytics_yolo26`)

| Model | 输入 | 类别 | S100 延迟 | S100 FPS |
| --- | --- | --- | --- | --- |
| YOLO11 n/s/m/l/x Pose | 640 | 80 | 1.69 / 2.76 / 5.89 / 7.23 / 13.61 | 568.0 / 354.1 / 167.5 / 136.9 / 73.0 |
| YOLOv8 n/s/m/l/x Pose | 640 | 80 | 1.62 / 2.83 / 5.47 / 10.31 / 16.07 | 587.6 / 344.4 / 180.5 / 96.2 / 61.9 |
| YOLO26 n/s/m/l/x Pose | 640 | 1 | 1.81 / 3.07 / 6.42 / 7.75 / 14.45 | 486.4 / 300.6 / 149.7 / 124.8 / 67.9 |

### OCR(`samples/Vision/PaddleOCR`)

| Model | 输入 | S100 平均延迟(ms) | FPS |
| --- | --- | --- | --- |
| PP-OCRv3_det | 640×640 | 1.219 | 798.6 |
| PP-OCRv3_rec | 48×320 | 2.588 | 380.5 |

### 深度估计(`samples/Vision/DepthAnythingV2`)

| Model | 输入 | 线程数 | 平均延迟(ms) | FPS |
| --- | --- | --- | --- | --- |
| DepthAnythingV2 | 518×518 | 1 / 2 / 4 / 8 | 137.4 / 263.7 / 521.9 / 1020.4 | 7.27 / 7.54 / 7.54 / 7.54 |

### S100P LLM 实测(`docs/appendix/rdk_s100/07_llm.md`,Python3.10/Linux)

> 部署流程见 **rdk-llm-deployment**;此处仅列附录给出的型号与实测。dtype=q4/q8,指标 TTFT(ms)/TPS/memory(GB)。

| model | dtype | seqlen | max context | TTFT(ms) | TPS | memory(GB) |
| --- | --- | --- | --- | --- | --- | --- |
| DeepSeek-R1-Distill-Qwen-1.5B | q8 / q4 | 256 | 1024 | 109 / 108 | 27.08 / 39.49 | 1.7 / 1.1 |
| DeepSeek-R1-Distill-Qwen-1.5B | q8 / q4 | 256 | 4096 | 226 / 224 | 23.80 / 32.35 | 1.8 / 1.2 |
| DeepSeek-R1-Distill-Qwen-7B | q8 | 256 | 1024 | 544 | 6.76 | 7.4 |
| InternLM2-1.8B | q8 | 256 | 1024 | 132 | 23.83 | 1.8 |
| Qwen2.5-1.5B | q8 | 256 | 1024 | 130 | 24.04 | 1.8 |
| Qwen2.5-1.5B-Instruct | q8 | 256 | 1024 | 130 | 24.40 | 1.8 |
| Qwen2.5-7B | q8 | 256 | 1024 | 535 | 6.67 | 7.4 |
| Qwen2.5-7B-Instruct | q8 | 256 | 1024 | 534 | 6.75 | 7.4 |
| Qwen2.5-Omni-3B | q8 | 256 | 2048 | 285 | 14.03 | 5.5 |

---

## RDK X5(Bayes-e · `rdk_model_zoo` 仓 `rdk_x5` 分支 · 产物 `.bin`)

> 来源:`docs/appendix/rdk_x5/01~06`。sample 路径形如 `https://github.com/D-Robotics/rdk_model_zoo/tree/rdk_x5/samples/vision/<model>`。X5 附录的亮点是**给了量化前后精度对照**(分类 Float/Quant Top-1;检测/分割/姿态 PyTorch AP vs Python(板端)AP),适合评估量化掉点。

### 图像分类(分类目录:convnext / edgenext / efficientformer(v2) / efficientnet / efficientvit / fasternet / fastvit / googlenet / mobilenetv1~v4 / mobileone / repghost / repvgg / repvit / resnet / resnext / ultralytics_yolo(cls))

代表性条目(输入 / Float Top-1 / Quant Top-1 / 单线程延迟ms / FPS):

| Model | 输入 | Float Top-1 | Quant Top-1 | 延迟(ms) | FPS |
| --- | --- | --- | --- | --- | --- |
| edgenext_xxsmall / xsmall / small / base | 256 | 71.43 / 75.00 / 79.78 / 82.05% | 69.34 / 73.00 / 78.21 / 80.48% | 1.65 / 2.38 / 5.17 / 15.02 | 2191 / 1625 / 782 / 260 |
| efficientformer_l1 / l3 | 224 | 79.45 / 82.31% | 78.04 / 80.86% | 7.83 / 17.39 | 499 / 225 |
| efficientformerv2_s0 / s1 / s2 | 224 | 75.94 / 79.66 / 82.24% | 74.30 / 77.44 / 80.44% | 2.74 / 4.65 / 10.40 | 1470 / 850 / 376 |
| efficientnet_b0 / b4 / l2 | 224/380/475 | 77.55 / 82.27 / 84.77% | 75.08 / 80.55 / 83.05% | 4.67 / 18.52 / 95.71 | 842 / 211 / 42 |
| fasternet_t0 / t1 / t2 / s | 224 | 70.40 / 74.17 / 80.07 / 82.95% | 69.89 / 73.46 / 79.07 / 82.14% | 0.57 / 0.77 / 1.96 / 2.99 | 1839 / 1553 / 898 / 546 |
| fastvit_t8 / t12 / s12 / sa24 | 256 | 76.60 / 79.04 / 79.88 / 82.73% | 72.83 / 76.97 / 78.77 / 81.73% | 2.16 / 3.68 / 4.47 / 11.06 | 1641 / 987 / 818 / 341 |
| mobilenetv4_conv_small / medium | 224 | 77.24 / 80.54% | 75.32 / 79.07% | 1.88 / 4.02 | 2035 / 943 |
| mobileone_s0~s4 | 224 | 70.68~80.65% | 64.96~79.45% | 1.38~6.95 | 1528~406 |
| repghost_0_5 / 0_8 / 1_0 / 1_3 / 1_5 | 224 | 67.54~77.16% | 64.43~75.56% | 1.53~3.49 | 1756~829 |
| repvgg_a0~b2 | 224 | 72.72~79.54% | 69.04~78.22% | 5.08~51.06 | 511~65 |
| repvit_m1_0 / m1_1 / m2_3 | 224 | 78.63 / 79.23 / 83.35% | 74.82 / 76.57 / 81.18% | 1.95 / 2.75 / 8.30 | 1630 / 1199 / 419 |
| resnext50_32x4d | 224 | 78.40% | 76.72% | 15.12 | 214 |
| convnext_tiny | 224 | 80.65% | 79.98% | 19.53 | 202 |
| yolov8 n/s/m/l/x-cls | 224 | 69.0~79.0% | 52.5~73.7% | 0.7~13.1 | 1374.6~76.4 |
| yolo11 n/s/m/l/x-cls | 224 | 70.0~79.5% | 49.5~73.2% | 1.0~10.0 | 949.5~100.2 |
| yolo26n-cls | 224 | - | - | 1.1 | 906.0 |

(另含 mobilenetv1/v2/v3、resnet18、googlenet、efficientvit_m5 等,精度见原附录。)

### 目标检测(`samples/vision/fcos`、`ultralytics_yolo`、`ultralytics_yolo26`)

覆盖:**fcos(efficientnetb0/b2/b3)、YOLOv5(nu/su/mu/lu/xu + v2.0/v7.0 各尺寸)、YOLOv8、YOLOv9(t/s/m/c/e)、YOLOv10(n/s/m/b/l/x)、YOLO11、YOLO12、YOLOv13(n/s/l/x)、YOLO26_detect(n/s/m/l/x)**。给 PyTorch AP vs Python(板端量化后)AP。代表性(单线程延迟ms / 单线程FPS / PyTorch AP / Python AP):

| Model | 延迟 | FPS | PyTorch AP | Python AP |
| --- | --- | --- | --- | --- |
| yolov5 nu/su/mu/lu/xu | 6.3 / 12.3 / 26.5 / 52.7 / 91.1 | 157 / 81 / 38 / 19 / 11 | 0.275 / 0.362 / 0.417 / 0.449 / 0.458 | 0.260 / 0.354 / 0.407 / 0.442 / 0.443 |
| yolov8 n/s/m/l/x | 7.0 / 13.6 / 30.6 / 59.4 / 92.4 | 142 / 74 / 33 / 17 / 11 | 0.306 / 0.384 / 0.433 / 0.454 / 0.465 | 0.292 / 0.372 / 0.423 / 0.440 / 0.448 |
| yolov9 t/s/m/c/e | 6.9 / 13.0 / 32.5 / 40.3 / 119.5 | 144 / 77 / 31 / 25 / 8 | 0.357 / 0.460 / 0.504 / 0.530 / 0.555 | 0.346 / 0.446 / 0.485 / 0.515 / 0.530 |
| yolov10 n/s/m/b/l/x | 8.7 / 14.9 / 29.4 / 40.0 / 49.8 / 68.9 | 114 / 67 / 34 / 25 / 20 / 15 | 0.387~0.541 | 0.357~0.522 |
| yolo11 n/s/m/l/x | 8.2 / 15.7 / 34.5 / 45.0 / 95.6 | 122 / 63 / 29 / 22 / 11 | 0.323 / 0.394 / 0.437 / 0.452 / 0.466 | 0.308 / 0.380 / 0.422 / 0.432 / 0.446 |
| yolo12 n/s/m/l/x | 39.4 / 63.4 / 102.3 / 181.6 / 311.9 | 25 / 16 / 10 / 5.5 / 3.2 | 0.410~0.557 | 0.383~0.532 |
| yolov13 n/s/l/x | 44.6 / 63.6 / 171.6 / 308.4 | 22 / 16 / 5.8 / 3.2 | 0.409~0.551 | 0.385~0.526 |
| yolo26 n/s/m/l/x_detect | 11.6 / 20.9 / 51.1 / 40.1 / 103.3 | 86 / 48 / 25 / 20 / 10 | 0.319~0.484 | 0.284~0.438 |

(fcos_efficientnetb0/b2/b3:512/768/896 输入,298 / 69.5 / 38.2 FPS;yolov5 v2.0/v7.0 各尺寸见原附录。)

### 实例分割(`ultralytics_yolo`、`ultralytics_yolo26`、`yoloe`)

| Model | 输入 | 类别 | 延迟 | FPS | Python Box/Mask |
| --- | --- | --- | --- | --- | --- |
| yolov8 n/s/m/l/x-seg | 640 | 80 | 10.4~115.6 | 96.0~8.6 | 0.284/0.219 ~ 0.439/0.336 |
| yolov9 c / e-seg | 640 | 80 | 55.9 / 135.4 | 17.9 / 7.4 | 0.423/0.321 / 0.332/0.268 |
| yolo11 n/s/m/l/x-seg | 640 | 80 | 11.7~129.1 | 85.6~7.7 | 0.296/0.227 ~ 0.447/0.338 |
| yolo26n-seg | 640 | 80 | 15.5 | 64.3 | -/0.285(mask) |
| YOLOE-11s-Seg-PF(开放词汇) | 640 | **4585** | 142.9 | 7.0 | - |

### 姿态估计(`ultralytics_yolo`、`ultralytics_yolo26`)

| Model | 输入 | 延迟 | FPS | PyTorch AP | Python AP |
| --- | --- | --- | --- | --- | --- |
| yolov8 n/s/m/l/x-pose | 640 | 7.0~93.9 | 143.1~10.7 | 0.476~0.670 | 0.462~0.655 |
| yolo11 n/s/m/l/x-pose | 640 | 8.3~97.8 | 119.8~10.2 | 0.465~0.672 | 0.452~0.654 |
| yolo26n-pose | 640 | 12.5 | 79.6 | - | 0.498 |

### OCR(`samples/vision/PaddleOCR`、`lprnet`)

| Model | 输入 | 参数量 | BPU 吞吐 | 数据集/备注 |
| --- | --- | --- | --- | --- |
| PP-OCRv3_det | 640×640 | 3.8 M | 158.12 FPS | ICDAR2019-ArT |
| PP-OCRv3_rec | 48×320 | 9.6 M | 245.68 FPS | ICDAR2019-ArT |
| LPRNet(车牌) | - | - | 266 FPS | 100 帧测试 |

### 抠图(`samples/vision/modnet`)

| Model | 输入 | 输入格式 | 延迟(ms) | FPS |
| --- | --- | --- | --- | --- |
| MODNet(1 线程 / 2 线程) | 512×512 | Float32 NCHW RGB | 89.88 / 130.49 | 11.12 / 15.27 |

---

## RDK X3(Bernoulli2 · `rdk_model_zoo` 仓 `rdk_x3` 分支 · 产物 `.bin`)

> 来源:`docs/appendix/rdk_x3/01~05`。X3 用 **`demos/<task>/`** 目录(不是 `samples/`),路径形如 `https://github.com/D-Robotics/rdk_model_zoo/tree/rdk_x3/demos/<task>/<Model>`。X3 附录覆盖分类/检测/分割/OCR,**无姿态/抠图/深度/LLM**。

### 图像分类(`demos/classification/`)

| Model | 输入 | Float Top-1 | Quant Top-1 | 单线程延迟(ms) | 多线程延迟(ms) | FPS |
| --- | --- | --- | --- | --- | --- | --- |
| GoogLeNet | 224 | 68.72% | 67.71% | 8.34 | 16.29 | 243.51 |
| MobileNetV2 | 224 | 72.0% | 68.17% | 2.41 | 4.42 | 890.99 |
| MobileNetV4 | 224 | 70.50% | 70.26% | 1.43 | 2.96 | 1309.17 |
| MobileOne | 224 | 72.00% | 71.00% | 4.50 | 8.70 | 455.87 |
| RepGhost | 224 | 72.50% | 72.25% | 2.09 | 4.56 | 855.18 |
| RepVGG | 224 | 74.46% | 62.78% | 11.58 | 22.71 | 174.94 |
| RepViT | 224 | 75.25% | 75.75% | 28.34 | 41.22 | 96.47 |
| ResNet18 | 224 | 71.49% | 70.50% | 8.87 | 17.07 | 232.74 |

### 目标检测(`demos/detect/`)

| Model | 输入 | 参数量 | BPU 吞吐(FPS) | 后处理(ms) |
| --- | --- | --- | --- | --- |
| FCOS | 512×512 | - | 173.9 | 5 |
| YOLOv5s_v2.0 / x_v2.0 | 640 | 7.5 / 89.0 M | 38.2 / 3.9 | 13 |
| YOLOv5n_v7.0 / s_v7.0 / x_v7.0 | 640 | 1.9 / 7.2 / 86.7 M | 37.2 / 20.9 / 3.6 | 13 |
| YOLOv8n | 640 | 3.2 M | 34.1 | 6 |
| YOLOv10n | 640 | - | 18.1 | 5 |

### 实例分割(`demos/detect/YOLOv8`)

| Model | 输入 | 参数量 | BPU 吞吐(FPS) | 后处理(ms) |
| --- | --- | --- | --- | --- |
| YOLOv8n-seg | 640 | 3.4 M | 27.3 | 6 |

### OCR(`demos/detect/PaddleOCR`)

| Model | 输入 | 参数量 | BPU 吞吐 | 数据集 |
| --- | --- | --- | --- | --- |
| PP-OCRv3_det | 640×640 | 3.8 M | 41.96 FPS | ICDAR2019-ArT |
| PP-OCRv3_rec | 48×320 | 9.6 M | 78.92 FPS | ICDAR2019-ArT |

---

## 用法提示

- **先按板型选仓/分支**(顶部表),再到对应章节查型号。型号命名里的 n/s/m/l/x 是大小档(快→准),延迟随之上升。
- **X5 看“Float vs Quant / PyTorch AP vs Python AP”** 判断量化掉点是否可接受;S100/S600 表给延迟+FPS,精度以 sample README 为准。
- **YOLOE / YOLOWorld 类的 4585 类**是开放词汇(open-vocabulary)检测/分割,类别数远大于 COCO 80,延迟也更高。
- **跨架构不通用**:X3/X5 的 `.bin` 与 S100/S600 的 `.hbm` 不能互拷,必须取对应分支的预编译产物或重编。
- 这些是**附录实测快照**,新模型会持续加入;最终以各 sample 仓当前分支 `ls` 与 README 为准。