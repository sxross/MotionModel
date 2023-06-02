class Tag
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter

  columns(
    name: :string
  )
  
  belongs_to :tagged, polymorphic: true
end

class Gadget
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter

  columns(
    name: :string
  )
  
  has_many   :tags, dependent: :destroy, class: Tag, inverse_of: :tagged, polymorphic: true
end  

class Widget
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter

  columns(
    name: :string
  )
  
  has_many   :tags, dependent: :destroy, class: Tag, inverse_of: :tagged, polymorphic: true
end  

describe 'polymorphic relationships' do
  describe 'polymorphic belongs to' do
    before do
      Tag.delete_all
      Gadget.delete_all
      Widdget.delete_all
    end

    it 'can relate to different classes' do
      gadget1 = Gadget.create(name: 'Gadget 1')
      gadget2 = Gadget.create(name: 'Gadget 2')
      gadget3 = Gadget.create(name: 'Gadget 3')
      widget1 = Widget.create(name: 'Widget 1')
      widget2 = Widget.create(name: 'Widget 2')
      
      tag1 = Tag.create(name: 'Tag 1', tagged: gadget1)
      tag2 = Tag.create(name: 'Tag 2', tagged: gadget2)
      tag3 = Tag.create(name: 'Tag 3', tagged: gadget2)
      tag4 = Tag.create(name: 'Tag 4', tagged: gadget3)
      tag5 = Tag.create(name: 'Tag 5', tagged: widget1)
      tag6 = Tag.create(name: 'Tag 6', tagged: widget1)
      tag7 = Tag.create(name: 'Tag 7', tagged: widget2)
      
      gadget1.tags.to_a.should == [tag1]
      gadget2.tags.to_a.should == [tag2, tag3]
      gadget3.tags.to_a.should == [tag4]
      widget1.tags.to_a.should == [tag5, tag6]
      widget2.tags.to_a.should == [tag7]
    end
  end

  describe 'polymorphic has many' do
    before do
      Tag.delete_all
      Gadget.delete_all
      Widdget.delete_all
    end

    it 'can relate polymorphuc records' do
      gadget1 = Gadget.create(name: 'Gadget 1')
      gadget2 = Gadget.create(name: 'Gadget 2')
      gadget3 = Gadget.create(name: 'Gadget 3')
      widget1 = Widget.create(name: 'Widget 1')
      widget2 = Widget.create(name: 'Widget 2')

      gadget1.tags << Tag.create(name: 'Tag 1')
      gadget2.tags << Tag.create(name: 'Tag 2')
      gadget2.tags << Tag.create(name: 'Tag 3')
      gadget3.tags << Tag.create(name: 'Tag 4')
      widget1.tags << Tag.create(name: 'Tag 5')
      widget1.tags << Tag.create(name: 'Tag 6')
      widget2.tags << Tag.create(name: 'Tag 7')

      Tag.all.to_a.map(:tagged).should == [
        gadget1,
        gadget2,
        gadget2,
        gadget3,
        widget1,
        widget1,
        widget2,
      ]
    end
  end
end
