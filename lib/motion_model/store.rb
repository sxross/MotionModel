module MotionModel
  class Store

    def self.config(db_adapter)
      @store = new(db_adapter)
    end

    def self.singleton
      @store
    end

    attr_reader :db_adapter

    def initialize(db_adapter)
      @db_adapter = db_adapter
    end

  end
end
