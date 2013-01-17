class ModelWithOptions
  include MotionModel::Model
  include MotionModel::Formotion

  columns :name => :string,
          :date => {:type => :date, :formotion => {:picker_type => :date_time}},
          :location => :string,
          :created_at => :date,
          :updated_at => :date

  has_many :related_models
end

class RelatedModel
  include MotionModel::Model

  columns :name => :string
  belongs_to :model_with_options
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
    @subject.from_formotion!({:name => '007 Reunion', :date => 1358197323, :location => "Q's Lab"})
    @subject.name.should == '007 Reunion'
    @subject.date.strftime("%Y-%m-%d %H:%M").should == '2013-01-14 13:02'
    @subject.location.should == "Q's Lab"
  end

  it "does not include auto date fields in the hash by default" do
    @subject.to_formotion[:sections].first[:rows].has_hash_key?(:created_at).should == false
    @subject.to_formotion[:sections].first[:rows].has_hash_key?(:updated_at).should == false
  end

  it "can optionally include auto date fields in the hash" do
    result = @subject.to_formotion(nil, true)[:sections].first[:rows].has_hash_value?(:created_at).should == true
    result = @subject.to_formotion(nil, true)[:sections].first[:rows].has_hash_value?(:updated_at).should == true
  end

  it "does not include related columns in the collection" do
    result = @subject.to_formotion[:sections].first[:rows].has_hash_value?(:related_models).should == false
  end
end
