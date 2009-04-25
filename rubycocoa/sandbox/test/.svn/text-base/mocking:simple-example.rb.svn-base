require File.expand_path("#{File.dirname(__FILE__)}/../../sandbox")
require 'testutil'

class SimpleObjcToRubyExample < Test::Unit::TestCase

  class NotifiedController < NSObject

    def awakeFromNib
      center.objc_send(:addObserver, self,
                       :selector, :notification_action,
                       :name, 'announce',
                       :object, nil)
    end

    def notification_action(notification)
      # Do some work
      raise "This method is mocked out in the test."
    end
  end

  class NotifyingController < NSObject
    def awakeFromNib
      # ...
    end

    def something_that_notifies
      center.postNotificationName_object('announce', self)
    end
  end

  context "notifications" do
    setup do
      @sut = NotifyingController.alloc.init
      @receiver = NotifiedController.alloc.init
      # ... connect outlets ...
      @receiver.awakeFromNib
      @sut.awakeFromNib
    end

    should "cause a Ruby object to be called from objective-c" do
      mock = flexmock(@receiver, 'receiver')
      during { 
        @sut.something_that_notifies
      }.behold! {
        mock.should_receive(:notification_action).
             once.with( on { | notification | 
                          notification.name == 'announce' &&
                          notification.object == @sut
                        })
      }
    end
  end
end
