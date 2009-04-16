require 'constants'

class BoardPosition < OSX::NSObject
  attr_reader :x, :y

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

class Behavior < OSX::NSObject
  def initWithPuzzle(puzzle)
    init
    puts "Behavior = #{self.class}"
    @puzzle = puzzle
    self
  end

  def click_tile(tile, error_block); subclass_responsibility; end
  def piece_position_request_template; subclass_responsibility; end
  def x_position_to_display; subclass_responsibility; end
  def y_position_to_display; subclass_responsibility; end
end

class PuzzleSolvingBehavior < Behavior
  def piece_position_request_template; 'tileAtXAndY'; end
  def x_position_to_display; puts "xPosition"; 'xPosition'; end
  def y_position_to_display; 'yPosition'; end
  
  def click_tile(tile, error_block)
    if @puzzle.moveable_tile?(tile)
      @puzzle.move_tile_at(tile)
    else
      error_block.call
    end
  end
end

class SolutionDisplayingBehavior < Behavior
  def piece_position_request_template; 'tileAtCorrectXAndY'; end
  def x_position_to_display; puts "correct x position"; 'correctXPosition'; end
  def y_position_to_display; 'correctYPosition'; end
  
  def click_tile(tile, error_block)
    @puzzle.configure_to_show_problem
  end
end


class Puzzle < OSX::NSObject
  include OSX

  def init
    super_init
    configure_to_show_problem
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

    @window.display
  end

  def all_tiles
    request = managedObjectModel.fetchRequestTemplateForName("allTiles")
    fetchedTiles = managedObjectContext.objc_send(:executeFetchRequest, request,
                                                  :error, nil)
    fetchedTiles
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
      objc_send(:fetchRequestFromTemplateWithName, @behavior.piece_position_request_template,
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
    fetchedTiles[0]
  end

  def blankTile
    request = NSFetchRequest.alloc.init
    entity = @managedObjectModel.entitiesByName.objectForKey("BlankTile")
    request.setEntity entity
    
    fetchedTiles = @managedObjectContext.objc_send(:executeFetchRequest, request,
                                     :error, nil)

    fetchedTiles[0]
  end

  def correct_position_of(tile)
    x = tile.valueForKey("correctXPosition").to_i
    y = tile.valueForKey("correctYPosition").to_i
    BoardPosition.at(x, y)
  end

  def display_position_of(tile)
    x = tile.valueForKey(@behavior.x_position_to_display).to_i
    y = tile.valueForKey(@behavior.y_position_to_display).to_i
    BoardPosition.at(x, y)
  end

  def blank_tile_position
    blankX = blankTile.valueForKey('xPosition').intValue
    blankY = blankTile.valueForKey('yPosition').intValue
    BoardPosition.at(blankX, blankY)
  end

  def moveable_tile?(tile_position)
    tile_position.adjacent_to(blank_tile_position)
  end

  def move_tile_at(tile_position)
    clickedTile = piece_at(tile_position.x, tile_position.y)
    swapTile_withTile(clickedTile, blankTile)
  end

  def configure_to_show_solution
    @behavior = SolutionDisplayingBehavior.alloc.initWithPuzzle(self)
  end

  def configure_to_show_problem
    @behavior = PuzzleSolvingBehavior.alloc.initWithPuzzle(self)
  end

  def click_tile(tile, error_block)
    @behavior.click_tile(tile, error_block)
  end
end
