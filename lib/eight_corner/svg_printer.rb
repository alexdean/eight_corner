module EightCorner

  # print a figure or collection of figures as an svg document
  class SvgPrinter

    def initialize(options={})
      options[:incremental_colors] ||= false

      @options = options
    end

    def svg(width, height)
      out = "<svg xmlns='http://www.w3.org/2000/svg' version='1.1' width='#{width}' height='#{height}'>\n"
      out += yield(self)
      out += '</svg>'

      out
    end

    def print(points)
      svg do
        @options[:incremental_colors] ? incremental_colors(points) : solid(points)
      end
    end

    def draw(figure, options={})
      points = figure.points
      options[:method] ||= :solid
      raise ArgumentError, "invalid :method" if ! respond_to?(options[:method])

      options[:x_offset] ||= 0
      options[:y_offset] ||= 0
      options[:width] ||= 200
      options[:height] ||= 200
      options[:show_border] ||= false
      options[:mark_initial_point] ||= false

      out = "<g transform='translate(#{options[:x_offset]}, #{options[:y_offset]})'>"
      if options[:show_border]
        out += "<rect width='#{options[:width]}' height='#{options[:height]}' style='stroke:black; stroke-width:1; fill:none'></rect>"
      end
      out += send(options[:method], points)
      if options[:mark_initial_point]
        out += point(points[0].x, points[0].y, 10, '#ff0000')
      end

      out += "</g>\n"
      out
    end

    def solid(points)
      out = '<polygon points="'
      out += points.map{|p| "#{p.x},#{p.y}"}.join(' ')
      out += '" style="fill:none; stroke:black; stroke-width:4"/>'
      out
    end

    def incremental_colors(points, options={})
      out = ''
      interp = Interpolate::Points.new(1 => 0, (points.size-1) => 12)
      1.upto(points.size-1) do |i|
        prev = points[i-1]
        curr = points[i]

        hex_str = interp.at(i).to_i.to_s(16) * 6
        out += line(prev, curr,  hex_str)
      end
      out += line(points.last, points.first, interp.at(points.size-1).to_i.to_s(16) * 6)
      out
    end

    def line(from, to, color)
      "<line x1='#{from.x}' y1='#{from.y}' x2='#{to.x}' y2='#{to.y}' style='stroke:##{color}; stroke-width:4'/>\n"
    end

    def point(x, y, r, color)
      "<circle cx='#{x}' cy='#{y}' r='#{r}' fill='#{color}' stroke='none' />"
    end

  end
end
