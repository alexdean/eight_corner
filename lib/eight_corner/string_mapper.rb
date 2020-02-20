require 'digest/sha2'

module EightCorner

  # StringMapper provides various methods for converting strings to
  # percentage/potential values, which can then be mapped to (x,y) points.
  #
  # a 'potential' is a percentage (in range 0..1) which can be applied to
  # some range of possible values. examples include applying a potential
  # to a range of possible angles, or a range of possible distances, to compute
  # an actual (x,y) point.
  class StringMapper
    def self.potential_pair(str)
      digest = Digest::SHA256.hexdigest(str)
      max = (16**32).to_f # largest possible 32-char hex string value
      [
        hex_string_potential(digest.slice(0,32), max: max),
        hex_string_potential(digest.slice(32,32), max: max)
      ]
    end

    def self.hex_string_potential(hex_string, max:)
      int = hex_string.to_i(16)
      (int / max).round(2)
    end

    def initialize(group_count: 7, min_group_size: 3)
      @group_count = group_count
      @group_max_idx = @group_count - 1
      @min_group_size = min_group_size
    end

    # break a string into groups and return a set of potentials for each group
    #
    # @param [String] a string to be potentialized
    # @return [Array<Array>] an array of arrays, each containing 2 floats
    #   in the range 0..1. The number of elements in the array is governed by
    #   the @group_count.
    def potentials(string)
      groups(string).map { |g| potential_pair(g) }
    end

    def potential_pair(str)
      self.class.potential_pair(str)
    end

    # convert a hex string into a percentage of the supplied max value
    #
    # @return [Float] float in the range 0..1.
    def hex_string_potential(hex_string, max:)
      self.class.hex_string_potential(hex_string, max: max)
    end

    # split a string into groups
    def groups(str)
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
