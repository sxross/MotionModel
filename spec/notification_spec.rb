class NotifiableTask
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter
  columns :name
  @@notification_called = false
  @@notification_details = :none
  
  def notification_called; @@notification_called; end
  def notification_called=(value); @@notification_called = value; end
  def notification_details; @@notification_details; end
  def notification_details=(value); @@notification_details = value; end

  def hookup_events
    @notification_id = NSNotificationCenter.defaultCenter.addObserverForName('MotionModelDataDidChangeNotification', object:self, queue:NSOperationQueue.mainQueue, 
      usingBlock:lambda{|notification|
      @@notification_called = true
      @@notification_details = notification.userInfo
    }
    )
  end

  def dataDidChange(notification)
    @notification_called = true
    @notification_details = notification.userInfo
  end

  def teardown_events
    NSNotificationCenter.defaultCenter.removeObserver @notification_id
  end
end

describe 'data change notifications' do
  before do
    NotifiableTask.delete_all
    @task = NotifiableTask.new(:name => 'bob')
    @task.notification_called = false
    @task.notification_details = :nothing
    @task.hookup_events
  end
  
  after do
    @task.teardown_events
  end
  
  it "fires a change notification when an item is added" do
    @task.save
    @task.notification_called.should == true
  end
  
  it "contains an add notification for new objects" do
    @task.save
    @task.notification_details[:action].should == 'add'
  end
  
  it "contains an update notification for an updated object" do
    @task.save
    @task.name = "Bill"
    @task.save
    @task.notification_details[:action].should == 'update'
  end
  
  it "does not get a delete notification for delete_all" do
    @task.save
    @task.notification_called = false
    NotifiableTask.delete_all
    @task.notification_called.should == false
  end

  it "contains a delete notification for a deleted object" do
    @task.save
    @task.delete
    @task.notification_details[:action].should == 'delete'
  end
end

