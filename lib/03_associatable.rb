require_relative '02_searchable'
require 'active_support/inflector'
require 'byebug'
# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.to_s.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    name = name.to_s
    name_id = "#{name}_id"
    defaults = {
      class_name: name.camelize,
      primary_key: :id,
      foreign_key: name_id.to_sym
    }

    options = defaults.merge(options)
    self.class_name = options[:class_name]
    self.primary_key = options[:primary_key]
    self.foreign_key = options[:foreign_key]
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    name = name.to_s
    defaults = {
      class_name: name.singularize.camelize,
      primary_key: :id,
      foreign_key: "#{self_class_name.to_s.underscore}_id".to_sym
    }
    options = defaults.merge(options)
    self.class_name = options[:class_name]
    self.primary_key = options[:primary_key]
    self.foreign_key = options[:foreign_key]
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, params = {})
    options = BelongsToOptions.new(name, params)
    assoc_options[name] = options

    define_method(name) do
      foreign = self.send(options.foreign_key)
      options.model_class.where(options.primary_key => foreign).first
    end
  end

  def has_many(name, params = {})
    options = HasManyOptions.new(name, self, params)
    define_method(name) do
      primary = self.send(options.primary_key)
      options.model_class.where(options.foreign_key => primary)
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
