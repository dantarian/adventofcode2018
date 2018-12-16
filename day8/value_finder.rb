#!/usr/bin/env ruby
# frozen_string_literal: true

require '../argument_validator'

USAGE = <<~USAGE
  Usage: value_finder.rb <filename>

  Given a file containing a series of integers defining a tree, with each
  individual node being of the format:

    <# nodes> <# metadata> [<node1> [...]] [<metadatum1> [...]]

  Returns the value of the root node, where value is defined as:
    * With no children, the value is the sum of the metadata.
    * With children, the sum of the values of those children referenced
      (1-indexed) by the metadata. If the referenced child does not
      exist, it is skipped.
USAGE

argument_validator = ArgumentValidator.new(USAGE, 1)

# Represents a node in a tree.
class Node
  attr_accessor :children
  attr_accessor :data

  def initialize(children, data)
    @children = children
    @data = data
    @child_values = {}
  end

  def sum
    data.sum + @children.map(&:sum).sum
  end

  def value
    return data.sum if @children.empty?

    data.inject(0) do |val, d|
      val + if d.zero? || (@children.length < d)
              0
            else
              child_value(d - 1)
            end
    end
  end

  private

  def child_value(index)
    return @child_values[index] if @child_values.key?(index)

    @child_values[index] = @children[index].value
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

puts TreeBuilder.new(filename).call.value
