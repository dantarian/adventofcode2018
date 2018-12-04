#!/usr/bin/env ruby
# frozen_string_literal: true

require '../argument_validator'
require 'set'

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
  def intersection(other)
    return nil unless overlap?(self, other)

    [range_intersection(h_range, other.h_range),
     range_intersection(v_range, other.v_range)]
  end

  private

  def range_intersection(range1, range2)
    [range1.min, range2.min].max..[range1.max, range2.max].min
  end

  def overlap?(claim1, claim2)
    range_overlap?(claim1.h_range, claim2.h_range) &&
      range_overlap?(claim1.v_range, claim2.v_range)
  end

  def range_overlap?(range1, range2)
    !(range1.max < range2.min || range2.max < range1.min)
  end
end

# Reads in a file and produces a list of claims.
class ClaimsReader
  MATCHER = /^#(?<id>\d+)\s+@\s+(?<h_start>\d+),(?<v_start>\d+):\s+(?<width>\d+)x(?<height>\d+)$/

  def initialize(filename)
    @strings = IO.readlines(filename).map(&:chomp)
  end

  def call
    @strings.map do |str|
      parts = MATCHER.match(str)
      Claim.new(
        parts['id'].to_i,
        parts['h_start'].to_i...(parts['h_start'].to_i + parts['width'].to_i),
        parts['v_start'].to_i...(parts['v_start'].to_i + parts['height'].to_i)
      )
    end
  end
end

# Given a list of claims, counts the number of squares claimed more than once.
class DoubleClaimCounter
  def initialize(claims)
    @claims = claims
  end

  def call
    previous_claims = []
    overlaps = Set[]
    @claims.each do |claim1|
      previous_claims.each do |claim2|
	intersection = claim1.intersection(claim2)
	if intersection
	  intersection.first.each do |x|
	    intersection.last.each do |y|
              overlaps.add([x,y])
	    end
	  end
	end
      end
      previous_claims << claim1
    end
    overlaps.length
  end
end

argument_validator.check_number_of_arguments(ARGV)
filename = ARGV.first
argument_validator.check_file_exists(filename)

claims = ClaimsReader.new(filename).call
puts DoubleClaimCounter.new(claims).call
