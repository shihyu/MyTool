/**
 * This class provides a basic implementation of the Singleton
 * pattern (Gamma et al). It ensures that only one isntance of
 * this class can be created.
 * 
 * @author $username$
 */
public class $safeitemname$ {

    /**
     * Member to hold the singleton instance.
     * TODO: Replace $safeitemname$ with the type of object you want to
     * return the single instance of
     */
    private static $safeitemname$ _instance = null;

    /**
     * Constructor: Declared private so that only this class can call it.
     */
    private $safeitemname$(){
       
    }

    /**
     * Method to retrieve the singleton instance. If an instance
     * does not exist, one will be created.
     * 
     * @return $safeitemname$ the instance.
     */
    public static $safeitemname$ getInstance() {
	// check if the instance has been created yet
        if (_instance == null) {
	    // if not, then create it
            _instance = new $safeitemname$();
        }
	// return the single instance
        return _instance;
    }


}
