module MotionModel
  module SQLite3ModelAdapter
    def self.included(base)
      base.send(:include, SQLModelAdapter)
      base.extend(PrivateClassMethods)
      base.extend(PublicClassMethods)
    end

    module PublicClassMethods
    end

    module PrivateClassMethods
      private

      def _db_column_config
        config = {}
        _column_hashes.each do |name, column|
          next if virtual_relation_column?(name)
          data = {type: column.type}
          config[name] = data
        end
        config
      end

    end

    private

    def _db_column_config
      self.class.send(:_db_column_config)
    end

  end
end
