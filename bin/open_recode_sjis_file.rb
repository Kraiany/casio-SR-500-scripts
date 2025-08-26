#!/usr/bin/env ruby

$: << File.expand_path('../../lib', __FILE__)

require 'optparse'
require 'date'
require 'csv'
require 'pathname'
require 'jp_encoding_file'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{$PROGRAM_NAME} [options] <path_with_wildcard>"


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

matching_files.each do |sjis_file_path|
  JPEncodingFile.new(sjis_file_path)
  puts "Конвертовано в UTF-8 файл: #{sjis_file_path}"
end
