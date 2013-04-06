module MotionModel
  module Validatable
    class ValidationSpecificationError < RuntimeError;  end
    class RecordInvalid < RuntimeError; end

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def validate(field = nil, validation_type = {})
        if field.nil? || field.to_s == ''
          ex = ValidationSpecificationError.new('field not present in validation call')
          raise ex
        end

        if validation_type == {}
          ex = ValidationSpecificationError.new('validation type not present or not a hash')
          raise ex
        end
    
        validations << {field => validation_type}
      end
      alias_method :validates, :validate

      def validations
        @validations ||= []
      end
    end

    def do_save?(options = {})
      _valid = true
      if options[:validate] != false
        call_hooks 'validation' do
          _valid = valid?
        end
      end
      _valid
    end
    private :do_save?

    def do_insert(options = {})
      return false unless do_save?(options)
      super
    end

    def do_update(options = {})
      return false unless do_save?(options)
      super
    end

    # it fails loudly
    def save!
      raise RecordInvalid.new('failed validation') unless valid?
      save
    end

    # This has two functions:
    # 
    # * First, it triggers validations.
    #
    # * Second, it returns the result of performing the validations.
    def valid?
      call_hooks 'validation' do
        @messages = []
        @valid = true
        self.class.validations.each do |validations|
          validate_each(validations)
        end
      end
      @valid
    end

    # Raw array of hashes of error messages.
    def error_messages
      @messages
    end

    # Array of messages for a given field. Results are always an array
    # because a field can fail multiple validations.
    def error_messages_for(field)
      key = field.to_sym
      error_messages.select{|message| message.has_key?(key)}.map{|message| message[key]}
    end

    def validate_each(validations) #nodoc
      validations.each_pair do |field, validation|
        @valid &&= validate_one field, validation
      end
    end

    def validation_method(validation_type) #nodoc
      validation_method = "validate_#{validation_type}".to_sym
    end

    def each_validation_for(field) #nodoc
      self.class.validations.select{|validation| validation.has_key?(field)}.each do |validation|
        validation.each_pair do |field, validation_hash|
          yield validation_hash
        end
      end
    end

    # Validates an arbitrary string against a specific field's validators.
    # Useful before setting the value of a model's field. I.e., you get data
    # from a form, do a <tt>validate_for(:my_field, that_data)</tt> and
    # if it succeeds, you do <tt>obj.my_field = that_data</tt>.
    def validate_for(field, value)
      @messages = []
      key = field.to_sym
      result = true
      each_validation_for(key) do |validation|
        validation.each_pair do |validation_type, setting|
          method = validation_method(validation_type)
          if self.respond_to? method
            value.strip! if value.is_a?(String)
            result &&= self.send(method, field, value, setting)
          end
        end
      end
      result
    end
  
    def validate_one(field, validation) #nodoc
      result = true
      validation.each_pair do |validation_type, setting|
        if self.respond_to? validation_method(validation_type)
          value = self.send(field)
          result &&= self.send(validation_method(validation_type), field, value.is_a?(String) ? value.strip : value, setting)
        else
          ex = ValidationSpecificationError.new("unknown validation type :#{validation_type.to_s}")
        end
      end
      result
    end

    # Validates that something has been endntered in a field.
    # Should catch Fixnums, Bignums and Floats. Nils and Strings should
    # be handled as well, Arrays, Hashes and other datatypes will not.
    def validate_presence(field, value, setting)
      if(value.is_a?(Numeric)) 
        return true
      elsif value.is_a?(String) || value.nil?
        result = value.nil? || ((value.length == 0) == setting)
        additional_message = setting ? "non-empty" : "non-empty"
        add_message(field, "incorrect value supplied for #{field.to_s} -- should be #{additional_message}.") if result
        return !result
      end
      return false
    end

    # Validates that the length is in a given range of characters. E.g.,
    #
    #     validate :name,   :length => 5..8
    def validate_length(field, value, setting)
      if value.is_a?(String) || value.nil?
        result = value.nil? || (value.length < setting.first || value.length > setting.last)
        add_message(field, "incorrect value supplied for #{field.to_s} -- should be between #{setting.first} and #{setting.last} characters long.") if result
        return !result
      end
      return false
    end

    def validate_email(field, value, setting)
      if value.is_a?(String) || value.nil?
        result = value.nil? || value.match(/\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i).nil?
        add_message(field, "#{field.to_s} does not appear to be an email address.") if result
      end
      return !result
    end

    # Validates contents of field against a given Regexp. This can be tricky because you need
    # to anchor both sides in most cases using \A and \Z to get a reliable match.
    def validate_format(field, value, setting)
      result = value.nil? || setting.match(value).nil?
      add_message(field, "#{field.to_s} does not appear to be in the proper format.") if result
      return !result
    end

    # Add a message for <tt>field</tt> to the messages collection.
    def add_message(field, message)
      @messages.push({field.to_sym => message})
    end
  end
end
