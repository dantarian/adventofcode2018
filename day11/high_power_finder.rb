#!/usr/bin/env ruby
# frozen_string_literal: true

require '../argument_validator'

USAGE = <<~USAGE
  Usage: high_power_finder.rb <serial_number>

  Returns the x,y coordinates of the top-left corner of a 3x3 subgrid of a
  supergrid with coordinates ranging from 1 to 300 in both directions,
  with maximal value based on some arbitrary formula.
USAGE

argument_validator = ArgumentValidator.new(USAGE, 1)

# Finds the subgrid with the highest power value.
class HighPowerFinder
  def initialize(serial_number)
  end

  def call
  end

  private

end

argument_validator.check_number_of_arguments(ARGV)
serial_number = ARGV.shift.to_i

puts HighPowerFinder.new(serial_number).call
