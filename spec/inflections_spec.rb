describe 'Extensions' do
  describe 'Pluralization' do
    it 'pluralizes a normal word: dog' do
      'dog'.pluralize.should == 'dogs'
    end

    it 'pluralizes words that end in "s": pass' do
      'pass'.pluralize.should == 'passes'
    end

    it "pluralizes words that end in 'us'" do
      'alumnus'.pluralize.should == 'alumni'
    end

    it "pluralizes words that end in 'ee'" do
      'attendee'.pluralize.should == 'attendees'
    end

    it "pluralizes words that end in 'e'" do
      'article'.pluralize.should == 'articles'
    end
  end

  describe 'Singularization' do
    it 'singularizes a normal word: "dogs"' do
      'dogs'.singularize.should == 'dog'
    end

    it "singualarizes a word that ends in 's': passes" do
      'passes'.singularize.should == 'pass'
    end

    it "singualarizes a word that ends in 'ee': assignees" do
      'assignees'.singularize.should == 'assignee'
    end

    it "singualarizes words that end in 'us'" do
      'alumni'.singularize.should == 'alumnus'
    end

    it "singualarizes words that end in 'es'" do
      'articles'.singularize.should == 'article'
    end
  end

  describe 'Irregular Patterns' do
    it "handles person to people singularizing" do
      'people'.singularize.should == 'person'
    end

    it "handles person to people pluralizing" do
      'person'.pluralize.should == 'people'
    end
  end

  describe 'Adding Rules to Inflector' do
    it 'accepts new rules' do
      MotionSupport::Inflector.inflections do |inflect|
        inflect.plural /^foot$/i, 'feet'
        inflect.singular /^feet$/i, 'foot'
      end
      'foot'.pluralize.should == 'feet'
      'feet'.singularize.should == 'foot'
    end
  end
end

