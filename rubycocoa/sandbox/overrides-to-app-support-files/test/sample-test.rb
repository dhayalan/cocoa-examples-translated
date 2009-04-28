require File.expand_path("#{File.dirname(__FILE__)}/path-setting")

class AppChoiceControllerTest < Test::Unit::TestCase
  include OSX
  
  context "initialization" do

    should "do something in the top-level directory" do
      puts "Top level sample test is running"
      assert { 1 == 1 }
    end
  end
end
