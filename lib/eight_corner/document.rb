module EightCorner
  class Document
    attr_reader :potential

    def initialize(text, figure_separator: "\n")
      # TODO: receive ancestor potentials

      # calculate an overall potential
      p1, p2 = StringMapper.potential_pair(text)
      @potential = (p1 + p2) % 1

      # generate figures
    end

    def generate_figures

    end
  end
end
