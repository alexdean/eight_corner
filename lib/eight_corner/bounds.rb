# A bounding box.
module EightCorner
  class Bounds

    # width
    attr_accessor :x

    # height
    attr_accessor :y

    def initialize(x=nil, y=nil)
      @x = x
      @y = y
    end

    def x_from_pct(percent)
      @x * percent
    end
    def y_from_pct(percent)
      @y * percent
    end

    def quadrant(point)
      current = [
        point.x < x/2 ? 0 : 1,
        point.y < y/2 ? 0 : 1
      ]

      {
        [0,0] => Quadrant::UPPER_LEFT,
        [1,0] => Quadrant::UPPER_RIGHT,
        [0,1] => Quadrant::LOWER_LEFT,
        [1,1] => Quadrant::LOWER_RIGHT
      }[current]
    end

  end
end
