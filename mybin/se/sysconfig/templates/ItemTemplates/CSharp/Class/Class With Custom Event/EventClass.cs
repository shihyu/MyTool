using System;

namespace $rootnamespace$
{
	/**
     * Defines the custom arguments that will be sent when the 
     * On$eventname$ event is raised.
	 * 
     * @author   $username$
	 */
	public class $eventname$Args : EventArgs {
		// example class member message argument
		private string m_message;

        /**
         * Creates an instance of the custom event arguments for all 
         * On$eventname$ events.
		 * 
         * @param message The message argument for the event
		 */
		public $eventname$Args(string message) : base() {
			m_message = message;
		}

		/**
		 *  Message property (read-only)
		 */
		public string Message {
			get { return m_message; }
		}
	}

	/**
	 * TODO: Add class description
	 * 
	 * @author   $username$
	 */
	public class $safeitemname$
	{
		// On$eventname$ declaration
		public delegate void $eventname$Delegate(object sender, $eventname$Args e);
		public event $eventname$Delegate On$eventname$;

        /**
		 * Default constructor
		 */
		public $safeitemname$() {
			// TODO: Add constructor code here
		}

        /**
         * Function to automate raising the On$eventname$ event.
		 * 
         * @param message The message argument for the event
         */
		protected virtual void RaiseOn$eventname$(string msg)
		{
			// create a new instance of argument object
			$eventname$Args args = new $eventname$Args(msg);
			// make sure the event delegate is not null
			if (On$eventname$ != null)
			{
				// raise the event asynchronously
				//On$eventname$.BeginInvoke(this, args, null, null);
				// raise the event synchronously
				On$eventname$(this, args);
			}
		}


	}
}


