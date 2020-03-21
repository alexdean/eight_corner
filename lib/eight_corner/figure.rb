module EightCorner

  # a Figure is 8 connected points
  class Figure
    attr_reader :text, :points

    # @param [String] text a text string that this figure will represent
    # @param [Integer] point_count the number of points this figure will have
    # @param [Float] initial_potential a value which will influence how the
    #   points are plotted, in the range 0..1.
    # @param [EightCorner::Bounds] bounds a Bounds object to contain the figure
    # @param [Integer] minimum_angle The minimum number of degrees in each angle
    #   in the figure.
    #
    # ## minimum_angle
    #
    # @see normalize_bearing
    #
    #   Each angle is formed at the intersection (at current point) from:
    #
    #     * the previous bearing (previous point -> current point)
    #     * and the current bearning (current point -> next point)
    def initialize(text,
      logger: nil,
      point_count: 8,
      initial_potential: 0.5,
      bounds: nil,
      minimum_angle: 20
    )
      @text = text
      @points = []
      @point_count = point_count
      @initial_potential = initial_potential
      @log = logger || Logger.new('/dev/null')
      @bounds = bounds || Bounds.new(100, 100)
      @minimum_angle = minimum_angle

      plot
    end

    def as_json
      points.map(&:as_json)
    end

    def plot
      mapper = StringMapper.new(group_count: @point_count-1)
      # 7 2-element arrays. each value is a float 0..1.
      potentials = mapper.potentials(@text)

      # set starting point.
      @points << starting_point(@text)

      @log.debug(['starting_point', @points[0]])

      # a potential is a value derived from the previous point in a figure
      # these are used to modify the bearing used to locate the next point in
      # the figure. in this way, previous figures add influence
      # which wouldn't be present if the figure were drawn on its own.
      #   - median potential (0.5) changes nothing.
      #   - extremely low potential (0.0) moves the bearing 15% counter-clockwise
      #   - extremely high potential (1.0) moves the bearing 15% clockwise
      # Interpolate::Points.new(0.0 => 0, 1.0 => 0)
      bearing_potential_interp = Interpolate::Points.new(0.0 => 0, 1.0 => 0) # Interpolate::Points.new(0.0 => -0.15, 0.5 => 0.0, 1.0 => 0.15)

      # increase low distance potentials to encourage longer lines
      # this is added to the raw distance potential determined by the string mapper.
      #   - a distance_pct of 0 will have 0.3 added to it.
      #   - a distance_pct of 0.5 or greater will have nothing added to it.
      additional_distance_interp = Interpolate::Points.new(0.0 => 0.3, 0.5 => 0.0)

      previous_potential = @initial_potential

      (@point_count - 1).times do |i|
        current_point = @points[i]

        # TODO encourage more open bearings?
        bearing_pct = potentials[i][0]
        distance_pct = potentials[i][1]

        @log.debug(['bearing_pct', bearing_pct])

        bearing_pct_adjustment = bearing_potential_interp.at(previous_potential)
        @log.debug(['bearing_pct_adjustment', bearing_pct_adjustment])

        @log.debug(['pre-ajustment', bearing_pct, bearing(current_point, bearing_pct)])
        bearing_pct += bearing_pct_adjustment
        @log.debug(['post-ajustment', bearing_pct, bearing(current_point, bearing_pct)])

        bearing_to_next = normalize_bearing(
                            bearing(current_point, bearing_pct),
                            bearing_from_previous: current_point.bearing_from_previous,
                            minimum_angle: @minimum_angle
                          )

        dist_to_boundary = distance_to_boundary(current_point, bearing_to_next)

        @log.debug(['bearing_to_next', bearing_to_next])
        @log.debug(['distance_to_boundary', dist_to_boundary])

        # if we're too close to the edge, go the opposite bearing.
        # so we don't get trapped in a corner.
        if dist_to_boundary <= 1
          @log.debug('dist_to_boundary is close to border. adjust bearing.')

          bearing_to_next += 180
          bearing_to_next %= 360
          dist_to_boundary = distance_to_boundary(current_point, bearing_to_next)

          @log.debug(['after 180: bearing_to_next', bearing_to_next])
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
          bearing_to_next,
          distance
        )
        next_point.bearing_pct = bearing_pct
        next_point.distance_pct = distance_pct
        next_point.created_by_potential = previous_potential

        # TODO: how do we create invalid points?
        # some bug in distance_to_boundary, most likely.
        if ! next_point.valid?
          @log.error "point produced invalid next. '#{@text}' #{i}"
          @log.error ['invalid next_point', next_point]
          @log.error(['bearing_to_next', bearing_to_next])
          @log.error(['distance', distance])
          @log.error(['distance_to_boundary', dist_to_boundary])

          if next_point.x < 0
            next_point.x = 0
          end
          if next_point.y < 0
            next_point.y = 0
          end
          if next_point.x > @bounds.x
            next_point.x = @bounds.x
          end
          if next_point.y > @bounds.y
            next_point.y = @bounds.y
          end

          @log.error(['adjusted next_point', next_point])
        end

        @points << next_point
        previous_potential = @points.last.potential
      end
    end

    # an overall potential based on the points in this figure
    # for use as an input for another #plot
    def potential
      points.last.potential
    end

    # return a starting point for string
    def starting_point(str)
      mapper = StringMapper.new

      raw_x_pct, raw_y_pct = mapper.potential_pair(str)

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

    # pick a bearing for the next point
    # steer away from the corners by avoiding bearings which tend toward the
    # corner we are currently closest to.
    #
    # current Point
    # x & y extents
    # percent : how far along the arc should we go?
    #  as a float 0..1
    #  always counter-clockwise.
    #
    # return: an bearing from current point.
    def bearing(current, percent)
      range = Quadrant.bearing_range_for(@bounds.quadrant(current))
      interp = Interpolate::Points.new({
        0 => range.begin,
        1 => range.end
      })

      interp.at(percent).to_i % 360
    end

    # adjust extremely large or small changes in direction, which don't look as nice
    #
    # the turns being adjusted are either close to the previous bearing, or
    # to the reciprocal of that bearing (returning to the previous point).
    #
    # @param [Integer] current A bearing which might need adjustment range: 0..359.
    # @param [Integer] bearing_from_previous The bearing from the previous point
    #   to the current point. (The reciprocal of this bearing would lead from
    #   the current point back to the previous point.) range: 0..359.
    # @param [Integer] minimum_angle Adjust any angle (formed from the 2 bearings)
    #   which is less than this number of degrees. range: 0..180.
    # @return [Integer] current, or a modified version of current which forms at
    #   least a minimum_angle.
    def normalize_bearing(current, bearing_from_previous:, minimum_angle:)
      previous = bearing_from_previous

      return current if !previous

      # this bearing would lead back to the previous point.
      reciprocal_of_previous = (previous - 180) % 360

      delta_left = (previous - current) % 360
      delta_right = (current - previous) % 360

      delta_reciprocal_left = (current - reciprocal_of_previous) % 360
      delta_reciprocal_right = (reciprocal_of_previous - current) % 360

      delta = delta_left
      delta_reciprocal = delta_reciprocal_left

      @log.debug "current:#{current}, previous:#{previous}, reciprocal_of_previous:#{reciprocal_of_previous}" \
        " delta_left:#{delta_left}, delta_right:#{delta_right}, delta_reciprocal_left:#{delta_reciprocal_left}" \
        " delta_reciprocal_right:#{delta_reciprocal_right}"

      # too acute
      # if delta >= 0 && delta < minimum_angle
      if delta_left < minimum_angle
        current = previous - minimum_angle
        @log.debug "current adjusted to #{current}. (too-small left)"
      # too acute
      # elsif delta > (-1 * minimum_angle) && delta <= 0
      elsif delta_right < minimum_angle
        current = previous + minimum_angle
        @log.debug "current adjusted to #{current}. (too-small right)"
      # too obtuse
      # elsif delta_reciprocal >= 0 && delta_reciprocal < minimum_angle
      elsif delta_reciprocal_left < minimum_angle
        current = reciprocal_of_previous + minimum_angle
        @log.debug "current adjusted to #{current}. (too-large left)"
      # too obtuse
      # elsif delta_reciprocal > (-1 * minimum_angle) && delta_reciprocal <= 0
      elsif delta_reciprocal_right < minimum_angle
        current = reciprocal_of_previous - minimum_angle
        @log.debug "current adjusted to #{current}. (too-large right)"
      else
        @log.debug "current not adjusted. (5)"
      end

      current % 360
    end

    # Find the distance from a point to the boundary along a given bearing.
    #
    # @param [Point] starting_point The point to start from.
    # @param [Integer] bearing The bearing to travel from the starting point.
    # @return [Float] Distance from starting_point to boundary when travelling
    #   along the given bearning.
    def distance_to_boundary(starting_point, bearing)
      bearing %= 360

      case bearing
        when 0 then
          starting_point.x

        when 1..89 then
          to_top = aas(90-bearing, 90, starting_point.y)
          to_right = aas(bearing, 90, @bounds.x - starting_point.x)
          [to_top, to_right].min

        when 90 then
          @bounds.x - starting_point.x

        when 91..179 then
          to_right = aas(180-bearing, 90, @bounds.x - starting_point.x)
          to_bottom = aas(90-180-bearing, 90, @bounds.y - starting_point.y)
          [to_right, to_bottom].min

        when 180 then
          @bounds.y - starting_point.y

        when 181..269 then
          to_bottom = aas(90-bearing-180, 90, @bounds.y - starting_point.y)
          to_left = aas(bearing - 180, 90, starting_point.x)
          [to_bottom, to_left].min

        when 270 then
          starting_point.x

        when 271..359 then
          to_left = aas(360-bearing, 90, starting_point.x)
          to_top = aas(90-360-bearing, 90, starting_point.y)
          [to_left, to_top].min

      end
    end

    # @param [Point] last_point the point to start from
    # @param [Float] bearing the bearing to travel at, in compass degrees
    # @param [Integer] distance how far to travel along the given bearing
    # @return [Point] a new point which is the given distance away from
    #   last_point, along the given bearing. x and y are rounded to nearest
    #   integers
    def next_point(last_point, bearing, distance)
      unit_degrees = compass2unit(bearing)
      radians = deg2rad(unit_degrees)

      point = Point.new
      point.x = (Math.cos(radians) * distance + last_point.x).round
      # for the unit circle, (0,0) is in the center, and going up means increasing y.
      # but our origin is in the upper-left, and going up means reducing y instead.
      # thus we need to invert the computed (unit-circle-based) y value
      point.y = (Math.sin(radians) * -1 * distance + last_point.y).round
      point.distance_from_last = distance
      point.bearing_from_previous = bearing
      point.bounds = @bounds
      point
    end

    private

    # convert compass degrees to unit circle degrees
    #
    # compass degrees start at 0 (at top) and go clockwise.
    # unit circle starts at x-axis (90 degrees on the compass) and goes counterclockwise.
    #
    # @param [Integer] compass_degrees A bearing in compass degrees
    # @return [Integer] A bearing in unit circle degrees
    def compass2unit(compass_degrees)
      ((compass_degrees - 360).abs + 90) % 360
    end

    def deg2rad(degrees)
      degrees * Math::PI / 180
    end

    # TODO: remove. unused.
    def rad2deg(radians)
      radians * 180 / Math::PI
    end

    # bearing, bearing, side
    # A / sin(a) == B / sin(b)
    # return length of side_B
    def aas(bearing_a, bearing_b, side_A)
      side_A / Math.sin(deg2rad(bearing_a)) * Math.sin(deg2rad(bearing_b))
    end
  end
end
