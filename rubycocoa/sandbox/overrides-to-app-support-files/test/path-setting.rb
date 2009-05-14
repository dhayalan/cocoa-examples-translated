require File.expand_path("#{File.dirname(__FILE__)}/../path-setting")


RubyCocoaLocations.the_apps_ruby_source_may_not_be_in_the_usual_location
RubyCocoaLocations.do_not_use_site_specific_libs_and_gems
RubyCocoaLocations.put_apps_third_party_libs_and_gems_in_load_path
RubyCocoaLocations.put_apps_ruby_source_in_load_path

Gem.use_paths(nil, Gem.path + [File.join(RubyCocoaLocations.sandbox_root, 'gems')])
$: << File.join(RubyCocoaLocations.sandbox_root, 'lib')
$: << RubyCocoaLocations.root_for_ruby_files   # To load files like 'test/util'
$: << '.'

require 'test/unit'
require 'Shoulda'
require 'assert2'
RubyCocoaLocations.load_ruby_files

require 'flexmock/test_unit'
require 'test/mock-talk'

# puts '=== path-setting'
# puts $:
