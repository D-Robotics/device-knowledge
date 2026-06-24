# D-Robotics 仓库家族地图

> 来源:[github.com/D-Robotics](https://github.com/D-Robotics) 组织 327+ 仓库元数据(名称/描述/语言/分支/fork)聚类 + 代表性 README 核对,逐条保留出处;数量为归纳近似值,清单随组织演进,以当前组织页为准。

## 识别速查表(命名约定 → 含义)

| 命名特征 | 含义 | 层 |
| --- | --- | --- |
| `hobot-xxx`(连字符) | BSP / 系统源码组件 | 系统/BSP |
| `hobot_xxx`(下划线) | TROS / ROS2 应用功能包 | 应用 |
| 无前缀(`hobot-*`/`rdk-gen`/`manifest`) | **RDK X3** 板 | — |
| `x5-` 前缀 | RDK X5 板 | — |
| `s100-` 前缀 | RDK S100 / S100P 板 | — |
| `j5-` 前缀 | J5(征程 Journey 5,车载/自动驾驶 SoC)板[^j5] | — |
| `tros_xxx` | TROS 工具 / 编排 / 发布 | 中间件 |
| `nodehub_xxx` | NodeHub 应用打包(deb 上架) | 应用分发 |
| `magicbox_xxx` | MagicBox 硬件产品配套 | 产品 |
| `xxx_doc` / `xxx-doc` | 文档源码 | 文档 |
| `rcl`/`rclcpp`/`rmw_*`/`rosbag2`/`ament_*`/`vision_opencv`/`isaac_*` | ROS2 上游移植(非原创) | 中间件 |
| `mono*`/`stereo*`/`face_*`/`hand_*`/`parking_*`/`*_cam` | 视觉/感知应用 | 应用 |

## 12 类家族

### 1. 系统 / BSP(~94)
内核与板级支持包,经 `repo`+`manifest`+`*-rdk-gen` 编进 OS 镜像。
- 构建入口:`rdk-gen`(X3)/`x5-rdk-gen`/`s100-rdk-gen`/`j5-rdk-gen`;清单:`manifest`/`x5-manifest`/`j5-manifest`。
- 注:**RDK S600**(S 系列新板,Nash BPU 560 TOPS,系统 Ubuntu 24.04/ROS2 Jazzy)截至目前**未见 `s600-` 前缀的 BSP/构建仓开源**;应用层适配已铺开(`hobot_dnn`/`hobot_bev`/`openpi_runtime` 等多仓已标注 S600 + Jazzy)。
- 底层:`kernel`/`x5-kernel`/`x5-kernel-rt`/`uboot`/`x5-uboot`/`bootloader`/`x5-bootloader`/`s100-bootloader`。
- BSP 组件(每板一套):`hobot-boot`/`-camera`/`-multimedia`/`-multimedia-dev`/`-dnn`/`-bpu-drivers`/`-dtb`/`-wifi`/`-io`/`-utils`/`-display`/`-spdev`/`-miniboot`/`-kernel-headers`/`-configs`/`-audio-config`,以及 `x5-hobot-*`、`s100-hobot-*` 同名集合。
- 摄像头底层:`x5-libcam-sensor`/`x5-libcam-inc`/`x5-drv-camsys`。
- 详见 [os-image-build](os-image-build.md)。

### 2. TROS / ROS2 核心移植(~14)
ROS2 上游同名仓的 RDK 移植/适配,**不是 RDK 原创算法**:`rcl`/`rclcpp`/`rcl_interfaces`/`rmw_cyclonedds`/`ament_package`/`rosbag2`/`rosbag2-foxy`/`tinyxml_vendor`/`vision_opencv`/`livox_ros_driver2`/`rviz_2d_overlay_plugins`/`isaac_*`。

### 3. TROS 工具 / 编排(~16)
`tros_*`:`tros_release`(发布)/`robot_dev_config`(TROS 编译入口)/`tros_demos`/`tros_nav_docking`/`tros_nav_workflow`/`tros_bridge_grpc`/`tros_perception_fusion`/`tros_runtime_stats`/`tros_websocket_interaction`/`tros_gnss` 等。

### 4. 感知 / 视觉应用包(~95,最大)
`hobot_*` 下划线 + 算法命名仓。检测/分割/姿态/双目/SLAM/标定/外设:
- 检测分割:`hobot_yolo_world`/`hobot_dosod`/`mono2d_body_detection`/`mono2d_yolo_pose`/`mono3d_indoor_detection`/`hobot_centerpoint`/`hobot_bev`。
- 双目深度:`hobot_stereonet`(+`_utils`)/`DStereo*`/`dstereo_occnet`/`elevation_net`。
- SLAM/点云:`orb_slam3`/`rtabmap(_ros)`/`pointcloud_*`。
- 人脸/手:`face_*`/`hand_*`/`palm_detection_mediapipe`/`reid`/`insightface_runtime`。
- 外设/相机:`hobot_usb_cam`/`hobot_mipi_cam`/`hobot_zed_cam`/`hobot_rgbd_cam`/`hobot_codec`/`hobot_cv`/`hobot_websocket`/`hobot_imu_sensor`/`rdk_imu`。
- 基础:`hobot_dnn`(dnn_node)/`hobot_msgs`/`hobot_shm`/`hobot_sensors`。

### 5. Model Zoo(5)
`rdk_model_zoo`(X5 主)/`rdk_model_zoo_s`(S)/`model_zoo`/`ai_toolchain_models`/`hobot_model`。→ skill `rdk-model-zoo`。

### 6. NodeHub 打包(9)
`nodehub_*`:把 TROS 应用打成 deb 上架 NodeHub 应用中心,README 通常只引 TROS 文档与实现仓。如 `nodehub_yolov8_object_detection`/`nodehub_hobot_clip`/`nodehub-x5-rdkmodelzoo-samples`。

### 7. 具身智能(~10)
`rdk_LeRobot_tools`/`lerobot`/`openpi`/`openpi_runtime`/`RoboTwin`/`embodied_ai_robots`/`Alicia-D-SDK`/`object_graspnet`/`xr_robot`。→ skill `rdk-embodied-lerobot`。

### 8. 端侧 LLM / 语音(~20)
`hobot_llamacpp`/`hobot_llm`/`hobot_xlm`/`hobot_gpt`/`hobot_chatbot`/`oellm_server`/`llama.cpp`/`PTQ_InternVL2`/`PTQ_MiniCPM`/`hobot_clip`/`sensevoice_ros2`/`hobot_tts`/`hobot_audio`/`xiaozhi-in-rdk`/`companion_agent`。→ skill `rdk-llm-deployment`。

### 9. MagicBox 产品(6)
`magicbox_lighting_control`/`magicbox_audio_io`/`magicbox_servo_control`/`magicbox_mipi_cam`/`magicbox_gesture_interaction`/`magicbox_qwen_llm`——某具体硬件产品(MagicBox)的配套包。

### 10. 文档(12)
`rdk_doc`(主文档源,16★)/`rdk_s_doc`/`rdk_x_doc`/`tros_doc`/`tros_vims_doc`/`model_zoo_doc`/`rdk_studio_doc`/`rdk_doc_center`/`case_doc`/`accessories_doc`/`magicbox_doc`/`DRobotics_SoC_Technology`。

### 11. 镜像 / 工具链辅助(数个)
`system_download`(镜像下载清单)/`ai_toolchain_models`/`sysroot_docker(_noble)`/`cross_compile`/`ros2_crosscompile_w_sdk`/`trosdep`/`x5-tuning-json`/`x5-factorytest`。

### 12. 其它 / 课程 / 内部(数十)
`device-knowledge`(本仓)/`moss`(agent 架构层)/`rdk-course-demos`/`rdk_studio_examples`/`rdk-studio-private-ci`/`coding-skills`/`d-robotics-recruit`/`benchmark`/`drobotics_tools`/`line_follower` 等示例与内部工具。

## 跨平台/独立仓提醒

- `lerobot`/`openpi` 是上游项目的 D-Robotics fork(README 标注 BPU 适配),不是从零原创。
- ROS2 核心移植仓(家族 2)出问题时,先核对 ROS2 上游行为,而非默认 RDK 改动引入。
- 同一能力可能同时存在 BSP 库(连字符)与 ROS 包(下划线)两份,**定位时先确定你要的是底层库还是 ROS 节点**。

[^j5]: J5 = 征程 Journey 5(面向自动驾驶 AUTO 领域的车载 SoC);前缀→板映射成立,但 `j5-rdk-gen` 等构建仓 README 为通用模板、不含 J5 字样,产品归属出处见官方开发者站「征程 Journey5 简介」(developer.d-robotics.cc J5 OpenExplorer 文档)。
