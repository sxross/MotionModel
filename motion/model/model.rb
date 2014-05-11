# MotionModel encapsulates a pattern for synthesizing a model
# out of thin air. The model will have attributes, types,
# finders, ordering, ... the works.
#
# As an example, consider:
#
#    class Task
#      include MotionModel
#
#      columns :task_name => :string,
#              :details   => :string,
#              :due_date  => :date
#
#      # any business logic you might add...
#    end
#
# Now, you can write code like:
#
#
# Recognized types are:
#
# * :string
# * :text
# * :date (must be in YYYY-mm-dd form)
# * :time
# * :integer
# * :float
# * :boolean
# * :array
#
# Assuming you have a bunch of tasks in your data store, you can do this:
#
#    tasks_this_week = Task.where(:due_date).ge(beginning_of_week).and(:due_date).le(end_of_week).order(:due_date)
#
# Partial queries are supported so you can do:
#
#    tasks_this_week = Task.where(:due_date).ge(beginning_of_week).and(:due_date).le(end_of_week)
#    ordered_tasks_this_week = tasks_this_week.order(:due_date)
#
module MotionModel
  class PersistFileError < Exception; end
  class RelationIsNilError < Exception; end
  class AdapterNotFoundError < Exception; end
  class RecordNotSaved < Exception; end

  module Model
    def self.included(base)
      base.extend(PrivateClassMethods)
      base.extend(PublicClassMethods)

      base.instance_eval do
        unless self.respond_to?(:id)
          add_field(:id, :integer)
        end
      end
    end

    module PublicClassMethods

      def new(options = {})
        object_class = options[:inheritance_type] ? Kernel.const_get(options[:inheritance_type]) : self
        object_class.allocate.instance_eval do
          initialize(options)
          self
        end
      end

      # Use to do bulk insertion, updating, or deleting without
      # making repeated calls to a delegate. E.g., when syncing
      # with an external data source.
      def bulk_update(&block)
        self._issue_notifications = false
        class_eval &block
        self._issue_notifications = true
      end

      # Macro to define names and types of columns. It can be used in one of
      # two forms:
      #
      # Pass a hash, and you define columns with types. E.g.,
      #
      #   columns :name => :string, :age => :integer
      #
      # Pass a hash of hashes and you can specify defaults such as:
      #
      #   columns :name => {:type => :string, :default => 'Joe Bob'}, :age => :integer
      #
      # Pass an array, and you create column names, all of which have type +:string+.
      #
      #   columns :name, :age, :hobby

      def columns(*fields)
        return _columns.map{|c| c.name} if fields.empty?

        case fields.first
        when Hash
          column_from_hash fields
        when String, Symbol
          column_from_string_or_sym fields
        else
          raise ArgumentError.new("arguments to `columns' must be a symbol, a hash, or a hash of hashes -- was #{fields.first}.")
        end

        unless columns.include?(:id)
          add_field(:id, :integer)
        end
      end

      # Use at class level, as follows:
      #
      #   class Task
      #     include MotionModel::Model
      #
      #     columns  :name, :details, :assignees
      #     has_many :assignees
      #
      # Note that :assignees must be declared as a virtual attribute on the
      # model before you can has_many on it.
      #
      # This enables code like:
      #
      #   Task.find(:due_date).gt(Time.now).first.assignees
      #
      # to get the people assigned to first task that is due after right now.
      #
      # This must be used with a belongs_to macro in the related model class
      # if you want to be able to access the inverse relation.

      def has_many(relation, options = {})
        raise ArgumentError.new("arguments to has_many must be a symbol or string.") unless [Symbol, String].include? relation.class
        add_field relation, :has_many, options        # Relation must be plural
      end

      def has_one(relation, options = {})
        raise ArgumentError.new("arguments to has_one must be a symbol or string.") unless [Symbol, String].include? relation.class
        add_field relation, :has_one, options        # Relation must be plural
      end

      # Use at class level, as follows
      #
      #   class Assignee
      #     include MotionModel::Model
      #
      #     columns :assignee_name, :department
      #     belongs_to :task
      #
      # Allows code like this:
      #
      #   Assignee.find(:assignee_name).like('smith').first.task
      def belongs_to(relation, options = {})
        add_field relation, :belongs_to, options
      end

      # Returns true if a column exists on this model, otherwise false.
      def column?(col)
        !column(col).nil?
      end

      # Returns type of this column.
      def column_type(col)
        column(col).type || nil
      end

      def column(col)
        col.is_a?(Column) ? col : _column_hashes[col.to_sym]
      end

      def has_many_columns
        _column_hashes.select { |name, col| col.type == :has_many}
      end

      def has_one_columns
        _column_hashes.select { |name, col| col.type == :has_one}
      end

      def belongs_to_columns
        _column_hashes.select { |name, col| col.type == :belongs_to}
      end

      def association_columns
        _column_hashes.select { |name, col| [:belongs_to, :has_many, :has_one].include?(col.type)}
      end

      # returns default value for this column or nil.
      def default(col)
        _col = column(col)
        _col.nil? ? nil : _col.default
      end

      # Build an instance that represents a saved object from the persistence layer.
      def read(attrs)
        new(attrs).instance_eval do
          @new_record = false
          @dirty = false
          self
        end
      end

      def create!(options)
        result = create(options)
        raise RecordNotSaved unless result
        result
      end

      # Creates an object and saves it. E.g.:
      #
      #   @bob = Person.create(:name => 'Bob', :hobby => 'Bird Watching')
      #
      # returns the object created or false.
      def create(options = {})
        row = self.new(options)
        row.save
        row
      end

      # Destroys all rows in the model -- before_delete and after_delete
      # hooks are called and deletes are not cascading if declared with
      # :dependent => :destroy in the has_many macro.
      def destroy_all
        ids = self.all.map{|item| item.id}
        bulk_update do
          ids.each do |item|
            find_by_id(item).destroy
          end
        end
        # Note collection is not emptied, and next_id is not reset.
      end

      # Retrieves first row or count rows of query
      def first(*args)
        all.send(:first, *args)
      end

      # Retrieves last row or count rows of query
      def last(*args)
        all.send(:last, *args)
      end

      def each(&block)
        raise ArgumentError.new("each requires a block") unless block_given?
        all.each{|item| yield item}
      end

      def empty?
        all.empty?
      end
    end

    module PrivateClassMethods

      private

      attr_accessor :abstract_class

      def config
        @config ||= begin
          if !superclass.ancestors.include?(MotionModel::Model) || superclass.abstract_class
            {}
          else
            superclass.send(:config).dup
          end
        end
      end

      # Hashes to for quick column lookup
      def _column_hashes
        config[:column_hashes] ||= {}
      end

      # BUGBUG: This appears not to be executed, therefore @_issue_notifications is always nil to begin with.
      @_issue_notifications = true
      def _issue_notifications
        @_issue_notifications = true if @_issue_notifications.nil?
        @_issue_notifications
      end

      def _issue_notifications=(value)
        @_issue_notifications = value
      end

      def _columns
        _column_hashes.values
      end

      # This populates a column from something like:
      #
      #   columns :name => :string, :age => :integer
      #
      #   or
      #
      #   columns :name => {:type => :string, :default => 'Joe Bob'}, :age => :integer

      def column_from_hash(hash) #nodoc
        hash.first.each_pair do |name, options|
          raise ArgumentError.new("you cannot use `description' as a column name because of a conflict with Cocoa.") if name.to_s == 'description'

          case options
          when Symbol, String
            add_field(name, options)
          when Hash
            add_field(name, options.delete(:type), options)
          else
            raise ArgumentError.new("arguments to `columns' must be a symbol, a hash, or a hash of hashes.")
          end
        end
      end

      # This populates a column from something like:
      #
      #   columns :name, :age, :hobby

      def column_from_string_or_sym(string) #nodoc
        string.each do |name|
          add_field(name.to_sym, :string)
        end
      end

      def issue_notification(object, info) #nodoc
        if _issue_notifications == true && !object.nil?
          NSNotificationCenter.defaultCenter.postNotificationName('MotionModelDataDidChangeNotification', object: object, userInfo: info)
        end
      end

      def define_accessor_methods(name, type, options = {}) #nodoc
        define_method(name.to_sym)        { _get_attr(name) } unless allocate.respond_to?(name)
        define_method("#{name}=".to_sym)  { |v| _set_attr(name, v) }
      end

      def define_belongs_to_methods(name) #nodoc
        col = column(name)
        define_method(name)               { get_belongs_to_attr(col) }
        define_method("#{name}=")         { |owner| set_belongs_to_attr(col, owner) }

        # TODO also define #{name}+id= methods....

        if col.polymorphic
          add_field col.foreign_polymorphic_type, :belongs_to_type
          add_field col.foreign_key,              :belongs_to_id
        else
          add_field col.foreign_key,              :belongs_to_id    # a relation is singular.
        end
      end

      def define_has_many_methods(name) #nodoc
        col = column(name)
        define_method(name)               { get_has_many_attr(col) }
        define_method("#{name}=")         { |collection| set_has_many_attr(col, *collection) }
      end

      def define_has_one_methods(name) #nodoc
        col = column(name)
        define_method(name)               { get_has_one_attr(col) }
        define_method("#{name}=")         { |instance| set_has_one_attr(col, instance) }
      end

      def add_field(name, type, options = {:default => nil}) #nodoc
        name = name.to_sym
        col = Column.new(self, name, type, options)

        _column_hashes[col.name] = col

        case type
          when :has_many    then define_has_many_methods(name)
          when :has_one     then define_has_one_methods(name)
          when :belongs_to  then define_belongs_to_methods(name)
          else                   define_accessor_methods(name, type, options)
          end
      end

      # Returns the column that has the name as its :as option
      def column_as(col) #nodoc
        _col = column(col)
        _column_hashes.values.find{ |c| c.as == _col.name }
      end

      # All relation columns, including type and id columns for polymorphic associations
      def relation_column?(col) #nodoc
        _col = column(col)
        [:belongs_to, :belongs_to_id, :belongs_to_type, :has_many, :has_one].include?(_col.type)
      end

      # Polymorphic association columns that are not stored in DB
      def virtual_polymorphic_relation_column?(col) #nodoc
        _col = column(col)
        [:belongs_to, :has_many, :has_one].include?(_col.type)
      end

      def has_relation?(col) #nodoc
        return false if col.nil?
        _col = column(col)
        [:has_many, :has_one, :belongs_to].include?(_col.type)
      end

    end

    def initialize(options = {})
      raise AdapterNotFoundError.new("You must specify a persistence adapter.") unless self.respond_to? :adapter

      @data ||= {}
      before_initialize(options) if respond_to?(:before_initialize)

      # Gather defaults
      columns.each do |col|
        next if options.has_key?(col)
        next if relation_column?(col)
        default = self.class.default(col)
        options[col] = default unless default.nil?
      end

      options.each do |col, value|
        initialize_data_columns col, value
      end

      @dirty = true
      @new_record = true
    end

    # String uniquely identifying a saved model instance in memory
    def object_identifier
      ["#{self.class.name}", (id.nil? ? nil : "##{id}"), ":0x#{self.object_id.to_s(16)}"].join
    end

    # String uniquely identifying a saved model instance
    def model_identifier
      raise 'Invalid' unless id
      "#{self.class.name}##{id}"
    end

    def new_record?
      @new_record
    end

    # Returns true if +comparison_object+ is the same exact object, or +comparison_object+
    # is of the same type and +self+ has an ID and it is equal to +comparison_object.id+.
    #
    # Note that new records are different from any other record by definition, unless the
    # other record is the receiver itself. Besides, if you fetch existing records with
    # +select+ and leave the ID out, you're on your own, this predicate will return false.
    #
    # Note also that destroying a record preserves its ID in the model instance, so deleted
    # models are still comparable.
    def ==(comparison_object)
      super ||
        comparison_object.instance_of?(self.class) &&
        !id.nil? &&
        comparison_object.id == id
    end
    alias :eql? :==

    def attributes
      @data
    end

    def attributes=(attrs)
      attrs.each { |k, v| set_attr(k, v) }
    end

    def update_attributes(attrs)
      self.attributes = attrs
      save
    end

    def read_attribute(name)
      @data[name]
    end

    # Default to_i implementation returns value of id column, much as
    # in Rails.

    def to_i
      @data[:id].to_i
    end

    # Default inspect implementation returns identifier and ID
    # Need to keep this short, i.e. for running specs as the output could be very large
    def inspect
      object_identifier
    end

    def to_s
      columns.each{|c| "#{c}: #{get_attr(c)}\n"}
    end

    def save!(options = {})
      result = save(options)
      raise RecordNotSaved unless result
      result
    end

    # Save current object. Speaking from the context of relational
    # databases, this inserts a row if it's a new one, or updates
    # in place if not.
    def save(options = {})
      save_without_transaction(options)
    end

    # Performs the save.
    # This is separated to allow #save to do any transaction handling that might be necessary.
    def save_without_transaction(options = {})
      return false if @deleted
      call_hooks 'save' do
        # Existing object implies update in place
        action = 'add'
        set_auto_date_field 'updated_at'
        if new_record?
          set_auto_date_field 'created_at'
          result = do_insert(options)
        else
          result = do_update(options)
          action = 'update'
        end
        @new_record = false
        @dirty = false
        issue_notification(:action => action)
        result
      end
    end

    # Set created_at and updated_at fields
    def set_auto_date_field(field_name)
      method = "#{field_name}="
      self.send(method, Time.now) if self.respond_to?(method)
    end

    # Stub methods for hook protocols
    def before_save(sender); end
    def after_save(sender);  end
    def before_delete(sender); end
    def after_delete(sender); end
    def before_destroy(sender); end
    def after_destroy(sender); end

    def call_hook(hook_name, postfix)
      hook = "#{hook_name}_#{postfix}"
      self.send(hook, self)
    end

    def call_hooks(hook_name, &block)
      result = call_hook('before', hook_name)
      # returning false from a before_ hook stops the process
      result = block.call if result != false && block_given?
      call_hook('after', hook_name) if result
      result
    end

    def delete(options = {})
      return if @deleted
      call_hooks('delete') do
        options = options.dup
        options[:omit_model_identifiers] ||= {}
        options[:omit_model_identifiers][model_identifier] = self
        do_delete
        @deleted = true
      end
    end

    # Destroys the current object. The difference between delete
    # and destroy is that destroy calls <tt>before_delete</tt>
    # and <tt>after_delete</tt> hooks. As well, it will cascade
    # into related objects, deleting them if they are related
    # using <tt>:dependent => :destroy</tt> in the <tt>has_many</tt>
    # and <tt>has_one></tt> declarations
    #
    # Note: lifecycle hooks are only called when individual objects
    # are deleted.
    def destroy(options = {})
      call_hooks 'destroy' do
        options = options.dup
        options[:omit_model_identifiers] ||= {}
        options[:omit_model_identifiers][model_identifier] = self
        self.class.association_columns.each do |name, col|
          delete_candidates = get_attr(name)
          Array(delete_candidates).each do |candidate|
            next if options[:omit_model_identifiers][candidate.model_identifier]
            if col.dependent == :destroy
              candidate.destroy(options)
            elsif col.dependent == :delete
              candidate.delete(options)
            end
          end
        end
        delete
      end
      self
    end

    # True if the column exists, otherwise false
    def column?(col)
      self.class.column?(col)
    end

    def column(col)
      self.class.column(col)
    end

    # Returns list of column names as an array
    def columns
      self.class.columns
    end

    # Type of a given column
    def column_type(col)
      self.class.column_type(col)
    end

    # Options hash for column, excluding the core
    # options such as type, default, etc.
    #
    # Options are completely arbitrary so you can
    # stuff anything in this hash you want. For
    # example:
    #
    #    columns :date => {:type => :date, :formotion => {:picker_type => :date_time}}
    def options(col)
      column(col).options
    end

    def dirty?
      @dirty
    end

    def set_dirty
      @dirty = true
    end

    def get_attr(name)
      send(name)
    end

    def _attr_present?(name)
      @data.has_key?(name)
    end

    def _get_attr(col)
      _col = column(col)
      return nil if @data[_col.name].nil?
      if _col.symbolize
        @data[_col.name].to_sym
      else
        @data[_col.name]
      end
    end

    def set_attr(name, value)
      method = "#{name}=".to_sym
      respond_to?(method) ? send(method, value) : _set_attr(name, value)
    end

    def _set_attr(name, value)
      name = name.to_sym
      old_value = @data[name]
      new_value = !column(name) || relation_column?(name) ? value : cast_to_type(name, value)
      if new_value != old_value
        @data[name] = new_value
        @dirty = true
      end
    end

    def get_belongs_to_attr(col)
      belongs_to_relation(col)
    end

    def get_has_many_attr(col)
      _has_many_has_one_relation(col)
    end

    def get_has_one_attr(col)
      _has_many_has_one_relation(col)
    end

    # Associate the owner but without rebuilding the inverse assignment
    def set_belongs_to_attr(col, owner, options = {})
      _col = column(col)
      unless belongs_to_synced?(_col, owner)
        _set_attr(_col.name, owner)
        rebuild_relation(_col, owner, set_inverse: options[:set_inverse])
        if _col.polymorphic
          set_polymorphic_attr(_col.name, owner)
        else
          _set_attr(_col.foreign_key, owner ? owner.id : nil)
        end
      end

      owner
    end

    # Determine if the :belongs_to relationship is synchronized. Checks the instance and the DB column attributes.
    def belongs_to_synced?(col, owner)
      # The :belongs_to that points to the instance has changed
      return false if get_belongs_to_attr(col) != owner

      # The polymorphic reference (_type, _id) columns do not match, maybe it was just saved
      return false if col.polymorphic && !polymorphic_attr_matches?(col, owner)

      # The key reference (_id) column does not match, maybe it was just saved
      return false if _get_attr(col.foreign_key) != owner.try(:id)

      true
    end

    def push_has_many_attr(col, *instances)
      _col = column(col)
      collection = get_has_many_attr(_col)
      _collection = []
      instances.each do |instance|
        next if collection.include?(instance)
        _collection << instance
      end
      push_relation(_col, *_collection)
      instances
    end

    # TODO clean up existing reference, check rails
    def set_has_many_attr(col, *instances)
      _col = column(col)
      unload_relation(_col)
      push_has_many_attr(_col, *instances)
      instances
    end

    def set_has_one_attr(col, instance)
      _col = column(col)
      if get_has_one_attr(_col) != instance
        rebuild_relation(_col, instance)
      end
      instance
    end

    def get_polymorphic_attr(col)
      _col = column(col)
      owner_class = nil
      id                  = _get_attr(_col.foreign_key)
      unless id.nil?
        owner_class_name  = _get_attr(_col.foreign_polymorphic_type)
        owner_class_name  = String(owner_class_name) # RubyMotion issue, String#classify might fail otherwise
        owner_class       = Kernel::deep_const_get(owner_class_name.classify)
      end
      [owner_class, id]
    end


    def polymorphic_attr_matches?(col, instance)
      klass, id = get_polymorphic_attr(col)
      klass == instance.class && id == instance.id
    end

    def set_polymorphic_attr(col, instance)
      _col = column(col)
      _set_attr(_col.foreign_polymorphic_type,  instance.class.name)
      _set_attr(_col.foreign_key,               instance.id)
      instance
    end

    def foreign_column_name(col)
      if col.polymorphic
        col.as || col.name
      elsif col.foreign_key
        col.foreign_key
      else
        self.class.name.underscore.to_sym
      end
    end

    private

    def _column_hashes
      self.class.send(:_column_hashes)
    end

    def relation_column?(col)
      self.class.send(:relation_column?, col)
    end

    def virtual_polymorphic_relation_column?(col)
      self.class.send(:virtual_polymorphic_relation_column?, col)
    end

    def has_relation?(col) #nodoc
      self.class.send(:has_relation?, col)
    end

    def rebuild_relation(col, instance_or_collection, options = {}) # nodoc
    end

    def unload_relation(col)
    end

    def evaluate_default_value(column, value)
      default = self.class.default(column)

      case default
      when NilClass
        {column => value}
      when Proc
        begin
          {column => default.call}
        rescue Exception => ex
          Debug.error "\n\nProblem initializing #{self.class} : #{column} with default and proc.\nException: #{ex.message}\nSorry, your app is pretty much crashing.\n"
          exit
        end
      when Symbol
        {column => self.send(column)}
      else
        {column => default}
      end
    end

    # issue #113. added ability to specify a proc or block
    # for the default value. This allows for arrays to be
    # created as unique. E.g.:
    #
    #     class Foo
    #       include MotionModel::Model
    #       include MotionModel::ArrayModelAdapter
    #       columns  subject: { type: :array, default: ->{ [] } }
    #     end
    #
    #     ...
    #
    # This is not constrained to initializing arrays. You can
    # initialize pretty much anything using a proc or block.
    # If you are specifying a block, make sure to use begin/end
    # instead of do/end because it makes Ruby happy.

    def initialize_data_columns(column, value) #nodoc
      self.attributes = evaluate_default_value(column, value)
    end

    def column_as(col) #nodoc
      self.class.send(:column_as, col)
    end

    def issue_notification(info) #nodoc
      self.class.send(:issue_notification, self, info)
    end

    def method_missing(sym, *args, &block)
      return @data[sym] if sym.to_s[-1] != '=' && @data && @data.has_key?(sym)
      super
    end

  end
end
