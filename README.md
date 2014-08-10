# Sigils

Draw graphs inspired by Georg Nees' 8-corner graphics.

## Algorithm

  1. input is a string
  1. convert string into 8 2-element arrays. each element is a float
     in the range 0..1.
  1. compute a starting point from the string
  1. for each point element, plot the next point using the 2 floats
    1. 1st is a direction from the current point
    1. 2nd is a distance from the current point

## Components

  1. Map a string into 8 elements and a starting point.
  1. Compute (x,y) points from 8 elements and a starting point.
  1. Plot points to generate final graphic.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sigils'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sigils

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it ( https://github.com/[my-github-username]/sigils/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
