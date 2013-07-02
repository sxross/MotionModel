Object.send(:remove_const, :SqlImage) if defined?(SqlImage)
Object.send(:remove_const, :SqlUser) if defined?(SqlUser)
Object.send(:remove_const, :SqlProduct) if defined?(SqlProduct)

class SqlImage
  include MotionModel::Model
  include MotionModel::FMDBModelAdapter
  columns :filename, :string
  belongs_to :imageable, polymorphic: true
end

class SqlUser
  include MotionModel::Model
  include MotionModel::FMDBModelAdapter
  columns :name, :string
  has_many :sql_images, as: :imageable
end

class SqlProduct
  include MotionModel::Model
  include MotionModel::FMDBModelAdapter
  columns :name, :string
  has_many :sql_images, as: :imageable
end

describe "Polymorphism" do

  before do
    MotionModel::Store.config(MotionModel::FMDBAdapter.new('spec.db', reset: true, ns_log: false))
    SqlImage.create_table
    SqlUser.create_table
    SqlProduct.create_table
    @user = SqlUser.create(:name => "Bob")
    @user.sql_images.create(:filename => "bob.png")
    @product = SqlProduct.create(:name => "MacBook")
    @product.sql_images.create(:filename => "macbook.png")
  end

  describe "has_many" do
    it "should return the correct polymorphic instance" do
      @user.sql_images.first.should.be.is_a(SqlImage)
      @user.sql_images.first.filename.should == "bob.png"
      @product.sql_images.first.should.be.is_a(SqlImage)
      @product.sql_images.first.filename.should == "macbook.png"
    end
  end

  describe "belongs_to" do
    it "should return the correct instance" do
      SqlImage.where(:filename => "bob.png").first.imageable.should == @user
      SqlImage.where(:filename => "macbook.png").first.imageable.should == @product
    end
  end

end