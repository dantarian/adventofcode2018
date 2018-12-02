#!/usr/bin/env ruby
# frozen_string_literal: true

require '../argument_validator'

USAGE = <<~USAGE
  Usage: close_match_finder.rb <filename>

  Given a file containing a series of strings, 1 per line, returns the common
  characters between a pair of those strings that differ by only one character.
USAGE

argument_validator = ArgumentValidator.new(USAGE, 1)

# Finds a pair of strings in a file that differ by only one character, and
# returns their common characters as a string.
class CloseMatchFinder
  def initialize(filename)
    @strings = IO.readlines(filename).map(&:chomp)
  end

  def call
    previous_strings = []
    @strings.each do |s1|
      previous_strings.each do |s2|
        return common_characters(s1, s2) if close_match?(s1, s2)
      end
      previous_strings << s1
    end
  end

  def close_match?(string1, string2)
    distance = 0
    string1.each_char.zip(string2.each_char) do |l, r|
      distance += 1 unless l == r
      return false if distance > 1
    end
    true
  end

  def common_characters(string1, string2)
    string1.each_char
           .zip(string2.each_char)
           .select { |arr| arr.first == arr.last }
           .map(&:first)
           .join('')
  end
end

argument_validator.check_number_of_arguments(ARGV)
filename = ARGV.first
argument_validator.check_file_exists(filename)

puts CloseMatchFinder.new(filename).call
