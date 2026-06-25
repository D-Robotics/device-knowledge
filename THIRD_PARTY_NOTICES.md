# Third-Party Notices · 第三方声明

This repository vendors the following skills from
[anthropics/skills](https://github.com/anthropics/skills), unmodified, under the
**Apache License 2.0**. Each skill keeps its original `LICENSE.txt`.

本仓库从 [anthropics/skills](https://github.com/anthropics/skills) 原样收录了以下 skill,
依据 **Apache License 2.0** 使用,各自保留原 `LICENSE.txt`。

| Vendored skill | Path · 路径 | Upstream · 上游 | License · 许可 |
|----------------|------------|-----------------|----------------|
| `skill-creator` | `skills/skill-creator/` | anthropics/skills | Apache-2.0, © Anthropic, PBC |
| `mcp-builder` | `skills/mcp-builder/` | anthropics/skills | Apache-2.0, © Anthropic, PBC |

These are general-purpose tooling skills (authoring/measuring skills, and building MCP
servers), kept alongside the device-knowledge skills for maintainer convenience. They are
**not** modified here — update them by re-copying from upstream.

这两个是通用工具型 skill(创建/评测 skill、构建 MCP server),与设备知识 skill 放在一起方便维护者使用。
本仓**未作修改**,更新时直接从上游重新复制即可。

> Note: Anthropic's document skills (`pdf`, `docx`, `xlsx`, `pptx`) are **not** vendored —
> they are "all rights reserved" and may not be redistributed.
> 注:Anthropic 的文档类 skill(`pdf`/`docx`/`xlsx`/`pptx`)为 "all rights reserved",不可再分发,故未收录。
