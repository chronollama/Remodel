class Relation
  extend Searchable

  def where(params)
    conditions = params.keys.map { |col| "#{col} = ?" }
    query = <<-SQL
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{conditions.join(" AND ")}
    SQL
    self.queries << query
    self.params << params
    self
  end
end
