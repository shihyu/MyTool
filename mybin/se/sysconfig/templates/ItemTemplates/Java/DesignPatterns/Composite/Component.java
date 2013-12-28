import java.util.*;

/**
 * This class provides a standard implementation of the Component
 * class as part of the Composite design pattern.
 * 
 * @author $username$
 */
public abstract class $safeitemname$Component {

    /**
     * the name of the node
     */
    protected String _nodeName = "";
    /**
     * ArrayList of component (child) nodes
     */
    protected ArrayList<$safeitemname$Component> _componentList = new ArrayList();

    /**
     * Default constructor
     */
    public $safeitemname$Component() {
    }

    /**
     * Example of a member function that may be performed on either a
     * component or leaf node.
     * TODO: Rename and implement this operation
     */
    public void operation() {
    }

    /**
     * Adds a new child to the component
     * 
     * @param aComponent A new child to be added to the child collection
     */
    public synchronized void addComponent($safeitemname$Component aComponent) {
        _componentList.add(aComponent);
    }

    /**
     * Removes a specific child from the node
     * 
     * @param aComponent The child object to be removed from the child collection
     */
    public synchronized void removeComponent($safeitemname$Component aComponent) {
	// traverse the children
        for (Iterator<$safeitemname$Component> i = _componentList.iterator(); i.hasNext(); ) {
	    // determine if we've found the child
            if (i.next() == aComponent) {
		// if so, remove it
                i.remove();
            }
        }
    }

    /**
     * Returns the the child specified by index.
     * 
     * @param index The numeric index of the child to get: 0..n.
     * 
     * @return $safeitemname$Component The specified child.
     */
    public synchronized $safeitemname$Component getChild(int index){
        return _componentList.get(index);
    }


    /**
     * Dumps the contents of the Composite hierarchy.
     */
    public void dump() {
        System.out.println("\nContents of Composite hierarchy: ");
        dump("   ");
        System.out.println();
    }

    /**
     * Dumps the contents of the Composite hierarchy, indenting
     * each level by the amount of space specified in padding.
     * 
     * @param padding A string containing the space to pad each indented level.
     */
    public abstract void dump(String padding);
   
}
