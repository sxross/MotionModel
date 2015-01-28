module MotionModel
  class ArrayFinderQuery
    attr_accessor :field_name
    
    def initialize(*args)#nodoc
      @field_name = args[0] if args.length > 1
      @collection = args.last
    end
    
    def belongs_to(obj, klass = nil) #nodoc
      @related_object = obj
      @klass          = klass
      self
    end
    
    # Conjunction to add conditions to query.
    #
    # Task.find(:name => 'bob').and(:gender).eq('M')
    # Task.asignees.where(:assignee_name).eq('bob')
    def and(field_name)
      @field_name = field_name
      self
    end
    alias_method :where, :and
    
    # Specifies how to sort. only ascending sort is supported in the short
    # form. For descending, implement the block form.
    #
    #     Task.where(:name).eq('bob').order(:pay_grade).all  => array of bobs ascending by pay grade
    #     Task.where(:name).eq('bob').order(:pay_grade){|o1, o2| o2 <=> o1}  => array of bobs descending by pay grade
    def order(field = nil, &block)
      if block_given?
        @collection = @collection.sort{|o1, o2| yield(o1, o2)}
      else
        raise ArgumentError.new('you must supply a field name to sort unless you supply a block.') if field.nil?
        @collection = @collection.sort{|o1, o2| o1.send(field) <=> o2.send(field)}
      end
      self
    end
    
    def translate_case(item, case_sensitive)#nodoc
      item = item.downcase if case_sensitive === false && item.respond_to?(:downcase)
      item
    end
    
    def do_comparison(query_string, options = {:case_sensitive => false})#nodoc
      query_string = translate_case(query_string, options[:case_sensitive])
      @collection = @collection.collect do |item|
        comparator = item.send(@field_name.to_sym)
        comparator = translate_case(comparator, options[:case_sensitive])
        item if yield query_string, comparator
      end.compact
      self
    end
    
    # performs a "like" query.
    #
    # Task.find(:work_group).contain('dev') => ['UI dev', 'Core dev', ...]
    def contain(query_string, options = {:case_sensitive => false})
      do_comparison(query_string) do |comparator, item|
        if options[:case_sensitive]
          item =~ Regexp.new(comparator, Regexp::MULTILINE)
        else
          item =~ Regexp.new(comparator, Regexp::IGNORECASE | Regexp::MULTILINE)
        end
      end
    end
    alias_method :contains, :contain
    alias_method :like, :contain
    
    # performs a set-inclusion test.
    #
    # Task.find(:id).in([3, 5, 9])
    def in(set)
      @collection = @collection.collect do |item|
        item if set.include?(item.send(@field_name.to_sym))
      end.compact
    end
    
    # performs strict equality comparison.
    #
    # If arguments are strings, they are, by default,
    # compared case-insensitive, if case-sensitivity
    # is required, use:
    #
    # eq('something', :case_sensitive => true)
    def eq(query_string, options = {:case_sensitive => false})
      do_comparison(query_string, options) do |comparator, item|
        comparator == item
      end
    end
    alias_method :==, :eq
    alias_method :equal, :eq
    
    # performs greater-than comparison.
    #
    # see `eq` for notes on case sensitivity.
    def gt(query_string, options = {:case_sensitive => false})
      do_comparison(query_string, options) do |comparator, item|
        comparator < item
      end
    end
    alias_method :>, :gt
    alias_method :greater_than, :gt
    
    # performs less-than comparison.
    #
    # see `eq` for notes on case sensitivity.
    def lt(query_string, options = {:case_sensitive => false})
      do_comparison(query_string, options) do |comparator, item|
        comparator > item
      end
    end
    alias_method :<, :lt
    alias_method :less_than, :lt
    
    # performs greater-than-or-equal comparison.
    #
    # see `eq` for notes on case sensitivity.
    def gte(query_string, options = {:case_sensitive => false})
      do_comparison(query_string, options) do |comparator, item|
        comparator <= item
      end
    end
    alias_method :>=, :gte
    alias_method :greater_than_or_equal, :gte
    
    # performs less-than-or-equal comparison.
    #
    # see `eq` for notes on case sensitivity.
    def lte(query_string, options = {:case_sensitive => false})
      do_comparison(query_string, options) do |comparator, item|
        comparator >= item
      end
    end
    alias_method :<=, :lte
    alias_method :less_than_or_equal, :lte
    
    # performs inequality comparison.
    #
    # see `eq` for notes on case sensitivity.
    def ne(query_string, options = {:case_sensitive => false})
      do_comparison(query_string, options) do |comparator, item|
        comparator != item
      end
    end
    alias_method :!=, :ne
    alias_method :not_equal, :ne
    
    ########### accessor methods #########

    # returns first element or count elements that matches.
    def first(*args)
      to_a.send(:first, *args)
    end

    # returns last element or count elements that matches.
    def last(*args)
      to_a.send(:last, *args)
    end
    
    # returns all elements that match as an array.
    def all
      to_a
    end
    
    # returns all elements that match as an array.
    def to_a
      @collection || []
    end

    # each is a shortcut method to turn a query into an iterator. It allows
    # you to write code like:
    #
    #   Task.where(:assignee).eq('bob').each{ |assignee| do_something_with(assignee) }
    def each(&block)
      raise ArgumentError.new("each requires a block") unless block_given?
      @collection.each{|item| yield item}
    end
   
    # returns length of the result set.
    def length
      @collection.length
    end
    alias_method :count, :length
    
    ################ relation support ##############
    
    # task.assignees.create(:name => 'bob')
    # creates a new Assignee object on the Task object task
    def create(options)
      raise ArgumentError.new("Creating on a relation requires the parent be saved first.") if @related_object.nil?
      obj = new(options)
      obj.save
      obj
    end
    
    # task.assignees.new(:name => 'BoB')
    # creates a new unsaved Assignee object on the Task object task
    def new(options = {})
      raise ArgumentError.new("Creating on a relation requires the parent be saved first.") if @related_object.nil?
      
      id_field = (@related_object.class.to_s.underscore + '_id').to_sym
      new_obj = @klass.new(options.merge(id_field => @related_object.id))
      
      new_obj
    end
    
    # Returns number of objects (rows) in collection
    def length
      @collection.length
    end
    alias_method :count, :length
    
    # Pushes an object onto an association. For e.g.:
    #
    #    Task.find(3).assignees.push(assignee)
    #
    # This both establishes the relation and saves the related
    # object, so make sure the related object is valid.
    def push(object)
      id_field = (@related_object.class.to_s.underscore + '_id=').to_sym
      object.send(id_field, @related_object.id)
      result = object.save
      result ||= @related_object.save
      result
    end
    alias_method :<<, :push
  end
end
