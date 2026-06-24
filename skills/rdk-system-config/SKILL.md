---
name: rdk-system-config
description: 当用户要做 RDK 系统级配置工作流时使用——配 Wi-Fi/蓝牙/有线网(nmcli、wifi_connect、/etc/NetworkManager 或 /etc/network/interfaces)、配 DNS/代理、改 config.txt 启动配置(X 系的 dtparam/gpio/arm_boost/过滤项,或 S 系的 bootargs/fdt-enable/dtbo)、调 CPU/BPU 频率与性能模式(scaling_governor/boost)与温控风扇、设开机自启动服务(init.d/rc.local)、配 Samba/NFS 文件共享、用 srpi-config TUI 各菜单(System/Interface/Performance/Localisation/Advanced)。本 skill 是"配置怎么做"的工作流入口。边界:查单条命令语法/选项走 rdk-command-manual;摄像头/GPIO/I2C/串口/PWM 外设驱动配置走 rdk-peripheral-cookbook;出了报错按现象排障走 rdk-board-knowledge;定位文档站章节走 rdk-doc-finder。
---

# RDK 系统配置(联网 / 显示 / 调频 / 自启动 / 文件共享 / srpi-config)

> 来源:整理自 D-Robotics 官方文档 `D-Robotics/rdk_x_doc` 与 `D-Robotics/rdk_s_doc` 的 `docs/02_System_configuration`(X 系 5 篇:network_blueteeth / srpi-config / config_txt / frequency_management / self_start;S 系 7 篇:多 gui_network_config 与 share_file_tool)。只转述文档确有的事实,逐项保留板型适用范围与 X/S 差异。

## 何时用

用户问"这块板该怎么配 Wi-Fi/有线网/蓝牙、怎么改启动配置、怎么把 CPU 锁到最高频/降频、怎么设开机自启、怎么搭 Samba/NFS 共享、srpi-config 某个菜单干什么"——以**配置任务为锚点查实操步骤(命令/菜单/配置文件)、适用板型、X 与 S 差异**时用本 skill。

边界(避免与兄弟 skill 重叠):
- **只想查某条命令的语法/选项/作用**(如 `hrut_somstatus` 怎么读、`srpi-config` 有哪些菜单一句话)→ `rdk-command-manual`。
- **外设驱动与接线**(摄像头 MIPI、GPIO 读写、I2C/SPI/串口/PWM 设备)→ `rdk-peripheral-cookbook`;本 skill 只覆盖 config.txt/srpi-config 里"开关总线"那一层。
- **配完报错、按现象排障** → `rdk-board-knowledge`。
- **要官方文档站 URL/章节定位** → `rdk-doc-finder`;**纯硬件/引脚事实** → `rdk-hardware`。

## 板型基线(决定用哪套做法)

| 维度 | X 系列(rdk_x_doc) | S 系列(rdk_s_doc) |
| --- | --- | --- |
| 覆盖板型 | X3(Bernoulli2)、X5 / Ultra(Bayes) | S100 / S100P / S600(Nash) |
| 系统 | Ubuntu 22.04 / Humble | S100 22.04 / Humble;S600 24.04 + Jazzy |
| 有线网 | 新版 NetworkManager,旧版 /etc/network/interfaces | 仅 NetworkManager+Netplan / nmcli,不支持 ifup/ifdown |
| Soft AP | 支持(hostapd 或 NM Hotspot,X5 可 5G) | 文档标注"暂不可用" |
| config.txt | /boot/config.txt(uboot 读),dtparam/gpio/arm_boost/过滤项 | /boot/config.txt(地瓜 Uboot),bootargs/fdt-enable/dtbo;**语法与 X 完全不同** |
| srpi-config | X3 / X5 / X3 Module(**不适用 Ultra**) | 文档示例为 S100(无 Display/Sensor Profiles 菜单) |
| GUI 配网 / 文件共享 | 文档无独立章节 | 独有 2.6 GUI 配网、2.7 Samba/NFS |

> 拿不准目标板某做法是否适用,先在板上确认(`which srpi-config`、`cat /boot/config.txt`、`nmcli device`),再按对应系套用。

## 各配置任务速记

下表只给"做什么 + 走哪条路";**完整命令/菜单/配置文件内容、X 与 S 逐项差异、出处**见 [系统配置详表](references/system-config.md)。

| 任务 | X 系做法 | S 系做法 |
| --- | --- | --- |
| 有线静态/DHCP IP | 改 `netplan-eth0.nmconnection`(新)或 `/etc/network/interfaces`(旧),`sudo restart_network` | `nmcli connection modify` 改 ipv4.method/addresses,`down`/`up` 生效 |
| Wi-Fi 连接(Server) | `sudo nmcli device wifi rescan/list` + `sudo wifi_connect "SSID" "PASSWD"` | 同 X |
| Wi-Fi 热点(AP) | hostapd + isc-dhcp-server,或 NM `Hotspot` | 暂不可用 |
| 蓝牙 | `/usr/bin/startbt.sh` 初始化 + `bluetoothctl`(power on/scan/pair/trust) | `bluetoothctl`(S 文档无 startbt.sh 步骤) |
| DNS / 代理 | 改 `/etc/systemd/resolved.conf` | 同 X;代理另可 `~/.bashrc` 或 `/etc/environment` 设 `http_proxy` 等 |
| 改启动配置 | `/boot/config.txt`:dtparam 开关总线、gpio 复用、arm_boost/governor 调频、throttling_temp/shutdown_temp | `/boot/config.txt`:bootargs/loglevel/fdt-enable/fdt-disable/dtbo_file_path |
| CPU 调频/锁频 | `echo perf/userspace > .../policy0/scaling_governor`,X3 boost 1.2→1.5G、X5 boost 1.5→1.8G(仅 X5H) | `echo ... > cpu0/cpufreq/scaling_governor`;S100 1.5/2.0G、S600 0.525/1.05/2.1G |
| 温控 / 风扇 | 改 `thermal_zoneN/trip_point_*_temp`(X3 单 zone、X5 双 zone) | S100 5 zone、S600 19 zone;风扇 emc2305 需把对应 zone policy 设 `user_space` 再写 `cooling_deviceN/cur_state` |
| 开机自启动 | `/etc/init.d` + `update-rc.d defaults` + `systemctl enable`,或 `/etc/rc.local` | 与 X 完全相同 |
| 文件共享 | 文档无独立章节 | Samba(`smb.conf` [shared] + `smbpasswd -a sunrise`)、NFS 客户端(`mount -t nfs`) |
| GUI 配网 | 文档无独立章节 | settings → Network 配静态 IP/DNS/Proxy |
| srpi-config TUI | System/Display/Interface/Performance/Localisation/Advanced/Sensor Profiles | System(多 Update Miniboot)/Interface(仅 SSH)/Performance(仅 ION)/Localisation/Advanced;**无 Display、无 Sensor Profiles** |

## 参考资料

- [系统配置详表(各项命令/菜单/配置文件 + X 与 S 差异 + 出处)](references/system-config.md)
- 单条命令语法 → `rdk-command-manual`;配置后报错 → `rdk-board-knowledge`;外设驱动 → `rdk-peripheral-cookbook`
