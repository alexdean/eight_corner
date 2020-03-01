require 'spec_helper'
require 'eight_corner'
include EightCorner

describe Figure do
  let(:subject) do
    Figure.new('text',
      bounds: Bounds.new(10, 10),
      # for debugging...
      # logger: Logger.new($stdout, level: Logger::DEBUG)
    )
  end

  describe "next_point" do
    it "should return a new point" do
      center = Point.new(5, 5)

      expect(
        subject.next_point(center,   0, 2)
      ).to eq (Point.new(5, 3))

      expect(
        subject.next_point(center,  45, 2)
      ).to eq (Point.new(6, 4))

      expect(
        subject.next_point(center,  90, 2)
      ).to eq (Point.new(7, 5))

      expect(
        subject.next_point(center, 135, 2)
      ).to eq (Point.new(6, 6))

      expect(
        subject.next_point(center, 180, 2)
      ).to eq (Point.new(5, 7))

      expect(
        subject.next_point(center, 225, 2)
      ).to eq (Point.new(4, 6))

      expect(
        subject.next_point(center, 270, 2)
      ).to eq (Point.new(3, 5))

      expect(
        subject.next_point(center, 315, 2)
      ).to eq (Point.new(4, 4))

      expect(
        subject.next_point(center, 360, 2)
      ).to eq (Point.new(5, 3))
    end
  end

  describe "bearing" do
    it 'should always return an integer'
    # D, [2014-08-09T16:09:53.857347 #12486] DEBUG -- : ["current", #<EightCorner::Point:0x007fcfd427d7f0 @x=10, @y=78>]
    # D, [2014-08-09T16:09:53.857372 #12486] DEBUG -- : ["bearing_to_next", 180.9]
    # D, [2014-08-09T16:09:53.857394 #12486] DEBUG -- : ["distance_to_boundary", nil]
  end

  describe '#normalize_bearing' do
    it 'adjusts a too-small left-handed turn' do
      expect(
        subject.normalize_bearing(355, bearing_from_previous: 0, minimum_angle: 10)
      ).to eq 350

      expect(
        subject.normalize_bearing(175, bearing_from_previous: 180, minimum_angle: 10)
      ).to eq 170
    end

    it 'adjusts an unchanged bearing' do
      expect(
        subject.normalize_bearing(0, bearing_from_previous: 0, minimum_angle: 10)
      ).to eq 350

      expect(
        subject.normalize_bearing(180, bearing_from_previous: 180, minimum_angle: 10)
      ).to eq 170
    end

    it 'adjusts a too-small right-handed turn' do
      expect(
        subject.normalize_bearing(5, bearing_from_previous: 0, minimum_angle: 10)
      ).to eq 10

      expect(
        subject.normalize_bearing(185, bearing_from_previous: 180, minimum_angle: 10)
      ).to eq 190
    end

    it 'adjusts a too-large left-handed turn' do
      expect(
        subject.normalize_bearing(185, bearing_from_previous: 0, minimum_angle: 10)
      ).to eq 190

      expect(
        subject.normalize_bearing(5, bearing_from_previous: 180, minimum_angle: 10)
      ).to eq 10
    end

    it 'adjusts a reciprocal bearing' do
      expect(
        subject.normalize_bearing(180, bearing_from_previous: 0, minimum_angle: 10)
      ).to eq 190

      expect(
        subject.normalize_bearing(0, bearing_from_previous: 180, minimum_angle: 10)
      ).to eq 10
    end

    it 'adjusts a too-large right-handed turn' do
      expect(
        subject.normalize_bearing(175, bearing_from_previous: 0, minimum_angle: 10)
      ).to eq 170

      expect(
        subject.normalize_bearing(355, bearing_from_previous: 180, minimum_angle: 10)
      ).to eq 350
    end
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

  describe 'compass2unit' do
    it 'should convert compass degrees to unit circle degrees' do
      subjects = {
          0 =>  90,
         30 =>  60,
         60 =>  30,
         90 =>   0,
        120 => 330,
        150 => 300,
        180 => 270,
        210 => 240,
        240 => 210,
        270 => 180,
        300 => 150,
        330 => 120,
        360 =>  90
      }

      subjects.each do |compass_degrees, unit_degrees|
        expect(subject.send(:compass2unit, compass_degrees)).to eq unit_degrees
      end
    end
  end
end
