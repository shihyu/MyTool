////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50292 $
////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc. 
// You may modify, copy, and distribute the Slick-C Code (modified or unmodified) 
// only if all of the following conditions are met: 
//   (1) You do not include the Slick-C Code in any product or application 
//       designed to run independently of SlickEdit software programs; 
//   (2) You do not use the SlickEdit name, logos or other SlickEdit 
//       trademarks to market Your application; 
//   (3) You provide a copy of this license with the Slick-C Code; and 
//   (4) You agree to indemnify, hold harmless and defend SlickEdit from and 
//       against any loss, damage, claims or lawsuits, including attorney's fees, 
//       that arise or result from the use or distribution of Your application.
////////////////////////////////////////////////////////////////////////////////////
/*
   The Slick-C(R) macro compiler CAN NOT COMPILE this file.

   We use this file to add prototypes for Slick-C(R)
   language functions to enhance Context Tagging(R) for
   Slick-C(R).
*/

const boolean true=true;
const boolean false=false;

/**
 * The multiple document interface (MDI).  This object is the form
 * that is instantiated as the main form of the editor.
 */
_mdi_form _mdi;

/**
 * The text box control representing the SlickEdit command line.
 */
_text_box _cmdline;

   /**
    * @return
    * Returns VF_??? constant defined in "slick.sh" which indicates the
    * current storage format of a variable (often not the same as declaration
    * type).  We DO NOT recommend you use this function because its return
    * values are likely to change with the next version of Slick-C&reg;.
    * This function is currently only intended for use by the developers
    * of SlickEdit and Slick-C&reg;.
    *
    * @example
    * <PRE>
    * t=1;
    * messageNwait("varformat="t._varformat());
    * </PRE>
    *
    *
    * @see _el
    * @see _makeempty
    * @see _isempty
    * @see _deleteel
    * @see _nextel
    * @see _indexin
    * @see _sort
    *
    * @categories Miscellaneous_Functions
    *
    */
   int _varformat();

   /**
    * @return
    * This method operates on _str, array ( [] ) , hash table ( :[] ) , struct,
    * and union types.  Returns true if variable does not yet point to anything.
    * This function is very specific to the required implementation of Slick-C&reg;.
    * The changes we plan to make in the future will not effect this function.
    *
    * @example
    * <pre>
    * t:["a"]=1;
    * t:["b"]=2;
    * t:["c"]=3;
    * // Traverse the elements in hash table
    * for (i._makeempty();;) {
    *    t._nextel(i);
    *    if (i._isempty()) break;
    *    messageNwait("index="i" value="t:[i]);
    * }
    * </pre>
    *
    * @see help:Arrays
    * @see help:Hash Tables
    * @see _makeempty
    * @see _varformat
    *
    * @categories Miscellaneous_Functions
    *
    */
   boolean _isempty();
   /**
    * This method operates on _str, array ( [] ) , hash table ( :[] ) , struct,
    * and union types.  Sets variable to point to nothing.  Slick-C&reg; allocates
    * spaces for the variable when an assignment is made.  This function is very
    * specific to the required implementation of Slick-C&reg;.  The changes we plan
    * to make in the future will not effect this function.
    *
    * @example
    * <pre>
    * t:["a"]=1;
    * t:["b"]=2;
    * t:["c"]=3;
    * // Traverse the elements in hash table
    * for (i._makeempty();;) {
    *    t._nextel(i);
    *    if (i._isempty()) break;
    *    messageNwait("index="i" value="t:[i]);
    * }
    * </pre>
    *
    * @see help:Arrays
    * @see help:Hash Tables
    * @see _isempty
    * @see _varformat
    *
    * @categories Miscellaneous_Functions
    *
    */
   void _makeempty();

   /** 
    * Inserts an element into an array or hash table. 
    * This method is not necessary for hash tables, but very useful 
    * for inserting into an array and shifting the the array items 
    * correctly.  It also allows you to specify a number of items, 
    * so you can use this method to effeciently initialize an array. 
    * Nofitems defaults to 1.
    *  
    * @param value      value to insert into the array 
    * @param index      index / key corresponding to item to insert
    * @param Nofitems   number of items to insert (arrays only)
    *
    * @example
    * <pre>
    * t[0]=1;
    * t[1]=2;
    * t[2]=3;
    * t._insertel(4,1,2);  // t = {1,4,4,2,3} 
    * </pre>
    *
    * @see _el 
    * @see _deleteel 
    * @see _nextel
    * @see _makeempty
    * @see _isempty
    * @see _varformat
    * @see _indexin
    * @see _sort
    *
    * @categories Miscellaneous_Functions
    */
   void _insertel(typeless value,typeless index,int Nofitems= 1);

   /**
    * Deletes element from hash table or array variable.  Nofitems specifies
    * the number of elements to delete and is ignored for hash table variables.
    * Nofitems defaults to 1.
    *
    * @param index      index / key corresponding to item to delete
    * @param Nofitems   number of items to delete
    *
    * @example
    * <pre>
    * t[0]=1;
    * t[1]=2;
    * t[2]=3;
    * t._deleteel(1);   // Delete t[1].  t[1] will now contain 3 
    * t:["a"]=1;
    * t._deleteel("a");  // Delete "a" element
    * </pre>
    *
    * @see _el
    * @see _nextel
    * @see _makeempty
    * @see _isempty
    * @see _varformat
    * @see _indexin
    * @see _sort
    *
    * @categories Miscellaneous_Functions
    */
   void _deleteel(typeless index,int Nofitems= 1);
   /** 
    * _nextel() is the Slick-C intrinsic function behind the 
    * Slick-C "foreach" statement. 
    *  
    * @return
    * Returns reference to next element in array or hash table.  If index is
    * empty (see _makeempty()), the first element is returned.  If there are no
    * more elements, index is set to empty.  See example below.
    * <p> 
    * For Slick-C classes that implement IIterable, _nextel() will 
    * call the class-specific _nextel() method. 
    * <p> 
    * For strings, _nextel() will parse out the next (possibly 
    * quoted) filename in the string, stripping whitespace. 
    * It will not strip quotes. 
    *
    * @param index      index / key to find next duplicate of
    *
    * @example
    * <pre>
    * t:["a"]=1;
    * t:["b"]=2;
    * t:["c"]=3;
    * // Traverse the elements in hash table
    * for (i._makeempty();;) {
    *     t._nextel(i);
    *     if (i._isempty()) break;
    *     messageNwait("index="i" value="t:[i]);
    * }
    * // Traverse the elements using 'foreach'
    * foreach (i => v in t) {
    *     messageNwait("index="i" value="v);
    * }
    * </pre>
    *
    * @see _el
    * @see _makeempty
    * @see _isempty
    * @see _deleteel
    * @see _varformat
    * @see _indexin
    * @see _sort
    *
    * @categories Miscellaneous_Functions
    *
    */
   typeless &_nextel(typeless &index);
   /**
    * @return
    * Returns a reference to an element in a hash table or array.
    * <p>
    * NOTE: For backwards compatibility, this function will also work
    * for structs and class instances, returning a reference to the
    * given field (specified by field index, see {@link _fieldindex}).
    * This use of _el() is discouraged.
    *
    * @param index      index / key correspond to item to return.
    *
    * @example
    * <pre>
    * t[0]=1;
    * t._el(0)=4;       //  Same as t[0]=4;
    * p= &t._el(0);     // Get a pointer to t[0] element
    * *p=5;             // Same as t[0]=5;
    * messageNwait("t[0]="t._el(0));
    * </pre>
    *
    * @see _deleteel
    * @see _nextel
    * @see _makeempty
    * @see _isempty
    * @see _varformat
    * @see _indexin
    * @see _sort
    * @see _length
    * @categories Miscellaneous_Functions
    */
   typeless &_el(typeless index);

   /**
    * @return
    * Returns last element in an array.  Equivalent to 
    * ar[ar._length() - 1].
    *
    * @example
    * <pre>
    * t[0]=1;
    * t[1]=2;
    * t[2]=3;
    * i = t._lastel();   // returns t[2]
    * </pre>
    *
    * @see _deleteel
    * @see _nextel
    * @see _makeempty
    * @see _isempty
    * @see _varformat
    * @see _indexin
    * @see _sort
    * @see _length
    * @categories Miscellaneous_Functions
    */
   typeless &_lastel();

   /**
    * Sorts an array.
    *
    * @param options
    *    options may contain one or more of the following option letters:
    *    <dl compact>
    *    <dt><b>D</b> <dd>Descending.  When not specified sort is ascending.
    *    <dt><b>I</b> <dd>Ignore case.  Default is case sensitive.
    *    <dt><b>N</b> <dd>Sort numbers.  Supports floating point.
    *    <dt><b>F</b> <dd>Sort filenames.
    *    </dl>
    * @param start      array index to start sorting at
    * @param Nofitems   number of items to sort
    *
    * @return int
    *
    * @example
    * <pre>
    * a[0]="def";
    * a[1]="abc";
    * // Sort array of strings in ascending order.
    * a._sort();
    * </pre>
    *
    * @see _el
    * @see _makeempty
    * @see _isempty
    * @see _deleteel
    * @see _nextel
    * @see _indexin
    * @see _varformat
    *
    * @categories Miscellaneous_Functions
    *
    */
   int _sort(_str options="",start=0,int Nofitems= -1);
   /**
    * @return Returns the number of elements in the given variable.
    * <ul>
    * <li>array -- the number of elements in the array
    * <li>hash table -- the number of items in the hash table
    * <li>struct or class instance -- the number of fields
    * <li>string -- the length of the string
    * </ul>
    *
    * @example
    * <pre>
    * int a[];
    * a[0]=1;
    * a[1]=2;
    * messageNwait("Number of elements="a._length());
    * </pre>
    *
    * @categories Miscellaneous_Functions
    */
   int _length();

   /**
    * @return
    * Returns non-zero pointer to element if element exists at index given.
    *
    * @param index      index or key corresponding to item to look for
    *
    * @example
    * <pre>
    * defmain()
    * {
    *     typeless a:[];
    *     a:['sdf']._makeempty();  // a._indexin('sdf') will be false
    *
    *     a:['key1']=5;         // a._indexin('key1') will be true
    * }
    * </pre>
    *
    * @see _el
    * @see _nextel
    * @see _makeempty
    * @see _isempty
    * @see _varformat
    * @see _indexin
    * @see _sort
    *
    * @categories Miscellaneous_Functions
    */
   typeless *_indexin(_str index);

   /**
    * @return For a given Slick-C variable, return the name of it's
    * type, as currently seen by the interpreter.
    * <p>
    * This function works with Slick-C classes, arrays, hash tables,
    * and strings.  It is unable to distinguish between integers,
    * booleans, and enumerated types.
    * 
    * @example
    * <pre>
    * class AAAA { int x; int y; };
    * void sayAAAA() {
    *    AAAA a;
    *    say(a._typename());
    * }
    * </pre>
    * 
    * @see _instanceof
    * @see _construct
    *
    * @categories Miscellaneous_Functions
    */
   _str _typename();

   /**
    * @return Return <code>true</code> if the given class is an instance
    * of the named class.  Note that it is preferable to use the
    * "instanceof" operator instead of this builtin wherever possible.
    * 
    * @param typeName   String containing name of type to test.
    * 
    * @example
    * <pre>
    * class AAAA { int x; int y; };
    * class BBBB : AAAA { int z; };
    * class CCCC { _str ch; };
    * void testInstanceOf() {
    *    AAAA a;
    *    BBBB b;
    *    CCCC c;
    *    true1  := b._instanceof("AAAA");  // BBBB inherits from AAAA
    *    true2  := b._instanceof("BBBB");  // b._typename() = BBBB
    *    false1 := b._instanceof("CCCC");  // no relation to CCCC
    *    false2 := b._instanceof("DDDD");  // no such class DDDD
    * }
    * </pre>
    * 
    * @see _typename
    * @see _construct
    *
    * @categories Miscellaneous_Functions
    */
   boolean _instanceof(_str typeName);

   /**
    * Construct an instance of the specified type and pass the 
    * given arguments to it's constructor.  Will make the
    * instance 'null', like _makeempty(), if <code>className</code> 
    * is not a known Slick-C class type.
    * <p>
    * This class is useful for dynamically creating class instances.
    * It does not actually allocate memory, it just initializes the
    * variable it operates on.  On account of this, Slick-C has no
    * need for a "delete" or _destruct() operator.
    * 
    * @param className  Name of class to construct
    * @param argument1  first argument for constructor
    * @param argument2  second argument for constructor
    *
    * @example
    * <pre>
    * class AAAA { 
    *    int x; int y;
    *    AAAA(int ax=0, int ay=0) { 
    *       x=ax; 
    *       y=ay; 
    *    } 
    * };
    * AAAA AFactory(int x, int y) {
    *    AAAA r = null;
    *    r._construct("AAAA", x, y);
    *    return r;
    * }
    * </pre>
    * 
    * @see _typename
    * @see _instanceof
    * @see _makeempty
    *
    * @categories Miscellaneous_Functions
    */
   void _construct(_str className, ...);

   /**
    * @return Returns the index of the given given class field.
    *         Indexes start at zero for the first field of the
    *         base (least derived) class.
    * 
    * @param fieldName  Name of field to look up.
    * 
    * @example
    * <pre>
    * class AAAA { int x; int y; };
    * class BBBB : AAAA { int z; };
    * void testFieldIndex() {
    *    BBBB b;
    *    say("x is at position "b._fieldindex("x"));  // 0
    *    say("y is at position "b._fieldindex("y"));  // 1
    *    say("z is at position "b._fieldindex("z"));  // 2
    * }
    * </pre>
    * 
    * @see _getfield
    * @see _fieldindex
    * @see _length
    * @see _setfield
    *
    * @categories Miscellaneous_Functions
    */
   int _fieldindex(_str fieldName);

   /**
    * @return Returns the name of the given given class field.
    *         Indexes start at zero for the first field of the
    *         base (least derived) class.
    * 
    * @param index   position of field to look up.
    * 
    * @example
    * <pre>
    * class AAAA { int x; int y; };
    * class BBBB : AAAA { int z; };
    * void testFieldName() {
    *    BBBB b;
    *    say("field 0 is named "b._fieldname(0));  // x
    *    say("field 1 is named "b._fieldname(1));  // y
    *    say("field 2 is named "b._fieldname(2));  // z
    * }
    * </pre>
    *
    * @see _getfield
    * @see _fieldindex
    * @see _length
    * @see _setfield
    *
    * @categories Miscellaneous_Functions
    */
   _str _fieldname(int index);

   /**
    * @return Return a reference to the given class field.
    *         Fields may be specified either by name or by
    *         index (see {@link _fieldindex}).  
    *         This function pays no attention to field 
    *         visibility (private or protected).
    * 
    * @param indexOrName   Name or position of field
    * 
    * @example
    * <pre>
    * class AAAA { int x; int y; };
    * class BBBB : AAAA { int z; };
    * void testGetField() {
    *    BBBB b;
    *    b.x = 0;
    *    b.y = 1;
    *    b.z = 2;
    *    int zero = b._getfield("x");
    *    int one  = b._getfield(1);
    *    int two  = b._getfield("z");
    *    b._getfield(0) = 10;
    *    int ten  = b._getfield("x");
    * }
    * </pre>
    * 
    * @see _fieldindex
    * @see _fieldname
    * @see _length
    * @see _setfield
    *
    * @categories Miscellaneous_Functions
    */
   typeless _getfield(_str indexOrName);

   /**
    * Set the value of a class field.
    * Fields may be specified either by name or by
    * index (see {@link _fieldindex}).  
    * This function pays no attention to field 
    * visibility (private or protected).
    * 
    * @param indexOrName   Name or position of field
    * @param value         value to set field to
    * 
    * @example
    * <pre>
    * class AAAA { int x; int y; };
    * class BBBB : AAAA { int z; };
    * void testSetField() {
    *    BBBB b;
    *    b._setfield("x", 0); // b.x = 0;
    *    b._setfield("y", 1); // b.y = 1;
    *    b._setfield(2, 2);   // b.z = 2;
    * }
    * </pre>
    * 
    * @see _getfield
    * @see _fieldindex
    * @see _fieldname
    * @see _length
    *
    * @categories Miscellaneous_Functions
    */
   void _setfield(_str indexOrName, typeless value);

   /**
    * @return Return the names table index of the given class method.
    * 
    * @param methodName    name of the method to look up
    * 
    * @example
    * <pre>
    * class AAAA {
    *    void saySomething() {
    *       message("something");
    *    }
    * };
    * int testFindMethod(_str name) {
    *    AAAA a;
    *    return a._findmethod(name);
    * }
    * </pre>
    * 
    * @see _callmethod
    * @see find_index
    * @see index_callable
    *
    * @categories Miscellaneous_Functions
    */
   int _findmethod(_str methodName);

   /**
    * Call the given class method and return it's result.
    * 
    * @param indexOrName   Name or names table index of method to call.
    * @param argument1     first argument for method
    * @param argument2     second argument for method
    * 
    * @return Returns the return value of the given method.
    * 
    * @example
    * <pre>
    * class AAAA {
    *    void saySomething() {
    *       message("something");
    *    }
    * };
    * int testCallMethod() {
    *    AAAA a;
    *    a._callmethod("saySomething");
    *    index := a._findmethod("saySomething");
    *    if (index_callbale(index)) {
    *       a._callmethod(index);
    *    }
    * }
    * </pre>
    * 
    * @see _findmethod
    * @see call_index
    *
    * @categories Miscellaneous_Functions
    */
   typeless _callmethod(_str indexOrName, ...);

   /**
    * Whether the tab control features an arrow button which, when clicked, 
    * reveals a drop down list containing the names of all the tabs in 
    * alphabetical order. 
    *
    * @appliesTo SSTab
    * @categories SSTab_Properties
    */
   int p_DropDownList;

   /**
    * Determines the first active tab when a form is displayed.
    *
    * @appliesTo SSTab
    * @categories SSTab_Properties
    */
   int p_FirstActiveTab;

   /**
    * Currently active beautifier configuration.
    */
   _str p_BeautifierCfg[]; 

   /**
    * Set to true to dynamically reduce the size of each tab if
    * they do not fit on the tab row. Scroll buttons are displayed 
    * when tabs have been reduced as much as possible. 
    *
    * @appliesTo SSTab
    * @categories SSTab_Properties
    */
   boolean p_BestFit;

   /**
    * Set to true to allow moving tabs with the mouse. 
    *
    * @appliesTo SSTab
    * @categories SSTab_Properties
    */
   boolean p_MovableTabs;

   /**
    * Set to true to allow scroll-wheel events to change current 
    * tab index. 
    *
    * @appliesTo SSTab
    * @categories SSTab_Properties
    */
   boolean p_AllowScrollWheel;

   /**
    * Set to true to show close buttons on individual tabs.  When
    * one of these buttons is clicked, an on_change event is thrown
    * with the CHANGE_TAB_CLOSE_BUTTON_CLICKED argument.  The
    * on_change event is responsible for closing the tab.
    *
    * @appliesTo SSTab, MDI_Window
    * @categories SSTab_Properties, MDI_Window_Properties
    */
   boolean p_ClosableTabs;

   /**
    * Determines the number of tabs. You may not use this property 
    * to delete tabs.  However, you may use this property to add 
    * tabs.  Use the {@link _deleteActive} method to delete the 
    * active tab. 
    *
    * @appliesTo SSTab
    * @categories SSTab_Properties
    */
   int p_NofTabs;

   /**
    * <P><b>SSTab Control</b> - Determines whether the tabs are 
    * displayed on the top, bottom, left, or right of the SSTab 
    * control. This property may be one of the following: 
    * <UL>
    * <LI>SSTAB_OTOP
    * <LI>SSTAB_OBOTTOM
    * <LI>SSTAB_OLEFT
    * <LI>SSTAB_ORIGHT
    * </UL>
    *
    * <P><b>Image</b> - Determines how the picture and caption are oriented.
    * This property may be one of the following:
    * <UL>
    * <LI>PSPIC_OHORIZONTAL - caption (if any) is positioned just right of picture
    * <LI>PSPIC_OVERTICAL - caption (if any) is rotated 90 degrees clockwise and positioned just below picture
    * </UL>
    *
    * @appliesTo SSTab, Image
    * @categories SSTab_Properties, Image_Properties
    */
   int p_Orientation;

   /**
    * Determines whether the tabs only display pictures and not captions.
    * When <b>true</b>, captions are display as tool tip help.
    *
    * @appliesTo SSTab
    * @categories SSTab_Properties
    */
   boolean p_PictureOnly;

   /**
    * Set to true to hide the tab row of a tab control. The tab row
    * is not hidden by default. 
    *
    * @appliesTo SSTab
    * @categories SSTab_Properties
    */
   boolean p_HideTabRow;

   /**
    * Set to true to display tab control in document-mode (no 
    * border). Document-mode is off by default. 
    *
    * @appliesTo SSTab
    * @categories SSTab_Properties
    */
   boolean p_DocumentMode;

   /**
    * Determines the caption for the active tab.
    *
    * @appliesTo SSTab
    * @categories SSTab_Properties
    *
    */
   _str p_ActiveCaption;

   /**
    * Determines the color to draw the caption for the current tab.
    *
    * @categories SSTab_Properties
    * @appliesTo SSTab
    */
   int p_ActiveColor;

   /**
    * Determines whether the active tab is enabled.  When a tab is disabled,
    * the user can not switch to this tab via keyboard or mouse. Use the
    * <b>_setEnabled</b> method instead of this property when setting
    * enabled state of a non-active tab.
    *
    * @appliesTo SSTab
    * @categories SSTab_Properties
    *
    */
   boolean p_ActiveEnabled;

   /**
    * Determines the help for the active tab.  See <b>p_help</b> property
    * for syntax of help string.
    *
    * @appliesTo SSTab
    * @categories SSTab_Properties
    *
    */
   _str p_ActiveHelp;

   /**
    * Determines the order in which the tabs are displayed.  The first tab is
    * 0. Set to -1 to move tab to end. 
    *
    * @appliesTo SSTab
    * @categories SSTab_Properties
    *
    */
   int p_ActiveOrder;

   /**
    * Determines the picture displayed to the left of the caption for the
    * active tab.  Set this to 0 for no picture.
    *
    * @appliesTo SSTab
    * @categories SSTab_Properties
    *
    */
   int p_ActivePicture;

   /**
    * The active tab-index. Set to -1 to activate the last tab.
    *
    * @appliesTo SSTab
    * @categories SSTab_Properties
    *
    */
   int p_ActiveTab;

   /**
    * The tooltip text for the active tab.
    *
    * @categories SSTab_Properties
    * @appliesTo SSTab
    */
   int p_ActiveToolTip;

   /** 
    * Returns a value representing the adaptive formatting settings
    * which have already been obtained for this buffer.  This value
    * is a combination of the AdaptiveFormattingFlags.
    * 
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_adaptive_formatting_flags;

   /**
    * Returns non-zero value if the current command button is the active default
    * button.  The active default button does not have to be a button with
    * <b>({@link p_default}!=0)</b>.  This property is not available when the control is not
    * displayed.
    *
    * @categories Command_Button_Properties
    * @appliesTo Command_Button
    */
   boolean p_adefault;

   /**
    * Gets or sets the amount to indent in twips after a bitmap in a list box,
    * text box, or combo box (text box not list).  This property is not
    * available when the control is not displayed.
    *
    * @example
    * <PRE>
    * #include 'slick.sh'
    * defeventtab form1;
    * combo1.on_create()
    * {
    *    {@link p_picture}=_pic_drremov;
    *    // Set indent before picture.
    *    {@link p_pic_indent_x}=100;
    *    // Set indent after picture.
    *    p_text='A:';
    *    {@link p_after_pic_indent_x}=200;
    *    // Extra y spacing. Half displayed above and half below picture
    *    {@link p_pic_space_y}=100;
    * }
    * </PRE>
    *
    * @categories List_Box_Properties, Combo_Box_Properties, Text_Box_Properties
    * @appliesTo List_Box, Combo_Box, Text_Box
    */
   int p_after_pic_indent_x;

   /**
    * Gets or sets the alignment.
    * Radio buttons and check boxes do not support this property under UNIX.
    *
    * <P><b>Label</b> - Determines where {@link p_caption} text gets displayed.
    * The <b>p_alignment</b> property has no effect if {@link p_auto_size} is non-zero.
    * <b>p_alignment</b> is one of the following constants defined in "slick.sh":
    * <DL compact style="margin-left:20pt">
    * <DT>AL_LEFT<DD style="marginleft:70pt">Display caption left justified.
    * <DT>AL_RIGHT<DD style="marginleft:70pt">Display caption right justified.
    * <DT>AL_CENTER<DD style="marginleft:70pt">Display caption horizontally centered at top.
    * <DT>AL_VCENTER<DD style="marginleft:70pt">Display caption vertically centered at left.
    * <DT>AL_VCENTERRIGHT<DD style="marginleft:70pt">Display caption vertically centered at right.
    * <DT>AL_CENTERBOTH<DD style="marginleft:70pt">Display caption centered vertically and horizontally.
    * </DL>
    *
    * <P><b>Radio Button, Check Box</b> - Determines whether p_caption text gets displayed on left or right.
    * We use the same conventions as Visual Basic (which are backwards).
    * p_alignment is  one of the following constants defined in "slick.sh":
    * <DL compact style="margin-left:20pt">
    * <DT>AL_LEFT<DD style="marginleft:70pt">Display caption right justified.
    * <DT>AL_RIGHT<DD style="marginleft:70pt">Display caption left justified.
    * </DL>
    *
    * @categories Label_Properties, Radio_Button_Properties, Check_Box_Properties
    * @appliesTo Label, Radio_Button, Check_Box
    */
   int p_alignment;

   /**
    * Determines whether the buffer displayed in an editor control may be saved.
    * When on, the buffer will be Auto Saved or Reloaded.
    *
    * @categories Editor_Control_Properties
    * @appliesTo Editor_Control
    */
   boolean p_AllowSave;

   /**
    * Always color the current item in the tree control, or only when
    * the tree has focus.
    *
    * @categories Tree_View_Properties
    * @appliesTo Tree_View
    */
   boolean p_AlwaysColorCurrent;
   /**
    * Determines the preferred style of casing for attributes for
    * the current buffer.  This property is available only when the 
    * control is displayed and is valid only in languages where 
    * attributes are used (e.g. HTML, XML). 
    *  
    * <p>values and respective results: 
    * <ol> 
    * <li>WORDCASE_PRESERVE - does not change </li>
    * <li>WORDCASE_LOWER - lowercase </li>
    * <li>WORDCASE_UPPER - uppercase </li> 
    * <li>WORDCASE_CAPITALIZE - capitalize the first letter only 
    * </li> 
    * </ol> 
    * 
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_attribute_casing;
   /**
    * Gets or sets the auto selection when tabbing between controls.  When
    * <b>p_auto_select</b> is non-zero, and you tab from a text box or combo box, the
    * selection is removed.  In addition, when you tab to a text box or combo
    * box, the text is selected.  If you do not want a text selection to change,
    * set the <b>p_auto_select</b> property to zero.
    *
    * @categories Text_Box_Properties, Check_Box_Properties
    * @appliesTo Text_Box, Check_Box
    */
   boolean p_auto_select;
   /**
    * Determines whether the source language type of the current file needs to 
    * be changed based on the contents of the first non-blank line of the file. 
    * At the moment this property only effects dataset files of the form 
    * datasetname" or "//pds(member)".  This property was intended for use
    * with mainframe source files which have no extension.  However, it is 
    * likely that this property will be useful for determining the language 
    * type of UNIX shell script files which typically have no file extension.
    *
    * @see p_TruncateLength
    * @see p_MaxLineLength
    * @see trunc
    *
    * @categories Edit_Window_Properties, Editor_Control_Properties
    * @appliesTo Edit_Window, Editor_Control 
    * @deprecated Use {@link p_AutoSelectLanguage} 
    */
   boolean p_AutoSelectExtension;
   /**
    * Determines whether the source language type of the current file needs to 
    * be changed based on the contents of the first non-blank line of the file. 
    * At the moment this property only effects dataset files of the form 
    * datasetname" or "//pds(member)".  This property was intended for use
    * with mainframe source files which have no extension.  However, it is 
    * likely that this property will be useful for determining the language 
    * type of UNIX shell script files which typically have no file extension.
    *
    * @see p_TruncateLength
    * @see p_MaxLineLength
    * @see trunc
    *
    * @categories Edit_Window_Properties, Editor_Control_Properties
    * @appliesTo Edit_Window, Editor_Control 
    * @since 13.0
    */
   boolean p_AutoSelectLanguage;
   /**
    * Determines whether a control automatically sizes its window based on its
    * contents.
    *
    * <P><b>Label</b> - Determines whether the window size is determined by the font and
    * the {@link p_caption} property.  When <b>p_auto_size</b> is non-zero, the {@link p_alignment}
    * property has no effect.
    *
    * <P><b>Text Box</b> - Determines whether the window size is determined by the fond
    * and the {@link p_text} property.
    *
    * <P><b>Editor Control, List Box, File List Box, Directory List Box</b> - Determines
    * whether the window height is rounded to an integral of the font height.
    *
    * <P><b>Hscroll Bar</b>- Determines whether the window height is set to the default
    * system scroll bar height.
    *
    * <P><b>Vscroll Bar</b>- Determines whether the window width is set to the default
    * system scroll bar width.
    *
    * <P><b>Picture Box, Image</b> - Depending on the {@link p_style} setting, 
    * determines whether the window size is set
    * to the size of the picture defined by the {@link p_picture}
    * property. If the {@link p_picture} property is zero and the
    * {@link p_caption} property is '', the <b>p_auto_size</b>
    * property has no effect.
    *
    * @categories Label_Properties, Text_Box_Properties, Editor_Control_Properties, List_Box_Properties, File_List_Box_Properties, Directory_List_Box_Properties, Hscroll_Bar_Properties, Vscroll_Bar_Properties, Picture_Box_Properties, Image_Properties
    * @appliesTo Label, Text_Box, Editor_Control, List_Box, File_List_Box, Directory_List_Box, Hscroll_Bar, Vscroll_Bar, Picture_Box, Image, Spin
    *
    */
   boolean p_auto_size;
   /**
    * Determines the background color of a control.
    *
    * <P><b>Form, Label, Spin, Text Box, Editor Control, Frame, Radio Button, Check Box,
    * List Box, File List Box, Directory List Box, Gauge, Tree View</b> -
    *    Determines the background color of the window.
    *
    * <P><b>Combo Box</b> - Determines the background color of the text box and list box.
    *
    * <P><b>Drive List</b> -  Determines the background color of the text box and list box.
    *
    * <P><b>Picture Box, Image</b> - Determines the background color of the window.  No background
    * of the window is seen if the {@link p_auto_size} property is non-zero and the {@link p_picture}
    * property has a valid picture.
    *
    * @categories All_Windows_Properties
    * @appliesTo All_Window_Objects
    */
   int p_backcolor;
   /**
    * Determines the binary mode of the buffer attached to this window.  Affects
    * the {@link _save_file()} function.  When on, all reformatting options given to
    * the {@link _save_file} function are ignored.  This property is initialized by the
    * {@link load_files} function.  The "<b>+lb</b>" {@link load_files} switch turns this buffer
    * property on.  This property is only available when the control is displayed.
    *
    * @categories Edit_Window_Properties, Editor_Control_Properties
    * @appliesTo Edit_Window, Editor_Control
    */
   boolean p_binary;
   /**
    * Determines the border of a control.
    * <p><b>Form</b> - Border style may be one of the following constants defined in "slick.sh":
    * <ul>
    * <li><b>BDS_NONE</B> - No border.
    * <li><b>BDS_FIXED_SINGLE</B> - Thin non-sizable border.
    * <li><b>BDS_SIZABLE</B> - Thick sizable border.
    * <li><b>BDS_DIALOG_BOX</B> - Standard non-sizable dialog box border.
    * </ul>
    * <p><b>Text Box, Editor Control, List Box, File List Box, Directory List Box,
    * Mini HTML, Tree View</b> - Border style may be one of the following constants defined in "slick.sh":
    * <ul>
    * <li><b>BDS_NONE</B> - No border.
    * <li><b>BDS_FIXED_SINGLE</B> - Thin non-sizable border.
    * </ul>
    * <p><b>Picture Box, Image</b> - Border style may be one of the following constants defined in "slick.sh":
    * <ul>
    * <li><b>BDS_NONE</B> - No border.
    * <li><b>BDS_FIXED_SINGLE</B> - Thin rectangular border.
    * <li><b>BDS_SUNKEN</B> - Sunken border. The exact look of this border style OS dependent. 
    * <li><b>BDS_SUNKEN_LESS</B> - Less sunken border. The exact look of this border style OS dependent. 
    * <li><b>BDS_ROUNDED</B> - Thin border with rounded corners.
    * </ul>
    * <p><b>Label</b> - Border style may be one of the following constants defined in "slick.sh":
    * <ul>
    * <li><b>BDS_NONE</B> - No border.
    * <li><b>BDS_FIXED_SINGLE</B> - Thin non-sizable border.
    * <li><b>BDS_SUNKEN</B> - Sunken border.   The exact look of this border style OS dependent.
    * </ul>
    *
    * @appliesTo Form, Label, Text_Box, Editor_Control, List_Box, File_List_Box, Directory_List_Box, Picture_Box, Image, Mini_HTML, Tree_View
    * @categories Form_Properties, Text_Box_Properties, Editor_Control_Properties, File_List_Box_Properties, Directory_List_Box_Properties, Picture_Box_Properties, Image_Properties, Mini_HTML_Properties, Tree_View_Properties
    */
   int p_border_style;
   /**
    * Sets the end of the bounds region in the editor.  Any text past the end of
    * the bounds region (in p_col > p_BoundsEnd) is treated as read-only.  Used
    * in ISPF mode, chiefly with column-oriented languages.
    * 
    * @appliesTo Edit_Window, Editor_Control
    *
    * @categories Edit_Window_Properties, Editor_Control_Properties
    *
    * @see p_BoundsStart
    */
   int p_BoundsEnd;
   /**
    * Sets the start of the bounds region in the editor.  Any text before the 
    * beginning of the bounds region (in p_col < p_BoundsStart) is treated as 
    * read-only. Used in ISPF mode, chiefly with column-oriented languages. 
    *  
    * @appliesTo Edit_Window, Editor_Control
    *
    * @categories Edit_Window_Properties, Editor_Control_Properties
    *
    * @see p_BoundsEnd
    */
   int p_BoundsStart;
   /**
    * Determines buffer flags.  This property is only available when the control
    * is displayed.  The buffer flags may be zero or more of the following
    * constant flags defined in "slick.sh":
    * <DL>
    * <DT>VSBUFFLAG_HIDDEN
    * <DD>Affects Edit Window only.
    *     {@link next_buffer} and {@link prev_buffer} commands won't switch to this buffer.
    * <DT>VSBUFFLAG_THROW_AWAY_CHANGES
    * <DD>Affects Edit Window only.
    *     Allow {@link quit} without prompting for save when this buffer is modified.
    * <DT>VSBUFFLAG_KEEP_ON_QUIT
    * <DD>Affects Edit Window only.  Don't delete buffer on {@link quit}.
    * <DT>VSBUFFLAG_REVERT_ON_THROW_AWAY
    * <DD>Affects Edit Window only.
    *     Replace buffer with copy on disk when the buffer is deleted with the {@link quit} command.
    * <DT>VSBUFFLAG_PROMPT_REPLACE
    * <DD>Indicates whether to prompt when replacing existing file on save.
    * <DT>VSBUFFLAG_DELETE_BUFFER_ON_CLOSE
    * <DD>Indicates whether the buffer should be deleted when a
    *     list box or editor control is deleted.
    * </DL>
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_buf_flags;
   /**
    * Determines buffer displayed in current window.
    * This property is only available when the control is displayed.
    *
    * @example
    * <PRE>
    * // Remember the original buffer
    * orig_buf_id=p_buf_id;
    * // Create a new buffer.  -q is a quit option
    * status={@link load_files}('-q main.e');
    * if (status) {
    *    first_line='';
    *    if (status== NEW_FILE_RC) {
    *        {@link _delete_buffer}();
    *    }
    * } else {
    *    {@link top}();   // Just in case the file was already loaded.
    *    {@link get_line}(first_line);
    *    {@link _delete_buffer}();
    * }
    * // Make sure were are back to the original buffer.
    * p_buf_id=orig_buf_id;
    * message('first_line='first_line);
    * </PRE>
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_buf_id;
   /**
    * Determines buffer name.  The buffer name is used as the default name
    * when a file is saved.  When the {@link p_DocumentName} property is '', the
    * buffer name is used as the display name.
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    * @see p_DocumentName
    * @see p_buf_name_no_symlinks
    */
   _str p_buf_name;
   /**
    * Buffer name with symbolic links resolved. 
    *  
    * <p>This property is read-only. 
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    * @see p_DocumentName 
    * @see p_buf_name 
    */
   _str p_buf_name_no_symlinks;

   /**
    * Returns number of bytes in buffer.  This property includes lines with
    * NOSAVE_LF set which means that this size will not match what is on disk if
    * the file has non-savable lines.  Use {@link p_RBufSize} to retrieve the number of
    * bytes which would be saved on disk.
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_buf_size;
   /**
    * Determines the record width of the current buffer.  Typically, the
    * <b>p_buf_width</b> property is zero when displaying ASCII files.  When the
    * <b>p_buf_width</b> property is non-zero, new line characters no longer split a
    * line, saving does not add new lines characters at the end of each line,
    * saving does not append an EOF character, tab character are not expanded
    * when displayed, and all characters in the buffer including new line
    * characters are displayed.
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_buf_width;
   /**
    * Gets/sets buffer specific information.  Currently this property is reserved
    * for used by SlickEdit Inc.  It may be removed in the future.
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   _str p_buser;
   /**
    * Gets/sets buffer specific information.  This function should be used 
    * only through the {@link _GetBufferInfoHt()} and {@link _SetBufferInfoHt()} 
    * api functions which allow you to set named buffer information. 
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   _str p_buf_user;
   /**
    * Determines the command button whose {@link lbutton_up} event handler gets executed
    * when ESC or Alt+F4 is pressed or the dialog box is closed by the system
    * menu.  If the cancel button does not have an {@link lbutton_up} event handler, the
    * dialog box is closed and '' is returned to {@link _modal_wait}.
    *
    * @appliesTo Command_Button
    * @categories Command_Button_Properties
    */
   boolean p_cancel;
   /**
    * Determines the title or text displayed.
    *
    * <p><b>Menu, Menu Item</b> - Determines the title of a submenu or menu item.
    * When menus are displayed, there is no instance handle.
    * Menu and menu item properties can only be accessed in menu resources.
    * The {@link _menu_get_state} and {@link _menu_set_state} function may be used to get and set
    * menu properties of displayed menus.
    *
    * <p>IMPORTANT:  For menu items, set the <b>p_caption</b>
    * property to "-" if you want a line separating menu items which follow.
    *
    * <p><b>Form, Frame</b> -  Determines the title of the window.
    *
    * <p><b>Picture Box, Image</b> -  Determines the caption 
    * displayed depending on {@link p_style} setting. 
    *
    * <p><b>Label, Command Button, Radio Button, Check Box</b> - Determines the text displayed in the window.
    *
    * @example
    * <PRE>
    *    #include "slick.sh"
    *    defmain()
    *    {
    *       // Find menu resource in names table
    *       tindex=find_index("menu1",oi2type(  OI_MENU));
    *       if (!tindex){
    *            messageNwait("menu1 not found");
    *            return('');
    *       }
    *       // Get resource handle to first child of this menu
    *       // The first child of a menu designed to be a menu bar is typically the File menu
    *       child=tindex.p_child;
    *       // Display the caption of the first child of this menu.
    *       messageNwait("caption="child.p_caption);
    *    }
    * </PRE>
    *
    * @appliesTo Form, Label, Frame, Command_Button, Radio_Button, Check_Box, Picture_Box, Image
    * @categories Label_Properties, Command_Button_Properties, Picture_Box_Properties, Image_Properties
    */
   _str p_caption;
   /**
    * Returns <b>true</b> if capitalization mode is on.
    *
    * @see p_LangId
    * @see p_caps
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   boolean p_caps;
   /**
    * Determines when clicking in the forms caption sends button down and up
    * events to the form.  Typically the operating system window manager takes
    * for handling mouse click events.  However, this property is useful for
    * dragging and dropping toolbars.  This property is ignored under X windows.
    *
    * @appliesTo Form
    * @categories Form_Properties
    */
   boolean p_CaptionClick;
   /**
    * Determines case sensitivity for searching in a Combo Box.
    * @categories Combo_Box_Properties
    */
   boolean p_case_sensitive;
   /**
    * This property is a string of categories.  Each category is separated with
    * a vertical bar character ('|').  Categories are typically used to define a
    * group of menu and/or menu items that are to be enabled/disabled at the
    * same time.  For example, SlickEdit defines the "ab-sel" category.
    * All menu items which contain this category are enabled when the active
    * buffer has a selection and disabled when it does not.  The {@link _menu_set_state}
    * function allows you to enable/disable menus or menu items by category or
    * command (only menu items have a {@link p_command} property).  For sub-menus, the
    * <b>p_categories</b> property is also used to uniquely identify the menu.  For
    * example, if you wanted to maintain a history of files recently opened on a
    * File menu, insert a menu item line with the <b>p_categories</b> property set to
    * "filehist".  Then use the {@link _menu_find} function to quickly find the menu
    * item.  This is how the {@link _menu_add_hist} function maintains File and Project
    * menu history.  The {@link _menu_add_hist} is a general purpose function for
    * maintaining history on a menu.
    *
    * @appliesTo Menu, Menu_Item
    * @categories Menu_Properties, Menu_Item_Properties
    */
   _str p_categories;
   /**
    * Returns the window id of a combo box.  A combo box consists of 4 controls:
    * the root window, text box, picture box, and list box.  The properties and
    * methods of the text box, picture box, and list box may be accessed
    * individually with the {@link p_cb_text_box}, {@link p_cb_picture}, {@link p_cb_list_box} instance
    * handle properties.  The <b>p_cb</b> property provides a way to make sure you are
    * accessing the root window properties and is only available when the
    * control is displayed.
    *
    * @example
    * <PRE>
    * defeventtab form1;
    * combo1.on_create()
    * {
    *    // Activate the list box of the combo box control
    *    p_window_id=p_cb_list_box;
    *    for (i=1;i&lt;=100;++i){
    *       _lbadd_item('line='i)
    *    }
    *    p_window_id=p_cb;
    * }
    * </PRE>
    *
    * @appliesTo Combo_Box, Drive_List
    * @categories Combo_Box_Properties, Drive_List_Properties
    * @deprecated Combo box is no longer split into 4 controls.
    *             Just use the regular {@link p_window_id} for
    *             everything
    */
   CTL_COMBO p_cb;
   /**
    * Returns the window id of the sub-control of a combo box that was clicked
    * in.  A combo box consists of 4 controls: the root window, text box,
    * picture box, and list box.  The properties and methods of the sub-controls
    * may be accessed individually with the {@link p_cb}, {@link p_cb_text_box}, {@link p_cb_picture},
    * {@link p_cb_list_box} instance handle properties.  When the combo box receives the
    * lbutton_down event, you may want to determine which of the sub-controls
    * was actually clicked in.  Compare the <b>p_cb_active</b> property to the
    * individual instance handles {@link p_cb}, {@link p_cb_text_box}, {@link p_cb_picture}, and
    * {@link p_cb_list_box}.
    *
    * @example
    * <PRE>
    * defeventtab form1;
    * combo1.lbutton_down()
    * {
    *    if (p_cb_active==p_cb_picture) {
    *        message('clicked in picture box');delay(100);
    *        if (p_cb_list_box.p_visible) {
    *             p_cb_list_box.p_visible=0;
    *        } else {
    *            p_cb_list_box.p_visible=1;
    *        }
    *        return('');
    *    }
    *    //  Skip user level 1 inheritance and execute the default event handler.
    *    {@link call_event}(p_window_id,lbutton_down,'2');
    * }
    * </PRE>
    *
    * @appliesTo Combo_Box, Drive_List
    * @categories Combo_Box_Properties, Drive_List_Properties
    * @deprecated Combo box is no longer split into 4 controls.
    *             Just use the regular {@link p_window_id} for
    *             everything
    */
   int p_cb_active;
   /**
    * When non-zero a key that scrolls the combo box list makes the list box
    * visible if it is not already visible.
    *
    * @appliesTo Combo_Box, Drive_List
    * @categories Combo_Box_Properties, Drive_List_Properties
    */
   boolean p_cb_extendedui;
   /**
    * Returns the window id of a list box sub-control of a combo box.  A combo
    * box consists of 4 controls: the root window, text box, picture box, and
    * list box.  The properties and methods of the sub-controls may be accessed
    * individually with the {@link p_cb}, {@link p_cb_text_box}, {@link p_cb_picture}, <b>p_cb_list_box</b>
    * instance handle properties.  The <b>p_cb_list_box</b> property is only available
    * when the control is displayed.
    *
    * @example
    * <PRE>
    * defeventtab form1;
    * combo1.on_create()
    * {
    *    // Active the list box of the combo box control
    *    p_window_id=p_cb_list_box;
    *    for (i=1;i&lt;=100;++i){
    *       _lbadd_item('line='i)
    *    }
    *    p_window_id=p_cb;
    * }
    * </PRE>
    *
    * @appliesTo Combo_Box, Drive_List
    * @categories Combo_Box_Properties, Drive_List_Properties
    * @deprecated Combo box is no longer split into 4 controls.
    *             Just use the regular {@link p_window_id} for
    *             everything
    */
   CTL_LISTBOX p_cb_list_box;
   /**
    * Returns the window id of a picture box sub-control of a combo box.  A
    * combo box consists of 4 controls: the root window, text box, picture box,
    * and list box.  The properties and methods of the sub-controls may be
    * accessed individually with the {@link p_cb}, {@link p_cb_text_box}, <b>p_cb_picture</b>,
    * {@link p_cb_list_box} instances handle properties.  The <b>p_cb_picture</b> property is
    * only available when the control is displayed.
    *
    * @example
    * <PRE>
    * #include "slick.sh"
    * defeventtab form1;
    * combo1.on_create()
    * {
    *    // Show a picture which indicates that click on the picture box button displays a dialog box.
    *    p_cb_picture.p_picture=_pic_cbdots;
    * }
    * combo1.lbutton_down()
    * {
    *    if (p_cb_active==p_cb_picture) {
    *        result=show('-modal form2')
    *        // process result
    *        return('');
    *    }
    *     //  Skip user level 1 inheritance and execute the default event handler.
    *     call_event(p_window_id, lbutton_down,'2');
    *
    * }
    * </PRE>
    *
    * @appliesTo Combo_Box, Drive_List
    * @categories Combo_Box_Properties, Drive_List_Properties
    * @deprecated Combo box is no longer split into 4 controls.
    *             Just use the regular {@link p_window_id} for
    *             everything
    */
   CTL_PICTURE p_cb_picture;
   /**
    * Returns the window id of a text box sub-control of a combo box.  A combo
    * box consists of 4 controls: the root window, text box, picture box, and
    * list box.  The properties and methods of the sub-controls may be accessed
    * individually with the {@link p_cb}, <b>p_cb_text_box</b>, {@link p_cb_picture}, {@link p_cb_list_box}
    * instances handle properties.  The <b>p_cb_text_box</b> property is only available
    * when the control is displayed.  Since all properties of {@link p_cb} and <b>p_cb_text</b>
    * access the same values except for the window position and size properties,
    * there is little need for the <b>p_cb_text_box</b> property other than to check if
    * it was clicked in.
    *
    * @example
    * <PRE>
    * defeventtab form1;
    * combo1.lbutton_down()
    * {
    *    if (p_cb_active==p_cb_text_box) {
    *        message('clicked in text box');delay(50);
    *    }
    *    //  Skip user level 1 inheritance and execute the default event handler.
    *    {@link call_event}(p_window_id, lbutton_down, '2');
    * }
    * </PRE>
    *
    * @appliesTo Combo_Box, Drive_List
    * @categories Combo_Box_Properties, Drive_List_Properties
    * @deprecated Combo box is no longer split into 4 controls.
    *             Just use the regular {@link p_window_id} for
    *             everything
    */
   CTL_TEXT p_cb_text_box;
   /**
    * Returns the maximum number of characters that can be displayed on a line
    * in the window.  This property is currently only useful if all characters
    * have the same font width.
    *
    * @appliesTo Editor_Control, Edit_Window, List_Box, File_List_Box, Directory_List_Box
    * @categories Editor_Control_Properties, Edit_Window_Properties, List_Box_Properties
    */
   int p_char_width;
   /**
    * True if this menu item is checked, false otherwise.
    *
    * @appliesTo Menu_Item
    * @categories Menu_Item_Properties
    */
   boolean p_checked;
   boolean p_CheckListBox;

   /**
    * Determines whether or not the frame control has a checkbox
    * that controls whether or not the frame's child controls are
    * enabled.  When set to true, the frame will have a checkbox on
    * the top border.  The frame's caption will also act as the
    * caption on the checkbox.  To get/set the checkbox value, use
    * frame.p_value.
    *
    * @appliesTo Frame
    * @categories Frame_Properties
    */
   boolean p_checkable;
   /**
    * Returns the client height of the window in pixels.  This property may only be accessed when
    * the control is displayed.
    *
    * @appliesTo All_Window_Objects
    * @categories All_Windows_Properties
    */
   int p_client_height;
   /**
    * Returns the client width of the window in pixels.  This property may only be accessed when
    * the control is displayed.
    *
    * @appliesTo All_Window_Objects
    * @categories All_Windows_Properties
    */
   int p_client_width;

   /**
    * Determines whether the child controls are clipped when the control is
    * painted.  When this property is off, dialogs sometimes have problems
    * repainting.  Painting a dialog box is slightly faster when <b>p_clip_controls</b>
    * is off.  However, the machines and video performance get faster, this
    * property will become useless.  This property is not yet supported under UNIX.
    *
    * @appliesTo Form, Frame
    * @categories Form_Properties, Frame_Properties
    */
   boolean p_clip_controls;
   /**
    * Determines the character column position.  The first column position is 1.
    * If there are tab characters in the line, p_col represents the expanded
    * column position and not the byte offset within the line.  This property is
    * only available when the control is displayed.
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_col;
   /**
    * Determines coloring styles for a buffer.  Color flags are defined in "slick.sh"
    * and may be one or more of the following constants:
    * <DL style="marginleft:20pt">
    * <DT>LANGUAGE_COLOR_FLAG
    * <DD>Color language specific elements.
    * <DT>MODIFY_COLOR_FLAG
    * <DD>Color modified lines.
    * <DT>CLINE_COLOR_FLAG
    * <DD>Color the current line.
    * </DL>
    *
    * @see _clex_find
    * @see _clex_load
    * @see _clex_skip_blanks
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_color_flags;
   /**
    * Color the entire current line, not just the text on the current line
    *
    * @appliesTo Tree_View
    * @categories Tree_View_Properties
    */
   boolean p_ColorEntireLine;
   /**
    * <P><b>Picture Box, Image</b> - Determines the editor command which gets invoked when
    * a two state picture button is pressed.  If <b>p_command</b> is a valid editor
    * command and {@link p_style} is PSPIC_FLAT_BUTTON (Image control only),
    * PSPIC_HIGHLIGHTED_BUTTON (Image control only),
    * PSPIC_BUTTON (image control only), or PSPIC_AUTO_BUTTON, the command is
    * executed on the active MDI edit window.
    *
    * <P><b>Menu Item</b> - Determines command which gets executed when a menu item is
    * selected.  When menus are displayed, there is no instance handle.  Menu
    * and menu item properties can only be accessed in menu resources.  The
    * {@link _menu_get_state} and {@link _menu_set_state} function may be used to get and set
    * menu properties of displayed menus.
    *
    * @appliesTo Picture_Box, Image, Menu_Item
    * @categories Picture_Box_Properties, Image_Properties, Menu_Item_Properties
    */
   _str p_command;
   /**
    * Determines the completion which occurs when the space bar or question mark
    * keys are pressed.  Valid <b>p_completion</b> constants are:
    * <DL compact style="margin-left:20pt">
    * <DT>NONE_ARG<DD style="marginleft:100pt">No completion
    * <DT>FILE_ARG<DD style="marginleft:100pt">One filename
    * <DT>MULTI_FILE_ARG<DD style="marginleft:100pt">Multiple filenames
    * <DT>DIR_ARG<DD style="marginleft:100pt">One directory name
    * <DT>MULTI_DIR_ARG<DD style="marginleft:100pt">Multiple directories, separated by semicolons
    * <DT>BUFFER_ARG<DD style="marginleft:100pt">Buffer name
    * <DT>COMMAND_ARG<DD style="marginleft:100pt">Slick-C&reg; command function
    * <DT>PICTURE_ARG<DD style="marginleft:100pt">Already loaded picture
    * <DT>FORM_ARG<DD style="marginleft:100pt">Dialog box template
    * <DT>MODULE_ARG<DD style="marginleft:100pt">Loaded Slick-C&reg; module
    * <DT>MACRO_ARG<DD style="marginleft:100pt">User recorded Slick-C&reg; command function
    * <DT>MACROTAG_ARG<DD style="marginleft:100pt">Slick-C&reg; tag name
    * <DT>VAR_ARG<DD style="marginleft:100pt">Slick-C&reg; global variable
    * <DT>ENV_ARG<DD style="marginleft:100pt">Environment variable
    * <DT>MENU_ARG<DD style="marginleft:100pt">Menu name
    * <DT>TAG_ARG<DD style="marginleft:100pt">Tag name
    * </DL>
    *
    * @appliesTo Combo_Box, Text_Box
    * @categories Combo_Box_Properties, Text_Box_Properties
    */
   _str p_completion;
   /**
    * Determines if this control should show completions in a drop-down
    * list underneath the control.  This option is on by default, but only
    * has an effect of <b>p_completion</b> is set.
    */
   boolean p_ListCompletions;
   /**
    * Windows only: When a form is displayed, determines whether the form has a system menu.
    */
   boolean p_control_box;
   /**
    * Determines the pixel position of the cursor relative to the beginning of
    * the window.  When this property is set, the actual value is rounded down
    * to the closest character.  This property is available only when the control
    * is displayed.
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_cursor_x;
   /**
    * Determines the pixel position of the cursor relative to the top of the
    * window.  When this property is set, the actual value is rounded down to
    * the closest line.  This property is available only when the control is
    * displayed.
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_cursor_y;
   /**
    * Determines whether the buffer has already been initialized for debugging.
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   boolean p_DebugMode;
   /**
    * Determines the command button whose {@link lbutton_up} event handler gets executed
    * when the ENTER key is pressed.  Also determines which command appears
    * visually as the default button (double border), when a control other than
    * a command button has focus.
    *
    * @appliesTo Command_Button
    * @categories Command_Button_Properties
    */
   boolean p_default;
   /**
    * Determines the delay in milliseconds for incrementing or decrementing
    * while you click and hold a spin control arrow.
    *
    * @appliesTo Spin
    * @categories Spin_Properties
    */
   int p_delay;
   /**
    * Determines 256 byte display translation table.  Use this property to
    * make characters look better in a particular font with out modifying the
    * editor buffer data.  For example, your buffer can contain EBCDIC
    * characters and with the proper display translation table the data can look
    * meaningful on screen.  This property is available only when the control is
    * displayed.  You can also edit and EBCDIC file by using the open dialog and
    * specifying EBCDIC encoding.
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   _str p_display_xlat;
   /**
    * Determines the document name.  Unlike {@link p_buf_name}, this string does not
    * have to be a valid filename.  When the document name is not "", this name
    * shown to user instead of the {@link p_buf_name} (the output filename) except when
    * the Save As dialog box is used.
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   _str p_DocumentName;

   /**
    * Returns non-zero value if the object is being edited in the dialog editor.  This
    * property is only available when the control is displayed.
    *
    * @appliesTo All_Window_Objects
    * @categories All_Windows_Properties
    */
   boolean p_edit;
   /**
    * Enable ability to edit tree cells in place.
    *
    * @appliesTo Tree_View
    * @categories Tree_View_Properties
    */
   boolean p_EditInPlace;
   /**
    * Determines embedded language context mode?  One of:
    * <DL style="marginleft:20pt">
    * <DT>VSEMBEDDED_BOTH</dt>
    * <DT>VSEMBEDDED_IGNORE</dt>
    * <DT>VSEMBEDDED_ONLY</dt>
    * </DL>
    *  
    * @see p_EmbeddedLexerName 
    * @see _EmbeddedStart() 
    * @see _EmbeddedEnd() 
    *  
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_embedded;
   /**
    * Determines embedded language context. 
    * This contains the name of the embedded language lexer name 
    * or "" if the cursor is not in an embedded language context.
    *  
    * @see p_embedded 
    * @see p_lexer_name
    * @see _EmbeddedStart() 
    * @see _EmbeddedEnd() 
    *  
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   _str p_EmbeddedLexerName;
   /**
    * Determines embedded language identifier characters. 
    * This contains the set of identifier characters of the 
    * embedded language or "" if the cursor is not in an embedded 
    * language context.
    *  
    * @see p_embedded 
    * @see p_EmbeddedLexerName 
    * @see p_identifier_chars 
    *  
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   _str p_EmbeddedIdentifierChars;
   /**
    * Determines embedded language case sensitivity. 
    * This returns the case sensitivity property for the embedded 
    * language lexer or if the cursor is not in an embedded 
    * language context, it will return the same thing as {@link 
    * p_LangCaseSensitive}. 
    *
    * @see p_embedded 
    * @see p_EmbeddedLexerName 
    * @see p_LangCaseSensitive
    *  
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   _str p_EmbeddedCaseSensitive;
   /**
    * Stores original values used for embedded language settings. 
    * This is a typeless container. 
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   typeless p_embedded_orig_values;
   /**
    * Determines the default encoding that the buffer will be saved in.  After
    * opening a file, this property indicates the encoding of the original file.
    *
    * <p>Use the {@link p_UTF8} property to check whether a buffer contains UTF-8.
    *
    * <P>VSCP_ACTIVE_CODEPAGE indicates that the buffer contains SBCS/DBCS active code page
    * data.  All other encodings indicate that the buffer contains UTF-8 data.
    *
    * <P>Encoding may be any one of the following:
    *
    * <BLOCKQUOTE><PRE>
    * VSCP_ACTIVE_CODEPAGE
    * VSCP_EBCDIC_SBCS
    * VSCP_CYRILLIC_KOI8_R
    * VSCP_ISO_8859_1
    * VSCP_ISO_8859_2
    * VSCP_ISO_8859_3
    * VSCP_ISO_8859_4
    * VSCP_ISO_8859_5
    * VSCP_ISO_8859_6
    * VSCP_ISO_8859_7
    * VSCP_ISO_8859_8
    * VSCP_ISO_8859_9
    * VSCP_ISO_8859_10
    * Any valid Windows code page
    * VSENCODING_UTF8
    * VSENCODING_UTF8_WITH_SIGNATURE
    * VSENCODING_UTF16LE
    * VSENCODING_UTF16LE_WITH_SIGNATURE
    * VSENCODING_UTF16BE
    * VSENCODING_UTF16BE_WITH_SIGNATURE
    * VSENCODING_UTF32LE
    * VSENCODING_UTF32LE_WITH_SIGNATURE
    * VSENCODING_UTF32BE
    * </PRE></BLOCKQUOTE>
    *
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_encoding;
   /**
    * Set to -1 if the buffer was loaded using with automatic encoding.  Set to the encoding
    * chosen if the user overrode automatic encoding processing.  {@link load_files}(),{@link _save_file}(), and
    * auto-reload set this property.  This buffer property is needed so that auto-reloaded
    * knows how to reload the buffer when it is modified by another application.
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_encoding_set_by_user;
   /**
    * Set by load_files when a new file is loaded to indicate an encoding translation error.
    * This allows the file to be loaded and for the user to get an error message.  An encoding
    * translation error can occur when translating file data to UTF-8 buffer data.
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_encoding_translation_error;
   /**
    * Determines the current file's language support.
    * The string represents a unique, primary file extension
    * generally associated with a language or editing mode.
    *
    * @see p_LangCaseSensitive
    * @see p_mode_name
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    * @deprecated Use {@link p_LangId}
    */
   _str p_extension;
   /**
    * Determines the current file's language support.
    * The string represents a unique, primary file extension
    * generally associated with a language or editing mode.
    *
    * @see p_LangCaseSensitive
    * @see p_mode_name
    * @see p_extension
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    * @since 13.0
    */
   _str p_LangId;
   /**
    * Binary string date which can be compared with binary dates returned by
    * the {@link _file_date} function.  This property is initialized by {@link load_files} (all
    * functions including {@link edit} which opens files calls load_files).  This property
    * can only be accessed when the object is displayed.
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   long p_file_date;
   /** 
    * Last known size of the file on disk. This can be wrong if 
    * another application has modified the file. 
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   long p_file_size;
   /**
    * This property is not fully supported yet.  Its value should always be PSFS_TRANSPARENT.
    *
    * @appliesTo Form, MDI_Window
    * @categories Form_Properties, MDI_Window_Properties
    */
   int p_fill_style;
   /**
    * Returns non-zero value if the font is a fixed font.
    * This property can only be accessed when the object is displayed.
    *
    * @appliesTo Editor_Control, Edit_Window, File_List_Box, Directory_List_Box
    * @categories Editor_Control_Properties, Edit_Window_Properties, File_List_Box_Properties, Directory_List_Box_Properties
    */
   boolean p_fixed_font;

   /**
    * Returns height of font in pixels.
    * This property can only be accessed when the object is displayed.
    *
    * @appliesTo Editor_Control, Edit_Window, File_List_Box, Directory_List_Box
    * @categories Editor_Control_Properties, Edit_Window_Properties, File_List_Box_Properties, Directory_List_Box_Properties
    */
   int p_font_height;
   /**
    * Returns height of font in pixels.
    * This property can only be accessed when the object is displayed.
    *
    * @appliesTo Editor_Control, Edit_Window, File_List_Box, Directory_List_Box
    * @categories Editor_Control_Properties, Edit_Window_Properties, File_List_Box_Properties, Directory_List_Box_Properties
    */
   int p_font_width;
   /**
    * The location for the grabbar, one of the following values:
    * <blockquote><pre>
    * SSTAB_GRABBARLOCATION_TOP
    * SSTAB_GRABBARLOCATION_BOTTOM
    * SSTAB_GRABBARLOCATION_LEFT
    * SSTAB_GRABBARLOCATION_RIGHT
    * </pre></blockquote>
    *
    * @appliesTo SSTab
    * @categories SSTab_Properties
    * @deprecated No longer supported
    */
   int p_GrabbarLocation;
   /**
    * Show grid lines for multi-column tree control
    *
    * @appliesTo Tree_View
    * @categories Tree_View_Properties
    */
   int p_Gridlines;
   /**
    * When in hex mode ({@link p_hex_mode}), determines whether cursor is display in hex
    * nibbles or ASCII data.  <b>false</b> indicates that the cursor is in the ASCII
    * data.  This property is available only when the control is displayed.
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   boolean p_hex_field;
   /**
    * Determines whether text is displayed in hex or ASCII lines.  You need to
    * use the {@link hex} function to switch into or out of hex display mode because this
    * function does more than just set this property.  This property is
    * available only when the control is displayed.  Possible values: 
    *  
    * <ul> 
    * <li>HM_HEX_OFF - hex mode off </li>
    * <li>HM_HEX_ON - hex mode on </li>
    * <li>HM_HEX_LINE - hex mode on using line hex
    * </li> 
    * </ul>
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   boolean p_hex_mode;
   /**
    * When in hex mode ({@link p_hex_mode}), determines whether cursor is currently on
    * before left or right nibble.  <b>true</b> indicates that the cursor is on the
    * right nibble.  This property is available only when the control is displayed.
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   boolean p_hex_nibble;
   /**
    * When in hex mode ({@link p_hex_mode}), determines number of 4 byte columns of hex data.
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_hex_Nofcols;
   /**
    * When in hex mode ({@link p_hex_mode}), determines start seek position of the top
    * line of the page displayed.  When you use the vertical scroll bars to
    * scroll, this value does not represent the start seek position of the top
    * line of the page displayed.
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_hex_toppage;

   /**
    * Determines the preferred style of casing for hex value 
    * elements for the current buffer.  This property is available 
    * only when the control is displayed and is valid only in 
    * languages where value elements are used (e.g. HTML, XML). 
    *  
    * <p>values and respective results: 
    * <ol> 
    * <li>WORDCASE_LOWER - lowercase </li>
    * <li>WORDCASE_UPPER - uppercase </li> 
    * </li> 
    * </ol>
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_hex_value_casing;

   int p_hsb_max;
   /**
    * Determines the amount the spin control should increment the text box.  If
    * p_increment is non-zero, there must be a text box with a tab index one
    * less than the spin control.  This allows the spin control to spin the
    * previous window which can be located with the {@link p_prev} property.  The value
    * in the text box may be a floating pointer number (sorry, <b>p_increment</b> is
    * only an int).  If <b>p_increment</b> is 0, the spin control will call the
    * {@link on_spin_up} and {@link on_spin_down} events.
    *
    * @appliesTo Spin
    * @categories Spin_Properties
    */
   int p_increment;
   /**
    * Determines whether to indent a case statement from its parent
    * switch statement. This property is available only 
    * when the control is displayed. 
    *  
    * @example 
    * <pre> 
    *    // p_indent_case_from_switch = true
    *    switch (num) {
    *       case 1:
    *       case 2:
    *       default:
    *          break;
    *    }
    * 
    *    // p_indent_case_from_switch = false
    *    switch (num) {
    *    case 1:
    *    case 2:
    *    default:
    *       break;
    *    }
    * </pre> 
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   boolean p_indent_case_from_switch;
   /**
    * Determines the indent style for the current buffer.  This effects what
    * happens when you press the ENTER key.  The indent style may be one of the
    * following constants defined in "slick.sh":
    * <DL compact style="margin-left:20pt">
    * <DT>INDENT_NONE  <DD style="marginleft:90pt">
    *    Go to column one.
    * <DT>INDENT_AUTO  <DD style="marginleft:90pt">
    *    Go the same column as the first non-blank character of the previous line or column one if there isn't one.
    * <DT>INDENT_SMART <DD style="marginleft:90pt">
    *    Indent based on the current language syntax.
    * </DL>
    * This property is available only when the control is displayed.
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_indent_style;
   /**
    * Determines whether to indent with tabs or spaces.  In addition, this
    * effects the {@link reflow_paragraph} command.  This property is available only
    * when the control is displayed.
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   boolean p_indent_with_tabs;
   /**
    * Determines a name table index for the current buffer.  The
    * name_info(index) is a string of syntax expansion and indenting options for
    * the current language.  This property was defined so that a buffer variable
    * was not required.  This property is available only when the control is
    * displayed.
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_index;
   /**
    * Determines whether the label caption (p_caption) is interpret
    * as html
    *
    * @appliesTo Label
    *
    * @categories Label_Properties
    *
    */
   boolean p_interpret_html;
   /**
    *
    * Determines whether the gutter should always be present even if there
    * are no pictures in the gutter.  This is needed for real time error notification
    * since the gutter can flash too frequently.
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   boolean p_KeepPictureGutter;

   /**
    * Determines the preferred style of casing for keywords for the
    * current buffer.  This property is available only when the 
    * control is displayed. 
    *  
    * <p>values and respective results: 
    * <ol> 
    * <li>WORDCASE_PRESERVE - does not change </li>
    * <li>WORDCASE_LOWER - lowercase </li>
    * <li>WORDCASE_UPPER - uppercase </li> 
    * <li>WORDCASE_CAPITALIZE - capitalize the first letter only 
    * </li> 
    * </ol> 
    * 
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_keyword_casing;

   /**
    * Returns <b>true</b> if language is case sensitive.  This property is read only.
    *
    * @see p_LangId 
    * @see p_EmbeddedCaseSensitive 
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   boolean p_LangCaseSensitive;
   /**
    * Returns a string containing two parts:
    * <li>First is the identifier start characters -- 
    * these are the valid leading characters for an identifier
    * in the current language.<br>
    * <li>Second is the additional identifier characters --
    * these are other characters that are valid in
    * identifiers in the current language.
    * 
    * Character ranges are separated by a dash (-), and
    * special characters (e.g. dash) can be escaped using
    * backslash (\).
    *
    * @note  
    *    For many purposes, this property replaces 
    *    {@link p_word_chars} which may contain other
    *    non-identifier characters.
    * 
    * @example
    *    For a typical language that allowed identifiers to
    *    start with an alphabetic character and continue with
    *    underscore or alphanumeric characters.
    *    <pre>A-Za-z _0-9</pre>
    * 
    * @see _clex_identifier_re()
    * @see _clex_identifier_notre()
    * @see _clex_identifier_chars()
    * @see _clex_is_identifier_char() 
    * @see cur_identifier()
    * @see p_word_chars
    * @see p_EmbeddedIdentifierChars
    * 
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   _str p_identifier_chars;
   /**
    * Determines the amount to change {@link p_value} when the mouse is
    * clicked between the thumb box and the arrow.
    *
    * @appliesTo Hscroll_Bar, Vscroll_Bar
    * @categories Hscroll_Bar_Properties, Vscroll_Bar_Properties
    */
   int p_large_change;
   /**
    * Buffer time stamp.
    *
    * <p>The purpose of this property is to track whether a buffer has been modified, quit, or
    * replaced since the last time it was queried.   This allows threads or processes on timers
    * to know whether the results they are working on are still valid.
    *
    * <p>This property is readonly and only available when the control
    * is displayed.
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_LastModified;
   /**
    * Contains flags to control the line number display in the current buffer.
    * The following flags, defined in slick.sh, are used with this property:
    * 
    * <dl>
    * <dt>VSLCBUFFLAG_READWRITE</dt><dd>prefix area on/off</dd>
    * <dt>VSLCBUFFLAG_LINENUMBERS</dt><dd>Line numbers on/off</dd>
    * <dt>VSLCBUFFLAG_LINENUMBERS_AUTO</dt><dd>Line numbers automatic</dd>
    * </dl>
    * 
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_LCBufFlags;
   /**
    * Determines the left edge scroll position in pixels or characters.  If the
    * {@link p_fixed_font} property is true, this property is in characters.  A scroll
    * position of zero means the first character of every line can be seen.
    * This property is available only when the control is displayed.
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_left_edge;
   /**
    * Determines the spacing in twips to indent to the right for each level of the tree.
    *
    * @appliesTo Tree_View
    * @categories Tree_View_Properties
    */
   int p_LevelIndent;
   /**
    * Determines lexer name which defines the language coloring elements for a
    * buffer.  This property is set to one of the lexer names in square brackets
    * in the file "vslick.vlx".  See <a href="help:Color Coding">Color Coding</a> for more information.
    *  
    * @see p_EmbeddedLexerName 
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   _str p_lexer_name;
   /**
    * Determines the current line number.  Note that p_line includes lines which
    * are non-savable (lines with NOSAVE_LF flag set).  Use the {@link p_RLine} property
    * to only count lines which will be saved in your file.  The Top of File
    * line is line 0.  A list box has a line 0, but is never displayed.  If the
    * current line number is not already known, it is determined.  Use the {@link point}
    * function if you want to optimize.  If the p_line property is set to a
    * value greater than the number of lines in the buffer, the cursor is placed
    * on the last line.  This property is available only when the control is
    * displayed.
    *
    * @see p_RLine
    * @appliesTo Editor_Control, Edit_Window, List_Box
    * @categories Editor_Control_Properties, Edit_Window_Properties, List_Box_Properties
    */
   int p_line;
   /**
    * Determines the numbers of bytes used to display line numbers to the left
    * of each line.  When this is 0, line numbers are not displayed to the left
    * of each line.
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_line_numbers_len;
   /**
    * Determines the line style used to draw lines between children and siblings.
    * p_LineStyle may be one of the following constants defined in "slick.sh":
    * <blockquote><pre>
    * TREE_NO_LINES
    * TREE_DOTTED_LINES
    * TREE_SOLID_LINES
    * </pre></blockquote>
    *
    * @appliesTo Tree_View
    * @categories Tree_View_Properties 
    * @deprecated Does not have any function in new treeview. 
    *             Style issues will look appropriate for their
    *             platform
    */
   int p_LineStyle;
   /**
    * Read-only.  True if lines have been "force wrapped"
    *
    * @appliesTo Editor_Control, Edit_Window, List_Box
    * @categories Editor_Control_Properties, Edit_Window_Properties, List_Box_Properties
    */
   boolean p_LinesForceWrapped;
   /**
    * Determines the margins for the current buffer.  This property is available
    * only when the control is displayed.  p_margins is a string in the format:
    * <b><i>left_ma</i></b> <b><i>right_ma</i></b> [<b><i>new_paragraph_ma</i></b> ].  If new_paragraph_ma is not given,
    * it defaults to left_ma.
    *
    * @example
    * <PRE>
    *    parse p_margins with left_ma right_ma new_para_ma;
    *    ++left_ma;++right_ma;++new_para_ma;
    *    p_margins=left_ma' 'right_ma' 'new_para_ma;
    * </PRE>
    *
    * @appliesTo Edit_Window
    * @categories Edit_Window_Properties
    */
   _str p_margins;
   /**
    * Determines the maximum scroll range.  The scroll range is determined by
    * p_min and p_max.  The {@link p_value} property is set to a number between p_min
    * and p_max when an {@link on_scroll} or {@link on_change} event occurs.
    *
    * @appliesTo Hscroll_Bar, Vscroll_Bar
    * @categories Hscroll_Bar_Properties, Vscroll_Bar_Properties
    */
   int p_max;
   /**
    * Display maximize button. Not fully supported.
    */
   boolean p_max_button;

   /**
    * Determines the maximum number of clicks allowed and may be one of the following values:
    *
    * <dl>
    * <dt>MC_SINGLE</dt><dd>Single clicks only.</dd>
    * <dt>MC_DOUBLE</dt><dd>Up to double click.</dd>
    * <dt>MC_TRIPLE</dt><dd>Up to triple click.</dd>
    * </dl>
    *
    * @appliesTo Picture_Box, Image
    * @categories Picture_Box_Properties, Image_Properties
    */
   int p_max_click;
   /**
    * Determines the maximum line length.  At the moment this option is only
    * used by the {@link _save_file} built-in when the +CL option is specified and the
    * destination file does not already have a strict record length.  This
    * property was intended for use with mainframe source files which have line
    * length restrictions.  At the moment only the physical line length is
    * checked as if tab characters count as 1 character.  We may change this in
    * the future.
    *
    * @see p_TruncateLength
    * @see p_MaxLineLength
    * @see trunc
    * @see p_AutoSelectLanguage
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_MaxLineLength;
   /**
    * Returns the menu bar menu handle.  Use the {@link _menu_set} property to set the
    * menu bar for a form.  This property can only be accessed when the form is
    * displayed.
    *
    * @appliesTo Form, MDI_Window
    * @categories Form_Properties, MDI_Window_Properties
    */
   int p_menu_handle;
   /**
    * <b>Picture Box, Image</b> - Determines the message that gets displayed when the
    * mouse is hovered within the window.
    * <p>
    * <b>Menu, Menu Item</b> - Determines the message displayed when this menu item is
    * selected.  Currently this property is only supported by the MDI menu bar.
    * In the future, we will add an event (maybe called on_menu_select) so that
    * forms can display menu messages any where they want.  When menus are
    * displayed, there is no instance handle.  Menu and menu item properties can
    * only be accessed in menu resources.  The {@link _menu_get_state} and
    * {@link _menu_set_state} function may be used to get and set menu properties of
    * displayed menus.
    *
    * @appliesTo Picture_Box, Image, Menu, Menu_Item
    * @categories Picture_Box_Properties, Image_Properties, Menu_Properties, Menu_Item_Properties
    */
   _str p_message;
   /**
    * Determines the minimum scroll range.  The scroll range is determined by
    * p_min and p_max.  The {@link p_value} property is set to a number between p_min
    * and p_max when an {@link on_scroll} or {@link on_change} event occurs.
    *
    * @appliesTo Hscroll_Bar, Vscroll_Bar
    * @categories Hscroll_Bar_Properties, Vscroll_Bar_Properties
    */
   int p_min;
   /**
    * Determines the language-specific event table for the current file.  
    * The binding for a key, mouse, and a few other events is determined
    * by checking event tables for bindings in the following order.
    * <ol>
    * <li>p_eventtab (window property)
    * <li>p_mode_eventtab (buffer property)
    * <li>Root event table (global stored in _default_keys variable)
    * </ol>
    *
    * This property is available only when the control is displayed.
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_mode_eventtab;
   /**
    * Determines the language name for the current file.  
    * {@link p_LangId} uniquely determines the language support,
    * this string is used for display purposes and is intended to
    * be more readable.
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   _str p_mode_name;
   /**
    * Determines whether the current buffer is modified.
    * The p_modify propert is equivelent to setting the p_ModifyFlags to 0 or 1.
    * Setting this property clears all the high order bits of the p_ModifyFlags property.
    *
    * @see p_ModifyFlags
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   boolean p_modify;

   /**
    * Determines whether the current buffer is modified and provides additional bits you can 
    * use to track whether a change has been made to a buffer since the last time you processed 
    * the buffer.  Any time a modification is made to a buffer this property is set to 1 which 
    * clears all high bits.  The p_modify property is equivalent to setting the p_ModifyFlags 
    * to 0 or 1. Make sure the high bit you use isn't already being used by another macro 
    * feature like AutoSave. Currently, the modify flags are stored as 32 bits. 
    *
    * <p>
    *
    * <b>IMPORTANT:</b><br> 
    * SlickEdit now reserves all 32 bits for its own internal use. Users wanting to track
    * buffer modifications in their own macros should use the {@link p_LastModified} property
    * instead.
    *
    * @example
    * <pre>
    * // This code would be executed within a timer call back.  See {@link _set_timer}.
    *
    * // IF the current buffer is modified AND some edits have been performed since the
    * // the last time we autosaved this file.
    * if (p_modify && !(pModifyFlags & MODIFYFLAG_AUTOSAVE_DONE)) { 
    *     AutoSaveCurrentBuffer();
    *     p_ModifyFlags |= MODIFYFLAG_AUTOSAVE_DONE;
    * }
    * </pre>
    *
    * @see p_modify
    * @see p_LastModified
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_ModifyFlags;
   /**
    * Determines how tabs are displayed.
    * p_MultiRow may be one of the following:
    * <UL>
    * <DT>SSTAB_MULTIROW_NONE
    * <DD>If tabs don't fit, display a scroll bar.
    * <DT>SSTAB_MULTIROW_MULTIROW
    * <DD>If tabs don't fit, make another row.
    *     Use the {@link p_TabsPerRow} property to set the number of tabs displayed on each row.
    * <DT>SSTAB_MULTIROW_BESTFIT
    * <DD>If tabs don't fit, try to reduce space taken by each tab.
    *     If tabs still don't fit, display a scroll bar.
    * </DL>
    *
    * @appliesTo SSTab
    * @categories SSTab_Properties
    * @deprecated No longer supported
    */
   int p_MultiRow;
   /**
    * Determines whether the list box allows multiple items to be selected and
    * the user interface style.  In addition, when the p_multi_select property
    * is set to MS_EDIT_WINDOW, the list box becomes an editor control.  The
    * p_multi_select property may be one of the following constants defined in
    * "slick.sh":
    * <DL compact style="margin-left:20pt">
    * <DT>MS_NONE<DD style="marginleft:90pt">
    *    Allow only one item to be selected.
    * <DT>MS_SIMPLE_LIST<DD style="marginleft:90pt">
    *    Allow multiple items to be selected.
    * <DT>MS_EXTENDED<DD style="marginleft:90pt">
    *    (List Box only)Allow multiple items to be selected.
    * </DL>
    *
    * @appliesTo List_Box, Tree_View
    * @categories List_Box_Properties, Tree_View_Properties
    */
   int p_multi_select;
   /**
    * Never color the current item in the tree control.
    *
    * @appliesTo Tree_View
    * @categories Tree_View_Properties
    */
   boolean p_NeverColorCurrent;
   /**
    * Returns the new line characters used for the current buffer.  This string
    * is one or two characters long.  This property is available only when the
    * control is displayed.
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   _str p_newline;
   /**
    * Determines whether selected items should be displayed in a different color
    * than non-selected items.  This property is only available when the control
    * is displayed.
    *
    * @appliesTo List_Box
    * @categories List_Box_Properties
    */
   boolean p_no_select_color;
   /**
    * Returns the total number of hidden lines in the current buffer.
    * SlickEdit uses this property to quickly determine when special processing
    * is needed for changing the cursor position and correctly scrolling.
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_Nofhidden;
   /**
    * Returns the number of lines in the current buffer.  This property
    * includes non-saveable lines (lines with the NOSAVE_LF flag set).
    * Use the {@link p_RNoflines} property to get the number of saveable lines ("real lines").
    *
    * @see p_RNoflines
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_Noflines;
   /**
    * Returns the number of lines with the NOSAVE_LF line flag set.  Use the {@link _lineflags}()
    * function to change the line flags.
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_NofNoSave;
   /**
    * Returns the number of selective display bitmaps in the current buffer.
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_NofSelDispBitmaps;
   /**
    * Determines the number of selected items in the list box.
    * @categories List_Box_Properties
    */
   int p_Nofselected;
   /**
    * Determines how many times the pictures width should be sub-divided.  The
    * p_value property may be set between 0 and p_Nofstates-1, to display a
    * particular state of the picture.
    * </P>
    *
    * @example
    * <PRE>
    * // For this example, create a picture or image control and
    * // set the {@link p_picture} property to "_arrow.bmp" or any two
    * // state bitmap.  Also set the {@link p_Nofstates} property to 2.
    * #include 'slick.sh'
    *
    * defeventtab form1;
    *
    * image1.on_create()
    * {
    *    index=_update_picture(-1,bitmap_path_search("_arrow.bmp"));
    *    if (index<0) {
    *        if (index==FILE_NOT_FOUND_RC) {
    *           _message_box("Picture find.bmp was not found");
    *        } else {
    *           _message_box("Error loading picture find.bmp\n\n":+
    *                        get_message(index));
    *        }
    *        return("");
    *    }
    *    p_picture=index;
    *    p_Nofstates=2;
    *    p_message="Searches for a string you specify";
    *    p_style=PSPIC_AUTO_BUTTON;
    *
    * }
    *
    * picture1.lbutton_down()
    * {
    *    mou_mode(1)
    *    mou_capture();
    *    done=0;
    *    for (;;) {
    *       event=get_event();
    *       switch (event) {
    *       case MOUSE_MOVE:
    *          // 'm' specifies mouse position in current scale mode
    *          mx=mou_last_x('m');
    *          my=mou_last_y('m');
    *          if (mx>=0 && my>=0 && mx<p_width && my<p_height) {
    *             if (!p_value) {
    *                // Show the button pushed in.
    *                p_value=1;
    *             }
    *          } else {
    *
    *             if (p_value) {
    *                // Show the button up.
    *                p_value=0;
    *             }
    *          }
    *          break;
    *       case LBUTTON_UP:
    *       case ESC:
    *          p_value=1;
    *          done=1;
    *       }
    *       if (done) break;
    *    }
    *    mou_mode(0);
    *    mou_release();
    *    return('')
    * }
    * </PRE>
    *
    * @appliesTo Picture_Box, Image
    * @categories Picture_Box_Properties, Image_Properties
    */
   int p_Nofstates;
   /**
    * Determines whether to insert a space before the opening 
    * parenthesis during syntax expansion for the current buffer. 
    * This property is available only when the control is 
    * displayed. 
    *  
    * @example 
    * <pre> 
    *    // p_no_space_before_paren = false 
    *       if (x == 5)
    *    // p_no_space_before_paren = true
    *       if(x == 5)
    * </pre>
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   boolean p_no_space_before_paren;
   /**
    * Returns the old line number stored for the current line.  Use the
    * {@link _SetAllOldLineNumbers} method to set the old line numbers for all lines in
    * the current buffer.
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_OldLineNumber;
   /**
    * <p><b>Mini_HTML</b> - Determines the padding in twips to the left and right of the text.
    *
    * @appliesTo Mini_HTML
    * @categories Mini_HTML_Properties
    */
   int p_PaddingX;
   /**
    * <p><b>Mini_HTML</b> - Determines the padding in twips above and below the text.
    *
    * @appliesTo Mini_HTML
    * @categories Mini_HTML_Properties
    */
   int p_PaddingY;
   /**
    * Determines whether to insert a space between parenthesis 
    * during syntax expansion for the current buffer. This property
    * is available only when the control is displayed. 
    *  
    * @example 
    * <pre> 
    *    // p_pad_parens = false 
    *    if (x == 5)
    *    // p_pad_parens = true
    *    if ( x == 5 )
    *</pre>
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   boolean p_pad_parens;
   /**
    * When <b>true</b>, hides actual characters typed in.
    * This is typically used for hiding passwords.
    *
    * @appliesTo Text_Box, Combo_Box
    * @categories Text_Box_Properties, Combo_Box_Properties
    */
   boolean p_Password;
   /**
    * Determines the amount to indent in twips before a picture displayed text
    * box, or combo box (text not list).
    *
    * @example
    * <PRE>
    * #include 'slick.sh'
    * defeventtab form1;
    * combo1.on_create()
    * {
    *    {@link p_picture}=_pic_drremov;
    *    // Set indent before picture.
    *    <b>p_pic_indent_x</b>=100;
    *    // Set indent after picture.
    *    {@link p_text}='A:';
    *    {@link p_after_pic_indent_x}=200;
    *    // Extra y spacing. Half displayed above and half below picture
    *    {@link p_pic_space_y}=100;
    * }
    * </PRE>
    *
    * @appliesTo Combo_Box, Text_Box
    * @categories Combo_Box_Properties, Text_Box_Properties
    */
   int p_pic_indent_x;
   /**
    * Determines the scaling (in points) of a picture with respect to the font
    * size ({@link p_font_size}).  If <b>p_pic_point_scale</b> is 0, the picture ({@link p_picture}) is
    * not scaled.  The height and width of the picture are multiplied by
    * ({@link p_font_size}/<b>p_pic_point_scale</b>).
    *
    * @example
    * <PRE>
    * #include 'slick.sh'
    * defeventtab form1;
    * combo1.on_create()
    * {
    *    // Let this picture be scaled based on an 8 point font
    *    <b>p_pic_point_scale</b>=8;
    *    {@link p_font_size}=18;
    *    {@link p_picture}=_pic_drremov;
    *    // Set indent before picture.
    *    {@link p_pic_indent_x}=100;
    *    // Set indent after picture.
    *    {@link p_text}='A:';
    *    {@link p_after_pic_indent_x}=200;
    *    // Extra y spacing. Half displayed above and half below picture
    *    {@link p_pic_space_y}=100;
    *
    * }
    * </PRE>
    *
    * @appliesTo Combo_Box, Text_Box, List_Box
    * @categories Combo_Box_Properties, Text_Box_Properties, List_Box_Properties
    */
   int p_pic_point_scale;
   /**
    * Determines the amount of extra line spacing in twips for a list box, text
    * box, or combo box (text not list).  This property effects the line spacing
    * even when there is not a picture in the control.  However, the line
    * spacing is more typically changed when a picture is present.
    *
    * @example
    * <PRE>
    * #include 'slick.sh'
    * defeventtab form1;
    * combo1.on_create()
    * {
    *    {@link p_picture}=_pic_drremov;
    *    // Set indent before picture.
    *    {@link p_pic_indent_x}=100;
    *    // Set indent after picture.
    *    {@link p_text}='A:';
    *    {@link p_after_pic_indent_x}=200;
    *    // Extra y spacing. Half displayed above and half below picture
    *    <b>p_pic_space_y</b>=100;
    * }
    * </PRE>
    *
    * @appliesTo Combo_Box, Text_Box, List_Box
    * @categories Combo_Box_Properties, Text_Box_Properties, List_Box_Properties
    */
   int p_pic_space_y;
   /**
    * The <b>p_picture</b> property is an index to a picture in the names table.
    *
    * <P><b>List Box</b> - Determines the of scaling picture and whether the list should display pictures.
    *
    * <P><b>Text Box, Combo Box</b> - Determines the picture displayed to the left of the text.
    *
    * <P><b>Picture Box, Image</b> - Determines the picture displayed.
    *
    * <P><b>Form</b> - Determines the picture displayed on a docked tool window that is part of tab group.
    *
    * <p>Here's how you can create a toolbar for the editor without 
    * writing any code at all: 
    * <ol>
    * <li>Create a new form for editing ("Macro", "New").
    * <li>Create an image control.  Double click on the image control (bottom right.  Looks like slanted rectangle) in the dialog editor.
    * <li>Set the p_picture property to find.bmp.  Make sure you specify the full path (c:\vslick\bitmaps is the default path used by installation program).
    * <li>Set the p_command property to gui-find.  Notice that the down arrow of the combo box displays all the editor commands.
    * <li>Set the p_message property to "Searches for a string you specify".
    * <li>Set the p_style property to PSPIC_HIGHLIGHTED_BUTTON.
    * <li>Repeat the steps 2-6 to add more tool bar buttons.
    * </ol>
    *
    * Save your tool bar.  To run it such that is stays on top of the MDI Window, type
    * the command "<b>show -mdi form-name</b>" on the SlickEdit command line where
    * form-name is the name of the tool bar form you created.  If you want to bind
    * it to a key, use macro recording to record typing the command on the command
    * line.  The mouse may be used during macro recording to place your cursor on
    * the command line.
    *
    * @example
    * <pre>
    * <code>
    * #include 'slick.sh'
    *
    * #define PIC_LSPACE_Y 60    // Extra line spacing for list box.
    * #define PIC_LINDENT_X 60   // Indent before for list box bitmap.
    *
    * defeventtab form1;
    * list1.{@link on_create}()
    * {
    *    {@link p_pic_space_y}=PIC_LSPACE_Y;
    *    {@link _lbadd_item}('a:',PIC_LINDENT_X,_pic_drremov);
    *    {@link _lbadd_item}('b:',PIC_LINDENT_X,_pic_drremov);
    *    {@link _lbadd_item}('c:',PIC_LINDENT_X,_pic_drfixed);
    *    // The <b>p_picture</b> property must be set to indicate that this list box
    *    // is displaying pictures and to provide a scaling picture for
    *    // the {@link p_pic_point_scale} property.  The {@link p_pic_point_scale} property allows the picture to
    *    // resized for fonts larger or smaller that the value of the {@link p_pic_point_scale} point size.
    *    <b>p_picture</b>=picture;
    *    {@link p_pic_point_scale}=8;
    * }
    *
    * // Another example
    *
    * #include 'slick.sh'
    * defeventtab form1;
    * combo1.{@link on_create}()
    * {
    *    {@link p_picture}=_pic_drremov;
    *    // Set indent before picture.
    *    {@link p_pic_indent_x}=100;
    *    // Set indent after picture.
    *    {@link p_text}='A:';
    *    {@link p_after_pic_indent_x}=200;
    *    // Extra y spacing. Half displayed above and half below picture
    *    <b>p_pic_space_y</b>=100;
    * }
    *
    *
    * </code>
    * </pre>
    * @appliesTo Combo_Box, Text_Box, List_Box, Picture_Box, Image
    * @categories Combo_Box_Properties, Text_Box_Properties, List_Box_Properties, Picture_Box_Properties, Image_Properties
    */
   int p_picture;

   /**
    * Determines the preferred style of formatting a pointer 
    * declaration for the current buffer.  This property is 
    * available only when the control is displayed. 
    *  
    * @example 
    * <pre> 
    *    p_pointer_style = 0; 
    *       char *p;
    *    p_pointer_style = VS_C_OPTIONS_SPACE_AFTER_POINTER; 
    *       char* p;
    *    p_pointer_style = VS_C_OPTIONS_SPACE_SURROUNDS_POINTER;
    *       char * p;
    * </pre>
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   boolean p_pointer_style;

   /**
    * Determines whether how read only mode should be protected.  Unlike
    * the p_readonly_mode property which is per buffer, this property is per
    * window.
    *
    * <dl>
    * <dt>VSPROTECTREADONLYMODE_OPTIONAL</dt><dd>If the buffer is in read only
    * mode and the user has selected to protect read only mode
    * (_default_option (VSOPTION_PROTECT_READONLY_MODE) )</dd>
    *
    * <dt>VSPROTECTREADONLYMODE_ALWAYS</dt><dd>If the buffer is in read only
    * mode, the buffer is protected.</dd>
    *
    * <dt>VSPROTECTREADONLYMODE_NEVER</dt><dd>Read only mode is
    * never protected.</dd>
    * </dl>
    *
    * @appliesTo Edit_Window, Editor_Control
    *
    * @categories Edit_Window_Properties, Editor_Control_Properties
    *
    */
   boolean p_ProtectReadOnlyMode;

   /**
    * Returns 'A' if the current buffer buffer contains SBCS/DBCS data and that
    * SlickEdit is running in UTF-8 mode.  Otherwise, '' is returned.
    * This property is read-only.  This property is intended for use with
    * the pos(), lastpos(), and parse functions in order to simplify supporting Unicode and
    * SBCS/DBCS mode buffers.
    *
    * @appliesTo Editor_Control, Edit_Window
    *
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   _str p_rawpos;

   /**
    * Returns number of bytes in buffer.  This property does not include lines
    * with NOSAVE_LF set which means that this size will match what will be
    * saved on disk.
    *
    * @appliesTo Editor_Control, Edit_Window
    *
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_RBufSize;

   /**
    * This property is identical to the {@link p_readonly_mode} property.
    *
    * <P><b>Edit Window, Editor Control</b>: Determines whether the current buffer is
    * read only.  This property may have no effect depending on the setting of
    * {@link p_ProtectReadOnlyMode} and {@link _default_option}(VSOPTION_PROTECT_READONLY_MODE).
    * Use the {@link _QReadOnly}() method to test whether you should allow editing
    * because it tests all necessary options.
    *
    * <p><b>Text Box</b>: Determines whether the text in a text box can be modified.  This
    * is some times more useful than disabling the control because the user can
    * still make a selection and copy the text to the clipboard.  In addition,
    * the color of the text is more readable when the text box is read only
    * (<b>p_ReadOnly</b>=true) than when it is disabled ({@link p_enabled}=false).
    *
    * @see p_readonly_set_by_user
    * @see p_ReadOnly
    * @see p_readonly_mode
    * @see p_ProtectReadOnlyMode
    * @see _QReadOnly
    *
    * @appliesTo Editor_Control, Edit_Window, Text_Box
    * @categories Editor_Control_Properties, Edit_Window_Properties, Text_Box_Properties
    */
   boolean p_ReadOnly;

   /**
    * This property is identical to the p_ReadOnly property.
    *
    * <p><b>Edit Window, Editor Control</b>: Determines whether the current buffer is read
    * only.  This property may have no effect depending on the setting of
    * {@link p_ProtectReadOnlyMode} and {@link _default_option}(VSOPTION_PROTECT_READONLY_MODE).
    * Use the {@link _QReadOnly}() method to test whether you should allow editing
    * because it tests all necessary options.
    *
    * <p><b>Text Box</b>: Determines whether the text in a text box can be modified.  This
    * is some times more useful than disabling the control because the user can
    * still make a selection and copy the text to the clipboard.  In addition,
    * the color of the text is more readable when the text box is read only
    * (<b>p_ReadOnly</b>=true) than when it is disabled ({@link p_enabled}=false).
    *
    * @see p_readonly_set_by_user
    * @see p_ReadOnly
    * @see p_readonly_mode
    * @see p_ProtectReadOnlyMode
    * @see _QReadOnly
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   boolean p_readonly_mode;
   /**
    * Determines whether the {@link p_readonly_mode} property was set by the user or
    * automatically by the editor.  This property is available only when the
    * control is displayed.
    *
    * <p>The editor has an option to automatically set and reset read only mode
    * based on the read only attribute (UNIX: permissions) of the file on disk.
    * We added this property so we could tell when the user has overridden the
    * automatic processing.  The {@link read_only_mode} and {@link read_only_mode_toggle}
    * commands turn this property on.
    *
    * @see p_readonly_mode
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   boolean p_readonly_set_by_user;

   /**
    * Returns the number of lines down from the top of the window.  Sets the
    * cursor on the line which is the specified number of lines down from the
    * top line of the window.
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_rel_line;

   /**
    * Determines the current line number.  Note that <b>p_RLine</b> (short for "real
    * line") does not include lines which are non-savable (lines with NOSAVE_LF
    * flag set).  Use the {@link p_line} property to count lines which will not be saved
    * in your file.  The Top of File line is line 0.  A list box has a line 0,
    * but it is never displayed.  If the current line number is not already known,
    * it is determined.  If the <b>p_RLine</b> property is set to a value greater than
    * the number of lines in the buffer, the cursor is placed on the last line.
    * This property is available only when the control is displayed.
    *
    * @see p_line
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_RLine;

   /**
    * Returns the number of lines in the current buffer.  This property does
    * not count non-saveable lines (lines with the NOSAVE_LF flag set).  Use the
    * {@link p_Noflines} property to count all lines.
    *
    * @see p_Noflines
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_RNoflines;

   /**
    * Determines the scroll bars displayed for the current window.  The
    * <b>p_scroll_bar</b> property may be one of the following constants defined in
    * "slick.sh":
    * <DL compact style="margin-left:20pt">
    * <DT>SB_NONE<DD style="marginleft:90pt">
    *    No scroll bars.
    * <DT>SB_HORIZONTAL<DD style="marginleft:90pt">
    *    Display horizontal scroll bar.
    * <DT>SB_VERTICAL<DD style="marginleft:90pt">
    *    Display vertical scroll bar.  May only appear when there are enough items in the list.
    * <DT>SB_BOTH<DD style="marginleft:90pt">
    *    Display horizontal and vertical scroll bars.
    * </DL>
    *
    * @appliesTo Editor_Control, List_Box, File_List_Box, Directory_List_Box, Tree_View
    * @categories Editor_Control_Properties, List_Box_Properties, Directory_List_Box_Properties, Tree_View_Properties
    */
   int p_scroll_bars;

   /**
    * Determines the left edge scroll position in pixels when the window is
    * scrolled.  A scroll position of zero means the first character of every
    * line can be seen.  A negative scroll position means the window is not
    * scrolled and the {@link p_left_edge} property determines the left edge scroll
    * position.  This property is available only when the control is displayed.
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_scroll_left_edge;
   /**
    * Determines the length of a selection in bytes.  A value of 0 indicates
    * that no characters are selected.  This property is available only when the
    * control is displayed.
    *
    * @see _get_sel
    * @see _set_sel
    * @see p_sel_start
    *
    * @appliesTo List_Box, Combo_Box, Text_Box
    * @categories List_Box_Properties, Combo_Box_Properties, Text_Box_Properties
    */
   int p_sel_length;
   /**
    * Determines the position of the left most character of the selection.  A
    * value of 1 indicates the first character.  This property is available only
    * when the control is displayed.
    *
    * @see _get_sel
    * @see _set_sel
    * @see p_sel_length
    *
    * @appliesTo List_Box, Combo_Box, Text_Box
    * @categories List_Box_Properties, Combo_Box_Properties, Text_Box_Properties
    */
   int p_sel_start;

   /**
    * @deprecated
    * This property is being dropped.  Use the
    * <b>p_ShowSpecialChars</b> property instead.
    *
    * @appliesTo Editor_Control, Edit_Window
    *
    * @categories Edit_Window_Properties, Editor_Control_Properties
    *
    */
   int p_show_tabs;

   /**
    * Determines whether the <b>_save_file</b> function (used by
    * <b>save</b> command) inserts or removes the EOF character that
    * may be appended to the end of DOS format ASCII files.
    *
    * @appliesTo Editor_Control, Edit_Window
    *
    * @categories Edit_Window_Properties, Editor_Control_Properties
    *
    */
   boolean p_showeof;

   /**
    * Determines the picture which is diplayed at the far left of a all tree
    * items with children.
    *
    * @appliesTo Tree_View
    *
    * @categories Tree_View_Properties
    *
    */
   boolean p_ShowRoot;

   /**
    * Determines what special characters are displayed for the current
    * buffer.  This property is only available when the object is displayed.
    * The p_ShowSpecialChars property is one or more of the following
    * flags defined in "slick.sh":
    *
    * <ul>
    * <li>SHOWSPECIALCHARS_NLCHARS</li>
    * <li>SHOWSPECIALCHARS_TABS</li>
    * <li>SHOWSPECIALCHARS_SPACES</li>
    * <li>SHOWSPECIALCHARS_EOF</li>
    * <li>SHOWSPECIALCHARS_FORMFEED</li>
    * <li>SHOWSPECIALCHARS_ALL</li>
    * </ul>
    *
    * @appliesTo Editor_Control, Edit_Window
    *
    * @categories Edit_Window_Properties, Editor_Control_Properties
    *
    */
   int p_ShowSpecialChars;

   /**
    * Determines the amount to change <b>p_value</b> when the mouse is
    * clicked on a scroll bar arrow.
    *
    * @appliesTo Hscroll_Bar, Vscroll_Bar
    *
    * @categories Hscroll_Bar_Properties, Vscroll_Bar_Properties
    *
    */
   int p_small_change;

   /**
    * Determines whether Soft Wrap is on or off.  When on, lines
    * longer than the window width are wrapped.  This property
    * is only available when the control is displayed.
    *
    * @see p_SoftWrapOnWord
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   boolean p_SoftWrap;
   /**
    * When Soft Wrap is on, determines whether lines are split
    * on character or words.
    *
    * @see p_SoftWrap
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   boolean p_SoftWrapOnWord;
   /**
    * Determines whether macro source code is generated when macro
    * recording is on and this editor control has focus.
    *
    * @appliesTo Editor_Control, Edit_Window
    *
    * @categories Edit_Window_Properties, Editor_Control_Properties
    *
    */
   boolean p_SourceRecording;

   /**
    * Determines the extra spacing in twips between each line.
    *
    * @appliesTo Tree_View
    *
    * @categories Hscroll_Bar_Properties, Vscroll_Bar_Properties
    *
    */
   int p_SpaceY;

   /**
    * Determines whether the picture is scaled to fit the size of the window.
    * The <b>p_auto_size</b> and <b>p_picture</b> properties must be
    * non-zero for this property to have any effect.
    *
    * @appliesTo Picture_Box, Image
    *
    * @categories Image_Properties, Picture_Box_Properties
    *
    */
   boolean p_stretch;

   /**
    * Determines whether embedded and non-embedded colors
    * should be swapped when displaying buffer text.
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   boolean p_SwapColors;
   /**
    * Determines the amount to indent when the tab key is pressed.
    * This property is ignored in "Plain Text" and "Cobol" modes.
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_SyntaxIndent;

   /**
    * Determines the tabs for the current buffer.  This property is available
    * only when the control is displayed.  <b>p_tabs</b> is a string in the
    * format: <i>t1 t2 t3 ... tN</i>.  Where <i>t1... tN</i> represent tab
    * stop column positions in increasing order.  When setting this property,
    * you may specify a string of the format "+<i>number</i>" to set tab
    * stops in increments of a number.  Tab stops continue past the last tab
    * stop by repeating the difference of the last two tab stop values.
    *
    * @example
    * <pre>
    * p_tabs="+3";  // Set the tab stops in increments of 3.  "1 4 "
    * parse p_tabs with t1 t2
    * message('t1='t1' t2='t2);
    * </pre>
    *
    * @appliesTo Edit_Window, Editor_Control
    *
    * @categories Edit_Window_Properties, Editor_Control_Properties
    *
    */
   _str p_tabs;

   /**
    * Determines the number of tabs per row.  This property is ignored if
    * <b>p_MultiRow</b> is <b>false</b>.
    *
    * @appliesTo SSTab
    *
    * @categories SSTab_Properties
    * @deprecated No longer supported
    *
    */
   int p_TabsPerRow;

   /**
    * @return Returns the index in the names table which was used to load or update
    * the form.  This property is set by the <b>_load_template</b> and
    * <b>_update_template</b> functions.  The purpose of this property is
    * to allow you to determine the name of the form
    * (<b>name_name</b>(p_template)) which should be opened for
    * editing when the user selects to edit the current dialog box
    * (Shift+Space).  This property is available only when the form is
    * displayed.
    *
    * @appliesTo Form
    *
    * @categories Form_Properties
    *
    */
   int p_template;

   /**
    * Determines the text of a combo box or text box.  When this property is
    * set, an <b>on_change</b> event will occur.
    *
    * @appliesTo Combo_Box, Text_Box
    *
    * @categories Combo_Box_Properties, Text_Box_Properties
    *
    */
   _str p_text;

   /**
    * Determines the tile id of the window.  This property is used to keep
    * track of tile groups.  Windows with the same tile id don't overlap
    * (unless a macro did something wrong).  In addition, when the editor
    * sets the focus to an edit window, all windows with the same tile id are
    * moved in front in the Z order.  This property is only available when
    * the object is displayed.
    *
    * @appliesTo Edit_Window
    *
    * @categories Edit_Window_Properties
    *
    */
   int p_tile_id;
   /** 
    * If non-zero, this id is appended to the end of the filename 
    * displayed for a window or in a window list. This id is not 
    * used for a file/buffer list. User of VSAPI must call 
    * vsMDIRefreshDuplicateWindows in order for this to 
    * update properly. 
    */
   int p_mdi_child_duplicate_id;

   /**
    * When this property is <b>true</b>, the caption at the top of a form is
    * smaller.  This property is typically used for floating tool bar forms.
    * This property is not supported when the object is displayed and is
    * ignored on all platforms except Windows 95/98 and Windows NT
    * version >=4.0.
    *
    * @appliesTo Form
    *
    * @categories Form_Properties
    *
    */
   boolean p_tool_window;

   /**
    * When this property is <b>true</b>, the caption at the top of a form is
    * smaller.  This property is typically used for floating tool bar forms.
    * This property is not supported when the object is displayed and is
    * ignored on all platforms except Windows 95/98 and Windows NT
    * version >=4.0.
    *
    *
    * <dl compact style="margin-left:20pt">
    * <dt>VSTBBORDER_BORDER</dt><dd>May display extra necessary border.</dd>
    * <dt>VSTBBORDER_GRABBARS</dt><dd>Displays double bars so that the toolbar (usually one where buttons can be added) can be dragged with the mouse.</dd>
    * </dl>
    *
    * @appliesTo Form
    * @categories Form_Properties
    */
   int p_ToolbarBorder;

   /**
    * <p>If non-zero, this determines how text gets inserted/deleted and how
    * lines are truncated.  Tab characters are not expanded when this
    * property is set.  This property was added to support mainframe legacy
    * code which is very column oriented and is typically set to 72.  When
    * source code is written using ISPF, the last 8 columns (usually columns
    * 73-80) are used for line numbers.  ISPF tries to make sure that when
    * text is inserted or deleted in columns 1-72 that the line numbers stay in
    * the same column.  This property has allows you to ensure that data to
    * the right of the truncation length does not change position.  In
    * addition, newly inserted lines are truncated at the length specified by
    * this property.  This property has no effect when saving a file.</p>
    *
    * <p>The following built-in functions (and any command which accesses
    * these built-ins) are effected by this property:</p>
    *
    * <dl>
    * <dt><b>_reflow_selection</b></dt><dd>
    *    Only text at or before the truncation length is reflowed.</dd>
    *
    * <dt><b>insert_line</b>, <b>vsInsertLine</b></dt><dd>
    *    Lines longer than the truncation length are truncated.</dd>
    *
    * <dt><b>replace_line</b>, <b>vsReplaceLine</b></dt><dd>
    *    Lines longer than the truncation length are truncated and
    * a error message is displayed.</dd>
    *
    * <dt><b>_split_line</b>, <b>vsSplitLine</b></dt><dd>
    *    The text to the right of the truncation length stays on the
    * current line and is not inserted into the next line.</dd>
    *
    * <dt><b>_join_line</b>, <b>vsJoinLine</b></dt><dd>
    *    The join is aborted if the join will create a line longer
    * than the truncation length.   An error status is returned if
    * the join is aborted.</dd>
    *
    * <dt><b>_JoinLineToCursor</b>, <b>vsJoinLineToCursor</b></dt><dd>
    *    The join is aborted if the join will create a line longer
    * than the truncation length.   An error status is returned if
    * the join is aborted.</dd>
    *
    * <dt><b>_insert_text</b>, <b>vsInsertText</b></dt><dd>
    *    Any resulting lines longer than the truncation length are
    * truncated.  In addition, the text to the right of the
    * truncation length on the current line is not effected.  If the
    * cursor is past the truncation length, the text is inserted
    * into the next line.</dd>
    *
    * <dt><b>_delete_text</b>, <b>vsDeleteText</b></dt><dd>
    *    The text to the right of the truncation length on the
    * current line is not effected.</dd>
    *
    * <dt><b>_delete_selection</b>,<b>vsDeleteSelection</b></dt><dd>
    *    The text to the right of the truncation length on the
    * current line is not effected.</dd>
    *
    * <dt><b>vsTruncQLineLength</b></dt><dd>
    *    Returns the length of the current line as if the text to the
    * right of the truncation length does not exist.  In addition,
    * trailing blanks (tab characters count) are not included in
    * the length.</dd>
    *
    * <dt><b>_SearchInitSkipped</b>,<b>vsSearchInitSkipped</b></dt><dd>
    *    Call this function before performing search and replace
    * operation to reset NofSkipped and Skipped lines data
    * returned by the _SearchQSkipped and
    * _SearchQNofSkipped functions.</dd>
    *
    * <dt><b>_SearchQSkipped</b>, <b>vsSearchQSkipped</b></dt><dd>
    *    Call this function after performing search and replace
    * operation to determine the line numbers where the
    * replace operation was skipped to avoid line truncation.</dd>
    *
    * <dt><b>_SearchQNofSkipped</b>,<b>vsSearchQNofSkipped</b></dt><dd>
    *    Call this function after performing search and replace
    * operation to determine how many replace operations were
    * skipped to avoid line truncation.</dd>
    *
    * <dt><b>keyin</b>, <b>vsKeyin</b></dt><dd>
    *    Text to the right of the truncation length on the current
    * line is not effected.</dd>
    *
    * <dt><b>search</b>, <b>search_replace</b>, <b>vsSearch</b>,
    * <b>vsSearchReplace</b>, <b>vsRepeatSearch</b></dt><dd>
    *    Multi-line search or replace is not supported.  Search is
    * performed as if the data to the right of the truncation
    * length is not there.  Unfortunately, using regular
    * expressions to match the end of line ($) does not work as
    * if the data to the right of the truncation length is not there.
    * After a replace, the text to the right truncation length is
    * not effected.</dd>
    *
    * <dt><b>_overlay_block_selection</b>, <b>_adjust_block_selection</b>,
    * <b>_fill_selection</b></dt><dd>
    *    Text to the right of the truncation length is not effected.</dd>
    *
    * <dt><b>_shift_selection_left</b>, <b>vsShiftSelectionLeft</b></dt><dd>
    *    Text to the right of the truncation length is not effected.</dd>
    *
    * <dt><b>_shift_selection_right</b>, <b>vsShiftSelectionRight</b></dt><dd>
    *    Text to the right of the truncation length is not effected.</dd>
    *
    * <dt><b>_copy_to_cursor</b>, <b>vsCopyToCursor</b></dt><dd>
    *    Text to the right of the truncation length is not effected.
    * Any resulting lines longer than then truncation length are
    * truncated.</dd>
    *
    * <dt><b>_move_to_cursor</b></dt><dd>
    *    Text to the right of the truncation length is not effected.
    * Any resulting lines longer than then truncation length are
    * truncated.</dd>
    * </dl>
    *
    * <p>The following built-in functions have been enhanced to support the
    * truncation length:</p>
    *
    * <dl>
    * <dt><b>_expand_tabsc</b>, <b>vsExpandTabsC</b>,
    * <b>_expand_tabsc_raw</b></dt><dd>
    *    A width value of -2 specifies that the
    * <b>vsTruncQLineLength</b> be used instead of the real
    * line length.</dd>
    *
    * <dt><b>_text_colc</b>, <b>vsTextColC</b></dt><dd>
    *    A new 'E' option specifies that the
    * <b>vsTruncQLineLength</b> be used instead of the real
    * line length.</dd>
    * </dl>
    *
    * <p>The following built-in functions have been enhanced to support
    * maximum line length:</p>
    *
    * <dl>
    * <dt><b>_save_file</b>, <b>vsSaveFile</b></dt><dd>
    *    A new +CL option (Check Line length option) was
    * added.  When specified, the new
    * <b>vsCheckLineLengths</b> function is called if the
    * output file has a required record length or if the source
    * file has a non-zero <b>p_MaxLineLength</b> property.</dd>
    *
    * <dt><b>_CheckLineLengths</b>, <b>vsCheckLineLengths</b></dt><dd>
    *    Allows you to get a list of lines longer than a specified
    * line length.  Usually, <b>p_MaxLineLength</b> is
    * specified.</dd>
    * </dl>
    *
    * @see p_TruncateLength
    * @see p_MaxLineLength
    * @see trunc
    * @see p_AutoSelectLanguage
    *
    * @appliesTo Edit_Window, Editor_Control
    *
    * @categories Edit_Window_Properties, Editor_Control_Properties
    *
    */
   int p_TruncateLength;

   /**
    * Determines the maximum number of undo steps stored for the current
    * buffer.  This property may not be set to a value less than 0.  This
    * property is only available when the object is displayed.
    *
    * @appliesTo Edit_Window, Editor_Control
    *
    * @categories Edit_Window_Properties, Editor_Control_Properties
    *
    */
   int p_undo_steps;

   /**
    * Determines whether the buffers data is UTF-8.
    *
    * @appliesTo Edit_Window, Editor_Control
    *
    * @categories Edit_Window_Properties, Editor_Control_Properties
    *
    */
   boolean p_UTF8;
   /**
    * This property is not used.
    */
   _str p_validate_info;

   /**
    * <p><b>Radio Button</b> - Value of 1 turns on radio button.  Value of 0 turns off
    * radio button.</p>
    *
    * <p><b>Check Box</b> - Value may be one of the following:</p>
    *
    * <dl>
    * <dt>0</dt><dd>Not checked.</dd>
    * <dt>1</dt><dd>Checked.</dd>
    * <dt>2</dt><dd>Grayed.</dd>
    * </dl>
    *
    * <p><b>Hscroll Bar, Vscroll Bar</b> - Indicates the scroll amount where
    * <b>p_min</b>>= <b>p_value</b> &lt;=<b>p_max</b>.  Setting the
    * p_value property has no effect.</p>
    *
    * <p><b>Gauge</b> - Indicates a portion of a total where <b>p_min</b>>=
    * <b>p_value</b> &lt;=<b>p_max</b>.</p>
    *
    * <p><b>Picture Box, Image</b> - Determines which state of a picture gets
    * displayed where 0>= p_value &lt;<b>p_Nofstates</b>.</p>
    *
    * <p><b>Frame</b> - Only applies when the frames
    * <b>p_checkable</b> value is true.  In this case,
    * <b>p_value</b> is the value of the checkbox.  Does not support
    * tri-state checkboes. Value may be
    * one of the following:</p>
    *
    * <dl>
    * <dt>0</dt><dd>Not checked.</dd>
    * <dt>1</dt><dd>Checked.</dd>
    * </dl>
    *
    * <p>Here's how you can create a toolbar for the editor without 
    * writing any code at all:</p> 
    *
    * <ol>
    * <li>Create a new form for editing ("Macro", "New").
    * <li>Create an image control.  Double click on the image
    * control (bottom right.  Looks like slanted rectangle)
    * in the dialog editor.</li>
    * <li>Set the <b>p_picture</b> property to
    * <b>find.bmp</b>.  Make sure you specify the
    * full path (c:\vslick\bitmaps is the default path used
    * by installation program).</li>
    * <li>Set the <b>p_command</b> property to <b>gui-
    * find</b>.  Notice that the down arrow of the combo
    * box displays all the editor commands.</li>
    * <li>Set the <b>p_message</b> property to "Searches
    * for a string you specify".</li>
    * <li>Set the <b>p_style</b> property to
    * <B>PSPIC_HIGHLIGHTED_BUTTON</B>.</li>
    * <li>Repeat the steps 2-6 to add more tool bar buttons.</li>
    * </ol>
    *
    * <p>Save your tool bar.  To run it such that is stays on top of the MDI
    * Window, type the command "show -mdi <i>form-name</i>" on the
    * SlickEdit command line where <i>form-name</i> is the name
    * of the tool bar form you created.  If you want to bind it to a key, use
    * macro recording to record typing the command on the command line.
    * The mouse may be used during macro recording to place your cursor
    * on the command line.</p>
    *
    * @example
    * <pre>
    * // For this example, create a picture or image
    * control and
    * // set the p_picture property to "_arrow.bmp" or any
    * two
    * // state bitmap.  Also set the p_Nofstates property
    * to 2.
    * #include 'slick.sh'
    * defeventtab form1;
    * image1.on_create()
    * {
    *    index=_update_picture(-
    * 1,bitmap_path_search("_arrow.bmp"));
    *    if (index<0) {
    *        if (index==FILE_NOT_FOUND_RC) {
    *           _message_box("Picture find.bmp was not found");
    *        } else {
    *           _message_box("Error loading picture
    * find.bmp\n\n":+
    *                        get_message(index));
    *        }
    *        return("");
    *    }
    *    p_picture=index;
    *    p_Nofstates=2;
    *    p_message="Searches for a string you specify";
    *    p_style=PSPIC_AUTO_BUTTON;
    * }
    * picture1.lbutton_down()
    * {
    *    mou_mode(1)
    *    mou_capture();
    *    done=0;
    *    for (;;) {
    *       event=get_event();
    *       switch (event) {
    *       case MOUSE_MOVE:
    *          // 'm' specifies mouse position in current
    * scale mode
    *          mx=mou_last_x('m');
    *          my=mou_last_y('m');
    *          if (mx>=0 && my>=0 && mx<p_width &&
    * my<p_height) {
    *             if (!p_value) {
    *                // Show the button pushed in.
    *                p_value=1;
    *             }
    *          } else {
    *             if (p_value) {
    *                // Show the button up.
    *                p_value=0;
    *             }
    *          }
    *          break;
    *       case LBUTTON_UP:
    *       case ESC:
    *          p_value=1;
    *          done=1;
    *       }
    *       if (done) break;
    *    }
    *    mou_mode(0);
    *    mou_release();
    *    return('')
    * }
    * </pre>
    *
    * @appliesTo Radio_Button, Check_Box, Hscroll_Bar, Vscroll_Bar, Picture_Box,
    * Image, Gauge, Frame
    *
    * @categories Check_Box_Properties, Gauge_Properties, Hscroll_Bar_Properties,
    * Image_Properties, List_Box_Properties, Picture_Box_Properties,
    * Radio_Button_Properties, Vscroll_Bar_Properties,
    * Frame_Properties
    *
    */
   int p_value;

   /**
    * Determines the preferred style of casing for value elements 
    * for the current buffer.  This property is available only when 
    * the control is displayed and is valid only in languages where
    * value elements are used (e.g. HTML, XML).  
    *  
    * <p>values and respective results: 
    * <ol> 
    * <li>WORDCASE_PRESERVE - does not change </li>
    * <li>WORDCASE_LOWER - lowercase </li>
    * <li>WORDCASE_UPPER - uppercase </li> 
    * <li>WORDCASE_CAPITALIZE - capitalize the first letter only 
    * </li> 
    * </ol>
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_value_casing;

   /**
    * Not used.
    */
   int p_vsb_max;

   /**
    * @return Returns the spacing in pixels between the left edge of the window and
    * text displayed in the window.  This property is available only when the
    * object is displayed.
    *
    * @appliesTo Edit_Window, Editor_Control, List_Box
    *
    * @categories Edit_Window_Properties, Editor_Control_Properties, List_Box_Properties
    *
    */
   int p_windent_x;

   /**
    * @return Returns the spacing in pixels between the top of the window and text
    * displayed in the window.  This property is available only when the
    * object is displayed.
    *
    * @appliesTo List_Box
    *
    * @categories List_Box_Properties
    *
    */
   int p_windent_y;

   /**
    * Determines the window state.  This property is available only when the
    * object is displayed.  The p_window_state property may be one of the
    * following:
    *
    * <dl>
    * <dt>'I'</dt><dd>Iconized window</dd>
    * <dt>'M'</dt><dd>Maximized window</dd>
    * <dt>'N'</dt><dd>Normalized window</dd> 
    * <dt>'F'</dt><dd>Fullscreen</dd> 
    * </dl>
    *
    * @appliesTo MDI_Window, Edit_Window
    *
    * @categories Edit_Window_Properties, MDI_Window_Properties
    *
    */
   _str p_window_state;

   /**
    * Determines the word characters for a buffer.  This value must be a
    * valid regular expression when placed in square braces.  These word
    * characters are used for word searches and word oriented commands
    * such as <b>next_word</b>, <b>prev_word</b>, and
    * <b>cap_word</b>.
    *
    * @note
    * In previous releases, p_word_chars had been used for searching
    * for symbols under the cursor.  As of SlickEdit 2008, you should
    * not use p_word_chars and instead use {@link p_identifier_chars}, 
    * or the utility functions {@link _clex_identifier_re()} or 
    * {@link _clex_identifier_chars()}.  These functions use the 
    * identifier characters set up in your color coding specification.
    * 
    * @appliesTo Edit_Window, Editor_Control
    *
    * @categories Edit_Window_Properties, Editor_Control_Properties
    */
   _str p_word_chars;

   /**
    * Determines whether a label caption (p_caption) is word wrapped when
    * it does not fit within the window.  This property has no effect if the
    * object is not displayed.
    *
    * @appliesTo Label
    *
    * @categories Label_Properties
    *
    */
   boolean p_word_wrap;

   /**
    * Determines the word wrap style for the current buffer.  The
    * p_word_wrap_style is a combination of the following flags defined in
    * "slick.sh":
    *
    * <dl>
    * <dt>STRIP_SPACES_WWS</dt><dd>Determines whether the
    * paragraph reformatting
    * functions such as
    * <b>reflow_paragraph</b>
    * reformat spaces
    * between words.  This
    * flag should not be used
    * with the
    * JUSTIFY_WWS flag.</dd>
    *
    * <dt>WORD_WRAP_WWS</dt><dd>Determines whether
    * word wrap is on.  When
    * word wrap is on text is
    * word wrapped as it
    * moves past the right
    * margin.</dd>
    *
    * <dt>JUSTIFY_WWS</dt><dd>Determines whether the
    * paragraph reformatting
    * functions such as
    * <b>reflow_paragraph</b>
    * left and right justify
    * the text.  This flag
    * should not be used with
    * the
    * STRIP_SPACES_WWS
    * flag.</dd>
    *
    * <dt>ONE_SPACE_WWS</dt><dd>Determines whether one
    * or two spaces are placed
    * after punctuation
    * characters.</dd>
    * </dl>
    *
    * @see p_margins
    * @see gui_justify
    * @see justify
    * @see gui_margins
    * @see margins
    *
    * @appliesTo Edit_Window, Editor_Control
    *
    * @categories Edit_Window_Properties, Editor_Control_Properties
    *
    */
   int p_word_wrap_style;

   /**
    * Indicates that the buffer contains SBCS/DBCS data and that it needs
    * to be converted to UTF-8 because SlickEdit is running in UTF-
    * 8 mode.  This is always false if SlickEdit is not running in
    * UTF-8 mode.  This property is read-only.
    *
    * @appliesTo Edit_Window, Editor_Control
    *
    * @categories Edit_Window_Properties, Editor_Control_Properties
    *
    */
   boolean p_xlat;

   /**
    * Returns the window id of the active form.   You can not use the name (p_name)
    * of the form to access properties of the active form.  You must use the
    * <b>p_active_form</b> property.  This property is not available when the form is not displayed.
    *
    * @example
    * <PRE>
    *    defeventtab form1;
    *    command1.lbutton_up()
    *    {
    *       // Close the active dialog box.
    *       p_active_form._delete_window();
    *    }
    * </PRE>
    *
    * @categories All_Windows_Properties
    * @appliesTo All_Window_Objects
    */
   int p_active_form;
   /**
    * Determines the brace style of the current buffer. This 
    * property is available only when the control is displayed. 
    *  
    * @example 
    * <pre> 
    *    // begin/end style 1
    *    p_begin_end_style = 0;
    *    if (x) {
    *       x = 5; 
    *    } 
    *  
    *    // begin/end style 2
    *    p_begin_end_style = VS_C_OPTIONS_STYLE1_FLAG;
    *    if (x)
    *    {
    *       x = 5;
    *    }
    *  
    *    // begin/end style 3
    *    p_begin_end_style = VS_C_OPTIONS_STYLE2_FLAG;
    *    if (x)
    *       {
    *       x = 5;
    *       }
    * 
    * </pre>
    *
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_begin_end_style;
   /**
    * Returns the maximum number of lines that can be displayed in the window.
    * This property is currently only useful if all lines have the same font
    * height.
    *
    * @categories Editor_Control_Properties
    */
   int p_char_height;
   /**
    * If the control is displayed, the window id of the first child is returned.
    * Otherwise, an encoded number is returned which can be used to get/set some
    * property values.  Although all objects have this property, some objects
    * such as Text Box and Menu Item can not have any child objects.  For these
    * objects, 0 is always returned.
    *
    * @appliesTo All_Window_Objects
    * @categories All_Windows_Properties
    */
   int p_child;
   /**
    * Determines whether the object is enabled.  When an object is disabled
    * (p_enabled=0), the object can not receive focus.  The font foreground
    * color for a Label, Text Box, and Combo Box is gray (the system disabled
    * color) when the control is disabled.  Objects may receive focus when
    * disabled if they are being edited ({@link p_edit}!=0).
    * </P>
    * @example
    * <PRE>
    * // This example illustrates how to disable a list box and make the items in the list box
    * // appear grayed (not so obvious)
    * #include "slick.sh"
    * defeventtab form1;
    * list1.on_create()
    * {
    *    _lbadd_item('item1');
    *    _lbadd_item('item2');
    *    p_no_select_color=1;
    *    p_enabled=0;
    *    p_forecolor=_rgb(80,80,80);
    * }
    * </PRE>
    *
    * @appliesTo All_Window_Objects
    * @categories All_Windows_Properties
    */
   boolean p_enabled;  // !desktop
   /**
    * Determines the event table used for user level 1 inheritance.
    * This property is automatically set when a Slick-C&reg; module is loaded
    * which defines an event table that identifies the object.
    *
    * @example
    * <PRE>
    *    index={@link find_index}('eventtab_name',EVENTTAB_TYPE);
    *    if (index) {
    *       p_eventtab=index;
    *    }
    * </PRE>
    *
    * @appliesTo All_Window_Objects
    * @categories All_Windows_Properties
    */
    int p_eventtab;
   /**
    * Determines the event table used for user level 2 inheritance.
    * When a control is created with the dialog editor, the p_eventtab2 property
    * is set to a default value.
    *
    * @example
    * <PRE>
    *    index={@link find_index}('eventtab_name',EVENTTAB_TYPE);
    *    if (index) {
    *        // link the event table "eventtab_name" in front of the default user level 2 inheritance.
    *        {@link eventtab_inherit}(index,p_eventtab2);
    *        p_eventtab2=index;
    *    }
    * </PRE>
    *
    * @appliesTo All_Window_Objects
    * @categories All_Windows_Properties
    */
   int p_eventtab2;
   /**
    * Determines whether the font is bold.
    *
    * @appliesTo All_Window_Objects
    * @categories All_Windows_Properties
    */
   boolean p_font_bold;
   /**
    * Determines whether the font is italic.   Command buttons, radio buttons, check boxes,
    * and frame controls do not support this property under UNIX.
    *
    * @appliesTo All_Window_Objects
    * @categories All_Windows_Properties
    */
   boolean p_font_italic;
   /**
    * Determines the font name.  Be sure to set the {@link p_font_printer} property
    * if you want to choose from printer fonts.
    *
    * @example
    * <PRE>
    *    p_font_name="Helvetica";
    *    {@link p_font_size}=18;   // 18 point size.
    * </PRE>
    *
    * @appliesTo All_Window_Objects
    * @categories All_Windows_Properties
    */
   _str p_font_name;
   /**
    * Determines whether the font is chosen from screen fonts or printer fonts.
    * @categories All_Windows_Properties
    */
   boolean p_font_printer;
   /**
    * Determines the font point size.
    *
    * @example
    * <PRE>
    *    {@link p_font_name}="Helvetica";
    *    p_font_size=18;   // 18 point size.
    * </PRE>
    *
    * @appliesTo All_Window_Objects
    * @categories All_Windows_Properties
    */
   _str p_font_size;
   /**
    * Determines the character set used by the font.
    * See VSCHARSET_*.
    *
    * @appliesTo All_Window_Objects
    * @categories All_Windows_Properties
    */
   int p_font_charset;
   /**
    * Determines whether the font has strike through.   Command buttons, radio buttons,
    * check boxes, and frame controls do not support this property under UNIX.
    *
    * @appliesTo All_Window_Objects
    * @categories All_Windows_Properties
    */
   boolean p_font_strike_thru;
   /**
    * Determines whether the font has transparency.   Command buttons, radio buttons,
    * check boxes, and frame controls do not support this property under UNIX.
    *
    * @appliesTo All_Window_Objects
    * @categories All_Windows_Properties
    */
   boolean p_font_transparent;
   /**
    * Determines whether the font is underlined.   Command buttons, radio buttons,
    * check boxes, and frame controls do not support this property under UNIX.
    *
    * @appliesTo All_Window_Objects
    * @categories All_Windows_Properties
    */
   boolean p_font_underline;
   /**
    * Determines whether the font is an outline font.   Command buttons, radio buttons,
    * check boxes, and frame controls do not support this property under UNIX.
    *
    * @appliesTo All_Window_Objects
    * @categories All_Windows_Properties
    */
   boolean p_font_outline;
   /**
    * Determines the background color of a control.
    *
    * <P><b>Form, Label, Text Box, Editor Control, Frame, Radio Button, Check Box,
    * List Box, File List Box, Directory List Box</b> -
    *    Determines the background color of the window.
    *
    * <P><b>Gauge</b> - Determines color of filled portion.
    *
    * <P><b>Combo Box</b> - Determines the foreground text color used in text box and list box.
    *
    * <P><b>Drive List</b> - Determines the foreground text color used in text box and list box.
    *
    * @appliesTo All_Window_Objects
    * @categories All_Windows_Properties
    */
   int p_forecolor;
   /**
    * Determines the whether an opening brace of a function goes on
    * a new line for the current buffer. This property is available
    * only when the control is displayed. 
    *  
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   boolean p_function_brace_on_new_line;
   /**
    *
    * Determines whether the current window has a buffer attatched
    *
    * @appliesTo All_Window_Objects
    *
    * @categories Check_Box_Properties, Combo_Box_Properties,
    * Command_Button_Properties, Directory_List_Box_Properties,
    * Drive_List_Properties, Edit_Window_Properties, Editor_Control_Properties,
    * File_List_Box_Properties, Form_Properties, Frame_Properties,
    * Gauge_Properties, Hscroll_Bar_Properties, Image_Properties,
    * Label_Properties, List_Box_Properties, MDI_Window_Properties,
    * Picture_Box_Properties, Radio_Button_Properties, Spin_Properties,
    * Text_Box_Properties, Tree_View_Properties, Vscroll_Bar_Properties
    */
   boolean p_HasBuffer;
   /**
    *
    * Determines whether the current window was created by _CreateTempEditor2() which
    * is used by _open_temp_view() and _create_temp_view().
    *
    * @appliesTo All_Window_Objects
    *
    * @categories Check_Box_Properties, Combo_Box_Properties,
    * Command_Button_Properties, Directory_List_Box_Properties,
    * Drive_List_Properties, Edit_Window_Properties, Editor_Control_Properties,
    * File_List_Box_Properties, Form_Properties, Frame_Properties,
    * Gauge_Properties, Hscroll_Bar_Properties, Image_Properties,
    * Label_Properties, List_Box_Properties, MDI_Window_Properties,
    * Picture_Box_Properties, Radio_Button_Properties, Spin_Properties,
    * Text_Box_Properties, Tree_View_Properties, Vscroll_Bar_Properties
    */
   boolean p_IsTempEditor;
   /**
    * Determines the height of a window in the scale mode of {@link p_xyscale_mode}.
    *
    * @appliesTo All_Window_Objects
    * @categories All_Windows_Properties
    */
   int p_height;
   /**
    * <b>Menu, Menu Item</b> - Gets or sets help command.  The {@link help} command is executed
    * when F1 is pressed while the menu/menu item is selected.  The help command
    * is typically a {@link help} or {@link popup_imessage} command.  When menus are displayed,
    * there is no instance handle.  Menu and menu item properties can only be
    * accessed in menu resources.  The {@link _menu_get_state} and {@link _menu_set_state}
    * function may be used to get and set menu properties of displayed menus.
    *
    * <P><b>Other objects</b> - Gets or sets a help string.  Help is displayed when F1 is
    * pressed or when a command button with a help string defined (p_help!='')
    * that does not have an {@link lbutton_up} event handler is pressed.  If the help
    * string starts with a '?' character, the characters that follow are
    * displayed in a message box.  The help string may also specify a unique
    * keyword in the "vslick.hlp" (UNIX: "uvslick.hlp") help file.  The unique
    * keywords for the help file are contained in the file "vslick.lst" (UNIX:
    * "uvslick.lst").  In addition, you may specify a unique keyword for any
    * windows help file by specifying a string in the format:
    * <b><i>keyword</i>:<i>help_filename</i></b>.
    *
    * <P>When F1 is pressed the dialog manager performs the following search to
    * find the help to display:
    * <OL>
    * <LI>If the active control has help defined, display the help.
    * <LI>If the active form has help defined, display the help.
    * <LI>Search for any control with help defined.
    * </OL>
    *
    * @appliesTo All_Window_Objects
    * @categories All_Windows_Properties
    */
   _str p_help;
   /**
    * Returns system dependent window handle for client area.  On Windows, this is the HWND.  This is 0 for an image control.
    *
    * @appliesTo All_Window_Objects
    * @categories All_Windows_Properties
    */
   long p_hwnd;
   /**
    * Returns system dependent window handle for window frame.  On Windows, this is the same as the client area.  This is 0 for an image control.
    *
    * @appliesTo All_Window_Objects
    * @categories All_Windows_Properties
    */
   long p_hwndframe;
   _str p_init_info;
   /**
    * Determines the initialization style.  The <b>p_init_style</b> property
    * is one or more of the following flags:
    * <DL compact style="margin-left:20pt">
    * <DT>IS_SAVE_XY<DD style="marginleft:60pt">
    *    Indicates that the form x and y values should be saved in the ".command"
    *    buffer when the form is closed.  The {@link show} function maybe given the -xy
    *    option to display the form in its previous position.
    * <DT>IS_REINIT<DD style="marginleft:60pt">
    *    Indicates that when {@link _delete_window} is called to delete a form window, the
    *    form window should be made invisible instead of destroyed.  The destroy
    *    events and all other side effects of the _delete_window function still take place.
    * <DT>IS_HIDEONDEL<DD style="marginleft:60pt">Same as IS_REINIT.
    * </DL>
    *
    * @appliesTo Form
    * @categories Form_Properties
    */
   int p_init_style;
   /**
    * Returns non-zero DOCKINGAREA_* constant indicating which area 
    * the current object is docked on, otherwise returns 0 if 
    * object is not docked. If the object is not a form 
    * (p_object==OI_FORM), then 0 is returned. This property is 
    * available only when the object is displayed. 
    *
    * @appliesTo All_Window_Objects
    * @categories All_Windows_Properties
    */
   int p_DockingArea;
   /**
    * Returns non-zero value if the current object is an MDI edit window.
    *
    * @appliesTo All_Window_Objects
    * @categories All_Windows_Properties
    */
   int p_mdi_child;
   /**
    * Returns non-zero value if the current form is a modal form.  When the
    * {@link _modal_wait} function is called with a specified form, the <b>p_modal</b> property
    * for the form is set to a non-zero value.  This property may only be
    * accessed when the control is displayed.
    *
    * @appliesTo Form
    * @categories Form_Properties
    */
   boolean p_modal;
   /**
    * Determines how the click to get focus policy.  This property may be one
    * of the following values:
    *
    * <dl style="margin-left:20pt">
    * <dt>MA_DEFAULT</dt><dd>Action depends on the control.</dd>
    * <dt>MA_ACTIVATE</dt><dd>Active the form, give the control focus, and process a click event.</dd>
    * <dt>MA_ACTIVATEANDEAT</dt>Active the form and give the control focus.<dd></dd>
    * <dt>MA_NOACTIVATE</dt><dd>Do not active the form and process the click event</dd>
    * <dt>MA_NOACTIVATEANDEAT</dt><dd>Do not active the form.</dd>
    * </dl>
    *
    * @appliesTo All_Window_Objects
    * @categories All_Windows_Properties
    */
   int p_MouseActivate;

   /**
    * Determines the mouse pointer displayed when the mouse is within the window.
    * This property may be one of the following constants defined in "slick.sh":
    * <dl style="margin-left:20pt">
    * <dt>MP_DEFAULT<dd>Shape of mouse pointer depends on control.
    * <dt>MP_ARROW
    * <dt>MP_CROSS
    * <dt>MP_IBEAM
    * <dt>MP_SIZE
    * <dt>MP_SIZENESW
    * <dt>MP_SIZENS
    * <dt>MP_SIZENWSE
    * <dt>MP_SIZEWE
    * <dt>MP_UP_ARROW
    * <dt>MP_HOUR_GLASS
    * </dl>
    * Try the above constants to see what they look like.
    *
    * @example
    * <pre>
    *    #include "slick.sh"
    *    defmain()
    *    {
    *       p_mouse_pointer=MP_HOUR_GLASS;
    *    }
    * </pre>
    *
    * @appliesTo All_Window_Objects
    * @categories All_Windows_Properties
    */
   int p_mouse_pointer;
   /**
    * Determines the name of the current object.
    * Control names are looked up relative to the current form ({@link p_active_form}).
    *
    * @appliesTo All_Window_Objects
    * @categories All_Windows_Properties
    */
   _str p_name;
   /**
    * If the control is displayed, the window id of the next window is returned.
    * Otherwise, an encoded number is returned which can be used to get/set some
    * property values.  When menus are displayed, there is no instance handle.
    * Menu and menu item properties can only be accessed in menu resources.
    *
    * @appliesTo All_Window_Objects
    * @categories All_Windows_Properties
    */
   int p_next;
   /**
    * Returns the object type of the current window.  The p_object property can
    * be one of the following constants defined in "slick.sh":
    * <dl style="margin-left:20pt">
    * <dt>OI_MDI_FORM
    * <dt>OI_FORM
    * <dt>OI_TEXT_BOX
    * <dt>OI_CHECK_BOX
    * <dt>OI_COMMAND_BUTTON
    * <dt>OI_RADIO_BUTTON
    * <dt>OI_FRAME
    * <dt>OI_LABEL
    * <dt>OI_LIST_BOX
    * <dt>OI_HSCROLL_BAR
    * <dt>OI_VSCROLL_BAR
    * <dt>OI_COMBO_BOX
    * <dt>OI_PICTURE_BOX
    * <dt>OI_IMAGE
    * <dt>OI_GAUGE
    * <dt>OI_SPIN
    * <dt>OI_MENU
    * <dt>OI_MENU_ITEM
    * <dt>OI_SSTAB
    * <dt>OI_DESKTOP
    * <dt>OI_SSTAB_CONTAINER
    * <dt>OI_EDITOR
    * <dt>OI_MINIHTML
    * <dt>OI_SWITCH
    * <dt>OI_TEXTBROWSER
    * </dl>
    * When menus are displayed, there is no instance handle.  Menu and menu item
    * properties can only be accessed in menu resources.  The {@link _menu_get_state}
    * function can be used to get the menu flags.  These flags indicate whether
    * the menu item is a submenu which contains other menu items.
    *
    * @appliesTo All_Window_Objects
    * @categories All_Windows_Properties
    */
   int p_object;
   /**
    * Determines whether the current object has been modified.  A non-zero value
    * indicates the object has been modified.  This property is available only
    * when the object is displayed.
    *
    * @appliesTo All_Window_Objects
    * @categories All_Windows_Properties
    */
   boolean p_object_modify;
   /**
    * Determines the old x position in pixels before the x position of the
    * window was changed.  This property is used to determine what other tiled
    * edges need to be adjusted to keep the tiled windows tiled.  The editor
    * sets this property when {@link _move_window}, {@link _tile_windows}, or {@link _cascade_windows}
    * is called.  This property is available only when the object is displayed.
    *
    * @appliesTo All_Window_Objects
    * @categories All_Windows_Properties
    */
   int p_old_x;
   /**
    * Determines the old y position in pixels before the y position of the
    * window was changed.  This property is used to determine what other tiled
    * edges need to be adjusted to keep the tiled windows tiled.  The editor
    * sets this property when {@link _move_window}, {@link _tile_windows}, or {@link _cascade_windows}
    * is called.  This property is available only when the object is displayed.
    *
    * @appliesTo All_Window_Objects
    * @categories All_Windows_Properties
    */
   int p_old_y;
   /**
    * Determines the old width in pixels before the width of the window was
    * changed.  This property is used to determine what other tiled edges need
    * to be adjusted to keep the tiled windows tiled.  The editor sets this
    * property when {@link _move_window}, {@link _tile_windows}, or {@link _cascade_windows} is called.
    * This property is available only when the object is displayed.
    *
    * @appliesTo All_Window_Objects
    * @categories All_Windows_Properties
    */
   int p_old_width;
   /**
    * Determines the old height in pixels before the height of the window was
    * changed.  This property is used to determine what other tiled edges need
    * to be adjusted to keep the tiled windows tiled.  The editor sets this
    * property when {@link _move_window}, {@link _tile_windows}, or {@link _cascade_windows} is called.
    * This property is available only when the object is displayed.
    *
    * @appliesTo All_Window_Objects
    * @categories All_Windows_Properties
    */
   int p_old_height;
   /**
    * Returns the parent window id.  When a form has a parent, the form is not
    * clipped within the parent window except in the case of an edit window form
    * which is clipped with the MDI window.  Controls are always clipped to the
    * parent window.  Often the parent window id is used to determine what
    * object a dialog box should act on.  Due to our implementation of the MDI
    * window, p_parent will be 0 if you {@link show} a dialog box with the <b>-mdi</b> option.
    *
    * @see _form_parent
    *
    * @appliesTo All_Window_Objects
    * @categories All_Windows_Properties
    */
   int p_parent;
   /**
    * The window id of the previous window is returned.
    * This property is available only when the control is displayed.
    *
    * @appliesTo All_Window_Objects
    * @categories All_Windows_Properties
    */
   int p_prev;

   /**
    * Determines whether updating font and picture properties immediately
    * cause the control to be redrawn.  This property can only be accessed
    * when the control is displayed.  Use this property only when you are
    * trying to update several properties at once and want to the control to
    * be redrawn only once.
    *
    * @example
    * <pre>
    * command1.lbutton_up()
    * {
    *   // Change the font of a text box control and redraw the control
    * only once.
    *    text1.p_redraw=0;  // Don't redraw the control
    *    text1.p_font_name="Courier";
    *    text1.p_font_size=10;
    *    text1.p_redraw=1;  // Redraw the control now
    * }
    * </pre>
    *
    * @appliesTo Label, Text_Box, Edit_Window, Editor_Control, Frame, Drive_List,
    * Command_Button, Radio_Button, Check_Box, Combo_Box, List_Box,
    * File_List_Box, Directory_List_Box, Picture_Box, Image
    *
    * @categories Check_Box_Properties, Combo_Box_Properties,
    * Command_Button_Properties, Directory_List_Box_Properties,
    * Drive_List_Properties, Edit_Window_Properties, Editor_Control_Properties,
    * File_List_Box_Properties, Frame_Properties, Image_Properties, Label_Properties,
    * List_Box_Properties, Picture_Box_Properties, Radio_Button_Properties,
    * Text_Box_Properties
    *
    */
   boolean p_redraw;

   /**
    * Determines the scale mode and may be SM_PIXEL or SM_TWIP.
    * 1440 twips represent one inch on the display.  The scale mode
    * determines unit of measure used by some properties and methods.  The
    * dialog editor does not yet allow you set the initial value of the scale
    * mode property.  The scale mode for the MDI Window and Edit
    * Windows must be SM_PIXEL.  The primary purpose of a scale mode
    * is to allow you to create dialog box templates that can easily be
    * adjusted for different screen resolutions.  If there were only one screen
    * resolution, you could always use a pixel scale mode.
    *
    * @appliesTo All_Window_Objects
    *
    * @categories Check_Box_Properties, Combo_Box_Properties,
    * Command_Button_Properties, Directory_List_Box_Properties,
    * Drive_List_Properties, Edit_Window_Properties, Editor_Control_Properties,
    * File_List_Box_Properties, Form_Properties, Frame_Properties, Gauge_Properties,
    * Hscroll_Bar_Properties, Image_Properties, Label_Properties, List_Box_Properties,
    * MDI_Window_Properties, Picture_Box_Properties, Radio_Button_Properties,
    * Spin_Properties, Text_Box_Properties, Tree_View_Properties, Vscroll_Bar_Properties
    *
    */
   int p_scale_mode;

   /**
    * Determines whether the object is selected.  If the <b>p_edit</b>
    * property of the object is non-zero, selection handles are displayed
    * around the object.  This property is available only when the object is
    * displayed.
    *
    * @appliesTo All_Window_Objects
    *
    * @categories Check_Box_Properties, Combo_Box_Properties,
    * Command_Button_Properties, Directory_List_Box_Properties, Drive_List_Properties,
    * Editor_Control_Properties, File_List_Box_Properties, Form_Properties, Frame_Properties,
    * Gauge_Properties, Hscroll_Bar_Properties, Image_Properties, Label_Properties,
    * List_Box_Properties, Picture_Box_Properties, Radio_Button_Properties, Spin_Properties,
    * Text_Box_Properties, Tree_View_Properties, Vscroll_Bar_Properties
    *
    */
   boolean p_selected;

   /**
    * Determines whether a form should be shown modal when it first
    * becomes visible. 
    *  
    * <p>This property must be set before the form becomes visible.
    *
    * @see _ShowWindow
    *
    * @categories Form_Properties
    *
    */
   boolean p_ShowModal;

   /**
    * <p>Determines the style of an object.</p>
    *
    * <p><b>Check Box</b> - Style may be one of the following constants defined in
    * "slick.sh":</p>
    *
    * <dl>
    * <dt>PSCH_AUTO2STATE</dt><dd>Two state check box.</dd>
    * <dt>PSCH_AUTO3STATEA</dt><dd>Three state check box.
    * Gray, check, unchecked.</dd>
    * <dt>PSCH_AUTO3STATEB</dt><dd>Three state check box.
    * Gray, unchecked, check.</dd>
    * </dl>
    *
    * <p><b>Combo Box</b> - Style may be one of the following constants defined in
    * "slick.sh":</p>
    *
    * <dl>
    * <dt>PSCBO_EDIT</dt><dd>Standard.  List drops down.</dd>
    * <dt>PSCBO_LIST_ALWAYS</dt><dd>List is always present.
    * Can edit.</dd>
    * <dt>PSCBO_NOEDIT</dt><dd>Must select item from
    * list box. Can't edit.</dd>
    * </dl>
    *
    * <p><b>Gauge</b> - Style may be one of the following constants defined in
    * "slick.sh":</p>
    *
    * <dl>
    * <dt>PSGA_HORZ_WITH_PERCENT</dt><dd>Fill gauge from left to
    * right and show percentage of completion.</dd>
    * <dt>PSGA_VERT_WITH_PERCENT</dt><dd>Fill gauge from bottom
    * to top and show percentage of completion.</dd>
    * <dt>PSGA_HORIZONTAL</dt><dd>Fill gauge from left to
    * right.</dd>
    * <dt>PSGA_VERTICAL</dt><dd>Fill gauge from bottom
    * to top.</dd>
    * </dl>
    *
    * <p><b>Image</b> - Style may be one of the following constants defined in
    * "slick.sh":</p>
    *
    * <dl>
    * <dt>PSPIC_DEFAULT</dt><dd>No default handling for
    * <b>lbutton_down</b> event. Uses p_border_style.</dd>
    * <dt>PSPIC_FLAT_BUTTON</dt><dd>Tool-button style. Set the 
    * <b>p_picture</b> property to a 1 state picture without a 
    * border to get a 3 state toolbar button (0-normal, 1-pushed, 
    * 2-mouse over button).  This style 
    * supports the <b>p_enabled</b> property on all platforms. 
    * <b>lbutton_down</b> event calls <b>lbutton_up</b> event or executes
    * command in <b>p_command</b> property.  <b>p_value</b>
    * property is restored to its original value.</dd>
    * <dt>PSPIC_FLAT_MONO_BUTTON</dt><dd>Tool-button style. Set the
    * <b>p_picture</b> property to a 1 state picture without a 
    * border to get a 3 state toolbar button (0-normal, 1-pushed, 
    * 2-mouse over button). The picture should be a 1-bit mask and 
    * is used, along with <b>p_forecolor</b>, to fill the mask with 
    * the foreground color. This style supports the 
    * <b>p_enabled</b> property on all platforms. 
    * <b>lbutton_down</b> event calls <b>lbutton_up</b> event or 
    * executes command in <b>p_command</b> property. <b>p_value</b>
    * property is restored to its original value.</dd>
    * <dt>PSPIC_HIGHLIGHTED_BUTTON</dt><dd>Tool-button style. Set 
    * the <b>p_picture</b> property to a 1 state picture without a 
    * border to get a 3 state toolbar button (0-normal, 1-pushed, 
    * 2-mouse over button).  This style 
    * supports the <b>p_enabled</b> property on all platforms.
    * <b>lbutton_down</b> event calls <b>lbutton_up</b> event or executes
    * command in <b>p_command</b> property.  <b>p_value</b>
    * property is restored to its original value.</dd>
    * <dt>PSPIC_BUTTON</dt><dd>Tool-button style. Set the 
    * <b>p_picture</b> property to a 1 state picture without a 
    * border to get a 2 state push 
    * button. This style supports the <b>p_enabled</b> property on all
    * platforms.  If you set the <b>p_picture</b> or 
    * <b>p_caption</b> property, the control will 
    * display and act like a tool-button.  <b>lbutton_down</b>
    * event calls <b>lbutton_up</b> event or executes command in
    * <b>p_command</b> property.  <b>p_value</b> property is restored
    * to its original value.</dd>
    * <dt>PSPIC_AUTO_BUTTON</dt><dd>Set the <b>p_picture</b>
    * property to a 1 state picture without a border to get a 2 state push
    * button.  <b>lbutton_down</b> event calls <b>lbutton_up</b>
    * event or executes command in <b>p_command</b>
    * property.  <b>p_value</b> property is restored to its
    * original value.</dd>
    * <dt>PSPIC_AUTO_CHECK</dt><dd>Picture is a 2 or more
    * state picture.  <b>lbutton_down</b> event calls <b>lbutton_up</b> after
    * <b>p_value</b> property has be incremented (or set to 0
    * if past last state).</dd>
    * <dt>PSPIC_SIZEVERT</dt><dd>Draws a thick vertical
    * line which is grabbed when sizing a docked toolbar.</dd>
    * <dt>PSPIC_SIZEHORZ</dt><dd>Draws a thick horizontal
    * line which is grabbed when sizing a docked toolbar.</dd>
    * <dt>PSPIC_GRABBARVERT</dt><dd>Draws two thick vertical
    * lines which are used to grab and dock/undock a toolbar.</dd>
    * <dt>PSPIC_GRABBARHORZ</dt><dd>Draws two thick
    * horizontal lines which are used to grab and dock/undock a toolbar.</dd>
    * <dt>PSPIC_TOOLBAR_DIVIDER_VERT</dt><dd>Draws a vertical toolbar
    * divider line.</dd>
    * <dt>PSPIC_TOOLBAR_DIVIDER_HORZ</dt><dd>Draws a horizontal
    * toolbar divider line.</dd>
    * </dl>
    *
    * <p><b>Picture Box</b> - Style may be one of the following constants defined in
    * "slick.sh":</p>
    *
    * <dl>
    * <dt>PSPIC_DEFAULT</dt><dd>No default handling for
    * <b>lbutton_down</b> event.</dd>
    * <dt>PSPIC_PUSH_BUTTON</dt><dd>Push-button style. Picture 
    * is a 1 state picture which needs button up and down borders 
    * drawn around it. 
    * The <b>lbutton_down</b> event calls the <b>lbutton_up</b>
    * event or executes the command in the <b>p_command</b>
    * property.  The <b>p_value</b> property is restored to its
    * original value.</dd>
    * <dt>PSPIC_SPLIT_PUSH_BUTTON</dt><dd>Push-button style with 
    * drop-down indicator arrow on right. Picture is a 1 state 
    * picture which needs button up and down borders drawn around 
    * it. The <b>lbutton_down</b> event calls the <b>lbutton_up</b>
    * event or executes the command in the <b>p_command</b>
    * property.  The <b>p_value</b> property is restored to its
    * original value. A reason of <b>CHANGE_SPLIT_BUTTON</b> 
    * is passed to lbutton_down/lbutton_up event if user 
    * clicks on the drop-down indicator part of the button.</dd> 
    * <dt>PSPIC_AUTO_BUTTON</dt><dd>Set the
    * <b>p_picture</b> property to a 2 or more state picture and set the
    * <b>p_Nofstates</b> property to indicate the number of picture states.
    * <b>lbutton_down</b> event calls <b>lbutton_up</b> event or executes
    * command in <b>p_command</b> property.  <b>p_value</b> property
    * is restored to its original value.</dd>
    * <dt>PSPIC_AUTO_CHECK</dt><dd>Picture is a 2 or more
    * state picture.  <b>lbutton_down</b> event calls <b>lbutton_up</b> after
    * <b>p_value</b> property has be incremented (or set to 0
    * if past last state).</dd>
    * <dt>PSPIC_FILL_GRADIENT_HORIZONTAL</dt><dd>Gradient 
    * fill left to right with 
    * <b>p_backcolor</b> to <b>p_forecolor</b>.</dd> 
    * <dt>PSPIC_FILL_GRADIENT_VERTICAL</dt><dd>Gradient fill top to
    * bottom with <b>p_backcolor</b> to <b>p_forecolor</b>.</dd> 
    * <dt>PSPIC_FILL_GRADIENT_DIAGONAL</dt><dd>Gradient 
    * fill top-left to bottom-right with 
    * <b>p_backcolor</b> to <b>p_forecolor</b>.</dd> 
    * </dl>
    *
    * <p><b>SSTab</b> - Style may be one of the following constants
    * defined in "slick.sh":</p> 
    *
    * <dl>
    * <dt>PSSSTAB_DEFAULT</dt><dd>Default style.</dd>
    * <dt>PSSSTAB_DOCUMENT_TABS</dt><dd>Mac only. Document tabs 
    * style. Used by File Tabs tool-window.</dd> 
    * </dl>
    *
    * @appliesTo Check_Box, Combo_Box, Gauge, Picture_Box, Image, SSTab
    *
    * @categories Check_Box_Properties, Combo_Box_Properties, 
	 * Gauge_Properties, Image_Properties, Picture_Box_Properties,
	 * SSTab_Properties
    *
    */
   int p_style;

   /**
    * Determines the tab order and/or creation order of controls within a
    * dialog box.  Effects which control gets focus when you press the Tab
    * and Shift+Tab keys when the dialog box is displayed.  The creation
    * order of controls is based on the tab order.  This is why the spin
    * control can rely on the <b>p_prev</b> property getting to the text box
    * previous in tab order.
    *
    * @appliesTo Editor_Control, Edit_Window
    *
    * @categories Check_Box_Properties, Combo_Box_Properties,
    * Command_Button_Properties, Directory_List_Box_Properties,
    * Drive_List_Properties, Editor_Control_Properties, File_List_Box_Properties,
    * Frame_Properties, Gauge_Properties, Hscroll_Bar_Properties,
    * Image_Properties, Label_Properties, List_Box_Properties,
    * Picture_Box_Properties, Radio_Button_Properties, Spin_Properties,
    * Text_Box_Properties, Tree_View_Properties, Vscroll_Bar_Properties
    *
    */
   int p_tab_index;

   /**
    * Determines whether Tab and Shift+Tab keys switch focus to the
    * control.
    *
    * @appliesTo Text_Box, Editor_Control, Command_Button, Radio_Button,
    * Check_Box, Combo_Box, List_Box, Hscroll_Bar, Vscroll_Bar, Drive_List,
    * File_List_Box, Directory_List_Box, Gauge, Tree_View
    *
    * @categories Check_Box_Properties, Combo_Box_Properties,
    * Command_Button_Properties, Directory_List_Box_Properties,
    * Drive_List_Properties, Editor_Control_Properties, File_List_Box_Properties,
    * Gauge_Properties, Hscroll_Bar_Properties, List_Box_Properties,
    * Radio_Button_Properties, Text_Box_Properties, Vscroll_Bar_Properties
    *
    */
   boolean p_tab_stop;

   /**
    * Determines the preferred style of casing for tag elements for
    * the current buffer.  This property is available only when the
    * control is displayed and is valid only in languages where 
    * tag elements are used (e.g. HTML, XML).   
    *  
    * <p>values and respective results: 
    * <ol> 
    * <li>WORDCASE_PRESERVE - does not change </li>
    * <li>WORDCASE_LOWER - lowercase </li>
    * <li>WORDCASE_UPPER - uppercase </li> 
    * <li>WORDCASE_CAPITALIZE - capitalize the first letter only 
    * </li> 
    * </ol> 
    * 
    * @appliesTo Editor_Control, Edit_Window
    * @categories Editor_Control_Properties, Edit_Window_Properties
    */
   int p_tag_casing;

   /**
    * Determines whether the control is visible when <b>p_edit</b>!=0.
    * This property is used to implement undelete in the dialog editor.
    * When we add full undo to the dialog editor, this property will be
    * removed.  This property is only available when the control is
    * displayed.
    *
    * @appliesTo All_Window_Objects
    *
    * @categories Check_Box_Properties, Combo_Box_Properties,
    * Command_Button_Properties, Directory_List_Box_Properties,
    * Drive_List_Properties, Editor_Control_Properties, File_List_Box_Properties,
    * Frame_Properties, Gauge_Properties, Hscroll_Bar_Properties, Image_Properties,
    * Label_Properties, List_Box_Properties, Picture_Box_Properties,
    * Radio_Button_Properties, Spin_Properties, Text_Box_Properties,
    * Tree_View_Properties, Vscroll_Bar_Properties
    *
    */
   boolean p_undo_visible;

   /**
    * Determines user defined value.  This property should only be used by
    * user level 1 inheritance and not by user level 2 inheritance.  This
    * property is only available when the object is displayed.
    *
    * @appliesTo All_Window_Objects
    *
    * @categories Check_Box_Properties, Combo_Box_Properties,
    * Command_Button_Properties, Directory_List_Box_Properties,
    * Drive_List_Properties, Edit_Window_Properties, Editor_Control_Properties,
    * File_List_Box_Properties, Form_Properties, Frame_Properties,
    * Gauge_Properties, Hscroll_Bar_Properties, Image_Properties,
    * Label_Properties, List_Box_Properties, MDI_Window_Properties,
    * Picture_Box_Properties, Radio_Button_Properties, Spin_Properties,
    * Text_Box_Properties, Tree_View_Properties, Vscroll_Bar_Properties
    *
    */
   typeless p_user;

   /**
    * Determines user defined value.  This property should only be used by
    * user level 2 inheritance and not by user level 1 inheritance.  This
    * property is only available when the object is displayed.
    *
    * @appliesTo All_Window_Objects
    *
    * @categories Check_Box_Properties, Combo_Box_Properties,
    * Command_Button_Properties, Directory_List_Box_Properties,
    * Drive_List_Properties, Edit_Window_Properties, Editor_Control_Properties,
    * File_List_Box_Properties, Form_Properties, Frame_Properties,
    * Gauge_Properties, Hscroll_Bar_Properties, Image_Properties,
    * Label_Properties, List_Box_Properties, MDI_Window_Properties,
    * Picture_Box_Properties, Radio_Button_Properties, Spin_Properties,
    * Text_Box_Properties, Tree_View_Properties, Vscroll_Bar_Properties
    *
    */
   typeless p_user2;

   /**
    *
    * This property has been deprecated.  Use the {@link p_window_id} property
    * instead.
    *
    * @appliesTo All_Window_Objects
    *
    * @categories All_Windows_Properties
    * @deprecated Use {@link p_window_id}.
    */
   int p_view_id;

   /**
    * Determines whether the control is visible.  This property has no effect
    * if the object is being edited (<b>p_edit</b>!=0).
    *
    * @see _ShowWindow
    *
    * @categories Check_Box_Properties, Combo_Box_Properties,
    * Command_Button_Properties, Directory_List_Box_Properties,
    * Drive_List_Properties, Edit_Window_Properties, Editor_Control_Properties,
    * File_List_Box_Properties, Form_Properties, Frame_Properties,
    * Gauge_Properties, Hscroll_Bar_Properties, Image_Properties,
    * Label_Properties, List_Box_Properties, MDI_Window_Properties,
    * Picture_Box_Properties, Radio_Button_Properties, Spin_Properties,
    * Text_Box_Properties, Tree_View_Properties, Vscroll_Bar_Properties
    *
    */
   boolean p_visible;

   /**
    * Determines the width of a window in the scale mode of <b>p_xyscale_mode</b>.
    *
    * @categories Check_Box_Properties, Combo_Box_Properties, Command_Button_Properties,
    * Directory_List_Box_Properties,Drive_List_Properties, Edit_Window_Properties,
    * Editor_Control_Properties, File_List_Box_Properties, Form_Properties,
    * Frame_Properties, Gauge_Properties, Hscroll_Bar_Properties, Image_Properties,
    * Label_Properties, List_Box_Properties, MDI_Window_Properties, Picture_Box_Properties,
    * Radio_Button_Properties, Spin_Properties, Text_Box_Properties, Tree_View_Properties,
    * Vscroll_Bar_Properties
    *
    */
   int p_width;

   /**
    * @return Returns the window flags.  The only window flag is
    * HIDE_WINDOW_OVERLAP which indicates the window is a hidden
    * window which should not get focus.  The hidden window stores many
    * views of system buffers such as ".command", ".clipboards", and
    * ".process-command",  Currently there can only be one hidden window.
    *
    * This property is available only when the object is displayed.
    *
    * @appliesTo Edit_Window
    *
    * @categories Edit_Window_Properties, Editor_Control_Properties, List_Box_Properties
    *
    */
   int p_window_flags;

   /**
    * Determines the current object/current window.  This property is one of
    * the more important properties to understand.  SlickEdit keeps
    * track of objects by instance handles also called window id's.  All
    * objects have a window id.  The terms current object or current window
    * mean the same thing.  Changing the active object does NOT change
    * the focus.  Use the <b>_set_focus</b> method to change the focus.
    * Using this property as a method has no different effect than when it is
    * not used as a method.  Be sure to carefully look at the examples below.
    *
    * @example
    * <pre>
    * #include "slick.sh"
    * defmain()
    * {
    *    //  Calling a function as a method like below
    *    _mdi.p_child.myproc();
    *
    *    // is identical to the code below
    *    new_wid= _mdi.p_child;
    *    orig_wid=p_window_id;
    *    p_window_id=new_wid;
    *    myproc();
    *    p_window_id=orig_wid;
    * }
    * static myproc()
    * {
    * }
    * </pre>
    *
    * @appliesTo All_Window_Objects
    *
    * @categories All_Windows_Properties
    *
    */
   int p_window_id;

   /**
    * Determines the x position of a window in the scale mode of
    * <b>p_xyscale_mode</b>.
    *
    * @appliesTo All_Window_Objects
    *
    * @categories Check_Box_Properties, Combo_Box_Properties,
    * Command_Button_Properties, Directory_List_Box_Properties,
    * Drive_List_Properties, Edit_Window_Properties, Editor_Control_Properties,
    * File_List_Box_Properties, Form_Properties, Frame_Properties,
    * Gauge_Properties, Hscroll_Bar_Properties, Image_Properties,
    * Label_Properties, List_Box_Properties, MDI_Window_Properties,
    * Picture_Box_Properties, Radio_Button_Properties, Spin_Properties,
    * Text_Box_Properties, Tree_View_Properties, Vscroll_Bar_Properties
    *
    */
   int p_x;

   /**
    * @return Returns the window id that the window is clipped to.  0 is returned if
    * the window is clipped to the screen.
    *
    * @appliesTo All_Window_Objects
    *
    * @categories Check_Box_Properties, Combo_Box_Properties,
    * Command_Button_Properties, Directory_List_Box_Properties,
    * Drive_List_Properties, Edit_Window_Properties, Editor_Control_Properties,
    * File_List_Box_Properties, Form_Properties, Frame_Properties,
    * Gauge_Properties, Hscroll_Bar_Properties, Image_Properties,
    * Label_Properties, List_Box_Properties, MDI_Window_Properties,
    * Picture_Box_Properties, Radio_Button_Properties, Spin_Properties,
    * Text_Box_Properties, Tree_View_Properties, Vscroll_Bar_Properties
    *
    */
   int p_xyparent;

   /**
    * @return Returns the parent scale mode.  May be SM_PIXEL or SM_TWIP.
    * 1440 twips represent one inch on the display.  The parent scale mode
    * is the scale mode used by the properties and methods which get or set
    * the size and position of the current objects window.  This property is
    * available only when the object is displayed.
    *
    * @example
    * <pre>
    * // Determine the width of both borders of the current control.
    * both_width=p_width - _dx2lx(p_xyscale_mode,p_client_width);
    * </pre>
    *
    * @appliesTo All_Window_Objects
    *
    * @categories Check_Box_Properties, Combo_Box_Properties,
    * Command_Button_Properties, Directory_List_Box_Properties,
    * Drive_List_Properties, Edit_Window_Properties, Editor_Control_Properties,
    * File_List_Box_Properties, Form_Properties, Frame_Properties,
    * Gauge_Properties, Hscroll_Bar_Properties, Image_Properties,
    * Label_Properties, List_Box_Properties, MDI_Window_Properties,
    * Picture_Box_Properties, Radio_Button_Properties, Spin_Properties,
    * Text_Box_Properties, Tree_View_Properties, Vscroll_Bar_Properties
    *
    */
   int p_xyscale_mode;

   /**
    * Determines the y position of a window in the scale mode of
    * <b>p_xyscale_mode</b>.
    *
    * @appliesTo All_Window_Objects
    *
    * @categories Check_Box_Properties, Combo_Box_Properties,
    * Command_Button_Properties, Directory_List_Box_Properties,
    * Drive_List_Properties, Edit_Window_Properties, Editor_Control_Properties,
    * File_List_Box_Properties, Form_Properties, Frame_Properties,
    * Gauge_Properties, Hscroll_Bar_Properties, Image_Properties,
    * Label_Properties, List_Box_Properties, MDI_Window_Properties,
    * Picture_Box_Properties, Radio_Button_Properties, Spin_Properties,
    * Text_Box_Properties, Tree_View_Properties, Vscroll_Bar_Properties
    *
    */
   int p_y;

   /**
    * Calls an event handler for an object or for a specific event table.  The
    * event handler is called with arguments arg1,arg2,..,argN if specified.
    * IMPORTANT: You must specify the option parameter if you want to call the
    * event handler with arguments.
    * <P>
    * The option defaults to 'W' and may be one of the following:
    * <DL compact style="margin-left:20pt">
    * <DT>'W'<DD>Indicates that wid_or_etab is the window id of the object.  The event
    * handler is determined by the dialog box inheritance order.
    * <DT>'E'<DD>Indicates that wid_or_etab is an index to and event table.
    * <DT>'2'<DD>Indicates that wid_or_etab is the window id of the object.  The event
    * handler is determined by the dialog box inheritance order but the user
    * level 1 inheritance is skipped.
    * </DL>
    * <P>
    * event is an event constant.  Use name2event to specify a key event.  See
    * help on Event Names
    * </P>
    *
    * @param wid_or_etab      window id
    * @param event            event to call
    * @param option           see above ('W', 'E', or '2')
    *
    * @example
    * <PRE>
    * // Often dialog boxes have an OK button which applies changes and closes
    * // the dialog box and an Apply button which applies changes but does not
    * // close the dialog box
    * defeventtab form1;
    * ok.lbutton_up()
    * {
    *      // If the apply button does not reference itself, we do not need to use
    *      // call event as a method.
    *      apply.call_event(_control apply,LBUTTON_UP);
    *      //  Some events do not have constants defined for them.  The commented
    *      // out call_event statement below has the same effect but uses the
    *
    *      // name2event primitive which works for key events such
    *      // as 'a', 'b', 'c'...'?','@','#' etc.
    *      //     apply.call_event(_control apply,name2event('lbutton-up'));
    *      p_active_form._delete_window(0);
    * }
    * apply.lbutton_up()
    * {
    *      // Add code for this event function here.
    *      // We can return a value if we want to.
    * }
    *
    * // Here's an example of calling an event handler of a specific event table
    * ok.lbutton_up()
    * {
    *      // The sample code above is better because it does get effected by changing
    *
    *      // the form name.  The 'E' option should be used when the dialog
    *      // box inheritance order won't call the correct event handler or if you
    *      // have written your own user level2  inheritance code which needs to
    *      // call other user level2 inheritance code.
    *      apply.call_event(defeventtab form1.apply,LBUTTON_UP,'E');
    *      p_active_form._delete_window(0);
    * }
    * </PRE>
    * @appliesTo All_Window_Objects
    * @categories Check_Box_Methods, Combo_Box_Methods, Command_Button_Methods, Directory_List_Box_Methods, Drive_List_Methods, Edit_Window_Methods, Editor_Control_Methods, File_List_Box_Methods, Form_Methods, Frame_Methods, Gauge_Methods, Hscroll_Bar_Methods, Image_Methods, Label_Methods, List_Box_Methods, MDI_Window_Methods, Picture_Box_Methods, Radio_Button_Methods, Spin_Methods, Text_Box_Methods, Vscroll_Bar_Methods
    */
   typeless call_event(...,int wid_or_etab ,_str event, option='W');


// See slick.sh, all these are #defined to "int" type
//
// The advantage to using these is that if you declare the
// variables used to refer to these controls using these
// types rather than 'int' or 'typeless', you can get context
// tagging for the members of the controls.
//
typedef _control        CTL_CONTROL;
typedef _form           CTL_FORM;
typedef _hthelp         CTL_HELP;
typedef _tree_view      CTL_TREE;
typedef _list_box       CTL_LISTBOX;
typedef _sstab          CTL_SSTAB;
typedef _combo_box      CTL_COMBO;
typedef _text_box       CTL_TEXT;
typedef _editor         CTL_EDITOR;
typedef _print_preview  CTL_PPREVIEW;
typedef _window         CTL_WINDOW;
typedef _basewindow     CTL_BASEWIN;
typedef _mdi_form       CTL_MDI;
typedef _menu           CTL_MENU;
typedef _menu_item      CTL_MENUITEM;
typedef _sstab_container CTL_SSTABC;
typedef _spin           CTL_SPIN;
typedef _gauge          CTL_GAUGE;
typedef _image          CTL_IMAGE;
typedef _picture_box    CTL_PICTURE;
typedef _vscroll_bar    CTL_VSCROLL;
typedef _hscroll_bar    CTL_HSCROLL;
typedef _scroll_bar     CTL_SCROLL;
typedef _label          CTL_LABEL;
typedef _frame          CTL_FRAME;
typedef _radio_button   CTL_RADIO;
typedef _command_button CTL_BUTTON;
typedef _check_box      CTL_CHECK;


/**
 * Calls command or procedure corresponding to name table index passing
 * arguments arg1,arg2,..,argN.  The arguments may be call by reference
 * or call by value as long as a constant is not passed to a procedure
 * expecting a variable which can be referenced.  If the procedure or
 * command is not linked to a module, the interpreter is stopped and
 * the message "Invalid argument" is displayed.  Use the function
 * {@link index_callable} to determine whether the procedure or command
 * is linked to a module.
 *
 * @param index   name table index of function to call
 *
 * @example
 * <PRE>
 * index=find_index('upcase_filter');
 * if (!index_callable(index) ) {
 *      message("upcase_filter name is either not in names table or not  linked to a module");
 * } else {
 *      string=call_index('abc',index);
 * }
 * </PRE>
 *
 * @see index_callable
 * @see find_index
 *
 * @categories Names_Table_Functions
 */
typeless call_index(...,int index);

/**
 * @return Appends <i>source</i> string to end of <i>dest</i> string.  This
 * function performs faster than using the statement
 * "<i>dest</i>=<i>dest</i>:+<i>source</i>;".
 *
 * @param dest       [reference] destination string
 * @param source     source string
 *
 * @categories String_Functions
 */
void strappend(_str &dest, _str source);

/**
 * Get the dimensions of the MDI client window
 *
 * @param x          X position
 * @param y          Y position
 * @param width      Width
 * @param height     Height
 */
void _MDIClientGetWindow(int &x,int &y,int &width,int &height);

/**
 * <p>Resizes and moves MDI edit windows so that they do not overlap.</p>
 *
 * <p>The option letter must be one of the following:</p>
 *
 * <dl>
 * <dt>'V'</dt><dd>(Default) Attempt to tile windows vertically.</dd>
 * <dt>'H'</dt><dd>Attempt to tile windows horizontally.</dd>
 * <dt>'U'</dt><dd>Until windows (one group of tabs)</dd> 
 * </dl>
 *
 * @see _cascade_windows
 *
 * @appliesTo MDI_Window
 *
 * @categories MDI_Window_Methods, Window_Functions
 *
 */
void _tile_windows(_str option='V');

/**
 * Arranges MDI edit windows to be cascaded (One below and right of the other).
 * Does not effect MDI edit windows that are iconized.
 * </P>
 * @example
 * <PRE>
 *   _mdi._cascade_windows();
 * </PRE>
 *
 * @categories MDI_Window_Methods
 */
void _cascade_windows();

/**
 * Arranges the iconized MDI edit windows.
 *
 * @appliesTo MDI_Window
 * @example
 * <PRE>
 *   _mdi._arrange_icons();
 * </PRE>
 * @categories MDI_Window_Methods, Window_Functions
 */
void _arrange_icons();

void _menu_event(_str event);

/**
 * Sets the menu bar to the loaded menu specified.  If the form already has a
 * menu bar you should destroy the old menu bar AFTER setting the menu bar.
 * See example below.
 *
 * @param menu_handle      menu handle
 *
 * @return Returns 0 if successful.
 *
 * @example
 * <PRE>
 * #include "slick.sh"
 * defmain()
 * {
 *     // Find index of SlickEdit MDI menu resource
 *     index=find_index("_mdi_menu",oi2type(OI_MENU));
 *     if (!index) {
 *         message("Can't find _mdi_menu");
 *         return("");
 *     }
 *     // Load this menu resource
 *     menu_handle=_menu_load(index);
 *     old_menu_handle=_mdi.p_menu_handle;  // Remember old menu handle
 *     _mdi._menu_set(menu_handle);
 *     if (old_menu_handle) {  // IF there was a menu bar
 *
 *         _menu_destroy(old_menu_handle);  // Delete old menu bar
 *     }
 *     // You DO NOT need to call _menu_destroy to destroy the new menu when
 *     // the MDI window is deleted.  This menu is destroyed automatically
 *     // when the MDI window is deleted.
 * }
 * </PRE>
 *
 * @see on_init_menu
 * @see _menu_add_filehist
 * @see _menu_add_hist
 * @see _menu_add_workspace_hist
 * @see _menu_delete
 * @see _menu_destroy
 * @see _menu_find
 * @see _menu_get_state
 * @see _menu_info
 * @see _menu_insert
 * @see _menu_load
 * @see _menu_match
 * @see _menu_move
 * @see _menu_set_state
 * @see _menu_show
 * @see alt_menu
 * @see insert_object
 * @see menu_mdi_bind_all
 * @see mou_show_menu
 * @see show
 *
 * @appliesTo MDI_Window, Form
 *
 * @categories Form_Methods, MDI_Window_Methods, Menu_Functions
 *
 */
int _menu_set(int menu_handle);


/**
 * If successful, loads menu resource and returns handle of loaded menu.
 * Otherwise a negative error code is returned.  option may be 'M' or 'P'.
 * Specify 'P' for option to display a menu resource as a pop-up menu.
 * menu_index is a handle to a menu resource returned by find_index or
 * name_match.
 * <P>
 * IMPORTANT: _menu_load is a method because under X windows we must know
 * which window a menu bar will be attached before you call _menu_set.  Make
 * sure your _menu_load and _menu_set calls operate on the same object.
 * Otherwise, your Slick-C&reg; code will not work under X windows.  For pop-up
 * menus, _menu_load does not need know the object.
 *
 * @param menu_index    index to load menu at
 * @param option        load options
 *
 * @example
 * <PRE>
 * #include "slick.sh"
 * // Create a form called form1 and set the border style to anything BUT
 * // BDS_DIALOG BOX.  Windows does not allow forms with a dialog
 * // box style border to have menu bars.
 * defeventtab form1;
 * form1.on_load()
 * {
 *     // Find index of SlickEdit MDI menu resource
 *     index=find_index(def_mdi_menu,oi2type(OI_MENU));
 *     // Load this menu resource
 *     menu_handle=p_active_form._menu_load(index);
 *     // _set_menu will fail if the form has a dialog box style border.
 *
 *     // Put a menu bar on this form.
 *     _menu_set(menu_handle);
 *     // You DO NOT need to call _menu_destroy.  This menu is destroyed when the form
 *     // window is deleted.
 * }
 * </PRE>
 *
 * @see on_init_menu
 * @see _menu_add_filehist
 * @see _menu_add_hist
 * @see _menu_add_workspace_hist
 * @see _menu_delete
 * @see _menu_destroy
 * @see _menu_find
 * @see _menu_get_state
 * @see _menu_info
 * @see _menu_insert
 * @see _menu_match
 * @see _menu_move
 * @see _menu_set
 * @see _menu_set_state
 * @see _menu_show
 * @see alt_menu
 * @see insert_object
 * @see menu_mdi_bind_all
 * @see mou_show_menu
 * @see show
 *
 * @categories Menu_Functions
 *
 */
int _menu_load(int menu_index,_str option='M');

/**
 * Returns window id of dock palette for a particular MDI frame 
 * docking <code>area</code>. If no palette exists for the that 
 * side 0 is returned. 
 *
 * @param area  One of the following:
 *              <ul>
 *              <li>DOCKINGAREA_LEFT
 *              <li>DOCKINGAREA_TOP
 *              <li>DOCKINGAREA_RIGHT
 *              <li>DOCKINGAREA_BOTTOM
 *              </ul>
 *
 * @see _LoadDockPalette
 * @appliesTo  MDI_Window
 * @categories MDI_Window_Methods
 */
int _GetDockPalette(vsDockingArea area);

/**
 * Loads a form as dock palette onto an MDI frame docking 
 * <code>area</code>. <code>index</code> corresponds to a form 
 * in the names table returned by find_index. 
 *
 * @param index  Index of form to load as dock palette.
 * @param area   One of the following:
 *               <ul>
 *               <li>DOCKINGAREA_LEFT
 *               <li>DOCKINGAREA_TOP
 *               <li>DOCKINGAREA_RIGHT
 *               <li>DOCKINGAREA_BOTTOM
 *               </ul>
 *
 * @see _GetDockPalette
 *
 * @appliesTo MDI_Window
 *
 * @categories MDI_Window_Methods
 *
 */
int _LoadDockPalette(int index, vsDockingArea area=DOCKINGAREA_TOP);

/**
 * Updates a dialog box template in the names table.  If the
 * <b>p_template</b> property is 0, a new dialog box template is
 * inserted.  Otherwise, the existing dialog box template is replaced.
 * Specify the name of the form (<b>p_name</b>) to the <b>show</b>
 * command to display the dialog box.
 *
 * @return Returns the index into the names table of the dialog box template.  The
 * <b>p_template</b> property of the form is set to the index into the
 * names table of the dialog box template.  On error, a negative error
 * code is returned which can be used by <b>get_message</b> to retrieve
 * the error message.
 *
 * @appliesTo Form
 *
 * @categories Form_Methods, Names_Table_Functions
 *
 */
int _update_template();

void _GetOuterMostWindow(int &x,int &y,int &width,int &height);
void _MDIChildGetWindow(int &x,int &y,int &width,int &height,_str option='C',int &icon_x=0,int &icon_y=0);
void _MDIChildSetWindow(int &x,int &y,int &width,int &height,_str option='C',int icon_x=MAXINT,int icon_y=MAXINT);



/**
 * Places the cursor at the byte offset specified.  Non-savable lines (lines
 * with the NOSAVE_LF flag set) are not included.  This methed is intended
 * for dealing with disk seek position.  However, if you have changed the
 * load options to translate files when they are openned, these offsets will
 * not match what is on disk.
 *
 * @param offset  offset to go to
 *
 * @returns Returns 0 if offset is a valid offset.  Otherwise an negative
 * error code is returned.
 *
 * @see goto_point
 * @see point
 * @see _QROffset
 * @see _GoToROffset
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 *
 */
int _GoToROffset(long offset);
/**
 * @return Returns line number (<B>p_line</B>) corresponding
 *         to offset
 *
 * @param offset Byte offset including no save bytes
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
int _QLineNumberFromOffset(long offset);
/**
 * @return Returns the number of bytes before the cursor.  Non-savable lines (lines
 * with the NOSAVE_LF flag set) are not included.  This method is intended
 * for dealing with disk seek position.  However, if you have changed the
 * load options to translate files when they are openned, these offsets will
 * not match what is on disk.
 *
 * @see goto_point
 * @see point
 * @see _QROffset
 * @see _GoToROffset
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 *
 */
long _QROffset();

/**
 * Displays tool tip message at (x, y) position specified.
 * The (x, y) position is relative to parent_wid.  Use the 'C'
 * option to close the tool tip window.
 *
 * @param option       options
 * @param parent_wid   parent window ID
 * @param x            x-position
 * @param y            y-position
 * @param msg          message to display
 * @param FontName     font to use
 * @param FontSizex10  FontSizex10 is the size of the font in points multiple by 10
 *                     (ex. 100 specifies a 10 point font).
 * @param FontFlags
 *                     FontFlags is a combination of the following flag constants defined
 *                     in "slick.sh":
 *                     <UL>
 *                     <LI>F_BOLD
 *                     <LI>F_ITALIC
 *                     <LI>F_STRIKE_THRU
 *                     <LI>F_UNDERLINE
 *                     </UL>
 * @param rgbfg        foreground color
 * @param rgbbg        background color
 * @param padding      No longer supported. Extra padding on 
 *                     left and right
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Miscellaneous_Functions
 */
void _bbhelp(_str option,
             int parent_wid=0,
             int x=0,int y=0,
             _str msg="",
             _str FontName="",
             int FontSizex10=0,
             int FontFlags=0,
             int rgbfg=0x80000000,
             int rgbbg=0x80000000,
             int padding=BBINDENT_X);

void _set_zorder(int wid);


/**
 * Sets focus to the object.  If you are trying to set the focus when a
 * dialog box is being created, call _set_focus during the on_load event of
 * the form.
 *
 * @see _get_focus
 *
 * @categories Miscellaneous_Functions
 *
 */
void _set_focus();

/**
 * Brings a window to the top in the Z order and gives the
 * window or a control wihin the window focus.
 *
 * @categories Miscellaneous_Functions
 *
 */
int _set_foreground_window(int reserved=0);

/**
 * Converts the <i>x</i> and <i>y</i> variables which are in the scale,
 * <i>scale_mode,</i> to pixels.  <i>scale_mode</i> may be SM_PIXEL or SM_TWIP.
 *
 * @param scale_mode    may be SM_PIXEL or SM_TWIP.
 * @param x             x coordinate
 * @param y             y coordinate
 *
 * @see _lx2dx
 * @see _lx2lx
 * @see _dx2lx
 * @see _lxy2lxy
 * @see _dxy2lxy
 * @see _ly2dy
 * @see _ly2ly
 * @see _dy2ly
 * @see _map_xy
 *
 * @categories Miscellaneous_Functions
 *
 */
void _lxy2dxy(int scale_mode,int &x,int &y);
/**
 * Converts the x and y positions given from pixels to the scale mode specified.
 * scale_mode may be one of the constants SM_TWIP or SM_PIXEL  defined in "slick.sh".
 *
 * @param scale_mode    may be SM_PIXEL or SM_TWIP.
 * @param x             x coordinate
 * @param y             y coordinate
 *
 * @see _lx2dx
 * @see _lx2lx
 * @see _dx2lx
 * @see _lxy2lxy
 * @see _dxy2lxy
 * @see _ly2dy
 * @see _ly2ly
 * @see _dy2ly
 * @see _map_xy
 * @categories Miscellaneous_Functions
 */
void _dxy2lxy(int scale_mode,int &x,int &y);


/**
 * @return Returns the display width of string in the current font.  Return value is
 * in the parent scale mode (p_xyscale_mode).
 *
 * @see _text_height
 *
 * @appliesTo All_Window_Objects
 *
 * @categories Check_Box_Methods, Combo_Box_Methods, Command_Button_Methods, Directory_List_Box_Methods, Drive_List_Methods, Edit_Window_Methods, Editor_Control_Methods, File_List_Box_Methods, Form_Methods, Frame_Methods, Gauge_Methods, Hscroll_Bar_Methods, Image_Methods, Label_Methods, List_Box_Methods, MDI_Window_Methods, Picture_Box_Methods, Radio_Button_Methods, Spin_Methods, Text_Box_Methods, Vscroll_Bar_Methods
 *
 */
int _text_width(_str string);

/**
 * @return Returns the display height of the current font in the parent scale mode
 * (<b>p_xyscale_mode</b>).
 *
 * @see _text_width
 *
 * @appliesTo All_Window_Objects
 *
 * @categories Check_Box_Methods, Combo_Box_Methods, Command_Button_Methods, Directory_List_Box_Methods, Drive_List_Methods, Edit_Window_Methods, Editor_Control_Methods, File_List_Box_Methods, Frame_Methods, Gauge_Methods, Hscroll_Bar_Methods, Image_Methods, List_Box_Methods, Picture_Box_Methods, Radio_Button_Methods, Spin_Methods, Text_Box_Methods, Vscroll_Bar_Methods
 *
 */
int _text_height();


/**
 *
 * @param ctlName    name of control to search for
 *
 * @return Returns instance handle (window id) of control, control_name,
 *         in the current form.  If the current form does not have a control
 *         with name (p_name), ctlName, 0 is returned.
 *
 * @example
 * <PRE>
 *    defeventtab form1;
 *    command1.lbutton_up()
 *    {
 *        wid=_find_control("command1");  // Look for self
 *        if (p_window_id==wid) {
 *             message("Found myself");
 *        } else {
 *             message("Not possible");
 *        }
 *    }
 * </PRE>
 * @appliesTo  All_Window_Objects
 *
 * @categories Form_Methods
 */
int _find_control(_str ctlName);

/** 
 * @return 
 * Returns an instance handle (window id) to form <i>form_name</i>. Returns 0 if
 * an instance is not found.  Beware, by default, this function will find edited 
 * or non-edited instances of a form.  Specify the 'N' option if you only want 
 * to find a non-edited instances of the form.  Specify the 'E' option if you 
 * only want to find an edited instance of a form. 
 *  
 * @param form_name     name of form to search for an instance of 
 * @param option        'N' or 'E', as described above 
 * @param wid           (optional) last known window handle for form 
 * 
 * @see _find_object
 * @see _find_control
 * @categories Form_Functions, Search_Functions
 */
int _find_formobj(_str form_name, _str option='', int wid=0);

/**
 * @return  Returns an instance handle (window id) to the object, 
 * <i>object_name</i>.  Returns 0 if an instance is not found.  Beware, by 
 * default, this function will find edited or non-edited instances of an object.  
 * Specify the 'N' option if you only want to find a non-edited instance of an 
 * object.  Specify the 'E' option if you only want to find an edited instance 
 * of an object. 
 *  
 * @param object_name is a string in the format: form_name  [.control_name]
 * @param option        'N' or 'E', as described above 
 * @param wid           (optional) last known window handle for the object 
 *  
 * @example
 * <pre>
 * defmain()
 * {
 *    // Get an instance handle to the MDI button bar.  Don't want edited 
 * form.
 *    // Can get a 0 return value if the user has turned off the menu bar.
 *    form_wid=_find_object("_mdibutton_bar_form", 'N');
 *    if (form_wid) {
 *         // Lets delete it (HA HA).  Bet you didn't think you could do that
 *        form_wid._delete_window();    
 *        // To restore the button bar,   invoke the menu item  "Macro", 
 * "Edit MDI Button Bar" 
 *        // and press the OK button.
 *    }
 * }
 * </pre>
 * @example
 * <pre>
 * defeventtab form1;
 * command1.lbutton_up()
 * {
 *     wid=_find_object("form1.command1");   // Look for self
 *     if (p_window_id==wid) {
 *          message("Found myself");
 *     } else {
 *          message("You must have another instance of form1 that does not 
 * have a command1 button");
 *     }
 * }
 * </pre>
 * @see _find_formobj
 * @see _find_control
 * @categories Search_Functions
 */
int _find_object(_str name, _str option='', int wid=0);

/**
 * Gives the object a unique tab index (<b>p_tab_index</b>) different
 * from other controls on the form.  If <b>p_tab_index</b> is not 0 and
 * is already unique (no other controls have the same tab index), it is not
 * changed.
 *
 * @see _unique_name
 *
 * @appliesTo All_Window_Objects
 *
 * @categories Check_Box_Methods, Combo_Box_Methods, Command_Button_Methods, Directory_List_Box_Methods, Drive_List_Methods, Editor_Control_Methods, File_List_Box_Methods, Frame_Methods, Gauge_Methods, Hscroll_Bar_Methods, Image_Methods, Label_Methods, List_Box_Methods, Picture_Box_Methods, Radio_Button_Methods, Spin_Methods, Text_Box_Methods, Vscroll_Bar_Methods
 *
 */
void _unique_tab_index();

/**
 * Gives the object a unique name (p_name) different from other controls on the form.
 * If p_name is not '' and is already unique (no other controls have the same name),
 * it is not changed.
 *
 * @param prefix     prefix to assign to name
 *
 * @see _unique_tab_index
 *
 * @appliesTo All_Window_Objects
 *
 * @categories Check_Box_Methods, Combo_Box_Methods, Command_Button_Methods, Directory_List_Box_Methods, Drive_List_Methods, Editor_Control_Methods, File_List_Box_Methods, Frame_Methods, Gauge_Methods, Hscroll_Bar_Methods, Image_Methods, Label_Methods, List_Box_Methods, Picture_Box_Methods, Radio_Button_Methods, Spin_Methods, Text_Box_Methods, Vscroll_Bar_Methods
 *
 */
void _unique_name(_str prefix="");


int _sysmenu_bind(int sc,_str caption);

void _sysmenu_command(int sc);

/**
 * Copies selected controls on a form to the clipboard.
 * A selected control has a non-zero p_selected property.
 *
 * @appliesTo Form
 * @categories Clipboard_Functions, Form_Methods
 * @param isClipboard  Indicates whether operation is performed for the clipboard or selection.  Effects Unix only.
 *
 * @return Returns 0 if successful.
 */
int _copy_objects_to_clipboard(boolean isClipboard=true);


/**
 * If clipboard is a text clipboard, the current object must be an edit
 * window or editor control.  For a text format clipboard, this function
 * inserts the clipboard into the current buffer as a stream of characters.
 * This function should not be used to paste internal clipboards.  Use the
 * paste command instead.
 * <P>
 * If the clipboard contains SlickEdit Controls, the controls are
 * inserted as children to the current object or the parent of the current
 * object if the current object does not allow child controls.
 *
 * @appliesTo All_Window_Objects
 * @categories Clipboard_Functions, Edit_Window_Methods, Editor_Control_Methods
 * @param isClipboard  Indicates whether operation is performed for the clipboard or selection.  Effects Unix only.
 *
 * @return Returns 0 if successful.
 * @see _clipboard_format
 * @see _clipboard_empty
 */
int _copy_from_clipboard(boolean isClipboard=true);

/**
 * If the current window is displaying a buffer, the current window id is
 * returned.  Otherwise, the active MDI edit window id is returned.
 *
 * @appliesTo  All_Window_Objects
 * @categories Window_Functions
 */
int _edit_window();
/**
 * Deletes the current window and all child controls on the window.  This
 * function is typically used to close a dialog box and optionally return a
 * value to _modal_wait.  When canceling a dialog box the modal_retvalue
 * SHOULD NOT BE SPECIFIED unless it is ''.  This convention is used so that
 * editing a dialog box which causes the dialog box to be deleted, is the
 * same as canceling the dialog box.  Only modal dialog boxes can return a
 * value.  You CAN NOT RELY on the focus returning to a particular window.
 * This function leaves focus selection up to the operating system.  If the
 * window being deleted is a form and (p_init_style &
 * (IS_REINIT|IS_HIDEONDEL) is true when _delete_window is called, the form
 * is made invisible and no windows are actually deleted.  Under UNIX, the
 * show command options -reinit and -hideondel turn on these p_init_style
 * flags.  The _load_template function is used to create an instance of a
 * dialog box.  The function _modal_wait, may be called with the instance
 * handle (window id) returned by _load_template, to wait for the dialog box
 * to be closed by the _delete_window function.  The return value of
 * _modal_wait is the modal_retvalue given to _delete_window function.
 *
 * @example
 * <PRE>
 * #include "slick.sh"
 * _command test()
 * {
 *     index=find_index("form1", oi2type(OI_FORM));
 *     // Normally the show command is called instead of the more low level
 *     // function _load_template
 *     wid=_load_template(index,_mdi);
 *     result=_modal_wait(wid);
 *     message('result='result);
 * }
 *
 * defeventtab form1;
 * ok.lbutton_up()
 * {
 *      p_active_form._delete_window("This is a test");
 * }
 * cancel.lbutton_up()
 * {
 *      // Return '' to _modal_wait
 *      p_active_form._delete_window();
 *
 * }
 * </PRE>
 * @appliesTo  All_Window_Objects
 * @categories Check_Box_Methods, Combo_Box_Methods, Command_Button_Methods, Directory_List_Box_Methods, Drive_List_Methods, Edit_Window_Methods, Editor_Control_Methods, File_List_Box_Methods, Form_Methods, Frame_Methods, Gauge_Methods, Hscroll_Bar_Methods, Image_Methods, Label_Methods, List_Box_Methods, Picture_Box_Methods, Radio_Button_Methods, Spin_Methods, Text_Box_Methods, Vscroll_Bar_Methods, Window_Functions
 */
int _delete_window(_str modalWaitResult="");

/**
 * <p>Hides or show a window in a number of ways.  Use _ShowWindow
 * with the SW_SHOWNOACTIVATE constant instead of the
 * <b>p_visible</b> property to make a window visible without
 * changing it Z order.  <i>swOption</i> may be one of the following
 * constants defined in "slick.sh":</p>
 *
 * <pre>
 *    SW_HIDE  // Make window invisible
 *    SW_SHOWMINIMIZED  // Show window iconized
 *    SW_SHOWMAXIMIZED  // Show window maximized
 *    SW_SHOWNOACTIVATE // Make window visible without
 * changing Z order
 *    SW_SHOW  // Make window visible and change
 * Z order
 *    SW_RESTORE  // Restore window
 * </pre>
 *
 * @see p_visible
 *
 * @appliesTo All_Window_Objects
 *
 * @categories Check_Box_Methods, Combo_Box_Methods, Command_Button_Methods, Directory_List_Box_Methods, Drive_List_Methods, Edit_Window_Methods, Editor_Control_Methods, File_List_Box_Methods, Form_Methods, Frame_Methods, Gauge_Methods, Hscroll_Bar_Methods, Label_Methods, List_Box_Methods, MDI_Window_Methods, Picture_Box_Methods, Radio_Button_Methods, Spin_Methods, Text_Box_Methods, Vscroll_Bar_Methods
 *
 */
int _ShowWindow(int sw=-1);
/**
 * Get the geometry of the current window. 
 *
 * <p>
 *
 * <code>(x,y)</code> specify the top-left corner. 
 * <code>(width,height)</code> specify width and height. 
 * <code>icon_x,icon_y</code> specify the iconized position. All 
 * values returned are in the parent scale mode 
 * (p_xyscale_mode) except for the 'O' option which returns the 
 * values in pixels. 
 * <code>option</code> can be 'C' for current size, 'N' for 
 * normalized size (before it was iconized), or 'O' for 
 * outer-frame geometry.
 *
 * @param x          (reference) x position
 * @param y          (reference) y-position
 * @param width      (reference) width
 * @param height     (reference) height
 * @param option     option, see above
 * @param icon_x     (reference) icon x-position
 * @param icon_y     (reference) icon y-position
 *
 * @see _move_window
 * @see p_x
 * @see p_y
 * @see p_width
 * @see p_height
 *
 * @appliesTo All_Window_Objects
 *
 * @categories Check_Box_Methods, Combo_Box_Methods, Command_Button_Methods, Directory_List_Box_Methods, Drive_List_Methods, Edit_Window_Methods, Editor_Control_Methods, File_List_Box_Methods, Form_Methods, Frame_Methods, Gauge_Methods, Hscroll_Bar_Methods, Image_Methods, Label_Methods, List_Box_Methods, MDI_Window_Methods, Picture_Box_Methods, Radio_Button_Methods, Spin_Methods, Text_Box_Methods, Vscroll_Bar_Methods
 *
 */
void _get_window(int &x, int &y, int &width, int &height ,
                 _str option='C',int &icon_x=0,int &icon_y=0);

/**
 * Moves and sizes the current window to the position and size specified.  The input position
 * and size parameters are specified in the parent scale mode (p_xyscale_mode).  Use the 'N'
 * option to move and size the normalized information for the window when the window is
 * iconized or maximized.  The 'C' option is the default, and specifies that the current
 * window position and size be changed.  The 'N' option is no 
 * longer supported.
 *
 * @param x          x-position to move to
 * @param y          y-position to move to
 * @param width      width
 * @param height     height
 * @param option     option, see above
 * @param icon_x     icon x-position  No longer supported.
 * @param icon_y     icon y-position  No longer supported.
 *
 * @see _get_window
 *
 * @appliesTo All_Window_Objects
 *
 * @categories Check_Box_Methods, Combo_Box_Methods, Command_Button_Methods, Directory_List_Box_Methods, Drive_List_Methods, Edit_Window_Methods, Editor_Control_Methods, File_List_Box_Methods, Form_Methods, Frame_Methods, Gauge_Methods, Hscroll_Bar_Methods, Image_Methods, Label_Methods, List_Box_Methods, MDI_Window_Methods, Picture_Box_Methods, Radio_Button_Methods, Spin_Methods, Text_Box_Methods, Vscroll_Bar_Methods, Window_Functions
 *
 */
void _move_window(int x, int y, int width, int height,
                           _str option='C',
                           int icon_x=MAXINT,
                           int icon_y=MAXINT);


/**
 * Forces all mouse messages to the current window.  This function is
 * typically called after an lbutton_down event which performs a get_event
 * loop which waits for an lbutton_up event to occur.
 *
 * @param grabMouse  Set to true to grab mouse events for ALL
 *                   windows (even those not belonging to the
 *                   application). Defaults to true.
 *
 * @example
 * <PRE>
 * #include 'slick.sh'
 *
 * defeventtab form1;
 * // For this example, create a picture or image control and set the
 * // p_picture property to "_arrow.bmp" or any two state bitmap.  Also
 * // set the p_Nofstates property to 2.
 * picture1.lbutton_down()
 * {
 *    mou_mode(1)
 *    mou_capture();
 *    done=0;
 *    for (;;) {
 *       event=get_event();
 *       switch (event) {
 *       case MOUSE_MOVE:
 *          mx=mou_last_x('m');  // 'm' specifies mouse position in current scale mode
 *
 *          my=mou_last_y('m');
 *          if (mx>=0 && my>=0 && mx<p_width && my<p_height) {
 *             if (!p_value) {
 *                // Show the button pushed in.
 *                p_value=1;
 *             }
 *          } else {
 *             if (p_value) {
 *                // Show the button up.
 *                p_value=0;
 *             }
 *          }
 *          break;
 *       case LBUTTON_UP:
 *       case ESC:
 *          done=1;
 *       }
 *       if (done) break;
 *    }
 *    mou_mode(0);
 *
 *    mou_release();
 *    return('')
 * }
 * </PRE>
 *
 * @see mou_release
 *
 * @appliesTo All_Window_Objects
 *
 * @categories Mouse_Functions
 *
 */
void mou_capture(bool grabMouse=true);
/**
 * Cancels last mou_capture so that mouse messages can be sent to all
 * windows.
 *
 * @appliesTo All_Window_Objects
 *
 * @see mou_capture
 *
 * @categories Mouse_Functions
 *
 */
int mou_release();

/**
 * (Supported under Windows, Windows 95/98, and Windows NT only)Limits the
 * range of the mouse to pixel rectangle (x1,y1) to (x2,y2) relative to the
 * current window.  To cancel a limit, specify 0 for all parameters.
 *
 * @param x1         left x
 * @param y1         top y
 * @param x2         right x
 * @param y2         bottom y
 *
 * @example
 * <PRE>
 *    mou_limit(0,0,p_client_x,p_client_height);
 *    for (;;){
 *         event=get_event();
 *         // Move controls within current window until get lbutton_up event.
 *         ...
 *    }
 *    // Cancel mouse range limit
 *    mou_limit(0,0,0,0);
 * </PRE>
 *
 * @appliesTo All_Window_Objects
 *
 * @categories Mouse_Functions
 *
 */
int mou_limit(int x1, int y1, int x2, int y2);

/**
 * Places start column, end column, buffer id, and buffer name of the
 * selection specified in the corresponding variables.  mark_id is a handle
 * to a selection or bookmark returned by one of the built-ins
 * _alloc_selection or _duplicate_selection.  A mark_id of '' or no mark_id
 * parameter identifies the active selection.  If mark_id specifies a book
 * mark, end_col is set to start_col.
 *
 * @param start_col  start column
 * @param end_col    end column
 * @param buf_id     buffer id
 * @param mark_id    mark id
 * @param buf_name   buffer name
 * @param utf8       utf8 property of buffer
 * @param encoding   encoding property of buffer (VSENCODING_...)
 * @param Noflines   number lines in selection (including NOSAVE,HIDDEN)
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Selection_Functions
 *
 * @return Returns 0 if successful.  Otherwise, TEXT_NOT_SELECTED_RC is
 * returned.
 */
int _get_selinfo(int &start_col, int &end_col, int &buf_id , _str mark_id="", _str &buf_name="", int utf8=0, int encoding=0, int Noflines=0);

/**
 * Switches to the previous window.  The hidden window is skipped unless the 'H'
 * is specified for option (used for debugging).
 *
 * @see get_window_id
 * @see activate_window
 * @see load_files
 * @see _next_window
 *
 * @appliesTo Edit_Window
 * @categories Window_Functions, Edit_Window_Methods
 */
void _prev_window(_str option="");

/**
 *
 * Switches to the next window.
 * By default, the next window is the window that was created after the current window.
 *
 * @param option  String of zero or more of the following options:
 * <DL compact style="margin-left:10pt">
 * <DT>H</DT><DD>Specifies that hidden windows should not be skipped.  Used for debugging.</DD>
 * <DT>R</DT><DD>Specifies not to set the screen refresh flags and not to set the focus.</DD>
 * <DT>F</DT><DD>Specifies to not to set the focus.</DD>
 * <DT>M</DT><DD>Specifies to skip to the next MDI child window which may or may not have an editor control.</DD>
 * </dl>
 *
 * @see get_window_id
 * @see activate_window
 * @see load_files
 * @see _next_window
 *
 * @categories Window_Functions
 *
 */
void _next_window(_str option="");

/**
 * We recommend you call this function with no parameters unless this
 * does not meet your needs.  This function acts as a method by forcing
 * immediate display update of the current object.
 *
 * @param option may be one of the following:
 *
 * <dl>
 * <dt>'A'</dt><dd>Update all editor controls.  This does not flush paint
 * messages.</dd>
 * <dt>'W'</dt><dd>Flush paint messages to the current window.</dd>
 * <dt>'F'</dt><dd>This options is ignored and is present only for
 * backward compatibility.</dd>
 * </dl>
 *
 * @appliesTo All_Window_Objects
 *
 * @categories Check_Box_Methods, Combo_Box_Methods, Command_Button_Methods, Directory_List_Box_Methods, Drive_List_Methods, Edit_Window_Methods, Editor_Control_Methods, File_List_Box_Methods, Form_Methods, Frame_Methods, Gauge_Methods, Hscroll_Bar_Methods, Image_Methods, Label_Methods, List_Box_Methods, MDI_Window_Methods, Picture_Box_Methods, Radio_Button_Methods, Spin_Methods, Text_Box_Methods, Vscroll_Bar_Methods
 *
 */
void refresh(_str option="A");

/**
 * Posts a paint message to an object.  This function is intended to
 * increase/change performance.  Normally when a Slick-C&reg; macro finishes, all
 * edit windows, editor controls, and list boxes are updated.  If a paint
 * message is posted to the window, the window is not updated until all key
 * presses have been processed.  One purpose of this function could be to
 * more rapidly update a text box while simultaneously modifying items in a
 * list box.
 *
 * @appliesTo Edit_Window, Editor_Control, List_Box
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, List_Box_Methods
 *
 */
void _post_paint();

/**
 * @return Returns 0 if editing is allowed for this buffer.
 *
 * @see p_readonly_set_by_user
 * @see p_ReadOnly
 * @see p_readonly_mode
 * @see p_ProtectReadOnlyMode
 * @see _QReadOnly
 * @see vsQReadOnly
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
boolean _QReadOnly();


/**
 * @param string     character sequence to key in
 *
 * Inserts or overwrites string into the command line or text area
 * depending on the insert state and the cursor position.  This function
 * performs word wrap.  Use the _insert_text or insert_line function for
 * better speed.
 *
 * Don't use keyin() unless you absolutely want word wrap
 * support.  keyin was and always will be MUCH SLOWER than
 * _insert_text().  The new word wrap in comment feature added a
 * lot more overhead to this already slow function.  The
 * performance of keyin can't be improved that much.  Worse yet,
 * keyin will overwrite characters when in replace mode.  This
 * is rarely what you want in any macros you write.
 *
 * Note that when you record a macro you get a lot of keyin()
 * calls.  This is the correct code generation but it is
 * recommended that you translate the keyin calls to
 * _insert_text() if you are unhappy with the performance.
 *
 * @appliesTo Text_Box, Combo_Box, Edit_Window, Editor_Control
 *
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods,
 * Text_Box_Methods
 *
 */
void keyin(_str string);


/**
 * Sets all old line numbers for the current buffer to the line number.
 * Use the <b>_GoToOldLineNumber</b> method to go to an old line
 * number. SlickEdit uses old line numbers to better handle going
 * to an error line after lines have been inserted or deleted.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 *
 */
void _SetAllOldLineNumbers();
/**
 * Searches for the OldLineNumber specified and places the cursor on the line
 * with that old line number or the closest old line number.  If no lines
 * have an old line number set, then the cursor is placed on the real line
 * p_RLine) number given.  The "real line number" does not count non-savable
 * lines (that is lines with the NOSAVE_LF flag).  Use the
 * _SetAllOldLineNumbers function to set the old line numbers.  Note that the
 * Slick-C&reg; save command takes an option to set the old line numbers on save.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 *
 * @param OldLineNumber
 */
void _GoToOldLineNumber(int OldLineNumber);


/**
 * Splits the current line at the cursor position.  More specifically inserts
 * <b>p_newline</b> character string at cursor.  If the cursor is past the
 * end of the line, the <b>p_newline</b> character string is inserted after
 * the last character of the line but before the line termination characters.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
void _split_line(int col=1);
/**
 * Joins the next line to the end of the current line.
 *
 * @return Returns 0 if successful.
 *         The join is aborted if the join will create a line longer than the
 *         truncation length and the truncation length is non-zero
 *         (see p_TruncateLength property).   A non-zero value is returned
 *         if the join is aborted.
 *
 * @see _JoinLineToCursor
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
int _join_line();
/**
 * Joins the next line to the cursor position.  If necessary the current line
 * is padded with blanks.  If the cursor is before the end of the current
 * line, the next line is joined at the end of the current line.
 * <P>
 * @return Returns 0 if successful.  The join is aborted if the join will
 *    create a line longer than the truncation length and the truncation length
 *    is non-zero (see p_TruncateLength property).  A non-zero value is returned
 *    if the join is aborted.
 *
 * @see _join_line
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
int _JoinLineToCursor();
/**
 * Deletes number of bytes of text starting from cursor location.  Specify
 * -1 to delete to end of line.  Specify -2 to delete to end of buffer.
 * option may be "C" to delete columns of text.  If the "C" option is given,
 * Nofbytes must not be negative and is the number of columns to delete from
 * the current line.
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
void _delete_text(int Nofbytes,_str option="");
/**
 * @param string        text to insert
 * @param binary        defaults to false.
 * @param NewLineChars  defaults to "\r\n".
 *
 * Insert string at cursor position.  Specify true for the binary option if you want to
 * allow splitting of newline characters (i.e. CR&lt;insert here&gt;LF).  You may use this
 * function to insert multiple lines of text.  The NewLineChars string specifies a 1 or
 * two byte sequence which indicates the line separation characters for the string argument.
 * The NewLineChars argument is ignored if the binary option is true.
 * <P>
 * When you use this function on a record file (p_buf_width!=0) and the binary option is
 * true, all data is inserted into current line and not broken up into multiple lines.
 * <P>
 * NOTE: If you are inserting at the end of a file and the last character of string is
 * a new line, you can end up with a blank line that has no new line characters in it.
 * You can test for this condition by calling _line_length(1) which will return 0.
 * Use delete_line() to delete the line.
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
void _insert_text(_str string,boolean binary=false,_str newlineChars="\r\n");

/**
 * @param binary defaults to false.
 *
 * @param NewLineChars defaults to "\r\n".
 *
 * <p>Insert <i>string</i> at cursor position.  Specify <b>true</b> for the
 * <i>binary</i> option if you want to allow splitting of newline characters
 * (i.e. CR&lt;insert here&gt;LF).  You may use this function to insert multiple lines
 * of text.  The <i>NewLineChars</i> string specifies a 1 or two byte sequence
 * which indicates the line separation characters for the <i>string</i>
 * argument.  The <i>NewLineChars</i> argument is ignored if the binary option
 * is <b>true</b>.</p>
 *
 * <p>When you use this function on a record file (p_buf_width!=0) and the
 * <i>binary</i> option is <b>true</b>, all data is inserted into current line
 * and not broken up into multiple lines.</p>
 *
 * <p>NOTE: If you are inserting at the end of a file and the last character
 * of <i>string</i> is a new line, you can end up with a blank line that has no
 * new line characters in it.  You can test for this condition by calling
 * <b>_line_length</b>(1) which will return 0.  Use <b>delete_line</b>() to
 * delete the line.</p>
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
void _insert_text_raw(_str string,boolean binary=false,_str newlineChars="\r\n");
/**
 * @return Returns number of bytes in current line not including end of line
 * characters.  Specify <i>IncludeNLChars</i>=<b>true</b> if you want to include
 * the end of line characters in the returned length.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
int _line_length(boolean includeNLChars=false);

/**
 * Converts an imaginary column position to a physical string column
 * position and visa versa.  The input and output values are described by
 * the table below:
 *
 * <dl>
 * <dt>Second param.</dt><dd>Input column, Output column</dd>
 * <dt>'P'</dt><dd>Imaginary, Physical</dd>
 * <dt>'T'</dt><dd>Imaginary, Physical.  Position is negated if the
 * imaginary column input corresponds to the middle
 * of a tab character.</dd>
 * <dt>'L'</dt><dd>Doesn't matter, Imaginary length of string.</dd>
 * <dt>'E'</dt><dd>Doesn't matter, Imaginary length of line where the
 * <b>vsTruncQLineLength</b> is used.  This has the
 * same effect as the 'L' option if the
 * <B>VSP_TRUNCATELENGTH</B> property is
 * 0.</dd>
 * <dt>'I'</dt><dd>Physical, Imaginary</dd>
 * </dl>
 *
 * <p>The input column is returned if input column is less than or equal to
 * zero and the third parameter is not 'L'.</p>
 *
 * <p>We use the term imaginary to describe column positions which
 * correspond to a string as displayed on your screen.  Strings containing
 * tab characters are expanded before displayed.  Hence, the need arises
 * for a differentiation between physical and imaginary positions.  A
 * physical position corresponds to a character in string.  The characters
 * are number one to the length of string.  An imaginary position
 * corresponds to a position in a string once tabs have been expanded.</p>
 *
 * @see expand_tabs
 * @see text_col
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, String_Functions
 *
 */
int _text_colc(int column=0,_str option="L");

/**
 * Returns a sub-string of current line containing tab characters.  The
 * start and count specification correspond to the current line as if tab
 * characters were expanded according to the current buffers tab settings.
 * We call this type of text position or count imaginary (or column).
 * Strings containing tab characters are expanded before displayed.  Hence,
 * the need arises for a differentiation between physical and imaginary
 * positions.  A physical position corresponds to a character in string.  The
 * characters are numbered one to the length of string.  An imaginary
 * position corresponds to a position in a string once tabs have been
 * expanded.
 * <P>
 * By default, the tab characters in the current line specified by start and
 * count are expanded to spaces according to the current buffer's tab
 * settings.  option may be 'E' or 'S'.  If the 'S' option is given, only
 * bisected tab characters are expanded to the appropriate number of spaces.
 * If count extends past the imaginary length of string, the result is padded
 * with blank characters.  A count of -1 specifies the rest of the line
 * starting from the imaginary column start.  The start parameter must be
 * greater than zero.
 *
 * @see _text_colc
 * @see text_col
 * @see expand_tabs
 * @categories Edit_Window_Methods, Editor_Control_Methods, String_Functions
 */
_str _expand_tabsc(int start=1,int count=-1,_str option="E");

/**
 * This function is identical to the <b>_expand_tabsc</b> function, except
 * that the resulting string is always in the same format as the internal buffer
 * data which can be SBCS/DBCS or UTF-8.  See "Unicode and SBCS/DBCS Macro
 * Programming".
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods, String_Functions
 */
int _expand_tabsc_raw(int start=1,int count=-1,_str option="E");

/**
 * Gets or sets the line status flags for the current line.  If the flags
 * argument is given, the line status flags for the current line are
 * modified.  mask defaults to the same value as flags if it is not
 * specified.  The mask indicates which bits will be set according to flags.
 * <DL compact>
 * <DT>MLCOMMENTINDEX_LF<DD style="marginleft:120pt">Indicates which multi-line comment.
 *    Only two are allowed. Must know which multi-line comment we are in so we know
 *    what will terminate it.
 * <DT>MLCOMMENTLEVEL_LF<DD style="marginleft:120pt">Indicates multi-line comment nest level.
 * <DT>NOSAVE_LF<DD style="marginleft:90pt">Used by Difference Editor and Merge Editor.
 * Lines with the NOSAVE_LF flag set are not saved in the file.
 * <DT>VIMARK_LF<DD style="marginleft:90pt">Used by VI emulation to mark lines.
 * <DT>MODIFY_LF<DD style="marginleft:90pt">Line has been modified.
 * <DT>INSERTED_LINE_LF<DD style="marginleft:90pt">Line was inserted.
 * <DT>HIDDEN_LF<DD style="marginleft:90pt">Indicates that this line should not be displayed.
 * <DT>PLUSBITMAP_LF<DD style="marginleft:90pt">Display "+" bitmap to left of this line.
 * <DT>MINUSBITMAP_LF<DD style="marginleft:90pt">Display "-" bitmap to left of this line.
 * <DT>CURLINEBITMAP_LF<DD style="marginleft:90pt">Display current line bitmap.
 * <DT>LEVEL_LF<DD style="marginleft:90pt">Bits used to store selective display nest level.
 * </DL>
 * <P>
 * The MLCOMMENT flags can not be modified.
 *
 * @return The new current line status flags for the current line.
 *
 * @example
 * <PRE>
 *    if (_lineflags() & INSERTED_LINE_LF) {
 *        messageNwait("This line was inserted");
 *    }
 *    if (_lineflags() & MODIFY_LF) {
 *        messageNwait("This line was modified");
 *    }
 *    // Turn on hidden flag
 *    _lineflags(HIDDEN_LF,HIDDEN_LF);
 *    if (_lineflags() & HIDDEN_LF) {
 *        messageNwait("HIDDEN flag is on");
 *
 *   }
 *    // Turn off HIDDEN flag
 *    _lineflags(0,HIDDEN_LF);
 *    if (!(_lineflags() & HIDDEN_LF)) {
 *        messageNwait("hidden flag is off");
 *    }
 * </PRE>
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
int _lineflags(int newflags=0,int mask=newflags);


/**
 * Supported under Windows, Windows 95/98,and Windows NT only.  Sends a DDE
 * request to the server specified.  Results are inserted into current
 * buffer.  Specify "" for reserved argument.
 *
 * @param reserved      not used
 * @param server_name   server name
 * @param item          DDE item
 * @param topic         DDE topic
 * @param milli_timeout timout in milliseconds
 *
 * @return
 * @example
 * <PRE>
 *    // Create a temporary window and buffer hold results
 *    // of _dderequest
 *    orig_window_id=_create_temp_view(temp_window_id);
 *    // Send DDE request to Microsoft Internet Explorer to open or reopen
 *    // the HTML file specified.
 *
 *    filename=absolute("toc.html");
 *    item='"file:'filename'",,0xFFFFFFFF,0x3,,,';
 *    status=_dderequest("","iExplore",item,"WWW_OpenURL");
 *    if (status) {
 *         messageNwait("Internet Explorer is probably not running");
 *    }
 *    // Could use get_line here to look at results in this buffer.
 *    _delete_temp_view(temp_window_id);
 *    activate_window(orig_window_id);
 * </PRE>
 * @categories Miscellaneous_Functions
 */
int _dderequest(_str reserved, _str server_name, _str item, _str topic,int milli_timeout=15000);

/**
 * Inserts a list of names from the names table which match name prefix,
 * name, and have the type specified.  If name is not specified, all names
 * having the specified type are inserted.  Valid types are listed in
 * "slick.sh" and have the suffix "_TYPE".
 *
 * @categories Names_Table_Functions
 */
int _insert_name_list(int type_flag,_str name_prefix="");




/**
 * Starts spell checking from the cursor position in the current buffer.
 * The output variable, col is set to the starting column position (p_col) of
 * the word found and the cursor is placed at the this column.  If the string
 * argument is given, the string argument is spell checked instead of the
 * current buffer.  In this case, col is set to the character position within
 * the string of the word found.
 *
 * @param word
 * @param replace_word
 * @param col
 * @param string
 *
 * @return Return values are as follows:
 * <DL compact>
 * <DT>SPELL_NO_MORE_WORDS_RC<DD style="marginleft:150pt">End of buffer reached.
 * <DT>SPELL_REPEATED_WORD_RC<DD style="marginleft:150pt">Found two of the same words found in a row.
 * <DT>SPELL_WORD_NOT_FOUND_RC<DD style="marginleft:150pt">Possible misspelled word.  word variable set to the misspelled word.
 * <DT>SPELL_REPLACE_WORD_RC<DD style="marginleft:150pt">History word found.  Replace word at cursor with replace_word.
 * <DT>SPELL_ERROR_READING_MAIN_DICT_RC<DD style="marginleft:150pt">
 * </DL>
 *
 * @appliesTo Editor_Control, Edit_Window
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
int _spell_check(_str &word, _str &replace_word, int &col , _str string="");

/**
 * Spell checks a limited area of the current line.  start_col is an
 * imaginary column position and specifies the column to start spell checking
 * from.  width specifies the number of characters in the area to spell
 * check.  This function is intended to used to assist in spell checking a
 * selection.
 *
 * @param word
 * @param replace_word
 * @param col
 * @param start_col
 * @param width
 *
 * @return Return values are as follows:
 * <DL compact>
 * <DT>SPELL_NO_MORE_WORDS_RC<DD style="marginleft:150pt">End of buffer reached.
 * <DT>SPELL_REPEATED_WORD_RC<DD style="marginleft:150pt">Found two of the same words found in a row.
 * <DT>SPELL_WORD_NOT_FOUND_RC<DD style="marginleft:150pt">Possible misspelled word.  word variable set to the misspelled word.
 * <DT>SPELL_REPLACE_WORD_RC<DD style="marginleft:150pt">History word found.  Replace word at cursor with replace_word.
 * <DT>SPELL_ERROR_READING_MAIN_DICT_RC<DD style="marginleft:150pt">
 * </DL>
 *
 * @appliesTo Editor_Control, Edit_Window
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
int _spell_check_area(_str &word, _str &replace_word, int &col , int start_col ,int width=-1);


/**
 * Copies text selection to the operating system clipboard.
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Clipboard_Functions, Edit_Window_Methods, Editor_Control_Methods
 * @param markid Handle to a selection returned by one of the built-ins _alloc_selection or
 *               _duplicate_selection.  A mark_id of '' or no mark_id parameter identifies
 *               the active selection.
 * @param isClipboard
 *               Indicates whether operation is performed for the clipboard or selection.  Effects Unix only.
 * @param addClipboard 
 *               When true, a text clipboard is added to the set
 *               of clipboards which will be added later when
 *               _clipboard_close() is called. _clipboard_open
 *               must be called before clipboard close.
 * 
 * @return Returns 0 if successful.
 * @see copy_to_clipboard
 */
int _copy_to_clipboard(_str markid="",boolean isClipboard=true,boolean addClipboard=false);
/**
 * Performs many macro recording related functions.  There are two kinds of
 * macros.  Source code macros and keyboard macros.  If you have a slow
 * machine, source code macros take a little bit more time to define but run
 * faster.  Only one keyboard macro may be defined and it is not saved
 * between edit sessions.  Currently we only use keyboard macros in VI
 * emulation.
 * <P>
 * When one command calls another command, recording output is turned off.
 * The original command can turn recording output back on with the statement
 * "_macro('m', _macro('s'));".  If your command calls the show command or
 * another command, you may need to turn recording output back on.
 * 
 * @appliesTo Edit_Window
 * @categories Macro_Programming_Functions
 * @param option    option defaults to 'M' when not given.
 *                  <DL compact>
 *                  <DT>Option<DD>Description
 *                  <DT>'M'<DD>  Temporarily turns recording output on or off.  If the second parameter is specified, recording output is set to new_value.  Returns current recording output value.  A non-zero value indicates macro actions should be recorded.
 *                  <DT>'S'<DD>  Returns non-zero value if macro recording is on.  Second parameter is ignored.
 *                  <DT>'B'<DD>  Turns on macro recording.  Output for recording is to the current file.  Returns 0.  Second parameter is ignored.
 *                  <DT>'E'<DD>  Turns off macro recording.  Returns 0.  Second parameter is ignored.
 *                  <DT>'R'<DD>  Indicates that a recording macro is running.  The editor needs to know when a recorded macro is being executed to correctly handle special cases.  For example, when in BRIEF emulation, after performing a search the delay function gets called to wait for 4 seconds or until a key is pressed to temporarily show a highlight on the text that was found.  When running a recorded macro, the delay function will return immediately.
 *                  <DT>'KB'<DD> Begin recording keyboard macro.
 *                  <DT>'KE'<DD> End recording keyboard macro.
 *                  <DT>'KD'<DD> End recording keyboard macro but delete the last key sequence in the recording since it is the key sequence which executed the command to end recording.
 *                  <DT>'KR'<DD> Query if a keyboard macro is being played back.  new_value argument is ignored.
 *                  <DT>'KP'<DD> Terminate if necessary and play
 *                  the last recorded keyboard macro. new_value
 *                  optionally specifies a list of keys.
 *                  </DL>
 *                  <P>
 *                  The 'M' option allows macro recording to be on, but no recorded actions to
 *                  be output.  This allows for the editor and macros, which output recording
 *                  information, to temporarily stop outputting Slick-C&reg; source code without
 *                  turning off macro recording.
 * @param new_value
 * 
 * @return If 'S' is specified, this return an int.  If 'KE'
 *         or 'KD' specified, this returns a list keys.
 * @see start_recording
 * @see end_recording
 * @see record_macro_toggle
 * @see record_macro_end_execute
 * @see list_macros
 * @see gui_save_macro
 * @see save_macro
 * @see _macro
 */
typeless _macro(_str option='M', _str new_value=null);
int _undo_status(_str option='U');
int _pixel2col(int x);


/**
 * Saves the current search data we recommend using the
 * <i>ReservedMore</i> variable to ensure all search data is restored.
 * For backward compatibility, the <i>ReservedMore</i> parameter is
 * optional.  The built-in function <b>restore_search</b> is called with
 * the same data to restore the search which is used by the built-in
 * functions <b>repeat_search</b>, <b>_select_match</b>, and
 * <b>match_length</b>.
 *
 * @param Flags is a combination of the search flag constants below
 * (defined in "slick.sh"):
 *
 * <ul>
 * <li>VSSEARCHFLAG_IGNORECASE</li>
 * <li>VSSEARCHFLAG_MARK</li>
 * <li>VSSEARCHFLAG_POSITIONONLASTCHAR</li>
 * <li>VSSEARCHFLAG_REVERSE</li>
 * <li>VSSEARCHFLAG_RE</li>
 * <li>VSSEARCHFLAG_WORD</li>
 * <li>VSSEARCHFLAG_UNIXRE</li>
 * <li>VSSEARCHFLAG_NO_MESSAGE</li>
 * <li>VSSEARCHFLAG_GO</li>
 * <li>VSSEARCHFLAG_INCREMENTAL</li>
 * <li>VSSEARCHFLAG_WRAP</li>
 * <li>VSSEARCHFLAG_HIDDEN_TEXT</li>
 * <li>VSSEARCHFLAG_SCROLL_STYLE</li>
 * <li>VSSEARCHFLAG_BINARYDBCS</li>
 * <li>VSSEARCHFLAG_BRIEFRE</li>
 * <li>VSSEARCHFLAG_PRESERVE_CASE</li>
 * <li>VSSEARCHFLAG_WORDPREFIX</li>
 * <li>VSSEARCHFLAG_WORDSUFFIX</li>
 * <li>VSSEARCHFLAG_WORDSTRICT</li>
 * <li>VSSEARCHFLAG_HIDDEN_TEXT_ONLY</li>
 * <li>VSSEARCHFLAG_NOSAVE_TEXT</li>
 * <li>VSSEARCHFLAG_NOSAVE_TEXT_ONLY</li>
 * <li>VSSEARCHFLAG_PROMPT_WRAP</li>
 * </ul>
 *
 * @param flags2 currently contains flags for color coding.  Constants are
 * not yet defined for this.
 *
 * @example
 * <pre>
 * search('test');
 * save_search(string, options, word_re);
 * status=search('xyz');
 * if (status) {
 *     messageNwait("Can't find xyz");
 * }
 * restore_search(string, options, word_re);
 * // Repeats search for 'test'
 * repeat_search();
 * </pre>
 *
 * @see repeat_search
 * @see _select_match
 * @see match_length
 * @see search_replace
 * @see restore_search
 * @see search
 * @see _search_case
 *
 * @categories Search_Functions
 *
 */
void save_search(_str &search_string, int &flags, _str &word_re,_str &ReservedMore="",int &flags2=0);
/**
 * Restores the current search data.  The built-in function
 * <b>save_search</b> may be called to return the current search data
 * which is used by the built-in functions <b>repeat_search</b>,
 * <b>_select_match</b>, and <b>match_length</b>.  <i>Flags</i> is a
 * combinations of the search flags constants below (defined in
 * "slick.sh"):
 *
 * <ul>
 * <li>VSSEARCHFLAG_IGNORECASE</li>
 * <li>VSSEARCHFLAG_MARK</li>
 * <li>VSSEARCHFLAG_POSITIONONLASTCHAR</li>
 * <li>VSSEARCHFLAG_REVERSE</li>
 * <li>VSSEARCHFLAG_RE</li>
 * <li>VSSEARCHFLAG_WORD</li>
 * <li>VSSEARCHFLAG_UNIXRE</li>
 * <li>VSSEARCHFLAG_NO_MESSAGE</li>
 * <li>VSSEARCHFLAG_GO</li>
 * <li>VSSEARCHFLAG_INCREMENTAL</li>
 * <li>VSSEARCHFLAG_WRAP</li>
 * <li>VSSEARCHFLAG_HIDDEN_TEXT</li>
 * <li>VSSEARCHFLAG_SCROLL_STYLE</li>
 * <li>VSSEARCHFLAG_BINARY</li>
 * <li>VSSEARCHFLAG_BRIEFRE</li>
 * <li>VSSEARCHFLAG_PRESERVE_CASE</li>
 * <li>VSSEARCHFLAG_WORDPREFIX</li>
 * <li>VSSEARCHFLAG_WORDSUFFIX</li>
 * <li>VSSEARCHFLAG_WORDSTRICT</li>
 * <li>VSSEARCHFLAG_HIDDEN_TEXT_ONLY</li>
 * <li>VSSEARCHFLAG_NOSAVE_TEXT</li>
 * <li>VSSEARCHFLAG_NOSAVE_TEXT_ONLY</li>
 * <li>VSSEARCHFLAG_PROMPT_WRAP</li>
 * </ul>
 *
 * @param flags2 currently contains flags for color coding.  Constants are
 * not yet defined for this.
 *
 * @see repeat_search
 * @see _select_match
 * @see match_length
 * @see search_replace
 * @see save_search
 * @see search
 * @see _search_case
 *
 * @categories Search_Functions
 *
 */
void restore_search(_str search_string, int flags, _str word_re,_str ReservedMore=null,int flags2=0);


/**
 * Returns the character position (first character is 1) corresponding to
 * the pixel_x position given.  This function is typically used after a mouse
 * press within a text box control to determine which character to place the
 * cursor on.  For edit window and editor controls, we recommend you use the
 * p_cursor_x property.
 *
 * @categories Mouse_Functions
 *
 */
int mou_col(int pixel_x);


/**
 * Reformats the selection specified according to the current margin
 * settings.  If the buffer containing the specified selection is active when
 * this function is invoked, the resulting lines are inserted after the end
 * of the selection.  Otherwise the resulting lines are inserted after the
 * cursor.  Character mark is not supported.  mark_id is a handle to a
 * selection returned by one of the built-ins _alloc_selection or
 * _duplicate_selection.  A mark_id of '' or no mark_id parameter identifies
 * the active selection.
 *
 * @return Returns 0 if successful.  Common return codes are
 * TEXT_NOT_SELECTED_RC, and LINE_OR_BLOCK_SELECTION_REQUIRED_RC.  On error,
 * message is displayed.
 *
 * @see _get_reflow_pos
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Selection_Functions
 *
 */
int _reflow_selection(_str markid="");


/**
 * Sorts the selection specified in ascending or descending order in
 * case sensitivity specified.  Sorting defaults to ascending and case
 * sensitive.  If the buffer containing the specified selection is active
 * when this function is invoked, the resulting lines are inserted after the
 * end of the selection.  Otherwise the resulting lines are inserted after
 * the cursor.  If a character selection is used, it is converted to a line
 * type selection.
 *
 * @param cmdline       cmdline is a string in the format: [A | D]  [E | I] [-N | -F]
 *    <P>
 *    Multiple options having the following meaning may be specified:
 *    <DL compact>
 *    <DT>A <DD>Sort in ascending order.
 *    <DT>D <DD>Sort in descending order.
 *    <DT>I <DD>Case insensitive sort (Ignore case).
 *    <DT>E <DD>Case sensitive sort (Exact case).
 *    <DT>-N<DD>Sort numbers
 *    <DT>-F<DD>Sort filenames
 *    </DL>
 *
 * @example
 * <PRE>
 * _sort_selection();   // Sort in ascending order and exact case.
 * _sort_selection('I');   // Sort in ascending order and ignore case.
 * _sort_selection('DI');  // Sort in descending order and ignore case.
 * _sort_selection('-n d');   // Sort numbers in descending order
 * </PRE>
 *
 * @return Returns 0 if successful.  Common return codes are
 *    INVALID_OPTION_RC, LINE_OR_BLOCK_SELECTION_REQUIRED_RC,
 *    NOT_ENOUGH_MEMORY_RC, TOO_MANY_SELECTIONS_RC, and
 *    INVALID_SELECTION_HANDLE_RC.  On error, message displayed.
 *
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Selection_Functions
 *
 */
int _sort_selection(_str cmdline="",_str markid="");

/**
 * Uses the selection id specified to select the last string matched by one
 * of the built-in functions search or repeat_search.
 *
 * @parm mark_id     mark_id is a selection handle allocated by the _alloc_selection built-in.
 * A mark_id of '' specifies the active selection or selection showing and is
 * always allocated.
 *
 * @see match_length
 * @see search
 * @see repeat_search
 * @see search_replace
 * @see save_search
 * @see restore_search
 * @see _search_case
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 *
 */
void _select_match(_str markid="");



/**
 * Starts or extends the block selection specified.  Used for processing
 * columns of text.  The first _select_block becomes the pivot point.
 * Subsequent _select_block calls will select the area between the pivot
 * point and the cursor.
 *
 * @param mark_id    mark_id is a selection handle allocated by the _alloc_selection built-in.
 *    A mark_id of '' specifies the active selection or selection showing and is always allocated.
 * @param options    options is a string of zero or more of the following:
 * <DL compact>
 * <DT>'C'<DD> Specifies that the selection extend as the cursor moves.
 * <DT>'E'<DD> (Default) Requires that _select_block be executed to end the text selection.
 * <DT>'P'<DD> specifies a persistent select style.  Macros use this to help determine if a selection should be unhighlighted when the cursor moves.
 * </DL>
 *
 * @return Returns 0 if successful.  Possible returns are TEXT_NOT_SELECT_RC.  and TEXT_ALREADY_SELECTED_RC.
 *
 * @see _select_char
 * @see _select_line
 * @see _show_selection
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 *
 */
int _select_block(_str markid="",_str options='E');


/**
 * Starts or extends the character selection specified.  Used for processing
 * sentences of text which do not start and end on line boundaries.  The
 * first _select_char becomes the pivot point.  Subsequent select_char calls
 * will extend the selection between the pivot point and the cursor.
 *
 * @param mark_id       is a selection handle allocated by the _alloc_selection built-in.
 *                      A mark_id of '' specifies the active selection or selection
 *                      showing and is always allocated.
 *
 * @param options       may be zero or more of the following letters:
 *    <DL compact>
 *    <DT><B>'E'</B>
 *    <DD>Specifies that selecting an area of text requires _select_char be
 *    executed to select the end of the text area as well as the beginning.  If
 *    the 'C' letter is not specified, this select style is used.
 *    <DT><B>'C'</B>
 *    <DD>Specifies that the selection extend as the cursor moves.
 *    <DT><B>'I'</B>
 *    <DD>Specifies an inclusive selection.  Currently only character selections
 *    are affected by this option.
 *    <DT><B>'N'</B>
 *    <DD>Specifies a non-inclusive selection.  Currently only character
 *    selections are affected by this option.  If the 'I' letter is not
 *    specified, the character selection will be non-inclusive selection.
 *    <DT><B>'P'</B>
 *    <DD>A value of 'P' specifies a persistent select style and may be
 *    specified in addition to the other options above.  Macros use this to help
 *    determine if a selection should be unhighlighted when the cursor moves.
 *    </DL>
 *
 * @return Returns 0 if successful.  Possible returns are TEXT_NOT_SELECT_RC.
 *         and TEXT_ALREADY_SELECTED_RC.
 *
 * @see _select_block
 * @see _select_line
 * @see _show_selection
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 *
 */
int _select_char(_str markid="",_str options='EN');

/**
 * Starts or extends the line mark specified.  Used for processing complete
 * lines of text.  The first _select_line becomes the pivot point.
 * Subsequent _select_line calls will mark the area between the pivot point
 * and the cursor.
 *
 * @param mark_id    is a selection handle allocated by the _alloc_selection built-in.
 *                   A mark_id of '' specifies the active selection or selection
 *                   showing and is always allocated.
 *
 * @param options    is a string of zero or more of the following:
 *    <DL compact>
 *    <DT><B>'C'</B>
 *    <DD>Specifies that the selection extend as the cursor moves.
 *    <DT><B>'E'</B>
 *    <DD>(Default) Requires that _select_line be executed to end the text selection.
 *    <DT><B>'P'</B>
 *    <DD>specifies a persistent select style.  Macros use this to help
 *    determine if a selection should be unhighlighted when the cursor moves.
 *    </DL>
 *
 * @return Returns 0 if successful.  Possible returns are TEXT_NOT_SELECT_RC.
 *         and TEXT_ALREADY_SELECTED_RC.
 *
 * @see _select_block
 * @see _select_char
 * @see _show_selection
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 *
 */
int _select_line(_str markid="",_str options='E');
/**
 * Places cursor on first character of selection specified.
 * If the selection type is LINE, the cursor is moved to the first line of the
 * selection and the column position is unchanged.
 *
 * @param mark_id    is a handle to a selection or bookmark returned by one of
 *                   the built-ins _alloc_selection or _duplicate_selection.
 *                   A mark_id of '' or no mark_id parameter identifies the active selection.
 * @param LockSelection  When true, the selection is extended to the cursor and the
 *                       select is locked (moving the cursor will no longer remove or
 *                       extend the selection).
 * @param RestoreScrollPos When true, the cursor y and left edge scroll positions are
 *                         restored if possible (window size could be smaller and y
 *                         be outsize window height).
 *
 * @return Returns 0 if successful.  Possible return values are TEXT_NOT_SELECTED_RC or
 *         INVALID_SELECTION_HANDLE_RC.  On error, message is displayed.
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 */
int _begin_select(_str markid="",boolean LockSelection=true,boolean RestoreScrollPos=true);
/**
 * Places cursor on last character of selection specified.
 * If the selection type is LINE, the cursor is moved to the lasst line of the
 * selection and the column position is unchanged.
 *
 * @param mark_id    is a handle to a selection or bookmark returned by one of
 *                   the built-ins _alloc_selection or _duplicate_selection.
 *                   A mark_id of '' or no mark_id parameter identifies the active selection.
 * @param LockSelection  When true, the selection is extended to the cursor and the
 *                       select is locked (moving the cursor will no longer remove or
 *                       extend the selection).
 * @param RestoreScrollPos When true, the cursor y and left edge scroll positions are
 *                         restored if possible (window size could be smaller and y
 *                         be outsize window height).
 *
 * @return Returns 0 if successful.  Possible return values are TEXT_NOT_SELECTED_RC or
 *         INVALID_SELECTION_HANDLE_RC.  On error, message is displayed.
 *
 * @appliesTo  Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 */
int _end_select(_str markid="",boolean LockSelection=true,boolean RestoreScrollPos=true);


/**
 * Deletes characters at left edge of marked area specified.
 * <i>mark_id</i> is a handle to a selection returned by one of the built-
 * ins <b>_alloc_selection</b> or <b>_duplicate_selection</b>.  A
 * <i>mark_id</i> of '' or no <i>mark_id</i> parameter identifies the
 * active selection.
 *
 * @return Returns 0 if successful.  Common return codes are
 * TEXT_NOT_SELECTED_RC, and
 * LINE_OR_BLOCK_SELECTION_REQUIRED_RC.  On error,
 * message is displayed.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Selection_Functions
 *
 */
int _shift_selection_left(_str markid="");

/**
 * Inserts space character at left edge of marked area specified.
 * <i>mark_id</i> is a handle to a selection returned by one of the built-
 * ins <b>_alloc_selection</b> or <b>_duplicate_selection</b>.  A
 * <i>mark_id</i> of '' or no <i>mark_id</i> parameter identifies the
 * active selection.
 *
 * @return Returns 0 if successful.  Common return codes are
 * TEXT_NOT_SELECTED_RC, and
 * LINE_OR_BLOCK_SELECTION_REQUIRED_RC.  On error,
 * message is displayed.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Selection_Functions
 *
 */
int _shift_selection_right(_str markid="");


/**
 * Copies the selection specified by mark_id to cursor.  Character or block
 * selections are inserted before the character at the cursor.  Line
 * selections are always inserted after the current line.  Resulting
 * selection is always on destination text.
 *
 *
 * @return Returns 0 if successful.  Common return codes are
 *         TEXT_NOT_SELECTED_RC, SOURCE_DEST_CONFLICT_RC, and
 *         INVALID_SELECTION_HANDLE_RC.  On error, message is displayed.
 *
 * @appliesTo  Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 */
int _copy_to_cursor(_str markid="",int MarkFlags=-1);

/**
 * Overlays the selected block of text specified at the cursor position and
 * fills in the source block with spaces.  This command handles all source
 * and destination conflicts.  A useful function for this command is to move
 * a large column of numbers up or down.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @param mark_id    is a handle to a selection returned by one of the built-ins
 *                   _alloc_selection or _duplicate_selection.  A mark_id of ''
 *                   or no mark_id parameter identifies the active selection.
 *
 * @return Returns 0 if successful.  Common return codes are
 * TEXT_NOT_SELECTED_RC, BLOCK_SELECTION_REQUIRED_RC.  On error, message is
 * displayed.
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 */
int _adjust_block_selection(_str markid="");
/**
 * Overwrites block selection specified at cursor position.  No clipboard is
 * created.  Resulting selection is placed on inserted text.
 *
 * @param mark_id    is a handle to a selection returned by one of the built-ins
 *                   _alloc_selection or _duplicate_selection.  A mark_id of ''
 *                   or no mark_id parameter identifies the active selection.
 *
 * @return Returns 0 if successful.  Common return codes are
 * TEXT_NOT_SELECTED_RC, BLOCK_SELECTION_REQUIRED_RC.  On error, message is
 * displayed.
 *
 * @appliesTo Editor_Control, Edit_Window
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 *
 */
int _overlay_block_selection(_str markid="");
/**
 * Moves the selection to the cursor.  For block and character selections,
 * the text is inserted at the cursor position.  In the case of a line
 * selection, the lines are inserted before or after the current line
 * depending upon the Line insert style.  Lines are inserted after the current
 * line by default.  Resulting selection is placed on the inserted text.
 * Text may be marked with one of the commands select_char (F8), select_line
 * (Ctrl+L), or select_block (Ctrl+B).
 *
 * @param mark_id    is a handle to a selection returned by one of the built-ins
 *                   _alloc_selection or _duplicate_selection.  A mark_id of ''
 *                   or no mark_id parameter identifies the active selection.
 *
 * @return Returns 0 if successful.  Common return values are
 *         TEXT_NOT_SELECTED_RC, SOURCE_DEST_CONFLICT_RC, and
 *         INVALID_SELECTION_HANDLE_RC.  On error, message is displayed.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 *
 */
int _move_to_cursor(_str markid="");


/**
 * Compares current line position to first line of mark specified.
 *
 * @param markid is a handle to a selection returned by one of the
 *               built-ins _alloc_selection or _duplicate_selection.  A <i>mark_id</i> of '' or
 *               no <i>mark_id</i> parameter identifies the active selection.
 * @appliesTo Edit_Window, Editor_Control
 *
 * @return
 *         <DL compact>
 *         <DT>0      <DD>Current line is on first line of mark
 *         <DT>&gt; 0 <DD>Current line is after first line of mark
 *         <DT>&lt; 0 <DD>Current line is before first line of mark
 *         <DT>-1     <DD>Text is not marked or mark is not in current buffer
 *         </DL>
 * @see _end_select_compare
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 */
int _begin_select_compare(_str markid="");
/**
 * Compares current line position to last line of mark specified.
 *
 * @param markid    is a handle to a selection returned by one of the built-ins
 *                   _alloc_selection or _duplicate_selection.  A mark_id of ''
 *                   or no mark_id parameter identifies the active selection.
 * @return
 *    <DL compact>
 *    <DT>0      <DD>Current line is on last line of mark
 *    <DT>&gt; 0 <DD>Current line is after last line of mark
 *    <DT>&lt; 0 <DD>Current line is before last line of mark
 *    <DT>-1     <DD>Text is not marked or mark is not in current buffer
 *    </DL>
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @see _begin_select_compare
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 */
int _end_select_compare(_str markid="");



/**
 * Switches to the next buffer.
 *
 * @param options    is a string of zero or more of the following:
 *    <DL compact>
 *    <DT>'H'<DD>Allow switching to the hidden window.
 *    <DT>'N'<DD>Don't update the active buffer's non-active cursor position information.
 *    <DT>'R'<DD>Don't do any screen updating.
 *    </DL>
 *    <P>
 *    The active cursor position information is saved in the active buffer's non-active
 *    cursor position information unless the 'N' option is specified.  Each buffer maintains ONE
 *    non-active cursor position which is updated when you switch to a
 *    buffer within the same window using one of the built-ins _next_buffer,
 *    _prev_buffer, _delete_buffer, load_files, _begin_select, and _end_select.
 *    When the non-active buffer becomes active, the non-active cursor position information
 *    is copied into the windows cursor position.  Switching windows DOES NOT update the
 *    buffers non-active cursor position information.
 *    <P>
 *    The 'H' option determines whether buffers with (p_buf_flags&VSBUFFLAG_HIDDEN) true may be selected.
 *    <P>
 *    The 'R' options specifies that the screen should not be refreshed.
 *
 * @see _prev_buffer
 * @see _delete_buffer
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Buffer_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
void _next_buffer(_str options="");
/**
 * Switches to the previous buffer.
 *
 * @param options    is a string of zero or more of the following:
 *    <DL compact>
 *    <DT>'H'<DD>Allow switching to the hidden window.
 *    <DT>'N'<DD>Don't update the active buffer's non-active cursor position information.
 *    <DT>'R'<DD>Don't do any screen updating.
 *    </DL>
 *    <P>
 *    The active cursor position information is saved in the active buffer's non-active
 *    cursor position information unless the 'N' option is specified.  Each buffer maintains ONE
 *    non-active cursor position which is updated when you switch to a
 *    buffer within the same window using one of the built-ins _next_buffer,
 *    _prev_buffer, _delete_buffer, load_files, _begin_select, and _end_select.
 *    When the non-active buffer becomes active, the non-active cursor position information
 *    is copied into the windows cursor position.  Switching windows DOES NOT update the
 *    buffers non-active cursor position.
 *    <P>
 *    The 'H' option determines whether buffers with (p_buf_flags&VSBUFFLAG_HIDDEN) true may be selected.
 *    <P>
 *    The 'R' options specifies that the screen should not be refreshed.
 *
 * @see _next_buffer
 * @see _delete_buffer
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Buffer_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
void _prev_buffer(_str options="");
/**
 * Deletes the active buffer from the buffer ring even if the buffer is
 * modified.  The previous buffer's non-active cursor position information
 * copied into the active cursor position making the previous
 * buffer active.
 *
 * @appliesTo  Edit_Window
 * @see _next_buffer
 * @see _prev_buffer
 *
 * @categories Buffer_Functions, Edit_Window_Methods
 */
void _delete_buffer();
/**
 * This function has been deprecated.  We recommend not calling it.
 *
 * @categories Window_Functions 
 * @deprecated Use {@link _next_window()}
 */
void _next_view();

/**
 * This function has been deprecated.  We recommend not calling it.
 *
 * @categories Window_Functions
 * @deprecated Use {@link _prev_window()}
 */
void _prev_view();
/**
 * This function has been deprecated.  We recommend not calling it.
 *
 * @categories Window_Functions
 * @deprecated Use {@link _delete_window()}
 */
void _quit_view();
/**
 * Undo the last operation performed by the editor control.
 *
 * @param option     letter defaults to 'U' and may be one of the following:
 *    <DL compact>
 *    <DT>'U'
 *    <DD>If the current buffer allows more than 0 undoable steps, the last
 *    operation is undone.  Otherwise, the current line is restored to its
 *    original value before the cursor moved onto it.
 *    <DT>'C'
 *    <DD>Same 'U' option except when the current buffer has more than 0
 *    undoable steps.  Consecutive cursor motion is undone as one step.
 *    <DT>'R'
 *    <DD>If the current buffer has more than 0 undoable steps, the last undo
 *    operation is redone.  Otherwise, this function has no affect.
 *    <DT>'S'
 *    <DD>Starts a new level of undo.
 *    </DL>
 *
 * @return On successful, completion, a number greater than or equal to zero is
 *    returned which is composed of the flags below (defined in "slick.sh"):
 *    <UL>
 *    <LI>LINE_DELETES_UNDONE
 *    <LI>CURSOR_MOVEMENT_UNDONE
 *    <LI>MARK_CHANGE_UNDONE
 *    <LI>TEXT_CHANGE_UNDONE
 *    <LI>LINE_INSERTS_UNDONE
 *    <LI>MODIFY_FLAG_UNDONE
 *    </UL>
 *    If not successful, NOTHING_TO_UNDO_RC or NOTHING_TO_REDO_RC is returned.
 *
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 * @see undo_msg
 */
void _undo(_str option="U");


/**
 * Moves the text cursor one position to the right.
 *
 * @see left
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 *
 */
void right();
/**
 * Deletes character under text cursor.
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
void _delete_char();

/**
 * Deletes character if any to left of text area cursor and moves cursor to
 * left.  When left edge is hit, text area is smooth scrolled or center
 * scrolled depending on the scroll style.
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 *
 */
void _rubout();

/**
 * Moves the text cursor one position to the left.
 *
 * @see right
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 *
 */
void left();
/**
 * Places cursor at column 1 of current line.
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @see _end_line
 *
 * @categories Combo_Box_Methods, CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
void _begin_line();
/**
 * Places cursor after end of current line.
 *
 * @see _begin_line
 * @categories Combo_Box_Methods, CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
void _end_line();

/**
 * Places cursor at first line and first column of buffer
 *
 * @see bottom
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
void top();
/**
 * Places text cursor at end of last line of buffer.
 *
 * @see top
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
void bottom();
/**
 * Moves cursor number of lines up.  If number is not given a value of '1' is used.
 * If line is not in view, line is center scrolled or smooth scrolled into view.
 *
 * @param Noflines        Number of lines to move up
 * @param doScreenLines      When true, cursor up to previous soft wrap line or previous line.
 *
 * @return Returns 0 if successful.  Otherwise TOP_OF_FILE_RC is returned.
 *
 * @example
 * <PRE>
 *     status=up();
 *     if (status==TOP_OF_FILE_RC) {
 *          message(get_message(status));
 *     }
 * </PRE>
 *
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 * @see down
 */
int up(int Noflines=1,boolean doScreenLines=false);
/**
 * Moves cursor number of lines down.  If number is not given, a value of
 * '1' is used.  If line is not in view, line is center scrolled or smooth
 * scrolled into view.
 *
 * @param Noflines        Number of lines to cursor down
 * @param doScreenLines      When true, cursor down to next soft wrap line or next line.
 *
 * @example
 * <PRE>
 *     status=down();
 *     if (status==BOTTOM_OF_FILE_RC ) {
 *         message(get_message(status));
 *     }
 * </PRE>
 *
 * @return Returns 0 if successful. Otherwise BOTTOM_OF_FILE_RC is returned.
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @see up
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
int down(int Noflines=1,boolean doScreenLines=false);


/**
 * Places cursor at previous tab stop if any.  To set the tab stops see help
 * on tabs command.  Each buffer has its own tab stops.  The default tabs for
 * the current buffer may be set with the {@link p_tabs} property.
 *
 * @see tab
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
void backtab();

/**
 * Places cursor at next tab stop if any.  If column is not in view, column
 * is center scrolled or smooth scrolled into view depending on the scroll
 * style.
 *
 * @see backtab
 * @see tabs
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
void tab();

/**
 * Moves text under the cursor <b>p_char_height</b> - 1 lines up.  If the
 * bottom line of the buffer is reached and it is not visible, the cursor is
 * placed at the last row of the window.  <b>_page_down</b> is not
 * affected by the scroll style.
 *
 * @return If bottom of buffer is reached, BOTTOM_OF_FILE_RC is returned.
 * Otherwise 0 is returned.
 *
 * @example
 * <pre>
 *           status=_page_down();
 *           if (status==BOTTOM_OF_FILE_RC then
 *              // BOTTOM centers last line of buffer if scroll style is
 *              // CENTER.
 *              bottom();
 *              message(get_message(rc));
 *           }
 * </pre>
 *
 * @see _page_up
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
int _page_down();

/**
 * Moves text under the cursor <b>p_char_height</b> - 1 lines down.
 * The scroll style has no effect on this function.
 *
 * @return If top of buffer is hit, TOP_OF_FILE_RC is returned.  Otherwise, 0 is
 * returned.
 *
 * @see page_down
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
int _page_up();


/**
 * Replaces the match found by the last <b>search</b> or
 * <b>repeat_search</b> with <i>replace_string</i>.  If the 'R' option is
 * specified, a search for the next string is performed with the same
 * options and direction specified by the last <b>search</b> or
 * <b>repeat_search</b> call.
 *
 * @return Returns 0 if successful.  Possible return codes are
 * INVALID_OPTION_RC, and STRING_NOT_FOUND_RC.  On
 * error, message is displayed.
 *
 * @see repeat_search
 * @see _select_match
 * @see match_length
 * @see search
 * @see save_search
 * @see restore_search
 * @see _search_case
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 *
 */
int search_replace(_str replace_string,_str option="");

/**
 * Repeats a search initiated by one of the built-ins, search(), or
 * repeat_search().  This built-in will not repeat a search initiated
 * with one of the search commands <b>find</b>, or <b>replace</b>
 * (see <b>find_next</b> command).
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 * @param options
 *                  <i>SearchOptions</i> is a string
 *                  of one or more of the following option letters:
 *
 *                  <dl compact style="margin-left:20pt">
 *                  <dt>+</dt><dd>Forward search.</dd>
 *                  <dt>-</dt><dd>Reverse search.</dd>
 *                  <dt>&lt;</dt><dd>Place cursor at beginning of string found.</dd>
 *                  <dt>></dt><dd>Place cursor after end of string found.</dd>
 *                  <dt>E</dt><dd>Case sensitive search.</dd>
 *                  <dt>I</dt><dd>Case insensitive search.</dd>
 *                  <dt>M</dt><dd>Search within visible mark.</dd>
 *                  <dt>R</dt><dd>Search for regular expression.  Syntax of regular
 *                  expression is described in section "<b>SlickEdit
 *                  Regular Expressions</b>".</dd>
 *                  <dt>U</dt><dd>Interpret string as a UNIX regular expression.   See
 *                  section <b>UNIX Regular Expressions</b>.</dd>
 *                  <dt>B</dt><dd>Interpret string as a Brief regular expression.   See
 *                  section <b>Brief Regular Expressions</b>.</dd>
 *                  <dt>'&'</dt><dd>Interpret string as a wildcard
 *                  expression. See section Wildcard Expressions.</dd>
 *                  <dt>N</dt><dd>Do not interpret search string as a regular
 *                  expression search string.</dd>
 *                  <dt>@</dt><dd>No error message.</dd>
 *                  <dt>W</dt><dd>Limits search to words.  Used to search and replace
 *                  variable names.  The default word characters are
 *                  [A-Za-z0-9_$].</dd>
 *                  <dt>W=<i>SlickEdit-regular-expression</i></dt><dd>
 *                  Specifies a word search and sets the default word
 *                  characters to those matched by the <i>SlickEdit-
 *                  regular-expression</i> given.</dd>
 *                  <dt>W:P</dt><dd>Limits search to word prefix.  For example,
 *                  searching for "pre" matches "pre" and "prefix" but
 *                  not "supreme" or "supre".</dd>
 *                  <dt>W:PS</dt><dd>Limits search to strict word prefix.  For example,
 *                  searching for "pre" matches "prefix" but not "pre",
 *                  "supreme" or "supre".</dd>
 *                  <dt>W:S</dt><dd>Limits search to word suffix.  For example,
 *                  searching for "fix" matches "fix" and "sufix" but
 *                  not "fixit".</dd>
 *                  <dt>W:SS</dt><dd>Limits search to strict word suffix.  For example,
 *                  searching for "fix" matches "sufix" but not "fix" or
 *                  "fixit".</dd>
 *                  <dt>Y</dt><dd>Binary search.  This allows start positions in the
 *                  middle of a DBCS or UTF-8 character.  This option
 *                  is useful when editing binary files (in SBCS/DBCS
 *                  mode) which may contain characters which look
 *                  like DBCS but are not.  For example, if you search
 *                  for the character 'a', it will not be found as the
 *                  second character of a DBCS sequence unless this
 *                  option is specified.</dd>
 *                  <dt>,</dt><dd>Delimiter to separate ambiguous options.
 *                  <dt>X<i>CCLetters</i></dt><dd>Requires the first character of search string
 *                  NOT be one of the color coding elements specified.
 *                  For example, "XCS" requires that the first character
 *                  not be in a comment or string. <i>CCLetters</i> is
 *                  a string of one or more of the following color
 *                  coding element letters:</dd>
 *
 *                  <dl compact style="margin-left:20pt">
 *                  <dt>O</dt><dd>Other</dd>
 *                  <dt>K</dt><dd>Keyword</dd>
 *                  <dt>N</dt><dd>Number</dd>
 *                  <dt>S</dt><dd>String</dd>
 *                  <dt>C</dt><dd>Comment</dd>
 *                  <dt>P</dt><dd>Preprocessing</dd>
 *                  <dt>L</dt><dd>Line number</dd>
 *                  <dt>1</dt><dd>Symbol 1</dd>
 *                  <dt>2</dt><dd>Symbol 2</dd>
 *                  <dt>3</dt><dd>Symbol 3</dd>
 *                  <dt>4</dt><dd>Symbol 4</dd>
 *                  <dt>F</dt><dd>Function color</dd>
 *                  <dt>V</dt><dd>No save line</dd>
 *                  </dl>
 *
 *                  <dt>C<i>CCLetters</i></dt><dd>Requires the first character of
 *                  search string to be one of the color coding elements specified. See
 *                  <i>CCLetters</i> above.</dd>
 *                  </dl>
 *                  <p>Any search option not specified takes on the same value as the last
 *                  search executed.
 * @param start_col The exact start column of the search may be
 *                  specified by <i>start_col</i>.  If <i>start_col</i> is not given,
 *                  searching continues so that the string found by the last search
 *                  command is not found again.</p>
 *
 * @return Returns 0 if successful.  Possible return codes are
 *         INVALID_OPTION_RC and STRING_NOT_FOUND_RC.  On error,
 *         message is displayed.
 * @example
 * <pre>
 * // While we could use a regular expression to do what this loop does, this example
 * // is easy to understand.
 * status=search('_command');
 * for (;;) {
 *     if (status) break;
 *     if (p_col==1) {
 *
 *         status=0;break;   // Found _command in column 1
 *     }
 *     status=repeat_search();
 * }
 * </pre>
 *
 * @see search
 * @see _select_match
 * @see match_length
 * @see search_replace
 * @see save_search
 * @see restore_search
 * @see _search_case
 */
int repeat_search(_str options,int start_col=0);

/**
 * Searches for <i>search_string</i> specified.  If <i>replace_string</i>
 * is specified, a search and replace without prompting is performed.
 * The number of changes is returned in the optional <i>Nofchanges</i>
 * variable.  Press and hold Ctrl+Alt+Shift to terminate a long search.
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 * @param searchString  String to search for
 * @param options    A string of options having the following meaning:
 *
 *                   <dl compact style="margin-left:20pt">
 *                   <dt>'+'</dt><dd>(Default) Forward search.</dd>
 *                   <dt>'-'</dt><dd>Reverse search.</dd>
 *                   <dt>'&lt;'</dt><dd>(Default) Place cursor at beginning of string found.</dd>
 *                   <dt>'>'</dt><dd>Place cursor after end of string found.</dd>
 *                   <dt>'E'</dt><dd>(Default) Case sensitive search.</dd>
 *                   <dt>'I'</dt><dd>Case insensitive search.</dd>
 *                   <dt>'M'</dt><dd> Search within visible mark.</dd>
 *                   <dt>'H'</dt><dd> Find text in hidden lines.   Only the line contain the
 *                   first character of the search string is checked.</dd>
 *                   <dt>'R'</dt><dd>Search for SlickEdit regular expression.  See
 *                   SlickEdit Regular Expressions.</dd>
 *                   <dt>'U'</dt><dd>Interpret string as a UNIX regular expression.   See
 *                   section UNIX Regular Expressions.</dd>
 *                   <dt>'B'</dt><dd>Interpret string as a Brief regular expression.   See
 *                   section Brief Regular Expressions.</dd>
 *                   <dt>'L'</dt><dd>Interpret string as a Perl regular expression.   See
 *                   section Brief Regular Expressions.</dd>
 *                   <dt>'&'</dt><dd>Interpret string as a wildcard
 *                   expression. See section Wildcard Expressions.</dd>
 *                   <dt>'N'</dt><dd>(Default) Do not interpret search string as a regular
 *                   search string.</dd>
 *                   <dt>'P'</dt><dd>Wrap to beginning/end when string not found.  Flag
 *                   is set.  However, this option has no effect on this
 *                   function.</dd>
 *                   <dt>'@'</dt><dd>No error message.</dd>
 *                   <dt>'*'</dt><dd>This option is ignored.</dd>
 *                   <dt>'W'</dt><dd>Limits search to words.  Used to search and replace
 *                   variable names.  The default word characters are
 *                   [A-Za-z0-9_$].</dd>
 *                   <dt>'W=<i>SlickEdit-regular-expression</i>'</dt><dd>
 *                   Specifies a word search and sets the default word
 *                   characters to those matched by the <i>SlickEdit-
 *                   regular-expression</i> given.</dd>
 *                   <dt>W:P</dt><dd>Limits search to word prefix.  For example,
 *                   searching for "pre" matches "pre" and "prefix" but
 *                   not "supreme" or "supre".</dd>
 *                   <dt>W:PS</dt><dd>Limits search to strict word prefix.  For example,
 *                   searching for "pre" matches "prefix" but not "pre",
 *                   "supreme" or "supre".</dd>
 *                   <dt>W:S</dt><dd>Limits search to word suffix.  For example,
 *                   searching for "fix" matches "fix" and "sufix" but
 *                   not "fixit".</dd>
 *                   <dt>W:SS</dt><dd>Limits search to strict word suffix.  For example,
 *                   searching for "fix" matches "sufix" but not "fix" or
 *                   "fixit".</dd>
 *                   <dt>Y</dt><dd>Binary search.  This allows start positions in the
 *                   middle of a DBCS or UTF-8 character.  This option
 *                   is useful when editing binary files (in SBCS/DBCS
 *                   mode) which may contain characters which look
 *                   like DBCS but are not.  For example, if you search
 *                   for the character 'a', it will not be found as the
 *                   second character of a DBCS sequence unless this
 *                   option is specified.</dd>
 *                   <dt>','</dt><dd>Delimiter to separate ambiguous options.
 *                   <dt>'&'</dt><dd>Interpret string as wildcard syntax (*,?) for searches.
 *                   <dt>'#'</dt><dd>Highlight matched occurances with highlight color.
 *                   <dt>'%'</dt><dd>Add scroll markup for matches.
 *                   <dt>'$'</dt><dd>Highlight replaced text with modified line color.
 *                   <dt>'X<i>CCLetters</i>'</dt><dd>
 *                   Requires the first character of search string
 *                   NOT be one of the color coding elements specified.
 *                   For example, "XCS" requires that the first character
 *                   not be in a comment or string. <i>CCLetters</i> is
 *                   a string of one or more of the following color
 *                   coding element letters:
 *
 *                   <dl compact style="margin-left:20pt">
 *                   <dt>O</dt><dd>Other
 *                   <dt>K</dt><dd>Keyword
 *                   <dt>N</dt><dd>Number
 *                   <dt>S</dt><dd>String
 *                   <dt>C</dt><dd>Comment
 *                   <dt>P</dt><dd>Preprocessing
 *                   <dt>L</dt><dd>Line number
 *                   <dt>1</dt><dd>Symbol 1
 *                   <dt>2</dt><dd>Symbol 2
 *                   <dt>3</dt><dd>Symbol 3
 *                   <dt>4</dt><dd>Symbol 4
 *                   <dt>F</dt><dd>Function color
 *                   <dt>V</dt><dd>No save line
 *                   </dl></dd>
 *
 *                   <dt>'C<i>CCLetters</i>'</dt><dd>Requires the first character of search string to
 *                   be one of the color coding elements specified. See
 *                   <i>CCLetters</i> above.</dd>
 *                   </dl>
 * @param replaceString   Optional string to replace search string with.
 * @param Nofchanges      Count of number of replaces.
 *
 * @return Returns 0 if the search specified is found.  Common return codes are
 *         STRING_NOT_FOUND_RC, INVALID_OPTION_RC, and
 *         INVALID_REGULAR_EXPRESSION_RC.  On error, message is
 *         displayed.
 * @example
 * <pre>
 * // Search and replace without prompting.
 * search( 'pathsearch', '*', 'path_search', Nofchanges);
 * messageNwait(Nofchanges' changes');
 * // Search and replace without prompting within the marked area.
 * search('pathsearch', '*M', 'path_search');
 * </pre>
 *
 * @see qreplace
 * @see repeat_search
 * @see _select_match
 * @see match_length
 * @see search_replace
 * @see save_search
 * @see restore_search
 * @see _search_case
 * @see _SearchInitSkipped
 * @see _SearchQSkipped
 * @see _SearchQNofSkipped
 */
int search(_str searchString,_str options="E",_str replaceString=null,int &Nofchanges=0);
int replace(_str string1, _str string2, _str options='E');


/**
 * @return Returns the length or buffer position of the string found by the
 * last <b>search</b> or <b>repeat_search</b> executed.  If the 'C' parameter is
 * given, the number of characters from the beginning of the match to the cursor
 * is returned.
 *
 * <p>The ['S'][0-9] parameter is used to return a match length or a start
 * buffer position of a tagged expression.  Specifying 'S' followed by a tagged
 * expression number 0-9 (i.e. 'S0') will return the start buffer position of
 * that tagged expression.  The start buffer position is a seek position or
 * point which may be used as input to the <b>goto_point</b> and <b>get_text</b>
 * built-ins.  An undefined start buffer position is returned if that tagged
 * expression was not found.  If 'S' is not followed by a number, the start
 * position of the entire string found is returned.  Specifying a tagged
 * expression number 0-9 will return the match length of that group.  0 is
 * returned if that tagged expression was not found.</p>
 *
 * @example
 * <pre>
 *         // This example works for files with tab characters.
 *         status=search('{if|then|while}','rew');
 *         if (status) {
 *              message('Match not found');
 *              return(status);
 *         }
 *         // In this case, match_length('S')==match_length('S0');
 *         // and match_length()==match_length('0');
 *         word=get_text(match_length('0'),match_length('S0'))
 * </pre>
 *
 * @see _select_match
 * @see search
 * @see repeat_search
 * @see search_replace
 * @see save_search
 * @see restore_search
 * @see _search_case
 *
 * @categories Search_Functions
 *
 */
int match_length(_str option="");

/**
 *
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * @param count    Specifies the number of bytes to get.  The following negative
 *                 numbers have special meaning:
 *                 <dl compact style="margin-left:20pt">
 *                 <dt>-1<dd>Get current unicode character or DBCS character
 *                 <dt>-2<dd>Get composite character or DBCS character
 *                 </dl>
 * @param seek_pos  Specifies the byte offset in the file to get the bytes from.
 *                  -3 specifies the cursor position.
 *
 * @return Returns <i>count</i> characters from current buffer starting from
 *         <i>seek_pos.</i>  <b>get_text</b> is a stream-oriented function which for
 *         ASCII buffers will return line separation characters.  Use the
 *         <b>get_text</b> function to retrieve strings found by a regular expression
 *         search.  <i>count</i> defaults to 1 if not specified.  <i>seek_pos</i>
 *         defaults to the physical character at the cursor position or the first
 *         physical character to the left of the cursor.
 * @example
 * <pre>
 *         // This example works for files with tab characters.
 *         status=search('{if|then|while}','rew');
 *         if (status) {
 *              message('Match not found');
 *              return(status);
 *         }
 *         word=get_text(match_length('0'),match_length('S0'))
 * </pre>
 */
_str get_text(int count=1,int seek_pos=-3);
/**
 * This function is identical to the <b>{@link get_text}</b> function,
 * except that the resulting string is always in the same format as 
 * the internal buffer data which can be SBCS/DBCS or UTF-8.  See 
 * <b>"Unicode and SBCS/DBCS Macro Programming."</b> 
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_str get_text_raw(int count=1,int seek_pos=-3);
/**
 * This function is identical to the <b>{@link get_text}</b> function,
 * except that it safely handles the case where you try to get text 
 * which is past the end of the buffer, even if the buffer does not 
 * end with a newline character. 
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_str get_text_safe(int count=1,int seek_pos=-3);

/**
 * Deteremine if the cursor is past the end of the current line 
 *  
 * @param moveToEndIfPast If true and cursor is past end of line, 
 *                        move cursor to the end of line
 *  
 * @return true if the cursor is past the end of the current line 
 *  
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
boolean past_end_of_line(boolean moveToEndIfPast = false);


_str GetRText(int count,int seek_pos=-3);
_str GetRTextRaw(int count,int seek_pos=-3);
/**
 * Inserts line into editor buffer after the current line.
 *
 * @param line   String to insert.  <i>line</i> should not contain newline characters since
 *               the appropriate newline characters are appended.
 *
 * @example <pre>
 * insert_line("add line after current line");
 * </pre>
 *
 * @see get_line
 * @see replace_line
 * @see delete_line
 * @see get_text
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
void insert_line(_str line);
/**
 * This function is identical to the <b>insert_line</b> function, except that
 * the input string is in the same format as the internal buffer data which can
 * be SBCS/DBCS or UTF-8.  See "<b>Unicode and SBCS/DBCS Macro Programming</b>".
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
void insert_line_raw(_str line);
/**
 * Places the current line of the current buffer into the variable
 * <i>line</i>.
 *
 * @see insert_line
 * @see replace_line
 * @see _delete_line
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
void get_line(_str &line);
/**
 * This function is identical to the <b>get_line</b> function, except that
 * the resulting string is always in the same format as the internal buffer data
 * which can be SBCS/DBCS or UTF-8.  See "Unicode and SBCS/DBCS Macro
 * Programming."
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
void get_line_raw(_str &line);


/**
 * Deletes current line.
 *
 * @see cut_line
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
void _delete_line();
/**
 * Sets the current line of the current buffer to line.
 *
 * @see get_line
 * @see insert_line
 * @see _delete_line
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
void replace_line(_str line);
/**
 * This function is identical to the <b>replace_line</b> function, except
 * that the input string  is in the same format as the internal buffer data
 * which can be SBCS/DBCS or UTF-8.  See "<b>Unicode and
 * SBCS/DBCS Macro Programming</b>".
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
void replace_line_raw(_str line);

/**
 * Inserts a file list of the files specified with columns for size, date,
 * time, attributes, and name.
 *
 * @param cmdline has the following syntax:
 * <pre>
 *      {<i>filespec</i>  | ['-' | '+' option_letters] [-exclude exfiles]}
 * </pre>
 *
 * @param option_letters may be 'H','S','A','D','P','T','V' with the
 * following meanings:
 *
 * <dl>
 * <dt>H</dt><dd>Include hidden files (defaults to OFF)<br>
 * This option is always turned on under Windows if the "Show all
 * files" explorer option is set.  On UNIX, this option is
 * ignored.</dd>
 * <dt>S</dt><dd>Include system files (defaults to OFF)<br> This
 * option is always turned on under Windows if the "Show all
 * files" explorer option is set.</dd>
 * <dt>A</dt><dd>Include archive files (defaults to OFF)</dd>
 * <dt>D</dt><dd>Include directory files (default to OFF)</dd>
 * <dt>P</dt><dd>Append path (defaults to OFF)</dd>
 * <dt>T</dt><dd>Tree file list (defaults to OFF)</dd>
 * <dt>U</dt><dd>UNIX dot files (defaults to ON)</dd>
 * <dt>V</dt><dd>Verbose output with size, date, attributes.  (defaults to ON)</dd>
 * <dt>G</dt><dd>List registered data sets.  This option is ignored for all platforms
 * except OS/390.</dd>
 * <dt>N </dt><dd>Stat of data sets.  By default, no trailing slash is appended to
 * partitioned data sets (directories).  We have this default mainly due to the
 * fact that this feature can cause a hang.  Use this option when you have to
 * differentiate files from directories.  This option is ignored for all
 * platforms except OS/390.</dd>
 * <dt>Z</dt><dd>Return data set member info in the same format as ISPF. This option is
 * ignored for all platforms except OS/390.</dd>
 * </dl>
 *
 * @param filespec may contain operating system wild cards such as '*'
 * and '?'.  If <i>filespec</i> is not specified, current directory is used.
 *
 * @param exfiles may contain operating system wild cards such as '*'
 * and '?'.  Specifying a directory will exclude a named directory and contained subdirectories
 *
 * @return Returns 0 if successful.  Common return codes are:
 * <ul>
 * <li>FILE_NOT_FOUND_RC</li>
 * <li>PATH_NOT_FOUND_RC</li>
 * <li>NO_MORE_FILES_RC</li>
 * <li>ACCESS_DENIED_RC</li>
 * </ul>
 *
 * @example
 * <pre>
 * insert_file_list('\*.*");  // List just root directory with directories.
 * insert_file_list('+tp \*.*"); // List all files.  Append paths.
 * insert_file_list('-v *.*');   // List files in current directory.  Just
 * file names.
 * insert_file_list('+tp \*.* -exclude *\CVS\'); //List all file, append paths, excluding "CVS" subdirectories
 * insert_file_list('+tp \*.* -exclude *.txt'); //List all files, append paths, excluding .txt files
 * </pre>
 *
 * @appliesTo Edit_Window, Editor_Control, List_Box
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, File_Functions, List_Box_Methods
 *
 */
int insert_file_list(_str cmdline);
/**
 * Toggles insert mode on/off.  Normally the cursor shape is smaller when in
 * insert mode.  When in insert mode, characters are inserted at the cursor
 * position.  When in over-write mode, the characters at the cursor position are
 * replaced.
 *
 * @example
 * <pre>
 *          // set insert mode on.
 *          if (!_insert_state()) _insert_toggle();
 *          keyin('insert these characters into the command line');
 * </pre>
 *
 * @see _insert_state
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 *
 */
void _insert_toggle();
/**
 * Each text box has its own insert state.  However, all edit windows and
 * editor controls share the same insert state.
 *
 * @return When no parameters specified, returns '1' if insert mode on.
 * Otherwise '0' is returned.
 *
 * <p>When <i>newValue</i> parameter is not "", the insert state is set to
 * <i>newValue</i>.  <i>newValue </i>must be an integer.</p>
 *
 * <p>Specify "D" for <i>set_default</i> to set the initial insert state used
 * when the editor is invoked.  The current insert state is not changed.  The
 * current initial insert state is returned.  Specify "" for <i>newValue</i> and
 * "D' for <i>set_default</i> to get the current initial insert state.</p>
 *
 * @example
 * <pre>
 *          // Make the active object the command line
 *          p_window_id=_cmdline;
 *          // set insert mode on.
 *          _insert_state(1);
 *          keyin('insert these characters into the command line');
 * </pre>
 *
 * @see _insert_toggle
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 *
 */
void _insert_state(_str mode="",_str set_default="");


/**
 * This function returns information about the process running depending
 * upon the input given as follows:
 *
 * <dl>
 * <dt>""</dt><dd>Returns 1 if the build window
 * (concurrent process buffer) is running.
 * Otherwise 0.</dd>
 * <dt>'C'</dt><dd>Returns start column of process request for input.
 * If the current line is not reading input for a
 * concurrent process, 0 is returned.</dd>
 * <dt>'B'</dt><dd>Returns 1 if the current buffer has the build window.
 * Otherwise 0 is returned.</dd>
 * <dt>'R'</dt><dd>Returns 1 if the build window is running.
 * Otherwise 0 is returned.  A delay is performed and
 * pending build window output is read into the
 * build window.</dd>
 * <dt>'X'</dt><dd>Returns 1 if the command shell running in
 * the build window has exited.
 * Otherwise 0 is returned.  A delay is performed and
 * pending build window output is read into the
 * build window.</dd>
 * </dl>
 *
 * @see concur_shell
 * @see _stop_process
 *
 * @categories Miscellaneous_Functions
 *
 */
int _process_info(_str option="");


/**
 * Remarks <i>column</i> does not have a default value.
 * The third parameter defaults to 'L'.
 *
 * <p>Converts an imaginary column position to a physical string column
 * position and visa versa.  The input and output values are described by
 * the table below:</p>
 *
 * <dl>
 * <dt>Third param.</dt><dd>Input column, Output column</dd>
 * <dt>'P'</dt><dd>Imaginary, Physical</dd>
 * <dt>'T'</dt><dd>Imaginary, Physical.  Position is negated if the
 * imaginary column input corresponds to the middle
 * of a tab character.</dd>
 * <dt>'L'</dt><dd>Doesn't matter, imaginary length of string.</dd>
 * <dt>'I'</dt><dd>Physical, Imaginary</dd>
 * </dl>
 *
 * <p>The input column is returned if input column is less than or equal to
 * zero and the third parameter is not 'L'.</p>
 *
 * <p>We use the term imaginary to describe column positions which
 * correspond to a string as displayed on your screen.  Strings containing
 * tab characters are expanded before displayed.  Hence, the need arises
 * for a differentiation between physical and imaginary positions.  A
 * physical position corresponds to a character in string.  The characters
 * are number one to the length of string.  An imaginary position
 * corresponds to a position in a string once tabs have been expanded.</p>
 *
 * @example  (Assume tabs are 1 9 17 25 ... (increments of 8))<br>
 * <pre>
 * text_col('abc'\t'def'\t'ghi') == 19
 * text_col('abc'\t'def'\t'ghi',12,'P')   == 8
 * text_col('abc'\t'def'\t'ghi',13,'P')   == 8
 * text_col('abc'\t'def'\t'ghi',12,'T')   == 8
 * text_col('abc'\t'def'\t'ghi',13,'T')   == -8
 * text_col('abc'\t'def'\t'ghi',8,'I') == 12
 * text_col('abc'\t'def'\t'ghi',-1,'P')   == -1
 * text_col('abc'\t'def'\t'ghi',0,'P') == 0
 * text_col('abc'\t'def'\t'ghi',0,'I') == 0
 * </pre>
 *
 * @see expand_tabs
 * @see _expand_tabsc
 * @see _text_colc
 * @see _expand_tabsc_raw
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, String_Functions
 *
 */
int text_col(_str string,int column=0,_str option="L");


/**
 * Returns a sub-string of input <i>string</i> containing tab
 * characters.  The <i>start</i> and <i>count</i> specification correspond to
 * the input string as if tab characters were expanded according to the
 * current buffers tab settings.  We call this type of text position or count
 * imaginary.  Strings containing tab characters are expanded before displayed.
 * Hence, the need arises for a differentiation between physical and imaginary
 * positions.  A physical position corresponds to a character in string.  The
 * characters are numbered one to the length of string.  An imaginary position
 * corresponds to a position in a string once tabs have been expanded.
 * <p>
 * By default, the tab characters in string specified by <i>start</i> and
 * <i>count</i> are expanded to spaces according to the current buffer's tab
 * settings.  Specify 'S' for <i>option</i> if you only want to expand tabs to
 * spaces when a tab character is bisected.  If <i>count</i> extends past the
 * imaginary length of string, the result is padded with blank characters.  A
 * <i>count</i> of -1 specifies the rest of the input string starting from the
 * imaginary column <i>start</i>.  The <i>start</i> parameter must be greater
 * than zero.
 * @example
 * <pre>
 * (Assume tabs are  1 9 17 25 33 41 ... (increments of 8))
 *
 *          expand_tabs("abc\tdef\tghi")
 *                :=="abc"FIVE_SPACES"def":+FIVE_SPACES:+"ghi"
 *          expand_tabs("abc\tdef\tghi",4)
 *                :== FIVE_SPACES"def":+FIVE_SPACES"ghi"
 *          expand_tabs("abc\tdef\tghi",1,-1,"S") :== "abc\tdef\tghi"
 *          expand_tabs("abc\tdef\tghi",4,-1,"S") :== "\tdef\tghi"
 *          expand_tabs("abc\tdef\tghi",5,-1,"S") :== FOUR_SPACES"def\tghi"
 *          expand_tabs("abc\tdef\tghi",5,10,"S")
 *                :== FOUR_SPACES"def":+THREE_SPACES
 * </pre>
 * @see _text_colc
 * @see text_col
 * @see _expand_tabsc
 * @see _expand_tabsc_raw
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods, String_Functions
 */
_str expand_tabs(_str string,int start=1,int count=-1,_str option='E');
/**
 * Sets the left edge scroll position and the cursor y position for viewing
 * the current line.  The current line is unchanged.  <i>left_edge</i> and
 * <i>cursor_y</i> are in pixels.  The <b>p_cursor_y</b> property may
 * also set the cursor y position. However, the current line will not
 * remain the same.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
_str set_scroll_pos(int left_edge,int cursor_y);

/**
 * Determines whether a block was read from a file.  o set the current value, specify
 * the <i>number</i> argument.  The purpose of this function is to allow macros to flush
 * the keyboard buffer when the editor is not keeping up with the key strokes.
 *
 * @appliesTo Edit_Window, Editor_Control
 * @param newValue
 *
 * @return Returns a non-zero number if the editor has read a block from a file.  Otherwise zero is returned.  T
 * @example
 * <pre>
 *  // This macro allows the user to hold a key down which
 *  // invokes this macro repeatedly to scroll down a file which is
 *  // only partially loaded.  No sudden screen jumps will occur.
 *  if (block_was_read() ) {
 *      block_was_read(0);
 *      flush_keyboard();
 *  }
 *  down();
 * </pre>
 * @categories Edit_Window_Methods, Editor_Control_Methods, File_Functions
 */
int block_was_read(int newValue=-1);
/**
 * @return Returns the text position of the beginning of the current line or the
 * current line number.
 *
 * <p>When invoked with no parameters the text position of the beginning of
 * the current line is returned.  If the length of the current line is 0, the
 * <b>point</b> function returns the seek position of the first previous
 * non-blank line concatenated to a down scroll amount.  Otherwise, the
 * seek position of the beginning of line is returned.  0 length lines are
 * only possible for buffers edited in SlickEdit's binary width
 * mode.  Lines of ASCII buffers always terminate with one or more line
 * separation characters.</p>
 *
 * <p>Specify 'L' for <i>option</i> to get the current line number.  Unlike
 * the <b>p_line</b> property which determines the current line number
 * when it is not known, a line number of -1 is returned to indicate that the
 * line number is not known.</p>
 *
 * <p>IMPORTANT:  This function includes lines with NOSAVE_LF set
 * which means that these file offsets and line numbers will not match
 * what is on disk if the file has non-savable lines.  Use
 * <b>_GoToROffset</b>, <b>_QROffset</b>, <b>p_RLine</b>, and
 * <b>p_RNoflines</b> for dealing with disk seek positions and line
 * numbers.</p>
 *
 * @example
 * <pre>
 *         parse point() with seek_pos down_scroll;
 *         message('seek_pos='seek_pos'  down_scroll='down_scroll);
 * </pre>
 *
 * @see goto_point
 * @see _QROffset
 * @see _GoToROffset
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
typeless point(_str option="P");
/**
 * <p>Moves the current buffer location to text position specified.
 * <i>text_pos</i> may either be a seek position to any byte in the current
 * buffer or a text line position which is specified with a seek position to the
 * beginning of a line followed by a count of the number of lines to scroll
 * down.  If <i>line_number</i> is specified, the current line number is set to
 * line_number.  The built-in function <b>point</b> may be used to return the
 * text line position (not necessarily the seek position for a record file) of
 * the beginning of the current line.  The current line number may also be
 * retrieved by the built-in function <b>point</b>.</p>
 *
 * <p>IMPORTANT:  This function includes lines with NOSAVE_LF set which means
 * that these file offsets will not match what is on disk if the file has non-
 * savable lines.  Use <b>_GoToROffset</b>, <b>_QROffset</b>, <b>p_RLine</b>,
 * and <b>p_RNoflines</b> for dealing with disk seek positions and line numbers.</p>
 *
 * <p>If a file offset is given, it can not be past the end of the file.
 * Negative file offsets are possible due to SlickEdit's implementation
 * of line 0.</p>
 *
 * @return Returns 0 if successful.  Otherwise INVALID_POINT_RC is returned.
 *
 * @example
 * <pre>
 *         // Get seek position to the beginning of the current line
 *         text_pos=point();line_number=point('L');
 *         down(4);
 *         goto_point(text_pos,line_number);
 * </pre>
 *
 * @see point
 * @see seek
 * @see gui_seek
 * @see _nrseek
 * @see _GoToROffset
 * @see _QROffset
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
int goto_point(_str text_pos,int linenum=-1);


/**
 * Writes current buffer to file name specified.  If no name is specified,
 * the buffer name is used.
 *
 * @return Returns 0 if successful.  Common return codes are:
 * INVALID_OPTION_RC, ACCESS_DENIED_RC,
 * ERROR_OPENING_FILE_RC, INSUFFICIENT_DISK_SPACE_RC,
 * ERROR_READING_FILE_RC, ERROR_WRITING_FILE_RC,
 * DRIVE_NOT_READY_RC, and PATH_NOT_FOUND_RC. On
 * error, message displayed.
 *
 * @param pszCmdLine may contain an output filename in double quotes and
 * any of the following switches delimited with a space:
 *
 * <p>(Note that since record files are saved in binary [always with the +B
 * switch], many options have no effect.)</p>
 *
 * <dl>
 * <dt>+ or -E</dt><dd>Turn on/off expand tabs to spaces switch.
 * Default is off.</dd>
 *
 * <dt>+ or -G</dt><dd>Turn on/off setting of all old numbers.
 * Default is off.  SlickEdit uses old line
 * numbers to better handle going to an error
 * line after lines have been inserted or deleted.
 * We don't recommend setting the old line
 * numbers on every save because this requires
 * that you do not save the file until you have
 * performed edits for all compile or multi-file
 * search messages.  See
 * <b>_SetAllOldLineNumbers</b> method for
 * more information.</dd>
 *
 * <dt>+ or -S</dt><dd>Strip trailing spaces on each line.  The buffer
 * is modified if the output file name matches
 * the buffer name.  Default is off.</dd>
 *
 * <dt>+ or -CL</dt><dd>Check maximum line length.  Default is off.
 * If the destination file requires a record length (an OS/390
 * data set member), lines are checked against this record 
 * length. Otherwise, line lengths are checked against 
 * the <b>p_MaxLineLength</b> property.  If there are any lines 
 * that are too long, an error code is returned and a message 
 * box is displayed with a list of the offending line numbers. 
 * At the moment only the physical line length is checked as if 
 * tab characters count as 1 character.  We may change this in 
 * the future.</dd>
 *
 * <dt>+FU</dt><dd>Save file in UNIX ASCII format (Lines
 * ending with just 10 character).  The buffer is
 * modified if the output file name matches the
 * buffer name.</dd>
 *
 * <dt>+FD</dt><dd>Save file in DOS  ASCII format (Lines
 * ending with 13,10).  The buffer is modified if
 * the output file name matches the buffer name.</dd>
 *
 * <dt>+FM</dt><dd>Save file in Macintosh ASCII format (Lines
 * ending with just 13 character).  The buffer is
 * modified if the output file name matches the
 * buffer name.</dd>
 *
 * <dt>+<i>ddd</i></dt><dd>Save file without line end characters and pad
 * or truncate lines so that each line is
 * <i>ddd</i> characters in length.  Use this
 * option to generate of fixed length record file.</dd>
 *
 * <dt>+FR</dt><dd>Save file without line end characters.</dd>
 *
 * <dt>+F<i>ddd</i></dt><dd>Save file using ASCII character <i>ddd</i>
 * as the line end character.  The buffer is
 * modified if the output file name matches the
 * buffer name.  This option is not supported for
 * UTF-8 buffers.</dd>
 *
 * <dt>+FTEXT</dt><dd>Saves file as SBCS/DBCS and converts
 * buffer data to SBCS/DBCS if necessary.  This
 * option is ignored if <b>p_binary</b>==true
 * or +B option specified.</dd>
 *
 * <dt>+FUTF8</dt><dd>Saves file as UTF-8 without a signature and
 * converts the buffer data to UTF-8 if
 * necessary.  This option is ignored if
 * <b>p_binary</b>==true or +B option
 * specified.</dd>
 *
 * <dt>+FUTF8S</dt><dd>Saves file as UTF-8 with a signature and
 * converts the buffer data to UTF-8 if
 * necessary.  This option is ignored if
 * <b>p_binary</b>==true or +B option
 * specified.</dd>
 *
 * <dt>+FUTF16LE</dt><dd>Saves file as UTF-16 little endian without a
 * signature and converts the buffer data to
 * UTF-8 if necessary.  This option is ignored if
 * <b>p_binary</b>==true or +B option
 * specified.</dd>
 *
 * <dt>+FUTF16LES</dt><dd>Saves file as UTF-16 little endian with a
 * signature and converts the buffer data to
 * UTF-8 if necessary.  This option is ignored if
 * <b>p_binary</b>==true or +B option
 * specified.</dd>
 *
 * <dt>+FUTF16BE</dt><dd>Saves file as UTF-16 big endian without a
 * signature and converts the buffer data to
 * UTF-8 if necessary.  This option is ignored if
 * <b>p_binary</b>==true or +B option
 * specified.</dd>
 *
 * <dt>+FUTF16BES</dt><dd>Saves file as UTF-16 big endian with a
 * signature and converts the buffer data to
 * UTF-8 if necessary.  This option is ignored if
 * <b>p_binary</b>==true or +B option
 * specified.</dd>
 *
 * <dt>+FUTF32LE</dt><dd>Saves file as UTF-32 little endian without a
 * signature and converts the buffer data to
 * UTF-8 if necessary.  This option is ignored if
 * <b>p_binary</b>==true or +B option
 * specified.</dd>
 *
 * <dt>+FUTF32LES</dt><dd>Saves file as UTF-32 little endian with a
 * signature and converts the buffer data to
 * UTF-8 if necessary.  This option is ignored if
 * <b>p_binary</b>==true or +B option
 * specified.</dd>
 *
 * <dt>+FUTF32BE</dt><dd>Saves file as UTF-32 big endian without a
 * signature and converts the buffer data to
 * UTF-8 if necessary.  This option is ignored if
 * <b>p_binary</b>==true or +B option
 * specified.</dd>
 *
 * <dt>+FUTF32BES</dt><dd>Saves file as UTF-32 big endian with a
 * signature and converts the buffer data to
 * UTF-8 if necessary.  This option is ignored if
 * <b>p_binary</b>==true or +B option
 * specified.</dd>
 *
 * <dt>+FCP<i>ddd</i></dt><dd>Saves file as SBCS/DBCS for the code page
 * file specified by <i>ddd</i> and converts the
 * buffer data to UTF-8 if necessary.  This
 * option is ignored if <b>p_binary</b>==true
 * or +B option specified.  Under windows, this
 * can be any valid code page or one of the
 * VSCP_* constants defined in "slick.sh."</dd>
 *
 * <dt>+FACP</dt><dd>Saves file as SBCS/DBCS for the active code
 * page and converts the buffer data to UTF-8 if
 * necessary.  This option is ignored if
 * <b>p_binary</b>==true or +B option
 * specified.  Under windows, this can be any
 * valid code page or one of the VSCP_*
 * constants defined in "slick.sh."</dd>
 *
 * <dt>+ or -B</dt><dd>Binary switch.  Save file exactly byte per byte
 * as it appears in the buffer.  This option
 * overrides all save options which effect bytes
 * in the input or output.  This option is always
 * on for record buffers.  Defaults to value of
 * <b>p_binary</b> property for other buffers.</dd>
 *
 * <dt>+ or -O</dt><dd>Overwrite destination switch (no backup).
 * Default is off.  Useful for writing a file to a
 * device such as the printer.</dd>
 *
 * <dt>+ or -P</dt><dd>Add saved file to current project.
 * Default is off.</dd>
 *
 * <dt>+ or -T</dt><dd>Compress saved file with tab increments of 8.
 * Default is off.</dd>
 *
 * <dt>+ or -ZR</dt><dd>Remove end of file marker (Ctrl+Z).  This
 * option is ignored if the current buffer is not a
 * DOS ASCII file.  The buffer is modified if
 * the <b>p_showeof</b> is true and the output
 * file name matches the buffer name.  Default is
 * off.</dd>
 *
 * <dt>+ or -Z</dt><dd>Add end of file marker (Ctrl+Z).  Note that if
 * a buffer has a visible EOF character, the
 * output file will still have an EOF character.
 * Use +ZR to ensure that the output file does
 * not have and EOF character.  Default is off.</dd>
 *
 * <dt>+ or -L</dt><dd>Reset line modify flags.  Default is off.</dd>
 *
 * <dt>+ or -N</dt><dd>Don't save lines with the NOSAVE_LF bit
 * set.  When the editor keeps track of whether a
 * buffer has lines with the NOSAVE_LF bit set,
 * we will not need this option.</dd>
 *
 * <dt>+ or -A</dt><dd>Convert destination filename to absolute.
 * Default is on.  This option is currently used to
 * write files to device names such as PRN.  For
 * example, "_save_file +o -a +e prn" sends the
 * current buffer to the printer.</dd>
 *
 * <dt>+DB, -DB, +D,-D,+DK,-DK</dt><dd>
 *    These options specify the backup style.  The
 * default backup style is +D.  The backup styles
 * are:</dd>
 *
 * <dl>
 * <dt>+DB, -DB</dt><dd>Write backup files into the same directory as
 * the destination file but change extension to
 * ".bak".</dd>
 *
 * <dt>+D</dt><dd>When on, backup files are placed in a single
 * directory.  The default backup directory is
 * "\vslick\backup\" (UNIX:
 * "$HOME/.vslick/backup") . You may define
 * an alternate backup directory by defining an
 * environment variable called
 * VSLICKBACKUP.  The VSLICKBACKUP
 * environment variable may contain a drive
 * specifier. The backup file gets the same name
 * part as the destination file.  For example,
 * given the destination file "c:\project\test.c"
 * (UNIX: "/project/test.c") , the backup  file
 * will be "c:\vslick\backup\test.c" (UNIX:
 * "$HOME/.vslick/backup/test.c").<br><br>
 *
 * <b>Non-UNIX platforms</b>: For a network,
 * you may need to create the backup directory
 * with appropriate access rights manually
 * before saving a file.</dd>
 *
 * <dt>-D</dt><dd>When on, backup file directories are derived
 * from concatenating a backup directory with
 * the path and name of the destination file.  The
 * default backup directory is "\vslick\backup\"
 * (UNIX: "$HOME/.vslick").  You may define
 * an alternate backup directory by defining an
 * environment variable called
 * VSLICKBACKUP.  The VSLICKBACKUP
 * environment variable may contain a drive
 * specifier.  For example, given the destination
 * file "c:\project\test.c", the backup file will be
 * "c:\vslick\backup\project\test.c" (UNIX:
 * "$HOME/.vslick/backup/project/test.c").<br><br>
 *
 * <b>Non-UNIX platforms</b>: For a network, you
 * may need to create the backup directory with
 * appropriate access rights manually before
 * saving a file.</dd>
 *
 * <dt>+DK,-DK</dt><dd>When on, backup files are placed in a
 * directory off the same directory as the
 * destination file.  For example, given the
 * destination file "c:\project\test.c" (UNIX:
 * "$HOME/.vslick"), the backup file will be
 * "c:\project\backup\test.c" (UNIX:
 * "/project/backup/test.c").  This option works
 * well on networks.</dd>
 * </dl>
 * </dl>
 *
 * <p>The <b>p_modify</b> property is turned off if the output filename is
 * the same as the current file name.</p>
 *
 * @example
 * <pre>
 *          // Save the current file.
 *          _save_file();
 *          // Write current file to printer.  Compress file with tabs.
 *          _save_file('+o -a +e prn');
 * </pre>
 *
 * @appliesTo Edit_Window
 *
 * @categories File_Functions
 *
 */
int _save_file(_str cmdline="");

/**
 * For an explanation of how windows, views, and buffers are related, see
 * section "Windows Structure."
 *
 * @param options  <i>options</i> may contain one file or buffer name and the following options:
 *
 * <dl>
 * <dt><i>FileOrBufferName</i></dt><dd>Find the buffer specified or load the file</dd>
 *
 * <dt>+ or -L[C|Z]</dt><dd>Turn on/off load entire file switch.  The optional C suffix
 * count the number of lines in the file.  The Z suffix counts the number of
 * lines in the file and truncates the file if an EOF character is found in the
 * middle of the file.</dd>
 *
 * <dt>+ or -LF   +LF</dt><dd>Turns off loading entire file and turns on fast line count.
 * This is the fastest way for SlickEdit to count the number of lines in
 * a file.  -LF turns off fast line counting.</dd>
 *
 * <dt>+ or -LB</dt><dd>SBCS/DBCS mode. Turns on/off binary loading.  Sets initial value
 * of <b>p_binary</b> property.  All edit/save options which performed
 * translations are ignored.   For example, tab expansion or tab compression
 * options are ignored.  This allows "safe" editing of binary files even when
 * edit/save file translation are on.</dd>
 *
 * <dt>+ or -LE</dt><dd>Turns on/off show EOF option.  Sets initial value of
 * <b>p_showeof</b> property.  When on, EOF characters at the end of DOS files
 * are not stripped.  This option is not supported when the +LZ option is given.</dd>
 *
 * <dt>+ or -LN</dt><dd>Turns on/off show new line characters option.  When on, new line
 * characters are initially visible.</dd>
 *
 * <dt>+ or -BP</dt><dd>Turn on/off reinsert selected buffer/window after current
 * buffer/window.  Wonderful option!  Helps <b>prev_buffer</b> and
 * <b>prev_window</b> commands to switch previously active file or window.</dd>
 *
 * <dt>+ or -S</dt><dd>Turn on/off unmodified block swapping to spill file.  Default is
 * off.</dd>
 *
 * <dt>+<i>nnn</i></dt><dd>Load binary file(s) that follow in record width <i>nnn</i>.</dd>
 *
 * <dt>+T[I] [<i>buf_name</i>]</dt><dd>Start a default operating system format temp buffer
 * with name <i>buf_name</i>. +TI indicates that <i>buf_name</i> is an internal name and
 * should not be converted to absolute. </dd>
 *
 * <dt>+T[I]U [<i>buf_name</i>]</dt><dd>Start a UNIX format temp buffer with name
 * <i>buf_name</i>. +TIU indicates that <i>buf_name</i> is an internal name and
 * should not be converted to absolute. </dd>
 *
 * <dt>+T[I]M [<i>buf_name</i>]</dt><dd>Start a MACINTOSH format temp buffer with name
 * <i>buf_name</i>. +TIM indicates that <i>buf_name</i> is an internal name and
 * should not be converted to absolute. </dd>
 *
 * <dt>+T[I]D [<i>buf_name</i>]</dt><dd>Start a DOS format temp buffer with name
 * <i>buf_name</i>. +TID indicates that <i>buf_name</i> is an internal name and
 * should not be converted to absolute. </dd>
 *
 * <dt>+T[I]<i>nnn</i></dt><dd>Start a temp buffer where <i>nnn</i> is the decimal value
 * of the character to be used as the line separator character. +TInnn indicates that <i>buf_name</i> is an internal name and
 * should not be converted to absolute. </dd>
 *
 * <dt>+FU [<i>buf_name</i>]</dt><dd>Force SlickEdit to interpret a file in
 * UNIX format.</dd>
 *
 * <dt>+FM [<i>buf_name</i>]</dt><dd>Force SlickEdit to interpret a file in
 * MAC format.</dd>
 *
 * <dt>+FD [<i>buf_name</i>]</dt><dd>Force SlickEdit to interpret a file in
 * DOS format.</dd>
 *
 * <dt>+F<i>nnn</i></dt><dd>SBCS/DBCS mode.  Force SlickEdit to use <i>nnn</i>
 * as the decimal value of the line separator character.</dd>
 *
 * <dt>+FENDDEFAULTS</dt><dd>When an editing mode switch is such as "+FTEXT" or
 * "+FUTF8" is specified, the value for the <b>p_encoding_set_by_user</b>
 * property is set.  When this option is specified,
 * <b>p_encoding_set_by_user</b> is set to -1.  This option made implementing
 * the <b>p_encoding_set_by_user</b> property easier.</dd>
 *
 * <dt>+FTEXT</dt><dd>SBCS/DBCS mode.  Open SBCS/DBCS file.  This is the default mode
 * when no mode (either SBCS/DBCS or Unicode) is specified.</dd>
 *
 * <dt>+FEBCDIC</dt><dd>SBCS/DBCS mode.  Open EBCDIC file.</dd>
 *
 * <dt>+FUTF8</dt><dd>Unicode mode.  Open UTF-8 file with or without signature.</dd>
 *
 * <dt>+FUTF8S</dt><dd>Unicode mode.  Open UTF-8 file with or without signature.</dd>
 *
 * <dt>+FUTF16LE</dt><dd>Unicode mode.  Open UTF-16 little endian file with or
 * without signature.</dd>
 *
 * <dt>+FUTF16LES</dt><dd>Unicode mode.  Open UTF-16 little endian file with or
 * without signature.</dd>
 *
 * <dt>+FUTF16BE</dt><dd>Unicode mode.  Open UTF-16 little endian file with or
 * without signature.</dd>
 *
 * <dt>+FUTF16BES</dt><dd>Unicode mode.  Open UTF-16 big endian file with or without
 * signature.</dd>
 *
 * <dt>+FUTF32LE</dt><dd>Unicode mode.  Open UTF-32 little endian file with or
 * without signature.</dd>
 *
 * <dt>+FUTF32LES</dt><dd>Unicode mode.  Open UTF-32 little endian file with or
 * without signature.</dd>
 *
 * <dt>+FUTF32BE</dt><dd>Unicode mode.  Open UTF-32 little endian file with or
 * without signature.</dd>
 *
 * <dt>+FUTF32BES</dt><dd>Unicode mode.  Open UTF-32 big endian file with or without
 * signature.</dd>
 *
 * <dt>+FCP<i>ddd</i></dt><dd>Unicode mode.  Open code page file specified by <i>ddd</i>.
 * Under windows, this can be any valid code page or one of the VSCP_* constants
 * defined in "slick.sh."</dd>
 *
 * <dt>+FACP</dt><dd>Unicode mode.  Open active code page file.  Under windows, this
 * can be any valid code page or one of the VSCP_* constants defined in
 * "slick.sh."</dd>
 *
 * <dt>+FAUTOXML</dt><dd> Unicode mode.  Open XML file.  The encoding is determined
 * based on the encoding specified by the "?xml" tag.  If the encoding is not
 * specified by the "?xml," the file data is assumed to be UTF-8 data which is
 * consistent with XML standards.  We applied some modifications to the standard
 * XML encoding determination to allow for some user error.  If the file has a
 * standard Unicode signature, the Unicode signature is assumed to be correct
 * and the encoding defined by the "?xml" tag is ignored.</dd>
 *
 * <dt>+FAUTOUNICODE</dt><dd>If the file has a standard Unicode signature,
 * open the file as a Unicode file.  Otherwise, the file is loaded as SBCS/DBCS data.</dd>
 *
 * <dt>+FAUTOUNICODE2</dt><dd>If the file has a standard Unicode signature
 * or "looks" like a Unicode * file, open the file as a Unicode file.  Otherwise, the file is
 * loaded as * SBCS/DBCS data.  This option is NOT full proof and may give incorrect
 * results.</dd>
 *
 * <dt>+FAUTOEBCDIC</dt><dd>If the file "looks" like an EBCDIC file, open the file
 * as an EBCDIC file.  Otherwise, the file is loaded as SBCS/DBCS data.  This option is NOT
 * full proof and may give incorrect results.  We have attempted to make this
 * option support binary EBCDIC files.</dd>
 *
 * <dt>+FAUTOEBCDIC,UNICODE</dt><dd>This option is a combination of
 * "+FAUTOEBCDIC" and "+FAUTOUNICODE" options.</dd>
 *
 * <dt>+FAUTOEBCDIC,UNICODE2</dt><dd>This option is a combination of
 * "+FAUTOEBCDIC" and "+FAUTOUNICODE2" options.</dd>
 *
 * <dt>+ or -U[:<i>nnn</i>]</dt><dd>Turn on/off undo.  Specifying <i>nnn</i> sets the
 * maximum number of undoable steps.  Default is off.  If +U  is not followed by
 * :<i>nnn</i>, <i>nnn</i> defaults to 300.  The range of <i>nnn</i> is
 * 0..32767.</dd>
 *
 * <dt>+ or -E</dt><dd>Turn on/off expand tabs to spaces switch.  Default is off.  Only
 * tabs of increments of 8 are supported.</dd>
 *
 * <dt>+E:<i>ddd</i></dt><dd>Expand tabs to spaces.  This expands tabs in increments of
 * <i>ddd</i>.</dd>
 *
 * <dt>+ or -D</dt><dd>Turn on/off memory buffer name search.  Disk file search.</dd>
 *
 * <dt>-I or +I</dt><dd>Insert a window with no views. This option is not supported by
 * _BufLoad or vsBufLoad().</dd>
 *
 * <dt>+ or -W</dt><dd>If the file or buffer is not already displayed in a window,
 * insert a window for displaying the file or buffer. This option is not supported by
 * _BufLoad or vsBufLoad().</dd>
 *
 * <dt>+B <i>buf_name</i></dt><dd>Look in memory only for buffer with buffer name or
 * document name <i>buf_name</i>.</dd>
 *
 * <dt>+BB <i>buf_name</i></dt><dd>Look in memory only for buffer with buffer name
 * <i>buf_name</i>.</dd>
 *
 * <dt>+BD <i>buf_name</i></dt><dd>Look in memory only for buffer with document name
 * <i>buf_name</i>.</dd>
 *
 * <dt>+BI <i>buf_id</i></dt><dd>Activate buffer with buffer id <i>buf_id</i>.</dd>
 *
 * <dt>+ or -M</dt><dd>If on, do not save cursor position of current buffer before
 * activating a new buffer.  This option is ignored by the _BufLoad() or vsBufLoad() functions.</dd>
 *
 * <dt>+ or -N</dt><dd>Network support switch.  When on, SlickEdit will detect
 * when another application has the same file open and automatically select
 * "Read only" mode.  This option requires an extra file handle open to the
 * original file.</dd>
 *
 * <dt>+ or -R</dt><dd>Turn replace current buffer switch on/off.  This option is not
 * supported by the _BufLoad() or vsBufLoad() functions.</dd>
 *
 * <dt>+ or -Q</dt><dd>Quiet switch.  This option is ignored by the _BufLoad() or vsBufLoad() functions</dd>
 * </dl>
 *
 * <p>The options above that only show a plus sign will also take a minus
 * sign.  However there function will remain the same.</p>
 *
 * <p>Here are more detailed descriptions of the options.</p>
 *
 * <dl>
 * <dt>+ or -L[C]</dt><dd>Turn on/off load entire file switch.  Default is off.
 * Entire file is loaded and unmodified blocks are swapped to spill file so that
 * file handle is freed.  Used to speed up file scrolling on slow disk.  Used to
 * free file handles or prevent file sharing problems.  Used to guard against
 * losing files loaded from remote system.  The optional C suffix tells Visual
 * SlickEdit to count the number of lines in the file.  The Z suffix counts the
 * number of lines in the file and truncates the file if an EOF character is
 * found in the middle of the file.</dd>
 *
 * <dt>+ or -BP</dt><dd>Turn on/off reinsert selected buffer/window after current
 * buffer/window.  Effects any macro which uses the <b>edit</b> command to
 * activate an existing buffer or window.  Effected commands include
 * <b>push_tag</b>, <b>next_error</b>, <b>edit</b>, <b>cursor_error</b>, and
 * <b>list_buffers</b>.  Helps the <b>prev_buffer</b> and <b>prev_window</b>
 * commands to switch to previously active file or window.</dd>
 *
 * <dt>+ or -S</dt><dd>Turn on/off unmodified block swapping to spill file.  When on,
 * unmodified blocks are spilled to spill file.  Used for editing remote files
 * across slow links.  Once a block is loaded from a slow access link, if it
 * needs to be spilled, it is written to your local hard disk or EMS/extended
 * memory.</dd>
 *
 * <dt>+<i>nnn</i></dt><dd>Load binary file giving each line <i>nnn</i> characters.
 * Used for editing binary or record files.</dd>
 *
 * <dt>+T [<i>buf_name</i>]</dt><dd>Start a temp buffer with name <i>buf_name</i>.
 * <i>buf_name</i> is expanded to absolute form and stored in the internal
 * variable ".buf_name".  The options +TU, +TM, and +TD are identical to the +T
 * option except they select one of the ASCII file formats UNIX,  MACINTOSH, or
 * DOS.</dd>
 *
 * <dt>+ or -U[:<i>nnn</i>]</dt><dd>Turn on/off undo.  Specifying <i>nnn</i> sets the
 * maximum number of undoable steps.  Default is off.  If +U  is not followed by
 * :<i>nnn</i>, <i>nnn</i> defaults to 300.  The range of <i>nnn</i> is
 * 0..32767.</dd>
 *
 * <dt>+ or -E</dt><dd>Turn on/off expand tabs to spaces switch.  Default is off.  Only
 * tab increments of 8 are supported.</dd>
 *
 * <dt>+ or -D</dt><dd>Turn on/off memory buffer name search.  When on, files are loaded
 * from disk regardless if there is a copy already in memory.  It is wise to
 * rename the copy after loading it to prevent saving the wrong file.</dd>
 *
 * <dt>+V [<i>window_id</i>]</dt><dd>Selects buffer by window information.  If no window is
 * specified the active window is assumed.</dd>
 *
 * <dt>+I</dt><dd>Insert a window with no views.  Window is deleted if no views are
 * inserted.</dd>
 *
 * <dt>+ or -W</dt><dd>Insert a window for each file that follows.</dd>
 *
 * <dt>+B <i>buf_name</i></dt><dd>Look in memory only for buffer with buffer name or
 * document name <i>buf_name</i>.  If buffer is not found, FILE_NOT_FOUND_RC is
 * returned.  No buffer is created, if buffer is not found.  Buffer name search
 * is case insensitive for file systems like DOS which are case insensitive.
 * Buf_name must be in absolute form (Full path spec).</dd>
 *
 * <dt>+BB <i>buf_name</i></dt><dd>Look in memory only for buffer with buffer name
 * <i>buf_name</i>.  If buffer is not found, FILE_NOT_FOUND_RC is returned.  No
 * buffer is created, if buffer is not found.  Buffer name search is case
 * insensitive for file systems like DOS which are case insensitive.  Buf_name
 * must be in absolute form (Full path spec).</dd>
 *
 * <dt>+BD <i>buf_name</i></dt><dd>Look in memory only for buffer with document name
 * <i>buf_name</i>.  If buffer is not found, FILE_NOT_FOUND_RC is returned.  No
 * buffer is created, if buffer is not found.  Buffer name search is case
 * insensitive for file systems like DOS which are case insensitive.  Buf_name
 * must be in absolute form (Full path spec).</dd>
 *
 * <dt>+BI <i>buf_id</i></dt><dd>Activate buffer with buffer id <i>buf_id</i>.</dd>
 *
 * <dt>+ or -M</dt><dd>If on, do not save cursor position of current buffer before
 * activating a new buffer.  This option has no effect if the +I or +W options
 * are used.</dd>
 *
 * <dt>+ or -N</dt><dd>Network support switch.  When on, SlickEdit will detect
 * when another application has the same file open and automatically select
 * "Read only" mode.  This option requires an extra file handle open to the
 * original file.</dd>
 *
 * <dt>+ or -R</dt><dd>Turn replace current buffer switch on/off.  When on the files
 * that follow will replace the current buffer.</dd>
 *
 * <dt>+ or -Q</dt><dd>Quiet switch.  When on, no message is displayed when an error
 * occurs.</dd>
 * </dl>
 *
 * @example
 * <pre>
 *          // Create a temp buffer and attatch it to the current window
 *          // The previous buffers cursor position information is saved before
 *          // switching to the new buffer.
 *          load_files '+t'
 *
 *          // Create a temp buffer with no name and turn undo on saving last
 *          // 300 steps.
 *          load_files '+u +t'
 *
 *          // Create a temp buffer with no name and turn undo on saving last
 *          // 32767 steps./
 *          load_files '+u:32767 +t'
 *
 *          /* Load the file "test.c" from disk even if already in memory */
 *          load_files '+d test.c'
 *
 *          /* Create a new window and a temporary buffer.  The new */
 *          /* window will show the temporary buffer created. */
 *          load_files '+i +t'
 *
 *          /* Create a new window and edit the file test.c in it. */
 *          load_files '+i test.c'
 *
 *          /* Activate the ".command" retrieve buffer */
 *          load_files '+b .command'
 *
 *    ;          Case 1  No buffer has name absolute(filename).
 *    ;          Then     Filename is loaded from disk.  The active cursor position
 *    ;                 information is replaced with the non-active cursor position
 *    ;                 information of this
 *    ;                       buffer.
 *
 *    ;          Case 2  Buffer exists with name absolute(filename).
 *    ;          Then     The active cursor position information is replaced with the
 *    ;                    non-active cursor position information of this buffer.
 *    ;
 *    ;          In any case, the active cursor position information is saved in the
 *    ;          active buffer's non-active cursor position.
 *
 *    load_files 'filename'
 * </pre>
 *
 * @return Returns 0 if successful.  Common return codes are
 * FILE_NOT_FOUND_RC (occurs when wild card specification matches no files),
 * NEW_FILE_RC (empty buffer created with filename specified because file did
 * not exist), PATH_NOT_FOUND_RC, TOO_MANY_WINDOWS_RC, TOO_MANY_FILES_RC,
 * TOO_MANY_SELECTIONS_RC, NOT_ENOUGH_MEMORY_RC.  On error, message is
 * displayed.
 *
 * @see get_window_id
 * @see activate_window
 * @see _next_window
 * @see _prev_window
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Buffer_Functions, Edit_Window_Methods, Editor_Control_Methods, File_Functions, Window_Functions
 *
 */
int load_files(_str options);


/**
 *
 * @param filename Name of buffer to find or file to load.  If options specifies a filename, +bi, or +v,
 *                 this parameter is ignored.  Null or '' may be specified when options are specified
 *                 which don't require a filename.
 * @param options  See {@link load_files} function for options.
 * @param CreateIfNotFound
 *                 Indicates that the a new file should be created if the file does not exist.
 *                 This option is ignored if the +t, +b, +bi, or +v options are specified.
 * @param BLResultFlags
 *                 Set to 0 or more of the following flags:
 *                 <dl compact>
 *                 <dt>VSBLRESULTFLAG_NEWFILECREATED</dt>
 *                 <dd>Indicates that a new file was created because the file was not found</dd>
 *                 <dt>VSBLRESULTFLAG_NEWTEMPFILECREATED</dt>
 *                 <dd>Indicates that a new temp file (+t option) was created</dd>
 *                 <dt>VSBLRESULTFLAG_NEWFILELOADED</dt>
 *                 <dd>Indicates that a file was loaded</dd>
 *                 <dt>VSBLRESULTFLAG_READONLY</dt>
 *                 <dd>Indicates that a file was loaded read only</dd>
 *                 <dt>VSBLRESULTFLAG_READONLYACCESS</dt>
 *                 <dd>Indicates that a file was loaded read only because of permissions on the file</dd>
 *                 <dt>VSBLRESULTFLAG_ANOTHERPROCESS</dt>
 *                 <dd>Indicates that a file was loaded read only because another process has the file open</dd>
 *                 </dl>
 *
 * @return If successful a buffer id>=0 is returned.  Otherwise a negative error code
 *         is returned.  Common return codes are
 *         FILE_NOT_FOUND_RC (occurs when wild card specification matches no files),
 *         PATH_NOT_FOUND_RC, TOO_MANY_WINDOWS_RC, TOO_MANY_FILES_RC,
 *         TOO_MANY_SELECTIONS_RC, NOT_ENOUGH_MEMORY_RC.  On error, message is
 *         displayed.
 * @example
 * <pre>
 *
 * // If absolute('test.cpp') exists as a buffer, return
 * // the buffer id.  Otherwise if the file exists on disk,
 * // load the file from disk and return the buffer id.
 * // Otherwise, create a new buffer with name absolute('test.cpp').
 * _BufLoad('test.cpp',null,true);
 *
 * // Load test.cpp from disk. If the file is not found,
 * // don't create it and return FILE_NOT_FOUND_RC.
 * // p_buf_name is set to absolute('test.cpp')
 * _BufLoad('test.cpp','+d',false);
 *
 * // Load test.cpp from disk. If the file is not found,
 * // create it and return the newly created buffer id.
 * // p_buf_name is set to absolute('test.cpp')
 * _BufLoad('test.cpp','+d');
 *
 * // Create a temp buffer
 * _BufLoad(null,'+t');
 *
 * // Create a temp buffer and set p_buf_name to '.internal'
 * _BufLoad('.internal','+ti');
 *
 * // Create a temp buffer and set p_buf_name to absolute('temp')
 * _BufLoad('temp','+t');
 *
 * // Find the buffer id for the ".command" retrieve buffer
 * bufid=_BufLoad('.command','+b');
 *
 * </pre>
 */
int _BufLoad(_str filename,_str options=null,boolean CreateIfNotFound=true,int &BLResultFlags=0);


/**
 * Creates a build window running in the current buffer.  If <i>command</i>
 * is an empty string ('') then the default command processor is started.  The
 * default command processor is defined by the COMSPEC (UNIX: SHELL) environment
 * variable.  Otherwise <i>command</i> contains the program name and arguments
 * to be executed as a concurrent process.  Each copy of SlickEdit can
 * run one concurrent session.
 *
 * @return  Returns 0 if successful.  Common error codes are: TOO_MANY_FILES_RC,
 * TOO_MANY_SELECTIONS_RC, CANT_FIND_INIT_PROGRAM_RC, ERROR_CREATING_SEMAPHORE_RC,
 * TOO_MANY_OPEN_FILES_RC, NOT_ENOUGH_MEMORY_RC, ERROR_CREATING_QUEUE_RC,
 * INSUFFICIENT_MEMORY_RC, and ERROR_CREATING_THREAD_RC.  On error, message is
 * displayed.
 *
 * @see shell
 * @see xcom
 * @see dos
 *
 *
 * @categories File_Functions
 */
int concur_shell(_str cmdline);

/**
 * Updates <b>p_left_edge</b> and <b>p_cursor_y</b> property to
 * make sure the cursor is in view.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
void _refresh_scroll();


/**
 * Be sure to look at the <b>get_string</b> function which prompts the user
 * for command line input.
 *
 * @return Returns the command line text, start of selection, end of
 * selection, and prompt in the corresponding variables.  If two arguments are
 * specified, <i>start_sel</i> is set to the cursor position.  The <i>prompt</i>
 * variable is always set to the prompt before the command line and not the
 * current text box.
 *
 * @see command_state
 * @see command_toggle
 * @see execute
 * @see set_command
 *
 * @appliesTo Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, Text_Box_Methods
 *
 */
void get_command(_str &text,int &start_sel=0,int &end_sel=0,_str &prompt="");

/**
 * <p>Be sure to look at the macro function <b>get_string</b> which allow
 * a macro to read command line input from the user.</p>
 *
 * <p><b>set_command</b> changes current setting of the command line.
 * Text of command line is set to <i>command_text</i>.   The selection
 * columns (1.. MAXINT) are set if <i>start_sel</i> is >=0.  If
 * <i>end_sel</i><0, <i>end_sel</i> is set to <i>start_sel</i>.  The
 * <i>prompt</i> parameter sets the command prompt.  The prompt may
 * only be modified by the <b>set_command</b> primitive.</p>
 *
 * @example
 * <pre>
 *           command_text='dir ';
 *           set_command(command_text, length(command_text)+1);
 * </pre>
 *
 * @see command_state
 * @see command_toggle
 * @see left
 * @see right
 * @see _delete_char
 * @see rubout
 * @see execute
 * @see get_command
 *
 * @appliesTo Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, Text_Box_Methods
 *
 */
void set_command(_str command_text,int start_sel=-1,int end_sel=-1,_str prompt=null);

int _pixel2col(int x);

/**
 * @return Returns the cursor position (same as <i>end_pos</i>).
 * <i>start_pos</i>, if given, is set to the cursor position from which the
 * selection was started.  <i>end_pos</i>, if given, is set to the current cursor
 * position.  The lowest cursor position is "1".
 *
 * @see _set_sel
 * @see p_sel_start
 * @see p_sel_length
 *
 * @appliesTo Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, Text_Box_Methods
 *
 */
int _get_sel(int &start_pos=0,int &end_pos=0);
/**
 * @return Sets the cursor position or selection.  If <i>end_pos</i> is not given,
 * the new cursor position is set to <i>start_pos</i> and no text is
 * selected.  If end_pos is given, the selection starts from
 * <i>start_pos</i> and ends at the cursor which is set to
 * <i>end_pos</i>.  The first text position is 1.
 *
 * @see _get_sel
 * @see p_sel_start
 * @see p_sel_length
 *
 * @appliesTo Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, Text_Box_Methods
 *
 */
void _set_sel(int start_pos,int end_pos=start_pos);

/**
 * Moves the line position of the retrieve buffer ".command", one line up
 * and places the contents of the line on the command line.  If the current
 * line is the first line of the buffer, the cursor is placed on the last line
 * and the contents of the last line are placed on the command line.
 * When the <b>execute</b> function is issued, the current line of the
 * retrieve buffer becomes the last line.  However, the first execution of
 * <b>retrieve_prev</b> after <b>execute</b> is issued will place the
 * contents of the last line on the command line without moving the line
 * position.
 *
 * @see _retrieve_next
 *
 * @appliesTo Command_Line
 *
 * @categories Command_Line_Methods, Retrieve_Functions
 *
 */
void _retrieve_prev();
/**
 * Moves the line position of the retrieve buffer ".command", one line
 * down and places the contents of the line on the command line.  If the
 * current line is the last line of the buffer, the cursor is placed on the
 * first line and the contents of the first line are placed on the command
 * line.  When <b>execute</b> is issued, the current line of the retrieve
 * buffer becomes the last line.
 *
 * @see _retrieve_prev
 *
 * @appliesTo Command_Line
 *
 * @categories Command_Line_Methods, Retrieve_Functions
 *
 */
void _retrieve_next();


/**
 * Enables a specific tab.  Used this method instead of the
 * <b>p_ActiveEnabled</b> property when setting enabled state of a
 * non-active tab.
 *
 * <p>
 *
 * The active window MUST be a tab control (OI_SSTAB). 
 *
 * @param tabIndex  Tab-index to set enabled.
 * @param enabled   Set to true to enable the tab, false to 
 *                  disable.
 *
 * @appliesTo SSTab
 * @categories SSTab_Methods
 *
 */
void _setEnabled(int tabIndex, boolean enabled);

/**
 * Return the tab-index of the tab that contains specified 
 * global (x,y) coordinates.
 *
 * <p>
 *
 * The active window MUST be a tab control (OI_SSTAB). 
 * 
 * @param x  Global x-coordinate.
 * @param y  Global y-coordinate.
 * 
 * @return Tab-index of tab containing (x,y), or -1.
 *
 * @appliesTo SSTab
 * @categories SSTab_Methods
 */
int _xyHitTest(int x, int y);

/**
 * Retrieves the tab information for the tab at the specified 
 * tab-index. 
 *
 * <p>
 *
 * The active window MUST be a tab control (OI_SSTAB). 
 *  
 * @param tabIndex  Tab-index to retrieve info for.
 * @param info      (out) SSTABCONTAINERINFO object.
 *  
 * @return Returns true on success, false on error (e.g. 
 *         tab-index does not exist).
 *
 * @appliesTo SSTab
 * @categories SSTab_Methods
 *
 */
boolean _getTabInfo(int tabIndex, SSTABCONTAINERINFO& info);

/**
 * Make the active window, which MUST be a tab container 
 * (OI_SSTAB_CONTAINER), the active tab on the tab control. 
 *
 * <p>
 *
 * Note that ON_CHANGE (CHANGE_TAB(DE)ACTIVATE) event is NOT 
 * called. 
 *
 * @appliesTo SSTab
 * @categories SSTab_Methods
 *
 */
void _makeActive();

/**
 * Get the tab container window (OI_SSTAB_CONTAINER) of the 
 * active tab on the tab control. 
 *
 * <p>
 *
 * The active window MUST be a tab control (OI_SSTAB). 
 *
 * @return Window id of active tab container. 0 if no active tab
 *         or active window is not a tab control.
 *
 * @appliesTo SSTab
 * @categories SSTab_Methods
 *
 */
int _getActiveWindow();


/**
 * Deletes the active tab.
 *
 * <p>
 *
 * The active window MUST be a tab control (OI_SSTAB). 
 *
 * @appliesTo  SSTab
 * @categories SSTab_Methods
 */
void _deleteActive();

/**
 * This method along with the _SetListColCaption method allows you to
 * create multiple labeled columns at the top of a list box and separate
 * tabbed delimited list box data into columns.
 *
 * @param index      starts at 0 and indicates which column you are
 *                   setting values for.  You must initialially create
 *                   multiple columns in order (that is 0,1,2... etc.).
 * @param width      is the width of the column in twips.
 * @param flags      The Style argument may be one of the following:
 *    <UL>
 *    <LI>LBCOLSTYLE_LABEL - Display the caption as a text that the user may not click on.
 *    <LI>LBCOLSTYLE_BUTTON - Treat the caption as a command button.
 *                            The on_change event will be sent with the reason
 *                            argument set to CHANGE_BUTTON_PRESS when a column
 *                            button is pressed.  arg(2) is set to the index of the column.
 *    <LI>LBCOLSTYLE_2STATE - Treat the caption like a 2 state push button where the
 *                            button stays down after you click. The on_change event
 *                            will be sent with the reason argument set to
 *                            CHANGE_BUTTON_PRESS when a column button is pressed.
 *                            arg(2) is set to the index of the column.
 *    </UL>
 * @param state      The InitialState argument specifies whether the button is initially
 *                   up or down (0 or 1 respectively).  The paremeter is ignored if Style
 *                   is LBCOLSTYLE_LABEL or LBCOLSTYLE_BUTTON.
 *
 * @example
 * <PRE>
 *    #include "slick.sh"
 *
 *    defeventtab form1;
 *    void list1.on_change(int reason)
 *    {
 *       if (reason==CHANGE_BUTTON_PRESS) {
 *          index=arg(2);
 *          _GetListColInfo(index,width,style,state);
 *          say('state='state);
 *          if (state) {
 *             _SetListColCaption(index,"Caption2 A");
 *          } else {
 *             _SetListColCaption(index,"Caption2");
 *          }
 *       }
 *    }
 *    list1.on_create()
 *    {
 *         _lbadd_item("style\t"p_style);
 *         _lbadd_item("width\t"p_width);
 *         _lbadd_item("caption\tcaption");
 *
 *         _SetListColInfo(0,1000,LBCOLSTYLE_LABEL);
 *         _SetListColCaption(0,"Caption1");
 *         _SetListColInfo(1,1000,LBCOLSTYLE_2STATE,0);
 *         _SetListColCaption(1,"Caption2");
 *         _lbtop();
 *    }
 * </PRE>
 *
 * @see _GetListColInfo
 * @see _GetListColCaption
 * @see _SetListColCaption
 *
 * @appliesTo Label
 *
 * @categories Label_Methods
 *
 */
void _SetListColInfo(int index,int width=0,int flags=0,int state=0);
/**
 * This method along with the _SetListColInfo method allows you to create
 * multiple labeled columns at the top of a list box and separate tabbed
 * delimited list box data into columns.
 *
 * @example
 * <PRE>
 *    #include "slick.sh"
 *
 *    defeventtab form1;
 *    void list1.on_change(int reason)
 *    {
 *       if (reason==CHANGE_BUTTON_PRESS) {
 *          index=arg(2);
 *          _GetListColInfo(index,width,style,state);
 *          say('state='state);
 *          if (state) {
 *             _SetListColCaption(index,"Caption2 A");
 *          } else {
 *             _SetListColCaption(index,"Caption2");
 *          }
 *       }
 *    }
 *    list1.on_create()
 *    {
 *         _lbadd_item("style\t"p_style);
 *         _lbadd_item("width\t"p_width);
 *         _lbadd_item("caption\tcaption");
 *
 *         _SetListColInfo(0,1000,LBCOLSTYLE_LABEL);
 *         _SetListColCaption(0,"Caption1");
 *         _SetListColInfo(1,1000,LBCOLSTYLE_2STATE,0);
 *         _SetListColCaption(1,"Caption2");
 *         _lbtop();
 *    }
 * </PRE>
 *
 * @see _GetListColInfo
 * @see _GetListColCaption
 * @see _SetListColInfo
 *
 * @appliesTo Label
 *
 * @categories Label_Methods
 *
 */
void _SetListColCaption(int index,_str caption);
/**
 * This method retrieves the column values set by the _SetListColInfo method.
 *
 * @see _SetListColInfo
 * @see _SetListColCaption
 * @see _SetListColInfo
 *
 * @appliesTo Label
 *
 * @categories Label_Methods
 */
void _GetListColInfo(int index,int &width,int &flags=0,int &state=0);
/**
 * Returns the caption for corresponding to the column index specified.
 *
 * @see _GetListColInfo
 * @see _SetListColCaption
 * @see _SetListColInfo
 *
 * @appliesTo Label
 *
 * @categories Label_Methods
 */
_str _GetListColCaption(int index);



/**
 * Returns display width of longest line in buffer in the parent
 * scale mode (p_xyscale_mode).  This function is typically used to
 * change the size of a dialog box and list box based on the
 * longest display item in the list box.
 *
 * @example
 * <PRE>
 *    #include 'slick.sh'
 *    defeventtab form1;
 *    list1.on_create()
 *    {
 *       _lbadd_item("Line1");
 *       _lbadd_item("This is a longer line2");
 *       _lbadd_item("This is the longest item in the list box");
 *       longest=_find_longest_line();
 *
 *       // Add on a little to account for the left and right borders of the
 *       // list box.  Have to convert client width because it's in pixels.
 *       list_width=longest+ p_width-_dx2lx(p_xyscale_mode,p_client_width);
 *
 *       form_wid=p_active_form;
 *
 *       // Again we have to account for the left and right borders.
 *
 *       // Multiple p_x of list box by two to show equal amounts of spacing on each side
 *       // of the list box
 *       form_width=2*p_x+ list_width+ form_wid.p_width-
 *                  _dx2lx(form_wid.p_xyscale_mode,form_wid.p_client_width);
 *
 *       p_width=list_width;
 *       form_wid.p_width=form_width;
 *
 *       // Now make sure the whole dialog box can be seen on screen
 *       form_wid._show_entire_form();
 *    }
 * </PRE>
 *
 * @appliesTo  Edit_Window, Editor_Control, List_Box
 * @categories Edit_Window_Methods, Editor_Control_Methods, List_Box_Methods
 */
int _find_longest_line();


void _end_modal_wait(_str result="");
void _move_selected(_str option_ch='M',int &handle_i=0,int &Nofselected=0,int &click_wid=0,int color=0);


/**
 * Returns an integer 0..255 corresponding to the byte given. 
 *
 * @param string of length one. (one byte).
 *
 * @return the byte code 0..255 corresponding to the specified 
 *         character
 * @example _asc('A') :== 65
 *
 * @see _chr 
 * @see _UTF8Asc 
 * @see _UTF8Chr
 * @categories String_Functions
 */
int _asc(_str character);

/**
 * Tests the given condition and produces a Slick-C stack if the 
 * condition fails, reporting the message, if specified.
 * @example
 *          _assert(1+1==2);
 *  
 * @see _StackDump
 * @categories Miscellaneous_Functions
 */
_str _assert(boolean condition, _str msg=null);

/**
 * 
 * 
 * @categories String_Functions
 * @param ascii_code  Integer byte code in the range of 0..255
 * 
 * @return Returns a string of length 1 corresponding to
 *         the byte code given.
 * @example 
 * 
 *          _chr(65):== 'A'
 * @see _asc 
 * @see _UTF8Asc 
 * @see _UTF8Chr
 */
_str _chr(int ascii_code);

/**
 * @return Returns UTF-8 string corresponding to the Unicode character index
 * given.  If SlickEdit is not running in UTF-8 mode (
 * _UTF8()==0 ), this function operates identically to the <b>_chr</b>
 * function.
 *
 * @categories String_Functions
 *
 */
_str _UTF8Chr(int utf32);
/**
 * @return Returns the number of bytes in <i>string</i>.
 *
 * @example
 * <pre>
 * length('abc')  == 3
 * length('')  == 0
 * </pre>
 *
 * @categories String_Functions
 *
 */
int length(_str string);

/**
 * @return Returns the position of <i>needle</i> in <i>haystack</i>.  If
 * <i>needle</i> is not found, 0 is returned.
 *
 * @param needle         string to search for.  If this is the only parameter
 *                       it retrieves tagged expression information. (see example).
 * @param haystack       (optional) string to search within
 * @param start          (optional, default=1) specifies the position at which the
 *                       search should begin.
 * @param options        (optional) Multiple options may be specified with the
 *                       following meaning:
 * @param wordchars      (optional) Define the word characters 
 *                       set for the string, for use when you
 *                       need to use regular expressions with
 *                       word boundaries (example
 *                       "[A-Za-z0-9]").
 * <dl>
 * <dt>'I'</dt><dd>Ignore case.</dd>
 * <dt>'R'</dt><dd>Interpret search string needle as a regular
 * expression.  See section SlickEdit Regular
 * Expressions for syntax of regular expressions.</dd>
 * <dt>'U'</dt><dd>Interpret search string as a UNIX regular
 * expression.  See UNIX Regular Expressions.</dd>
 * <dt>'B'</dt><dd>Interpret string as a Brief regular expression.
 * See section Brief Regular Expressions.</dd>
 * <dt>'L'</dt><dd>Interpret string as a Perl regular expression.
 * See section Perl Regular Expressions.</dd>
 * <dt>'&'</dt><dd>Interpret string as a wildcard expression.
 * See section Wildcard Expressions.</dd>
 * <dt>Y</dt><dd>Binary search.  This allows start positions in the
 * middle of a DBCS or UTF-8 character.  This option
 * is useful when editing binary files (in SBCS/DBCS
 * mode) which may contain characters which look
 * like DBCS but are not.  For example, if you search
 * for the character 'a', it will not be found as the
 * second character of a DBCS sequence unless this
 * option is specified.</dd>
 * <dt>A</dt><dd>Specifies an SBCS/DBCS active code page search.
 * <i>needle</i> and <i>haystack</i> must be
 * SBCS/DBCS active code page data and not UTF-8.
 * This option has no effect unless SlickEdit is
 * running in Unicode support mode.  See "Unicode
 * and SBCS/DBCS Macro Programming."</dd>
 *
 * @example
 * <pre>
 * pos('a','zzz') == 0
 * pos('a','zzza')   == 4
 * pos('a,'zzzA',1,'I') == 4
 * pos('a','zzza',5) == 0
 * pos('[a-z]','%$?a',1,'R')  == 4
 * </pre>
 *
 * <p>Calling the pos function with one parameter allows you to retrieve
 * tagged expression information.  Specifying 'S' followed by a tagged
 * expression number 0-9 (i.e. 'S0') will return the start position of that
 * tagged expression.  1 is returned if that tagged expression was not
 * found.  If 'S' is not followed by a number, the start position of the
 * entire string found is returned.  Specifying a tagged expression number
 * 0-9 will return the match length of the group.  For 'R' and 'B' option
 * regular expressions, the first tagged expression is 0 and the last is 9.
 * For 'U' option regular expressions, the first tagged expression is 1 and
 * the last is 0.  0 is returned if that tagged expression was not found.  A
 * value of '' will return the match length of the entire string found.</p>
 *
 * @example
 * <pre>
 *        get_line(line);
 *        word_sep='([~a-zA-Z0-9_$]|^|$)';
 *        i=pos(word_sep'{if|then|while}'word_sep,line,1,'r');
 *        if (!i ) {
 *            message('Match not found');
 *            return(1);
 *        }
 *        word=substr(line,pos('S0'),pos('0'));
 * </pre>
 *
 * @see substr
 * @see lastpos
 *
 * @categories String_Functions
 */
int pos(_str needle ,_str haystack="",int start=1,_str options="",_str wordchars=null);
/**
 * @return Returns the position <CODE>(1..length(haystack))</CODE> of the
 * last occurrence of <CODE>needle</CODE> in <CODE>haystack</CODE>.
 * If <CODE>needle</CODE> is not found, 0 is returned.
 *
 * @param needle         string to search for.  If this is the only parameter
 *                       it retrieves tagged expression information. (see example).
 * @param haystack       (optional) string to search within
 * @param start          (optional) specifies the position at which the
 *                       search should begin.  If not specified or if "" is specified,
 *                       searching begins at end of <CODE>haystack</CODE>.
 *                       <CODE>start</CODE> must be in the range 1..MAX_WHOLE_NUMBER.
 * @param options        (optional) Multiple options may be specified with the
 *                       following meaning:
 *                       <DL compact>
 *                       <DT>'I' <DD>Ignore case.
 *                       <DT>'R' <DD>Interpret search string needle as a regular expression.
 *                                   See help section "SlickEdit Regular Expressions"
 *                                   for syntax of regular expressions.
 *                       <DT>'U' <DD>Interpret search string as a UNIX regular expression.
 *                                   See help section "UNIX Regular Expressions".
 *                       <DT>'B' <DD>Interpret string as a Brief regular expression.
 *                                   See help section "Brief Regular Expressions".
 *                       <DT>'L' <DD>Interpret string as a Perl regular expression.
 *                                   See help section "Perl Regular Expressions".
 *                       <DT>'&' <DD>Interpret string as a Wildcard expression.
 *                                   See help section "Wildcard Expressions".
 *                       <DT>'Y' <DD>Binary search.  This allows start positions in the
 *                                   middle of a DBCS character (only effects Japanese
 *                                   operating systems).  This option is useful search binary
 *                                   data which may contain characters which look like
 *                                   DBCS but are not.
 *                       </DL>
 *  
 * @param wordchars      (optional) Define the word characters 
 *                       set for the string, for use when you
 *                       need to use regular expressions with
 *                       word boundaries (example
 *                       "[A-Za-z0-9]").
 * @example
 * <PRE>
 * lastpos('a','aca') == '3'
 * lastpos('aa','aaa',2) == '2'
 * lastpos('W\cord','word test',3,'IR') == '2'
 * </PRE>
 *
 * Calling the lastpos function with one parameter allows you to retrieve
 * tagged expression information.  Specifying 'S' followed by a tagged
 * expression number 0-9 (i.e.  'S0') will return the start position of that
 * tagged expression.  1 is returned if that tagged expression was not found.
 * If 'S' is not followed by a number, the start position of the entire
 * string found is returned.  Specifying a tagged expression number 0-9 will
 * return the match length of that tagged expression.  For 'R' option regular
 * expressions, the first tagged expression is 0 and the last is 9.  For 'U'
 * option regular expressions, the first tagged expression is 1 and the last
 * is 0.  0 is returned if that tagged expression was not found.  A value of
 * '' will return the match length of the entire string found.
 *
 * <PRE>
 * get_line(line);
 * word_sep='([~a-zA-Z0-9_$]|^|$)';
 * i=lastpos(word_sep'{if|then|while}'word_sep,line,'','r');
 * if (!i) {
 *      message('Match not found');
 *      return(1);
 * }
 * word=substr(line,lastpos('S0'),lastpos('0'));
 * </PRE>
 *
 * The <CODE>pos</CODE> and <CODE>lastpos</CODE> function return the same tagged
 * expression information.  For example, pos('S0')==lastpos('S0') will always be true.
 *
 * @see pos
 * @see substr
 *
 * @categories String_Functions
 */
int lastpos(_str needle ,_str haystack="",int start=MAXINT,_str options="",_str wordchars=null);

/**
 * @return
 * Returns string stripped of leading and/or trailing 
 * <i>strip_char</i>. 'ltb' may be one of 3 values with the 
 * following meaning: 
 * <ol>
 * <li>'L' -- Remove leading <i>strip_char</i>
 * <li>'T' -- Remove trailing <i>strip_char</i>
 * <li>'B' -- (Default) Remove both leading and trailing 
 * <i>strip_char</i>
 * </ol>
 * <p>
 * If <i>strip_char</i> is omitted, both tabs and spaces are 
 * stripped. 
 *
 * @param string     input string
 * @param ltb        leading, trailing, or both
 * @param strip_char character to strip
 *
 * @example
 * <pre>
 *    strip(' abc ') :== 'abc'
 *    strip(' abc ','L')   :== 'abc '
 *    strip(' abc ','T')   :== ' abc'
 *    strip('  '\t'abc '\t,'B',' ') :== \t'abc '\t
 * </pre>
 *
 * @categories String_Functions
 *
 */
_str strip(_str string,_str ltb="B",_str strip_char=" \t");

/**
 * @return
 * Returns length characters of string beginning at start.
 * By default, length is the rest of string.
 * If length is greater than length of string,
 * the return string is padded with blanks or pad character if specified.
 * 'start' must be a positive whole number.
 *
 * @param string     input string
 * @param start      start position
 * @param length     number of characters to get, default is to get to end of string
 * @param pad        padding character if 'start+length' goes beyond end of string
 *
 * @example
 * <pre>
 *    substr('test',2)     :== 'est'
 *    substr('test',1,5)   :== 'test '
 *    substr('',1,5,'*')   :== '*****'
 *    substr('test',2,4)   :== 'est '
 * </pre>
 *
 * @categories String_Functions
 *
 */
_str substr(_str string,int start,int length=-1,_str pad=" ");
/**
 * @return  Returns string converted to upper case.
 *
 * @param string     Input string.
 * @param utf8       -1 specifies that input and output string are UTF-8
 *                   if UTF-8 support is enabled.
 *                   0 specifies that input and output string are SBCS/DBCS.
 *                   1 specifies that input and output string are UTF-8.
 *
 * @example
 * <pre>
 *    upcase('ABc')  == 'ABC'
 *    upcase('abc')  == 'ABC'
 * </pre>
 *
 * @see lowcase
 * @see upcase_selection
 * @see upcase_word
 *
 * @categories String_Functions
 *
 */
_str upcase(_str string,int utf8= -1);

/**
 * @return  Returns string converted to lower case.
 *
 * @param string     Input string.
 * @param utf8       -1 specifies that input and output string are UTF-8
 *                   if UTF-8 support is enabled.
 *                   0 specifies that input and output string are SBCS/DBCS.
 *                   1 specifies that input and output string are UTF-8.
 *
 * @example
 * <pre>
 *    lowcase('ABc') == 'abc'
 *    lowcase('ABC') == 'abc'
 * </pre>
 *
 * @see upcase
 *
 * @categories String_Functions
 *
 */
_str lowcase(_str string,int utf8= -1);

/**
 * @return  Returns string with case converted on all strings, 
 * lower to upper, and upper to lower.
 *
 * @param string     Input string.
 * @param utf8       -1 specifies that input and output string are UTF-8
 *                   if UTF-8 support is enabled.
 *                   0 specifies that input and output string are SBCS/DBCS.
 *                   1 specifies that input and output string are UTF-8.
 *
 * @example
 * <pre>
 *    togglecase('ABc') == 'abC'
 *    togglecase('abc') == 'ABC'
 * </pre>
 *
 * @see lowcase
 * @see upcase
 * @see togglecase_selection
 *
 * @categories String_Functions
 *
 */
_str togglecase(_str string,int utf8= -1);

/**
 * @return  Returns string with characters reversed.
 *
 * @param string     Input string.
 * @param utf8       -1 specifies that input and output string are UTF-8
 *                   if UTF-8 support is enabled.
 *                   0 specifies that input and output string are SBCS/DBCS.
 *                   1 specifies that input and output string are UTF-8.
 *
 * @example
 * <pre>
 *    strrev('ABc')  == 'cBA'
 *    strrev('abc123')  == '321cba'
 * </pre>
 *
 * @see lowcase
 * @see upcase
 *
 * @categories String_Functions
 *
 */
_str strrev(_str string,int utf8= -1);

/**
 * @return Returns <b>true</b> if <i>string1</i> matches <i>string2</i> when
 * compared case insensitive.
 *
 * @param s1   input string 1
 * @param s2   input string 2
 *
 * @categories String_Functions
 *
 */
boolean strieq(_str s1, _str s2);

/**
 * Replaces all occurrences of a search string within a string. 
 *  
 * @return Returns <i>original</i> with all occurrences of 
 *         <i>search_for</i> replaced with <i>replace_with</i>.
 *         See {@link pos}</b> function for information on valid
 *         search <i>search_options</i>.
 *
 * @param original           String to modify
 * @param replace_with   String to replace occurrences of 
 *                       <CODE>search_for</CODE> with
 * @param search_for     String to search for. May be a regular 
 *                        expression
 * @param search_options Search options. See {@link pos} for 
 *                       valid options.
 *
 * @see pos
 *
 * @categories String_Functions
 */
_str stranslate(_str original,_str replace_with,_str search_for,_str search_options="");

/**
 * <p>If <i>option</i> =='', this function returns the first character position
 * in <i>string</i> which is not one of the characters in
 * <i>reference</i>.  If <i>string</i> is only composed of characters
 * from <i>reference</i>, then 0 is returned.</p>
 *
 * <p>If <i>option</i> == 'M' , this function returns the first character
 * position in <i>string</i> which matches one of the characters in
 * <i>reference</i>.  If no characters in <i>reference</i> match a
 * character in <i>string</i>, 0 is returned.</p>
 *
 * <p>If <i>start </i>is specified, the searching begins at <i>start</i>.</p>
 *
 * @example
 * <pre>
 * verify("test.*","*?",'M')  ==6
 * verify("?*st.*","*?",'M',3)   ==6
 * verify("?*st.*","*?")   ==3
 * </pre>
 *
 * @categories String_Functions
 *
 */
_str verify(_str string, _str reference, _str option="",int start=1);


/**
 * Returns a symmetrically padded string of <i>width</i> characters.
 * If the length of <i>string</i> is less than <i>width</i> characters, the
 * left and right of the returned string will be padded with the <i>pad</i> character.
 * The right will always be padded the same or more than the left.  If the length of
 * <i>string</i> is greater than or equal to <i>width</i> characters, the returned
 * string will be truncated on the left and right.  The right will always be
 * truncated the same or more than the left.  Pad defaults to "".
 *
 * @param string
 * @param width
 * @param pad
 *
 * @return the padded string
 * @example
 * <pre>
 * center("test",6)  :==" test "
 * center("test",6,"-") :=="-test-"
 * center("test",7,"-") :=="-test--"
 * center("test",3)  :=="tes"
 * center("test",2)  :=="es"
 * </pre>
 * @categories String_Functions
 */
_str center(_str string,int width,_str pad=" ");

/**
 * @return Returns string with characters translated according to tables.
 * Characters that are in the input_table are translated to the
 * corresponding character in the output table.  If the length of
 * input_table is greater than the length of output_table, output_table is
 * padded with the pad character given.  Pad character defaults to ''.
 * If output_table is not given, string is converted to upper case.
 * <p>
 * If 'compliment' is given and not zero, characters matching the
 * input table will be preserved, and all *other* characters will
 * be replaced with the pad character.
 *
 * @param string          Input string
 * @param output_table    table of characters to replace matches with
 * @param input_table     table of characters to look for
 * @param pad             pad character if length(output_table) < length(input_table)
 * @param compliment      Replace char with 'pad' character if it matches input table
 * @param binary          When true, input string is treated as an
 *                        array of bytes (dbcs or utf8 characters are not
 *                        special).
 *
 * @return translated string
 *
 * @example
 * <pre>
 *    translate('bottom_of_window','-','_')  =='bottom-of-window'
 *    translate('bottom_of_window','','_','*')  =='bottom*of*window'
 *    translate('bottom_of_window') =='BOTTOM_OF_WINDOW'
 * </pre>
 *
 * @see stranslate
 *
 * @categories String_Functions
 */
_str translate(_str string,_str output_table,_str input_table,_str pad="",int compliment=0,boolean binary=false);
/**
 * Halts the macro command currently running.  If the command is an
 * external command (extension '.e' or '.cmd'), the module is unloaded
 * and the previous command is resumed.
 *
 * @see exit
 * @see _suspend
 * @see _resume
 *
 * @categories Miscellaneous_Functions
 *
 */
void stop();

/**
 * Write a string to the SlickEdit debug window.
 *
 * @param string     string to display
 *
 * @categories Miscellaneous_Functions
 */
void say(_str string);

/**
 * Write a string to the SlickEdit log file.
 * The log file is located in the user's configuration
 * directory, under the "logs" subdirectory.
 *
 * @param string     string to display
 * @param log        can be a single word, and word.log will be
 *                   stored in the standard logs subdirectory.
 *                   Leave this blank to use the default
 *                   (vs.log). Can also specify a full path to
 *                   the log file.
 * @param depth      controls space before this line.  There
 *                   will be depth * 3 spaces before the text
 *                   specified in the string param.
 *  
 * @categories Miscellaneous_Functions
 */
void dsay(_str string, _str log = null, int depth = 0);

/**
 * Exits the editor without saving anything.  The editors return code is set
 * to <i>number</i> if given.  Otherwise return code is set to 0.
 *
 * @see safe_exit
 * @see fexit
 * @categories Miscellaneous_Functions
 */
void exit(int retcode);

/**
 * Calls event handler for key.  This function is intended for use by edit window, editor controls,
 * and text box controls for the special purposes described below.  Use the call_event function for other purposes.
 * <p>
 * <pre>
 *    Reasons for using this function:
 *    --You used <b>get_event</b> and read a key or mouse event and you want normal
 *      processing of the event to occur.  Specify first parameter only.
 *    --You have written a key translator macro such as <b>alt_prefix</b>, <b>ctrl_prefix</b>, <b>shift_prefix</b>,
 *      <b>esc_alt_prefix</b>, or <b>case_indirect</b> and you want processing to continue.
 *      Specify the first and second parameters.  The <b>last_index</b> function with the 'p' option will return the key message text.
 *    --You have written a keyboard hook function for the <b>on_select</b> event and you want
 *      processing to call the original event. Specify 'S' for the third argument.
 *    --You have written an _on_hex() function and you want
 *      processing to call the original event. Specify 'E' for the third argument.
 *    --You have written buffer specific keyboard callback by using the _kbd_add_callback()
 *      function and you want processing to call the original event. Specify '1' for the third argument.
 *    --Specify 'L' if you have already processed _on_select, _on_hex, _on_key
 * </pre>
 *    If the current object is the command line or an MDI edit window, the root and mode event tables are used to
 * determine the event handler to be called.  If event is an ASCII character and a binding does not exist, the
 * character is inserted.  The call is recorded if macro recording is on.
 * <p>
 *    If the current object is not the command line or an MDI edit window, the dialog box inheritance order is used.
 * However, user level 1 and 2 inheritance are skipped if the third parameter is given.
 * <p>
 *    If two or more arguments are given and the current object is a text box, an edit window, or an editor control,
 * call_key determines the event handler for the key by using the last event table used to determine an event handler.
 * <p>
 *    If 2 or more parameters are specified, the last event returned by the <b>last_event</b> function is set to key.
 * @example
 *
 *          key=get_event();
 *          call_key(key);
 *
 * @see get_event
 * @see test_event
 * @see last_event
 * @see event2name
 * @see event2index
 * @see index2event
 * @see list_bindings
 * @see name2event
 * @see eventtab_index
 *
 *
 * @categories Keyboard_Functions
 */
void call_key(_str key,_str continuation_message="\1", _str chOption="D");

/** 
 * The call function is just used to evaluate an expression 
 * and leaves the result in rc.  It is unneccessary, and is 
 * no longer used in Slick-C. 
 *  
 * @param t    expression to evaluate (usually a function call) 
 *  
 * @deprecated 
 * @categories Miscellaneous_Functions 
 */
void call(typeless t);

/**
 * Load a Slick-C resource template by index.
 *  
 * @param index_or_wid Resource template index or window id of 
 *                     already-created object. If 'W' or 'R'
 *                     options are used, then it is the window
 *                     id of the already-created object.
 *                     Otherwise it is the resource template.
 * @param parent       Parent window id.
 * @param options      Load options. 
 *                     <ul>
 *                       <li>'H' = Load template hidden.
 *                       <li>'E' = Used internally by dialog editor. Load template in edit mode.
 *                       <li>'A' = Load template with ON_CREATE arguments passed on the interpreter stack. <b>IMPORTANT:</b> See VSLOAD_ARGPARAMS for more explanation before you attempt to use this option.
 *                       <li>'W' = Reload template with provided wid passed in index_or_wid parameter.
 *                       <li>'R' = Reinitialize template with provided wid passed in index_or_wid parameter. p_user, p_user2, * window geometry, default property values are reset.
 *                       <li>'C' = Do not call ON_CREATE events for loaded template. This includes ON_LOAD and ON_RESIZE. Use 'W' to call these events later.
 *                       <li>'P' = Load template as a child of parent wid.
 *                       <li>'N' = Load template as a child of parent wid and do not draw a border.
 *                       <li>'S' = Create children of parent. Parent wid must be a handle to the already created parent.
 *                       <li>'Y' = Load template with ON_CREATE arguments passed as an array. Next argument is the array of ON_CREATE arguments.
 *                       <li>'M' = Use MDI callbacks. Useful for setting status line text when window is not an MDI child.
 *                       <li>'T' = Load template as toolbar.
 *                     </ul> 
 * 
 * @return Window id of loaded resource. Returns <0 on error. 
 *  
 * @see find_index
 *  
 * @categories Window_Functions
 */
int _load_template(int index_or_wid, int parent, _str options, ...);

/**
 * @param load_option may be 'L','R', or 'U'.  Module
 * name extensions are replaced with '.ex'.
 *
 * @return If <i>load_option</i>=='L' the modules specified are loaded if
 * the module is not already loaded.  If any of the modules are already loaded,
 * loading stops and MODULE_ALREADY_LOADED_RC is returned.  Error return codes
 * may be INTERPRETER_OUT_OF_MEMORY_RC or a file I/O RC.  Upon successful
 * completion, 0 is returned.
 *
 * <p>If <i>load_option</i>=='R' the modules specified are loaded after the
 * Slick-C&reg; interpreter stops.  If any of the modules are already loaded, they
 * are unloaded before the new module is loaded.  Return value may be
 * INTERPRETER_OUT_OF_MEMORY_RC immediately after _load is executed.  Upon
 * successful completion, 0 is returned.  If any of the <i>modules</i> can not
 * be unloaded, the message "Can't remove module" will be displayed.</p>
 *
 * <p>If <i>load_option</i>=='U' the modules specified are unloaded.  If any
 * of the <i>modules</i> can not be unloaded because they are running, unloading
 * stops and CANT_REMOVE_MODULE_RC is returned.  Upon successful completion, 0
 * is returned.</p>
 *
 * @see unload
 * @see load
 * @see gui_load
 * @see gui_unload
 * @see load_all
 *
 * @categories Macro_Programming_Functions
 *
 */
int _load(_str modules,_str load_option="L");

/**
 * Sets the contents of the variable corresponding to the name table
 * index to value.
 *
 * @param index  index into the names table returned by one of the
 *               functions {@link find_index} or {@link name_match}.
 * @param value  value to set variable to.
 *
 * @example
 * <PRE>
 * // VAR_TYPE is defined in "slick.sh"
 * index=find_index("rc",VAR_TYPE)
 * _set_var(index,"anything");
 * message('rc='_get_var(index));
 * </PRE>
 *
 * @see _get_var
 * @see find_index
 * @see name_match
 *
 * @categories Macro_Programming_Functions,Miscellaneous_Functions
 *
 */
void _set_var(int index,typeless value);
/**
 * @return Returns the contents of the variable
 *         corresponding to the name table index given.
 *
 * @param index  name table index of variable to get contents of.
 *
 * @example
 * <PRE>
 * // VAR_TYPE is defined in "slick.sh"
 * index=find_index('rc',VAR_TYPE);
 * message('rc='_get_var(index));
 *
 * @see _set_var
 * @see find_index
 * @see name_match
 *
 * @categories Miscellaneous_Functions
 *
 */
typeless &_get_var(int index);
int _make(_str modules);
/**
 * Reserved word.
 *
 * @categories Miscellaneous_Functions
 *
 */
void trace();


/**
 * @return  Returns the name of the environment variable matching the prefix
 * <i>name_prefix</i>.  If a match is not found, the global <b>rc</b> variable
 * is set to STRING_NOT_FOUND_RC and '' is returned.  If <i>find_first</i> is
 * non-zero, matching starts from the first environment variable.  Otherwise
 * matching starts after the previous match.
 *
 * @see get_env
 * @see set_env
 * @categories Miscellaneous_Functions
 */
_str env_match(_str name_prefix, int find_first);
/**
 * @return Returns the value of the environment variable <i>name</i>.  If
 * <i>name</i> is not found, rc is set to STRING_NOT_FOUND_RC and '' is
 * returned.
 *
 * @see env_match
 * @see set_env
 *
 * @categories Miscellaneous_Functions
 *
 */
_str get_env(_str EnvVarName);
/**
 *
 * Assigns <i>value</i> to the environment variable <i>name</i>.  If
 * <i>value</i> is not given, the environment variable is removed from
 * the environment.
 *
 * @return Returns 0 if successful.  Otherwise,
 * INTERPRETER_OUT_OF_MEMORY_RC is returned.
 *
 * @see env_match
 * @see get_env
 *
 * @categories Miscellaneous_Functions
 *
 */
int set_env(_str EnvVarName,_str value=null);
/**
 * @return All index values returned by this function are indexes into the
 * names table.  SlickEdit stores information for names of procedures,
 * commands, variables, event tables, and more in the names table.
 *
 * <p>When the second parameter is 'D', this function returns (and sets if
 * <i>new_value</i> not ''), the index of the last command executed by a key or
 * the built-in <b>call_key</b> function.</p>
 *
 * <p>When the second parameter is 'C', this function returns (and sets if
 * <i>new_value </i>not ''), the index of the last command executed by any
 * mechanism.</p>
 *
 * <p>When the second parameter is 'P', this function returns the prefix key
 * message displayed on the message line for the last key sequence executed.
 * <i>new_value</i> parameter is ignored.</p>
 *
 * <p>When the second parameter is 'K', this function returns the index of
 * the last event table used to determine a key binding.  <i>new_value</i>
 * parameter is ignored.</p>
 *
 * <p>When the second parameter is 'W', this function returns (and sets if
 * <i>new_value</i> not ''), the command line/menu wait value.  This flag is set
 * to non-zero when a command is invoked from the command line or a menu.</p>
 *
 * @see prev_index
 *
 * @categories Names_Table_Functions
 *
 */
int last_index(_str new_value="",_str option="D");
/**
 * @return Returns index of previous command executed by a key or the built-in
 * function <b>call_key</b>. If <i>new_value</i> is specified and not '',
 * the index of the previous command is set to <i>new_value</i>.
 *
 * <p>When the second parameter is 'C', this command returns (and sets if
 * <i>new_value </i>not '') the index of the previous command executed
 * by any mechanism.</p>
 *
 * @see last_index
 *
 * @categories Miscellaneous_Functions
 *
 */
int prev_index(_str new_value="",_str option="D");

/**
 * @param cmdline is a string in the format: <i>pcode_offset filename</i> *
 * @return  Returns string containing <i>pcode_offset</i> and <i>filename</i>
 * of the last interpreter run-time error.  The filename returned has no path.
 * <i>pcode_offset</i> is the offset in .ex (pcode) file of error.  This
 * information may be passed to <b>st</b> command to find the corresponding line
 * of the last run-time error.  If the <i>pcode_offset</i> and <i>filename</i>
 * arguments are specified, the error position information is set.
 * @example
 * <pre>
 *          parse error_pos() with pcode_offset filename;
 *          sourcefilename= path_search(substr(filename,1,length(filename)-1));
 *          st('-f 'pcode_offset sourcefilename);
 * </pre>
 * @categories Miscellaneous_Functions
 */
_str error_pos(_str cmdline);


/**
 * Performs find first, find next directory search.
 *
 * @param   name_prefix_options  has the following syntax:
 *          {<i>name_prefix</i>  | ['-' | '+' <i>option_letters</i>]}
 * <p>
 * When prefix match is on, file names with prefix matching
 * <i>name_prefix</i> are returned (the prefix "abc" matches "abcd" and "abce").
 * When prefix match is off, a normal directory search is performed for file
 * names matching name_prefix.  If any wild card characters such as '*' or '?'
 * are present in <i>name_prefix</i>, prefix matching is ignored.
 * <p>
 * <i>option_letters</i>  may be:
 * <DL compact style="margin-left:20pt;">
 *   <DT>H        <DD>Include hidden files.  Defaults to off. On
 *   UNIX this option is ignored.  This option is always turned
 *   on under Windows if the "Show all files" explorer option is
 *   set.
 *   <DT>S        <DD>Include system files.  Defaults to off.  Ignored by UNIX version.
 *    This option is always turned on under Windows if the "Show all
 *   files" explorer option is set.
 *   <DT>D        <DD>Include directory files.  Defaults to on.
 *   <DT>P        <DD>Prefix match.  Defaults to on.
 *   <DT>T        <DD>Tree list.  Defaults to off.
 *   <DT>U        <DD>UNIX dot files.  Defaults to on.
 *   <DT>X        <DD>Exclude non-directory files.  Defaults to off.
 *   <DT>V        <DD>Verbose match.  Defaults to off.  When on, string returned is in the
 *   same format as the file manager file list except that no path is included.
 *   Column constants in "slick.sh" may be used to parse out name, file size,
 *   date, time, and attributes.
 *   <DT>G        <DD>List registered data sets.  This option is ignored for all platforms
 *   except OS/390.
 *   <DT>N        <DD>Stat of data sets.  By default, no trailing slash is appended to
 *   partitioned data sets (directories).  We have this default mainly due to the
 *   fact that this feature can cause a hang.  Use this option when you have to
 *   differentiate files from directories.  This option is ignored for all
 *   platforms except OS/390.
 *   <DT>Z        <DD>Return data set member info in the same format as ISPF. This option is
 *   ignored for all platforms except OS/390.
 *   <DT>DIR_SIZE_COL
 *   <DT>DIR_SIZE_WIDTH
 *   <DT>DIR_DATE_COL
 *   <DT>DIR_DATE_WIDTH
 *   <DT>DIR_TIME_COL
 *   <DT>DIR_TIME_WIDTH
 *   <DT>DIR_ATTR_COL
 *   <DT>DIR_ATTR_WIDTH
 *   <DT>DIR_FILE_COL
 * </DL>
 * <p>
 * There is an R option for read only files which defaults to off.
 * However, read only files will always be included in file matching due to
 * operating system limits.
 * <P>
 * @param find_first  A non-zero value for <i>find_first</i>, begins a new directory search.
 * If <i>find_first</i> is zero, the next matching file name is returned.  '' is
 * returned if no match is found and <b>rc</b> is set to the error code.  Search
 * is not case sensitive except for file systems like UNIX which are case
 * sensitive.  If a directory is found, the name returned ends with a backslash.
 *
 * @example
 * <pre>
 *           // Find all C source files in the current directory.  '-P' turns
 *           // off prefix match.
 *           //  No directories will be found since the D switch is not on.
 *           filename= file_match('*.c -P',1);         // find first.
 *           for (;;) {
 *               if (filename=='=' )  break;
 *               messageNwait('name found='filename);
 *               // Be sure to pass filename with correct path.
 *               // Result filename is built with path of given file name.
 *               filename= file_match(filename,0);       // find next.
 *           }
 *
 *            // find out if the file "junk" is read only
 *            if (pos('R',substr("junk",DIR_ATTR_COL,DIR_ATTR_WIDTH)) ) {
 *                 message('File "junk" is read only');
 *            } else {
 *                 message('File "junk" is NOT read only');
 *            }
 * </pre>
 * @see find_index
 * @see name_match
 * @see buf_match
 * @see path_search
 * @categories File_Functions
 */
_str file_match(_str name_prefix_options, int find_first);

/**
 * @return Returns name table index to name of type name_t.
 *         0 is returned if a match is not found.  A name type match
 *         is considered if  (name_t & name_type(index)) is true.
 *         Search is case sensitive unless one of the flags
 *         MODULE_TYPE, PICTURE_TYPE, or IGNORECASE_TYPE is given.
 *         When one of the flags MODULE_TYPE or PICTURE_TYPE is given,
 *         search is case sensitive for file systems like UNIX which is
 *         case sensitive.  The search is always case insensitive when
 *         the IGNORECASE_TYPE flag is given.  All underscore characters
 *         in name are converted to dash characters before searching
 *         takes place.
 *
 * @param name  symbol name to search for
 * @param name_type_flags
 *        The name type flags are listed in the file "slick.sh".
 *        <DL compact>
 *        <DT>PROC_TYPE      <DD style="marginleft:90pt">Matches global function
 *        <DT>VAR_TYPE       <DD style="marginleft:90pt">Matches global variable
 *        <DT>EVENTTAB_TYPE  <DD style="marginleft:90pt">Matches event table
 *        <DT>COMMAND_TYPE   <DD style="marginleft:90pt">Matches command
 *        <DT>CLASS_TYPE     <DD style="marginleft:90pt">Matches class name
 *        <DT>INTERFACE_TYPE <DD style="marginleft:90pt">Matches interface name
 *        <DT>STRUCT_TYPE    <DD style="marginleft:90pt">Matches struct name
 *        <DT>CONST_TYPE     <DD style="marginleft:90pt">Matches const name
 *        <DT>ENUM_TYPE      <DD style="marginleft:90pt">Matches enumerated type
 *        <DT>MODULE_TYPE    <DD style="marginleft:90pt">Matches module
 *        <DT>PICTURE_TYPE   <DD style="marginleft:90pt">Matches picture.
 *        <DT>BUFFER_TYPE    <DD style="marginleft:90pt">Matches buffer scope variable
 *        <DT>OBJECT_TYPE    <DD style="marginleft:90pt">Matches any type of dialog box template.
 *        Use the oi2type to build the correct object flags.  See example below.
 *        <DT>MISC_TYPE      <DD style="marginleft:90pt">Matches miscellaneous.
 *        <DT>IGNORECASE_TYPE<DD style="marginleft:90pt">Perform case insensitive search.
 *        </DL>
 *
 * @example
 * <PRE>
 * // Call a global function by index
 * index=find_index("gui_open",COMMAND_TYPE);
 * call_index(index);
 *
 * // Find the Calculator dialog box template.
 * index=find_index("_calc_form",oi2type(OI_FORM));
 * if (index) {
 *      messageNwait("Found it");
 * } else {
 *      messageNwait("Did not find it");
 * }
 * // Some properties can be retrieved by the name table index.  However, none
 * // can be set unless the dialog box is displayed.
 * messageNwait("Dialog box caption is "index.p_caption);
 *
 * // Display the dialog box modelessly
 * wid=show(index); // show(name_name(index)) also works
 * // wid is the window id or instance handle for this dialog box.  We can use this to change
 * // the caption
 * wid.p_caption="Changed the caption";
 * </PRE>
 *
 * @see name_match
 * @see name_name
 * @see name_type
 * @see name_info
 * @see call_index
 * @see insert_name
 * @see set_name_info
 * @see delete_name
 * @see oi2type
 * @see replace_name
 *
 * @categories Names_Table_Functions
 */
int find_index(_str name, int name_type_flags);


/**
 * @return Returns name table index of the name with prefix matching
 *         name_prefix and where (name_t & name_type(index)) is true.
 *         A non-zero value for find_first, begins a new search.  If
 *         find_first is zero, the next matching index is returned.
 *         0 is returned if no match is found.  Search is case sensitive
 *         unless one of the flags MODULE_TYPE, PICTURE_TYPE, or
 *         IGNORECASE_TYPE is given.  When one of the flags MODULE_TYPE
 *         or PICTURE_TYPE is given, search is case sensitive for file
 *         systems like UNIX which is case sensitive.  The search is
 *         always case insensitive when the IGNORECASE_TYPE flag is given.
 *         Underscores in name_prefix are translated to dashes before
 *         search takes place.
 *
 * @param name_prefix      Symbol name prefix to search for
 * @param find_first       Find first match (true) or next match?
 * @param name_type_flags
 *        The name type flags are listed in the file "slick.sh".
 *        <DL compact>
 *        <DT>PROC_TYPE      <DD style="marginleft:90pt">Matches global function
 *        <DT>VAR_TYPE       <DD style="marginleft:90pt">Matches global variable
 *        <DT>EVENTTAB_TYPE  <DD style="marginleft:90pt">Matches event table
 *        <DT>COMMAND_TYPE   <DD style="marginleft:90pt">Matches command
 *        <DT>CLASS_TYPE     <DD style="marginleft:90pt">Matches class name
 *        <DT>INTERFACE_TYPE <DD style="marginleft:90pt">Matches interface name
 *        <DT>STRUCT_TYPE    <DD style="marginleft:90pt">Matches struct name
 *        <DT>CONST_TYPE     <DD style="marginleft:90pt">Matches const name
 *        <DT>ENUM_TYPE      <DD style="marginleft:90pt">Matches enumerated type
 *        <DT>MODULE_TYPE    <DD style="marginleft:90pt">Matches module
 *        <DT>PICTURE_TYPE   <DD style="marginleft:90pt">Matches picture.
 *        <DT>BUFFER_TYPE    <DD style="marginleft:90pt">Matches buffer scope variable
 *        <DT>OBJECT_TYPE    <DD style="marginleft:90pt">Matches any type of dialog box template.
 *        Use the oi2type to build the correct object flags.  See example below.
 *        <DT>MISC_TYPE      <DD style="marginleft:90pt">Matches miscellaneous.
 *        <DT>IGNORECASE_TYPE<DD style="marginleft:90pt">Perform case insensitive search.
 *        </DL>
 *
 * @example
 * <PRE>
 * // COMMAND_TYPE is defined in "slick.sh"
 * name_t= COMMAND_TYPE;
 * name_prefix='p';           // Find names that start with p
 * index= name_match(name_prefix,1,name_t);   // Find first
 * // Press Ctrl+Break to break a macro during a messageNwait
 * for (;;) {
 *     if (!index ) break;
 *     messageNwait(''name found='name_name(index));
 *     index= name_match(name_prefix,0,name_t) // Find next
 * }
 * </PRE>
 *
 * @see find_index
 * @see buf_match
 * @see file_match
 *
 * @categories Names_Table_Functions
 *
 */
int name_match(_str name_prefix,  int find_first ,int name_type_flags=~0&~IGNORECASE_TYPE);
/**
 * @return Returns an integer name type corresponding to name table entry
 * <i>index</i>.  If <i>index</i> is not an index to a valid name, 0 is
 * returned.  All valid types are defined in "slick.sh"
 *
 * @example
 * <pre>
 *          index= find_index("find_next");
 *          message('find_next name type is 'name_type(index));
 * </pre>
 *
 * @see find_index
 * @see name_match
 * @see name_name
 * @see name_info
 * @see call_index
 * @see insert_name
 * @see set_name_info
 * @see delete_name
 * @see replace_name
 *
 * @categories Names_Table_Functions
 *
 */
int name_type(int index);

/**
 * @return Returns name corresponding to name table entry <i>index</i>.  If
 * <i>index</i> is not an index to a valid name, '' is returned.  Names are
 * returned in lower case.
 *
 * @example
 * <pre>
 *          index= name_match("repeat_se")
 *          message 'possible match of repeat_se is 'name_name(index)
 * </pre>
 *
 * @see find_index
 * @see name_match
 * @see name_type
 * @see name_info
 * @see call_index
 * @see insert_name
 * @see set_name_info
 * @see delete_name
 * @see replace_name
 *
 * @categories Names_Table_Functions
 *
 */
_str name_name(int index);
/**
 * This function is used when defining a command to return the information
 * string specified in the command definition.  See <b>name_info Attributes</b>
 * for more information.
 *
 * @return Returns name information corresponding to name table
 * <i>index</i>.  If <i>index</i> is not an index to a valid name
 * or name has no information, '' is returned.  For commands,
 * the name information is a list of the types of arguments the
 * command accepts and objects for which the command is valid.
 *
 * @example
 * <pre>
 * _command mycommand() name_info(','VSARG2_REQUIRES_EDITORCTL |
 *                                    VSARG2_READ_ONLY)
 * {
 *    index= find_index("mycommand", COMMAND_TYPE);
 *    message('Name info for this command is 'name_info(index));
 * }
 * </pre>
 *
 * @see find_index
 * @see name_match
 * @see name_name
 * @see name_type
 * @see call_index
 * @see insert_name
 * @see set_name_info
 * @see delete_name
 * @see name_info_arg2
 * @see replace_name
 *
 * @categories Names_Table_Functions
 *
 */
_str name_info(int index);
/**
 * Replace info, corresponding to name table <i>index</i>.  If
 * <i>index</i> is not a valid index, the interpreter is halted.  Info may
 * be changed for any name type.
 *
 * @return Returns 0 if successful.  Otherwise,
 * INTERPRETER_OUT_OF_MEMORY_RC is returned.  Pending
 * message set.
 *
 * @see find_index
 * @see name_match
 * @see name_name
 * @see name_type
 * @see name_info
 * @see call_index
 * @see insert_name
 * @see delete_name
 * @see replace_name
 *
 * @categories Names_Table_Functions
 *
 */
int set_name_info(int index,_str info);


/**
 * Deletes unused items in the names table.  Global function (including command)
 * names are deleted if there are no references to the function.  Global variables
 * are deleted if there is no reference to the variable.  Using the index returned
 * by <b>find_index</b> to call a function or set a variable DOES NOT count as a
 * reference.  Pictures are deleted if there are no references to the picture and
 * the picture name does not start with an underscore.
 *
 * @categories Names_Table_Functions
 */
void _delete_unused();

/**
 * Write out the current state of the Slick-C interpreter to the given 
 * file path.  The current state includes all global variables, names 
 * table entries, loaded modules, and loaded DLLs.  It does not include 
 * the current function stack, locals, or user data stored in Slick-C 
 * dialogs and controls. 
 * 
 * @param path File to save state file to.
 * 
 * @return 0 on success, <0 on error. 
 *  
 * @categories Names_Table_Functions
 */
int _write_state(_str path);

/**
 * Removes name entry corresponding to name table <i>index</i>.
 * If <i>index</i> is not a valid index, the interpreter is halted.
 * The internal name types for procedure, variable, and module, may
 * not be deleted.
 *
 * @see  find_index
 * @see name_match
 * @see name_name
 * @see name_type
 * @see name_info
 * @see call_index
 * @see insert_name
 * @see set_name_info
 * @see replace_name
 * @categories Names_Table_Functions
 */
void delete_name(int index);
/**
 * Inserts <i>name</i> into names table with type and optional info.  Valid
 * types are listed in "slick.sh" and have the suffix "_TYPE".  Internal name
 * types may not be inserted except for PICTURE_TYPE and EVENTTAB_TYPE.  If the
 * <i>type</i> given is PICTURE_TYPE, <i>name</i> must be a filename.
 *
 * @return If successful, the index of the new name table entry is returned.
 * Otherwise 0 is returned and <b>rc</b> is set to INTERPRETER_OUT_OF_MEMORY_RC.
 * On error, message displayed.
 *
 * @see find_index
 * @see name_match
 * @see name_name
 * @see name_type
 * @see name_info
 * @see call_index
 * @see set_name_info
 * @see delete_name
 * @see _insert_name_list
 * @see replace_name
 *
 * @categories Names_Table_Functions
 *
 */
int insert_name(_str name, int type,_str info="",int copy_index=0);
/**
 * Replaces information for a name in the names table.  Valid types are
 * listed in "slick.sh" and have the suffix "_TYPE".  Internal name types
 * may not be inserted except for PICTURE_TYPE and
 * EVENTTAB_TYPE.  If the <i>type</i> given is PICTURE_TYPE,
 * <i>name</i> should be a filename.
 *
 * @return If successful, the index of the name table entry is returned.  Otherwise
 * a negative error code is returned.
 *
 * @see find_index
 * @see name_match
 * @see name_name
 * @see name_type
 * @see name_info
 * @see call_index
 * @see set_name_info
 * @see delete_name
 * @see _insert_name_list
 * @see insert_name
 *
 * @categories Names_Table_Functions
 *
 */
int replace_name(int index,_str name,_str info="",int copy_index=0);
/**
 * @return Returns the binary string representation of the key named
 * <i>string_constant</i>.  The binary key string returned is the same as the
 * binary key string returned by the GET_EVENT and TEST_EVENT built-in
 * functions.
 *
 * @example
 * <pre>
 *          key=get_event();
 *          if (key:==name2event('C-S')) {
 *              ...
 *          }
 * </pre>
 *
 * @see get_event
 * @see test_event
 * @see last_event
 * @see event2name
 * @see event2index
 * @see index2event
 * @see list_bindings
 * @see name2event
 * @see call_key
 * @see eventtab_index
 *
 * @categories Keyboard_Functions
 *
 */
_str name2event(_str name);

/**
 * @return  Returns the event name corresponding to the binary <i>event</i>
 * string.  <i>Event</i> may have been returned by <b>get_event</b>(),
 * <b>test_event</b>(), and <b>last_event</b>() into a event name.
 *
 * @param  option defaults to 'S' and may be one of the following:
 * <DL compact style="margin-left:20pt;">
 *    <DT>'S'  <DD>Return Slick-C&reg; source code event name.
 *    <DT>'L'  <DD>Return long menu bar event name.
 *    <DT>'C'  <DD>Return condensed menu bar event name.
 * </DL>
 * @example
 * <pre>
 *          key=get_event()
 *           message 'The key pressed was 'event2name(key)
 * </pre>
 * @see  get_event
 * @see test_event
 * @see last_event
 * @see call_key
 * @see event2index
 * @see index2event
 * @see list_bindings
 * @see name2event
 * @see eventtab_index
 * @categories Keyboard_Functions
 */
_str event2name(_str event,_str option="S");

/**
 * @return  Returns the event index corresponding to the binary <i>event</i>
 * string given.  The event index returned by this function may be used by the
 * functions <b>eventtab_index</b>, or <b>index2event</b>. <i>event </i>may have
 * been returned by <b>get_event</b>(), <b>test_event</b>(), and
 * <b>last_event</b>().
 * @example
 * <pre>
 *         key=get_event();
 *         root_keys= find_index('root_keys',EVENTTAB_TYPE);
 *         index=eventtab_index(root_keys,p_mode_eventtab,EVENT2INDEX(key));
 *         // name could be type nothing, proc, command, macro, or key table.
 *         message('Key is bound to 'name_name(index));
 * </pre>
 * @see  get_event
 * @see test_event
 * @see last_event
 * @see call_key
 * @see event2name
 * @see index2event
 * @see list_bindings
 * @see name2event
 * @see eventtab_index
 * @categories Keyboard_Functions
 */
int event2index(_str string);
/**
 * Converts key table <i>index</i> into the binary string representation of
 * keys returned by <b>get_event</b>(), <b>test_event</b>, and
 * <b>last_event</b>().
 *
 * @see get_event
 * @see test_event
 * @see last_event
 * @see call_key
 * @see event2name
 * @see event2index
 * @see list_bindings
 * @see name2event
 * @see eventtab_index
 *
 * @categories Keyboard_Functions
 *
 */
_str index2event(int index);



/**
 * Finds all bindings to a name table index.
 *
 * @categories Keyboard_Functions
 * @param keytab_index  Names table index to event table.
 * @param list    (Output) List of events and bindings
 * @param match_index
 *               Index of command to find.
 *
 * @example
 * <pre>
 * // For a more complete example, see at source for append_key_bindings
 * // in "bind.e".
 * match_index=find_index("gui_find",COMMAND_TYPE);
 * VSEVENT_BINDING list[];
 * list_bindings(_default_keys,list,match_index);
 * if (list._length()>0 ) {
 *     message("Found bindings for this command");
 * }
 * </pre>
 *
 * @see get_event
 * @see test_event
 * @see last_event
 * @see call_key
 * @see event2name
 * @see event2index
 * @see index2event
 * @see eventtab_index
 * @see name2event
 */
void list_bindings(int &keytab_index,  VSEVENT_BINDING (&list)[], int match_index=0);

/**
 *
 * Returns name table index bound to the key corresponding
 * to <i>key_index</i>.  The fourth parameter may be set to "U", to return the
 * index of the event table used.  If the mode event table has a non zero
 * binding for the key corresponding to <i>key_index</i> this index is returned.
 * Otherwise the root key table binding is returned.
 * @example
 * <pre>
 * key=get_event();
 * root_keys_index= find_index('default-keys',EVENTTAB_TYPE);
 * index=eventtab_index(root_keys_index,p_mode_eventtab,event2index(key));
 * // Display information about the binding to this key.
 * message('name='name_name(index)' type='name_type(name));
 * </pre>
 * @categories Keyboard_Functions
 */
int eventtab_index(int root_keys_index, int mode_keys_index, int key_index,_str option="");
/**
 * This functions binds a command, procedure, or event table to an event or range of events.
 *
 * @categories Keyboard_Functions
 * @param eventtab_index
 *                   is an index to an event table which is simply array of
 *                   VSEVENT_BINDING structures.
 *                   array of integers.
 * @param key_index  Integer representation of the key.  Use event2index() to convert
 *                   a key string to a key index.
 * @param index      Index into the names table of the command, procedure, or event table.
 * @param key_index2 Integer representation of the key.  Use event2index() to convert
 *                   a key string to a key index.  When specified, key_index must be greater
 *                   than or equal to key_index2. There are some useful special range key names.
 *
 * <dl>
 * <dt>VSEV_RANGE_FIRST_CHAR_KEY<dd>First character key.  This is character code 0. No shift flags may be combined with this.
 * <dt>VSEV_RANGE_LAST_CHAR_KEY<dd>Last character key.  This is character code 0x1ffffff.  No shift flags may be combined with this.
 * <dt>VSEV_RANGE_FIRST_NONCHAR_KEY<dd>First non unicode character key. No shift flags may be combined with this.
 * <dt>VSEV_ALL_RANGE_LAST_NONCHAR_KEY<dd>Last non unicode character key with all shift flags.
 * <dt>VSEV_RANGE_FIRST_MOUSE<dd>First mouse event.  Shift flags may be combined with this.
 * <dt>VSEV_RANGE_LAST_MOUSE<dd>Last mouse event. Shift flags may be combined with this.
 * <dt>VSEV_ALL_RANGE_LAST_MOUSE<dd>Last mouse event with all shift flags.
 * <dt>VSEV_RANGE_FIRST_ON<dd>First ON event. No shift flags may be combined with this.
 * <dt>"VSEV_RANGE_LAST_ON<dd>Last ON event. No shift flags may be combined with this.
 * </dl>
 *
 * @example
 * <pre>
 * // "vsevents.sh" needs to be included.
 * index=find_index('cmdline_toggle');
 *
 * root_eventtab_index=find_index('default_keys',EVENTTAB_TYPE);
 * // Bind the fundamental mode escape key to command toggle.
 * // The root and mode key tables both point to the "default_keys" key
 * // table when in fundamental mode.
 * set_eventtab_index(root_eventtab_index,event2index(ESC),index);
 *
 * // Unbind all character keys. This effects keys
 * // like a-z, punctuation, and foreign language characters.
 * // Keys like Alt+A which are not unicode characters are not effected.
 * set_eventtab_index(root_eventtab_index,VSEV_RANGE_FIRST_CHAR_KEY,0,VSEV_RANGE_LAST_CHAR_KEY)
 *
 * // Unbind all non-character keys including keys like Enter, Backspace, Ctrl+Shift+Alt+Enter, Alt+A
 * set_eventtab_index(root_eventtab_index,VSEV_RANGE_FIRST_NONCHAR_KEY,0,VSEV_ALL_RANGE_LAST_NONCHAR_KEY)
 *
 * // Unbind all mouse events in any shift key combination.
 * set_eventtab_index(root_eventtab_index,VSEV_RANGE_FIRST_MOUSE,0,VSEV_ALL_RANGE_LAST_MOUSE)
 *
 * // Unbind all Ctrl+mouse events.
 * set_eventtab_index(root_eventtab_index,VSEV_RANGE_FIRST_MOUSE|VSEVFLAG_CTRL,0,VSEV_ALL_RANGE_LAST_MOUSE|VSEVFLAG_CTRL)
 *
 * </pre>
 */
void set_eventtab_index( int eventtab_index, int key_index, int index,int key_index2=VSEV_NULL);


/**
 *
 * Returns and optionally sets the inheritance event table
 * of an event table.  This function allows you to link one event table to
 * another to create inheritance.  When an event handler does not exist in one
 * event table, the next event is checked for an event handler and the next
 * until there are no more event tables in the chain.
 * @categories Keyboard_Functions
 */
int eventtab_inherit(int etab_index, int new_etab_index=-1);
/**
 * @return Returns index into the name table of the module to which the
 * procedure or command, corresponding to <i>index,</i> is linked.  If
 * <i>index</i> is invalid or does not correspond to a procedure or command, 0
 * is returned.
 *
 * @example
 * <pre>
 *          index=find_index('upcase_filter');
 *          if (!index_callable(index) ) {
 *               message('upcase_filter name in name table but not linked');
 *          } else {
 *               message('upcase_filter is defined in module
 * 'name_name(index));
 *          }
 * </pre>
 *
 * @see call_index
 *
 * @categories Names_Table_Functions
 *
 */
int index_callable(int index);
/**
 * @return Returns index of current signal handler for specified signal.  Currently
 * this function only supports the 'B'=Ctrl+Break signal.  Specifying the
 * index parameter will set the signal handler.  Valid values for index
 * must be less than or equal to 0.  If index is 0, the default signal handler
 * is used which halts Slick-C&reg; batch/macros that are running.  If index is
 * less than 0, the Ctrl+break signal is ignored.
 *
 * @categories Keyboard_Functions
 *
 */
int signal_handler(_str option,int index=-1);


/**
 * Registers a DLL command or function that can be called from the
 * Slick-C&reg; macro.  This function is identical to the vsDLLExport
 * function except that you always need to specify the dll module
 * the function is contained in.   See <b>vsDLLExport</b> for
 * information on parameters.
 * @categories Macro_Programming_Functions
 */
int _dllload(_str DllFilename ,_str option='L');


/**
 * Registers a DLL command or function that can be called from the
 * Slick-C&reg; macro.  This function is identical to the vsDLLExport
 * function except that you always need to specify the dll module
 * the function is contained in.   See <b>vsDLLExport</b> for
 * information on parameters.
 * @categories Miscellaneous_Functions
 */
int _dllexport(_str FuncProto ,_str NameInfo="",int arg2=0);

/**
 * @return Returns n<sup>p</sup> -- 'n' raised to the power of 'p'. 
 *
 * @categories Miscellaneous_Functions
 */
double pow(double n,double p);

/**
 * Convert the given function name index (see {@link find_index}) 
 * to a function pointer. 
 * 
 * @param index      name index for function type 
 * @return pointer to function corresponding to this name 
 *  
 * @see name_match
 * @see call_index 
 * @see find_index 
 *
 * @categories Names_Table_Functions
 */
typeless name_index2funptr(int index);

/**
 * @return Returns <b>true</b> if <i>t</i> is a valid pointer to a function
 * that can be called in the Slick-C&reg; syntax (*t)(...).
 *
 * @categories Miscellaneous_Functions
 *
 */
boolean _isfunptr(typeless t);
/**
 * @return Returns non-zero value if <i>string</i> is a valid number of any
 * kind, including floating point.
 *
 * @categories String_Functions
 *
 */
boolean isnumber(_str number);
/**
 * @return Returns <b>true</b> if <i>string</i> is a valid signed or
 * unsigned integer.  If <i>string</i> is floating point number, 0 is returned.
 *
 * @categories String_Functions
 *
 */
boolean isinteger(_str string);

/** 
 * Dump the current interpreter stack to the debug window, 
 * or the log file.
 * 
 * @param dumpToFile          dump the stack the log file
 * @param dumpToScreen        dump the stack to the debug window
 * @param ignoreNStackItems   ignore 'n' items on top of stack 
 *  
 * @categories Miscellaneous_Functions
 */
void _StackDump(int dumpToFile=0,int dumpToScreen=1,int ignoreNStackItems=0);

/** 
 * Dump the contents of the given Slick-C variable to the debug
 * window, or the log file. 
 *  
 * @param v                   variable to display contents of
 * @param caption             caption to print out for variable
 * @param dumpToScreen        dump the stack to the debug window
 * @param dumpToFile          dump the stack the log file
 *  
 * @categories Miscellaneous_Functions
 */
void _dump_var(var v,_str caption='',int dumpToScreen=1,int dumpToFile=0);


/**
 * @return Returns a non-zero value if the key specified is currently down.
 * One of the following keys may be specified:
 *
 * <ul>
 * <li>CTRL</li>
 * <li>SHIFT</li>
 * </ul>
 *
 * <p>This function is typically used when get_event() returns the
 * on_keystatechange event.</p>
 *
 * @example
 * <pre>
 * defmain()
 * {
 *      mou_mode(1);
 * OuterLoop:
 *      for (;;) {
 *          event=get_event();
 *          switch( event ) {
 *          case ESC:
 *               break OuterLoop;
 *           case ON_KEYSTATECHANGE:
 *               if (_IsKeyDown(CTRL) ){
 *                    message("CTRL is down");
 *                } else {
 *                     message("CTRL is not down");
 *                }
 *            }
 *       }
 *       mou_mode(0);
 *            }
 * </pre>
 *
 * @categories Keyboard_Functions
 *
 */
int _IsKeyDown(_str ShiftKeyEvent);

/**
 * Test if a key or mouse event is available. 
 *
 * @param flags  One or more of EventPendingFlags.
 *
 * @return true if event is available.
 *
 * @see get_event
 * @see last_event
 * @see call_key
 * @see event2name
 * @see event2index
 * @see index2event
 * @see list_bindings
 * @see name2event
 * @see eventtab_index
 *
 * @categories Keyboard_Functions
 *
 */
boolean _IsEventPending(int flags);

/**
 * Remove all key events from input queue.
 *
 * @categories Keyboard_Functions
 */
void _FlushPendingKeys();

_str _MultiByteToUTF8(_str string,int codePage=VSCP_ACTIVE_CODEPAGE);
/**
 * @return Converts the UTF-8 string given to the code page specified and returns
 * the result.  If SlickEdit is not running in UTF-8 mode (
 * _UTF8()==0 ), this function returns the input string unchanged.
 *
 * @categories Unicode_Functions
 *
 */
_str _UTF8ToMultiByte(_str string,int codePage=VSCP_ACTIVE_CODEPAGE);
/**
 * @return Returns the column position of the beginning of the character which
 * contains the byte at column <i>col</i>.
 *
 * @param string  Input string to perform operation on. When
 * SlickEdit is running in UTF-8 mode,
 * this string is UTF-8.  Otherwise, this string
 * is SBCS/DBCS for the active code page.
 *
 * @param col  Column position within string.
 * 1..length(<i>string</i>)
 *
 * @param CharLen Set to length of entire character at position
 * <i>col</i>.
 *
 * @param BeginComposite   When true, column position returned is the
 * beginning of a composite character (one or
 * more UTF-8 sequences) sequence.
 * Otherwise, of a UTF-8 character sequences
 * is returned.  This parameter is ignored when
 * SlickEdit is not running in UTF-8
 * mode.
 *
 * @categories String_Functions
 *
 */
int _strBeginChar(_str string,int col,int &charLen=0,boolean beginComposite=true);

/**
 *
 * @return Returns non-zero value if the active code page contains
 *         DBCS (double byte characters).
 *
 * @categories Miscellaneous_Functions
 */
int _dbcs();

/**
 * @return Returns SHIFTJIS_CHARSET if the font specified contains Japanese
 * characters.
 *
 * @param options is a string of zero or more of the following option
 * letters:
 * <dl>
 * <dt>F</dt><dd>Display fixed fonts only.</dd>
 * <dt>P</dt><dd>Display printer fonts.</dd>
 * <dt>S</dt><dd>(Default) Display screen fonts.</dd>
 * </dl>
 *
 * <p>The S and P options may not both be specified.</p>
 *
 * @appliesTo Label, Text_Box, Edit_Window, Editor_Control, Frame,
 * Command_Button, Radio_Button, Check_Box, Combo_Box, List_Box, Drive_List,
 * File_List_Box, Directory_List_Box
 *
 * @categories Check_Box_Methods, Combo_Box_Methods, Command_Button_Methods,
 * Directory_List_Box_Methods, Drive_List_Methods, Edit_Window_Methods,
 * Editor_Control_Methods, File_List_Box_Methods, Frame_Methods, Label_Methods,
 * List_Box_Methods, Radio_Button_Methods, Text_Box_Methods
 *
 */
int _GetFontCharSet(_str FontName, _str FontSize, _str options="");


/**
 * @return  Returns <b>true</b> if the 1 byte length string <i>ch</i> is a
 * valid first character of a double byte character (DBCS).  Always return
 * <b>false</b>, if the operating system is not in Japanese mode.
 * @example
 * <pre>
 *         // IF there are at least two bytes left in the current line and the first byte is
 *         // a dbcs lead byte.
 *         if (<b>p_col</b><<b>_text_colc</b>() && _dbcsIsLeadByte(get_text())) {
 *              p_col+=2;  // Move cursor over double byte character
 *         } else {
 *              p_col+=1;  // Move cursor over single byte character
 *         }
 * </pre>
 * @see _dbcs
 * @see _dbcsStartOfDBCS
 * @see _dbcsSubstr
 *
 * @categories String_Functions
 */
boolean _dbcsIsLeadByte(_str ch);
int _dbcsAssociateFont(_str toFontName,_str fromFontName);


int _getpwnam(_str name,passwd &passwd);

/**
 * Returns value for system-metric <code>sm</code>. 
 *
 * @param sm may be one of VSM_* constants 
 * defined in "slick.sh": 
 * <p>The following constants are supported by all platforms
 * <pre> 
 *    VSM_TOOLBAR_HANDLE_EXTENT
 * </pre> 
 * <p>All other constants are only supported by Windows
 *
 * @return System-metric value, 0 if system-metric unknown. 
 *  
 * @categories Miscellaneous_Functions
 *
 */
int GetSystemMetrics(int sm);

int _pipe_process(int &infh,int &outfh,int &pid,_str command,_str options="",int (*pfnCallback)(int reason,int infh,int outfh,int pid));
int _kill(int process_id,int signum=9);
extern int _file_open(_str pszFilename,int option);
extern int _file_close(int fh);
int _file_read(int fh,_str &data,int Nofbytes);
int _file_write(int fh,_str data);

/**
 * @return Returns the host name of the current machine. 
 *
 * @categories Miscellaneous_Functions
 *
 */
_str _gethostname();

/**
 * Get logged in user name.
 *
 * @return Logged in user name.
 */
_str _GetUserName();

/**
 * @return Returns the id of the window which currently has the focus.  Zero is
 * returned if a Slick-C&reg; window does not have focus.
 *
 * @see _set_focus
 *
 * @categories Miscellaneous_Functions
 *
 */
int _get_focus();

/**
 * @return Returns directory with trailing backslash which contains
 * "system.ini".
 *
 * @appliesTo All_Window_Objects
 *
 * @categories File_Functions
 *
 */
_str _get_windows_directory();

/**
 * @return
 * Returns 1 if running under WIN32s on Windows 3.x (no longer supported).
 * Returns 2 if running under Windows 95/98.  Otherwise 0 is returned.
 *
 * @see machine
 *
 * @categories Miscellaneous_Functions
 *
 */
int _win32s();


/**
 * Displays help.  This function is not available in the UNIX version.
 *
 * @return Returns 0 if successful.
 *
 * @param option may be one of the following constants defined in "slick.sh":
 *
 * <dl>
 * <dt>HELP_FORCEFILE</dt><dd>Load
 * <i>help_filename</i>
 * specified.  If the help
 * file is already loaded,
 * the help window
 * receives the focus.
 * <i>help_item</i> is
 * ignored.</dd>
 *
 * <dt>HELP_CONTENTS</dt><dd>Display table of contents
 * help item of
 * <i>help_filename</i>.
 * <i>help_item</i> is
 * ignored.</dd>
 *
 * <dt>HELP_KEY   Display help on
 * <i>help_item</i> from
 * help file
 * <i>help_filename</i>.</dd>
 *
 * <dt>HELP_PARTIALKEY</dt><dd>Displays Search dialog
 * box which lists help
 * items and allows you to
 * enter a help item.   This
 * constant is supported by
 * Windows only and is
 * translated to
 * HELP_KEY for X
 * Windows.</dd>
 * </dl>
 *
 * <p>Windows, Windows 95/98, and Windows NT help files have the
 * extension ".HLP".  <i>help_filename</i> specifies one or more help
 * files separated with plus signs.</p>
 *
 * @example
 * <pre>
 * // Windows example.  Display help on SetFocus function.
 * _syshelp("win31wh.hlp+mscxx.hlp", "SetFocus");
 * </pre>
 *
 * @see wh
 * @see help
 *
 * @categories Miscellaneous_Functions
 *
 */
int _syshelp(_str filename,_str keyword,int help_option= -1);

/**
 * Supported under Windows, Windows 95/98, and Windows NT only.  Sends a
 * system topic DDE command to the server specified.<i></i>
 *
 * @param server_name
 * @param command
 * @param topic
 * @param item
 * @param milli_timeout
 *
 * @return
 * @example
 * <pre>
 *       // Invoke a second copy of SlickEdit  by invoking the editor with
 *       // the +new invocation option.  Then execute the command below to
 *       // set a dde command to the first instance of SlickEdit.
 *       _ddecommand("SlickEdit", "dde -mdi  -refresh edit c:\\junk");
 *       // If you use single instead of double quotes above you don't need
 *       // the two backslashes.  Now bring the SlickEdit window to the
 *       // front to show the user.
 *       _set_foreground_window("SlickEdit");
 *
 *       // Get help on MessageBox from Microsoft VC++
 *       _ddecommand("MSIN","KeywordLookup(`MessageBox')","vcbks40.mvb");
 * </pre>
 * @categories Miscellaneous_Functions
 */
int _ddecommand(_str server_name,_str command ,_str topic="System",_str item="",int milli_timeout=15000);


/**
 * Searches and activates if found, the operating system window with the
 * class <i>class_name</i>.  The <i>title</i> of the window is checked
 * as well if the <i>title </i>parameter is given.
 *
 * @return Returns 0 if successful.
 *
 * @categories Miscellaneous_Functions
 *
 */
int _set_foreground_syswindow(_str class_name,_str title="");

/**
 * @param cancel
 * @param options Set to 'T' to process timer events.
 *
 * <p>Reads and dispatches all system messages until there are no more
 * messages or the variable <i>cancel_message_loop</i> becomes non-
 * zero.</p>
 *
 * <p>If options contains "T", timer events will be processed.</p>
 *
 * @example
 * <pre>
 * #include "slick.sh"
 * static  typeless gcancel
 * _command test()
 * {
 *     // Show the form modeless so there is no modal wait
 *     form1_wid=show('form1');
 *     disabled_wid_list=_enable_non_modal_forms(0,form1_wid);
 *     gcancel=0;
 *     for (;;) {
 *           // Read mouse, key, and all other events until none are left
 *           // or until the variable gcancel becomes true
 *           process_events(gcancel);
 *           if (gcancel) break;
 *     }
 *     _enable_non_modal_forms(1,0,disabled_wid_list);
 *     form1_wid._delete_window();
 * }
 * defeventtab form1;
 * cancel.lbutton_up()
 * {
 *      gcancel=1;
 * }
 * </pre>
 *
 * @categories Keyboard_Functions
 *
 */
void process_events(boolean &cancel,_str options="");
/**
 * Converts (maps) the <i>x</i> and <i>y</i> coordinates from the coordinate
 * space relative to the <i>from_wid</i> to the coordinate space relative to the
 * <i>to_wid</i>.   If <i>scale_mode </i> specifies the input and output scale
 * mode for the <i>x</i> and <i>y</i> coordinates.
 *
 * @param from_wid   Window to map coordinates from.
 * @param to_wid     Window to map coordinates to. 0 defaults to the desktop.
 * @param x          x-coordinate relative to from_wid.
 * @param y          y-coordinate relative to from_wid.
 * @param scale_mode (optional). Scale mode of the from/to windows. May be SM_PIXEL
 *                   or SM_TWIP. Defaults to SM_PIXEL.
 *
 * @see _lx2dx
 * @see _lx2lx
 * @see _dx2lx
 * @see _lxy2lxy
 * @see _lxy2dxy
 * @see _ly2dy
 * @see _ly2ly
 * @see _dy2ly
 *
 * @categories Miscellaneous_Functions
 *
 */
void _map_xy(int from_wid,int to_wid,int &x,int &y=0,int scale_mode=SM_PIXEL);

/**
 * 
 * 
 * @categories Window_Functions
 * @param name_prefix
 * @param find_first
 * @param options    is a string of zero or more of the following:
 *                   
 *                   <dl>
 *                   <dt>'I'</dt><dd>Windows with <b>p_visible</b> false will be returned.</dd>
 *                   <dt>'X'</dt><dd>Exact buffer name match instead of prefix matching.</dd>
 *                   <dt>'H'</dt><dd>Windows with (p_window_flags &
 *                   HIDE_WINDOW_OVERLAP) true will be returned.</dd>
 *                   <dt>'E'</dt><dd>Only windows with <b>p_edit</b> true will be returned.</dd>
 *                   <dt>'N'</dt><dd>Only windows with <b>p_edit</b> false will be returned.</dd>
 *                   <dt>'A'</dt><dd>Non-MDI edit window ids will be returned.  By default,
 *                   only MDI edit window ids are returned.</dd>
 *                   </dl>
 * @param buf_id     If !=-1, match this buffer id instead of the
 *                   name_prefix
 * @param findWindowOptions  If !=null, find a window tile with 
 *                           the specified string of options.
 *                           Only supported if Tab Groups are
 *                           supported by the MDI interface.
 *                           find_first paramter is ignored.
 *    <dl compact>
 *    <dt><b>VG</b> <dd>Match visible document tab of current
 *    tab group.
 *    <dt><b>VM</b> <dd>Match visible document tab of current
 *    MDI window.
 *    <dt><b>VA</b> <dd>Match visible document tab in any tab
 *    group
 *    <dt><b>G</b> <dd>Match document tab of current tab group.
 *    <dt><b>M</b> <dd>Match ocument tab of current MDI window.
 *    <dt><b>A</b> <dd>Match document tab in any tab group
 *    <dt><b>N</b> <dd>Use MDI next window order. This option is
 *    only useful when used in conjunction with smart next
 *    window to find the most recently referenced window. Only
 *    matches MDI child edit windows. All other options are
 *    ignored when this option is used.
 *    </dl>
 * 
 * @return Returns window id of window which has a buffer name
 *         (<b>p_buf_name</b>) with prefix matching <i>name_prefix</i>.  A
 *         non-zero value for <i>find_first</i>,  begins a new search.  If
 *         <i>find_first</i> is zero, the next matching window id is returned.  0
 *         is returned if no match is found.  Search is not case sensitive except
 *         for file systems like UNIX which are case sensitive.
 * @example 
 * <pre>
 * // Look for window displaying ".process" buffer.
 * wid=window_match('.process','xn');
 * </pre>
 * @see buf_match
 * @see name_match
 * @see file_match
 */
int window_match(_str name_prefix,int find_first,_str options="",int buf_id=-1,_str findWindowOptions=null);

/**
 * Cancels printing.  This function is intended to be called during
 * printing started with the _print function.
 *
 * @categories Miscellaneous_Functions
 *
 */
void _print_cancel();
/**
 * Runs the operating system <b>Print Setup dialog box</b>.
 *
 * @return Returns 0 if successful.
 *
 * @see printer_setup
 *
 * @categories Buffer_Functions
 *
 */
int _printer_setup(_str input_option,_str option,_str output_options);

/**
 * @return Returns non-zero value if the <i>font_name</i> given is a
 * scalable font.
 *
 * @param options is a string of zero or more of the following option
 * letters:
 * <dl>
 * <dt>F</dt><dd>Display fixed fonts only.</dd>
 * <dt>P</dt><dd>Display printer fonts.</dd>
 * <dt>S</dt><dd>(Default) Display screen fonts.</dd>
 * </dl>
 *
 * <p>The S and P options may not both be specified.</p>
 *
 * @see _insert_font_list
 * @see _choose_font
 * @see _font_form
 * @see _font_type
 *
 * @categories Miscellaneous_Functions
 *
 */
int _isscalable_font(_str font_name, _str options="S");


/**
 * This function is used by font dialog boxes.  The following font
 * type flags are returned:
 * <DL compact style="margin-left:20pt;">
 *    <DT>RASTER_FONTTYPE  <DD>Font is a raster font.
 *    <DT>DEVICE_FONTTYPE  <DD>Font is a printer font.
 *    <DT>TRUETYPE_FONTTYPE   <DD>Font is a true type font
 *    <DT>FIXED_FONTTYPE   <DD>Font is a fixed size
 * </DL>
 *
 * @param options a string of zero or more of the following option
 * letters:
 * <DL compact style="margin-left:20pt;">
 *    <DT>F<DD>This letter is ignored and is only here because it is used by other
 * font functions.
 *    <DT>P<DD>Get font type for print font <i>font_name</i>.
 *    <DT>S<DD>(Default) Display screen fonts.
 *
 * @see  _insert_font_list
 * @see _choose_font
 * @see _font_form
 * @see _isscalable_font
 * @categories Miscellaneous_Functions
 */
int _font_type(_str font_name, _str options="S");


/**
 * Displays the operating system specific <b>Font dialog box</b>.  We also have our
 * own Font dialog box  (<b>_font_form</b>).  The <i>cf_flags</i> and <i>font</i>
 * parameters determine the font that is initially displayed by the dialog box.
 *
 * @param cf_flags is a combination of the following flags defined in "slick.sh":
 *    CF_SCREENFONTS Display screen fonts.
 *    CF_PRINTERFONTS   Display printer fonts.
 *    CF_EFFECTS  Allows color and strike out and underline selection.
 *    CF_FIXEDPITCHONLY Display fixed pitch fonts only.
 *
 * @param font is a string in the format: <i>font_name</i>, <i>font_size</i>, <i>font_flags</i> [,]
 * @param font_size is a font point size.
 * @param font_flags is a combination of the following flags defined in "slick.sh":
 *    F_BOLD
 *    F_ITALIC
 *    F_STRIKE_THRU
 *    F_UNDERLINE
 *
 *
 * @example
 * <pre>
 * defmain()
 * {
 *     font="Helvetica,10,"(F_BOLD|F_ITALIC)
 *     // You can use the _font_param function to build the above string like this
 *     //     font=_font_param("Helvetica", 10, F_BOLD|ITALIC);
 *     result=_choose_font(CF_PRINTERFONTS, font);
 *     if (result==''){
 *          message("User has cancelled");
 *     } else {
 *          parse result with font_name' ,' font_size ',' font_flags ',';
 *          message("Name="font_name" Size="font_size" Flags="font_flags);
 *     }
 * }
 * </pre>
 *
 * @return  Returns '' if user selects cancel.  Otherwise, a font string is
 * returned in the same format as the <i>font</i> argument.  The <i>rgb_color</i>
 * is appended only if the CF_EFFECTS flag is specified.  However, a ',' will still
 * follow the <i>font_flags</i>.
 *
 * @see _font_form
 * @see _font_param
 *
 * @categories Miscellaneous_Functions
 */
_str _choose_font(int cf_flags=CF_SCREENFONTS,_str font_string=",10,,");
_str _get_profile_string(_str section="",_str key="",_str defaultValue="");


/**
 * Gets and optionally sets an editor default option.
 *
 * @param option   may be one of the following letters:
 *                 <DL compact style="margin-left:20pt;">
 *                 <DT>'A'  </DT><DD>boolean. Alt  menu.  When <b>true</b>, won't accidentally get placed on menu bar when press Alt key not followed by another key.</DD>
 *                 <DT>'C'  </DT><DD>boolean.  Display MDI child cursor position when do not have focus.  Default is on.</DD>
 *                 <DT>'E'  </DT><DD>boolean.  Set Slick-C&reg; error position on weak interpreter error.  Effects <b>find_error</b> command.</DD>
 *                 <DT>'F'  </DT><DD>boolean.  Maximize first MDI child.  Default is off.</DD>
 *                 <DT>'H'  </DT><DD>boolean.  Display horizontal scroll bar on edit window.  Default is on.</DD>
 *                 <DT>'I'  </DT><DD>boolean.  When on, a carriage return not followed by a new line in the build window erases current line.  Default is on.</DD>
 *                 <DT>'K'  </DT><DD>boolean.  Cursor blink.  Default is on.</DD>
 *                 <DT>'L'  int.  Window left margin in twips for edit window and editor control.  Ignored when there are selective display </DT><DD>bitmaps or any other line prefix bitmaps.  Default is 100.</DD>
 *                 <DT>'N'  _str.  Past EOF character.  Determines the character displayed on lines past the end of the file.  Useful for VI emulation.</DT><DD></DD>
 *                 <DT>'P'  </DT><DD>boolean.  Hide mouse when type character.  Default is off.</DD>
 *                 <DT>'Q'  _str.  This option is ignored.</DT><DD></DD>
 *                 <DT>VSOPTIONZ_SPECIAL_CHAR_XLAT_TAB</DT><DD>_str. Determines the characters display when special characters are display like tabs, new lines, spaces, etc.
 *                                                             This strings must be 6 characters in length.  The special characters in order are EOLCH1, EOLCH2, TAB(9), SPACE(32), VIRTUAL TAB SPACE, and EOF(26).</DD>
 *                 <DT>'R'  Column to display vertical line in edit window.  0 specifies no vertical line.  Defaults to 0.</DT><DD></DD>
 *                 <DT>'S'  int.  Default search flags.</DT><DD></DD>
 *                 <DT>'T'  </DT><DD>boolean.  Display top of file line for edit window and editor control.  Defaults to on.</DD>
 *                 <DT>'U'  </DT><DD>boolean. Draw box focus rect around current line for edit window and editor control.  Defaults to off.</DD>
 *                 <DT>'V'  </DT><DD>boolean.  Display vertical scroll bar on edit window.  Defaults to on.</DD>
 *                 <DT>'W'  int.  Maximum length of filename placed in menu in </DT><DD>bytes.  Effects X windows only.  Defaults to 40.</DD>
 *                 <DT>'Z'  </DT><DD>boolean.  Protect read only mode.  When on, the editor will not allow read only files to be modified.  Saving a read only file always displays the Save As dialog box.  Defaults to on.</DD>
 *                 <DT>VSOPTION_WARNING_ARRAY_SIZE</DT><DD>int.  A message box is displayed when a macro creates an array larger than this value to optional let the use terminate the macro.</DD>
 *                 <DT>VSOPTION_WARNING_STRING_LENGTH</DT><DD>int.  A message box is displayed when a macro creates a string larger than this value to optional let the use terminate the macro.</DD>
 *                 </DL>
 * @param newValue
 *
 * @return Returns the (possibly newly set) current value for corresponding option.
 * @categories Miscellaneous_Functions
 */
_str _default_option(_str option,_str newValue=null);

/**
 * Gets and optionally sets the create mode for all edited forms.  When in
 * create mode, the cursor appears differently to the user to indicate that
 * a new control can be created on the dialog box.
 * @categories Miscellaneous_Functions
 */
int _decreate_mode(int mode= -1);
/**
 * @return Returns the highest possible window id allocated.  This function
 * is used in conjunction with the <b>_iswindow_valid</b> function to loop
 * through all windows.
 *
 * @example
 * <pre>
 * _find_formobj(form_name /*,'E' - Find edited forms only | 'N' - Find non-
 * edited forms only */)
 * {
 *    last=_last_window_id()
 *    option=upcase(arg(2))
 *    for (i=1;i&lt;=last;++i) {
 *       if (_iswindow_valid(i) && i.p_object==OI_FORM &&
 *            (option=='' || (option=='E' && i.p_edit) ||
 *                    (option=='N' && !i.p_edit)
 *            )
 *          ) {
 *          if (name_eq(i.p_name,form_name)) {
 *             return(i)
 *          }
 *       }
 *    }
 *    return(0)
 * }
 * </pre>
 *
 * @categories Window_Functions
 *
 */
int _last_window_id();
/**
 * @return Returns <b>true</b> if <i>window_id</i> is a valid window handle.
 * This function is used to loop through all windows and to check if a window
 * was deleted.
 *
 * @example
 * <pre>
 * _find_formobj(form_name /*,'E' - Find edited forms only | 'N'-Find non-
 * edited forms only*/)
 * {
 *    last=_last_window_id();
 *    option=upcase(arg(2));
 *    for (i=1;i&lt;=last;++i) {
 *       if (_iswindow_valid(i) && i.p_object==OI_FORM &&
 *            (option=='' || (option=='E' && i.p_edit) ||
 *            (option=='N' && !i.p_edit)
 *            )
 *          ) {
 *          if (name_eq(i.p_name,form_name)) {
 *             return(i);
 *          }
 *       }
 *    }
 *    return(0);
 * }
 * </pre>
 *
 * @categories Window_Functions
 *
 */
boolean _iswindow_valid(int wid);

/**
 * @return Returns the window id of a displayed form whose <b>p_template</b>
 * property matches <i>form_index.</i>  Returns 0 if a match is not found.
 * <i>form_name</i> is an index into the names table of a form.  When a form is
 * loaded with the <b>_load_template</b> function (<b>show</b> calls this
 * function), the <b>p_template</b> property is set to the <i>form_index</i>
 * given to the <b>_load_template</b> function.   This allows a macro to
 * determine the correct name of a form when you press Shift-SPACE to edit a
 * dialog box.  Using the form name would be incorrect since this can be changed
 * after the form is loaded.  The <b>p_template</b> property is read only and is
 * set only by the <b>_load_template</b> and <b>_update_template</b> functions.
 * Beware, by default, this function will find edited or non-edited instances of
 * an object.
 *
 * @param option may be 'N' or 'E'.  Specify the 'N' option if you only
 * want to find a non-edited instance of an object.  Specify the 'E' option if
 * you only want to find an edited instance of an object.
 *
 * @see _find_object
 * @see _find_formobj
 * @see _find_control
 *
 * @categories Form_Functions
 *
 */
int _isloaded(int form_index,_str options="");
/**
 * @return Returns the time in milliseconds since the last key or mouse
 * event.
 *
 * @categories Miscellaneous_Functions
 *
 */
long _idle_time_elapsed();
void _reset_idle();


/**
 * <p>If <i>newValue</i> is not null, the corresponding option is set to
 * <i>vewValue</i>.</p>
 *
 * @return Returns current/set value.
 *
 * <p>The options have the following meaning:</p>
 *
 * <dl>
 * <dt>'R'</dt><dd>Indicates whether repeated words should be flagged
 * as an error.  Returns non-zero value when on.</dd>
 * <dt>'U'</dt><dd>Indicates whether upper case words should be
 * ignored.  Returns non-zero value when on.</dd>
 * <dt>'C'</dt><dd>Specifies name of common word dictionary.
 * Returns name of dictionary.</dd>
 * <dt>'M'</dt><dd>Specifies name of main dictionary.  Returns name
 * of dictionary.</dd>
 * <dt>'1'</dt><dd>Specifies name of user 1 dictionary.  Returns name
 * of dictionary.</dd>
 * <dt>'2'</dt><dd>Specifies name of user 2 dictionary.  Returns name
 * of dictionary.</dd>
 * </dl>
 *
 * @categories Miscellaneous_Functions
 *
 */
_str _spell_option(_str option, _str newValue=null);
/**
 * Clears spelling data in memory.
 *
 * @param option must be one of the folowing:
 *
 * <dl>
 * <dt>'H'</dt><dd>Clear history.</dd>
 * <dt>'1'</dt><dd>Clear user 1 dictionary</dd>
 * <dt>'2'</dt><dd>Clear user 2 dictionary</dd>
 * <dt>'R'</dt><dd>Clear the repeat word.</dd>
 * </dl>
 *
 * @categories Miscellaneous_Functions
 *
 */
int _spell_clear(_str option);
/**
 * Adds the word specified to user dictionary 1 or 2.  After the word is
 * added to a user dictionary, it is considered a correctly spelled word.
 *
 * @return Returns 0 if successful.
 *
 * @categories Miscellaneous_Functions
 *
 */
int _spell_add(_str word,int dictionaryNum);
/**
 * Deletes a word from the history or a user dictionary.
 *
 * @param option must be one of the folowing:
 *
 * <dt>'H'</dt><dd>Delete word from history.</dd>
 * <dt>'1'</dt><dd>Delete word from user 1 dictionary.</dd>
 * <dt>'2'</dt><dd>Delete word from user 2 dictionary.</dd>
 * </dl>
 *
 * @categories Miscellaneous_Functions
 *
 */
int _spell_delete(_str word,_str option);
/**
 * Adds a word to be ignored for the current spelling session.  If the
 * <i>replace_word</i> argument is given, occurrences of
 * <i>ignore_word</i> are replaced with the <i>replace_word</i>.
 *
 * @return Returns 0 if successful.
 *
 * @categories Miscellaneous_Functions
 *
 */
int _spell_add_hist(_str ignore_word,_str replace_word="");
/**
 * Writes the user dictionary 1 and 2 information in memory to the files
 * specified.  <i>user_dict1</i> and <i>user_dict2</i> specify output file
 * names.  The default user dictionary name set by the
 * <b>_spell_option</b> function is used if a dictionary name is not
 * specified.
 *
 * @return Returns 0 if successful.
 *
 * @categories File_Functions
 *
 */
int _spell_save(_str user_dict1="",_str user_dict2="");


/**
 * (Supported under Windows, Windows 95/98, and Windows NT only) Returns the
 * drive type of the drive specified.  <i>drive</i> is a drive letter followed
 * by a colon character.  The drive type may be one of the following constants
 * defined in "slick.sh":
 * <DL compact style="margin-left:20pt;">
 *     <DT>DRIVE_NOROOTDIR <dd>Indicates that the drive is not valid.
 *     <DT>DRIVE_REMOVABLE <dd>Drive is a floppy drive.
 *     <DT>DRIVE_FIXED     <dd>Drive is a non-removable drive.
 *     <DT>DRIVE_REMOTE    <dd>Drive is a network drive.
 *     <DT>DRIVE_CDROM     <dd>Drive is a CD-ROM
 *     <DT>DRIVE_RAMDISK   <dd> Drive is a RAM (in memory) disk.
 * </DL>
 *
 * @param drive
 *
 * @return
 * @example
 * <pre>
 * defmain()
 * {
 *      message("drive type of A: is "_drive_type("A:"));
 * }
 * </pre>
 * @categories File_Functions
 */
int _drive_type(_str drive);
/**
 * @return Waits for a dialog box (form) to be closed, and returns the
 * parameter specified to the _delete_window function which closes the dialog
 * box.  If no parameter is specified to _delete_window, '' is returned.
 * <i>form_wid</i> is the instance handle (window id) usually returned by one of
 * the functions <b>_load_template</b> or <b>show</b>.  All other forms, other
 * than <i>form_wid</i>, are disabled.  When the wait terminates, all forms are
 * reenabled unless there is a previous modal wait.  If there is a previous
 * modal wait, the previous wait dialog box receives focus.
 *
 * @example
 * <pre>
 * #include "slick.sh"
 * _command test()
 * {
 *     //  Normally the <b>show</b> function is called with -modal option so
 * that it calls _modal_wait.
 *     //  However, there are a few instances where you might wait to get an
 * instance handle
 *     //  returned from show so you can perform some initializations on the
 * dialog box.
 *     form_wid=show('form1');
 *     // Perform initializations on dialog box here.
 *     // Now wait for dialog box to be deleted.
 *     result=_modal_wait(wid);
 *     message('result='result);
 * }
 *
 * defeventtab form1;
 * ok.lbutton_up()
 * {
 *      p_active_form._delete_window("This is a test");
 * }
 * cancel.lbutton_up()
 * {
 *      // Return '' to _modal_wait
 *      p_active_form._delete_window();
 * }
 * </pre>
 *
 * @categories Form_Functions
 *
 */
_str _modal_wait(int form_wid);
/**
 * Creates a modal dialog box and displays <i>string</i> message and various
 * buttons.
 * 
 * @categories Miscellaneous_Functions
 * @param string   may contain carriage return characters to break a
 *                 string message into multiple lines.  By default, <i>string</i> is broken into
 *                 multiple lines on word boundaries if necessary.  The title of the dialog box
 *                 is set to <i>title</i> if given.
 * @param title
 * @param mb_flags is a combination of zero or more ID
 *                 button flags and MB_* flags:
 *                 
 *                 <p>Note: The MB_OK, MB_OKCANCEL, MB_ABORTRETRYIGNORE,
 *                 MB_YESNOCANCEL, MB_RETRYCANCEL are combinations of the ID
 *                 button flags (ex. MB_OKCANCEL is IDOK|IDCANCEL)
 *                 <dl>
 *                 <dt>IDOK</dt><dd>Display an OK button</dd>
 *                 <dt>IDSAVE</dt><dd>Display a Save button</dd>
 *                 <dt>IDSAVEALL</dt><dd>Display a Save All button</dd>
 *                 <dt>IDOPEN</dt><dd>Display an Open button</dd>
 *                 <dt>IDYES</dt><dd>Display a Yes button</dd>
 *                 <dt>IDYESTOALL</dt><dd>Display a Yes to All button</dd>
 *                 <dt>IDNO</dt><dd>Display a No button</dd>
 *                 <dt>IDNOTOALL</dt><dd>Display a No to All button</dd>
 *                 <dt>IDABORT</dt><dd>Display an Abort button</dd>
 *                 <dt>IDRETRY</dt><dd>Display a Retry button</dd>
 *                 <dt>IDIGNORE</dt><dd>Display an Ignore button</dd>
 *                 <dt>IDCLOSE</dt><dd>Display a Close button</dd>
 *                 <dt>IDCANCEL</dt><dd>Display a Cancel button</dd>
 *                 <dt>IDDISCARD</dt><dd>Display a Discard button</dd>
 *                 <dt>IDHELP</dt><dd>Display a Help button</dd>
 *                 <dt>IDAPPLY</dt><dd>Display an Apply button</dd>
 *                 <dt>IDRESET</dt><dd>Display a Reset button</dd>
 *                 <dt>IDRESTOREDEFAULTS</dt><dd>Display Restore
 *                 Defaults button</dd>
 *                 <dt>MB_OK</dt><dd>Display an OK button.</dd>
 *                 <dt>MB_OKCANCEL</dt><dd>Display an OK and Cancel button.</dd>
 *                 <dt>MB_ABORTRETRYIGNORE</dt><dd>Display  Abort, Retry, Ignore buttons.
 *                 Not supported on UNIX.</dd>
 *                 <dt>MB_YESNOCANCEL</dt><dd> Display Yes, No, and Cancel buttons.</dd>
 *                 <dt>MB_YESNO</dt><dd>Display Yes, and No buttons.</dd>
 *                 <dt>MB_RETRYCANCEL</dt><dd>Display a Retry and Cancel button.
 *                 Not supported on UNIX.</dd>
 *                 <dt>MB_ICONHAND</dt><dd>Display a stop sign picture to the left of the message.</dd>
 *                 <dt>MB_ICONQUESTION</dt><dd>Display a question picture to the left of the
 *                 message.</dd>
 *                 <dt>MB_ICONEXCLAMATION</dt><dd>Display an exclamation point picture to the
 *                 left of the message.</dd>
 *                 <dt>MB_ICONINFORMATION</dt><dd>Display an 'i' picture to the left of the message.</dd>
 *                 <dt>MB_ICONSTOP</dt><dd>Display a stop sign picture to the left of the message.</dd>
 *                 </dl>
 * @param default_button  If specified, determines which of the 
 *                        buttons is the default button. One of
 *                        the following button constants:
 * 
 *         <ul>
 *         <li>IDOK</li>
 *         <li>IDSAVE</li>
 *         <li>IDSAVEALL</li>
 *         <li>IDOPEN</li>
 *         <li>IDYES</li>
 *         <li>IDYESTOALL</li>
 *         <li>IDNO</li>
 *         <li>IDNOTOALL</li>
 *         <li>IDABORT</li>
 *         <li>IDRETRY</li>
 *         <li>IDIGNORE</li>
 *         <li>IDCLOSE</li>
 *         <li>IDCANCEL</li>
 *         <li>IDDISCARD</li>
 *         <li>IDHELP</li>
 *         <li>IDAPPLY</li>
 *         <li>IDRESET</li>
 *         <li>IDRESTOREDEFAULTS</li>
 *         </ul>
 *  
 * @return Returns the button id of the button pressed which closed the
 *         dialog box.  One of the following constants is returned:
 *         
 * <ul>
 * <li>IDOK</li>
 * <li>IDSAVE</li>
 * <li>IDSAVEALL</li>
 * <li>IDOPEN</li>
 * <li>IDYES</li>
 * <li>IDYESTOALL</li>
 * <li>IDNO</li>
 * <li>IDNOTOALL</li>
 * <li>IDABORT</li>
 * <li>IDRETRY</li>
 * <li>IDIGNORE</li>
 * <li>IDCLOSE</li>
 * <li>IDCANCEL</li>
 * <li>IDDISCARD</li>
 * <li>IDHELP</li>
 * <li>IDAPPLY</li>
 * <li>IDRESET</li>
 * <li>IDRESTOREDEFAULTS</li>
 * </ul>
 * @example 
 * <pre>
 * result=_message_box("Save changes?", '', MB_YESNO|MB_ICONQUESTION);
 * if (result==IDYES) {
 *     // save the file
 * } else {
 *     // Don't save it
 * }
 * // Same as above but using ID button flags instead of MB_OK.
 * // Also change the default button
 * result=_message_box("Save changes?", '', IDYES|IDNO|MB_ICONQUESTION,IDNO);
 * if (result==IDYES) {
 *     // save the file
 * } else {
 *     // Don't save it
 * }
 * </pre>
 * @see sticky_message
 * @see message
 */
_str _message_box(_str string,_str title="SlickEdit",int mb_flags=MB_OK|MB_ICONEXCLAMATION,int default_button=0);
// The default color here is retrieved from a global variable

/**
 * Plays standard system beep if no parameters are specified or beeps for <i>frequency</i> and <i>duration</i>
 * specified.  <i>frequency</i> is specified in hertz.  <i>duration</i> is in milliseconds.  Under UNIX, the
 * <i>frequency</i> and <i>duration</i> parameters are ignored.
 *
 * @param frequency frequency of tone in hertz
 * @param duration  duration of tone in milliseconds
 *
 * @categories Miscellaneous_Functions
 */
void _beep(int frequency=-1,int duration=-1);
//void _auto_size(      ,"sss"  ,0  ,0  ,0,0},
_str _scroll_page(_str option="",int value=p_char_height);
/**
 * @return Returns the number of pixels per inch in the x direction on the display.
 *
 * @categories Display_Functions
 *
 */
int _pixels_per_inch_x();
/**
 * @return Returns the number of twips per pixel in the x direction on the display.
 * We recommend that you use the <b>_dx2lx</b> function instead of
 * this function because it may not be portable.
 *
 * @see _twips_per_pixel_y
 * @see _dx2lx
 *
 * @categories Display_Functions
 *
 */
int _twips_per_pixel_x();
/**
 * @return Returns the number of twips per pixel in the y direction on the display.
 * We recommend that you use the <b>_dy2ly</b> function instead of
 * this function because it may not be portable.
 *
 * @see _twips_per_pixel_x
 * @see _dy2ly
 *
 * @categories Display_Functions
 *
 */
int _twips_per_pixel_y();
// The option defaults to 'U' -US, 'L' locale,  'B' binary

/**
 * @return Returns date of <i>filename</i>.
 *
 * @param filename   file to retrieve date of
 * @param option     Currently you must specify the 'B'
 *                   option which returns the date in binary string
 *                   comparison form.  '' is returned if <i>filename</i> is
 *                   not found.  The time returned is in milliseconds.
 *                   The actual accuracy may depend on the Operating System.
 *
 * @see _file_time
 * @see file_date
 * @categories File_Functions
 */
_str _file_date(_str filename,_str option);
/**
 * The option defaults to 'U' -US, 'L' localte, 'M' military
 * @categories File_Functions
 */
_str _file_time(_str filename,_str option);

/**
 * @return Returns the size of <i>filename</i>
 * 
 * @param filename   file to retrieve size of
 * 
 * @categories File_Functions
 */
int _file_size(_str filename);

/**
 * @return Returns the system date.
 *
 * @param  option  return value format option, may be one of the following:
 *    <ul>
 *    <li><b>'U'</b> US format date mm/dd/yyyy.
 *    <li><b>'L'</b> Locale dependent date string.
 *         Under Windows, this uses the regional settings
 *         "Short date style".
 *         For other platforms, this option is still under development.
 *  
 *    <li><b>'I'</b> ISO 8601 format date yyyy-mm-dd.
 *    </ul>
 *
 * @see _time()
 * @see _file_date()
 *
 * @categories Miscellaneous_Functions
 */
_str _date(_str option='U');

/**
 * @return Returns system time in the format specified.
 *
 * @param retval_option may be one of the following:
 *
 * <dl>
 * <dt>'T'</dt><dd>Return time in the format <i>hh</i>:<i>mmcc</i>
 * where <i>hh</i> is an hour between 1 and 12, mm
 * is the minutes between 0 and 59, and <i>cc</i> is
 * the "am" or "pm".</dd>
 *
 * <dt>'B'</dt><dd>Return binary time in milliseconds.  This options is
 * used for comparing dates with the :< and :>
 * operators.</dd>
 *
 * <dt>'M'</dt><dd>24-hour (Military) time in the format
 * <i>hh</i>:<i>mm</i>:<i>ss</i> where <i>hh</i>
 * is an hour between 0 and 23, <i>mm</i> is the
 * minutes between 0 and 59, and <i>ss</i> is the
 * seconds between 0 and 59.</dd>
 *
 * <dt>'L'</dt><dd>Returns time in the current local format.  Under
 * Windows, this uses the regional settings "Time
 * style."  For other platforms, this has not yet been
 * defined.</dd>
 *  
 * <dt>'F'</dt><dd>Return time in the format YYYYMMDDhhmmssfff
 * where <i>YYYY</i> is the year, <i>MM</i> is the month, 
 * <i>DD</i> is the day, <i>hh</i> is an hour between 0 and 23, 
 * <i>mm</i> is the minutes between 0 and 59, <i>ss</i> is the 
 * seconds between 0 and 59, and <i>fff</i> is the fractional 
 * second, in milliseconds.</dd> 
 *  
 * <dt>'G'</dt><dd>Returns seconds elapsed since UNIX Epoch
 * (Midnight of January 1, 1970). This value is always in
 * UTC/GMT.</dd>
 *
 * @categories Miscellaneous_Functions
 *
 * @see _date()
 * @see _file_date()
 */
_str _time(_str option='T');

_str _next_drop_file();



/**
 * Inserts a list of font names or font sizes.  If the <i>font_name</i>
 * parameter is specified<i>,</i>, font sizes are inserted.  Otherwise, a list
 * of font names are inserted.
 *
 * @param options is a string of zero or more of the following option
 * letters:
 * <dl>
 * <dt>F</dt><dd>Display fixed fonts only.</dd>
 * <dt>P</dt><dd>Display printer fonts.</dd>
 * <dt>S</dt><dd>(Default) Display screen fonts.</dd>
 * </dl>
 * <p>
 * The S and P options may not both be specified.</p>
 *
 * @example
 * <pre>
 * combo1.on_create()
 * {
 *      // Combo boxes have 3 separate controls.  Each of which can be
 * accessed with all the
 *      // properties and methods of the stand alone control.  See <b>Combo
 * Box Control</b>.
 *      _insert_font_list();
 * }
 * </pre>
 *
 * @see _font_type
 * @see _choose_font
 * @see _font_form
 * @see _isscalable_font
 *
 * @appliesTo Edit_Window, Editor_Control, List_Box
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, List_Box_Methods
 *
 */
int _insert_font_list(_str options="S",_str font_name="");
/**
 * @return Returns the pixel height of the display.
 *
 * @categories Display_Functions
 *
 */
int _screen_height();
/**
 * @return Returns the pixel width of the display.
 *
 * @categories Display_Functions
 *
 */
int _screen_width();


/**
 * @return  Returns a unique tile id.  SlickEdit uses tile ids to
 * group and ungroup tiled windows.
 *
 * @categories Window_Functions
 */
int _create_tile_id();
int _timer_is_valid(int timer_handle);
/**
 * Creates a timer and optionally calls a function you specify.
 * <i>interval</i> is specified in milliseconds.  <i>callback</i> is a
 * pointer to a function or names table index to a global function returned
 * by <b>find_index</b>.  <i>arg1</i> is a an optional argument to pass
 * to the call back function.  If only one argument is given, a
 * <b>get_event</b> timer is created.  This allows you to use get_event
 * in a loop and wait for a key or mouse event, or until the
 * <b>on_timer</b> event occurs.  When the <i>callback</i> argument
 * is not <b>null</b>, <b>get_event</b> is not effected.  Instead, the
 * callback function is called with the <i>arg1</i> argument if given at
 * intervals specified by <i>interval.</i>
 *
 * @return Returns a timer handler >=0.  On error, negative error code is returned.
 *
 * @example
 * <pre>
 * _set_timer(1000);
 * for(;;){
 *    event=get_event();
 *    if (event==on_timer){
 *        message("on_timer event");
 *    } else {
 *        message(event2name(event));
 *    }
 * }
 * _kill_timer();
 * </pre>
 *
 * @see _kill_timer
 *
 * @categories Miscellaneous_Functions
 *
 */
int _set_timer(int milli_interval,typeless pfnCallback=0,typeless callbackArgument=null);
/**
 * Frees the timer corresponding to <i>timer_handle</i>.  <i>timer_handle</i>
 * must have been allocated by the <b>_set_timer</b> function.  When
 * <i>timer_handle</i> is -1, the <b>get_event</b> timer is killed (see
 * <b>_set_timer</b>) Beware, if a timer callback function dies, the timer
 * handle is automatically killed to prevent infinite error message loops.
 *
 * @see _set_timer
 *
 * @categories Miscellaneous_Functions
 *
 */
int _kill_timer(int timer_handle=-1);
void _set_timer_alternate(int timer_handle,int alternateInterval,int alternateIdleTime);

/**
 * Determines if a particular operating system clipboard format is available.
 * Use the <b>clipboard_itype</b> function to determine the format of an
 * internal TEXT clipboard.
 *
 * @categories Clipboard_Functions
 * @param format may be one of the following constants defined in "slick.sh":
 * <pre>
 *    CBF_TEXT There is a TEXT format clipboard.
 *    CBF_VSTEXT  There is a SlickEdit TEXT format clipboard.
 *    CBF_VSCONTROLS
 *    There is a SlickEdit CONTROLS format clipboard.
 * </pre>
 * @param isClipboard
 *               Indicates whether operation is performed for the clipboard or selection.  Effects Unix only.
 *
 * @return Returns 0 if the clipboard format is not available.
 *         Otherwise, a non-zero value is returned.  If
 *         CBF_VSTEXT is given and the format exists, a string
 *         in the format "<i>type process_id more_info</i>" is
 *         returned.
 */
_str _clipboard_format(_str format,boolean isClipboard=true);


/**
 * Returns non-zero value if the operating system clipboard is empty.  After an auto
 * restore of your previous clipboards, the operating system clipboard may be empty,
 * but there will be some internal clipboards.  Use the <b>clipboard_itype</b> function
 * to determine if there are any internal clipboards.
 *
 * @categories Clipboard_Functions
 * @param isClipboard
 *               Indicates whether operation is performed for the clipboard or selection.  Effects Unix only.
 *
 * @return  Returns non-zero value if the operating system clipboard is empty
 */
int _clipboard_empty(boolean isClipboard=true);

/* mdi form or form. */
/* {"-get-icon-xy"      ,METHOD|PROC ,_GET_ICON_XY_OP   ,"vv"      ,2  ,0              ,0,0}, */
/* {"-set-icon-xy"      ,METHOD|PROC ,_SET_ICON_XY_OP   ,"ee"      ,2  ,0              ,0,0}, */
/* {"-get-max-window"   ,PROC ,_GET_MAX_WINDOW_OP,"vvvv"      ,4  ,0              ,0,0}, */

/**
 * Creates an object and returns an instance handle.
 *
 * @param object_index
 *                   An object constant with prefix "OI_" from "slick.sh".
 *                   Can't use OI_MDI_FORM.
 * @param parent_wid Must be an existing window id, _mdi constant,
 *                   or _app constant.  _mdi is a window handle for the MDI window.
 *                   _app is a window handle to the SlickEdit application window
 *                   (exists but can be seen).
 * @param title      Used by OI_FORM, OI_FRAME, OI_COMMAND_BUTTON, OI_CHECK_BOX,
 *                   and OI_RADIO_BUTTON objects only.
 * @param x
 * @param y
 * @param width
 * @param height
 * @param cw_flags   Create window flags.  Many additional properties for
 *                   objects can be set after the object is created.  These flags are a
 *                   combination of the flags below.
 *                   <DL compact style="margin-left:20pt;">
 *                   <DT>CW_HIDDEN</DT><DD>Create the window initially hidden.
 *                   <DT>CW_CHILD</DT><DD>Create the object as a child of the parent window,
 *                   <i>parent_wid</i>.  This flag is not valid for an OI_FORM object and
 *                   REQUIRED for all other objects.</DD>
 *                   <DT>CW_PARENT</DT><DD>Keep form object on top of another window.
 *                   This flag is only supported by form objects.</DD>
 *                   <DT>CW_LEFT_JUSTIFY, CW_RIGHT_JUSTIFY</DT><DD>Displays text on left or
 *                   right for OI_CHECK_BOX or OI_RADIO_BUTTON.</DD>
 *                   <DT>CW_BSDEFAULT</DT><DD>Selects a OI_COMMAND_BUTTON to be the
 *                   default button.</DD>
 *                   <DT>CW_EDIT</DT><DD>Creates the window for editing in the dialog editor.</DD>
 *                   <DT>CW_COMBO_LIST_ALWAYS</DT><DD>Used to create OI_COMBO_BOX in the list
 *                   always style.  Effects OI_COMBO_BOX object only.</DD>
 *                   <DT>CW_COMBO_NOEDIT</DT><DD>Used to create OI_COMBO_BOX in the no
 *                   edit style.  Effects OI_COMBO_BOX object only.</DD>
 *                   </DL>
 * @param bds_style  Border style.  Effects OI_FORM object only.  May be one of the following:
 *                   <DL compact style="margin-left:20pt;">
 *                   <DT>BDS_NONE
 *                   <DT>BDS_FIXED_SINGLE
 *                   <DT>BDS_SIZABLE
 *                   <DT>BDS_DIALOG_BOX
 *                   </DL>
 *
 * @return Returns the window id of root window of the object created.  On error,
 *         a negative error number is returned.
 * @example
 * <pre>
 * form_wid=_create_window(OI_FORM,_mdi,"Title",0,0,4000,2000,
 *               CW_PARENT|CW_HIDDEN,
 *               BDS_DIALOG_BOX);
 * text_wid=form_wid._create_window(OI_TEXT_BOX,form_wid,"",100,100,3500,100,
 *    CW_CHILD);
 * form_wid._center_window(_mdi)
 * form_wid.p_visible=1;
 * </pre>
 *
 * @see _top_height
 * @see _bottom_height
 * @categories Window_Functions
 */
int _create_window(int object_index, int parent_wid, _str title, int x, int y, int width, int height, int cw_flags=0, int bds_style=-1);
void _delete_modal_windows(_str modalWaitResult="");


/**
 * Set the mouse pointer used by the active window.
 *
 * @param mp Mouse pointer constant. One of MP_* constants in slick.sh.
 *
 * @see p_mouse_pointer
 *
 * @appliesTo All_Window_Objects
 *
 * @categories Mouse_Functions
 */
void mou_set_pointer(int mp);

/**
 * @return Last mouse x position relative to active window in pixels. If the 'M'
 * option is given the return value is in current windows scale mode (p_scale_mode).
 *
 * @param option (optional). '' means to return pixels.
 *               'M' means to return value in current windows scale mode (p_scale_mode).
 *
 * @see p_scale_mode
 * @see mou_last_y
 * @see mou_get_xy
 *
 * @appliesTo All_Window_Objects
 *
 * @categories Mouse_Functions
 */
int mou_last_x(_str option="");

/**
 * @return Last mouse y position relative to active window in pixels. If the 'M'
 * option is given the return value is in current windows scale mode (p_scale_mode).
 *
 * @param option (optional). '' means to return pixels.
 *               'M' means to return value in current windows scale mode (p_scale_mode).
 *
 * @see p_scale_mode
 * @see mou_last_x
 * @see mou_get_xy
 *
 * @appliesTo All_Window_Objects
 *
 * @categories Mouse_Functions
 */
int mou_last_y(_str option="");

/**
 * Retrieve last mouse x, y position in pixels relative to screen.
 *
 * @see p_scale_mode
 * @see mou_last_x
 * @see mou_last_x
 *
 * @appliesTo All_Window_Objects
 *
 * @categories Mouse_Functions
 */
void mou_get_xy(int &x,int &y);

/**
 * Gets and optionally sets the mouse event mode. The current new mouse event mode
 * is returned.
 *
 * @param mode One of the following:
 * <pre>
 * -1 Do not set mode. Just return current mode.
 *  0 Turn mode off.
 *  1 Turn mode on. When on, mouse button-up, and move events are returned by get_event() and test_event().
 * </pre>
 *
 * @return Current mouse event mode.
 *
 * @see get_event
 * @see test_event
 *
 * @appliesTo All_Window_Objects
 *
 * @categories Mouse_Functions
 */
int mou_mode(int mode=-1);

/**
 * @return Returns and optionally sets the grid width used by the dialog
 * editor.  This affects the distance displayed between the dots displayed on a
 * form that is being edited.  If the <i>new_width</i> parameter is given, the
 * grid width is set to this value.  The <i>new_width</i> parameter is in twips
 * (1440 twips are one inch on the display).
 *
 * @see gui_grid
 * @see grid
 * @see _grid_height
 *
 * @categories Miscellaneous_Functions
 *
 */
int _grid_width(int new_width= -1);
/**
 * @return Returns and optionally sets the grid height used by the dialog
 * editor.  This affects the distance displayed between the dots displayed on a
 * form that is being edited.  If the <i>new_height</i> parameter is given, the
 * grid height is set to this value.  The <i>new_height</i> parameters is in
 * twips (1440 twips are one inch on the display).
 *
 * @see gui_grid
 * @see _grid_width
 * @see grid
 *
 * @categories Miscellaneous_Functions
 *
 */
int _grid_height(int new_height= -1);

/**
 * @return  Returns non-zero value if the current window (<b>p_window_id</b>) is
 * the command line.  Otherwise 0 is returned.
 * @example
 *
 *      if ( command_state() ) {
 *           _delete_char();
 *      } else {
 *           wordwrap_delete_char('');
 *      }
 *
 * @see command_toggle
 * @see execute
 * @see set_command
 * @see get_command
 *
 * @appliesTo  Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, Command_Line_Functions, Text_Box_Methods
 */
int command_state();


/**
 * If the visible cursor is on the command line, the cursor is moved to
 * the text area.  Otherwise the visible cursor is moved from the text
 * area to the command line.
 *
 * @see command_state
 * @see execute
 * @see set_command
 * @see get_command
 *
 * @appliesTo  Edit_Window, Command_Line
 *
 * @categories Command_Line_Functions
 */
void command_toggle();

/**
 * Moves the cursor to the command line.
 *
 * @appliesTo  Edit_Window, Command_Line
 * @categories CursorMovement_Functions
 */
void cursor_command();


/**
 * Moves the cursor to the text area.
 *
 * @appliesTo  Edit_Window, Command_Line
 * @categories CursorMovement_Functions
 */
void cursor_data();

/**
 * Runs the command currently on the command line or the <i>command</i>
 * specified.  Command may be an internal command (_command), an external
 * operating system command, or an external Slick-C&reg; batch macro (with
 * <b>defmain</b> entry point).  If the <i>command</i> argument is <b>null</b>,
 * the command line is erased and the command is inserted into the command
 * retrieve buffer ".command".  See <b>retrieve_prev</b>, <b>retrieve_next</b>.
 *
 * @param command
 * @param options a string of one or more of the following letters:
 *                <DL compact style="margin-left:20pt;">
 *                <DT>W <DD>If command is an external program, run <b>slkwait</b> program to wait
 *                for program to complete.   This option allows you to view the results after
 *                running a DOS text mode application which displays results to the screen.
 *                Defaults to OFF.
 *                <DT>A <DD>If command is an external program, run program asynchronously (no
 *                wait).  Defaults to OFF.
 *                <DT>R <DD>Insert command into command retrieve buffer (.command) and clear
 *                command line.  Defaults to OFF unless no arguments given.
 *
 * @see command_state
 * @see command_toggle
 * @see set_command
 * @see get_command
 * @categories Miscellaneous_Functions
 */
void execute(_str command=null,_str options="");

/**
 * Fills the selection specified with <i>character</i>.  <i>mark_id</i> is a
 * handle to a selection returned by one of the built-ins
 * <b>_alloc_selection</b> or <b>_duplicate_selection</b>.  A <i>mark_id</i> of
 * '' or no <i>mark_id</i> parameter identifies the active selection.
 *
 * @return  Returns 0 if successful.  Otherwise, TEXT_NOT_SELECTED_RC is
 * returned.
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Selection_Functions
 */
int _fill_selection(_str ch,_str mark_id="");


/**
 * Deletes the marked text specified.  No clipboard is created.
 *
 * @param mark_id is a handle to a selection returned by one of
 *                the built-ins <b>_alloc_selection</b> or <b>_duplicate_selection</b>.
 *                A <i>mark_id</i> of '' or no <i>mark_id</i> parameter identifies the
 *                active selection.  This function performs a "binary" delete when in
 *                hex mode (<b>p_hex_mode</b>==<b>true</b>).  A binary delete allows
 *                bisecting of end of line pairs like CR,LF.
 *
 * @return Returns 0 if successful.  Otherwise TEXT_NOT_SELECTED_RC is
 *         returned. On error, message is displayed.
 * @categories Selection_Functions
 */
int _delete_selection(_str mark_id="");
/**
 * Makes the mark corresponding to mark_id visible.  Currently only one
 * mark may be showing at a time.  <i>mark_id</i> is a handle to a
 * selection returned by one of the built-ins <b>_alloc_selection</b> or
 * <b>_duplicate_selection</b>.  A <i>mark_id</i> of '' or no
 * <i>mark_id</i> parameter identifies the active selection.
 *
 * @return Returns 0 if successful.  Otherwise
 * INVALID_SELECTION_HANDLE_RC is returned.  On error,
 * message is displayed.
 *
 * @categories Selection_Functions
 *
 */
int _show_selection(_str mark_id="");
/**
 * <p>Returns a handle to a selection or bookmark.  A selection requires 2 marks
 * and a bookmark requires one. If no more marks are available, a negative number
 * (TOO_MANY_SELECTIONS_RC) is returned.  This handle may be passed as a parameter
 * to other selection functions such as _select_line and _copy_to_cursor.  The
 * 'B' option is used for allocating a book mark.  Bookmarks can not be deleted.</p>
 *
 * <p>IMPORTANT: The active selection or selection showing may not be freed by the
 * _free_selection function.  Use the _show_selection function to make another
 * mark active before freeing the mark you have allocated.</p>
 *
 * @param option
 *
 * @return A handle to a selection of a bookmark.
 * @example <pre>
 * /* Allocate a selection for copying the current line. */
 * mark_id= _alloc_selection();
 * if (mark_id<0){
 *   message(get_message(mark_id));
 *   return(mark_id);
 * }
 * _select_line(mark_id);
 * _copy_to_cursor(mark_id);
 * // This selection can be freed because it is not the active selection.
 * _free_selection(mark_id);
 * </pre>
 *
 * @see _free_selection
 * @see _show_selection
 *
 * @categories Selection_Functions
 */
int _alloc_selection(_str option="");

/**
 *
 * @param markid
 *
 * @return If successful, a handle to a newly created selection identical to
 *         the selection specified.  Otherwise a negative error code is returned.
 *         Possible error codes are INVALID_SELECTION_HANDLE_RC or TOO_MANY_SELECTIONS_RC.
 *         <i>mark_id</i> is a handle to a selection returned by one of the built-ins
 *         <b>_alloc_selection</b> or <b>_duplicate_selection</b>.
 *         <p>
 *         <b>IMPORTANT:</b>  If an empty string ('') is specified for the <i>mark_id</i>
 *         parameter, a handle to the active selection is returned.  This is different
 *         than other selection functions which automatically assume the active selection
 *         and perform the same operation.
 *         <p>
 *         On error, message is displayed.
 * @example
 * <pre>
 * _deselect();_select_line();
 * mark_id=_duplicate_selection();  // Duplicate active selection
 * mark_showing=_duplicate_selection(''); // Save handle of active selection
 * _copy_to_cursor();
 * _show_selection(mark_id);  // Keep selection on source text.
 * _free_selection(mark_showing);   // Free selection on destination text.
 * </pre>
 * @categories Selection_Functions
 */

int _duplicate_selection(_str markid=null);


/**
 * Frees the selection handle or bookmark handle corresponding to
 * <i>mark_id</i>.  <b>_free_selection</b> will not free the active selection
 * (the one that is seen on screen).  Use <b>_show_selection</b> if necessary to
 * activate another selection before freeing the selection.  <i>mark_id</i> is a
 * handle to a selection returned by one of the built-ins
 * <b>_alloc_selection</b> or <b>_duplicate_selection</b>.  A <i>mark_id</i> of
 * '' or no <i>mark_id</i> parameter identifies the active selection.
 * @example
 * <pre>
 *          // Get handle to active selection
 *          current_mark_id=_duplicate_selection('');
 *          // Allocate another mark.
 *          mark_id=_alloc_selection();
 *          _select_line(mark_id);
 *          _show_selection(mark_id);get_event();
 *          _show_selection(current_mark_id);
 *          _free_selection(mark_id);
 * </pre>
 * @see  _alloc_selection
 *
 * @categories Selection_Functions
 */
void _free_selection(_str markid);


/**
 * Clears selection specified.  <i>mark_id</i> is a handle to a
 * selection returned by one of the built-ins <b>_alloc_selection</b>
 * or <b>_duplicate_selection</b>.
 *
 * @param mark_id a value of '' or no
 * <i>mark_id</i> parameter identifies the active selection.
 *
 * @categories Selection_Functions
 */
void _deselect(_str markid="");
/**
 * @return Returns the type or style information about the selection specified.
 *
 * @param mark_id is a selection handle allocated by the
 * <b>_alloc_selection</b> built-in.  A <i>mark_id</i> of '' specifies the
 * active selection or selection showing and is always allocated.  The
 * third parameter is only supported by the 'T' option.
 *
 * @param option may be 'T', 'S', 'P', 'I', or 'U'.
 *
 * <p>If a value of 'T' is specified for <i>option</i>, one of the selection
 * types "BLOCK", "CHAR", "LINE" or "" is returned.  If the third
 * parameter is specified, the selection style is set to <i>new_type</i>
 * which must be "BLOCK", "CHAR", or "LINE".  A null string is
 * returned if the selection specified has not been set.</p>
 *
 * <p>When a value of 'S' is specified for <i>option</i>, the select style is
 * returned.  Select styles are 'C' or 'E' which correspond to cut/paste
 * (selection extends as the cursor moves) or begin/end respectively.  A
 * null string is returned if the selection specified has not been set.</p>
 *
 * <p>If a value of 'P' is specified for <i>option</i>, selection anchor (pivot
 * point) information is returned.  The selection anchor information is a
 * two letter string and is used to determine how the selected area moves
 * as the cursor moves.  This option is only useful for cut/paste style
 * selections which extend the selection as the cursor moves.  The first
 * letter is 'B' if the begin mark is the line anchor or 'E' if it is not.  The
 * second letter is 'B' if the begin mark is the column anchor or 'E' if it is
 * not.  The null string is returned if the selection specified has not been
 * set.</p>
 *
 * <p>If a value of 'I' is specified for <i>option</i>, a '1' is returned if the
 * selection specified is an inclusive selection.  A '0' is returned if the
 * selection specified is non-inclusive.  A null string is returned if the
 * selection specified has not been set.  Currently this style affects only
 * character selections.</p>
 *
 * <p>When a value of 'U' is specified for <i>option</i>, a 'P' is returned if
 * the selection specified is a persistent mark.  Otherwise, '' is returned.</p>
 *
 * @categories Selection_Functions
 *
 */
int _select_type(_str markid="",_str option='T',_str newValue=null);
/**
 * @return Returns relative position where cursor should be placed in
 * resulting reflowed text output from the <b>_reflow_selection</b> function.
 * If the cursor does not need to be moved, <i>Noflines_down</i> will be a
 * negative number, otherwise <i>Noflines_down</i> indicates the number of lines
 * to move down in the reflowed text, and <i>col</i> specifies
 * the column to move to.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Selection_Functions
 *
 */
int _get_reflow_pos(int &Noflines_down,int &col);


/**
 * If the 'C' argument is specified the scroll style is set to center scrolling,
 * both horizontally and vertically.  The 'V' option specifies center
 * scrolling vertically, and smooth scrolling horizontally.
 * The 'H' option specifies center scrolling horizontally and smooth
 * scrolling vertically.  Otherwise, it is set to smooth scrolling
 * in both directions.
 * <p>
 * The scroll style affects the position of the cursor for
 * primitives which cause the cursor to move to
 * text that is not in view.  <i>number</i> specifies how close the cursor
 * may get to the top or bottom of the window before scrolling occurs.
 * For the <b>bottom</b> primitive, center scrolling style will also cause
 * the bottom line of the buffer to be centered when the end of the
 * bottom line is within view.  Scrolls style affects: <b>left</b>,
 * <b>right</b>, <b>up</b>, <b>down</b>, <b>_rubout</b>,
 * <b>tab</b>, <b>backtab</b>, <b>insert_line</b>, <b>keyin</b> and
 * any macro procedure or command which executes one of these
 * primitives.
 *
 * @param cmdline is a string in the format: C | V | H | S  [<i>number</i>]
 *
 * @categories CursorMovement_Functions
 *
 */
_str _scroll_style(_str newScrollStyle=null);

/**
 * Gets and/or sets the default search case sensitivity to exact or ignore
 * case and returns current case sensitivity.  'E' specifies case sensitive
 * searching by default.  'I' specifies case insensitive searching by default.
 * The built-in <b>search</b> command will default to this case unless
 * the 'E' or 'I' is specified to override the default.
 *
 * @see repeat_search
 * @see _select_match
 * @see match_length
 * @see search_replace
 * @see save_search
 * @see restore_search
 * @see search
 *
 * @categories Search_Functions
 *
 */
_str _search_case(_str option=null);

/**
 * Copies the file source_name to dest_name.
 *
 * @return  Returns 0 if successful.  Common return codes are:
 * ACCESS_DENIED_RC, ERROR_OPENING_FILE_RC, FILE_NOT_FOUND_RC,
 * INSUFFICIENT_DISK_SPACE_RC, ERROR_CREATING_DIRECTORY_RC,
 * ERROR_READING_FILE_RC, ERROR_WRITING_FILE_RC,  DRIVE_NOT_READY_RC,
 * and PATH_NOT_FOUND_RC.
 *
 *
 * @categories File_Functions
 */
int copy_file(_str source_filename,_str dest_filename);

int _file_touch(_str filename);
int _file_move(_str dest_filename,_str source_filename);

/**
 * NOTE: Under UNIX this function operates like the chmod command.
 * See man page for this command for syntax of arguments.
 * <pre>
 * <i>cmdline</i> is a string in the format: [+|-][R][H][S][A] <i>filename</i>
 *
 * Changes the attributes of the <i>filename</i> specified.  + adds the attribute
 * and - removes the attribute.  The attributes have the following meaning:
 *    R        Read-only
 *    H        Hidden
 *    S        System
 *    A        Archive
 * </pre>
 *
 * @return Returns 0 if successful.  Common return codes are FILE_NOT_FOUND_RC, PATH_NOT_FOUND_RC,
 * ERROR_WRITING_FILE_RC, and INVALID_OPTION_RC.  On error, message is displayed.
 *
 * @categories File_Functions
 */
int _chmod(_str cmdline);


/**
 * Changes to drive and directory specified.  If <i>changeDrive</i>
 * is non-zero the current working drive is changed to drive specified.
 *
 * @return  Returns 0 if successful.  Common return code is PATH_NOT_FOUND_RC.
 *
 * @categories File_Functions
 */
int chdir(_str path,int changeDrive=0);
/**
 * Removes directory specified by <i>path</i>.
 *
 * @return Returns 0 if successful.  Common return codes are
 * PATH_NOT_FOUND_RC and ACCESS_DENIED_RC.
 *
 * @categories File_Functions
 *
 */
int rmdir(_str path);
int mkdir(_str path);
/**
 * @return Returns the current working directory for the <i>drive</i>
 * specified.  <i>drive</i> must be a one-character drive letter.  The
 * <i>drive</i> argument is ignored under UNIX.
 *
 * @example
 * <pre>
 *          message getcwd()      /* Display current working directory. */
 *          message getcwd('D')  /* Display current working directory of
 * drive D */
 * </pre>
 *
 * @categories Miscellaneous_Functions
 *
 */
_str getcwd(_str path);
/**
 * @return Returns the process id of SlickEdit.
 *
 * @categories Miscellaneous_Functions
 *
 */
int getpid();
/**
 * Searches the path specified for a file or program.  The path given with
 * the filename is searched first.  Then the directories specified by the
 * environment variable <i>env_var</i> are searched.
 *
 * @return If successful, a complete file specification for a filename is returned.
 * Otherwise '' is returned.
 *
 * @param options is a string of zero or more of the following:
 *
 * <dl>
 * <dt>'P'</dt><dd>Program search.  Does not effect UNIX.</dd>
 * <dt>'M'</dt><dd>Program search including search for .e and .ex Slick-
 * C batch macros.</dd>
 * <dt>'S'</dt><dd>Don't search in current directory.  Does not effect
 * UNIX.</dd>
 * </dl>
 *
 * <p>Non-UNIX platforms:  The search order for a program or macro is:</p>
 *
 * <dl>
 * <dt>.com</dt>
 * <dt>.exe</dt>
 * <dt>.e</dt><dd>(if M option specified)</dd>
 * <dt>.ex</dt><dd>(if M option specified)</dd>
 * <dt>.bat</dt><dd>(Windows and Windows 95/98 only)</dd>
 * <dt>.cmd</dt><dd>(Windows NT only)</dd>
 * </dl>
 *
 * <p>UNIX:  The search order for a program or macro is:</p>
 *
 * <dl>
 * <dt>filename</dt><dd>(No changes to filename)</dd>
 * <dt>.e</dt><dd>(if M option specified)</dd>
 * <dt>.ex</dt><dd>(if M option specified)</dd>
 * </dl>
 *
 * @example
 * <pre>
 * name=path_search('vs','PATH','P');  // Find vs.exe
 * name=path_search('draw','PATH','M');   // Find external draw
 * macro
 * name=path_search('vslick.ini');  // Find ini file
 * </pre>
 *
 * @categories File_Functions
 *
 */
_str path_search(_str filename ,_str env_var="PATH",_str options="",_str dotExtList=null);

/**
 * Deletes the <i>filename</i> specified.
 *
 * @return  Returns 0 if successful.  Common return codes are
 * ACCESS_DENIED_RC, ERROR_OPENING_FILE_RC, FILE_NOT_FOUND_RC,
 * DRIVE_NOT_READY_RC, and PATH_NOT_FOUND_RC.
 * @categories File_Functions
 */
int delete_file(_str filename);
/**
 * Returns f<i>ilename</i> with exact path specification as if the current directory was <i>toDir</i>.
 *
 * @param filename The filename to build the path for.
 * @param toDir    The directory to use as the current working directory.  If null, the current directory is used.
 *
 * @return A string containing the absolute path to the filename.
 * @example <pre>
 * /* Assuming current working directory is 'c:\vslick' */
 *
 * absolute('..\autoexec.bat')      :== 'c:\autoexec.bat'
 * absolute('vs.exe')               :== 'c:\vslick\vs.exe'
 * absolute('vs.exe','d:\vslick\')  :== 'd:\vslick\vs.exe'
 * </pre>
 *
 * @see relative
 *
 * @categories File_Functions
 */
_str absolute(_str filename,_str toDir=null);
/**
 * @return Returns <i>filename</i> with relative path specification as if the
 * current directory was <i>toDir</i>.  If <i>toDir</i> is null, the current
 * directory is used.
 *
 * @example
 * <pre>
 *          /* Assuming current working directory is 'c:\vslick' */
 *
 *          relative('c:\vslick\vs.exe') == 'vs.exe'
 *          relative('d:\vslick\vs.exe','d:\vslick') == 'vs.exe'
 *          relative('c:\autoexec.bat') == 'c:\autoexec.bat'
 * </pre>
 *
 * @see absolute
 *
 * @categories File_Functions
 *
 */
_str relative(_str filename,_str toDir=null,boolean addDotDots=true);
/**
 * @return Returns a binary string representation of the last event returned
 * from <b>get_event</b> or <b>test_event</b>.  If the <i>event</i> parameter is
 * specified, the last event is set to <i>event</i>.  For ASCII keys, a string
 * of length 1 is returned.  For extended keys like Alt+L, and ESC, a string of
 * length 2 or 3 is returned.  Use the <b>mou_mode</b> function if you want
 * button-up events returned by <b>get_event</b>.
 *
 * @param newEvent   set the last event
 * @param keysOnly   report only the last keyboard event, no MOUSE_MOVE, etc.
 * @example
 * <pre>
 *          event=get_event();
 *          message('The key pressed was 'event2name(last_event()));
 * </pre>
 *
 * @see get_event
 * @see test_event
 * @see call_key
 * @see event2name
 * @see event2index
 * @see index2event
 * @see list_bindings
 * @see name2event
 * @see eventtab_index
 *
 * @categories Keyboard_Functions
 *
 */
_str last_event(_str newEvent=null, boolean keysOnly=false);
/**
 * @return Tests to see if a key or mouse message is available.  If a key is ready, a
 * binary string representation of the key is returned.  If no key is
 * available, '' is returned.    For ASCII keys a string of length 1 is
 * returned.  For  extended keys, like Alt+L, and Backspace, a string of
 * length 2 or 3 is returned.
 *
 * <p>If the 'R'  is not given, the screen is refreshed.</p>
 *
 * @param options  defaults to '' and may be 'R' and/or 'K':
 *
 * <dl>
 * <dt>'R'</dt><dd>Specifies no screen refresh.</dd>
 * <dt>'K'</dt><dd>Return keys from physical keyboard and not
 * keyboard macro that is being played back.</dd>
 * <dt>'P'</dt><dd>UNIX only.  Causes all messages except keyboard
 * messages to be dispatched before testing for a key
 * or mouse event.  This is necessary because the
 * UNIX version can only look at the top message on
 * the message queue.  This option is ignored under
 * non-UNIX platforms.</dd>
 * </dl>
 *
 * @see get_event
 * @see last_event
 * @see call_key
 * @see event2name
 * @see event2index
 * @see index2event
 * @see list_bindings
 * @see name2event
 * @see eventtab_index
 *
 * @categories Keyboard_Functions
 *
 * @deprecated Use {@link _IsKeyPending} or {@link _IsEventPending} instead.
 */
_str test_event(_str options="");
/**
 * @return Waits for a key to be pressed and returns a binary string
 * representation of the key typed.  For ASCII keys a string of length 1 is
 * returned except for extended keys such as Ctrl+ENTER, Ctrl+BACKSPACE, Alt+A,
 * Ctrl+A, etc.  For extended keys a string of length 2 or 3 is returned.
 *
 * @param options defaults to '' and may be one or more of the
 * following:
 *
 * <dl>
 * <dt>'R'</dt> <dd>Specifies no screen refresh.</dd>
 * <dt>'K'</dt><dd>Return keys from physical keyboard and not keyboard macro that is
 * being played back.</dd>
 * <dt>'N'</dt><dd>Get next key.  When a Slick-C&reg; macro uses <b>get_event</b> for
 * multiple key sequence key bindings, all <b>get_event</b> calls after the
 * first should pass this parameter.  Otherwise key stroke recording will not
 * work since terminating key stroke recording requires that the last key
 * sequence be removed.</dd>
 * <dt>'D'</dt><dd>Return and possibly set the prefix key delay in 10ths of seconds.
 * To set the prefix key delay, concatenate a number to the 'D'.  For example,
 * the parameter 'D4' sets the prefix key delay to .4 seconds.  The current or
 * new prefix key delay is returned.</dd>
 * <dt>'B'</dt><dd>Reset mouse button click count to zero.</dd>
 * <dt>'U'</dt><dd>Always return unshifted key with SHIFT 
 * modifier (Ex: '<' = Shift+,).</dd> 
 * <dt>'F'</dt><dd>Ignore FocusIn events coming to the 
 * command line</dd> 
 * </dl>
 *
 * <p>
 * If 'R' option is not given, the screen is refreshed.
 * </p>
 *
 * @example
 * <pre>
 *      key=get_event();
 *      message('The key pressed was 'event2name(key));
 * </pre>
 *
 * @see pgetkey
 * @see test_event
 * @see last_event
 * @see call_key
 * @see event2name
 * @see event2index
 * @see index2event
 * @see list_bindings
 * @see name2event
 * @see eventtab_index
 *
 * @categories Keyboard_Functions
 *
 */
_str get_event(_str options="");


/**
 * Waits <i>secondsX100</i> is in hundredths of a second.  If 'K'
 * is specified for <i>option</i>, this function returns when a key is pressed.
 * @categories Miscellaneous_Functions
 */
void delay(int secondsX100,_str option="");
/**
 * Returns execution to the statement after the last <b>_suspend</b>.
 * This function is used in conjunction with <b>_suspend</b> to check
 * for critical errors which halt the interpreter.  Critical errors which halt
 * the interpreter automatically issue a <b>_resume</b>.  If a
 * <b>_suspend</b> was issued, the following statement receives control
 * and can check the <b>rc</b> variable to determine the reason for the
 * <b>_resume</b>.  Before executing the <b>_resume</b> statement
 * you will want to set the <b>rc</b> variable to a positive value to
 * distinguish your resume codes from internal error codes which are
 * negative.
 *
 * @example
 * <pre>
 * _suspend(); // rc is set to 0 by
 * _suspend in first pass.
 * if (rc ) {
 *      if (rc==1) { // normal return?
 *          return(0);
 *      }
 *      message('Please specify floating point number');
 *      return(1);
 * }
 * // If arg(1) is not a valid number, run time error will occur which
 * cause _resume
 * f=arg(1);
 * ++f;
 * // Indicate normal return
 * rc=1;
 * _resume();
 * </pre>
 *
 * @see _suspend
 *
 * @categories Miscellaneous_Functions
 *
 */
void _resume();
/**
 * Pushes a new level for a signal handler.  After a <b>_suspend</b> has
 * been executed, errors which halt the interpreter will set the variable
 * <b>rc</b> to the error code and <b>_resume</b> execution at the
 * first statement after <b>_suspend</b>.  The <b>_resume</b> function
 * restores the interpreter stack and code position to the state it was in
 * after the last <b>_suspend</b> was executed.  Be sure to execute
 * <b>_resume</b> to restore the previous signal handler.  This function
 * sets the <b>rc</b> variable to 0 if successful.  Interpreter is stopped if
 * too many suspends are performed.
 *
 * @example
 * <pre>
 * _suspend(); // rc is set to 0 by
 * _suspend in first pass.
 * if (rc) {
 *      if (rc==1) { // normal return?
 *          return(0);
 *      }
 *      message('Please specify floating point number');
 *      return(1);
 * }
 * // If arg(1) is not a valid number, run time error will occur which
 * cause _resume
 * f=arg(1);
 * ++f;
 * // Initiate normal return
 * rc=1;
 * _resume();
 * </pre>
 *
 * @see signal_handler
 * @see _resume
 *
 * @categories Miscellaneous_Functions
 *
 */
int _suspend();


/**
 * @return Returns length of the path in the string <i>filename</i> including
 * trailing backslash.
 *
 * @categories File_Functions
 *
 */
int pathlen(_str filename);
/**
 * This function has been deprecated.  It has the same effect as calling
 * {@link activate_window}().
 *
 * @categories Window_Functions
 * @AppliesTo All_Window_Objects
 * @deprecated Use {@link activate_window()}. 
 */
void activate_view(int view_id);
/**
 * Determines the current object/current window.
 *
 * @param window_id  ID of window
 *
 * @example
 * <pre>
 * #include "slick.sh"
 * defmain()
 * {
 *    //  Calling a function as a method like below
 *    _mdi.p_child.myproc();
 *
 *    // is identical to the code below
 *    new_wid= _mdi.p_child;
 *    orig_wid=p_window_id;
 *    p_window_id=new_wid;
 *    myproc();
 *    p_window_id=orig_wid;
 * }
 * static myproc()
 * {
 * }
 * </pre>
 *
 * @categories Window_Functions
 * @AppliesTo All_Window_Objects
 *
 * @see p_window_id
 * @see get_window_id
 * @see load_files
 * @see _next_window
 * @see _prev_window
 * @see _delete_window
 * @see _open_temp_view
 * @see _delete_temp_view
 * @see _create_window
 */
void activate_window(int window_id);
/**
 * This function has been deprecated.  It has the same effect as calling
 * {@link get_window_id}().
 *
 * @categories Window_Functions
 * @AppliesTo All_Window_Objects
 * @deprecated Use {@link get_window_id()}.
 */
void get_view_id(int &view_id);
/**
 * Determines the current object/current window.  This function has the same effect
 * as setting the {@link p_window_id} property.
 *
 * @example
 * <pre>
 * get_window_id(window_id);   // Remember current window
 * _next_window();           // Switch to next window
 * activate_window(window_id); // Go back to orig. window
 * </pre>
 *
 * @see activate_window
 * @see load_files
 * @see _next_window
 * @see _prev_window
 *
 * @appliesTo All_Window_Objects
 *
 * @categories Buffer_Functions, Window_Functions
 *
 */
void get_window_id(int &window_id);

/**
 * Returns and/or sets the cursor shape settings for insert mode, replace mode,
 * virtual insert mode, and virtual replace mode.  The returned string is in
 * the same format as the input string.  Top and bottom refer to character
 * vertical scan lines.  The cursor is said to be in virtual space if it is
 * past the end of a line or in the middle of a tab character.  To make this
 * function independent of hardware, this function maps the numbers 1 to 1000
 * to the actual number of vertical scan lines in a character.
 * <p>
 * If the -v option
 * is given, all options that follow are ignored and two vertical cursor shapes
 * are selected.  A thin vertical cursor for insert mode and a fat vertical cursor
 * for replace mode.
 *
 * @param cmdline is a string in the format:
 * <pre>
 *         [-v] <i>ins_top ins_bot rep_top rep_bot vins_top vins_bot vrep_top vrep_bottom</i>
 * </pre>
 *
 * @categories Miscellaneous_Functions
 *
 * @return   */
_str _cursor_shape(_str cmdline=null);
/**
 * @return Returns the default path for the editor spill file.  When <i>path</i> is
 * not null, the default spill file path is set to <i>path</i>.  If the spill file
 * has already been created due to insufficient memory, this function has
 * no effect on this session.
 *
 * @categories File_Functions
 *
 */
_str _spill_file_path(_str path=null);

/**
 * The <i>buffer_ksize </i>parameter sets the maximum size of the text buffer cache.
 * If <i>buffer_ksize</i> is less than zero, the cache will grow until no memory is available.
 * In most cases, SlickEdit's cache is 3 times faster than the operating system cache.
 * This means that you will want SlickEdit's buffer cache size small enough that the
 * operating system does not swapping memory SlickEdit is using to disk.  When the cache
 * is full, text is written to a spill file "$slk.<i>nnn</i>" where <i>nnn</i> is a number.
 * When the buffer cache size is set to a small value you may need to change the read ahead/read
 * behind line setting to avoid disk thrashing.  If the DISK light stays on too long while you
 * scroll your text files, execute the command "set-var def-read-ahead-lines 0" to avoid the problem.
 * <p>
 * The <i>state_ksize</i> parameter specifies the maximum amount of swappable state file data (parts
 * of "vslick.sta" or "vslick.stu" under UNIX) to be kept in memory.  -1 specifies no limit.
 * The -ST invocation option may be used to specify the state cache size.  Modifying the state cache
 * size may not take effect until the editor is reinvoked.  When you specify 0 as the argument to
 * the -ST invocation , this specifies to preload the entire state file and close the file handle.
 * This function does NOT support the "-ST 0" feature.
 *
 * @param cmdline is a string in the format: <i>buffer_ksize</i> [<i>state_ksize</i> ]
 *
 * @return A string of the current cache size values is returned.  On error message, is displayed.
 *
 * @categories File_Functions
 */
_str _cache_size(_str cmdline=null);
/**
 * Sends a Ctrl+Break signal to the build window created by the
 * built-in function <b>concur_shell</b>.
 *
 * @see concur_shell
 * @see _process_info
 *
 * @categories Miscellaneous_Functions
 *
 */
void _stop_process();
/**
 * Posts a calls to the Slick-C&reg; function corresponding to name table
 * index, proc_index, and optional passes the first argument, arg1.  The
 * call is made after the editor returns to a message loop.  This function
 * should only be used under circumstances where an operation can not be
 * performed immediately.  The dialog editor uses this function to display
 * error message boxes during on_lost_focus events.  During the
 * on_got_focus and on_lost_focus events you can not display a dialog box.
 * Use find_index to get an index to a global function.
 *
 * @param pfnCallback         pointer to function to call
 * @param CallbackArgument    argument to pass to function
 *
 * @categories Miscellaneous_Functions
 */
int _post_call(typeless pfnCallback,_str CallbackArgument=null);

/**
 * @return
 * Returns 'WINDOWS' if running under Windows NT or newer on an Intel compatible
 * machine.  Returns 'NT386' if running under Windows NT on 386 compatible machine.
 * Returns 'NTMIPS' if running under Windows NT on
 * MIPS/compatible machine.  Returns NTALPHA if running under Windows NT
 * on a DEC ALPHA AXP machine.  Returns 'SPARC' if running under SUN SPARC
 * station.  Returns 'RS6000' if running under AIX RS600.  Returns 'NTPPC'
 * if running under Windows NT on a PowerPC.  Returns 'LINUX' if running
 * under LINUX on Intel machine.  Returns 'HP9000' if running under UNIX
 * on HP9000.  Returns 'SGMIPS' if running under UNIX on Silicon Graphics
 * machine. Returns 'MACOSX11' if running under Mac OS X on a PowerPC.
 * <ul>
 * <li>"WINDOWS"      -- Windows NT or newer on Intel compatible machine.
 * <li>"PCDOS"        -- Windows 3.1
 * <li>"PCDOSP"       -- Windows 3.1 protected mode?
 * <li>"NTPPC"        -- Windows NT on a PowerPC.
 * <li>"NTMIPS"       -- Windows NT on MIPS/compatible machine.
 * <li>"NTALPHA"      -- Windows NT DEC ALPHA AXP machine.
 * <li>"NT386"        -- Windows NT on 386 compatible machine.
 * <li>"OS2386"       -- OS/2 on 386 compatible machine
 * <li>"OS2PPC"       -- OS/2 on PowerPC.
 * <li>"LINUX"        -- LINUX on Intel machine.
 * <li>"SPARCSOLARIS" -- Sun Solaris on Sun SPARC station.
 * <li>"SPARC"        -- SUN SPARC station.
 * <li>"RS6000"       -- AIX RS600.
 * <li>"M88K"         -- Unix on Motorola 88K
 * <li>"HP9000"       -- UNIX/HPUX on HP9000.
 * <li>"SGMIPS"       -- UNIX/Irix on Silicon Graphics machine.
 * <li>"EPMIPS"       --
 * <li>"UNIXWARE"     -- Unixware on Intel compatible machine.
 * <li>"ALPHAOSF"     -- OSF/1 on DEC ALPHA AXP machine.
 * <li>"INTELSOLARIS" -- Sun Solaris on Intel compatible machine.
 * <li>"DECULTRIX"    -- DEC Ultrix on MIPS
 * <li>"SCO"          -- SCO on Intel compatible machine.
 * <li>"FREEBSD"      -- FreeBSD on Intel compatible machine.
 * <li>"UNIXWARE"     -- UnixWare on Intel compatible machine.
 * <li>"S390"         -- Operating System/390
 * <li>"LINUXON390"   -- Linux on System/390 
 * <li>"MACOSX"       -- Native Mac OS X 
 * <li>"MACOSX11"     -- Mac OS X under X11
 * </ul>
 *
 * @see _win32s
 * @see machine_bits 
 *
 * @categories Miscellaneous_Functions
 *
 */
_str machine();

/**
 * @return
 * Returns '64' if running a 64-bit version of SlickEdit on a platform 
 * such as 64-bit Windows 7 or Linux.  Otherwise, return '32'. 
 * <P> 
 * Note that the result is not based on what OS you are running under, 
 * but rather what version of the editor you are running.  This function 
 * can return '32' even if you are running a 64-bit OS if you are running 
 * 32-bit SlickEdit in a compatiblity mode. 
 *  
 * @see _win32s 
 * @see machine 
 *
 * @categories Miscellaneous_Functions
 *
 */
_str machine_bits();

/**
 * Returns message corresponding to error number error_code.
 * If error_code does not exists, "Message not available" is returned.
 * If the error_code argument is not given or is MAXINT,
 * the message currently displayed on the SlickEdit message line is returned.
 * The error codes are listed in the file "rc.sh".
 *
 * @param rc   error status to look up 
 *             Also can pass in the following special arguments
 *             <ul> 
 *             <li><b>-age</b> -- return the age of the current message on the message line 
 *             <li><b>-sticky</b> -- return 'true' if the current message on the message line is sticky
 *             <li><b>-sticky_age</b> -- return the age of the current message, even if it is a sticky message 
 *             </ul>
 * @param s0   string to replace %s0 with
 * @param s1   string to replace %s1 with
 * @param sN   string to replace %sN with
 *
 * @return Message string for the given error code with arguments collated.
 *
 * @categories String_Functions
 */
_str get_message(int rc=MAXINT, ...);


/**
 * Clears the message line and any pending message.
 *
 * @example
 * <pre>
 * _deselect();
 * _select_line();   // Cause pending message "Text not selected".
 * clear_message();  // Message will not get displayed.
 * </pre>
 *
 * @see message
 * @see messageNwait
 * @see _message_box
 * @see popup_message
 * @see popup_imessage
 * @see sticky_message
 * @categories Miscellaneous_Functions
 */
void clear_message();
/**
 * @param   string is temporarily displayed on the message line.  Message
 * will disappear after a key is pressed.
 *
 * @see sticky_message
 * @see _message_box
 * @see clear_message
 * @see messageNwait
 * @see popup_message
 * @see popup_imessage
 *
 * @categories Miscellaneous_Functions
 *
 */
void message(_str msg);
/**
 * @param string is displayed on the message line.  Message will remain
 * on the message line until another message is displayed or
 * <b>clear_message</b> is called.
 *
 * @see message
 * @see clear_message
 * @see messageNwait
 * @see _message_box
 * @see popup_message
 * @see popup_imessage
 *
 * @categories Miscellaneous_Functions
 *
 */
void sticky_message(_str msg);
/**
 * @return
 * Returns display name or buffer name of the buffer with prefix matching
 * name_prefix.  A non-zero value for find_first, begins a new search.  If
 * find_first is zero, the next matching buffer id is returned.  '' is
 * returned if no match is found.  Search is not case sensitive except for
 * file systems like UNIX which are case sensitive.  The global rc
 * variable is set to a non-zero value if there are no more matches.
 *
 * @param name_prefix         Prefix to search for
 * @param find_first          A non-zero value for find_first begins a new search,
 *                            otherwise, the next matching buffer is returned.
 * @param options_letters     A string of one or more of the following:
 *    <ul>
 *    <li>H -- Return buffers with (p_buf_flags & VSBUFFLAG_HIDDEN) true.
 *    <li>E -- Exact buffer name match instead of prefix matching.
 *    <li>X -- Same as E option.
 *    <li>V -- If the 'V' (verbose) option is specified,
 *             a string of the following form is returned:
 *             <pre>buf_id modify buf_flags buf_name</pre>
 *    <li>B -- Find buffer names only.
 *    <li>D -- Find document names only.
 *    <li>I -- Return buffer ID only
 *    <li>N -- Match the file name only (not the whole path or a
 *             prefix)
 *    <li>A -- name_prefix is an absolute filename with
 *             symlinks resolved
 *    </ul>
 *
 * @example
 * <pre>
 *    // Find names that start with p
 *    name_prefix='p';
 *    // Find first.  return verbose information.
 *    buf_info= buf_match(name_prefix,1,'v');
 *    for (;;) {
 *       if (rc) break;
 *       parse buf_info with buf_id ModifyFlags buf_flags buf_name;
 *       messageNwait('id='buf_id' ModifyFlags='ModifyFlags' flags='buf_flags' name='buf_name);
 *       buf_info= buf_match(name_prefix,0,'v');    // find next
 *    }
 * </pre>
 *
 * @see find_index
 * @see name_match
 * @see file_match
 * @categories Buffer_Functions
 */
_str buf_match(_str name_prefix,int find_first,_str options="");

/**
 * @return Return value depends on input.
 *
 * @param option defaults to 'E' if not given or ''.
 * @param new_value (optional). Set new value for option.
 *                  Only valid for 'R' option.
 * <pre>
 * Input Return Value
 * 'E'   Invocation name of editor.  (argv[0])
 * 'P'   Absolute editor executable path with trailing backslash.
 * 'S'   Absolute state file name.
 * 'R'   Absolute auto restore file name.
 *       If new_value!=null, then option is set to new_value and
 *       new_value is returned.
 * 'V'   DDE server name.
 * </pre>
 * @categories Miscellaneous_Functions
 */
_str editor_name(_str option='E', _str new_value=null);

/**
 * Sets the screen element corresponding to <i>ColorIndex</i> to the foreground
 * and background colors given. The <i>fg_color</i> and <i>bg_color</i> parameters
 * specify an RGB color.  Use the <b>_rgb</b> function to build these colors.
 *
 * @param ColorIndex is one of the following constants defined in "slick.sh":
 *                   <UL>
 *                   <LI>CFG_CLINE
 *                   <LI>CFG_CURSOR
 *                   <LI>CFG_SELECTION
 *                   <LI>CFG_SELECTED_CLINE
 *                   <LI>CFG_MESSAGE
 *                   <LI>CFG_STATUS
 *                   <LI>CFG_WINDOW_TEXT
 *                   </UL>
 * @param fg_color   foreground color (RGB)
 * @param bg_color   background color (RGB)
 * @param font_flags is one of the following font flags:
 *                   <UL>
 *                   <LI>F_BOLD
 *                   <LI>F_ITALIC
 *                   <LI>F_STRIKE_THRU
 *                   <LI>F_UNDERLINE
 *                   <LI>F_INHERIT_STYLE
 *                   </UL>
 * @param ParentIndex parent color index to inherit color or font 
 *                    attributes from.
 *
 * @return Returns the current foreground, background, and font flags
 * setting for the field specified each separated with a space.
 * @categories Miscellaneous_Functions 
 *  
 * @see _AllocColor 
 * @see _rgb 
 */
_str _default_color(int ColorIndex, 
                    int fg_color=-1,int bg_color=-1,
                    int font_flags=-1,int ParentIndex=0);


/**
 * Gets and optionally sets an editor default font.
 *
 * @param fieldnum is one of the following constants defined in "slick.sh":
 * <UL>
 *    <LI>CFG_CMDLINE
 *    <LI>CFG_MESSAGE
 *    <LI>CFG_STATUS
 *    <LI>CFG_WINDOW_TEXT
 * </UL>
 * @param   font  is a string in the format: <i>font_name</i>, <i>font_size</i>, <i>font_flags</i>
 * @param   font_size   is a font point size.
 * @param   font_flags  is a combination of the following flags defined in "slick.sh":
 * <UL>
 *    <LI>F_BOLD
 *    <LI>F_ITALIC
 *    <LI>F_STRIKE_THRU
 *    <LI>F_UNDERLINE
 * </UL>
 * @example
 * <pre>
 * // Set the default command line.
 * font="Courier,10,"(F_BOLD|F_ITALIC)
 * _default_font(CFG_CMDLINE, font);
 * </pre>
 * @return  Returns the current font string value in the same format as the <i>font</i> argument.
 * @categories Miscellaneous_Functions
 */
_str _default_font(int fieldnum,_str font="");
/**
 * <p>Runs the external program specified.  The program parameter should
 * include arguments to be passed to the program as well.</p>
 *
 * <p>A positive or 0 return code indicates the return code is from the
 * program executed.  A negative return code indicates one of the OS or
 * SlickEdit return codes listed in "rc.sh".</p>
 *
 * @param options defaults to '' and may be one or more of the following:
 *
 * <dl compact style="margin-left:20pt">
 * <dt>'Q'</dt><dd>Run program without showing console window.  DO NOT 
 * USE WITH 'W' OPTION.</dd> 
 *
 * <dt>'P'</dt><dd>Do not search for SlickEdit batch programs.</dd>
 *
 * <dt>'A'</dt><dd>Run program asynchronously.</dd>
 *
 * <dt>'W'</dt><dd>Run slkwait program to wait for a key press before
 * closing application.  DO NOT USE WITH 'Q' OPTION.  Under UNIX, this 
 * argument is ignored if <i>shell_processor</i> is specified.</dd> 
 *
 * <dt>'N'</dt><dd>No command processor.  Use this option when you
 * notice an extra command shell window is created
 * when you are trying to run a windows program.  By
 * default, if any command shell special characters
 * (ex.  '>', '&lt;',  '|'.  There are others.) are found in the
 * <i>program</i> argument, the command processor
 * is used to process the <i>program</i> argument.
 * This can cause a command shell window to be
 * created when you are trying to run a windows
 * program.</dd>
 *
 * <dt>'B'</dt><dd>Allow user to break by pressing Ctrl+Alt+Shift
 * (Windows only).</dd>
 * </dl>
 *
 * <p>For UNIX, the <i>shell_processor</i> argument allows you to specify
 * an alternate shell command line to parse the <i>command</i> string
 * specified.  For non-UNIX platforms, this argument is ignored.
 * <i>shell_processor</i> defaults to  "<b>$SHELL -c</b>".  For
 * backward compatibility with SlickEdit, if
 * <i>shell_processor</i> does not contain a space, "<b> -c</b>" is
 * concatenated on to the end of the string.</p>
 *
 * @example
 * <pre>
 *           shell("cl -c test.c >$errors.tmp");
 *           shell("man cc","","xterm -T "man" -e /bin/sh -c");
 * </pre>
 *
 * @categories File_Functions
 *
 */
int shell(_str program, _str options="",_str shell_processor="",int &process_id=null);
int shell_state();


int _tbQRefreshBy();
int _tbSetRefreshBy(int tbRefreshBy);
_str _BufDate(int buf_id);


/**
 * Convert EBCDIC character to ASCII if the 
 * editor is compiled with EBCDIC support. 
 * 
 * @param EBCDIC character. 
 * @return ASCII character. 
 *  
 * @categories String_Functions 
 */
_str _maybe_e2a(_str string);
/**
 * Convert EBCDIC character to ASCII string.
 * 
 * @param EBCDIC character. 
 * @return ASCII character. 
 *  
 * @categories String_Functions 
 */
_str _e2a(_str string);
/**
 * Convert ASCII character to EBCDIC.
 * 
 * @param ASCII character. 
 * @return EBCDIC character. 
 *  
 * @categories String_Functions 
 */
_str _a2e(_str string);

/**
 * Get a list of active process on the current system.
 *
 * @param process_list     array of process info to populate
 *
 * @categories Miscellaneous_Functions
 */
int _list_processes(PROCESS_INFO (&process_list)[]);

/**
 * Determine if process has exited.
 *
 * @param pid Process id to test.
 *
 * @return true if process is exited.
 */
boolean _IsProcessRunning(pid);


/**
 * Perform a Unicode (or DBCS) string compare.  Compare is
 * typically Unicode except for OEM's which may start the
 * editor in non-Unicode mode.
 *
 * @param s1     String 1
 * @param s2     String 2
 *
 * @return <dl compact>
 *         <dt>1<dd>s1>s2
 *         <dt>0<dd>s1==s2
 *         <dt>-1<dd>s1<s2
 *         </dl>
 *
 * @see stricmp
 *
 * @categories String_Functions
 */
int strcmp(_str s1,_str s2);
/**
 * Perform a case insensitive Unicode (or DBCS) string compare.  Compare is
 * typically Unicode except for OEM's which may start the
 * editor in non-Unicode mode.
 *
 * @param s1     String 1
 * @param s2     String 2
 *
 * @return <dl compact>
 *         <dt>1<dd>s1>s2
 *         <dt>0<dd>s1==s2
 *         <dt>-1<dd>s1<s2
 *         </dl>
 * @see strcmp
 *
 * @categories String_Functions
 */
int stricmp(_str s1,_str s2);


/**
 * This method allows you to subdived a single label control into
 * multiple labels with borders and various options.  <i>index</i> starts
 * at 0 and indicates which label you are setting the <i>width</i>,
 * <i>flags</i>, and <i>state</i> for.  You must initialially create
 * multiple labels in order (that is 0,1,2... etc.).
 *
 * @example
 * <pre>
 * // Create a form with a label control named label1
 * void label2.on_create()
 * {
 *
 * }
 * </pre>
 *
 * @appliesTo Label
 *
 * @categories Label_Methods
 *
 */
void _SetMultiLabelProp(int index,_str caption,int styles,int min_width,int max_width,int alignment_flags);
/**
 * @return Returns Unicode character index corresponding to the UTF-8
 * sequence given.  If SlickEdit is not running in UTF-8 mode (
 * _UTF8()==0 ), this function operates identically to the <b>_asc</b>
 * function.
 *
 * @categories Unicode_Functions
 */
int _UTF8Asc(_str UTF8Sequence);

/**
 * Performs text substitution used by searchreplace without
 * modifying buffer.  Substitution includes RE groups and handles
 * preserve case options.
 *
 * @param replace_string Replace string.
 *
 * @return Destination replacement text.
 *
 * @see search
 * @see search_replace
 *
 * @categories Search_Functions
 */
_str get_replace_text(_str replace_string);

/**
 * Compare size and dimensions of selection handles.
 * Used to compare duplicated selection handles for equality.
 * mark1_id and mark2_id are a handle to a selection returned by
 * one of the built-in _alloc_selection or _duplicate_selection.
 *
 * @param mark1_id   selection handle
 * @param mark2_id   selection handle
 *
 * @return 0, if selections are equal
 *
 * @see _alloc_selection
 * @see _duplicate_selection
 * @see _free_selection
 * @see _get_selinfo
 *
 * @categories Selection_Functions
 */
int _compare_selection(_str mark1_id, _str mark2_id);



/**
 * Restores inactive bookmarks for the file specified.  This function is typically
 * called when a new file is loaded, so that inactive bookmarks may be restored.
 *
 * @param vsbmflags  One or more of these flags must be in the bookmark for the bookmark to be restored.
 *
 * @see _BookmarkAdd
 * @see _BookmarkRemove
 * @see _BookmarkRestore
 * @see _BookmarkGetInfo
 * @see _BookmarkFind
 * @see _BookmarkQCount
 *
 * @categories Bookmark_Functions
 *
 */
void _BookmarkRestore(int vsbmflags=-1);


/**
 * Deletes a bookmark.
 *
 * @param i      Index of bookmark where 0&lt;=i&lt;_BookmarkQCount().
 * @param free_markid
 *               When non-zero, <b>_free_selection</b> is called for the markid belonging to this bookmark.
 *
 * @see _BookmarkAdd
 * @see _BookmarkRemove
 * @see _BookmarkRestore
 * @see _BookmarkGetInfo
 * @see _BookmarkFind
 * @see _BookmarkQCount
 *
 * @categories Bookmark_Functions
 */
void _BookmarkRemove(int i,int free_markid=1);

/**
 * Adds a new bookmark.
 *
 * @param BookmarkName
 *                  Name of bookmark to add.
 * @param markid    Selection id returned from <b>vsAllocSelection</b> or <b>vsDuplicateSelection</b>.
 * @param vsbmflags Combination of VSBMFLAGS_??? ORed together.
 * @param RealLineNumber
 *                  Real line number of bookmark.  Specify -1 if <i>markid</i> is an active bookmark.
 * @param col       Column of bookmark.  Specify 0 if <i>markid</i> is an active bookmark.
 * @param BeginLineROffset
 *                  Real offset to beginning of line.  Imaginary line data not counted.  Specify 0 if <i>markid</i> is an active bookmark.
 * @param LineData  Text on the line of the bookmark.  Specify 0 if <i>markid</i> is an active bookmark.
 * @param Filename  Filename the bookmark is in.  Specify 0 if <i>markid</i> is an active bookmark.
 * @param DocumentName
 *                  Document name the bookmark is in.  Specify 0 if <i>markid</i> is an active bookmark.
 *
 * @see _BookmarkAdd
 * @see _BookmarkRemove
 * @see _BookmarkRestore
 * @see _BookmarkGetInfo
 * @see _BookmarkFind
 * @see _BookmarkQCount
 *
 * @categories Bookmark_Functions
 */
void _BookmarkAdd(_str BookmarkName,
                  int markid,
                  int vsbmflags=VSBMFLAG_SHOWNAME|VSBMFLAG_STANDARD,
                  int RealLineNumber=-1,
                  int col=0,
                  long BeginLineROffset=0,
                  _str LineData="",
                  _str Filename="",
                  _str DocumentName=""
                  );

/**
 * Retrieves information for a bookmark.
 *
 * @param i         Bookmark index where 0&lt;=i&lt;_BookmarkQCount().
 * @param BookmarkName
 *                  Set to name of bookmark.
 * @param markid    Set to selection id previous given to _BookmarkAdd.  Specify NULL if you don't need this value.
 * @param vsbmflags Set to combination of VSBMFLAGS_??? ORed together. Specify NULL if you don't need this value.
 * @param buf_id    Set to buffer id of bookmark. Specify NULL if you don't need this value.
 * @param determineLineNumber
 * @param RealLineNumber
 *                  Set to real line number of bookmark. Specify NULL if you don't need this value.
 * @param Col
 * @param BeginLineROffset
 *                  Set to real offset to beginning of line.  Imaginary line data not counted. Specify NULL if you don't need this value.
 * @param LineData  Set to text on the line of the bookmark.
 * @param Filename  Set to filename the bookmark is in.
 * @param DocumentName
 *                  Set to document name the bookmark is in.
 *
 * @return Returns 0 or TEXT_NOT_SELECTED_RC if successful.  TEXT_NOT_SELECTED_RC indicates that
 *         the bookmark is not active.  This occurs when a buffer with bookmarks is closed.
 * @see _BookmarkAdd
 * @see _BookmarkRemove
 * @see _BookmarkRestore
 * @see _BookmarkGetInfo
 * @see _BookmarkFind
 * @see _BookmarkQCount
 *
 * @categories Bookmark_Functions
 *
 */
int _BookmarkGetInfo(int i,
                     _str &BookmarkName=0,
                     int &markid=0,
                     int &vsbmflags=0,
                     int &buf_id=0,
                     int determineLineNumber=1,
                     int &RealLineNumber=0,
                     int &Col=0,
                     long &BeginLineROffset=0,
                     _str &LineData="",
                     _str &Filename="",
                     _str &DocumentName=""
                      );
/**
 * Finds bookmark index.
 *
 * @return Returns index of bookmark 0..vsBookmarkQCount() or -1
 * to indicate the bookmark was not found.
 *
 * @param pszBookmarkName  Name of bookmark to find.
 * <i>vsbmflags</i>  One or more of these flags must be in the
 * bookmark found.
 *
 * @see vsBookmarkAdd
 * @see vsBookmarkRemove
 * @see vsBookmarkRestore
 * @see vsBookmarkGetInfo
 * @see vsBookmarkFind
 * @see vsBookmarkQCount
 *
 * @categories Bookmark_Functions
 *
 */
int _BookmarkFind(_str BookmarkName,int vsbmflags=VSBMFLAG_STANDARD);
/**
 * Finds bookmark index.
 *
 * @param BookmarkName  Name of bookmark to find.
 * @param vsbmflags  One or more of these flags must be in the bookmark found.
 *
 *
 * @return  Returns index of boomark 0.._BookmarkQCount() or -1 to indicate the bookmark was not found.
 *
 * @see _BookmarkAdd
 * @see _BookmarkRemove
 * @see _BookmarkRestore
 * @see _BookmarkGetInfo
 * @see _BookmarkFind
 * @see _BookmarkQCount
 *
 */

/**
 * Counts the number of bookmarks.
 *
 * @return Returns the number of bookmarks.
 * @see _BookmarkAdd
 * @see _BookmarkRemove
 * @see _BookmarkRestore
 * @see _BookmarkGetInfo
 * @see _BookmarkFind
 * @see _BookmarkQCount
 *
 * @categories Bookmark_Functions
 */
int _BookmarkQCount();



/**
 * Returns an index to a color.  Use the _default_color function to set the
 * color attributes.  Color indexes are passed to the _SetTextColor function
 * to set color.  There is a limit of 255 colors so make sure to free the
 * color when you are done.
 *
 * @param fg_color   foreground color (RGB)
 * @param bg_color   background color (RGB)
 * @param font_flags is one of the following font flags:
 *                   <UL>
 *                   <LI>F_BOLD
 *                   <LI>F_ITALIC
 *                   <LI>F_STRIKE_THRU
 *                   <LI>F_UNDERLINE
 *                   <LI>F_INHERIT_STYLE
 *                   </UL>
 * @param parent_color color to inherit attributes from
 *  
 * @example
 * <PRE>
 * int gColorIndex;
 * definit()
 * {
 *      if (arg(1)=='L' && gColorIndex) return;
 *      gColorIndex=_AllocColor(0xffffff,0xFF0000);
 *      //_default_color(gColorIndex,0xffffff,0xFF0000);
 * }
 * defmain()
 * {
 *      // Change the color of 5 bytes of text starting from cursor
 *      _SetTextColor(gColorIndex,5);
 * }
 * </PRE>
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @see _FreeColor
 * @see _SetTextColor
 * @see _GetTextColor
 * @see _default_color 
 * @see _rgb 
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
int _AllocColor(int fg=0x000000, int bg=0xffffff, int fontFlags=0, int parent_color=0);
/**
 * Frees a color index returned by _AllocColor. 
 *  
 * @param ColorIndex index of color in color table
 *
 * @param cfg     color index allocated using _AllocColor()
 *  
 * @appliesTo  Edit_Window, Editor_Control
 * @see _AllocColor
 * @see _SetTextColor
 * @see _GetTextColor
 * @see _default_color
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
void _FreeColor(int cfg);

/**
 * If 'parent_color' is not specified, just return what color index 
 * 'cfg' inherits color or font attributes from.  If 'parent_color' is 
 * given, set the parent for this color to the specified color. 
 *  
 * @param cfg           color index (note you can not set the parent 
 *                      color for default CFG_* color constants,
 *                      however, these all implicitly consider
 *                      CFG_WINDOW_TEXT as their parent color.
 * @param parent_color  color index for 'cfg' to inherit from.
 * 
 * @return Returns the parent color index.  
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
int _InheritColor(int cfg, int parent_color=0);

/**
 * Sets the text color for the number of bytes specified starting from the cursor.
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * @param ColorIndex index of color in color table
 * @param Nofbytes   number of bytes to color code
 * @param replacePreviousColor
 *                   When true, previous color is replaced with new color.  When adding lots of color,
 *                   this slows down adding color.
 *
 * @return
 * @example
 * <PRE>
 * int gColorIndex;
 * definit()
 * {
 *      if (arg(1)=='L' && gColorIndex) return;
 *      gColorIndex=_AlocColor();
 *      _default_color(gColorIndex,0xffffff,0xFF0000);
 * }
 * defmain()
 * {
 *      // Change the color of 5 bytes of text starting from cursor
 *      _SetTextColor(gColorIndex,5);
 * }
 * </PRE>
 *
 * @see _FreeColor
 * @see _AllocColor
 * @see _GetTextColor
 * @see _default_color
 */
int _SetTextColor(int ColorIndex, int Nofbytes,boolean replacePreviousColor=true);


/**
 * Searches for language specific symbols or returns information about the
 * symbol at the cursor.  This function returns 0 if the p_lexer_name
 * property has not be set.
 * </P>
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 * @param clexflags Determines the language elements to search or to test for.
 *                  May be one or more of the following flags, which are defined
 *                  in "slick.sh."  Use the OR operator to specify more than one flag.
 *
 *                  <UL>
 *                  <LI>OTHER_CLEXFLAG
 *                  <LI>KEYWORD_CLEXFLAG
 *                  <LI>NUMBER_CLEXFLAG
 *                  <LI>STRING_CLEXFLAG
 *                  <LI>COMMENT_CLEXFLAG
 *                  <LI>PPKEYWORD_CLEXFLAG
 *                  <LI>LINENUM_CLEXFLAG
 *                  <LI>SYMBOL1_CLEXFLAG
 *                  <LI>SYMBOL2_CLEXFLAG
 *                  <LI>SYMBOL3_CLEXFLAG
 *                  <LI>SYMBOL4_CLEXFLAG
 *                  </UL>
 * @param options   options may be one of the following:
 *                  <DL compact>
 *                  <DT>O<DD>(Default) Find any of the language
 *                  elements specified.  Returns 0 and places cursor on first character of
 *                  symbol if it is found.  Otherwise, STRING_NOT_FOUND_RC is returned.
 *
 *                  <DT>N<DD>Find language elements specified which
 *                  are NOT any of the language elements specified in clexflags.  Returns 0
 *                  and placed cursor on first character of symbol if it is found.  Otherwise,
 *                  STRING_NOT_FOUND_RC is returned.
 *
 *                  <DT>T<DD>Test if symbol under cursor is any of
 *                  the language elements specified in clexflags.  Returns non-zero value if
 *                  cursor is on one of the language elements specified.
 *
 *                  <DT>G<DD>Return the color constant (NOT CLEXFLAG)
 *                  which corresponds to the symbol under the cursor.  The clexflags argument
 *                  is ignored.  Color constants are defined in "slick.sh" and may be one of
 *                  the following:
 *                  <UL>
 *                  <LI>CFG_WINDOW_TEXT
 *                  <LI>CFG_MODIFIED_LINE
 *                  <LI>CFG_INSERTED_LINE
 *                  <LI>CFG_KEYWORD
 *                  <LI>CFG_LINENUM
 *                  <LI>CFG_NUMBER
 *                  <LI>CFG_STRING
 *                  <LI>CFG_COMMENT
 *                  <LI>CFG_PPKEYWORD
 *                  <LI>CFG_SYMBOL1
 *                  <LI>CFG_SYMBOL2
 *                  <LI>CFG_SYMBOL3
 *                  <LI>CFG_SYMBOL4
 *                  </UL>
 *
 *                  <DT>D<DD>Return the detailed color constant (NOT CLEXFLAG)
 *                  which corresponds to the symbol under the cursor.  The clexflags argument
 *                  is ignored.  This option is very similar to the 'G' option above,
 *                  except that it also recognizes the following specialized colors:
 *                  <UL>
 *                  <LI>CFG_LINE_COMMENT
 *                  <LI>CFG_DOCUMENTATION
 *                  <LI>CFG_DOC_KEYWORD
 *                  <LI>CFG_DOC_PUNCTUATION
 *                  <LI>CFG_DOC_ATTRIBUTE
 *                  <LI>CFG_DOC_ATTR_VALUE
 *                  <LI>CFG_IDENTIFIER
 *                  <LI>CFG_FLOATING_NUMBER
 *                  <LI>CFG_HEX_NUMBER
 *                  <LI>CFG_SINGLEQUOTED_STRING
 *                  <LI>CFG_BACKQUOTED_STRING
 *                  <LI>CFG_UNTERMINATED_STRING
 *                  <LI>CFG_INACTIVE_CODE
 *                  <LI>CFG_INACTIVE_KEYWORD
 *                  <LI>CFG_INACTIVE_COMMENT
 *                  <LI>CFG_IMAGINARY_SPACE
 *                  </UL>
 *  
 *                  <DT>E<DD>Searches for embedded source.  Returns 0
 *                  if succesful.  Otherwise, STRING_NOT_FOUND_RC is returned.  The clexflags
 *                  argument is ignored.
 *
 *                  <DT>S<DD>Searches for non-embedded source.
 *                  Returns 0 if succesful.  Otherwise, STRING_NOT_FOUND_RC is returned.  The
 *                  clexflags argument is ignored.
 *  
 *                  <DT>M</DT><DD>Search only within the current selection
 *                  </DL>
 *  
 *                  <P>
 *                  The option parameter may include a '-' (dash) character to enable the 'O'
 *                  and 'N' options to search backwards.
 *                  </P>
 *
 * @return
 * @example
 * <PRE>
 * // Find start of comment or string
 * status=_clex_find(COMMENT_CLEXFLAG|STRING_CLEXFLAG);
 * if (status) {
 *    messageNwait("Not found");
 *    stop();
 * }
 * color=_clex_find(0,"g");
 * if (color==CFG_COMMENT) {
 *    ...
 * }
 * // Assuming already in comment, find non-comment character
 * status=_clex_find(COMMENT_CLEXFLAG,"n");
 * // Assuming already in comment, find non-comment character backwards
 * status=_clex_find(COMMENT_CLEXFLAG,"n-");
 * </PRE>
 *
 * @see _clex_load
 * @see p_color_flags
 * @see _clex_skip_blanks
 */
int _clex_find(int clexflags,_str options="O");



/**
 * Loads color lexer definition file specified.  By convention,
 * these files have the extension ".vlx".  See <b>Color Coding</b>
 * for information on syntax of lexer definitions.
 *
 * @return  Returns 0 if successful.
 *
 * @see _clex_find
 * @see p_color_flags
 * @see _clex_skip_blanks
 *
 * @categories File_Functions
 */
int _clex_load(_str filename);


/**
 * Copies color formatted text selection to the operating system
 * clipboard. 
 *  
 * Note: This function always adds cilpboards. _clipboared_open
 * needs to be called before calling this function and 
 * _clipboard_close should be called after all other clipboards 
 * have been added.
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Clipboard_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 * @param format - currently available clipboard formats
 *    'R' - 'RTF Format' (Windows format)
 *    'H' - 'HTML Format' (Windows format)
 *
 * @param markid Handle to a selection returned by one of the built-ins _alloc_selection or
 *               _duplicate_selection.  A mark_id of '' or no mark_id parameter identifies
 *               the active selection.
 *
 * @return Returns 0 if successful.
 * @see copy_to_clipboard
 * @see _clipboard_close
 * @see _clipboard_open
 */
int _copy_color_coding_to_clipboard(_str format, _str markid="");


/**
 * Gets and optionally sets a column width of a list box.  This function is
 * used to create the column grid look of the dialog editor properties list box.
 * <P>
 * Each line in the list box should separate each column with a tab character. 
 *  
 * Starting in version 17.0, do not use this on the Tree_View, 
 * use _TreeColWidth 
 *
 * @param column     column is a number between 0 and 199.
 * @param width      if specified, sets the width of the column.
 *                   new_width is specified in the  scale mode (p_xyscale_mode)
 *                   of the list box parent.
 *
 * @example
 * <PRE>
 *    defeventtab form1;
 *    list1.on_create()
 *    {
 *         // Assume list box parent scale mode is in twips.  1440 twips make up an inch on the
 *         // display.
 *         // In the future, we will allow the scale mode to be modified.
 *         _col_width(0,1000);
 *         _col_width(1,1000);
 *         _lbadd_item("style\t"p_style);
 *         _lbadd_item("width\t"p_width);
 *         _lbtop();
 *    }
 * </PRE>
 *
 * @return  Returns width of column requested in the list box scale mode (p_scale_mode).
 *
 * @appliesTo  List_Box
 * @categories List_Box_Methods
 */
int _col_width(int column,int width=-3);


/**
 * Inserts a suggestion list of possible correct spellings for word
 * specified after the current line.
 *
 * @param word    If the word argument is not given, the last word
 *                found by one of the functions _spell_check or
 *                _spell_check_area is used.
 *                The cursor is placed on the last suggestion inserted.
 *
 * @appliesTo List_Box
 *
 * @categories List_Box_Methods
 *
 */
int _spell_insert_suglist(_str word="");
/**
 * This function is not available under UNIX.  Inserts a list of
 * valid drives for use by a list box.   Each drive letter is in
 * lower case followed by a colon.
 *
 * @example
 * <PRE>
 *    combo1.on_create()
 *    {
 *         // Combo boxes have 3 separate controls.  Each of which can be accessed with all the
 *         // properties and methods of the stand alone control.  See Combo Box Control.
 *         _insert_drive_list();
 *    }
 * </PRE>
 *
 * @appliesTo Edit_Window, Editor_Control, List_Box
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, File_Functions, List_Box_Methods
 *
 */
void _insert_drive_list();

/**
 * Insert the Slick-C&reg; stack dump into the list
 */
void _StackInsertList(int ignoreNStackItems=0);


/**
 * Sets or clears key bindings in loaded menu and/or menu resource.
 *
 * @param menu_handle Handle of loaded menu returned by p_menu_handle,
 * <b>_menu_load</b>, <b>_menu_find</b>, or <b>_menu_get_state</b>.  Specify 0
 * if you want this parameter to be ignored.
 *
 * @param resource_handle Handle to menu resource returned by
 * <b>find_index</b>, <b>name_match</b>, <b>p_child</b>, <b>p_next</b>, or
 * <b>p_child</b>.  Specify 0 if you want this parameter to be ignored.
 *
 * @param command Name of command to bind
 *
 * @param key_string If option=='B'<i>, key_string</i> is displayed to
 * right of menu items which execute <i>command</i>.  If option=='U', key
 * strings for menu items which display key string to right of menu item are
 * removed.
 *
 * @param option May be one of the following letters:
 *
 * <dl>
 * <dt>'B'</dt><dd><i>key_string</i> is displayed to right of menu items which
 * execute <i>command</i>.</dd>
 * <dt>'U'</dt><dd>Key strings for menu items which display key string to
 * right of menu item are removed.</dd>
 * <dt>'C'</dt><dd>Clear all bindings for <i>menu_handle</i> or
 * <i>resource_handle</i>.</dd>
 * </dl>
 *
 * @return Returns 0 if successful.
 *
 * @see on_init_menu
 * @see _menu_add_filehist
 * @see _menu_add_hist
 * @see _menu_add_workspace_hist
 * @see _menu_delete
 * @see _menu_destroy
 * @see _menu_find
 * @see _menu_get_state
 * @see _menu_info
 * @see _menu_insert
 * @see _menu_load
 * @see _menu_match
 * @see _menu_move
 * @see _menu_set
 * @see _menu_set_state
 * @see _menu_show
 * @see alt_menu
 * @see insert_object
 * @see menu_mdi_bind_all
 * @see mou_show_menu
 * @see show
 *
 * @categories Menu_Functions
 *
 */
//int _menu_bind(int menu_handle, int resource_handle, _str command, _str key_string, _str option);
/**
 * Finds menu or menu item with a specified command or category.
 *
 * @param menu_handle Handle of loaded menu returned by
 * <b>p_menu_handle</b>, <b>_menu_load</b>, <b>_menu_find</b>, or
 * <b>_menu_get_state</b>.
 *
 * @param command_or_category
 * Command or category of menu item to find.  If a command is specified, the
 * command must match exactly.  See <i>option</i> parameter.
 *
 * @param output_menu_handle
 * Handle to loaded menu which contains menu item found.
 *
 * @param output_menu_pos
 * Position of menu item found within <i>output_menu_handle</i>.  0 is the
 * position of the first menu item.  Use the <b>_menu_info</b> function to
 * determine the number of items in a loaded menu.<i></i>
 *
 * @param option
 * May be 'M' or  'C'.  If the 'M' option is given,
 * <i>command_or_category</i> is the command of the menu item to be found.  If
 * the 'C' option is given,  <i>command_or_category</i> is the category of the
 * menu item to be found.  Defaults to 'C' if not specified.
 *
 * @return Returns 0 if successful.
 *
 * @example
 * <pre>
 * #include "slick.sh"
 * defmain()
 * {
 *     // Find the menu item which executes the gui-find command
 *     status=_menu_find(_mdi.p_menu_handle, "new", output_mh,
 * output_mp,'M');
 *     if (status) {
 *         message("Command not found in menu bar");
 *         return(0);
 *     }
 *     _menu_get_state(output_mh, output_mp, mf_flags, 'P', caption,
 *                          command, categories, help_command, help_message);
 *     message("Help message for new command is "help_message);
 * }
 * </pre>
 *
 * @see on_init_menu
 * @see _menu_add_filehist
 * @see _menu_add_hist
 * @see _menu_add_workspace_hist
 * @see _menu_delete
 * @see _menu_destroy
 * @see _menu_get_state
 * @see _menu_info
 * @see _menu_insert
 * @see _menu_load
 * @see _menu_match
 * @see _menu_move
 * @see _menu_set
 * @see _menu_set_state
 * @see _menu_show
 * @see alt_menu
 * @see insert_object
 * @see menu_mdi_bind_all
 * @see mou_show_menu
 * @see show
 *
 * @categories Menu_Functions
 *
 */
int _menu_find(int menu_handle, _str command_or_category, int &output_menu_handle, int &output_menu_pos, _str option='C');
/**
 * Moves menu or menu item from source position to destination position.
 * <i>src_menu_index</i> and <i>dest_menu_index</i> do not have to be the same
 * menu.  <i>src_menu_index</i> and <i>dest_menu_index</i> are returned by
 * <b>find_index</b>, <b>name_match</b>, <b>p_child</b>, <b>p_next</b>, or
 * <b>p_child</b>. This function currently only supports menu resources and not
 * loaded menus.
 *
 * @see on_init_menu
 * @see _menu_add_filehist
 * @see _menu_add_hist
 * @see _menu_add_workspace_hist
 * @see _menu_delete
 * @see _menu_destroy
 * @see _menu_find
 * @see _menu_get_state
 * @see _menu_info
 * @see _menu_insert
 * @see _menu_load
 * @see _menu_match
 * @see _menu_set
 * @see _menu_set_state
 * @see _menu_show
 * @see alt_menu
 * @see insert_object
 * @see menu_mdi_bind_all
 * @see mou_show_menu
 * @see show
 *
 * @categories Menu_Functions
 *
 */
int _menu_move(int src_menu_index, int src_menu_pos, int dest_menu_index, int dest_menu_pos);
/**
 * Moves menu or menu item from source position to destination position.
 * <i>src_menu_index</i> and <i>dest_menu_index</i> do not have to be the same
 * menu.  <i>src_menu_index</i> and <i>dest_menu_index</i> are returned by
 * <b>find_index</b>, <b>name_match</b>, <b>p_child</b>, <b>p_next</b>, or
 * <b>p_child</b>. This function currently only supports menu resources and not
 * loaded menus.
 *
 * @see on_init_menu
 * @see _menu_add_filehist
 * @see _menu_add_hist
 * @see _menu_add_workspace_hist
 * @see _menu_delete
 * @see _menu_destroy
 * @see _menu_find
 * @see _menu_get_state
 * @see _menu_info
 * @see _menu_insert
 * @see _menu_load
 * @see _menu_match
 * @see _menu_set
 * @see _menu_set_state
 * @see _menu_show
 * @see alt_menu
 * @see insert_object
 * @see menu_mdi_bind_all
 * @see mou_show_menu
 * @see show
 *
 * @categories Menu_Functions
 *
 */

/**
 * Deletes a menu or menu item in a loaded menu or a menu resource.
 *
 * @param menu_handle Handle of loaded menu returned by
 * <b>p_menu_handle</b>, <b>_menu_load</b>, <b>_menu_find</b>, or
 * <b>_menu_get_state</b>.  This handle may also be a handle to menu resource
 * returned by <b>find_index</b> or <b>name_match</b>.<i></i>
 * menu_pos Position within menu <i>menu_handle</i>.  The first menu item
 * position is 0.
 *
 * @example
 * <pre>
 * #include "slick.sh"
 * defmain()
 * {
 *      status=_menu_find(_mdi.p_menu_handle,"M","help -using",mh,mpos);
 *      if (!status) _menu_delete(mh,mpos);
 * }
 * </pre>
 *
 * @return Returns 0 if successful.
 *
 * @see on_init_menu
 * @see _menu_add_filehist
 * @see _menu_add_hist
 * @see _menu_add_workspace_hist
 * @see _menu_destroy
 * @see _menu_find
 * @see _menu_get_state
 * @see _menu_info
 * @see _menu_load
 * @see _menu_match
 * @see _menu_move
 * @see _menu_set
 * @see _menu_set_state
 * @see _menu_show
 * @see alt_menu
 * @see insert_object
 * @see menu_mdi_bind_all
 * @see mou_show_menu
 * @see show
 *
 * @categories Menu_Functions
 *
 */
int _menu_delete(int menu_handle, int menu_pos);
/**
 * Inserts a menu or menu item into a loaded menu or a menu resource.
 *
 * @param menu_handle   Handle of loaded menu returned by
 * <b>p_menu_handle</b>, <b>_menu_load</b>, <b>_menu_find</b>, or
 * <b>_menu_get_state</b>.  This handle may also be a handle to menu resource
 * returned by <b>find_index</b> or <b>name_match</b>.<i></i>
 * menu_pos Position within menu <i>menu_handle</i>.  Menu item is inserted
 * before position.  The first menu item position is 0.  Specify -1 or a
 * position greater than the last menu item to insert after the last menu item.
 *
 * @param mf_flags <i>mf_flags</i> may be zero or more of the following
 * flags defined in "slick.sh":
 *
 * <ul>
 * <li>MF_CHECKED</li>
 * <li>MF_UNCHECKED</li>
 * <li>MF_GRAYED</li>
 * <li>MF_ENABLED</li>
 * <li>MF_SUBMENU</li>
 * </ul>
 *
 * @param caption  Menu item title.
 *
 * @param command The command to be executed when the menu item is selected.
 * This parameter is ignored if <i>mf_flags</i> contain the MF_SUBMENU flag.
 *
 * @param categories Menu item categories.  May be one or more categories
 * separated with a '|' character.  See <b>_menu_set_state</b> function for more
 * information about categories.
 *
 * @param help_command  Menu item help command.  Executed when F1 pressed on
 * menu item.
 *
 * @param help_message  Menu item help message.  Displayed when cursor is on
 * menu item.
 *
 * @example
 * <pre>
 * #include "slick.sh"
 * defmain()
 * {
 *      // Insert 2 items into a menu resource called menu1
 *      index=find_index("menu1",oi2type(OI_MENU));
 *      if (!index) {  // IF menu1 does not already exist?
 *          // Create new menu resource in names table
 *          index=insert_name("menu1",oi2type(OI_MENU));
 *          if (index&lt;=0) {
 *              message("unable to create menu1");
 *              return("");
 *          }
 *      }
 *      // Insert File menu
 *      _menu_insert(index, 0,MF_ENABLED|MF_SUBMENU,"&File",
 *                                "","","help file menu","");
 *      // Insert New menu item within File menu
 *      _menu_insert(index.p_child,0,MF_ENABLED,"&New","New","",
 *                              "help file menu", "");
 *      // Load and display the menu as a pop-up menu
 *      show('menu1');
 * }
 * </pre>
 *
 * @return Returns 0 if successful.
 *
 * @see on_init_menu
 * @see _menu_add_filehist
 * @see _menu_add_hist
 * @see _menu_add_workspace_hist
 * @see _menu_delete
 * @see _menu_destroy
 * @see _menu_find
 * @see _menu_get_state
 * @see _menu_info
 * @see _menu_load
 * @see _menu_match
 * @see _menu_move
 * @see _menu_set
 * @see _menu_set_state
 * @see _menu_show
 * @see alt_menu
 * @see insert_object
 * @see menu_mdi_bind_all
 * @see mou_show_menu
 * @see show
 *
 * @categories Menu_Functions
 *
 */
int _menu_insert(int menu_handle, int menu_pos, int mf_flags,
                 _str caption,_str  command="",_str categories="",
                 _str help_command="",_str help_message="");

/**
 * Destroy menu loaded by the <b>_menu_load</b> function.  This function is
 * typically used to destroy the old menu bar when replacing a menu bar or to
 * destroy a pop-up menu after it has been displayed.  <i>menu_handle</i> is
 * typically returned by <b>p_menu_handle</b> or <b>_menu_load</b>.
 *
 * @return Returns 0 if successful.
 *
 * @see on_init_menu
 * @see _menu_add_filehist
 * @see _menu_add_hist
 * @see _menu_add_workspace_hist
 * @see _menu_delete
 * @see _menu_find
 * @see _menu_get_state
 * @see _menu_info
 * @see _menu_insert
 * @see _menu_load
 * @see _menu_match
 * @see _menu_move
 * @see _menu_set
 * @see _menu_set_state
 * @see _menu_show
 * @see alt_menu
 * @see insert_object
 * @see menu_mdi_bind_all
 * @see mou_show_menu
 * @see show
 *
 * @categories Completion_Functions, Menu_Functions
 *
 */
int _menu_destroy(int menu_handle);

/**
 * @return Returns number of menu items in loaded menu <i>menu_handle</i>.
 * <i>menu_handle</i> is returned by <b>p_menu_handle</b>, <b>_menu_load</b>,
 * <b>_menu_find</b>, or <b>_menu_get_state</b>.
 *
 * @see on_init_menu
 * @see _menu_add_filehist
 * @see _menu_add_hist
 * @see _menu_add_workspace_hist
 * @see _menu_delete
 * @see _menu_destroy
 * @see _menu_find
 * @see _menu_get_state
 * @see _menu_insert
 * @see _menu_load
 * @see _menu_match
 * @see _menu_move
 * @see _menu_set
 * @see _menu_set_state
 * @see _menu_show
 * @see alt_menu
 * @see insert_object
 * @see menu_mdi_bind_all
 * @see mou_show_menu
 * @see show
 *
 * @categories Menu_Functions
 *
 */
int _menu_info(int menu_handle,_str option="C");
/**
 * Sets menu item values for the menu items which contain the command or category specified.
 *
 * @param menu_handle            Handle of loaded menu returned by p_menu_handle, _menu_load, _menu_find, or _menu_get_state.
 * @param command_or_category    Command/category to look for or position of menu item within menu_handle.  If a command is specified, the command must match exactly.  See option parameter.
 * @param mf_flags               mf_flags may be zero or more of the following flags defined in "slick.sh":<pre>
 *       MF_CHECKED
 *       MF_UNCHECKED
 *       MF_GRAYED
 *       MF_ENABLED</pre>
 * @param option                 May be 'M', 'C', 'P'.  If the 'M' option is given, command_or_category is the command of the menu item to be found. If the 'C' option is given,  command_or_category is the category of the menu item to be found.  If the 'P' option is given, command_or_category is the position (0.._menu_info(menu_handle)-1) of the menu item with in menu_handle.  Defaults to 'C'.
 * @param item_text              Menu item text.
 * @param command                Menu item command to be executed.
 * @param category               Menu item category.  Another way to search for a menu item.
 * @param help_command           Menu item help command.  Executed when F1 pressed on menu item.
 * @param help_message           Menu item help message.  Display when cursor on menu item.
 *
 * @return Returns 0 if successful.
 *
 * @example
 * <pre>
 *    #include "slick.sh"
 *    // Create a form called form1 and set the border style to anything BUT
 *    // BDS_DIALOG BOX.  Windows does not allow forms with a dialog
 *    // box style border to have menu bars.
 *    defeventtab form1;
 *    form1.on_load()
 *    {
 *       // Find index of SlickEdit MDI menu resource
 *       index=find_index(def_mdi_menu,oi2type(OI_MENU));
 *       // Load this menu resource
 *       menu_handle=p_active_form._menu_load(index);
 *       // _set_menu will fail if the form has a dialog box style border.
 *
 *       // Put a menu bar on this form.
 *       _menu_set(menu_handle);
 *
 *       // You DO NOT need to call _menu_destroy.  This menu is destroyed when the form
 *       // window is deleted.
 *       // Gray out all menu items which are not allowed when there no child windows.
 *       _menu_set_state(menu_handle,"new",MF_GRAYED,'M');
 *    }
 * </pre>
 *
 * @see on_init_menu
 * @see _menu_add_filehist
 * @see _menu_add_hist
 * @see _menu_add_workspace_hist
 * @see _menu_delete
 * @see _menu_destroy
 * @see _menu_find
 * @see _menu_get_state
 * @see _menu_info
 * @see _menu_insert
 * @see _menu_load
 * @see _menu_match
 * @see _menu_move
 * @see _menu_set
 * @see _menu_show
 * @see alt_menu
 * @see insert_object
 * @see menu_mdi_bind_all
 * @see mou_show_menu
 * @see show
 *
 * @categories Menu_Functions
 *
 */
int _menu_set_state(int menu_handle,_str command_or_category,
                    int mf_flags, _str option='C',_str item_text="",
                    _str command="",_str category="",_str help_command="",
                    _str help_message="");
/**
 * Gets menu item values for the menu items which contain the command or
 * category specified.
 *
 * @param menu_handle Handle of loaded menu returned by
 * <b>p_menu_handle</b>, <b>_menu_load</b>, <b>_menu_find</b>, or
 * <b>_menu_get_state</b>.
 *
 * @param command_or_category
 * Command, category, or position within <i>menu_handle</i> of menu item.  If
 * a command is specified, the command must match exactly.  See <i>option</i>
 * parameter.
 *
 * @param option May be 'M', 'C', 'P'.  If the 'M' option is given,
 * <i>command_or_category</i> is the command of the menu item to be found. If
 * the 'C' option is given,  <i>command_or_category</i> is the category of the
 * menu item to be found.  If the 'P' option is given,
 * <i>command_or_category</i> is the position
 * (0..<b>_menu_info</b>(<i>menu_handle</i>)-1) of the menu item with in
 * <i>menu_handle</i>.  Defaults to 'C'.
 *
 * @param mf_flags <i>mf_flags</i> may be zero or more of the following
 * flags defined in "slick.sh":
 *
 * <ul>
 * <li>MF_CHECKED</li>
 * <li>MF_UNCHECKED</li>
 * <li>MF_GRAYED</li>
 * <li>MF_ENABLED</li>
 * <li>MF_SUBMENU</li>
 * </ul>
 *
 * @param caption Menu item title.
 *
 * @param command For sub-menu, <i>command</i> is a menu handle which may be
 * used in calls to <b>_menu_get_state</b> or <b>_menu_info</b>.  Otherwise,
 * this is the command to be executed when the menu item is selected.
 *
 * @param categories Menu item categories.  May be one or more categories
 * separated with a '|' character.  See <b>_menu_set_state</b> function for more
 * information about categories.
 *
 * @param help_command  Menu item help command.  Executed when F1 pressed on
 * menu item.
 *
 * @param help_message  Menu item help message.  Displayed when cursor is on
 * menu item.
 *
 * @example
 * <pre>
 * // This code traverses a menu that has been loaded with _menu_load
 * #include "slick.sh"
 * defmain()
 * {
 *      traverse_menu(_mdi.p_menu_handle);
 * }
 * static void traverse_menu(menu_handle)
 * {
 *     Nofitems=_menu_info(menu_handle,'c');
 *     for (i=0;i&lt;Nofitems;++i) {
 *          _menu_get_state(menu_handle,i,mf_flags,'p',caption,command,
 *                       categories,help_command,help_message);
 *          messageNwait("p_caption="caption)
 *          if (mf_flags & MF_SUBMENU) {
 *              traverse_menu(command);
 *          }
 *     }
 * }
 * </pre>
 *
 * @return Returns 0 if successful.
 *
 * @see on_init_menu
 * @see _menu_add_filehist
 * @see _menu_add_hist
 * @see _menu_add_workspace_hist
 * @see _menu_delete
 * @see _menu_destroy
 * @see _menu_find
 * @see _menu_info
 * @see _menu_insert
 * @see _menu_load
 * @see _menu_match
 * @see _menu_move
 * @see _menu_set
 * @see _menu_set_state
 * @see _menu_show
 * @see alt_menu
 * @see insert_object
 * @see menu_mdi_bind_all
 * @see mou_show_menu
 * @see show
 *
 * @categories Menu_Functions
 *
 */
int _menu_get_state(int menu_handle, _str command_or_category,int &mf_flags,_str option='C',
                    _str &caption="",_str &command="",
                    _str &categories="",_str &help_command="",
                    _str &help_message="");

/**
 * This function is identical to the _menu_set_state function and is
 * present only for backward compatibility with SlickEdit Version
 * 1.0x.
 *
 * @categories Menu_Functions
 *
 */
int _set_menu_state(int menu_handle ,_str command_or_category,
                    int mf_flags, _str option="C",
                    _str item_text="",_str command="",
                    _str category="",_str help_command="",
                    _str help_message="");
/**
 * This function is identical to the <b>_menu_get_state</b> function and is
 * present only for backward compatibility with SlickEdit Version 1.0x.
 *
 * @categories Menu_Functions
 *
 */
int _get_menu_state(int menu_handle, _str command_or_category,int &mf_flags,_str option="C",_str &item_text="", _str &command="",_str &category="", _str &help_command="", _str &help_message="");
/**
 * Displays/runs menu as pop-up.  All menu items should be grayed/checked
 * before calling this function.  This function does not return until the menu
 * is closed.
 *
 * @param menu_handle Handle of loaded menu returned by
 * <b>p_menu_handle</b>, <b>_menu_load</b>, <b>_menu_find</b>, or
 * <b>_menu_get_state</b>.
 *
 * @param vpm_flags Defaults to VPM_LEFTBUTTON|VPM_LEFTALIGN.  <i>vpm_flags</i>
 * may be zero or more of the following flags defined in "slick.sh":
 *
 * <dl>
 * <dt>VPM_LEFTBUTTON</dt><dd>Track menu items with left mouse button.</dd>
 * <dt>VPM_RIGHTBUTTON</dt><dd>Track menu items with right mouse button.</dd>
 * <dt>VPM_LEFTALIGN</dt><dd><i>x</i> coordinate represents left most corner of menu.</dd>
 * <dt>VPM_CENTERALIGN</dt><dd><i>x</i> coordinate represents horizontal center of menu.</dd>
 * <dt>VPM_RIGHTALIGN</dt><dd><i>x</i> coordinate represents right side of menu.</dd>
 * </dl>
 *
 * @param x x coordinate of left side of menu.  Defaults to 0 if not given.
 *
 * @param y y coordinate of top of menu.  Defaults to 0 if not given.
 *
 * @example
 * <pre>
 * #include "slick.sh"
 * defmain()
 * {
 *    // Low-level code to display SlickEdit menu bar as pop-up.
 *    // Could just use show or mou_show_menu function.
 *    index=find_index("_mdi_menu",oi2type(OI_MENU))
 *    if (!index) {
 *        message("Can't find _mdi_menu");
 *    }
 *    menu_handle=_menu_load(index,'P');
 *    // Display this menu in the menu of the screen.
 *    x=_screen_width()/2;y=_screen_height()/2;
 *    flags=VPM_CENTERALIGN|VPM_LEFTBUTTON;
 *    _menu_show(menu_handle,flags,x,y)
 *    _menu_destroy(menu_handle);
 * }
 * </pre>
 *
 * @return Returns 0 if successful.
 *
 * @see on_init_menu
 * @see _menu_add_filehist
 * @see _menu_add_hist
 * @see _menu_add_workspace_hist
 * @see _menu_delete
 * @see _menu_destroy
 * @see _menu_find
 * @see _menu_get_state
 * @see _menu_info
 * @see _menu_insert
 * @see _menu_load
 * @see _menu_match
 * @see _menu_move
 * @see _menu_set
 * @see _menu_set_state
 * @see alt_menu
 * @see insert_object
 * @see menu_mdi_bind_all
 * @see mou_show_menu
 * @see show
 *
 * @categories Menu_Functions
 *
 */
int _menu_show(int menu_handle, int vpm_flags=VPM_LEFTBUTTON|VPM_LEFTALIGN,
               int x=0, int y=0);


void _QtPrintPreviewDialog(_str reserved="", int editorctl_wid=0,
           void (*pfnCallback)(int reason,_str caption="")=0,
           _str font="",
           _str lheader="", _str lfooter="",
           _str options="",
           _str cheader="",_str cfooter="",
           _str rheader="",_str rfooter="");


/**
 * <p>This function is only supported by the UNIX version.  Prints the
 * contents of the current buffer according to the options given.</p>
 *
 * <p>It is much easier to create input parameters to this function by using
 * macro recording.  Use the <b>Text Mode Print dialog box</b> to set
 * your options.  Then print a document while macro recording is on.</p>
 *
 * @return Returns 0 if successful.
 *
 * @param output_window_id specifies the window/buffer to get the
 * formatted text.  Usually the <b>_create_temp_view</b> function is
 * used to create an empty window/buffer.
 *
 * @param filename is inserted into the header and footer parameters
 * wherever a %f occurs.  Usually this is the buffer name.
 *
 * <p><i>cheader</i>, <i>cfooter</i>, <i>lheader</i>, <i>lfooter</i>,
 * <i>rheader</i>, and <i>rfooter</i> are strings which may have escape
 * sequences with the following meaning embedded into them:</p>
 *
 * <dl>
 * <dt>%f</dt><dd>Buffer name</dd>
 * <dt>%p</dt><dd>Page number</dd>
 * <dt>%d</dt><dd>Date</dd>
 * </dl>
 *
 * <p>The letters 'c', 'l', and 'r' correspond to the header or footer at the center,
 * left, and right of the page.</p>
 *
 * <p>The header is printer at the top of each page.  The footer is printed at
 * the bottom of each page.</p>
 *
 * @param options is a string in the format:<br>
 *
 * <i>flags</i>, <i>bl_after_header</i>, <i>bl_before_footer</i>,
 * <i>lines_per_page</i>,  <i>cols_per_line</i>,
 * <i>linenums_every</i>,
 *
 * @param flags are reserved and should be 0.
 *
 * @param bl_after_header indicates the number of blank lines between
 * the header line and the text on the page.  This value is ignored if all
 * header parameters are blank.
 *
 * @param bl_before_footer indicates the number of blank lines between
 * the last line of text printed on the page and the footer line.
 *
 * @param lines_per_page indicates the maximum number of lines that
 * can be printed.  This includes header, footer, and blank lines.
 *
 * @param cols_per_line indicates the maximum number of columns that
 * can be printed on a line.
 *
 * @param linenums_every when non-zero, lines at intervals of this value
 * are printed with line numbers.
 *
 * @appliesTo Edit_Window
 *
 * @categories Buffer_Functions, Edit_Window_Methods
 *
 */
void _tprint_format(int output_view_id,_str filename="",_str options="",
                           _str print_cheader="",_str print_cfooter="",
                           _str print_lheader="",_str print_lfooter="",
                           _str print_rheader="",_str print_rfooter="");

/**
 * <p>Prints the contents of the current buffer according to the options given.
 * This function is not supported by the UNIX version.</p>
 *
 * <p>It is much easier to create input parameters to this function by using
 * macro recording.  Use the <b>Print Setup dialog box</b> to set your
 * options.  Then print a document while macro recording is on.
 *
 * @return Returns 0 if successful.
 *
 * @param sysmessage is a description given to the operating system
 * which identifies this particular print job.  Usually this is the buffer
 * name.
 *
 * @param reserved should be '' to avoid compatibility problems.
 *
 * @param callback_index is a pointer to a function or a names table
 * index to a global function which is called with PRINT_ONINIT to
 * initialize, and PRINT_ONEXIT to uninitialize.  The callback function
 * can cancel printing by calling the <b>_print_cancel</b> function.
 *
 * @param font is a string in the format:
 * <i>font_name, font_size, font_flags</i>[,]
 *
 * @param font_flags is a combination of the flags below:
 * <ul>
 * <li>F_BOLD</li>
 * <li>F_ITALIC</li>
 * <li>F_STRIKE_THRU</li>
 * <li>F_UNDERLINE</li>
 * <li>F_PRINTER</li>
 * </ul>
 *
 * @param lheader, <i>lfooter</i>, <i>cheader</i>, <i>cfooter</i>,
 * <i>rheader</i>, and <i>rfooter</i> are strings which may have escape
 * sequences with the following meaning embedded into them:
 * <dl>
 * <dt>%f</dt><dd>Buffer name</dd>
 * <dt>%p</dt><dd>Page number</dd>
 * <dt>%d</dt><dd>Date</dd>
 * </dl>
 *
 * <p>The letters 'l', 'c', and 'r' correspond to the header or footer at the left,
 * center, and right of the page.</p>
 *
 * <p>The header is printed at the top of each page.  The footer is printed at
 * the bottom of each page.</p>
 *
 * @param options is a string in the format:
 *
 * <i>left_ma, AfterHeader_ma, right_ma, BeforeFooter_ma,
 * space_between_ma, print_flags, linenums_every ,top_ma,
 * bottom_ma</i>
 *
 * <p><b>Windows:</b> The <i>left_ma</i>, <i>top_ma</i>,
 * <i>right_ma</i>, and <i>bottom_ma</i> parameters are margin space
 * from the outside edge of the paper to the printed text.
 * <i>AfterHeader_ma </i>is the space in inches between the header and
 * the first line on the page.  <i>BeforeFooter_ma</i> is the space in
 * inches between the last line on a page and the footer.</p>
 *
 * <p><i>space_between_ma</i> is the spacing in twips between columns.
 * This parameter is only used if the <i>print_flags</i> have the
 * PRINT_TWO_UP flag.</p>
 *
 * <p><i>print_flags</i> is a combination of the flags below:</p>
 * <ul>
 * <li>PRINT_LEFT_HEADER</li>
 * <li>PRINT_RIGHT_HEADER</li>
 * <li>PRINT_CENTER_HEADER</li>
 * <li>PRINT_LEFT_FOOTER</li>
 * <li>PRINT_RIGHT_FOOTER</li>
 * <li>PRINT_CENTER_FOOTER</li>
 * <li>PRINT_TWO_UP</li>
 * </ul>
 *
 * <p>The PRINT_LEFT_HEADER, PRINT_RIGHT_HEADER, and
 * PRINT_CENTER_HEADER flags have no effect if the
 * <i>cheader</i>, <i>cfooter</i>, <i>rheader</i>, and <i>rfooter</i>
 * parameters are given.</p>
 *
 * @appliesTo Edit_Window
 *
 * @categories Buffer_Functions, Edit_Window_Methods
 *
 */
int _print(_str sysmessage="", _str reserved="",
           void (*pfnCallback)(int reason,_str caption="")=0,
           _str font="",
           _str lheader="", _str lfooter="",
           _str options="",
           _str cheader="",_str cfooter="",
           _str rheader="",_str rfooter="");




/**
 * @return Returns tree item index corresponding to LineNumber given.
 *
 * @param LineNumber Specifies the line number of a tree node as if
 * the tree we are list box.
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
int _TreeGetIndexFromLineNumber(int LineNumber);

/**
 * Adds a new sibling or child item.
 *
 * @return Returns the item index of the new item.
 *
 * @param ItemIndex Specifies a tree item.  The root of the tree
 * can't be deleted and always has an item index of 0.
 *
 * @param caption caption to be used for new tree node.
 *
 * @param flags   One or more of the following flags ORed together.
 *
 * <dl>
 * <dt>TREE_ADD_BEFORE</dt><dd>Add this item before the item
 * specified.</dd>
 * <dt>TREE_ADD_AS_CHILD</dt><dd>Add this item after last child of
 * the item specified by
 * <i>ItemIndex</i>.</dd>
 * <dt>TREE_ADD_SORTED_CS</dt><dd>
 *    Add this item sorted case
 * sensitive.</dd>
 * <dt>TREE_ADD_SORTED_CI</dt><dd>
 *    Add this item sorted case
 * insensitive.</dd>
 * <dt>TREE_ADD_SORTED_FILENAME</dt><dd>
 *    Add this item sorted by
 * filename.</dd>
 * </dl>
 *
 * @param NonCurrentBMIndex
 *    Names table index to a picture which gets displayed to
 * the left of the caption text when this node is not the
 * current node.  We recommend you specify the same
 * values for <i>NonCurrentBMIndex </i>and
 * <i>CurrentBMIndex </i>for leaf items.
 *
 * @param CurrentBMIndex
 *    Names table index to a picture which gets displayed to
 * the left of the caption text when this node is the current
 * node.
 *
 * @param ShowChildren
 * Indicates whether to show the children of this node. 
 * TREE_NODE_COLLAPSED specifies not to show the children. Specify 
 * TREE_NODE_EXPANDED to initially show children of this node. 
 * Set this to TREE_NODE_LEAF for leaf items. 
 *
 * @param moreFlags Combination of TREENODE_* flags.
 * 
 * @param userInfo
 * Allows you to specify per-node user data.
 * See {@link _TreeSetUserInfo}.
 *
 * @example
 * <pre>
 * #include "slick.sh"
 *
 * defeventtab form1;
 * void tree1.on_create()
 * {
 *    flag=TREE_ADD_AS_CHILD;
 *
 *
 * container1=prev=_TreeAddItem(0,"Container1",TREE_ADD_AS
 * _CHILD, _pic_fldclos, _pic_fldaop,0);
 *    for (i=0;i<3;++i) {
 *       _TreeAddItem(container1,"item "i,TREE_ADD_AS_CHILD,
 * _pic_file, _pic_file,-1);
 *    }
 *    container2=_TreeAddItem(container1,"Container2",0,
 * _pic_fldclos, _pic_fldaop,0);
 *    for (i=0;i<3;++i) {
 *       _TreeAddItem(container2,"item "i,TREE_ADD_AS_CHILD,
 * _pic_file,_pic_file,-1);
 *    }
 * }
 * </pre>
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
int _TreeAddItem(int ItemIndex, _str caption,
                             int flags=0, int NonCurrentBMIndex=0,
                             int CurrentBMIndex=0, int ShowChildren=TREE_NODE_EXPANDED,
                             int moreFlags=0, typeless userInfo=0);
/**
 * Force a tree redraw.
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 */
void _TreeRefresh();

/**
 * @return This method is for moving the cursor down through the displayed tree.
 * Retuns 0 if successful.  Otherwise BOTTOM_OF_FILE_RC is
 * returned.
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
int _TreeDown();

/**
 * @return This method is for moving the cursor up through the displayed tree.
 * Retuns 0 if successful.  Otherwise TOP_OF_FILE_RC is returned.
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
int _TreeUp();

/**
 * This method moves the cursor to the first line of the displayed tree.
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
void _TreeTop();

/**
 * This method moves the cursor to the last line of the displayed tree.
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
void _TreeBottom();

/**
 * @return Returns the current tree item index of the displayed tree.
 *
 * @see _TreeSetCurIndex
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
int _TreeCurIndex();
/**
 * Sets the user info value for the specified tree item.
 *
 * @see _TreeSetCaption
 * @see _TreeGetCaption
 * @see _TreeSetInfo
 * @see _TreeGetInfo
 * @see _TreeGetUserInfo
 * @see _TreeAddItem
 * 
 * @appliesTo Tree_View
 * @categories Tree_View_Methods
 *
 */
void _TreeSetUserInfo(int ItemIndex, typeless info);
/**
 * @return Returns the user info value set by the <b>_TreeSetUserInfo</b>
 * method for the specified tree item.
 *
 * @see _TreeSetCaption
 * @see _TreeGetCaption
 * @see _TreeSetInfo
 * @see _TreeGetInfo
 * @see _TreeSetUserInfo
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
typeless _TreeGetUserInfo(int ItemIndex);
/**
 * Modifies some tree item properties.
 *
 * @param ItemIndex           Specifies a tree item.  The root of the tree can't
 *                            be deleted and always has an item index of 0.
 * @param ShowChildren        Indicates whether to show the children of this node.
 *                            TREE_NODE_COLLAPSED specifies not to show the
 *                            children. Specify TREE_NODE_EXPANDED to initially
 *                            show children of this node. Set this to
 *                            TREE_NODE_LEAF for leaf items.
 * @param NonCurrentBMIndex   Names table index to a picture which gets displayed
 *                            to the left of the caption text when this node is not
 *                            the current node.  We recommend you specify the same
 *                            values for NonCurrentBMIndex and CurrentBMIndex
 *                            for leaf items.
 * @param CurrentBMIndex      Names table index to a picture which gets displayed
 *                            to the left of the caption text when this node is the current node.
 * @param moreFlags           Combination of TREENODE_* flags.
 * @param setCurrentNodeIfHidden Set this to 0 for performance
 *                               if you are hiding a lot of
 *                               nodes and will set the current
 *                               node yourself when finished.
 * @param flagMask   Mask indicating which TREENODE_* flags to set
 *
 * @see _TreeSetCaption
 * @see _TreeGetCaption
 * @see _TreeGetInfo
 * @see _TreeSetUserInfo
 * @see _TreeGetUserInfo
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
void _TreeSetInfo(int ItemIndex, int ShowChildren,
                  int NonCurrentBMIndex=-1, int CurrentBMIndex=-1,
                  int moreFlags=0,int setCurrentNodeIfHidden=1,
                  int flagMask=-1);
/**
 * Retrieves some tree item properties.
 *
 * @param ItemIndex  Specifies a tree item.  The root of the tree
 * cannot be deleted and always has an item index of 0.
 *
 * @param ShowChildren
 * Indicates whether children of this node are displayed. 
 * TREE_NODE_COLLAPSED indicates children are not displayed. 
 * TREE_NODE_EXPANDED indicates children of this node are 
 * displayed. TREE_NODE_LEAF for leaf items. 
 *
 * @param NonCurrentBMIndex
 *    Names table index to a picture which gets displayed to
 * the left of the caption text when this node is not the
 * current node.
 *
 * @param CurrentBMIndex
 *    Names table index to a picture which gets displayed to
 * the left of the caption text when this node is the current
 * node.
 *
 * @param moreFlags
 * Indicates whether this item is hidden
 * (TREENODE_HIDDEN).
 *
 * @param lineNumber
 *    Set to the line number of the current node in the tree as
 * if the tree we are list box.  This has an impact on 
 * performance, so do mnot specify this parameter if you are 
 * not actually using it. 
 *  
 * @param flagMask   Mask indicating which TREENODE_* flags to get
 *
 * @see _TreeSetCaption
 * @see _TreeGetCaption
 * @see _TreeSetInfo
 * @see _TreeSetUserInfo
 * @see _TreeGetUserInfo
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
void _TreeGetInfo(int ItemIndex, int &ShowChildren,
                  int &NonCurrentBMIndex=0, int &CurrentBMIndex=0,
                  int &moreFlags=0,int &lineNumber,int flagMask=-1);
/**
 * @return Returns tree item index under the mouse coordinates specified.
 *
 * @param mouX       X coordinate.
 * @param mouY       Y coordinate.
 * @param option     all values for <B>option</B> are deprecated
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
int _TreeGetIndexFromPoint(int mou_x,int mou_y,_str option="S");

/**
 * @return Returns information about the selected items in the tree.
 * Only use this function if p_multi_select is set to MS_SIMPLE_LIST.
 *
 * @param NofSelected         (Output only) Set to number of selected items in the tree.
 * @param firstSelectedItem   (Ouput only) Set to the tree item that started the selection.
 * @param endSelectedItem     (Ouput only) Set to the tree item that ends the selection.
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 * @deprecated Use {@link _TreeGetNumSelectedItems} or
 *            {@link _TreeGetNextSelectedIndex}
 */
void _TreeGetSelInfo(int &NofSelected,int &startSelectedItem=0,int &endSelectedItem=0);

/**
 * Sets all node flags in the tree.
 * Use this function only if p_multi_select is set to MS_SIMPLE_LIST.
 *
 * @param flags         New flags to set.
 * @param mask          Indicates which flags will be effected.
 *
 * @example
 * <PRE>
 *  // Select all the items in the tree
 *  tree1._TreeSetAllFlags(TREENODE_SELECTED);
 *  // Deselect all the items in the tree
 *  tree1._TreeSetAllFlags(0,TREENODE_SELECTED);
 * </PRE>
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
void _TreeSetAllFlags(int flags,int Mask=flags);

/**
 * Sets the caption for the specified tree item.
 *
 * @param ItemIndex     Specifies a tree item.
 * @param caption       Caption to set tree item to
 * @param ColIndex      Column index to set. First column is 0.
 *                      The default is to set all columns,
 *                      separated by tabs.
 *
 * @see _TreeGetCaption
 * @see _TreeSetInfo
 * @see _TreeGetInfo
 * @see _TreeSetUserInfo
 * @see _TreeGetUserInfo
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
void _TreeSetCaption(int ItemIndex, _str caption, int ColIndex=-1);

/**
 * Returns the caption for the specified tree item.
 *
 * @param ItemIndex     Specifies a tree item. 
 * @param ColIndex      Column index to get. First column is 0.
 *                      The default is to get all columns,
 *                      separated by tabs.
 *
 * @see _TreeSetCaption
 * @see _TreeSetInfo
 * @see _TreeGetInfo
 * @see _TreeSetUserInfo
 * @see _TreeGetUserInfo
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
_str _TreeGetCaption(int ItemIndex, int ColIndex=-1);

/**
 * @return Returns the tree item index of the first child of the node specified by
 * <i>ItemIndex</i>.  -1 is returned if the node specified has no children.
 *
 * @see _TreeGetNextSiblingIndex
 * @see _TreeGetPrevSiblingIndex
 * @see _TreeGetParentIndex
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
int _TreeGetFirstChildIndex(int ItemIndex);

/**
 * @return Returns the tree item index of the previous sibling of the node
 * specified by <i>ItemIndex</i>.  -1 is returned if the node specified has
 * no previous sibling.
 *
 * @param ItemIndex     Specifies a tree item.
 *
 * @see _TreeGetParentIndex
 * @see _TreeGetNextSiblingIndex
 * @see _TreeGetFirstChildIndex
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
int _TreeGetPrevSiblingIndex(int ItemIndex);

/**
 * @return Returns the tree item index of the next sibling of the node specified by
 * <i>ItemIndex</i>.  -1 is returned if the node specified has no next
 * sibling.
 *
 * @param ItemIndex     Specifies a tree item.
 *
 * @see _TreeGetParentIndex
 * @see _TreeGetPrevSiblingIndex
 * @see _TreeGetFirstChildIndex
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
int _TreeGetNextSiblingIndex(int ItemIndex);
/**
 * @return Returns the tree item index of the previous tree node as though the tree
 * is a list box.  By default, will not return hidden nodes.  Specify 'H' to
 * return hidden nodes. -1 is returned if the node specified has no next
 * node.
 *
 * @param ItemIndex     Specifies a tree item.
 *
 * @see _TreeGetParentIndex
 * @see _TreeGetNextIndex
 * @see _TreeGetPrevIndex
 * @see _TreeGetNextSiblingIndex
 * @see _TreeGetPrevSiblingIndex
 * @see _TreeGetFirstChildIndex
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
int _TreeGetPrevIndex(int ItemIndex);

/**
 * @return Returns the tree item index of the next tree node as though the tree is a
 * list box.  By default, will not return hidden nodes.  Specify 'H' to
 * return hidden nodes. -1 is returned if the node specified has no next
 * node.
 *
 * @param ItemIndex     Specifies a tree item.
 *
 * @see _TreeGetParentIndex
 * @see _TreeGetNextIndex
 * @see _TreeGetPrevIndex
 * @see _TreeGetNextSiblingIndex
 * @see _TreeGetPrevSiblingIndex
 * @see _TreeGetFirstChildIndex
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
int _TreeGetNextIndex(int ItemIndex);

/**
 * @return Returns the tree item index of the parent of the node specified by
 * <i>ItemIndex</i>.  -1 is returned if the node specified has no parent
 * (this only happens when <i>ItemIndex</i> is 0).
 *
 * @param ItemIndex     Specifies a tree item.
 *
 * @see _TreeGetNextSiblingIndex
 * @see _TreeGetPrevSiblingIndex
 * @see _TreeGetFirstChildIndex
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
int _TreeGetParentIndex(int ItemIndex);

/**
 * Deletes the tree item specified and all its descendants.  <i>option</i>
 * may be "C" or "". When the "C" option is given, only the children of
 * this tree item are deleted.
 *
 * @param ItemIndex     Specifies a tree item.
 * @param option        may be "C" or "".  When the "C" option is given,
 *                      only the children of this tree item are deleted.
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
void _TreeDelete(int ItemIndex,_str option="");

/**
 * This method is for moving the cursor up one page through the
 * displayed tree.  Retuns 0 if successful.  Otherwise TOP_OF_FILE_RC
 * is returned.
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
void _TreePageUp();

/**
 * This method is for moving the cursor down one page through the
 * displayed tree.  Retuns 0 if successful.  Otherwise
 * BOTTOM_OF_FILE_RC is returned.
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
void _TreePageDown();

/**
 * Sets the current index in the display tree.
 *
 * @param ItemIndex           Specifies a tree item.
 *
 * @see _TreeCurIndex
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
void _TreeSetCurIndex(int ItemIndex);

/**
 * @return Returns the depth of the specified tree item.  The depth of the root tree
 * item (ItemIndex=0) is 0.
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
int _TreeGetDepth(int ItemIndex);

/**
 * Sort children of node specified where caption is the primary key
 * and optionally the user info is the secondary key.
 *
 * @param ParentIndex         Tree item index to parent containing children to be sorted.
 * @param PrimarySortOptions  String of one or more of the following options:
 *    <DL>
 *    <DT>'F'<DD>Sort filenames
 *    <DT>'N'<DD>Sort numbers
 *    <DT>'E'<DD>Exact Case.  Sort is case insensitive if this
 *    option is not specified
 *    <DT>'I'<DD>Sort case insensitive
 *    <DT>'B'<DD>First try case insensitive compare, then
 *    perform insensitive
 *    <DT>'D'<DD>Descending.  Sort is ascending if this option
 *    is not specified
 *    <DT>'2'<DD>Sort based only on filename part of caption
 *    <DT>'T'<DD>Traverse children (sort recursively)
 *    <DT>'='<DD>Place parents nodes at the top after sort. Here
 *    we consider a parent nodes to be those with ShowChildren
 *    >= 0.
 *    <DT>'U'<DD>Remove duplicates
 *    <DT>'H'<DD>Hide duplicates
 *    <DT>'C'<DD>Sort current sort column only
 *    </DL>
 * @param SecondarySortOptions String of sort options for secondary key.
 *                             See PrimarySortOptions.
 *
 * @see _TreeSortUserInfo
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
void _TreeSortCaption(int ItemIndex,_str PrimarySortOptions="",_str SecondarySortOptions="");

/**
 * Sort children of node specified where caption is the primary key and
 * optionally the user info is the secondary key.
 *
 * @param ParentIndex   Tree item index to parent containing
 * children to be sorted.
 *
 * @param PrimarySortOptions  String of one or more of the
 * following options:
 *    <DL>
 *    <DT>'F'<DD>Sort filenames
 *    <DT>'N'<DD>Sort numbers
 *    <DT>'E'<DD>Exact Case.  Sort is case insensitive if this
 *    option is not specified
 *    <DT>'I'<DD>Sort case insensitive
 *    <DT>'B'<DD>First try case insensitive compare, then
 *    perform insensitive
 *    <DT>'D'<DD>Descending.  Sort is ascending if this option
 *    is not specified
 *    <DT>'2'<DD>Sort based only on filename part of caption
 *    <DT>'T'<DD>Traverse children (sort recursively)
 *    <DT>'='<DD>Place parents nodes at the top after sort. Here
 *    we consider a parent nodes to be those with ShowChildren
 *    >= 0.
 *    <DT>'U'<DD>Remove duplicates
 *    <DT>'H'<DD>Hide duplicates
 *    <DT>'C'<DD>Sort current sort column only
 *    </DL>
 *
 * @param SecondarySortOptions   String of sort options for secondary
 * key.   See <i>PrimarySortOptions</i>.
 *
 * @see _TreeSortUserInfo
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
void _TreeSortUserInfo(int ItemIndex,_str PrimarySortOptions="",_str SecondarySortOptions="");

/**
 * Searches a tree control.
 *
 * @return Returns the index of the tree item or -1 if the search fails.
 *
 * @param ItemIndex  By default, this is the parent index of the
 * children to be searched.  If the 'S' option is
 * specified, this is the first sibling searched.
 *
 * @param searchCaption Item caption to search for.
 *
 * @param options  A string of zero or more of the following:
 *
 * <dl>
 * <dt>'I'</dt><dd>Case insensitive search.</dd>
 * <dt>'P'</dt><dd>Prefix match.</dd>
 * <dt>'S'</dt><dd>Search siblings.  When this is specified,
 * <i>itemIndex</i> is the first sibling
 * searched.  By default, <i>itemIndex</i>
 * is the parent of the items to be searched.</dd>
 * <dt>'T'</dt><dd>Search recursively through the tree.  By
 * default, only one level is searched.</dd> 
 * <dt>'H'</dt><dd>Search hidden nodes.</dd>
 * 
 * </dl>
 *
 * @param searchUserInfo Option item user info to search for. 
 *  
 * @param ColIndex      Column to search. First column is 0. 
 *                      The default is to search all columns.
 *
 * @see _TreeGetCaption
 * @see _TreeSetInfo
 * @see _TreeGetInfo
 * @see _TreeSetUserInfo
 * @see _TreeGetUserInfo
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 */
int _TreeSearch(int ItemIndex,_str searchCaption,_str options="",_str searchUserInfo=null,int ColIndex=-1);
/**
 * @return Returns the line number of the first visible node is returned.
 *
 * @param NewScrollPos  If lineNumber>=0, then the first visible node is set
 *                      to the node corresponding the line number specified.
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
int _TreeScroll(int lineNumber=-1);

/**
 * @return Returns the line number of the current node in the tree as if the tree we
 * are list box.  If <i>lineNumber</i>>=0, the current node is set to the
 * node corresponding to the line number specified.
 *
 * @param lineNumber    If lineNumber>=0, the current node is set to the node
 *                      corresponding to the line number specified.
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
int _TreeCurLineNumber(int lineNumber=-1);

/**
 * @return Returns the number of children beneath the parent node specified.
 *
 * @param ItemIndex     Specifies a tree item.
 * @param options       If 'T', get the number of children recursively
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
int _TreeGetNumChildren(int ItemIndex,_str options="");

/**
 * Start effecient update of tree contents.  Using this function saves
 * time and reduces the amount of memory allocation and redraws that
 * get triggered when the contents of a tree are updated. 
 *  
 * Do not set column flags (_TreeSetColButtonInfo) between calls 
 * to _TreeBeginUpdate and _TreeEndUpdate, they will be reset. 
 * 
 *
 * @param ItemIndex     Specifies a tree item (parent node to update children of)
 * @param options       if 'T', update the node and all child nodes recursively
 *
 * @see _TreeAddItem
 * @see _TreeEndUpdate
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
int _TreeBeginUpdate(int ItemIndex,_str options="");
/**
 * Finish effecient update of tree contents.  This function will delete
 * all tree nodes that were not recycled during the tree update.
 *  
 * Do not set column flags (_TreeSetColButtonInfo) between calls 
 * to _TreeBeginUpdate and _TreeEndUpdate, they will be reset. 
 *
 * @param ItemIndex     Specifies a tree item (parent node to update children of)
 *
 * @see _TreeBeginUpdate
 * @see _TreeDelete
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
int _TreeEndUpdate(int ItemIndex);
/**
 * Set up the column button info for a multi-column tree control.
 * This is used to add headers and set sorting properties for the colunms.
 *
 * @param ButtonIndex   column index, 0 is the first column
 * @param ButtonWidth   column width, in twips
 * @param ButtonFlags   button flags, bitset of TREE_BUTTON_
 * @param State         initial state of button, depressed or normal
 * @param Caption       Button caption
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
void _TreeSetColButtonInfo(int ButtonIndex,int ButtonWidth,int ButtonFlags=-1,int State=-1,_str Caption='');
/**
 * Retrieve the column button info for a multi-column tree control.
 *
 * @param ButtonIndex   column index, 0 is the first column
 * @param ButtonWidth   column width, in twips
 * @param ButtonFlags   button flags, bitset of TREE_BUTTON_
 * @param State         this is no longer used, it is always 0
 * @param Caption       Button caption
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
void _TreeGetColButtonInfo(int ButtonIndex,int &ButtonWidth,int &ButtonFlags,int &StateNOTUSED,_str &Caption);
/**
 * Delete a tree column from a multi-column tree control.
 *
 * @param ButtonIndex   column index, 0 is the first column
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
void _TreeDeleteColButton(int ButtonIndex);
/**
 * How many columns does the tree control have?
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
int _TreeGetNumColButtons();
/**
 * Retrieve the positional coordinates of the tree control
 *
 * @param ItemIndex           Specifies a tree item
 * @param x                   x position
 * @param y                   y position
 * @param HorizontalScrollPos horizontal scroll positoin
 * @param Height              height
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
void _TreeGetCurCoord(int ItemIndex,int &x,int &y,int &HorizontalScrollPos,int &Height);
/**
 * Sort by a column of a multi-column tree control
 *
 * @param ButtonIndex   column index, 0 is the first column.
 *                      If not specified, find first column with TREEBUTTON_SORT flag on
 * @param PrimarySortOptions  String of one or more of the following options:
 *    <DL>
 *    <DT>'I'<DD>Ignore case
 *    <DT>'F'<DD>Sort filenames
 *    <DT>'N'<DD>Sort numbers
 *    <DT>'E'<DD>Exact Case.  
 *    <DT>'D'<DD>Descending.  Sort is ascending if this option is not specified.
 *    </DL>
 * @param SecondarySortOptions Deprecated
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
void _TreeSortCol(int ButtonIndex=0,_str PrimarySortOptions="",_str SecondarySortOptionsDEPRECATED="");
/**
 * Move an item in the tree up one position.
 *
 * @param ItemIndex   Specifies a tree item
 *
 * @return 0 on success.
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
int _TreeMoveUp(int ItemIndex);
/**
 * Move an item in the tree down one position.
 *
 * @param ItemIndex   Specifies a tree item
 *
 * @return 0 on success.
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
int _TreeMoveDown(int ItemIndex);

/**
 * Compares children of <B><parent1Index/B> and 
 * <B><parent2Index/B>.  These must be in the same tree control. 
 * Does not recurse 
 * @param int parent1Index index of first sub-tree to compare
 * @param int parent2Index index of second sub-tree to compare
 * @param _str reservedOptions 
 * 
 * @return int 0 if sub-trees match.  Otherwise returns the 
 *         strcmp output from comparing the first item that
 *         didn't match
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 */
int _TreeCompare(int parent1Index,int parent2Index,_str reservedOptions="");

/**
 * Set color for a "cell", on column in a tree control 
 *  
 * @param int nodeIndex Index to set the color for
 * @param int col Column (0..N-1) to set the color for
 * @param int FGColor RGB color for text in this cell
 * @param int BGColor RGB color for background in this cell
 * @param int Flags Combination of font flags.  Currently only 
 *            F_INHERIT_FG_COLOR, and F_INHERIT_BG_COLOR are
 *            supported.  These will cause this cell to be
 *            colored the "default" color, either the default
 *            tree color, or one set by _TreeSetColColor
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 */
void _TreeSetColor(int nodeIndex,int col,int FGColor,int BGColor,int Flags);
/**
 * Get color for a "cell", on column in a tree control 
 *  
 * @param int nodeIndex Index to set the color for
 * @param int col Column (0..N-1) to set the color for
 * @param int Gets the FGColor RGB color for text in this cell
 * @param int Gets the BGColor RGB color for background in this 
 *            cell
 * @param int Gets the flags for this cell 
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 */
void _TreeGetColor(int nodeIndex,int col,int &FGColor,int &BGColor,int &Flags);

/**
 * Set color for a column in a tree control.  Does not actually 
 * change the cells, and can be overridden by _TreeSetColor
 *  
 * @param int col Column (0..N-1) to set the color for
 * @param int FGColor RGB color for text in this cell
 * @param int BGColor RGB color for background in this cell
 * @param int Flags Combination of font flags.  Currently only 
 *            F_INHERIT_FG_COLOR, and F_INHERIT_BG_COLOR are
 *            supported.  These will cause this cell to be
 *            colored the "default" color, either the default
 *            tree color, or one set by _TreeSetColColor
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 */
void _TreeSetColColor(int col,int FGColor,int BGColor,int Flags);
/**
 * Get color for a column in a tree control 
 *  
 * @param int col Column (0..N-1) to set the color for
 * @param int Gets the FGColor RGB color for text in this column
 * @param int Gets the BGColor RGB color for background in this 
 *            column
 * @param int Gets the flags for this column
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 */
void _TreeGetColColor();

/**
 * Set color for a row in a tree control.  Actually sets each 
 * cell in the row (as opposed to _TreeSetColColor) 
 *  
 * @param int nodeIndex Index to set the color for
 * @param int FGColor RGB color for text in this row
 * @param int BGColor RGB color for background in this row
 * @param int Flags Combination of font flags.  Currently only 
 *            F_INHERIT_FG_COLOR, and F_INHERIT_BG_COLOR are
 *            supported.  These will cause this cell to be
 *            colored the "default" color, either the default
 *            tree color, or one set by _TreeSetColColor
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 */
void _TreeSetRowColor(int nodeIndex,int FGColor,int BGColor,int Flags);

/**
 * Specify bitmaps to overlay on top of the note bitmap 
 *  
 * @param nodeIndex Index of existing tree node
 * @param bitmapArrayIndex Array of bitmap indexes, [0] is drawn 
 *                         first, then [1], etc.  All have to
 *                         be the same size as the bitmap
 *                         specified when the node was added (or
 *                         scale well to that size)
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 */
void _TreeSetOverlayBitmaps(int nodeIndex,int bitmapArrayIndex[]);

/**
 * @param nodeIndex Index of existing tree node
 * @param bitmapArrayIndex Fills in an array of bitmap indexes
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 */
void _TreeGetOverlayBitmaps(int nodeIndex,int (&bitmapArrayIndex)[]);


#define SHIFT
#define CTRL

#define backspace
#define del
#define enter
#define esc
#define home
#define ins
#define pgdn
#define pgup
#define f1
#define f2
#define f3
#define f4
#define f5
#define f6
#define f7
#define f8
#define f9
#define f10
#define f11
#define f12
#define a_f1
#define a_f2
#define a_f3
#define a_f4
#define a_f5
#define a_f6
#define a_f7
#define a_f8
#define a_f9
#define a_f10
#define a_f11
#define a_f12
#define c_f1
#define c_f2
#define c_f3
#define c_f4
#define c_f5
#define c_f6
#define c_f7
#define c_f8
#define c_f9
#define c_f10
#define c_f11
#define c_f12
#define s_f1
#define s_f2
#define s_f3
#define s_f4
#define s_f5
#define s_f6
#define s_f7
#define s_f8
#define s_f9
#define s_f10
#define s_f11
#define s_f12
#define s_tab
#define a_0
#define a_1
#define a_2
#define a_3
#define a_4
#define a_5
#define a_6
#define a_7
#define a_8
#define a_9
#define a_a
#define a_b
#define a_c
#define a_d
#define a_e
#define a_f
#define a_g
#define a_h
#define a_i
#define a_j
#define a_k
#define a_l
#define a_m
#define a_n
#define a_o
#define a_p
#define a_q
#define a_r
#define a_s
#define a_t
#define a_u
#define a_v
#define a_w
#define a_x
#define a_y
#define a_z
#define a_equal
#define a_minus
#define c_a
#define c_b
#define c_c
#define c_d
#define c_e
#define c_f
#define c_g
#define c_h
#define c_i
#define c_j
#define c_k
#define c_l
#define c_m
#define c_n
#define c_o
#define c_p
#define c_q
#define c_r
#define c_s
#define c_t
#define c_u
#define c_v
#define c_w
#define c_x
#define c_y
#define c_z
#define c_backspace
#define c_end
#define c_home
#define c_left
#define c_pgdn
#define c_pgup
#define c_right
#define a_left
#define a_right
#define c_up
#define a_up
#define a_down
#define c_down
#define a_ins
#define c_ins
#define a_home
#define a_pgup
#define a_del
#define c_del
#define a_end
#define a_pgdn
#define a_pad_slash
#define c_pad_slash
#define a_slash
#define pad_5
#define a_tab
#define a_backspace
#define a_backslash
#define a_comma
#define a_dot
#define a_semicolon
#define a_quote
#define a_left_bracket
#define a_right_bracket
#define a_enter
#define a_pad_plus
#define c_pad_plus
#define pad_star
#define pad_minus
#define pad_plus
#define pad_slash
#define s_left
#define s_right
#define s_up
#define s_down
#define s_pgup
#define s_pgdn
#define s_home
#define s_end
#define c_break
#define c_2
#define a_alt
#define c_ctrl
#define c_minus
#define c_left_bracket
#define c_right_bracket
#define mouse_move
/**
 * <b>Command Button</b> - Occurs when the left mouse button is pressed and released and also when the selection character is pressed.
 * <p><b>Check Box</b> -  Occurs when the left mouse button is pressed and released and also when the selection character is pressed.
 * <p><b>Radio Button</b> - Occurs when the left mouse button is pressed and released and when the {@link p_value} property is changed to a non-zero value.
 * <p><b>Picture Box, Image</b> - Depends on {@link p_style} property as follows:
 *
 * <dl compact style="margin-left:20pt">
 * <dt>PSPIC_DEFAULT<dd style="margin-left:130pt">Occurs when the left mouse button is pressed and released.
 * <dt>PSPIC_PARTIAL_BUTTON<dd style="margin-left:130pt">Occurs when the left mouse button is pressed and released while inside the window.
 * <dt>PSPIC_AUTO_BUTTON<dd style="margin-left:130pt">Occurs when the left mouse button is pressed and released while inside the window.
 * <dt>PSPIC_AUTO_CHECK<dd style="margin-left:130pt">Occurs when the left mouse button is pressed.
 * <dt>PSPIC_BUTTON<dd style="margin-left:130pt">(Image control only) Occurs when the left mouse button is pressed and released while inside the window.
 * <dt>PSPIC_FLAT_BUTTON<dd style="margin-left:130pt">(Image control only) Occurs when the left mouse button is pressed and released while inside the window.
 * <dt>PSPIC_HIGHLIGHTED_BUTTON<dd style="margin-left:130pt">(Image control only) Occurs when the left mouse button is pressed and released while inside the window.
 * </dl>
 *
 *
 * <p><b>Other</b> - Occurs when the left mouse button is released.
 */
#define lbutton_up
#define rbutton_up
#define mbutton_up
#define lbutton_down
#define rbutton_down
#define mbutton_down
#define lbutton_double_click
#define rbutton_double_click
#define mbutton_double_click
#define lbutton_triple_click
#define rbutton_triple_click
#define mbutton_triple_click
#define on_select
#define on_close
#define on_got_focus
#define on_lost_focus
#define on_change
#define on_resize
#define on_timer
#define on_paint
#define on_vsb_line_up
#define on_vsb_line_down
#define on_vsb_page_up
#define on_vsb_page_down
#define on_vsb_thumb_track
#define on_vsb_thumb_pos
#define on_vsb_top
#define on_vsb_bottom
#define on_hsb_line_up
#define on_hsb_line_down
#define on_hsb_page_up
#define on_hsb_page_down
#define on_hsb_thumb_track
#define on_hsb_thumb_pos
#define on_hsb_top
#define on_hsb_bottom
#define on_sb_end_scroll
#define on_drop_down
#define on_drag_drop
#define on_drag_over
#define on_scroll_lock
#define on_num_lock
#define on_drop_files
#define on_create
#define on_destroy
#define on_create2
#define on_destroy2
#define on_spin_up
#define on_spin_down
#define on_scroll
#define on_change2
#define on_load
#define on_init_menu
#define on_keystatechange
#define on_highlight
#define context


#define BACKSPACE
#define DEL
#define ENTER
#define ESC
#define HOME
#define END
#define INS
#define PGDN
#define PGUP
#define TAB
#define UP
#define DOWN
#define LEFT
#define RIGHT
#define F1
#define F2
#define F3
#define F4
#define F5
#define F6
#define F7
#define F8
#define F9
#define F10
#define F11
#define F12
#define A_F1
#define A_F2
#define A_F3
#define A_F4
#define A_F5
#define A_F6
#define A_F7
#define A_F8
#define A_F9
#define A_F10
#define A_F11
#define A_F12
#define C_F1
#define C_F2
#define C_F3
#define C_F4
#define C_F5
#define C_F6
#define C_F7
#define C_F8
#define C_F9
#define C_F10
#define C_F11
#define C_F12
#define S_F1
#define S_F2
#define S_F3
#define S_F4
#define S_F5
#define S_F6
#define S_F7
#define S_F8
#define S_F9
#define S_F10
#define S_F11
#define S_F12
#define S_TAB
#define A_0
#define A_1
#define A_2
#define A_3
#define A_4
#define A_5
#define A_6
#define A_7
#define A_8
#define A_9
#define A_A
#define A_B
#define A_C
#define A_D
#define A_E
#define A_F
#define A_G
#define A_H
#define A_I
#define A_J
#define A_K
#define A_L
#define A_M
#define A_N
#define A_O
#define A_P
#define A_Q
#define A_R
#define A_S
#define A_T
#define A_U
#define A_V
#define A_W
#define A_X
#define A_Y
#define A_Z
#define A_EQUAL
#define A_MINUS
#define C_A
#define C_B
#define C_C
#define C_D
#define C_E
#define C_F
#define C_G
#define C_H
#define C_I
#define C_J
#define C_K
#define C_L
#define C_M
#define C_N
#define C_O
#define C_P
#define C_Q
#define C_R
#define C_S
#define C_T
#define C_U
#define C_V
#define C_W
#define C_X
#define C_Y
#define C_Z
#define C_BACKSPACE
#define C_END
#define C_HOME
#define C_LEFT
#define C_PGDN
#define C_PGUP
#define C_RIGHT
#define A_LEFT
#define A_RIGHT
#define C_UP
#define A_UP
#define A_DOWN
#define C_DOWN
#define A_INS
#define C_INS
#define A_HOME
#define A_PGUP
#define A_DEL
#define C_DEL
#define A_END
#define A_PGDN
#define A_PAD_SLASH
#define C_PAD_SLASH
#define A_SLASH
#define PAD_5
#define A_TAB
#define A_BACKSPACE
#define A_BACKSLASH
#define A_COMMA
#define A_DOT
#define A_SEMICOLON
#define A_QUOTE
#define A_LEFT_BRACKET
#define A_RIGHT_BRACKET
#define A_ENTER
#define A_PAD_PLUS
#define C_PAD_PLUS
#define PAD_STAR
#define PAD_MINUS
#define PAD_PLUS
#define PAD_SLASH
#define S_LEFT
#define S_RIGHT
#define S_UP
#define S_DOWN
#define S_PGUP
#define S_PGDN
#define S_HOME
#define S_END
#define C_BREAK
#define C_2
#define A_ALT
#define C_CTRL
#define C_MINUS
#define C_LEFT_BRACKET
#define C_RIGHT_BRACKET
#define MOUSE_MOVE
#define LBUTTON_UP
#define RBUTTON_UP
#define MBUTTON_UP
#define LBUTTON_DOWN
#define RBUTTON_DOWN
#define MBUTTON_DOWN
#define LBUTTON_DOUBLE_CLICK
#define RBUTTON_DOUBLE_CLICK
#define MBUTTON_DOUBLE_CLICK
#define LBUTTON_TRIPLE_CLICK
#define RBUTTON_TRIPLE_CLICK
#define MBUTTON_TRIPLE_CLICK
#define WHEEL_UP
#define WHEEL_DOWN
#define WHEEL_LEFT
#define WHEEL_RIGHT
#define ON_SELECT
#define ON_CLOSE
#define ON_GOT_FOCUS
#define ON_LOST_FOCUS
#define ON_CHANGE
#define ON_RESIZE
#define ON_TIMER
#define ON_PAINT
#define ON_VSB_LINE_UP
#define ON_VSB_LINE_DOWN
#define ON_VSB_PAGE_UP
#define ON_VSB_PAGE_DOWN
#define ON_VSB_THUMB_TRACK
#define ON_VSB_THUMB_POS
#define ON_VSB_TOP
#define ON_VSB_BOTTOM
#define ON_HSB_LINE_UP
#define ON_HSB_LINE_DOWN
#define ON_HSB_PAGE_UP
#define ON_HSB_PAGE_DOWN
#define ON_HSB_THUMB_TRACK
#define ON_HSB_THUMB_POS
#define ON_HSB_TOP
#define ON_HSB_BOTTOM
#define ON_SB_END_SCROLL
#define ON_DROP_DOWN
#define ON_DRAG_DROP
#define ON_DRAG_OVER
#define ON_SCROLL_LOCK
#define ON_NUM_LOCK
#define ON_DROP_FILES
#define ON_CREATE
#define ON_DESTROY
#define ON_CREATE2
#define ON_DESTROY2
#define ON_SPIN_UP
#define ON_SPIN_DOWN
#define ON_SCROLL
#define ON_CHANGE2
#define ON_LOAD
#define ON_INIT_MENU
#define ON_KEYSTATECHANGE
#define ON_HIGHLIGHT
#define CONTEXT



/**
 * Occurs when the left mouse button is double clicked.
 *
 * @categories Combo_Box_Events, Edit_Window_Events, Editor_Control_Events,
 * Form_Events, Image_Events, List_Box_Events, Picture_Box_Events, Text_Box_Events
 *
 */
typeless lbutton_double_click();
/**
 * Occurs when the left mouse button is triple clicked.
 *
 * @appliesTo Text_Box, Combo_Box, List_Box,  Directory_List_Box,
 * File_List_Box, Drive_List, Vscroll_Bar, Hscroll_Bar
 *
 * @categories Combo_Box_Events, Edit_Window_Events, Editor_Control_Events,
 * Form_Events, Image_Events, List_Box_Events, Picture_Box_Events, Text_Box_Events
 *
 */
typeless lbutton_triple_click();
/**
 * <p>Command Button - Occurs when the left mouse button is pressed and released
 * and also when the selection character is pressed.</p>
 *
 * <p>Check Box -  Occurs when the left mouse button is pressed and released
 * and also when the selection character is pressed.</p>
 *
 * <p>Radio Button -Occurs when the left mouse button is pressed and released
 * and when the p_value property is changed to a non-zero value.</p>
 *
 * <p>Picture Box, Image -Depends on p_style property as follows:</p>
 *
 * <dl>
 * <dt>PSPIC_DEFAULT</dt><dd>Occurs when the left mouse button is pressed and released.<dd>
 * <dt>PSPIC_PARTIAL_BUTTON</dt><dd>Occurs when the left mouse button is pressed and
 * released while inside the window.<dd>
 * <dt>PSPIC_AUTO_BUTTON</dt><dd>Occurs when the left mouse button is pressed and
 * released while inside the window.<dd>
 * <dt>PSPIC_AUTO_CHECK</dt><dd>Occurs when the left mouse button is pressed.<dd>
 * <dt>PSPIC_BUTTON</dt><dd>  (Image control only) Occurs when the left mouse button is
 * pressed and released while inside the window.<dd>
 * <dt>PSPIC_FLAT_BUTTON</dt><dd>(Image control only) Occurs when the left mouse
 * button is pressed and released while inside the window.<dd>
 * <dt>PSPIC_HIGHLIGHTED_BUTTON</dt><dd>(Image control only) Occurs when the left mouse
 * button is pressed and released while inside the window.<dd>
 * <dl>
 *
 * <p>Other - Occurs when the left mouse button is released.</p>
 *
 * @categories Check_Box_Events, Command_Button_Events, Image_Events, Picture_Box_Events, Radio_Button_Events
 *
 */
typeless lbutton_up();
/**
 * Occurs when the left mouse button is pressed.  The lbutton_up event
 * occurs when the left button is released.  This event already has default
 * processing which is not typically overridden.  For an edit window you can
 * bind this event to one of the commands <b>mou_click</b>,
 * <b>mou_click_line</b>, <b>mou_click_block</b>, <b>mou_click_menu</b>,
 * <b>mou_click_menu_line</b>, or <b>mou_click_menu_block</b>.
 *
 * @categories Combo_Box_Events, Edit_Window_Events, Editor_Control_Events,
 * Form_Events, Image_Events, List_Box_Events, Picture_Box_Events, Text_Box_Events
 *
 */
typeless lbutton_down();
/**
 * Reformats current paragraph or selection using left justification.
 *
 * @see justify
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void left_justify();
void mou_set_xy(int x, int y);

/**
 * Occurs when the mouse pointer moves within the window.
 *
 * @categories Combo_Box_Events, Edit_Window_Events, Editor_Control_Events, Form_Events, Image_Events, List_Box_Events, Picture_Box_Events, Text_Box_Events
 *
 */
event mouse_move();

/**
 * <p><b>Text Box</b> - Occurs when the <b>p_text</b> property changes.</p>
 *
 * <p><b>Combo Box</b> - Occurs when the <b>p_text</b> property changes.
 * The <b>on_change</b> event is called with a <i>reason</i> argument which may
 * be one the following constants defined in "slick.sh":</p>
 *
 * <dl>
 * <dt>CHANGE_OTHER</dt><dd>Change probably caused by typing.</dd>
 *
 * <dt>CHANGE_CLINE</dt><dd>Change occurred because selected line in list box changed
 * and the list was visible.</dd>
 *
 * <dt>CHANGE_CLINE_NOTVIS</dt><dd>Change occurred  because a key was pressed
 * which scrolls the list (Up, Down, PgUp, PgDn) while the list was invisible.</dd>
 *
 * <dt>CHANGE_CLINE_NOTVIS2</dt><dd>Same as CHANGE_CLINE_NOTVIS.  Sent
 * to user level 2 inheritance only. User level 2 inheritance will receive the
 * CHANGE_CLINE_NOTVIS reason as well if the user level 1 inheritance does not
 * catch the <b>on_change</b> event.</dd>
 * </dl>
 *
 * <p><b>List Box</b> - The <b>on_change</b> event is called with a
 * <i>reason</i> argument set to CHANGE_SELECTED.  Occurs when items are
 * selected or deselected because of a key press or mouse event.  None of the
 * _lb??? functions cause a list box on_change event.</p>
 *
 * <p><b>Directory List Box</b> - The <b>on_change</b> event is called
 * with a <i>reason</i> argument which may be one of the following <i>reason</i>
 * constants defined in "slick.sh":</p>
 *
 * <dl>
 * <dt>CHANGE_SELECTED</dt><dd>
 * Occurs when items are selected or deselected because of a key press or
 * mouse event.  None of the _lb??? functions cause an on_change event.
 * CHANGE_PATH <b>_dlpath</b> function was called which changed the
 * directory displayed.</dd>
 * </dl>
 *
 * <p><b>File List Box</b> - The <b>on_change</b> event is called with a
 * <i>reason</i> argument which may be one of the following <i>reason</i>
 * constants defined in "slick.sh":</p>
 *
 * <dl>
 * <dt>CHANGE_SELECTED</dt><dd>
 * Occurs when items are selected or deselected because of a key press or
 * mouse event.  None of the _lb??? functions cause an on_change event.</dd>
 *
 * <dt>CHANGE_FILENAME</dt><dd>
 * <b>_flfilename</b> function was called which changed the file names
 * listed.</dd>
 * </dl>
 *
 * <p><b>Drive List -</b>  The <b>on_change</b> event is called with a
 * <i>reason</i> argument which may be one the following constants defined in
 * "slick.sh":</p>
 *
 * <dl>
 * <dt>CHANGE_OTHER</dt><dd><b>p_text</b> property changed probably because of key
 * press.</dd>
 *
 * <dt>CHANGE_CLINE</dt><dd><b>p_text</b> property changed because selected line in
 * list box changed and the list was visible.</dd>
 *
 * <dt>CHANGE_CLINE_NOTVIS
 * </dt><dd><b>p_text</b> property changed because a key was pressed which scrolls
 * the list (Up, Down, PgUp, PgDn) while the list was invisible.</dd>
 *
 * <dt>CHANGE_CLINE_NOTVIS2</dt><dd>
 * Same as CHANGE_CLINE_NOTVIS.  Sent to user level 2 inheritance only.
 * Use level 2 inheritance will receive the CHANGE_CLINE_NOTVIS reason as well
 * if the user level 1 inheritance does not catch the on_change event.</dd>
 *
 * <dt>CHANGE_DRIVE</dt><dd>The drive changed by selecting a different drive from the
 * combo list box.</dd>
 * </dl>
 *
 * <p><b>Vscroll Bar, Hscroll Bar</b> - Sent after dragging the thumb box is
 * completed.  The <b>p_value</b> property has the new scroll position.</p>
 *
 * <p><b>Spin -</b>  The <b>on_change</b> event is called with a
 * <i>reason</i> set to CHANGE_NEW_FOCUS.  This event occurs before an
 * <b>on_spin_up</b> or <b>on_spin_down</b> event to allow you to return the
 * window id of the control you want to get focus after spinning is completed.
 * Return '' if you don't care.</p>
 *
 * <p><b>Tree View -</b>  The <b>on_change</b> event is called with a
 * <i>reason</i> argument which may be one the following constants defined in
 * "slick.sh":</p>
 *
 * <dl>
 * <dt>CHANGE_EXPANDED</dt><dd>
 * Occurs when you expand a level of the tree.  During this event you can
 * fill in the children at this level of the tree. arg(2) is the tree item
 * index.</dd>
 *
 * <dt>CHANGE_COLLAPSED</dt><dd>
 * Occurs when you collapse a level of the tree. arg(2) is the tree item
 * index.</dd>
 *
 * <dt>CHANGE_LEAF_ENTER</dt><dd>
 * User pressed Enter key while on leaf tree item.  arg(2) is the tree
 * item index.</dd>
 * </dl>
 * Will usually be called with the index of the item changing as the second
 * argument
 *
 * <p><b>SSTab -</b>  The <b>on_change</b> event is called with a
 * <i>reason</i> argument which may be one the following constants defined in
 * "slick.sh":</p>
 *
 * <dl>
 * <dt>CHANGE_TABACTIVATED</dt><dd>
 * Occurs when a different tab is activated.  arg(2) is the tab order
 * (p_ActiveTab).</dd>
 *
 * <dt>CHANGE_TABDEACTIVATED</dt><dd>
 * Occurs before a different tab is activated. arg(2) is the tab order
 * (p_ActiveTab).</dd>
 *
 * <dt>CHANGE_TAB_DROP_DOWN_CLICK</dt><dd>
 * The drop-down list was clicked.</dd>
 *
 * <dt>CHANGE_TABMOVED</dt><dd> 
 * Tab was moved from <code>from-index</code> to
 * <code>to-index</code>, where arg(2) is from-index, arg(3) is
 * to-index.</dd>
 * </dl>
 *  
 * @param reason     change event reason, one of CHANGE_* 
 * @param index      identifies the item being changed 
 *  
 * @appliesTo Text_Box, Combo_Box, List_Box,  Directory_List_Box, File_List_Box, Drive_List, Vscroll_Bar, Hscroll_Bar, Spin, Tree_View, SSTab
 * @categories Combo_Box_Events, Directory_List_Box_Events, Drive_List_Events, File_List_Box_Events, Hscroll_Bar_Events, List_Box_Events, Spin_Events, Text_Box_Events, Tree_View_Events, Vscroll_Bar_Events
 *
 */
event on_change(int reason, int index=0);

/**
 * <b>Combo Box -</b>Occurs when the <b>p_text</b> property changes.  No
 * arguments are passed.
 *
 * @appliesTo Combo_Box
 *
 * @categories Combo_Box_Events
 *
 */
event on_change2();

/** 
 * This event is triggered when the mouse passes over an item in
 * a collection control and the item is highlighted.
 * 
 * <b>Combo Box -</b>Occurs when an item is highlighted when you
 * move over it with the mouse.  An index is passed in to 
 * indicate which line was highlighted, followed by the text 
 * for the item which was highlighted. 
 *  
 * @param index      index of item which was highlighted. 
 *                   -1 indicates that the mouse has left the
 *                   control and nothing is being highlighted.
 * @param caption    string caption of the item highlighted 
 *                   this is redundant but passed in for
 *                   convenience.
 *  
 * @appliesTo Combo_Box, List_Box, SSTab, Tree_View
 *
 * @categories Combo_Box_Events, List_Box_Events, SSTab_Properties, Tree_View_Events
 */
event on_highlight(int index, _str caption="");

/**
 * Occurs when dialog box is closed via the system menu of the form or when
 * the user cancels the dialog box (ESC or Alt+F4).  When this event falls
 * through to the dialog manager, the dialog manager looks to see if the form
 * has this event.  If the form has a handler for this event, the form
 * <b>on_close</b> is called.  If the form does not have an <b>on_close</b>
 * event, the dialog manager executes the <b>lbutton_up</b> event handler for
 * the command button with the <b>p_cancel</b> property set to <b>true</b>.  If
 * no such button exists, the dialog managers closes the dialog box.
 *
 * @appliesTo Form
 *
 * @categories Form_Events
 *
 */
event on_close();

/**
 * All objects are sent an <b>on_create</b> event when a dialog box template
 * is loaded with the <b>show</b> or <b>_load_template</b> function.  The
 * <b>show</b> and <b>_load_template</b> function can be given a variable number
 * of arguments to pass to the <b>on_create</b> event.  The on_create event can
 * not be used to change the focus.  Use the <b>on_load</b> function to set the
 * initial focus of a dialog box.
 *
 * @example
 * <pre>
 * #include 'slick.sh'
 * _command mycommand()
 * {
 *     show('form1','first argument', 'second argument');
 * }
 *
 * defeventtab form1;
 * command1.on_create()
 * {
 *    arg1=arg(1);
 *    arg2=arg(2);
 *    message('arg1='arg1' arg2='arg2);
 * }
 * </pre>
 *
 * @appliesTo Text_Box, Combo_Box, List_Box,  Directory_List_Box,
 * File_List_Box, Drive_List, Command_Button, Check_Box, Radio_Button, Frame,
 * Hscroll_Bar, Vscroll_Bar, Spin, Gauge, Image, Form, Tree_View
 *
 * @categories Check_Box_Events, Combo_Box_Events, Command_Button_Events, Directory_List_Box_Events, Drive_List_Events, File_List_Box_Events, Form_Events, Frame_Events, Gauge_Events, Hscroll_Bar_Events, Image_Events, List_Box_Events, Radio_Button_Events, Spin_Events, Text_Box_Events, Tree_View_Events, Vscroll_Bar_Events
 *
 */
event on_create();

/**
 * All objects are sent an <b>on_create2</b> event when a dialog box template
 * is loaded with the <b>show</b> or <b>_load_template</b> function.  No
 * parameters are passed to the <b>on_create2</b> event.  We recommend that only
 * user level 2 inheritance catch this event.  User level 1 inheritance should
 * catch the <b>on_create</b> event instead.
 *
 * @appliesTo Text_Box, Combo_Box, List_Box,  Directory_List_Box,
 * File_List_Box, Drive_List, Command_Button, Check_Box, Radio_Button, Frame,
 * Hscroll_Bar, Vscroll_Bar, Spin, Gauge, Image, Form, Tree_View
 *
 * @categories Check_Box_Events, Combo_Box_Events, Command_Button_Events, Directory_List_Box_Events, Drive_List_Events, File_List_Box_Events, Form_Events, Frame_Events, Gauge_Events, Hscroll_Bar_Events, Image_Events, List_Box_Events, Radio_Button_Events, Spin_Events, Text_Box_Events, Tree_View_Events, Vscroll_Bar_Events
 *
 */
event on_create2();

/**
 * All objects are sent an <b>on_destroy</b> event when the object is deleted
 * with the <b>_delete_window</b> function.
 *
 * @appliesTo Text_Box, Combo_Box, List_Box,  Directory_List_Box,
 * File_List_Box, Drive_List, Command_Button, Check_Box, Radio_Button, Frame,
 * Hscroll_Bar, Vscroll_Bar, Spin, Gauge, Image, Form, Tree_View
 *
 * @categories Check_Box_Events, Combo_Box_Events, Command_Button_Events, Directory_List_Box_Events, Drive_List_Events, File_List_Box_Events, Form_Events, Frame_Events, Gauge_Events, Hscroll_Bar_Events, Image_Events, List_Box_Events, Radio_Button_Events, Spin_Events, Text_Box_Events, Tree_View_Events, Vscroll_Bar_Events
 *
 */
event on_destroy();

/**
 * All objects are sent an <b>on_destroy2</b> event when the object is
 * deleted with the <b>_delete_window</b> function.  We recommend that only user
 * level 2 inheritance catch this event.  User level 1 inheritance should catch
 * the <b>on_destroy</b> event.
 *
 * @appliesTo Text_Box, Combo_Box, List_Box,  Directory_List_Box,
 * File_List_Box, Drive_List, Command_Button, Check_Box, Radio_Button, Frame,
 * Hscroll_Bar, Vscroll_Bar, Spin, Gauge, Image, Form, Tree_View
 *
 * @categories Check_Box_Events, Combo_Box_Events, Command_Button_Events, Directory_List_Box_Events, Drive_List_Events, File_List_Box_Events, Form_Events, Frame_Events, Gauge_Events, Hscroll_Bar_Events, Image_Events, List_Box_Events, Radio_Button_Events, Spin_Events, Text_Box_Events, Tree_View_Events, Vscroll_Bar_Events
 *
 */
event on_destroy2();

/**
 * The <b>on_got_focus</b> event is sent to an object when it receives the
 * input focus.
 *
 * @appliesTo Text_Box, Combo_Box, List_Box,  Directory_List_Box,
 * File_List_Box, Drive_List, Command_Button, Check_Box, Radio_Button, Frame,
 * Hscroll_Bar, Vscroll_Bar, Spin, Gauge, Form, Tree_View
 *
 * @categories Check_Box_Events, Combo_Box_Events, Command_Button_Events, Directory_List_Box_Events, Drive_List_Events, File_List_Box_Events, Form_Events, Frame_Events, Gauge_Events, Hscroll_Bar_Events, List_Box_Events, Radio_Button_Events, Spin_Events, Text_Box_Events, Tree_View_Events, Vscroll_Bar_Events
 *
 */
event on_got_focus();

/**
 * The <b>on_drop_down</b> event is sent to a combo box with a <i>reason</i>
 * argument.  The <i>reason</i> argument specifies one of the following
 * conditions:
 *
 * <dl>
 * <dt>DROP_UP</dt><dd>After combo list box is made invisible.</dd>
 * <dt>DROP_DOWN</dt><dd>Before combo list box is made visible.</dd>
 * <dt>DROP_INIT</dt><dd>Before retrieve next/previous.  Used to initialize list box
 * before it is accessed.</dd>
 * <dt>DROP_UP_SELECTED</dt><dd>Mouse released while on valid selection in list box
 * and list is visible.</dd>
 * </dl>
 *
 * @example
 * <pre>
 * #include "slick.sh"
 * defeventtab form1;
 * void combo1.on_drop_down(int reason)
 * {
 *     if (reason==DROP_INIT) {
 *        if (p_user=='') {
 *            p_user=1;   // Indicate that the list box has been filled.
 *            // Insert one heck of a lot of items
 *            _insert_name_list(COMMAND_TYPE);
 *            _lbsort();
 *            _lbtop();
 *        }
 *     }
 * }
 * </pre>
 *
 * @appliesTo Combo_Box
 *
 * @categories Combo_Box_Events
 *
 */
event on_drop_down();

/**
 * The <b>on_hsb_bottom</b> event is sent to an Edit Window when the
 * horizontal thumb is placed in the farthest right position.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Events, Editor_Control_Events
 *
 */
event on_hsb_bottom();

/**
 * The <b>on_hsb_line_down</b> event is sent when the right arrow of a
 * horizontal scroll bar is pressed.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Events, Editor_Control_Events
 *
 */
event on_hsb_line_down();

/**
 * The <b>on_hsb_line_up</b> event is sent when the left arrow of a
 * horizontal scroll bar is pressed.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Events, Editor_Control_Events
 *
 */
event on_hsb_line_up();

/**
 * The <b>on_hsb_page_down</b> event is sent when the you click on the area
 * between thumb box and right arrow of a horizontal scroll bar.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Events, Editor_Control_Events
 *
 */
event on_hsb_page_down();

/**
 * The <b>on_hsb_page_up</b> event is sent when the you click on the area
 * between the left arrow and the thumb box of a horizontal scroll bar.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Events, Editor_Control_Events
 *
 */
event on_hsb_page_up();

/**
 * The <b>on_hsb_thumb_pos</b> event is sent when you click and drag the
 * thumb box of a horizontal scroll bar.  The <i>hsb_pos</i> argument is a
 * number between 0 and 32000 and corresponds to the far left and right
 * positions.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Events, Editor_Control_Events
 *
 */
event on_hsb_thumb_pos();

/**
 * The <b>on_hsb_thumb_track</b> event is sent when you finish dragging the
 * thumb box of a horizontal scroll bar.  The <i>hsb_pos</i> argument is a
 * number between 0 and 32000 and corresponds to the far left and right
 * positions.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Events, Editor_Control_Events
 *
 */
event on_hsb_thumb_track();

/**
 * The <b>on_hsb_top</b> event is sent to an Edit Window when the horizontal
 * thumb is placed in the farthest left position.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Events, Editor_Control_Events
 *
 */
event on_hsb_top();
/**
 * The <b>on_init_menu</b> event is sent to a Form or MDI Window which has a
 * menu bar just before the user activates the menu.  This event is typically
 * used to gray out menu items just before the user sees the drop-menus.
 *
 * @example
 * <pre>
 * #include "slick.sh"
 * // Create a form called form1 and set the border style to anything BUT
 * // BDS_DIALOG BOX.  Windows does not allow forms with a dialog
 * // box style border to have menu bars.
 * defeventtab form1;
 * form1.on_load()
 * {
 *     // Find index of SlickEdit MDI menu resource
 *     index=find_index(def_mdi_menu,oi2type(OI_MENU));
 *     // Load this menu resource
 *     menu_handle=p_active_form._menu_load(index);
 *     // _set_menu will fail if the form has a dialog box style border.
 *     // Put a menu bar on this form.
 *     _menu_set(menu_handle);
 *     // You DO NOT need to call _menu_destroy.  This menu is destroyed when
 * the form
 *     // window is deleted.
 * }
 * form1.on_init_menu()
 * {
 *     // Gray out all menu items which are not allowed when there no child
 * windows.
 *     _menu_set_state(p_menu_handle,"!ncw",MF_GRAYED,'C');
 * }
 * </pre>
 *
 * @see _menu_add_filehist
 * @see _menu_add_hist
 * @see _menu_add_workspace_hist
 * @see _menu_destroy
 * @see _menu_find
 * @see _menu_get_state
 * @see _menu_info
 * @see _menu_insert
 * @see _menu_load
 * @see _menu_match
 * @see _menu_move
 * @see _menu_set
 * @see _menu_set_state
 * @see _menu_show
 * @see alt_menu
 * @see insert_object
 * @see menu_mdi_bind_all
 * @see mou_show_menu
 * @see show
 *
 * @appliesTo MDI_Window, Form
 *
 * @categories Form_Events, MDI_Window_Events
 *
 */
event on_init_menu();

/**
 * The on_keystatechange event is returned by the <b>get_event</b>
 * function to indicate that a shift key has been pressed or released.  You must
 * call the <b>mou_mode</b> function with a one for this event to be returned by
 * the get_event function.
 *
 * @example
 * <pre>
 * defmain()
 * {
 *      mou_mode(1);
 * OuterLoop:
 *      for (;;) {
 *          event=get_event();
 *          switch( event ) {
 *          case ESC:
 *               break OuterLoop;
 *           case ON_KEYSTATECHANGE:
 *               if (_IsKeyDown(CTRL) ){
 *                    message("CTRL is down");
 *                } else {
 *                     message("CTRL is not down");
 *                }
 *            }
 *       }
 *       mou_mode(0);
 *            }
 *
 * </pre>
 *
 * @categories Keyboard_Functions
 *
 */
event on_keystatechange();

/**
 * The <b>on_load</b> event is sent to a form (after the <b>on_create</b> and
 * <b>on_create2</b> events) when a dialog box template is loaded with the
 * <b>show</b> or <b>_load_template</b> function.  The <b>on_load</b> event is
 * intended to be used to set the control which has the initial focus.  Use the
 * <b>on_create</b> event unless you need to set the initial focus.
 *
 * @example
 * <pre>
 * #include 'slick.sh'
 * defeventtab form1;
 * form1.on_load()
 * {
 *     // Change the focus to the text2 control
 *     p_window_id=_control text2;
 * }
 * </pre>
 *
 * @appliesTo Form
 *
 * @categories Form_Events
 *
 */
event on_load();

/**
 * The <b>on_lost_focus</b> event is sent to an object when it loses input
 * focus.
 *
 * @appliesTo Text_Box, Combo_Box, List_Box,  Directory_List_Box,
 * File_List_Box, Drive_List, Command_Button, Check_Box, Radio_Button, Frame,
 * Hscroll_Bar, Vscroll_Bar, Spin, Gauge, Form, Tree_View
 *
 * @categories Check_Box_Events, Combo_Box_Events, Command_Button_Events, Directory_List_Box_Events, Drive_List_Events, File_List_Box_Events, Form_Events, Frame_Events, Gauge_Events, Hscroll_Bar_Events, List_Box_Events, Radio_Button_Events, Spin_Events, Text_Box_Events, Tree_View_Events, Vscroll_Bar_Events
 *
 */
event on_lost_focus();

/**
 * The <b>on_resize</b> event is sent to an object when the window position
 * or size is changed.  Use the <b>p_x</b>, <b>p_y</b>, <b>p_width</b>, and
 * <b>p_height</b> properties to get the position and size.
 *
 * The on_resize event is called with an argument aht specifies
 * whether the size or the position of the control was changed.
 * This value is 0 if the control was resized, and 1 if the
 * control was simply moved.
 *
 * @appliesTo Text_Box, Combo_Box, List_Box,  Directory_List_Box,
 * File_List_Box, Drive_List, Command_Button, Check_Box, Radio_Button, Frame,
 * Hscroll_Bar, Vscroll_Bar, Spin, Gauge, Form, Tree_View
 *
 * @categories Check_Box_Events, Combo_Box_Events, Command_Button_Events, Directory_List_Box_Events, Drive_List_Events, File_List_Box_Events, Form_Events, Frame_Events, Gauge_Events, Hscroll_Bar_Events, List_Box_Events, Radio_Button_Events, Spin_Events, Text_Box_Events, Tree_View_Events, Vscroll_Bar_Events
 *
 */
event on_resize();

/**
 * The <b>on_scroll</b> event is sent when you click and drag the thumb box
 * of a scroll bar.  The <b>on_change</b> event is sent after dragging the thumb
 * box is completed.
 *
 * @example
 * <pre>
 * #include 'slick.sh'
 *
 * defeventtab form1;
 * hscroll1.on_scroll()
 * {
 *    message('on_scroll p_value='p_value);
 * }
 * hscroll1.on_change()
 * {
 *    message('on_change p_value='p_value);
 * }
 * </pre>
 *
 * @see on_change
 *
 * @appliesTo Hscroll_Bar, Vscroll_Bar
 *
 * @categories Hscroll_Bar_Events, Vscroll_Bar_Events
 *
 */
event on_scroll();

/**
 * The <b>on_scroll_lock</b> event is sent when the scroll lock key is
 * pressed.  The <i>value</i> parameter is 1 if scroll lock is on.  Otherwise,
 * <i>value</i> is 0.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Events, Editor_Control_Events
 *
 */
event on_scroll_lock();

/**
 * The <b>on_select</b> event is sent before a key press event when the
 * current buffer has a selection.  User level 1 and user level 2 inheritance
 * can not catch this event.  Only the <b>default_keys</b> event table can
 * process this event.  This event will not occur if the user level 1 or user
 * level 2 inheritance has an event handler for the key.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Events, Editor_Control_Events
 *
 */
event on_select();

/**
 * The <b>on_spin_down</b> event is sent to a spin control if the
 * <b>p_increment</b> property is 0.  When the <b>p_increment</b> property is
 * non-zero, the number in the previous control in the tab order (which must be
 * a text box) is decremented.
 *
 * @appliesTo Spin
 *
 * @categories Spin_Events
 *
 */
event on_spin_down();

/**
 * The <b>on_spin_up</b> event is sent to a spin control if the
 * <b>p_increment</b> property is 0.  When the <b>p_increment</b> property is
 * non-zero, the number in the previous control in the tab order (which must be
 * a text box) is incremented.
 *
 * @appliesTo Spin
 *
 * @categories Spin_Events
 *
 */
event on_spin_up();

/**
 * The <b>on_timer</b> event is returned by the <b>get_event</b> function
 * when <b>_set_timer</b> is called with only the first argument.
 *
 * @categories Miscellaneous_Functions
 */
event on_timer();

/**
 * The <b>on_vsb_bottom</b> event is sent to an Edit Window when the
 * horizontal thumb is placed in the bottom position.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Events, Editor_Control_Events
 *
 */
event on_vsb_bottom();

/**
 * The <b>on_vsb_line_down</b> event is sent when the down arrow of a
 * horizontal scroll bar is pressed.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Events, Editor_Control_Events
 *
 */
event on_vsb_line_down();

/**
 * The <b>on_vsb_line_up</b> event is sent when the up arrow of a horizontal
 * scroll bar is pressed.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Events, Editor_Control_Events
 *
 */
event on_vsb_line_up();

/**
 * The <b>on_vsb_page_down</b> event is sent when the you click on the area
 * between thumb box and down arrow of a horizontal scroll bar.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Events, Editor_Control_Events
 *
 */
event on_vsb_page_down();

/**
 * The <b>on_vsb_page_up</b> event is sent when the you click on the area
 * between the up arrow and the thumb box of a horizontal scroll bar.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Events, Editor_Control_Events
 *
 */
event on_vsb_page_up();

/**
 * The <b>on_vsb_thumb_pos</b> event is sent when you click and drag the
 * thumb box of a vertical scroll bar.  The <i>vsb_pos</i> argument is a number
 * between 0 and 32000 and corresponds to the far left and right positions.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Events, Editor_Control_Events
 *
 */
event on_vsb_thumb_pos();

/**
 * The <b>on_vsb_thumb_track</b> event is sent when you finish dragging the
 * thumb box of a vertical scroll bar.  The <i>vsb_pos</i> argument is a number
 * between 0 and 32000 and corresponds to the far left and right positions.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Events, Editor_Control_Events
 *
 */
event on_vsb_thumb_track();

/**
 * The <b>on_vsb_top</b> event is sent to an Edit Window when the vertical
 * scroll bar thumb box is placed in the top position.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Events, Editor_Control_Events
 *
 */
event on_vsb_top();

/**
 * Occurs when the right mouse button is double clicked.
 *
 * @categories All_Windows_Properties
 */
event rbutton_double_click();
/**
 * Occurs when the right mouse button is pressed.  The rbutton_up event
 * occurs when the right button is released.
 *
 * @categories All_Windows_Properties
 */
event rbutton_down();
/**
 * Occurs when the right mouse button is triple clicked.
 *
 * @categories All_Windows_Properties
 */
event rbutton_triple_click();
/**
 * Occurs when the right button is released.
 *
 * @categories All_Windows_Properties
 */
event rbutton_up();

/**
 * <b>rc</b> is a global variable that is automatically defined by the Slick-C&reg;
 * translator.  We have shifted the Slick-C&reg; language away from needing
 * this variable.  However, there are still a few functions such as
 * <b>buf_match</b>, and <b>get_env</b> which requires its use for
 * error checking.  Many other functions set the <b>rc</b> variable, but
 * we have not documented them to prevent unnecessary use of the
 * <b>rc</b> variable.  See also Error handling and the RC Variable.
 *
 * @categories All_Windows_Properties
 */
typeless rc;


/**
 * Add an extensions specific keyboard 
 * callback 
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * @param callback_index  Index into names table of command or function to call.  Signature 
 *                        is boolean mycallback(). Return true if no further processing of
 *                        this key is necessary.
 * @param keyList  Array of keys that may be handled by this callback.
 * @param options
 *    options may contain one or more of the following option letters:
 *    'K' - All keys
 *  
 * @example <pre>
 * boolean _on_key_my_callback() {
 *     say('key='last_event());
 *     return(false);
 * }
 * // Note that these callbacks typically use the naming convention _on_key_&lt;p_LangId&gt;
 * _str keyList[];
 * keyList[0]='(';keyList[1]=')';
 * _kbd_add_callback(find_index("_on_key_my_callback",PROC_TYPE),keyList);
 * </pre>
 * @see _kbd_remove_callback
 * @see _kbd_try_callbacks
 */
void _kbd_add_callback(int callback_index, _str (&keyList)[], _str options = null);
/**
 * remove an extensions specific keyboard callback 
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * @param callback_index  Index of callback function specified by 
 *                        _kbd_add_callback. Using callback_index == -1 will
 *                        remove all callbacks.
 * 
 * @see _kbd_add_callback
 * @see _kbd_try_callbacks
 */
void _kbd_remove_callback(int callback_index);
/**
 * Tries each extensions specific keyboard callback that supports this key. If 
 * one of the callbacks returns true, no further processing of the key is done. 
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 * @see _kbd_add_callback
 * @see _kbd_remove_callback
 */
void _kbd_try_callbacks();


/**
 * Set to true if current text change has occurred during a word wrap or XML 
 * wrap operation. 
 *  
 * @appliesTo Editor_Control, Edit_Window
 * @categories Editor_Control_Properties, Edit_Window_Properties
 */
int p_TextWrapChangeNotify;

/**
 * When on, use file status overlays on file bitmaps
 * @categories Tree_View_Properties
 * @appliesTo Tree_View
 */
int p_UseFileInfoOverlays;

/**
 * When on, show the expand/collapse picture on tree nodes
 * @categories Tree_View_Properties
 * @appliesTo Tree_View
 */
boolean p_ShowExpandPicture;

/**
 * Return the frame-width of the active window in pixels.
 *
 * @appliesTo Picture_Box
 * @categories Picture_Box_Methods
 */
int _frame_width();
