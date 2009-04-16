class PersistentStore < OSX::NSObject
  include OSX
  
  attr_accessor :managedObjectModel, :managedObjectContext

  def init
    super_init
    allBundles = NSMutableSet.alloc.init
    allBundles.addObject(NSBundle.mainBundle)
    allBundles.addObjectsFromArray(NSBundle.allFrameworks)

    @managedObjectModel = NSManagedObjectModel.mergedModelFromBundles(allBundles.allObjects)

    app_support = ApplicationSupport.alloc.initForApp("TilePuzzle")
    didCreateNewStoreFile = ! app_support.file_exists?("TilePuzzle.xml")
    
    coordinator = NSPersistentStoreCoordinator.alloc.initWithManagedObjectModel(managedObjectModel)
    coordinator.objc_send(:addPersistentStoreWithType, NSXMLStoreType,
                          :configuration, nil,
                          :URL, app_support.file_url("TilePuzzle.xml"),
                          :options, nil,
                          :error, nil)

    @managedObjectContext = NSManagedObjectContext.alloc.init
    @managedObjectContext.persistentStoreCoordinator = coordinator
    
    if (didCreateNewStoreFile)
      createTiles(managedObjectContext)
      managedObjectContext.undoManager.removeAllActions
    end


    self
  end

  def undoably
    managedObjectContext.undoManager.beginUndoGrouping
    yield
    managedObjectContext.undoManager.endUndoGrouping
  end

  def fetch_by_name(name, hash = {})
    request = managedObjectModel.
      objc_send(:fetchRequestFromTemplateWithName, name,
                 :substitutionVariables, hash)
    executeTileFetch(request)
  end

  def executeTileFetch(request)
    fetchedTiles, fetchError = managedObjectContext.objc_send(:executeFetchRequest, request,
                                                 :error)
    if fetchedTiles == nil
      NSApplication.sharedApplication.presentError(fetchError)
      NSApplication.sharedApplication.terminate(self)
    end
    fetchedTiles
  end

end
