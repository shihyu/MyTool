using System;

namespace $rootnamespace$
{
	/**
	 * TODO: Add class description
	 * 
	 * @author   $username$
	 */
	public class $safeitemname$ {
		// private static member referencing the single instance of the object
		// TODO: Replace $safeitemname$ with the type of object you want to
		// return the single instance of
		private static $safeitemname$ _instance;

		/**
		 * Constructor: Declared private so that only this class can call it.
		 */
		private $safeitemname$() {
			// TODO: Add constructor code here
		}

        /**
         * Returns the single instance of the object.
		 */
		public static $safeitemname$ Instance {
			get {
				// check if the instance has been created yet
				if(_instance == null) {
					// if not, then create it
					_instance = new $safeitemname$();
				}
				// return the single instance
				return _instance;
			}
		}
	}

}
