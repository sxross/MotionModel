module MotionModel
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
    def do_comparison(query_string, options = {:case_sensitive => false})
      query_string = query_string.downcase if query_string.respond_to?(:downcase) && !options[:case_sensitive]
      @collection = @collection.select do |item|
        comparator = item.send(@field_name.to_sym)
        yield query_string, comparator
      end
      self
    end
    
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
    
    def eq(query_string, options = {:case_sensitive => false})
      do_comparison(query_string, options) do |comparator, item|
        comparator == item
      end
    end
    alias_method :==, :eq
    alias_method :equal, :eq
    
    def gt(query_string, options = {:case_sensitive => false})
      do_comparison(query_string, options) do |comparator, item|
        comparator > item
      end
    end
    alias_method :>, :gt
    alias_method :greater_than, :gt
    
    def lt(query_string, options = {:case_sensitive => false})
      do_comparison(query_string, options) do |comparator, item|
        comparator < item
      end
    end
    alias_method :<, :lt
    alias_method :less_than, :lt
    
    def gte(query_string, options = {:case_sensitive => false})
      do_comparison(query_string, options) do |comparator, item|
        comparator >= item
      end
    end
    alias_method :>=, :gte
    alias_method :greater_than_or_equal, :gte
    
    
    def lte(query_string, options = {:case_sensitive => false})
      do_comparison(query_string, options) do |comparator, item|
        comparator <= item
      end
    end
    alias_method :<=, :lte
    alias_method :less_than_or_equal, :lte
    
    def ne(query_string, options = {:case_sensitive => false})
      do_comparison(query_string, options) do |comparator, item|
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
    
    def length
      @collection.length
    end
    alias_method :count, :length
  end
end