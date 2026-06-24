# RDK Model Zoo 目录与运行时参考

> 来源:[D-Robotics/rdk_model_zoo](https://github.com/D-Robotics/rdk_model_zoo)(`rdk_x5` 分支)README 与目录结构,逐条保留出处;清单随仓库演进,以当前分支实际 `ls samples/` 为准。

## 分支策略(单一事实源)

| 板型 | 分支 | 状态 |
| --- | --- | --- |
| RDK X5 | `rdk_x5` | 主交付,活跃维护(RDK OS ≥ 3.5.0 / Ubuntu 22.04 aarch64 / TROS-Humble) |
| RDK X5(旧) | `rdk_x5_legacy` | 原 `main`,历史归档 |
| RDK X3 | `rdk_x3` | X3 设备 |
| RDK S100/S100P | 两处并存:[rdk_model_zoo_s](https://github.com/D-Robotics/rdk_model_zoo_s) 的 `s100` 分支,或 `rdk_model_zoo` 的 `rdk_s` 分支 | **都含完整可跑 sample**(`.hbm`);rdk_s 分支不只是转换教程,每 sample 同样有 conversion+evaluator+model+runtime。两仓口径有矛盾(主 README 称 _s 为历史归档),以板型分支实际 `ls samples/` 为准 |
| RDK S600 | `rdk_model_zoo` 仓 `feat/add-samples-s600-support`(开发中) | S100/S600 共用;附录目前只给 S600 的 LLM benchmark |

## 目录布局

```text
rdk_model_zoo/
└── samples/
    ├── vision/
    │   ├── 分类: convnext / edgenext / efficientformer(v2) / efficientnet /
    │   │        efficientvit / fasternet / fastvit / googlenet / mobilenetv1~v4 /
    │   │        mobileone / repghost / repvgg / repvit / resnet / resnext / vargconvnet
    │   ├── 检测: fcos / yolov5 / ultralytics_yolo / ultralytics_yolo26 / yoloworld(开放词汇)
    │   ├── 分割/抠图: modnet(抠图) / yoloe(实例分割) / ultralytics_yolo(seg 任务)
    │   ├── 姿态: ultralytics_yolo(pose 任务)
    │   ├── OCR: PaddleOCR / lprnet(车牌)
    │   └── 多模态: clip(图文匹配)
    └── ...(以仓库当前分支为准)
```

`ultralytics_yolo` / `ultralytics_yolo26` 是一个目录覆盖**检测 / 分割 / 姿态 / 分类**多任务,是检测类首选入口。

## 模型格式 × 运行时对照

| 板型 | BPU 架构 | 模型产物 | Python 运行时 | 备注 |
| --- | --- | --- | --- | --- |
| RDK X3 | Bernoulli2 | `.bin` | `pyeasy_dnn` / `hobot_dnn` | 经典栈,轻量模型为主 |
| RDK X5 | Bayes-e | `.bin` | `hbm_runtime`(legacy: `hobot_dnn`/`pyeasy_dnn`) | 主力,另有 C/C++ 接口 |
| RDK S100/S100P | Nash | **`.hbm`** | **`hbm_runtime`** | 与 X3/X5 的 `.bin` 不同,易混 |

C/C++ 与 Python 接口并存,sample 目录内通常同时给出脚本与说明。

## 预编译模型下载

- 下载根:`https://archive.d-robotics.cc/downloads/rdk_model_zoo/<分支>/<模型族>/<文件>`
- 命名含量化标识与输入尺寸/格式,例:`yolo11x_detect_bayese_640x640_nv12.bin`(bayese = Bayes-e 量化,nv12 = 输入排布)。
- 多数 sample 用 `--model-path` 指定 `.bin`/`.hbm` 后即可跑;输入图来自 sample 自带测试图或摄像头。

## 跑通 checklist

1. `cat /sys/class/socinfo/board_id` 确认板型 → 选对分支克隆。
2. 进 `samples/vision/<model>/`,按其 README 下对应板型的预编译模型(或按教程自行转换)。
3. 装该 sample 依赖的 Python 运行时(`hbm_runtime`;`rdk_x5_legacy` 等旧分支栈为 `hobot_dnn`/`pyeasy_dnn`)。
4. 跑脚本,先验证单图推理 + 可视化,再接摄像头/视频流。
5. 慢/帧率低先确认走的是 BPU 模型而非原始 `.pt`/`.onnx`(后者只走 CPU,见 rdk-device)。

## 常见误区

- **克隆错分支**:在 X5 上用了 `rdk_x3`/`rdk_x5_legacy` 的 demo → 模型或接口对不上。先选分支。
- **`.bin` 拷到 S100 跑**:S100 是 Nash 架构、`.hbm` 产物,跨架构不通用,必须取 `rdk_s` 分支或对应工具链重编。
- **以为 BPU 模型零 CPU 参与**:输入输出端的量化/反量化、不支持算子都会落 CPU,属预期。

## 逐板型逐型号清单(深化)

本文件给的是**目录与运行时概览**;若需要**每块板官方实测了哪些具体型号、量化前后精度/帧率、去哪个分支取 sample**,见 [per-board-model-catalog](per-board-model-catalog.md)。其中特别标注了 **S600 的取用路径**(附录目前只给 S600 的 LLM benchmark,视觉/语音 sample 在 `rdk_model_zoo` 的 `feat/add-samples-s600-support` 开发分支)。

## 相关官方资料

- [逐板型逐型号清单(本仓)](per-board-model-catalog.md)
- [Model Zoo (X3/X5/Ultra · Bayes)](https://github.com/D-Robotics/rdk_model_zoo)
- [Model Zoo (S100/S100P · Nash · 现成模型主库)](https://github.com/D-Robotics/rdk_model_zoo_s)
- [Model Zoo Benchmark 附录(model_zoo_doc)](https://github.com/D-Robotics/model_zoo_doc/tree/main/docs/appendix)
- [BPU 工具链概述](https://developer.d-robotics.cc/rdk_doc/Advanced_development/toolchain_development/overview)
- [NodeHub 应用中心](https://developer.d-robotics.cc/en/nodehub)
