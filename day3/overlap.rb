#!/usr/bin/env ruby
# frozen_string_literal: true

require '../argument_validator'

USAGE = <<~USAGE
  Usage: overlap.rb <filename>

  Given a file containing a series of strings, 1 per line, each consisting
  of an ID, a set of starting coordinates, a width and a height, returns
  the number of squares in a 1000x1000 grid claimed by more than one entry.
USAGE

argument_validator = ArgumentValidator.new(USAGE, 1)

# Struct defining a pair of ranges, in the horizontal and vertical
# directions.
Claim = Struct.new(:id, :h_range, :v_range) do
  def cover?(x, y)
    h_range.cover?(x) && v_range.cover?(y)
  end
end

# Reads in a file and produces a list of claims.
class ClaimsReader
  def initialize(filename)
    @strings = IO.readlines(filename).map(&:chomp)
  end

  def call
    matcher = /^#(?<id>\d+)\s+@\s+(?<h_start>\d+),(?<v_start>\d+):\s+(?<width>\d+)x(?<height>\d+)$/

    @strings.map do |str|
      parts = matcher.match(str)
      Claim.new(parts['id'].to_i,
                parts['h_start'].to_i...(parts['h_start'].to_i + parts['width'].to_i),
		parts['v_start'].to_i...(parts['v_start'].to_i + parts['height'].to_i))
    end
  end
end

# Given a list of claims, counts the number of squares claimed more than once.
class DoubleClaimCounter
  def initialize(claims)
    @claims = claims
    @r_claims = claims.reverse
    @num_claims = claims.length
    h_ranges = claims.map(&:h_range)
    v_ranges = claims.map(&:v_range)
    @h_range = h_ranges.map(&:min).min..h_ranges.map(&:max).max
    @v_range = v_ranges.map(&:min).min..v_ranges.map(&:max).max
  end

  def call
    @h_range.inject(0) do |count, x|
      puts "Processing row #{x}..."
      count + @v_range.inject(0) do |subcount, y|
        first = @claims.find_index { |claim| claim.cover?(x, y) }
        if first
          second = @r_claims.find_index { |claim| claim.cover?(x, y) }
          subcount + (first + second == @num_claims - 1 ? 0 : 1)
        else
          subcount
        end
      end
    end
  end
end

argument_validator.check_number_of_arguments(ARGV)
filename = ARGV.first
argument_validator.check_file_exists(filename)

claims = ClaimsReader.new(filename).call
puts 'Read file.'
puts DoubleClaimCounter.new(claims).call
