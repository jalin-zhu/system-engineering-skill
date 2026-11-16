# Install with an agent

Paste one line into your agent's chat. It reads this file and installs the skill into its own skills directory.

## The prompt

**English**

```
Install the skill at https://github.com/jalin-zhu/system-engineering-skill into your skills directory.
Follow https://raw.githubusercontent.com/jalin-zhu/system-engineering-skill/main/INSTALL.md exactly.
Install the Chinese version unless I asked for English. Report the path and version when done.
```

**中文**

```
把 https://github.com/jalin-zhu/system-engineering-skill 这个技能安装到你的技能目录。
严格按 https://raw.githubusercontent.com/jalin-zhu/system-engineering-skill/main/INSTALL.md 执行。
装中文版。完成后告诉我安装路径和版本。
```

If your agent cannot fetch URLs, give it the repository URL instead and tell it to read `INSTALL.md` at the root.

---

# For the agent

## Goal

Install this skill into the skills directory of the agent you are running in. Touch nothing outside that directory.

## Steps

1. **Identify the skills root.** Match the agent you are running in:

   | Agent | Skills root |
   |---|---|
   | Qoder | `~/.qoder/skills/` |
   | Claude Code | `~/.claude/skills/` |
   | Project-local (either) | `<repo>/.qoder/skills/` or `<repo>/.claude/skills/` |

   If you cannot tell which agent you are, ask the user once. Do not guess a path and do not install into several roots.

2. **Check for an existing install** at `<root>/system-engineering`. If it exists, rename it to `system-engineering.bak-<yyyyMMdd-HHmmss>`. Never delete it.

3. **Obtain the files**, in this order of preference:
   - **a.** `npx -y system-engineering-skill install --target <qoder|claude> --lang <zh|en>` — use when Node.js ≥ 18 is available and the registry is reachable.
   - **b.** `git clone --depth 1 https://github.com/jalin-zhu/system-engineering-skill.git <temp>`, then copy `SKILL.md`, `SKILL.en.md`, `reference.md`, `project-wiki.md`, `README.md`, `README.zh-CN.md`, `INSTALL.md`, `LICENSE` into `<root>/system-engineering/`.
   - **c.** If both fail because of network restrictions, **stop and report the failure**. Do not reconstruct file contents from memory — an invented skill file is worse than no skill.

4. **Apply the language.** `zh`: keep `SKILL.md` as is. `en`: copy `SKILL.en.md` over `SKILL.md`, and preserve the Chinese text as `SKILL.zh-CN.md`.

5. **Write `<root>/system-engineering/.installed.json`**:

   ```json
   { "name": "system-engineering", "version": "<from package.json>", "lang": "zh|en", "installedAt": "<ISO-8601 UTC>" }
   ```

6. **Verify before reporting**:
   - `SKILL.md` exists and its YAML frontmatter contains both `name` and `description`
   - `reference.md` and `project-wiki.md` are present
   - every file listed in `SKILL.md` as a link actually exists
   - nothing was written outside the target directory

7. **Report** the target, absolute install path, version, language, any backup path, and this line: *restart the session so the skill list refreshes*.

## Do not

- Do not modify the user's project files, git history, or global agent config.
- Do not delete or overwrite an existing install without keeping the backup.
- Do not add steps that are not in this file — the procedure is deliberately minimal.
- Do not claim success without running the step 6 checks.

## Confirm it loaded

After restarting, ask the agent for a multi-step change, for example *"add CSV export to the orders page"*. A loaded skill answers with a short survey before touching files:

```
Done: user clicks Export, gets a .csv whose columns match the table
Subtasks: T1 export endpoint / T2 download handling / T3 permissions
Dependencies: T1 → T2; T3 parallel
Capabilities: T1/T2 main agent; no gap
Integration: anchor = orders service; data = orders table; registration = existing router
```

Then it shows the `PROJECT_WIKI.md` change and asks for approval **before** editing code. If it jumps straight to files, the skill did not load.

---

# 给 Agent 的中文版

## 目标

把这个技能安装到你当前运行环境对应的技能目录，不碰目录之外的任何文件。

## 步骤

1. **确定技能根目录**：Qoder 用 `~/.qoder/skills/`，Claude Code 用 `~/.claude/skills/`，项目内安装用 `<repo>/.qoder/skills/`。判断不出自己属于哪个 Agent 时，问用户一次，不要猜，也不要同时装到多处。
2. **检查是否已安装**：`<root>/system-engineering` 若已存在，重命名为 `system-engineering.bak-<yyyyMMdd-HHmmss>`，**不要删除**。
3. **获取文件**，按优先级：
   - a. `npx -y system-engineering-skill install --target <qoder|claude> --lang <zh|en>`
   - b. `git clone --depth 1 https://github.com/jalin-zhu/system-engineering-skill.git <临时目录>`，再复制 `SKILL.md`、`SKILL.en.md`、`reference.md`、`project-wiki.md`、`README.md`、`README.zh-CN.md`、`INSTALL.md`、`LICENSE` 到 `<root>/system-engineering/`
   - c. 两种方式都因网络失败时：**停下并报告**。禁止凭记忆编造文件内容——一个编造的技能文件比没有更糟。
4. **处理语言**：`zh` 保持 `SKILL.md` 原样；`en` 把 `SKILL.en.md` 复制为 `SKILL.md`，中文原文保留为 `SKILL.zh-CN.md`。
5. **写入 `.installed.json`**，字段同上。
6. **报告前必须验证**：`SKILL.md` 存在且 frontmatter 含 `name`、`description`；`reference.md`、`project-wiki.md` 存在；`SKILL.md` 中引用的文件真实存在；没有写到目标目录之外。
7. **汇报**：目标、绝对路径、版本、语言、备份路径，并附一句「重启会话以刷新技能列表」。

## 禁止

- 不要改用户的项目文件、git 历史或全局 Agent 配置
- 不要在不保留备份的情况下删除或覆盖已有安装
- 不要执行本文件之外的步骤
- 不要跳过第 6 步验证就宣称成功
