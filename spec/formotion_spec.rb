Object.send(:remove_const, :ModelWithOptions) if defined?(ModelWithOptions)
class ModelWithOptions
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter
  include MotionModel::Formotion

  columns :name => :string,
          :date => {:type => :date, :formotion => {:picker_type => :date_time}},
          :location => {:type => :string, :formotion => {:section => :address}},
          :created_at => :date,
          :updated_at => :date

  has_many :related_models

  has_formotion_sections :address => { title: "Address" }

end

class RelatedModel
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter

  columns :name => :string
  belongs_to :model_with_options
end

def section(subject)
  subject[:sections]
end

def rows(subject)
  section(subject).first[:rows]
end

def first_row(subject)
  rows(subject).first
end

describe "formotion" do
  before do
    @subject = ModelWithOptions.create(:name => 'get together', :date => '12-11-13 @ 9:00 PM', :location => 'my house')
  end

  it "generates a formotion hash" do
    @subject.to_formotion.should.not.be.nil
  end

  it "has the correct form title" do
    @subject.to_formotion('test form')[:title].should == 'test form'
  end

  it "has two sections" do
    @subject.to_formotion[:sections].length.should == 2
  end

  it "has 2 rows in default section" do
    @subject.to_formotion[:sections].first[:rows].length.should == 2
  end

  it "does not include title in the default section" do
    @subject.to_formotion[:sections].first[:title].should == nil
  end

  it "does include title in the :address section" do
    @subject.to_formotion[:sections][1][:title].should == 'Address'
  end

  it "has 1 row in :address section" do
    @subject.to_formotion[:sections][1][:rows].length.should == 1
  end

  it "value of location row in :address section is 'my house'" do
    @subject.to_formotion[:sections][1][:rows].first[:value].should == 'my house'
  end

  it "value of name row is 'get together'" do
    first_row(@subject.to_formotion)[:value].should == 'get together'
  end

  it "binds data from rendered form into model fields" do
    @subject.from_formotion!({:name => '007 Reunion', :date => 1358197323, :location => "Q's Lab"})
    @subject.name.should == '007 Reunion'
    @subject.date.utc.strftime("%Y-%m-%d %H:%M").should == '2013-01-14 21:02'
    @subject.location.should == "Q's Lab"
  end

  describe 'auto fields behavior' do
    before do
      @first_row = @subject.to_formotion[:sections].first[:rows]
    end

    it "does not include auto date fields in the hash by default" do
      @first_row.has_hash_key?(:created_at).should == false
      @first_row.has_hash_key?(:updated_at).should == false
    end

    it "can optionally include auto date fields in the hash" do
      optional_result = @subject.to_formotion(nil, true)[:sections].first[:rows]
      result = optional_result.has_hash_key?(:created_at).should == true
      result = optional_result.has_hash_key?(:updated_at).should == true
    end

    it "does not include related columns in the collection" do
      result = @first_row.has_hash_value?(:related_models).should == false
    end
  end
end
