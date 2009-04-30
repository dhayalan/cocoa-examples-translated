require 'constants'
require 'BoardPosition'
require 'ApplicationSupport'
require 'PersistentStore'

class Puzzle

  def init
    @persistent_store = PersistentStore.alloc.init
    create_all_tiles if @persistent_store.fresh?
    self
  end

  def all_tiles
    annotated(@persistent_store.fetch_by_template("allTiles"))
  end

  def shuffle
    fetched = all_tiles
    
    @persistent_store.undoably do 
      (0...NumTiles).each do | i | 
        swap(fetched[i], fetched[rand(NumTiles)])
      end
    end
  end

  def move_tile(tile_position, error_block)
    if moveable_tile?(tile_position)
      swap_with_blank(tile_position)
    else
      error_block.call
    end
  end

  def finish_pending_user_edits
    @persistent_store.finish_pending_user_edits
  end

  def save
    @persistent_store.save
  end

  def undo_manager
    @persistent_store.undo_manager
  end

  private

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
    link_duration_of_contents_to_duration_of_container(tiles)
  end

  def link_duration_of_contents_to_duration_of_container(tiles)
    # Objective-C objects within an Objective-C container can lose their
    # Ruby half, allowing their object_id to change each time they're
    # fetched into the Ruby universe. By putting them inside a Ruby
    # container, that fate is avoided.
    # See rubycocoa/gotchas/object-id-simple.
    tiles.to_a
  end

  def create_all_tiles
    place_image_tiles_sequentially
    place_blank_tile_at_end
    @persistent_store.forget_all_undoable_actions
  end
    
  def place_image_tiles_sequentially
    (0...NumTiles-1).each do | i | 
      x = i / TileGridSize
      y = i % TileGridSize

      @persistent_store.insert_by_name("ImageTile",
                                       :xPosition => x,
                                       :yPosition => y,
                                       :correctXPosition => x,
                                       :correctYPosition => y)
    end
  end

  def place_blank_tile_at_end
    last_pos = TileGridSize-1
    @persistent_store.insert_by_name("BlankTile",
                                     :xPosition => last_pos,
                                     :yPosition => last_pos,
                                     :correctXPosition => last_pos,
                                     :correctYPosition => last_pos)
  end


  def swap(first, second)
    first_x = first.xPosition
    first_y = first.yPosition

    @persistent_store.undoably do 
      first.xPosition = second.xPosition
      first.yPosition = second.yPosition
      second.xPosition = first_x
      second.yPosition = first_y
    end
  end

  def piece_at(x, y)
    result = @persistent_store.fetch_by_template("tileAtXAndY", 
                                                 'x' => x,
                                                 'y' => y)
    annotated(result)[0]
  end


  def the_blank_tile
    result = @persistent_store.fetch_by_name("BlankTile")
    annotated(result)[0]
  end

  def moveable_tile?(tile_position)
    tile_position.adjacent_to(the_blank_tile.current_position)
  end

  def swap_with_blank(tile_position)
    tile = piece_at(tile_position.x, tile_position.y)
    swap(tile, the_blank_tile)
  end

end
