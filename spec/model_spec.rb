class Task
  include MotionModel::Model
  columns       :name => :string, 
  							:details => :string,
  							:some_day => :date
end

class ATask
  include MotionModel::Model
  columns :name, :details, :some_day
end

class TypeCast
  include MotionModel::Model
  columns :an_int => {:type => :int, :default => 3},
          :an_integer => :integer,
          :a_float => :float,
          :a_double => :double,
          :a_date => :date,
          :a_time => :time
end

describe "Creating a model" do
  describe 'column macro behavior' do
    before do
      Task.delete_all
    end

    it 'succeeds when creating a valid model from attributes' do
      a_task = Task.new(:name => 'name', :details => 'details')
      a_task.name.should.equal('name')
    end
    
    it 'creates a model with all attributes even if some omitted' do
      atask = Task.create(:name => 'bob')
      atask.should.respond_to(:details)
    end

    it 'simply bypasses spurious attributes erroneously set' do
      a_task = Task.new(:name => 'details', :zoo => 'very bad')
      a_task.should.not.respond_to(:zoo)
      a_task.name.should.equal('details')
    end
    
    it "adds a default value if none supplied" do
      a_type_test = TypeCast.new
      a_type_test.an_int.should.equal(3)
    end

    it "can check for a column's existence on a model" do
      Task.column?(:name).should.be.true
    end

    it "can check for a column's existence on an instance" do
      a_task = Task.new(:name => 'name', :details => 'details')
      a_task.column?(:name).should.be.true
    end

    it "gets a list of columns on a model" do
      cols = Task.columns
      cols.should.include(:name)
      cols.should.include(:details)
    end

    it "gets a list of columns on an instance" do
      a_task = Task.new
      cols = a_task.columns
      cols.should.include(:name)
      cols.should.include(:details)
    end

    it "columns can be specified as a Hash" do
      lambda{Task.new}.should.not.raise
      Task.new.column?(:name).should.be.true
    end

    it "columns can be specified as an Array" do
      lambda{ATask.new}.should.not.raise
      Task.new.column?(:name).should.be.true
    end

    it "the type of a column can be retrieved" do
      Task.new.type(:some_day).should.equal(:date)
    end

  end

  describe "ID handling" do
    before do
      Task.delete_all
    end


    it 'creates an id if none present' do
      task = Task.create
      task.should.respond_to(:id)
    end

    it 'does not overwrite an existing ID' do
      task = Task.create(:id => 999)
      task.id.should.equal(999)
    end

    it 'creates multiple objects with unique ids' do
      Task.create.id.should.not.equal(Task.create.id)
    end

  end

  describe 'count and length methods' do
    before do
      Task.delete_all
    end

    it 'has a length method' do
      Task.should.respond_to(:length)
    end

    it 'has a count method' do
      Task.should.respond_to(:count)
    end

    it 'when there is one element, length returns 1' do
      task = Task.create
      Task.length.should.equal(1)
    end

    it 'when there is one element, count returns 1' do
      task = Task.create
      Task.count.should.equal(1)
    end

    it 'when there is more than one element, length returned is correct' do
      10.times { Task.create }
      Task.length.should.equal(10)
    end

  end

  describe 'deleting' do
    before do
      Task.delete_all
      Task.bulk_update do
        1.upto(10) {|i| Task.create(:name => "task #{i}")}
      end
    end
    
    it 'deletes a row' do
      target = Task.find(:name).eq('task 3').first
      target.should.not == nil
      target.delete
      Task.find(:name).eq('task 3').count.should.equal 0
    end
    
    it 'deleting a row changes length' do
      target = Task.find(:name).eq('task 2').first
      lambda{target.delete}.should.change{Task.length}
    end
  end
  
  describe 'Handling Attribute Implementation' do
    it 'raises a NoMethodError exception when an unknown attribute it referenced' do
      task = Task.new
      lambda{task.bar}.should.raise(NoMethodError)
    end

    it 'successfully retrieves by attribute' do
      task = Task.create(:name => 'my task')
      task.name.should == 'my task'
    end

    describe "dirty" do
      before do
        @new_task = Task.new
      end

      it 'marks a new object as dirty' do
        @new_task.should.be.dirty
      end

      it 'marks a saved object as clean' do
        lambda{@new_task.save}.should.change{@new_task.dirty?}
      end

      it 'marks a modified object as dirty' do
        @new_task.save
        lambda{@new_task.name = 'now dirty'}.should.change{@new_task.dirty?}
      end
    end
  end
  
  describe 'Type casting' do
    before do
      @convertible = TypeCast.new
      @convertible.an_int = '1'
      @convertible.an_integer = '2'
      @convertible.a_float = '3.7'
      @convertible.a_double = '3.41459'
      @convertible.a_date = '2012-09-15'
    end
    
    it 'does the type casting on instantiation' do
      @convertible.an_int.should.is_a Integer
      @convertible.an_integer.should.is_a Integer
      @convertible.a_float.should.is_a Float
      @convertible.a_double.should.is_a Float
      @convertible.a_date.should.is_a NSDate
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
        
  end
end
