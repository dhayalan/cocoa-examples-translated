class PersistentStore < OSX::NSObject
  include OSX
  
  attr_accessor :managedObjectModel, :managedObjectContext
  
  def fresh?
    @is_fresh
  end

  def init
    super_init
    allBundles = NSMutableSet.alloc.init
    allBundles.addObject(NSBundle.mainBundle)
    allBundles.addObjectsFromArray(NSBundle.allFrameworks)

    @managedObjectModel = NSManagedObjectModel.mergedModelFromBundles(allBundles.allObjects)

    app_support = ApplicationSupport.alloc.initForApp("TilePuzzle")
    @is_fresh = ! app_support.file_exists?("TilePuzzle.xml")
    
    coordinator = NSPersistentStoreCoordinator.alloc.initWithManagedObjectModel(managedObjectModel)
    coordinator.objc_send(:addPersistentStoreWithType, NSXMLStoreType,
                          :configuration, nil,
                          :URL, app_support.file_url("TilePuzzle.xml"),
                          :options, nil,
                          :error, nil)

    @managedObjectContext = NSManagedObjectContext.alloc.init
    @managedObjectContext.persistentStoreCoordinator = coordinator
    self
  end

  def undoably
    managedObjectContext.undoManager.beginUndoGrouping
    yield
    managedObjectContext.undoManager.endUndoGrouping
  end

  def fetch_by_template(name, hash = {})
    request = managedObjectModel.
      objc_send(:fetchRequestFromTemplateWithName, name,
                 :substitutionVariables, hash)
    executeTileFetch(request)
  end

  def fetch_by_name(name)
    request = NSFetchRequest.alloc.init
    entity = managedObjectModel.entitiesByName.objectForKey(name)
    request.entity=entity
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

  def insert_by_name(name, settings = {})
    retval = NSEntityDescription.objc_send(:insertNewObjectForEntityForName, name,
                                           :inManagedObjectContext, managedObjectContext)
    settings.each do | key, value | 
      retval.setValue_forKey(value, key)
    end
    retval
  end

  def undo_manager
    managedObjectContext.undoManager
  end

  def forget_all_undoable_actions
    managedObjectContext.processPendingChanges
    undo_manager.removeAllActions
  end


  def finish_pending_user_edits
    managedObjectContext.commitEditing
  end

  def save
    managedObjectContext.save_(nil)
  end
end
