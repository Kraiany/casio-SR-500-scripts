require 'csv'

# A class for reading one X/Z report CSV file of Casio SR-500 POS register
# (XZ/YYYY/MM/Z001_DD.CSV and similar).
#
# The files are CP932 CSV. They start with a header block of
# name/value rows (mode, file, settlement counter, date, time) followed by a
# table that starts with a "レコード" row and has one row per record number.
# The file is only read, never modified.
#
# File name prefix: X = interim reading, Z = settlement. The number is the
# report: 001 totals, 002 payments and keys, 004 PLU sales, 005 departments,
# 006 groups, 009 hourly, 010 monthly by day.
class SR500ReportFile

  # Names of the header rows.
  FileLabel       = 'ファイル'
  ModeLabel       = 'モード'
  SettlementLabel = '精算回数'
  DateLabel       = '日付'
  TimeLabel       = '時刻'
  RecordLabel     = 'レコード'

  attr_reader :path, :report, :mode, :settlement_no, :date, :time, :columns, :rows

  # @param path [String] The path to the report file.
  # @raise [ArgumentError] if the file is not a report file.
  def initialize(path)
    @path = path
    text  = File.binread(path).force_encoding('Windows-31J').
              encode('UTF-8', invalid: :replace, undef: :replace)
    table = CSV.parse(text, liberal_parsing: true).map { |row| row.map { |f| f.to_s.strip } }

    header = ->(label) { table.find { |row| row[0] == label }&.at(1) }
    file   = header.(FileLabel).to_s
    @report = file[/\AFILE(\d+)\z/, 1]&.to_i
    raise ArgumentError, "#{path}: not a report file (no #{FileLabel} row)" if @report.nil?

    @mode          = header.(ModeLabel)
    @settlement_no = header.(SettlementLabel).to_i
    @date          = header.(DateLabel)
    @time          = header.(TimeLabel)
    @columns       = table.find { |row| row[0] == RecordLabel } || []
    @rows          = table.select { |row| row[0] =~ /\A\d{4}\z/ }
  end

  # Identifies the report regardless of the export it came from.
  def key
    [mode, report, date, settlement_no, time]
  end

  # Converts a number like "28,895" or "-3,586,565" to an integer.
  def self.number(text)
    text.to_s.delete(',').to_i
  end
end
