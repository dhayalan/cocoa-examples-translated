require File.expand_path("#{File.dirname(__FILE__)}/../path-setting")
require "#{File.dirname(__FILE__)}/testutil"
require 'Notifiable'

module PatchTests

  class Super < Object
  end

  class Sub < Super
  end

  class ClassPatchesTests < Test::Unit::TestCase
    should "reveal the entire class hierarchy" do
      assert_equal([Object], Object.hierarchy_including_self)
      assert_equal([Sub, Super, Object],
                   Sub.hierarchy_including_self)
    end

    should "filter the hierarchy with a block" do
      assert_equal([Super],
                   Sub.hierarchy_including_if { | c | c == Super })
    end
  end

end
