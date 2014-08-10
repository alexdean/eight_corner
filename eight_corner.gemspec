# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'eight_corner/version'

Gem::Specification.new do |spec|
  spec.name          = "eight_corner"
  spec.version       = EightCorner::VERSION
  spec.authors       = ["Alex Dean"]
  spec.email         = ["alex@crackpot.org"]
  spec.summary       = %q{Library for generating abstract figures from text strings.}
  spec.description   = %q{Map text to graphic figures inspired by Georg Nees 'eight corner' project.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'interpolate'

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0.0"
  spec.add_development_dependency "guard", "~> 2.6.1"
  spec.add_development_dependency "guard-rspec", "~> 4.3.1"
  spec.add_development_dependency "ruby_gntp", "~> 0.3.4"
end
