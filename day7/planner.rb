#!/usr/bin/env ruby
# frozen_string_literal: true

require '../argument_validator'

USAGE = <<~USAGE
  Usage: planner.rb <filename>

  Given a file containing a series of step orders in the form "Step
  A must be finished before step B can begin.", returns the order in
  which the steps must be completed (in the case of a tie, the step
  earlies in the alphabet wins).
USAGE

argument_validator = ArgumentValidator.new(USAGE, 1)

# Reads in a file and produces a minimal string.
class Planner
  RULE_MATCHER = /^Step (?<parent>[A-Z]).*step (?<child>[A-Z]).*$/.freeze

  def initialize(filename)
    @dependencies = ('A'..'Z').map { |char| [char, []] }.to_h
    File.readlines(filename).map(&:chomp).each do |rule|
      parts = RULE_MATCHER.match(rule)
      @dependencies[parts[:child]] << parts[:parent]
    end
  end

  def call
    plan_steps(@dependencies).join('')
  end

  private

  def plan_steps(dependencies)
    return if dependencies.empty?

    next_step = dependencies.select { |_, v| v.empty? }.min.first
    updated_dependencies = dependencies.reject { |k, _| k == next_step }
                                       .map { |k, v| [k, v - [next_step]] }
                                       .to_h
    [next_step, plan_steps(updated_dependencies)].flatten
  end
end

argument_validator.check_number_of_arguments(ARGV)
filename = ARGV.first
argument_validator.check_file_exists(filename)

puts Planner.new(filename).call
