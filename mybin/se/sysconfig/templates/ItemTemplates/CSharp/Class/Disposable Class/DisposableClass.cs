using System;

namespace $rootnamespace$
{
	/**
	 * TODO: Add class description
	 * 
	 * @author   $username$
	 */
	public class $safeitemname$ : IDisposable
	{
        /**
		 * Default constructor
		 */
		public $safeitemname$() {
			// TODO: Add constructor code here
		}

        /**
         * Destructor
         */
		~$safeitemname$() {
            // TODO: A destructor is costly to the garbage collection process
            // and should only be implemented if your class references 
            // unmanaged resources.  If not, remove the destructor.
			Dispose(false);
		}

        /**
         * Implementation of Dispose that is called internally when the 
         * object is disposed manually by the application.
		 * 
         * @param disposing  A flag indicating whether the function is 
         *                   being called manually (true) or by the
         *                   garbage collector via the destructor 
         *                   (false).
         */
		protected virtual void Dispose(bool disposing) {
            // If disposing equals false, the method has been called by the
            // runtime from inside the finalizer and you should not reference 
            // other objects. Only unmanaged resources can be disposed.
			if (disposing == true)
			{
				// free your managed resources here
			}
			// free your unmanaged resources here
		}

        /**
         * Implementation of Dispose that may be called manually by the
         * application.
		 */
		public void Dispose() {
			// call the internal Dispose manually to free the object's resources
			Dispose(true);
			// tell the garbage collector to take this object off the finalization
			// queue and prevent finalization code for this object from executing 
			// a second time.
			GC.SuppressFinalize(this);
		}

	}
}


