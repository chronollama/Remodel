class Relation
  extend Searchable

  def initialize
    @queries = []
  end

  def first

  end

  def last

  end

  def to_a

  end

  def select

  end

  def group

  end

  def order

  end

  def joins

  end

  def where(params)
    conditions = params.keys.map { |col| "#{col} = ?"}
    query = DBConnection.execute(<<-SQL, *params.values)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{conditions.join(" AND ")}
    SQL
    @queries << query
    self
  end

  private

  def run_queries

  end
end
