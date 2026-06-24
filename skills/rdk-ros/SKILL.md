---
name: rdk-ros
description: 当涉及 RDK 上的 TROS/ROS2 环境初始化、ros2 命令、节点排障、包定位、或双目深度(hobot_stereonet)/Livox 激光雷达/点云/SLAM 建图等感知节点时使用。摄像头格式/驱动排障走 rdk-device,GPIO/外设驱动走 rdk-peripheral-cookbook。
---

# RDK TROS/ROS2 开发

> 来源:整理自 D-Robotics RDK 官方文档、工具链与社区实践,逐条保留出处链接;由 device-knowledge 知识库忠实转换而来,未改写技术事实。

## 何时用

RDK 板端 TROS/ROS2 环境初始化、`ros2` 命令报错或排障、定位 ROS2 包/launch/config、或上手双目深度(hobot_stereonet)/Livox 激光雷达等感知节点时。

ros2 命令不存在多半是没 source TROS 环境;先确认环境与包存在再执行。

**TROS/ROS2 环境**：
- `ros2` 命令不存在 → `source /opt/tros/humble/setup.bash`(X3/X5/Ultra/S100/S100P 基于 ROS2 **Humble**，路径 `/opt/tros/humble/`)
- **RDK S600 是 Ubuntu 24.04 / ROS2 Jazzy** → 用 `source /opt/tros/jazzy/setup.bash`(路径 `/opt/tros/jazzy/`,`apt` 包名 `tros-jazzy-*`);**别在 S600 上找 humble**,反之亦然
- S100/S600 部分镜像仅 sunrise 用户配了 TROS → `su - sunrise` 再试
- 自定义包: `colcon build --symlink-install` → `source install/setup.bash`
- 节点失败: `ros2 run <pkg> <node> --ros-args --log-level debug` 查详细日志
- 先 `device_exec` 确认包名和文件存在，不要盲猜 launch 文件路径

**排障速查**：
- `ros2 pkg list | grep <name>` 确认包是否安装；`ros2 pkg prefix <name>` 查安装路径
- `ros2 launch <pkg> <launch.py> --show-args` 查看 launch 可用参数
- `ros2 node list` / `ros2 topic list` 确认节点和话题状态
- 预装节点在 `/opt/tros/humble/lib/<pkg>/`，模型文件常在包内 `config/` 目录(X3/X5/Ultra 为 `config/*.bin`,S100/S100P 为 `config/*.hbm`)

**感知节点上手要点**(详见 references/hardware-notes.md)：
- 双目深度(hobot_stereonet)：必须先用棋盘格做双目内/外参标定，生成 `left.yaml`/`right.yaml`/`extrinsics.yaml`，路径在 launch 中指定；左右相机时间戳偏差 > 30ms 显著影响视差精度。
- Livox 激光雷达(livox_ros_driver2)：必须走有线(Wi-Fi 带宽不够)，网卡 MTU 保持 1500 否则丢包；默认网段 192.168.1.x，按型号选 launch(如 `ros2 launch livox_ros_driver2 msg_HAP_launch.py`)。
- **想跑某个感知能力但不知道用哪个节点**(检测/分割/人体/人脸/手势/双目深度/3D/激光雷达/语音/VLM…):查 [TROS 功能节点目录](references/tros-node-catalog.md)——按 audio/body/classification/detection/driver/function/generate/segmentation/spatial 九类 + apps 分表,每个节点给「包名/作用/关键订阅话题/关键发布话题/支持板型/最小 launch/官方文档」。话题约定速记:图像输入走 `/image` 或零拷贝 `/hbmem_img`,AI 结果由 `ai_msg_pub_topic_name` 指定,级联节点订阅上游 `/hobot_mono2d_body_detection`;检测/分类/分割多走 `dnn_node_example` + `dnn_example_config_file` 切模型。

## 工作流:TROS/ROS2 环境确认与包定位

**触发场景**:ros2 command not found / TROS 环境 / 找不到 launch / ros2 package / colcon

**前置条件**:
- 已确认设备系统版本和登录用户。
- 需要执行 ROS2/TROS 节点或定位包资源。

**步骤**:

1. **加载 TROS 环境** `[safe]`
   RDK TROS 默认路径通常在 /opt/tros/humble，部分镜像需要切换到配置好的用户。
   ```bash
   source /opt/tros/humble/setup.bash
   ```
   预期:当前 shell 能找到 ros2 命令。

2. **验证 ROS2 命令可用** `[safe]`
   先确认环境变量生效，再继续定位包或 launch。
   ```bash
   ros2 pkg list | head
   ```
   预期:输出若干 ROS2/TROS 包名。

3. **定位目标包前缀** `[safe]`
   不要猜 launch 文件路径，先让 ros2 告诉你包安装位置。
   ```bash
   ros2 pkg prefix <pkg>
   ```
   预期:输出目标包路径；找不到时检查包名或安装状态。

4. **查找 launch/config 资源** `[safe]`
   用 find 在实际安装目录中定位 launch、模型(.bin/.hbm)、yaml 等资源。
   ```bash
   find /opt/tros -name "*launch.py"   # 通配 *_launch.py 与 *.launch.py 两种命名(D-Robotics 包多用 _launch.py)
   ```
   预期:找到候选 launch 文件后再组织 ros2 launch 命令。

**验证**:
- 节点可执行验证 — `ros2 run <pkg> <node> --ros-args --log-level debug`:节点能启动或给出明确错误；错误应与包路径、参数或硬件资源关联。
- 构建后环境验证 — `source install/setup.bash && ros2 pkg list | grep <pkg>`:自定义包构建后能被当前 shell 发现。

**安全注意**:
- 不要把相对路径配置直接照搬到不同工作目录；优先使用板端 find/ros2 pkg prefix 得到绝对路径。

**预期结果**:用户能稳定加载 TROS 环境，定位包资源，并把 launch/节点错误收敛到可诊断范围。

来源:<https://developer.d-robotics.cc/rdk_doc/Robot_development/quick_start/preparation> <https://developer.d-robotics.cc/rdk_doc/Robot_development/quick_start/ros_pkg> <https://github.com/D-Robotics/robot_dev_config>

## 硬件参考主题

以下主题详见 [硬件与系统参考](references/hardware-notes.md):

- TROS (TogetheROS.Bot)
- 双目深度（hobot_stereonet）
- Livox 激光雷达（livox_ros_driver2）

## 参考资料

- [TROS/ROS2 命令](references/ros-commands.md)
- [TROS 功能节点目录(感知能力→节点速查)](references/tros-node-catalog.md)
- [官方端到端应用案例(X 系列 AMR / 巡线小车)](references/app-cases.md)（从硬件清单→传感器自检→kalibr 标定→建图导航 / CNN 采集标注训练量化→板端 BPU 推理闭环的整链路;单点节点仍查 tros-node-catalog）
- [硬件与系统参考(详细章节)](references/hardware-notes.md)
