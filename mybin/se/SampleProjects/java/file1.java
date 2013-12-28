/**
 * Sample project to show Context Tagging(R) and project support.
 * <P>
 * You need a Java development system installed (SUN's Java JDK works
 * well) and you must build a tag file for the run-time libraries.
 * Use the Automatic Tagging dialog box ("Search", "Tag Files...",
 * "Auto Tag...") to build a tag file for these run-time libraries.
 * This is the same dialog used by the install program.
 *
 * <ul>
 * <li>  Procs tab of Project toolbar.  Displays symbols in this file.
 *       Classes tab of Project toolbar (class browser).  Shows all
 *       symbols in the workspace (just this file in this case).
 *
 * <li>  Symbols tab of Output toolbar.  Shows symbol definition
 *       when you move the cursor over a symbol reference.
 *
 * <li>  Alt+Period lists members on demand.
 *
 * <li>  Alt+Comma displays function help on demand.
 *
 * <li>  Typing '.' lists members.
 *
 * <li>  Typing '(' displays parameter info.
 *
 * <li>  Ctrl+Shift+D displays the Javadoc editor used for creating and
 *       modifying Javadoc comments.
 *
 * <li>  Ctrl+Slash find symbol references for the symbol at the cursor.
 *       Ctrl+G (CUA emulation only) finds the next occurrence.
 *
 * <li>  Override a method using the "Override Method" menu item
 *       on the context menu (Right click).
 * </ul>
 */
public class file1 {
    public static void main (String args[]) {
        // Display something when this app executes
        System.out.println("Hello World!\n");
        // Feature: Auto List Members
        //
        // Type a period after "System" below and the members
        // of this class will be listed.
        //
        //  * To insert an item using the keyboard, select an item
        //    (change its color) and press Enter or a non-identifier
        //    character like '=', ';', '(', or ')'.  To select an item,
        //    use the arrow keys or start typing the name of a valid member.
        //  * To select an item with the mouse, double click on the
        //    item.
        //  * Press Esc to cancel the list.
        //
        System
            .gc();    // So we can compile, make this statement valid.


        // Feature: Auto Parameter Info
        //
        // Type an open parenthesis after "f1.method" below and
        // the members of this class will be listed.
        //
        // The javadoc comment for f1.method() and a list of
        // type compatible expressions is displayed.
        //
        // Press Ctrl+PgUp/Ctrl+PgDn to select overload of method().
        //
        // Click on the hypertext link to "java.lang.String.substring" to
        // go there.
        //
        file1 f1=new file1();
        f1.method
            (3);      // So we can compile, make this statement valid.


        // Feature: List Members on demand
        //
        // Place the cursor anywhere on the "string" member below
        // and press Alt+Period (Alt+'.').  Since the list displays
        // prefix matches, the cursor must be on the 's' to show
        // all members.
        //
        f1.string="test";

        // Feature: Parameter Info on demand
        //
        // Press Alt+Comma (Alt+',') inside argument list below.
        //
        f1.method( 3 );

        // Feature: Symbol References
        //
        // Place the cursor anywhere on the "string" member below
        // and press Ctrl+Slash (Ctrl+'/').  This will find all references
        // to the "string" member of class MYCLASS.  Press
        // Ctrl+G (CUA emulation only), to go to the next occurrence.
        //
        f1.string="test";

        // Feature: Javadoc editor
        //
        // Place the cursor on the UndocumentedMethod() below
        // and press Ctrl+Shift+D to try out the Javadoc editor.
        //

        // Feature: Override method
        //
        // Right Click on the comment text "Right Click Here", select
        // "Override Method" from the context menu, and select one or more
        // methods to override.
    }
    // Right Click Here
    void UndocumentedMethod(int i,String s) {

    }
    int i;
    String string;
    /**
     * Javadoc description for method() to illustrate HTML viewer
     * used by the Parameter Info feature.  Click on
     * the hypertext item under See Also to go there.
     *
     * @param i      Integer input parameter
     * @see java.lang.String#substring
     */
    void method(int i) {
    }
    /**
     * Javadoc description for method() to illustrate HTML viewer
     * used by the Parameter Info feature.  Click on
     * the hypertext item under See Also to go there.
     *
     * @param i      Integer input parameter
     * @param s      Input string parameter
     * @see java.lang.String#substring
     */
    void method(String s,int i) {
    }
}
