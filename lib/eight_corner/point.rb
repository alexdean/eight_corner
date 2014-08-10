module EightCorner

  # A point on a 2D plane.
  class Point

    attr_accessor :x, :y

    def initialize(x=nil, y=nil)
      @x = x
      @y = y
    end

    def quadrant

    end

    def max
      [@x,@y].max
    end

    def max_is
      @x > @y ? :x : :y
    end

    def ==(other)
      x == other.x && y == other.y
    end

    def valid?
      x > 0 && y > 0
    end

  end
end
