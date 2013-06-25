Object.send(:remove_const, :SqlTask) if defined?(SqlTask)
class SqlTask
  include MotionModel::Model
  include MotionModel::FMDBModelAdapter
  columns       :name => :string,
                :details => :string,
                :an_integer => :integer,
                :some_day => :date
end

describe 'finders' do
  before do
    MotionModel::Store.config(MotionModel::FMDBAdapter.new('spec.db', reset: true, ns_log: false))
    SqlTask.create_table
  end

  describe :find do
    before do
      1.upto(10) {|i| SqlTask.create(:name => "task #{i}", :id => i)}
    end

    it 'finds elements within the collection' do
      SqlTask.count.should == 10
      SqlTask.find(3).name.should.equal("task 3")
    end

    it 'returns nil if find by id is not found' do
      SqlTask.find(999).should.be.nil
    end
  end

  describe :where do

    it 'returns a FinderQuery object' do
      SqlTask.where(:details => 'foo').should.is_a(MotionModel::SQLScope)
    end

    describe "= operator" do

      describe "when providing a string" do
        it 'returns exact matches' do
          SqlTask.create(:name => 'find me')
          SqlTask.create(:name => 'find me')
          tasks = SqlTask.where(:name => 'find me')
          tasks.count.should.equal(2)
          tasks.first.name.should == 'find me'
        end

        it 'excludes records that do not match exactly' do
          SqlTask.create(:name => 'do not find me')
          tasks = SqlTask.where(:name => 'find me')
          tasks.count.should.equal(0)
        end
      end

      describe "when providing an array" do
        it "returns records that match any of the values specified" do
          task1 = SqlTask.create(:name => 'lorem ipsum', :id => 1)
          task2 = SqlTask.create(:name => 'lorem ipsum', :id => 2)
          task3 = SqlTask.create(:name => 'lorem ipsum', :id => 3)
          tasks = SqlTask.where(:id => [1,3]).all.to_a
          tasks.length.should == 2
          tasks.should.include task1
          tasks.should.include task3
        end
      end

      describe "when providing nil" do
        it 'returns records with null values' do
          task1 = SqlTask.create(:name => nil)
          task2 = SqlTask.create(:name => 'find me')
          tasks = SqlTask.where(:name => nil)
          tasks.count.should.equal(1)
          tasks.first.should == task1
        end
      end

    end

    describe "!= operator" do
      describe "when providing a string" do
        it 'returns records that do not match exactly' do
         task1 = SqlTask.create(:name => 'lorem ipsum')
         task2 = SqlTask.create(:name => 'lorem ipsum dolor sit amet')
         task3 = SqlTask.create(:name => 'dolor sit amet')
         tasks = SqlTask.where({:name => {:'!=' => 'lorem ipsum'}}).all.to_a
         tasks.length.should == 2
         tasks.should.include task2
         tasks.should.include task3
        end
      end
      describe "when providing an array" do
        it "returns records that don't match any of the values specified" do
          task1 = SqlTask.create(:name => 'lorem ipsum', :id => 1)
          task2 = SqlTask.create(:name => 'lorem ipsum', :id => 2)
          task3 = SqlTask.create(:name => 'lorem ipsum', :id => 3)
          tasks = SqlTask.where({:id => {:'!=' => [1,3]}}).all.to_a
          tasks.length.should == 1
          tasks.should.include task2
        end
      end

      describe "when providing nil" do
        it 'returns records without null values' do
          task1 = SqlTask.create(:name => nil)
          task2 = SqlTask.create(:name => 'find me')
          tasks = SqlTask.where(:name => {:"!=" => nil})
          tasks.count.should.equal(1)
          tasks.first.should == task2
        end
      end
    end

    describe "> operator" do
      it 'returns records with values greater than the value specified' do
        task1 = SqlTask.create(:an_integer => 1)
        task2 = SqlTask.create(:an_integer => 2)
        task3 = SqlTask.create(:an_integer => 3)
        tasks = SqlTask.where({:an_integer => {:'>' => 1}}).all.to_a
        tasks.length.should == 2
        tasks.should.include task2
        tasks.should.include task3
      end
    end

    describe ">= operator" do
      it 'returns records with values greater than or equal to the value specified' do
        task1 = SqlTask.create(:an_integer => 1)
        task2 = SqlTask.create(:an_integer => 2)
        task3 = SqlTask.create(:an_integer => 3)
        tasks = SqlTask.where({:an_integer => {:'>=' => 2}}).all.to_a
        tasks.length.should == 2
        tasks.should.include task2
        tasks.should.include task3
      end
    end

    describe "< operator" do
      it 'returns records with values less than the value specified' do
        task1 = SqlTask.create(:an_integer => 1)
        task2 = SqlTask.create(:an_integer => 2)
        task3 = SqlTask.create(:an_integer => 3)
        tasks = SqlTask.where({:an_integer => {:'<' => 2}}).all.to_a
        tasks.length.should == 1
        tasks.should.include task1
      end
    end

    describe "<= operator" do
      it 'returns records with values less than or equal to the value specified' do
        task1 = SqlTask.create(:an_integer => 1)
        task2 = SqlTask.create(:an_integer => 2)
        task3 = SqlTask.create(:an_integer => 3)
        tasks = SqlTask.where({:an_integer => {:'<=' => 2}}).all.to_a
        tasks.length.should == 2
        tasks.should.include task1
        tasks.should.include task2
      end
    end

    describe "between operator" do
      it 'returns records with values greater than or equal to the lower range AND less than or equal to the upper range of the values specified' do
        task1 = SqlTask.create(:an_integer => 1)
        task2 = SqlTask.create(:an_integer => 2)
        task3 = SqlTask.create(:an_integer => 3)
        task4 = SqlTask.create(:an_integer => 4)
        tasks = SqlTask.where({:an_integer => {:between => (1..3)}}).all.to_a
        tasks.length.should == 3
        tasks.should.include task1
        tasks.should.include task2
        tasks.should.include task3
        tasks.should.not.include task4
      end
    end

    describe "like operator" do
      # not implemented
    end

    it 'allows for multiple (chained) query parameters' do
      SqlTask.create(:name => 'find me', :details => "details 1")
      SqlTask.create(:name => 'find me', :details => "details 2")
      tasks = SqlTask.where(:name => 'find me').where({:details => {:'!=' => 'details 1'}}).all.to_a
      tasks.first.details.should.equal('details 2')
      tasks.length.should == 1
    end
  end

  describe :order do

    describe "when providing a symbol" do
      it "should order by the column specified in ascending order" do
        task1 = SqlTask.create(:name => 'find me', :details => "details 2")
        task2 = SqlTask.create(:name => 'find me', :details => "details 3")
        task3 = SqlTask.create(:name => 'find me', :details => "details 1")
        SqlTask.order(:details).to_a.should == [task3, task1, task2]
      end
    end

    describe "when providing a hash" do
      it "should order by the column specified by the order specified" do
        task1 = SqlTask.create(:name => 'find me', :details => "details 2")
        task2 = SqlTask.create(:name => 'find me', :details => "details 3")
        task3 = SqlTask.create(:name => 'find me', :details => "details 1")
        SqlTask.order(:details => :desc).to_a.should == [task2, task1, task3]
      end
    end
  end

  describe :limit do
    it "should limit the number of results by the number specified" do
      task1 = SqlTask.create(:name => 'find me')
      task2 = SqlTask.create(:name => 'find me')
      task3 = SqlTask.create(:name => 'find me')
      SqlTask.limit(2).all.to_a.should == [task1, task2]
    end
  end

  describe :group do
    it "should group results by the column specified" do
      task1 = SqlTask.create(:name => 'lorem ipsum', :an_integer => 1)
      task2 = SqlTask.create(:name => 'dolor sit amet', :an_integer => 1)
      task3 = SqlTask.create(:name => 'dolor sit amet', :an_integer => 1)
      task4 = SqlTask.create(:name => 'dolor sit amet', :an_integer => 1)
      SqlTask.select("count(name) AS total").group(:name).to_a.length.should == 2
      SqlTask.select("count(name) AS total").group(:name).first.total.should == 3
      SqlTask.select("count(name) AS total").group(:name).last.total.should == 1
    end
  end


end