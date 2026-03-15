# claude-agents

Production-grade [Claude Code](https://docs.anthropic.com/en/docs/claude-code) agents built via a structured engineering pipeline with evaluation gates, failure taxonomies, and token-optimized output. Designed for AI-to-AI handoff workflows.

Each agent in this repo was engineered through a multi-phase factory process — classified by type and risk tier, interviewed for requirements, designed with ranked failure modes, built against a design brief, and validated through hard-gate evals before release. This isn't prompt engineering. It's systems engineering applied to AI agent design.

## Why This Exists

LLMs are powerful but stateless. Every new conversation starts from zero unless you give it structured context. These agents solve the operational problem of making AI workflows reliable, repeatable, and quality-gated — the same way you'd treat any production system.

The core insight: **the quality of an AI agent is determined by what it refuses to do, not what it can do.** Every agent here has explicit failure modes, forbidden outputs, and ambiguity strategies — because in production, the failure cases matter more than the happy path.

## Agents

### Installable (user-level)

These agents install into `~/.claude/` via symlinks and are available as subagents in any Claude Code session.

| Agent | What It Does | Key Engineering Decisions |
|---|---|---|
| **context-distiller** | Distills any codebase into a single 30-50K token `.md` file for handoff to external AI agents without CLI access | Token budget derived from [GPT-5.4 context degradation research](https://help.apiyi.com/en/gpt-5-4-1m-context-272k-pricing-threshold-performance-guide-en.html) — retrieval holds at 256K but reasoning degrades earlier. 5-phase workflow with purpose confirmation gate. 4-tier file importance heuristic. Credential detection via pattern matching + content analysis. |

### Standalone

Self-contained workspace agents in `standalone/`. Clone the repo, `cd` into the agent directory, and run `claude`.

| Agent | What It Does |
|---|---|
| **deep-researcher** | Exhaustively investigates any topic using web sources and produces structured reports with inline citations in `.md`, `.pdf`, and `.docx` formats |

## Agent Architecture

This repo ships two types of agents:

**Installable agents** use a two-layer structure:

```
agents/[name].md          # System prompt: identity, constraints, budget rules,
                          # filter lists, compression strategy, forbidden outputs

skills/[name]-[skill]/    # Execution logic: step-by-step workflow, heuristics,
    SKILL.md              # input/output specs, good+bad examples, edge case handling
```

The separation matters: the agent definition sets **what** and **why** (loaded every session), while skills define **how** (loaded on demand). This mirrors the infrastructure pattern of separating configuration from execution logic.

**Standalone agents** are self-contained workspaces with their own `CLAUDE.md`, skills, docs, and tooling:

```
standalone/[name]/
    CLAUDE.md             # Agent instructions (loaded automatically by Claude Code)
    skills/               # Skill definitions
    docs/                 # Reference material and knowledge
    evals/                # Test cases and validation criteria
    setup.sh              # Dependency installation
```

## Engineering Process

Every agent goes through these phases before release:

```
classify → interview → research → design → build → validate → deliver
   │           │           │          │         │         │
   │           │           │          │         │         └─ hard gates:
   │           │           │          │         │            - no fabrication
   │           │           │          │         │            - no secret leaks
   │           │           │          │         │            - budget compliance
   │           │           │          │         │            - structure conformance
   │           │           │          │         │
   │           │           │          │         └─ scored dimensions (1-5):
   │           │           │          │            completeness, density,
   │           │           │          │            navigability, accuracy
   │           │           │          │
   │           │           │          └─ failure taxonomy:
   │           │           │             ranked by cost, each mapped
   │           │           │             to a prevention mechanism
   │           │           │
   │           │           └─ domain research (intensity
   │           │              varies by agent type)
   │           │
   │           └─ structured discovery:
   │              scope, constraints, audience,
   │              deployment target
   │
   └─ type + risk tier classification
      (determines everything downstream)
```

**Release criteria:** All hard gates pass on all test cases (zero tolerance). 80%+ of representative cases score 3+ on all dimensions. All edge and adversarial cases handled. No exceptions.

## Context Distiller — Deep Dive

The first agent solves a specific problem: **how do you give an external AI full understanding of a codebase it can't access?**

Naive approach: dump all files into a prompt. This fails because:
- Token budgets are real — reasoning quality degrades past ~50K tokens
- Not all files are equally important — lock files and generated code are noise
- Without structure, the receiving model can't build a mental model
- Secrets get leaked, binaries get included, context gets wasted

The context-distiller's approach:

**1. Scan & Filter** — Systematic traversal with smart defaults (skip `.git/`, `node_modules/`, credentials, binaries). Pattern-based credential detection catches `secrets.json`, `*.pem`, `*.key`, and files with `secret`/`credential`/`password`/`token` in the name.

**2. Read & Score** — 4-tier importance heuristic. Tier 1 (always include): entry points, config files, architecture docs. Tier 4 (file map only): generated code, static assets, data fixtures. Budget-aware: stops reading low-priority files when approaching 60% of token budget.

**3. Infer & Confirm Purpose** — Drafts a purpose statement from code analysis, then confirms with the user before proceeding. A wrong purpose frames the entire document incorrectly — this is the highest-cost single failure.

**4. Generate** — Structured output with enforced section order and per-section token allocation:

| Section | Budget | Why This Order |
|---|---|---|
| Purpose & Goals | 5% | Intent first — why does this exist? |
| Architecture Overview | 15% | Structure second — how does it work? |
| File Map | 10% | Navigation third — what's where? |
| Usage & Operations | 10% | Operations fourth — how do I use it? |
| Key Files | 60% | Details last — the actual code |

**5. Budget Check** — Token estimation with language-aware multipliers (1.4x for code, 1.3x for prose). Compresses or removes lowest-value content until under 50K.

## Install

### Installable agents

```bash
git clone https://github.com/leonbeckert/claude-agents.git ~/claude-agents

# Install all installable agents
~/claude-agents/install.sh

# Install a specific agent
~/claude-agents/install.sh context-distiller
```

The install script symlinks agent definitions and skills into `~/.claude/`. Your existing Claude Code configuration is not modified — symlinks are additive.

Once installed, agents are available as subagents in any Claude Code session:

```
> Use the context-distiller agent to distill this project, focus on the API layer
```

### Standalone agents

```bash
cd ~/claude-agents/standalone/deep-researcher
./setup.sh   # install dependencies (first time only)
claude        # start the agent
```

## Built With

These agents are produced by [agentspawn](https://github.com/leonbeckert/agentspawn) — a meta-agent that engineers specialized Claude Code agents through structured phases with evaluation gates and failure-first design.
