# 从源码构建 RDK OS 镜像与 TROS

> 来源:[D-Robotics/rdk-gen](https://github.com/D-Robotics/rdk-gen)、[x5-rdk-gen](https://github.com/D-Robotics/x5-rdk-gen)、[manifest](https://github.com/D-Robotics/manifest)、[robot_dev_config](https://github.com/D-Robotics/robot_dev_config) README,逐条保留出处;命令以仓库当前分支为准。**这是高级/定制场景**——只装系统/跑应用不需要从源码构建,直接烧官方镜像即可(见 rdk-ecosystem 的镜像烧录文档)。

## 何时需要从源码构建

- 要**定制 OS 镜像**(改根文件系统、预装包、分区)。
- 要**改内核 / 设备树 / 驱动**、适配新摄像头 sensor、加 BSP 功能。
- 要**整套 TROS 从源码交叉编译**(而非 `apt install tros-*`)。
否则不要碰:普通开发烧官方镜像 + `apt` 装 TROS 即可。

## A. OS 镜像构建(BSP 层,`repo` + `manifest` + `*-rdk-gen`)

### A.1 主机环境(以 X3 / rdk-gen 为例,X5/S100 同构)

- 推荐 Ubuntu 22.04(与目标板系统版本一致,减少依赖差异)。
- 安装构建依赖(含 `repo`、`qemu-user-static`、`debootstrap` 等):

```bash
sudo apt-get install -y build-essential make cmake libpcre3 libpcre3-dev bc bison \
  flex python3-numpy mtd-utils zlib1g-dev debootstrap libdata-hexdumper-perl \
  libncurses5-dev zip qemu-user-static curl repo git liblz4-tool apt-cacher-ng \
  libssl-dev checkpolicy autoconf android-sdk-libsparse-utils mtools parted \
  dosfstools udev rsync
# X5/S100 还需 device-tree-compiler u-boot-tools ccache 等(见对应 *-rdk-gen README)
```

- 交叉编译工具链(官方文件服务器):

```bash
curl -fO http://archive.d-robotics.cc/toolchain/gcc-arm-11.2-2022.02-x86_64-aarch64-none-linux-gnu.tar.xz
sudo tar -xvf gcc-arm-11.2-2022.02-x86_64-aarch64-none-linux-gnu.tar.xz -C /opt
```

### A.2 用 `repo` 拉全量源码(manifest 是清单)

```bash
# (可选)切国内镜像加速 repo 自身
export REPO_URL='https://mirrors.tuna.tsinghua.edu.cn/git/git-repo/'
# 初始化仓库清单:main=与最新发布镜像对应,develop=开发分支(新特性多、稳定性略低)
repo init -u git@github.com:D-Robotics/manifest.git -b main
repo sync
```

`manifest` 仓的清单把内核、bootloader、`hobot-*`(连字符)等所有 BSP 源码拉到 `source/` 下。
**板型对应**:X3 用 `manifest`;X5 用 `x5-rdk-gen` + `x5-manifest`;S100 用 `s100-rdk-gen`;J5 用 `j5-rdk-gen` + `j5-manifest`(同一套 `repo init/sync` 流程,换对应 manifest)。

### A.3 编译镜像

```bash
cd rdk-gen
sudo ./pack_image.sh      # 成功后在 deploy/ 生成 *.img
```

### A.4 rdk-gen 关键脚本与目录

| 脚本/目录 | 作用 |
| --- | --- |
| `pack_image.sh` | 构建镜像总入口 |
| `download_samplefs.sh` | 下载预制基础 Ubuntu 文件系统 |
| `download_deb_pkgs.sh` | 下载需预装的 D-Robotics deb(内核、多媒体库、示例、tros.bot 等) |
| `hobot_customize_rootfs.sh` | 定制化修改 rootfs |
| `source_sync.sh` | 下载 bootloader/uboot/kernel/示例 等源码 |
| `mk_kernel.sh` | 编译内核、设备树、驱动模块 |
| `mk_debs.sh` | 生成 deb 软件包 |
| `make_ubuntu_samplefs.sh` | 制作 Ubuntu samplefs(可改本脚本定制) |
| `config/` | 放入镜像 `/hobot/config`(vfat 分区,SD 卡启动可在 Windows 下直接改) |

`pack_image.sh` 过程:下载 samplefs + 预装 deb → 解压 samplefs 并 `hobot_customize_rootfs.sh` 定制 → 装 deb 进 rootfs → 生成镜像。
`source/` 目录含 `bootloader`/`hobot-boot`/`hobot-bpu-drivers`/… 即家族 1 的连字符 BSP 仓。

## B. TROS 从源码构建(应用层,`vcstool` + `robot_dev_config`)

`robot_dev_config` 是 [TogetheROS.Bot](https://developer.d-robotics.cc/en/rdk_doc/Quick_start) 的**编译入口**(兼容 ROS2),用 `vcstool` 按 `ros2.repos` 拉所有 `hobot_*`(下划线)ROS 包 + ROS2 核心移植仓。

```bash
# 基于 Ubuntu 22.04 docker 交叉编译(官方示例,依赖 ROS humble;镜像 pc_tros_ubuntu22.04)
mkdir -p /mnt/data/test/cc_ws/tros_ws/src
cd /mnt/data/test/cc_ws/tros_ws
git clone https://github.com/D-Robotics/robot_dev_config.git -b develop
sudo pip install -U vcstool
vcs-import src < ./robot_dev_config/ros2.repos   # 拉取全部 ROS 包源码
# 再按 build.sh / all_build.sh(x3)/ rdkultra_build.sh / x86_build.sh / minimal_build.sh 编译
```

`robot_dev_config` 关键脚本:

| 脚本 | 用途 |
| --- | --- |
| `build.sh` | 编译脚本 |
| `all_build.sh` / `rdkultra_build.sh` / `x86_build.sh` | X3 / RDK Ultra / x86 完整编译配置 |
| `minimal_build.sh` / `minimal_deploy.sh` | 最小化编译 / 裁剪部署 |
| `bloom_script/` | 应用打 deb(README 历史提到 `build_deb.sh`,但当前仓库 deb 打包走 `bloom_script/`,以仓库实际为准) |
| `aarch64_toolchainfile.cmake` | 交叉编译工具链文件 |

## 两套构建系统对比(别混用)

| | OS 镜像(A) | TROS 应用(B) |
| --- | --- | --- |
| 多仓工具 | Google `repo` | `vcstool` |
| 清单 | `manifest`(XML) | `robot_dev_config/ros2.repos` |
| 入口 | `*-rdk-gen` | `robot_dev_config` |
| 拉取对象 | kernel/uboot/bootloader/`hobot-*`(连字符) | `hobot_*`(下划线)+ rcl/rclcpp/rmw… |
| 产物 | 可烧录 `*.img` | `/opt/tros` 工作区 + deb |
| 板型 | 强相关(前缀切分) | 跨板型(靠 BSP 提供能力) |

## 相关文档

- [X3 镜像构建 (rdk-gen)](https://github.com/D-Robotics/rdk-gen) · [X5 (x5-rdk-gen)](https://github.com/D-Robotics/x5-rdk-gen)
- [TROS 编译入口 (robot_dev_config)](https://github.com/D-Robotics/robot_dev_config)
- [系统镜像烧录(官方,非源码构建)](https://developer.d-robotics.cc/rdk_doc/Quick_start/install_os/rdk_x5)
- [系统镜像下载清单](https://github.com/D-Robotics/system_download)
