# RDK 专属命令详表(9.1 RDK专属命令用法)

> 来源:`D-Robotics/rdk_doc` `docs/09_Appendix/rdk-command-manual/`(X 系列)与 `docs_s/09_Appendix/rdk-command-manual/`、`D-Robotics/rdk_s_doc` `docs/09_Appendix/rdk-command-manual/`(S 系列),分支 main。逐条转述官方,未改写。
>
> 文档站 URL 规律(去掉路径里的数字前缀):
> - X 系列:`https://developer.d-robotics.cc/rdk_doc/Appendix/rdk-command-manual/cmd_<name>`
> - S 系列:`https://developer.d-robotics.cc/rdk_doc/rdk_s/Appendix/rdk-command-manual/cmd_<name>`

---

## hrut_somstatus — 温度 / 频率 / BPU 负载

- **作用**:获取温度传感器温度、CPU\BPU 运行频率以及 BPU 负载。
- **语法**:`sudo hrut_somstatus`
- **适用板型**:全板通用(X3/X5/Ultra/S100/S100P/S600)。
- **X 系列输出**:`temperature`(CPU 温度) + `cpu frequency`(每核 min/cur/max) + `bpu status information`(bpu0/bpu1 的 min/cur/max/ratio,ratio=BPU 负载率)。
- **S 系列(S100)输出差异**:温度为多路 PVT —— `pvt_cmn_pvtc1_t1/t2`(CPU)、`pvt_mcu_pvtc1_t1/t2`(MCU)、`pvt_bpu_pvtc1_t1`(BPU);并多出 `voltage` 段(VDD_CPU/VDD_BPU/VDD_DDRx/VDDIO_* 等多条电压轨,单位 mV);`cpu frequency` 以 `policy0/policy4` 簇为单位;`bpu status` 仅 `bpu0: ratio`。
- **典型用法**:快速看板子温度是否过高、BPU 当前是否被占用(ratio)。
- **出处**:X `docs/09_Appendix/rdk-command-manual/cmd_hrut_somstatus.md`;S `docs_s/.../cmd_hrut_somstatus.md` 与 `rdk_s_doc docs/.../cmd_hrut_somstatus.md`。

---

## hrut_boardid — 开发板编号

- **作用**:获取(或设置)当前开发板编号,不同开发板编号不同。
- **⚠️ 警告**:boardid 会影响启动时硬件初始化,**请谨慎设置**。

### X3 变体(`cmd_hrut_boardid.md`)

```
Usage:  hrut_boardid [OPTIONS] <Values>
  g  从 veeprom 获取 board id
  s  从 veeprom 设置 board id
  G  从 bootinfo 获取 board id
  S  从 bootinfo 设置 board id
  c  清除 veeprom 中的 board id 配置
  C  清除 bootinfo 中的 board id 配置
  h  帮助
```

boardid 为 32bit 位域,含:auto detect[31]、model[30:28](DDR 厂商:hynix/micron/samsung)、ddr_type[27:24](LPDDR4/LPDDR4X/DDR4/DDR3L)、frequency[23:20]、capacity[19:16](1G/2G/4G)、ecc[15:12]、som_type[11:8](sdb v3/v4、RDK X3 v1/v1.2/v2、RDK Module、X3E)、DFS EN[7]、alternative[6:4]、base_board_type[3:0](X3 DVB/X3 SDB/customer board)。完整取值见 `cmd_hrut_boardid.md`。

### X5 变体(`cmd_hrut_boardid_rdkx5.md`)

```
hrut_boardid -h
  hrut_boardid: prints current boardid
  -h: Print this message
```
仅打印当前 boardid,无 X3 的 get/set/clear 子选项。

### S 系列变体

直接 `hrut_boardid` 输出形如 `0x6A84`,编码:`6A`=芯片代号、`8`=板级电源设计、`4`=板级设计版本。

- **出处**:X3 `cmd_hrut_boardid.md`;X5 `cmd_hrut_boardid_rdkx5.md`;S `rdk_s_doc docs/09_Appendix/rdk-command-manual/cmd_hrut_boardid.md`。

---

## hrut_socuid — SoC UID

- **作用**:打印当前 SoC 芯片的 uid(唯一标识符)。
- **语法**:`hrut_socuid`(X3 文档示例用 `sudo hrut_socuid`)。
- **示例**:X 系列 `soc_uid: 0x210627120003012002160908030307`;S 系列 `060c0b0d3090694108255c4c00001079`。
- **出处**:`cmd_hrut_socuid.md`(X 与 S)。

---

## hrut_ps — 进程详细信息

- **作用**:打印 busybox `ps` 不支持的进程信息。
- **语法**:`hrut_ps`
- **字段**:pid、ppid、state(I/R/S/D/T/X/Z/t/P)、prio、nice、rt_prio、policy(调度策略)、vsize(虚拟内存)、rss(物理内存)、comm(命令名)。
- **出处**:`cmd_hrut_ps.md`(X 与 S)。

---

## rdkos_info — 系统信息一键收集

- **作用**:一次性收集 RDK 系统软硬件版本、驱动加载清单、RDK 软件包安装清单和最新系统日志,便于快速获取系统状态(排障时收集信息首选)。
- **语法**:`sudo rdkos_info [options]`
- **选项**:
  - `-b` 基础模式,**不收集系统日志**
  - `-s` 简洁模式(**默认**),输出最新 30 行系统日志
  - `-d` 详细模式,输出最新 300 行系统日志
  - `-v` 显示版本信息
  - `-h` 显示帮助
- **输出含**:`[Hardware Model]`、`[CPU And BPU Status]`、`[Total/Used/Free Memory]`(X 系列还有 `[ION Memory Size]`)、`[RDK OS Version]`、`[RDK Kernel Version]`、`[RDK Miniboot Version]`。
- **出处**:`cmd_rdkos_info.md`(X 与 S)。

---

## rdk-miniboot-update — 更新最小启动镜像

- **作用**:更新 RDK 硬件的最小启动镜像(miniboot)。
- **语法**:`sudo rdk-miniboot-update [options]... [FILE]`
- **选项**(均可选;不带参数则用最新版本 miniboot 升级):
  - `-f` 安装指定文件,而非最新更新
  - `-h` 帮助
  - `-l` 打印将要使用的最新 miniboot 镜像完整路径(预览不带参数时用哪个镜像)
  - `-s` 静默(不显示进度)
- **典型用法**:`sudo rdk-miniboot-update`(升级到最新);`sudo rdk-miniboot-update -f /userdata/miniboot.img`(指定镜像);`rdk-miniboot-update -l`(查看默认镜像路径)。
- **出处**:`docs/09_Appendix/rdk-command-manual/cmd_rdk-miniboot-update.md`(X 系列)。

---

## rdk-backup — 系统备份成镜像

- **作用**:将当前系统备份成镜像。
- **语法**:`sudo rdk-backup [dir]`
- **参数**:`[dir]` 为生成和挂载镜像的打包目录,默认 `/mnt`;打包目录在制作镜像时会被忽略。
- **前置**:**执行前需先联网**,过程中会下载安装所需工具。
- **产物**:打包目录下生成 `rdk-<时间和日期>.img`。
- **出处**:`docs/09_Appendix/rdk-command-manual/cmd_rdk-backup.md`(X 系列)。

---

## devmem — 读写物理寄存器

- **作用**:busybox 命令,经 `/dev/mem` 的 mmap 把设备内存映射到用户空间,读写物理地址。
- **语法**:`devmem ADDRESS [WIDTH [VALUE]]`
  - `ADDRESS` 必填,目标物理地址
  - `WIDTH` 可选,位宽 8/16/32,**默认 32**
  - `VALUE` 可选,提供即写、不提供即读
- **示例**:读 `devmem 0xa600307c 32`;写 `devmem 0xa6003078 32 0x1000100`。
- **出处**:`cmd_devmem.md`(X 与 S,内容一致)。

---

## srpi-config — 系统配置工具

- **作用**:系统配置 TUI;桌面系统下也可用菜单里的 `RDK Configuration` 图形入口打开同样的配置终端。
- **语法**:`sudo srpi-config`(必须 sudo,默认 `sunrise` 账号无系统文件修改权限)。
- **适用板型**:官方注明 X 系列仅适用 `RDK X3`、`RDK X5`、`RDK X3 Module`,**不适用 RDK Ultra**;S 系列(S100)文档同样提供 srpi-config。
- **主要菜单**(以 X 系列文档为准):
  - **System Options**:Wireless LAN、Password、Hostname、Boot/Auto login、Power LED、Browser。
  - **Display Options**:FB Console Resolution、Display Choose DSI or HDMI(仅 RDK X5 支持切换显示屏)。
  - **Interface Options**:SSH、VNC、Peripheral bus config(40pin 上 SPI/I2C/Serial/I2S,X5 增加 PWM;同一行接口共用引脚、同时只能生效一种)、Configure Wi-Fi antenna(板载 trace / 外置 cable)、Audio(音频转接板)。
  - **Performance Options**:CPU frequency(超频,默认不建议)、ION memory(默认 672MB)。
  - **Localisation Options**:Locale、Time Zone、Keyboard。
  - **Advanced Options**:Expand Filesystem、Network Proxy Settings、Boot Order(X3 Module/X5 Module 在 eMMC 与 SD 卡间切换启动)。
  - **Sensor Profiles**:多套 Sensor 效果库(如 IMX219 切换 ISP 效果库)。
  - **Update / About / Finish**。
- **出处**:X `docs/02_System_configuration/02_srpi-config.md`;S `docs_s/02_System_configuration/02_srpi-config.md`。(注:文档归在 `02_System_configuration`,非 09_Appendix,但属 RDK 专属系统命令,一并收录。)

---

## 烧录 / OTA 相关(指回官方,不在本表展开)

命令手册附录未把烧录工具逐条列入 9.1,实际烧录/升级流程散在快速开始与高级开发章节,需要时指回:

- **S 系列烧录工具 xburn**:`rdk_doc docs_s/01_Quick_start/02_install_os/rdk_s100(/rdk_s600)/03_xburn/`(Windows/Linux/Mac 三平台)。
- **OTA miniboot**:`rdk_doc docs_s/07_Advanced_development/02_linux_development/06_OTA/02_ota_miniboot.md`(配合 `rdk-miniboot-update`)。
- **X 系列系统烧录**:`docs/01_Quick_start/install_os/rdk_x3(_module)/`、`rdk_x5(_module)/` 下 `01_system_burn / 02_nand_flash_firmware / 03_boot_system`。
