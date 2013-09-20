require_relative './db_connection'

module Searchable
  def where(params = {})
    where_line = params.keys.map { |attr_name| "#{attr_name} = ?"}.join(" AND ")
    attr_values = params.values

    matches = DBConnection.execute(<<-SQL, *attr_values)
    SELECT *
    FROM "#{self.table_name}"
    WHERE #{where_line}
    SQL

    parse_all(matches)
  end
end