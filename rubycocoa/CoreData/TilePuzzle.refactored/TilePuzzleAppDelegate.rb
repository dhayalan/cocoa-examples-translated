require 'constants'
require 'TilesView'

class TilePuzzleAppDelegate < OSX::NSObject
  include OSX

  ib_outlet :window
  kvc_reader :isShowingSolution
  kvc_reader :puzzleImage
  
  def init
    super_init
    @isShowingSolution = false
    imagePath = NSBundle.mainBundle.pathForImageResource(PuzzleImageName)
    @puzzleImage = NSImage.alloc.initWithContentsOfFile(imagePath)
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
      

  # This is misleading. It looks like an action called from UI,
  # but it's only called internally.
  def saveAction(sender)
    success, error = managedObjectContext.save(nil)
    unless success
      NSApplication.sharedApplication.presentError(error)
    end
  end

  def windowWillReturnUndoManager(sender)
    managedObjectContext.undoManager
  end

  def windowWillClose(notification)
    saveAction(self)
  end

  def applicationShouldTerminateAfterLastWindowClosed
    true
  end

  def applicationShouldTerminate(sender)
    reply = NSTerminateNow
    return reply unless managedObjectContext  # This should be impossible.
    if managedObjectContext.commitEditing
      result, error = managedObjectContext.save_  # _ required because name of method is "save:"
      unless result
        errorResult = NSApplication.sharedApplication.presentError(error)
        if errorResult
          reply = NSTerminateCancel
        else
          alertReturn = NSRunAlertPanel(nil, "Could not save changes while quitting. Quit anyway?", "Quit anyway", "Cancel", nil)
          reply = NSTerminateCancel if alertReturn == NSAlertAlternateReturn
        end
      end
    else
      reply = NSTerminateCancel
    end
    reply
  end

  def createTiles(context)
    imageSize = @puzzleImage.size
    pieceWidth = imageSize.width / TileGridSize
    pieceHeight = imageSize.height / TileGridSize
    
    place_tiles(pieceWidth, pieceHeight, context)

    blankTile = NSEntityDescription.objc_send(:insertNewObjectForEntityForName, "BlankTile",
                                              :inManagedObjectContext, context)
    blankTile.setValue_forKey(TileGridSize-1, "xPosition")
    blankTile.setValue_forKey(TileGridSize-1, "correctXPosition")
    blankTile.setValue_forKey(TileGridSize-1, "yPosition")
    blankTile.setValue_forKey(TileGridSize-1, "correctYPosition")

    context.processPendingChanges
    context.undoManager.removeAllActions
  end
    
  def place_tiles(pieceWidth, pieceHeight, context)
    i = 1
    (0...TileGridSize).each do | tileX | 
      (0...TileGridSize).each do | tileY |
        return if i == NumTiles
        i += 1

        imageRect = OSX.NSMakeRect(tileX * pieceWidth, tileY * pieceHeight,
                               pieceWidth, pieceHeight)
        newTile = NSEntityDescription.objc_send(:insertNewObjectForEntityForName, "ImageTile",
                                                :inManagedObjectContext, context)
        newTile.setValue_forKey(tileX, "xPosition")
        newTile.setValue_forKey(tileX, "correctXPosition")
        newTile.setValue_forKey(tileY, "yPosition")
        newTile.setValue_forKey(tileY, "correctYPosition")
        newTile.setValue_forKey(OSX.NSStringFromRect(imageRect), "imageRectString")
      end
    end
  end

  def shuffle(sender)
    request = managedObjectModel.fetchRequestTemplateForName("allTiles")
    fetchedTiles = managedObjectContext.objc_send(:executeFetchRequest, request,
                                                  :error, nil)
    
    managedObjectContext.undoManager.beginUndoGrouping
    (0...NumTiles).each do | i | 
      swapTile_withTile(fetchedTiles[i], fetchedTiles[rand(NumTiles)])
    end
    managedObjectContext.undoManager.endUndoGrouping

    @window.display
  end

  def showSolution(sender)
    @isShowingSolution = true
    puts "=== @isShowingSolution: #{valueForKey('isShowingSolution').boolValue}"
    
    puts 'about to display'
    @window.display
    puts 'done displaying'
  end

  def swapTile_withTile(firstTile, secondTile)
    firstX = firstTile.valueForKey("xPosition")
    firstY = firstTile.valueForKey("yPosition")
    
    managedObjectContext.undoManager.beginUndoGrouping
    firstTile.setValue_forKey(secondTile.valueForKey("xPosition"),
                              "xPosition")
    firstTile.setValue_forKey(secondTile.valueForKey("yPosition"),
                              "yPosition")
    secondTile.setValue_forKey(firstX, "xPosition")
    secondTile.setValue_forKey(firstY, "yPosition")
    managedObjectContext.undoManager.endUndoGrouping
  end

end
