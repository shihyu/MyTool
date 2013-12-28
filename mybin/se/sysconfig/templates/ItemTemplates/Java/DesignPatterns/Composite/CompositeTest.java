/**
 * This class tests the classes in the Composite pattern.
 * 
 * @author $username$
 */
public class $safeitemname$CompositeTest {

    /**
     * Example of how the composite pattern can be used
     */
    public static void main(String args[]) {
	// create a root node
        $safeitemname$Composite root = new $safeitemname$Composite("Root");

	// create a composite child node and add it to the root
        $safeitemname$Composite sub1 = new $safeitemname$Composite("sub1");
        root.addComponent(sub1);
	// create a leaf child node and add it to the previous child
        $safeitemname$Leaf leaf1 = new $safeitemname$Leaf("leaf1");
        sub1.addComponent(leaf1);

	// create a second composite child node and add it to the root
        $safeitemname$Composite sub2 = new $safeitemname$Composite("sub2");
        root.addComponent(sub2);
	// create a leaf child node and add it to the previous child
        $safeitemname$Leaf leaf2 = new $safeitemname$Leaf("leaf2");
        sub2.addComponent(leaf2);

	// dump the contents of the tree
        root.dump();
    }
}
