require 'constants'
require 'util'
require 'BoardPosition'

class TilesView < OSX::NSView
  def drawRect(rect)                  # This will be called when you click.
    NSColor.whiteColor.set
    NSBezierPath.fillRect(rect)
    
    $all = @puzzle.all_tiles          # Look at this in Puzzle.rb
    print_array

    # Each is going to extract each Objective-C object in turn, 
    # giving it a new (potentially) Ruby proxy. Often, but not 
    # always, that proxy will be the same one as before.
    $all.each do | tile |
      draw_tile_in_rect(tile, rect)
    end
  end

  def draw_tile_in_rect(tile, rect)
    print_tile(tile)
    return if tile.blank?

    to = tile_position_in_view_coordinates(tile.send(@position_to_display), rect)
    from = @puzzle_image.tile_rect(tile.ending_position)

    @puzzle_image.objc_send(:compositeToPoint, to,
                            :fromRect, from,
                            :operation, NSCompositeCopy)
  end

  def elementary(e)
    "#{[e.xPosition.to_i, e.yPosition.to_i].inspect}: #{e.object_id}/#{e.__ocid__} #{e.respond_to?(:blank?)}"
  end

  def print_array
    puts "NSArray at #{$all.__ocid__}"
    puts $all.collect { | e | elementary(e) }
  end

  def print_tile(tile)
    puts "Drawing #{elementary(tile)}"
    puts tile
    unless tile.respond_to?(:blank?)
      puts "ABOUT TO DIE"
      print_array
    end
  end
 





  # The following bits aren't relevant to the point of this example.

  include OSX
  include Utilities

  ib_outlet :puzzle

  # View protocol

  def awakeFromNib
    NSNotificationCenter.defaultCenter.objc_send(:addObserver, self,
                                                 :selector, 'didUndo:',
                                                 :name, nil,
                                                 :object, @puzzle.undo_manager)

    @puzzle_image = find_puzzle_image
    user_wants_to_solve_puzzle
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

  def move_tile(tile_position)
    @puzzle.move_tile(tile_position, on_error { OSX.NSBeep })
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
