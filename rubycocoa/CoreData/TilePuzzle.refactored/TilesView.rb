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
      puts NSRect.new(origin, piece_size).inspect
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
    puts "To draw this tile:"
    puts tile
    puts "in this rect"

    @puzzle_image.objc_send(:compositeToPoint, tile_display_position_in_view_coordinates(tile, rect),
                            :fromRect, @puzzle_image.piece_rect(@puzzle.correct_position_of(tile)),
                            :operation, NSCompositeCopy)
  end

  def on_error(&block)
    block
  end

  def mouseDown(event)
    locationInView = event.locationInWindow
    locationInView = convertPoint_fromView(locationInView, nil)
    clicked = convert_to_tile_position(locationInView)

    @puzzle.click_tile(clicked, on_error { OSX.NSBeep })

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

  def tile_display_position_in_view_coordinates(tile, rect)
    tileSize = NSSize.new
    tileSize.height = rect.size.height / TileGridSize
    tileSize.width = rect.size.width / TileGridSize

    tileX = @puzzle.display_position_of(tile).x * tileSize.width
    tileY = @puzzle.display_position_of(tile).y * tileSize.height
    puts "tile position in view coordinates: " +     NSPoint.new(rect.origin.x + tileX, rect.origin.y+tileY).inspect

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

