#!/usr/bin/env sh
# Installer for the system-engineering agent skill (POSIX, no dependencies).
set -eu

NAME="system-engineering"
SRC_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TARGET="qoder"
LANG_OPT="zh"
DEST_ROOT=""
FORCE="0"

usage() {
  cat <<EOF
system-engineering installer

Usage: ./scripts/install.sh [options]

Options:
  --target <t>   qoder | claude | project | all   (default: qoder)
  --lang <l>     zh | en                          (default: zh)
  --dir <path>   destination root for --target project (default: ./.qoder/skills)
  --force        overwrite without keeping a backup
  -h, --help     show this help
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --target|-t) TARGET=$(printf '%s' "${2:-}" | tr '[:upper:]' '[:lower:]'); shift 2 ;;
    --lang|-l)   LANG_OPT=$(printf '%s' "${2:-}" | tr '[:upper:]' '[:lower:]'); shift 2 ;;
    --dir|-d)    DEST_ROOT=${2:-}; shift 2 ;;
    --force|-f)  FORCE="1"; shift ;;
    -h|--help)   usage; exit 0 ;;
    *) echo "error: unknown argument $1" >&2; usage >&2; exit 1 ;;
  esac
done

case "$LANG_OPT" in
  zh|en) ;;
  *) echo "error: --lang must be zh or en" >&2; exit 1 ;;
esac

dest_for() {
  case "$1" in
    qoder)  printf '%s' "$HOME/.qoder/skills/$NAME" ;;
    claude) printf '%s' "$HOME/.claude/skills/$NAME" ;;
    project)
      root=${DEST_ROOT:-$PWD/.qoder/skills}
      printf '%s' "$root/$NAME" ;;
    *) echo "error: unknown target $1" >&2; exit 1 ;;
  esac
}

install_into() {
  dest=$1
  if [ -e "$dest" ]; then
    if [ "$FORCE" = "1" ]; then
      rm -rf "$dest"
    else
      backup="$dest.bak-$(date +%Y%m%d-%H%M%S)"
      mv "$dest" "$backup"
      echo "  backup  $backup"
    fi
  fi
  mkdir -p "$dest"

  if [ "$LANG_OPT" = "en" ]; then
    cp "$SRC_DIR/SKILL.en.md" "$dest/SKILL.md"
    cp "$SRC_DIR/SKILL.md" "$dest/SKILL.zh-CN.md"
  else
    cp "$SRC_DIR/SKILL.md" "$dest/SKILL.md"
    cp "$SRC_DIR/SKILL.en.md" "$dest/SKILL.en.md"
  fi
  for f in reference.md project-wiki.md README.md README.zh-CN.md; do
    [ -f "$SRC_DIR/$f" ] && cp "$SRC_DIR/$f" "$dest/$f"
  done
  printf '{\n  "name": "%s",\n  "version": "%s",\n  "lang": "%s",\n  "installedAt": "%s"\n}\n' \
    "$NAME" "$(node -p "require('$SRC_DIR/package.json').version" 2>/dev/null || echo unknown)" \
    "$LANG_OPT" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$dest/.installed.json"
}

if [ "$TARGET" = "all" ]; then
  set -- qoder claude
else
  set -- "$TARGET"
fi

for t in "$@"; do
  dest=$(dest_for "$t")
  echo "installing $NAME ($LANG_OPT) -> $dest"
  install_into "$dest"
  echo "  done"
done

echo ""
echo "Restart your agent so it rescans the skills directory."
