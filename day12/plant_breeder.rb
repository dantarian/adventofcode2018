#!/usr/bin/env ruby
# frozen_string_literal: true

require '../argument_validator'
require 'set'
require 'progress_bar'

USAGE = <<~USAGE
  Usage: plant_breeder.rb <filename> <generations>

  Given a file containing an initial state and a set of rules for updating
  that state in a one-dimensional game-of-life setup, calculates the sum
  of the "pot" numbers containing "plants" after the given number of generations.
USAGE

argument_validator = ArgumentValidator.new(USAGE, 2)

# Reads in a file and produces a state and a set of rules.
class InputReader
  def initialize(filename)
    @strings = IO.readlines(filename).map(&:chomp)
  end

  def call
    [state, rules]
  end

  private

  def state
    @strings[0].sub('initial state: ', '')
  end

  def rules
    @strings[2...@strings.length]
  end
end

# Takes a string of # and . and turns it into an array containing the indexes
# with a '#'.
class StateBuilder
  def initialize(state_string)
    @state_string = state_string
  end

  def call
    @state_string.each_char
                 .each_with_index
                 .select { |c, _| c == '#' }
                 .map { |_, i| i }
                 .to_set
  end
end

# Takes a set of rules of the form "[.#]{5} => [.#]" and produces a set of
# arrays of booleans that would describe arrangements leading to a value
# of true in the central location in the next generation.
class RulesBuilder
  def initialize(rules_strings)
    @rules_strings = rules_strings
  end

  def call
    @rules_strings.select { |str| str.end_with?('#') }
                  .map { |str| str[0...5] }
                  .map { |str| str.each_char.map { |c| c == '#' } }
                  .to_set
  end
end

# Given an initial state and a set of rules, generates the next state.
class PlantBreeder
  def initialize(state, rules, generations)
    @state = state
    @rules = rules
    @generations = generations
    @bar = ProgressBar.new(generations)
  end

  def call
    @generations.times { @state = breed }
    @state
  end

  private

  def breed
    @bar.increment!

    first, last = @state.minmax
    first -= 2
    last += 2

    (first..last).map { |pot| pot if @rules.include?(local_state(pot)) }
                 .reject(&:nil?)
                 .to_set
  end

  def local_state(pot)
    (pot - 2..pot + 2).map { |p| @state.include? p }
  end
end

argument_validator.check_number_of_arguments(ARGV)
filename = ARGV.first
argument_validator.check_file_exists(filename)
generations = ARGV.last.to_i

state, rules = InputReader.new(filename).call
state = StateBuilder.new(state).call
rules = RulesBuilder.new(rules).call
state = PlantBreeder.new(state, rules, generations).call
puts state.sum
