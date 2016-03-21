class ModelSpecTask
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter
  columns       :name => :string,
  							:details => :string,
  							:some_day => :date,
                :enabled => {:type => :boolean, :default => false}

  def custom_attribute_by_method
    "#{name} - #{details}"
  end
end

class AModelSpecTask
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter
  columns :name, :details, :some_day
end

class BModelSpecTask
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter
  columns :name, :details
  def details=(value)
    write_attribute(:details, "overridden")
  end
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
      ModelSpecTask.delete_all
    end

    it 'succeeds when creating a valid model from attributes' do
      a_task = ModelSpecTask.new(:name => 'name', :details => 'details')
      a_task.name.should.equal('name')
    end

    it 'creates a model with all attributes even if some omitted' do
      atask = ModelSpecTask.create(:name => 'bob')
      atask.should.respond_to(:details)
    end

    it "adds a default value if none supplied" do
      a_type_test = TypeCast.new
      a_type_test.an_int.should.equal(3)
    end
    
    it "on initialization uses supplied value instead of default value, if supplied" do
      a_task = ModelSpecTask.new(:enabled => true)
      a_task.enabled.should.be.true
    end
        
    it "on creation uses supplied value instead of default value, if supplied" do
      a_task = ModelSpecTask.create(:enabled => true)
      a_task.enabled.should.be.true
    end

    it "can check for a column's existence on a model" do
      ModelSpecTask.column?(:name).should.be.true
    end

    it "can check for a column's existence on an instance" do
      a_task = ModelSpecTask.new(:name => 'name', :details => 'details')
      a_task.column?(:name).should.be.true
    end

    it "gets a list of columns on a model" do
      cols = ModelSpecTask.columns
      cols.should.include(:name)
      cols.should.include(:details)
    end

    it "gets a list of columns on an instance" do
      a_task = ModelSpecTask.new
      cols = a_task.columns
      cols.should.include(:name)
      cols.should.include(:details)
    end

    it "columns can be specified as a Hash" do
      lambda{ModelSpecTask.new}.should.not.raise
      ModelSpecTask.new.column?(:name).should.be.true
    end

    it "columns can be specified as an Array" do
      lambda{AModelSpecTask.new}.should.not.raise
      ModelSpecTask.new.column?(:name).should.be.true
    end

    it "the type of a column can be retrieved" do
      ModelSpecTask.new.column_type(:some_day).should.equal(:date)
    end

  end

  describe "ID handling" do
    before do
      ModelSpecTask.delete_all
    end


    it 'creates an id if none present' do
      task = ModelSpecTask.create
      task.should.respond_to(:id)
    end

    it 'does not overwrite an existing ID' do
      task = ModelSpecTask.create(:id => 999)
      task.id.should.equal(999)
    end

    it 'creates multiple objects with unique ids' do
      ModelSpecTask.create.id.should.not.equal(ModelSpecTask.create.id)
    end

  end

  describe 'count and length methods' do
    before do
      ModelSpecTask.delete_all
    end

    it 'has a length method' do
      ModelSpecTask.should.respond_to(:length)
    end

    it 'has a count method' do
      ModelSpecTask.should.respond_to(:count)
    end

    it 'when there is one element, length returns 1' do
      task = ModelSpecTask.create
      ModelSpecTask.length.should.equal(1)
    end

    it 'when there is one element, count returns 1' do
      task = ModelSpecTask.create
      ModelSpecTask.count.should.equal(1)
    end

    it 'instance variables have access to length and count' do
      task = ModelSpecTask.create
      task.length.should.equal(1)
      task.count.should.equal(1)
    end

    it 'when there is more than one element, length returned is correct' do
      10.times { ModelSpecTask.create }
      ModelSpecTask.length.should.equal(10)
    end

  end

  describe 'adding or updating' do
    before do
      ModelSpecTask.delete_all
    end

    it 'adds to the collection when a new task is saved' do
      task = ModelSpecTask.new
      lambda{task.save}.should.change{ModelSpecTask.count}
    end

    it 'does not add to the collection when an existing task is saved' do
      task = ModelSpecTask.create(:name => 'updateable')
      task.name = 'updated'
      lambda{task.save}.should.not.change{ModelSpecTask.count}
    end

    it 'updates data properly' do
      task = ModelSpecTask.create(:name => 'updateable')
      task.name = 'updated'
      ModelSpecTask.where(:name).eq('updated').should == 0
      lambda{task.save}.should.change{ModelSpecTask.where(:name).eq('updated')}
    end
  end

  describe 'deleting' do
    before do
      ModelSpecTask.delete_all
      ModelSpecTask.bulk_update do
        1.upto(10) {|i| ModelSpecTask.create(:name => "task #{i}")}
      end
    end

    it 'deletes a row' do
      target = ModelSpecTask.find(:name).eq('task 3').first
      target.should.not == nil
      target.delete
      ModelSpecTask.find(:name).eq('task 3').count.should.equal 0
    end

    it 'deleting a row changes length' do
      target = ModelSpecTask.find(:name).eq('task 2').first
      lambda{target.delete}.should.change{ModelSpecTask.length}
    end

    it 'undeleting a row restores it' do
      target = ModelSpecTask.find(:name).eq('task 3').first
      target.should.not == nil
      target.delete
      target.undelete
      ModelSpecTask.find(:name).eq('task 3').count.should.equal 1
    end
  end

  describe 'Handling Attribute Implementation' do
    it 'raises a NoMethodError exception when an unknown attribute it referenced' do
      task = ModelSpecTask.new
      lambda{task.bar}.should.raise(NoMethodError)
    end

    it 'raises a NoMethodError exception when an unknown attribute receives an assignment' do
      task = ModelSpecTask.new
      lambda{task.bar = 'foo'}.should.raise(NoMethodError)
    end

    it 'successfully retrieves by attribute' do
      task = ModelSpecTask.create(:name => 'my task')
      task.name.should == 'my task'
    end

    describe "dirty" do
      before do
        @new_task = ModelSpecTask.new
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
      ModelSpecTask.delete_all
      @task = ModelSpecTask.create :name => 'Feed the Cat', :details => 'Get food, pour out'
    end

    it 'uses a custom attribute by method' do
      @task.custom_attribute_by_method.should == 'Feed the Cat - Get food, pour out'
    end
  end

  describe 'overloading accessors using write_attribute' do
    before do
      BModelSpecTask.delete_all
    end

    it 'updates the attribute on creation' do
      @task = BModelSpecTask.create :name => 'foo', :details => 'bar'
      @task.details.should.equal('overridden')
      @task.should.not.be.dirty
    end

    it 'updates the attribute but does not save a new instance' do
      @task = BModelSpecTask.new :name => 'foo', :details => 'bar'
      @task.details.should.equal('overridden')
      @task.should.be.dirty
    end

  end

  describe 'protecting timestamps' do
    class NoTimestamps
      include MotionModel::Model
      include MotionModel::ArrayModelAdapter
      columns name: :string
      protect_remote_timestamps
    end

    class AutoTimeable
      include MotionModel::Model
      include MotionModel::ArrayModelAdapter
      columns name:       :string,
              created_at: :date,
              updated_at: :date
    end

    class ProtectedTimestamps
      include MotionModel::Model
      include MotionModel::ArrayModelAdapter
      columns name:       :string,
              created_at: :date,
              updated_at: :date
      protect_remote_timestamps
    end

    it 'does nothing to break classes with no timestamps' do
      lambda{NoTimestamps.create!(name: 'no timestamps')}.should.not.raise
    end

    it "changes the timestamps if they are not protected" do
      auto_timeable = AutoTimeable.new(name: 'auto timeable')
      lambda{auto_timeable.name = 'changed auto timeable'; auto_timeable.save!}.should.change{auto_timeable.updated_at}
    end

    it "does not change created_at if timestamps are protected" do
      protected_times = ProtectedTimestamps.new(name: 'auto timeable', created_at: Time.now, updated_at: Time.now)
      lambda{protected_times.name = 'changed created at'; protected_times.save!}.should.not.change{protected_times.created_at}
    end

    it "does not change updated_at if timestamps are protected" do
      protected_times = ProtectedTimestamps.new(name: 'auto timeable', created_at: Time.now, updated_at: Time.now)
      lambda{protected_times.name = 'changed updated at'; protected_times.save!}.should.not.change{protected_times.updated_at}
    end
  end
end

describe "#all" do
  it "should return a new collection" do
    x = Task.all.object_id
    Task.create
    Task.all.object_id.should != x
  end
end
