require 'fileutils'
require 'open3'
require 'pry'

# A class for decoding Shift-JIS files into UTF-8, using uchardet for charset detection.
class JPEncodingFile < File
  # The path to the input file.
  attr_accessor :path
  # The encoding of the file (detected by uchardet).
  attr_reader :encoding
  # The directory where converted files will be saved if not converting in place.
  # attr_accessor :output_dir
  # # A boolean indicating whether to convert the file in place (overwriting the original).
  # attr_accessor :inplace

  # Initializes a new JPEncodingFile object.
  #
  # @param path [String] The path to the input file.
  # @param inplace [Boolean] Whether to convert the file in place. Default is false.
  # @param output_dir [String] The directory for converted files if not converting in place.
  def initialize(path)
    @path = path
    @encoding = nil
    @uchardet_available = check_uchardet
    get_encoding
    recode_file
    super(path,'r')
  end

  # Checks if the uchardet utility is installed.
  #
  # @return [Boolean] True if uchardet is installed, false otherwise.
  def check_uchardet
    @uchardet_available = system('which uchardet > /dev/null 2>&1')
    raise "UchardetNotInstalledError" unless @uchardet_available
    @uchardet_available
  end

  # Use uchardet to detect encoding
  def get_encoding
    encoding, _, status = Open3.capture3('uchardet', @path)
    @encoding = encoding.strip

    raise "uchardetFailedToDetectError",
          "Error: uchardet failed to detect encoding for #{@path}" unless status.success?
  end

  def recode_file
    return if @encoding == 'UTF-8'
    if @encoding == 'SHIFT_JIS' || @encoding == 'ISO-2022-JP'
      begin
        content = File.read(@path, encoding: @encoding)
        utf8_content = content.encode('UTF-8', @encoding).
                         tr!('０１２３４５６７８９','0123456789').
                         tr!('\\','￥').
                         tr!('，',',')

        File.open(@path, 'w:UTF-8') do |f|
          f.write(utf8_content)
          f.close
        end
        @encoding = 'UTF-8'
      rescue StandardError => e
        puts "Error converting #{@path}: #{e.message}"
        return nil
      end
    end
  end

end

# if __FILE__ == $0
#   # Create a dummy Shift-JIS file for testing
#   sjis_file_path = 'sjis_test.txt'
#   File.open(sjis_file_path, 'w:Shift_JIS') do |f|
#     f.write "これはShift-JISのテストファイルです。\n"
#     f.write "こんにちは、世界！\n"
#   end

#   # Create a dummy UTF-8 file for testing
#   utf8_file_path = 'utf8_test.txt'
#   File.open(utf8_file_path, 'w:UTF-8') do |f|
#     f.write "This is a UTF-8 test file.\n"
#     f.write "こんにちは、世界！\n"
#   end

#   # Test in-place conversion
#   puts "\n--- Testing in-place conversion ---"
#   converter = JPEncodingFile.new(sjis_file_path)

#   if output_file_path
#     puts "Converted file: #{output_file_path}"
#     puts "Encoding: #{converter.encoding}"
#   else
#     puts "Conversion failed."
#   end

#   # Test with a UTF-8 file
#   puts "\n--- Testing with a UTF-8 file ---"
#   converter = JPEncodingFile.new(utf8_file_path)
#   output_file_path = converter.open
#   if output_file_path
#     puts "Converted file: #{output_file_path}"
#     puts "Encoding: #{converter.encoding}"
#   else
#     puts "Conversion failed."
#   end

#   # Test with missing uchardet
#   puts "\n--- Testing with missing uchardet ---"
#   # Temporarily rename uchardet to simulate it being missing
#   begin
#     old_path = '/usr/local/bin/uchardet' # Common path, adjust as needed for your system
#     if File.exist?(old_path)
#       File.rename(old_path, '/tmp/uchardet_temp')
#       converter = JPEncodingFile.new(sjis_file_path, inplace: true)
#       output_file_path = converter.open
#       if converter.uchardet_available
#         puts "uchardet is available"
#       else
#         puts "uchardet is not available"
#       end
#     else
#       puts "uchardet not found in /usr/local/bin/ , test skipped"
#     end
#   ensure
#     # Rename uchardet back to its original name
#     if File.exist?('/tmp/uchardet_temp')
#       File.rename('/tmp/uchardet_temp', old_path)
#     end
#   end
# end
