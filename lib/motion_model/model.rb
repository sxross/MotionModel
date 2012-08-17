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

      def add_attribute(attr, type)
        attr_accessor attr
        @column_attrs << attr
        @typed_attrs  << type
      end

      def next_id
        @_next_id
      end

      def increment_id
        @_next_id += 1
      end

      def column?(target_key)
        @column_attrs.each{|key| 
          return true if key == target_key
          }
        false
      end

      def type(field_name)
        index = @column_attrs.index(field_name)
        index ? @typed_attrs[index] : nil
      end

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

      def delete_all
        @collection = [] # TODO: Handle cascading or let GC take care of it.
      end

      def find(id)
        return @collection[id] || nil
      end
    end
 
    
    def initialize(options = {})
      options.each do |key, value|
        instance_variable_set("@#{key.to_s}", value || '') if self.class.column?(key.to_sym)
      end
      unless self.id
        self.id = self.class.next_id
        self.class.increment_id
      end
    end

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
end

