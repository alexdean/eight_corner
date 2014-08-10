module EightCorner

  # This class is a catch-all. Will be cleaned up, you know, sometime.
  class Base
    def initialize(x_extent, y_extent, options={})
      options[:group_with] ||= :group2
      options[:angle_with] ||= :percentize_modulus_exp
      options[:distance_with] ||= :percentize_modulus

      @bounds = Bounds.new(x_extent, y_extent)
      @point_count = 8
      @log = options[:logger] || Logger.new('/dev/null')

      @grouping_method = options[:group_with]
      @angle_method = options[:angle_with]
      @distance_method = options[:distance_with]
    end

    def plot(str)

      mapper = StringMapper.new(group_count: @point_count-1)

      # 7 2-element arrays. each value is a float 0..1.
      # 1st: % applied to calculate an angle
      # 2nd: % applied to calculate a distance
      potentials = mapper.potentials(
        mapper.groups(str, @grouping_method),
        @angle_method,
        @distance_method
      )

      # out: an array of Point instances. the figure we are drawing.
      fig = Figure.new
      fig.points << starting_point(str)

      (@point_count - 1).times do |i|
        current = fig.points[i]

        # TODO encourage more open angles?
        angle_to_next = angle(current, potentials[i][0])
        dist_to_boundary = distance_to_boundary(current, angle_to_next)

        # if we're too close to the edge, go the opposite direction.
        # so we don't get trapped in a corner.
        if dist_to_boundary <= 1
          angle_to_next += 180
          angle_to_next %= 360
          dist_to_boundary = distance_to_boundary(current, angle_to_next)
        end

        @log.debug(['current', current])
        @log.debug(['angle_to_next', angle_to_next])
        @log.debug(['distance_to_boundary', dist_to_boundary])



        # how to encourage more space-filling?
        # track how many points are in each quadrant.
        # if current point is in the most-populated one, move to least-populated.
        # if current point and previous point are too close together...
        # if current point and last point are in different quadrants...


        # encourage longer lines
        # can't be longer than dist_to_boundary.
        # increase low potentials
        additional_distance = Interpolate::Points.new(0.0 => 0.3, 0.5 => 0.0)

        distance_pct = potentials[i][1] + additional_distance.at(potentials[i][1])

        # force % into range 0.5 .. 0.9. keep away from bounds.
        distance_pct = 0.5 if distance_pct < 0.5
        distance_pct = 0.9 if distance_pct > 0.9

        distance = dist_to_boundary * distance_pct

        next_pt = next_point(
          current,
          angle_to_next,
          distance
        )

        # TODO: how do we create invalid points?
        if ! next_pt.valid?
          # if next_pt.x < 10
          #   next_pt.x += 10
          # end
          # if next_pt.y < 10
          #   next_pt.y += 10
          # end

          @log.error "point produced invalid next. '#{str}' #{i}"
          @log.error(['current', current])
          @log.error(['angle_to_next', angle_to_next])
          @log.error(['distance_to_boundary', dist_to_boundary])
          @log.error(['next_pt', next_pt])
        end

        fig.points << next_pt
      end

      fig
    end

    # return a starting point for string
    def starting_point(str)
      mapper = StringMapper.new
      raw_x_pct = mapper.percentize_modulus(str)
      raw_y_pct = mapper.percentize_modulus_exp(str)

      # mapper produces raw %'s 0..1.
      # figures that start out very close to a border often get trapped and
      # look strange, so we won't allow a starting point <30% or >70%.
      interp = Interpolate::Points.new(0 => 0.3, 1 => 0.7)

      x_pct = interp.at( raw_x_pct )
      y_pct = interp.at( raw_y_pct )

      Point.new(
        (x_pct * @bounds.x).to_i,
        (y_pct * @bounds.y).to_i
      )
    end

    # pick an angle for the next point
    # steer away from the corners by avoiding angles which tend toward the
    # corner we are currently closest to.
    #
    # current Point
    # x & y extents
    # percent : how far along the arc should we go?
    #  as a float 0..1
    #  always counter-clockwise.
    #
    # return: an angle from current point.
    def angle(current, percent)
      # the valid range of angles (to the next point)
      # based on the quadrant the current point is in.
      quad_to_range = {
        Quadrant::UPPER_LEFT  => 30..240,
        Quadrant::UPPER_RIGHT => 120..330,
        Quadrant::LOWER_LEFT  => 300..(330+180),
        Quadrant::LOWER_RIGHT => 210..(330+90)
      }

      quadrant = @bounds.quadrant(current)

      range = quad_to_range[quadrant]
      interp = Interpolate::Points.new({
        0 => range.begin,
        1 => range.end
      })

      interp.at(percent).to_i % 360
    end

    # what is the distance from point to extent, along a line of degrees angle
    def distance_to_boundary(point, degrees)
      degrees %= 360

      case degrees
        when 0 then
          point.x

        when 1..89 then
          to_top = aas(90-degrees, 90, point.y)
          to_right = aas(degrees, 90, @bounds.x - point.x)
          [to_top, to_right].min

        when 90 then
          @bounds.x - point.x

        when 91..179 then
          to_right = aas(180-degrees, 90, @bounds.x - point.x)
          to_bottom = aas(90-180-degrees, 90, @bounds.y - point.y)
          [to_right, to_bottom].min

        when 180 then
          @bounds.y - point.y

        when 181..269 then
          to_bottom = aas(90-degrees-180, 90, @bounds.y - point.y)
          to_left = aas(degrees - 180, 90, point.x)
          [to_bottom, to_left].min

        when 270 then
          point.x

        when 271..359 then
          to_left = aas(360-degrees, 90, point.x)
          to_top = aas(90-360-degrees, 90, point.y)
          [to_left, to_top].min

      end
    end

    def next_point(point, angle, distance)
      # geometry black magic here. still not positive exactly why this works.
      # unit circle begins at 90 and goes counterclockwise.
      # we want to start at 0 and go clockwise
      # orientation of 0 degrees to coordinate space probably matters also.
      theta = (180 - angle) % 360

      Point.new(
        (Math.sin(deg2rad(theta)) * distance + point.x).round,
        (Math.cos(deg2rad(theta)) * distance + point.y).round
      )
    end

    def deg2rad(degrees)
      degrees * Math::PI / 180
    end

    def rad2deg(radians)
      radians * 180 / Math::PI
    end

    # angle, angle, side
    # A / sin(a) == B / sin(b)
    # return length of side_B
    def aas(angle_a, angle_b, side_A)
      side_A / Math.sin(deg2rad(angle_a)) * Math.sin(deg2rad(angle_b))
    end

  end
end
