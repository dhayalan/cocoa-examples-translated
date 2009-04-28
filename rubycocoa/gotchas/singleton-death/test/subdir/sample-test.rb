require File.expand_path("#{File.dirname(__FILE__)}/../path-setting")

class AppChoiceControllerTest < Test::Unit::TestCase
  include OSX
  
  context "initialization" do

    should "do something in a lower-level directory" do
      puts "Subdir sample test is running"
      assert { 1 == 1 }
    end
  end
end
