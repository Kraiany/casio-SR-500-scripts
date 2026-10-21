#!/usr/bin/env ruby

$: << File.expand_path('../../lib', __FILE__)

require 'optparse'
require 'sr500_report_set'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{$PROGRAM_NAME} [options] <path_with_wildcard>"

  opts.on("-d", "--dir DIR", "Каталог для вихідних CSV файлів") do |dir|
    options[:dir] = dir
  end

  opts.on("-a", "--all", "Включити рядки з нульовими значеннями (платежі, відділи, PLU)") do
    options[:all] = true
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

matching_files = Dir.glob(ARGV.first)

if matching_files.empty?
  puts "Не знайдено файлів за шаблоном: #{ARGV.first}"
  exit 1
end

if options[:dir].nil?
  puts "Потрібно вказати каталог для вихідних файлів за допомогою опції -d або --dir."
  exit 1
end

report_set = SR500ReportSet.new(matching_files)

unless report_set.skipped.empty?
  puts "Пропущено файлів, які не є звітами: #{report_set.skipped.size}"
end
report_set.conflicts.each do |known, other|
  puts "Різний вміст однакового звіту: #{known} та #{other}"
end

report_set.write(options[:dir], all: options[:all]).each do |name, rows|
  puts "#{File.join(options[:dir], name)}: #{rows}"
end
