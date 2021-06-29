#include <stdio.h>

/**
 * Sample project to show Context Tagging(R) and project support.
 * <P>
 * If you want Context Tagging to work for the C and C++
 * run-times use the Automatic Tagging dialog
 * box ("Search", "Tag Files...", "Auto Tag...") to build a tag
 * file for these run-time libraries. This is the same dialog
 * used by the install program.
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
 * <li>  Ctrl+Shift+D displays the Javadoc editor used for creating and modifying
 *       Javadoc comments.
 *
 * <li>  Ctrl+Slash finds symbol references for the symbol at the cursor.
 *       Ctrl+G (CUA emulation only) finds the next occurence.
 *
 * <li>  Classes tab of Project toolbar. Right click on a class and
 *       select one of the "Add ..." menu items to add member to a class.
 * </ul>
 */
class MYCLASS {
public:
    /**
     * Comment for i
     */
    int i;
    /**
     * Comment for 'str'
     */
    const char *str;
    void method(int i=1);
    void method(char *s,int i);
};

/**
 * Javadoc description for method() to illustrate HTML viewer
 * used by the Parameter Info feature.  Click on
 * the hypertext item under See Also to go there.
 *
 * @param i      Integer input parameter
 * @see MYCLASS
 * @see MYCLASS#i
 * @see MYCLASS#str
 */
void MYCLASS::method(int i) {
}
/**
 * Javadoc description for method() to illustrate HTML viewer
 * used by the Parameter Info feature.  Click on
 * the hypertext item under See Also to go there.
 *
 * @param i      Integer input parameter
 * @param s      Input string parameter
 * @see MYCLASS
 * @see MYCLASS#i
 * @see MYCLASS#str
 */
void MYCLASS::method(char *s,int i) {
}
int main(int argc, char* argv[])
{
    printf("Hello World!\n");  // Display something when this app executes
    MYCLASS c1;
    // Feature: Auto List Members
    //
    // Type a period after "c1" below and the members
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
    c1
       .i;       // So we can compile, make this statement valid.


    // Feature: Auto Parameter Info
    //
    // Type an open parenthesis after "c1.method" below and
    // the members of this class will be listed.
    //
    // The javadoc comment for c1.method() and a list of
    // type compatible expressions is displayed.
    //
    // Press Ctrl+PgUp/Ctrl+PgDn to select overload of method().
    //
    // Click on the hypertext link to "MYCLASS" to
    // go there.
    //
    c1.method
        (3);     // So we can compile, make this statement valid.


    // Feature: List Members on demand
    //
    // Place the cursor anywhere on the "str" member below
    // and press Alt+Period (Alt+'.').  Since the list displays
    // prefix matches, the cursor must be on the 's' to show
    // all members.
    //
    c1.str="test";

    // Feature: Parameter Info on demand
    //
    // Press Alt+Comma (Alt+',') inside argument list below.
    //
    c1.method( );

    // Feature: Javadoc editor
    //
    // Press Ctrl+Shift+D with the cursor on this comment to use our
    // Javadoc editor to document this function.
    //

    // Feature: Symbol References
    //
    // Place the cursor anywhere on the "str" member below
    // and press Ctrl+Slash (Ctrl+'/').  This will find all references
    // to the "str" member of class MYCLASS.  Press
    // Ctrl+G (CUA emulation only), to go to the next occurence.
    //
    c1.str="test";

    // Feature: Adding members to a class with the class browser
    //
    //   1. Make the class browser active by clicking on the Classes
    //      tab of Project toolbar (docked on the left by default).
    //   2. Open the Workspace folder.
    //   3. Open the Classes folder.
    //   4. Right click on MYCLASS to display the context menu.
    //   5. Choose "Add Member Function..."
    //   6. Enter a valid C++ function declaration and press Enter.
    //
    // Notice that this adds a function prototype and a function
    // declaration.

    // done.
    return(0);
}

