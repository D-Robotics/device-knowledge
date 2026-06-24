# RDK 板端委派与 S100 大小脑协同 · 硬件与系统参考

> 来源:整理自 D-Robotics RDK 官方文档、工具链与社区实践,逐条保留出处链接;由 device-knowledge 知识库忠实转换而来,未改写技术事实。

本文汇集本 skill 涉及的 RDK 硬件/系统章节,逐节整理自官方文档与实践,供需要细节时查阅。

## S100 "大小脑异构" 与 MCU 协同（具身智能关键）

S100 和 X 系列最大的**设计哲学差异**：不是算力堆得更高，而是 **CPU + BPU + MCU 三块异构**，"感知-决策-控制"在单 SoC 内闭环。

**三块的分工**：

| 计算单元 | 硬件 | 典型任务 | 开发者接触面 |
|----------|------|----------|--------------|
| **"大脑" CPU** | 6x A78AE @1.5GHz (S100) / 2.0GHz (S100P) | Linux 应用、ROS2 节点、AI 任务编排 | 用户主要写代码的地方，Ubuntu 22.04 |
| **"决策" BPU** | Nash 80 TOPS (S100) / 128 TOPS (S100P) | LLM / VLM / 目标检测 / 分割 / 点云 | 模型经天工开物/OE 转 `.hbm` 后部署，走 `hbm_runtime` / BPU runtime（非 X 系列的 `.bin`+`hobot_dnn`） |
| **"小脑" MCU** | 4x R52+ @1.2GHz | 关节实时控制（ms 级）、IMU 预处理、电机回路 | 需要单独固件，走 IPC 与 CPU 通信；不是普通 Linux 程序 |

**MCU 的关键特性**（用户常忽视）：
- **S100 = 4 核 R52+(1× DCLS + 1× Split-Lock)**;**S600 = 6 核 R52+(1× DCLS + 2× Split-Lock)**（可独立 / 可锁步，按安全需求选）
- 运行 RTOS / 裸金属固件，不运行 Linux
- 与 CPU 通过 IPC（shared memory + 通知）交互，可达 kHz 级回路
- 官方宣传："CPU 占用率下降 80%"——因为关节控制从 Linux 实时线程卸到了 MCU

**S100 与 X5 典型机器人链路对比**：

```
X5 机器人（传统）：
  CPU (Linux) → [ROS2 节点调用 BPU 推理] → [ROS2 节点发 velocity cmd]
                                          → [Linux RT 线程 PID 电机回路]  ← 抖动、抢占
                                          
S100 机器人（推荐）：
  CPU (Linux) → [ROS2 + BPU 推理 + 规划] → [IPC → MCU]
                                                  ↓
                                      MCU (RTOS) → [电机驱动器 PWM/CAN]  ← 硬实时
```

**开发者实操要点**：
- MCU 固件**不在 `apt`** 里，是独立工具链烧录（通过 JTAG 或 S100 的 Type-C 调试口）
- Main Domain / MCU Domain 两个独立 UART 调试口，别弄混
- 要上手 MCU：到 D-Robotics GitHub 按 `s100-` 前缀 + MCU/firmware 关键词找 SDK/RTOS 固件仓（可借 rdk-source-map 定位），仓库名与烧录步骤以官方 rdk_s_doc / S100 用户手册为准；纯视觉应用用户可以暂不碰 MCU，只当 BPU 算力板用
- 相机走扩展板（MIPI 多路 4-lane 或 GMSL，具体路数以官方 S100 硬件手册为准），裸板**没有**直接的相机接口

**S100 vs S100P 买哪个**：
- S100 (12GB, 80 TOPS, A78AE @1.5GHz) → 7B 级量化 LLM、主流 VLM、双足/四足本体
- S100P (24GB, 128 TOPS, A78AE @2.0GHz) → 更大模型/VLM 原型、多路 GMSL、严肃科研；具体模型上限以官方 Model Zoo / hobot_llm 文档为准
