require 'osx/cocoa'

class ApplicationSupport
  include OSX

  attr_reader :pathname

  def initialize(app_name, options = {})
    @file_manager = options[:file_manager] || NSFileManager.defaultManager
    @low_level_fileops = options[:low_level_fileops] || OSX

    @pathname = discover_pathname(app_name)
    force_directory_to_exist(@pathname)
  end

  def url
    NSURL.fileURLWithPath(pathname)
  end

  def contains_file?(name)
    @file_manager.fileExistsAtPath(file_path(name))
  end

  def file_url(name)
    NSURL.fileURLWithPath(file_path(name))
  end

  private

  def discover_pathname(app_name)
    paths = @low_level_fileops.NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
                                                                   NSUserDomainMask, true)
    paths[0].stringByAppendingPathComponent(app_name)
  end

  def force_directory_to_exist(name)
    return if @file_manager.fileExistsAtPath(name)
    result, error = @file_manager.createDirectoryAtPath_withIntermediateDirectories_attributes_error(name, true, nil)
    unless result
      outbox = NotificationOutBox.new(:local, :sender => self)
      outbox.post(Oopsy::Could_not_create_application_directory,
                  :error => error)
                          
    end
  end

  def file_path(name)
    pathname.stringByAppendingPathComponent(name)
  end
end
