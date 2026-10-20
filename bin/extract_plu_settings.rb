#!/usr/bin/env ruby

$: << File.expand_path('../../lib', __FILE__)

require 'optparse'
require 'sr500_plu_file'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{$PROGRAM_NAME} [options] <path to FILE092P.092>"

  opts.on("-o", "--output FILE", "Шлях до вихідного CSV файлу (за замовчуванням stdout)") do |file|
    options[:output] = file
  end

  opts.on("-a", "--all", "Включити невикористані PLU (порожні та PLUnnnn)") do
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

path = ARGV.first
unless File.file?(path)
  puts "Файл не знайдено: #{path}"
  exit 1
end

csv = SR500PluFile.new(path).to_csv(all: options[:all])

if options[:output]
  File.write(options[:output], csv, encoding: 'UTF-8')
  puts "PLU записано у файл: #{options[:output]}"
else
  puts csv
end
