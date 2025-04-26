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

  # Start fresh
  def new_order
    return { items: [] }
  end

  def parse
    orders = []
    order = new_order

    @lines.each do |l|
      l.strip!

      if l.match Reset
        # debugger
        order = new_order
        next
      end

      if l.match /^[\d]{4}-[\d]{2}-[\d]{2}\s+[\d]{2}:[\d]{2}$/
        order = new_order
        order[:timestamp] = Time.new(l+":00")
        next
      end

      if l.match /^000[\d]{3}$/
        order[:number] = (l.to_i)
        next
      end

      if l.match /^(.+)\s+([\d\.]+)%\s+#{currency}([\d,]+)$/
        key = $1.strip
        percent = $2.strip
        value_str = $3.strip
        value = $3.strip.gsub(',','').to_i

        order[:tax] = { percent:  percent, amount: value}
        order[:taxableamount] = "(#{percent}%) #{value_str}"
        next
      end


      if /^(.+)\s+#{currency}([\d,]+)$/.match(l)
        key = $1.strip
        value = $2.strip.gsub(',','')

        case key
        # when TaxableAmount
        #   debugger
        #   order[:taxableamount] = value.to_i
        #   next
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
          orders.push SR500Order.new(order) #  End of receipt
          next
        when Cash
          order[:cash] = value.to_i
          orders.push SR500Order.new(order) #  End of receipt
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


end
