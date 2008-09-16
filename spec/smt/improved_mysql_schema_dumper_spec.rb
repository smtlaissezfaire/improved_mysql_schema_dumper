require File.dirname(__FILE__) + "/../spec_helper"

module SMT
  describe ImprovedMysqlSchemaDumper do
    it "should have dump as a singleton method" do
      ImprovedMysqlSchemaDumper.should respond_to(:dump)
    end
  end
end
