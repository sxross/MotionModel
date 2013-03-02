module MotionModel

  class FMDBAdapter < SQLite3Adapter

    class Transaction

      def initialize(db)
        @db = db
        @pending = false
        @rolling_back = false
        @depth = 0
      end

      def begin_transaction
        @pending = true
        @db.beginTransaction
      end

      def commit
        return unless @pending
        @db.commit
        @pending = false
      end

      def rollback
        return unless @pending
        @db.rollback
        @pending = false
        @rolling_back = true
      end

      def execute(&block)
        return if @rolling_back
        if @pending
          result = block.call(@db)
        else
          begin_transaction
          begin
            result = block.call(@db)
            commit
          rescue => exc
            rollback
          end
        end
        result
      end
    end

    def initialize(name = nil, options = {})
      @name = name || 'fmdb.db'
      if options[:reset]
        NSFileManager.defaultManager.removeItemAtPath(db_path, error:nil)
      end
      MotionModel::Store.config(self)
    end

    def db_path
      File.join(NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true)[0], @name)
    end

    def queue
      if @queue.nil?
        @queue = FMDatabaseQueue.databaseQueueWithPath(db_path)
      end
      @queue
    end

    def execute_sql(sql)
      result = nil
      if @transaction
        @transaction.execute do |db|
          result = self.class._execute(db, sql)
        end
      else
        queue.inDatabase( -> (db) {
          result = self.class._execute(db, sql)
        } )
      end
      result
    end

    def self._execute(db, sql)
      result = nil
      case sql.type
      when :select
        rset = db.executeQuery(sql.sql)
        if rset
          result = []
          while rset.next do
            result << rset.resultDictionary
          end
        end
      else
        result = db.executeUpdate(sql.sql)
      end
      result
    end

    # TODO IMPORTANT need to test transactions and rollbacks
    def transaction(&block)
      if @transaction
        @transaction.execute(&block)
      else
        queue.inDatabase( -> (db) {
          @transaction ||= Transaction.new(db)
          @transaction.execute(&block)
          @transaction = nil
        })
      end
    end

  end

end
