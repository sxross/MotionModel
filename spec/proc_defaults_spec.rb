describe "proc for defaults" do
  describe "accepts a proc or block for default" do
    describe "accepts proc" do
      class AcceptsProc
        include MotionModel::Model
        include MotionModel::ArrayModelAdapter
        columns  subject: { type: :array, default: ->{ [] } }
      end

      before do
        @test1 = AcceptsProc.create
        @test2 = AcceptsProc.create
      end

      it "initializes array type using proc call" do
        @test1.subject.should.be == @test2.subject
      end
    end

    describe "accepts block" do
      class AcceptsBlock
        include MotionModel::Model
        include MotionModel::ArrayModelAdapter
        columns  subject: {
          type: :array, default: begin
            []
          end
        }
      end

      before do
        @test1 = AcceptsBlock.create
        @test2 = AcceptsBlock.create
      end

      it "initializes array type using begin/end block call" do
        @test1.subject.should.be == @test2.subject
      end
    end

    describe "accepts symbol" do
      class AcceptsSym
        include MotionModel::Model
        include MotionModel::ArrayModelAdapter
        columns  subject: { type: :integer, default: :randomize }

        def self.randomize
          rand 1_000_000
        end
      end

      before do
        @test1 = AcceptsSym.create
        @test2 = AcceptsSym.create
      end

      it "initializes column by calling a method" do
        @test1.subject.should.be == @test2.subject
      end
    end

    describe "scalar defaults still work" do
      class AcceptsScalars
        include MotionModel::Model
        include MotionModel::ArrayModelAdapter
        columns  subject: { type: :integer, default: 42 }
      end

      before do
        @test1 = AcceptsScalars.create
      end

      it "initializes column as normal" do
        @test1.subject.should == 42
      end
    end
  end
end
