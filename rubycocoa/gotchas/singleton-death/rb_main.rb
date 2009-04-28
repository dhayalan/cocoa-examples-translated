# This version of rb_main.rb is derived from the one Xcode provides,
# but it allows third-party libraries and gems within the app
# bundle. It also prevents libraries and gems that are not in the app
# bundle from being required (except for the ones Apple provides to
# everyone).
#
# Created by Brian Marick (marick@exampler.com) on 5/10/08.

require 'osx/cocoa'
require 'path-setting'

if $0 == __FILE__ then
  OSX::NSLog "RubyCocoa version is #{OSX::RUBYCOCOA_VERSION}."
  RubyCocoaLocations.do_not_use_site_specific_libs_and_gems
  RubyCocoaLocations.put_apps_third_party_libs_and_gems_in_load_path
  RubyCocoaLocations.put_apps_ruby_source_in_load_path
  RubyCocoaLocations.load_ruby_files
  OSX.NSApplicationMain(0, nil)
end
