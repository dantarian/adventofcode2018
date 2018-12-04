#!/usr/bin/env ruby
# frozen_string_literal: true

require '../argument_validator'
require 'set'

USAGE = <<~USAGE
  Usage: overlap.rb <filename>

  Given a file containing a series of strings, 1 per line, each consisting
  of an ID, a set of starting coordinates, a width and a height, returns
  the ID of the entry that does not overlap any others.
USAGE

argument_validator = ArgumentValidator.new(USAGE, 1)

# Struct defining a pair of ranges, in the horizontal and vertical
# directions.
Claim = Struct.new(:id, :h_range, :v_range) do
  def intersection(other)
    return nil unless overlap?(other)

    [range_intersection(h_range, other.h_range),
     range_intersection(v_range, other.v_range)]
  end

  def overlap?(other)
    range_overlap?(h_range, other.h_range) &&
      range_overlap?(v_range, other.v_range)
  end

  private

  def range_intersection(range1, range2)
    [range1.min, range2.min].max..[range1.max, range2.max].min
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
        parts['id'],
        parts['h_start'].to_i...(parts['h_start'].to_i + parts['width'].to_i),
        parts['v_start'].to_i...(parts['v_start'].to_i + parts['height'].to_i)
      )
    end
  end
end

# Given a list of claims, counts the number of squares claimed more than once.
class NonOverlappingClaimFinder
  def initialize(claims)
    @claims = claims
  end

  def call
    previous_claims = []
    non_overlapping_ids = @claims.map(&:id)
    @claims.each do |claim1|
      previous_claims.each do |claim2|
        non_overlapping_ids -= [claim1.id, claim2.id] if claim1.overlap?(claim2)
      end
      previous_claims << claim1
    end
    non_overlapping_ids.first
  end
end

argument_validator.check_number_of_arguments(ARGV)
filename = ARGV.first
argument_validator.check_file_exists(filename)

claims = ClaimsReader.new(filename).call
puts NonOverlappingClaimFinder.new(claims).call
