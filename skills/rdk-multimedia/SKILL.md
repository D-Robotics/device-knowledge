---
name: rdk-multimedia
description: 当用户要在 RDK 板上做"底层多媒体硬件流水线"时使用——硬件 H.264/H.265/JPEG/MJPEG 编解码、相机 VIN/ISP 取流、VPS/PYM 缩放裁剪旋转、HDMI/MIPI 显示输出,用 sp_dev(/app/cdev_demo C/Python API)、hobot_codec、HB_VIN/HB_VENC/HB_VDEC/HB_VPS/HB_VOT 接口,或 S 系 /app/multimedia_samples(sample_vin/isp/pym/gdc/codec/pipeline、sunrise_camera)、MediaCodec。本 skill 特指"裸用底层硬件单元搬运/编解码/缩放/显示像素流"。划清边界:把模型跑成 BPU 推理(.bin/.hbm 量化转换、视觉推理闭环)→rdk-device;把取流/编码包成 ROS2 节点(hobot_codec 作为 TROS 节点、image topic、usb_cam/mipi_cam launch)→rdk-ros;选哪款相机/IMU/扩展板硬件、CAM 接口接线→rdk-accessories;GPIO/I2C/PWM/电机等非视频外设→rdk-peripheral-cookbook。详细规格/分辨率上限/sp_dev 速查/X 与 S 差异见 references/multimedia-pipeline.md。
---

# RDK 硬件多媒体流水线(编解码 / 取流 / 缩放 / 显示)

> 来源:整理自 D-Robotics 官方文档 `rdk_doc`(X 系:`docs/07_Advanced_development/03_multimedia_development/**`、`docs/03_Basic_Application/06_multi_media_sp_dev_api/**`)与 `rdk_s_doc`(S 系:`docs/07_Advanced_development/03_multimedia_development/**`、`docs/03_Basic_Application/04_multi_media/**`),逐条保留出处;只写文档确有的事实。

这个 skill 管的是"像素流怎么在板上的硬件单元之间搬运":相机进来、ISP 调好、VPS 缩放、VPU/JPU 编解码、HDMI 显示出去。**不**管模型推理(→rdk-device)、不管把这些包成 ROS 节点(→rdk-ros)。

## 先认清流水线(回答任何问题前先定位用户卡在哪一段)

**X 系(X3=Bernoulli2、X5/Ultra=Bayes)流水线:**
```
sensor → VIN(SIF/MIPI 接入 + ISP 图像处理 + LDC/DIS/DWE 畸变防抖)
       → VPS(IPU 缩放/裁剪/旋转 + PYM 金字塔 + GDC 矫正)
       → VENC(VPU:H264/H265) / VDEC + JPU(JPEG/MJPEG)
       → VOT(视频输出:HDMI / MIPI / BT1120,最大 1080P@60)
```
模块间在线/离线绑定走"系统控制"接口(如 `HB_SYS_SetVINVPSMode` 配 VIN↔VPS online/offline)。

**S 系(S100/S100P/S600=Nash)换了一套术语——别拿 X 系的 VPS/VOT 套 S 系:**
```
Camera+SerDes → VIN(CIM + MIPI + LPWM + VCON)
              → ISP → PYM(金字塔缩小/ROI) → GDC(几何畸变矫正)
              → CODEC(VPU 视频 + JPU 图像,MediaCodec 子系统)
              → IDE/IDU 显示(经 MIPI DSI / MIPI CSI2 Device 输出)
```
S 系还多了 STITCH(拼接)、YNR。S100 vs S600 的 MIPI/CIM/ISP 路数与分辨率上限不同,见 reference。

## 两条开发路径,先问用户用哪条

1. **sp_dev 简易封装(推荐新手 / 快速原型,X3/X5/Ultra)**:板上 `/app/cdev_demo/`,C 接口前缀 `sp_*`(也有 Python 封装)。四大模块 VIO / Encoder / Decoder / Display,模块串联用 `sp_module_bind`。现成 demo:`vio2encoder`(相机→编码存 .h264)、`decoder2display`(文件→HDMI)、`rtsp2display`(RTSP 拉流→HDMI)、VPS 缩放。**先让用户跑这些 demo 验证通路,再改代码。**
2. **底层 HB_* 接口(要精细控制 GOP/码率/ROI/多路绑定)**:`HB_MIPI_*` / `HB_VIN_*` / `HB_VPS_*` / `HB_VENC_*` / `HB_VDEC_*` / `HB_VOT_*` + `HB_SYS_*` 绑定。S 系则用 `/app/multimedia_samples/` 下的 `sample_vin/isp/pym/gdc/codec/pipeline` 作模板,`sample_pipeline` 就是 VIN→ISP→PYM→GDC→CODEC 全链路。

sp_dev 函数速查表、HB_* 模块对照、编解码规格/分辨率上限、码率控制五种模式、X 与 S 差异全表见 [多媒体流水线速查](references/multimedia-pipeline.md)。

## 高频排障口径

- **"编码很慢 / CPU 占满 / ffmpeg 软编"**:确认走的是**硬件** VPU/JPU(sp_dev 或 HB_VENC),不是 CPU 软编码;ffmpeg 默认软编,要硬编需用 RDK 的硬件编码后端或 sp_dev。
- **"编码报尺寸 / stride 错误"**:H264/H265 的 **stride 要 32 字节对齐、宽高 8 字节对齐**(JPEG 宽 16/高 8 对齐);不对齐要用 `VIDEO_CROP_INFO_S` 裁剪。规格表见 reference。
- **"想缩放 / 多分辨率出图"**:用 VPS(X 系)或 PYM(S 系)。X 系 VPS 一个 IPU 最多 7 路输出,chn5 才能放大(≤1.5 倍),downscale 最多缩到原图 1/8;sp_dev 走 `sp_open_vps` / `sp_open_camera` 时一次设最多 5 组分辨率(1 组可放大、4 组缩小)。
- **"相机取不到帧 / VIN 起不来"**:这是 ISP/sensor bringup 范畴;X5 上 MIPI 相机 bringup(尤其非官方支持 sensor、no MCLK / i2c NACK)走 `rdk-mipi-camera-bringup` skill,本 skill 只覆盖取流之后的处理链。选 sensor 型号/接线走 rdk-accessories。
- **同一报错重复 2 次** → 停手查官方 doc(`rdk_doc` / `rdk_s_doc` 对应章节),别反复试同一参数。
- **拿不准 X 与 S 哪个接口** → 先确认板型:X3/X5/Ultra 用 `docs/07_Advanced_development/03_multimedia_development/`(VPS/VOT 体系);S100/S600 用 `rdk_s_doc` 同名路径(Camsys/IDE 体系)。

## 边界自检(避免越界到兄弟 skill)

- 用户最终目的是**模型推理结果**(检测框、分类),取流只是喂给模型 → 主体走 **rdk-device**,本 skill 只补取流/缩放细节。
- 用户在 **ROS2/TROS** 里要 image topic、`hobot_codec` 节点、`mipi_cam`/`usb_cam` launch → **rdk-ros**。
- 用户问"哪款相机能用 / 怎么接 CAM 排线 / IMU 选型" → **rdk-accessories**。
