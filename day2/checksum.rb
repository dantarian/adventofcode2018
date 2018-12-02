#!/usr/bin/env ruby
# frozen_string_literal: true

require '../argument_validator'

USAGE = <<~USAGE
  Usage: checksum.rb <filename>

  Given a file containing a series of strings, 1 per line, returns a checksum
  calculated by multiplying the number of those strings containing exactly two
  of any letter by the number containing exactly three of any letter.
USAGE

argument_validator = ArgumentValidator.new(USAGE, 1)

# Calculates the checksum of a file consisting of many string by multiplying
# the number of those strings that contain exactly two of the same character
# by the number that contain exactly three of the same character. Strings
# may legitimately fall into both classes.
class ChecksumCalculator
  def initialize(filename)
    @strings = IO.readlines(filename)
  end

  def call
    strings_with_pairs_count = 0
    strings_with_triples_count = 0
    @strings.each do |string|
      counts = CharacterCounter.count(string)
      strings_with_pairs_count += 1 if counts.value?(2)
      strings_with_triples_count += 1 if counts.value?(3)
    end

    strings_with_pairs_count * strings_with_triples_count
  end
end

# Take a string and returns a map containing the counts of each letter.
class CharacterCounter
  def self.count(input)
    unless input.respond_to? :each_char
      raise ArgumentError, 'Argument has no each_char method.'
    end

    input.each_char.each_with_object({}) do |char, hash|
      hash[char] = (hash.key?(char) ? hash[char] + 1 : 1)
    end
  end
end

argument_validator.check_number_of_arguments(ARGV)
filename = ARGV.first
argument_validator.check_file_exists(filename)

puts ChecksumCalculator.new(filename).call
