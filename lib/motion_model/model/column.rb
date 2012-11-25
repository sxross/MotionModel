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
      
      def classify
        case @type
        when :belongs_to
          @klass ||= Object.const_get(@name.to_s.camelize)
        when :has_many
          @klass ||= Object.const_get(@name.to_s.singularize.camelize)
        else
          raise "#{@name} is not a relation. This isn't supposed to happen."
        end
      end
    end
  end
end