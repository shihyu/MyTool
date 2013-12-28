using System;
using System.Collections.Generic;

namespace $rootnamespace$
{
	/**
     * The delegate used during the traversal of the items in the
     * composite tree structure
	 */
	public delegate void Enum$safeitemname$Callback(I$safeitemname$ child);

	/**
     * The interface that defines the elements that make up the
     * composite tree structure
	 */
	public interface I$safeitemname$ {
		/**
         * Example of a member function that may be performed on either a
         * composite or component node.
         * TODO: Rename and implement operations in the Composite and
         * Component classes
		 */
		void MemberFunction();

		/**
         * Example of a numeric property that may be get or set on either a
         * composite or component node.
		 */
		int NumberProperty {
			get;
			set;
		}

		/**
         * Adds a new child to the node
		 * 
         * @param child A new child to be added to the child collection
		 * 
		 * @return The number of children owned by this object
		 */
		int AddChild(I$safeitemname$ child);

		/**
         * Removes a specific child from the node
		 * 
         * @param child The child object to be removed from the child
         *              collection
		 * 
		 * @return The number of children owned by this object
		 */
		int RemoveChild(I$safeitemname$ child);

		/**
         * Property to return the enumerator for the node's immediate 
         * children.
		 * 
         * @returns The enumerator for the child collection
		 */
		IEnumerator<I$safeitemname$> Children {
			get;
		}

		/**
         * Traverses the immediate children of the node and sends them to 
         * the caller via the Enum$safeitemname$Callback delegate
		 * 
         * @param callback A handler for the Enum$safeitemname$Callback
         *                 delegate
		 */
		void EnumChildren(Enum$safeitemname$Callback callback);
	   
		/**
         * Recursively traverses all children underneath the node and
         * sends them to the caller via the Enum$safeitemname$Callback
         * delegate.
		 * 
		 * @param callback A handler for the Enum$safeitemname$Callback
		 *                 delegate
		 */
		void EnumDescendants(Enum$safeitemname$Callback callback);
	}

	/**
     * The component class that implements the I$safeitemname$ 
     * interface.  Objects of this type are considered leaves in the
     * tree and may NOT have children.
	 */
	public class $safeitemname$Component : I$safeitemname$ {
		// example number property member
		private int _NumberPropertyValue;

		#region I$safeitemname$ implementation

		/**
         * Example member function implementation
		 */
		public void MemberFunction() {
			// TODO: Add code to implement the member function
		}

		/**
         * Implementation of the NumberProperty property
		 */
		public int NumberProperty {
			get { return _NumberPropertyValue; }
			set {_NumberPropertyValue = value; }
		}

		/**
         * AddChild has no implementation in the component class
		 */
		public int AddChild(I$safeitemname$ child) {
			return 0;
		}

		/**
         * RemoveChild has no implementation in the component class
		 */
		public int RemoveChild(I$safeitemname$ child) {
			return 0;
		}

		/**
         * A component has no children, so return null
		 */
		public IEnumerator<I$safeitemname$> Children {
			get { return null;	}
		}

		/**
         * Because a component has no children, this function requires no
         * implementation
		 */
		public void EnumChildren(Enum$safeitemname$Callback callback) {}

		/**
         * Because a component has no children, this function requires no
		 * implementation
		 */
		public void EnumDescendants(Enum$safeitemname$Callback callback) {}

		#endregion
	}

	/**
     * The composite class that implements the I$safeitemname$
     * interface.  Objects of this type are considered nodes in the 
     * tree and may have children.
	 */
	public class $safeitemname$Composite : I$safeitemname$ {
		// List of I$safeitemname$ subordinate (child) nodes
		protected List<I$safeitemname$> _subordinates;

		#region Composite implementation

		/**
		 * Default constructor
		 */
		public $safeitemname$Composite() {
			_subordinates = new List<I$safeitemname$>();
		}

		/**
         * Constructor
		 * 
         * @param capacity Allows for preallocation of an expected 
         *                 number of children
		 */
		public $safeitemname$Composite(int capacity) {
			// create the child array list
			_subordinates = new ArrayList(capacity);
		}

		#endregion

		#region I$safeitemname$ implementation

		/**
         * Example member function implementation.  Simply forwards
		 * the call to the child objects.
		 */
		public void MemberFunction() {
			// traverse the children
			foreach (I$safeitemname$ m in _subordinates) 
			{
				// call the function on each child
				m.MemberFunction();
			}
		}

		/**
		 * Example number property implementation.  Simply gets the number 
		 * property from each child object and adds them.
		 * 
		 * @return The sum of all numbers contained in the leaves under 
		 *         this node in the composite tree.
		 */
		public int NumberProperty {
			get { 
				int sum = 0;
				// traverse the children
				foreach (I$safeitemname$ m in _subordinates) {
					// sum their values
					sum += m.NumberProperty;
				}
				return sum;
			}
			set {}
		}

		/**
		 * Adds a new child to the node
		 * 
		 * @param child A new child to be added to the child collection
		 * 
		 * @return The number of children owned by this object
		 */
		public int AddChild(I$safeitemname$ child) {
			return _subordinates.Add(child);
		}

		/**
		 * Removes a specific child from the node
		 * @param child The child object to be removed from the child
		 *              collection
		 * 
		 * @return The number of children owned by this object
		 */
		public int RemoveChild(I$safeitemname$ child) {
			_subordinates.Remove(child);
            return _subordinates.Count;
		}

		/**
		 * Property to return the enumerator for the node's immediate 
		 * children.
		 * 
		 * @returns The enumerator for the child collection
		 */
		public IEnumerator<I$safeitemname$> Children {
			get {
				return _subordinates.GetEnumerator();
			}
		}

		/**
		 * Traverses the immediate children of the node and sends them to 
		 * the caller via the Enum$safeitemname$Callback delegate
		 * 
		 * @param callback A handler for the Enum$safeitemname$Callback
		 *                 delegate
		 */
		public void EnumChildren(Enum$safeitemname$Callback callback) {
			// make sure the delegate isn't null
			if (callback != null) {
				// traverse the children
				foreach (I$safeitemname$ m in _subordinates) {
					// callback the reference to each one
					callback(m);
				}
			}
		}

		/**
		 * Recursively traverses all children underneath the node and
		 * sends them to the caller via the Enum$safeitemname$Callback
		 * delegate.
		 * 
		 * @param callback A handler for the Enum$safeitemname$Callback
		 *                 delegate
		 */
		public void EnumDescendants(Enum$safeitemname$Callback callback) {
			// make sure the delegate isn't null
			if (callback != null) {
				// traverse the children
				foreach (I$safeitemname$ m in _subordinates) {
					// have the current child call back all of it's children
					m.EnumDescendants(callback);
					// callback the reference to the current child
					callback(m);
				}
			}
		}

		#endregion
	}
}
