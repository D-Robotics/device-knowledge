---
name: rdk-source-map
description: 当用户在 D-Robotics GitHub 组织(约 226 个公开仓,组织共约 327 含私有)里需要定位/区分仓库时使用——看到某个仓不知道它是干嘛的/属于哪一层/对应哪块板、想知道"做某任务该去哪个仓"、分不清 hobot-(连字符)与 hobot_(下划线)、或要从源码构建 RDK OS 镜像/定制内核 BSP(repo/manifest/rdk-gen/vcstool 流程)。本 skill 是"仓库地图与源码导航";官方文档站章节定位走 rdk-doc-finder,板上跑现成模型走 rdk-model-zoo,ROS 节点用法走 rdk-ros,具身/LLM 落地走 rdk-embodied-lerobot / rdk-llm-deployment。
---

# D-Robotics GitHub 组织仓库地图

> 来源:基于 [github.com/D-Robotics](https://github.com/D-Robotics) 组织 327+ 仓库元数据与代表性 README([rdk-gen](https://github.com/D-Robotics/rdk-gen)、[manifest](https://github.com/D-Robotics/manifest)、[robot_dev_config](https://github.com/D-Robotics/robot_dev_config)、[hobot_dnn](https://github.com/D-Robotics/hobot_dnn) 等)实地核对归纳,逐条保留出处;清单随组织演进,以当前仓库为准。

## 何时用

用户面对 D-Robotics 一大堆相似命名的仓库**不知道哪个是哪个 / 该去哪个**时用本 skill 快速定位。它回答"这仓是什么、属于哪层、对应哪块板、我的任务该看哪个仓、怎么从源码构建镜像"。

## 三条正交的轴(看懂就能区分任意一个仓)

1. **层级**:BSP/系统 → TROS/ROS2 中间件 → 应用/AI → 产品/文档。
2. **板型**:用前缀切分——**无前缀 = RDK X3** / `x5-` = X5 / `s100-` = S100·S100P / `j5-` = J5(征程5 车载)。(RDK S600 是 S 系列新板,系统 Ubuntu 24.04/Jazzy,BSP 暂未以 `s600-` 前缀开源,见 references。)
3. **装配方式**:`hobot-`(连字符)与 `hobot_`(下划线)是两套体系(见下,最高频混淆点)。

## 最高频区分:连字符 vs 下划线

| | `hobot-xxx`(**连字符**) | `hobot_xxx`(**下划线**) |
| --- | --- | --- |
| 层级 | BSP / 系统源码(进 OS 镜像) | TROS / ROS2 **应用功能包** |
| 例 | `hobot-boot`/`hobot-camera`/`hobot-multimedia`/`hobot-bpu-drivers`/`hobot-dnn`(底层库) | `hobot_dnn`(dnn_node)/`hobot_stereonet`/`hobot_usb_cam`/`hobot_llamacpp` |
| 怎么装配 | `repo` + `manifest` + `*-rdk-gen` → **系统镜像** | `vcstool` + `robot_dev_config/ros2.repos` → **TROS 工作区** |
| 语言 | C / Shell / 配置 | C++ / Python(ROS 包) |

> 同名跨层典型:`hobot-dnn`(连字符,镜像里的 BPU 推理底层库)被 `hobot_dnn`(下划线,封装它的 ROS2 `dnn_node` 包)调用。**上层 ROS 节点 → 下层 BSP 库**。

## 板型前缀:同一 BSP 组件每块板各一份

`hobot-multimedia`(X3)/ `x5-hobot-multimedia`(X5)/ `s100-hobot-multimedia`(S100)是**同一个组件按 SoC 维护的三份**;`camera`/`dnn`/`boot`/`dtb`/`wifi`/`io`/`utils`/`display` 等都如此。这是 Android/Yocto 式按芯片切分的 BSP 多仓结构。

## 两套"多仓装配"系统(理解全组织的钥匙)

```
OS 镜像构建                              TROS 应用构建
  repo + manifest                         vcstool + ros2.repos
  入口 rdk-gen / x5-rdk-gen / s100-rdk-gen 入口 robot_dev_config
  拉 kernel/uboot/bootloader/hobot-*(连字符) 拉 hobot_*(下划线) + rcl/rclcpp/rmw…
  → 可烧录 RDK OS 镜像(*.img)            → /opt/tros 工作区 + deb 包
  底层、板型强相关                        上层、跨板型(靠 BSP 提供能力)
```

从源码构建镜像 / 定制内核 / TROS 从源码编译的**具体命令**见 [os-image-build](references/os-image-build.md)。

## 任务 → 去哪个仓(速查)

| 想做的事 | 去哪个仓库家族 |
| --- | --- |
| 拿现成 BPU 模型直接跑 | `rdk_model_zoo`(X5)/ `rdk_model_zoo_s`(S) → 也见 skill `rdk-model-zoo` |
| 用某个视觉/感知 ROS 节点(检测/双目/SLAM/标定) | `hobot_*` 下划线 + `mono*/stereo*/face_*/hand_*/parking_*` |
| 端侧 LLM/VLM/语音 | `hobot_llamacpp`/`hobot_llm`/`sensevoice_ros2`/`hobot_tts`/`xiaozhi-in-rdk` → skill `rdk-llm-deployment` |
| 具身/机械臂/LeRobot/VLA | `rdk_LeRobot_tools`/`lerobot`/`openpi*`/`RoboTwin` → skill `rdk-embodied-lerobot` |
| **从源码构建/定制 OS 镜像、改内核驱动、加 sensor** | `*-rdk-gen` + `*-manifest` + `kernel`/`uboot`/`bootloader` + `hobot-*`(连字符) |
| TROS 从源码编译整套 | `robot_dev_config`(入口)+ `tros_*` |
| 把 TROS 应用打成 deb 上架应用中心 | `nodehub_*`(NodeHub 打包,README 多只引 TROS 文档) |
| 查官方文档源码 | `rdk_doc`(主)/ `rdk_s_doc` / `tros_doc` / `model_zoo_doc` 等 `*_doc` |

完整 12 类家族地图、识别速查表与代表仓清单见 [repo-families](references/repo-families.md)。

## 识别速查(一眼认出)

- `*_doc` 后缀 → 文档仓;`nodehub_*` → NodeHub 打包;`tros_*` → TROS 工具/编排;`magicbox_*` → MagicBox 产品。
- `rcl`/`rclcpp`/`rmw_*`/`rosbag2`/`vision_opencv`/`isaac_*` → ROS2 上游移植,非 RDK 原创。
- 板型前缀 + 连字符 + `kernel`/`boot`/`manifest` → BSP/镜像层。
- 下划线 + 算法/外设名 → ROS2 应用层。
