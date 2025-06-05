require 'jp_encoding_file'
require 'sr500_order'
require 'sr500_constants'
require 'debug'
require_relative 'receipt_parser'
require_relative 'sr500_order'

# A class for reading recepit files of Casi SR-500 POS register.
class SR500ReceiptFile < JPEncodingFile

  include SR500Constants

  def initialize(path, currency = Yen)
    @path     = path
    @csv      = nil
    @lines    = nil
    @currency = currency

    super(@path)
  end

  def readlines
    @lines = super
  end

  def parse
    @orders = []
    current_receipt_lines = []

    @lines.each_index do |index|
      line = @lines[index]
      # Skip empty lines
      line.strip!
      next if line.empty?

      next_line = @lines[index+1]

      if line.strip.match(Timestamp) && current_receipt_lines.any?
        process_current_receipt(current_receipt_lines, @orders)
        current_receipt_lines = []
        next
      end

      # End of file
      if next_line.nil?
        current_receipt_lines << line
        process_current_receipt(current_receipt_lines, @orders) if current_receipt_lines.any?
        current_receipt_lines = []
        return
      end

      if  next_line && next_line.strip.match(Timestamp)
        current_receipt_lines << line
        process_current_receipt(current_receipt_lines, @orders) if current_receipt_lines.any?
        current_receipt_lines = []
        next
      end

      # # Check for reset, cancellation, or receipt markers
      # if line.match(DrawerOpen)        || # ＃／替      ････････････'
      #    line.match(OrderCancellation) || # 取引中止
      #    line.match(Receipt)              # 領収書
      #   process_current_receipt(current_receipt_lines, @orders) if current_receipt_lines.any?
      #   current_receipt_lines = []
      #   next
      # end

      # Check for settlement line
      # if line.match(/^#{Settlement}\S+[\d]{4}-[\d]{2}-[\d]{2}\s+[\d]{2}:[\d]{2}$/) # 精算

      #   process_current_receipt(current_receipt_lines, @orders) if current_receipt_lines.any?
      #   current_receipt_lines = []
      #   next
      # end

      # Check for separator line
      if line.match(/^-{20,25}/)
        process_current_receipt(current_receipt_lines, @orders) if current_receipt_lines.any?
        current_receipt_lines = []
        return
      end

      # Add line to current receipt
      current_receipt_lines << line
    end

    # Process the last receipt if any
    process_current_receipt(current_receipt_lines, @orders) if current_receipt_lines.any?

    @orders
  end

  def to_csv(header: true)
    @csv = header ? SR500Order.csv_header : ''
    @csv << @orders.map(&:to_csv).join
  end
  alias to_s to_csv

  private

  def process_current_receipt(receipt_lines, orders)
    return if receipt_lines.empty?

    return if receipt_lines.length < 3

    # Don't include Z report
    return if receipt_lines[2].include?(DailyReport) # 日計明細

    # Join the receipt lines with newlines
    receipt_text = receipt_lines.join("\n")

    # Parse the receipt using the new ReceiptParser
    parser = ReceiptParser.new(receipt_text)
    parsed_data = parser.parse

    # Convert parsed data to SR500Order format
    unless parsed_data.nil?             ||
           parsed_data[:date_time].nil? ||
           parsed_data[:items].empty?   ||
           parsed_data[:tax] == 0

      order = {
        timestamp:      parsed_data[:date_time].strftime("%Y-%m-%d %H:%M"),
        date:           parsed_data[:date_time].strftime("%Y-%m-%d"),
        time:           parsed_data[:date_time].strftime("%H:%M"),
        hour:           parsed_data[:date_time].strftime("%H"),
        epoch:          parsed_data[:date_time].to_i,
        number:         parsed_data[:receipt_number].to_i,
        items:          parsed_data[:items],
        corrections:    parsed_data[:corrections],
        returns:        parsed_data[:returns],
        totalamountdue: parsed_data[:totalamountdue],
        payments:       parsed_data[:payments],
        change:         parsed_data[:change],
        tax_amount:     parsed_data[:tax_amount],
        tax_percent:    parsed_data[:tax_percent],
        taxincluded:    parsed_data[:tax_amount],
        subtotal:       parsed_data[:subtotal],
        amountreceived: parsed_data[:amountreceived],
        cash:           parsed_data[:cash],
        taxableamount:  format_taxable_amount(parsed_data[:subtotal], parsed_data[:tax_percent]),
      }
#debugger
      drop_corrections parsed_data # Remove cancellations together
                                   # wich cancelled items from order

      orders << SR500Order.new(order)

    end
  end

  def format_taxable_amount(subtotal, tax_percent)
    return nil unless subtotal
    "(#{tax_percent}%) #{subtotal}"
  end

  def drop_corrections(parsed_data)
    return if parsed_data[:corrections].empty?
    parsed_data[:corrections].each do |c|
      idx = parsed_data[:items].find_index { |x| x[:price] == c[:amount] }
      next if idx.nil?
      parsed_data[:items].delete_at idx
    end
  end

end

__END__

# Example usage:
receipt_text = <<~RECEIPT
      2025-04-01 14:24
                  000004
Coffee/Te         ￥550
対象計      10.0%   ￥550
内税                 ￥50
合  計          ￥550
お預り          ￥550
お  釣              ￥0
RECEIPT

parser = ReceiptParser.new(receipt_text)
result = parser.parse
