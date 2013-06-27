describe "cloning configuration data for KVO" do
  class KVOObservable
    include MotionModel::Model
    include MotionModel::ArrayModelAdapter

    columns :name, :nickname
  end

  class KVOWatcher
    attr_reader :o

    include BW::KVO

    def initialize(o)
      @o = o
      observe(o, :name) do |old_value, new_value|
      end
    end
  end

  before do
    @observable = KVOObservable.create!(name: 'Jim', nickname: 'Jimmy')
    @watcher = KVOWatcher.new(@observable)
  end

  it "is a KVO anonymous class" do
    @watcher.o.class.to_s.should.match(/^NSKVO/)
    @watcher.o.class.should.not == KVOObservable
  end

  it "retrieves attribute values correctly" do
    @watcher.o.name.should == @observable.name
    @watcher.o.nickname.should == @observable.nickname
  end
end
