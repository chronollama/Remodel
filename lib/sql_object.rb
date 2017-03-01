require_relative 'db_connection'
require 'active_support/inflector'

class SQLObject
  def initialize(params = {})
    params.each do |attr_name, val|
      attr_name = attr_name.to_sym
      if self.class.columns.include?(attr_name)
        send("#{attr_name}=", val)
      else
        raise "unknown attribute '#{attr_name}'"
      end
    end
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    results.map { |result| self.new(result) }
  end

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

  def self.finalize
    columns.each do |column_name|
      define_method(column_name) do
        attributes[column_name]
      end

      define_method("#{column_name}=") do |val|
        attributes[column_name] = val
      end
    end
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = #{id}
    SQL
    result.empty? ? nil : self.new(result.first)
  end

  def insert
    col_names = self.class.columns.reject { |col| col == :id }
    question_marks = (["?"] * (self.class.columns.size - 1))
    DBConnection.execute(<<-SQL, *attribute_values(false))
      INSERT INTO
        #{self.class.table_name} (#{col_names.join(', ')})
      VALUES
        (#{question_marks.join(', ')})
    SQL
    send :id=, DBConnection.last_insert_row_id
  end

  def save
    id.nil? ? insert : update
  end

  def self.table_name
    @table_name || self.to_s.tableize
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def update
    col_names = self.class.columns.reject { |col| col == :id }
    col_names.map! { |col| "#{col} = ?" }
    DBConnection.execute(<<-SQL, *attribute_values(false))
      UPDATE
        #{self.class.table_name}
      SET
        #{col_names.join(', ')}
      WHERE
        id = #{id}
    SQL
  end

  private

  def attributes
    @attributes ||= {}
  end

  def attribute_values(with_id = true)
    if with_id
      self.class.columns.map { |col_name| send(col_name) }
    else
      columns = self.class.columns.reject { |col| col == :id }
      columns.map { |col_name| send(col_name) }
    end
  end
end
