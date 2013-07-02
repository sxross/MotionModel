class SqlMessage
  include MotionModel::Model
  include MotionModel::FMDBModelAdapter
  columns :subject, :string
  belongs_to :author,     :inverse_of => :authored_sql_messages, :joined_class_name => "SqlMessageUser"
  belongs_to :recipient,  :inverse_of => :received_sql_messages, :joined_class_name => "SqlMessageUser"
end

class SqlMessageUser
  include MotionModel::Model
  include MotionModel::FMDBModelAdapter
  columns :name, :string
  has_many :authored_sql_messages, :inverse_of => :author,     :joined_class_name => "SqlMessage"
  has_many :received_sql_messages, :inverse_of => :recipient,  :joined_class_name => "SqlMessage"
end

 describe "nonstandard associations" do

  before do
    MotionModel::Store.config(MotionModel::FMDBAdapter.new('spec.db', reset: true, ns_log: false))
    SqlMessage.create_table
    SqlMessageUser.create_table
    @bob = SqlMessageUser.create(:name => "Bob")
    @frank = SqlMessageUser.create(:name => "Frank")
    @message = SqlMessage.create(
      :subject => "Hello",
      :author => @bob,
      :recipient => @frank
    )
  end

  describe "SqlMessage" do

    describe :author do
      it "should return the author of the message" do
        @message.author.should == @bob
      end
    end

    describe :author_id do
      it "should return the id of the author" do
        @message.author_id.should == @bob.id
      end
    end

    describe :recipient do
      it "should return the receiver of the message" do
        @message.recipient_id.should == @frank.id
        @message.recipient.should == @frank
      end
    end
  end

  describe "SqlMessageUser" do

    describe :authored_sql_messages do
      it "should return messages the user has authored" do
        @bob.authored_sql_messages.to_a.should == [@message]
        @frank.authored_sql_messages.to_a.should == []
      end
    end

    describe :received_sql_messages do
      it "should return messages the user has received" do
        @bob.received_sql_messages.to_a.should == []
        @frank.received_sql_messages.to_a.should == [@message]
      end
    end

  end

end