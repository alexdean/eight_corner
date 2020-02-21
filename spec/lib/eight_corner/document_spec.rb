require 'spec_helper'
require 'eight_corner'
include EightCorner

RSpec.describe EightCorner::Document do
  describe 'constructor' do
    describe 'when given a single string' do
      it 'generates a single figure' do
        document = EightCorner::Document.new('abc')
        expect(document.figures.size).to eq 1

        expect(document.figures.map(&:class).uniq).to eq([EightCorner::Figure])
      end
    end

    describe 'when given an array of strings' do
      it 'generates a figure for each string' do
        input_array = ['abc', 'def', 'ghi']

        document = EightCorner::Document.new(input_array)
        expect(document.figures.size).to eq input_array.size

        expect(document.figures.map(&:class).uniq).to eq([EightCorner::Figure])
      end
    end
  end
end
