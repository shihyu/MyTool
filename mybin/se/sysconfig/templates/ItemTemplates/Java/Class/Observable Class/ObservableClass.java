import java.util.*;

/**
 * TODO: Add class description
 * 
 * @author   $username$
 */
public class $safeitemname$ extends Observable {
    /**
     * Defines the custom arguments that will be sent when the
     * $eventname$ event is raised.
     */
    public class $eventname$Arg {
	// example class member message argument
	private String _message;

	/**
	 * Creates an instance of the custom event arguments for all
         * update events.
         * 
         * @param message The message argument for the event
	 */
	public $eventname$Arg(String message) {
	    _message = message;
	}

	/**
	 * Message property (read-only)
	 * 
         * @return String The event's message
	 */
	public String getMessage() {
	    return _message;
	}
    }

    /**
     * Default constructor
     */
    public $safeitemname$() {
	// TODO: Add constructor code here
    }

    /**
     * Function to automate invoking the $eventname$ event.
     * 
     * @param msg The message argument for the event
     */
    protected void $eventname$Invoke(String msg) {
	// create a new instance of argument object
	$eventname$Arg arg = new $eventname$Arg(msg);
	// flag that the object has changed
	setChanged();
	// notify any observing objects
        notifyObservers(arg);
    }

}


