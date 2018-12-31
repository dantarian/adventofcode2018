#!/usr/bin/env ruby
# frozen_string_literal: true

require '../argument_validator'

USAGE = <<~USAGE
  Usage: advanced_high_power_finder.rb <serial_number>

  Returns the x,y,n coordinates of the top-left corner of a square subgrid of
  size n of a supergrid with coordinates ranging from 1 to 300 in both directions,
  with maximal value based on some arbitrary formula.
USAGE

argument_validator = ArgumentValidator.new(USAGE, 1)

Address = Struct.new(:x, :y, :n)

# Fill a square array with power levels
class GridBuilder
  def initialize(serial_number, size)
    @serial_number = serial_number
    @size = size
    @ten_s = 10 * serial_number
  end

  def call
    (1..@size).inject([]) do |grid, x|
      sx = @serial_number * x
      grid << (1..@size).inject([]) do |col, y|
        col << calc(x, y, sx, @ten_s)
      end
    end
  end

  def calc(x, y, sx, ten_s)
    ((((y * x * x) + (20 * x * y) + (100 * y) + sx + ten_s) / 100) % 10) - 5
  end
end

# Finds the subgrid with the highest power value.
class HighPowerFinder
  def initialize(grid)
    @grid = grid
    @size = grid.length
  end

  def call
    (1..@size).map { |size| max_of_size(size) }.max_by(&:last)
  end

  private

  def max_of_size(size)
    max = subgrid_sums(size).map { |c| c.each_with_index.max_by(&:first) }
                            .each_with_index
                            .max_by { |max_c| max_c.first.first }

    [Address.new(max.last + 1, max.first.last + 1, size), max.first.first]
  end

  def subgrid_sums(size)
    row_sums = (0...@size).map { |y| window_sums(@grid.map { |a| a[y] }, size) }
    (0...row_sums.first.length).map do |x|
      window_sums(row_sums.map { |a| a[x] }, size)
    end
  end

  def window_sums(array, size)
    array.each_cons(size + 1).inject([array.first(size).sum]) do |acc, subarray|
      acc << acc.last + subarray.last - subarray.first
    end
  end
end

argument_validator.check_number_of_arguments(ARGV)
serial_number = ARGV.shift.to_i

grid = GridBuilder.new(serial_number, 300).call
puts HighPowerFinder.new(grid).call
