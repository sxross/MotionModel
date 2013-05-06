module MotionModel

  class AbstractRelation
    attr_reader :associated_class

    def initialize(owner, column, associated_class, scope)
      @owner = owner
      @column = column
      @associated_class = associated_class
      @scope = scope
      @loaded = owner.new_record?
    end
    private :initialize # This is an abstract class

    def loaded?
      !!@loaded
    end

    def scoped
      @_scope ||= @scope.is_a?(Proc) ? @scope.call : @scope
    end

    def column_name
      @column.name
    end

    def keys_for_to_s
      keys = [:column_name, :loaded?]
      keys << :count if loaded?
      keys += self.instance_variables
      keys
    end

    def unload
      @_scope = nil
      @loaded = false
    end

    private

    def maybe_reload
      reload unless loaded?
    end

    # Build an instance of a :has_many association, the other side of which is a :belongs_to,
    # and add it to the collection
    def build_from_instance(associated_instance)
      if @column.polymorphic
        associated_instance.set_polymorphic_attr(@column.as, @owner)
      else
        # Note: Don't trigger reverse association assignment
        associated_instance.set_belongs_to_attr(@column.inverse_column, @owner)
      end
      associated_instance
    end

    def set_inverse_association(instance)
      inverse_column = instance.column(@column.inverse_name)
      inverse_column ||= instance.column(@column.inverse_name.to_s.pluralize.to_sym)

      case inverse_column.type
      when :belongs_to
        if inverse_column.polymorphic
          instance.set_polymorphic_attr(inverse_column, @owner)
        else
          instance.set_belongs_to_attr(inverse_column, @owner, set_inverse: false)
        end
      when :has_one
        instance.set_has_one_attr(inverse_column, @owner)
      when :has_many
        instance.push_has_many_attr(inverse_column, @owner)
      end
    end

  end

  class CollectionRelation < AbstractRelation

    class RelationArray < ::Array

      def self.build(relation, arr = [])
        # Note: new is glitchy, reports can't convert {type} into Integer (TypeError)
        alloc.init.addObjectsFromArray(arr).instance_eval do
          @relation = relation
          self
        end
      end
      #private :new # Use .build instead

      # RubyMotion bombs when trying to override push
      private :push # This method should be avoided because it can't be overridden
      def push_instance(instance, &after_init)
        @relation.push(instance, &after_init)
      end
      alias :<< :push_instance

      # Push the instance to the collection directly, not via the relation
      def collection_push(instance)
        send(:push, instance)
      end

      def build(attrs = {})
        @relation.build(attrs)
      end

    end

    def initialize(owner, column, associated_class, scope, collection = nil)
      super(owner, column, associated_class, scope)
      if collection
        @loaded = true
        @collection = RelationArray.build(self, collection)
      else
        @loaded = false
        @collection = RelationArray.build(self)
      end
    end

    def build(attrs = {})
      instance = build_from_instance(@associated_class.new(attrs))
      push(instance)
      instance
    end

    def to_a
      collection
    end

    def count
      collection.count
    end

    def first
      to_a.first
    end

    def each(*args, &block)
      collection.each(*args, &block)
    end

    # Return only the loaded associates, if any
    def loaded
      @loaded ? @collection : []
    end

    def push(*args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      args.each do |instance|
        set_inverse_association(instance) unless options[:set_inverse] == false
        collection.collection_push(instance) unless collection.include?(instance)
        @owner.reload_through_relations(@column)
      end
      self
    end

    def delete(instance)
      collection.delete(instance)
    end

    def reject!(&block)
      @collection = collection.reject(&block)
    end

    def unload
      current = to_a
      super
      @collection = RelationArray.build(self)
      current
    end

    def reload
      @collection = nil
      if @column.through
        relation = @owner.send(:relation, @column.through)
        if relation.loaded?
          column_name = relation.associated_class.foreign_association(associated_class)
          @collection = relation.to_a.map { |o| o.send(column_name) }
        end
      end
      @collection ||= RelationArray.build(self, scoped.to_a)
      @loaded = true
      @collection
    end

    private

    def collection
      maybe_reload
      @collection
    end

    def set_collection(collection, options = {})
      collection.map do |instance|
        set_inverse_association(instance)
      end unless options[:set_inverse] == false
      @loaded = true
      @collection = RelationArray.build(self, collection)
    end
    alias_method :'collection=', :set_collection

  end

  class InstanceRelation < AbstractRelation

    def initialize(owner, column, associated_class, scope, instance = nil)
      super(owner, column, associated_class, scope)
      @instance = instance
      @loaded = true if instance
    end

    # TODO dynamically define i.e. rails: comment.build_post(attrs)
    def build(attrs = {})
      @instance = build_from_instance(@associated_class.new(attrs))
    end

    def instance
      maybe_reload
      @instance
    end

    def set_instance(instance, options = {})
      @instance = instance
      set_inverse_association(instance) unless options[:set_inverse] == false
      @owner.reload_through_relations(@column)
      @loaded = true
    end
    alias_method :'instance=', :set_instance

    # Return only the loaded associate, if present
    def loaded
      @loaded ? @instance : nil
    end

    def unload
      super
      @instance = nil
    end

    def reload
      @instance = nil
      if @column.through
        relation = @owner.send(:relation, @column.through)
        if relation.loaded?
          column_name = relation.associated_class.foreign_association(associated_class)
          @instance = relation.send(column_name)
        end
      end
      @instance ||= scoped.first
      @loaded = true
      @instance
    end

  end

end
