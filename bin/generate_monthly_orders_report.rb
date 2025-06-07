#!/usr/bin/env ruby

$: << File.expand_path('../../lib', __FILE__)

require 'optparse'
require 'date'
require 'csv'
require 'pathname'
require 'sr500_monthly_receipts'


options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{$PROGRAM_NAME} [options] <path_with_wildcard>"

  opts.on("-o", "--orders FILE", "Шлях до вихідного CSV файлу чеків (orders)") do |file|
    options[:orders] = file
  end

  opts.on("-i", "--items FILE", "Шлях до вихідного CSV файлу проданих товарів (items)") do |file|
    options[:items] = file
  end

  opts.on("-h", "--help", "Вивести цю довідку") do
    puts opts
    exit
  end

  if ARGV.empty?
    puts opts
    exit 1
  end
end.parse!

file_path_with_wildcard = ARGV.first
matching_files = Dir.glob(file_path_with_wildcard)

if matching_files.empty?
  puts "Не знайдено файлів за шаблоном: #{file_path_with_wildcard}"
  exit 1
end

orders_file = options[:orders]
if orders_file.nil?
  puts "Потрібно вказати шлях до вихідного файлу чеків за допомогою опції -o або --orders."
  exit 1
end

items_file = options[:items]
if items_file.nil?
  puts "Потрібно вказати шлях до вихідного файлу товарів за допомогою опції -i або --items."
  exit 1
end

monthly_receipts = SR500MonthlyReceipts.new(matching_files)
monthly_receipts.readlines
monthly_receipts.parse

File.open(orders_file,"w:UTF-8") do |f|
  f.write monthly_receipts.to_csv
end

File.open(items_file,"w:UTF-8") do |f|
  f.write Items.to_csv
end

puts "Звіти записано у файли: #{orders_file} #{items_file}"
