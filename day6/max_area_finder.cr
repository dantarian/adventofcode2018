USAGE = <<-END_OF_USAGE
Usage: max_area_finder <filename>

Given a file containing a number of coordinates, one set per line,
returns the size of the largest non-infinite area closest to one
of those points, as measured by the Manhatten Distance.
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

  private def sign(i : Int32)
    return 0 if i == 0
    i.abs / i
  end
end

def read_points(filename : String)
  File.read_lines(filename).map do |coords|
    substrings = coords.split(", ")
    Point.new(substrings[0].to_i, substrings[1].to_i)
  end
end

class MaxAreaFinder
  @x_min : Int32
  @x_max : Int32
  @y_min : Int32
  @y_max : Int32
  @finite_points : Array(Point)
  @owned_points = Hash(Point, Point | Nil).new

  def initialize(@known_points : Array(Point))
    @x_min = @known_points.map { |p| p.x }.min
    @x_max = @known_points.map { |p| p.x }.max
    @y_min = @known_points.map { |p| p.y }.min
    @y_max = @known_points.map { |p| p.y }.max
    @owned_points.merge!(Hash.zip(@known_points, @known_points))
    @finite_points = @known_points.select { |point| finite?(point) }
  end

  def call
    find_owners
    @owned_points.group_by { |k,v| v }.max_of { |k,v| v.size }
  end

  private def find_owners
    points_to_check = @finite_points.map { |point| point.neighbours }
                                    .flatten
                                    .to_set
                                    .select { |point| consider?(point) }

    while points_to_check.size > 0
      new_points_to_check = Set.new([] of Point)
      points_to_check.each do |point|
        owner = find_owning_point(point)
        @owned_points[point] = owner
        if (!owner.nil?) && @finite_points.includes?(owner)
          new_points_to_check.concat(point.neighbours.to_set.select { |p| consider?(p) })
        end
      end
      points_to_check = new_points_to_check
    end
  end

  private def consider?(point)
    point.x >= @x_min &&
      point.x <= @x_max &&
      point.y >= @y_min &&
      point.y <= @y_max &&
      !@owned_points.has_key?(point)
  end

  private def finite?(known_point : Point)
    edge_points(known_point)
      .map { |point| find_owning_point(point) }
      .none? { |owning_point| owning_point == known_point }
  end

  private def edge_points(point : Point)
    [
      Point.new(point.x, @y_min),
      Point.new(point.x, @y_max),
      Point.new(@x_min, point.y),
      Point.new(@x_max, point.y)
    ]
  end

  private def find_owning_point(point : Point)
    return @owned_points[point] if @owned_points.has_key?(point)

    points_to_check = @known_points
    distances = points_to_check.map { |p| { p, p.distance_to(point) } }
    owner, min_distance = distances.min_by { |p, d| d }
    owner = nil unless distances.map { |p, d| d }.one? { |d| d == min_distance }
    @owned_points[point] = owner
    owner
  end
end

points = read_points(ARGV.first)
puts MaxAreaFinder.new(points).call
