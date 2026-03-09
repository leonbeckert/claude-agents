# Distill

Produce a single .md context document from a directory, following the full scan → filter → read → confirm → generate → write workflow.

## Input

From the user:
- **Directory path:** Absolute path to the folder to distill. If not provided, use the current working directory.
- **Focus directive** (optional): Natural-language instruction like "just the framework, skip generated agents" or "focus on the API layer." Defaults to full project if omitted.
- **Output path** (optional): Where to write the .md file. Default: `[directory-name]-context.md` in the current working directory.

From project files (do NOT ask):
- Everything. The agent reads the target directory itself.

## When to Clarify

- If the directory path is ambiguous or doesn't exist
- If a large subdirectory (50+ files) falls in a gray area relative to the focus directive — ask whether to include or skip it
- Never clarify about individual file importance — use the heuristic below

## Process

### Phase 1: Scan & Filter

1. Run `find [dir] -type f -not -path '*/.git/*'` to get the complete file list. For large projects (500+ files), pipe through `wc -l` first to gauge scale before listing individual files.
2. Apply the default filter list from the agent definition. Note filtered directories.
3. If a focus directive was given, apply it: exclude directories/files outside the focus, promote files within focus. **If the focus matches no files or directories**, report this to the user, show what the project actually contains, and ask them to adjust the focus or confirm a full-project distillation instead.
4. Run `wc -l` on remaining files to gauge sizes. Run `file` on ambiguous extensions to detect binaries.
5. Produce a working file list sorted by importance (see heuristic below).
6. **Early exit:** If the working file list is empty after filtering (no text files, or all files are binary/filtered), report to the user that the directory contains no distillable text content. Mention any notable binary files by name if functionally relevant. Do not proceed to Phase 2 or produce an output document.

### Phase 2: Read & Score

6. Read high-importance files first: CLAUDE.md, README, main config files, entry points.
7. Read medium-importance files: source files, skills, templates, docs.
8. Skim low-importance files: tests, examples, data fixtures. Read only if budget allows.
9. Track cumulative token usage. When approaching 60% of budget on reading alone, stop reading low-priority files and work with what you have.

### Phase 3: Infer & Confirm Purpose

10. Based on what you've read, draft a 2-3 sentence purpose statement covering: what the project does, who it's for, and what problem it solves.
11. Present the purpose statement to the user using AskUserQuestion with options:
    - "This is accurate" (proceed)
    - "Needs adjustment" (user provides correction)
12. Incorporate any corrections before proceeding.

### Phase 4: Generate Document

13. Write each section following the output template and budget allocation from the agent definition:

**Section 1 — Purpose & Goals (~5%):**
Write the confirmed purpose. Add non-goals and key constraints if discoverable from the code.

**Section 2 — Architecture Overview (~15%):**
Describe how components connect. Identify the main architectural pattern (monolith, microservices, plugin system, pipeline, etc.). Note key design decisions visible in the code (e.g., "uses hooks for lifecycle management" or "separates skills from core logic"). Use ASCII diagrams for complex relationships.

**Section 3 — File Map (~10%):**
Annotated directory tree. Every included file gets a one-line purpose annotation. Filtered directories get a `[filtered]` note. Group by directory. For large projects (200+ files after filtering), list Tier 1 and Tier 2 files individually; summarize Tier 3-4 at directory level with counts (e.g., `src/helpers/ [8 files — validation, formatting, parsing, ...]`). For deeply nested structures (5+ levels), collapse single-child intermediate directories using slash notation (e.g., `src/modules/auth/middleware/`). Example:
```
├── CLAUDE.md                    # Agent identity, core rules, output defaults
├── skills/
│   ├── research.md              # Web research workflow for domain knowledge
│   └── interview.md             # Structured discovery interview process
├── docs/
│   └── guide.md                 # Domain reference: regulations, frameworks
├── node_modules/                # [filtered — dependency dir]
└── .env                         # [REDACTED — environment secrets]
```

**Section 4 — Usage & Operations (~10%):**
How to set up, configure, and run the project. Key commands. Environment requirements. Common workflows. If the project has a README with setup instructions, distill them here. If the project lacks standard documentation, note the gap and include whatever can be inferred from config files, scripts, or code structure.

**Section 5 — Key Files (~60%):**
Include the most important files in full or summarized form. For each file:
- State why it matters (1 sentence)
- Include contents (full or compressed per the compression strategy)
- Note any omissions

Order files by importance, not alphabetically. The most critical file comes first. If a file's content is already substantially reflected in an earlier section (e.g., ARCHITECTURE.md in Architecture Overview), note this and include only content not already covered. For multi-service projects, allocate Key Files budget roughly proportionally across services — each service gets at minimum its entry point and config, even if lower-priority services are heavily compressed.

### Phase 5: Budget Check & Write

14. Estimate total token count: `wc -w [output]` and multiply by 1.4 for code-heavy content or 1.3 for prose-heavy (words → tokens approximation). When within 10% of the 50K limit, use the conservative multiplier.
15. If over 50K tokens: identify the lowest-value content in Key Files and compress or remove it. Repeat until under budget.
16. If under 30K tokens: consider whether important files were missed. Re-read the file list for anything skipped.
17. Write the final .md file to the output path.

## File Importance Heuristic

**Tier 1 — Always include (full or summarized):**
- CLAUDE.md, README.md, README — project identity and instructions
- Main config files: package.json, Cargo.toml, pyproject.toml, Makefile, docker-compose.yml, settings.json
- Entry points: main.*, index.*, app.*, server.*, lib.rs (Rust crate root), __main__.py (Python entry), build.rs (Rust build script), cmd/*/main.go (Go entry)
- Architecture docs: ARCHITECTURE.md, design-brief.md, ADRs

**Tier 2 — Include if budget allows:**
- Source files in src/, lib/, core/
- Skills, plugins, middleware definitions
- API route definitions
- Database schemas, migrations
- CI/CD configs (.github/workflows/, Jenkinsfile)

**Tier 3 — Mention in File Map, inline only if focused:**
- Test files (tests/, spec/, __tests__/)
- Documentation beyond README
- Example files, tutorials
- Scripts, utilities, helpers

**Tier 4 — File Map only (one-line note):**
- Generated code, build output
- Static assets (images, fonts, CSS)
- Vendored/copied dependencies
- Data fixtures, seed files

## Output Template

```markdown
# [Project Name] — Context Document

> Generated [YYYY-MM-DD] | Focus: [directive or "full project"] | ~[X]K tokens
> Source: `[absolute path]`

---

## 1. Purpose & Goals

[Confirmed purpose statement. Non-goals. Key constraints.]

## 2. Architecture Overview

[Components, connections, patterns, decisions, data flow.]

## 3. File Map

[Annotated directory tree]

## 4. Usage & Operations

[Setup, commands, workflows, environment requirements.]

## 5. Key Files

### [filename]
> [Why this file matters — 1 sentence]

\`\`\`[language]
[file contents, full or summarized]
\`\`\`

[Repeat for each key file, ordered by importance]
```

## Good Example (abbreviated)

```markdown
# Agent Factory — Context Document

> Generated 2026-03-09 | Focus: framework only, skip generated agents | ~38K tokens
> Source: `/Users/leon/AI/agent-factory`

---

## 1. Purpose & Goals

Agent Factory is a meta-agent that engineers specialized Claude Code agents. It follows
a phased workflow (classify → interview → research → design → build → validate → deliver)
to produce agents with the right evals, tools, retrieval boundaries, and failure checks.
The system is designed for a single developer who builds agents for various professional
and personal needs.

Non-goals: not a documentation generator, not autonomous (user approves designs),
not optimizing for file count.

## 2. Architecture Overview

The factory is a Claude Code project with a skill-based architecture...
[continues with component descriptions, ASCII diagram, design decisions]
```

## Bad Example (abbreviated)

```markdown
# Project Summary

Here are all the files in the project:

CLAUDE.md:
[entire file pasted]

README.md:
[entire file pasted]

skills/research.md:
[entire file pasted]

[...20 more files pasted with no context, no architecture section,
no purpose statement, and way over token budget]
```

**What's wrong:** No purpose section (reader doesn't know what this is or why). No architecture overview (reader can't see how pieces connect). Files dumped alphabetically with no importance ordering. No annotations explaining why each file matters. No compression — guaranteed to blow token budget. No file map — reader can't see project structure at a glance.

## Rules

1. Never skip the purpose confirmation step — a wrong purpose frames the entire document incorrectly
2. Track token budget throughout. Better to produce a tight 35K doc than a bloated 55K one
3. Read before summarizing. Never describe a file you haven't actually read
4. The File Map section must reflect the FULL directory structure (with filters noted), not just the files you chose to inline
5. Key Files must be ordered by importance to the project, not alphabetically
6. Redact any secrets found in files — replace with `[REDACTED]`
7. No opinions, no suggestions, no code review — this is a factual mirror of the codebase
