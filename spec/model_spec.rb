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


class Parent
  include MotionModel::Model
  columns       :name => :string
  has_many      :children
end

class Child
  include MotionModel::Model
  columns       :name => :string
  belongs_to    :parent
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
    Child.delete_all
    Parent.delete_all
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

    it 'creates a model with attributes that are relations, if it can accept nested attributes' do
      child = Child.create(:name => 'child', :parent => {:name => 'parent'})
      Child.first.name.should.equal('child')
      Parent.first.name.should.equal('parent')
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

  
  describe 'deleting' do
    before do
      10.times {|i| Task.create(:name => "task #{i}")}
    end
    
    it 'deletes a row' do
      target = Task.find(:name).eq('task 3').first
      target.delete
      Task.find(:name).eq('task 3').count.should.equal 0
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

  describe "hash generation" do
    it "should generate a hash from the an object" do
      task = Task.new(:name => "name", :details => "details")
      hash = task.to_hash
      hash[:name].should.equal("name")
      hash[:details].should.equal("details")
      hash[:date].should.equal(nil)
      hash[:id].should.equal(1)
    end

    describe "hashes with inclusion" do
      before do
        Parent.delete_all
        Child.delete_all
        @parent = Parent.create(:name => "parent")
        @child1 = @parent.children.create(:name => "child1")
        @child2 = @parent.children.create(:name => "child2")
      end
      
      it "should not generate any included info without :include option" do
        hash = @parent.to_hash
        hash.keys.size.should.equal(2)
        hash[:name].should.equal("parent")
        hash[:id].should.equal(1)
      end

      it "should generate inclusions for all has_many objects" do
        Parent.first.children.count.should.equal(2)

        hash = @parent.to_hash(:include => :children)
        hash.keys.size.should.equal(3)
        hash[:name].should.equal("parent")
        hash[:id].should.equal(1)
        hash[:children].size.should.equal(2)
        hash[:children][0].keys.size.should.equal(2)
        hash[:children][0][:name].should.equal("child1")
        hash[:children][0][:id].should.equal(1)
        hash[:children][1].keys.size.should.equal(2)
        hash[:children][1][:name].should.equal("child2")
        hash[:children][1][:id].should.equal(2)
      end

      it "should generate inclusion for the belongs_to objects" do
        hash = @child1.to_hash(:include => :parent)
        hash.keys.size.should.equal(3)
        hash[:name].should.equal("child1")
        hash[:id].should.equal(1)
        hash[:parent].keys.size.should.equal(2)
        hash[:parent][:name].should.equal("parent")
        hash[:parent][:id].should.equal(1)
      end
    end
  end
end

class NotifiableTask
  include MotionModel::Model
  columns :name
  has_many :assignees
  
  attr_accessor :notification_called, :notification_details
  
  def hookup_events
    NSNotificationCenter.defaultCenter.addObserver(self, selector:'dataDidChange:', name:'MotionModelDataDidChangeNotification', object:nil)
    @notification_details = nil
  end

  def dataDidChange(notification)
    @notification_called = true
    @notification_details = notification.userInfo
  end

  def teardown_events
    NSNotificationCenter.defaultCenter.removeObserver self
  end
end

describe 'data change notifications' do
  before do
    @task = NotifiableTask.new
    @task.hookup_events
  end
  
  after do
    @task.teardown_events
  end
  
  it "fires a change notification when an item is added" do
    @task.notification_called = false
    lambda{@task.save}.should.change{@task.notification_called}
  end
  
  it "contains an add notification for new objects" do
    @task.save
    @task.notification_details[:action].should == 'add'
  end
  
  it "contans an update notification for an updated object" do
    @task.save
    @task.name = "Bill"
    @task.save
    @task.notification_details[:action].should == 'update'
  end
  
  it "contains a delete notification for a deleted object" do
    @task.save
    @task.delete
    @task.notification_details[:action].should == 'delete'
  end
  
  it "does not get a delete notification for delete_all" do
    @task = NotifiableTask.create :name => 'Bob'
    @task.notification_called = nil
    lambda{NotifiableTask.delete_all}.should.not.change{@task.notification_called}
  end
end

