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
#    Task.create :task_name => 'Walk the dog',
#                :details   => 'Pick up after yourself',
#                :due_date  => '2012-09-17'
#
# Recognized types are:
#
# * :string
# * :date (must be in YYYY-mm-dd form)
# * :integer
# * :float
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
      base.extend(ClassMethods)
      base.instance_variable_set("@_columns", [])               # Columns in model
      base.instance_variable_set("@_column_hashes", {})         # Hashes to for quick column lookup
      base.instance_variable_set("@_relations", {})             # relations
      base.instance_variable_set("@collection", [])             # Actual data
      base.instance_variable_set("@_next_id", 1)                # Next assignable id
      base.instance_variable_set("@_issue_notifications", true) # Next assignable id
    end
    
    module ClassMethods
      # Use to do bulk insertion, updating, or deleting without
      # making repeated calls to a delegate. E.g., when syncing
      # with an external data source.
      def bulk_update(&block)
        @_issue_notifications = false
        class_eval &block
        @_issue_notifications = true
      end
      
      def issue_notification(object, info) #nodoc
        if @_issue_notifications == true && !object.nil?
          NSNotificationCenter.defaultCenter.postNotificationName('MotionModelDataDidChangeNotification', object: object, userInfo: info)
        end
      end

      def define_accessor_methods(name)
        define_method(name.to_sym) {
          @data[name]
        }
        define_method("#{name}=".to_sym) { |value|
          @data[name] = cast_to_type(name, value)
        }
      end

      def define_belongs_to_methods(name)
        define_method(name) {
          col = column_named(name)
          parent_id = @data[self.class.belongs_to_id(col.name)]
          col.classify.find(parent_id)
        }
        define_method("#{name}=") { |value|
          col = column_named(name)
          parent_id = self.class.belongs_to_id(col.name)
          @data[parent_id.to_sym] = value.to_i
        }
      end

      def define_has_many_methods(name)
        define_method(name) {
          relation_for(name)
        }
      end

      def add_field(name, type, default = nil) #nodoc
        col = Column.new(name, type, default)
        @_columns.push col
        @_column_hashes[col.name.to_sym] = col

        case type
          when :has_many
            define_has_many_methods(name)
          when :belongs_to
            define_belongs_to_methods(name)
          else
            define_accessor_methods(name)
          end
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

        col = Column.new
        
        case fields.first
        when Hash
          fields.first.each_pair do |name, options|
            raise ArgumentError.new("you cannot use `description' as a column name because of a conflict with Cocoa.") if name.to_s == 'description'
            
            case options
            when Symbol, String
              add_field(name, options)
            when Hash
              add_field(name, options[:type], options[:default])
            else
              raise ArgumentError.new("arguments to fields must be a symbol, a hash, or a hash of hashes.")
            end
          end
        else
          fields.each do |name|
            add_field(name, :string)
          end
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
      def has_many(*relations)
        relations.each do |relation|
          raise ArgumentError.new("arguments to has_many must be a symbol, a string or an array of same.") unless relation.is_a?(Symbol) || relation.is_a?(String)
          add_field relation, :has_many                                   # Relation must be plural
        end
      end
      
      def belongs_to_id(relation)
        (relation.to_s.underscore + '_id').to_sym
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
        add_field belongs_to_id(relation), :belongs_to_id    # a relation is singular.
      end
      
      # Returns a column denoted by +name+
      def column_named(name)
        @_column_hashes[name.to_sym]
      end

      # Returns next available id
      def next_id #nodoc
        @_next_id
      end

      # Sets next available id
      def next_id=(value)
        @_next_id = value
      end

      # Increments next available id
      def increment_id #nodoc
        @_next_id += 1
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
      
      def has_relation?(col)
        return false if col.nil?

        col = case col
        when MotionModel::Model::Column
          column_named(col.name)
        else
          column_named(col)
        end
        col.type == :has_many || col.type == :belongs_to
      end
      
      # Creates an object and saves it. E.g.:
      #
      #   @bob = Person.create(:name => 'Bob', :hobby => 'Bird Watching')
      #
      # returns the object created or false.
      def create(options = {})
        row = self.new(options)
        row.before_create if row.respond_to?(:before_create)
        row.before_save   if row.respond_to?(:before_save)
        
        # TODO: Check for Validatable and if it's
        # present, check valid? before saving.

        row.save
        row
      end
      
      def length
        @collection.length
      end
      alias_method :count, :length

      # Empties the entire store.
      def delete_all
        # Do each delete so any on_delete and
        # cascades are called, then empty the
        # collection and compact the array.
        bulk_update do
          @collection.each{|item| item.delete}
        end
        @collection = []
        @_next_id = 1
        # @collection.compact!
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
          return @collection.select{|c| c.id == args[0].to_i}.first || nil
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
 
    ####### Instance Methods #######
    def initialize(options = {})
      @data ||= {}  # REVIEW: Why make this conditional?
      
      # Time zone, for future use.
      @tz_offset ||= NSDate.date.to_s.gsub(/^.*?( -\d{4})/, '\1')

      @cached_date_formatter = NSDateFormatter.alloc.init # Create once, as they are expensive to create
      @cached_date_formatter.dateFormat = "MM-dd-yyyy HH:mm"
      
      unless options[:id]
        options[:id] = self.class.next_id
      else
        self.class.next_id = [options[:id].to_i, self.class.next_id].max
      end
      self.class.increment_id

      columns.each do |col|
        unless [:belongs_to, :belongs_to_id, :has_many].include? column_named(col).type
          options[col] ||= self.class.default(col)
          cast_value = cast_to_type(col, options[col])
          @data[col] = cast_value
        else
          if column_named(col).type == :belongs_to_id
            @data[col] = options[col]
          end
        end
      end
      
      dirty = true
    end

    def to_i
      @data[:id].to_i
    end

    def cast_to_type(column_name, arg)
      return nil if arg.nil?
      
      return_value = arg
      
      case type(column_name)
      when :string
        return_value = arg.to_s
      when :int, :integer, :belongs_to_id
        return_value = arg.is_a?(Integer) ? arg : arg.to_i
      when :float, :double
        return_value = arg.is_a?(Float) ? arg : arg.to_f
      when :date
        return arg if arg.is_a?(NSDate)
        return_value = NSDate.dateWithNaturalLanguageString(arg, locale:NSUserDefaults.standardUserDefaults.dictionaryRepresentation)
      else
        raise ArgumentError.new("type #{column_name} : #{type(column_name)} is not possible to cast.")
      end
      return_value
    end

    def to_s
      columns.each{|c| "#{c}: #{self.send(c)}\n"}
    end
    
    def save
      collection = self.class.instance_variable_get('@collection')
      @dirty = false
      
      # Existing object implies update in place
      # TODO: Optimize location of existing id
      action = 'add'
      if obj = collection.find{|o| o.id == @data[:id]}
        collection = self
        action = 'update'
      else
        collection << self
      end
      self.class.issue_notification(self, :action => action)
    end
    
    def delete
      collection = self.class.instance_variable_get('@collection')
            
      target_index = collection.index{|item| item.id == self.id}
      collection.delete_at(target_index)
      self.class.issue_notification(self, :action => 'delete')
    end

    def length
      @collection.length
    end
    
    alias_method :count, :length
      
    def column?(target_key)
      self.class.column?(target_key.to_sym)
    end

    def columns
      self.class.columns
    end

    def column_named(name)
      self.class.column_named(name.to_sym)
    end

    def type(field_name)
      self.class.type(field_name)
    end
    
    # Modify respond_to? to add model's attributes.
    alias_method :old_respond_to?, :respond_to?
    def respond_to?(method)
      column_named(method) || old_respond_to?(method)
    end
    
    def dirty?
      @dirty      
    end
    
    def relation_for(col)
      # relation is a belongs_to or a has_many
      col = column_named(col)
      raise RelationIsNilError.new("nil relation #{col} accessed from #{caller[1]}.") if col.nil?

      case col.type
        when :belongs_to
          return col.classify.find(@data[:id])
         when :has_many
          belongs_to_id = self.class.send(:belongs_to_id, self.class.to_s)
          return col.classify.find(belongs_to_id).belongs_to(self, col.classify).eq(@data[:id])
        else
          false
      end
    end
    
    # Handle attribute retrieval
    # 
    # Gets and sets work as expected, and type casting occurs
    # For example:
    # 
    #     Task.date = '2012-09-15'
    # 
    # This creates a real Date object in the data store.
    # 
    #     date = Task.date
    # 
    # Date is a real date object.
    def method_missing(method, *args, &block)
      if self.respond_to? method
        return method(args, &block)
      else
        raise NoMethodError.new("nil column #{method} accessed from #{caller[1]}.")
      end
    end
  end
end
