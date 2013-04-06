module MotionModel
  module Model
    class Column
      attr_accessor :name
      attr_accessor :type
      attr_accessor :default
      attr_accessor :dependent

      def initialize(name = nil, type = nil, options = {})
        @name = name
        @type = type
        raise RuntimeError.new "columns need a type declared." if type.nil?
        @default = options.delete :default
        @dependent = options.delete :dependent
        @options = options
      end

      def options
        @options
      end

      def class_name
        @options[:joined_class_name] || @name
      end

      def classify
        if @options[:class]
          @options[:class]
        else
          case @type
          when :belongs_to
            @klass ||= Object.const_get(class_name.to_s.camelize)
          when :has_many, :has_one
            @klass ||= Object.const_get(class_name.to_s.singularize.camelize)
          else
            raise "#{@name} is not a relation. This isn't supposed to happen."
          end
        end
      end

      def class_const_get
        Kernel::const_get(classify)
      end

      def through_class
        Kernel::const_get(@options[:through].to_s.classify)
      end
    end
  end
end
