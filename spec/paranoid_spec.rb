class VTask
  include MotionModel::Model
  include MotionModel::Validatable
  include MotionModel::Paranoid

  columns :name => :string
  validate :name, :presence => true
end

describe "Paranoid" do

  it "fails loudly" do
    task = VTask.new
    lambda { task.save!}.should.raise(MotionModel::RecordInvalid)
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