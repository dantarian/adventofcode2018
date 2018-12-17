#!/usr/bin/env ruby
# frozen_string_literal: true

require '../argument_validator'

USAGE = <<~USAGE
  Usage: high_score_finder.rb <players> <last_marble_value>

  Returns the final score of a game played using numbered marbles.
USAGE

argument_validator = ArgumentValidator.new(USAGE, 2)

# Node in a doubly-linked circular list
class Node
  attr_reader :value
  attr_accessor :clockwise
  attr_accessor :anticlockwise

  def initialize(value, clockwise = nil, anticlockwise = nil)
    @value = value
    @clockwise = clockwise || self
    @anticlockwise = anticlockwise || self
  end
end

# Simple implementation of a doubly-linked circular list
class CircularList
  def initialize(value)
    @current = Node.new(value)
  end

  def value
    @current.value
  end

  def next(count = 1)
    count.times { @current = @current.clockwise }
    self
  end

  def previous(count = 1)
    count.times { @current = @current.anticlockwise }
    self
  end

  def add!(value)
    current_node = @current
    next_node = @current.clockwise
    new_node = Node.new(value, next_node, current_node)
    current_node.clockwise = new_node
    next_node.anticlockwise = new_node
    @current = new_node
    self
  end

  def delete!
    @current.anticlockwise.clockwise = @current.clockwise
    @current.clockwise.anticlockwise = @current.anticlockwise
    @current = @current.clockwise
    self
  end

  def to_s
    values = []
    current_node = @current
    loop do
      values << current_node.value
      current_node = current_node.clockwise
      break if current_node == @current
    end
    values.join(' ')
  end
end

# Works out the winning score.
class HighScoreFinder
  def initialize(players, last_marble_value)
    @scores = Array.new(players) { 0 }
    @last_marble_value = last_marble_value
    @marbles = CircularList.new(0)
  end

  def call
    (1..@last_marble_value).each do |marble|
      take_turn(marble, marble % @scores.length)
    end

    @scores.max
  end

  private

  def take_turn(marble, player)
    if (marble % 23).zero?
      @scores[player] += marble + @marbles.previous(7).value
      @marbles.delete!
    else
      @marbles.next.add!(marble)
    end
  end
end

argument_validator.check_number_of_arguments(ARGV)
players = ARGV.shift.to_i
last_marble_value = ARGV.shift.to_i

puts HighScoreFinder.new(players, last_marble_value).call
