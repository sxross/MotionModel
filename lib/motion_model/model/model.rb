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

  module Model
    def self.included(base)
      base.extend(PrivateClassMethods)
      base.extend(PublicClassMethods)
    end

    module PublicClassMethods
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

        unless self.respond_to?(:id)
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

      def generate_belongs_to_id(relation)
        (relation.to_s.singularize.underscore + '_id').to_sym
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
        add_field generate_belongs_to_id(relation), :belongs_to_id    # a relation is singular.
      end

      # Returns true if a column exists on this model, otherwise false.
      def column?(column)
        !column_named(column).nil?
      end

      # Returns type of this column.
      def column_type(column)
        column_named(column).type || nil
      end

      # returns default value for this column or nil.
      def default(column)
        column_named(column).try(:default)
      end

      # Build an instance that represents a saved object from the persistence layer.
      def read(attrs)
        new(attrs).instance_eval do
          @new_record = false
          @dirty = false
          self
        end
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
      # :delete => destroy in the has_many macro.
      def destroy_all
        ids = self.all.map{|item| item.id}
        bulk_update do
          ids.each do |item|
            find(item).destroy
          end
        end
        # Note collection is not emptied, and next_id is not reset.
      end

      def find_by_id(id)
        where(id: id).first
      end

      # Retrieves first row of query
      def first
        all.first
      end

      # Retrieves last row of query
      def last
        all.last
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

      # Hashes to for quick column lookup
      def _column_hashes
        @_column_hashes ||= {}
      end

      @_issue_notifications = true
      def _issue_notifications
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

      def define_accessor_methods(name) #nodoc
        unless alloc.respond_to?(name.to_sym)
          define_method(name.to_sym) {
            @data[name]
          }
        end
        define_method("#{name}=".to_sym) { |value|
          @data[name] = cast_to_type(name, value)
          @dirty = true
        }
      end

      def define_belongs_to_methods(name) #nodoc
        define_method(name) {
          return @data[name] if @data[name]
          col = column_named(name)
          parent_id = @data[self.class.generate_belongs_to_id(col.name)]
          col.classify.find_by_id(parent_id)
        }
        define_method("#{name}=") { |parent|
          @data[name]  = parent
          col = column_named(name)
          parent_id = self.class.generate_belongs_to_id(col.name)
          @data[parent_id.to_sym] = parent.id
        }
      end

      def define_has_many_methods(name) #nodoc
        define_method(name) {
          relation_for(name)
        }
      end

      def add_field(name, type, options = {:default => nil}) #nodoc
        col = Column.new(name, type, options)

        _column_hashes[col.name.to_sym] = col

        case type
          when :has_many then define_has_many_methods(name)
          when :belongs_to then define_belongs_to_methods(name)
          else
            define_accessor_methods(name)
          end
      end

      # Returns a column denoted by +name+
      def column_named(name) #nodoc
        _column_hashes[name.to_sym]
      end

      def relation_column?(column) #nodoc
        [:belongs_to, :belongs_to_id, :has_many].include? column_named(column).type
      end

      def virtual_relation_column?(column) #nodoc
        [:belongs_to, :has_many].include? column_named(column).type
      end

      def has_relation?(col) #nodoc
        return false if col.nil?

        col = case col
        when MotionModel::Model::Column
          column_named(col.name)
        else
          column_named(col)
        end
        col.type == :has_many || col.type == :belongs_to
      end

    end

    def initialize(options = {})
      raise AdapterNotFoundError.new("You must specify a persistence adapter.") unless self.respond_to? :adapter

      @data ||= {}
      before_initialize(options) if respond_to?(:before_initialize)

      options.each do |col, value|
        initialize_data_columns col, value
      end

      @dirty = true
      @new_record = true
    end

    def new_record?
      @new_record
    end

    def attributes
      @data
    end

    def read_attribute(name)
      @data[name]
    end

    # Default to_i implementation returns value of id column, much as
    # in Rails.

    def to_i
      @data[:id].to_i
    end

    # Default to_s implementation returns a list of columns and values
    # separated by newlines.
    def to_s
      columns.each{|c| "#{c}: #{self.send(c)}\n"}
    end

    # Save current object. Speaking from the context of relational
    # databases, this inserts a row if it's a new one, or updates
    # in place if not.
    def save(*)
      call_hooks 'save' do
        # Existing object implies update in place
        action = 'add'
        set_auto_date_field 'updated_at'
        if new_record?
          set_auto_date_field 'created_at'
          do_insert
        else
          do_update
          action = 'update'
        end
        @new_record = false
        @dirty = false
        issue_notification(:action => action)
      end
    end

    # Set created_at and updated_at fields
    def set_auto_date_field(field_name)
      method = "#{field_name}="
      self.send(method, Time.now) if self.respond_to?(method)
    end

    def call_hook(hook_name, postfix)
      hook = "#{hook_name}_#{postfix}"
      self.send(hook, self) if respond_to? hook.to_sym
    end

    def call_hooks(hook_name, &block)
      result = call_hook('before', hook_name)
      # returning false from a before_ hook stops the process
      block.call if result != false && block_given?
      call_hook('after', hook_name)
    end

    def delete
      call_hooks('delete') { do_delete }
    end

    # Destroys the current object. The difference between delete
    # and destroy is that destroy calls <tt>before_delete</tt>
    # and <tt>after_delete</tt> hooks. As well, it will cascade
    # into related objects, deleting them if they are related
    # using <tt>:delete => :destroy</tt> in the <tt>has_many</tt>
    # declaration
    #
    # Note: lifecycle hooks are only called when individual objects
    # are deleted.
    def destroy
      has_many_columns.each do |col|
        delete_candidates = self.send(col.name)

        delete_candidates.each do |candidate|
          candidate.delete if col.destroy == :delete
          candidate.destroy if col.destroy == :destroy
        end
      end
      delete
    end

    # True if the column exists, otherwise false
    def column?(column_name)
      self.class.column?(column_name.to_sym)
    end

    # Returns list of column names as an array
    def columns
      self.class.columns
    end

    # Type of a given column
    def column_type(column_name)
      self.class.column_type(column_name)
    end

    # Options hash for column, excluding the core
    # options such as type, default, etc.
    #
    # Options are completely arbitrary so you can
    # stuff anything in this hash you want. For
    # example:
    #
    #    columns :date => {:type => :date, :formotion => {:picker_type => :date_time}}
    def options(column_name)
      column_named(column_name).options
    end

    def dirty?
      @dirty
    end

    private

    def _column_hashes
      self.class.send(:_column_hashes)
    end

    def relation_column?(col)
      self.class.send(:relation_column?, col)
    end

    def virtual_relation_column?(col)
      self.class.send(:virtual_relation_column?, col)
    end

    def has_relation?(col) #nodoc
      self.class.send(:has_relation?, col)
    end

    def initialize_data_columns(column, value) #nodoc
      self.send("#{column}=".to_sym, value || self.class.default(column))
    end

    def column_named(name) #nodoc
      self.class.send(:column_named, name.to_sym)
    end

    def has_many_columns
      columns.map{|col| column_named(col)}.select{|col| col.type == :has_many}
    end

   def generate_belongs_to_id(class_or_column) # nodoc
      self.class.generate_belongs_to_id(self.class)
    end

    def relation_for(col) # nodoc
      col = column_named(col)
      related_klass = col.classify

      case col.type
        when :belongs_to
          related_klass.find(@data[:id])
        when :has_many
          related_klass.find(generate_belongs_to_id(self.class)).belongs_to(self, related_klass).eq(@data[:id])
        else
          nil
      end
    end

    def issue_notification(info) #nodoc
      self.class.send(:issue_notification, self, info)
    end

    def method_missing(name, *args, &block)
      if name.to_s[-1] == '='
        @data["#{name[0..-2]}".to_sym] = args.first
        return args.first
      else
        return @data[name] if @data.has_key?(name)
      end
      super
    end

  end
end
