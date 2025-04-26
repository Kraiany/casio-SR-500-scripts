# Format
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
require 'pry'

# A class for reading recepit files of Casi SR-500 POS register.
class SR500RecipeFile < JPEncodingFile

  # Constants
  TaxableAmount  = "対象計"
  TaxIncluded    = "内税"
  TotalAmountDue = "合  計"
  AmountReceived = "お預り"
  AmountReturned = "お  釣" # change


  attr_accessor :csv
  attr_accessor :lines
  attr_accessor :currency

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
    order = {  }
    order[:items] = []

    @lines.each do |l|
      l.strip!

      if l.match /^[\d]{4}-[\d]{2}-[\d]{2}\s+[\d]{2}:[\d]{2}$/
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
        value = $3.strip

        order[:tax] = { percent:  percent, amount: value}
        next
      end


      if /^(.+)\s+#{currency}([\d,]+)$/.match(l)
        key = $1.strip
        value = $2.strip

        case key
        when TaxableAmount
          order[:taxableamount] = value.to_f
          next
        when TaxIncluded
          order[:taxincluded] = value.to_f
          next
        when TotalAmountDue
          order[:totalamountdue] = value.to_f
          next
        when AmountReceived
          order[:amountreceived] = value.to_f
          next
        when AmountReturned
          order[:amountreturned] = value.to_f
          orders.push SR500Order.new(order) #  End of receipt
          next
        else
          order[:items].push({ product: key, price: value })
          next
        end
      end
    end
    orders.push SR500Order.new(order)
    # binding.pry
  end

end
