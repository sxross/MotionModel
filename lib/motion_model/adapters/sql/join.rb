module MotionModel
  class Join
    def initialize(column, joining_class, sym, options = nil)
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
      if @column.options[:polymorphic]
        "#{@column.options[:as]}_id"
      else
        @column.type == :belongs_to ? 'id' : "#{@joining_class.name.underscore}_id"
      end
    end

    def joining_table_key
      @column.type == :has_many ? 'id' : "#{joined_class.name.underscore}_id"
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
      str = %Q["#{joined_table_name}"."#{joined_table_key}" = "#{joining_table_name}"."#{joining_table_key}"]
      if @column.options[:polymorphic]
        str << %Q[ AND "#{joined_table_name}"."#{@column.options[:as]}_type" = "#{@joining_class.name}"]
      end
      str
    end

    def to_sql_str
      %Q[#{type} "#{joined_table_name}" ON #{on_str}]
    end

    def select(scope)
      scope.dup.select(joined_class.columns, table_name: joined_class.table_name)
    end

  end
end
