import java.util.*;

/**
 * This class provides a standard implementation of the Leaf
 * class as part of the Composite design pattern.
 * 
 * @author $username$
 */
public class $safeitemname$Leaf extends $safeitemname$Component {

    /**
     * Constructor
     * 
     * @param aNodeName The name of the node being created
     */
    public $safeitemname$Leaf(String aNodeName) {
        _nodeName = aNodeName;
    }

    /**
     * Example of a member function that may be performed on either a
     * component or leaf node.
     * TODO: Rename and implement this operation
     */
    public void operation() {}

    /**
     * Dumps the contents of the Composite hierarchy, indenting
     * each level by the amount of space specified in padding.
     * 
     * @param padding A string containing the space to pad each indented level.
     */
    public void dump(String padding) {
        System.out.println(padding + "Leaf Node: " + _nodeName);
    }


}
