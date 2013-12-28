#include "$safeitemname$.h"

$safeitemname$* $safeitemname$::_instance = 0;

/**
 * Returns the single instance of the object.
 */
$safeitemname$* $safeitemname$::getInstance() {
	// check if the instance has been created yet
    if (0 == _instance) {
		// if not, then create it
        _instance = new $safeitemname$;
    }
	// return the single instance
    return _instance;
};


