#!/usr/bin/env ruby
# frozen_string_literal: true

require '../argument_validator'
require 'io/console'
require 'byebug'

USAGE = <<~USAGE
  Usage: message_finder.rb <filename>

  Given a file containing a series of strings, 1 per line, each consisting
  of the start coordinates of a point and its velocity in the format:

    position=<x, y> velocity=<dx, dy>

  Finds the point at which the points coalesce to form a message.
USAGE

argument_validator = ArgumentValidator.new(USAGE, 1)

Point = Struct.new(:x, :y, :dx, :dy) do
  def apply_change(multiplier = 1)
    Point.new(x + (multiplier * dx),
              y + (multiplier * dy),
              dx,
              dy)
  end
end

# Reads in a file and produces a list of points.
class PointsReader
  MATCHER = /^position=<\s*(?<x>-?\d+),\s+(?<y>-?\d+)>\svelocity=<\s*(?<dx>-?\d+),\s*(?<dy>-?\d+)>$/

  def initialize(filename)
    @strings = IO.readlines(filename).map(&:chomp)
  end

  def call
    @strings.map do |str|
      parts = MATCHER.match(str)
      Point.new(parts[:x].to_i,
                parts[:y].to_i,
                parts[:dx].to_i,
                parts[:dy].to_i)
    end
  end
end

# Given a list of points, moves them until they form a message.
class MessageFinder
  def initialize(points)
    @points = points
    @time = 0
  end

  def call
    @points = quick_shrink(@points)
    display(@points)
    while (char = STDIN.getch)
      exit if ["\u0003", 'q'].include?(char)
      @points = move(@points)
      @time += 1
      display(@points)
    end
  end

  def quick_shrink(points)
    min_x_point, max_x_point = points.minmax_by(&:x)
    diff = max_x_point.x - min_x_point.x
    closing_speed = min_x_point.dx - max_x_point.dx
    multiplier = ((diff - 80) / closing_speed).floor
    @time += multiplier
    points.map { |p| p.apply_change(multiplier) }
  end

  def move(points)
    points.map(&:apply_change)
  end

  def display(points)
    puts "--- Time = #{@time} ---"
    puts render(points)
    puts '--- Press q to quit, or any other key to continue. ---'
  end

  def render(points)
    ymin, ymax = points.minmax_by(&:y).map(&:y)
    xmin, xmax = points.minmax_by(&:x).map(&:x)
    points_by_y = points.group_by(&:y).map { |k, v| [k, v.map(&:x)] }.to_h
    (ymin..ymax).map do |y|
      (xmin..xmax).map { |x| points_by_y[y]&.include?(x) ? '*' : ' ' }.join('')
    end
  end
end

argument_validator.check_number_of_arguments(ARGV)
filename = ARGV.first
argument_validator.check_file_exists(filename)

points = PointsReader.new(filename).call
MessageFinder.new(points).call
