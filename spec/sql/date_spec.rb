Object.send(:remove_const, :Creatable) if defined?(Creatable)
Object.send(:remove_const, :Updateable) if defined?(Updateable)
describe "time conversions" do

  describe "auto_date_fields" do

    class Creatable
      include MotionModel::Model
      include MotionModel::FMDBModelAdapter
      columns :name => :string,
              :created_at => :date
    end

    class Updateable
      include MotionModel::Model
      include MotionModel::FMDBModelAdapter
      columns :name => :string,
              :updated_at => :date
    end

    before do
      MotionModel::Store.config(MotionModel::FMDBAdapter.new('spec.db', reset: true, ns_log: false))
      Creatable.create_table
      Updateable.create_table
    end

    it "Sets created_at when an item is created" do
      c = Creatable.new(:name => 'test')
      lambda{c.save}.should.change{c.created_at}
    end

    it "Sets updated_at when an item is created" do
      c = Updateable.new(:name => 'test')
      lambda{c.save}.should.change{c.updated_at}
    end

    it "Doesn't update created_at when an item is updated" do
      c = Creatable.create(:name => 'test')
      c.name = 'test 1'
      lambda{c.save}.should.not.change{c.created_at}
    end

    it "Updates updated_at when an item is updated" do
      c = Updateable.create(:name => 'test')
      sleep 1
      c.name = 'test 1'
      lambda{ c.save }.should.change{c.updated_at}
    end

  end


end