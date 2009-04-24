require 'constants'
require 'TilesView'

class TilePuzzleAppDelegate < OSX::NSObject
  include OSX

  ib_outlet :window, :puzzle, :view
  
  def windowWillReturnUndoManager(sender)
    @puzzle.undo_manager
  end

  def windowWillClose(notification)
    @puzzle.save
  end

  def applicationShouldTerminateAfterLastWindowClosed
    true
  end

  def applicationShouldTerminate(sender)
    return NSTerminateNow unless @puzzle # Died in initialization.
    @puzzle.finish_pending_user_edits
    @puzzle.save
    NSTerminateNow
  end

  def shuffle(sender)
    @puzzle.shuffle
    @window.display
  end

  def showSolution(sender)
    @view.user_wants_to_see_solution
    @window.display
  end
end

