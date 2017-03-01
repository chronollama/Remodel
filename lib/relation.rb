class Relation
  extend Searchable

  def initialize
    @queries = []
    @params = []
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

  private

  def run_queries
    
  end
end
