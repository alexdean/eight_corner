module EightCorner

  # StringMapper provides various methods for converting strings to
  # percentage/potential values, which can then be mapped to (x,y) points.
  class StringMapper

    def initialize(options={})
      options[:group_count] ||= 7
      options[:min_group_size] ||= 3

      @group_count = options[:group_count]
      @group_max_idx = @group_count - 1
      @min_group_size = options[:min_group_size]

      @frequencies = {"E"=>0.103202, "A"=>0.095238, "R"=>0.092638, "N"=>0.087925, "O"=>0.075898, "S"=>0.065659, "L"=>0.064196, "I"=>0.046481, "T"=>0.040793, "H"=>0.03868, "C"=>0.038193, "D"=>0.03413, "M"=>0.033317, "B"=>0.023891, "G"=>0.023566, "Y"=>0.022103, "U"=>0.021615, "W"=>0.019178, "K"=>0.016252, "P"=>0.015602, "F"=>0.011539, "V"=>0.010889, "Z"=>0.010076, "J"=>0.003738, " "=>0.00195, "X"=>0.00195, "Q"=>0.000975}
    end

    # return an array of 2-float arrays.
    # provide method symbols for and percentizing method for constructing the 2 array elements.
    def potentials(groups, percentizeA, percentizeB)
      [percentizeA, percentizeB].each do |arg|
        raise ArgumentError, "Invalid method #{arg}" if ! respond_to?(arg)
      end

      out = []
      groups.each do |i|
        # puts send(groupA, str, i)
        out << [
          send(percentizeA, i),
          send(percentizeB, i),
        ]
      end

      out
    end

    # split a string into groups, via :method
    def groups(str, method)
      raise ArgumentError, "Invalid method #{arg}" if ! respond_to?(method)

      out = []
      @group_count.times do |i|
        out << send(method, str, i)
      end
      out
    end

    # sequential series of characters extracted from string.
    # loops back to beginning for short strings
    def group1(str, idx)
      range = 0..@group_max_idx
      return ArgumentError, "argument must be in #{range}" if ! range.include?(idx)

      str_size = str.size
      g_size = group_size str

      out = ""

      start_idx = (idx * g_size)
      end_idx = start_idx + g_size

      (start_idx...end_idx).each do |x|
        out += str[x % str_size]
      end

      out
    end

    # builds a group from every nth character in the string.
    def group2(str, idx)
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

    def percentize_modulus(str)
      # i+memo just to add some order-dependency. "alex" != "xela"
      (str.each_byte.inject(0){|memo,i| memo += i + memo; memo} % 100)/100.to_f
    end

    def percentize_modulus_exp(str)
      (str.each_byte.inject(0){|memo,i| memo += i^2 + memo; memo} % 100)/100.to_f
    end

    # turn a string into a float 0..1
    # a string with common letters should be near 0.5.
    # a string with uncommon letters should be near 0 or 1.
    def percentize_frequency(str)
      # letters aren't evenly distributed.
      # a string that has every letter once would add up to 1.

      # totally common: sum would be E*3

      common = @frequencies.first[1] * str.size

      sum = 0
      str.upcase.each_char {|c| sum += @frequencies[c].to_f }

      distance = common - sum # distance from common.

      # add or subtract from 0.5?
      # all letters are positive/negative based on order in frequency distribution.
      m = 1
      @frequencies.keys.each do |i|
        m *= -1
        break if str[0].upcase == i
      end

      interp = Interpolate::Points.new({0=>0, common=>0.5})
      pct_distance = interp.at(distance)
      # interpolate (0 .. common) => (0 .. 0.5)
      # multiply by m and add to 0.5

      pct_distance * m + 0.5
    end
  end
end
