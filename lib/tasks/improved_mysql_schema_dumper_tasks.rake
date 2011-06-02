# Taken from migrate_test_db plugin:
Rake::TaskManager.class_eval do
  def remove_task(task_name)
    @tasks.delete(task_name.to_s)
  end
end
 
def remove_task(task_name)
  Rake.application.remove_task(task_name)
end

remove_task "db:schema:dump"
remove_task "db:schema:load"
remove_task "db:structure:dump"
remove_task "db:test:clone_structure"

namespace :db do
  namespace :schema do
    desc "Create a db/schema.rb file that can be portably used against any DB supported by AR"
    task :dump => :environment do
      require 'active_record/schema_dumper'
      file = ENV['SCHEMA'] || "db/schema.rb"
      ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
    end

    desc "Load a schema.rb file into the database"
    task :load => :environment do
      file = ENV['SCHEMA'] || "db/schema.rb"
      ActiveRecord::SchemaDumper.load(file)
    end
  end
  
  namespace :structure do
    desc "Dump the database structure to a SQL file"
    task :dump => :environment do
      abcs = ActiveRecord::Base.configurations
      case abcs[RAILS_ENV]["adapter"]
      when "mysql"
        ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, "db/#{RAILS_ENV}_structure.sql")
      when "oci", "oracle"
        ActiveRecord::Base.establish_connection(abcs[RAILS_ENV])
        File.open("db/#{RAILS_ENV}_structure.sql", "w+") { |f| f << ActiveRecord::Base.connection.structure_dump }
      when "postgresql"
        ENV['PGHOST']     = abcs[RAILS_ENV]["host"] if abcs[RAILS_ENV]["host"]
        ENV['PGPORT']     = abcs[RAILS_ENV]["port"].to_s if abcs[RAILS_ENV]["port"]
        ENV['PGPASSWORD'] = abcs[RAILS_ENV]["password"].to_s if abcs[RAILS_ENV]["password"]
        search_path = abcs[RAILS_ENV]["schema_search_path"]
        search_path = "--schema=#{search_path}" if search_path
        `pg_dump -i -U "#{abcs[RAILS_ENV]["username"]}" -s -x -O -f db/#{RAILS_ENV}_structure.sql #{search_path} #{abcs[RAILS_ENV]["database"]}`
        raise "Error dumping database" if $?.exitstatus == 1
      when "sqlite", "sqlite3"
        dbfile = abcs[RAILS_ENV]["database"] || abcs[RAILS_ENV]["dbfile"]
        `#{abcs[RAILS_ENV]["adapter"]} #{dbfile} .schema > db/#{RAILS_ENV}_structure.sql`
      when "sqlserver"
        `scptxfr /s #{abcs[RAILS_ENV]["host"]} /d #{abcs[RAILS_ENV]["database"]} /I /f db\\#{RAILS_ENV}_structure.sql /q /A /r`
        `scptxfr /s #{abcs[RAILS_ENV]["host"]} /d #{abcs[RAILS_ENV]["database"]} /I /F db\ /q /A /r`
      when "firebird"
        set_firebird_env(abcs[RAILS_ENV])
        db_string = firebird_db_string(abcs[RAILS_ENV])
        sh "isql -a #{db_string} > db/#{RAILS_ENV}_structure.sql"
      else
        raise "Task not supported by '#{abcs["test"]["adapter"]}'"
      end

      if ActiveRecord::Base.connection.supports_migrations?
        File.open("db/#{RAILS_ENV}_structure.sql", "a") { |f| f << ActiveRecord::Base.connection.dump_schema_information }
      end
    end
  end
  
  namespace :test do
    remove_task "clone_structure"
    desc "Recreate the test databases from the development structure"
    task :clone_structure => [ "db:structure:dump", "db:test:purge" ] do
      abcs = ActiveRecord::Base.configurations
      case abcs["test"]["adapter"]
      when "mysql"
        ActiveRecord::Base.establish_connection(:test)
        IO.read("db/#{RAILS_ENV}_structure.sql").split(";").each do |table|
          ActiveRecord::Base.connection.execute(table)
        end
      when "postgresql"
        ENV['PGHOST']     = abcs["test"]["host"] if abcs["test"]["host"]
        ENV['PGPORT']     = abcs["test"]["port"].to_s if abcs["test"]["port"]
        ENV['PGPASSWORD'] = abcs["test"]["password"].to_s if abcs["test"]["password"]
        `psql -U "#{abcs["test"]["username"]}" -f db/#{RAILS_ENV}_structure.sql #{abcs["test"]["database"]}`
      when "sqlite", "sqlite3"
        dbfile = abcs["test"]["database"] || abcs["test"]["dbfile"]
        `#{abcs["test"]["adapter"]} #{dbfile} < db/#{RAILS_ENV}_structure.sql`
      when "sqlserver"
        `osql -E -S #{abcs["test"]["host"]} -d #{abcs["test"]["database"]} -i db\\#{RAILS_ENV}_structure.sql`
      when "oci", "oracle"
        ActiveRecord::Base.establish_connection(:test)
        IO.readlines("db/#{RAILS_ENV}_structure.sql").join.split(";\n\n").each do |ddl|
          ActiveRecord::Base.connection.execute(ddl)
        end
      when "firebird"
        set_firebird_env(abcs["test"])
        db_string = firebird_db_string(abcs["test"])
        sh "isql -i db/#{RAILS_ENV}_structure.sql #{db_string}"
      else
        raise "Task not supported by '#{abcs["test"]["adapter"]}'"
      end
    end
  end
end
