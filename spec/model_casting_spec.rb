class TypeCast
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter
  columns :a_boolean => :boolean,
          :an_int => {:type => :int, :default => 3},
          :an_integer => :integer,
          :a_float => :float,
          :a_double => :double,
          :a_date => :date,
          :a_time => :time,
          :an_array => :array
end

describe 'Type casting' do
  before do
    @convertible = TypeCast.new
    @convertible.a_boolean = 'false'
    @convertible.an_int = '1'
    @convertible.an_integer = '2'
    @convertible.a_float = '3.7'
    @convertible.a_double = '3.41459'
    @convertible.a_date = '2012-09-15'
    @convertible.an_array = 1..10
  end
  
  it 'does the type casting on instantiation' do
    @convertible.a_boolean.should.is_a FalseClass
    @convertible.an_int.should.is_a Integer
    @convertible.an_integer.should.is_a Integer
    @convertible.a_float.should.is_a Float
    @convertible.a_double.should.is_a Float
    @convertible.a_date.should.is_a NSDate
    @convertible.an_array.should.is_a Array
  end

  it 'returns a boolean for a boolean field' do
    @convertible.a_boolean.should.is_a(FalseClass)
  end

  it 'the boolean field should be the same as it was in string form' do
    @convertible.a_boolean.to_s.should.equal('false')
  end

  it 'the boolean field accepts a non-zero integer as true' do
    @convertible.a_boolean = 1
    @convertible.a_boolean.should.is_a(TrueClass)
  end

  it 'the boolean field accepts a zero valued integer as false' do
    @convertible.a_boolean = 0
    @convertible.a_boolean.should.is_a(FalseClass)
  end

  it 'the boolean field accepts a string that starts with "true" as true' do
    @convertible.a_boolean = 'true'
    @convertible.a_boolean.should.is_a(TrueClass)
  end

  it 'the boolean field treats a string with "true" not at the start as false' do
    @convertible.a_boolean = 'something true'
    @convertible.a_boolean.should.is_a(FalseClass)
  end

  it 'the boolean field accepts a string that does not contain "true" as false' do
    @convertible.a_boolean = 'something'
    @convertible.a_boolean.should.is_a(FalseClass)
  end

  it 'the boolean field accepts nil as false' do
    @convertible.a_boolean = nil
    @convertible.a_boolean.should.is_a(FalseClass)
  end

  it 'returns an integer for an int field' do
    @convertible.an_int.should.is_a(Integer)
  end

  it 'the int field should be the same as it was in string form' do
    @convertible.an_int.to_s.should.equal('1')
  end

  it 'returns an integer for an integer field' do
    @convertible.an_integer.should.is_a(Integer)
  end

  it 'the integer field should be the same as it was in string form' do
    @convertible.an_integer.to_s.should.equal('2')
  end

  it 'returns a float for a float field' do
    @convertible.a_float.should.is_a(Float)
  end

  it 'the float field should be the same as it was in string form' do
    @convertible.a_float.should.>(3.6)
    @convertible.a_float.should.<(3.8)
  end

  it 'returns a double for a double field' do
    @convertible.a_double.should.is_a(Float)
  end

  it 'the double field should be the same as it was in string form' do
    @convertible.a_double.should.>(3.41458)
    @convertible.a_double.should.<(3.41460)
  end

  it 'returns a NSDate for a date field' do
    @convertible.a_date.should.is_a(NSDate)
  end
  
  it 'the date field should be the same as it was in string form' do
    @convertible.a_date.to_s.should.match(/^2012-09-15/)
  end

  it 'returns an Array for an array field' do
    @convertible.an_array.should.is_a(Array)
  end

  it 'the array field should be the same as the range form' do
    (@convertible.an_array.first..@convertible.an_array.last).should.equal(1..10)
  end
end
