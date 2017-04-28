require 'eight_corner/string_mapper'
include EightCorner

describe StringMapper do
  let(:subject) {StringMapper.new}

  describe 'potentials' do
    it 'should potentialize a string' do
      expect(subject.potentials('something')).to eq([
        [0.97, 0.6],
        [0.59, 0.96],
        [0.44, 0.55],
        [0.71, 0.01],
        [0.31, 0.8],
        [0.78, 0.22],
        [0.9, 0.57]
      ])
    end
  end

  describe 'potential_pair' do
    it 'should compute a pair of potentials for a string' do
      expect(subject.potential_pair('something')).to eq([0.25, 0.26])
    end
  end

  describe 'hex_string_potential' do
    it 'should convert a hex string to a percentage' do
      expect(subject.hex_string_potential(0.to_s(16), max: 256)).to eq 0
      expect(subject.hex_string_potential(256.to_s(16), max: 256)).to eq 1
    end
  end

  describe 'groups' do
    it 'should split a string into groups of characters' do
      str = 'something'
      # every 8th character, see `compute_group` specs below
      expect(subject.groups(str)).to eq ["snh", "ogi", "msn", "eog", "tms", "heo", "itm"]
    end
  end

  describe "compute_group" do
    it "should return each n-th character from the string" do
      # something something som
      # 012345601 234560123 456
      str = 'something'
      expect(subject.compute_group(str, 0)).to eq('snh')
      expect(subject.compute_group(str, 1)).to eq('ogi')
      expect(subject.compute_group(str, 2)).to eq('msn')
      expect(subject.compute_group(str, 3)).to eq('eog')
      expect(subject.compute_group(str, 4)).to eq('tms')
      expect(subject.compute_group(str, 5)).to eq('heo')
      expect(subject.compute_group(str, 6)).to eq('itm')
    end
  end
end
