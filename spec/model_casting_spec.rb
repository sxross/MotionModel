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
  it 'returns proper array for parsed json data using bubble wrap' do
    parsed_json = BW::JSON.parse('{"menu_categories":["Lunch"]}')
    @convertible.an_array = parsed_json["menu_categories"]
    @convertible.an_array.count.should == 1
    @convertible.an_array.include?("Lunch").should == true
  end
  it 'the array field should be the same as the range form' do
    (@convertible.an_array.first..@convertible.an_array.last).should.equal(1..10)
  end

  describe 'can cast to an arbitrary type' do
    class HasArbitraryTypes
      include MotionModel::Model
      include MotionModel::ArrayModelAdapter
      columns name: String,
              properties: Hash
    end

    class EmbeddedAddress
      include MotionModel::Model
      include MotionModel::ArrayModelAdapter
      columns     street: String,
                  city:   String,
                  state:  String,
                  zip:    Integer,
                  pets:   Array
      # attr_accessor :street
      # attr_accessor :city
      # attr_accessor :state
      # attr_accessor :zip
      # attr_accessor :pets

      # def initialize(options = {})
      #   @street = options[:street] if options[:street]
      #   @city = options[:city] if options[:city]
      #   @state = options[:state] if options[:state]
      #   @zip = options[:zip] if options[:zip]
      #   @pets = options[:pets] if options[:pets]
      # end
    end

    class EmbeddingClass
      include MotionModel::Model
      include MotionModel::ArrayModelAdapter
      columns name: String,
              address: EmbeddedAddress,
              pets: Array
    end

    before do
      EmbeddingClass.delete_all
      HasArbitraryTypes.delete_all
    end

    it "creation works" do
      arb = HasArbitraryTypes.create(name: 'A Name', properties: {address: '123 Main Street', city: 'Seattle', state: 'WA'})
      arb.name.should == 'A Name'
      arb.properties.class.should == Hash
      arb.properties[:address].should == '123 Main Street'
    end

    it "updating works" do
      HasArbitraryTypes.create(name: 'Another Name', properties: {address: '123 Main Street', city: 'Seattle', state: 'WA'})
      arb = HasArbitraryTypes.first
      arb.properties[:address] = '234 Main Street'
      arb.save
      arb.properties[:address].should == '234 Main Street'
      arb = HasArbitraryTypes.find(:name).eq('Another Name').first
      arb.properties[:address].should == '234 Main Street'
    end

    it "creating objects with embedded documents works" do
      addr = EmbeddedAddress.new(street: '2211 First', city: 'Seattle', state: 'WA', zip: 98104)
      emb = EmbeddingClass.create(name: 'On Class', address: addr)
      emb.address.class.should == EmbeddedAddress
      emb.address.street.should == '2211 First'
    end

    it "copies embedded types" do
      addr = EmbeddedAddress.new(street: '2211 First', city: 'Seattle', state: 'WA', zip: 98104, pets: ['rover', 'fido', 'barney'])
      emb = EmbeddingClass.create(name: 'On Class', address: addr)
      emb.address.pets.class.should == Array
      emb.address.pets.should.include?('barney')
      EmbeddingClass.first.address.pets.should.include?('barney')
    end

    it "updates embedded types" do
      addr = EmbeddedAddress.new(street: '3322 First', city: 'Seattle', state: 'WA', zip: 98104, pets: ['rover', 'fido', 'barney'])
      emb = EmbeddingClass.create(name: 'On Class', address: addr)
      emb.address.pets.should.include?('barney')
      found = EmbeddingClass.find(:name).eq('On Class').first
      found.address.pets.should.include?('barney')
      found.address.pets.delete('barney')
      found.save
      EmbeddingClass.find(:name).eq('On Class').first.address.pets.should.not.include?('barney')
    end

    it "serializes with arbitrary Ruby types without error" do
      HasArbitraryTypes.create(name: 'A Name', properties: {address: '123 Main Street', city: 'Seattle', state: 'WA'})
      lambda{HasArbitraryTypes.serialize_to_file('test.dat')}.should.not.raise
    end

    it "deserializes arbitrary Ruby types with correct values" do
      HasArbitraryTypes.create(name: 'A Name', properties: {address: '123 Main Street', city: 'Seattle', state: 'WA'})
      HasArbitraryTypes.serialize_to_file('test.dat')
      HasArbitraryTypes.deserialize_from_file('test.dat')
      result = HasArbitraryTypes.find(:name).eq('A Name').first
      result.should.not.be.nil
      result.properties.class.should == Hash
      result.properties[:city].should == 'Seattle'
    end

    it "serializes arbitrary user-defined classes without error" do
      addr = EmbeddedAddress.new(street: '2211 First', city: 'Seattle', state: 'WA', zip: 98104)
      emb = EmbeddingClass.create(name: 'On Class', address: addr)
      lambda{EmbeddingClass.serialize_to_file('test.dat')}.should.not.raise
    end

    it "deserializes arbitrary user-defined classes with correct values" do
      addr = EmbeddedAddress.new(street: '2211 First', city: 'Seattle', state: 'WA', zip: 98104, pets: ['Katniss', 'Peeta'])
      emb = EmbeddingClass.create(name: 'On Class', address: addr)
      lambda{EmbeddingClass.serialize_to_file('test.dat')}.should.not.raise
      EmbeddingClass.deserialize_from_file('test.dat')
      result = EmbeddingClass.find(:name).eq('On Class').first
      result.should.not.be.nil
      result.address.class.should == EmbeddedAddress
      result.address.city.should == 'Seattle'
      result.address.pets.should.include?('Katniss')
    end
  end
end
