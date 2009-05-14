require 'osx/cocoa'
include OSX

require 'ApplicationSupport'

class DragAppAppDelegate
  def applicationSupportFolder
    ApplicationSupport.new('DragApp').pathname
  end
end
