module MotionModel
  module Model
    module Transactions
      def transaction(&block)
        if block_given?
          @savepoints = [] if @savepoints.nil?
          @savepoints.push self.duplicate
          yield
          @savepoints.pop
        else
          raise ArgumentError.new("transaction must have a block")
        end
      end

      def rollback
        unless @savepoints.empty?
          restore_attributes
        else
          NSLog "No savepoint, so rollback not performed."
        end
      end

      def columns_without_relations
        columns.select{|col| ![:has_many, :belongs_to].include?(column_type(col))}
      end

      def restore_attributes
        savepoint = @savepoints.last
        if savepoint.nil?
          NSLog "No savepoint, so rollback not performed."
        else
          columns_without_relations.each do |col|
            self.send("#{col}=", savepoint.send(col))
          end
        end
      end

      def duplicate
        Marshal.load(Marshal.dump(self))
      end
    end
  end
end
