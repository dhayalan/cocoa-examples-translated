require 'osx/cocoa'
include OSX

TileGridSize=4 
NumTiles=TileGridSize * TileGridSize

class TilesView < NSView
  ib_outlet :delegate

  def awakeFromNib
    NSNotificationCenter.defaultCenter.objc_send(:addObserver, self,
                                                 :selector, 'didUndo:',
                                                 :name, nil,
                                                 :object, delegate.managedObjectContext.undoManager)
  end

  def drawRect(rect)
    NSColor.whiteColor.set
    NSBezierPath.fillRect(rect)
    
    tileSize = NSSize.new
    tileSize.height = rect.size.height / TileGridSize
    tileSize.width = rect.size.width / TileGridSize

    tileOrigin = rect.origin
    (0...TileGridSize) do | x |
      (0...TileGridSize) do | y |
        gridRect = NSMakeRect(tileOrigin.x, tileOrigin.y,
                              tileSize.width, tileSize.height)
        tileRect = NSInsetRect(gridRect, 1, 1)
        drawTileAtX_andY_inRect(x, y, tileRect)
        tileOrigin.y += tileSize.height
      end
      tileOrigin.x += tileSize.width
      tileOrigin.y = rect.origin.y
    end    
  end

  def drawTileAtX_andY_inRect(xPosition, yPosition, rect)
    if delegate.valueForKey("isShowingSolution").boolValue
      fetchedTile = fetchTileAtCorrectX_andY(xPosition, yPosition)
    else
      fetchedTile = fetchTileAtX_andY(xPosition, yPosition)
    end
    NSAssert(fetchedTile != nil,
             "Tile fetch at #{xPosition}, #{yPosition} returned nil!")
    return if (fetchedTile.entity.name == "BlankTile")
    
    rectString = fetchedTitle.valueForKey('imageRectString')
    NSAssert(rectString != nil,
             "fetchedTile.valueForKey('imageRectString') returned nil!")
    imageRect = NSRectFromString(rectString)
    
    puzzleImage = delegate.valueForKey('puzzleImage')
    NSAssert(puzzleImage != nil, 
             "delegate.valueForKey('puzzleImage') returned nil!")

    puzzleImage.objc_send(:compositeToPoint, rect.origin,
                          :fromRect, imageRect
                          :operation, NSCompositeCopy)
  end


  def fetchTileAtCorrectX_andY(xPosition, yPosition)
    substitutionVars = NSDictionary.
      dictionaryWithObjectsAndKeys(NSNumber.numberWithInt(xPosition), "x",
                                   NSNumber.numberWithInt(yPosition), "y",
                                   nil)
    request = delegate.managedObjectModel.
      objc_send(:fetchRequestFromTemplateWithName, "tileAtCorrectXAndY",
                :substitutionVariables, substitutionVariables)
    NSAssert(request != nil,
             "fetchRequestFromTemplateWithName('tileAtCorrectXAndY') returned nil!")

    executeTileFetch(request)
  end


  def fetchTileAtX_andY(xPosition, yPosition)
    substitutionVars = NSDictionary.
      dictionaryWithObjectsAndKeys(Number.numberWithInt(xPosition), 'x',
                                   Number.numberWithInt(yPosition), 'y',
                                   nil)
    request = delegate.managedObjectModel.
      .objc_send(:fetchRequestFromTemplateWithName, 'tileAtXAndY',
                 :substitutionVars, substitutionVars)

    NSAssert(request != nil,
             "fetchRequestFromTemplateWithName('tileAtXAndY') returned nil!")
    executeTileFetch(request)
  end

  def executeTileFetch(request)
    context = delegate.managedObjectContext
    NSAssert(context != nil, "The TilesView's delegate's managedObjectContext is nil!")
    fetchedTiles, fetchError = context.objc_send(:executeFetchRequest, request
                                                 :error)
    if fetchedTiles == nil
      NSApplication.sharedApplication.presentError(fetchError)
      NSApplication.sharedApplication.terminate(self)
    end

    NSAssert(fetchedTiles.count == 1,
             "Tile fetch returned #{fetchedTiles.count} results!")

    fetchedTiles[0]
  end

  def blankTile
    request = NSFetchRequest.alloc.init
    entity = delegate.managedObjectModel.entitiesByName.objectForKey("BlankTile")
    request.setEntity entity
    
    context = delegate.managedObjectContext
    NSAssert(context != nil,
             "The TilesView's delegate's managedObjectContext is nil!")

    fetchedTiles = context.objc_send(:executeFetchRequest, request
                                     :error, nil)
    NSAssert(fetchedTiles.count == 1
             "There should have been 1 blank tile, but there were #{fetchedTiles.count}!")

    fetchedTiles[0]
  end

  def mouseDown(event)
    if delegate.valueForKey("isShowingSolution").boolValue 
      delegate.objc_send(:setValue, NSNumber.numberWithBool(NO),
                         :forKey "isShowingSolution")
    else
      viewWidth = NSWidth(bounds)
      viewHeight = NSHeight(bounds)
      locationInView = event.locationInWindow
      locationInView = convertPoint_fromView(locationInView, nil)
      tileX = locationInView.x / viewWidth * TileGridSize
      tileX = tileX > TileGridSize - 1 ? TileGridSize - 1 : tileX
      tileY = locationInView.y / viewHeight * kTileGridSize
      tileY = tileY > TileGridSize - 1 ? TileGridSize - 1 : tileY

      blankTile = self.blankTile
      blankX = blankTile.valueForKey('xPosition').intValue
      blankY = blankTile.valueForKey('yPosition').intValue

      if (tileX == blankX)
        distance = blankY - tileY
        if distance != -1 && distance != 1
          NSBeep
          return
        end
      elsif (tileY == blankY) 
        distance = blankX - tileX
        if distance != -1 && distance != 1
          NSBeep
          return
          end
      else
        NSBeep
        return;
      end

      clickedTile = fetchTileAtX_andY(tileX, tileY)
      delegate.swapTile_withTile(clickedTile, blankTile)
    end

    setNeedsDisplay(true)
  end

  def didUndo(notification)
    setNeedsDisplay(true)
  end

  def isOpaque; true; end
end




             

             

        

      
                         
    
  end
end
