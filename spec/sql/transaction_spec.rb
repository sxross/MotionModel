class SqlTransactClass
  include MotionModel::Model
  include MotionModel::FMDBModelAdapter
  include MotionModel::Model::Transactions
  columns :name, :age
end

describe "transactions" do
  before do
    MotionModel::Store.config(MotionModel::FMDBAdapter.new('spec.db', reset: true, ns_log: false))
    SqlTransactClass.create_table
  end

  it "wraps a transaction but auto-commits" do
    item = SqlTransactClass.create(:name => 'joe', :age => 22)
    item.transaction do
      item.name = 'Bob'
    end
    item.name.should == 'Bob'
    SqlTransactClass.where(:name => 'Bob').count.should == 1
  end

  it "wraps a transaction but can rollback to a savepoint" do
    item = SqlTransactClass.create(:name => 'joe', :age => 22)
    item.transaction do
      item.name = 'Bob'
      item.rollback
    end
    item.name.should == 'joe'
    SqlTransactClass.where(:name => 'Joe').count.should == 1
    SqlTransactClass.where(:name => 'Bob').count.should == 0
  end

  it "allows multiple savepoints -- inside one not exercised" do
    item = SqlTransactClass.create(:name => 'joe', :age => 22)
    item.transaction do
      item.transaction do
        item.name = 'Bob'
      end
      item.rollback
      item.name.should == 'joe'
      SqlTransactClass.where(:name => 'Joe').count.should == 1
      SqlTransactClass.where(:name => 'Bob').count.should == 0
    end
   end

  it "allows multiple savepoints -- inside one exercised" do
    item = SqlTransactClass.create(:name => 'joe', :age => 22)
    item.transaction do
      item.transaction do
        item.name = 'Ralph'
        item.rollback
      end
      item.name.should == 'joe'
      SqlTransactClass.where(:name => 'Joe').count.should == 1
      SqlTransactClass.where(:name => 'Bob').count.should == 0
    end
   end

  it "allows multiple savepoints -- set in outside context rollback in inside" do
    item = SqlTransactClass.create(:name => 'joe', :age => 22)
    item.transaction do
      item.name = 'Ralph'
      item.transaction do
        item.rollback
      end
      item.name.should == 'Ralph'
      SqlTransactClass.where(:name => 'Ralph').count.should == 1
    end
   end

  it "allows multiple savepoints -- multiple savepoints exercised" do
    item = SqlTransactClass.create(:name => 'joe', :age => 22)
    item.transaction do
      item.name = 'Ralph'
      item.transaction do
        item.name = 'Paul'
        item.rollback
        item.name.should == 'Ralph'
        SqlTransactClass.where(:name => 'Ralph').count.should == 1
      end
      item.rollback
      item.name.should == 'joe'
      SqlTransactClass.where(:name => 'joe').count.should == 1
    end
   end
end
