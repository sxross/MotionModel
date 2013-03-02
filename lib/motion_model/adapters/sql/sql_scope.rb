module MotionModel
  class SQLScope

    def initialize(model_class, db_adapter)
      @model_class = model_class
      @db_adapter = db_adapter
      @conditions = []
    end

    def table_name
      @model_class.table_name
    end

    def select(select, options = {})
      table_name = options[:table_name] || self.table_name
      @_selects = [] unless options[:add]
      dup.instance_eval do
        if select.is_a?(String)
          _selects.push(select)
        else
          foreign_table = table_name != self.table_name
          _selects.push(select.map { |c|
            str = %Q["#{table_name}".#{c.to_s}]
            str << %Q[ AS "#{table_name}.#{c.to_s}"] if foreign_table
            str
          })
        end
        self
      end
    end

    def where(*args)
      dup.instance_eval do
        args.each do |clause|
          if clause.is_a?(String)
            @conditions << clause
          else
            clause.each do |key, options|
              begin # TODO this is else fallthru if it's just a "col: value" expression
                value = options
                @conditions << SQLCondition.new(table_name, key.to_s, value)
              end
            end
          end
        end
        self
      end
    end

    def order(options)
      dup.instance_eval do
        @orders ||= []
        options.each do |column, direction|
          @orders << %Q["#{table_name}"."#{column.to_s}" #{direction == :desc ? 'DESC' : 'ASC'}]
        end
        self
      end
    end

    def limit(limit)
      dup.instance_eval do
        @limit = limit
        self
      end
    end

    def all
      dup
    end

    def to_a
      do_select
    end

    def do_select
      @model_class.do_select(self)
    end

    def first
      limit(1).all.to_a.first
    end

    def count
      select('COUNT(*) AS _sql_count').do_select.first.attributes[:_sql_count]
    end

    def empty?
      count == 0
    end

    def delete
      @model_class.do_delete(self)
    end

    def to_sql
      @db_adapter.send("to_#{type.to_s}_sql", self)
    end

    def each(*args, &block)
      to_a.each(*args, &block)
    end

    def map(*args, &block)
      to_a.map(*args, &block)
    end

    def execute
      @db_adapter.build_sql_context(type, to_sql).execute
    end

    def select_str
      _selects.join(', ')
    end

    def order_str
      @orders ? "ORDER BY #{@orders.join(', ')}" : nil
    end

    def limit_str
      @limit ? %Q[LIMIT #{@limit}] : nil
    end

    def options_str
      [SQLCondition.to_sql_str(@conditions), order_str, limit_str].compact.join(' ')
    end

    private

    def _selects
      @_selects ||= [%Q["#{table_name}".*]]
    end

    def type
      @type || :select
    end

  end

end
