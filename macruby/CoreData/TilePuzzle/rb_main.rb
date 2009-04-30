#
#  rb_main.rb
#  Fenestra
#
#  Created by Brian Marick on 5/10/08.
#  Copyright (c) 2008 Exampler Consulting. All rights reserved.
#

framework 'Cocoa'

def rb_main_init
  path = NSBundle.mainBundle.resourcePath.fileSystemRepresentation
  rbfiles = Dir.entries(path).select {|x| /\.rb\z/ =~ x}
  rbfiles -= [ File.basename(__FILE__) ]
  rbfiles.each do |path|
    require( File.basename(path) )
  end
end

if $0 == __FILE__ then
  rb_main_init
  OSX.NSApplicationMain(0, nil)
end
