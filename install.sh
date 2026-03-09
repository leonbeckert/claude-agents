#!/usr/bin/env bash
# Install claude-agents by symlinking into ~/.claude/
# Usage: ./install.sh [agent-name]   — install one agent
#        ./install.sh                — install all agents

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

mkdir -p "$CLAUDE_DIR/agents" "$CLAUDE_DIR/skills"

install_agent() {
    local name="$1"
    local agent_file="$REPO_DIR/agents/$name.md"

    if [ ! -f "$agent_file" ]; then
        echo "Error: Agent '$name' not found in $REPO_DIR/agents/"
        exit 1
    fi

    # Symlink agent definition
    ln -sf "$agent_file" "$CLAUDE_DIR/agents/$name.md"
    echo "Linked agents/$name.md"

    # Symlink all skills for this agent
    for skill_dir in "$REPO_DIR/skills/$name"-*/; do
        [ -d "$skill_dir" ] || continue
        local skill_name
        skill_name="$(basename "$skill_dir")"
        ln -sfn "$skill_dir" "$CLAUDE_DIR/skills/$skill_name"
        echo "Linked skills/$skill_name/"
    done
}

if [ $# -eq 1 ]; then
    install_agent "$1"
else
    for agent_file in "$REPO_DIR/agents/"*.md; do
        [ -f "$agent_file" ] || continue
        name="$(basename "$agent_file" .md)"
        install_agent "$name"
    done
fi

echo "Done."
