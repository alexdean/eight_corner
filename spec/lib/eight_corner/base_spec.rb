require 'spec_helper'
require 'eight_corner'
include EightCorner

describe Base do
  let(:subject) {Base.new(10,10)}

  describe "next_point" do
    it "should work" do
      expect(
        subject.next_point(Point.new(3,3), 45, 2.8)
      ).to eq (Point.new(5,1))
    end
  end

  describe "angle" do
    it 'should always return an integer'
    # D, [2014-08-09T16:09:53.857347 #12486] DEBUG -- : ["current", #<EightCorner::Point:0x007fcfd427d7f0 @x=10, @y=78>]
    # D, [2014-08-09T16:09:53.857372 #12486] DEBUG -- : ["angle_to_next", 180.9]
    # D, [2014-08-09T16:09:53.857394 #12486] DEBUG -- : ["distance_to_boundary", nil]
  end

  describe "distance_to_boundary" do

    describe "for 0 degrees" do
      it "should return x" do
        expect(
          subject.distance_to_boundary(Point.new(5,6), 0)
        ).to eq(5)
      end
    end

    describe "between 1 and 89 degrees" do
      it "should return distance to top boundary when that is closest" do
        expect(
          subject.distance_to_boundary(Point.new(2,2), 45).round(4)
        ).to eq(2.8284)
      end
      it "should return distance to right boundary when that is closest" do
        expect(
          subject.distance_to_boundary(Point.new(9,5), 45).round(4)
        ).to eq(1.4142)
      end
      it "should return a value when hitting upper-right corner" do
        expect(
          subject.distance_to_boundary(Point.new(5,5), 45).round(4)
        ).to eq(7.0711)
      end
    end

    describe "for 90 degrees" do
      it "should return distance to right boundary" do
        expect(
          subject.distance_to_boundary(Point.new(1,1), 90)
        ).to eq(9)
      end
    end

    describe "for 91 to 179 degrees" do
      it "should return distance to right boundary when that is closest" do
        expect(
          subject.distance_to_boundary(Point.new(9,7), 135).round(4)
        ).to eq(1.4142)
      end
      it "should return distance to bottom boundary when that is closest" do
        expect(
          subject.distance_to_boundary(Point.new(3,8), 135).round(4)
        ).to eq(2.8284)
      end
      it "should return a value when hitting lower-right corner" do
        expect(
          subject.distance_to_boundary(Point.new(5,5), 135).round(4)
        ).to eq(7.0711)
      end
    end

    describe "for 180 degrees" do
      it "should return distance to bottom boundary" do
        expect(
          subject.distance_to_boundary(Point.new(5,7), 180)
        ).to eq(3)
      end
    end

    describe "for 181 to 269 degrees" do
      it "should return distance to bottom boundary when that is closest" do
        expect(
          subject.distance_to_boundary(Point.new(5,8), 225).round(4)
        ).to eq(2.8284)
      end
      it "should return distance to left boundary when that is closest" do
        expect(
          subject.distance_to_boundary(Point.new(2,5), 225).round(4)
        ).to eq(2.8284)
      end
      it "should return a value when hitting lower-left corner" do
        expect(
          subject.distance_to_boundary(Point.new(5,5), 225).round(4)
        ).to eq(7.0711)
      end
    end

    describe "for 270 degrees" do
      it "should return distance to left boundary" do
        expect(
          subject.distance_to_boundary(Point.new(3,7), 270)
        ).to eq(3)
      end
    end

    describe "for 271 to 359 degrees" do
      it "should return distance to left boundary when that is closest" do
        expect(
          subject.distance_to_boundary(Point.new(2,5), 315).round(4)
        ).to eq(2.8284)
      end
      it "should return distance to top boundary when that is closest" do
        expect(
          subject.distance_to_boundary(Point.new(5,2), 315).round(4)
        ).to eq(2.8284)
      end
      it "should return a value when hitting upper-left corner" do
        expect(
          subject.distance_to_boundary(Point.new(5,5), 315).round(4)
        ).to eq(7.0711)
      end
    end

  end

end
