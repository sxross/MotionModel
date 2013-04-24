module MotionModel
  class Join
    def initialize(column, joining_class, options = nil)
      @column = column
      @joining_class = joining_class
      @options = options || {}
    end

    def joined_table_name
      joined_class.table_name
    end

    def joining_table_name
      @joining_class.table_name
    end

    def joined_table_key
      @column.type == :belongs_to ? @column.primary_key : @column.inverse_column.foreign_key
    end

    def joined_table_type
      @column.foreign_polymorphic_type
    end

    def joining_table_key
      @column.type == :belongs_to ? @column.inverse_column.foreign_key : @column.inverse_column.primary_key
    end

    def joined_class
      @column.classify
    end

    def type
      @options[:outer] ? 'LEFT OUTER JOIN' : 'INNER JOIN'
    end

    def on_str
      @options[:on] || build_on_str
    end

    def build_on_str
      conditions = []
      conditions << %Q["#{joined_table_name}"."#{joined_table_key}" = "#{joining_table_name}"."#{joining_table_key}"]
      if @column.polymorphic
        conditions << %Q["#{joined_table_name}"."#{joined_table_type}" = "#{@joining_class.name}"]
      end
      if @options[:conditions]
        conditions += SQLCondition.build_from_clause(joined_table_name, @options[:conditions]).map(&:to_sql_str)
      end
      conditions.join(' AND ')
    end

    def to_sql_str
      %Q[#{type} "#{joined_table_name}" ON (#{on_str})]
    end

    def select(scope)
      scope.dup.select(joined_class.columns, table_name: joined_class.table_name)
    end

  end
end
