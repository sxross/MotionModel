module MotionModel
  module SQLite3ModelAdapter
    def self.included(base)
      base.send(:include, SQLModelAdapter)
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
