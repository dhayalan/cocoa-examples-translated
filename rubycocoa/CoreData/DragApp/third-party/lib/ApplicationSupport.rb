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

  private

  def discover_pathname(app_name)
    paths = @low_level_fileops.NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
                                                                   NSUserDomainMask, true)
    paths[0].stringByAppendingPathComponent(app_name)
  end

  def force_directory_to_exist(name)
    unless @file_manager.fileExistsAtPath(name)
      @file_manager.createDirectoryAtPath_attributes(name, nil)
    end
  end
end
