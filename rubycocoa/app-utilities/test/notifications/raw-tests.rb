require File.expand_path("#{File.dirname(__FILE__)}/../path-setting")
require "#{File.dirname(__FILE__)}/testutil"

class RawNotificationTests < Test::Unit::TestCase

  def setup
    super
    @observed = NSObject.alloc.init
    @watcher = flexmock(SomeRandomWatcher.alloc.init)
  end

  should "observe a name/object combination" do
    center = NSNotificationCenter.defaultCenter
    center.addObserver_selector_name_object(@watcher,
                 :posted, "name", @observed)
    during {
      center.postNotificationName_object_userInfo(
                   "name", @observed, :key => :value)
      center.postNotificationName_object_userInfo(
                   "name", :a_random_object, :key => :value)
      center.postNotificationName_object_userInfo(
                   "WRONG_NAME", @observed, :key => :value)
    }.behold! {
      @watcher.should_receive(:posted).
               once.with(this_notification("name", @observed, :key => :value))
    }
  end
end

