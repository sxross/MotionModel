module MotionModel

  class MotionModel::RecordInvalid < RuntimeError; end
  
  module Paranoid


    # It doesn't save when validations fails
    def save(options={ :validate => true})
      (valid? || !options[:validate]) ? super : false
    end

    # it fails loudly
    def save!
      raise MotionModel::RecordInvalid unless valid?
      save
    end

  end
end