require 'eight_corner/string_mapper'
include EightCorner

describe StringMapper do
  let(:subject) {StringMapper.new}

  describe "group1" do
    it "should return 3-string groups for short strings" do
      str = 'something'
      expect(subject.group1(str, 0)).to eq('som')
      expect(subject.group1(str, 1)).to eq('eth')
      expect(subject.group1(str, 2)).to eq('ing')
      expect(subject.group1(str, 3)).to eq('som')
      expect(subject.group1(str, 4)).to eq('eth')
      expect(subject.group1(str, 5)).to eq('ing')
      expect(subject.group1(str, 6)).to eq('som')
    end

    it "should wrap around to beginning" do
      # 'alex deanalex deanale'
      #                    ^^^
      #  0  1  2  3  4  5  6

      expect(subject.group1('alex dean', 6)).to eq('ale')
    end

    it "should return larger groups for longer strings" do
      str = 'there are a bunch of characters in this string'

      expect(subject.group1(str, 0)).to eq('there ')
      expect(subject.group1(str, 1)).to eq('are a ')
      expect(subject.group1(str, 2)).to eq('bunch ')
      expect(subject.group1(str, 3)).to eq('of cha')
      expect(subject.group1(str, 4)).to eq('racter')
      expect(subject.group1(str, 5)).to eq('s in t')
      expect(subject.group1(str, 6)).to eq('his st')
    end
  end

  describe "group2" do
    it "should return each n-th character from the string" do
      # something something som
      # 012345601 234560123 456
      str = 'something'
      expect(subject.group2(str, 0)).to eq('snh')
      expect(subject.group2(str, 1)).to eq('ogi')
      expect(subject.group2(str, 2)).to eq('msn')
      expect(subject.group2(str, 3)).to eq('eog')
      expect(subject.group2(str, 4)).to eq('tms')
      expect(subject.group2(str, 5)).to eq('heo')
      expect(subject.group2(str, 6)).to eq('itm')
    end
  end
end


# strings will be of any length
# which percentages will be most interesting?