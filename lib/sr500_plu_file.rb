require 'csv'

# A class for reading the PLU settings file of Casio SR-500 POS register
# (AUTOPGM/FILE092P.092).
#
# The file is a binary program dump. It starts with the text header
# "n:P0092:" and continues with tables. Each table starts with a 18 bytes
# header and is followed by `count` fixed-size records:
#
#   66 00 <table id> 01 00 <?> 00 00 00 <record size: u32 LE> 01 00 00 <count: u16 BE>
#
# Table 4 holds PLU records, table 5 holds department records. Text is
# Shift-JIS, padded with spaces. Prices are BCD.
class SR500PluFile

  MAGIC            = 'n:P0092:'.b
  PLU_TABLE        = 4
  DEPARTMENT_TABLE = 5

  HEADER_SIZE      = 18
  PLU_RECORD_SIZE  = 35
  DEPT_RECORD_SIZE = 25

  # PLU record layout (35 bytes):
  #   0..6   PLU code in BCD padded with 0xe nibbles. It equals the record
  #          number when set, and is zero for unassigned records.
  #   7..22  name, Shift-JIS, 16 bytes
  #   23..34 tail: bytes 0..4 flags (unknown meaning, 0x40 in byte 1 is
  #          set on some items), byte 5 department number, bytes 6..8
  #          price in BCD, byte 9 always zero, bytes 10..11 unknown (not
  #          exported)
  #
  # Department record layout (25 bytes): name (16 bytes), 9 bytes unused here.

  Plu = Struct.new(:number, :name, :price, :department, :flags, keyword_init: true)

  HEADERS = ['PLU', 'Name', 'Price', 'Department', 'Department Name', 'Flags'].freeze

  attr_reader :path

  def initialize(path)
    @path = path
    @data = File.binread(path)
    unless @data.start_with?(MAGIC)
      raise ArgumentError, "#{path}: not a PLU settings file (no #{MAGIC} header)"
    end
  end

  # PLU records. Unused slots (no name or the default "PLUnnnn" name, and
  # nothing else set) are skipped unless +all+ is true.
  def plus(all: false)
    list = table(PLU_TABLE, PLU_RECORD_SIZE).each_with_index.map do |record, index|
      number = index + 1
      tail   = record.byteslice(23, 12)
      Plu.new(
        number:     number,
        name:       decode(record.byteslice(7, 16)),
        price:      bcd(tail.byteslice(6, 3)),
        department: tail.getbyte(5),
        flags:      tail.byteslice(0, 5).unpack1('H*')
      )
    end
    all ? list : list.reject { |plu| unused?(plu) }
  end

  # Department names by department number (1-based).
  def departments
    table(DEPARTMENT_TABLE, DEPT_RECORD_SIZE).each_with_index.to_h do |record, index|
      [index + 1, decode(record.byteslice(0, 16))]
    end
  end

  def to_csv(all: false)
    names = departments
    CSV.generate do |csv|
      csv << HEADERS
      plus(all: all).each do |plu|
        csv << [plu.number, plu.name, plu.price, plu.department,
                names[plu.department], plu.flags]
      end
    end
  end
  alias to_s to_csv

  private

  # Returns the records of the table with the given id as binary strings.
  def table(id, record_size)
    prefix = [0x66, 0x00, id, 0x01, 0x00].pack('C*')
    pos = 0
    while (pos = @data.index(prefix, pos))
      size  = @data.byteslice(pos + 9, 4).unpack1('V')
      count = @data.byteslice(pos + 16, 2).unpack1('n')
      start = pos + HEADER_SIZE
      if size == record_size &&
         @data.byteslice(pos + 13, 3) == "\x01\x00\x00".b &&
         start + size * count <= @data.bytesize
        return Array.new(count) { |i| @data.byteslice(start + i * size, size) }
      end
      pos += 1
    end
    raise "#{path}: table #{id} with #{record_size} bytes records not found"
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

  def unused?(plu)
    default_name = plu.name.empty? || plu.name == format('PLU%04d', plu.number)
    default_name && plu.price == 0 && plu.department == 0 && plu.flags.delete('0').empty?
  end

end
