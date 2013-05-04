module MotionModel
  module FMDBModelAdapter
    def self.included(base)
      base.send(:include, SQLite3ModelAdapter)
      base.extend(PrivateClassMethods)
      base.extend(PublicClassMethods)
    end

    module PublicClassMethods
    end

    module PrivateClassMethods
      private
    end

  end
end
