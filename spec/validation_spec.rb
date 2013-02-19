class ValidatableTask
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter
  include MotionModel::Validatable
  columns       :name => :string, 
                :email => :string,
                :some_day => :string,
                :some_float => :float,
                :some_int => :int

  validate      :name, :presence => true
  validate      :name, :length => 2..10
  validate      :email, :email => true
  validate      :some_day, :format => /\A\d?\d-\d?\d-\d\d\Z/
  validate      :some_day, :length => 8..10
  validate      :some_float, :presence => true
  validate      :some_int, :presence => true
end

describe "validations" do
  before do
    @valid_tasks = {
      :name => 'bob',
      :email => 'bob@domain.com',
      :some_day => '12-12-12',
      :some_float => 1.080,
      :some_int => 99
    }
  end

  describe "presence" do
    it "is initially false if name is blank" do
      task = ValidatableTask.new(@valid_tasks.except(:name))
      task.valid?.should === false
    end

    it "contains correct error message if name is blank" do
      task = ValidatableTask.new(@valid_tasks.except(:name))
      task.valid?
      task.error_messages_for(:name).first.should == 
        "incorrect value supplied for name -- should be non-empty."
    end

    it "is true if name is filled in" do
      task = ValidatableTask.create(@valid_tasks.except(:name))
      task.name = 'bob'
      task.valid?.should === true
    end

    it "is false if the float is nil" do
      task = ValidatableTask.new(@valid_tasks.except(:some_float))
      task.valid?.should === false
    end

    it "is true if the float is filled in" do
      task = ValidatableTask.new(@valid_tasks)
      task.valid?.should === true
    end

    it "is false if the integer is nil" do
      task = ValidatableTask.new(@valid_tasks.except(:some_int))
      task.valid?.should === false
    end

    it "is true if the integer is filled in" do
      task = ValidatableTask.new(@valid_tasks)
      task.valid?.should === true
    end

    it "is true if the Numeric datatypes are zero" do
      task = ValidatableTask.new(@valid_tasks)
      task.some_float = 0
      task.some_int = 0
      task.valid?.should === true
    end
  end

  describe "length" do
    it "succeeds when in range of 2-10 characters" do
      task = ValidatableTask.create(@valid_tasks.except(:name))
      task.name = '123456'
      task.valid?.should === true
    end

    it "fails when length less than two characters" do
      task = ValidatableTask.create(@valid_tasks.except(:name))
      task.name = '1'
      task.valid?.should === false
      task.error_messages_for(:name).first.should == 
        "incorrect value supplied for name -- should be between 2 and 10 characters long."
    end

    it "fails when length greater than 10 characters" do
      task = ValidatableTask.create(@valid_tasks.except(:name))
      task.name = '123456709AB'
      task.valid?.should === false
      task.error_messages_for(:name).first.should == 
        "incorrect value supplied for name -- should be between 2 and 10 characters long."
    end
  end

  describe "email" do
    it "succeeds when a valid email address is supplied" do
      ValidatableTask.new(@valid_tasks).should.be.valid?
    end

    it "fails when an empty email address is supplied" do
      ValidatableTask.new(@valid_tasks.except(:email)).should.not.be.valid?
    end

    it "fails when a bogus email address is supplied" do
      ValidatableTask.new(@valid_tasks.except(:email).merge({:email => 'bogus'})).should.not.be.valid?
    end
  end

  describe "format" do
    it "succeeds when date is in the correct format" do
      ValidatableTask.new(@valid_tasks).should.be.valid?
    end

    it "fails when date is in incorrect format" do
      ValidatableTask.new(@valid_tasks.except(:some_day).merge({:some_day => 'a-12-12'})).should.not.be.valid?
    end
  end

  describe "validating one element" do
    it "validates any properly formatted arbitrary string and succeeds" do
      task = ValidatableTask.new
      task.validate_for(:some_day, '12-12-12').should == true
    end

    it "validates any improperly formatted arbitrary string and fails" do
      task = ValidatableTask.new
      task.validate_for(:some_day, 'a-12-12').should == false
    end
  end
end

class VTask
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter
  include MotionModel::Validatable

  columns :name => :string
  validate :name, :presence => true
end

describe "saving with validations" do

  it "fails loudly" do
    task = VTask.new
    lambda { task.save!}.should.raise
  end

  it "can skip the validations" do
    task = VTask.new
    lambda { task.save({:validate => false})}.should.change { VTask.count }
  end

  it "should not save when validation fails" do
    task = VTask.new
    lambda { task.save }.should.not.change{ VTask.count }
    task.save.should == false
  end

  it "saves it when everything is ok" do
    task = VTask.new
    task.name = "Save it"
    lambda { task.save }.should.change { VTask.count }
  end

end
