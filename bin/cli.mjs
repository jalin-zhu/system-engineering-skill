#!/usr/bin/env node
// Installer for the system-engineering agent skill. No dependencies.
import { existsSync, mkdirSync, cpSync, rmSync, renameSync, readFileSync, writeFileSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const NAME = "system-engineering";
const VERSION = JSON.parse(readFileSync(join(ROOT, "package.json"), "utf8")).version;

const TARGETS = {
  qoder: () => join(homedir(), ".qoder", "skills", NAME),
  claude: () => join(homedir(), ".claude", "skills", NAME),
  project: (opts) => join(resolve(opts.dir || join(process.cwd(), ".qoder", "skills")), NAME),
};

const SHARED_FILES = ["reference.md", "project-wiki.md", "INSTALL.md", "README.md", "README.zh-CN.md"];

function usage() {
  console.log(`system-engineering-skill v${VERSION}

Usage:
  system-engineering-skill install [options]
  system-engineering-skill status
  system-engineering-skill uninstall [options]

Options:
  --target <t>   qoder | claude | project | all   (default: qoder)
  --lang <l>     zh | en                          (default: zh)
  --dir <path>   destination root for --target project (default: ./.qoder/skills)
  --force        overwrite without keeping a backup
  -h, --help     show this help

Targets:
  qoder     ${TARGETS.qoder()}
  claude    ${TARGETS.claude()}
  project   <dir>/${NAME}/`);
}

function parseArgs(argv) {
  const opts = { target: "qoder", lang: "zh", dir: null, force: false, command: "help", unknown: [] };
  const rest = [];
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "-h" || a === "--help") opts.command = "help";
    else if (a === "--force" || a === "-f") opts.force = true;
    else if (a === "--target" || a === "-t") opts.target = (argv[++i] || "").toLowerCase();
    else if (a === "--lang" || a === "-l") opts.lang = (argv[++i] || "").toLowerCase();
    else if (a === "--dir" || a === "-d") opts.dir = argv[++i];
    else if (a.startsWith("-")) opts.unknown.push(a);
    else rest.push(a);
  }
  if (rest.length) opts.command = rest[0].toLowerCase();
  return opts;
}

function resolveTargets(opts) {
  if (opts.target === "all") return ["qoder", "claude"];
  if (!TARGETS[opts.target]) {
    fail(`unknown target "${opts.target}" — use qoder, claude, project, or all`);
  }
  return [opts.target];
}

function installInto(dest, opts) {
  if (existsSync(dest)) {
    if (opts.force) {
      rmSync(dest, { recursive: true, force: true });
    } else {
      const backup = `${dest}.bak-${timestamp()}`;
      renameSync(dest, backup);
      console.log(`  backup  ${backup}`);
    }
  }
  mkdirSync(dest, { recursive: true });

  if (opts.lang === "en") {
    cpSync(join(ROOT, "SKILL.en.md"), join(dest, "SKILL.md"));
    cpSync(join(ROOT, "SKILL.md"), join(dest, "SKILL.zh-CN.md"));
  } else {
    cpSync(join(ROOT, "SKILL.md"), join(dest, "SKILL.md"));
    cpSync(join(ROOT, "SKILL.en.md"), join(dest, "SKILL.en.md"));
  }
  for (const f of SHARED_FILES) {
    const src = join(ROOT, f);
    if (existsSync(src)) cpSync(src, join(dest, f));
  }
  writeFileSync(
    join(dest, ".installed.json"),
    JSON.stringify({ name: NAME, version: VERSION, lang: opts.lang, installedAt: new Date().toISOString() }, null, 2) + "\n"
  );
}

function cmdInstall(opts) {
  if (!["zh", "en"].includes(opts.lang)) fail(`unknown lang "${opts.lang}" — use zh or en`);
  for (const t of resolveTargets(opts)) {
    const dest = TARGETS[t](opts);
    console.log(`installing ${NAME} v${VERSION} (${opts.lang}) → ${dest}`);
    installInto(dest, opts);
    console.log("  done");
  }
  console.log(`\nRestart your agent so it rescans the skills directory.`);
}

function cmdStatus() {
  console.log(`${NAME} v${VERSION} (source: ${ROOT})\n`);
  const rows = [];
  for (const [name, fn] of Object.entries(TARGETS)) {
    let dest;
    try {
      dest = fn({ dir: null });
    } catch {
      continue;
    }
    const meta = join(dest, ".installed.json");
    let state = "not installed";
    if (existsSync(join(dest, "SKILL.md"))) {
      state = existsSync(meta) ? `installed (${JSON.parse(readFileSync(meta, "utf8")).version})` : "installed (unknown version)";
    }
    rows.push([name, dest, state]);
  }
  for (const [name, dest, state] of rows) {
    console.log(`  ${name.padEnd(8)} ${state.padEnd(26)} ${dest}`);
  }
  console.log(`\n  project  (resolved at install time from --dir)`);
}

function cmdUninstall(opts) {
  for (const t of resolveTargets(opts)) {
    const dest = TARGETS[t](opts);
    if (!existsSync(dest)) {
      console.log(`  ${t}: not installed at ${dest}`);
      continue;
    }
    if (!statSync(dest).isDirectory()) fail(`${dest} is not a directory`);
    rmSync(dest, { recursive: true, force: true });
    console.log(`  ${t}: removed ${dest}`);
  }
}

function timestamp() {
  const d = new Date();
  const p = (n) => String(n).padStart(2, "0");
  return `${d.getFullYear()}${p(d.getMonth() + 1)}${p(d.getDate())}-${p(d.getHours())}${p(d.getMinutes())}${p(d.getSeconds())}`;
}

function fail(msg) {
  console.error(`error: ${msg}`);
  process.exit(1);
}

const opts = parseArgs(process.argv.slice(2));
switch (opts.command) {
  case "install":
    cmdInstall(opts);
    break;
  case "status":
    cmdStatus();
    break;
  case "uninstall":
    cmdUninstall(opts);
    break;
  case "help":
    usage();
    break;
  default:
    fail(`unknown command "${opts.command}" — run with --help`);
}
