require "rubygems"
require "active_record"

module SMT
  dir = "#{File.dirname(__FILE__)}/smt"
  autoload :ImprovedMysqlSchemaDumper, "#{dir}/improved_mysql_schema_dumper"
end
