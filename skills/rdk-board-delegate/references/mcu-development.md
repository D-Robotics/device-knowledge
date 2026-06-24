# RDK S 系列 MCU(小脑)开发参考

> 来源:D-Robotics 官方文档 rdk_s_doc `docs/07_Advanced_development/05_mcu_development/`(00_code_release / 01_basic_information / 02_MCU_build_system / 03_FreeRTOS_development / 04_mcu_uart / 08_mcu_ipc / 12_mcu_port / 13_mcu_ramdump),以及 `docs/01_Quick_start/01_hardware_introduction/`。在线版:https://developer.d-robotics.cc 。本文逐条保留出处,只写文档里有出处的事实,未改写技术结论。

适用板型:**RDK S100 / S100P / S600**(Nash BPU、`.hbm`)。X3/X5/Ultra 无此 MCU 子系统,不适用本文。

---

## 0. 一句话先讲清:S 系列的"MCU 开发"到底是开发什么

S 系列 SoC 内有一块 **R52+ 实时核 MCU**,跑 **FreeRTOS**(不是 Linux),负责硬实时控制(关节/电机/IMU/CAN)。它在固件层又分成两半:

| | MCU0 | MCU1 |
|---|---|---|
| 职责 | 启动 Acore(Linux)、启动/关闭 MCU1、电源管理(PMIC/休眠唤醒)、OTA、Boot、SCMI | 跑**用户业务**:实时控制、CAN/SPI/I2C/UART、IPC 应用 |
| 开源 | **否**,企业版专有,默认只给地瓜验证过的 bin | **是**,客户可改可编译 |
| 客户改不改 | **不要动**(改了可能开不了机) | 这才是你写代码的地方 |

> 来源:01_basic_information.md「范围」「基础信息」。
> 工具链/系统版本(来源同上「基础信息」):
> - 编译工具链 GCC:`gcc-arm-none-eabi-10.3~2021.10`
> - MCU 核:ARM **R52+**(参考 ARM R52 TRM https://developer.arm.com/documentation/100026/latest )
> - OS:**FreeRTOS Kernel V10.0.1**
> - 编译用 Python:3.8.10;编译系统:**Scons 3.0.0**

所以"MCU 开发"= 改 **MCU1** 的 FreeRTOS 业务固件 → 交叉编译出 `.elf` → 通过 **Linux remoteproc** 加载到 MCU1 → 用共享串口 / sysfs 看 log 调试。**日常迭代不需要 JTAG,也不需要烧 flash**(见 §3)。

---

## 1. 开发环境与工具链

> 来源:01_basic_information.md「开发环境」「编译 MCU 系统」。

- 交叉编译:主机(推荐 **Ubuntu 22.04**,与板端系统版本对齐)上编译,产物推到板端运行。
- 主机依赖安装:

```bash
sudo apt-get install -y build-essential make cmake libpcre3 libpcre3-dev bc bison \
    flex python3-numpy mtd-utils zlib1g-dev debootstrap \
    libdata-hexdumper-perl libncurses5-dev zip qemu-user-static \
    curl repo git liblz4-tool apt-cacher-ng libssl-dev checkpolicy autoconf \
    android-sdk-libsparse-utils mtools parted dosfstools udev rsync python3-pip scons
pip install "scons>=4.0.0"   # 注:正文另述编译系统基于 Scons 3.0.0,以官方实际下发为准
pip install ecdsa tqdm
```

- **工具链获取**:首次编译会从 ARM 官网下载 GCC 工具链并解压(约 10 分钟),网络差易失败。可改为手动下载后放入 `Build/ToolChain/Gcc/`,编译时检测到已存在就不再联网下载。工具链下载入口见官方 download 页「工具下载」。

---

## 2. 编译 MCU1 固件

### 2.1 代码包结构

> 来源:00_code_release.md。社区版只给驱动/Service 的头文件 + 静态库 + samples;企业版才给 McalCdd/Service/Platform 源码。

社区版顶层目录:`Build`(编译/链接脚本) `Config`(各 board 的 McalCdd 配置) `Include` `Library`(驱动/Service 静态库) `OpenSource`(FreeRTOS) `output`(产物) `samples`(Can/IPC/Eth 等示例) `Target`(启动/任务/中断基础代码)。

### 2.2 编译命令(S100 与 S600 参数顺序不同!)

> 来源:01_basic_information.md「编译 MCU 系统」。两板共用 `build_freertos.py`,但参数顺序不一样,易踩坑。

```bash
# 进入 MCU1 编译目录(两板相同)
cd mcu/Build/FreeRtos_mcu1

# RDK S100:  ... s100 mcu1 gcc <debug|release>
python build_freertos.py lite matrix B s100 mcu1 gcc debug
python build_freertos.py lite matrix B s100 mcu1 gcc release

# RDK S600:  ... s600 gcc mcu1 <debug|release>   (gcc 与 mcu1 顺序与 S100 相反)
python build_freertos.py lite matrix B s600 gcc mcu1 debug
python build_freertos.py lite matrix B s600 gcc mcu1 release
```

- `debug` 版含调试信息与较多 log;`release` 不含调试信息、log 较少。
- 产物 `.elf` 即 MCU1 firmware(下一步要推到板端的就是它):
  - S100:`output/debug/S100_MCU_SIP_V2.0/S100_MCU_DEBUG.elf`
  - S600:`output/debug/S600_MCU_Matrix_V2.0/S600_MCU_DEBUG.elf`(release 为 `S600_MCU_RELEASE.elf`)

### 2.3 编译系统重点文件(需要增删编译目录/改链接时看)

> 来源:02_MCU_build_system.md。

- 入口脚本 `build_freertos.py` → 调度 Scons。影响编译的关键文件:
  - **SConstruct**(S600 是统一入口 `SConstruct`;S100 是 `SConstruct_Lite_FRtos_S100_sip_B`)= 编译定义文件。
  - **settings_*.py**(S100 `settings_freertos.py` / S600 `settings_files/gcc/settings_lite_freertos.py`)= 编译环境变量,内含 `COMPILER_TOOL`。
  - **gcc_arm.py** = 实际编译命令定义(CC 等)。
  - **S600 专有**:`build_config/S600/lite-matrix-B-mcu1.yaml` = 被编译的文件夹清单 + `LinkFIle` 指向链接脚本。
- 增加编译目录:
  - S100:改 `SConstruct_Lite_FRtos_S100_sip_B`,在被编译模块下放一份 `SConscript`(可从任一已编译模块拷)。
  - S600:改 `build_config/S600/lite-matrix-B-mcu1.yaml`,同样需补 `SConscript`。
- 链接脚本:`Build/FreeRtos_mcu1/Linker/gcc/<S100|S600>/link_freertos_mcu1.ld`。
- MCU1 镜像 layout(MEMORY 区)关键区域**强烈不建议客户修改**:`LOG_SHARE_Reserved`、`SCMI_IPC_Reserved`、`FREERTOS_HEAP`,以及共享关键地址 `MCU_STATE_START_ADDR`(`0x0C800800`)。要调 `FLASH`/`CAN_Reserved` 等先咨询地瓜。FreeRTOS 内存方案两板都用 **heap_4.c**。

---

## 3. 加载/烧录:MCU1 走 remoteproc,MCU0 才走 fastboot/Xburn

这是最容易混淆的点。**两套机制完全不同**:

### 3.1 MCU1(日常):Linux remoteproc 加载 `.elf`,不需要烧 flash

> 来源:01_basic_information.md「MCU1启动/关闭流程」。MCU1 由 Acore 经 remoteproc 框架通知 MCU0 来启停。

```bash
# 1) 把编译出的 .elf 推到板端 /lib/firmware/(scp 或 adb push)
#    例:scp S100_MCU_DEBUG.elf root@<board>:/lib/firmware/

# 2) 板端启动 MCU1
cd /sys/class/remoteproc/remoteproc_mcu0
echo S100_MCU_DEBUG.elf > firmware   # S600 换成 S600_MCU_DEBUG.elf
echo start > state

# 3) 停止 MCU1
echo stop > state
```

> [!CAUTION]
> **stop 之后必须等系统进入 wfi 模式才能再 start**。否则 start 会把 firmware 重新加载到 MCU SRAM、覆盖正在运行的代码,导致系统跑飞挂死。来源:01_basic_information.md 同节 `:::caution`。

- MCU1 异常(Undefined/Abort)后会陷入死循环/shell;S 系列**不能对 MCU1 单独上下电**,恢复方式就是 `echo stop > state` 让它进 wfi,再 `echo start`(见 13_mcu_ramdump.md「异常后重启 MCU1」)。
- S600 的 stop/start 与同步异常是两条独立路径,且 `main.c` 中的 `EL1_Undefined_Handler` 当前**未**挂到向量表(已知问题,计划下版修复)——分析 S600 异常时注意别认错处理函数。来源:01_basic_information.md S600 DocScope。

### 3.2 MCU0(很少碰):fastboot 或 Xburn 烧 flash

> 来源:01_basic_information.md「MCU0烧录流程」。MCU0 镜像仅企业版提供。

```bash
# 非空板:Acore 串口狂按 enter 进 uboot
fastboot 0
fastboot oem interface:mtd
# S100 镜像 MCU_S100_SIP_V2.0.img / S600 镜像 MCU_S600_Matrix_V2.0.img
fastboot flash MCU_a "xxx/MCU_S100_SIP_V2.0.img"
fastboot flash MCU_b "xxx/MCU_S100_SIP_V2.0.img"
```

- **空板烧录**:用 **Xburn** 工具指定区域烧录,并指定 `miniboot_flash`(指定区域烧录步骤见各板 Quick_start 的 xburn 章节)。

### 3.3 JTAG / Type-C 调试口

- JTAG 信号在 MCU PIN 表上确有引出:S100 为 `JTG_TCK/TRSTN/TMS/TDI/TDO` = `GPIO_MCU[72..76]`(来源:12_mcu_port/01_user_manual.md PIN 表)。
- JTAG 主要用于裸机/底层 bring-up 与故障注入级调试;**绝大多数 MCU1 业务开发用 §3.1 的 remoteproc 即可,无需 JTAG**。具体 JTAG 接线/调试器型号以官方 S100/S600 硬件手册为准(本仓未取到该细节,见 uncertainties)。

---

## 4. 串口(UART):调试控制台 vs 业务/透传串口

> 来源:04_mcu_uart.md、01_basic_information.md「MCU 串口使用」。

### 4.1 调试控制台(看 log、敲 shell 命令)

- **MCU0 与 MCU1 共用同一个调试串口(MCU-COM)**,波特率 **921600**,8-N-1。设备管理器里认 `MCU-COM`。
  - S100:MCU 共 3 路 UART(Uart4~Uart6),**Uart4 作调试控制台**。
  - S600:MCU 共 4 路 UART(Uart8~Uart11),**Uart8 作调试控制台**。
- Acore 侧也能读 MCU log:`/proc/remoteproc_mcu0`、`/proc/remoteproc_mcu1`(来源:01_basic_information.md「MCU Log 简介」)。MCU Log 当前仅支持 `%s %d %u %x %X %c`。

> [!IMPORTANT]
> **"Main Domain UART" 与 "MCU Domain UART" 是两个不同的调试口,别接错。** Acore(Linux,大脑)的串口和 MCU(小脑)的 MCU-COM 是分开的;委派 OpenClaw 排查"看不到 log"时先确认插的是哪一个。

### 4.2 业务/示例串口

- S100:引出 **Uart5**(Main Board `MCU Expansion Header (J22)`)供学习。
- S600:引出 **Uart10/Uart11**(Main Board `2x UART(MAIN)/2x UART(MCU) (J18)`)。
- 测试命令 `uarttest`(在 MCU shell 里敲):
  - S100:`uarttest 1` 自环(RX 接 TX)、`2` 收、`3` 发、`5`/`6` 改波特率(9600/115200)。
  - S600:`uarttest 0 11 921600 0 1 8`(配置指定通道)、`1` 默认初始化、`2` 收、`3` 发、`4` 回环。
- 主要 API:`Uart_Init/Deinit`、`Uart_BaudSet/Get`、`Uart_SetDatabits/Stopbit/Parity`、`Uart_SyncDataTrans/Receive`(阻塞)、`Uart_AsyncDataTrans/Receive`(非阻塞),返回 `E_OK/E_NOT_OK`。
- DMA 模式下收发 buffer 地址须 **64 字节对齐**。

> [!TIP]
> S100 的 Uart5 既是学习串口、又可能被 **IpcBox 透传**占用,冲突会导致 `uarttest` 失败。在 MCU shell 用 `ipcbox_set_mode debug` 看 `uart` 行是否 `Enable`,若占用先 `ipcbox_set_mode uart 0` 释放。来源:04_mcu_uart.md `:::tip`。

---

## 5. IPC:大脑(Acore)与小脑(MCU)之间怎么通信

> 来源:08_mcu_ipc.md(MCU 侧);Linux 侧原理见 `02_linux_development/04_driver_development_super/06_driver_ipc.md`。

### 5.1 机制

- IPC = **共享内存 + MDMA 搬运 + notify 中断**。数据流:`Acore <-> IPC <-> MCU`。
- 以 **Instance** 为单位,一个 Instance 含一个或多个 Channel,**同一 Instance 共享一个中断**,因此一个 IPC Instance 只能在 MCU0 **或** MCU1 其中一侧使能(两侧都使能会互相抢占导致通信失败)。
- 关键约束(踩坑点,来源「使用限制说明」):
  - `Ipc_MDMA_SendMsg` 的数据 buffer 地址须 **16 字节对齐**(示例:`static uint8 __attribute__((aligned(16))) Ipc_Send_Buf[8192];`)。
  - 发送靠轮询 DMA 状态 → 发送前必须**关 DMA 中断**;接收时把 DMA 中断与 IPC 中断配成**同优先级**避免互相打断。
  - MDMA 发送通道只有 2 个,多核/多任务发送要用自旋锁或关中断防抢占。
  - 两端(MCU 与对端)的 Instance 控制段/data 段地址、Channel 数量与 ID、Buffer 大小**必须一致**,否则通信失败。
  - `receive_coreid` 要写对:Instance 工作在 MCU1 就配 `Ipc_Receive_Core1`,且 IPC 中断在哪个核工作就在哪个核使能。

### 5.2 配置两要素(MCU1 用 IPC 时)

> 来源:08_mcu_ipc.md「IPC 配置相关」。

1. **回调函数**:IPC 收到 notify → 触发中断进回调。在 `Ipc_ChannelConfigType` 里配 `RxCallback`(及可选 `TxErrCallback`)。
2. **receive_coreid**:在 `Ipc_InstanceConfigType` 配 `.receive_coreid = Ipc_Receive_Core1`,并保证 MCU0 侧对应配置一致。
   - MCU0 配置:`mcu/Config/McalCdd/gen_s100_sip_B/Ipc/src/Ipc_Cfg.c`
   - MCU1 配置:`mcu/Config/McalCdd/gen_s100_sip_B_mcu1/Ipc/src/Ipc_Cfg.c`

### 5.3 MCU 侧 IPC API

> 来源:08_mcu_ipc.md「应用程序接口」。

- `Ipc_MDMA_Init(pConfigPtr, InstanceId)` / `Ipc_MDMA_DeInit(InstanceId)`
- `Ipc_MDMA_OpenInstance(InstanceId)` / `Ipc_MDMA_CloseInstance(InstanceId)`
- `Ipc_MDMA_CheckRemoteCoreReady(InstanceId)`(对端就绪检查)
- `Ipc_MDMA_SendMsg(InstanceId, ChanId, Size, Buf, Timeout)`(同步发送,返回 `E_OK` 或 `IPC_E_*` 错误码)
- `Ipc_MDMA_PollMsg(InstanceId)`(不使用中断接收时轮询)
- `Ipc_MDMA_TryGetHwResource(InstanceId, ChanId, BufSize)`

### 5.4 IpcBox 外设透传框架 + 可直接跑的 sample

> 来源:08_mcu_ipc.md「IpcBox 功能介绍」「应用 sample」。**sample 跑在 Acore 侧,需先启动 MCU1(见 §3.1)**。

IpcBox 把 RunCmd / SPI / I2C / UART 外设统一接入 IPC 转发:`Acore <-> IPC <-> MCU <-> Peri`。开机默认**关闭**(会占外设资源),按需打开。

```bash
# 查看各透传模块使能情况
ipcbox_set_mode debug
# 临时开/关某外设透传(1=开 0=关)
ipcbox_set_mode uart 1
ipcbox_set_mode i2c 1
ipcbox_set_mode spi 1
# 日志级别 0=NO_LOG 1=ERROR 2=WARN 3=INFO 4=DEBUG
ipcbox_loglevel 4
```

- 永久打开:改 `Service/HouseKeeping/ipc_box/src/ipc_box.c` 里 `IpcBox_InstanceMap[]` 把对应外设 `DISABLE` 改 `ENABLE`。
- 透传数据包 `IpcBoxPacket_t`(默认 128 字节,含 magic/version/checksum/length/cmd/data[])。
- I2C/SPI 透传的 get/set 因从设备各异,需客户实现 `IpcBox_I2cGetValue/SetValue`(`Service/HouseKeeping/ipc_box/src/ipc_i2c.c`)。
- **RunCmd** 透传:Acore 下发命令 → MCU 常驻线程读队列、解析、执行 cmd(类似 uboot cmd),可很方便定制 MCU 侧应用(例:读 ADC 值再经 IPC 回传)。

---

## 6. FreeRTOS 业务怎么写(MCU1)

> 来源:03_FreeRTOS_development.md、01_basic_information.md「MCU1 main 函数简介」。

- **main 流程关键**(勿删):`Uart_Init → Log_Init → (Shell_Init) → Version_into_AonSram → FreeRtos_Irq_Init → FreeRtos_Task_Init`。S600 的 main 按 `GetCurrentCoreID()` 分 core0(初始化+建任务)/core1(休眠/唤醒循环)两支。
- 启动方式:S100/S600 都在 main 里完成硬件+RTOS 初始化+建所有任务后再启动调度器(FreeRTOS 第一种启动方式)。
- 任务创建在 `Target/.../FreeRtosOsHal/Task_Hal.c`;任务体在 `Target/.../HorizonTask.c`。周期任务命名如 `OsTask_SysCore_BSW_10ms`/`ASW_xms`,**集成时保持各功能的相对优先级、所在 core、同任务内调用顺序**。可在已有任务里挂自己的 demo。
- 中断:集中配在 `FreeRtosOsHal/Isr_Hal.c` 的 `FreeRtos_Irq_Init()`(装 handler、设优先级、enable)。完整中断号-模块表见 03_FreeRTOS_development.md(S100 32~370、S600 32~523)。
- **中断冲突铁律**:MCU0/MCU1 同处一个硬件域、同一中断两核都能收到,**同一中断只能由 MCU0 或 MCU1 之一使能**;MCU1 使能某中断前必须确保 MCU0 对应中断已关。
  - 已被 MCU0 占用的中断清单见 03_FreeRTOS_development.md「MCU 中断使用情况」,MCU1 开发避开它们。
- 系统服务任务(集成注意,来源 03 同文):`ScmiProcess` 放高优先级(建议 2ms,最长别超 100ms);`AcoreBootProc`/`OtaFlash_MainFunction` 因都用 flash,放**同一个低优任务串行**避免 flash 并发冲突,且须在 MCU0 上处理。

---

## 7. 调试:看 log、查存活、抓 crash

> 来源:01_basic_information.md「MCU 在 sysfs 上 debug 功能介绍」、13_mcu_ramdump.md。

- sysfs 节点(`/sys/class/remoteproc/remoteproc_mcu0|mcu1` 下):
  - `alive`(MCU0/MCU1 alive/dead,1s 刷新)、`taskcounter`(存活秒数)、`mcu_version`、`sbl_version`(仅 mcu0)、`cpuloads`(各任务优先级/剩余栈/运行次数/使用率,需 MCU 已上电,有 1s 延迟)、`firmware`、`state`(offline/running)、`recovery`(coredump 使能)。
- **ramdump / crash**:
  - MCU1 异常 → 陷 shell;读现场信息:`cat /sys/devices/platform/soc/soc:mcu_crash/crash`。
  - MCU0 异常 → 系统重启,若重启原因为 `mpainc` 则保留现场并转储到 `/log` 分区,目录形如 `SuperSoC_Mdump-0010-2025_08_13_20_25_11`。
  - **注意**:MCU0/MCU1 的 crash 共享一块内存,两者**同时**异常时 ramdump 数据不可用。
- 共享内存读数据不同步问题:Acore 侧读 MCU 写入的 SRAM 变量须加 `volatile` 或用 `ioremap_np()`,否则可能读到旧缓存(来源:03_FreeRTOS_development.md「MCU 与 Acore 共享内存区域预留」)。

---

## 8. Port(PIN 复用)与外设驱动一览

> 来源:12_mcu_port/01_user_manual.md;各外设独立章节 04~17。

- Port 子系统配 PIN 功能/属性。功能配置:`Port_SetFunctionPins(PORT_FUNC_SPI5)` 之类(枚举见 `McalCdd/Port/inc/Port_Func.h`)。
- GPIO 操作:`Port_SetGpioByIndex / Port_GpioDirectionOutput/Input / Port_GpioGetValue`,PinIdx 用 PIN 表序号。
- **GPIO 黑名单**:部分 PIN(电源相关、debug uart、HSM uart 等)在 `Port_Func.c` 的 `Gpio_Blacklist[]` 里禁止操作——委派改 GPIO 前先查黑名单,别动到电源脚把板子搞挂。
- MCU 侧外设章节(同目录):`04_mcu_uart` `05_mcu_pwm` `06_mcu_spi` `07_mcu_adc` `08_mcu_ipc` `09_mcu_can` `10_mcu_i2c` `11_mcu_eth` `13_mcu_ramdump` `14_mcu_ICU` `15_mcu_timer` `16_mcu_watchdog` `17_mcu_ethercat`。CAN 是机器人关节总线主力(S100 用到 Can0~9,S600 用到 Can1~10/Can1~15)。

---

## 9. S100 vs S600 MCU 差异速查

> 来源:综合 01/02/04/08/12 各文 DocScope。

| 维度 | RDK S100 | RDK S600 |
|---|---|---|
| MCU UART 路数 / 调试口 | 3 路 Uart4~Uart6,**Uart4** 控制台 | 4 路 Uart8~Uart11,**Uart8** 控制台 |
| 业务示例 UART | Uart5(J22) | Uart10/Uart11(J18) |
| 编译参数顺序 | `... s100 mcu1 gcc <debug\|release>` | `... s600 gcc mcu1 <debug\|release>` |
| 编译入口 | `SConstruct_Lite_FRtos_S100_sip_B` | `SConstruct` + `build_config/S600/lite-matrix-B-mcu1.yaml` |
| 固件 elf | `S100_MCU_SIP_V2.0/S100_MCU_DEBUG.elf` | `S600_MCU_Matrix_V2.0/S600_MCU_DEBUG.elf` |
| MCU0 镜像 | `MCU_S100_SIP_V2.0.img` | `MCU_S600_Matrix_V2.0.img` |
| FLASH 区大小(layout) | FLASH 2154K + 独立 FREERTOS_HEAP 512K | FLASH 2666K(HEAP 起始地址不同 0x0CE00000) |
| MCU core 数 | 单 core 业务(main 直接初始化) | core0/core1 分工(main 按 coreID 分支) |
| CAN(MCU1) | Can0~Can9 | Can1~Can10(部分文档列 Can1~Can15) |
| 中断号范围 | 32~370 | 32~523 |
| 异常处理已知问题 | — | `main.c` 的 `EL1_*_Handler` 未挂向量表,实际走 `HorizonHook.c` 的 `User_*_Handler`(待修) |

两板相同点:GCC `10.3~2021.10`、R52+、FreeRTOS V10.0.1、heap_4.c、MCU1 走 remoteproc 加载、调试口 921600 共用、IPC 共享内存+MDMA、`MCU_STATE_START_ADDR=0x0C800800`。

---

## 10. 委派 OpenClaw 排查 MCU 问题时,交接信息怎么填

把本文事实落到 §「OpenClaw 工作交接」五要素上:

- **目标**:一句话,如"让 MCU1 重新加载我新编的固件并确认 IPC 通"。
- **背景**:板型(S100/S100P/S600)+ debug/release + 当前 `state`(offline/running)。
- **已做的事**:贴 `ipcbox_set_mode debug`、`cat /sys/.../mcu_version`、remoteproc `echo start` 的**实际输出**。
- **分析**:比如"stop 后没等 wfi 直接 start 导致跑飞"(§3.1 CAUTION)、"中断 MCU0/MCU1 双使能冲突"(§6)、"IPC 两端 buffer size 不一致"(§5.1)。
- **期望**:要 MCU 串口 log / `crash` 节点内容 / 某 sysfs 值。
