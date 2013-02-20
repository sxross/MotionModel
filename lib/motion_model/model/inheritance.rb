module MotionModel
  module Inheritance

    def self.included(base)
      base.extend(PrivateClassMethods)
      base.extend(PublicClassMethods)

      base.instance_eval do
        # Departing from rails 'type' name, be more explicit
        columns inheritance_type: :string

        def self.inherited(subclass)
          subclass.instance_eval do
            self.table_name = superclass.table_name

            def self.default_scope
              unscoped.where(inheritance_type: self.inheritance_type)
            end

            def _columns
              superclass.send(:_columns)
            end

            def _column_hashes
              superclass.send(:_column_hashes)
            end

            def _issue_notifications
              superclass.send(:_issue_notifications)
            end
          end
        end
      end
    end

    module PublicClassMethods
      def inheritance_type
        name
      end
    end

    module PrivateClassMethods
      private
    end

    def inheritance_type
      self.class.inheritance_type
    end

  end

end
