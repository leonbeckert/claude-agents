# Source Credibility Framework — How to evaluate and rank sources during research

## CRAAP Criteria

Evaluate every source against these five dimensions before citing:

| Criterion | Question | Red Flags |
|---|---|---|
| **Currency** | When was it published/updated? | No date, 5+ years old for fast-moving topics |
| **Relevance** | Does it directly address the research question? | Tangentially related, clickbait title |
| **Authority** | Who published it? What are their credentials? | Anonymous, no institutional backing, self-published without expertise |
| **Accuracy** | Is it supported by evidence? Can claims be verified? | No citations, contradicts established sources, emotional language |
| **Purpose** | Why does this source exist? | Selling a product, political agenda, satire, entertainment |

## Source Strength Classification

Every source falls into one of three tiers. This determines how it can be used in the report.

### Evidence (highest — supports claims directly)

Sources that provide primary data or authoritative statements of fact.

**Examples:**
- Official documentation (API docs, specs, RFCs, standards)
- Government/regulatory publications
- Peer-reviewed research papers
- Official statistics and datasets
- Primary source documents (original announcements, press releases from the entity)
- Verified benchmark data with methodology disclosed

**Usage:** Can be cited directly to support claims. "According to [source], X is Y."

### Orientation (middle — context and framing)

Sources that provide informed analysis, expert interpretation, or structured summaries.

**Examples:**
- Industry reports (Gartner, McKinsey, etc.)
- Expert blog posts from recognized practitioners
- Conference talks and presentations
- Case studies with documented methodology
- Well-sourced journalism (not opinion pieces)
- Technical tutorials from official or recognized sources

**Usage:** Use for context, framing, and supporting patterns. Hedge when the claim is the author's interpretation. "Industry analysis suggests X [source], though primary data is limited."

### Heuristic (lowest — background only)

Sources that reflect community practice, anecdotal experience, or popular opinion.

**Examples:**
- Forum posts (Reddit, Stack Overflow, HN)
- Personal blog posts without citations
- Social media threads
- Anecdotal case studies ("we did X and it worked")
- Aggregator articles that cite other articles
- Wikipedia (use as a starting point, then follow citations to primary sources)

**Usage:** Background context only. Always hedge. "Community practitioners commonly report X [source], though systematic evidence is limited." Never use as the sole support for a claim.

## Quick Decision Tree

```
Is the source an official document, dataset, or peer-reviewed paper?
  → YES: Evidence
  → NO: Is the author a recognized expert or institution?
    → YES: Does it include citations and methodology?
      → YES: Orientation
      → NO: Heuristic
    → NO: Heuristic
```

## Conflicting Sources

When sources at the same strength tier disagree:
1. Note the disagreement explicitly in the report
2. Present both positions with citations
3. If one position has more Evidence-tier support, note that
4. Do not pick a winner unless Evidence clearly favors one side

When sources at different strength tiers disagree:
1. Evidence overrides Orientation overrides Heuristic
2. Still mention the disagreement if the lower-tier source is widely cited
