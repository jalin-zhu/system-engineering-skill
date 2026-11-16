---
name: system-engineering
description: Provides a front-loaded global survey and orchestration protocol for multi-step, multi-tool, cross-domain work — before a project starts, write PROJECT_WIKI.md (a project wiki describing architecture and runtime logic in prose) as the shared medium between agent and user; for each new request, decompose into modules, propose an integration plan, and update the wiki only after user review, then implement; during execution, enforce subsystem cooperation (high cohesion, low coupling) and finish with a regression check. Use when a task spans multiple steps, tools, or subagents; when changing across modules or domains; for refactors, migrations, bulk edits, end-to-end delivery, adding features to an existing system, starting a new project, documenting system architecture or runtime logic; or when the user asks to "plan before acting", "give me the whole picture", "break this down", or "orchestrate".
---

# System Engineering

> English version. 中文版（默认）: [SKILL.md](SKILL.md)

## When this applies

**Load when any of the following is true:**

- **Starting a new project** (build the project wiki first, before anything else)
- The task needs ≥3 steps, or spans ≥2 modules / file groups
- Multiple tools, multiple subagents, or cross-domain skills are needed (for example "change the backend + change the frontend + write the migration")
- The work involves refactoring, migration, bulk edits, end-to-end delivery, or production changes
- Adding a feature, module, service, table, or config entry to an existing system
- The user asks for "the whole plan", "break this down", "orchestrate it", or "write project documentation"

**Do not load:** single-file tweaks, pure lookups, or anything one tool call can settle. The survey costs more than it saves there.

**Exception to Step 0:** if the task does not live in any project directory (throwaway script, one-off analysis), skip the wiki — but say in your reply why you skipped it.

## Hard rules

1. If the wiki is missing, build it first: an initial wiki for a new project, a reverse-engineered one for an existing project. **Creating PROJECT_WIKI.md is an expected deliverable of this skill and is not subject to "don't create files unless necessary."**
2. Do not write implementation code until the wiki change has been reviewed and approved by the user.
3. Do not call write-capable tools or start subagents before the topology survey is done.
4. The survey is a **decision gate, not a document**. Three to five sentences spoken inline is enough.
5. Subagents are one level deep. A delegated task may not delegate further.
6. Any subtask output must be verified by the orchestrator before it is merged into the whole.
7. Irreversible operations must stop and ask a human. A subagent may not cross that gate.
8. Before adding a module, understand the existing architecture and produce an integration-point list.

## Step 0: Project wiki (PROJECT_WIKI.md)

### 0.1 What it is

The **single structured medium** through which agent and user agree on what the project is. Every later decision about module boundaries and integration uses it as the baseline — never memory, never guesswork.

**Canonical location:** `PROJECT_WIKI.md` at the project root.

**Detection order** (stop at the first hit):

1. `<project root>/PROJECT_WIKI.md`
2. `<project root>/docs/PROJECT_WIKI.md`
3. `<project root>/.qoder/project-wiki.md`
4. Any markdown file whose first line is the marker `<!-- project-wiki -->`

**Four required sections (all of them, or it is not a wiki):**

| Section | What it must contain | Why |
|---|---|---|
| **Architecture overview** | Layers, each layer's responsibility, module boundaries, dependency direction; who calls whom, sync or async | Decides which layer a new module belongs to |
| **Runtime logic** | The main path step by step (entry → processing → persistence → response), state changes, key failure paths and fallbacks | Shows which path a change will break |
| **Module inventory** | Module / responsibility / input / output / dependencies / code location | Makes an "integration plan" land on real files |
| **Data and contracts** | Entities and tables, interface signatures and fields, event payloads, cache keys | Detects a second source of truth before it appears |

**Three supporting sections** (fill in or write "n/a"): configuration and dependencies; deployment and observability (logs/metrics/rollback); known constraints and past decisions.

**Writing standard:**

- Every statement must point at something concrete — file name, module name, function name, table name, config key. Checkable, not impressionistic.
- Runtime logic must be detailed enough to **reproduce one complete request by following it**, not "the system handles the request".
- No empty adjectives ("high-performance", "robust", "well-designed"). No bare directory listings without responsibilities and dependencies.
- **Diagrams are optional.** Mermaid is fine when a picture helps, but the prose must stand alone; a diagram may never replace text.

Full template and writing rubric: [project-wiki.md](project-wiki.md).

### 0.2 Three entry situations

| Situation | How to tell | Required action |
|---|---|---|
| **New project** | Empty directory, or the user describes building from scratch | **Write the wiki first** (initial architecture + main path); confirm with the user before the first line of implementation |
| **Existing project, no wiki** | Code exists but detection misses | **Reverse-engineer it**: read directory layout, entry points, routers/registries, schema, dependency manifests, logs → write the wiki → confirm → only then change code |
| **Existing project, wiki present** | Detection hits | Read it as this round's baseline; if it disagrees with the code, fix the wiki first and say what was wrong |

Do not reverse-engineer in a vacuum: show the user the module map you inferred, and label each line as **confirmed** (traces to a file/line), **inferred** (needs user confirmation), or **missing** (should exist but cannot be found).

If a legacy `PROJECT_MODEL.md` exists: read it, **merge it into `PROJECT_WIKI.md`**, add the prose that is missing, then delete the old file so there is only one source of truth.

### 0.3 The fixed flow for every new request (no skipping)

1. **Read both sources**: the user's request and `PROJECT_WIKI.md`. Decomposing without reading the wiki is guessing.
2. **Decompose into modules**: classify as *add / modify / delete / leave alone*, with a reason for each. Deletion is a legitimate outcome — if you can remove a module instead of adding one, do that.
3. **Integration plan**: for each added or modified module, answer — which existing module does it reuse, which layer does it sit in, where does its data come from and go to, who calls it, and through what mechanism is it registered (see 3.1).
4. **Show the wiki change**: list new sections, modified sections (before → after), deleted sections, and which existing runtime paths are affected. Use a diff or a point-by-point comparison. Never just say "I'll update the docs".
5. **Ask for review**: explicitly write "confirm and I will start changing code". Approval is never assumed.
6. **After approval**: update `PROJECT_WIKI.md`, then give the file-level plan (which files, in what order, how to verify).
7. **If rejected**: change only the wiki, not the code; revise and submit again.

### 0.4 Change log

Append one line to `PROJECT_WIKI.md` for every approved change:

```
## Change log
- 2026-11-13 | request: <one line> | added: <module> | modified: <module> | removed: <module> | impact: <existing call sites>
```

### 0.5 Keeping wiki and code in sync

- Update the wiki when a change is approved (mandatory).
- If implementation reveals the wiki is wrong, fix it immediately and say what was wrong.
- After a refactor or migration, delete modules, interfaces, and call paths that no longer exist.

**Never:** write the wiki once and forget it; keep changing code without the wiki; let the two drift apart; write "see the code" instead of explaining.

## Step 1: Topology survey (before touching anything)

**Input:** the wiki produced in Step 0 (initial version for a new project, latest version otherwise).

Before the first tool call, answer the following in 3–5 sentences; these answers drive every later decision. The first four are always required; the fifth is required whenever a module is added or changed:

| Dimension | What must be answered | What counts as a failure |
|---|---|---|
| **Definition of done** | What state means "finished"? Which command or check proves it? | "It works now" — unverifiable |
| **Subtasks** | Which independent or semi-independent subtasks? What does each deliver? | Fake splits: A and B are really one change |
| **Dependencies** | What is serial, what is parallel? If A fails, is B still meaningful? What shares state? | All parallel (ignores hidden dependencies) or all serial (wastes parallelism) |
| **Capability inventory** | Which skills/tools/subagents cover these subtasks? Where is the gap? Build it or ask the user? | Assuming "some tool probably does this" and starting |
| **Integration surface** | Which wiki module and which runtime path does the new module belong to? Who calls it, what does it read/write, how is it registered? | Guessing location from a name; caring only that the feature works, not that the system can discover or reuse it |

Survey output format (spoken, not a file):

```
Done: <verifiable definition>
Subtasks: T1 <...> / T2 <...> / T3 <...>
Dependencies: T1→T2 serial; T3 parallel with T2; if T1 fails, T3 is moot
Capabilities: T1 uses <tool/skill>; T2 has no coverage → gap = <...> → build it / ask the user
Integration (new modules only): anchor = <wiki module>; data = <entity/table>; calls = <upstream→module→downstream>; registration = <mechanism>
```

## Step 2: Global configuration decisions

Make three **explicit** decisions based on the survey. Write them down; do not keep them in your head.

### 2.1 Routing

Assign each subtask an executor: the main agent, a dedicated skill, a subagent, or the user.

- Many files to read, only a conclusion needed → subagent
- Step-by-step control and continuous context needed → main agent
- Heavy domain knowledge (PDF, bioinformatics, design systems, deployment platforms) → the matching skill
- Missing information, permissions, or business judgement → back to the user; do not guess

### 2.2 Handoff contracts

The deliverable format between subtasks must be decided **before** work starts:

- Structured data (JSON / field list) or free text?
- Is evidence mandatory (file paths + line numbers / command output / request and response)?
- Downstream may consume only the declared fields; it may not read upstream process.

### 2.3 Risk gates

List irreversible or expensive operations and mark each "requires human confirmation":

- Deleting or overwriting files, `push --force`, `reset --hard`, bulk rewrites
- Sending anything outward (messages, email, pull requests, external write APIs)
- Spending money, deploying, releasing, changing production configuration
- Changing public interfaces, database schemas, or contract fields

Gate rule: **stop and report** before the gate — what you are about to do, the blast radius, how to roll back — then proceed only after confirmation.

## Step 3: Subsystem cooperation rules (the seams)

### 3.1 Integration prerequisite: understand the existing architecture first

**Applies to:** new files/modules/services/interfaces/tables/config entries/dependencies, or changes to an existing contract.

**Inputs:** `PROJECT_WIKI.md` + the actual code. When they conflict, the code wins and the wiki gets fixed.

Before writing implementation code or dispatching a subagent, complete these four items and state the conclusions in your reply:

1. **Locate the anchor**: which layer of the wiki architecture does this belong to, next to which module? Read the existing comparable module and its entry points (router table, registry, export index, schema, DI configuration). Never guess from a name.
2. **Map the four connection surfaces**, one by one; missing any means the survey is incomplete:
   - **Data**: which entities/tables/cache keys/files are read or written? Which existing data source owns them? Does this create a second source of truth?
   - **Calls**: who calls this, what does it call (including events, messages, scheduled jobs, hooks)? Sync or async? How do failures propagate back?
   - **State and lifecycle**: initialization order, global/singleton state, cleanup and teardown, concurrency and idempotency.
   - **Configuration and cross-cutting concerns**: which config entries, permissions, logs/metrics, and flags are needed? Are existing mechanisms reused?
3. **Confirm the registration mechanism**: the new module must be discoverable through an existing mechanism (registry, plugin slot, router table, DI container, export index). No hard-coded branches or bypass connections at the call site.
4. **Decide reuse versus new**: if existing capability covers ≥70%, extend it. If a new module is truly needed, explain why extension is impossible and where the boundary sits.

**Prohibited** (stop and redesign if any appear):

- Building a parallel implementation without reading the existing comparable one (two solutions to one problem)
- Bypassing registration, routing, or configuration mechanisms
- Creating a second source of truth (the same data maintained in two places)
- Verifying only "the new feature works" without checking that existing call paths still work

**Deliverable:** an integration-point list (anchor / data / calls / state / config), plus the affected existing modules and how each will be regression-tested.

### 3.2 High cohesion

One subtask, one reason to change. If a subtask covers both "change the data model" and "tweak UI copy", split it further.
Logic repeated across subtasks gets extracted once, not written twice.

### 3.3 Low coupling

- Subtasks communicate only through **contracts**, not shared internals, temporary file names, or local conventions.
- Upstream implementation details (dead ends, abandoned approaches) are not passed downstream.
- Test: changing one subtask should not require changing another. If it does, the contract was underspecified.

### 3.4 Minimal context transfer (compress when delegating)

Give a subagent or downstream step exactly four blocks, never the raw exploration:

```
Goal: <what result is wanted>
Key decisions: <chosen approach and why, one line each>
Constraints: <what must not be touched, what must be obeyed>
Open questions: <what it must judge and report back>
```

### 3.5 Delegation depth limit

- Main agent → subagent. That is the end. A subagent may not delegate.
- If more levels seem necessary, the main agent should run the phases serially, or manage them with TodoWrite.
- Do not wake the same subagent repeatedly for small items; batch them.

### 3.6 Verify before merging

After each subtask is delivered, check it against this list before merging:

- [ ] Meets the part of the definition of done that belongs to it
- [ ] Touched nothing outside the contract's file/data scope
- [ ] Deliverable format matches the handoff contract
- [ ] Key conclusions carry evidence (not "I think" / "should be fine")
- [ ] No conflict with completed subtasks (duplicate definitions, overwrites, semantic drift)
- [ ] The new part registers through an existing mechanism; no parallel approach, no second source of truth
- [ ] Affected existing call sites regression-tested (old paths still work)
- [ ] `PROJECT_WIKI.md` updated; documentation and code agree

## Step 4: Post-execution regression check

Before wrapping up, answer three questions. If you cannot, it is not done:

1. **Against the definition of done**: map every acceptance criterion from Step 1 to concrete evidence (command output, test result, file and line). Anything unmapped is unfinished.
2. **Broken seams**: any "I thought you provided it, you thought I wanted it"? Typical symptoms — mismatched field names, undefined empty values, unhandled error paths, the same state maintained on both sides.
3. **Unverified global changes**: did any subtask change global state (configuration, schema, public interfaces, dependency versions) without passing verification or a gate?

## Completeness and operability check (before delivery)

- **Completeness**: who owns error paths, empty states, timeouts, retries, partial failures? Not every subtask has to handle them, but each must have a named owner.
- **Operability**: how will a failure be observed (logs, status codes, metrics)? How to roll back? What is the degraded mode?
- **Consistency**: is any fact now stored in two places? Are new config entries reflected in docs, examples, and tests? Does the wiki still match?

## Anti-patterns (stop and correct immediately)

| Anti-pattern | Symptom | Correction |
|---|---|---|
| No wiki, start coding | Code first, docs later | Go back to Step 0 |
| Hollow wiki | Only a directory tree, or "handles business logic" | Every paragraph points at a file, function, or table |
| Diagram instead of prose | One architecture diagram, no explanation | Prose must stand alone; diagrams are supplementary |
| Wiki drifted from code | Code changed, wiki did not | Fix it now and say what was stale |
| Act first, review later | Wiki change never shown to the user before coding | Stop implementation, get review, then continue |
| Think while doing | Ten files read before deciding what "done" means | Go back to Step 1 and write three sentences |
| Fake parallelism | Three subagents at once, one feeding another | Make it serial |
| Context dumping | Whole exploration pasted at a subagent | Compress into the four-block handoff |
| Silent overreach | A subtask also bumped a public interface or version | Roll back, go through a gate |
| Outsourced verification | "The subagent said it passed" | The orchestrator reads the evidence |
| Global rewrite for a local need | Rewriting a module for one small request | Draw a minimal change boundary |

## Working with other skills

This skill is a **pre-layer**; it does not replace domain skills:

- Build the wiki and run the survey first, then load the domain skill for the actual subtask
- The domain skill answers "how to do it right"; this skill answers "do the right thing, in the right order, across the right seams"
- When the user explicitly asks for diagrams, pair with `markdown-mermaid-writing` (syntax) or `drafter` (layout); the wiki body stays prose-first
- For complex work, use TodoWrite to turn the surveyed subtasks into a checklist

Templates and worked examples: [reference.md](reference.md). Wiki template and rubric: [project-wiki.md](project-wiki.md).
