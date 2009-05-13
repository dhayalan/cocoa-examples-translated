
require File.expand_path("#{File.dirname(__FILE__)}/../../sandbox/overrides-to-app-support-files/path-setting")


RubyCocoaLocations.do_not_use_site_specific_libs_and_gems

Gem.use_paths(nil, Gem.path + [File.join(RubyCocoaLocations.sandbox_root, 'gems')])
$: << File.join(RubyCocoaLocations.sandbox_root, 'lib')
$: << '.'

def sut_root
  File.join(RubyCocoaLocations.dir_containing('app-utilities'), 'app-utilities/lib')
end

$: << sut_root

require 'test/unit'
require 'Shoulda'
require 'assert2'

require 'flexmock/test_unit'
require 'test/mock-talk'

# puts '=== path-setting'
# puts $:
