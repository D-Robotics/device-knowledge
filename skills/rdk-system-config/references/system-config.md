# RDK 系统配置详表

> 来源:`D-Robotics/rdk_x_doc` 与 `D-Robotics/rdk_s_doc` 的 `docs/02_System_configuration`。X 系=rdk_x_doc(X3/X5/Ultra),S 系=rdk_s_doc(S100/S100P/S600)。只保留文档确有内容,板型适用范围以文档 DocScope/注意框为准。

---

## 1. 网络与蓝牙(2.1)

### 1.1 有线网络 — X 系列

默认静态 IP `192.168.127.10`。按系统版本分两套:

**新版(RDK X5 ≥ 3.3.0 / RDK X3 ≥ 3.0.2,NetworkManager)** — 配置文件 `/etc/NetworkManager/system-connections/netplan-eth0.nmconnection`:
- 静态:`[ipv4]` 段 `address1=192.168.127.10/24,192.168.127.1`、`method=manual`、`route-metric=700`(有线优先级故意调低,有线+无线同时使能时优先用无线)。
- DHCP:`[ipv4]` 仅留 `method=auto` + `route-metric=700`。
- 改 MAC:`[ethernet]` 加 `cloned-mac-address=12:34:56:78:9A:BA`,需 `reboot`。
- 静态/DHCP/MAC 改后 `sudo restart_network` 生效(改 MAC 需 reboot)。桌面版可点网络图标 GUI 改,选中 `netplan-eth0` 生效。

**旧版(X5 < 3.3.0 / X3 < 3.0.2)** — 配置文件 `/etc/network/interfaces`:
- 静态:`iface eth0 inet static` + `address/netmask/gateway/metric 700`,含 `pre-up /etc/set_mac_address.sh`。
- DHCP:`iface eth0 inet dhcp` + `metric 700`。
- 改 MAC:加 `pre-up ifconfig eth0 hw ether 00:11:22:9f:51:27`,`reboot` 生效。
- 改后 `sudo restart_network`(改 MAC 需 reboot)。

### 1.2 有线网络 — S 系列

默认 `NetworkManager + Netplan`;S100 基于 Ubuntu 22.04、S600 基于 Ubuntu 24.04,**均不支持 ifup/ifdown**。用 nmcli:

```shell
# 静态(以 eth1 为例)
nmcli connection modify "eth1_cfg" \
  ipv4.method manual ipv4.addresses "192.168.10.100/24" \
  ipv4.gateway "192.168.10.1" ipv4.dns "223.5.5.5 8.8.8.8" \
  ipv4.never-default yes connection.autoconnect yes
nmcli connection down "eth1_cfg"; nmcli connection up "eth1_cfg"

# DHCP:ipv4.method auto,并把 addresses/gateway/dns 置空
# 查看:nmcli device show eth1
```

保存后配置写入 `/etc/NetworkManager/system-connections/`;直接编辑 `.nmconnection` 后用 `sudo nmcli connection reload` + `sudo nmcli connection up [name]` 生效。

### 1.3 无线网络(两系列通用 Station 流程)

- 开发板集成/需装 2.4GHz Wi-Fi,默认 Station 模式。
- **Desktop 版**:点桌面右上角 Wi-Fi 图标选热点输密码。
- **Server 版**:
  1. `sudo nmcli device wifi rescan`(报 `Scanning not allowed immediately following previous scan` 说明太频繁,稍后再试)
  2. `sudo nmcli device wifi list`
  3. `sudo wifi_connect "SSID" "PASSWD"`(报 `No network with SSID ... found` 则重新 rescan)

### 1.4 Soft AP 模式

- **S 系列**:文档明确 `Wi-Fi AP 模式暂不可用`(持续更新中)。
- **X 系列(传统 hostapd 法)**:`apt install hostapd isc-dhcp-server` → 配 `/etc/hostapd.conf`(interface=wlan0、ssid、wpa=2、wpa_key_mgmt=WPA-PSK、wpa_pairwise=CCMP、wpa_passphrase;**X5 可建 5G**:`channel=36`、`hw_mode=a`)→ 配 `/etc/default/isc-dhcp-server`(`INTERFACESv4="wlan0"`)与 `/etc/dhcp/dhcpd.conf`(取消 `authoritative;` 注释 + 加 subnet 段)→ `systemctl mask/stop wpa_supplicant` 并重启 wlan0 → `sudo hostapd -B /etc/hostapd.conf` → `ifconfig wlan0 10.5.5.1 netmask 255.255.255.0` → `systemctl start/enable isc-dhcp-server`。切回 Station:`killall -9 hostapd`、flush wlan0、`systemctl unmask/restart wpa_supplicant`(RDK X5 还需 `rmmod aic8800_fdrv; modprobe aic8800_fdrv`)、`wifi_connect`。
- **X 系列(NetworkManager 法,X5 ≥ 3.3.0 / X3 ≥ 3.0.2)**:右上角无线图标 → `Edit Connections...` → + → Connection Type `Wi-Fi` → SSID/Mode=`Hotspot`/Band(Automatic / A 5GHz / B-G 2.4GHz)→ `Wi-Fi Security` 设加密与密码 → 重启或 `restart_network`。

### 1.5 DNS(两系列通用)

改 `/etc/systemd/resolved.conf` 加 `DNS=8.8.8.8 114.114.114.114`,然后:
```bash
sudo systemctl restart systemd-resolved; sudo systemctl enable systemd-resolved
sudo mv /etc/resolv.conf /etc/resolv.conf.bak
sudo ln -s /run/systemd/resolve/resolv.conf /etc/
```

### 1.6 代理(S 文档)

当前用户改 `~/.bashrc`、全局改 `/etc/environment`,加 `http_proxy/https_proxy/ftp_proxy=http://addr:port`、`no_proxy=localhost,127.0.0.1`,`source ~/.bashrc` 生效。

### 1.7 系统更新(两系列)

`sudo apt update` → `sudo apt full-upgrade`(推荐 full-upgrade 以同步依赖;apt 不检查磁盘空间,先 `df -h`;deb 缓存在 `/var/cache/apt/archives`,`sudo apt clean` 清理)→ 升级可能重装驱动/内核,`sudo reboot`。S 文档额外标注"产品未上市前请勿执行"。

### 1.8 蓝牙

- 自 3.0.0 系统起蓝牙默认随系统启动(X3/X5 一致)。若 `hciconfig` 看不到设备,X 系列执行 `/usr/bin/startbt.sh`(完成初始化 + `hciconfig hci0 up` + `hciconfig hci0 piscan`)。
- 查进程:`ps ax | grep "/usr/bin/dbus-daemon\|/usr/lib/bluetooth/bluetoothd"`;S 文档另给 `bluetoothctl list` 看控制器。
- 配网:`sudo bluetoothctl` → `show` 看 powered/discoverable → `power on` → `discoverable on` → `scan on`/`scan off` → `pair [MAC]`(按提示 yes)→ `trust [MAC]` 自动重连。更多功能查 BlueZ 官方。
- X 文档另述蓝牙通信接口(UART Only 双线 BT_RX/BT_TX 无流控;加 BT_CTS/BT_RTS 硬件流控支持 A2DP;PCM 同步接口语音)与 USB 蓝牙(已集成 USB2.0-BT / CSR8510 A10 驱动,Realtek 需额外固件)。

---

## 2. srpi-config TUI(2.2)

打开:`sudo srpi-config`(默认 sunrise 无权改系统文件,必须 sudo);桌面系统可在菜单找 `RDK Configuration`。完成后选 `Finish`,需重启的项会提示。

**适用板型**:X 文档明确"仅适用 RDK X3、RDK X5 和 RDK X3 Module"(不适用 Ultra);S 文档的 srpi-config 截图与正文均为 S100。

### 2.1 X 系列菜单

| 菜单 | 子项 |
| --- | --- |
| System Options | Wireless LAN(SSID/密码)、Password(默认 sunrise)、Hostname、Boot/Auto login(控制台/桌面、自动登录用 sunrise)、Power LED、Browser(默认 firefox,可 `apt install chromium`) |
| Display Options | FB Console Resolution(Server/console 下 HDMI 分辨率)、Display Chose DSI or HDMI(**仅 RDK X5 支持切换显示屏**) |
| Interface Options | SSH(默认开)、VNC(X11vnc)、Peripheral bus config(开关 40pin 上 SPI/I2C/Serial/I2S,X5 增 PWM,直接改设备树 status 重启生效;X5 引脚复用见下)、Configure Wi-Fi antenna(板载 trace / 外置 cable,`cat /boot/config.txt` 看 antenna_option)、Audio(装/卸 Audio Driver HAT V1/V2、WM8960 等转接板) |
| Performance Options | CPU frequency(超频,需散热,X5 详见频率管理)、ION memory(默认 672MB,跑大模型/多路编解码时调大) |
| Localisation Options | Locale(如 zh_CN.UTF-8 重启生效)、Time Zone、Keyboard |
| Advanced Options | Expand Filesystem(扩展到整张 TF 卡)、Network Proxy Settings、Boot Order(X3 Module / X5 Module 切 eMMC/SD 启动) |
| Sensor Profiles | 多套 Sensor 效果库;IMX219 Switch ISP(1 FOV 79.3° = Jetson Nano 摄像头适配 200/160FOV,2 FOV 120° = 树莓派5代摄像头适配 120FOV) |
| Update / About / Finish | 更新工具 / 信息 / 完成 |

X5 Peripheral bus 引脚复用(同一行只能生效一种,全 disable 则为 GPIO):serial3↔i2c5 / i2c0↔pwm2 / spi2↔pwm0 / spi2↔pwm1 / i2c1↔pwm3。

### 2.2 S100 菜单(与 X 的差异)

- **System Options**:除 Wireless LAN/Password/Hostname/Boot-Auto login/Power LED/Browser 外,多 **Update Miniboot**(升级 Miniboot 分区)。
- **Interface Options**:仅 **SSH**;VNC"正在适配";外设配置建议改走 config.txt。
- **Performance Options**:**仅 ION memory**(无超频、无 CPU 定频项)。
- Localisation / Advanced(Expand Filesystem 默认扩到 eMMC、Network Proxy)/ Update / About / Finish 同 X。
- **无 Display Options、无 Sensor Profiles 菜单。**

---

## 3. config.txt(2.3)— X 与 S 是两套完全不同的机制

### 3.1 X 系列(/boot/config.txt,uboot 阶段读取)

适用 X3 / X5 / X3 Module;系统 ≥ 2.1.0、miniboot ≥ 20231126;root 编辑;若文件不存在可新建。注意 srpi-config 配置可能被本文件的过滤项过滤掉。

- **设备树**:`dtdebug=1`(串口打配置日志,须先于 dtoverlay);`dtoverlay=...`(X3 `ion_resize,size=0x40000000` 调 ION 到 1GB;X5 `dtoverlay_spi5_spidev` 加 /dev/spidev5.0,注意 can 与 spidev 在 spi5 二选一)。
- **X5 ION**:`ion=ion_reserved_size=...` / `ion_carveout_size` / `ion_cma_size`(默认 320M/320M/128M),`dmesg | grep "Reserved ion"` 查。
- **dtparam 开关总线**:`dtparam=uart3=off`、`dtparam=i2c5=on`。X3 支持 uart3/spi0-2/i2c0-5/i2s0-1;X5 支持 uart1/2/3/6、spi1/2、i2c0/1/4/5、dw_i2s1(注意引脚复用,同上)。
- **CPU 频率**:`arm_boost=1`(X3 v1.x→1.5G、V2.0/Module→1.8G;X5→1.8G);`governor=performance`(可选 conservative/ondemand/userspace/powersave/schedutil);`governor=userspace` + `frequency=1000000`(X3 频点 240000~1800000;X5 频点 300000/600000/1200000/1500000)。
- **IO 初始化 gpio**:`gpio=5=f3`(功能复用 f0-f3)、`ip`/`op`、`dh`/`dl`、`pu`/`pd`/`pn`;用 BOARD 编码;连续脚 `gpio=5-6=f3`。
- **温控**:`throttling_temp=86000`(降频点,CPU 最低 240MHz/BPU 最低 400MHz)、`shutdown_temp=112000`(宕机关机,宕机后不自动重启)。
- **选项过滤**:文件尾用 `[all]/[rdkv1]/[rdkv1.2]/[rdkv2]/[rdkmd]/[x5-rdk]` 分段,加过滤后后续配置只属该型号。
- **电压域**(仅 RDK Module):`voltage_domain=3.3V`(或 1.8V,需配合硬件跳线帽)。

### 3.2 S 系列(/boot/config.txt,地瓜 Uboot)

优先级 `setenv > 配置文件 > 上次 saveenv`;格式 `<key>=<value>`(首个 `=` 后全为值),单行 ≤1024 字符;使能 AVB 时不可用(AVB 默认不使能)。

- `bootargs=isolcpus=1-2`(内核 cmdline);`loglevel=8`(打印等级)。
- `fdt-enable=/soc/uart@394C0000;` / `fdt-disable=...;`(使能/失能 dts 节点,行尾 `;` 不可省;节点全路径从 `/proc/device-tree` 取并补行首 `/`)。
- DTB Overlay:`apt install device-tree-compiler` → `dtc -I dts -O dtb -o x.dtbo x.dtso` → 拷到 /boot → `dtbo_file_path=/x.dtbo`(/boot 相对路径);自定义分区 `dtbo_dev_part=0:0x10`(分区号查 `ls -l /dev/block/platform/by-name/<分区名>`)。
- 自定义配置文件:Uboot 内 `setenv boot_config_f test.txt` / `boot_config_dev_part 0:0xd` / `boot_config_intf scsi` 后 `saveenv`。解析代码在 Uboot `board/hobot/common/drobot_boot_config.c`。
- **S 系列无 X 式 dtparam/gpio/arm_boost/过滤项语法。**

---

## 4. Thermal 与 CPU 频率(2.4)

查状态统一用 `sudo hrut_somstatus`。所有 trip_point 设置断电重启后失效,需重设(可放自启动)。

### 4.1 X3

- thermal_zone0 三温度点:`trip_point_0_temp`(启动 80℃)、`trip_point_1_temp`(降频 95℃,CPU↓240MHz/BPU↓400MHz)、`trip_point_2_temp`(宕机 105℃,不可超 105)。`echo 85000 > .../thermal_zone0/trip_point_1_temp`。
- 调频:`/sys/devices/system/cpu/cpufreq/policy0/scaling_governor`(performance/powersave/ondemand/conservative/userspace/schedutil);userspace 下 `echo 1000000 > .../scaling_setspeed`。
- 超频:默认 ondemand;`echo 1 > /sys/devices/system/cpu/cpufreq/boost`(1.2→1.5GHz),`echo 0` 关。

### 4.2 X5

- 三传感器在 hwmon0:temp1=DDR、temp2=BPU(仅 BPU 运行时上电可读)、temp3=CPU(精度 0.001℃)。
- 两 thermal_zone:zone0 含 DDR(1 个 trip_point,默认 95℃);zone1 含 CPU/BPU/GPU(trip_point_1=调频 95℃、trip_point_2=关机 105℃)。四 cooling_device:cpu/bpu/gpu/ddr。policy 默认 step_wise,可切 user_space。
- 调频:`echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor`;userspace 下写 `policy0/scaling_setspeed`;频点 300000/600000/1200000/1500000。
- 超频:默认 schedutil;`echo 1 > .../cpufreq/boost` + performance(1.5→1.8GHz)。**仅 X5H 支持,X5M 不可超频**(`cat /sys/class/socinfo/soc_name` 看 X5M/X5H;X5U=早期未烧 eFUSE,理论可超频但不保证稳定,量产不推荐)。

### 4.3 S100

- 5 个温度传感器(hwmon0):temp1/2=MAIN 域、temp3/4=MCU 域、temp5=BPU(精度 0.001℃);5 个 thermal_zone(zone0~4 绑 5 传感器)。
- thermal_zone0 四 trip_point:0=关机 120℃、1=风扇 43℃(档 2~5)、2=风扇 65℃(档 6~10)、3=CPU Acore 调频 95℃;zone4 两 trip_point:0=关机 120℃、1=BPU 调频 95℃;zone1/2/3 各 1 个 = 关机 120℃。
- 4 cooling_device:0=cpu cluster0、1=cpu cluster1、2=emc2305 风扇(档 0~10)、3=bpu。CPU/风扇绑 zone0,BPU 绑 zone4。
- 风扇固定档:先 `echo user_space > .../thermal_zone0/policy`,再 `echo 10 > /sys/class/thermal/cooling_device2/cur_state`(step_wise 时档位会被系统按温度自动调)。
- CPU 频率:`echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor`;userspace 写 `policy0/scaling_setspeed`;频点 1500000 / 2000000(因芯片而异)。

### 4.4 S600

- 19 个温度传感器(hwmon1,范围 -40~125℃):CPU 7 个(CMN0-TS0~6)、DDR 4 个(DDR0~3-TS0)、BPU 8 个(BPU0~3-TS0[0~1]);19 个 thermal_zone(zone0~18)。
- CPU zone(0~6):zone2 五 trip_point(0=风扇 45℃、1=风扇 65℃、2=CPU Acore 调频 95℃、3=hot 110℃、4=关机 115℃),其余 1 个=关机 115℃。DDR zone(7~10):2 个(hot 110℃、关机 115℃)。BPU zone(11~18):zone16 五 trip_point(0/1 风扇、2=BPU 调频 95℃、3=hot 110、4=关机 115),其余=关机 115℃。
- 11 cooling_device:0~4=cpu cluster0~4、5/6=两组 emc2305 风扇(档 0~10)、7~10=bpu core0~3。
- 风扇固定档:`echo user_space > .../thermal_zone2/policy` 与 `.../thermal_zone16/policy`,再 `echo 10 > /sys/class/thermal/cooling_device5/cur_state`。
- CPU 频率:同 S100 路径;频点 525000 / 1050000 / 2100000(因芯片而异)。

---

## 5. 开机自启动(2.5)— X / S 完全相同

**方法一 init.d Service**:
1. `/etc/init.d/your_script_name` 写脚本(含 `### BEGIN/END INIT INFO` 头,`Default-Start: 2 3 4 5`、`Default-Stop: 0 1 6`,正文 `/path/to/program &` + `exit 0`)。
2. `sudo chmod +x /etc/init.d/your_script_name`
3. `sudo update-rc.d your_script_name defaults`
4. `sudo systemctl enable your_script_name`
5. 重启后 `systemctl status your_script_name.service` 验证(active (exited) 即正常)。

**方法二 rc.local**(systemd 下属遗留服务):在 `sudo vim /etc/rc.local` 末尾 `exit 0` 之前插入启动命令。

---

## 6. GUI 配网(2.6)— S 系列独有

桌面 settings → Network 配静态 IP/DNS/Proxy:
- 选对应 `Ethernet (ethN)`(**S100**:eth0/eth1;**S600**:eth0/eth1/eth3/eth4,各对应不同物理口)→ 齿轮 → IPV4 → `Manual` 填 IP/掩码/网关 → 下拉填 DNS。
- 一卡多 IP:点加号再配一组;S100 完成后选中 `eth1_cfg` 出现 √(若 /etc/netplan 无网络项则界面不同),S600 选中 `netplan-eth1` 出现 √。
- Proxy:settings → Network → Network Proxy(S100)/ Proxy(S600)齿轮填配置。

---

## 7. 共享文件(2.7)— S 系列独有

### Samba
```bash
sudo apt install samba
mkdir ~/shared
# 编辑 /etc/samba/smb.conf 末尾加 [shared] 段:
#   path=/home/<user>/shared, read only=no, browsable=yes,
#   guest ok=no, create mask=0775, directory mask=0775
sudo smbpasswd -a sunrise        # 用系统用户作 Samba 用户并设密码
sudo systemctl restart smbd      # status smbd 查状态
sudo ufw allow samba             # 若启用 ufw 防火墙(可选)
```

### NFS(Ubuntu 22.04/24.04 作客户端)
前提:已有 NFS 服务端。
```bash
sudo apt install nfs-common
sudo mkdir -p /userdata/windows_nfs_share
sudo mount -v -t nfs -o vers=3,proto=tcp 192.168.127.11:/D/NFSShare /userdata/windows_nfs_share
mount | grep windows_nfs_share   # 验证
```
开机自动挂载:写 `/etc/systemd/system/mount-windows-nfs.service`(Type=oneshot、RemainAfterExit=yes、After/Wants=network-online.target、ExecStartPre=/bin/sleep 10、ExecStart=mount …、ExecStop=umount …)→ `systemctl daemon-reload` → `systemctl enable --now mount-windows-nfs.service`。
