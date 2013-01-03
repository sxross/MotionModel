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
end
