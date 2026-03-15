#!/bin/bash
# Setup dependencies for deep-researcher agent.
# Run once: bash setup.sh

set -e

echo "Checking and installing dependencies..."

# pandoc — document conversion
if ! command -v pandoc &> /dev/null; then
  echo "Installing pandoc..."
  brew install pandoc
else
  echo "pandoc: $(pandoc --version | head -1)"
fi

# typst — PDF engine (27x faster than LaTeX)
if ! command -v typst &> /dev/null; then
  echo "Installing typst..."
  brew install typst
else
  echo "typst: $(typst --version)"
fi

# pdftotext — PDF text extraction for large PDFs
if ! command -v pdftotext &> /dev/null; then
  echo "Installing poppler (provides pdftotext)..."
  brew install poppler
else
  echo "pdftotext: available"
fi

# tesseract — OCR for scanned PDFs
if ! command -v tesseract &> /dev/null; then
  echo "Installing tesseract..."
  brew install tesseract
else
  echo "tesseract: $(tesseract --version 2>&1 | head -1)"
fi

# Playwright — install browser for MCP
echo "Installing Playwright browser..."
npx playwright install chromium 2>/dev/null || echo "Playwright browser install skipped (will install on first use)"

# Generate DOCX reference template if it doesn't exist
if [ ! -f "templates/reference.docx" ]; then
  echo "Generating DOCX reference template..."
  pandoc -o templates/reference.docx --print-default-data-file reference.docx 2>/dev/null || \
    echo "Note: DOCX reference template generation requires pandoc. Run again after pandoc is installed."
fi

# Create output directory
mkdir -p output

echo ""
echo "Setup complete. Run: cd $(pwd) && claude"
