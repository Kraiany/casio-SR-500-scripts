# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

Ruby is pinned in `bin/.ruby-version` (3.4.1). Gems are managed with Bundler; the Node dependency is only used for TOC generation in the Markdown docs.

```bash
bundle install                 # Ruby gems (Gemfile)
npm install                    # markdown-toc, for README TOCs only

# Generate orders + items CSVs from EJ files (both output flags are required).
# Input files are converted to UTF-8 IN PLACE, so run this on a copy of data/.
bundle exec ruby bin/generate_monthly_orders_report.rb -o orders.csv -i items.csv "copy/CASIO*/**/*.TXT"

# Convert SJIS receipt files to UTF-8 in place (uses uchardet; must be installed)
ruby bin/open_recode_sjis_file.rb "copy/CASIO*/**/*.TXT"

# Export the PLU (product) settings from the binary AUTOPGM/FILE092P.092 to CSV (read-only)
ruby bin/extract_plu_settings.rb -o plu_settings.csv "data/CASIO-2026-02-01/SR500_550_4000/AUTOPGM/FILE092P.092"

# Export the register's own X/Z report CSVs (XZ/YYYY/MM/*.CSV) as UTF-8 CSVs (read-only, dedupes exports)
ruby bin/extract_z_reports.rb -d reports "data/CASIO_2026-10-04/SR500_550_4000/XZ/20*/*/*.CSV"

# Regenerate the TOC of a README
npm exec markdown-toc -i README.md

# Render a Markdown doc to PDF (needs pandoc + MacTeX, see README_PDF.md)
bin/md2pdf.sh README_PDF.md
```

There is no test suite and no linter configured. Verify parser changes by running the report script on a fresh copy of `data/` before and after the change, and diffing the output CSVs.

## Architecture

This is a parser for Casio SR-500 POS electronic-journal (EJ) text exports. The input is a Shift-JIS text file containing many receipts back to back; the output is two CSVs (one row per order, one row per line item).

The pipeline, which spans several files:

1. **Encoding** — `lib/jp_encoding_file.rb` (`JPEncodingFile < File`) detects the charset with the external `uchardet` binary and rewrites the file as UTF-8 on open (in place). Everything downstream assumes UTF-8 strings.
2. **Splitting receipts** — `lib/sr500_receipt_file.rb` (`SR500ReceiptFile`) walks the lines and decides where each receipt begins and ends. A receipt boundary is any of: a timestamp-only line (`YYYY-MM-DD HH:MM`), a `精算 <timestamp>` settlement line (end of receipts section), a `戻 <timestamp>` return line, or a `------` separator. A separator starts a report block (X/Z reading, settlement) that is skipped up to the next timestamp-only line, because a file can contain more receipts after such a block (some files start with one). Receipts with fewer than 3 lines, or whose third line is the daily report (`日計明細`), are skipped.
3. **Parsing a receipt** — `lib/receipt_parser.rb` (`ReceiptParser`) turns one receipt's lines into a hash (items, subtotal, tax, total, cash, change, corrections, returns). Line classification is driven entirely by the Japanese labels in `lib/sr500_constants.rb` (`対象計`, `内税`, `合  計`, `お預り`, `お  釣`, `現金`, `訂正`, `戻`, `取引中止`, etc.). Note the exact spacing in some labels (`合  計`, `お  釣`); a mismatch silently breaks matching. Items are either one line `name ￥price` or a name line followed by a `￥price` line; lines that are neither are skipped. Receipts paid in exact cash have no `合  計` line, so `totalamountdue` falls back to the subtotal (`対象計`, tax-inclusive).
4. **Corrections** — `SR500ReceiptFile#drop_corrections` removes items that were cancelled on the same receipt (`訂正` lines), matching by price. Cancelled items are not reported.
5. **Filtering** — a receipt is dropped if it has no date, no items, or zero tax (`parsed_data[:tax_amount]` is `0` when the receipt has no 内税 line or a zero tax amount).
6. **Modeling** — `lib/sr500_order.rb` holds `SR500Order` (one per receipt, with a `key` of `<epoch>-<6-digit receipt number>`) and `SR500OrderItem`. Every item is also appended to the class-level `Items.items` array, which is what `Items.to_csv` writes. This global state means `Items` accumulates across all files processed in one run. `SR500Order.register_key` does the same for order keys: a receipt whose key was already built is skipped, which is what makes it safe to pass overlapping (cumulative) exports.
7. **Aggregation / CLI** — `lib/sr500_monthly_receipts.rb` (`SR500MonthlyReceipts`) takes a list of paths (sorted), builds one `SR500ReceiptFile` per path, and concatenates their CSV output with a single header. `bin/generate_monthly_orders_report.rb` is the only real entry point: it globs the path argument, parses, and writes the orders CSV (`-o`) and the items CSV (`-i`).

`lib/sr500_plu_file.rb` (`SR500PluFile`) is separate from this pipeline: it reads the binary `AUTOPGM/FILE092P.092` settings dump (not EJ text). The full format (24 tables, all record layouts, what is confirmed vs unknown) is in `FILE092P_092.md`, which is also a resource of the project skill `sr500-plu-settings` (`.claude/skills/`, symlinked, keep one copy). The layout was reverse-engineered, see also the comments in the class: tables with an 18-byte header, fixed-size records, Shift-JIS names, BCD prices. The PLU number is the record number. Flags (`0x40` etc.) and two trailing bytes per record are not decoded. All `FILE092P.092` copies under `data/` are byte-identical.

`lib/sr500_report_file.rb` / `lib/sr500_report_set.rb` are also separate from the EJ pipeline: they read the register's own X/Z report CSVs (`XZ/YYYY/MM/Z001_DD.CSV`, CP932, 6-line header then a `レコード` table). The prefix digit is the report (001 totals, 002 payments, 004 PLU sales, 005 departments, 009 hourly), `_DD` is the day of the month, an `A`/`B` suffix is a repeated run that day, and PLU report 004 has its own settlement counter. Exports under `data/` are cumulative snapshots: the newest (`CASIO_2026-10-04`, also the `data/XZ` symlink) holds everything the older ones do, with no conflicting content. `BACKUP/` holds binary, compressed copies of the same reports (1:1 by date) and adds nothing. These reports are the reliable source for daily totals: net sales equal department and hourly totals on all but one day.

`lib/sr500_constants.rb` is the shared vocabulary: the Japanese labels, the timestamp regexes, the CSV `HEADERS`, and `Yen = '￥'`. Change parsing behavior there first.

Data layout: `data/` holds raw EJ exports (one directory per export date). `orders.csv`, `items.csv` and `db/cafe_reports.db` at the root are generated/local artifacts; they are git-ignored patterns or large outputs, not sources.

## Format reference

`README_EJ_FORMAT.md` documents every receipt type seen in the EJ files (standard sale, cash, multi-item, change, split tax, returns, official receipts `領収書`, drawer open `＃／替`, daily summary `日計明細`). Read it before changing how a receipt type is detected, since the boundary and skip rules above are derived from those formats.

## Gotchas

- Input files are rewritten in place during parsing. Never point a run at the only copy of an export.
- `parse_returns` only reads a return amount when the following line contains `-`. Receipt headers such as `戻 <timestamp>` are followed by a receipt number, and parsing them used to crash. `returns` is parsed but never written to the CSVs.
- Debugging: there is no `debug` gem or `debugger` call in the code now; add `require 'debug'` locally if you need a breakpoint.
