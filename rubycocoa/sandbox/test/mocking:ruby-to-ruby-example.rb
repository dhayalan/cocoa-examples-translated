require File.expand_path("#{File.dirname(__FILE__)}/../../sandbox")
require 'testutil'

class RubyToRubyExample < Test::Unit::TestCase

  class R2RControllerUnderTest < NSObject
    ib_outlet :button

    def awakeFromNib
      # ...
    end

    ib_action :do_something_changing_button do | ignored_sender | 
      # ... work ...
      first_try = key_event(NSControlKeyMask, 'a')
      unless @button.performKeyEquivalent(first_try)
        second_try = key_event(NSCommandKeyMask, 'a')
        @button.performKeyEquivalent(second_try)
      end
      # ... more work ...
    end

  end

  context "action that coincidentally changes a button" do
    setup do
      @sut = R2RControllerUnderTest.alloc.init
      @sut.button = @button = flexmock('button')
      @sut.awakeFromNib
    end

    should "send only one key event if the first one fails" do
      during { 
        @sut.do_something_changing_button(nil)
      }.behold! {
        @button.should_receive(:performKeyEquivalent).
                once.with(NSEvent).and_return(true)
      }
    end


    should "send two key events if the first one fails" do
      during { 
        @sut.do_something_changing_button(nil)
      }.behold! {
        @button.should_receive(:performKeyEquivalent).
                ordered.once.with(any).and_return(false)
        @button.should_receive(:performKeyEquivalent).
                ordered.once.with(NSEvent)
      }
    end

    should "send control-a the first time and command-a the second" do
      during {
        @sut.do_something_changing_button(nil)
      }.behold! {
        @button.should_receive(:performKeyEquivalent).
                ordered.once.with(on { | event | control_a(event) } ).
                and_return(false)
        @button.should_receive(:performKeyEquivalent).
                ordered.once.with(on { | event | command_a(event) } ).
                and_return(false)
      }
    end
  end

end
