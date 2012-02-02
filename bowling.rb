require 'rspec'

class BowlingScore
  def initialize
    @frames = [Frame.new(1)]
  end

  def roll(pins)
    raise TooManyRollsError if game_over?
    current_frame.roll(pins)
    advance_frame if current_frame.completed? and !game_over? 
  end

  def score
    @frames.map {|frame| frame.score}.reduce(:+)
  end

private
  def current_frame
    @frames.last
  end

  def advance_frame
    new_frame = Frame.new(current_frame.frame_number + 1)
    current_frame.next_frame = new_frame
    @frames << new_frame
  end

  def game_over?
    current_frame.completed? and current_frame.tenth?
  end
end

class Frame
  attr_accessor :next_frame
  attr_reader :rolls, :roll1, :roll2, :pins, :frame_number

  def initialize(frame_number)
    @pins = @rolls = 0
    @frame_number = frame_number
  end

  def roll(pins)
    @pins += pins
    @roll1 = pins if @rolls == 0
    @roll2 = pins if @rolls == 1
    @rolls += 1
  end

  def score
    return @pins if tenth?
    score = @pins + spare_bonus + strike_bonus
  end

  def spare_bonus
    return 0 if !spare?
    @next_frame.roll1 if @next_frame != nil || 0
  end

  def strike_bonus
    return 0 if !strike?

    if @next_frame.strike?
      @next_frame.roll1 + (@next_frame.tenth? ? 0 : @next_frame.next_frame.roll1)
    else
      @next_frame.roll1 + @next_frame.roll2
    end
  end

  def tenth?
    @frame_number == 10
  end

  def spare?
    @rolls == 2 and @pins == 10
  end

  def strike?
    @rolls == 1 and @pins == 10
  end

  def completed?
    if tenth?
      return @rolls == 3 || (@rolls == 2 and @pins < 10)
    end
    @pins == 10 or @rolls == 2
  end
end

class TooManyRollsError < Exception
end

describe BowlingScore do
  describe "when all gutters" do
    before { 20.times { subject.roll 0 } }
    it { subject.score.should == 0 }
  end

  describe 'when some but not all pins are knocked down' do
    before { 20.times { subject.roll 1 } }
    it { subject.score.should == 20 }
  end

  describe 'getting a spare, followed by no pins' do
    before do
      2.times { subject.roll(5) }
      18.times { subject.roll(0) }
    end

    it { subject.score.should == 10 }
  end

  describe 'getting a spare followed by some pins' do
    before do
      2.times { subject.roll(5) }
      subject.roll 5
      17.times { subject.roll(0) }
    end

    it { subject.score.should == 20 }
  end

  describe 'getting a spare followed by pins on next two rolls' do
    before do
      2.times { subject.roll(5) }
      subject.roll 5
      subject.roll 2
      16.times { subject.roll(0) }
    end

    it { subject.score.should == 22 }
  end

  describe 'getting a strike followed by no pins' do
    before do
      subject.roll(10)
      18.times { subject.roll(0) }
    end

    it { subject.score.should == 10 }
  end

  describe 'getting a strike followed by pins on next roll only' do
    before do
      subject.roll(10)
      subject.roll(5)
      17.times { subject.roll(0) }
    end

    it { subject.score.should == 20 }
  end

  describe 'getting a strike followed by pins (non spare) in next two rolls' do
    before do
      subject.roll(10)
      subject.roll(5)
      subject.roll(2)
      16.times { subject.roll(0) }
    end

    it { subject.score.should == 24 }
  end

  describe 'getting three strikes in a row, followed by gutters' do
    before do
      3.times { subject.roll(10) }
      14.times { subject.roll(0) }
    end

    it { subject.score.should == 60 }
  end

  describe 'getting three strikes in a row, followed by pins' do
    before do
      3.times { subject.roll(10) }
      subject.roll(2)
      subject.roll(5)
      12.times { subject.roll(0) }
    end

    it { subject.score.should == 76 }
  end

  describe 'all strikes' do
    before do
      12.times { subject.roll(10) }
    end

    it { subject.score.should == 300 }
  end

  describe 'full example game' do
    before do
      subject.roll(1)
      subject.roll(4)
      subject.roll(4)
      subject.roll(5)
      subject.roll(6)
      subject.roll(4)
      subject.roll(5)
      subject.roll(5)
      subject.roll(10)
      subject.roll(0)
      subject.roll(1)
      subject.roll(7)
      subject.roll(3)
      subject.roll(6)
      subject.roll(4)
      subject.roll(10)
      subject.roll(2)
      subject.roll(8)
      subject.roll(6)
    end

    it { subject.score.should == 133 }
  end

  describe 'not clearing pins by second roll on tenth frame' do
    before do
      18.times { subject.roll(0) }
      subject.roll(2)
      subject.roll(3)
    end

    it 'should raise an error on the extra roll' do
      lambda { subject.roll(0) }.should raise_error TooManyRollsError
    end
  end

  describe 'when rolling 13 strikes' do
    before do
      12.times { subject.roll(10) }
    end

    it 'should raise an error on the extra roll' do
      lambda { subject.roll(0) }.should raise_error TooManyRollsError
    end
  end
end
