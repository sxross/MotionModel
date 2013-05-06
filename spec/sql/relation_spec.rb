#if defined?(ENV['MOTION_MODEL_FMDB'])
#
#  class Dog
#    include MotionModel::Model
#    include MotionModel::FMDBModelAdapter
#    has_one :tail
#    has_many :legs
#    columns :name
#  end
#
#  class Tail
#    include MotionModel::Model
#    include MotionModel::FMDBModelAdapter
#    belongs_to :dog
#    columns length: {type: :integer}
#  end
#
#  class Leg
#    include MotionModel::Model
#    include MotionModel::FMDBModelAdapter
#    belongs_to :dog
#    columns side: {type: :boolean}
#  end
#
#  MotionModel::Store.config(MotionModel::FMDBAdapter.new('spec.db', reset_db: true, ns_log: false))
#  Dog.create_table(drop: true)
#  Tail.create_table(drop: true)
#  Leg.create_table(drop: true)
#
#  # Set initial ID's
#  Dog.create(id: 100)
#  Tail.create(id: 200)
#  Leg.create(id: 300)
#
#  def delete_all
#    [Dog, Tail, Leg].each { |t| t.delete_all }
#  end
#  delete_all
#
#  describe "has_one" do
#    before do
#      @tail = Tail.new length: 4
#      @dog = Dog.new name: "Buddy"
#      @tail.dog = @dog
#    end
#
#    it "should set Tail#dog" do
#      @tail.dog.should == @dog
#    end
#
#    it "should have Tail#dog_id nil" do
#      @tail.dog_id.should == nil
#    end
#
#    it "should set Dog#tail" do
#      @dog.tail.should == @tail
#    end
#
#    describe "when dog saved" do
#      before do
#        delete_all
#        @dog.save
#      end
#
#      it "Dog.count should be correct" do
#        Dog.count.should == 1
#      end
#
#      it "Tail.count should be correct" do
#        Tail.count.should == 1
#      end
#
#      it "id should be set" do
#        @dog.id.should.not == nil
#      end
#
#      it "should set Tail#dog_id" do
#        @tail.dog_id.should == @dog.id
#      end
#    end
#
#  end
#
#  describe "has_many" do
#
#    before do
#      @dog = Dog.new
#      @leg1 = Leg.new side: 'left'; @leg1.dog = @dog
#      @leg2 = Leg.new side: 'right'; @leg2.dog = @dog
#    end
#
#    it "should set Leg#dog" do
#      @leg1.dog.should == @dog
#      @leg2.dog.should == @dog
#    end
#
#    it "should have Leg#dog_id nil" do
#      @leg1.dog_id.should == nil
#      @leg2.dog_id.should == nil
#    end
#
#    it "should set Dog#legs" do
#      @dog.legs.should == [@leg1, @leg2]
#    end
#
#    describe "when dog saved" do
#      before do
#        delete_all
#        @dog.save
#      end
#
#      it "Dog.count should be correct" do
#        Dog.count.should == 1
#      end
#
#      it "Leg.count should be correct" do
#        Leg.count.should == 2
#      end
#
#      it "should set Leg#dog_id" do
#        @leg1.dog_id.should == @dog.id
#        @leg2.dog_id.should == @dog.id
#      end
#    end
#
#  end
#
#end
