require_relative 'sr500_constants'

class ReceiptParser
  include SR500Constants

  def initialize(receipt_text)
    @receipt_text = receipt_text
    @lines = receipt_text.strip.split("\n")
  end

  def parse
    subtotal = parse_subtotal
    return if subtotal[:amount] == 0

    {
      date_time:      parse_date_time,
      receipt_number: parse_receipt_number,
      items:          parse_items,
      corrections:    parse_corrections,
      returns:        parse_returns,
      subtotal:       subtotal[:amount],
      tax_amount:     parse_tax,
      tax_percent:    subtotal[:percent],
      totalamountdue: parse_total,
      payments:       parse_payments,
      change:         parse_change,
      amountreceived: parse_received,
      cash:           parse_cash
    }
  end

  private

  def parse_cash
    line = @lines.find { |line| line.include?(Cash) }  # 現金
    return nil if line.nil?
    if line.include?(Yen)
      name, price = line.split(Yen)
    end
    parse_price price
  end

  def parse_date_time
    date_str = @lines[0].strip
    date_str = date_str.gsub(/\s+/, ' ')
    date_str = "#{date_str}:00"
    return nil unless date_str =~ /^\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}$/

    Time.parse(date_str)
  end

  def parse_received
    line = @lines.find { |line| line.include?(AmountReceived) }  # お預り
    return nil if line.nil?
    if line.include?(Yen)
      name, price = line.split(Yen)
    end
    parse_price price
  end

  def parse_receipt_number
    return nil if @lines[1].nil?
    return nil unless @lines[1] =~ /^\d{6}$/
    @lines[1].strip
  end

  def parse_items
    items = []
    current_line = 2

    while current_line < @lines.length
#debugger
      line = @lines[current_line].strip

      # Break conditions using constants - these go after all PLU items
      break if line.include?(TaxableAmount)     || #対象計
               line.include?(TaxIncluded)       || #内税
               line.include?(TotalAmountDue)    || #合  計
               line.include?(AmountReceived)    || #お預り
               line.include?(Change)            || #お  釣
               line.include?(Cash)              || #現金
               line.include?(DrawerOpen)        || #＃／替
               line.include?(OrderCancellation) || #取引中止
               line.include?(Settlement)        || #精算
               line.include?(Receipt)           || #領収書
               line.include?(DailyReport)          #日計明細

      # Skip this line
      if line.include?(Cancellation)      || #訂正
         line.include?(SharpSlashKae)     || #＃／替
         line.include?(Return)               #戻
        current_line += 1
        next
      end

      if line.include?(Yen)
        name, price = line.split(Yen)
        items << {
          name: name.strip,
          price: parse_price(price),
          type: 'sale'
        }
        current_line += 1
      else
        next_line = @lines[current_line+1]

        if next_line.include?(Cancellation)      || #訂正
           next_line.include?(SharpSlashKae)     || #＃／替
           next_line.include?(Return)               #戻
          current_line += 1
        else
          if next_line.include?(Yen)
            line = "#{@lines[current_line]} #{next_line}"
            name, price = line.split(Yen)
            debugger if price.nil?
            items << {
              name: name.strip,
              price: parse_price(price),
              type: 'sale'
            }
            current_line += 2
          end
        end
      end
    end

    items
  end

  def parse_corrections
    corrections = []
    current_line = 0

    while current_line < @lines.length
      line = @lines[current_line].strip

      if line.include?(Cancellation)  # '訂正'
        amount = line.split(/[-￥]/).last.strip
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
      elsif line.include?('戻')  # '戻' marker
        # Get the next line which contains the return amount
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
    return { percent: 0, amount: 0 } unless subtotal_line

    if subtotal_line.include?(Yen) && subtotal_line.include?('%')
      _, percent_str, price_str = subtotal_line.split
    else
      next_line = @lines[@lines.index(subtotal_line) + 1]
      _, percent_str, price_str = "#{subtotal_line} #{next_line}".split
    end

    { percent: parse_percent(percent_str), amount: parse_price( price_str) }
  end

  def parse_tax
    tax_line = @lines.find { |line| line.include?(TaxIncluded) }  # '内税'
    return 0 unless tax_line

    price_str = tax_line.split(Yen).last.strip
    parse_price(price_str)
  end

  def parse_total
    total_line = @lines.find { |line| line.include?(TotalAmountDue) }  # '合  計'
    return 0 unless total_line

    price_str = total_line.split(Yen).last.strip
    parse_price(price_str)
  end

  def parse_payments
    payments = []
    current_line = 0
    while current_line < @lines.length
      line = @lines[current_line].strip

      if line.include?(Cash) || line.include?(AmountReceived)  # '現金' or 'お預り'
        method = line.split(Yen).first.strip
        amount = line.split(Yen).last.strip

        # Check if this payment is followed by a correction
        next_line = @lines[current_line + 1]
        if next_line && next_line.include?(Cancellation)  # '訂正'
          correction_amount = next_line.split(/[￥-]/).last.strip
          payments << {
            method: method,
            amount: parse_price(amount),
            correction: parse_price(correction_amount),
            type: 'payment_with_correction'
          }
        else
          payments << {
            method: method,
            amount: parse_price(amount),
            type: 'payment'
          }
        end
      end
      current_line += 1
    end

    payments
  end

  def parse_change
    change_line = @lines.find { |line| line.include?(Change) }  # 'お  釣'
    return 0 unless change_line

    price_str = change_line.split(Yen).last.strip
    parse_price(price_str)
  end

  def parse_percent(percent_str)
    numeric_str = percent_str.gsub(/[^0-9\.]/, '')
    amount = numeric_str.to_f
  end

  def parse_price(price_str)
    is_negative = price_str.start_with?('-')
    numeric_str = price_str.gsub(/[^0-9]/, '')
    amount = numeric_str.to_i
    is_negative ? -amount : amount
  end
end
