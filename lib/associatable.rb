require_relative 'searchable'
require 'active_support/inflector'

class AssocOptions
  attr_accessor :foreign_key, :class_name, :primary_key, :through, :source

  def model_class
    class_name.to_s.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsOptions < AssocOptions
  def initialize(name, options = {})
    defaults = {
      class_name: name.to_s.camelize,
      primary_key: :id,
      foreign_key: "#{name}_id".to_sym
    }
    options = defaults.merge(options)
    self.class_name = options[:class_name]
    self.primary_key = options[:primary_key]
    self.foreign_key = options[:foreign_key]
  end
end

class HasOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    defaults = {
      class_name: name.to_s.singularize.camelize,
      primary_key: :id,
      foreign_key: "#{self_class_name.to_s.underscore}_id".to_sym,
      through: nil,
      source: nil
    }
    options = defaults.merge(options)
    self.class_name = options[:class_name]
    self.primary_key = options[:primary_key]
    self.foreign_key = options[:foreign_key]
    self.through = options[:through]
    self.source = options[:source]
  end
end

module Associatable
  def assoc_options
    @assoc_options ||= {}
  end

  def belongs_to(name, params = {})
    options = BelongsOptions.new(name, params)
    define_method(name) do
      key_reference = self.send(options.foreign_key)
      options.model_class.where(options.primary_key => key_reference).first
    end
  end

  def has_many(name, params = {})
    options = HasOptions.new(name, self, params)
    assoc_options[name] = options
    define_method(name) do
      if options.through
        has_many_through(name, options.through, options.source)
      else
        key_reference = self.send(options.primary_key)
        options.model_class.where(options.foreign_key => key_reference)
      end
    end
  end

  def has_one(name, params = {})
    options = HasOptions.new(name, self, params)
    assoc_options[name] = options
    define_method(name) do
      if options.through
        has_one_through(name, options.through, options.source)
      else
        key_reference = self.send(options.primary_key)
        options.model_class.where(options.foreign_key => key_reference).first
      end
    end
  end

  def has_one_through(name, through_name, source_name)
    define_method(name) do
      params = deconstruct_options(through_name, source_name)
      query = DBConnection.execute(<<-SQL, params[join_owner_pk_value])
        SELECT
          #{params[source_table]}.*
        FROM
          #{params[source_table]}
        JOIN
          #{params[join_table]}
          ON #{params[source_join_pk]} = #{params[source_join_fk]}
        WHERE
          #{params[join_owner_fk]} = ?
      SQL
      query.empty? ? nil : source_options.model_class.new(query.first)
    end
  end

  private

  def deconstruct_options(through_name, source_name)
    sql_params = {}
    through_options = self.class.assoc_options[through_name]
    source_options = through_options.model_class.assoc_options[source_name]

    sql_params[join_table] = through_options.table_name
    sql_params[source_table] = source_options.table_name
    sql_params[join_owner_pk_value] = self.send(through_options.primary_key)
    sql_params[join_owner_fk] = "#{join_table}.#{through_options.foreign_key}"
    sql_params[source_join_pk] = "#{join_table}.#{source_options.primary_key}"
    sql_params[source_join_fk] = "#{source_table}.#{source_options.foreign_key}"

    sql_params
  end
end

class SQLObject
  extend Associatable
end
