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
      if @column.options[:polymorphic]
        associated_instance.send("#{@column.options[:as]}_type=", @owner.class.name)
        associated_instance.send("#{@column.options[:as]}_id=", @owner.id)
      else
        # Note: Don't trigger reverse association assignment
        associated_instance.send("set_#{@owner.class.name.underscore}", @owner)
      end
      associated_instance
    end

    def init_associate(instance, &after_init)
      if @column.options[:polymorphic]
        raise 'Polymorphic associate must be of associated class' unless instance.class == @associated_class
        instance.send("#{@column.options[:as]}_type=", @owner.class.name)
        instance.send("#{@column.options[:as]}_id=", @owner.id)
      elsif @column.options[:through]
        fail 'Unsupported'
        # Not sure this ever needs to be supported... should maybe not initialize associates
        #  via a 'through' association
      else
        foreign_key = instance.class.foreign_key(@owner.class)
        instance.send("#{foreign_key}=", @owner.id)
      end
      instance.instance_eval(&after_init) if block_given?
      instance
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
      _c = collection
      #collection.send(:push, build_from_instance(@associated_class.new(attrs)))
      instance = build_from_instance(@associated_class.new(attrs))
      _c.send(:push, instance)
      instance
    end

    # Return only the loaded associates, if any
    def loaded
      @loaded ? @collection : []
    end

    def push(*instances)
      instances.each do |instance|
        associate = init_associate(instance)
        collection.send(:push, associate) unless collection.include?(associate)
      end
      self
    end

    def reject!(&block)
      @collection = collection.reject(&block)
    end

    def unload
      super
      @collection = RelationArray.build(self)
    end

    private

    def collection
      maybe_reload
      @collection
    end

    def collection=(collection)
      _collection = collection.map do |instance|
        init_associate(instance)
      end
      @loaded = true
      @collection = RelationArray.build(self, _collection)
    end

    def reload
      @collection = RelationArray.build(self, scoped.to_a)
      @loaded = true
      @collection
    end

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

    # Return only the loaded associate, if present
    def loaded
      @loaded ? @instance : nil
    end

    def unload
      super
      @instance = nil
    end

    private

    def instance=(instance)
      @loaded = true
      @instance = init_associate(instance)
    end

    def reload
      if @column.options[:through]
        association = @owner.send(@column.options[:through])
        if association.loaded?
          column_name = association.associated_class.foreign_association(associated_class)
          @instance = association.send(column_name)
        else
          @instance = scoped.first
        end
      else
        @instance= scoped.first
      end
      @loaded = true
      @instance
    end

  end

end
