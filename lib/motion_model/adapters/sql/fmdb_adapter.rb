module MotionModel

  class FMDBAdapter < SQLite3Adapter

    def initialize(name = 'fmdb.db', options = {})
      @name = name
      if options[:reset_db]
        NSFileManager.defaultManager.removeItemAtPath(db_path, error:nil)
      end
      MotionModel::Store.config(self)
    end

    def db_path
      File.join(NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true)[0], @name)
    end

    def db
      @db ||= begin
        db = FMDatabase.databaseWithPath(db_path)
        db.open
        db
      end
    end

    def execute_sql(sql)
      case sql.type
      when :select
        rset = db.executeQuery(sql.sql)
        if rset
          collection = []
          while rset.next do
            collection << rset.resultDictionary
          end if rset
          collection
        else
          nil
        end
      else
        db.executeUpdate(sql.sql)
      end
    end

  end

end
