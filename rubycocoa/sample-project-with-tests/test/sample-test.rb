require File.expand_path("#{File.dirname(__FILE__)}/path-setting")
require File.dirname(__FILE__) + "/testutil"

class AppChoiceControllerTest < Test::Unit::TestCase
  include OSX
  
  context "initialization" do

    should "do something" do
      assert { 1 == 1 }
    end
  end
end
