# Eight Corner

Draw graphs inspired by Georg Nees' 8-corner graphics.

## Example

This code was used to create a poster representing the staff of TED Conferences
in 2014. There is a [blog post](https://www.deanspot.org/alex/2014/08/21/ted-eightcorner.html)
about this.

![TED Staff Poster](https://www.deanspot.org/assets/eightcorner/ted_staff_poster.png)

## Algorithm

  1. input is a string
  1. convert string into 8 2-element arrays. each element is a float
     in the range 0..1.
  1. compute a starting point from the string
  1. for each point element, plot the next point using the 2 floats
    1. 1st is a direction from the current point
    1. 2nd is a distance from the current point
  1. multiple figures in a single body of text may influence each other,
     meaning that ordering is significant.

## Components

  1. Map a string into 8 elements and a starting point.
  1. Compute (x,y) points from 8 elements and a starting point.
  1. Plot points to generate final graphic.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'eight_corner'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install eight_corner

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it ( https://github.com/alexdean/eight_corner/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
