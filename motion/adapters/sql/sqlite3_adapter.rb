motion_require 'sql_db_adapter'

module MotionModel
  class SQLite3Adapter < SQLDBAdapter

    def to_db_type(column_type, value)
      case column_type
      when :datetime, :date
        value.nil? ? nil : value.to_i
      when :hash
        value.nil? ? nil : BW::JSON.generate(value)
      else
        value
      end
    end

    def from_db_type(column_type, db_value)
      case column_type
      when :datetime, :date
        db_value.nil? ? nil : Time.at(db_value)
      else
        db_value
      end
    end

    def last_insert_row_id
      # Sharing an SQLIte3 connection across multiple threads can corrupt the returned ID
      build_sql_context(:select, "SELECT last_insert_rowid() AS id").execute.first['id']
    end

    private

    def _db_column_type(column_type)
      case column_type
      when :integer;          'integer'
      when :belongs_to_id;    'integer'
      when :belongs_to_type;  'text collate nocase'
      when :boolean;          'integer'
      when :float;            'real'
      when :string;           'text collate nocase'
      when :date;             'integer'
      when :datetime;         'integer'
      else;                   'text collate nocase'
      end
    end

  end

end
