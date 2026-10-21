require 'csv'
require 'fileutils'

# A class for reading the settings (program memory) file of Casio SR-500 POS
# register (AUTOPGM/FILE092P.092) and writing its tables as CSV files.
#
# The format is described in FILE092P_092.md. In short: a text header
# "n:P0092:", a container header at 0x80, then pairs of a descriptor block
# and a table up to the end of the file:
#
#   69 00 <length: u16 LE> <length - 1 bytes>      descriptor block
#   66 00 <table id> 01 00 <?> 00 00 00 <record size: u32 LE> 01 00 00 <count: u16 BE>
#   <count> records of <record size> bytes
#
# Text is Shift-JIS, padded with spaces. Numbers (prices, tax rates, hours,
# codes) are BCD. The file is only read, never modified.
class SR500SettingsFile

  MAGIC       = 'n:P0092:'.b
  FIRST_BLOCK = 0xA0

  # Table ids.
  TotalsLabels = 1
  Functions    = 2
  Departments  = 5
  Groups       = 6
  Staff        = 7
  Hours        = 9
  ReportNames  = 24
  PrintLabels  = 23
  TaxRates     = 25
  TaxRates2    = 27
  Messages     = 32
  Keyboard     = 74

  # Tables that are written as raw records (undecoded or mostly empty).
  RAW_TABLES = [20, 22, 28, 29, 30, 38, 43, 44, 62, 91, 98].freeze

  # What a key of the keyboard layout table (74) points to.
  KEY_KINDS = { 2 => 'Function (probable)', 4 => 'PLU', 5 => 'Department' }.freeze

  FILES = {
    'departments.csv'     => %w[Department Name Flags Amount],
    'function_keys.csv'   => %w[Record Code Name Flags],
    'groups.csv'          => %w[Group Name],
    'staff.csv'           => %w[Record Name Number],
    'hourly_slots.csv'    => %w[Slot From To],
    'totals_labels.csv'   => %w[Line Label],
    'report_names.csv'    => %w[Number Name],
    'print_labels.csv'    => %w[Number Label],
    'tax_rates.csv'       => ['Set', 'Record', 'Rate %', 'Field 0x45', 'Flag', 'Mode'],
    'message_lines.csv'   => %w[Line Text],
    'keyboard_layout.csv' => %w[Row Level Kind Meaning Number],
    'raw_tables.csv'      => %w[Table Record Hex Text]
  }.freeze

  attr_reader :path, :tables

  # @param path [String] The path to FILE092P.092.
  # @raise [ArgumentError] if the file is not a settings file or its
  #   structure is damaged.
  def initialize(path)
    @path = path
    @data = File.binread(path)
    unless @data.start_with?(MAGIC)
      raise ArgumentError, "#{path}: not a settings file (no #{MAGIC} header)"
    end
    @tables = read_tables
  end

  # Records (binary strings) of a table. When +size+ is given the record
  # size must match.
  def records(id, size = nil)
    list = tables[id]
    if list.nil? || (size && list.first && list.first.bytesize != size)
      raise "#{path}: table #{id}#{" with #{size} bytes records" if size} not found"
    end
    list
  end

  # Writes the CSV files of all tables except the PLU list to +dir+ and
  # returns { file name => row count }. Empty records (blank text, zeros)
  # are left out unless +all+ is true.
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

  # Walks the chain of descriptor blocks and tables.
  def read_tables
    result = {}
    pos = FIRST_BLOCK
    while pos < @data.bytesize
      unless @data.byteslice(pos, 2) == "i\x00".b
        raise ArgumentError, "#{path}: damaged file, no descriptor block at 0x#{pos.to_s(16)}"
      end
      length = @data.byteslice(pos + 2, 2).unpack1('v')
      head   = pos + 4 + (length - 1)
      unless @data.byteslice(head, 2) == "f\x00".b
        raise ArgumentError, "#{path}: damaged file, no table at 0x#{head.to_s(16)}"
      end
      id    = @data.getbyte(head + 2)
      size  = @data.byteslice(head + 9, 4).unpack1('V')
      count = @data.byteslice(head + 16, 2).unpack1('n')
      start = head + 18
      stop  = start + size * count
      if stop > @data.bytesize
        raise ArgumentError, "#{path}: damaged file, table #{id} runs past the end"
      end
      result[id] = Array.new(count) { |i| @data.byteslice(start + i * size, size) }
      pos = stop
    end
    result
  end

  def decode(bytes)
    bytes.dup.force_encoding('Windows-31J').
      encode('UTF-8', invalid: :replace, undef: :replace).strip
  end

  # BCD digits to integer. Returns nil when a nibble is not a digit.
  def bcd(bytes)
    digits = bytes.unpack1('H*')
    digits =~ /\A\d+\z/ ? digits.to_i : nil
  end

  def hex(bytes)
    bytes.unpack1('H*')
  end

  # The raw tables are binary, so a space byte is a value like any other.
  def zeros?(record)
    record.bytes.all?(0)
  end

  def rows_for(name, all)
    case name
    when 'departments.csv'     then department_rows
    when 'function_keys.csv'   then function_rows(all)
    when 'groups.csv'          then text_rows(Groups, 0, 16)
    when 'staff.csv'           then staff_rows
    when 'hourly_slots.csv'    then hour_rows
    when 'totals_labels.csv'   then text_rows(TotalsLabels, 0, 12)
    when 'report_names.csv'    then text_rows(ReportNames, 0, 12)
    when 'print_labels.csv'    then text_rows(PrintLabels, 0, 12, all)
    when 'tax_rates.csv'       then tax_rows
    when 'message_lines.csv'   then text_rows(Messages, 0, 24, all)
    when 'keyboard_layout.csv' then keyboard_rows
    when 'raw_tables.csv'      then raw_rows(all)
    end
  end

  # Records that are one text field: number, text. Blank ones are skipped
  # unless +all+ is true.
  def text_rows(id, offset, width, all = true)
    records(id).each_with_index.filter_map do |record, index|
      text = decode(record.byteslice(offset, width))
      [index + 1, text] unless !all && text.empty?
    end
  end

  # Department record (25 bytes): name 16, flags 4, 2 bytes, amount BCD 3.
  def department_rows
    records(Departments, 25).each_with_index.map do |record, index|
      [index + 1, decode(record.byteslice(0, 16)), hex(record.byteslice(16, 4)),
       bcd(record.byteslice(22, 3))]
    end
  end

  # Function and payment keys (22 bytes): code BCD 2, name 12, flags 4, 4 zero.
  def function_rows(all)
    records(Functions, 22).each_with_index.filter_map do |record, index|
      name = decode(record.byteslice(2, 12))
      next if name.empty? && !all
      [index + 1, bcd(record.byteslice(0, 2)), name, hex(record.byteslice(14, 4))]
    end
  end

  # Staff (15 bytes): name 12, number BCD 2, 1 zero.
  def staff_rows
    records(Staff, 15).each_with_index.map do |record, index|
      [index + 1, decode(record.byteslice(0, 12)), bcd(record.byteslice(12, 2))]
    end
  end

  # Hourly slots (4 bytes): start hour and end hour, each a BCD byte
  # followed by a zero byte.
  def hour_rows
    records(Hours, 4).each_with_index.map do |record, index|
      [index + 1, format('%02d:00', bcd(record.byteslice(0, 1))),
       format('%02d:00', bcd(record.byteslice(2, 1)))]
    end
  end

  # Tax rates (8 bytes) of both sets: rate BCD 3 (four decimals), 3 bytes,
  # 1 byte, 1 byte.
  def tax_rows
    { 1 => TaxRates, 2 => TaxRates2 }.flat_map do |set, id|
      records(id, 8).each_with_index.map do |record, index|
        [set, index + 1, format('%.2f', bcd(record.byteslice(0, 3)) / 10_000.0),
         hex(record.byteslice(3, 3)), hex(record.byteslice(6, 1)), hex(record.byteslice(7, 1))]
      end
    end
  end

  # Keyboard layout (12 bytes): three cells of number BCD 3 and a kind byte,
  # one cell for each shift level.
  def keyboard_rows
    records(Keyboard, 12).each_with_index.flat_map do |record, index|
      (0..2).filter_map do |level|
        cell   = record.byteslice(level * 4, 4)
        number = bcd(cell.byteslice(0, 3))
        kind   = cell.getbyte(3)
        next if kind == 0 && number == 0
        [index + 1, level + 1, kind, KEY_KINDS.fetch(kind, 'Unknown'), number]
      end
    end
  end

  # Tables that are not decoded: record as hex and as text.
  def raw_rows(all)
    RAW_TABLES.flat_map do |id|
      next [] unless tables[id]
      tables[id].each_with_index.filter_map do |record, index|
        next if !all && zeros?(record)
        [id, index + 1, hex(record).scan(/../).join(' '),
         decode(record).gsub(/[[:cntrl:]�]/, '.')]
      end
    end
  end

end
