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
  before do
    Task.delete_all
  end

  describe 'column macro behavior' do

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

  describe 'finders' do
    before do
      Task.delete_all
      10.times {|i| Task.create(:name => "task #{i}")}
    end

    describe 'find' do
      it 'finds elements within the collection' do
        task = Task.find(3).name.should.equal('task 3')
      end

      it 'returns nil if find by id is not found' do
        Task.find(999).should.be.nil
      end
      
      it 'looks into fields if field name supplied' do
        Task.create(:name => 'find me')
        tasks = Task.find(:name).eq('find me')
        tasks.all.length.should.equal(1)
        tasks.first.name.should == 'find me'
      end
      
      it "provides an array of valid model instances when doing a find" do
        Task.create(:name => 'find me')
        tasks = Task.find(:name).eq('find me')
        tasks.first.name.should.eql 'find me'
      end
      
      it 'allows for multiple (chained) query parameters' do
        Task.create(:name => 'find me', :details => "details 1")
        Task.create(:name => 'find me', :details => "details 2")
        tasks = Task.find(:name).eq('find me').and(:details).like('2')
        tasks.first.details.should.equal('details 2')
        tasks.all.length.should.equal(1)
      end

      it 'where should respond to finder methods' do
        Task.where(:details).should.respond_to(:contain)
      end
      
      it 'returns a FinderQuery object' do
        Task.where(:details).should.is_a(MotionModel::FinderQuery)
      end
      
      it 'using where instead of find' do
        atask = Task.create(:name => 'find me', :details => "details 1")
        found_task = Task.where(:details).contain("s 1").first.details.should == 'details 1'
      end
      
      it "performs set inclusion(in) queries" do
        class InTest
          include MotionModel::Model
          columns :name
        end
        
        1.upto(10) do |i|
          InTest.create(:id => i, :name => "test #{i}")
        end
        
        results = InTest.find(:id).in([3, 5, 7])
        results.length.should == 3
      end
      
      it 'handles case-sensitive queries' do
        task = Task.create :name => 'Bob'
        Task.find(:name).eq('bob', :case_sensitive => true).all.length.should == 0
      end
    
      it 'all returns all members of the collection as an array' do
        Task.all.length.should.equal(10)
      end
    
      it 'each yields each row in sequence' do
        i = 0
        Task.each do |task|
          task.name.should.equal("task #{i}")
          i += 1
        end
      end
      
      describe 'block-style finders' do
        before do
          @items_less_than_5 = Task.find{|item| item.name.split(' ').last.to_i < 5}
        end
        
        it 'returns a FinderQuery' do
          @items_less_than_5.should.is_a MotionModel::FinderQuery
        end
        
        it 'handles block-style finders' do
          @items_less_than_5.length.should == 5 # Zero based
        end
        
        it 'deals with any arbitrary block finder' do
          @even_items = Task.find do |item|
            test_item = item.name.split(' ').last.to_i
            test_item % 2 == 0 && test_item < 5
          end
          @even_items.each{|item| item.name.split(' ').last.to_i.should.even?}
          @even_items.length.should == 3   # [0, 2, 4]
        end
      end
    end
    
    describe 'sorting' do
      before do
        Task.delete_all
        Task.create(:name => 'Task 3', :details => 'detail 3')
        Task.create(:name => 'Task 1', :details => 'detail 1')
        Task.create(:name => 'Task 2', :details => 'detail 6')
        Task.create(:name => 'Random Task', :details => 'another random task')
      end

      it 'sorts by field' do
        tasks = Task.order(:name).all
        tasks[0].name.should.equal('Random Task')
        tasks[1].name.should.equal('Task 1')
        tasks[2].name.should.equal('Task 2')
        tasks[3].name.should.equal('Task 3')
      end

      it 'sorts observing block syntax' do
        tasks = Task.order{|one, two| two.details <=> one.details}.all
        tasks[0].details.should.equal('detail 6')
        tasks[1].details.should.equal('detail 3')
        tasks[2].details.should.equal('detail 1')
        tasks[3].details.should.equal('another random task')
      end
    end
    
  end
  
  describe 'deleting' do
    before do
      10.times {|i| Task.create(:name => "task #{i}")}
    end
    
    it 'deletes a row' do
      target = Task.find(:name).eq('task 3').first
      target.delete
      Task.find(:description).eq('Task 3').length.should.equal 0
    end
    
    it 'deleting a row changes length' do
      target = Task.find(:name).eq('task 3').first
      lambda{target.delete}.should.change{Task.length}
    end
  end
  
  describe 'Handling Attribute method_missing Implementation' do
    it 'raises a NoMethodError exception when an unknown attribute it referenced' do
      task = Task.new
      lambda{task.bar}.should.raise(NoMethodError)
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

