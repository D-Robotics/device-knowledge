# BPU 工具链:X 系列 hb_mapper→.bin vs S 系列 hb_compile→.hbm

> 来源:本文事实逐条取自官方 doc,均可溯源。
> - X 系列(Bernoulli2/Bayes):rdk_doc `docs/07_Advanced_development/04_toolchain_development/intermediate/ptq_process.md`、`.../runtime_sample.md`、`.../overview.md`
> - S 系列(Nash):rdk_s_doc `docs/07_Advanced_development/04_toolchain_development/01_algorithm_toolchain/01_overview.md`、`docs/04_Algorithm_Application/02_Python_API.md`、`docs/04_Algorithm_Application/04_C++_Sample/02_ResNet18.md`;rdk_model_zoo(`rdk_s` 分支)`samples/vision/mobilenetv2/conversion/`、`samples/vision/3dresnet/conversion/`、`samples/vision/resnet152/conversion/`
> - OE 在线手册:<https://toolchain.d-robotics.cc/>;OE 资源入口:<https://developer.d-robotics.cc/rdk_doc/rdk_s/Advanced_development/toolchain_development/overview>
>
> 注意:模型转换始终在 **x86 Linux 主机 Docker** 内完成,**板端只有 runtime**。下文 march 取值、命令名、产物后缀以官方最新工具链文档为准;拿不准的 march 变体(如 `nash-m`/`nash-p`)见文末。

## 0. 一图对照

| 维度 | X3 / X5 / RDK Ultra | S100 / S100P / S600 |
|---|---|---|
| BPU 架构 | Bernoulli2(X3)/ Bayes(Ultra)/ Bayes-e(X5) | Nash |
| 主机端工具链 | 算法工具链 / OpenExplorer(hb_mapper 体系) | 天工开物 / OpenExplorer OE(hb_compile 体系) |
| 验证命令 | `hb_mapper checker` | `hb_compile --model x.onnx --march <nash-*>` |
| 编译命令 | `hb_mapper makertbin --config x.yaml` | `hb_compile --config x.yaml` |
| `march` 取值 | X3=`bernoulli2`、Ultra=`bayes`、X5=`bayes-e` | **S100=`nash-e`、S100P=`nash-m`**(官方 FAQ);S600=`nash`,后缀以最新文档为准 |
| 产物后缀 | `.bin` | `.hbm` |
| 中间/调试产物 | `hb_perf` html、`hb_mapper_*.log` | `*_quantized_model.bc`(HBIR,可 x86 推理比对) |
| 主机性能评估 | `hb_perf x.bin` | x86 推理脚本(ONNX/HBIR/HBM 三态比对) |
| 板端底层库 | `libdnn.so` + `hbDNN*` C API | `libdnn` + `libhbucp`/`libucp` |
| 板端上层加载 | `hobot_dnn` / TROS `dnn_node` | `hbm_runtime`(`HB_HBMRuntime`,pybind11) |
| LLM 链路 | — | 独立 `D-Robotics_LLM_S100` SDK,非本表 CNN 链路 |

**跨架构产物不能复用**:`.bin` 与 `.hbm` 互不通用,且不同 march 编译产物互不通用。

---

## 1. 通用前置:浮点模型约束(两条链路都适用)

> 来源:rdk_doc `.../overview.md`;Nash 算子实证见 §4.4

- 框架:支持 caffe 1.0 浮点模型,以及 `ir_version ≤ 7`、`opset10`/`opset11` 的 onnx 浮点模型;其他框架需先导出符合要求的 onnx。
- 输入:只支持**固定 4 维** NCHW 或 NHWC,且 **N 维只能为 1**(如 `1x3x224x224`),不支持动态维度/非 4 维。
- 后处理:浮点模型里**不要包含 nms 等后处理算子**,放到部署后处理里算。
- 未列入算子支持列表的算子因 BPU 硬件限制暂不支持;转换前先查算子支持列表。

---

## 2. X 系列链路:hb_mapper → `.bin`

> 来源:rdk_doc `.../intermediate/ptq_process.md`

### 2.1 验证模型(checker)
```bash
hb_mapper checker \
  --model-type ${model_type} \   # caffe 或 onnx
  --march ${march} \             # X3=bernoulli2 / Ultra=bayes / X5=bayes-e
  --model ${model.onnx} \
  --input-shape ${input_name} ${NxCxHxW}   # 可选,多输入多次传
```
- 日志默认写入 `hb_mapper_checker.log`(`--output` 已废弃)。
- 出现 CPU 算子会把模型拆成多个 Subgraph;理想情况只有 1 个子图。把 pow/reshape 这类 CPU 算子移到后处理可减少子图。

### 2.2 准备 yaml + 校准数据 + 编译(makertbin)
```bash
# 不开启 fast-perf(正式转换)
hb_mapper makertbin --config ${config_file} --model-type ${model_type}

# 开启 fast-perf(只为快速测最高性能 bin)
hb_mapper makertbin --fast-perf --model ${model} --model-type ${type} --march ${march}
```

yaml 关键结构(节选):
```yaml
model_parameters:
  onnx_model: '****.onnx'        # 或 prototxt + caffe_model 二选一
  march: 'bernoulli2'           # Ultra=bayes / X5=bayes-e
  output_model_file_prefix: 'mobilenetv1'
  working_dir: './model_output_dir'
input_parameters: { ... }       # 输入类型/排布/归一化
calibration_parameters: { ... } # 校准数据目录与方法
compiler_parameters:
  optimize_level: 'O3'          # bayes/bayes-e 在 O3 默认启用编译缓存
```
- 失败查 `hb_mapper_makertbin.log`;转换成功控制台尾部有明确提示,并给出各输出 Cosine 相似度。

### 2.3 主机性能评估
```bash
hb_perf ***.bin          # pack 后的模型加 -p:hb_perf -p ***.bin
```
产出 `hb_perf_result/`(子图结构 + BPU 静态分析,**不含 CPU 部分**,CPU 性能须上板实测)。

### 2.4 板端加载
- 底层 `libdnn.so` + `hbDNN*` C API(`hbDNNGetModelHandle`、`hbDNNInfer`、`hbDNNResize`、`hbDNNRoiInfer` 等)。
- 上层用 `hobot_dnn` / TROS `dnn_node`(如 `dnn_node_example`)加载 `.bin`,模型常放 `/userdata/models/`。

---

## 3. S 系列链路:天工开物/OE + hb_compile → `.hbm`

### 3.1 装工具链(OE 包 + Docker)
> 来源:rdk_s_doc `.../01_algorithm_toolchain/01_overview.md`(V3.7.0,对应 S100 系统软件 4.0.5 / S600 5.1.0;板端 `cat /etc/version` 确认)

```bash
# OE 开发工具包(含 OE 用户手册,在线版 https://toolchain.d-robotics.cc/)
wget https://d-robotics-aitoolchain.oss-cn-beijing.aliyuncs.com/oe/3.7.0/oe-package-3.7.0-s100-s600.tgz

# CPU Docker(在线拉取)
docker login -u "ccr\$deliver-ronly" registry.d-robotics.cc -p '<密码见官方 overview 文档>'
docker pull registry.d-robotics.cc/deliver/ai_toolchain_ubuntu_22_s100_s600_cpu:v3.7.0
# 或离线 tar:.../oe/3.7.0/ai_toolchain_ubuntu_22_s100_s600_cpu_v3.7.0.tar(GPU 版同理)
```

启动容器(挂载工程 + 增大共享内存):
```bash
sudo docker load -i ai_toolchain_ubuntu_22_s100_xxx.tar   # 离线包
sudo docker run -it --rm \
  --network host --shm-size=15g \
  -v "$(pwd)":/workspace --workdir /workspace \
  <docker-image-name> /bin/bash
```
> 来源:rdk_model_zoo `rdk_s` 分支 `samples/vision/3dresnet/conversion/README_cn.md`

### 3.2 验证模型(hb_compile 快速校验)
> 来源:rdk_model_zoo `rdk_s` 分支 `samples/vision/mobilenetv2/conversion/README.md`
```bash
hb_compile --model mobilenetv2_100.onnx --march nash-e
```

### 3.3 准备校准数据
> 来源:rdk_model_zoo `rdk_s` 分支 `samples/vision/resnet152/conversion/get_calibration_data.py`

用 `horizon_tc_ui` 的 transformer 做预处理(须与推理前完全一致:含减均值、归一化),结果存为 `.npy`(float32):
```python
from horizon_tc_ui.data.transformer import (
    PaddedCenterCropTransformer, ResizeTransformer, HWC2CHWTransformer,
    MeanTransformer, ScaleTransformer, RGB2BGRTransformer)
transformers = [
    PaddedCenterCropTransformer(224),
    ResizeTransformer(target_size=(224,224), mode='skimage', method=3),
    HWC2CHWTransformer(),
    ScaleTransformer(scale_value=255.0),
    MeanTransformer(means=np.array([123.675,116.28,103.53])),
    ScaleTransformer(scale_value=0.017),
]
```
校准图片量级:示例用约 **100 张**(覆盖真实输入分布)。

### 3.4 编写 config.yaml + 编译(hb_compile → `.hbm`)
> 来源:rdk_model_zoo `rdk_s` 分支 `samples/vision/mobilenetv2/conversion/mobilenetv2_config.yaml`

```yaml
model_parameters:
  onnx_model: '../mobilenetv2_100.onnx'
  march: "nash-e"
  layer_out_dump: False
  working_dir: '../model_output'
  output_model_file_prefix: 'mobilenetv2_224x224_nv12'
input_parameters:
  input_type_rt: 'nv12'
  input_type_train: 'bgr'
  input_layout_train: 'NCHW'
  norm_type: 'data_mean_and_scale'
  mean_value: 103.53 116.28 123.675
  scale_value: 0.017429 0.017507 0.017124
calibration_parameters:
  cal_data_dir: '../calibration_data_bgr'
  cal_data_type: 'float32'
  calibration_type: 'default'
compiler_parameters:
  optimize_level: 'O2'
```
```bash
hb_compile --config conversion/mobilenetv2_config.yaml
# 产物:model_output/mobilenetv2_224x224_nv12.hbm
#       + model_output/mobilenetv2_224x224_nv12_quantized_model.bc(HBIR 中间态)
```
注意 yaml 结构与 X 系列 §2.2 **同构**——差异只在 `march` 值、命令名(`hb_compile` vs `hb_mapper makertbin`)、产物后缀(`.hbm` vs `.bin`)。

### 3.5 主机端精度比对(.bc HBIR)
> 来源:rdk_model_zoo `rdk_s` 分支 `mobilenetv2/runtime/python/x86_inference.py`

x86 推理脚本可直接吃 **ONNX / HBIR(.bc)/ HBM** 三种格式,便于量化前后比对:
```bash
python3 runtime/python/x86_inference.py -m model_output/mobilenetv2_224x224_nv12_quantized_model.bc -i test.jpg
# 量化后余弦相似度示例:output Calibrated 0.993383 / Quantized 0.988877
```

### 3.6 板端加载:`hbm_runtime`
> 来源:rdk_s_doc `docs/04_Algorithm_Application/02_Python_API.md`、`docs/04_Algorithm_Application/04_C++_Sample/02_ResNet18.md`

**安装**(基于 pybind11 封装 `libdnn`/`libhbucp`/`libucp`,需 Python ≥ 3.10):
```bash
sudo apt-get install hobot-dnn          # 或 dpkg -i hobot-dnn_*.deb
# 安装过程会构建 hbm_runtime 的 whl,落在板端 /tmp:
#   hbm_runtime-x.x.x-cp310-cp310-manylinux_2_34_aarch64.whl
pip install /tmp/hbm_runtime-*.whl       # 或 pip install hbm_runtime
```

**Python 推理(最简)**:
```python
import numpy as np
from hbm_runtime import HB_HBMRuntime
model = HB_HBMRuntime("/opt/hobot/model/s600/basic/resnet18_224x224_nv12.hbm")
name = model.model_names[0]
inp = model.input_names[name][0]
x = np.ones(model.input_shapes[name][inp], dtype=np.float32)
out = model.run(x)            # 返回 {model_name: {...}} 嵌套结构
print(out[name])
```
- 支持单模型多输入(`Dict[str,np.ndarray]`)、多模型(`Dict[str,Dict[...]]`,可多个 .hbm 或单 .hbm 内含多模型),推理时 C++ 侧释放 GIL → Python 多线程可并发。
- 可选调度:`set_scheduling_params(...)` 设默认,或在 `run()` 里单次覆盖优先级 / BPU core 绑定 / device id。

**C++ 推理**:示例工程在板端 `/app/cdev_demo/bpu/.../resnet18/`,`cmake .. && make` 后:
```bash
./resnet_18 --model_path /opt/hobot/model/s600/basic/resnet18_224x224_nv12.hbm --top_k 5
```
模型默认目录 `/opt/hobot/model/s100|s600/basic/`。

---

## 4. 关键差异与坑

### 4.1 命令名别搞混
- S 系列是 `hb_compile`,**不是** `hb_mapper`;X 系列才是 `hb_mapper checker` / `hb_mapper makertbin`。在 S 板/容器里敲 `hb_mapper` 会找不到。

### 4.2 march 取值
- X3=`bernoulli2`、RDK Ultra=`bayes`、X5=`bayes-e`(均有官方 doc 出处)。
- **官方 FAQ 按板型区分 march:Super100(S100)=`nash-e`、Super100P(S100P)=`nash-m`**(BPU 架构名即 march)。示例 `mobilenetv2_config.yaml` 用 `nash-e` 是 S100 的;S100P 改 `nash-m`。S600=`nash`(后缀以工具链最新文档为准)。`bpu_export_config.yaml` 的 `type` 字段可选 `nash-e`/`nash-m`/`nash-p` 即对应不同 SKU。

### 4.3 产物与中间态
- X:`.bin` + `hb_perf` html;S:`.hbm` + `*_quantized_model.bc`(HBIR,可在 x86 上推理比对)。
- 两边都不要把 `.pt` / 原生 `.onnx` 拷上板直接跑——那只走 CPU。

### 4.4 算子约束(Nash 实证)
> 来源:rdk_model_zoo `rdk_s` 分支 `samples/vision/3dresnet/conversion/README_cn.md`(OpenExplorer 3.5.0)
- 工具链支持 `Conv3D`,但**不支持** 3D `GlobalAveragePooling`;需在转换前把该 3D pooling 路径替换为等价 2D `ReduceMean` 再编译。
- 该模型转换后多数算子相似度 > 0.99,最终量化相似度约 0.99。
- 通用约束见 §1。

### 4.5 LLM 是另一条链路
> 来源:rdk_s_doc `.../02_LLM_Toolchain/01_s100_LLM_Toolchain.md`
- S100/S100P 大模型(DeepSeek-R1-Distill-Qwen、InternLM2、Qwen2.5、Qwen2.5-Omni)走独立的 `D-Robotics_LLM_S100` SDK(q4/q8 量化、PPL 评估、板端 oellm_runtime),**不**走本文的通用 hb_compile CNN 链路。
```bash
wget https://d-robotics-aitoolchain.oss-cn-beijing.aliyuncs.com/llm_s100/1.0.0/D-Robotics_LLM_S100_1.0.0_SDK.tar.gz
```
