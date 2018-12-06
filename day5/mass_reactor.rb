#!/usr/bin/env ruby
# frozen_string_literal: true

require '../argument_validator'
require 'time'

USAGE = <<~USAGE
  Usage: mass_reactor.rb <filename>

  Given a file containing a series of characters, returns the length of the
  shortest string of those characters that remain after removing all
  characters of a letter and then pairs of adjacent upper-case and lower-case
  versions of the same character, including such pairs as are generated as a
  result of removing the characters between them.
USAGE

argument_validator = ArgumentValidator.new(USAGE, 1)

# Reads in a file and produces a hash of minimal strings by dropped character.
class Reactor
  def initialize(filename)
    @polymer = File.read(filename).chomp
  end

  def call
    result = Hash.new { |h, k| h[k] = [] }
    @polymer.each_char do |char|
      ('a'..'z').each do |drop_char|
        if result[drop_char].last && (char.swapcase == result[drop_char].last)
          result[drop_char].pop
        elsif ![drop_char, drop_char.upcase].include?(char)
          result[drop_char] << char
        end
      end
    end
    result
  end
end

argument_validator.check_number_of_arguments(ARGV)
filename = ARGV.first
argument_validator.check_file_exists(filename)

puts Reactor.new(filename).call.min_by { |_, v| v.length }.last.length
