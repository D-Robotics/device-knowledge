# RDK S 系列 Linux 高级开发(S100 家族独有主题)

> 来源:D-Robotics 官方文档仓 `rdk_doc`(default branch `main`)`docs_s/07_Advanced_development/02_linux_development/**`,逐主题保留出处路径与在线 URL。在线版:https://developer.d-robotics.cc 。只写文档里有出处的事实,未改写技术结论。

## 适用范围(先看这里)

- 本文覆盖的主题文档目录命名为 **S100X**,适用 **S100 家族(S100 / S100E / S100P)**。hbmem 的 12G / 24G 两种内存模式分别对应 S100(12GB)与 S100P(24GB)。
- **S600 不在这些文档覆盖范围内**:`rdk_doc` 仓当前没有 S600 专属的 `02_linux_development` 高级开发文档。S600 的 hbmem / IPC / EtherCAT 等是否与 S100 一致**未经文档证实**,不要照搬到 S600,以官方 S600 手册为准。
- 这些都是 **Acore(Linux/大脑)侧** 的系统能力;MCU(小脑)侧的 IPC / FreeRTOS / 固件烧录见同 skill 的 [MCU 开发参考](mcu-development.md)。两者互补:本文补的是「大脑侧怎么用 IPC、怎么管共享内存、怎么走 PCIe/EtherCAT/PTP」。

---

## 1. hbmem:零拷贝共享内存(感知-决策-控制流水线的内存底座)

> 来源:`04_driver_development_s100/15_driver_hbmem/01_introduce`、`02_hardware`、`03_software`。

**是什么** —— `libhbmem`(`libhbmem.so` / 头文件 `hb_mem_mgr.h`)对 S100X **系统预留内存** 的统一管理,四大能力:内存分配、内存共享、内存队列、内存池/共享内存池。**非 root 用户无法使用 hbmem API**。

**典型用途** —— 在 CPU / BPU / ISP / Codec / VDSP / MCU(IPC) 之间**零拷贝**传递图像与 featuremap:一个模块产出的 buffer 直接 import 到另一个线程/进程,靠引用计数(consume count)保证不被提前释放。机器人上典型链路:相机/ISP 产出 → BPU 推理输入 → 后处理,全程不拷贝大块内存。

**两种 buffer 类型**:
- `com_buf` —— 整块连续物理内存,适合语音、纯 featuremap。`hb_mem_alloc_com_buf`。
- `graph_buf` —— 图像内存(RGB/RAW 用一个 buffer;**planar YUV 各分量物理地址不连续**),适合 Pyramid 输出。`hb_mem_alloc_graph_buf`;一次申请多个并成组用 `hb_mem_alloc_graph_buf_group`。

**关键接口**(均在 `hb_mem_mgr.h`):
- 生命周期:`hb_mem_module_open` / `hb_mem_module_close`。
- 分配/释放:`hb_mem_alloc_com_buf` / `hb_mem_alloc_graph_buf` / `hb_mem_free_buf`(或 `_with_vaddr` 版)。
- cache 一致性:`hb_mem_flush_buf`(写回内存)/ `hb_mem_invalidate_buf`(使 cache 无效),都有 `_with_vaddr` 变体。
- 跨进程共享:`hb_mem_import_com_buf` / `hb_mem_import_graph_buf`,配 `hb_mem_inc_*_consume_cnt` / `hb_mem_dec_consume_cnt` 管引用计数;`hb_mem_get_share_info` / `hb_mem_wait_share_status` 等待共享就绪。
- 内存池:`hb_mem_pool_create` / `_alloc_buf`(单进程,绕过陷内核态,加速分配);共享内存池 `hb_mem_share_pool_create`(多进程共享,但池内 buffer **等大**、import/free 略慢)。
- 队列:`hb_mem_create_buf_queue` + `hb_mem_dequeue_buf` / `hb_mem_queue_buf`(生产者)/ `hb_mem_request_buf` / `hb_mem_release_buf`(消费者),四态 FREE/DEQUEUE/QUEUE/REQUEST。**环形队列、满了会覆盖最早元素、仅支持单进程**。

**分配属性(`HB_MEM_USAGE_*`,按位组合)**:cache 属性 `HB_MEM_USAGE_CACHED`;读写意图 `CPU_READ_OFTEN`/`CPU_WRITE_OFTEN`(WRITE 自动带 READ);heap 选择 `PRIV_HEAP_DMA`(cma)/`PRIV_HEAP_RESERVED`(carveout)/`PRIV_HEAP_2_RESERVED`(carveout2);初始化 `MAP_INITIALIZED`/`MAP_UNINITIALIZED`;`HW_*`(如 `HW_BPU`/`HW_ISP`/`HW_PCIE`/`HW_IPC`)仅作 debug 标记,不影响分配。

**硬件/内存布局** —— S100X 支持 **12G / 24G interleave** 两种内存模式。默认 ION 预留三类 heap:`cma_reserved`(1GiB)、`carveout`(512MiB)、`cma`(512MiB)。heap 不足时回退顺序为 `cma_reserved => carveout => cma`(或对称组合)。heap 大小可在 dts 改,但要留够系统内存。

**适用** —— S100 / S100E / S100P(12G 模式≈S100,24G 模式≈S100P)。

**坑** —— 不要直接对物理地址 `mmap`/传递,**不会增加引用计数**,存在释放后仍被访问的风险;改用 import 接口。

**文档** —— https://developer.d-robotics.cc/rdk_doc/Advanced_development/linux_development/driver_development_s100/driver_hbmem(以站点实际路由为准;源文件 `docs_s/07_Advanced_development/02_linux_development/04_driver_development_s100/15_driver_hbmem/`)。

---

## 2. Acore 侧 IPC:大脑(Linux)怎么和小脑(MCU)/VDSP/BPU 通信

> 来源:`04_driver_development_s100/06_driver_ipc.md`。**MCU 侧** 的 IPC(`Ipc_MDMA_*` API、IpcBox、receive_coreid 等)见 [mcu-development.md](mcu-development.md) 第 5 节;本节补的是 **Acore/Linux 侧** 的实例分配、设备树配置、实时性调优与用户态 sample,与 MCU 侧不重复。

**是什么** —— IPC(Inter-Processor Communication)= **共享内存(buffer-ring)+ MailBox 核间中断**。Acore 侧对外封装为 `libipcfhal`(用户态↔内核态),底层是 IPCF 驱动;Acore↔VDSP 走 RPMSG(开源框架)。

**实例分配方案**(Acore 侧实例号 0-34):
- `[0-14]` Acore↔MCU(其中 `[0-8]` 可用,`[4-6]` 默认客户预留,不用 CANHAL/规控可自行改配置)。
- `[22-24]` Acore↔VDSP(RPMSG,暂未对客户开放)。
- `[32-34]` Acore↔BPU。

**Acore 侧配置**(设备树)—— `source/hobot-drivers/kernel-dts/drobot-s100-ipc.dtsi`(及 `include/drobot_s100_ipc.h`)。每实例配 `instance--num_chans--num_bufs--buf_size`;约束:`通道数 * buf 个数 * buf 大小 <= 0.5MB`(数据段每实例预分配 1MB,Acore/MCU 各半);通道数 <= 32、buf 个数 <= 1024。**Acore 与 MCU 两侧的通道数/buf 数/大小必须一致,data/ctrl 段的 local 与 remote 相反**。

**典型用途** —— OTA、诊断、规控、CANHAL 等业务;以及 IpcBox 把 MCU 侧 UART/SPI/I2C 外设透传到 Acore。

**实时性优化(机器人硬实时回路关键,以 ipc_instance5 为例)**:
```bash
cat /proc/interrupts | grep mailbox   # 按 dts mboxes=<&mailbox0 5 21 5> 推出中断号(此例 19)
ps aux | grep mailbox                  # 找中断线程 pid(此例 75)
echo 4 > /proc/irq/19/smp_affinity     # 中断绑到 CPU2,减少迁移
taskset -p 0x04 75                     # 中断线程绑核 CPU2
chrt -f -p 99 75                       # SCHED_FIFO 优先级 99,防被高优任务打断
# uboot 下隔离 CPU(setenv bootargs "${bootargs} isolcpus=2 nohz_full=2 rcu_nocbs=2"; saveenv; reset)
cat /sys/devices/system/cpu/isolated   # 确认隔离生效
echo -1 > /proc/sys/kernel/sched_rt_runtime_us   # 放开 RT(慎用,可能饿死普通任务)
```

**用户态 sample** —— `/app/ipcbox_sample/`:`ipcbox_runcmd`(读 MCU ADC)、`ipcbox_uart`(UART 透传回环,S100 默认 Uart5,需 TX/RX 短接)、`ipcbox_spi`(SPI3 MOSI/MISO 短接回环)、`ipcbox_i2c`(detect/get/set)。**前提:先启动 MCU1,并确认 MCU 侧外设已配为透传**。另有 Python 库 `pyhbipchal`(pybind11 封装,`/app/pyhbipchal_sample/`)。

**坑** —— 错误码 `IPCF_HAL_E_CHANNEL_INVALID`(14):内核态 RingBuffer 满(写)或空(读),建议等 1-2ms 重试。

**适用** —— S100 家族(Acore 是 6×A78AE 跑 Ubuntu 22.04)。

**文档** —— 源文件 `docs_s/07_Advanced_development/02_linux_development/04_driver_development_s100/06_driver_ipc.md`。

---

## 3. PCIe:RC/EP、多 S100 拓扑与 PCIe 加速卡

> 来源:`04_driver_development_s100/13_driver_pcie/01_hw_guide`、`02_sw_arch`、`04_libhbpciehal`。

**是什么/规格(S100E)** —— 2 个 PCIe Gen4 控制器,**每个都可配 RC 或 EP**;EP 模式支持 **SR-IOV(1 PF + 4 VF)**、8 对 DMA、MSI-X、SMMU、48 Outbound、**PTM 时间同步**。

**典型用途/拓扑**(5 种):①双 S100X 直连(一 RC 一 EP);②三 S100X(一 RC 接两 EP);③S100X 接第三方标准 EP(如 NVMe SSD);④**S100X 作 EP 接第三方 RC(典型:S100X 当 PCIe AI 加速卡)**;⑤经 PCIe Switch 接多 S100X + 第三方 EP。

**驱动加载** —— RC 端:`modprobe hobot-pcie / hobot-pcie-rc / hobot-pcie-ep-dev / hobot-pcie-dev-manager`;EP 端:`modprobe hobot-pcie / hobot-pcie-ep-fun`。源码在 `hobot-drivers/pcie/`。

**用户态 High Level API** —— `libhbpciehl.so`(基于 Low Level `libhbpcie.so`),抽象出 **topic / publish / subscribe**,屏蔽不同地瓜芯片硬件差异:
```c
pcieInit(&ph, chipID, topicID); pcieDeInit(ph);
pciePublish(ph, weight); pcieSubscribe(ph);
pcieAllocInnerBuf(...) / pcieRegisterUserBuf(...);  // 用户 buffer 需物理连续
pcieStartRecv(ph, callback, data); pcieSendData(ph, size);
```
发送方 `pcieInit→pcieAlloc/Register Buf→pciePublish→pcieSendData`,接收方 `pcieInit→pcieSubscribe→pcieStartRecv`。

**适用** —— 文档以 S100E 规格给出,适用 S100X 家族;具体 lane/控制器数以板型硬件手册为准。

**文档** —— 源文件 `docs_s/07_Advanced_development/02_linux_development/04_driver_development_s100/13_driver_pcie/`。

---

## 4. EtherCAT:多轴运动控制主站(机器人优先)

> 来源:`04_driver_development_s100/16_driver_ethernet/02_ethercat.md`。

**是什么** —— S100 默认提供 **EtherCAT-IgH 1.5** 开源主站协议栈(deb 包 `hobot-ethercat`,含内核模块 + 用户层应用)。**EtherCAT 与普通以太网协议互斥,无法共存**(占用网口时 eth 不可用)。

**典型用途** —— 工业/机器人多轴伺服、运动控制总线主站,周期性下发 PDO 控制多个伺服从站。

**关键命令**:
```bash
systemctl start ethercat.service        # 启动主站服务
sudo ethercat master                     # 查看主站状态(Phase/Slaves/网口/帧统计)
sudo cp script/ethercat.service /lib/systemd/system/ && sudo systemctl enable ethercat  # 自启
```
板端从源码编译:`git clone https://gitlab.com/etherlab.org/ethercat.git -b stable-1.5`,`./configure --enable-kernel --enable-generic --enable-igb --disable-eoe --enable-hrtimer --with-linux-dir=...`,再 `make / make modules / make install`;配置 `/usr/local/etc/ethercat.conf` 的 `MASTER0_DEVICE="eth0"`、`DEVICE_MODULES="generic"`。

**适用** —— S100 家族。**搭配 §2 的 IPC 绑核/隔核与 §5 的 PTP 时间同步可提升运动控制实时性与多轴对齐。**

**文档** —— 源文件 `.../16_driver_ethernet/02_ethercat.md`;协议栈 https://etherlab.org/en_GB/ethercat 。

---

## 5. 时间同步:PTP / gPTP(多传感器/多轴时间对齐)

> 来源:`04_driver_development_s100/12_driver_timesync.md`。

**是什么** —— `linuxptp` 的 **ptp4l + phc2sys** 两件套:ptp4l 跑 PTP/gPTP(可作 master 或 slave),phc2sys 在 PHC(网卡硬件时钟)与 Linux 系统时钟之间互同步。支持硬件时间戳(`-H`,默认)。

**典型用途** —— 机器人/自动驾驶多传感器与多轴控制的统一时基;附带 **automotive profile** 示例(`automotive-master.cfg` / `automotive-slave.cfg`,L2 传输、P2P delay、gPTP),位于 `/usr/hobot/lib/pkgconfig/`。

**关键命令**:
```bash
# Master:
ptp4l -i eth0 -f /usr/hobot/lib/pkgconfig/automotive-master.cfg -m -l 7
# Slave:
ptp4l -i eth0 -f /usr/hobot/lib/pkgconfig/automotive-slave.cfg -m -l 7 > ptp4l.log &
phc2sys -s eth0 -c CLOCK_REALTIME --transportSpecific=1 -m --step_threshold=1000 -w > phc2sys.log &
```
slave log 中 `master offset` 收敛到个位/十位即同步正常。配置文件语法见 https://linuxptp.nwtime.org/documentation/ptp4l/ 。

**适用** —— S100 家族(PCIe 控制器另支持 PTM 时间同步,见 §3)。

**文档** —— 源文件 `.../12_driver_timesync.md`。

---

## 6. 系统 OTA 与 miniboot 单独升级

> 来源:`06_OTA/01_ota_system.md`、`06_OTA/02_ota_miniboot.md`。

**是什么** —— 设备端 OTA 交付物为 `libupdate.so`(底层烧写/校验 API),上层 OTA 服务与云端对接由客户实现。分区分三类:**持久化**(ubootenv/veeprom/userdata,不升级)、**AB**(boot_a/boot_b,交替升级)、**BAK**(主分区 + 备份,主升级验证成功后同步到备份)。

**根文件系统(开启 OTA 后)** —— `system_A`/`system_B`(只读 lowerdir,AB 双分区无缝升级)+ `overlay`(可写 upperdir,**不参与升级**)+ `/`(merged 视图)的 **overlayfs**:用户对 `/etc/xxx` 等的修改写进 overlay,OTA 升级 system 分区后用户改动仍优先生效。

**开启 OTA(默认关闭)** —— 改 `build_params/*.conf` 的 `PARTITION_FILE="s100-ota-gpt.json"` 与 `RDK_DM_VERIFY_ENABLE="yes"`,改 `board_s100_*.mk` 的 `RDK_OTA="yes"`,`./mk_debs.sh hobot-miniboot` 后 `sudo ./pack_image.sh -l` 重编。OTA 包支持 `.zip` 与 `.zst.tar`(img 经 zstd 压缩,压缩比/解压更优)。

**miniboot 单独升级**(`02_ota_miniboot.md`,**非 OTA 镜像也可用,重启生效**)—— 基于 OTA 分区级机制,**只升级 BAK 与 AB 分区**(`HSM_FW/HSM_RCA/keyimage/SBL/scp/spl/MCU/acore_cfg/bl31/optee/uboot`),**不碰 Permanent 分区**;失败自动回滚不变砖;**不支持升级分区表**(分区表有改动须用地瓜工具整烧)。命令:
```bash
sudo apt-get install -y hobot-miniboot
sudo rdk-miniboot-update --build release --reboot y   # --build release|debug(默认 release);--reboot y|n
```

**适用** —— S100 家族(分区表名 `s100-ota-gpt.json`、`board_s100_*.mk`)。

**文档** —— 源文件 `docs_s/07_Advanced_development/02_linux_development/06_OTA/`。

---

## 速查:这些主题归谁、典型机器人场景

| 主题 | 一句话 | 机器人典型场景 | 适用板型 |
|------|--------|----------------|----------|
| hbmem | 零拷贝共享内存 + 队列/池 | 相机→BPU→后处理不拷贝大块内存 | S100/S100E/S100P |
| Acore IPC | Linux↔MCU/VDSP/BPU 核间通信 + 实时绑核 | 大脑下发指令给小脑硬实时回路 | S100 家族 |
| PCIe | RC/EP、多板拓扑、加速卡、pub/sub API | S100 当 AI 加速卡 / 多板互联 | S100E 规格 |
| EtherCAT | IgH 1.5 运动控制主站 | 多轴伺服总线控制 | S100 家族 |
| PTP/gPTP | ptp4l + phc2sys 时间同步 | 多传感器/多轴统一时基 | S100 家族 |
| OTA / miniboot | AB/BAK + overlayfs / 单独升 miniboot | 量产设备远程升级、bootloader 热修 | S100 家族 |
