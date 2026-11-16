# system-engineering

> 给 AI 编程 Agent 的前置规程：**先把系统说清楚，再动代码。**

[English](README.md) · [中文技能](SKILL.md) · [English skill](SKILL.en.md)

---

## 它解决什么问题

Agent 的默认路径是「遇到问题 → 找工具 → 改文件」。这个循环在局部最优，在全局很贵。失败模式高度可预测：

- 新功能单独跑得通，但从未注册到任何地方——系统发现不了它，也复用不了。
- 在已有模块旁边又新建了一个，而旧模块本来就覆盖了 70%。
- 同一份数据开始在两个地方各自维护。
- 需求一段一段拆，第 2 步做出的决定让第 6 步直接作废。
- 从未定义「什么算完成」，于是没人能判断到底做完没有。

这些都不是编码错误，是**协作错误**。防住的成本远低于返工。

## 它插入的五道闸门

| 阶段 | 闸门 |
|---|---|
| **0. 项目 Wiki** | `PROJECT_WIKI.md` 用文字描述架构与运行逻辑。新项目先写；老项目没有就逆向补写。每次需求变更，**用户审阅通过后**才更新。 |
| **1. 任务测绘** | 定义终态、列子任务、梳理依赖、盘点能力、定位接入面——在调用任何工具之前，3-5 句话说完。 |
| **2. 全局决策** | 路由（谁做哪块）、衔接契约（跨接缝传什么格式）、风险闸门（哪些事必须先问人）。 |
| **3. 子系统配合** | 接入前置、高内聚、低耦合、上下文最小化、单层委派、合并前验证。 |
| **4. 回归检查** | 每条验收标准对应到证据；找断裂的接缝；拦住未验证的全局变更。 |

Wiki 是承重结构。当 Agent 和用户对「系统是什么」产生分歧时，它是唯一双方都能指着说话的产物。它刻意**用文字而不是图**——图可以看起来很完整却什么都没说，而一段点名了文件的话是可以核对的。

## 安装

最省事的方式：粘一句话，让 Agent 自己装。下面是手动方式。

### 让 Agent 自己装（不用终端）

把这句粘进任何能访问网络的 Agent：

```
把 https://github.com/jalin-zhu/system-engineering-skill 这个技能安装到你的技能目录。
严格按 https://raw.githubusercontent.com/jalin-zhu/system-engineering-skill/main/INSTALL.md 执行。
装中文版。完成后告诉我安装路径和版本。
```

Agent 会读 [INSTALL.md](INSTALL.md)，识别自己对应的技能目录，备份已有安装，拷入文件，自检后回报路径。Qoder、Claude Code 以及任何按目录加载技能的 Agent 都适用。如果它访问不了网络，规程要求它停下报告，而不是凭记忆编造文件内容。

### npx（跨平台）

```bash
npx system-engineering-skill install                 # 装到 Qoder，中文
npx system-engineering-skill install --target claude # 装到 Claude Code
npx system-engineering-skill install --target all --lang en
npx system-engineering-skill status                  # 查看装在哪、什么版本
npx system-engineering-skill uninstall --target qoder
```

### macOS / Linux

```bash
git clone https://github.com/jalin-zhu/system-engineering-skill.git
cd system-engineering-skill
./scripts/install.sh --target qoder          # 或：claude | project | all
./scripts/install.sh --target claude --lang en
```

### Windows（PowerShell）

```powershell
git clone https://github.com/jalin-zhu/system-engineering-skill.git
cd system-engineering-skill
.\scripts\install.ps1 -Target qoder
.\scripts\install.ps1 -Target claude -Lang en
```

### 手动

把本目录整个复制到 Agent 读取的技能目录：

| 目标 | 路径 |
|---|---|
| Qoder | `~/.qoder/skills/system-engineering/` |
| Claude Code | `~/.claude/skills/system-engineering/` |
| 项目内 | `<repo>/.qoder/skills/system-engineering/` |

Agent 必须找到的只有 `SKILL.md`；`reference.md` 和 `project-wiki.md` 按需加载。

### 参数

| 参数 | 取值 | 默认 |
|---|---|---|
| `--target` / `-Target` | `qoder`、`claude`、`project`、`all` | `qoder` |
| `--lang` / `-Lang` | `zh`、`en` | `zh` |
| `--dir` / `-Dir` | `project` 目标的安装根目录 | `./.qoder/skills` |
| `--force` / `-Force` | 覆盖且不留备份 | 关闭 |

语言处理：`--lang zh` 时，中文 `SKILL.md` 装成 `SKILL.md`，英文版同时以 `SKILL.en.md` 随包保留（反之亦然）。Agent 读到的永远是你选定语言的 `SKILL.md`。

已有安装不会被直接删除，而是重命名为 `system-engineering.bak-<时间戳>`。

## 验证是否生效

新开一个会话，给一个多步骤任务，例如「给订单页加 CSV 导出」。技能正常加载时会先输出测绘再碰文件：

```
终态：点击导出拿到与列表列一致的 .csv
子任务：T1 导出接口 / T2 下载处理 / T3 权限
依赖：T1 → T2；T3 并行但必须先于发布落地
能力：T1/T2 主代理；无缺口
接入：落点 = 订单服务；数据 = orders 表（只读）；注册 = 既有路由
```

随后它应当展示 `PROJECT_WIKI.md` 的变更并请求确认，**之后**才动代码。如果它直接改文件，说明技能没加载。

## 仓库结构

| 路径 | 用途 |
|---|---|
| `SKILL.md` | 中文技能正文（默认） |
| `SKILL.en.md` | 英文技能正文 |
| `reference.md` | 测绘单模板与案例（跨端功能、重构、新增模块、新项目） |
| `project-wiki.md` | `PROJECT_WIKI.md` 模板、写作标准、逆向补写清单、审阅格式 |
| `INSTALL.md` | 供 Agent 执行的安装规程（聊天安装背后的那份文件） |
| `bin/cli.mjs` | `npx` 安装器（无依赖） |
| `scripts/install.sh` | POSIX 安装脚本 |
| `scripts/install.ps1` | PowerShell 安装脚本 |

## 语言

操作核心完整双语：`SKILL.md`（中文）与 `SKILL.en.md`（英文）保持同步、可互相替换，由安装器决定哪一份成为 `SKILL.md`。

`reference.md` 与 `project-wiki.md` 目前以中文为主——它们是填空式模板，占位符本身承载语义。欢迎提交翻译 PR。

## 兼容性

任何读取 `SKILL.md` 目录的 Agent 都能用：Qoder、Claude Code 以及同类技能加载机制。技能本身是纯 Markdown——无运行时、无依赖、加载时不执行任何脚本。

它与其他技能是叠加关系：先建 Wiki 与测绘，再把具体子任务交给领域技能（前端、PDF、数据库、部署等）。

## 设计取舍

**为什么用 Wiki 而不是图。** 图对人信号强，对 Agent 精度低：没有文件名、没有失败路径、没有归属。文字写错了是能被指出来的。图允许存在，但从不是必需项。

**为什么要有审阅闸门。** Agent 天生偏向行动。写「请考虑架构」会被忽略，写「把 diff 拿出来，等我确认」不会。闸门是执行机制，原则只是它的理由。

**为什么委派只允许一层。** 嵌套子代理的成本按组合增长，而且每深一层就丢失一次全局约束。一层 + 四段式交接，编排者才控制得住。

**为什么鼓励删除。** 不加约束的话，每个需求都在加模块。把「删除一个模块」明确列为合法的拆解结论，系统才不会越滚越肿。

## 许可

MIT，见 [LICENSE](LICENSE)。
