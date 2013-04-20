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
      @db_adapter.log(sql, result)
    end

    def execute
      result = @db_adapter.execute_sql(self)
      log(@sql, result)
      result
    end
  end

  class SQLDBAdapter < BaseDBAdapter

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
      create_table_sql(name, columns, options).execute
    end

    def create_table_sql(table_name, column_config, options = {})
      column_sql = []

      if column_config[:id]
        _column_config = column_config.dup
        column_config = {
            id: _column_config.delete(:id).merge({not_null: true, primary_key: true, auto_increment: true})
        }.merge(_column_config)
      end

      # Map MotionModel column types to SQLite3
      column_config.each do |col_name, option_specs|
        type_str = _db_column_type(option_specs[:type])

        # Default options
        option_specs[:not_null] ||= false

        options = []
        option_specs.each do |key, value|
          str = begin
            case(key)
            when :not_null;       value ? 'NOT NULL' : nil
            when :primary_key;    value ? 'PRIMARY KEY' : nil
            when :auto_increment; value ? 'AUTOINCREMENT' : nil
            end
          end
          options << str if str
        end

        column_sql << %Q["#{col_name}" #{type_str} #{options.compact.join(' ')}]
      end

      existence = "IF NOT EXISTS"

      build_sql_context(:create_table,
          %Q[CREATE TABLE #{existence} "main"."#{table_name}" ( #{column_sql.join(', ')} );])
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
