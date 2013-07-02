class SqlAssignee
  include MotionModel::Model
  include MotionModel::FMDBModelAdapter
  columns :assignee_name => :string
  belongs_to :sql_task
end

class SqlTask
  include MotionModel::Model
  include MotionModel::FMDBModelAdapter
  columns       :name => :string,
                :details => :string,
                :some_day => :date
  has_many :sql_assignees
end

class SqlCascadingTask
  include MotionModel::Model
  include MotionModel::FMDBModelAdapter
  columns       :name => :string,
                :details => :string,
                :some_day => :date
  has_many :sql_cascaded_assignees, :dependent => :delete
end

class SqlCascadedAssignee
  include MotionModel::Model
  include MotionModel::FMDBModelAdapter
  columns       :assignee_name => :string
  belongs_to    :sql_cascading_task
  has_many      :sql_employees
end

class SqlEmployee
  include MotionModel::Model
  include MotionModel::FMDBModelAdapter
  columns       :name
  belongs_to    :sql_cascaded_assignee
end

describe "cascading deletes" do

  describe "when marked for destruction" do
    before do
      MotionModel::Store.config(MotionModel::FMDBAdapter.new('spec.db', reset: true, ns_log: false))
      SqlAssignee.create_table
      SqlTask.create_table
      SqlCascadingTask.create_table
      SqlCascadedAssignee.create_table
      SqlEmployee.create_table
    end

    it "deletes assignees that belong to a destroyed task" do
      task = SqlCascadingTask.create(:name => 'cascading')
      task.sql_cascaded_assignees.create(:assignee_name => 'joe')
      task.sql_cascaded_assignees.create(:assignee_name => 'bill')

      SqlCascadingTask.count.should == 1
      SqlCascadedAssignee.count.should == 2

      task.destroy

      SqlCascadingTask.count.should == 0
      SqlCascadedAssignee.count.should == 0
    end

    it "deletes all assignees when all tasks are destroyed" do
      1.upto(3) do |item|
        task = SqlCascadingTask.create :name => "Task #{item}"
        1.upto(3) do |assignee|
          task.sql_cascaded_assignees.create :assignee_name => "assignee #{assignee} for task #{task}"
        end
      end
      SqlCascadingTask.count.should == 3
      SqlCascadedAssignee.count.should == 9

      SqlCascadingTask.destroy_all

      SqlCascadingTask.count.should == 0
      SqlCascadedAssignee.count.should == 0
    end

    it "deletes only one level when a task is destroyed but dependent is delete" do
      task = SqlCascadingTask.create :name => 'dependent => :delete'
      assignee = task.sql_cascaded_assignees.create :assignee_name => 'deletable assignee'
      assignee.sql_employees.create :name => 'person who sticks around'

      SqlCascadingTask.count.should == 1
      SqlCascadedAssignee.count.should == 1
      SqlEmployee.count.should == 1

      task.destroy

      SqlCascadingTask.count.should == 0
      SqlCascadedAssignee.count.should == 0
      SqlEmployee.count.should == 1
    end
  end
end
