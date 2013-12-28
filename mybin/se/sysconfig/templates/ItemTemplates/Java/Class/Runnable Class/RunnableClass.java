/**
 * TODO: Add class description
 * 
 * @author   $username$
 */
public class $safeitemname$ implements Runnable {
    /**
     * Internal thread object.  This is optional if the the managing thread
     * is handled externally.
     */
    private Thread _thread;

    /**
     * Default constructor
     */
    public $safeitemname$() {
	// create the thread and pass this object to it
	_thread = new Thread(this);
	// TODO: Add constructor code here
    }

    /**
     * Make the thread start running
     */
    public void start() {	
	_thread.start();
    }

    /**
     * Make the thread stop running
     */
    public void stop() {	
	_thread.stop();
    }

    /**
     * Implementation of Runnable.run
     */
    public void run()
    {
	// TODO: Add code here to be run in the worker thread
    }

}


