require 'constants'

class TilesView < OSX::NSView
  include OSX

  ib_outlet :delegate
  ib_outlet :puzzle
  attr_reader :delegate

  def awakeFromNib
    NSNotificationCenter.defaultCenter.objc_send(:addObserver, self,
                                                 :selector, 'didUndo:',
                                                 :name, nil,
                                                 :object, @puzzle.managedObjectContext.undoManager)

    imagePath = NSBundle.mainBundle.pathForImageResource(PuzzleImageName)
    @puzzle_image = NSImage.alloc.initWithContentsOfFile(imagePath)

    def @puzzle_image.piece_size
      NSSize.new(size.width / TileGridSize, size.height / TileGridSize)
    end

    def @puzzle_image.piece_rect(tile_position)
      origin = NSPoint.new(piece_size.width * tile_position.x,
                           piece_size.height * tile_position.y)
      NSRect.new(origin, piece_size)
    end

  end

  def drawRect(rect)
    NSColor.whiteColor.set
    NSBezierPath.fillRect(rect)
    
    @puzzle.all_tiles.each do | tile |
      draw_tile_in_rect(tile, rect)
    end
  end

  def draw_tile_in_rect(tile, rect)
    return if tile.entity.name == "BlankTile"

#    loc =         BoardPosition.at(tile.valueForKey("correctXPosition").to_i,
#                                   tile.valueForKey("correctYPosition").to_i)


    @puzzle_image.objc_send(:compositeToPoint, tile_position_in_view_coordinates(tile, rect),
                            :fromRect, @puzzle_image.piece_rect(tile.position),
                            :operation, NSCompositeCopy)
  end


  def mouseDown(event)
    # puts "mouseDown"
    if delegate.valueForKey("isShowingSolution").boolValue 
      delegate.objc_send(:setValue, NSNumber.numberWithBool(false),
                         :forKey, "isShowingSolution")
    else
      locationInView = event.locationInWindow
      locationInView = convertPoint_fromView(locationInView, nil)
      clicked = convert_to_tile_position(locationInView)

      if @puzzle.moveable_tile?(clicked)
        @puzzle.move_tile_at(clicked)
      else
        OSX.NSBeep
      end
    end

    setNeedsDisplay(true)
  end

  def convert_to_tile_position(locationInView)
    viewWidth = NSWidth(bounds)
    viewHeight = NSHeight(bounds)
    tileX = (locationInView.x / viewWidth * TileGridSize).to_i
    tileX = tileX > TileGridSize - 1 ? TileGridSize - 1 : tileX
    tileY = (locationInView.y / viewHeight * TileGridSize).to_i
    tileY = tileY > TileGridSize - 1 ? TileGridSize - 1 : tileY
    BoardPosition.at(tileX, tileY)
  end

  def tile_position_in_view_coordinates(tile, rect)
    tileSize = NSSize.new
    tileSize.height = rect.size.height / TileGridSize
    tileSize.width = rect.size.width / TileGridSize

    tileX = tile.valueForKey('xPosition').to_i * tileSize.width
    tileY = tile.valueForKey('yPosition').to_i * tileSize.height
    NSPoint.new(rect.origin.x + tileX, rect.origin.y+tileY)
  end

  def didUndo(notification)
    setNeedsDisplay(true)
  end

  def isOpaque
    # puts "isOpaque called"
    true
  end
end

