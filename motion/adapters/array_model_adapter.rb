module MotionModel
  module ArrayModelAdapter
    def adapter
      'Array Model Adapter'
    end

    def self.included(base)
      base.extend(PrivateClassMethods)
      base.extend(PublicClassMethods)
      base.instance_eval do
        _reset_next_id
      end
    end

    module PublicClassMethods
       def collection
        @collection ||= []
      end

      def insert(object)
        collection << object
      end
      alias :<< :insert

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
        bulk_update { collection.pop.delete until collection.empty? }
        _reset_next_id
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

        ArrayFinderQuery.new(args[0].to_sym, collection)
      end
      alias_method :where, :find

      def find_by_id(id)
        find(:id).eq(id).first
      end

      # Returns query result as an array
      def all
        collection.dup
      end

      def order(field_name = nil, &block)
        ArrayFinderQuery.new(collection).order(field_name, &block)
      end

    end

    module PrivateClassMethods
      private

      # Returns next available id
      def _next_id #nodoc
        @_next_id
      end

      def _reset_next_id
        @_next_id = 1
      end

      # Increments next available id
      def increment_next_id(other_id) #nodoc
        @_next_id = [@_next_id, other_id.to_i].max + 1
      end

    end

    def before_initialize(options)
      assign_id(options)
    end

    def increment_next_id(other_id)
      self.class.send(:increment_next_id, other_id)
    end

    # Undelete does pretty much as its name implies. However,
    # the natural sort order is not preserved. IMPORTANT: If
    # you are trying to undo a cascading delete, this will not
    # work. It only undeletes the object you still own.

    def undelete
      collection << self
      issue_notification(:action => 'add')
    end

    def collection #nodoc
      self.class.collection
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

    def _next_id
      self.class.send(:_next_id)
    end

    def assign_id(options) #nodoc
      options[:id] ||= _next_id
      increment_next_id(options[:id])
    end

    def belongs_to_relation(col) # nodoc
      col.classify.find(_get_attr(col.foreign_key))
    end

    def has_many_relation(col) # nodoc
      _has_many_has_one_relation(col)
    end

    def has_one_relation(col) # nodoc
      _has_many_has_one_relation(col)
    end

    def _has_many_has_one_relation(col) # nodoc
      related_klass = col.classify
      related_klass.find(col.inverse_column.foreign_key).belongs_to(self, related_klass).eq(_get_attr(:id))
    end

    def do_insert(options = {})
      collection << self
    end

    def do_update(options = {})
      self
    end

    def do_delete
      target_index = collection.index{|item| item.id == self.id}
      collection.delete_at(target_index) unless target_index.nil?
      issue_notification(:action => 'delete')
    end

  end
end
