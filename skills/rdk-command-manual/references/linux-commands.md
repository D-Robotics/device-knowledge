# Linux 常用命令附录索引(9.2 Linux命令用法)

> 来源:`D-Robotics/rdk_doc` `docs/09_Appendix/linux-command-manual/`(分支 main,`_category_.json` label = `9.2 Linux命令用法`)。这些是通用 Linux 命令的用法说明,本 skill **只做索引指回官方**,不全文搬运;需要标准用法时直接给官方链接或按标准 man 解释,不要臆造 RDK 特有差异。

文档站 URL 规律:`https://developer.d-robotics.cc/rdk_doc/Appendix/linux-command-manual/cmd_<name>`

| 命令 | 用途分类 | 官方文件 | 文档站链接 |
| --- | --- | --- | --- |
| `apt` | 包管理 | `cmd_apt.md` | `.../Appendix/linux-command-manual/cmd_apt` |
| `dpkg` | deb 包管理 | `cmd_dpkg.md` | `.../cmd_dpkg` |
| `dpkg-deb` | deb 包解析 | `cmd_dpkg-deb.md` | `.../cmd_dpkg-deb` |
| `dmesg` | 内核日志 | `cmd_dmesg.md` | `.../cmd_dmesg` |
| `find` | 文件查找 | `cmd_find.md` | `.../cmd_find` |
| `grep` | 文本搜索 | `cmd_grep.md` | `.../cmd_grep` |
| `ps` | 进程查看 | `cmd_ps.md` | `.../cmd_ps` |
| `top` | 实时进程/负载 | `cmd_top.md` | `.../cmd_top` |
| `nohup` | 后台不挂断运行 | `cmd_nohup.md` | `.../cmd_nohup` |
| `mount` | 挂载文件系统 | `cmd_mount.md` | `.../cmd_mount` |
| `tar` | 归档/解包 | `cmd_tar.md` | `.../cmd_tar` |
| `zip` | 压缩 | `cmd_zip.md` | `.../cmd_zip` |
| `rsync` | 增量同步 | `cmd_rsync.md` | `.../cmd_rsync` |
| `scp` | 远程拷贝 | `cmd_scp.md` | `.../cmd_scp` |
| `ssh` | 远程登录 | `cmd_ssh.md` | `.../cmd_ssh` |
| `ip` | 网络配置(新) | `cmd_ip.md` | `.../cmd_ip` |
| `ifconfig` | 网络配置(旧) | `cmd_ifconfig.md` | `.../cmd_ifconfig` |
| `route` | 路由表 | `cmd_route.md` | `.../cmd_route` |
| `netstat` | 网络连接/端口 | `cmd_netstat.md` | `.../cmd_netstat` |

说明:
- 共 19 条,均为标准 Linux 命令,RDK 文档收录是为方便初学者;遇到 RDK 板上具体网络/包管理问题(如 APT 公钥失效、TROS 包找不到),按现象排障应走 `rdk-board-knowledge`,本附录仅供命令语法参考。
- S 系列(`rdk_s_doc` / `rdk_doc docs_s/`)的 `09_Appendix/linux-command-manual/` 目录存在但命令文件与 X 系列重合,无需另列。
