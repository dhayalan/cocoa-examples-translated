require File.expand_path("#{File.dirname(__FILE__)}/../../sandbox")
require 'testutil'

class CheckingObjcToRubyExample < Test::Unit::TestCase

  class SomethingToObserve < OSX::NSObject
    kvc_accessor :property
  end

  class Dep < NSObject
    def observeValueForKeyPath_ofObject_change_context(a, b, c, d)
      raise 'die'
    end
  end

  def sut_observing_mock(mock)
    sut = SomethingToObserve.alloc.init
    sut.objc_send(:addObserver, mock,
                  :forKeyPath, 'property',
                  :options, NSKeyValueObservingOptionNew,
                  :context, nil)
    sut
  end

  context "a checking method call" do

    teardown do 
      @sut.removeObserver_forKeyPath(@mock, 'property')
    end

    should "fail on a flexmock whose class doesn't define the method" do
      @mock = flexmock(NSObject.alloc.init)
      @sut = sut_observing_mock(@mock)

      assert_raises(OCException) do
        @sut.property = 3
      end
    end

    should "succeed on a flexmock whose class does define the method" do
      @mock = flexmock(Dep.alloc.init)
      @sut = sut_observing_mock(@mock)
      during {
        @sut.property = 3
      }.behold! { 
        @mock.should_receive(:observeValueForKeyPath_ofObject_change_context).
              once.with_any_args
      }
    end

    should "succeed using rubycocoa_flexmock" do
      @mock = rubycocoa_flexmock
      @sut = sut_observing_mock(@mock)
      during {
        @sut.property = 3
      }.behold! { 
        @mock.should_receive(:observeValueForKeyPath_ofObject_change_context, 4).
              once.with('property', @sut, any, any)
      }
    end
  end
end
