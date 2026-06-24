# RDK 设备控制与模型部署 · 硬件与系统参考

> 来源:整理自 D-Robotics RDK 官方文档、工具链与社区实践,逐条保留出处链接;由 device-knowledge 知识库忠实转换而来,未改写技术事实。

本文汇集本 skill 涉及的 RDK 硬件/系统章节,逐节整理自官方文档与实践,供需要细节时查阅。

### 19. 新手"从 0 到 1"标准路径（X5 为主，覆盖 90% 社区咨询）

> 用户第一次拿到板说 "我怎么开始"、"跑个 demo"、"入门"、"开箱" 时，按这个清单推进，不要一上来就讲 BPU 工具链。

**X5 开箱到第一个检测的最短路径**：

```
[ 1 ] 烧录 SD 卡                  → RDK Studio 烧录 / Rufus，镜像从 developer.d-robotics.cc 资源入口或 GitHub `D-Robotics/system_download` 清单获取；3.x 镜像默认 Humble
[ 2 ] 供电 + 启动                 → **必须**官方 5V/5A Type-C；电脑 USB 口供电≈反复重启
[ 3 ] 指示灯判断                  → 绿色电源灯亮=供电正常；橙色状态灯**闪烁**=系统正常（橙灯为 **3.1.0+ 固件**才有,更早只有绿色 ACT 灯闪）
[ 4 ] 首次配置向导                → 首次启动有 ~45s 默认环境配置；之后用 `sudo srpi-config` 配 Wi-Fi/SSH/VNC/语言区域
[ 5 ] 联网 + 获取 IP             → `nmcli dev wifi connect "SSID" password "pwd"`(S 系列也可 `wifi_connect "SSID" "PWD"`) → `ip addr`
[ 6 ] SSH 登录                    → 各板**同时有** `root/root` 与 `sunrise/sunrise`(桌面 autologin 用 sunrise);`ssh root@<ip>` 或 `ssh sunrise@<ip>`。**S100/S600 管理口 eth1 出厂固定 `192.168.127.10`**
[ 7 ] 第一个检测示例（预装）      → `cd /app/pydev_demo/02_detection_sample/ && sudo python3 ...`（按目录内 README;X5 3.5.0+ 目录见下）
[ 8 ] Web 实时检测                → `cd /app/pydev_demo/09_web_display_camera_sample/`，浏览器访问 `http://<ip>:8000`
```

**X5 `/app/pydev_demo/` 内置示例清单**（**软件 3.5.0+**,按任务命名,用 `hbm_runtime` 加载;无需转模型）：

| 目录 | 功能 |
|------|------|
| `01_classification_sample/` | 图像分类 |
| `02_detection_sample/` | 目标检测（内含 `01_ultralytics_yolov5x` / `02_yolo11` / `03_yolov8` / `04_yolov10`） |
| `03_instance_segment_sample/` | 实例分割 |
| `04_pose_sample/` | 姿态估计 |
| `05_open_instance_segment_sample/` | 开放词汇实例分割 |
| `06_segment_sample/` | 语义分割 |
| `07_usb_camera_sample/` | USB 摄像头采集 |
| `08_mipi_camera_sample/` | MIPI 摄像头采集 |
| `09_web_display_camera_sample/` | Web 浏览器显示推理（8000 端口,最适合演示） |

> **版本/板型差异**:① 旧 X5(<3.5.0)/X3 是另一套编号清单(`01_basic_sample`/`07_yolov5_sample`/`09_yolov5x_sample` 等,用 `pyeasy_dnn`);以板上实际 `ls /app/pydev_demo/` 为准。② **S 系列(S100/S600)** 预装示例同在 `/app/pydev_demo/` 下(S100 形如 `01_classification_sample/01_resnet18`,S600 形如 `classification_sample/resnet18` 无数字前缀),统一用 `hbm_runtime`(`HB_HBMRuntime`)加载 `.hbm`,模型默认在 `/opt/hobot/model/s100|s600/basic/`,Python ≥ 3.10。

**新手三个"标志性成就"路径**（由浅入深）：
1. **跑通预装 YOLOv5** → 5 分钟 → "确认板卡正常 + BPU 工作"
2. **用 Web 示例看实时检测** → 10 分钟 → "摄像头 + BPU + 网络" 三者联调
3. **跑一次自己训练的模型** → 半天到数天 → 进入"模型部署全流程"（下一节）

### 20. 模型部署全流程与高频踩坑（**最核心的用户痛点**）

> 社区数据：新手在这一步卡住的占比 **60%+**。看到用户说 ".pt 拷上去跑" / "推理巨慢" / "YOLO 转换失败" 等任一关键词 → **先警告再继续**，不要顺着他跑。

**第一铁律 — `.pt` / `.onnx` 不能直接在 BPU 上加速**：
- 原生 PyTorch / ONNX Runtime 在 RDK 板上只会走 **CPU**，BPU 完全不参与 → 通常只有 **1-2 FPS**
- 用户说"我模型跑上去只有 X FPS" / "直接部署的 .pt" → **立即**告诉他要走 `.pt → .onnx → .bin` 全流程，否则没意义
- 社区里大量博客都印证这点（CSDN "直接部署 .pt 推理速度慢，视频流很卡"）

**完整全流程（主机 + 板端）**：

```
[主机 x86 / Docker]                     [板端 aarch64]
────────────────                         ──────────
[1] PyTorch/TF 训练                      
[2] 导出 ONNX（用 vendor fork）     ──▶  
[3] hb_mapper checker 验证算子       
[4] 准备校准数据集（~100 张）            
[5] hb_mapper makertbin 量化转换     
[6] 得到 .bin(X3/X5/Ultra)/.hbm(S100/S100P) ──▶ [7] scp 到板上 /userdata/models/
                                         [8] 加载推理:X3/X5/Ultra 用 hobot_dnn / ROS2 节点,S100/S100P 用 hbm_runtime
                                         [9] hb_eval_perf 评估 fps/latency
```

> 注:`hb_mapper → .bin` 是 X3/X5/Ultra(Bernoulli2/Bayes)链路;**S100/S100P(Nash)走 D-Robotics 天工开物/OE 工具链,产物是 `.hbm`,板端 `hbm_runtime`(pip 包 `hbm-runtime`)加载**。

**步骤级踩坑（都是社区真实反复出现的）**：

| 坑 | 症状 | 解决 |
|----|------|------|
| 直接拿 ultralytics 默认导出脚本导 ONNX | `hb_mapper checker` 报算子不支持 / 转换成功但上板检测框全乱 | 用**官方 `ultralytics/yolov5` 仓**(不是某 D-Robotics fork),但要按 [model_zoo YOLOv5 文档](https://github.com/D-Robotics/rdk_model_zoo/blob/rdk_x3/demos/detect/YOLOv5/README_cn.md)**改 Detect 输出头**(去掉后处理、改 4 维 NHWC);`checkout v2.0`(LeakyReLU)或 **`v7.0`(Sigmoid)** 都支持(各按文档改输出头),不是"只能 v2.0" |
| Docker 拉不下来 / 启动不了 | 用户在 Win 上装 WSL2 + Docker，config 出错起不来 | 优先用**D-Robotics官方 Docker 镜像**（Horizon OE / 天工开物）；WSL2 要 `wsl --update`；内存分配 ≥ 8GB；镜像大所以国内优先拉 CPU 版 |
| ONNX opset 版本不对 | `hb_mapper checker` 报不支持的算子 | export 时固定 `--opset 11`（Bayes）/ 以工具链文档为准；X3 Bernoulli2 更严格，S100 Nash 最宽松 |
| 校准数据集缺失 / 量化精度暴跌 30%+ | 转换成功但上板 mAP 暴跌 | 必须准备 **50-100 张**与训练集分布一致的图片做 PTQ；RKNN 社区经验（同理适用）：`do_quantization=True` 时校准集决定精度 |
| 转换时 OOM | 大模型 `hb_mapper makertbin` 进程被杀 | 主机 RAM ≥ 16GB，或用 ZRAM；先试 YOLOv5s 不要直接 YOLOv5x |
| 工具链 `march` 参数填错 | `hb_mapper checker --march bayes-e` 的 `bayes-e` 不能用在 X3 | X3 → `bernoulli2` / X5 → `bayes-e` / Ultra → `bayes` / **S100 → `nash-e`、S100P → `nash-m`**（官方 FAQ）/ S600 → `nash`；S 系列走天工开物/OE，产物 `.hbm`、板端 `hbm_runtime` |
| 板上 runtime 版本与 .bin 不匹配 | `libdnn` / `hobot_dnn` 初始化失败 | `dpkg -l \| grep hobot-dnn` 看板上版本；必要时按官方发布说明升级 `hobot-dnn` / BPU runtime |
| 在虚拟环境里 import hobot_dnn | `ModuleNotFoundError` | `hobot_dnn` Python bindings 只认系统 Python `/usr/bin/python3`；conda/venv 全部失败，社区反复踩 |

**Moss 应对脚本（遇到模型部署问题时）**：
1. 先确认**模型当前状态**（`.pt` / `.onnx` / `.bin`？在主机还是板上？）
2. **看到 `.pt` / `.onnx` 上板跑**：立刻打断，解释三步流程
3. 明确**板型 → 对应工具链**（X3 用 OE v1，X5/Ultra 用 OE v2，S100 用天工开物）
4. 转换报错时**不要乱猜**，让用户粘 `hb_mapper` 的错误日志前 30 行
5. 成功转换后才谈部署路径（`/userdata/models/` 或 TROS 包 `config/`）
