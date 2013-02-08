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

  module Model
    def self.included(base)
      base.extend(PrivateClassMethods)
      base.extend(PublicClassMethods)
      base.instance_variable_set("@_columns", [])               # Columns in model
      base.instance_variable_set("@_column_hashes", {})         # Hashes to for quick column lookup
      base.instance_variable_set("@_relations", {})             # relations
      base.instance_variable_set("@collection", [])             # Actual data
      base.instance_variable_set("@_next_id", 1)                # Next assignable id
      base.instance_variable_set("@_issue_notifications", true) # Next assignable id
    end

    module PublicClassMethods
      # Use to do bulk insertion, updating, or deleting without
      # making repeated calls to a delegate. E.g., when syncing
      # with an external data source.
      def bulk_update(&block)
        @_issue_notifications = false
        class_eval &block
        @_issue_notifications = true
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
        return @_columns.map{|c| c.name} if fields.empty?

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
      def belongs_to(relation)
        add_field relation, :belongs_to
        add_field generate_belongs_to_id(relation), :belongs_to_id    # a relation is singular.
      end

      # Returns true if a column exists on this model, otherwise false.
      def column?(column)
        respond_to?(column)
      end

      # Returns type of this column.
      def type(column)
        column_named(column).type || nil
      end

      # returns default value for this column or nil.
      def default(column)
        column_named(column).default || nil
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

      def length
        @collection.length
      end
      alias_method :count, :length

      # Deletes all rows in the model -- no hooks are called and
      # deletes are not cascading so this does not affected related
      # data.
      def delete_all
        # Do each delete so any on_delete and
        # cascades are called, then empty the
        # collection and compact the array.
        bulk_update do
          @collection.each{|item| item.delete}
        end
        @collection = []
        @_next_id = 1
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

      # Finds row(s) within the data store. E.g.,
      #
      #   @post = Post.find(1)  # find a specific row by ID
      #
      # or...
      #
      #   @posts = Post.find(:author).eq('bob').all
      def find(*args, &block)
        if block_given?
          matches = @collection.collect do |item|
            item if yield(item)
          end.compact
          return FinderQuery.new(matches)
        end

        unless args[0].is_a?(Symbol) || args[0].is_a?(String)
          target_id = args[0].to_i
          return @collection.select{|element| element.id == target_id}.first
        end

        FinderQuery.new(args[0].to_sym, @collection)
      end
      alias_method :where, :find

      # Retrieves first row of query
      def first
        @collection.first
      end

      # Retrieves last row of query
      def last
        @collection.last
      end

      # Returns query result as an array
      def all
        @collection
      end

      def order(field_name = nil, &block)
        FinderQuery.new(@collection).order(field_name, &block)
      end

      def each(&block)
        raise ArgumentError.new("each requires a block") unless block_given?
        @collection.each{|item| yield item}
      end

      def empty?
        @collection.empty?
      end
    end

    module PrivateClassMethods
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
        if @_issue_notifications == true && !object.nil?
          NSNotificationCenter.defaultCenter.postNotificationName('MotionModelDataDidChangeNotification', object: object, userInfo: info)
        end
      end

      def define_accessor_methods(name) #nodoc
        define_method(name.to_sym) {
          @data[name]
        }
        define_method("#{name}=".to_sym) { |value|
          @data[name] = cast_to_type(name, value)
          @dirty = true
        }
      end

      def define_belongs_to_methods(name) #nodoc
        define_method(name) {
          col = column_named(name)
          parent_id = @data[self.class.generate_belongs_to_id(col.name)]
          col.classify.find(parent_id)
        }
        define_method("#{name}=") { |value|
          col = column_named(name)
          parent_id = self.class.generate_belongs_to_id(col.name)
          @data[parent_id.to_sym] = value.to_i
        }
      end

      def define_has_many_methods(name) #nodoc
        define_method(name) {
          relation_for(name)
        }
      end

      def add_field(name, type, options = {:default => nil}) #nodoc
        col = Column.new(name, type, options)

        @_columns.push col
        @_column_hashes[col.name.to_sym] = col

        case type
          when :has_many then define_has_many_methods(name)
          when :belongs_to then define_belongs_to_methods(name)
          else
            define_accessor_methods(name)
          end
      end

      # Returns a column denoted by +name+
      def column_named(name) #nodoc
        @_column_hashes[name.to_sym]
      end

      # Returns next available id
      def next_id #nodoc
        @_next_id
      end

      # Sets next available id
      def next_id=(value) #nodoc
        @_next_id = value
      end

      # Increments next available id
      def increment_id #nodoc
        @_next_id += 1
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
      @data ||= {}

      assign_id options

      columns.each do |col|
        unless relation_column?(col) # all data columns
          initialize_data_columns col, options
        else
          @data[col] = options[col] if column_named(col).type == :belongs_to_id
        end
      end

      @dirty = true
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
    def save
      call_hooks 'save' do
        @dirty = false

        # Existing object implies update in place
        action = 'add'
        set_auto_date_field 'created_at'
        if obj = collection.find{|o| o.id == @data[:id]}
          obj = self
          set_auto_date_field 'updated_at'
          action = 'update'
        else
          collection << self
        end
        self.class.issue_notification(self, :action => action)
      end
    end

    # Set created_at and updated_at fields
    def set_auto_date_field(field_name)
      self.send("#{field_name}=", Time.now) if self.respond_to? field_name
    end

    # Deletes the current object. The object can still be used.
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
      call_hooks('delete') do
        target_index = collection.index{|item| item.id == self.id}
        collection.delete_at(target_index) unless target_index.nil?
        self.class.issue_notification(self, :action => 'delete')
      end
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

    # Undelete does pretty much as its name implies. However,
    # the natural sort order is not preserved. IMPORTANT: If
    # you are trying to undo a cascading delete, this will not
    # work. It only undeletes the object you still own.

    def undelete
      collection << self
      self.class.issue_notification(self, :action => 'add')
    end

    # Count of objects in the current collection
    def length
      collection.length
    end
    alias_method :count, :length

    # True if the column exists, otherwise false
    def column?(column_name)
      self.class.column?(column_name.to_sym)
    end

    # Returns list of column names as an array
    def columns
      self.class.columns
    end

    # Type of a given column
    def type(column_name)
      self.class.type(column_name)
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

    # True if this object responds to the method or
    # property, otherwise false.
    alias_method :old_respond_to?, :respond_to?
    def respond_to?(method)
      column_named(method) || old_respond_to?(method)
    end

    def dirty?
      @dirty
    end


    private

    def assign_id(options) #nodoc
      unless options[:id]
        options[:id] = self.class.next_id
      else
        self.class.next_id = [options[:id].to_i, self.class.next_id].max
      end
      self.class.increment_id
    end

    def relation_column?(column) #nodoc
      [:belongs_to, :belongs_to_id, :has_many].include? column_named(column).type
    end

    def initialize_data_columns(column, options) #nodoc
       self.send("#{column}=".to_sym, options[column] || self.class.default(column))
    end

    def collection #nodoc
      self.class.instance_variable_get('@collection')
    end

    def column_named(name) #nodoc
      self.class.column_named(name.to_sym)
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

    # Any way you reach this means you've tried to access a method
    # not defined on this model.
    def method_missing(method, *args, &block) #nodoc
      if self.respond_to? method
        return method(args, &block)
      else
        raise NoMethodError.new("nil column #{self.class}##{method} accessed from #{caller[1]}.")
      end
    end
  end
end
