module MotionModel
  module SQLModelAdapter
    def adapter
      self
    end

    def self.included(base)
      base.send(:include, BaseModelAdapter)
      base.extend(PrivateClassMethods)
      base.extend(PublicClassMethods)
      base.send(:include, InstanceMethods)
    end

    module PublicClassMethods

      def default_scope
        if @default_scope
          @default_scope.dup
        else
          unscoped
        end
      end

      def table_name=(table_name)
        @table_name = table_name
      end

      def table_name
        @table_name ||= name.demodulize.pluralize.underscore
      end

      def table_exists?
        _db_adapter.table_exists?(table_name)
      end

      def create_table
        _db_adapter.create_table(table_name, _column_hashes)
      end

      def unscoped
        SQLScope.new(self, _db_adapter)
      end

      def scoped
        default_scope
      end

      def all
        default_scope.all
      end

      def first
        default_scope.first
      end

      def last
        default_scope.last
      end

      def order(*args)
        default_scope.order(*args)
      end

      def limit(limit)
        default_scope.limit(limit)
      end

      def count
        default_scope.count
      end
      alias_method :length, :count

      def empty?
        count == 0
      end

      def where(*args)
        default_scope.where(*args)
      end

      def find(*args)
        if args.count == 1 && args.first.is_a?(Numeric)
          find_by_id(args.first)
        else
          where(*args)
        end
      end

      def find_by_id(id)
        where(id: id).first
      end

      def do_select(scope)
        result = scope.execute
        return nil unless result
        rows_attrs = result.map do |row|
          Hash[row.map { |k, v|
            col = _column_hashes[k.to_sym]
            val = col ? _db_adapter.from_db_type(col.type, v) : v
            [k.to_sym, val]
          }]
        end
        rows_attrs.map { |attrs| read(attrs) }
      end

      def delete_all_sql
        _db_adapter.to_delete_sql(default_scope)
      end

      def delete_all
        _db_adapter.build_sql_context(:delete, delete_all_sql).execute
      end

      def foreign_association(associated_class)
        "#{associated_class.name.to_s.underscore}".to_sym
      end

      def foreign_key(associated_class)
        "#{associated_class.name.to_s.underscore}_id".to_sym
      end

      def transaction(&block)
        _db_adapter.transaction(&block)
      end
    end

    module PrivateClassMethods
      private

      def _db_column_config
        config = {}
        _column_hashes.each do |name, column|
          next if virtual_polymorphic_relation_column?(name)
          data = {type: column.type}
          config[name] = data
        end
        config
      end

      def define_belongs_to_methods(name) #nodoc
        super
        define_method("loaded_#{name}") {
          @data[name]
        }
      end

      def define_has_many_methods(name) #nodoc
        super
        define_method("loaded_#{name}") {
          send("#{name}_relation").loaded
        }
      end

      def define_has_one_methods(name) #nodoc
        super
        define_method("loaded_#{name}") {
          send("#{name}_relation").loaded
        }
      end

    end

    module InstanceMethods
      def insert_sql
        attrs = _db_typed_attributes
        attrs.delete(:id) if attrs[:id].nil?
        _db_adapter.to_insert_sql(self.class.default_scope, attrs)
      end

      def do_insert(options = {})
        save_loaded_belongs_to_relations(options)
        result = _db_adapter.build_sql_context(:insert, insert_sql).execute
        if result
          self.id = _db_adapter.last_insert_row_id
          save_loaded_has_many_has_one_relations(options)
          true
        else
          false
        end
      end

      def do_update(options = {})
        save_loaded_belongs_to_relations(options)
        result = _db_adapter.build_sql_context(:update, update_sql).execute
        if result
          save_loaded_has_many_has_one_relations(options)
          true
        else
          false
        end
      end

      def save(options = {})
        _db_transaction { save_without_transaction(options) }
      end

      def save_without_transaction(options = {})
        options = options.dup
        options[:omit_object_ids] ||= {}
        options[:omit_object_ids][object_id] = true
        super
      end

      # Save any dirty already-loaded :belongs_to associates.
      # No need to load since they then would not be dirty.
      def save_loaded_belongs_to_relations(options)
        self.class.belongs_to_columns.each do |name, col|
          associate = send("loaded_#{name}")
          next if associate.nil? || !associate.dirty?
          associate.save_without_transaction(options) unless options[:omit_object_ids][associate.object_id]
          if col.options[:polymorphic]
            self.attributes = {"#{name}_type" => associate.class.name, "#{name}_id" => associate.id}
          else
            foreign_key = self.class.foreign_key(associate.class)
            self.attributes = {foreign_key => associate.id} unless self.send(foreign_key)
          end
        end
      end

      # Save any dirty already-loaded :has_many/:has_one associates.
      # No need to load since they then would not be dirty.
      def save_loaded_has_many_has_one_relations(options)
        cols = self.class.has_many_columns.merge(self.class.has_one_columns)
        cols.each do |name, col|
          associates = Array(self.send("loaded_#{name}"))
          associates.each do |associate|
            next if col.options[:through]

            if col.options[:polymorphic]
              foreign_key = "#{col.options[:as]}_id"
              foreign_type = "#{col.options[:as]}_type"
              associate.attributes = {foreign_type => self.class.name} unless associate.send(foreign_type)
            else
              foreign_key = associate.class.foreign_key(self.class)
            end
            associate.attributes = {foreign_key => id} unless associate.send(foreign_key)
            next unless associate.dirty?
            associate.save_without_transaction(options) unless options[:omit_object_ids][associate.object_id]
          end unless associates.nil?
        end
      end

      def update_sql
        attrs = _db_typed_attributes
        attrs.delete(:id)
        _db_adapter.to_update_sql(id, self.class.where(id: id), attrs)
      end

      def delete_sql
        _db_adapter.to_delete_sql(self.class.where(id: id))
      end

      def do_delete
        _db_adapter.build_sql_context(:delete, delete_sql).execute
      end

      def destroy(options = {})
        _db_transaction do
          super
        end
      end

      # Rebuild relation, in the event it's cached.
      # TODO check other relations that are :through this one, and rebuild them as well
      def rebuild_relation_for(col, instance_or_collection) # nodoc
        # Called from :belongs_to side, which won't know if this is :has_one or :has_many
        instance_or_collection = Array(instance_or_collection) if col.type == :has_many && !instance_or_collection.nil?
        relation_for(col, instance_or_collection, reset: true)

        # Rebuild any relations that are :through this one
        _column_hashes.each do |_name, _column|
          if _column.options[:through] == col.name
            rebuild_relation_for(_name, instance_or_collection.map { |i| i.send(_name) })
          elsif _column.options[:through] == col.name.to_s.pluralize.to_sym
            rebuild_relation_for(_name, instance_or_collection.map { |i| i.send(_name.to_s.singularize.to_sym) })
          end
        end
      end

      private

      def before_initialize(options)
      end

      # Attributes converted to a hash of db-compatible types
      def _db_typed_attributes
        attrs = {}
        _db_column_config.each { |k, v| attrs[k] = _db_adapter.to_db_type(_column_hashes[k].type, send(k)) }
        attrs
      end

      def _db_column_config
        self.class.send(:_db_column_config)
      end

      #def relation_columns
      #  @relation_columns ||= {}
      #end

      def relations
        @relations ||= {}
      end

      # Return the relation, which may be cached.
      # Call rebuild_relation_for if the association is being assigned
      def relation_for(col, instance_or_collection = nil, options = {}) # nodoc
        relations[col.name] = nil if options[:reset]
        relations[col.name] ||= begin
          case col.type
          when :belongs_to
            instance = instance_or_collection
            if col.options[:polymorphic]
              associated_class = instance.class
              foreign_id = instance.id
            else
              associated_class = col.classify
              #foreign_id = send(self.class.foreign_key(associated_class))
              foreign_id = "#{col.name}_id"
              #relation_columns[col.name] = col
            end
            scope = -> { foreign_id.nil? ? associated_class.limit(0) : associated_class.where(id: foreign_id) }
            InstanceRelation.new(self, col, associated_class, scope, instance)
          when :has_many, :has_one
            associated_class = col.classify
            #relation_columns[col.name] = col
            _scope = associated_class
            _scope = _scope.where(col.options[:conditions]) if col.options[:conditions]
            if col.options[:polymorphic]
              scope = -> { id.nil? ? _scope.limit(0) : _scope.
                  where("#{col.options[:as]}_type" => self.class.name, "#{col.options[:as]}_id" => id) }
            elsif col.options[:through]
              scope = -> { id.nil? ? _scope.limit(0) : _scope.scoped.
                  joins(col.options[:through] => self.class.name.underscore.to_sym).
                  where({col.options[:through] => col.through_class.foreign_key(self.class)} => id)}
            else
              foreign_key = associated_class.foreign_key(self.class)
              scope = -> { id.nil? ? _scope.limit(0) : _scope.where(foreign_key => id) }
            end
            if col.type == :has_one
              InstanceRelation.new(self, col, associated_class, scope, instance_or_collection)
            else
              CollectionRelation.new(self, col, associated_class, scope, instance_or_collection)
            end
          else
            nil
          end
        end
      end

      def _db_transaction(&block)
        self.class.send(:transaction, &block)
      end

    end
  end
end
