require File.expand_path("#{File.dirname(__FILE__)}/path-setting")
require 'ApplicationSupport'

class ApplicationSupportTest < Test::Unit::TestCase
  include OSX
  
  context "initialization" do

    should "blah" do
      ApplicationSupport.alloc.initForApp("ThisOne")
      assert { false }
    end
  end
end
