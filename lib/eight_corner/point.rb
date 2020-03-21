module EightCorner

  # A point on a 2D plane.
  class Point

    attr_accessor :x, :y,
      # distance from previous point to this one
      :distance_from_last,
      # the distance % used to build this distance
      :distance_pct,
      # bearing from previous point to this one
      # (NOT from this point to the previous one.)
      :bearing_from_previous,
      # the bearing % used to build this bearing
      :bearing_pct,
      # the bounds object that the point exists in
      :bounds,
      # the potential value used to create this point
      :created_by_potential

    def initialize(x=nil, y=nil)
      @x = x
      @y = y
    end

    # which quadrant of the Bounds is this point in?
    def quadrant
      raise "cannot calculate quadrant. bounds is nil" if bounds.nil?
      @quadrant ||= bounds.quadrant(self)
    end

    # TODO: is this unused? remove if so.
    def bearing_range
      Quadrant.bearing_range_for(quadrant)
    end

    # a single % value based on the data in this point
    # used as an input for another Figure#plot call
    # TODO: what is distribution of values of this function?
    # we want something reasonably gaussian, i think.
    #
    # w/o created_by_potential, rearranging the initial string in a series of figures
    # alters the first 10 figures or so, and then they eventually converge back to
    # being identical. (The ~11th figure shows no dependence on this initial change in ordering.)
    def potential
      (x/bounds.x.to_f + y/bounds.y.to_f + distance_pct.to_f + bearing_pct.to_f + created_by_potential.to_f) % 1
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
      x >= 0 && y >= 0 && x <= bounds.x && y <= bounds.y
    end

    def as_json
      [@x, @y]
    end
  end
end
