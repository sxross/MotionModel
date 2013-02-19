describe "time conversions" do
  it "NSDate and Time should agreee on minutes since epoch" do
    t = Time.new
    d = NSDate.dateWithTimeIntervalSince1970(t.to_f)
    t.to_f.should == d.timeIntervalSince1970
  end

  it "Parsing '3/18/12 @ 7:00 PM' With Natural Language should work right" do
    NSDate.dateWithNaturalLanguageString('3/18/12 @ 7:00 PM'.gsub('-','/'), locale:NSUserDefaults.standardUserDefaults.dictionaryRepresentation).
      strftime("%m-%d-%Y | %I:%M %p").
      should == "03-18-2012 | 07:00 PM"
  end

  it "Sets created_at when an item is created" do
    class Creatable
      include MotionModel::Model
      include MotionModel::ArrayModelAdapter
      columns :name => :string,
              :created_at => :date
    end

    c = Creatable.new(:name => 'test')
    lambda{c.save}.should.change{c.created_at}
  end

    it "Sets updated_at when an item is created" do
    class Updateable
      include MotionModel::Model
      include MotionModel::ArrayModelAdapter
      columns :name => :string,
              :created_at => :date,
              :updated_at => :date
    end

    c = Updateable.create(:name => 'test')
    c.name = 'test 1'
    lambda{c.save}.should.not.change{c.created_at}
    d = Updateable.create(:name => 'test')
    d.name = 'test 2'
    lambda{d.save}.should.change{d.updated_at}
  end

end
