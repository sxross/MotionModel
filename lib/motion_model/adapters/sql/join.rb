module MotionModel
  class Join
    def initialize(foreign_class, sym, options = {})
      @foreign_class = foreign_class
      @joined_class = Kernel.const_get(sym.to_s.singularize.classify)
      @options = options
    end

    def joined_table_name
      @joined_class.table_name
    end

    def foreign_table_name
      @foreign_class.table_name
    end

    def primary_key
      'id'
    end

    def type
      @options[:outer] ? 'LEFT OUTER JOIN' : 'LEFT INNER JOIN'
    end

    def foreign_key
      @options[:foreign_key] || "#{@joined_class.name.underscore}_id"
    end

    def on_str
      @options[:on] || %Q["#{joined_table_name}"."#{primary_key}" = "#{foreign_table_name}"."#{foreign_key}"]
    end

    def to_sql_str
      %Q[#{type} "#{joined_table_name}" ON #{on_str}]
    end

    def select(scope)
      scope.dup.select(@joined_class.columns, table_name: @joined_class.table_name)
    end

  end
end
