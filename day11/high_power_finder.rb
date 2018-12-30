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

def calc(x, y, sx, ten_s)
  (((y * x * x) + (20 * x * y) + (100 * y) + sx + ten_s) / 100) % 10
end

Point = Struct.new(:x, :y)

# Finds the subgrid with the highest power value.
class HighPowerFinder
  def initialize(serial_number)
    ten_s = serial_number * 10
    @grid = {}
    (1..300).each do |x|
      sx = serial_number * x
      (1..300).each do |y|
        @grid[Point.new(x, y)] = calc(x, y, sx, ten_s)
      end
    end
  end

  def call
    @grid.map { |k, _| [k, subgrid_sum(k)] }
         .to_h
         .reject { |_, v| v.nil? }
         .max_by { |_, v| v }
  end

  private

  def subgrid_sum(key)
    return nil if (key.x > 298) || (key.y > 298)

    (0..2).inject(0) do |accx, dx|
      accx + (0..2).inject(0) do |accy, dy|
        accy + @grid[Point.new(key.x + dx, key.y + dy)]
      end
    end
  end
end

argument_validator.check_number_of_arguments(ARGV)
serial_number = ARGV.shift.to_i

puts HighPowerFinder.new(serial_number).call
