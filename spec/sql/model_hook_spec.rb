Object.send(:remove_const, :SqlTaskModelHook) if defined?(SqlTaskModelHook)
class SqlTaskModelHook
  attr_reader :before_delete_called, :after_delete_called
  attr_reader :before_save_called, :after_save_called

  include MotionModel::Model
  include MotionModel::FMDBModelAdapter
  columns       :name => :string,
                :details => :string,
                :some_day => :date

  def before_delete(sender)
    @before_delete_called = true
  end

  def after_delete(sender)
    @after_delete_called = true
  end

  def before_save(sender)
    @before_save_called = true
  end

  def after_save(sender)
    @after_save_called = true
  end

end

describe "lifecycle hooks" do

  before do
    MotionModel::Store.config(MotionModel::FMDBAdapter.new('spec.db', reset: true, ns_log: false))
    SqlTaskModelHook.create_table
  end

  describe "delete and destroy" do
    before{@task = SqlTaskModelHook.create(:name => 'joe')}

    it "calls the before delete hook when delete is called" do
      lambda{@task.delete}.should.change{@task.before_delete_called}
    end

    it "calls the after delete hook when delete is called" do
      lambda{@task.delete}.should.change{@task.after_delete_called}
    end

   it "calls the before delete hook when destroy is called" do
      lambda{@task.destroy}.should.change{@task.before_delete_called}
    end

    it "calls the after delete hook when destroy is called" do
      lambda{@task.destroy}.should.change{@task.after_delete_called}
    end
  end

  describe "create and save" do
    before{@task = SqlTaskModelHook.new(:name => 'joe')}

    it "calls before_save hook on save" do
      lambda{@task.save}.should.change{@task.before_save_called}
    end

    it "calls after_save hook on save" do
      lambda{@task.save}.should.change{@task.after_save_called}
    end
  end
end
