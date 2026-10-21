#!/usr/bin/env ruby

$: << File.expand_path('../../lib', __FILE__)

require 'optparse'
require 'sr500_plu_file'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{$PROGRAM_NAME} [options] <path to FILE092P.092>"

  opts.on("-d", "--dir DIR", "Каталог для вихідних CSV файлів") do |dir|
    options[:dir] = dir
  end

  opts.on("-a", "--all", "Включити порожні записи та невикористані PLU") do
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

if options[:dir].nil?
  puts "Потрібно вказати каталог для вихідних файлів за допомогою опції -d або --dir."
  exit 1
end

settings = SR500PluFile.new(path)

rows = { 'plu.csv' => nil }.merge(settings.write(options[:dir], all: options[:all]))
plu  = settings.to_csv(all: options[:all])
File.write(File.join(options[:dir], 'plu.csv'), plu, encoding: 'UTF-8')
rows['plu.csv'] = plu.lines.size - 1

rows.each do |name, count|
  puts "#{File.join(options[:dir], name)}: #{count}"
end
