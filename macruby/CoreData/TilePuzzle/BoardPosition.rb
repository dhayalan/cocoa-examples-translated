class BoardPosition
  attr_reader :x, :y


  def self.for_tile(tile, xkey, ykey)
    x = tile.valueForKey(xkey).intValue
    y = tile.valueForKey(ykey).intValue
    at(x, y)
  end

  def self.at(x, y)
    BoardPosition.alloc.initAtX x, andY: y
  end

  def initAtX x, andY: y
    init
    @x = x
    @y = y
    self
  end

  def adjacent_to(other)
    return true if (self.x == other.x) && (other.y - self.y).abs == 1
    return true if (self.y == other.y) && (other.x - self.x).abs == 1
    false
  end
end

