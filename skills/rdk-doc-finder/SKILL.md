---
name: rdk-doc-finder
description: 当开发者问"X 在官方文档哪里 / 哪本手册讲 Y / 哪一章 / 去哪查 Z / 给个权威出处链接"时使用,把任意 RDK 问题精准指到官方文档站的章节 + URL。本 skill 是"官方文档站/手册导航"(developer.d-robotics.cc 的 rdk_x_doc / rdk_s_doc / tros_doc / model_zoo_doc / rdk_studio_doc / accessories_doc 六个站)。与兄弟 skill 划清:定位 GitHub 仓库/源码走 rdk-source-map;买哪块板/能不能跑/选型口径走 rdk-ecosystem;报错诊断走 rdk-board-knowledge;硬件引脚事实走 rdk-hardware。本 skill 只回答"该去哪个手册的哪一章看",不替代上述内容性 skill。
---

# RDK 官方文档定位器

> 来源:实地核对 D-Robotics 六个 Docusaurus 文档仓(rdk_x_doc / rdk_s_doc / tros_doc / model_zoo_doc / rdk_studio_doc / accessories_doc,默认分支均 `main`)的目录树与 `docusaurus.config.js`,并对代表性 URL 在 developer.d-robotics.cc 实测 200/404 验证;逐条保留出处。文档随版本演进,以站点实际页面为准。

回答"这个问题官方文档在哪讲 / 该看哪本手册哪一章 / 给我权威链接"。**完整主题→URL 速查表见 [doc-map](references/doc-map.md)**,本页只讲选站规则与 URL 推导法。

## 第一步:按板型/主题选对站(六站分工)

| 站(baseUrl) | 管什么 | 覆盖板 |
| --- | --- | --- |
| **rdk_x_doc** | X 系列主手册:上手/系统配置/40pin/视觉/音频/多媒体/工具链/Linux 开发/FAQ/附录命令 | X3 · X3 Module · X5 · X5 Module · Ultra |
| **rdk_s_doc** | S 系列主手册:同上 + **MCU 开发 / hbmem / PCIe / OTA / VDSP**(S 独有) | S100 · S100P · S600 |
| **tros_doc** | **TROS/ROS2 机器人开发**:安装/quick demo/功能包(boxs)/应用(apps)/性能调优 | 跨板(X/S 通用) |
| **model_zoo_doc** | **Model Zoo 算法清单与使用说明**(预编译模型、infer API、各板 guide) | X3 · X5 · S100 · S600 |
| **rdk_studio_doc** | **RDK Studio 桌面客户端**:安装登录/烧录/连设备/AI 对话/OpenClaw/Skill/CLI/FAQ | Studio 软件本身 |
| **accessories_doc** | **官方配件**:双目相机 GS130W/GS130WI、IMU 模组 | 配件硬件 |

选站心法:
- 问"**怎么用某 ROS2 节点 / TROS 怎么装 / Nav2 / SLAM**"→ **tros_doc**(即使是 X/S 板)。
- 问"**有没有现成的 YOLO/分类/分割模型、精度多少**"→ **model_zoo_doc**。
- 问"**RDK Studio 客户端怎么操作 / OpenClaw / 烧录界面 / 客户端报错**"→ **rdk_studio_doc**。
- 问"**S100 的 MCU / R52 / hbmem / .hbm / PCIe / EtherCAT**"→ **rdk_s_doc**(X 站没有 MCU 章节)。
- 其余板上系统/外设/工具链类问题:X 板 → **rdk_x_doc**,S 板 → **rdk_s_doc**。
- 板型不明时先问一句"你是哪块板(X3/X5/Ultra/S100/S600)",别默认塞 X5。

## 第二步:URL 推导规则(实测验证)

六站都是 Docusaurus,`url: https://developer.d-robotics.cc`,`baseUrl: /<repo>/`,`routeBasePath: /`。由 GitHub 源文件路径反推站点 URL:

> **规则**:取仓内 `docs/<path>.md`,**逐段去掉开头的 `NN_` / `NN-` 数字序号前缀**,去掉 `.md`,大小写原样保留,拼到 `https://developer.d-robotics.cc/<repo>/<去前缀路径>`。

实测样例(均返 200):
- `rdk_x_doc` 的 `docs/03_Basic_Application/01_40pin_user_sample/gpio.md`
  → `https://developer.d-robotics.cc/rdk_x_doc/Basic_Application/40pin_user_sample/gpio`
- `tros_doc` 的 `docs/03_boxs/detection/yolo.md`
  → `https://developer.d-robotics.cc/tros_doc/boxs/detection/yolo`
- `rdk_s_doc` 的 `docs/07_Advanced_development/05_mcu_development/08_mcu_ipc.md`
  → `https://developer.d-robotics.cc/rdk_s_doc/Advanced_development/mcu_development/mcu_ipc`

**两个例外,推导前先查源文件 frontmatter**:
1. 文件头有 `slug:` 时以 slug 为准(可保留数字前缀、甚至改名)。已知 `rdk_s_doc` 的 S100/S600 **硬件介绍**页用自定义 slug,如开发者套件页实测是
   `https://developer.d-robotics.cc/rdk_s_doc/01_Quick_start/01_hardware_introduction/01_rdk_s100/01_rdk_s100_kit`(保留了序号)。
2. 拿不准时给 **GitHub 源路径 + 站点根**,不要臆造 URL。查源文件:
   ```bash
   gh api "repos/D-Robotics/<repo>/contents/<docs/path.md>?ref=main" --jq '.content' | base64 -d | head -8
   ```

## 第三步:旧链接迁移提醒(必读)

- 旧的合并仓 **`rdk_doc`**(`developer.d-robotics.cc/rdk_doc/...`,含 `docs/`=X、`docs_s/`=S)页面仍可访问,但顶部已挂"**本手册已迁移至全新资料中心**"(实测注明 2026-06-10 起)。
- **新出处一律用拆分后的 `rdk_x_doc` / `rdk_s_doc` / `tros_doc` 等**;只有当新站确无对应页时才回退旧 `rdk_doc` 链接,并提示用户它是归档版。
- `rdk_x_doc` 与 `rdk_s_doc` 是 `rdk_doc` 的 X/S 拆分迁移目标;`tros_doc`(机器人开发)是从原 `rdk_doc` 第 5 章独立出来的 TROS 专站。

## 第四步:查不到就核对,别编

- 不确定某页是否存在/URL 是否正确时,用 `web_fetch` 实测该 URL,或先列源仓子树定位文件:
  ```bash
  gh api "repos/D-Robotics/<repo>/git/trees/main?recursive=1" --jq '.tree[].path' | grep -iE '关键词'
  ```
- **完整分类索引(快速上手/系统配置/40pin/视觉/音频/多媒体/算法 ModelZoo/机器人 TROS/工具链/Linux 与 MCU 高级开发/FAQ/附录命令手册/发布说明/RDK Studio/配件)见 [doc-map](references/doc-map.md)**,每条标了覆盖哪些板与归属哪个站。
