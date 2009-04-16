require 'constants'
require 'BoardPosition'
require 'ApplicationSupport'
require 'PersistentStore'

class Puzzle < OSX::NSObject
  include OSX

  def init
    super_init
    @persistent_store = PersistentStore.alloc.init
    self
  end

  def managedObjectModel
    @persistent_store.managedObjectModel
  end

  def managedObjectContext
    @persistent_store.managedObjectContext
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
    
    @persistent_store.undoably do 
      (0...NumTiles).each do | i | 
        swapTile_withTile(fetchedTiles[i], fetchedTiles[rand(NumTiles)])
      end
    end
  end

  def all_tiles
    annotated(@persistent_store.fetch_by_name("allTiles"))
  end

  def swapTile_withTile(firstTile, secondTile)
    firstX = firstTile.valueForKey("xPosition")
    firstY = firstTile.valueForKey("yPosition")

    @persistent_store.undoably do 
      firstTile.setValue_forKey(secondTile.valueForKey("xPosition"),
                                "xPosition")
      firstTile.setValue_forKey(secondTile.valueForKey("yPosition"),
                                "yPosition")
      secondTile.setValue_forKey(firstX, "xPosition")
      secondTile.setValue_forKey(firstY, "yPosition")
    end
  end

  def piece_at(xPosition, yPosition)
    result = @persistent_store.fetch_by_name("tileAtXAndY", 
                                             'x' => xPosition,
                                             'y' => yPosition)
    annotated(result)[0]
  end


  def executeTileFetch(request)
    fetchedTiles, fetchError = managedObjectContext.objc_send(:executeFetchRequest, request,
                                                 :error)
    if fetchedTiles == nil
      NSApplication.sharedApplication.presentError(fetchError)
      NSApplication.sharedApplication.terminate(self)
    end
    annotated(fetchedTiles)[0]
  end

  def blankTile
    request = NSFetchRequest.alloc.init
    entity = managedObjectModel.entitiesByName.objectForKey("BlankTile")
    request.setEntity entity
    
    fetchedTiles = managedObjectContext.objc_send(:executeFetchRequest, request,
                                     :error, nil)

    annotated(fetchedTiles)[0]
  end

  def annotated(tiles)

    tiles.each do | tile |

      def tile.blank?
        entity.name == "BlankTile"
      end
      

      def tile.ending_position
        BoardPosition.for_tile(self, "correctXPosition", "correctYPosition")
      end

      def tile.current_position
        BoardPosition.for_tile(self, "xPosition", "yPosition")
      end
    end
    tiles
  end

  def moveable_tile?(tile_position)
    tile_position.adjacent_to(blankTile.current_position)
  end

  def move_tile_at(tile_position)
    clickedTile = piece_at(tile_position.x, tile_position.y)
    swapTile_withTile(clickedTile, blankTile)
  end

  def move_tile(tile_position, error_block)
    if moveable_tile?(tile_position)
      move_tile_at(tile_position)
    else
      error_block.call
    end
  end

  def undo_manager
    managedObjectContext.undoManager
  end
end
