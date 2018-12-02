#!/usr/bin/env ruby
# frozen_string_literal: true

require 'immutable'
require 'sysexits'

# Provides methods for validating input.
class ArgumentValidator
  def self.check_usage(args)
    return if args.length == 1

    puts 'Usage: first_repeat_in_running_sum.rb <filename>'
    puts
    puts 'Given a file containing a series of integers, 1 per line, returns'
    puts 'the first repeat value obtained by a running sum over the integers,'
    puts 'looping as necessary.'
    Sysexits.exit(:usage)
  end

  def self.check_file_exists(filename)
    return if File.exist?(filename)

    puts "File not found: #{filename}"
    Sysexits.exit(:input_missing)
  end
end

# Provides methods for reading a file and finding the first duplicate value
# in a running sum of its contents, repeating as necessary.
class DuplicateFrequencyFinder
  def initialize(filename)
    @filename = filename
    @running_total = 0
    @history = Immutable::Set.new
    @deltas = []
  end

  def call
    read_deltas
    loop do
      @deltas.each do |delta|
        apply_delta(delta)
        return @running_total unless @history
      end
    end
  end

  private

  def read_deltas
    File.foreach(@filename) do |line|
      @deltas << line.chomp.to_i
    end
  end

  def apply_delta(delta)
    @running_total += delta
    @history = @history.add?(@running_total)
  end
end

ArgumentValidator.check_usage(ARGV)
filename = ARGV.first
ArgumentValidator.check_file_exists(filename)
puts DuplicateFrequencyFinder.new(filename).call
