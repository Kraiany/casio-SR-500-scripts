require 'debug'
require 'csv'
require 'sr500constants'

class SR500Order

  include SR500Constants

  attr_accessor :timestamp
  attr_accessor :sequence
  attr_accessor :taxableamount
  attr_accessor :taxincluded
  attr_accessor :totalamountdue
  attr_accessor :amountreceived
  attr_accessor :amountreturned
  attr_accessor :items
  attr_accessor :tax_percent
  attr_accessor :tax_amount
  attr_accessor :cash

  def initialize(order)
    return unless order[:timestamp]

    @timestamp      = order.delete :timestamp
    @sequence       = order.delete :number

    @tax_percent    = order[:tax][:percent]
    @tax_amount     = order[:tax][:amount]
    order.delete :tax

    @taxableamount  = order.delete :taxableamount
    @taxincluded    = order.delete :taxincluded
    @totalamountdue = order.delete :totalamountdue
    @amountreceived = order.delete :amountreceived
    @amountreturned = order.delete :amountreturned
    @cash           = order.delete :cash

    @items = []
    order[:items].each do |item|
      @items.push SR500OrderItem.new(
                    item[:product],
                    item[:price],
                    @timestamp,
                    @sequence
                  )
    end
  end

  def self.csv_header

    [ HEADERS[:timestamp],      HEADERS[:sequence],
      HEADERS[:items],          HEADERS[:tax_percent],
      HEADERS[:tax_amount],     HEADERS[:taxableamount],
      HEADERS[:taxincluded],
      HEADERS[:amountreceived],
      HEADERS[:cash],
      HEADERS[:amountreturned]
    ].to_csv
  end

  def to_csv(header: false)
    csv = ''
    # # debugger
    csv = SR500Order.csv_header if header

    items_str = items.map(&:to_s).join(', ')
    csv << [timestamp,
            sequence,
            items_str,
            tax_percent,
            tax_amount,
            taxableamount,
            taxincluded,
            amountreceived,
            cash,
            amountreturned
           ].to_csv
  end
end

class SR500OrderItem
  attr_accessor :product
  attr_accessor :price
  attr_accessor :timestamp
  attr_accessor :order_sequence

  def initialize(product,price,timestamp,sequence)
    @product        = product
    @price          = price
    @timestamp      = timestamp
    @order_sequence = sequence
  end

  def to_s
    "#{product} (#{price})"
  end
end
