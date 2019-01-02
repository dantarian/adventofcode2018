USAGE = <<-END_OF_USAGE
Usage: plant_breeder <filename> <generations>

Given a file containing an initial state and a set of rules for transitioning
from one state to the next, applies those rules <generations> times and then
outputs the sum of the indexes of the pots (where the first element of the
initial state has index 0).
END_OF_USAGE

class ArgumentValidator
  def initialize(@usage : String, @expected_args : Int32)
  end

  def check_number_of_arguments(args)
    return if args.size == @expected_args

    puts @usage
    exit
  end

  def check_file_exists(filename)
    return if File.exists?(filename)

    puts "File not found: #{filename}"
    puts
    puts @usage
    exit
  end
end

argument_validator = ArgumentValidator.new(USAGE, 2)
argument_validator.check_number_of_arguments(ARGV)
argument_validator.check_file_exists(ARGV.first)

def read_file(filename : String)
  lines = File.read_lines(filename)
  state = lines.first.sub("initial state: ", "")
  rules = lines.last(lines.length - 2)
  {state, rules}
end

def read_state(state : String)
  state.each_char
       .each_with_index
       .map { |c, i| i if c == "#" }
       .reject(&:nil?))
       .to_set
end

def read_rules(rules : Array(String))
  rules.select { |s| s.ends_with?("#") }
       .map { |s| s[0...5] }
       .map { |s| s.each_char.map { |c| c == "#" } }
       .to_set
end

def breed(state : String, rules : Set(Array(Boolean)))
  first, last = state.minmax
  first -= 2
  last += 2

  (first..last).map { |i| i if rules.includes?((i-2..i+2).map { |j| state.includes? j }) }
               .reject(&:nil?)
               .to_set
end

state, rules = read_file(ARGV.first)
state = read_state(state)
rules = read_rules(rules)
generations = ARGV.last.to_i

current_gen = 0
past_results = {} of (UInt64, Tuple(Int,Int))
past_results[state.hash] = {current_gen, state.sum}

while current_gen < generations
  current_gen += 1
  state = breed(state, rules)
  hash = state.hash
  break if past_results.key?(hash)
  past_results[hash] = {current_gen, state.sum}
end

if current_gen == generations
  puts state.sum
else
  # We have a loop. Find its length.
  loop_start = past_results[hash].first
  loop_length = current_gen - loop_start
  target_gen = ((generations - current_gen) % loop_length) + loop_start
  target_result = past_results.select { |k, v| v.first == target_gen }.first.last
  puts target_result.last
end

