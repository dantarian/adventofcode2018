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
    grid = []
    (1..@size).each do |x|
      sx = @serial_number * x
      col = []
      (1..@size).each do |y|
        col << calc(x, y, sx, @ten_s)
      end
      grid << col
    end
    grid
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
    max_per_column = subgrid_sums(size).map do |col|
      max = col.max
      [max, col.index(max)]
    end

    max = max_per_column.max_by(&:first)

    [Address.new(max_per_column.index(max) + 1, max.last + 1, size), max.first]
  end

  def subgrid_sums(size)
    row_sums = (0...@size).map { |y| window_sums(@grid.map { |a| a[y] }, size) }
    (0...row_sums.first.length).map do |x|
      window_sums(row_sums.map { |a| a[x] }, size)
    end
  end

  def window_sums(array, size)
    output = [array.first(size).sum]
    if array.length > size
      (0...array.length - size).each do |offset|
        output << output[offset] + array[offset + size] - array[offset]
      end
    end
    output
  end
end

argument_validator.check_number_of_arguments(ARGV)
serial_number = ARGV.shift.to_i

grid = GridBuilder.new(serial_number, 300).call
puts HighPowerFinder.new(grid).call
