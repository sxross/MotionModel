module MotionModel
  module Validatable
    def self.included(base)
      base.extend(ClassMethods)
      base.instance_variable_set('@validations', [])
    end

    module ClassMethods
      def validate(field = nil, validation_type = {})
        if field.nil? || field.to_s == ''
          ex = ValidationSpecificationError.new('field not present in validation call')
          raise ex
        end
    
        if validation_type == {} # || !(validation_type is_a?(Hash))
          ex = ValidationSpecificationError.new('validation type not present or not a hash')
          raise ex
        end
    
        @validations << {field => validation_type}
      end      
    end
  
    def valid?
      @messages = []
      @valid = true
      self.class.instance_variable_get(@validations).each do |validations|
        validate_each(validations)
      end
      @valid
    end

    def validate_each(validations)
      validations.each_pair do |field, validation|
        validate_one field, validation
      end
    end
  
    def validate_one(field, validation)
      validation.each_pair do |validation_type, setting|
        case validation_type
        when :presence
          @valid &&= validate_presence(field)
          if setting
            additional_message = "non-empty"
          else
            additional_message = "empty"
          end
          @valid = !@valid if setting == false
          @messages << {field => "incorrect value supplied for #{field.to_s} -- should be #{additional_message}"}
        else
          @valid = false
          ex = ValidationSpecificationError.new("unknown validation type :#{validation_type.to_s}")
        end
      end
    end
  
    def validate_presence(field)
      value = self.send(field.to_s)
      return false if value.nil?
      return value.strip.length > 0
    end
  end
end
