class ModelWithOptions
  include MotionModel::Model
  include MotionModel::Formotion

  columns :name => :string,
          :date => {:type => :date, :formotion => {:picker_type => :date_time}},
          :location => :string
end

describe "formotion" do
  before do
    @subject = ModelWithOptions.create(:name => 'get together', :date => '12-11-13 @ 9:00 PM', :location => 'my house')
  end

  it "generates a formotion hash" do
    @subject.to_formotion.should.not.be.nil
  end

  it "has the correct section title" do
    @subject.to_formotion('test section')[:sections].first[:title].should == 'test section'
  end

  it "has 3 rows" do
    @subject.to_formotion('test section')[:sections].first[:rows].length.should == 3
  end

  it "binds data from rendered form into model fields" do
    @subject.from_formotion!({:name => '007 Reunion', :date => '3-3-13', :location => "Q's Lab"})
    @subject.name.should == '007 Reunion'
    @subject.date.strftime("%Y-%d-%d %H:%M:%S").should == '2013-03-03 12:00:00'
    @subject.location.should == "Q's Lab"
  end
end
