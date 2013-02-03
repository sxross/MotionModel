class VTask
  include MotionModel::Model
  include MotionModel::Validatable
  include MotionModel::Paranoid

  columns :name => :string
  validate :name, :presence => true
end

describe "Paranoid" do
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

  it "can skip validations" do
    task = VTask.new
    lambda { task.save!}.should.change { VTask.count }
  end

  it "saves twices and don't fuck" do
    lambda { VTask.new.save!}.should.change { VTask.count }
    lambda { VTask.new.save}.should.not.change { VTask.count }
  end
end