module MotionModel
  module Model
    class Column
      attr_reader :name
      attr_reader :owner
      attr_reader :type
      attr_reader :options

      OPTION_ATTRS = [:as, :conditions, :default, :dependent, :foreign_key, :inverse_of, :joined_class_name,
          :polymorphic, :symbolize, :through]

      OPTION_ATTRS.each do |key|
        define_method(key) { @options[key] }
      end

      def initialize(owner, name = nil, type = nil, options = {})
        raise RuntimeError.new "columns need a type declared." if type.nil?
        @owner = owner
        @name = name
        @type = type
        @klass = options.delete(:class)
        @options = options
      end

      def class_name
        joined_class_name || name
      end

      def primary_key
        :id
      end

      def foreign_name
        as || name
      end

      def foreign_polymorphic_type
        "#{foreign_name}_type".to_sym
      end

      def foreign_key
        @options[:foreign_key] || "#{foreign_name.to_s.singularize}_id".to_sym
      end

      def classify
        if type == :belongs_to && polymorphic
          nil
        elsif @klass
          @klass
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
        Kernel::const_get(through.to_s.classify)
      end

      def inverse_foreign_key
        inverse_column.foreign_key
      end

      def inverse_name
        if as
          as
        elsif inverse_of
          inverse_of
        elsif type == :belongs_to
          # Check for a singular and a plural relationship
          name = owner.name.singularize.underscore
          col = classify.column(name)
          col ||= classify.column(name.pluralize)
          col.name
        else
          owner.name.singularize.underscore.to_sym
        end
      end

      def inverse_column
        classify.column(inverse_name)
      end

    end
  end
end
