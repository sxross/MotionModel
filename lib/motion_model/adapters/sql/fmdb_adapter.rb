module MotionModel

  class FMDBAdapter < SQLite3Adapter

    class Transaction

      def initialize(db)
        @db = db
        @pending = false
        @rolling_back = false
        @depth = 0
      end

      def execute(&block)
        return if @rolling_back
        result = nil
        if @pending
          result = block.call(@db)
        else
          begin_transaction
          begin
            result = block.call(@db)
            commit
          rescue => exc
            rollback
            raise
          end
        end
        result
      end

      def self.execute(&block)
        raise 'No transaction pending' unless pending?
        pending_transaction.execute(&block)
      end

      def self.pending?
        !!pending_transaction
      end

      def self.pending_transaction
        NSThread.currentThread.threadDictionary['fmdb_pending_transaction']
      end

      def self.pending_transaction=(transaction)
        raise 'Transaction already pending' if transaction && self.pending?
        NSThread.currentThread.threadDictionary['fmdb_pending_transaction'] = transaction
      end

      private

      def begin_transaction
        self.class.pending_transaction = self
        @pending = true
        @db.beginTransaction
      end

      def end_transaction
        @pending = false
        self.class.pending_transaction = nil
      end

      def commit
        return unless @pending
        @db.commit
        end_transaction
      end

      def rollback
        return unless @pending
        @db.rollback
        end_transaction
        @rolling_back = true
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

    def db
      unless @db
        @db = FMDatabase.databaseWithPath(db_path)
        @db.crashOnErrors = true
        @db.open
      end
      @db
    end

    def execute_sql(sql)
      block = proc do
        self.class._execute(db, sql)
      end

      result = nil
      begin
        @result = nil
        if Transaction.pending?
          result = Transaction.execute(&block)
        else
          result_semaphore.wait
          begin
            queue.sync { @result = block.call }
            result = @result
            @result = nil
          end
          result_semaphore.signal
        end
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
      begin
        if Transaction.pending?
          Transaction.execute(&block)
        else
          queue.sync do
            Transaction.new(db).execute(&block)
          end
        end
      end
    end

    def queue
      unless @queue
        queue_name = "#{NSBundle.mainBundle.bundleIdentifier}.#{self.class.name.underscore}"
        @queue = ::Dispatch::Queue.new(queue_name)
      end
      @queue
    end

    def result_semaphore
      @result_semaphore ||= Dispatch::Semaphore.new(1)
    end

  end

end
