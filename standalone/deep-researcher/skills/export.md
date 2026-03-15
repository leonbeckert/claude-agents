# Export

Converts a .md research report to .pdf and .docx using pandoc.

## Input

From the user:
- **File path:** Path to the .md file to convert (optional — defaults to the most recently created .md in `output/`)

From project files (do NOT ask):
- `templates/reference.docx` — DOCX reference document for styling

## When to Clarify

- Never. Export is fully automated. If dependencies are missing, run setup.sh and retry.

## Process

1. **Identify the source file.** If not specified, find the most recent .md in `output/*/`.

2. **Determine output paths.** Replace the `.md` extension with `.pdf` and `.docx`, keeping the **exact same base filename** in the **same directory**. Example: `output/topic/report.md` → `output/topic/report.pdf` + `output/topic/report.docx`. Never invent a different filename — always derive from the source file.

3. **Convert to PDF:**
   ```bash
   pandoc [input.md] -o [output.pdf] \
     --pdf-engine=typst \
     --toc \
     --toc-depth=2
   ```

4. **Convert to DOCX:**
   ```bash
   pandoc [input.md] -o [output.docx] \
     --reference-doc=templates/reference.docx \
     --toc \
     --toc-depth=3 \
     --highlight-style=kate
   ```

5. **Validate outputs.** Check that both files exist and are non-empty:
   ```bash
   ls -la [output.pdf] [output.docx]
   ```

6. **Report to user.** List the three output files with their paths and sizes.

## Troubleshooting

| Error | Fix |
|---|---|
| `pandoc: command not found` | Run `bash setup.sh` |
| `typst: command not found` | Run `brew install typst` |
| PDF has broken tables | Check markdown table syntax — pipes must align |
| PDF has no syntax highlighting | Typst handles this automatically, check code fence language tags |
| DOCX TOC shows placeholder | Expected — user must right-click TOC in Word and "Update Field" |
| Unicode chars missing in PDF | Typst uses system fonts natively, should work. If not, check font availability |
| YAML frontmatter appears in output | Ensure frontmatter is delimited by `---` on its own lines |

## Rules

- Always convert to both formats — never skip one
- Never modify the source .md during export
- If conversion fails, report the error and the pandoc command that failed so the user can debug
