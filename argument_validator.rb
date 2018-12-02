# frozen_string_literal: true

require 'sysexits'

# Provides methods for validating that input consists of exactly one file.
class ArgumentValidator
  def initialize(usage, expected_args)
    @usage = usage
    @expected_args = expected_args
  end

  def check_number_of_arguments(args)
    return if args.length == @expected_args

    puts @usage
    Sysexits.exit(:usage)
  end

  def check_file_exists(filename)
    return if File.exist?(filename)

    puts "File not found: #{filename}"
    puts
    puts @usage
    Sysexits.exit(:input_missing)
  end
end
