#!/usr/bin/env ruby
# frozen_string_literal: true

require '../argument_validator'

USAGE = <<~USAGE
  Usage: checksum.rb <filename>

  Given a file containing a series of integers defining a tree, with each
  individual node being of the format:

    <# nodes> <# metadata> [<node1> [...]] [<metadatum1> [...]]

  Returns the sum of all metadata.
USAGE

argument_validator = ArgumentValidator.new(USAGE, 1)

Node = Struct.new(:children, :data) do
  def sum
    data.sum + children.map(&:sum).sum
  end
end

# Reads in a file and builds a tree out of it.
class TreeBuilder
  def initialize(filename)
    @values = File.read(filename).chomp.split(' ').map(&:to_i)
  end

  def call
    children = @values.shift
    metadata = @values.shift
    Node.new(build_subtree(children),
             @values.shift(metadata))
  end

  private

  def build_subtree(number_of_nodes)
    return [] if number_of_nodes < 1

    (1..number_of_nodes).map do
      children = @values.shift
      metadata = @values.shift
      Node.new(build_subtree(children),
               @values.shift(metadata))
    end
  end
end

argument_validator.check_number_of_arguments(ARGV)
filename = ARGV.first
argument_validator.check_file_exists(filename)

puts TreeBuilder.new(filename).call.sum
