module MotionModel

  class SQLCondition
    def initialize(table_name, column, value, operator = :'=')
      @table_name = table_name
      @column = column
      @value = value
      @operator = operator
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
      value = begin
        if @value.is_a?(Numeric)
          @value
        elsif @value.is_a?(Array)
          @value.map { |v| v.is_a?(Numeric) ? v : %Q["#{v}"] }.join(', ')
        else
          %Q["#{@value}"]
        end
      end

      case @operator
      when :'='
        if @value.nil?
          %Q[#{column} IS NULL]
        elsif @value.is_a?(Array)
          %Q[#{column} IN (#{value})]
        else
          %Q[#{column} = #{value}]
        end
      when :'!='
        if @value.nil?
          %Q[#{column} IS NOT NULL]
        elsif @value.is_a?(Array)
          %Q[#{column} NOT IN (#{value})]
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
      end
    end
  end

end
