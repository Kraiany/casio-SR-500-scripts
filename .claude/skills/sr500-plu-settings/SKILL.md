---
name: sr500-plu-settings
description: Extract the PLU (product) settings - names, prices, departments - and other register settings (department, function key, group and staff names, tax rates, receipt message lines) from the Casio SR-500 binary program file AUTOPGM/FILE092P.092 into UTF-8 CSV. Use when asked about the PLU/product list or prices of the register, product master data, or the format of FILE092P.092.
---

# Extracting settings from FILE092P.092

`AUTOPGM/FILE092P.092` is the register's binary program memory. It is a snapshot
(2025-01-04) and contains no sales data. The full format is in the resource
[FILE092P_092.md](FILE092P_092.md) in this directory: read the section for the table you need
before decoding anything by hand.

## Steps

1. **Find the file.** `ls data/*/SR500_550_4000/AUTOPGM/FILE092P.092`. All copies are
   byte-identical (check with `md5`: `f65a4db84d657d6a554e6aa7ceaee92b`), so use any one.
   The file is only read; never write to it or to `data/`.
2. **Check it is the right file.** Size is 105,712 bytes and it starts with the text `n:P0092:`.
3. **Export the PLU list** to UTF-8 CSV:
   ```bash
   ruby bin/extract_plu_settings.rb -o plu_settings.csv "<path to FILE092P.092>"
   ```
   Columns: `PLU, Name, Price, Department, Department Name, Flags`. Prices are whole yen.
   Add `--all` to include the unused slots (2,500 rows). Output files are git-ignored (`*.csv`).
4. **Verify the result.**
   - 67 data rows: 65 named products plus 2 blank-named records with data (PLU 22 and 23).
   - Names that also occur in the sales data have a price that was actually sold. Compare with
     the `Price` column of the items CSV from `bin/generate_monthly_orders_report.rb` (49 of 49 match
     on the current data).
5. **Other settings** (departments, function keys, staff, hourly slots, tax rates, receipt
   lines, keyboard layout and the raw tables): export them all with
   ```bash
   ruby bin/extract_settings.rb -d settings "<path to FILE092P.092>"
   ```
   which writes 13 CSV files (including `plu.csv`; `-a` adds blank records). The files and
   columns are listed in `FILE092P_092.md`. For a table the exporter does not decode, read it
   with the "Reading any table" snippet there. Text is CP932; prices, PLU codes, hours and tax
   rates are BCD.
6. **If a current product list is needed**, do not use this file: it is from January 2025. Products
   added later (about 10 by the end of 2026) and their sales are in the daily PLU report. Run
   `ruby bin/extract_z_reports.rb -d reports "<export>/SR500_550_4000/XZ/20*/*/*.CSV"` and use
   `reports/z_plu_sales.csv` (names and sales per day; unit price is `Amount / Count`).

## Rules and pitfalls

- The PLU number is the record number (1-based), not a field. Records 25..216 with the name
  `PLUnnnn` and a zero tail are unused default slots, not products.
- The format mixes byte orders: table record size is little endian, record count is big endian.
- Names are 16 bytes and cut off (`BIOLOGIST RENAIS`); strip the trailing spaces.
- The `Flags` value (`0x40` on 49 records), the tax-rate and keyboard-layout tables, and some
  tables are only partly understood; `FILE092P_092.md` marks each as confirmed, probable or unknown.
  Do not present the probable ones as facts.
- Receipt message line 17 is the shop's address (it is in `message_lines.csv`): do not commit the generated files or copy it into committed text.
- If the format needs to be changed in code, update `FILE092P_092.md`, `lib/sr500_settings_file.rb` and `lib/sr500_plu_file.rb` together.
