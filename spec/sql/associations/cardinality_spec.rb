# Example models taken from
# http://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html "Cardinality and associations"

begin
  class Worker
    include MotionModel::Model
    include MotionModel::FMDBModelAdapter
    columns :name
    has_one :office
    belongs_to :manager
  end

  class Office
    include MotionModel::Model
    include MotionModel::FMDBModelAdapter
    columns :name
    belongs_to :worker
  end

  class Manager
    include MotionModel::Model
    include MotionModel::FMDBModelAdapter
    columns :name
    has_many :workers
  end

  class Assignment
    include MotionModel::Model
    include MotionModel::FMDBModelAdapter
    columns :name
    belongs_to :programmer
    belongs_to :project
  end

  class Programmer
    include MotionModel::Model
    include MotionModel::FMDBModelAdapter
    columns :name
    has_many :assignments
    has_many :projects, through: :assignments
  end

  class Project
    include MotionModel::Model
    include MotionModel::FMDBModelAdapter
    columns :name
    has_many :assignments
    has_many :programmers, through: :assignments
  end
end

MotionModel::Store.config(MotionModel::FMDBAdapter.new('spec.db', reset_db: true, ns_log: false))
MODELS = [Worker, Office, Manager, Assignment, Programmer, Project]
id = 0
MODELS.each do |model|
  model.create_table(drop: true)
  id += 1000
  model.create(id: id) # Set initial ID
end

def delete_all
  MODELS.each { |t| t.delete_all }
end
delete_all

describe "Cardinality" do

  before do
    delete_all
  end

  describe "One-to-one" do

    shared "association" do
      it "should have belongs_to association" do
        @_office.worker.should == @worker
      end

      it "should have belongs_to association id" do
        @_office.worker_id.should == @worker.id
      end

      it "should have has_one association" do
        @_worker.office.should == @office
      end
    end

    shared "before save" do
      before do
        @_worker = @worker
        @_office = @office
      end

      behaves_like "association"
    end

    shared "after save" do
      describe "after saving has_one" do
        before do
          @worker.save
          @_worker = Worker.find(@worker.id)
          @_office = Office.find(@office.id)
        end

        behaves_like "association"
      end

      describe "after saving belongs_to" do
        before do
          @office.save
          @_worker = Worker.find(@worker.id)
          @_office = Office.find(@office.id)
        end

        behaves_like "association"
      end
    end

    describe "set belongs_to" do
      before do
        @worker = Worker.new
        @office = Office.new
        @worker.office = @office
      end

      it "should assign inverse" do
        @office.worker.should == @worker
      end

      behaves_like "before save"
      behaves_like "after save"
    end

    describe "set has_one" do
      before do
        @worker = Worker.new
        @office = Office.new
        @office.worker = @worker
      end

      it "should assign inverse" do
        @worker.office.should == @office
      end

      behaves_like "before save"
      behaves_like "after save"
    end
  end

  describe "One-to-many" do

    shared "association" do
      it "should have belongs_to association" do
        @_worker1.manager.should == @manager
      end

      it "should have belongs_to association id" do
        @_worker1.manager_id.should == @manager.id
      end

      it "should have has_many association" do
        @_manager.workers.should == [@worker1, @worker2]
      end
    end

    shared "before save" do
      before do
        # If we haven't saved yet
        @_worker1 = @worker1
        @_worker2 = @worker2
        @_manager = @manager
      end

      behaves_like "association"
    end

    shared "after save" do
      describe "after saving has_many" do
        before do
          @manager.save
          @_worker1 = Worker.find(@worker1.id)
          @_worker2 = Worker.find(@worker2.id)
          @_manager = Manager.find(@manager.id)
        end

        behaves_like "association"
      end

      describe "after saving belongs_to" do
        before do
          @worker2.save # Results in worker1.id = 1001 and worker2.id = 1002 as expected
          @_worker1 = Worker.find(@worker1.id)
          @_worker2 = Worker.find(@worker2.id)
          @_manager = Manager.find(@manager.id)
          @_manager.workers.should == [@worker1, @worker2]
        end

        behaves_like "before save"
      end
    end

    describe "set belongs_to" do
      before do
        @manager = Manager.new
        @worker1 = Worker.new
        @worker2 = Worker.new
        @worker1.manager = @manager
        @worker2.manager = @manager
      end

      it "should assign inverse" do
        @manager.workers.should == [@worker1, @worker2]
      end

      behaves_like "before save"
      behaves_like "after save"
    end

    shared "saved has_many" do
      it "should assign inverse" do
        @worker1.manager.should == @manager
        @worker2.manager.should == @manager
      end

      behaves_like "before save"
      behaves_like "after save"
    end

    describe "set has_many" do
      before do
        @manager = Manager.new
        @worker1 = Worker.new
        @worker2 = Worker.new
        @manager.workers = [@worker1, @worker2]
      end

      behaves_like "saved has_many"
    end

    describe "push has_many" do
      before do
        @manager = Manager.new
        @worker1 = Worker.new
        @worker2 = Worker.new
        @manager.workers_relation.push(@worker1, @worker2)
      end

      behaves_like "saved has_many"
    end

  end

  describe "Many-to-many" do

    describe "set belongs_to" do

      shared "association" do
        it "programmer1 assignments" do
          @programmer1.assignments.should == [@assignment1, @assignment2]
        end

        it "programmer2 assignments" do
          @programmer2.assignments.should == [@assignment3]
        end

        it "programmer3 assignments" do
          @programmer3.assignments.should == [@assignment4]
        end

        it "project1 assignments" do
          @project1.assignments.should == [@assignment1]
        end

        it "project2 assignments" do
          @project2.assignments.should == [@assignment2]
        end

        it "project3 assignments" do
          @project3.assignments.should == [@assignment3, @assignment4]
        end

        # TODO
        #it "should assign has_many through" do
        #  @programmer1.projects.should == [@project1, @project2]
        #end
        #
        #it "should assign has_many through2" do
        #  @project1.programmers.should == [@programmer1]
        #end
        #
        # etc...
        #
      end

      shared "before save" do
        behaves_like "association"
      end

      shared "after save" do
      end

      before do
        @assignment1 = Assignment.new
        @assignment2 = Assignment.new
        @assignment3 = Assignment.new
        @assignment4 = Assignment.new
        @programmer1 = Programmer.new
        @programmer2 = Programmer.new
        @programmer3 = Programmer.new
        @project1 = Project.new
        @project2 = Project.new
        @project3 = Project.new

        @assignment1.programmer = @programmer1
        @assignment1.project = @project1
        @assignment2.programmer = @programmer1
        @assignment2.project = @project2

        @assignment3.programmer = @programmer2
        @assignment3.project = @project3
        @assignment4.programmer = @programmer3
        @assignment4.project = @project3
      end

      behaves_like "before save"

    end

  end
end
