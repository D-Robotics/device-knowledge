# RDK 官方文档全量主题 → 位置索引

> 来源:核对 D-Robotics 六个文档仓(`rdk_x_doc` / `rdk_s_doc` / `tros_doc` / `model_zoo_doc` / `rdk_studio_doc` / `accessories_doc`,默认分支 `main`)的 `git/trees` 目录树 + `docusaurus.config.js`,并对代表性 URL 在 developer.d-robotics.cc 实测验证;逐条保留出处。URL 推导规则与例外见 [SKILL.md](../SKILL.md)。文档随版本演进,以站点实际页面为准;标 ⚠️ 的条目为按规则推导未逐一实测,使用前可 `web_fetch` 核对。

**站点根**:
- X 系列 `https://developer.d-robotics.cc/rdk_x_doc/`
- S 系列 `https://developer.d-robotics.cc/rdk_s_doc/`
- TROS `https://developer.d-robotics.cc/tros_doc/`
- Model Zoo `https://developer.d-robotics.cc/model_zoo_doc/`
- RDK Studio `https://developer.d-robotics.cc/rdk_studio_doc/`
- 配件 `https://developer.d-robotics.cc/accessories_doc/`(见末尾"配件"小节的部署说明)

X 系列走 `rdk_x_doc`,S 系列走 `rdk_s_doc`,TROS 走 `tros_doc`,Studio 走 `rdk_studio_doc`——每条已标清覆盖板与归属站。

---

## 一、快速上手(Quick Start)

| 主题 | 位置 | 覆盖板 |
| --- | --- | --- |
| [RDK X5 硬件介绍](https://developer.d-robotics.cc/rdk_x_doc/Quick_start/hardware_introduction/rdk_x5) | rdk_x_doc | X5 ✅实测 |
| [RDK X3 硬件介绍](https://developer.d-robotics.cc/rdk_x_doc/Quick_start/hardware_introduction/rdk_x3) | rdk_x_doc | X3 ⚠️ |
| [RDK Ultra 硬件介绍](https://developer.d-robotics.cc/rdk_x_doc/Quick_start/hardware_introduction/rdk_ultra)（路径在 `docs/01_Quick_start/hardware_introduction/rdk_ultra.md`，X 仓内）⚠️ | rdk_x_doc | Ultra |
| [RDK S100 开发者套件介绍](https://developer.d-robotics.cc/rdk_s_doc/01_Quick_start/01_hardware_introduction/01_rdk_s100/01_rdk_s100_kit)（自定义 slug，保留序号）✅实测 | rdk_s_doc | S100/S100P |
| RDK S600 硬件介绍 — 源 `rdk_s_doc:docs/01_Quick_start/01_hardware_introduction/02_rdk_s600/01_rdk_s600.md`（自定义 slug，查 frontmatter）⚠️ | rdk_s_doc | S600 |
| [X3 系统烧录](https://developer.d-robotics.cc/rdk_x_doc/Quick_start/install_os/rdk_x3/system_burn)（源 `install_os/rdk_x3/01_system_burn.md`）⚠️ | rdk_x_doc | X3 |
| [X5 系统烧录](https://developer.d-robotics.cc/rdk_x_doc/Quick_start/install_os/rdk_x5/system_burn)⚠️ | rdk_x_doc | X5 |
| S100 系统烧录(xburn,分 Win/Linux/Mac) — 源 `rdk_s_doc:docs/01_Quick_start/02_install_os/rdk_s100/03_xburn/*.md`⚠️ | rdk_s_doc | S100 |
| S600 系统烧录(xburn) — 源 `rdk_s_doc:docs/01_Quick_start/02_install_os/rdk_s600/03_xburn/*.md`⚠️ | rdk_s_doc | S600 |
| [远程登录(SSH/串口)X](https://developer.d-robotics.cc/rdk_x_doc/Quick_start/remote_login)⚠️ / [S](https://developer.d-robotics.cc/rdk_s_doc/Quick_start/remote_login)⚠️ | rdk_x_doc / rdk_s_doc | X / S |
| 开机配置向导 — X `Quick_start/configuration_wizard`⚠️;S `rdk_s_doc:docs/01_Quick_start/03_configuration_wizard/configuration_wizard_s100|s600.md`⚠️ | rdk_x_doc / rdk_s_doc | X / S100·S600 |
| RDK Studio 入门(板侧文档内)— X `Quick_start/rdk_studio`⚠️;S 同名⚠️ | rdk_x_doc / rdk_s_doc | X / S |
| 镜像下载清单 — X `Quick_start/download`⚠️;S 同名⚠️ | rdk_x_doc / rdk_s_doc | X / S |

## 二、系统配置(System Configuration)

| 主题 | 位置 | 覆盖板 |
| --- | --- | --- |
| [网络/蓝牙配置 X](https://developer.d-robotics.cc/rdk_x_doc/System_configuration/network_blueteeth)⚠️ | rdk_x_doc | X |
| S 网络/蓝牙 — `rdk_s_doc:docs/02_System_configuration/01_network_bluetooth.md` → `System_configuration/network_bluetooth`⚠️ | rdk_s_doc | S |
| srpi-config 配置工具 — `System_configuration/srpi-config`(X/S 各一)⚠️ | rdk_x_doc / rdk_s_doc | X / S |
| config.txt 启动配置 — `System_configuration/config_txt`⚠️ | rdk_x_doc / rdk_s_doc | X / S |
| 频率/散热管理 — `System_configuration/frequency_management`⚠️ | rdk_x_doc / rdk_s_doc | X / S |
| 开机自启 — `System_configuration/self_start`⚠️ | rdk_x_doc / rdk_s_doc | X / S |
| GUI 网络配置(S 独有)— `rdk_s_doc:.../06_gui_network_config.md` → `System_configuration/gui_network_config`⚠️ | rdk_s_doc | S |
| 文件共享工具(S 独有)— `rdk_s_doc:.../07_share_file_tool.md` → `System_configuration/share_file_tool`⚠️ | rdk_s_doc | S |

## 三、40pin 外设(GPIO/I2C/SPI/UART/PWM)

| 主题 | 位置 | 覆盖板 |
| --- | --- | --- |
| [40pin 管脚定义 X](https://developer.d-robotics.cc/rdk_x_doc/Basic_Application/40pin_user_sample/40pin_define)⚠️ | rdk_x_doc | X |
| [GPIO 应用 X](https://developer.d-robotics.cc/rdk_x_doc/Basic_Application/40pin_user_sample/gpio) ✅实测 | rdk_x_doc | X |
| [I2C X](https://developer.d-robotics.cc/rdk_x_doc/Basic_Application/40pin_user_sample/i2c)⚠️ / [SPI](https://developer.d-robotics.cc/rdk_x_doc/Basic_Application/40pin_user_sample/spi)⚠️ / [UART](https://developer.d-robotics.cc/rdk_x_doc/Basic_Application/40pin_user_sample/uart)⚠️ / [PWM](https://developer.d-robotics.cc/rdk_x_doc/Basic_Application/40pin_user_sample/pwm)⚠️ | rdk_x_doc | X |
| S100 40pin(define/gpio/pwm/uart/i2c/spi)— 源 `rdk_s_doc:docs/03_Basic_Application/03_40pin_user_guide/01_s100/*.md`;含嵌套 `01_s100` 子目录,**实测站点 slug 待逐一确认**,先给源路径 + S 站根⚠️ | rdk_s_doc | S100 |
| S600 40pin(ext_io/gpio/uart/spi)— 源 `rdk_s_doc:docs/03_Basic_Application/03_40pin_user_guide/02_s600/*.md`⚠️ | rdk_s_doc | S600 |

## 四、视觉 / 相机(Image / Vision)

| 主题 | 位置 | 覆盖板 |
| --- | --- | --- |
| MIPI 摄像头 X — `rdk_x_doc:docs/03_Basic_Application/04_vision/RDK_X3|RDK_X5/mipi_camera.md` → `Basic_Application/vision/RDK_X5/mipi_camera`⚠️ | rdk_x_doc | X3/X5 |
| USB 摄像头 X — 同上目录 `usb_camera`⚠️ | rdk_x_doc | X3/X5 |
| [S MIPI 摄像头](https://developer.d-robotics.cc/rdk_s_doc/Basic_Application/Image/mipi_camera) ✅实测 | rdk_s_doc | S100/S600 |
| [S USB 摄像头](https://developer.d-robotics.cc/rdk_s_doc/Basic_Application/Image/usb_camera)⚠️ | rdk_s_doc | S100/S600 |
| Python 视觉样例(分类/检测/分割/姿态/USB/MIPI/Web 推流)— `rdk_x_doc:docs/03_Basic_Application/03_pydev_demo_sample/RDK_X5/*` → `Basic_Application/pydev_demo_sample/RDK_X5/...`⚠️ | rdk_x_doc | X3/X5 |
| C 视觉样例(vio2display / rtsp2display / vio_capture 等)— `rdk_x_doc:docs/03_Basic_Application/02_cdev_demo_sample/*` → `Basic_Application/cdev_demo_sample/...`⚠️ | rdk_x_doc | X |

## 五、音频(Audio)

| 主题 | 位置 | 覆盖板 |
| --- | --- | --- |
| X5 板载 ES8326 / WM8960 HAT / Hiwonder 音频 — `rdk_x_doc:docs/03_Basic_Application/05_audio/rdk_x5/*.md` → `Basic_Application/audio/rdk_x5/in_board_es8326` 等⚠️ | rdk_x_doc | X5 |
| X3 音频(WM8960 / audio_driver_hat2)— `rdk_x_doc:.../05_audio/rdk_x3_and_rdk_x3_module/*.md`⚠️ | rdk_x_doc | X3 |
| S 音频扩展板 — `rdk_s_doc:docs/03_Basic_Application/02_audio/01_audio_board_super.md` → `Basic_Application/audio/audio_board_super`⚠️ | rdk_s_doc | S100/S600 |

## 六、多媒体(VPU/编解码/ISP/VIO)

| 主题 | 位置 | 覆盖板 |
| --- | --- | --- |
| X 多媒体 sp API(BPU/编码/解码/显示/VIO,Python+C)— `rdk_x_doc:docs/03_Basic_Application/06_multi_media_sp_dev_api/RDK_X5/...` → `Basic_Application/multi_media_sp_dev_api/RDK_X5/...`⚠️ | rdk_x_doc | X3/X5 |
| S 多媒体 API(cdev/pydev:decoder/display/encoder/sys/vio)— `rdk_s_doc:docs/03_Basic_Application/04_multi_media/multi_media_api/...` → `Basic_Application/multi_media/multi_media_api/...`⚠️ | rdk_s_doc | S100/S600 |
| X 高级多媒体开发(video_input/encode/decode/ISP/region/system_control)— `rdk_x_doc:docs/07_Advanced_development/03_multimedia_development/*` → `Advanced_development/multimedia_development/...`⚠️ | rdk_x_doc | X |
| S 高级多媒体(camsys/camera_bringup/codec/display/camerasync + 应用样例 vin/isp/pym/gdc/codec)— `rdk_s_doc:docs/07_Advanced_development/03_multimedia_development/...`⚠️ | rdk_s_doc | S100/S600 |

## 七、算法 / Model Zoo

| 主题 | 位置 | 覆盖板 |
| --- | --- | --- |
| [Model Zoo 简介](https://developer.d-robotics.cc/model_zoo_doc/model_zoo_intro)⚠️ | model_zoo_doc | 全板 |
| [RDK X5 Model Zoo 使用说明](https://developer.d-robotics.cc/model_zoo_doc/rdk_x5_guide) ✅实测 | model_zoo_doc | X5 |
| [RDK X3 guide](https://developer.d-robotics.cc/model_zoo_doc/rdk_x3_guide)⚠️ / [RDK S guide](https://developer.d-robotics.cc/model_zoo_doc/rdk_s_guide)⚠️ | model_zoo_doc | X3 / S |
| [推理 API 参考](https://developer.d-robotics.cc/model_zoo_doc/infer_api_ref)⚠️ | model_zoo_doc | 全板 |
| 各板模型清单(分类/检测/实例分割/姿态/OCR/深度/抠图/LLM)— `model_zoo_doc:docs/appendix/rdk_x5|rdk_x3|rdk_s100|rdk_s600/*.md` → `appendix/rdk_x5/02_object_detection` 等⚠️ | model_zoo_doc | X3/X5/S100/S600 |
| 板上 Python/C++ 算法样例(ResNet18/MobileNetV2/YOLOv5x/YOLO11/seg/pose/LaneNet/ASR/PaddleOCR)— `rdk_s_doc:docs/04_Algorithm_Application/03_Python_Sample|04_C++_Sample/*` → `Algorithm_Application/Python_Sample/...`⚠️ | rdk_s_doc | S100/S600 |

## 八、机器人开发 TROS / ROS2(走 tros_doc)

| 主题 | 位置 | 覆盖板 |
| --- | --- | --- |
| TROS 安装 / 环境准备 / Hello World / ros_pkg / 交叉编译 — `tros_doc:docs/01_quick_start/*` → `quick_start/install_tros` 等⚠️ | tros_doc | 跨板 |
| quick demo(传感器/通信/CV/渲染/工具/codec/tts)— `tros_doc:docs/02_quick_demo/*` → `quick_demo/demo_sensor` 等⚠️ | tros_doc | 跨板 |
| [YOLO 目标检测(boxs)](https://developer.d-robotics.cc/tros_doc/boxs/detection/yolo) ✅实测 | tros_doc | 跨板 |
| DOSOD 开放词汇 / YOLO-World — `tros_doc:docs/03_boxs/detection/hobot_dosod|hobot_yolo_world.md` → `boxs/detection/hobot_dosod`⚠️ | tros_doc | 跨板 |
| 人体/手势/人脸/ReID(body)— `tros_doc:docs/03_boxs/body/*` → `boxs/body/mono2d_body_detection` 等⚠️ | tros_doc | 跨板 |
| 双目/VIO/3D(spatial:hobot_stereonet/hobot_vio/elevation_net/mono3d)— `tros_doc:docs/03_boxs/spatial/*` → `boxs/spatial/hobot_stereonet`⚠️ | tros_doc | 跨板 |
| 端侧生成式(hobot_llamacpp / hobot_llm / hobot_xlm)— `tros_doc:docs/03_boxs/generate/*` → `boxs/generate/hobot_llm`⚠️ | tros_doc | 跨板 |
| 语音(hobot_audio / sensevoice_ros2)— `tros_doc:docs/03_boxs/audio/*` → `boxs/audio/hobot_audio`⚠️ | tros_doc | 跨板 |
| 应用:Nav2 导航 / SLAM / 小车跟随 / 跌倒检测 — `tros_doc:docs/04_apps/*` → `apps/navigation2`、`apps/slam`⚠️ | tros_doc | 跨板 |
| TROS 开发进阶(zero_copy / flame_graph / breakpad / ai_predict)— `tros_doc:docs/05_tros_dev/*` → `tros_dev/zero_copy`⚠️ | tros_doc | 跨板 |

> 注:同名 boxs/apps 内容在旧 `rdk_doc` 第 5 章(`docs/05_Robot_development/...`)也有归档副本;新出处一律用 **tros_doc**。

## 九、工具链(BPU 量化/编译)

| 主题 | 位置 | 覆盖板 |
| --- | --- | --- |
| X 工具链总览 — `rdk_x_doc:docs/07_Advanced_development/04_toolchain_development/overview.md` → `Advanced_development/toolchain_development/overview`⚠️ | rdk_x_doc | X |
| X 工具链 expert(quick_start/user_guide/api_reference/environment_config)— `.../04_toolchain_development/expert/*` → `Advanced_development/toolchain_development/expert/quick_start`⚠️ | rdk_x_doc | X |
| X 工具链 intermediate(PTQ/runtime_sample/supported_op_list)— `.../04_toolchain_development/intermediate/*`⚠️ | rdk_x_doc | X |
| S 工具链总览 / LLM 工具链 — `rdk_s_doc:docs/07_Advanced_development/04_toolchain_development/01_algorithm_toolchain/01_overview.md`(注意有嵌套 `01_algorithm_toolchain/` 一层)与 `02_LLM_Toolchain/` → `Advanced_development/toolchain_development/algorithm_toolchain/overview` 等⚠️ | rdk_s_doc | S100/S600 |

## 十、Linux 高级开发(驱动/内核/硬件测试)与 MCU(S 独有)

| 主题 | 位置 | 覆盖板 |
| --- | --- | --- |
| X 驱动开发(GPIO/I2C/SPI/UART/PWM/pinctrl/thermal/RTC/watchdog 等)— `rdk_x_doc:docs/07_Advanced_development/02_linux_development/driver_development[_x5]/*` → `Advanced_development/linux_development/driver_development/driver_gpio_dev`⚠️ | rdk_x_doc | X3/X5 |
| X 实时内核 / 内核头 / 环境搭建 / 硬件单元测试 — `.../02_linux_development/{realtime_kernel,kernel_headers,environment_build,hardware_unit_test/*}`⚠️ | rdk_x_doc | X |
| X 硬件开发(原理图/接口/相机/显示/CAN/POE/V4l2)— `rdk_x_doc:docs/07_Advanced_development/01_hardware_development/rdk_x5/*` → `Advanced_development/hardware_development/rdk_x5/hardware`⚠️ | rdk_x_doc | X3/X5/Ultra |
| S 驱动开发(uart/i2c/gpio/pinctrl/ipc/spi/pwm/thermal/lowpower/audio/timesync/wifi/rtc)— `rdk_s_doc:docs/07_Advanced_development/02_linux_development/04_driver_development_super/*` → `Advanced_development/linux_development/driver_development_super/driver_gpio_dev`⚠️ | rdk_s_doc | S100/S600 |
| **S PCIe**(hw_guide/sw_arch/sw_setup/libhbpciehal)— `.../04_driver_development_super/13_driver_pcie/*` → `.../driver_development_super/driver_pcie/s100x_pcie_hw_guide`⚠️ | rdk_s_doc | S100/S600 |
| **S hbmem**(introduce/hardware/software/debug/FAQ)— `.../04_driver_development_super/15_driver_hbmem/*` → `.../driver_development_super/driver_hbmem/s100_hbmem_introduce`⚠️ | rdk_s_doc | S100/S600 |
| **S EtherCAT / 以太网驱动** — `.../04_driver_development_super/16_driver_ethernet/02_ethercat.md` → `.../driver_development_super/driver_ethernet/ethercat`⚠️ | rdk_s_doc | S100/S600 |
| **S OTA**(system/miniboot)— `.../06_OTA/*` → `Advanced_development/linux_development/OTA/ota_system`⚠️ | rdk_s_doc | S100/S600 |
| **S VDSP 开发** — `rdk_s_doc:docs/07_Advanced_development/07_vdsp_development.md` → `Advanced_development/vdsp_development`⚠️ | rdk_s_doc | S100/S600 |
| **S MCU 开发**(IPC 实测见下,另含 build_system/FreeRTOS/uart/pwm/spi/adc/can/i2c/eth/ramdump/ICU/mcu_port)— `rdk_s_doc:docs/07_Advanced_development/05_mcu_development/*` | rdk_s_doc | S100/S600 |
| [S MCU IPC 使用指南](https://developer.d-robotics.cc/rdk_s_doc/Advanced_development/mcu_development/mcu_ipc) ✅实测 | rdk_s_doc | S100/S600 |
| S 板级 bringup(S100/S600)— `rdk_s_doc:docs/07_Advanced_development/01_hardware_development/03_rdk_s100_board_bringup.md` → `Advanced_development/hardware_development/rdk_s100_board_bringup`⚠️ | rdk_s_doc | S100/S600 |

## 十一、应用案例

| 主题 | 位置 | 覆盖板 |
| --- | --- | --- |
| AMR / 巡线小车 — `rdk_x_doc:docs/06_Application_case/{amr,line_follower}.md` → `Application_case/amr`⚠️ | rdk_x_doc | X |
| S 应用案例入口 — `rdk_s_doc:docs/06_Application_case/01_intro.md` → `Application_case/intro`⚠️ | rdk_s_doc | S |

## 十二、FAQ

| 主题 | 位置 | 覆盖板 |
| --- | --- | --- |
| X FAQ(硬件系统/接口/应用样例/多媒体/工具链/TROS/桌面应用)— `rdk_x_doc:docs/08_FAQ/*.md` → `FAQ/hardware_and_system` 等(源文件名 `01_hardware_and_system.md`)⚠️ | rdk_x_doc | X |
| S 上手 FAQ — `rdk_s_doc:docs/01_Quick_start/03_FAQ.md` 与 install_os 下 `05_FAQ.md`⚠️ | rdk_s_doc | S |
| 工具链 FAQ — 见第九节工具链各页内的 FAQ 段 | rdk_x_doc / rdk_s_doc | X / S |
| RDK Studio 客户端 FAQ — 见第十四节 | rdk_studio_doc | Studio |

## 十三、附录:命令手册 & 发布说明

| 主题 | 位置 | 覆盖板 |
| --- | --- | --- |
| Linux 命令手册(apt/dmesg/ssh/scp/top/ps/tar 等)— `rdk_x_doc:docs/09_Appendix/linux-command-manual/cmd_*.md` → `Appendix/linux-command-manual/cmd_ssh`⚠️ | rdk_x_doc | X |
| RDK 专有命令(hrut_somstatus / hrut_boardid / rdkos_info / devmem / rdk-miniboot-update / rdk-backup)— X `rdk_x_doc:docs/09_Appendix/rdk-command-manual/*`;S `rdk_s_doc:docs/09_Appendix/rdk-command-manual/*` → `Appendix/rdk-command-manual/cmd_hrut_somstatus`⚠️ | rdk_x_doc / rdk_s_doc | X / S |
| X 发布说明 — `rdk_x_doc:docs/...Release_Note/...` → `Release_Note/release_note`⚠️ | rdk_x_doc | X |
| S 发布说明 / Roadmap(v4.0.x 多版本)— `rdk_s_doc:docs/10_Release_Note/*.md` → `Release_Note/roadmap` 等⚠️ | rdk_s_doc | S100/S600 |

## 十四、RDK Studio 桌面客户端(走 rdk_studio_doc,路径用连字符)

> 注:Studio 站目录用 `NN-xxx`(连字符序号),去前缀后段名也是连字符,如 `2-quick-start/1-install-and-login.md` → `quick-start/install-and-login`。

| 主题 | 位置 |
| --- | --- |
| 产品介绍 / 架构 / 功能矩阵 / 支持硬件 / 版本说明 — `docs/1-product-intro/*` → `product-intro/overview` 等⚠️ |
| [安装与登录](https://developer.d-robotics.cc/rdk_studio_doc/quick-start/install-and-login) ✅实测 |
| 快速上手:烧录系统 / 连设备(TypeC/SSH/串口)/ 配网 / 配 AI 模型 / 首次对话 — `docs/2-quick-start/*`⚠️ |
| 工作台 / AI 对话 / 远程终端 / 文件管理 / 远程 IDE / 远程桌面 / 系统烧录 / 网络配置 / 设备管理 — `docs/3-user-guide/*`⚠️ |
| **OpenClaw**(概览/部署卸载/主面板/与 dMoss 协作/任务委派/配对安全)— `docs/3-user-guide/10-openclaw/*` → `user-guide/openclaw/overview`⚠️ |
| **Skill**(SKILL.md 结构/内置 skill/ClawHub 社区/创建导入/触发匹配/同步到板)— `docs/3-user-guide/11-skill/*` → `user-guide/skill/skill-md-structure`⚠️ |
| 本地模型 / 飞书·微信 渠道 / 配置中心 / 监控(任务队列·token)/ CLI(rdkstudio·dmoss-agent)— `docs/3-user-guide/{12,13,14,15}-*`⚠️ |
| 资源:分享/获取 Skill、NodeHub 案例 — `docs/4-resources/*` → `resources/get-skills`⚠️ |
| [FAQ:.hbm 模型无法加载](https://developer.d-robotics.cc/rdk_studio_doc/faq/hbm-not-found) ✅实测 |
| FAQ 其它(AI 无响应/SSH 失败/TypeC 烧录失败/相机无画面/OpenClaw 安装失败/配网失败/IDE 失败/多设备/token 异常/模型质量/VNC/本地 LLM/串口空)— `docs/5-faq/*.md` → `faq/ssh-failed` 等⚠️ |

## 十五、官方配件(accessories_doc)

> ⚠️ 部署说明:`accessories_doc` 的 `docusaurus.config.js` 配置 `url: developer.d-robotics.cc` + `baseUrl: /accessories_doc/`,但实测该站点根在 developer.d-robotics.cc 上暂未生效(返 404),可能尚未迁入新资料中心或走独立 GitHub Pages。**当前优先给 GitHub 源链接**,站点 URL 待官方上线后核对。

| 主题 | GitHub 源(D-Robotics/accessories_doc,main) |
| --- | --- |
| 配件总览 | `docs/01_accessories.md`(slug `/accessories`) |
| 双目相机 GS130W(简介/安装/快速上手/硬件/软件/下载) | `docs/01_stereo_camera_gs130w/*.md` |
| 双目相机 GS130WI | `docs/02_stereo_camera_gs130wi/*.md` |
| IMU 模组(简介/安装/快速上手/硬件/软件:C API·Python API·ROS2·IIO/下载) | `docs/03_imu_module/*.md`,软件子页在 `03_imu_module/05_software/*.md` |

> X5 板侧 IMU/IMU 模组使用也有一份在 `rdk_x_doc:docs/03_Basic_Application/07_accessory_instructions/rdk_x5/imu/{icm42688,rdk_imu_module}.md`(→ `Basic_Application/accessory_instructions/rdk_x5/imu/icm42688`⚠️)。
