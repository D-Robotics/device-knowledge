# 板端推理编程 API 对照(X3/X5/Ultra vs S100/S100P/S600)

> 来源:D-Robotics 官方文档 —— rdk_x_doc `docs/03_Basic_Application/02_cdev_demo_sample/{00_overview,bpu}.md`、`docs/03_Basic_Application/03_pydev_demo_sample/RDK_X5/{00_overview,01_classification_sample,02_detection_sample}.md`、`docs/03_Basic_Application/03_pydev_demo_sample/RDK_X3/{01_basic_sample,07_yolov5_sample}.md`;rdk_s_doc `docs/04_Algorithm_Application/{02_Python_API.md,03_Python_Sample/01_Summary.md,03_Python_Sample/02_ResNet18.md,04_C++_Sample/01_Summary.md,04_C++_Sample/02_ResNet18.md}`。只记录文档确有的事实;C++ libdnn 裸接口细节在 OE 文档,见末尾「未覆盖/存疑」。

本页解决的是 [toolchain-workflow.md](toolchain-workflow.md) 不覆盖的那一半:工具链只讲**主机侧**把模型转成 `.bin`/`.hbm`,本页讲**板上怎么写代码加载模型、喂输入、跑推理、取输出**。

## 一句话选型

| 板型 | Python 推理库 | 模型格式 | C/C++ 推理底座 |
|---|---|---|---|
| X3(全部镜像) | `hobot_dnn.pyeasy_dnn` | `.bin` | `/app/cdev_demo/bpu`,**spcdev(`libspcdev.so`)** 封装(`libsp`/sp_dev 是多媒体取流编解码 demo 用的,见 §5) |
| X5 / Ultra(旧镜像) | `hobot_dnn.pyeasy_dnn` | `.bin` | 同上 |
| **X5 软件 3.5.0+** | **`hbm_runtime.HB_HBMRuntime`** | **仍是 `.bin`** | 同上 |
| S100 / S100P / S600 | `hbm_runtime.HB_HBMRuntime` | `.hbm` | `/app/cdev_demo/bpu`,libdnn(`hbDNN*`)+libhbucp |

> ⚠️ **重要变化**:X5 软件 **3.5.0** 起,官方 pydev 示例已从 `pyeasy_dnn` 迁移到 `hbm_runtime`(模型仍是 `.bin`,不是 `.hbm`)。所以「X5 用 pyeasy_dnn」只在**旧 X5/Ultra 镜像**成立;面对 3.5.0+ 的 X5,以板上 `ls /app/pydev_demo/`(任务命名目录,如 `01_classification_sample/`、`02_detection_sample/`)和示例里实际 import 为准。来源:rdk_x_doc X5 `00_overview.md`(标注「软件版本 3.5.0」)、`01_classification_sample.md`、`02_detection_sample.md`。

板端预装代码位置:
- X 系:Python=`/app/pydev_demo/`,C=`/app/cdev_demo/`
- S 系:Python=`/app/pydev_demo/`,C++=`/app/cdev_demo/bpu/`
- 基础模型:`/opt/hobot/model/{x5|s100|s600}/basic/*.{bin|hbm}`

---

## 1. Python · X3 / 旧 X5 — `hobot_dnn.pyeasy_dnn`

最经典的板端推理 API。来源:X3 `01_basic_sample.md`、`07_yolov5_sample.md`。

**关键调用流程**:
```python
from hobot_dnn import pyeasy_dnn as dnn
import numpy as np

# 1. 加载模型(.bin),返回 model 列表
models = dnn.load('../models/yolov5s_672x672_nv12.bin')

# 2. 查输入/输出张量属性
#    models[0].inputs[i].properties / outputs[i].properties
#    含 tensor_type(如 NV12)、dtype、layout(NCHW)、shape(如 (1,3,224,224))、name
#    例:inputs[0] tensor type=NV12, shape=(1,3,224,224), name='data'
#        outputs[0] tensor type=float32, shape=(1,1000,1,1), name='prob'

# 3. 前处理:图像 → 模型输入尺寸 → NV12 格式
#    (BGR resize 到目标尺寸,再转 NV12)

# 4. 推理:对第 0 个模型做前向
outputs = models[0].forward(nv12_data)

# 5. 后处理:从 outputs[i].buffer 取张量,分类/检测各自解析
#    分类示例用 libpostprocess 库解析;检测示例配合后处理库做解码+NMS
```

要点:
- 输入是 **NV12**(分类示例输入张量类型即为 NV12),需把 BGR 图 resize 后转 NV12 再喂入。
- 模型可能含多个 model(`dnn.load` 返回列表),单模型取 `models[0]`。
- 后处理:X 系 Python 示例依赖 `libpostprocess` 库解析输出张量(分类直接取概率,检测做解码+NMS)。
- 报 `No module named 'hobot_dnn'` → RDK 专用推理库未装,检查板端 Python 环境。

---

## 2. Python · X5(3.5.0+)/ S100 / S100P / S600 — `hbm_runtime.HB_HBMRuntime`

`hbm_runtime` 是基于 pybind11 的 Python 绑定,底层封装 **libhbucp / libdnn** C++ 库。来源:rdk_s_doc `02_Python_API.md`、X5 `01/02_*_sample.md`、S Python sample `01_Summary/02_ResNet18`。

> X5 3.5.0+ 用同一个类名加载 `.bin`;S 系加载 `.hbm`。API 形态一致。

**最小推理流程(单模型单输入)**:
```python
import numpy as np
from hbm_runtime import HB_HBMRuntime

# 1. 加载(单模型传 str;多模型传 List[str],也可一个 .hbm 内含多模型)
model = HB_HBMRuntime("/opt/hobot/model/s600/basic/resnet18_224x224_nv12.hbm")

# 2. 查元信息(全部是只读 Dict,外层 key = 模型名)
model_name = model.model_names[0]
input_name = model.input_names[model_name][0]
input_shape = model.input_shapes[model_name][input_name]

# 3. 构造输入(dtype 用 model.input_dtypes 决定;此处示意)
input_tensor = np.ones(input_shape, dtype=np.float32)

# 4. 推理
outputs = model.run(input_tensor)

# 5. 取结果:返回恒为嵌套结构 {model_name: {output_name: np.ndarray}}(单模型也一样)
output_array = outputs[model_name]
```

**run() 三种输入形态**(签名见 `02_Python_API.md`):

| 形态 | 输入类型 | 说明 |
|---|---|---|
| 单模型单输入 | `np.ndarray` | 仅 1 个输入张量;模型唯一时 `model_name` 可省 |
| 单模型多输入 | `Dict[str, np.ndarray]` | key = **输入张量名**(须真实存在);如 NV12 双平面 `{'data_y':…, 'data_uv':…}` |
| 多模型多输入 | `Dict[str, Dict[str, np.ndarray]]` | 外层 key = **模型名**,内层 = 输入名→张量 |

- 返回统一为 `Dict[str, Dict[str, np.ndarray]]`(外层模型名 / 内层输出名)。
- 输入自动检查并转 **C-contiguous**(非连续会多一次拷贝);dtype 或 shape 不匹配抛 `ValueError`;支持模型维度 `-1` 动态补全。

**元信息属性速查**(只读,外层 key=模型名):

| 属性 | 含义 |
|---|---|
| `model_names` / `model_count` | 模型名列表 / 数量 |
| `input_names` / `output_names` | 各模型输入/输出张量名列表 |
| `input_shapes` / `output_shapes` | 张量形状 `Dict[模型名][张量名]=List[int]` |
| `input_dtypes` / `output_dtypes` | 数据类型(`hbDNNDataType` 枚举:U8/S8/F16/F32/S16/U16/S32/… ) |
| `input_quants` / `output_quants` | 量化参数 `QuantParams`(`scale`/`zero_point`/`quant_type`/`axis`),用于前/后处理反量化 |
| `input_strides` / `output_strides` | stride(含义见 OE libdnn 文档) |
| `input_counts` / `output_counts` | 张量个数 |
| `compile_bpu_core_num` | 编译期指定的 BPU core 数(可与运行时核绑定做一致性校验) |
| `sched_params` | 当前调度参数(`SchedParam`: priority/customId/bpu_cores/deviceId) |

**调度参数(优先级 / BPU 核绑定)**:
```python
# 模型级默认值(持久化在 runtime 实例)
model.set_scheduling_params(
    priority={model_name: 5},      # 0~255,越大越高
    bpu_cores={model_name: [0]},   # 核索引列表;[-1] 表示由调度器自动分配
)
# 单次覆盖:run() 传同名参数,仅本次生效,不改默认值
outputs = model.run(input_tensor, priority={model_name: 50})
```
- 优先级关系:`run() 参数 > set_scheduling_params() 默认 > 内置默认`。
- `custom_id`(如 frame id/时间戳,越小越优先,优先级 priority > customId)、`device_id`(多设备)同样可设。
- **核数约束**:`bpu_cores` —— S100 只能取 1 个,S600 取 0~3;`[-1]`=ANY 自动选。

**多线程吞吐**:推理阶段在 C++ 侧释放 GIL,Python 多线程可并发 `run()`;多模型 `run()` 底层为每个模型起一个 C++ 线程并行执行。每次调用可带独立调度参数互不影响。

**前/后处理(X5 检测示例与 S 系一致的范式)**:
1. 前处理:BGR → resize 到模型输入尺寸 → `bgr_to_nv12_planes` 出 y/uv 平面(NV12)。例:S 系 yolov5x hbm 输入是两张量 `data_y [1,672,672,1]` + `data_uv [1,336,336,2]`(U8)。
2. 推理:`model.run(...)`。
3. 后处理(检测):`dequantize_outputs`(按 `output_quants` 的 scale/zero_point 反量化)→ `decode_outputs`(用 strides/anchors/类别数解码)→ `filter_predictions`(置信度过滤)→ `NMS` → `scale_coords_back`(还原到原图尺寸)→ `draw_boxes`。来源:X5 `02_detection_sample.md` 的 API 流程。
4. S 系示例统一调 `utils/` 工具:`preprocess_utils` / `postprocess_utils` / `draw_utils` / `common_utils`。

常用命令行参数(分类/检测示例通用):`--model-path`、`--test-img`、`--label-file`、`--priority`(0~255)、`--bpu-cores`(如 `0 1`);检测另有 `--nms-thres`(默认 0.45)、`--score-thres`(默认 0.25)、`--img-save-path`。

> ⚠️ S 系示例运行需 `numpy`/`opencv-python`/`scipy`;S600 上 `pip install` 可能要 `--break-system-packages`。取相机流用 Hobot VIO(`hobot_vio`,如 `libsrcampy`)——详见 rdk-multimedia。

---

## 3. C / C++ 板端推理

### 3.1 X3 / X5 — libsp / spcdev 封装(`/app/cdev_demo/bpu`)

来源:X cdev `00_overview.md`、`bpu.md`。这是一个 **C 语言** 示例,**不是裸 libdnn**,而是基于 **spcdev 接口(`libspcdev.so`)**:解析命令行参数 → 通过 spcdev API 拿显示器分辨率 → 初始化模型模块、显示模块、视频输入模块 → 按需用 VPS 缩放 → 前/后处理线程把推理结果转坐标 → 显示。

```bash
cd /app/cdev_demo/bpu/src && make        # 产物在 src/bin/sample
cd /app/cdev_demo/bpu/src/bin
# 摄像头 + yolov5
./sample -f /app/model/basic/yolov5s_672x672_nv12.bin -m 0
# h264 回灌 + fcos
./sample -f /app/model/basic/fcos_512x512_nv12.bin -m 1 -i 1080p_.h264 -w 1920 -h 1080
```
参数:`-f` 模型路径、`-m` 模型选择(0=yolov5 / 1=fcos)、`-i` 输入视频(无摄像头时)、`-w/-h` 输出宽高、`-d` debug。`include/` 放模型头文件,`src/` 是入口与各模型前处理/推理/后处理实现。日志会打印 model info(input/output 的 tensorLayout/tensorType/validShape/alignedShape)。

> 运行带显示的示例前先 `systemctl stop lightdm` 关图形界面。

### 3.2 S100 / S100P / S600 — libdnn(`hbDNN*`)+ libhbucp(`/app/cdev_demo/bpu`)

来源:S `04_C++_Sample/01_Summary.md`、`02_ResNet18.md`。C++ 示例底层即 **libdnn / libhbucp**(与 `hbm_runtime` Python 同一套 C++ 库),官方把推理封装进 **per-model 类**(如 `inc/resnet18.hpp` + `src/resnet18.cc`,`main.cc` 调用),推理通过类的 **`.infer()`** 方法完成。

```bash
cd classification_sample/resnet18   # S100 为 01_classification_sample/01_resnet18
mkdir build && cd build && cmake .. && make -j$(nproc)
./resnet_18 \
  --model_path /opt/hobot/model/s600/basic/resnet18_224x224_nv12.hbm \
  --test_img   /app/res/assets/zebra_cls.jpg \
  --label_file /app/res/labels/imagenet1000_clsidx_to_labels.txt \
  --top_k 5
```
- 工具链验证环境:CMake 3.22.1 / GCC·G++ 11.4.0;S100=Ubuntu 22.04,S600=Ubuntu 24.04。
- 功能四段:加载(解析输入输出 name/shape)→ 前处理(BGR resize 到 224x224 转 NV12,Y/UV 分离)→ `.infer()` 前向 → 后处理(取输出 tensor,解析 Top-K)。
- 通用依赖 `libgflags-dev`;ASR 另需 `libsndfile1-dev`/`libsamplerate0-dev`;S100 OCR 需 `libpolyclipping-dev`。
- 公共工具 `utils/inc`:`common_utils.hpp`(反量化/绘制)、`preprocess_utils.hpp`、`postprocess_utils.hpp`(NMS/解码/mask)、`multimedia_utils.hpp`(视频帧解码/像素格式转换)。

> **裸 libdnn(`hbDNN*`) C++ 接口**(`hbDNNTensorProperties`、tensor 申请/拷贝/`hbDNNInfer` 等)的逐函数说明不在 rdk_s_doc 文档树内,在 OE/天工开物文档(`j6.doc.oe.hobot.cc .../ucp/runtime/bpu_sdk_api/`)。本仓如需补,应另起一页从 OE 文档取证,勿凭记忆编造签名。

---

## 4. 各 sample 矩阵

### X5 pydev(软件 3.5.0+,`hbm_runtime`,`.bin`)
| 目录 | 任务 | 模型 |
|---|---|---|
| `01_classification_sample/` | 图像分类 | ResNet18 / MobileNetV2 |
| `02_detection_sample/` | 目标检测 | YOLOv5x / YOLO11 / YOLOv8 / YOLO10 |
| `03_instance_segment_sample/` | 实例分割 | — |
| `04_pose_sample/` | 姿态估计 | — |
| `05_open_instance_segment_sample/` | 开放词表实例分割 | — |
| `06_segment_sample/` | 语义分割 | — |
| `07_usb_camera_sample/` `08_mipi_camera_sample/` `09_web_display_camera_sample/` | 摄像头 + 推理 + (Web)显示 | 取流/显示部分详见 rdk-multimedia |

### X3 pydev(`pyeasy_dnn`,`.bin`)
编号清单(以板上 `ls` 为准):`01_basic_sample`(分类:ResNet18/GoogleNet/MobileNetV1/…)、`04_segment`、`06/07/09 yolov3/v5/v5x`、`11_centernet`、`12_yolov5s_v6_v7`、`02_usb_camera`、`03_mipi_camera`、`05_web_display_camera`、`08_decode_rtsp_stream`。

### S 系 Python / C++ sample(`hbm_runtime` / libdnn,`.hbm`)
S100 目录带编号(`01_classification_sample` … `11_web_display_camera_sample`),S600 目录不带编号(`classification_sample` … `rtsp_yolov5x_display_sample`)。覆盖:分类、检测、实例分割、姿态、(S100 额外)开放词表分割/车道线/OCR、语音(ASR)、USB/MIPI 摄像头、Web 显示、解码/RTSP 显示。

---

## 5. 与 rdk-multimedia 的边界(不重复搬运)

X cdev 的多媒体取流/编解码 C demo —— `vio_capture`、`vio2encoder`、`vio2display`、`decode2display`、`rtsp2display` —— 是 **libsp/sp_dev** 的 camera→编码/解码→显示 pipeline(如 `./vio2encoder -w 1920 -h 1080 -o stream.h264` 生成 h264),与 **rdk-multimedia** 的 sp_dev 覆盖重叠。

本页只在「推理需要喂入相机/视频帧」时提醒:**取流、编解码、显示的 sp_dev/libsrcampy API 详见 rdk-multimedia**;板端推理本身(加载模型 / `forward`·`run`·`infer` / 输入输出张量 / 后处理)看本页。

---

## 6. 未覆盖 / 存疑

- **X5 版本分水岭**:pyeasy_dnn vs hbm_runtime 取决于 X5 软件版本(3.5.0 为已知迁移点)。Ultra 的 pydev 用哪条链路、旧 X5 升级到 3.5.0+ 后旧脚本是否仍兼容 pyeasy_dnn,文档未明确——以板上实际 import 和 `ls /app/pydev_demo/` 为准。
- **裸 libdnn C++ API(`hbDNN*`)**:逐函数签名不在本批 doc 内,在 OE 文档;S 系 C++ 样例仅以 per-model 类 + `.infer()` 演示,未暴露底层调用序列。
- **X 系 spcdev 的 C API 头文件清单**:`bpu.md` 只说「基于 spcdev 接口/`libspcdev.so`」,未逐个列出 spcdev 函数签名。
- **pyeasy_dnn 完整 API 面**:本批 doc 给出 `dnn.load` / `models[i].forward` / `inputs[i].properties` / `outputs[i].properties` / `outputs[i].buffer`,但未给完整方法/属性手册;如需深挖另取 X 系多媒体 API 或 hobot_dnn 专页。