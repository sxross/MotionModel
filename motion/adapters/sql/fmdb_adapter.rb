module MotionModel
  class FMDBAdapter < SQLite3Adapter

    class Transaction

      def initialize(db)
        @db = db
        @rolling_back = false
        @depth = 0
        @any_writes = false
      end

      def initiate(&block)
        begin
          begin_transaction
          result = block.call
          if !@rolling_back
            if @any_writes
              commit_writes
            else
              commit
            end
          end
        end
        result
      rescue => exc
        rollback
        raise
      end

      def execute(&block)
        return if @rolling_back
        block.call
      rescue => exc
        rollback
        raise
      end

      def execute_sql(sql)
        result = nil
        case sql.type
        when :select
          rset = @db.executeQuery(sql.sql)
          if rset
            result = []
            while rset.next do
              result << rset.resultDictionary
            end
          end
        else
          @any_writes = true
          result = @db.executeUpdate(sql.sql)
        end
        result
      rescue => exc
        rollback
        raise
      end

      private

      def begin_transaction
        @pending = true
        @any_writes = false
        @db.beginTransaction
      end

      def end_transaction
        @pending = false
      end

      def commit
        @db.commit
      end

      # Using a different method when there have been writes for debug purposes only
      def commit_writes
        commit
      end

      def rollback
        return unless @pending
        @db.rollback unless @rolling_back
        @rolling_back = true
      end

    end

    def initialize(name = nil, options = {})
      @name = name || 'fmdb.db'
      super(options)
      if options[:reset]
        NSFileManager.defaultManager.removeItemAtPath(db_path, error:nil)
      end
      MotionModel::Store.config(self)
      queue_name = "#{NSBundle.mainBundle.bundleIdentifier}.#{self.class.name.underscore}"
      @queue = Dispatch::Queue.new(queue_name) # Non-concurrent queue
      #@queue = Dispatch::Queue.concurrent(queue_name)
    end

    def execute_sql(sql)
      transaction do
        thread_dictionary['fmdb_pending_transaction'].execute_sql(sql)
      end
    end

    def transaction(&block)
      if thread_dictionary['fmdb_pending_transaction']
        result = thread_dictionary['fmdb_pending_transaction'].execute {
          block.call }
      else
        @result_semaphore ||= Dispatch::Semaphore.new(0)
        @queue.sync do
        #@queue.async do
        #begin
        #::Dispatch::Queue.main.async do
          _transaction = thread_dictionary['fmdb_pending_transaction'] = Transaction.new(db)
          _transaction.initiate do
            result = block.call
            @result = result
            @result_semaphore.signal
          end
          thread_dictionary['fmdb_pending_transaction'] = nil
        end

        @result_semaphore.wait
        result = @result
        @result_semaphore.signal
      end
      result
    end

    private

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

    def thread_dictionary
      NSThread.currentThread.threadDictionary
    end

  end

end
