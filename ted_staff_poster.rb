require 'eight_corner'
require 'csv'

### TUNABLES

width = 2550
height = 3300 # kinda deceptive. doc will be cut off at this point if the number
              # of figures warrants. figs will not be fit into this amount of
              # vertical space. (they're given square spaces based on width.)
cols = 11

x_margin = 150
y_margin = 150

figure_x_margin = 5
figure_y_margin = 5

log = Logger.new($stderr)
log.level = Logger::INFO

figure_interdependence = false

### OK, STOP TUNING NOW.



figure_width = (width - (x_margin * 2) - (cols * figure_x_margin * 2)) / cols
figure_height = figure_width

base = EightCorner::Base.new(
  figure_width,
  figure_height,
  logger: log
)
printer = EightCorner::SvgPrinter.new


data = CSV.read('ted_staff.csv', headers: true)
figure_count = data.size

# try to center-ish the last row of figures
figures_in_last_row = figure_count % cols
last_row_starts_at = figure_count - figures_in_last_row
width_of_last_row_data = (figure_width + (figure_x_margin * 2)) * figures_in_last_row
unoccupied_last_row_space = width - x_margin*2 - width_of_last_row_data
pixel_offset_in_last_row = unoccupied_last_row_space / 2

# this is necessary to make the last row center properly.
# which means i have a math error in here somewhere...
# pixel_offset_in_last_row += 30

svg = printer.svg(width, height) do |p|
  idx = 0
  out = ''
  previous_figure = nil

  data.each do |data|
    log.debug ['data', data.inspect]

    out += "<!-- #{data['full']} -->\n"

    previous_potential = previous_figure.nil? ? 0.5 : previous_figure.potential
    previous_potential = 0.5 if figure_interdependence == false
    # puts "#{data['full']}\t#{previous_potential}"

    figure = base.plot(data['full'].to_s,
      point_interdependence: true,
      initial_potential: previous_potential
    )

    log.debug ['points', figure.points.inspect]


    col = idx % cols
    figure_x_origin = figure_width * col + (figure_x_margin * col * 2) + x_margin
    # try to center-ish the last row of figures
    if idx >= last_row_starts_at
      figure_x_origin += pixel_offset_in_last_row
    end



    row = idx/cols
    figure_y_origin = figure_height * row + (figure_y_margin * row * 2) + y_margin

    out += p.draw(figure,
      # show_border: true,
      # mark_initial_point: true,
      # method: :incremental_colors,
      # label: data['full'],
      # label: data['full'][0..5] +' '+previous_potential.to_s[0..10],
      # method: :solid,
      x_offset: figure_x_origin,
      y_offset: figure_y_origin,
      width: figure_width,
      height: figure_height
    )
    idx += 1

    previous_figure = figure
  end
  out
end

# filename = File.basename(__FILE__, '.rb')
filename = "output"

svg_filename = "#{filename}.svg"
File.open(svg_filename, 'w') {|f| f.write svg }

`open -a Firefox #{svg_filename}`
