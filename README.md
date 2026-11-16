# system-engineering

> A pre-flight protocol for AI coding agents: **agree on the system before writing code.**

[中文文档](README.zh-CN.md) · [English skill](SKILL.en.md) · [中文技能](SKILL.md)

---

## The problem

Coding agents default to `problem → find tool → edit files`. That loop is locally optimal and globally expensive. The failures are predictable:

- A feature is added that works in isolation but was never registered anywhere — nothing else can find or reuse it.
- A module is created next to an existing one that already did 70% of the job.
- The same data starts being maintained in two places.
- Requirements are decomposed one paragraph at a time, so a decision made at step 2 invalidates step 6.
- "Done" was never defined, so nobody can tell whether it is done.

None of these are coding errors. They are **coordination errors**, and they are cheaper to prevent than to fix.

## What this skill does

It inserts five gates before and around the coding:

| Phase | Gate |
|---|---|
| **0. Project wiki** | `PROJECT_WIKI.md` describes architecture and runtime logic in prose. New project → write it first. Existing project without one → reverse-engineer it. Every request updates it **only after the user approves the diff**. |
| **1. Topology survey** | Define done, list subtasks, map dependencies, inventory capabilities, locate the integration surface — in 3–5 sentences, before any tool call. |
| **2. Global decisions** | Routing (who does what), handoff contracts (what format crosses each seam), risk gates (what needs a human before it happens). |
| **3. Subsystem cooperation** | Integration prerequisite, high cohesion, low coupling, minimal context transfer, one-level delegation, verify-before-merge. |
| **4. Regression check** | Map every acceptance criterion to evidence; hunt broken seams; block unverified global changes. |

The wiki is the load-bearing part. It is the only artifact both the agent and the user can point at when they disagree about what the system is. It is deliberately **prose, not diagrams** — a diagram can look complete while saying nothing, a paragraph that names a file can be checked.

## Install

Fastest route: paste one line and let the agent install it. Manual routes follow.

### Ask your agent (no terminal)

Paste this into any agent that can fetch URLs:

```
Install the skill at https://github.com/jalin-zhu/system-engineering-skill into your skills directory.
Follow https://raw.githubusercontent.com/jalin-zhu/system-engineering-skill/main/INSTALL.md exactly.
Install the Chinese version unless I asked for English.
```

The agent reads [INSTALL.md](INSTALL.md), detects its own skills root, backs up any existing install, copies the files, verifies the result, and reports the path. Works in Qoder, Claude Code, and anything else that loads a skills directory. If it cannot reach the network, the procedure tells it to stop and report rather than reconstruct file contents from memory.

### npx (any OS)

```bash
npx system-engineering-skill install                 # Qoder, Chinese
npx system-engineering-skill install --target claude # Claude Code
npx system-engineering-skill install --target all --lang en
npx system-engineering-skill status                  # show what is installed where
npx system-engineering-skill uninstall --target qoder
```

### macOS / Linux

```bash
git clone https://github.com/jalin-zhu/system-engineering-skill.git
cd system-engineering-skill
./scripts/install.sh --target qoder          # or: claude | project | all
./scripts/install.sh --target claude --lang en
```

### Windows (PowerShell)

```powershell
git clone https://github.com/jalin-zhu/system-engineering-skill.git
cd system-engineering-skill
.\scripts\install.ps1 -Target qoder
.\scripts\install.ps1 -Target claude -Lang en
```

### Manual

Copy this directory into the skills folder your agent reads:

| Target | Path |
|---|---|
| Qoder | `~/.qoder/skills/system-engineering/` |
| Claude Code | `~/.claude/skills/system-engineering/` |
| Project-local | `<repo>/.qoder/skills/system-engineering/` |

The only file an agent must find is `SKILL.md`. `reference.md` and `project-wiki.md` are loaded on demand.

### Options

| Flag | Values | Default |
|---|---|---|
| `--target` / `-Target` | `qoder`, `claude`, `project`, `all` | `qoder` |
| `--lang` / `-Lang` | `zh`, `en` | `zh` |
| `--dir` / `-Dir` | destination root for `project` | `./.qoder/skills` |
| `--force` / `-Force` | overwrite without keeping a backup | off |

Language handling: with `--lang zh`, the Chinese `SKILL.md` is installed as `SKILL.md` and the English one ships alongside as `SKILL.en.md` (and vice versa). The agent always reads a `SKILL.md` in the language you chose.

Existing installations are moved to `system-engineering.bak-<timestamp>` rather than deleted.

## Verify it works

Start a fresh session and ask for something multi-step, e.g. *"add CSV export to the orders page"*. A correctly loaded skill responds with a short survey before touching files:

```
Done: user clicks Export, gets a .csv whose columns match the table
Subtasks: T1 export endpoint / T2 download handling / T3 permissions
Dependencies: T1 → T2; T3 parallel but must land before release
Capabilities: T1/T2 main agent; no gap
Integration: anchor = orders service; data = orders table (read-only); registration = existing router
```

Then it should show the `PROJECT_WIKI.md` change and ask for approval **before** editing code. If it jumps straight to files, the skill did not load.

## Repository layout

| Path | Purpose |
|---|---|
| `SKILL.md` | Chinese skill body (default) |
| `SKILL.en.md` | English skill body |
| `reference.md` | Survey template, worked examples (cross-end feature, refactor, module addition, new project) |
| `project-wiki.md` | `PROJECT_WIKI.md` template, writing rubric, reverse-engineering checklist, review format |
| `INSTALL.md` | Agent-executable install procedure (the file behind the chat prompt) |
| `bin/cli.mjs` | `npx` installer (no dependencies) |
| `scripts/install.sh` | POSIX installer |
| `scripts/install.ps1` | PowerShell installer |

## Languages

The operational core is fully bilingual: `SKILL.md` (Chinese) and `SKILL.en.md` (English) are kept in sync and are interchangeable — the installer decides which one becomes `SKILL.md`.

`reference.md` and `project-wiki.md` are currently Chinese-first, since they are fill-in-the-blank templates whose placeholders carry the meaning. Translation PRs are welcome.

## Compatibility

Anything that loads a `SKILL.md` directory works: Qoder, Claude Code, and similar skill-loading agents. The skill itself is plain markdown — no runtime, no dependencies, no scripts executed at load time.

It composes with other skills rather than replacing them: build the wiki and survey first, then hand the actual subtask to the domain skill (frontend, PDF, database, deployment, …).

## Design notes

**Why a wiki instead of diagrams.** A diagram is high-signal for humans and low-precision for agents: it has no filenames, no failure paths, no ownership. Prose can be wrong in a way you can check. Diagrams are allowed, never required.

**Why the review gate.** Agents are biased toward action. A rule that says "consider the architecture" is ignored; a gate that says "show the diff and wait" is not. The gate is the enforcement mechanism, the principle is just the justification.

**Why one-level delegation.** Nested subagents multiply cost combinatorially and lose the global constraint at every hop. One level, with a four-block handoff, keeps the orchestrator in control.

**Why deletion is encouraged.** Left unchecked, every request adds a module. Explicitly naming "delete a module" as a valid decomposition outcome is what keeps the system from accreting.

## License

MIT — see [LICENSE](LICENSE).
