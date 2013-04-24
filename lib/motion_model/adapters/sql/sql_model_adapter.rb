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

      def do_select_attrs(scope)
        result = scope.execute
        if result.nil?
          fail "Empty response from DB"
        end
        result.map do |row|
          Hash[row.map { |k, v|
            col = column(k.to_sym)
            val = col ? _db_adapter.from_db_type(col.type, v) : v
            [k.to_sym, val]
          }]
        end
      end

      def do_select(scope)
        do_select_attrs(scope).map { |attrs| read(attrs) }
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
        define_method("#{name}_relation") { relation(column(name)) }
        define_method("loaded_#{name}")   { get_loaded_attr(name) }
      end

      def define_has_many_methods(name) #nodoc
        super
        define_method("#{name}_relation") { relation(column(name)) }
        define_method("loaded_#{name}")   { get_loaded_attr(name) }
      end

      def define_has_one_methods(name) #nodoc
        super
        define_method("#{name}_relation") { relation(column(name)) }
        define_method("loaded_#{name}")   { get_loaded_attr(name) }
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
      # No need to load since as they would not be dirty.
      def save_loaded_belongs_to_relations(options)
        self.class.belongs_to_columns.each do |name, col|
          associate = get_loaded_attr(name)
          next if associate.nil? || !associate.dirty?
          associate.save_without_transaction(options) unless options[:omit_object_ids][associate.object_id]
          set_belongs_to_attr(col, associate)
        end
      end

      # Save any dirty already-loaded :has_many/:has_one associates.
      # No need to load since they then would not be dirty.
      def save_loaded_has_many_has_one_relations(options)
        cols = self.class.has_many_columns.merge(self.class.has_one_columns)
        cols.each do |name, col|
          associates = Array(get_loaded_attr(name))
          associates.each do |associate|
            next if col.through
            associate.set_belongs_to_attr(col.inverse_name, self)
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

      def rebuild_relation(col, instance_or_collection, options = {}) # nodoc
        _col = column(col)

        # TODO is this necessary any longer?
        # try_plural true when called from the belongs_to side, which won't know if relation is singular or plural
        #_col ||= column(col.to_s.pluralize.to_sym) if col.is_a?(Symbol) && try_plural

        # Called from :belongs_to side, which won't know if this is :has_one or :has_many
        rel = relation(_col)
        case _col.type
        when :belongs_to
          rel.set_instance(instance_or_collection, options.slice(:set_inverse))
        when :has_one
          rel.set_instance(instance_or_collection, options.slice(:set_inverse))
        when :has_many
          rel.push(instance_or_collection, options.slice(:set_inverse))  #.loaded
        end unless instance_or_collection.nil?
      end

      def unload_relation(col)
        _col = column(col)
        rel = relation(_col)
        rel.unload
      end

      def push_relation(col, *instances) # nodoc
        _col = column(col)
        rel = relation(_col)
        rel.push(*instances)
      end

      def get_loaded_attr(col)
        _col = column(col)
        _col.type == :belongs_to? ? get_attr(name) : relation(_col).loaded
      end

      private

      def before_initialize(options)
      end

      # Attributes converted to a hash of db-compatible types
      def _db_typed_attributes
        attrs = {}
        _db_column_config.each { |k, v| attrs[k] = _db_adapter.to_db_type(column(k).type, get_attr(k)) }
        attrs
      end

      def _db_column_config
        self.class.send(:_db_column_config)
      end

      def _relations
        @_relations ||= {}
      end

      def get_belongs_to_attr(col)
        rel = relation(col)
        rel.instance
      end

      def get_has_many_attr(col)
        relation(col).to_a
      end

      def get_has_one_attr(col)
        relation(col).instance
      end

      def relation(col) # nodoc
        _col = column(col)

        unless _relations[_col.name]
          _relations[_col.name] = begin
            case _col.type
            when :belongs_to; build_belongs_to_relation(_col)
            when :has_one;    build_has_one_relation(_col)
            when :has_many;   build_has_many_relation(_col)
            end
          end
        end
        _relations[_col.name]
      end

      def build_belongs_to_relation(col)
        if col.polymorphic
          associate_class, associate_id = get_polymorphic_attr(col.name)
        else
          associate_class = col.classify
          associate_id = _get_attr(col.foreign_key)
        end
        if associate_id.nil?
          # A null scope. If polymorphic, the class is arbitrary
          scope = SQLScope.new(nil, nil, nil)
        else
          scope = associate_class.where(id: associate_id)
        end
        InstanceRelation.new(self, col, associate_class, scope)
      end

      def build_has_one_relation(col)
        associate_class, scope = _has_many_has_one_relation_scope(col)
        InstanceRelation.new(self, col, associate_class, scope)
      end

      def build_has_many_relation(col)
        associate_class, scope = _has_many_has_one_relation_scope(col)
        CollectionRelation.new(self, col, associate_class, scope)
      end

      def _has_many_has_one_relation_scope(col)
        associate_class = col.classify
        _scope = associate_class
        _scope = _scope.where(col.conditions) if col.conditions

        if col.through
          through_col = column(col.through)
          _scope = _scope.scoped.joins(col.through)
          inverse_column = through_col.inverse_column
          table_name = through_col.classify.table_name
        else
          inverse_column = col.inverse_column
          table_name = col.classify.table_name
        end

        if inverse_column.nil?
          fail "inverse_column not found for #{self} column #{col.name}"
        end

        if inverse_column.polymorphic
          scope = -> do
            if id.nil?
              _scope.limit(0)
            else
              _scope.where(col.foreign_polymorphic_type => self.class.name, col.foreign_key => id)
            end
          end
        else
          scope = -> do
            if id.nil?
              _scope.limit(0)
            else
              _scope.where({table_name => inverse_column.foreign_key} => id)
            end
          end
        end

        [associate_class, scope]
      end

      def _db_transaction(&block)
        self.class.send(:transaction, &block)
      end

    end
  end
end
