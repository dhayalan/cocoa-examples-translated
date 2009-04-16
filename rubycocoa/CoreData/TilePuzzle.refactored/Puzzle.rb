require 'constants'

class BoardPosition < OSX::NSObject
  attr_reader :x, :y


  def self.for_tile(tile, xkey, ykey)
    x = tile.valueForKey(xkey).to_i
    y = tile.valueForKey(ykey).to_i
    at(x, y)
  end

  def self.at(x, y)
    BoardPosition.alloc.initAtX_andY(x, y)
  end

  def initAtX_andY(x, y)
    init
    @x = x
    @y = y
    self
  end

  def ==(other)
    self.x == other.x && self.y == other.y
  end

  def adjacent_to(other)
    return true if (self.x == other.x) && (other.y - self.y).abs == 1
    return true if (self.y == other.y) && (other.x - self.x).abs == 1
    false
  end
end

class Puzzle < OSX::NSObject
  include OSX

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
    @managedObjectContext
  end

  def createTiles(context)
    place_tiles(context)

    blankTile = NSEntityDescription.objc_send(:insertNewObjectForEntityForName, "BlankTile",
                                              :inManagedObjectContext, context)
    blankTile.setValue_forKey(TileGridSize-1, "xPosition")
    blankTile.setValue_forKey(TileGridSize-1, "correctXPosition")
    blankTile.setValue_forKey(TileGridSize-1, "yPosition")
    blankTile.setValue_forKey(TileGridSize-1, "correctYPosition")

    context.processPendingChanges
    context.undoManager.removeAllActions
  end
    
  def place_tiles(context)
    i = 1
    (0...TileGridSize).each do | tileX | 
      (0...TileGridSize).each do | tileY |
        return if i == NumTiles
        i += 1

        newTile = NSEntityDescription.objc_send(:insertNewObjectForEntityForName, "ImageTile",
                                                :inManagedObjectContext, context)
        newTile.setValue_forKey(tileX, "xPosition")
        newTile.setValue_forKey(tileX, "correctXPosition")
        newTile.setValue_forKey(tileY, "yPosition")
        newTile.setValue_forKey(tileY, "correctYPosition")
      end
    end
  end


  def shuffle
    fetchedTiles = all_tiles
    
    managedObjectContext.undoManager.beginUndoGrouping
    (0...NumTiles).each do | i | 
      swapTile_withTile(fetchedTiles[i], fetchedTiles[rand(NumTiles)])
    end
    managedObjectContext.undoManager.endUndoGrouping
  end

  def all_tiles
    request = managedObjectModel.fetchRequestTemplateForName("allTiles")
    fetchedTiles = managedObjectContext.objc_send(:executeFetchRequest, request,
                                                  :error, nil)
    annotated(fetchedTiles)
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

  def piece_at(xPosition, yPosition)
    substitutionVars = NSDictionary.
      dictionaryWithObjectsAndKeys(NSNumber.numberWithInt(xPosition), 'x',
                                   NSNumber.numberWithInt(yPosition), 'y',
                                   nil)
    request = @managedObjectModel.
      objc_send(:fetchRequestFromTemplateWithName, 'tileAtXAndY',
                 :substitutionVariables, substitutionVars)
    executeTileFetch(request)
  end


  def executeTileFetch(request)
    fetchedTiles, fetchError = @managedObjectContext.objc_send(:executeFetchRequest, request,
                                                 :error)
    if fetchedTiles == nil
      NSApplication.sharedApplication.presentError(fetchError)
      NSApplication.sharedApplication.terminate(self)
    end
    annotated(fetchedTiles)[0]
  end

  def blankTile
    request = NSFetchRequest.alloc.init
    entity = @managedObjectModel.entitiesByName.objectForKey("BlankTile")
    request.setEntity entity
    
    fetchedTiles = @managedObjectContext.objc_send(:executeFetchRequest, request,
                                     :error, nil)

    annotated(fetchedTiles)[0]
  end

  def annotated(tiles)

    tiles.each do | tile |
      def tile.correct_position
        BoardPosition.for_tile(self, "correctXPosition", "correctYPosition")
      end

      def tile.display_position
        BoardPosition.for_tile(self, "xPosition", "yPosition")
      end
    end
    tiles
  end

  def moveable_tile?(tile_position)
    tile_position.adjacent_to(blankTile.display_position)
  end

  def move_tile_at(tile_position)
    clickedTile = piece_at(tile_position.x, tile_position.y)
    swapTile_withTile(clickedTile, blankTile)
  end

  def click_tile(tile, error_block)
    if moveable_tile?(tile)
      move_tile_at(tile)
    else
      error_block.call
    end
  end
end
