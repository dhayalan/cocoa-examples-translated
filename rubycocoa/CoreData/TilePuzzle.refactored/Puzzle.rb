require 'constants'

class Puzzle < OSX::NSObject
  include OSX

  def init
    super_init
    puts "init puzzle"
    self
  end

  def managedObjectModel
    return @managedObjectModel if @managedObjectModel
    
    allBundles = NSMutableSet.alloc.init
    allBundles.addObject(NSBundle.mainBundle)
    allBundles.addObjectsFromArray(NSBundle.allFrameworks)

    @managedObjectModel = NSManagedObjectModel.mergedModelFromBundles(allBundles.allObjects)
    @managedObjectModel
  end

  def applicationSupportFolder
    paths = OSX.NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, true)
    paths[0].stringByAppendingPathComponent("TilePuzzle")
  end

  def managedObjectContext
    return @managedObjectContext if @managedObjectContext

    fileManager = NSFileManager.defaultManager
    unless fileManager.fileExistsAtPath(applicationSupportFolder)
      fileManager.objc_send(:createDirectoryAtPath, applicationSupportFolder,
                            :attributes, nil)
    end

    storeFilePath = applicationSupportFolder.stringByAppendingPathComponent("TilePuzzle.xml")
    didCreateNewStoreFile = ! fileManager.fileExistsAtPath(storeFilePath)
    
    url = NSURL.fileURLWithPath(storeFilePath)
    coordinator = NSPersistentStoreCoordinator.alloc.initWithManagedObjectModel(managedObjectModel)
    coordinator.objc_send(:addPersistentStoreWithType, NSXMLStoreType,
                          :configuration, nil,
                          :URL, url,
                          :options, nil,
                          :error, nil)
    @managedObjectContext = NSManagedObjectContext.alloc.init
    @managedObjectContext.persistentStoreCoordinator = coordinator
    
    if (didCreateNewStoreFile)
      createTiles(managedObjectContext)
      managedObjectContext.undoManager.removeAllActions
    end
    puts "returning managedobjectcontext"
    @managedObjectContext
  end

end
