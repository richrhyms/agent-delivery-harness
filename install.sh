#!/usr/bin/env bash
# Agent Delivery Harness — installer
# Symlinks agent and command definitions into ~/.claude/ so `git pull` picks up
# updates, and copies the protocol spec and config into the runtime directory.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_HOME:-$HOME/.claude}"
AGENTS_DIR="$CLAUDE_DIR/agents/orchestration"
COMMANDS_DIR="$CLAUDE_DIR/commands"
RUNTIME_DIR="$CLAUDE_DIR/orchestration"

info() { printf '  %s\n' "$1"; }

echo "Installing Agent Delivery Harness -> $CLAUDE_DIR"
echo

# --- agents (symlinked) ---
mkdir -p "$AGENTS_DIR"
for f in "$REPO_DIR"/agents/*.md; do
  ln -sfn "$f" "$AGENTS_DIR/$(basename "$f")"
done
info "agents      -> $AGENTS_DIR (symlinked, $(ls -1 "$REPO_DIR"/agents/*.md | wc -l | tr -d ' ') roles)"

# --- commands (symlinked) ---
mkdir -p "$COMMANDS_DIR"
for f in "$REPO_DIR"/commands/orch*.md; do
  ln -sfn "$f" "$COMMANDS_DIR/$(basename "$f")"
done
info "commands    -> $COMMANDS_DIR (symlinked, $(ls -1 "$REPO_DIR"/commands/orch*.md | wc -l | tr -d ' ') commands)"

# --- runtime dir: protocol + config copied, not symlinked ---
# NOTE: agent definitions reference $RUNTIME_DIR/README.md by absolute path,
# so protocol.md installs under that name.
mkdir -p "$RUNTIME_DIR"/{projects,active,archive}

for pair in "protocol.md:README.md" "config.md:config.md"; do
  src="${pair%%:*}"; dst="${pair##*:}"
  if [ -f "$RUNTIME_DIR/$dst" ] && ! cmp -s "$REPO_DIR/$src" "$RUNTIME_DIR/$dst"; then
    cp "$RUNTIME_DIR/$dst" "$RUNTIME_DIR/$dst.bak.$(date +%Y%m%d%H%M%S)"
    info "backed up existing $dst"
  fi
  cp "$REPO_DIR/$src" "$RUNTIME_DIR/$dst"
done
info "protocol    -> $RUNTIME_DIR/README.md"
info "config      -> $RUNTIME_DIR/config.md"
info "runtime     -> $RUNTIME_DIR/{projects,active,archive}"

echo
echo "Done. Next steps:"
echo "  1. Restart Claude Code (or start a new session) so it discovers the commands."
echo "  2. Run  /orch-setup <project>   to configure your first project."
echo "  3. Run  /orch \"<task>\"          to start a task."
