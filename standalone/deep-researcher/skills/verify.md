# Verify

Spot-checks citations in a research report by fetching source URLs and confirming claims match.

## Input

From the user:
- **File path:** Path to the .md file to verify (optional — defaults to the most recently created .md in `output/`)

From project files (do NOT ask):
- `docs/credibility-framework.md` — source strength classification rules

## When This Runs

- **Automatically** as Phase 5.5 of the research skill, after synthesis and before export.
- **Manually** if the user requests verification of an existing report.
- Never ask for clarification — verification is fully automated.

## Process

1. **Read the report.** Parse all inline citations in the format `[claim text](url)`.

2. **Select citations to verify based on depth tier:**
   - Deep: top 5 most important claims (those that support key takeaways)
   - Deeper: all Evidence-tier citations
   - Deepest: all citations

3. **For each selected citation:**
   a. Fetch the URL using WebFetch with the prompt: "Does this page contain or support the claim: '[claim text]'? Quote the relevant passage if found."
   b. If WebFetch returns empty, try Playwright (browser_navigate → browser_snapshot) and search the snapshot for the claim.
   c. Classify the result:
      - **Verified** — the source contains content supporting the claim
      - **Partial** — the source exists but the claim is a stretch or overstatement
      - **Broken** — the URL returns 404 or is inaccessible
      - **Unverified** — the source exists but the specific claim couldn't be confirmed

4. **Generate a verification report.** Append to the end of the .md file (or create a separate `[topic]-verification.md`):

   ```markdown
   ## Citation Verification Report

   Verified: [count] | Partial: [count] | Broken: [count] | Unverified: [count]

   | # | Claim (truncated) | URL | Status | Notes |
   |---|---|---|---|---|
   | 1 | [first 50 chars...] | [url] | Verified | Exact quote found |
   ```

5. **Flag issues.** For Broken or Unverified citations, add a note in the main report next to the citation suggesting the user review it.

## Good Example

A claim `[WASM runs within 10% of native speed](https://example.com/bench)` is verified:
- WebFetch finds: "Our benchmarks show WebAssembly achieves 90-95% of native performance..."
- Status: **Verified** — source directly supports the claim

## Bad Example

A claim `[React is used by 80% of Fortune 500 companies](https://example.com/survey)` is checked:
- WebFetch finds: "React is popular among enterprise developers..."
- Status: **Partial** — source mentions popularity but doesn't state the 80% figure. The claim overstates what the source says.
- Action: Flag as `> **[Overstatement]** Original source says React is "popular among enterprise developers" but does not provide the 80% figure.`

## Rules

- Do not modify verified claims — only flag problems
- Verification is token-intensive; at Deepest tier with 40+ sources, this may take significant time. Warn the user before starting if there are >30 citations to check.
- If a source URL redirects, follow the redirect and verify against the final destination
- Broken URLs should be flagged but not removed — the user may have a cached copy or alternative access
