module MotionModel
  class Relation

    def initialize(owner, type, associated_class, scope, options = {})
      @owner = owner
      @type = type
      @associated_class = associated_class
      @scope = scope
      @options = options
    end

    def scoped
      @scope.is_a?(Proc) ? @scope.call : @scope
    end

    def to_a
      return @collection if @collection
      reload.to_a
    end

    def each(*args, &block)
      to_a.each(*args, &block)
    end

    def reload
      @collection = scoped.to_a
      self
    end

    def collection
      @collection ||= []
    end

    def collection=(collection)
      if @options[:polymorphic]
        @collection = collection.map do |instance|
          init_instance(instance)
        end
      else
        raise 'Unsupported'
      end
    end

    def instance
      @instance
    end

    def instance=(instance)
      @instance = init_instance(instance)
    end

    def init_instance(instance)
      if @options[:polymorphic]
        instance = instance.class == @associated_class ? instance : build_from_instance(instance)
        instance.send("#{@options[:as]}_type=", @owner.class.name)
        instance.send("#{@options[:as]}_id=", @owner.id)
        instance
      else
        raise 'Unsupported'
      end
    end

    def build(attrs = {})
      build_from_instance(@associated_class.new(attrs))
    end

    def build_from_instance(associated_instance)
      raise 'Unsupported' unless @type == :has_many
      if @options[:polymorphic]
        associated_instance.send("#{@options[:as]}_type=", @owner.class.name)
        associated_instance.send("#{@options[:as]}_id=", @owner.id)
      else
        associated_instance.send("#{@owner.class.name.underscore}=", @owner)
      end
      collection << associated_instance
      associated_instance
    end

    def <<(instance)
      collection << instance
    end

  end
end
