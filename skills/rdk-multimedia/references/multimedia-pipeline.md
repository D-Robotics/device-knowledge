# RDK 多媒体流水线速查(编解码规格 / sp_dev API / X 与 S 差异)

> 来源:`rdk_doc`(X 系)`docs/07_Advanced_development/03_multimedia_development/{overview,video_input,video_processing,video_encode,video_decode,video_output}.md` 与 `docs/03_Basic_Application/06_multi_media_sp_dev_api/RDK_X5/**`;`rdk_s_doc`(S 系)`docs/07_Advanced_development/03_multimedia_development/01_S100/{01_camsys,03_codec,04_display}.md`、`02_multimedia_application/{01_overview,06_sample_codec}.md` 与 `03_S600_multimedia_application/{01_overview,02_sample_vin,03_sample_isp,06_sample_codec,09_sample_pipeline}.md`(`01_S100/03_codec.md` 自述「支持平台:RDKS100/RDKS600」,为 S100+S600 共用规格)。下表只收录文档明确列出的数值;拿不准的见末尾 "不确定"。

## 1. 模块与缩写对照(X 系)

| 缩写 | 全称 | 作用 |
|---|---|---|
| VIN | Video IN | 接 sensor(SIF/MIPI/DVP),含 ISP 图像处理、LDC/DIS/DWE 畸变防抖;最多 8 路 sensor 接入 |
| ISP | Image Signal Processor | 图像效果调校,输出 YUV;支持 Multi context,最多 8 路 |
| VPS | Video Process System | 缩放/裁剪/旋转/GDC 矫正/帧率控制/金字塔 |
| IPU | Image Process Unit | VPS 内做旋转/裁剪/缩放 |
| PYM | Pyramid | 图像金字塔 |
| GDC | Geometrical Distortion Correction | 几何畸变矫正 |
| VENC | Video Encode | H.264/H.265/JPEG/MJPEG 硬件编码 |
| VDEC | Video Decode | H.264/H.265/JPEG/MJPEG 硬件解码 |
| VPU | Video Processing Unit | 视频(H264/H265)编解码硬件 |
| JPU | JPEG Processing Unit | JPEG/MJPEG 编解码硬件 |
| VOT | Video Output | 视频输出到显示设备 |
| VIO | Video IN/OUT | VIN + VOT 合称 |

## 2. 编解码规格(X3,来源 video_encode.md / video_decode.md)

**H.264 / H.265(VPU):**
- 分辨率:最大 8192×8192;最小 256×128;H264 解码最小 32×32,H265 解码最小 8×8。
- 对齐:stride 32 字节对齐,width/height 8 字节对齐(不对齐用 `VIDEO_CROP_INFO_S` 裁剪)。
- 性能:最高 4K@60fps;多码流实时编码;Multi-instance 最多 **32**。
- 码率控制:CBR / VBR / AVBR / FixQp / QpMap 五种(QPMAP 块大小:H264=16×16、H265=32×32)。
- 其它:带 QP map 的 ROI 编码、旋转、镜像、自定义 GOP(最多 8 个结构表)。

**JPEG / MJPEG(JPU):**
- 分辨率:最大 32768×32768;最小 16×16。
- 对齐:stride 32 字节对齐,width 16 字节、height 8 字节对齐。
- 性能:YUV4:2:0(如 NV12)最高 4K@30fps;Multi-instance 最多 **64**。
- 码率控制:仅 FixQp;支持 YUV 4:0:0/4:2:0/4:2:2/4:4:0/4:4:4、ROI、slice encoding、旋转镜像。

**解码性能(X3):** H264/H265 = 3840×2160@60fps;JPEG/MJPEG YUV4:2:0 = 290M pixel/sec;最大 32 通道。VDEC 按帧发送(`VIDEO_MODE_FRAME`),输出可选解码序 / 显示序(`HB_VDEC_SetChnAttr` 配 `VDEC_CHN_ATTR_S`)。

## 3. VPS 通道能力(**X3**,来源 video_processing.md;X5 结构不同)

> ⚠️ 下面这套(1×IPU+1×PYM+2×GDC、7 路 chn0~chn6、chn5 唯一 upscale)是 **X3(Bernoulli2)** 的 VPS;**X5(Bayes)的 VPS 结构不同**(见 `cdev_multimedia_api_x5/vio_api.md` 的 `sp_open_vps`:X5 为「5 个 downscale + 1 个 upscale」组),用 X5 时以 X5 文档为准。

VPS 硬件 = 1×IPU + 1×PYM + 2×GDC,7 路输出 chn0~chn6:
- chn0~chn4:downscale(最大缩到原图 **1/8**,>1/8),最小 32×32,最大 4096。
- chn5:唯一支持 **upscale**(水平/垂直各最大 1.5 倍;宽 4 的倍数、高偶数;最大 4096)。
- chn6:金字塔 online 通道。
- PYM:输入/输出最大 4096×4096,最小输入 64×64。
- IPU 各 scaler FIFO/分辨率上限:US/DS2=4096B/8M、DS1/DS3=2048B/2M、DS0/DS4=1280B/1M。

## 4. VOT 视频输出(X3,来源 video_output.md)

- X3 有 1 个高清设备 DHV0、1 个视频层 VHV0(支持放大、2 通道)、2 个图形层。
- 输出接口:RGB / BT1120(BT656) / MIPI,均最大 1080P@60fps。
- 支持设备级回写(WD)到 DDR,可用于显示和编码。

## 5. sp_dev 用户态 API 速查(X3/X5/Ultra,/app/cdev_demo)

> X5 接口基于 3.5.0 软件版本;3.5.0 之前及 X3 参考 RDK X3 API 文档。模块串联用 `sp_module_bind`。

**VIO(取流 / VPS)**
| 函数 | 作用 |
|---|---|
| `void *sp_init_vio_module()` | 创建 VIO 句柄(其它接口前必调) |
| `void sp_release_vio_module(void *obj)` | 销毁 |
| `int32_t sp_open_camera(obj, pipe_id, video_index, chn_num, *width, *height)` | 打开 MIPI 相机,最多 5 组分辨率(1 放大 4 缩小) |
| `int32_t sp_open_camera_v2(obj, pipe_id, video_index, chn_num, sp_sensors_parameters*, *width, *height)` | 指定 RAW 分辨率打开 |
| `int32_t sp_open_vps(...)` | 打开 VPS(纯缩放/裁剪,不接相机) |
| `int32_t sp_vio_get_frame(...)` | 取一帧 |
| `int32_t sp_vio_set_frame(...)` | 回灌一帧给 VPS |
| `sp_vio_close` | 关闭 |

`video_index`=-1 自动探测,host 编号查 `/etc/board_config.json`。文档化 sensor 分辨率(sp_open_camera_v2):IMX219 默认 1920×1080@30、最大 3264×2464@15;IMX477 默认 1920×1080@50、最大 4000×3000@10。

**Encoder**
| 函数 | 作用 |
|---|---|
| `void *sp_init_encoder_module()` / `sp_release_encoder_module` | 句柄 |
| `int32_t sp_start_encode(obj, chn, type, width, height, bits)` | 建编码通道(type 选 `SP_ENCODER_H264`/`SP_ENCODER_H265`/`SP_ENCODER_MJPEG`;sp_dev 编码层无独立 JPEG 常量,底层 JPU 做 JPEG) |
| `int32_t sp_encoder_set_frame(obj, char *frame_buffer, size)` | 送原始帧 |
| `int32_t sp_encoder_get_stream(obj, char *stream_buffer)` | 取码流 |
| `sp_stop_encode` | 关 |

**Decoder**
| 函数 | 作用 |
|---|---|
| `sp_init_decoder_module` / `sp_release_decoder_module` | 句柄 |
| `int32_t sp_start_decode(obj, const char *stream_file, video_chn, type, width, height)` | 建解码通道 |
| `int32_t sp_decoder_set_image(obj, char *image_buffer, chn, size, eos)` | 送码流 |
| `int32_t sp_decoder_get_image(obj, char *image_buffer)` | 取解码帧 |
| `sp_stop_decode` | 关 |

**Display**
| 函数 | 作用 |
|---|---|
| `sp_init_display_module` / `sp_release_display_module` | 句柄 |
| `int32_t sp_start_display(obj, chn, width, height)` | 建显示通道 |
| `int32_t sp_display_set_image(obj, char *addr, size, chn)` | 送显 |
| `int32_t sp_display_draw_rect(obj, x0,y0,x1,y1, chn, flush, color, line_width)` | 画框 |
| `int32_t sp_display_draw_string(obj, x, y, char *str, chn, flush, color, line_width)` | 画字 |
| `void sp_get_display_resolution(int32_t *width, int32_t *height)` | 读显示器分辨率 |

**绑定(sys_api):**
```c
int32_t sp_module_bind(void *src, int32_t src_type, void *dst, int32_t dst_type);
int32_t sp_module_unbind(void *src, int32_t src_type, void *dst, int32_t dst_type);
// src_type ∈ {SP_MTYPE_VIO, SP_MTYPE_DECODER}
// dst_type ∈ {SP_MTYPE_ENCODER, SP_MTYPE_DISPLAY}
```
典型组合:VIO→ENCODER(录像/推流)、DECODER→DISPLAY(播放)。现成 demo:`vio2encoder`、`decoder2display`、`rtsp2display`、VPS 缩放。绑定成功日志形如 `sp_module_bind(vio -> encoder) success`。

## 6. 底层 HB_* 接口分组(X 系)

- **VIN / MIPI**:`HB_MIPI_SetBus/SetPort/InitSensor/SetSensorClock/SetMipiAttr/Read/WriteSensor…`、`HB_VIN_SetDevAttr/EnableDev/SetDevBindPipe…`。
- **系统绑定**:`HB_SYS_SetVINVPSMode`(VIN↔VPS online/offline)、`HB_SYS_Bind` 系列。
- **VPS**:`HB_VPS_*`(Group/Channel 管理、缩放/裁剪/旋转/PYM)。
- **VENC / VDEC**:`HB_VENC_*` / `HB_VDEC_*`(`HB_VDEC_SetChnAttr` 配 `VDEC_CHN_ATTR_S`、`HB_VDEC_SendStream` 送流)。
- **VOT**:`HB_VOT_*`。

## 7. S 系(S100 / S600,Nash)差异 —— 别套 X 系命名

**Camsys 子系统(来源 01_camsys.md):** Camera+SerDes → VIN(CIM+MIPI+LPWM+VCON) → ISP → PYM → GDC,另有 STITCH、YNR。术语:CIM=Camera Interface Manager,VPF=Video Process Framework(VIN+ISP+PYM…),VIO=VIN+VPM。

| 项 | S100 | S600 |
|---|---|---|
| MIPI RX | 3 个(RX0/RX1/RX4) | 6 个(RX0~RX5) |
| CIM | 3 个(CIM0/1/4) | 6 个(CIM0~5) |
| ISP | 2 个(ISP0/1),最大 4096×2160 | 4 个(ISP0~3),最大 5696×3328 |
| CIM online 去向 | ISP0/1(RAW)、PYM0/1(YUV),或 offline 下 DDR | ISP0~3、PYM0~3,或 offline |
| CIM 接入最大宽 | CIM0 IPI0=5696,其余 4096 | CIM0~2=5696,其余 4096 |

MIPI 物理层:DPHY 4.5Gbps×4lane=18Gbps,CPHY 3.5Gsps×3trios=24Gbps。单 CIM 最大 4V×8M×30fps,支持 RAW8/10/12/14/16/20、YUV422-8bit。

**S100 Codec(来源 03_codec.md):** VPU + JPU 各 1,均 **4K@90fps**。
- VPU:最大 8192×4096、最小 256×128(宽 32/高 8 对齐),input/output 4:2:0、4:2:2;码率控制 CBR/VBR/AVBR/FIXQP/QPMAP;ROI 最多 64 区;rotation 90/180/270;最多 **32** instance。
- JPU:最大 8192×8192、最小 32×32;支持 4:0:0/4:2:0/4:2:2/4:4:0/4:4:4;最多 **64** instance。
- 上层封装为 **MediaCodec** 子系统,提供 H264/H265/JPEG 编解码与视频录像。

**S600 Codec(同一份 03_codec.md,「支持平台」标注 RDKS100/RDKS600):** 编解码硬件规格文档只有这一份,VPU/JPU 的最大/最小分辨率、4K@90fps 性能、instance 上限(VPU≤32、JPU≤64)等特性表 **S100 与 S600 共用**,数值同上方 S100 块。S600 相对 S100 **唯一文档明确的差异是 VPU 多核**:
- 原文「只有 S600 支持 VPU 多核,编解码示例通过 `-u` 配置不同核只在 S600 上生效」。`codec_demo` 的 `-u`(vpu core id)默认 0、可配 **0/1/2**(即 S600 暴露 3 个 VPU 核供选);S100 无此选项。
- 编码能力上限(两者共用):H264 最高 **High@L5.2**;H265 最高 **Main / Main-tier @L5.1**;MJPEG/JPEG 为 ISO/IEC 10918-1 Baseline sequential。instance:Video≤32、MJPEG/JPEG≤64、Audio≤32。
- 注意有 **两套 codec 示例**,别混:① 板上 `/app/multimedia_samples/sample_codec`(`06_sample_codec.md`,S100/S600 文档逐字节相同)走 `codec_config.ini` + `-e/-d` 位掩码(如 `-e 0x3` 启前两路编码),**无 `-u`**;② `codec_demo`(源码 `source/hobot-sp-samples/.../codec_demo`)走 `-m samplemode(0编/1解) -c codecid(0 h264/1 h265/2 mjpeg/3 jpeg) -w/-h -p pixfmt(0 yuv420p/1 nv12/2 nv21) -n 线程数 -u vpu核`,**`-u` 在这一套**。

**S 系显示(来源 04_display.md):** 用 **IDE(Image Display Engine)/ IDU**,不是 X 系 VOT。S100 有 2 个 IDU,共 6 通道(通道 0/1/4/5 为 YUV 层、2/3 为 RGB 层),每通道最大输入 2880×2160,经 **MIPI DSI / MIPI CSI2 Device** 输出(共用一个 MIPI D-PHY)。YUV 层支持 Up-Scale 最大 6 倍。

## 8. S 系示例代码(来源 02_multimedia_application/01_overview.md)

板上 `/app/multimedia_samples/`:
| 目录 | 用途 |
|---|---|
| `sample_vin` | 初始化 sensor,从 VIN 取图 |
| `sample_isp` | 初始化 ISP、取处理后数据 |
| `sample_pym` | PYM 缩小 |
| `sample_gdc` | GDC 各种转换模式 |
| `sample_codec` | H264/H265/JPEG/MJPEG 编解码 |
| `sample_pipeline` | **VIN→ISP→YNR→PYM→(GDC)→VPU 全链路**(S 系实际链路 `vin→isp→ynr→pym`,YNR 是独立一级);S600 子目录:`single_pipe_vin_isp_ynr_pym_vpu` / `..._gdc` / `..._gdc_vpu` / `multi_pipe_vin_isp_ynr_pym_gdc_vpu` |
| `sample_gpu_3d` | OpenCL / OpenGLES 3D GPU |
| `sunrise_camera` | Web 智能摄像头 / 分析盒方案 |
| `vp_sensors` | sensor 配置代码(非独立程序),加 sensor 看 `vp_sensors/README.md` |

用法:`cd /app/multimedia_samples/<sample> && make`,然后 `./sample_xxx`(带 `-i/-w/-h/-f/-V` 等参数,无参数打印 help)。

**S600 示例差异(来源 `03_S600_multimedia_application/`):** 目录布局与 S100 同(均在 `/app/multimedia_samples/` 下)。`sample_vin`/`sample_isp`/`sample_pipeline` 在 S600 文档中比 S100 多出 **`-m <mipi_rx>`** 选项 —— 为 Serdes sensor 指定所连的 mipi host,例 `./get_vin_data -s 4 -m 2 -l 1`(sensor idx 4、mipi host 2、link 1);非 Serdes sensor 无需 `-l/-m`。S600 **目前仅 mipi host 0、2、4、5 可用**(对照 `01_overview.md`「硬件使用指南」的 mipi host 编号图)。

## 9. 不确定 / 待核实

- S100P 的 MIPI/CIM/ISP 路数文档未单列(camsys 文档只对比 S100 与 S600);默认按 S100 处理,需要时核 `rdk_s_doc`。
- sp_dev 在 S 系上的可用性:S 系主推 `/app/multimedia_samples` 的 HB_*/MediaCodec 路线;`docs/03_Basic_Application/04_multi_media/` 下有 `multi_media_api/{cdev,pydev}` 与 `pydev_multimedia_api_s100.md`,但与 X 系 sp_dev 的 API 对齐程度未逐一核对,使用前以 `rdk_s_doc` 对应文件为准。
- X5/Ultra 的编解码规格(instance 数、最大分辨率)文档以 X3 章节为主叙述,X5/Ultra 个别数值可能随软件版本变化,精确上限以板上对应版本文档为准。
- VENC/VDEC 的 `type` 枚举具体常量名(H264/H265/MJPEG/JPEG)未在已读文件逐一列出常量字面量,编码时以板上头文件为准。