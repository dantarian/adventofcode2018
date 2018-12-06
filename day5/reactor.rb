#!/usr/bin/env ruby
# frozen_string_literal: true

require '../argument_validator'
require 'time'

USAGE = <<~USAGE
  Usage: reactor.rb <filename>

  Given a file containing a series of characters, returns the length of the
  string of those characters that remain after removing all pairs of
  adjacent upper-case and lower-case versions of the same character,
  including such pairs as are generated as a result of removing the
  characters between them.
USAGE

argument_validator = ArgumentValidator.new(USAGE, 1)

# Reads in a file and produces a minimal string.
class Reactor
  def initialize(filename)
    @polymer = File.read(filename).chomp
  end

  def call
    result = []
    @polymer.each_char do |char|
      if result.last && (char.swapcase == result.last)
        result.pop
      else
        result << char
      end
    end
    result
  end
end

argument_validator.check_number_of_arguments(ARGV)
filename = ARGV.first
argument_validator.check_file_exists(filename)

puts Reactor.new(filename).call.length
