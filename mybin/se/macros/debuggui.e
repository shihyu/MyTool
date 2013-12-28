////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50251 $
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
#import "stdprocs.e"
#import "tags.e"
#import "tagwin.e"
#import "tbcmds.e"
#import "toolbar.e"
#import "treeview.e"
#import "util.e"
#import "xmlcfg.e"
#endregion

///////////////////////////////////////////////////////////////////////////
// Almost of the toolbar forms have tree controls.  The use the p_user
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
#define DEBUG_ADD_WATCH_CAPTION "< add >"

// Debugger configuration file nodes and attributes
#define VSDEBUG_CONFIG_TAG_DEBUGGER          "Debugger"
#define VSDEBUG_CONFIG_TAG_PACKAGE           "Package"
#define VSDEBUG_CONFIG_TAG_CONFIGURATION     "Configuration"

#define VSDEBUG_CONFIG_ATTR_NAME             "Name"
#define VSDEBUG_CONFIG_ATTR_PATH             "Path"
#define VSDEBUG_CONFIG_ATTR_PLATFORM         "Platform"
#define VSDEBUG_CONFIG_ATTR_ARGUMENTS        "Arguments"
#define VSDEBUG_CONFIG_ATTR_DEFAULT          "Default"
#define VSDEBUG_CONFIG_ATTR_STANDARD         "Standard"

#define VSDEBUG_CONFIG_VALUE_STANDARD_GDB    "Standard GDB"
#define VSDEBUG_CONFIG_VALUE_GDB             "GDB"

// string to display to let the user create a new debug session
#define VSDEBUG_NEW_SESSION                  "<New Debugging Session>"

/**
 * Are we currently updating the list of threads?
 */
static boolean gInUpdateThreadList=false;
/**
 * Are we currently updating the current thread?
 */
static boolean gInUpdateThread=false;
/**
 * Are we currently updating the execution stack frame?
 */
static boolean gInUpdateFrame=false;
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
static boolean gInUpdateUserViews=false;


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
      gUserViewQuery=null;
      gUserViewList._makeempty();
   }
}

static boolean isDynamicDebugger()
{
   session_id := dbg_get_current_session();
   switch (dbg_get_callback_name(session_id)) {
   case 'xdebug':
   case 'pydbgp':
   case 'perl5db':
   case 'rdbgp':
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
   int orig_wid=p_window_id;
   int indent, pic_index;
   p_window_id = listBox;

   // go through the list and grab each item
   list := '';
   _lbtop();
   for (;;) {
      line := '';
      _lbget_item(line, indent, pic_index);
      if (line!='') {
         list :+= line' ';
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
boolean isThisADebugProject()
{
   session_id := dbg_get_current_session();
   return (dbg_get_callback_name(session_id) != '');
}

defeventtab _debug_props_runtime_filters_form;

// our list of filters
#define FILTERS_LIST ctl_filter_list.p_user

/**
 * Callbacks for embedding forms inside Options Dialog
 */
#region Options Dialog Helper Functions

/**
 * Initializes _debug_props_runtime_filters_form for options - 
 * does form initialization in absence of an on_create method. 
 */
void _debug_props_runtime_filters_form_init_for_options()
{
   // fill in the class filters
   filter := '';
   n := dbg_get_num_runtimes();
   for (i := 1; i <= n; ++i) {
      dbg_get_runtime_expr(i, filter);
      if (filter != '') {
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
   FILTERS_LIST = buildListboxList(ctl_filter_list);
}

/**
 * Determines if anything on the current form has been modified.
 */
boolean _debug_props_runtime_filters_form_is_modified()
{
   // build our current list and compare it to the saved one
   currentList := buildListboxList(ctl_filter_list);
   return (currentList != FILTERS_LIST);
}

/**
 * Applies any changes to the current form.
 */
boolean _debug_props_runtime_filters_form_apply()
{
   int orig_wid=p_window_id;
   int indent,pic_index;
   dbg_clear_runtimes();

   p_window_id=ctl_filter_list.p_window_id;
   _lbtop();
   for (;;) {
      _str line='';
      _lbget_item(line,indent,pic_index);
      if (line!='') dbg_add_runtime_expr(strip(line));

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
   widthDiff := p_width - (ctl_add_filter.p_x + ctl_add_filter.p_width + 120);
   if (widthDiff) {
      ctl_add_filter.p_x += widthDiff;
      ctl_del_filter.p_x += widthDiff;
      ctl_reset_filter.p_x += widthDiff;

      ctl_filter_list.p_width += widthDiff;
   }

   // and now height
   heightDiff := p_height - (ctl_filter_list.p_y + ctl_filter_list.p_height + 120);
   if (heightDiff) {
      ctl_filter_list.p_height += heightDiff;
   }
}

void ctl_add_filter.lbutton_up()
{
   // add filter here
   int wid=p_window_id;
   _str name=show('-modal _textbox_form',
                  'Enter New Item',
                  0, //Flags
                  '',//Width
                  '',//Help item
                  '',//Buttons and captions
                  '',//retrieve
                  'Item:' //prompt
                  );
   if (name!='') {
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
   mou_hour_glass(1);
   boolean ff=true;
   int orig_wid=p_window_id;
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
   mou_hour_glass(0);
}

void ctl_reset_filter.lbutton_up()
{
   // delete selected filter here
   mou_hour_glass(1);
   ctl_filter_list._lbclear();
   int session_id = dbg_get_current_session();
   if (dbg_get_callback_name(session_id) == 'jdwp') {
      ctl_filter_list._lbadd_item("java.*");
      ctl_filter_list._lbadd_item("javax.*");
      ctl_filter_list._lbadd_item("com.sun.*");
      ctl_filter_list._lbadd_item("com.ibm.*");
      ctl_filter_list._lbadd_item("sun.*");
   } else if (dbg_get_callback_name(session_id) == 'gdb') {
      ctl_filter_list._lbadd_item("printf");
      ctl_filter_list._lbadd_item("strcpy");
      ctl_filter_list._lbadd_item("std::*");
   }
   ctl_filter_list._lbsort();
   ctl_filter_list._lbselect_line();
   ctl_del_filter.p_enabled=true;
   mou_hour_glass(0);
}

void ctl_filter_list.DEL()
{
   if (p_next.p_next.p_enabled) {
      p_next.p_next.call_event(p_next.p_next,LBUTTON_UP,'W');
   }
}

defeventtab _debug_props_directories_form;

#define DIRECTORIES_LIST ctl_dir_list.p_user

#region Options Dialog Helper Functions

void _debug_props_directories_form_init_for_options()
{
   // fill in the directory search paths
   dir := '';
   n := dbg_get_num_dirs();
   for (i := 1; i <= n; ++i) {
      dbg_get_source_dir(i, dir);
      if (dir != '') {
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
   DIRECTORIES_LIST = buildListboxList(ctl_dir_list);
}

boolean _debug_props_directories_form_is_modified()
{
   if(((def_debug_options & VSDEBUG_OPTION_CONFIRM_DIRECTORY)? 1:0) != ctl_prompt_for_dir.p_value) return true;

   curList := buildListboxList(ctl_dir_list);
   return (curList != DIRECTORIES_LIST);
}

boolean _debug_props_directories_form_apply()
{
   list := '';
   int indent,pic_index;

   int orig_wid=p_window_id;
   // get the directory search paths
   dbg_clear_sourcedirs();
   debug_clear_file_path_cache();
   p_window_id=ctl_dir_list.p_window_id;
   _lbtop();
   for (;;) {
      _str line='';
      _lbget_item(line,indent,pic_index);
      if (line!='') {
         dbg_add_source_dir(strip(line));
         list :+= line' ';
      } 
      // do something with down
      if (_lbdown()) {
         break;
      }
   }

   if (ctl_prompt_for_dir.p_value) def_debug_options |= VSDEBUG_OPTION_CONFIRM_DIRECTORY;
   else def_debug_options &= ~VSDEBUG_OPTION_CONFIRM_DIRECTORY;

   p_window_id=orig_wid;

   return true;
}

_str _debug_props_directories_form_build_export_summary(PropertySheetItem (&table)[])
{
   // fill in the directory search paths
   dir := '';
   dirList := '';
   n := dbg_get_num_dirs();
   for (i := 1; i <= n; ++i) {
      dbg_get_source_dir(i, dir);
      if (dir != '') {
         dirList :+= dir';';
      }
   }
   PropertySheetItem psi;
   psi.Caption = "Directories";
   psi.Value = strip(dirList, 'T', ';');
   table[0] = psi;

   psi.Caption = "Confirm source file directory";
   psi.Value = (def_debug_options & VSDEBUG_OPTION_CONFIRM_DIRECTORY)? "True" : "False";
   table[1] = psi;

   return '';
}

_str _debug_props_directories_form_import_summary(PropertySheetItem (&table)[])
{
   error := '';

   dbg_clear_sourcedirs();
   debug_clear_file_path_cache();

   dirList := table[0].Value;
   while (dirList != '') {
      dir := '';
      parse dirList with dir ';' dirList;

      // this might be coming from another operating system, so we 
      // will try flipping the fileseps
      dir = stranslate(dir, FILESEP, FILESEP2);

      // make sure it exists...
      if (file_exists(dir)) {
         dbg_add_source_dir(strip(dir));
      } else {
         error :+= dir' does not exist.'OPTIONS_ERROR_DELIMITER;
      }
   }

   // confirm source file directory
   confirm := (table[1].Value == "True");
   if (confirm) {
      def_debug_options |= VSDEBUG_OPTION_CONFIRM_DIRECTORY;
   } else {
      def_debug_options &= ~VSDEBUG_OPTION_CONFIRM_DIRECTORY;
   }

   return error;
}

#endregion Options Dialog Helper Functions

void _debug_props_directories_form.on_resize()
{
   // width and height of border
   width := _dx2lx(p_xyscale_mode,p_active_form.p_client_width);
   height := _dy2ly(p_xyscale_mode,p_active_form.p_client_height);

   // check width
   widthDiff := width - (ctl_add_dir.p_x + ctl_add_dir.p_width + 120);
   if (widthDiff) {
      ctl_add_dir.p_x += widthDiff;
      ctl_del_dir.p_x += widthDiff;
      ctl_reset_dirs.p_x += widthDiff;

      ctl_dir_list.p_width += widthDiff;
   }

   heightDiff := height - (ctl_prompt_for_dir.p_y + ctl_prompt_for_dir.p_height + 120);
   if (heightDiff) {
      ctl_prompt_for_dir.p_y += heightDiff;
      ctl_dir_list.p_height += heightDiff;
   }
}

void ctl_add_dir.lbutton_up()
{
   int wid=p_window_id;
   _str orig_cwd = getcwd();
   _str name = _ChooseDirDialog();
   chdir(orig_cwd);
   if (name!='') {
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
   mou_hour_glass(1);
   ctl_dir_list._lbclear();
   ctl_del_dir.p_enabled=false;
   mou_hour_glass(0);
}

defeventtab _debug_props_configurations_form;

#define DEBUG_CONFIG_FILE_HANDLE       ctl_config_tree.p_user
#define DEBUG_CONFIG_GDB_HASH          ctl_config_path.p_user
#define DEBUG_CONFIG_PACKAGE_INDEX     ctl_config_name.p_user
#define DEBUG_CONFIG_CHANGE_SEL        ctl_config_args.p_user

#region Options Dialog Helper Functions

void _debug_props_configurations_form_init_for_options()
{
   // we are not changing the tree selection right now, so false
   DEBUG_CONFIG_CHANGE_SEL = 0;

   // Load the GDB debugger configurations
   debug_gdb_load_configurations();
   _debug_props_configurations_form_initial_alignment();
}

void _debug_props_configurations_form_save_settings()
{
   fh := debug_get_gdb_config_tree(true);
   _xmlcfg_set_modify(fh, 0);
}

boolean _debug_props_configurations_form_is_modified()
{
   fh := debug_get_gdb_config_tree(true);
   return (_xmlcfg_get_modify(fh) != 0);
}

boolean _debug_props_configurations_form_apply()
{
   if (!debug_gdb_validate_and_save_configuration()) return false;

   // save the XML configuration file
   int fh = debug_get_gdb_config_tree(true);
   if (fh > 0) {
      _str filename=_ConfigPath():+DEBUGGER_CONFIG_FILENAME;
      int status=_xmlcfg_save(fh,-1,VSXMLCFG_SAVE_ONE_LINE_IF_ONE_ATTR,filename);
      if (status < 0) {
         debug_message("Could not save configuration: ",status);
         return false;
      }
   }

   return true;
}

_str _debug_props_configurations_form_export_settings(_str &file)
{
   error := '';

   // get the path to the debugger configuration file
   debugFile := _ConfigPath():+DEBUGGER_CONFIG_FILENAME;
   if (!file_exists(debugFile)) {
      debugFile = get_env("VSROOT"):+DEBUGGER_CONFIG_FILENAME;
      if (!file_exists(debugFile)) debugFile = '';
   }

   if (debugFile != '') {
      targetFile := file :+ DEBUGGER_CONFIG_FILENAME;
      if (copy_file(debugFile, targetFile)) {
         error = 'Error copying debugger configuration file, 'debugFile'.';
      } else {
         file = DEBUGGER_CONFIG_FILENAME;
      }
   }

   return error;
}

_str _debug_props_configurations_form_import_settings(_str &importFile)
{
   error := '';

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
         error = 'Error opening debugger configuration file 'origFile'.';
      } else if (importHandle < 0) {
         error = 'Error opening debugger configuration file 'importFile'.';
      } else {
         // grab each debugger out of the import file and put it in the configuration file
         do {
            // find the Debugger tag
            importDbgIndex := _xmlcfg_find_simple(importHandle, VSDEBUG_CONFIG_TAG_DEBUGGER);
            if (importDbgIndex < 0) {
               error = 'Error finding debugger information in configuration file 'importFile'.';
               break;
            }
   
            // find the Package section for GDB
            importPkgIndex := _xmlcfg_find_simple(importHandle, VSDEBUG_CONFIG_TAG_PACKAGE"[@"VSDEBUG_CONFIG_ATTR_NAME"='"VSDEBUG_CONFIG_VALUE_GDB"']", importDbgIndex);
            if (importPkgIndex < 0) {
               error = 'Error finding package information in configuration file 'importFile'.';
               break;
            }

            // grab each debugger out of the import file and put it in the configuration file
            // find the Debugger tag
            origDbgIndex := _xmlcfg_find_simple(origHandle, VSDEBUG_CONFIG_TAG_DEBUGGER);
            if (origDbgIndex < 0) {
               error = 'Error finding debugger information in configuration file 'origFile'.';
               break;
            }
   
            // find the Package section for GDB
            origPkgIndex := _xmlcfg_find_simple(origHandle, VSDEBUG_CONFIG_TAG_PACKAGE"[@"VSDEBUG_CONFIG_ATTR_NAME"='"VSDEBUG_CONFIG_VALUE_GDB"']", origDbgIndex);
            if (origPkgIndex < 0) {
               error = 'Error finding package information in configuration file 'origFile'.';
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
   sizeBrowseButtonToTextBox(ctl_config_path.p_window_id, ctl_find_config.p_window_id,
                             0, ctl_config_name.p_x + ctl_config_name.p_width);

   alignUpDownListButtons(ctl_config_tree.p_window_id, ctl_config_frame.p_x + ctl_config_frame.p_width,
                          ctl_add_config.p_window_id, ctl_delete_config.p_window_id);
}

void _debug_props_configurations_form.on_resize()
{
   // check width
   widthDiff := p_width - (ctl_add_config.p_x + ctl_add_config.p_width + 120);
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

   heightDiff := p_height - (ctl_config_frame.p_y + ctl_config_frame.p_height + 120);
   if (heightDiff) {
      ctl_config_tree.p_height += heightDiff;

      ctl_config_frame.p_y += heightDiff;
   }
}

void _debug_props_configurations_form.on_destroy()
{
   // close the handle
   int fh = debug_get_gdb_config_tree(true);
   if (fh > 0) {
      _xmlcfg_close(fh);
      DEBUG_CONFIG_FILE_HANDLE=0;
   }
}

void ctl_config_tree.on_change(int reason,int index)
{
   if (index>0 && reason==CHANGE_SELECTED) {

      // check if current entries are valid
      int orig_index=debug_get_gdb_config_current();
      if (index!=orig_index && !debug_gdb_validate_and_save_configuration()) {
         _TreeSetCurIndex(orig_index);
         return;
      }

      // find the XML config tree handle
      int fh=debug_get_gdb_config_tree(true);
      if (fh < 0) {
         return;
      }

      // set this to true so we'll know we're only changing the 
      // current selection, not anything in the XML
      DEBUG_CONFIG_CHANGE_SEL = 1;

      // save the config index for the newly selected item
      debug_set_gdb_config_current();

      // get the attriutes for the selected configuration
      int config_index = ctl_config_tree._TreeGetUserInfo(index);
      _str gdb_name   = _xmlcfg_get_attribute(fh,config_index,VSDEBUG_CONFIG_ATTR_NAME);
      _str gdb_path   = _xmlcfg_get_attribute(fh,config_index,VSDEBUG_CONFIG_ATTR_PATH);
      _str gdb_args   = _xmlcfg_get_attribute(fh,config_index,VSDEBUG_CONFIG_ATTR_ARGUMENTS);
      if (gdb_path!='') {
         gdb_path = debug_normalize_config_path(gdb_path);
      }

      // fill them into the form
      ctl_config_name.p_text   = gdb_name;
      ctl_config_path.p_text   = gdb_path;
      ctl_config_args.p_text   = gdb_args;
      _str gdb_default = _xmlcfg_get_attribute(fh,config_index,VSDEBUG_CONFIG_ATTR_DEFAULT);
      ctl_default_config.p_value = (gdb_default==1)? 1:0;

      DEBUG_CONFIG_CHANGE_SEL = 0;
   }
}

void ctl_config_tree.DEL()
{
   call_event(ctl_delete_config,LBUTTON_UP,'w');
}

void ctl_delete_config.lbutton_up()
{
   // find the current item in the tree
   int tree_index=ctl_config_tree._TreeCurIndex();
   if (tree_index <= 0) {
      return;
   }

   // can not delete a slickedit default node
   if (debug_gdb_is_slickedit_default(tree_index)) {
      debug_message("Can not delete default debugger");
      return;
   }

   // find the XML config tree handle
   int fh=debug_get_gdb_config_tree();
   if (fh < 0) {
      return;
   }

   // can not delete a slickedit default node
   if (debug_gdb_is_native_default(tree_index)) {
      int j = ctl_config_tree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
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
   int fh = debug_get_gdb_config_tree();
   if (fh < 0) {
      return COMMAND_CANCELLED_RC;
   }

   // used the saved package index
   int package_index = debug_get_gdb_config_package();
   if (package_index <= 0) {
      return COMMAND_CANCELLED_RC;
   }

   // Transfer focus to the "Name" control
   _str gdb_path=ctl_find_config.debug_gui_find_executable();
   if (gdb_path=='') {
      return COMMAND_CANCELLED_RC;
   }

   // validate the path they gave us
   gdb_path=debug_normalize_config_path(gdb_path);
   int gdb_status=debug_gdb_validate_gdb_path(gdb_path);
   if (gdb_status < 0) {
      return(gdb_status);
   }

   // create a new node and set its index
   int config_index = _xmlcfg_add(fh, package_index, VSDEBUG_CONFIG_TAG_CONFIGURATION, VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_set_attribute(fh, config_index, VSDEBUG_CONFIG_ATTR_PLATFORM, machine());

   // Add this nice new item to the tree
   int tree_index = ctl_config_tree._TreeAddListItem(machine()"\t""\t",0,TREE_ROOT_INDEX,-1,config_index);
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
   _str orig_path=ctl_config_path.p_text;
   _str gdb_path=debug_gui_find_executable();
   if (gdb_path=='' || gdb_path==orig_path) {
      return;
   }

   // validate the path they gave us
   ctl_config_path.p_text=debug_normalize_config_path(gdb_path);
   int gdb_status=debug_gdb_validate_gdb_path(ctl_config_path.p_text);
   if (gdb_status < 0) {
      ctl_config_path._set_focus();
      return;
   }
}

void ctl_config_path.on_change()
{
   if (!DEBUG_CONFIG_CHANGE_SEL) {
      debug_gdb_config_set_attr(VSDEBUG_CONFIG_ATTR_PATH, relative(p_text,get_env("VSROOT")));
   }
}

void ctl_config_name.on_change()
{
   if (!DEBUG_CONFIG_CHANGE_SEL) {
      debug_gdb_config_set_attr(VSDEBUG_CONFIG_ATTR_NAME,p_text);
   }
}

void ctl_config_args.on_change()
{
   if (!DEBUG_CONFIG_CHANGE_SEL) {
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

static boolean isThisPlatform(_str machineName)
{
   if (machineName == machine()) {
      return true;
   }
   if (machine() == 'WINDOWS' && substr(machineName,1,2)=='NT') {
      return true;
   }
   return false;
}

/**
 * Load the current set of configurations into the tree control
 */
static void debug_gdb_load_configurations()
{
   // Save the tested GDB executables hash table, initially empty
   boolean tested_gdb_hash:[];  tested_gdb_hash._makeempty();
   DEBUG_CONFIG_GDB_HASH = tested_gdb_hash;

   // get the path to the GDB configuration file
   _str filename=_ConfigPath():+DEBUGGER_CONFIG_FILENAME;
   if (!file_exists(filename)) {
      filename=get_env("VSROOT"):+DEBUGGER_CONFIG_FILENAME;
   }

   // clear the list of configurations
   ctl_config_tree._TreeDelete(TREE_ROOT_INDEX,'c');
   DEBUG_CONFIG_FILE_HANDLE = -1;

   // open the XML configuration file
   boolean have_standard_gdb=false;
   boolean have_default_gdb=false;
   int status=0;
   int fh=_xmlcfg_open(filename,status);
   if (status<0 && fh<0) {
      fh=_xmlcfg_create(filename,VSENCODING_UTF8);
      status=(fh<0)? fh:0;

      // create the base nodes of tree
      if (!status) {
         // create the XML declaration
         int xmldecl_index = _xmlcfg_add(fh, TREE_ROOT_INDEX, "xml", VSXMLCFG_NODE_XML_DECLARATION, VSXMLCFG_ADD_AS_CHILD);
         _xmlcfg_set_attribute(fh, xmldecl_index, "version", "1.0");
         // create the DOCTYPE declaration
         int doctype_index = _xmlcfg_add(fh, TREE_ROOT_INDEX, "DOCTYPE", VSXMLCFG_NODE_DOCTYPE, VSXMLCFG_ADD_AS_CHILD);
         _xmlcfg_set_attribute(fh, doctype_index, "root",   VSDEBUG_CONFIG_TAG_DEBUGGER);
         _xmlcfg_set_attribute(fh, doctype_index, "SYSTEM", VSDEBUG_DTD_PATH);
      }
   }
   if (status < 0) {
      debug_message("Could not create debugger configuration file");
   }
   // save the file handle
   DEBUG_CONFIG_FILE_HANDLE = fh;

   // find the Debugger tag
   int debugger_index = _xmlcfg_find_simple(fh, VSDEBUG_CONFIG_TAG_DEBUGGER);
   if (debugger_index < 0) {
      // create the Debugger top level node
      debugger_index = _xmlcfg_add(fh, TREE_ROOT_INDEX, VSDEBUG_CONFIG_TAG_DEBUGGER, VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
   }

   // find the Package section for GDB
   int package_index = _xmlcfg_find_simple(fh, VSDEBUG_CONFIG_TAG_PACKAGE"[@"VSDEBUG_CONFIG_ATTR_NAME"='"VSDEBUG_CONFIG_VALUE_GDB"']", debugger_index);
   if (package_index < 0) {
      // create the Package node for GDB configuration options
      package_index = _xmlcfg_add(fh, debugger_index, VSDEBUG_CONFIG_TAG_PACKAGE, VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_set_attribute(fh, package_index, VSDEBUG_CONFIG_ATTR_NAME, VSDEBUG_CONFIG_VALUE_GDB);
   }

   // save the node ID of the package index
   DEBUG_CONFIG_PACKAGE_INDEX = package_index;

   // Find all the GDB configuration nodes
   _str gdb_configs[]; gdb_configs._makeempty();
   status=_xmlcfg_find_simple_array(fh, VSDEBUG_CONFIG_TAG_CONFIGURATION, gdb_configs, package_index);
   if (!status) {

      // For each node, extract the critical attributes, and add to tree
      int i,n=gdb_configs._length();
      for (i=0; i<n; ++i) {
         // Is this the right platform?
         if (isThisPlatform(_xmlcfg_get_attribute(fh, (int)gdb_configs[i], VSDEBUG_CONFIG_ATTR_PLATFORM))) {
            // Use a tab here since we have columns, otherwise sometimes the tree only
            // colors the the first item.
            int gdb_index = ctl_config_tree._TreeAddListItem("\t",0,TREE_ROOT_INDEX,-1,gdb_configs[i]);
            debug_gdb_update_tree_node(gdb_index);
            if (debug_gdb_is_slickedit_default(gdb_index)) {
               have_standard_gdb=true;
            }
            if (debug_gdb_is_native_default(gdb_index)) {
               have_default_gdb=true;
            }
         }
      }
   }

   // If not already in the list, add the standard GDB executable
   if (!have_standard_gdb) {
      _str gdb_path = debug_get_slickedit_gdb();
      tested_gdb_hash:[gdb_path]=true;
      int config_index = _xmlcfg_add(fh, package_index, VSDEBUG_CONFIG_TAG_CONFIGURATION, VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_set_attribute(fh, config_index, VSDEBUG_CONFIG_ATTR_STANDARD, 1);
      _xmlcfg_set_attribute(fh, config_index, VSDEBUG_CONFIG_ATTR_DEFAULT, !have_default_gdb);
      _xmlcfg_set_attribute(fh, config_index, VSDEBUG_CONFIG_ATTR_NAME, VSDEBUG_CONFIG_VALUE_STANDARD_GDB);
      _xmlcfg_set_attribute(fh, config_index, VSDEBUG_CONFIG_ATTR_PATH, relative(gdb_path,get_env("VSROOT")));
      _xmlcfg_set_attribute(fh, config_index, VSDEBUG_CONFIG_ATTR_PLATFORM, machine());

      // Use a tab here since we have columns, otherwise sometimes the tree only
      // colors the the first item.
      int gdb_index = ctl_config_tree._TreeAddListItem("\t",0,TREE_ROOT_INDEX,-1,config_index);
      debug_gdb_update_tree_node(gdb_index);
   }

   // Set up the tree captions
   ctl_config_tree._TreeSetColButtonInfo(0,2000,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Name");
   ctl_config_tree._TreeSetColButtonInfo(1,-1,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_AUTOSIZE|TREE_BUTTON_SORT_FILENAME,0,"Path");
   ctl_config_tree._TreeRetrieveColButtonInfo();
   ctl_config_tree._TreeAdjustLastColButtonWidth(); 

   // Sort the items in the tree
   ctl_config_tree._TreeSortCol();
   ctl_config_tree._TreeTop();
   ctl_config_tree._TreeRefresh();
   call_event(CHANGE_SELECTED,ctl_config_tree._TreeGetFirstChildIndex(TREE_ROOT_INDEX), ctl_config_tree, ON_CHANGE, 'w');
}

/**
 * Get the handle for the XML config tree.
 * The handle is stored in the user info for 'ctl_config_tree'
 */
static int debug_get_gdb_config_tree(boolean quiet=false)
{
   int fh = DEBUG_CONFIG_FILE_HANDLE;
   if (fh < 0 && !quiet) {
      debug_message("Debugger configuration file is not open");
   }
   return(fh);
}

/**
 * Is this a default GDB supplied with SlickEdit?
 */
static boolean debug_gdb_is_slickedit_default(int tree_index)
{
   int node_index = ctl_config_tree._TreeGetUserInfo(tree_index);
   int fh=debug_get_gdb_config_tree(true);
   if (fh > 0 && node_index > 0 &&
       _xmlcfg_get_attribute(fh, node_index, VSDEBUG_CONFIG_ATTR_STANDARD)==true) {
      return true;
   }
   return false;
}

/**
 * Is this the default native GDB
 */
static boolean debug_gdb_is_native_default(int tree_index)
{
   int node_index = ctl_config_tree._TreeGetUserInfo(tree_index);
   int fh=debug_get_gdb_config_tree(true);
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
      ctl_config_name.p_text='';
      ctl_config_path.p_text='';
      ctl_config_args.p_text='';
      ctl_default_config.p_value=0;
   }
}

static void debug_gdb_update_tree_node(int tree_index)
{
   // Save the tested GDB executables hash table, initially empty
   boolean tested_gdb_hash:[];
   tested_gdb_hash = DEBUG_CONFIG_GDB_HASH;

   // watch out for bad tree indices
   if (tree_index <= 0) {
      return;
   }

   // find the XML config tree handle
   int fh=debug_get_gdb_config_tree(true);
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
   _str gdb_name = _xmlcfg_get_attribute(fh,config_index,VSDEBUG_CONFIG_ATTR_NAME);
   _str gdb_path = _xmlcfg_get_attribute(fh,config_index,VSDEBUG_CONFIG_ATTR_PATH);
   if (gdb_path!='') {
      gdb_path = debug_normalize_config_path(gdb_path);
   }
   ctl_config_tree._TreeSetCaption(tree_index, gdb_name"\t"gdb_path);

   // save this as a validated GDB path
   tested_gdb_hash:[gdb_path]=true;
   DEBUG_CONFIG_GDB_HASH = tested_gdb_hash;

   // update the boldness for this node
   _str gdb_default = _xmlcfg_get_attribute(fh,config_index,VSDEBUG_CONFIG_ATTR_DEFAULT);
   int bold_flag = (gdb_default==1)? TREENODE_BOLD:0;
   ctl_config_tree._TreeSetInfo(tree_index,-1,-1,-1,bold_flag);

}

static void debug_gdb_config_set_attr(_str attr, _str value)
{
   // find the current item in the tree
   int tree_index=debug_get_gdb_config_current();
   if (tree_index <= 0) {
      return;
   }

   // find the XML config tree handle
   int fh=debug_get_gdb_config_tree(true);
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
   int fh=debug_get_gdb_config_tree(true);
   if (fh < 0) {
      return;
   }

   // for each item in the tree
   int tree_index=ctl_config_tree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (tree_index > 0) {

      // Get the correspond XML config index for this node
      int config_index = ctl_config_tree._TreeGetUserInfo(tree_index);
      if (config_index > 0) {
         _str gdb_default = _xmlcfg_get_attribute(fh,config_index,VSDEBUG_CONFIG_ATTR_DEFAULT);
         int bold_flag = (gdb_default==1)? TREENODE_BOLD:0;
         ctl_config_tree._TreeSetInfo(tree_index,-1,-1,-1,bold_flag);
      }

      tree_index = ctl_config_tree._TreeGetNextSiblingIndex(tree_index);
   }
}

/**
 * Validate the items for the currently selected node
 */
static boolean debug_gdb_validate_and_save_configuration()
{
   // no current node, then do nothing
   if (debug_get_gdb_config_current() <= 0) {
      //message('debug_get_gdb_config_current FAILED');
      return true;
   }

   // check to be sure the GDB they gave was proper
   int gdb_status=debug_gdb_validate_gdb_path(ctl_config_path.p_text);
   if (gdb_status < 0) {
      //message('debug_gdb_validate_gdb_path FAILED');
      ctl_config_path._set_focus();
      return(false);
   }

   // all is OK, save the data
   debug_gdb_config_set_attr(VSDEBUG_CONFIG_ATTR_NAME, ctl_config_name.p_text);
   debug_gdb_config_set_attr(VSDEBUG_CONFIG_ATTR_PATH, relative(ctl_config_path.p_text,get_env("VSROOT")));
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
   // Check for empty string
   gdb_path=strip(gdb_path,'B','"');
   if (gdb_path=='') {
      return COMMAND_CANCELLED_RC;
   }
   // check if file exists
   if (!file_exists(gdb_path)) {
      debug_message(get_message(FILE_NOT_FOUND_RC):+": ":+maybe_quote_filename(gdb_path));
      return FILE_NOT_FOUND_RC;
   }
   // Has this path already been tested and proven?
   boolean tested_gdb_hash:[];
   tested_gdb_hash = DEBUG_CONFIG_GDB_HASH;
   if (tested_gdb_hash._indexin(gdb_path)) {
      return 0;
   }

   // create a temporary GDB session
   int orig_session   = dbg_get_current_session();
   int gdb_session_id = dbg_create_new_session("gdb", "GDB test", false);
   if (gdb_session_id < 0) {
      debug_message(get_message(gdb_session_id));
      return gdb_session_id;
   }

   // check if it supports -gdb-version
   _str gdb_version='';
   int gdb_status=dbg_gdb_test_version(gdb_path,gdb_version,5000);
   if (gdb_status < 0) {
      debug_message("\"":+gdb_path"\" does not appear to be a compatible version of GDB.\n":+
                    "The required version is GDB 5.1 or greater.\n":+
                    "The identified version was \"":+gdb_version"\".",gdb_status);
   }

   // close the GDB session
   dbg_destroy_session(gdb_session_id);
   dbg_set_current_session(orig_session);

   // return status
   if (gdb_status < 0) {
      return gdb_status;
   }

   // mark this GDB path as tested and good
   tested_gdb_hash:[gdb_path] = true;
   DEBUG_CONFIG_GDB_HASH = tested_gdb_hash;
   // success
   return(0);

}

/**
 * Get the index for the GDB package in the XML config tree.
 * The index is stored in the user info for "ctl_config_name'.
 */
static int debug_get_gdb_config_package(boolean quiet=false)
{
   int package_index = DEBUG_CONFIG_PACKAGE_INDEX;
   if (package_index <= 0 && !quiet) {
      debug_message("Could not find \"Package\" tag");
   }
   return package_index;
}

defeventtab _debug_props_form;
#define VSDEBUG_PROPS_FORM "_debug_props_form"

void ctl_ok.on_create(_str tab_number='')
{
   // set font and color for the html control
   _str font_name,font_size,flags;
   typeless charset;
   parse _default_font(CFG_DIALOG) with font_name','font_size','flags','charset;
   if (!isinteger(charset)) charset=-1;
   if (!isinteger(font_size)) font_size=8;
   if (font_name!="") {
      ctl_html._minihtml_SetProportionalFont(font_name,charset);
   }
   ctl_html._minihtml_SetProportionalFontSize(3,((int)font_size)*10);
   ctl_html.p_backcolor=0x80000022;

   // update the properties
   debug_pkg_update_version();

}

void ctl_options.lbutton_up()
{
   optionsWid := config('Debugging', '+N', '', true);
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
CTL_SSTAB debug_gui_tab()
{
   _nocheck _control ctl_sstab;
   return ctl_sstab;
}

/**
 * Update the debug properties form
 *
 * @param description
 * @param major_version
 * @param minor_version
 * @param runtime_version
 * @param debugger_name
 */
void debug_gui_update_version(_str description,
                              _str major_version, _str minor_version,
                              _str runtime_version,
                              _str debugger_name)
{
   // insert n/a (not applicable) if we don't know info
   if (description  =='') description='n/a';
   if (runtime_version=='') runtime_version='n/a';
   if (debugger_name=='')   debugger_name='n/a';

   _str version=major_version;
   if (major_version!='') {
      if (minor_version!='') {
         version=version'.'minor_version;
      }
   } else {
      if (minor_version!='') {
         version=version'0.'minor_version;
      } else {
         version='n/a';
      }
   }

   // adjust the "VM" titles if this is JDWP
   int session_id = dbg_get_current_session();
   _str vm_version_title = "Runtime Version:";
   _str vm_name_title    = "Debugger:";
   if (dbg_get_callback_name(session_id) == 'jdwp') {
      vm_version_title = "VM Version:";
      vm_name_title    = "VM Name:";
   }

   // put together the string to put in the HTML control
   _str t = "<DL compact>\n";

   t = t :+ "<DT><B>" :+ "Description:" :+ "</B></DT>\n";
   t = t :+ "<DD>" :+ description    :+ "</DD>\n";

   t = t :+ "<DT><B>" :+ "Version:" :+ "</B></DT>\n";
   t = t :+ "<DD>" :+ version    :+ "</DD>\n";

   t = t :+ "<DT><B>" :+ vm_version_title :+ "</B></DT>\n";
   t = t :+ "<DD>" :+ runtime_version    :+ "</DD>\n";

   t = t :+ "<DT><B>" :+ vm_name_title :+ "</B></DT>\n";
   t = t :+ "<DD>" :+ debugger_name    :+ "</DD>\n";

   t = t :+ "</DL>\n";

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
   int forcedResize=0;
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
   int border_width   = tree_wid.p_x;
   int border_height  = (combo_wid1)? combo_wid1.p_y:tree_wid.p_y;
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

   tree_wid.p_width  = containerW  - tree_wid.p_x - border_width;
   tree_wid.p_height = containerH - tree_wid.p_y - border_height;
   if (tree_wid2) {
      tree_wid2.p_width  = containerW  - tree_wid2.p_x - border_width;
      tree_wid2.p_height = containerH - tree_wid2.p_y - border_height;
   }

   if (combo_wid1) {
      if (combo_wid1.p_object==OI_TEXT_BOX && combo_wid1.p_next.p_object==OI_SPIN) {
         combo_wid1.p_width = containerW - border_width - combo_wid1.p_x - combo_wid1.p_next.p_width - border_width;
         combo_wid1.p_next.p_x = combo_wid1.p_x + combo_wid1.p_width + border_width;
         combo_wid1.p_next.p_y = combo_wid1.p_y;
      } else {
         combo_wid1.p_width = containerW - border_width - combo_wid1.p_x;
      }
   }
   if (combo_wid2) {
      if (combo_wid2.p_object==OI_TEXT_BOX && combo_wid2.p_next.p_object==OI_SPIN) {
         combo_wid2.p_width = containerW - border_width - combo_wid2.p_x - combo_wid2.p_next.p_width - border_width;
         combo_wid2.p_next.p_x = combo_wid2.p_x + combo_wid2.p_width + border_width;
         combo_wid2.p_next.p_y = combo_wid2.p_y;
      } else {
         combo_wid2.p_width = containerW - border_width - combo_wid2.p_x;
      }
   }
}

/**
 * Return the path to the installed SlickEdit GDB executable.
 * <p>
 * NOTE:  On MacOS X, if /usr/bin/gdb exists, it will attempt to
 * use that instead of the GDB executable shipped with SlickEdit.
 */
_str debug_get_slickedit_gdb()
{
   if (_isMac() && file_exists("/usr/bin/gdb")) {
      return "/usr/bin/gdb";
   }
   if (machine()=='LINUX' && file_exists("/usr/bin/gdb")) {
      return "/usr/bin/gdb";
   }
   return path_search('gdb':+EXTENSION_EXE,"VSLICKBIN","S");
}

/**
 * Return the absolute path for the given GDB,
 * with environment variables replaced.
 */
static _str debug_normalize_config_path(_str gdb_path)
{
   gdb_path = _replace_envvars(gdb_path);
   gdb_path = absolute(gdb_path,get_env("VSROOT"));
   return gdb_path;
}

/**
 * Return the name and arguments for the default native GDB configuration
 * for the current platform.
 */
void dbg_gdb_get_default_configuration(_str &gdb_name, _str &gdb_path, _str &gdb_args)
{
   // get the path to the GDB configuration file
   int status=0;
   _str filename=_ConfigPath():+DEBUGGER_CONFIG_FILENAME;
   if (!file_exists(filename)) {
      filename=get_env("VSROOT"):+DEBUGGER_CONFIG_FILENAME;
   }

   int fh=_xmlcfg_open(filename,status);
   if (!status) {
      // find the Debugger tag
      int debugger_index = _xmlcfg_find_simple(fh, VSDEBUG_CONFIG_TAG_DEBUGGER);
      if (debugger_index > 0) {
         // find the Package section for GDB
         int package_index = _xmlcfg_find_simple(fh, VSDEBUG_CONFIG_TAG_PACKAGE"[@"VSDEBUG_CONFIG_ATTR_NAME"='"VSDEBUG_CONFIG_VALUE_GDB"']", debugger_index);
         if (package_index > 0) {
            // Find all the GDB configuration nodes
            typeless gdb_configs[]; gdb_configs._makeempty();
            status = _xmlcfg_find_simple_array(fh, VSDEBUG_CONFIG_TAG_CONFIGURATION, gdb_configs, package_index);
            if (!status) {
               // For each node, extract the critical attributes, and add to tree
               int i,n=gdb_configs._length();
               for (i=0; i<n; ++i) {
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

   // Always insert the standard GDB bundled with SlickEdit
   gdb_path = debug_get_slickedit_gdb();
   gdb_args = '';
   gdb_name = VSDEBUG_CONFIG_VALUE_STANDARD_GDB;
}

/**
 * Find an executable and place the name in the preceding text
 * box control.  The current object must be a button such that
 * p_prev is a text box.
 */
_str debug_gui_find_executable()
{
   int wid=p_window_id;
   _str initial_directory='';
   _str program=wid.p_prev.p_text;
   if (program!='') {
      _str filename=path_search(program,'','P');
      if (filename=='') {
         filename=path_search(program,'','P');
      }
      if (filename=='') {
         _message_box(nls('Program %s not found',program));
      } else {
         filename=debug_normalize_config_path(filename);
         initial_directory=_strip_filename(filename,'N');
      }
   }

   _str result=_OpenDialog(
      '-modal',
       'Choose Application',
       '',
      (__UNIX__)?"All Files("ALLFILES_RE")":"Executable Files (*.exe)", // File Type List
      OFN_FILEMUSTEXIST,     // Flags
      '',
      '',
      initial_directory
      );

   result=strip(result,'B','"');
   p_window_id=wid;
   return result;
}

static void debug_gdb_reset_checkboxes(_str attr_name, _str value)
{
   // find the XML config tree handle
   int fh=debug_get_gdb_config_tree(true);
   if (fh < 0) {
      return;
   }

   // used the saved package index
   int package_index = debug_get_gdb_config_package(true);
   if (package_index <= 0) {
      return;
   }

   // Find all the GDB configuration nodes
   typeless gdb_configs[]; gdb_configs._makeempty();
   int status=_xmlcfg_find_simple_array(fh, VSDEBUG_CONFIG_TAG_CONFIGURATION, gdb_configs, package_index);
   if (!status) {

      // For each node, extract the critical attributes, and add to tree
      int i,n=gdb_configs._length();
      for (i=0; i<n; ++i) {
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
   _str session_name = ctl_session_combo.p_text;
   if (session_name == '') {
      debug_message("You must supply a session name!",0,true);
      ctl_session_combo._set_focus();
      return;
   }

   // make sure the session name is unique
   _str debug_cb_name = ctl_session_combo.p_user;
   int session_id = dbg_find_session(session_name);
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
   // get all the available debugger sessions
   int session_ids[];
   dbg_get_all_sessions(session_ids);

   // load all the session names into the combo box
   int max_width = 0;
   _str session_name = "";
   _str first_name = "";
   int i,n = session_ids._length();
   for (i=n-1; i>=0; --i) {
      int session_id = session_ids[i];
      if (dbg_is_session_active(session_id)) {
         continue;
      }
      if (debug_cb_name != "" && dbg_get_callback_name(session_id) != debug_cb_name) {
         continue;
      }

      session_name = dbg_get_session_name(session_id);
      if (first_name == "") first_name = session_name;
      _lbadd_item(session_name);
      _cbset_text(session_name);
      
      int item_width = _text_width(session_name);
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
   return max_width;
}
void ctl_ok.on_create(_str debug_cb_name=_project_DebugCallbackName,
                      _str default_name='')
{
   // save the callback name for verification later
   ctl_session_combo.p_user = debug_cb_name;

   // get all the available debugger sessions
   max_width := ctl_session_combo.debug_load_session_names(debug_cb_name, default_name);

   // If the workspace session is not active, and of the right type,
   // and there is no session matching the default name.
   // Then make the workspace session name the default.
   boolean use_workspace_as_default = false;
   int workspace_session_id = debug_get_workspace_session_id();
   if (dbg_find_session(default_name) <= 0 &&
       debug_cb_name == _project_DebugCallbackName &&
       !dbg_is_session_active(workspace_session_id)) {
      ctl_session_combo.p_text = dbg_get_session_name(workspace_session_id);
      use_workspace_as_default = true;
   }

   // did they provide a default name for this session?
   if (default_name != '') {
      ctl_session_combo._lbadd_item(default_name);
      if (!use_workspace_as_default) {
         ctl_session_combo.p_text = default_name;
      }
      
      int item_width = ctl_session_combo._text_width(default_name);
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
// Callbacks for JDWP debugger attach form
//
defeventtab _debug_jdwp_attach_form;
void ctl_ok.lbutton_up()
{
   // verify that the port is a positive integer
   if (ctl_port.p_text!='' && (!isinteger(ctl_port.p_text) || (int)ctl_port.p_text < 0)) {
      debug_message("Expecting a positive integer value!",0,true);
      ctl_port._set_focus();
      return;
   }

   // get the session name
   _str session_name = ctl_session_combo.p_text;
   
   _save_form_response();
   p_active_form._delete_window("host="ctl_host.p_text",port="ctl_port.p_text",session="session_name);
}
void ctl_ok.on_create(_str session_name="")
{
   // get all the available debugger sessions
   // and resize form so that session name can be fully displayed
   max_width := ctl_session_combo.debug_load_session_names("jdwp", session_name);
   if (max_width > ctl_session_combo.p_width) {
      delta := max_width - ctl_session_combo.p_width;
      p_active_form.p_width += delta;
      ctl_host.p_width = max_width;
      ctl_session_combo.p_width = max_width;
   }

   _retrieve_prev_form();

   // select the default session name
   if (session_name != "") {
      ctl_session_combo._cbset_text(session_name);
   } else if (ctl_session_combo.p_text == "") {
      ctl_session_combo._cbset_text(VSDEBUG_NEW_SESSION);
   }
}

///////////////////////////////////////////////////////////////////////////
// Callbacks for GDB debugger attach form
//
defeventtab _debug_gdb_attach_form;
void ctl_ok.lbutton_up()
{
   // verify that the PID is a positive integer
   int index=ctl_processes._TreeCurIndex();
   if (index <= 0) {
      debug_message("Please select a process!",0,true);
      ctl_processes._set_focus();
      return;
   }
   _str process_id=ctl_processes._TreeGetCaption(index);
   parse process_id with . "\t" process_id "\t" . ;
   _str process_name=ctl_file.p_text;
   if (process_id!='' && (!isinteger(process_id) || (int)process_id < 0)) {
      debug_message("Expecting a positive integer value!",0,true);
      ctl_processes._set_focus();
      return;
   }
   if (process_name!='' && !file_exists(process_name)) {
      debug_message(process_name,FILE_NOT_FOUND_RC,true);
      ctl_file._set_focus();
      return;
   } else if (process_name=='') {
      int response=_message_box("Warning: If you do not specify a filename,\n there will be no debugging information.","SlickEdit",MB_OKCANCEL|MB_ICONEXCLAMATION);
      if (response==IDCANCEL) {
         ctl_file._set_focus();
         return;
      }
   }

   // get the session name
   _str session_name = ctl_session_combo.p_text;
   
   _save_form_response();
   p_active_form._delete_window("pid="process_id",app="process_name",session="session_name);
}

static _refresh_process_list()
{
   PROCESS_INFO pl[];
   _list_processes(pl);
   int index,i,n=pl._length(),pid=getpid();
   _str process_name = _strip_filename(ctl_file.p_text,'P');
   _str process_name_no_ext = _strip_filename(process_name,'E');
   _TreeBeginUpdate(TREE_ROOT_INDEX);
   _TreeDelete(TREE_ROOT_INDEX, 'C');
   for (i=0; i<n; ++i) {
      int hidden = TREENODE_HIDDEN;
      if ((ctl_system.p_value || !pl[i].is_system) && pl[i].pid != pid) {
         hidden=0;
      }
      index = _TreeAddItem(TREE_ROOT_INDEX,
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

void ctl_ok.on_create(_str session_name="")
{
   // get all the available debugger sessions
   max_width := ctl_session_combo.debug_load_session_names("gdb", session_name);
   if (max_width > ctl_session_combo.p_width) {
      delta := max_width - ctl_session_combo.p_width;
      p_active_form.p_width += delta;
      ctl_processes.p_width += delta;
      ctl_file.p_width += delta;
      ctl_refresh.p_x += delta;
      ctl_session_combo.p_width = max_width;
   }

   sizeBrowseButtonToTextBox(ctl_file.p_window_id, ctl_find_app.p_window_id);

   ctl_processes._TreeSetColButtonInfo(0,1500,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Name");
   ctl_processes._TreeSetColButtonInfo(1,500,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_AL_RIGHT,0,"PID");
   ctl_processes._TreeSetColButtonInfo(2,-1,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Title");
   ctl_processes._TreeAdjustLastColButtonWidth(); 

   // need to populate combo box with list of processes, and search
   // within it for a process who's name matches the current project
   // executable name
   ctl_file.p_text="";
   _retrieve_prev_form();
   ctl_processes._refresh_process_list();

   // select the default session name
   if (session_name != "") {
      ctl_session_combo._cbset_text(session_name);
   } else if (ctl_session_combo.p_text == "") {
      ctl_session_combo._cbset_text(VSDEBUG_NEW_SESSION);
   }
}

void ctl_processes.lbutton_double_click()
{
   ctl_ok.call_event(ctl_ok,LBUTTON_UP);
}

void ctl_refresh.lbutton_up()
{
   ctl_processes._refresh_process_list();
}

void ctl_system.lbutton_up()
{
   int pid = getpid();
   int index = ctl_processes._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (index > 0) {
      int hidden=TREENODE_HIDDEN;
      if (ctl_system.p_value || !ctl_processes._TreeGetUserInfo(index)) {
         _str caption = ctl_processes._TreeGetCaption(index);
         _str tree_pid;
         parse caption with . "\t" tree_pid "\t" .;
         if (pid != (int)tree_pid) {
            hidden=0;
         }
      }
      ctl_processes._TreeSetInfo(index, -1, 0, 0, hidden);
      index = ctl_processes._TreeGetNextSiblingIndex(index);
   }
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _link_order_form_initial_alignment()
{
   // size the buttons to the textbox
   sizeBrowseButtonToTextBox(ctl_file.p_window_id, ctl_find_app.p_window_id, 0, ctl_processes.p_x + ctl_processes.p_width);
}

void _debug_gdb_attach_form.on_resize()
{
   // we always need a little padding
   padding := ctl_label.p_x;

   // width/height of OK, Cancel, Help buttons (all are the same)
   int button_width  = ctl_ok.p_width;
   int button_height = ctl_ok.p_height;

   // have we set the min size yet?  if not, min width will be 0
   if (!_minimum_width()) {
      _set_minimum_size(button_width*3, button_height*8);
   }

   int client_height=p_height;
   int client_width=p_width;

   // figure out how much the width changed
   widthDiff := client_width - (ctl_processes.p_width + 2 * padding);
   if (widthDiff) {
      origTreeWidth := ctl_processes.p_width;
      ctl_processes.p_width += widthDiff;
      ctl_processes._TreeScaleColButtonWidths(origTreeWidth, true);
      ctl_refresh.p_x += widthDiff;
      ctl_file.p_width += widthDiff;
      ctl_find_app.p_x += widthDiff;
      ctl_session_combo.p_width+=widthDiff;
   }

   heightDiff := client_height - (ctl_ok.p_y + ctl_ok.p_height + padding);
   if (heightDiff) {
      ctl_processes.p_height += heightDiff;
      ctl_refresh.p_y += heightDiff;
      ctl_ok.p_y += heightDiff;
      ctl_cancel.p_y += heightDiff;
      ctl_file_label.p_y += heightDiff;
      ctl_file.p_y += heightDiff;
      ctl_find_app.p_y += heightDiff;
      ctl_system.p_y += heightDiff;
      ctl_session_label.p_y+=heightDiff;
      ctl_session_combo.p_y+=heightDiff;
   }

}


///////////////////////////////////////////////////////////////////////////
// Callbacks for GDB debugger core file attach form
//
defeventtab _debug_gdb_corefile_form;
void ctl_ok.lbutton_up()
{
   // verify that the core file was specified
   _str core_file=ctl_core.p_text;
   _str process_name=ctl_file.p_text;
   if (core_file=='') {
      debug_message("Expecting a core file!",0,true);
      ctl_core._set_focus();
      return;
   } else if (!file_exists(core_file)) {
      debug_message(core_file,FILE_NOT_FOUND_RC,true);
      return;
   }
   if (process_name!='' && !file_exists(process_name)) {
      debug_message(process_name,FILE_NOT_FOUND_RC,true);
      ctl_file._set_focus();
      return;
   } else if (process_name=='') {
      int response=_message_box("Warning: If you do not specify a filename,\n there may be no symbolic debugging information.","SlickEdit",MB_OKCANCEL|MB_ICONEXCLAMATION);
      if (response==IDCANCEL) {
         ctl_file._set_focus();
         return;
      }
   }

   // finally, get the selected GDB path and supplemental arguments
   _str gdb_name='';
   _str gdb_path='';
   _str gdb_args='';
   int line_no=ctl_gdb.p_line;
   _str gdb_info[] = ctl_gdb.p_user;
   if (line_no > 0 && line_no <= gdb_info._length()) {
      parse gdb_info[line_no-1] with gdb_name "\t" gdb_path "\t" gdb_args;
   }

   // get the session name
   _str session_name = ctl_session_combo.p_text;
   
   // that's all folks
   _save_form_response();
   p_active_form._delete_window("core="core_file",app="process_name",path="gdb_path",args="gdb_args",session="session_name);
}
void ctl_ok.on_create(_str session_name="")
{
   // load the list of GDB configurations
   ctl_gdb.debug_gui_load_configurations_list();

   // get all the available debugger sessions
   max_width := ctl_session_combo.debug_load_session_names("gdb", session_name);
   if (max_width > ctl_session_combo.p_width) {
      delta := max_width - ctl_session_combo.p_width;
      p_active_form.p_width += delta;
      ctl_core.p_width += delta;
      ctl_file.p_width += delta;
      ctl_gdb.p_width += delta;
      ctl_gdb_config.p_x += delta;
      ctl_session_combo.p_width = max_width;
   }

   // adjust alighment of browse buttons
   _debug_gdb_corefile_form_initial_alignment();

   // restore the last response they entered
   ctl_file.p_text="";
   _retrieve_prev_form();
   if (ctl_core.p_text=="") {
      ctl_core.p_text="core";
   }

   // select the default session name
   if (session_name != "") {
      ctl_session_combo._cbset_text(session_name);
   } else if (ctl_session_combo.p_text == "") {
      ctl_session_combo._cbset_text(VSDEBUG_NEW_SESSION);
   }

}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _debug_gdb_corefile_form_initial_alignment()
{
   sizeBrowseButtonToTextBox(ctl_core, ctl_find_core.p_window_id);
   sizeBrowseButtonToTextBox(ctl_file, ctl_find_exec.p_window_id);
}

///////////////////////////////////////////////////////////////////////////
// Callbacks for GDB debug other executable attach form
//
defeventtab _debug_gdb_executable_form;
static void debug_gui_executable_ok(_str command)
{
   // verify that the core file was specified
   _str program_name=ctl_file.p_text;
   _str program_args=ctl_args.p_text;
   if (program_name=='') {
      debug_message("Expecting an executable file!",0,true);
      ctl_file._set_focus();
      return;
   } else if (!file_exists(_unquote_filename(program_name))) {
      debug_message(program_name,FILE_NOT_FOUND_RC,true);
      return;
   }

   // get the working directory specified
   _str dir_name=ctl_dir.p_text;
   if (dir_name != '' && !file_exists(_unquote_filename(dir_name))) {
      debug_message(dir_name,FILE_NOT_FOUND_RC,true);
      return;
   }

   // get the session name
   _str session_name = ctl_session_combo.p_text;
   
   // that's all folks
   _save_form_response();
   p_active_form._delete_window("command="command",app="program_name",dir="dir_name",args="program_args",session="session_name);
}
void ctl_step.lbutton_up()
{
   debug_gui_executable_ok("step");
}
void ctl_run.lbutton_up()
{
   debug_gui_executable_ok("run");
}
void ctl_step.on_create(_str session_name="")
{
   // get all the available debugger sessions
   max_width := ctl_session_combo.debug_load_session_names("gdb", session_name);
   max_width += 500;
   if (max_width > ctl_session_combo.p_width) {
      p_active_form.p_width += (max_width - ctl_session_combo.p_width);
      ctl_dir.p_width = max_width;
      ctl_file.p_width = max_width;
      ctl_args.p_width = max_width;
      ctl_session_combo.p_width = max_width;
   }

   // align the browse buttons to the text boxes
   _debug_gdb_executable_form_initial_alignment();

   // restore the last response they entered
   ctl_file.p_text="";
   ctl_dir.p_text="";
   ctl_args.p_text="";
   _retrieve_prev_form();

   // make sure the session they passed in is selected
   if (session_name != "") {
      ctl_session_combo._cbset_text(session_name);
   } else if (ctl_session_combo.p_text == "") {
      ctl_session_combo._cbset_text(VSDEBUG_NEW_SESSION);
   }
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _debug_gdb_executable_form_initial_alignment()
{
   sizeBrowseButtonToTextBox(ctl_file, ctl_find_exec.p_window_id);
   sizeBrowseButtonToTextBox(ctl_dir, ctl_find_dir.p_window_id);
}

///////////////////////////////////////////////////////////////////////////
// Callbacks for GDB debugger remote attach form
//
defeventtab _debug_gdb_remote_form;
static void debug_gdb_remote_enable_disable_form(boolean en)
{
   ctl_host_label.p_enabled = en;
   ctl_host.p_enabled = en;
   ctl_port_label.p_enabled = en;
   ctl_port.p_enabled= en;

   en=!en;
   ctl_device_label.p_enabled = en;
   ctl_device.p_enabled = en;
   ctl_baud_label.p_enabled = en;
   ctl_baud.p_enabled = en;
}
void ctl_device_radio.lbutton_up()
{
   boolean en = p_value? false:true;
   debug_gdb_remote_enable_disable_form(en);
}
void ctl_socket_radio.lbutton_up()
{
   boolean en = p_value? true:false;
   debug_gdb_remote_enable_disable_form(en);
}
void ctl_ok.lbutton_up()
{
   // verify connection properties
   _str port_string='';
   if (ctl_socket_radio.p_value) {
      // verify that the port is a positive integer
      if (ctl_port.p_text!='' && (!isinteger(ctl_port.p_text) || (int)ctl_port.p_text < 0)) {
         debug_message("Expecting a positive integer value!",0,true);
         ctl_tab.p_ActiveTab=0;
         ctl_port._set_focus();
         return;
      }
      port_string="host="ctl_host.p_text",port="ctl_port.p_text;
   }

   if (ctl_device_radio.p_value) {
      // verify that the port is a positive integer
      if (ctl_baud.p_text!='' && (!isinteger(ctl_baud.p_text) || (int)ctl_baud.p_text < 0)) {
         debug_message("Expecting a positive integer value!",0,true);
         ctl_tab.p_ActiveTab=0;
         ctl_baud._set_focus();
         return;
      }
      port_string="device="ctl_device.p_text",baud="ctl_baud.p_text;
   }


   // check that the timeout is a valid integer
   if (ctl_timeout.p_text!='' && (!isinteger(ctl_timeout.p_text) || (int)ctl_timeout.p_text < 0)) {
      debug_message("Expecting a positive integer value!",0,true);
      ctl_tab.p_ActiveTab=1;
      ctl_timeout._set_focus();
      return;
   } else {
      port_string=port_string:+",timeout="ctl_timeout.p_text;
   }

   // check that the address is a valid integer
   if (ctl_address_size.p_text!="" && ctl_address_size.p_text!="Default" &&
       (!isinteger(ctl_address_size.p_text) || (int)ctl_address_size.p_text < 0)) {
      debug_message("Expecting a positive integer value!",0,true);
      ctl_tab.p_ActiveTab=1;
      ctl_timeout._set_focus();
      return;
   } else {
      numBits := ctl_address_size.p_text;
      if (numBits == "Default") numBits = "";
      port_string=port_string:+",address="numBits;
   }

   // save the check box settings
   port_string=port_string:+",cache="ctl_cache.p_value;
   port_string=port_string:+",break="ctl_break.p_value;

   // finally, check the file name (for symbols)
   _str process_name=ctl_file.p_text;
   if (process_name!='' && !file_exists(process_name)) {
      debug_message(process_name,FILE_NOT_FOUND_RC,true);
      ctl_tab.p_ActiveTab=0;
      ctl_file._set_focus();
      return;
   } else if (process_name=='') {
      int response=_message_box("Warning: If you do not specify a filename,\n there may be no symbolic debugging information.","SlickEdit",MB_OKCANCEL|MB_ICONEXCLAMATION);
      if (response==IDCANCEL) {
         ctl_tab.p_ActiveTab=0;
         ctl_file._set_focus();
         return;
      }
   }

   // finally, get the selected GDB path and supplemental arguments
   _str gdb_name='';
   _str gdb_path='';
   _str gdb_args='';
   int line_no=ctl_gdb.p_line;
   _str gdb_info[] = ctl_gdb.p_user;
   if (line_no > 0 && line_no <= gdb_info._length()) {
      parse gdb_info[line_no-1] with gdb_name "\t" gdb_path "\t" gdb_args;
   }

   // get the session name
   _str session_name = ctl_session_combo.p_text;
   
   // that's all folks
   _save_form_response();
   p_active_form._delete_window("file="ctl_file.p_text","port_string",path="gdb_path",args="gdb_args",session="session_name);
}
/**
 * The current object must be a combo-box.
 * Load the list of GDB configurations into the box.
 */
static void debug_gui_load_configurations_list()
{
   // get the path to the GDB configuration file
   _str filename=_ConfigPath():+DEBUGGER_CONFIG_FILENAME;
   if (!file_exists(filename)) {
      filename=get_env("VSROOT"):+DEBUGGER_CONFIG_FILENAME;
   }

   // clear the list of configurations
   _lbclear();
   _col_width(0,0);
   p_user = null;

   // open the XML configuration file
   _str gdb_config_array[]; gdb_config_array._makeempty();
   int status=0;

   // Always insert the standard GDB bundled with SlickEdit
   _str standard_gdb = debug_get_slickedit_gdb();
   _lbadd_item(VSDEBUG_CONFIG_VALUE_STANDARD_GDB);
   gdb_config_array[gdb_config_array._length()] = VSDEBUG_CONFIG_VALUE_STANDARD_GDB:+"\t":+standard_gdb:+"\t";

   int fh=_xmlcfg_open(filename,status);
   if (!status) {
      // find the Debugger tag
      int debugger_index = _xmlcfg_find_simple(fh, VSDEBUG_CONFIG_TAG_DEBUGGER);
      if (debugger_index > 0) {
         // find the Package section for GDB
         int package_index = _xmlcfg_find_simple(fh, VSDEBUG_CONFIG_TAG_PACKAGE"[@"VSDEBUG_CONFIG_ATTR_NAME"='"VSDEBUG_CONFIG_VALUE_GDB"']", debugger_index);
         if (package_index > 0) {
            // Find all the GDB configuration nodes
            typeless gdb_configs[]; gdb_configs._makeempty();
            status=_xmlcfg_find_simple_array(fh, VSDEBUG_CONFIG_TAG_CONFIGURATION, gdb_configs, package_index);
            if (!status) {
               // For each node, extract the critical attributes, and add to tree
               int i,n=gdb_configs._length();
               for (i=0; i<n; ++i) {
                  if (isThisPlatform(_xmlcfg_get_attribute(fh, gdb_configs[i], VSDEBUG_CONFIG_ATTR_PLATFORM))) {
                     _str gdb_name = _xmlcfg_get_attribute(fh, gdb_configs[i], VSDEBUG_CONFIG_ATTR_NAME);
                     _str gdb_path = _xmlcfg_get_attribute(fh, gdb_configs[i], VSDEBUG_CONFIG_ATTR_PATH);
                     _str gdb_args = _xmlcfg_get_attribute(fh, gdb_configs[i], VSDEBUG_CONFIG_ATTR_ARGUMENTS);
                     _str gdb_standard = _xmlcfg_get_attribute(fh, gdb_configs[i], VSDEBUG_CONFIG_ATTR_STANDARD);
                     gdb_path = debug_normalize_config_path(gdb_path);
                     if (gdb_standard!=true) {
                        gdb_config_array[gdb_config_array._length()] = gdb_name:+"\t":+gdb_path:+"\t"gdb_args;
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
   if (p_text=='') {
      p_text=VSDEBUG_CONFIG_VALUE_STANDARD_GDB;
   }
}
void ctl_ok.on_create(_str session_name="")
{
   // make sure all the controls are aligned nicely
   _debug_gdb_remote_form_initial_alignment();

   // get all the available debugger sessions
   max_width := ctl_session_combo.debug_load_session_names("gdb", session_name);
   if (max_width > ctl_session_combo.p_width) {
      delta := max_width - ctl_session_combo.p_width;
      p_active_form.p_width += delta;
      ctl_find_app.p_x += delta;
      ctl_file.p_width += delta;
      ctl_tab.p_width += delta;
      ctl_gdb.p_width += delta;
      ctlframe1.p_width += delta;
      ctl_host.p_width += delta;
      ctl_device.p_width += delta;
      ctl_gdb_config.p_x += delta;
      ctl_session_combo.p_width = max_width;
   }

   // handy default values for baud settings
   ctl_baud._lbadd_item("300");
   ctl_baud._lbadd_item("600");
   ctl_baud._lbadd_item("1200");
   ctl_baud._lbadd_item("2400");
   ctl_baud._lbadd_item("4800");
   ctl_baud._lbadd_item("9600");
   ctl_baud._lbadd_item("14400");
   ctl_baud._lbadd_item("19200");
   ctl_baud._lbadd_item("28800");
   ctl_baud._lbadd_item("38400");
   ctl_baud._lbadd_item("57600");

   // default value for address sizes
   ctl_address_size._lbadd_item("Default");
   ctl_address_size._lbadd_item("8");
   ctl_address_size._lbadd_item("16");
   ctl_address_size._lbadd_item("32");
   ctl_address_size._lbadd_item("64");
   ctl_address_size._cbset_text("Default");

   // handy default values for communication ports
#if __UNIX__
   int ff=1;
   for (;;ff=0) {
      _str file_name = file_match("/dev/tty*",ff);
      if (file_name=="") break;
      ctl_device._lbadd_item(file_name);
   }
   if (machine()=='SPARC' || pos('SOLARIS',machine())) {
      ctl_device._lbadd_item("/dev/sr0");
      ctl_device._lbadd_item("/dev/cua/a");
      ctl_device._lbadd_item("/dev/cua/b");
      ctl_device._lbadd_item("/dev/term/a");
      ctl_device._lbadd_item("/dev/term/b");
   }
#else
   ctl_device._lbadd_item("COM1");
   ctl_device._lbadd_item("COM2");
   ctl_device._lbadd_item("COM3");
   ctl_device._lbadd_item("COM4");
#endif

   // load the list of GDB configurations
   ctl_gdb.debug_gui_load_configurations_list();

   // get the previous form values
   _retrieve_prev_form();
   if (ctl_address_size.p_text == "") {
      ctl_address_size.p_text = "Default";
   }

   // select the default session name
   if (session_name != "") {
      ctl_session_combo._cbset_text(session_name);
   } else if (ctl_session_combo.p_text == "") {
      ctl_session_combo._cbset_text(VSDEBUG_NEW_SESSION);
   }

   // enable/disable the appropriate items
   ctl_tab.p_ActiveTab=0;
   boolean en = ctl_socket_radio.p_value? true:false;
   debug_gdb_remote_enable_disable_form(en);
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _debug_gdb_remote_form_initial_alignment()
{
   rightAlign := ctl_session_combo.p_x + ctl_session_combo.p_width;
   sizeBrowseButtonToTextBox(ctl_file.p_window_id, ctl_find_app.p_window_id, 0, rightAlign);
}

void ctl_gdb_config.lbutton_up()
{
   int combo_wid=ctl_gdb;
   debug_configurations();
   combo_wid.debug_gui_load_configurations_list();
}
void ctl_gdb.on_change(int reason)
{
   int line_no=p_line;
   _str gdb_info[] = ctl_gdb.p_user;
   if (line_no > 0 && line_no <= gdb_info._length()) {
      _str gdb_name='';
      _str gdb_path='';
      _str gdb_args='';
      parse gdb_info[line_no-1] with gdb_name "\t" gdb_path "\t" gdb_args;
      ctl_args.p_caption=gdb_path' 'gdb_args;
   }
}


///////////////////////////////////////////////////////////////////////////
// Handlers for debugger sessions combo box / toolbar
//
#define VSDEBUG_SESSIONS_FORM "_tbdebug_sessions_form"
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

      int session_line = 1;
      int session_ids[];
      dbg_get_all_sessions(session_ids);

      _lbclear();
      int i,n = session_ids._length();
      for (i=0; i<n; ++i) {
         if (debug_active() && !dbg_is_session_active(session_ids[i])) {
            continue;
         }
         _str session_name = dbg_get_session_name(session_ids[i]);
         if (session_name == '') {
            continue;
         }
         _lbadd_item(session_name);
         if (session_ids[i] == dbg_get_current_session()) {
            session_line = p_line;
         }
      }

      if (n > 0) {
         _lbsort('i');
      } else {
         _lbadd_item("no debugger sessions");
      }

      int h = p_pic_space_y + _text_height();
      h *= (p_Noflines+1);
      int screen_x,screen_y,screen_width,screen_height;
      _GetVisibleScreen(screen_x,screen_y,screen_width,screen_height);
      int sh = (screen_height*_twips_per_pixel_y()) intdiv 2;
      p_height = (h>sh)? sh:h;
      _lbtop();
      p_line=session_line;

   } else if (reason==DROP_UP_SELECTED) {

      _str selected_caption = _lbget_text();
      int selected_session_id = dbg_find_session(selected_caption);
      if (selected_session_id <= 0) return;
      if (selected_session_id != dbg_get_current_session()) {
         mou_hour_glass(1);
         dbg_set_current_session(selected_session_id);
         debug_gui_update_session();
         debug_pkg_enable_disable_tabs();
         mou_hour_glass(0);
      }
   }
}
void _tbdebug_combo_etab.on_change(int reason)
{
   return;
   _str selected_caption = _lbget_text();
   int selected_session_id = dbg_find_session(selected_caption);
   if (selected_session_id <= 0) return;
   if (selected_session_id != dbg_get_current_session()) {
      mou_hour_glass(1);
      dbg_set_current_session(selected_session_id);
      debug_gui_update_session();
      debug_pkg_enable_disable_tabs();
      mou_hour_glass(0);
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
   int wid = debug_gui_session_list();
   if (wid <= 0) {
      return;
   }

   int session_id = dbg_get_current_session();
   int session_ids[];
   dbg_get_all_sessions(session_ids);

   wid._lbclear();
   wid._lbadd_item("no debugger sessions");
   int i,n = session_ids._length();
   for (i=0; i<n; ++i) {
      _str session_name = dbg_get_session_name(session_ids[i]);
      wid._lbadd_item(session_name);
   }

   if (session_id > 0) {
      wid.p_text = dbg_get_session_name(session_id);
   } else {
      wid.p_text = "no debugger sessions";
   }
}


///////////////////////////////////////////////////////////////////////////
// Handlers for debug threads toolbar
//
#define VSDEBUG_THREADS_FORM "_tbdebug_threads_form"
defeventtab _tbdebug_threads_form;
void _tbdebug_threads_form.'C-A'-'C-Z',F2-F4,f6-F12,C_F12,'c-a-a'-'c-a-z','a-0'-'a-9'()
{
   _smart_toolbar_hotkey();
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
   dbg_invalidate_views();

   ctl_threads_tree._TreeSetColButtonInfo(0,1500,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Thread");
   ctl_threads_tree._TreeSetColButtonInfo(1,1500,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Group");
   ctl_threads_tree._TreeSetColButtonInfo(2,1500,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Status");
   ctl_threads_tree._TreeSetColButtonInfo(3,-1,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"State");
   ctl_threads_tree._TreeRetrieveColButtonInfo();
   ctl_threads_tree._TreeAdjustLastColButtonWidth(); 
   ctl_threads_tree.p_user = 0;

   debug_pkg_enable_disable_tabs();
   debug_gui_update_threads();
}
void _tbdebug_threads_form.on_destroy()
{
   ctl_threads_tree._TreeAppendColButtonInfo();
}
static void debug_gui_save_settings()
{
   // Process the trees in a tab control or form

   if (p_object==OI_SSTAB) {
      _append_retrieve(p_window_id, p_ActiveTab);
      // for each tab container
      int first_child=p_child;
      int wid=first_child;
      for (;;) {
         // for each control in the tab container
         int first_ctl=wid.p_child;
         int ctl=first_ctl;
         for (;;) {
            // if we find a tree, then save its column widths
            if (ctl.p_object==OI_TREE_VIEW) {
               ctl._TreeAppendColButtonInfo();
            }
            // next control please
            ctl=ctl.p_next;
            if (ctl==first_ctl) {
               break;
            }
         }
         // next tab please
         wid=wid.p_next;
         if (wid==first_child) {
            break;
         }
      }

   } else if (p_object==OI_TREE_VIEW) {
      _TreeAppendColButtonInfo();
   } 
}

void _tbdebug_threads_form.on_resize()
{
   _nocheck _control ctl_threads_tree;
   debug_gui_resize_toolbar(0,ctl_threads_tree);
}
void _tbdebug_threads_form.on_change(int reason)
{ 
   _nocheck _control ctl_threads_tree;
   if( ctl_threads_tree.p_user && reason==CHANGE_AUTO_SHOW ) {
      debug_gui_update_threads(true);
   }
}
void _tbdebug_threads_form.on_got_focus()
{ 
   _nocheck _control ctl_threads_tree;
   if ( ctl_threads_tree.p_user ) {
      debug_gui_update_threads();
   }
}
void ctl_threads_tree.on_change(int reason,int index)
{
   if (!debug_active()) return;
   if (gInUpdateThreadList) return;
   //say("ctl_threads_tree.on_change: reason="reason" index="index);
   if (reason == CHANGE_SELECTED || reason == CHANGE_LEAF_ENTER) {
      int cur_index=_TreeCurIndex();
      if (cur_index > 0) {
         int show_children=0;
         _TreeGetInfo(cur_index, show_children);
         if (show_children < 0) {
            int thread_id=_TreeGetUserInfo(cur_index);
            int frame_id=dbg_get_cur_frame(thread_id);
            //say("ctl_threads_tree.on_change: thread_id="thread_id);
            dbg_set_cur_thread(thread_id);
            debug_gui_update_cur_thread(thread_id);
            debug_gui_update_stack(thread_id);
            debug_gui_switch_frame(thread_id,frame_id);
            if (debug_is_suspended() && reason == CHANGE_LEAF_ENTER) {
               debug_show_next_statement(true,0,0,'','',thread_id,frame_id);
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
   int tree_index=tree_wid._TreeCurIndex();
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
   int index=find_index("_debug_threads_menu",oi2type(OI_MENU));
   if (!index) {
      return;
   }
   int menu_handle=p_active_form._menu_load(index,'P');
   CTL_TREE tree_wid=p_window_id;

   // Show the menu.
   int x=mou_last_x('M')-100;
   int y=mou_last_y('M')-100;
   _lxy2dxy(p_scale_mode,x,y);
   _map_xy(p_window_id,0,x,y,SM_PIXEL);
   _KillToolButtonTimer();
   _menu_show(menu_handle,VPM_LEFTALIGN|VPM_RIGHTBUTTON,x,y);
   _menu_destroy(menu_handle);
}


///////////////////////////////////////////////////////////////////////////
// Handlers for debugger call stack toolbar
//
#define VSDEBUG_STACK_FORM "_tbdebug_stack_form"
defeventtab _tbdebug_stack_form;
void _tbdebug_stack_form.'C-A'-'C-Z',F2-F4,f6-F12,C_F12,'c-a-a'-'c-a-z','a-0'-'a-9'()
{
   _smart_toolbar_hotkey();
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
   ctl_stack_tree._TreeRetrieveColButtonWidths();
   ctl_stack_tree._TreeAdjustLastColButtonWidth(); 

   debug_pkg_enable_disable_tabs();
   status := debug_pkg_update_threads();
   if (status != DEBUG_GDB_TIMEOUT_RC) {
      status = debug_pkg_update_threadgroups();
   }
   if (status != DEBUG_GDB_TIMEOUT_RC) {
      status = debug_pkg_update_threadnames();
   }
   if (status != DEBUG_GDB_TIMEOUT_RC) {
      status = debug_pkg_update_threadstates();
   }
   debug_gui_update_suspended();
   int thread_id=dbg_get_cur_thread();
   dbg_update_thread_list(ctl_thread_combo.p_window_id,true);
   ctl_thread_combo.p_line=thread_id;
   ctl_thread_combo._lbselect_line();
   ctl_thread_combo.p_text=ctl_thread_combo._lbget_text();
   if (status != DEBUG_GDB_TIMEOUT_RC) {
      status = debug_pkg_update_stack(thread_id);
   }
   dbg_update_stack_tree(ctl_stack_tree,TREE_ROOT_INDEX,thread_id);
   ctl_stack_tree._TreeSortUserInfo(TREE_ROOT_INDEX,'N');
}
void _tbdebug_stack_form.on_destroy()
{
   ctl_stack_tree._TreeAppendColButtonInfo();
}
void _tbdebug_stack_form.on_resize()
{
   _nocheck _control ctl_stack_tree;
   _nocheck _control ctl_thread_combo;

   // adjust breakpoints for resizable icons
   ctl_stack_tree.p_x = ctl_top_btn.p_x*2 + ctl_top_btn.p_width;
   ctl_up_btn.p_y = ctl_top_btn.p_y + ctl_top_btn.p_height;
   ctl_down_btn.p_y = ctl_up_btn.p_y + ctl_up_btn.p_height;

   // now resize the rest of the toolbar
   debug_gui_resize_toolbar(0,ctl_stack_tree,0,ctl_thread_combo);
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
   CTL_COMBO list_wid=debug_gui_stack_thread_list();
   if (list_wid) {
      list_wid._lbclear();
      list_wid.p_text='';
   }
}
void ctl_thread_combo.on_got_focus()
{
   if (gInUpdateThreadList) return;
   _str orig_text=p_text;
   gInUpdateThreadList = true;
   _lbclear();
   debug_pkg_update_threads();
   debug_pkg_update_threadgroups();
   debug_pkg_update_threadnames();
   debug_pkg_update_threadstates();
   dbg_update_thread_list(p_window_id,true);
   _cbset_text(orig_text);
   gInUpdateThreadList = false;
}
void ctl_thread_combo.on_drop_down(int reason)
{
   // set caption and bitmaps for current context
   if (gInUpdateThreadList) return;
   if (reason==DROP_DOWN) {
      _str orig_text=p_text;
      gInUpdateThreadList = true;
      debug_pkg_update_threads();
      debug_pkg_update_threadgroups();
      debug_pkg_update_threadnames();
      debug_pkg_update_threadstates();
      _lbclear();
      dbg_update_thread_list(p_window_id,true);
      _cbset_text(orig_text);
      gInUpdateThreadList = false;
   }  else if (reason==DROP_UP) {
   }  else if (reason==DROP_UP_SELECTED) {
      int thread_id=p_line;
      int frame_id=dbg_get_cur_frame(thread_id);
      dbg_set_cur_suspended_thread(thread_id);
      debug_gui_update_cur_thread(thread_id);
      debug_gui_update_stack(thread_id);
      debug_gui_switch_frame(thread_id,frame_id);
   }
}
void ctl_thread_combo.on_change(int reason, int index=0)
{
   if (!debug_active()) return;
   if (gInUpdateThreadList || gInUpdateThread) return;
   if (reason == CHANGE_CLINE || reason==CHANGE_CLINE_NOTVIS) {
      gInUpdateThread=true;
      if (index >= 0) p_line=index;
      if (p_line != index) p_text=p_text;
      gInUpdateThread=false;
      int thread_id=p_line;
      if (thread_id > 0 && thread_id <= dbg_get_num_threads()) {
         int frame_id=dbg_get_cur_frame(thread_id);
         dbg_set_cur_suspended_thread(thread_id);
         debug_gui_update_cur_thread(thread_id);
         debug_gui_update_stack(thread_id);
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
      int cur_index=_TreeCurIndex();
      if (cur_index > 0) {
         int thread_id=dbg_get_cur_thread();
         int frame_id=_TreeGetUserInfo(cur_index);
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
   int cur_index=_TreeCurIndex();
   if (cur_index > 0) {
      int thread_id=dbg_get_cur_thread();
      int frame_id=_TreeGetUserInfo(cur_index);
      int status=debug_gui_switch_frame(thread_id,frame_id);
      if (!status) {
         debug_show_next_statement(false,0,0,'','',thread_id,frame_id);
      }
   }
}
// Handle right-button released event, in order to display pop-up menu
// for the threads tree.
//
void ctl_stack_tree.rbutton_up()
{
   // get the menu form
   int index=find_index("_debug_stack_menu",oi2type(OI_MENU));
   if (!index) {
      return;
   }
   int menu_handle=p_active_form._menu_load(index,'P');
   CTL_TREE tree_wid=p_window_id;

   // Show the menu.
   int x=mou_last_x('M')-100;
   int y=mou_last_y('M')-100;
   _lxy2dxy(p_scale_mode,x,y);
   _map_xy(p_window_id,0,x,y,SM_PIXEL);
   _KillToolButtonTimer();
   _menu_show(menu_handle,VPM_LEFTALIGN|VPM_RIGHTBUTTON,x,y);
   _menu_destroy(menu_handle);
}

void debug_gui_stack_update_buttons()
{
   CTL_FORM form_wid=debug_gui_stack_wid();
   if (!form_wid) {
      return;
   }
   CTL_TREE tree_wid=debug_gui_stack_tree();
   if (!tree_wid) {
      return;
   }
   boolean down_enabled=true;
   boolean up_enabled=true;
   boolean top_enabled=true;
   int no_of_frames=tree_wid._TreeGetNumChildren(TREE_ROOT_INDEX);
   int tree_index=tree_wid._TreeCurIndex();
   if (no_of_frames>0 && tree_index>0 && debug_is_suspended()) {
      int frame_id=tree_wid._TreeGetUserInfo(tree_index);
      int thread_id=dbg_get_cur_thread();
      _str file_name='';
      int line_number=0;
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
      return '';
   }
   _str path=_TreeGetUserInfo(tree_index);
   tree_index = _TreeGetParentIndex(tree_index);
   while (tree_index != TREE_ROOT_INDEX) {
       path=_TreeGetUserInfo(tree_index) :+ ' ' :+ path;
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
   int show_children=0;
   _TreeGetInfo(index,show_children);
   _str caption=_TreeGetCaption(index);
   if (show_children >= 0) {
      // check if it is a string, special case
      if (pos('^[^\t]*\t["]?*["]',caption,1,'r')) {
         return(0);
      }
      return(-1);
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
   int index=_TreeGetFirstChildIndex(tree_index);
   while (index > 0) {
      int show_children=0;
      _TreeGetInfo(index,show_children);
      if (show_children > 0) {
         call_event(CHANGE_EXPANDED,index,p_window_id,ON_CHANGE,'w');
         _TreeSetInfo(index, 1);

         // If the first child is an array index, resort the children.
         // When we update the value of an array element, the GUI reinserts
         // it as the last child (same level). We're resorting to fix this.
         //
         int  childIndex = _TreeGetFirstChildIndex( index);
         if (childIndex > 0) {
            _str caption    = _TreeGetCaption( childIndex) ;
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
   _str msg = nls("Error") :+ "\t**" :+ get_message(status) :+ "**";
   int index=_TreeAddItem(TREE_ROOT_INDEX,msg,TREE_ADD_AS_CHILD,0,0,-1,TREENODE_BOLD,0);
   p_window_id._TreeRefresh();
   return(status);
}

/**
 * Display a status message from the debugger as a tree item.
 */
static void debug_warn_if_empty()
{
   if (_TreeGetNumChildren(TREE_ROOT_INDEX)==0) {
      _str msg = "Warning" :+ "\t" :+ "**No symbols visible in this context**";
      int index=_TreeAddItem(TREE_ROOT_INDEX,msg,TREE_ADD_AS_CHILD,0,0,-1,0,0);
   }
}

static void debug_gui_save_tree_columns()
{
   numCols := _TreeGetNumColButtons();
   widths := '';

   // get a string containing the column widths
   total := 0;
   for (i := 0; i < numCols; ++i) {
      typeless bw = 0, bf = 0, bs = 0, caption = "";
      _TreeGetColButtonInfo(i, bw, bf, bs, caption);
      widths :+= ' 'bw;
      total += bw;
   }

   // strip off the extra space we added
   widths = substr(widths, 2);

   // we save under the control name, and also under the number of columns (which is variable)
   name := p_active_form.p_name'.'p_name'.'numCols'_button_widths';
   _append_retrieve(0, widths, name);

   _TreeAppendColButtonSorting();
}

static void debug_gui_restore_tree_columns()
{
   numCols := _TreeGetNumColButtons();
   name := p_active_form.p_name'.'p_name'.'numCols'_button_widths';
   widths := _retrieve_value(name);

   // maybe we got nothing?
   if (widths == '') return;
   
   typeless bw = 0, bf = 0, bs = 0, caption = "", w = "";

   for (i := 0; i < numCols; ++i) {
      if (widths=='') break;

      // get the next width
      parse widths with w widths;

      if (isinteger(w)) {
         _TreeGetColButtonInfo(i, bw, bf, bs, caption);
         _TreeSetColButtonInfo(i, w, bf, bs, caption);
      }
   }

   _TreeAdjustLastColButtonWidth(); 
   //_TreeRetrieveColButtonSorting();
}

///////////////////////////////////////////////////////////////////////////
// Handlers for debugger local variables toolbar
//
#define VSDEBUG_LOCALS_FORM "_tbdebug_locals_form"
defeventtab _tbdebug_locals_form;
void _tbdebug_locals_form.'C-A'-'C-Z',F2-F4,f6-F12,C_F12,'c-a-a'-'c-a-z','a-0'-'a-9'()
{
   _smart_toolbar_hotkey();
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
   int editable_flag = (isDynamicDebugger() || debug_session_is_implemented("modify_local")==0)? 0:TREE_EDIT_TEXTBOX;
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
   ctl_locals_tree._TreeSetColButtonInfo(1,col1Width,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_WRAP|TREE_BUTTON_AUTOSIZE,0,"Value");
   ctl_locals_tree._TreeSetColEditStyle(1,editable_flag);
   if (displayType) {
      ctl_locals_tree._TreeSetColButtonInfo(2,col2Width,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_WRAP|TREE_BUTTON_AUTOSIZE,0,"Type");
   }

   ctl_locals_tree.debug_gui_restore_tree_columns();
   ctl_locals_tree.p_user=0;

   debug_pkg_enable_disable_tabs();
   debug_gui_update_suspended();
   int thread_id=dbg_get_cur_thread();
   int frame_id=dbg_get_cur_frame(thread_id);

   status := debug_pkg_update_stack(thread_id);
   if (status != DEBUG_GDB_TIMEOUT_RC) {
      status = debug_gui_update_locals(thread_id,frame_id);
   }
   dbg_update_stack_list(ctl_stack_combo.p_window_id,thread_id);
   debug_gui_update_cur_frame(thread_id,frame_id);
}

void _tbdebug_locals_form.on_destroy()
{
   ctl_locals_tree.debug_gui_save_tree_columns();
}
void _tbdebug_locals_form.on_resize()
{
   _nocheck _control ctl_locals_tree;
   _nocheck _control ctl_stack_combo;
   debug_gui_resize_toolbar(0,ctl_locals_tree,0,ctl_stack_combo);
}

void _tbdebug_locals_form.on_change(int reason)
{ 
   _nocheck _control ctl_locals_tree;
   if( ctl_locals_tree.p_user && reason==CHANGE_AUTO_SHOW ) {
      int thread_id = dbg_get_cur_thread();
      int frame_id=dbg_get_cur_frame(thread_id);
      debug_gui_update_locals(thread_id,frame_id,true);
   }
}
void _tbdebug_locals_form.on_got_focus()
{ 
   _nocheck _control ctl_locals_tree;
   if ( ctl_locals_tree.p_user ) {
      int thread_id = dbg_get_cur_thread();
      int frame_id=dbg_get_cur_frame(thread_id);
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
   int status=0;
   if (reason==CHANGE_SELECTED) {
   } else if (reason==CHANGE_EXPANDED) {
      if (debug_expand_var_requires_suspend(index) < 0) return 0;
      int thread_id=dbg_get_cur_thread();
      int frame_id=dbg_get_cur_frame(thread_id);
      _str local_path=debug_get_variable_path(index);
      status=debug_pkg_expand_local(thread_id,frame_id,local_path);
      if (status) {
         return(status);
      }
      _TreeBeginUpdate(index);
      status=dbg_update_locals_tree(p_window_id,index,thread_id,frame_id,local_path);
      _TreeEndUpdate(index);
      return(status);

   } else if (reason==CHANGE_COLLAPSED) {
      int thread_id=dbg_get_cur_thread();
      int frame_id=dbg_get_cur_frame(thread_id);
      _str local_path=debug_get_variable_path(index);
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
            
            _str sig='', value='', oldValue='', name = '', class_name = '';
            int flags=0, line_number=0, is_in_scope=0;
            dbg_get_local(thread_id, frame_id, path, name, class_name, sig, flags, value, line_number, is_in_scope, oldValue); 
            
            varName := _TreeGetTextForCol(index, 0);
            newValue := '';
            if (!show_modify_variable_dlg(session_id, thread_id, frame_id, oldValue, varName, newValue)) {
               debug_gui_modify_local(index, thread_id, frame_id, path, newValue);
            }
         }
      } 
   } else if (reason == CHANGE_EDIT_OPEN) {
      // get the raw value of the variable
      int thread_id = dbg_get_cur_thread();
      int frame_id  = dbg_get_cur_frame(thread_id);
      _str local_path=debug_get_variable_path(index);
      _str sig='', value='', raw_value='', name = '', class_name = '';
      int flags=0, line_number=0, is_in_scope=0;
      dbg_get_local(thread_id, frame_id, local_path, name, class_name, sig, flags, value, line_number, is_in_scope, raw_value); 

      // set the raw value in the text box, so the user is editing the real thing
      arg(4) = raw_value;

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
      if (arg(4)=='') {
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
   if (newValue=='') return(DELETED_ELEMENT_RC);
   status := debug_pkg_modify_local(thread_id, frame_id, path, newValue);

   // error - show a message, but reload the tree anyway!
   if (status) {
      debug_message("Could not modify local",status);
      if (status!=DEBUG_GDB_ERROR_MODIFYING_VARIABLE_RC &&
          status!=DEBUG_JDWP_ERROR_MODIFYING_VARIABLE_RC) {
         return(-1);
      }
   }

   int parent_index=_TreeGetParentIndex(index);
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
   int index=find_index("_debug_variables_menu",oi2type(OI_MENU));
   if (!index) {
      return;
   }
   int menu_handle=p_active_form._menu_load(index,'P');
   CTL_TREE tree_wid=p_window_id;

   int cur_index=tree_wid._TreeCurIndex();
   if (cur_index <= 0) {
      return;
   }

   int thread_id=dbg_get_cur_thread();
   int frame_id=dbg_get_cur_frame(thread_id);
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
   int x=mou_last_x('M')-100;
   int y=mou_last_y('M')-100;
   _lxy2dxy(p_scale_mode,x,y);
   _map_xy(p_window_id,0,x,y,SM_PIXEL);
   _KillToolButtonTimer();
   _menu_show(menu_handle,VPM_LEFTALIGN|VPM_RIGHTBUTTON,x,y);
   _menu_destroy(menu_handle);
}

static void AddOrRemoveBasesFromMenu(int menu_handle)
{
   int node_index=_TreeCurIndex();
   if ( node_index>-1 ) {
      int state=-1;
      _TreeGetInfo(node_index,state);
      _str caption=_TreeGetCaption(node_index);
      _str ch=first_char(caption);
      _str value='';
      parse caption with . "\t" value;

      if ( state<0 && /*ch!='[' &&*/ ch!='<' && first_char(value) != '"' && 
           debug_gui_check_modifiable(node_index) >= 0 ) {

         _str var_path=debug_get_variable_path(node_index);
         AddBasesToMenu(menu_handle);
      }else{
         int submenu_handle=0;
         int menu_pos=_menu_find_loaded_menu_caption(menu_handle,"View variable as",submenu_handle);
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
   _str variable_name = '';
   int cur_index=_TreeCurIndex();
   while (cur_index > 0) {
      _str caption=_TreeGetCaption(cur_index);
      parse caption with caption "\t" . ;

      if (substr(caption,1,1) != '[') {
         variable_name = strip(caption) :+ variable_name;
         break;
      }

      variable_name = variable_name :+ '[]';
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
   int cur_index=_TreeCurIndex();
   if (cur_index <= 0) {
      return '';
   }
   _str variable_expr = '';
   _str variable_value = '';
   _str caption=_TreeGetCaption(cur_index);
   if (caption==DEBUG_ADD_WATCH_CAPTION) {
      return '';
   }
   parse caption with caption "\t" variable_value ;
   if (caption == "Warning" && substr(variable_value,1,2)=="**") {
      return '';
   }
   variable_expr = caption;
   // now walk up the tree
   int parent_index=_TreeGetParentIndex(cur_index);
   while (parent_index) {
      caption=_TreeGetCaption(parent_index);
      parse caption with caption "\t" variable_value ;
      if (substr(variable_expr,1,1)=='[') {
         variable_expr=strip(caption):+variable_expr;
      } else if (substr(variable_value,1,2)=='0x') {
         variable_expr=caption:+'->':+variable_expr;
      } else {
         variable_expr=caption:+'.':+variable_expr;
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
   class_name = '';
   field_name = '';
   int cur_index=_TreeCurIndex();
   if (cur_index <= 0) {
      return DEBUG_INVALID_INDEX_RC;
   }

   // get the path to the root of this tree
   _str path = debug_get_variable_path(cur_index);
   if (path == '') {
      return DEBUG_INVALID_ID_RC;
   }

   // now get the vital info
   int thread_id = dbg_get_cur_thread();
   int frame_id  = dbg_get_cur_frame(thread_id);
   _str signature='';
   _str value='';
   _str dummy='';
   _str raw_value='';
   int flags=0;
   int line_number=0;
   int is_in_scope=0;
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
_command void debug_goto_variable() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   // we better be in a tree control when this happens
   if (p_object != OI_TREE_VIEW) {
      return;
   }

   // nothing selected?
   int index=_TreeCurIndex();
   if (index <= 0) {
      return;
   }

   // get the caption, and name of variable
   _str caption=debug_get_variable_expr();
   if (caption=='') {
      debug_message("Error: no variable selected");
      return;
   }

   // now go there, if possible
   debug_show_next_statement(true,0,0,'','',0,0);
   _mdi.p_child.down();
   _mdi.p_child.find_tag("-c "caption);
}

/**
 * Attempt to add a watch on the selected local, member,
 * or auto watch variable.
 * 
 * @categories Debugger_Commands
 */
_command void debug_watch_variable() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   // we better be in a tree control when this happens
   if (p_object != OI_TREE_VIEW) {
      return;
   }

   // nothing selected?
   int index=_TreeCurIndex();
   if (index <= 0) {
      return;
   }

   // get the caption, and name of variable
   _str caption=debug_get_variable_expr();
   if (caption=='') {
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
_command void debug_add_watchpoint_on_variable() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   // we better be in a tree control when this happens
   if (p_object != OI_TREE_VIEW) {
      return;
   }

   // nothing selected?
   int index=_TreeCurIndex();
   if (index <= 0) {
      return;
   }

   // get the class and field name for the watch variable
   _str class_name='';
   _str field_name='';
   debug_get_variable_class_and_name(class_name, field_name);

   // get the caption, and name of variable
   _str caption=debug_get_variable_expr();
   if (caption=='') {
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
_command void debug_show_memory() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   // we better be in a tree control when this happens
   if (p_object != OI_TREE_VIEW) {
      return;
   }

   // nothing selected?
   int index=_TreeCurIndex();
   if (index <= 0) {
      return;
   }

   // make sure the memory toolbar is up
   if (!debug_gui_memory_wid()) {
      int orig_wid=p_window_id;
      activate_memory();
      p_window_id=orig_wid;
   }

   // get the caption, and name of variable
   _str caption=debug_get_variable_expr();
   if (caption=='') {
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
      list_wid.p_text='';
   }
}
void ctl_stack_combo.on_drop_down(int reason)
{
   // set caption and bitmaps for current context
   if (reason==DROP_DOWN) {
      int thread_id=dbg_get_cur_thread();
      debug_pkg_update_stack(thread_id);
      _lbclear();
      dbg_update_stack_list(p_window_id,dbg_get_cur_thread());
   } else if (reason==DROP_UP_SELECTED) {
      int thread_id=dbg_get_cur_thread();
      int frame_id=p_line;
      debug_gui_switch_frame(thread_id,frame_id);
   }
}
void ctl_stack_combo.on_change(int reason, int index=0)
{
   if (!debug_active()) return;
   if (!debug_is_suspended()) return;
   if (gInUpdateThreadList || gInUpdateThread || gInUpdateFrame) return;
   if (reason == CHANGE_CLINE || reason==CHANGE_CLINE_NOTVIS) {
      gInUpdateFrame=true;
      if (index >= 0) p_line=index;
      if (p_line != index) p_text=p_text;
      gInUpdateFrame=false;
      int thread_id=dbg_get_cur_thread();
      int frame_id=p_line;
      if (thread_id > 0 && thread_id <= dbg_get_num_threads() &&
          frame_id  > 0 && frame_id  <= dbg_get_num_frames(thread_id)) {
         debug_gui_switch_frame(thread_id,frame_id);
         _tbSetRefreshBy(VSTBREFRESHBY_DEBUGGING);
         _tbOnUpdate(true);
         debug_show_next_statement(false,0,0,'','',thread_id,frame_id);
      }
   } else if (reason == CHANGE_OTHER) {
   } else if (reason == CHANGE_SELECTED) {
   }
}
void ctl_stack_combo.on_got_focus()
{
   if (gInUpdateThread) return;
   gInUpdateThread = true;
   _str orig_text=p_text;
   _lbclear();
   int thread_id=dbg_get_cur_thread();
   dbg_update_stack_list(p_window_id,thread_id);
   p_text=orig_text;
   gInUpdateThread = false;
}


///////////////////////////////////////////////////////////////////////////
// Handlers for debugger members toolbar
//
#define VSDEBUG_MEMBERS_FORM "_tbdebug_members_form"
defeventtab _tbdebug_members_form;
void _tbdebug_members_form.'C-A'-'C-Z',F2-F4,f6-F12,C_F12,'c-a-a'-'c-a-z','a-0'-'a-9'()
{
   _smart_toolbar_hotkey();
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

   int editable_flag = (isDynamicDebugger() || debug_session_is_implemented("modify_member")==0)? 0:TREE_EDIT_TEXTBOX;
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
   ctl_members_tree._TreeSetColButtonInfo(1,col1Width,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_WRAP|TREE_BUTTON_AUTOSIZE,0,"Value");
   ctl_members_tree._TreeSetColEditStyle(1,editable_flag);
   if (displayType) {
      ctl_members_tree._TreeSetColButtonInfo(2,col2Width,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_WRAP|TREE_BUTTON_AUTOSIZE,0,"Type");
   }

   ctl_members_tree.debug_gui_restore_tree_columns();
   ctl_members_tree.p_user = 0;

   debug_pkg_enable_disable_tabs();
   debug_gui_update_suspended();
   int thread_id=dbg_get_cur_thread();
   int frame_id=dbg_get_cur_frame(thread_id);

   status := debug_pkg_update_stack(thread_id);
   if (status != DEBUG_GDB_TIMEOUT_RC) {
      status = debug_gui_update_members(thread_id,frame_id);
   }
   dbg_update_stack_list(ctl_stack_combo,thread_id);
   debug_gui_update_cur_frame(thread_id,frame_id);
}
void _tbdebug_members_form.on_destroy()
{
   ctl_members_tree.debug_gui_save_tree_columns();
}
void _tbdebug_members_form.on_resize()
{
   _nocheck _control ctl_members_tree;
   _nocheck _control ctl_stack_combo;
   debug_gui_resize_toolbar(0,ctl_members_tree,0,ctl_stack_combo);
}
void _tbdebug_members_form.on_change(int reason)
{ 
   _nocheck _control ctl_members_tree;
   if( ctl_members_tree.p_user && reason==CHANGE_AUTO_SHOW ) {
      int thread_id = dbg_get_cur_thread();
      int frame_id=dbg_get_cur_frame(thread_id);
      debug_gui_update_members(thread_id,frame_id,true);
   }
}
void _tbdebug_members_form.on_got_focus()
{ 
   _nocheck _control ctl_members_tree;
   if ( ctl_members_tree.p_user ) {
      int thread_id = dbg_get_cur_thread();
      int frame_id=dbg_get_cur_frame(thread_id);
      debug_gui_update_members(thread_id,frame_id);
   }
}
int ctl_members_tree.on_change(int reason,int index)
{
   if (reason==CHANGE_SELECTED) {
   } else if (reason==CHANGE_EXPANDED) {
      if (debug_expand_var_requires_suspend(index) < 0) return 0;
      int thread_id=dbg_get_cur_thread();
      int frame_id=dbg_get_cur_frame(thread_id);
      _str member_path=debug_get_variable_path(index);
      int status=debug_pkg_expand_member(thread_id,frame_id,member_path);
      if (status) {
         return(0);
      }
      _TreeBeginUpdate(index);
      status=dbg_update_members_tree(p_window_id,index,thread_id,frame_id,member_path);
      _TreeEndUpdate(index);
      if (status) {
         return(0);
      }
   } else if (reason==CHANGE_COLLAPSED) {
      int thread_id=dbg_get_cur_thread();
      int frame_id=dbg_get_cur_frame(thread_id);
      _str member_path=debug_get_variable_path(index);
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

            _str sig='', value='', oldValue='', name = '', class_name = '';
            int flags=0, line_number=0, is_in_scope=0;
            dbg_get_member(thread_id, frame_id, path, name, class_name, sig, flags, value, oldValue);

            varName := _TreeGetTextForCol(index, 0);
            newValue := '';
            if (!show_modify_variable_dlg(session_id, thread_id, frame_id, oldValue, varName, newValue)) {
               debug_gui_modify_member(index, thread_id, frame_id, path, newValue);
            }
         }
      }

   } else if (reason == CHANGE_EDIT_OPEN) {
      // now get the vital info
      int thread_id = dbg_get_cur_thread();
      int frame_id  = dbg_get_cur_frame(thread_id);
      _str member_path=debug_get_variable_path(index);
      _str sig='', name = '', class_name = '', value='', raw_value='';
      int flags=0;

      dbg_get_member(thread_id, frame_id, member_path, name, class_name, sig, flags, value, raw_value);
      arg(4) = raw_value;

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
      if (arg(4)=='') {
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
   // we don't want to bother with this
   if (newValue=='') return(DELETED_ELEMENT_RC);

   status := debug_pkg_modify_member(thread_id,frame_id,path,newValue);

   // uh-oh, something is bad
   if (status) {
      debug_message("Could not modify member",status);
      return(-1);
   }

   int parent_index=_TreeGetParentIndex(index);
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
   int index=find_index("_debug_variables_menu",oi2type(OI_MENU));
   if (!index) {
      return;
   }
   int menu_handle=p_active_form._menu_load(index,'P');
   CTL_TREE tree_wid=p_window_id;

   int cur_index=tree_wid._TreeCurIndex();
   if (cur_index <= 0) {
      return;
   }

   int thread_id=dbg_get_cur_thread();
   int frame_id=dbg_get_cur_frame(thread_id);
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
   int x=mou_last_x('M')-100;
   int y=mou_last_y('M')-100;
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
      list_wid.p_text='';
   }
}


///////////////////////////////////////////////////////////////////////////
// Handlers for debugger watches toolbar
//
#define VSDEBUG_WATCHES_FORM "_tbdebug_watches_form"
defeventtab _tbdebug_watches_form;
void _tbdebug_watches_form.'C-A'-'C-Z',F2-F4,f6-F12,C_F12,'c-a-a'-'c-a-z','a-0'-'a-9'()
{
   _smart_toolbar_hotkey();
}
void _tbdebug_watches_form.'C-W',A_LEFT,A_RIGHT,A_UP()
{
   if (!_no_child_windows()) {
      p_window_id=_mdi.p_child;
      _set_focus();
   }
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

   int i;
   int editable_flag = (isDynamicDebugger() || debug_session_is_implemented("modify_watch")==0)? 0:TREE_EDIT_TEXTBOX;
   for (i=1; i<=4; ++i) {
      int tree_wid = _find_control("ctl_watches_tree":+i);
      if (tree_wid) {
         tree_wid._TreeSetColButtonInfo(0,col0Width,TREE_BUTTON_PUSHBUTTON,0,"Name");
         tree_wid._TreeSetColEditStyle(0,TREE_EDIT_TEXTBOX);
         tree_wid._TreeSetColButtonInfo(1,col1Width,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_WRAP,0,"Value");
         tree_wid._TreeSetColEditStyle(1,editable_flag);
         tree_wid._TreeSetColButtonInfo(2,col2Width,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_AUTOSIZE,0,"Frame");
         if (displayType) {
            tree_wid._TreeSetColButtonInfo(3,col3Width,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_WRAP|TREE_BUTTON_AUTOSIZE,0,"Type");
         }
      }
   }

   ctl_watches_tree1.debug_gui_restore_tree_columns();
   ctl_watches_tree2.debug_gui_restore_tree_columns();
   ctl_watches_tree3.debug_gui_restore_tree_columns();
   ctl_watches_tree4.debug_gui_restore_tree_columns();
   ctl_sstab._retrieve_value();
   ctl_watches_tree1.p_user=0;
   ctl_watches_tree2.p_user=0;
   ctl_watches_tree3.p_user=0;
   ctl_watches_tree4.p_user=0;

   debug_pkg_enable_disable_tabs();
   debug_gui_update_suspended();
   int tree_wid = _find_control("ctl_watches_tree":+ctl_sstab.p_ActiveTab+1);
   if (tree_wid) {
      int thread_id=dbg_get_cur_thread();
      int frame_id=dbg_get_cur_frame(thread_id);
      debug_gui_update_watches(thread_id,frame_id,ctl_sstab.p_ActiveTab+1);
   }
}
void _tbdebug_watches_form.on_destroy()
{
   ctl_watches_tree1.debug_gui_save_tree_columns();
   ctl_watches_tree2.debug_gui_save_tree_columns();
   ctl_watches_tree3.debug_gui_save_tree_columns();
   ctl_watches_tree4.debug_gui_save_tree_columns();
}
void _tbdebug_watches_form.on_resize()
{
   int i;
   for (i=1; i<=4; ++i) {
      int tree_wid = _find_control("ctl_watches_tree":+i);
      if (tree_wid) {
         debug_gui_resize_toolbar(ctl_sstab,tree_wid);
      }
   }
}
void _tbdebug_watches_form.on_change(int reason)
{ 
   _nocheck _control ctl_sstab;
   CTL_TREE tree_wid=debug_gui_watches_tree();
   if( tree_wid && tree_wid.p_user && reason==CHANGE_AUTO_SHOW ) {
      int thread_id = dbg_get_cur_thread();
      int frame_id=dbg_get_cur_frame(thread_id);
      dbg_clear_watch_variables();
      debug_gui_update_watches(thread_id,frame_id,ctl_sstab.p_ActiveTab+1,false,true);
   }
}
void _tbdebug_watches_form.on_got_focus()
{ 
   _nocheck _control ctl_sstab;
   CTL_TREE tree_wid=debug_gui_watches_tree();
   if ( tree_wid && tree_wid.p_user ) {
      int thread_id = dbg_get_cur_thread();
      int frame_id=dbg_get_cur_frame(thread_id);
      debug_gui_update_watches(thread_id,frame_id,ctl_sstab.p_ActiveTab+1);
   }
}
void ctl_sstab.on_change(int reason)
{
   if (reason==CHANGE_TABDEACTIVATED) {
      int tree_wid = _find_control("ctl_watches_tree":+p_ActiveTab+1);
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
      int tree_wid = _find_control("ctl_watches_tree":+p_ActiveTab+1);
      if (tree_wid) {
         int thread_id=dbg_get_cur_thread();
         int frame_id=dbg_get_cur_frame(thread_id);
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

void ctl_sstab.on_destroy()
{
   debug_gui_save_settings();
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
   CTL_FORM wid=debug_gui_watches_wid();
   return (wid? wid.ctl_sstab.p_ActiveTab+1:1);
}
static CTL_TREE debug_gui_watches_tree()
{
   CTL_FORM wid=debug_gui_watches_wid();
   if (wid) {
      return wid._find_control("ctl_watches_tree":+wid.ctl_sstab.p_ActiveTab+1);
   }
   return(0);
}
void debug_gui_clear_watches()
{
   CTL_FORM form_wid=debug_gui_watches_wid();
   if (form_wid) {
      int i;
      for (i=1; i<=4; ++i) {
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
      int thread_id=dbg_get_cur_thread();
      int frame_id=dbg_get_cur_frame(thread_id);
      _str watch_path=debug_get_variable_path(index);
      int tab_number=debug_gui_active_watches_tab();
      int status=debug_pkg_expand_watch(thread_id,frame_id,watch_path);
      if (status) {
         return(status);
      }
      _TreeBeginUpdate(index);
      status=dbg_update_watches_tree(p_window_id,index,thread_id,frame_id,tab_number,watch_path);
      _TreeEndUpdate(index);
      if (status) {
         return(status);
      }
   } else if (reason==CHANGE_COLLAPSED) {
      int thread_id=dbg_get_cur_thread();
      int frame_id=dbg_get_cur_frame(thread_id);
      _str watch_path=debug_get_variable_path(index);
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

            _str sig='', value='', oldValue='', name = '', class_name = '';
            int flags=0, line_number=0, is_in_scope=0;
            dbg_get_watch_info(thread_id,frame_id,path,name,class_name,sig,value,flags,oldValue);

            varName := _TreeGetTextForCol(index, 0);
            newValue := '';

            if (!show_modify_variable_dlg(session_id, thread_id, frame_id, oldValue, varName, newValue)) {
               debug_gui_modify_watch(index, thread_id, frame_id, path, newValue);
            }
         }
      }
   } else if (reason == CHANGE_EDIT_OPEN && col==1) {

      int thread_id=dbg_get_cur_thread();
      int frame_id=dbg_get_cur_frame(thread_id);
      _str watch_path=debug_get_variable_path(index);

      _str name, class_name, signature, value, raw_value = '';
      int flags = 0;
      dbg_get_watch_info(thread_id,frame_id,watch_path,name,class_name,signature,value,flags,raw_value);
      arg(4) = raw_value;

      return 0;
   } else if (reason == CHANGE_EDIT_QUERY && col==1) {
      if( !debug_session_is_implemented("modify_watch") ) {
         return(-1);
      }
      return debug_gui_check_modifiable(index);
   } else if (reason == CHANGE_EDIT_CLOSE && col==1) {
      if (arg(4)=='') {
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
      int parent_index=_TreeGetParentIndex(index);
      if (parent_index==TREE_ROOT_INDEX) {
         return(0);
      }
      return(-1);

   } else if (reason == CHANGE_EDIT_OPEN && col==0) {
      // if this is the new entry node, clear the message
      if(strieq(arg(4), DEBUG_ADD_WATCH_CAPTION)) {
         arg(4) = '';
      }
   } else if (reason == CHANGE_EDIT_CLOSE && col==0) {
      // check the old caption to see if it is the new entry node
      boolean wasNewEntryNode = strieq(_TreeGetCaption(index), DEBUG_ADD_WATCH_CAPTION);

      // if the node changed and is now empty, delete it
      if(arg(4) == '') {
         if(wasNewEntryNode) {
            arg(4) = DEBUG_ADD_WATCH_CAPTION;
            return 0;
         } else {
            int watch_id=_TreeGetUserInfo(index);
            dbg_remove_watch(watch_id);
            _TreeDelete(index);
            return DELETED_ELEMENT_RC;
         }
      }

      // we'll need these later
      int status=0;
      int thread_id=dbg_get_cur_thread();
      int frame_id=dbg_get_cur_frame(thread_id);
      int tab_number=debug_gui_active_watches_tab();

      // make sure the last node in the tree is the new entry node
      if(wasNewEntryNode) {
         // add the watch to the system
         status=dbg_add_watch(tab_number,arg(4),'',VSDEBUG_BASE_DEFAULT);
         if (status<0) {
            debug_message("Could not add watch",status);
            return(0);
         }

         // unbold the existing node
         _TreeSetInfo(index, -1, -1, -1, 0);
         _TreeSetUserInfo(index,status);

         // replace the new entry node
         int add_index = _TreeAddItem(TREE_ROOT_INDEX,DEBUG_ADD_WATCH_CAPTION,TREE_ADD_AS_CHILD,0,0,-1,TREENODE_BOLD,-1);
      } else {
         int watch_id=_TreeGetUserInfo(index);
         int expandable=0,base=VSDEBUG_BASE_DEFAULT;
         _str expr,context_name,value, raw_value, type = '';
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
   if (newValue=='') return(DELETED_ELEMENT_RC);

   status := debug_pkg_modify_watch(thread_id,frame_id,path,newValue);

   if (status) {
      debug_message("Could not modify variable", status);
      return -1;
   }

   int parent_index=_TreeGetParentIndex(index);
   path=debug_get_variable_path(parent_index);
   int tab_number=debug_gui_active_watches_tab();
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
   int index=find_index("_debug_variables_menu",oi2type(OI_MENU));
   if (!index) {
      return;
   }
   int menu_handle=p_active_form._menu_load(index,'P');
   CTL_TREE tree_wid=p_window_id;

   int cur_index=tree_wid._TreeCurIndex();
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
      _str caption=tree_wid._TreeGetCaption(cur_index);
      parse caption with caption "\t" . ;
      if (!pos("^:v$",caption,1,'r') && substr(caption,1,1)!='[') {
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
   int x=mou_last_x('M')-100;
   int y=mou_last_y('M')-100;
   _lxy2dxy(p_scale_mode,x,y);
   _map_xy(p_window_id,0,x,y,SM_PIXEL);
   _KillToolButtonTimer();
   _menu_show(menu_handle,VPM_LEFTALIGN|VPM_RIGHTBUTTON,x,y);
   _menu_destroy(menu_handle);
}
static void debug_gui_remove_watch()
{
   // with single node selection, if there is a current index, it is selected
   int index = _TreeCurIndex();
   if(index > 0) {
      // cannot delete new entry node
      if(strieq(_TreeGetCaption(index), DEBUG_ADD_WATCH_CAPTION)) {
         return;
      }
      int user_info=_TreeGetUserInfo(index);
      if (user_info < 0) {
         return;
      }
      int status=dbg_remove_watch(user_info);
      if (status) {
         debug_message("Could not remove watch",status);
         return;
      }
      _TreeDelete(index);
      // update the watches (watch indexes may have changed)
      int thread_id=dbg_get_cur_thread();
      int frame_id=dbg_get_cur_frame(thread_id);
      int tab_number=debug_gui_active_watches_tab();
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
_command void debug_remove_watch() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   debug_gui_remove_watch();
}
/**
 * Remove all watches from this watch tab.
 * 
 * @categories Debugger_Commands
 */
_command int debug_clear_watches() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   int thread_id=dbg_get_cur_thread();
   int frame_id=dbg_get_cur_frame(thread_id);
   int tab_number=debug_gui_active_watches_tab();

   // first ask them
   if (dbg_get_num_watches() > 0) {
      int result=_message_box('Are you sure you want to clear all watches on this tab?','',MB_YESNOCANCEL);
      if (result!=IDYES) {
         return(COMMAND_CANCELLED_RC);
      }
   }

   // find the watches on active tab
   int i=1,n=dbg_get_num_watches();
   while (i <= n) {
      int watch_tab=0;
      _str de,dc,dv,rv,type = '';
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
   p_user = (p_user | (1 << p_ActiveTab));
   boolean isWatchpoint = (p_ActiveTab == 3);
   int breakpoint_type = ctl_breakpoint_tab.p_user;
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
   visited_mask := ctl_breakpoint_tab.p_user;
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
   int count=0;
   if (ctl_skips.p_text!='' && (!isinteger(ctl_skips.p_text) || (int)ctl_skips.p_text < 0)) {
      debug_message("Expecting a positive integer value!");
      ctl_skips._set_focus();
      return;
   } else if (ctl_skips.p_text!='') {
      count=(int)ctl_skips.p_text;
   } else {
      count=0;
   }

   // validate the conditional expression
   _str condition=ctl_expr.p_text;
   if (ctl_breakpoint_tab.p_ActiveTab == 3 /*address*/) {
      condition = ctl_variable.p_text;
   }

   // get the thread name
   _str thread_name = ctl_thread_combo.p_text;
   if (thread_name=='(any thread)') {
      thread_name='';
   }

   // get the class name
   // this is where we would handle class exclude patterns
   _str class_name = ctl_class.p_text;

   // extract the class and method name (dot is trouble...)
   _str method_name = ctl_function.p_text;

   // get the file name
   _str file_name = "";
   if (visited_file) {
      file_name = ctl_file.p_text;
      if (file_name != '') {
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
   int line_number=0;
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
   _str address='';
   if (visited_addr) {
      if (ctl_address.p_enabled && ctl_address.p_text != '' &&
          !pos('^0x:h$',ctl_address.p_text,1,'r')) {
         debug_message("Expecting a hexidecimal integer address!");
         ctl_address._set_focus();
         return;
      } else {
         address = ctl_address.p_text;
      }
   }

   // check the breakpoint ID
   int status=0;
   int breakpoint_id = (int) ctl_function.p_user;
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
   int breakpoint_type = ctl_breakpoint_tab.p_user;
   int breakpoint_flags = 0;
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
      if (method_name == '') {
         debug_message("You must enter a function name!");
         ctl_function._set_focus();
         return;
      }
      break;
   case VSDEBUG_BREAKPOINT_LINE:
      if (file_name == '') {
         debug_message("You must enter a file name!");
         ctl_file._set_focus();
         return;
      }
      if (line_number == '') {
         debug_message("You must enter a line number!");
         ctl_file._set_focus();
         return;
      }
      break;
   case VSDEBUG_BREAKPOINT_ADDRESS:
      if (address == '') {
         debug_message("Expecting a hexidecimal integer address!");
         ctl_address._set_focus();
         return;
      }
      break;
   case VSDEBUG_WATCHPOINT_READ:
   case VSDEBUG_WATCHPOINT_WRITE:
   case VSDEBUG_WATCHPOINT_ANY:
      if (condition == '') {
         debug_message("Expecting a variable name or expression");
         ctl_variable._set_focus();
         return;
      }
      if (ctl_variable_size.p_visible && address == '') {
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
   if (ctl_function_label.p_user) {
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
   int count=0;
   _str condition='';
   _str thread_name='';
   _str class_name='';
   _str method_name='';
   _str file_name='';
   int line_number=0;
   _str address='';
   boolean enabled=false;
   boolean isWatchpoint=false;
   int status = 0;
   int breakpoint_type = VSDEBUG_BREAKPOINT_LINE;
   int breakpoint_flags = 0;
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
      ctl_breakpoint_tab.p_user = breakpoint_type;
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
         if (address == null) address = '';

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
      int orig_tab = ctl_breakpoint_tab.p_ActiveTab;
      ctl_breakpoint_tab.p_ActiveTab = 2;
      ctl_breakpoint_tab.p_ActiveEnabled = false;
      ctl_breakpoint_tab.p_ActiveTab = orig_tab;
   }

   if (!debug_session_is_implemented("enable_watchpoint")) {
      ctl_variable_label.p_enabled = false;
      ctl_variable.p_enabled = false;
      int orig_tab = ctl_breakpoint_tab.p_ActiveTab;
      ctl_breakpoint_tab.p_ActiveTab = 3;
      ctl_breakpoint_tab.p_ActiveEnabled = false;
      ctl_breakpoint_tab.p_ActiveTab = orig_tab;
   } else {
      int session_id = dbg_get_current_session();
      if (dbg_get_callback_name(session_id) == 'windbg') {
         ctl_variable_size_label.p_visible = true;
         ctl_variable_size.p_visible = true;
      }
   }

   ctl_class.p_text=class_name;
   ctl_function.p_text=ctl_function.p_text:+method_name;

   ctl_thread_combo.p_text=thread_name;
   debug_pkg_update_threads();
   debug_pkg_update_threadgroups();
   debug_pkg_update_threadnames();
   debug_pkg_update_threadstates();
   dbg_update_thread_list(ctl_thread_combo,false);
   ctl_thread_combo._lbadd_item('(any thread)');
   if (thread_name=='') {
      ctl_thread_combo.p_text="(any thread)";
   }

   ctl_function.p_user=breakpoint_id;
   ctl_function_label.p_user=enabled;
   ctl_breakpoint_tab.p_user=(1 << ctl_breakpoint_tab.p_ActiveTab);
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
   int stop_when=0;
   int count=0;
   _str condition='';
   _str thread_name;
   _str exception_name;
   boolean enabled=false;

   // has the exception name changed?
   if (ctl_exception.p_text != ctl_ok.p_user) {
      // validate the exception name
      if (ctl_exception.p_text=='' || !pos("^[*.a-zA-Z0-9_$-]#$", ctl_exception.p_text, 1, 'r')) {
         debug_message("Expecting a valid exception identifier!");
         ctl_exception._set_focus();
         return;
      }
      // check if it is a known exception
      debug_update_exception_list();
      if (!debug_find_exception_in_list(ctl_exception.p_text)) {
         int result=_message_box("\""ctl_exception.p_text"\" is not a known exception.  Use it anyway?",'',MB_YESNOCANCEL|MB_ICONQUESTION,IDNO);
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
   if (ctl_skips.p_text!='' && (!isinteger(ctl_skips.p_text) || (int)ctl_skips.p_text < 0)) {
      debug_message("Expecting a positive integer value!");
      ctl_skips._set_focus();
      return;
   } else if (ctl_skips.p_text!='') {
      count=(int)ctl_skips.p_text;
   } else {
      count=0;
   }

   // get the thread name
   thread_name = ctl_thread_combo.p_text;
   if (thread_name=='(any thread)') {
      thread_name='';
   }

   // get the exception name
   exception_name=ctl_exception.p_text;

   // check the exception ID
   int exception_id = (int) ctl_exception.p_user;

   // disable the exception
   int status=0;
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
   int stop_when=0;
   int count=0;
   _str condition;
   _str thread_name;
   _str exception_name;
   boolean enabled=false;
   int status = dbg_get_exception(exception_id,
                                  stop_when,count,condition,
                                  exception_name,thread_name,
                                  enabled);
   if (status) {
      debug_message("Error",status);
   }

   ctl_skips.p_text=count;
   ctl_exception.p_text=exception_name;
   ctl_thread_combo.p_text=thread_name;
   debug_pkg_update_threads();
   debug_pkg_update_threadgroups();
   debug_pkg_update_threadnames();
   debug_pkg_update_threadstates();
   dbg_update_thread_list(ctl_thread_combo,false);
   ctl_thread_combo._lbadd_item('(any thread)');
   if (thread_name=='') {
      ctl_thread_combo.p_text="(any thread)";
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
 * @param depth         search depth (default 0, max 64)
 *
 * @return 1 if the class derives from 'parent_name, 0 otherwise
 */
static int debug_class_derives_from(int i, _str &parent_name,
                                    _str (&class_list)[],
                                    _str (&parent_list)[],
                                    int (&result_list)[],
                                    var tag_files,int depth=0)
{
   if (result_list[i] >= 0) {
      return result_list[i];
   }
   if (depth > 64) {
      return(0);
   }

   // this is better code
   _str normal_parents='';
   _str normal_types='';
   _str normal_files='';
   int status=tag_normalize_classes(parent_list[i],class_list[i],
                                    null,tag_files,false,true,
                                    normal_parents,normal_types,normal_files);
   if (status) {
      // here we go
      _str in_tag_files='';
      normal_parents=cb_get_normalized_inheritance(class_list[i],in_tag_files,tag_files);
   }

   // search for a parent that derives from exception
   while (normal_parents != '') {
      _str class_name='';
      parse normal_parents with class_name VS_TAGSEPARATOR_parents normal_parents;
      parse class_name with class_name '<' .;

      if (class_name==parent_name) {
         result_list[i]=1;
         return(1);
      }
      int j=ArraySearch(class_list,class_name,StringCompare);
      if (j >= 0 && debug_class_derives_from(j,parent_name,class_list,parent_list,result_list,tag_files,depth+1)) {
         result_list[i]=1;
         return(1);
      }
   }

   // class 'i' does not derive from 'parent_name'
   result_list[i]=0;
   return(0);
}

/**
 * Insert the set of Java Exceptions into the given list (current object)
 */
void dbg_jdwp_list_exceptions(_str (&exception_list)[])
{
   // parallel arrays of classes and inheritance status
   _str class_name,class_parents;
   _str class_list[];  class_list._makeempty();
   _str parent_list[]; parent_list._makeempty();
   _str sorted_list[]; sorted_list._makeempty();
   int result_list[];  result_list._makeempty();
   int class_hash:[];  class_hash._makeempty();

   // show progress form
   int gauge_form=progress_show('Finding Exception Classes',100);

   // save the original setting for the array size warning
   int orig_threshold = _default_option(VSOPTION_WARNING_ARRAY_SIZE);
   int curr_threshold = orig_threshold;

   // get all the classes from the Java tag files
   typeless tag_files=tags_filenamea("java");
   int i=0;
   _str tag_filename=next_tag_filea(tag_files,i,false,true);
   while (tag_filename!='') {
      int status=tag_find_class(class_name);
      while (!status) {
         // make sure we have room in the array
         if (sorted_list._length()+10 > curr_threshold) {
            curr_threshold = sorted_list._length()+1000;
            _default_option(VSOPTION_WARNING_ARRAY_SIZE, curr_threshold);
         }
         // have we encountered this class already?
         if (class_hash._indexin(class_name)) {
            status=tag_next_class(class_name);
            continue;
         } else {
            class_hash:[class_name]=1;
         }
         // get the class's parents, if it has any
         tag_get_inheritance(class_name,class_parents);
         if (class_parents=='' && class_name!="java/lang/Exception" && class_name!="java.lang/Exception") {
            status=tag_next_class(class_name);
            continue;
         }
         // normalize the class name and add to lists
         sorted_list[sorted_list._length()]=class_name"\t"class_parents;
         // next please
         status=tag_next_class(class_name);
      }
      tag_reset_find_class();
      tag_filename=next_tag_filea(tag_files,i,false,true);
   }
   class_hash._makeempty();

   int gauge_wid=progress_gauge(gauge_form);
   gauge_wid.p_max=sorted_list._length();
   sorted_list._sort();

   // sort the class list, parent list, and result list
   int n=sorted_list._length();
   for (i=0; i<n; ++i) {
      parse sorted_list[i] with class_name "\t" class_parents;
      class_list[class_list._length()]=class_name;
      parent_list[parent_list._length()]=class_parents;
      result_list[result_list._length()]=(class_name=="java.lang/Exception" || class_name=="java/lang/Exception")? 1:-1;
   }

   // insert each class that derives from 'Exception'
   exception_list._makeempty();
   for (i=0; i<n; ++i) {
      if (debug_class_derives_from(i,"java/lang/Exception",class_list,parent_list,result_list,tag_files) ||
          debug_class_derives_from(i,"java.lang/Exception",class_list,parent_list,result_list,tag_files)) {
         class_name=class_list[i];
         debug_translate_class_name(class_name);
         exception_list[exception_list._length()]=class_name;
      }
      progress_increment(gauge_form);
      if (progress_cancelled()) {
         break;
      }
   }

   // clean up progress form
   _default_option(VSOPTION_WARNING_ARRAY_SIZE, orig_threshold);
   progress_close(gauge_form);
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
   int orig_wid=_get_focus();
   int status=show("-modal -xy _debug_exception_message_form",msg,caption);
   if (orig_wid) {
      orig_wid._set_focus();
   }
   return(status);
}


///////////////////////////////////////////////////////////////////////////
// Handlers for debugger breakpoints tool window
//
#define VSDEBUG_BREAKPOINTS_FORM "_tbdebug_breakpoints_form"
defeventtab _tbdebug_breakpoints_form;
void _tbdebug_breakpoints_form.on_create()
{
   ctl_breakpoints_tree._TreeSetColButtonInfo(0,1500,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Name");
   ctl_breakpoints_tree._TreeSetColButtonInfo(1,1000,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Class");
   ctl_breakpoints_tree._TreeSetColButtonInfo(2,1000,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT|TREE_BUTTON_SORT_FILENAME,0,"File");
   ctl_breakpoints_tree._TreeSetColButtonInfo(3,-1,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT|TREE_BUTTON_SORT_NUMBERS,0,"Line");
   ctl_breakpoints_tree._TreeRetrieveColButtonInfo();
   ctl_breakpoints_tree._TreeAdjustLastColButtonWidth(); 

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
   ctl_disable_btn.p_y = ctl_add_btn.p_y + ctl_add_btn.p_height;
   ctl_clear_btn.p_y = ctl_disable_btn.p_y + ctl_disable_btn.p_height;
   ctl_props_btn.p_y = ctl_clear_btn.p_y + ctl_clear_btn.p_height;

   // now resize the rest of the toolbar
   debug_gui_resize_toolbar(0,ctl_breakpoints_tree,0,0);
}

void _tbdebug_breakpoints_form.on_destroy()
{
   ctl_breakpoints_tree._TreeAppendColButtonInfo();
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
static CTL_TREE debug_gui_breakpoints_tree()
{
   _nocheck _control ctl_breakpoints_tree;
   CTL_FORM wid=debug_gui_breakpoints_wid();
   return (wid? wid.ctl_breakpoints_tree:0);
}
void debug_gui_clear_breakpoints()
{
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
   // get the breakpoint ID
   int breakpoint_id = _TreeGetUserInfo(index);

   // inspect the breakpoint
   int enabled = dbg_get_breakpoint_enabled(breakpoint_id);
   if (enabled < 0) {
      return(enabled);
   }

   // enable or disable the breakpoint
   int status=0;
   int orig_wid=p_window_id;
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
   int checkState = (enabled==0)? TCB_UNCHECKED:TCB_CHECKED;
   if (enabled==1) checkState = TCB_PARTIALLYCHECKED;
   _TreeSetCheckState(index,checkState);

   // update the editor
   dbg_update_editor_breakpoints();
   return(status);
}

static int debug_gui_preview_breakpoint(int index)
{
   // get the breakpoint ID
   int breakpoint_id = _TreeGetUserInfo(index);

   // get the breakpoint's vital information
   VS_TAG_BROWSE_INFO cm;
   tag_browse_info_init(cm);
   int status = dbg_get_breakpoint_location(breakpoint_id, cm.file_name, cm.line_no);
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
_command int debug_delete_breakpoint() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY)
{
   CTL_TREE tree_wid = debug_gui_breakpoints_tree();
   if (!tree_wid) {
      return(0);
   }

   int index=tree_wid._TreeCurIndex();
   if (index>0) {
      // get the breakpoint ID
      int breakpoint_id = tree_wid._TreeGetUserInfo(index);

      // disable the breakpoint
      int status=debug_pkg_disable_breakpoint(breakpoint_id);
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
      mou_hour_glass(1);
      debug_force_update_after_step_or_continue();
      mou_hour_glass(0);
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
   int index=find_index("_debug_breakpoints_menu",oi2type(OI_MENU));
   if (!index) {
      return;
   }
   int menu_handle=p_active_form._menu_load(index,'P');
   CTL_TREE tree_wid=p_window_id;

   int cur_index=tree_wid._TreeCurIndex();
   if (cur_index <= 0 || dbg_get_num_breakpoints() <= 0) {
      _menu_set_state(menu_handle, "goto", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "delete", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "edit", MF_GRAYED, 'C');
   }

   // Show the menu.
   int x=mou_last_x('M')-100;
   int y=mou_last_y('M')-100;
   _lxy2dxy(p_scale_mode,x,y);
   _map_xy(p_window_id,0,x,y,SM_PIXEL);
   _KillToolButtonTimer();
   _menu_show(menu_handle,VPM_LEFTALIGN|VPM_RIGHTBUTTON,x,y);
   _menu_destroy(menu_handle);
}
/**
 * Edit the current breakpoint
 */
int ctl_breakpoints_tree.lbutton_double_click()
{
   int index=_TreeCurIndex();
   if (index>0) {

      // get the editor control
      int editorctl_wid = 0;
      if (!_no_child_windows() && _mdi.p_child._isdebugging_supported()) {
         editorctl_wid = _mdi.p_child;
      }

      // get the breakpoint ID
      int breakpoint_id = _TreeGetUserInfo(index);

      // display the breakpoint editor form
      int status=show("-modal -xy _debug_breakpoint_form",breakpoint_id, editorctl_wid);
      if (status < 0) {
         return(status);
      }

      // update the editor
      return debug_gui_update_breakpoints(true);
   }
   return(0);
}

/**
 * Attempt to go to the location of the selected breakpoint.
 * 
 * @categories Debugger_Commands
 */
_command void debug_goto_breakpoint() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   // we better be in a tree control when this happens
   if (p_object != OI_TREE_VIEW) {
      return;
   }

   // nothing selected?
   int index=_TreeCurIndex();
   if (index <= 0) {
      return;
   }

   // get the caption, and name of variable
   _str caption=_TreeGetCaption(index);
   _str class_name, method_name, file_name, line_no;
   parse caption with method_name "\t" class_name "\t" file_name "\t" line_no ;
   if (file_name != '') {
      if (!file_exists(file_name)) {
         file_name=absolute(file_name,_strip_filename(_project_name,'N'));
      } else {
         file_name=absolute(file_name);
      }
      // try to open the file
      int status=_mdi.p_child.edit(maybe_quote_filename(file_name),EDIT_DEFAULT_FLAGS);
      if (status) {
         // no message here, edit() will complain if it has a problem
         return;
      }

      // maybe add this file to list of read only files
      _mdi.p_child.debug_maybe_add_readonly_file(file_name);

      // go to the specified line number
      if (line_no != '' && isinteger(line_no)) {
         _mdi.p_child.goto_line((int) line_no);
      }
      return;
   }

   // no filename, try to look up the tag
   _mdi.p_child.find_tag("-c "class_name"."method_name);
}

int _OnUpdate_debug_edit_breakpoint(CMDUI &cmdui,int target_wid,_str command)
{
   if(isEclipsePlugin()) {
      return MF_ENABLED;
   }
   if (_no_child_windows()) {
      return MF_GRAYED;
   }
   if (!_mdi.p_child._isdebugging_supported()) {
      return(MF_GRAYED);
   }
   if (!_no_child_windows() && 
       _mdi.p_child._LanguageInheritsFrom('e') && 
       _get_extension(_mdi.p_child.p_buf_name)!='sh') {
      return MF_ENABLED;
   }
   //if (_project_DebugCallbackName=='' || !_project_DebugConfig) {
   //   return MF_GRAYED;
   //}
   boolean supported = debug_session_is_implemented("enable_breakpoint");
   if (!supported) {
      return MF_GRAYED;
   }

   // Are we in disassembly?
   _str address = _mdi.p_child.debug_get_disassembly_address();
   boolean enabled=false;
   int breakpoint_id=dbg_find_breakpoint(_mdi.p_child.p_buf_name,_mdi.p_child.p_RLine,enabled,0,address);
   return (breakpoint_id > 0)? MF_ENABLED:MF_GRAYED;
}
/**
 * Edit the selected breakpoint, or the breakpoint under the cursor.
 *
 * @return 0 on success, <0 on error.
 * 
 * @categories Debugger_Commands
 */
_command int debug_edit_breakpoint() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY)
{
   // get the breakpoint ID
   int breakpoint_id=0;
   int editorctl_wid=0;
   CTL_TREE tree_wid=debug_gui_breakpoints_tree();
   if (tree_wid && (p_window_id == tree_wid)) {
      int index=tree_wid._TreeCurIndex();
      if (index > 0) {
         breakpoint_id=tree_wid._TreeGetUserInfo(index);
      }
      if (!_no_child_windows() && _mdi.p_child._isdebugging_supported()) {
         editorctl_wid = _mdi.p_child;
      }
   } else if (_isEditorCtl()) {
      _str address=null;
      boolean enabled=false;
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
   int status=show("-modal -xy _debug_breakpoint_form",breakpoint_id, editorctl_wid);
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
_command int debug_add_breakpoint() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY)
{
   // get the editor control for surfing default values
   int editorctl_wid=0;
   if (_isEditorCtl()) {
      editorctl_wid = p_window_id;
   } else if (!_no_child_windows() && _mdi.p_child._isdebugging_supported()) {
      editorctl_wid = _mdi.p_child;
   }

   // display the breakpoint editor form
   int breakpoint_id=show("-modal -xy _debug_breakpoint_form",0,editorctl_wid);
   if (breakpoint_id < 0) {
      return(breakpoint_id);
   }

   // update the editor
   debug_gui_update_breakpoints(true);

   // update the debugger, in case if we hit the breakpoint right away
   if (debug_active()) {
      mou_hour_glass(1);
      debug_force_update_after_step_or_continue();
      mou_hour_glass(0);
   }

   return 0;
}

/**
 * Update the enable/disable states of the
 * buttons on the breakpoints form.
 */
static void debug_gui_breakpoints_update_buttons()
{
   CTL_FORM form_wid=debug_gui_breakpoints_wid();
   if (!form_wid) {
      return;
   }
   CTL_TREE tree_wid=debug_gui_breakpoints_tree();
   if (!tree_wid) {
      return;
   }
   boolean disable_enabled=false;
   boolean clear_enabled=false;
   boolean props_enabled=false;

   int no_of_breakpoints=tree_wid._TreeGetNumChildren(TREE_ROOT_INDEX);
   int tree_index=tree_wid._TreeCurIndex();
   if (no_of_breakpoints>0 && tree_index>0) {
      int breakpoint_id=tree_wid._TreeGetUserInfo(tree_index);
      if (breakpoint_id > 0 && breakpoint_id <= dbg_get_num_breakpoints()) {
         props_enabled=true;
      }
   }
   if (no_of_breakpoints > 0) {
      clear_enabled=true;
      disable_enabled=true;
   }

   _nocheck _control ctl_add_btn;
   int session_id = dbg_get_current_session();
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
#define VSDEBUG_EXCEPTIONS_FORM "_tbdebug_exceptions_form"
defeventtab _tbdebug_exceptions_form;
void _tbdebug_exceptions_form.on_create()
{
   ctl_exceptions_tree._TreeSetColButtonInfo(0,1800,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Exceptions to catch");
   ctl_exceptions_tree._TreeSetColButtonInfo(1,-1,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT|TREE_BUTTON_AUTOSIZE,0,"When");
   ctl_exceptions_tree._TreeRetrieveColButtonInfo();
   ctl_exceptions_tree._TreeAdjustLastColButtonWidth(); 

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
   ctlimage1.p_y = ctl_add_exception.p_y + ctl_add_exception.p_height;
   ctlimage2.p_y = ctlimage1.p_y + ctlimage1.p_height;
   ctlimage3.p_y = ctlimage2.p_y + ctlimage2.p_height;

   // now resize the rest of the toolbar
   debug_gui_resize_toolbar(0,ctl_exceptions_tree);
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
   // get the exception ID
   int exception_id = _TreeGetUserInfo(index);

   // inspect the exception
   int enabled = dbg_get_exception_enabled(exception_id);
   if (enabled < 0) {
      return(enabled);
   }

   // enable or disable the exception
   int status=0;
   int orig_wid=p_window_id;
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
   int x=mou_last_x();
   int y=mou_last_y();
   int index=_TreeGetIndexFromPoint(x,y,'PB');
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
   int index=_TreeCurIndex();
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
_command int debug_delete_exception() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY)
{
   CTL_TREE tree_wid = debug_gui_exceptions_tree();
   if (!tree_wid) {
      return(0);
   }

   int index=tree_wid._TreeCurIndex();
   if (index>0) {
      // get the exception ID
      int exception_id = tree_wid._TreeGetUserInfo(index);

      // disable the exception
      int status=debug_pkg_disable_exception(exception_id);
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
   int index=find_index("_debug_exceptions_menu",oi2type(OI_MENU));
   if (!index) {
      return;
   }
   int menu_handle=p_active_form._menu_load(index,'P');
   CTL_TREE tree_wid=p_window_id;

   int cur_index=tree_wid._TreeCurIndex();
   if (cur_index <= 0 || dbg_get_num_breakpoints() <= 0) {
      _menu_set_state(menu_handle, "goto", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "delete", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "edit", MF_GRAYED, 'C');
   }

   // Show the menu.
   int x=mou_last_x('M')-100;
   int y=mou_last_y('M')-100;
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
   int index=_TreeCurIndex();
   if (index>0) {
      // get the exception ID
      int exception_id = _TreeGetUserInfo(index);

      // display the exception editor form
      int status=show("-modal -xy _debug_exception_form",exception_id);
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
_command void debug_goto_exception() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   // we better be in a tree control when this happens
   if (p_object != OI_TREE_VIEW) {
      return;
   }

   // nothing selected?
   int index=_TreeCurIndex();
   if (index <= 0) {
      return;
   }

   // get the caption, and name of variable
   _str caption=_TreeGetCaption(index);
   parse caption with caption "\t" . ;
   _mdi.p_child.find_tag("-c "caption);
}

/**
 * Edit the selected exception, or the exception under
 * the cursor.
 *
 * @return 0 on success, <0 on error.
 * 
 * @categories Debugger_Commands
 */
_command int debug_edit_exception() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY)
{
   // get the exception ID
   int exception_id=0;
   CTL_TREE tree_wid=debug_gui_exceptions_tree();
   if (tree_wid) {
      int index=tree_wid._TreeCurIndex();
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
   int status=show("-modal -xy _debug_exception_form",exception_id);
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
   _str exception_name=p_cb_text_box.p_text;
   if (exception_name=='') {
      return(0);
   }

   // check if we already have this exception in the list
   int enabled=0;
   int index=dbg_find_exception(exception_name,enabled,0);
   if (index > 0) {
      int tree_index=ctl_exceptions_tree._TreeSearch(0,exception_name,'',index);
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
   _str exception=ctl_exception_combo.p_cb_text_box.p_text;

   // add the exception to the exception list
   int exception_id=dbg_add_exception(VSDEBUG_EXCEPTION_STOP_WHEN_CAUGHT,
                                      0, '', exception, '');
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

   p_text='';
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
         mou_hour_glass(1);
         p_cb_list_box._retrieve_list();
         debug_jdwp_list_exceptions();
         p_cb_list_box._lbsort();
         mou_hour_glass(0);
      }
   }
}
*/


///////////////////////////////////////////////////////////////////////////
// Handlers for debugger auto-variables, locals, and members toolbar
//
#define VSDEBUG_AUTOVARS_FORM "_tbdebug_autovars_form"
defeventtab _tbdebug_autovars_form;
void _tbdebug_autovars_form.'C-A'-'C-Z',F2-F4,f6-F12,C_F12,'c-a-a'-'c-a-z','a-0'-'a-9'()
{
   _smart_toolbar_hotkey();
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

   int editable_auto = (isDynamicDebugger() || debug_session_is_implemented("modify_autovar")==0)? 0:TREE_EDIT_TEXTBOX;
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
   ctl_autovars_tree._TreeSetColButtonInfo(1,col1Width,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_WRAP|TREE_BUTTON_AUTOSIZE,0,"Value");
   ctl_autovars_tree._TreeSetColEditStyle(1,TREE_EDIT_TEXTBOX);
   if (displayType) {
      ctl_autovars_tree._TreeSetColButtonInfo(2,col2Width,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_WRAP|TREE_BUTTON_AUTOSIZE,0,"Type");
   }

   ctl_autovars_tree.debug_gui_restore_tree_columns();
   ctl_autovars_tree.p_user=0;

   debug_pkg_enable_disable_tabs();
   debug_gui_update_suspended();

   int thread_id=dbg_get_cur_thread();
   int frame_id=dbg_get_cur_frame(thread_id);

   if (thread_id>0 && frame_id>0) {
      debug_gui_update_autovars(thread_id,frame_id);
   }

   dbg_update_stack_list(ctl_stack_combo1.p_window_id,thread_id);
   ctl_stack_combo1.p_text=ctl_stack_combo1._lbget_text();

   debug_gui_update_cur_frame(thread_id,frame_id);
}
void _tbdebug_autovars_form.on_destroy()
{
   ctl_autovars_tree.debug_gui_save_tree_columns();
}
void _tbdebug_autovars_form.on_resize()
{
   _nocheck _control ctl_autovars_tree;
   _nocheck _control ctl_stack_combo1;
   debug_gui_resize_toolbar(0,ctl_autovars_tree,0,ctl_stack_combo1);
}
void _tbdebug_autovars_form.on_change(int reason)
{ 
   _nocheck _control ctl_autovars_tree;
   if( ctl_autovars_tree.p_user && reason==CHANGE_AUTO_SHOW ) {
      int thread_id = dbg_get_cur_thread();
      int frame_id=dbg_get_cur_frame(thread_id);
      debug_gui_update_autovars(thread_id,frame_id,true);
   }
}
void _tbdebug_autovars_form.on_got_focus()
{ 
   _nocheck _control ctl_autovars_tree;
   if ( ctl_autovars_tree.p_user ) {
      int thread_id = dbg_get_cur_thread();
      int frame_id=dbg_get_cur_frame(thread_id);
      debug_gui_update_autovars(thread_id,frame_id);
   }
}
int ctl_autovars_tree.on_change(int reason,int index)
{
   if (reason==CHANGE_SELECTED) {
   } else if (reason==CHANGE_EXPANDED) {
      if (debug_expand_var_requires_suspend(index) < 0) return 0;
      int thread_id=dbg_get_cur_thread();
      int frame_id=dbg_get_cur_frame(thread_id);
      _str watch_path=debug_get_variable_path(index);
      int status=debug_pkg_expand_auto(thread_id,frame_id,watch_path);
      if (status) {
         return(status);
      }
      _TreeBeginUpdate(index);
      status=dbg_update_autos_tree(p_window_id,index,thread_id,frame_id,watch_path);
      _TreeEndUpdate(index);
      if (status) {
         return(status);
      }
   } else if (reason==CHANGE_COLLAPSED) {
      int thread_id=dbg_get_cur_thread();
      int frame_id=dbg_get_cur_frame(thread_id);
      _str watch_path=debug_get_variable_path(index);
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

            _str sig='', value='', oldValue='', name = '', class_name = '';
            int flags=0, line_number=0, is_in_scope=0;
            dbg_get_autovar_info(thread_id,frame_id,path,name,class_name,sig,value,flags,oldValue);

            varName := _TreeGetTextForCol(index, 0);
            newValue := '';
            if (!show_modify_variable_dlg(session_id, thread_id, frame_id, oldValue, varName, newValue)) {
               debug_gui_modify_autovar(index, thread_id, frame_id, path, newValue);
            }
         }
      }
   } else if (reason == CHANGE_EDIT_OPEN) {
      // get the "raw" value of the variable, set it to arg(4), so we use that in the text box
      int thread_id = dbg_get_cur_thread();
      int frame_id  = dbg_get_cur_frame(thread_id);
      _str path=debug_get_variable_path(index);
      _str field_name = '', class_name = '', signature = '', value='', raw_value='';
      int flags = 0;
      dbg_get_autovar_info(thread_id,frame_id,path,field_name,class_name,signature,value,flags,raw_value);

      arg(4) = raw_value;
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
      if (arg(4)=='') {
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
   if (newValue == '') return(DELETED_ELEMENT_RC);

   status := debug_pkg_modify_autovar(thread_id,frame_id,path,newValue);
   
   if (status) {
      debug_message("Could not modify variable",status);
      return -1;
   }

   // either way, it's a good idea to refresh the tree
   int parent_index=_TreeGetParentIndex(index);
   path=debug_get_variable_path(parent_index);
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
   int index=find_index("_debug_variables_menu",oi2type(OI_MENU));
   if (!index) {
      return;
   }
   int menu_handle=p_active_form._menu_load(index,'P');
   CTL_TREE tree_wid=p_window_id;

   int thread_id=dbg_get_cur_thread();
   int frame_id=dbg_get_cur_frame(thread_id);
   int cur_index=tree_wid._TreeCurIndex();
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
   int x=mou_last_x('M')-100;
   int y=mou_last_y('M')-100;
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
      list_wid.p_text='';
   }
}

/**
 * Set the number of lines to scan for auto-watches
 * 
 * @categories Debugger_Commands
 */
_command void debug_set_auto_lines(_str num_lines=3) name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   if (!isinteger(num_lines)) {
      debug_message("Expecting a positive integer value!",0,true);
      return;
   }
   // Set the def-vars to what they specified
   if(def_debug_auto_lines != num_lines) {
      def_debug_auto_lines = (int) num_lines;
      _config_modify_flags(CFGMODIFY_DEFVAR);
      if (debug_is_suspended()) {
         int thread_id=dbg_get_cur_thread();
         int frame_id=dbg_get_cur_frame(thread_id);
         dbg_clear_autos(thread_id,frame_id);
         debug_gui_update_autovars(thread_id,frame_id);
      }
   }
}

///////////////////////////////////////////////////////////////////////////
// Handlers debugger classes display toolbar
//
#define VSDEBUG_CLASSES_FORM "_tbdebug_classes_form"
defeventtab _tbdebug_classes_form;
void ctl_system.lbutton_up()
{
   debug_gui_update_classes(true);
}
void _tbdebug_classes_form.'C-A'-'C-Z',F2-F4,f6-F12,C_F12,'c-a-a'-'c-a-z','a-0'-'a-9'()
{
   _smart_toolbar_hotkey();
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
   dbg_invalidate_views();

   int editable_flag=(debug_session_is_implemented("modify_field")==0)? 0:TREE_EDIT_TEXTBOX;
   ctl_classes_tree._TreeSetColButtonInfo(0,1500,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Name");
   ctl_classes_tree._TreeSetColButtonInfo(1,-1,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Scope/Value");
   ctl_classes_tree._TreeSetColEditStyle(1,editable_flag);
   ctl_classes_tree._TreeRetrieveColButtonInfo();
   ctl_classes_tree._TreeAdjustLastColButtonWidth(); 
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
}

void _tbdebug_classes_form.on_change(int reason)
{ 
   _nocheck _control ctl_classes_tree;
   if( ctl_classes_tree.p_user && reason==CHANGE_AUTO_SHOW ) {
      int thread_id = dbg_get_cur_thread();
      int frame_id=dbg_get_cur_frame(thread_id);
      debug_gui_update_classes(true);
   }
}
void _tbdebug_classes_form.on_got_focus()
{ 
   _nocheck _control ctl_classes_tree;
   if ( ctl_classes_tree.p_user ) {
      int thread_id = dbg_get_cur_thread();
      int frame_id=dbg_get_cur_frame(thread_id);
      debug_gui_update_classes();
   }
}
int ctl_classes_tree.on_change(int reason,int index)
{
   int status=0;
   if (reason==CHANGE_SELECTED) {
      // find the output tagwin and update it
      int f = _GetTagwinWID(true);
      if (f && index>0) {
         // TBF (this should really happen on a timer)
      }

   } else if (reason==CHANGE_EXPANDED) {
      if (debug_expand_var_requires_suspend(index) < 0) return 0;
      _str class_path=debug_get_variable_path(index);
      status=debug_pkg_expand_class(class_path);
      if (status) {
         return(status);
      }
      _TreeBeginUpdate(index);
      status=dbg_update_class_tree(p_window_id,index,class_path,!(p_prev.p_value));
      _TreeEndUpdate(index);
      if (status) {
         return(status);
      }
      return(index);
   } else if (reason==CHANGE_COLLAPSED) {
      _str class_path=debug_get_variable_path(index);
      //dbg_collapse_class(class_path);
      //_TreeDelete(index,'C');
      return(index);

   } else if (reason == CHANGE_EDIT_QUERY) {
      int parent_index=_TreeGetParentIndex(index);
      if (parent_index==TREE_ROOT_INDEX) {
         return(-1);
      }
      if (_TreeGetParentIndex(parent_index)==TREE_ROOT_INDEX) {
         int member_id=_TreeGetUserInfo(index);
         if (member_id >= VSDEBUG_CLASS_METHODS) {
            return(-1);
         }
      }
      return debug_gui_check_modifiable(index);

   } else if (reason == CHANGE_EDIT_OPEN) {

   } else if (reason == CHANGE_EDIT_CLOSE) {
      if (arg(4)=='') {
         return(DELETED_ELEMENT_RC);
      }
      _str field_path=debug_get_variable_path(index);
      status=debug_pkg_modify_field(field_path,arg(4));
      if (status) {
         debug_message("Could not modify field",status);
         return(-1);
      }
      int parent_index=_TreeGetParentIndex(index);
      field_path=debug_get_variable_path(parent_index);
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
      int parent_index=_TreeGetParentIndex(index);
      if (parent_index <= TREE_ROOT_INDEX) {
         int class_id=_TreeGetUserInfo(index);
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
   int index=find_index("_debug_classes_menu",oi2type(OI_MENU));
   if (!index) {
      return;
   }
   int menu_handle=p_active_form._menu_load(index,'P');
   CTL_TREE tree_wid=p_window_id;

   int cur_index=tree_wid._TreeCurIndex();
   if (cur_index <= 0) {
      _menu_set_state(menu_handle, "debug_goto_decl", MF_GRAYED, 'M');
      _menu_set_state(menu_handle, "debug_class_break", MF_GRAYED, 'M');
      _menu_set_state(menu_handle, "debug_class_watch", MF_GRAYED, 'M');
      _menu_set_state(menu_handle, "debug_class_props", MF_GRAYED, 'M');
   } else {
      int parent_index=tree_wid._TreeGetParentIndex(cur_index);
      if (parent_index > 0) {
         _menu_set_state(menu_handle, "debug_class_props", MF_GRAYED, 'M');
         int member_id=tree_wid._TreeGetUserInfo(cur_index);
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
   int x=mou_last_x('M')-100;
   int y=mou_last_y('M')-100;
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
   int wid=debug_gui_classes_wid();
   return (wid? wid.ctl_classes_tree:0);
}
void debug_gui_clear_classes()
{
   CTL_TREE tree_wid=debug_gui_classes_tree();
   if (tree_wid) {
      tree_wid._TreeDelete(TREE_ROOT_INDEX,'c');
   }
}

/**
 * Go to the definition of the selected item
 * 
 * @categories Debugger_Commands
 */
_command void debug_goto_decl() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   //debug_message("Goto definition is not implemented yet.");
   //return;

   int status,flags=0;
   _str name='',class_name='',signature='',return_type='',file_name='',type_name='',value='';

   CTL_TREE tree_wid=debug_gui_classes_tree();
   if (tree_wid) {
      int cur_index=tree_wid._TreeCurIndex();
      if (cur_index > 0) {
         int parent_index=tree_wid._TreeGetParentIndex(cur_index);
         if (parent_index > 0) {
            // method or field selected
            int class_id=tree_wid._TreeGetUserInfo(parent_index);
            int member_id=tree_wid._TreeGetUserInfo(cur_index);
            status=dbg_get_method(class_id,member_id,name,class_name,signature,return_type,file_name,flags);
            if (status) {
               status=dbg_get_field(class_id,member_id,name,signature,value,flags);
            }
            // class selected
            if (!status) {
               _str outer_class='';
               _str class_file_name='';
               typeless ds,df,dl;
               status = dbg_get_class(class_id,class_name,outer_class,ds,class_file_name,df,dl);
               if (!status && outer_class!='') {
                  class_name=outer_class:+VS_TAGSEPARATOR_package:+class_name;
                  if (file_name=='') file_name = class_file_name;
               }
            }
            // is this the constructor for an anonymous class?
            if (isinteger(name)) {
               name='@'name;
               if (pos(':v\.:i',class_name,1,'r')) {
                  class_name=substr(class_name,1,pos('S')-2);
               }
            }
         } else {
            // class selected
            int class_id=tree_wid._TreeGetUserInfo(cur_index);
            _str loader='';
            status = debug_pkg_expand_class(class_id);
            status = dbg_get_class(class_id,name,class_name,signature,file_name,flags,loader);
            int p=lastpos(VS_TAGSEPARATOR_class,name);
            if (p) {
               class_name=class_name:+VS_TAGSEPARATOR_package:+substr(name,1,p-1);
               name=substr(name,p+1);
            }
            // is this an anonymous class?
            if (pos('\.:i',name,1,'r')) {
               name='@'substr(name,pos('S')+1);
            } else if (isinteger(name)) {
               name='@'name;
            }
         }
         // got a class name, need to fine tune it a bit
         if (class_name != '') {
            // is this an anonymous class?
            if (pos(':v[./:$]{:i}',class_name,1,'r')) {
               class_name=substr(class_name,1,pos('S')-2) :+ ':@' :+
                          substr(class_name,pos('S0'),pos('0')) :+
                          substr(class_name,pos('S')+pos(''));
            }
         }
         if (status < 0) {
            debug_message("Error",status);
            return;
         }
         if (file_name=='') {
            debug_message("Source code not found");
            return;
         }
         if (_get_extension(file_name)=='e') {
            debug_resolve_slickc_class(class_name);
         }
         // attempt to resolve full path to source, do not complain
         // if path not found, becuase they have already been prompted
         _str full_path=debug_resolve_or_prompt_for_path(file_name,class_name,name);
         if (full_path!='') {
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
_command void debug_class_break() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   CTL_TREE tree_wid=debug_gui_classes_tree();
   if (tree_wid) {
      int cur_index=tree_wid._TreeCurIndex();
      if (cur_index > 0) {
         int parent_index=tree_wid._TreeGetParentIndex(cur_index);
         if (parent_index > 0) {
            int class_id=tree_wid._TreeGetUserInfo(parent_index);
            int method_id=tree_wid._TreeGetUserInfo(cur_index);
            _str method_name='',class_name='',signature='',return_type='',file_name='';
            int flags=0;
            int status=dbg_get_method(class_id,method_id,method_name,class_name,signature,return_type,file_name,flags);
            if (!status) {
               // class selected
               typeless dn,ds,df,dl;
               dbg_get_class(class_id,dn,class_name,ds,file_name,df,dl);
               // got a class name, need to fine tune it a bit
               if (pos('^:v[./:$]{:i}$',dn,1,'r')) {
                  // an anonymous class?
                  dn=substr(dn,pos('S0'),pos('0'));
               }
               class_name=(class_name!='')? class_name:+'.':+dn : dn;
               // add the breakpoint to the breakpoint list
               int breakpoint_id=dbg_add_breakpoint(0,'','',class_name,method_name,
                                                    '',0,null,VSDEBUG_BREAKPOINT_METHOD,0);
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
                  mou_hour_glass(1);
                  debug_force_update_after_step_or_continue();
                  mou_hour_glass(0);
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
_command void debug_class_exception() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   CTL_TREE tree_wid=debug_gui_classes_tree();
   if (tree_wid) {
      int cur_index=tree_wid._TreeCurIndex();
      if (cur_index > 0) {
         int parent_index=tree_wid._TreeGetParentIndex(cur_index);
         if (parent_index <= 0) {
            typeless dn,ds,df,dl;
            int class_id=tree_wid._TreeGetUserInfo(cur_index);
            _str class_name='',file_name='';
            int status=dbg_get_class(class_id,dn,class_name,ds,file_name,df,dl);
            if (!status) {
               // add the exception breakpoint to the exception list
               int exception_id=dbg_add_exception(VSDEBUG_EXCEPTION_STOP_WHEN_CAUGHT, 0, '',class_name,'');
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
_command void debug_class_watch() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   CTL_TREE tree_wid=debug_gui_classes_tree();
   if (tree_wid) {
      int cur_index=tree_wid._TreeCurIndex();
      if (cur_index > 0) {
         int parent_index=tree_wid._TreeGetParentIndex(cur_index);
         if (parent_index > 0) {
            int root_index=tree_wid._TreeGetParentIndex(parent_index);
            // nested field, this is tricky stuff
            _str member_caption='';
            while (root_index > 0) {
               _str caption=tree_wid._TreeGetCaption(cur_index);
               parse caption with caption "\t" .;
               if (member_caption=='') {
                  member_caption=strip(caption);
               } else {
                  member_caption=strip(caption):+member_caption;
               }
               if (substr(member_caption,1,1)!='[') {
                  member_caption='.':+member_caption;
               }
               cur_index=_TreeGetParentIndex(cur_index);
               parent_index=_TreeGetParentIndex(cur_index);
               root_index=_TreeGetParentIndex(parent_index);
            }
            int class_id=tree_wid._TreeGetUserInfo(parent_index);
            int field_id=tree_wid._TreeGetUserInfo(cur_index);
            _str field_name='',class_name='',signature='',return_type='',file_name='';
            _str inner_name='',outer_name='',value='';
            typeless df,dl;
            int status,flags=0;
            status=dbg_get_class(class_id,inner_name,outer_name,signature,file_name,df,dl);
            // got a class name, need to fine tune it a bit
            if (pos('^:v[./:$]{:i}$',inner_name,1,'r')) {
               // an anonymous class?
               inner_name=substr(inner_name,pos('S0'),pos('0'));
            }
            class_name=(outer_name!='')? outer_name'.'inner_name:inner_name;
            status=dbg_get_field(class_id,field_id,field_name,signature,value,flags);
            if (!status) {
               // activate the watches if they are not already activated
               if (!debug_gui_watches_wid()) {
                  activate_watch();
               }
               // add the watch to the watches list
               int tab_number=debug_gui_active_watches_tab();
               int watch_id=dbg_add_watch(tab_number,class_name'.'field_name:+member_caption,'',VSDEBUG_BASE_DEFAULT);
               if (watch_id < 0) {
                  debug_message("Error adding watch",watch_id);
                  return;
               }
               // update the views
               int thread_id=dbg_get_cur_thread();
               int frame_id=dbg_get_cur_frame(thread_id);
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
_command void debug_class_watchpoint() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   CTL_TREE tree_wid=debug_gui_classes_tree();
   if (tree_wid) {
      int cur_index=tree_wid._TreeCurIndex();
      if (cur_index > 0) {
         int parent_index=tree_wid._TreeGetParentIndex(cur_index);
         if (parent_index > 0) {
            int root_index=tree_wid._TreeGetParentIndex(parent_index);
            // nested field, this is tricky stuff
            _str member_caption='';
            while (root_index > 0) {
               _str caption=tree_wid._TreeGetCaption(cur_index);
               parse caption with caption "\t" .;
               if (member_caption=='') {
                  member_caption=strip(caption);
               } else {
                  member_caption=strip(caption):+member_caption;
               }
               if (substr(member_caption,1,1)!='[') {
                  member_caption='.':+member_caption;
               }
               cur_index=_TreeGetParentIndex(cur_index);
               parent_index=_TreeGetParentIndex(cur_index);
               root_index=_TreeGetParentIndex(parent_index);
            }
            int class_id=tree_wid._TreeGetUserInfo(parent_index);
            int field_id=tree_wid._TreeGetUserInfo(cur_index);
            _str field_name='',class_name='',signature='',return_type='',file_name='';
            _str inner_name='',outer_name='',value='';
            typeless df,dl;
            int status,flags=0;
            status=dbg_get_class(class_id,inner_name,outer_name,signature,file_name,df,dl);
            // got a class name, need to fine tune it a bit
            if (pos('^:v[./:$]{:i}$',inner_name,1,'r')) {
               // an anonymous class?
               inner_name=substr(inner_name,pos('S0'),pos('0'));
            }
            class_name=(outer_name!='')? outer_name'.'inner_name:inner_name;
            status=dbg_get_field(class_id,field_id,field_name,signature,value,flags);
            if (!status) {
               // activate the breakpoints if they are not already activated
               if (!debug_gui_breakpoints_wid()) {
                  activate_breakpoints();
               }
               // add the watch to the watches list
               int breakpoint_id = dbg_add_breakpoint(0, field_name, "",
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
                  mou_hour_glass(1);
                  debug_force_update_after_step_or_continue();
                  mou_hour_glass(0);
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
_command void debug_class_props() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   CTL_TREE tree_wid=debug_gui_classes_tree();
   if (tree_wid) {
      int cur_index=tree_wid._TreeCurIndex();
      if (cur_index > 0) {
         int parent_index=tree_wid._TreeGetParentIndex(cur_index);
         if (parent_index <= TREE_ROOT_INDEX) {
            int class_id=tree_wid._TreeGetUserInfo(cur_index);
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
_command void debug_class_collapse() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   CTL_TREE tree_wid=debug_gui_classes_tree();
   if (tree_wid) {
      int index=tree_wid._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      while (index > 0) {
         int show_children=0;
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
static void debug_goto_field(boolean is_local)
{
   int cur_index=_TreeCurIndex();
   if (cur_index <= 0) {
      debug_message("No field selected");
   }

   int thread_id=dbg_get_cur_thread();
   int frame_id=dbg_get_cur_frame(thread_id);
   _str field_path = debug_get_variable_path(cur_index);

   int status,flags=0;
   _str name='',class_name='',signature='';
   _str file_name='',type_name='',method_name='',value='';
   int line_number=0,is_in_scope=0;

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
   _str full_path='';
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
         full_path=full_path:+FILESEP;
      }
      full_path=full_path:+file_name;
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
   // normalize the class name
   debug_translate_class_name(cm.class_name);

   // determine what kind of breakpoint to create
   _str condition="";
   int breakpoint_type = VSDEBUG_BREAKPOINT_METHOD;
   if (tag_tree_type_is_statement(cm.type_name)) {
      breakpoint_type = VSDEBUG_BREAKPOINT_LINE;
   } else if (tag_tree_type_is_func(cm.type_name)) {
      breakpoint_type = VSDEBUG_BREAKPOINT_METHOD;
   } else if (tag_tree_type_is_data(cm.type_name)) {
      breakpoint_type = def_debug_watchpoint_type;
      condition = cm.class_name':'cm.member_name;
      debug_translate_class_name(condition);
   } else {
      _message_box("Can not set breakpoint on this item");
      return -1;
   }

   // activate the breakpoints tab
   activate_breakpoints();

   // add the breakpoint to the breakpoint list
   int breakpoint_id = 0;
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
   int status=0;
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
      mou_hour_glass(1);
      debug_force_update_after_step_or_continue();
      mou_hour_glass(0);
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

   _str name='',outer_class='',signature='',file_name='',loader='';
   int flags=0;
   int status=dbg_get_class(class_id,name,outer_class,signature,file_name,flags,loader);
   if (status) {
      ctl_error.p_value=1;
      ctl_name._begin_line();
      ctl_name.p_text=get_message(status);
      ctl_close_btn._set_focus();
      return;
   }
   if (loader=='') {
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

   int i=1;
   _str class_name='';
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
#define VSDEBUG_REGISTERS_FORM "_tbdebug_regs_form"
defeventtab _tbdebug_regs_form;
void _tbdebug_regs_form.'C-A'-'C-Z',F2-F4,f6-F12,C_F12,'c-a-a'-'c-a-z','a-0'-'a-9'()
{
   _smart_toolbar_hotkey();
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

   int editable_flag=(debug_session_is_implemented("modify_register")==0)? 0:TREE_EDIT_TEXTBOX;
   ctl_registers_tree._TreeSetColButtonInfo(0,1500,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Name");
   ctl_registers_tree._TreeSetColButtonInfo(1,-1,TREE_BUTTON_PUSHBUTTON,0,"Value");
   ctl_registers_tree._TreeSetColEditStyle(1,editable_flag);
   ctl_registers_tree._TreeRetrieveColButtonInfo();
   ctl_registers_tree._TreeAdjustLastColButtonWidth(); 
   ctl_registers_tree.p_user=0;

   debug_pkg_enable_disable_tabs();
   debug_gui_update_registers(true);
}
void _tbdebug_regs_form.on_destroy()
{
   ctl_registers_tree._TreeAppendColButtonInfo();
}
void _tbdebug_regs_form.on_resize()
{
   _nocheck _control ctl_registers_tree;
   debug_gui_resize_toolbar(0,ctl_registers_tree);
}
void _tbdebug_regs_form.on_change(int reason)
{ 
   _nocheck _control ctl_registers_tree;
   if( ctl_registers_tree.p_user && reason==CHANGE_AUTO_SHOW ) {
      debug_gui_update_registers(true);
   }
}
void _tbdebug_regs_form.on_got_focus()
{ 
   _nocheck _control ctl_registers_tree;
   if ( ctl_registers_tree.p_user ) {
      debug_gui_update_registers();
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
#define VSDEBUG_MEMORY_FORM "_tbdebug_memory_form"
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
   _smart_toolbar_hotkey();
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

   int addr_width = ctl_memory_tree._text_width("0x87654321 ");
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
   debug_gui_update_memory(true);
   //ctl_memory_tree._TreeAdjustLastColButtonWidth();
   ctl_memory_tree._TreeRefresh();
//   ctl_memory_tree._TreeSetTextboxCreateFunction(debug_memory_textbox_init);

   // use same font as is the default for editor windows
   font := _default_font(CFG_WINDOW_TEXT);
   typeless font_name, font_size;
   parse font with font_name "," font_size "," .;
   ctl_memory_tree.p_font_name = font_name;
   ctl_memory_tree.p_font_size = (int) font_size;
}
void ctl_address_combo.on_destroy()
{
   ctl_address_combo._append_retrieve(ctl_address_combo,ctl_address_combo.p_text);
   ctl_size._append_retrieve(ctl_size,ctl_size.p_text);
}
void _tbdebug_memory_form.on_change(int reason)
{ 
   _nocheck _control ctl_memory_tree;
   if( ctl_memory_tree.p_user && reason==CHANGE_AUTO_SHOW ) {
      debug_gui_update_memory(true);
   }
}
void _tbdebug_memory_form.on_got_focus()
{ 
   _nocheck _control ctl_memory_tree;
   if ( ctl_memory_tree.p_user ) {
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
   debug_gui_update_memory(true);
   int fw=0,bw=0,bf=0,bs=0;
   _str bc="";
   ctl_memory_tree._TreeGetColButtonInfo(0,fw,bf,bs,bc);
   ctl_memory_tree._TreeGetColButtonInfo(1,bw,bf,bs,bc);
   int nw = (ctl_memory_tree.p_width-fw)*2 intdiv 3;
   int index=ctl_memory_tree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   if (index > 0) {
      _str caption=ctl_memory_tree._TreeGetCaption(index);
      if (substr(caption,1,2)=="0x") {
         parse caption with . "\t" caption "\t" . ;
         int cw=ctl_memory_tree._text_width(' 'caption' ');
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
      if (dbg_get_session_name(session_id) != 'gdb') return 0;
      return (int)debug_session_is_implemented("modify_local");

   } else if (reason == CHANGE_EDIT_CLOSE) {

      // cancel if they wiped out all the text
      int col = arg(3);
      _str new_value = arg(4);
      if (new_value=='') {
         return(DELETED_ELEMENT_RC);
      }

      // massage the value depending on if it is hex or ascii
      if (col==1) {
         new_value = stranslate(new_value,'',' ');
         new_value = stranslate(new_value,'','-');
      } else {
         // convert escaped string to hex
         hex_value := '';
         int i=0, n=length(new_value);
         for (i=1; i<=n; ++i) {
            ch := substr(new_value,i,1);
            if (ch=='\') {
               i++;
               ch = substr(new_value,i,1);
               switch (ch) {
               case 'n':  hex_value :+= "0a"; break;
               case 'r':  hex_value :+= "0e"; break;
               case 't':  hex_value :+= "09"; break;
               case 'v':  hex_value :+= "0b"; break;
               case '0':  hex_value :+= "00"; break;
               case '1':  hex_value :+= "01"; break;
               case '2':  hex_value :+= "02"; break;
               case '3':  hex_value :+= "03"; break;
               case '4':  hex_value :+= "04"; break;
               case '5':  hex_value :+= "05"; break;
               case '6':  hex_value :+= "06"; break;
               case '7':  hex_value :+= "07"; break;
               case '8':  hex_value :+= "08"; break;
               case '9':  hex_value :+= "09"; break;
               case '\':  hex_value :+= "5c"; break;
               case 'x':
                  hex_value :+= substr(new_value,i+1,2);
                  i+=2;
                  break;
               }
            } else {
               hex_value :+= substr(dec2hex(_asc(ch),16),3);
            }
         }
         new_value=hex_value;
      }

      // make sure all the digits are hex
      if (pos("^:h*$",new_value,1,'r') != 1) {
         _message_box("Invalid characters: Expecting hexadecimal numbers only");
         return(-1);
      }

      // make sure they gave an even number of digits (corresponding to chars)
      if (length(new_value) % 2) {
         _message_box("Expecting an even number of digits");
         return(-1);
      }

      // dig up the original value
      line := _TreeGetCaption(index);
      parse line with auto address "\t" auto value "\t" auto text;
      if (col == 1) {
         value = stranslate(value,'',' ');
         value = stranslate(value,'','-');
      } else {
         // convert string to hex, just to measure length
         value = '';
         int i=0, n=length(text);
         for (i=1; i<=n; ++i) {
            ch := substr(text,i,1);
            value :+= substr(dec2hex(_asc(ch),16),3);
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

      // now modify the memory
      status := debug_gdb_modify_memory(address,new_value);
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
 * Use gdb's -data-evaluate-expression and a cast to modify 
 * memory byte-by-byte. 
 */
static int debug_gdb_modify_memory(_str address, _str value)
{
   session_id := dbg_get_current_session();
   offset := 0;
   value = stranslate(value,'',' ');
   while (value != '') {
      byte := substr(value,1,2);
      value = substr(value,3);
      cmd  := "-data-evaluate-expression \"(*(((unsigned char*)"address")+"offset")=0x"byte")\"";
      status := dbg_session_do_command(session_id, cmd, auto rpy, auto err, false);
      if (substr(rpy,1,6)=='^error' || status < 0) {
         parse rpy with "^error,msg=" rpy;
         _message_box("Error modifying memory at "address"+"offset": "rpy);
         return status;
      }
      offset++;
   }
   return 0;
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
      if (isinteger(wid.ctl_size.p_text)) {
         size=(int)wid.ctl_size.p_text;
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
         int thread_id=dbg_get_cur_thread();
         int frame_id=dbg_get_cur_frame(thread_id);
         _str size_var;
         int dereference_status=debug_pkg_eval_expression(thread_id,frame_id,"*("address")",size_var);
         if (dereference_status==DEBUG_EXPR_CANNOT_CAST_STRING_RC ||
             dereference_status==DEBUG_EXPR_CANNOT_CAST_OBJECT_RC) {
            dereference_status=0;
         }
         int status=debug_pkg_eval_expression(thread_id,frame_id,"sizeof("address")",size_var);
         if (dereference_status) {
            address="&"address;
         } else {
            status=debug_pkg_eval_expression(thread_id,frame_id,"sizeof(*("address"))",size_var);
         }
         if (!status && (int)wid.ctl_size.p_text < (int)size_var) {
            size=(int)size_var;
         } else {
            size=(int)wid.ctl_size.p_text;
         }
      } else {
         size=(int)wid.ctl_size.p_text;
      }

      wid.ctl_address_combo.p_text=address;
      _append_retrieve(wid.ctl_address_combo,address);
      wid.ctl_size.p_text=size;
      dbg_clear_memory();
      debug_gui_clear_memory();
      if (debug_is_suspended()) {
         debug_gui_update_memory(true);
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
   debug_check_and_set_suspended();
   debug_gui_update_all();
   debug_gui_update_all_buttons();
   debug_gui_update_breakpoints(true);
   debug_gui_update_exceptions(true);
   debug_show_next_statement(true,0,0,'','',0,0);
   return 0;
}

/**
 * Update all the debug toolbars, except for the button bars
 */
int debug_gui_update_all(int thread_id=0, int frame_id=0)
{
   // first take care of the current session
   debug_gui_update_current_session();

   // first take care of the threads
   status := debug_gui_update_threads();
   if (!thread_id) {
      thread_id=dbg_get_cur_thread();
   }
   int num_threads=dbg_get_num_threads();
   if (num_threads <= 0) {
      thread_id=0;
   } else if (thread_id <= 0 || thread_id > num_threads) {
      thread_id=1;
   }
   if (!frame_id) {
      frame_id=dbg_get_cur_frame(thread_id);
   }

   // now, if we have a thread, update the stack for it
   dbg_set_cur_thread(thread_id);
   debug_gui_update_cur_thread(thread_id);
   if (status != DEBUG_GDB_TIMEOUT_RC) {
      status = debug_gui_update_stack(thread_id);
   }

   // update everything that depends on the thread and frame
   if (status != DEBUG_GDB_TIMEOUT_RC) {
      status = debug_gui_switch_frame(thread_id,frame_id);
   }

   // now update the non-thread and non-frame specific toolbars
   if (status != DEBUG_GDB_TIMEOUT_RC) {
      status = debug_gui_update_registers();
   }
   if (status != DEBUG_GDB_TIMEOUT_RC) {
      status = debug_gui_update_memory();
   }

   // update the suspended state and buttons
   debug_gui_update_suspended();
   debug_gui_update_all_buttons();

   // update the user views
   if (status != DEBUG_GDB_TIMEOUT_RC) {
      debug_gui_update_user_views(VSDEBUG_UPDATE_ALL);
      debug_gui_update_user_views(VSDEBUG_UPDATE_USER);
   }

   // that's all folks
   return(status);
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
      thread_id=dbg_get_cur_thread();
   }
   if (!frame_id) {
      frame_id=dbg_get_cur_frame(thread_id);
   }
   status := 0;
   if (status != DEBUG_GDB_TIMEOUT_RC) {
      status = debug_gui_update_locals(thread_id,frame_id);
   }
   if (status != DEBUG_GDB_TIMEOUT_RC) {
      status = debug_gui_update_members(thread_id,frame_id);
   }
   if (status != DEBUG_GDB_TIMEOUT_RC) {
      status = debug_gui_update_autovars(thread_id,frame_id);
   }
   if (status != DEBUG_GDB_TIMEOUT_RC) {
      int tab_number=debug_gui_active_watches_tab();
      status = debug_gui_update_watches(thread_id,frame_id,tab_number);
   }
   if (status != DEBUG_GDB_TIMEOUT_RC) {
      status = debug_gui_update_memory(true);
   }

   // static fields in the symbol browser may have changed
   if (status != DEBUG_GDB_TIMEOUT_RC) {
      int classes_wid=debug_gui_classes_tree();
      if (classes_wid) {
         classes_wid.debug_gui_reexpand_fields(TREE_ROOT_INDEX);
      }
   }

   // call the user views callback
   if (status != DEBUG_GDB_TIMEOUT_RC) {
      debug_gui_update_user_views(VSDEBUG_UPDATE_VARIABLES);
   }

   // that's all folks
   refresh();
   return(status);
}

/**
 * Update the class tree view
 */
int debug_gui_update_classes(boolean alwaysUpdate=false)
{
   if ( !debug_is_suspended() && !alwaysUpdate ) {
      return(0);
   }

   CTL_FORM form_wid=debug_gui_classes_wid();
   boolean isActive = alwaysUpdate || _tbIsWidActive(form_wid);

   int status=0;
   CTL_TREE tree_wid=debug_gui_classes_tree();
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
   // don't let this function be recursive
   if (gInUpdateThreadList || gInUpdateThread) {
      return(0);
   }
   gInUpdateThread=true;

   // update the threads tree, if we have one
   CTL_TREE tree_wid=debug_gui_threads_tree();
   if (tree_wid) {
      int tree_index=tree_wid._TreeSearch(TREE_ROOT_INDEX,'','T',thread_id);
      if (tree_index>0 && tree_index!=tree_wid._TreeCurIndex()) {
         tree_wid._TreeSetCurIndex(tree_index);
      }
      tree_wid._TreeSortCol();
   }

   CTL_COMBO list_wid=debug_gui_stack_thread_list();
   if (list_wid) {
      // update the thread names
      debug_pkg_update_threadnames();
      // get the thread name
      _str thread_name='';
      _str thread_group='';
      int thread_flags=0;
      int status=dbg_get_thread(thread_id,thread_name,thread_group,thread_flags);
      if (status) {
         gInUpdateThread=false;
         return(status);
      }
      // set the thread caption in the stack toolbar
      gInUpdateThreadList=true;
      _str thread_caption=(thread_group!='')? thread_group'.'thread_name : thread_name;
      list_wid._cbset_text(thread_caption);
      gInUpdateThreadList=false;
      list_wid._cbset_text(thread_caption);
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
int debug_gui_update_threads(boolean alwaysUpdate=false)
{
   // don't let this function be recursive
   if (gInUpdateThreadList) {
      return(0);
   }
   gInUpdateThreadList=true;

   // if the threads toolbar is not active, don't update yet
   int form_wid = debug_gui_threads_wid();
   boolean isActive = alwaysUpdate || _tbIsWidActive(form_wid);
   if (!form_wid) {
      gInUpdateThreadList=false;
      return(0);
   }

   // update the threads
   int result=0;
   int status=debug_pkg_update_threads();
   if (status) {
      result=status;
   } else {
      if (isActive) {
         status=debug_pkg_update_threadgroups();
         if (status) {
            result=status;
         }
         status=debug_pkg_update_threadnames();
         if (status) {
            result=status;
         }
         status=debug_pkg_update_threadstates();
         if (status) {
            result=status;
         }
      }
   }

   // update the thread list
   CTL_TREE tree_wid=debug_gui_threads_tree();
   if (tree_wid && isActive) {
      // save the original caption prefix
      _str caption='',thread_name='',group_name='';
      int tree_index=tree_wid._TreeCurIndex();
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
      if (caption!='') {
         tree_index=tree_wid._TreeSearch(TREE_ROOT_INDEX,caption,'TP');
         if (tree_index>0 && tree_index!=tree_wid._TreeCurIndex()) {
            tree_wid._TreeSetCurIndex(tree_index);
         }
      } else {
         int thread_id=dbg_get_cur_thread();
         tree_index=tree_wid._TreeSearch(TREE_ROOT_INDEX,'','TP',thread_id);
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
   if (result != DEBUG_GDB_TIMEOUT_RC) {
      debug_gui_update_user_views(VSDEBUG_UPDATE_THREADS);
   }

   // that's all folks
   gInUpdateThreadList=false;
   return(result);
}
/**
 * Update the list of breakpoints in all views
 */
int debug_gui_update_breakpoints(boolean updateEditor=false)
{
   CTL_TREE tree_wid=debug_gui_breakpoints_tree();
   if (tree_wid) {
      tree_wid._TreeBeginUpdate(TREE_ROOT_INDEX);
      dbg_update_breakpoints_tree(tree_wid,TREE_ROOT_INDEX,
                                  _strip_filename(_project_name,'N'),
                                  -1,-1);
      // DJB 05/20/2005 -- have to force enable/disable states
      //                -- because tree insert in update will not
      //                -- guarrantee tree node state changes
      int i,n = dbg_get_num_breakpoints();
      for (i=1; i<=n; ++i) {
         int enabled = dbg_get_breakpoint_enabled(i);
         int checkState = (enabled==0)? TCB_UNCHECKED:TCB_CHECKED;
         if (enabled==1) checkState = TCB_PARTIALLYCHECKED;
         int tree_index = tree_wid._TreeSearch(TREE_ROOT_INDEX,'','',i);
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
   int status=0;
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
      int tree_index = tree_wid._TreeSearch(TREE_ROOT_INDEX,'','',breakpoint_id);
      if (tree_index > 0) tree_wid._TreeSetCurIndex(tree_index);
   }
   return 0;
}
/**
 * Update the list of exceptions in all views
 */
int debug_gui_update_exceptions(boolean updateEditor=false)
{
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
int debug_gui_update_stack(int thread_id)
{
   if (!debug_active()) return(0);
   if (!debug_is_suspended()) return(0);
   if (gInUpdateThreadList || gInUpdateThread) {
      return(0);
   }

   int result=0;
   int status=debug_pkg_update_stack(thread_id);
   if (status) {
      result=status;
   }

   // update the source file paths for each stack frame
   int frame_id,num_frames=dbg_get_num_frames(thread_id);
   for (frame_id=1; frame_id<=num_frames; ++frame_id) {
      // get the details about the current method
      _str method_name='',signature='',return_type='',class_name='',file_name='',address='';
      int line_number=0;
      status=dbg_get_frame(thread_id, frame_id, method_name, signature, return_type, class_name, file_name, line_number, address);
      if (status) {
         continue;
      }
      // no source code or debug information
      if (file_name=='' || line_number<0) {
         continue;
      }
      // Attempt to resolve the path to 'file_name'
      if (file_name != absolute(file_name)) {
         _str full_path=debug_resolve_or_prompt_for_path(file_name,class_name,method_name,true);
         if (full_path!='') {
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
   if (result != DEBUG_GDB_TIMEOUT_RC) {
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

   // update the bitmaps in the editor controls
   if (_isEditorCtl()) {
      dbg_update_editor_stack(thread_id,frame_id);
   } else {
      _mdi.p_child.dbg_update_editor_stack(thread_id,frame_id);
   }

   // update the stack tree, if we have one
   CTL_TREE tree_wid=debug_gui_stack_tree();
   if (tree_wid) {
      int tree_index=tree_wid._TreeSearch(TREE_ROOT_INDEX,'','T',frame_id);
      if (tree_index>0 && tree_index!=tree_wid._TreeCurIndex()) {
         tree_wid._TreeSetCurIndex(tree_index);
      }
   }

   _str method_name='';
   _str signature='';
   _str return_type='';
   _str class_name='';
   _str file_name='';
   _str address='';
   int line_number=0;
   int status=dbg_get_frame(thread_id,frame_id,method_name,signature,return_type,class_name,file_name,line_number,address);
   if (status) {
      gInUpdateFrame=false;
      return(status);
   }
   _str frame_caption=method_name'('signature')';

   CTL_COMBO list_wid=debug_gui_local_stack_list();
   if (list_wid) {
      list_wid._cbset_text(frame_caption);
      list_wid.p_line=frame_id;
      list_wid._lbselect_line();
   }

   list_wid=debug_gui_members_stack_list();
   if (list_wid) {
      list_wid._cbset_text(frame_caption);
      list_wid.p_line=frame_id;
      list_wid._lbselect_line();
   }

   list_wid=debug_gui_auto_stack_list();
   if (list_wid) {
      list_wid._cbset_text(frame_caption);
      list_wid.p_line=frame_id;
      list_wid._lbselect_line();
   }

   // attempt to resolve the paths in the frame
   boolean paths_changed=false;
   int i,n=dbg_get_num_frames(thread_id);
   for (i=1; i<=n; ++i) {
      status=dbg_get_frame(thread_id,i,method_name,signature,return_type,class_name,file_name,line_number,address);
      if (status) {
         gInUpdateFrame=false;
         return(status);
      }
      if (file_name!='' && line_number>=0 && file_name!=absolute(file_name)) {
         _str full_path=debug_resolve_or_prompt_for_path(file_name,class_name,method_name,true);
         if (full_path!='') {
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
   // TBF
   if (!_isEditorCtl()) {
      if (_no_child_windows()) {
         return(0);
      }
      return _mdi.p_child.debug_gui_update_disassembly();
   }

   // update the disassembly
   int status = dbg_update_disassembly(p_window_id, p_buf_name);

   // update the editor stack
   int thread_id = dbg_get_cur_thread();
   int frame_id  = dbg_get_cur_frame(thread_id);
   dbg_update_editor_stack(thread_id, frame_id);
   dbg_update_editor_breakpoints();

   // maybe update the user views of the disassembly
   if (status != DEBUG_GDB_TIMEOUT_RC) {
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
   // make sure the current object is an editor control
   if (!_isEditorCtl()) {
      if (_no_child_windows()) {
         return 0;
      }
      return _mdi.p_child.debug_gui_clear_disassembly();
   }

   // Removes files from list that have been autosaved or will be autosaved
   int orig_wid = p_window_id;
   activate_window(VSWID_HIDDEN);
   _safe_hidden_window();
   int orig_buf_id = p_buf_id;
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
int debug_gui_update_locals(int thread_id, int frame_id, boolean alwaysUpdate=false)
{
   if (!debug_active()) return(0);
   if (!debug_is_suspended()) return(0);
   if (gInUpdateThreadList || gInUpdateThread || gInUpdateFrame) {
      return(0);
   }

   CTL_FORM form_wid = debug_gui_locals_wid();
   boolean isActive = alwaysUpdate || _tbIsWidActive(form_wid);

   int status=0;
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
int debug_gui_update_members(int thread_id, int frame_id, boolean alwaysUpdate=false)
{
   if (!debug_active()) return(0);
   if (!debug_is_suspended()) return(0);
   if (gInUpdateThreadList || gInUpdateThread || gInUpdateFrame) {
      return(0);
   }

   CTL_FORM form_wid = debug_gui_members_wid();
   boolean isActive = alwaysUpdate || _tbIsWidActive(form_wid);

   int status=0;
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
int debug_gui_update_autovars(int thread_id, int frame_id, boolean alwaysUpdate=false)
{
   if (!debug_active()) return(0);
   if (!debug_is_suspended()) return(0);
   if (gInUpdateThreadList || gInUpdateThread || gInUpdateFrame) {
      return(0);
   }

   CTL_FORM form_wid=debug_gui_autovars_wid();
   boolean isActive = alwaysUpdate || _tbIsWidActive(form_wid);

   CTL_TREE tree_wid=debug_gui_autovars_tree();
   if (tree_wid && isActive) {
      int status=debug_pkg_update_autos(thread_id, frame_id);
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
                             boolean in_place=false, boolean alwaysUpdate=false)
{
   CTL_FORM form_wid=debug_gui_watches_wid();
   boolean isActive = alwaysUpdate || _tbIsWidActive(form_wid);

   CTL_TREE tree_wid=debug_gui_watches_tree();
   if (tree_wid && isActive) {

      int status=0;
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
         int index=tree_wid._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
         while (index > 0) {
            int watch_id=tree_wid._TreeGetUserInfo(index);
            if (watch_id > 0) {
               int expandable=0,show_children=0,base;
               _str expr,context_name='',value='',raw_value = '',type='';
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
         int add_index=tree_wid._TreeAddItem(TREE_ROOT_INDEX,DEBUG_ADD_WATCH_CAPTION,TREE_ADD_AS_CHILD,0,0,-1,TREENODE_BOLD,-1);
         tree_wid.debug_gui_reexpand_captions(TREE_ROOT_INDEX, expandedCaptions);
      }
      tree_wid._TreeRefresh();
      tree_wid.p_user = 0;
   }

   if (tree_wid && !isActive) {
      tree_wid.p_user = 1;
   }

   // update the user views of the watches
   if (debug_gui_query_user_views(VSDEBUG_UPDATE_WATCHES)) {
      debug_pkg_update_watches(thread_id, frame_id, tab_number);
      debug_gui_update_user_views(VSDEBUG_UPDATE_WATCHES);
   }

   // that's all folks
   return(0);
}

/**
 * Update the registers view
 */
int debug_gui_update_registers(boolean alwaysUpdate=false)
{
   if ( !debug_is_suspended() && !alwaysUpdate ) {
      return(0);
   }

   CTL_FORM form_wid=debug_gui_registers_wid();
   boolean isActive = alwaysUpdate || _tbIsWidActive(form_wid);

   CTL_TREE tree_wid=debug_gui_registers_tree();
   if (tree_wid && isActive) {
      int status=debug_pkg_update_registers();
      if (status) {
         return tree_wid.debug_tree_message(status);
      }

      tree_wid._TreeBeginUpdate(TREE_ROOT_INDEX);
      status=dbg_update_registers_tree(tree_wid, TREE_ROOT_INDEX);
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
      debug_pkg_update_registers();
      debug_gui_update_user_views(VSDEBUG_UPDATE_REGISTERS);
   }

   // that's all folks
   return(0);
}

/**
 * Update all the debug toolbars, except for the button bars
 */
int debug_gui_update_memory(boolean alwaysUpdate=false)
{
   if (!(debug_is_suspended() || alwaysUpdate)) {
      return(0);
   }

   CTL_FORM form_wid=debug_gui_memory_wid();
   boolean isActive = alwaysUpdate || _tbIsWidActive(form_wid);

   CTL_TREE tree_wid=debug_gui_memory_tree();
   if (tree_wid && isActive) {

      _str address=0;
      int size=0;
      debug_gui_memory_params(address,size);
      int status=debug_pkg_update_memory(address,size);
      if (status) {
         return tree_wid.debug_tree_message(status);
      }

      int cur_line=tree_wid._TreeScroll();
      tree_wid._TreeBeginUpdate(TREE_ROOT_INDEX);
      status=dbg_update_memory_tree(tree_wid, TREE_ROOT_INDEX);
      tree_wid._TreeEndUpdate(TREE_ROOT_INDEX);
      tree_wid._TreeSortCaption(TREE_ROOT_INDEX);
      if (size > 0 && tree_wid._TreeGetNumChildren(TREE_ROOT_INDEX)==0) {
         _str msg = "Error" :+ "\t";
         if (status < 0) {
            msg = msg :+ get_message(status);
         } else {
            msg = msg :+ "No memory visible at this location.";
         }
         int index=tree_wid._TreeAddItem(TREE_ROOT_INDEX,msg,TREE_ADD_AS_CHILD,0,0,-1,0,0);
      }
      tree_wid._TreeScroll(cur_line);
      tree_wid._TreeAdjustColumnWidths(0);
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
   debug_gui_stack_update_buttons();
   debug_gui_breakpoints_update_buttons();

   // make sure the editor stack is update to date
   int thread_id=dbg_get_cur_thread();
   if (debug_is_suspended() || dbg_get_num_frames(thread_id) > 0) {
      int frame_id=dbg_get_cur_frame(thread_id);
      if (_isEditorCtl()) {
         dbg_update_editor_stack(thread_id,frame_id);
      } else {
         _mdi.p_child.dbg_update_editor_stack(thread_id,frame_id);
      }
   }

   // update the user views if they have buttons to enable/disable
   debug_gui_update_user_views(VSDEBUG_UPDATE_BUTTONS);

   // update everything on the button bar
   _tbOnUpdate(true);
}

/**
 * Single function for efficiently switching the current frame
 */
int debug_gui_switch_frame(int thread_id, int frame_id)
{
   mou_hour_glass(1);
   int num_frames=dbg_get_num_frames(thread_id);
   if (frame_id <= 0 || frame_id > num_frames) {
      frame_id=(num_frames > 0)? 1:0;
   }
   if (frame_id > 0) {
      dbg_set_cur_frame(thread_id,frame_id);
   }

   // update everything that depends on the thread and frame
   status := debug_gui_update_cur_frame(thread_id,frame_id);
   debug_gui_update_all_buttons();

   if (status != DEBUG_GDB_TIMEOUT_RC) {
      status = debug_gui_update_autovars(thread_id,frame_id);
   }
   if (status != DEBUG_GDB_TIMEOUT_RC) {
      status = debug_gui_update_locals(thread_id,frame_id);
   }
   if (status != DEBUG_GDB_TIMEOUT_RC) {
      status = debug_gui_update_members(thread_id,frame_id);
   }
   if (status != DEBUG_GDB_TIMEOUT_RC) {
      int tab_number=debug_gui_active_watches_tab();
      status = debug_gui_update_watches(thread_id,frame_id,tab_number);
   }

   // static fields in the symbol browser may have changed
   if (status != DEBUG_GDB_TIMEOUT_RC) {
      int classes_wid=debug_gui_classes_tree();
      if (classes_wid) {
         classes_wid.debug_gui_reexpand_fields(TREE_ROOT_INDEX);
      }
   }

   mou_hour_glass(0);
   return(status);
}

/**
 * Disable combo boxes when suspended.
 */
void debug_gui_update_suspended()
{
   // disable threads combo boxes if we don't have threads support
   CTL_COMBO list_wid=debug_gui_stack_thread_list();
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
   int i,n=gUserViewList._length();
   for (i=0; i<n; ++i) {
      (*gUserViewList[i])(reason);
   }
   gInUpdateUserViews=false;
}
/**
 * Check if we need to update the user views for a given reason code
 */
boolean debug_gui_query_user_views(int reason)
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
   int i;
   int numCallbacks = gUserViewList._length();
   for (i = 0; i < numCallbacks; i++) {
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
   int i, len=base_list._length();
   AddGlobalBasesToMenu(menu_handle,base_list);
   AddLocalBasesToMenu(menu_handle,base_list);
   return(0);
}

static int AddGlobalBasesToMenu(int menu_handle,int (&base_list)[])
{
   int submenu_handle=0;
   int menu_pos=_menu_find_loaded_menu_caption(menu_handle,"View var as",submenu_handle);
   int i;
   int len=base_list._length();
   _str global_base=dbg_get_global_format();
   for (i=0;i<len;++i) {
      _str cur_base_name=dbg_get_format_name(base_list[i]);
      int flags=0;
      if ( global_base==base_list[i] ) {
         flags|=MF_CHECKED;
      }
      _menu_insert(menu_handle,menu_pos,flags,cur_base_name,"debug_set_global_base ":+base_list[i]);
   }
   return(0);
}

static int AddLocalBasesToMenu(int menu_handle,int (&base_list)[])
{
   int submenu_handle=0;
   int menu_pos=_menu_find_loaded_menu_caption(menu_handle,"View variable as",submenu_handle);
   int i;
   int len=base_list._length();

   int index=_TreeCurIndex();

   int watch_id=_TreeGetUserInfo(index);
   if (watch_id==0) {
      _menu_delete(menu_handle,menu_pos);
      return(1);
   }

   _str watch_option='';
   if (substr(p_name,1,length('ctl_watches'))=='ctl_watches') {
      watch_option='-watch';
   }

   _str var_name = debug_get_variable_name();
   _str caption_varname=var_name;
   if (watch_option!='') {
      caption_varname='"':+var_name:+'"';
   }
   _menu_set_state(menu_handle,menu_pos,0,'P',"View ":+caption_varname:+" as");

   int var_base=dbg_get_var_format(var_name);
   // If this is a watch variable, we have to check for a format on the watch itself
   if (watch_option=='-watch') {
      int expandable=0,tab_number;
      _str expr,context_name,value,raw_value = '',type='';
      dbg_get_watch(0,0,watch_id,tab_number,expr,context_name,value,expandable,var_base,raw_value,type);
   }
   for (i=0;i<len;++i) {
      _str cur_base_name=dbg_get_format_name(base_list[i]);
      int flags=0;
      if ( var_base==base_list[i] ) {
         flags|=MF_CHECKED;
      }
      _menu_insert(submenu_handle,i,flags,cur_base_name,"debug_set_var_base ":+watch_option:+" ":+var_name:+" ":+base_list[i]);
   }
   return(0);
}

static int DisableLocalBasesToMenu(int menu_handle)
{
   int submenu_handle=0;
   int menu_pos=_menu_find_loaded_menu_caption(menu_handle,"View var as",submenu_handle);
   int i;

   int index=_TreeCurIndex();

   _str caption=_TreeGetCaption(index);
   _str varname='';
   parse caption with varname .;

   if (_TreeGetUserInfo(index)==0) {
      _menu_delete(menu_handle,menu_pos);
      return(1);
   }

   _menu_set_state(menu_handle,menu_pos,MF_GRAYED,'P',"View ":+varname:+" as");
   return(0);
}

_command int debug_set_global_base(int new_base=-1) name_info(','VSARG2_READ_ONLY)
{
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

_command int debug_toggle_hex() name_info(','VSARG2_READ_ONLY)
{
   int new_base = VSDEBUG_BASE_HEXADECIMAL;
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

_command int debug_set_var_base(_str args='') name_info(','VSARG2_READ_ONLY)
{
   if ( args=='' ) {
      return(INVALID_ARGUMENT_RC);
   }
   int status=0;
   _str varname='';
   int new_base=0;
   _str new_base_str='';
   boolean iswatch=false;

   _str cur_arg='';
   for (;;) {
      cur_arg=parse_file(args);
      if (substr(cur_arg,1,1)!='-' || cur_arg=='') break;
      if (cur_arg=='-watch') {
         iswatch=true;
      }else if (iswatch) {
         // If we got here, this is a watch variable, and  we still have a leading '-'
         // That means that this is really an expression, and we should break so that this gets
         // treated as the variable name.
         break;
      }
   }

   varname=cur_arg;
   new_base_str=parse_file(args);

   if (varname=='' || new_base_str=='') {
      return(INVALID_ARGUMENT_RC);
   }

   if ( dbg_get_global_format()!=VSDEBUG_BASE_DEFAULT ) {
      int result=_message_box(nls("The global base is currently set to %s, and this will override individual variable settings.\n\nWould you like to shut off the global base now?",dbg_get_format_name(dbg_get_global_format())),'',MB_YESNOCANCEL);
      if ( result==IDYES ) {
         dbg_set_global_format(VSDEBUG_BASE_DEFAULT);
      }else if (result==IDCANCEL) {
         return(COMMAND_CANCELLED_RC);
      }
   }

   new_base=(int)new_base_str;

   if (!iswatch) {
      dbg_set_var_format(varname,new_base);
   }else{
      int watch_id=0;
      int index=_TreeCurIndex();
      if (index>=0) {
         watch_id=_TreeGetUserInfo(index);
      }
      int expandable=0,tab_number,cur_base=VSDEBUG_BASE_DEFAULT;
      _str expr,context_name,value,raw_value='',type='';
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

   int status = mouse_drag(null, "_execpt.ico");
   if (status < 0) {
      debug_gui_update_stack(dbg_get_cur_thread());
      return status;
   }

   debug_set_instruction_pointer();
   return 0;
}

#if __NT__
///////////////////////////////////////////////////////////////////////////
// Callbacks for WinDbg debug other executable attach form
//
defeventtab _debug_windbg_executable_form;
void ctl_ok.lbutton_up()
{
   _str program_name=ctl_file.p_text;
   if (program_name=='') {
      debug_message("Expecting an executable file!",0,true);
      ctl_file._set_focus();
      return;
   } else if (!file_exists(program_name)) {
      debug_message(program_name,FILE_NOT_FOUND_RC,true);
      return;
   }

   // get the working directory specified
   _str dir_name=ctl_dir.p_text;
   if (dir_name != '' && !file_exists(dir_name)) {
      debug_message(dir_name,FILE_NOT_FOUND_RC,true);
      return;
   }
   _str symbols_name = ctl_symbols.p_text;
   _str program_args=ctl_args.p_text;
   _save_form_response();

   // get the session name
   _str session_name = ctl_session_combo.p_text;

   p_active_form._delete_window("windbg: app="program_name",args="program_args",dir="dir_name",symbols="symbols_name",session="session_name);
}

void ctl_ok.on_create(_str session_name="")
{
   // get all the available debugger sessions
   max_width := ctl_session_combo.debug_load_session_names("windbg", session_name);
   if (max_width > ctl_session_combo.p_width) {
      p_active_form.p_width += (max_width - ctl_session_combo.p_width);
   }

   _debug_windbg_executable_form_initial_alignment();

   // restore the last response they entered
   ctl_file.p_text="";
   ctl_dir.p_text="";
   ctl_args.p_text="";
   _retrieve_prev_form();

   // select the default session name
   if (session_name != "") {
      ctl_session_combo._cbset_text(session_name);
   } else if (ctl_session_combo.p_text == "") {
      ctl_session_combo._cbset_text(VSDEBUG_NEW_SESSION);
   }
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _debug_windbg_executable_form_initial_alignment()
{
   rightAlign := p_active_form.p_width - ctl_label.p_x;
   sizeBrowseButtonToTextBox(ctl_file.p_window_id, ctl_find_exec.p_window_id, 0, rightAlign);
   sizeBrowseButtonToTextBox(ctl_dir.p_window_id, ctl_find_dir.p_window_id, 0, rightAlign);
   ctl_session_combo.p_width = ctl_args.p_width = ctl_symbols.p_width = (ctl_find_exec.p_x + ctl_find_exec.p_width) - ctl_args.p_x;
}

///////////////////////////////////////////////////////////////////////////
// Callbacks for WinDbg debugger attach form
//
// Note: _debug_gdb_attach_form eventtable is also used for
defeventtab _debug_windbg_attach_form;
void ctl_ok.lbutton_up()
{
   // verify that the PID is a positive integer
   int index=ctl_processes._TreeCurIndex();
   if (index <= 0) {
      debug_message("Please select a process!",0,true);
      ctl_processes._set_focus();
      return;
   }
   _str process_id=ctl_processes._TreeGetCaption(index);
   parse process_id with . "\t" process_id "\t" . ;
   _str process_name=ctl_file.p_text;
   if (process_id!='' && (!isinteger(process_id) || (int)process_id < 0)) {
      debug_message("Expecting a positive integer value!",0,true);
      ctl_processes._set_focus();
   return;
   }

   // get the session name
   _str session_name = ctl_session_combo.p_text;
   
   _str symbols_name=ctl_symbol.p_text;
   _save_form_response();
   p_active_form._delete_window("windbg: pid="process_id",image="process_name",symbols="symbols_name",session="session_name);
}

void ctl_ok.on_create(_str session_name="")
{
   // get all the available debugger sessions
   max_width := ctl_session_combo.debug_load_session_names("windbg", session_name);
   if (max_width > ctl_session_combo.p_width) {
      delta := max_width - ctl_session_combo.p_width;
      p_active_form.p_width += delta;
      ctl_processes.p_width += delta;
      ctl_refresh.p_x += delta;
      ctl_session_combo.p_width = max_width;
   }

   _debug_windbg_attach_form_initial_alignment();

   ctl_processes._TreeSetColButtonInfo(0,1500,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Name");
   ctl_processes._TreeSetColButtonInfo(1,500,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_AL_RIGHT,0,"PID");
   ctl_processes._TreeSetColButtonInfo(2,-1,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Title");

   // need to populate combo box with list of processes, and search
   // within it for a process who's name matches the current project
   // executable name
   ctl_file.p_text="";
   _retrieve_prev_form();
   ctl_processes._refresh_process_list();
   ctl_processes._TreeAdjustColumnWidths();
   ctl_processes._TreeAdjustLastColButtonWidth();

   if (session_name != "") {
      ctl_session_combo._cbset_text(session_name);
   } else if (ctl_session_combo.p_text == "") {
      ctl_session_combo._cbset_text(VSDEBUG_NEW_SESSION);
   }
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _debug_windbg_attach_form_initial_alignment()
{
   // form level
   rightAlign := ctl_processes.p_x + ctl_processes.p_width;
   sizeBrowseButtonToTextBox(ctl_file.p_window_id, ctl_find_app.p_window_id, 0, rightAlign);
   sizeBrowseButtonToTextBox(ctl_symbol.p_window_id, ctlcommand1.p_window_id, 0, rightAlign);
}

void _debug_windbg_attach_form.on_resize()
{
   // width/height of OK, Cancel, Help buttons (all are the same)
   int button_width  = ctl_ok.p_width;
   int button_height = ctl_ok.p_height;

   // have we set the min size yet?  if not, min width will be 0
   if (!_minimum_width()) {
      _set_minimum_size(button_width*3, button_height*8);
   }

   int motion_y=p_height-button_height-ctl_label.p_y-ctl_cancel.p_y;
   int motion_x=p_width-(ctl_processes.p_x*2+ctl_processes.p_width);

   ctl_ok.p_y+=motion_y;
   ctl_cancel.p_y+=motion_y;
   ctl_system.p_y+=motion_y;
   ctl_processes.p_width+=motion_x;
   ctl_processes.p_height+=motion_y;
   ctl_refresh.p_x+=motion_x;
   ctl_refresh.p_y+=motion_y;

   ctl_file_label.p_y+=motion_y;
   ctl_file.p_y+=motion_y;
   ctl_find_app.p_y+=motion_y;
   ctl_find_app.p_x+=motion_x;
   ctl_file.p_width+=motion_x;

   ctl_symbol_label.p_y+=motion_y;
   ctl_symbol.p_y+=motion_y;
   ctlcommand1.p_y+=motion_y;
   ctlcommand1.p_x+=motion_x;
   ctl_symbol.p_width+=motion_x;

   ctl_session_label.p_y+=motion_y;
   ctl_session_combo.p_y+=motion_y;
   ctl_session_combo.p_width+=motion_x;

   ctl_processes._TreeAdjustLastColButtonWidth();
}

///////////////////////////////////////////////////////////////////////////
// Callbacks for WinDbg debugger dumpfile form
//
defeventtab _debug_windbg_corefile_form;
void ctl_ok.lbutton_up()
{
   _str core_file=ctl_filename.p_text;
   _str image_path=ctl_imagepath.p_text;
   _str symbols_path=ctl_symbols.p_text;
   if (core_file=='') {
      debug_message("Expecting a dump file!",0,true);
      return;
   } else if (!file_exists(core_file)) {
      debug_message(core_file,FILE_NOT_FOUND_RC,true);
      return;
   }

   // get the session name
   _str session_name = ctl_session_combo.p_text;
   
   _save_form_response();
   p_active_form._delete_window("windbg: dumpfile="core_file",image="image_path",symbols="symbols_path",session="session_name);
}

void ctl_ok.on_create(_str session_name="")
{
   // get all the available debugger sessions
   max_width := ctl_session_combo.debug_load_session_names("windbg", session_name);
   if (max_width > ctl_session_combo.p_width) {
      delta := max_width - ctl_session_combo.p_width;
      p_active_form.p_width += delta;
      ctl_filename.p_width += delta;
      ctl_imagepath.p_width += delta;
      ctl_symbols.p_width += delta;
      ctl_session_combo.p_width = max_width;
   }

   _debug_windbg_corefile_form_initial_alignment();

   // select the default session name
   _retrieve_prev_form();

   if (session_name != "") {
      ctl_session_combo._cbset_text(session_name);
   } else if (ctl_session_combo.p_text == "") {
      ctl_session_combo._cbset_text(VSDEBUG_NEW_SESSION);
   }
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _debug_windbg_corefile_form_initial_alignment()
{
   rightAlign := p_active_form.p_width - ctllabel1.p_x;
   sizeBrowseButtonToTextBox(ctl_filename.p_window_id, ctl_find.p_window_id, 0, rightAlign);
   ctl_imagepath.p_width = ctl_symbols.p_width = (ctl_find.p_x + ctl_find.p_width) - ctl_imagepath.p_x;
}

void _debug_windbg_corefile_form.on_resize()
{
   deltax := p_width - (ctl_find.p_x + ctl_find.p_width + ctllabel1.p_x);

   ctl_find.p_x += deltax;
   ctl_filename.p_width += deltax;
   ctl_imagepath.p_width += deltax;
   ctl_symbols.p_width += deltax;
   ctl_session_combo.p_width = ctl_symbols.p_width;
}
#endif

static int show_modify_variable_dlg(int session_id, int thread_id, int frame_id, _str oldValue, _str varName, _str &newValue)
{
   // was the old value surrounded by double quotes?
   oldValueHadQuotes := false;
   if (oldValue != null) {
      oldValueHadQuotes = (oldValue == '"'strip(oldValue, 'B', '"')'"');
   }

   // ask the user whether this is a string or an expression
   newValue = '';
   status := show('-modal _dbgp_modify_variable_form', varName, oldValue, oldValueHadQuotes ? DBGP_MODIFY_STRING : -1);
   if (status == IDOK) {
      newValue = _param1;
      if (_param2 == DBGP_MODIFY_EXPR) {
         dbg_session_eval_expression(session_id, thread_id, frame_id, newValue, newValue);
      } else {
         newValue = '"'newValue'"';
      }
      return 0;
   }

   return -1;
}

defeventtab _dbgp_modify_variable_form;

#define DBGP_MODIFY_STRING 0
#define DBGP_MODIFY_EXPR   1

void _ctl_ok.on_create(_str varName, _str value, int defaultValue = -1)
{
   // set up the editor control
   _ctl_editor.p_LangId = "fundamental";
   _ctl_editor.p_line_numbers_len = 0;
   _ctl_editor.p_LCBufFlags &= ~(VSLCBUFFLAG_LINENUMBERS | VSLCBUFFLAG_LINENUMBERS_AUTO);

   _lbl_name.p_caption = "Enter new value for "varName;

   // split up the individual lines in the value
   _str lines[];
   nlPos := pos('\n', value, 1);
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
   _ctl_editor._select_char('','CN');
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
   _ctl_string_radio._append_retrieve(0, select, _ctl_string_radio.p_active_form.p_name'.'_ctl_string_radio.p_name);

   // extract the value from the editor
   _str line;
   _ctl_editor.top();
   _ctl_editor.get_line(line);
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
