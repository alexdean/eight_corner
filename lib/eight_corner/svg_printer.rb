module EightCorner

  # print a figure or collection of figures as an svg document
  class SvgPrinter

    def initialize(incremental_colors: false)
      @incremental_colors = incremental_colors
    end

    def svg(width, height)
      out = "<svg xmlns='http://www.w3.org/2000/svg' version='1.1' width='#{width}' height='#{height}'>\n"
      out += yield(self)
      out += '</svg>'

      out
    end

    def print(points)
      svg do
        @incremental_colors ? incremental_colors(points) : solid(points)
      end
    end

    def draw(figure,
        x_offset: 0,
        y_offset: 0,
        width: 200,
        height: 200,
        show_border: false,
        mark_initial_point: false,
        label: nil,
        style: :solid
      )


      raise ArgumentError, "invalid :style" if ! respond_to?(style)

      points = figure.points

      out = "<g transform='translate(#{x_offset}, #{y_offset})'>"
      if show_border
        out += "<rect width='#{width}' height='#{height}' style='stroke:black; stroke-width:1; fill:none'></rect>"
      end
      out += send(style, points)
      if mark_initial_point
        out += point(points[0].x, points[0].y, 5, '#ff0000')
      end
      if label
        out += "<text x='5' y='#{height-5}' style='font-family: sans-serif'>#{label}</text>"
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
