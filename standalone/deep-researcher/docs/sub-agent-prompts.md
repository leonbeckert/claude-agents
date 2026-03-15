# Sub-Agent Prompt Templates — Reusable prompts for research sub-agents

## Research Thread Sub-Agent

Use this template for each parallel research thread during the decomposition phase.

```
Research the following specific aspect of [TOPIC]:

**Thread focus:** [SPECIFIC_ANGLE]

**Instructions:**
1. Run multiple WebSearch queries on this angle. Include the current year in at least one query for freshness.
2. For each promising result, use WebFetch to extract the actual content.
3. If WebFetch returns empty or insufficient content (JS-heavy page), note the URL for Playwright fallback.
4. For PDF sources: note the URL for download — do not attempt to download yourself.

**Source evaluation:**
Classify each source you find:
- Evidence: official docs, primary data, peer-reviewed papers
- Orientation: expert analysis, industry reports, case studies
- Heuristic: blog posts, forum threads, anecdotal reports

**Return format:**
For each finding, return:
- The claim or insight (1-2 sentences)
- Source URL
- Source strength (Evidence/Orientation/Heuristic)
- Publication date (if available)
- A relevance note (why this matters for the topic)

**Important:**
- Do NOT fabricate URLs or citations
- If you find conflicting information, report both sides
- Prioritize quality over quantity — 5 strong sources beat 15 weak ones
- If a subtopic has insufficient sources, say so explicitly
```

## Gap Analysis Sub-Agent

Use this template during the second pass (Deeper/Deepest) to find what was missed.

```
You are reviewing research findings on [TOPIC] to identify gaps.

**Existing findings summary:**
[PASTE_SUMMARY_OF_FIRST_PASS_FINDINGS]

**Your task:**
1. Identify angles, subtopics, or perspectives NOT covered in the existing findings
2. For each gap, run targeted WebSearch queries
3. Use WebFetch to extract content from promising results
4. Return findings in the same format as the initial research threads

**Look specifically for:**
- Technical details that were mentioned but not explained
- Alternative approaches or competing solutions not covered
- Recent developments (last 6 months) that may have been missed
- Quantitative data (benchmarks, statistics, adoption rates) where only qualitative claims exist
- Geographic or industry-specific variations

**Return format:**
Same as research thread format, plus:
- Which gap this finding addresses
- How it relates to or modifies existing findings
```

## Contrarian Search Sub-Agent (Deepest only)

Use this template to actively seek opposing viewpoints and critiques.

```
You are searching for opposing viewpoints and critiques on [TOPIC].

**Mainstream position (from research so far):**
[PASTE_KEY_CLAIMS_AND_CONSENSUS]

**Your task:**
1. Search explicitly for critiques, limitations, failures, and opposing views
2. Use queries like: "[TOPIC] criticism", "[TOPIC] problems", "[TOPIC] alternatives", "why not [TOPIC]", "[TOPIC] failed"
3. Look for sources that challenge the mainstream claims found so far
4. Distinguish legitimate technical critiques from uninformed complaints

**Return format:**
For each contrarian finding:
- The contrarian claim (1-2 sentences)
- What mainstream claim it challenges
- Source URL and strength classification
- Assessment: Is this a substantive challenge or a marginal objection?
```

## Playwright Fallback Sub-Agent

Use when WebFetch returns empty for a URL that likely has valuable content.

```
A URL returned empty content via WebFetch, likely because it requires JavaScript rendering.

**URL:** [URL]
**Expected content:** [WHAT_WE_EXPECT_TO_FIND]

**Steps:**
1. Use browser_navigate to load the URL
2. Use browser_wait_for to ensure the page has loaded (wait for a text marker if known)
3. Use browser_snapshot to get the accessibility tree
4. If there are cookie/popup banners, identify the dismiss button in the snapshot and browser_click it, then snapshot again
5. Extract the relevant content from the snapshot
6. Use browser_close when done

**Return:** The extracted content with the source URL, or "content not accessible" if the page blocks automated access.
```
