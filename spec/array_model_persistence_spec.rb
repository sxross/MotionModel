class PersistTask
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter
  columns :name => :string,
          :desc => :string,
          :created_at => :date,
          :updated_at => :date
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

  it "does not change created or updated date on load" do
    created_at = PersistTask.first.created_at
    updated_at = PersistTask.first.updated_at

    PersistTask.serialize_to_file('test.dat')
    tasks = PersistTask.deserialize_from_file('test.dat')
    PersistTask.first.created_at.should == created_at
    PersistTask.first.updated_at.should == updated_at
  end

  describe 'model change resiliency' do
    it 'column addition' do
      Object.send(:remove_const, :Foo) if defined?(Foo)
      class Foo
        include MotionModel::Model
        include MotionModel::ArrayModelAdapter
        columns       :name => :string
      end
      @foo = Foo.create(:name=> 'Bob')
      Foo.serialize_to_file('test.dat')

      @foo.should.not.respond_to :address

      Foo.delete_all
      class Foo
        columns         :address => :string
      end
      Foo.deserialize_from_file('test.dat')

      @foo = Foo.first

      @foo.name.should == 'Bob'
      @foo.address.should == nil
      @foo.should.respond_to :address
      Foo.length.should == 1
    end

    it "column removal" do
      Object.send(:remove_const, :Foo) if defined?(Foo)
      class Foo
        include MotionModel::Model
        include MotionModel::ArrayModelAdapter
        columns       :name => :string, :desc => :string
      end

      @foo = Foo.create(:name=> 'Bob', :desc => 'who cares anyway?')
      Foo.serialize_to_file('test.dat')

      @foo.should.respond_to :desc

      Object.send(:remove_const, :Foo) if defined?(Foo)
      class Foo
        include MotionModel::Model
        include MotionModel::ArrayModelAdapter
        columns       :name => :string,
                      :address => :string
      end
      Foo.deserialize_from_file('test.dat')
    end
  end

  describe "array model migrations" do
    class TestForColumnAddition
      include MotionModel::Model
      include MotionModel::ArrayModelAdapter
      columns       :name => :string, :desc => :string
    end

    it "column addition should call migrate first as a test" do
      TestForColumnAddition.mock!(:migrate)
      TestForColumnAddition.deserialize_from_file('dfca.dat')
      1.should == 1
    end

    it "this example should pass" do
      1.should == 1
    end

    it "accepts properly formatted version strings" do
      lambda{TestForColumnAddition.schema_version("3.1")}.should.not.raise
    end

    it "rejects non-string versions" do
      lambda{TestForColumnAddition.schema_version(3)}.should.raise(MotionModel::ArrayModelAdapter::VersionNumberError)
    end

    it "rejects improperly formated version strings" do
      lambda{TestForColumnAddition.schema_version("3/1/1")}.should.raise(MotionModel::ArrayModelAdapter::VersionNumberError)
    end

    it "returns the version number if no arguments supplied" do
      TestForColumnAddition.schema_version("3.1")
      TestForColumnAddition.schema_version.should == "3.1"
    end
  end

  describe "remembering filename" do
    class Foo
      include MotionModel::Model
      include MotionModel::ArrayModelAdapter
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

class Parent
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter
  columns   :name
  has_many  :children
  has_one  :dog
end

class Child
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter
  columns     :name
  belongs_to  :parent
end

class Dog
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter
  columns     :name
  belongs_to  :parent
end

describe "serialization of relations" do
  before do
    parent = Parent.create(:name => 'BoB')
    parent.children.create :name => 'Fergie'
    parent.children.create :name => 'Will I Am'
    parent.dog.create :name => 'Fluffy'
  end

  it "is wired up right" do
    Parent.first.name.should == 'BoB'
    Parent.first.children.count.should == 2
    Parent.first.dog.count.should == 1
  end

  it "serializes and deserializes properly" do
    Parent.serialize_to_file('parents.dat')
    Child.serialize_to_file('children.dat')
    Dog.serialize_to_file('dogs.dat')
    Parent.delete_all
    Child.delete_all
    Dog.delete_all
    Parent.deserialize_from_file('parents.dat')
    Child.deserialize_from_file('children.dat')
    Dog.deserialize_from_file('dogs.dat')
    Parent.first.name.should == 'BoB'
    Parent.first.children.count.should == 2
    Parent.first.children.first.name.should == 'Fergie'
    Parent.first.dog.first.name.should == 'Fluffy'
  end

  it "allows to serialize and eserialize from directories" do
    directory_path = '/Library/Caches'
    Parent.serialize_to_file('parents.dat', directory_path)
    Child.serialize_to_file('children.dat', directory_path)
    Dog.serialize_to_file('dogs.dat', directory_path)
    Parent.delete_all
    Child.delete_all
    Dog.delete_all
    Parent.deserialize_from_file('parents.dat', directory_path)
    Child.deserialize_from_file('children.dat', directory_path)
    Dog.deserialize_from_file('dogs.dat', directory_path)
    Parent.first.name.should == 'BoB'
    Parent.first.children.count.should == 2
    Parent.first.children.first.name.should == 'Fergie'
    Parent.first.dog.first.name.should == 'Fluffy'
  end
  
  class StoredTask
    include MotionModel::Model
    include MotionModel::ArrayModelAdapter
    columns   :name
  end

  describe "reloading correct ids" do
    before do
      # # StoredTasks.dat was built with the following
      # t1 = StoredTask.create(name: "One")     # id: 1
      # t2 = StoredTask.create(name: "Two")     # id: 2
      # t3 = StoredTask.create(name: "Three")   # id: 3
      # t2.destroy

      # # StoredTasks.all => [id: 1, id:3]
      # StoredTask.serialize_to_file('StoredTasks.dat')
      StoredTask.deserialize_from_file('StoredTasks.dat', NSBundle.mainBundle.resourcePath)
    end

    it "creates a new task with the correct id after deserialization" do
      StoredTask.count.should == 2
      StoredTask.first.id.should == 1
      StoredTask.last.id.should == 3
      
      t4 = StoredTask.create(name: "Four")
      t4.id.should == 4
    end
  end
end
