if defined?(ENV['MOTION_MODEL_FMDB'])

  # Example models taken from
  # http://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html "Cardinality and associations"

  begin
    class Employee
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
      belongs_to :employee
    end

    class Manager
      include MotionModel::Model
      include MotionModel::FMDBModelAdapter
      columns :name
      has_many :employees
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
  MODELS = [Employee, Office, Manager, Assignment, Programmer, Project]
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
          @_office.employee.should == @employee
        end

        it "should have belongs_to association id" do
          @_office.employee_id.should == @employee.id
        end

        it "should have has_one association" do
          @_employee.office.should == @office
        end
      end

      shared "before save" do
        before do
          @_employee = @employee
          @_office = @office
        end

        behaves_like "association"
      end

      shared "after save" do
        describe "after saving has_one" do
          before do
            @employee.save
            @_employee = Employee.find(@employee.id)
            @_office = Office.find(@office.id)
          end

          behaves_like "association"
        end

        describe "after saving belongs_to" do
          before do
            @office.save
            @_employee = Employee.find(@employee.id)
            @_office = Office.find(@office.id)
          end

          behaves_like "association"
        end
      end

      describe "set belongs_to" do
        before do
          @employee = Employee.new
          @office = Office.new
          @employee.office = @office
        end

        it "should assign inverse" do
          @office.employee.should == @employee
        end

        behaves_like "before save"
        behaves_like "after save"
      end

      describe "set has_one" do
        before do
          @employee = Employee.new
          @office = Office.new
          @office.employee = @employee
        end

        it "should assign inverse" do
          @employee.office.should == @office
        end

        behaves_like "before save"
        behaves_like "after save"
      end
    end

    describe "One-to-many" do

      shared "association" do
        it "should have belongs_to association" do
          @_employee1.manager.should == @manager
        end

        it "should have belongs_to association id" do
          @_employee1.manager_id.should == @manager.id
        end

        it "should have has_many association" do
          @_manager.employees.should == [@employee1, @employee2]
        end
      end

      shared "before save" do
        before do
          # If we haven't saved yet
          @_employee1 = @employee1
          @_employee2 = @employee2
          @_manager = @manager
        end

        behaves_like "association"
      end

      shared "after save" do
        describe "after saving has_many" do
          before do
            @manager.save
            @_employee1 = Employee.find(@employee1.id)
            @_employee2 = Employee.find(@employee2.id)
            @_manager = Manager.find(@manager.id)
          end

          behaves_like "association"
        end

        describe "after saving belongs_to" do
          before do
            @employee2.save # Results in employee1.id = 1001 and employee2.id = 1002 as expected
            @_employee1 = Employee.find(@employee1.id)
            @_employee2 = Employee.find(@employee2.id)
            @_manager = Manager.find(@manager.id)
            @_manager.employees.should == [@employee1, @employee2]
          end

          behaves_like "before save"
        end
      end

      describe "set belongs_to" do
        before do
          @manager = Manager.new
          @employee1 = Employee.new
          @employee2 = Employee.new
          @employee1.manager = @manager
          @employee2.manager = @manager
        end

        it "should assign inverse" do
          @manager.employees.should == [@employee1, @employee2]
        end

        behaves_like "before save"
        behaves_like "after save"
      end

      shared "saved has_many" do
        it "should assign inverse" do
          @employee1.manager.should == @manager
          @employee2.manager.should == @manager
        end

        behaves_like "before save"
        behaves_like "after save"
      end

      describe "set has_many" do
        before do
          @manager = Manager.new
          @employee1 = Employee.new
          @employee2 = Employee.new
          @manager.employees = [@employee1, @employee2]
        end

        behaves_like "saved has_many"
      end

      describe "push has_many" do
        before do
          @manager = Manager.new
          @employee1 = Employee.new
          @employee2 = Employee.new
          @manager.employees_relation.push(@employee1, @employee2)
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
end
