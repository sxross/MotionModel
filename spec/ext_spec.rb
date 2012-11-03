describe 'Extensions' do
  describe 'Pluralization' do
    it 'pluralizes a normal word: dog' do
      Inflector.inflections.pluralize('dog').should == 'dogs'
    end
  
    it 'pluralizes words that end in "s": pass' do
      Inflector.inflections.pluralize('pass').should == 'passes'
    end
    
    it "pluralizes words that end in 'us'" do
      Inflector.inflections.pluralize('alumnus').should == 'alumni'
    end
    
    it "pluralizes words that end in 'ee'" do
      Inflector.inflections.pluralize('attendee').should == 'attendees'
    end
  end
  
  describe 'Singularization' do
    it 'singularizes a normal word: "dogs"' do
      Inflector.inflections.singularize('dogs').should == 'dog'
    end
    
    it "singualarizes a word that ends in 's': passes" do
      Inflector.inflections.singularize('passes').should == 'pass'
    end
    
    it "singualarizes a word that ends in 'ee': assignees" do
      Inflector.inflections.singularize('assignees').should == 'assignee'
    end
    
    it "singualarizes words that end in 'us'" do
      Inflector.inflections.singularize('alumni').should == 'alumnus'
    end
  end
  
  describe 'Irregular Patterns' do
    it "handles person to people singularizing" do
      Inflector.inflections.singularize('people').should == 'person'
    end

    it "handles person to people pluralizing" do
      Inflector.inflections.pluralize('person').should == 'people'
    end
  end
  
  describe 'Adding Rules to Inflector' do
    it 'accepts new rules' do
      Inflector.inflections.irregular /^foot$/, 'feet'
      Inflector.inflections.irregular /^feet$/, 'foot'
      Inflector.inflections.pluralize('foot').should == 'feet'
      Inflector.inflections.singularize('feet').should == 'foot'
    end
  end
end

