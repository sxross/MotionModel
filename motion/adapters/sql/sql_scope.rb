module MotionModel
  class SQLScope

    attr_reader :model_class

    # For debug
    attr_reader :conditions

    def initialize(model_class, db_adapter, type = :select)
      @model_class = model_class
      @db_adapter = db_adapter
      @type = type
      @loaded = false
      @conditions = []
      @selects = []
      @joins = nil
      @orders = nil
      @group = nil
      @limit = nil
    end

    def method_missing(id, *args)
      if @model_class.respond_to?(id)
        # Handle Model-class-define scopes
        return @model_class.send(id, self.deep_clone, *args)
      end
      super
    end

    def deep_clone
      _default_selects = @default_selects
      _selects = @selects.try(:dup)
      _joins = @joins.try(:dup)
      _orders = @orders.try(:dup)
      _group = @group.try(:dup)
      _limit = @limit
      _conditions = @conditions.try(:dup)
      _type = @type
      self.class.new(@model_class, @db_adapter).instance_eval do
        @default_selects = _default_selects
        @selects = _selects
        @joins = _joins
        @orders = _orders
        @group = _group
        @limit = _limit
        @conditions = _conditions
        @type = _type
        self
      end
    end

    def loaded?
      !!@loaded
    end

    def table_name
      @model_class.table_name
    end

    def select(*args)
      return self if null_scope?
      deep_clone.instance_eval do
        options = args.last.is_a?(Hash) ? args.pop : {}
        table_name = options[:table_name] || self.table_name
        if options[:add]
          select = options[:add]
        else
          select = args.first
          @default_selects = []
        end

        if select.is_a?(Symbol)
          str = %Q["#{table_name}"."#{select.to_s}"]
          @selects.push(str)
        elsif select.is_a?(String)
          # Strings won't be quoted, so use symbol to refer to columns
          @selects.push(select)
        else
          foreign_table = table_name != self.table_name
          @selects.push(select.map { |c|
            str = %Q["#{table_name}"."#{c.to_s}"]
            str << %Q[ AS "#{table_name}"."#{c.to_s}"] if foreign_table
            str
          })
        end
        self
      end
    end

    #def self.normalize_where_args(args)
    #end

    def where(*args)
      return self if null_scope?
      deep_clone.instance_eval do
        args.each do |clause|
          if clause.is_a?(String)
            @conditions << clause
          else
            @conditions += SQLCondition.build_from_clause(table_name, clause)
          end
        end
        self
      end
    end

    def self.normalize_join_args(args)
      if args.is_a?(Symbol)
        join_data = [args, {}, nil]
      elsif args.is_a?(Hash)
        data = args.to_a.first
        if data.first.is_a?(Array)
          join_name = data.first.first
          join_options = data.first.last
          nested_join_args = normalize_join_args(data.last)
          nested_join_args[1][:joining_class] = join_name
          join_data = [join_name, join_options, nested_join_args]
        elsif data.last.is_a?(Symbol)
          join_name = data.first
          join_options = {}
          nested_join_args = normalize_join_args(data.last)
          nested_join_args[1][:joining_class] = data.first
          join_data = [join_name, join_options, nested_join_args]
        else
          join_data = [data.first, data.last, nil]
        end
      else
        join_data = [args[0], args[1], args[2]]
      end
      join_data
    end

    def joins(*args)
      return self if null_scope?
      deep_clone.instance_eval do
        args.each do |join_data|
          if join_data.is_a?(String)
            _joins << join_data
          else
            join_name, join_options, nested_join_args = self.class.normalize_join_args(join_data)
            if join_options[:joining_class]
              joining_class = Kernel::const_get(join_options[:joining_class].to_s.classify)
            else
              joining_class = @model_class
            end
            join_column = joining_class.column(join_name)
            _joins << Join.new(join_column, joining_class, join_options)

            joins(nested_join_args) if nested_join_args
          end
        end
        self
      end
    end

    def order(options)
      return self if null_scope?
      deep_clone.instance_eval do
        @orders ||= []
        unless options.is_a?(Hash)
          options = Hash[Array(options).map { |c| [c, :asc] }]
        end
        options.each do |spec, direction|
          if spec.is_a?(String)
            @orders << spec
          else
            @orders << %Q["#{table_name}"."#{spec.to_s}" #{direction == :desc ? 'DESC' : 'ASC'}]
          end
        end
        self
      end
    end

    def group(column)
      return self if null_scope?
      deep_clone.instance_eval do
        @group = %Q["#{table_name}"."#{column.to_s}"]
        self
      end
    end

    def limit(limit)
      return self if null_scope?
      deep_clone.instance_eval do
        @limit = limit
        self
      end
    end

    def all
      deep_clone
    end

    def to_a
      reload unless loaded?
      @collection
    end

    def reload
      @collection = do_select
      @loaded = true
      @collection
    end

    # Fetch the row attributes
    def fetch_row_attrs
      do_select_attrs
    end

    def do_select
      @model_class.nil? ? [] : @model_class.do_select(self)
    end

    def first
      limit(1).all.to_a.first
    end

    def last
      id = select(%Q[MAX("#{table_name}"."id") AS id]).to_a.first.id
      where(id: id).to_a.first
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

    # For debug and copy/paste, use single quotes
    def to_sql_sq
      to_sql.gsub(/"/, "'")
    end

    def each(*args, &block)
      to_a.each(*args, &block)
    end

    def map(*args, &block)
      to_a.map(*args, &block)
    end

    # Scope that will never return anything
    def null_scope?
      type.nil?
    end

    def execute
      if null_scope?
        []
      else
        @db_adapter.build_sql_context(type, to_sql).execute
      end
    end

    def select_str
      _selects.join(', ')
    end

    def joins_str
      return nil if _joins.empty?
      _joins.map{ |j| j.is_a?(String) ? j : j.to_sql_str }.join(' ')
    end

    def order_str
      @orders ? "ORDER BY #{@orders.join(', ')}" : nil
    end

    def group_str
      @group ? "GROUP BY #{@group}" : nil
    end

    def limit_str
      @limit ? %Q[LIMIT #{@limit}] : nil
    end

    def options_str
      arr = [SQLCondition.to_sql_str(@conditions), group_str, order_str, limit_str].compact
      arr.empty? ? nil : arr.join(' ')
    end

    private

    def _default_selects
      @default_selects ||= [%Q["#{table_name}".*]]
    end

    def _selects
      (_default_selects + @selects).compact
    end

    def _joins
      @joins ||= []
    end

    def type
      @type
    end

  end

end
