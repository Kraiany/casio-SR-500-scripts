require 'debug'
require 'csv'
require 'sr500constants'

# Class Items is only used for collecting all items into class
# variable @@items and generating CSV for all items.
class Items
  @@items = []

  def self.items
    @@items
  end

 def items
    self.class.items
 end

 def self.to_csv
   csv = [:timestamp, :sequence, :product, :price].map(&:to_s).map(&:capitalize).to_csv
   @@items.each do |item|
     csv << [item.timestamp, item.order_sequence, item.product, item.price].to_csv
   end
   csv
 end
end

# Single receipt is parsed into single instance of class SR500Order.
class SR500Order


  include SR500Constants

   [ :timestamp, :date, :time, :hour, :sequence, :taxableamount, :taxincluded,
     :totalamountdue, :amountreceived, :amountreturned, :items,
     :tax_percent, :tax_amount, :cash
   ].each do |attr|
     attr_accessor attr
   end

  def initialize(order)
    return unless order[:timestamp]
    return if order[:items].size == 0

    @timestamp      = order.delete :timestamp
    @time           = order.delete :time
    @date           = order.delete :date
    @hour           = order.delete :hour
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

      i = SR500OrderItem.new(
        item[:product],
        item[:price],
        @timestamp,
        @sequence,
      )

      @items << i
      Items.items << i
    end
  end

  def self.csv_header

    [ HEADERS[:timestamp],
      HEADERS[:date], HEADERS[:time], HEADERS[:hour],
      HEADERS[:sequence],
      HEADERS[:items],          HEADERS[:tax_percent],
      HEADERS[:tax_amount],     HEADERS[:taxableamount],
      HEADERS[:taxincluded],
      HEADERS[:amountreceived],
      HEADERS[:cash],
      HEADERS[:amountreturned]
    ].to_csv
  end

  def to_csv(header: false)
    return unless timestamp
    csv = header ? SR500Order.csv_header : ''

    items_str = items.map(&:to_s).join(', ')
    csv << [timestamp,
            date,
            time,
            hour,
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

  alias to_s to_csv
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
    @time
    @order_sequence = sequence
  end

  def to_s
    "#{product} (#{price})"
  end
end
