module EightCorner

  # a Bounds has 4 quadrants.
  # TODO: singleton instance for each quadrant?
  # would allow each to return their own bearing_range_for.
  module Quadrant
    UPPER_LEFT  = 0
    UPPER_RIGHT = 1
    LOWER_RIGHT = 2
    LOWER_LEFT  = 3

    # the valid range of bearings (to the next point) for each quadrant.
    #
    # we try to steer away from the corners to prevent figures from getting
    # 'trapped' in a corner.
    def self.bearing_range_for(quadrant)
      {
        UPPER_LEFT  => 30..240,
        UPPER_RIGHT => 120..330,
        LOWER_LEFT  => 300..(330+180),
        LOWER_RIGHT => 210..(330+90)
      }[quadrant]
    end
  end
end
