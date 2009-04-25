# Complicated rigamarole to get sandbox contents into the path.
# You can load app files with (for example)
#    require 'preferences/PreferencesController'
# So File.expand_path('..') is in the path.
#
# The sandbox library (File.expand_path('../../sandbox/lib') is in the path.
#

require File.expand_path("#{File.dirname(__FILE__)}/../path-setting")

def RubyCocoaLocations.root_for_ruby_files   # overriding version from above.
  RubyCocoaLocations.dir_containing('rb_main.rb')
end
RubyCocoaLocations.set_hierarchical_app_load_paths

def RubyCocoaLocations.sandbox_root
  File.join(RubyCocoaLocations.dir_containing('sandbox.rb'), 'sandbox')
end


Gem.use_paths(nil, Gem.path + [File.join(RubyCocoaLocations.sandbox_root, 'gems')])
$: << File.join(RubyCocoaLocations.sandbox_root, 'lib')
$: << RubyCocoaLocations.root_for_ruby_files   # To load files like 'test/util'
$: << '.'

require 'test/unit'
require 'Shoulda'
RubyCocoaLocations.load_ruby_files

require 'flexmock/test_unit'
require 'test/mock-talk'

# puts '=== path-setting'
# puts $:
