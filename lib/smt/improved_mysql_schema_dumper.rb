module SMT
  module ImprovedMysqlSchemaDumper
    def dump(connection, file_handle)
      file_path = file_handle.path
      cmd = <<-CMD.strip
      mysqldump -u #{database_username} 
                -h #{database_host} 
                -p#{database_password} 
                --quote-names  
                --add-drop-table 
                --single-transaction
                #{database_name} > #{file_path})
      CMD
      
      sh(cmd)
    end
  end
end
