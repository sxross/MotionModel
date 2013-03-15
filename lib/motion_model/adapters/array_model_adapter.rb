module MotionModel
  module ArrayModelAdapter
    def adapter
      'Array Model Adapter'
    end

    def self.included(base)
      base.extend(PrivateClassMethods)
      base.extend(PublicClassMethods)
      base.instance_variable_set("@collection", [])             # Actual data
    end

    module PublicClassMethods

      def collection
        @collection ||= []
      end

      def insert(object)
        collection << object
      end

      def length
        collection.length
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
          collection.each{|item| item.delete}
        end
        @collection = []
        @_next_id = 1
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
          matches = collection.collect do |item|
            item if yield(item)
          end.compact
          return ArrayFinderQuery.new(matches)
        end

        unless args[0].is_a?(Symbol) || args[0].is_a?(String)
          target_id = args[0].to_i
          return collection.select{|element| element.id == target_id}.first
        end

        ArrayFinderQuery.new(args[0].to_sym, @collection)
      end
      alias_method :where, :find

      # Returns query result as an array
      def all
        collection
      end

      def order(field_name = nil, &block)
        ArrayFinderQuery.new(@collection).order(field_name, &block)
      end

    end

    module PrivateClassMethods

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

    end

    def before_initialize(options)
      assign_id(options)
    end

    # Undelete does pretty much as its name implies. However,
    # the natural sort order is not preserved. IMPORTANT: If
    # you are trying to undo a cascading delete, this will not
    # work. It only undeletes the object you still own.

    def undelete
      collection << self
      self.class.issue_notification(self, :action => 'add')
    end

    # This adds to the ArrayStore without the magic date
    # and id manipulation stuff
    def add_to_store(*)
      do_insert
      @dirty = @new_record = false
    end



    # Count of objects in the current collection
    def length
      collection.length
    end
    alias_method :count, :length

    private

    def assign_id(options) #nodoc
      unless options[:id]
        options[:id] = self.class.next_id
      else
        self.class.next_id = [options[:id].to_i, self.class.next_id].max
      end
      self.class.increment_id
    end

    def collection #nodoc
      self.class.instance_variable_get('@collection')
    end

    def do_insert
      collection << self
    end

    def do_update
    end

    def do_delete
      target_index = collection.index{|item| item.id == self.id}
      collection.delete_at(target_index) unless target_index.nil?
      self.class.issue_notification(self, :action => 'delete')
    end

  end
end
