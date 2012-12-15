class Hash
  def except(keys)
    self.dup.reject{|k, v| keys.include?(k)}
  end
end

class ValidatableTask
  include MotionModel::Model
  include MotionModel::Validatable
  columns       :name => :string, 
                :email => :string,
                :some_day => :string

  validate      :name, :presence => true
  validate      :name, :length => 2..10
  validate      :email, :email => true
  validate      :some_day, :format => /\A\d?\d-\d?\d-\d\d\Z/
  validate      :some_day, :length => 8..10
end

describe "validations" do
  before do
    @valid_tasks = {
      :name => 'bob',
      :email => 'bob@domain.com',
      :some_day => '12-12-12'
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
