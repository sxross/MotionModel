module MotionModel
  module SQLModelAdapter
    def adapter
      self
    end

    def self.included(base)
      base.send(:include, BaseModelAdapter)
      base.extend(PrivateClassMethods)
      base.extend(PublicClassMethods)
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
        _db_adapter.create_table(table_name, _db_column_config)
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
        default_scope.limit(1).first
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
      alias_method :find, :where

      def find_by_id(id)
        where(id: id).first
      end

      def do_select(scope)
        rows_attrs = scope.execute.map do |row|
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

      def foreign_key(associated_class)
        "#{associated_class.name.to_s.underscore}_id".to_sym
      end

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

      def transaction(&block)
        _db_adapter.transaction(&block)
      end
    end

    def insert_sql
      attrs = _db_typed_attributes
      attrs.delete(:id) if attrs[:id].nil?
      _db_adapter.to_insert_sql(self.class.default_scope, attrs)
    end

    def do_insert(options)
      _db_transaction do
        save_belongs_to_relations(options)
        result = _db_adapter.build_sql_context(:insert, insert_sql).execute
        if result
          self.id = _db_adapter.last_insert_row_id
          save_has_many_has_one_relations(options)
          self
        else
          false
        end
      end
    end

    def do_update(options)
      _db_transaction do
        save_belongs_to_relations(options)
        result = _db_adapter.build_sql_context(:update, update_sql).execute
        if result
          save_has_many_has_one_relations(options)
          true
        else
          false
        end
      end
    end

    def save(options = {})
      options = options.dup
      options[:omit_instances] ||= {}
      options[:omit_instances][object_id] = true
      super
    end

    def save_belongs_to_relations(options)
      self.class.belongs_to_columns.each do |name, col|
        associate = send(name)
        next if associate.nil? || !associate.dirty?
        associate.save(options) unless options[:omit_instances][associate.object_id]
        foreign_key = self.class.foreign_key(associate.class)
        self.attributes = {foreign_key => associate.id}
      end
    end

    def save_has_many_has_one_relations(options)
      cols = self.class.has_many_columns.merge(self.class.has_one_columns)
      cols.each do |name, col|
        ref = self.send(name)
        if col.type == :has_many
          associates = ref.is_a?(Relation) ? ref.collection : ref
        else
          if ref.is_a?(Relation)
            associates = ref.instance ? [ref.instance] : nil
          else
            associates = [ref]
          end
        end
        associates.each do |associate|
          if col.options[:polymorphic]
            foreign_key = "#{col.options[:as]}_id"
            foreign_type = "#{col.options[:as]}_type"
            associate.attributes = {foreign_type => self.class.name} unless associate.send(foreign_type)
          else
            foreign_key = associate.class.foreign_key(self.class)
          end
          associate.attributes = {foreign_key => id} unless associate.send(foreign_key)
          next unless associate.dirty?
          associate.save(options) unless options[:omit_instances][associate.object_id]
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

    private

    # Attributes converted to a hash of db-compatible types
    def _db_typed_attributes
      attrs = {}
      _db_column_config.each { |k, v| attrs[k] = _db_adapter.to_db_type(_column_hashes[k].type, send(k)) }
      attrs
    end

    def _db_column_config
      self.class.send(:_db_column_config)
    end

    def relation_columns
      @relation_columns ||= {}
    end

    def relations
      @relations ||= {}
    end

    def relation_for(column_name) # nodoc
      col = column_named(column_name)
      associated_class = col.classify

      case col.type
      when :belongs_to
        relations[col.name] ||= begin
          foreign_id = send(self.class.foreign_key(associated_class))
          return nil if foreign_id.nil?
          relation_columns[col.name] = col
          Relation.new(self, col.type, associated_class, associated_class.where(id: foreign_id))
        end
      when :has_many, :has_one
        relations[col.name] ||= begin
          relation_columns[col.name] = col
          if col.options[:polymorphic]
            scope = -> { id.nil? ? associated_class.limit(0) :
                associated_class.where("#{col.options[:as]}_type" => self.class.name, "#{col.options[:as]}_id" => id) }
            Relation.new(self, col.type, associated_class, scope, polymorphic: true, as: col.options[:as])
          else
            scope = -> { id.nil? ? associated_class.limit(0) :
                associated_class.where(associated_class.foreign_key(self.class) => id) }
            Relation.new(self, col.type, associated_class, scope)
          end
        end
      else
        nil
      end
    end

    def _db_transaction(&block)
      self.class.send(:transaction, &block)
    end

  end

end
