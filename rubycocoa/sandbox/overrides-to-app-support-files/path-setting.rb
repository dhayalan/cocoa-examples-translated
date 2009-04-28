require 'osx/cocoa'

module RubyCocoaLocations
  def self.the_apps_ruby_source_may_not_be_in_the_usual_location
    $:.delete(RubyCocoaLocations.resource_path)
    $:.delete('.')
  end
  
  def self.do_not_use_site_specific_libs_and_gems
    require 'rbconfig'
    $:.delete_if { | p | p =~ Regexp.new(RbConfig::CONFIG['sitedir']) }
    ENV['RUBYLIB'].split(':').each do | path |
      $:.delete(path)
    end if ENV.has_key?('RUBYLIB')
  end

  def self.put_apps_third_party_libs_and_gems_in_load_path
    $: << app_root + "/third-party/lib"
    RbConfig::CONFIG['sitelibdir'] = $:.last   # Rubygems uses this
    unless require 'rubygems'
      Gem::ConfigMap[:sitelibdir] = $:.last
    end
    Gem.clear_paths
    ENV['GEM_HOME'] = app_root + "/third-party/gems"
  end

  def self.put_apps_ruby_source_in_load_path
    $:.unshift(root_for_ruby_files)
  end

  def self.load_ruby_files
    rbfiles = Dir.chdir(root_for_ruby_files) { Dir["*.rb"] }
    rbfiles.delete_if { | name | File.basename(name) == 'rb_main.rb' }
    rbfiles.delete_if { | name | File.basename(name) == 'path-setting.rb' }
    rbfiles.each { |file| require(file) }
    begin
      require 'load-subdirs.rb'   # Order of subdirs is typically important.
    rescue Exception
      # There might be no subdirs.
    end
  end

  def self.root_for_ruby_files
    if debug_build?
      File.expand_path(resource_path + "/../../../../..")
    elsif release_build?
      resource_path
    else # test
      dir_containing("rb_main.rb")
    end
  end

  def self.app_root
    root_for_ruby_files
  end


# Util

  def self.debug_build?
    resource_path =~ %r{/build/Debug/\w+.app/}
  end

  def self.release_build?
    resource_path =~ %r{/build/Release/\w+.app/}
  end

  def self.resource_path
    OSX::NSBundle.mainBundle.resourcePath.fileSystemRepresentation
  end

  def self.dir_in_which(start=Dir.getwd, &block)
    return File.expand_path(start) if block.call(start)
    dir_in_which(File.join(start, '..'), &block)
  end

  def self.dir_containing(file_basename)
    dir_in_which { | dirname | 
      File.exist?(File.join(dirname, file_basename)) 
    }
  end


end
