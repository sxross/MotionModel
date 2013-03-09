module MotionModel
  class Join
    def initialize(relation_type, joining_class, sym, options = nil)
      @relation_type = relation_type
      @joining_class = joining_class
      @joined_class = Kernel.const_get(sym.to_s.singularize.classify)
      @options = options || {}
    end

    def joined_table_name
      @joined_class.table_name
    end

    def joining_table_name
      @joining_class.table_name
    end

    def joined_table_key
      @relation_type == :belongs_to ? 'id' : "#{@joining_class.name.underscore}_id"
    end

    def joining_table_key
      @relation_type == :has_many ? 'id' : "#{@joined_class.name.underscore}_id"
    end

    def type
      @options[:outer] ? 'LEFT OUTER JOIN' : 'INNER JOIN'
    end

    def on_str
      @options[:on] || build_on_str
    end

    def build_on_str
      %Q["#{joined_table_name}"."#{joined_table_key}" = "#{joining_table_name}"."#{joining_table_key}"]
    end

    def to_sql_str
      %Q[#{type} "#{joined_table_name}" ON #{on_str}]
    end

    def select(scope)
      scope.dup.select(@joined_class.columns, table_name: @joined_class.table_name)
    end

  end
end
