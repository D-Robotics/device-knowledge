# RDK 官方资料导航

> 来源:整理自 D-Robotics RDK 官方文档、工具链与社区实践,逐条保留出处链接;由 device-knowledge 知识库忠实转换而来,未改写技术事实。

按主题分组的官方文档/资料索引,可配合 web_fetch 核对最新版本。

> **文档站已拆分(2026-06)**:官方把合并仓 `rdk_doc` 拆成独立站——X 系列 → `rdk_x_doc`、S 系列 → `rdk_s_doc`、TROS → `tros_doc`、Model Zoo → `model_zoo_doc`、RDK Studio → `rdk_studio_doc`、配件 → `accessories_doc`。下面的 `developer.d-robotics.cc/rdk_doc/...` 链接仍可访问(顶部带"已迁移"横幅)。**要按问题精准定位到新站的哪一章/给权威 URL,用 skill `rdk-doc-finder`(含全量主题→URL 索引与 URL 推导规则)。**

## getting-started

- [RDK X5 快速上手](https://developer.d-robotics.cc/rdk_doc/Quick_start/hardware_introduction/rdk_x5)
- [RDK X3 快速上手](https://developer.d-robotics.cc/rdk_doc/Quick_start/hardware_introduction/rdk_x3)
- [RDK Ultra 快速上手](https://developer.d-robotics.cc/rdk_doc/Quick_start/hardware_introduction/rdk_ultra)
- [S100 快速上手](https://developer.d-robotics.cc/rdk_doc/rdk_s/Quick_start/hardware_introduction/rdk_s100)
- [X3 系统镜像烧录](https://developer.d-robotics.cc/rdk_doc/Quick_start/install_os/rdk_x3)
- [X5 系统镜像烧录](https://developer.d-robotics.cc/rdk_doc/Quick_start/install_os/rdk_x5)
- [S100 系统镜像烧录](https://developer.d-robotics.cc/rdk_doc/rdk_s/Quick_start/install_os/rdk_s100)
- [网络配置（有线/WiFi/蓝牙）](https://developer.d-robotics.cc/rdk_doc/System_configuration/network_blueteeth)
- [远程登录（SSH/串口）](https://developer.d-robotics.cc/rdk_doc/Quick_start/remote_login)

## studio

- [RDK Studio 设备管理](https://developer.d-robotics.cc/rdk_doc/Quick_start/RDK_Studio/Device_management/hardware_resource)
- [RDK Studio 烧录系统](https://developer.d-robotics.cc/rdk_doc/Quick_start/RDK_Studio/flashing)
- [RDK Studio 集成工具](https://developer.d-robotics.cc/rdk_doc/Quick_start/RDK_Studio/Device_management/integration_tools)
- [RDK Studio OpenClaw 配置](https://developer.d-robotics.cc/rdk_doc/Quick_start/RDK_Studio/openclaw/config_openclaw)
- [RDK Studio NodeHub](https://developer.d-robotics.cc/rdk_doc/Quick_start/RDK_Studio/nodehub)

## vision

- [USB 摄像头使用（hobot_usb_cam）](https://developer.d-robotics.cc/rdk_doc/Basic_Application/vision/usb_camera)
- [MIPI 摄像头使用](https://developer.d-robotics.cc/rdk_doc/Basic_Application/vision/mipi_camera)
- [YOLO 目标检测](https://developer.d-robotics.cc/rdk_doc/Basic_Application/pydev_demo_sample/yolov5_sample)
- [人体检测与姿态估计](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/body/mono2d_body_detection)
- [DOSOD 开放词汇检测](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/detection/hobot_dosod)
- [图像分类](https://developer.d-robotics.cc/rdk_doc/Basic_Application/pydev_demo_sample/basic_sample)
- [语义分割](https://developer.d-robotics.cc/rdk_doc/Basic_Application/pydev_demo_sample/segment_sample)
- [Web 可视化推流](https://developer.d-robotics.cc/rdk_doc/Basic_Application/pydev_demo_sample/web_display_camera_sample)
- [视觉SLAM与建图](https://developer.d-robotics.cc/rdk_doc/Robot_development/apps/slam)
- [StereoNet 双目深度估计](https://github.com/D-Robotics/hobot_stereonet)
- [OpenCV 加速绑定（hobot_cv）](https://github.com/D-Robotics/hobot_cv)

## ros

- [TROS 安装与环境配置](https://developer.d-robotics.cc/rdk_doc/Robot_development/quick_start/install_tros)
- [TROS 环境准备](https://developer.d-robotics.cc/rdk_doc/Robot_development/quick_start/preparation)
- [TROS Hello World](https://developer.d-robotics.cc/rdk_doc/Robot_development/quick_start/hello_world)
- [ROS2 package 使用](https://developer.d-robotics.cc/rdk_doc/Robot_development/quick_start/ros_pkg)
- [传感器数据采集](https://developer.d-robotics.cc/rdk_doc/Robot_development/quick_demo/demo_sensor)
- [Livox 激光雷达 ROS2 驱动](https://github.com/D-Robotics/livox_ros_driver2)
- [Nav2 导航部署](https://developer.d-robotics.cc/rdk_doc/Robot_development/apps/navigation2)
- [TROS 编译入口（robot_dev_config）](https://github.com/D-Robotics/robot_dev_config)
- [rosbag2 (D-Robotics fork)](https://github.com/D-Robotics/rosbag2)

## toolchain

- [BPU 工具链概述](https://developer.d-robotics.cc/rdk_doc/Advanced_development/toolchain_development/overview)
- [工具链快速上手](https://developer.d-robotics.cc/rdk_doc/Advanced_development/toolchain_development/expert/quick_start)
- [工具链开发指南](https://developer.d-robotics.cc/rdk_doc/Advanced_development/toolchain_development/expert/user_guide)
- [工具链 API 手册](https://developer.d-robotics.cc/rdk_doc/Advanced_development/toolchain_development/expert/api_reference)
- [工具链 FAQ](https://developer.d-robotics.cc/rdk_doc/FAQ/toolchain)

## llm

- [端侧大模型部署 (LLM)](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/generate/hobot_llm)
- [S100 端侧大模型部署 (LLM)](https://developer.d-robotics.cc/rdk_doc/rdk_s/Robot_development/boxs/generate/hobot_llm)
- [S100 文本图片特征检索](https://developer.d-robotics.cc/rdk_doc/rdk_s/Robot_development/boxs/function/hobot_clip)
- [TTS/ASR 语音](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/audio/hobot_audio)

## hardware

- [40pin 管脚定义](https://developer.d-robotics.cc/rdk_doc/Basic_Application/01_40pin_user_sample/40pin_define)
- [40pin GPIO 使用](https://developer.d-robotics.cc/rdk_doc/Basic_Application/01_40pin_user_sample/gpio)
- [I2C 接口使用](https://developer.d-robotics.cc/rdk_doc/Basic_Application/01_40pin_user_sample/i2c)
- [SPI 接口使用](https://developer.d-robotics.cc/rdk_doc/Basic_Application/01_40pin_user_sample/spi)
- [UART 串口通信](https://developer.d-robotics.cc/rdk_doc/Basic_Application/01_40pin_user_sample/uart)
- [PWM 输出控制](https://developer.d-robotics.cc/rdk_doc/Basic_Application/01_40pin_user_sample/pwm)
- [S100 MCU IPC](https://developer.d-robotics.cc/rdk_doc/rdk_s/Advanced_development/mcu_development/S100/mcu_ipc)
- [X5 板级 IO C 库（x5-hobot-io）](https://github.com/D-Robotics/x5-hobot-io)
- [X5 平台工具集（x5-hobot-utils）](https://github.com/D-Robotics/x5-hobot-utils)
- [X3 镜像构建（rdk-gen）](https://github.com/D-Robotics/rdk-gen)
- [X5 镜像构建（x5-rdk-gen）](https://github.com/D-Robotics/x5-rdk-gen)

## system

- [系统配置入口](https://developer.d-robotics.cc/rdk_doc/System_configuration)
- [系统更新与升级](https://developer.d-robotics.cc/rdk_doc/Release_Note/release_note)
- [S100 文件共享工具](https://developer.d-robotics.cc/rdk_doc/rdk_s/System_configuration/share_file_tool)
- [性能调优与散热](https://developer.d-robotics.cc/rdk_doc/System_configuration/frequency_management)
- [多媒体编解码](https://developer.d-robotics.cc/rdk_doc/Advanced_development/multimedia_development/overview)

## ecosystem

- [NodeHub 应用中心](https://developer.d-robotics.cc/en/nodehub)
- [开发者社区论坛](https://developer.d-robotics.cc/forum)
- [GitHub D-Robotics 仓库](https://github.com/D-Robotics)
- [Model Zoo (X3 · Bernoulli2 / X5 · Ultra · Bayes)](https://github.com/D-Robotics/rdk_model_zoo)
- [Model Zoo (S100/S100P · Nash)](https://github.com/D-Robotics/rdk_model_zoo_s)
- [RDK 文档源码](https://github.com/D-Robotics/rdk_doc)
- [系统镜像下载清单](https://github.com/D-Robotics/system_download)
