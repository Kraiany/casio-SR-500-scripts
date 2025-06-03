# Example gFormat
# -----------
# 対象計      10.0%   ￥550 - TaxAmmount
# 内税                 ￥50
# 合  計          ￥550
# お預り          ￥550 - Change
# お  釣              ￥0
#      2025-04-01 09:33
#                   000003
# ＃／替      ････････････
#      2025-04-01 14:24
#                   000004
# Coffee/Te         ￥550
# 対象計      10.0%   ￥550 - Total
# 内税                 ￥50 - Internal tax (???)
# 合  計          ￥550  - Total
# お預り          ￥550  - Deposit
# お  釣              ￥0 - Change
#      2025-04-01 15:32
#                   000005
# Coffee/Te         ￥550
# Pyrig             ￥550
# Pyrig             ￥550
# 対象計      10.0% ￥1,650
# 内税                ￥150
# 合  計      ￥1，650
# お預り      ￥2，000
# お  釣          ￥350

require 'jpencodingfile'
require 'sr500order'
require 'sr500constants'
require 'debug'
require_relative 'receipt_parser'
require_relative 'SR500Order'

# A class for reading recepit files of Casi SR-500 POS register.
class SR500ReceiptFile < JPEncodingFile

  include SR500Constants

  attr_accessor :csv
  attr_accessor :lines
  attr_accessor :currency
  attr_accessor :orders

  def initialize(path, currency = '￥')
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
    orders = []
    current_receipt_lines = []
    
    @lines.each do |line|
      line.strip!

      # Skip empty lines
      next if line.empty?

      # Check for reset, cancellation, or receipt markers
      if line.match(Reset) || line.match(OrderCancellation) || line.match(Receipt)
        process_current_receipt(current_receipt_lines, orders) if current_receipt_lines.any?
        current_receipt_lines = []
        next
      end

      # Check for settlement line
      if line.match(/^#{Settlement}\s+[\d]{4}-[\d]{2}-[\d]{2}\s+[\d]{2}:[\d]{2}$/)
        process_current_receipt(current_receipt_lines, orders) if current_receipt_lines.any?
        current_receipt_lines = []
        next
      end

      # Check for separator line
      if line.match(/^-{20,25}/)
        process_current_receipt(current_receipt_lines, orders) if current_receipt_lines.any?
        current_receipt_lines = []
        next
      end

      # Add line to current receipt
      current_receipt_lines << line
    end

    # Process the last receipt if any
    process_current_receipt(current_receipt_lines, orders) if current_receipt_lines.any?

    orders
  end

  private

  def process_current_receipt(receipt_lines, orders)
    return if receipt_lines.empty?

    # Join the receipt lines with newlines
    receipt_text = receipt_lines.join("\n")
    
    # Parse the receipt using the new ReceiptParser
    parser = ReceiptParser.new(receipt_text)
    parsed_data = parser.parse

    # Convert parsed data to SR500Order format
    order = {
      timestamp: parsed_data[:date_time].strftime("%Y-%m-%d %H:%M"),
      date: parsed_data[:date_time].strftime("%Y-%m-%d"),
      time: parsed_data[:date_time].strftime("%H:%M"),
      hour: parsed_data[:date_time].strftime("%H"),
      epoch: parsed_data[:date_time].to_i,
      number: parsed_data[:receipt_number].to_i,
      items: parsed_data[:items],
      corrections: parsed_data[:corrections],
      returns: parsed_data[:returns],
      taxableamount: format_taxable_amount(parsed_data[:subtotal], parsed_data[:tax]),
      tax: format_tax(parsed_data[:tax]),
      total: parsed_data[:total],
      payments: parsed_data[:payments],
      change: parsed_data[:change]
    }

    orders << SR500Order.new(order)
  end

  def format_taxable_amount(subtotal, tax)
    return nil unless subtotal && tax
    tax_percent = ((tax.to_f / subtotal) * 100).round(1)
    "(#{tax_percent}%) #{subtotal}"
  end

  def format_tax(tax_amount)
    return nil unless tax_amount
    { percent: ((tax_amount.to_f / (tax_amount + tax_amount)) * 100).round(1), amount: tax_amount }
  end

  def to_csv(header: true)
    csv = header ? SR500Order.csv_header : ''
    csv << orders.map(&:to_csv).join
  end
  alias to_s to_csv

  private

    # Start fresh
  def new_order
    return { items: [] }
  end

end

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
