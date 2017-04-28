module EightCorner

  # This class is a catch-all. Will be cleaned up, you know, sometime.
  class Base
    def self.validate_options!(options, defaults)
      unknown_options = options.keys - defaults.keys
      if unknown_options.size > 0
        raise ArgumentError, "Unrecognized options: #{unknown_options.inspect}"
      end
    end

    def initialize(x_extent, y_extent, options={})
      defaults = {
        logger: Logger.new('/dev/null')
      }
      self.class.validate_options!(options, defaults)

      options = defaults.merge(options)

      @bounds = Bounds.new(x_extent, y_extent)
      @point_count = 8

      @log = options[:logger]
      # @figure_interdepencence = options[:figure_interdepencence]
    end

    def plot(str, options={})
      defaults = {
        start_method: :starting_point,
        # will the initial_potential, and potentials generated from previous
        # points in the same figure, be used to alter the angle to the next
        # point?
        point_interdependence: true,
        # 0.5 is 'no change' see angle_potential_interp
        initial_potential: 0.5
      }
      self.class.validate_options!(options, defaults)
      options = defaults.merge(options)

      mapper = StringMapper.new(group_count: @point_count-1)
      # 7 2-element arrays. each value is a float 0..1.
      potentials = mapper.potentials(str)

      # the figure we are drawing.
      figure = Figure.new
      # set starting point.
      figure.points << starting_point(potentials.first)

      # a potential is a value derived from the previous point in a figure
      # these are used to modify the angle used to locate the next point in
      # the figure. in this way, previous figures add influence
      # which wouldn't be present if the figure were drawn on its own.
      #   - median potential (0.5) changes nothing.
      #   - extremely low potential (0.0) moves the angle 15% counter-clockwise
      #   - extremely high potential (1.0) moves the angle 15% clockwise
      angle_potential_interp = Interpolate::Points.new(0.0 => -0.15, 0.5 => 0.0, 1.0 => 0.15)

      # increase low distance potentials to encourage longer lines
      # this is added to the raw distance potential determined by the string mapper.
      #   - a distance_pct of 0 will have 0.3 added to it.
      #   - a distance_pct of 0.5 or greater will have nothing added to it.
      additional_distance_interp = Interpolate::Points.new(0.0 => 0.3, 0.5 => 0.0)

      previous_potential = options[:initial_potential]

      (@point_count - 1).times do |i|
        current_point = figure.points[i]

        # TODO encourage more open angles?
        angle_pct = potentials[i][0]
        distance_pct = potentials[i][1]

        @log.debug(['angle_pct', angle_pct])

        # if points can influence each other, apply potential from previous
        # point to the angle-selection process.
        if options[:point_interdependence]
          angle_pct_adjustment = angle_potential_interp.at(previous_potential)
          @log.debug(['angle_pct_adjustment', angle_pct_adjustment])

          @log.debug(['pre-ajustment', angle_pct, angle(current_point, angle_pct)])
          angle_pct += angle_pct_adjustment
          @log.debug(['post-ajustment', angle_pct, angle(current_point, angle_pct)])
        end

        angle_to_next = angle(current_point, angle_pct)
        dist_to_boundary = distance_to_boundary(current_point, angle_to_next)

        @log.debug(['angle_to_next', angle_to_next])
        @log.debug(['distance_to_boundary', dist_to_boundary])

        # if we're too close to the edge, go the opposite direction.
        # so we don't get trapped in a corner.
        if dist_to_boundary <= 1
          @log.debug('dist_to_boundary is close to border. adjust angle.')

          angle_to_next += 180
          angle_to_next %= 360
          dist_to_boundary = distance_to_boundary(current_point, angle_to_next)

          @log.debug(['after 180: angle_to_next', angle_to_next])
          @log.debug(['after 180: distance_to_boundary', dist_to_boundary])
        end

        # how to encourage more space-filling?
        # track how many points are in each quadrant.
        # if current point is in the most-populated one, move to least-populated.
        # if current point and previous point are too close together...
        # if current point and last point are in different quadrants...


        distance_pct += additional_distance_interp.at(distance_pct)

        # longer lines fill space better
        distance_pct = 0.3 if distance_pct < 0.3
        # keep away from bounds.
        distance_pct = 0.9 if distance_pct > 0.9

        distance = dist_to_boundary * distance_pct

        next_point = next_point(
          current_point,
          angle_to_next,
          distance
        )
        next_point.angle_pct = angle_pct
        next_point.distance_pct = distance_pct
        next_point.created_by_potential = previous_potential

        # TODO: how do we create invalid points?
        # some bug in distance_to_boundary, most likely.
        if ! next_point.valid?
          if next_point.x < 0
            next_point.x = 0
          end
          if next_point.y < 0
            next_point.y = 0
          end

          @log.error "point produced invalid next. '#{str}' #{i}"
          @log.error(['angle_to_next', angle_to_next])
          @log.error(['distance_to_boundary', dist_to_boundary])
          @log.error(['next_point', next_point])
        end

        figure.points << next_point
        previous_potential = figure.points.last.potential
      end

      figure
    end

    # return a starting point for string
    def starting_point(str)
      mapper = StringMapper.new

      raw_x_pct, raw_y_pct = mapper.potential_pair(str)

      # mapper produces raw %'s 0..1.
      # figures that start out very close to a border often get trapped and
      # look strange, so we won't allow a starting point <30% or >70%.
      interp = Interpolate::Points.new(0 => 0.2, 1 => 0.8)

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
      range = Quadrant.angle_range_for(@bounds.quadrant(current))
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

    def next_point(last_point, angle, distance)
      # geometry black magic here. still not positive exactly why this works.
      # unit circle begins at 90 and goes counterclockwise.
      # we want to start at 0 and go clockwise
      # orientation of 0 degrees to coordinate space probably matters also.
      theta = (180 - angle) % 360

      point = Point.new
      point.x = (Math.sin(deg2rad(theta)) * distance + last_point.x).round
      point.y = (Math.cos(deg2rad(theta)) * distance + last_point.y).round
      point.distance_from_last = distance
      point.angle_from_last = angle
      point.bounds = @bounds
      point
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
