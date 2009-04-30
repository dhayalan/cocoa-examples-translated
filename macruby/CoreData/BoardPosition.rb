class BoardPosition < OSX::NSObject
  attr_reader :x, :y


  def self.for_tile(tile, xkey, ykey)
    x = tile.valueForKey(xkey).to_i
    y = tile.valueForKey(ykey).to_i
    at(x, y)
  end

  def self.at(x, y)
    BoardPosition.alloc.initAtX_andY(x, y)
  end

  def initAtX_andY(x, y)
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

