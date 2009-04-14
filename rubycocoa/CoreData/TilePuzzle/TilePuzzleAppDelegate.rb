require 'constants'
require 'TilesView'

module OSX
class TilePuzzleAppDelegate
  def init
    super_init
    isShowingSolution = false
    imagePath = NSBundle.mainBundle.pathForImageResource(PuzzleImageName)
    puzzleImage = NSImage.alloc.initWithContentsOfFile(imagePath)
    self
  end
end
end
