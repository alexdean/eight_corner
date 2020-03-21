require 'spec_helper'
require 'eight_corner'

RSpec.describe EightCorner::Point do
  subject { described_class.new(10, 20) }

  describe '#as_json' do
    it 'should encode the point as a 2-element array' do
      expect(subject.as_json).to eq([10, 20])
    end
  end
end
