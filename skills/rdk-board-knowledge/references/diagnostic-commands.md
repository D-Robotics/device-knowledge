# RDK 诊断与系统命令

> 来源:整理自 D-Robotics RDK 官方文档、工具链与社区实践,逐条保留出处链接;由 device-knowledge 知识库忠实转换而来,未改写技术事实。

## 诊断 / 系统 / 工具链命令

| 命令模式 | 说明 | 风险 | 适用板型 |
| --- | --- | --- | --- |
| `^hrut_bpuprofile(\s\|$)` | BPU profiling tool (X5/Ultra; use -b 0 to select bpu0) | safe | x3/x5/ultra/s100/s100p/s600 |
| `cat\s+\/sys\/devices\/system\/bpu\/bpu\d+\/ratio` | BPU utilization via sysfs (universal across all RDK boards, recommended fallback) | safe | x3/x5/ultra/s100/s100p/s600 |
| `cat\s+\/sys\/devices\/system\/bpu\/bpu\d+\/devfreq` | BPU current frequency via sysfs (universal) | safe | x3/x5/ultra/s100/s100p/s600 |
| `^hrut_smi$` | BPU utilization monitor (X3 only; NOT installed on RDK X5 — use hrut_bpuprofile or sysfs instead) | safe | x3/x5/ultra/s100/s100p/s600 |
| `^bputop$` | BPU load top-like view (X3/Ultra only; NOT installed on RDK X5 — use hrut_bpuprofile or sysfs) | safe | x3/x5/ultra/s100/s100p/s600 |
| `^hrut_count$` | BPU inference counter | safe | x3/x5/ultra/s100/s100p/s600 |
| `^hrut_somstatus$` | SoC status (temperature, voltage, clock) — universal across all RDK boards | safe | x3/x5/ultra/s100/s100p/s600 |
| `cat\s+\/sys\/devices\/virtual\/thermal` | CPU/BPU thermal zone reading | safe | x3/x5/ultra/s100/s100p/s600 |
| `cat\s+\/sys\/class\/socinfo` | SoC identification (board_id, chip_id) | safe | x3/x5/ultra/s100/s100p/s600 |
| `free\s+-[hm]` | Memory usage | safe | x3/x5/ultra/s100/s100p/s600 |
| `df\s+-[hT]` | Disk space usage | safe | x3/x5/ultra/s100/s100p/s600 |
| `dmesg` | Kernel ring buffer (hardware/driver logs) | safe | x3/x5/ultra/s100/s100p/s600 |
| `journalctl` | Systemd journal logs | safe | x3/x5/ultra/s100/s100p/s600 |
| `\btop\s\|htop` | Process/CPU monitor | safe | x3/x5/ultra/s100/s100p/s600 |
| `hbdk` | BPU model compilation toolchain (Horizon OE) | moderate | **x3/x5/ultra 限定**（S 系列用天工开物 OE） |
| `hb_mapper` | ONNX→**.bin** model conversion（X 系列专属） | moderate | **x3/x5/ultra 限定**（S100/S100P/S600 用 `hb_compile`） |
| `hb_compile` | ONNX→**.hbm** model conversion（S 系列天工开物，如 `hb_compile --model x.onnx --march nash-e`） | moderate | s100/s100p/s600 |
| `hb_eval_perf` | BPU .bin model performance evaluation | safe | x3/x5/ultra 限定 |
| `hb_model_modifier` | Compiled .bin model inspection/modification | moderate | x3/x5/ultra 限定 |
| `hrt_model_exec` | Run inference on compiled .bin model | safe | x3/x5/ultra 限定 |
| `\bapt(?:-get)?\s+(install\|update\|upgrade\|remove\|purge)` | APT package management | moderate | x3/x5/ultra/s100/s100p/s600 |
| `pip3?\s+install` | Python package install | moderate | x3/x5/ultra/s100/s100p/s600 |
| `npm\s+install` | Node.js package install | moderate | x3/x5/ultra/s100/s100p/s600 |
| `systemctl\s+(start\|stop\|restart\|enable\|disable\|status)` | Systemd service management | moderate | x3/x5/ultra/s100/s100p/s600 |
| `nmcli` | NetworkManager CLI (WiFi/ethernet) | moderate | x3/x5/ultra/s100/s100p/s600 |
| `ip\s+(addr\|link\|route)` | IP address/routing query | safe | x3/x5/ultra/s100/s100p/s600 |
| `docker\s+(run\|exec\|build\|compose)` | Docker container management | moderate | x3/x5/ultra/s100/s100p/s600 |
| `make\s+-C\s+\/lib\/modules\/[^ ]+\/build\s+M=` | Out-of-tree kernel module build in workspace | moderate | x3/x5/ultra/s100/s100p/s600 |
| `apt(?:-get)?\s+install\b.*linux-headers` | Kernel headers for driver build (does not install a boot kernel) | moderate | x3/x5/ultra/s100/s100p/s600 |
| `\b(insmod\|rmmod\|modprobe)\b` | Temporary kernel module load/unload; runtime risk but not persistent by itself | moderate | x3/x5/ultra/s100/s100p/s600 |
| `dd\s+if=` | Raw disk write (dd) | dangerous | x3/x5/ultra/s100/s100p/s600 |
| `mkfs` | Filesystem format | dangerous | x3/x5/ultra/s100/s100p/s600 |
| `rm\s+-rf?\s+\/` | Recursive root delete | dangerous | x3/x5/ultra/s100/s100p/s600 |
| `fdisk\|parted` | Partition table modification | dangerous | x3/x5/ultra/s100/s100p/s600 |
| `flashcp\|flash_erase` | Flash memory write/erase | dangerous | x3/x5/ultra/s100/s100p/s600 |
| `make\b.*modules_install\|depmod\b` | Kernel module installation / dependency index mutation | dangerous | x3/x5/ultra/s100/s100p/s600 |
| `update-initramfs\|mkinitramfs\|dracut\|rdk-miniboot-update\|hbupdate\|u-boot-update\|fw_setenv` | Boot chain / initramfs / bootloader mutation | dangerous | x3/x5/ultra/s100/s100p/s600 |
| `(?:cp\|mv\|install\|rsync\|tee\|sed\s+-i\|rm\|chmod\|chown\|>\|>>).*(?:\/boot\|\/lib\/modules\|\/etc\/(fstab\|modules\|modules-load\.d\|modprobe\.d))` | Boot or kernel module path write | dangerous | x3/x5/ultra/s100/s100p/s600 |
