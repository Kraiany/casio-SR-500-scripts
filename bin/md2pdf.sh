#!/bin/bash

# A script to convert Markdown to PDF with support for multiple languages.
# It automatically determines the output PDF name from the input Markdown file.
#
# Usage: ./generate_pdf.sh <input_file.md>

# --- Check for the single required argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <input_file.md>"
    exit 1
fi

INPUT_FILE=$1
# Automatically create the output filename by replacing \.md with \.pdf
OUTPUT_FILE={INPUT_FILE%.md}.pdf

# --- Run the Pandoc command
pandoc "$INPUT_FILE" \
    --pdf-engine=xelatex \
    -o "$OUTPUT_FILE" \
    -V CJKmainfont="Toppan Bunkyu Gothic" \
    -V mainfont="Times New Roman" \
    -V geometry:"top=1cm, bottom=2cm, left=2cm, right=2cm" \
    -V papersize=a4

# --- Check for success
if [ $? -eq 0 ]; then
    echo "✅ Successfully generated $OUTPUT_FILE"
else
    echo "❌ Failed to generate PDF."
fi

