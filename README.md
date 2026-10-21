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
│   ├── sr500_plu_file.rb        # Reader for the binary PLU settings file
│   ├── sr500_report_file.rb     # Reader for one X/Z report CSV
│   ├── sr500_report_set.rb      # Collects X/Z reports from many exports into CSV files
│   ├── sr500_constants.rb       # Constants and configurations
│   ├── receipt_parser.rb        # Parser for one receipt into a data structure
│   ├── sr500_order.rb           # Order data structure
│   └── jp_encoding_file.rb      # Japanese encoding utilities
├── bin/                         # Command-line scripts
│   ├── generate_monthly_orders_report.rb # Writes orders and items CSV files
│   ├── extract_plu_settings.rb  # Writes the PLU settings of the register to CSV
│   ├── extract_z_reports.rb     # Writes the X/Z reports of the register to CSV
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

### Extracting PLU Settings

The register's PLU (product) settings are stored in a binary file,
`AUTOPGM/FILE092P.092`, in the data export. To get them as a UTF-8 CSV:

```bash
ruby bin/extract_plu_settings.rb -o plu_settings.csv \
  "data/CASIO-2026-02-01/SR500_550_4000/AUTOPGM/FILE092P.092"
```

Columns are `PLU`, `Name`, `Price`, `Department`, `Department Name` and
`Flags` (raw hex of five status bytes, meaning not decoded). Unused slots
are skipped; pass `--all` to include all 2500. The file is only read, not
modified.

### Extracting X/Z Reports

The register writes its own daily reports to `XZ/YYYY/MM/*.CSV` (`Z001_02 .CSV`
is report 001 of the 2nd day of the month). `Z` files are settlements and `X`
files are interim readings. To convert them to UTF-8 CSV files:

```bash
ruby bin/extract_z_reports.rb -d reports "data/CASIO_2026-10-04/SR500_550_4000/XZ/20*/*/*.CSV"
```

Five files are written to the `reports` directory: `z_summary.csv` (totals,
tax, cancellations per settlement), `z_payments.csv`, `z_departments.csv`,
`z_hourly.csv` and `z_plu_sales.csv`. Every row has a `Mode` column (`Z` or
`X`); sum daily totals over `Z` rows only. PLU sales have their own settlement
counter, so join them to the other files by `Date`. Rows with zero count and
amount are skipped unless `--all` is given (hourly rows are always complete).

Exports are cumulative snapshots: the newest one contains everything from the
older ones. Passing several exports is safe, each report is read once. The
report files are only read, never modified. Use the department totals
(`z_summary.csv`, `z_departments.csv`, `z_hourly.csv`) for sales amounts. PLU
sales can be lower than net sales on some days, because items rung on open
department keys have no PLU.

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
