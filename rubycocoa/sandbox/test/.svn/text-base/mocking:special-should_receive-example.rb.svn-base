require File.expand_path("#{File.dirname(__FILE__)}/../../sandbox")
require 'testutil'

class RubyCocoaFlexmockExample < Test::Unit::TestCase

  # If the Cocoa code requires a method to be defined but it's not 
  # used, it has to be declared with the special form of 
  # 'should_receive'.
  context "a combo box" do

    setup do
      @sut = NSComboBox.alloc.init
      @mock = rubycocoa_flexmock
      @mock.should_receive(:comboBox_objectValueForItemAtIndex, 2).
            zero_or_more_times.by_default
    end

    should "ask twice for number of items upon initialization" do
      during {
        @sut.usesDataSource = true
        @sut.setDataSource(@mock)
      }.behold! {
        @mock.should_receive(:numberOfItemsInComboBox, 0).twice
      }
    end
  end
end
