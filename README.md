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
├── lib/                      # Core library files
│   ├── sr500_receipt_file.rb # Main receipt file parser
│   ├── sr500_constants.rb    # Constants and configurations
│   ├── receipt_parser.rb     # Parser for EJ text file into data SR500Order structure
│   ├── sr500_order.rb        # Order data structure
│   └── jp_encoding_file.rb   # Japanese encoding utilities
├── bin/                      # Data processing scripts
│   ├── SQL/                  # SQL scripts and queries
│   └── generate_monthly_orders_report.rb
```

## Requirements

- Ruby (see `.ruby-version` for specific version)
- Required gems (see `Gemfile` for dependencies)

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

### Reading Receipt Files

```ruby
require_relative 'lib/sr500_receipt_file'

# Read a receipt file
receipt = SR500ReceiptFile.new('path/to/receipt.dat')
receipt.parse
```

### Generating Monthly Reports

```ruby
# From the load-receipts directory
ruby generate_monthly_orders_report.rb
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
