module MotionModel
  class Relation

    def initialize(instance, column_name, associated_class, scope)
      @instance = instance
      @column_name = column_name
      @associated_class = associated_class
      @scope = scope
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

    def build(attrs = {})
      inst = @associated_class.new(attrs)
      #foreign_key = instance.class.foreign_key(@associated_class)
      #inst.send("#{foreign_key.to_s}=",
      collection << inst
      inst
    end

    def <<(instance)
      collection << instance
    end

  end
end
