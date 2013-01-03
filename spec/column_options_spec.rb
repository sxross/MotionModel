class ModelWithOptions
  include MotionModel::Model

  columns :date => {:type => :date, :formotion => {:picker_type => :date_time}}
end

describe "column options" do
  it "accepts the hash form of column declaration" do
    lambda{ModelWithOptions.new}.should.not.raise
  end

  it "retrieves non-nil options for a column declaration" do
    instance = ModelWithOptions.new
    instance.options(:date).should.not.be.nil
  end

  it "retrieves correct options for a column declaration" do
    instance = ModelWithOptions.new
    instance.options(:date)[:formotion].should.not.be.nil
    instance.options(:date)[:formotion][:picker_type].should == :date_time
  end
end
