# RDK TROS/ROS2 开发 · 硬件与系统参考

> 来源:整理自 D-Robotics RDK 官方文档、工具链与社区实践,逐条保留出处链接;由 device-knowledge 知识库忠实转换而来,未改写技术事实。

本文汇集本 skill 涉及的 RDK 硬件/系统章节,逐节整理自官方文档与实践,供需要细节时查阅。

### 5. TROS (TogetheROS.Bot)

- 基于 ROS2 Humble，路径 `/opt/tros/humble/`（X3/X5/Ultra/S100/S100P）;**RDK S600 是 ROS2 Jazzy，路径 `/opt/tros/jazzy/`**（Ubuntu 24.04，包名 `tros-jazzy-*`）
- 预装节点在 `/opt/tros/humble/lib/<pkg>/` 和 `/opt/tros/humble/share/<pkg>/`（S600 对应 `/opt/tros/jazzy/...`）
- 模型文件通常在包内 `config/` 目录：X3/X5/Ultra 为 `/opt/tros/humble/lib/<pkg>/config/*.bin`，S100/S100P 为 `config/*.hbm`（按板型 BPU 架构）
- 环境激活：`source /opt/tros/humble/setup.bash`
- **S100 特殊**：部分镜像仅 `sunrise` 用户的 `~/.bashrc` 配了 TROS source，root 需手动执行

**常用排障**
- `ros2 pkg list | grep <name>` — 确认包是否安装
- `ros2 pkg prefix <name>` — 查包安装路径
- `ros2 launch <pkg> <launch.py> --show-args` — 查看 launch 可用参数
- `ros2 node list` / `ros2 topic list` — 确认节点和话题状态

### 10. 双目深度（hobot_stereonet）

- **仓库**：<https://github.com/D-Robotics/hobot_stereonet>
- **板型适配**：官方支持表为 RDK X5/X5 Module(Humble) 与 S100;BPU 架构不同产物跨架构不通用(X5=`.bin`,S100/S600=`.hbm`)。以仓库当前支持表为准。
- **标定**：必须先用棋盘格做双目内/外参标定，生成 `left.yaml`/`right.yaml`/`extrinsics.yaml`，路径在 launch 中指定
- **常见坑**：
  - 左右相机时间戳偏差 > 30ms 会显著影响视差精度，建议用硬件触发（trigger 线）或 PTP 时间同步
  - 模型输入尺寸是双目各一路的 **640×352×3×2 或 544×448×3×2**(以仓库模型为准),深度图与左图对齐输出
  - 推理 fps 随板型/模型变化,以实测为准

### 11. Livox 激光雷达（livox_ros_driver2）

- **仓库**：<https://github.com/D-Robotics/livox_ros_driver2>
- **支持型号**：Mid-360（车规小型化）、HAP（量产）、Avia（开发款）等
- **网络**（以仓库 `config/*.json` 为准）：雷达走以太网 + UDP；默认网段 192.168.1.x
  - **Mid-360**：出厂 IP `192.168.1.1XX`（XX = 雷达 SN 后两位,如 SN 尾 02 → `192.168.1.102`）；上位机(板端)host 配 `192.168.1.50/24`；端口 host 侧 561xx
  - **HAP**：设备 IP `192.168.1.100`，板端 host IP `192.168.1.5`；端口 cmd 56000 / point 57000 / imu 58000 / log 59000
  - 防火墙放行约 UDP 56000-59000(HAP) / 561xx(Mid-360)
- **启动**：`ros2 launch livox_ros_driver2 msg_HAP_launch.py`（按型号选 launch）
- **数据类型**：`livox_ros_driver2/msg/CustomMsg`（含强度+时间戳）和标准 `sensor_msgs/PointCloud2` 二选一
- **常见坑**：
  - 网卡 MTU < 1500 会丢包，全部点云稀疏 → `sudo ip link set dev eth0 mtu 1500`
  - Wi-Fi 桥接走雷达数据带宽不够，**必须**走有线
  - rosbag 录制点云体积巨大（HAP ~50MB/s），按需开关录制
