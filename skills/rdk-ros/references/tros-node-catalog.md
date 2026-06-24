# TROS 功能节点目录(感知能力 → 节点速查)

> 来源:整理自 D-Robotics TROS 官方文档仓库 [D-Robotics/tros_doc](https://github.com/D-Robotics/tros_doc)(默认分支 `main`)下 `docs/03_boxs/**`、`docs/04_apps/**`、`docs/05_tros_dev/**`,以及对应公开站点 <https://developer.d-robotics.cc/rdk_doc/Robot_development/>。仅记录文档确有的事实;话题名/板型以各节点 README 为准,拿不准处见末尾「不确定项」。

## 怎么用这张表

想跑某个感知能力时:先在下面对应类目里找节点 → 看「订阅/发布话题」确认数据怎么进出 → 看「板型」确认你的板支持 → 复制「最小 launch」起节点 → 点「文档」看完整参数。

**先决条件**:`source /opt/tros/humble/setup.bash`(X3/X5/Ultra/S100/S100P);**RDK S600 用 `/opt/tros/jazzy`**(Ubuntu 24.04 / Jazzy)。launch 前用 `ros2 pkg prefix <pkg>` 确认包已装,`ros2 launch <pkg> <launch> --show-args` 看可调参数。

## 话题约定(读表前先懂这几条)

TROS 视觉节点话题命名高度一致,理解约定后整张表都好读:

- **图像输入**:`ros_img_sub_topic_name`(默认 `/image`,普通 ROS2 image)或 `sharedmem_img_topic_name`(默认 `/hbmem_img`,零拷贝共享内存,大图低延迟首选)。sensor 包(mipi_cam / usb_cam / hobot_image_publisher 回灌)负责发布。
- **AI 结果输出**:由各节点 `ai_msg_pub_topic_name` 决定,消息类型多为 `ai_msgs::msg::PerceptionTargets`。
- **级联订阅**:下游节点(人手关键点、人脸、reid、SAM 分割)靠 `ai_msg_sub_topic_name` 订阅上游检测框,通常是 `/hobot_mono2d_body_detection`。
- **Web 可视化**:`websocket` 包订阅 `image_topic`(图)+ `smart_topic`(AI msg),浏览器开 `http://<板端IP>:8000` 看效果。

下表「关键订阅/发布话题」给的是该节点最有应用价值的话题(默认值),完整话题与参数以文档为准。

> **板型列说明**:下表凡列「X3」的节点,官方支持表通常**同时支持 RDK X3 Module**(表内为省略未逐一重复);S 系列产物 `.hbm`、X 系列 `.bin`。具体以各节点 README「支持平台」表为准。

---

## audio — 语音感知

| 节点 / 包 | 作用 | 关键订阅 | 关键发布 | 支持板型 | 最小 launch | 文档 |
|---|---|---|---|---|---|---|
| **hobot_audio** | 本地离线智能语音:唤醒词 + 命令词识别 + 声源定位(DOA)+ ASR;配环形/线形四麦阵列 | 麦克风阵列(ALSA 设备,非 ROS 话题) | `/audio_smart`(`audio_msg::msg::SmartAudioData`,含唤醒/命令词/DOA);开 ASR 后 `/audio_asr`(`std_msgs::msg::String`) | X3, X5, X5 Module | `ros2 launch hobot_audio hobot_audio.launch.py` | [audio/hobot_audio](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/audio/hobot_audio) |
| **sensevoice_ros2** | SenseVoice GGUF 智能语音:命令词 + ASR;配 3.5mm 耳麦 | 麦克风(`micphone_name`,如 `plughw:0,0`) | `/audio_smart`(命令词)、`/asr_text`(ASR;需唤醒词「你好,地瓜机器人」才输出) | X5, X5 Module, S100, S100P, S600 | `ros2 launch sensevoice_ros2 sensevoice_ros2.launch.py micphone_name:="plughw:0,0"` | [audio/sensevoice_ros2](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/audio/sensevoice_ros2) |

---

## body — 人体 / 人手 / 人脸

| 节点 / 包 | 作用 | 关键订阅 | 关键发布 | 支持板型 | 最小 launch | 文档 |
|---|---|---|---|---|---|---|
| **mono2d_body_detection** | 2D 人体/人头/人脸/人手框 + 人体关键点检测,带多目标跟踪(MOT) | `/hbmem_img`(或 `/image`) | `/hobot_mono2d_body_detection`(`ai_msgs/PerceptionTargets`) | X3, X5, X5 Module | `ros2 launch mono2d_body_detection mono2d_body_detection.launch.py` | [body/mono2d_body_detection](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/body/mono2d_body_detection) |
| **mono2d_body_detection**(YOLO-Pose 变体) | 用 YOLO11-Pose 做人体框 + 关键点 + MOT(Nash 平台 `.hbm` 模型) | `/hbmem_img` | `/hobot_mono2d_body_detection`(`pose`/关键点) | S100, S100P, S600 | `ros2 launch mono2d_body_detection mono2d_body_detection.launch.py kps_model_type:=1 kps_model_file_name:=config/yolo11x_pose_nashe_640x640_nv12.hbm` | [body/mono2d_yolo_pose](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/body/mono2d_yolo_pose) |
| **hand_lmk_detection** | 人手关键点(需上游人手框) | `/image` + `/hobot_mono2d_body_detection`(人手框) | `/hobot_hand_lmk_detection` | X3, X5, X5 Module | `ros2 launch hand_lmk_detection hand_lmk_detection.launch.py` | [body/hand_lmk_detection](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/body/hand_lmk_detection) |
| **hand_gesture_detection** | 静态/动态手势识别(需上游人手框 + 关键点) | `/hobot_hand_lmk_detection` | `/hobot_hand_gesture_detection` | X3, X5, X5 Module | `ros2 launch hand_gesture_detection hand_gesture_detection.launch.py`(动态:加 `is_dynamic_gesture:=True`) | [body/hand_gesture_detection](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/body/hand_gesture_detection) |
| **hand_landmarks_mediapipe**(palm_detection_mediapipe) | MediaPipe 手掌检测 + 手部关键点 | `/image`(或 `/hbmem_img`) | `/hand_landmarks_mediapipe` | X5, X5 Module, S100, S100P | `ros2 launch hand_landmarks_mediapipe hand_landmarks.launch.py` | [body/hand_lmk_gesture_mediapipe](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/body/hand_lmk_gesture_mediapipe) |
| **face_age_detection** | 人脸年龄估计(需上游人体/人脸框) | `/image` + `/hobot_mono2d_body_detection` | `/hobot_face_age_detection` | X3, X5, X5 Module | `ros2 launch face_age_detection body_det_face_age_det.launch.py` | [body/mono_face_age_detection](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/body/mono_face_age_detection) |
| **face_landmarks_detection** | 人脸 106 点关键点(需上游人脸框) | `/image` + `/hobot_mono2d_body_detection` | `/hobot_face_landmarks_detection`(`faceLandmark106pts`) | X3, X5, X5 Module | `ros2 launch face_landmarks_detection body_det_face_landmarks_det.launch.py` | [body/mono_face_landmarks_detection](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/body/mono_face_landmarks_detection) |
| **reid** | 行人重识别:把每人特征编码为 [1,512],靠余弦相似度判断是否同一人(需上游人体框) | `/image` + `/hobot_mono2d_body_detection` | `/perception/detection/reid`(含实例 ID) | X5, X5 Module, S100, S100P, S600 | `ros2 launch reid reid.launch.py` | [body/reid](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/body/reid) |
| **mono_edgetam** | EdgeTAM 点/框提示的目标跟踪 + 分割,两阶段:prompt 初始化 → track 跟踪 | prompt 阶段订阅 `/hobot_dnn_detection`(`ai_msgs/PerceptionTargets`,点/框提示) | 分割结果话题 + `render_frames`(渲染) | S100, S100P | prompt:`ros2 launch mono_edgetam_prompt mono_edgetam_prompt.launch.py edgetam_prompt_mode:=0`;再 track:`ros2 launch mono_edgetam_track mono_edgetam_track.launch.py` | [body/mono_edgetam](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/body/mono_edgetam) |

---

## classification — 分类

| 节点 / 包 | 作用 | 关键订阅 | 关键发布 | 支持板型 | 最小 launch | 文档 |
|---|---|---|---|---|---|---|
| **dnn_node_example**(mobilenetv2 配置) | MobileNetV2 图像分类,发布物体类别 | `/hbmem_img` | `hobot_dnn_detection` | X3, X5, X5 Module, S100, S100P, S600 | `ros2 launch dnn_node_example dnn_node_example.launch.py dnn_example_config_file:=config/mobilenetv2workconfig.json dnn_example_image_width:=480 dnn_example_image_height:=272` | [classification/mobilenetv2](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/classification/mobilenetv2) |

---

## detection — 目标检测

> 多数检测/分类/分割共用 `dnn_node_example` 入口(仓库 [hobot_dnn](https://github.com/D-Robotics/hobot_dnn)),靠 `dnn_example_config_file` 切换模型,统一订阅 `/hbmem_img`、发布 `hobot_dnn_detection`。

| 节点 / 包 | 作用 | 关键订阅 | 关键发布 | 支持板型 | 最小 launch | 文档 |
|---|---|---|---|---|---|---|
| **dnn_node_example**(yolo 配置) | YOLO 系列检测,支持 v2/v3/v5/v5x/v8/v10/v11/v12 | `/hbmem_img` | `hobot_dnn_detection` | X3, X5, X5 Module, S100, S100P, S600 | `ros2 launch dnn_node_example dnn_node_example.launch.py dnn_example_config_file:=config/yolov2workconfig.json dnn_example_image_width:=1920 dnn_example_image_height:=1080` | [detection/yolo](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/detection/yolo) |
| **dnn_node_example**(fcos 配置) | FCOS 单阶段检测 | `/hbmem_img` | `hobot_dnn_detection` | X3, X5, X5 Module | `ros2 launch dnn_node_example dnn_node_example.launch.py dnn_example_config_file:=config/fcosworkconfig.json dnn_example_image_width:=480 dnn_example_image_height:=272` | [detection/fcos](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/detection/fcos) |
| **dnn_node_example**(mobilenet_ssd 配置) | MobileNet-SSD 检测 | `/hbmem_img` | `hobot_dnn_detection` | X3, X5, X5 Module | `ros2 launch dnn_node_example dnn_node_example.launch.py dnn_example_config_file:=config/mobilenet_ssd_workconfig.json dnn_example_image_width:=480 dnn_example_image_height:=272` | [detection/mobilenet](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/detection/mobilenet) |
| **dnn_node_example**(efficientnet_det 配置) | EfficientDet 检测 | `/hbmem_img` | `hobot_dnn_detection` | X3 | `ros2 launch dnn_node_example dnn_node_example.launch.py dnn_example_config_file:=config/efficient_det_workconfig.json dnn_example_image_width:=480 dnn_example_image_height:=272` | [detection/efficientnet](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/detection/efficientnet) |
| **hobot_dosod** | DOSOD 开放集目标检测 | `/image`(`ros_img_sub_topic_name`) | `/hobot_dosod`(`ai_msgs/PerceptionTargets`) | X5, X5 Module, S100, S100P, S600 | `ros2 launch hobot_dosod dosod.launch.py` | [detection/hobot_dosod](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/detection/hobot_dosod) |
| **hobot_yolo_world** | YOLO-World 开放词汇检测:用文本改检测类别(零样本) | `/image` + `/target_words`(`ros_string_sub`,输入文本) | `/hobot_yolo_world` | X5, X5 Module | `ros2 launch hobot_yolo_world yolo_world.launch.py` | [detection/hobot_yolo_world](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/detection/hobot_yolo_world) |

---

## segmentation — 分割

| 节点 / 包 | 作用 | 关键订阅 | 关键发布 | 支持板型 | 最小 launch | 文档 |
|---|---|---|---|---|---|---|
| **dnn_node_example**(mobilenet_unet 配置) | MobileNet-UNet 语义分割,渲染图存运行路径 | `/hbmem_img` | `hobot_dnn_detection` | X3, X5, X5 Module, S100, S100P, S600 | `ros2 launch dnn_node_example dnn_node_example.launch.py dnn_example_dump_render_img:=1 dnn_example_config_file:=config/mobilenet_unet_workconfig.json dnn_example_image_width:=1920 dnn_example_image_height:=1080` | [segmentation/mobilenet_unet](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/segmentation/mobilenet_unet) |
| **hobot_model**(yolov8_seg 配置,经 dnn_node_example) | YOLOv8-Seg 实例分割 | `/hbmem_img` | `hobot_dnn_detection` | X5, X5 Module, S100, S100P | `ros2 launch dnn_node_example dnn_node_example.launch.py dnn_example_config_file:=config/yolov8segworkconfig.json dnn_example_image_width:=1920 dnn_example_image_height:=1080` | [segmentation/yolov8_seg](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/segmentation/yolov8_seg) |
| **mono_mobilesam** | Mobile-SAM:对上游检测框内目标做分割(无需类别,只要框) | `/image` + 上游检测框 | `hobot_sam`(分割 + 检测 msg) | X5, X5 Module | `ros2 launch mono_mobilesam sam.launch.py` | [segmentation/mono_mobilesam](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/segmentation/mono_mobilesam) |
| **mono_edgesam** | EdgeSAM:对上游检测框内目标做分割 | `/image` + 上游检测框 | `/perception/segmentation/edgesam` | X5, X5 Module, S100, S100P, S600 | `ros2 launch mono_edgesam sam.launch.py` | [segmentation/mono_edgesam](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/segmentation/mono_edgesam) |

---

## spatial — 空间感知(深度 / 3D / 里程计 / 占用)

| 节点 / 包 | 作用 | 关键订阅 | 关键发布 | 支持板型 | 最小 launch | 文档 |
|---|---|---|---|---|---|---|
| **hobot_stereonet** | 双目深度估计(IGEV/GRU),输出视差图 + 深度图 | `/image_combine_raw`(双目拼接图,上左下右) | `~/stereonet_depth`(深度)、`~/stereonet_pointcloud2`(点云)、`~/stereonet_visual`(可视化) | X5, X5 Module, S100, S100P | 依相机而定,如配 ZED:`ros2 launch hobot_zed_cam zed_cam_node.launch.py`(再起 stereonet) | [spatial/hobot_stereonet](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/spatial/hobot_stereonet) |
| **dstereo_occnet** | 地瓜双目 OCC:双目图 → 占用网格(voxel) | `/image_combine_raw`(+ 可选 `/image_combine_raw/camera_info`) | `/dstereo_occnet_node/voxel`(`sensor_msgs/PointCloud2`,rviz2 可视) | X5, X5 Module, S100, S100P | `ros2 launch dstereo_occnet zed2i_occ_node.launch.py` | [spatial/dstereo_occupancy](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/spatial/dstereo_occupancy) |
| **hobot_vio** | 视觉惯性里程计(相机 + IMU 融合定位),输出运动轨迹 | `/camera/infra1/image_rect_raw`(`image_topic`)+ `/camera/imu`(`imu_topic`),默认 RealSense | 相机运动轨迹(rviz2 查看) | X3, X5, X5 Module | `ros2 launch hobot_vio hobot_vio.launch.py` | [spatial/hobot_vio](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/spatial/hobot_vio) |
| **stereo_imu_cam**(hobot_mipi_cam) | 地瓜双目 IMU 相机驱动(自带标定),供双目深度 / VIO 用 | — | `/image_left_raw` `/image_right_raw`(双目)、`/imu_data`(IMU,rad/s、m/s²) | X5, X5 Module | `ros2 launch mipi_cam mipi_cam_dual_channel.launch.py`(参数见文档) | [spatial/stereo_imu_cam](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/spatial/stereo_imu_cam) |
| **elevation_net** | 单目高程网络:从图像估像素深度 + 高度,输出点云 | 本地图片(回灌) | `PointCloud2`(深度 + 高度) | X3, X5, X5 Module | `ros2 launch elevation_net elevation_net.launch.py` | [spatial/elevation_net](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/spatial/elevation_net) |
| **mono3d_indoor_detection** | 单目室内 3D 检测,输出类别 + 3D 位置/朝向(类别:充电座/垃圾桶/拖鞋) | 本地图片(回灌) | 3D 检测 `ai_msg` | X3, X5, X5 Module | `ros2 launch mono3d_indoor_detection mono3d_indoor_detection.launch.py` | [spatial/mono3d_indoor_detection](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/spatial/mono3d_indoor_detection) |

---

## driver — 自动驾驶感知(BEV / 激光雷达 / 路面)

| 节点 / 包 | 作用 | 关键订阅 | 关键发布 | 支持板型 | 最小 launch | 文档 |
|---|---|---|---|---|---|---|
| **hobot_bev** | BEV 多任务感知:6 路环视图 → 10 类目标 3D 框 + 车道线/人行道/路沿分割(nuScenes 训练) | 本地 6 路图像(回灌) | 渲染图片 msg(`/image_jpeg`,Web 可视) | S100, S100P | `ros2 launch hobot_bev hobot_bev.launch.py` | [driver/hobot_bev](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/driver/hobot_bev) |
| **hobot_centerpoint** | 激光雷达 3D 检测(CenterPoint,32 线点云):car/truck/bus/barrier/motorcycle/pedestrian | 本地点云文件(回灌) | `/hobot_centerpoint`(3D 框)+ 渲染图(`/image_jpeg`) | S100, S100P | `ros2 launch hobot_centerpoint hobot_centerpoint.launch.py` | [driver/hobot_centerpoint](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/driver/hobot_centerpoint) |
| **parking_perception** | 路面结构化:车位 + 路面目标(骑车人等)检测分割 | `/image`(sensors image)或本地图片 | `ai_msg_parking_perception` | X3 | `ros2 launch parking_perception parking_perception.launch.py` | [driver/parking_perception](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/driver/parking_perception) |

---

## function — 通用功能(多模态 / 光流)

| 节点 / 包 | 作用 | 关键订阅 | 关键发布 | 支持板型 | 最小 launch | 文档 |
|---|---|---|---|---|---|---|
| **hobot_clip**(clip_manage / clip_encode_image / clip_encode_text) | CLIP 图文检索:以文搜图 / 以图搜图,特征入 SQLite 库;支持本地/服务(Action)模式 | 图像/文本(本地或 Action 请求) | CLIP 编码特征 / 检索结果(`clip_msgs`) | X5, X5 Module, S100, S100P | 入库模式:`ros2 launch clip_manage hobot_clip_manage.launch.py clip_mode:=0 clip_db_file:=clip.db clip_storage_folder:=/root/config` | [function/hobot_clip](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/function/hobot_clip) |
| **mono_pwcnet** | PwcNet 光流估计:两帧连续图像 → 第一帧光流图 | `/image`(`ros_img_sub`) | `/pwcnet_msg` | X5, X5 Module | `ros2 launch mono_pwcnet pwcnet.launch.py` | [function/mono_pwcnet](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/function/mono_pwcnet) |

---

## generate — 端侧生成式(LLM / VLM)

> 这几个多用 `ros2 run` + 参数,既能终端直接对话,也能「订阅文本话题→发布文本结果」接入应用。

| 节点 / 包 | 作用 | 关键订阅 | 关键发布 | 支持板型 | 最小命令 | 文档 |
|---|---|---|---|---|---|---|
| **hobot_llamacpp** | 端侧 VLM(InternVL2.5-1B / SmolVLM,基于 llama.cpp + BPU);图文问答 | 订阅模式:图片话题 + 文本话题 | 文本结果话题 | X5, X5 Module, S100, S100P | 终端体验:`ros2 run hobot_llamacpp hobot_llamacpp --ros-args -p feed_type:=0 -p image:=config/image2.jpg -p user_prompt:="描述一下这张图片." -p model_file_name:=vit_model_int16.hbm -p llm_model_name:=Qwen2.5-0.5B-Instruct-Q4_0.gguf` | [generate/hobot_llamacpp](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/generate/hobot_llamacpp) |
| **hobot_llm** | 端侧 LLM 文本对话 | `/text_query`(`std_msgs/String`) | `/text_result` | X3 | 订阅发布模式:`ros2 run hobot_llm hobot_llm`(另开终端 `ros2 topic pub --once /text_query std_msgs/msg/String "{data: '中国的首都是哪里'}"`) | [generate/hobot_llm](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/generate/hobot_llm) |
| **hobot_xlm** | 端侧 LLM(如 DeepSeek-R1-Distill-Qwen-1.5B),S100 系列 | `/prompt_text`(`ros_string_sub_topic_name`) | `/generation/lanaguage/deepseek` + `/tts_text` | S100, S100P | `ros2 run hobot_xlm hobot_xlm --ros-args -p feed_type:=1 -p ros_string_sub_topic_name:="/prompt_text" -p model_name:="DeepSeek_R1_Distill_Qwen_1.5B"` | [generate/hobot_xlm](https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/generate/hobot_xlm) |

---

## apps — 整机应用(04_apps)

> 多数 App 模式:**PC 端跑 Gazebo 虚拟小车 + Rviz2,RDK 端跑感知/策略节点**;控制指令(`/cmd_vel` 等)也可直接驱动实物小车。先看 SLAM 建图,再看 Nav2 导航。

| 应用 / 包 | 作用 | RDK 端最小 launch | 配合(PC 端) | 支持板型 | 文档 |
|---|---|---|---|---|---|
| **audio_control** | 语音命令词控制小车前后左右(配 hobot_audio/sensevoice) | `ros2 launch audio_control audio_control.launch.py` | `ros2 launch turtlebot3_gazebo empty_world.launch.py` | X3, X5, X5 Module(**官方支持表无 S100**) | [apps/car_audio_control](https://developer.d-robotics.cc/rdk_doc/Robot_development/apps/car_audio_control) |
| **audio_tracking** | 声源 DOA 角度追踪:小车转向声源并前进 | `ros2 launch audio_tracking audio_tracking.launch.py car_front_audio_angle:=90` | Gazebo empty_world | X3, X5, X5 Module | [apps/car_audio_tracking](https://developer.d-robotics.cc/rdk_doc/Robot_development/apps/car_audio_tracking) |
| **gesture_control** | 手势控制小车(旋转/平移),链路:人体检测→手关键点→手势识别→控制 | `ros2 launch gesture_control gesture_control.launch.py` | Gazebo empty_world | X3, X5, X5 Module | [apps/car_gesture_control](https://developer.d-robotics.cc/rdk_doc/Robot_development/apps/car_gesture_control) |
| **body_tracking** | 人体跟随:小车跟着人移动 | `ros2 launch body_tracking body_tracking_without_gesture.launch.py` | Gazebo empty_world | X3, X5, X5 Module | [apps/car_tracking](https://developer.d-robotics.cc/rdk_doc/Robot_development/apps/car_tracking) |
| **hobot_falldown_detection** | 跌倒检测:订阅图像→人体关键点→姿态分析→发布跌倒事件 | `ros2 launch hobot_falldown_detection hobot_falldown_detection.launch.py` | — | X3, X5, X5 Module | [apps/fall_detection](https://developer.d-robotics.cc/rdk_doc/Robot_development/apps/fall_detection) |
| **parking_search** | 车位寻找:车位检测→控制策略→驶入车位 | `ros2 launch parking_search parking_search.launch.py` | 可选 Gazebo | X3 | [apps/parking_search](https://developer.d-robotics.cc/rdk_doc/Robot_development/apps/parking_search) |
| **hobot_rtsp_client**(智能盒子) | IPC RTSP 视频流 → 解码 → 人体人脸检测 → Web 展示 | `ros2 launch hobot_rtsp_client hobot_rtsp_client_ai_websocket_plugin.launch.py hobot_rtsp_url_num:=1 hobot_rtsp_url_0:='rtsp://...' hobot_transport_0:='udp' websocket_channel:=0` | 浏览器 | X3, X5, X5 Module, S100, S100P, S600 | [apps/video_boxs](https://developer.d-robotics.cc/rdk_doc/Robot_development/apps/video_boxs) |
| **Nav2**(nav2_bringup) | ROS2 Navigation2 导航(基于 SLAM 建好的地图) | `ros2 launch nav2_bringup bringup_launch.py use_sim_time:=True map:=/opt/ros/humble/share/nav2_bringup/maps/turtlebot3_world.yaml` | PC:`turtlebot3_world.launch.py` + Rviz2 设目标点 | X3, X5, X5 Module, S100, S100P | [apps/navigation2](https://developer.d-robotics.cc/rdk_doc/Robot_development/apps/navigation2) |
| **SLAM**(slam_toolbox) | SLAM-Toolbox 建图(RDK 端运行,Gazebo/Rviz2 在 PC) | `ros2 launch slam_toolbox online_sync_launch.py` | PC:`turtlebot3_world.launch.py` + `turtlebot3_bringup rviz2.launch.py` | X3, X5, X5 Module, S100, S100P, S600 | [apps/slam](https://developer.d-robotics.cc/rdk_doc/Robot_development/apps/slam) |

---

## 自定义节点开发要点(05_tros_dev)

- **hobot_dnn 推理框架**:TROS 板端算法推理框架,基于它二次开发自己的 BPU 推理 Node(模型管理、输入处理、结果解析、输出内存管理)。典型链路:订阅摄像头图像 → BPU 推理(如人体框)→ MOT 跟踪编号 → Web 渲染。文档:[tros_dev/ai_predict](https://developer.d-robotics.cc/rdk_doc/Robot_development/tros_dev/ai_predict)。
- **zero-copy(零拷贝)大数据传输**:用 RDK `hbmem` 跨进程零拷贝传大块数据(图像/点云),显著降时延与负载。tros.b Foxy 为私有实现;**Humble 及之后(含 Jazzy)直接用 ROS2 原生 loaned message**(`talker_loaned_message`)。这也是为什么很多视觉节点订阅 `/hbmem_img` 而非 `/image`。文档:[tros_dev/zero_copy](https://developer.d-robotics.cc/rdk_doc/Robot_development/tros_dev/zero_copy)。
- **快速体验入口**:`docs/02_quick_demo`(感知/通信/渲染/工具类 demo)是上手 TROS 各能力的速通示例,适合先跑通再深入单节点。

## 不确定项

- 部分节点(检测/分类/分割经 `dnn_node_example` 的)发布话题在文档里写作 `hobot_dnn_detection`,未带前导 `/`;实际为 `/hobot_dnn_detection`(ROS2 全局话题),沿用文档原文未补斜杠的表述。
- `mono_mobilesam` 发布的 `smart_topic` 文档示例为 `hobot_sam`,`mono_edgesam` 为 `/perception/segmentation/edgesam`;两者订阅的上游检测框具体话题名文档未逐一列出,实际以 launch 中 `ai_msg_sub_topic_name` 为准。
- `hobot_llamacpp` 订阅/发布的图像与文本话题确切名称,文档主要演示 `ros2 run` 终端模式,订阅发布模式的话题名未在 README 明确列出,需查包内 launch/参数。
- `mono2d_yolo_pose` 文档中关键点结果是否单独发 `/pose` 话题、还是并入 `/hobot_mono2d_body_detection`,README 未完全澄清;表中以主 ai_msg 话题为准。
- 各节点「支持板型」严格取自对应 README 的「支持平台」表;同一算法在不同板型的模型格式不同(X3/X5/Ultra 用 `.bin`,S100/S100P/S600 用 `.hbm`),launch 里的模型文件名需按板替换(如 yolo_pose 的 `*_nashe_*.hbm` / `*_nashp_*.hbm`)。
- 文档 URL 采用站点路径 `https://developer.d-robotics.cc/rdk_doc/Robot_development/boxs/<class>/<node>`(已抽样 200 验证 `detection/yolo`、`apps/navigation2`);个别节点页面路径(如别名/重定向)若 404,可回退到仓库源文件 `https://github.com/D-Robotics/tros_doc/blob/main/docs/03_boxs/<class>/<file>.md`。