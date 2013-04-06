class ModelWithAdapter
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter

  columns :name
end

describe 'adapters with adapter method defined' do
  it "does not raise an exception" do
    lambda{ModelWithAdapter.create(:name => 'bob')}.should.not.raise
  end

  it "provides humanized string representation of the current adapter" do
    ModelWithAdapter.create(:name => 'bob').adapter.should == 'Array Model Adapter'
  end
end

class ModelWithoutAdapter
  include MotionModel::Model

  columns :name
end

describe 'adapters without adapter method defined' do
  it "raises an exception" do
    lambda{
      ModelWithoutAdapter.new
    }.should.raise(MotionModel::AdapterNotFoundError)
  end
end
