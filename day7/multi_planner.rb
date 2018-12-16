#!/usr/bin/env ruby
# frozen_string_literal: true

require '../argument_validator'

USAGE = <<~USAGE
  Usage: multi_planner.rb <filename>

  Given a file containing a series of step orders in the form "Step
  A must be finished before step B can begin.", returns the time in
  which the job can be completed, given that each step takes 60
  seconds plus its position in the alphabet (1-indexed) to complete
  and there are five workers available.
USAGE

argument_validator = ArgumentValidator.new(USAGE, 1)

WorkerAllocation = Struct.new(:current_step, :time_remaining) do
  def clear_if_step_in(steps)
    if steps.include?(current_step)
      WorkerAllocation.new(nil, 0)
    else
      self
    end
  end
end

# Reads in a file and produces a minimal string.
class Planner
  OFFSET_FROM_ASCII = 4
  RULE_MATCHER = /^Step (?<parent>[A-Z]).*step (?<child>[A-Z]).*$/.freeze

  def initialize(filename)
    @dependencies = ('A'..'Z').map { |char| [char, []] }.to_h
    File.readlines(filename).map(&:chomp).each do |rule|
      parts = RULE_MATCHER.match(rule)
      @dependencies[parts[:child]] << parts[:parent]
    end
  end

  def call
    run_steps(@dependencies, Array.new(5) { WorkerAllocation.new(nil, 0) })
  end

  private

  def run_steps(dependencies, worker_allocations)
    return finish_work(worker_allocations) if dependencies.empty?

    while free_workers?(worker_allocations) && available_steps?(dependencies)
      (dependencies, worker_allocations) =
        allocate_work(dependencies, worker_allocations)
    end

    step_time = time_to_available(worker_allocations)
    worker_allocations = progress_work(worker_allocations, step_time)
    (dependencies, worker_allocations) =
      clear_finished(dependencies, worker_allocations)

    step_time + run_steps(dependencies, worker_allocations)
  end

  def free_workers?(worker_allocations)
    worker_allocations.any? do |a|
      a.current_step.nil?
    end
  end

  def available_steps?(dependencies)
    dependencies.any? { |_, v| v.empty? }
  end

  def extract_next_step(dependencies)
    step = dependencies.select { |_, v| v.empty? }.min.first
    [step, dependencies.reject { |k, _| k == step }]
  end

  def allocate_work(dependencies, worker_allocations)
    (step, remaining_dependencies) = extract_next_step(dependencies)
    updated_allocations = worker_allocations.map do |allocation|
      if allocation.current_step.nil? && !step.nil?
        allocation = WorkerAllocation.new(step, time_to_execute(step))
        step = nil
      end
      allocation
    end
    [remaining_dependencies, updated_allocations]
  end

  def progress_work(worker_allocations, time)
    worker_allocations.map do |allocation|
      remaining = allocation.time_remaining - time
      WorkerAllocation.new(
        allocation.current_step,
        remaining.positive? ? remaining : 0
      )
    end
  end

  def clear_finished(dependencies, worker_allocations)
    finished_steps = worker_allocations.select { |a| a.time_remaining.zero? }
                                       .map(&:current_step)
                                       .reject(&:nil?)
    [
      dependencies.map { |k, v| [k, v - finished_steps] }.to_h,
      worker_allocations.map do |allocation|
        allocation.clear_if_step_in(finished_steps)
      end
    ]
  end

  def finish_work(worker_allocations)
    time_spent = worker_allocations.map(&:time_remaining).max
    worker_allocations.map { WorkerAllocation.new(nil, 0) }
    time_spent
  end

  def time_to_available(worker_allocations)
    worker_allocations
      .reject { |a| a.current_step.nil? }
      .map(&:time_remaining)
      .min
  end

  def time_to_execute(step)
    step.ord - OFFSET_FROM_ASCII
  end
end

argument_validator.check_number_of_arguments(ARGV)
filename = ARGV.first
argument_validator.check_file_exists(filename)

puts Planner.new(filename).call
