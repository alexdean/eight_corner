module EightCorner
  class Document
    attr_reader :potential, :figures

    # param [Array<String>] figure_texts Strings which should be converted into
    #   figures.
    def initialize(figure_texts, figure_width: 100, figure_height: 100, logger: nil, initial_potential: 0.5)
      # TODO: receive ancestor potentials from previous versions of the document

      @figure_texts = Array(figure_texts)
      # calculate an overall potential
      p1, p2 = StringMapper.potential_pair(@figure_texts.join)
      @potential = (p1 + p2) % 1
      @initial_potential = initial_potential

      @logger = logger || Logger.new('/dev/null')

      @figures = []
      @bounds = Bounds.new(figure_width, figure_height)

      generate_figures
    end

    def generate_figures
      @figure_texts.each do |text|
        @figures << Figure.new(text,
          logger: @logger,
          point_count: 8,
          bounds: @bounds,
          initial_potential: @initial_potential
        )
      end
    end
  end
end
