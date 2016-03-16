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

class User
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter
  columns :name => :string

  has_many :email_accounts
end

class EmailAccount
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter
  columns :name => :string
  belongs_to :user
end

class BelongsToUser
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter

  columns :name => :string,
          :id => :string

  has_one :belongs_to_profile
end

class BelongsToProfile
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter

  columns :email => :string,
          :id => :string

  belongs_to :belongs_to_user
end

describe 'related objects' do
  describe "supporting belongs_to and has_many with camelcased relations" do
    before do
      EmailAccount.delete_all
      User.delete_all
    end

    it "camelcased style" do
      t = User.create(:name => "Arkan")
      t.email_accounts.create(:name => "Gmail")
      EmailAccount.first.user.name.should == "Arkan"
      User.last.email_accounts.last.name.should == "Gmail"
    end
  end

  describe 'has_many' do
    before do
      Task.delete_all
      Assignee.delete_all
    end

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
      a_task.assignees.count.should == 1
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
          t = Task.create(:name => "task #{task}", :id => task)
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

      it 'supports adding related objects to parents' do
        assignee = Assignee.new(:assignee_name => 'Zoe')
        Task.count.should == 3
        assignee_count = Task.find(3).assignees.count
        Task.find(3).assignees.push(assignee)
        Task.find(3).assignees.count.should == assignee_count + 1
      end

    end

    it "supports creating blank (empty) scratchpad associated objects" do
      task = Task.create :name => 'watch a movie'
      assignee = task.assignees.new # TODO per Rails convention, this should really be #build, not #new
      assignee.assignee_name = 'Chloe'
      assignee.save
      task.assignees.count.should == 1
      task.assignees.first.assignee_name.should == 'Chloe'
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

    describe "belongs_to reassignment" do
      before do
        Task.delete_all
        @t1 = Task.create(:name => "Walk the Dog")
        @t2 = Task.create :name => "Feed the cat"
        @a1 = Assignee.create :assignee_name => "Jim"
      end

      describe "basic wiring" do
        before do
          @t1.assignees << @a1
        end

        it "pushing a created assignee gives a task count of 1" do
          @t1.assignees.count.should == 1
        end

        it "pushing a created assignee gives a cascaded assignee name" do
          @t1.assignees.first.assignee_name.should == "Jim"
        end

        it "pushing a created assignee enables back-referencing a task" do
          @a1.task.name.should == "Walk the Dog"
        end
      end

      describe "when pushing assignees onto two different tasks" do
        before do
          @t2.assignees << @a1
        end

        it "pushing assignees to two different tasks lets the last task have the assignee (count)" do
          @t2.assignees.count.should == 1
        end

        it "pushing assignees to two different tasks removes the assignee from the first task (count)" do
          @t1.assignees.count.should == 0
        end

        it "pushing assignees to two different tasks lets the last task have the assignee (assignee name)" do
          @t2.assignees.first.assignee_name.should == "Jim"
        end

        it "pushing assignees to two different tasks lets the last task have the assignee (back reference)" do
          @a1.task.name.should == "Feed the cat"
        end
      end

      describe "directly assigning to child" do
        it "directly assigning a different task to an assignee changes the assignee's task" do
          @a1.task_id = @t1.id
          @a1.save
          @t1.assignees.count.should == 1
          @t1.assignees.first.assignee_name.should == @a1.assignee_name
        end

        it "directly assigning an instance of a task to an assignee changes the assignee's task" do
          @a1.task = @t1
          @a1.save
          @t1.assignees.count.should == 1
          @t1.assignees.first.assignee_name.should == @a1.assignee_name
        end

        it "directly assigning the assignee a nil task twice doesn't change anything" do
          @a1.task.should == nil
          @a1.task = nil
          @a1.dirty?.should == false
        end

        it "directly assigning the existing task to an assignee doesn't change anything" do
          @a1.task = @t1
          @a1.save
          @a1.task = @t1
          @a1.dirty?.should == false
        end

        it "directly assigning the assignee a nil task twice doesn't change anything" do
          @a1.task.should == nil
          @a1.task = nil
          @a1.dirty?.should == false
        end
      end
    end
  end

  it 'can get parent from a has_one create relation with a custom ID' do
    user = BelongsToUser.create(name: 'Sam', id: "")
    profile = user.belongs_to_profile.create(email: 'ss@gmail.com')

    BelongsToProfile.first.belongs_to_user.should.is_a?(BelongsToUser)
    BelongsToProfile.first.belongs_to_user.name.should == 'Sam'

    BelongsToUser.first.belongs_to_profile.first.belongs_to_user.should.is_a?(BelongsToUser)
    BelongsToUser.first.belongs_to_profile.first.belongs_to_user.name.should == 'Sam'
  end
end

