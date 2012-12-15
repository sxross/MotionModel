module MotionModel
  module Model
    class Column
      attr_accessor :name
      attr_accessor :type
      attr_accessor :default
      attr_accessor :destroy

      def initialize(name = nil, type = nil, options = {})
        @name = name
        @type = type
        @default = options[:default]
        @destroy = options[:dependent]
      end

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
