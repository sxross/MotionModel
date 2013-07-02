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
    MotionModel::Store.config(MotionModel::FMDBAdapter.new('spec.db', reset: true, ns_log: false))
    SqlTypeCast.create_table
    @convertible = SqlTypeCast.new
  end

  describe "when assigning a boolean" do

    it "accepts false as false" do
      @convertible.a_boolean = false
      @convertible.a_boolean.should.is_a(FalseClass)
      @convertible.save
      SqlTypeCast.last.a_boolean.should == false
    end

    it 'accepts the string "false" as false' do
      @convertible.a_boolean = 'false'
      @convertible.a_boolean.should.is_a(FalseClass)
      @convertible.save
      SqlTypeCast.last.a_boolean.should == false
    end

    it 'accepts a non-zero integer as true' do
      @convertible.a_boolean = 1
      @convertible.a_boolean.should.is_a(TrueClass)
      @convertible.save
      SqlTypeCast.last.a_boolean.should == true
    end

    it 'accepts a zero valued integer as false' do
      @convertible.a_boolean = 0
      @convertible.a_boolean.should.is_a(FalseClass)
      @convertible.save
      SqlTypeCast.last.a_boolean.should == false
    end

    it "accepts true as true" do
      @convertible.a_boolean = true
      @convertible.a_boolean.should.is_a(TrueClass)
      @convertible.save
      SqlTypeCast.last.a_boolean.should == true
    end

    it 'accepts a string that starts with "true" as true' do
      @convertible.a_boolean = 'true'
      @convertible.a_boolean.should.is_a(TrueClass)
      @convertible.save
      SqlTypeCast.last.a_boolean.should == true
    end

    it 'accepts a string with "true" not at the start as false' do
      @convertible.a_boolean = 'something true'
      @convertible.a_boolean.should.is_a(FalseClass)
      @convertible.save
      SqlTypeCast.last.a_boolean.should == false
    end

    it 'accepts a string that does not contain "true" as false' do
      @convertible.a_boolean = 'something'
      @convertible.a_boolean.should.is_a(FalseClass)
      @convertible.save
      SqlTypeCast.last.a_boolean.should == false
    end

    it 'accepts nil as false' do
      @convertible.a_boolean = nil
      @convertible.a_boolean.should.is_a(FalseClass)
      @convertible.save
      SqlTypeCast.last.a_boolean.should == false
    end

  end

  describe "When assigning an integer" do

    it 'accepts a string and converts it to an integer' do
      @convertible.an_integer = '2'
      @convertible.an_integer.should.is_a(Integer)
      @convertible.save
      SqlTypeCast.last.an_integer.should == 2
    end

    it 'accepts an integer' do
      @convertible.an_integer = 2
      @convertible.save
      SqlTypeCast.last.an_integer.should.is_a(Integer)
    end

  end

  describe "when assigning a float" do

    it 'accepts a string and converts it to a float' do
      @convertible.a_float = '3.7'
      @convertible.a_float.should.is_a(Float)
      @convertible.save
      SqlTypeCast.last.a_float.should.>(3.6)
      SqlTypeCast.last.a_float.should.<(3.8)
    end

    it 'accepts a float' do
      @convertible.a_float = 3.7
      @convertible.a_float.should.is_a(Float)
      @convertible.save
      SqlTypeCast.last.a_float.should.>(3.6)
      SqlTypeCast.last.a_float.should.<(3.8)
    end

  end

  describe "when assigning a date" do

    it 'converts a string into an NSDate' do
      @convertible.a_date = '2012-09-15'
      @convertible.a_date.should.is_a(NSDate)
      @convertible.save
      SqlTypeCast.last.a_date.should.is_a(NSDate)
    end

    it 'should return the same as it was in string form' do
      @convertible.a_date = '2012-09-15'
      @convertible.save
      SqlTypeCast.last.a_date.to_s.should.match(/^2012-09-15/)
    end

  end

  describe "when assigning a string" do

    it 'accepts a string' do
      @convertible.a_string = 'string'
      @convertible.save
      SqlTypeCast.last.a_string.should.equal 'string'
    end

  end

  describe "when assigning a datetime" do

    it "converts a string to NSDate" do
      @convertible.a_datetime = '2012-09-15 13:50'
      @convertible.save
      SqlTypeCast.last.a_datetime.should.is_a(NSDate)
    end

    it "converts an integer to NSDate" do
      @convertible.a_datetime = 1358197323
      @convertible.a_datetime.should.not.is_a?(Bignum)
      @convertible.save
      SqlTypeCast.last.a_datetime.should.is_a(NSDate)
      SqlTypeCast.last.a_datetime.utc.strftime("%Y-%m-%d %H:%M").should == '2013-01-14 21:02'
    end

  end

end