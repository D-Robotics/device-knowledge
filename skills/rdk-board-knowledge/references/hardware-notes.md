# RDK 板型基线与故障诊断 · 硬件与系统参考

> 来源:整理自 D-Robotics RDK 官方文档、工具链与社区实践,逐条保留出处链接;由 device-knowledge 知识库忠实转换而来,未改写技术事实。

本文汇集本 skill 涉及的 RDK 硬件/系统章节,逐节整理自官方文档与实践,供需要细节时查阅。

### 9. 常见开发陷阱

1. **USB 摄像头崩溃**：99% 是 YUYV 格式导致 → 改 MJPEG
2. **模型路径找不到**：launch 依赖工作目录 → 用 `find` 定位绝对路径
3. **pip install 板端失败**：无网或架构不匹配 → 在联网机器下载 aarch64 whl 再拷贝安装
4. **ros2 命令不存在**：未 source TROS → `source /opt/tros/humble/setup.bash`
5. **/app 目录只读**：放到 `/tmp`、`/userdata`、`$HOME`
6. **GPIO 编号错误**：不能用树莓派的编号 → 查当前板型的 pinout 文档
7. **Docker 镜像架构错**：必须用 arm64/aarch64 镜像
8. **hobot_dnn 在 venv 中找不到**：必须用系统 Python，不支持虚拟环境

### 18. 用户高频误区与一句话纠正

> Moss 收到以下问法时，**先纠正误区再继续**；不要顺着错误前提回答。

| 误区表述 | 事实与纠正 |
|----------|-----------|
| "我在 X3 编译的 .bin 直接拷到 X5 跑" | 不行，BPU 架构不同（Bernoulli2 vs Bayes），必须用对应工具链重编 |
| "Ultra 就是 X5 超频版" | 不是。Ultra 是同 Bayes 架构但**算力×9.6**、8GB RAM、主动散热专设的工业/科研板；`.bin` 多数互通但 X5 上测试过不代表 Ultra 能跑满 |
| "`hb_mapper` 我在板子上 `apt install` 不到" | 对。工具链在**主机 Docker**里运行，不在板上；板上只装 runtime（`hobot-dnn`、`bpu_infer_lib_*`）|
| "S100 = Jetson Orin 国产替代" | 定位接近但架构差异大——Jetson 走 GPU + CUDA，S100 走 BPU + ONNX 工具链；代码**不能直接迁移**，需要重新走模型转换 |
| "X5/S 系列只有 root / sunrise 是 X3 专属" | ❌ 官方 RDK 镜像普遍**同时提供 `sunrise/sunrise`(普通)+ `root/root`(超级)**两个账户(X5、S100、S600 都如此,见官方 FAQ Q13 与配置向导)。`sunrise` 不是 X3 专属;X3 主登录用 sunrise,RDK Studio 的 SSH 通道则多走 root |
| "模型放 `/opt/hobot/model/rdkx5/` 吧" | 实际路径是 **`/opt/hobot/model/x5/`**（目录名不含 `rdk` 前缀）；X3 则在 `/opt/hobot/model/rdkx3/`（**有** `rdk` 前缀，历史原因，确实不对称）|
| "X5 也能用 `hrut_smi` / `bputop`" | **不能**。RDK OS 3.x 的 X5 镜像只装了 `hrut_bpuprofile` + `hrut_somstatus`；`hrut_smi` 主要在 X3，`bputop` 主要在 X3/Ultra。所有板通用的兜底是 `cat /sys/devices/system/bpu/bpu0/ratio` |
| "RDK OS 1.x 的机器 `apt upgrade` 到 3.x" | **不行**。1.x 到 2.x/3.x 必须**重刷镜像**；同主版本升级也要按官方流程评估与备份，Studio 不自动跑整机 `apt upgrade` |
| "hobot_dnn 我放 venv 里用" | 不行。`hobot_dnn` Python bindings 只认**系统 Python**（`/usr/bin/python3`），conda/venv 里找不到 |
| "rosdepc 是 pip 包" | 不是。`rosdepc` 是D-Robotics对 `rosdep` 的国内镜像加速封装，随 TROS apt 包一起来 |
| "RDK Studio = RDK 硬件" | **RDK Studio 是桌面 IDE 工作台**（本仓库即是），运行在 PC 上连 RDK 板；不是板子本身，也不预装在板上（但可以和板上 OpenClaw 协同） |
| "NodeHub 和 Model Zoo 是一回事" | 两个仓库：**NodeHub** 侧重 ROS2 节点级应用（developer.d-robotics.cc/en/nodehub，Studio 内也有 NodeHub 入口），**Model Zoo** (`rdk_model_zoo` / `rdk_model_zoo_s`) 侧重模型 + 推理样例 |
| "RDK 是地平线的" | 品牌称谓：现官方为 **D-Robotics**；历史上与地平线有渊源，外部旧资料里的 "Horizon / 地平线" 指的是同一条产品线，口径以D-Robotics为准 |
| "RDK S100 就是速腾聚创 RoboSense 的激光雷达吧" | **完全两回事**！RDK S100 是D-Robotics的**计算开发板**（SoC + BPU）；速腾聚创的 RS 系列是激光雷达传感器。CSDN 上确实有把两者混淆的文章，直接纠正即可。 |

---
