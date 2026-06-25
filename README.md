# RDK Device Knowledge Skills · RDK 设备知识技能

Source-backed knowledge for D-Robotics RDK boards (and Jetson / Raspberry Pi / Rockchip), written in the official [Claude skill format](https://github.com/anthropics/skills). Any skill-aware host (Claude Code, Moss, RDK Studio) scans `skills/**` directly.

面向 D-Robotics RDK(及 Jetson / 树莓派 / Rockchip)的 source-backed 知识,采用 [Claude 官方 skill 格式](https://github.com/anthropics/skills)。任意支持 skill 的宿主(Claude Code、Moss、RDK Studio)可直接扫描 `skills/**` 加载。

## Skills · 技能清单

| Skill | What it covers · 用途 |
|-------|------------------------|
| [`rdk-ecosystem`](skills/rdk-ecosystem/) | Board selection & cross-platform comparison · 选型 / 跨平台对比 / 能否跑某模型 |
| [`rdk-hardware`](skills/rdk-hardware/) | Per-board hardware facts (specs, 40PIN, CAN, power, IP) · 板型硬件事实(规格 / 40PIN / CAN / 供电 / IP) |
| [`rdk-board-knowledge`](skills/rdk-board-knowledge/) | Board ID, error diagnosis, FAQ, S-series flashing · 板型识别 / 报错诊断 / FAQ / S 系烧录 |
| [`rdk-system-config`](skills/rdk-system-config/) | System config (network, freq, thermal, autostart) · 系统配置(网络 / 调频 / 温控 / 自启) |
| [`rdk-device`](skills/rdk-device/) | Deploy your own model end-to-end + first boot + camera · 自训模型端到端部署 + 开箱 + 摄像头 |
| [`rdk-model-zoo`](skills/rdk-model-zoo/) | Ready-made precompiled BPU models · 取现成预编译 BPU 模型 |
| [`rdk-ros`](skills/rdk-ros/) | TROS/ROS2 env, nodes, perception · TROS/ROS2 环境 / 节点 / 感知 |
| [`rdk-multimedia`](skills/rdk-multimedia/) | Hardware codec & camera pipeline · 硬件编解码与相机流水线 |
| [`rdk-peripheral-cookbook`](skills/rdk-peripheral-cookbook/) | Drive peripherals (GPIO/I2C/SPI/CAN/audio) · 驱动外设(GPIO/I2C/SPI/CAN/音频) |
| [`rdk-accessories`](skills/rdk-accessories/) | Official accessories (cameras, IMU, expansion boards) · 官方配件(相机 / IMU / 扩展板) |
| [`rdk-llm-deployment`](skills/rdk-llm-deployment/) | On-board LLM/VLM chat + voice stack · 端侧 LLM/VLM 对话 + 语音栈 |
| [`rdk-embodied-lerobot`](skills/rdk-embodied-lerobot/) | Embodied policy deploy (ACT / VLA / Pi0) · 具身策略部署(ACT / VLA / Pi0) |
| [`rdk-board-delegate`](skills/rdk-board-delegate/) | S-series heterogeneous dev (MCU/hbmem/EtherCAT) + OpenClaw delegate · S 系异构开发 + OpenClaw 委派 |
| [`rdk-command-manual`](skills/rdk-command-manual/) | RDK command syntax / flags / boards · RDK 命令语法 / 选项 / 适用板型 |
| [`rdk-doc-finder`](skills/rdk-doc-finder/) | Locate the official doc-site chapter & URL · 定位官方文档站章节与 URL |
| [`rdk-source-map`](skills/rdk-source-map/) | Navigate the D-Robotics GitHub org repos · 在 D-Robotics GitHub 组织里定位仓库 |
| [`jetson-knowledge`](skills/jetson-knowledge/) | NVIDIA Jetson ecosystem & toolchain · NVIDIA Jetson 生态与工具链 |
| [`rpi-knowledge`](skills/rpi-knowledge/) | Raspberry Pi ecosystem & GPIO · 树莓派生态与 GPIO |
| [`rk-knowledge`](skills/rk-knowledge/) | Rockchip RK3588 NPU & RKNN · Rockchip RK3588 NPU 与 RKNN |
| [`host-software-dev`](skills/host-software-dev/) | RDK Studio desktop client dev · RDK Studio 桌面客户端开发 |

## Vendored official skills · 内置官方 skill

General-purpose tooling skills copied unmodified from [anthropics/skills](https://github.com/anthropics/skills) (Apache-2.0), kept here for maintainers. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

从 [anthropics/skills](https://github.com/anthropics/skills) 原样收录的通用工具 skill(Apache-2.0),供维护者使用,详见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

| Skill | What it's for · 用途 |
|-------|----------------------|
| [`skill-creator`](skills/skill-creator/) | Create / improve / measure skills · 创建 / 改进 / 评测 skill(维护本仓用) |
| [`mcp-builder`](skills/mcp-builder/) | Build MCP servers · 构建 MCP server(把知识做成 MCP 服务时用) |

## Add a skill · 新增 skill

A skill is one folder under `skills/<name>/`. Follow the shape of [`rdk-device`](skills/rdk-device/) as the reference template.

一个 skill 就是 `skills/<name>/` 下的一个文件夹。以 [`rdk-device`](skills/rdk-device/) 为参考模板。

```text
skills/<name>/
├── SKILL.md           # required · 必需
├── references/*.md     # detailed tables/notes · 详细查表(可选)
├── evals/evals.json    # test prompts + assertions · 测试集(可选)
├── scripts/            # deterministic helpers · 确定性脚本(可选)
└── assets/             # templates/config · 模板/配置(可选)
```

**EN**
1. **`SKILL.md` frontmatter** — `name` (must equal the folder name) and a `description` that states *what it does + when to use* (a bit pushy to avoid under-triggering), includes Chinese `触发词` keywords, and routes to sibling skills.
2. **Body** — write in English, imperative and scannable: a decision table where useful, numbered workflows, 3–4 worked examples (real question → how to answer), a do/don't pitfalls table, and a reference map.
3. **Bundled resources** — put long detail in `references/*.md` (English; add a table of contents if a file exceeds 300 lines). Add `evals/evals.json`. Add `scripts/` or `assets/` only when genuinely useful.
4. **Stay source-backed** — cite official docs (D-Robotics / NVIDIA / Raspberry Pi / Rockchip); don't invent facts.
5. **Validate** — run `node scripts/validate-skills.mjs` (must pass: `name` == folder, every `references/` link resolves).

**中文**
1. **`SKILL.md` frontmatter** —— `name`(必须等于文件夹名)+ `description`:写清*做什么 + 何时用*(稍微"主动"些以免漏触发),带中文 `触发词` 关键词,并路由到相邻 skill。
2. **正文** —— 用英文写,imperative、可扫读:需要时给决策表、编号 workflow、3–4 个 worked example(真实问题 → 怎么答)、do/don't 速查表、reference map。
3. **附带资源** —— 长内容放 `references/*.md`(英文;超 300 行加目录)。加 `evals/evals.json`。`scripts/`、`assets/` 仅在确有用处时加。
4. **保持 source-backed** —— 引用官方文档(D-Robotics / NVIDIA / 树莓派 / Rockchip),不臆造事实。
5. **校验** —— 运行 `node scripts/validate-skills.mjs`(必须通过:`name` == 文件夹名、每个 `references/` 链接都存在)。

## License

[MIT](LICENSE)
