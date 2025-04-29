#!/usr/bin/env ruby

$: << "#{File.dirname(__FILE__)}/../lib"

require 'optparse'
require 'date'
require 'csv'
require 'pathname'
require 'sr500monthlyreceipts'


options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{$PROGRAM_NAME} [options] <path_with_wildcard>"

  opts.on("-o", "--output FILE", "Шлях до вихідного CSV файлу") do |file|
    options[:output] = file
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

output_file = options[:output]
if output_file.nil?
  puts "Потрібно вказати шлях до вихідного файлу за допомогою опції -o або --output."
  exit 1
end

monthly_receipts = SR500MonthlyReceipts.new(matching_files)
monthly_receipts.readlines
monthly_receipts.parse
csv = monthly_receipts.to_csv

File.open(output_file,"w:UTF-8") do |f|
  f.write csv
end

File.open(output_file + "items.csv","w:UTF-8") do |f|
  f.write Items.to_csv
end

puts "Звіти об'єднано у файл: #{output_file}"
