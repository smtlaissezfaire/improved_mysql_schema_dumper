# Include hook code here
ActiveRecord::SchemaDumper.instance_eval do
  alias_method :__old_schema_dumper__, :dump
  
  def dump(connection, file)
    SMT::ImprovedMysqlSchemaDumper.dump(connection, "#{RAILS_ROOT}/config/development_structure.sql")
  end
end
