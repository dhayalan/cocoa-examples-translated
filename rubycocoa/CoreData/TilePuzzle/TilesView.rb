require 'constants'


class TilesView < OSX::NSView
  include OSX

  ib_outlet :delegate
  attr_reader :delegate

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

    tileOrigin = rect.origin.dup
    (0...TileGridSize).each do | x |
      (0...TileGridSize).each do | y |
        puts "#{x}, #{y} and #{tileOrigin.x}, #{tileOrigin.y}"
        
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
    return if (fetchedTile.entity.name == "BlankTile")
    
    rectString = fetchedTile.valueForKey('imageRectString')
    imageRect = NSRectFromString(rectString)
    
    puzzleImage = delegate.valueForKey('puzzleImage')

    puzzleImage.objc_send(:compositeToPoint, rect.origin,
                          :fromRect, imageRect,
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
    executeTileFetch(request)
  end


  def fetchTileAtX_andY(xPosition, yPosition)
    substitutionVars = NSDictionary.
      dictionaryWithObjectsAndKeys(NSNumber.numberWithInt(xPosition), 'x',
                                   NSNumber.numberWithInt(yPosition), 'y',
                                   nil)
    request = delegate.managedObjectModel.
      objc_send(:fetchRequestFromTemplateWithName, 'tileAtXAndY',
                 :substitutionVariables, substitutionVars)

    executeTileFetch(request)
  end

  def executeTileFetch(request)
    context = delegate.managedObjectContext

    fetchedTiles, fetchError = context.objc_send(:executeFetchRequest, request,
                                                 :error)
    if fetchedTiles == nil
      NSApplication.sharedApplication.presentError(fetchError)
      NSApplication.sharedApplication.terminate(self)
    end


    fetchedTiles[0]
  end

  def blankTile
    request = NSFetchRequest.alloc.init
    entity = delegate.managedObjectModel.entitiesByName.objectForKey("BlankTile")
    request.setEntity entity
    
    context = delegate.managedObjectContext

    fetchedTiles = context.objc_send(:executeFetchRequest, request,
                                     :error, nil)

    fetchedTiles[0]
  end

  def mouseDown(event)
    puts "mouseDown"
    if delegate.valueForKey("isShowingSolution").boolValue 
      delegate.objc_send(:setValue, NSNumber.numberWithBool(NO),
                         :forKey, "isShowingSolution")
    else
      viewWidth = NSWidth(bounds)
      viewHeight = NSHeight(bounds)
      locationInView = event.locationInWindow
      locationInView = convertPoint_fromView(locationInView, nil)

      tileX = (locationInView.x / viewWidth * TileGridSize).to_i
      tileX = tileX > TileGridSize - 1 ? TileGridSize - 1 : tileX
      tileY = (locationInView.y / viewHeight * TileGridSize).to_i
      tileY = tileY > TileGridSize - 1 ? TileGridSize - 1 : tileY

      blankTile = self.blankTile
      blankX = blankTile.valueForKey('xPosition').intValue
      blankY = blankTile.valueForKey('yPosition').intValue
      puts "tileX #{tileX} tileY #{tileY} blankX #{blankX} blankY #{blankY}"

      if (tileX == blankX)
        distance = blankY - tileY
        if distance != -1 && distance != 1
          puts "1"
          OSX.NSBeep
          return
        end
      elsif (tileY == blankY) 
        distance = blankX - tileX
        if distance != -1 && distance != 1
          puts "2"
          OSX.NSBeep
          return
          end
      else
        puts "3"
        OSX.NSBeep
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

  def isOpaque
    puts "isOpaque called"
    true
  end
end

