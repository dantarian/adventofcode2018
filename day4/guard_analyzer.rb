#!/usr/bin/env ruby
# frozen_string_literal: true

require '../argument_validator'
require 'time'

USAGE = <<~USAGE
  Usage: guard_analyzer.rb <filename>

  Given a file containing a series of strings, 1 per line, each consisting
  of a timestamp and either a guard shift start entry, a guard falls asleep
  entry or a guard wakes up entry, returns the ID of the guard who spends
  the most time asleep, and the minute of the hour at which they're most
  likely to be asleep (and their product).
USAGE

argument_validator = ArgumentValidator.new(USAGE, 1)

# Reads in a file and produces a hash mapping guards to their sleep periods.
class SleepReader
  GUARD_MATCHER = /.*Guard #(?<id>\d+) begins shift$/.freeze
  SLEEP_MATCHER =
    /^\[(?<timestamp>\d{4}-\d{2}-\d{2}\s\d{2}:\d{2})\]\s+falls asleep$/.freeze
  WAKES_MATCHER =
    /^\[(?<timestamp>\d{4}-\d{2}-\d{2}\s\d{2}:\d{2})\]\s+wakes up$/.freeze

  def initialize(filename)
    @strings = IO.readlines(filename).map(&:chomp).sort
  end

  def call
    guard, started_sleeping = nil
    @strings.each_with_object(Hash.new { |h, k| h[k] = [] }) do |str, result|
      if GUARD_MATCHER.match?(str)
        guard = GUARD_MATCHER.match(str)['id'].to_i
      elsif SLEEP_MATCHER.match?(str)
        started_sleeping = Time.parse(SLEEP_MATCHER.match(str)['timestamp'])
      else
        result[guard] << [started_sleeping, Time.parse(WAKES_MATCHER.match(str)['timestamp'])]
      end
      result
    end
  end
end

# Finds the guard who sleeps the most.
class SleepiestGuardFinder
  def initialize(guard_data)
    @guard_data = guard_data
  end

  def call
    @guard_data
      .transform_values { |v| v.map { |a| a.last - a.first }.sum }
      .max_by { |_, v| v }
      .first
  end
end

# Finds a guard's sleepiest minute of the hour.
class SleepiestMinuteFinder
  def initialize(sleeps)
    @sleeps = sleeps
  end

  def call
    minutes = @sleeps.each_with_object(Hash.new { |h, k| h[k] = 0 }) do |sleep, hist|
      time = sleep.first
      while time < sleep.last
        hist[time.min] += 1
        time += 60
      end
      hist
    end
    minutes.max_by { |_, v| v }
  end
end

# Finds the sleepiest guard and minute combination.
class SleepiestGuardAndMinute
  def initialize(guard_data)
    @guard_data = guard_data
  end

  def call
    result = @guard_data
             .transform_values { |sleeps| SleepiestMinuteFinder.new(sleeps).call }
             .max_by { |_, v| v.last }
    { guard: result.first, minute: result.last.first }
  end
end

argument_validator.check_number_of_arguments(ARGV)
filename = ARGV.first
argument_validator.check_file_exists(filename)

sleeps = SleepReader.new(filename).call
sleepiest_guard = SleepiestGuardFinder.new(sleeps).call
sleepiest_minute = SleepiestMinuteFinder.new(sleeps[sleepiest_guard]).call.first
product = sleepiest_guard * sleepiest_minute

puts 'Strategy 1:'
puts "#{sleepiest_guard} x #{sleepiest_minute} = #{product}"

sleepiest = SleepiestGuardAndMinute.new(sleeps).call
product = sleepiest[:guard] * sleepiest[:minute]

puts 'Strategy 2:'
puts "#{sleepiest[:guard]} x #{sleepiest[:minute]} = #{product}"
