# Design Brief: Deep Researcher

## Classification
- Type: Analytical/Research
- Tier: 2 (Standard)

## Deployment Target
- **Standalone workspace** at `generated-agents/deep-researcher/`
- Reason: The agent IS the primary workspace — user `cd`s in, gives a topic, gets research output. No codebase to augment.

## Scope
- **What it does:** Exhaustively researches any topic at three depth tiers (Deep/Deeper/Deepest) using parallel sub-agents, web search, Playwright for JS-heavy sites, and PDF reading. Produces a structured .md report with inline citations, then auto-converts to .pdf and .docx.
- **What it does NOT do:** Does not write code projects (includes code snippets in reports when relevant, but doesn't scaffold repos). Does not do ongoing monitoring or alerting. Does not produce academic papers with formal peer-review citations (APA/MLA). Does not provide legal, medical, or financial advice.

## Top Failure Modes (ranked by cost)

1. **Hallucinated citations** — Agent fabricates URLs or attributes claims to wrong sources.
   - Prevented by: Mandatory verification pass that fetches each cited URL and confirms the claim exists on that page. Under-sourced claims flagged with `[under-sourced]` marker.

2. **Shallow research disguised as depth** — Verbose output that restates the same surface-level information from multiple similar sources.
   - Prevented by: Per-tier minimum unique source requirements (Deep: 10-20, Deeper: 20-40, Deepest: 40+). Gap analysis pass that identifies under-explored angles. Multi-pass research where second pass explicitly targets gaps from first pass.

3. **Citation gaming** — Formatting opinions as cited facts, or attributing aggregate claims to a single source.
   - Prevented by: Three-tier source strength classification (Evidence > Orientation > Heuristic). Each citation tagged with source type. Synthesis skill distinguishes sourced claims from inferences.

4. **Stale information** — Using outdated data when newer data exists.
   - Prevented by: Recency bias for time-sensitive topics (WebSearch queries include current year). Date-awareness in source evaluation. CRAAP Currency criterion applied.

5. **Format conversion failures** — PDF/DOCX output has broken tables, missing code blocks, or garbled formatting.
   - Prevented by: Validated pandoc pipeline (typst for PDF, reference-doc for DOCX). Export skill runs conversion and checks output file size > 0. Setup script ensures dependencies are installed.

## Skill Plan

| Skill | Purpose | Inputs | Key Risk |
|---|---|---|---|
| `research` | Core pipeline: decompose topic → spawn parallel sub-agents → multi-pass research → gap analysis → synthesize → cite → export | Topic string, depth tier (Deep/Deeper/Deepest), optional language (en/de) | Shallow synthesis, hallucinated citations, missed angles |
| `export` | Convert existing .md to .pdf + .docx via pandoc | Path to .md file (or uses latest output) | Broken formatting, missing pandoc/typst |
| `verify` | Spot-check citations by fetching source URLs and confirming claims match | Path to .md file with inline citations | Token-heavy, source pages may have changed |

## Depth Tier Definitions

| Dimension | Deep | Deeper | Deepest |
|---|---|---|---|
| **Unique sources** | 10-20 | 20-40 | 40+ |
| **Research passes** | 1 pass + synthesis | 2 passes + gap analysis + synthesis | 3+ passes + gap analysis + contrarian search + synthesis |
| **Parallel sub-agents** | 3-4 | 5-6 | 7-8 |
| **Source types** | Web articles, docs, blogs | + academic papers, technical specs, PDFs | + all available: patents, forums, archived pages, foreign-language sources |
| **Contrarian viewpoints** | Not required | Included if found | Actively sought — dedicated sub-agent for opposing views |
| **Report length** | 2,000-4,000 words | 5,000-10,000 words | 10,000+ words |
| **Verification** | Spot-check top 5 claims | Verify all Evidence-tier claims | Verify all claims, cross-reference between sources |

## Research Methodology

### Phase 1: Decomposition
Agent analyzes the topic and splits it into independent research threads. Each thread becomes a sub-agent prompt.

### Phase 2: Parallel Research
Sub-agents execute concurrently. Each sub-agent:
1. WebSearch for the thread topic (multiple queries, including current year for freshness)
2. WebFetch promising URLs for content extraction
3. If WebFetch returns empty/insufficient → fall back to Playwright MCP (browser_navigate → browser_snapshot)
4. For PDF sources: download via curl, read via Read tool (≤100 pages) or pdftotext (>100 pages)
5. Return: distilled findings with source URLs and source strength classification

### Phase 3: Gap Analysis (Deeper/Deepest only)
Main agent reviews sub-agent findings, identifies under-explored angles, and spawns a second wave of sub-agents targeting gaps.

### Phase 4: Contrarian Search (Deepest only)
Dedicated sub-agent searches for opposing viewpoints, critiques, and counter-evidence.

### Phase 5: Synthesis
Main agent weaves all findings into a structured report:
- Adaptive structure based on topic (no rigid template)
- Inline citations as `[claim](source-url)`
- Source strength markers where relevant
- Under-sourced claims flagged: `> **[Under-sourced]** claim text`
- Code snippets included when relevant to the topic

### Phase 6: Export
Automatic conversion: .md → .pdf (pandoc + typst) → .docx (pandoc + reference-doc)

## Knowledge Architecture

| Layer | File | Purpose | Loads |
|---|---|---|---|
| Always-loaded | `CLAUDE.md` | Identity, depth tiers, research rules, citation requirements, output format, ambiguity strategy | Every session |
| On-demand | `skills/research.md` | Full research methodology, sub-agent prompt templates, decomposition strategy, synthesis approach | When user requests research |
| On-demand | `skills/export.md` | Pandoc commands, conversion pipeline, troubleshooting | When converting output |
| On-demand | `skills/verify.md` | Citation verification methodology, CRAAP framework, source strength classification | After synthesis or on demand |
| Reference | `docs/credibility-framework.md` | CRAAP criteria, source strength definitions, examples of each tier | When evaluating sources |
| Reference | `docs/sub-agent-prompts.md` | Reusable prompt templates for research sub-agents | During decomposition |
| Template | `templates/reference.docx` | DOCX reference document for pandoc styling | During export |
| Config | `.mcp.json` | Playwright MCP configuration (headless, cookie dismiss) | Session start |
| Config | `.claude/settings.json` | Tool permissions, allowed bash commands | Session start |
| Setup | `setup.sh` | Install dependencies (pandoc, typst, pymupdf4llm) | One-time |

## Tool Requirements

| Tool | Purpose | When Used |
|---|---|---|
| WebSearch | Primary source discovery | Every research pass |
| WebFetch | Content extraction from URLs | Every research pass |
| Playwright MCP | JS-heavy sites, SPAs, pages where WebFetch fails | Fallback when WebFetch returns empty |
| Agent (sub-agents) | Parallel research threads | Every research task |
| Bash (curl) | Download PDFs and documents from URLs | When source is a downloadable file |
| Bash (pdftotext) | Extract text from PDFs > 100 pages | When PDF exceeds Read tool limit |
| Bash (pandoc) | Convert .md → .pdf and .md → .docx | Export phase |
| Read | Read PDFs ≤ 100 pages, read downloaded documents | When source is a local file |
| Write | Create output .md files | Synthesis phase |

## Ambiguity Strategy

| Situation | Strategy |
|---|---|
| Topic is clear | Research immediately, no questions |
| Topic is ambiguous (e.g., "research Python") | Ask one clarifying question with options |
| Depth tier not specified | Default to **Deep** |
| Language not specified | Default to **English** |
| Report structure not specified | Always adaptive — never ask |
| Conflicting sources found | Include both views with source strength labels, don't pick a winner unless evidence is overwhelming |
| Can't find enough sources | Flag gaps, report what's available, mark under-sourced sections |

## Playwright MCP Configuration

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": [
        "@playwright/mcp@latest",
        "--headless",
        "--viewport-size=1280x720"
      ]
    }
  }
}
```

- Use `browser_snapshot` (accessibility tree) over `browser_take_screenshot` — text-based, parseable, cheaper
- Cookie/popup handling: `browser_snapshot` → identify dismiss button → `browser_click`
- Decision rule: always try WebFetch first, Playwright only when WebFetch fails or returns empty

## Export Pipeline

### PDF (pandoc + typst)
```bash
pandoc output/research.md -o output/research.pdf \
  --pdf-engine=typst \
  --toc \
  --toc-depth=2
```

### DOCX (pandoc + reference-doc)
```bash
pandoc output/research.md -o output/research.docx \
  --reference-doc=templates/reference.docx \
  --toc \
  --toc-depth=3 \
  --highlight-style=kate
```

## Forbidden Outputs
- Never fabricate a URL. If you can't find a source, say so.
- Never present an inference as a cited fact.
- Never claim the research is "complete" or "exhaustive" at Deep or Deeper tiers — only Deepest may claim thoroughness, and even then with the caveat that some sources may be behind paywalls or otherwise inaccessible.

## Open Questions
- None. Requirements are clear from the interview, research validated the technical approach, and the tool ecosystem is confirmed available on the user's machine.
