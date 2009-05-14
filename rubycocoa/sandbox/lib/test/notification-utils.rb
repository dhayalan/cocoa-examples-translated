require 'NotificationBox'

# Use this class when creating a mock that's to receive a notification.
# I don't know why you can't use NSObject, but you can't -- the notification
# will not be received.
class SomeRandomWatcher < OSX::NSObject
end

class Test::Unit::TestCase

  def inject_watchers_for(name)
    @watcher = flexmock(SomeRandomWatcher.alloc.init)
    @watcher_inbox = NotificationInBox.new(:local,
                                           :observer => @watcher)
    @watcher_inbox.observe(:name => name,
                           :selector => :notification_watcher_selector_that_should_have_been_called)
  end
  alias_method :including_random_watchers_for, :inject_watchers_for

  def inject_announcers
    @outbox = NotificationOutBox.new(:local)
  end
  alias_method :including_random_announcers, :inject_announcers


  def no_more_watchers
    @watcher_inbox.stop_observing if @watcher_inbox
  end

  def watchers_are_notified
    @watcher.should_receive(:notification_watcher_selector_that_should_have_been_called, 0)
  end

  def some_object_announces(*args)
    @outbox.post(*args)
  end

  # Use these in _with_ expectations.
  def notification_name(name)
    on { | notification | 
      notification.name == name
    }
  end

  def this_notification(name, object = nil, userInfo = nil)
    on { | notification |
      object = notification.object if object == any
      notification.name == name && 
      notification.object == object && 
      notification.userInfo == userInfo.to_ns
    }
  end

  def userinfo(expected)
    on { | notification |
      if notification.userInfo == expected.to_ns
        true
      else
        puts "actual: #{notification.userInfo.inspect}"
        puts "expected: #{expected.to_ns.inspect}"
        false
      end
    }
  end

end
