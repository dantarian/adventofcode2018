#!/usr/bin/env ruby
# frozen_string_literal: true

require '../argument_validator'
require 'set'

USAGE = <<~USAGE
  Usage: first_repeat_in_running_sum.rb <filename>

  Given a file containing a number of integers, 1 per line, returns the first
  repeat value obtained by a running sum over the integers, repeating the set
  of integers as necessary.
USAGE

argument_validator = ArgumentValidator.new(USAGE, 1)

# Provides methods for reading a file and finding the first duplicate value
# in a running sum of its contents, repeating as necessary.
class DuplicateFrequencyFinder
  def initialize(filename)
    @deltas = File.foreach(filename).map(&:chomp).map(&:to_i)
  end

  def call
    running_total = 0
    history = Set[]

    loop do
      @deltas.each do |delta|
        running_total += delta
        return running_total unless history.add?(running_total)
      end
    end
  end
end

argument_validator.check_number_of_arguments(ARGV)
filename = ARGV.first
argument_validator.check_file_exists(filename)

puts DuplicateFrequencyFinder.new(filename).call
