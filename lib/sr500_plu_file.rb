require 'csv'
require 'sr500_settings_file'

# A class for reading the PLU settings of Casio SR-500 POS register from
# its settings file (AUTOPGM/FILE092P.092). See SR500SettingsFile for the
# file structure and FILE092P_092.md for the format.
#
# Table 4 holds PLU records, table 5 holds department records. Text is
# Shift-JIS, padded with spaces. Prices are BCD.
class SR500PluFile < SR500SettingsFile

  PLU_TABLE        = 4
  DEPARTMENT_TABLE = 5

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

  # PLU records. Unused slots (no name or the default "PLUnnnn" name, and
  # nothing else set) are skipped unless +all+ is true.
  def plus(all: false)
    list = records(PLU_TABLE, PLU_RECORD_SIZE).each_with_index.map do |record, index|
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
    records(DEPARTMENT_TABLE, DEPT_RECORD_SIZE).each_with_index.to_h do |record, index|
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

  def unused?(plu)
    default_name = plu.name.empty? || plu.name == format('PLU%04d', plu.number)
    default_name && plu.price == 0 && plu.department == 0 && plu.flags.delete('0').empty?
  end

end
