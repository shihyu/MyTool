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
#pragma option(metadata,"toolbar.e")

enum DockingArea {
   DOCKINGAREA_NONE   = 0,
   DOCKINGAREA_LEFT,
   DOCKINGAREA_TOP,
   DOCKINGAREA_RIGHT,
   DOCKINGAREA_BOTTOM,

   DOCKINGAREA_FIRST = DOCKINGAREA_LEFT,
   DOCKINGAREA_LAST = DOCKINGAREA_BOTTOM,

   // Unspecified (ALL in some contexts)
   DOCKINGAREA_UNSPEC = -1
};

enum_flags ToolbarRequireFlag {
   TB_REQUIRE_NONE             = 0,

   TB_REQUIRE_BUILD            = 0x0001,
   TB_REQUIRE_DEBUGGING        = 0x0002,
   TB_REQUIRE_CONTEXT_TAGGING  = 0x0004,
   TB_REQUIRE_VERSION_CONTROL  = 0x0008,
   TB_REQUIRE_PRO_MACROS       = 0x0010,
   TB_REQUIRE_BEAUTIFIER       = 0x0020,
   TB_REQUIRE_PRO_DIFF         = 0x0040,
   TB_REQUIRE_MERGE            = 0x0080,
   TB_REQUIRE_REFACTORING      = 0x0100,
   TB_REQUIRE_REALTIMEERRORS   = 0x0200,
   TB_REQUIRE_CURRENT_CONTEXT  = 0x0400,
   TB_REQUIRE_XML_VALIDATION   = 0x0800,
};

// Structure for new toolbar/tool window list def_toolbartab.
// Users should only need to use the define constants
const TBFLAG_ALLOW_CONTROLS_TO_BE_ADDED= 0x0001;
const TBFLAG_SIZEBARS=       0x0002;
const TBFLAG_ALWAYS_ON_TOP=  0x0004;
const TBFLAG_ALLOW_DOCKING=  0x0008;
const TBFLAG_WHEN_DEBUGGER_STARTED_ONLY=   0x0010;
const TBFLAG_WHEN_DEBUGGER_SUPPORTED_ONLY= 0x0020;
const TBFLAG_LIST_WITH_DEBUG_TOOLBARS=     0x0040;
// When tool window is floating, ESC dismisses the tool window like a dialog
const TBFLAG_DISMISS_LIKE_DIALOG=  0x0080;
// Do not enclose sizeable tool window in a panel with title bar caption.
// Used by low-profile tool windows like _tbbufftabs_form, _tbcontext_form.
// Note:
// This flag is not necessary for button bars since they are not sizeable.
const TBFLAG_NO_CAPTION=                   0x0400;
// Do not allow tool window to auto hide
const TBFLAG_NO_AUTOHIDE=                  0x0800;
// Do not allow tool window to tab-linked into a tabgroup
const TBFLAG_NO_TABLINK=                   0x1000;
// MacOS X Unified toolbar -- Mac only -- must test _isMac()
const TBFLAG_UNIFIED_TOOLBAR=              0x2000;

// Initial flags for a new tool bar
const TBFLAG_NEW_TOOLBAR=  (TBFLAG_ALLOW_CONTROLS_TO_BE_ADDED|TBFLAG_ALLOW_DOCKING);

struct _TOOLBAR {
   _str  FormName;     //Name of form for toolbox/button bar
/* Debug Window toolbars
    - Are opened from "View/Debug Windows" menu
    - Are not listed in toolbar list at View/Toolbars unless in
      debug mode.
    - Are not listed from right click on Toolbar context menu unless
      in debug mode.
*/
   int tbflags;

   bool restore_docked;  // Indicates whether to restore this toolbar docked
                            // If this is set, then also set docked_area
   // Below is last show info.
   int show_x;
   int show_y;
   int show_width;
   int show_height;

   // Below are last docked information.


// 8/29/2011-rb : _TOOLBAR::docked_bbside was changed to _TOOLBAR::docked_area in v17.
// Hack so that vusrdefs/vunxdefs from older version can set docked_bbside and not cause Slick-C stack.
#define docked_bbside docked_area

   DockingArea docked_area; //0 indicates last docked position info is unknown.
   int docked_row;    // 1 is first row.  Reinsert at this row.
   int docked_x;     // Reinsert at this x,y.  If toolbar fits
   int docked_y;
   int docked_width;
   int docked_height;

   // Unique identifier used to perform smart redocking.
   // Last tabgroup this tool window was tab-linked into.
   // Only applies to docked tool windows.
   // 0 indicates unknown tabgroup.
   // Note:
   // If the tabgroup is unknown or no longer exists, then the tool
   // window will be docked according to the last docked information.
   int tabgroup;

   // p_ActiveOrder property for tab-linked tool windows. Determines the
   // tab order in a tabgroup that this tool window is displayed. Corresponds
   // roughly to p_ActiveOrder in a tab control. Increasing values indicate
   // the left-to-right ordering in a tab control, but there can be gaps between
   // values.
   //
   // Example:
   // tabOrder=0 indicates this will be the first tab in the tabgroup.
   // Existing tabs are shifted to the right.
   //
   // Example:
   // For tool windows of the same tabgroup, tabOrder=3 indicates this
   // tool window appears to the right of tool windows with a tabOrder <3,
   // and to the left of tool windows with a tabOrder >3. Tabs are shifted
   // to accomodate the ordering.
   //
   // Note:
   // If tabOrder is <0 or greater than the number of tabs in the tabgroup,
   // then the tool window is placed on the end of the tabgroup.
   int tabOrder;

   // Last auto hide/show width
   int auto_width;
   // Last auto hide/show height
   int auto_height;

   // Bitset of ToolbarRequireFlag
   int rflags;
};

/**
 * When on, floating toolbars and tool-windows are hidden when 
 * you switch to another application. When you switch back to 
 * SlickEdit the toolbars/tool-windows are made visible again. 
 * This option is global to all toolbars and tool-windows. 
 * <p>
 * To control this setting, go to "View" > "Toolbars" > "Customize..."
 * and check "Hide when application is inactive."
 *
 * @default false
 * @categories Configuration_Variables
 */
bool def_hidetoolbars;

enum_flags ToolbarOptions {
/**
 * Disable panels with title bar captions for all tool windows.
 */
   TBOPTION_NO_CAPTION           = 0x1,
/**
 * Disable Auto Hide for all tool windows.
 */
   TBOPTION_NO_AUTOHIDE          = 0x2,
/**
 * Use old style tool windows. Features disabled:
 * <li>Panels
 * <li>Auto Hide
 */
   TBOPTION_OLD_STYLE            = (TBOPTION_NO_CAPTION|TBOPTION_NO_AUTOHIDE),
/**
 * When a tool window is closed, and it is tab-linked into a tabgroup,
 * close ALL tool windows in the tabgroup.
 */
   TBOPTION_CLOSE_TABGROUP       = 0x4,
/**
 * When a tool window is Auto Hidden, and it is tab-linked into a tabgroup,
 * DO NOT auto hide all tool windows in the tabgroup.
 */
   TBOPTION_NO_AUTOHIDE_TABGROUP = 0x8,
};

/**
 * Bitwise flags for global tool window options.
 * See TBOPTION_* for more information.
 */
int def_toolbar_options;

// Defined in tbautohide.e
extern bool _tbDockChanMouseInCallback(DockingArea area, _str sid, int pic, _str caption, bool active, bool clicked);
extern bool _tbDockChanMouseOutCallback(DockingArea area, _str sid, int pic, _str caption, bool active, bool precedesMouseIn);


// Orientation of a pallet.
// Used by floating pallets.
// This is important when docking a tool window into a floating pallet that
// requires creation of a new row. TBORIENT_HORIZONTAL gets vertical row breaks,
// TBORIENT_VERTICAL gets horizontal row breaks, TBORIENT_NONE is undetermined
// until the first row break is created.
const TBORIENT_NONE=       0;
const TBORIENT_HORIZONTAL= 1;
const TBORIENT_VERTICAL=   2;

//
// Prototypes
//

/**
 * Load a dock channel on a docking <code>area</code>. 
 *
 * @param index   Resource template index to load.
 * @param dcside  One of DOCKINGAREA_* constants. 
 */
extern void _LoadDockChannel(int index, DockingArea area);

/**
 * Get dock channel wid for a docking <code>area</code>. 
 *
 * @param area  One of DOCKINGAREA_* constants. 
 *
 * @return Dock channel wid for given area or 0 if no dock 
 *         channel.
 */
extern int _GetDockChannel(DockingArea area);

/**
 * Get dock channel area for active window.
 *
 * @return Dock channel area for active window.
 */
extern DockingArea _GetDockChannelArea();

/**
 * Get dock-channel geometry, in pixels, for a docking 
 * <code>area</code>. Geometry of dock-channel is stored in 
 * <code>(x,y)-(width,height)</code> <b>relative to the MDI 
 * frame</b>. 
 *
 * @param area  One of DOCKINGAREA_* constants. 
 * @param x
 * @param y
 * @param width
 * @param height
 */
extern int _GetDockChannelGeometry(DockingArea area, int& x=null, int& y=null, int& width=null, int& height=null);

/**
 * Get dock-palette geometry, in pixels, for a docking 
 * <code>area</code>. Geometry of dock-palette is stored in 
 * <code>(x,y)-(width,height)</code> <b>relative to the MDI 
 * frame</b>. 
 *
 * @param area  One of DOCKINGAREA_* constants. 
 * @param x
 * @param y
 * @param width
 * @param height
 */
extern int _GetDockPaletteGeometry(DockingArea area, int& x=null, int& y=null, int& width=null, int& height=null);

