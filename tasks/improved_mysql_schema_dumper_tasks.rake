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
end
