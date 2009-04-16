require 'constants'
require 'TilesView'

class TilePuzzleAppDelegate < OSX::NSObject
  include OSX

  ib_outlet :window, :puzzle, :view
  
  # This is misleading. It looks like an action called from UI,
  # but it's only called internally.
  def saveAction(sender)
    puts "In save action"
    retval, error = @puzzle.managedObjectContext.save_
    if retval == 0
      NSApplication.sharedApplication.presentError(error)
    end
  end

  def windowWillReturnUndoManager(sender)
    @puzzle.managedObjectContext.undoManager
  end

  def windowWillClose(notification)
    saveAction(self)
  end

  def applicationShouldTerminateAfterLastWindowClosed
    true
  end

  def applicationShouldTerminate(sender)
    reply = NSTerminateNow
    return reply unless @puzzle.managedObjectContext  # This should be impossible.
    if @puzzle.managedObjectContext.commitEditing
      result, error = @puzzle.managedObjectContext.save_  # _ required because name of method is "save:"
      unless result
        errorResult = NSApplication.sharedApplication.presentError(error)
        if errorResult
          reply = NSTerminateCancel
        else
          alertReturn = NSRunAlertPanel(nil, "Could not save changes while quitting. Quit anyway?", "Quit anyway", "Cancel", nil)
          reply = NSTerminateCancel if alertReturn == NSAlertAlternateReturn
        end
      end
    else
      reply = NSTerminateCancel
    end
    reply
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
