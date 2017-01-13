require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    if instance_variable_defined?(:@column_names)
      @column_names
    else
      column_names = DBConnection.execute2(<<-SQL)
        SELECT
          *
        FROM
          #{table_name}
      SQL
      @column_names = column_names.first.map(&:to_sym)
    end
  end

  def self.finalize!
    columns.each do |column_name|
      define_method(column_name) do
        attributes[column_name]
      end

      define_method("#{column_name}=") do |val|
        attributes[column_name] = val
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || self.to_s.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    parse_all(results)
  end

  def self.parse_all(results)
    all_objects = []
    results.each do |result|
      all_objects << self.new(result)
    end

    all_objects
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = ?
    SQL
    result.empty? ? nil : self.new(result.first)
  end

  def initialize(params = {})
    params.each do |attr_name, val|
      attr_name = attr_name.to_sym

      unless self.class.columns.include?(attr_name)
        raise "unknown attribute '#{attr_name}'"
      else
        send("#{attr_name}=", val)
      end

    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values(no_id = false)
    if no_id
      columns = self.class.columns.reject { |col| col == :id }
      columns.map { |col_name| send(col_name) }
    else
      self.class.columns.map { |col_name| send(col_name) }
    end
  end

  def insert
    col_names = self.class.columns.reject { |col| col == :id }
    num_question_marks = self.class.columns.size - 1
    question_marks = (["?"] * num_question_marks)
    values = attribute_values
    DBConnection.execute(<<-SQL, *attribute_values(true))
      INSERT INTO
        #{self.class.table_name} (#{col_names.join(", ")})
      VALUES
        (#{question_marks.join(", ")})
    SQL
    send :id=, DBConnection.last_insert_row_id
  end

  def update
    col_names = self.class.columns.reject { |col| col == :id }
    col_names.map! { |col| "#{col} = ?"}
    DBConnection.execute(<<-SQL, *attribute_values(true))
      UPDATE
        #{self.class.table_name}
      SET
        #{col_names.join(", ")}
      WHERE
        id = #{id}
    SQL

  end

  def save
    id.nil? ? insert : update
  end
end
