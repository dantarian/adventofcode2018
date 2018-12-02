#!/usr/bin/env ruby
# frozen_string_literal: true

require '../argument_validator'

USAGE = <<~USAGE
  Usage: sum.rb <filename>

  Given a file containing a series of integers, 1 per line, adds them up and
  returns the answer.
USAGE

argument_validator = ArgumentValidator.new(USAGE, 1)
argument_validator.check_number_of_arguments(ARGV)
filename = ARGV.first
argument_validator.check_file_exists(filename)

puts File.foreach(filename).map(&:chomp).map(&:to_i).sum
