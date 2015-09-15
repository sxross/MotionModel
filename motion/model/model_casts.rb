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
          return DateParser::parse_date(arg)
          # return NSDate.dateWithNaturalLanguageString(arg.gsub('-','/'), locale:NSUserDefaults.standardUserDefaults.dictionaryRepresentation)
        when Time, NSDate
          return arg
          # return NSDate.dateWithNaturalLanguageString(arg.strftime('%Y/%m/%d %H:%M:%S'), locale:NSUserDefaults.standardUserDefaults.dictionaryRepresentation)
        else
          return arg
      end
    end

    def cast_to_array(arg)
      array=*arg
      array
    end

    def cast_to_hash(arg)
      arg.is_a?(String) ? BW::JSON.parse(String(arg)) : arg
    end

    def cast_to_string(arg)
      String(arg)
    end

    def cast_to_arbitrary_class(arg)
      # This little oddity is because a number of built-in
      # Ruby classes cannot be dup'ed. Not only that, they
      # respond_to?(:dup) but raise an exception when you
      # actually do it. Not only that, the behavior can be
      # different depending on architecture (32- versus 64-bit).
      #
      # This is Ruby, folks, not just RubyMotion.
      #
      # We don't have to worry if it's a MotionModel, because
      # using a reference to the data is ok. The by-reference
      # copy is fine.

      return arg if arg.respond_to?(:motion_model?)

      # But if it is not a MotionModel, we either need to dup
      # it (for most cases), or just assign it (for built-in
      # types like Integer, Fixnum, Float, NilClass, etc.)

      result = nil
      begin
        result = arg.dup
      rescue
        result = arg
      end

      result
    end

    def cast_to_type(column_name, arg) #nodoc
      return nil if arg.nil? && ![ :boolean, :bool ].include?(column_type(column_name))
      p "Column: #{column_name}"
      p "Arg: #{arg}"
      return case column_type(column_name)
      when :string, :belongs_to_type then cast_to_string(arg)
      when :boolean, :bool then cast_to_bool(arg)
      when :int, :integer, :belongs_to_id then cast_to_integer(arg)
      when :float, :double then cast_to_float(arg)
      when :date, :time, :datetime then cast_to_date(arg)
      when :text then cast_to_string(arg)
      when :array then cast_to_array(arg)
      when :hash then cast_to_hash(arg)
      when Class then cast_to_arbitrary_class(arg)
      else
        raise ArgumentError.new("type #{column_name} : #{column_type(column_name)} is not possible to cast.")
      end
    end
  end
end
