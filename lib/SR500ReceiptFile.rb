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

# A class for reading recepit files of Casi SR-500 POS register.
class SR500RecipeFile < JPEncodingFile

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
    order = new_order
    partial_line = nil

    @lines.each do |l|
      l.strip!

      if partial_line
        l = "#{partial_line}    #{l}"
        partial_line = nil
      end

      if l.match Reset
        order = new_order
        next
      end

      if l.match OrderCancellation
        order = new_order
        next
      end

      if l.match Receipt
        order = new_order
        next
      end

      # Settlement or X/Z report line
      # 精算 2025-03-23 17:55
      # ----------------------
      if l.match /^#{Settlement}\s+[\d]{4}-[\d]{2}-[\d]{2}\s+[\d]{2}:[\d]{2}$/
        orders.push SR500Order.new(order) if order[:timestamp]
        order = new_order
        next
      end

      if l.match /^-{20,25}/
        orders.push SR500Order.new(order) if order[:timestamp]
        order = new_order
        next
      end

      # Timestamp
      # ----------------------
      if l.match /^[\d]{4}-[\d]{2}-[\d]{2}\s+[\d]{2}:[\d]{2}$/ # Timestamp
        orders.push SR500Order.new(order) if order[:timestamp]
        order = new_order
        time = Time.new(l+":00")
        # debugger
        order[:timestamp] = time.strftime("%Y-%m-%d %H:%M")
        order[:date]      = time.strftime("%Y-%m-%d")
        order[:time]      = time.strftime("%H:%M")
        order[:hour]      = time.strftime("%H")
        order[:epoch]     = time.to_i
        next
      end

      if l.match /^000[\d]{3}$/ # Order number
        order[:number] = (l.to_i)
        next
      end

      # When percentage line is split into 2 lines
      # 対象計      10.0%
      #            ￥15,510
      if l.match /^(.+)\s+([\d\.]+)%\s*$/
        partial_line = l
       next
      end

      # Single line percentage, or after two consequtive lines joined
      #
      # 対象計      10.0% ￥1,100
      if l.match /^#{TaxableAmount}\s+([\d\.]+)%\s+#{currency}([\d,]+)$/
        # key = $1.strip
        percent = $1.strip
        value_str = $2.strip
        value = $2.strip.gsub(',','').to_i

        order[:tax] = { percent:  percent, amount: value}
        order[:taxableamount] = "(#{percent}%) #{value_str}"
        next
      end

      # 訂正
      if l.match /^#{Cancellation}\s+-([\d,]+)$/
        refund = $1.tr(',','').to_i
        if order[:items].last[:price] == refund
          order[:items].pop
        elsif order[:cash] == refund
          cash = order[:cash]
          order[:cash] = nil
        else
          debugger
          STDOUT.puts "Refund #{refund} differs from both last item price #{order[:items].last.to_s} and cash #{cash}"
          pp self
        end
        next
      end

      if /^(.+)\s+#{currency}([\d,]+)$/.match(l)
        key = $1.strip
        value = $2.strip.gsub(',','').to_i

        case key
        when TaxIncluded
          order[:taxincluded] = value.to_i
          next
        when TotalAmountDue
          order[:totalamountdue] = value.to_i
          next
        when AmountReceived
          order[:amountreceived] = value.to_i
          next
        when AmountReturned
          order[:amountreturned] = value.to_i
          # orders.push SR500Order.new(order) #  End of receipt
          next
        when Cash
          order[:cash] = value.to_i
          # orders.push SR500Order.new(order) #  End of receipt
          next
        else
          order[:items].push({ product: key, price: value })
          next
        end
      end
    end
    orders.push SR500Order.new(order) if order[:timestamp]
    @orders = orders
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
