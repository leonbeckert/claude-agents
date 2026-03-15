# Research

Orchestrates the full research pipeline: decompose topic into threads, spawn parallel sub-agents, synthesize findings, and export.

## Input

From the user:
- **Topic:** What to research (required)
- **Depth tier:** Deep, Deeper, or Deepest (optional — defaults to Deep)
- **Language:** en or de (optional — defaults to en)

From project files (do NOT ask):
- `docs/sub-agent-prompts.md` — sub-agent prompt templates
- `docs/credibility-framework.md` — source evaluation criteria

## When to Clarify

- If the topic has multiple distinct meanings (e.g., "research Mercury" — planet, element, or car brand), ask with options
- If the topic is a single word with no obvious interpretation, ask for a brief description
- Never ask about report structure, citation format, or output format — these are fixed

## Process

### Phase 1: Decomposition

Analyze the topic and split it into independent research threads. The number of threads should match the sub-agent count for the depth tier:
- Deep: 3-4 threads
- Deeper: 5-6 threads
- Deepest: 7-8 threads

Good decomposition means threads are independent and collectively exhaustive. Example for "WebAssembly performance":
1. Core architecture and how WASM execution works
2. Benchmarks and performance comparisons vs native/JS
3. Real-world adoption and production use cases
4. Toolchain and developer experience
5. Limitations and known performance pitfalls (Deeper+)
6. Future roadmap and upcoming features (Deeper+)

### Phase 2: Parallel Research

For each thread, launch a background sub-agent using the research thread prompt template from `docs/sub-agent-prompts.md`. Fill in [TOPIC] and [SPECIFIC_ANGLE].

Use `subagent_type: "researcher"` if available, otherwise `"general-purpose"`.
Set `run_in_background: true` for all sub-agents.

**Language adaptation:** If the user requested German output, add to each sub-agent prompt: "Search in both English and German. Return findings in German." The synthesis in Phase 5 must then be written in German.

Wait for all sub-agents to complete. Collect their findings.

**Playwright fallback:** If any sub-agent reports URLs that returned empty via WebFetch, launch a Playwright fallback sub-agent (or handle directly with Playwright MCP tools) to extract that content.

**PDF handling:** If any sub-agent identifies PDF sources:
1. Download with `curl -sL -o output/downloads/[filename].pdf [url]`
2. Read with Read tool if ≤100 pages
3. Use `pdftotext output/downloads/[filename].pdf output/downloads/[filename].txt` for larger files
4. Incorporate findings into the synthesis

### Phase 3: Gap Analysis (Deeper and Deepest only)

Review all sub-agent findings. Identify:
- Angles not covered or only superficially covered
- Claims made without sufficient source diversity
- Questions raised by the research but not answered

Launch 2-3 additional sub-agents using the gap analysis prompt template, targeting the identified gaps.

### Phase 4: Contrarian Search (Deepest only)

Summarize the key claims and consensus from all research so far. Launch a dedicated contrarian sub-agent using the contrarian prompt template to find opposing viewpoints, critiques, and failure cases.

### Phase 5: Synthesis

Weave all findings into a structured .md report:

1. **Create the output directory:** `mkdir -p output/[topic-slug]`
2. **Determine structure adaptively.** Based on the topic and findings, choose a structure that makes sense. There is no rigid template — but most reports benefit from:
   - A summary section at the top (key takeaways)
   - Logical sections organized by theme or question
   - A section on limitations, gaps, or open questions
   - A compiled source list at the bottom
3. **Write with inline citations.** Every factual claim gets `[claim](source-url)`. Group inference statements clearly: "Based on [source A](url) and [source B](url), it appears that..."
4. **Flag under-sourced claims:** `> **[Under-sourced]** claim text`
5. **Include code snippets** when they illustrate a point relevant to the topic
6. **Add metadata** at the top of the report:
   ```
   ---
   title: [Topic]
   depth: [Deep/Deeper/Deepest]
   sources: [count]
   date: [YYYY-MM-DD]
   ---
   ```
   Use `title` (not `topic`) so pandoc picks it up as the document title for PDF/DOCX export.

### Phase 5.5: Lint & Verify

Before export, run the report through two checks:

1. **Lint** (automatic — runs via hook on Write to `output/*/report.md`). The lint script checks:
   - YAML frontmatter is present with `title`, `depth`, `sources`, `date`
   - File is named `report.md`
   - Source count meets tier minimum
   - No uncited factual claims (heuristic: paragraphs with statistics/dates but no inline URL)

   If the hook flags issues, fix them before proceeding.

2. **Verify** (automatic for Deep, expanded for Deeper/Deepest). Run the verify skill:
   - Deep: spot-check top 5 claims
   - Deeper: verify all Evidence-tier citations
   - Deepest: verify all citations

### Phase 6: Export

Run the export skill to convert the .md to .pdf and .docx. **This phase is mandatory unless the user explicitly requested specific formats only (e.g., "just markdown").** Do not silently skip export. If export fails, report the error — do not proceed without it.

## Source Count Validation

Before finishing synthesis, count unique source URLs. If below the tier minimum:
- Deep: minimum 10 → if under, note in the report footer: "Note: This report includes [N] unique sources, below the target of 10-20 for Deep-tier research."
- Deeper: minimum 20 → run one more targeted search pass. If still under after the extra pass, note the shortfall in the report footer.
- Deepest: minimum 40 → run additional passes until sources are exhausted or minimum is met. If still under, note the shortfall and explain what was attempted.

## Good Example (abbreviated)

```markdown
---
title: WebAssembly Performance in 2026
depth: Deep
sources: 14
date: 2026-03-11
---

# WebAssembly Performance in 2026

## Key Takeaways

- WASM execution is [within 10-20% of native performance for compute-heavy tasks](https://example.com/benchmark-2026)
- [Garbage collection support](https://webassembly.org/roadmap/) landed in all major browsers, enabling languages like Java and C# to compile efficiently
- The primary bottleneck remains [DOM interop overhead](https://example.com/dom-analysis), not raw computation

## How WASM Execution Works

WebAssembly uses a [stack-based virtual machine with near-native execution speed](https://webassembly.org/docs/semantics/) because...

> **[Under-sourced]** Some reports suggest WASM cold-start times have improved by 3x since 2024, but no systematic benchmark data was found to confirm this.
```

## Bad Example

```markdown
# WebAssembly Performance

WebAssembly is very fast and efficient. It's used by many companies for high-performance web applications. Studies show it can be up to 20x faster than JavaScript in some cases.

The technology was created by the W3C and is supported by all major browsers.
```

**What's wrong:** No citations anywhere. "Studies show" without a source is a hallucinated citation. "20x faster" is an unsourced claim. "Very fast and efficient" is vague. No metadata, no source list.

## Rules

- **Never skip Phase 6 (export)** unless the user explicitly requested only specific formats. The default expectation is .md + .pdf + .docx.
- **Every report MUST have YAML frontmatter** with `title`, `depth`, `sources`, `date`. This is not optional — pandoc uses it for the document title, and the lint hook checks for it.
- **The final report MUST be named `report.md`** in `output/[topic-slug]/`. Sub-agent working notes go in `output/[topic-slug]/drafts/` if saved.
- **Use the rich citation format**: inline `[claim](url)` plus `- Source: [description](url) | Type | Date` metadata. The lint hook checks for source type annotations.
- When in doubt about a claim, flag it under-sourced rather than dropping it
- Sub-agent prompts must include the full context — sub-agents do not see your conversation history
- Always create the output directory before writing files
