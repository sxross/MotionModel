class Task
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter
  columns       :name => :string,
  							:details => :string,
  							:some_day => :date

  def custom_attribute_by_method
    "#{name} - #{details}"
  end
end

class ATask
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter
  columns :name, :details, :some_day
end

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
      Task.new.column_type(:some_day).should.equal(:date)
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

    it 'instance variables have access to length and count' do
      task = Task.create
      task.length.should.equal(1)
      task.count.should.equal(1)
    end

    it 'when there is more than one element, length returned is correct' do
      10.times { Task.create }
      Task.length.should.equal(10)
    end

  end

  describe 'adding or updating' do
    before do
      Task.delete_all
    end

    it 'adds to the collection when a new task is saved' do
      task = Task.new
      lambda{task.save}.should.change{Task.count}
    end

    it 'does not add to the collection when an existing task is saved' do
      task = Task.create(:name => 'updateable')
      task.name = 'updated'
      lambda{task.save}.should.not.change{Task.count}
    end

    it 'updates data properly' do
      task = Task.create(:name => 'updateable')
      task.name = 'updated'
      Task.where(:name).eq('updated').should == 0
      lambda{task.save}.should.change{Task.where(:name).eq('updated')}
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

    it 'undeleting a row restores it' do
      target = Task.find(:name).eq('task 3').first
      target.should.not == nil
      target.delete
      target.undelete
      Task.find(:name).eq('task 3').count.should.equal 1
    end
  end
  
  describe 'Handling Attribute Implementation' do
    it 'raises a NoMethodError exception when an unknown attribute it referenced' do
      task = Task.new
      lambda{task.bar}.should.raise(NoMethodError)
    end

    it 'raises a NoMethodError exception when an unknown attribute receives an assignment' do
      task = Task.new
      lambda{task.bar = 'foo'}.should.raise(NoMethodError)
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

      it 'marks an updated object as clean' do
        @new_task.save
        @new_task.should.not.be.dirty
        @new_task.name = 'now updating task'
        @new_task.should.be.dirty
        @new_task.save
        @new_task.should.not.be.dirty
      end
    end
  end
  
  describe 'defining custom attributes' do
    before do
      Task.delete_all
      @task = Task.create :name => 'Feed the Cat', :details => 'Get food, pour out'
    end

    it 'uses a custom attribute by method' do
      @task.custom_attribute_by_method.should == 'Feed the Cat - Get food, pour out'
    end
  end
end
