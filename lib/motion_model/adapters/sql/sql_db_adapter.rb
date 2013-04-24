module MotionModel
  class SQLContext
    attr_reader :sql, :type

    def initialize(db_adapter, type, sql, options = {})
      @db_adapter = db_adapter
      @type = type
      @sql = sql
      @options = options
    end

    def to_s
      "<SQL: #{@sql}>"
    end

    def log(sql, result)
      @db_adapter.log(sql, type, result)
    end

    def execute
      result = @db_adapter.execute_sql(self)
      log(@sql, result)
      result
    end
  end

  class SQLDBAdapter < BaseDBAdapter

    EXISTENCE = "IF NOT EXISTS"

    def to_db_type(column_type, value)
      value
    end

    def from_db_type(column_type, db_value)
      db_value
    end

    def build_sql_context(type, str)
      SQLContext.new(self, type, str)
    end

    def table_exists?(table_name)
      sql = build_sql_context(:select, <<-SQL.strip << ';')
        SELECT 1 FROM sqlite_master WHERE type="table" AND name="#{table_name}"
      SQL
      sql.execute.count > 0
    end

    def create_table(name, columns, options = {})
      sqls = create_table_sql(name, columns, options)
      sqls.each { |s| s.execute }
    end

    def create_table_sql(table_name, column_config, options = {})
      column_sql = []
      create_index_sqls = []

      column_config = column_config.dup
      if column_config[:id]
        column_config[:id].options.merge!({not_null: true, primary_key: true, auto_increment: true})
        create_index_sqls << create_index_sql(table_name, :id, unique: true)
      end

      # Map MotionModel column types to SQLite3
      column_config.each do |col_name, column|
        if [:belongs_to, :has_many, :has_one].include?(column.type)
          if column.type == :belongs_to
            if column.options[:polymorphic]
              _options = {index_name: "#{table_name}_#{col_name}_idx"}
              col_names = %W[#{col_name}_type #{col_name}_id]
              create_index_sqls << create_index_sql(table_name, col_names, _options)
            else
              create_index_sqls << create_index_sql(table_name, "#{col_name}_id")
            end
          end
        else
          type_str = _db_column_type(column.type)

          # Default options
          column.options[:not_null] ||= false

          col_options = []
          column.options.each do |key, value|
            str = begin
              case(key)
              when :not_null;       value ? 'NOT NULL' : nil
              when :primary_key;    value ? 'PRIMARY KEY' : nil
              when :auto_increment; value ? 'AUTOINCREMENT' : nil
              end
            end
            col_options << str if str
          end

          column_sql << %Q["#{col_name}" #{type_str} #{col_options.compact.join(' ')}]

          if column.options[:index]
            create_index_sqls << create_index_sql(table_name, col_name, column.options[:index])
          end
        end
      end

      sql = []
      sql << build_sql_context(:drop_table,
          %Q[DROP TABLE IF EXISTS "main"."#{table_name}";]) if options[:drop]
      sql << build_sql_context(:create_table,
          %Q[CREATE TABLE #{EXISTENCE} "main"."#{table_name}" ( #{column_sql.join(', ')} );])
      sql += create_index_sqls.map{ |s| build_sql_context(:create_indexes, s) }
      sql
    end

    def create_index_sql(table_name, col_names, options = {})
      options = {} unless options.is_a?(Hash)
      col_names = Array(col_names)
      idx_name = options[:index_name] || "#{table_name}_#{col_names.first}_idx"
      unique = options[:unique] ? "UNIQUE" : ''
      _col_names = col_names.map { |s| %Q["#{s}"] }.join(', ')
      <<-SQL.strip << ';'
        CREATE #{unique} INDEX #{EXISTENCE} "#{idx_name}" ON "#{table_name}" (#{_col_names})
      SQL
    end

    def to_select_sql(scope)
      [
          %Q[SELECT #{scope.select_str}],
          %Q[FROM "#{scope.table_name}"],
          scope.joins_str,
          scope.options_str
      ].compact.join(' ') << ';'
    end

    def to_insert_sql(scope, attrs)
      typed_attrs = _quoted_db_typed_attributes(attrs)
      column_names_str = typed_attrs.keys.map { |n| %Q["#{n.to_s}"] }.join(', ')
      values_str = typed_attrs.values.join(', ')

      <<-SQL.strip << ';'
        INSERT INTO "#{scope.table_name}" (#{column_names_str}) VALUES (#{values_str})
      SQL
    end

    def to_update_sql(id, scope, attrs)
      typed_attrs = _quoted_db_typed_attributes(attrs)
      column_values_str = typed_attrs.map { |k, v| %Q["#{k.to_s}" = #{v}] }.join(', ')

      <<-SQL.strip << ';'
        UPDATE "#{scope.table_name}" SET #{column_values_str} WHERE ("#{scope.table_name}"."id" = #{id})
      SQL
    end

    def to_delete_sql(scope)
      <<-SQL.strip << ';'
        DELETE FROM "#{scope.table_name}" #{scope.options_str}
      SQL
    end

    private

    def _quoted_db_typed_attributes(attrs)
      quoted_attrs = {}
      attrs.each do |name, value|
        quoted_attrs[name] = begin
          case value
          when nil;       'NULL'
          when Numeric;   value.to_s
          else;           %Q["#{value.gsub(/"/, '""')}"]
          end
        end
      end
      quoted_attrs
    end

  end
end
