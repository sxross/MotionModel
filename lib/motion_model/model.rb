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
# * :date (must be in a form that Date.parse can recognize)
# * :time (must be in a form that Time.parse can recognize)
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
  module Model
    def self.included(base)
      base.extend(ClassMethods)
      base.instance_variable_set("@column_attrs", [])
      base.instance_variable_set("@typed_attrs", [])
      base.instance_variable_set("@collection", [])
      base.instance_variable_set("@_next_id", 1)
    end
    
    module ClassMethods
      # Macro to define names and types of columns. It can be used in one of
      # two forms:
      #
      # Pass a hash, and you define columns with types. E.g.,
      #
      #   columns :name => :string, :age => :integer
      #   
      # Pass an array, and you create column names, all of which have type +:string+.
      #   
      #   columns :name, :age, :hobby
      def columns(*fields)
        return @column_attrs if fields.empty?

        case fields.first
        when Hash
          fields.first.each_pair do |attr, type|
            add_attribute(attr, type)
          end
        else
          fields.each do |attr|
            add_attribute(attr, :string)
          end
        end

        unless self.respond_to?(:id)
          add_attribute(:id, :integer)
        end
      end

      def add_attribute(attr, type) #nodoc
        attr_accessor attr
        @column_attrs << attr
        @typed_attrs  << type
      end

      def next_id #nodoc
        @_next_id
      end

      def increment_id #nodoc
        @_next_id += 1
      end

      # Returns true if a column exists on this model, otherwise false.
      def column?(column)
        @column_attrs.each{|key| 
          return true if key == column
          }
        false
      end
      
      # Returns type of this column.
      def type(column)
        index = @column_attrs.index(column)
        index ? @typed_attrs[index] : nil
      end

      # Creates an object and saves it. E.g.:
      #
      #   @bob = Person.create(:name => 'Bob', :hobby => 'Bird Watching')
      #
      # returns the object created or false.
      def create(options = {})
        row = self.new(options)
        # TODO: Check for Validatable and if it's
        # present, check valid? before saving.
        @collection.push(row)
        row
      end

      def length
        @collection.length
      end
      alias_method :count, :length

      # Empties the entire store.
      def delete_all
        @collection = [] # TODO: Handle cascading or let GC take care of it.
      end

      # Finds row(s) within the data store. E.g.,
      #
      #   @post = Post.find(1)  # find a specific row by ID
      #
      # or...
      #
      #   @posts = Post.find(:author).eq('bob').all
      def find(*args)
        unless args[0].is_a?(Symbol) || args[0].is_a?(String)
          return @collection[args[0].to_i] || nil
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
      
    end
 
    ####### Instance Methods #######
    def initialize(options = {})
      columns.each{|col| instance_variable_set("@#{col.to_s}", nil) unless options.has_key?(col)}
      
      options.each do |key, value|
        instance_variable_set("@#{key.to_s}", value || '') if self.class.column?(key.to_sym)
      end
      unless self.id
        self.id = self.class.next_id
        self.class.increment_id
      end
    end

    def length
      @collection.length
    end
    
    alias_method :count, :length
      
    def column?(target_key)
      self.class.column?(target_key)
    end

    def columns
      self.class.columns
    end

    def type(field_name)
      self.class.type(field_name)
    end

    def initWithCoder(coder)
      self.init
      self.class.instance_variable_get("@column_attrs").each do |attr|
        # If a model revision has taken place, don't try to decode
        # something that's not there.
        new_tag_id = 1
        if coder.containsValueForKey(attr.to_s)
          value = coder.decodeObjectForKey(attr.to_s)
          self.instance_variable_set('@' + attr.to_s, value || '')
        else
          self.instance_variable_set('@' + attr.to_s, '') # set to empty string if new attribute
        end

        # re-issue tags to make sure they are unique
        @tag = new_tag_id
        new_tag_id += 1
      end
      self
    end
    
    def encodeWithCoder(coder)
      self.class.instance_variable_get("@column_attrs").each do |attr|
        coder.encodeObject(self.send(attr), forKey: attr.to_s)
      end
    end
    
  end
  
  class FinderQuery
    attr_accessor :field_name
    
    def initialize(*args)
      @field_name = args[0] if args.length > 1
      @collection = args.last
    end
    
    def and(field_name)
      @field_name = field_name
      self
    end
    
    def order(field = nil, &block)
      if block_given?
        @collection = @collection.sort{|o1, o2| yield(o1, o2)}
      else
        raise ArgumentError.new('you must supply a field name to sort unless you supply a block.') if field.nil?
        @collection = @collection.sort{|o1, o2| o1.send(field) <=> o2.send(field)}
      end
      self
    end
    
    ######## relational methods ########
    def do_comparison(query_string)
      # TODO: Flag case-insensitive searching
      query_string = query_string.downcase if query_string.respond_to?(:downcase)
      @collection = @collection.select do |item|
        comparator = item.send(@field_name.to_sym)
        yield query_string, comparator
      end
      self
    end
    
    def contain(query_string)
      do_comparison(query_string) do |comparator, item|
        item =~ Regexp.new(comparator)
      end
    end
    alias_method :contains, :contain
    alias_method :like, :contain
    
    def eq(query_string)
      do_comparison(query_string) do |comparator, item|
        comparator == item
      end
    end
    alias_method :==, :eq
    alias_method :equal, :eq
    
    def gt(query_string)
      do_comparison(query_string) do |comparator, item|
        comparator > item
      end
    end
    alias_method :>, :gt
    alias_method :greater_than, :gt
    
    def lt(query_string)
      do_comparison(query_string) do |comparator, item|
        comparator < item
      end
    end
    alias_method :<, :lt
    alias_method :less_than, :lt
    
    def gte(query_string)
      do_comparison(query_string) do |comparator, item|
        comparator >= item
      end
    end
    alias_method :>=, :gte
    alias_method :greater_than_or_equal, :gte
    
    
    def lte(query_string)
      do_comparison(query_string) do |comparator, item|
        comparator <= item
      end
    end
    alias_method :<=, :lte
    alias_method :less_than_or_equal, :lte
    
    def ne(query_string)
      do_comparison(query_string) do |comparator, item|
        comparator != item
      end
    end
    alias_method :!=, :ne
    alias_method :not_equal, :ne
    
    ########### accessor methods #########
    def first
      @collection.first
    end
    
    def last
      @collection.last
    end
    
    def all
      @collection
    end
    
    # each is a shortcut method to turn a query into an iterator. It allows
    # you to write code like:
    #
    #   Task.where(:assignee).eq('bob').each{ |assignee| do_something_with(assignee) }
    def each(&block)
      raise ArgumentError.new("each requires a block") unless block_given?
      @collection.each{|item| yield item}
    end
  end
end

