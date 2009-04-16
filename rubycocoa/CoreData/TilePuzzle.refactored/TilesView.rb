require 'constants'
require 'util'
require 'BoardPosition'

class TilesView < OSX::NSView
  include OSX
  include Utilities

  ib_outlet :delegate
  ib_outlet :puzzle
  attr_reader :delegate

  # View protocol

  def awakeFromNib
    NSNotificationCenter.defaultCenter.objc_send(:addObserver, self,
                                                 :selector, 'didUndo:',
                                                 :name, nil,
                                                 :object, @puzzle.undo_manager)

    @puzzle_image = find_puzzle_image
    user_wants_to_solve_puzzle
  end

  def drawRect(rect)
    NSColor.whiteColor.set
    NSBezierPath.fillRect(rect)
    
    @puzzle.all_tiles.each do | tile |
      draw_tile_in_rect(tile, rect)
    end
  end

  def mouseDown(event)
    send(@click_behavior, tile_position_clicked(event))
    setNeedsDisplay(true)
  end

  def didUndo(notification)
    setNeedsDisplay(true)
  end

  def isOpaque; true; end


  # Used by peer objects

  def user_wants_to_solve_puzzle(*ignored)
    @position_to_display = :current_position
    @click_behavior = :move_tile
  end

  def user_wants_to_see_solution(*ignored)
    @position_to_display = :ending_position
    @click_behavior = :user_wants_to_solve_puzzle
  end


  private

  def draw_tile_in_rect(tile, rect)
    return if tile.blank?

    to = tile_position_in_view_coordinates(tile.send(@position_to_display), rect)
    from = @puzzle_image.tile_rect(tile.ending_position)

    @puzzle_image.objc_send(:compositeToPoint, to,
                            :fromRect, from,
                            :operation, NSCompositeCopy)
  end

  def move_tile(clicked)
    @puzzle.click_tile(clicked, on_error { OSX.NSBeep })
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

  def tile_position_in_view_coordinates(position, rect)
    tileSize = NSSize.new
    tileSize.height = rect.size.height / TileGridSize
    tileSize.width = rect.size.width / TileGridSize

    tileX = position.x * tileSize.width
    tileY = position.y * tileSize.height

    NSPoint.new(rect.origin.x + tileX, rect.origin.y+tileY)
  end

  def find_puzzle_image
    imagePath = NSBundle.mainBundle.pathForImageResource(PuzzleImageName)
    puzzle_image = NSImage.alloc.initWithContentsOfFile(imagePath)

    def puzzle_image.tile_size
      NSSize.new(size.width / TileGridSize, size.height / TileGridSize)
    end

    def puzzle_image.tile_rect(tile_position)
      origin = NSPoint.new(tile_size.width * tile_position.x,
                           tile_size.height * tile_position.y)
      NSRect.new(origin, tile_size)
    end
    puzzle_image
  end

end

