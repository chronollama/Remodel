require_relative 'db_connection'
require_relative 'sql_object'

module Searchable
  def where(params)
    conditions = params.keys.map { |col| "#{col} = ?" }
    results = DBConnection.execute(<<-SQL, *params.values)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{conditions.join(" AND ")}
    SQL
    results.map { |result| self.new(result) }
  end
end

class SQLObject
  extend Searchable
end
