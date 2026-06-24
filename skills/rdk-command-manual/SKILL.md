---
name: rdk-command-manual
description: 当用户要查某条 RDK 专属命令或系统命令的语法/作用/选项/适用板型时使用,如 hrut_somstatus 怎么读、hrut_boardid 各选项含义、rdkos_info -d 输出什么、rdk-miniboot-update/rdk-backup 怎么用、srpi-config 有哪些菜单、devmem 怎么读写寄存器,以及 Linux 常用命令(apt/dmesg/ip/scp/tar 等)在 RDK 文档里的索引。本 skill 是"命令手册查询"入口(命令为锚点查语法);出了报错要按现象排障走 rdk-board-knowledge,外设驱动配置走 rdk-peripheral-cookbook,GitHub 源码仓定位走 rdk-source-map,官方文档站章节定位走 rdk-doc-finder。
---

# RDK 命令手册(RDK 专属命令 + Linux 命令索引)

> 来源:整理自 D-Robotics 官方文档 `D-Robotics/rdk_doc`(`docs/`=X 系列、`docs_s/`=S 系列)与 `D-Robotics/rdk_s_doc` 的 `09_Appendix`(官方分类:`9.1 RDK专属命令用法` + `9.2 Linux命令用法`),逐条保留出处;只转述文档确有的事实,未改写技术内容。

## 何时用

用户问"某条命令怎么用 / 这个选项什么意思 / 这块板该用哪个命令查状态"时用本 skill——以**命令为锚点查语法、选项、典型用法、适用板型、出处**。

边界(避免与兄弟 skill 重叠):
- **命令报了错、要按现象排障** → `rdk-board-knowledge`(故障速查 + 诊断流程;那里的 `diagnostic-commands.md` 含 `hrut_bpuprofile`/`hrut_smi`/sysfs 等监控命令的风险分级)。
- **外设(摄像头/GPIO/I2C/串口/PWM)驱动与配置** → `rdk-peripheral-cookbook`。
- **定位 GitHub 仓库/源码** → `rdk-source-map`;**官方文档站章节定位/给权威 URL** → `rdk-doc-finder`。
- **纯硬件事实/引脚定义** → `rdk-hardware`。

## 板型与产物速记(影响命令是否适用)

- **X 系列**:X3(Bernoulli2)、X5 / Ultra(Bayes);`hrut_*`、`srpi-config`(X3/X5/X3 Module,**不适用 Ultra**)、`rdk-miniboot-update`、`rdk-backup` 等主要在此文档。
- **S 系列**:S100 / S100P / S600(Nash 架构,模型产物 `.hbm`);命令同名但输出/选项可能不同(如 `hrut_somstatus` 多路 PVT 温度与电压、`hrut_boardid` 输出 `0x6A84` 形式)。S 系列文档在 `rdk_doc/docs_s/` 与独立仓 `rdk_s_doc`。
- 拿不准某命令在目标板是否存在/同义,**先在板上 `which <cmd>` 或 `<cmd> -h` 确认**,再按文档解释。

## RDK 专属命令(9.1)速查

下表只列"是什么 + 一句话";**完整语法、选项、典型用法、适用板型差异、逐条出处**见 [RDK 专属命令详表](references/rdk-commands.md)。

| 命令 | 作用一句话 | 需 sudo | 备注 |
| --- | --- | --- | --- |
| `hrut_somstatus` | 看温度 / CPU·BPU 频率 / BPU 负载(ratio) | 是 | 全板通用;S 系列额外含多路 PVT 温度与电压轨 |
| `hrut_boardid` | 读/设开发板编号 boardid | 视板型 | X3 有 g/s/G/S/c/C 选项;X5 仅 `-h`;S 系列输出 `0x6A84` 编码。**改 boardid 影响启动初始化,谨慎** |
| `hrut_socuid` | 打印 SoC 芯片唯一 UID | X3 示例用 sudo | — |
| `hrut_ps` | 打印 busybox ps 不支持的进程信息(prio/policy/vsize/rss 等) | 否 | — |
| `rdkos_info` | 一次性收集系统软硬件版本、驱动/包清单、最新日志 | 是 | `-b/-s/-d/-v/-h`;排障收集信息首选 |
| `rdk-miniboot-update` | 更新 miniboot 最小启动镜像 | 是 | `-f/-h/-l/-s`;不带参=升级到最新 |
| `rdk-backup` | 把当前系统备份成 `.img` 镜像 | 是 | `[dir]` 默认 /mnt;**执行前需联网** |
| `srpi-config` | 系统配置 TUI(网络/接口/性能/本地化等) | 是 | X3/X5/X3 Module(不适用 Ultra);S100 亦有 |
| `devmem` | 读/写物理地址寄存器(busybox) | 视地址 | `devmem ADDR [WIDTH [VALUE]]`,WIDTH 8/16/32 默认 32 |

> BPU 占用/profiling 命令(`hrut_bpuprofile`、`hrut_smi`、`bputop`、`cat /sys/devices/system/bpu/bpu0/ratio` 等)按板型差异与风险分级,见 `rdk-board-knowledge` 的 [diagnostic-commands.md](../rdk-board-knowledge/references/diagnostic-commands.md),本 skill 不重复维护。

## Linux 常用命令(9.2)

官方把 `apt / dmesg / dpkg / dpkg-deb / find / grep / ifconfig / ip / mount / netstat / nohup / ps / route / rsync / scp / ssh / tar / top / zip` 收进附录,内容是通用 Linux 用法。本 skill **只做索引指回官方**,不全文搬运——见 [Linux 命令索引](references/linux-commands.md)。需要具体某条的标准用法时,优先给官方链接;通用 Linux 语法可直接按标准 man 解释,不要臆造 RDK 特有差异。

## 参考资料

- [RDK 专属命令详表(语法/选项/典型用法/板型差异/出处)](references/rdk-commands.md)
- [Linux 命令附录索引(指回官方)](references/linux-commands.md)
- 故障诊断与监控命令风险分级:`rdk-board-knowledge`
