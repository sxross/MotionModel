class Assignee
  include MotionModel::Model
  columns :assignee_name => :string
  belongs_to :task
end

class Task
  include MotionModel::Model
  columns       :name => :string, 
  							:details => :string,
  							:some_day => :date
  has_many :assignees
end


Inflector.inflections.irregular 'assignees', 'assignee'
Inflector.inflections.irregular 'assignee', 'assignees'

describe 'related objects' do
  describe 'has_many' do
    it "is wired up right" do
      lambda {Task.new}.should.not.raise
      lambda {Task.new.assignees}.should.not.raise
    end
  
    it 'relation objects are empty on initialization' do
      a_task = Task.create
      a_task.assignees.all.should.be.empty
    end
    
    it "supports creating related objects directly on parents" do
      a_task = Task.create(:name => 'Walk the Dog')
      a_task.assignees.create(:assignee_name => 'bob')
      a_task.assignees.length.should == 1
      a_task.assignees.first.assignee_name.should == 'bob'
      Assignee.count.should == 1
    end
    
    describe "supporting has_many" do
      before do
        Task.delete_all
        Assignee.delete_all
      
        @tasks = []
        @assignees = []
        1.upto(3) do |task|
          t = Task.create(:name => "task #{task}")
          assignee_index = 1
          @tasks << t
          1.upto(task * 2) do |assignee|
            @assignees << t.assignees.create(:assignee_name => "employee #{assignee_index}_assignee_for_task_#{t.id}")
            assignee_index += 1
          end
        end
      end

      it "is wired up right" do
        Task.count.should == 3
        Assignee.count.should == 12        
      end
      
      it "has 2 assignees for the first task" do
        Task.first.assignees.count.should == 2
      end
      
      it "the first assignee for the second task is employee 7" do
        Task.find(2).name.should == @tasks[1].name
        Task.find(2).assignees.first.assignee_name.should == @assignees[2].assignee_name
      end
    end
    
    it 'supports adding related objects to parents' do
      assignee = Assignee.new(:assignee_name => 'Zoe')
      assignee_count = Task.find(3).assignees.count
      Task.find(3).assignees.push(assignee)
      Task.find(3).assignees.count.should == assignee_count + 1
    end
  end
  
  describe "supporting belongs_to" do
    before do
      Task.delete_all
      Assignee.delete_all
    end

    it "allows a child to back-reference its parent" do
      t = Task.create(:name => "Walk the Dog")
      t.assignees.create(:assignee_name => "Rihanna")
      Assignee.first.task.name.should == "Walk the Dog"
    end
  end
end
