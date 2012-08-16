class Task
  include MotionModel::Model
  columns       :name => :string, 
  							:description => :string,
  							:some_day => :date
end

class ATask
  include MotionModel::Model
  columns :name, :description, :some_day
end

describe "Creating a model" do
  before do
    Task.delete_all
  end

  describe 'column macro behavior' do

    it 'succeeds when creating a valid model from attributes' do
  	  a_task = Task.new(:name => 'name', :description => 'description')
  	  a_task.name.should.equal('name')
    end

    it 'simply bypasses spurious attributes erroneously set' do
    	a_task = Task.new(:name => 'description', :zoo => 'very bad')
    	a_task.should.not.respond_to(:zoo)
    	a_task.name.should.equal('description')
    end

    it "can check for a column's existence on a model" do
  	  Task.column?(:name).should.be.true
    end

    it "can check for a column's existence on an instance" do
  	  a_task = Task.new(:name => 'name', :description => 'description')
  	  a_task.column?(:name).should.be.true
    end

    it "gets a list of columns on a model" do
    	cols = Task.columns
    	cols.should.include(:name)
    	cols.should.include(:description)
    end

    it "gets a list of columns on an instance" do
    	a_task = Task.new
    	cols = a_task.columns
    	cols.should.include(:name)
    	cols.should.include(:description)
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
      10.times {|i| Task.create(:name => "task #{i}")}
    end

    it 'finds elements within the collection' do
      Task.find(3).name.should.equal('task 3')
    end

    it 'returns nil if find by id is not found' do
      Task.find(999).should.be.nil
    end

  end
end