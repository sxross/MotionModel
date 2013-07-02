Object.send(:remove_const, :ModelWithColumnOptions) if defined?(ModelWithColumnOptions)
class ModelWithColumnOptions
  include MotionModel::Model
  include MotionModel::FMDBModelAdapter
  include MotionModel::Formotion

  columns :date => {:type => :date, :formotion => {:picker_type => :date_time}}
end

describe "column options" do
  before do
    MotionModel::Store.config(MotionModel::FMDBAdapter.new('spec.db', reset: true, ns_log: false))
    ModelWithColumnOptions.create_table
  end

  it "accepts the hash form of column declaration" do
    lambda{ModelWithColumnOptions.new}.should.not.raise
  end

  it "retrieves non-nil options for a column declaration" do
    instance = ModelWithColumnOptions.new
    instance.options(:date).should.not.be.nil
  end

  it "retrieves correct options for a column declaration" do
    instance = ModelWithColumnOptions.new
    instance.options(:date)[:formotion].should.not.be.nil
    instance.options(:date)[:formotion][:picker_type].should == :date_time
  end
end