# RDK 常见故障速查

> 来源:整理自 D-Robotics RDK 官方文档、工具链与社区实践,逐条保留出处链接;由 device-knowledge 知识库忠实转换而来,未改写技术事实。

按"错误现象 → 排查建议 → 文档"组织,逐条来自官方文档与社区案例。

### 1. 现象

匹配:`terminate called after throwing|exit code -6|SIGABRT`

**建议**:摄像头节点崩溃 — 用 `v4l2-ctl -d /dev/video0 --list-formats-ext` 确认格式；USB 摄像头需设为 MJPEG（非默认 YUYV），分辨率用 640x480 先验证

文档:<https://developer.d-robotics.cc/rdk_doc/Basic_Application/vision/usb_camera>

### 2. 现象

匹配:`did not receive image data|No image data|timeout.*image`

**建议**:无图像数据 — 确认 pixel_format=MJPEG、分辨率与 v4l2 能力一致、/dev/videoN 正确；换 /dev/video1 试试

文档:<https://developer.d-robotics.cc/rdk_doc/Basic_Application/vision/usb_camera>

### 3. 现象

匹配:`VIDIOC_S_FMT.*Invalid argument|VIDIOC_REQBUFS.*Invalid`

**建议**:摄像头格式不支持 — `v4l2-ctl --list-formats-ext` 查支持列表，宽高/fps 必须精确匹配列表中的一档

### 4. 现象

匹配:`select timeout|camera.*timeout|v4l2.*timeout`

**建议**:摄像头超时 — 可能 USB 带宽不足或驱动冲突；尝试降低分辨率/帧率，或拔插 USB 重试

### 5. 现象

匹配:`No such file.*\.(hbm|bin)|model.*not found|cannot open.*model`

**建议**:模型文件未找到 — `find /opt/tros -name "*.hbm" -o -name "*.bin"` 定位真实路径，不要依赖相对路径

### 6. 现象

匹配:`out of memory|OOM|Cannot allocate memory|MemoryError|std::bad_alloc`

**建议**:BPU/RAM OOM — `cat /sys/devices/system/bpu/bpu0/ratio && free -h` 查占用（X5 也可用 `hrut_bpuprofile -b 0`）；减小 batch_size、用更小模型、或 kill 占用 BPU 的进程

### 7. 现象

匹配:`hbm.*version.*mismatch|model.*incompatible|invalid model|model format error`

**建议**:模型格式不兼容 — X3=Bernoulli2, X5/Ultra=Bayes, S100=Nash，hbm/bin 跨架构不通用，需用对应工具链重新编译

### 8. 现象

匹配:`hb_mapper.*failed|convert.*error|calibration.*fail|compile.*failed`

**建议**:模型转换失败 — 检查 ONNX opset 版本、不支持的算子、校准数据格式；用 `hb_mapper checker` 先验证 ONNX

文档:<https://developer.d-robotics.cc/rdk_doc/Advanced_development/toolchain_development/overview>

### 9. 现象

匹配:`unsupported op|not support.*operator|op.*not implemented`

**建议**:算子不支持 — 查官方算子列表；Transformer/Attention 算子仅 S100 (Nash) 部分支持，X3/X5 需替换为等效 CNN 结构

文档:<https://developer.d-robotics.cc/rdk_doc/Advanced_development/toolchain_development/expert/api_reference>

### 10. 现象

匹配:`NO_PUBKEY|gpg.*key.*expired|public key.*not available|公钥.*不可用`

**建议**:APT 公钥失效 — D-Robotics 源公钥过期或源配置不完整：优先按官方 TROS 安装文档重新配置 apt source/keyring，再 `sudo apt update` 验证

文档:<https://developer.d-robotics.cc/rdk_doc/Robot_development/quick_start/install_tros>

### 11. 现象

匹配:`E: Unable to locate package tros[-_]?(humble|foxy)|无法找到软件包 tros`

**建议**:TROS 包找不到 — apt source 未配置或版本不匹配：`sudo apt update` 后仍失败请检查 /etc/apt/sources.list.d/ 是否含 d-robotics 源；TROS 默认走 humble

文档:<https://developer.d-robotics.cc/rdk_doc/Robot_development/quick_start/install_tros>

### 12. 现象

匹配:`apt.*Could not get lock|dpkg.*locked|E: Could not open lock file`

**建议**:APT 锁未释放 — 先用 `ps -ef | grep -E "apt|dpkg"` 确认没有 apt/dpkg 进程；若上次安装中断，再执行 `sudo dpkg --configure -a` 后重试 `sudo apt update`

### 13. 现象

匹配:`source.*setup\.bash.*No such file|\/opt\/tros.*not found`

**建议**:TROS 未安装或路径错误 — `ls /opt/tros/humble/setup.bash` 确认；S100 部分镜像需 `su - sunrise` 后再 source

### 14. 现象

匹配:`Package.*not found|package.*does not exist|not a ros2 package`

**建议**:ROS2 包未找到 — `ros2 pkg list | grep <name>` 确认；可能需 `apt install ros-humble-<pkg>` 或从源码 colcon build

### 15. 现象

匹配:`no executable found|No such file or directory.*ros2|ros2:.*command not found`

**建议**:ROS2/TROS 不在 PATH — `source /opt/tros/humble/setup.bash`；S100 试 `su - sunrise`（部分镜像仅该用户配了 TROS）

### 16. 现象

匹配:`topic.*not available|waiting for.*publisher|no publishers`

**建议**:话题无发布者 — `ros2 node list` + `ros2 topic list` 确认上游节点是否运行；检查 QoS 是否匹配

### 17. 现象

匹配:`Failed to load entry point|plugin.*not found|pluginlib`

**建议**:ROS2 插件加载失败 — 确认包已安装且 setup.bash 已 source；`colcon build` 后需 `source install/setup.bash`

### 18. 现象

匹配:`DDS.*error|rmw.*error|RTPS`

**建议**:DDS 通信错误 — 检查网络配置；多机通信需 `ROS_DOMAIN_ID` 一致，防火墙放行 UDP 7400-7500+

### 19. 现象

匹配:`multiple publishers.*same topic|domain.*conflict|多个发布者.*同名 topic`

**建议**:同网段多设备 ROS_DOMAIN_ID 冲突 — 在 ~/.bashrc 设置不同 ID：`export ROS_DOMAIN_ID=42`（0-101）；重新 `source ~/.bashrc` 后再启动节点

### 20. 现象

匹配:`Permission denied|Operation not permitted|EACCES`

**建议**:权限不足 — GPIO/I2C/SPI 需 root 或 sudo；`/dev/video*` 权限问题尝试 `chmod 666`

### 21. 现象

匹配:`Device or resource busy|EBUSY`

**建议**:设备被占用 — `lsof /dev/<device>` 或 `fuser -v /dev/<device>` 找到占用进程并 kill

### 22. 现象

匹配:`Read-only file system|EROFS`

**建议**:只读文件系统 — `/app` 等目录可能只读；写入 `/tmp`、`/userdata`、`$HOME` 等可写路径

### 23. 现象

匹配:`lsusb.*no permission|cannot open USB device|libusb.*LIBUSB_ERROR_ACCESS`

**建议**:USB 设备无权限 — 添加 udev rules：`sudo tee /etc/udev/rules.d/99-rdk.rules <<< 'SUBSYSTEM=="usb",MODE="0666"' && sudo udevadm control --reload && sudo udevadm trigger`；再重新插拔

### 24. 现象

匹配:`Connection refused|Network is unreachable|Could not resolve host|ENETUNREACH`

**建议**:网络不通 — `ip addr` 看 IP、`ping 8.8.8.8` 测外网、`ping <gateway>` 测网关；可能需配 WiFi/有线

### 25. 现象

匹配:`Connection timed out|ssh.*timeout|ETIMEDOUT`

**建议**:SSH/连接超时 — 确认设备 IP、检查防火墙、确保设备已上电且网线/WiFi 已连

### 26. 现象

匹配:`Host key verification failed|REMOTE HOST IDENTIFICATION`

**建议**:SSH 主机密钥变更 — 设备重刷系统后密钥会变；`ssh-keygen -R <ip>` 清除旧密钥后重连

### 27. 现象

匹配:`No space left on device|ENOSPC`

**建议**:磁盘已满 — `df -h` 查各分区；清理 `/tmp`、apt 缓存（`apt clean`）、旧日志；SD 卡可 `resize2fs` 扩展

### 28. 现象

匹配:`under[-_ ]?voltage|throttled.*0x[0-9a-f]+|undervoltage detected|供电不足`

**建议**:RDK 供电不足 — 需 5V/3A 以上电源（Ultra/S100 推荐 5V/5A）；HDMI 红灯快闪、莫名重启即供电不足；尽量用官方电源，避免 USB-A→USB-C 转接

### 29. 现象

匹配:`System halted|kernel panic.*hung|hung_task.*timeout`

**建议**:系统挂死 — 首查供电（dmesg 是否有 under-voltage）、再查温度（`cat /sys/class/thermal/thermal_zone*/temp` > 85°C 需散热）、最后查 SD 卡是否坏块

### 30. 现象

匹配:`dd:.*Read-only file system|write[ -]?protect|无法写入.*只读`

**建议**:SD 卡写保护 — 拨动适配器侧面的 LOCK 开关至解锁位；某些读卡器无法正确传递写保护信号，建议换 USB 读卡器

### 31. 现象

匹配:`GPT.*corrupt|Backup GPT table is corrupt|invalid GPT|gptcheck.*failed`

**建议**:GPT 分区表损坏 — 用 `sudo sgdisk -e /dev/sdX` 修复备份头；若刷机中断导致整盘脏，建议 `sudo wipefs -a /dev/sdX` 后重刷整镜像

### 32. 现象

匹配:`xburn.*(failed|error)|mcu.*upgrade.*fail|S100.*MCU.*(失败|错误)`

**建议**:S100 MCU 升级失败 — 确认拨码/按键已进入官方文档要求的下载模式，USB 直连不走 hub；优先用 RDK Studio 或官方 xburn 工具重试，并记录完整日志

### 33. 现象

匹配:`ModuleNotFoundError|ImportError.*No module named`

**建议**:Python 模块缺失 — `pip3 install <module>`；板端无网络时需离线安装 whl（注意匹配 Python 版本和 aarch64 架构）

### 34. 现象

匹配:`hobot_dnn.*import|hobot_vio.*import|from hobot`

**建议**:hobot Python SDK 导入失败 — 确认使用系统 Python（不是 conda/venv），且 `/usr/lib/python3/dist-packages/hobot*` 存在

### 35. 现象

匹配:`docker.*not found|Cannot connect to the Docker daemon`

**建议**:Docker 未安装或未启动 — `systemctl start docker`；板端安装: `apt install docker.io`

### 36. 现象

匹配:`exec format error|standard_init_linux|Exec format error`

**建议**:容器架构不匹配 — RDK 是 aarch64，需拉取 arm64 镜像，不能用 x86 镜像

### 37. 现象

匹配:`stereo.*calibration|calib.*not found|no calibration file`

**建议**:StereoNet 缺标定文件 — 先按 hobot_stereonet 仓库 README 完成双目内/外参标定，把 yaml 放到 launch 指定目录

文档:<https://github.com/D-Robotics/hobot_stereonet>

### 38. 现象

匹配:`livox.*not.*connect|lidar.*offline|pcap.*not exist|MID-?360|HAP`

**建议**:Livox 雷达连接失败 — 用 `ip addr` 确认网卡 IP 与雷达 IP 同网段（默认 192.168.1.1xx），检查防火墙放行 UDP 56000-56010；Mid-360 出厂 IP 与 HAP 不同

文档:<https://github.com/D-Robotics/livox_ros_driver2>

### 39. 现象

匹配:`ALSA lib.*unable to open slave|snd_pcm_open.*failed|cannot open audio device`

**建议**:音频设备打开失败 — 先 `aplay -l` 确认有声卡；被占用用 `fuser -v /dev/snd/*` 找占用；如 PulseAudio 占着 `pactl suspend-sink 0` 或 `systemctl stop pulseaudio` 临时释放

### 40. 现象

匹配:`no soundcards found|Device or resource busy.*snd|no such audio device`

**建议**:无声卡识别 — `lsusb` 看 USB 声卡/麦在不在，`dmesg | grep -i "audio\|snd"` 看加载情况；RDK 板多数型号无板载 3.5mm，**最稳方案是插 USB 声卡**，内核自动加载 snd-usb-audio

### 41. 现象

匹配:`aplay:.*Dac failed|audio underrun|xrun|buffer underrun`

**建议**:音频 xrun/underrun — CPU 占用高或 PulseAudio 抢占；用 `aplay -D plughw:<card>,<dev>` 直连 ALSA 避开 PA；或降采样率（16kHz 够语音用）

### 42. 现象

匹配:`arecord:.*main.*Invalid argument|arecord.*Channels count non available`

**建议**:arecord 参数错 — `arecord -l` 确认设备，`arecord -D plughw:<card>,<dev> --dump-hw-params` 看支持的采样率/通道/格式；USB 麦常见 16000 Hz / 单声道 / S16_LE

### 43. 现象

匹配:`Could not open file.*\/dev\/i2c|No such file.*i2c-\d+|i2c.*not found`

**建议**:I2C 总线节点不存在 — `ls /dev/i2c-*` 看有哪些；RDK 若缺目标总线，引脚可能被默认配成 GPIO，需要先用 `/app/40pin_samples/config_40pin_pinmux.py` 切到 I2C 模式

### 44. 现象

匹配:`i2cdetect.*could not set address|Remote I\/O error|I\/O error.*i2c|EREMOTEIO`

**建议**:I2C 读写失败 — `i2cdetect -y <bus>` 先扫地址确认设备在；地址冲突时检查跳线；供电不足（PCA9685/OLED 无 V+ 独立电源）也会出现该错

### 45. 现象

匹配:`PCA9685.*not found|adafruit.*PCA9685.*ValueError|No I2C device at address 0x40`

**建议**:PCA9685 未识别 — `i2cdetect -y <bus>` 应看到 `0x40`；看不到的常见原因：接线反、VCC 未接 3.3V/5V、I2C 总线号填错（Python 里 busio.I2C 默认 1，RDK 按实际总线改）

### 46. 现象

匹配:`pwm.*export.*failed|pwmchip.*not found|No such file.*\/sys\/class\/pwm`

**建议**:PWM 通道不可用 — `ls /sys/class/pwm/` 看有哪些 chip；RDK 上若缺目标 pwmchip，引脚未切到 PWM 复用 → 先跑 Pinmux 脚本；超过板子硬件 PWM 路数（X3=2, X5=8）时建议改 PCA9685

### 47. 现象

匹配:`Invalid argument.*duty_cycle|duty_cycle.*greater than period`

**建议**:PWM duty_cycle 越界 — duty_cycle 必须 ≤ period；舵机 50Hz 场景：period=20000000（ns），duty_cycle 在 1000000~2000000 之间（1ms ~ 2ms）

### 48. 现象

匹配:`gpiod\.LineBulk.*Busy|gpioset.*EBUSY|line.*already requested`

**建议**:GPIO line 被占用 — 另一进程或前一次脚本没释放；`sudo lsof | grep gpio` 查；脚本里用 `with` 或 `try/finally + line.release()` 保证释放

### 49. 现象

匹配:`No such device or address.*gpio|gpiochip\d+.*not found`

**建议**:gpiochip 不存在 — `gpiodetect` 看实际 chip 编号；RDK 各板 chip 编号不同，不要照抄 RPi 的 `gpiochip0`；优先用 `gpiofind "<line name>"` 自动定位

### 50. 现象

匹配:`import Hobot\.GPIO.*No module|ModuleNotFoundError.*Hobot`

**建议**:Hobot.GPIO 只认系统 Python — `which python3` 确认不是 conda/venv；正确路径一般 `/usr/bin/python3`；若缺包 `sudo apt install python3-hobot-gpio`（或跨平台兜底用 `libgpiod`）

### 51. 现象

匹配:`Permission denied.*\/dev\/tty(USB|ACM|S|HS)`

**建议**:串口权限不足 — 当前用户不在 `dialout` 组：`sudo usermod -aG dialout $USER` 然后**重新登录**（不是 `sudo su` 切换）；临时用 `sudo chmod 666 /dev/ttyUSB0`

### 52. 现象

匹配:`could not open port|SerialException.*could not open`

**建议**:串口打不开 — `ls /dev/tty{USB,ACM,S,HS}*` 确认存在；设备名没出现多半是 USB 转 TTL 芯片驱动没装（CP210x/CH340/FTDI），`dmesg | tail` 看最近插拔日志

### 53. 现象

匹配:`No such device|ENODEV|Device not found`

**建议**:设备未识别 — 跑通用 9 步诊断：`dmesg | tail -50 && lsusb && ls /dev/tty* /dev/video* /dev/i2c-* /dev/snd/`；定位到具体接口（USB / I2C / UART / CSI）再针对性排查

### 54. 现象

匹配:`upload.*failed|HTTP\s+413|file.*too large|Payload Too Large`

**建议**:论坛上传失败 — 单文件上限约 12MB（实际看 Discourse 设置）；图片建议长边 1280px 内；超大日志改用 .zip 或粘到 gist 后给链接

### 55. 现象

匹配:`short_url.*missing|uploads\.json.*csrf|CSRF.*invalid`

**建议**:论坛上传 CSRF/会话失效 — 调用 `forum_drobotics_auth_status` 重新拉取 Cookie；若仍失败，让用户重新登录主账号或在对话提供凭据

### 56. 现象(S 系列工具链)

匹配:`hb_mapper.*not found|command not found.*hb_mapper`(在 S100/S100P/S600 上)

**建议**:S 系列(Nash)工具链命令是 **`hb_compile`**(产 `.hbm`),不是 X 系列的 `hb_mapper`(产 `.bin`)。例:`hb_compile --model x.onnx --march nash-e`。转换在主机 Docker(天工开物/OE)里跑,板上只有 `hbm_runtime`。详见 rdk-device 的 toolchain-workflow。

### 57. 现象(S 系列模型)

匹配:`No such file.*\.hbm|hbm_runtime.*not found|HB_HBMRuntime|invalid march|march.*nash`

**建议**:① 找不到 `.hbm` → S100/S100P/S600 模型是 `.hbm`(非 `.bin`),`find / -name "*.hbm"` 定位,或从 `rdk_model_zoo_s`(s100 分支)取预编译。② `hbm_runtime` 缺失 → `sudo apt-get install hobot-dnn` 后 `pip install /tmp/hbm_runtime-*.whl`。③ `march` 错 → **S100=`nash-e`、S100P=`nash-m`**(官方 FAQ),S600=`nash`;别套 X 系列 `bayes-e`/`bernoulli2`。

### 58. 现象(S 系列 TROS 版本)

匹配:`/opt/tros/humble.*No such file`(在 RDK S600 上)

**建议**:**RDK S600 是 Ubuntu 24.04 / ROS2 Jazzy**,TROS 在 `/opt/tros/jazzy/`、`apt` 包名 `tros-jazzy-*`;别在 S600 上找 humble(那是 X3/X5/Ultra/S100/S100P 的)。

### 59. 现象(S100/S600 连不上板)

匹配:`No route to host|Connection timed out`(首次连 S100/S600)

**建议**:S100/S600 双千兆口中 **eth1 出厂固定静态 IP `192.168.127.10`**(管理口),eth0 走 DHCP。连不上先把电脑网卡设同网段后 `ssh root@192.168.127.10`(或 `sunrise@...`)。
