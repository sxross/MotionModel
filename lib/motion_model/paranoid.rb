module MotionModel
  module Paranoid
    # it doesn't save the record if validations fail.
    def save
      if valid? or @skip
        super
      else
        return false
      end
    end

    # it allows to skip validations
    def save!
      @skip = true
      save
    end
  end
end