# Casio SR-500 Scripts

- [Casio SR-500 Scripts](#casio-sr-500-scripts)
  * [Features](#features)
  * [Project Structure](#project-structure)
  * [Requirements](#requirements)
  * [Installation](#installation)
  * [Usage](#usage)
    + [Reading Receipt Files](#reading-receipt-files)
    + [Generating Monthly Reports](#generating-monthly-reports)
  * [Data Format](#data-format)
    + [Electronic Journal File Format](#electronic-journal-file-format)
  * [Documentation](#documentation)
    + [PDF generation](#pdf-generation)
  * [Contributing](#contributing)
---

A collection of Ruby scripts and utilities for working with Casio SR-500 POS register data. This project provides tools for reading, parsing, and analyzing receipt data from Casio SR-500 POS registers.

## Features

- Read and parse Casio SR-500 receipt files
- Handle Japanese character encoding (SJIS/UTF-8)
- Generate monthly reports and analytics
- Export data to CSV format
- Database integration for data storage and querying

## Project Structure

```
.
├── lib/                         # Core library files
│   ├── sr500_receipt_file.rb    # Splits an EJ file into receipts
│   ├── sr500_monthly_receipts.rb # Runs several EJ files as one batch
│   ├── sr500_constants.rb       # Constants and configurations
│   ├── receipt_parser.rb        # Parser for one receipt into a data structure
│   ├── sr500_order.rb           # Order data structure
│   └── jp_encoding_file.rb      # Japanese encoding utilities
├── bin/                         # Command-line scripts
│   ├── generate_monthly_orders_report.rb # Writes orders and items CSV files
│   ├── open_recode_sjis_file.rb # Converts Shift-JIS files to UTF-8 in place
│   └── md2pdf.sh                # Markdown to PDF (see README_PDF.md)
```

## Requirements

- Ruby (see `bin/.ruby-version` for specific version)
- Required gems (see `Gemfile` for dependencies)
- `uchardet` on the `PATH` for charset detection (`brew install uchardet`)

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/casio-SR-500-scripts.git
   cd casio-SR-500-scripts
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

3. install NPM module for Table of Contents generation:
  ```
  npm install
  ```

## Usage

### Generating Monthly Reports

Pass one or more EJ files (a shell wildcard works, quote it so Ruby expands it), plus the two output paths:

```bash
bundle exec ruby bin/generate_monthly_orders_report.rb \
  -o orders.csv -i items.csv "data/CASIO*/**/*.TXT"
```

Note that the input files are converted from Shift-JIS to UTF-8 **in place** before they are parsed. Run the script on a copy if you need to keep the original exports unchanged.

### Reading Receipt Files

```ruby
$LOAD_PATH.unshift 'lib'
require 'sr500_receipt_file'

receipt = SR500ReceiptFile.new('path/to/receipt.txt')
receipt.parse
```

## Data Format

The project works with Casio SR-500 POS register data files, which typically contain:

- Transaction records
- Order details
- Japanese text (encoded in SJIS)

### Electronic Journal File Format

File format with examples of different receipt type examples is
described in the file [README_EJ_FORMAT.md](README_EJ_FORMAT.md)

## Documentation

NPM module `markdown-toc` is used generating table of contents in
README* files. To generate TOC run:
  ```
  npm exec markdown-toc -i README.md
  ```

### PDF generation

For documentation and reports utility script `md2pdf.sh` can be
used. Please see [README_PDF](./README_PDF.md) file for details about
installation and usage of the script.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the terms of the included LICENSE file.
