module MotionModel
  module ArrayModelAdapter
    class PersistFileError < Exception; end
    class VersionNumberError < ArgumentError; end

    module PublicClassMethods

      def validate_schema_version(version_number)
        raise MotionModel::ArrayModelAdapter::VersionNumberError.new('version number must be a string') unless version_number.is_a?(String)
        if version_number !~ /^[\d.]+$/
          raise MotionModel::ArrayModelAdapter::VersionNumberError.new('version number string must contain only numbers and periods')
        end
      end

      # Declare a version number for this schema. For example:
      #
      # class Task
      #   include MotionModel::Model
      #   include MotionModel::ArrayModelAdapter
      #
      #   version_number 1.0.1
      # end
      #
      # When a version number mismatch occurs as an individual row is loaded
      # from persistent storage, the migrate method is invoked, allowing
      # you to programmatically migrate on a per-row basis.

      def schema_version(*version_number)
        if version_number.empty?
          return @schema_version
        else
          validate_schema_version(version_number[0])
          @schema_version = version_number[0]
        end
      end

      def migrate
      end


      # Returns the unarchived object if successful, otherwise false
      #
      # Note that subsequent calls to serialize/deserialize methods
      # will remember the file name, so they may omit that argument.
      #
      # Raises a +MotionModel::PersistFileFailureError+ on failure.
      def deserialize_from_file(file_name = nil, directory = nil)
        if schema_version != '1.0.0'
          migrate
        end

        @file_name = file_name if file_name
        @file_path =
          if directory.nil?
            documents_file(@file_name)
          else
            File.join(directory, @file_name)
          end
            

        if File.exist? @file_path
          error_ptr = Pointer.new(:object)

          data = NSData.dataWithContentsOfFile(@file_path, options:NSDataReadingMappedIfSafe, error:error_ptr)

          if data.nil?
            error = error_ptr[0]
            raise MotionModel::PersistFileError.new "Error when reading the data: #{error}"
          else
            bulk_update do
              NSKeyedUnarchiver.unarchiveObjectWithData(data)
            end
            return self
          end
        else
          return false
        end
      end
      # Serializes data to a persistent store (file, in this
      # terminology). Serialization is synchronous, so this
      # will pause your run loop until complete.
      #
      # +file_name+ is the name of the persistent store you
      # want to use. If you omit this, it will use the last
      # remembered file name.
      #
      # Raises a +MotionModel::PersistFileError+ on failure.
      def serialize_to_file(file_name = nil)
        @file_name = file_name if file_name
        error_ptr = Pointer.new(:object)

        data = NSKeyedArchiver.archivedDataWithRootObject collection
        unless data.writeToFile(documents_file(@file_name), options: NSDataWritingAtomic, error: error_ptr)
          # De-reference the pointer.
          error = error_ptr[0]

          # Now we can use the `error' object.
          raise MotionModel::PersistFileError.new "Error when writing data: #{error}"
        end
      end


      def documents_file(file_name)
        file_path = File.join NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true), file_name
        file_path
      end
    end

    def initWithCoder(coder)
      self.init

      new_tag_id = 1
      columns.each do |attr|
        next if has_relation?(attr)
        # If a model revision has taken place, don't try to decode
        # something that's not there.
        if coder.containsValueForKey(attr.to_s)
          value = coder.decodeObjectForKey(attr.to_s)
          self.send("#{attr}=", value)
        else
          self.send("#{attr}=", nil)
        end

        # re-issue tags to make sure they are unique
        @tag = new_tag_id
        new_tag_id += 1
      end
      add_to_store

      self
    end

    # Follow Apple's recommendation not to encode missing
    # values.
    def encodeWithCoder(coder)
      columns.each do |attr|
        # Serialize attributes except the proxy has_many and belongs_to ones.
        unless [:belongs_to, :has_many, :has_one].include? column(attr).type
          value = self.send(attr)
          unless value.nil?
            coder.encodeObject(value, forKey: attr.to_s)
          end
        end
      end
    end

  end
end
