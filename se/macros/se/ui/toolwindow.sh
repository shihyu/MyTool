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
#pragma option(metadata,"toolwindow.e")


enum_flags ToolWindowFlag {
   TWF_FIXEDHEIGHT = 0x001,  // (system) Tool-window has fixed height
   TWF_NO_TABLINK  = 0x002,  // (system) Do not tab-link tool-window into tabgroup
   TWF_NO_DOCKING  = 0x004,  // (user) Do not allow tool-window to be docked with other tool-windows

   TWF_SUPPORTS_MULTIPLE   = 0x008,  // (system) Support multiple instances of tool-window
   TWF_NO_UNPIN            = 0x010,  // (system) Do not allow tool-window unpin action

   // (user) Solitary floating tool-window, ESC dismisses the window like a dialog
   TWF_DISMISS_LIKE_DIALOG = 0x020,  

   // (system) Debug tool-windows
   // - Are opened from Debug>Windows menu.
   // - Are not listed in tool-window list at View>Tool Windows unless in
   //   debug mode.
   TWF_WHEN_DEBUGGER_STARTED_ONLY   = 0x040,
   TWF_WHEN_DEBUGGER_SUPPORTED_ONLY = 0x080,
   TWF_LIST_WITH_DEBUG_TOOLWINDOWS  = 0x100,

   TWF_FIXEDWIDTH = 0x200,  // (system) Tool-window has fixed width

   // System flags (i.e. not user-settable)
   TWF_SYSTEM_MASK = (TWF_FIXEDHEIGHT | TWF_FIXEDWIDTH | TWF_NO_TABLINK | TWF_NO_UNPIN | TWF_SUPPORTS_MULTIPLE | TWF_WHEN_DEBUGGER_STARTED_ONLY | TWF_WHEN_DEBUGGER_SUPPORTED_ONLY | TWF_LIST_WITH_DEBUG_TOOLWINDOWS)
};

enum_flags ToolWindowRequireFlag {
   TW_REQUIRE_NONE             = 0,

   TW_REQUIRE_BUILD            = 0x0001,
   TW_REQUIRE_DEBUGGING        = 0x0002,
   TW_REQUIRE_CONTEXT_TAGGING  = 0x0004,
   TW_REQUIRE_VERSION_CONTROL  = 0x0008,
   TW_REQUIRE_PRO_MACROS       = 0x0010,
   TW_REQUIRE_BEAUTIFIER       = 0x0020,
   TW_REQUIRE_PRO_DIFF         = 0x0040,
   TW_REQUIRE_MERGE            = 0x0080,
   TW_REQUIRE_REFACTORING      = 0x0100,
   TW_REQUIRE_REALTIMEERRORS   = 0x0200,
   TW_REQUIRE_DEFS             = 0x0400,
   TW_REQUIRE_FTP              = 0x0800,
   TW_REQUIRE_BACKUP_HISTORY   = 0x1000,
   TW_REQUIRE_BUFFTABS         = 0x2000,
};

enum_flags ToolWindowDockingFlag {
   TWD_INSERTAFTER = 0x1,  // Insert tool-window after current window
   TWD_EDGE        = 0x2   // Insert tool-window along edge of application frame
};

struct ToolWindowInfo {
   int flags;      // ToolWindowFlag
   DockAreaPos preferredArea;  // If no last docking info, then use preferredArea
   int rflags;     // ToolWindowRequireFlag
};

_metadata enum_flags ToolWindowOption {
   /**
    * Disable Auto Hide for all tool-windows.
    */
   TWOPTION_NO_AUTOHIDE          = 0x1,
   /**
    * When a tool-window is closed, and it is tab-linked into a 
    * tabgroup, close ALL tool-windows in the tabgroup. 
    */
   TWOPTION_CLOSE_TABGROUP       = 0x2,
   /**
    * When a tool window is Auto Hidden, and it is tab-linked into a tabgroup,
    * DO NOT auto hide all tool windows in the tabgroup.
    */
   TWOPTION_NO_AUTOHIDE_TABGROUP = 0x4,
   /**
    * When a tool window is active, and selected from the tool window menu 
    * hide the tool window if it is selected from the menu (thus toggling it).
    */
   TWOPTION_MENU_TOGGLE_SHOW_HIDE = 0x8,
};

struct RestoreGroupItem {
   _str name;  // Form name of window or PlaceHolder
   int wid;    // Window id. If 0, then this item is a PlaceHolder.
};
struct RestoreGroupInfo {
   int mdi_wid;  // MDI window that restore group belongs to
   WindowRestorePosition position;
   int current;  // Current wid
   RestoreGroupItem items[];
};

const TWAUTOHIDE_DELAY_DEFAULT= (1000);

/**
 * Bitwise flags for global tool-window options. See TWOPTION_* 
 * for more information. 
 */
int def_toolwindow_options;

enum_flags ToolWindowFindFormFlag {
   TWFF_ACTIVE_FORM = 0x1,   // Find active form (p_active_form)
   TWFF_FOCUS_FORM  = 0x2,   // Find form with focus (_get_focus().p_active_form)
   TWFF_CURRENT_MDI = 0x4,   // Find on current mdi-window (_MDICurrent(), or mdi_wid passed in to tw_find_form())
   TWFF_UNDOCKED    = 0x8,   // Find undocked windows (undocked windows are floating and not attached to an mdi-area
   TWFF_ANY         = 0x10,  // The "hail mary" flag finds non-edited form any where
};

/**
 * Register window <code>wid</code> as a tool-window. Must call 
 * this function before adding a tool-window to a layout. 
 *
 * <p>
 *
 * Set <code>flags</code> to one or more of ToolWindowFlag. 
 *
 * <p>
 *
 * Set <code>preferredArea</code> to one of DockArea.
 * 
 * @param wid 
 * @param flags
 * @param preferredArea
 */
extern int tw_register(int wid, int flags, int preferredArea);

/**
 * Add tool-window <code>wid</code> to current tabgroup. Set 
 * <code>mdi_wid</code> to add to specific mdi-window; set to 0
 * for current mdi-window. 
 *
 * <p>
 *
 * Set <code>dFlags</code> to one or more of 
 * ToolWindowDockingFlag. 
 * 
 * @param mdi_wid 
 * @param wid 
 * @param dFlags
 */
extern void tw_add(int mdi_wid, int wid, int dFlags);

/**
 * Remove tool-window specified by <code>wid</code>. Tool-window
 * is NOT destroyed. 
 *
 * @param wid
 */
extern void tw_remove(int wid);

/**
 * Create a new horizontal tile from tool-window 
 * <code>wid</code>. If tool-window is already part of a 
 * tile/tabgroup, then it is removed and inserted into 
 * new tile. Set <code>mdi_wid</code> to add new tile to 
 * specific mdi-window; set to 0 for current mdi-window. Set 
 * <code>insertAfter=true</code> to create tile after current 
 * tile/tabgroup. Set <code>edge=true</code> and 
 * <code>insertAfter=false</code> to create tile along top edge 
 * of main-area. Set <code>edge=true</code> and 
 * <code>insertAfter=true</code> to create tile along bottom 
 * edge of main-area. Tool-window is inserted as first tab of a 
 * new tabgroup by default unless registered with TWF_NO_TABLINK 
 * flag. 
 *
 * <p>
 *
 * Set <code>dFlags</code> to one or more of 
 * ToolWindowDockingFlag. 
 *
 * @param mdi_wid 
 * @param wid
 * @param dFlags
 */
extern void tw_new_horizontal_tile(int mdi_wid, int wid, int dFlags);

/**
 * Create a new vertical tile from tool-window <code>wid</code>. 
 * If tool-window is already part of a tile/tabgroup, then it is 
 * removed and inserted into new tile. Set <code>mdi_wid</code> 
 * to add new tile to specific mdi-window; set to 0 for current 
 * mdi-window. Set <code>insertAfter=true</code> to create tile 
 * after current tile/tabgroup. Set <code>edge=true</code> and 
 * <code>insertAfter=false</code> to create tile along left edge 
 * of main-area. Set <code>edge=true</code> and 
 * <code>insertAfter=true</code> to create tile along right edge 
 * of main-area. Tool-window is inserted as first tab of a new 
 * tabgroup by default unless registered with TWF_NO_TABLINK 
 * flag. 
 *
 * <p>
 *
 * Set <code>dFlags</code> to one or more of 
 * ToolWindowDockingFlag. 
 *
 * @param mdi_wid 
 * @param wid
 * @param dFlags
 */
extern void tw_new_vertical_tile(int mdi_wid, int wid, int dFlags);

/**
 * Set tool-window <code>wid</code> active. If tool-window is
 * part of a tabgroup, then the tab is set current. 
 * 
 * @param wid 
 */
extern void tw_set_active(int wid);

/**
 * Float tool-window <code>wid</code>. 
 *  
 * @param wid 
 */
extern void tw_float(int wid);

/**
 * Restore tool-window <code>wid</code> to last known 
 * <code>position</code>. 
 *  
 * @param wid 
 * @param position 
 */
extern void tw_restore(int wid, WindowRestorePosition position);

/**
 * Delete tool-window specified by <code>wid</code>. Set 
 * <code>noRestore=true</code> if you do not want the layout to 
 * remember the position of the tool-window. Otherwise you can 
 * call <code>tw_restore</code> later to restore the tool-window 
 * to the remembered position. 
 *
 * <p>
 *
 * Note that passing <code>noRestore=true</code> is equivalent 
 * to calling Slick-C <code>_delete_window()</code>. 
 *
 * @param wid
 * @param noRestore
 */
extern void tw_delete(int wid, bool noRestore=false);

/**
 * Return true if tool-window <code>wid</code> is a floating 
 * tool-window, false if a docked tool-window. 
 *  
 * @param wid
 *
 * @return bool.
 */
extern bool tw_is_floating(int wid);

/**
 * Finds tool-window adjacent to tool-window <code>wid</code>. 
 *  
 * @param wid            Tool-window window id (form wid)
 * @param option_letter   One of the following:
 *    <dl compact>
 *    <dt><b>"L"</b> <dd>find tab to left
 *    <dt><b>"R"</b> <dd>find tab to right
 *    <dt><b>"A"</b> <dd>find tab above
 *    <dt><b>"B"</b> <dd>find tab below
 *    <dt><b>"N"</b> <dd>find next tab (current or not)
 *    <dt><b>"P"</b> <dd>find previous tab (current or not)
 *    <dt><b>"C"</b> <dd>find current tab within tab group
 *    <dt><b>"F</b> <dd>first window in this window's tab group
 *    <dt><b>"Z</b> <dd>last window in this window's tab group
 *    <dt><b>"1"</b> <dd>find next tab within tab group
 *    <dt><b>"2"</b> <dd>find previous tab within tab group
 *    <dt><b>"G"</b> <dd>find next tab group
 *    <dt><b>"H"</b> <dd>find previous tab group
 *    <dt><b>"g"</b> <dd>find next tab group (not circular)
 *    <dt><b>"h"</b> <dd>find previous tab group (not circular)
 *    </dl>
 * @param move_or_close  True means window edge can be sized
 *                       with current window
 *
 * @return Non-zero window id if adjacent tool-window exists. 0 
 *         otherwise.
 */
extern int tw_next_window(int wid, _str option_letter, bool move_or_close);

/**
 * Return current tool-window id of the specified MDI window 
 * <code>mdi_wid</code>. Set <code>mdi_wid=0</code> to specify 
 * most recent MDI window. 
 *  
 * @param mdi_wid 
 *  
 * @return Tool-window window id, or 0 if no window.
 */
extern int tw_current_window(int mdi_wid);

/**
 * Return the list of tool-window window-ids, registered with 
 * <code>tw_register</code>, into the array of 
 * <code>wids</code>. Set <code>mdi_wid</code> to a specific 
 * mdi-window to only return tool-windows for that mdi-window. 
 * Set <code>mdi_wid=0</code> to return all tool-windows (even 
 * those that are not part of a layout). 
 *
 * @param wids
 */
extern void tw_get_registered_windows(int (&wids)[], int mdi_wid=0);

/**
 * Return the restore <code>info</code> for the tool-window form
 * name <code>form_name</code> at given <code>position</code>. 
 * Typically used to restore an entire tabgroup. 
 * 
 * @param form_name 
 * @param position 
 * @param info 
 */
extern void tw_get_restore_info(_str form_name, WindowRestorePosition position, RestoreGroupInfo& info);

/**
 * Return the <code>vsDockAreaPos</code> position of tool-window
 * <code>wid</code> relative to the MDI area. If tool-window 
 * does not belong to an area yet, then VSDOCKAREAPOS_NONE is
 * returned. 
 * 
 * @param wid 
 * 
 * @return vsDockAreaPos 
 */
extern DockAreaPos tw_dock_area(int wid);

/**
 * Test tool-window <code>wid</code> flag <code>f</code>. If 
 * flag is set, then return true, otherwise return false. 
 *
 * @param wid 
 * @param f 
 *
 * @return bool
 */
extern bool tw_test_flag(int wid, ToolWindowFlag f);

/**
 * (Un)set tool-window <code>wid</code> flag <code>f</code>. If 
 * <code>v=true</code>, then flag is set, otherwise flag is 
 * unset. 
 *
 * @param wid 
 * @param f 
 * @param v 
 */
extern void tw_set_flag(int wid, ToolWindowFlag f, bool v=true);

/**
 * Auto-hide tool-window <code>wid</code> to 
 * left/right/top/bottom edge of main window. Edge is determined
 * by where tool-window is in relation to the mdi-area. Set
 * <code>hideGroup=true</code> to auto-hide all tool-windows in 
 * the same tabgroup. 
 *
 * @param wid  
 * @param hideGroup 
 */
extern void tw_auto_hide(int wid, bool hideGroup);

/**
 * Raise auto-hide tool-window <code>wid</code>. 
 * 
 * @param wid 
 */
extern void tw_auto_raise(int wid);

/**
 * Lower auto-hide tool-window <code>wid</code>. 
 * 
 * @param wid 
 */
extern void tw_auto_lower(int wid);

/**
 * Return true if tool-window <code>wid</code> is an auto-hide 
 * window. Note that if you want to know whether an auto-hide 
 * tool-window is visible (raised) or hidden (lowered), then use
 * <code>tw_is_auto_raised()</code>. <code>to_mdi_wid</code> specifies 
 * which mdi window to test. Set it to 0 to test all mdi 
 * windows. 
 * 
 * @param wid 
 * @param to_mdi_wid 
 *
 * @return bool
 */
extern bool tw_is_auto(int wid, int to_mdi_wid=0);

/**
 * Return true if tool-window <code>wid</code> is a raised (i.e.
 * visible) auto-hide window. <code>to_mdi_wid</code> specifies 
 * which mdi window to test. Set it to 0 to test all mdi 
 * windows. 
 * 
 * @param wid 
 * @param to_mdi_wid 
 *
 * @return bool
 */
extern bool tw_is_auto_raised(int wid, int to_mdi_wid=0);

/**
 * Restore auto-hide tool-window <code>wid</code> to last known 
 * window-position. Set <code>restoreGroup=true</code> to 
 * restore all auto-hide tool-windows in the same tabgroup. 
 *
 * @param wid 
 * @param restoreGroup 
 */
extern void tw_auto_restore(int wid, bool restoreGroup);

