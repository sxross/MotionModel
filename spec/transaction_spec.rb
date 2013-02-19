class TransactClass
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter
  include MotionModel::Model::Transactions
  columns :name, :age
  has_many :transaction_things
end

class TransactionThing
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter
  include MotionModel::Model::Transactions
  columns :thingie_description
  belongs_to :transact_class
end

describe "transactions" do
  before{TransactClass.destroy_all}

  it "wraps a transaction but auto-commits" do
    item = TransactClass.create(:name => 'joe', :age => 22)
    item.transaction do
      item.name = 'Bob'
    end
    item.name.should == 'Bob'
    TransactClass.find(:name).eq('Bob').count.should == 1
  end

  it "wraps a transaction but can rollback to a savepoint" do
    item = TransactClass.create(:name => 'joe', :age => 22)
    item.transaction do
      item.name = 'Bob'
      item.rollback
    end
    item.name.should == 'joe'
    TransactClass.find(:name).eq('joe').count.should == 1
    TransactClass.find(:name).eq('Bob').count.should == 0
  end

  it "allows multiple savepoints -- inside one not exercised" do
    item = TransactClass.create(:name => 'joe', :age => 22)
    item.transaction do
      item.transaction do
        item.name = 'Bob'
      end
      item.rollback
      item.name.should == 'joe'
      TransactClass.find(:name).eq('joe').count.should == 1
      TransactClass.find(:name).eq('Bob').count.should == 0
    end
   end

  it "allows multiple savepoints -- inside one exercised" do
    item = TransactClass.create(:name => 'joe', :age => 22)
    item.transaction do
      item.transaction do
        item.name = 'Ralph'
        item.rollback
      end
      item.name.should == 'joe'
      TransactClass.find(:name).eq('joe').count.should == 1
      TransactClass.find(:name).eq('Bob').count.should == 0
    end
   end

  it "allows multiple savepoints -- set in outside context rollback in inside" do
    item = TransactClass.create(:name => 'joe', :age => 22)
    item.transaction do
      item.name = 'Ralph'
      item.transaction do
        item.rollback
      end
      item.name.should == 'Ralph'
      TransactClass.find(:name).eq('Ralph').count.should == 1
    end
   end

  it "allows multiple savepoints -- multiple savepoints exercised" do
    item = TransactClass.create(:name => 'joe', :age => 22)
    item.transaction do
      item.name = 'Ralph'
      item.transaction do
        item.name = 'Paul'
        item.rollback
        item.name.should == 'Ralph'
        TransactClass.find(:name).eq('Ralph').count.should == 1
      end
      item.rollback
      item.name.should == 'joe'
      TransactClass.find(:name).eq('joe').count.should == 1
    end
   end
end
