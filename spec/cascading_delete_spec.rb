class Assignee
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter
  columns :assignee_name => :string
  belongs_to :task
end

class Task
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter
  columns       :name => :string,
                :details => :string,
                :some_day => :date
  has_many :assignees
end

class CascadingTask
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter
  columns       :name => :string,
                :details => :string,
                :some_day => :date
  has_many :cascaded_assignees, :dependent => :delete
end

class CascadedAssignee
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter
  columns       :assignee_name => :string
  belongs_to    :cascading_task
  has_many      :employees
end

class Employee
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter
  columns       :name
  belongs_to    :CascadedAssignee
end

describe "cascading deletes" do
  # describe "when not marked for destruction" do
  #   it "leaves assignees alone when they are not marked for destruction" do
  #     Task.delete_all
  #     Assignee.delete_all

  #     task = Task.create :name => 'Walk the dog'
  #     task.assignees.create :assignee_name => 'Joe'
  #     lambda{task.destroy}.should.not.change{Assignee.length}
  #   end
  # end

  describe "when marked for destruction" do
    before do
      CascadingTask.delete_all
      CascadedAssignee.delete_all
    end

    it "deletes assignees that belong to a destroyed task" do
      task = CascadingTask.create(:name => 'cascading')
      task.cascaded_assignees_relation.create(:assignee_name => 'joe')
      task.cascaded_assignees_relation.create(:assignee_name => 'bill')

      CascadingTask.count.should == 1
      CascadedAssignee.count.should == 2

      task.destroy

      CascadingTask.count.should == 0
      CascadedAssignee.count.should == 0
    end

    it "deletes all assignees when all tasks are destroyed" do
      1.upto(3) do |item|
        task = CascadingTask.create :name => "Task #{item}"
        1.upto(3) do |assignee|
          task.cascaded_assignees_relation.create :assignee_name => "assignee #{assignee} for task #{task}"
        end
      end
      CascadingTask.count.should == 3
      CascadedAssignee.count.should == 9

      CascadingTask.destroy_all
      
      CascadingTask.count.should == 0
      CascadedAssignee.count.should == 0
    end

    it "deletes only one level when a task is destroyed but dependent is delete" do
      task = CascadingTask.create :name => 'dependent => :delete'
      assignee = task.cascaded_assignees_relation.create :assignee_name => 'deletable assignee'
      assignee.employees_relation.create :name => 'person who sticks around'

      CascadingTask.count.should == 1
      CascadedAssignee.count.should == 1
      Employee.count.should == 1

      task.destroy

      CascadingTask.count.should == 0
      CascadedAssignee.count.should == 0
      Employee.count.should == 1
    end
  end
end
