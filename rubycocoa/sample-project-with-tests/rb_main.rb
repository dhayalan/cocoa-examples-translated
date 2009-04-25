#
#  rb_main.rb
#  Fenestra
#
#  Created by Brian Marick on 5/10/08.
#  Copyright (c) 2008 Exampler Consulting. All rights reserved.
#

require 'osx/cocoa'
require 'path-setting'

def rb_main_init
  path = OSX::NSBundle.mainBundle.resourcePath.fileSystemRepresentation
  rbfiles = Dir.entries(path).select {|x| /\.rb\z/ =~ x}
  rbfiles -= [ File.basename(__FILE__) ]
  rbfiles.each do |path|
    require( File.basename(path) )
  end
end

if $0 == __FILE__ then
  OSX::NSLog "RubyCocoa version is #{OSX::RUBYCOCOA_VERSION}."
  RubyCocoaLocations.restrict_load_path_to_OSX_defaults
  RubyCocoaLocations.make_chosen_libs_and_gems_available
  rb_main_init
  OSX.NSApplicationMain(0, nil)
end
