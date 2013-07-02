class SqlTransactClass
  include MotionModel::Model
  include MotionModel::FMDBModelAdapter
  columns :name
end

describe "transactions" do
  before do
    MotionModel::Store.config(MotionModel::FMDBAdapter.new('spec.db', reset: true, ns_log: true))
    SqlTransactClass.create_table
  end

  it "allows multiple updates in a single transaction" do
    item = SqlTransactClass.create(:name => 'Joe')
    SqlTransactClass.transaction do
      item.name = 'Bob'
      item.save
      SqlTransactClass.create(:name => 'Billy')
    end
    SqlTransactClass.where(:name => 'Joe').count.should == 0
    SqlTransactClass.where(:name => 'Bob').count.should == 1
    SqlTransactClass.where(:name => 'Billy').count.should == 1
  end

  # it "rolls back the transaction if there is a problem" do
  #   item = SqlTransactClass.create(:name => 'Joe')
  #   SqlTransactClass.transaction do
  #     item.name = 'Bob'
  #     item.save
  #     SqlTransactClass.create(:name => 'Billy')
  #     raise "Bug"
  #   end
  #   SqlTransactClass.where(:name => 'Joe').count.should == 1
  #   SqlTransactClass.where(:name => 'Bob').count.should == 0
  #   SqlTransactClass.where(:name => 'Billy').count.should == 0
  # end

end
