module MotionModel
  module BaseModelAdapter
    def self.included(base)
      base.extend(PrivateClassMethods)
      base.extend(PublicClassMethods)
      base.send(:include, InstanceMethods)
    end

    module PublicClassMethods
    end

    module PrivateClassMethods
      private

      def _db_adapter
        store.db_adapter
      end

      def store
        MotionModel::Store.singleton
      end
    end

    module InstanceMethods
      private

      def _db_adapter
        self.class.send(:_db_adapter)
      end
    end

  end
end
