class Task
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter
  columns       :name => :string,
  							:details => :string,
  							:some_day => :date
end

describe 'finders' do
  before do
    Task.delete_all
    1.upto(10) {|i| Task.create(:name => "task #{i}", :id => i)}
  end

  describe 'find' do
    it 'finds elements within the collection' do
      Task.count.should == 10
      Task.find(3).name.should.equal("task 3")
    end

    it 'returns nil if find by id is not found' do
      Task.find(999).should.be.nil
    end
      
    it 'looks into fields if field name supplied' do
      Task.create(:name => 'find me')
      tasks = Task.find(:name).eq('find me')
      tasks.count.should.equal(1)
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
      Task.where(:details).should.is_a(MotionModel::ArrayFinderQuery)
    end
      
    it 'using where instead of find' do
      atask = Task.create(:name => 'find me', :details => "details 1")
      found_task = Task.where(:details).contain("s 1").first.details.should == 'details 1'
    end

    it 'should returns first 5 results for where call' do
      Task.where(:name).contains('task').first(5).length.should == 5
    end

    it 'should returns last 5 results for where call' do
      Task.where(:name).contains('task').last(5).length.should == 5
    end

    it 'should returns first element for where call' do
      Task.where(:name).contains('task').first.should.is_a Task
    end

    it 'should returns last element for where call' do
      Task.where(:name).contains('task').last.should.is_a Task
    end

    it "performs set inclusion(in) queries" do
      class InTest
        include MotionModel::Model
        include MotionModel::ArrayModelAdapter
        columns :name
      end
        
      1.upto(10) do |i|
        InTest.create(:id => i, :name => "test #{i}")
      end
        
      results = InTest.find(:id).in([3, 5, 7])
      results.length.should == 3
    end

    it 'handles case-insensitive queries as default' do
      task = Task.create :name => 'camelCase'
      Task.find(:name).eq('camelcase').all.length.should == 1
    end

    it 'handles case-sensitive queries' do
      task = Task.create :name => 'Bob'
      Task.find(:name).eq('bob', :case_sensitive => true).all.length.should == 0
    end
    
    it 'all returns all members of the collection as an array' do
      Task.all.each { |t| puts t }
      Task.all.length.should.equal(10)
    end
    
    it 'each yields each row in sequence' do
      task_id = nil
      Task.each do |task|
        task_id.should.<(task.id) if task_id
        task_id = task.id
      end
    end

    it 'should returns first 5 members of the collection as an array' do
      Task.first(5).length.should.equal(5)
    end

    it 'should returns last 5 members of the collection as an array' do
      Task.last(5).length.should.equal(5)
    end

    it 'should be a difference between first and last element' do
      first_records = Task.first(5)
      last_records = Task.last(5)

      first_records[0].should.not == last_records[0]
    end

    it 'should returns first element' do
      Task.first.should.is_a Task
    end

    it 'should returns last element' do
      Task.last.should.is_a Task
    end
    
    describe 'comparison finders' do
      
      it 'returns elements with id greater than 5' do
        tasks = Task.where(:id).gt(5).all
        tasks.length.should.equal(5)
        tasks.reject{|t| [6,7,8,9,10].include?(t.id)}.should.be.empty
      end
      
      it 'returns elements with id greater than or equal to 7' do
        tasks = Task.where(:id).gte(7).all
        tasks.length.should.equal(4)
        tasks.reject{|t| [7,8,9,10].include?(t.id)}.should.be.empty
      end
      
      it 'returns elements with id less than 5' do
        tasks = Task.where(:id).lt(5).all
        tasks.length.should.equal(4)
        tasks.reject{|t| [1,2,3,4].include?(t.id)}.should.be.empty
      end
      
      it 'returns elements with id less than or equal to 3' do
        tasks = Task.where(:id).lte(3).all
        tasks.length.should.equal(3)
        tasks.reject{|t| [1,2,3].include?(t.id)}.should.be.empty
      end
      
    end
      
    describe 'block-style finders' do
      before do
        @items_less_than_5 = Task.find{|item| item.name.split(' ').last.to_i < 5}
      end
        
      it 'returns a FinderQuery' do
        @items_less_than_5.should.is_a MotionModel::ArrayFinderQuery
      end
        
      it 'handles block-style finders' do
        @items_less_than_5.length.should == 4
      end
        
      it 'deals with any arbitrary block finder' do
        @even_items = Task.find do |item|
          test_item = item.name.split(' ').last.to_i
          test_item % 2 == 0 && test_item <= 6
        end
        @even_items.each{|item| item.name.split(' ').last.to_i.should.even?}
        @even_items.length.should == 3   # [2, 4, 6]
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

