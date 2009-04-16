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

    user_wants_to_solve_puzzle
  end

  def user_wants_to_solve_puzzle
    @position_to_display = :display_position
    @click_behavior = :move_piece
  end

  def user_wants_to_see_solution
    @position_to_display = :correct_position
    @click_behavior = :erase_solution_display
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

    to = position_in_view_coordinates(tile.send(@position_to_display), rect)
    from = @puzzle_image.piece_rect(tile.correct_position)

    @puzzle_image.objc_send(:compositeToPoint, to,
                            :fromRect, from,
                            :operation, NSCompositeCopy)
  end

  def on_error(&block)
    block
  end

  def mouseDown(event)
    clicked = tile_position_clicked(event)
    send(@click_behavior, clicked)
    setNeedsDisplay(true)
  end

  def move_piece(clicked)
    @puzzle.click_tile(clicked, on_error { OSX.NSBeep })
  end

  def erase_solution_display(clicked)
    user_wants_to_solve_puzzle
  end

  def tile_position_clicked(event)
    locationInView = event.locationInWindow
    locationInView = convertPoint_fromView(locationInView, nil)
    viewWidth = NSWidth(bounds)
    viewHeight = NSHeight(bounds)
    tileX = (locationInView.x / viewWidth * TileGridSize).to_i
    # Why is following check needed?
    tileX = tileX > TileGridSize - 1 ? TileGridSize - 1 : tileX
    tileY = (locationInView.y / viewHeight * TileGridSize).to_i
    tileY = tileY > TileGridSize - 1 ? TileGridSize - 1 : tileY
    BoardPosition.at(tileX, tileY)
  end

  def position_in_view_coordinates(position, rect)
    tileSize = NSSize.new
    tileSize.height = rect.size.height / TileGridSize
    tileSize.width = rect.size.width / TileGridSize

    tileX = position.x * tileSize.width
    tileY = position.y * tileSize.height

    NSPoint.new(rect.origin.x + tileX, rect.origin.y+tileY)
  end

  def didUndo(notification)
    setNeedsDisplay(true)
  end

  def isOpaque
    true
  end
end

