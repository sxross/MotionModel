module MotionModel

  class Record
    include MotionModel::Model
    include MotionModel::FMDBModelAdapter

    columns :name, :type
  end

  describe "Basic SQL DB operations" do

    before do
      MotionModel::Store.config(MotionModel::FMDBAdapter.new('spec.db', reset: true, ns_log: false))
      Record.create_table
      @alpha = Record.new(id: 123, name: "alpha", type: "bravo")
    end

    it "should start out with an empty table" do
      Record.empty?.should == true
    end

    it "count should return 0" do
      Record.count.should == 0
    end

    describe "after inserting one record" do
      before do
        Record.delete_all
        @alpha.save
      end

      it "should not be an empty table" do
        Record.empty?.should == false
      end

      it "count should return 1" do
        Record.count.should == 1
      end

      it "should be able to select the record" do
        Record.find(id: @alpha.id).first.name.should == "alpha"
      end

      describe "when updating" do
        it "count should return 1" do
          Record.count.should == 1
        end

        it "should return the update data" do
          new_name = 'charlie'
          @alpha.name = new_name
          @alpha.save
          Record.find(id: @alpha.id).first.name.should == new_name
        end
      end

      describe "when deleting" do

        before do
          @alpha.delete
        end

        it "count should return 0" do
          Record.count.should == 0
        end

        it "should not find the record" do
          Record.find(id: @alpha.id).to_a.empty?.should == true
        end
      end

      describe "when deleting all" do

        before do
          Record.delete_all
        end

        it "count should return 0" do
          Record.count.should == 0
        end

        it "should not find the record" do
          Record.find(id: @alpha.id).to_a.empty?.should == true
        end
      end


    end

  end

end
