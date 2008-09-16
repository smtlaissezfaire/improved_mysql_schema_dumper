require File.dirname(__FILE__) + "/../spec_helper"

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
        @ar_base = mock('ar base', { :configurations => {
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
  end
end
