class ApplicationSupport

  def initForApp(appname)
    init
    @appname = appname
    @fileManager = NSFileManager.defaultManager
    force_application_support_folder
    self
  end

  def folder_name
    return @folder_name if @folder_name

    paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, true)
    @folder_name = paths[0].stringByAppendingPathComponent(@appname)
  end

  def force_application_support_folder
    unless @fileManager.fileExistsAtPath(folder_name)
      @fileManager.createDirectoryAtPath folder_name, attributes: nil
    end
  end

  def file_exists?(filename)
    @fileManager.fileExistsAtPath(file_path(filename))
  end

  def file_path(filename)
    folder_name.stringByAppendingPathComponent(filename)
  end

  def file_url(filename)
    NSURL.fileURLWithPath(file_path(filename))
  end
end
