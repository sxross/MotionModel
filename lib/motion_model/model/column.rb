module MotionModel
  module Model
    class Column
      attr_accessor :name
      attr_accessor :type
      attr_accessor :default

      def initialize(name = nil, type = nil, default = nil)
        @name = name
        @type = type
        @default = default || nil
      end
      
      def add_attr(name, type, default = nil)
        @name = name
        @type = type
        @default = default || nil
      end
      alias_method :add_attribute, :add_attr
    end
  end
end