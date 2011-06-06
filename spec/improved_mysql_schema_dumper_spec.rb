require "spec_helper"

module SMT
  describe ImprovedMysqlSchemaDumper do
    it "should have dump as a singleton method" do
      ImprovedMysqlSchemaDumper.should respond_to(:dump)
    end

    describe "ar_base" do
      before :each do
        ImprovedMysqlSchemaDumper.reset_ar_base!
      end

      it "should be ActiveRecord::Base by default" do
        ImprovedMysqlSchemaDumper.ar_base.should == ActiveRecord::Base
      end

      it "should allow setting to a mock" do
        a_mock = mock 'a mock ar::base class'
        ImprovedMysqlSchemaDumper.ar_base = a_mock
        ImprovedMysqlSchemaDumper.ar_base.should == a_mock
      end
    end

    describe "configuration" do
      before :each do
        @ar_base = mock('ar base', {
          :configurations => {
           "development" => {
             "encoding"=>"utf8",
             "username"=>"root",
             "adapter"=>"mysql",
             "host"=>"localhost",
             "password"=>nil,
             "database"=>"development"
           }
        }})
        ImprovedMysqlSchemaDumper.ar_base = @ar_base
      end

      it "should be the configuration in dev mode" do
        ImprovedMysqlSchemaDumper.configuration.should == @ar_base.configurations["development"]
      end

      it "should have the username" do
        ImprovedMysqlSchemaDumper.database_username.should == "root"
      end

      it "should have the database host" do
        ImprovedMysqlSchemaDumper.database_host.should == "localhost"
      end

      it "should have the database password" do
        ImprovedMysqlSchemaDumper.database_password.should be_nil
      end

      it "should have the database name" do
        ImprovedMysqlSchemaDumper.database_name.should == "development"
      end
    end

    describe "dump command" do
      before :each do
        @file_path = "/foo/bar"
        @ar_base = mock('ar base').as_null_object
        ImprovedMysqlSchemaDumper.ar_base = @ar_base
      end

      it "should contain the host" do
        ImprovedMysqlSchemaDumper.stub!(:database_host).and_return "localhost"
        ImprovedMysqlSchemaDumper.dump_command(@file_path).should include("-h localhost")
      end

      it "should not contain any newlines" do
        ImprovedMysqlSchemaDumper.dump_command(@file_path).should_not include("\n")
      end

      it "should not contain extra spaces" do
        ImprovedMysqlSchemaDumper.dump_command(@file_path).should_not include("  ")
      end

      it "should quote the filename" do
        ImprovedMysqlSchemaDumper.dump_command(@file_path).should include("> '#{@file_path}'")
      end

      it "should include mysqldump -u root -h localhost" do
        configuration = {
          "username" => "root",
          "host" => "localhost"
        }
        @ar_base.stub!(:configurations).and_return({ "development" => configuration })
        ImprovedMysqlSchemaDumper.dump_command(@file_path).should include("mysqldump -u root -h localhost")
      end

      it "should include the password, if there is one" do
        configuration = {
          "username" => "root",
          "host" => "localhost",
          "password" => "foo"
        }
        @ar_base.stub!(:configurations).and_return({ "development" => configuration })
        ImprovedMysqlSchemaDumper.dump_command(@file_path).should include("-pfoo")
      end


      it "should not include the password if there isn't one" do
        configuration = {
          "username" => "root",
          "host" => "localhost"
        }
        @ar_base.stub!(:configurations).and_return({ "development" => configuration })
        ImprovedMysqlSchemaDumper.dump_command(@file_path).should_not include("-p")
      end

      it "should not dump data" do
        ImprovedMysqlSchemaDumper.dump_command(@file_path).should include("--no-data")
      end
    end
  end

  describe "load" do
    before :each do
      @ar_base_connection = mock 'ar base connection', :execute => nil
      @ar_base = mock 'ar base', :connection => @ar_base_connection
      ImprovedMysqlSchemaDumper.ar_base = @ar_base

      @a_file = mock 'a file'
      File.stub!(:read).and_return "a string"
    end

    it "should have the AR BASE connection" do
      ImprovedMysqlSchemaDumper.connection.should == @ar_base_connection
    end

    it "should open the file" do
      File.should_receive(:read).with(@a_file).and_return "some string"
      ImprovedMysqlSchemaDumper.load(@a_file)
    end

    it "should execute a single string" do
      File.stub!(:read).and_return "a string"
      @ar_base_connection.should_receive(:execute).with('a string')
      ImprovedMysqlSchemaDumper.load(@a_file)
    end

    it "should execute a string spanning multiple lines" do
      File.stub!(:read).and_return "foo\nbar\nbaz"
      @ar_base_connection.should_receive(:execute).with("foo\nbar\nbaz")
      ImprovedMysqlSchemaDumper.load(@a_file)
    end

    it "should execute multiple statements, split by semi-colons" do
      File.stub!(:read).and_return "foo;\nbar;"
      @ar_base_connection.should_receive(:execute).with("foo")
      @ar_base_connection.should_receive(:execute).with("\nbar")
      ImprovedMysqlSchemaDumper.load(@a_file)
    end
  end
end
