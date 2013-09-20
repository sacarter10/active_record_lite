require_relative './associatable'
require_relative './db_connection'
require_relative './mass_object'
require_relative './searchable'

class SQLObject < MassObject
  extend Searchable
  extend Associatable

  def self.set_table_name(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name
  end

  def self.all
    row_hashes = DBConnection.execute("SELECT * FROM #{table_name}")

    parse_all(row_hashes)
  end

  def self.find(id)
    match = DBConnection.execute("SELECT * FROM #{table_name} WHERE id = ?", id)

    return match.nil? ? "No matches found" : self.new(match.first)
  end

  def save
    if self.id.nil?
      create
    else
      update
    end
  end

  private
  def attribute_values
    self.class.attributes.map {|attr_name| self.send(attr_name.to_s)}
  end

  def create
    attr_names = self.class.attributes.join(", ")
    question_marks = (Array.new(self.class.attributes.length) {"?"}).join(", ")

    attr_values = attribute_values

    DBConnection.execute(<<-SQL, *attr_values)
      INSERT INTO #{self.class.table_name} (#{attr_names})
      VALUES (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    set_line = self.class.attributes.map {|attr_name| "#{attr_name} = ?"}
    set_line = set_line.join(", ") #don't try to set ID

    attr_values = attribute_values

    DBConnection.execute(<<-SQL, *attr_values)
    UPDATE #{self.class.table_name}
    SET #{set_line}
    WHERE id = #{self.id}
    SQL
  end

end
