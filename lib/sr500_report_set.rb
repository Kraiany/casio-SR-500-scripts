require 'csv'
require 'fileutils'
require 'sr500_report_file'

# A class for collecting X/Z report files of Casio SR-500 POS register from
# many exports and writing them as CSV files.
#
# Exports are cumulative snapshots, so the same report is usually present in
# several of them. Reports are identified by mode, report number, date,
# settlement counter and time, and each one is kept once.
#
# Every output row has the Mode column: Z is a settlement, X is an interim
# reading. Sum daily totals over Z rows only. PLU sales (report 004) have
# their own settlement counter, so join them to the other reports by date.
class SR500ReportSet

  # Report numbers.
  Totals      = 1
  Payments    = 2
  PluSales    = 4
  Departments = 5
  Hourly      = 9

  # Labels of the rows of the totals report (001).
  GrossSales    = '総売'
  NetSales      = '純売'
  Cash          = '現金在高'
  Taxable       = '対象計'
  TaxIncluded   = '内税'
  TaxTotal      = '消費税合計'
  Cancelled     = '取引中止'
  Customers     = '純客'

  LEADING = %w[Mode Date Time Settlement\ No].freeze

  FILES = {
    'z_summary.csv'     => LEADING + ['Items', 'Gross Sales', 'Orders', 'Net Sales', 'Cash', 'Taxable',
                                      'Tax Included', 'Tax Total', 'Cancelled Count',
                                      'Cancelled Amount', 'Customers'],
    'z_payments.csv'    => LEADING + %w[Record Name Count Amount],
    'z_departments.csv' => LEADING + %w[Department Name Count Amount],
    'z_hourly.csv'      => LEADING + %w[From To Count Amount],
    'z_plu_sales.csv'   => LEADING + %w[PLU Code Name Count Amount]
  }.freeze

  attr_reader :reports, :skipped, :conflicts

  # @param paths [Array<String>] Report file paths. Files that are not
  #   reports are skipped and listed in +skipped+.
  def initialize(paths)
    @reports   = {}
    @skipped   = []
    @conflicts = []
    paths.sort.each do |path|
      begin
        report = SR500ReportFile.new(path)
      rescue ArgumentError
        @skipped << path
        next
      end
      if (known = @reports[report.key])
        @conflicts << [known.path, path] unless known.rows == report.rows
      else
        @reports[report.key] = report
      end
    end
  end

  # Writes the CSV files to +dir+ and returns { file name => row count }.
  # Rows with zero count and amount are left out unless +all+ is true
  # (hourly rows are always complete).
  def write(dir, all: false)
    FileUtils.mkdir_p(dir)
    FILES.keys.to_h do |name|
      csv = CSV.generate do |out|
        out << FILES[name]
        rows_for(name, all).each { |row| out << row }
      end
      File.write(File.join(dir, name), csv, encoding: 'UTF-8')
      [name, csv.lines.size - 1]
    end
  end

  private

  def sorted(report_number)
    reports.values.select { |r| r.report == report_number }.
      sort_by { |r| [r.date, r.time, r.mode, r.settlement_no] }
  end

  def lead(report)
    [report.mode, report.date, report.time, report.settlement_no]
  end

  def number(text)
    SR500ReportFile.number(text)
  end

  def rows_for(name, all)
    case name
    when 'z_summary.csv'     then summary_rows
    when 'z_payments.csv'    then payments_rows(all)
    when 'z_departments.csv' then department_rows(all)
    when 'z_hourly.csv'      then hourly_rows
    when 'z_plu_sales.csv'   then plu_rows(all)
    end
  end

  # Total report: columns are record, label, count, amount.
  def summary_rows
    sorted(Totals).map do |report|
      line = ->(label) { report.rows.find { |row| row[1] == label } }
      count  = ->(label) { line.(label)&.then { |row| number(row[2]) } }
      amount = ->(label) { line.(label)&.then { |row| number(row[3]) } }
      lead(report) + [count.(GrossSales), amount.(GrossSales), count.(NetSales), amount.(NetSales),
                      amount.(Cash), amount.(Taxable), amount.(TaxIncluded), amount.(TaxTotal),
                      count.(Cancelled), amount.(Cancelled), count.(Customers)]
    end
  end

  # Payments and keys report: columns are record, label, count, amount.
  def payments_rows(all)
    sorted(Payments).flat_map do |report|
      report.rows.reject { |row| row[1].empty? }.
        select { |row| all || number(row[2]) != 0 || number(row[3]) != 0 }.
        map { |row| lead(report) + [row[0].to_i, row[1], number(row[2]), number(row[3])] }
    end
  end

  # Department report: columns are record, name, count, amount.
  def department_rows(all)
    sorted(Departments).flat_map do |report|
      report.rows.
        select { |row| all || number(row[2]) != 0 || number(row[3]) != 0 }.
        map { |row| lead(report) + [row[0].to_i, row[1], number(row[2]), number(row[3])] }
    end
  end

  # Hourly report: columns are record, from, to, count, amount.
  def hourly_rows
    sorted(Hourly).flat_map do |report|
      report.rows.map { |row| lead(report) + [row[1], row[2], number(row[3]), number(row[4])] }
    end
  end

  # PLU report: columns are record, scanning code, name, count, amount. The
  # record number is the PLU number. The code is the PLU code in BCD padded
  # with E, for example "60EEEEEEEEEEEE".
  def plu_rows(all)
    sorted(PluSales).flat_map do |report|
      report.rows.
        select { |row| all || number(row[3]) != 0 || number(row[4]) != 0 }.
        map do |row|
          code = row[1].delete('E')
          lead(report) + [row[0].to_i, code.to_i, row[2], number(row[3]), number(row[4])]
        end
    end
  end

end
