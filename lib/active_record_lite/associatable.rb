require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'
require 'active_support/inflector'

class AssocParams
  def other_class
    @other_class_name.constantize
  end

  def other_table
    other_class.table_name
  end
end

class BelongsToAssocParams < AssocParams
  attr_reader :primary_key, :foreign_key, :other_table_name

  def initialize(name, params)
    @primary_key = params[:primary_key] || :id

    @foreign_key = params[:foreign_key] || "#{name.to_s}_id".to_sym

    @other_class_name = params[:class_name] || name.to_s.camelize
  end

  def type
  end
end

class HasManyAssocParams < AssocParams
  attr_reader :primary_key, :foreign_key

  def initialize(name, params, self_class)
    @primary_key = params[:primary_key] || :id
    @foreign_key = params[:foreign_key] || "#{self_class.underscore}_id"

    @other_class_name = params[:class_name] || name.to_s.singularize.camelize
  end

  def type
  end
end

module Associatable
  def assoc_params
    @assoc_params ||= {}
  end

  def belongs_to(name, params = {})
    assoc_params[name] = BelongsToAssocParams.new(name, params)

    define_method(name) do
      aps = self.class.assoc_params[name]

      fk_attrib = self.send(aps.foreign_key)

      owner = DBConnection.execute(<<-SQL, fk_attrib)
      SELECT *
      FROM #{aps.other_table}
      WHERE #{aps.other_table}.#{aps.primary_key} = ?
      SQL

      aps.other_class.parse_all(owner)
    end
  end

  def has_many(name, params = {})
    define_method(name) do
      aps = HasManyAssocParams.new(name, params, self.class)

      pk_attrib = self.send(aps.primary_key)

      possessions = DBConnection.execute(<<-SQL, pk_attrib)
      SELECT *
      FROM #{aps.other_table}
      WHERE #{aps.other_table}.#{aps.foreign_key} = ?
      SQL

      aps.other_class.parse_all(possessions)
    end
  end

  def has_one_through(name, assoc1, assoc2) #name, through, source
    define_method(name) do
      step1 = self.class.assoc_params[assoc1]
      step2 = step1.other_class.assoc_params[assoc2]

      fk_attrib = self.send(step1.foreign_key)

      owner = DBConnection.execute(<<-SQL, fk_attrib)
      SELECT #{step2.other_table}.*
      FROM #{step2.other_table}
      INNER JOIN #{step1.other_table}
      ON #{step2.other_table}.#{step2.primary_key} =             #{step1.other_table}.#{step1.primary_key}
      WHERE #{step1.other_table}.#{step1.primary_key} = ?
      SQL

      step2.other_class.parse_all(owner)
    end
  end
end
