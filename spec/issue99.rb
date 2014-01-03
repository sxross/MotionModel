describe "issue99 -- namespacing conflict" do
  it "does not raise an error when creating a Collection object" do
    class Collection
      include MotionModel::Model
      include MotionModel::ArrayModelAdapter
      columns name: :string
      has_many :items, dependent: :destroy
    end
    class Item
      include MotionModel::Model
      include MotionModel::ArrayModelAdapter
      columns name: :string
      belongs_to :collection
    end
    
    c = lambda{ 
      c = Collection.create(name:'asdf')
      c.items.create(name:'qwer') }.
        should.not.raise
  end
end