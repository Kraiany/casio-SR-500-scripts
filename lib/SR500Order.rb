require 'pry'

class SR500Order
  attr_accessor :timestamp
  attr_accessor :sequence
  attr_accessor :taxableamount
  attr_accessor :taxincluded
  attr_accessor :totalamountdue
  attr_accessor :amountreceived
  attr_accessor :amountreturned
  attr_accessor :items

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
