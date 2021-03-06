if defined?(Rails)
  ActiveRecord::SchemaDumper.instance_eval do
    alias_method :__old_schema_dumper__, :dump

    def dump(connection, file)
      ImprovedMysqlSchemaDumper.dump(connection, "#{Rails.root}/db/development_structure.sql")
    end

    def load(file)
      ImprovedMysqlSchemaDumper.load("#{Rails.root}/db/development_structure.sql")
    end
  end
end

module ImprovedMysqlSchemaDumper
  MAJOR = 1
  MINOR = 0
  TINY  = 0

  VERSION = "#{MAJOR}.#{MINOR}.#{TINY}"

  class << self
    def reset_ar_base!
      @ar_base = nil
    end

    def ar_base
      @ar_base ||= ActiveRecord::Base
    end

    attr_writer :ar_base

    def configuration
      ar_base.configurations["development"]
    end

    def database_username
      configuration["username"]
    end

    def database_host
      configuration["host"]
    end

    def database_password
      configuration["password"]
    end

    def database_name
      configuration["database"]
    end

    def dump(connection, file_path)
      sh(dump_command(file_path))
    end

    def dump_command(file_path)
      password_string = password? ? "-p#{database_password}" : ""
      cmd = <<-CMD.gsub(/\s+/, " ")
      mysqldump -u #{database_username}
                -h #{database_host}
                #{password_string}
                --quote-names
                --add-drop-table
                --single-transaction
                --no-data
                #{database_name} > '#{file_path}'
      CMD
    end

    def connection
      ar_base.connection
    end

    def load(a_file)
      contents = File.read(a_file)
      contents.split(";").each do |statement|
        connection.execute(statement)
      end
    end

  private

    def password?
      database_password ? true : false
    end
  end
end
