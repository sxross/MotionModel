module MotionModel
  class Model
    def cast_to_bool(arg)
      case arg
        when NilClass then false
        when TrueClass, FalseClass then arg
        when Integer then arg != 0
        when String then (arg =~ /^true/i) != nil
        else raise ArgumentError.new("type #{column_name} : #{column_type(column_name)} is not possible to cast.")
      end
    end

    def cast_to_integer(arg)
      arg.is_a?(Integer) ? arg : arg.to_i
    end

    def cast_to_float(arg)
      arg.is_a?(Float) ? arg : arg.to_f
    end

    def cast_to_date(arg)
      case arg
        when String
          return arg.to_date
          # return NSDate.dateWithNaturalLanguageString(arg.gsub('-','/'), locale:NSUserDefaults.standardUserDefaults.dictionaryRepresentation)
        when Time
          return arg
          # return NSDate.dateWithNaturalLanguageString(arg.strftime('%Y/%m/%d %H:%M:%S'), locale:NSUserDefaults.standardUserDefaults.dictionaryRepresentation)
        else
          return arg
      end
    end

    def cast_to_array(arg)
      Array(arg)
    end

    def cast_to_hash(arg)
      arg.is_a?(String) ? BW::JSON.parse(String(arg)) : arg
    end

    def cast_to_string(arg)
      String(arg)
    end

    def cast_to_type(column_name, arg) #nodoc
      return nil if arg.nil? && ![ :boolean, :bool ].include?(column_type(column_name))

      return case column_type(column_name)
      when :string, :belongs_to_type then cast_to_string(arg)
      when :boolean, :bool then cast_to_bool(arg)
      when :int, :integer, :belongs_to_id then cast_to_integer(arg)
      when :float, :double then cast_to_float(arg)
      when :date, :time, :datetime then cast_to_date(arg)
      when :text then cast_to_string(arg)
      when :array then cast_to_array(arg)
      when :hash then cast_to_hash(arg)
      else
        raise ArgumentError.new("type #{column_name} : #{column_type(column_name)} is not possible to cast.")
      end
    end
  end
end
