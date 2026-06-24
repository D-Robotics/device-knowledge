---
name: rk-knowledge
description: 当用户询问 Rockchip RK3588 平台(Rock 5B/5 ITX、OrangePi 5 Plus、Firefly)的 NPU、RKNN 工具链部署时使用;本 skill 只讲 RK3588 平台本身,涉及与 RDK 的选型对比参见 rdk-ecosystem。
---

# Rockchip RK3588 知识

> 来源:整理自 Rockchip / Radxa 官方文档与社区实践,逐条保留出处链接;具体规格与版本以官方为准。

RK3588/RKNN 起步知识:RKNN 工具链、NPU 与板端推理要点。

## RK3588 要点

- 模型用 **RKNN Toolkit 2** 转为 `.rknn`,板端用 `librknnrt` / `rknn_toolkit_lite2` 推理。
- NPU 标称 6 TOPS = **三核合计(单核约 2 TOPS)**;多核分配靠 RKNN 的 `core_mask`,是部署时的实际决策点。
- RKNN 报错先核对系统镜像、内核、NPU runtime(`librknnrt`)与 rknn-toolkit2 版本是否匹配,而非默认模型本身错误。

## 设备与诊断

- 常见开发板:Radxa ROCK 5 系列、Orange Pi 5 系列、Firefly ROC-RK3588S-PC 等;典型 RK3588/RK3588S 板卡是通用 Linux SBC。
- 诊断先用通用只读命令:`uname -a`、`cat /etc/os-release`、`cat /proc/device-tree/model`、`lscpu`、`lsusb`、`dmesg | grep -i rknpu`。
- NPU 可用性取决于镜像内核驱动、`librknnrt` 与模型转换工具版本。

## 常用命令

| 命令模式 | 说明 | 风险 | 适用板型 |
| --- | --- | --- | --- |
| `dmesg\s*\\|\s*grep\s+(-i\s+)?rknpu` | 查看 Rockchip NPU 驱动/运行时内核日志 | safe | radxa-rock-5b/radxa-rock-5-itx/orange-pi-5-plus/firefly-roc-rk3588s-pc |
| `pip\s+install\s+.*rknn\|rknn[-_]toolkit` | 安装 RKNN Toolkit 2(PC 端转换)/ rknn_toolkit_lite2(板端推理)。**v2.3.2 起官方 wheel 已上 PyPI**,可直接 `pip install rknn-toolkit2`(含 x86_64/aarch64);**关键是版本要与板端 `librknnrt` 匹配**——不匹配会触发下方 version mismatch,此时改从官方 RKNPU2_SDK 的 `packages/` 取与板端对应版本的 `.whl` | moderate | radxa-rock-5b/radxa-rock-5-itx/orange-pi-5-plus/firefly-roc-rk3588s-pc |

## 常见故障

- 匹配 `RKNN.*(version|mismatch|init runtime|load model|invalid model)|librknnrt` → RKNN runtime/toolkit 版本不匹配很常见。先核对板端 `librknnrt` / `rknn_toolkit_lite2` 版本,再用匹配的 RKNN Toolkit 2 重新生成 `.rknn` 模型。 (<https://github.com/airockchip/rknn-toolkit2>)

## 设备规格

- **Radxa ROCK 5B** (`rock-5b`):Rockchip RK3588 / 6 TOPS / 8GB / rknn
- **Radxa ROCK 5 ITX** (`rock-5-itx`):Rockchip RK3588 / 6 TOPS / 16GB / rknn
- **Orange Pi 5 Plus** (`orange-pi-5-plus`):Rockchip RK3588 / 6 TOPS / 16GB / rknn
- **Firefly ROC-RK3588S-PC** (`firefly-roc-rk3588s-pc`):Rockchip RK3588S / 6 TOPS / 8GB / rknn

## 官方资料

- [Radxa ROCK 5B Documentation](https://docs.radxa.com/en/rock5/rock5b/getting-started/introduction)
- [Radxa ROCK 5 ITX Documentation](https://docs.radxa.com/en/rock5/rock5itx/getting-started/introduction)
- [Rockchip RKNN Toolkit 2](https://github.com/airockchip/rknn-toolkit2)
- [Orange Pi 5 Plus Product Page](http://www.orangepi.org/html/hardWare/computerAndMicrocontrollers/details/Orange-Pi-5-plus.html)
- [Firefly ROC-RK3588S-PC Wiki](https://wiki.t-firefly.com/en/ROC-RK3588S-PC/)
