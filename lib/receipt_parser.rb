require_relative 'SR500Constants'

class ReceiptParser
  include SR500Constants

  def initialize(receipt_text)
    @receipt_text = receipt_text
    @lines = receipt_text.strip.split("\n")
  end

  def parse
    {
      date_time: parse_date_time,
      receipt_number: parse_receipt_number,
      items: parse_items,
      corrections: parse_corrections,
      returns: parse_returns,
      subtotal: parse_subtotal,
      tax: parse_tax,
      total: parse_total,
      payments: parse_payments,
      change: parse_change
    }
  end

  private

  def parse_date_time
    date_str = @lines[0].strip
    Time.parse(date_str)
  end

  def parse_receipt_number
    @lines[1].strip
  end

  def parse_items
    items = []
    current_line = 2

    while current_line < @lines.length
      line = @lines[current_line].strip
      
      # Break conditions using constants
      break if line.include?(TaxableAmount) ||     # '対象計'
               line.include?(TotalAmountDue) ||    # '合  計'
               line.include?(AmountReturned) ||    # 'お  釣'
               line.include?(Cancellation) ||      # '訂正'
               line.include?(Cash) ||             # '現金'
               line.include?(AmountReceived)       # 'お預り'

      if line.include?('￥')
        name, price = line.split('￥')
        items << {
          name: name.strip,
          price: parse_price(price),
          type: 'sale'
        }
      end
      current_line += 1
    end

    items
  end

  def parse_corrections
    corrections = []
    current_line = 0

    while current_line < @lines.length
      line = @lines[current_line].strip
      
      if line.include?(Cancellation)  # '訂正'
        amount = line.split('￥').last.strip
        corrections << {
          amount: parse_price(amount),
          type: 'correction'
        }
      end
      current_line += 1
    end

    corrections
  end

  def parse_returns
    returns = []
    current_line = 0

    while current_line < @lines.length
      line = @lines[current_line].strip
      
      if line.include?(OrderCancellation)  # '取引中止'
        return_line = @lines[current_line + 1]
        if return_line
          name, price = return_line.split('-')
          returns << {
            name: name.strip,
            price: parse_price(price),
            type: 'return'
          }
        end
      end
      current_line += 1
    end

    returns
  end

  def parse_subtotal
    subtotal_line = @lines.find { |line| line.include?(TaxableAmount) }  # '対象計'
    return 0 unless subtotal_line

    if subtotal_line.include?('￥')
      price_str = subtotal_line.split('￥').last.strip
    else
      next_line = @lines[@lines.index(subtotal_line) + 1]
      price_str = next_line.split('￥').last.strip if next_line
    end

    parse_price(price_str)
  end

  def parse_tax
    tax_line = @lines.find { |line| line.include?(TaxIncluded) }  # '内税'
    return 0 unless tax_line

    price_str = tax_line.split('￥').last.strip
    parse_price(price_str)
  end

  def parse_total
    total_line = @lines.find { |line| line.include?(TotalAmountDue) }  # '合  計'
    return 0 unless total_line

    price_str = total_line.split('￥').last.strip
    parse_price(price_str)
  end

  def parse_payments
    payments = []
    current_line = 0

    while current_line < @lines.length
      line = @lines[current_line].strip
      
      if line.include?(Cash) || line.include?(AmountReceived)  # '現金' or 'お預り'
        method = line.split('￥').first.strip
        amount = line.split('￥').last.strip
        payments << {
          method: method,
          amount: parse_price(amount)
        }
      end
      current_line += 1
    end

    payments
  end

  def parse_change
    change_line = @lines.find { |line| line.include?(AmountReturned) }  # 'お  釣'
    return 0 unless change_line

    price_str = change_line.split('￥').last.strip
    parse_price(price_str)
  end

  def parse_price(price_str)
    is_negative = price_str.start_with?('-')
    numeric_str = price_str.gsub(/[^0-9]/, '')
    amount = numeric_str.to_i
    is_negative ? -amount : amount
  end
end 