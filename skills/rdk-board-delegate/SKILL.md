---
name: rdk-board-delegate
description: 当需要向板端 agent(OpenClaw)交接/委派任务、用 board_openclaw_chat / board_openclaw_delegate 但不确定该传哪些信息(目标/背景/已做/分析/期望)、交接信息不全被打回、或理解 S100 "大小脑异构"(6×A78AE 大脑 CPU + Nash BPU + 4×R52+ 小脑 MCU 实时控制)分工与 MCU 固件烧录(JTAG/Type-C、Main/MCU 双 UART)时使用。
---

# RDK 板端委派与 S100 大小脑协同

> 来源:整理自 D-Robotics RDK 官方文档、工具链与社区实践,逐条保留出处链接;由 device-knowledge 知识库忠实转换而来,未改写技术事实。

## 何时用

- 要把任务交给板端 agent(OpenClaw),调 `board_openclaw_chat` / `board_openclaw_delegate` 前不确定该写哪些信息,或交接太简略被打回。
- 想搞清 S100 三块异构算力(CPU/BPU/MCU)谁负责什么、MCU 怎么烧固件、S100 还是 S100P。

板端委派/交接必须信息完整(目标/背景/已做/分析/期望);S100 的 MCU 与主控分工是具身智能关键。

**OpenClaw 工作交接**：`board_openclaw_chat` / `board_openclaw_delegate` 必须包含——
目标（一句话）、背景（为什么 + 设备状态）、已做的事（命令+关键输出）、分析（判断+方案理由）、期望（需要什么信息/操作）

## S100 "大小脑异构":三块算力的分工

S100 的设计哲学不是堆算力,而是 **CPU + BPU + MCU 三块异构**,"感知-决策-控制"在单 SoC 内闭环:

- **"大脑" CPU**(6× A78AE):Linux 应用、ROS2 节点、AI 任务编排——用户主要写代码的地方(Ubuntu 22.04)。
- **"决策" BPU**(Nash 80/128 TOPS):LLM/VLM/检测/分割/点云,模型经天工开物/OE 转成 `.hbm` 后走 `hbm_runtime` / BPU runtime(S100 是 Nash 架构、产物 `.hbm`,不是 X 系列的 `.bin` + `hobot_dnn`)。
- **"小脑" MCU**(4× R52+ @1.2GHz):关节实时控制(ms/kHz 级)、IMU 预处理、电机回路。运行 RTOS/裸金属固件,**不是普通 Linux 程序**,通过 IPC(共享内存+通知)与 CPU 交互。

**委派/实操关键(用户常忽视)**:

- 关节控制从 Linux RT 线程卸载到 MCU 后,官方宣传 "CPU 占用率下降 80%";硬实时回路比 X5 的 Linux RT 线程稳。
- MCU 固件**不在 `apt`**;开发对象是 **MCU1**(开源业务固件,跑 FreeRTOS),用 GCC 交叉编译出 `.elf`。**日常迭代不烧 flash、不需要 JTAG**——把 `.elf` 推到板端 `/lib/firmware`,再 `echo start > /sys/class/remoteproc/remoteproc_mcu0/state` 由 Linux remoteproc 加载即可(stop 后必须等系统进 wfi 才能再 start,否则跑飞)。JTAG/`fastboot`/Xburn 只用于 **MCU0**(闭源、负责启动/电源管理)或裸机底层调试。**Main Domain(Acore/Linux)UART 与 MCU Domain UART 是两个不同调试口,别弄混**。详细工具链/编译/IPC 实操见 [MCU 开发参考](references/mcu-development.md)。
- 纯视觉应用可暂不碰 MCU,只当 BPU 算力板用;要上手 MCU,到 D-Robotics GitHub 按 `s100-` 前缀 + MCU/firmware 关键词找 SDK/RTOS 固件仓(可借 rdk-source-map 定位),仓库名与烧录步骤以官方 rdk_s_doc / S100 用户手册为准。相机走扩展板(MIPI 多路 4-lane 或 GMSL,具体路数以官方 S100 硬件手册为准),裸板无直接相机接口。
- 选型:S100(12GB/80 TOPS)→ 7B 量化 LLM、主流 VLM、双足/四足;S100P(24GB/128 TOPS)→ 更大模型/多路 GMSL/科研。

## 需要更细时查阅

[硬件与系统参考](references/hardware-notes.md) 的「S100 大小脑异构与 MCU 协同」一节,补充了正文未展开的细节:

- 三块算力分工对照表(硬件/典型任务/开发者接触面),含 A78AE 主频 S100 @1.5GHz vs S100P @2.0GHz
- MCU R52+ 锁步细节:**S100 = 1× DCLS + 1× Split-Lock(4 核);S600 = 1× DCLS + 2× Split-Lock(6 核)**(按安全需求选)
- X5(传统 Linux RT 线程电机回路)vs S100(IPC→MCU 硬实时)的机器人链路对比图

要在 **大脑(Linux/Acore)侧** 用 S100 独有的系统能力——零拷贝共享内存(hbmem)、Acore↔MCU/VDSP/BPU 的 IPC 与实时绑核、PCIe(RC/EP/加速卡)、EtherCAT 运动控制主站、PTP/gPTP 时间同步、系统 OTA / miniboot 升级——见 [S 系列 Linux 高级开发参考](references/s-advanced.md)。它与 MCU 侧(mcu-development.md)互补:前者是大脑侧怎么管内存/收发/升级,后者是小脑侧固件怎么写。适用 S100 家族(S100/S100E/S100P);S600 未在该文档覆盖。

## 参考资料

- [MCU(小脑)开发参考](references/mcu-development.md)（S 系列 MCU 工具链/编译(S100 vs S600 参数顺序相反)、remoteproc 加载固件与 wfi 陷阱、Acore↔MCU IPC 共享内存机制、FreeRTOS 业务与中断双使能、ramdump/crash 调试,以及 S100/S600 MCU 差异速查）
- [S 系列 Linux 高级开发参考](references/s-advanced.md)（Acore 侧 S100 独有主题:hbmem 零拷贝共享内存 + 内存队列/池、Acore IPC 实例分配与实时绑核 + libipcfhal/pyhbipchal sample、PCIe RC/EP 拓扑与 libhbpciehal pub/sub、EtherCAT-IgH 运动控制主站、PTP/gPTP 时间同步、系统 OTA(AB/BAK+overlayfs)与 miniboot 单独升级）
- [硬件与系统参考(详细章节)](references/hardware-notes.md)
