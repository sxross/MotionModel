module MotionModel

  class SQLCondition
    def initialize(table_name, column, value, operator = nil)
      @table_name = table_name
      @column = column
      @value = value
      @operator = operator || :'='
    end

    def self.to_sql_str(conditions)
      return nil if conditions.empty?
      str = conditions.map { |condition|
        condition.is_a?(String) ? condition : condition.to_sql_str
      }.compact.map { |s| "(#{s})" }.join(' AND ')
      "WHERE #{str}"
    end

    def to_sql_str
      column = %Q["#{@table_name}"."#{@column.to_s}"]
      if @value.is_a?(Numeric)
        value = @value
      elsif @value.is_a?(Array)
        values = @value.map { |v| v.is_a?(Numeric) ? v : %Q["#{v}"] }
      elsif @value.is_a?(Range)
        values = [@value.min, @value.max]
      else
        value = %Q["#{@value}"]
      end

      case @operator
      when :'=', :eq
        if @value.nil?
          %Q[#{column} IS NULL]
        elsif @value.is_a?(Array)
          %Q[#{column} IN (#{values.join(', ')})]
        else
          %Q[#{column} = #{value}]
        end
      when :'!=', :ne, :not_eq, :not_in
        if @value.nil?
          %Q[#{column} IS NOT NULL]
        elsif @value.is_a?(Array)
          %Q[#{column} NOT IN (#{values.join(', ')})]
        else
          %Q[#{column} <> #{value}]
        end
      when :'>'
        %Q[#{column} > #{value}]
      when :'>='
        %Q[#{column} >= #{value}]
      when :'<'
        %Q[#{column} < #{value}]
      when :'<='
        %Q[#{column} <= #{value}]
      when :between, :in_range
        %Q[#{column} BETWEEN #{values.first} AND #{values.last}]
      end
    end
  end

end
