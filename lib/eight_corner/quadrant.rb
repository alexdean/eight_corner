module EightCorner

  # a Bounds has 4 quadrants.
  # TODO: singleton instance for each quadrant?
  # would allow each to return their own angle_range_for.
  module Quadrant
    UPPER_LEFT  = 0
    UPPER_RIGHT = 1
    LOWER_RIGHT = 2
    LOWER_LEFT  = 3

    def self.angle_range_for(quad)
      # the valid range of angles (to the next point)
      # based on the quadrant the current point is in.
      {
        UPPER_LEFT  => 30..240,
        UPPER_RIGHT => 120..330,
        LOWER_LEFT  => 300..(330+180),
        LOWER_RIGHT => 210..(330+90)
      }[quad]
    end
  end
end