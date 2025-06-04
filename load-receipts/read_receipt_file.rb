#!/usr/bin/env ruby
$:.push "#{File.dirname(__FILE__)}/../lib"

require 'debug'
require 'sr500receiptfile'

obj = SR500RecipeFile.new("./src2/EJ250405.TXT")
obj.readlines
obj.parse

#debugger
puts obj.to_csv
