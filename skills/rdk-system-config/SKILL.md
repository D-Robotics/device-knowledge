---
name: rdk-system-config
description: How-to workflows for RDK board system configuration — wired/Wi-Fi/Bluetooth networking (nmcli, wifi_connect, NetworkManager vs /etc/network/interfaces), DNS/proxy, the /boot/config.txt boot file (X-series dtparam/gpio/arm_boost/filters vs S-series bootargs/fdt-enable/dtbo), CPU frequency locking and overclock, thermal trip points and emc2305 fan control, boot self-start services, Samba/NFS file sharing, and the srpi-config TUI. Use whenever a user asks "how do I configure X on this board" and wants concrete steps (commands / menus / config-file edits), the right per-board method, and the X-vs-S difference. 触发词:配网/连WiFi/有线静态IP/改config.txt/改启动配置/CPU锁频/降频/超频/调频/风扇控制/温控/开机自启/自启动/Samba/NFS共享/srpi-config菜单/蓝牙配对/DNS/代理. Routing — single-command syntax lookup → rdk-command-manual; camera/GPIO/I2C/SPI/UART/PWM device drivers → rdk-peripheral-cookbook; errors AFTER configuring → rdk-board-knowledge; doc-site URLs/chapters → rdk-doc-finder; pure pin/hardware facts → rdk-hardware.
---

# RDK System Configuration

Turn a "how do I configure …" question into the exact commands, srpi-config menu path, or `/boot/config.txt` edit for the user's board — and never let an X-series recipe leak onto an S-series board (or vice versa). **The single thing that matters most: X-series and S-series are two different systems.** Confirm which family you are on before quoting any method.

> Sources: official D-Robotics docs `D-Robotics/rdk_x_doc` and `D-Robotics/rdk_s_doc`, directory `docs/02_System_configuration` (X: 5 files network_blueteeth / srpi-config / config_txt / frequency_management / self_start; S: 7 files, additionally gui_network_config and share_file_tool). Every non-trivial fact below was re-verified against these files; nothing is invented.

## Confirm the board first

X and S diverge on networking, config.txt syntax, frequencies, thermal zones, and which tools exist. Probe before answering:

```bash
cat /sys/class/socinfo/board_id   # or: cat /etc/version, hrut_somstatus
which srpi-config                  # exists on X3/X5/X3 Module; S100 too; NOT on Ultra
cat /boot/config.txt              # X and S use the SAME path, COMPLETELY different syntax
nmcli device                      # network manager present?
```

## Board baseline cheat-sheet (decides which recipe to use)

| Dimension | X-series (`rdk_x_doc`) | S-series (`rdk_s_doc`) |
|---|---|---|
| Boards | X3 (Bernoulli2), X5 (Bayes-e), Ultra (Bayes) | S100 (Nash-e) / S100P (Nash-m), S600 (Nash-p) |
| OS / ROS | Ubuntu 22.04 + Humble | S100/S100P: 22.04 + Humble · S600: **24.04 + Jazzy** |
| Wired net | New: NetworkManager · Old: `/etc/network/interfaces` | NetworkManager + Netplan / nmcli only; **no ifup/ifdown** |
| Soft AP | Supported (hostapd or NM Hotspot; X5 can do 5G) | Doc marks **"not yet available"** |
| config.txt | `/boot/config.txt` (uboot) — `dtparam`/`gpio`/`arm_boost`/`[filters]` | `/boot/config.txt` (D-Robotics Uboot) — `bootargs`/`fdt-enable`/`dtbo`; **syntax totally different** |
| srpi-config | X3 / X5 / X3 Module (**NOT Ultra**) | Doc example is S100 (no Display, no Sensor Profiles menu) |
| GUI config / file share | No standalone doc chapter | Has its own 2.6 GUI networking + 2.7 Samba/NFS |

> Canonical board fact (carry consistent across all skills): the **S100/S600 management port `eth1` is factory-fixed at `192.168.127.10`**; X-series default wired IP is also `192.168.127.10`. The S-series doc's nmcli examples use a sample `192.168.10.100/24` connection named `eth1_cfg` — substitute the real connection name from `nmcli connection show`.

## Task → route map

Full commands, menus, config-file bodies, item-by-item X/S differences, and provenance are in **[system-config.md](references/system-config.md)**. A deterministic lookup for "which sysfs path / value for thermal & CPU freq on board X" is `scripts/sysconf_lookup.py`.

| Task | X-series method | S-series method |
|---|---|---|
| Static / DHCP wired IP | Edit `netplan-eth0.nmconnection` (new) or `/etc/network/interfaces` (old), then `sudo restart_network` | `nmcli connection modify` ipv4.method/addresses, then `down`/`up` |
| Wi-Fi connect (Server) | `sudo nmcli device wifi rescan`/`list` + `sudo wifi_connect "SSID" "PASSWD"` | Same as X |
| Wi-Fi hotspot (AP) | hostapd + isc-dhcp-server, or NM `Hotspot` (X5 can do 5G) | Not yet available |
| Bluetooth | `/usr/bin/startbt.sh` init + `bluetoothctl` (power on/scan/pair/trust) | `bluetoothctl` (no startbt.sh step; adds `bluetoothctl list`) |
| DNS / proxy | DNS via `/etc/systemd/resolved.conf` | Same DNS; proxy via `~/.bashrc` or `/etc/environment` |
| Edit boot config | `/boot/config.txt`: dtparam buses, gpio mux, arm_boost/governor, throttling/shutdown temp | `/boot/config.txt`: bootargs/loglevel/fdt-enable/fdt-disable/dtbo_file_path |
| CPU freq / lock | `scaling_governor` on `policy0`; boost: X3 1.2→1.5G, X5 1.5→1.8G (**X5H only**) | `cpu0/cpufreq/scaling_governor`; S100 1.5/2.0G, S600 0.525/1.05/2.1G; **no overclock** |
| Thermal / fan | Set `thermal_zoneN/trip_point_*_temp` (X3 1 zone, X5 2 zones) | S100 5 zones, S600 19 zones; fan: set zone `policy=user_space` then write `cooling_deviceN/cur_state` |
| Boot self-start | init.d + `update-rc.d defaults` + `systemctl enable`, or `/etc/rc.local` | **Identical to X** |
| File share | No doc chapter | Samba (`smb.conf [shared]` + `smbpasswd -a sunrise`), NFS client (`mount -t nfs`) |
| GUI networking | No doc chapter | settings → Network: static IP / DNS / Proxy |
| srpi-config TUI | System/Display/Interface/Performance/Localisation/Advanced/Sensor Profiles | System (adds Update Miniboot) / Interface (SSH only) / Performance (ION only) / Localisation / Advanced; **no Display, no Sensor Profiles** |

## Workflows

### Workflow 1 — Network configuration

1. **Probe the family and version.** `nmcli device` (present → NetworkManager path). For X-series, version gates the method: X5 ≥ 3.3.0 / X3 ≥ 3.0.2 use NetworkManager; older use `/etc/network/interfaces`.
2. **Wired static IP** — X new/S: NetworkManager (`nmcli connection modify` or edit `.nmconnection`); X old: `/etc/network/interfaces`. `route-metric=700` is intentional (Wi-Fi wins when both up) — don't "fix" it. Full commands → [system-config.md](references/system-config.md) §1.1–1.2.
3. **Wi-Fi** (both) — Desktop: tray icon; Server: `nmcli device wifi rescan` → `list` → `wifi_connect "SSID" "PASSWD"`. Common errors → §1.3.
4. **Soft AP** — X-series only (hostapd or NM Hotspot; X5 can do 5G); S-series: **not yet available** — don't hand a hostapd recipe. Details → §1.4.
5. **DNS / proxy / Bluetooth** — DNS: `/etc/systemd/resolved.conf` + relink `resolv.conf`; Proxy (S): `~/.bashrc` or `/etc/environment`; Bluetooth: X needs `startbt.sh` first, S uses `bluetoothctl` directly. Full steps → §1.5–1.8.
6. **Verify** — run `bash scripts/sys_probe.sh` for structured JSON (`interfaces`, `config_txt_exists`, `cpu_governor`, `gateway_reachable`). Confirm `gateway_reachable` is `true` and the expected interface appears in `interfaces`.

**验证:** `bash scripts/sys_probe.sh` returns `gateway_reachable: true`; `ip addr` shows the configured IP on the expected interface; DNS resolves (`ping -c1 8.8.8.8` succeeds).

### Workflow 2 — Edit /boot/config.txt (X and S are two different mechanisms)

**X-series** (X3/X5/X3 Module; system ≥ 2.1.0; edit as root): `dtparam` bus toggles, `gpio=` mux/init, `arm_boost`/`governor`/`frequency` for CPU, `throttling_temp`/`shutdown_temp` for thermal, `[all]/[rdkv1]/[rdkv2]/[x5-rdk]` model filters. Full syntax & options → [system-config.md](references/system-config.md) §3.1.

**S-series** (D-Robotics Uboot; priority `setenv > config file > saveenv`; ≤1024 chars/line; AVB must be off): `bootargs=` kernel cmdline, `fdt-enable=`/`fdt-disable=` dts node paths (**trailing `;` mandatory**), `dtbo_file_path=` for DTB overlays. **No X-style `dtparam`/`gpio`/`arm_boost`/filter syntax.** Full syntax → §3.2.

**验证:** `cat /boot/config.txt` shows the edited entry; after reboot, the change takes effect (e.g. `dmesg | grep <peripheral>` shows the bus enabled, or the governor/freq value matches); for S-series `fdt-enable`/`fdt-disable` entries, the trailing `;` is present.

### Workflow 3 — CPU frequency, thermal, and fan

1. **Read state:** `sudo hrut_somstatus` on both families. All `trip_point` edits and sysfs governor changes **reset on reboot** — persist via boot self-start (Workflow 4).
2. **Lock CPU clock:** `echo userspace > .../scaling_governor` → write `scaling_setspeed`. Per-board paths and valid frequencies (X3 240000–1800000, X5 300000–1500000, S100 1500000/2000000, S600 525000/1050000/2100000) → [system-config.md](references/system-config.md) §4 or `scripts/sysconf_lookup.py`.
3. **Overclock:** X3 `echo 1 > .../cpufreq/boost` (1.2→1.5G); X5 1.5→1.8G but **X5H only** (`cat /sys/class/socinfo/soc_name`); **S-series has no overclock.**
4. **Fix fan speed (S only):** set bound zone `policy=user_space` **first**, then `echo <0-10> > cooling_deviceN/cur_state`. S100: `cooling_device2`↔`zone0`; S600: `cooling_device5/6`↔`zone2`+`zone16`. Full thermal-zone/trip-point tables → §4.3–4.4 or `scripts/sysconf_lookup.py`.

**验证:** `cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor` shows `performance` (or `userspace` + `scaling_setspeed` at target freq); S-series fan — `cat /sys/class/thermal/cooling_deviceN/cur_state` shows the set value, not system-overridden; `hrut_somstatus` shows temperature <85 °C.

### Workflow 4 — Boot self-start (identical on X and S)

1. Create `/etc/init.d/your_script` with an `### BEGIN/END INIT INFO` header (`Default-Start: 2 3 4 5`, `Default-Stop: 0 1 6`), body `/path/to/program &` + `exit 0`.
2. `sudo chmod +x /etc/init.d/your_script`
3. `sudo update-rc.d your_script defaults`
4. `sudo systemctl enable your_script`
5. Reboot, verify `systemctl status your_script.service` (`active (exited)` = OK).
- Alternative: insert commands before `exit 0` in `/etc/rc.local` (legacy under systemd).

**验证:** after reboot, `systemctl status your_script.service` shows `active (exited)`; `journalctl -u your_script` shows the service started without errors.

### Workflow 5 — File sharing (S-series only)

- **Samba:** install → add `[shared]` block to `smb.conf` → `smbpasswd -a sunrise` → restart smbd. Full `smb.conf` block → [system-config.md](references/system-config.md) §7.
- **NFS client:** install `nfs-common` → `mount -t nfs -o vers=3,proto=tcp` → for auto-mount, install a `mount-windows-nfs.service` oneshot unit. Full unit file → §7.

**验证:** Samba — `smbclient -L //<board-ip>` lists the `[shared]` share; `smbstatus` shows connected users. NFS — `df -h /userdata/...` shows the mounted NFS volume; `mount | grep nfs` confirms the mount.

## Worked examples

**Example 1 — "S600 上怎么把 CPU 锁到最高频?"**
*"S600 supports 525000 / 1050000 / 2100000 kHz (per chip). Lock the max: `echo userspace > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor` then `echo 2100000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_setspeed`. Note: S-series has no boost/overclock — 2.1 GHz is the ceiling. The setting resets on reboot, so add it to a boot self-start script if you need it to persist."*

**Example 2 — "我的 X5 风扇一直响,想固定风扇转速怎么搞?"**
First check the board: dedicated fan-speed sysfs control with `cooling_deviceN` is documented for **S100/S600**, not X5 (X5 thermal has cpu/bpu/gpu/ddr cooling devices but no emc2305 fan stage). If they are actually on **S100**: *"Fan is `cooling_device2` bound to `thermal_zone0`. Set the zone to manual first — `echo user_space > /sys/class/thermal/thermal_zone0/policy` — then `echo 10 > /sys/class/thermal/cooling_device2/cur_state` (0=off … 10=full). Under the default `step_wise` policy the system would override your value by temperature."* If it's really X5, route the fan-hardware question to rdk-peripheral-cookbook / rdk-hardware.

**Example 3 — "刚拿到 S600,怎么用命令行给 eth1 配个静态 IP?"**
*"S600 (Ubuntu 24.04) uses NetworkManager + Netplan; `ifup/ifdown` is unsupported. Find the connection name with `nmcli connection show`, then: `nmcli connection modify "<conn>" ipv4.method manual ipv4.addresses 192.168.10.100/24 ipv4.gateway 192.168.10.1 ipv4.dns "223.5.5.5 8.8.8.8" connection.autoconnect yes`, then `nmcli connection down "<conn>"; nmcli connection up "<conn>"`. The factory eth1 management IP is 192.168.127.10 — don't lock yourself off the port you're connected through."*

**Example 4 — "X5 上想关掉 uart3、打开 i2c5,改 config.txt 行不行?"**
*"Yes, on X5 use `/boot/config.txt` dtparam: `dtparam=uart3=off` and `dtparam=i2c5=on`, edit as root, reboot. Watch X5 pin multiplexing — a row shares pins, only one function per row (e.g. uart3↔i2c5, spi2↔pwm0/pwm1). If you previously enabled it via srpi-config, a config.txt `[filter]` can mask that, so keep them consistent. This is S-vs-X specific: on S-series there is no `dtparam`; you'd use `fdt-enable`/`fdt-disable` with the full device-tree node path instead."*

## Common pitfalls

| ❌ Don't | ✅ Do |
|---|---|
| Hand an S-series user a hostapd Soft AP recipe | S Soft AP is "not yet available" — say so; only X-series has it |
| Use `dtparam=`/`gpio=`/`arm_boost=` on S `/boot/config.txt` | S uses `bootargs`/`fdt-enable`/`dtbo`; different mechanism entirely |
| `ifup eth0` / edit `/etc/network/interfaces` on S | S has no ifup/ifdown — use `nmcli connection modify` |
| Tell any X5 it can overclock | Only **X5H** can; check `cat /sys/class/socinfo/soc_name` first |
| `echo` a fan `cur_state` while zone is `step_wise` | Set the zone `policy=user_space` first, else the value is overridden |
| Promise thermal/freq edits survive reboot | They reset — persist via boot self-start |
| Suggest `srpi-config` on RDK Ultra | srpi-config is X3/X5/X3 Module (+S100), not Ultra |
| Drop the trailing `;` in S `fdt-enable=…` | The `;` is mandatory; node path comes from `/proc/device-tree` with a leading `/` |

## Anti-hallucination guardrails

When answering from this skill, follow these rules — never fabricate facts, commands, or file paths:

1. **Report only observed data.** Quote what scripts/commands actually return, not what you remember. If the probe says `board_id: X5`, answer for X5 — even if the user insists it's an S100.
2. **No fabrication when tools are missing.** If a script or reference doesn't exist, say "not found" — don't invent from memory. Route to the appropriate skill or doc instead.
3. **Preserve null/false/empty on failure.** If a probe returns `null` or `false`, report that — don't substitute a plausible value. Empty output is data, not an error to "fix".
4. **No substitution off-platform.** If `off_platform: true`, say "probe didn't run on an RDK board" — don't guess what it would have returned. Ask for on-board logs.
5. **No hand-editing JSON.** Scripts emit structured JSON; never hand-craft output. If the contract says `{ok,off_platform,reason,fields}`, that's what goes to the user.
6. **Acknowledge sandbox limits.** If you can't run a command, say so — don't pretend you did. Offer the command for the user to run.
7. **Read-only boundary.** Never modify the system — no `dd`, `mkfs`, `rm -rf`, `apt install`, `reboot`, or GPIO output without explicit user confirmation.

## Reference map

| Read this | When |
|---|---|
| [system-config.md](references/system-config.md) | Full per-task commands, srpi-config menu trees, config.txt bodies, every X/S difference, thermal-zone/trip-point tables, Samba/NFS unit files, with provenance |
| `scripts/sysconf_lookup.py` | Deterministic "board → CPU freq points / governor path / thermal-zone & fan cooling-device mapping" lookup, so you don't recite per-board sysfs from memory |
| `scripts/sys_probe.sh` | Live system config probe — reads `ip addr` (UP interfaces) + `/boot/config.txt` existence + `scaling_governor` + `ping -c1 -W1` gateway reachability (structured JSON `{ok,off_platform,reason,fields}`; non-board → `{"ok":false,"off_platform":true,"reason":"not_on_rdk_board","fields":null}`) |
