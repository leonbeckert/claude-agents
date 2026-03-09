# claude-agents

User-level agents for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Each agent is available in every project on your machine.

## Agents

| Agent | Description |
|---|---|
| **context-distiller** | Distills a folder/codebase into a single 30-50K token .md file for handoff to external AI agents without CLI access |

## Install

```bash
git clone <this-repo> ~/claude-agents

# Install all agents
~/claude-agents/install.sh

# Or install one agent
~/claude-agents/install.sh context-distiller
```

The install script symlinks agent definitions and skills into `~/.claude/agents/` and `~/.claude/skills/`. Your existing Claude Code config is not modified.

## Usage

Once installed, agents are available as subagents in any Claude Code session. Invoke via the Agent tool or by asking Claude to delegate to the agent by name.

**Context Distiller example:**
> "Use the context-distiller agent to distill this project, focus on the API layer"

## Structure

```
claude-agents/
├── agents/              # Agent definitions (symlinked to ~/.claude/agents/)
│   └── context-distiller.md
├── skills/              # Agent skills (symlinked to ~/.claude/skills/)
│   └── context-distiller-distill/
│       └── SKILL.md
├── install.sh           # Symlink installer
└── README.md
```

## Uninstall

Remove the symlinks:

```bash
rm ~/.claude/agents/context-distiller.md
rm -rf ~/.claude/skills/context-distiller-distill
```
