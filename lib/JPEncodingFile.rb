require 'fileutils'
require 'open3'

# A class for decoding Shift-JIS files into UTF-8, using uchardet for charset detection.
class JPEncodingFile
  # The path to the input file.
  attr_accessor :filepath
  # The encoding of the file (detected by uchardet).
  attr_reader :encoding
  # The directory where converted files will be saved if not converting in place.
  attr_accessor :output_dir
  # A boolean indicating whether to convert the file in place (overwriting the original).
  attr_accessor :inplace

  # Initializes a new JPEncodingFile object.
  #
  # @param filepath [String] The path to the input file.
  # @param inplace [Boolean] Whether to convert the file in place. Default is false.
  # @param output_dir [String] The directory for converted files if not converting in place.
  def initialize(filepath, inplace: false, output_dir: nil)
    @filepath = filepath
    @encoding = nil
    @inplace = inplace
    @output_dir = output_dir
    @uchardet_available = nil # Will be set in check_uchardet
    check_uchardet
  end

  # Checks if the uchardet utility is installed.
  #
  # @return [Boolean] True if uchardet is installed, false otherwise.
  def check_uchardet
    @uchardet_available = system('which uchardet > /dev/null 2>&1')
    raise "UchardetNotInstalledError" unless @uchardet_available
    @uchardet_available
  end

  # Opens the file, detects its encoding, and converts it to UTF-8 if necessary.
  #
  # If inplace is true, the original file is overwritten.  Otherwise, a new file
  # is created in the output directory.
  #
  # @return [String, nil] The path to the UTF-8 encoded file, or nil on error.
  def open
    return nil unless @uchardet_available
    return nil unless File.exist?(@filepath)

    raise ArgumentError, "output_dir must be specified when inplace is false" \
      if !@inplace and !@output_dir

    # Use uchardet to detect encoding
    encoding, _, status = Open3.capture3('uchardet', @filepath)
    @encoding = encoding.strip

    raise "uchardetFailedToDetectError",
          "Error: uchardet failed to detect encoding for #{@filepath}" unless status.success?

    if @encoding == 'SHIFT_JIS' || @encoding == 'ISO-2022-JP'
      begin
        content = File.read(@filepath, encoding: @encoding)
        utf8_content = content.encode('UTF-8', @encoding).
                         tr!('０１２３４５６７８９','0123456789').
                         tr!('\\','￥')

        output_filename = @inplace ?
                            @filepath :
                            File.join(@output_dir, File.basename(@filepath))

        File.open(output_filename, 'w:UTF-8') do |f|
          f.write(utf8_content)
        end

        # puts "Converted #{@filepath} (from #{@encoding}) to UTF-8"
        # + " and saved to #{output_filename}" if !@inplace

        return output_filename

      rescue StandardError => e
        puts "Error converting #{@filepath}: #{e.message}"
        return nil
      end
    elsif @encoding == 'UTF-8'
      # puts "#{@filepath} is already UTF-8."
      return @filepath
    else
      puts "Warning: Unsupported encoding #{@encoding} for #{@filepath}.  File not converted."
      return @filepath
    end
  end
end

if __FILE__ == $0
  # Create a dummy Shift-JIS file for testing
  sjis_file_path = 'sjis_test.txt'
  File.open(sjis_file_path, 'w:Shift_JIS') do |f|
    f.write "これはShift-JISのテストファイルです。\n"
    f.write "こんにちは、世界！\n"
  end

  # Create a dummy UTF-8 file for testing
  utf8_file_path = 'utf8_test.txt'
  File.open(utf8_file_path, 'w:UTF-8') do |f|
    f.write "This is a UTF-8 test file.\n"
    f.write "こんにちは、世界！\n"
  end

  # Test in-place conversion
  puts "\n--- Testing in-place conversion ---"
  converter = JPEncodingFile.new(sjis_file_path, inplace: true)
  output_file_path = converter.open
  if output_file_path
    puts "Converted file: #{output_file_path}"
    puts "Encoding: #{converter.encoding}"
  else
    puts "Conversion failed."
  end

  # Test conversion to output directory
  puts "\n--- Testing conversion to output directory ---"
  output_dir = 'output_files'
  FileUtils.mkdir_p(output_dir) unless Dir.exist?(output_dir)
  converter = JPEncodingFile.new(sjis_file_path, inplace: false, output_dir: output_dir)
  output_file_path = converter.open
  if output_file_path
    puts "Converted file: #{output_file_path}"
    puts "Encoding: #{converter.encoding}"
  else
    puts "Conversion failed."
  end

  # Test with a UTF-8 file
  puts "\n--- Testing with a UTF-8 file ---"
  converter = JPEncodingFile.new(utf8_file_path, inplace: true)
  output_file_path = converter.open
  if output_file_path
    puts "Converted file: #{output_file_path}"
    puts "Encoding: #{converter.encoding}"
  else
    puts "Conversion failed."
  end

  # Test with missing uchardet
  puts "\n--- Testing with missing uchardet ---"
  # Temporarily rename uchardet to simulate it being missing
  begin
    old_path = '/usr/local/bin/uchardet' # Common path, adjust as needed for your system
    if File.exist?(old_path)
      File.rename(old_path, '/tmp/uchardet_temp')
      converter = JPEncodingFile.new(sjis_file_path, inplace: true)
      output_file_path = converter.open
      if converter.uchardet_available
        puts "uchardet is available"
      else
        puts "uchardet is not available"
      end
    else
      puts "uchardet not found in /usr/local/bin/ , test skipped"
    end
  ensure
    # Rename uchardet back to its original name
    if File.exist?('/tmp/uchardet_temp')
      File.rename('/tmp/uchardet_temp', old_path)
    end
  end
end
