require File.expand_path("#{File.dirname(__FILE__)}/path-setting")
require 'ApplicationSupport'
require 'Oopsies'
require 'test/notification-utils'

class ApplicationSupportTest < Test::Unit::TestCase
  include OSX
  
  def setup
    @file_manager = rubycocoa_flexmock("file manager")
    @low_level_fileops = rubycocoa_flexmock("low level file operations")
    @test_options = {
      :file_manager => @file_manager,
      :low_level_fileops => @low_level_fileops
    }

    @low_level_fileops.should_receive('NSSearchPathForDirectoriesInDomains', 3).
                       and_return(['/userhome/appsupport'].to_ns).
                       by_default
    @file_manager.should_receive(:fileExistsAtPath, 1).
                  and_return(true).
                  by_default
  end

  context "initialization" do


    should "ask Cocoa to give the user domain's application support" do
      during { 
        ApplicationSupport.new("irrelevant", @test_options).pathname
      }.behold! {
        @low_level_fileops.should_receive('NSSearchPathForDirectoriesInDomains', 3).once.
                           with(NSApplicationSupportDirectory, NSUserDomainMask, any).
                           and_return(['/userhome/appsupport'].to_ns)
      }
    end


    should "return a result without tildes" do
      during { 
        ApplicationSupport.new("irrelevant", @test_options).pathname
      }.behold! {
        @low_level_fileops.should_receive('NSSearchPathForDirectoriesInDomains', 3).once.
                           with(any, any, true).
                           and_return(['/userhome/appsupport'].to_ns)
      }
    end

    should "add the application name to the the application support directory" do
      as = ApplicationSupport.new("AppName", @test_options)
      assert { as.pathname == "/userhome/appsupport/AppName" }
    end

    should "also be able to return a URL." do
      as = ApplicationSupport.new("AppName", @test_options)
      # Equality is pointer-equality for NSURLs.
      assert { as.url.absoluteString ==
               NSURL.fileURLWithPath("/userhome/appsupport/AppName").absoluteString }
    end

    should "create the application's directory if needed" do
      during {
        ApplicationSupport.new("AppName", @test_options).pathname
      }.behold! {
        @file_manager.should_receive(:fileExistsAtPath, 1).once.
                      with("/userhome/appsupport/AppName").
                      and_return(false)
        @file_manager.should_receive(:createDirectoryAtPath_withIntermediateDirectories_attributes_error, 3).once.
                      with(any, any, any).
                      and_return([true])
                  
      }
    end

    should "notify someone who cares if directory cannot be created" do
      inject_watchers_for(Oopsy::Could_not_create_application_directory)
      during {
        ApplicationSupport.new("AppName", @test_options).pathname
      }.behold! {
        @file_manager.should_receive(:fileExistsAtPath, 1).once.
                      with("/userhome/appsupport/AppName").
                      and_return(false)
        @file_manager.should_receive(:createDirectoryAtPath_withIntermediateDirectories_attributes_error, 3).once.
                      with(any, any, any).
                      and_return([false, :an_NSError])
        watchers_are_notified.once.with(this_notification(Oopsy::Could_not_create_application_directory,
                                                          any,
                                                          { :error => :an_NSError }))
      }
    end

  end

  context "file operations" do
    should "tell that a file exists" do
      during { 
        @result = ApplicationSupport.new("ThisApp", @test_options).contains_file?("there.xml")
      }.behold! {
        @file_manager.should_receive(:fileExistsAtPath, 1).once.
                      with("/userhome/appsupport/ThisApp/there.xml").
                      and_return(true)
      }
      assert { @result == true }
    end

    should "convert a file name to a URL" do
      result = ApplicationSupport.new("ThisApp", @test_options).file_url("there.xml")
      # Equality is pointer-equality for NSURLs.
      assert { result.absoluteString ==
               NSURL.fileURLWithPath("/userhome/appsupport/ThisApp/there.xml").absoluteString }
    end

    should "convert file name even if file does not exist." do
      during { 
        @result = ApplicationSupport.new("ThisApp", @test_options).file_url("notthere.xml")
      }.behold! {
        @file_manager.should_receive(:fileExistsAtPath, 1).
                      with("/userhome/appsupport/ThisApp/notthere.xml").never
      }
      assert { @result.absoluteString ==
               NSURL.fileURLWithPath("/userhome/appsupport/ThisApp/notthere.xml").absoluteString }
    end
  end
end
