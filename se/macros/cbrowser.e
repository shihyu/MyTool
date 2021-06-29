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
#pragma option(pedantic,on)
#region Imports
#include "slick.sh"
#include "cbrowser.sh"
#include "tagsdb.sh"
#include "eclipse.sh"
#import "se/tags/TaggingGuard.e"
#import "se/ui/toolwindow.e"
#import "se/ui/twautohide.e"
#import "se/util/MousePointerGuard.e"
#import "se/lang/api/LanguageSettings.e"
#import "backtag.e"
#import "bind.e"
#import "caddmem.e"
#import "codehelputil.e"
#import "context.e"
#import "debuggui.e"
#import "eclipse.e"
#import "files.e"
#import "help.e"
#import "ini.e"
#import "jrefactor.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "menu.e"
#import "pushtag.e"
#import "picture.e"
#import "proctree.e"
#import "projutil.e"
#import "quickrefactor.e"
#import "recmacro.e"
#import "refactor.e"
#import "saveload.e"
#import "search.e"
#import "seldisp.e"
#import "setupext.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagcalls.e"
#import "tagform.e"
#import "taggui.e"
#import "tagrefs.e"
#import "tags.e"
#import "tagwin.e"
#import "tbfilelist.e"
#import "tbcmds.e"
#import "toolbar.e"
#import "tagfind.e"
#import "treeview.e"
#import "util.e"
#import "vc.e"
#import "tbxmloutline.e"
#endregion

using se.lang.api.LanguageSettings;

static const TBCBROWSER_FORM        = "_tbcbrowser_form";
static const CBOPTIONS_FORM         = "_cboptions_form";
static const TBBASECLASSES_FORM     = "_tbbaseclasses_form";
static const TBDERIVEDCLASSES_FORM  = "_tbderivedclasses_form";
static const TBPROPS_FORM           = "_tbsymbol_props_form";
static const TBARGS_FORM            = "_tbsymbol_args_form";
static const TBSYMBOLCALLS_FORM     = "_tbsymbolcalls_form";
static const TBSYMBOLCALLERS_FORM   = "_tbsymbolcallers_form";


//############################################################################

struct CB_TAG_CATEGORY {
   typeless tag_types[];          // either int (SE_TAG_TYPE_*) or
                                  // a string (user defined type)
   int     sequence_number;       // sequence number, for sorting
   SETagFlags flag_mask;          // AND'd with tag's flags
   bool mask_nzero;            // should result be 0 or !=0?
   bool use_package_separator; // use package or class sep here?
   bool level3_inheritance;    // enable inheritance tree at level 3
   bool level4_inheritance;    // enable inheritance tree at level 4
   bool is_container;          // are the items in this ctg containers?
   bool remove_duplicates;     // remove duplicate captions under this category?
};

static struct CB_TAG_CATEGORY gh_cb_categories:[] = {
   // packages and namespaces
   "Programs" => {
      {SE_TAG_TYPE_PROGRAM},
      110, SE_TAG_FLAG_NULL, false, true, false, false, true, false
   },
   "Libraries" => {
      {SE_TAG_TYPE_LIBRARY},
      120, SE_TAG_FLAG_NULL, false, true, false, false, true, false
   },
   CB_packages => {
      {SE_TAG_TYPE_PACKAGE},
      130, SE_TAG_FLAG_NULL, false, true, false, true, true, true
   },
   // class and record types
   "Interfaces" => {
      {SE_TAG_TYPE_INTERFACE},
      210, SE_TAG_FLAG_NULL, false, false, true, true, true, false
   },
   CB_classes => {
      {SE_TAG_TYPE_CLASS},
      220, SE_TAG_FLAG_NULL, false, false, true, true, true, false
   },
   "Structures" => {
      {SE_TAG_TYPE_STRUCT},
      230, SE_TAG_FLAG_NULL, false, false, true, true, true, false
   },
   "Unions" => {
      {SE_TAG_TYPE_UNION},
      240, SE_TAG_FLAG_NULL, false, false, false, false, true, false
   },
   "Groups" => {
      {SE_TAG_TYPE_GROUP, SE_TAG_TYPE_MIXIN},
      250, SE_TAG_FLAG_NULL, false, false, false, false, true, false
   },
   // type definitions
   "Enumerated Types" => {
      {SE_TAG_TYPE_ENUM},
      310, SE_TAG_FLAG_NULL, false, false, false, false, true, false
   },
   "Type Definitions" => {
      {SE_TAG_TYPE_TYPEDEF},
      320, SE_TAG_FLAG_NULL, false, false, false, false, false, false
   },
   // tasks, procedures, functions
   "Tasks" => {
      {SE_TAG_TYPE_TASK},
      410, SE_TAG_FLAG_NULL, false, false, false, false, true, false
   },
   "Global Functions" => {
      {0, SE_TAG_TYPE_PROTO, SE_TAG_TYPE_FUNCTION},
      420, SE_TAG_FLAG_STATIC, false, false, false, false, false, true
   },
   "Static Functions" => {
      {0, /*SE_TAG_TYPE_PROTO,*/ SE_TAG_TYPE_FUNCTION},
      430, SE_TAG_FLAG_STATIC, true, false, false, false, false, false
   },
   "Global Procedures" => {
      {SE_TAG_TYPE_PROC, SE_TAG_TYPE_PROCPROTO},
      440, SE_TAG_FLAG_STATIC, false, false, false, false, false, true
   },
   "Static Procedures" => {
      {SE_TAG_TYPE_PROC /*, SE_TAG_TYPE_PROCPROTO*/},
      450, SE_TAG_FLAG_STATIC, true, false, false, false, false, false
   },
   "Nested Functions" => {
      {SE_TAG_TYPE_SUBPROC, SE_TAG_TYPE_SUBFUNC},
      460, SE_TAG_FLAG_NULL, false, false, false, false, false, false
   },
   // data / storage
   "Global Variables" => {
      {SE_TAG_TYPE_GVAR, SE_TAG_TYPE_VAR},
      510, SE_TAG_FLAG_STATIC, false, false, false, false, false, false
   },
   "Static Variables" => {
      {SE_TAG_TYPE_GVAR},
      520, SE_TAG_FLAG_STATIC, true, false, false, false, false, false
   },
   "Properties" => {
      {SE_TAG_TYPE_PROPERTY},
      530, SE_TAG_FLAG_NULL, false, false, false, false, false, false
   },
   // preprocessing and constants
   "Defines" => {
      {SE_TAG_TYPE_DEFINE, SE_TAG_TYPE_UNDEF},
      610, SE_TAG_FLAG_NULL, false, false, false, false, false, false
   },
   "Constants" => {
      {SE_TAG_TYPE_CONSTANT},
      620, SE_TAG_FLAG_NULL, false, false, false, false, false, false
   },
   // database
   "Database Objects" => {
      {SE_TAG_TYPE_DATABASE},
      710, SE_TAG_FLAG_NULL, false, false, false, false, true, false
   },
   "Database partition" => {
      {SE_TAG_TYPE_PARTITION},
      711, SE_TAG_FLAG_NULL, false, false, false, false, true, false
   },
   "Database Tables" => {
      {SE_TAG_TYPE_TABLE},
      720, SE_TAG_FLAG_NULL, false, false, false, false, true, false
   },
   "Tablespaces" => {
      {SE_TAG_TYPE_TABLESPACE},
      721, SE_TAG_FLAG_NULL, false, false, false, false, true, false
   },
   "Database Views" => {
      {SE_TAG_TYPE_VIEW},
      722, SE_TAG_FLAG_NULL, false, false, false, false, true, false
   },
   "Database Sequences" => {
      {SE_TAG_TYPE_SEQUENCE},
      723, SE_TAG_FLAG_NULL, false, false, false, false, true, false
   },
   "Database Queries" => {
      {SE_TAG_TYPE_QUERY},
      724, SE_TAG_FLAG_NULL, false, false, false, false, true, false
   },
   "Database Indexes" => {
      {SE_TAG_TYPE_INDEX},
      730, SE_TAG_FLAG_NULL, false, false, false, false, true, false
   },
   "Database Clusters" => {
      {SE_TAG_TYPE_CLUSTER},
      731, SE_TAG_FLAG_NULL, false, false, false, false, true, false
   },
   "Database Cursors" => {
      {SE_TAG_TYPE_CURSOR},
      732, SE_TAG_FLAG_NULL, false, false, false, false, true, false
   },
   "Database Triggers" => {
      {SE_TAG_TYPE_TRIGGER},
      733, SE_TAG_FLAG_NULL, false, false, false, false, true, false
   },
   "Database Audit Policies" => {
      {SE_TAG_TYPE_POLICY},
      734, SE_TAG_FLAG_NULL, false, false, false, false, true, false
   },
   "Database Users and Roles" => {
      {SE_TAG_TYPE_USER,SE_TAG_TYPE_ROLE,SE_TAG_TYPE_PROFILE},
      735, SE_TAG_FLAG_NULL, false, false, false, false, true, false
   },
   "Database Editions" => {
      {SE_TAG_TYPE_EDITION},
      736, SE_TAG_FLAG_NULL, false, false, false, false, true, false
   },
   "Files" => {
      {SE_TAG_TYPE_FILE},
      740, SE_TAG_FLAG_NULL, false, false, false, false, false, false
   },
   "Directories" => {
      {SE_TAG_TYPE_DIRECTORY},
      750, SE_TAG_FLAG_NULL, false, false, false, false, false, false
   },
   // graphical interface objects
   "GUI Objects" => {
      {SE_TAG_TYPE_FORM,SE_TAG_TYPE_MENU,SE_TAG_TYPE_CONTROL},
      810, SE_TAG_FLAG_NULL, false, false, false, false, true, false
   },
   "GUI Event Tables" => {
      {SE_TAG_TYPE_EVENTTAB},
      820, SE_TAG_FLAG_NULL, false, false, false, false, true, false
   },
   // include statements, imports, and copy files
   "Imports/Uses" => {
      {SE_TAG_TYPE_IMPORT},
      910, SE_TAG_FLAG_NULL, false, false, false, false, false, true
   },
   CB_includes => {
      {SE_TAG_TYPE_INCLUDE},
      920, SE_TAG_FLAG_NULL, false, false, false, false, false, true
   },
   CB_includesCB => {
      {SE_TAG_TYPE_INCLUDE},
      920, SE_TAG_FLAG_NULL, false, false, false, false, false, true
   },
   "Tags" => {
      {SE_TAG_TYPE_TAG,SE_TAG_TYPE_TAGUSE,SE_TAG_TYPE_ATTRIBUTE}, // XML tags
      930, SE_TAG_FLAG_NULL, false, false, true, true, true, false
   },
   "Targets" => {
      {SE_TAG_TYPE_TARGET}, // ANT targets
      940, SE_TAG_FLAG_NULL, false, false, false, false, false, false
   },
   "Labels" => {
      {SE_TAG_TYPE_LABEL}, // XML ids,HTML anchors
      950, SE_TAG_FLAG_NULL, false, false, false, false, false, false
   },
   // anything else!!!
   CB_misc => {
      {-1},
      1000, SE_TAG_FLAG_NULL, false, false, false, false, false, false
   },
};

/** 
 * Table used to optimize mapping tag types to tag categories.
 */
static _str gh_type_to_categories:[] = null;


/**
 *
 * @return int
 */
int gClassBrowserTimerId=-1;
int gClassBrowserHighlightTimerId=-1;
int gClassBrowserOptionsTimerId=-1;

//////////////////////////////////////////////////////////////////////////////
// Temporary used for expand/collapse operations.  Prior to expanding
// an item, we iterate through the items in the list, deleting the leaves,
// and hashing the captions and tree indexes of the interior nodes into
// this table.  When inserting the new items into the tree, we first check
// if the target caption is in this table, and if so, simply delete it
// from the hash table instead of inserting a new copy into the tree.
// After everything has been inserted, we iterate through what remains in
// this structure and delete them from the tree.
//
//static int gh_captions_index_map:[][];


// Filter-by-types array (1=allow; 0=disallow).
int def_cb_filter_by_types[] = {
   // 0-54 (0 - SE_TAG_TYPE_LASTID
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1,
   // Reserved 55-127
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1,
   // 128-159 (SE_TAG_TYPE_FIRSTUSER - SE_TAG_TYPE_LASTUSER
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1,
   // 160-255 (SE_TAG_TYPE_FIRSTOEM - SE_TAG_TYPE_LASTOEM
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1   // SE_TAG_TYPE_MAXIMUM
};

//////////////////////////////////////////////////////////////////////////////

/**
 * Indicates the maximum depth which to expand the symbol browser's
 * derived classes dialog.  If set to 1 (the default), only the
 * immediate derived classes will be expanded.  If set higher, the
 * entire inheritance tree can be exposed on one operation.
 * 
 * @default 1
 * @categories Configuration_Variables
 */
int def_cb_max_derived_class_depth = 1;

/**
 * Indicates whether or not to show symbols in the preview 
 * window when the mouse is hovered over them in tagging related 
 * tool windows or the file tabs. 
 * 
 * @default true
 * @categories Configuration_Variables
 */
bool def_tag_hover_preview = false;
/**
 * The amount of time to delay before previewing a symbol in
 * the preview tool window when the mouse is hovered over a
 * symbol in a tagging related tool window or the file tabs. 
 * 
 * @default 500 ms
 * @categories Configuration_Variables
 */
int def_tag_hover_delay = 500;

//////////////////////////////////////////////////////////////////////////////
// These globals are used only for comparing values when refreshing
// the symbol browser.  It allows us to compare the new settings with
// the old and avoid expensive refreshes if possible.
//
static  int gi_sort_by_line;        // sort by line number instead of name
static  int gi_sort_float_to_top=1; // float structs, unions to top

//////////////////////////////////////////////////////////////////////////////
// The name of a member/caption to be excluded from filtering so that
// restore_position can force the member to show up in the symbol browser.
// This is allowed only in restore_position.
//
static _str gz_exception_name;

//////////////////////////////////////////////////////////////////////////////
// Global flags indicating that we are in an un-interuptable refresh
// operation and if a refresh is needed for a dormant (hidden) class
// browser.
//
//static int gi_in_refresh=0;
//static int gi_need_refresh=0;
static bool gb_in_twrestore=false;


// Maps bitmap id to text symbols for printing and saving to file
_str gmap_bitmapid_to_symbol:[];

struct TBSYMBOLS_FORM_INFO {
   int m_form_wid;
   int m_i_in_refresh;
   int m_i_need_refresh;
   _str m_z_class_filter;
   _str m_z_member_filter;
};
static TBSYMBOLS_FORM_INFO gtbSymbolsFormList:[];

struct TBBASECLASSES_FORM_INFO {
   int m_form_wid;
};
static TBBASECLASSES_FORM_INFO gtbBaseClassesFormList:[];

struct TBPROPS_FORM_INFO {
   int m_form_wid;
};
static TBPROPS_FORM_INFO gtbPropsFormList:[];

struct TBARGS_FORM_INFO {
   int m_form_wid;
};
static TBARGS_FORM_INFO gtbArgsFormList:[];

static void _init_all_formobj() {
   gtbSymbolsFormList._makeempty();
   gtbBaseClassesFormList._makeempty();
   gtbPropsFormList._makeempty();
   gtbArgsFormList._makeempty();
   int last = _last_window_id();
   int i;
   for (i=1; i<=last; ++i) {
      if (_iswindow_valid(i) && i.p_object == OI_FORM) {
         if (!i.p_edit) {
            if (i.p_name:==TBCBROWSER_FORM) {
               gtbSymbolsFormList:[i].m_form_wid=i;
               gtbSymbolsFormList:[i].m_i_in_refresh= 0;
               gtbSymbolsFormList:[i].m_i_need_refresh= 0;
               _nocheck _control ctl_class_filter_combo_box,ctl_member_filter_combo_box;
               gtbSymbolsFormList:[i].m_z_class_filter= i.ctl_class_filter_combo_box.cb_get_filter();
               gtbSymbolsFormList:[i].m_z_member_filter= i.ctl_member_filter_combo_box.cb_get_filter();
               //wid = i;
               //break;
            } else if (i.p_name:==TBBASECLASSES_FORM || i.p_name==TBDERIVEDCLASSES_FORM) {
               gtbBaseClassesFormList:[i].m_form_wid=i;
            } else if (i.p_name:==TBPROPS_FORM) {
               gtbPropsFormList:[i].m_form_wid=i;
            } else if (i.p_name:==TBARGS_FORM) {
               gtbArgsFormList:[i].m_form_wid=i;
            }
         }
      }
   }
}

void _exit_SymbolsToolWindow() {
   gtbSymbolsFormList._makeempty();
   gtbBaseClassesFormList._makeempty();
   gtbPropsFormList._makeempty();
   gtbArgsFormList._makeempty();
}


//############################################################################
//////////////////////////////////////////////////////////////////////////////
// Called when this module is loaded (before defload).  Used to
// initialize the timer variable and window IDs.
//
definit()
{
   // IF editor is initializing from invocation
   if (arg(1)!='L') {
      gClassBrowserTimerId=-1;
      gClassBrowserHighlightTimerId= -1;
      gClassBrowserOptionsTimerId= -1;
      gz_exception_name="";  // Ok for this to be global
      gb_in_twrestore=false;
      gh_type_to_categories=null;
      gh_type_to_categories=null;
   }
   gtbSymbolsFormList._makeempty();
   gtbBaseClassesFormList._makeempty();
   gtbPropsFormList._makeempty();
   gtbArgsFormList._makeempty();
   _init_all_formobj();
}

//////////////////////////////////////////////////////////////////////////////
// Called when this module is loaded (after definit).  Used to
// correctly initialize the window IDs (if those forms are available),
// and loads the array of pictures used for different tag types.
//
defload()
{
   if( def_cb_filter_by_types._varformat()!=VF_ARRAY || def_cb_filter_by_types._length()<(SE_TAG_TYPE_MAXIMUM+1) ) {
      // Initialize the filter-by-types array
      int i;
      for( i=0;i<=SE_TAG_TYPE_MAXIMUM;++i ) {
         def_cb_filter_by_types[i]=1;
      }
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }

   // project and category open/close pictures
   gh_type_to_categories = null;

   gmap_bitmapid_to_symbol:[_pic_file]       = "||";
   gmap_bitmapid_to_symbol:[_pic_file_d]     = "||";
   gmap_bitmapid_to_symbol:[_pic_file12]     = "||";
   gmap_bitmapid_to_symbol:[_pic_file_d12]   = "||";
   gmap_bitmapid_to_symbol:[_pic_fldclos]    = "[]";
   gmap_bitmapid_to_symbol:[_pic_fldopen]    = "[]";
   gmap_bitmapid_to_symbol:[_pic_func]       = "Fn";
   gmap_bitmapid_to_symbol:[_pic_workspace]  = "[W]";
}
int _tbGetActiveSymbolsForm()
{
   if (!_haveContextTagging()) return 0;
   return tw_find_form(TBCBROWSER_FORM);
}

int ActivateClassBrowser()
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   index := find_index("_activateClassBrowser",PROC_TYPE);
   if( index_callable(index) ) {
      return (call_index(index));
   }
   return activate_cbrowser().p_active_form;
}
int _tbGetActiveBaseClassesForm()
{
   if (!_haveContextTagging()) return 0;
   return tw_find_form(TBBASECLASSES_FORM);
}
int _tbGetActiveDerivedClassesForm()
{
   if (!_haveContextTagging()) return 0;
   return tw_find_form(TBDERIVEDCLASSES_FORM);
}
int _tbGetActiveSymbolPropertiesForm()
{
   if (!_haveContextTagging()) return 0;
   return tw_find_form(TBPROPS_FORM);
}
int _tbGetActiveSymbolArgumentsForm()
{
   if (!_haveContextTagging()) return 0;
   return tw_find_form(TBARGS_FORM);
}

/**
 * Update the picture used by a pic type name.
 *
 * <p>
 * If protected, private, or package access type pictures are not specified,
 * then the public picture will be used for the access type picture.
 * </p>
 *
 * <p>
 * IMPORTANT:<br>
 * Pictures are cached ONCE per editor session, so it is best to call this
 * function in a defload() and build a state file around it.
 * </p>
 *
 * @param type_name              Type name. See CB_BITMAP_INFO.type_name and
 *                               gi_code_type[] in cbrowser.e for a list of
 *                               type names.
 * @param pic_filename_public    Picture to be used for public scope symbols of type type_name.
 * @param pic_filename_protected (optional). Picture to be used for protected scope symbols of type type_name.
 * @param pic_filename_private   (optional). Picture to be used for private scope symbols of type type_name.
 * @param pic_filename_package   (optional). Picture to be used for package scope symbols of type type_name.
 *
 * @see cb_add_user_type()
 */
void cb_update_picture_by_type(_str type_name, _str pic_filename_public, _str pic_filename_protected="", _str pic_filename_private="", _str pic_filename_package="")
{
   type_id := tag_get_type_id(type_name);
   if (type_id <= 0) return;
   filterFlags := tag_type_get_filter(type_id);
   description := tag_type_get_description(type_id);
   tag_register_type(type_id, type_name, 0, description, filterFlags, pic_filename_public);
}

/**
 * Update the picture used by a pic name.
 *
 * <p>
 * If protected, private, or package access type pictures are not specified,
 * then the public picture will be used for the access type picture.
 * </p>
 *
 * <p>
 * The pic name is the name part used to assemble the bitmap filename.
 * For example, the name part 'fun' is used to assemble the bitmaps used
 * to represent functions: _clsfun0.ico, _clsfun1.ico, _clsfun2.ico, _clsfun3.ico,
 * where the numbers 0-3 represent the access type (see CB_access_*).
 * </p>
 *
 * <p>
 * IMPORTANT:<br>
 * Pictures are cached ONCE per editor session, so it is best to call this
 * function in a defload() and build a state file around it.
 * </p>
 *
 * @param pic_name               Pic name. See CB_BITMAP_INFO.name and
 *                               gi_code_type[] in cbrowser.e for a list of
 *                               type names.
 * @param pic_filename_public    Picture to be used for public scope symbols of type type_name.
 * @param pic_filename_protected (optional). Picture to be used for protected scope symbols of type type_name.
 * @param pic_filename_private   (optional). Picture to be used for private scope symbols of type type_name.
 * @param pic_filename_package   (optional). Picture to be used for package scope symbols of type type_name.
 *
 * @see cb_add_user_type()
 */
void cb_update_picture_by_name(_str pic_name, _str pic_filename_public, _str pic_filename_protected="", _str pic_filename_private="", _str pic_filename_package="")
{
   pic_index := _find_or_add_picture(pic_filename_public);
   if (pic_index <= 0) return;
   type_id := tag_get_type_for_bitmap(pic_index);
   tag_get_type(type_id, auto type_name);
   filterFlags := tag_type_get_filter(type_id);
   description := tag_type_get_description(type_id);
   tag_register_type(type_id, type_name, 0, description, filterFlags, pic_filename_public);
}

/**
 * Add a user tag type for use anywhere that uses an icon to represent a
 * tag type (e.g. Symbol browser, Procs tab, etc.).
 *
 * <p>
 * Note:<br>
 * Since only the name part (i.e. no path) of the picture filenames are stored
 * in the names table, the picture files must exists in a path pointed to by
 * the VSLICKBITMAPS environment variable (set in user.cfg.xml).
 * VSLICKBITMAPS is set to %VSROOT%\bitmaps\ if not set
 * explicitly in user.cfg.xml.
 * </p>
 *
 * <p>
 * Important:<br>
 * If the name part (i.e. no path) of the picture filenames do not start with
 * '_' (underscore), then they will be removed from the state file the next
 * time the configuration is saved.
 * </p>
 *
 * @param type_id                Tag type ID in the range SE_TAG_TYPE_OEM-SE_TAG_TYPE_MAXIMUM
 * @param type_name              Type name (e.g. 'customtype').
 * @param is_container           1=type is a container (e.g. struct), 0=not a container (e.g. var)
 * @param description            Description of type.
 * @param text_symbol            Text used when saving to file or printing a tree.
 * @param pic_filename_public    Icon to be used for public scope symbols of type type_name.
 * @param pic_filename_protected Icon to be used for protected scope symbols of type type_name.
 * @param pic_filename_private   Icon to be used for private scope symbols of type type_name.
 * @param pic_filename_package   Icon to be used for package scope symbols of type type_name.
 * @param filterFlags            (optional) VS_TAGFILTER_* 
 *
 * @return 0 on success; otherwise non-zero on error.
 */
int cb_add_user_type(int type_id, _str type_name,
                     bool is_container, _str description, _str text_symbol,
                     _str pic_filename_public, _str pic_filename_protected="",
                     _str pic_filename_private="", _str pic_filename_package="",
                     SETagFilterFlags filter_flags = SE_TAG_FILTER_ANYTHING)

{
   int i_access;
   int i_type;
   int status;
   int result;
   _str pics_not_loaded;
   _str access_descr;
   _str filename;
   _str msg;

   if( type_id<SE_TAG_TYPE_FIRSTOEM || type_id>SE_TAG_TYPE_LASTOEM ) {
      msg="Invalid type ID";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return(1);
   }
   if( type_name=="" ) {
      msg="Invalid type name";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return(1);
   }

   // If type_name already exists, then replace it
   existing_type_id := tag_get_type_id(type_name);
   if (existing_type_id > 0) {
      type_id = existing_type_id;
   }

   // Do not allow us to add before CB_type_LAST
   if( type_id != SE_TAG_TYPE_NULL && type_id <= SE_TAG_TYPE_LASTID ) {
      msg="Type '"type_name"' already exists in pre-defined tag types";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return(1);
   }
   // At this point i_type is pointing to the next available entry in gi_code_type
   // array. If we found an already-existing entry to replace, then i_type points
   // to it.

   // Update gi_code_type array
   pic_basename := _strip_filename(pic_filename_public, 'E');
   _maybe_strip(pic_basename, '0');
   status = tag_register_type(type_id, type_name, (int)is_container, description, filter_flags, pic_basename);
   return(status);
}

/**
 * Add type ID type_id to category category_name in symbol browser. If
 * category does not exist, it is created.
 *
 * @param category_name      Name of category (e.g. "Structures")
 * @param type_id            Type ID in range SE_TAG_TYPE_OEM - SE_TAG_TYPE_MAXIMUM
 * @param is_container       true=container type (e.g. struct), false=not a container
 * @param add_after_category If category_name does not exist, then it will be added after add_after_category 
 * @param reset_category     Remove any previous specifications for this category
 *
 * @return 0 on success, otherwise non-zero.
 */
int cb_add_to_category(_str category_name,
                       SETagType type_id,
                       bool is_container=false,
                       _str add_after_category="", 
                       bool reset_category=false)
{
   CB_TAG_CATEGORY *p;
   _str msg;

   if( category_name=="" ) {
      msg="Invalid category name";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return(1);
   }
   if( type_id<SE_TAG_TYPE_FIRSTOEM || type_id>SE_TAG_TYPE_LASTOEM ) {
      msg="Invalid type ID";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return(1);
   }

   p=gh_cb_categories._indexin(category_name);
   if( p && !reset_category ) {
      // Adding to existing category
      p->tag_types[p->tag_types._length()]=type_id;
   } else if (p && reset_category && type_id == 0) {
      // remove this category entirely
      gh_cb_categories._deleteel(category_name);
      gh_type_to_categories = null;
   } else {
      CB_TAG_CATEGORY ctc;
      ctc._makeempty();
      ctc.tag_types[ctc.tag_types._length()]=type_id;
      ctc.flag_mask=SE_TAG_FLAG_NULL;
      ctc.mask_nzero=false;
      ctc.use_package_separator=false;
      ctc.level3_inheritance=true;
      ctc.level4_inheritance=true;
      ctc.is_container=is_container;
      ctc.remove_duplicates=true;
      // Calculate sequence number
      sequence_number := 999;   // Sanity
      if( add_after_category!="" ) {
         p=gh_cb_categories._indexin(add_after_category);
         if( !p ) {
            msg='No category "'add_after_category'" to add after.';
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            return(1);
         }
      } else {
         p=gh_cb_categories._indexin(CB_misc);
         if( p ) {
            // Add before "Miscellaneous" in order
            sequence_number=p->sequence_number-1;
         }
      }
      ctc.sequence_number=sequence_number;
      gh_cb_categories:[category_name]=ctc;
      gh_type_to_categories = null;
   }
   // Flag the editor that the configuration has changed
   _config_modify_flags(CFGMODIFY_DEFVAR);

   return(0);
}

//############################################################################
// function for selection bitmap given tag type and flags
// This function is not normally called for 'standard' tag types,
// icon selection for those is done in the tagsdb DLL, which delagates
// to this function if it cannot resolve the tag type.
//
int cb_select_icon(_str tag_type, SETagFlags tag_flags)
{
   switch (tag_type) {
   case "macro":
      return CB_type_define;
   case "dd":
   case "db":
   case "dw":
      return CB_type_data;
   case "equ":
      return CB_type_constant;
   default:
      int index;
      index=find_index("cb_user_select_icon",PROC_TYPE);
      if( index ) {
         return call_index(tag_type,tag_flags,index);
      }
      break;
   }
   return CB_type_miscellaneous;
}


//############################################################################

/**
 * Kill the existing symbol browser update timer
 */
static void cb_kill_timer()
{
   //say("cb_kill_timer*************************");
   if (gClassBrowserTimerId != -1) {
      _kill_timer(gClassBrowserTimerId);
      gClassBrowserTimerId=-1;
   }
}

/**
 * Start the symbol browser update timer
 */
static void cb_start_timer(int form_wid,typeless timer_cb, int index=-1, int timer_delay=0)
{
   if (gtbPropsFormList._length()       || 
       gtbArgsFormList._length()        || 
       gtbBaseClassesFormList._length() || 
       _GetTagwinWID(false)             || 
       _GetReferencesWID(false)) {
      // kill the existing timer and start a new one
      if (gClassBrowserTimerId != -1) {
         cb_kill_timer();
      }
      if (timer_delay <= 0) {
         timer_delay=max(CB_TIMER_DELAY_MS,_default_option(VSOPTION_DOUBLE_CLICK_TIME));
      }
      gClassBrowserTimerId=_set_timer(timer_delay, timer_cb, form_wid" "index);
   }
}

/**
 * Kill the existing symbol browser highlight timer
 */
static void cb_kill_timer_highlight()
{
   //say("cb_kill_timer_highlight*************************");
   if (gClassBrowserHighlightTimerId != -1) {
      _kill_timer(gClassBrowserHighlightTimerId);
      gClassBrowserHighlightTimerId=-1;
   }
}

/**
 * Start the symbol browser highlight timer
 */
static void cb_start_timer_highlight(int form_wid,typeless timer_cb, int index=-1, int timer_delay=0)
{
   if (gtbPropsFormList._length()       || 
       gtbArgsFormList._length()        || 
       gtbBaseClassesFormList._length() || 
       _GetTagwinWID(false)             || 
       _GetReferencesWID(false)) {
      // kill the existing timer and start a new one
      if (gClassBrowserHighlightTimerId != -1) {
         cb_kill_timer_highlight();
      }
      if (timer_delay <= 0) {
         timer_delay=max(CB_TIMER_DELAY_MS,_default_option(VSOPTION_DOUBLE_CLICK_TIME));
      }
      gClassBrowserHighlightTimerId=_set_timer(timer_delay, timer_cb, form_wid" "index);
   }
}

/**
 * Kill the existing symbol browser options update timer
 */
static void cb_kill_timer_options()
{
   //say("cb_kill_timer_options*************************");
   if (gClassBrowserOptionsTimerId != -1) {
      _kill_timer(gClassBrowserOptionsTimerId);
      gClassBrowserOptionsTimerId=-1;
   }
}

/**
 * Start the symbol browser options update timer
 */
static void cb_start_timer_options(int form_wid,typeless timer_cb, int timer_delay=0)
{
   if (timer_delay <= 0) {
      timer_delay=max(CB_TIMER_DELAY_MS,_default_option(VSOPTION_DOUBLE_CLICK_TIME));
   }
   // kill the existing timer and start a new one
   if (gClassBrowserOptionsTimerId != -1) {
      cb_kill_timer_options();
   }
   gClassBrowserOptionsTimerId = _set_timer(timer_delay, timer_cb, form_wid);
}


//############################################################################
//////////////////////////////////////////////////////////////////////////////
// Event table for the _tbcbrowser_form (which the symbol browser is in).
//
defeventtab _tbcbrowser_form.ctl_class_tree_view;

//////////////////////////////////////////////////////////////////////////////
// Keyboard shortcuts for all symbol browser menu options
//
def "A-g"=cb_goto_proc;
def "A-d"=cb_goto_decl;
def "A-l"=cb_sortby_line;
def "A-t"=cb_sortby_name;
def "A-o"=cb_options;
def "A-f"=cb_find;
def "A-i"=gui_make_tags;
def "A-2"=cb_expand_twolevels;
def "A-e"=cb_expand_children;
def "A-c"=cb_collapse;
def "A-s"=cb_crunch;
def "A-h"=cb_parents;
def "A-p"=cb_props;
def "A-a"=cb_args;
def "A-r"=cb_references;
def "A-u"=cb_calltree;
def "A-t"=cb_caller_tree;

//############################################################################
//////////////////////////////////////////////////////////////////////////////
// Event table for the _tbcbrowser_form (which the symbol browser is in).
//
defeventtab _tbcbrowser_form;

_tbcbrowser_form."F12"()
{
   if (isEclipsePlugin()) {
      eclipse_activate_editor();
   } else if (def_keys == "eclipse-keys") {
      activate_editor();
   }
}

_tbcbrowser_form."C-S-PAD-SLASH"()
{
   if (isEclipsePlugin() || def_keys == "eclipse-keys") {
      cb_crunch();
   }
   
}

_tbcbrowser_form."C-M"()
{
   if (isEclipsePlugin()) {
      eclipse_maximize_part();
   }
}

//////////////////////////////////////////////////////////////////////////////
// Add keyboard bindings to menu items
//
static void menu_add_bindings(int menu_handle, _str cmd, _str cmd2, _str args)
{
   _str bindings = _mdi.p_child.where_is(cmd,2);
   if (bindings=="" && cmd2!="") {
      bindings = _mdi.p_child.where_is(cmd2,2);
   }
   int flags;
   _str caption;
   if (bindings != "") {
      _menu_get_state(menu_handle, cmd:+args, flags, 'M', caption);
      parse caption with caption "\t" .;
      _menu_set_state(menu_handle, cmd:+args, flags, 'M', caption "\t" bindings);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Hide the given item(s)
//
static void menu_hide_item(int menu_handle, _str cat)
{
   int mh,mpos;
   int status=_menu_find(menu_handle,cat,mh,mpos,'C');
   if (!status) {
     _menu_delete(mh,mpos);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Handle right-button released event, in order to display pop-up menu
// for the symbol browser.  Also responsible for graying inactive items
// depending where we are in the symbol browser tree.
//
void ctl_class_tree_view.rbutton_up()
{
   // kill the refresh timer, prevents delays before the menu comes
   // while the refreshes are finishing up.
   cb_kill_timer();
   cb_kill_timer_highlight();
   cb_kill_timer_options();

   // get the menu form
   int index=find_index("_cbrowse_menu",oi2type(OI_MENU));
   if (!index) {
      return;
   }
   int menu_handle=p_active_form._menu_load(index,'P');
   cbWid := _tbGetActiveSymbolsForm();
   //int cbWid = ActivateClassBrowser();
   // blow away parts of the menu, depending on where
   // it is being shown from
   //if (isEclipsePlugin()) {
   //   gtbcbrowser_wid = p_active_form;
   //}
   if (_get_focus() == cbWid.ctl_class_tree_view) {
      struct VS_TAG_BROWSE_INFO cm;
      k := cbWid.ctl_class_tree_view._TreeCurIndex();
      // If we right clicked on a class.
      if (cbWid.ctl_class_tree_view.get_user_tag_info(k, cm, false)) {
         lang := cm.language;
         if (lang == "") lang = _Filename2LangId(cm.file_name);
         qrIndex := _menu_find_loaded_menu_category(menu_handle, "quick_refactoring", auto qrMenu);
         if (cm.type_name=="class") {
            if (!_LanguageInheritsFrom("m", lang)) {
               if (_LanguageInheritsFrom("c", lang)) {
                  _menu_insert(qrMenu,-1,MF_ENABLED,
                               "Add Member Function...","cb_add_member 0","",
                               "help Symbols tool window",
                               "Adds a member function to the this class");
                  _menu_insert(qrMenu,-1,MF_ENABLED,
                               "Add Member Variable...","cb_add_member 1","",
                               "help Symbols tool window",
                               "Adds a member function to the this class");
               }
               if ( _LanguageInheritsFrom("c", lang) || 
                    _LanguageInheritsFrom("e", lang) ) {
                  // This DOES NOT work for works for all extensions with a
                  // generate_match_signature function.  Some special code in override_method
                  // is needed.
                  //int gen_index = find_index("_"ext"_generate_match_signature",PROC_TYPE);
                  //if (gen_index) {
                  int status=tag_read_db(cm.tag_database);
                  if (status >= 0) {
                     _str parents = cm.class_parents;
                     if (parents == "") {
                        tag_get_inheritance(cm.qualified_name,parents);
                     }
                     if (parents!="") {
                        _menu_insert(qrMenu,-1,MF_ENABLED,
                                     "Override Virtual Function...","cb_override_method","",
                                     "help Symbols tool window",
                                     "Adds a function which overrides a base class virtual method");
                     }
                  }
                  //}
               } else if ( _LanguageInheritsFrom("java", lang) || 
                           _LanguageInheritsFrom("cs",   lang) ) {
                  _menu_insert(qrMenu,-1,MF_ENABLED,
                               "Override Method...","cb_override_method","",
                               "help Symbols tool window",
                               "Adds a method which overrides a base class method");
               }
            }
         }
         if (tag_tree_type_is_func(cm.type_name)) {
            if ( _LanguageInheritsFrom("c",    lang) || 
                 _LanguageInheritsFrom("cs",   lang) || 
                 _LanguageInheritsFrom("java", lang) || 
                 _LanguageInheritsFrom("e",    lang) ) {
               _menu_insert(qrMenu,-1,MF_ENABLED,
                            "Delete","cb_delete","",
                            "help Symbols tool window",
                            "Deletes the method");
            }
         }
         if (isEclipsePlugin() && lang=="java") {
            menu_hide_item(menu_handle, "set_breakpoint");
         }
         if (cm.tag_database == "") {
            menu_hide_item(menu_handle, "rebuildtagfile");
         }
      }
   } else if ((p_active_form.p_name == TBBASECLASSES_FORM) ||
              (p_active_form.p_name == TBDERIVEDCLASSES_FORM) ||
              (p_active_form.p_name == TBPROPS_FORM) || 
              (p_active_form.p_name == TBARGS_FORM)  || 
              (p_active_form.p_name == CBOPTIONS_FORM)) {
      menu_hide_item(menu_handle, "expand");
      menu_hide_item(menu_handle, "expand2");
      menu_hide_item(menu_handle, "collapseothers");
      menu_hide_item(menu_handle, "collapseall");
      menu_hide_item(menu_handle, "derived");
      menu_hide_item(menu_handle, "parents");
      menu_hide_item(menu_handle, "options");
      menu_hide_item(menu_handle, "filters");
      menu_hide_item(menu_handle, "sortby");
      menu_hide_item(menu_handle, "findtag");
      menu_hide_item(menu_handle, "cpp_refactoring");
      menu_hide_item(menu_handle, "quick_refactoring");
      menu_hide_item(menu_handle, "organize_imports");
      menu_hide_item(menu_handle, "set_breakpoint");
      menu_hide_item(menu_handle, "expandtwolevels");
   } else {
      // don't know where we are
      return;
   }

   // hide C/C++ refactoring if it is disabled
   if (def_disable_cpp_refactoring || !_haveRefactoring()) {
      menu_hide_item(menu_handle, "cpp_refactoring");
   }

   // get the id of the symbol browser form
   _nocheck _control ctl_class_tree_view;
   _nocheck _control ctl_class_filter_label;
   _nocheck _control ctl_member_filter_label;
   f := _tbGetActiveSymbolsForm();
   if (!f) return;

   // get position in tree control
   i := f.ctl_class_tree_view._TreeCurIndex();
   int depth = (i<0)? 0 : f.ctl_class_tree_view._TreeGetDepth(i);

   // If a tag is not selected, disable tag operations.
   if ((depth <= 2) || (i == TREE_ROOT_INDEX)) {
      _menu_set_state(menu_handle, "properties", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "arguments", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "references", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "calltree", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "callertree", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "derived", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "parents", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "declaration", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "definition", MF_GRAYED, 'C');
   }

   // If at first level below categories, disable inheritance
   // unless we are under structs, classes, or interfaces.
   int p,g;
   caption := "";
   if (depth == 3) {
      p = f.ctl_class_tree_view._TreeGetParentIndex(i);
      caption = f.ctl_class_tree_view._TreeGetCaption(p);
      parse caption with caption CB_delimiter .;
      CB_TAG_CATEGORY *ctg = gh_cb_categories._indexin(caption);
      if (!ctg || !ctg->level3_inheritance) {
         _menu_set_state(menu_handle, "derived", MF_GRAYED, 'C');
         _menu_set_state(menu_handle, "parents", MF_GRAYED, 'C');
      }
   }

   // If at a second level below categories, disable inheritance unless
   // we are under structs, classes, interfaces, packages, programs, or libraries.
   if (depth == 4) {
      p = f.ctl_class_tree_view._TreeGetParentIndex(i);
      g = f.ctl_class_tree_view._TreeGetParentIndex(p);
      caption = f.ctl_class_tree_view._TreeGetCaption(g);
      parse caption with caption CB_delimiter .;
      CB_TAG_CATEGORY *ctg = gh_cb_categories._indexin(caption);
      if (!ctg || !ctg->level4_inheritance) {
         _menu_set_state(menu_handle, "derived", MF_GRAYED, 'C');
         _menu_set_state(menu_handle, "parents", MF_GRAYED, 'C');
      }
   }

   // Gray goto-proc (goto_decl) if the current item is not a function
   show_children := 0;
   caption = "";
   if (i>=0) {
      f.ctl_class_tree_view._TreeGetInfo(i, show_children);
      caption = f.ctl_class_tree_view._TreeGetCaption(i);
   }
   if (show_children != TREE_NODE_LEAF || pos("(", caption)==0) {
      _menu_set_state(menu_handle, "declaration", MF_GRAYED, 'C');
   }

   // stuff the key shortcut into the memu item for cb_find
   menu_add_bindings(menu_handle, "cb_goto_decl", "", "");
   menu_add_bindings(menu_handle, "cb_goto_proc", "", "");
   menu_add_bindings(menu_handle, "cb_find", "cf", " -");
   menu_add_bindings(menu_handle, "gui_make_tags", "", "");
   menu_add_bindings(menu_handle, "cb_parents", "", "");
   menu_add_bindings(menu_handle, "cb_crunch", "", "");
   menu_add_bindings(menu_handle, "cb_props", "", "");
   menu_add_bindings(menu_handle, "cb_args", "", "");
   menu_add_bindings(menu_handle, "cb_references", "", "");
   menu_add_bindings(menu_handle, "cb_calltree", "", "");
   menu_add_bindings(menu_handle, "cb_callertree", "", "");
   menu_add_bindings(menu_handle, "cb_options", "", "");

   // set check marks depending on state of gi_sort_by_line
   if (gi_sort_by_line) {
      _menu_set_state(menu_handle, "sortline", MF_CHECKED, 'C');
   } else {
      _menu_set_state(menu_handle, "sortname", MF_CHECKED, 'C');
   }
   if (gi_sort_float_to_top) {
      _menu_set_state(menu_handle, "sortfloat", MF_CHECKED, 'C');
   }

   // set check marks depending on presence/absence of filters
   if (f.ctl_class_filter_label.p_visible) {
      _menu_set_state(menu_handle,"class",MF_CHECKED,'C');
   }
   if (f.ctl_member_filter_label.p_visible) {
      _menu_set_state(menu_handle,"member",MF_CHECKED,'C');
   }

   // populate refactoring submenu
   struct VS_TAG_BROWSE_INFO refcm;
   if(f.ctl_class_tree_view.get_user_tag_info(i, refcm, false)) {
      addCPPRefactoringMenuItems(menu_handle, "cb", refcm);
      addQuickRefactoringMenuItems(menu_handle, "cb", refcm);
   } else {
      addCPPRefactoringMenuItems(menu_handle, "cb", null);
      addQuickRefactoringMenuItems(menu_handle, "cb", null);
   }

   // Show the menu.
   int x=mou_last_x('M')-100;
   int y=mou_last_y('M')-100;
   _lxy2dxy(p_scale_mode,x,y);
   _map_xy(p_window_id,0,x,y,SM_PIXEL);
   _KillToolButtonTimer();
   call_list("_on_popup2_",translate("_cbrowse_menu","_","-"),menu_handle);
   _menu_show(menu_handle,VPM_LEFTALIGN|VPM_RIGHTBUTTON,x,y);
   _menu_destroy(menu_handle);
}

/**
 * Get the search scope options for the references tool window. 
 *  
 * @return Returns on of the following constants: 
 *         <ul> 
 *         <li>VS_TAG_FIND_TYPE_EVERYWHERE
 *         <li>VS_TAG_FIND_TYPE_BUFFER_ONLY
 *         <li>VS_TAG_FIND_TYPE_PROJECT_ONLY
 *         <li>VS_TAG_FIND_TYPE_WORKSPACE_ONLY
 *         </ul>
 *  
 * @categories Tagging_Functions 
 */
static _str _GetCBrowserLookinOption()
{
   window_id := _GetCBrowserWID();
   if (window_id) {
      control_id := window_id._find_control("ctllookin");
      if (control_id) {
         if ((control_id.p_object == OI_COMBO_BOX) || (control_id.p_object == OI_TEXT_BOX)) {
            return control_id.p_text;
         }
      }
   }
   return "";
}

/**
 * Update the list of tag files if look-in scope changes.
 */
void ctllookin.on_change(int reason)
{
   if (!p_enabled) return;
   cb_kill_timer();
   cb_kill_timer_highlight();
   cb_kill_timer_options();
   switch (reason) {
   case CHANGE_SELECTED:
   case CHANGE_CLINE:
      ctl_class_tree_view.refresh_tagfiles();
      break;
   }
}

//////////////////////////////////////////////////////////////////////////////
// Toggle display of class filter
//
_command cb_filterby_menu(_str option="") name_info(','VSARG2_CMDLINE|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Symbols tool window");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   if (option=="") {
      return "";
   }

   _nocheck _control ctl_class_filter_label;
   _nocheck _control ctl_member_filter_label;
   f := _tbGetActiveSymbolsForm();
   if (!f) {
      return "";
   }

   // based on menu selection
   switch (option) {
   case "class":
      f.ctl_class_filter_label.p_user = (f.ctl_class_filter_label.p_user)? 0:1;
      break;
   case "member":
      f.ctl_member_filter_label.p_user = (f.ctl_member_filter_label.p_user)? 0:1;
      break;
   case "options":
      return cb_options();
   default:
      return "";
   }

   f.checkShowHideControls();
   return cb_refresh();
}

//////////////////////////////////////////////////////////////////////////////
// Reposition the controls depending on whether they want the member
// and class filters visible or not.
//
// Expects p_window_id to be the form containing the symbol browser
// and all symbol browser controls.
//
static void checkShowHideControls()
{
   _nocheck _control ctl_class_filter_combo_box;
   _nocheck _control ctl_member_filter_combo_box;
   _nocheck _control ctl_class_filter_label;
   _nocheck _control ctl_member_filter_label;
   _nocheck _control ctl_class_tree_view;
   _nocheck _control ctl_filter_check_box;

   // vertical margin
   int border_height = ctl_filter_check_box.p_y;

   // grab bit flags
   int show_class_filter  = ctl_class_filter_label.p_user;
   int show_member_filter = ctl_member_filter_label.p_user;

   if (show_class_filter != ctl_class_filter_combo_box.p_visible ||
       show_member_filter != ctl_member_filter_combo_box.p_visible) {

      // hide/show class filter
      ctl_class_filter_combo_box.p_visible = (show_class_filter != 0);
      ctl_class_filter_label.p_visible     = (show_class_filter != 0);

      // compute initial y position for class tree view
      int label_height = ctl_class_filter_combo_box.p_height + border_height;
      int tree_view_y = ctl_class_filter_combo_box.p_y;
      if (show_class_filter) {
         tree_view_y += label_height;
      }

      // hide/show member filter
      ctl_member_filter_combo_box.p_visible = (show_member_filter != 0);
      ctl_member_filter_label.p_visible     = (show_member_filter != 0);

      // position the member filter, and maybe adjust position of tree view
      ctl_member_filter_combo_box.p_y = tree_view_y;
      ctl_member_filter_label.p_y     = tree_view_y;
      if (show_member_filter) {
         tree_view_y += label_height;
      }

      resizeSymbolsBrowser();
   }
}

//////////////////////////////////////////////////////////////////////////////
// Save the state of the class tree.  This is a recursive function whose
// output is a string (open_cats) which represents the set of open
// non-leaf nodes in the tree.  The syntax of the output string is:
//
//    c_1{s}c_2{s}...c_n{s}
//
// where 'c_i' is the caption of the tree item (pre-tab) and 's' is any
// string of the same form.
//
// p_window_id must be the symbol browser tree control.
//
static void save_class_tree_view(int i, _str parent, _str &open_cats)
{
   // search for member
   child := _TreeGetFirstChildIndex(i);
   while (child > 0) {
      int show_children;
      _TreeGetInfo(child, show_children);
      if (show_children == TREE_NODE_EXPANDED) {
         caption := _TreeGetCaption(child);
         parse caption with caption "\t" .;
         parse caption with caption CB_delimiter .;
         open_cats :+= caption "{";
         save_class_tree_view(child, caption, open_cats);
         open_cats :+= "}";
      }
      child = _TreeGetNextSiblingIndex(child);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Compare the caption at tree index 'i' with the given caption string.
// Handles special cases of tabs and PARTIAL LISTs for categories.
// p_window_id must be the symbol browser tree control.
//
static int caption_is_equal(int i, _str &label)
{
   caption := label_no_paren := "";
   parse _TreeGetCaption(i) with caption "\t" .;
   parse caption with caption CB_delimiter .;
   parse caption with caption "(" .;
   // DJB 11-15-2005
   // remove template parameter signatures
   if (pos(">",caption) > pos("<",caption) && !pos("<",label)) {
      parse caption with caption "<" .;
   }
   parse label with label_no_paren "(" .;
   return (caption :== label_no_paren)? 1:0;
}

//////////////////////////////////////////////////////////////////////////////
// Remove entries from open categories string until synchronized on
// a closing brace.  This function is nearly identical in structure
// to restore_class_tree_view(), except that it does not interact with
// the tree at all.
//
static void strip_restore_error(_str &open_cats)
{
   // loop until we hit the end of the list
   label := "";
   while (pos("}", open_cats) != 1) {
      parse open_cats with label "{" open_cats;
      if (label == "") {
         return;
      }
      strip_restore_error(open_cats);
   }

   // clean up (remove trailing brace)
   if (pos("}", open_cats) == 1) {
     open_cats = substr(open_cats, 2);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Restores the state of the class tree.  This is a recursive function
// whose input (open_cats) is of the form described above in
// save_class_tree_view.  It parses the input string and opens
// tree nodes with matching headlines, causing them to be expanded
// in accordance with the current filtering options.
// p_window_id must be the symbol browser tree control.
//
static void restore_class_tree_view(int i, _str &open_cats)
{
   //say("restore_class_tree_view: i="i" open_cats="open_cats);
   child := _TreeGetFirstChildIndex(i);

   // loop until we hit the end of the list
   label := "";
   while (pos("}", open_cats) != 1) {

      // get the item label to search for
      parse open_cats with label "{" open_cats;
      if (label == "") {
         return;
      }

      // search each child node (including the current child)
      while (child > 0) {
         show_children := 0;
         _TreeGetInfo(child, show_children);
         if (show_children==TREE_NODE_COLLAPSED && caption_is_equal(child,label)) {
            //say("Found: "label" index="child);
            call_event(CHANGE_EXPANDED,child,p_window_id,ON_CHANGE,'w');
            _TreeSetInfo(child, TREE_NODE_EXPANDED);
            restore_class_tree_view(child, open_cats);
            child = _TreeGetNextSiblingIndex(child);
            break;
         }
         child = _TreeGetNextSiblingIndex(child);
      }

      if (child <= 0 && open_cats != "" && pos("}", open_cats) != 1) {
         strip_restore_error(open_cats);
         child = _TreeGetFirstChildIndex(i);
      }
   }

   // clean up (remove trailing brace)
   if (pos("}", open_cats) == 1) {
     open_cats = substr(open_cats, 2);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Restores the position of the currently selected item in the
// symbol browser tree view.  The input is the form window ID and
// a comma separated list of captions.  This function may also
// be used to set the position of the symbol browser.  This is how
// cb_find (Find Tag) works.
//
// This function recursively tries all tree paths that match until
// it finds one that matches.  On exit it will return either
// -1, indicating that the item was not found, or the tree index
// of the item.  It is the caller's responsibility to set the current
// index in the tree control after calling this function.
//
// p_window_id must be the symbol browser tree control.
//
static int restore_position(int index, _str path)
{
   // boundary case, return if this is successful
   if (path=="") {
      //say("restore_position: empty path");
      return index;
   }

   // grab the first item off of the path
   //say('entering with--'path);
   label := "";
   parse path with label "," path;

   // get first child of tree node 'index'
   _str caption;
   int child, found_at;
   found_at = -1;
   child = _TreeGetFirstChildIndex(index);
   while (child > 0) {
      if (caption_is_equal(child, label)) {
         found_at = child;
         show_children := 0;
         _TreeGetInfo(child, show_children);
         if (show_children == TREE_NODE_COLLAPSED && path != "") {
            //say(label "=========" path);
            parse path with caption "," .;
            parse caption with gz_exception_name "(" .;
            call_event(CHANGE_EXPANDED,child,p_window_id,ON_CHANGE,'w');
            gz_exception_name = "";
         }
         int result = restore_position(child, path);
         if (result >= 0) {
            //say("expanding--"label);
            if (show_children == TREE_NODE_COLLAPSED && path != "") {
               _TreeSetInfo(child, TREE_NODE_EXPANDED);
            }
            return result;
         }
      }
      child = _TreeGetNextSiblingIndex(child);
   }

   // maybe we had a category that broke into sections?
   int depth = _TreeGetDepth(index);
   if (depth == 2) {
      first_char := substr(label, 1, 1) ":";
      child = _TreeSearch(index, first_char, 'PI');
      if (child > 0) {
         found_at = child;
         path = label :+ ((path=="")? "" : ",") :+ path;
         int show_children;
         _TreeGetInfo(child, show_children);
         call_event(CHANGE_EXPANDED,child,p_window_id,ON_CHANGE,'w');
         int result = restore_position(child, path);
         if (result >= 0) {
            //say("letter expanding--"label);
            if (show_children == TREE_NODE_COLLAPSED && path != "") {
               _TreeSetInfo(child, TREE_NODE_EXPANDED);
            }
            return result;
         }
      }
   }


   // bail out if we don't find a matching caption
   //say("restore_position: found_at="found_at);
   return found_at;
}

//////////////////////////////////////////////////////////////////////////////
// Save the current position of the symbol browser as a comma-separated
// list of captions appropriate for use with restore_position (above).
// p_window_id must be the symbol browser tree control.
//
static void save_position(_str &curr_path)
{
   // save the current position
   curr_path = "";
   child := _TreeCurIndex();
   while (child > 0) {
      caption := _TreeGetCaption(child);
      parse caption with caption "\t" .;
      parse caption with caption CB_delimiter .;
      if (curr_path != "") {
         curr_path = caption "," curr_path;
      } else {
         curr_path = caption;
      }
      child = _TreeGetParentIndex(child);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Refresh the class tree view, starting at the given 'index' and doing
// everything below.  This is a recursive function, calling itself to
// refresh non-leaf children.  The function assumes that the tree index
// passed in is a tree index of a non-leaf tree node.
// p_window_id must be the symbol browser tree control.
//
static void refresh_class_tree_view(int index)
{
   // expand/close this tree item
   call_event(CHANGE_EXPANDED,index,p_window_id,ON_CHANGE,'w');

   // recursively refresh our children
   child := _TreeGetFirstChildIndex(index);
   while (child > 0) {
      int show_children;
      _TreeGetInfo(child, show_children);
      if (show_children==TREE_NODE_EXPANDED) {
         refresh_class_tree_view(child);
      } else if (show_children==TREE_NODE_COLLAPSED) {
         _TreeDelete(child, 'c');
      }
      child = _TreeGetNextSiblingIndex(child);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Refresh the inheritance and tag properties dialogs if they are up.
// p_window_id must be the symbol browser tree control.
//
static void refresh_dialog_views()
{
   cbrowser_form := p_active_form;
   // get the details about the current selection
   currIndex := _TreeCurIndex();
   if (currIndex <= 0) {
      return;
   }

   show_children := 0;
   _TreeGetInfo(currIndex, show_children);
   if (!get_user_tag_info(currIndex, auto cm, false)) {
      return;
   }

   // refresh the properties toolbar
   cbrowser_form.cb_refresh_property_view(cm);

   // refresh the arguments toolbar
   cbrowser_form.cb_refresh_arguments_view(cm);

   // get the information about the containing class
   if (show_children == TREE_NODE_LEAF) {
      parentIndex := _TreeGetParentIndex(currIndex);
      if (!get_user_tag_info(parentIndex, cm, false)) {
         return;
      }
   }
   cb_refresh_inheritance_view(cbrowser_form,cm,null,true);
}

//////////////////////////////////////////////////////////////////////////////
// Recursive function used by _TagFileModified_cbrowser (below) that
// handles updating items that were inherited from classes in another
// tag file that was modified.
// p_window_id must be the symbol browser tree control.
//
static void refresh_inherited_tags(int index, int prj_key)
{
   child := _TreeGetFirstChildIndex(index);
   while (child > 0) {
      typeless v = _TreeGetUserInfo(child);
      if (v._varformat()==VF_LSTR && isinteger(v)) {
         if ((v intdiv (CB_MAX_LINE_NUMBER*CB_MAX_FILE_NUMBER)) == prj_key) {
            refresh_class_tree_view(index);
            return;
         }
      }
      int show_children;
      _TreeGetInfo(child, show_children);
      if (show_children==TREE_NODE_EXPANDED) {
         refresh_inherited_tags(child, prj_key);
      } else if (show_children==TREE_NODE_COLLAPSED) {
         _TreeDelete(child, 'c');
      }
      child = _TreeGetNextSiblingIndex(child);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Refresh display for given tag file name.  This function handles both
// updating everything under the tag file that was modified, as well as
// updating items in other tag files that were inherited by this item.
//
void _TagFileModified_cbrowser(_str tag_db_name)
{
   if (!_haveContextTagging()) return;
   _nocheck _control ctl_class_tree_view;

   TBSYMBOLS_FORM_INFO v;
   int f;
   foreach (f => v in gtbSymbolsFormList) {
      // blow out of here if we are not the active tab
      if (!tw_is_wid_active(f)) {
         gtbSymbolsFormList:[f].m_i_need_refresh=1;
         continue;
      }                                       

      // make sure this is the Symbols tool window
      tree_wid := f._find_control("ctl_class_tree_view");
      if (tree_wid <= 0) {
         continue;
      }

      // make the symbol browser tree control the current object
      orig_wid := p_window_id;
      p_window_id = f.ctl_class_tree_view;
      gtbSymbolsFormList:[f].m_i_in_refresh = 1;

      // search for project
      prj_index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      _str prj_db_name;
      while (prj_index > 0) {
         caption := _TreeGetCaption(prj_index);
         parse caption with . ":" prj_db_name;
         if (_file_eq(strip(prj_db_name), tag_db_name)) {
            break;
         }
         prj_index = _TreeGetNextSiblingIndex(prj_index);
      }
      if (prj_index < 0) {
         prj_index = 0;
      }

      // refresh the class tree view under this project
      show_children := 0;
      _TreeGetInfo(prj_index, show_children);
      if (show_children==TREE_NODE_EXPANDED) {
         refresh_class_tree_view(prj_index);
      }

      // refresh the class tree view for inherited members from this tag file
      int prj_key = _TreeGetUserInfo(prj_index);
      index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      while (index > 0) {
         if (index != prj_index) {
            count := 0;
            child := _TreeGetFirstChildIndex(index);
            while (child > 0 && ++count<8) {
               _TreeGetInfo(child, show_children);
               if (show_children==TREE_NODE_EXPANDED) {
                  refresh_inherited_tags(child, prj_key);
               }
               child = _TreeGetNextSiblingIndex(child);
            }
         }
         index = _TreeGetNextSiblingIndex(index);
      }
      _TreeRefresh();

      // refresh the derived classes dialog, parent classes, properties, etc
      refresh_dialog_views();

      gtbSymbolsFormList:[f].m_i_in_refresh = 0;
      p_window_id = orig_wid;

   }
}

static void RefreshTagFilesTimerCB()
{
   if (!_haveContextTagging()) return;
   cb_kill_timer_options();

   foreach (auto f => auto v in gtbSymbolsFormList) {
      // blow out of here if we are not the active tab
      if (!tw_is_wid_active(f)) {
         gtbSymbolsFormList:[f].m_i_need_refresh=1;
         continue;
      }                                       
      if (f != 0 && f.p_name == TBCBROWSER_FORM) {
         f.ctllookin.updateLookinOptions();
         f.ctl_class_tree_view.refresh_tagfiles();
         if (gtbSymbolsFormList._indexin(f)) {
            gtbSymbolsFormList:[f].m_i_need_refresh=0;
         }
      }
   }
}


//////////////////////////////////////////////////////////////////////////////
// Update the list of tag files in the symbol browser tree
// p_window_id must be the symbol browser tree control.
//
void refresh_tagfiles()
{
   // get the information about the current buffer
   currentLanguageMode := "";
   buffer_name := "";
   if (!_no_child_windows()) {
      editorctl_wid := _mdi.p_child;
      currentLanguageMode = editorctl_wid.p_mode_name;
      buffer_name = editorctl_wid.p_buf_name;
   }

   lookinOption := _GetCBrowserLookinOption();
   includeWorkspaceTagFiles := false;
   includeProjectTagFile    := false;
   includeSameProject       := false;
   includeGlobalTagFiles    := false;
   includeLanguageTagFiles  := false;
   includeLanguageMode      := "";
   includeLanguageId        := "";
   
   switch (lookinOption) {
   case VS_TAG_FIND_TYPE_EVERYWHERE:
      includeWorkspaceTagFiles = true;
      includeLanguageTagFiles  = true;
      includeGlobalTagFiles    = true;
      break;
   case VS_TAG_FIND_TYPE_PROJECT_ONLY:
      includeProjectTagFile    = true;
      break;
   case VS_TAG_FIND_TYPE_SAME_PROJECTS:
      includeSameProject       = true;
      break;
   case VS_TAG_FIND_TYPE_WORKSPACE_ONLY:
      includeWorkspaceTagFiles = true;
      break;
   case VS_TAG_FIND_TYPE_CONTEXT:
      includeWorkspaceTagFiles = true;
      includeLanguageTagFiles  = (currentLanguageMode != "");
      includeLanguageMode      = currentLanguageMode;
      includeLanguageId        = _Modename2LangId(includeLanguageMode);
      break;
   default:
      parse lookinOption with . '"' auto mode_name '"' .;
      includeLanguageMode = mode_name;
      includeLanguageId        = _Modename2LangId(includeLanguageMode);
      includeLanguageTagFiles  = true;
      includeWorkspaceTagFiles = true;
      break;
   }

   // create a hash table of all the language-specific tag files
   _str tag_files;
   bool languageTagFiles:[];
   if (includeLanguageTagFiles && includeLanguageMode != "") {
      tag_files = tags_filename(includeLanguageId);
      filename := next_tag_file(tag_files,true);
      while (filename != "") {
         languageTagFiles:[_file_case(filename)] = true;
         filename=next_tag_file(tag_files,false);
      }
   }

   // populate restoration hash table
   bool addedTagFiles:[];
   count := 1;
   _TreeBeginUpdate(TREE_ROOT_INDEX);

   // put in the workspace tags file name (only)
   if (includeWorkspaceTagFiles) {
      tag_files = workspace_tags_filename_only();
      filename := next_tag_file(tag_files,true);
      while (filename != "") {
         if (!addedTagFiles._indexin(_file_case(filename)) && (includeLanguageMode == "" || languageTagFiles._indexin(_file_case(filename)))) {
            add_tag_file(filename, CB_workspace_tag_file, ++count);
            addedTagFiles:[_file_case(filename)] = true;
         }
         filename=next_tag_file(tag_files,false);
      }
   }

   // put in the workspace tags file names
   if (includeWorkspaceTagFiles) {
      tag_files = project_tags_filename();
      if(isEclipsePlugin()) {
         _eclipse_get_projects_tagfiles(tag_files);
      }
      filename := next_tag_file(tag_files,true);
      while (filename != "") {
         if (!addedTagFiles._indexin(_file_case(filename)) && (includeLanguageMode == "" || languageTagFiles._indexin(_file_case(filename)))) {
            add_tag_file(filename, CB_project_tag_file, ++count);
            addedTagFiles:[_file_case(filename)] = true;
         }
         filename=next_tag_file(tag_files,false);
      }
   }

   // now put in the auto-updated workspace tag files
   if (includeWorkspaceTagFiles) {
      tag_files = auto_updated_tags_filename();
      filename := next_tag_file(tag_files,true);
      while (filename != "") {
         if (!addedTagFiles._indexin(_file_case(filename)) && (includeLanguageMode == "" || languageTagFiles._indexin(_file_case(filename)))) {
            add_tag_file(filename, CB_autoupdated_tag_file, ++count);
            addedTagFiles:[_file_case(filename)] = true;
         }
         filename=next_tag_file(tag_files,false);
      }
   }

   // put in the current project tags file names
   if (includeProjectTagFile) {
      tag_files = project_tags_filename_only();
      filename := next_tag_file(tag_files,true);
      while (filename != "") {
         if (!addedTagFiles._indexin(_file_case(filename)) && (includeLanguageMode == "" || languageTagFiles._indexin(_file_case(filename)))) {
            add_tag_file(filename, CB_project_tag_file, ++count);
            addedTagFiles:[_file_case(filename)] = true;
         }
         filename=next_tag_file(tag_files,false);
      }
   }

   // now put in the tag file associated with the same propjec as the current file
   if (includeSameProject) {
      if (buffer_name != "") {
         tag_files = "";
         refs_projects := _WorkspaceFindAllProjectsWithFile(buffer_name, _workspace_filename, isAbsolute:true, skipProjectsNotYetCached:true);
         foreach (auto one_project in refs_projects) {
            proj_tagfile := project_tags_filename_only(one_project);
            if (proj_tagfile == "") continue;
            _maybe_append(tag_files, ' ');
            tag_files :+= _maybe_quote_filename(proj_tagfile);
         }
         if (tag_files._length() <= 0) {
            tag_files = workspace_tags_filename_only();
         }
      } else {
         tag_files = project_tags_filename();
      }
      filename := next_tag_file(tag_files,true);
      while (filename != "") {
         if (!addedTagFiles._indexin(_file_case(filename)) && (includeLanguageMode == "" || languageTagFiles._indexin(_file_case(filename)))) {
            add_tag_file(filename, CB_project_tag_file, ++count);
            addedTagFiles:[_file_case(filename)] = true;
         }
         filename=next_tag_file(tag_files,false);
      }
   }

   // now put in the compiler tags file names
   if (includeLanguageTagFiles && (includeLanguageMode == "" || !_istagging_supported(includeLanguageId) || _LanguageInheritsFrom("c", includeLanguageId))) {
      tag_files = compiler_tags_filename("c");
      filename := next_tag_file(tag_files,true);
      while (filename != "") {
         if (!addedTagFiles._indexin(_file_case(filename))) {
            add_tag_file(filename, CB_cpp_compiler_tag_file, ++count);
            addedTagFiles:[_file_case(filename)] = true;
         }
         filename=next_tag_file(tag_files,false);
      }
   }
   if (includeLanguageTagFiles && (includeLanguageMode == "" || !_istagging_supported(includeLanguageId) || _LanguageInheritsFrom("java", includeLanguageId))) {
      tag_files = compiler_tags_filename("java");
      filename := next_tag_file(tag_files,true);
      while (filename != "") {
         if (!addedTagFiles._indexin(_file_case(filename))) {
            add_tag_file(filename, CB_java_compiler_tag_file, ++count);
            addedTagFiles:[_file_case(filename)] = true;
         }
         filename=next_tag_file(tag_files,false);
      }
   }

   // put in tag files that match current language mode
   if (includeLanguageTagFiles && includeLanguageMode != "") {
      // determine what language modes each tag file *really* belongs to
      _str tag_file_langids:[];
      LanguageSettings.getTagFileListTable(auto langTagFileTable);
      foreach (auto langId => auto langTagFileList in langTagFileTable) {
         tag_files=AbsoluteList(_replace_envvars(langTagFileList));
         filename := next_tag_file(tag_files,true);
         while (filename != "") {
            if (tag_file_langids._indexin(_file_case(filename))) {
               if (tag_file_langids:[_file_case(filename)] == includeLanguageId) {
                  filename=next_tag_file(tag_files,false);
                  continue;
               }
            }
            tag_file_langids:[_file_case(filename)] = langId;
            filename=next_tag_file(tag_files,false);
         }
      }
      // now add the tag files for this language mode
      tag_files = tags_filename(includeLanguageId);
      filename := next_tag_file(tag_files,true);
      while (filename != "") {
         if (!addedTagFiles._indexin(_file_case(filename))) {
            useLanguageMode := includeLanguageMode;
            if (tag_file_langids._indexin(_file_case(filename))) {
               langId = tag_file_langids:[_file_case(filename)];
               useLanguageMode = _LangId2Modename(langId);
            }
            add_tag_file(filename, '"'useLanguageMode'"', ++count);
            addedTagFiles:[_file_case(filename)] = true;
         }
         filename=next_tag_file(tag_files,false);
      }
   }

   // now put in the extension specific tags file names
   if (includeLanguageTagFiles && includeLanguageMode == "") {
      LanguageSettings.getTagFileListTable(auto langTagFileTable);
      foreach (auto langId => auto langTagFileList in langTagFileTable) {
         tag_files=AbsoluteList(_replace_envvars(langTagFileList));
         filename := next_tag_file(tag_files,true);
         while (filename != "") {
            if (!addedTagFiles._indexin(_file_case(filename))) {
               add_tag_file(filename, '"'_LangId2Modename(langId)'"', ++count);
               addedTagFiles:[_file_case(filename)] = true;
            }
            filename=next_tag_file(tag_files,false);
         }
      }
   }

   //cb_remove_stale_items(TREE_ROOT_INDEX);
   _TreeEndUpdate(TREE_ROOT_INDEX);
   _TreeSortUserInfo(TREE_ROOT_INDEX, 'N');
   _TreeRefresh();
}


/**
 * Look-in options could change if the current buffer changes
 */
void _switchbuf_symbols_browser()
{
   if (_in_batch_open_or_close_files()) return;
   if (!_haveContextTagging()) return;
   wid := _GetCBrowserWID();
   if (wid != 0) {
      cb_start_timer_options(wid, RefreshTagFilesTimerCB);
   }
}


//////////////////////////////////////////////////////////////////////////////
// Refresh list of tag databases.  It uses prepare_for_expand() to set up
// a hash table of all the current tag database captions.  Tries to insert
// the new ones, and deletes all the stale items afterward.
//
void _TagFileAddRemove_cbrowser(_str file_name, _str options)
{
   if (!_haveContextTagging()) return;

   // refresh tag files
   wid := _GetCBrowserWID();
   if (wid != 0) {
      cb_start_timer_options(wid, RefreshTagFilesTimerCB);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Callback for refreshing the symbol browser, as required by the background
// tagging.  Since we handle the AddRemove and Modified callbacks, we don't
// have to do anything for refresh, we are already totally up-to-date.
//
void _TagFileRefresh_cbrowser()
{
   if (!_haveContextTagging()) return;

   // refresh tag files
   wid := _GetCBrowserWID();
   if (wid != 0) {
      cb_start_timer_options(wid, RefreshTagFilesTimerCB);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Restore the symbol browser tree when they open a new project
//
void _prjopen_cbrowser(bool singleFileProject)
{
   if (singleFileProject) return;
   if (!_haveContextTagging()) return;
   _nocheck _control ctl_class_tree_view;

   // symbol browser restore options turned off?
   if (!(def_restore_flags & RF_CBROWSER_TREE)) {
      return;
   }

   _nocheck _control ctl_class_tree_view;

   TBSYMBOLS_FORM_INFO v;
   int f;
   foreach (f => v in gtbSymbolsFormList) {

      // blow out of here if we are not the active tab
      if (!tw_is_wid_active(f)) {
         gtbSymbolsFormList:[f].m_i_need_refresh=1;
         continue;
      }                                       

      // refresh tag files, we get this callback before Addremove (above)
      f.ctl_class_tree_view.refresh_tagfiles();

      // now restore open items
      _str open_cats, curr_path;
      open_cats = _retrieve_value(TBCBROWSER_FORM:+".ctl_member_filter_label");
      curr_path = _retrieve_value(TBCBROWSER_FORM:+".ctl_class_filter_label");

      gtbSymbolsFormList:[f].m_i_in_refresh = 1;
      f.ctl_class_tree_view.restore_class_tree_view(TREE_ROOT_INDEX, open_cats);
      int index = f.ctl_class_tree_view.restore_position(TREE_ROOT_INDEX, curr_path);
      if (index > 0) {
         f.ctl_class_tree_view._TreeSetCurIndex(index);
      }
      f.ctl_class_tree_view._TreeRefresh();
      gtbSymbolsFormList:[f].m_i_in_refresh = 0;
   }
}

//////////////////////////////////////////////////////////////////////////////
// Force a refresh in the current symbol browser.
//
_command cb_refresh() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   f := _tbGetActiveSymbolsForm();
   if (!f) {
      return "";
   }

   gtbSymbolsFormList:[f].m_i_in_refresh = 1;
   orig_redraw := f.ctl_class_tree_view.p_redraw;
   f.ctl_class_tree_view.p_redraw=false;
   f.ctl_class_tree_view.refresh_class_tree_view(TREE_ROOT_INDEX);
   f.ctl_class_tree_view.refresh_dialog_views();
   f.ctl_class_tree_view.p_redraw=orig_redraw;
   gtbSymbolsFormList:[f].m_i_need_refresh = 0;
   gtbSymbolsFormList:[f].m_i_in_refresh = 0;
}

//////////////////////////////////////////////////////////////////////////////
// shortcuts for sort by line and short by name
//
_command cb_sortby_line() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   cb_sortby_menu("sortline");
}
_command cb_sortby_name() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   cb_sortby_menu("sortname");
}
_command cb_sortby_float() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   cb_sortby_menu("floattotop");
}
//////////////////////////////////////////////////////////////////////////////
// Change gi_sort_by_line and force a refresh of the symbol browser
//
_command cb_sortby_menu(_str option="") name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (option=="") {
      return "";
   }

   f := _tbGetActiveSymbolsForm();
   if (!f) {
      return "";
   }

   // based on menu selection
   switch (option) {
   case "sortline":
      gi_sort_by_line = 1;
      break;
   case "sortname":
      gi_sort_by_line = 0;
      break;
   case "floattotop":
      gi_sort_float_to_top = (int) !gi_sort_float_to_top;
      break;
   default:
      return "";
   }

   return cb_refresh();
}

//////////////////////////////////////////////////////////////////////////////
// Retrieve and translate the class filter and member filter regular
// expressions.  If the input expression (p_text) contains vertical
// bars, open parentheses, or left curly braces, then do not perform
// translation.  The following translations are performed:
//    -- convert all comma's, semicolons, and spaces to | (OR)
//    -- eliminate adjacent vertical bars
//    -- For brief regular expressions, add grouping
//    -- For brief regular expression, shift BOL/EOL symbols to begin/end
//
// p_window_id must be the combo box containing the regular expression.
//
static _str cb_get_filter()
{
   if (p_visible) {
      re := p_text;
      if (!pos("|",re) && !pos("(",re) && !pos("{",re)) {
         s := strip(re);
         s = translate(s,"|||",";, ");
         s = stranslate(s,"|","[|][|]#", "R");
         //if (pos("|",s) && (def_re_search_flags&BRIEFRE_SEARCH)) {
         //   s = '\(' :+ stranslate(s, '\)|\(', '|') :+ '\)';
         //}
         return s;
      }
      return re;
   }
   return "";
}

//////////////////////////////////////////////////////////////////////////////
// right click callback for filtering options image, simply
// displays the options dialog.
//
void ctl_filter_check_box.rbutton_up()
{
   cb_options();
}

//////////////////////////////////////////////////////////////////////////////
// single-click callback for filtering options image button,
// pick up new value of options and apply changes (if any)
//
void ctl_filter_check_box.lbutton_up()
{
   if (p_value) {
      ctl_class_filter_combo_box.p_text  = "";
      ctl_member_filter_combo_box.p_text = "";
   }
   cb_refresh();
}

//////////////////////////////////////////////////////////////////////////////
// 'enter' event handler for both the class filter or member filter
// combo-box controls.  Retrieves both filters and updates the class
// browser if either one of them has changed.
//
void ctl_class_filter_combo_box.enter()
{
   _nocheck _control ctl_class_filter_combo_box;
   _nocheck _control ctl_member_filter_combo_box;
   _nocheck _control ctl_class_tree_view;

   // for dialog box retrieval
   _append_retrieve(ctl_class_filter_combo_box, ctl_class_filter_combo_box.p_text);
   _append_retrieve(ctl_member_filter_combo_box, ctl_member_filter_combo_box.p_text);
   _save_form_response();
   ctl_class_filter_combo_box._retrieve_list();
   ctl_member_filter_combo_box._retrieve_list();

   // get the current filters
   _str c_filter = ctl_class_filter_combo_box.cb_get_filter();
   _str m_filter = ctl_member_filter_combo_box.cb_get_filter();
   if (c_filter :== gtbSymbolsFormList:[p_active_form].m_z_class_filter && m_filter :== gtbSymbolsFormList:[p_active_form].m_z_member_filter) {
      return;
   } else {
      gtbSymbolsFormList:[p_active_form].m_z_class_filter  = c_filter;
      gtbSymbolsFormList:[p_active_form].m_z_member_filter = m_filter;
   }
   if (c_filter!="" || m_filter!="") {
      ctl_filter_check_box.p_value=0;
   }

   // update the symbol browser (refreshs everything)
   cb_refresh();
}

//////////////////////////////////////////////////////////////////////////////
// Add a tag file to the tree control, return the new index
// p_window_id must be the symbol browser tree control.
//
static int add_tag_file(_str file_name, _str file_type, int sequence_number)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // open the tag database for business
   int status = tag_read_db(file_name);
   if ( status < 0 ) {
      return(status);
   }

   // get tag file description
   caption :=  file_type ": " file_name;
   _str descr = tag_get_db_comment();
   if (descr != "") {
      caption :+= " (" descr ")";
   }

   j := _TreeAddItem(TREE_ROOT_INDEX, caption, TREE_ADD_AS_CHILD, _pic_fldtags, _pic_fldtags, TREE_NODE_COLLAPSED, 0, sequence_number);
   return j;
}

static void updateLookinOptions()
{
   // put in the standard, top five search types
   p_enabled = false;
   origText := p_text;
   _lbclear();
   _lbadd_item(VS_TAG_FIND_TYPE_EVERYWHERE);
   _lbadd_item(VS_TAG_FIND_TYPE_CONTEXT);
   _lbadd_item(VS_TAG_FIND_TYPE_WORKSPACE_ONLY);
   _lbadd_item(VS_TAG_FIND_TYPE_PROJECT_ONLY);
   _lbadd_item(VS_TAG_FIND_TYPE_SAME_PROJECTS);

   // add language-specific tag files
   bool haveLangIds:[];
   LanguageSettings.getTagFileListTable(auto langTagFilesTable);
   foreach (auto langId => . in langTagFilesTable) {
      mode_name := _LangGetModeName(langId);
      _lbadd_item(nls(VS_TAG_FIND_TYPE_EXTENSION,mode_name));
      haveLangIds:[langId] = true;
   }

   // add languages with compiler tag files (if not already present)
   foreach (langId in "c java") {
      if (!haveLangIds._indexin(langId)) {
         tag_files := compiler_tags_filename(langId);
         if (tag_files != "") {
            mode_name := _LangGetModeName(langId);
            _lbadd_item(nls(VS_TAG_FIND_TYPE_EXTENSION,mode_name));
         }
      }
   }

   // restore the original value
   if (origText == p_text) {
      _cbset_text(origText);
   }
   p_enabled = true;
   if (origText != "" && origText != p_text) {
      _cbset_text(origText);
   } else if (origText == "") {
      _cbset_text(VS_TAG_FIND_TYPE_EVERYWHERE);
   }
}

//////////////////////////////////////////////////////////////////////////////
// on form creation, popuplate the tree widget, set initial focus
//
void ctl_class_tree_view.on_create()
{
   TBSYMBOLS_FORM_INFO info;
   i := p_active_form;

   info.m_form_wid=i;
   info.m_i_in_refresh= 0;
   info.m_i_need_refresh= 0;
   info.m_z_class_filter= ctl_class_filter_combo_box.cb_get_filter();
   info.m_z_member_filter= ctl_member_filter_combo_box.cb_get_filter();
   gtbSymbolsFormList:[i]=info;

   // restore previous search scope and options
   ctllookin.updateLookinOptions();
   ctllookin._retrieve_value();
   if (ctllookin.p_text=="") {
      ctllookin._cbset_text(VS_TAG_FIND_TYPE_EVERYWHERE);
   }

   ctl_class_filter_label.p_user  = _retrieve_value(TBCBROWSER_FORM:+".ctl_class_filter_label.p_visible");
   ctl_member_filter_label.p_user = _retrieve_value(TBCBROWSER_FORM:+".ctl_member_filter_label.p_visible");
   _str v=_retrieve_value(TBCBROWSER_FORM:+".ctl_filter_check_box");
   if (v!="" && isnumber(v)) {
      ctl_filter_check_box.p_value=(int)v;
   }
   ctl_class_filter_combo_box._retrieve_value();
   ctl_member_filter_combo_box._retrieve_value();
   ctl_class_filter_combo_box._retrieve_list();
   ctl_member_filter_combo_box._retrieve_list();
   if (ctl_filter_check_box.p_value) {
      ctl_class_filter_combo_box.p_text="";
      ctl_member_filter_combo_box.p_text="";
   }
   ctl_class_tree_view.p_user = _retrieve_value(TBCBROWSER_FORM:+".ctl_class_tree_view");
   if (ctl_class_tree_view.p_user == "") {
      ctl_class_tree_view.p_user = CB_DEFAULTS;
   }
   ctl_filter_check_box.p_user = _retrieve_value(TBCBROWSER_FORM:+".ctl_filter_check_box.p_user");
   if (ctl_filter_check_box.p_user == "") {
      ctl_filter_check_box.p_user = CB_DEFAULTS2;
   }
   gi_sort_by_line = _retrieve_value("_cbrowse_menu.cb_sort_by_line");
   gi_sort_float_to_top = _retrieve_value("_cbrowse_menu.cb_sort_float");

   // reduced level indent
   ctl_class_tree_view.p_LevelIndent = _dx2lx(SM_TWIP, 12);

   // insert items for each tag file
   ctl_class_tree_view.refresh_tagfiles();

   if (!gb_in_twrestore && (def_restore_flags & RF_CBROWSER_TREE)) {
      _str open_cats, curr_path;
      open_cats = _retrieve_value(TBCBROWSER_FORM:+".ctl_member_filter_label");
      curr_path = _retrieve_value(TBCBROWSER_FORM:+".ctl_class_filter_label");

      gtbSymbolsFormList:[p_active_form].m_i_in_refresh = 1;
      ctl_class_tree_view.restore_class_tree_view(TREE_ROOT_INDEX, open_cats);
      int index = ctl_class_tree_view.restore_position(TREE_ROOT_INDEX, curr_path);
      if (index > 0) {
         ctl_class_tree_view._TreeSetCurIndex(index);
      }
      gtbSymbolsFormList:[p_active_form].m_i_in_refresh = 0;
   }

   checkShowHideControls();
   ctl_class_tree_view._TreeRefresh();
   ctl_class_tree_view._MakePreviewWindowShortcuts();
}

///////////////////////////////////////////////////////////////////////////////
// For saving and restoring the state of the classes tool window
// when the user undocks, pins, unpins, or redocks the window.
//
struct SYMBOL_BROWSER_WINDOW_STATE {
   typeless nodes;
   int column_width;
};
void _twSaveState__tbcbrowser_form(SYMBOL_BROWSER_WINDOW_STATE& state, bool closing)
{
   //if( closing ) {
   //   return;
   //}
   gb_in_twrestore=true;
   ctl_class_tree_view._TreeSaveNodes(state.nodes);
}
void _twRestoreState__tbcbrowser_form(SYMBOL_BROWSER_WINDOW_STATE& state, bool opening)
{
   //if( opening ) {
   //   return;
   //}
   if (state != null) {
      ctl_class_tree_view._TreeDelete(TREE_ROOT_INDEX, 'c');
      ctl_class_tree_view._TreeRestoreNodes(state.nodes);
      ctl_class_tree_view._TreeSizeColumnToContents(0);
   }
   gb_in_twrestore=false;
}

//////////////////////////////////////////////////////////////////////////////
// Called when the symbol browser is resized
//
void cbrowser_on_resize(int avail_width, int avail_height)
{
   f := _tbGetActiveSymbolsForm();
   if (!f) return;

   // available width, height, and amount of border
   _nocheck _control ctllookinlabel;
   max_label_width := max(f.ctllookinlabel.p_width, f.ctl_class_filter_label.p_width, f.ctl_member_filter_label.p_width);
   border_width   := f.ctllookinlabel.p_x;
   border_height  := f.ctllookin.p_y;
   label_height   := 2*border_height + f.ctl_class_filter_combo_box.p_height;
   filter_x       := border_width + max_label_width + border_width;
   avail_width    -= border_width;
   avail_height   -= border_height;

   // count the number of label/combo-boxes visible
   labels_visible := 1;
   if (f.ctl_class_filter_label.p_visible) {
      labels_visible++;
   }
   if (f.ctl_member_filter_label.p_visible) {
      labels_visible++;
   }

   // adjust x position and width of filters
   f.ctl_filter_check_box.p_x = avail_width - f.ctl_filter_check_box.p_width;
   f.ctllookin.p_x = filter_x;
   f.ctllookin.p_x_extent = f.ctl_filter_check_box.p_x - border_width;
   f.ctl_class_filter_combo_box.p_x = filter_x;
   f.ctl_class_filter_combo_box.p_width = avail_width - f.ctl_class_filter_combo_box.p_x;
   f.ctl_member_filter_combo_box.p_x = filter_x;
   f.ctl_member_filter_combo_box.p_width = avail_width - f.ctl_class_filter_combo_box.p_x;

   // adjust y position of class and member filter
   f.ctl_filter_check_box.p_y        = 2*border_height;
   f.ctl_class_filter_combo_box.p_y  = label_height + border_height;
   f.ctl_class_filter_label.p_y      = label_height + 2*border_height;
   f.ctl_member_filter_combo_box.p_y = (labels_visible-1)*label_height;
   f.ctl_member_filter_label.p_y     = (labels_visible-1)*label_height + border_height;

   // adjust the size and position the class tree view
   f.ctl_class_tree_view.p_y = labels_visible*label_height;
   f.ctl_class_tree_view.p_x_extent = avail_width;
   f.ctl_class_tree_view.p_y_extent = avail_height;

}

static void resizeSymbolsBrowser()
{
   int old_wid, clientW, clientH;
   if (isEclipsePlugin()) {
      classesOutputContainer := _tbGetActiveSymbolsForm();
      if(!classesOutputContainer) return;
      old_wid = p_window_id;
      p_window_id = classesOutputContainer;
      eclipse_resizeContainer(classesOutputContainer);
      clientW = classesOutputContainer.p_parent.p_width; 
      clientH = classesOutputContainer.p_parent.p_height;
   } else {
      clientW = _dx2lx(p_active_form.p_xyscale_mode,p_active_form.p_client_width);
      clientH = _dy2ly(p_active_form.p_xyscale_mode,p_active_form.p_client_height);
   }
   
   // Resize x positioning
   margin_x := 60;
   max_label_width := max(ctllookinlabel.p_width, ctl_class_filter_label.p_width, ctl_member_filter_label.p_width);
   ctllookinlabel.p_x = margin_x;
   ctl_class_filter_label.p_x = margin_x;
   ctl_member_filter_label.p_x = margin_x;
   ctl_filter_check_box.p_x = clientW - ctl_filter_check_box.p_width - margin_x;
   ctllookin.p_x                   = margin_x + max_label_width + margin_x;
   ctl_class_filter_combo_box.p_x  = margin_x + max_label_width + margin_x;
   ctl_member_filter_combo_box.p_x = margin_x + max_label_width + margin_x;

   // Resize width
   ctllookin.p_x_extent = ctl_filter_check_box.p_x - margin_x;
   ctl_class_filter_combo_box.p_x_extent = clientW - ctl_class_tree_view.p_x;
   ctl_member_filter_combo_box.p_x_extent = clientW - ctl_class_tree_view.p_x;
   ctl_class_tree_view.p_width = clientW - 2 * ctl_class_tree_view.p_x;

   // Resize height
   ctl_class_tree_view.p_y_extent = clientH - ctl_class_tree_view.p_x;
   cbrowser_on_resize(clientW, clientH);

   if (isEclipsePlugin()) {
      p_window_id = old_wid;
   }
}

void _tbcbrowser_form.on_resize()
{
   resizeSymbolsBrowser();
}

//////////////////////////////////////////////////////////////////////////////
// Called by on_destroy event for _tbcbrowser_form
//
void cbrowser_on_destroy()
{
   // get the window ID of the form
   f := _tbGetActiveSymbolsForm();
   if (!f) return;

   // save all the currently open categories
   open_cats := "";
   curr_path := "";
   if (!gb_in_twrestore && (def_restore_flags & RF_CBROWSER_TREE)) {
      f.ctl_class_tree_view.save_class_tree_view(TREE_ROOT_INDEX, "", open_cats);
      f.ctl_class_tree_view.save_position(curr_path);
   }

   // save options and current position
   _nocheck _control ctllookin;
   _nocheck _control ctl_member_filter_label;
   _nocheck _control ctl_class_filter_label;
   _append_retrieve(f.ctllookin, f.ctllookin.p_text);
   _append_retrieve(0, f.ctl_member_filter_label.p_user, TBCBROWSER_FORM:+".ctl_member_filter_label.p_visible");
   _append_retrieve(0, f.ctl_class_filter_label.p_user,  TBCBROWSER_FORM:+".ctl_class_filter_label.p_visible");
   _append_retrieve(f.ctl_member_filter_combo_box, f.ctl_member_filter_combo_box.p_text, TBCBROWSER_FORM:+".ctl_member_filter_combo_box");
   _append_retrieve(f.ctl_class_filter_combo_box,  f.ctl_class_filter_combo_box.p_text,  TBCBROWSER_FORM:+".ctl_class_filter_combo_box");
   _append_retrieve(0, f.ctl_class_tree_view.p_user, TBCBROWSER_FORM:+".ctl_class_tree_view" );
   _append_retrieve(0, f.ctl_filter_check_box.p_user, TBCBROWSER_FORM:+".ctl_filter_check_box.p_user" );
   _append_retrieve(0, open_cats, TBCBROWSER_FORM:+".ctl_member_filter_label" );
   _append_retrieve(0, curr_path, TBCBROWSER_FORM:+".ctl_class_filter_label" );
   _append_retrieve(0, gi_sort_by_line, "_cbrowse_menu.cb_sort_by_line" );
   _append_retrieve(0, gi_sort_float_to_top, "_cbrowse_menu.cb_sort_float" );
   _append_retrieve(0, f.ctl_filter_check_box.p_value, TBCBROWSER_FORM:+".ctl_filter_check_box");

   // reset the cached window ID's
}

void _tbcbrowser_form.on_destroy()
{
   cbrowser_on_destroy();
   call_event(p_window_id,ON_DESTROY,'2');
   cb_kill_timer();
   cb_kill_timer_highlight();
   cb_kill_timer_options();
   gtbSymbolsFormList._deleteel(p_active_form);
}

//////////////////////////////////////////////////////////////////////////////
// Decompose the typeless user data into database ID, file_id, and line_no
//
int cb_get_db_file_line(typeless value, int &db_id, int &file_id, int &line_no)
{
   if ((VF_IS_INT(value) || value._varformat()==VF_LSTR) &&
       !value._isempty() && isnumber(value)) {

      // simple little computations
      line_no = value % CB_MAX_LINE_NUMBER;
      value   = value intdiv CB_MAX_LINE_NUMBER;
      file_id = value % CB_MAX_FILE_NUMBER;
      db_id   = value intdiv CB_MAX_FILE_NUMBER;
      return 0;
   }
   // invalid user info
   db_id=file_id=line_no=0;
   return 1;
}

static _str get_language_from_symbol_browser_database_caption(_str caption)
{
   if (caption == "Workspace" || caption == "Auto Updated") {
      return "";
   }
   if (pos(" Compiler",caption)) {
      parse caption with caption . ;
      if (caption == "C++") caption = "C/C++";
   }
   caption = strip(caption,"B","\"");
   lang := _Modename2LangId(caption);
   return lang;
}

/**
 * Grab the supplementary information stored with each tag in the tree widget
 * p_window_id must be the symbol browser tree control.
 * 
 * @param j             tree index
 * @param cm            (output) symbol information
 * @param no_db_access  get minimal information, no database access
 * 
 * @return 
 * Returns 0 if 'tree_index' is invalid, or if it does not point to a symbol. 
 * Returns 1 if it found a valid symbol. 
 */
static int get_user_tag_info(int j, struct VS_TAG_BROWSE_INFO &cm, bool no_db_access)
{
   tag_init_tag_browse_info(cm);

   // bail out if j <= 0
   extra_depth := 0;
   if (j <= 0) {
      return 0;
   }

   // handle things differently depending on the current depth
   int p,g;
   _str caption,file_name;
   int tree_depth = _TreeGetDepth(j);
   switch (tree_depth) {
   case 0:  // bail out if this is the tree root
      return 0;

   case 1:  // project/global tag file?
      caption = _TreeGetCaption(j);
      parse caption with caption ":" file_name " (" .;
      cm.tag_database = absolute(strip(file_name));
      cm.language = get_language_from_symbol_browser_database_caption(caption);
      return 0;

   case 2: // category?
      p = _TreeGetParentIndex(j);
      caption = _TreeGetCaption(p);
      parse caption with caption ":" file_name " (" .;
      cm.tag_database = absolute(strip(file_name));
      cm.language = get_language_from_symbol_browser_database_caption(caption);
      caption = _TreeGetCaption(j);
      parse caption with cm.category CB_delimiter .;
      return 0;

   case 3:
      // get the tag database name and category caption
      p = _TreeGetParentIndex(j);
      g = _TreeGetParentIndex(p);
      caption = _TreeGetCaption(g);
      parse caption with caption ":" file_name " (" .;
      cm.tag_database = absolute(strip(file_name));
      cm.language = get_language_from_symbol_browser_database_caption(caption);
      caption = _TreeGetCaption(p);
      parse caption with cm.category CB_delimiter .;
      if (_TreeGetUserInfo(j) == "") {
         return 0;
      }
      caption = _TreeGetCaption(j);
      parse caption with cm.member_name CB_delimiter .;
      break;

   default:
      // traverse up the tree and locate tag database and category name
      p = _TreeGetParentIndex(j);
      g = _TreeGetParentIndex(p);
      int cat_index = j;
      int prj_index = p;
      while (g > 0) {
         if (_TreeGetUserInfo(g) != "") {
            cat_index = prj_index;
            prj_index = g;
         } else {
            extra_depth=1;
         }
         g = _TreeGetParentIndex(g);
      }

      // get the tag database name and category caption
      caption = _TreeGetCaption(prj_index);
      parse caption with caption ": " file_name " (" .;
      cm.tag_database = absolute(strip(file_name));
      cm.language = get_language_from_symbol_browser_database_caption(caption);
      caption = _TreeGetCaption(cat_index);
      parse caption with cm.category CB_delimiter .;
      cm.member_name  = _TreeGetCaption(j);
      parse cm.member_name with cm.member_name "\t" cm.class_name "(" .;
      //int lp=lastpos("::",cm.class_name);
      //if (lp) {
      //   cm.class_name=substr(cm.class_name,1,lp-1);
      //}
      parse cm.member_name with cm.member_name CB_delimiter .;
      break;
   }

   // normalize member name
   dummy := "";
   tag_tree_decompose_caption(cm.member_name,cm.member_name,dummy,cm.arguments,cm.template_args);

   // get basic location info for this tag
   typeless value = _TreeGetUserInfo(j);
   int tag_file_id,file_id;
   cb_get_db_file_line(value, tag_file_id, file_id, cm.line_no);
   //say("file="file_id" line="cm.line_no" tagfile="tag_file_id" value="_TreeGetUserInfo(j));

   // find the tag file with the given sequence number (tag_file_id)
   child := 0;
   if (tag_file_id > 0) {
      child = _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      while (child > 0) {
         int sequence_number;
         sequence_number = _TreeGetUserInfo(child);
         if (sequence_number == tag_file_id) {
            caption = _TreeGetCaption(child);
            parse caption with . ":" file_name " (" .;
            cm.tag_database = absolute(strip(file_name));
            break;
         }
         child = _TreeGetNextSiblingIndex(child);
      }
   }

   // get the class name and member name for the fully qualified class name
   _str class_name,member_name;
   _str pcaption;
   _str separator;
   int target_depth;
   show_children := 0;
   _TreeGetInfo(j, show_children);
   if (show_children != TREE_NODE_LEAF) {
      class_name = cm.class_name;
      member_name = cm.member_name;
      target_depth = 4;
   } else {
      p = _TreeGetParentIndex(j);
      pcaption = _TreeGetCaption(p);
      parse pcaption with member_name "\t" class_name "(" .;
      lp := lastpos("::",class_name);
      if (lp) {
         class_name=substr(class_name,1,lp-1);
      }
      target_depth = 5;
   }

   // get the picture index for packages
   pic_package := tag_get_bitmap_for_type(SE_TAG_TYPE_PACKAGE);

   // get the picture index for the parent node
   parent_show_children := 0;
   parent_pic_index := 0;
   _TreeGetInfo(p, parent_show_children, parent_pic_index);

   // select the class separator and construct qualified name
   if (class_name != "") {
      separator = VS_TAGSEPARATOR_class;
      if (tree_depth == target_depth+extra_depth) {
         CB_TAG_CATEGORY *ctg = gh_cb_categories._indexin(cm.category);
         if (ctg && ctg->use_package_separator) {
            separator = VS_TAGSEPARATOR_package;
         } 
      } else if (parent_pic_index == pic_package) {
         separator = VS_TAGSEPARATOR_package;
      }
      cm.qualified_name = class_name :+ separator :+ member_name;
   } else {
      cm.qualified_name = member_name;
   }
   parse cm.qualified_name with cm.qualified_name "(" .;

   // bail out if we were asked not to touch the database
   if (no_db_access) {
      return 1;
   }

   // blow out of here if member_name == ""
   if (cm.member_name == "") {
      return 1;
   }

   // open the tag database for business
   int status = tag_read_db(cm.tag_database);
   if ( status < 0 ) {
      return(status);
   }

   // convert the tag file id to a real name
   status = tag_get_file(file_id, file_name);
   if (status) {
      return status;
   }
   cm.file_name = file_name;

   status = tag_get_language(file_name,cm.language);
   if (status) {
      cm.language="";
   } else if (cm.language=="jar" || cm.language=="zip") {
      cm.language="java";
   }

   // find the given tag in the file at the given line (case sensitive)
   status = tag_find_closest(cm.member_name, cm.file_name, cm.line_no, true);
   if (!status) {
      tag_get_detail(VS_TAGDETAIL_type_id,   cm.type_id);
      tag_get_detail(VS_TAGDETAIL_type,      cm.type_name);
      tag_get_detail(VS_TAGDETAIL_flags,     cm.flags);
      tag_get_detail(VS_TAGDETAIL_return,    cm.return_type);
      tag_get_detail(VS_TAGDETAIL_arguments, cm.arguments);
      tag_get_detail(VS_TAGDETAIL_throws,    cm.exceptions);
      tag_get_detail(VS_TAGDETAIL_class_parents, cm.class_parents);
      tag_get_detail(VS_TAGDETAIL_template_args, cm.template_args);
      tag_get_detail(VS_TAGDETAIL_doc_comments,  cm.doc_comments);
      tag_get_detail(VS_TAGDETAIL_doc_type,      cm.doc_type);
      if (cm.type_name=="include" && cm.return_type!="" && file_exists(cm.return_type)) {
         cm.file_name=cm.return_type;
         cm.line_no=1;
      }
   }

   tag_reset_find_tag();
   return 1;
}

//////////////////////////////////////////////////////////////////////////////
// Find which tag file the given class belongs to, and normalize the
// class name (qualifies class name with package name) if (normalize!=0).
// Returns the tag file that the class was found in, or "" if not found.
//
static int find_class_in_cur_tag_file(_str cur_class_name, _str class_name,
                                      _str &qualified_name, bool normalize,
                                      bool ignore_case=false)
{
   //say("find_class_in_cur_tag_file: cur="cur_class_name" class="class_name);
   // disect the current class name into package and outer components
   _str inner_name,outer_name;
   tag_split_class_name(cur_class_name,inner_name,outer_name);

   if (normalize) {
      // first, try to find it in the current tag file, and current class context
      int status = tag_find_class(qualified_name, class_name, normalize, !ignore_case, outer_name);
      if (!status) {
         tag_reset_find_class();
         return 0;
      }

      // now try the current tag file, and current package
      if (pos(VS_TAGSEPARATOR_package,outer_name)>0) {
         outer_name = substr(outer_name,1,pos('S')-1);
         status = tag_find_class(qualified_name, class_name, normalize, !ignore_case, outer_name);
         if (!status) {
            tag_reset_find_class();
            return 0;
         }
      }
   }

   // OK, now try general case
   result := tag_find_class(qualified_name, class_name, normalize, ignore_case);
   tag_reset_find_class();
   return result;
}

//////////////////////////////////////////////////////////////////////////////
// Find which tag file the given class belongs to, and normalize the
// class name (qualifies class name with package name) if (normalize!=0).
// Returns the tag file that the class was found in, or "" if not found.
//
_str find_class_in_tag_file(_str cur_class_name, _str class_name,
                                   _str &qualified_name, bool normalize,
                                   typeless &tag_files, bool ignore_case=false)
{
   // disect the current class name into package and outer components
   _str inner_name,outer_name;
   tag_split_class_name(cur_class_name,inner_name,outer_name);

   // first, try to find it in the current tag file, and current class context
   orig_tag_file := tag_current_db();
   int status = find_class_in_cur_tag_file(cur_class_name,class_name,
                                           qualified_name,normalize,ignore_case);
   //say("find_class_in_tag_file1: qual="qualified_name" class="class_name" status="status" tagfile="orig_tag_file);
   if (status==0) {
      return orig_tag_file;
   }

   // didn't find it in our tag file, search others
   i := 0;
   filename := next_tag_filea(tag_files,i,false,true);
   while (filename != "") {
      if (! _file_eq(filename, orig_tag_file)) {
         status = find_class_in_cur_tag_file(cur_class_name,class_name,
                                             qualified_name,normalize,ignore_case);
         //say("find_class_in_tag_file2: qual="qualified_name" class="class_name" status="status" tagfile="orig_tag_file);
         if (status==0) {
            tag_read_db(orig_tag_file);
            return filename;
         }
      }
      filename=next_tag_filea(tag_files,i,false,true);
   }

   // re-open the original tag file
   status = tag_read_db(orig_tag_file);
   return "";
}

int tag_get_browse_inheritance(VS_TAG_BROWSE_INFO &cm, typeless &tag_files=null)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // already have the information
   if (cm.class_parents != "") {
      return 0;
   }

   if (_isEditorCtl() && _file_eq(cm.file_name, p_buf_name)) {

      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext();

      // make sure that context and locals are up to date
      _UpdateContext(true);
      _UpdateLocals(true);

      // check locals
      save_pos(auto p);
      _end_line();
      seekpos := (int)_QROffset();
      restore_pos(p);
      i := tag_find_local_iterator(cm.member_name, true, true, false, cm.class_name);
      while (i > 0) {
         tag_get_detail2(VS_TAGDETAIL_local_type, i, auto type_name);
         if (tag_is_local_in_scope(i, seekpos) && (type_name == cm.type_name || cm.type_name == "")) {
            tag_get_detail2(VS_TAGDETAIL_local_parents, i, cm.class_parents);
            tag_get_detail(VS_TAGDETAIL_local_line, auto file_line);
            if (file_line == cm.line_no || (cm.line_no==0 && cm.class_parents!="")) {
               if (cm.file_name=="") cm.file_name = p_buf_name;
               if (cm.line_no==0)    cm.line_no = file_line;
               return 0;
            }
         }
         // next please
         i = tag_next_local_iterator(cm.member_name, i, true, true, false, cm.class_name);
      }

      // check context
      i = tag_find_context_iterator(cm.member_name, true, true, false, cm.class_name);
      while (i > 0) {
         tag_get_detail2(VS_TAGDETAIL_context_type, i, auto type_name);
         if (type_name == cm.type_name || cm.type_name == "") {
            tag_get_detail2(VS_TAGDETAIL_context_parents, i, cm.class_parents);
            tag_get_detail(VS_TAGDETAIL_context_line, auto file_line);
            if (file_line == cm.line_no || (cm.line_no==0 && cm.class_parents!="")) {
               if (cm.file_name=="") cm.file_name = p_buf_name;
               if (cm.line_no==0)    cm.line_no = file_line;
               return 0;
            }
         }
         // next please
         i = tag_next_context_iterator(cm.member_name, i, true, true, false, cm.class_name);
      }
   }

   // we found some match, just not on the expected line
   if (cm.class_parents != "") {
      return 0;
   }

   // check in tag databases
   i := 0;
   orig_tag_file := tag_current_db();
   tag_filename := cm.tag_database;
   if (tag_filename != "") {
      tag_read_db(cm.tag_database);
   } else if ( tag_files != null ) {
      tag_filename = next_tag_filea(tag_files,i,false,true);
   }

   while (tag_filename != "") {
      // find all instances of the tag, tag first with class parents
      file_name:="";
      status := 0;
      if (cm.type_name!="") {
         status = tag_find_tag(cm.member_name, cm.type_name, cm.class_name, cm.arguments);
      } else {
         status = tag_find_equal(cm.member_name, true, cm.class_name);
      }
      while (!status) {
         // check file name and line number
         tag_get_detail(VS_TAGDETAIL_file_name, file_name);
         if (cm.file_name=="" || _file_eq(file_name, cm.file_name)) { 
            tag_get_detail(VS_TAGDETAIL_class_parents, cm.class_parents);
            tag_get_detail(VS_TAGDETAIL_file_line, auto file_line);
            if (file_line == cm.line_no || (cm.line_no==0 && cm.class_parents!="")) {
               if (cm.file_name=="") cm.file_name = file_name;
               if (cm.line_no==0)    cm.line_no = file_line;
               tag_reset_find_tag();
               return 0;
            }
         }
         // next please
         if (cm.type_name!="") {
            status = tag_next_tag(cm.member_name, cm.type_name, cm.class_name, cm.arguments);
         } else {
            status = tag_next_equal(true, cm.class_name);
         }
      }
      tag_reset_find_tag();

      // we found some match, just not on the expected line
      if (cm.class_parents != "") {
         cm.file_name = file_name;
         cm.tag_database = tag_current_db();
         return 0;
      }

      // next tag file please
      if ( tag_files == null ) break;
      if ( cm.tag_database != "" ) break;
      tag_filename = next_tag_filea(tag_files,i,false,true);
   }

   // restore the original tag file
   if (orig_tag_file != "") {
      tag_read_db(orig_tag_file);
   } 

   // no luck finding symbol
   return BT_RECORD_NOT_FOUND_RC;
}

void tag_get_info_from_return_type(VS_TAG_RETURN_TYPE &rt, VS_TAG_BROWSE_INFO &cm) 
{
   tag_init_tag_browse_info(cm);
   if (rt.taginfo == "") {
      return;
   }
   tag_decompose_tag_browse_info(rt.taginfo, cm); 
   cm.file_name = rt.filename;
   cm.line_no   = rt.line_number;
   cm.qualified_name = rt.return_type;
}

_str tag_get_tag_type_of_return_type(VS_TAG_RETURN_TYPE &rt, SETagFlags &tag_flags=SE_TAG_FLAG_NULL)
{
   if (rt.taginfo == "") {
      return "";
   }
   tag_decompose_tag_browse_info(rt.taginfo, auto cm);
   tag_flags = cm.flags;
   return cm.type_name;
}

int tag_get_context_inheritance(VS_TAG_BROWSE_INFO &cm, 
                                VS_TAG_RETURN_TYPE (&parents)[],
                                typeless tag_files,
                                VS_TAG_RETURN_TYPE (&visited):[]=null, 
                                int depth=0)
{
   already_exists := false;
   status := 0;
   temp_wid := orig_wid := 0;
   if (cm.file_name!="" && !_QBinaryLoadTagsSupported(cm.file_name)) {
      if (_chdebug) {
         isay(depth, "tag_get_context_inheritance: file="cm.file_name);
      }
      status = _open_temp_view(cm.file_name, 
                               temp_wid, orig_wid,
                               "", already_exists, false, true);
      if (status) {
         parents._makeempty();
         return status;
      }
      p_RLine = cm.line_no;
      if (cm.scope_seekpos != 0) {
         _GoToROffset(cm.scope_seekpos);
      }
   } else {
      temp_wid = 0;
   }

   // make sure the 'cm' has the class inheritance information
   status = tag_get_browse_inheritance(cm, tag_files);
   if (status && (cm.file_name!="") && cm.class_parents=="") {
      cm.file_name="";
      cm.line_no=0;
      tag_get_browse_inheritance(cm, tag_files);
   }
   if (_chdebug) {
      tag_browse_info_dump(cm, "tag_get_context_inheritance", depth);
   }

   // clear out the output array
   parents._makeempty();

   // convert the list of class parents to an array
   split(cm.class_parents, VS_TAGSEPARATOR_parents, auto class_parents);
   if (_chdebug) {
      isay(depth, "tag_get_context_inheritance: class_parents="cm.class_parents);
   }

   // for each parent class, parse it as a return type 
   n := class_parents._length();
   for (i:=0; i<n; ++i) {

      if (_isEditorCtl()) {
         _str errorArgs[];
         VS_TAG_RETURN_TYPE tmp_rt;
         tag_return_type_init(tmp_rt);
         isjava := _LanguageInheritsFrom("java", cm.language) ||
                   _LanguageInheritsFrom("cs", cm.language);

         status = _Embeddedparse_return_type(errorArgs, tag_files, 
                                             cm.member_name, cm.class_name, 
                                             cm.file_name, class_parents[i], 
                                             isjava, tmp_rt, visited, depth+1);
         if (!status) {
            parents[i] = tmp_rt;
            continue;
         }
      }

      if (_chdebug) {
         isay(depth+1, "tag_get_context_inheritance: parent["i"]="class_parents[i]);
      }
      status = tag_normalize_classes(class_parents[i], 
                                     cm.qualified_name, 
                                     cm.file_name,
                                     tag_files, false, true, 
                                     auto normalized_parent,
                                     auto normalized_type,
                                     auto normalized_file, 
                                     visited, depth+1);
      if (status) {
         continue;
      }

      parents[i].return_type = normalized_parent;
      parents[i].filename = normalized_file;
      tag_split_class_name(normalized_parent, auto tag_name, auto class_name);
      tag_init_tag_browse_info(auto temp_cm, tag_name, class_name, normalized_type);
      parents[i].taginfo = tag_compose_tag_browse_info(temp_cm);
   }

   if (temp_wid) {
      _delete_temp_view(temp_wid);
      activate_window(orig_wid);
   }

   return 0;
}

//////////////////////////////////////////////////////////////////////////////
// Customized function to get the parents of a class, fully qualified.
// This is currently our best approach to package name resolution.
// Utilizes find_class_in_tag_file() above to find the fully qualified
// class name and what tag file it belongs to.  This allows us to trace
// inheritance across multiple projects.
//
_str cb_get_normalized_inheritance(_str class_name,
                                   _str &in_tag_files,
                                   typeless &tag_files,
                                   bool check_context=false,
                                   _str orig_parents="",
                                   _str file_name="",
                                   _str &parent_types="",
                                   bool includeTemplateParameters=false,
                                   VS_TAG_RETURN_TYPE (&visited):[]=null, 
                                   int depth=0)
{
   if (_chdebug) {
      isay(depth, "cb_get_normalized_inheritance: orig_parents="orig_parents" class_name="class_name" file_name="file_name);
   }
   tag_init_tag_browse_info(auto cm);
   tag_split_class_name(class_name, cm.member_name, cm.class_name);
   cm.qualified_name = class_name;
   cm.class_parents = orig_parents;
   cm.file_name = file_name;
   in_tag_files = "";
   parent_types = "";

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   orig_db := tag_current_db();
   VS_TAG_RETURN_TYPE parents[] = null;
   status := tag_get_context_inheritance(cm, parents, tag_files, visited, depth+1);
   tag_read_db(orig_db);
   if (cm.class_parents=="") {
      return "";
   }

   class_parents := "";
   n := parents._length();
   for (i:=0; i<n; ++i) {
      _maybe_append(class_parents, VS_TAGSEPARATOR_parents);
      _maybe_append(parent_types, VS_TAGSEPARATOR_parents);
      _maybe_append(in_tag_files, ";");
//      _maybe_append_filesep(in_tag_files);
      if (parents[i] == null || parents[i].return_type == null) continue;
      class_parents :+= parents[i].return_type;
      if (includeTemplateParameters) {
         argName := "";
         _str argTypes[];
         foreach (argName in parents[i].template_names) {
            if (parents[i].template_types != null &&
                parents[i].template_types._indexin(argName) &&
                parents[i].template_types:[argName].return_type != "") {
               argTypes :+= tag_return_type_string(parents[i].template_types:[argName]);
            } else {
               argTypes :+= parents[i].template_args:[argName];
            }
         }
         argList := "";
         if (argTypes._length() > 0) {
            argList = "<":+join(argTypes,","):+">";
            class_parents:+=argList;
         }
      }

      parent_type_name := tag_get_tag_type_of_return_type(parents[i]);
      parent_types :+= parent_type_name;
      parent_tagfile := find_class_in_tag_file(cm.member_name, cm.class_name, auto qual_name, false, tag_files);
      in_tag_files :+= parent_tagfile;
   }

   if (class_parents != "") {
      return class_parents;
   }

   //say("cb_get_normalized_inheritance: class_name="class_name);
   found_definition := false;
   if (check_context && orig_parents=="") {
      type_name := "";
      inner_name := "";
      outer_name := "";
      tag_split_class_name(class_name, inner_name, outer_name);

      // check locals
      i = tag_find_local_iterator(inner_name, true, false, false, outer_name);
      while (i > 0) {
         //say("cb_get_normalized_inheritance: local");
         tag_get_detail2(VS_TAGDETAIL_local_type, i, type_name);
         if (tag_tree_type_is_class(type_name)) {
            found_definition = true;
            tag_get_detail2(VS_TAGDETAIL_local_parents, i, orig_parents);
            break;
         }
         i = tag_next_local_iterator(inner_name, i, true, false, false, outer_name);
      }

      // check context
      if (!found_definition) {
         i = tag_find_context_iterator(inner_name, true, false, false, outer_name);
         while (i > 0) {
            //say("cb_get_normalized_inheritance: context");
            tag_get_detail2(VS_TAGDETAIL_context_type, i, type_name);
            if (tag_tree_type_is_class(type_name)) {
               found_definition = true;
               tag_get_detail2(VS_TAGDETAIL_context_parents, i, orig_parents);
               break;
            }
            i = tag_next_context_iterator(inner_name, i, true, false, false, outer_name);
         }
      }
   }

   // get the list of parents from the database
   if (!found_definition && orig_parents=="") {
      tag_get_inheritance(class_name, orig_parents);
   }

   // start searching in the workspace tag file
   workspace_tag_database := workspace_tags_filename_only();
   if (workspace_tag_database!="") {
      tag_read_db(workspace_tag_database);
   }

   // this is better code
   normal_parents := "";
   status = tag_normalize_classes(orig_parents, class_name, file_name,
                                  tag_files, false, true,
                                  normal_parents, parent_types,
                                  in_tag_files, visited, depth+1);
   if (!status) {
      // here we go
      return normal_parents;
   }

   // for each parent
   new_parents := "";
   parent := "";
   in_tag_files="";
   while (orig_parents != "") {
      parse orig_parents with parent ";" orig_parents;
      if (parent != "") {

         // attempt to normalize the class name
         //say("cb_get_normalized_inheritance: parent="parent);
         normalized := "";
         parent_tag_file := find_class_in_tag_file(class_name, parent, normalized, true, tag_files);
         //say("cb_get_normalized_inheritance: normal="normalized);
         if (parent_tag_file=="") {
            parent_tag_file = find_class_in_tag_file(class_name, parent, normalized, true, tag_files, true);
            if (parent_tag_file=="") {
               normalized = parent;
               parent_tag_file = tag_current_db();
            }
         }

         // append to the new parent list
         if (new_parents == "") {
            new_parents  = normalized;
            in_tag_files = parent_tag_file;
         } else {
            new_parents  :+= ";" normalized;
            in_tag_files :+= ";" parent_tag_file;
         }
      }
   }

   return new_parents;
}

//////////////////////////////////////////////////////////////////////////////
// Return the filename name of the n'th tag file, and vice-versa
// p_window_id must be the symbol browser tree control.
//
//static _str get_tag_file_name(int i)
//{
//   int child = _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
//   while (child > 0) {
//      int sequence_number = _TreeGetUserInfo(child);
//      if (sequence_number == i) {
//         _str caption = _TreeGetCaption(child);
//         parse caption with . ":" file_name " (" .;
//         return absolute(strip(file_name));
//      }
//      child = _TreeGetNextSiblingIndex(child);
//   }
//   return "";
//}

//////////////////////////////////////////////////////////////////////////////
// Return the sequence number of the given tag file name.  If the given
// tag file is in the list twice, it will only return the first occurance.
// p_window_id must be the symbol browser tree control.
//
static int get_tag_file_number(_str &tag_file_name)
{
   child := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (child > 0) {
      caption := _TreeGetCaption(child);
      _str file_name;
      parse caption with . ":" file_name " (" .;
      file_name = absolute(strip(file_name));
      if (_file_eq(file_name, tag_file_name)) {
         return _TreeGetUserInfo(child);
      }
      child = _TreeGetNextSiblingIndex(child);
   }
   return 0;
}

//////////////////////////////////////////////////////////////////////////////
// Add the members inherited from all our parent classes.
// Uses the hash table (classes_visited) to mark which
// classes we have already visited.  This is done to circumvent the
// unusual case of circular references, a potential result of
// incorrect package name resolution.  This function is recursive, but
// limited to CB_MAX_INHERITANCE_DEPTH levels of recursion, limiting
// the amount of recursion we are willing to traverse.
// p_window_id must be the symbol browser tree control.
//
static int add_class_inherited(_str class_name, int depth,
                               int &count, typeless &tag_files,
                               _str class_parents,
                               _str search_file_name,
                               bool (&classes_visited):[]
                               )
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (depth >= CB_MAX_INHERITANCE_DEPTH) {
      return 0;
   }

   // check if we have visited this class already
   if (classes_visited._indexin(class_name)) return 0;
   classes_visited:[class_name]=true;

   // get the fully qualified parents of this class
   orig_tag_file := tag_current_db();
   tag_dbs := "";
   _str parents = cb_get_normalized_inheritance(class_name, tag_dbs, tag_files, 
                                                false, class_parents, search_file_name);

   // add each of them to the list also
   _str p1,t1;
   result := 0;
   while (parents != "") {
      parse parents with p1 ";" parents;
      parse tag_dbs with t1 ";" tag_dbs;
      int status = tag_read_db(t1);
      if (status < 0) {
         continue;
      }

      // add transitively inherited class members
      parse p1 with p1 "<" .;
      result = add_class_inherited(p1, depth+1, count, tag_files, "", "", classes_visited);

      // add the members inherited from the given class
      int tag_file_id = get_tag_file_number(t1);
      tag_tree_add_members_of(p1, "", tag_file_id, count);
   }

   // return to the original tag file and return, successful
   tag_read_db(orig_tag_file);
   return result;
}

//////////////////////////////////////////////////////////////////////////////
// If 'cm' is a prototype, attempt to locate it's corresponding definition
//
void maybe_convert_proto_to_proc(VS_TAG_BROWSE_INFO &cm, bool find_all_matches=false)
{
   search_cm := cm;
   const_flag := (search_cm.flags & SE_TAG_FLAG_CONST);
   found := false;
   VS_TAG_RETURN_TYPE visited:[];
   if ((search_cm.type_name:=="proto" || search_cm.type_name:=="procproto" || (search_cm.flags & SE_TAG_FLAG_FORWARD)) &&
       !(search_cm.flags & (SE_TAG_FLAG_NATIVE|SE_TAG_FLAG_ABSTRACT))) {
      search_arguments := VS_TAGSEPARATOR_args:+search_cm.arguments;
      search_class     := stranslate(search_cm.class_name,VS_TAGSEPARATOR_class,"::");

      if (tag_find_tag(search_cm.member_name, "proc", search_class, search_arguments)==0 ||
          tag_find_tag(search_cm.member_name, "func", search_class, search_arguments)==0 ||
          tag_find_tag(search_cm.member_name, "constr", search_class, search_arguments)==0 ||
          tag_find_tag(search_cm.member_name, "destr", search_class, search_arguments)==0) {
         tag_get_tag_browse_info(cm);
         if (find_all_matches && (cm.flags & SE_TAG_FLAG_CONST) == const_flag) {
            tag_insert_match_info(cm);
         }
         found=true;
      } else if (pos(VS_TAGSEPARATOR_package,search_class)) {
         search_class=substr(search_class,1,pos('S')-1):+
                       VS_TAGSEPARATOR_class:+
                       substr(search_class,pos('S')+1);
         if (tag_find_tag(search_cm.member_name, "proc", search_class, search_arguments)==0 ||
             tag_find_tag(search_cm.member_name, "func", search_class, search_arguments)==0 ||
             tag_find_tag(search_cm.member_name, "constr", search_class, search_arguments)==0 ||
             tag_find_tag(search_cm.member_name, "destr", search_class, search_arguments)==0) {
            tag_get_tag_browse_info(cm);
            if (find_all_matches && (cm.flags & SE_TAG_FLAG_CONST) == const_flag) {
               tag_insert_match_info(cm);
            }
            found=true;
         }
      }

      // find alternate matches until we locate proc with correct constness
      while (found && !tag_next_tag(search_cm.member_name, search_cm.type_name, search_cm.class_name, search_arguments)) {
         tag_get_tag_browse_info(cm);
         if ((cm.flags & SE_TAG_FLAG_CONST) == const_flag) {
            if (!find_all_matches) break;
            tag_insert_match_info(cm);
         }
      }
      tag_reset_find_tag();

      if (!found) {

         // put together list of tag files (just this tag file)
         _str tag_files[];
         tag_files[0] = search_cm.tag_database;

         // list of functions with this tag name in some class context
         _str errorArgs[];
         VS_TAG_BROWSE_INFO tag_matches[];

         // find all matching functions and populate 'tag_matches' array
         status := tag_find_equal(search_cm.member_name, true);
         while (status == 0 && tag_matches._length() < def_tag_max_function_help_protos) {
            tag_get_tag_browse_info(auto found_cm);
            if (tag_tree_type_is_func(found_cm.type_name) && 
                (!pos("proto",found_cm.type_name) && !(found_cm.flags & SE_TAG_FLAG_FORWARD)) && 
                found_cm.class_name!="") {
               if (tag_tree_compare_args(VS_TAGSEPARATOR_args:+found_cm.arguments, search_arguments, true)==0) {
                  tag_matches :+= found_cm;
               }
            }
            status = tag_next_equal(true);
         }
         tag_reset_find_tag();

         // For each match, evaluate it's class name as a return type
         // this will resolve typedefs, namespaces, namespace aliases.
         n := tag_matches._length();
         for (i:=0; i<n; ++i) {
            found_cm := tag_matches[i];
            VS_TAG_RETURN_TYPE rt; 
            tag_return_type_init(rt);

            orig_wid := p_window_id;
            temp_view_id := orig_view_id := 0;
            inmem := false;
            status=_open_temp_view(found_cm.file_name,temp_view_id,orig_view_id,"",inmem,false,true);
            if (!status) {
               // go to the specified line and evaluate the return type
               p_RLine = found_cm.line_no; 
               p_col = 1;
               rt_status := _Embeddedparse_return_type(errorArgs, tag_files, search_cm.member_name,
                                                       found_cm.class_name, found_cm.file_name, found_cm.class_name, 
                                                       false, rt, visited);

               // close the temporary view and restore the window and view id's.
               _delete_temp_view(temp_view_id);
               p_window_id=orig_view_id;
               p_window_id = orig_wid;

               // success?
               if (rt_status==0 && rt.return_type == search_cm.class_name) {
                  found = true;
                  if (!find_all_matches) break;
                  tag_insert_match_info(found_cm);
                  cm = found_cm;
               }

            }

            // break out of look as soon as we find a match
            if (found && !find_all_matches) {
               break;
            }
         }

         // restore the current tag database
         tag_read_db(search_cm.tag_database);
      }
   }

   // find all items matching this symbol which had duplicates removed
   // this is especially useful for package names
   if (find_all_matches && !tag_tree_type_is_func(search_cm.type_name)) {
      if (search_cm.category == null || search_cm.category == "") {
         search_cm.category = type_to_category(search_cm.type_name, search_cm.flags, false);
      }
      if (search_cm.category != null) {
         CB_TAG_CATEGORY *ctg = gh_cb_categories._indexin(search_cm.category);
         if (ctg && ctg->remove_duplicates) {
            search_arguments := VS_TAGSEPARATOR_args:+search_cm.arguments;
            search_class     := stranslate(search_cm.class_name,VS_TAGSEPARATOR_class,"::");
            if (tag_find_tag(search_cm.member_name, search_cm.type_name, search_class, search_arguments)==0) {
               tag_get_tag_browse_info(cm);
               if (find_all_matches) tag_insert_match_info(cm);
               found=true;
            } else if (pos(VS_TAGSEPARATOR_package,search_class)) {
               search_class=substr(search_class,1,pos('S')-1):+
                                   VS_TAGSEPARATOR_class:+
                                   substr(search_class,pos('S')+1);
               if (tag_find_tag(search_cm.member_name, search_cm.type_name, search_class, search_arguments)==0) {
                  tag_get_tag_browse_info(cm);
                  if (find_all_matches) tag_insert_match_info(cm);
                  found=true;
               }
            }

            // find alternate matches until we locate proc with correct constness
            while (found && !tag_next_tag(search_cm.member_name, search_cm.type_name, search_cm.class_name, search_arguments)) {
               tag_get_tag_browse_info(cm);
               if (!find_all_matches) break;
               tag_insert_match_info(cm);
            }
            tag_reset_find_tag();
         }
      }

   }

   if (find_all_matches && tag_get_num_of_matches() == 0) {
      tag_insert_match_info(search_cm);
      cm = search_cm;
   }

}

//////////////////////////////////////////////////////////////////////////////
// This is the timer callback.  Whenever the current index (cursor position)
// for the symbol browser tree is changed, a timer is started/reset.  If no
// activity occurs within a set amount of time, this function is called to
// update the properties view, inheritance view, and output window.
//
static void _ClassBrowserTimerCallback(_str cmdline)
{
   // kill the timer
   cb_kill_timer();

   // if something is going on, get out of here
   if( _IsKeyPending() ) {
      return;
   }
   parse cmdline with auto sform_wid auto sindex;
   f := (int)sform_wid;
   index := (int)sindex;
   if (!_iswindow_valid(f) || f.p_name!=TBCBROWSER_FORM) {
      return;
   }
   _nocheck _control ctl_class_tree_view;
   cbrowser_form := f;
   cbrowser_tree := f.ctl_class_tree_view;

   // get the details about the current selection
   currIndex := cbrowser_tree._TreeCurIndex();
   if (currIndex < 0) {
      return;
   }
   cbrowser_tree._TreeGetInfo(currIndex, auto show_children);
   parentIndex := 0;
   if (currIndex > 0) {
      parentIndex = cbrowser_tree._TreeGetParentIndex(currIndex);
   }

   if (!cbrowser_tree.get_user_tag_info(currIndex, auto cm, false)) {
      return;
   }

   // if something is going on, get out of here
   if( _IsKeyPending() ) {
      return;
   }

   // grab the window ID of the class tree view
   orig_wid := p_window_id;
   p_window_id = cbrowser_tree;

   // set flag to know we are in refresh code
   orig_refresh := gtbSymbolsFormList:[cbrowser_form].m_i_in_refresh;
   gtbSymbolsFormList:[cbrowser_form].m_i_in_refresh = 1;

   // refresh the property dialog if available
   cbrowser_form.cb_refresh_property_view(cm);

   // refresh the symbol arguments dialog if available
   cbrowser_form.cb_refresh_arguments_view(cm);

   // find the output tagwin and update it
   cb_refresh_output_tab(cm, true, true, false, APF_SYMBOLS);

   // find the output references tab and update it
   if (def_autotag_flags2 & AUTOTAG_UPDATE_CALLSREFS) {
      refresh_references_tab(cm);
   }

   // refresh the calls/uses dialog if available
   if (def_autotag_flags2 & AUTOTAG_UPDATE_CALLSREFS) {
      struct VS_TAG_BROWSE_INFO fcm = cm;
      if (cm.tag_database!="" && tag_read_db(cm.tag_database) >= 0) {
         maybe_convert_proto_to_proc(fcm);
      }
      cb_refresh_calltree_view(fcm);
      cb_refresh_callertree_view(fcm, expandChildren:false);
   }

   cm_status := 0;
   if (show_children == TREE_NODE_LEAF) {
      cm_status = cbrowser_tree.get_user_tag_info(parentIndex, cm, false);
   }

   // refresh the inheritance dialog if available
   if (cm_status > 0) {
      cb_refresh_inheritance_view(cbrowser_form,cm);
   }

   // restore the window ID
   gtbSymbolsFormList:[cbrowser_form].m_i_in_refresh = orig_refresh;
   p_window_id=orig_wid;
}

//////////////////////////////////////////////////////////////////////////////
// This is the timer callback.  Whenever the current index (cursor position)
// for the symbol browser tree is changed, a timer is started/reset.  If no
// activity occurs within a set amount of time, this function is called to
// update the properties view, inheritance view, and output window.
//
static void _ClassBrowserHighlightCallback(_str cmdline)
{
   // kill the timer
   cb_kill_timer_highlight();

   // if something is going on, get out of here
   if( _IsKeyPending() ) {
      return;
   }

   parse cmdline with auto sform_wid auto sindex;
   f := (int)sform_wid;
   index := (int)sindex;
   if (!_iswindow_valid(f) || f.p_name!=TBCBROWSER_FORM) {
      return;
   }

   _nocheck _control ctl_class_tree_view;

   // get the details about the current selection
   int currIndex = index;
   if (currIndex <= 0) {
      return;
   }

   f.ctl_class_tree_view._TreeGetInfo(currIndex, auto show_children);
   parentIndex := f.ctl_class_tree_view._TreeGetParentIndex(currIndex);

   if (!f.ctl_class_tree_view.get_user_tag_info(currIndex, auto cm, false)) {
      return;
   }

   // now update the preview window only
   _UpdateTagWindowDelayed(cm, def_tag_hover_delay);
}

//////////////////////////////////////////////////////////////////////////////
// Handle double-click event (mapped to goto-proc), unless the tree depth
// is less than or equal to two, in which case we simply call expand/collapse
//
void ctl_class_tree_view.enter,lbutton_double_click()
{
   // Is there a on_change timer event queued, then cancel it
   cb_kill_timer();
   cb_kill_timer_highlight();
   cb_kill_timer_options();

   // IF this is an item we can go to like a class name
   i := _TreeCurIndex();
   int d = (i<0)? 0:_TreeGetDepth(i);
   if (d > 2) {
      cb_goto_proc();
   } else if (i>=0) {
      show_children := 0;
      _TreeGetInfo(i,show_children);
      if (show_children == TREE_NODE_LEAF) {
         call_event(CHANGE_LEAF_ENTER,i,p_window_id,ON_CHANGE,'w');
      } else {
         call_event(show_children?CHANGE_COLLAPSED:CHANGE_EXPANDED,i,p_window_id,ON_CHANGE,'w');
         _TreeSetInfo(i,(int)!show_children);
      }
   }
}

//////////////////////////////////////////////////////////////////////////////
// Add the given category to the tree under its project index (j).
// If there are no global items appropriate for the category, do not
// add the category to the tree.  This function looks for any global with
// a type of either t1, t2, t3, or t4 where the mask evaluates to either
// zero or nzero, as requested.  Categories are inserted with a sequence
// number which they are sorted by.
// p_window_id must be the symbol browser tree control.
//
static void maybe_add_category(int j, _str category, CB_TAG_CATEGORY &ctg, int count)
{
   // change "includes/copy book" to just includes
   if (category :== CB_includesCB || category :== CB_includes) {
      int license1=_default_option(VSOPTION_PACKFLAGS1);
      if (!(license1&VSPACKFLAG1_COB) && !(license1&VSPACKFLAG1_ASM)) {
         if (category:==CB_includesCB) {
            return;
         }
      } else {
         if (category:==CB_includes) {
            return;
         }
      }
   }

   // miscellaneous is special
   int status;
   tag_flags := SE_TAG_FLAG_NULL;
   type_id   := SE_TAG_TYPE_NULL;
   _str type_name;
   _str cn;
   if (category :== CB_misc) {
      // try to find the item
      status=tag_find_global(-1, (int)ctg.flag_mask, (ctg.mask_nzero? 1:0));
      while (!status) {
         tag_get_detail(VS_TAGDETAIL_flags, tag_flags);
         tag_get_detail(VS_TAGDETAIL_type,  type_name);
         //say("maybe_add_category: type_name="type_name);
         cn = type_to_category(type_name, tag_flags, false);
         if (cn :== CB_misc) {
            j = _TreeAddItem(j, category, TREE_ADD_AS_CHILD, _pic_folder, _pic_folder, TREE_NODE_COLLAPSED, 0, ctg.sequence_number);
            tag_reset_find_in_class();
            return;
         }
         status=tag_next_global(-1, (int)ctg.flag_mask, (ctg.mask_nzero? 1:0));
      }
      tag_reset_find_in_class();
      return;
   }

   for (i:=0; i<ctg.tag_types._length(); i++) {
      // get the tag type, has to be either a string or an int
      // try to find the item with the given type
      t1 := ctg_type_to_type_id(ctg.tag_types[i]);
      status=tag_find_global(t1, (int)ctg.flag_mask, (ctg.mask_nzero? 1:0));
      if (status==0) {
         tag_get_detail(VS_TAGDETAIL_type_id, type_id);
         if (type_id == t1) {
            j = _TreeAddItem(j, category, TREE_ADD_AS_CHILD, _pic_folder, _pic_folder, TREE_NODE_COLLAPSED, 0, ctg.sequence_number);
            tag_reset_find_in_class();
            return;
         }
      }
   }
   tag_reset_find_in_class();
}

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
// Add all members in the global scope with the given type (t1), matching
// the mask as either zero or nzero, as specified.  This function will not
// insert more that CB_NOAHS_WATER_MARK items under a single category.
// During a refresh, it will stop inserting items after CB_LOW_WATER_MARK
// items are inserted.  During a user expand/collapse, it will stop inserting
// items after CB_HIGH_WATER_MARK items are inserted and prompt the user
// If the user does not cancel, it will continue inserting until it reaches
// CB_FLOOD_WATER_MARK items and every subsequent CB_FLOOD_WATER_MARK items.
// p_window_id must be the symbol browser tree control.
//
static void add_members_in_category(int j, _str ctg_name, CB_TAG_CATEGORY &ctg, _str letter, int &count)
{
   // Miscellaneous category is a very special case
   status := 0;
   pic_misc := 0;
   if (ctg_name :== CB_misc) {
      status=tag_find_global(-1, (int)ctg.flag_mask, (ctg.mask_nzero? 1:0));
      while (!status) {
         tag_get_tag_browse_info(auto cm);
         cn := type_to_category(cm.type_name, cm.flags, false);
         if (cn :== CB_misc) {
            file_id := 0;
            tag_get_detail(VS_TAGDETAIL_file_id, file_id);
            ucm := (file_id * CB_MAX_LINE_NUMBER) + cm.line_no;
            caption := tag_tree_make_caption_fast(VS_TAGMATCH_tag,0,true,true,true);
            pic_overlay := 0;
            if (pic_misc == 0) {
               pic_misc = tag_get_bitmap_for_type(SE_TAG_TYPE_MISCELLANEOUS, cm.flags, pic_overlay);
            }
            if (_TreeAddItem(j,caption,TREE_ADD_AS_CHILD|TREE_OVERLAY_BITMAP1,pic_overlay,pic_misc,TREE_NODE_LEAF,0,ucm) < 0) {
               break;
            }
         }
         status=tag_next_global(-1, (int)ctg.flag_mask, (ctg.mask_nzero? 1:0));
      }
      tag_reset_find_in_class();
      return;
   }

   for (i:=0; i<ctg.tag_types._length(); i++) {
      // get the tag type, has to be either a string or an int
      // add all items with this type to the category
      t1 := ctg_type_to_type_id(ctg.tag_types[i]);
      in_count := count;
      if (letter=="") {
         status = tag_tree_add_members_in_category(t1, (int)ctg.flag_mask, (ctg.mask_nzero? 1:0), ctg_name, in_count);
         count = in_count;
         //say("count = "in_count);
         if (status < 0) {
            _TreeSetCaption(j, ctg_name CB_delimiter CB_partial);
         } else if (status > 0) {
            // indicates that category was divided
            return;
         }
      } else {
         status = tag_tree_add_members_in_section(letter, t1, (int)ctg.flag_mask, (ctg.mask_nzero? 1:0), ctg_name, in_count);
         //say("count = "in_count);
         count = in_count;
         if (status < 0) {
            _TreeSetCaption(j, letter ": " ctg_name CB_delimiter CB_partial);
         }
      }
   }
}

//////////////////////////////////////////////////////////////////////////////
// pop up a message box warning that a huge number of items are about
// to be inserted into the symbol browser tree, giving the user the
// oportunity to terminate the operation.
//
int cb_warn_overflow(int t, int j, _str ctg_name, int count)
{
   int orig_autotag_flags = def_autotag_flags2;
   def_autotag_flags2=0;
   int status = _message_box(nls("Expanding a large number (%s) of items under '%s'.  Continue?", count, ctg_name), "", MB_YESNOCANCEL|MB_ICONQUESTION);
   def_autotag_flags2 = orig_autotag_flags;
   if (status!=IDYES) {
      count = CB_NOAHS_WATER_MARK;
      t._TreeSetCaption(j, ctg_name CB_delimiter CB_partial);
   }
   return count;
}

//////////////////////////////////////////////////////////////////////////////
// pop up a message box warning that we were unable to load the
// given DLL.  This is used in the BSC code, through a call to _post_call
// when we are unable for some reason to load msbsc50.dll.
//
void cb_warn_no_bsc(_str dll_name)
{
   int orig_autotag_flags = def_autotag_flags2;
   def_autotag_flags2=0;
   _message_box(nls("Unable to load Visual C++ 5.0 Browser DLL: %s",dll_name));
   def_autotag_flags2 = orig_autotag_flags;
}

//////////////////////////////////////////////////////////////////////////////
// pop up a message box warning that a huge number of items are about
// to be inserted into the symbol browser tree, giving the user the
// oportunity to terminate the operation.
//
int cb_divide_category(int t, int j, int type_id, int mask, int nzero, _str ctg_name)
{
   CB_TAG_CATEGORY *ctg = gh_cb_categories._indexin(ctg_name);
   if (ctg && ctg->level3_inheritance) {
      return -1;
   }

   // if we plan to remove duplicates, just do it,
   // but don't create categories
   if (ctg && ctg->remove_duplicates) {
      t._TreeSortCaption(j,'U');
      num_items := _TreeGetNumChildren(j);
      if (num_items < def_cbrowser_low_refresh intdiv 2) {
         return num_items;
      }
   }

   // letters to add, include '$' and '_' if there are tags like that
   alphabet := "A B C D E F G H I J K L M N O P Q R S T U V W X Y Z [Misc]";
   if (tag_find_prefix("$") == 0) {
      alphabet = "$ " alphabet;
   }
   if (tag_find_prefix("_") == 0) {
      alphabet = "_ " alphabet;
   }
   tag_reset_find_tag();

   // add the letters of the alphabet and 'misc'
   t._TreeDelete(j, 'C');
   t._TreeSetUserInfo(j, 0);
   while (alphabet != "") {
      _str letter;
      parse alphabet with letter alphabet;
      t._TreeAddItem(j, letter ": " ctg_name, TREE_ADD_AS_CHILD, _pic_folder, _pic_folder, TREE_NODE_COLLAPSED);
   }

   return 0;
}

//////////////////////////////////////////////////////////////////////////////
// Remove duplicate items under the given tree index (j).
// Assume that the items under 'f' have already been sorted by caption.
// p_window_id must be the symbol browser tree control.
//
//static void remove_duplicates_under(int f, int j)
//{
//   k = _TreeGetFirstChildIndex(j);
//   if (k > 0) {
//      kcap = _TreeGetCaption(k);
//      parse kcap with kcap CB_delimiter rest;
//      while (k > 0) {
//         m = _TreeGetNextSiblingIndex(k);
//         if (m > 0) {
//            mcap = _TreeGetCaption(m);
//            parse mcap with mcap CB_delimiter .;
//            if (kcap :== mcap) {
//               _TreeGetInfo(m, mshow);
//               if (mshow > 0) {
//                  _TreeDelete(k);
//               } else {
//                  _TreeDelete(m);
//                  m=k;
//               }
//            } else {
//               //messageNwait("retaining: "kcap);
//               kcap = mcap;
//            }
//         }
//         k=m;
//      }
//   }
//}

//////////////////////////////////////////////////////////////////////////////
// Possibly the most important function for the entire symbol browser.
// This function handles the on_change event for the symbol browser tree
// control.  What is done depends on the tree depth, current index, and
// the specific event, which includes the following:
//    CHANGE_EXPANDED:
//          0  -- refresh list of tag files
//          1  -- refresh set of categories for a tag file
//          2  -- refresh set of globals for a category
//          3+ -- refresh set of members in a class (container)
//    CHANGE_COLLAPSED:
//          0  -- should never happen
//          1  -- do nothing
//          2  -- trim "...PARTIAL LIST" off of categories
//          3+ -- do nothing
//    CHANGE_SELECTED:
//          3+ -- start timer for refreshing other views
//    CHANGE_LEAF_ENTER:
//          3+ -- goto definition for the selected item
//
void ctl_class_tree_view.on_change(int reason,int index)
{
   // context index for the selected item
   //say("ctl_class_tree_view.on_change: reason="reason" index="index);
   struct VS_TAG_BROWSE_INFO cm;
   int count,status;
   _str caption,full_caption,rest;

   // grab our window ID, this shouldn't be necessary
   f := _tbGetActiveSymbolsForm();
   if (!f) return;
   // blow out of here if index is invalid
   if (index < 0) {
      return;
   }

   // scrolling through list, kill the existing timer and start a new one
   if (reason == CHANGE_SELECTED) {
      cb_start_timer(p_active_form,_ClassBrowserTimerCallback);
      f.ctl_class_tree_view._TreeRefresh();

   } else if (reason == CHANGE_EXPANDED) {
      orig_wid := p_window_id;
      p_window_id = f.ctl_class_tree_view;
      
      // handled change_expanded event, show hour glass and prepare list
      se.util.MousePointerGuard hour_glass;
      d := _TreeGetDepth(index);

      // root level, list of tag files
      if (d == 0) {

         refresh_tagfiles();

      } else if (d == 1) {  // list of categories in a project

         // get tag details
         _TreeBeginUpdate(index, CB_delimiter);
         get_user_tag_info(index, cm, true);

         /**
          * For Eclipse, we want to make sure that the JDK tag file 
          * associated with the Project is the appropriate version. 
          *  
          * Calling _eclipse_update_tag_list here will take care of 
          * everything for us. 
          */
         if (isEclipsePlugin()) {
            eclipse_proj_name := _strip_filename(cm.tag_database, 'PE');
            _eclipse_update_tag_list(eclipse_proj_name);
         }

         // open the tag database for business
         status = tag_read_db(cm.tag_database);
         if ( status < 0 ) {
            if ( status==NEW_FILE_RC || status==FILE_NOT_FOUND_RC) {
               _message_box(nls("Tag file '%s' not found.\n\nIf you have tag files which were created before version 3.0 you need to rebuild them.",cm.tag_database));
            } else {
               _message_box(nls("Error reading tag file '%s'",cm.tag_database)". "get_message(status));
            }
            p_window_id = orig_wid;
            return;
         }

         count=1;
         typeless ctg_name;
         CB_TAG_CATEGORY ctg;
         for (ctg_name._makeempty();;) {
            gh_cb_categories._nextel(ctg_name);
            if (ctg_name._isempty()) break;
            if (ctg_name._varformat() == VF_LSTR) {
               ctg = gh_cb_categories._el(ctg_name);
               maybe_add_category(index, ctg_name, ctg, ++count);
            }
         }
         // p_window_id = f;
         //cb_remove_stale_items(index);
         _TreeEndUpdate(index);
         _TreeSortUserInfo(index, 'N');

      } else if (d == 2 || (d == 3 && f.ctl_class_tree_view._TreeGetUserInfo(index) == "")) {
         // list of globals in a category

         _TreeBeginUpdate(index, CB_delimiter);
         full_caption = _TreeGetCaption(index);
         letter := "";
         if (d == 3) {
            parse full_caption with letter ":" .;
         }
         parse full_caption with caption CB_delimiter .;
         if (full_caption :!= caption) {
            _TreeSetCaption(index, caption);
         }

         // get filtration mask
         int show_mask1, show_mask2;
         if (f.ctl_filter_check_box.p_value) {
            show_mask1 = CB_QUALIFIERS;
            show_mask2 = CB_QUALIFIERS2;
         } else {
            show_mask1 = f.ctl_class_tree_view.p_user;
            show_mask2 = f.ctl_filter_check_box.p_user;
         }
         // get tag details
         get_user_tag_info(index, cm, true);

         // open the database for business
         status = tag_read_db(cm.tag_database);
         if ( status < 0 ) {
            return;
         }

         gtbSymbolsFormList:[f].m_z_class_filter  = f.ctl_class_filter_combo_box.cb_get_filter();
         gtbSymbolsFormList:[f].m_z_member_filter = f.ctl_member_filter_combo_box.cb_get_filter();

         count = 0;
         tag_tree_prepare_expand(f, index, p_window_id, 
                                 gtbSymbolsFormList:[f].m_i_in_refresh, 
                                 gtbSymbolsFormList:[f].m_z_class_filter, 
                                 gtbSymbolsFormList:[f].m_z_member_filter, 
                                 gz_exception_name, 
                                 show_mask1, null, show_mask2);

         CB_TAG_CATEGORY *ctg = gh_cb_categories._indexin(cm.category);
         if (ctg) {
            add_members_in_category(index, cm.category, *ctg, letter, count);
         }

         _TreeEndUpdate(index);
         if (ctg && ctg->remove_duplicates) {
            _TreeSortCaption(index,'U');
            //remove_duplicates_under(gtbcbrowser_wid, index);
         }
         _TreeSortCaption(index,'I','N');

         // remove duplicates if there are "EMPTY" or "PARTIAL" items
         if (ctg && ctg->remove_duplicates) {
            one_caption := dup_caption := "";
            dup_index := 0;
            one_index := _TreeGetFirstChildIndex(index);
            if (one_index > 0) {
               one_caption = _TreeGetCaption(one_index);
               for (;;) {
                  dup_index = _TreeGetNextSiblingIndex(one_index);
                  if (dup_index <= 0) {
                     break;
                  }
                  dup_caption = _TreeGetCaption(dup_index);
                  parse dup_caption with dup_caption CB_delimiter .;
                  if (one_caption == dup_caption) {
                     _TreeDelete(one_index);
                  }
                  one_caption = dup_caption;
                  one_index   = dup_index;
               }
            }
         }

      } else { // list of members of a class/container

         _TreeBeginUpdate(index, CB_delimiter);
         full_caption = _TreeGetCaption(index);
         parse full_caption with caption CB_delimiter .;
         if (full_caption :!= caption) {
            _TreeSetCaption(index, caption);
         }

         // get tag details
         get_user_tag_info(index, cm, false);
         //say("ctl_class_tree_view.on_change: cat="cm.category" cn="cm.class_name" file="cm.file_name" name="cm.member_name" qual="cm.qualified_name" db="cm.tag_database);

         // open the database for business
         status = tag_read_db(cm.tag_database);
         if ( status < 0 ) {
            return;
         }
         _str search_file_name = cm.file_name;
         if (cm.flags & SE_TAG_FLAG_PARTIAL) {
            search_file_name = "";
         }

         // expanding a package
         remove_duplicates := false;
         if (d == 3 && cm.category :== CB_packages) {
            search_file_name = "";
            remove_duplicates=true;
         } else if (d == 4 && cm.category :== CB_packages &&
                    f.ctl_class_tree_view._TreeGetUserInfo(_TreeGetParentIndex(index)) == "") {
            search_file_name = "";
            d=(d-1);
            remove_duplicates=true;
         } else if (tag_tree_type_is_package(cm.type_name)) {
            search_file_name = "";
            d=3;
            remove_duplicates=true;
         }

         // Check for partial class, remove duplicates under it
         if (tag_tree_type_is_class(cm.type_name) && (cm.flags & SE_TAG_FLAG_PARTIAL)) {
            search_file_name = "";
            remove_duplicates=true;
         }

         // inheritance make sense at this level
         has_inherited_members := false;
         if ((d==3 && gh_cb_categories:[cm.category].level3_inheritance) ||
             (d==4 && gh_cb_categories:[cm.category].level4_inheritance) || (d >= 5)) {
            has_inherited_members=true;
         }

         // grab bit flags and filtering options
         int show_mask1, show_mask2;
         if (f.ctl_filter_check_box.p_value) {
            show_mask1 = CB_QUALIFIERS;
            show_mask2 = CB_QUALIFIERS2;
         } else {
            show_mask1 = f.ctl_class_tree_view.p_user;
            show_mask2 = f.ctl_filter_check_box.p_user;
         }
         gtbSymbolsFormList:[f].m_z_class_filter  = f.ctl_class_filter_combo_box.cb_get_filter();
         gtbSymbolsFormList:[f].m_z_member_filter = f.ctl_member_filter_combo_box.cb_get_filter();

         count=0;
         tag_tree_prepare_expand(f, index, p_window_id, 
                                 gtbSymbolsFormList:[f].m_i_in_refresh, 
                                 gtbSymbolsFormList:[f].m_z_class_filter, 
                                 gtbSymbolsFormList:[f].m_z_member_filter, 
                                 gz_exception_name, 
                                 show_mask1, null, show_mask2);

         // get the inherited class members
         if ((show_mask1 & CB_SHOW_inherited_members) && has_inherited_members) {
            _str lang = _Filename2LangId(cm.file_name);
            typeless tag_files = tags_filenamea(lang);
            int k=add_class_inherited(cm.qualified_name, 0, count, tag_files, 
                                      cm.class_parents, search_file_name, 
                                      auto classes_visited);
         }

         // get the class methods
         if ((show_mask1 & CB_SHOW_class_members) || !has_inherited_members) {
            // get user info indicating tag file name for our parent
            // this takes care of the case that we are inserting children
            // of a structure that was inherited from a different tag file
            tag_file_id := 0;
            typeless v = _TreeGetUserInfo(index);
            if (v._varformat()==VF_LSTR && isinteger(v)) {
               tag_file_id = (v intdiv (CB_MAX_LINE_NUMBER*CB_MAX_FILE_NUMBER));
            }

            // insert all the tags for this class, applying filtering
            orig_count := count;
            status = tag_tree_add_members_of(cm.qualified_name, search_file_name, tag_file_id, count);

            // Look for items in slightly altered class name (package vs class separator)
            qname := cm.qualified_name;
            while ((status || count==orig_count) && pos(VS_TAGSEPARATOR_package, qname)) {
               lp := lastpos(VS_TAGSEPARATOR_package, qname);
               qname = substr(qname,1,lp-1):+VS_TAGSEPARATOR_class:+substr(qname,lp+1);
               status = tag_tree_add_members_of(qname, "", tag_file_id, count);
            }

            //say("tag_tree_add_members_of("cm.qualified_name","search_file_name")="status);
            if (status < 0) {
               caption = _TreeGetCaption(index);
               _str rpart;
               parse caption with rpart "\t" rest;
               _TreeSetCaption(index, rpart CB_delimiter CB_partial "\t" rest);
            }
         }

         // remove the unneeded items
         //cb_remove_stale_items(index);
         _TreeEndUpdate(index);
         _str P=(gi_sort_float_to_top)? "P":"";
         if (gi_sort_by_line && search_file_name!="") {
            _TreeSortUserInfo(index,'N'P, 'I');
         } else {
            _TreeSortCaption(index,'I'P,'N');
         }

         // remove duplicates if we are expanding a nested package or namespace
         if (remove_duplicates) {
            one_caption := dup_caption := "";
            dup_index := 0;
            one_index := _TreeGetFirstChildIndex(index);
            if (one_index > 0) {
               one_caption = _TreeGetCaption(one_index);
               for (;;) {
                  dup_index = _TreeGetNextSiblingIndex(one_index);
                  if (dup_index <= 0) {
                     break;
                  }
                  dup_caption = _TreeGetCaption(dup_index);
                  parse dup_caption with dup_caption CB_delimiter .;
                  if (one_caption == dup_caption) {
                     if (_TreeGetNumChildren(dup_index) == 0) {
                        _TreeDelete(dup_index);
                        continue;
                     }
                     _TreeDelete(one_index);
                  }
                  one_caption = dup_caption;
                  one_index   = dup_index;
               }
            }
         }
      }

      // if after expanding, the item is still empty, then add ...EMPTY to the caption
      // otherwise remove ...EMPTY if present.
      if (d >= 2) {
         caption = _TreeGetCaption(index);
         child := _TreeGetFirstChildIndex(index);
         if (child <= 0) {
            if (!pos(CB_delimiter:+CB_empty, caption)) {
               parse caption with caption "\t" rest;
               parse caption with caption CB_delimiter . ;
               caption :+= CB_delimiter :+ CB_empty;
               if (rest != "") {
                  caption :+= "\t" rest;
               }
               _TreeSetCaption(index, caption);
            }
         } else if (pos(CB_delimiter:+CB_empty, caption)) {
            parse caption with caption "\t" rest ;
            parse caption with caption CB_delimiter . ;
            if (rest != "") {
               caption :+= "\t" rest;
            }
            _TreeSetCaption(index, caption);
         }
      }

      _TreeSizeColumnToContents(0);
      p_window_id = orig_wid;

      //_message_box("number of items = "_TreeGetNumChildren(index));

   } else if (reason == CHANGE_COLLAPSED) {

      se.util.MousePointerGuard hour_glass;
      orig_wid := p_window_id;
      p_window_id = f.ctl_class_tree_view;

      // remove the "PARTIAL LIST" from category captions on collapsation
      int d = _TreeGetDepth(index);
      full_caption = _TreeGetCaption(index);
      parse full_caption with caption "\t" rest;
      parse caption      with caption CB_delimiter .;
      if (rest!="") {
         caption :+= "\t"rest;
      }
      if (full_caption :!= caption) {
         _TreeSetCaption(index, caption);
      }
      // remove all leaves under this node
      _TreeDelete(index, 'L');
      p_window_id = orig_wid;

   } else if (reason == CHANGE_LEAF_ENTER) {
      // look up this item and then display in buffer
      if (f.ctl_class_tree_view.get_user_tag_info(index, cm, false)) {
         if (push_tag_in_file(cm.member_name, cm.file_name, cm.class_name, cm.type_name, cm.line_no)) {
            return;
         }
      }
   }
}

void ctl_class_tree_view.on_highlight(int index, _str caption="")
{
   //say("ctl_class_tree_view.on_highlight: index="index" caption="caption);
   cb_kill_timer_highlight();
   if (!def_tag_hover_preview) return;
   if (index < 0) {
      _UpdateTagWindowDelayed(null,0);
      return;
   }
   cb_start_timer_highlight(p_active_form,_ClassBrowserHighlightCallback, index, def_tag_hover_delay);
}

//////////////////////////////////////////////////////////////////////////////
// set up for an expand operation (external entry point)
//
void cb_prepare_expand(int formWID, int treeWID, int index)
{
   tag_tree_prepare_expand(formWID, index, treeWID, 0, "", "", "", 0, null, CB_QUALIFIERS2);
}

//////////////////////////////////////////////////////////////////////////////
// Update other views when viewer gets focus, important because
// inheritance view, call tree, and props can also update the output
// view, so if they return focus to the symbol browser, we need to
// restart the update timer.
//
void _tbcbrowser_form.on_got_focus()
{
   if (!_find_control("ctl_class_tree_view")) {
      return;
   }
   /*if (isEclipsePlugin()) {
      classesOutputContainer := _tbGetActiveSymbolsForm();
      if(!classesOutputContainer) return;
      old_wid = p_window_id;
      p_window_id = classesOutputContainer;
   } */
   // refresh tag files
   if (gtbSymbolsFormList:[p_active_form].m_i_need_refresh) {
      orig_refresh := gtbSymbolsFormList:[p_active_form].m_i_in_refresh;
      gtbSymbolsFormList:[p_active_form].m_i_in_refresh = 1;
      ctl_class_tree_view.refresh_tagfiles();
      ctl_class_tree_view.refresh_dialog_views();
      gtbSymbolsFormList:[p_active_form].m_i_in_refresh = orig_refresh;
   }

   cb_start_timer(p_active_form,_ClassBrowserTimerCallback);
   /*if (isEclipsePlugin()) {
      p_window_id = old_wid;
   } */
}

void _tbcbrowser_form.on_change(int reason)
{
   if (reason==CHANGE_AUTO_SHOW ) {
      tree_wid := _find_control("ctl_class_tree_view");
      if (tree_wid) {
         if (gtbSymbolsFormList:[p_active_form].m_i_need_refresh) {
            orig_refresh := gtbSymbolsFormList:[p_active_form].m_i_in_refresh;
            gtbSymbolsFormList:[p_active_form].m_i_in_refresh = 1;
            ctl_class_tree_view.refresh_tagfiles();
            ctl_class_tree_view.refresh_dialog_views();
            gtbSymbolsFormList:[p_active_form].m_i_in_refresh = orig_refresh;
         }
      }
   }
}

//////////////////////////////////////////////////////////////////////////////
// Handle spacebar press in class tree.  This is intended to goto the
// exact item at the current index.
//
void ctl_class_tree_view." "()
{
   orig_window_id := p_window_id;
   k := ctl_class_tree_view._TreeCurIndex();
   if (ctl_class_tree_view.get_user_tag_info(k, auto cm, false)) {
      push_tag_in_file(cm.member_name, cm.file_name, cm.class_name, cm.type_name, cm.line_no);
   }
   p_window_id = orig_window_id;
   ctl_class_tree_view._set_focus();
}

//////////////////////////////////////////////////////////////////////////////
// Push a bookmark and open the given file and position the cursor on the
// given line/column
//
int push_pos_in_file(_str file_name, int line_no, int col_no)
{
   // no MDI children?
   mark := -1;
   if (!_no_child_windows()) {
      // get a bookmark
      mark=_alloc_selection('b');
      if ( mark<0 ) {
         return(mark);
      }
      _mdi.p_child._select_char(mark);
      _mdi.p_child.mark_already_open_destinations();
   }

   // try to open the file
   int status = edit(_maybe_quote_filename(file_name),EDIT_DEFAULT_FLAGS);
   if (status) {
      if (mark >= 0) {
         _free_selection(mark);
      }
      return(status);
   }

   // jump to the line
   goto_line(line_no);
   goto_col(0);

   // make sure the line is not hidden
   if (_lineflags() & HIDDEN_LF) {
      expand_line_level();
   }

   // push the bookmark
   if (mark >= 0) {
      _mdi.p_child.push_destination();
      _mdi.p_child.push_bookmark(mark);
   }
   return 0;
}

//////////////////////////////////////////////////////////////////////////////
// Push a bookmark and delegate to _cb_goto_tag_in_file() to open the given
// file and position the cursor on the given proc/class/type as near to
// the given line number as possible.
//
int push_tag_in_file(_str proc_name, _str file_name, _str class_name, _str type_name, int line_no)
{
   // check if there is a load-tags function, if so, bail out
   if (_QBinaryLoadTagsSupported(file_name)) {
      _message_box(nls("Can not locate source code for %s.",file_name));
      return(1);
   }

   // no MDI children?
   status := 0;
   if (_no_child_windows()) {
      status = _cb_goto_tag_in_file(proc_name, file_name, class_name, type_name, line_no);
      if (!status && (_mdi.p_child._lineflags() & HIDDEN_LF)) {
         _mdi.p_child.expand_line_level();
      }
      return status;
   }

   // get a bookmark
   _mdi.p_child.mark_already_open_destinations();
   int mark=_alloc_selection('b');
   if ( mark<0 ) {
      return(mark);
   }
   _mdi.p_child._select_char(mark);

   // try to open the file
   status=_cb_goto_tag_in_file(proc_name, file_name, class_name, type_name, line_no);
   if (status) {
      _free_selection(mark);
      return status;
   }

   // make sure the line is not hidden
   if (_mdi.p_child._lineflags() & HIDDEN_LF) {
      _mdi.p_child.expand_line_level();
   }

   // push the bookmark
   _mdi.p_child.push_destination();
   return(_mdi.p_child.push_bookmark(mark));
}

//////////////////////////////////////////////////////////////////////////////
// Using up-to-date context info, find the nearest matching tag with the
// given class name and type name as close as possible to the given line
// number.  If no such match is found, relax the search to just the given
// proc_name.  If that match is not found, alert the user that the tag
// was not found.
//
int _cb_goto_tag_in_file(_str proc_name, _str file_name, _str class_name, _str type_name, int line_no,bool file_already_active=false, _str file_lang="")
{
   // Note that the [ext]_proc_search code in cparse and dparse always
   // goes to column one for non proc type identifiers.
   closed_col := 1;
   int closest_line_no = CB_MAX_LINE_NUMBER;

   // watch out for non-existent file name
   if (file_name == "") {
      return(FILE_NOT_FOUND_RC);
   }

   // break file name down into filename / included-by components
   parse file_name with file_name "\1" auto file_included_by;

   // check if there is a load-tags function, if so, bail out
   if (_QBinaryLoadTagsSupported(file_name)) {
      message(nls("Can not locate source code for %s.",file_name));
      return(1);
   }
   if (!file_already_active) {
      // try to open the file
      int status = edit(_maybe_quote_filename(file_name),EDIT_DEFAULT_FLAGS);
      if (status) {
         return status;
      }
   }

   // check if tagging is even supported for this file
   if (! _istagging_supported(p_LangId) ) {
      // Be lazy and don't close edited buffer
      if (!file_already_active && file_lang != "" && p_LangId=="fundamental" && _istagging_supported(file_lang)) {
         message(nls("Setting language mode to '%s'",file_lang));
         _SetEditorLanguage(file_lang);
      }
      if (! _istagging_supported(p_LangId) ) {
         message(nls("No tagging support function for extension '%s'",_get_extension(file_name)));
         return(1);
      }
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   seekpos := (int)_QROffset();

   // update the current context and locals for this file
   save_pos(auto p);
   _UpdateContext(true,true);
   _UpdateLocals(true,true);
   
   context_id := tag_current_context();
   case_sensitive := p_EmbeddedCaseSensitive;

   // see if it is found in locals
   local_found := false;
   int i,i_class_name,i_type_name,i_line_no,i_seekpos;
   closest_col := 1;
   if (context_id>0) {
      i = tag_find_local_iterator(proc_name, true, case_sensitive);
      while (i > 0) {
         // get class and type for checking
         tag_get_detail2(VS_TAGDETAIL_local_class, i, i_class_name);
         tag_get_detail2(VS_TAGDETAIL_local_type,  i, i_type_name);
         if ((type_name =="" || type_name ==i_type_name) &&
             (class_name=="" || class_name==i_class_name)) {
            // get line number and seekpos
            tag_get_detail2(VS_TAGDETAIL_local_start_linenum, i, i_line_no);
            tag_get_detail2(VS_TAGDETAIL_local_start_seekpos, i, i_seekpos);

            p_RLine=i_line_no;
            _GoToROffset(i_seekpos);
            if (abs(p_RLine-line_no) < abs(closest_line_no-line_no)) {
               closest_line_no = p_RLine;
               closest_col=p_col;
            }
            if (p_RLine == line_no) {
               if (!p_IsTempEditor) {
                  if (_lineflags() & HIDDEN_LF) expand_line_level();
                  center_line();
               }
               return(0);  // got it.
            }
         }
         i = tag_next_local_iterator(proc_name, i, true, case_sensitive);
      }
   }

   // see if it is found in context
   i = tag_find_context_iterator(proc_name, true, case_sensitive);
   while (i > 0) {
      // get class and type for checking
      tag_get_detail2(VS_TAGDETAIL_context_class, i, i_class_name);
      tag_get_detail2(VS_TAGDETAIL_context_type,  i, i_type_name);
      if ((type_name =="" || type_name ==i_type_name) &&
          (class_name=="" || tag_compare_classes(class_name, i_class_name, p_LangCaseSensitive)==0)) {
         // get line number and seekpos
         tag_get_detail2(VS_TAGDETAIL_context_start_linenum, i, i_line_no);
         tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, i, i_seekpos);

         p_RLine=i_line_no;
         _GoToROffset(i_seekpos);
         if (abs(p_RLine-line_no) < abs(closest_line_no-line_no)) {
            closest_line_no = p_RLine;
            closest_col=p_col;
         }
         if (p_RLine == line_no) {
            if (!p_IsTempEditor) {
               if (_lineflags() & HIDDEN_LF) expand_line_level();
               center_line();
            }
            return(0);  // got it.
         }
      }
      i = tag_next_context_iterator(proc_name, i, true, case_sensitive);
   }
   // special case for cobol copy books (.cpy)
   if (type_name=="include" && line_no==1 &&
       closest_line_no==CB_MAX_LINE_NUMBER) {
      closest_line_no=1;
   }

   if (closest_line_no == CB_MAX_LINE_NUMBER) {
      long_msg := ".  ";//:+  'nls('You may want to rebuild the tag file.');
      _message_box(get_message(VSCODEHELPRC_NO_SYMBOLS_FOUND, proc_name):+long_msg);
      restore_pos(p);
      return(1);
   }

   restore_pos(p);
   p_col=closest_col;
   goto_line(closest_line_no);
   if (!p_IsTempEditor) {
      if (_lineflags() & HIDDEN_LF) expand_line_level();
      center_line();
   }
   return(0);
}


//############################################################################
//////////////////////////////////////////////////////////////////////////////
// handlers for symbol browser options form
//
defeventtab _cboptions_form;

//////////////////////////////////////////////////////////////////////////////
// Set p_value for the given check box (as current object) depending on
// the settings of the given big masks.
//
static void set_filter_check_box(int show_mask, int on_bit, int off_bit)
{
   if (show_mask & on_bit) {
      p_value = (show_mask & off_bit)? 2/*don't care*/ : 1/*on*/;
   } else {
      p_value = 0/*off*/;
   }
}

//////////////////////////////////////////////////////////////////////////////
// Refresh the symbol browser options view.  Retrieve stored symbol browser
// options and set the controls in the symbol browser options dialog to
// correspond with current operating parameters.
//
static void refresh_filter_options(int show_mask1, int show_mask2)
{
   // bits in first SHOW mask
   ctl_show_static_data.set_filter_check_box(show_mask1, CB_SHOW_class_data, CB_SHOW_instance_data);
   ctl_show_data_members.set_filter_check_box(show_mask1, CB_SHOW_data_members, CB_SHOW_other_members);
   ctl_show_inline.set_filter_check_box(show_mask1, CB_SHOW_inline, CB_SHOW_out_of_line);
   ctl_show_static.set_filter_check_box(show_mask1, CB_SHOW_static, CB_SHOW_non_virtual);
   ctl_show_virtual.set_filter_check_box(show_mask1, CB_SHOW_virtual, CB_SHOW_non_virtual);
   ctl_show_abstract.set_filter_check_box(show_mask1, CB_SHOW_abstract, CB_SHOW_non_abstract);
   ctl_show_operators.set_filter_check_box(show_mask1, CB_SHOW_operators, CB_SHOW_non_special);
   ctl_show_constructors.set_filter_check_box(show_mask1, CB_SHOW_constructors, CB_SHOW_non_special);
   ctl_show_final_members.set_filter_check_box(show_mask1, CB_SHOW_final_members, CB_SHOW_non_final_members);
   ctl_show_const_members.set_filter_check_box(show_mask1, CB_SHOW_const_members, CB_SHOW_non_const_members);
   ctl_show_volatile_members.set_filter_check_box(show_mask1, CB_SHOW_volatile_members, CB_SHOW_non_volatile_members);
   ctl_show_transient_members.set_filter_check_box(show_mask1, CB_SHOW_transient_data, CB_SHOW_persistent_data);
   ctl_show_synchronized_members.set_filter_check_box(show_mask1, CB_SHOW_synchronized, CB_SHOW_non_synchronized);
   ctl_show_template_classes.set_filter_check_box(show_mask1, CB_SHOW_template_classes, CB_SHOW_non_template_classes);
   ctl_show_inherited_members.set_filter_check_box(show_mask1, CB_SHOW_inherited_members, CB_SHOW_class_members);

   // bits in second SHOW mask
   ctl_show_preprocessing.set_filter_check_box(show_mask2, CB_SHOW_macros, CB_SHOW_non_macros);
   ctl_show_native.set_filter_check_box(show_mask2, CB_SHOW_native, CB_SHOW_non_native);
   ctl_show_extern.set_filter_check_box(show_mask2, CB_SHOW_extern, CB_SHOW_non_extern);
   ctl_show_anonymous.set_filter_check_box(show_mask2, CB_SHOW_anonymous, CB_SHOW_non_anonymous);

   // set package, private, public, public members on/off
   ctl_show_package_members.p_value   = (show_mask1 & CB_SHOW_package_members)?   1:0;
   ctl_show_private_members.p_value   = (show_mask1 & CB_SHOW_private_members)?   1:0;
   ctl_show_public_members.p_value    = (show_mask1 & CB_SHOW_public_members)?    1:0;
   ctl_show_protected_members.p_value = (show_mask1 & CB_SHOW_protected_members)? 1:0;
}

//////////////////////////////////////////////////////////////////////////////
// Gets the filtering flags from the options dialog.
//    show_mask1 -- bit mask for show options (see CB_SHOW_*, above)
//    show_mask2 -- more show options
// p_window_id must be the options dialog form window ID.
//
static void get_filter_options(int &show_mask1, int &show_mask2)
{
   show_mask1 = show_mask2 = 0;

   if (ctl_show_static_data.p_value>=1) {          show_mask1 |= CB_SHOW_class_data;           }
   if (ctl_show_static_data.p_value!=1) {          show_mask1 |= CB_SHOW_instance_data;        }
   if (ctl_show_data_members.p_value>=1) {         show_mask1 |= CB_SHOW_data_members;         }
   if (ctl_show_data_members.p_value!=1) {         show_mask1 |= CB_SHOW_other_members;        }
   if (ctl_show_inline.p_value!=1) {               show_mask1 |= CB_SHOW_out_of_line;          }
   if (ctl_show_inline.p_value>=1) {               show_mask1 |= CB_SHOW_inline;               }
   if (ctl_show_static.p_value>=1) {               show_mask1 |= CB_SHOW_static;               }
   if (ctl_show_virtual.p_value>=1) {              show_mask1 |= CB_SHOW_virtual;              }
   if (ctl_show_abstract.p_value>=1) {             show_mask1 |= CB_SHOW_abstract;             }
   if (ctl_show_abstract.p_value!=1) {             show_mask1 |= CB_SHOW_non_abstract;         }
   if (ctl_show_operators.p_value>=1) {            show_mask1 |= CB_SHOW_operators;            }
   if (ctl_show_constructors.p_value>=1) {         show_mask1 |= CB_SHOW_constructors;         }
   if (ctl_show_final_members.p_value!=1) {        show_mask1 |= CB_SHOW_non_final_members;    }
   if (ctl_show_final_members.p_value>=1) {        show_mask1 |= CB_SHOW_final_members;        }
   if (ctl_show_const_members.p_value!=1) {        show_mask1 |= CB_SHOW_non_const_members;    }
   if (ctl_show_const_members.p_value>=1) {        show_mask1 |= CB_SHOW_const_members;        }
   if (ctl_show_volatile_members.p_value!=1) {     show_mask1 |= CB_SHOW_non_volatile_members; }
   if (ctl_show_volatile_members.p_value>=1) {     show_mask1 |= CB_SHOW_volatile_members;     }
   if (ctl_show_synchronized_members.p_value!=1) { show_mask1 |= CB_SHOW_non_synchronized;     }
   if (ctl_show_synchronized_members.p_value>=1) { show_mask1 |= CB_SHOW_synchronized;         }
   if (ctl_show_transient_members.p_value!=1) {    show_mask1 |= CB_SHOW_persistent_data;      }
   if (ctl_show_transient_members.p_value>=1) {    show_mask1 |= CB_SHOW_transient_data;       }
   if (ctl_show_template_classes.p_value!=1) {     show_mask1 |= CB_SHOW_non_template_classes; }
   if (ctl_show_template_classes.p_value>=1) {     show_mask1 |= CB_SHOW_template_classes;     }
   if (ctl_show_package_members.p_value) {         show_mask1 |= CB_SHOW_package_members;      }
   if (ctl_show_private_members.p_value) {         show_mask1 |= CB_SHOW_private_members;      }
   if (ctl_show_protected_members.p_value) {       show_mask1 |= CB_SHOW_protected_members;    }
   if (ctl_show_public_members.p_value) {          show_mask1 |= CB_SHOW_public_members;       }
   if (ctl_show_inherited_members.p_value>=1) {    show_mask1 |= CB_SHOW_inherited_members;    }
   if (ctl_show_inherited_members.p_value!=1) {    show_mask1 |= CB_SHOW_class_members;        }

   if (ctl_show_extern.p_value>=1) {               show_mask2 |= CB_SHOW_extern;               }
   if (ctl_show_extern.p_value!=1) {               show_mask2 |= CB_SHOW_non_extern;           }
   if (ctl_show_native.p_value>=1) {               show_mask2 |= CB_SHOW_native;               }
   if (ctl_show_native.p_value!=1) {               show_mask2 |= CB_SHOW_non_native;           }
   if (ctl_show_preprocessing.p_value>=1) {        show_mask2 |= CB_SHOW_macros;               }
   if (ctl_show_preprocessing.p_value!=1) {        show_mask2 |= CB_SHOW_non_macros;           }
   if (ctl_show_anonymous.p_value>=1) {            show_mask2 |= CB_SHOW_anonymous;            }
   if (ctl_show_anonymous.p_value!=1) {            show_mask2 |= CB_SHOW_non_anonymous;        }

   // Turn on non-virtual provided neither virtual-only or static-only are set
   if (ctl_show_static.p_value!=1 && ctl_show_virtual.p_value!=1) {
       show_mask1 |= CB_SHOW_non_virtual;
   }
   // Turn off virtual/static if the other is set
   if (ctl_show_static.p_value==1 && ctl_show_virtual.p_value==2) {
      show_mask1 &= ~CB_SHOW_virtual;
   }
   if (ctl_show_static.p_value==2 && ctl_show_virtual.p_value==1) {
      show_mask1 &= ~CB_SHOW_static;
   }

   // Turn on non-virtual provided neither virtual-only or static-only are set
   if (ctl_show_operators.p_value!=1 && ctl_show_constructors.p_value!=1) {
       show_mask1 |= CB_SHOW_non_special;
   }
   // Turn off operators/constructors if the other is set
   if (ctl_show_operators.p_value==1 && ctl_show_constructors.p_value==2) {
      show_mask1 &= ~CB_SHOW_constructors;
   }
   if (ctl_show_operators.p_value==2 && ctl_show_constructors.p_value==1) {
      show_mask1 &= ~CB_SHOW_operators;
   }
}

//////////////////////////////////////////////////////////////////////////////
// Apply new option settings from the symbol browser options dialog.
// First step is to reset the global options (see above), then call
// refresh_class_tree_view() and/or checkShowHideControls() if necessary.
//
static void apply_new_options()
{
   int show_mask1, show_mask2;
   get_filter_options(show_mask1, show_mask2);
   int show_class_filter  = ctl_show_class_filter.p_value;
   int show_member_filter = ctl_show_member_filter.p_value;

   _nocheck _control ctl_class_tree_view;
   _nocheck _control ctl_filter_check_box;
   _nocheck _control ctl_class_filter_combo_box;
   _nocheck _control ctl_member_filter_combo_box;


   TBSYMBOLS_FORM_INFO v;
   int f;
   foreach (f => v in gtbSymbolsFormList) {
      if (show_class_filter != f.ctl_class_filter_label.p_visible ||
          show_member_filter != f.ctl_member_filter_label.p_visible) {

         f.ctl_class_filter_label.p_user  = ctl_show_class_filter.p_value;
         f.ctl_member_filter_label.p_user = ctl_show_member_filter.p_value;
         f.checkShowHideControls();
      }

      int orig_show_mask1 = f.ctl_class_tree_view.p_user;
      int orig_show_mask2 = f.ctl_filter_check_box.p_user;
      _str class_filter  = f.ctl_class_filter_combo_box.cb_get_filter();
      _str member_filter = f.ctl_member_filter_combo_box.cb_get_filter();
      if (class_filter  :!= gtbSymbolsFormList:[f].m_z_class_filter ||
          member_filter :!= gtbSymbolsFormList:[f].m_z_member_filter ||
          (show_mask1 & CB_QUALIFIERS)  != (orig_show_mask1 & CB_QUALIFIERS) ||
          (show_mask2 & CB_QUALIFIERS2) != (orig_show_mask2 & CB_QUALIFIERS2)) {

         f.ctl_class_tree_view.p_user  = show_mask1;
         f.ctl_filter_check_box.p_user = show_mask2;
         f.ctl_filter_check_box.p_value = 0;
         gtbSymbolsFormList:[f].m_z_class_filter  = class_filter;
         gtbSymbolsFormList:[f].m_z_member_filter = member_filter;
         f.cb_refresh();
      }
   }
}

//////////////////////////////////////////////////////////////////////////////
// Handle user pressing symbol browser options "Apply" button
//
void ctl_apply_button.lbutton_up()
{
   apply_new_options();
}

//////////////////////////////////////////////////////////////////////////////
// Handle user pressing symbol browser options "OK" button, apply the
// options and dismiss the form.
//
void ctl_ok_button.lbutton_up()
{
   _save_form_response();
   apply_new_options();
   p_active_form._delete_window(0);
}

//////////////////////////////////////////////////////////////////////////////
// Special cases to insure that at least one of package, private, protected,
// or public is on.  If all but one is on, and you attempt to toggle that
// one off, turn on the next item.
//
void ctl_show_package_members.lbutton_up()
{
   if (ctl_show_package_members.p_value == 0 && ctl_show_public_members.p_value == 0 && ctl_show_protected_members.p_value == 0 && ctl_show_private_members.p_value == 0) {
      ctl_show_public_members.p_value = 1;
   }
}
void ctl_show_private_members.lbutton_up()
{
   if (ctl_show_package_members.p_value == 0 && ctl_show_public_members.p_value == 0 && ctl_show_protected_members.p_value == 0 && ctl_show_private_members.p_value == 0) {
      ctl_show_package_members.p_value = 1;
   }
}
void ctl_show_protected_members.lbutton_up()
{
   if (ctl_show_package_members.p_value == 0 && ctl_show_public_members.p_value == 0 && ctl_show_protected_members.p_value == 0 && ctl_show_private_members.p_value == 0) {
      ctl_show_private_members.p_value = 1;
   }
}
void ctl_show_public_members.lbutton_up()
{
   if (ctl_show_package_members.p_value == 0 && ctl_show_public_members.p_value == 0 && ctl_show_protected_members.p_value == 0 && ctl_show_private_members.p_value == 0) {
      ctl_show_protected_members.p_value = 1;
   }
}

//////////////////////////////////////////////////////////////////////////////
// Symbol browser options form creation, restore the options and
// refresh the controls as per current settings.
//
void ctl_ok_button.on_create()
{
   int f=p_active_form.p_parent;
   if (!f || f.p_name!=TBCBROWSER_FORM) return;
   _nocheck _control ctl_class_tree_view;
   _nocheck _control ctl_class_filter_combo_box;
   _nocheck _control ctl_member_filter_combo_box;
   _nocheck _control ctl_filter_check_box;

   int show_mask1 = f.ctl_class_tree_view.p_user;
   int show_mask2 = f.ctl_filter_check_box.p_user;
   refresh_filter_options(show_mask1, show_mask2);

   ctl_show_member_filter.p_value = (f.ctl_member_filter_combo_box.p_visible)? 1:0;
   ctl_show_class_filter.p_value  = (f.ctl_class_filter_combo_box.p_visible )? 1:0;
}


//############################################################################
//////////////////////////////////////////////////////////////////////////////
// handlers for class inheritance properties dialog
//
defeventtab _tbbaseclasses_form;

//////////////////////////////////////////////////////////////////////////////
// Handle right-mouse button on the inheritance tree dialog
//
void _tbbaseclasses_form.rbutton_up()
{
   int f=p_active_form.p_parent;
   if (!f || f.p_name!=TBCBROWSER_FORM) return;
   //int f = _tbGetActiveSymbolsForm();
   //if (!f) return;
   call_event(f.ctl_class_tree_view,RBUTTON_UP,'w');
}

//////////////////////////////////////////////////////////////////////////////
// handle horizontal resize bar
//
ctl_divider.lbutton_down()
{
   int border_width = ctl_inheritance_tree_view.p_x;
   int member_width = ctl_member_tree_view.p_x_extent;
   _ul2_image_sizebar_handler((border_width)*4,member_width);
}

//////////////////////////////////////////////////////////////////////////////
// Handle resize event, distributing available space evenly between the
// inheritance tree side and the member list side.  Do not allow the size
// to go below the minimum required to show classes in the tree and show
// all three buttons.
//
void _tbbaseclasses_form.on_resize()
{
   // width/height of OK, Cancel, Help buttons (all are the same)
   int button_width  = ctl_inheritance_tree_view.p_x;//ctl_ok_button.p_width;
   button_height := 375;//ctl_ok_button.p_height;

   // have we set the min size yet?  if not, min width will be 0
   if (!_minimum_width()) {
      _set_minimum_size(button_width*2, button_height*5);
   }

   // available space and border usage
   int avail_x, avail_y, border_x, border_y;
   avail_x  = p_width;
   avail_y  = p_height;
   border_x = ctl_inheritance_tree_view.p_x;
   border_y = ctl_inheritance_tree_view.p_y;

   // half the width of the dialog
   int half_x        = ctl_divider.p_x;
   int half_width    = ctl_divider.p_width;
   if (half_x < button_width*2 + border_x*2) {
      half_x = button_width*2 + border_x*2;
   }
   if (half_x > avail_x) {
      half_x = avail_x - ctl_divider.p_width;
      ctl_divider.p_x = half_x;
   }

   // size the tree controls
   ctl_inheritance_tree_view.p_width  = half_x - border_x;
   ctl_inheritance_tree_view.p_height = avail_y - border_y*2;
   ctl_member_tree_view.p_x      = half_x + half_width;
   ctl_member_tree_view.p_height = avail_y - border_y*2;
   ctl_member_tree_view.p_width  = avail_x - half_x - border_x - half_width;

   // set the height of the divider
   ctl_divider.p_height = ctl_inheritance_tree_view.p_height;
#if 0
   // move around the buttons
   int button_y = avail_y - button_height - border_y;
   ctl_ok_button.p_y   = button_y;
   ctl_help_button.p_y = button_y;
   ctl_help_button.p_x = ctl_divider.p_x - button_width;
#endif
}

//////////////////////////////////////////////////////////////////////////////
// Get context information for the currently selected member in the class
// inheritance dialog.  Complete context is obtained by looking both at
// the currently selected member, and the currently selected class.
// Final details are obtained from the database.  If (class_only==1),
// then get the tag info for the currently selected class, not member.
// p_window_id must be the inheritance tree window ID.
//
static int get_inheritance_tag_info(struct VS_TAG_BROWSE_INFO &cm, int class_only, bool no_db_access, int classIndex=-1, int memberIndex=-1)
{
   tag_init_tag_browse_info(cm);

   // check current tree index
   if (classIndex < 0) {
      classIndex = ctl_inheritance_tree_view._TreeCurIndex();
   }
   if (classIndex < 0) {
      return 0;
   }

   // get some more details
   _str ucm = ctl_inheritance_tree_view._TreeGetUserInfo(classIndex);
   _str line_no=0,class_end,caption;
   parse ucm with cm.tag_database ";" cm.class_name ";" cm.type_name ";" cm.file_name ";" line_no ;
   cm.line_no = line_no!=""? (int) line_no : 0;

   // if they are requesting only information on the currently selected class
   if (class_only) {
      cm.qualified_name = cm.class_name;
      cm.member_name = cm.class_name;
      cm.class_name  = "";
      while (pos(VS_TAGSEPARATOR_package, cm.member_name)) {
         parse cm.member_name with class_end (VS_TAGSEPARATOR_package) cm.member_name;
         if (cm.class_name != "") {
            cm.class_name = cm.class_name:+VS_TAGSEPARATOR_package:+class_end;
         } else {
            cm.class_name = class_end;
         }
      }
      while (pos(VS_TAGSEPARATOR_class, cm.member_name)) {
         parse cm.member_name with class_end (VS_TAGSEPARATOR_class) cm.member_name;
         if (cm.class_name != "") {
            cm.class_name = cm.class_name:+VS_TAGSEPARATOR_class:+class_end;
         } else {
            cm.class_name = class_end;
         }
      }
   } else {
      // get basic location info for this tag
      if (memberIndex < 0) {
         memberIndex = ctl_member_tree_view._TreeCurIndex();
      }
      if (memberIndex <= 0) {
         return 0;
      }
      int d = ctl_member_tree_view._TreeGetDepth(memberIndex);
      if (d<2) {
         return 0;
      }
      caption = ctl_member_tree_view._TreeGetCaption(memberIndex);
      tag_tree_decompose_caption(caption,cm.member_name);
      cm.line_no = ctl_member_tree_view._TreeGetUserInfo(memberIndex);
      cm.type_name = "";
   }

   // bail out if we were asked not to touch the database
   if (no_db_access) {
      return 1;
   }

   // open the tag database for business
   int status = tag_read_db(cm.tag_database);
   if ( status < 0 ) {
      return(status);
   }

   // find the specific tag in the database
   status = tag_find_closest(cm.member_name, cm.file_name, cm.line_no, true);
   if (!status) {
      tag_get_detail(VS_TAGDETAIL_type,      cm.type_name);
      tag_get_detail(VS_TAGDETAIL_flags,     cm.flags);
      tag_get_detail(VS_TAGDETAIL_return,    cm.return_type);
      tag_get_detail(VS_TAGDETAIL_arguments, cm.arguments);
      tag_get_detail(VS_TAGDETAIL_throws,    cm.exceptions);
      tag_get_detail(VS_TAGDETAIL_language_id,   cm.language);
      tag_get_detail(VS_TAGDETAIL_class_parents, cm.class_parents);
      tag_get_detail(VS_TAGDETAIL_template_args, cm.template_args);
      tag_get_detail(VS_TAGDETAIL_doc_comments,  cm.doc_comments);
      tag_get_detail(VS_TAGDETAIL_doc_type,      cm.doc_type);
      if (cm.language=="jar" || cm.language=="zip") {
         cm.language="java";
      }
   }

   // success
   tag_reset_find_tag();
   return 1;
}

//////////////////////////////////////////////////////////////////////////////
// This is the timer callback.  Whenever the current index (cursor position)
// for the inheritance tree is changed, a timer is started/reset.  If no
// activity occurs within a set amount of time, this function is called to
// update the properties view, inheritance view, and output window.
//
static void _MemberListTimerCallback(_str cmdline)
{
   // kill the timer
   cb_kill_timer();

   parse cmdline with auto sform_wid auto sindex;
   f := (int)sform_wid;
   index := (int)sindex;
   if (!_iswindow_valid(f) || (f.p_name!=TBBASECLASSES_FORM && f.p_name!=TBDERIVEDCLASSES_FORM)) {
      return;
   }

   // update the property view, call tree view, and output tab
   if (f.get_inheritance_tag_info(auto cm, 0, false)) {
      // refresh the symbol properties dialog if available
      f.cb_refresh_property_view(cm);
      // refresh the symbol arguments dialog if available
      f.cb_refresh_arguments_view(cm);

      // find the output tagwin and update it
      cb_refresh_output_tab(cm, true);
   }
}
static void _MemberListHighlightCallback(_str cmdline)
{
   // kill the timer
   cb_kill_timer_highlight();

   parse cmdline with auto sform_wid auto sindex;
   f := (int)sform_wid;
   index := (int)sindex;
   if (!_iswindow_valid(f) || (f.p_name!=TBBASECLASSES_FORM && f.p_name!=TBDERIVEDCLASSES_FORM)) {
      return;
   }

   // update the property view, call tree view, and output tab
   if (f.get_inheritance_tag_info(auto cm, 0, false, -1, index)) {
      _UpdateTagWindowDelayed(cm, def_tag_hover_delay);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Handle on-change event for member list (a tree control) in inheritance
// tree dialog.  The only event handled is CHANGE_LEAF_ENTER, for which
// we utilize push_tag_in_file to push a bookmark and bring up the code in
// the editor.
//
void ctl_member_tree_view.on_change(int reason,int index)
{
   if (reason == CHANGE_LEAF_ENTER) {

      // get the current index and tag details
      int k = index;
      if (get_inheritance_tag_info(auto cm, 0, false)) {
         push_tag_in_file(cm.member_name, cm.file_name, cm.class_name, cm.type_name, cm.line_no);
      }
   } else if (reason == CHANGE_SELECTED) {
      if (_get_focus() == ctl_member_tree_view) {
         cb_start_timer(p_active_form,_MemberListTimerCallback);
      }
   }
}

void ctl_member_tree_view.on_highlight(int index, _str caption="")
{
   cb_kill_timer_highlight();
   if (!def_tag_hover_preview) return;
   if (index < 0) {
      _UpdateTagWindowDelayed(null,0);
      return;
   }
   cb_start_timer_highlight(p_active_form,_MemberListHighlightCallback, index, def_tag_hover_delay);
}


//////////////////////////////////////////////////////////////////////////////
// Update other views when viewer gets focus, important because
// inheritance view, call tree, and props can also update the output
// view, so if they return focus to the symbol browser, we need to
// restart the update timer.
//
void ctl_member_tree_view.on_got_focus()
{
   if (!_find_control("ctl_member_tree_view")) return;
   cb_start_timer(p_active_form,_MemberListTimerCallback);
}

//////////////////////////////////////////////////////////////////////////////
// If the spacebar is pressed when the focus is on the member list,
// bring the item up in the editor, but retain focus on the member list.
//
void ctl_member_tree_view." "()
{
   orig_window_id := p_window_id;
   if (get_inheritance_tag_info(auto cm, 0, false)) {
      push_tag_in_file(cm.member_name, cm.file_name, cm.class_name, cm.type_name, cm.line_no);
   }
   p_window_id = orig_window_id;
   ctl_member_tree_view._set_focus();
}

//////////////////////////////////////////////////////////////////////////////
// Handle double-click (meaning drill-down) on a member in a class.
// This method will attempt to locate the proc that corresponds to any
// prototype that is selected, and position us there.
//
void ctl_member_tree_view.enter,lbutton_double_click()
{
   k := ctl_member_tree_view._TreeCurIndex();
   int d = (k<0)? 0:ctl_member_tree_view._TreeGetDepth(k);
   if (d > 1) {
      if (get_inheritance_tag_info(auto cm, 0, false)) {
         tag_push_matches();
         maybe_convert_proto_to_proc(cm, true);
         tag_remove_duplicate_symbol_matches();
         match_id := tag_select_symbol_match(cm);
         tag_pop_matches();
         if (match_id >= 0) {
            push_tag_in_file(cm.member_name, cm.file_name, cm.class_name, cm.type_name, cm.line_no);
         }
      }
   } else {
      show_children := 0;
      _TreeGetInfo(k,show_children);
      if (show_children == TREE_NODE_LEAF) {
         call_event(CHANGE_LEAF_ENTER,k,p_window_id,ON_CHANGE,'w');
      } else {
         call_event(show_children?CHANGE_COLLAPSED:CHANGE_EXPANDED,k,p_window_id,ON_CHANGE,'w');
         _TreeSetInfo(k,(int)!show_children);
      }
   }
}


//////////////////////////////////////////////////////////////////////////////
// This is the timer callback.  Whenever the current index (cursor position)
// for the inheritance tree is changed, a timer is started/reset.  If no
// activity occurs within a set amount of time, this function is called to
// update the properties view, inheritance view, and output window.
//
static void _InheritanceTimerCallback(_str cmdline)
{
   // kill the timer
   cb_kill_timer();

   parse cmdline with auto sform_wid auto sindex;
   f := (int)sform_wid;
   index := (int)sindex;
   if (!_iswindow_valid(f) || (f.p_name!=TBBASECLASSES_FORM && f.p_name!=TBDERIVEDCLASSES_FORM) ) {
      return;
   }

   // update the property view, call tree view, and output tab
   if (f.get_inheritance_tag_info(auto cm, 1, false)) {

      // refresh the list of member functions
      se.util.MousePointerGuard hour_glass;
      _str in_file_name = cm.file_name;
      if (cm.flags & SE_TAG_FLAG_PARTIAL) {
         in_file_name="";
      }
      f.ctl_member_tree_view.add_members_of(cm.qualified_name, cm.tag_database, in_file_name);
      f.ctl_member_tree_view._TreeRefresh();

      // refresh the properties view
      f.cb_refresh_property_view(cm);

      // refresh the symbol arguments dialog if available
      f.cb_refresh_arguments_view(cm);

      // find the output tagwin and update it
      cb_refresh_output_tab(cm, true);
   } else {
      f.ctl_member_tree_view._TreeDelete(TREE_ROOT_INDEX,'c');
      f.ctl_member_tree_view._TreeAddItem(TREE_ROOT_INDEX, "CLASS NOT FOUND", TREE_ADD_AS_CHILD, _pic_folder, _pic_folder);
   }
}
static void _InheritanceHighlightCallback(_str cmdline)
{
   // kill the timer
   cb_kill_timer_highlight();

   parse cmdline with auto sform_wid auto sindex;
   f := (int)sform_wid;
   index := (int)sindex;
   if (!_iswindow_valid(f) || (f.p_name!=TBBASECLASSES_FORM && f.p_name!=TBDERIVEDCLASSES_FORM)) {
      return;
   }

   // update the property view, call tree view, and output tab
   if (f.get_inheritance_tag_info(auto cm, 1, false, index)) {

      // find the output tagwin and update it
      _UpdateTagWindowDelayed(cm, def_tag_hover_delay);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Handle on-change for inheritance tree, meaning that a diffenent class
// was selected, so we need to update the list of members.
//
void ctl_inheritance_tree_view.on_change(int reason,int index)
{
   struct VS_TAG_BROWSE_INFO cm;
   if (reason == CHANGE_LEAF_ENTER) {
      if (get_inheritance_tag_info(cm, 1, true)) {
         push_tag_in_file(cm.member_name, cm.file_name, cm.class_name, cm.type_name, cm.line_no);
      }
   } else if (reason == CHANGE_SELECTED) {

      if (_get_focus() == ctl_inheritance_tree_view) {
         cb_start_timer(p_active_form,_InheritanceTimerCallback);
      } else {
         if (get_inheritance_tag_info(cm, 1, true)) {
            se.util.MousePointerGuard hour_glass;
            _str in_file_name = cm.file_name;
            if (cm.flags & SE_TAG_FLAG_PARTIAL) {
               in_file_name="";
            }
            ctl_member_tree_view.add_members_of(cm.qualified_name, cm.tag_database, in_file_name);
            ctl_member_tree_view._TreeRefresh();
         }
      }
   } else if (reason == CHANGE_EXPANDED && ctl_member_tree_view.p_user==1) {

      // already expanded?
      if (ctl_inheritance_tree_view._TreeGetFirstChildIndex(index) > 0) {
         return;
      }
      // still needs to be expanded
      if (!get_inheritance_tag_info(cm, 1, true, index)) {
         return;
      }

      _str lang = _Filename2LangId(cm.file_name);
      typeless tag_files = tags_filenamea(lang);

      se.util.MousePointerGuard hour_glass;
      bool been_there_done_that:[];
      VS_TAG_RETURN_TYPE visited:[];
      ctl_inheritance_tree_view.add_children_of(index, cm.qualified_name,
                                                cm.type_name,
                                                cm.tag_database, tag_files,
                                                cm.file_name, cm.line_no,
                                                been_there_done_that, visited);
      clear_message();
   }
}

void ctl_inheritance_tree_view.on_highlight(int index, _str caption="")
{
   cb_kill_timer_highlight();
   if (!def_tag_hover_preview) return;
   if (index < 0) {
      _UpdateTagWindowDelayed(null,0);
      return;
   }
   cb_start_timer_highlight(p_active_form,_InheritanceHighlightCallback, index, def_tag_hover_delay);
}

//////////////////////////////////////////////////////////////////////////////
// Update other views when viewer gets focus, important because
// inheritance view, call tree, and props can also update the output
// view, so if they return focus to the symbol browser, we need to
// restart the update timer.
//
void ctl_inheritance_tree_view.on_got_focus()
{
   if (!_find_control("ctl_inheritance_tree_view")) return;
   cb_start_timer(p_active_form,_InheritanceTimerCallback);
}

//////////////////////////////////////////////////////////////////////////////
// Handles double-clock/enter in inheritance tree view, pushing a bookmark
// and displaying the class in the editor for editing.
//
void ctl_inheritance_tree_view.enter,lbutton_double_click()
{
   j := ctl_inheritance_tree_view._TreeCurIndex();
   if (get_inheritance_tag_info(auto cm, 1, true)) {
      push_tag_in_file(cm.member_name, cm.file_name, cm.class_name, cm.type_name, cm.line_no);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Handles spacebar in inheritance tree view, pushing a bookmark
// and displaying the class in the editor for editing, but retaining
// focus in the inheritance tree browser.
//
void ctl_inheritance_tree_view." "()
{
   j := ctl_inheritance_tree_view._TreeCurIndex();
   if (get_inheritance_tag_info(auto cm, 1, true)) {
      orig_window_id := p_window_id;
      push_tag_in_file(cm.member_name, cm.file_name, cm.class_name, cm.type_name, cm.line_no);
      p_window_id = orig_window_id;
      ctl_inheritance_tree_view._set_focus();
   }
}

static int cbrowser_get_class_pic_index(_str class_type, _str parents=null)
{
   tagType := tag_get_type_id(class_type);
   if (tagType == SE_TAG_TYPE_NULL) tagType = SE_TAG_TYPE_CLASS;
   pic_member := tag_get_bitmap_for_type(tagType);
   return pic_member;
}

//////////////////////////////////////////////////////////////////////////////
// Add the parents (classes that 'class_name' derives from) to the
// inheritance tree browser).  tag databases and file names are resolved
// allowing us to display parents that are in other tag files.
// This function is recursive, but limited to CB_MAX_INHERITANCE_DEPTH levels.
// p_window_id must be the inheritance tree control (left tree of window).
//
int cbrowser_add_parents_of(int j, _str class_name, _str class_parents,
                            _str tag_db_name, typeless &tag_files,
                            _str child_file_name, int child_line_no, 
                            int depth=0, _str class_type="",
                            VS_TAG_RETURN_TYPE (&visited):[]=null)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (depth >= CB_MAX_INHERITANCE_DEPTH) {
      return 0;
   }

   // what tag file is this class really in?
   normalized := "";
   tag_file := find_class_in_tag_file(class_name, class_name, normalized, true, tag_files);
   if (tag_file == "") {
      tag_file = find_class_in_tag_file(class_name, class_name, normalized, true, tag_files, true);
   }
   if (tag_file != "") {
      tag_db_name = tag_file;
   }
   pic_class := 0;
   status := tag_read_db(tag_db_name);
   if (status < 0) {
      pic_class = cbrowser_get_class_pic_index(class_type);
      _TreeAddItem(j, class_name, TREE_ADD_AS_CHILD, pic_class, pic_class, TREE_NODE_EXPANDED);
      return 0;
   }

   // get are parent classes and the tag files they come from
   result := 0;
   tag_dbs := "";
   parent_types := "";
   parents := cb_get_normalized_inheritance(class_name, 
                                            tag_dbs, tag_files, 
                                            false, class_parents, 
                                            child_file_name, 
                                            parent_types, false,
                                            visited, depth+1);

   // check if this is a base class
   pic_class = cbrowser_get_class_pic_index(class_type, parents);

   // make sure the right tag file is still open
   status = tag_read_db(tag_db_name);
   if (status < 0) {
      pic_class = cbrowser_get_class_pic_index(class_type);
      _TreeAddItem(j, class_name, TREE_ADD_AS_CHILD, pic_class, pic_class, TREE_NODE_EXPANDED);
      return 0;
   }

   file_name := "";
   type_name := "";
   line_no := 0;
   status = find_location_of_parent_class(tag_db_name, class_name, file_name, line_no, type_name);
   if (status < 0 || j<0) {
      file_name = child_file_name;
      line_no   = child_line_no;
   }

   // OK, we are now ready to insert
   ucm := tag_db_name ";" class_name ";" type_name ";" file_name ";" line_no;
   k := _TreeAddItem(j, class_name, TREE_ADD_AS_CHILD, pic_class, pic_class, TREE_NODE_EXPANDED, 0, ucm);

   // recursively process parent classes
   orig_tag_file := tag_current_db();
   while (parents != "") {
      parse parents with auto p1 ";" parents;
      parse tag_dbs with auto t1 ";" tag_dbs;
      parse parent_types with class_type ";" parent_types;
      parse p1 with p1 "<" .;
      find_location_of_parent_class(t1,p1,file_name,line_no,type_name);
      result = cbrowser_add_parents_of(k, p1, "", t1, tag_files, file_name, line_no, depth+1, class_type, visited);
   }

   tag_read_db(orig_tag_file);
   return k;
}


//////////////////////////////////////////////////////////////////////////////
// Add the children (classes that derive from 'class_name') to the
// inheritance tree browser).
static int add_children_of(int j, _str class_name, _str type_name,
                           _str tag_db_name, typeless &tag_files,
                           _str child_file_name, int child_line_no, 
                           bool (&been_there_done_that):[], 
                           VS_TAG_RETURN_TYPE (&visited):[],
                           int depth=0, int max_depth=1)
{
   if (_chdebug) {
      isay(depth, "add_children_of H"__LINE__": IN, class_name="class_name" p_ShowRoot="p_ShowRoot);
   }
   pic_class := 0;
   if (j == TREE_ROOT_INDEX) {
      pic_class = tag_get_bitmap_for_type(tag_get_type_id(type_name));
      ucm := tag_db_name ";" class_name ";" type_name ";" child_file_name ";" child_line_no;
      j = _TreeAddItem(j, class_name, TREE_ADD_AS_CHILD, pic_class, pic_class, 1, 0, ucm);
   }

   tag_lock_matches(true);
   tag_push_matches();
   tag_clear_matches();
   tag_find_derived(class_name, 
                    tag_db_name, tag_files, 
                    child_file_name, child_line_no, 
                    been_there_done_that, 
                    visited, depth+1, max_depth+1, depth+1);
   num_matches := tag_get_num_of_matches();
   for (i := 1; i <= num_matches; i++) {
      tag_get_match_info(i, auto cm);
      pic_class = tag_get_bitmap_for_type(tag_get_type_id(cm.type_name), cm.flags, auto pic_overlay);
      show_children := TREE_NODE_COLLAPSED;//(depth < max_depth)? 1:0;
      cm.qualified_name = tag_join_class_name(cm.member_name, cm.class_name, tag_files, true, false, false, visited, depth+1);
      if (_chdebug) {
         tag_browse_info_dump(cm, "add_children_of: cm["i"]", depth+1);
      }
      ucm := cm.tag_database ";" cm.qualified_name ";" cm.type_name ";" cm.file_name ";" cm.line_no;
      k := _TreeAddItem(j, cm.qualified_name, TREE_ADD_AS_CHILD|TREE_OVERLAY_BITMAP1, pic_overlay, pic_class, show_children, 0, ucm);
      if (show_children) {
         // still needs to be expanded
         tag_push_matches();
         get_inheritance_tag_info(cm, 1, true, k);
         add_children_of(k, cm.qualified_name,
                         cm.type_name,
                         cm.tag_database, tag_files,
                         cm.file_name, cm.line_no,
                         been_there_done_that, 
                         visited, depth+1, max_depth);
         tag_pop_matches();
      }
   }

   tag_pop_matches();
   tag_unlock_matches();
   return j;
}

//////////////////////////////////////////////////////////////////////////////
// Add the members of the given class to the list of members in the
// inheritance tree view.  As apposed to the class tree view, members are
// not filtered here.  Members are dispersed into four categories, publ// They are then sorted by caption and (secondary) line number.
// p_window_id must be the member tree control (right tree of window).
//
static int add_members_of(_str class_name, _str tag_db_name, _str in_file_name)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // uh-oh
   if (class_name == "") {
      _TreeDelete(TREE_ROOT_INDEX,'c');
      _TreeAddItem(TREE_ROOT_INDEX, "CLASS NOT FOUND", TREE_ADD_AS_CHILD, _pic_folder, _pic_folder);
      return(-1);
   }

   // open the database for business
   int status = tag_read_db(tag_db_name);
   if ( status < 0 ) {
      _TreeDelete(TREE_ROOT_INDEX,'c');
      _TreeAddItem(TREE_ROOT_INDEX, "CLASS NOT FOUND", TREE_ADD_AS_CHILD, _pic_folder, _pic_folder);
      return(status);
   }

   // re-use the public, protected, private, package categories
   int j_access[];
   i_access := 0;
   i_type := 0;
   j := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (j>0) {
      j_access[i_access]=j;
      ++i_access;
      _TreeDelete(j,'c');
      j = _TreeGetNextSiblingIndex(j);
   }
   if (i_access != 4) {
      _TreeDelete(TREE_ROOT_INDEX, 'c');
      i_access = 0;
   }

   if (i_access == 0) {
      j_access[CB_access_public]    = _TreeAddItem(TREE_ROOT_INDEX, "PUBLIC",    TREE_ADD_AS_CHILD|TREE_OVERLAY_BITMAP1, _pic_folder, _pic_symbol_public, TREE_NODE_EXPANDED);
      j_access[CB_access_protected] = _TreeAddItem(TREE_ROOT_INDEX, "PROTECTED", TREE_ADD_AS_CHILD|TREE_OVERLAY_BITMAP1, _pic_folder, _pic_symbol_public, TREE_NODE_EXPANDED);
      j_access[CB_access_private]   = _TreeAddItem(TREE_ROOT_INDEX, "PRIVATE",   TREE_ADD_AS_CHILD|TREE_OVERLAY_BITMAP1, _pic_folder, _pic_symbol_public, TREE_NODE_EXPANDED);
      j_access[CB_access_package]   = _TreeAddItem(TREE_ROOT_INDEX, "PACKAGE",   TREE_ADD_AS_CHILD|TREE_OVERLAY_BITMAP1, _pic_folder, _pic_symbol_public, TREE_NODE_EXPANDED);
   }

   // insert all the members in class, must be in same file as class, no other filtering
   status = tag_find_in_class(class_name);
   while (!status) {
      tag_flags := SE_TAG_FLAG_NULL;
      tag_get_detail(VS_TAGDETAIL_flags,tag_flags);
      if ((tag_flags & SE_TAG_FLAG_INCLASS) == 0){
         status = tag_next_in_class();
         continue;
      }
      // kick out if this does not come from the given filename
      tag_get_tag_browse_info(auto cm);
      if (!(cm.flags & SE_TAG_FLAG_EXTERN_MACRO) &&
          in_file_name != "" && !_file_eq(cm.file_name, in_file_name)) {
         status = tag_next_in_class();
         continue;
      }

      // function/data, access restrictions and type code for picture selection
      caption := tag_tree_make_caption_fast(VS_TAGMATCH_tag,0,false,true,false);

      // compute file/id / line number code
      ucm := cm.line_no;

      // determine if this is public, private, or protected
      switch (cm.flags & SE_TAG_FLAG_ACCESS) {
      case SE_TAG_FLAG_PUBLIC:    i_access = 0; break;
      case SE_TAG_FLAG_PROTECTED: i_access = 1; break;
      case SE_TAG_FLAG_PRIVATE:   i_access = 2; break;
      case SE_TAG_FLAG_PACKAGE:   i_access = 3; break;
      default:                    i_access = 0; break;
      }

      // get the appropriate bitmap
      pic_member := tag_get_bitmap_for_type(cm.type_id, cm.flags, auto pic_overlay);
      j = _TreeAddItem(j_access[i_access],caption,TREE_ADD_AS_CHILD|TREE_OVERLAY_BITMAP1,pic_overlay,pic_member,TREE_NODE_LEAF,0,ucm);
      status = tag_next_in_class();
   }
   tag_reset_find_in_class();

   // sort each of the access categories
   if (gi_sort_by_line) {
      _TreeSortUserInfo(j_access[CB_access_public   ],'N','I');
      _TreeSortUserInfo(j_access[CB_access_protected],'N','I');
      _TreeSortUserInfo(j_access[CB_access_private  ],'N','I');
      _TreeSortUserInfo(j_access[CB_access_package  ],'N','I');
   } else {
      _TreeSortCaption(j_access[CB_access_public   ],'I','N');
      _TreeSortCaption(j_access[CB_access_protected],'I','N');
      _TreeSortCaption(j_access[CB_access_private  ],'I','N');
      _TreeSortCaption(j_access[CB_access_package  ],'I','N');
   }

   // mark the empty categories as EMPTY
   j = _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (j>0) {
      caption := _TreeGetCaption(j);
      parse caption with caption CB_delimiter .;
      child := _TreeGetFirstChildIndex(j);
      if (child <= 0) {
         caption :+= CB_delimiter :+ CB_empty;
      }
      _TreeSetCaption(j, caption);
      j = _TreeGetNextSiblingIndex(j);
   }

   // go to the top of the tree
   _TreeTop();

   return 0;
}

//////////////////////////////////////////////////////////////////////////////
// Clear the inheritance view, removing all items in parents tree and
// member list.  p_window_id must be the inheritance tree window ID.
//
static void clear_inheritance_view(_str msg="")
{
   ctl_inheritance_tree_view._TreeDelete(TREE_ROOT_INDEX, 'c');
   index := ctl_member_tree_view._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (index > 0) {
      ctl_member_tree_view._TreeDelete(index, 'c');
      index = ctl_member_tree_view._TreeGetNextSiblingIndex(index);
   }
   ctl_inheritance_tree_view._TreeSetCaption(TREE_ROOT_INDEX, msg);
   refresh();
}

//////////////////////////////////////////////////////////////////////////////
// Refresh the inheritance tree view with the given tag specification
// obtained from get_user_tag_info().  If we can show that the class
// hasn't changed, then break out early.
// p_window_id must be the inheritance tree window ID.
//
static void cb_refresh_inheritance_view(int cbrowser_form, struct VS_TAG_BROWSE_INFO cm, _str show_derived=null, bool force=false, int form_wid=0)
{
   //say("cb_refresh_inheritance_view: here 1");
   // Refresh the specific form requested
   f := form_wid;
   if (f > 0) {
      f.cb_refresh_inheritance_view_for_one_window(cbrowser_form,cm,show_derived,force);
      return;
   }

   // refresh all instances of the arguments toolbar
   found_one := false;
   foreach (f => . in gtbBaseClassesFormList) {
      if (tw_is_from_same_mdi(f,cbrowser_form)) {
         found_one=true;
         f.cb_refresh_inheritance_view_for_one_window(cbrowser_form,cm,show_derived,force);
      }
   }
   if (!found_one) {
      f=_tbGetActiveBaseClassesForm();
      if (f) {
         f.cb_refresh_inheritance_view_for_one_window(cbrowser_form,cm,show_derived,force);
      }
   }
}
static void cb_refresh_inheritance_view_for_one_window(int cbrowser_form,struct VS_TAG_BROWSE_INFO cm, _str show_derived=null, bool force=false)
{
   if (cm.qualified_name == "") {
      cm.qualified_name = cm.class_name;
   }
   if (cm.type_name :== "enumc") {
      return;
   }
   if (show_derived==null) {
      show_derived=ctl_member_tree_view.p_user;
      if (show_derived==null || show_derived=="") {
         show_derived=(p_active_form.p_name!=TBBASECLASSES_FORM);
      }
   }

   // same inheritance tree as last time?
   struct VS_TAG_BROWSE_INFO cm2=ctl_inheritance_tree_view.p_user;
   if (!force && tag_browse_info_equal(cm,cm2) &&
       show_derived==ctl_member_tree_view.p_user) {
      return;
   }
   ctl_inheritance_tree_view.p_user=cm;
   ctl_member_tree_view.p_user=show_derived;

   // bail out if there is no class involved or if class name hasn't changed
   _str caption;
   _str tag_db_name,class_name,type_name,file_name,line_no;
   currIndex := ctl_inheritance_tree_view._TreeCurIndex();
   if (currIndex > 0) {
      caption = ctl_inheritance_tree_view._TreeGetCaption(currIndex);
      _str ucm = ctl_inheritance_tree_view._TreeGetUserInfo(currIndex);
      parse ucm with tag_db_name ";" class_name ";" type_name ";" file_name ";" line_no;
      if (caption :== cm.qualified_name && _file_eq(tag_db_name, cm.tag_database) && _file_eq(file_name, cm.file_name) && type_name :== cm.type_name) {
         return;
      }
   } else {
      if (cm.qualified_name=="") {
         ctl_inheritance_tree_view._TreeSetCaption(TREE_ROOT_INDEX, "No class selected");
         ctl_inheritance_tree_view._TreeSetUserInfo(TREE_ROOT_INDEX, 0);
      }
   }

   // If a file is not selected, clear the tree
   if (cm.qualified_name == "") {
      clear_inheritance_view("No class selected");
      return;
   }

   // check that we are positioned on something class-related
   f := cbrowser_form;
   if (f<0) {
      f=_tbGetActiveSymbolsForm();
   }
   if (!f) {
      clear_inheritance_view("No class selected");
      return;
   }
   int item_depth;
   typeless value;
   currIndex  = f.ctl_class_tree_view._TreeCurIndex();
   item_depth = f.ctl_class_tree_view._TreeGetDepth(currIndex);
   value      = f.ctl_class_tree_view._TreeGetUserInfo(currIndex);

   // If a class is not selected, clear the tree
   if (item_depth <= 2) {
      clear_inheritance_view("No class selected");
      return;
   }
   CB_TAG_CATEGORY *ctg = gh_cb_categories._indexin(cm.category);
   if (item_depth == 3 && (!ctg || !ctg->level3_inheritance)) {
      clear_inheritance_view("No class selected");
      return;
   }
   if (item_depth == 4 && (!ctg || !ctg->level4_inheritance)) {
      clear_inheritance_view("No class selected");
      return;
   }

   // Delete everything in the tree, and insert the new parent hierarchy
   struct VS_TAG_RETURN_TYPE visited:[];
   se.util.MousePointerGuard hour_glass;
   ctl_inheritance_tree_view._TreeDelete(TREE_ROOT_INDEX, 'c');
   //_str ext = _Ext2LangId(get_extension(cm.file_name));
   int j;
   _str lang = _Filename2LangId(cm.file_name);
   typeless tag_files = tags_filenamea(lang);
   if (show_derived) {
      bool been_there_done_that:[];
      p_active_form.p_caption=CB_derived;
      ctl_member_tree_view.p_user=1;
      j = ctl_inheritance_tree_view.add_children_of(TREE_ROOT_INDEX, 
                                                    cm.qualified_name,
                                                    cm.type_name,
                                                    cm.tag_database, tag_files,
                                                    cm.file_name, cm.line_no,
                                                    been_there_done_that, visited,
                                                    0, def_cb_max_derived_class_depth);
   } else {
      p_active_form.p_caption=CB_bases;
      ctl_member_tree_view.p_user=0;
      j = ctl_inheritance_tree_view.cbrowser_add_parents_of(TREE_ROOT_INDEX, 
                                                            cm.qualified_name, cm.class_parents,
                                                            cm.tag_database, tag_files,
                                                            cm.file_name, cm.line_no, 
                                                            0, cm.type_name, visited);
   }

   // Initialize the member list for this class
   ctl_inheritance_tree_view._TreeSetCurIndex(j);
   call_event(CHANGE_SELECTED,j,ctl_inheritance_tree_view,ON_CHANGE,'w');
   ctl_inheritance_tree_view._TreeRefresh();
   clear_message();
}

//////////////////////////////////////////////////////////////////////////////
// THIS is not used?
//
//void cb_refresh_inheritance_view(struct VS_TAG_BROWSE_INFO &cm)
//{
//   // bail out if there is no inheritance form
//   _nocheck _control ctl_inheritance_tree_view;
//   _nocheck _control ctl_member_tree_view;
//   int f = gcbparents_wid;
//   if (!f) return;
//
//   // bail out if type is a macro defininition
//   if (cm.type_name :== "define") {
//      return;
//   }
//
//   // try to determine the qualified class name
//   if (cm.qualified_name == "") {
//      cm.qualified_name = cm.class_name;
//   }
//   if (tag_tree_type_is_class(cm.class_name)) {
//      cm.qualified_name = _JoinClassWithOuter(cm.class_name, cm.qualified_name, false);
//   }
//
//   // bail out if there is no class involved or if class name hasn't changed
//   int currIndex = f.ctl_inheritance_tree_view._TreeCurIndex();
//   if (currIndex > 0) {
//      caption = f.ctl_inheritance_tree_view._TreeGetCaption(currIndex);
//      ucm = f.ctl_inheritance_tree_view._TreeGetUserInfo(currIndex);
//      parse ucm with tag_db_name ";" class_name ";" type_name ";" file_name ";" line_no;
//      if (caption :== cm.qualified_name && file_eq(tag_db_name, cm.tag_database) && file_eq(file_name, cm.file_name) && type_name :== cm.type_name) {
//         return;
//      }
//   } else {
//      if (cm.qualified_name=="") {
//         f.clear_inheritance_view("No class selected");
//         return;
//      }
//   }
//
//   // Delete everything in the tree, and insert the new parent hierarchy
//   mou_hour_glass(true);
//   f.ctl_inheritance_tree_view._TreeDelete(TREE_ROOT_INDEX, 'c');
//   _str lang = _Filename2LangId(cm.file_name);
//   typeless tag_files = tags_filenamea(lang);
//   j = f.ctl_inheritance_tree_view.add_parents_of(-1, cm.qualified_name,
//                                                  cm.tag_database, tag_files,
//                                                  cm.file_name, cm.line_no, 0);
//
//   // Initialize the member list for this class
//   f.ctl_inheritance_tree_view._TreeSetCurIndex(j);
//   f.call_event(CHANGE_SELECTED,j,f.ctl_inheritance_tree_view,ON_CHANGE,'w')
//   //mou_hour_glass(false);
//}

//////////////////////////////////////////////////////////////////////////////
// On form creation, get the argument (tag information), and refresh
// the view, cache the window id.
//
void _tbbaseclasses_form.on_create()
{
   TBBASECLASSES_FORM_INFO info;
   info.m_form_wid=p_active_form;
   gtbBaseClassesFormList:[p_active_form]=info;

   // reduced level indent
   ctl_inheritance_tree_view.p_LevelIndent = _dx2lx(SM_TWIP, 12);
   ctl_member_tree_view.p_LevelIndent = _dx2lx(SM_TWIP, 8);
}

//////////////////////////////////////////////////////////////////////////////
// Blow away our cached window ID on form destroy
//
void _tbbaseclasses_form.on_destroy()
{
   cb_kill_timer();
   cb_kill_timer_highlight();
   gtbBaseClassesFormList._deleteel(p_active_form);
}


//############################################################################
//////////////////////////////////////////////////////////////////////////////
// Handlers for item properties dialog
//
defeventtab _tbsymbol_props_form;

//////////////////////////////////////////////////////////////////////////////
// Refresh the item properities with the given tag information
// Sets all the controls with the appropriate values, and puts the
// member name(type_name) in the caption for the dialog.
//
void cb_refresh_property_view(struct VS_TAG_BROWSE_INFO cm,int form_wid=-1)
{
   //say("cb_refresh_property_view: here 1");
   // bail out if we have no member name
   if (cm.member_name._isempty() || cm.member_name == "") {
      return;
   }

   // Refresh the specific form requested
   f := form_wid;
   if (f > 0) {
      cb_refresh_property_view_for_one_window(cm, form_wid);
      return;
   }

   // refresh all instances of the arguments toolbar
   cbrowser_form := p_active_form;
   found_one := false;
   foreach (f => . in gtbPropsFormList) {
      if (tw_is_from_same_mdi(f,cbrowser_form)) {
         found_one=true;
         cb_refresh_property_view_for_one_window(cm,f);
      }
   }
   if (!found_one) {
      f=_tbGetActiveSymbolPropertiesForm();
      if (f) {
         cb_refresh_property_view_for_one_window(cm,f);
      }
   }
}
void cb_refresh_property_view_for_one_window(struct VS_TAG_BROWSE_INFO cm,int form_wid=-1)
{
   //say("cb_refresh_property_view: here 1");
   // bail out if we have no member name
   if (cm.member_name._isempty() || cm.member_name == "") {
      return;
   }

   // get the properties dialog window ID
   int f=form_wid;
   if (f<0) {
      f=_tbGetActiveSymbolPropertiesForm();
   }
   if (!f) {
      return;
   }

   _nocheck _control ctl_proto_check_box;
   _nocheck _control ctl_const_check_box;
   _nocheck _control ctl_final_check_box;
   _nocheck _control ctl_inline_check_box;
   _nocheck _control ctl_static_check_box;
   _nocheck _control ctl_virtual_check_box;
   _nocheck _control ctl_override_check_box;
   _nocheck _control ctl_abstract_check_box;
   _nocheck _control ctl_access_check_box;
   _nocheck _control ctl_volatile_check_box;
   _nocheck _control ctl_extern_check_box;
   _nocheck _control ctl_native_check_box;
   _nocheck _control ctl_file_text_box;
   _nocheck _control ctl_name_text_box;
   _nocheck _control ctl_kind_text_box;
   _nocheck _control ctl_template_check_box;
   _nocheck _control ctl_synchronized_check_box;
   _nocheck _control ctl_transient_check_box;
   _nocheck _control ctl_mutable_check_box;
   _nocheck _control ctl_partial_check_box;
   _nocheck _control ctl_forward_check_box;
   _nocheck _control ctl_internal_check_box;
   _nocheck _control ctl_constexpr_check_box;
   _nocheck _control ctl_constinit_check_box;
   _nocheck _control ctl_consteval_check_box;
   _nocheck _control ctl_export_check_box;
   _nocheck _control ctl_linkage_check_box;

   // make sure that cm is totally initialized
   if (cm.tag_database._isempty())   cm.tag_database = "";
   if (cm.category._isempty())       cm.category = "";
   if (cm.class_name._isempty())     cm.class_name = "";
   if (cm.member_name._isempty())    cm.member_name = "";
   if (cm.qualified_name._isempty()) cm.qualified_name = "";
   if (cm.type_name._isempty())      cm.type_name = "";
   if (cm.file_name._isempty())      cm.file_name = "";
   if (cm.return_type._isempty())    cm.return_type = "";
   if (cm.arguments._isempty())      cm.arguments = "";
   if (cm.exceptions._isempty())     cm.exceptions = "";
   if (cm.class_parents._isempty())  cm.class_parents = "";
   if (cm.template_args._isempty())  cm.template_args = "";
   if (cm.language._isempty())       cm.language = "";
   if (cm.language._isempty())       cm.language = "";

   // construct string containing all tag information
   _str cm_string =     "" :+
      cm.tag_database   :+ "\t" :+
      cm.category       :+ "\t" :+
      cm.class_name     :+ "\t" :+
      cm.member_name    :+ "\t" :+
      cm.qualified_name :+ "\t" :+
      cm.type_name      :+ "\t" :+
      cm.file_name      :+ "\t" :+
      cm.line_no        :+ "\t" :+
      cm.flags          :+ "\t" :+
      cm.return_type    :+ "\t" :+
      cm.arguments      :+ "\t" :+
      cm.exceptions     :+ "\t" :+
      cm.class_parents  :+ "\t" :+
      cm.template_args  :+ "\t" :+
      cm.language;

   // blow out of here if tag has not changed
   ucm := f.ctl_name_text_box.p_user;
   if (!ucm._isempty() && ucm._varformat()==VF_LSTR && ucm:==cm_string) {
      return;
   }

   // save tag browse info
   f.ctl_name_text_box.p_user = cm_string;

   // construct the item caption
   item_name := tag_make_caption_from_browse_info(cm, include_class:true, include_args:false, include_tab:false);

   // enable/disable declarations, depending if they are relevent or not
   if (cm.class_name != "" && cm.member_name != "" && cm.type_name :!= "enumc" && cm.type_name :!= "typedef" && cm.type_name :!= "database" && cm.type_name :!="table" && cm.type_name :!= "column" && cm.type_name :!= "view" && cm.type_name :!= "index") {
      f.ctl_const_check_box.p_enabled        = true;
      f.ctl_static_check_box.p_enabled       = true;
      f.ctl_final_check_box.p_enabled        = true;
      f.ctl_access_check_box.p_enabled       = true;
      f.ctl_volatile_check_box.p_enabled     = true;
      f.ctl_synchronized_check_box.p_enabled = true;
      f.ctl_transient_check_box.p_enabled    = true;
      f.ctl_mutable_check_box.p_enabled      = true;
      f.ctl_constexpr_check_box.p_enabled    = true;
      f.ctl_constinit_check_box.p_enabled    = true;
      f.ctl_consteval_check_box.p_enabled    = true;
      f.ctl_export_check_box.p_enabled       = true;
      f.ctl_linkage_check_box.p_enabled      = true;
   } else {
      f.ctl_const_check_box.p_enabled        = false;
      f.ctl_static_check_box.p_enabled       = false;
      f.ctl_final_check_box.p_enabled        = false;
      f.ctl_volatile_check_box.p_enabled     = false;
      f.ctl_synchronized_check_box.p_enabled = false;
      f.ctl_transient_check_box.p_enabled    = false;
      f.ctl_mutable_check_box.p_enabled      = false;
      f.ctl_constexpr_check_box.p_enabled    = false;
      f.ctl_constinit_check_box.p_enabled    = false;
      f.ctl_consteval_check_box.p_enabled    = false;
      f.ctl_export_check_box.p_enabled       = true;
      f.ctl_linkage_check_box.p_enabled      = true;
   }

   // enable/disable other check-boxes, depending on type of tag
   switch (cm.type_name) {
   case "proc":
   case "procproto":
   case "proto":
   case "func":
   case "destr":
   case "constr":
      f.ctl_inline_check_box.p_enabled   = true;
      f.ctl_proto_check_box.p_enabled    = true;
      f.ctl_volatile_check_box.p_enabled = true;
      f.ctl_const_check_box.p_enabled    = true;
      f.ctl_static_check_box.p_enabled   = true;
      f.ctl_final_check_box.p_enabled    = true;
      f.ctl_mutable_check_box.p_enabled  = false;
      f.ctl_partial_check_box.p_enabled  = false;
      f.ctl_forward_check_box.p_enabled  = false;
      if (cm.class_name == "") {
         f.ctl_abstract_check_box.p_enabled = false;
         f.ctl_virtual_check_box.p_enabled  = false;
         f.ctl_override_check_box.p_enabled = false;
      } else {
         f.ctl_virtual_check_box.p_enabled  = true;
         f.ctl_abstract_check_box.p_enabled = true;
         f.ctl_override_check_box.p_enabled = true;
      }
      f.ctl_template_check_box.p_enabled     = true;
      f.ctl_synchronized_check_box.p_enabled = true;
      f.ctl_transient_check_box.p_enabled    = false;
      f.ctl_extern_check_box.p_enabled       = true;
      f.ctl_native_check_box.p_enabled       = true;
      f.ctl_constexpr_check_box.p_enabled    = true;
      f.ctl_constinit_check_box.p_enabled    = true;
      f.ctl_consteval_check_box.p_enabled    = true;
      f.ctl_export_check_box.p_enabled       = true;
      f.ctl_linkage_check_box.p_enabled      = true;
      break;
   case "var":
   case "gvar":
   case "lvar":
   case "param":
   case "prop":
      f.ctl_static_check_box.p_enabled   = true;
      f.ctl_const_check_box.p_enabled    = true;
      f.ctl_final_check_box.p_enabled    = true;
      f.ctl_volatile_check_box.p_enabled = true;
      f.ctl_proto_check_box.p_enabled    = false;
      f.ctl_abstract_check_box.p_enabled = false;
      f.ctl_virtual_check_box.p_enabled  = false;
      f.ctl_override_check_box.p_enabled = false;
      f.ctl_template_check_box.p_enabled = true;
      f.ctl_synchronized_check_box.p_enabled = true;
      f.ctl_transient_check_box.p_enabled = true;
      f.ctl_extern_check_box.p_enabled   = true;
      f.ctl_native_check_box.p_enabled   = false;
      f.ctl_mutable_check_box.p_enabled  = true;
      f.ctl_partial_check_box.p_enabled  = false;
      f.ctl_forward_check_box.p_enabled  = false;
      if (cm.type_name == "prop" || _LanguageInheritsFrom("c", cm.language)) {
         f.ctl_inline_check_box.p_enabled = true;
      } else {
         f.ctl_inline_check_box.p_enabled = false;
      }
      f.ctl_constexpr_check_box.p_enabled = true;
      f.ctl_constinit_check_box.p_enabled = true;
      f.ctl_consteval_check_box.p_enabled = true;
      f.ctl_export_check_box.p_enabled    = true;
      f.ctl_linkage_check_box.p_enabled   = true;
      break;
   case "class":
   case "struct":
      f.ctl_final_check_box.p_enabled    = true;
   case "interface":
   case "concept":
      f.ctl_inline_check_box.p_enabled   = false;
      f.ctl_virtual_check_box.p_enabled  = false;
      f.ctl_override_check_box.p_enabled = false;
      f.ctl_proto_check_box.p_enabled    = false;
      f.ctl_abstract_check_box.p_enabled = true;
      f.ctl_volatile_check_box.p_enabled = false;
      f.ctl_template_check_box.p_enabled = true;
      f.ctl_synchronized_check_box.p_enabled = false;
      f.ctl_transient_check_box.p_enabled = false;
      f.ctl_extern_check_box.p_enabled   = true;
      f.ctl_native_check_box.p_enabled   = true;
      f.ctl_partial_check_box.p_enabled  = true;
      f.ctl_forward_check_box.p_enabled  = true;
      f.ctl_constexpr_check_box.p_enabled = false;
      f.ctl_constinit_check_box.p_enabled = false;
      f.ctl_consteval_check_box.p_enabled = false;
      f.ctl_export_check_box.p_enabled    = true;
      f.ctl_linkage_check_box.p_enabled   = false;
      break;
   case "tag":
      f.ctl_final_check_box.p_enabled    = true;
      f.ctl_inline_check_box.p_enabled   = false;
      f.ctl_virtual_check_box.p_enabled  = false;
      f.ctl_override_check_box.p_enabled = false;
      f.ctl_proto_check_box.p_enabled    = false;
      f.ctl_abstract_check_box.p_enabled = false;
      f.ctl_volatile_check_box.p_enabled = false;
      f.ctl_template_check_box.p_enabled = false;
      f.ctl_synchronized_check_box.p_enabled = false;
      f.ctl_transient_check_box.p_enabled = false;
      f.ctl_extern_check_box.p_enabled   = false;
      f.ctl_native_check_box.p_enabled   = false;
      f.ctl_constexpr_check_box.p_enabled = false;
      f.ctl_constinit_check_box.p_enabled = false;
      f.ctl_consteval_check_box.p_enabled = false;
      f.ctl_export_check_box.p_enabled    = false;
      f.ctl_linkage_check_box.p_enabled   = false;
      break;
   case "import":
      f.ctl_static_check_box.p_enabled   = true;
      f.ctl_inline_check_box.p_enabled   = false;
      f.ctl_virtual_check_box.p_enabled  = false;
      f.ctl_override_check_box.p_enabled = false;
      f.ctl_proto_check_box.p_enabled    = false;
      f.ctl_abstract_check_box.p_enabled = false;
      f.ctl_volatile_check_box.p_enabled = false;
      f.ctl_template_check_box.p_enabled = false;
      f.ctl_synchronized_check_box.p_enabled = false;
      f.ctl_transient_check_box.p_enabled = false;
      f.ctl_extern_check_box.p_enabled   = false;
      f.ctl_native_check_box.p_enabled   = false;
      f.ctl_constexpr_check_box.p_enabled = false;
      f.ctl_constinit_check_box.p_enabled = false;
      f.ctl_consteval_check_box.p_enabled = false;
      f.ctl_export_check_box.p_enabled    = false;
      f.ctl_linkage_check_box.p_enabled   = false;
      break;
   default:
      f.ctl_inline_check_box.p_enabled   = false;
      f.ctl_virtual_check_box.p_enabled  = false;
      f.ctl_override_check_box.p_enabled = false;
      f.ctl_proto_check_box.p_enabled    = false;
      f.ctl_abstract_check_box.p_enabled = false;
      f.ctl_volatile_check_box.p_enabled = false;
      f.ctl_template_check_box.p_enabled = false;
      f.ctl_synchronized_check_box.p_enabled = false;
      f.ctl_transient_check_box.p_enabled = false;
      f.ctl_extern_check_box.p_enabled   = false;
      f.ctl_native_check_box.p_enabled   = false;
      f.ctl_constexpr_check_box.p_enabled = false;
      f.ctl_constinit_check_box.p_enabled = false;
      f.ctl_consteval_check_box.p_enabled = false;
      f.ctl_export_check_box.p_enabled    = false;
      f.ctl_linkage_check_box.p_enabled   = false;
      break;
   }

   // append line number to file name
   file_name := cm.file_name ":" cm.line_no;

   // set the text controls, have to toggle p_ReadOnly to do this
   f.ctl_name_text_box.p_ReadOnly = false;
   f.ctl_file_text_box.p_ReadOnly = false;
   f.ctl_kind_text_box.p_ReadOnly = false;
   f.ctl_name_text_box._begin_line();
   f.ctl_file_text_box._begin_line();
   f.ctl_kind_text_box._begin_line();
   if (cm.member_name!="") {
      f.ctl_name_text_box.p_text = item_name;
   } else {
      f.ctl_name_text_box.p_text = "";
   }
   f.ctl_file_text_box.p_text = file_name;
   f.ctl_kind_text_box.p_text = tag_type_get_description(cm.type_id);
   f.ctl_name_text_box.p_ReadOnly = true;
   f.ctl_file_text_box.p_ReadOnly = true;
   f.ctl_kind_text_box.p_ReadOnly = true;

   // set some of the simple check boxes, depending on flag values
   f.ctl_inline_check_box.p_value       = (cm.flags & SE_TAG_FLAG_INLINE)?       1:0;
   f.ctl_final_check_box.p_value        = (cm.flags & SE_TAG_FLAG_FINAL)?        1:0;
   f.ctl_virtual_check_box.p_value      = (cm.flags & SE_TAG_FLAG_VIRTUAL)?      1:0;
   f.ctl_override_check_box.p_value     = (cm.flags & SE_TAG_FLAG_OVERRIDE)?      1:0;
   f.ctl_const_check_box.p_value        = (cm.flags & SE_TAG_FLAG_CONST)?        1:0;
   f.ctl_static_check_box.p_value       = (cm.flags & SE_TAG_FLAG_STATIC)?       1:0;
   f.ctl_mutable_check_box.p_value      = (cm.flags & SE_TAG_FLAG_MUTABLE)?      1:0;
   f.ctl_partial_check_box.p_value      = (cm.flags & SE_TAG_FLAG_PARTIAL)?      1:0;
   f.ctl_forward_check_box.p_value      = (cm.flags & SE_TAG_FLAG_FORWARD)?      1:0;
   f.ctl_abstract_check_box.p_value     = (cm.flags & SE_TAG_FLAG_ABSTRACT)?     1:0;
   f.ctl_volatile_check_box.p_value     = (cm.flags & SE_TAG_FLAG_VOLATILE)?     1:0;
   f.ctl_template_check_box.p_value     = (cm.flags & SE_TAG_FLAG_TEMPLATE)?     1:0;
   f.ctl_synchronized_check_box.p_value = (cm.flags & SE_TAG_FLAG_SYNCHRONIZED)? 1:0;
   f.ctl_transient_check_box.p_value    = (cm.flags & SE_TAG_FLAG_TRANSIENT)?    1:0;
   f.ctl_extern_check_box.p_value       = (cm.flags & SE_TAG_FLAG_EXTERN)?       1:0;
   f.ctl_native_check_box.p_value       = (cm.flags & SE_TAG_FLAG_NATIVE)?       1:0;
   f.ctl_internal_check_box.p_value     = (cm.flags & SE_TAG_FLAG_INTERNAL)?     1:0;
   f.ctl_constexpr_check_box.p_value    = (cm.flags & SE_TAG_FLAG_CONSTEXPR)?    1:0;
   f.ctl_constinit_check_box.p_value    = (cm.flags & SE_TAG_FLAG_CONSTINIT)?    1:0;
   f.ctl_consteval_check_box.p_value    = (cm.flags & SE_TAG_FLAG_CONSTEVAL)?    1:0;
   f.ctl_export_check_box.p_value       = (cm.flags & SE_TAG_FLAG_EXPORT)?       1:0;
   f.ctl_linkage_check_box.p_value      = (cm.flags & SE_TAG_FLAG_LINKAGE)?      1:0;

   // set captions for public, protected, private, or package
   if (cm.member_name != "" && cm.type_name :!= "enumc" && cm.type_name :!= "database" && cm.type_name :!= "define" && cm.type_name :!= "undef" && cm.type_name :!= "table" && cm.type_name :!= "view" && cm.type_name :!= "column" && cm.type_name :!= "index") {
      f.ctl_access_check_box.p_value = 1;
      f.ctl_access_check_box.p_enabled = true;
      switch (cm.flags & SE_TAG_FLAG_ACCESS) {
      case SE_TAG_FLAG_PROTECTED:
         f.ctl_access_check_box.p_caption = "Protected";
         break;
      case SE_TAG_FLAG_PRIVATE:
         f.ctl_access_check_box.p_caption = "Private";
         break;
      case SE_TAG_FLAG_PACKAGE:
         f.ctl_access_check_box.p_caption = "Package";
         break;
      default: // SE_TAG_FLAG_PUBLIC:
         if (cm.class_name == "") {
            f.ctl_access_check_box.p_caption = "Global";
         } else {
            f.ctl_access_check_box.p_caption = "Public";
         }
         if (cm.flags & SE_TAG_FLAG_INTERNAL) {
            f.ctl_access_check_box.p_value = 0;
         }
         break;
      }
   } else {
      f.ctl_access_check_box.p_caption = "Public";
      f.ctl_access_check_box.p_value = 0;
      f.ctl_access_check_box.p_enabled = false;
   }

   // reset caption for some items that are modified by callbacks
   f.ctl_volatile_check_box.p_caption = "Volatile";

   // disable props by extension
   lang := cm.language;
   if (length(lang) <= 0) {
      lang = _Filename2LangId(cm.file_name);
   }
   if (!_LanguageInheritsFrom("cs",lang)) {
      f.ctl_forward_check_box.p_enabled = false;
   }
   f.cb_default_disable_props(cm.file_name,lang);

   // set value for "Prototype" check box
   f.ctl_proto_check_box.p_value = 0;
   if (cm.type_name:=="proto" || cm.type_name:=="procproto") {
      f.ctl_proto_check_box.p_value = 1;
   }
}

// check if there is an extension-specific function
// for enable-disable of check-boxes
static void cb_default_disable_props(_str file_name, _str ext)
{
   DPindex := _FindLanguageCallbackIndex("_%s_disable_props",ext);
   if (index_callable(DPindex)) {
      call_index(DPindex);
   }
}

//////////////////////////////////////////////////////////////////////////////
// extension-specific disabling of tag properties check-boxes
//
void _ada_disable_props()
{
   ctl_final_check_box.p_enabled        = false;
   ctl_synchronized_check_box.p_enabled = false;
   ctl_native_check_box.p_enabled       = false;
   ctl_volatile_check_box.p_enabled     = false;
   ctl_transient_check_box.p_enabled    = false;
   ctl_partial_check_box.p_enabled      = false;
   ctl_constexpr_check_box.p_enabled    = false;
   ctl_constinit_check_box.p_enabled    = false;
   ctl_consteval_check_box.p_enabled    = false;
}
void _as_disable_props()
{
   ctl_inline_check_box.p_enabled       = false;
   ctl_virtual_check_box.p_enabled      = false;
   ctl_override_check_box.p_enabled     = false;
   ctl_synchronized_check_box.p_enabled = false;
   ctl_volatile_check_box.p_enabled     = false;
   ctl_abstract_check_box.p_enabled     = false;
   ctl_transient_check_box.p_enabled    = false;
   ctl_template_check_box.p_enabled     = false;
   ctl_extern_check_box.p_enabled       = false;
   ctl_mutable_check_box.p_enabled      = false;
   ctl_partial_check_box.p_enabled      = false;
   ctl_constexpr_check_box.p_enabled    = false;
   ctl_constinit_check_box.p_enabled    = false;
   ctl_consteval_check_box.p_enabled    = false;
}
void _asm_disable_props()
{
   ctl_final_check_box.p_enabled        = false;
   ctl_inline_check_box.p_enabled       = false;
   ctl_virtual_check_box.p_enabled      = false;
   ctl_override_check_box.p_enabled     = false;
   ctl_synchronized_check_box.p_enabled = false;
   ctl_native_check_box.p_enabled       = false;
   ctl_volatile_check_box.p_enabled     = false;
   ctl_abstract_check_box.p_enabled     = false;
   ctl_transient_check_box.p_enabled    = false;
   ctl_template_check_box.p_enabled     = false;
   ctl_extern_check_box.p_enabled       = false;
   ctl_partial_check_box.p_enabled      = false;
   ctl_constexpr_check_box.p_enabled    = false;
   ctl_constinit_check_box.p_enabled    = false;
   ctl_consteval_check_box.p_enabled    = false;
}
void _masm_disable_props()
{
   ctl_final_check_box.p_enabled        = false;
   ctl_inline_check_box.p_enabled       = false;
   ctl_virtual_check_box.p_enabled      = false;
   ctl_override_check_box.p_enabled     = false;
   ctl_synchronized_check_box.p_enabled = false;
   ctl_native_check_box.p_enabled       = false;
   ctl_volatile_check_box.p_enabled     = false;
   ctl_abstract_check_box.p_enabled     = false;
   ctl_transient_check_box.p_enabled    = false;
   ctl_template_check_box.p_enabled     = false;
   ctl_extern_check_box.p_enabled       = false;
   ctl_partial_check_box.p_enabled      = false;
   ctl_constexpr_check_box.p_enabled    = false;
   ctl_constinit_check_box.p_enabled    = false;
   ctl_consteval_check_box.p_enabled    = false;
}
void _asm390_disable_props()
{
   ctl_final_check_box.p_enabled        = false;
   ctl_inline_check_box.p_enabled       = false;
   ctl_virtual_check_box.p_enabled      = false;
   ctl_override_check_box.p_enabled     = false;
   ctl_synchronized_check_box.p_enabled = false;
   ctl_native_check_box.p_enabled       = false;
   ctl_volatile_check_box.p_enabled     = false;
   ctl_abstract_check_box.p_enabled     = false;
   ctl_transient_check_box.p_enabled    = false;
   ctl_template_check_box.p_enabled     = false;
   ctl_extern_check_box.p_enabled       = false;
   ctl_partial_check_box.p_enabled      = false;
   ctl_constexpr_check_box.p_enabled    = false;
   ctl_constinit_check_box.p_enabled    = false;
   ctl_consteval_check_box.p_enabled    = false;
}
void _s_disable_props()
{
   ctl_final_check_box.p_enabled        = false;
   ctl_inline_check_box.p_enabled       = false;
   ctl_virtual_check_box.p_enabled      = false;
   ctl_override_check_box.p_enabled     = false;
   ctl_synchronized_check_box.p_enabled = false;
   ctl_native_check_box.p_enabled       = false;
   ctl_volatile_check_box.p_enabled     = false;
   ctl_abstract_check_box.p_enabled     = false;
   ctl_transient_check_box.p_enabled    = false;
   ctl_template_check_box.p_enabled     = false;
   ctl_extern_check_box.p_enabled       = false;
   ctl_partial_check_box.p_enabled      = false;
   ctl_constexpr_check_box.p_enabled    = false;
   ctl_constinit_check_box.p_enabled    = false;
   ctl_consteval_check_box.p_enabled    = false;
}
void _bas_disable_props()
{
   ctl_inline_check_box.p_enabled       = false;
   ctl_synchronized_check_box.p_enabled = false;
   ctl_native_check_box.p_enabled       = false;
   ctl_volatile_check_box.p_enabled     = false;
   ctl_transient_check_box.p_enabled    = false;
   ctl_template_check_box.p_enabled     = false;
   ctl_mutable_check_box.p_enabled      = false;
   ctl_constexpr_check_box.p_enabled    = false;
   ctl_constinit_check_box.p_enabled    = false;
   ctl_consteval_check_box.p_enabled    = false;
}
void _c_disable_props()
{
   ctl_synchronized_check_box.p_enabled = false;
   ctl_native_check_box.p_enabled       = false;
   ctl_transient_check_box.p_enabled    = false;
   ctl_partial_check_box.p_enabled      = false;
}
void _cob_disable_props()
{
   ctl_static_check_box.p_enabled       = true;
   ctl_final_check_box.p_enabled        = false;
   ctl_inline_check_box.p_enabled       = false;
   ctl_virtual_check_box.p_enabled      = false;
   ctl_override_check_box.p_enabled     = false;
   ctl_synchronized_check_box.p_enabled = false;
   ctl_native_check_box.p_enabled       = false;
   ctl_const_check_box.p_enabled        = false;
   ctl_volatile_check_box.p_enabled     = false;
   ctl_abstract_check_box.p_enabled     = true;
   ctl_transient_check_box.p_enabled    = false;
   ctl_template_check_box.p_enabled     = true;
   ctl_extern_check_box.p_enabled       = true;
   ctl_mutable_check_box.p_enabled      = false;
   ctl_partial_check_box.p_enabled      = false;
   ctl_constexpr_check_box.p_enabled    = false;
   ctl_constinit_check_box.p_enabled    = false;
   ctl_consteval_check_box.p_enabled    = false;
}
void _e_disable_props()
{
   ctl_final_check_box.p_enabled        = false;
   ctl_inline_check_box.p_enabled       = false;
   ctl_virtual_check_box.p_enabled      = false;
   ctl_override_check_box.p_enabled     = false;
   ctl_synchronized_check_box.p_enabled = false;
   ctl_volatile_check_box.p_enabled     = false;
   ctl_abstract_check_box.p_enabled     = false;
   ctl_transient_check_box.p_enabled    = false;
   ctl_template_check_box.p_enabled     = false;
   ctl_mutable_check_box.p_enabled      = false;
   ctl_partial_check_box.p_enabled      = false;
   ctl_constexpr_check_box.p_enabled    = false;
   ctl_constinit_check_box.p_enabled    = false;
   ctl_consteval_check_box.p_enabled    = false;
}
void _idl_disable_props()
{
   ctl_final_check_box.p_enabled        = false;
   ctl_inline_check_box.p_enabled       = false;
   ctl_virtual_check_box.p_enabled      = false;
   ctl_override_check_box.p_enabled     = false;
   ctl_synchronized_check_box.p_enabled = false;
   ctl_volatile_check_box.p_enabled     = false;
   ctl_abstract_check_box.p_enabled     = false;
   ctl_transient_check_box.p_enabled    = false;
   ctl_template_check_box.p_enabled     = false;
   ctl_extern_check_box.p_enabled       = false;
   ctl_mutable_check_box.p_enabled      = false;
   ctl_partial_check_box.p_enabled      = false;
   ctl_constexpr_check_box.p_enabled    = false;
   ctl_constinit_check_box.p_enabled    = false;
   ctl_consteval_check_box.p_enabled    = false;
}
void _java_disable_props()
{
   ctl_template_check_box.p_enabled     = true;
   ctl_extern_check_box.p_enabled       = false;
   ctl_mutable_check_box.p_enabled      = false;
   ctl_partial_check_box.p_enabled      = false;
   ctl_constexpr_check_box.p_enabled    = false;
   ctl_constinit_check_box.p_enabled    = false;
   ctl_consteval_check_box.p_enabled    = false;
}
void _d_disable_props()
{
   ctl_mutable_check_box.p_enabled      = false;
   ctl_partial_check_box.p_enabled      = false;
   ctl_constexpr_check_box.p_enabled    = false;
   ctl_constinit_check_box.p_enabled    = false;
   ctl_consteval_check_box.p_enabled    = false;
}
void _cs_disable_props()
{
   ctl_template_check_box.p_enabled     = true;
   ctl_extern_check_box.p_enabled       = false;
   ctl_mutable_check_box.p_enabled      = false;
   ctl_partial_check_box.p_enabled      = true;
   ctl_internal_check_box.p_enabled     = true;
   ctl_volatile_check_box.p_enabled     = true;
   ctl_volatile_check_box.p_caption = "Unsafe";
   ctl_constexpr_check_box.p_enabled    = false;
   ctl_constinit_check_box.p_enabled    = false;
   ctl_consteval_check_box.p_enabled    = false;
}
void _js_disable_props()
{
   ctl_template_check_box.p_enabled     = false;
   ctl_mutable_check_box.p_enabled      = false;
   ctl_partial_check_box.p_enabled      = false;
   ctl_constexpr_check_box.p_enabled    = false;
   ctl_constinit_check_box.p_enabled    = false;
   ctl_consteval_check_box.p_enabled    = false;
}
void _cfscript_disable_props()
{
   ctl_template_check_box.p_enabled     = false;
   ctl_mutable_check_box.p_enabled      = false;
   ctl_partial_check_box.p_enabled      = false;
   ctl_constexpr_check_box.p_enabled    = false;
   ctl_constinit_check_box.p_enabled    = false;
   ctl_consteval_check_box.p_enabled    = false;
}
void _phpscript_disable_props()
{
   ctl_template_check_box.p_enabled     = false;
   ctl_mutable_check_box.p_enabled      = false;
   ctl_partial_check_box.p_enabled      = false;
   ctl_constexpr_check_box.p_enabled    = false;
   ctl_constinit_check_box.p_enabled    = false;
   ctl_consteval_check_box.p_enabled    = false;
}
void _cics_disable_props()
{
   ctl_template_check_box.p_enabled     = false;
   ctl_mutable_check_box.p_enabled      = false;
   ctl_partial_check_box.p_enabled      = false;
   ctl_constexpr_check_box.p_enabled    = false;
   ctl_constinit_check_box.p_enabled    = false;
   ctl_consteval_check_box.p_enabled    = false;
}
void _pas_disable_props()
{
   ctl_static_check_box.p_enabled       = false;
   ctl_final_check_box.p_enabled        = false;
   ctl_inline_check_box.p_enabled       = false;
   ctl_synchronized_check_box.p_enabled = false;
   ctl_native_check_box.p_enabled       = false;
   ctl_volatile_check_box.p_enabled     = false;
   ctl_transient_check_box.p_enabled    = false;
   ctl_template_check_box.p_enabled     = false;
   ctl_mutable_check_box.p_enabled      = false;
   ctl_partial_check_box.p_enabled      = false;
   ctl_constexpr_check_box.p_enabled    = false;
   ctl_constinit_check_box.p_enabled    = false;
   ctl_consteval_check_box.p_enabled    = false;
}
void _pl_disable_props()
{
   ctl_final_check_box.p_enabled        = false;
   ctl_inline_check_box.p_enabled       = false;
   ctl_virtual_check_box.p_enabled      = false;
   ctl_override_check_box.p_enabled     = false;
   ctl_synchronized_check_box.p_enabled = false;
   ctl_native_check_box.p_enabled       = false;
   ctl_transient_check_box.p_enabled    = false;
   ctl_template_check_box.p_enabled     = false;
   ctl_mutable_check_box.p_enabled      = false;
   ctl_partial_check_box.p_enabled      = false;
   ctl_constexpr_check_box.p_enabled    = false;
   ctl_constinit_check_box.p_enabled    = false;
   ctl_consteval_check_box.p_enabled    = false;
}
void _py_disable_props()
{
   ctl_final_check_box.p_enabled        = false;
   ctl_inline_check_box.p_enabled       = false;
   ctl_virtual_check_box.p_enabled      = false;
   ctl_override_check_box.p_enabled     = false;
   ctl_synchronized_check_box.p_enabled = false;
   ctl_native_check_box.p_enabled       = false;
   ctl_transient_check_box.p_enabled    = false;
   ctl_template_check_box.p_enabled     = false;
   ctl_mutable_check_box.p_enabled      = false;
   ctl_partial_check_box.p_enabled      = false;
   ctl_constexpr_check_box.p_enabled    = false;
   ctl_constinit_check_box.p_enabled    = false;
   ctl_consteval_check_box.p_enabled    = false;
}

//////////////////////////////////////////////////////////////////////////////
// try to restore property view from previously stored information
//
static void maybe_restore_property_view(typeless ucm)
{
   if (!ucm._isempty() && ucm._varformat() == VF_LSTR && length(ucm) > 0) {
      tag_init_tag_browse_info(auto cm);
      _str tb,ln,fl;
      parse ucm with cm.tag_database "\t" cm.category "\t" cm.class_name "\t" cm.member_name "\t" cm.qualified_name "\t" cm.type_name "\t" cm.file_name "\t" ln "\t" fl "\t" cm.return_type "\t" cm.arguments "\t" cm.exceptions "\t" cm.class_parents "\t" cm.template_args "\t" cm.language;
      cm.line_no = (isinteger(ln))? (int)ln : 0;
      cm.flags   = (isinteger(fl))? (SETagFlags)fl : SE_TAG_FLAG_NULL;
      cb_refresh_property_view_for_one_window(cm,p_active_form);
   }
}

//////////////////////////////////////////////////////////////////////////////
// On form creation, get argument, and pass to refresh, cache window ID.
//
void ctl_name_label.on_create(struct VS_TAG_BROWSE_INFO cm=null, _str activeTab="")
{
   TBPROPS_FORM_INFO info;
   info.m_form_wid=p_active_form;
   gtbPropsFormList:[p_active_form]=info;

   // Init vars private to tab control:
   typeless ht:[];
   ht:["_formW"] = p_active_form.p_width;
   ht:["_formH"] = p_active_form.p_height;
   ht:["_output_sstabW"] = p_width;
   ht:["_output_sstabH"] = p_height;
   p_user = ht;

   // If active tab is specified as second argument.
   // Otherwise, use the saved value.
   if (activeTab != "" && isinteger(activeTab)) {
      p_ActiveTab = (int)activeTab;
   } else {
      _retrieve_value();
   }

   // if we were passed a tag argument, display its properties
   if (cm != null) {
      cb_refresh_property_view_for_one_window(cm,p_active_form);
   } else {
      typeless ucm = _retrieve_value("_tbsymbol_props_form.ctl_name_text_box.p_user");
      maybe_restore_property_view(ucm);
   }
}

//////////////////////////////////////////////////////////////////////////////
// On destroy, blow away the cached window ID
//
void _tbsymbol_props_form.on_destroy()
{
   _append_retrieve(0, ctl_name_text_box.p_user, "_tbsymbol_props_form.ctl_name_text_box.p_user");
   call_event(p_window_id,ON_DESTROY,'2');
   gtbPropsFormList._deleteel(p_active_form);
}

//////////////////////////////////////////////////////////////////////////////
// For any check box on this form, make it behave as read-only by
// resetting it's value in the lbutton_up callback.
//
void ctl_static_check_box.lbutton_up()
{
   p_value = (p_value)? 0:1;
}

//////////////////////////////////////////////////////////////////////////////
// handle resize event
//
void _tbsymbol_props_form.on_resize(bool forcedResize=false)
{
   typeless lastW, lastH;
   typeless ht:[];
   ht = ctl_name_label.p_user;
   if (ht._indexin("formWH")) {
      _str text;
      text = ht:["formWH"];
      parse text with lastW lastH;
      if (!forcedResize && lastW == p_width && lastH == p_height) return;
   } else {
      ht:["formWH"] = p_width:+" ":+p_height;
      ctl_name_label.p_user = ht;
      return;
   }

   // border size
   border_x := ctl_static_check_box.p_x;
   border_y := ctl_name_text_box.p_y;

   // available space and border usage
   avail_x := _dx2lx(SM_TWIP,p_client_width)  - border_x;
   avail_y := _dy2ly(SM_TWIP,p_client_height) - border_y;

   // x-position and height of tag name text box
   name_x  := ctl_name_text_box.p_x;
   name_y  := ctl_name_text_box.p_height;

   // adjust the items inside the properties tab
   ctl_name_text_box.p_width = avail_x - name_x;
   ctl_file_text_box.p_width = avail_x - name_x;
   ctl_kind_text_box.p_width = avail_x - name_x;

   _control ctl_static_check_box;
   _control ctl_const_check_box;
   _control ctl_final_check_box;
   _control ctl_proto_check_box;
   _control ctl_inline_check_box;
   _control ctl_volatile_check_box;
   _control ctl_access_check_box;
   _control ctl_abstract_check_box;
   _control ctl_virtual_check_box;
   _control ctl_override_check_box;
   _control ctl_transient_check_box;
   _control ctl_synchronized_check_box;
   _control ctl_template_check_box;
   _control ctl_native_check_box;
   _control ctl_extern_check_box;
   _control ctl_partial_check_box;
   _control ctl_forward_check_box;
   _control ctl_mutable_check_box;
   _control ctl_internal_check_box;
   _control ctl_constexpr_check_box;
   _control ctl_constinit_check_box;
   _control ctl_consteval_check_box;
   _control ctl_export_check_box;
   _control ctl_linkage_check_box;

   int check_box_order[];
   check_box_order._makeempty();
   check_box_order :+= ctl_static_check_box;
   check_box_order :+= ctl_access_check_box;
   check_box_order :+= ctl_internal_check_box;
   check_box_order :+= ctl_extern_check_box;
   check_box_order :+= ctl_export_check_box;
   check_box_order :+= ctl_linkage_check_box;
   check_box_order :+= ctl_const_check_box;
   check_box_order :+= ctl_volatile_check_box;
   check_box_order :+= ctl_final_check_box;
   check_box_order :+= ctl_proto_check_box;
   check_box_order :+= ctl_forward_check_box;
   check_box_order :+= ctl_inline_check_box;
   check_box_order :+= ctl_mutable_check_box;
   check_box_order :+= ctl_abstract_check_box;
   check_box_order :+= ctl_virtual_check_box;
   check_box_order :+= ctl_override_check_box;
   check_box_order :+= ctl_transient_check_box;
   check_box_order :+= ctl_synchronized_check_box;
   check_box_order :+= ctl_template_check_box;
   check_box_order :+= ctl_native_check_box;
   check_box_order :+= ctl_partial_check_box;
   check_box_order :+= ctl_constexpr_check_box;
   check_box_order :+= ctl_constinit_check_box;
   check_box_order :+= ctl_consteval_check_box;

   // lay out the check boxes in the maximum number of columns that fit.
   check_x := ctl_static_check_box.p_x;
   check_y := ctl_static_check_box.p_y;
   check_w := ctl_static_check_box.p_width;
   check_h := ctl_static_check_box.p_y - ctl_kind_text_box.p_y - border_y;
   columns := (avail_x intdiv check_w);
   columns = (columns == 0)? 1 : columns;
   columns = (columns >= 8)? 8 : columns;
   for (i:=0; i<check_box_order._length(); i++) {
      check_box_order[i].p_x = check_x + check_w*(i % columns);
      check_box_order[i].p_y = check_y + check_h*(i intdiv columns);
   }

   // Save form's new XYWH:
   ht:["formWH"] = p_width:+" ":+p_height;
   ctl_name_label.p_user = ht;
}


//############################################################################
//////////////////////////////////////////////////////////////////////////////
// Handlers for item properties dialog
//
defeventtab _tbsymbol_args_form;

//////////////////////////////////////////////////////////////////////////////
// Refresh the item properities with the given tag information
// Sets all the controls with the appropriate values, and puts the
// member name(type_name) in the caption for the dialog.
//
void cb_refresh_arguments_view(struct VS_TAG_BROWSE_INFO cm, int form_wid=-1)
{
   //say("cb_refresh_arguments_view: here 1");
   // bail out if we have no member name
   if (cm.member_name._isempty() || cm.member_name == "") {
      return;
   }

   // Refresh the specific form requested
   f := form_wid;
   if (f > 0) {
      cb_refresh_arguments_view_for_one_window(cm, form_wid);
      return;
   }

   // refresh all instances of the arguments toolbar
   cbrowser_form := p_active_form;
   found_one := false;
   foreach (f => . in gtbArgsFormList) {
      if (tw_is_from_same_mdi(f,cbrowser_form)) {
         found_one=true;
         cb_refresh_arguments_view_for_one_window(cm,f);
      }
   }
   if (!found_one) {
      f=_tbGetActiveSymbolArgumentsForm();
      if (f) {
         cb_refresh_arguments_view_for_one_window(cm,f);
      }
   }
}
static void cb_refresh_arguments_view_for_one_window(struct VS_TAG_BROWSE_INFO cm, int form_wid=-1)
{
   //say("cb_refresh_arguments_view: here 1");
   // bail out if we have no member name
   if (cm.member_name._isempty() || cm.member_name == "") {
      return;
   }

   // get the properties dialog window ID
   f := form_wid;
   if (f<0) {
      f=_tbGetActiveSymbolArgumentsForm();
   }
   if (!f) {
      return;
   }

   _nocheck _control ctl_aname_text_box;
   _nocheck _control ctl_type_text_box;
   _nocheck _control ctl_template_list_box;
   _nocheck _control ctl_args_list_box;
   _nocheck _control ctl_args_label;
   _nocheck _control ctl_type_label;
   _nocheck _control ctl_template_label;

   // make sure that cm is totally initialized
   if (cm.tag_database._isempty())   cm.tag_database = "";
   if (cm.category._isempty())       cm.category = "";
   if (cm.class_name._isempty())     cm.class_name = "";
   if (cm.member_name._isempty())    cm.member_name = "";
   if (cm.qualified_name._isempty()) cm.qualified_name = "";
   if (cm.type_name._isempty())      cm.type_name = "";
   if (cm.file_name._isempty())      cm.file_name = "";
   if (cm.return_type._isempty())    cm.return_type = "";
   if (cm.arguments._isempty())      cm.arguments = "";
   if (cm.exceptions._isempty())     cm.exceptions = "";
   if (cm.class_parents._isempty())  cm.class_parents = "";
   if (cm.template_args._isempty())  cm.template_args = "";
   if (cm.language._isempty())       cm.language = "";
   if (cm.language._isempty())       cm.language = "";

   // construct string containing all tag information
   _str cm_string =     "" :+
      cm.tag_database   :+ "\t" :+
      cm.category       :+ "\t" :+
      cm.class_name     :+ "\t" :+
      cm.member_name    :+ "\t" :+
      cm.qualified_name :+ "\t" :+
      cm.type_name      :+ "\t" :+
      cm.file_name      :+ "\t" :+
      cm.line_no        :+ "\t" :+
      cm.flags          :+ "\t" :+
      cm.return_type    :+ "\t" :+
      cm.arguments      :+ "\t" :+
      cm.exceptions     :+ "\t" :+
      cm.class_parents  :+ "\t" :+
      cm.template_args  :+ "\t" :+
      cm.language;

   // blow out of here if tag has not changed
   ucm := f.ctl_aname_text_box.p_user;
   if (!ucm._isempty() && ucm._varformat()==VF_LSTR && ucm:==cm_string) {
      return;
   }

   // save tag browse info
   f.ctl_aname_text_box.p_user = cm_string;

   // construct the item caption
   item_name := tag_make_caption_from_browse_info(cm, include_class:true, include_args:false, include_tab:false);

   // append line number to file name
   file_name := cm.file_name ":" cm.line_no;

   // set the text controls, have to toggle p_ReadOnly to do this
   f.ctl_type_text_box.p_ReadOnly = false;
   f.ctl_aname_text_box.p_ReadOnly = false;
   f.ctl_type_text_box._begin_line();
   f.ctl_aname_text_box._begin_line();
   if (cm.member_name!="") {
      f.ctl_aname_text_box.p_text = item_name;
      if (cm.return_type!="") {
         if (cm.exceptions!="") {
            f.ctl_type_text_box.p_text = cm.return_type:+" throws ":+cm.exceptions;
         } else {
            f.ctl_type_text_box.p_text = cm.return_type;
         }
      } else {
         switch (cm.type_name) {
         case "enum":
         case "struct":
         case "class":
         case "typedef":
         case "union":
         case "label":
         case "interface":
         case "constructor":
         case "destructor":
         case "annotation":
         case "region":
         case "note":
         case "todo":
         case "warning":
            f.ctl_type_text_box.p_text = cm.type_name;
            break;
         default:
            f.ctl_type_text_box.p_text = "";
            break;
         }
      }
   } else {
      f.ctl_type_text_box.p_text = "";
      f.ctl_aname_text_box.p_text = "";
   }
   f.ctl_type_text_box.p_ReadOnly = true;
   f.ctl_aname_text_box.p_ReadOnly = true;

   // select the label for the Type/Return Type
   switch (cm.type_name) {
   case "func":
   case "proc":
   case "proto":
   case "procproto":
   case "constr":
   case "destr":
      f.ctl_type_label.p_caption = "Return type:";
      break;
   case "define":
   case "constant":
   case "enumc":
      f.ctl_type_label.p_caption = "Value:";
      break;
   default:
      f.ctl_type_label.p_caption = "Type:";
      break;
   }

   // adjust template label for system verilog
   f.ctl_template_label.p_caption = "Template Arguments:";
   if (_LanguageInheritsFrom("systemverilog", cm.language)) {
      f.ctl_template_label.p_caption = "Parameter Arguments:";
   }

   // parse template signature and dump into list box
   f.ctl_template_list_box._lbclear();
   apos := 0;
   a := "";
   while (tag_get_next_argument(cm.template_args, apos, a) >= 0) {
      f.ctl_template_list_box._lbadd_item(a);
   }
   f.ctl_template_list_box._lbtop();

   // parse signature and dump into list box
   f.ctl_args_list_box._lbclear();
   apos=0;
   while (tag_get_next_argument(cm.arguments, apos, a) >= 0) {
      f.ctl_args_list_box._lbadd_item(a);
   }
   f.ctl_args_list_box._lbtop();

}

//////////////////////////////////////////////////////////////////////////////
// try to restore property view from previously stored information
//
static void maybe_restore_arguments_view(typeless ucm)
{
   if (!ucm._isempty() && ucm._varformat() == VF_LSTR && length(ucm) > 0) {
      tag_init_tag_browse_info(auto cm);
      _str tb,ln,fl;
      parse ucm with cm.tag_database "\t" cm.category "\t" cm.class_name "\t" cm.member_name "\t" cm.qualified_name "\t" cm.type_name "\t" cm.file_name "\t" ln "\t" fl "\t" cm.return_type "\t" cm.arguments "\t" cm.exceptions "\t" cm.class_parents "\t" cm.template_args "\t" cm.language;
      cm.line_no = (isinteger(ln))? (int)ln : 0;
      cm.flags   = (isinteger(fl))? (SETagFlags)fl : SE_TAG_FLAG_NULL;
      cb_refresh_arguments_view_for_one_window(cm,p_active_form);
   }
}

//////////////////////////////////////////////////////////////////////////////
// On form creation, get argument, and pass to refresh, cache window ID.
//
void ctl_aname_label.on_create(struct VS_TAG_BROWSE_INFO cm=null, _str activeTab="")
{
   TBARGS_FORM_INFO info;
   info.m_form_wid=p_active_form;
   gtbArgsFormList:[p_active_form]=info;

   // Init vars private to tab control:
   typeless ht:[];
   ht:["_formW"] = p_active_form.p_width;
   ht:["_formH"] = p_active_form.p_height;
   ht:["_output_sstabW"] = p_width;
   ht:["_output_sstabH"] = p_height;
   p_user = ht;

   // If active tab is specified as second argument.
   // Otherwise, use the saved value.
   if (activeTab != "" && isinteger(activeTab)) {
      p_ActiveTab = (int)activeTab;
   } else {
      _retrieve_value();
   }

   // if we were passed a tag argument, display its properties
   if (cm != null) {
      cb_refresh_arguments_view_for_one_window(cm,p_active_form);
   } else {
      typeless ucm = _retrieve_value("_tbsymbol_args_form.ctl_aname_text_box.p_user");
      maybe_restore_arguments_view(ucm);
   }
}

//////////////////////////////////////////////////////////////////////////////
// On destroy, blow away the cached window ID
//
void _tbsymbol_args_form.on_destroy()
{
   _append_retrieve(0, ctl_aname_text_box.p_user, "_tbsymbol_args_form.ctl_aname_text_box.p_user");
   call_event(p_window_id,ON_DESTROY,'2');
   gtbArgsFormList._deleteel(p_active_form);
}

//////////////////////////////////////////////////////////////////////////////
// handle resize event
//
void _tbsymbol_args_form.on_resize(bool forcedResize=false)
{
   typeless lastW, lastH;
   typeless ht:[];
   ht = ctl_aname_label.p_user;
   if (ht != null && ht._indexin("formWH")) {
      _str text;
      text = ht:["formWH"];
      parse text with lastW lastH;
      if (!forcedResize && lastW == p_width && lastH == p_height) return;
   } else {
      ht:["formWH"] = p_width:+" ":+p_height;
      ctl_aname_label.p_user = ht;
      return;
   }

   // border size
   border_x := ctl_aname_label.p_x;
   border_y := ctl_aname_text_box.p_y;

   // available space and border usage
   avail_x := _dx2lx(SM_TWIP,p_client_width)  - border_x;
   avail_y := _dy2ly(SM_TWIP,p_client_height) - border_y;

   // x-position and height of tag name text box
   name_x := ctl_aname_text_box.p_x;
   name_y := ctl_aname_text_box.p_height;

   // adjust the items inside the arguments tab
   ctl_aname_text_box.p_width = avail_x - name_x - border_x;
   ctl_type_text_box.p_width = avail_x - name_x - border_x;
   ctl_template_list_box.p_width = avail_x - name_x - border_x;
   ctl_args_list_box.p_width  = avail_x - name_x - border_x;
   ctl_args_list_box.p_y_extent = avail_y - ctl_aname_text_box.p_y;
   //ctl_api_button.p_y = ctl_args_list_box.p_y_extent - ctl_api_button.p_height;

   // Save form's new XYWH:
   ht:["formWH"] = p_width:+" ":+p_height;
   ctl_aname_label.p_user = ht;
}


/**
 * Return true if tool-window with name <code>form_name</code> 
 * is in the same tabgroup as tool-window <code>wid</code>. If 
 * <code>wid=0</code> then active window is assumed (which must 
 * be a tool-window). 
 *
 * @param form_name 
 * @param wid 
 *
 * @return bool 
 */
static bool is_same_tabgroup(_str form_name, int wid=0)
{
   wid = wid > 0 ? wid : p_active_form;
   if ( !wid.p_isToolWindow ) {
      return false;
   }

   int first_wid = wid;
   while ( wid > 0 ) {
      wid = tw_next_window(wid, "1", false);
      if ( !wid || wid == first_wid ) {
         break;
      }
      if ( wid.p_name == form_name ) {
         // Winner
         return true;
      }
   }
   // Not in same tabgroup
   return false;
}

//############################################################################
//////////////////////////////////////////////////////////////////////////////
// Refresh the output symbols tab (peek-a-boo window)
//
void cb_refresh_output_tab(struct VS_TAG_BROWSE_INFO cm, bool just_go_there,
                           bool maybeActivateSymbolTab=false,
                           bool activateHiddenSymbolTab=false,
                           enum ActivatePreviewFlags activateHiddenSymbolTabFromOtherFlag=APF_NULL_FLAGS)
{
   if (!_haveContextTagging()) {
      return;
   }
   tagwin_save_tag_info(cm);

   // Activate the symbol tab if it is not currently active
   // Do not activate it if it is auto-hidden or un-docked.
   if (just_go_there && maybeActivateSymbolTab && _autoRestoreFinished() && !tw_is_current_form("_tbtagwin_form") && 
      // Preview tool window not visible cases
      (
       // Auto-hidden case
       (activateHiddenSymbolTab && 
        _iswindow_valid(_get_focus()) &&
        !tw_is_auto_raised(_get_focus().p_active_form) &&
        tw_is_auto_form("_tbtagwin_form")
       )

       ||

       // Docked but not active case
       (activateHiddenSymbolTabFromOtherFlag==APF_NULL_FLAGS &&
        !tw_is_auto_form("_tbtagwin_form") && 
        tw_dock_area_of_form("_tbtagwin_form") &&
        !is_same_tabgroup("_tbtagwin_form")
       )

       ||

       // Activated from other window or operation (docked or auto)
       (doActivatePreviewToolWindow(activateHiddenSymbolTabFromOtherFlag) &&
        !is_same_tabgroup("_tbtagwin_form") && !(tw_is_auto_form("_tbtagwin_form") && tw_is_auto_form(p_active_form.p_name)))
      )
     ) {

      activateSymbolWindow(false);
   }

   // check that the output toolbar is visible
   f := _GetTagwinWID(true);
   if (!f) {
      return;
   }

   // no file name, yikes! 
   if (cm.file_name==null) {
      return;
   }

   // check if there is a load-tags function, if so, bail out
   if (_QBinaryLoadTagsSupported(cm.file_name)) {
      return;
   }

   // if the symbol window has "Prototypes" shut off, display the proc instead
   // if one is found.
   if (!(def_tagwin_flags & SE_TAG_FILTER_PROTOTYPE)) {
      maybe_convert_proto_to_proc(cm);
   }

   // find the output tagwin and update it
   if (cm.member_name != "" || just_go_there) {
      timer_delay := max(CB_TIMER_DELAY_MS, _default_option(VSOPTION_DOUBLE_CLICK_TIME));
      if (just_go_there) timer_delay=0;
      _UpdateTagWindowDelayed(cm, def_tag_hover_delay);
   }
}


//############################################################################
//////////////////////////////////////////////////////////////////////////////
// command control / menu entry points
//

//////////////////////////////////////////////////////////////////////////////
// Bring up symbol browser options form
//
_command cb_options() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Symbols tool window");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   f := _tbGetActiveSymbolsForm();
   if (!f) {
      messageNwait(get_message(VSRC_FORM_NOT_FOUND, TBCBROWSER_FORM));
      return("");
   }
   f.show("-xy _cboptions_form");
}

//////////////////////////////////////////////////////////////////////////////
// Save or print the contents of the symbol browser
//
_command cb_save_print_copy(_str action="") name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // verify the form name
   f := _tbGetActiveSymbolsForm();
   if (!f) {
      messageNwait(get_message(VSRC_FORM_NOT_FOUND, TBCBROWSER_FORM));
      return("");
   }

   // get the window ID of the symbol browser tree
   _nocheck _control ctl_class_tree_view;
   int tree_wid=f.ctl_class_tree_view;

   // OK, we have the tree, now let's rock
   switch (action) {
   case "copy_item":
      tree_wid._TreeCopyContents(tree_wid._TreeCurIndex(), false);
      break;
   // entire tree
   case "copy":
      tree_wid._TreeCopyContents();
      break;
   case "save":
      tree_wid._TreeSaveContents();
      break;
   case "print":
      tree_wid._TreePrintContents();
      break;
   // just the sub tree
   case "copy_subtree":
      tree_wid._TreeCopyContents(tree_wid._TreeCurIndex(), true);
      break;
   case "save_subtree":
      tree_wid._TreeSaveContents(tree_wid._TreeCurIndex());
      break;
   case "print_subtree":
      tree_wid._TreePrintContents(tree_wid._TreeCurIndex());
      break;
   // no argument or bad argument
   default:
      return("");
   }
}

//////////////////////////////////////////////////////////////////////////////
// Return the current symbol referenced under the cursor, of failing that, 
// return the actual definition or declaration under the cursor.
// 
static bool cb_get_symbol_info(VS_TAG_BROWSE_INFO &cm)
{
   // initialize the symbol to blank
   tag_browse_info_init(cm);

   if (_isEditorCtl()) {
      // first try to identify the symbol under the cursor
      status := tag_get_browse_info("", cm, 
                                    quiet:true, 
                                    filterDuplicates:true, 
                                    filterPrototypes:true, 
                                    filterDefinitions:true, 
                                    filterFunctionSignatures:true);
      if (status >= 0 && cm.member_name != "") {
         return true;
      }
      // if not found, try for a symbol definition or declaration 
      // under the cursor
      context_id := tag_get_current_context(cm.member_name, 
                                            cm.flags, 
                                            cm.type_name, 
                                            auto dummy_type_id,
                                            cm.class_name,
                                            auto cur_class,
                                            auto cur_package);
      if (context_id > 0) {
         tag_get_context_info(context_id, cm);
         return true;
      }
      _message_box(nls("No symbol under the cursor."));
      return false;
   }

   // try to get the symbol from the Symbols tool window.
   f := _tbGetActiveSymbolsForm();
   if (!f) {
      _message_box(nls("Symbols tool window not active"));
      return false;
   }

   _nocheck _control ctl_class_tree_view;
   currIndex := f.ctl_class_tree_view._TreeCurIndex();
   if (!f.ctl_class_tree_view.get_user_tag_info(currIndex, cm, false)) {
      _message_box(nls("No symbol selected."));
      return false;
   }
   if (cm.member_name == "") {
      _message_box(nls("No symbol selected."));
      return false;
   }

   // That's all folks
   return true;
}

//////////////////////////////////////////////////////////////////////////////
// Bring up tag properties form and hand it the tag information for
// the current tag.
//
_command cb_props() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Symbols tool window");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // if the current control is the editor, get the symbol from there
   // otherwise, take it form the Symbol Browser tool window.
   if (!cb_get_symbol_info(auto cm)) {
      _message_box(nls("No symbol under the cursor."));
      return VSCODEHELPRC_NO_SYMBOLS_FOUND;
   }

   tbprops_wid := _tbGetActiveSymbolPropertiesForm();
   activate_tool_window(TBPROPS_FORM,false);
   if (!tbprops_wid) {
      tbprops_wid=_tbGetActiveSymbolPropertiesForm();
   }
   cb_refresh_property_view_for_one_window(cm,tbprops_wid);
}

//////////////////////////////////////////////////////////////////////////////
// Bring up tag properties form and hand it the tag information for
// the current tag.
//
_command cb_args() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Symbols tool window");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // if the current control is the editor, get the symbol from there
   // otherwise, take it form the Symbol Browser tool window.
   if (!cb_get_symbol_info(auto cm)) {
      return VSCODEHELPRC_NO_SYMBOLS_FOUND;
   }

   tbargs_wid := _tbGetActiveSymbolArgumentsForm();
   activate_tool_window(TBARGS_FORM,false);
   if (!tbargs_wid) {
      tbargs_wid=_tbGetActiveSymbolArgumentsForm();
   }
   cb_refresh_arguments_view_for_one_window(cm,tbargs_wid);
}

//////////////////////////////////////////////////////////////////////////////
// Bring up tag properties form and hand it the tag information for
// the current tag.
//
_command cb_references() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "References");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   f := _tbGetActiveSymbolsForm();
   if (!f) {
      messageNwait(get_message(VSRC_FORM_NOT_FOUND, TBCBROWSER_FORM));
      return("");
   }
   _nocheck _control ctl_class_tree_view;

   currIndex := f.ctl_class_tree_view._TreeCurIndex();
   if (!f.ctl_class_tree_view.get_user_tag_info(currIndex, auto cm, false)) {
      messageNwait(get_message(NOTHING_SELECTED_RC, TBCBROWSER_FORM));
      return(1);
   }

   // check if the current workspace tag file or extension specific
   // tag file requires occurrences to be tagged.
   if (_MaybeRetagOccurrences(cm.tag_database) == COMMAND_CANCELLED_RC) {
      return(1);
   }
   if(!isEclipsePlugin()) {
      // If form already exists, reuse it.  Otherwise, create it
      activate_tool_window("_tbtagrefs_form");
   } else {
      index := find_index("_refswindow_Activate",PROC_TYPE);
      if (index_callable(index)) {
         (call_index(index));
      }
   }

   // need to populate the form wid here
   // find the output references tab and update it
   refresh_references_tab(cm);
}

//////////////////////////////////////////////////////////////////////////////
/**
 * Bring up call tree form and hand it the tag information for the current tag.
 * 
 * @categories Tagging_Functions
 */
_command int cb_calltree() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Symbols tool window");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // if the current control is the editor, get the symbol from there
   // otherwise, take it form the Symbol Browser tool window.
   if (!cb_get_symbol_info(auto cm)) {
      _message_box(nls("No symbol under the cursor."));
      return VSCODEHELPRC_NO_SYMBOLS_FOUND;
   }

   // for the call tree, we prefer a definition to a declaration
   maybe_convert_proto_to_proc(cm);

   // check if there is a load-tags function, if so, bail out
   if (_QBinaryLoadTagsSupported(cm.file_name)) {
      _message_box(nls("Can not locate source code for %s.",cm.file_name));
      return(1);
   }

   symbolcalls_wid := _tbGetActiveSymbolCallsForm();
   activate_tool_window(TBSYMBOLCALLS_FORM,true,"ctl_call_tree_view");
   if (!symbolcalls_wid) {
      symbolcalls_wid = _tbGetActiveSymbolCallsForm();
   }
   if (!symbolcalls_wid) {
      messageNwait(get_message(VSRC_FORM_NOT_FOUND, TBSYMBOLCALLS_FORM));
      return(1);
   }

   _nocheck _control ctl_call_tree_view;
   symbolcalls_wid=symbolcalls_wid.p_active_form;
   symbolcalls_wid.cb_refresh_calltree_view(cm, symbolcalls_wid);
   symbolcalls_wid.ctl_call_tree_view._TreeTop();
   return 0;
}

//////////////////////////////////////////////////////////////////////////////
/**
 * Bring up caller tree form and hand it the tag information for the current tag.
 * 
 * @categories Tagging_Functions
 */
_command int cb_caller_tree() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Symbols tool window");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // if the current control is the editor, get the symbol from there
   // otherwise, take it form the Symbol Browser tool window.
   if (!cb_get_symbol_info(auto cm)) {
      _message_box(nls("No symbol under the cursor."));
      return VSCODEHELPRC_NO_SYMBOLS_FOUND;
   }

   symbolcallers_wid := _tbGetActiveSymbolCallersForm();
   activate_tool_window(TBSYMBOLCALLERS_FORM,true,"ctl_call_tree_view");
   symbolcallers_wid = _tbGetActiveSymbolCallersForm();
   if (!symbolcallers_wid) {
      messageNwait(get_message(VSRC_FORM_NOT_FOUND, TBSYMBOLCALLERS_FORM));
      return(1);
   }

   _nocheck _control ctl_call_tree_view;
   symbolcallers_wid=symbolcallers_wid.p_active_form;
   symbolcallers_wid.cb_refresh_callertree_view(cm, symbolcallers_wid);
   symbolcallers_wid.ctl_call_tree_view._TreeTop();
   return 0;
}

//////////////////////////////////////////////////////////////////////////////
// Bring up class parents form and hand it the tag information for
// the current tag.
//
_command void cb_parents(_str option="") name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Symbols tool window");
      return;
   }

   f := _tbGetActiveSymbolsForm();
   if (!f) {
      messageNwait(get_message(VSRC_FORM_NOT_FOUND, TBCBROWSER_FORM));
      return;
   }
   int cbrowser_form=f;
   _nocheck _control ctl_class_tree_view;

   currIndex := f.ctl_class_tree_view._TreeCurIndex();
   parentIndex := f.ctl_class_tree_view._TreeGetParentIndex(currIndex);
   show_children := 0;
   f.ctl_class_tree_view._TreeGetInfo(currIndex, show_children);
   cm_status := 0;
   struct VS_TAG_BROWSE_INFO cm;
   if (show_children == TREE_NODE_LEAF) {
      cm_status = f.ctl_class_tree_view.get_user_tag_info(parentIndex, cm, false);
   } else {
      cm_status = f.ctl_class_tree_view.get_user_tag_info(currIndex, cm, false);
   }
   if (!cm_status) {
      messageNwait(get_message(NOTHING_SELECTED_RC, TBCBROWSER_FORM));
      return;
   }
   show_derived := (option=="derived");

   baseclases_wid := (show_derived)? _tbGetActiveDerivedClassesForm():_tbGetActiveBaseClassesForm();
   if (!baseclases_wid) {
      baseclases_wid=activate_tool_window(show_derived? TBDERIVEDCLASSES_FORM:TBBASECLASSES_FORM,true,"ctl_inheritance_tree_view");
      baseclases_wid=baseclases_wid.p_active_form;
   }
   baseclases_wid.cb_refresh_inheritance_view(cbrowser_form,cm,show_derived,false,baseclases_wid);

}

_command void cb_jrefactor(_str params = "") name_info(","VSARG2_EDITORCTL|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      return;
   }

    // get the tag info
   f := _tbGetActiveSymbolsForm();
   if (!f) {
      messageNwait(get_message(VSRC_FORM_NOT_FOUND, TBCBROWSER_FORM));
      return;
   }
   _nocheck _control ctl_class_tree_view;

   index := f.ctl_class_tree_view._TreeCurIndex();
   cm_status := f.ctl_class_tree_view.get_user_tag_info(index, auto cm, false);
   if (!cm_status) {
      messageNwait(get_message(NOTHING_SELECTED_RC, TBCBROWSER_FORM));
      return;
   }

   // fill in the browse info for the tag
   status := tag_complete_browse_info(cm);
   if (status < 0) return;

   // trigger the requested refactoring
   switch(params) {
      case "add_import":
         refactor_add_import(false, cm, _mdi.p_child.p_buf_name);
         break;
      case "goto_import":
         refactor_goto_import(false, cm, _mdi.p_child.p_buf_name);
         break;
      case "organize_imports_options" :
         refactor_organize_imports_options();
         break;
   }
}

/**
 * Trigger a refactoring operation for the currently
 * selected symbol in the symbol browser
 *
 * @param params The quick refactoring to run
 */
_command void cb_quick_refactor(_str params = "") name_info(','VSARG2_EDITORCTL|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      return;
   }

   // get the tag info
   f := _tbGetActiveSymbolsForm();
   if (!f) {
      messageNwait(get_message(VSRC_FORM_NOT_FOUND, TBCBROWSER_FORM));
      return;
   }
   _nocheck _control ctl_class_tree_view;

   index := f.ctl_class_tree_view._TreeCurIndex();
   cm_status := f.ctl_class_tree_view.get_user_tag_info(index, auto cm, false);
   if (!cm_status) {
      messageNwait(get_message(NOTHING_SELECTED_RC, TBCBROWSER_FORM));
      return;
   }

   // fill in the browse info for the tag
   int status = tag_complete_browse_info(cm);
   if(status < 0) return;

   _str lang=_Filename2LangId(cm.file_name);
   typeless s_syntax_indent;

   // trigger the requested refactoring
   switch(params) {
      case "quick_encapsulate_field" :
         refactor_start_quick_encapsulate(cm);
         break;
      case "quick_rename":
         refactor_quick_rename_symbol(cm);
         break;
      case "quick_modify_params":
         if(cm.type_name == "proto" || cm.type_name == "procproto") {
            if(!refactor_convert_proto_to_proc(cm)) {
               _message_box("Cannot perform quick modify parameters refactoring because the function definition could not be found",
                            "Modify Parameters");
               break;
            }
         }

         refactor_start_quick_modify_params(cm);
         break;

      // symbol browser doesn't have any info about local variables
      //case "local_to_field": break;
   }
}

/**
 * Trigger a refactoring operation for the currently
 * selected symbol in the symbol browser
 *
 * @param params The refactoring to run
 */
_command void cb_refactor(_str params = "") name_info(','VSARG2_EDITORCTL|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      return;
   }

   // get the tag info
   f := _tbGetActiveSymbolsForm();
   if (!f) {
      messageNwait(get_message(VSRC_FORM_NOT_FOUND, TBCBROWSER_FORM));
      return;
   }
   _nocheck _control ctl_class_tree_view;

   index := f.ctl_class_tree_view._TreeCurIndex();
   cm_status := f.ctl_class_tree_view.get_user_tag_info(index, auto cm, false);
   if (!cm_status) {
      messageNwait(get_message(NOTHING_SELECTED_RC, TBCBROWSER_FORM));
      return;
   }

   // fill in the browse info for the tag
   int status = tag_complete_browse_info(cm);
   if(status < 0) return;

   // trigger the requested refactoring
   switch(params) {
      case "extract_super_class":
         refactor_extract_class_symbol(cm,true);
         break;
      case "extract_class":
         refactor_extract_class_symbol(cm,false);
         break;
      case "encapsulate" :
         refactor_start_encapsulate(cm);
         break;
      case "move_field":
         refactor_start_move_field(cm);         
         break;
      case "standard_methods" :
         refactor_start_standard_methods(cm);
         break;
      case "rename":
         refactor_rename_symbol(cm);
         break;
      case "global_to_field":
         refactor_global_to_field_symbol(cm);
         break;
      case "static_to_instance_method":
         refactor_static_to_instance_method_symbol(cm);
         break;
      case "move_method":
         refactor_move_method_symbol(cm);
         break;
      case "pull_up":
         refactor_pull_up_symbol(cm);
         break;
      case "push_down":
         refactor_push_down_symbol(cm);
         break;
      case "modify_params":
         if(cm.type_name == "proto" || cm.type_name == "procproto") {
            if(!refactor_convert_proto_to_proc(cm)) {
               _message_box("Cannot perform modify parameters refactoring because the function definition could not be found",
                            "Modify Parameters");
               break;
            }
         }

         refactor_start_modify_params(cm);
         break;
      // symbol browser doesn't have any info about local variables
      //case "local_to_field": break;
   }
}


//////////////////////////////////////////////////////////////////////////////
// Callback used by _sellist form when user makes choice of tag
//
static _str _taglist_callback(int reason,var result,typeless key)
{
   _nocheck _control _sellist;
   if (reason==SL_ONDEFAULT) {  // Enter key
      result=_sellist.p_line-1;
      return(1);
   }
   return("");
}

//////////////////////////////////////////////////////////////////////////////
// Returns the number of exact matches for the given tag name
// Returns either 0, 1, or 2, since it short cuts the search after
// it determines that there is more than one match.
//
static int number_of_exact_matches(_str proc_name, _str type_name,
                                   _str class_name, typeless &tag_files)
{
   // count the number of exact matches for this tag
   i := count := status := 0;
   tag_filename := next_tag_filea(tag_files,i,false,true);
   while (tag_filename != "") {
      status = tag_find_equal(proc_name);
      while (status==0) {
         tag_get_tag_browse_info(auto cm);
         if (type_name=="" || type_name :== cm.type_name) {
            if (class_name=="" || class_name :== cm.class_name) {
               ++count;
               if (count >= 2) {
                  tag_reset_find_tag();
                  return 2;
               }
            }
         }
         status = tag_next_equal();
      }
      tag_reset_find_tag();
      tag_filename=next_tag_filea(tag_files,i,false,true);
   }

   return count;
}

//////////////////////////////////////////////////////////////////////////////
// Returns the number of prefix matches for the given tag name
// Returns either 0, 1, or 2, since it short cuts the search after
// it determines that there is more than one match.
//
static int number_of_prefix_matches(_str proc_name, typeless &tag_files)
{
   // count the number of exact matches for this tag
   i := count := 0;
   tag_filename := next_tag_filea(tag_files,i,false,true);
   while (tag_filename != "") {
      int status = tag_find_prefix(proc_name);
      if (status==0) {
         ++count;
         status = tag_next_prefix(proc_name);
         if (status==0) {
            ++count;
         }
      }
      tag_reset_find_tag();
      if (count >= 2) {
         return 2;
      }
      tag_filename=next_tag_filea(tag_files,i,false,true);
   }

   return count;
}

//////////////////////////////////////////////////////////////////////////////
// Map tag types to code categories, see CB_*, top of file
// Since we support class nesting, this function only produces a
// best guess for the category.  For globals, however it produces
// exact results.
//
static _str type_to_category(_str type_name, SETagFlags tag_flags, bool containers_only)
{
   typeless ctg_name;
   CB_TAG_CATEGORY ctg;

   if (gh_type_to_categories == null) {
      // Loop through symbol browser categories
      for (ctg_name._makeempty();;) {
         gh_cb_categories._nextel(ctg_name);
         if (ctg_name._isempty()) break;
         if (ctg_name._varformat() == VF_LSTR) {
            ctg = gh_cb_categories._el(ctg_name);

            // Now loop through the types used in this category
            for (i:=0; i<ctg.tag_types._length(); i++) {
               // get the tag type, has to be either a string or an int
               // Add the category to the index for this type name
               tname := ctg_type_to_type_name(ctg.tag_types[i]);
               if (tname == "") continue;
               if (gh_type_to_categories._indexin(tname)) {
                  gh_type_to_categories:[tname] :+= "\t":+ctg_name;
               } else {
                  gh_type_to_categories:[tname] = ctg_name;
               }
            }
         }
      }
   }

   // narrow down the categories to the ones involving this type name
   _str categories_to_visit = gh_type_to_categories:[type_name];
   while (categories_to_visit != null && categories_to_visit != "") {

      parse categories_to_visit with ctg_name "\t" categories_to_visit;
      if (ctg_name._isempty()) continue;
      ctg = gh_cb_categories:[ctg_name];

      // check presence/absence of tag flags
      bool nzero;
      nzero = (tag_flags & ctg.flag_mask)? true:false;
      if (ctg.flag_mask & SE_TAG_FLAG_STATIC) {
         if (nzero != ctg.mask_nzero) {
            continue;
         }
      }

      // check container criteria
      //if (containers_only == true || ctg.is_container == false) {
      //   continue;
      //}

      // OK, look for a matching type name
      int i;
      for (i=0; i<ctg.tag_types._length(); i++) {
         // get the tag type, has to be either a string or an int
         // and compare it to the type name we are testing
         tname := ctg_type_to_type_name(ctg.tag_types[i]);
         if (tname :== type_name) {
            return ctg_name;
         }
      }
   }

   return CB_misc;
}

/**
 * Convert a category's type id or type name to a type name.
 */
static _str ctg_type_to_type_name(typeless t1)
{
   if (isinteger(t1)) {
      // translate the type id to a type name
      _str tname;
      int status=tag_get_type(t1, tname);
      if (status < 0) return t1;
      return tname;
   }
   if (t1._varformat() == VF_LSTR) {
      return t1;
   }
   return "";
}
/**
 * Convert a category's type id or type name to a type name.
 */
static SETagType ctg_type_to_type_id(typeless t1)
{
   if (isinteger(t1)) {
      // translate the type id to a type name
      _str tname;
      int status=tag_get_type(t1, tname);
      if (status < 0) return t1;
      return tag_get_type_id(tname);
   }
   if (t1._varformat() == VF_LSTR) {
      return tag_get_type_id(t1);
   }
   return SE_TAG_TYPE_NULL;
}

/**
 * Activate the symbol browser if necessary and locate the
 * given symbol in the tree.
 * 
 * @param cm  symbol information
 */
int tag_show_in_class_browser(struct VS_TAG_BROWSE_INFO &cm)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // find the symbol browser form
   f := _tbGetActiveSymbolsForm();
   if (!f && !isEclipsePlugin()) {
      show_tool_window(TBCBROWSER_FORM);
   }
   f = ActivateClassBrowser();
   if(!f) {
      messageNwait(get_message(VSRC_FORM_NOT_FOUND, TBCBROWSER_FORM));
      return VSRC_FORM_NOT_FOUND;
   }


   // DJB - 11/16/2005
   // first make sure the right tag file is open
   tag_get_tagfile_browse_info(cm);
   int status = tag_read_db(cm.tag_database);
   if (status < 0) {
      message(nls(get_message(status),cm.tag_database));
      return status;
   }

   // determine tag category
   _str category;
   if (cm.class_name == "") {
      category = type_to_category(cm.type_name, cm.flags, false);
   } else {
      _str top_name;
      if (pos("/", cm.class_name)) {
         parse cm.class_name with top_name "/" .;
         category = CB_packages; // guess
      } else if (pos(":", cm.class_name)) {
         parse cm.class_name with top_name ":" .;
         category = CB_classes; // guess
      } else {
         top_name = cm.class_name;
         category = CB_classes; // guess
      }

      status = tag_find_equal(top_name, true/*case_sensitive*/);
      while (status == 0) {
         tag_get_tag_browse_info(auto found_cm);
         if (_file_eq(cm.file_name, found_cm.file_name) && found_cm.class_name=="") {
            cat := type_to_category(found_cm.type_name, SE_TAG_FLAG_NULL, true);
            if (cat != "") {
               category = cat;
               break;
            }
         }
         status = tag_next_equal(true/*case_sensitive*/);
      }
      tag_reset_find_tag();
   }

   // construct the traversal path
   path := tag_make_caption_from_browse_info(cm, include_class:false, include_args:false, include_tab:false);
   if (cm.class_name != "") {
      cm.class_name = translate(cm.class_name, ",,", ":/");
      path = cm.class_name "," path;
   }

   // compute the tag filename path
   tag_filename_path := "";
   int index = f.ctl_class_tree_view._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (index > 0) {
      _str filename;
      tag_filename_path = f.ctl_class_tree_view._TreeGetCaption(index);
      parse tag_filename_path with tag_filename_path "(" .;
      parse tag_filename_path with . ": " filename;
      if (_file_eq(strip(filename),cm.tag_database)) {
         break;
      }
      index = f.ctl_class_tree_view._TreeGetNextSiblingIndex(index);
   }
   if (index <= 0) {
      return 1;
   }

   // put together final path and pass to restore_position
   path = tag_filename_path "," category "," path;

   //_message_box("Restoring: " path);
   index = f.ctl_class_tree_view.restore_position(TREE_ROOT_INDEX, path);
   if (index > 0) {
      f.ctl_class_tree_view._TreeSetCurIndex(index);
      ActivateClassBrowser();
      f.ctl_class_tree_view._set_focus();
      return 0;
   }
   return 1;
}

//////////////////////////////////////////////////////////////////////////////
// Find a tag in the symbol browser.  This function takes as input a single
// tag argument (optional) and attempts to find a match in some tag database.
// If no argument is given, it attempts to find a tag at the current word.
// If there is no match for the current word, then we use the push tag
// bookmark dialog to dynamically find a tag using prefix matching completion.
// If there are no exact matches for the tag passed in, it will revert to
// the push bookmark dialog.  The result of these operations is a proc_name
// that we need to find.
//
// If the user gave specific information tag(class:type), we first check
// if there is a match for such a beast.  If not, we strip the class and type,
// and attempt to use the proc_name alone and continue.
//
// Once we have a proc_name, we find all matches, and then pop up a selection
// list dialog for the user to select a tag (unless there are no matches,
// or exactly one match).  The user then selects the match of their choice.
//
// At this point, we have a triplet of tag_name, type_name, and class_name.
// We then calcuate a caption path for finding the tag in the class
// browser and pass that on to restore_position().
//
_command cf,cb_find(_str tag_arg="") name_info(TAG_ARG','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI|VSARG2_REQUIRES_PRO_EDITION)
{
   _macro_delete_line();

   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "The Symbols tool window");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   _nocheck _control ctl_class_tree_view;

   // initialize list of matching tags
   _str taglist[];
   _str filesForTags:[];
   int linesForTags:[];
   IgnoreCase := false;

   // make sure that the matches don't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   // No argument, grab the current word at the cursor
   //ignore_tcase := (def_ignore_tcase)? true:false;
   tag_init_tag_browse_info(auto cm);
   tag_init_tag_browse_info(auto find_cm);
   ignore_tcase := true;
   context_found := false;
   num_matches := 0;
   database_name := "";
   lang := "";

   if (tag_arg=="" && _isEditorCtl() && !_no_child_windows()) {
      lang = p_LangId;
      tagName := "";
      _str errorArgs[];
      tag_clear_matches();
      num_matches = context_match_tags(errorArgs,tagName);

      // filter out case-insenstive matches if requested.
      case_sensitive_proc_name := "";
      if (tagName != "" && (_GetCodehelpFlags() & VSCODEHELPFLAG_GO_TO_DEF_CASE_SENSITIVE)) {
         tag_decompose_tag_browse_info(tagName, find_cm);
         case_sensitive_proc_name = find_cm.member_name;
      }
      typeless visited;
      tag_remove_duplicate_symbol_matches(filterDuplicatePrototypes:false, 
                                          filterDuplicateGlobalVars:true, 
                                          filterDuplicateClasses:true, 
                                          filterAllImports:true, 
                                          filterDuplicateDefinitions:true, 
                                          filterAllTagMatchesInContext:false, 
                                          case_sensitive_proc_name);
      num_matches = tag_get_num_of_matches();
      if (num_matches <= 0) {
         if (tagName != "") {
            _message_box(nls("Could not find declaration of symbol: '%s'.",tagName));
         } else {
            _message_box(nls("No symbol under cursor."));
         }
         return(1);
      }

      // get the first match
      context_found=true;
      tag_get_match_browse_info(1, find_cm);
      if (cm.type_name!="param" && cm.type_name!="lvar") {
         taglist[taglist._length()] = tag_compose_tag_browse_info(find_cm);
         filesForTags:[taglist[taglist._length()-1]] = find_cm.file_name;
         linesForTags:[taglist[taglist._length()-1]] = find_cm.line_no;
      }
      //say("tag_name="proc_name" type="type_name" cls="class_name);
      num_matches = tag_get_num_of_matches();
      for (i:=2; i<=num_matches; i++) {
         tag_get_match_browse_info(i, cm);
         if (cm.type_name!="param" && cm.type_name!="lvar") {
            taglist[taglist._length()] = tag_compose_tag_browse_info(cm);
            filesForTags:[taglist[taglist._length()-1]] = cm.file_name;
            linesForTags:[taglist[taglist._length()-1]] = cm.line_no;
         }
         //say("tag_name="dn" type="match_type_name" cls="match_class_name);
         if (cm.type_name != find_cm.type_name && !(pos("pro",find_cm.type_name) && pos("pro",cm.type_name))) {
            find_cm.type_name = "";
         }
         if (cm.class_name != find_cm.class_name) {
            find_cm.class_name == "";
         }
      }
      if (taglist._length() <= 0) {
         _message_box(nls("Tag '%s' can not be found in the symbol browser; it is a local variable.",tagName));
         return(1);
      }
   } else if (tag_arg != "" && tag_arg != "-") {
      // get argument passed by user
      tag_decompose_tag_browse_info(tag_arg, find_cm);


   } else if (p_active_form.p_window_id == _GetCBrowserWID()) {
      // restrict search to current tag file if this is initiated from
      // the Symbols tool window.
      tag_init_tag_browse_info(find_cm);
      k := ctl_class_tree_view._TreeCurIndex();
      ctl_class_tree_view.get_user_tag_info(k, cm, true);
      database_name = cm.tag_database;
   }

   // massage the tag name slightly
   tag_files := null;
   if (database_name != "") {
      tag_files[0] = database_name;
   } else {
      tag_files = tags_filenamea(lang);
   }

   find_cm.member_name = strip(find_cm.member_name);
   find_cm.member_name = translate(find_cm.member_name,"_","-");

   // compute the name of th scope being searched
   scope_name := "";
   scope_name = (lang != "")? _LangGetModeName(lang) : "";
   scope_name = (database_name != "")? _strip_filename(database_name, 'P') : "";
   if (scope_name != "") scope_name = " ("scope_name")";

   // if we still do not have a tag name to search for,
   // then prompt to search for one within the specified langauge
   if (find_cm.member_name == "") {
      new_proc_name := show("-modal -reinit _tagbookmark_form", find_cm.member_name, "Symbol Browser Find Tag":+scope_name, lang, true, "", database_name);
      if (new_proc_name == "") {
         return(COMMAND_CANCELLED_RC);       
      }
      tag_decompose_tag_browse_info(new_proc_name, find_cm);
   }

   if (!context_found) {
      // count the number of exact matches for this tag
      // intelligently figure out if they gave class_name / type_name
      count := number_of_exact_matches(find_cm.member_name, find_cm.type_name, find_cm.class_name, tag_files);
      if (count == 0 && database_name != "") {
         tag_files = tags_filenamea(lang);
         count = number_of_exact_matches(find_cm.member_name, find_cm.type_name, find_cm.class_name, tag_files);
      }
      if (count == 0 && find_cm.type_name != "") {
         if (find_cm.class_name == "") {
            count = number_of_exact_matches(find_cm.member_name, "", find_cm.type_name, tag_files);
            if (count) {
               find_cm.class_name = find_cm.type_name;
               find_cm.type_name = "";
            }
         }
         if (count == 0) {
            count = number_of_exact_matches(find_cm.member_name, "", find_cm.class_name, tag_files);
            if (count) {
               find_cm.type_name = "";
            }
         }
      }
      if (count==0 && find_cm.class_name != "") {
         count = number_of_exact_matches(find_cm.member_name, find_cm.type_name, "", tag_files);
         if (count) {
            find_cm.class_name="";
         }
      }
      if (count==0) {
         find_cm.type_name="";
         find_cm.class_name="";
         count = number_of_exact_matches(find_cm.member_name, "", "", tag_files);
      }

      // no matches for this symbol, so then, just give up
      if (count==0) {
         _message_box(nls("Could not find declaration of symbol: '%s'.",find_cm.member_name));
         return(1);
      }
   }

   // bail out if there aren't any tag files
   tag_files_list := tags_filename(lang);
   if (warn_if_no_tag_files(tag_files_list)) {
      return(2);
   }

   status := 0;
   if (!context_found) {
      // iterate through each tag file
      i:=0;
      tag_filename := next_tag_filea(tag_files,i,false,true);
      while (tag_filename != "") {

         /* Find prefix tag match for proc_name. */
         status = tag_find_equal(find_cm.member_name);
         while (! status) {
            tag_get_tag_browse_info(cm);
            if (find_cm.type_name == "" || find_cm.type_name :== cm.type_name) {
               if (find_cm.class_name == "" || find_cm.class_name :== cm.class_name) {
                  taglist[taglist._length()] = tag_compose_tag_browse_info(cm);
                  filesForTags:[taglist[taglist._length()-1]] = cm.file_name;
                  linesForTags:[taglist[taglist._length()-1]] = cm.line_no;
                  if (ignore_tcase && !IgnoreCase /*&& tag_case(file_name)=="i"*/) {
                     IgnoreCase=true;
                  }
               }
            }

            status = tag_next_equal();
         }
         tag_reset_find_tag();

         tag_filename=next_tag_filea(tag_files,i,false,true);
      }
   }

   // If user wants strict language case sensitivity
   if (!ignore_tcase && !IgnoreCase) {
      for (i:=0;i<taglist._length();++i) {
         if (cm.member_name :!= substr(taglist[i],1,length(cm.member_name))) {
            taglist._deleteel(i);
            --i;
         }
      }
   }

   // didn't find the tag?
   if (taglist._length()==0) {
      long_msg := ".";//  'nls("You may want to rebuild the tag file.");
      _message_box(get_message(VSCODEHELPRC_NO_SYMBOLS_FOUND, find_cm.member_name):+long_msg);
      return(1);
   }

   // sort the list and remove duplicates
   taglist._sort('I');
   cf_remove_duplicates(taglist);

   //messageNwait("prompt_user: len="taglist._length());
   if (taglist._length()>=2) {
      tag_init_tag_browse_info(cm);
      tag_push_matches();
      foreach (auto taginfo in taglist) {
         tag_decompose_tag_browse_info(taginfo, cm);
         cm.file_name = filesForTags:[taginfo];
         cm.line_no   = linesForTags:[taginfo];
         tag_insert_match_info(cm);
      }

      match_id := tag_select_match();
      if (match_id < 0) {
         tag_pop_matches();
         return match_id;
      }
      tag_get_match_info(match_id, find_cm);
      tag_pop_matches();
   } else {
      tag_decompose_tag_browse_info(taglist[0], find_cm);
   }
   if (find_cm.member_name=="") {
      return(COMMAND_CANCELLED_RC);
   }

   // found the tag, type, and class name, now find it in a database
   i:=0;
   tag_filename := next_tag_filea(tag_files,i,false,true);
   while ( tag_filename!="" ) {

      // Find tag match for proc_name.
      found_it := 0;
      status = tag_find_tag(find_cm.member_name, find_cm.type_name, find_cm.class_name);
      while (status==0) {
         _str tag;
         tag_get_detail(VS_TAGDETAIL_name, tag);
         if (find_cm.member_name :== tag) {
            found_it=1;
            break;
         }
         status = tag_next_tag(find_cm.member_name, find_cm.type_name, find_cm.class_name);
      }
      tag_reset_find_tag();
      if (found_it) {
         break;
      }

      // didn't find it, try the next file
      tag_filename=next_tag_filea(tag_files,i,false,true);
   }

   // this should NEVER happen
   if (status) {
      long_msg := ".";//  'nls("You may want to rebuild the tag file.");
      _message_box(get_message(VSCODEHELPRC_NO_SYMBOLS_FOUND, find_cm.member_name):+long_msg);
      return(1);
   }

   // get the details on the tag we are looking for
   tag_get_tag_info(cm);
   status = tag_show_in_class_browser(cm);
   return status;
}

//////////////////////////////////////////////////////////////////////////////
// Remove duplicates from a list
//
static void cf_remove_duplicates(_str (&list)[])
{
   if (!list._length()) return;
   _str previous_line=list[0];
   int i;
   for (i=1;i<list._length();++i) {
      if ( list[i]:==previous_line ) {
         list._deleteel(i);
         --i;
      } else {
         previous_line=list[i];
      }
   }
}

//////////////////////////////////////////////////////////////////////////////
// Goto the declaration for the currently selected tag in the symbol browser
// Translates type_name (proc) to (proto).
//
_command cb_goto_decl() name_info(","VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   _nocheck _control ctl_class_tree_view;

   f := _tbGetActiveSymbolsForm();
   if (!f) {
      messageNwait(get_message(VSRC_FORM_NOT_FOUND, TBCBROWSER_FORM));
      return("");
   }

   k := f.ctl_class_tree_view._TreeCurIndex();
   if (f.ctl_class_tree_view.get_user_tag_info(k, auto cm, false)) {
      cm.qualified_name = "";
      if (cm.type_name!="procproto" && cm.type_name!="proto" && tag_tree_type_is_func(cm.type_name)) {
         search_arguments :=  VS_TAGSEPARATOR_args:+cm.arguments;
         if (tag_find_tag(cm.member_name, "proto", cm.class_name, search_arguments)==0) {
            tag_get_tag_browse_info(cm);
         } else if (tag_find_tag(cm.member_name, "procproto", cm.class_name, search_arguments)==0) {
            tag_get_tag_browse_info(cm);
         }
      }
      tag_reset_find_tag();
      push_tag_in_file(cm.member_name, cm.file_name, cm.class_name, cm.type_name, cm.line_no);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Goto the definition of the currently selected tag in the symbol browser
// Translates (proto) to proc, constr, destr, or function, until it
// finds a match.
//
_command cb_goto_proc() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   _nocheck _control ctl_class_tree_view;

   f := _tbGetActiveSymbolsForm();
   if (!f) {
      messageNwait(get_message(VSRC_FORM_NOT_FOUND, TBCBROWSER_FORM));
      return("");
   }

   k := f.ctl_class_tree_view._TreeCurIndex();
   if (f.ctl_class_tree_view.get_user_tag_info(k, auto cm, false)) {
      cm.qualified_name = "";
      tag_push_matches();
      maybe_convert_proto_to_proc(cm, true);
      tag_remove_duplicate_symbol_matches();
      match_id := tag_select_symbol_match(cm);
      tag_pop_matches();
      if (match_id >= 0) {
         push_tag_in_file(cm.member_name, cm.file_name, cm.class_name, cm.type_name, cm.line_no);
      }
   }
}
_command void cb_delete() name_info(','VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      return;
   }
   f := _tbGetActiveSymbolsForm();
   if (!f) {
      messageNwait(get_message(VSRC_FORM_NOT_FOUND, TBCBROWSER_FORM));
      return;
   }

   k := f.ctl_class_tree_view._TreeCurIndex();
   if (f.ctl_class_tree_view.get_user_tag_info(k, auto cm, false)) {

      // check if there is a load-tags function, if so, bail out
      if (_QBinaryLoadTagsSupported(cm.file_name)) {
         _message_box(nls("Can not locate source code for %s.",cm.file_name));
         return;
      }

      proto_cm := cm;
      // This should never happen.
      if (!tag_tree_type_is_func(cm.type_name)) {
         return;
      }
      search_arguments :=  VS_TAGSEPARATOR_args:+cm.arguments;
      found_def := false;
      found_proto := false;
      comment_out_def := true;
      comment_out_proto := true;
      /*
         Because when we see a function definition we don't know whether it is
         a nested class "outerClass::InnerClass::method" or a namespace
         "mynamespace::myclass::method, we look for both here.  This code has
         not been tested for nested namespaces because add member and a lot of
         other code does not work for nested namespaces.
      */
      //say("mem="cm.member_name" class="cm.class_name" s="search_arguments);
      //"member4"  "mynamespace/myclass" "char *psz"
      if (tag_find_tag(cm.member_name, "proc", cm.class_name, search_arguments)==0 ||
          tag_find_tag(cm.member_name, "func", cm.class_name, search_arguments)==0 ||
          tag_find_tag(cm.member_name, "constr", cm.class_name, search_arguments)==0 ||
          tag_find_tag(cm.member_name, "destr", cm.class_name, search_arguments)==0) {
         tag_get_tag_browse_info(cm);
         found_def=true;
      }
      if (!found_def) {
         _str temp_class_name=translate(cm.class_name,":","/");
         if (tag_find_tag(cm.member_name, "proc", temp_class_name, search_arguments)==0 ||
             tag_find_tag(cm.member_name, "func", temp_class_name, search_arguments)==0 ||
             tag_find_tag(cm.member_name, "constr", temp_class_name, search_arguments)==0 ||
             tag_find_tag(cm.member_name, "destr", temp_class_name, search_arguments)==0) {
            tag_get_tag_browse_info(cm);
            found_def=true;
         }
      }
      tag_reset_find_tag();
      default_cm := cm;
      cm=proto_cm;
      if (tag_find_tag(cm.member_name, "proto", cm.class_name, search_arguments)==0) {
         tag_get_tag_browse_info(cm);
         found_proto=true;
      } else if (tag_find_tag(cm.member_name, "procproto", cm.class_name, search_arguments)==0) {
         tag_get_tag_browse_info(cm);
         found_proto=true;
      }
      tag_reset_find_tag();
      proto_cm=cm;
      temp_view_id := 0;
      temp_view_id2 := 0;
      int orig_view_id;
      buf_id2 := -1;
      if (!found_proto) {
         comment_out_proto=comment_out_def;
         cm=default_cm;
      }
      int buf_id=_BufEdit(cm.file_name,"",false,"",true);
      if (buf_id<0) {
         if (buf_id==FILE_NOT_FOUND_RC) {
            _message_box(get_message(CMRC_FILE_NOT_FOUND_1ARG, cm.file_name));
         } else {
            _message_box(get_message(ARGUNABLE_TO_OPEN_FILE_RC, cm.file_name):+".  ":+get_message(buf_id));
         }
         if (temp_view_id2) _delete_temp_view(temp_view_id2);
         return;
      }
      _open_temp_view("",temp_view_id,orig_view_id,"+bi "buf_id);
      if (_QReadOnly()) {
         _message_box(nls("File '%s' is read only",p_buf_name));
         if (temp_view_id2) _delete_temp_view(temp_view_id2);
         _delete_temp_view(temp_view_id);activate_window(orig_view_id);
         return;
      }
      if (found_proto && found_def) {
         buf_id2=_BufEdit(default_cm.file_name,"",false,"",true);
         if (buf_id2<0) {
            if (buf_id2==FILE_NOT_FOUND_RC) {
               _message_box(get_message(CMRC_FILE_NOT_FOUND_1ARG, default_cm.file_name));
            } else {
               _message_box(get_message(ARGUNABLE_TO_OPEN_FILE_RC, default_cm.file_name):+".  ":+get_message(buf_id));
            }
            if (temp_view_id2) _delete_temp_view(temp_view_id2);
            _delete_temp_view(temp_view_id);activate_window(orig_view_id);
            return;
         }
         int orig_view_id2;
         _open_temp_view("",temp_view_id2,orig_view_id2,"+bi "buf_id2);
         if (_QReadOnly()) {
            _message_box(nls("File '%s' is read only",p_buf_name));
            if (temp_view_id2) _delete_temp_view(temp_view_id2);
            _delete_temp_view(temp_view_id);activate_window(orig_view_id);
            return;
         }
         //result=_message_box("A prototype and definition of this symbol has been found.  The definition will be commented out.\n\nDo you want to comment out the prototype","Delete "cm.member_name,MB_YESNOCANCEL);
         int result=_message_box("A prototype and definition of this symbol has been found.  The definition will be commented out.\n\nDelete prototype?  Select 'No' to comment out the prototype.","Delete "cm.member_name,MB_YESNOCANCEL,IDNO);
         if (result==IDCANCEL) {
            return;
         }
         comment_out_proto=(result==IDNO);

         activate_window(orig_view_id2);
      }

      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);

      int status=_cb_goto_tag_in_file(cm.member_name, cm.file_name, cm.class_name, cm.type_name, cm.line_no,true);
      if (status) {
         if (temp_view_id2) _delete_temp_view(temp_view_id2);
         _delete_temp_view(temp_view_id);activate_window(orig_view_id);
         return;
      }

      context_id := tag_current_context();
      if (context_id<0) {
         if (temp_view_id2) _delete_temp_view(temp_view_id2);
         _delete_temp_view(temp_view_id);activate_window(orig_view_id);
         _message_box("Unable to find this function");
         return;
      }
      _TagDelayCallList();
      status=_c_delete_tag(context_id,comment_out_proto,!(found_def && found_proto));

      if (!status && !(found_proto && found_def && _file_eq(default_cm.file_name,proto_cm.file_name))) {
      //if (!status && (!found_def || !file_eq(default_cm.file_name,proto_cm.file_name))) {
         status=_save_file(build_save_options(p_buf_name));
         if ( status ) {
            _message_box(nls('Unable to save file "%s"',p_buf_name)".  "get_message(status));
         } else {
            TagFileOnSave();
         }
      }
      if (!status && found_proto && found_def) {
         cm=default_cm;
         activate_window(temp_view_id2);
         status=_cb_goto_tag_in_file(cm.member_name, cm.file_name, cm.class_name, cm.type_name, cm.line_no,true);
         if (!status) {
            context_id = tag_current_context();
            if (context_id<0) {
               _message_box(nls("Unable to find symbol %s in file '%s'",cm.member_name,cm.file_name));
            } else {
               status=_c_delete_tag(context_id,comment_out_def,true);
            }
         }
      }
      _TagProcessCallList();

      if (temp_view_id2) _delete_temp_view(temp_view_id2);
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
   }
}
_command void cb_override_method() name_info(','VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      return;
   }
   f := _tbGetActiveSymbolsForm();
   if (!f) {
      messageNwait(get_message(VSRC_FORM_NOT_FOUND, TBCBROWSER_FORM));
      return;
   }

   k := f.ctl_class_tree_view._TreeCurIndex();
   if (f.ctl_class_tree_view.get_user_tag_info(k, auto cm, false)) {

      // check if there is a load-tags function, if so, bail out
      if (_QBinaryLoadTagsSupported(cm.file_name)) {
         _message_box(nls("Can not locate source code for %s.",cm.file_name));
         return;
      }

      orig_view_id := temp_view_id := 0;
      int buf_id=_BufEdit(cm.file_name,"",false,"",true);
      if (buf_id<0) {
         if (buf_id==FILE_NOT_FOUND_RC) {
            messageNwait(get_message(VSRC_FORM_NOT_FOUND, TBCBROWSER_FORM));
         } else {
            _message_box(get_message(ARGUNABLE_TO_OPEN_FILE_RC, cm.file_name):+".  ":+get_message(buf_id));
         }
         return;
      }
      _open_temp_view("",temp_view_id,orig_view_id,"+bi "buf_id);
      if (_QReadOnly()) {
         _message_box(nls("File '%s' is read only",p_buf_name));
         _delete_temp_view(temp_view_id);activate_window(orig_view_id);
         return;
      }
      int status=_cb_goto_tag_in_file(cm.member_name, cm.file_name, cm.class_name, cm.type_name, cm.line_no,true);
      if (status) {
         _delete_temp_view(temp_view_id);activate_window(orig_view_id);
         return;
      }

      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);

      int context_id = tag_current_context();
      if (context_id<0) {
         _delete_temp_view(temp_view_id);activate_window(orig_view_id);
         _message_box("Unable to find this class");
         return;
      }
      scope_seekpos := 0;
      tag_get_detail2(VS_TAGDETAIL_context_scope_seekpos, context_id, scope_seekpos);
      _GoToROffset(scope_seekpos);
      override_method(false,cm,!_LanguageInheritsFrom("c"));
      if(temp_view_id) {
         _delete_temp_view(temp_view_id);
      }
   }
}
_command void cb_add_member(_str option="") name_info(','VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      return;
   }
   f := _tbGetActiveSymbolsForm();
   if (!f) {
      messageNwait(get_message(VSRC_FORM_NOT_FOUND, TBCBROWSER_FORM));
      return;
   }

   k := f.ctl_class_tree_view._TreeCurIndex();
   if (f.ctl_class_tree_view.get_user_tag_info(k, auto cm, false)) {
      _c_add_member(cm,option != 0);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Collapse all tree items except for the branch currently having focus
//
_command cb_collapse() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Symbols tool window");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   f := _tbGetActiveSymbolsForm();
   if (!f) {
      messageNwait(get_message(VSRC_FORM_NOT_FOUND, TBCBROWSER_FORM));
      return("");
   }

   _nocheck _control ctl_class_tree_view;

   se.util.MousePointerGuard hour_glass;
   i := f.ctl_class_tree_view._TreeCurIndex();
   while (i > 0) {
      p := f.ctl_class_tree_view._TreeGetParentIndex(i);
      int j = f.ctl_class_tree_view._TreeGetFirstChildIndex(p);
      while (j > 0) {
         if (j!=i) {
            show_children := 0;
            f.ctl_class_tree_view._TreeGetInfo(j, show_children);
            if (show_children != TREE_NODE_LEAF) {
               f.ctl_class_tree_view._TreeDelete(j, 'c');
               if (show_children>0) {
                  f.ctl_class_tree_view._TreeSetInfo(j, TREE_NODE_COLLAPSED);
               }
            }
         }
         j = f.ctl_class_tree_view._TreeGetNextSiblingIndex(j);
      }
      i=p;
   }
}

//////////////////////////////////////////////////////////////////////////////
// Return the number of children under tree index 'i'
//
int cb_tree_count_children(int t, int index)
{
   count := 0;
   child := t._TreeGetFirstChildIndex(index);
   while (child > 0) {
      ++count;
      child = t._TreeGetNextSiblingIndex(child);
   }
   return count;
}

//////////////////////////////////////////////////////////////////////////////
// Expand the current item and its children
//
_command cb_expand_twolevels() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Symbols tool window");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   f := _tbGetActiveSymbolsForm();
   if (!f) {
      messageNwait(get_message(VSRC_FORM_NOT_FOUND, TBCBROWSER_FORM));
      return("");
   }
   _nocheck _control ctl_class_tree_view;

   gtbSymbolsFormList:[f].m_i_in_refresh=1;
   se.util.MousePointerGuard hour_glass;
   f.ctl_class_tree_view.p_redraw = false;
   i := f.ctl_class_tree_view._TreeCurIndex();
   if (i >= 0) {

      int show_children;
      f.ctl_class_tree_view._TreeGetInfo(i, show_children);
      if (show_children == TREE_NODE_COLLAPSED) {
         call_event(CHANGE_EXPANDED,i,f.ctl_class_tree_view,ON_CHANGE,'w');
         f.ctl_class_tree_view._TreeSetInfo(i, TREE_NODE_EXPANDED);
      }

      count := 0;
      int child = f.ctl_class_tree_view._TreeGetFirstChildIndex(i);
      while (child > 0) {
         f.ctl_class_tree_view._TreeGetInfo(child, show_children);
         if (show_children==TREE_NODE_COLLAPSED) {
            call_event(CHANGE_EXPANDED,child,f.ctl_class_tree_view,ON_CHANGE,'w');
            f.ctl_class_tree_view._TreeSetInfo(child, TREE_NODE_EXPANDED);
            int incr = f.ctl_class_tree_view._TreeGetNumChildren(child)+1;
            count += incr;
            if (count % def_cbrowser_flood_refresh < incr) {
               _str caption = f.ctl_class_tree_view._TreeGetCaption(i);
               int r = cb_warn_overflow(f.ctl_class_tree_view, i, caption, count);
               if (r >= CB_NOAHS_WATER_MARK) {
                  break;
               }
            }

         }
         child = f.ctl_class_tree_view._TreeGetNextSiblingIndex(child);
      }
   }
   f.ctl_class_tree_view.p_redraw = true;
   gtbSymbolsFormList:[f].m_i_in_refresh=0;
}

/**
 * Recursively expand the current item and its chidren.
 * 
 * @param index    Index of node to expand.
 * @param count    [out]  Number of children expanded.
 * @param onChange true=Call tree's ON_CHANGE event with CHANGE_EXPANDED for reason.
 * 
 * @return 0 on success, 1 if the water mark is hit.
 */
int do_expand_children(int index, int &count, bool onChange=true)
{
   se.util.MousePointerGuard hour_glass(MP_DEFAULT);
   if (index >= 0) {
      show_children := 0;
      _TreeGetInfo(index, show_children);
      if (show_children==TREE_NODE_COLLAPSED) {
         if( onChange ) {
            call_event(CHANGE_EXPANDED,index,p_window_id,ON_CHANGE,'w');
         }
         _TreeSetInfo(index, TREE_NODE_EXPANDED);
      }

      // check if we need to break out of loop
      int incr = _TreeGetNumChildren(index)+1;
      count+=incr;
      if (count % def_cbrowser_flood_refresh < incr) {
         caption := _TreeGetCaption(index);
         hour_glass.setMousePointer(MP_HOUR_GLASS);
         int r = cb_warn_overflow(p_window_id, index, caption, count);
         if (r >= CB_NOAHS_WATER_MARK) {
            return(1);
         }
      }

      child := _TreeGetFirstChildIndex(index);
      while (child > 0) {
         _TreeGetInfo(child, show_children);
         if (show_children!=TREE_NODE_LEAF) {
            if (do_expand_children(child,count,onChange)) {
               return(1);
            }
         }
         child = _TreeGetNextSiblingIndex(child);
      }
   }
   return(0);
}

/**
 * Recursively collapse the current item and its chidren.
 * 
 * @param index    Index of node to collapse.
 * @param onChange true=Call tree's ON_CHANGE event with CHANGE_COLLAPSED for reason.
 */
void do_collapse_children(int index, bool onChange=true)
{
   if (index >= 0) {
      show_children := 0;
      _TreeGetInfo(index, show_children);
      if (show_children==TREE_NODE_EXPANDED) {
         _TreeSetInfo(index, TREE_NODE_COLLAPSED);
         if( onChange ) {
            call_event(CHANGE_COLLAPSED,index,p_window_id,ON_CHANGE,'w');
         }
      }

      child := _TreeGetFirstChildIndex(index);
      while (child > 0) {
         _TreeGetInfo(child, show_children);
         if (show_children!=TREE_NODE_LEAF) {
            do_collapse_children(child,onChange);
         }
         child = _TreeGetNextSiblingIndex(child);
      }
   }
}

//////////////////////////////////////////////////////////////////////////////
// Expand the current item and its children
//
_command cb_expand_children() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Symbols tool window");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   f := _tbGetActiveSymbolsForm();
   if (!f) {
      messageNwait(get_message(VSRC_FORM_NOT_FOUND, TBCBROWSER_FORM));
      return("");
   }
   _nocheck _control ctl_class_tree_view;

   gtbSymbolsFormList:[f].m_i_in_refresh=1;
   se.util.MousePointerGuard hour_glass;
   f.ctl_class_tree_view.p_redraw = false;
   i := f.ctl_class_tree_view._TreeCurIndex();
   if (i >= 0) {
      count := 0;
      f.ctl_class_tree_view.do_expand_children(i,count,true);
   }
   f.ctl_class_tree_view.p_redraw = true;
   gtbSymbolsFormList:[f].m_i_in_refresh=0;
}

//////////////////////////////////////////////////////////////////////////////
// Collapse all tree items except list of projects
//
_command cb_crunch() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Symbols tool window");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   f := _tbGetActiveSymbolsForm();
   if (!f) {
      messageNwait(get_message(VSRC_FORM_NOT_FOUND, TBCBROWSER_FORM));
      return("");
   }

   _nocheck _control ctl_class_tree_view;

   se.util.MousePointerGuard hour_glass;
   int j = f.ctl_class_tree_view._TreeGetFirstChildIndex(0);
   while (j > 0) {
      show_children := 0;
      f.ctl_class_tree_view._TreeGetInfo(j, show_children);
      if (show_children!=TREE_NODE_LEAF) {
         f.ctl_class_tree_view._TreeDelete(j, 'c');
         if (show_children==TREE_NODE_EXPANDED) {
            f.ctl_class_tree_view._TreeSetInfo(j, TREE_NODE_COLLAPSED);
         }
      }
      j = f.ctl_class_tree_view._TreeGetNextSiblingIndex(j);
   }
}


//############################################################################
//////////////////////////////////////////////////////////////////////////////
// Skip over the contents of a C style string
//
/*
static int skip_c_string(_str params,int j,_str ch)
{
   re := '[\\\'ch']';
   for (;;) {
      j=pos(re,params,j,'r');
      if (!j) {
         // String not terminated.
         return(length(params)+1);
      }
      ch=substr(params,j,1);
      if (ch=='\') {
         j+=2;
         continue;
      }
      return(j+1);
   }
}
*/

//////////////////////////////////////////////////////////////////////////////
// Skip over nested parameter sets (parents, <>, [], etc)
//
/*
static int skip_nested(_str params,int j,_str start_ch,_str end_ch)
{
   nesting := 1;
   re := '[\'start_ch'\'end_ch']';
   for (;;) {
      j=pos(re,params,j,'r');
      //messageNwait('re='re" j="j" end_ch="end_ch);
      if (!j) {
         return(length(params)+1);
      }
      ch := substr(params,j,1);
      if (ch==start_ch) {
         ++nesting;
         ++j;
         continue;
      }
      --nesting;
      //messageNwait("nesting="nesting);
      ++j;
      if (nesting<=0) {
         //messageNwait("j="j);
         return(j);
      }
   }
}
*/

//////////////////////////////////////////////////////////////////////////////
// Get the next argument from the given string, pass find_first==1
// to get the first argument.
//
// NOTE:  cb_next_arg() is deprecated.
//        tag_get_next_argument() should be used instead.
//
static const NEXTARG_CHARS1=  '[:;,<\[("""\n]';
static int gnext_arg_index;
_str cb_next_arg(_str params,int &arg_pos,int find_first,_str ext=null)
{
   argument := "";
   if (find_first) gnext_arg_index=1;
   arg_pos = tag_get_next_argument(params, gnext_arg_index, argument, ext);
   return argument;

   /*
   ispascal := ((pos(";",params) || pos(":",params)) &&
                 !pos(":[",params) && !pos("::",params))? 1:0;
   if (_LanguageInheritsFrom("verilog",ext)) {
      ispascal=false;
   }

   int next_arg_index = arg_pos;
   if (next_arg_index==0) {
      next_arg_index=1;
   }

   // skip leading spaces
   ch := substr(params,next_arg_index,1);
   while ((ch==" " || ch=="\t") && next_arg_index <= length(params)) {
      next_arg_index++;
      ch=substr(params,next_arg_index,1);
   }
   // pull next argument off of list
   int j=next_arg_index;
outer_loop:
   for (;;) {
      //say("params="substr(params,1,80) " index=" j);
      j=pos(NEXTARG_CHARS1,params,j,'r');
      if (!j) {
         j=length(params)+1;
         break;
      }
      ch=substr(params,j,1);
      switch (ch) {
      case ":":
         //if (!ispascal) {
            ++j;
         //}
         break;
      case ",":
         if (!ispascal) {
            break outer_loop;
         }
         ++j;
         break;
      case ";":
         break outer_loop;
      case "\n":
         break outer_loop;
      case "<":
         j=skip_nested(params,j+1,ch,">");
         break;
      case "[":
         j=skip_nested(params,j+1,ch,"]");
         break;
      case "(":
         j=skip_nested(params,j+1,ch,")");
         break;
      case '"':
      case "'":
         j=skip_c_string(params,j+1,ch);
         break;
      }
   }
   if (j<next_arg_index) {
      return("");
   }
   arg_pos = j+1;
   result := substr(params,next_arg_index,j-next_arg_index);
   return (strip(result));
   */
}

_str getTextSymbolFromBitmapId(int bmid)
{
   if (gmap_bitmapid_to_symbol._indexin(bmid))
      return gmap_bitmapid_to_symbol:[bmid];
   return " ";
}

/**
 * Define the container form name for the symbol browser.
 * 
 * @param containerFormName
 *               container form name
 */
_command void cbrowser_setFormName(_str containerFormName=TBCBROWSER_FORM) name_info(','VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   // Access the container form in the view.
   formwid := _find_formobj(containerFormName,'n');
   if( formwid==0 ) {
      return;
   }

   //// Do the remaining defload
   //doDefLoad();
}

/**
 * Used by various tool windows to stay in synch.
 */
int _GetProctreeWID()
{
   if (!_haveDefsToolWindow()) return 0;
   return _tbGetActiveDefsForm();
}

/**
 * Used by various tool windows to stay in synch.
 */
int _GetCBrowserWID()
{
   if (!_haveContextTagging()) return 0;
   return _tbGetActiveSymbolsForm();
}

/**
 * Used by various tool windows to stay in synch.
 */
int _GetCBrowserParentsWID()
{
   if (!_haveContextTagging()) return 0;
   return _tbGetActiveBaseClassesForm();
}

/**
 * Used by various tool windows to stay in synch.
 */
int _GetCBrowserCallTreeWID()
{
   if (!_haveContextTagging()) return 0;
   return _tbGetActiveSymbolCallsForm();
}

/**
 * Used by various tool windows to stay in synch.
 */
int _GetCBrowserPropsWID()
{
   if (!_haveContextTagging()) return 0;
   return _tbGetActiveSymbolPropertiesForm();
}

/**
 * Used by various tool windows to stay in synch.
 */
int _GetCBrowserArgsWID()
{
   if (!_haveContextTagging()) return 0;
   return _tbGetActiveSymbolArgumentsForm();
}

/**
 * Used by various tool windows to stay in synch.
 */
bool CBrowseFocus()
{
   FocusWID := _get_focus();
   // try symbol browser tool window
   _nocheck _control ctl_class_tree_view;
   int CBrowserWID = _GetCBrowserWID();
   if( CBrowserWID>0 && (FocusWID==CBrowserWID || FocusWID==CBrowserWID.ctl_class_tree_view) ) {
      CBrowserWID=_GetTagwinWID();
      return true;
   }
   // try defs tool window
   _nocheck _control _proc_tree;
   CBrowserWID = _GetProctreeWID();
   if( CBrowserWID>0 && (FocusWID==CBrowserWID || FocusWID==CBrowserWID._proc_tree) ) {
      CBrowserWID=_GetTagwinWID();
      return true;
   }
   // try inheritance tree
   _nocheck _control ctl_member_tree_view;
   _nocheck _control ctl_inheritance_tree_view;
   CBrowserWID=_GetCBrowserParentsWID();
   if( CBrowserWID>0 && (FocusWID==CBrowserWID || FocusWID==CBrowserWID.ctl_member_tree_view || FocusWID==CBrowserWID.ctl_inheritance_tree_view) ) {
      CBrowserWID=_GetTagwinWID();
      return true;
   }
   // try tag properties tool window
   CBrowserWID=_GetCBrowserPropsWID();
   if( CBrowserWID>0 && (FocusWID==CBrowserWID) ) {
      CBrowserWID=_GetTagwinWID();
      return true;
   }
   // try tag properties tool window
   CBrowserWID=_GetCBrowserArgsWID();
   if( CBrowserWID>0 && (FocusWID==CBrowserWID) ) {
      CBrowserWID=_GetTagwinWID();
      return true;
   }
   // try call tree tool window
   _nocheck _control ctl_call_tree_view;
   CBrowserWID=_GetCBrowserCallTreeWID();
   if( CBrowserWID>0 && (FocusWID==CBrowserWID || FocusWID==CBrowserWID.ctl_call_tree_view) ) {
      CBrowserWID=_GetTagwinWID();
      return true;
   }
   // try call references tool window
   _nocheck _control ctlreferences;
   CBrowserWID=_GetReferencesWID();
   if( CBrowserWID>0 && (FocusWID==CBrowserWID || FocusWID==CBrowserWID.ctlreferences) ) {
      CBrowserWID=_GetTagwinWID();
      return true;
   }
   _nocheck _control ctl_file_list;
   _nocheck _control ctl_workspace_list;
   _nocheck _control ctl_project_list;
   _nocheck _control ctl_filter;
   CBrowserWID=_GetFilesToolTreeWID();
   if( CBrowserWID>0 && (FocusWID==CBrowserWID
                         || FocusWID==CBrowserWID.ctl_file_list
                         || FocusWID==CBrowserWID.ctl_workspace_list
                         || FocusWID==CBrowserWID.ctl_project_list
                         || FocusWID==CBrowserWID.ctl_filter
                         ) ) {
      CBrowserWID=_GetTagwinWID();
      return true;
   }
   // no tagging window in focus
   return false;
}

/**
 * Set a breakpoint or watchpoing on the current item selected in the
 * symbol browser tool window.
 */
_command int cb_set_breakpoint() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   f := _tbGetActiveSymbolsForm();
   if (!f) {
      messageNwait(get_message(VSRC_FORM_NOT_FOUND, TBCBROWSER_FORM));
      return 0;
   }
   _nocheck _control ctl_class_tree_view;
   currIndex := f.ctl_class_tree_view._TreeCurIndex();
   cm_status := f.ctl_class_tree_view.get_user_tag_info(currIndex, auto cm, false);
   if (!cm_status) {
      messageNwait(get_message(NOTHING_SELECTED_RC, TBCBROWSER_FORM));
      return NOTHING_SELECTED_RC;
   }

   return debug_set_breakpoint_on_tag(cm);
}

/**
 * Dump the configured class categories to the debug window.
 */
_command void dump_cb_categories() name_info(','VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   orig := _default_option(VSOPTION_MAX_STACK_DUMP_ARGUMENT_NOFLINES);
   _default_option(VSOPTION_MAX_STACK_DUMP_ARGUMENT_NOFLINES, 5000);
   _dump_var(gh_cb_categories, "Categories: ");
   _default_option(VSOPTION_MAX_STACK_DUMP_ARGUMENT_NOFLINES, orig);
}

_command void cb_show_tag_files() name_info(','VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Tagging");
      return;
   }

   f := _tbGetActiveSymbolsForm();
   if (!f) {
      messageNwait(get_message(VSRC_FORM_NOT_FOUND, TBCBROWSER_FORM));
      return;
   }

   _nocheck _control ctl_class_tree_view;
   currIndex := f.ctl_class_tree_view._TreeCurIndex();
   f.ctl_class_tree_view.get_user_tag_info(currIndex, auto cm, false);

   gui_make_tags(cm.tag_database, cm.language);
}
_command void cb_rebuild_tag_file() name_info(','VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Tagging");
      return;
   }

   f := _tbGetActiveSymbolsForm();
   if (!f) {
      messageNwait(get_message(VSRC_FORM_NOT_FOUND, TBCBROWSER_FORM));
      return;
   }

   _nocheck _control ctl_class_tree_view;
   currIndex := f.ctl_class_tree_view._TreeCurIndex();
   f.ctl_class_tree_view.get_user_tag_info(currIndex, auto cm, false);

   TagRebuildAnyTagFile(cm.tag_database, cm.language);
}

