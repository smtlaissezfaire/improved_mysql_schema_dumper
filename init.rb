# Include hook code here
ActiveRecord::SchemaDumper.instance_eval do
  alias_method :__old_schema_dumper__, :dump
  
  def dump(connection, file)
    SMT::ImprovedMysqlSchemaDumper.dump(connection, "#{RAILS_ROOT}/db/development_structure.sql")
  end
  
  def load(file)
    SMT::ImprovedMysqlSchemaDumper.load("#{RAILS_ROOT}/db/development_structure.sql")
  end
end
