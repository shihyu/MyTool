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
#include "debug.sh"
#include "tagsdb.sh"
#include "xml.sh"
#include "minihtml.sh"
#import "cbrowser.e"
#import "context.e"
#import "debug.e"
#import "debugpkg.e"
#import "diffprog.e"
#import "env.e"
#import "files.e"
#import "guicd.e"
#import "guiopen.e"
#import "listbox.e"
#import "main.e"
#import "math.e"
#import "menu.e"
#import "mouse.e"
#import "optionsxml.e"
#import "picture.e"
#import "saveload.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "tagwin.e"
#import "tbcmds.e"
#import "toolbar.e"
#import "se/ui/twevent.e"
#import "treeview.e"
#import "util.e"
#import "wkspace.e"
#import "xmlcfg.e"
#import "se/ui/toolwindow.e"
#endregion

///////////////////////////////////////////////////////////////////////////
// Almost of the toolbar forms have tree controls.  They use the p_user
// attribute of the tree control to flag the situation where the form
// needs to be updated, but is not because it is currently hidden or
// not the current tab in a tab group.
// 
// When the form becomes active either through on_got_focus() or
// CHANGE_AUTO_SHOW, we then force the form to be updated, provided
// this p_user property is non-zero.
// 

///////////////////////////////////////////////////////////////////////////
// globals
//

/**
 * Prompt showing where to click to add a new watch
 */
static const DEBUG_ADD_WATCH_CAPTION= "< add >";

// Debugger configuration file nodes and attributes
static const VSDEBUG_CONFIG_TAG_DEBUGGER=          "Debugger";
static const VSDEBUG_CONFIG_TAG_PACKAGE=           "Package";
static const VSDEBUG_CONFIG_TAG_CONFIGURATION=     "Configuration";

static const VSDEBUG_CONFIG_ATTR_NAME=             "Name";
static const VSDEBUG_CONFIG_ATTR_PATH=             "Path";
static const VSDEBUG_CONFIG_ATTR_PLATFORM=         "Platform";
static const VSDEBUG_CONFIG_ATTR_ARGUMENTS=        "Arguments";
static const VSDEBUG_CONFIG_ATTR_DEFAULT=          "Default";
static const VSDEBUG_CONFIG_ATTR_STANDARD=         "Standard";

static const VSDEBUG_CONFIG_VALUE_SLICKEDIT_GDB=   "SlickEdit GDB";
static const VSDEBUG_CONFIG_VALUE_SLICKEDIT_GDB32= "SlickEdit GDB 32-bit";
static const VSDEBUG_CONFIG_VALUE_STANDARD_GDB=    "Standard GDB";
static const VSDEBUG_CONFIG_VALUE_LOCAL_GDB=       "Local GDB";
static const VSDEBUG_CONFIG_VALUE_CYGWIN_GDB=      "Cygwin GDB";
static const VSDEBUG_CONFIG_VALUE_MINGW_GDB=       "MinGW GDB";
static const VSDEBUG_CONFIG_VALUE_TORNADO_GDB=     "WindRiver GDB";
static const VSDEBUG_CONFIG_VALUE_GDB=             "GDB";

// string to display to let the user create a new debug session
const VSDEBUG_NEW_SESSION=                  "<New Debugging Session>";


static const DBGP_MODIFY_STRING= 0;
static const DBGP_MODIFY_EXPR=   1;

/**
 * Function type for user-supplied Slick-C&reg; view update callbacks
 *
 * @param reason     VSDEBUG_UPDATE_* update reason flag
 *
 * @return 0 on success, &lt;0 for query callbacks if
 *         it should not call the other callbacks.
 *
 * @see debug_gui_update_user_views(int reason)
 * @see debug_gui_remove_update_callbacks()
 * @see debug_gui_add_update_callback(pfn)
 */
typedef int (*VSDEBUG_UPDATE_CALLBACK)(int reason);

/**
 * Are we currently updating the list of threads?
 */
static bool gInUpdateThreadList=false;
/**
 * Are we currently updating the current thread?
 */
static bool gInUpdateThread=false;
/**
 * Are we currently updating the execution stack frame?
 */
static bool gInUpdateFrame=false;
/**
 * Callback to check if a particular update needs to happen
 */
static VSDEBUG_UPDATE_CALLBACK gUserViewQuery=null;
/**
 * List of user view update callbacks
 */
static VSDEBUG_UPDATE_CALLBACK gUserViewList[];
/**
 * Are we currently updating the user views?
 */
static bool gInUpdateUserViews=false;
/**
 * Are they switching threads or stack frames using a combo box?
 */
static bool gInComboboxDropDown=false;


///////////////////////////////////////////////////////////////////////////
// Ran each time the editor is started
//
definit()
{
   if (arg(1)!='L') {
      gInUpdateThreadList=false;
      gInUpdateThread=false;
      gInUpdateFrame=false;
      gInUpdateUserViews=false;
      gInComboboxDropDown=false;
      gUserViewQuery=null;
      gUserViewList._makeempty();
   }
}

static bool isDynamicDebugger()
{
   if (!_haveDebugging()) return false;
   session_id := dbg_get_current_session();
   switch (dbg_get_callback_name(session_id)) {
   case "xdebug":
   case "perl5db":
   case "rdbgp":
      return true;
   default:
      return false;
   }
}

///////////////////////////////////////////////////////////////////////////
// Callbacks for debugger properties form

/**
 * Creates a string of list box entries separated by spaces. 
 * Used to compare before and after states of a list box to see 
 * if the values have changed. 
 * 
 * @param listBox    window id of listbox
 * 
 * @return           concatendated string of values
 */
_str buildListboxList(int listBox)
{
   // let's look at our list box
   orig_wid := p_window_id;
   int indent, pic_index;
   p_window_id = listBox;

   // go through the list and grab each item
   list := "";
   _lbtop();
   for (;;) {
      line := "";
      _lbget_item(line, indent, pic_index);
      if (line!="") {
         list :+= line" ";
      }
      // do something with down
      if (_lbdown()) break;
   }

   p_window_id=orig_wid;

   return strip(list);
}

/**
 * Determine if the current project is a debug project.  Used to 
 * determine visibility of Runtime Filters and Directories 
 * debugger options. 
 * 
 * @return true if this is a debug project, false otherwise
 */
bool isThisADebugProject()
{
   if (!_haveDebugging()) return false;
   session_id := dbg_get_current_session();
   return (dbg_get_callback_name(session_id) != "");
}

/**
 * Callbacks for embedding forms inside Options Dialog
 */
#region Options Dialog Helper Functions

defeventtab _debug_props_runtime_filters_form;

// our list of filters
static _str FILTERS_LIST(...) {
   if (arg()) ctl_filter_list.p_user=arg(1);
   return ctl_filter_list.p_user;
}

/**
 * Initializes _debug_props_runtime_filters_form for options - 
 * does form initialization in absence of an on_create method. 
 */
void _debug_props_runtime_filters_form_init_for_options()
{
   // fill in the class filters
   if (!_haveDebugging()) return;
   filter := "";
   n := dbg_get_num_runtimes();
   for (i := 1; i <= n; ++i) {
      dbg_get_runtime_expr(i, filter);
      if (filter != "") {
         ctl_filter_list._lbadd_item(filter);
      }
   }
   // sort our list
   ctl_filter_list._lbsort();
}

/**
 * Saves a baseline state of the form so that we can compare to 
 * this state later to see what has been modified. 
 */
void _debug_props_runtime_filters_form_save_settings()
{
   FILTERS_LIST( buildListboxList(ctl_filter_list));
}

/**
 * Determines if anything on the current form has been modified.
 */
bool _debug_props_runtime_filters_form_is_modified()
{
   // build our current list and compare it to the saved one
   currentList := buildListboxList(ctl_filter_list);
   return (currentList != FILTERS_LIST());
}

/**
 * Applies any changes to the current form.
 */
bool _debug_props_runtime_filters_form_apply()
{
   if (!_haveDebugging()) return false;
   orig_wid := p_window_id;
   int indent,pic_index;
   dbg_clear_runtimes();

   p_window_id=ctl_filter_list.p_window_id;
   _lbtop();
   for (;;) {
      line := "";
      _lbget_item(line,indent,pic_index);
      if (line!="") dbg_add_runtime_expr(strip(line));

      // do something with down
      if (_lbdown()) break;
   }
   p_window_id=orig_wid;

   return true;
}

#endregion Options Dialog Helper Functions

/**
 * Resize event for _debug_props_runtime_filters_form.
 */
void _debug_props_runtime_filters_form.on_resize()
{
   // check width
   widthDiff := p_width - (ctl_add_filter.p_x_extent + 120);
   if (widthDiff) {
      ctl_add_filter.p_x += widthDiff;
      ctl_del_filter.p_x += widthDiff;
      ctl_reset_filter.p_x += widthDiff;

      ctl_filter_list.p_width += widthDiff;
   }

   // and now height
   heightDiff := p_height - (ctl_filter_list.p_y_extent + 120);
   if (heightDiff) {
      ctl_filter_list.p_height += heightDiff;
   }
}

void ctl_add_filter.lbutton_up()
{
   // add filter here
   wid := p_window_id;
   name := show("-modal _textbox_form",
                  "Enter New Item",
                  0, //Flags
                  "",//Width
                  "",//Help item
                  "",//Buttons and captions
                  "",//retrieve
                  "Item:" //prompt
                  );
   if (name!="") {
      name=_param1;
      p_window_id=wid;
      p_window_id=p_prev;
      _lbadd_item(name);
      _lbsort();
      _lbtop();
      _lbselect_line();
      p_window_id=wid;
   }
   p_next.p_enabled=(p_prev.p_Noflines!=0);
}

void ctl_del_filter.lbutton_up()
{
   // delete selected filter here
   mou_hour_glass(true);
   ff := true;
   orig_wid := p_window_id;
   p_window_id=p_prev.p_prev;
   while (!_lbfind_selected(ff)) {
      _lbdelete_item();
      _lbup();
      ff=false;
   }
   if( ff==false ) {
      // We found at least 1 selected item, so _lbdown() to
      // compensate for the last call to _lbup().
      _lbdown();
   }
   _lbselect_line();
   p_window_id=orig_wid;
   p_enabled=(p_prev.p_prev.p_Noflines!=0);
   mou_hour_glass(false);
}

void ctl_reset_filter.lbutton_up()
{
   // delete selected filter here
   mou_hour_glass(true);
   ctl_filter_list._lbclear();
   session_id := dbg_get_current_session();
   debug_cb_name := dbg_get_callback_name(session_id);
   if (debug_cb_name == "jdwp") {
      ctl_filter_list._lbadd_item("java.*");
      ctl_filter_list._lbadd_item("javax.*");
      ctl_filter_list._lbadd_item("com.sun.*");
      ctl_filter_list._lbadd_item("com.ibm.*");
      ctl_filter_list._lbadd_item("sun.*");
      ctl_filter_list._lbadd_item("org.codehaus.*");
      ctl_filter_list._lbadd_item("groovy.lang.*");
      ctl_filter_list._lbadd_item("scala.*");
      ctl_filter_list._lbadd_item("jdk.interal.*");
   } else if (debug_cb_name == "mono") {
      ctl_filter_list._lbadd_item("System.*");
      ctl_filter_list._lbadd_item("Microsoft.*");
      ctl_filter_list._lbadd_item("Mono.*");
   } else if (debug_cb_name == "gdb" || debug_cb_name == "lldb" || debug_cb_name == "windbg") {
      ctl_filter_list._lbadd_item("printf");
      ctl_filter_list._lbadd_item("strcpy");
      ctl_filter_list._lbadd_item("strcmp");
      ctl_filter_list._lbadd_item("std::*");
      ctl_filter_list._lbadd_item("boost::*");
   }
   ctl_filter_list._lbsort();
   ctl_filter_list._lbselect_line();
   ctl_del_filter.p_enabled=true;
   mou_hour_glass(false);
}

void ctl_filter_list.DEL()
{
   if (p_next.p_next.p_enabled) {
      p_next.p_next.call_event(p_next.p_next,LBUTTON_UP,'W');
   }
}


#region Options Dialog Helper Functions

defeventtab _debug_props_directories_form;

static _str DIRECTORIES_LIST(...) {
   if (arg()) ctl_dir_list.p_user=arg(1);
   return ctl_dir_list.p_user;
}

void _debug_props_directories_form_init_for_options()
{
   // fill in the directory search paths
   if (!_haveDebugging()) return;
   dir := "";
   n := dbg_get_num_dirs();
   for (i := 1; i <= n; ++i) {
      dbg_get_source_dir(i, dir);
      if (dir != "") {
         ctl_dir_list._lbadd_item(dir);
      }
   }
   ctl_dir_list._lbsort();

   ctl_prompt_for_dir.p_value=(def_debug_options & VSDEBUG_OPTION_CONFIRM_DIRECTORY)? 1:0;
}

/**
 * Saves a baseline state of the form so that we can compare to 
 * this state later to see what has been modified. 
 */
void _debug_props_directories_form_save_settings()
{
   DIRECTORIES_LIST(buildListboxList(ctl_dir_list));
}

bool _debug_props_directories_form_is_modified()
{
   if(((def_debug_options & VSDEBUG_OPTION_CONFIRM_DIRECTORY)? 1:0) != ctl_prompt_for_dir.p_value) return true;

   curList := buildListboxList(ctl_dir_list);
   return (curList != DIRECTORIES_LIST());
}

bool _debug_props_directories_form_apply()
{
   if (!_haveDebugging()) return false;
   list := "";
   int indent,pic_index;

   orig_wid := p_window_id;
   // get the directory search paths
   dbg_clear_sourcedirs();
   debug_clear_file_path_cache();
   p_window_id=ctl_dir_list.p_window_id;
   _lbtop();
   for (;;) {
      line := "";
      _lbget_item(line,indent,pic_index);
      if (line!="") {
         dbg_add_source_dir(strip(line));
         list :+= line" ";
      } 
      // do something with down
      if (_lbdown()) {
         break;
      }
   }

   if (ctl_prompt_for_dir.p_value) def_debug_options |= VSDEBUG_OPTION_CONFIRM_DIRECTORY;
   else def_debug_options &= ~VSDEBUG_OPTION_CONFIRM_DIRECTORY;
   _config_modify_flags(CFGMODIFY_DEFVAR);

   p_window_id=orig_wid;

   return true;
}

_str _debug_props_directories_form_build_export_summary(PropertySheetItem (&table)[])
{
   // fill in the directory search paths
   if (!_haveDebugging()) return "";
   dir := "";
   dirList := "";
   n := dbg_get_num_dirs();
   for (i := 1; i <= n; ++i) {
      dbg_get_source_dir(i, dir);
      if (dir != "") {
         dirList :+= dir";";
      }
   }
   PropertySheetItem psi;
   psi.Caption = "Directories";
   psi.Value = strip(dirList, 'T', ";");
   table[0] = psi;

   psi.Caption = "Confirm source file directory";
   psi.Value = (def_debug_options & VSDEBUG_OPTION_CONFIRM_DIRECTORY)? "True" : "False";
   table[1] = psi;

   return "";
}

_str _debug_props_directories_form_import_summary(PropertySheetItem (&table)[])
{
   if (!_haveDebugging()) return "";
   error := "";

   dbg_clear_sourcedirs();
   debug_clear_file_path_cache();

   dirList := table[0].Value;
   while (dirList != "") {
      dir := "";
      parse dirList with dir ";" dirList;

      // this might be coming from another operating system, so we 
      // will try flipping the fileseps
      dir = stranslate(dir, FILESEP, FILESEP2);

      // make sure it exists...
      if (file_exists(dir)) {
         dbg_add_source_dir(strip(dir));
      } else {
         error :+= dir" does not exist."OPTIONS_ERROR_DELIMITER;
      }
   }

   // confirm source file directory
   confirm := (table[1].Value == "True");
   if (confirm) {
      def_debug_options |= VSDEBUG_OPTION_CONFIRM_DIRECTORY;
   } else {
      def_debug_options &= ~VSDEBUG_OPTION_CONFIRM_DIRECTORY;
   }
   _config_modify_flags(CFGMODIFY_DEFVAR);

   return error;
}

#endregion Options Dialog Helper Functions

void _debug_props_directories_form.on_resize()
{
   // width and height of border
   width := _dx2lx(p_xyscale_mode,p_active_form.p_client_width);
   height := _dy2ly(p_xyscale_mode,p_active_form.p_client_height);

   // check width
   widthDiff := width - (ctl_add_dir.p_x_extent + 120);
   if (widthDiff) {
      ctl_add_dir.p_x += widthDiff;
      ctl_del_dir.p_x += widthDiff;
      ctl_reset_dirs.p_x += widthDiff;

      ctl_dir_list.p_width += widthDiff;
   }

   heightDiff := height - (ctl_prompt_for_dir.p_y_extent + 120);
   if (heightDiff) {
      ctl_prompt_for_dir.p_y += heightDiff;
      ctl_dir_list.p_height += heightDiff;
   }
}

void ctl_add_dir.lbutton_up()
{
   wid := p_window_id;
   orig_cwd := getcwd();
   name := _ChooseDirDialog();
   chdir(orig_cwd);
   if (name!="") {
      p_window_id=wid;
      p_window_id=p_prev;
      _lbadd_item(name);
      _lbsort();
      _lbtop();
      _lbselect_line();
      p_window_id=wid;
   }
   p_next.p_enabled=(p_prev.p_Noflines!=0);
}

void ctl_reset_dirs.lbutton_up()
{
   // delete selected filter here
   mou_hour_glass(true);
   ctl_dir_list._lbclear();
   ctl_del_dir.p_enabled=false;
   mou_hour_glass(false);
}


#region Options Dialog Helper Functions

defeventtab _debug_props_configurations_form;

static int DEBUG_CONFIG_FILE_HANDLE(...) {
   if (arg()) ctl_config_tree.p_user=arg(1);
   return ctl_config_tree.p_user;
}
static bool DEBUG_CONFIG_GDB_HASH(...):[] {
   if (arg()) ctl_config_path.p_user=arg(1);
   return ctl_config_path.p_user;
}
static int DEBUG_CONFIG_PACKAGE_INDEX(...) {
   if (arg()) ctl_config_name.p_user=arg(1);
   return ctl_config_name.p_user;
}
static int DEBUG_CONFIG_CHANGE_SEL(...) {
   if (arg()) ctl_config_args.p_user=arg(1);
   return ctl_config_args.p_user;
}

void _debug_props_configurations_form_init_for_options()
{
   // we are not changing the tree selection right now, so false
   DEBUG_CONFIG_CHANGE_SEL(0);

   // Load the GDB debugger configurations
   debug_gdb_load_configurations();
   _debug_props_configurations_form_initial_alignment();
}

void _debug_props_configurations_form_save_settings()
{
   fh := debug_get_gdb_config_tree(true);
   _xmlcfg_set_modify(fh, 0);
}

bool _debug_props_configurations_form_is_modified()
{
   fh := debug_get_gdb_config_tree(true);
   return (_xmlcfg_get_modify(fh) != 0);
}

bool _debug_props_configurations_form_apply()
{
   if (!debug_gdb_validate_and_save_configuration()) return false;

   // save the XML configuration file
   fh := debug_get_gdb_config_tree(true);
   if (fh > 0) {
      filename := _ConfigPath():+DEBUGGER_CONFIG_FILENAME;
      status := _xmlcfg_save(fh,-1,VSXMLCFG_SAVE_ONE_LINE_IF_ONE_ATTR,filename);
      if (status < 0) {
         debug_message("Could not save configuration: ",status);
         return false;
      }
   }

   return true;
}

_str _debug_props_configurations_form_export_settings(_str &file)
{
   error := "";

   // get the path to the debugger configuration file
   debugFile := _ConfigPath():+DEBUGGER_CONFIG_FILENAME;
   if (!file_exists(debugFile)) {
      debugFile = _getSlickEditInstallPath():+DEBUGGER_CONFIG_FILENAME;
      if (!file_exists(debugFile)) debugFile = "";
   }

   if (debugFile != "") {
      targetFile := file :+ DEBUGGER_CONFIG_FILENAME;
      if (copy_file(debugFile, targetFile)) {
         error = "Error copying debugger configuration file, "debugFile".";
      } else {
         file = DEBUGGER_CONFIG_FILENAME;
      }
   }

   return error;
}

_str _debug_props_configurations_form_import_settings(_str &importFile)
{
   error := "";

   // get the path to the GDB configuration file
   origFile := _ConfigPath():+DEBUGGER_CONFIG_FILENAME;
   if (!file_exists(origFile)) {
      // we can just save the import file to the config dir
      copy_file(importFile, origFile);
   } else {
      // we will have to do some merging...sigh.
      status := 0;
      origHandle := _xmlcfg_open(origFile, status);
      importHandle := _xmlcfg_open(importFile, status);
      if (origHandle < 0) {
         error = "Error opening debugger configuration file "origFile".";
      } else if (importHandle < 0) {
         error = "Error opening debugger configuration file "importFile".";
      } else {
         // grab each debugger out of the import file and put it in the configuration file
         do {
            // find the Debugger tag
            importDbgIndex := _xmlcfg_find_simple(importHandle, VSDEBUG_CONFIG_TAG_DEBUGGER);
            if (importDbgIndex < 0) {
               error = "Error finding debugger information in configuration file "importFile".";
               break;
            }
   
            // find the Package section for GDB
            importPkgIndex := _xmlcfg_find_simple(importHandle, VSDEBUG_CONFIG_TAG_PACKAGE"[@"VSDEBUG_CONFIG_ATTR_NAME"='"VSDEBUG_CONFIG_VALUE_GDB"']", importDbgIndex);
            if (importPkgIndex < 0) {
               error = "Error finding package information in configuration file "importFile".";
               break;
            }

            // grab each debugger out of the import file and put it in the configuration file
            // find the Debugger tag
            origDbgIndex := _xmlcfg_find_simple(origHandle, VSDEBUG_CONFIG_TAG_DEBUGGER);
            if (origDbgIndex < 0) {
               error = "Error finding debugger information in configuration file "origFile".";
               break;
            }
   
            // find the Package section for GDB
            origPkgIndex := _xmlcfg_find_simple(origHandle, VSDEBUG_CONFIG_TAG_PACKAGE"[@"VSDEBUG_CONFIG_ATTR_NAME"='"VSDEBUG_CONFIG_VALUE_GDB"']", origDbgIndex);
            if (origPkgIndex < 0) {
               error = "Error finding package information in configuration file "origFile".";
               break;
            }
   
            // Find all the GDB configuration nodes
            _str gdb_configs[]; 
            gdb_configs._makeempty();
            status=_xmlcfg_find_simple_array(importHandle, VSDEBUG_CONFIG_TAG_CONFIGURATION, gdb_configs, importPkgIndex);

            // For each node, extract the critical attributes, and add to tree
            n := gdb_configs._length();
            for (i := 0; i < n; ++i) {
               // see if we can find a node with this name in the existing config file
               importGDBIndex := (int)gdb_configs[i];
               gdb_name := _xmlcfg_get_attribute(importHandle, importGDBIndex, VSDEBUG_CONFIG_ATTR_NAME);

               origGDBIndex := _xmlcfg_find_simple(origHandle, VSDEBUG_CONFIG_TAG_CONFIGURATION"[@"VSDEBUG_CONFIG_ATTR_NAME"='"gdb_name"']", origPkgIndex);
               if (origGDBIndex < 0) {
                  // nope, just copy this in there
                  _xmlcfg_copy(origHandle, origPkgIndex, importHandle, importGDBIndex, VSXMLCFG_COPY_AS_CHILD);
               } else {
                  // yup, so we need to copy over the data
                  _str attr:[];
                  _xmlcfg_get_attribute_ht(importHandle, importGDBIndex, attr);

                  // remove all the existing attributes
                  _xmlcfg_delete_all_attributes(origHandle, origGDBIndex);

                  // now set each attribute
                  foreach (auto key => auto value in attr) {
                     _xmlcfg_set_attribute(origHandle, origGDBIndex, key, value);
                  }
               }
            }

            // save the original file
            _xmlcfg_save(origHandle, -1, 0);

         } while (false);

         // close the files, we're done
         _xmlcfg_close(origHandle);
         _xmlcfg_close(importHandle);
      }
   }

   return error;
}

#endregion Options Dialog Helper Functions

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _debug_props_configurations_form_initial_alignment()
{
   // size the buttons to the textbox
   sizeBrowseButtonToTextBox(ctl_config_path.p_window_id, 
                             ctl_find_config.p_window_id,
                             0, 
                             ctl_config_name.p_x_extent);

}

void _debug_props_configurations_form.on_resize()
{
   // check width
   widthDiff := p_width - (ctl_add_config.p_x_extent + 120);
   if (widthDiff) {
      ctl_add_config.p_x += widthDiff;
      ctl_delete_config.p_x += widthDiff;

      ctl_config_tree.p_width += widthDiff;
      ctl_config_frame.p_width += widthDiff;

      ctl_config_name.p_width += widthDiff;
      ctl_config_path.p_width += widthDiff;
      ctl_config_args.p_width += widthDiff;

      ctl_find_config.p_x += widthDiff;
   }

   heightDiff := p_height - (ctl_config_frame.p_y_extent + 120);
   if (heightDiff) {
      ctl_config_tree.p_height += heightDiff;

      ctl_config_frame.p_y += heightDiff;
   }

   alignUpDownListButtons(ctl_config_tree.p_window_id, 
                          ctl_config_frame.p_x_extent,
                          ctl_add_config.p_window_id, 
                          ctl_delete_config.p_window_id);
}

void _debug_props_configurations_form.on_destroy()
{
   // close the handle
   fh := debug_get_gdb_config_tree(true);
   if (fh > 0) {
      _xmlcfg_close(fh);
      DEBUG_CONFIG_FILE_HANDLE(0);
   }
}

void ctl_config_tree.on_change(int reason,int index)
{
   if (index>0 && reason==CHANGE_SELECTED) {

      // check if current entries are valid
      orig_index := debug_get_gdb_config_current();
      if (index!=orig_index && !debug_gdb_validate_and_save_configuration()) {
         _TreeSetCurIndex(orig_index);
         return;
      }

      // find the XML config tree handle
      fh := debug_get_gdb_config_tree(true);
      if (fh < 0) {
         return;
      }

      // set this to true so we'll know we're only changing the 
      // current selection, not anything in the XML
      DEBUG_CONFIG_CHANGE_SEL(1);

      // save the config index for the newly selected item
      debug_set_gdb_config_current();

      // get the attriutes for the selected configuration
      int config_index = ctl_config_tree._TreeGetUserInfo(index);
      gdb_name := _xmlcfg_get_attribute(fh,config_index,VSDEBUG_CONFIG_ATTR_NAME);
      gdb_path := _xmlcfg_get_attribute(fh,config_index,VSDEBUG_CONFIG_ATTR_PATH);
      gdb_args := _xmlcfg_get_attribute(fh,config_index,VSDEBUG_CONFIG_ATTR_ARGUMENTS);
      if (gdb_path!="") {
         gdb_path = debug_normalize_config_path(gdb_path);
      }

      // fill them into the form
      ctl_config_name.p_text   = gdb_name;
      ctl_config_path.p_text   = gdb_path;
      ctl_config_args.p_text   = gdb_args;
      gdb_default := _xmlcfg_get_attribute(fh,config_index,VSDEBUG_CONFIG_ATTR_DEFAULT);
      ctl_default_config.p_value = (gdb_default==1)? 1:0;

      DEBUG_CONFIG_CHANGE_SEL(0);
   }
}

void ctl_config_tree.DEL()
{
   call_event(ctl_delete_config,LBUTTON_UP,'w');
}

void ctl_delete_config.lbutton_up()
{
   // find the current item in the tree
   tree_index := ctl_config_tree._TreeCurIndex();
   if (tree_index <= 0) {
      return;
   }

   // can not delete a slickedit default node
   if (debug_gdb_is_slickedit_default(tree_index)) {
      debug_message("Can not delete default debugger");
      return;
   }

   // find the XML config tree handle
   fh := debug_get_gdb_config_tree();
   if (fh < 0) {
      return;
   }

   // can not delete a slickedit default node
   if (debug_gdb_is_native_default(tree_index)) {
      j := ctl_config_tree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      while (j > 0) {
         if (debug_gdb_is_slickedit_default(j)) {
            int default_index = ctl_config_tree._TreeGetUserInfo(j);
           _xmlcfg_set_attribute(fh, default_index, VSDEBUG_CONFIG_ATTR_DEFAULT, 1);
         }
         j = ctl_config_tree._TreeGetNextSiblingIndex(j);
      }
   }

   // delete the node from the XML tree
   int config_index = ctl_config_tree._TreeGetUserInfo(tree_index);
   if (config_index > 0) {
      _xmlcfg_delete(fh, config_index);
   }

   // delete the node from the tree control
   ctl_config_tree._TreeDelete(tree_index);

   // save the config index for the new selected item
   debug_set_gdb_config_current();

   // make sure the change event is fired, otherwise our tree selection
   // and the info below do not match up
   ctl_config_tree.call_event(CHANGE_SELECTED,ctl_config_tree._TreeCurIndex(), ctl_config_tree, ON_CHANGE, 'w');
}

/**
 * Create a new item and add it to the tree for editing.
 * The item will be validated before we close the dialog.
 */
int ctl_add_config.lbutton_up()
{
   // check if current entries are valid
   if (!debug_gdb_validate_and_save_configuration()) {
      return COMMAND_CANCELLED_RC;
   }

   // save the XML configuration file
   fh := debug_get_gdb_config_tree();
   if (fh < 0) {
      return COMMAND_CANCELLED_RC;
   }

   // used the saved package index
   package_index := debug_get_gdb_config_package();
   if (package_index <= 0) {
      return COMMAND_CANCELLED_RC;
   }

   // Transfer focus to the "Name" control
   gdb_path := ctl_find_config.debug_gui_find_executable();
   if (gdb_path=="") {
      return COMMAND_CANCELLED_RC;
   }

   // validate the path they gave us
   gdb_path=debug_normalize_config_path(gdb_path);
   gdb_status := debug_gdb_validate_gdb_path(gdb_path);
   if (gdb_status < 0) {
      return(gdb_status);
   }

   // create a new node and set its index
   config_index := _xmlcfg_add(fh, package_index, VSDEBUG_CONFIG_TAG_CONFIGURATION, VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_set_attribute(fh, config_index, VSDEBUG_CONFIG_ATTR_PLATFORM, machine());
   _xmlcfg_set_attribute(fh, config_index, VSDEBUG_CONFIG_ATTR_NAME, VSDEBUG_CONFIG_VALUE_GDB);

   // Add this nice new item to the tree
   tree_index := ctl_config_tree._TreeAddListItem(VSDEBUG_CONFIG_VALUE_GDB"\t"gdb_path,0,TREE_ROOT_INDEX,-1,config_index);
   ctl_config_tree._TreeSetCurIndex(tree_index);
   ctl_config_tree._TreeRefresh();
   debug_set_gdb_config_current();

   // that's all folks
   ctl_config_path.p_text=gdb_path;
   ctl_config_path.end_line();
   ctl_config_path._set_focus();

   return(0);
}

void ctl_find_config.lbutton_up()
{
   orig_path := ctl_config_path.p_text;
   gdb_path := debug_gui_find_executable();
   if (gdb_path=="" || gdb_path==orig_path) {
      return;
   }

   // validate the path they gave us
   ctl_config_path.p_text=debug_normalize_config_path(gdb_path);
   gdb_status := debug_gdb_validate_gdb_path(ctl_config_path.p_text);
   if (gdb_status < 0) {
      ctl_config_path._set_focus();
      return;
   }
}

void ctl_config_path.on_change()
{
   if (!DEBUG_CONFIG_CHANGE_SEL()) {
      debug_gdb_config_set_attr(VSDEBUG_CONFIG_ATTR_PATH, relative(p_text,_getSlickEditInstallPath()));
   }
}

void ctl_config_name.on_change()
{
   if (!DEBUG_CONFIG_CHANGE_SEL()) {
      debug_gdb_config_set_attr(VSDEBUG_CONFIG_ATTR_NAME,p_text);
   }
}

void ctl_config_args.on_change()
{
   if (!DEBUG_CONFIG_CHANGE_SEL()) {
      debug_gdb_config_set_attr(VSDEBUG_CONFIG_ATTR_ARGUMENTS,p_text);
   }
}

void ctl_default_config.lbutton_up()
{
   debug_gdb_reset_checkboxes(VSDEBUG_CONFIG_ATTR_DEFAULT, p_value);
   debug_gdb_config_set_attr(VSDEBUG_CONFIG_ATTR_DEFAULT, p_value);
   debug_gdb_reset_default();

   // check if they are currently debugging
   if (debug_active()) {
      _message_box("This changes will not take effect until the next debug session.");
   }
}

static bool isThisPlatform(_str machineName)
{
   if (machineName == machine()) {
      return true;
   }
   if (machine() == "WINDOWS" && substr(machineName,1,2)=="NT") {
      return true;
   }
   return false;
}

/**
 * Add the given version of GDB
 */
static void debug_gdb_add_system_configuration(int fh, int package_index, _str gdb_path, _str gdb_name, bool setDefault=false)
{
   if (gdb_path != "") {
      int config_index = _xmlcfg_add(fh, package_index, VSDEBUG_CONFIG_TAG_CONFIGURATION, VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_set_attribute(fh, config_index, VSDEBUG_CONFIG_ATTR_STANDARD, 1);
      _xmlcfg_set_attribute(fh, config_index, VSDEBUG_CONFIG_ATTR_NAME, gdb_name);
      _xmlcfg_set_attribute(fh, config_index, VSDEBUG_CONFIG_ATTR_PATH, gdb_path);
      _xmlcfg_set_attribute(fh, config_index, VSDEBUG_CONFIG_ATTR_PLATFORM, machine());
      if (setDefault) {
         _xmlcfg_set_attribute(fh, config_index, VSDEBUG_CONFIG_ATTR_DEFAULT, 1);
      }

      // Use a tab here since we have columns, otherwise sometimes the tree only
      // colors the the first item.
      gdb_index := ctl_config_tree._TreeAddListItem(gdb_name:+"\t":+gdb_path,0,TREE_ROOT_INDEX,-1,config_index);
      debug_gdb_update_tree_node(gdb_index);
   }
}

/**
 * Load the current set of configurations into the tree control
 */
static void debug_gdb_load_configurations()
{
   // Save the tested GDB executables hash table, initially empty
   bool tested_gdb_hash:[];  tested_gdb_hash._makeempty();
   DEBUG_CONFIG_GDB_HASH(tested_gdb_hash);

   // get the path to the GDB configuration file
   filename := _ConfigPath():+DEBUGGER_CONFIG_FILENAME;
   if (!file_exists(filename)) {
      filename=_getSlickEditInstallPath():+DEBUGGER_CONFIG_FILENAME;
   }

   // clear the list of configurations
   ctl_config_tree._TreeDelete(TREE_ROOT_INDEX,'c');
   DEBUG_CONFIG_FILE_HANDLE(-1);

   // open the XML configuration file
   have_usr_bin_gdb := false;
   have_usr_local_gdb := false;
   have_cygwin_gdb := false;
   have_mingw_gdb := false;
   have_tornado_gdb := false;
   have_slickedit_gdb := false;
   have_default_gdb := false;
   status := 0;
   fh := _xmlcfg_open(filename,status);
   if (status<0 && fh<0) {
      fh=_xmlcfg_create(filename,VSENCODING_UTF8);
      status=(fh<0)? fh:0;

      // create the base nodes of tree
      if (!status) {
         // create the XML declaration
         xmldecl_index := _xmlcfg_add(fh, TREE_ROOT_INDEX, "xml", VSXMLCFG_NODE_XML_DECLARATION, VSXMLCFG_ADD_AS_CHILD);
         _xmlcfg_set_attribute(fh, xmldecl_index, "version", "1.0");
         // create the DOCTYPE declaration
         doctype_index := _xmlcfg_add(fh, TREE_ROOT_INDEX, "DOCTYPE", VSXMLCFG_NODE_DOCTYPE, VSXMLCFG_ADD_AS_CHILD);
         _xmlcfg_set_attribute(fh, doctype_index, "root",   VSDEBUG_CONFIG_TAG_DEBUGGER);
         _xmlcfg_set_attribute(fh, doctype_index, "SYSTEM", VSDEBUG_DTD_PATH);
      }
   }
   if (status < 0) {
      debug_message("Could not create debugger configuration file");
   }
   // save the file handle
   DEBUG_CONFIG_FILE_HANDLE(fh);

   // find the Debugger tag
   debugger_index := _xmlcfg_find_simple(fh, VSDEBUG_CONFIG_TAG_DEBUGGER);
   if (debugger_index < 0) {
      // create the Debugger top level node
      debugger_index = _xmlcfg_add(fh, TREE_ROOT_INDEX, VSDEBUG_CONFIG_TAG_DEBUGGER, VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
   }

   // find the Package section for GDB
   package_index := _xmlcfg_find_simple(fh, VSDEBUG_CONFIG_TAG_PACKAGE"[@"VSDEBUG_CONFIG_ATTR_NAME"='"VSDEBUG_CONFIG_VALUE_GDB"']", debugger_index);
   if (package_index < 0) {
      // create the Package node for GDB configuration options
      package_index = _xmlcfg_add(fh, debugger_index, VSDEBUG_CONFIG_TAG_PACKAGE, VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_set_attribute(fh, package_index, VSDEBUG_CONFIG_ATTR_NAME, VSDEBUG_CONFIG_VALUE_GDB);
   }

   // save the node ID of the package index
   DEBUG_CONFIG_PACKAGE_INDEX(package_index);

   // Find all the GDB configuration nodes
   _str gdb_configs[];
   status=_xmlcfg_find_simple_array(fh, VSDEBUG_CONFIG_TAG_CONFIGURATION, gdb_configs, package_index);
   if (!status) {

      // For each node, extract the critical attributes, and add to tree
      n := gdb_configs._length();
      for (i:=0; i<n; ++i) {
         // Is this the right platform?
         if (isThisPlatform(_xmlcfg_get_attribute(fh, (int)gdb_configs[i], VSDEBUG_CONFIG_ATTR_PLATFORM))) {
            // Use a tab here since we have columns, otherwise sometimes the tree only
            // colors the the first item.
            gdb_name := _xmlcfg_get_attribute(fh, (int)gdb_configs[i], VSDEBUG_CONFIG_ATTR_NAME);
            gdb_path := _xmlcfg_get_attribute(fh, (int)gdb_configs[i], VSDEBUG_CONFIG_ATTR_PATH);
            gdb_index := ctl_config_tree._TreeAddListItem(gdb_name:+"\t":+gdb_path,0,TREE_ROOT_INDEX,-1,gdb_configs[i]);
            debug_gdb_update_tree_node(gdb_index);
            if (debug_gdb_is_slickedit_default(gdb_index)) {
               have_slickedit_gdb=true;
            }
            if (debug_gdb_is_native_default(gdb_index)) {
               have_default_gdb=true;
            }
            // check for other common GDB installations
            if (gdb_path != "") {
               if (gdb_path == debug_get_usr_bin_gdb())   have_usr_bin_gdb = true;
               if (gdb_path == debug_get_usr_local_gdb()) have_usr_local_gdb = true;
               if (gdb_path == debug_get_cygwin_gdb())    have_cygwin_gdb = true;
               if (gdb_path == debug_get_mingw_gdb())     have_mingw_gdb = true;
               if (gdb_path == debug_get_tornado_gdb())   have_tornado_gdb = true;
            }
         }
      }
   }

   // Check if the default GDB should be the one shipped with SlickEdit or /usr/bin/gdb
   use_slickedit_gdb_by_default := true;
   if (!have_default_gdb && (_isMac() || _isUnix()) && file_exists("/usr/bin/gdb")) {
      use_slickedit_gdb_by_default = false;
   }

   // If not already in the list, add the standard GDB executable in /usr/bin
   if (!have_usr_bin_gdb) {
      debug_gdb_add_system_configuration(fh, package_index, 
                                         debug_get_usr_bin_gdb(),
                                         VSDEBUG_CONFIG_VALUE_STANDARD_GDB,
                                         !have_default_gdb && !use_slickedit_gdb_by_default);
   }

   // If not already in the list, add the standard GDB executable in /usr/local
   if (!have_usr_local_gdb) {
      debug_gdb_add_system_configuration(fh, package_index, debug_get_usr_local_gdb(), VSDEBUG_CONFIG_VALUE_LOCAL_GDB);
   }

   // If not already in the list, add the standard GDB executable in "C:\Cygwin\"
   if (!have_cygwin_gdb) {
      debug_gdb_add_system_configuration(fh, package_index, debug_get_cygwin_gdb(), VSDEBUG_CONFIG_VALUE_CYGWIN_GDB);
   }

   // If not already in the list, add the standard GDB executable in "C:\MinGW\"
   if (!have_mingw_gdb) {
      debug_gdb_add_system_configuration(fh, package_index, debug_get_mingw_gdb(), VSDEBUG_CONFIG_VALUE_MINGW_GDB);
   }

   // If not already in the list, add the wind river tornado GDB executable
   if (!have_tornado_gdb) {
      debug_gdb_add_system_configuration(fh, package_index, debug_get_tornado_gdb(), VSDEBUG_CONFIG_VALUE_TORNADO_GDB);
   }

   // If not already in the list, add the GDB executable shipped with SlickEdit
   if (!have_slickedit_gdb) {
      gdb_path := debug_get_slickedit_gdb();
      debug_gdb_add_system_configuration(fh, package_index, 
                                         relative(gdb_path,_getSlickEditInstallPath()), 
                                         VSDEBUG_CONFIG_VALUE_SLICKEDIT_GDB, 
                                         !have_default_gdb && use_slickedit_gdb_by_default);

      // On some platforms we might ship an extra 32-bit GDB executable (Windows)
      gdb32_path := debug_get_slickedit_gdb32();
      if (gdb32_path != "" && file_exists(gdb32_path)) {
         debug_gdb_add_system_configuration(fh, package_index, 
                                            relative(gdb32_path,_getSlickEditInstallPath()), 
                                            VSDEBUG_CONFIG_VALUE_SLICKEDIT_GDB32);
      }
   }

   // Set up the tree captions
   ctl_config_tree._TreeSetColButtonInfo(0,2000,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT|TREE_BUTTON_SORT_DESCENDING,0,"Name");
   ctl_config_tree._TreeSetColButtonInfo(1,-1,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_AUTOSIZE|TREE_BUTTON_SORT_FILENAME,0,"Path");
   ctl_config_tree._TreeRetrieveColButtonInfo();
   ctl_config_tree._TreeAdjustLastColButtonWidth(); 

   // Sort the items in the tree
   ctl_config_tree._TreeSortCol(0, 'D');
   ctl_config_tree._TreeTop();
   ctl_config_tree._TreeRefresh();
   call_event(CHANGE_SELECTED,ctl_config_tree._TreeGetFirstChildIndex(TREE_ROOT_INDEX), ctl_config_tree, ON_CHANGE, 'w');
}

/**
 * The current object must be a combo-box.
 * Load the list of GDB configurations into the box.
 */
void debug_gui_load_configurations_list()
{
   // get the path to the GDB configuration file
   filename := _ConfigPath():+DEBUGGER_CONFIG_FILENAME;
   if (!file_exists(filename)) {
      filename=_getSlickEditInstallPath():+DEBUGGER_CONFIG_FILENAME;
   }

   // clear the list of configurations
   _lbclear();
   _col_width(0,0);
   p_user = null;


   // Always insert the standard GDB bundled with SlickEdit
   standard_gdb := debug_get_slickedit_gdb();
   _lbadd_item(VSDEBUG_CONFIG_VALUE_STANDARD_GDB);
   _str gdb_config_array[];
   gdb_config_array :+= VSDEBUG_CONFIG_VALUE_STANDARD_GDB:+"\t":+standard_gdb:+"\t";

   // open the XML configuration file
   status := 0;
   fh := _xmlcfg_open(filename,status);
   if (!status) {
      // find the Debugger tag
      debugger_index := _xmlcfg_find_simple(fh, VSDEBUG_CONFIG_TAG_DEBUGGER);
      if (debugger_index > 0) {
         // find the Package section for GDB
         package_index := _xmlcfg_find_simple(fh, VSDEBUG_CONFIG_TAG_PACKAGE"[@"VSDEBUG_CONFIG_ATTR_NAME"='"VSDEBUG_CONFIG_VALUE_GDB"']", debugger_index);
         if (package_index > 0) {
            // Find all the GDB configuration nodes
            typeless gdb_configs[]; gdb_configs._makeempty();
            status=_xmlcfg_find_simple_array(fh, VSDEBUG_CONFIG_TAG_CONFIGURATION, gdb_configs, package_index);
            if (!status) {
               // For each node, extract the critical attributes, and add to tree
               n := gdb_configs._length();
               for (i:=0; i<n; ++i) {
                  if (isThisPlatform(_xmlcfg_get_attribute(fh, gdb_configs[i], VSDEBUG_CONFIG_ATTR_PLATFORM))) {
                     gdb_name := _xmlcfg_get_attribute(fh, gdb_configs[i], VSDEBUG_CONFIG_ATTR_NAME);
                     gdb_path := _xmlcfg_get_attribute(fh, gdb_configs[i], VSDEBUG_CONFIG_ATTR_PATH);
                     gdb_args := _xmlcfg_get_attribute(fh, gdb_configs[i], VSDEBUG_CONFIG_ATTR_ARGUMENTS);
                     gdb_standard := _xmlcfg_get_attribute(fh, gdb_configs[i], VSDEBUG_CONFIG_ATTR_STANDARD);
                     gdb_path = debug_normalize_config_path(gdb_path);
                     if (gdb_standard!=true || gdb_name != VSDEBUG_CONFIG_VALUE_STANDARD_GDB) {
                        gdb_config_array :+= gdb_name:+"\t":+gdb_path:+"\t"gdb_args;
                        _lbadd_item(gdb_name);
                     }
                  }
               }
            }
         }
      }
      // close the XML cfg handler
      _xmlcfg_close(fh);
   }

   // save the details about the GDB configurations available
   p_user = gdb_config_array;
   _lbtop();
   _retrieve_value();
   if (p_text=="") {
      p_text=VSDEBUG_CONFIG_VALUE_STANDARD_GDB;
   }
}

/**
 * Get the handle for the XML config tree.
 * The handle is stored in the user info for 'ctl_config_tree'
 */
static int debug_get_gdb_config_tree(bool quiet=false)
{
   fh := DEBUG_CONFIG_FILE_HANDLE();
   if (fh < 0 && !quiet) {
      debug_message("Debugger configuration file is not open");
   }
   return(fh);
}

/**
 * Is this a default GDB supplied with SlickEdit?
 */
static bool debug_gdb_is_slickedit_default(int tree_index)
{
   int node_index = ctl_config_tree._TreeGetUserInfo(tree_index);
   fh := debug_get_gdb_config_tree(true);
   if (fh > 0 && node_index > 0 &&
       _xmlcfg_get_attribute(fh, node_index, VSDEBUG_CONFIG_ATTR_STANDARD)==true) {
      return true;
   }
   return false;
}

/**
 * Is this the default native GDB
 */
static bool debug_gdb_is_native_default(int tree_index)
{
   int node_index = ctl_config_tree._TreeGetUserInfo(tree_index);
   fh := debug_get_gdb_config_tree(true);
   if (fh > 0 && node_index > 0 &&
       _xmlcfg_get_attribute(fh, node_index, VSDEBUG_CONFIG_ATTR_DEFAULT)==true) {
      return true;
   }
   return false;
}

/**
 * Get the tree index for the selected item in the edit frame.
 * The index is stored in the user info for 'ctl_config_frame'.
 */
static int debug_get_gdb_config_current()
{
   return ctl_config_tree._TreeCurIndex();
}
/**
 * Set the index for the selected item in the edit frame.
 * The index is stored in the user info for the current tree node.
 */
static void debug_set_gdb_config_current(int tree_index=-1)
{
   if (tree_index < 0) {
      tree_index = ctl_config_tree._TreeCurIndex();
   }

   if (tree_index <= 0) {
      ctl_find_config.p_enabled=false;
      ctl_config_name.p_enabled=false;
      ctl_config_path.p_enabled=false;
      ctl_config_args.p_enabled=false;
      ctl_default_config.p_enabled=false;
      ctl_delete_config.p_enabled=false;
   } else if (debug_gdb_is_slickedit_default(tree_index)) {
      ctl_find_config.p_enabled=false;
      ctl_config_name.p_enabled=false;
      ctl_config_path.p_enabled=false;
      ctl_config_args.p_enabled=false;
      ctl_delete_config.p_enabled=false;
      ctl_default_config.p_enabled = (ctl_config_tree._TreeGetNumChildren(TREE_ROOT_INDEX) > 1);
   } else {
      ctl_find_config.p_enabled=true;
      ctl_config_name.p_enabled=true;
      ctl_config_path.p_enabled=true;
      ctl_config_args.p_enabled=true;
      ctl_delete_config.p_enabled=true;
      ctl_default_config.p_enabled=true;
      ctl_delete_config.p_enabled=true;
   }

   if (tree_index <= 0) {
      ctl_config_name.p_text="";
      ctl_config_path.p_text="";
      ctl_config_args.p_text="";
      ctl_default_config.p_value=0;
   }
}

static void debug_gdb_update_tree_node(int tree_index)
{
   // Save the tested GDB executables hash table, initially empty
   bool tested_gdb_hash:[];
   tested_gdb_hash = DEBUG_CONFIG_GDB_HASH();

   // watch out for bad tree indices
   if (tree_index <= 0) {
      return;
   }

   // find the XML config tree handle
   fh := debug_get_gdb_config_tree(true);
   if (fh < 0) {
      return;
   }

   // Get the correspond XML config index for this node
   int config_index = ctl_config_tree._TreeGetUserInfo(tree_index);
   if (config_index < 0) {
      return;
   }

   // Is this the right platform?
   if (!isThisPlatform(_xmlcfg_get_attribute(fh, config_index, VSDEBUG_CONFIG_ATTR_PLATFORM))) {
      return;
   }

   // update the tree control caption
   gdb_name := _xmlcfg_get_attribute(fh,config_index,VSDEBUG_CONFIG_ATTR_NAME);
   gdb_path := _xmlcfg_get_attribute(fh,config_index,VSDEBUG_CONFIG_ATTR_PATH);
   if (gdb_path!="") {
      gdb_path = debug_normalize_config_path(gdb_path);
   }
   ctl_config_tree._TreeSetCaption(tree_index, gdb_name"\t"gdb_path);

   // save this as a validated GDB path
   tested_gdb_hash:[gdb_path]=true;
   DEBUG_CONFIG_GDB_HASH(tested_gdb_hash);

   // update the boldness for this node
   gdb_default := _xmlcfg_get_attribute(fh,config_index,VSDEBUG_CONFIG_ATTR_DEFAULT);
   bold_flag := (gdb_default==1)? TREENODE_BOLD:0;
   ctl_config_tree._TreeSetInfo(tree_index,-1,-1,-1,bold_flag);

}

static void debug_gdb_config_set_attr(_str attr, _str value)
{
   // find the current item in the tree
   tree_index := debug_get_gdb_config_current();
   if (tree_index <= 0) {
      return;
   }

   // find the XML config tree handle
   fh := debug_get_gdb_config_tree(true);
   if (fh < 0) {
      return;
   }

   // Get the correspond XML config index for this node
   int config_index = ctl_config_tree._TreeGetUserInfo(tree_index);
   if (config_index < 0) {
      return;
   }

   // update the attribute
   _xmlcfg_set_attribute(fh, config_index, attr, value);

   // update the tree control
   debug_gdb_update_tree_node(tree_index);
}

static void debug_gdb_reset_default()
{
   // find the XML config tree handle
   fh := debug_get_gdb_config_tree(true);
   if (fh < 0) {
      return;
   }

   // for each item in the tree
   tree_index := ctl_config_tree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (tree_index > 0) {

      // Get the correspond XML config index for this node
      int config_index = ctl_config_tree._TreeGetUserInfo(tree_index);
      if (config_index > 0) {
         gdb_default := _xmlcfg_get_attribute(fh,config_index,VSDEBUG_CONFIG_ATTR_DEFAULT);
         bold_flag := (gdb_default==1)? TREENODE_BOLD:0;
         ctl_config_tree._TreeSetInfo(tree_index,-1,-1,-1,bold_flag);
      }

      tree_index = ctl_config_tree._TreeGetNextSiblingIndex(tree_index);
   }
}

/**
 * Validate the items for the currently selected node
 */
static bool debug_gdb_validate_and_save_configuration()
{
   // no current node, then do nothing
   if (debug_get_gdb_config_current() <= 0) {
      //message('debug_get_gdb_config_current FAILED');
      return true;
   }

   // check to be sure the GDB they gave was proper
   gdb_status := debug_gdb_validate_gdb_path(ctl_config_path.p_text);
   if (gdb_status < 0) {
      //message('debug_gdb_validate_gdb_path FAILED');
      ctl_config_path._set_focus();
      return(false);
   }

   // all is OK, save the data
   debug_gdb_config_set_attr(VSDEBUG_CONFIG_ATTR_NAME, ctl_config_name.p_text);
   debug_gdb_config_set_attr(VSDEBUG_CONFIG_ATTR_PATH, relative(ctl_config_path.p_text,_getSlickEditInstallPath()));
   debug_gdb_config_set_attr(VSDEBUG_CONFIG_ATTR_ARGUMENTS, ctl_config_args.p_text);

   debug_gdb_reset_checkboxes(VSDEBUG_CONFIG_ATTR_DEFAULT, ctl_default_config.p_value);
   debug_gdb_config_set_attr(VSDEBUG_CONFIG_ATTR_DEFAULT, ctl_default_config.p_value);
   debug_gdb_reset_default();
   return true;
}

/**
 * Validate the GDB executable path (this is what we care most about)
 */
static int debug_gdb_validate_gdb_path(_str gdb_path)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // Check for empty string
   gdb_path=strip(gdb_path,'B','"');
   if (gdb_path=="") {
      return COMMAND_CANCELLED_RC;
   }
   // check if file exists
   if (!file_exists(gdb_path)) {
      debug_message(get_message(FILE_NOT_FOUND_RC):+": ":+_maybe_quote_filename(gdb_path));
      return FILE_NOT_FOUND_RC;
   }
   // Has this path already been tested and proven?
   bool tested_gdb_hash:[];
   tested_gdb_hash = DEBUG_CONFIG_GDB_HASH();
   if (tested_gdb_hash._indexin(gdb_path)) {
      return 0;
   }

   // create a temporary GDB session
   orig_session := dbg_get_current_session();
   gdb_session_id := dbg_create_new_session("gdb", "GDB test", false);
   if (gdb_session_id < 0) {
      debug_message(get_message(gdb_session_id));
      return gdb_session_id;
   }

   // check if it supports -gdb-version
   gdb_version := "";
   gdb_status := dbg_gdb_test_version(gdb_path,gdb_version,5000);
   if (gdb_status < 0) {
      debug_message("\"":+gdb_path"\" does not appear to be a compatible version of GDB.\n":+
                    "The required version is GDB 5.1 or greater.\n":+
                    "The identified version was \"":+gdb_version"\".",gdb_status);
   }

   // close the GDB session
   dbg_destroy_session(gdb_session_id);
   dbg_set_current_session(orig_session);

   // mark this GDB path as tested and good
   tested_gdb_hash:[gdb_path] = true;
   DEBUG_CONFIG_GDB_HASH(tested_gdb_hash);
   // success
   return(0);

}

/**
 * Get the index for the GDB package in the XML config tree.
 * The index is stored in the user info for "ctl_config_name'.
 */
static int debug_get_gdb_config_package(bool quiet=false)
{
   package_index := DEBUG_CONFIG_PACKAGE_INDEX();
   if (package_index <= 0 && !quiet) {
      debug_message("Could not find \"Package\" tag");
   }
   return package_index;
}

defeventtab _debug_props_form;
static const VSDEBUG_PROPS_FORM= "_debug_props_form";

void ctl_ok.on_create(_str tab_number="")
{
   // set font and color for the html control
   ctl_html._minihtml_UseDialogFont();
   ctl_html.p_backcolor=0x80000022;

   // update the properties
   debug_pkg_update_version();

}

void ctl_options.lbutton_up()
{
   optionsWid := config("Debugging", "+N", "", true);
   _modal_wait(optionsWid);

   // in case anything has changed
   debug_pkg_update_version();
}

void ctl_ok.lbutton_up()
{
   p_active_form._delete_window(0);
}

/**
 * @return
 *    Return the window ID of the window containing the debugger properties
 * combo and list of watches.
 */
CTL_FORM debug_gui_props_wid()
{
   static CTL_FORM form_wid;

   if (_iswindow_valid(form_wid) && !form_wid.p_edit &&
       form_wid.p_object==OI_FORM && form_wid.p_name==VSDEBUG_PROPS_FORM) {
      return(form_wid);
   }

   form_wid=_find_formobj(VSDEBUG_PROPS_FORM,'N');
   return(form_wid);
}

/**
 * Update the debug properties form
 *
 * @param description
 * @param major_version
 * @param minor_version
 * @param runtime_version
 * @param debugger_name
 * @param debugger_path    path to debugger executable
 * @param debugger_name    arguments to pass to debugger executable
 */
void debug_gui_update_version(_str description,
                              _str major_version, _str minor_version,
                              _str runtime_version,
                              _str debugger_name,
                              _str debugger_path,
                              _str debugger_args)
{
   if (!_haveDebugging()) {
      return;
   }
   // insert n/a (not applicable) if we don't know info
   if (description  =="") description="n/a";
   if (runtime_version=="") runtime_version="n/a";
   if (debugger_name=="")   debugger_name="n/a";

   version := major_version;
   if (major_version!="") {
      if (minor_version!="") {
         version :+= "."minor_version;
      }
   } else {
      if (minor_version!="") {
         version :+= "0."minor_version;
      } else {
         version="n/a";
      }
   }

   // adjust the "VM" titles if this is JDWP
   session_id := dbg_get_current_session();
   vm_version_title := "Runtime Version:";
   vm_name_title := "Debugger:";
   if (dbg_get_callback_name(session_id) == "jdwp" || dbg_get_callback_name(session_id) == "mono") {
      vm_version_title = "VM Version:";
      vm_name_title    = "VM Name:";
   }

   // put together the string to put in the HTML control
   t := "<DL compact>\n";

   t :+= "<DT><B>" :+ "Description:" :+ "</B></DT>\n";
   t :+= "<DD>" :+ description    :+ "</DD>\n";

   t :+= "<DT><B>" :+ "Version:" :+ "</B></DT>\n";
   t :+= "<DD>" :+ version    :+ "</DD>\n";

   t :+= "<DT><B>" :+ vm_version_title :+ "</B></DT>\n";
   t :+= "<DD>" :+ runtime_version    :+ "</DD>\n";

   t :+= "<DT><B>" :+ vm_name_title :+ "</B></DT>\n";
   t :+= "<DD>" :+ debugger_name    :+ "</DD>\n";

   // add in debugger path for GDB
   if (debugger_path != "" && dbg_get_callback_name(session_id) == "gdb") {
      t :+= "<DT><B>" :+ "GDB Path:" :+ "</B></DT>\n";
      t :+= "<DD>" :+ debugger_path :+ "</DD>\n";
   }

   t :+= "</DL>\n";

   ctl_html.p_text = t;

   // update the user views of the version info
   debug_gui_update_user_views(VSDEBUG_UPDATE_VERSION);
}

///////////////////////////////////////////////////////////////////////////
// Generic code for resizing debug toolbars with trees
//
static void debug_gui_resize_toolbar(int tab_wid,
                                     CTL_TREE tree_wid,
                                     CTL_TREE tree_wid2=0,
                                     CTL_COMBO combo_wid1=0,
                                     CTL_COMBO combo_wid2=0)
{
   forcedResize := 0;
   if (arg() > 0) forcedResize=arg(1);

   int containerW, containerH;
   if (tab_wid!=0) {
      containerW = _dx2lx(SM_TWIP,p_active_form.p_client_width)  - 2 * tab_wid.p_x;
      containerH = _dy2ly(SM_TWIP,p_active_form.p_client_height) - 2 * tab_wid.p_y;
   } else {
      containerW = _dx2lx(SM_TWIP,p_active_form.p_client_width);
      containerH = _dy2ly(SM_TWIP,p_active_form.p_client_height);
   }

   // get gaps _before_ we resize any tab control
   border_width   := tree_wid.p_x;
   border_height  := (combo_wid1)? combo_wid1.p_y:tree_wid.p_y;
   if (border_width > border_height) {
      border_width=border_height;
   }
   if (tab_wid!=0) {
      // size the tab control. This is important because sizing
      // the tab control also reconfigures the tab containers and
      // we use the tab container dimension to do our resize.
      tab_wid.p_width  = containerW;
      tab_wid.p_height = containerH;
      // we are done resizing the tab control, so now we set the
      // container width, height to the tab control child instead of
      // the form, since all other controls will be resized relative
      // to it.
      containerW = tab_wid.p_child.p_width;
      containerH = tab_wid.p_child.p_height;
   }

   tree_wid.p_x_extent = containerW - border_width;
   tree_wid.p_y_extent = containerH - border_height;
   if (tree_wid2) {
      tree_wid2.p_x_extent = containerW - border_width;
      tree_wid2.p_y_extent = containerH - border_height;
   }

   if (combo_wid1) {
      if (combo_wid1.p_object==OI_TEXT_BOX && combo_wid1.p_next.p_object==OI_SPIN) {
         combo_wid1.p_width = containerW - border_width - combo_wid1.p_x - combo_wid1.p_next.p_width - border_width;
         combo_wid1.p_next.p_x = combo_wid1.p_x_extent + border_width;
         combo_wid1.p_next.p_y = combo_wid1.p_y;
      } else {
         combo_wid1.p_width = containerW - border_width - combo_wid1.p_x;
      }
   }
   if (combo_wid2) {
      if (combo_wid2.p_object==OI_TEXT_BOX && combo_wid2.p_next.p_object==OI_SPIN) {
         combo_wid2.p_width = containerW - border_width - combo_wid2.p_x - combo_wid2.p_next.p_width - border_width;
         combo_wid2.p_next.p_x = combo_wid2.p_x_extent + border_width;
         combo_wid2.p_next.p_y = combo_wid2.p_y;
      } else {
         combo_wid2.p_width = containerW - border_width - combo_wid2.p_x;
      }
   }
}

/**
 * Return the path to the installed SlickEdit GDB executable.
 */
_str debug_get_slickedit_gdb()
{
   return path_search("gdb":+EXTENSION_EXE,"VSLICKBIN","S");
}

/**
 * Return the path to the installed SlickEdit GDB executable.
 */
_str debug_get_slickedit_gdb32()
{
   return path_search("gdb32":+EXTENSION_EXE,"VSLICKBIN","S");
}

/**
 * Return the path to the system GDB executable found in /usr/bin 
 */
static _str debug_get_usr_bin_gdb()
{
   if (_isUnix()) {
      if (file_exists("/usr/bin/gdb")) {
         return "/usr/bin/gdb";
      }
   }
   // Did not find GDB in a standard location.
   return "";
}

/**
 * Return the path to the GDB executable found in /usr/local. 
 */
static _str debug_get_usr_local_gdb()
{
   if (_isUnix()) {
      if (file_exists("/usr/local/bin/gdb")) {
         return "/usr/local/bin/gdb";
      }
   }
   // Did not find GDB in a standard location.
   return "";
}

/**
 * Return the path to the system-installed Cygwin GDB executable. 
 */
static _str debug_get_cygwin_gdb()
{
   if (_isWindows()) {
      cygwin_path := _cygwin_path();
      _maybe_append_filesep(cygwin_path);
      if (cygwin_path != "" && file_exists(cygwin_path:+"bin\\gdb.exe")) {
         return cygwin_path:+"bin\\gdb.exe";
      }
      if (file_exists("C:\\Cygwin\\bin\\gdb.exe")) {
         return "C:\\Cygwin\\bin\\gdb.exe";
      }
      if (file_exists("C:\\Cygwin32\\bin\\gdb.exe")) {
         return "C:\\Cygwin32\\bin\\gdb.exe";
      }
      if (file_exists("C:\\Cygwin64\\bin\\gdb.exe")) {
         return "C:\\Cygwin64\\bin\\gdb.exe";
      }
   }
   // Did not find GDB in a standard location.
   return "";
}

/**
 * Return the path to the system-installed MinGW GDB executable. 
 */
static _str debug_get_mingw_gdb()
{
   if (_isWindows()) {
      if (file_exists("C:\\MinGW\\bin\\gdb.exe")) {
         return "C:\\MinGW\\bin\\gdb.exe";
      }
      if (file_exists("C:\\MinGW64\\bin\\gdb.exe")) {
         return "C:\\MinGW64\\bin\\gdb.exe";
      }
   }
   // Did not find GDB in a standard location.
   return "";
}

/**
 * Return the path to the system-installed Cygwin GDB executable. 
 */
static _str debug_get_tornado_gdb()
{
   if (_isWindows()) {
      tornado_path := _GetTornadoBasePath();
      _maybe_append_filesep(tornado_path);
      if (tornado_path != "" && file_exists(tornado_path:+"bin\\gdb.exe")) {
         return tornado_path:+"bin\\gdb.exe";
      }
   }
   // Did not find GDB in a standard location.
   return "";
}

/**
 * Return the absolute path for the given GDB,
 * with environment variables replaced.
 */
static _str debug_normalize_config_path(_str gdb_path)
{
   gdb_path = _replace_envvars(gdb_path);
   gdb_path = absolute(gdb_path,_getSlickEditInstallPath());
   return gdb_path;
}

/**
 * Return the name and arguments for the default native GDB configuration
 * for the current platform.
 */
void dbg_gdb_get_default_configuration(_str &gdb_name, _str &gdb_path, _str &gdb_args)
{
   // get the path to the GDB configuration file
   status := 0;
   filename := _ConfigPath():+DEBUGGER_CONFIG_FILENAME;
   if (!file_exists(filename)) {
      filename=_getSlickEditInstallPath():+DEBUGGER_CONFIG_FILENAME;
   }

   fh := _xmlcfg_open(filename,status);
   if (!status) {
      // find the Debugger tag
      debugger_index := _xmlcfg_find_simple(fh, VSDEBUG_CONFIG_TAG_DEBUGGER);
      if (debugger_index > 0) {
         // find the Package section for GDB
         package_index := _xmlcfg_find_simple(fh, VSDEBUG_CONFIG_TAG_PACKAGE"[@"VSDEBUG_CONFIG_ATTR_NAME"='"VSDEBUG_CONFIG_VALUE_GDB"']", debugger_index);
         if (package_index > 0) {
            // Find all the GDB configuration nodes
            typeless gdb_configs[]; gdb_configs._makeempty();
            status = _xmlcfg_find_simple_array(fh, VSDEBUG_CONFIG_TAG_CONFIGURATION, gdb_configs, package_index);
            if (!status) {
               // For each node, extract the critical attributes, and add to tree
               n := gdb_configs._length();
               for (i:=0; i<n; ++i) {
                  if (isThisPlatform(_xmlcfg_get_attribute(fh, gdb_configs[i], VSDEBUG_CONFIG_ATTR_PLATFORM)) &&
                      _xmlcfg_get_attribute(fh, gdb_configs[i], VSDEBUG_CONFIG_ATTR_DEFAULT)==true) {

                     gdb_name = _xmlcfg_get_attribute(fh, gdb_configs[i], VSDEBUG_CONFIG_ATTR_NAME);
                     gdb_path = _xmlcfg_get_attribute(fh, gdb_configs[i], VSDEBUG_CONFIG_ATTR_PATH);
                     gdb_args = _xmlcfg_get_attribute(fh, gdb_configs[i], VSDEBUG_CONFIG_ATTR_ARGUMENTS);
                     gdb_path = debug_normalize_config_path(gdb_path);
                     gdb_args = _replace_envvars(gdb_args);
                     _xmlcfg_close(fh);
                     return;
                  }
               }
            }
         }
      }
      // close the XML cfg handler
      _xmlcfg_close(fh);
   }

   // On Unix and macOS, use /usr/bin/gdb if it is there
   if (_isMac() || _isUnix()) {
      gdb_path = debug_get_usr_bin_gdb();
      gdb_args = "";
      if (gdb_path != "" && file_exists(gdb_path)) {
         gdb_name = VSDEBUG_CONFIG_VALUE_STANDARD_GDB;
         return;
      }

      // no /usr/bin/gdb, try /usr/local/bin/gdb
      gdb_path = debug_get_usr_local_gdb();
      gdb_args = "";
      if (gdb_path != "" && file_exists(gdb_path)) {
         gdb_name = VSDEBUG_CONFIG_VALUE_LOCAL_GDB;
         return;
      }
   }

   // No default GDB configured, so use one shipped with SlickEdit.
   gdb_path = debug_get_slickedit_gdb();
   gdb_args = "";
   gdb_name = VSDEBUG_CONFIG_VALUE_SLICKEDIT_GDB;
}

/**
 * Find an executable and place the name in the preceding text
 * box control.  The current object must be a button such that
 * p_prev is a text box.
 */
_str debug_gui_find_executable()
{
   wid := p_window_id;
   initial_directory := "";
   program := wid.p_prev.p_text;
   if (program!="") {
      filename := path_search(program,"",'P');
      if (filename=="") {
         filename=path_search(program,"",'P');
      }
      if (filename=="") {
         _message_box(nls("Program %s not found",program));
      } else {
         filename=debug_normalize_config_path(filename);
         initial_directory=_strip_filename(filename,'N');
      }
   }

   result := _OpenDialog(
      "-modal",
       "Choose Application",
       "",
      (_isUnix())?"All Files("ALLFILES_RE")":"Executable Files (*.exe)", // File Type List
      OFN_FILEMUSTEXIST,     // Flags
      "",
      "",
      initial_directory
      );

   result=strip(result,'B','"');
   p_window_id=wid;
   return result;
}

static void debug_gdb_reset_checkboxes(_str attr_name, _str value)
{
   // find the XML config tree handle
   fh := debug_get_gdb_config_tree(true);
   if (fh < 0) {
      return;
   }

   // used the saved package index
   package_index := debug_get_gdb_config_package(true);
   if (package_index <= 0) {
      return;
   }

   // Find all the GDB configuration nodes
   typeless gdb_configs[]; gdb_configs._makeempty();
   status := _xmlcfg_find_simple_array(fh, VSDEBUG_CONFIG_TAG_CONFIGURATION, gdb_configs, package_index);
   if (!status) {

      // For each node, extract the critical attributes, and add to tree
      n := gdb_configs._length();
      for (i:=0; i<n; ++i) {
         if (value) {
            _xmlcfg_set_attribute(fh,gdb_configs[i],attr_name,0);
         }
      }
   }
}

///////////////////////////////////////////////////////////////////////////
// Callbacks for create new session form
//
defeventtab _debug_select_session_form;
void ctl_ok.lbutton_up()
{
   // check that they have supplied a session name
   session_name := ctl_session_combo.p_text;
   if (session_name == "") {
      debug_message("You must supply a session name!",0,true);
      ctl_session_combo._set_focus();
      return;
   }

   // make sure the session name is unique
   debug_cb_name := ctl_session_combo.p_user;
   session_id := dbg_find_session(session_name);
   if (session_id > 0) {
      if (dbg_is_session_active(session_id) ||
          dbg_get_callback_name(session_id) != debug_cb_name) {
         debug_message("Another session already exists with this name!",0,true);
         ctl_session_combo._set_focus();
         return;
      }
   }

   // return the session name
   p_active_form._delete_window(session_name);
}
int debug_load_session_names(_str debug_cb_name="", _str default_name="")
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // get all the available debugger sessions
   int session_ids[];
   dbg_get_all_sessions(session_ids);

   // load all the session names into the combo box
   max_width := 0;
   session_name := "";
   first_name := "";
   n := session_ids._length();
   for (i:=n-1; i>=0; --i) {
      session_id := session_ids[i];
      if (dbg_is_session_active(session_id)) {
         continue;
      }

      // always include the workspace session if it isn't active
      if (debug_cb_name != "" && 
          session_id != debug_get_workspace_session_id(debug_cb_name) &&  
          dbg_get_callback_name(session_id) != debug_cb_name) {
         continue;
      }

      session_name = dbg_get_session_name(session_id);
      if (first_name == "") first_name = session_name;
      _lbadd_item(session_name);
      _cbset_text(session_name);
      
      item_width := _text_width(session_name);
      if (item_width > max_width) {
         max_width = item_width;
      }
   }
   _lbadd_item(VSDEBUG_NEW_SESSION);
   if (default_name != "") {
      _cbset_text(default_name);
   } else if (first_name != "") {
      _cbset_text(first_name);
   } else {
      _cbset_text(VSDEBUG_NEW_SESSION);
   }
   return max_width+450;
}
void ctl_ok.on_create(_str debug_cb_name=_project_DebugCallbackName,
                      _str default_name="")
{
   // save the callback name for verification later
   ctl_session_combo.p_user = debug_cb_name;

   // get all the available debugger sessions
   max_width := ctl_session_combo.debug_load_session_names(debug_cb_name, default_name);

   // If the workspace session is not active, and of the right type,
   // and there is no session matching the default name.
   // Then make the workspace session name the default.
   use_workspace_as_default := false;
   workspace_session_id := debug_get_workspace_session_id(debug_cb_name);
   if (dbg_find_session(default_name) <= 0 &&
       debug_cb_name == _project_DebugCallbackName &&
       !dbg_is_session_active(workspace_session_id)) {
      ctl_session_combo.p_text = dbg_get_session_name(workspace_session_id);
      use_workspace_as_default = true;
   }

   // did they provide a default name for this session?
   if (default_name != "") {
      ctl_session_combo._lbadd_item(default_name);
      if (!use_workspace_as_default) {
         ctl_session_combo.p_text = default_name;
      }
      
      item_width := ctl_session_combo._text_width(default_name);
      if (item_width > max_width) {
         max_width = item_width;
      }
   }

   // adjust the form size to fit the max width
   if (ctl_session_combo.p_width < max_width + ctl_session_label.p_width intdiv 2) {
      ctl_session_combo.p_width = max_width + ctl_session_label.p_width intdiv 2;
      p_active_form.p_width = ctl_session_combo.p_width + ctl_session_combo.p_x*2;
   }
}

///////////////////////////////////////////////////////////////////////////
// Callbacks for launching debugger with user-specified arguments
//
defeventtab _debug_arguments_form;
static void debug_gui_arguments_ok(_str command)
{
   // verify that the core file was specified
   program_args := ctl_args.p_text;

   // get the working directory specified
   dir_name := ctl_dir.p_text;
   if (dir_name != "" && !file_exists(_maybe_unquote_filename(dir_name))) {
      debug_message(dir_name,FILE_NOT_FOUND_RC,true);
      return;
   }

   // that's all folks
   _save_form_response();
   p_active_form._delete_window("command="command",dir="dir_name",args="program_args);
}
void ctl_step.lbutton_up()
{
   debug_gui_arguments_ok("step");
}
void ctl_run.lbutton_up()
{
   debug_gui_arguments_ok("run");
}
void ctl_step.on_create(_str working_dir="")
{
   // align the browse buttons to the text boxes
   _debug_arguments_form_initial_alignment();

   // restore the last response they entered
   ctl_dir.p_text=working_dir;
   ctl_args.p_text="";
   _retrieve_prev_form();
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _debug_arguments_form_initial_alignment()
{
   sizeBrowseButtonToTextBox(ctl_dir, ctl_find_dir.p_window_id);
}

///////////////////////////////////////////////////////////////////////////
// Handlers for debugger sessions combo box / toolbar
//
static const VSDEBUG_SESSIONS_FORM= "_tbdebug_sessions_form";
defeventtab _tbdebug_sessions_form;
void _tbdebug_sessions_form.on_resize()
{
   _tbdebug_combo_etab.p_width = p_active_form.p_width - 2*_tbdebug_combo_etab.p_x;
   _tbdebug_combo_etab.p_y = (p_active_form.p_height - _tbdebug_combo_etab.p_height)>>1;
}

// handle combo box drop down and selection
defeventtab _tbdebug_combo_etab;
void _tbdebug_combo_etab.on_drop_down(int reason)
{
   // set caption and bitmaps for current context
   if (reason==DROP_DOWN) {

      session_line := 1;
      int session_ids[];
      dbg_get_all_sessions(session_ids);

      _lbclear();
      n := session_ids._length();
      for (i:=0; i<n; ++i) {
         if (debug_active() && !dbg_is_session_active(session_ids[i])) {
            continue;
         }
         session_name := dbg_get_session_name(session_ids[i]);
         if (session_name == "") {
            continue;
         }
         _lbadd_item(session_name);
         if (session_ids[i] == dbg_get_current_session()) {
            session_line = p_line;
         }
      }

      if (n > 0) {
         _lbsort("i");
      } else {
         _lbadd_item("no debugger sessions");
      }

      h := p_pic_space_y + _text_height();
      h *= (p_Noflines+1);
      int screen_x,screen_y,screen_width,screen_height;
      _GetVisibleScreen(screen_x,screen_y,screen_width,screen_height);
      sh := (screen_height*_twips_per_pixel_y()) intdiv 2;
      p_height = (h>sh)? sh:h;
      _lbtop();
      p_line=session_line;

   } else if (reason==DROP_UP_SELECTED) {

      selected_caption := _lbget_text();
      selected_session_id := dbg_find_session(selected_caption);
      if (selected_session_id <= 0) return;
      if (selected_session_id != dbg_get_current_session()) {
         mou_hour_glass(true);
         dbg_set_current_session(selected_session_id);
         debug_gui_update_session();
         debug_pkg_enable_disable_tabs();
         mou_hour_glass(false);
      }
   }
}
void _tbdebug_combo_etab.on_change(int reason)
{
   return;
   selected_caption := _lbget_text();
   selected_session_id := dbg_find_session(selected_caption);
   if (selected_session_id <= 0) return;
   if (selected_session_id != dbg_get_current_session()) {
      mou_hour_glass(true);
      dbg_set_current_session(selected_session_id);
      debug_gui_update_session();
      debug_pkg_enable_disable_tabs();
      mou_hour_glass(false);
   }
}
// callback for when a context combo box is created
void _tbdebug_combo_etab.on_create()
{
   p_width = 2100;
   p_pic_point_scale=8;
   p_style=PSCBO_NOEDIT;

   debug_gui_update_current_session();
}

/**
 * @return
 *    Return the window ID of the window containing the
 *    debugger sessions selection combo box.
 */
CTL_FORM debug_gui_sessions_wid()
{
   static CTL_FORM form_wid;

   if (_iswindow_valid(form_wid) && !form_wid.p_edit &&
       form_wid.p_object==OI_FORM && form_wid.p_name==VSDEBUG_SESSIONS_FORM) {
      return(form_wid);
   }

   form_wid=_find_formobj(VSDEBUG_SESSIONS_FORM,'N');
   return(form_wid);
}

/**
 * @return
 *    Return the window ID of the debugger sessions combo box.
 */
CTL_COMBO debug_gui_session_list()
{
   CTL_FORM wid=debug_gui_sessions_wid();
   return (wid? wid._tbdebug_combo_etab:0);
}

/**
 * Update the current context combo box window(s)
 * the current object must be the editor control to update
 *
 * @param AlwaysUpdate  update now, or wait for
 *                      CONTEXT_UPDATE_TIMEOUT ms idle time?
 */
void debug_gui_update_current_session()
{
   if (!_haveDebugging()) return;
   wid := debug_gui_session_list();
   if (wid <= 0) {
      return;
   }

   session_id := dbg_get_current_session();
   int session_ids[];
   dbg_get_all_sessions(session_ids);

   wid._lbclear();
   wid._lbadd_item("no debugger sessions");
   n := session_ids._length();
   for (i:=0; i<n; ++i) {
      session_name := dbg_get_session_name(session_ids[i]);
      wid._lbadd_item(session_name);
   }

   if (session_id > 0) {
      wid.p_text = dbg_get_session_name(session_id);
   } else {
      wid.p_text = "no debugger sessions";
   }
}

/**
 * Is the given status a bad termination status for the debugger. 
 * This might mean we were unable to connect to the debugger. 
 */
static bool debug_is_dead_status(int status)
{
   switch (status) {
   case DEBUG_NOT_INITIALIZED_RC:
   case DEBUG_PROGRAM_FINISHED_RC:
   case DEBUG_GDB_TIMEOUT_RC:
   case DEBUG_GDB_TERMINATED_RC:
   case DEBUG_GDB_APP_EXITED_RC:
   case DEBUG_GDB_ERROR_OPENING_FILE_RC:
   case DEBUG_JDWP_INVALID_HANDSHAKE_RC:
   case DEBUG_MONO_INVALID_HANDSHAKE_RC:
   case DEBUG_DBGP_NOT_CONNECTED_RC:
   case DEBUG_GDB_ALL_PTYS_IN_USE_RC:
   case DEBUG_GDB_CANNOT_OPEN_SLAVE_PTY_RC:
   case DEBUG_GDB_MISSING_GDB_RC:
   case DEBUG_GDB_ERROR_ATTACHING_REMOTE_RC:
   case DEBUG_GDB_ERROR_ATTACHING_CORE_RC:
      return true;
   default:
      return false;
   }
}

///////////////////////////////////////////////////////////////////////////
// Handlers for debug threads toolbar
//
static const VSDEBUG_THREADS_FORM= "_tbdebug_threads_form";
defeventtab _tbdebug_threads_form;
void _tbdebug_threads_form.'C-A'-'C-Z',F2-F4,f6-F12,C_F12,'c-a-a'-'c-a-z','a-0'-'a-9'()
{
   _smart_toolwindow_hotkey();
}
void _tbdebug_threads_form.'C-W',A_LEFT,A_RIGHT,A_UP()
{
   if (!_no_child_windows()) {
      p_window_id=_mdi.p_child;
      _set_focus();
   }
}
void _tbdebug_threads_form.on_create()
{
   _nocheck _control ctl_threads_tree;

   ctl_threads_tree._TreeSetColButtonInfo(0,1500,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Thread");
   ctl_threads_tree._TreeSetColButtonInfo(1,1500,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Group");
   ctl_threads_tree._TreeSetColButtonInfo(2,1500,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Status");
   ctl_threads_tree._TreeSetColButtonInfo(3,-1,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"State");

   dbg_invalidate_views();

   ctl_threads_tree.p_user = 0;

   debug_pkg_enable_disable_tabs();
   debug_gui_update_threads();
}
void _tbdebug_threads_form.on_destroy()
{
   ctl_threads_tree._TreeAppendColButtonInfo();
}
void _twSaveState__tbdebug_threads_form(typeless& state, bool closing)
{
   ctl_threads_tree._TreeAppendColButtonInfo();
}
void _twRestoreState__tbdebug_threads_form(typeless& state, bool opening)
{
   ctl_threads_tree._TreeRetrieveColButtonInfo();
}
void _tbdebug_threads_form.on_resize()
{
   _nocheck _control ctl_threads_tree;
   debug_gui_resize_toolbar(0,ctl_threads_tree);
   if ( !(p_window_flags & VSWFLAG_ON_RESIZE_ALREADY_CALLED) ) {
      // First time
      ctl_threads_tree._TreeRetrieveColButtonInfo();
      ctl_threads_tree._TreeAdjustLastColButtonWidth(); 
   }
}
void _tbdebug_threads_form.on_change(int reason)
{ 
   if (reason==CHANGE_AUTO_SHOW ) {
      tree_wid := _find_control("ctl_threads_tree");
      if (tree_wid && tree_wid.p_user) {
         debug_gui_update_threads(true);
      }
   }
}
void _tbdebug_threads_form.on_got_focus()
{ 
   tree_wid := _find_control("ctl_threads_tree");
   if (tree_wid && tree_wid.p_user) {
      debug_gui_update_threads();
   }
}
void ctl_threads_tree.on_change(int reason,int index)
{
   if (!debug_active()) return;
   if (gInUpdateThreadList) return;
   //say("ctl_threads_tree.on_change: reason="reason" index="index);
   if (reason == CHANGE_SELECTED || reason == CHANGE_LEAF_ENTER) {
      cur_index := _TreeCurIndex();
      if (cur_index > 0) {
         show_children := 0;
         _TreeGetInfo(cur_index, show_children);
         if (show_children < 0) {
            thread_id := (int)_TreeGetUserInfo(cur_index);
            frame_id := dbg_get_cur_frame(thread_id);
            //say("ctl_threads_tree.on_change: thread_id="thread_id);
            dbg_set_cur_thread(thread_id);
            debug_gui_update_cur_thread(thread_id);
            debug_gui_update_stack(thread_id);
            debug_gui_update_registers(thread_id);
            debug_gui_switch_frame(thread_id,frame_id);
            if (debug_is_suspended() && reason == CHANGE_LEAF_ENTER) {
               debug_show_next_statement(true,0,0,"","",thread_id,frame_id);
            }
         }
      }
   } else if (reason == CHANGE_EXPANDED) {
   } else if (reason == CHANGE_COLLAPSED) {
   }
}

/**
 * Clear the thread group tree update flags
 */
void debug_gui_clear_thread_update_flags()
{
   gInUpdateThreadList=false;
   gInUpdateThread=false;
   gInUpdateFrame=false;
}

/**
 * @return
 *    Return the window ID of the window containing the threads
 *    combo and list of threads.
 */
CTL_FORM debug_gui_threads_wid()
{
   static CTL_FORM form_wid;

   if (_iswindow_valid(form_wid) && !form_wid.p_edit &&
       form_wid.p_object==OI_FORM && form_wid.p_name==VSDEBUG_THREADS_FORM ) {
      return(form_wid);
   }

   form_wid=_find_formobj(VSDEBUG_THREADS_FORM,'N');
   return(form_wid);
}
static CTL_TREE debug_gui_threads_tree()
{
   CTL_FORM wid=debug_gui_threads_wid();
   return (wid? wid.ctl_threads_tree:0);
}
void debug_gui_clear_threads()
{
   // clear the threads list
   CTL_TREE tree_wid=debug_gui_threads_tree();
   if (tree_wid) {
      tree_wid._TreeDelete(TREE_ROOT_INDEX,'c');
   }
}
int debug_gui_get_selected_thread()
{
   CTL_TREE tree_wid=debug_gui_threads_tree();
   if (!tree_wid) {
      return(0);
   }
   tree_index := tree_wid._TreeCurIndex();
   if (tree_index <= 0) {
      return(0);
   }
   return tree_wid._TreeGetUserInfo(tree_index);
}

// Handle right-button released event, in order to display pop-up menu
// for the threads tree.
//
void ctl_threads_tree.rbutton_up()
{
   // get the menu form
   index := find_index("_debug_threads_menu",oi2type(OI_MENU));
   if (!index) {
      return;
   }
   menu_handle := p_active_form._menu_load(index,'P');
   tree_wid := p_window_id;

   // Show the menu.
   x := mou_last_x('M')-100;
   y := mou_last_y('M')-100;
   _lxy2dxy(p_scale_mode,x,y);
   _map_xy(p_window_id,0,x,y,SM_PIXEL);
   _KillToolButtonTimer();
   _menu_show(menu_handle,VPM_LEFTALIGN|VPM_RIGHTBUTTON,x,y);
   _menu_destroy(menu_handle);
}


///////////////////////////////////////////////////////////////////////////
// Handlers for debugger call stack toolbar
//
static const VSDEBUG_STACK_FORM= "_tbdebug_stack_form";
defeventtab _tbdebug_stack_form;
void _tbdebug_stack_form.'C-A'-'C-Z',F2-F4,f6-F12,C_F12,'c-a-a'-'c-a-z','a-0'-'a-9'()
{
   _smart_toolwindow_hotkey();
}
void _tbdebug_stack_form.'C-W',A_LEFT,A_RIGHT,A_UP()
{
   if (!_no_child_windows()) {
      p_window_id=_mdi.p_child;
      _set_focus();
   }
}
void _tbdebug_stack_form.on_create()
{
   dbg_invalidate_views();

   ctl_stack_tree._TreeSetColButtonInfo(0,2000,TREE_BUTTON_PUSHBUTTON,0,"Method");
   ctl_stack_tree._TreeSetColButtonInfo(1,-1,TREE_BUTTON_PUSHBUTTON,0,"Class");

   debug_pkg_enable_disable_tabs();
   thread_id := dbg_get_cur_thread();
   if (debug_is_suspended()) {
      status := debug_pkg_update_threads();
      if (!debug_is_dead_status(status)) {
         status = debug_pkg_update_threadgroups();
      }
      gInUpdateThreadList = true;
      debug_gui_update_suspended();
      thread_id = dbg_get_cur_thread();
      ctl_thread_combo._lbclear();
      dbg_update_thread_list(ctl_thread_combo.p_window_id,true);
      ctl_thread_combo.p_line=thread_id;
      ctl_thread_combo._lbselect_line();
      ctl_thread_combo._cbset_text(ctl_thread_combo._lbget_text());
      if (!debug_is_dead_status(status)) {
         status = debug_pkg_update_stack(thread_id);
      }
      ctl_stack_tree._TreeDelete(TREE_ROOT_INDEX, 'C');
      gInUpdateThreadList = false;
   }
   dbg_update_stack_tree(ctl_stack_tree,TREE_ROOT_INDEX,thread_id);
   ctl_stack_tree._TreeSortUserInfo(TREE_ROOT_INDEX,'N');
}
void _tbdebug_stack_form.on_destroy()
{
   ctl_stack_tree._TreeAppendColButtonInfo();
}
void _twSaveState__tbdebug_stack_form(typeless& state, bool closing)
{
   ctl_stack_tree._TreeAppendColButtonInfo();
}
void _twRestoreState__tbdebug_stack_form(typeless& state, bool opening)
{
   ctl_stack_tree._TreeRetrieveColButtonInfo();
}
void _tbdebug_stack_form.on_resize()
{
   _nocheck _control ctl_stack_tree;
   _nocheck _control ctl_thread_combo;

   // adjust breakpoints for resizable icons
   ctl_stack_tree.p_x = ctl_top_btn.p_x*2 + ctl_top_btn.p_width;
   ctl_up_btn.p_y = ctl_top_btn.p_y_extent;
   ctl_down_btn.p_y = ctl_up_btn.p_y_extent;

   // now resize the rest of the toolbar
   debug_gui_resize_toolbar(0,ctl_stack_tree,0,ctl_thread_combo);

   if ( !(p_window_flags & VSWFLAG_ON_RESIZE_ALREADY_CALLED) ) {
      // First time
      ctl_stack_tree._TreeRetrieveColButtonWidths();
      ctl_stack_tree._TreeAdjustLastColButtonWidth(); 
   }
}

/**
 * @return
 *    Return the window ID of the window containing the stack
 *    combo and list of stack.
 */
CTL_FORM debug_gui_stack_wid()
{
   static CTL_FORM form_wid;

   if (_iswindow_valid(form_wid) && !form_wid.p_edit &&
       form_wid.p_object==OI_FORM && form_wid.p_name==VSDEBUG_STACK_FORM) {
      return(form_wid);
   }

   form_wid=_find_formobj(VSDEBUG_STACK_FORM,'N');
   return(form_wid);
}
CTL_COMBO debug_gui_stack_thread_list()
{
   CTL_FORM wid=debug_gui_stack_wid();
   return (wid? wid.ctl_thread_combo:0);
}
CTL_TREE debug_gui_stack_tree()
{
   CTL_FORM wid=debug_gui_stack_wid();
   return (wid? wid.ctl_stack_tree:0);
}
void debug_gui_clear_stack()
{
   CTL_TREE tree_wid=debug_gui_stack_tree();
   if (tree_wid) {
      tree_wid._TreeDelete(TREE_ROOT_INDEX,'c');
   }
   list_wid := debug_gui_stack_thread_list();
   if (list_wid) {
      list_wid._lbclear();
      list_wid._cbset_text("");
   }
}
void ctl_thread_combo.on_got_focus()
{
   if ( !(p_active_form.p_window_flags & VSWFLAG_ON_CREATE_ALREADY_CALLED) ) return;
   if ( !(p_active_form.p_window_flags & VSWFLAG_ON_RESIZE_ALREADY_CALLED) ) return;
   if (gInUpdateThreadList) return;
   if (gInComboboxDropDown) return;
   gInUpdateThreadList = true;
   debug_pkg_update_threads();
   debug_pkg_update_threadgroups();
   thread_id := dbg_get_cur_thread();
   _lbclear();
   dbg_update_thread_list(p_window_id,true);
   ctl_thread_combo.p_line=thread_id;
   ctl_thread_combo._lbselect_line();
   ctl_thread_combo._cbset_text(ctl_thread_combo._lbget_text());
   gInUpdateThreadList = false;
}
void ctl_thread_combo.on_drop_down(int reason)
{
   // set caption and bitmaps for current context
   if (gInUpdateThreadList) return;
   gInComboboxDropDown = false;
   if (reason==DROP_INIT) {
      gInUpdateThreadList = true;
      debug_pkg_update_threads();
      debug_pkg_update_threadgroups();
      thread_id := dbg_get_cur_thread();
      _lbclear();
      dbg_update_thread_list(p_window_id,true);
      ctl_thread_combo.p_line=thread_id;
      ctl_thread_combo._lbselect_line();
      ctl_thread_combo._cbset_text(ctl_thread_combo._lbget_text());
      gInUpdateThreadList = false;

   } else if (reason==DROP_DOWN) {
      gInComboboxDropDown = true;
   }  else if (reason==DROP_UP) {
   }  else if (reason==DROP_UP_SELECTED) {
      found_line := _lbfind_item(p_text);
      if (found_line >= 0) p_line=found_line+1;
      thread_id := p_line;
      ctl_thread_combo._lbselect_line();
      ctl_thread_combo._cbset_text(ctl_thread_combo._lbget_text());
      frame_id := dbg_get_cur_frame(thread_id);
      dbg_set_cur_suspended_thread(thread_id);
      debug_gui_update_cur_thread(thread_id);
      debug_gui_update_stack(thread_id);
      debug_gui_update_registers(thread_id);
      debug_gui_switch_frame(thread_id,frame_id);
   }
}
void ctl_thread_combo.on_change(int reason, int index=0)
{
   if (!debug_active()) return;
   if (gInUpdateThreadList || gInUpdateThread) return;
   if (reason == CHANGE_CLINE || reason==CHANGE_CLINE_NOTVIS) {
      if (gInComboboxDropDown) return;
      gInUpdateThread=true;
      if (index >= 0) p_line=index;
      if (p_line != index) p_text=p_text;
      gInUpdateThread=false;
      thread_id := p_line;
      if (thread_id > 0 && thread_id <= dbg_get_num_threads()) {
         frame_id := dbg_get_cur_frame(thread_id);
         dbg_set_cur_suspended_thread(thread_id);
         debug_gui_update_cur_thread(thread_id);
         debug_gui_update_stack(thread_id);
         debug_gui_update_registers(thread_id);
         debug_gui_switch_frame(thread_id,frame_id);
      }
   } else if (reason == CHANGE_OTHER) {
   } else if (reason == CHANGE_SELECTED) {
   }
}
void ctl_stack_tree.on_change(int reason,int index)
{
   //say("ctl_stack_tree.on_change: reason="reason "index="index);
   if (!debug_active()) return;
   if (!debug_is_suspended()) return;
   if (gInUpdateThreadList || gInUpdateThread) return;
   if (reason == CHANGE_SELECTED) {
      cur_index := _TreeCurIndex();
      if (cur_index > 0) {
         thread_id := dbg_get_cur_thread();
         frame_id := (int)_TreeGetUserInfo(cur_index);
         debug_gui_switch_frame(thread_id,frame_id);
      }
   } else if (reason == CHANGE_EXPANDED) {
   } else if (reason == CHANGE_COLLAPSED) {
   } else if (reason == CHANGE_LEAF_ENTER) {
   }
}
// switch stack frame and go to source
void ctl_stack_tree.lbutton_double_click()
{
   if (!debug_active()) return;
   if (!debug_is_suspended()) return;
   cur_index := _TreeCurIndex();
   if (cur_index > 0) {
      _tbSetRefreshBy(VSTBREFRESHBY_DEBUGGING);
      _tbOnUpdate(true);
      thread_id := dbg_get_cur_thread();
      frame_id := (int)_TreeGetUserInfo(cur_index);
      debug_gui_switch_frame(thread_id,frame_id);
      debug_show_next_statement(false,0,0,"","",thread_id,frame_id);
   }
}
// Handle right-button released event, in order to display pop-up menu
// for the threads tree.
//
void ctl_stack_tree.rbutton_up()
{
   // get the menu form
   index := find_index("_debug_stack_menu",oi2type(OI_MENU));
   if (!index) {
      return;
   }
   menu_handle := p_active_form._menu_load(index,'P');
   CTL_TREE tree_wid=p_window_id;

   // Show the menu.
   x := mou_last_x('M')-100;
   y := mou_last_y('M')-100;
   _lxy2dxy(p_scale_mode,x,y);
   _map_xy(p_window_id,0,x,y,SM_PIXEL);
   _KillToolButtonTimer();
   _menu_show(menu_handle,VPM_LEFTALIGN|VPM_RIGHTBUTTON,x,y);
   _menu_destroy(menu_handle);
}

void debug_gui_stack_update_buttons()
{
   if (!_haveDebugging()) return;
   CTL_FORM form_wid=debug_gui_stack_wid();
   if (!form_wid) {
      return;
   }
   CTL_TREE tree_wid=debug_gui_stack_tree();
   if (!tree_wid) {
      return;
   }
   down_enabled := true;
   up_enabled := true;
   top_enabled := true;
   no_of_frames := tree_wid._TreeGetNumChildren(TREE_ROOT_INDEX);
   tree_index := tree_wid._TreeCurIndex();
   if (no_of_frames>0 && tree_index>0 && debug_is_suspended()) {
      frame_id := tree_wid._TreeGetUserInfo(tree_index);
      thread_id := dbg_get_cur_thread();
      file_name := "";
      line_number := 0;
      dbg_get_frame_path(thread_id,frame_id,file_name,line_number);
      if (frame_id <= 1) {
         up_enabled=false;
         top_enabled=false;
      }
      if (frame_id >= no_of_frames) {
         down_enabled=false;
      }
   } else {
      down_enabled=false;
      up_enabled=false;
      top_enabled=false;
   }
   _nocheck _control ctl_down_btn;
   _nocheck _control ctl_up_btn;
   _nocheck _control ctl_top_btn;
   if (form_wid.ctl_down_btn.p_enabled!=down_enabled) {
      form_wid.ctl_down_btn.p_enabled=down_enabled;
   }
   if (form_wid.ctl_up_btn.p_enabled!=up_enabled) {
      form_wid.ctl_up_btn.p_enabled=up_enabled;
   }
   if (form_wid.ctl_top_btn.p_enabled!=top_enabled) {
      form_wid.ctl_top_btn.p_enabled=top_enabled;
   }
}

///////////////////////////////////////////////////////////////////////////
// Utility functions for variables and watches toolbars
//

/**
 * From the current index in the tree, construct a local
 * variable, member variable, or watch variable path for
 * expanding sub-nodes of an item.
 * <P>
 * The current object must be a tree control.
 *
 * @param tree_index      index within three
 *
 * @return Path (list of indexes) to tree node
 */
static _str debug_get_variable_path(int tree_index)
{
   if (tree_index==TREE_ROOT_INDEX) {
      return "";
   }
   path := _TreeGetUserInfo(tree_index);
   tree_index = _TreeGetParentIndex(tree_index);
   while (tree_index != TREE_ROOT_INDEX) {
       path=_TreeGetUserInfo(tree_index) :+ " " :+ path;
       tree_index = _TreeGetParentIndex(tree_index);
   }
   return path;
}

/**
 * Is this node modifyable?
 */
static int debug_gui_check_modifiable(int index)
{
   if (!debug_is_suspended()) {
      debug_message("Can not modify variable while application is running.",0,false);
      return(-1);
   }

   // if the variable has children, then we don't want to mess with it
   show_children := 0;
   _TreeGetInfo(index,show_children);
   caption := _TreeGetCaption(index);
   if (show_children >= 0) {
      // check if it is a string, special case
      if (pos('^[^\t]*\t["]?*["]',caption,1,'r')) {
         return(0);
      }
      return(-1);
   }

   if (caption == DEBUG_ADD_WATCH_CAPTION) {
      return (-1);
   }

   // check if it is a null class, another special case
   if (pos('^[^\t]*\t[^("]*[(]null[)]',caption,1,'r')) {
      return(-1);
   }

   // check if it is an error message
   if (pos('^[^\t]*\t[*][*]?*[*][*]',caption,1,'r')) {
      return(-1);
   }

   // check if it is a void return type
   if (pos('^[^\t]*\tvoid$',caption,1,'r') || pos('^[^\t]*\tvoid\t',caption,1,'r')) {
      return(-1);
   }

   // is this a tuple?  they are UNCHANGING!
   parent := _TreeGetParentIndex(index);
   if (parent > 0) {
      // the type will always be in the last column
      numCols := _TreeGetNumColButtons();
      if (numCols > 0) {
         caption = _TreeGetTextForCol(parent, numCols - 1);
         if (caption != null && pos('^tuple \(:i# items\)$',caption,1,'r')) {
            return -1;
         }
      }
   }

   // looks OK to me
   return(0);
}

/**
 * Create a list of field paths that are expanded.
 * This is used to save and restore the tree between
 * refreshes.
 *
 * @param tree_index      tree node index to start at
 * @param base_path       base path, initially the empty string
 * @param path_list       (reference) list of paths to construct
 */
static void debug_gui_reexpand_fields(int tree_index)
{
   index := _TreeGetFirstChildIndex(tree_index);
   while (index > 0) {
      show_children := 0;
      _TreeGetInfo(index,show_children);
      if (show_children > 0) {
         call_event(CHANGE_EXPANDED,index,p_window_id,ON_CHANGE,'w');
         _TreeSetInfo(index, 1);

         // If the first child is an array index, resort the children.
         // When we update the value of an array element, the GUI reinserts
         // it as the last child (same level). We're resorting to fix this.
         //
         childIndex := _TreeGetFirstChildIndex( index);
         if (childIndex > 0) {
            caption := _TreeGetCaption( childIndex);
            debug_gui_reexpand_fields(index);
            _TreeSortUserInfo( index, 'N') ;
         }
      }
      index=_TreeGetNextSiblingIndex(index);
   }
}

/**
 * Display a status message from the debugger as a tree item.
 */
static int debug_tree_message(int status)
{
   _TreeDelete(TREE_ROOT_INDEX,'c');
   msg := nls("Error") :+ "\t**" :+ get_message(status) :+ "**";
   index := _TreeAddItem(TREE_ROOT_INDEX,msg,TREE_ADD_AS_CHILD,0,0,-1,TREENODE_BOLD,0);
   p_window_id._TreeRefresh();
   return(status);
}

/**
 * Display a status message from the debugger as a tree item.
 */
static void debug_warn_if_empty()
{
   if (_TreeGetNumChildren(TREE_ROOT_INDEX)==0) {
      msg :=  "Warning" :+ "\t" :+ "**No symbols visible in this context**";
      index := _TreeAddItem(TREE_ROOT_INDEX,msg,TREE_ADD_AS_CHILD,0,0,-1,0,0);
   }
}

///////////////////////////////////////////////////////////////////////////
// Handlers for debugger local variables toolbar
//
static const VSDEBUG_LOCALS_FORM= "_tbdebug_locals_form";
defeventtab _tbdebug_locals_form;
void _tbdebug_locals_form.'C-A'-'C-Z',F2-F4,f6-F12,C_F12,'c-a-a'-'c-a-z','a-0'-'a-9'()
{
   _smart_toolwindow_hotkey();
}
void _tbdebug_locals_form.'C-W',A_LEFT,A_RIGHT,A_UP()
{
   if (!_no_child_windows()) {
      p_window_id=_mdi.p_child;
      _set_focus();
   }
}
void _tbdebug_locals_form.on_create()
{
   dbg_invalidate_views();

   // even though we allow modifying variables with the dynamic 
   // debuggers, we don't do it in the tree
   editable_flag := (isDynamicDebugger() || debug_session_is_implemented("modify_local")==0)? 0:TREE_EDIT_TEXTBOX;
   displayType := debug_session_is_implemented("display_var_types");

   // set up our column widths
   col0Width := 2000;
   col1Width := 0;
   col2Width := 0;
   if (displayType) {
      col0Width = 1500;
      col1Width = 1500;
      col2Width = 0;
   }

   ctl_locals_tree._TreeSetColButtonInfo(0,col0Width,TREE_BUTTON_PUSHBUTTON/*|TREE_BUTTON_SORT*/,0,"Name");
   ctl_locals_tree._TreeSetColButtonInfo(1,col1Width,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_WRAP|(displayType? 0:TREE_BUTTON_AUTOSIZE),0,"Value");
   ctl_locals_tree._TreeSetColEditStyle(1,editable_flag);
   if (displayType) {
      ctl_locals_tree._TreeSetColButtonInfo(2,col2Width,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_WRAP|TREE_BUTTON_AUTOSIZE,0,"Type");
   }

   ctl_locals_tree.p_user=0;

   debug_pkg_enable_disable_tabs();
   debug_gui_update_suspended();
   thread_id := dbg_get_cur_thread();
   frame_id := dbg_get_cur_frame(thread_id);
   if (debug_is_suspended()) {
      status := debug_pkg_update_stack(thread_id);
      if (!debug_is_dead_status(status)) {
         status = debug_gui_update_locals(thread_id,frame_id);
      }
   }
   dbg_update_stack_list(ctl_stack_combo.p_window_id,thread_id);
   debug_gui_update_cur_frame(thread_id,frame_id);
}
void _tbdebug_locals_form.on_destroy()
{
   ctl_locals_tree._TreeAppendColButtonInfo();
}
void _twSaveState__tbdebug_locals_form(typeless& state, bool closing)
{
   ctl_locals_tree._TreeAppendColButtonInfo();
}
void _twRestoreState__tbdebug_locals_form(typeless& state, bool opening)
{
   ctl_locals_tree._TreeRetrieveColButtonInfo();
}
void _tbdebug_locals_form.on_resize()
{
   _nocheck _control ctl_locals_tree;
   _nocheck _control ctl_stack_combo;
   debug_gui_resize_toolbar(0,ctl_locals_tree,0,ctl_stack_combo);

   if ( !(p_window_flags & VSWFLAG_ON_RESIZE_ALREADY_CALLED) ) {
      // First time
      ctl_locals_tree._TreeRetrieveColButtonInfo();
      ctl_locals_tree._TreeAdjustLastColButtonWidth(); 
   }
}

void _tbdebug_locals_form.on_change(int reason)
{ 
   if (reason==CHANGE_AUTO_SHOW ) {
      tree_wid := _find_control("ctl_locals_tree");
      if (tree_wid && tree_wid.p_user) {
         thread_id := dbg_get_cur_thread();
         frame_id := dbg_get_cur_frame(thread_id);
         debug_gui_update_locals(thread_id,frame_id,true);
      }
   }
}
void _tbdebug_locals_form.on_got_focus()
{ 
   tree_wid := _find_control("ctl_locals_tree");
   if (tree_wid && tree_wid.p_user) {
      thread_id := dbg_get_cur_thread();
      frame_id := dbg_get_cur_frame(thread_id);
      debug_gui_update_locals(thread_id,frame_id);
   }
}
// if not suspended, do not allow node to be expanded
static int debug_expand_var_requires_suspend(int index)
{
   if (debug_is_suspended()) {
      return 0;
   }
   if (_TreeGetNumChildren(index) > 0) {
      return 0;
   }
   debug_message("Can not expand variable", DEBUG_THREAD_NOT_SUSPENDED_RC, false);
   return DEBUG_THREAD_NOT_SUSPENDED_RC;
}
int ctl_locals_tree.on_change(int reason,int index)
{
   status := 0;
   if (reason==CHANGE_SELECTED) {
   } else if (reason==CHANGE_EXPANDED) {
      if (debug_expand_var_requires_suspend(index) < 0) return 0;
      thread_id := dbg_get_cur_thread();
      frame_id := dbg_get_cur_frame(thread_id);
      local_path := debug_get_variable_path(index);
      status=debug_pkg_expand_local(thread_id,frame_id,local_path);
      if (status) {
         return(status);
      }
      _TreeBeginUpdate(index);
      status=dbg_update_locals_tree(p_window_id,index,thread_id,frame_id,local_path);
      _TreeEndUpdate(index);
      _TreeSortUserInfo(index,'N');
      return(status);

   } else if (reason==CHANGE_COLLAPSED) {
      thread_id := dbg_get_cur_thread();
      frame_id := dbg_get_cur_frame(thread_id);
      local_path := debug_get_variable_path(index);
      //dbg_collapse_local(thread_id,frame_id,local_path);
      //_TreeDelete(index,'C');
      return(-1);

   } else if (reason == CHANGE_LEAF_ENTER) {
      // if this is a value column in a dynamic debugger, then it's time to change the value
      if (getTreeColFromMouse() == 1 && isDynamicDebugger()) {

         if (debug_session_is_implemented("modify_local") && !debug_gui_check_modifiable(index)) {
            
            // we do special handling for the dynamic debuggers - they can change their variable types willy-nilly!
            session_id := dbg_get_current_session();
            thread_id := dbg_get_cur_thread();
            frame_id := dbg_get_cur_frame(thread_id);
            path := debug_get_variable_path(index);
            
            sig := value := oldValue := name := class_name := "";
            flags := line_number := is_in_scope := 0;
            dbg_get_local(thread_id, frame_id, path, name, class_name, sig, flags, value, line_number, is_in_scope, oldValue); 
            
            varName := _TreeGetTextForCol(index, 0);
            newValue := "";
            if (!show_modify_variable_dlg(session_id, thread_id, frame_id, oldValue, varName, newValue)) {
               debug_gui_modify_local(index, thread_id, frame_id, path, newValue);
            }
         }
      } 
   } else if (reason == CHANGE_EDIT_OPEN) {
      // get the raw value of the variable
      thread_id := dbg_get_cur_thread();
      frame_id := dbg_get_cur_frame(thread_id);
      local_path := debug_get_variable_path(index);
      sig := value := raw_value := name := class_name := "";
      flags := line_number := is_in_scope := 0;
      dbg_get_local(thread_id, frame_id, local_path, name, class_name, sig, flags, value, line_number, is_in_scope, raw_value); 

      // set the raw value in the text box, so the user is editing the real thing
      // unless they are editing a string value, then it needs to remain quoted and escaped
      if (first_char(value) != '"' && first_char(value) != "'") {
         arg(4) = raw_value;
      }

      return 0;
   } else if (reason == CHANGE_EDIT_QUERY) {
      // The debugger might have changed its mind, so check
      // each time. This is specifically useful for PHP,
      // Python, and Perl debuggers that do not know if they
      // support modifying variables until the session is
      // started.

      if( !debug_session_is_implemented("modify_local") ) {
         return(-1);
      }
      return debug_gui_check_modifiable(index);
   } else if (reason == CHANGE_EDIT_CLOSE) {
      if (arg(4)=="") {
         return(DELETED_ELEMENT_RC);
      }

      // we will need this information to reload the tree
      thread_id := dbg_get_cur_thread();
      frame_id := dbg_get_cur_frame(thread_id);
      path := debug_get_variable_path(index);

      // give this a whirl
      status = debug_gui_modify_local(index, thread_id, frame_id, path, arg(4));
      if (status == -1) {
         arg(4) = _TreeGetTextForCol(index, 1);
      }

      return status;
   }

   return(0);
}

static int debug_gui_modify_local(int index, int thread_id, int frame_id, _str path, _str newValue)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (newValue=="") return(DELETED_ELEMENT_RC);
   status := debug_pkg_modify_local(thread_id, frame_id, path, newValue);

   // error - show a message, but reload the tree anyway!
   if (status) {
      debug_message("Could not modify local",status);
      if (status!=DEBUG_GDB_ERROR_MODIFYING_VARIABLE_RC &&
          status!=DEBUG_JDWP_ERROR_MODIFYING_VARIABLE_RC) {
         return(-1);
      }
   }

   parent_index := _TreeGetParentIndex(index);
   _TreeBeginUpdate(parent_index);
   status=dbg_update_locals_tree(p_window_id,parent_index,
                                 thread_id,frame_id,path);

   _TreeEndUpdate(parent_index);
   _TreeSortUserInfo(parent_index,'N');
   if (status) {
      debug_message("Error",status);
   }

   debug_gui_update_all_vars();
   return(DELETED_ELEMENT_RC);

}

// Handle right-button released event, in order to display pop-up menu
// for the threads tree.
//
void ctl_locals_tree.rbutton_up()
{
   // get the menu form
   index := find_index("_debug_variables_menu",oi2type(OI_MENU));
   if (!index) {
      return;
   }
   menu_handle := p_active_form._menu_load(index,'P');
   CTL_TREE tree_wid=p_window_id;

   cur_index := tree_wid._TreeCurIndex();
   if (cur_index <= 0) {
      return;
   }

   thread_id := dbg_get_cur_thread();
   frame_id := dbg_get_cur_frame(thread_id);
   if (cur_index <= 0 || dbg_get_num_locals(thread_id,frame_id) <= 0) {
      _menu_set_state(menu_handle, "goto",   MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "watch",  MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "watchpoint", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "memory", MF_GRAYED, 'C');
   }
   if (!debug_is_suspended()) {
      _menu_set_state(menu_handle, "watch",  MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "memory", MF_GRAYED, 'C');
   }

   int output_menu_handle,output_menu_pos;
   if (!_menu_find(menu_handle,"scan",output_menu_handle,output_menu_pos)) {
      _menu_delete(menu_handle,output_menu_pos);
   }
   if (!_menu_find(menu_handle,"delete",output_menu_handle,output_menu_pos)) {
      _menu_delete(menu_handle,output_menu_pos);
   }
   if (!_menu_find(menu_handle,"clearall",output_menu_handle,output_menu_pos)) {
      _menu_delete(menu_handle,output_menu_pos);
   }

   AddOrRemoveBasesFromMenu(menu_handle);

   // Show the menu.
   x := mou_last_x('M')-100;
   y := mou_last_y('M')-100;
   _lxy2dxy(p_scale_mode,x,y);
   _map_xy(p_window_id,0,x,y,SM_PIXEL);
   _KillToolButtonTimer();
   _menu_show(menu_handle,VPM_LEFTALIGN|VPM_RIGHTBUTTON,x,y);
   _menu_destroy(menu_handle);
}

static void AddOrRemoveBasesFromMenu(int menu_handle)
{
   node_index := _TreeCurIndex();
   if ( node_index>-1 ) {
      state := -1;
      _TreeGetInfo(node_index,state);
      caption := _TreeGetCaption(node_index);
      ch := _first_char(caption);
      value := "";
      parse caption with . "\t" value;

      if ( state<0 && /*ch!='[' &&*/ ch!="<" && debug_gui_check_modifiable(node_index) >= 0 ) {
         var_path := debug_get_variable_path(node_index);
         AddBasesToMenu(menu_handle);
      } else if ( state>=0 && /*ch!='[' &&*/ ch!="<" && _first_char(value)=='"' && debug_gui_check_modifiable(node_index) >= 0 ) {
         var_path := debug_get_variable_path(node_index);
         AddBasesToMenu(menu_handle);
      } else {
         submenu_handle := 0;
         menu_pos := _menu_find_loaded_menu_caption(menu_handle,"View variable as",submenu_handle);
         if ( menu_pos>-1 ) {
            _menu_delete(menu_handle,menu_pos);
         }
         menu_pos=_menu_find_loaded_menu_caption(menu_handle,"-",submenu_handle);
         if ( menu_pos>-1 ) {
            _menu_delete(menu_handle,menu_pos);
         }
      }
   }
}

/**
 * Get the simple name of the variable (or expression) currently
 * selected in the tree.
 */
static _str debug_get_variable_name()
{
   // get the caption at the current index
   variable_name := "";
   cur_index := _TreeCurIndex();
   while (cur_index > 0) {
      caption := _TreeGetCaption(cur_index);
      parse caption with caption "\t" . ;

      if (substr(caption,1,1) != "[") {
         variable_name = strip(caption) :+ variable_name;
         break;
      }

      variable_name :+= "[]";
      cur_index=_TreeGetParentIndex(cur_index);
   }
   // that's all
   return variable_name;
}

/**
 * Get the name of the variable (or expression) currently
 * selected in the tree.
 */
static _str debug_get_variable_expr()
{
   // get the caption at the current index
   cur_index := _TreeCurIndex();
   if (cur_index <= 0) {
      return "";
   }
   variable_expr := "";
   variable_value := "";
   caption := _TreeGetCaption(cur_index);
   if (caption==DEBUG_ADD_WATCH_CAPTION) {
      return "";
   }
   parse caption with caption "\t" variable_value ;
   if (caption == "Warning" && substr(variable_value,1,2)=="**") {
      return "";
   }
   variable_expr = caption;
   // now walk up the tree
   parent_index := _TreeGetParentIndex(cur_index);
   while (parent_index) {
      caption=_TreeGetCaption(parent_index);
      parse caption with caption "\t" variable_value ;
      if (substr(variable_expr,1,1)=="[") {
         variable_expr=strip(caption):+variable_expr;
      } else if (substr(variable_value,1,2)=="0x") {
         variable_expr=caption:+"->":+variable_expr;
      } else {
         variable_expr=caption:+".":+variable_expr;
      }
      parent_index=_TreeGetParentIndex(parent_index);

   }
   // that's all
   return variable_expr;
}

/**
 * Get the simple name of the variable (or expression) currently
 * selected in the tree.
 */
static int debug_get_variable_class_and_name(_str &class_name, _str &field_name)
{
   // get the caption at the current index
   class_name = "";
   field_name = "";
   cur_index := _TreeCurIndex();
   if (cur_index <= 0) {
      return DEBUG_INVALID_INDEX_RC;
   }

   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // get the path to the root of this tree
   path := debug_get_variable_path(cur_index);
   if (path == "") {
      return DEBUG_INVALID_ID_RC;
   }

   // now get the vital info
   thread_id := dbg_get_cur_thread();
   frame_id := dbg_get_cur_frame(thread_id);
   signature := "";
   value := "";
   dummy := "";
   raw_value := "";
   flags := 0;
   line_number := 0;
   is_in_scope := 0;
   if (p_window_id == debug_gui_locals_tree()) {
      dbg_get_local(thread_id,frame_id,path,field_name,class_name,signature,flags,value,line_number,is_in_scope,raw_value);
   } else if (p_window_id == debug_gui_members_tree()) {
      dbg_get_member(thread_id,frame_id,path,field_name,class_name,signature,flags,value,raw_value);
   } else if (p_window_id == debug_gui_autovars_tree()) {
      dbg_get_autovar_info(thread_id,frame_id,path,field_name,class_name,signature,value,flags,raw_value);
   } else if (p_window_id == debug_gui_watches_tree()) {
      dbg_get_watch_info(thread_id,frame_id,path,field_name,class_name,signature,value,flags,raw_value);
   } else {
      return INVALID_OBJECT_HANDLE_RC;
   }

   return 0;
}

/**
 * Attempt to go to the declaration of the selected local, member,
 * or watch variable.
 * 
 * @categories Debugger_Commands
 */
_command void debug_goto_variable() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return;
   }

   // we better be in a tree control when this happens
   if (p_object != OI_TREE_VIEW) {
      return;
   }

   // nothing selected?
   index := _TreeCurIndex();
   if (index <= 0) {
      return;
   }

   // get the caption, and name of variable
   caption := debug_get_variable_expr();
   if (caption=="") {
      debug_message("Error: no variable selected");
      return;
   }

   // now go there, if possible
   debug_show_next_statement(true,0,0,"","",0,0);
   child_wid := _MDIGetActiveMDIChild();
   if (child_wid) {
      child_wid.down();
      child_wid.find_tag("-c "caption);
   }
}

/**
 * Attempt to add a watch on the selected local, member,
 * or auto watch variable.
 * 
 * @categories Debugger_Commands
 */
_command void debug_watch_variable() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return;
   }

   // we better be in a tree control when this happens
   if (p_object != OI_TREE_VIEW) {
      return;
   }

   // nothing selected?
   index := _TreeCurIndex();
   if (index <= 0) {
      return;
   }

   // get the caption, and name of variable
   caption := debug_get_variable_expr();
   if (caption=="") {
      debug_message("Error: no variable selected");
      return;
   }

   // now attempt to add the watch
   debug_add_watch(caption);
}

/**
 * Attempt to add a watchpoint on the selected local, member,
 * or auto watch variable.
 * 
 * @categories Debugger_Commands
 */
_command void debug_add_watchpoint_on_variable() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return;
   }

   // we better be in a tree control when this happens
   if (p_object != OI_TREE_VIEW) {
      return;
   }

   // nothing selected?
   index := _TreeCurIndex();
   if (index <= 0) {
      return;
   }

   // get the class and field name for the watch variable
   class_name := "";
   field_name := "";
   debug_get_variable_class_and_name(class_name, field_name);

   // get the caption, and name of variable
   caption := debug_get_variable_expr();
   if (caption=="") {
      debug_message("Error: no variable selected");
      return;
   }

   // now add the watchpoint
   debug_add_watchpoint(caption, class_name, field_name);
}

/**
 * Attempt to go to the declaration of the selected local, member,
 * or watch variable.
 * 
 * @categories Debugger_Commands
 */
_command void debug_show_memory() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return;
   }

   // we better be in a tree control when this happens
   if (p_object != OI_TREE_VIEW) {
      return;
   }

   // nothing selected?
   index := _TreeCurIndex();
   if (index <= 0) {
      return;
   }

   // make sure the memory toolbar is up
   if (!debug_gui_memory_wid()) {
      orig_wid := p_window_id;
      activate_memory();
      p_window_id=orig_wid;
   }

   // get the caption, and name of variable
   caption := debug_get_variable_expr();
   if (caption=="") {
      debug_message("Error: no variable selected");
      return;
   }

   // now set up the memory window
   debug_set_memory_params(caption);
}

/**
 * @return
 *    Return the window ID of the window containing the locals
 *    combo and list of locals
 */
CTL_FORM debug_gui_locals_wid()
{
   static CTL_FORM form_wid;

   if (_iswindow_valid(form_wid) && !form_wid.p_edit &&
       form_wid.p_object==OI_FORM && form_wid.p_name==VSDEBUG_LOCALS_FORM) {
      return(form_wid);
   }

   form_wid=_find_formobj(VSDEBUG_LOCALS_FORM,'N');
   return(form_wid);
}
static CTL_TREE debug_gui_locals_tree()
{
   CTL_FORM wid=debug_gui_locals_wid();
   return (wid? wid.ctl_locals_tree:0);
}
CTL_TREE debug_gui_local_stack_list()
{
   CTL_FORM wid=debug_gui_locals_wid();
   return (wid? wid.ctl_stack_combo:0);
}
void debug_gui_clear_locals()
{
   CTL_FORM form_wid=debug_gui_locals_wid();
   if (!form_wid) {
      return;
   }
   CTL_TREE tree_wid=debug_gui_locals_tree();
   if (tree_wid) {
      tree_wid._TreeDelete(TREE_ROOT_INDEX,'c');
   }
   CTL_COMBO list_wid=debug_gui_local_stack_list();
   if (list_wid) {
      list_wid._lbclear();
      list_wid._cbset_text("");
   }
}
void ctl_stack_combo.on_drop_down(int reason)
{
   // set caption and bitmaps for current context
   gInComboboxDropDown = false;
   if (reason==DROP_INIT) {
      gInComboboxDropDown = true;
      thread_id := dbg_get_cur_thread();
      debug_pkg_update_stack(thread_id);
      _lbclear();
      dbg_update_stack_list(p_window_id, dbg_get_cur_thread());
      frame_id := dbg_get_cur_frame(thread_id);
      if (frame_id > 0) {
         method_name := "";
         signature := "";
         return_type := "";
         class_name := "";
         file_name := "";
         address := "";
         line_number := 0;
         status := dbg_get_frame(thread_id,frame_id,method_name,signature,return_type,class_name,file_name,line_number,address);
         if (!status) {
            _cbset_text(method_name"("signature")");
         }
      }
   } else if (reason==DROP_DOWN) {
      gInComboboxDropDown = true;
   } else if (reason==DROP_UP_SELECTED) {
      thread_id := dbg_get_cur_thread();
      frame_id := p_line;
      debug_gui_switch_frame(thread_id,frame_id);
   }
}
void ctl_stack_combo.on_change(int reason, int index=0)
{
   if (!debug_active()) return;
   if (!debug_is_suspended()) return;
   if (gInUpdateThreadList || gInUpdateThread || gInUpdateFrame) return;
   if (reason == CHANGE_CLINE || reason==CHANGE_CLINE_NOTVIS) {
      if (gInComboboxDropDown) return;
      gInUpdateFrame=true;
      if (index >= 0) p_line=index;
      if (p_line != index) p_text=p_text;
      gInUpdateFrame=false;
      thread_id := dbg_get_cur_thread();
      frame_id := p_line;
      if (thread_id > 0 && thread_id <= dbg_get_num_threads() &&
          frame_id  > 0 && frame_id  <= dbg_get_num_frames(thread_id)) {
         debug_gui_switch_frame(thread_id,frame_id);
         _tbSetRefreshBy(VSTBREFRESHBY_DEBUGGING);
         _tbOnUpdate(true);
         debug_show_next_statement(false,0,0,"","",thread_id,frame_id);
      }
   } else if (reason == CHANGE_OTHER) {
   } else if (reason == CHANGE_SELECTED) {
   }
}
void ctl_stack_combo.on_got_focus()
{
   if ( !(p_active_form.p_window_flags & VSWFLAG_ON_CREATE_ALREADY_CALLED) ) return;
   if ( !(p_active_form.p_window_flags & VSWFLAG_ON_RESIZE_ALREADY_CALLED) ) return;
   if (gInUpdateThread) return;
   if (gInComboboxDropDown) return;
   gInUpdateThread = true;
   orig_text := p_text;
   _lbclear();
   thread_id := dbg_get_cur_thread();
   dbg_update_stack_list(p_window_id,thread_id);
   if (_lbfind_item(orig_text) >= 0) {
      _cbset_text(orig_text);
   }
   gInUpdateThread = false;

   tree_wid := p_next;
   if (tree_wid.p_object == OI_TREE_VIEW && tree_wid.p_user != null && tree_wid.p_user._varformat() == VF_INT && tree_wid.p_user==1) {
      frame_id := dbg_get_cur_frame(thread_id);
      switch (tree_wid.p_name) {
      case "ctl_locals_tree":
         debug_gui_update_locals(thread_id,frame_id);
         break;
      case "ctl_members_tree":
         debug_gui_update_members(thread_id,frame_id);
         break;
      case "ctl_autovars_tree":
         debug_gui_update_autovars(thread_id,frame_id);
         break;
      case "ctl_watches_tree":
      case "ctl_watches_tree1":
         debug_gui_update_watches(thread_id,frame_id,1);
         break;
      case "ctl_watches_tree2":
         debug_gui_update_watches(thread_id,frame_id,2);
         break;
      case "ctl_watches_tree3":
         debug_gui_update_watches(thread_id,frame_id,3);
         break;
      case "ctl_watches_tree4":
         debug_gui_update_watches(thread_id,frame_id,4);
         break;
      }
   }
}


///////////////////////////////////////////////////////////////////////////
// Handlers for debugger members toolbar
//
static const VSDEBUG_MEMBERS_FORM= "_tbdebug_members_form";
defeventtab _tbdebug_members_form;
void _tbdebug_members_form.'C-A'-'C-Z',F2-F4,f6-F12,C_F12,'c-a-a'-'c-a-z','a-0'-'a-9'()
{
   _smart_toolwindow_hotkey();
}
void _tbdebug_members_form.'C-W',A_LEFT,A_RIGHT,A_UP()
{
   if (!_no_child_windows()) {
      p_window_id=_mdi.p_child;
      _set_focus();
   }
}
void _tbdebug_members_form.on_create()
{
   dbg_invalidate_views();

   editable_flag := (isDynamicDebugger() || debug_session_is_implemented("modify_member")==0)? 0:TREE_EDIT_TEXTBOX;
   displayType := debug_session_is_implemented("display_var_types");

   // set up our column widths
   col0Width := 2000;
   col1Width := 0;
   col2Width := 0;
   if (displayType) {
      col0Width = 1500;
      col1Width = 1500;
      col2Width = 0;
   }

   ctl_members_tree._TreeSetColButtonInfo(0,col0Width,TREE_BUTTON_PUSHBUTTON/*|TREE_BUTTON_SORT*/,0,"Name");
   ctl_members_tree._TreeSetColButtonInfo(1,col1Width,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_WRAP|(displayType? 0:TREE_BUTTON_AUTOSIZE),0,"Value");
   ctl_members_tree._TreeSetColEditStyle(1,editable_flag);
   if (displayType) {
      ctl_members_tree._TreeSetColButtonInfo(2,col2Width,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_WRAP|TREE_BUTTON_AUTOSIZE,0,"Type");
   }

   ctl_members_tree.p_user = 0;

   thread_id := dbg_get_cur_thread();
   frame_id := dbg_get_cur_frame(thread_id);
   debug_pkg_enable_disable_tabs();
   debug_gui_update_suspended();
   if (debug_is_suspended()) {
      status := debug_pkg_update_stack(thread_id);
      if (!debug_is_dead_status(status)) {
         status = debug_gui_update_members(thread_id,frame_id);
      }
   }
   dbg_update_stack_list(ctl_stack_combo,thread_id);
   debug_gui_update_cur_frame(thread_id,frame_id);
}
void _tbdebug_members_form.on_destroy()
{
}
void _tbdebug_members_form.on_resize()
{
   _nocheck _control ctl_members_tree;
   _nocheck _control ctl_stack_combo;
   debug_gui_resize_toolbar(0,ctl_members_tree,0,ctl_stack_combo);
   if ( !(p_window_flags & VSWFLAG_ON_RESIZE_ALREADY_CALLED) ) {
      // First time
      ctl_members_tree._TreeRetrieveColButtonInfo();
      ctl_members_tree._TreeAdjustLastColButtonWidth(); 
   }
}
void _twSaveState__tbdebug_members_form(typeless& state, bool closing)
{
   ctl_members_tree._TreeAppendColButtonInfo();
}
void _twRestoreState__tbdebug_members_form(typeless& state, bool opening)
{
   ctl_members_tree._TreeRetrieveColButtonInfo();
}
void _tbdebug_members_form.on_change(int reason)
{ 
   if (reason==CHANGE_AUTO_SHOW ) {
      tree_wid := _find_control("ctl_members_tree");
      if (tree_wid && tree_wid.p_user) {
         thread_id := dbg_get_cur_thread();
         frame_id := dbg_get_cur_frame(thread_id);
         debug_gui_update_members(thread_id,frame_id,true);
      }
   }
}
void _tbdebug_members_form.on_got_focus()
{ 
   tree_wid := _find_control("ctl_members_tree");
   if (tree_wid && tree_wid.p_user) {
      thread_id := dbg_get_cur_thread();
      frame_id := dbg_get_cur_frame(thread_id);
      debug_gui_update_members(thread_id,frame_id);
   }
}
int ctl_members_tree.on_change(int reason,int index)
{
   if (reason==CHANGE_SELECTED) {
   } else if (reason==CHANGE_EXPANDED) {
      if (debug_expand_var_requires_suspend(index) < 0) return 0;
      thread_id := dbg_get_cur_thread();
      frame_id := dbg_get_cur_frame(thread_id);
      member_path := debug_get_variable_path(index);
      status := debug_pkg_expand_member(thread_id,frame_id,member_path);
      if (status) {
         return(0);
      }
      _TreeBeginUpdate(index);
      status=dbg_update_members_tree(p_window_id,index,thread_id,frame_id,member_path);
      _TreeEndUpdate(index);
      _TreeSortUserInfo(index,'N');
      if (status) {
         return(0);
      }
   } else if (reason==CHANGE_COLLAPSED) {
      thread_id := dbg_get_cur_thread();
      frame_id := dbg_get_cur_frame(thread_id);
      member_path := debug_get_variable_path(index);
      //dbg_collapse_member(thread_id,frame_id,member_path);
      //_TreeDelete(index,'C');
      return(-1);

   } else if (reason == CHANGE_LEAF_ENTER) {
      // if this is a value column in a dynamic debugger, then it's time to change the value
      if (getTreeColFromMouse() == 1 && isDynamicDebugger()) {

         if (debug_session_is_implemented("modify_member") && !debug_gui_check_modifiable(index)) {

            session_id := dbg_get_current_session();
            thread_id := dbg_get_cur_thread();
            frame_id := dbg_get_cur_frame(thread_id);
            path := debug_get_variable_path(index);

            sig := value := oldValue := name := class_name := "";
            flags := line_number := is_in_scope := 0;
            dbg_get_member(thread_id, frame_id, path, name, class_name, sig, flags, value, oldValue);

            varName := _TreeGetTextForCol(index, 0);
            newValue := "";
            if (!show_modify_variable_dlg(session_id, thread_id, frame_id, oldValue, varName, newValue)) {
               debug_gui_modify_member(index, thread_id, frame_id, path, newValue);
            }
         }
      }

   } else if (reason == CHANGE_EDIT_OPEN) {
      // now get the vital info
      thread_id := dbg_get_cur_thread();
      frame_id := dbg_get_cur_frame(thread_id);
      member_path := debug_get_variable_path(index);
      sig := name := class_name := value := raw_value := "";
      flags := 0;

      dbg_get_member(thread_id, frame_id, member_path, name, class_name, sig, flags, value, raw_value);

      // set the raw value in the text box, so the user is editing the real thing
      // unless they are editing a string value, then it needs to remain quoted and escaped
      if (first_char(value) != '"' && first_char(value) != "'") {
         arg(4) = raw_value;
      }

      return 0;

   } else if (reason == CHANGE_EDIT_QUERY) {
      // The debugger might have changed its mind, so check
      // each time. This is specifically useful for PHP,
      // Python, and Perl debuggers that do not know if they
      // support modifying variables until the session is
      // started.
      if( !debug_session_is_implemented("modify_member") ) {
         return(-1);
      }
      return debug_gui_check_modifiable(index);
   } else if (reason == CHANGE_EDIT_CLOSE) {
      if (arg(4)=="") {
         return(DELETED_ELEMENT_RC);
      }

      // we will need this information to reload the tree
      thread_id := dbg_get_cur_thread();
      frame_id := dbg_get_cur_frame(thread_id);
      path := debug_get_variable_path(index);
      status := debug_gui_modify_member(index, thread_id, frame_id, path, arg(4));
      if (status == -1) {
         arg(4) = _TreeGetTextForCol(index, 1);
      }

      return status;
   }

   return(0);
}

static int debug_gui_modify_member(int index, int thread_id, int frame_id, _str path, _str newValue)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // we don't want to bother with this
   if (newValue=="") return(DELETED_ELEMENT_RC);

   status := debug_pkg_modify_member(thread_id,frame_id,path,newValue);

   // uh-oh, something is bad
   if (status) {
      debug_message("Could not modify member",status);
      return(-1);
   }

   parent_index := _TreeGetParentIndex(index);
   path=debug_get_variable_path(parent_index);
   _TreeBeginUpdate(parent_index);
   status=dbg_update_members_tree(p_window_id,parent_index,
                                  thread_id,frame_id,path);
   _TreeEndUpdate(parent_index);
   _TreeSortUserInfo(parent_index,'N');
   if (status) {
      debug_message("Error",status);
   }
   debug_gui_update_all_vars();
   return(DELETED_ELEMENT_RC);
}

// Handle right-button released event, in order to display pop-up menu
// for the threads tree.
//
void ctl_members_tree.rbutton_up()
{
   // get the menu form
   index := find_index("_debug_variables_menu",oi2type(OI_MENU));
   if (!index) {
      return;
   }
   menu_handle := p_active_form._menu_load(index,'P');
   tree_wid := p_window_id;

   cur_index := tree_wid._TreeCurIndex();
   if (cur_index <= 0) {
      return;
   }

   thread_id := dbg_get_cur_thread();
   frame_id := dbg_get_cur_frame(thread_id);
   if (cur_index <= 0 || dbg_get_num_members(thread_id,frame_id) <= 0) {
      _menu_set_state(menu_handle, "goto",   MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "watch",  MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "watchpoint", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "memory", MF_GRAYED, 'C');
   }
   if (!debug_is_suspended()) {
      _menu_set_state(menu_handle, "watch",  MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "memory", MF_GRAYED, 'C');
   }

   int output_menu_handle,output_menu_pos;
   if (!_menu_find(menu_handle,"scan",output_menu_handle,output_menu_pos)) {
      _menu_delete(menu_handle,output_menu_pos);
   }
   if (!_menu_find(menu_handle,"delete",output_menu_handle,output_menu_pos)) {
      _menu_delete(menu_handle,output_menu_pos);
   }
   if (!_menu_find(menu_handle,"clearall",output_menu_handle,output_menu_pos)) {
      _menu_delete(menu_handle,output_menu_pos);
   }

   AddOrRemoveBasesFromMenu(menu_handle);

   // Show the menu.
   x := mou_last_x('M')-100;
   y := mou_last_y('M')-100;
   _lxy2dxy(p_scale_mode,x,y);
   _map_xy(p_window_id,0,x,y,SM_PIXEL);
   _KillToolButtonTimer();
   _menu_show(menu_handle,VPM_LEFTALIGN|VPM_RIGHTBUTTON,x,y);
   _menu_destroy(menu_handle);
}

/**
 * @return
 *    Return the window ID of the window containing the members
 *    combo and list of member variables.
 */
CTL_FORM debug_gui_members_wid()
{
   static CTL_FORM form_wid;

   if (_iswindow_valid(form_wid) && !form_wid.p_edit &&
       form_wid.p_object==OI_FORM && form_wid.p_name==VSDEBUG_MEMBERS_FORM) {
      return(form_wid);
   }

   form_wid=_find_formobj(VSDEBUG_MEMBERS_FORM,'N');
   return(form_wid);
}
static CTL_TREE debug_gui_members_tree()
{
   CTL_FORM wid=debug_gui_members_wid();
   return (wid? wid.ctl_members_tree:0);
}
CTL_TREE debug_gui_members_stack_list()
{
   CTL_FORM wid=debug_gui_members_wid();
   return (wid? wid.ctl_stack_combo:0);
}
void debug_gui_clear_members()
{
   CTL_TREE tree_wid=debug_gui_members_tree();
   if (tree_wid) {
      tree_wid._TreeDelete(TREE_ROOT_INDEX,'c');
   }

   CTL_COMBO list_wid=debug_gui_members_stack_list();
   if (list_wid) {
      list_wid._lbclear();
      list_wid._cbset_text("");
   }
}


///////////////////////////////////////////////////////////////////////////
// Handlers for debugger watches toolbar
//
static const VSDEBUG_WATCHES_FORM= "_tbdebug_watches_form";
defeventtab _tbdebug_watches_form;
void _tbdebug_watches_form.'C-A'-'C-Z',F2-F4,f6-F12,C_F12,'c-a-a'-'c-a-z','a-0'-'a-9'()
{
   _smart_toolwindow_hotkey();
}
void _tbdebug_watches_form.'C-W',A_LEFT,A_RIGHT,A_UP()
{
   if (!_no_child_windows()) {
      p_window_id=_mdi.p_child;
      _set_focus();
   }
}

CTL_SSTAB debug_gui_watches_tab()
{
   _nocheck _control ctl_watches_sstab;
   return ctl_watches_sstab;
}

void _tbdebug_watches_form.on_create()
{
   dbg_invalidate_views();

   displayType := debug_session_is_implemented("display_var_types");

   // set up our column widths
   col0Width := 1500;
   col1Width := 1500;
   col2Width := 0;
   col3Width := 0;
   if (displayType) {
      col0Width = 1000;
      col1Width = 1500;
      col2Width = 1000;
      col3Width = 0;
   }

   editable_flag := (isDynamicDebugger() || debug_session_is_implemented("modify_watch")==0)? 0:TREE_EDIT_TEXTBOX;
   for (i:=1; i<=4; ++i) {
      tree_wid := _find_control("ctl_watches_tree":+i);
      if (tree_wid) {
         tree_wid._TreeSetColButtonInfo(0,col0Width,TREE_BUTTON_PUSHBUTTON,0,"Name");
         tree_wid._TreeSetColEditStyle(0,TREE_EDIT_TEXTBOX);
         tree_wid._TreeSetColButtonInfo(1,col1Width,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_WRAP,0,"Value");
         tree_wid._TreeSetColEditStyle(1,editable_flag);
         tree_wid._TreeSetColButtonInfo(2,col2Width,TREE_BUTTON_PUSHBUTTON|(displayType? 0:TREE_BUTTON_AUTOSIZE),0,"Frame");
         if (displayType) {
            tree_wid._TreeSetColButtonInfo(3,col3Width,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_WRAP|TREE_BUTTON_AUTOSIZE,0,"Type");
         }
      }
   }

   ctl_watches_sstab._retrieve_value();
   ctl_watches_tree1.p_user=0;
   ctl_watches_tree2.p_user=0;
   ctl_watches_tree3.p_user=0;
   ctl_watches_tree4.p_user=0;

   debug_pkg_enable_disable_tabs();
   debug_gui_update_suspended();
   tree_wid := _find_control("ctl_watches_tree":+ctl_watches_sstab.p_ActiveTab+1);
   if (tree_wid) {
      thread_id := dbg_get_cur_thread();
      frame_id := dbg_get_cur_frame(thread_id);
      tab_number := debug_gui_active_watches_tab();
      debug_gui_update_watches(thread_id,frame_id,tab_number);
   }
}
void _tbdebug_watches_form.on_destroy()
{
   _append_retrieve(ctl_watches_sstab.p_window_id, ctl_watches_sstab.p_ActiveTab);
   _twSaveState__tbdebug_watches_form(auto state, false);
}
void _twSaveState__tbdebug_watches_form(typeless& state, bool closing)
{
   tree_wid := _find_control("ctl_watches_tree":+ctl_watches_sstab.p_ActiveTab+1);
   if (tree_wid) {
      tree_wid._TreeAppendColButtonInfo(false,"ctl_watches_tree");
   }
}
void _twRestoreState__tbdebug_watches_form(typeless& state, bool opening)
{
   ctl_watches_tree1._TreeRetrieveColButtonInfo(false,"ctl_watches_tree");
   ctl_watches_tree2._TreeRetrieveColButtonInfo(false,"ctl_watches_tree");
   ctl_watches_tree3._TreeRetrieveColButtonInfo(false,"ctl_watches_tree");
   ctl_watches_tree4._TreeRetrieveColButtonInfo(false,"ctl_watches_tree");
}
void _tbdebug_watches_form.on_resize()
{
   for (i:=1; i<=4; ++i) {
      tree_wid := _find_control("ctl_watches_tree":+i);
      if (tree_wid) {
         debug_gui_resize_toolbar(ctl_watches_sstab,tree_wid);
      }
      if ( !(p_window_flags & VSWFLAG_ON_RESIZE_ALREADY_CALLED) ) {
         // First time
         tree_wid._TreeRetrieveColButtonInfo(false,"ctl_watches_tree");
         tree_wid._TreeAdjustLastColButtonWidth(); 
      }
   }
}
void _tbdebug_watches_form.on_change(int reason)
{ 
   if (reason==CHANGE_AUTO_SHOW ) {
      tree_wid := debug_gui_watches_tree();
      if (tree_wid && tree_wid.p_user) {
         thread_id := dbg_get_cur_thread();
         frame_id := dbg_get_cur_frame(thread_id);
         dbg_clear_watch_variables();
         debug_gui_update_watches(thread_id,frame_id,ctl_watches_sstab.p_ActiveTab+1,false,true);
      }
   }
}
void _tbdebug_watches_form.on_got_focus()
{ 
   tree_wid := debug_gui_watches_tree();
   if ( tree_wid && tree_wid.p_user ) {
      thread_id := dbg_get_cur_thread();
      frame_id := dbg_get_cur_frame(thread_id);
      debug_gui_update_watches(thread_id,frame_id,ctl_watches_sstab.p_ActiveTab+1);
   }
}

void ctl_watches_sstab.on_change(int reason)
{
   ignore_on_change := _GetDialogInfoHt("IGNORE_ON_CHANGE", p_window_id);
   if (ignore_on_change != null && ignore_on_change) return;

   if (reason==CHANGE_TABDEACTIVATED) {
      tree_wid := _find_control("ctl_watches_tree":+p_ActiveTab+1);
      if (tree_wid) {
         // get the column sizes for this tree
         int colSizes[];
         numCols := tree_wid._TreeGetNumColButtons();
         for (i := 0; i < numCols; i++) {
            colSizes[i] = tree_wid._TreeColWidth(i);
         }

         // now go through and set these sizes for the other trees
         ctl_watches_tree1.setColumnWidths(colSizes);
         ctl_watches_tree2.setColumnWidths(colSizes);
         ctl_watches_tree3.setColumnWidths(colSizes);
         ctl_watches_tree4.setColumnWidths(colSizes);
      }
   } else if (reason==CHANGE_TABACTIVATED) {
      tree_wid := _find_control("ctl_watches_tree":+p_ActiveTab+1);
      if (tree_wid) {
         thread_id := dbg_get_cur_thread();
         frame_id := dbg_get_cur_frame(thread_id);
         dbg_clear_watch_variables();
         debug_gui_update_watches(thread_id,frame_id,p_ActiveTab+1);
      }
   }
}

static void setColumnWidths(int (&colSizes)[])
{
   for (i := 0; i < colSizes._length(); i++) {
      _TreeColWidth(i, colSizes[i]);
   }
}

/**
 * @return
 *    Return the window ID of the window containing the watches
 * combo and list of watches.
 */
CTL_FORM debug_gui_watches_wid()
{
   static CTL_FORM form_wid;

   if (_iswindow_valid(form_wid) && !form_wid.p_edit &&
       form_wid.p_object==OI_FORM && form_wid.p_name==VSDEBUG_WATCHES_FORM) {
      return(form_wid);
   }
   form_wid=_find_formobj(VSDEBUG_WATCHES_FORM,'N');
   return(form_wid);
}
CTL_TREE debug_gui_active_watches_tab()
{
   wid := debug_gui_watches_wid();
   return (wid? wid.ctl_watches_sstab.p_ActiveTab+1:1);
}
static CTL_TREE debug_gui_watches_tree()
{
   wid := debug_gui_watches_wid();
   if (wid) {
      return wid._find_control("ctl_watches_tree":+wid.ctl_watches_sstab.p_ActiveTab+1);
   }
   return(0);
}
void debug_gui_clear_watches()
{
   form_wid := debug_gui_watches_wid();
   if (form_wid) {
      for (i:=1; i<=4; ++i) {
         CTL_TREE tree_wid = form_wid._find_control("ctl_watches_tree":+i);
         if (tree_wid) {
            tree_wid._TreeDelete(TREE_ROOT_INDEX,'c');
         }
      }
   }
}
int ctl_watches_tree1.on_change(int reason,int index,int col=-1)
{
   if (reason==CHANGE_SELECTED) {
   } else if (reason==CHANGE_EXPANDED) {
      if (debug_expand_var_requires_suspend(index) < 0) return 0;
      thread_id := dbg_get_cur_thread();
      frame_id := dbg_get_cur_frame(thread_id);
      watch_path := debug_get_variable_path(index);
      tab_number := debug_gui_active_watches_tab();
      status := debug_pkg_expand_watch(thread_id,frame_id,watch_path);
      if (status) {
         return(status);
      }
      _TreeBeginUpdate(index);
      status=dbg_update_watches_tree(p_window_id,index,thread_id,frame_id,tab_number,watch_path);
      _TreeEndUpdate(index);
      _TreeSortUserInfo(index,'N');
      if (status) {
         return(status);
      }
   } else if (reason==CHANGE_COLLAPSED) {
      thread_id := dbg_get_cur_thread();
      frame_id := dbg_get_cur_frame(thread_id);
      watch_path := debug_get_variable_path(index);
      //dbg_collapse_watch(thread_id,frame_id,watch_path);
      //_TreeDelete(index,'C');
      return(-1);
   } else if (reason == CHANGE_LEAF_ENTER) {

      // if this is a value column in a dynamic debugger, then it's time to change the value
      if (getTreeColFromMouse() == 1 && isDynamicDebugger()) {

         if (debug_session_is_implemented("modify_watch") && !debug_gui_check_modifiable(index)) {

            session_id := dbg_get_current_session();
            thread_id := dbg_get_cur_thread();
            frame_id := dbg_get_cur_frame(thread_id);
            path := debug_get_variable_path(index);

            sig := value := oldValue := name := class_name := "";
            flags := line_number := is_in_scope := 0;
            dbg_get_watch_info(thread_id,frame_id,path,name,class_name,sig,value,flags,oldValue);

            varName := _TreeGetTextForCol(index, 0);
            newValue := "";

            if (!show_modify_variable_dlg(session_id, thread_id, frame_id, oldValue, varName, newValue)) {
               debug_gui_modify_watch(index, thread_id, frame_id, path, newValue);
            }
         }
      }
   } else if (reason == CHANGE_EDIT_OPEN && col==1) {

      thread_id := dbg_get_cur_thread();
      frame_id := dbg_get_cur_frame(thread_id);
      watch_path := debug_get_variable_path(index);

      _str name, class_name, signature, value, raw_value = "";
      flags := 0;
      dbg_get_watch_info(thread_id,frame_id,watch_path,name,class_name,signature,value,flags,raw_value);

      // set the raw value in the text box, so the user is editing the real thing
      // unless they are editing a string value, then it needs to remain quoted and escaped
      if (first_char(value) != '"' && first_char(value) != "'") {
         arg(4) = raw_value;
      }

      return 0;
   } else if (reason == CHANGE_EDIT_QUERY && col==1) {
      if( !debug_session_is_implemented("modify_watch") ) {
         return(-1);
      }
      return debug_gui_check_modifiable(index);
   } else if (reason == CHANGE_EDIT_CLOSE && col==1) {
      if (arg(4)=="") {
         return(DELETED_ELEMENT_RC);
      }

      // we will need this information to reload the tree
      thread_id := dbg_get_cur_thread();
      frame_id := dbg_get_cur_frame(thread_id);
      path := debug_get_variable_path(index);

      status := debug_gui_modify_watch(index, thread_id, frame_id, path, arg(4));
      if (status == -1) {
         arg(4) = _TreeGetTextForCol(index, 1);
      }

      return status;
   } else if (reason == CHANGE_EDIT_QUERY && col==0) {
      parent_index := _TreeGetParentIndex(index);
      if (parent_index==TREE_ROOT_INDEX) {
         return(0);
      }
      return(-1);

   } else if (reason == CHANGE_EDIT_OPEN && col==0) {
      // if this is the new entry node, clear the message
      if(strieq(arg(4), DEBUG_ADD_WATCH_CAPTION)) {
         arg(4) = "";
      }
   } else if (reason == CHANGE_EDIT_CLOSE && col==0) {
      // check the old caption to see if it is the new entry node
      wasNewEntryNode := strieq(_TreeGetCaption(index), DEBUG_ADD_WATCH_CAPTION);

      // if the node changed and is now empty, delete it
      if(arg(4) == "") {
         if(wasNewEntryNode) {
            arg(4) = DEBUG_ADD_WATCH_CAPTION;
            return 0;
         } else {
            watch_id := _TreeGetUserInfo(index);
            dbg_remove_watch(watch_id);
            _TreeDelete(index);
            return DELETED_ELEMENT_RC;
         }
      }

      // we'll need these later
      status := 0;
      thread_id := dbg_get_cur_thread();
      frame_id := dbg_get_cur_frame(thread_id);
      tab_number := debug_gui_active_watches_tab();

      // make sure the last node in the tree is the new entry node
      if(wasNewEntryNode) {
         // add the watch to the system
         status=dbg_add_watch(tab_number,arg(4),"",VSDEBUG_BASE_DEFAULT);
         if (status<0) {
            debug_message("Could not add watch",status);
            return(0);
         }

         // unbold the existing node
         _TreeSetInfo(index, -1, -1, -1, 0);
         _TreeSetUserInfo(index,status);

         // replace the new entry node
         add_index := _TreeAddItem(TREE_ROOT_INDEX,DEBUG_ADD_WATCH_CAPTION,TREE_ADD_AS_CHILD,0,0,-1,TREENODE_BOLD,-1);
      } else {
         watch_id := _TreeGetUserInfo(index);
         expandable :=0;
         base := VSDEBUG_BASE_DEFAULT;
         _str expr,context_name,value, raw_value, type = "";
         status=dbg_get_watch(thread_id,frame_id,watch_id,tab_number,expr,context_name,value,expandable,base,raw_value,type);
         if (status) {
            debug_message("Error querying watch",status);
            return(0);
         }
         status=dbg_set_watch(watch_id,arg(4),context_name,base);
         if (status) {
            debug_message("Error modifying watch",status);
            return(0);
         }
         _TreeDelete(index,'C');
         dbg_collapse_watch(thread_id,frame_id,watch_id);
      }

      debug_gui_update_watches(thread_id,frame_id,tab_number,true);

   }

   return(0);
}

static int debug_gui_modify_watch(int index, int thread_id, int frame_id, _str path, _str newValue)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (newValue=="") return(DELETED_ELEMENT_RC);

   status := debug_pkg_modify_watch(thread_id,frame_id,path,newValue);

   if (status) {
      debug_message("Could not modify variable", status);
      return -1;
   }

   parent_index := _TreeGetParentIndex(index);
   path = debug_get_variable_path(parent_index);
   tab_number := debug_gui_active_watches_tab();
   _TreeBeginUpdate(parent_index);     
   status=dbg_update_watches_tree(p_window_id,parent_index,
                                  thread_id,frame_id,tab_number,path);
   _TreeEndUpdate(parent_index);
   _TreeSortUserInfo(parent_index,'N');
   if (status) {
      debug_message("Error",status);
   }
   debug_gui_update_all_vars();
   return(DELETED_ELEMENT_RC);
}

// Handle right-button released event, in order to display pop-up menu
// for the threads tree.
//
void ctl_watches_tree1.rbutton_up()
{
   // get the menu form
   index := find_index("_debug_variables_menu",oi2type(OI_MENU));
   if (!index) {
      return;
   }
   menu_handle := p_active_form._menu_load(index,'P');
   tree_wid := p_window_id;

   cur_index := tree_wid._TreeCurIndex();
   if (cur_index <= 0 || strieq(_TreeGetCaption(cur_index), DEBUG_ADD_WATCH_CAPTION)) {
      _menu_set_state(menu_handle, "goto",   MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "delete", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "memory", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "watchpoint", MF_GRAYED, 'C');
   }
   if (!debug_is_suspended()) {
      _menu_set_state(menu_handle, "watch",  MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "memory", MF_GRAYED, 'C');
   }
   if (dbg_get_num_watches()==0) {
      _menu_set_state(menu_handle, "delete",   MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "clearall", MF_GRAYED, 'C');
   }

   // get the caption, and name of variable
   if (cur_index > 0) {
      caption := tree_wid._TreeGetCaption(cur_index);
      parse caption with caption "\t" . ;
      if (!pos("^:v$",caption,1,'r') && substr(caption,1,1)!="[") {
         _menu_set_state(menu_handle,"goto",MF_GRAYED,'C');
      }
   }
   int output_menu_handle,output_menu_pos;
   if (!_menu_find(menu_handle,"scan",output_menu_handle,output_menu_pos)) {
      _menu_delete(menu_handle,output_menu_pos);
   }
   if (!_menu_find(menu_handle,"watch",output_menu_handle,output_menu_pos)) {
      _menu_delete(menu_handle,output_menu_pos);
   }

   AddOrRemoveBasesFromMenu(menu_handle);

   // Show the menu.
   x := mou_last_x('M')-100;
   y := mou_last_y('M')-100;
   _lxy2dxy(p_scale_mode,x,y);
   _map_xy(p_window_id,0,x,y,SM_PIXEL);
   _KillToolButtonTimer();
   _menu_show(menu_handle,VPM_LEFTALIGN|VPM_RIGHTBUTTON,x,y);
   _menu_destroy(menu_handle);
}
static void debug_gui_remove_watch()
{
   // with single node selection, if there is a current index, it is selected
   if (!_haveDebugging()) return;
   index := _TreeCurIndex();
   if(index > 0) {
      // cannot delete new entry node
      if(strieq(_TreeGetCaption(index), DEBUG_ADD_WATCH_CAPTION)) {
         return;
      }
      user_info := _TreeGetUserInfo(index);
      if (user_info < 0) {
         return;
      }
      status := dbg_remove_watch(user_info);
      if (status) {
         debug_message("Could not remove watch",status);
         return;
      }
      _TreeDelete(index);
      // update the watches (watch indexes may have changed)
      thread_id := dbg_get_cur_thread();
      frame_id := dbg_get_cur_frame(thread_id);
      tab_number := debug_gui_active_watches_tab();
      debug_gui_update_watches(thread_id,frame_id,tab_number);
   }
}
void ctl_watches_tree1.'DEL'()
{
   debug_gui_remove_watch();
}
/**
 * Attempt to go to the declaration of the selected local, member,
 * or watch variable.
 * 
 * @categories Debugger_Commands
 */
_command void debug_remove_watch() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return;
   }

   debug_gui_remove_watch();
}
/**
 * Remove all watches from this watch tab.
 * 
 * @categories Debugger_Commands
 */
_command int debug_clear_watches() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   thread_id := dbg_get_cur_thread();
   frame_id := dbg_get_cur_frame(thread_id);
   tab_number := debug_gui_active_watches_tab();

   // first ask them
   if (dbg_get_num_watches() > 0) {
      result := _message_box("Are you sure you want to clear all watches on this tab?","",MB_YESNOCANCEL);
      if (result!=IDYES) {
         return(COMMAND_CANCELLED_RC);
      }
   }

   // find the watches on active tab
   i := 1;
   n := dbg_get_num_watches();
   while (i <= n) {
      watch_tab := 0;
      _str de,dc,dv,rv,type = "";
      int expandable,base;
      dbg_get_watch(thread_id,frame_id,i,watch_tab,de,dc,dv,expandable,base,rv,type);
      if (tab_number==watch_tab) {
         dbg_remove_watch(i);
         --n;
      } else {
         ++i;
      }
   }

   debug_gui_update_watches(thread_id,frame_id,tab_number);
   return(0);
}


///////////////////////////////////////////////////////////////////////////
// Callbacks for breakpoint property editor
//
defeventtab _debug_breakpoint_form;
void _debug_breakpoint_form.ENTER()
{
   ctl_ok.call_event(_control ctl_ok,LBUTTON_UP);
}
void ctl_breakpoint_tab.on_change(int reason)
{
   visited_mask := _GetDialogInfoHt("visited", ctl_breakpoint_tab);
   if (visited_mask == null) visited_mask = 0;
   visited_mask |= (1 << p_ActiveTab);
   _SetDialogInfoHt("visited", visited_mask, ctl_breakpoint_tab);
   isWatchpoint := (p_ActiveTab == 3);
   breakpoint_type := _GetDialogInfoHt("type", ctl_breakpoint_tab);
   if (breakpoint_type == null) breakpoint_type = 0;
   switch (breakpoint_type) {
   case VSDEBUG_WATCHPOINT_READ:
   case VSDEBUG_WATCHPOINT_WRITE:
   case VSDEBUG_WATCHPOINT_ANY:
      isWatchpoint=true;
      break;
   }

   ctl_expr_label.p_enabled = !isWatchpoint;
   ctl_expr.p_enabled = !isWatchpoint;
   ctl_skips_label.p_enabled = !isWatchpoint;
   ctl_skips.p_enabled = !isWatchpoint;
   //ctl_thread_combo.p_enabled = !isWatchpoint;
   //ctl_thread_label.p_enabled = !isWatchpoint;
}
void ctl_ok.lbutton_up()
{
   // check which tabs have been visited
   // don't validate input coming from nodes
   // we didn't even visit
   visited_mask := _GetDialogInfoHt("visited", ctl_breakpoint_tab);
   if (visited_mask == null) visited_mask = 0;
   visited_func := false;
   visited_file := false;
   visited_addr := false;
   visited_data := false;
   if (isinteger(visited_mask)) {
      visited_func = (visited_mask & 0x1);
      visited_file = (visited_mask & 0x2);
      visited_addr = (visited_mask & 0x4);
      visited_data = (visited_mask & 0x8);
   }

   // validate the skips value
   count := 0;
   if (ctl_skips.p_text!="" && (!isinteger(ctl_skips.p_text) || (int)ctl_skips.p_text < 0)) {
      debug_message("Expecting a positive integer value!");
      ctl_skips._set_focus();
      return;
   } else if (ctl_skips.p_text!="") {
      count=(int)ctl_skips.p_text;
   } else {
      count=0;
   }

   // validate the conditional expression
   condition := ctl_expr.p_text;
   if (ctl_breakpoint_tab.p_ActiveTab == 3 /*address*/) {
      condition = ctl_variable.p_text;
   }

   // get the thread name
   thread_name := ctl_thread_combo.p_text;
   if (thread_name=="(any thread)") {
      thread_name="";
   }

   // get the class name
   // this is where we would handle class exclude patterns
   class_name := ctl_class.p_text;

   // extract the class and method name (dot is trouble...)
   method_name := ctl_function.p_text;

   // get the file name
   file_name := "";
   if (visited_file) {
      file_name = ctl_file.p_text;
      if (file_name != "") {
         if (!file_exists(file_name)) {
            file_name=absolute(file_name,_strip_filename(_project_name,'N'));
         } else {
            file_name=absolute(file_name);
         }
         if (!file_exists(file_name)) {
            debug_message("Specified file does not exist!");
            ctl_file._set_focus();
            return;
         }
      }
   }

   // validate the line number
   line_number := 0;
   if (visited_file) {
      if (!isinteger(ctl_line.p_text) || (int)ctl_line.p_text < 0) {
         if (ctl_breakpoint_tab.p_ActiveTab==1 /*line*/) {
            debug_message("Expecting a positive integer value!");
            ctl_line._set_focus();
            return;
         }
      } else {
         line_number=(int)ctl_line.p_text;
      }
   }

   // validate the address
   address := "";
   if (visited_addr) {
      if (ctl_address.p_enabled && ctl_address.p_text != "" &&
          !pos('^0x:h$',ctl_address.p_text,1,'r')) {
         debug_message("Expecting a hexadecimal integer address!");
         ctl_address._set_focus();
         return;
      } else {
         address = ctl_address.p_text;
      }
   }

   // check the breakpoint ID
   status := 0;
   breakpoint_id := _GetDialogInfoHt("id", ctl_breakpoint_tab);
   if (breakpoint_id == null) breakpoint_id = 0;
   if (breakpoint_id > 0) {
      // disable the breakpoint
      /*status=*/debug_pkg_disable_breakpoint(breakpoint_id);
      if (status) {
         debug_message("Error disabling breakpoint",status);
         return;
      }
   
      // delete the breakpoint
      status=dbg_remove_breakpoint(breakpoint_id);
      if (status) {
         debug_message("Error removing breakpoint",status);
         return;
      }
   }

   // determine the breakpoint type
   breakpoint_type := _GetDialogInfoHt("type", ctl_breakpoint_tab);
   if (breakpoint_type == null) breakpoint_type = 0;
   breakpoint_flags := 0;
   switch (ctl_breakpoint_tab.p_ActiveTab) {
   case 0:
      if (breakpoint_id <= 0) breakpoint_type = VSDEBUG_BREAKPOINT_METHOD;
      break;
   case 1:
      if (breakpoint_id <= 0) breakpoint_type = VSDEBUG_BREAKPOINT_LINE;
      break;
   case 2:
      if (breakpoint_id <= 0) breakpoint_type = VSDEBUG_BREAKPOINT_ADDRESS;
      break;
   case 3:
      if (ctl_watch_write.p_value) {
         breakpoint_type = VSDEBUG_WATCHPOINT_WRITE;
      } else if (ctl_watch_read.p_value) {
         breakpoint_type = VSDEBUG_WATCHPOINT_READ;
      } else {
         breakpoint_type = VSDEBUG_WATCHPOINT_ANY;
      }
      if (ctl_watch_instance.p_value) {
         breakpoint_flags |= VSDEBUG_WATCHPOINT_INSTANCE;
      }
      if (ctl_watch_activate.p_value) {
         breakpoint_flags |= VSDEBUG_WATCHPOINT_STOP_ACTIVATE;
      }
      if (ctl_variable_size.p_visible) {
         address = ctl_variable_size.p_text;
      }
      break;
   }

   // make sure the essentials are there
   switch (breakpoint_type) {
   case VSDEBUG_BREAKPOINT_METHOD:
      if (method_name == "") {
         debug_message("You must enter a function name!");
         ctl_function._set_focus();
         return;
      }
      break;
   case VSDEBUG_BREAKPOINT_LINE:
      if (file_name == "") {
         debug_message("You must enter a file name!");
         ctl_file._set_focus();
         return;
      }
      if (line_number == "") {
         debug_message("You must enter a line number!");
         ctl_file._set_focus();
         return;
      }
      break;
   case VSDEBUG_BREAKPOINT_ADDRESS:
      if (address == "") {
         debug_message("Expecting a hexadecimal integer address!");
         ctl_address._set_focus();
         return;
      }
      break;
   case VSDEBUG_WATCHPOINT_READ:
   case VSDEBUG_WATCHPOINT_WRITE:
   case VSDEBUG_WATCHPOINT_ANY:
      if (condition == "") {
         debug_message("Expecting a variable name or expression");
         ctl_variable._set_focus();
         return;
      }
      if (ctl_variable_size.p_visible && address == "") {
         debug_message("Expecting a number or expression");
         ctl_variable_size._set_focus();
         return;
      }
      break;
   }

   // now add it with the right stuff
   breakpoint_id=dbg_add_breakpoint(count,condition,thread_name,
                                    class_name,method_name,
                                    file_name,line_number,address,
                                    breakpoint_type, breakpoint_flags);
   if (breakpoint_id < 0) {
      debug_message("Error adding breakpoint",breakpoint_id);
      return;
   }

   // now enable the breakpoint (if it was enabled before)
   _save_form_response();
   if (breakpoint_id > 0) {
      status=debug_pkg_enable_breakpoint(breakpoint_id);
      if (status) {
         debug_message("Error enabling breakpoint",status);
         return;
      }
   }

   // that's all folks
   p_active_form._delete_window(breakpoint_id);
}
int ctl_ok.on_create(int breakpoint_id, int editorctl_wid)
{
   // inspect the breakpoint
   count := 0;
   condition := "";
   thread_name := "";
   class_name := "";
   method_name := "";
   file_name := "";
   line_number := 0;
   address := "";
   enabled := false;
   isWatchpoint := false;
   status := 0;
   breakpoint_type := VSDEBUG_BREAKPOINT_LINE;
   breakpoint_flags := 0;
   if (breakpoint_id != 0) {
      status = dbg_get_breakpoint(breakpoint_id,
                                  count,condition,thread_name,
                                  class_name,method_name,
                                  file_name,line_number,enabled,address);
      if (status) {
         debug_message("Error",status);
      }

      // get the type of the breakpoint and lock into it's mode
      breakpoint_type = dbg_get_breakpoint_type(breakpoint_id, breakpoint_flags);
      _SetDialogInfoHt("type", breakpoint_type, ctl_breakpoint_tab);
      switch (breakpoint_type) {
      case VSDEBUG_BREAKPOINT_METHOD:
         ctl_breakpoint_tab.p_ActiveTab = 3;
         ctl_breakpoint_tab.p_ActiveEnabled = false;
         ctl_breakpoint_tab.p_ActiveTab = 0;
         ctl_breakpoint_tab.p_ActiveEnabled = true;
         break;
      case VSDEBUG_BREAKPOINT_LINE:
         ctl_breakpoint_tab.p_ActiveTab = 3;
         ctl_breakpoint_tab.p_ActiveEnabled = false;
         ctl_breakpoint_tab.p_ActiveTab = 1;
         ctl_breakpoint_tab.p_ActiveEnabled = true;
         break;
      case VSDEBUG_BREAKPOINT_ADDRESS:
         ctl_breakpoint_tab.p_ActiveTab = 3;
         ctl_breakpoint_tab.p_ActiveEnabled = false;
         ctl_breakpoint_tab.p_ActiveTab = 2;
         ctl_breakpoint_tab.p_ActiveEnabled = true;
         break;
      case VSDEBUG_WATCHPOINT_READ:
      case VSDEBUG_WATCHPOINT_WRITE:
      case VSDEBUG_WATCHPOINT_ANY:
         isWatchpoint=true;
         ctl_breakpoint_tab.p_ActiveTab = 0;
         ctl_breakpoint_tab.p_ActiveEnabled = false;
         //ctl_breakpoint_tab.p_ActiveTab = 1;
         //ctl_breakpoint_tab.p_ActiveEnabled = false;
         ctl_breakpoint_tab.p_ActiveTab = 2;
         ctl_breakpoint_tab.p_ActiveEnabled = false;
         ctl_breakpoint_tab.p_ActiveTab = 3;
         ctl_breakpoint_tab.p_ActiveEnabled = true;
         p_active_form.p_caption="Watchpoint properties";
         break;
      }
      switch (breakpoint_type) {
      case VSDEBUG_WATCHPOINT_READ:             ctl_watch_read.p_value=1;  break;
      case VSDEBUG_WATCHPOINT_WRITE:            ctl_watch_write.p_value=1; break;
      case VSDEBUG_WATCHPOINT_ANY:              ctl_watch_any.p_value=1;   break;
      }

   } else {
      ctl_watch_write.p_value=1;
      enabled=true;

      if (editorctl_wid && editorctl_wid._isEditorCtl()) {
         // seed the file name and line number
         file_name   = editorctl_wid.p_buf_name;
         line_number = editorctl_wid.p_RLine;

         // probe for whether we can set a breakpoint here or not
         _str cur_tag_name;
         _str cur_context;
         _str cur_type_name;
         status=editorctl_wid.debug_get_current_context(cur_context,cur_tag_name,cur_type_name);
         if (status > 0) {
            // seed the class and method
            debug_translate_class_name(cur_context);
            class_name = cur_context;
            method_name = cur_tag_name;
         }

         // set up the address field
         address = editorctl_wid.debug_get_disassembly_address();
         if (address == null) address = "";

         // set up expression for watchpoint
         ctl_variable.p_text = editorctl_wid.debug_get_expression_under_cursor();
      }
   }

   // breakpoint flags
   ctl_watch_instance.p_value = (breakpoint_flags & VSDEBUG_WATCHPOINT_INSTANCE)? 1:0;
   ctl_watch_activate.p_value = (breakpoint_flags & VSDEBUG_WATCHPOINT_STOP_ACTIVATE)? 1:0;

   if (isWatchpoint || ctl_breakpoint_tab.p_ActiveTab == 3) {
      ctl_variable.p_text=condition;
      ctl_variable_size.p_text = address;
      ctl_expr.p_enabled = false;
      ctl_expr_label.p_enabled = false;
      ctl_skips_label.p_enabled = false;
      ctl_skips.p_enabled = false;
      //ctl_thread_combo.p_enabled = false;
      //ctl_thread_label.p_enabled = false;
   } else {
      ctl_expr.p_text=condition;
   }

   ctl_file.p_text=file_name;
   ctl_line.p_text=line_number;
   ctl_skips.p_text=count;
   ctl_address.p_text=address;

   if (!debug_session_is_implemented("update_disassembly")) {
      ctl_address_label.p_enabled = false;
      ctl_address.p_enabled = false;
      orig_tab := ctl_breakpoint_tab.p_ActiveTab;
      ctl_breakpoint_tab.p_ActiveTab = 2;
      ctl_breakpoint_tab.p_ActiveEnabled = false;
      ctl_breakpoint_tab.p_ActiveTab = orig_tab;
   }

   if (!debug_session_is_implemented("enable_watchpoint")) {
      ctl_variable_label.p_enabled = false;
      ctl_variable.p_enabled = false;
      orig_tab := ctl_breakpoint_tab.p_ActiveTab;
      ctl_breakpoint_tab.p_ActiveTab = 3;
      ctl_breakpoint_tab.p_ActiveEnabled = false;
      ctl_breakpoint_tab.p_ActiveTab = orig_tab;
   } else {
      session_id := dbg_get_current_session();
      if (dbg_get_callback_name(session_id) == "windbg") {
         ctl_variable_size_label.p_visible = true;
         ctl_variable_size.p_visible = true;
      }
   }

   ctl_class.p_text=class_name;
   ctl_function.p_text=ctl_function.p_text:+method_name;

   ctl_thread_combo._cbset_text(thread_name);
   debug_pkg_update_threads();
   debug_pkg_update_threadgroups();
   dbg_update_thread_list(ctl_thread_combo,false);
   ctl_thread_combo._lbadd_item("(any thread)");
   if (thread_name=="") {
      ctl_thread_combo._cbset_text("(any thread)");
   }

   _SetDialogInfoHt("id", breakpoint_id, ctl_breakpoint_tab);
   ctl_function_label.p_user=enabled;
   visited_mask := (1 << ctl_breakpoint_tab.p_ActiveTab);
   _SetDialogInfoHt("visited", visited_mask, ctl_breakpoint_tab);
   return(0);
}


///////////////////////////////////////////////////////////////////////////
// Callbacks for exception breakpoint property editor
//
defeventtab _debug_exception_form;
void _debug_exception_form.ENTER()
{
   ctl_ok.call_event(_control ctl_ok,LBUTTON_UP);
}
void ctl_ok.lbutton_up()
{
   // inspect the exception
   stop_when := 0;
   count := 0;
   condition := "";
   _str thread_name;
   _str exception_name;
   enabled := false;

   // has the exception name changed?
   if (ctl_exception.p_text != ctl_ok.p_user) {
      // validate the exception name
      if (ctl_exception.p_text=="" || !pos("^[*.a-zA-Z0-9_$-]#$", ctl_exception.p_text, 1, 'r')) {
         debug_message("Expecting a valid exception identifier!");
         ctl_exception._set_focus();
         return;
      }
      // check if it is a known exception
      debug_update_exception_list();
      if (!debug_find_exception_in_list(ctl_exception.p_text)) {
         result := _message_box("\""ctl_exception.p_text"\" is not a known exception.  Use it anyway?","",MB_YESNOCANCEL|MB_ICONQUESTION,IDNO);
         if (result==IDCANCEL) {
            p_active_form._delete_window(0);
            return;
         }
         if (result==IDNO) {
            ctl_exception._set_focus();
            return;
         }
      }
   }

   // validate the skips value
   if (ctl_skips.p_text!="" && (!isinteger(ctl_skips.p_text) || (int)ctl_skips.p_text < 0)) {
      debug_message("Expecting a positive integer value!");
      ctl_skips._set_focus();
      return;
   } else if (ctl_skips.p_text!="") {
      count=(int)ctl_skips.p_text;
   } else {
      count=0;
   }

   // get the thread name
   thread_name = ctl_thread_combo.p_text;
   if (thread_name=="(any thread)") {
      thread_name="";
   }

   // get the exception name
   exception_name=ctl_exception.p_text;

   // check the exception ID
   exception_id := (int) ctl_exception.p_user;

   // disable the exception
   status := 0;
   /*status=*/debug_pkg_disable_exception(exception_id);
   if (status) {
      debug_message("Error disabling exception",status);
      return;
   }

   // delete the exception
   status=dbg_remove_exception(exception_id);
   if (status) {
      debug_message("Error removing exception",status);
      return;
   }

   // get the stop conditions
   if (ctl_caught.p_value) {
      stop_when|=VSDEBUG_EXCEPTION_STOP_WHEN_CAUGHT;
   }
   if (ctl_uncaught.p_value) {
      stop_when|=VSDEBUG_EXCEPTION_STOP_WHEN_UNCAUGHT;
   }

   // now add it with the right stuff
   exception_id=dbg_add_exception(stop_when,count,condition,exception_name,thread_name);
   if (exception_id < 0) {
      debug_message("Error adding exception",exception_id);
      return;
   }

   // now enable the exception (if it was enabled before)
   _save_form_response();
   if (ctl_exception_label.p_user) {
      status=debug_pkg_enable_exception(exception_id);
      if (status) {
         debug_message("Error enabling exception",status);
         return;
      }
   }

   // that's all folks
   p_active_form._delete_window(0);
}
int ctl_ok.on_create(int exception_id)
{
   // inspect the exception
   stop_when := 0;
   count := 0;
   _str condition;
   _str thread_name;
   _str exception_name;
   enabled := false;
   status := dbg_get_exception(exception_id,
                               stop_when,count,condition,
                               exception_name,thread_name,
                               enabled);
   if (status) {
      debug_message("Error",status);
   }

   ctl_skips.p_text=count;
   ctl_exception.p_text=exception_name;
   ctl_thread_combo._cbset_text(thread_name);
   debug_pkg_update_threads();
   debug_pkg_update_threadgroups();
   dbg_update_thread_list(ctl_thread_combo,false);
   ctl_thread_combo._lbadd_item("(any thread)");
   if (thread_name=="") {
      ctl_thread_combo._cbset_text("(any thread)");
   }

   ctl_exception.p_user=exception_id;
   ctl_exception_label.p_user=enabled;
   ctl_ok.p_user=exception_name;

   ctl_caught.p_value=(stop_when & VSDEBUG_EXCEPTION_STOP_WHEN_CAUGHT);
   ctl_uncaught.p_value=(stop_when & VSDEBUG_EXCEPTION_STOP_WHEN_UNCAUGHT);

   return(0);
}

int StringCompare(_str s1, _str s2);

/**
 * Does the i'th class in 'class_list' derive from 'parent_name'
 *
 * @param i             index of class to check
 * @param parent_name   name of parent class to check
 * @param class_list    list of class names
 * @param parent_list   list of parent classes (parallel to class_list)
 * @param result_list   list of partial results (dynamic programming)
 * @param tag_files     list of tag files to search 
 * @param visited       (in/out) caches context tagging search results 
 * @param depth         search depth (default 0, max 64)
 *
 * @return 1 if the class derives from 'parent_name, 0 otherwise
 */
int debug_class_derives_from(int i, _str &parent_name,
                             _str (&class_list)[],
                             _str (&parent_list)[],
                             int (&result_list)[],
                             var tag_files,
                             VS_TAG_RETURN_TYPE (&visited):[], 
                             int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (result_list[i] >= 0) {
      return result_list[i];
   }
   if (depth > 64) {
      return(0);
   }

   // this is better code
   normal_parents := "";
   normal_types := "";
   normal_files := "";
   status := tag_normalize_classes(parent_list[i],class_list[i],
                                   null,tag_files,false,true,
                                   normal_parents,normal_types,normal_files,
                                   visited, depth+1);
   if (status) {
      // here we go
      in_tag_files := "";
      parent_types := "";
      normal_parents=cb_get_normalized_inheritance(class_list[i],
                                                   in_tag_files,tag_files,
                                                   false, "", "",
                                                   parent_types, false,
                                                   visited, depth+1);
   }

   // search for a parent that derives from exception
   while (normal_parents != "") {
      class_name := "";
      parse normal_parents with class_name VS_TAGSEPARATOR_parents normal_parents;
      parse class_name with class_name "<" .;

      if (class_name==parent_name) {
         result_list[i]=1;
         return(1);
      }
      j := ArraySearch(class_list,class_name,StringCompare);
      if (j >= 0 && debug_class_derives_from(j,parent_name,class_list,parent_list,result_list,tag_files,visited,depth+1)) {
         result_list[i]=1;
         return(1);
      }
   }

   // class 'i' does not derive from 'parent_name'
   result_list[i]=0;
   return(0);
}

///////////////////////////////////////////////////////////////////////////
// Handlers for exception caught dialog
//
defeventtab _debug_exception_message_form;
void ctl_ok.on_create(_str msg="",_str caption=null)
{
   ctl_message.p_caption=msg;
   if (caption!=null) {
      p_active_form.p_caption=caption;
   }
}
void ctl_ok.lbutton_up()
{
   p_active_form._delete_window(0);
}
void ctl_ignore.lbutton_up()
{
   p_active_form._delete_window(1);
}
void ctl_ignoreall.lbutton_up()
{
   p_active_form._delete_window(2);
}
/**
 * Display a message box with the given message and allow
 * the user to select OK, Ignore, or Ignore All.
 *
 * @param msg                   Message to display
 * @param caption               Caption for dialog
 *
 * @return 0 if OK was pressed, 1 for button 1, 2 for button 2.
 */
int debug_exception_message(_str msg, _str caption=null)
{
   orig_wid := _get_focus();
   status := show("-modal -xy _debug_exception_message_form",msg,caption);
   if (orig_wid) {
      orig_wid._set_focus();
   }
   return(status);
}


///////////////////////////////////////////////////////////////////////////
// Handlers for debugger breakpoints tool window
//
static const VSDEBUG_BREAKPOINTS_FORM= "_tbdebug_breakpoints_form";
defeventtab _tbdebug_breakpoints_form;
void _tbdebug_breakpoints_form.on_create()
{
   _nocheck _control ctl_breakpoints_tree;

   ctl_breakpoints_tree._TreeSetColButtonInfo(0,1500,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Name");
   ctl_breakpoints_tree._TreeSetColButtonInfo(1,1000,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Class");
   ctl_breakpoints_tree._TreeSetColButtonInfo(2,1000,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT|TREE_BUTTON_SORT_FILENAME,0,"File");
   ctl_breakpoints_tree._TreeSetColButtonInfo(3,-1,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT|TREE_BUTTON_SORT_NUMBERS,0,"Line");

   debug_pkg_enable_disable_tabs();
   debug_gui_update_suspended();
   dbg_update_breakpoints_tree(ctl_breakpoints_tree,TREE_ROOT_INDEX,
                               _strip_filename(_project_name,'N'),
                               -1,
                               -1);
   debug_gui_breakpoints_update_buttons();
   ctl_breakpoints_tree._TreeTop();
}
void _tbdebug_breakpoints_form.on_resize()
{
   _nocheck _control ctl_breakpoints_tree;

   // adjust breakpoints for resizable icons
   ctl_breakpoints_tree.p_x = ctl_disable_btn.p_x*2 + ctl_disable_btn.p_width;
   ctl_disable_btn.p_y = ctl_add_btn.p_y_extent;
   ctl_clear_btn.p_y = ctl_disable_btn.p_y_extent;
   ctl_props_btn.p_y = ctl_clear_btn.p_y_extent;

   // now resize the rest of the toolbar
   debug_gui_resize_toolbar(0,ctl_breakpoints_tree,0,0);

   if ( !(p_window_flags & VSWFLAG_ON_RESIZE_ALREADY_CALLED) ) {
      // First time
      ctl_breakpoints_tree._TreeRetrieveColButtonInfo();
      ctl_breakpoints_tree._TreeAdjustLastColButtonWidth(); 
   }
}
void _tbdebug_breakpoints_form.on_destroy()
{
   ctl_breakpoints_tree._TreeAppendColButtonInfo();
}
void _twSaveState__tbdebug_breakpoints_form(typeless& state, bool closing)
{
   ctl_breakpoints_tree._TreeAppendColButtonInfo();
}
void _twRestoreState__tbdebug_breakpoints_form(typeless& state, bool opening)
{
   ctl_breakpoints_tree._TreeRetrieveColButtonInfo();
}

/**
 * @return
 *    Return the window ID of the window containing the breakpoints
 * combo and list of breakpoints.
 */
CTL_FORM debug_gui_breakpoints_wid()
{
   static CTL_FORM form_wid;
   if (_iswindow_valid(form_wid) && !form_wid.p_edit &&
       form_wid.p_object==OI_FORM && form_wid.p_name==VSDEBUG_BREAKPOINTS_FORM) {
      return(form_wid);
   }
   form_wid=_find_formobj(VSDEBUG_BREAKPOINTS_FORM,'N');
   return(form_wid);
}
CTL_TREE debug_gui_breakpoints_tree()
{
   _nocheck _control ctl_breakpoints_tree;
   CTL_FORM wid=debug_gui_breakpoints_wid();
   return (wid? wid.ctl_breakpoints_tree:0);
}
void debug_gui_clear_breakpoints()
{
   if (!_haveDebugging()) return;
   CTL_TREE tree_wid=debug_gui_breakpoints_tree();
   if (tree_wid) {
      tree_wid._TreeDelete(TREE_ROOT_INDEX,'c');
   }
}

/**
 * Toggle the breakpoint at the specified tree index
 * between enabled and disabled.
 */
static int debug_gui_toggle_breakpoint(int index)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // get the breakpoint ID
   breakpoint_id := _TreeGetUserInfo(index);

   // inspect the breakpoint
   enabled := dbg_get_breakpoint_enabled(breakpoint_id);
   if (enabled < 0) {
      return(enabled);
   }

   // enable or disable the breakpoint
   status := 0;
   orig_wid := p_window_id;
   if (enabled) {
      status=debug_pkg_disable_breakpoint(breakpoint_id);
      if (status) {
         debug_message("Error disabling breakpoint",status);
         orig_wid._set_focus();
      }
   } else {
      status=debug_pkg_enable_breakpoint(breakpoint_id);
      if (status) {
         debug_message("Error enabling breakpoint",status);
         orig_wid._set_focus();
      }
   }

   // get the bitmap information in the tree
   enabled=dbg_get_breakpoint_enabled(breakpoint_id);
   //say("debug_gui_toggle_breakpoint: AFTER enabled="enabled" status="status);
   // change this single node
   checkState := (enabled==0)? TCB_UNCHECKED:TCB_CHECKED;
   if (enabled==1) checkState = TCB_PARTIALLYCHECKED;
   _TreeSetCheckState(index,checkState);

   // update the editor
   dbg_update_editor_breakpoints();
   return(status);
}

static int debug_gui_preview_breakpoint(int index)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // get the breakpoint ID
   breakpoint_id := _TreeGetUserInfo(index);

   // make sure the breakpoint properties button is enabled
   if (!ctl_props_btn.p_enabled) {
      ctl_props_btn.p_enabled = true;
   }

   // get the breakpoint's vital information
   tag_init_tag_browse_info(auto cm);
   status := dbg_get_breakpoint_location(breakpoint_id, cm.file_name, cm.line_no);
   if (status < 0) {
      return status;
   }
   dbg_get_breakpoint_scope(breakpoint_id, cm.class_name, cm.member_name);

   // now update the symbol preview window
   cb_refresh_output_tab(cm, true, true, false, APF_BREAKPOINTS);
   return 0;
}

void ctl_breakpoints_tree.on_got_focus()
{
   // send an event to change_selected, so that the preview is updated
   if (_TreeCurIndex() >= 0) {
      call_event(CHANGE_SELECTED, _TreeCurIndex(), ctl_breakpoints_tree, ON_CHANGE, 'W');
   }
}

int ctl_breakpoints_tree.on_change(int reason, int index)
{
   if ( index>=0 ) {
      if ( reason==CHANGE_SELECTED ) {
         return debug_gui_preview_breakpoint(index);
      }
      if ( reason==CHANGE_CHECK_TOGGLED ) {
         return debug_gui_toggle_breakpoint(index);
      }
   }
   return 0;
}

/**
 * Remove the current breakpoint
 * 
 * @categories Debugger_Commands
 */
_command int debug_delete_breakpoint() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   CTL_TREE tree_wid = debug_gui_breakpoints_tree();
   if (!tree_wid) {
      return(0);
   }

   index := tree_wid._TreeCurIndex();
   if (index>0) {
      // get the breakpoint ID
      breakpoint_id := tree_wid._TreeGetUserInfo(index);

      // disable the breakpoint
      status := debug_pkg_disable_breakpoint(breakpoint_id);
      if (status) {
         debug_message("Error disabling breakpoint",status);
         return(status);
      }

      // now remove the bugger
      status=dbg_remove_breakpoint(breakpoint_id);
      if (status) {
         debug_message("Error removing breakpoint",status);
         return(status);
      }

      // update the editor
      tree_wid._TreeDelete(index);
      debug_gui_update_breakpoints(true);
   }

   // update the debugger, in case if we hit the breakpoint right away
   if (debug_active()) {
      mou_hour_glass(true);
      debug_force_update_after_step_or_continue();
      mou_hour_glass(false);
   }

   return(0);
}
int ctl_breakpoints_tree.DEL()
{
   return debug_delete_breakpoint();
}

/**
 * Display the right-click menu for the breakpoints
 */
void ctl_breakpoints_tree.rbutton_up()
{
   // get the menu form
   index := find_index("_debug_breakpoints_menu",oi2type(OI_MENU));
   if (!index) {
      return;
   }
   menu_handle := p_active_form._menu_load(index,'P');
   tree_wid := p_window_id;

   cur_index := tree_wid._TreeCurIndex();
   if (cur_index <= 0 || dbg_get_num_breakpoints() <= 0) {
      _menu_set_state(menu_handle, "goto", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "delete", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "edit", MF_GRAYED, 'C');
   }

   // Show the menu.
   x := mou_last_x('M')-100;
   y := mou_last_y('M')-100;
   _lxy2dxy(p_scale_mode,x,y);
   _map_xy(p_window_id,0,x,y,SM_PIXEL);
   _KillToolButtonTimer();
   _menu_show(menu_handle,VPM_LEFTALIGN|VPM_RIGHTBUTTON,x,y);
   _menu_destroy(menu_handle);
}
/**
 * Edit the current breakpoint
 */
void ctl_breakpoints_tree.lbutton_double_click()
{
   debug_goto_breakpoint();
}

/**
 * Attempt to go to the location of the selected breakpoint.
 * 
 * @categories Debugger_Commands
 */
_command void debug_goto_breakpoint() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return;
   }

   // we better be in a tree control when this happens
   if (p_object != OI_TREE_VIEW) {
      return;
   }

   // nothing selected?
   index := _TreeCurIndex();
   if (index <= 0) {
      return;
   }

   // get the caption, and name of variable
   caption := _TreeGetCaption(index);
   _str class_name, method_name, file_name, line_no;
   parse caption with method_name "\t" class_name "\t" file_name "\t" line_no ;
   if (file_name != "") {
      if (!file_exists(file_name)) {
         file_name=absolute(file_name,_strip_filename(_project_name,'N'));
      } else {
         file_name=absolute(file_name);
      }
      // try to open the file
      status := edit(_maybe_quote_filename(file_name),EDIT_DEFAULT_FLAGS);
      if (status) {
         // no message here, edit() will complain if it has a problem
         return;
      }

      // maybe add this file to list of read only files
      debug_maybe_add_readonly_file(file_name);

      // go to the specified line number
      if (line_no != "" && isinteger(line_no)) {
         goto_line((int) line_no);
      }
      return;
   }

   // no filename, try to look up the tag
   child_wid := _MDIGetActiveMDIChild();
   if (child_wid) {
      if (class_name != "") {
         child_wid.find_tag("-c "class_name"."method_name);
      } else {
         child_wid.find_tag("-c "method_name);
      }
   }
}

/**
 * Edit the selected breakpoint, or the breakpoint under the cursor.
 *
 * @return 0 on success, <0 on error.
 * 
 * @categories Debugger_Commands
 */
_command int debug_edit_breakpoint() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // get the breakpoint ID
   breakpoint_id := 0;
   editorctl_wid := 0;
   CTL_TREE tree_wid=debug_gui_breakpoints_tree();
   if (tree_wid && (p_window_id == tree_wid)) {
      index := tree_wid._TreeCurIndex();
      if (index > 0) {
         breakpoint_id=tree_wid._TreeGetUserInfo(index);
      }
      if (!_no_child_windows() && _mdi.p_child._isdebugging_supported()) {
         editorctl_wid = _mdi.p_child;
      }
   } else if (_isEditorCtl()) {
      _str address=null;
      enabled := false;
      breakpoint_id = dbg_find_breakpoint(p_buf_name,p_RLine,enabled,0,address);
      editorctl_wid = p_window_id;
   } else {
      debug_message("Breakpoints dialog is not active");
      return(-1);
   }

   if (breakpoint_id <= 0) {
      debug_message("No selected breakpoint");
      return(-1);
   }

   // display the breakpoint editor form
   status := show("-modal -xy _debug_breakpoint_form",breakpoint_id, editorctl_wid);
   if (status < 0) {
      return(status);
   }

   // update the editor
   return debug_gui_update_breakpoints(true);
}

/**
 * Create a new breakpoint or watch point.
 * 
 * @return breakpoint id > 0 on success, < 0 on error.
 * 
 * @categories Debugger_Commands
 */
_command int debug_add_breakpoint() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // get the editor control for surfing default values
   editorctl_wid := 0;
   if (_isEditorCtl()) {
      editorctl_wid = p_window_id;
   } else if (!_no_child_windows() && _mdi.p_child._isdebugging_supported()) {
      editorctl_wid = _mdi.p_child;
   }

   // display the breakpoint editor form
   breakpoint_id := show("-modal -xy _debug_breakpoint_form",0,editorctl_wid);
   if (breakpoint_id < 0) {
      return(breakpoint_id);
   }

   // update the editor
   debug_gui_update_breakpoints(true);

   // update the debugger, in case if we hit the breakpoint right away
   if (debug_active()) {
      mou_hour_glass(true);
      debug_force_update_after_step_or_continue();
      mou_hour_glass(false);
   }

   return 0;
}

void ctl_props_btn.lbutton_up() 
{
   tree_wid := debug_gui_breakpoints_tree();
   if (!tree_wid) return;
   tree_wid.debug_edit_breakpoint();
}

/**
 * Update the enable/disable states of the
 * buttons on the breakpoints form.
 */
static void debug_gui_breakpoints_update_buttons()
{
   if (!_haveDebugging()) {
      return;
   }
   CTL_FORM form_wid=debug_gui_breakpoints_wid();
   if (!form_wid) {
      return;
   }
   CTL_TREE tree_wid=debug_gui_breakpoints_tree();
   if (!tree_wid) {
      return;
   }
   disable_enabled := false;
   clear_enabled := false;
   props_enabled := false;

   no_of_breakpoints := tree_wid._TreeGetNumChildren(TREE_ROOT_INDEX);
   tree_index := tree_wid._TreeCurIndex();
   if (no_of_breakpoints>0 && tree_index>0) {
      breakpoint_id := tree_wid._TreeGetUserInfo(tree_index);
      if (breakpoint_id > 0 && breakpoint_id <= dbg_get_num_breakpoints()) {
         props_enabled=true;
      }
   }
   if (no_of_breakpoints > 0) {
      clear_enabled=true;
      disable_enabled=true;
   }

   _nocheck _control ctl_add_btn;
   session_id := dbg_get_current_session();
   form_wid.ctl_add_btn.p_enabled = debug_session_is_implemented("enable_breakpoint");

   _nocheck _control ctl_disable_btn;
   _nocheck _control ctl_clear_btn;
   _nocheck _control ctl_props_btn;
   if (form_wid.ctl_disable_btn.p_enabled!=disable_enabled) {
      form_wid.ctl_disable_btn.p_enabled=disable_enabled;
   }
   if (form_wid.ctl_clear_btn.p_enabled!=clear_enabled) {
      form_wid.ctl_clear_btn.p_enabled=clear_enabled;
   }
   if (form_wid.ctl_props_btn.p_enabled!=props_enabled) {
      form_wid.ctl_props_btn.p_enabled=props_enabled;
   }
}


///////////////////////////////////////////////////////////////////////////
// Handlers for debugger exceptions tool window
//
static const VSDEBUG_EXCEPTIONS_FORM= "_tbdebug_exceptions_form";
defeventtab _tbdebug_exceptions_form;
void _tbdebug_exceptions_form.on_create()
{
   _nocheck _control ctl_exceptions_tree;

   ctl_exceptions_tree._TreeSetColButtonInfo(0,1800,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Exceptions to catch");
   ctl_exceptions_tree._TreeSetColButtonInfo(1,-1,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT|TREE_BUTTON_AUTOSIZE,0,"When");

   debug_pkg_enable_disable_tabs();
   debug_gui_update_suspended();

   _nocheck _control ctl_exceptions_tree;
   dbg_update_exceptions_tree(ctl_exceptions_tree,TREE_ROOT_INDEX,
                              -1,-1);
   ctl_exceptions_tree._TreeTop();
}
void _tbdebug_exceptions_form.on_destroy()
{
   ctl_exceptions_tree._TreeAppendColButtonInfo();
}
void _tbdebug_exceptions_form.on_resize()
{
   //_nocheck _control ctl_exception_combo;
   _nocheck _control ctl_exceptions_tree;

   // adjust exceptions for resizable icons
   ctl_exceptions_tree.p_x = ctl_add_exception.p_x*2 + ctl_add_exception.p_width;
   ctlimage1.p_y = ctl_add_exception.p_y_extent;
   ctlimage2.p_y = ctlimage1.p_y_extent;
   ctlimage3.p_y = ctlimage2.p_y_extent;

   // now resize the rest of the toolbar
   debug_gui_resize_toolbar(0,ctl_exceptions_tree);

   if ( !(p_window_flags & VSWFLAG_ON_RESIZE_ALREADY_CALLED) ) {
      // First time
      ctl_exceptions_tree._TreeRetrieveColButtonInfo();
      ctl_exceptions_tree._TreeAdjustLastColButtonWidth(); 
   }
}
void _twSaveState__tbdebug_exceptions_form(typeless& state, bool closing)
{
   ctl_exceptions_tree._TreeAppendColButtonInfo();
}
void _twRestoreState__tbdebug_exceptions_form(typeless& state, bool opening)
{
   ctl_exceptions_tree._TreeRetrieveColButtonInfo();
}

/**
 * @return
 *    Return the window ID of the window containing the exceptions
 * combo and list of exceptions.
 */
CTL_FORM debug_gui_exceptions_wid()
{
   static CTL_FORM form_wid;
   if (_iswindow_valid(form_wid) && !form_wid.p_edit &&
       form_wid.p_object==OI_FORM && form_wid.p_name==VSDEBUG_EXCEPTIONS_FORM) {
      return(form_wid);
   }
   form_wid=_find_formobj(VSDEBUG_EXCEPTIONS_FORM,'N');
   return(form_wid);
}
static CTL_TREE debug_gui_exceptions_tree()
{
   _nocheck _control ctl_exceptions_tree;
   CTL_FORM wid=debug_gui_exceptions_wid();
   return (wid? wid.ctl_exceptions_tree:0);
}
static CTL_TREE debug_gui_exceptions_combo()
{
   //_nocheck _control ctl_exception_combo;
   //CTL_FORM wid=debug_gui_exceptions_wid();
   //return (wid? wid.ctl_exception_combo:0);
   return 0;
}
void debug_gui_clear_exceptions()
{
   if (!_haveDebugging()) return;
   CTL_TREE tree_wid=debug_gui_exceptions_tree();
   if (tree_wid) {
      tree_wid._TreeDelete(TREE_ROOT_INDEX,'c');
   }
   CTL_COMBO combo_wid=debug_gui_exceptions_combo();
   if (combo_wid) {
      combo_wid._lbclear();
   }
}

/**
 * Toggle the exception at the specified tree index
 * between enabled and disabled.
 */
static int debug_gui_toggle_exception(int index)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // get the exception ID
   exception_id := _TreeGetUserInfo(index);

   // inspect the exception
   enabled := dbg_get_exception_enabled(exception_id);
   if (enabled < 0) {
      return(enabled);
   }

   // enable or disable the exception
   status := 0;
   orig_wid := p_window_id;
   if (enabled) {
      status=debug_pkg_disable_exception(exception_id);
      if (status) {
         debug_message("Error disabling exception",status);
         orig_wid._set_focus();
      }
   } else {
      status=debug_pkg_enable_exception(exception_id);
      if (status) {
         debug_message("Error enabling exception",status);
         orig_wid._set_focus();
      }
   }

   // get the bitmap information in the tree
   enabled=dbg_get_exception_enabled(exception_id);
   //say("debug_gui_toggle_exception: AFTER enabled="enabled" status="status);
   if (enabled) {
      _TreeSetCheckState(index,TCB_CHECKED);
   } else {
      _TreeSetCheckState(index,TCB_UNCHECKED);
   }

   // update the editor
   return(status);
}

/**
 * Toggle a exception between enabled and disabled
 */
int ctl_exceptions_tree.lbutton_up()
{
   x := mou_last_x();
   y := mou_last_y();
   index := _TreeGetIndexFromPoint(x,y,'PB');
   if (index>0) {
      // toggle the exception
      return debug_gui_toggle_exception(index);
   }
   return(0);
}
/**
 * Toggle a exception between enabled and disabled
 */
int ctl_exceptions_tree.' '()
{
   index := _TreeCurIndex();
   if (index>0) {
      // toggle the exception
      return debug_gui_toggle_exception(index);
   }
   return(0);
}

/**
 * Remove the current exception
 * 
 * @categories Debugger_Commands
 */
_command int debug_delete_exception() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   CTL_TREE tree_wid = debug_gui_exceptions_tree();
   if (!tree_wid) {
      return(0);
   }

   index := tree_wid._TreeCurIndex();
   if (index>0) {
      // get the exception ID
      exception_id := tree_wid._TreeGetUserInfo(index);

      // disable the exception
      status := debug_pkg_disable_exception(exception_id);
      if (status) {
         debug_message("Error disabling exception",status);
         return(status);
      }

      // now remove the bugger
      status=dbg_remove_exception(exception_id);
      if (status) {
         debug_message("Error removing exception",status);
         return(status);
      }

      // update the editor
      tree_wid._TreeDelete(index);
      return debug_gui_update_exceptions(true);
   }
   return(0);
}
int ctl_exceptions_tree.DEL()
{
   return debug_delete_exception();
}
/**
 * Display the right-click menu for the exception breakpoints
 */
void ctl_exceptions_tree.rbutton_up()
{
   // get the menu form
   index := find_index("_debug_exceptions_menu",oi2type(OI_MENU));
   if (!index) {
      return;
   }
   menu_handle := p_active_form._menu_load(index,'P');
   CTL_TREE tree_wid=p_window_id;

   cur_index := tree_wid._TreeCurIndex();
   if (cur_index <= 0 || dbg_get_num_breakpoints() <= 0) {
      _menu_set_state(menu_handle, "goto", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "delete", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "edit", MF_GRAYED, 'C');
   }

   // Show the menu.
   x := mou_last_x('M')-100;
   y := mou_last_y('M')-100;
   _lxy2dxy(p_scale_mode,x,y);
   _map_xy(p_window_id,0,x,y,SM_PIXEL);
   _KillToolButtonTimer();
   _menu_show(menu_handle,VPM_LEFTALIGN|VPM_RIGHTBUTTON,x,y);
   _menu_destroy(menu_handle);
}

/**
 * Edit the current exception
 */
int ctl_exceptions_tree.lbutton_double_click()
{
   index := _TreeCurIndex();
   if (index>0) {
      // get the exception ID
      exception_id := _TreeGetUserInfo(index);

      // display the exception editor form
      status := show("-modal -xy _debug_exception_form",exception_id);
      if (status) {
         return(status);
      }

      // update the editor
      return debug_gui_update_exceptions(true);
   }
   return(0);
}

/**
 * Attempt to go to the declaration of the selected exception class.
 * 
 * @categories Debugger_Commands
 */
_command void debug_goto_exception() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return;
   }

   // we better be in a tree control when this happens
   if (p_object != OI_TREE_VIEW) {
      return;
   }

   // nothing selected?
   index := _TreeCurIndex();
   if (index <= 0) {
      return;
   }

   // get the caption, and name of variable
   caption := _TreeGetCaption(index);
   parse caption with caption "\t" . ;
   child_wid := _MDIGetActiveMDIChild();
   if (child_wid) {
      child_wid.find_tag("-c "caption);
   }
}

/**
 * Edit the selected exception, or the exception under
 * the cursor.
 *
 * @return 0 on success, <0 on error.
 * 
 * @categories Debugger_Commands
 */
_command int debug_edit_exception() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // get the exception ID
   exception_id := 0;
   CTL_TREE tree_wid=debug_gui_exceptions_tree();
   if (tree_wid) {
      index := tree_wid._TreeCurIndex();
      if (index > 0) {
         exception_id=tree_wid._TreeGetUserInfo(index);
      }
   } else {
      debug_message("Exceptions dialog is not active");
      return(-1);
   }

   if (exception_id <= 0) {
      debug_message("No selected exception");
      return(-1);
   }

   // display the exception editor form
   status := show("-modal -xy _debug_exception_form",exception_id);
   if (status) {
      return(status);
   }

   // update the editor
   return debug_gui_update_exceptions(true);
}

/*
/**
 * Add a exception when they hit enter in the combo box
 */
int ctl_exception_combo.ENTER()
{
   exception_name := p_cb_text_box.p_text;
   if (exception_name=="") {
      return(0);
   }

   // check if we already have this exception in the list
   enabled := 0;
   index := dbg_find_exception(exception_name,enabled,0);
   if (index > 0) {
      tree_index := ctl_exceptions_tree._TreeSearch(0,exception_name,"",index);
      if (tree_index > 0) {
         ctl_exceptions_tree._TreeSetCurIndex(tree_index);
      }
      debug_message(nls("Exception \"%s\" already defined",exception_name));
      return(0);
   }

   // save the break point response
   _append_retrieve(ctl_exception_combo, ctl_exception_combo.p_text);
   _save_form_response();
   ctl_exception_combo.p_cb_list_box._retrieve_list();
   exception := ctl_exception_combo.p_cb_text_box.p_text;

   // add the exception to the exception list
   exception_id := dbg_add_exception(VSDEBUG_EXCEPTION_STOP_WHEN_CAUGHT,
                                      0, "", exception, "");
   if (exception_id < 0) {
      debug_message("Error adding exception",exception_id);
      return (exception_id);
   }

   // enable the exception
   if (exception_id > 0) {
      status = debug_pkg_enable_exception(exception_id);
      if (status) {
         debug_message("Error setting exception",status);
      }
   }

   p_text="";
   _begin_line();
   // update the views
   status= debug_gui_update_exceptions(true);
   refresh();
   return(status);
}
*/

/*
/**
 * Populate the list of exceptions
 */
void ctl_exception_combo.on_drop_down(int reason)
{
   // set caption and bitmaps for current context
   if (reason==DROP_DOWN && p_cb_list_box.p_Noflines==0) {
      if (_project_DebugCallbackName=='jdwp') {
         mou_hour_glass(true);
         p_cb_list_box._retrieve_list();
         debug_jdwp_list_exceptions();
         p_cb_list_box._lbsort();
         mou_hour_glass(false);
      }
   }
}
*/


///////////////////////////////////////////////////////////////////////////
// Handlers for debugger auto-variables, locals, and members toolbar
//
static const VSDEBUG_AUTOVARS_FORM= "_tbdebug_autovars_form";
defeventtab _tbdebug_autovars_form;
void _tbdebug_autovars_form.'C-A'-'C-Z',F2-F4,f6-F12,C_F12,'c-a-a'-'c-a-z','a-0'-'a-9'()
{
   _smart_toolwindow_hotkey();
}
void _tbdebug_autovars_form.'C-W',A_LEFT,A_RIGHT,A_UP()
{
   if (!_no_child_windows()) {
      p_window_id=_mdi.p_child;
      _set_focus();
   }
}
void _tbdebug_autovars_form.on_create()
{
   dbg_invalidate_views();

   editable_auto := (isDynamicDebugger() || debug_session_is_implemented("modify_autovar")==0)? 0:TREE_EDIT_TEXTBOX;
   displayType := debug_session_is_implemented("display_var_types");

   // set up our column widths
   col0Width := 2000;
   col1Width := 0;
   col2Width := 0;
   if (displayType) {
      col0Width = 1500;
      col1Width = 1500;
      col2Width = 0;
   }

   ctl_autovars_tree._TreeSetColButtonInfo(0,col0Width,TREE_BUTTON_PUSHBUTTON/*|TREE_BUTTON_SORT*/,0,"Name");
   ctl_autovars_tree._TreeSetColButtonInfo(1,col1Width,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_WRAP|(displayType? 0:TREE_BUTTON_AUTOSIZE),0,"Value");
   ctl_autovars_tree._TreeSetColEditStyle(1,TREE_EDIT_TEXTBOX);
   if (displayType) {
      ctl_autovars_tree._TreeSetColButtonInfo(2,col2Width,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_WRAP|TREE_BUTTON_AUTOSIZE,0,"Type");
   }

   ctl_autovars_tree.p_user=0;

   debug_pkg_enable_disable_tabs();
   debug_gui_update_suspended();

   thread_id := dbg_get_cur_thread();
   frame_id := dbg_get_cur_frame(thread_id);

   if (thread_id>0 && frame_id>0 && debug_is_suspended()) {
      debug_gui_update_autovars(thread_id,frame_id);
   }

   dbg_update_stack_list(ctl_stack_combo1.p_window_id,thread_id);
   ctl_stack_combo1._cbset_text(ctl_stack_combo1._lbget_text());

   debug_gui_update_cur_frame(thread_id,frame_id);
}
void _tbdebug_autovars_form.on_destroy()
{
   ctl_autovars_tree._TreeAppendColButtonInfo();
}
void _twSaveState__tbdebug_autovars_form(typeless& state, bool closing)
{
   ctl_autovars_tree._TreeAppendColButtonInfo();
}
void _twRestoreState__tbdebug_autovars_form(typeless& state, bool opening)
{
   ctl_autovars_tree._TreeRetrieveColButtonInfo();
}
void _tbdebug_autovars_form.on_resize()
{
   _nocheck _control ctl_autovars_tree;
   _nocheck _control ctl_stack_combo1;
   debug_gui_resize_toolbar(0,ctl_autovars_tree,0,ctl_stack_combo1);

   if ( !(p_window_flags & VSWFLAG_ON_RESIZE_ALREADY_CALLED) ) {
      // First time
      ctl_autovars_tree._TreeRetrieveColButtonInfo();
      ctl_autovars_tree._TreeAdjustLastColButtonWidth(); 
   }
}
void _tbdebug_autovars_form.on_change(int reason)
{ 
   if (reason==CHANGE_AUTO_SHOW ) {
      tree_wid := _find_control("ctl_autovars_tree");
      if (tree_wid && tree_wid.p_user) {
         thread_id := dbg_get_cur_thread();
         frame_id := dbg_get_cur_frame(thread_id);
         debug_gui_update_autovars(thread_id,frame_id,true);
      }
   }
}
void _tbdebug_autovars_form.on_got_focus()
{ 
   tree_wid := _find_control("ctl_autovars_tree");
   if (tree_wid && tree_wid.p_user) {
      thread_id := dbg_get_cur_thread();
      frame_id := dbg_get_cur_frame(thread_id);
      debug_gui_update_autovars(thread_id,frame_id);
   }
}
int ctl_autovars_tree.on_change(int reason,int index)
{
   if (reason==CHANGE_SELECTED) {
   } else if (reason==CHANGE_EXPANDED) {
      if (debug_expand_var_requires_suspend(index) < 0) return 0;
      thread_id := dbg_get_cur_thread();
      frame_id := dbg_get_cur_frame(thread_id);
      watch_path := debug_get_variable_path(index);
      status := debug_pkg_expand_auto(thread_id,frame_id,watch_path);
      if (status) {
         return(status);
      }
      _TreeBeginUpdate(index);
      status=dbg_update_autos_tree(p_window_id,index,thread_id,frame_id,watch_path);
      _TreeEndUpdate(index);
      _TreeSortUserInfo(index,'N');
      if (status) {
         return(status);
      }
   } else if (reason==CHANGE_COLLAPSED) {
      thread_id := dbg_get_cur_thread();
      frame_id := dbg_get_cur_frame(thread_id);
      watch_path := debug_get_variable_path(index);
      //dbg_collapse_auto(thread_id,frame_id,watch_path);
      //_TreeDelete(index,'C');
      return(-1);

   } else if (reason == CHANGE_LEAF_ENTER) {

      // if this is a value column in a dynamic debugger, then it's time to change the value
      if (getTreeColFromMouse() == 1 && isDynamicDebugger()) {

         if (debug_session_is_implemented("modify_autovar") && !debug_gui_check_modifiable(index)) {
            session_id := dbg_get_current_session();
            thread_id := dbg_get_cur_thread();
            frame_id := dbg_get_cur_frame(thread_id);
            path := debug_get_variable_path(index);

            sig := value := oldValue := name := class_name := "";
            flags := line_number := is_in_scope := 0;
            dbg_get_autovar_info(thread_id,frame_id,path,name,class_name,sig,value,flags,oldValue);

            varName := _TreeGetTextForCol(index, 0);
            newValue := "";
            if (!show_modify_variable_dlg(session_id, thread_id, frame_id, oldValue, varName, newValue)) {
               debug_gui_modify_autovar(index, thread_id, frame_id, path, newValue);
            }
         }
      }
   } else if (reason == CHANGE_EDIT_OPEN) {
      // get the "raw" value of the variable, set it to arg(4), so we use that in the text box
      thread_id := dbg_get_cur_thread();
      frame_id := dbg_get_cur_frame(thread_id);
      path := debug_get_variable_path(index);
      field_name := class_name := signature := value := raw_value := "";
      flags := 0;
      dbg_get_autovar_info(thread_id,frame_id,path,field_name,class_name,signature,value,flags,raw_value);

      // set the raw value in the text box, so the user is editing the real thing
      // unless they are editing a string value, then it needs to remain quoted and escaped
      if (first_char(value) != '"' && first_char(value) != "'") {
         arg(4) = raw_value;
      }

      return 0;
   } else if (reason == CHANGE_EDIT_QUERY) {
      // The debugger might have changed its mind, so check
      // each time. This is specifically useful for PHP,
      // Python, and Perl debuggers that do not know if they
      // support modifying variables until the session is
      // started.
      if( !debug_session_is_implemented("modify_autovar") ) {
         return(-1);
      }
      return debug_gui_check_modifiable(index);

   } else if (reason == CHANGE_EDIT_CLOSE) {
      if (arg(4)=="") {
         return(DELETED_ELEMENT_RC);
      }

      // we will need this information to reload the tree
      thread_id := dbg_get_cur_thread();
      frame_id := dbg_get_cur_frame(thread_id);
      path := debug_get_variable_path(index);

      status := debug_gui_modify_autovar(index, thread_id, frame_id, path, arg(4));
      if (status == -1) {
         arg(4) = _TreeGetTextForCol(index, 1);
      }

      return status;
   }

   return(0);
}

static int debug_gui_modify_autovar(int index, int thread_id, int frame_id, _str path, _str newValue)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (newValue == "") return(DELETED_ELEMENT_RC);

   status := debug_pkg_modify_autovar(thread_id,frame_id,path,newValue);
   
   if (status) {
      debug_message("Could not modify variable",status);
      return -1;
   }

   // either way, it's a good idea to refresh the tree
   parent_index := _TreeGetParentIndex(index);
   path = debug_get_variable_path(parent_index);
   _TreeBeginUpdate(parent_index);
   status=dbg_update_autos_tree(p_window_id,parent_index,
                                thread_id,frame_id,path);
   _TreeEndUpdate(parent_index);
   _TreeSortUserInfo(parent_index,'N');
   if (status) {
      debug_message("Error",status);
   }

   debug_gui_update_all_vars();
   return(DELETED_ELEMENT_RC);
}

// Handle right-button released event, in order to display pop-up menu
// for the threads tree.
//
void ctl_autovars_tree.rbutton_up()
{
   // get the menu form
   index := find_index("_debug_variables_menu",oi2type(OI_MENU));
   if (!index) {
      return;
   }
   menu_handle := p_active_form._menu_load(index,'P');
   tree_wid := p_window_id;

   thread_id := dbg_get_cur_thread();
   frame_id := dbg_get_cur_frame(thread_id);
   cur_index := tree_wid._TreeCurIndex();
   if (cur_index <= 0 || dbg_get_num_autos(thread_id,frame_id) <= 0) {
      _menu_set_state(menu_handle, "goto",   MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "watch",  MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "watchpoint", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "memory", MF_GRAYED, 'C');
   }
   if (!debug_is_suspended()) {
      _menu_set_state(menu_handle, "watch",  MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "memory", MF_GRAYED, 'C');
   }

   int output_menu_handle,output_menu_pos;
   if (!_menu_find(menu_handle,"delete",output_menu_handle,output_menu_pos)) {
      _menu_delete(menu_handle,output_menu_pos);
   }
   if (!_menu_find(menu_handle,"clearall",output_menu_handle,output_menu_pos)) {
      _menu_delete(menu_handle,output_menu_pos);
   }
   // check the current number of scan lines
   _menu_set_state(menu_handle, def_debug_auto_lines, MF_CHECKED, 'C');

   AddOrRemoveBasesFromMenu(menu_handle);

   // Show the menu.
   x := mou_last_x('M')-100;
   y := mou_last_y('M')-100;
   _lxy2dxy(p_scale_mode,x,y);
   _map_xy(p_window_id,0,x,y,SM_PIXEL);
   _KillToolButtonTimer();
   _menu_show(menu_handle,VPM_LEFTALIGN|VPM_RIGHTBUTTON,x,y);
   _menu_destroy(menu_handle);
}

/**
 * @return
 *    Return the window ID of the window containing the automatic
 *    variables combo and list of automatic variable watches.
 */
CTL_FORM debug_gui_autovars_wid()
{
   static CTL_FORM form_wid;

   if (_iswindow_valid(form_wid) && !form_wid.p_edit &&
       form_wid.p_object==OI_FORM && form_wid.p_name==VSDEBUG_AUTOVARS_FORM) {
      return(form_wid);
   }

   form_wid=_find_formobj(VSDEBUG_AUTOVARS_FORM,'N');
   return(form_wid);
}
CTL_COMBO debug_gui_auto_stack_list()
{
   CTL_FORM wid=debug_gui_autovars_wid();
   return (wid? wid.ctl_stack_combo1:0);
}
static CTL_TREE debug_gui_autovars_tree()
{
   CTL_FORM wid=debug_gui_autovars_wid();
   return (wid? wid.ctl_autovars_tree:0);
}
void debug_gui_clear_autovars()
{
   CTL_FORM form_wid=debug_gui_autovars_wid();
   if (!form_wid) {
      return;
   }

   form_wid.ctl_autovars_tree._TreeDelete(TREE_ROOT_INDEX,'c');

   CTL_COMBO list_wid=debug_gui_auto_stack_list();
   if (list_wid) {
      list_wid._lbclear();
      list_wid.p_text="";
   }
}

/**
 * Set the number of lines to scan for auto-watches
 * 
 * @categories Debugger_Commands
 */
_command void debug_set_auto_lines(_str num_lines=3) name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return;
   }

   if (!isinteger(num_lines)) {
      debug_message("Expecting a positive integer value!",0,true);
      return;
   }
   // Set the def-vars to what they specified
   if(def_debug_auto_lines != num_lines) {
      def_debug_auto_lines = (int) num_lines;
      _config_modify_flags(CFGMODIFY_DEFVAR);
      if (debug_is_suspended()) {
         thread_id := dbg_get_cur_thread();
         frame_id := dbg_get_cur_frame(thread_id);
         dbg_clear_autos(thread_id,frame_id);
         debug_gui_update_autovars(thread_id,frame_id);
      }
   }
}

///////////////////////////////////////////////////////////////////////////
// Handlers debugger classes display toolbar
//
static const VSDEBUG_CLASSES_FORM= "_tbdebug_classes_form";
defeventtab _tbdebug_classes_form;
void ctl_system.lbutton_up()
{
   debug_gui_update_classes(true);
}
void _tbdebug_classes_form.'C-A'-'C-Z',F2-F4,f6-F12,C_F12,'c-a-a'-'c-a-z','a-0'-'a-9'()
{
   _smart_toolwindow_hotkey();
}
void _tbdebug_classes_form.'C-W',A_LEFT,A_RIGHT,A_UP()
{
   if (!_no_child_windows()) {
      p_window_id=_mdi.p_child;
      _set_focus();
   }
}
void _tbdebug_classes_form.on_create()
{
   _nocheck _control ctl_classes_tree;

   dbg_invalidate_views();

   editable_flag := (debug_session_is_implemented("modify_field")==0)? 0:TREE_EDIT_TEXTBOX;
   ctl_classes_tree._TreeSetColButtonInfo(0,1500,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Name");
   ctl_classes_tree._TreeSetColButtonInfo(1,-1,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Scope/Value");
   ctl_classes_tree._TreeSetColEditStyle(1,editable_flag);
   ctl_system._retrieve_value();
   ctl_classes_tree.p_user=0;

   debug_pkg_enable_disable_tabs();
   debug_gui_update_classes(true);
}
void _tbdebug_classes_form.on_destroy()
{
   ctl_classes_tree._TreeAppendColButtonInfo();
}
void ctl_system.on_destroy()
{
   ctl_system._append_retrieve(ctl_system,ctl_system.p_value);
}
void _tbdebug_classes_form.on_resize()
{
   _nocheck _control ctl_classes_tree;
   debug_gui_resize_toolbar(0,ctl_classes_tree);

   if ( !(p_window_flags & VSWFLAG_ON_RESIZE_ALREADY_CALLED) ) {
      // First time
      ctl_classes_tree._TreeRetrieveColButtonInfo();
      ctl_classes_tree._TreeAdjustLastColButtonWidth(); 
   }
}
void _twSaveState__tbdebug_classes_form(typeless& state, bool closing)
{
   ctl_classes_tree._TreeAppendColButtonInfo();
}
void _twRestoreState__tbdebug_classes_form(typeless& state, bool opening)
{
   ctl_classes_tree._TreeRetrieveColButtonInfo();
}
void _tbdebug_classes_form.on_change(int reason)
{ 
   if (reason==CHANGE_AUTO_SHOW ) {
      tree_wid := _find_control("ctl_classes_tree");
      if (tree_wid && tree_wid.p_user) {
         thread_id := dbg_get_cur_thread();
         frame_id := dbg_get_cur_frame(thread_id);
         debug_gui_update_classes(true);
      }
   }
}
void _tbdebug_classes_form.on_got_focus()
{ 
   tree_wid := _find_control("ctl_classes_tree");
   if (tree_wid && tree_wid.p_user) {
      thread_id := dbg_get_cur_thread();
      frame_id := dbg_get_cur_frame(thread_id);
      debug_gui_update_classes();
   }
}
int ctl_classes_tree.on_change(int reason,int index)
{
   status := 0;
   if (reason==CHANGE_SELECTED) {
      // find the output tagwin and update it
      f := _GetTagwinWID(true);
      if (f && index>0) {
         // TBF (this should really happen on a timer)
      }

   } else if (reason==CHANGE_EXPANDED) {
      if (debug_expand_var_requires_suspend(index) < 0) return 0;
      class_path := debug_get_variable_path(index);
      status=debug_pkg_expand_class(class_path);
      if (status) {
         return(status);
      }
      _TreeBeginUpdate(index);
      status=dbg_update_class_tree(p_window_id,index,class_path,!(p_prev.p_value));
      _TreeEndUpdate(index);
      _TreeSortUserInfo(index,'N');
      if (status) {
         return(status);
      }
      return(index);
   } else if (reason==CHANGE_COLLAPSED) {
      class_path := debug_get_variable_path(index);
      //dbg_collapse_class(class_path);
      //_TreeDelete(index,'C');
      return(index);

   } else if (reason == CHANGE_EDIT_QUERY) {
      parent_index := _TreeGetParentIndex(index);
      if (parent_index==TREE_ROOT_INDEX) {
         return(-1);
      }
      if (_TreeGetParentIndex(parent_index)==TREE_ROOT_INDEX) {
         member_id := _TreeGetUserInfo(index);
         if (member_id >= VSDEBUG_CLASS_METHODS) {
            return(-1);
         }
      }
      return debug_gui_check_modifiable(index);

   } else if (reason == CHANGE_EDIT_OPEN) {

   } else if (reason == CHANGE_EDIT_CLOSE) {
      if (arg(4)=="") {
         return(DELETED_ELEMENT_RC);
      }
      field_path := debug_get_variable_path(index);
      status=debug_pkg_modify_field(field_path,arg(4));
      if (status) {
         debug_message("Could not modify field",status);
         return(-1);
      }
      parent_index := _TreeGetParentIndex(index);
      field_path = debug_get_variable_path(parent_index);
      expandedCaptions := debug_gui_save_expanded_captions(parent_index, 0);
      _TreeBeginUpdate(parent_index);
      status=dbg_update_class_tree(p_window_id,parent_index,field_path,!(p_prev.p_value));
      _TreeEndUpdate(parent_index);
      debug_gui_reexpand_captions(parent_index, expandedCaptions);
      if (status) {
         debug_message("Error",status);
      }
      debug_gui_update_all_vars();
      return(DELETED_ELEMENT_RC);

   } else if (reason == CHANGE_LEAF_ENTER) {
      parent_index := _TreeGetParentIndex(index);
      if (parent_index <= TREE_ROOT_INDEX) {
         class_id := _TreeGetUserInfo(index);
         show("-xy -modal _debug_class_props_form",class_id);
         return(0);
      }
      debug_goto_decl();
   }

   return(0);
}

// Handle right-button released event, in order to display pop-up menu
// for the classes tree.
//
void ctl_classes_tree.rbutton_up()
{
   // get the menu form
   index := find_index("_debug_classes_menu",oi2type(OI_MENU));
   if (!index) {
      return;
   }
   menu_handle := p_active_form._menu_load(index,'P');
   tree_wid := p_window_id;

   cur_index := tree_wid._TreeCurIndex();
   if (cur_index <= 0) {
      _menu_set_state(menu_handle, "debug_goto_decl", MF_GRAYED, 'M');
      _menu_set_state(menu_handle, "debug_class_break", MF_GRAYED, 'M');
      _menu_set_state(menu_handle, "debug_class_watch", MF_GRAYED, 'M');
      _menu_set_state(menu_handle, "debug_class_props", MF_GRAYED, 'M');
   } else {
      parent_index := tree_wid._TreeGetParentIndex(cur_index);
      if (parent_index > 0) {
         _menu_set_state(menu_handle, "debug_class_props", MF_GRAYED, 'M');
         member_id := tree_wid._TreeGetUserInfo(cur_index);
         if (member_id < VSDEBUG_CLASS_METHODS) {
            _menu_set_state(menu_handle, "debug_class_break", MF_GRAYED, 'M');
         } else {
            _menu_set_state(menu_handle, "debug_class_watch", MF_GRAYED, 'M');
         }
      } else {
         _menu_set_state(menu_handle, "debug_class_break", MF_GRAYED, 'M');
         _menu_set_state(menu_handle, "debug_class_watch", MF_GRAYED, 'M');
      }
   }

   // Show the menu.
   x := mou_last_x('M')-100;
   y := mou_last_y('M')-100;
   _lxy2dxy(p_scale_mode,x,y);
   _map_xy(p_window_id,0,x,y,SM_PIXEL);
   _KillToolButtonTimer();
   _menu_show(menu_handle,VPM_LEFTALIGN|VPM_RIGHTBUTTON,x,y);
   _menu_destroy(menu_handle);
}

/**
 * @return
 *    Return the window ID of the window containing the classes
 *    combo and list of classes.
 */
CTL_FORM debug_gui_classes_wid()
{
   static CTL_FORM form_wid;

   if (_iswindow_valid(form_wid) && !form_wid.p_edit &&
       form_wid.p_object==OI_FORM && form_wid.p_name==VSDEBUG_CLASSES_FORM) {
      return(form_wid);
   }

   form_wid=_find_formobj(VSDEBUG_CLASSES_FORM,'N');
   return(form_wid);
}
static CTL_TREE debug_gui_classes_tree()
{
   wid := debug_gui_classes_wid();
   return (wid? wid.ctl_classes_tree:0);
}
void debug_gui_clear_classes()
{
   tree_wid := debug_gui_classes_tree();
   if (tree_wid) {
      tree_wid._TreeDelete(TREE_ROOT_INDEX,'c');
   }
}

/**
 * Go to the definition of the selected item
 * 
 * @categories Debugger_Commands
 */
_command void debug_goto_decl() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return;
   }

   //debug_message("Goto definition is not implemented yet.");
   //return;

   status := flags := 0;
   name := class_name := signature := return_type := file_name := type_name := value := "";

   tree_wid := debug_gui_classes_tree();
   if (tree_wid) {
      cur_index := tree_wid._TreeCurIndex();
      if (cur_index > 0) {
         parent_index := tree_wid._TreeGetParentIndex(cur_index);
         if (parent_index > 0) {
            // method or field selected
            class_id := tree_wid._TreeGetUserInfo(parent_index);
            member_id := tree_wid._TreeGetUserInfo(cur_index);
            status=dbg_get_method(class_id,member_id,name,class_name,signature,return_type,file_name,flags);
            if (status) {
               status=dbg_get_field(class_id,member_id,name,signature,value,flags);
            }
            // class selected
            if (!status) {
               outer_class := "";
               class_file_name := "";
               typeless ds,df,dl;
               status = dbg_get_class(class_id,class_name,outer_class,ds,class_file_name,df,dl);
               if (!status && outer_class!="") {
                  class_name=outer_class:+VS_TAGSEPARATOR_package:+class_name;
                  if (file_name=="") file_name = class_file_name;
               }
            }
            // is this the constructor for an anonymous class?
            if (isinteger(name)) {
               name="@"name;
               if (pos(':v\.:i',class_name,1,'r')) {
                  class_name=substr(class_name,1,pos('S')-2);
               }
            }
         } else {
            // class selected
            class_id := tree_wid._TreeGetUserInfo(cur_index);
            loader := "";
            status = debug_pkg_expand_class(class_id);
            status = dbg_get_class(class_id,name,class_name,signature,file_name,flags,loader);
            p := lastpos(VS_TAGSEPARATOR_class,name);
            if (p) {
               class_name :+= VS_TAGSEPARATOR_package:+substr(name,1,p-1);
               name=substr(name,p+1);
            }
            // is this an anonymous class?
            if (pos('\.:i',name,1,'r')) {
               name="@"substr(name,pos('S')+1);
            } else if (isinteger(name)) {
               name="@"name;
            }
         }
         // got a class name, need to fine tune it a bit
         if (class_name != "") {
            // is this an anonymous class?
            if (pos(':v[./:$]{:i}',class_name,1,'r')) {
               class_name=substr(class_name,1,pos('S')-2) :+ ':@' :+
                          substr(class_name,pos('S0'),pos('0')) :+
                          substr(class_name,pos('S')+pos(""));
            }
         }
         if (status < 0) {
            debug_message("Error",status);
            return;
         }
         if (file_name=="") {
            debug_message("Source code not found");
            return;
         }
         if (_get_extension(file_name)=="e") {
            debug_resolve_slickc_class(class_name);
         }
         // attempt to resolve full path to source, do not complain
         // if path not found, becuase they have already been prompted
         full_path := debug_resolve_or_prompt_for_path(file_name,class_name,name);
         if (full_path!="") {
            push_tag_in_file(name, full_path, class_name, type_name, 0);
         }
      }
   }
}
/**
 * Set a breakpoint on the selected method
 * 
 * @categories Debugger_Commands
 */
_command void debug_class_break() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return;
   }

   tree_wid := debug_gui_classes_tree();
   if (tree_wid) {
      cur_index := tree_wid._TreeCurIndex();
      if (cur_index > 0) {
         parent_index := tree_wid._TreeGetParentIndex(cur_index);
         if (parent_index > 0) {
            class_id  := tree_wid._TreeGetUserInfo(parent_index);
            method_id := tree_wid._TreeGetUserInfo(cur_index);
            method_name := class_name := signature := return_type := file_name := "";
            flags := 0;
            status := dbg_get_method(class_id,method_id,method_name,class_name,signature,return_type,file_name,flags);
            if (!status) {
               // class selected
               typeless dn,ds,df,dl;
               dbg_get_class(class_id,dn,class_name,ds,file_name,df,dl);
               // got a class name, need to fine tune it a bit
               if (pos('^:v[./:$]{:i}$',dn,1,'r')) {
                  // an anonymous class?
                  dn=substr(dn,pos('S0'),pos('0'));
               }
               class_name=(class_name!="")? class_name:+".":+dn : dn;
               // add the breakpoint to the breakpoint list
               breakpoint_id := dbg_add_breakpoint(0,"","",class_name,method_name,
                                                   "",0,null,VSDEBUG_BREAKPOINT_METHOD,0);
               if (breakpoint_id < 0) {
                  debug_message("Error adding breakpoint",breakpoint_id);
                  return;
               }
               // enable the breakpoint
               if (breakpoint_id > 0) {
                  status = debug_pkg_enable_breakpoint(breakpoint_id);
                  if (status) {
                     debug_message("Error setting breakpoint",status);
                  }
               }
               // update the views
               status= debug_gui_update_breakpoints(true);

               // update the debugger, in case if we hit the breakpoint right away
               if (debug_active()) {
                  mou_hour_glass(true);
                  debug_force_update_after_step_or_continue();
                  mou_hour_glass(false);
               }

               return;
            }
         }
      }
   }
   debug_message("No method selected");
}
/**
 * Set an uncaught exception breakpoint on the selected method
 * 
 * @categories Debugger_Commands
 */
_command void debug_class_exception() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return;
   }

   tree_wid := debug_gui_classes_tree();
   if (tree_wid) {
      cur_index := tree_wid._TreeCurIndex();
      if (cur_index > 0) {
         parent_index := tree_wid._TreeGetParentIndex(cur_index);
         if (parent_index <= 0) {
            typeless dn,ds,df,dl;
            class_id := tree_wid._TreeGetUserInfo(cur_index);
            class_name := file_name := "";
            status := dbg_get_class(class_id,dn,class_name,ds,file_name,df,dl);
            if (!status) {
               // add the exception breakpoint to the exception list
               exception_id := dbg_add_exception(VSDEBUG_EXCEPTION_STOP_WHEN_CAUGHT, 0, "",class_name,"");
               if (exception_id < 0) {
                  debug_message("Error adding exception",exception_id);
                  return;
               }
               // enable the exception
               if (exception_id > 0) {
                  status = debug_pkg_enable_exception(exception_id);
                  if (status) {
                     debug_message("Error setting exception",status);
                  }
               }
               // update the views
               status= debug_gui_update_exceptions(true);
               refresh();
               return;
            }
         }
      }
   }
}
/**
 * Set a watch on the selected static field
 * 
 * @categories Debugger_Commands
 */
_command void debug_class_watch() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return;
   }

   tree_wid := debug_gui_classes_tree();
   if (tree_wid) {
      cur_index := tree_wid._TreeCurIndex();
      if (cur_index > 0) {
         parent_index := tree_wid._TreeGetParentIndex(cur_index);
         if (parent_index > 0) {
            root_index := tree_wid._TreeGetParentIndex(parent_index);
            // nested field, this is tricky stuff
            member_caption := "";
            while (root_index > 0) {
               caption := tree_wid._TreeGetCaption(cur_index);
               parse caption with caption "\t" .;
               if (member_caption=="") {
                  member_caption=strip(caption);
               } else {
                  member_caption=strip(caption):+member_caption;
               }
               if (substr(member_caption,1,1)!="[") {
                  member_caption=".":+member_caption;
               }
               cur_index=_TreeGetParentIndex(cur_index);
               parent_index=_TreeGetParentIndex(cur_index);
               root_index=_TreeGetParentIndex(parent_index);
            }
            class_id := tree_wid._TreeGetUserInfo(parent_index);
            field_id := tree_wid._TreeGetUserInfo(cur_index);
            field_name := class_name := signature := return_type := file_name := "";
            inner_name := outer_name := value := "";
            typeless df,dl;
            status := flags := 0;
            status=dbg_get_class(class_id,inner_name,outer_name,signature,file_name,df,dl);
            // got a class name, need to fine tune it a bit
            if (pos('^:v[./:$]{:i}$',inner_name,1,'r')) {
               // an anonymous class?
               inner_name=substr(inner_name,pos('S0'),pos('0'));
            }
            class_name=(outer_name!="")? outer_name"."inner_name:inner_name;
            status=dbg_get_field(class_id,field_id,field_name,signature,value,flags);
            if (!status) {
               // activate the watches if they are not already activated
               if (!debug_gui_watches_wid()) {
                  activate_watch();
               }
               // add the watch to the watches list
               tab_number := debug_gui_active_watches_tab();
               watch_id := dbg_add_watch(tab_number,class_name"."field_name:+member_caption,"",VSDEBUG_BASE_DEFAULT);
               if (watch_id < 0) {
                  debug_message("Error adding watch",watch_id);
                  return;
               }
               // update the views
               thread_id := dbg_get_cur_thread();
               frame_id := dbg_get_cur_frame(thread_id);
               status= debug_gui_update_watches(thread_id,frame_id,tab_number);
               refresh();
               return;
            }
         }
      }
   }
   debug_message("No field selected");
}

/**
 * Set a watch on the selected static field
 * 
 * @categories Debugger_Commands
 */
_command void debug_class_watchpoint() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return;
   }

   tree_wid := debug_gui_classes_tree();
   if (tree_wid) {
      cur_index := tree_wid._TreeCurIndex();
      if (cur_index > 0) {
         parent_index := tree_wid._TreeGetParentIndex(cur_index);
         if (parent_index > 0) {
            root_index := tree_wid._TreeGetParentIndex(parent_index);
            // nested field, this is tricky stuff
            member_caption := "";
            while (root_index > 0) {
               caption := tree_wid._TreeGetCaption(cur_index);
               parse caption with caption "\t" .;
               if (member_caption=="") {
                  member_caption=strip(caption);
               } else {
                  member_caption=strip(caption):+member_caption;
               }
               if (substr(member_caption,1,1)!="[") {
                  member_caption=".":+member_caption;
               }
               cur_index=_TreeGetParentIndex(cur_index);
               parent_index=_TreeGetParentIndex(cur_index);
               root_index=_TreeGetParentIndex(parent_index);
            }
            class_id := tree_wid._TreeGetUserInfo(parent_index);
            field_id := tree_wid._TreeGetUserInfo(cur_index);
            field_name := class_name := signature := return_type := file_name := "";
            inner_name := outer_name := value := "";
            typeless df,dl;
            status := flags := 0;
            status=dbg_get_class(class_id,inner_name,outer_name,signature,file_name,df,dl);
            // got a class name, need to fine tune it a bit
            if (pos('^:v[./:$]{:i}$',inner_name,1,'r')) {
               // an anonymous class?
               inner_name=substr(inner_name,pos('S0'),pos('0'));
            }
            class_name=(outer_name!="")? outer_name"."inner_name:inner_name;
            status=dbg_get_field(class_id,field_id,field_name,signature,value,flags);
            if (!status) {
               // activate the breakpoints if they are not already activated
               if (!debug_gui_breakpoints_wid()) {
                  activate_breakpoints();
               }
               // add the watch to the watches list
               breakpoint_id := dbg_add_breakpoint(0, field_name, "",
                                                   class_name, field_name,
                                                   file_name, 0, "",
                                                   def_debug_watchpoint_type, 0);
               if (breakpoint_id < 0) {
                  debug_message("Error adding watchpoint",breakpoint_id);
                  return;
               }
               // enable the breakpoint
               if (breakpoint_id > 0) {
                  status = debug_pkg_enable_breakpoint(breakpoint_id);
                  if (status) {
                     debug_message("Error setting watchpoint",status);
                  }
               }
               // update the views
               status= debug_gui_update_breakpoints(true);

               // update the debugger, in case if we hit the breakpoint right away
               if (debug_active()) {
                  mou_hour_glass(true);
                  debug_force_update_after_step_or_continue();
                  mou_hour_glass(false);
               }

               return;
            }
         }
      }
   }
   debug_message("No field selected");
}
/**
 * Display the class properties dialog for the selected class.
 * 
 * @categories Debugger_Commands
 */
_command void debug_class_props() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return;
   }

   tree_wid := debug_gui_classes_tree();
   if (tree_wid) {
      cur_index := tree_wid._TreeCurIndex();
      if (cur_index > 0) {
         parent_index := tree_wid._TreeGetParentIndex(cur_index);
         if (parent_index <= TREE_ROOT_INDEX) {
            class_id := tree_wid._TreeGetUserInfo(cur_index);
            show("-xy -modal _debug_class_props_form",class_id);
            return;
         }
      }
   }
   debug_message("No class selected");
}
/**
 * Collapse everything in the class tree
 * 
 * @categories Debugger_Commands
 */
_command void debug_class_collapse() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return;
   }

   tree_wid := debug_gui_classes_tree();
   if (tree_wid) {
      index := tree_wid._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      while (index > 0) {
         show_children := 0;
         _TreeGetInfo(index,show_children);
         if (show_children > 0) {
            _TreeDelete(index,'c');
            _TreeSetInfo(index,0);
         }
         //dbg_collapse_class(index);
         index=tree_wid._TreeGetNextSiblingIndex(index);
      }
   }
}
/**
 * Go to the definition of the selected item in the locals tree
 */
/*
static void debug_goto_field(bool is_local)
{
   cur_index := _TreeCurIndex();
   if (cur_index <= 0) {
      debug_message("No field selected");
   }

   int thread_id=dbg_get_cur_thread();
   int frame_id=dbg_get_cur_frame(thread_id);
   _str field_path = debug_get_variable_path(cur_index);

   status := flags := 0;
   name := class_name := signature := "";
   file_name := type_name := method_name := value := "";
   line_number := is_in_scope := 0;

   if (is_local) {
      status=dbg_get_local(thread_id,frame_id,field_path,
                           name,class_name,
                           signature,flags,value,line_number,is_in_scope);
   } else {
      status=dbg_get_member(thread_id,frame_id,field_path,
                            name,class_name,signature,flags,value);
   }
   if (status < 0) {
      debug_message("Error",status);
      return;
   }
   if (file_name=='') {
      debug_message("Source code not found");
      return;
   }
   full_path := "";
   status=debug_pkg_resolve_path(file_name,full_path);
   if (status) {
      // see if we can find the file in the tag files, this gives us an initial path
      _str found_path=debug_search_tagfiles_for_path(file_name);
      // prompt the user for the real path name
      full_path = _ChooseDirDialog('Find Source',found_path,file_name);
      if (full_path=='') {
         return;
      }
      if (last_char(full_path)!='') {
         full_path :+= FILESEP;
      }
      full_path :+= file_name;
   }

   push_tag_in_file(name, full_path, class_name, type_name, 0);
}
*/

/**
 * Set a breakpoint or watchpoing on the tag described by 'cm'
 * 
 * @param cm   tag info struct
 * 
 * @return 0 on success, <0 on error
 */
int debug_set_breakpoint_on_tag(VS_TAG_BROWSE_INFO &cm)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // normalize the class name
   debug_translate_class_name(cm.class_name);

   // determine what kind of breakpoint to create
   condition := "";
   breakpoint_type := VSDEBUG_BREAKPOINT_METHOD;
   if (tag_tree_type_is_statement(cm.type_name)) {
      breakpoint_type = VSDEBUG_BREAKPOINT_LINE;
   } else if (tag_tree_type_is_func(cm.type_name)) {
      breakpoint_type = VSDEBUG_BREAKPOINT_METHOD;
   } else if (tag_tree_type_is_data(cm.type_name)) {
      breakpoint_type = def_debug_watchpoint_type;
      condition = cm.class_name":"cm.member_name;
      debug_translate_class_name(condition);
   } else {
      _message_box("Can not set breakpoint on this item");
      return -1;
   }

   // activate the breakpoints tab
   activate_breakpoints();

   // add the breakpoint to the breakpoint list
   breakpoint_id := 0;
   if (!isEclipsePlugin()) {
      breakpoint_id=dbg_add_breakpoint(0, condition, "",
                                           cm.class_name, cm.member_name,
                                           cm.file_name, cm.line_no, "",
                                           breakpoint_type, 0);
   } else {
      return _eclipse_set_breakpoint_in_file(cm.file_name, cm.line_no);
   }
   if (breakpoint_id < 0) {
      debug_message("Error adding breakpoint",breakpoint_id);
      return breakpoint_id;
   }
   // enable the breakpoint
   status := 0;
   if (breakpoint_id > 0) {
      status = debug_pkg_enable_breakpoint(breakpoint_id);
      if (status) {
         debug_message("Error setting breakpoint",status);
      }
   }
   // update the views
   status= debug_gui_update_breakpoints(true);

   // update the debugger, in case if we hit the breakpoint right away
   if (debug_active()) {
      mou_hour_glass(true);
      debug_force_update_after_step_or_continue();
      mou_hour_glass(false);
   }

   return status;
}


///////////////////////////////////////////////////////////////////////////
// Handlers for class properties dialog
//
defeventtab _debug_class_props_form;
void ctl_name.on_create(int class_id=1)
{
   if (class_id <= 0 || class_id > dbg_get_num_classes()) {
      ctl_name.p_ReadOnly=false;
      ctl_name.p_text="Invalid class ID";
      ctl_name.p_ReadOnly=true;
      ctl_error.p_value=1;
      ctl_name._begin_line();
      ctl_close_btn._set_focus();
      return;
   }
   debug_pkg_expand_class(class_id);

   name := outer_class := signature := file_name := loader := "";
   flags := 0;
   status := dbg_get_class(class_id,name,outer_class,signature,file_name,flags,loader);
   if (status) {
      ctl_error.p_value=1;
      ctl_name._begin_line();
      ctl_name.p_text=get_message(status);
      ctl_close_btn._set_focus();
      return;
   }
   if (loader=="") {
      loader="(default system loader)";
   }

   ctl_name.p_ReadOnly=false;
   ctl_name.p_text=name;
   ctl_name.p_ReadOnly=true;

   ctl_scope.p_ReadOnly=false;
   ctl_scope.p_text=outer_class;
   ctl_scope.p_ReadOnly=true;

   ctl_loader.p_ReadOnly=false;
   ctl_loader.p_text=loader;
   ctl_loader.p_ReadOnly=true;

   ctl_name._begin_line();
   ctl_scope._begin_line();
   ctl_loader._begin_line();

   ctl_loaded.p_value=1;
   if (flags & VSDEBUG_FLAG_PREPARED) {
      ctl_prepared.p_value=1;
   }
   if (flags & VSDEBUG_FLAG_VERIFIED) {
      ctl_verified.p_value=1;
   }
   if (flags & VSDEBUG_FLAG_INITIALIZED) {
      ctl_initialized.p_value=1;
   }
   if (flags & VSDEBUG_FLAG_ERROR) {
      ctl_error.p_value=1;
   }

   i := 1;
   class_name := "";
   status=dbg_get_parent_class(class_id,i,class_name);
   while (!status) {
      ctl_parents._lbadd_item("extends "class_name);
      i++;
      status=dbg_get_parent_class(class_id,i,class_name);
   }

   i=1;
   status=dbg_get_parent_interface(class_id,i,class_name);
   while (!status) {
      ctl_parents._lbadd_item("implements "class_name);
      i++;
      status=dbg_get_parent_interface(class_id,i,class_name);
   }
}

///////////////////////////////////////////////////////////////////////////
// Handlers for debugger registers display toolbar
//
static const VSDEBUG_REGISTERS_FORM= "_tbdebug_regs_form";
defeventtab _tbdebug_regs_form;
void _tbdebug_regs_form.'C-A'-'C-Z',F2-F4,f6-F12,C_F12,'c-a-a'-'c-a-z','a-0'-'a-9'()
{
   _smart_toolwindow_hotkey();
}
void _tbdebug_regs_form.'C-W',A_LEFT,A_RIGHT,A_UP()
{
   if (!_no_child_windows()) {
      p_window_id=_mdi.p_child;
      _set_focus();
   }
}
void _tbdebug_regs_form.on_create()
{
   dbg_invalidate_views();

   editable_flag := (debug_session_is_implemented("modify_register")==0)? 0:TREE_EDIT_TEXTBOX;
   ctl_registers_tree._TreeSetColButtonInfo(0,1500,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Name");
   ctl_registers_tree._TreeSetColButtonInfo(1,-1,TREE_BUTTON_PUSHBUTTON,0,"Value");
   ctl_registers_tree._TreeSetColEditStyle(1,editable_flag);
   ctl_registers_tree.p_user=0;

   debug_pkg_enable_disable_tabs();
   debug_gui_update_suspended();

   thread_id := dbg_get_cur_thread();
   debug_gui_update_registers(thread_id);
}
void _tbdebug_regs_form.on_destroy()
{
   ctl_registers_tree._TreeAppendColButtonInfo();
}
void _tbdebug_regs_form.on_resize()
{
   _nocheck _control ctl_registers_tree;
   debug_gui_resize_toolbar(0,ctl_registers_tree);

   if ( !(p_window_flags & VSWFLAG_ON_RESIZE_ALREADY_CALLED) ) {
      // First time
      ctl_registers_tree._TreeRetrieveColButtonInfo();
      ctl_registers_tree._TreeAdjustLastColButtonWidth(); 
   }
}
void _twSaveState__tbdebug_regs_form(typeless& state, bool closing)
{
   ctl_registers_tree._TreeAppendColButtonInfo();
}
void _twRestoreState__tbdebug_regs_form(typeless& state, bool opening)
{
   ctl_registers_tree._TreeRetrieveColButtonInfo();
}
void _tbdebug_regs_form.on_change(int reason)
{ 
   if (reason==CHANGE_AUTO_SHOW ) {
      tree_wid := _find_control("ctl_registers_tree");
      if (tree_wid && tree_wid.p_user) {
         thread_id := dbg_get_cur_thread();
         debug_gui_update_registers(thread_id,true);
      }
   }
}
void _tbdebug_regs_form.on_got_focus()
{ 
   tree_wid := _find_control("ctl_registers_tree");
   if (tree_wid && tree_wid.p_user) {
      thread_id := dbg_get_cur_thread();
      debug_gui_update_registers(thread_id);
   }
}

/**
 * @return
 *    Return the window ID of the window containing the regs
 *    combo and list of regs.
 */
CTL_FORM debug_gui_registers_wid()
{
   static CTL_FORM form_wid;

   if (_iswindow_valid(form_wid) && !form_wid.p_edit &&
       form_wid.p_object==OI_FORM && form_wid.p_name==VSDEBUG_REGISTERS_FORM) {
      return(form_wid);
   }

   form_wid=_find_formobj(VSDEBUG_REGISTERS_FORM,'N');
   return(form_wid);
}
static CTL_TREE debug_gui_registers_tree()
{
   CTL_FORM wid=debug_gui_registers_wid();
   return (wid? wid.ctl_registers_tree:0);
}
void debug_gui_clear_registers()
{
   CTL_TREE tree_wid=debug_gui_registers_tree();
   if (tree_wid) {
      tree_wid._TreeDelete(TREE_ROOT_INDEX,'c');
   }
}


///////////////////////////////////////////////////////////////////////////
// Handlers for debugger memory display toolbar
//
static const VSDEBUG_MEMORY_FORM= "_tbdebug_memory_form";
defeventtab _tbdebug_memory_form;
void ctl_size.on_change()
{
   dbg_clear_memory();
   debug_gui_clear_memory();
   debug_gui_update_memory(false);
}
void ctl_address_combo.ENTER()
{
   if (!debug_active()) return;
   dbg_clear_memory();
   debug_gui_clear_memory();
   debug_gui_update_memory(true);
   _append_retrieve(_control ctl_address_combo,ctl_address_combo.p_text);
}
void ctl_address_combo.on_change(int reason)
{
   if (!debug_active()) return;
   if (reason == CHANGE_CLINE || reason==CHANGE_CLINE_NOTVIS) {
   } else if (reason == CHANGE_OTHER) {
   } else if (reason == CHANGE_SELECTED) {
   }
}
void ctl_address_combo.on_drop_down(int reason)
{
   if (reason==DROP_UP_SELECTED) {
      call_event(ctl_address_combo,ENTER);
   } else if (reason==DROP_INIT) {
      ctl_address_combo._retrieve_list();
   }
}
void _tbdebug_memory_form.'C-A'-'C-Z',F2-F4,f6-F12,C_F12,'c-a-a'-'c-a-z','a-0'-'a-9'()
{
   _smart_toolwindow_hotkey();
}
void _tbdebug_memory_form.'C-W',A_LEFT,A_RIGHT,A_UP()
{
   if (!_no_child_windows()) {
      p_window_id=_mdi.p_child;
      _set_focus();
   }
}
// put the text box into overstrike mode and position
// the cursor on the character they clicked on
void debug_memory_textbox_init()
{
   _insert_state(0);
   mou_get_xy(auto mx,auto my);
   _dxy2lxy(SM_TWIP, mx, my);
   _map_xy(0, p_window_id, mx, my, SM_TWIP);
   if (mx < 0) {
      mx = 0;
   } else if (mx > p_width) {
      mx = p_width;
   }
   num_width := _text_width("0");
   if (num_width > 0) {
      col := 1+ (mx intdiv num_width);
      _set_sel(col,col);
   }
}
void _tbdebug_memory_form.on_create()
{
   dbg_invalidate_views();

   // use same font as is the default for editor windows
   font := _default_font(CFG_WINDOW_TEXT);
   typeless font_name, font_size;
   parse font with font_name "," font_size "," .;
   ctl_memory_tree.p_font_name = font_name;
   ctl_memory_tree.p_font_size = (int) font_size;

   addr_width := ctl_memory_tree._text_width("0x87654321 ");
   ctl_memory_tree._TreeSetColButtonInfo(0,addr_width,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_FIXED_WIDTH,0,"Location");
   ctl_memory_tree._TreeSetColButtonInfo(1,10000,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_FIXED_WIDTH,0,"Content");
   ctl_memory_tree._TreeSetColEditStyle(1,TREE_EDIT_TEXTBOX);
   ctl_memory_tree._TreeSetColButtonInfo(2,-1,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_FIXED_WIDTH|TREE_BUTTON_AUTOSIZE,0,"Text");
   ctl_memory_tree._TreeSetColEditStyle(2,TREE_EDIT_TEXTBOX);
   ctl_memory_tree._TreeAdjustLastColButtonWidth(); 

   ctl_address_combo._retrieve_value();
   ctl_size._retrieve_value();
   ctl_memory_tree.p_user=0;
   ctl_memory_tree.p_EditInPlace=true;

   debug_pkg_enable_disable_tabs();
   debug_gui_update_memory();
   //ctl_memory_tree._TreeAdjustLastColButtonWidth();
   ctl_memory_tree._TreeRefresh();
//   ctl_memory_tree._TreeSetTextboxCreateFunction(debug_memory_textbox_init);

}
void ctl_address_combo.on_destroy()
{
   ctl_address_combo._append_retrieve(ctl_address_combo,ctl_address_combo.p_text);
   ctl_size._append_retrieve(ctl_size,ctl_size.p_text);
}
void _tbdebug_memory_form.on_change(int reason)
{ 
   if (reason==CHANGE_AUTO_SHOW ) {
      tree_wid := _find_control("ctl_memory_tree");
      if (tree_wid && tree_wid.p_user) {
         debug_gui_update_memory(true);
      }
   }
}
void _tbdebug_memory_form.on_got_focus()
{ 
   tree_wid := _find_control("ctl_memory_tree");
   if (tree_wid && tree_wid.p_user) {
      debug_gui_update_memory();
   }
}
void _tbdebug_memory_form.on_resize()
{
   _nocheck _control ctl_memory_tree;
   _nocheck _control ctl_address_combo;
   _nocheck _control ctl_size;
   debug_gui_resize_toolbar(0,ctl_memory_tree,0,ctl_address_combo,ctl_size);
   debug_gui_clear_memory();
   debug_gui_update_memory();
   bf := bs := 0;
   bc := "";
   ctl_memory_tree._TreeGetColButtonInfo(0,auto fw,bf,bs,bc);
   ctl_memory_tree._TreeGetColButtonInfo(1,auto bw,bf,bs,bc);
   nw := (ctl_memory_tree.p_width-fw)*2 intdiv 3;
   index := ctl_memory_tree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   if (index > 0) {
      caption := ctl_memory_tree._TreeGetCaption(index);
      if (substr(caption,1,2)=="0x") {
         parse caption with . "\t" caption "\t" . ;
         cw := ctl_memory_tree._text_width(" "caption" ");
         if (cw>nw) nw=cw;
      }
   }
   ctl_memory_tree._TreeSetColButtonInfo(1,nw);
   ctl_memory_tree._TreeAdjustLastColButtonWidth(); 
   ctl_memory_tree._TreeRefresh();
}
int ctl_memory_tree.on_change(int reason,int index)
{
   if (reason==CHANGE_SELECTED) {

   } else if (reason == CHANGE_EDIT_OPEN) {

   } else if (reason == CHANGE_EDIT_QUERY) {

      // memory editing is only supported for GDB
      session_id := dbg_get_current_session();
      return (int)debug_session_is_implemented("modify_memory");

   } else if (reason == CHANGE_EDIT_CLOSE) {

      // cancel if they wiped out all the text
      int col = arg(3);
      _str new_value = arg(4);
      if (new_value=="") {
         return(DELETED_ELEMENT_RC);
      }

      // massage the value depending on if it is hex or ascii
      if (col==1) {
         new_value = stranslate(new_value,""," ");
         new_value = stranslate(new_value,"","-");
      } else {
         // convert escaped string to hex
         hex_value := "";
         n := length(new_value);
         for (i:=1; i<=n; ++i) {
            ch := substr(new_value,i,1);
            if (ch=='\') {
               i++;
               ch = substr(new_value,i,1);
               switch (ch) {
               case "n":  hex_value :+= "0a"; break;
               case "r":  hex_value :+= "0e"; break;
               case "t":  hex_value :+= "09"; break;
               case "v":  hex_value :+= "0b"; break;
               case "0":  hex_value :+= "00"; break;
               case "1":  hex_value :+= "01"; break;
               case "2":  hex_value :+= "02"; break;
               case "3":  hex_value :+= "03"; break;
               case "4":  hex_value :+= "04"; break;
               case "5":  hex_value :+= "05"; break;
               case "6":  hex_value :+= "06"; break;
               case "7":  hex_value :+= "07"; break;
               case "8":  hex_value :+= "08"; break;
               case "9":  hex_value :+= "09"; break;
               case '\':  hex_value :+= "5c"; break;
               case "x":
                  hex_value :+= substr(new_value,i+1,2);
                  i+=2;
                  break;
               }
            } else {
               hex_value :+= _dec2hex(_asc(ch),16);
            }
         }
         new_value=hex_value;
      }

      // make sure all the digits are hex
      if (pos("^( |:h)*$",new_value,1,'r') != 1) {
         _message_box("Invalid characters: Expecting hexadecimal numbers only");
         return(-1);
      }

      // make sure they gave an even number of digits (corresponding to chars)
      if (length(stranslate(new_value,""," ")) % 2) {
         _message_box("Expecting an even number of digits");
         return(-1);
      }

      // dig up the original value
      line := _TreeGetCaption(index);
      parse line with auto address "\t" auto value "\t" auto text;
      if (col == 1) {
         value = stranslate(value,""," ");
         value = stranslate(value,"","-");
      } else {
         // convert string to hex, just to measure length
         value = "";
         n := length(text);
         for (i:=1; i<=n; ++i) {
            ch := substr(text,i,1);
            value :+= _dec2hex(_asc(ch),16);
         }
      }

      // make sure the length matches, prompt if not
      if (length(new_value) < length(value)) {
         answer := _message_box("Incomplete number of digits.  Continue anyway?","",MB_OKCANCEL|MB_ICONEXCLAMATION);
         if (answer != IDOK) {
            return(-1);
         }
      }
      if (length(new_value) > length(value)) {
         answer := _message_box("Data overruns this cell.  Continue anyway?","",MB_OKCANCEL|MB_ICONEXCLAMATION);
         if (answer != IDOK) {
            return(-1);
         }
      }

      // check if they didn't really modify the value
      if (new_value :== value) {
         answer := _message_box("Data appears unchanged.  Continue anyway?","",MB_OKCANCEL|MB_ICONEXCLAMATION);
         if (answer != IDOK) {
            return(DELETED_ELEMENT_RC);
         }
      }

      // now modify the memory
      session_id := dbg_get_current_session();
      status := dbg_session_modify_memory(session_id, address, new_value, length(new_value) intdiv 2);
      if (status) {
         debug_message("Error",status);
      }

      // and update all views
      dbg_clear_memory();
      dbg_clear_variables();
      debug_gui_update_all_vars();
      return(DELETED_ELEMENT_RC);
   }

   return(0);
}

/**
 * @return
 *    Return the window ID of the window containing the memory watches,
 *    address combo, and extend combo.
 */
CTL_FORM debug_gui_memory_wid()
{
   static CTL_FORM form_wid;

   if (_iswindow_valid(form_wid) && !form_wid.p_edit &&
       form_wid.p_object==OI_FORM && form_wid.p_name==VSDEBUG_MEMORY_FORM) {
      return(form_wid);
   }

   form_wid=_find_formobj(VSDEBUG_MEMORY_FORM,'N');
   return(form_wid);
}
static CTL_TREE debug_gui_memory_tree()
{
   CTL_FORM wid=debug_gui_memory_wid();
   return (wid? wid.ctl_memory_tree:0);
}
static void debug_gui_memory_params(_str &address, int &size)
{
   address=0;
   size=0;
   CTL_FORM wid=debug_gui_memory_wid();
   if (wid) {
      _nocheck _control ctl_address_combo;
      _nocheck _control ctl_size;
      address=wid.ctl_address_combo.p_text;

      str_size := strip(wid.ctl_size.p_text);
      typeless result = 0;
      status := eval_exp(result, str_size, 10);
      if (status == 0 && result >= 0) {
         size = (int)result;
      }
   }
}
void debug_set_memory_params(_str address, int size=0)
{
   if (!debug_active()) return;
   CTL_FORM wid=debug_gui_memory_wid();
   if (wid) {
      _nocheck _control ctl_address_combo;
      _nocheck _control ctl_size;
      if (!size && debug_is_suspended()) {
         thread_id := dbg_get_cur_thread();
         frame_id := dbg_get_cur_frame(thread_id);
         size_var := "";
         dereference_status := debug_pkg_eval_expression(thread_id,frame_id,"*("address")",size_var);
         if (dereference_status==DEBUG_EXPR_CANNOT_CAST_STRING_RC ||
             dereference_status==DEBUG_EXPR_CANNOT_CAST_OBJECT_RC) {
            dereference_status=0;
         }
         status := debug_pkg_eval_expression(thread_id,frame_id,"sizeof("address")",size_var);
         if (dereference_status) {
            address="&"address;
         } else {
            status=debug_pkg_eval_expression(thread_id,frame_id,"sizeof(*("address"))",size_var);
         }
         msize := (isinteger(wid.ctl_size.p_text) ? (int)wid.ctl_size.p_text : 0);
         vsize := (isinteger(size_var) ? (int)size_var : 0);
         if (!status && (msize < vsize)) {
            size=vsize;
         } else {
            size=msize;
         }
      } else if (isinteger(wid.ctl_size.p_text)) {
         size=(int)wid.ctl_size.p_text;
      } else {
         size = 0;
      }

      wid.ctl_address_combo.p_text=address;
      _append_retrieve(wid.ctl_address_combo,address);
      wid.ctl_size.p_text=size;
      dbg_clear_memory();
      debug_gui_clear_memory();
      if (debug_is_suspended()) {
         debug_gui_update_memory();
      }
   }
}
void debug_gui_clear_memory()
{
   CTL_TREE tree_wid=debug_gui_memory_tree();
   if (tree_wid) {
      tree_wid._TreeDelete(TREE_ROOT_INDEX,'c');
   }
}


///////////////////////////////////////////////////////////////////////////
// debugger toolbar update functions
//
// 
/**
 * Updates everything about the current debugger session.
 * <p>
 * This should be used only when switching sessions.
 */
int debug_gui_update_session()
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   debug_check_and_set_suspended();
   debug_gui_update_all();
   debug_gui_update_all_buttons();
   debug_gui_update_breakpoints(true);
   debug_gui_update_exceptions(true);
   debug_show_next_statement(true,0,0,"","",0,0);
   return 0;
}

/**
 * Update all the debug toolbars, except for the button bars
 */
int debug_gui_update_all(int thread_id=0, int frame_id=0, bool check_all_threads=true)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // first take care of the current session
   debug_gui_update_current_session();

   // make sure the current thread is up-to-date
   result := status := debug_pkg_update_current_thread();
   if (status < 0) {
      return status;
   }

   // first take care of the threads
   orig_thread_id := dbg_get_cur_thread();
   status = debug_gui_update_threads();
   if (status < 0) result = status;
   if (!thread_id || thread_id==orig_thread_id) {
      thread_id = dbg_get_cur_thread();
   }
   num_threads := dbg_get_num_threads();
   if (num_threads <= 0) {
      thread_id=0;
   } else if (thread_id <= 0 || thread_id > num_threads) {
      thread_id=1;
   }
   if (!frame_id) {
      frame_id=dbg_get_cur_frame(thread_id);
   }

   dbg_set_cur_thread(thread_id);
   status = debug_gui_update_cur_thread(thread_id);
   if (status < 0) result = status;
   if (!debug_is_dead_status(status)) {
      debug_check_and_set_suspended(true,check_all_threads);
      if (!thread_id || orig_thread_id==thread_id) {
         thread_id = dbg_get_cur_thread();
      }
      debug_log("debug_gui_update_all: suspended="debug_is_suspended());
   }

   if (!debug_is_dead_status(status) && debug_is_suspended()) {
      // now, if we have a thread, update the stack for it
      status = debug_gui_update_stack(thread_id,frame_id);
      if (status < 0) result = status;
      status = debug_gui_switch_frame(thread_id,frame_id);
      if (status < 0) result = status;

      // now update the non-frame specific toolbars
      status = debug_gui_update_registers(thread_id);
      if (status < 0) result = status;

      // now update the non-thread and non-frame specific toolbars
      status = debug_gui_update_memory();
      if (status < 0) result = status;
   }

   // update the suspended state and buttons
   debug_gui_update_suspended();
   debug_gui_update_all_buttons();

   // update the user views
   if (!debug_is_dead_status(status) && debug_is_suspended()) {
      debug_gui_update_user_views(VSDEBUG_UPDATE_ALL);
      debug_gui_update_user_views(VSDEBUG_UPDATE_USER);
   }

   // that's all folks
   return(result);
}

/**
 * Update all the variables displayed
 *
 * @param thread_id     current thread ID
 * @param frame_id      current frame ID
 */
int debug_gui_update_all_vars(int thread_id=0, int frame_id=0)
{
   if (!debug_active()) return(0);
   if (!debug_is_suspended()) return(0);
   if (gInUpdateThreadList || gInUpdateThread || gInUpdateFrame) {
      return(0);
   }
   if (!thread_id) {
      thread_id = dbg_get_cur_thread();
   }
   if (!frame_id) {
      frame_id=dbg_get_cur_frame(thread_id);
   }

   status := 0;
   if (!debug_is_dead_status(status)) {
      status = debug_gui_update_locals(thread_id,frame_id);
   }
   if (!debug_is_dead_status(status)) {
      status = debug_gui_update_members(thread_id,frame_id);
   }
   if (!debug_is_dead_status(status)) {
      status = debug_gui_update_autovars(thread_id,frame_id);
   }
   if (!debug_is_dead_status(status)) {
      tab_number := debug_gui_active_watches_tab();
      status = debug_gui_update_watches(thread_id,frame_id,tab_number);
   }
   if (!debug_is_dead_status(status)) {
      status = debug_gui_update_memory(true);
   }

   // static fields in the symbol browser may have changed
   if (!debug_is_dead_status(status)) {
      classes_wid := debug_gui_classes_tree();
      if (classes_wid) {
         classes_wid.debug_gui_reexpand_fields(TREE_ROOT_INDEX);
      }
   }

   // call the user views callback
   if (!debug_is_dead_status(status)) {
      debug_gui_update_user_views(VSDEBUG_UPDATE_VARIABLES);
   }

   // that's all folks
   refresh();
   return(status);
}

/**
 * Update the class tree view
 */
int debug_gui_update_classes(bool alwaysUpdate=false)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if ( !debug_is_suspended() && !alwaysUpdate ) {
      return(0);
   }

   CTL_FORM form_wid=debug_gui_classes_wid();
   isActive := alwaysUpdate || tw_is_wid_active(form_wid);

   status := 0;
   tree_wid := debug_gui_classes_tree();
   if (tree_wid && isActive) {
      status=debug_pkg_update_classes();
      if (status) {
         return(status);
      }

      cb_prepare_expand(0,tree_wid,TREE_ROOT_INDEX);
      expandedCaptions := tree_wid.debug_gui_save_expanded_captions(TREE_ROOT_INDEX, 0);
      tree_wid._TreeBeginUpdate(TREE_ROOT_INDEX);
      status=dbg_update_class_tree(tree_wid,TREE_ROOT_INDEX,null,!(tree_wid.p_prev.p_value));
      tree_wid._TreeEndUpdate(TREE_ROOT_INDEX);
      tree_wid._TreeSortCaption(TREE_ROOT_INDEX);
      tree_wid.debug_gui_reexpand_captions(TREE_ROOT_INDEX, expandedCaptions);
      tree_wid._TreeRefresh();
      tree_wid.p_user = 0;
   }

   if (tree_wid && !isActive) {
      tree_wid.p_user = 1;
   }

   // update the user views of the class tree
   if (debug_gui_query_user_views(VSDEBUG_UPDATE_CLASSES)) {
      status=debug_pkg_update_classes();
      if (status) {
         return(status);
      }

      debug_gui_update_user_views(VSDEBUG_UPDATE_CLASSES);
   }

   // that's all folks
   return(status);
}
/**
 * Update the currently selected thread
 */
int debug_gui_update_cur_thread(int thread_id)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // don't let this function be recursive
   if (gInUpdateThreadList || gInUpdateThread) {
      return(0);
   }
   gInUpdateThread=true;

   // update the threads tree, if we have one
   CTL_TREE tree_wid=debug_gui_threads_tree();
   if (tree_wid) {
      tree_index := tree_wid._TreeSearch(TREE_ROOT_INDEX,"",'T',thread_id);
      if (tree_index>0 && tree_index!=tree_wid._TreeCurIndex()) {
         tree_wid._TreeSetCurIndex(tree_index);
      }
      tree_wid._TreeSortCol();
   }

   list_wid := debug_gui_stack_thread_list();
   if (list_wid) {
      // get the thread name
      thread_name := "";
      thread_group := "";
      thread_flags := 0;
      status := dbg_get_thread(thread_id,thread_name,thread_group,thread_flags);
      // if we don't already know the thread name, update the thread names
      if (status || (thread_name == "" || thread_name == "main")) {
         orig_thread_id := dbg_get_cur_thread();
         debug_pkg_update_threads();
         if (!thread_id || thread_id==orig_thread_id) {
            thread_id = dbg_get_cur_thread();
         }
      }
      // get the thread name (again)
      status=dbg_get_thread(thread_id,thread_name,thread_group,thread_flags);
      if (status) {
         gInUpdateThread=false;
         return(status);
      }
      // set the thread caption in the stack toolbar
      gInUpdateThreadList=true;
      thread_caption := (thread_group!="")? thread_group"."thread_name : thread_name;
      list_wid._cbset_text(thread_caption);
      gInUpdateThreadList=false;
   }

   // update the user views of the stack
   debug_gui_update_user_views(VSDEBUG_UPDATE_CUR_THREAD);

   // that's all folks
   gInUpdateThread=false;
   return(0);
}

/**
 * Update the list of threads and current thread in all views
 */
int debug_gui_update_threads(bool alwaysUpdate=false)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // don't let this function be recursive
   if (gInUpdateThreadList) {
      return(0);
   }
   gInUpdateThreadList=true;

   // if the threads toolbar is not active, don't update yet
   form_wid := debug_gui_threads_wid();
   isActive := alwaysUpdate || tw_is_wid_active(form_wid);
   if (!form_wid) {
      gInUpdateThreadList=false;
      return(0);
   }

   // update the threads
   result := 0;
   status := debug_pkg_update_threads();
   if (status) {
      result=status;
   } else {
      if (isActive) {
         status=debug_pkg_update_threadgroups();
         if (status) {
            result=status;
         }
      }
   }

   // update the thread list
   CTL_TREE tree_wid=debug_gui_threads_tree();
   if (tree_wid && isActive) {
      // save the original caption prefix
      caption := thread_name := group_name := "";
      tree_index := tree_wid._TreeCurIndex();
      if (tree_index > 0) {
         caption=tree_wid._TreeGetCaption(tree_index);
         parse caption with thread_name "\t" group_name "\t" . ;
         caption=thread_name "\t" group_name "\t";
      }
      // now update the list
      tree_wid._TreeBeginUpdate(TREE_ROOT_INDEX);
      status=dbg_update_thread_tree(tree_wid, TREE_ROOT_INDEX);
      tree_wid._TreeEndUpdate(TREE_ROOT_INDEX);
      // reset the current item if we had one
      if (caption!="") {
         tree_index=tree_wid._TreeSearch(TREE_ROOT_INDEX,caption,'TP');
         if (tree_index>0 && tree_index!=tree_wid._TreeCurIndex()) {
            tree_wid._TreeSetCurIndex(tree_index);
         }
      } else {
         thread_id := dbg_get_cur_thread();
         tree_index=tree_wid._TreeSearch(TREE_ROOT_INDEX,"",'TP',thread_id);
         if (tree_index>0 && tree_index!=tree_wid._TreeCurIndex()) {
            tree_wid._TreeSetCurIndex(tree_index);
         }
      }
      tree_wid._TreeSortCol();
      tree_wid._TreeRefresh();
      tree_wid.p_user = 0;
   }

   if (tree_wid && !isActive) {
      tree_wid.p_user = 1;
   }

   // update the user thread views
   if (!debug_is_dead_status(status)) {
      debug_gui_update_user_views(VSDEBUG_UPDATE_THREADS);
   }

   // that's all folks
   gInUpdateThreadList=false;
   return(result);
}
/**
 * Update the list of breakpoints in all views
 */
int debug_gui_update_breakpoints(bool updateEditor=false)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   CTL_TREE tree_wid=debug_gui_breakpoints_tree();
   if (tree_wid) {
      tree_wid._TreeBeginUpdate(TREE_ROOT_INDEX);
      dbg_update_breakpoints_tree(tree_wid,TREE_ROOT_INDEX,
                                  _strip_filename(_project_name,'N'),
                                  -1,-1);
      // DJB 05/20/2005 -- have to force enable/disable states
      //                -- because tree insert in update will not
      //                -- guarrantee tree node state changes
      n := dbg_get_num_breakpoints();
      for (i:=1; i<=n; ++i) {
         enabled := dbg_get_breakpoint_enabled(i);
         checkState := (enabled==0)? TCB_UNCHECKED:TCB_CHECKED;
         if (enabled==1) checkState = TCB_PARTIALLYCHECKED;
         tree_index := tree_wid._TreeSearch(TREE_ROOT_INDEX,"","",i);
         if (tree_index > 0) {
            tree_wid._TreeSetCheckState(tree_index,checkState);
         }
      }
      tree_wid._TreeEndUpdate(TREE_ROOT_INDEX);
      tree_wid._TreeSortCol();
      tree_wid._TreeRefresh();
      debug_gui_breakpoints_update_buttons();
   }

   // update the bitmaps in the editor controls
   status := 0;
   if (updateEditor) {
      status=dbg_update_editor_breakpoints();
   }

   // update user views of the breakpoints
   debug_gui_update_user_views(VSDEBUG_UPDATE_BREAKPOINTS);

   return(status);
}
/**
 * Update the highlighted breakpoint in the breakpoint list
 */
int debug_gui_update_current_breakpoint(int breakpoint_id)
{
   CTL_TREE tree_wid=debug_gui_breakpoints_tree();
   if (tree_wid) {
      tree_index := tree_wid._TreeSearch(TREE_ROOT_INDEX,"","",breakpoint_id);
      if (tree_index > 0) tree_wid._TreeSetCurIndex(tree_index);
   }
   return 0;
}
/**
 * Update the list of exceptions in all views
 */
int debug_gui_update_exceptions(bool updateEditor=false)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   CTL_TREE tree_wid=debug_gui_exceptions_tree();
   if (tree_wid) {
      tree_wid._TreeBeginUpdate(TREE_ROOT_INDEX);
      dbg_update_exceptions_tree(tree_wid,TREE_ROOT_INDEX,
                                 -1,-1);
      tree_wid._TreeEndUpdate(TREE_ROOT_INDEX);
      tree_wid._TreeSortCol();
      tree_wid._TreeRefresh();
   }

   // update user views of the exceptions
   debug_gui_update_user_views(VSDEBUG_UPDATE_EXCEPTIONS);

   return(0);
}
/**
 * Update the stack and the current frame in all views
 *
 * @param thread_id     Current thread ID
 */
int debug_gui_update_stack(int thread_id, int frame_id=0)
{
   if (!debug_active()) return(0);
   if (!debug_is_suspended()) return(0);
   if (gInUpdateThreadList || gInUpdateThread) {
      return(0);
   }

   result := 0;
   status := 0;
   if (debug_gui_stack_tree() == 0 && frame_id == 1) {
      status = debug_pkg_update_stack_top(thread_id);
   } else {
      status = debug_pkg_update_stack(thread_id);
   }
   if (status) {
      result=status;
   }

   // update the source file paths for each stack frame
   num_frames := dbg_get_num_frames(thread_id);
   for (frame_id=1; frame_id<=num_frames; ++frame_id) {
      // get the details about the current method
      method_name := signature := return_type := class_name := file_name := address := "";
      line_number := 0;
      status=dbg_get_frame(thread_id, frame_id, method_name, signature, return_type, class_name, file_name, line_number, address);
      if (status) {
         continue;
      }
      // no source code or debug information
      if (file_name=="" || line_number<0) {
         continue;
      }
      // Attempt to resolve the path to 'file_name'
      if (file_name != absolute(file_name)) {
         full_path := debug_resolve_or_prompt_for_path(file_name,class_name,method_name,true);
         if (full_path!="") {
            dbg_set_frame_path(thread_id,frame_id,full_path);
         }
      }
   }

   CTL_TREE tree_wid=debug_gui_stack_tree();
   if (tree_wid) {
      tree_wid._TreeBeginUpdate(TREE_ROOT_INDEX);
      status=dbg_update_stack_tree(tree_wid, TREE_ROOT_INDEX, thread_id);
      tree_wid._TreeEndUpdate(TREE_ROOT_INDEX);
      tree_wid._TreeSortUserInfo(TREE_ROOT_INDEX,'N');
      if (status) result=status;
      if (result) {
         tree_wid.debug_tree_message(result);
      }
      debug_gui_stack_update_buttons();
      tree_wid._TreeRefresh();
   }

   // update the user views of the stack
   if (!debug_is_dead_status(status)) {
      debug_gui_update_user_views(VSDEBUG_UPDATE_STACK);
   }

   // that's all folks
   return(result);
}
/**
 * Update the stack and the current frame in all views
 *
 * @param thread_id     Current thread ID
 * @param frame_id      Current frame ID
 */
int debug_gui_update_cur_frame(int thread_id, int frame_id)
{
   // don't let this function be recursive
   if (!debug_active()) return(0);
   if (!debug_is_suspended()) return(0);
   if (gInUpdateThreadList /*|| gInUpdateThread*/ || gInUpdateFrame) {
      return(0);
   }
   gInUpdateFrame=true;

   // update the stack
   if (frame_id == 1) {
      debug_pkg_update_stack_top(thread_id);
   } else {
      debug_pkg_update_stack(thread_id);
   }

   // update the bitmaps in the editor controls
   if (_isEditorCtl()) {
      dbg_update_editor_stack(thread_id,frame_id);
   } else {
      _mdi.p_child.dbg_update_editor_stack(thread_id,frame_id);
   }

   // update the stack tree, if we have one
   CTL_TREE tree_wid=debug_gui_stack_tree();
   if (tree_wid) {
      tree_index := tree_wid._TreeSearch(TREE_ROOT_INDEX,"",'T',frame_id);
      if (tree_index>0 && tree_index!=tree_wid._TreeCurIndex()) {
         tree_wid._TreeSetCurIndex(tree_index);
      }
   }

   method_name := "";
   signature := "";
   return_type := "";
   class_name := "";
   file_name := "";
   address := "";
   line_number := 0;
   status := dbg_get_frame(thread_id,frame_id,method_name,signature,return_type,class_name,file_name,line_number,address);
   if (status) {
      gInUpdateFrame=false;
      return(status);
   }
   frame_caption := method_name"("signature")";

   CTL_COMBO list_wid=debug_gui_local_stack_list();
   if (list_wid) {
      list_wid._cbset_text(frame_caption);
      list_wid._lbselect_line();
   }

   list_wid=debug_gui_members_stack_list();
   if (list_wid) {
      list_wid._cbset_text(frame_caption);
      list_wid._lbselect_line();
   }

   list_wid=debug_gui_auto_stack_list();
   if (list_wid) {
      list_wid._cbset_text(frame_caption);
      list_wid._lbselect_line();
   }

   // attempt to resolve the paths in the frame
   paths_changed := false;
   n := dbg_get_num_frames(thread_id);
   for (i:=1; i<=n; ++i) {
      status=dbg_get_frame(thread_id,i,method_name,signature,return_type,class_name,file_name,line_number,address);
      if (status) {
         gInUpdateFrame=false;
         return(status);
      }
      if (file_name!="" && line_number>=0 && file_name!=absolute(file_name)) {
         full_path := debug_resolve_or_prompt_for_path(file_name,class_name,method_name,true);
         if (full_path!="") {
            //say("debug_gui_update_editor: setting path to file="file_name" full="full_path" thread="thread_id" frame="i);
            paths_changed=true;
            dbg_set_frame_path(thread_id,i,full_path);
         }
      }
   }

   // update the bitmaps in the editor controls
   if (paths_changed) {
      if (_isEditorCtl()) {
         dbg_update_editor_stack(thread_id,frame_id);
      } else {
         _mdi.p_child.dbg_update_editor_stack(thread_id,frame_id);
      }
   }

   // update the user views of the stack
   debug_gui_update_user_views(VSDEBUG_UPDATE_CUR_FRAME);

   // that's all folks
   gInUpdateFrame=false;
   return(status);
}
/**
 * Update the disassembly for the current stack frame.
 * <p>
 * The current object is expected to be an editor control.
 * Otherwise, it will attempt to use _mdi.p_child.
 */
int debug_gui_update_disassembly()
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (!debug_active()) return(0);
   if (!debug_is_suspended()) return(0);
   if (gInUpdateThreadList || gInUpdateThread || gInUpdateFrame) {
      return(0);
   }

   // TBF
   if (!_isEditorCtl()) {
      if (_no_child_windows()) {
         return(0);
      }
      return _mdi.p_child.debug_gui_update_disassembly();
   }

   // update the disassembly
   status := dbg_update_disassembly(p_window_id, p_buf_name);

   // update the editor stack
   thread_id := dbg_get_cur_thread();
   frame_id := dbg_get_cur_frame(thread_id);
   dbg_update_editor_stack(thread_id, frame_id);
   dbg_update_editor_breakpoints();

   // maybe update the user views of the disassembly
   if (!debug_is_dead_status(status)) {
      if (debug_gui_query_user_views(VSDEBUG_UPDATE_DISASSEMBLY)) {
         debug_gui_update_user_views(VSDEBUG_UPDATE_DISASSEMBLY);
      }
   }

   // that's all folks
   return(status);
}
/**
 * Clear the disassembly from all open buffers.
 */
int debug_gui_clear_disassembly()
{
   if (!_haveDebugging()) {
      return 0;
   }
   // make sure the current object is an editor control
   if (!_isEditorCtl()) {
      if (_no_child_windows()) {
         return 0;
      }
      return _mdi.p_child.debug_gui_clear_disassembly();
   }

   // Removes files from list that have been autosaved or will be autosaved
   orig_wid := p_window_id;
   activate_window(VSWID_HIDDEN);
   _safe_hidden_window();
   orig_buf_id := p_buf_id;
   for (;;) {
      dbg_clear_editor_disassembly(p_window_id, p_buf_name);
      _next_buffer('hr');
      if (p_buf_id == orig_buf_id) {
         break;
      }
   }

   // that's all folks
   activate_window(orig_wid);
   return 0;
}

/**
 * Update the list of locals in all views.
 *
 * @param thread_id     current thread ID
 * @param frame_id      current frame ID
 * @param alwaysUpdate  update even if the toolbar is hidden
 */
int debug_gui_update_locals(int thread_id, int frame_id, bool alwaysUpdate=false)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (!debug_active()) return(0);
   if (!debug_is_suspended()) return(0);
   if (gInUpdateThreadList || gInUpdateThread || gInUpdateFrame) {
      return(0);
   }

   CTL_FORM form_wid = debug_gui_locals_wid();
   isActive := alwaysUpdate || tw_is_wid_active(form_wid);

   status := 0;
   CTL_TREE tree_wid1=debug_gui_locals_tree();
   if (tree_wid1 && isActive) {
      status=debug_pkg_update_locals(thread_id,frame_id);
      if (status) {
         return tree_wid1.debug_tree_message(status);
      }
      expandedCaptions := tree_wid1.debug_gui_save_expanded_captions(TREE_ROOT_INDEX, 0);
      tree_wid1._TreeBeginUpdate(TREE_ROOT_INDEX);
      status=dbg_update_locals_tree(tree_wid1, TREE_ROOT_INDEX, thread_id, frame_id, null);
      tree_wid1._TreeEndUpdate(TREE_ROOT_INDEX);
      //tree_wid1._TreeSortCaption(TREE_ROOT_INDEX);
      tree_wid1._TreeSortUserInfo(TREE_ROOT_INDEX,'N');
      tree_wid1.debug_gui_reexpand_captions(TREE_ROOT_INDEX, expandedCaptions);
      tree_wid1.debug_warn_if_empty();
      tree_wid1._TreeRefresh();
      tree_wid1.p_user=0;
   }

   // indicate that an update is necessary
   if (tree_wid1 && !isActive) {
      tree_wid1.p_user=1;
   }

   // update the user views of the local variables
   if (debug_gui_query_user_views(VSDEBUG_UPDATE_LOCALS)) {
      status=debug_pkg_update_locals(thread_id,frame_id);
      debug_gui_update_user_views(VSDEBUG_UPDATE_LOCALS);
   }

   // that's all folks
   return(status);
}

/**
 * Update the list of members in all views.
 *
 * @param thread_id     current thread ID
 * @param frame_id      current frame ID
 * @param alwaysUpdate  update even if the toolbar is hidden
 */
int debug_gui_update_members(int thread_id, int frame_id, bool alwaysUpdate=false)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (!debug_active()) return(0);
   if (!debug_is_suspended()) return(0);
   if (gInUpdateThreadList || gInUpdateThread || gInUpdateFrame) {
      return(0);
   }

   CTL_FORM form_wid = debug_gui_members_wid();
   isActive := alwaysUpdate || tw_is_wid_active(form_wid);

   status := 0;
   CTL_TREE tree_wid1=debug_gui_members_tree();
   if (tree_wid1 && isActive) {
      status=debug_pkg_update_members(thread_id,frame_id);
      if (status) {
         return tree_wid1.debug_tree_message(status);
      } 
      expandedCaptions := tree_wid1.debug_gui_save_expanded_captions(TREE_ROOT_INDEX, 0);
      tree_wid1._TreeBeginUpdate(TREE_ROOT_INDEX);
      status=dbg_update_members_tree(tree_wid1, TREE_ROOT_INDEX, thread_id, frame_id, null);
      tree_wid1._TreeEndUpdate(TREE_ROOT_INDEX);
      //tree_wid1._TreeSortCaption(TREE_ROOT_INDEX);
      tree_wid1._TreeSortUserInfo(TREE_ROOT_INDEX,'N');
      tree_wid1.debug_gui_reexpand_captions(TREE_ROOT_INDEX, expandedCaptions);
      tree_wid1.debug_warn_if_empty();
      tree_wid1._TreeRefresh();
      tree_wid1.p_user = 0;
   }

   if (tree_wid1 && !isActive) {
      tree_wid1.p_user = 1;
   }

   // call the user views callback
   if (debug_gui_query_user_views(VSDEBUG_UPDATE_MEMBERS)) {
      status=debug_pkg_update_members(thread_id,frame_id);
      debug_gui_update_user_views(VSDEBUG_UPDATE_MEMBERS);
   }

   // that's all folks
   return(status);
}
/**
 * Update the automatic variable watches in all views.
 *
 * @param thread_id     current thread ID
 * @param frame_id      current frame ID
 * @param alwaysUpdate  update even if the toolbar is hidden
 */
int debug_gui_update_autovars(int thread_id, int frame_id, bool alwaysUpdate=false)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (!debug_active()) return(0);
   if (!debug_is_suspended()) return(0);
   if (gInUpdateThreadList || gInUpdateThread || gInUpdateFrame) {
      return(0);
   }

   CTL_FORM form_wid=debug_gui_autovars_wid();
   isActive := alwaysUpdate || tw_is_wid_active(form_wid);

   CTL_TREE tree_wid=debug_gui_autovars_tree();
   if (tree_wid && isActive) {
      status := debug_pkg_update_autos(thread_id, frame_id);
      if (status) {
         return tree_wid.debug_tree_message(status);
      }

      expandedCaptions := tree_wid.debug_gui_save_expanded_captions(TREE_ROOT_INDEX, 0);
      tree_wid._TreeBeginUpdate(TREE_ROOT_INDEX);
      status=dbg_update_autos_tree(tree_wid, TREE_ROOT_INDEX, thread_id, frame_id, null);
      tree_wid._TreeEndUpdate(TREE_ROOT_INDEX);
      //tree_wid._TreeSortCaption(TREE_ROOT_INDEX);
      tree_wid._TreeSortUserInfo(TREE_ROOT_INDEX,'N');
      tree_wid.debug_gui_reexpand_captions(TREE_ROOT_INDEX, expandedCaptions);
      tree_wid.debug_warn_if_empty();
      tree_wid._TreeRefresh();
      tree_wid.p_user = 0;
   }

   if (tree_wid && !isActive) {
      tree_wid.p_user = 1;
   }

   // call the user views callback
   if (debug_gui_query_user_views(VSDEBUG_UPDATE_AUTOVARS)) {
      debug_pkg_update_autos(thread_id, frame_id);
      debug_gui_update_user_views(VSDEBUG_UPDATE_AUTOVARS);
   }

   // that's all folks
   return(0);
}

/**
 * Build a table of what fields are currently expanded in the tree, 
 * starting from the tree index passed in.  This only looks at the 
 * first column of the tree for the caption information. 
 *  
 * @return Returns a hash table of expanded captions, as needed 
 *         by debug_gui_reexpand_captions. 
 * 
 * @param index               tree node index
 */
static typeless debug_gui_save_expanded_captions(int index, int column=-1)
{
   typeless expandedCaptions:[] = null;
   show_children := 0;
   child := _TreeGetFirstChildIndex(index);
   while (child > 0) {
      _TreeGetInfo(child, show_children);
      if (show_children > 0) {
         caption := _TreeGetCaption(child, column);
         expandedCaptions:[caption] = debug_gui_save_expanded_captions(child, column);
      }
      child = _TreeGetNextSiblingIndex(child);
   }
   return expandedCaptions;
}

/** 
 * Re-expand tree nodes that were previously expanded in this tree. 
 *  
 * @param index               tree node index 
 * @param expandedCaptions    hash table of captions created by 
 *                            debug_gui_save_expanded_captions() 
 */ 
static void debug_gui_reexpand_captions(int index, typeless (&expandedCaptions):[])
{
   if (expandedCaptions != null) {
      show_children := 0;
      child := _TreeGetFirstChildIndex(index);
      while (child > 0) {
         _TreeGetInfo(child, show_children);
         if (show_children >= 0) {
            caption := _TreeGetCaption(child,0);
            if (expandedCaptions._indexin(caption)) {
               if (show_children == 0) _TreeSetInfo(child, 1);
               call_event(CHANGE_EXPANDED,child,p_window_id,ON_CHANGE,'w');
               debug_gui_reexpand_captions(child, expandedCaptions:[caption]);
            }
         }
         child = _TreeGetNextSiblingIndex(child);
      }
   }
}

/**
 * Update the active watch tab.
 *
 * @param thread_id     current thread ID
 * @param frame_id      current frame ID
 * @param tab_number    which watches tab to update
 * @param in_place      update the watches in place or refresh whole tree?
 * @param alwaysUpdate  update even if the toolbar is hidden
 */
int debug_gui_update_watches(int thread_id, int frame_id, int tab_number,
                             bool in_place=false, bool alwaysUpdate=false)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (!debug_active()) return(0);
   //if (!debug_is_suspended()) return(0);
   if (gInUpdateThreadList || gInUpdateThread || gInUpdateFrame) {
      return(0);
   }

   form_wid := debug_gui_watches_wid();
   isActive := alwaysUpdate || tw_is_wid_active(form_wid);

   tree_wid := debug_gui_watches_tree();
   if (tree_wid && isActive) {

      status := 0;
      if (debug_is_suspended()) {
         status=debug_pkg_update_watches(thread_id, frame_id, tab_number);
         if (status) {
            return tree_wid.debug_tree_message(status);
         }
      }

      if (in_place) {
         // whether we have a place for the variable type
         displayType := debug_session_is_implemented("display_var_types");
         // update the watch values in place (no new members, just change captions)
         index := tree_wid._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
         while (index > 0) {
            watch_id := tree_wid._TreeGetUserInfo(index);
            if (watch_id > 0) {
               expandable := show_children := base := 0;
               expr := context_name := value := raw_value := type := "";
               dbg_get_watch(thread_id,frame_id,watch_id,tab_number,expr,context_name,value,expandable,base,raw_value,type);
               caption := expr"\t";
               if (!displayType || value != type) {
                  caption :+= value;
               }
               caption :+= "\t"context_name;
               if (displayType) {
                  caption :+= "\t"type;
               }
               tree_wid._TreeSetCaption(index,caption);
               tree_wid._TreeGetInfo(index,show_children);
               if (!expandable) {
                  tree_wid._TreeSetInfo(index,-1);
               } else if (show_children < 0) {
                  tree_wid._TreeSetInfo(index,0);
               } else {
                  // don't change tree info
               }
            }
            index=tree_wid._TreeGetNextSiblingIndex(index);
         }
      } else {
         // update it allowing for new members
         expandedCaptions := tree_wid.debug_gui_save_expanded_captions(TREE_ROOT_INDEX, 0);
         tree_wid._TreeBeginUpdate(TREE_ROOT_INDEX);
         status=dbg_update_watches_tree(tree_wid, TREE_ROOT_INDEX, thread_id, frame_id, tab_number, null);
         tree_wid._TreeEndUpdate(TREE_ROOT_INDEX);
         tree_wid._TreeSortUserInfo(TREE_ROOT_INDEX,'N');
         add_index := tree_wid._TreeAddItem(TREE_ROOT_INDEX,DEBUG_ADD_WATCH_CAPTION,TREE_ADD_AS_CHILD,0,0,-1,TREENODE_BOLD,-1);
         tree_wid.debug_gui_reexpand_captions(TREE_ROOT_INDEX, expandedCaptions);
      }
      tree_wid._TreeRefresh();
      tree_wid.p_user = 0;
   }

   if (tree_wid && !isActive) {
      tree_wid.p_user = 1;
   }

   // update the user views of the watches
   if (debug_gui_query_user_views(VSDEBUG_UPDATE_WATCHES) && debug_is_suspended()) {
      debug_pkg_update_watches(thread_id, frame_id, tab_number);
      debug_gui_update_user_views(VSDEBUG_UPDATE_WATCHES);
   }

   // that's all folks
   return(0);
}

/**
 * Update the registers view
 */
int debug_gui_update_registers(int thread_id, bool alwaysUpdate=false)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (!debug_active()) return(0);
   if (gInUpdateThreadList || gInUpdateThread || gInUpdateFrame) {
      return(0);
   }
   if ( !debug_is_suspended() && !alwaysUpdate ) {
      return(0);
   }

   CTL_FORM form_wid=debug_gui_registers_wid();
   isActive := alwaysUpdate || tw_is_wid_active(form_wid);

   CTL_TREE tree_wid=debug_gui_registers_tree();
   if (tree_wid && isActive) {
      status := debug_pkg_update_registers(thread_id);
      if (status) {
         return tree_wid.debug_tree_message(status);
      }

      tree_wid._TreeBeginUpdate(TREE_ROOT_INDEX);
      status=dbg_update_registers_tree(tree_wid, TREE_ROOT_INDEX, thread_id);
      tree_wid._TreeEndUpdate(TREE_ROOT_INDEX);
      tree_wid._TreeSortCol();
      tree_wid._TreeRefresh();
      tree_wid.p_user=0;
   }

   if (tree_wid && !isActive) {
      tree_wid.p_user=1;
   }

   // update the user views of the registers
   if (debug_gui_query_user_views(VSDEBUG_UPDATE_REGISTERS)) {
      debug_pkg_update_registers(thread_id);
      debug_gui_update_user_views(VSDEBUG_UPDATE_REGISTERS);
   }

   // that's all folks
   return(0);
}

/**
 * Update all the debug toolbars, except for the button bars
 */
int debug_gui_update_memory(bool alwaysUpdate=false)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (!debug_active()) return(0);
   if (gInUpdateThreadList || gInUpdateThread || gInUpdateFrame) {
      return(0);
   }
   if ( !debug_is_suspended() && !alwaysUpdate ) {
      return(0);
   }

   CTL_FORM form_wid=debug_gui_memory_wid();
   isActive := alwaysUpdate || tw_is_wid_active(form_wid);

   CTL_TREE tree_wid=debug_gui_memory_tree();
   if (tree_wid && isActive) {

      address := "";
      size := 0;
      debug_gui_memory_params(address,size);
      dbg_clear_memory();
      status := debug_pkg_update_memory(address,size);
      if (status) {
         return tree_wid.debug_tree_message(status);
      }

      cur_line := tree_wid._TreeScroll();
      tree_wid._TreeBeginUpdate(TREE_ROOT_INDEX);
      status=dbg_update_memory_tree(tree_wid, TREE_ROOT_INDEX);
      tree_wid._TreeEndUpdate(TREE_ROOT_INDEX);
      tree_wid._TreeSortCaption(TREE_ROOT_INDEX);
      if (size > 0 && tree_wid._TreeGetNumChildren(TREE_ROOT_INDEX)==0) {
         msg :=  "Error" :+ "\t";
         if (status < 0) {
            msg :+= get_message(status);
         } else {
            msg :+= "No memory visible at this location.";
         }
         index := tree_wid._TreeAddItem(TREE_ROOT_INDEX,msg,TREE_ADD_AS_CHILD,0,0,-1,0,0);
      }
      tree_wid._TreeScroll(cur_line);
      tree_wid._TreeSizeColumnToContents(0);
      tree_wid._TreeRefresh();
      tree_wid.p_user=0;
   }

   if (tree_wid && !isActive) {
      tree_wid.p_user=1;
   }

   // call the user view for updating memory
   debug_gui_update_user_views(VSDEBUG_UPDATE_MEMORY);

   // that's all folks
   return(0);
}

/**
 * Update *all* the button bars
 */
void debug_gui_update_all_buttons()
{
   _tbSetRefreshBy(VSTBREFRESHBY_DEBUGGING);
   if (!_haveDebugging()) return;
   debug_gui_stack_update_buttons();
   debug_gui_breakpoints_update_buttons();

   // make sure the editor stack is update to date
   thread_id := dbg_get_cur_thread();
   if (debug_is_suspended() || dbg_get_num_frames(thread_id) > 0) {
      frame_id := dbg_get_cur_frame(thread_id);
      if (_isEditorCtl()) {
         dbg_update_editor_stack(thread_id,frame_id);
      } else {
         _mdi.p_child.dbg_update_editor_stack(thread_id,frame_id);
      }
   }

   // update the user views if they have buttons to enable/disable
   debug_gui_update_user_views(VSDEBUG_UPDATE_BUTTONS);

   // update everything on the button bar
   if (_autoRestoreFinished()) {
      _tbOnUpdate(true);
   }
}

/**
 * Single function for efficiently switching the current frame
 */
int debug_gui_switch_frame(int thread_id, int frame_id)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   //mou_hour_glass(true);
   num_frames := dbg_get_num_frames(thread_id);
   if (frame_id <= 0 || frame_id > num_frames) {
      frame_id=(num_frames > 0)? 1:0;
   }
   if (frame_id > 0) {
      dbg_set_cur_frame(thread_id,frame_id);
   }

   // update everything that depends on the thread and frame
   status := debug_gui_update_cur_frame(thread_id,frame_id);
   debug_gui_update_all_buttons();

   if (!debug_is_dead_status(status)) {
      status = debug_gui_update_autovars(thread_id,frame_id);
   }
   if (!debug_is_dead_status(status)) {
      status = debug_gui_update_locals(thread_id,frame_id);
   }
   if (!debug_is_dead_status(status)) {
      status = debug_gui_update_members(thread_id,frame_id);
   }
   if (!debug_is_dead_status(status)) {
      tab_number := debug_gui_active_watches_tab();
      status = debug_gui_update_watches(thread_id,frame_id,tab_number);
   }

   // static fields in the symbol browser may have changed
   if (!debug_is_dead_status(status)) {
      classes_wid := debug_gui_classes_tree();
      if (classes_wid) {
         classes_wid.debug_gui_reexpand_fields(TREE_ROOT_INDEX);
      }
   }

   //mou_hour_glass(false);
   return(status);
}

/**
 * Disable combo boxes when suspended.
 */
void debug_gui_update_suspended()
{
   // disable threads combo boxes if we don't have threads support
   list_wid := debug_gui_stack_thread_list();
   if (list_wid) {
      list_wid.p_enabled=debug_is_suspended();
   }

   // enable thread combo boxes if we have an "update_stack" callback
   list_wid=debug_gui_local_stack_list();
   if (list_wid) {
      list_wid.p_enabled=debug_is_suspended();
   }
   list_wid=debug_gui_members_stack_list();
   if (list_wid) {
      list_wid.p_enabled=debug_is_suspended();
   }
   list_wid=debug_gui_auto_stack_list();
   if (list_wid) {
      list_wid.p_enabled=debug_is_suspended();
   }

   // update the user views
   debug_gui_update_user_views(VSDEBUG_UPDATE_SUSPENDED);
}

/**
 * Update all the user registered views
 */
void debug_gui_update_user_views(int reason)
{
   // no user view callbacks to update?
   if (!debug_gui_query_user_views(reason)) {
      return;
   }

   // OK, fine, call the update functions
   gInUpdateUserViews=true;
   n := gUserViewList._length();
   for (i:=0; i<n; ++i) {
      (*gUserViewList[i])(reason);
   }
   gInUpdateUserViews=false;
}
/**
 * Check if we need to update the user views for a given reason code
 */
bool debug_gui_query_user_views(int reason)
{
   // no user view callbacks to update?
   if (gUserViewList==null)        return false;
   if (gUserViewList._length()==0) return false;

   // User query function if they have one
   if (gUserViewQuery!=null) {
      return ((*gUserViewQuery)(reason) != 0);
   }

   // no query function, so assume things must be called
   return true;
}
/**
 * Remove all the user registered views
 */
void debug_gui_remove_update_callbacks()
{
   gUserViewQuery=null;
   gUserViewList._makeempty();
}
/**
 * Add a new user view update method.
 * You may register multiple update callback functions.
 */
void debug_gui_add_update_callback(VSDEBUG_UPDATE_CALLBACK pfn)
{
   gUserViewList[gUserViewList._length()]=pfn;
}
/**
 * Remove an existing user view update method.
 */
void debug_gui_remove_update_callback(VSDEBUG_UPDATE_CALLBACK pfn)
{
   numCallbacks := gUserViewList._length();
   for (i := 0; i < numCallbacks; i++) {
      if (gUserViewList[i] == pfn) {
         gUserViewList._deleteel(i);
      }
   }
}
/**
 * Add a new user view update method
 * <p>
 * You may only register one query callback function.
 * <p>
 * The query callback function should return '1' if
 * the corresponding update callback needs to be called,
 * '0' otherwise.
 */
void debug_gui_add_query_callback(VSDEBUG_UPDATE_CALLBACK pfn)
{
   gUserViewQuery=pfn;
}

static int AddBasesToMenu(int menu_handle)
{
   int base_list[];
   dbg_get_supported_format_list(base_list);
   AddGlobalBasesToMenu(menu_handle,base_list);
   AddLocalBasesToMenu(menu_handle,base_list);
   return(0);
}

static int AddGlobalBasesToMenu(int menu_handle,int (&base_list)[])
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   submenu_handle := 0;
   menu_pos := _menu_find_loaded_menu_caption(menu_handle,"View variable as",submenu_handle);
   //say("AddGlobalBasesToMenu: menu_pos="menu_pos);
   global_base := dbg_get_global_format();
   foreach (auto b in base_list) {
      flags := 0;
      if (b == VSDEBUG_BASE_UNICODE_TEXT || b == VSDEBUG_BASE_DEFAULT_FLOAT || b == VSDEBUG_BASE_DEFAULT) {
         _menu_insert(menu_handle,++menu_pos,flags,'-');
      }
      if (b <= VSDEBUG_BASE_NUMBER_MASK) {
         if ((global_base & VSDEBUG_BASE_NUMBER_MASK) == b) flags |= MF_CHECKED;
      } else if ( (global_base & b) == b ) {
         flags |= MF_CHECKED;
      } else if (b == VSDEBUG_BASE_DEFAULT_FLOAT && !(global_base & VSDEBUG_BASE_FLOAT_MASK)) {
         flags |= MF_CHECKED;
      } else if (b == VSDEBUG_BASE_UNICODE_TEXT && !(global_base & VSDEBUG_BASE_STRING_MASK)) {
         flags |= MF_CHECKED;
      }
      cur_base_name := dbg_get_format_name(b);
      _menu_insert(menu_handle,++menu_pos,flags,cur_base_name,"debug_set_global_base ":+b);
   }
   return(0);
}

static int AddLocalBasesToMenu(int menu_handle,int (&base_list)[])
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   submenu_handle := 0;
   menu_pos := _menu_find_loaded_menu_caption(menu_handle,"View variable as",submenu_handle);
   len := base_list._length();
   index := _TreeCurIndex();

   watch_id := _TreeGetUserInfo(index);
   if (watch_id==0) {
      _menu_delete(menu_handle,menu_pos);
      return(1);
   }

   watch_option := "";
   if (substr(p_name,1,length("ctl_watches"))=="ctl_watches") {
      watch_option="-watch";
   }

   var_name := debug_get_variable_name();
   caption_varname := var_name;
   if (watch_option!="") {
      caption_varname='"':+var_name:+'"';
   }
   _menu_set_state(menu_handle,menu_pos,0,'P',"View ":+caption_varname:+" as");

   var_base := dbg_get_var_format(var_name);
   // If this is a watch variable, we have to check for a format on the watch itself
   if (watch_option=="-watch") {
      expandable := tab_number := 0;
      _str expr,context_name,value,raw_value = "",type="";
      dbg_get_watch(0,0,watch_id,tab_number,expr,context_name,value,expandable,var_base,raw_value,type);
   }

   menu_pos = 0;
   foreach (auto b in base_list) {
      flags := 0;
      if (b == VSDEBUG_BASE_UNICODE_TEXT || b == VSDEBUG_BASE_DEFAULT_FLOAT) {
         _menu_insert(submenu_handle,menu_pos++,flags,'-');
      }
      if (b <= VSDEBUG_BASE_NUMBER_MASK) {
         if ((var_base & VSDEBUG_BASE_NUMBER_MASK) == b) flags |= MF_CHECKED;
      } else if ( (var_base & b) == b ) {
         flags |= MF_CHECKED;
      } else if (b == VSDEBUG_BASE_DEFAULT_FLOAT && !(var_base & VSDEBUG_BASE_FLOAT_MASK)) {
         flags |= MF_CHECKED;
      } else if (b == VSDEBUG_BASE_UNICODE_TEXT && !(var_base & VSDEBUG_BASE_STRING_MASK)) {
         flags |= MF_CHECKED;
      }
      cur_base_name := dbg_get_format_name(b);
      _menu_insert(submenu_handle,menu_pos++,flags,cur_base_name,"debug_set_var_base ":+watch_option:+" ":+var_name:+" ":+b);
   }
   return(0);
}

static int DisableLocalBasesToMenu(int menu_handle)
{
   submenu_handle := 0;
   menu_pos := _menu_find_loaded_menu_caption(menu_handle,"View variable as",submenu_handle);
   index := _TreeCurIndex();
   caption := _TreeGetCaption(index);
   varname := "";
   parse caption with varname .;

   if (_TreeGetUserInfo(index)==0) {
      _menu_delete(menu_handle,menu_pos);
      return(1);
   }

   _menu_set_state(menu_handle,menu_pos,MF_GRAYED,'P',"View ":+varname:+" as");
   return(0);
}

_command int debug_set_global_base(int new_base=-1) name_info(','VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   if ( new_base<0 ) {
      return(INVALID_ARGUMENT_RC);
   }
   dbg_set_global_format(new_base);

   // Have to do this twice because the first time will turn all of the changed
   // items red
   debug_gui_update_all_vars();
   debug_gui_update_all_vars();

   return(0);
}

_command int debug_toggle_hex() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   new_base := VSDEBUG_BASE_HEXADECIMAL;
   if (dbg_get_global_format() == VSDEBUG_BASE_HEXADECIMAL) {
      new_base = VSDEBUG_BASE_DEFAULT;
   }
                 
   dbg_set_global_format(new_base);

   // Have to do this twice because the first time will turn all of the changed
   // items red
   debug_gui_update_all_vars();
   debug_gui_update_all_vars();

   return(0);
}

_command int debug_set_var_base(_str args="") name_info(','VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   if ( args=="" ) {
      return(INVALID_ARGUMENT_RC);
   }
   status := 0;
   varname := "";
   new_base := 0;
   new_base_str := "";
   iswatch := false;

   cur_arg := "";
   for (;;) {
      cur_arg=parse_file(args);
      if (substr(cur_arg,1,1)!="-" || cur_arg=="") break;
      if (cur_arg=="-watch") {
         iswatch=true;
      } else if (iswatch) {
         // If we got here, this is a watch variable, and  we still have a leading '-'
         // That means that this is really an expression, and we should break so that this gets
         // treated as the variable name.
         break;
      }
   }

   varname=cur_arg;
   new_base_str=parse_file(args);

   if (varname=="" || new_base_str=="") {
      return(INVALID_ARGUMENT_RC);
   }

   global_format := dbg_get_global_format();
   if ( (global_format & (VSDEBUG_BASE_DEFAULT|VSDEBUG_BASE_DEFAULT_FLOAT|VSDEBUG_BASE_UNICODE_TEXT)) == global_format ) {
      result := _message_box(nls("The global base is currently set to %s, and this will override individual variable settings.\n\nWould you like to shut off the global base now?",dbg_get_format_name(dbg_get_global_format())),"",MB_YESNOCANCEL);
      if ( result==IDYES ) {
         dbg_set_global_format(VSDEBUG_BASE_DEFAULT);
      } else if (result==IDCANCEL) {
         return(COMMAND_CANCELLED_RC);
      }
   }

   new_base=(int)new_base_str;

   if (!iswatch) {
      dbg_set_var_format(varname, new_base);
   } else {
      watch_id := 0;
      index := _TreeCurIndex();
      if (index>=0) {
         watch_id=_TreeGetUserInfo(index);
      }
      expandable := tab_number := 0;
      cur_base := VSDEBUG_BASE_DEFAULT;
      expr := context_name := value := raw_value := type := "";
      dbg_get_watch(0,0,watch_id,tab_number,expr,context_name,value,expandable,cur_base,raw_value,type);
      dbg_set_watch(watch_id,expr,context_name,new_base);
   }

   // Have to do this twice because the first time will turn all of the changed
   // items red
   debug_gui_update_all_vars();
   debug_gui_update_all_vars();

   return(0);
}

/**
 * 
 * @return Returns 0 if successful.
 * 
 * @categories Debugger_Functions
 */
int debug_mouse_drag_instruction_pointer()
{
   // do nothing if this session does not support it
   if (!debug_session_is_implemented("set_instruction_pointer")) {
      return(0);
   }

   status := mouse_drag(null, "_ed_exec.svg");
   if (status < 0) {
      debug_gui_update_stack(dbg_get_cur_thread());
      return status;
   }

   debug_set_instruction_pointer();
   return 0;
}


void debug_refresh_process_list(_str fileName, bool includeSystemProcesses)
{
   PROCESS_INFO pl[];
   _list_processes(pl);
   n := pl._length();
   pid := getpid();
   process_name := _strip_filename(fileName,'P');
   process_name_no_ext := _strip_filename(process_name,'E');
   _TreeBeginUpdate(TREE_ROOT_INDEX);
   _TreeDelete(TREE_ROOT_INDEX, 'C');
   for (i:=0; i<n; ++i) {
      hidden := TREENODE_HIDDEN;
      if ((includeSystemProcesses || !pl[i].is_system) && pl[i].pid != pid) {
         hidden=0;
      }
      index := _TreeAddItem(TREE_ROOT_INDEX,
                            pl[i].name"\t"pl[i].pid"\t"pl[i].title,
                            TREE_ADD_AS_CHILD,0,0,-1,hidden,
                            pl[i].is_system);
      if (hidden != TREENODE_HIDDEN) {
         if (strieq(pl[i].name,process_name) || strieq(pl[i].name, process_name_no_ext)) {
             _TreeSetCurIndex(index);
         }
      }
   }
   _TreeTop();
   _TreeEndUpdate(TREE_ROOT_INDEX);
}


static int show_modify_variable_dlg(int session_id, int thread_id, int frame_id, _str oldValue, _str varName, _str &newValue)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // was the old value surrounded by double quotes?
   oldValueHadQuotes := false;
   if (oldValue != null) {
      oldValueHadQuotes = (oldValue == '"'strip(oldValue, 'B', '"')'"');
   }

   // ask the user whether this is a string or an expression
   newValue = "";
   status := show("-modal _dbgp_modify_variable_form", varName, oldValue, oldValueHadQuotes ? DBGP_MODIFY_STRING : -1);
   if (status == IDOK) {
      newValue = _param1;
      if (_param2 == DBGP_MODIFY_EXPR) {
         dbg_session_eval_expression(session_id, thread_id, frame_id, newValue, newValue);
      } else {
         if (oldValueHadQuotes) {
            newValue = strip(newValue, 'B', '"');
         }
         newValue = '"'newValue'"';
      }
      return 0;
   }

   return -1;
}

defeventtab _dbgp_modify_variable_form;

void _ctl_ok.on_create(_str varName, _str value, int defaultValue = -1)
{
   // set up the editor control
   _ctl_editor.p_LangId = "fundamental";
   _ctl_editor.p_line_numbers_len = 0;
   _ctl_editor.p_LCBufFlags &= ~(VSLCBUFFLAG_LINENUMBERS | VSLCBUFFLAG_LINENUMBERS_AUTO);

   _lbl_name.p_caption = "Enter new value for "varName;

   // split up the individual lines in the value
   _str lines[];
   nlPos := pos("\n", value, 1);
   while (nlPos > 0) {
      lines[lines._length()] = substr(value, 1, nlPos - 1);
      value = substr(value, nlPos + 2);

      nlPos = pos("\n", value, 1);
   }
   lines[lines._length()] = value;

   // now add the value to the editor control
   if (!lines._isempty() && lines._length()) {
      _ctl_editor.top();
      _ctl_editor.replace_line(lines[0]);
      for (i := 1; i < lines._length(); i++) {
         _ctl_editor.insert_line(lines[i]);
         _ctl_editor.down();
      }
   } else {
      _ctl_editor.replace_line(value);
   }

   // select the current value
   _deselect();
   _ctl_editor.top();
   _ctl_editor._select_char("",'CN');
   _ctl_editor.bottom();
   _ctl_editor._select_char();
   _ctl_editor._end_select();

   // no default value?  restore what we picked last time
   if (defaultValue == -1) {
      defaultValue = _ctl_string_radio._retrieve_value();
   }

   // set up the default
   if (defaultValue == DBGP_MODIFY_STRING) {
      _ctl_string_radio.p_value = 1;
   } else {
      _ctl_expr_radio.p_value = 1;
   }
}

void _ctl_ok.lbutton_up()
{
   // what did they select?
   select := DBGP_MODIFY_STRING;
   if (_ctl_expr_radio.p_value) {
      select = DBGP_MODIFY_EXPR;
   } 

   // save the value of the radio selection
   _ctl_string_radio._append_retrieve(0, select, _ctl_string_radio.p_active_form.p_name"."_ctl_string_radio.p_name);

   // extract the value from the editor
   _ctl_editor.top();
   _ctl_editor.get_line(auto line);
   value := line;
   while (!_ctl_editor.down()) {
      _ctl_editor.get_line(line);
      value :+= "\n"line;
   }

   _param1 = value;
   _param2 = select;

   p_active_form._delete_window(IDOK);
}

void _ctl_cancel.lbutton_up()
{
   p_active_form._delete_window(IDCANCEL);
}
