#!/usr/bin/env ruby
# frozen_string_literal: true

require 'sysexits'

# FileSummer: Provides methods for reading a file and then summing its contents.
class FileSummer
  def self.usage
    puts 'Usage: sum.rb <filename>'
    puts
    puts 'Given a file containing a series of integers, 1 per line, adds them'
    puts 'up and returns the answer.'
    Sysexits.exit(:usage)
  end

  def self.handle_missing_file(filename)
    puts "File not found: #{filename}"
    Sysexits.exit(:input_missing)
  end

  def self.sum_file(filename)
    result = 0
    File.foreach(filename) do |line|
      result += line.chomp.to_i
    end
    result
  end
end

FileSummer.usage unless ARGV.length == 1
filename = ARGV.first
FileSummer.handle_missing_file(filename) unless File.exist?(filename)
puts FileSummer.sum_file(filename)
