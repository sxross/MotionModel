module MotionModel
  class SQLite3Adapter < SQLDBAdapter

    def initialize(name = 'fmdb.db')
      @name = name
      MotionModel::Store.config(self)
    end

    def to_db_type(column_type, value)
      case column_type
      when :datetime
        value.nil? ? nil : value.timeIntervalSince1970
      else
        value
      end
    end

    def from_db_type(column_type, db_value)
      case column_type
      when :datetime
        db_value.nil? ? nil : NSDate.dateWithTimeIntervalSince1970(db_value)
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
      when :integer;  'integer'
      when :boolean;  'integer'
      when :float;    'real'
      when :string;   'text collate nocase'
      when :date;     'integer'
      when :datetime; 'integer'
      else;           'text collate nocase'
      end
    end

  end

end
