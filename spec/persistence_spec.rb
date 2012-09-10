class PersistTask
  include MotionModel::Model
  columns :name, :desc
end

describe 'persistence' do
  before do
    PersistTask.delete_all
    %w(one two three).each do |task|
      @tasks = PersistTask.create(:name => "name #{task}")
    end
  end
  
  it "serializes data" do
    lambda{@tasks.serialize_to_file('test.dat')}.should.not.raise
  end
  
  it 'reads persisted model data' do
    @tasks.serialize_to_file('test.dat')

    PersistTask.delete_all
    
    PersistTask.count.should      == 0
    
    tasks = PersistTask.deserialize_from_file('test.dat')
    
    PersistTask.count.should      == 3
    PersistTask.first.name.should == 'name one'
    PersistTask.last.name.should  == 'name three'
  end
  
  describe 'model change resiliency' do
    it 'column addition' do
      class Foo
        include MotionModel::Model
        columns       :name => :string
      end
      @foo = Foo.create(:name=> 'Bob')
      @foo.serialize_to_file('test.dat')
      
      @foo.should.not.respond_to :address
  
      class Foo
        include MotionModel::Model
        columns       :name => :string,
                      :address => :string
      end
      Foo.deserialize_from_file('test.dat')
      
      @foo = Foo.first
      
      @foo.name.should == 'Bob'
      @foo.address.should == nil
      @foo.should.respond_to :address
      Foo.length.should == 1
    end
    
    it "column removal" do
      class Foo
        include MotionModel::Model
        columns       :name => :string, :desc => :string
      end
      @foo = Foo.create(:name=> 'Bob', :desc => 'who cares anyway?')
      @foo.serialize_to_file('test.dat')
      
      @foo.should.respond_to :desc
  
      class Foo
        include MotionModel::Model
        columns       :name => :string,
                      :address => :string
      end
      Foo.deserialize_from_file('test.dat')
      
      @foo = Foo.first
      
      @foo.name.should == 'Bob'
      @foo.address.should == nil
      @foo.should.not.respond_to :desc
      @foo.should.respond_to :address
      Foo.length.should == 1
    end
  end
end
