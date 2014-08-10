require 'eight_corner'
require 'csv'

width = 3300
height = 5100
cols = 9

x_margin = 100
y_margin = 200

figure_x_margin = 10
figure_y_margin = 10


figure_width = (width - (x_margin * 2) - (cols - 1) * figure_x_margin) / cols
figure_height = figure_width



log = Logger.new($stderr)
log.level = Logger::INFO

base = EightCorner::Base.new(figure_width, figure_height, logger: log)
printer = EightCorner::SvgPrinter.new


data = CSV.read('ted_staff.csv', headers: true)
row_count = data.size

figures_in_last_row = row_count % cols
col_offset_in_last_row = (cols - figures_in_last_row) / 2

last_row_starts_at = row_count - figures_in_last_row

svg = printer.svg(width, height) do |p|
  out = ''

  idx = 0

  data.each do |row|
    log.debug ['row', row.inspect]

    out += "<!-- #{row['full']} -->\n"
    figure = base.plot(row['full'].to_s)

    log.debug ['points', figure.points.inspect]


    col = idx % cols
    # try to center-ish the last row of figures
    if idx >= last_row_starts_at
      col += col_offset_in_last_row
    end

    figure_x_origin = figure_width * col + figure_x_margin * col + x_margin

    row = idx/cols
    figure_y_origin = figure_height * row + figure_y_margin * row + y_margin

    out += p.draw(figure,
      show_border: true,
      mark_initial_point: true,
      method: :incremental_colors,
      # method: :solid,
      x_offset: figure_x_origin,
      y_offset: figure_y_origin,
      width: figure_width,
      height: figure_height
    )
    idx += 1
  end
  out
end

filename = File.basename(__FILE__, '.rb')

svg_filename = "#{filename}.svg"
File.open(svg_filename, 'w') {|f| f.write svg }

`open -a Firefox #{svg_filename}`
