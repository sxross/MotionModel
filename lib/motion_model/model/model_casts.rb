module MotionModel
  class Model
    def cast_to_bool(arg)
      case arg
        when NilClass then false
        when TrueClass, FalseClass then arg
        when Integer then arg != 0
        when String then (arg =~ /^true/i) != nil
        else raise ArgumentError.new("type #{column_name} : #{type(column_name)} is not possible to cast.")
      end
    end

    def cast_to_integer(arg)
      arg.is_a?(Integer) ? arg : arg.to_i
    end

    def cast_to_float(arg)
      arg.is_a?(Float) ? arg : arg.to_f
    end

    def cast_to_date(arg)
      arg.is_a?(NSDate) ? arg : NSDate.dateWithNaturalLanguageString(arg, locale:NSUserDefaults.standardUserDefaults.dictionaryRepresentation)
    end

    def cast_to_array(arg)
      arg.is_a?(Array) ? arg : arg.to_a
    end

    def cast_to_type(column_name, arg) #nodoc
      return nil if arg.nil? && ![ :boolean, :bool ].include?(type(column_name))

      return case type(column_name)
      when :string then arg.to_s
      when :boolean, :bool then cast_to_bool(arg)
      when :int, :integer, :belongs_to_id then cast_to_integer(arg)
      when :float, :double then cast_to_float(arg)
      when :date then cast_to_date(arg)
      when :array then cast_to_array(arg)
      else
        raise ArgumentError.new("type #{column_name} : #{type(column_name)} is not possible to cast.")
      end
    end
  end
end
