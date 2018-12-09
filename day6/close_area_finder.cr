USAGE = <<-END_OF_USAGE
Usage: close_area_finder <filename>

Given a file containing a number of coordinates, one set per line,
returns the size of the area whose total distance from all
of those points, as measured by the Manhattan Distance, is less
than 10000.
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

argument_validator = ArgumentValidator.new(USAGE, 1)
argument_validator.check_number_of_arguments(ARGV)
argument_validator.check_file_exists(ARGV.first)

struct Point
  property x : Int32, y : Int32

  def initialize(@x : Int32, @y : Int32)
  end

  def neighbours
    [
      Point.new(x, y-1),
      Point.new(x, y+1),
      Point.new(x-1, y),
      Point.new(x+1, y)
    ]
  end

  def distance_to(other_point : Point)
    (x - other_point.x).abs + (y - other_point.y).abs
  end

  def to_s(io)
    io << "(#{x}, #{y})"
  end
end

def read_points(filename : String)
  File.read_lines(filename).map do |coords|
    substrings = coords.split(", ")
    Point.new(substrings[0].to_i, substrings[1].to_i)
  end
end

class AreaFinder
  @x_min : Int32
  @x_max : Int32
  @y_min : Int32
  @y_max : Int32
  @checked_points = Hash(Point, Boolean).new

  def initialize(@known_points : Array(Point))
    @x_min = @known_points.map { |p| p.x }.min
    @x_max = @known_points.map { |p| p.x }.max
    @y_min = @known_points.map { |p| p.y }.min
    @y_max = @known_points.map { |p| p.y }.max
  end

  def call
    find_points
    @checked_points.select { |k,v| v }.size
  end

  private def find_points
    points_to_check = @known_points

    while points_to_check.size > 0
      new_points_to_check = Set.new([] of Point)
      points_to_check.each do |point|
	distance = @known_points.map { |kp| kp.distance_to(point) }.sum
	@checked_point[point] = (distance < 10000)
        if (distance < 10000)
          new_points_to_check.concat(point.neighbours.to_set.select { |p| consider?(p) })
        end
      end
      points_to_check = new_points_to_check
    end
  end

  private def consider?(point)
    !@checked_points.has_key?(point)
  end
end

points = read_points(ARGV.first)
puts AreaFinder.new(points).call
