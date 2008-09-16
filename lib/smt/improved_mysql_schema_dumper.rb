module SMT
  module ImprovedMysqlSchemaDumper
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
      
      def dump(connection, file_handle)
        file_path = file_handle.path
        sh(dump_command(file_path))
      end
      
      def dump_command(file_path)
        cmd = <<-CMD.gsub(/\n|\s\s+/, "")
        mysqldump -u #{database_username}
                  -h #{database_host}
                  -p#{database_password}
                  --quote-names
                  --add-drop-table
                  --single-transaction
                  #{database_name} > #{file_path}
        CMD
      end
      
    end
  end
end
