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
    lambda{PersistTask.serialize_to_file('test.dat')}.should.not.raise
  end
  
  it 'reads persisted model data' do
    PersistTask.serialize_to_file('test.dat')

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
      Foo.serialize_to_file('test.dat')
      
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
      Foo.serialize_to_file('test.dat')
      
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

  describe "remembering filename" do
    class Foo
      include MotionModel::Model
      columns :name => :string
    end

    before do
      Foo.delete_all
      @foo = Foo.create(:name => 'Bob')
    end

    it "deserializes from last file if no filename given (previous method serialize)" do
      Foo.serialize_to_file('test.dat')
      Foo.delete_all
      Foo.count.should == 0
      Foo.deserialize_from_file 
      Foo.count.should == 1
    end

    it "deserializes from last file if no filename given (previous method deserialize)" do
      Foo.serialize_to_file('test.dat')
      Foo.serialize_to_file('bogus.dat')           # serialize sets default filename to something bogus
      File.delete Foo.documents_file('bogus.dat')  # and we get rid of that file
      Foo.deserialize_from_file('test.dat')        # so we'll be sure the default filename last was set by deserialize
      Foo.delete_all
      Foo.count.should == 0
      Foo.deserialize_from_file
      Foo.count.should == 1
    end

    it "serializes to last file if no filename given (previous method serialize)" do
      Foo.serialize_to_file('test.dat')
      Foo.create(:name => 'Ted')
      Foo.serialize_to_file 
      Foo.delete_all
      Foo.count.should == 0
      Foo.deserialize_from_file('test.dat')
      Foo.count.should == 2
    end

    it "serializes to last file if no filename given (previous method deserialize)" do
      Foo.serialize_to_file('test.dat')
      Foo.delete_all
      Foo.serialize_to_file('bogus.dat')           # serialize sets default filename to something bogus
      File.delete Foo.documents_file('bogus.dat')  # and we get rid of that file
      Foo.deserialize_from_file('test.dat')        # so we'll be sure the default filename was last set by deserialize
      Foo.create(:name => 'Ted')
      Foo.serialize_to_file 
      Foo.delete_all
      Foo.count.should == 0
      Foo.deserialize_from_file('test.dat')
      Foo.count.should == 2
    end

  end
end
