# RDK 官方端到端应用案例(X 系列:AMR / 巡线小车)

> 来源:rdk_x_doc(default branch `main`)`docs/06_Application_case/amr.md`(标 RDK-X5)与 `docs/06_Application_case/line_follower.md`。只写文档有出处的事实,GitHub 仓与命令均取自原文。这两个案例是**完整 ROS2/TROS 工程**,放本目录是因为它们以 TROS 节点 + colcon + launch + BPU 推理为骨架,与本 skill 的 TROS 工作流/感知节点目录同质;S 系列方案展示(无 build 步骤)在 rdk-ecosystem,不在此。

## 何时翻这页

用户想「照着官方做一台能跑的机器人」——自主移动导航(AMR)或 CNN 巡线小车——需要从硬件清单、传感器自检、标定、建图导航、模型训练到板端推理的**整链路**指引时。单点能力(只问双目深度/只问 nav2 某参数)仍回 SKILL.md 与 tros-node-catalog.md。

## 案例一:AMR 自主移动机器人(RDK X5)

**定位** —— 官方 AMR 整机方案,X5 主控,多传感器融合 + nav2 自主导航。文档强调 AMR 不同于依赖轨道/预定义路线的 AGV。

**硬件清单(关键件)** —— RDK X5 ×1、舵轮 AMR 底盘(煜禾森)、单线激光雷达(氪见)、ToF 摄像头(光鉴)、双目摄像头 230ai(地瓜配件)、IMU **BMI088**(地瓜配件)、USB 转网口、12V→5V 供电、若干 3D 打印支架/盖板。底盘走 **CAN**,双目走 22pin 排线,激光雷达走网口(网段/掩码需与板子一致)。

**软件链路(TROS Humble)**:
1. **传感器自检** —— 双目查 `i2c`;雷达 `ping` 通且网段一致;底盘 `ip link` 起 CAN(`can1` 出现 `<NOARP,UP,LOWER_UP>`)并收 can 数据;IMU 查 i2c 并读三轴数据。
2. **功能安装** —— `sudo apt -y tros-hobot-nav2 ros-foxy-navigation2 ros-foxy-nav-msgs`;源码编译类:`hobot_stereonet`(双目深度,D-Robotics)、`Tofslam_ros2`、`voxel_filter`(点云过滤)、`pose_setter`(指定位置导航)。
3. **编译** —— `source /opt/tros/humble/setup.bash && colcon build`。
4. **标定(kalibr,官方提供 docker)** —— 棋盘格或 aprilgrid;依次做双目内参、单目内参、IMU 参数、IMU↔RGB 外参;采图用 `ros1_bridge` 把话题转 ros1 bag(需 Ubuntu 20.04 装 ros1+ros2)。
5. **建图** —— tofSLAM(`Localization_mode: False` 为建图),产物 `final-voxel.pcd`;`pcd2pgm` 转 pgm 栅格地图。建图时摄像头须看到完整 AprilTag;启动后静置 3~4s 等 IMU 初始化。
6. **定点导航** —— 启动 nav2 + 定点导航功能,`pose_setter` 用 AprilTag 算 robot→map 变换发布初始位姿,再依次请求多个目标点;nav2 障碍层叠加点云以避开低于激光雷达高度的障碍。

**用到的关键节点/仓库(均见 tros-node-catalog 可交叉)** —— `hobot_stereonet`(github.com/D-Robotics/hobot_stereonet)、`mipi_cam`(双目 `device_mode:=dual`/`out_format:=nv12`)、社区仓 `Tofslam_ros2`/`voxel_filter`/`pose_setter`/`pcd2pgm_package`。AMR 还用到官版 `yolov8-seg`(经 hobot_dnn 部署)。

## 案例二:CNN 巡线小车(line_follower,X3/X5)

**定位** —— 用 **CNN 替代传统阈值法**做巡线引导线感知;是「采集→标注→训练→量化→板端推理→UART 控制闭环」的完整工具链教学案例。代码仓 **github.com/D-Robotics/line_follower**(`x3` 用 `feature-x3` 分支、`x5` 用 `feature-x5` 分支,板端推理子包按设备型号拉对应分支)。

**端到端流水线**:
1. **采集 + 标注** —— 用 tros.b `hobot_sensor` 的 MIPI 采图 + 跨设备通信,把图传到 PC 标注;`ros2 run line_follower_model annotation`,右键点引导线中心标目标点,回车保存为 `xy_[x]_[y]_[uuid].jpg`。建议 ≥100 张,环境/场地变化时补采。
2. **训练** —— backbone 选 **ResNet18**,框架 **PyTorch**(CPU 或 GPU 版均可),代码 `line_follower_model/training_member_function.py`;`ros2 run line_follower_model training`。
3. **导出 ONNX** —— `ros2 run line_follower_model generate_onnx` → `best_line_follower_model_xy.onnx`。
4. **浮点转定点(算法工具链)** —— 代码 `line_follower/10_model_convert`;生成校准数据约 **100 张**,编译得 **`resnet18_224x224_nv12.bin`**(发挥 X3 5T BPU 算力)。
5. **板端推理 + 控制闭环** —— `line_follower_perception`(C++,`line_follower_perception.cpp`):把子包与定点模型拷到板端 `colcon build --packages-select line_follower_perception`,`ros2 run line_follower_perception line_follower_perception --ros-args -p model_path:=./resnet18_224x224_nv12.bin -p model_name:=resnet18_224x224_nv12`;摄像头取前方图→CNN 推理出引导线坐标→控制策略→**UART 下发运控指令**闭环。

**为什么归这里** —— 量化产物是 X 系列的 `.bin`(`resnet18_224x224_nv12.bin`),走 hobot_dnn/BPU runtime;模型转换走天工开物工具链(细节见 rdk-device 的 toolchain-workflow)。本页只串「整条工程怎么走」,单步深入分别去:模型转换→rdk-device、现成模型→rdk-model-zoo、TROS 节点→本 skill tros-node-catalog.md。

## 交叉指引

- 这两个案例的 doc 站点入口与路由,见 rdk-doc-finder 的 doc-map「应用案例」节。
- 案例仓库定位(line_follower 等)走 rdk-source-map。
- **S 系列**的官方方案(机器狗/人形/双臂等)是社区展示而非 build 教程,去 rdk-ecosystem 的「官方方案展示」。