class SqlTypeCast
  include MotionModel::Model
  include MotionModel::FMDBModelAdapter
  columns :a_boolean => :boolean,
          :an_integer => :integer,
          :a_float => :float,
          :a_string => :string,
          :a_date => :date,
          :a_datetime => :datetime
end

describe 'Type casting' do

  before do
    @convertible = SqlTypeCast.new
  end

  describe "when assigning a boolean" do

    it "accepts false as false" do
      @convertible.a_boolean = false
      @convertible.a_boolean.should.is_a(FalseClass)
    end

    it 'accepts the string "false" as false' do
      @convertible.a_boolean = 'false'
      @convertible.a_boolean.should.is_a(FalseClass)
    end

    it 'should return the same as it was in string form' do
      @convertible.a_boolean = 'false'
      @convertible.a_boolean.to_s.should.equal('false')
    end

    it 'accepts a non-zero integer as true' do
      @convertible.a_boolean = 1
      @convertible.a_boolean.should.is_a(TrueClass)
    end

    it 'accepts a zero valued integer as false' do
      @convertible.a_boolean = 0
      @convertible.a_boolean.should.is_a(FalseClass)
    end

    it "accepts true as true" do
      @convertible.a_boolean = true
      @convertible.a_boolean.should.is_a(TrueClass)
    end

    it 'accepts a string that starts with "true" as true' do
      @convertible.a_boolean = 'true'
      @convertible.a_boolean.should.is_a(TrueClass)
    end

    it 'accepts a string with "true" not at the start as false' do
      @convertible.a_boolean = 'something true'
      @convertible.a_boolean.should.is_a(FalseClass)
    end

    it 'accepts a string that does not contain "true" as false' do
      @convertible.a_boolean = 'something'
      @convertible.a_boolean.should.is_a(FalseClass)
    end

    it 'accepts nil as false' do
      @convertible.a_boolean = nil
      @convertible.a_boolean.should.is_a(FalseClass)
    end

  end

  describe "When assigning an integer" do

    it 'accepts a string and converts it to an integer' do
      @convertible.an_integer = '2'
      @convertible.an_integer.should.is_a(Integer)
    end

    it 'accepts an integer' do
      @convertible.an_integer = 2
      @convertible.an_integer.should.is_a(Integer)
    end

  end

  describe "when assigning a float" do

    it 'accepts a string and converts it to a float' do
      @convertible.a_float = '3.7'
      @convertible.a_float.should.is_a(Float)
      @convertible.a_float.should.>(3.6)
      @convertible.a_float.should.<(3.8)
    end

    it 'accepts a float' do
      @convertible.a_float = 3.7
      @convertible.a_float.should.is_a(Float)
      @convertible.a_float.should.>(3.6)
      @convertible.a_float.should.<(3.8)
    end

  end

  describe "when assigning a date" do

    it 'converts a string into an NSDate' do
      @convertible.a_date = '2012-09-15'
      @convertible.a_date.should.is_a(NSDate)
    end

    it 'should return the same as it was in string form' do
      @convertible.a_date = '2012-09-15'
      @convertible.a_date.to_s.should.match(/^2012-09-15/)
    end

  end

  describe "when assigning a string" do

    it 'accepts a string' do
      @convertible.a_string = 'string'
      @convertible.a_string.should.equal 'string'
    end

  end

  describe "when assigning a datetime" do

    it "converts a string to NSDate" do
      @convertible.a_datetime = '2012-09-15 13:50'
      @convertible.a_datetime.should.is_a(NSDate)
    end

  end

end