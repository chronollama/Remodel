class Validator
  attr_accessor :presence, :uniqueness
end

class ValidatorDefaults < Validator
  def initialize(options = {})
    defaults = {
      presence: false,
      uniqueness: false
    }

    options = defaults.merge(options)
    self.presence = options[:presence]
    self.uniqueness = options[:uniqueness]
    self.numericality = options[:numericality]
    self.integer_only = options[:integer_only]
  end
end
