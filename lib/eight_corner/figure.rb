module EightCorner

  # a Figure is 8 connected points
  class Figure

    attr_accessor :points
    def initialize
      @points = []
    end

    # an overall potential based on the points in this figure
    # for use as an input for another Base#plot
    def potential
      points.last.potential
    end

  end
end
