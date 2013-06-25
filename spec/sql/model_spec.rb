class SqlTask
  include MotionModel::Model
  include MotionModel::FMDBModelAdapter
  columns       :name => :string,
                :details => :string,
                :some_day => :date

  def custom_attribute_by_method
    "#{name} - #{details}"
  end
end

describe "Creating a model" do
  before do
    MotionModel::Store.config(MotionModel::FMDBAdapter.new('spec.db', reset: true, ns_log: false))
    SqlTask.create_table
  end

  describe 'column macro behavior' do

    it 'succeeds when creating a valid model from attributes' do
      a_task = SqlTask.new(:name => 'name', :details => 'details')
      a_task.name.should.equal('name')
    end

    it 'creates a model with all attributes even if some omitted' do
      atask = SqlTask.create(:name => 'bob')
      atask.should.respond_to(:details)
    end

    it "adds a default value if none supplied" do
      a_type_test = TypeCast.new
      a_type_test.an_int.should.equal(3)
    end

    it "can check for a column's existence on a model" do
      SqlTask.column?(:name).should.be.true
    end

    it "can check for a column's existence on an instance" do
      a_task = SqlTask.new(:name => 'name', :details => 'details')
      a_task.column?(:name).should.be.true
    end

    it "gets a list of columns on a model" do
      cols = SqlTask.columns
      cols.should.include(:name)
      cols.should.include(:details)
    end

    it "gets a list of columns on an instance" do
      a_task = SqlTask.new
      cols = a_task.columns
      cols.should.include(:name)
      cols.should.include(:details)
    end

    it "columns can be specified as a Hash" do
      lambda{SqlTask.new}.should.not.raise
      SqlTask.new.column?(:name).should.be.true
    end

    it "the type of a column can be retrieved" do
      SqlTask.new.column_type(:some_day).should.equal(:date)
    end

  end

  describe "ID handling" do
    before do
      SqlTask.delete_all
    end


    it 'creates an id if none present' do
      task = SqlTask.create
      task.should.respond_to(:id)
    end

    it 'does not overwrite an existing ID' do
      task = SqlTask.create(:id => 999)
      task.id.should.equal(999)
    end

    it 'creates multiple objects with unique ids' do
      SqlTask.create.id.should.not.equal(SqlTask.create.id)
    end

  end

  describe 'count and length methods' do
    before do
      SqlTask.delete_all
    end

    it 'has a length method' do
      SqlTask.should.respond_to(:length)
    end

    it 'has a count method' do
      SqlTask.should.respond_to(:count)
    end

    it 'when there is one element, length returns 1' do
      task = SqlTask.create
      SqlTask.length.should.equal(1)
    end

    it 'when there is one element, count returns 1' do
      task = SqlTask.create
      SqlTask.count.should.equal(1)
    end

    it 'when there is more than one element, length returned is correct' do
      10.times { SqlTask.create }
      SqlTask.length.should.equal(10)
    end

  end

  describe 'adding or updating' do
    before do
      SqlTask.delete_all
    end

    it 'adds to the collection when a new task is saved' do
      task = SqlTask.new
      lambda{task.save}.should.change{SqlTask.count}
    end

    it 'does not add to the collection when an existing task is saved' do
      task = SqlTask.create(:name => 'updateable')
      task.name = 'updated'
      lambda{task.save}.should.not.change{SqlTask.count}
    end

    it 'updates data properly' do
      task = SqlTask.create(:name => 'updateable')
      task.name = 'updated'
      SqlTask.where(:name => 'updated').count.should == 0
      task.save
      SqlTask.where(:name => 'updated').count.should == 1
    end
  end

  describe 'deleting' do
    before do
      SqlTask.delete_all
      SqlTask.bulk_update do
        1.upto(10) {|i| SqlTask.create(:name => "task #{i}")}
      end
    end

    it 'deletes a row' do
      target = SqlTask.where(:name => 'task 3').first
      target.should.not == nil
      target.delete
      SqlTask.where(:name => 'task 3').count.should.equal 0
    end

    it 'deleting a row changes length' do
      target = SqlTask.where(:name => 'task 2').first
      lambda{target.delete}.should.change{SqlTask.length}
    end

  end

  describe 'Handling Attribute Implementation' do
    it 'raises a NoMethodError exception when an unknown attribute it referenced' do
      task = SqlTask.new
      lambda{task.bar}.should.raise(NoMethodError)
    end

    it 'raises a NoMethodError exception when an unknown attribute receives an assignment' do
      task = SqlTask.new
      lambda{task.bar = 'foo'}.should.raise(NoMethodError)
    end

    it 'successfully retrieves by attribute' do
      task = SqlTask.create(:name => 'my task')
      task.name.should == 'my task'
    end

    describe "dirty" do
      before do
        @new_task = SqlTask.new
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
      SqlTask.delete_all
      @task = SqlTask.create :name => 'Feed the Cat', :details => 'Get food, pour out'
    end

    it 'uses a custom attribute by method' do
      @task.custom_attribute_by_method.should == 'Feed the Cat - Get food, pour out'
    end
  end
end
