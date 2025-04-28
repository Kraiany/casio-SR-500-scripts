require 'sr500receiptfile'

class SR500MonthlyReceipts

  attr_accessor :paths
  attr_accessor :receipts

  # Take multiple file paths
  def initialize(paths)
    @paths = paths
    @receipts = []
    paths.each do |path|
      @receipts.push SR500RecipeFile.new(path)
    end
  end

  def readlines
    receipts.each do |receipt|
      receipt.readlines
    end
  end

  def parse
    receipts.each do |receipt|
      receipt.parse
    end
  end

  def to_csv
    csv = ''
    receipts.each_index do |index|
      if index == 0
        csv << receipts[index].to_csv(header: true)
      else
        csv << receipts[index].to_csv(header: false)
      end
    end
    csv
  end

  alias to_s to_csv

end
