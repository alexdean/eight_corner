module EightCorner

  # StringMapper provides various methods for converting strings to
  # percentage/potential values, which can then be mapped to (x,y) points.
  #
  # a 'potential' is a percentage (in range 0..1) which can be applied to
  # some range of possible values. examples include applying a potential
  # to a range of possible angles, or a range of possible distances, to compute
  # an actual (x,y) point.
  class StringMapper

    def initialize(options={})
      defaults = {
        group_count: 7,
        min_group_size: 3
      }
      Base.validate_options!(options, defaults)
      options = defaults.merge(options)

      @group_count = options[:group_count]
      @group_max_idx = @group_count - 1
      @min_group_size = options[:min_group_size]
    end

    # break a string into groups and return a set of potentials for each group
    #
    # @param [String] a string to be potentialized
    # @return [Array<Array>] an array of arrays, each containing 2 floats
    #   in the range 0..1. The number of elements in the array is governed by
    #   the @group_count.
    def potentials(string)
      groups = groups(string)

      out = []
      max = (16**32).to_f # largest possible 32-char hex string value

      groups.each do |group|
        digest = Digest::SHA256.hexdigest(group)
        out << [
          potentialize_hex_string(digest.slice(0,32), max: max),
          potentialize_hex_string(digest.slice(32,32), max: max)
        ]
      end

      out
    end

    # convert a hex string into a percentage of the supplied max value
    #
    # @return [Float] float in the range 0..1.
    def potentialize_hex_string(hex_string, max:)
      int = hex_string.to_i(16)
      (int / max).round(2)
    end

    # split a string into groups
    def groups(str)
      # raise ArgumentError, "Invalid method #{arg}" if ! respond_to?(method)

      out = []
      @group_count.times do |i|
        out << compute_group(str, i)
      end
      out
    end

    # builds a group from every nth character in the string.
    def compute_group(str, idx)
      str_size = str.size

      out = ''
      group_size(str).times do |i|
        out += str[(i * @group_count + idx) % str_size]
      end
      out
    end

    # how many characters should be in each group?
    def group_size(str)
      [
        str.size / @group_count,
        @min_group_size
      ].max
    end
  end
end
