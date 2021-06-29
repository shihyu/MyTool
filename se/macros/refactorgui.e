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
#include "refactor.sh"
#include "quickrefactor.sh"
#include "tagsdb.sh"
#include "cbrowser.sh"
#include "diff.sh"
#include "minihtml.sh"
#import "cbrowser.e"
#import "cjava.e"
#import "combobox.e"
#import "diff.e"
#import "diffmf.e"
#import "diffedit.e"
#import "guicd.e"
#import "gnucopts.e"
#import "guiopen.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "picture.e"
#import "projconv.e"
#import "project.e"
#import "projutil.e"
#import "quickrefactor.e"
#import "refactor.e"
#import "saveload.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "taggui.e"
#import "tags.e"
#import "treeview.e"
#import "util.e"
#import "wkspace.e"
#endregion
/**
 * This module implements our support for refactoring.
 *
 * @since  9.0
 */

static int VSREFACTOR_GET_METHOD_FLAGS(int FLAGS,int STANDARD_METHOD_TYPE ) {
   return ( ( FLAGS >> STANDARD_METHOD_TYPE ) & VSREFACTOR_FLAGS_MASK );
}
static int VSREFACTOR_ENABLE_METHOD_FLAG(int FLAGS,int STANDARD_METHOD_TYPE,int SETTING ) {
   return ( FLAGS | ( SETTING << STANDARD_METHOD_TYPE ) );
}
static int VSREFACTOR_DISABLE_METHOD_FLAG(int FLAGS,int STANDARD_METHOD_TYPE,int SETTING ) {
   return ( FLAGS & ~( SETTING << STANDARD_METHOD_TYPE ) );
}

///////////////////////////////////////////////////////////////////////////////
static int find_compiler_configuration_index(CompilerConfiguration (&configs)[],_str compiler)
{
   num_configs := configs._length();
   int config_index;

   for (config_index=0;config_index<num_configs;++config_index) {
      if (configs[config_index].configuarationName:==compiler) {
         return config_index;
      }
   }

   return -1;
}

static _str add_compilers_callback(int sl_event,_str &result, _str info)
{
   if (sl_event!=SL_ONDEFAULT) {
      return '';
   }

   _nocheck _control _sellist;
   int status=_sellist._lbfind_selected(true);

   result='';
   while (!status) {
      if (result:=='') {
         result=_sellist.p_line-1;
      } else {
         strappend(result,',');
         strappend(result,_sellist.p_line-1);
      }

      status=_sellist._lbfind_selected(false);
   }
   return(1);
}

_str add_new_cpp_compiler()
{
   newName := prompt_for_new_compiler_name();
   if (newName == "") {
      // user cancelled operation
      return '';
   }

   // Check for duplicate
   CompilerConfiguration configs[];
   get_cpp_compiler_configs(configs);
   if ( find_compiler_configuration_index( configs, newName ) != -1 ) {
      _message_box("Error: Configuration name \"" newName "\" already exists");
      return '';
   }

   // make a new config for this one
   config_index := configs._length();
   configs[config_index].configuarationName=newName;
   configs[config_index].systemHeader='';
   configs[config_index].systemIncludes._makeempty();

   // save it
   write_cpp_compiler_configs(configs);

   // give the user a chance to configure
   show("-xy -modal _refactor_c_compiler_properties_form", newName);

   return newName;
}

#region Options Dialog Helper Functions

defeventtab _refactor_c_compiler_properties_form;

// These are used with _GetDialogInfo and _SetDialogInfo
static const COMP_PROP_ACTIVE_CONFIG=     (0);         // int
static const COMP_PROP_SELECTED_CONFIG=   (1);         // int
static const COMP_PROP_ALL_CONFIGS=       (2);         // CompilerConfiguration[]
static const COMP_PROP_SELECTED_INC=      (3);         // int
static const COMP_PROP_MODIFIED=          (4);         // boolean - whether configuration has been modified

static const NO_CONFIGS= "No compilers found";

void _refactor_c_compiler_properties_form_init_for_options()
{
   ctl_ok.p_visible = false;
   ctl_cancel.p_visible = false;
   ctl_help.p_visible = false;
}

void _refactor_c_compiler_properties_form_save_settings()
{
   _SetDialogInfo(COMP_PROP_MODIFIED, false);
}

bool _refactor_c_compiler_properties_form_is_modified()
{
   return _GetDialogInfo(COMP_PROP_MODIFIED);
}

bool _refactor_c_compiler_properties_form_apply()
{
   // Don't let user leave this dialog until they have selected an active valid configuration.
   // This should only happen if there are no active configs when the dialog is brought up initially
   // or if they delete the active configuration
   int active_index=_GetDialogInfo(COMP_PROP_ACTIVE_CONFIG);
   if ( active_index < 0  ) {
      _message_box( "Choose a default configuration." );
      return false;
   }

   CompilerConfiguration configs[]=_GetDialogInfo(COMP_PROP_ALL_CONFIGS);
   int config_index=_GetDialogInfo(COMP_PROP_SELECTED_CONFIG);

   // If the currently selected configuration is not the active configuration,
   // ask them if they would like to make it active
   if ( config_index != active_index ) {
      int response = _message_box('Do you want to make "'configs[config_index].configuarationName'" the default configuration?',"SlickEdit", MB_YESNO);
      if (response == IDYES) {
         active_index=config_index;
      }
   }

   _str orig_active_config = def_refactor_active_config;
   def_refactor_active_config = configs[active_index].configuarationName;
   _config_modify_flags(CFGMODIFY_DEFVAR);

   write_and_save_configs();

   // configuration has changed? - only do this if embedded in options dialog
   if (!ctl_ok.p_visible && orig_active_config != def_refactor_active_config) {
      _TagCallList(TAGFILE_ADD_REMOVE_CALLBACK_PREFIX,'','');
      _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
      invalidate_latest_compiler();
   }

   return true;
}

#endregion Options Dialog Helper Functions

void ctl_ok.on_create(_str selConfig = def_refactor_active_config)
{
   CompilerConfiguration configs[];
   get_cpp_compiler_configs(configs);

   selIndex := 0;
   activeIndex := -1;

   // If default config exists then set the combo box to that one
   for (config_index:=0; config_index<configs._length(); ++config_index) {
      if (configs[config_index].configuarationName :== selConfig ) {
         selIndex = config_index;
      }
      if (configs[config_index].configuarationName :== def_refactor_active_config ) {
         activeIndex = config_index;
      }
   }

   _SetDialogInfo(COMP_PROP_ACTIVE_CONFIG,activeIndex);
   _SetDialogInfo(COMP_PROP_SELECTED_CONFIG,selIndex);

   _SetDialogInfo(COMP_PROP_ALL_CONFIGS,configs);
   _SetDialogInfo(COMP_PROP_SELECTED_INC,0);

   update_config_list();
}

static void write_and_save_configs()
{
   CompilerConfiguration configs[]=_GetDialogInfo(COMP_PROP_ALL_CONFIGS);
   write_cpp_compiler_configs(configs);

   _GetLatestCompiler(true, false);
}

void ctl_ok.lbutton_up()
{
   _str orig_active_config = def_refactor_active_config;

   if (_refactor_c_compiler_properties_form_apply()) {
      p_active_form._delete_window(def_refactor_active_config);

      // configuration has changed?
      if (orig_active_config != def_refactor_active_config) {
         _TagCallList(TAGFILE_ADD_REMOVE_CALLBACK_PREFIX,'','');
         _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
      }
   }
}

void ctl_cancel.lbutton_up()
{
   p_active_form._delete_window('');
}

static void update_config_list()
{
   // save this before we clear the list - it might get reset
   selIndex := _GetDialogInfo(COMP_PROP_SELECTED_CONFIG);

   ctl_compiler_name._lbclear();

   CompilerConfiguration configs[] = _GetDialogInfo(COMP_PROP_ALL_CONFIGS);

   int config_index;
   for (config_index=0; config_index<configs._length(); ++config_index) {
      ctl_compiler_name._lbadd_item(configs[config_index].configuarationName);
   }

   if (configs._length()==0) {
      ctl_compiler_name._lbadd_item(NO_CONFIGS);
   }

   // now select the current one
   if (selIndex >= 0 && selIndex < configs._length()) {
      ctl_compiler_name.p_line = selIndex + 1;
      if (ctl_compiler_name._lbget_seltext() != configs[selIndex].configuarationName) {
         ctl_compiler_name._lbselect_line();
      }
   }
   call_event(CHANGE_CLINE, selIndex + 1, ctl_compiler_name, ON_CHANGE, 'W');
}

static void update_config_properties()
{
   // get all data
   CompilerConfiguration configs[]=_GetDialogInfo(COMP_PROP_ALL_CONFIGS);
   int config_index=_GetDialogInfo(COMP_PROP_SELECTED_CONFIG);

   if ((config_index<0) || (config_index>=configs._length())) {
      config_index=0;
   }

   // clear other controls
   ctl_header_file.p_text="";
   ctl_include_directories._lbclear();

   int active_config=_GetDialogInfo(COMP_PROP_ACTIVE_CONFIG);
   if (active_config<0) {
      ctl_active_configuration.p_caption = "Default: None";
   }

   if (config_index >= configs._length()) {
      // can happen if there are no configs
      ctl_delete_compiler.p_enabled=false;
      ctl_copy_compiler.p_enabled=false;
      ctl_make_active.p_enabled=false;
      ctl_build_tagfile.p_enabled=false;
      ctl_header_label.p_enabled=false;
      ctl_header_file.p_enabled=false;
      ctl_browse_header.p_enabled=false;
      ctl_includes_label.p_enabled=false;
      ctl_include_directories.p_enabled=false;
      ctlBrowseUserIncludes.p_enabled=false;
      ctlMoveUserIncludesUp.p_enabled=false;
      ctlMoveUserIncludesDown.p_enabled=false;
      ctl_delete.p_enabled=false;
      ctl_refresh_includes.p_enabled=false;

      return;
   }

   _str config_name=configs[config_index].configuarationName;
   int num_includes=configs[config_index].systemIncludes._length();

   ctl_header_file.p_text=configs[config_index].systemHeader;

   int include_index;
   for (include_index=0;include_index<num_includes;++include_index) {
      ctl_include_directories._lbadd_item(configs[config_index].systemIncludes[include_index]);
   }

   include_index=_GetDialogInfo(COMP_PROP_SELECTED_INC);
   if (num_includes>0) {
      if (include_index>=num_includes) {
         include_index=num_includes-1;
      }
      ctl_include_directories.p_line=include_index+1;
      ctl_include_directories._lbselect_line();
   }

   ctl_delete_compiler.p_enabled=true;
   ctl_copy_compiler.p_enabled=true;
   ctl_make_active.p_enabled=true;
   ctl_build_tagfile.p_enabled=true;
   ctl_header_label.p_enabled=true;
   ctl_header_file.p_enabled=true;
   ctl_browse_header.p_enabled=true;
   ctl_includes_label.p_enabled=true;
   ctl_include_directories.p_enabled=true;
   ctlBrowseUserIncludes.p_enabled=true;
   ctlMoveUserIncludesUp.p_enabled=num_includes>1;
   ctlMoveUserIncludesDown.p_enabled=num_includes>1;
   ctl_delete.p_enabled=num_includes>0;
   ctl_refresh_includes.p_enabled = (config_name==COMPILER_NAME_VS6 ||
                                     config_name==COMPILER_NAME_VSDOTNET ||
                                     config_name==COMPILER_NAME_VS2003 ||
                                     config_name==COMPILER_NAME_VS2005 ||
                                     config_name==COMPILER_NAME_VS2005_EXPRESS ||
                                     config_name==COMPILER_NAME_VCPP_TOOLKIT2003 ||
                                     config_name==COMPILER_NAME_PLATFORM_SDK2003 ||
                                     config_name==COMPILER_NAME_VS2008 ||
                                     config_name==COMPILER_NAME_VS2008_EXPRESS ||
                                     config_name==COMPILER_NAME_VS2010 ||
                                     config_name==COMPILER_NAME_VS2010_EXPRESS ||
                                     config_name==COMPILER_NAME_VS2012 ||
                                     config_name==COMPILER_NAME_VS2012_EXPRESS ||
                                     config_name==COMPILER_NAME_VS2013 ||
                                     config_name==COMPILER_NAME_VS2013_EXPRESS ||
                                     config_name==COMPILER_NAME_VS2015 ||
                                     config_name==COMPILER_NAME_VS2015_EXPRESS ||
                                     substr(config_name,1,length(COMPILER_NAME_DDK))==COMPILER_NAME_DDK);

   if (active_config>=0) {
      ctl_active_configuration.p_caption = "Default: " :+ configs[active_config].configuarationName;
   }
}


void _refactor_c_compiler_properties_form.on_resize()
{
   // width/height of OK, Cancel, Help buttons (all are the same)
   int button_width  = ctl_ok.p_width;
   int button_height = ctl_ok.p_height;
   int horz_margin   = ctl_compiler_frame.p_x;
   int vert_margin   = ctl_compiler_name.p_y;

   // if OK is not visible, we're in the options dialog...things are different there.
   if (!ctl_ok.p_visible) {
      button_width = button_height = 0;
   } else {
      // force size of dialog to remain reasonable
      // if the minimum width has not been set, it will return 0
      if (!_minimum_width()) {
         _set_minimum_size(button_width*6, button_height*15);
      }
   }

   // use the 'Help' button to compute the sizing motion
   int motion_y = p_height-vert_margin-ctl_ok.p_y-button_height;
   int motion_x = p_width-horz_margin-ctl_copy_compiler.p_x-ctl_copy_compiler.p_width;

   ctl_ok.p_y     += motion_y;
   ctl_cancel.p_y += motion_y;
   ctl_help.p_y   += motion_y;
   ctl_compiler_frame.p_height += motion_y;
   ctl_include_directories.p_y_extent = ctl_compiler_frame.p_height - vert_margin;

   ctl_compiler_name.p_width += motion_x;
   ctl_add_compiler.p_x += motion_x;
   ctl_delete_compiler.p_x += motion_x;
   ctl_copy_compiler.p_x += motion_x;
   ctl_make_active.p_x += motion_x;
   ctl_build_tagfile.p_x += motion_x;
   ctl_browse_header.p_x += motion_x;
   ctl_compiler_frame.p_width += motion_x;
   ctl_header_file.p_width += motion_x;
   ctl_includes_label.p_width += motion_x;
   ctl_include_directories.p_width += motion_x;
   // align the right edges of the compilers drop down and the active compiler
   // so that the active compiler never overlaps the "Make Active" button
   ctl_active_configuration.p_x_extent = ctl_compiler_name.p_x_extent ;

   // size the buttons to the textbox
   rightAlign := ctl_compiler_frame.p_width - ctl_compiler_frame.p_x;
   sizeBrowseButtonToTextBox(ctl_header_file.p_window_id, ctl_browse_header.p_window_id, 0, rightAlign);
   alignUpDownListButtons(ctl_include_directories, 
                          rightAlign, 
                          ctlBrowseUserIncludes.p_window_id, 
                          ctlMoveUserIncludesUp.p_window_id, 
                          ctlMoveUserIncludesDown.p_window_id, 
                          ctl_delete.p_window_id, 
                          ctl_refresh_includes.p_window_id);

}

void ctl_compiler_name.on_change(int reason, int index)
{
   if ( reason != CHANGE_CLINE && reason != CHANGE_CLINE_NOTVIS ) {
      return;
   }

   _SetDialogInfo(COMP_PROP_SELECTED_CONFIG,index-1);
   _SetDialogInfo(COMP_PROP_SELECTED_INC,0);

   update_config_properties();
}

ctl_add_compiler.lbutton_up()
{
   CompilerConfiguration configs[]=_GetDialogInfo(COMP_PROP_ALL_CONFIGS);

   _str config_names[];
   _str config_includes[];
   _str header_names[];

   _str new_names[];
   _str new_includes[];
   _str new_headers[];

   getCppIncludeDirectories( config_names, config_includes, header_names );

   int index;
   for (index=0;index<config_names._length();++index) {
      if (find_compiler_configuration_index(configs,config_names[index])<0) {
         new_names[new_names._length()] = config_names[index];
         new_includes[new_includes._length()] = config_includes[index];
         new_headers[new_headers._length()] = header_names[index];
      }
   }

   prompt_for_new := false;

   new_names[new_names._length()] = 'Add other compiler';

   if (new_names._length()>1) {
      _str indices = show('-modal _sellist_form',
                          'Add Compiler',
                          SL_ALLOWMULTISELECT | SL_DEFAULTCALLBACK,
                          new_names,
                          'Add Compilers',
                          '',
                          '',
                          add_compilers_callback,
                          '',
                          '',
                          '',
                          '',
                          '');

      while (indices != '') {
         _str index_string;
         parse indices with index_string ',' indices;
         index = (int)index_string;

         if ( (index>=0) && (index < new_headers._length()) ) {
            config_index := configs._length();
            configs[config_index].configuarationName=new_names[index];
            configs[config_index].systemHeader=new_headers[index];

            _str temp_include;
            _str remaining_includes=new_includes[index];

            while (remaining_includes:!="") {
               parse remaining_includes with temp_include (PARSE_PATHSEP_RE),'r' remaining_includes;
               configs[config_index].systemIncludes[configs[config_index].systemIncludes._length()]=temp_include;
            }
            _SetDialogInfo(COMP_PROP_ALL_CONFIGS,configs);
            _SetDialogInfo(COMP_PROP_SELECTED_CONFIG,config_index);
            _SetDialogInfo(COMP_PROP_SELECTED_INC,0);
            _SetDialogInfo(COMP_PROP_MODIFIED, true);

            update_config_list();
         } else {
            prompt_for_new = true;
         }
      }
   } else {
      prompt_for_new = true;
   }

   if (prompt_for_new) {
      get_new_compiler_name();
   }
}

void ctl_delete_compiler.lbutton_up()
{
   CompilerConfiguration configs[]=_GetDialogInfo(COMP_PROP_ALL_CONFIGS);
   int config_index=_GetDialogInfo(COMP_PROP_SELECTED_CONFIG);

   configs._deleteel(config_index);

   int active_index=_GetDialogInfo(COMP_PROP_ACTIVE_CONFIG);
   if (active_index==config_index) {
      _SetDialogInfo(COMP_PROP_ACTIVE_CONFIG,-1);
   } else if (active_index>config_index) {
      _SetDialogInfo(COMP_PROP_ACTIVE_CONFIG,active_index-1);
   }

   // check if deleting the last configuration
   if (config_index==configs._length()) {
      --config_index;
   }

   _SetDialogInfo(COMP_PROP_ALL_CONFIGS,configs);
   _SetDialogInfo(COMP_PROP_SELECTED_CONFIG,config_index);
   _SetDialogInfo(COMP_PROP_SELECTED_INC,0);
   _SetDialogInfo(COMP_PROP_MODIFIED, true);

   update_config_list();
}

void ctl_copy_compiler.lbutton_up()
{
   CompilerConfiguration configs[]=_GetDialogInfo(COMP_PROP_ALL_CONFIGS);
   int config_index=_GetDialogInfo(COMP_PROP_SELECTED_CONFIG);

   // prompt for name, check for duplicate, and add to list
   // prompt for new name
   newName := "";
   _str promptResult = show("-modal _textbox_form",
                            "Enter the name for the new configuration",
                            0,
                            "",
                            "",
                            "",
                            "",
                            "Configuration name:" configs[config_index].configuarationName );
   if (promptResult == "") {
      // user cancelled operation
      return;
   }

   newName = _param1;

   // Check for duplicate
   existing_index := find_compiler_configuration_index(configs,newName);
   if ( existing_index >= 0 ) {
      _message_box("Error: Configuration name \"" newName "\" already exists");

      // select the config they just tried to add
      if (existing_index != config_index) {
         ctl_compiler_name.p_line = existing_index + 1;
         ctl_compiler_name._lbselect_line();
      }
      return;
   }

   new_config_index := configs._length();
   configs[new_config_index]=configs[config_index];
   configs[new_config_index].configuarationName=newName;

   _SetDialogInfo(COMP_PROP_ALL_CONFIGS,configs);
   _SetDialogInfo(COMP_PROP_SELECTED_CONFIG,new_config_index);
   _SetDialogInfo(COMP_PROP_MODIFIED, true);

   update_config_list();
}

void ctl_make_active.lbutton_up()
{
   _SetDialogInfo(COMP_PROP_ACTIVE_CONFIG,_GetDialogInfo(COMP_PROP_SELECTED_CONFIG));
   _SetDialogInfo(COMP_PROP_MODIFIED, true);

   update_config_properties();
}

int ctl_build_tagfile.lbutton_up()
{
   CompilerConfiguration configs[]=_GetDialogInfo(COMP_PROP_ALL_CONFIGS);
   int config_index=_GetDialogInfo(COMP_PROP_SELECTED_CONFIG);
   _str config_name = configs[config_index].configuarationName;

   write_and_save_configs();

   useThread := _is_background_tagging_enabled(AUTOTAG_LANGUAGE_NO_THREADS);
   int status = refactor_build_compiler_tagfile(config_name, 'cpp', false, useThread);
   return status;
}

ctl_header_file.on_lost_focus()
{
   CompilerConfiguration configs[]=_GetDialogInfo(COMP_PROP_ALL_CONFIGS);
   int config_index=_GetDialogInfo(COMP_PROP_SELECTED_CONFIG);

   configs[config_index].systemHeader=p_text;

   _SetDialogInfo(COMP_PROP_ALL_CONFIGS,configs);
   _SetDialogInfo(COMP_PROP_MODIFIED, true);
}

void ctl_browse_header.lbutton_up()
{
   // browse for header file
   plugin_dir := _getSlickEditInstallPath() :+ "plugins" :+ FILESEP;
   initial_header_dir := "";
   if (file_exists(plugin_dir:+"com_slickedit.base")) {
      initial_header_dir = plugin_dir :+ "com_slickedit.base" :+ FILESEP :+ "sysconfig" :+ FILESEP:+ "vsparser" :+ FILESEP;
   }
   result := _OpenDialog('-modal',
                          'Select header file', // Title
                          '*.h',                                          // Wild Cards
                          '*.h',                                          // File Filters
                          OFN_FILEMUSTEXIST,                                // OFN flags
                          '.h',                                           // Default extension
                          "",       // Initial name
                          initial_header_dir                                // Initial directory
                         );

   if ( result=='' ) {
      return;
   }
   result=strip(result,'B','"');

   CompilerConfiguration configs[]=_GetDialogInfo(COMP_PROP_ALL_CONFIGS);
   int config_index=_GetDialogInfo(COMP_PROP_SELECTED_CONFIG);

   configs[config_index].systemHeader=result;

   _SetDialogInfo(COMP_PROP_ALL_CONFIGS,configs);
   _SetDialogInfo(COMP_PROP_MODIFIED, true);

   update_config_properties();
}

static void move_inc_up()
{
   int cur_inc=_GetDialogInfo(COMP_PROP_SELECTED_INC);

   if (cur_inc>0) {
      CompilerConfiguration configs[]=_GetDialogInfo(COMP_PROP_ALL_CONFIGS);
      int config_index=_GetDialogInfo(COMP_PROP_SELECTED_CONFIG);

      _str temp=configs[config_index].systemIncludes[cur_inc-1];
      configs[config_index].systemIncludes[cur_inc-1]=configs[config_index].systemIncludes[cur_inc];
      configs[config_index].systemIncludes[cur_inc]=temp;

      _SetDialogInfo(COMP_PROP_ALL_CONFIGS,configs);
      _SetDialogInfo(COMP_PROP_SELECTED_INC,cur_inc-1);
      _SetDialogInfo(COMP_PROP_MODIFIED, true);
      update_config_properties();
   }
}

static void move_inc_down()
{
   CompilerConfiguration configs[]=_GetDialogInfo(COMP_PROP_ALL_CONFIGS);
   int config_index=_GetDialogInfo(COMP_PROP_SELECTED_CONFIG);
   int cur_inc=_GetDialogInfo(COMP_PROP_SELECTED_INC);

   if ((cur_inc+1)<configs[config_index].systemIncludes._length()) {
      _str temp=configs[config_index].systemIncludes[cur_inc+1];
      configs[config_index].systemIncludes[cur_inc+1]=configs[config_index].systemIncludes[cur_inc];
      configs[config_index].systemIncludes[cur_inc]=temp;

      _SetDialogInfo(COMP_PROP_ALL_CONFIGS,configs);
      _SetDialogInfo(COMP_PROP_SELECTED_INC,cur_inc+1);
      _SetDialogInfo(COMP_PROP_MODIFIED, true);
      update_config_properties();
   }
}

static void remove_inc()
{
   CompilerConfiguration configs[]=_GetDialogInfo(COMP_PROP_ALL_CONFIGS);
   int config_index=_GetDialogInfo(COMP_PROP_SELECTED_CONFIG);
   int cur_inc=_GetDialogInfo(COMP_PROP_SELECTED_INC);

   if ( (cur_inc>=0) && (cur_inc<configs[config_index].systemIncludes._length())) {
      configs[config_index].systemIncludes._deleteel(cur_inc);

      _SetDialogInfo(COMP_PROP_ALL_CONFIGS,configs);
      if (cur_inc>=configs[config_index].systemIncludes._length()) {
         _SetDialogInfo(COMP_PROP_SELECTED_INC,cur_inc-1);
      }
      _SetDialogInfo(COMP_PROP_MODIFIED, true);
      update_config_properties();
   }
}

void ctl_include_directories.'C-UP'()
{
   move_inc_up();
}

void ctl_include_directories.'C-DOWN'()
{
   move_inc_down();
}

void ctl_include_directories.'DEL'()
{
   remove_inc();
}

void ctl_include_directories.on_change(int reason)
{
   if (reason==CHANGE_SELECTED) {
      _SetDialogInfo(COMP_PROP_SELECTED_INC,p_line-1);
   }
}

void ctlBrowseUserIncludes.lbutton_up()
{
   _str result = _ChooseDirDialog('Choose Include Directory');
   if ( result=='' ) {
      return;
   }

   _str include_dir = result;

   CompilerConfiguration configs[]=_GetDialogInfo(COMP_PROP_ALL_CONFIGS);
   int config_index=_GetDialogInfo(COMP_PROP_SELECTED_CONFIG);

   int num_includes=configs[config_index].systemIncludes._length();
   int found_include=num_includes;

   // check if this directory is alreayd listed
   int include_index;
   for (include_index=0;include_index<num_includes;++include_index) {
      if (_file_eq(include_dir,configs[config_index].systemIncludes[include_index])) {
         found_include=include_index;
      }
   }

   configs[config_index].systemIncludes[found_include]=include_dir;

   _SetDialogInfo(COMP_PROP_ALL_CONFIGS,configs);
   _SetDialogInfo(COMP_PROP_SELECTED_INC,found_include);
   _SetDialogInfo(COMP_PROP_MODIFIED, true);

   update_config_properties();

   p_window_id=ctl_include_directories;
}

void ctlMoveUserIncludesUp.lbutton_up()
{
   move_inc_up();
}

void ctlMoveUserIncludesUp.lbutton_double_click()
{
}

void ctlMoveUserIncludesUp.lbutton_triple_click()
{
}

void ctlMoveUserIncludesDown.lbutton_up()
{
   move_inc_down();
}

void ctlMoveUserIncludesDown.lbutton_double_click()
{
}

void ctlMoveUserIncludesDown.lbutton_triple_click()
{
}

void ctl_delete.lbutton_up()
{
   remove_inc();
}

void ctl_delete.lbutton_double_click()
{
}

void ctl_delete.lbutton_triple_click()
{
}

void ctl_refresh_includes.lbutton_up()
{
   CompilerConfiguration configs[]=_GetDialogInfo(COMP_PROP_ALL_CONFIGS);
   int config_index=_GetDialogInfo(COMP_PROP_SELECTED_CONFIG);
   _str include_path = _get_vs_sys_includes(configs[config_index].configuarationName);

   if (include_path != '') {
      configs[config_index].systemIncludes._makeempty();

      _str directory;

      while (include_path!='') {
         parse include_path with directory (PARSE_PATHSEP_RE),'r' include_path;
         configs[config_index].systemIncludes[configs[config_index].systemIncludes._length()]=directory;
      }
      _SetDialogInfo(COMP_PROP_ALL_CONFIGS,configs);
      _SetDialogInfo(COMP_PROP_MODIFIED, true);
      update_config_properties();
   }
}

static _str prompt_for_new_compiler_name()
{
   // prompt for name, check for duplicate, and add to list
   newName := "";
   _str promptResult = show("-modal _textbox_form",
                            "Enter the name for the new configuration",
                            0,
                            "",
                            "",
                            "",
                            "",
                            "Configuration name:" "" );
   if (promptResult == "") {
      // user cancelled operation
      return '';
   }

   return _param1;
}

static void get_new_compiler_name()
{
   newName := prompt_for_new_compiler_name();
   if (newName == "") {
      // user cancelled operation
      return;
   }

   // Check for duplicate
   CompilerConfiguration configs[]=_GetDialogInfo(COMP_PROP_ALL_CONFIGS);
   if ( find_compiler_configuration_index( configs, newName ) != -1 ) {
      _message_box("Error: Configuration name \"" newName "\" already exists");
      return;
   }

   config_index := configs._length();
   configs[config_index].configuarationName=newName;
   configs[config_index].systemHeader='';
   configs[config_index].systemIncludes._makeempty();

   _SetDialogInfo(COMP_PROP_ALL_CONFIGS,configs);
   _SetDialogInfo(COMP_PROP_SELECTED_CONFIG,config_index);
   _SetDialogInfo(COMP_PROP_SELECTED_INC,0);
   _SetDialogInfo(COMP_PROP_MODIFIED, true);

   update_config_list();
}

/**
 * Used to show the refactoring options menu set to a particuar configuration
 * without changing the active configuration
 */
void _refactor_set_config(_str compiler_name)
{
   CompilerConfiguration configs[]=_GetDialogInfo(COMP_PROP_ALL_CONFIGS);
   config_index := find_compiler_configuration_index(configs,compiler_name);

   if (config_index>=0) {
      ctl_compiler_name.p_line = config_index + 1;
      ctl_compiler_name._lbselect_line();
   }
}

/**
 * Check the validity of a C identifier
 *
 * @param id_name Parameter to check validity of
 *
 * @return true if id_name is a valid C identifier
 */
bool refactor_c_is_valid_id( _str id_name )
{
   return(pos("^:v$",id_name,1,'r')!=0);
}

///////////////////////////////////////////////////////////////////////////////
/**
 * Form used for the local to field refactoring.
 * Currently allows the user to set the field name and the access modifier.
 */
defeventtab _refactor_local_to_field_form;
static int FORMATFLAGS(...) {
   if (arg()) ctl_button_ok.p_user=arg(1);
   return ctl_button_ok.p_user;
}
void ctl_button_cancel.lbutton_up()
{
   p_active_form._delete_window(COMMAND_CANCELLED_RC);
}
void ctl_button_ok.lbutton_up()
{
   if ( !refactor_c_is_valid_id(ctl_text_field_name.p_text) ) {
      ctl_text_field_name._text_box_error("Field name needs to be a valid identifier");
      return;
   }

   int nFlags = FORMATFLAGS();
   if ( ctl_radio_public.p_value == 1 ) {
      nFlags |= VSREFACTOR_ACCESS_PUBLIC;
   }
   if ( ctl_radio_protected.p_value == 1 ) {
      nFlags |= VSREFACTOR_ACCESS_PROTECTED;
   }
   if ( ctl_radio_private.p_value == 1 ) {
      nFlags |= VSREFACTOR_ACCESS_PRIVATE;
   }

   _param1 = ctl_text_field_name.p_text;
   _param2 = nFlags;

   //refactor_local_to_field_symbol(ctl_button_ok.p_user, ctl_text_field_name.p_text, nFlags);
   p_active_form._delete_window();
}
void _refactor_local_to_field_form.on_create( _str strName="", int nFormatFlags=0 )
{
   //ctl_button_ok.p_user = cm;
   //gRefactorBrowseInfo = cm;
   FORMATFLAGS(nFormatFlags);
   ctl_text_field_name.p_text = "m_" strName;
}

///////////////////////////////////////////////////////////////////////////////
/**
 * Form used for the local to field refactoring.
 * Currently allows the user to set the field name and the access modifier.
 */
static _str _rfct_classIdHash:[];

defeventtab _refactor_global_to_field_form;
void ctl_combo_classes.on_create()
{
   //say("ctl_combo_classes.on_create:");
   ctl_combo_classes.p_text="";

   sClass := "";
   int  nStatus = tag_find_class(sClass);
   while ( !nStatus ) {
      nClassId := -1;
      sType := "";
      int status = tag_get_class_detail(sClass, VS_TAGDETAIL_type, sType);
      if ( !status ) {
         status = tag_find_in_class(sClass);
         if ( !status ) {
            tag_get_detail(VS_TAGDETAIL_class_id, nClassId);
            //say("class_id="nClassId" class="sClass);
         }
      }

      if ( nClassId >= 0 && (sType == "class" || sType == "struct") ) {
         cpp_class_name := tag_name_to_cpp_name(sClass);
         if ( !_rfct_classIdHash._indexin(cpp_class_name) ) {
            // don't add anonymous classes/struct/unions
            if ( pos('@', cpp_class_name) == 0 ) {
               _rfct_classIdHash:[cpp_class_name] = sClass;//nClassId;
               _lbadd_item(cpp_class_name);
            }
         }
      } /*else {
         say("FAILED TO ADD: class<"sClass"> type{"sType"} classID["nClassId"]");
      }*/
      nStatus = tag_next_class(sClass);
   }
   tag_reset_find_class();
   tag_reset_find_in_class();
   _lbsort();
   _lbtop();_lbselect_line();
   ctl_combo_classes._retrieve_value();
}
void _refactor_global_to_field_form.on_load()
{
   p_window_id=ctl_combo_classes;
}
void ctl_button_cancel.lbutton_up()
{
   _rfct_classIdHash._makeempty();
   p_active_form._delete_window(COMMAND_CANCELLED_RC);
}
void ctl_button_ok.lbutton_up()
{
   if ( !refactor_c_is_valid_id(ctl_text_field_name.p_text) ) {
      ctl_text_field_name._text_box_error("Field name needs to be a valid identifier");
      return;
   }

   orig_wid := p_window_id;
   typeless nStatus = ctl_combo_classes._cbi_search("", "$");
   if ( nStatus ) {
      _message_box("Combo box contains invalid input.");
      ctl_combo_classes._set_focus();
      return;
   }

   _append_retrieve(ctl_combo_classes, ctl_combo_classes.p_text);

   int nFlags = FORMATFLAGS();
   if ( ctl_radio_public.p_value == 1 ) {
      nFlags |= VSREFACTOR_ACCESS_PUBLIC;
   }
   if ( ctl_radio_protected.p_value == 1 ) {
      nFlags |= VSREFACTOR_ACCESS_PROTECTED;
   }
   if ( ctl_radio_private.p_value == 1 ) {
      nFlags |= VSREFACTOR_ACCESS_PRIVATE;
   }

   _param1 = ctl_text_field_name.p_text;
   _param2 = nFlags;
   _param3 = ctl_combo_classes.p_text;
   _param4 = _rfct_classIdHash:[_param3];

   _rfct_classIdHash._makeempty();
   p_active_form._delete_window();
}
void _refactor_global_to_field_form.on_create( _str strName="", int nFormatFlags=0 )
{
   FORMATFLAGS(nFormatFlags);
   ctl_text_field_name.p_text = strName;
}

///////////////////////////////////////////////////////////////////////////////
/**
 * Forms used for the move method refactoring.
 * Currently allows the user to select the class to move the method to and the
 * access modifier of the moved method.
 */
defeventtab _refactor_move_static_method_form;

static _str MM_FILENAME(...) {
   if (arg()) ctl_radio_private.p_user=arg(1);
   return ctl_radio_private.p_user;
}
static _str MM_CLASSNAME(...) {
   if (arg()) ctl_label_method_name.p_user=arg(1);
   return ctl_label_method_name.p_user;
}
static _str MM_METHODNAME(...) {
   if (arg()) ctl_text_method_name.p_user=arg(1);
   return ctl_text_method_name.p_user;
}
static int MM_TRANSHANDLE(...) {
   if (arg()) ctl_button_ok.p_user=arg(1);
   return ctl_button_ok.p_user;
}

void ctl_combo_classes.on_create()
{
   //say("ctl_combo_classes.on_create:");
   ctl_combo_classes.p_text="";

   sClass := "";
   int  nStatus = tag_find_class(sClass);
   while ( !nStatus ) {
      nClassId := -1;
      sType := "";
      int status = tag_get_class_detail(sClass, VS_TAGDETAIL_type, sType);
      if ( !status ) {
         status = tag_find_in_class(sClass);
         if ( !status ) {
            tag_get_detail(VS_TAGDETAIL_class_id, nClassId);
            //say("class_id="nClassId" class="sClass);
         }
      }

      if ( nClassId >= 0 && (sType == "class" || sType == "struct") ) {
         cpp_class_name := tag_name_to_cpp_name(sClass);
         if ( !_rfct_classIdHash._indexin(cpp_class_name) ) {
            // don't add anonymous classes/struct/unions
            if ( pos('@', cpp_class_name) == 0 ) {
               _rfct_classIdHash:[cpp_class_name] = sClass;//nClassId;
               _lbadd_item(cpp_class_name);
            }
         }
      } /*else {
         say("FAILED TO ADD: class<"sClass"> type{"sType"} classID["nClassId"]");
      }*/
      nStatus = tag_next_class(sClass);
   }
   tag_reset_find_class();
   tag_reset_find_in_class();
   _lbsort();
   _lbtop();_lbselect_line();
   ctl_combo_classes._retrieve_value();
}
void _refactor_move_static_method_form.on_load()
{
   p_window_id=ctl_combo_classes;
}
void ctl_button_cancel.lbutton_up()
{
   _rfct_classIdHash._makeempty();
   p_active_form._delete_window(COMMAND_CANCELLED_RC);
}
void ctl_button_ok.lbutton_up()
{
   if ( !refactor_c_is_valid_id(ctl_text_method_name.p_text) ) {
      ctl_text_method_name._text_box_error("Method name needs to be a valid identifier");
      return;
   }

   orig_wid := p_window_id;
   typeless nStatus = ctl_combo_classes._cbi_search("", "$");
   if ( nStatus ) {
      _message_box("Combo box contains invalid input.");
      ctl_combo_classes._set_focus();
      return;
   }

   _append_retrieve(ctl_combo_classes, ctl_combo_classes.p_text);

   int nFlags = FORMATFLAGS();
   if ( ctl_radio_public.p_value == 1 ) {
      nFlags |= VSREFACTOR_ACCESS_PUBLIC;
   }
   if ( ctl_radio_protected.p_value == 1 ) {
      nFlags |= VSREFACTOR_ACCESS_PROTECTED;
   }
   if ( ctl_radio_private.p_value == 1 ) {
      nFlags |= VSREFACTOR_ACCESS_PRIVATE;
   }

   _param1 = ctl_text_method_name.p_text;
   _param2 = nFlags;
   _param3 = ctl_combo_classes.p_text;
   _param4 = _rfct_classIdHash:[_param3];

   _rfct_classIdHash._makeempty();
   p_active_form._delete_window();
}
void _refactor_move_static_method_form.on_create( _str strName="", int nMethodFlags=0, int nFormatFlags=0 )
{
   if ( (nMethodFlags & SE_TAG_FLAG_ACCESS) == SE_TAG_FLAG_PUBLIC ) {
      ctl_radio_public.p_value     = 1;
      ctl_radio_protected.p_value  = 0;
      ctl_radio_private.p_value    = 0;
   } else if ( (nMethodFlags & SE_TAG_FLAG_ACCESS) == SE_TAG_FLAG_PROTECTED ) {
      ctl_radio_public.p_value     = 0;
      ctl_radio_protected.p_value  = 1;
      ctl_radio_private.p_value    = 0;
   } else if ( (nMethodFlags & SE_TAG_FLAG_ACCESS) == SE_TAG_FLAG_PRIVATE ) {
      ctl_radio_public.p_value     = 0;
      ctl_radio_protected.p_value  = 0;
      ctl_radio_private.p_value    = 1;
   }

   FORMATFLAGS(nFormatFlags);
   ctl_text_method_name.p_text = strName;
}

defeventtab _refactor_move_method_form;
void ctl_tree_receivers.on_create()
{
   if ( MM_FILENAME() == "" )
      return;

   show_cancel_form("Searching for delegates...", "", true, true);

   // set up tree column info
   _TreeSetColButtonInfo(0, p_width intdiv 2, 0, 0, "Delegate");
   _TreeSetColButtonInfo(1, p_width intdiv 2, 0, 0, "References");
   _TreeSetColButtonInfo(2, p_width intdiv 2, 0, 0, "Class");
   _TreeSetColEditStyle(1,TREE_EDIT_TEXTBOX);
   _TreeSetColEditStyle(2,TREE_EDIT_TEXTBOX);

   // begin the refactoring transaction
   nHandle := refactor_begin_transaction(/*"Move Method"*/);
   if ( nHandle < 0 ) {
      _message_box("Failed creating refactoring transaction:  ":+get_message(nHandle));
      p_active_form._delete_window(COMMAND_CANCELLED_RC);
      return;
   }

   int nStatus = refactor_add_project_file(nHandle, MM_FILENAME());
   if ( nStatus < 0 ) {
      close_cancel_form(cancel_form_wid());
      refactor_cancel_transaction(nHandle);
      p_active_form._delete_window(COMMAND_CANCELLED_RC);
      return;
   }
   nStatus = refactor_c_move_method_find_delegates(nHandle, MM_METHODNAME(), MM_CLASSNAME());
   if ( nStatus == COMMAND_CANCELLED_RC ) {
      close_cancel_form(cancel_form_wid());
      refactor_cancel_transaction(nHandle);
      p_active_form._delete_window(COMMAND_CANCELLED_RC);
      return;
   }
   if ( nStatus < 0 ) {
      close_cancel_form(cancel_form_wid());
      _message_box("Failed to find delegates: ":+get_message(nStatus));
      refactor_cancel_transaction(nHandle);
      p_active_form._delete_window(COMMAND_CANCELLED_RC);
      return;
   }
   int nReceivers = refactor_c_move_method_num_delegates(nHandle);
   //say("NumReceivers = "nReceivers);
   int r;
   for ( r = 0; r < nReceivers; ++r ) {
      sDelegate := sDelegateClass := "";
      nType := nAccess := nReferences := 0;
      nStatus = refactor_c_move_method_get_delegate(nHandle, r, sDelegate, sDelegateClass, nType, nAccess, nReferences);
      if ( nStatus < 0 ) {
         //say("refactor_c_move_method_get_delegate["r"] FAILED":+get_message(nStatus));
         continue;
      }

      sDelegateClassCpp := tag_name_to_cpp_name(sDelegateClass);
      sTreeItem := ' 'sDelegate"\t"nReferences"\t"sDelegateClassCpp;
      tag_flags := (nAccess == VSREFACTOR_ACCESS_PUBLIC)? SE_TAG_FLAG_PUBLIC : ((nAccess == VSREFACTOR_ACCESS_PROTECTED)? SE_TAG_FLAG_PROTECTED : SE_TAG_FLAG_PRIVATE);
      tag_type  := (nType == 0)? SE_TAG_TYPE_PARAMETER : SE_TAG_TYPE_VAR;
      pic_cb := tag_get_bitmap_for_type(tag_type,tag_flags,auto pic_overlay);
      _TreeAddItem(TREE_ROOT_INDEX, sTreeItem, TREE_ADD_AS_CHILD|TREE_OVERLAY_BITMAP1, pic_overlay, pic_cb, -1, 0, sDelegateClass);
   }
   close_cancel_form(cancel_form_wid());

   //refactor_cancel_transaction(nHandle);
   MM_TRANSHANDLE(nHandle);

   // adjust the tree column widths
   _TreeAdjustColumnWidths(0);
   _TreeAdjustColumnWidths(1);
}
void ctl_button_cancel.lbutton_up()
{
   _rfct_classIdHash._makeempty();
   p_active_form._delete_window(COMMAND_CANCELLED_RC);
}
void ctl_button_ok.lbutton_up()
{
   if ( !refactor_c_is_valid_id(ctl_text_method_name.p_text) ) {
      ctl_text_method_name._text_box_error("Method name needs to be a valid identifier");
      return;
   }

   nTreeIdx := ctl_tree_receivers._TreeCurIndex();
   if ( nTreeIdx <= 0 ) {
      return;
   }

   _str sReceiver = ctl_tree_receivers._TreeGetUserInfo(nTreeIdx);
   int nFlags = FORMATFLAGS();
   if ( ctl_radio_public.p_value == 1 ) {
      nFlags |= VSREFACTOR_ACCESS_PUBLIC;
   }
   if ( ctl_radio_protected.p_value == 1 ) {
      nFlags |= VSREFACTOR_ACCESS_PROTECTED;
   }
   if ( ctl_radio_private.p_value == 1 ) {
      nFlags |= VSREFACTOR_ACCESS_PRIVATE;
   }

   _param1 = ctl_text_method_name.p_text;
   _param2 = nFlags;
   _param3 = nTreeIdx-1;
   _param4 = sReceiver;
   _param5 = MM_TRANSHANDLE();

   p_active_form._delete_window();
}
int _refactor_move_method_form.on_create( struct VS_TAG_BROWSE_INFO cm = null, _str strName="", int nFormatFlags=0 )
{
   if ( cm != null ) {
      if ( (cm.flags & SE_TAG_FLAG_ACCESS) == SE_TAG_FLAG_PUBLIC ) {
         ctl_radio_public.p_value     = 1;
         ctl_radio_protected.p_value  = 0;
         ctl_radio_private.p_value    = 0;
      } else if ( (cm.flags & SE_TAG_FLAG_ACCESS) == SE_TAG_FLAG_PROTECTED ) {
         ctl_radio_public.p_value     = 0;
         ctl_radio_protected.p_value  = 1;
         ctl_radio_private.p_value    = 0;
      } else if ( (cm.flags & SE_TAG_FLAG_ACCESS) == SE_TAG_FLAG_PRIVATE ) {
         ctl_radio_public.p_value     = 0;
         ctl_radio_protected.p_value  = 0;
         ctl_radio_private.p_value    = 1;
      }
      MM_FILENAME(cm.file_name);
      MM_CLASSNAME(tag_name_to_cpp_name(cm.class_name));
      MM_METHODNAME(cm.member_name);
   } else {
      MM_FILENAME("");
      MM_CLASSNAME("");
      MM_METHODNAME("");
   }

   FORMATFLAGS(nFormatFlags);
   ctl_text_method_name.p_text = strName;
   return 0;
}

///////////////////////////////////////////////////////////////////////////////
/**
 * Form used for the encapsulate field refactoring.
 * Currently allows the user to set the names of the getter and setter functions
 */
//#define BROWSEINFO               ctl_ok.p_user
//#define CLASS_NAME_ARRAY         ctl_ok.p_user2
//#define CLASS_FILE_ARRAY         ctl_cancel.p_user
//#define CLASS_SEEK_POS_ARRAY     ctl_cancel.p_user2
//#define SYMBOL_NAME_ENCAP        ctl_getter_name.p_user
//#define ENCAP_FORMATTING_FLAGS   ctl_getter_name.p_user2
//#define ENCAP_SYNTAX_INDENT      ctl_setter_name.p_user
//#define ENCAP_HANDLE             ctl_setter_name.p_user2

defeventtab _refactor_encapsulate_field_form;

void ctl_ok.on_create( int handle, _str symbolName, _str class_methods[])
{
//   ENCAP_HANDLE = handle;
//   BROWSEINFO = cm;
//   SYMBOL_NAME_ENCAP = symbolName;
//   ENCAP_FORMATTING_FLAGS = formattingFlags;
//   ENCAP_SYNTAX_INDENT = syntaxIndent;

   _str strippedName = symbolName;

   // Strip off any leading _ and stick in strippedName
   if ( ( substr( strippedName, 1, 1 ) == '_' ) ) {
      strippedName = substr( strippedName, 2 );
   }

   // Strip off any leading m_ and stick in strippedName
   if ( ( substr( strippedName, 1, 1 ) == 'm' ) &&
       ( substr( strippedName, 2, 1 ) == '_' ) ) {
      strippedName = substr( strippedName, 3 );
   }

   // Make first character in strippedName uppercase
   _str functionName;
   functionName = substr( strippedName,1,1);
   functionName = upcase( functionName );
   functionName :+= substr( strippedName, 2 );

   // Make default getter and setter names
   getterName := 'get' functionName;
   setterName := 'set' functionName;

   ctl_getter_name.p_text = getterName;
   ctl_setter_name.p_text = setterName;

   int i;
   s := "As first public method";

   ctl_insert_after._lbadd_item( s );

   for (i = 0; i < class_methods._length(); i++) {
      ctl_insert_after._lbadd_item(class_methods[i]);
   }
//   for ( i = 0 ; i < refactor_c_get_num_class_methods( handle ) ; i++ ) {
//      _str name = '';
//      refactor_c_get_class_method( handle, i, name );
//      ctl_insert_after.p_cb_list_box._lbadd_item( name );
//   }

   ctl_insert_after._lbtop();
   ctl_insert_after._lbfind_and_select_item( s );
}

void ctl_cancel.lbutton_up()
{
   p_active_form._delete_window('');
}

void ctl_ok.lbutton_up()
{
   _str getterName,setterName,methodName;

   getterName = ctl_getter_name.p_text;
   if ( !refactor_c_is_valid_id(getterName) ) {
      ctl_getter_name._text_box_error("Function name needs to be a valid identifier");
      return;
   }

   setterName = ctl_setter_name.p_text;
   if ( !refactor_c_is_valid_id(setterName) ) {
      ctl_setter_name._text_box_error("Function name needs to be a valid identifier");
      return;
   }
   methodName = ctl_insert_after.p_text;

   p_active_form._delete_window( getterName :+ PATHSEP :+ setterName :+ PATHSEP :+ methodName );
}

///////////////////////////////////////////////////////////////////////////////
/**
 * Form used for the move field refactoring.
 * Currently allows the user to pick a class in the current compilation unit to move the field to.
 */

defeventtab _refactor_replace_literal_form;

// Name of literal to replace with constant
static _str RF_LITERAL(...) {
   if (arg()) ctl_radio_const.p_user=arg(1);
   return ctl_radio_const.p_user;
}

void ctl_ok.lbutton_up()
{
   int flags;

   if ( ctl_radio_const.p_value ) {
      flags = VSREFACTOR_DEFTYPE_CONSTANT;
   } else if ( ctl_radio_static_const.p_value ) {
      flags = VSREFACTOR_DEFTYPE_STATIC;
   } else {
      flags = VSREFACTOR_DEFTYPE_DEFINE;
   }

   p_window_id.p_active_form._delete_window( ctl_constant_name.p_text :+ PATHSEP :+ flags );
}

void ctl_cancel.lbutton_up()
{
   p_active_form._delete_window('');
}

/**
 * Creates the replace literal dialog
 * 
 * @param filename         
 * @param literalName
 * @param extension
 */
void ctl_ok.on_create(_str filename, _str literal, _str lang="", bool quick_refactor=false)
{
   RF_LITERAL(literal);

   // update the help link for quick refactorings
   if (quick_refactor) {
      p_active_form.p_help="Replace literal with constant (Quick Refactoring)";
   }

   ctl_constant_name.p_text = "aConstant";
   ctl_operation_description.p_caption = getOperationDescription(literal, "aConstant");
   if (_LanguageInheritsFrom('java',lang)) {
      ctl_radio_define.p_enabled = false;
   } else {
      ctl_radio_define.p_enabled = true;
   }
}

static _str getOperationDescription( _str literalName, _str constantName )
{
   description := "literal: ";
   strappend( description, literalName );

   len := length(literalName);

   if ( len > 30 ) {
      choppedName := substr( description, 1, 45 );
      strappend( choppedName, "..." );
      description = choppedName;
   }
   return description;
}

ctl_constant_name.on_change()
{
   ctl_operation_description.p_caption = getOperationDescription(RF_LITERAL(), p_text);
}

///////////////////////////////////////////////////////////////////////////////
/**
 * Form used for the move field refactoring.
 * Currently allows the user to pick a class in the current compilation unit to move the field to.
 */

defeventtab _refactor_move_field_form;
static VS_TAG_BROWSE_INFO BROWSEINFO(...) {
   if (arg()) ctl_ok.p_user=arg(1);
   return ctl_ok.p_user;
}
// Symbol Name for Move Field form
static _str SYMBOL_NAME(...) {
   if (arg()) ctl_operation_description.p_user=arg(1);
   return ctl_operation_description.p_user;
}
// Class Name for Move Field form
static _str CLASS_NAME(...) {
   if (arg()) ctl_operation_description.p_user2=arg(1);
   return ctl_operation_description.p_user2;
}
// File that this class is in
static _str CLASS_FILE_NAME(...) {
   if (arg()) ctl_class_list.p_user=arg(1);
   return ctl_class_list.p_user;
}
// File that this class is in
static _str CLASS_DEF_FILE_NAME(...) {
   if (arg()) ctl_class_list.p_user2=arg(1);
   return ctl_class_list.p_user2;
}
// File that this class is in
static _str CLASS_DEF_FILE_DIR(...) {
   if (arg()) ctl_browse_button.p_user=arg(1);
   return ctl_browse_button.p_user;
}

void ctl_ok.lbutton_up()
{
   CLASS_DEF_FILE_NAME(absolute(ctl_class_definition_cpp.p_text));

   if ( CLASS_FILE_NAME() == "" ) {
       _message_box("You must choose a class to move the field to");
       return;
    }

   if ( !file_exists( CLASS_DEF_FILE_NAME() ) ) {
       _message_box("You must choose an existing source file to move the static field definition to.");
       return;
    }

   p_active_form._delete_window( CLASS_NAME() :+ PATHSEP :+ CLASS_FILE_NAME() :+ PATHSEP :+ CLASS_DEF_FILE_NAME() );
}

void ctl_cancel.lbutton_up()
{
   p_active_form._delete_window("");
}

void ctl_class_list.on_change(int reason)
{
   _str tag_name='', class_to_move_to='', inner_class='', type_name='', tag_file_name='', class_name='',
      signature='', return_type='', arguments='', tag_file='';
   i := tag_flags := line_no := 0;

   class_to_move_to = _lbget_seltext();

   struct VS_TAG_BROWSE_INFO cm = BROWSEINFO();
   _str lang = _isEditorCtl()? p_LangId : _Filename2LangId(cm.file_name);
   _str tag_files[] = tags_filenamea( lang );

   _str file_name = tagGetClassFilename( tag_files, class_to_move_to, inner_class, 'c' );

   CLASS_NAME(class_to_move_to);
   CLASS_FILE_NAME(file_name);

   _str defFileName = find_class_definition_file(_form_parent(), class_to_move_to, lang);

   // Look for this cpp. If not found then blank out def file name
   if ( file_exists( defFileName ) ) {
      CLASS_DEF_FILE_NAME(defFileName);
   } else {
      CLASS_DEF_FILE_NAME(file_name);
   }

   CLASS_DEF_FILE_DIR(_strip_filename(CLASS_DEF_FILE_NAME(), 'N'));

   txt := "Move '";

   strappend( txt, SYMBOL_NAME() );
   strappend( txt, "' to class '" );
   strappend( txt, CLASS_NAME() );
   strappend( txt, "'" );

   CLASS_NAME(inner_class);

   // If CLASS_FILE_NAME() is a header file then
   // build a string of the equivalent cpp file in the same directory.
   // See if it exists. If not allow user to choose a new one
   // If blank then don't move static member declaration into a new file
   ctl_class_definition_cpp.p_text = _strip_filename( CLASS_DEF_FILE_NAME(), 'P' );
   ctl_operation_description.p_caption = txt;
}

void ctl_ok.on_create( _str symbolName, struct VS_TAG_BROWSE_INFO cm )
{
   // Get the tag file for the current project or current workspace
   status := 0;
   tag_files := project_tags_filenamea();
   foreach (auto project_tagfile in tag_files) {

      status = tag_read_db(project_tagfile);
      if ( status < 0 ) continue;

      class_name := "";
      if ( tag_find_class( class_name ) == 0 ) {

         // Ignore nameless unions and java packages
         if ( ( pos( "@", class_name ) == 0 ) && ( pos( ".", class_name ) == 0 ) ) {
            ctl_class_list._lbadd_item( class_name );
         }

         while ( tag_next_class( class_name ) == 0  ) {
            // Ignore nameless unions and java packages
            if ( ( pos( "@", class_name ) == 0 ) && ( pos( ".", class_name ) == 0 ) ) {
               ctl_class_list._lbadd_item( class_name );
            }
         }
      }

      tag_reset_find_class();
   }

   ctl_class_list._lbsort();
   SYMBOL_NAME(symbolName);
   BROWSEINFO(cm);

   _refactor_move_field_form_initial_alignment();
}

void ctl_class_definition_cpp.on_change()
{
   filename := absolute(p_text);
   if ( file_exists(filename) ) {
      CLASS_DEF_FILE_NAME(filename);
      CLASS_DEF_FILE_DIR(_strip_filename( filename, 'N' ));
   }
}

void ctl_browse_button.lbutton_up()
{
   wid := p_window_id;

   result := _OpenDialog('-modal',
                          'Select cpp to insert static member declaration', // Title
                          '*.*',                                          // Wild Cards
                          '*.*',                                          // File Filters
                          OFN_FILEMUSTEXIST,                                // OFN flags
                          '.cpp',                                           // Default extension
                          _strip_filename( CLASS_DEF_FILE_NAME(), 'P' ),       // Initial name
                          CLASS_DEF_FILE_DIR()                                // Initial directory
                         );

   if ( result=='' ) {
      return;
   }
   result=strip(result,'B','"');

   p_window_id=wid.p_prev;
   ctl_class_definition_cpp.p_text=_strip_filename( result, 'P' );
   CLASS_DEF_FILE_NAME(result);
   CLASS_DEF_FILE_DIR(_strip_filename( result, 'N' ));
   return;
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _refactor_move_field_form_initial_alignment()
{
   // size the buttons to the textbox
   sizeBrowseButtonToTextBox(ctl_class_definition_cpp.p_window_id, 
                             ctl_browse_button.p_window_id, 0,
                             ctl_class_list.p_x_extent);
}

///////////////////////////////////////////////////////////////////////////////
/**
 * Form used for displaying options for creating extracted method parameter list
 */
defeventtab _refactor_extract_method_form;

static const NO_COMMENT=            0;
static const JAVADOC_COMMENT=       1;
static const XMLDOC_COMMENT=        2;

/**
 * Create a parameter declaration for constructing the prototype
 *
 * @param index   index of parameter to create
 */
static _str em_make_parameter(int index) {
   caption := ctl_parameter_list._TreeGetCaption(index);
   _str return_type,name,array_string;
   parse caption with . "\t" return_type "\t" name "\t" array_string;
   return_type = stranslate(return_type, "\1", "&");
   return_type = stranslate(return_type, "&&", "\1");
   return return_type' 'name;
}
/**
 * Create the function prototype string to update
 * the prototype preview label
 */
static _str em_make_prototype()
{
   numParams := 0;
   _str result = ctl_name.p_user;
   result :+= ' ' :+ ctl_name.p_text :+ '( ';
   index := ctl_parameter_list._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (index > 0) {
      checked := ctl_parameter_list._TreeGetCheckState(index);
      if (checked != TCB_UNCHECKED) {
         if (numParams++ >= 1) result :+= ', ';
         result :+= em_make_parameter(index);
      }
      index = ctl_parameter_list._TreeGetNextSiblingIndex(index);
   }
   result :+= ' );';
   return result;
}

static void em_update_extract_method_info(EXTRACT_METHOD_INFO &info)
{
   info.params._makeempty();
   index := ctl_parameter_list._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (index > 0) {
      // Get parameter information associated with this treenode
      VS_TAG_LOCAL_INFO local_info = ctl_parameter_list._TreeGetUserInfo(index);

      // Update the parameter information with the caption infor for this treenode
      caption := ctl_parameter_list._TreeGetCaption(index);
      parse caption with . "\t" . "\t" local_info.new_name "\t" .;

      // Get the parameter array in sync with the tree ordering.
      // Only stick checked parameters into new list
      checked := ctl_parameter_list._TreeGetCheckState(index);
      if (checked != TCB_UNCHECKED) {
         info.params[info.params._length()] = local_info;
      }

      index = ctl_parameter_list._TreeGetNextSiblingIndex(index);
   }
}

static void em_update_caption()
{
   // Get the data in sync with the table
   if (gMethodInfo == null) {
      ctl_prototype.p_caption = em_make_prototype();
      return;
   }

   em_update_extract_method_info(gMethodInfo);

   _str caption = build_prototype_string(ctl_name.p_text, gMethodInfo.function_cm,
         gMethodInfo.params, gMethodInfo.return_type);

   caption = stranslate(caption, "\1", "&");
   caption = stranslate(caption, "&&", "\1");

   // Build the prototype
   ctl_prototype.p_caption = caption;
}

/**
 * Close or cancel the form without saving
 */
void ctl_cancel.lbutton_up()
{
   p_active_form._delete_window('');
}

static int getCommentType()
{
   // what kind of comment did we pick?
   comment_type := NO_COMMENT;
   if (ctl_javadoc_comment.p_value) {
      comment_type = JAVADOC_COMMENT;
   } else if (ctl_xmldoc_comment.p_value) {
      comment_type = XMLDOC_COMMENT;
   }

   return comment_type;
}

/**
 * Saves the value of "Generate comment for extracted method" radio buttons.
 */
void _refactor_extract_method_form.on_destroy()
{
   comment_type := getCommentType();
   ctl_no_comment._append_retrieve(0, comment_type, '_refactor_extract_method_form.ctl_no_comment');
}

/**
 * Create the form and populate it with the given data
 * <p>
 * User info is used on the following controls:
 * <ul>
 * <li>ctl_name -- return type of function
 * <li>ctl_replace -- status < 0 if we cannot replace with a function call
 * <li>ctl_parameter_list -- each item has user info containing it's original name
 * </ul>
 * <p>
 * Each argument is of the form:
 * <pre>
 *    name [tab] return_type [tab] reference [tab] required [newline]
 * </pre>
 *
 * @param method_name      name of extracted method
 * @param return_type      return type of extracted method
 * @param arguments        method arguments, separated by NEWLINE characters
 * @param status           status with respect to replacing function call
 */
void ctl_ok.on_create(_str method_name='', _str return_type='', _str arguments='', int replace_status=0, 
                  bool beautify_enabled=false, bool javadoc_enabled=false, bool xmldoc_enabled=false,
                  _str lang='', EXTRACT_METHOD_INFO method_info=null)
{
   _refactor_extract_method_form_initial_alignment();

   // Make sure this is set before any dialog components are touched.
   gMethodInfo = method_info;

   // set up tree column info
   ctl_parameter_list._TreeSetColButtonInfo(0, 200, 0, 0, "Keep");
   ctl_parameter_list._TreeSetColButtonInfo(1, ctl_parameter_list.p_width intdiv 2, 0, 0, "Type");
   ctl_parameter_list._TreeSetColButtonInfo(2, ctl_parameter_list.p_width intdiv 2, 0, 0, "Argument Name");
   ctl_parameter_list._TreeSetColEditStyle(2,TREE_EDIT_TEXTBOX);

   // adjust help topics if this is quick refactoring
   if (beautify_enabled) {
      p_active_form.p_help="Extract Method (Quick Refactoring)";
   }

   // save method name, return type, and status
   ctl_name.p_text=method_name;
   ctl_name.p_user=return_type;
   ctl_replace.p_user=replace_status;
   ctl_replace.p_value=(int)(replace_status>0);

   // hide the beautify and Javadoc and XMLDoc options if
   // they are not enabled.
   if (!beautify_enabled && !javadoc_enabled && !xmldoc_enabled) {
      int delta = ctl_parameter_list.p_y-ctl_beautify.p_y;
      ctl_parameter_list.p_y -= delta;
      ctl_parameter_list.p_height += delta;
      ctl_rename.p_y -= delta;
      ctl_move_parameter_up.p_y -= delta;
      ctl_move_parameter_down.p_y -= delta;
      ctl_beautify.p_visible = false;
      ctl_beautify.p_visible = false;
      ctlframe1.p_visible = false;
   }

   if (beautify_enabled == false) {
      ctl_beautify.p_enabled = false;
   } else {
      ctl_beautify.p_value = 1;
   }

   if (javadoc_enabled == false) {
      ctl_javadoc_comment.p_enabled = false;
   } 

   if (xmldoc_enabled == false) {
      ctl_xmldoc_comment.p_enabled = false;
   } 

   comment_type := ctl_no_comment._retrieve_value();
   if (comment_type != null && isinteger(comment_type)) {
      if (ctl_xmldoc_comment.p_enabled && comment_type == XMLDOC_COMMENT) {
         ctl_xmldoc_comment.p_value = 1;
      } else if (ctl_javadoc_comment.p_enabled && comment_type == JAVADOC_COMMENT) {
         ctl_javadoc_comment.p_value = 1;
      } else {
         ctl_no_comment.p_value = 1;
      }
   } else {
      // By default select xmldoc for cs and javadoc for everything if they are supported.
      if (ctl_xmldoc_comment.p_enabled && _LanguageInheritsFrom('cs',lang)) {
      } else if (ctl_javadoc_comment.p_enabled){
         ctl_javadoc_comment.p_value = 1;
      } else {
         ctl_no_comment.p_value = 1;
      }
   }

   // insert each argument the user
   index := 0;
   while (arguments != '') {
      line := "";
      parse arguments with line "\n" arguments;
      if (line != '') {
         name := reference := required := array_string := "";
         parse line with name "\t" return_type "\t" reference "\t" required "\t" array_string;
         line = "\t"return_type' 'reference"\t"name"\t"array_string;
         checked := (required != '')? TCB_CHECKED : TCB_UNCHECKED;
         typeless userInfo = (gMethodInfo != null)? method_info.params[index] : (typeless) name; 
         nodeIndex := ctl_parameter_list._TreeAddItem(TREE_ROOT_INDEX, line, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF, 0, userInfo);
         // allow any parameter to be taken out.  
         // Note this will cause code that doesn't compile.
         //ctl_parameter_list._TreeSetCheckable(nodeIndex, checked==TCB_CHECKED? 0:1, 0);
         ctl_parameter_list._TreeSetCheckable(nodeIndex, 1, 0);
         ctl_parameter_list._TreeSetCheckState(nodeIndex, checked);
         index++;
      }
   }

   // adjust the tree column widths
   ctl_parameter_list._TreeAdjustColumnWidths(0);
   ctl_parameter_list._TreeAdjustColumnWidths(1);

   // set up the prototype label
   em_update_caption();
}
/**
 * When the OK button is pressed, we return a string containing all
 * the form results.  The string is of the form:
 * <pre>
 *    new method name                              [newline]
 *    create function call (1/0)                   [newline]
 *    new parameter name [tab] orig parameter name [newline]
 *    new parameter name [tab] orig parameter name [newline]
 *    ...
 *    new parameter name [tab] orig parameter name [newline]
 * </pre>
 */
void ctl_ok.lbutton_up()
{
   comment_type := getCommentType();

   // put in name and boolean for whether to create function call or not
   _str result = ctl_name.p_text "\n" ctl_replace.p_value "\n" ctl_beautify.p_value "\n" comment_type;

   if (gMethodInfo == null) {
      // create argument list, just a map of parameter names,
      // in order to their original names, skip names that are not marked
      index := ctl_parameter_list._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      while (index > 0) {
         checked := ctl_parameter_list._TreeGetCheckState(index);
         if (checked == TCB_CHECKED) {
            caption := ctl_parameter_list._TreeGetCaption(index);
            _str orig_id = ctl_parameter_list._TreeGetUserInfo(index);
            _str return_type,name,array_string;
            parse caption with . "\t" return_type "\t" name "\t" array_string;
            result :+= "\n" :+ name :+ "\t" :+ orig_id :+ "\t" :+ array_string;
         }
         index = ctl_parameter_list._TreeGetNextSiblingIndex(index);
      }
   }
   // that's all folks
   p_active_form._delete_window(result);
}
/**
 * Move an item down in the adjoining tree control.
 */
void ctl_move_parameter_down.lbutton_up()
{
   // find the tree control
   while (p_window_id.p_object != OI_TREE_VIEW) p_window_id = p_prev;
   // check the current index and next index
   index := _TreeCurIndex();
   if (index <= 0) return;
   // move the item down one index
   _TreeMoveDown(index);
   // update the prototype
   em_update_caption();
}
/**
 * Move an item up in the adjoining tree control.
 */
void ctl_move_parameter_up.lbutton_up()
{
   // find the tree control
   while (p_window_id.p_object != OI_TREE_VIEW) p_window_id = p_prev;
   // check the current index and next index
   index := _TreeCurIndex();
   if (index <= 0) return;
   // move the item down one index
   _TreeMoveUp(index);
   // update the prototype
   em_update_caption();
}
/**
 * Rename a parameter
 */
void ctl_rename.lbutton_up()
{
   // remember the alamo
   orig_wid := p_window_id;
   // find the current tree item
   tree_wid := p_prev;
   index := tree_wid._TreeCurIndex();
   if (index <= 0) return;
   caption := tree_wid._TreeGetCaption(index);
   keep := return_type := new_name := "";
   parse caption with keep "\t" return_type "\t" new_name;
   // prompt for a new parameter name
   while (new_name != '') {
      _str promptResult = show("-modal _textbox_form",
                               "Enter the new name for the argument",
                               0,
                               "",
                               "",
                               "",
                               "",
                               "Argument name:"new_name);
      // user cancelled operation
      if (promptResult == "") return;
      // check if response was valid
      new_name=_param1;
      if (refactor_validate_id(tree_wid, new_name, 2)) break;
   }
   // create the new caption and update the tree
   p_window_id = orig_wid;
   caption = keep"\t"return_type"\t"new_name;
   tree_wid._TreeSetCaption(index, caption);
   // finally, update the prototype
   em_update_caption();
}
/**
 * Allow them to edit parameter names within the tree.
 * The name column is the only editable column.
 */
int ctl_parameter_list.on_change(int reason,int index,int col=-1,_str &text='')
{
   if (reason==CHANGE_SELECTED) {

   } else if (reason == CHANGE_EDIT_QUERY) {
      return 0;

   } else if (reason == CHANGE_EDIT_CLOSE) {
      // make sure the new argument is valid
      if (arg(4)=='' || !refactor_validate_id(ctl_parameter_list, arg(4), 2)) {
         return(-1);
      }
      return 0;

   } else if (reason == CHANGE_EDIT_OPEN) {

   } else if (reason == CHANGE_OTHER && col>=0 && text!='') {
      // update the prototype with new argument
      em_update_caption();
   } else if (reason == CHANGE_CHECK_TOGGLED) {
      // update the prototype
      em_update_caption();
   }

   return(0);
}
/**
 * Validate the parameter name and update the prototype
 */
void ctl_name.on_change()
{
   // must match a "C" style identifier
   if (!refactor_c_is_valid_id(p_text)) {
      return;
   }
   em_update_caption();
}
/**
 * If they toggle the replace option, warn them if there
 * is an error preventing this from being done.
 */
void ctl_replace.lbutton_up()
{
   if (p_user < 0) {
      p_value = 0;
      _message_box(get_message(VSRC_VSREFACTOR_CANNOT_REPLACE_CODE_WITH_CALL)"\n\n"get_message(p_user));
   }
}


/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _refactor_extract_method_form_initial_alignment()
{
}

/**
 * Resize the extract method form
 */
void _refactor_extract_method_form.on_resize()
{
   // width/height of OK, Cancel, Help buttons (all are the same)
   int button_width  = ctl_ok.p_width;
   int button_height = ctl_ok.p_height;
   int horz_margin   = ctl_parameter_list.p_x;
   int vert_margin   = ctl_name.p_y;

   // force size of dialog to remain reasonable
   // if the minimum width has not been set, it will return 0
   if (!_minimum_width()) {
      _set_minimum_size(button_width*4, button_height*12);
   }

   // use the 'Help' button to compute the sizing motion
   int motion_x = p_width  - ctl_rename.p_x - ctl_rename.p_width  - horz_margin;
   int motion_y = p_height - ctl_cancel.p_y - ctl_cancel.p_height - vert_margin;

   // adjust vertical movements
   ctl_parameter_list.p_height += 3*motion_y intdiv 4;
   ctl_prototype.p_height += motion_y intdiv 4;
   ctl_border.p_height += motion_y intdiv 4;
   ctl_border.p_y      += 3*motion_y intdiv 4;
   ctl_ok.p_y     += motion_y;
   ctl_cancel.p_y += motion_y;
   ctl_help.p_y   += motion_y;

   // adjust horizontal movements
   ctl_name.p_width += motion_x;
   ctl_parameter_list.p_width += motion_x;
   ctl_border.p_width += motion_x;
   ctl_prototype.p_width += motion_x;
   ctl_replace.p_width += motion_x;

   // adjust the tree column widths
   ctl_parameter_list._TreeAdjustLastColButtonWidth();

   alignUpDownListButtons(ctl_parameter_list.p_window_id, 
                          p_active_form.p_width - ctl_parameter_list.p_x,
                          ctl_rename.p_window_id, 
                          ctl_move_parameter_up.p_window_id, 
                          ctl_move_parameter_down.p_window_id);
}

///////////////////////////////////////////////////////////////////////////////
/**
 * Form used for displaying changes made by a refactoring.
 */
defeventtab _refactor_results_form;
static const REFACTOR_RESULTS_FORM_WIDTH=           8000;
static const REFACTOR_RESULTS_FORM_HEIGHT=          6000;
static int REFACTOR_RESULTS_TRANSACTION_HANDLE(...) {
   if (arg()) ctlOK.p_user=arg(1);
   return ctlOK.p_user;
}
static _str REFACTOR_RESULTS_FILE_LIST(...)[] {
   if (arg()) ctlFileListTree.p_user=arg(1);
   return ctlFileListTree.p_user;
}
static bool REFACTOR_RESULTS_REVERSED(...) {
   if (arg()) ctlCopyFile.p_user=arg(1);
   return ctlCopyFile.p_user;
}
static int getOriginalFileWID() {
   if (REFACTOR_RESULTS_REVERSED()) {
      return _control _ctlfile2;
   }
   return _control _ctlfile1;
}
static int getModifiedFileWID() {
   if (REFACTOR_RESULTS_REVERSED()) {
      return _control _ctlfile1;
   }
   return _control _ctlfile2;
}

static const MARK_SEARCH_STRING  = "{#0[<][<][<]/?*([-]:i|)/[>][>][>]}";
static const MARK_SEARCH_OPTIONS = "@rh>";
static int  tree_previous_file_selection = 0;
static int  tree_previous_mark_selection = 0;
static int  outstanding_input_requests = 0;
static _str current_mark="";
static bool ignore_file_tree_changes = false;
static int tree_next_prev_diff_direction = 0;

static void set_input_request_mark_info(_str& mark_string, _str string, int line_number, int col, int visited)
{
   mark_string = line_number :+ '@' :+ col :+ '@' :+ visited :+ '@' :+ string;
}

static void get_input_request_mark_info(_str mark_string, _str &string, int &line_number, int &col, int &visited)
{
   typeless s_line_number, s_col, s_visited;
   parse mark_string with s_line_number '@' s_col '@' s_visited '@' string;
   line_number = (int)s_line_number;
   col = (int)s_col;
   visited = (int)s_visited;
}

static void validate_input_request_mark(int input_request_mark_tree_index)
{
   int temp_view_id, orig_hidden_window_view_id, orig_view_id, orig_window_id, line_number, col, show_children;
   int non_current_bmi, current_bmi, more_flags, visited;
   // May not be in same file!?!?!
   _str mark_string, mark_info = ctlFileListTree._TreeGetUserInfo(input_request_mark_tree_index);

   get_input_request_mark_info(mark_info, mark_string, line_number, col, visited); 

   // Search for string associated with previous mark selection.
   ctlOriginalFile   := getOriginalFileWID();
   ctlRefactoredFile := getModifiedFileWID();
   ctlRefactoredFile.p_line = line_number;
   ctlRefactoredFile.p_col = col;
   result := ctlRefactoredFile.search(mark_string, '@h');

   // If the string cannot be found then search up instead. 
   if (result < 0) {
      result = ctlRefactoredFile.search(mark_string, "@hE-");
   }

   // If string can still not be found then the mark must have been removed through editing.
   if (result < 0) {
//      // Change exclamation point to green
      int bitmap_input = _find_or_add_picture("_f_checkbox.svg");
      ctlFileListTree._TreeGetInfo(input_request_mark_tree_index, show_children, non_current_bmi, current_bmi, more_flags, line_number);
      ctlFileListTree._TreeSetInfo(input_request_mark_tree_index, show_children, bitmap_input, bitmap_input, more_flags);
      // decrement number of input requests
   }
}

static bool is_input_request_node(int tree_index)
{
   int show_children, non_current_bmi, current_bmi, more_flags, line_number;
   ctlFileListTree._TreeGetInfo(tree_index, show_children, non_current_bmi, current_bmi, more_flags, line_number);
   return (show_children == -1);
}

static bool is_file_node(int tree_index)
{
   int show_children, non_current_bmi, current_bmi, more_flags, line_number;
   ctlFileListTree._TreeGetInfo(tree_index, show_children, non_current_bmi, current_bmi, more_flags, line_number);
   return (show_children != -1);
}

static void jump_to_mark(int input_request_mark_tree_index)
{
   int col, line_number, visited;
   _str mark_string, mark_info = ctlFileListTree._TreeGetUserInfo(input_request_mark_tree_index);

   // If still in same file as last selection then see if the previous mark selection
   // can be found. if it cannot be found then mark it as being fixed. Change the bitmap
   // to green.
   if (tree_previous_mark_selection != 0 && tree_previous_mark_selection != input_request_mark_tree_index && 
            ctlFileListTree._TreeGetParentIndex(tree_previous_mark_selection) == tree_previous_file_selection) { 
      validate_input_request_mark(tree_previous_mark_selection);
   }

   tree_previous_mark_selection = input_request_mark_tree_index;
   tree_previous_file_selection = ctlFileListTree._TreeGetParentIndex(input_request_mark_tree_index);

   get_input_request_mark_info(mark_info, mark_string, line_number, col, visited); 
   // Has this input request been looked at yet? If not then mark as visited since we
   // are looking at it now and decrement the count of input requests not yet visited.
   // When this goes to zero enable the ok button.
   if (visited == 0) {
      visited = 1;
      outstanding_input_requests--;
      if (outstanding_input_requests <= 0) {
         ctlOK.p_enabled = true;
      }
      set_input_request_mark_info( mark_info, mark_string, line_number, col, visited); 
      ctlFileListTree._TreeSetUserInfo(input_request_mark_tree_index, mark_info);
   }

   // First try searching at the line where the mark_string was originally.
   // It may not be found due to edits of the refactored view but try this first.
   ctlOriginalFile   := getOriginalFileWID();
   ctlRefactoredFile := getModifiedFileWID();
   ctlRefactoredFile.p_line = line_number;
   ctlRefactoredFile.p_col  = col;
   result := ctlRefactoredFile.search(mark_string, '@h');

   // If the string could not be found with the above search then try searching backwards.
   if (result != 0) {
      result = ctlRefactoredFile.search(mark_string,'@hE-');
   }

   if (result == 0) {

      if (current_mark != '') {
         _free_selection(current_mark);
         current_mark='';
      }

      current_mark = _alloc_selection();

      ctlRefactoredFile._select_char(current_mark);
      ctlRefactoredFile.search(">>>", "@h");
      ctlRefactoredFile._GoToROffset(ctlRefactoredFile._QROffset() + 3);
      ctlRefactoredFile._select_char(current_mark);
      _show_selection(current_mark);
   } else {
      // Jump to line number where string occurred
      ctlRefactoredFile.p_line = line_number;
      ctlRefactoredFile.p_col = col;
   }

   ctlRefactoredFile._set_focus();
   ctlOriginalFile.p_line = line_number;

   // sync the lines
   ctlOriginalFile.center_line();
   ctlRefactoredFile.center_line();

   if (ctlFileListTree._TreeCurIndex() != input_request_mark_tree_index) {
      ctlFileListTree._TreeSetCurIndex(input_request_mark_tree_index);
   }
}

void ctlOK.on_create(_str fakeFile1, _str fakeFile2, 
                     _str isDiff, int handle, 
                     _str fileList[], 
                     _str results_name, 
                     bool place_modified_on_left=false)
{  
   tree_previous_file_selection = 0;
   tree_previous_mark_selection = 0;
   tree_next_prev_diff_direction = 0;
   outstanding_input_requests = 0;

   // save the information that was passed in
   REFACTOR_RESULTS_TRANSACTION_HANDLE(handle);
   REFACTOR_RESULTS_FILE_LIST(fileList);
   REFACTOR_RESULTS_REVERSED(place_modified_on_left);

   bitmap_input := _find_or_add_picture("_f_error.svg");
   bitmap_file  := _find_or_add_picture("_f_doc.svg");

   // doing things backwards?
   ctlOriginalFile   := getOriginalFileWID();
   ctlRefactoredFile := getModifiedFileWID();
   if (place_modified_on_left) {
      ctlCopyFile.p_caption  = "<< &File";
      ctlCopyBlock.p_caption = "<< &Block";
      ctlCopyLine.p_caption  = "<< &Line";

      // swap file1 and file1 positions
      ctlRefactoredFileLabel.p_x = ctlOriginalFile.p_x;
      ctlOriginalFileLabel.p_x   = ctlRefactoredFile.p_x;
   }


   // populate the file list tree
   ignore_file_tree_changes=true;
   for (i := 0; i < fileList._length(); i++) {

      // Save view id and window
      get_window_id(auto orig_view_id);
      orig_window_id := p_window_id;

      // Preserve the active view in the HIDDEN WINDOW
      p_window_id=VSWID_HIDDEN;
      orig_hidden_window_view_id := _create_temp_view(auto temp_view_id);

      status := refactor_get_modified_file_contents( 0, handle, fileList[i]);

      // Crucial step here. Cursor is at very bottom of buffer to start with. Or you can search backwards.
      top();

      _str mark_list[];
      mark_string := "";
      line_number := 0;
      col := 0;
      visited := 0;
      save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
      result := search(MARK_SEARCH_STRING, MARK_SEARCH_OPTIONS);
      while (result == 0) {
         // Get mark string
         mark_string = get_text(match_length('0'),match_length('S0'));
         // Get line number. Should this be old line number?
         line_number = p_line; 
         // Get col at beginning of mark string
         col = p_col - length(mark_string);

         // Has this mark been visited?
         visited = 0;
         set_input_request_mark_info( mark_list[mark_list._length()], mark_string, line_number, col, visited); 
         outstanding_input_requests++;

         result = search(MARK_SEARCH_STRING, MARK_SEARCH_OPTIONS);
      }

      // clean up the temp view
      restore_search(s1, s2, s3, s4, s5);
      _delete_temp_view(temp_view_id);
      activate_window(orig_hidden_window_view_id);
      p_window_id = orig_window_id;
      activate_window(orig_view_id);

      // Stick the file in the list and all of the marks as children of the file.
      int file_index;
// FIX This code freaks everything out if it is uncommented. I don't know why
//      if (mark_list != null) {
         file_index  = ctlFileListTree._TreeAddItem(TREE_ROOT_INDEX, fileList[i], TREE_ADD_AS_CHILD, bitmap_file, bitmap_file, 1, 0, fileList[i]);
//      } else {
//         file_index  = ctlFileListTree._TreeAddItem(TREE_ROOT_INDEX, fileList[i], TREE_ADD_AS_CHILD, bitmap_file, bitmap_file, -1);
//      }
      for (j := 0; j < mark_list._length(); j++) {
         // Get mark_string 
         get_input_request_mark_info( mark_list[j], mark_string, line_number, col, visited); 
         // Build caption for tree node based on mark_string
         mark_name := substr( mark_string, 4, length(mark_string)-6);
         ctlFileListTree._TreeAddItem(file_index, mark_name, TREE_ADD_AS_CHILD, bitmap_input, bitmap_input, -1, 0, mark_list[j]);
      }

// FIX This code freaks everything out if it is uncommented. I don't know why
//      if (mark_list == null || mark_list._length() == 0) {
//         ctlFileListTree._TreeSetInfo(file_index,  -1);
//      }
   }

   // sort the tree
   ctlFileListTree._TreeSortCaption(TREE_ROOT_INDEX);
   ignore_file_tree_changes=false;

   // make the first file active
   if (fileList._length() > 0) {
      index := ctlFileListTree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      ctlFileListTree._TreeSetCurIndex(index);

      // Be sure to pass 0 for column
      ctlFileListTree.call_event(CHANGE_SELECTED, index, 0, ctlFileListTree, ON_CHANGE, 'W');
      ctlOriginalFile.center_line();
      ctlRefactoredFile.center_line();
   }

   // Only disable ok button if there are outstanding requests
   if (outstanding_input_requests) {
      ctlOK.p_enabled=false;
      ctlNextInput.p_enabled = true;
      ctlNextInput.p_visible = true;
      ctlPrevInput.p_enabled = true;
      ctlPrevInput.p_visible = true;
   } else {
      ctlNextInput.p_enabled = false;
      ctlNextInput.p_visible = false;
      ctlPrevInput.p_enabled = false;
      ctlPrevInput.p_visible = false;
   }

   // set caption
   p_active_form.p_caption = results_name;

   DIFF_MISC_INFO misc;
   InitMiscDiffInfo(misc, 'diff');
   _SetDialogInfo(DIFFEDIT_CONST_MISC_INFO, misc, ctlOriginalFile);
   _DiffAddWindow(p_active_form, isDiff:false);
}

void ctlFileListTree.lbutton_double_click()
{
   ctlOriginalFile   := getOriginalFileWID();
   ctlRefactoredFile := getModifiedFileWID();

   value := "";
   caption := "";
   index := ctlFileListTree._TreeCurIndex();

   if (is_input_request_node(index)) {
      int col, line_number, visited;
      _str mark_string, mark_info = ctlFileListTree._TreeGetUserInfo(index);
      get_input_request_mark_info(mark_info, mark_string, line_number, col, visited); 

      ctlRefactoredFile.top();
      result := ctlRefactoredFile.search(mark_string,'@rh');

      // Could not find mark string. Don't bring up dialog since we don't know where
      // to put the results.
      if (result < 0) {
         return;
      }

      caption = "Insert value for " :+ substr( mark_string, 4, length(mark_string)-6);
      int prompt_result = show('-modal _textbox_form',
                  caption,  // Form caption
                  0, //flags
                  '',   //use default textbox width
                  '', //Help item.
                  '',   //Buttons and captions
                  '', //Retrieve Name
                  'Value:'value);  

      // user cancelled operation
      if (prompt_result == "") return;

      value = _param1;

      // Only replace the mark if the user entered something.
      if ( value != '') {
         ctlRefactoredFile.search(mark_string, "+", value);

         _deselect('');

         if (current_mark != '') {
            _free_selection(current_mark);
            current_mark='';
         }
      }
   }
}

void ctlFileListTree.lbutton_up()
{
   index := _TreeCurIndex();
   if (is_input_request_node(index)) {
      jump_to_mark(index);
   }
}

/**
 * Cleanup the buffers/views used by the editor controls
 *
 * NOTE: This must be called on p_active_form for _refactor_results_form
 *
 * @return
 */
static int cleanupRefactoringResultsViews()
{
   // if there are already files loaded, get rid of them
   ctlOriginalFile   := getOriginalFileWID();
   ctlRefactoredFile := getModifiedFileWID();
   if (ctlOriginalFile.p_buf_name != "") {
      // clean up diff modifications to buffer
      DiffFreeAllColorInfo(ctlOriginalFile.p_buf_id);
      ctlOriginalFile._DiffRemoveImaginaryLines();
      ctlOriginalFile._DiffClearLineFlags();
      DiffTextChangeCallback(0, ctlOriginalFile.p_buf_id);
   }

   // delete the buffer associated with the original file control
   ctlOriginalFile._delete_buffer();

   if (ctlRefactoredFile.p_buf_name != "") {
      // clean up diff modifications to buffer
      DiffFreeAllColorInfo(ctlRefactoredFile.p_buf_id);
      ctlRefactoredFile._DiffRemoveImaginaryLines();
      ctlRefactoredFile._DiffClearLineFlags();
      DiffTextChangeCallback(0, ctlRefactoredFile.p_buf_id);
   }

   // delete the buffer associated with the refactored file control
   ctlRefactoredFile._delete_buffer();

   return 0;
}

void ctlFileListTree.on_change(int reason,int index,int col=-1)
{
   ctlOriginalFile   := getOriginalFileWID();
   ctlRefactoredFile := getModifiedFileWID();
   haveMouHourGlass  := false;

   while (reason == CHANGE_SELECTED && !ignore_file_tree_changes && col >= 0) {
      status := 0;

      ctlNextFile.p_enabled = (_TreeGetNextSiblingIndex(index) > 0);
      ctlPrevFile.p_enabled = (_TreeGetPrevSiblingIndex(index) > 0);

      // Check previous file selection before moving onto new file selection.
      // Validate any input requests that are associated with the previous file selection
      // changing them to fixed if they are not found.
      if (tree_previous_file_selection > 0) {
         child_index := _TreeGetFirstChildIndex(tree_previous_file_selection);
         while (child_index > 0) {
            validate_input_request_mark(child_index);
            child_index = _TreeGetNextSiblingIndex(child_index);
         }
      }

      if (is_input_request_node(index)) {
         index = _TreeGetParentIndex(index);
      }

      if (index == tree_previous_file_selection) {
         return;
      }

      tree_previous_file_selection = index;
      if (!haveMouHourGlass) {
         mou_hour_glass(true);
         haveMouHourGlass = true;
      }

      // if there are any changes in the refactored buffer, store them
      filename := _TreeGetCaption(index);
      if (ctlRefactoredFile.p_buf_name != "" && ctlRefactoredFile.p_modify) {

         status = refactor_set_modified_file_contents(ctlRefactoredFile,
                                                      REFACTOR_RESULTS_TRANSACTION_HANDLE(),
                                                      ctlOriginalFile.p_buf_name);

         if (status < 0) {
            _message_box("Refactoring error: Could not store modifications for file '" ctlOriginalFile.p_buf_name "'");
            break;
         }
      }

      // if there are already files loaded, get rid of them
      p_active_form.cleanupRefactoringResultsViews();

      // open the original file from disk always, even if it is already loaded
      // in the editor.  this is safe to do because refactoring requires that
      // all files be saved to disk before it can run.  this greatly simplifies
      // this dialog since this buffer can always be safely deleted without
      // worrying if it is open elsewhere
      //
      // The +m option preserves the old buffer position information for the current buffer

      options := "+m +q +d ";
      status = refactor_get_file_encoding(REFACTOR_RESULTS_TRANSACTION_HANDLE(), filename, auto encoding);
      if (encoding != '') {
         options :+= encoding" ";
      }
      status = ctlOriginalFile.load_files(options:+_maybe_quote_filename(filename));
      if (status) {
         // file must not be there
         _message_box("Refactoring diff: Original file '" filename "' not found");
         break;
      }
      ctlOriginalFile._SetEditorLanguage();

      options = "+m ";
      if (encoding != '') {
         options :+= encoding" ";
      }
      // determine what line endings should be used
      switch (ctlOriginalFile.p_newline) {
      case "\r\n":
         options :+= "+TD ";
         break;
      case "\r":
         options :+= "+TM ";
         break;
      case "\n":
         options :+= "+TU ";
         break;
      default:
         options :+= "+T ";
         break;
      }

      ctlRefactoredFile.load_files(options);
      ctlRefactoredFile.p_buf_flags = ctlRefactoredFile.p_buf_flags | VSBUFFLAG_HIDDEN;
      ctlRefactoredFile._delete_line();
      //ctlOriginalFile

      // insert the refactored contents, fake the slightly modified filename,
      // and mark it not modified.
      refactor_get_modified_file_contents(ctlRefactoredFile, REFACTOR_RESULTS_TRANSACTION_HANDLE(), filename);
      /* Set the buffer to a valid absolute filename to avoid having a ':'
         later in the buffer name which causes an infinite loop in the
         editor config code.
        
        Setting buffer name twice won't be necesssary for v21.0.3 because the 
        get path length code has been fixed to ignore colons that aren't the
        2nd byte of the string.
      */ 
      ctlRefactoredFile.p_buf_name = filename;
      ctlRefactoredFile._SetEditorLanguage();
      ctlRefactoredFile.p_buf_name = "refactored-" filename;
      ctlRefactoredFile.p_modify = false;

      ctlOriginalFile._DiffClearLineFlags();
      ctlRefactoredFile._DiffClearLineFlags();
      ctlOriginalFile._DiffSetWindowFlags();
      ctlRefactoredFile._DiffSetWindowFlags();

      // do the diff
      // todo - remove DIFF_DONT_COMPARE_EOL_CHARS
      outputBufID := 0;

      DIFF_INFO info;
      info.iViewID1 = _ctlfile1;
      info.iViewID2 = _ctlfile2;
      info.iOptions = DIFF_DONT_COMPARE_EOL_CHARS;
      info.iNumDiffOutputs = 0;
      info.iIsSourceDiff = false;
      info.loadOptions = def_load_options;
      info.iGaugeWID = 0;
      info.iMaxFastFileSize = def_max_fast_diff_size;
      info.lineRange1 = "1";
      info.lineRange2 = "2";
      info.iSmartDiffLimit = def_smart_diff_limit;
      info.imaginaryText = "Imaginary Buffer Line";
      info.tokenExclusionMappings=null;

      // make original read-only
      ctlOriginalFile.p_readonly_mode = true;
      ctlOriginalFile._DiffSetReadOnly(1);

      status = Diff(info,outputBufID);

      // turn on intra-line diff callback
      DiffTextChangeCallback(1, ctlOriginalFile.p_buf_id);
      DiffTextChangeCallback(1, ctlRefactoredFile.p_buf_id);

      ctlFileNameLabel.p_caption = filename;
      ctlFileNameLabel._ShrinkFilename(filename, ctlFileNameLabel.p_width);
      ctlOriginalFile.refresh();
      ctlRefactoredFile.refresh();
      //say("ctlFileListTree.on_change H"__LINE__": filename="filename);

      // make sure there really was something different

      // move to first diff
      ctlOriginalFile.top_of_buffer();
      p_active_form._DiffSetupScrollBars();
      p_active_form._DiffSetupHorizontalScrollBar();
      vscroll1._ScrollMarkupSetAssociatedEditor(_ctlfile1);
      _DiffSetNeedRefresh(true);
      diff_label_copy_buttons(_control ctlCopyBlock, _control ctlCopyLine, 
                              reverse_left_and_right: REFACTOR_RESULTS_REVERSED());

      // position both buffers at line zero.  this must be done in case the
      // entire file was changed.  otherwise, next diff will step to the
      // next file.
      if (tree_next_prev_diff_direction >= 0) {
         ctlOriginalFile.top(); ctlOriginalFile.up();
         ctlRefactoredFile.top(); ctlRefactoredFile.up();
      } else {
         ctlOriginalFile.bottom(); ctlOriginalFile._end_line();
         ctlRefactoredFile.bottom(); ctlRefactoredFile._end_line();
      }

      ignore_file_tree_changes = true;
      if (tree_next_prev_diff_direction == 0) {
         // quietly try to move to first difference
         status = _DiffNextDifference(ctlOriginalFile, ctlRefactoredFile, "", "No Messages");
         // tell diff things have changed
         _DiffSetNeedRefresh(true);
         diff_label_copy_buttons(_control ctlCopyBlock, _control ctlCopyLine, 
                                 reverse_left_and_right: REFACTOR_RESULTS_REVERSED());
         // sync the lines
         ctlOriginalFile.center_line();
         ctlRefactoredFile.center_line();
         ctlOriginalFile.p_scroll_left_edge = ctlRefactoredFile.p_scroll_left_edge = -1;
         ignore_file_tree_changes = false;
         break;
      } else if (tree_next_prev_diff_direction > 0 && refactorResultsJumpNextDiff()) {
         index = _TreeCurIndex();
         ignore_file_tree_changes = false;
         continue;
      } else if (tree_next_prev_diff_direction < 0 && refactorResultsJumpPrevDiff()) {
         index = _TreeCurIndex();
         ignore_file_tree_changes = false;
         continue;
      }
      tree_next_prev_diff_direction = 0;
      ignore_file_tree_changes = false;
      break;
   }

   if (haveMouHourGlass) {
      mou_hour_glass(false);
   }
}

void ctlOK.lbutton_up()
{
   // Don't allow leaving until all of the input requests remarks are gone.
   // Search for all of the input requests int the tree.
   // populate the file list tree

   _str fileList[] = REFACTOR_RESULTS_FILE_LIST();
   handle := REFACTOR_RESULTS_TRANSACTION_HANDLE();
   ctlOriginalFile   := getOriginalFileWID();
   ctlRefactoredFile := getModifiedFileWID();

   // if there are any changes in the refactored buffer, store them
   if (ctlRefactoredFile.p_buf_name != "" && ctlRefactoredFile.p_modify) {

      int status = refactor_set_modified_file_contents(ctlRefactoredFile, handle,
                                                       ctlOriginalFile.p_buf_name);
      if (status < 0) {
         _message_box("Refactoring error: Could not store modifications for file '" ctlOriginalFile.p_buf_name "'");
      }
   }

   // Only do this check if we have input requests in tree.
   // Using the ctlNextInput being enabled as the check. 
   if (ctlNextInput.p_enabled == true) {
      for (i := 0; i < fileList._length(); i++) {
   
         // Save view id and window
         get_window_id(auto orig_view_id);
         orig_window_id := p_window_id;
   
         // Preserve the active view in the HIDDEN WINDOW
         p_window_id=VSWID_HIDDEN;
         orig_hidden_window_view_id := _create_temp_view(auto temp_view_id);
   
         status := refactor_get_modified_file_contents( 0, handle, fileList[i]);
         if (status == FILE_NOT_FOUND_RC) {
            // clean up the temp view
            _delete_temp_view(temp_view_id);
            activate_window(orig_hidden_window_view_id);
            p_window_id = orig_window_id;
            activate_window(orig_view_id);
            continue;
         }
   
         // Crucial step here. Cursor is at very bottom of buffer to start with. Or you can search backwards.
         top();
         result := search(MARK_SEARCH_STRING, MARK_SEARCH_OPTIONS);
   
         // clean up the temp view
         _delete_temp_view(temp_view_id);
         activate_window(orig_hidden_window_view_id);
         p_window_id = orig_window_id;
         activate_window(orig_view_id);
   
         // Found a marker
         if (result == 0) {
            _message_box("Resolve the outstanding input requests.", "Modify Parameters");
            return;
         }
      }
   }

   p_active_form._delete_window("1");
}


static bool refactorResultsJumpNextDiff()
{
   // find next diff
   jumpedToNextFile  := false;
   ctlOriginalFile   := getOriginalFileWID();
   ctlRefactoredFile := getModifiedFileWID();
   status := _DiffNextDifference(ctlOriginalFile, ctlRefactoredFile, "", "No Messages");

   index := ctlFileListTree._TreeCurIndex();
   if (is_input_request_node(index)){
      index = ctlFileListTree._TreeGetParentIndex(index);
   }

   // if there are no differences, but more files to check, prompt them
   if (status == 1 && ctlFileListTree._TreeGetNextSiblingIndex(index) >= 0) {
      response := IDYES;
      if (!(def_refactor_option_flags & REFACTOR_GO_TO_NEXT_FILE)) {
         response = _difftree_save_prompt("No more differences.  Proceed to next file?","Don't show this message again","OK","");
         if (response == IDYES && _param1) {
            def_refactor_option_flags |= REFACTOR_GO_TO_NEXT_FILE;
         }
      }
      if (response == IDYES) {
         index = ctlFileListTree._TreeGetNextSiblingIndex(index);
         tree_next_prev_diff_direction = 1;
         ctlFileListTree._TreeSetCurIndex(index);
         jumpedToNextFile = true;
      }
   } else if (status == 1) {
      _message_box(get_message(VSDIFF_NO_MORE_DIFFERENCES_RC));
   }

   // tell diff things have changed
   _DiffSetNeedRefresh(true);
   diff_label_copy_buttons(ctlCopyBlock, ctlCopyLine, 
                           reverse_left_and_right: REFACTOR_RESULTS_REVERSED());

   // sync the lines
   ctlOriginalFile.center_line();
   ctlRefactoredFile.center_line();
   ctlOriginalFile.p_scroll_left_edge = ctlRefactoredFile.p_scroll_left_edge = -1;
   return jumpedToNextFile;
}

static bool refactorResultsJumpPrevDiff()
{
   // find prev diff
   jumpedToPrevFile  := false;
   ctlOriginalFile   := getOriginalFileWID();
   ctlRefactoredFile := getModifiedFileWID();
   status := _DiffNextDifference(ctlOriginalFile, ctlRefactoredFile, "-", "No Messages");

   index := ctlFileListTree._TreeCurIndex();
   if (is_input_request_node(index)) {
      index = ctlFileListTree._TreeGetParentIndex(index);
   }

   // if there are no differences, but more files to check, prompt them
   if (status == 1 && ctlFileListTree._TreeGetPrevSiblingIndex(index) >= 0) {
      int response = IDYES;
      if (!(def_refactor_option_flags & REFACTOR_GO_TO_PREV_FILE)) {
         response = _difftree_save_prompt("No more differences.  Go to previous file?","Don't show this message again","OK","");
         if (response == IDYES && _param1) {
            def_refactor_option_flags |= REFACTOR_GO_TO_PREV_FILE;
         }
      }
      if (response == IDYES) {
         jumpedToPrevFile = true;
         tree_next_prev_diff_direction = -1;
         ctlFileListTree._TreeUp();
         while (is_input_request_node(ctlFileListTree._TreeCurIndex())) {
            ctlFileListTree._TreeUp();
         }

         while (!_DiffNextDifference(ctlOriginalFile, ctlRefactoredFile, "", "No Messages"));
      }
   } else if (status == 1) {
      _message_box(get_message(VSDIFF_NO_MORE_DIFFERENCES_RC));
   }

   // tell diff things have changed
   _DiffSetNeedRefresh(true);
   diff_label_copy_buttons(ctlCopyBlock, ctlCopyLine, 
                           reverse_left_and_right: REFACTOR_RESULTS_REVERSED());

   // sync the lines
   ctlOriginalFile.center_line();
   ctlRefactoredFile.center_line();
   return jumpedToPrevFile;
}

void ctlNextDiff.lbutton_up()
{
   refactorResultsJumpNextDiff();
}

void ctlPrevDiff.lbutton_up()
{
   refactorResultsJumpPrevDiff();
}

void ctlNextInput.lbutton_up()
{
   // make sure the current tree index is valid
   index := ctlFileListTree._TreeCurIndex();
   if (index <= 0) return;

   if (is_input_request_node(index)) {
      if (ctlFileListTree._TreeGetNextSiblingIndex(index) > 0) {
         index = ctlFileListTree._TreeGetNextSiblingIndex(index);
         ctlFileListTree._TreeSetCurIndex(index);
         jump_to_mark(index);
         return;
      } else {
         // Jump to parent 
         index = ctlFileListTree._TreeGetParentIndex(index);
      }
   } else {
      if (ctlFileListTree._TreeGetFirstChildIndex(index) > 0) {
         index = ctlFileListTree._TreeGetFirstChildIndex(index);
         ctlFileListTree._TreeSetCurIndex(index);
         jump_to_mark(index);
         return;
      }
   }

   // Search next parent siblings until we run out of siblings or find one
   // with children.
   temp := ctlFileListTree._TreeGetNextSiblingIndex(index);
   while ((temp > 0) && (ctlFileListTree._TreeGetNumChildren(temp) == 0)) {
      temp = ctlFileListTree._TreeGetNextSiblingIndex(temp);
   }

   // Found a sibling with children. Jump to first child
   if (temp > 0) {
      index = ctlFileListTree._TreeGetFirstChildIndex(temp);
      ctlFileListTree._TreeSetCurIndex(index);
      jump_to_mark(index);
      return;
   }

   // no more
   _message_box("No more input requests!");
}

void ctlPrevInput.lbutton_up()
{
   // make sure the current tree index is valid
   index := ctlFileListTree._TreeCurIndex();
   if (index <= 0) return;

   if (is_input_request_node(index)) {
      if (ctlFileListTree._TreeGetPrevSiblingIndex(index) > 0) {
         index = ctlFileListTree._TreeGetPrevSiblingIndex(index);
         ctlFileListTree._TreeSetCurIndex(index);
         jump_to_mark(index);
         return;
      } else {
         // Jump to parent 
         index = ctlFileListTree._TreeGetParentIndex(index);
      }
   }

   // Search previous parent siblings until we run out of siblings or find one
   // with children.
   temp := ctlFileListTree._TreeGetPrevSiblingIndex(index);
   while ((temp > 0) && (ctlFileListTree._TreeGetNumChildren(temp) == 0)) {
      temp = ctlFileListTree._TreeGetPrevSiblingIndex(temp);
   }

   // Found a sibling with children. Jump to the last child.
   if (temp > 0) {
      temp = ctlFileListTree._TreeGetFirstChildIndex(temp);
      while (ctlFileListTree._TreeGetNextSiblingIndex(temp) > 0) {
         temp = ctlFileListTree._TreeGetNextSiblingIndex(temp);
      }
      ctlFileListTree._TreeSetCurIndex(temp);
      jump_to_mark(temp);
      return;
   }

   // no more
   _message_box("No more input requests!");
}
void ctlCopyFile.lbutton_up()
{
   ctlOriginalFile   := getOriginalFileWID();
   ctlRefactoredFile := getModifiedFileWID();

   // make sure they don't do this by accident
   orig_wid := p_window_id;
   status := _message_box("Revert to original version of file?", "SlickEdit", MB_YESNO);
   if (status != IDYES) {
      return;
   }

   // and then remove the file from the transaction
   handle := REFACTOR_RESULTS_TRANSACTION_HANDLE();
   status = refactor_remove_file(handle, ctlOriginalFile.p_buf_name);
   if (status < 0) {
      _message_box("Could not restore file: ":+get_message(status));
      return;
   }

   // now remove the file from the tree
   index := ctlFileListTree._TreeCurIndex();
   if (index <= 0) return;
   if (is_input_request_node(index)) {
      index = ctlFileListTree._TreeGetParentIndex(index);
   }

   // no more files?
   firstIndex := ctlFileListTree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   if (firstIndex == index) {
      nextIndex := ctlFileListTree._TreeGetNextSiblingIndex(firstIndex);
      if (nextIndex <= 0) {
         _message_box("No more files!");
         ctlCancel.call_event(ctlCancel, LBUTTON_UP, 'W');
         return;
      }
   }

   // delete this file from the tree
   tree_previous_file_selection = 0;
   tree_previous_mark_selection = 0;
   tree_next_prev_diff_direction = 0;
   ctlFileListTree._TreeDelete(index);
   index = ctlFileListTree._TreeCurIndex();
   ctlFileListTree.call_event(CHANGE_SELECTED, index, 0, ctlFileListTree, ON_CHANGE, 'W');

   // that's all folks
   return;
}

void ctlNextFile.lbutton_up()
{
   ctlFileListTree._TreeDown();
}
void ctlPrevFile.lbutton_up()
{
   ctlFileListTree._TreeUp();
}

void ctlCopyBlock.lbutton_up()
{
   ctlOriginalFile   := getOriginalFileWID();
   ctlRefactoredFile := getModifiedFileWID();

   formWid := p_active_form;
   switch (ctlCopyBlock.p_caption) {
   case 'Del Block':
      ctlOriginalFile.diff_delete_block('No Messages');
      break;
   case 'Block>>':
   case '<<Block':
      ctlOriginalFile.diff_copy_block('No Messages');
      break;
   }

   //if (def_diff_edit_flags & DIFFEDIT_AUTO_JUMP) {
   //   ctlNextDiff.call_event(ctlNextDiff, LBUTTON_UP, 'W');
   //}

   if (!_iswindow_valid(formWid)) return;

   _DiffSetNeedRefresh(true);
   diff_label_copy_buttons(ctlCopyBlock, ctlCopyLine, 
                           reverse_left_and_right: REFACTOR_RESULTS_REVERSED());

   p_window_id=ctlRefactoredFile;
   ctlOriginalFile.refresh('w');
   ctlRefactoredFile.refresh('w');
   ctlRefactoredFile._set_focus();
   return;
}
void ctlCopyLine.lbutton_up()
{
   ctlOriginalFile   := getOriginalFileWID();
   ctlRefactoredFile := getModifiedFileWID();
   diff_copy_line(ctlOriginalFile, ctlRefactoredFile);
   return;
}

void _refactor_results_form.on_resize()
{
   // enforce a minimum size
   // if the minimum width has not been set, it will return 0
   if (!_minimum_width()) {
      _set_minimum_size(REFACTOR_RESULTS_FORM_WIDTH, REFACTOR_RESULTS_FORM_HEIGHT);
   }

   // get the active forms client width and height in twips
   clientHeight := p_height;
   clientWidth := p_width;

   // take spacing standard from left border spacing (ctlOriginalFile.p_x)
   ctlOriginalFile     := _ctlfile1;
   ctlRefactoredFile   := _ctlfile2;
   refactoredFileLabel := ctlRefactoredFileLabel;
   originalFileLabel   := ctlOriginalFileLabel;
   if (REFACTOR_RESULTS_REVERSED()) {
      refactoredFileLabel = ctlOriginalFileLabel;
      originalFileLabel   = ctlRefactoredFileLabel;
   }

   spacing := ctlOK.p_x;
   labelSpacing := 60;

   // move the buttons
   newButtonY := clientHeight - ctlOK.p_height - spacing;
   ctlOK.p_y = newButtonY;
   ctlCancel.p_y = newButtonY;
   ctlNextFile.p_y = newButtonY;
   ctlPrevFile.p_y = newButtonY;
   ctlNextDiff.p_y = newButtonY;
   ctlPrevDiff.p_y = newButtonY;
   ctlNextInput.p_y = newButtonY;
   ctlPrevInput.p_y = newButtonY;
   ctlCopyBlock.p_y = newButtonY;
   ctlCopyLine.p_y = newButtonY;
   ctlCopyFile.p_y = newButtonY;

   // adjust button X positioning
   btnMarginX := ctlPrevInput.p_x - ctlNextInput.p_x_extent;
   btnMarginW := ctlOK.p_width intdiv 4;
   if (btnMarginX < ctlOK.p_x) btnMarginX = ctlOK.p_x;
   ctlCancel.p_x = ctlOK.p_x_extent + btnMarginX;
   ctlNextFile.p_x = ctlCancel.p_x_extent + btnMarginW;
   ctlPrevFile.p_x = ctlNextFile.p_x_extent + btnMarginX;
   ctlNextDiff.p_x = ctlPrevFile.p_x_extent + btnMarginW;
   ctlPrevDiff.p_x = ctlNextDiff.p_x_extent + btnMarginX;
   ctlNextInput.p_x = ctlPrevDiff.p_x_extent + btnMarginW;
   ctlPrevInput.p_x = ctlNextInput.p_x_extent + btnMarginX;
   ctlCopyFile.p_x = ctlPrevInput.p_x_extent + btnMarginW;
   ctlFileNameLabel.p_x = ctlRefactoredFileLabel.p_x_extent + btnMarginX;
   ctlFileNameLabel.p_width = _ctlfile1.p_x_extent - ctlFileNameLabel.p_x;

   // slide over copy block, line, and file if input buttons are missing
   newButtonX := ctlCopyFile.p_x;
   if (!ctlNextInput.p_visible && !ctlPrevInput.p_visible) {
      newButtonX = ctlNextInput.p_x;
   }
   if (REFACTOR_RESULTS_REVERSED() && newButtonX < ctlRefactoredFile.p_x) {
      newButtonX = ctlRefactoredFile.p_x;
   }
   ctlCopyFile.p_x = newButtonX;
   ctlCopyBlock.p_x = ctlCopyFile.p_x_extent  + btnMarginX;
   ctlCopyLine.p_x  = ctlCopyBlock.p_x_extent + btnMarginX;

   // resize the editor controls to 75%
   fileContentsHeight := (ctlOK.p_y - ctlOriginalFile.p_y) * 3 intdiv 4;
   fileContentsWidth  := clientWidth - 3 * spacing - vscroll1.p_width;
   ctlOriginalFile.p_height = fileContentsHeight;
   ctlOriginalFile.p_width = fileContentsWidth intdiv 2;

   ctlRefactoredFile.p_x = ctlOriginalFile.p_x_extent + spacing + vscroll1.p_width;
   ctlRefactoredFile.p_height = ctlOriginalFile.p_height;
   ctlRefactoredFile.p_width = ctlOriginalFile.p_width;
   originalFileLabel.p_x = ctlOriginalFile.p_x;
   refactoredFileLabel.p_x = ctlRefactoredFile.p_x;

   // resize and move the scroll bars
   vscroll1.p_height = ctlOriginalFile.p_height;
   vscroll1.p_x = ctlOriginalFile.p_x_extent;
   hscroll1.p_width = fileContentsWidth + vscroll1.p_width + spacing;
   hscroll1.p_y = ctlOriginalFile.p_y_extent;

   // resize the file list (gets last 25%)
   ctlFileListTreeLabel.p_x = ctlOriginalFile.p_x;
   ctlFileListTreeLabel.p_y = ctlOriginalFile.p_y_extent + hscroll1.p_height + spacing;
   ctlFileListTree.p_x = ctlFileListTreeLabel.p_x;
   ctlFileListTree.p_y = ctlFileListTreeLabel.p_y_extent + labelSpacing;
   ctlFileListTree.p_y_extent = ctlOK.p_y - spacing;
   ctlFileListTree.p_width = fileContentsWidth + vscroll1.p_width + spacing;

   // position the line number controls
   _ctlfile1line.p_x = _ctlfile1.p_x_extent - _ctlfile1line.p_width - btnMarginX;
   _ctlfile1line.p_y = hscroll1.p_y_extent + 30;
   _ctlfile2line.p_x = _ctlfile2.p_x_extent - _ctlfile2line.p_width - btnMarginX;
   _ctlfile2line.p_y = _ctlfile1line.p_y;
}

void _refactor_results_form.on_destroy()
{
   // if there are files loaded, get rid of them
   _DiffRemoveWindow(p_active_form, isDiff:false);
   p_active_form.cleanupRefactoringResultsViews();
}

///////////////////////////////////////////////////////////////////////////////
/**
 * Form used for displaying options for standard methods to create for a class
 */
defeventtab _refactor_standard_methods_form;

static int get_value( int methodType, int flags, int mask )
{
   if ( VSREFACTOR_GET_METHOD_FLAGS( flags, methodType ) & mask ) {
      return 1;
   } else {
      return 0;
   }
}

static void set_flag( int &flags, int methodType, int setting, int value )
{
   if ( value ) {
      flags = VSREFACTOR_ENABLE_METHOD_FLAG( flags, methodType, setting );
   } else {
      flags = VSREFACTOR_DISABLE_METHOD_FLAG( flags, methodType, setting );
   }
}

void ctl_ok.lbutton_up()
{
   orig_wid := p_window_id;

   // Grab the dialog settings and build methodsFlags
   methodsFlags := 0;

   set_flag( methodsFlags, VSREFACTOR_METHOD_DEFAULT_CONSTRUCTOR, VSREFACTOR_METHOD_CREATE, ctl_dc.p_value );
   set_flag( methodsFlags, VSREFACTOR_METHOD_DEFAULT_CONSTRUCTOR, VSREFACTOR_METHOD_PUBLIC, ctl_dc_public.p_value );
   set_flag( methodsFlags, VSREFACTOR_METHOD_DEFAULT_CONSTRUCTOR, VSREFACTOR_METHOD_PROTECTED, ctl_dc_protected.p_value );
   set_flag( methodsFlags, VSREFACTOR_METHOD_DEFAULT_CONSTRUCTOR, VSREFACTOR_METHOD_PRIVATE, ctl_dc_private.p_value );

   set_flag( methodsFlags, VSREFACTOR_METHOD_COPY_CONSTRUCTOR, VSREFACTOR_METHOD_CREATE, ctl_cc.p_value );
   set_flag( methodsFlags, VSREFACTOR_METHOD_COPY_CONSTRUCTOR, VSREFACTOR_METHOD_PUBLIC, ctl_cc_public.p_value );
   set_flag( methodsFlags, VSREFACTOR_METHOD_COPY_CONSTRUCTOR, VSREFACTOR_METHOD_PROTECTED, ctl_cc_protected.p_value );
   set_flag( methodsFlags, VSREFACTOR_METHOD_COPY_CONSTRUCTOR, VSREFACTOR_METHOD_PRIVATE, ctl_cc_private.p_value );

   set_flag( methodsFlags, VSREFACTOR_METHOD_ASSIGNMENT_OPERATOR, VSREFACTOR_METHOD_CREATE, ctl_ao.p_value );
   set_flag( methodsFlags, VSREFACTOR_METHOD_ASSIGNMENT_OPERATOR, VSREFACTOR_METHOD_VIRTUAL, ctl_ao_virtual.p_value );
   set_flag( methodsFlags, VSREFACTOR_METHOD_ASSIGNMENT_OPERATOR, VSREFACTOR_METHOD_PUBLIC, ctl_ao_public.p_value );
   set_flag( methodsFlags, VSREFACTOR_METHOD_ASSIGNMENT_OPERATOR, VSREFACTOR_METHOD_PROTECTED, ctl_ao_protected.p_value );
   set_flag( methodsFlags, VSREFACTOR_METHOD_ASSIGNMENT_OPERATOR, VSREFACTOR_METHOD_PRIVATE, ctl_ao_private.p_value );

   set_flag( methodsFlags, VSREFACTOR_METHOD_DESTRUCTOR, VSREFACTOR_METHOD_CREATE, ctl_d.p_value );
   set_flag( methodsFlags, VSREFACTOR_METHOD_DESTRUCTOR, VSREFACTOR_METHOD_VIRTUAL, ctl_d_virtual.p_value );
   set_flag( methodsFlags, VSREFACTOR_METHOD_DESTRUCTOR, VSREFACTOR_METHOD_PUBLIC, ctl_d_public.p_value );
   set_flag( methodsFlags, VSREFACTOR_METHOD_DESTRUCTOR, VSREFACTOR_METHOD_PROTECTED, ctl_d_protected.p_value );
   set_flag( methodsFlags, VSREFACTOR_METHOD_DESTRUCTOR, VSREFACTOR_METHOD_PRIVATE, ctl_d_private.p_value );

   orig_wid.p_active_form._delete_window( methodsFlags );
}

void ctl_cancel.lbutton_up()
{
  p_window_id.p_active_form._delete_window('');
}

void ctl_ok.on_create( _str symbolName, int startSeekPosition, int endSeekPosition, _str className, int existingMethodsFlags )
{
   // Default constructor dialog settings
   ctl_dc_public.p_value = get_value( VSREFACTOR_METHOD_DEFAULT_CONSTRUCTOR, existingMethodsFlags, VSREFACTOR_METHOD_PUBLIC );
   ctl_dc_protected.p_value = get_value( VSREFACTOR_METHOD_DEFAULT_CONSTRUCTOR, existingMethodsFlags, VSREFACTOR_METHOD_PROTECTED );
   ctl_dc_private.p_value = get_value( VSREFACTOR_METHOD_DEFAULT_CONSTRUCTOR, existingMethodsFlags, VSREFACTOR_METHOD_PRIVATE );

   if ( VSREFACTOR_GET_METHOD_FLAGS( existingMethodsFlags, VSREFACTOR_METHOD_DEFAULT_CONSTRUCTOR ) & VSREFACTOR_METHOD_CREATE ) {
      ctl_dc.p_value = 0;
      ctl_dc.p_caption = "Replace Default Constructor";
      if ( VSREFACTOR_GET_METHOD_FLAGS( existingMethodsFlags, VSREFACTOR_METHOD_DEFAULT_CONSTRUCTOR ) & VSREFACTOR_METHOD_REPLACEABLE ) {
         ctl_dc.p_enabled = true;
      }else {
         ctl_dc.p_enabled = false;
      }
   } else {
      ctl_dc.p_value = 1;
      ctl_dc.p_caption = "Create Default Constructor";
      ctl_dc_public.p_value = 1; // Default new methods to public;
   }

   // Copy constructor dialog settings
   ctl_cc_public.p_value = get_value( VSREFACTOR_METHOD_COPY_CONSTRUCTOR, existingMethodsFlags, VSREFACTOR_METHOD_PUBLIC );
   ctl_cc_protected.p_value = get_value( VSREFACTOR_METHOD_COPY_CONSTRUCTOR, existingMethodsFlags, VSREFACTOR_METHOD_PROTECTED );
   ctl_cc_private.p_value = get_value( VSREFACTOR_METHOD_COPY_CONSTRUCTOR, existingMethodsFlags, VSREFACTOR_METHOD_PRIVATE );

   if ( VSREFACTOR_GET_METHOD_FLAGS( existingMethodsFlags, VSREFACTOR_METHOD_COPY_CONSTRUCTOR ) & VSREFACTOR_METHOD_CREATE ) {
      ctl_cc.p_value = 0;
      ctl_cc.p_caption = "Replace Copy Constructor";
      if ( VSREFACTOR_GET_METHOD_FLAGS( existingMethodsFlags, VSREFACTOR_METHOD_COPY_CONSTRUCTOR ) & VSREFACTOR_METHOD_REPLACEABLE ) {
         ctl_cc.p_enabled = true;
      } else {
         ctl_cc.p_enabled = false;
      }
   } else {
      ctl_cc.p_value = 1;
      ctl_cc.p_caption = "Create Copy Constructor";
      ctl_cc_public.p_value = 1; // Default new methods to public;
   }

   // Assignment operator dialog settings
   ctl_ao_virtual.p_value = get_value( VSREFACTOR_METHOD_ASSIGNMENT_OPERATOR, existingMethodsFlags, VSREFACTOR_METHOD_VIRTUAL );
   ctl_ao_public.p_value = get_value( VSREFACTOR_METHOD_ASSIGNMENT_OPERATOR, existingMethodsFlags, VSREFACTOR_METHOD_PUBLIC );
   ctl_ao_protected.p_value = get_value( VSREFACTOR_METHOD_ASSIGNMENT_OPERATOR, existingMethodsFlags, VSREFACTOR_METHOD_PROTECTED );
   ctl_ao_private.p_value = get_value( VSREFACTOR_METHOD_ASSIGNMENT_OPERATOR, existingMethodsFlags, VSREFACTOR_METHOD_PRIVATE );

   if ( VSREFACTOR_GET_METHOD_FLAGS( existingMethodsFlags, VSREFACTOR_METHOD_ASSIGNMENT_OPERATOR ) & VSREFACTOR_METHOD_CREATE ) {
      ctl_ao.p_value = 0;
      ctl_ao.p_caption = "Replace Assignment Operator";
      if ( VSREFACTOR_GET_METHOD_FLAGS( existingMethodsFlags, VSREFACTOR_METHOD_ASSIGNMENT_OPERATOR ) & VSREFACTOR_METHOD_REPLACEABLE ) {
         ctl_ao.p_enabled = true;
      } else {
         ctl_ao.p_enabled = false;
      }
   } else {
      ctl_ao.p_value = 1;
      ctl_ao.p_caption = "Create Assignment Operator";
      ctl_ao_public.p_value = 1; // Default new methods to public;
   }

   // Assignment operator dialog settings
   ctl_d_virtual.p_value = get_value( VSREFACTOR_METHOD_DESTRUCTOR, existingMethodsFlags, VSREFACTOR_METHOD_VIRTUAL );
   ctl_d_public.p_value = get_value( VSREFACTOR_METHOD_DESTRUCTOR, existingMethodsFlags, VSREFACTOR_METHOD_PUBLIC );
   ctl_d_protected.p_value = get_value( VSREFACTOR_METHOD_DESTRUCTOR, existingMethodsFlags, VSREFACTOR_METHOD_PROTECTED );
   ctl_d_private.p_value = get_value( VSREFACTOR_METHOD_DESTRUCTOR, existingMethodsFlags, VSREFACTOR_METHOD_PRIVATE );

   if ( VSREFACTOR_GET_METHOD_FLAGS( existingMethodsFlags, VSREFACTOR_METHOD_DESTRUCTOR ) & VSREFACTOR_METHOD_CREATE ) {
      ctl_d.p_value = 0;
      ctl_d.p_caption = "Replace Destructor";
      if ( VSREFACTOR_GET_METHOD_FLAGS( existingMethodsFlags, VSREFACTOR_METHOD_DESTRUCTOR ) & VSREFACTOR_METHOD_REPLACEABLE ) {
         ctl_d.p_enabled = true;
      } else {
         ctl_d.p_enabled = false;
      }
   } else {
      ctl_d.p_value = 1;
      ctl_d.p_caption = "Create Destructor";
      ctl_d_public.p_value = 1; // Default new methods to public;
   }

   ctl_operation_description.p_caption = "Create standard methods for class '" :+ className :+ "'";
}

///////////////////////////////////////////////////////////////////////////////
/**
 * Form used for displaying options for renaming symbols
 */
defeventtab _refactor_rename_form;

static VS_TAG_BROWSE_INFO RENAME_BROWSE_INFO(...) {
   if (arg()) ctl_rename_overloaded.p_user2=arg(1);
   return ctl_rename_overloaded.p_user2;
}

void ctl_ok.on_create( struct VS_TAG_BROWSE_INFO cm, _str symbolName,
                       int startSeekPosition, int endSeekPosition, _str filename,
                       int isFunction, int isClassFunction )
{
   RENAME_BROWSE_INFO(cm);

   ctl_symbol_name.p_text = symbolName;

   if ( isFunction == 1 ) {
      ctl_rename_overloaded.p_value = 1;
      ctl_rename_overridden.p_value = 1;
      ctl_rename_overridden.p_enabled = false;
   } else {
      ctl_rename_overloaded.p_value    = 0;
      ctl_rename_overridden.p_value    = 0;
      ctl_rename_overloaded.p_enabled  = false;
      ctl_rename_overridden.p_enabled  = false;
   }

   if ( isClassFunction == 0 ) {
      ctl_rename_overridden.p_value = 0;
      ctl_rename_overridden.p_enabled = false;
   }
}

void ctl_rename_overloaded.lbutton_up()
{
   // Disable overridden checkbox with overloaded is checked but make it checked
   // because overloaded implies overridden.
   if ( ctl_rename_overloaded.p_value == 1 ) {
      ctl_rename_overridden.p_value = 1;
      ctl_rename_overridden.p_enabled = false;
   } else {
      ctl_rename_overridden.p_enabled = true;
   }
}

void ctl_cancel.lbutton_up( )
{
   p_window_id.p_active_form._delete_window( '' );
}

void ctl_ok.lbutton_up()
{
   struct VS_TAG_BROWSE_INFO cm = RENAME_BROWSE_INFO();
   orig_wid := p_window_id;
   flags := 0;

   new_name := ctl_symbol_name.p_text;

   if ( cm.member_name == new_name ) {
      ctl_symbol_name._text_box_error("New name needs to be different from old name");
      return;
   }

   if ( !refactor_c_is_valid_id(new_name) ) {
      ctl_symbol_name._text_box_error("New name needs to be a valid identifier");
      return;
   }

   if ( ctl_rename_overridden.p_value == 1 ) {
      flags |= VSREFACTOR_RENAME_VIRTUAL_METHOD_IN_BASE_CLASSES; // Overloaded methods should be renamed
   }

   if ( ctl_rename_overloaded.p_value == 1 ) {
      flags |= VSREFACTOR_RENAME_OVERLOADED_METHODS; // Overloaded methods should be renamed
   }

   orig_wid.p_active_form._delete_window( new_name :+ PATHSEP :+ flags );
   return;
}

///////////////////////////////////////////////////////////////////////////////
/**
 * Form used for displaying options for renaming symbols
 */
defeventtab _refactor_quick_rename_form;

void ctl_ok.on_create( _str symbolName="", _str id_chars="" )
{
   ctl_symbol_name.p_user = symbolName;
   ctl_symbol_name.p_text = symbolName;
   ctl_ok.p_user = id_chars;
}

void ctl_ok.lbutton_up()
{
   orig_wid := p_window_id;
   flags := 0;

   new_name := ctl_symbol_name.p_text;
   _str id_chars = ctl_ok.p_user;

   if ( ctl_symbol_name.p_user == new_name ) {
      ctl_symbol_name._text_box_error("New name needs to be different from old name");
      return;
   }

   id_chars = stranslate(id_chars,'',' ');
   valid := true;
   if (id_chars != '') {
      valid = pos('^['id_chars']+$',new_name,1,'r') == 1;
   } else {
      valid = refactor_c_is_valid_id(new_name);
   }

   if (!valid) {
      ctl_symbol_name._text_box_error("New name needs to be a valid identifier");
   } else {
      orig_wid.p_active_form._delete_window( new_name );
   }
   return;
}

///////////////////////////////////////////////////////////////////////////////
/**
 * Form used for displaying options for C/C++ Parsing and testing parsing
 * of the current file.
 */
defeventtab _refactor_test_parser_form;

static void get_html_test_parser_information(_str file_name)
{
   description := "";
   directory := "";
   _str error = false;

   // first display the current file
   strappend(description, "<DL>\n");
   strappend(description, "<DT><B>Current file:</B></DT>\n");
   strappend(description, "<DD>\n");
   strappend(description, "<TT>"file_name"</TT>");
   if (!file_exists(file_name)) {
      _str currentFileWarning = "Error:  The file '" file_name "' does not exist or has not been saved.";
      strappend(description, "<BR><I><FONT color=red>"currentFileWarning"</FONT></I>\n");
      error = true;
   }
   if (!_LanguageInheritsFrom('c',_Filename2LangId(file_name))) {
      _str currentExtWarning = "Error:  The file '" file_name "' is not a C or C++ source file.";
      strappend(description, "<BR><I><FONT color=red>"currentExtWarning"</FONT></I>\n");
      error = true;
   }
   strappend(description, "</DD>\n");
   projectName := "";
   if (!isEclipsePlugin()) {

      // now display the active project
      strappend(description, "<DT><B>Current workspace:</B>  <A HREF=\"workspace-open\">(Open...)</A></DT>\n");
      strappend(description, "<DD>\n");
      if (_workspace_filename != '') {
         strappend(description, "<TT>"_workspace_filename"</TT>\n");
      } else {
         currentWorkspaceWarning := "Error:  You must open a workspace.";
         strappend(description, "<I><FONT color=red>"currentWorkspaceWarning"</FONT></I>\n");
         error = true;
      }
      strappend(description, "</DD>\n");

      if (isEclipsePlugin()) {
         _eclipse_get_c_project_name_string(projectName);

      } else {
         // figure out which project includes this file
         if (_projectFindFile(_workspace_filename, _project_name, _RelativeToProject(file_name)) != "") {
            projectName = _project_name;
         } else {
            projectName = _WorkspaceFindProjectWithFile(file_name, _workspace_filename, true, true);
         }
      }
      // if no project name, the includes and defines cannot be properly found
      currentProjectWarning := "";
      if (projectName == "") {
         currentProjectWarning = "Warning:  The file '" file_name "' is not in a project in this workspace.";
         if (_project_name != "") {
            projectName = _project_name;
            strappend(currentProjectWarning, "  Attempting to use settings from the current project.");
         }
      }

      // now display the active project
      strappend(description, "<DT><B>Effective project:</B>  <A HREF=\"workspace-properties\">(Change...)</A></DT>\n");
      strappend(description, "<DD>\n");
      if (projectName != '') {
         strappend(description, "<TT>"projectName"</TT><BR>\n");
      }
      if (currentProjectWarning != '') {
         strappend(description, "<I><FONT color=darkorange>"currentProjectWarning"</FONT></I><BR>\n");
      }
      strappend(description, "<BR>\n");
      strappend(description, "</DD>\n");
   }
   // get the #defines and #undefs for this file
   cppDefines := "";
   if (isEclipsePlugin()) {
      _eclipse_get_project_defines_string(cppDefines);
   } else {
      cppDefines = _ProjectGet_AllDefines(file_name, _ProjectHandle(projectName), GetCurrentConfigName());
   }
   // now display the list of defines
   project_edit_command :=  "project-edit 4 ":+projectName;
   strappend(description, "<DT><B>Macro Definitions:</B>");
   if (!isEclipsePlugin()) {
      strappend(description, "<A HREF=\""project_edit_command"\">(Edit...)</A>");
   }
   strappend(description, "</DT>\n");
   if ((isEclipsePlugin())||(projectName != '')) {
      strappend(description, "<DD><PRE>\n");
      directory = parse_next_option(cppDefines);
      while (directory != '') {
         strappend(description, directory"\n");
         directory = parse_next_option(cppDefines);
      }
      strappend(description, "</PRE></DD>\n");
   } else {
      strappend(description, "<DD>\n");
      strappend(description, "<I><FONT color=darkorange>Warning:  No active project.</FONT></I>\n");
      strappend(description, "</DD>\n");
   }

   // get the user includes from the specified project
   _str userIncludes = getDelimitedIncludePath(PATHSEP, file_name, projectName);

   // now display the user defined includes
   strappend(description, "<DT><B>User Include Search Directories:</B>");
   if (!isEclipsePlugin()) {
      strappend(description, "<A HREF=\""project_edit_command"\">(Edit...)</A>");
   }
   strappend(description, "</DT>\n");
   if ((isEclipsePlugin())||(projectName != '')) {
      strappend(description, "<DD><PRE>\n");
      while (userIncludes != '') {
         parse userIncludes with directory (PARSE_PATHSEP_RE),'r' userIncludes;
         if (directory != '') {
            strappend(description, directory"\n");
         }
      }
      strappend(description, "</PRE></DD>\n");
   } else {
      strappend(description, "<DD>\n");
      strappend(description, "<I><FONT color=darkorange>Warning:  No active project.</FONT></I><BR><BR>\n");
      strappend(description, "</DD>\n");
   }

   compiler_name := "";
   if (!isEclipsePlugin()) {
      // now display the active compiler configuration name
      compiler_name = _ProjectGet_ActualCompilerConfigName( _ProjectHandle(projectName) );
      strappend(description, "<DT><B>Active C/C++ Compiler Configuration:</B>");
      strappend(description, "  <A HREF=\""project_edit_command"\">(Change...)</A>");
      strappend(description, "<DD>\n");
      if (compiler_name == '') {
         currentConfigWarning := "Error:  You have not yet selected an active C/C++ compiler configuration.";
         strappend(description, "<I><FONT color=red>"currentConfigWarning"</FONT></I>\n");
         error = true;
      } else {
         strappend(description, compiler_name);
      }
      strappend(description, "</DD>\n");

   }
      // now display the active compiler configuration name
      select_config_command_default := "refactor-options";
      strappend(description, "<DT><B>Default C/C++ Compiler Configuration:</B>");
      strappend(description, "  <A HREF=\"refactor-options\">(Change...)</A></DT>\n");
      strappend(description, "<DD>\n");
      if (def_refactor_active_config == '') {
         currentConfigWarning := "Warning:  You have not yet selected a default C/C++ compiler configuration.";
         strappend(description, "<I><FONT color=darkorange>"currentConfigWarning"</FONT></I>\n");
      } else {
         strappend(description, def_refactor_active_config);
         if (compiler_name == '') compiler_name = def_refactor_active_config;
      }
      strappend(description, "</DD>\n");

      if (compiler_name != '') {
         // get the compiler configuration header file and includes
         headerFile := "";
         sysIncludes := "";
         refactor_get_active_config(headerFile, sysIncludes, _ProjectHandle(projectName));

         // now display the compiler enumlation header file name
         strappend(description, "<DT><B>Compiler Emulation Header File:</B>  <A HREF=\"refactor-options\">(Edit...)</A></DT>\n");
         strappend(description, "<DD>\n");
         strappend(description, "<TT>"headerFile"</TT>");
         strappend(description, "</DD>\n");

         // now display the user defined includes
         strappend(description, "<DT><B>Compiler Include Search Directories:</B>  <A HREF=\"refactor-options\">(Edit...)</A></DT>\n");
         strappend(description, "<DD><PRE>\n");
         while (sysIncludes != '') {
            parse sysIncludes with directory (PARSE_PATHSEP_RE),'r' sysIncludes;
            if (directory != '') {
               strappend(description, directory"\n");
            }
         }
         strappend(description, "</PRE></DD>\n");
      }

      // close off the list and we are DONE
      strappend(description, "</DL>");
      ctl_html.p_text = description;
      ctl_ok.p_enabled = !error;
      ctl_pp.p_enabled = !error;
}
void ctl_ok.on_create(_str file_name='')
{
   error := false;
   ctl_html.p_user = file_name;
   get_html_test_parser_information( file_name );
}
void ctl_ok.lbutton_up()
{
   p_active_form._delete_window('ok');
}
void ctl_pp.lbutton_up()
{
   p_active_form._delete_window('pp');
}
void ctl_copy.lbutton_up()
{
   ctl_html._minihtml_command("copy");
}
void ctl_html.on_change(int reason,_str hrefText)
{
   if ( reason==CHANGE_CLICKED_ON_HTML_LINK ) {
      orig_wid := p_window_id;
      execute(hrefText);
      p_window_id = orig_wid;
      get_html_test_parser_information( ctl_html.p_user );
   }
}
void _refactor_test_parser_form.on_resize()
{

   // enforce a minimum size
   // if the minimum width has not been set, it will return 0
   if (!_minimum_width()) {
      int min_width  = ctl_help.p_x_extent+ctl_ok.p_x*2;
      int min_height = ctl_ok.p_height * 9;
      _set_minimum_size(min_width, min_height);
   }

   // get the active forms client width and height in twips
   clientHeight := p_height;
   clientWidth := p_width;

   int motion_y = clientHeight-ctl_label.p_y-ctl_ok.p_y-ctl_ok.p_height;

   ctl_ok.p_y        += motion_y;
   ctl_pp.p_y        += motion_y;
   ctl_cancel.p_y    += motion_y;
   ctl_copy.p_y      += motion_y;
   ctl_help.p_y      += motion_y;
   ctl_html.p_height += motion_y;
   ctl_html.p_width = clientWidth - ctl_html.p_x*2;
}

///////////////////////////////////////////////////////////////////////////////
/**
 * Form used for canceling
 * or constructor.
 */
defeventtab _refactor_finding_children_form;
void ctl_cancel.lbutton_up()
{
   gcanceled_finding_children=true;
   p_active_form._delete_window('');
}

///////////////////////////////////////////////////////////////////////////////
/**
 * Form used for displaying options for modifiying parameters lists
 */
defeventtab _refactor_modify_params_form;
static _str MP_RETURN_TYPE(...) {
   if (arg()) ctl_ok.p_user=arg(1);
   return ctl_ok.p_user;
}
static _str MP_METHOD_NAME(...) {
   if (arg()) ctl_ok.p_user2=arg(1);
   return ctl_ok.p_user2;
}
static _str MP_PARAMETER_INFO_STRING(...) {
   if (arg()) ctl_cancel.p_user=arg(1);
   return ctl_cancel.p_user;
}


static void get_parameter_info(_str param_info, _str &orig_pos, _str &param_type, _str &param_name, 
                               _str &default_value, _str &refs, _str &old_or_new)
{
   parse param_info with orig_pos "@" param_type "@" param_name "@" default_value "@" refs "@" old_or_new;
}

static _str set_parameter_info(_str orig_pos, _str param_type, _str param_name, _str default_value, _str refs, 
                               _str old_or_new)
{
   param_info :=  orig_pos :+ "@" :+ param_type :+ "@" :+ param_name :+ "@" :+ default_value;
   param_info :+= "@" :+ refs :+ "@" :+ old_or_new;
   return param_info;
}

/**
 * Close or cancel the form without saving
 */
void ctl_cancel.lbutton_up()
{
   p_active_form._delete_window('');
}
/**
 * Create the form and populate it with the given data
 * <p>
 * User info is used on the following controls:
 * <ul>
 * <li>ctl_name -- return type of function
 * <li>ctl_replace -- status < 0 if we cannot replace with a function call
 * <li>ctl_parameter_list -- each item has user info containing it's original name
 * </ul>
 * <p>
 * Each argument is of the form:
 * <pre>
 *    name [tab] return_type [tab] reference [tab] required [newline]
 * </pre>
 *
 * @param method_name      name of extracted method
 * @param return_type      return type of extracted method
 * @param arguments        method arguments, separated by NEWLINE characters
 * @param status           status with respect to replacing function call
 */

/**
 * Validate that the given identifier name is well-formed
 * and not in conflict with any other existing parameters
 * being used. Assumes 3 column tree model. 
 */
static bool refactor_validate_id(int tree_wid, _str new_name, int column)
{
   // check for well-formedness
   if (!refactor_c_is_valid_id(new_name)) {
      _message_box("Expecting a valid identifier name");
      return false;
   }
   // check third column of tree control for matching parameter names
   if (tree_wid) {
      index := tree_wid._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      while (index > 0) {
         caption := tree_wid._TreeGetCaption(index);

         switch (column) {
            case 0: parse caption with caption "\t" . "\t" .; break;
            case 1: parse caption with . "\t" caption "\t" .; break;
            case 2: parse caption with . "\t" . "\t" caption; break;
         }

         if (caption == new_name) {
            _message_box(new_name" is already used as a parameter name.");
            return false;
         }
         index = tree_wid._TreeGetNextSiblingIndex(index);
      }
   }
   // if we get here, the name is ok
   return true;
}

/**
 * Create a parameter declaration for constructing the prototype
 *
 * @param index   index of parameter to create
 */
static _str mp_make_parameter(int index) {
   caption := ctl_parameter_list._TreeGetCaption(index);
   _str type_name,name,default_value;
   parse caption with type_name "\t" name "\t" default_value;
   _str parameter = type_name;
   if (!pos("[(] *[*&] *":+_escape_re_chars(name):+" *[)][\\:\\[\\]]*$", type_name, 1, 'r')) {
      strappend(parameter," ");
      strappend(parameter,name);
   }
   if ( default_value != '' ) {
      parameter :+= '=' :+ default_value;
   }
   return parameter;
}

static _str mp_make_prototype()
{
   numParams := 0;
   result := "";
   result = MP_RETURN_TYPE() :+ ' ' :+ MP_METHOD_NAME() :+ '( ';
   index := ctl_parameter_list._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (index > 0) {
      pic_index := show_children := 0;
      ctl_parameter_list._TreeGetInfo(index, show_children, pic_index);
      if (numParams++ >= 1) result :+= ', ';
      result :+= mp_make_parameter(index);
      index = ctl_parameter_list._TreeGetNextSiblingIndex(index);
   }
   result :+= ' );';

   result = stranslate(result, "\1", "&");
   result = stranslate(result, "&&", "\1");
   return result;
}

void ctl_ok.on_create(_str method_name='', _str parameter_info_string='', bool quick_refactor=false)
{
   ctl_name_label.p_caption = "Method Name: " :+ method_name;
   // set up tree column info
   wid := p_window_id;
   p_window_id=ctl_parameter_list;
   _TreeSetColButtonInfo(0, ctl_parameter_list.p_width intdiv 3, 0, 0, "Type");
   _TreeSetColButtonInfo(1, ctl_parameter_list.p_width intdiv 3, 0, 0, "Argument Name");
   _TreeSetColButtonInfo(2, ctl_parameter_list.p_width intdiv 3, 0, 0, "Default Value");
   _TreeSetColEditStyle(0,TREE_EDIT_TEXTBOX);
   _TreeSetColEditStyle(1,TREE_EDIT_TEXTBOX);
   _TreeSetColEditStyle(2,TREE_EDIT_TEXTBOX);
   p_window_id=wid;

   // update the help link for quick refactorings
   if (quick_refactor) {
      p_active_form.p_caption = "Quick Modify Parameter List";
      p_active_form.p_help="Modify parameter list (Quick Refactoring)";
   }

   // insert each argument the user
   _str return_type;
   typeless num_parameters;
   _str arguments = parameter_info_string;
   parse arguments with num_parameters "@" return_type "$" arguments;

   int n = (int)num_parameters;
   while (n--) {
      line := param_info := "";
      parse arguments with param_info "$" arguments;
      if (param_info != '') {
         position := name := type_name := default_value := refs := new_or_old := "";

         get_parameter_info(param_info, position, type_name, name, default_value, refs, new_or_old);

         line = type_name"\t"name"\t"default_value;

         ctl_parameter_list._TreeAddItem(TREE_ROOT_INDEX, line, TREE_ADD_AS_CHILD, _pic_treecb_blank, _pic_treecb_blank, -1, 0, param_info);
      }
   }

   MP_METHOD_NAME(method_name);
   MP_RETURN_TYPE(return_type);
   MP_PARAMETER_INFO_STRING(parameter_info_string);

   // adjust the tree column widths
   ctl_parameter_list._TreeAdjustColumnWidths(colPaddingTwips: 60);

   // set up the prototype label
   ctl_prototype.p_caption = mp_make_prototype();
}

/**
 * Resize the modify parameters form
 */
void _refactor_modify_params_form.on_resize()
{
   // width/height of OK, Cancel, Help buttons (all are the same)
   button_width  := ctl_ok.p_width;
   button_height := ctl_ok.p_height;
   horz_margin   := ctl_parameter_list.p_x;
   vert_margin   := ctl_name_label.p_y;

   // force size of dialog to remain reasonable
   // if the minimum width has not been set, it will return 0
   if (!_minimum_width()) {
      _set_minimum_size(button_width*4, button_height*10);
   }

   // get the active forms client width and height in twips
   client_height := p_active_form.p_height;
   client_width  := p_active_form.p_width;

   // adjust height of parameter list and prototype, both of which are stretchy
   ctl_parameter_list.p_height = (p_active_form.p_height intdiv 2) - 2*vert_margin - ctl_name_label.p_height;
   ctl_border.p_height = (p_active_form.p_height intdiv 2) - 3*vert_margin - ctl_ok.p_height;

   // lay everything out vertically
   alignControlsVertical(ctl_name_label.p_x,
                         ctl_name_label.p_y,
                         vert_margin,
                         ctl_name_label.p_window_id,
                         ctl_parameter_list.p_window_id,
                         ctl_border.p_window_id,
                         ctl_ok.p_window_id);

   // lay out the control buttons
   alignControlsHorizontal(ctl_ok.p_x, ctl_ok.p_y, ctl_ok.p_x, ctl_ok.p_window_id, ctl_cancel.p_window_id, ctl_help.p_window_id);

   // lay out the control buttons
   alignUpDownListButtons(ctl_parameter_list.p_window_id, 
                          client_width - horz_margin, 
                          ctl_new.p_window_id,
                          ctl_move_parameter_up.p_window_id, 
                          ctl_move_parameter_down.p_window_id,
                          ctl_delete.p_window_id); 

   // adjust the tree column widths
   ctl_parameter_list._TreeAdjustLastColButtonWidth();

   // adjust the width and height of the prototype
   ctl_border.p_width = ctl_parameter_list.p_width;
   ctl_prototype.p_width = ctl_border.p_width - 2*ctl_prototype.p_x;
   ctl_prototype.p_height = ctl_border.p_height - 2*ctl_prototype.p_y;
}

/**
 * Move an item down in the adjoining tree control.
 */
void ctl_move_parameter_down.lbutton_up()
{
   // find the tree control
   while (p_window_id.p_object != OI_TREE_VIEW) p_window_id = p_prev;
   // check the current index and next index
   index := _TreeCurIndex();
   if (index <= 0) return;
   // move the item down one index
   _TreeMoveDown(index);
   // update the prototype
   ctl_prototype.p_caption = mp_make_prototype();
}
/**
 * Move an item up in the adjoining tree control.
 */
void ctl_move_parameter_up.lbutton_up()
{
   // find the tree control
   while (p_window_id.p_object != OI_TREE_VIEW) p_window_id = p_prev;
   // check the current index and next index
   index := _TreeCurIndex();
   if (index <= 0) return;
   // move the item down one index
   _TreeMoveUp(index);
   // update the prototype
   ctl_prototype.p_caption = mp_make_prototype();
}

void ctl_delete.lbutton_up()
{
   // find the tree control
   while (p_window_id.p_object != OI_TREE_VIEW) p_window_id = p_prev;

   index := _TreeCurIndex();
   if (index <= 0) return;

   orig_pos := param_type := param_name := default_value := refs := old_or_new := "";
   _str param_info = _TreeGetUserInfo(index);

   get_parameter_info(param_info, orig_pos, param_type, param_name, default_value, refs, old_or_new);

   if ( refs == "has_refs" ) {
      _message_box("Cannot delete this parameter because it is referenced.");
      return;
   }

   _TreeDelete(index);
   ctl_prototype.p_caption = mp_make_prototype();
}

// Returns 0 if editing is successful. 1 if user canceled.
static int edit_parameter( _str& param_type, _str& param_name, _str& default_value )
{
   _str prompt_result='',new_name=param_name;
   // prompt for a new parameter name
   valid_values := false;
   while (valid_values==false) {
      prompt_result = show('-modal _textbox_form',
                     "New Parameter",  // Form caption
                     0, //flags
                     '',   //use default textbox width
                     'refactor_modify_parameters', //Help item.
                     '',   //Buttons and captions
                     'refactor_modify_parameters', //Retrieve Name
                     'Type:'param_type,
                     'Name:'param_name,
                     'Default Value:'default_value);
      // user cancelled operation
      if (prompt_result == "") return 1;

      param_type     = _param1;
      param_name     = _param2;
      default_value  = _param3;

      // check if response was valid
      new_name=_param2;
      if ( _param1 == '' ) {
         _message_box("Must enter a type");
      } else if (refactor_validate_id(ctl_parameter_list, new_name, 1)) {
         valid_values=true;
         break;
      }
   }

   if (prompt_result=='') {
      return 1;
   }
   if (_param1=='' && _param2=='') {
      return 1;
   }

   return 0;
}

void ctl_new.lbutton_up()
{
   _str param_type='',prompt_result='',param_name='param',default_value='';
   new_name := "param";

   index := ctl_parameter_list._TreeCurIndex();

   int result = edit_parameter(param_type, param_name, default_value);

   int bitmapid = _find_or_add_picture("_sym_constructor.svg");

   if (result == 0) {
      line :=  param_type"\t"param_name"\t"default_value;

      k := ctl_parameter_list._TreeAddItem(TREE_ROOT_INDEX, line, TREE_ADD_AS_CHILD, bitmapid, bitmapid, -1);
      param_info := set_parameter_info( k-1, param_type, param_name, default_value, "no_refs", "new" );

      // Call into C to validate new parameter?
      // Does this new parameter have a naming conflict with any other parameters or variables in
      // the scope of the function?
      ctl_parameter_list._TreeSetUserInfo(k, param_info);
   }

   ctl_prototype.p_caption = mp_make_prototype();
}

/**
 * Allow them to edit parameter names within the tree.
 * The name column is the only editable column.
 */
int ctl_parameter_list.on_change(int reason,int index,int col=-1,_str &text='')
{
   if (index < 0) {
      return 0;
   }

   // extract parameter information
   param_info := "";
   orig_position := "";
   param_type := "";
   param_name := "";
   default_value := "";
   refs := "";
   old_or_new := "";
   if (reason == CHANGE_EDIT_QUERY || reason == CHANGE_OTHER) {
      param_info = ctl_parameter_list._TreeGetUserInfo(index);
      get_parameter_info(param_info, orig_position, param_type, param_name, default_value, refs, old_or_new); 
   }

   if (reason == CHANGE_EDIT_CLOSE) {
      return 0;
   } else if (reason == CHANGE_EDIT_QUERY) {
      // Allow any column of a new parameter to be changed
      // and allows any default_value to be changed.
      if (old_or_new=="new" || col==2) {
         return col;
      }
      _message_box("You cannot edit this value");
      return -1;
   } else if (reason == CHANGE_OTHER && col == 2 && text != "") {
      if (col == 1) {
         param_name = text;
      } else if (col == 2) {
         default_value == text;
      }
      // change name or default value to text entered
      param_info = set_parameter_info(orig_position, param_type, param_name, default_value, refs, old_or_new);
      ctl_parameter_list._TreeSetUserInfo(index, param_info);
      ctl_prototype.p_caption = mp_make_prototype();
   }

   return(0);
}

/**
 * When the OK button is pressed, we return a string containing all
 * the form results.  The string is of the form:
 * <pre>
 *    number of parameters                                  [@]
 *    return_type of function
 *    [$]
 *    original parameter position( 0..numParameters-1)      [@]
 *    parameter type string                                 [@]
 *    parameter name string                                 [@]
 *    default value                                         [@]
 *    has_refs' or 'no_refs'                                [@]
 *    [$]
 *    next parameter's values ( see above )
 * </pre>
 */
void ctl_ok.lbutton_up()
{
   // Take off number of parameters from front of string
   _str old_param_info=MP_PARAMETER_INFO_STRING();
   new_param_info := "";
   return_type := "";

   // Build new list with new num parameters and old return_type
   parse old_param_info with . "@" return_type "$" .;
   new_param_info = ctl_parameter_list._TreeGetNumChildren(TREE_ROOT_INDEX) :+ "@" :+ return_type;

   // create argument list, just a map of parameter names,
   // in order to their original names, skip names that are not marked
   index := ctl_parameter_list._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   default_param := warn_user := false;
   while (index > 0) {
      _str param_info = ctl_parameter_list._TreeGetUserInfo(index);

      _str orig_position, param_type, param_name, default_value, refs, old_or_new;
      // extract parameter information
      get_parameter_info(param_info, orig_position, param_type, param_name, default_value, refs, old_or_new); 

      // If a previous parameter has a default value but we find one later on that
      // does not have a default parameter warn user that default values are going to be taken
      // off and the default value stuck in everywhere.
      if ((default_param == true) && (default_value=="")) {
         warn_user=true;
      }

      if (default_value != "") {
         default_param=true;
      }

      // Grab user info which contains substring pertaining to this parameter and stick it on the
      // end of the string list
      new_param_info :+= "$" :+ param_info;

      index = ctl_parameter_list._TreeGetNextSiblingIndex(index);
   }

   if (warn_user) {
      _str res = _message_box( "Some default values occur before other parameters without default values " :+
                        "so these default values will have to be removed and replaced explicity with their " :+
                        "current default values. Is this OK?","Modifying Parameters", MB_OKCANCEL);

      if (res != IDOK)
         return;
   }
   // that's all folks
   p_active_form._delete_window(new_param_info);
}

///////////////////////////////////////////////////////////////////////////////
/**
 * Form used for displaying options for modifiying parameters lists
 */
defeventtab _refactor_pull_up_form;
static VS_TAG_BROWSE_INFO PULL_UP_BROWSE_INFO(...) {
   if (arg()) ctl_ok.p_user=arg(1);
   return ctl_ok.p_user;
}
static _str PULL_UP_SELECTED_SUPER_CLASS(...) {
   if (arg()) ctl_ok.p_user2=arg(1);
   return ctl_ok.p_user2;
}
// Class Name for Move Field form
static _str PULL_UP_CLASS_NAME(...) {
   if (arg()) ctl_cancel.p_user=arg(1);
   return ctl_cancel.p_user;
}
// File that this class is in
static _str PULL_UP_CLASS_FILE_NAME(...) {
   if (arg()) ctl_super_class_list.p_user=arg(1);
   return ctl_super_class_list.p_user;
}
// File that this class is in
static _str PULL_UP_CLASS_DEF_FILE_NAME(...) {
   if (arg()) ctl_super_class_list.p_user2=arg(1);
   return ctl_super_class_list.p_user2;
}
// File that this class is in
static _str PULL_UP_CLASS_DEF_FILE_DIR(...) {
   if (arg()) ctl_browse_button.p_user=arg(1);
   return ctl_browse_button.p_user;
}
static MemberInfo PULL_UP_MEMBER_INFO(...)[] {
   if (arg()) ctl_help.p_user=arg(1);
   return ctl_help.p_user;
}

void ctl_class_definition_cpp.on_change()
{
   filename := absolute(p_text);
   if ( file_exists(filename) ) {
      PULL_UP_CLASS_DEF_FILE_NAME(filename);
      PULL_UP_CLASS_DEF_FILE_DIR(_strip_filename( filename, 'N' ));
   }
}

void ctl_browse_button.lbutton_up()
{
   wid := p_window_id;

   result := _OpenDialog('-modal',
                         'Select cpp to insert static member declaration', // Title
                         '*.*',                                          // Wild Cards
                         '*.*',                                          // File Filters
                         OFN_FILEMUSTEXIST,                                // OFN flags
                         '.cpp',                                           // Default extension
                         _strip_filename( PULL_UP_CLASS_DEF_FILE_NAME(), 'P' ),       // Initial name
                         PULL_UP_CLASS_DEF_FILE_DIR()                                // Initial directory
                         );

   if ( result=='' ) {
      return;
   }
   result=strip(result,'B','"');

   p_window_id=wid.p_prev;
   ctl_class_definition_cpp.p_text=_strip_filename( result, 'P' );
   PULL_UP_CLASS_DEF_FILE_NAME(result);
   PULL_UP_CLASS_DEF_FILE_DIR(_strip_filename( result, 'N' ));
   return;
}

void ctl_ok.on_create(_str super_class_info, struct VS_TAG_BROWSE_INFO &cm)
{
   _refactor_pull_up_form_initial_alignment();

   typeless num_classes;
   _str super_class, super_class_file_name, class_list = super_class_info;
   parse class_list with num_classes "@" class_list;

   // Assumes that super classes are in order from
   // closest to the original class to the most base class
   int n = num_classes;
   while (n--) {
      parse class_list with super_class "@" super_class_file_name "@" class_list;

      if (super_class != '') {
         ctl_super_class_list._lbadd_item(super_class);
      }
   }

   // Select the first class by default
   PULL_UP_BROWSE_INFO(cm);

   ctl_ok.p_enabled = false;
}


/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _refactor_pull_up_form_initial_alignment()
{
   sizeBrowseButtonToTextBox(ctl_class_definition_cpp, ctl_browse_button, 0, ctl_super_class_list.p_x_extent);
}

/**
 * Resize the Pull Up form
 */

void _refactor_pull_up_form.on_resize()
{
   // width/height of OK, Cancel, Help buttons (all are the same)
   int button_width  = ctl_ok.p_width;
   int button_height = ctl_ok.p_height;
   int horz_margin   = ctl_super_class_list.p_x;
   int vert_margin   = ctl_name_label.p_y;

   // force size of dialog to remain reasonable
   // if the minimum width has not been set, it will return 0
   if (!_minimum_width()) {
      _set_minimum_size(button_width*4, button_height*12);
   }

   int motion_x = p_width  - (ctl_super_class_list.p_x_extent + horz_margin);
   int motion_y = p_height - (ctl_cancel.p_y_extent + vert_margin);

   // adjust vertical movements
   ctl_ok.p_y     += motion_y;
   ctl_cancel.p_y += motion_y;
   ctl_help.p_y   += motion_y;
   ctl_file_to_move_to.p_y += motion_y;
   ctl_class_definition_cpp.p_y += motion_y;
   ctl_class_definition_cpp.p_width += motion_x;
   ctl_browse_button.p_y += motion_y;
   ctl_browse_button.p_x += motion_x;

   ctl_super_class_list.p_width += motion_x;
   ctl_invisible_button.p_x += motion_x;

   ctl_super_class_list.p_height += motion_y;
}

ctl_super_class_list.on_change(int reason)
{
   _str tag_name='', class_to_move_to='', inner_class='', type_name='', tag_file_name='', class_name='',
     signature='', return_type='', arguments='', tag_file='';
   i := tag_flags := line_no := 0;

   class_to_move_to = _lbget_seltext();

   PULL_UP_SELECTED_SUPER_CLASS(class_to_move_to);

   struct VS_TAG_BROWSE_INFO cm = PULL_UP_BROWSE_INFO();
   _str lang = _isEditorCtl()? p_LangId : _Filename2LangId(cm.file_name);
   _str tag_files[] = tags_filenamea( lang );

   _str file_name = tagGetClassFilename( tag_files, class_to_move_to, inner_class, 'c' );

   PULL_UP_CLASS_NAME(class_to_move_to);
   PULL_UP_CLASS_FILE_NAME(file_name);

   _str defFileName = find_class_definition_file(_form_parent(), class_to_move_to, lang);

   // Look for this cpp. If not found then blank out def file name
   if ( file_exists( defFileName ) ) {
      PULL_UP_CLASS_DEF_FILE_NAME(defFileName);
   } else {
      PULL_UP_CLASS_DEF_FILE_NAME(file_name);
   }

   PULL_UP_CLASS_DEF_FILE_DIR(_strip_filename(PULL_UP_CLASS_DEF_FILE_NAME(), 'N'));
   PULL_UP_CLASS_NAME(inner_class);

   // If CLASS_FILE_NAME() is a header file then
   // build a string of the equivalent cpp file in the same directory.
   // See if it exists. If not allow user to choose a new one
   // If blank then don't move static member declaration into a new file
   ctl_class_definition_cpp.p_text = _strip_filename( PULL_UP_CLASS_DEF_FILE_NAME(), 'P' );

   ctl_ok.p_enabled = true;

   return 0;
}

void ctl_ok.lbutton_up()
{
   // that's all folks
   _str super_class_info = PULL_UP_SELECTED_SUPER_CLASS() :+ '@' :+ PULL_UP_CLASS_DEF_FILE_NAME();
   p_active_form._delete_window(super_class_info);
}

void ctl_super_class_list.lbutton_double_click()
{
   // that's all folks
   _str super_class_info = PULL_UP_SELECTED_SUPER_CLASS() :+ '@' :+ PULL_UP_CLASS_DEF_FILE_NAME();
   p_active_form._delete_window(super_class_info);
}

///////////////////////////////////////////////////////////////////////////////
/**
 * Form used for displaying options for modifiying parameters lists
 */
defeventtab _refactor_pull_up_form2;

// Apply the appropriate coloring to members depending on it's status.
// Returns true is their are still unresolved dependencies that must be 
// resolved by the user before continuing refactoring.
bool updateDependencies(int tree_control)
{
   unresolvedDependencies := false;
   int nMember, nDependency, showChildren, flags, newFlags;
   _str membersThatAreDependencies:[] = null;

   // 1. Go through members. 
   //   For each member checked, go through it's dependencies and insert the memberIndex into the hash table.
   nMember = tree_control._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (nMember > 0) {
      // This member is checked. Store it's dependencies in the hash table.
      MemberInfo memberInfo = (MemberInfo)tree_control._TreeGetUserInfo(nMember);
      checked := tree_control._TreeGetCheckState(nMember);
      if (checked != TCB_UNCHECKED) {
         for (nDependency=0; nDependency < memberInfo.dependencies._length(); nDependency++) {
            membersThatAreDependencies:[memberInfo.dependencies[nDependency].memberIndex] = 1;
         }
      }

      nMember = tree_control._TreeGetNextSiblingIndex(nMember);
   }

   // 2. Go through all members.
   //      If the memberIndex of the member is in the hash table and the member is not already checked set it to red.
   //      If the memberIndex of the member is not in the hash table and the member is checked then set it to bold.
   //      Otherwise mark the member as 0 (not bold and not red)
   nMember = ctl_members._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (nMember > 0) {
      MemberInfo memberInfo = (MemberInfo)ctl_members._TreeGetUserInfo(nMember);
      ctl_members._TreeGetInfo(nMember, showChildren, 0, 0, flags);
      checked := ctl_members._TreeGetCheckState(nMember);

      // This member is checked.
      newFlags = flags & TREENODE_HIDDEN;
      if (checked == TCB_CHECKED) {
         newFlags = TREENODE_BOLD;
      // This member is not checked and is a dependency of a checked member. Color red.
      } else if (checked == TCB_UNCHECKED && !membersThatAreDependencies:[memberInfo.memberIndex]._isempty()) {
         newFlags = TREENODE_FORCECOLOR;
         unresolvedDependencies = true;
      }

      // Set the color information for this member.
      ctl_members._TreeSetInfo(nMember, TREE_NODE_LEAF, -1, -1, newFlags);

      nMember = ctl_members._TreeGetNextSiblingIndex(nMember);
   }

   return unresolvedDependencies;
}

void ctl_ok.on_create(_str member_name, int member_line_no, _str class_name, _str super_class, _str members_info, MemberInfo (&memberInfo)[])
{
   ctl_ok.p_enabled = false;

   // set up tree column info
   ctl_members._TreeSetColButtonInfo(0, ctl_members.p_width, 0, 0, "Class Members");

   // For no icon
   int tree_id, selected_member=-1;

   bitmap_function  := tag_get_bitmap_for_type(SE_TAG_TYPE_FUNCTION);
   bitmap_prototype := tag_get_bitmap_for_type(SE_TAG_TYPE_PROTO);
   bitmap_variable  := tag_get_bitmap_for_type(SE_TAG_TYPE_VAR);
   bitmap_class     := tag_get_bitmap_for_type(SE_TAG_TYPE_CLASS);
   bitmap_interface := tag_get_bitmap_for_type(SE_TAG_TYPE_INTERFACE);

   // Set the user info to the index into the the class's typeInfo
   // that this member is located.
   ctl_members._TreeBeginUpdate(TREE_ROOT_INDEX);
   for (i := 0; i < memberInfo._length(); i++) {
      checkState := TCB_UNCHECKED;
      int bitmapid_normal     = _pic_treecb_blank;
      int bitmapid_selected   = _pic_treecb_blank;

      if (memberInfo[i].memberType == 'proto') {
         bitmapid_normal = bitmapid_selected = bitmap_prototype;
      } else if (memberInfo[i].memberType == 'func') {
         bitmapid_normal = bitmapid_selected = bitmap_function;
      } else if (memberInfo[i].memberType == 'var') {
         bitmapid_normal = bitmapid_selected = bitmap_variable;
      } else if (memberInfo[i].memberType == 'class') {
         bitmapid_normal = bitmapid_selected = bitmap_class;
      } else if (memberInfo[i].memberType == 'interface') {
         bitmapid_normal = bitmapid_selected = bitmap_interface;
      }

      if (memberInfo[i].hidden) {
         continue;
      }

      _str line = memberInfo[i].description;

      if (memberInfo[i].description != '') {

         // Is this the member that the user originally selected?
         // If so mark it as checked.
         checked := TCB_UNCHECKED;
         if (memberInfo[i].lineNo == member_line_no && pos(member_name, memberInfo[i].description) != 0) {
            selected_member = i;
            checked = TCB_CHECKED;
         }
         memberInfo[i].treeIndex = ctl_members._TreeAddItem(TREE_ROOT_INDEX, line, TREE_ADD_AS_CHILD, 
                                     bitmapid_normal, bitmapid_selected, TREE_NODE_LEAF, 0, memberInfo[i]);
         ctl_members._TreeSetCheckable(memberInfo[i].treeIndex, 1, 0);
         ctl_members._TreeSetCheckState(memberInfo[i].treeIndex, checked);

      } else {
         memberInfo[i].treeIndex = 0;
      }
   }

   ctl_members._TreeEndUpdate(TREE_ROOT_INDEX);

   PULL_UP_MEMBER_INFO = memberInfo;

 //  say("memberInfoList length="memberInfo._length());
 //  for (i = 0; i < memberInfo._length(); i++) {
 //     say("memberInfoList description"memberInfo[i].description);
 //     say("    fileName="memberInfo[i].fileName);
 //     say("    memberIndex="memberInfo[i].memberIndex);
 //     say("    memberName="memberInfo[i].memberName);
 //     say("    memberType="memberInfo[i].memberType);
 //     say("    num dependencies="memberInfo[i].dependencies._length());
 //     for (j = 0; j < memberInfo[i].dependencies._length(); j++) {
 //        say("          dependency="memberInfo[i].dependencies[j].symbolName);
 //        say("              defFilename="memberInfo[i].dependencies[j].defFilename);
 //        say("              defSeekPos="memberInfo[i].dependencies[j].defSeekPosition);
 //        say("              description="memberInfo[i].dependencies[j].description);
 //        say("              isAGlobal="memberInfo[i].dependencies[j].isAGlobal);
 //        say("              memberIndex="memberInfo[i].dependencies[j].memberIndex);
 //        say("              crossDependencyMemberIndex="memberInfo[i].dependencies[j].crossDependencyMemberIndex);
 //     }
 //  }


   ctl_class_member_description.p_caption = "Move members from class '"class_name"' to class '"super_class"'";
   // Select the first class by default
//   ctl_members._TreeAdjustLastColButtonWidth();
   ctl_members._TreeAdjustColumnWidths(0);

   // Update dependencies
   if (selected_member != -1) {
      ctl_dependencies._TreeBeginUpdate(TREE_ROOT_INDEX, "T");
      ctl_dependencies._TreeDelete(TREE_ROOT_INDEX, "C");

      // Add dependencies for the initial item to the list.
      for (i = 0; i < memberInfo[selected_member].dependencies._length(); i++) {
         _str descrip = memberInfo[selected_member].dependencies[i].description;

         tree_id = ctl_dependencies._TreeAddItem(TREE_ROOT_INDEX, descrip, 
                                                 TREE_ADD_AS_CHILD, 0, 0, -1, 0,
                                                 memberInfo[selected_member].dependencies[i]);
      }
      ctl_dependencies._TreeEndUpdate(TREE_ROOT_INDEX);
   }
 
   unresolvedDependencies := updateDependencies(ctl_members);

   // Don't let the person leave if there are still dependencies that have not been checked.
   if (unresolvedDependencies == true) {
      ctl_ok.p_enabled = false;
   } else {
      ctl_ok.p_enabled = true;
   }
}

/**
 * Resize the Pull Up form
 */

void _refactor_pull_up_form2.on_resize()
{
   // width/height of OK, Cancel, Help buttons (all are the same)
   int button_width  = ctl_ok.p_width;
   int button_height = ctl_ok.p_height;
   int horz_margin   = ctl_members.p_x;
   int vert_margin   = ctl_class_member_description.p_y;

   // force size of dialog to remain reasonable
   // if the minimum width has not been set, it will return 0
   if (!_minimum_width()) {
      _set_minimum_size(button_width*4, button_height*12);
   }

   // get the active forms client width and height in twips
   client_height := p_height;
   client_width := p_width;

   int motion_x = client_width  - ctl_members.p_width - ctl_members.p_x - horz_margin;
   int motion_y = client_height - ctl_cancel.p_y - ctl_cancel.p_height - vert_margin;

   // client height minus everything but the tree controls.
   int trees_vertical_space = client_height - ctl_class_member_description.p_height;
   trees_vertical_space -= ctl_dependencies_description.p_height;
   trees_vertical_space -= ctl_ok.p_height;
   trees_vertical_space -= vert_margin*2;
   trees_vertical_space -= 200;

   // adjust vertical movements
   ctl_members.p_height = trees_vertical_space intdiv 2;
   ctl_dependencies.p_height = trees_vertical_space intdiv 2;
   ctl_ok.p_y     = client_height - vert_margin - ctl_ok.p_height + 100;
   ctl_cancel.p_y = client_height - vert_margin - ctl_ok.p_height + 100;
   ctl_help.p_y   = client_height - vert_margin - ctl_ok.p_height + 100;
   ctl_dependencies_description.p_y = ctl_members.p_y_extent + 100;
   ctl_dependencies.p_y = ctl_dependencies_description.p_y_extent;

   ctl_members.p_width += motion_x;
   ctl_dependencies.p_width += motion_x;

   // adjust the tree column widths
   ctl_members._TreeAdjustLastColButtonWidth();
   ctl_dependencies._TreeAdjustLastColButtonWidth();
}

void ctl_members.on_change(int reason,int index,int col=-1,_str &text='')
{
   int i, j, nDependency, memberShowChildren, treeIndex, tree_id, showChildren, moreFlags;

   if (reason != CHANGE_EXPANDED && reason != CHANGE_COLLAPSED && reason != CHANGE_SELECTED && reason != CHANGE_CHECK_TOGGLED) {
      return;
   }

   ctl_dependencies._TreeBeginUpdate(TREE_ROOT_INDEX, "T");
   ctl_dependencies._TreeDelete(TREE_ROOT_INDEX, "C");

   MemberInfo memberInfo = (MemberInfo)ctl_members._TreeGetUserInfo(index);

   // Add dependencies for current selection to list.
   for (i = 0; i < memberInfo.dependencies._length(); i++) {
      _str descrip = memberInfo.dependencies[i].description;

      tree_id = ctl_dependencies._TreeAddItem(TREE_ROOT_INDEX, descrip, 
                                              TREE_ADD_AS_CHILD, 0, 0, -1, 0,
                                              memberInfo.dependencies[i]);
   }
   ctl_dependencies._TreeEndUpdate(TREE_ROOT_INDEX);
   

   unresolvedDependencies := updateDependencies(ctl_members);

   // Don't let the person leave if there are still dependencies that have not been checked.
   if (unresolvedDependencies == true) {
      ctl_ok.p_enabled = false;
   } else {
      ctl_ok.p_enabled = true;
   }

   // Change current selection to the item that was just checked/unchecked.
   if (reason == CHANGE_EXPANDED || reason == CHANGE_COLLAPSED || reason==CHANGE_CHECK_TOGGLED) {
      ctl_members._TreeSetCurIndex(index);
   }
}

void ctl_ok.lbutton_up()
{
   int members_to_move[] = null;
   int i, show_children, node_index;
   has_global_dependency := false;

   // Go through tree items finding the nodes that are expanded(checked) and 
   // add them to the list of members to be moved.
   node_index = ctl_members._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (node_index > 0) {

      // This the the member info class. Member index is the index into the type info
      // for the original class for this member.
      MemberInfo member_info = (MemberInfo)ctl_members._TreeGetUserInfo(node_index);

      // Expanded in our implementation means checked
      checked := ctl_members._TreeGetCheckState(node_index);
      if (checked == TCB_CHECKED) {
         members_to_move[ members_to_move._length() ] = member_info.memberIndex;
         for (i = 0 ; i < member_info.dependencies._length(); i++) {
            if (member_info.dependencies[i].isAGlobal) {
               has_global_dependency = true;
               break;
            }
         }
      }

      node_index = ctl_members._TreeGetNextIndex(node_index);
   }

   // Turn array into string so that it can be passed back from dialog
   // and can be passed into refactoring C code.
   _str s_members_to_move = members_to_move._length() :+ '@';
   for (i = 0; i < members_to_move._length(); i++) {
      s_members_to_move :+= members_to_move[i] :+ '@';
   }

   if (has_global_dependency) {
      int result = _message_box("At least one member to be moved is dependent on a global variable or function.\n" :+
                   "This might cause a compile error if this is not accessible in the member's new location.\n" :+
                   "Do you want to continue?","Pull Up", MB_OK | MB_OKCANCEL);
      if (result == IDCANCEL) {
         return; 
      }
   }

   if (members_to_move._length() == 0) {
      p_active_form._delete_window('');
   }

   // that's all folks
   p_active_form._delete_window(s_members_to_move);
}

///////////////////////////////////////////////////////////////////////////////
/**
 * Form used for displaying options for modifiying parameters lists
 */
defeventtab _refactor_push_down_form;
static VS_TAG_BROWSE_INFO PUSH_DOWN_BROWSE_INFO(...) {
   if (arg()) ctl_ok.p_user=arg(1);
   return ctl_ok.p_user;
}
static _str PUSH_DOWN_SELECTED_DERIVED_CLASS(...) {
   if (arg()) ctl_ok.p_user2=arg(1);
   return ctl_ok.p_user2;
}
// Class Name for Move Field form
static _str PUSH_DOWN_CLASS_NAME(...) {
   if (arg()) ctl_cancel.p_user=arg(1);
   return ctl_cancel.p_user;
}
static _str PUSH_DOWN_DERIVED_CLASS_LIST(...)[] {
   if (arg()) ctl_cancel.p_user2=arg(1);
   return ctl_cancel.p_user2;
}

// File that this class is in
static _str PUSH_DOWN_CLASS_FILE_NAME(...) {
   if (arg()) ctl_derived_class_list.p_user=arg(1);
   return ctl_derived_class_list.p_user;
}
// File that this class is in
static _str PUSH_DOWN_CLASS_DEF_FILE_NAME(...) {
   if (arg()) ctl_derived_class_list.p_user2=arg(1);
   return ctl_derived_class_list.p_user2;
}
// File that this class is in
static _str PUSH_DOWN_CLASS_DEF_FILE_DIR(...) {
   if (arg()) ctl_help.p_user=arg(1);
   return ctl_help.p_user;
}
static MemberInfo PUSH_DOWN_MEMBER_INFO(...)[] {
   if (arg()) ctl_help.p_user2=arg(1);
   return ctl_help.p_user2;
}

void ctl_class_definition_cpp.on_change()
{
   filename := absolute(p_text);
   if ( file_exists(filename) ) {
      PUSH_DOWN_CLASS_DEF_FILE_NAME(filename);
      PUSH_DOWN_CLASS_DEF_FILE_DIR(_strip_filename( filename, 'N' ));
   }
}

void ctl_ok.on_create(struct VS_TAG_BROWSE_INFO (&children)[], struct VS_TAG_BROWSE_INFO &cm)
{
   ctl_ok.p_enabled = false;

   int i;
   for (i = 0; i < children._length(); i++) {
      ctl_derived_class_list._lbadd_item(children[i].member_name);
   }

   PUSH_DOWN_BROWSE_INFO(cm);
}

/**
 * Resize the Push down form
 */

void _refactor_push_down_form.on_resize()
{
   // width/height of OK, Cancel, Help buttons (all are the same)
   int button_width  = ctl_ok.p_width;
   int button_height = ctl_ok.p_height;
   int horz_margin   = ctl_derived_class_list.p_x;
   int vert_margin   = ctl_name_label.p_y;

   // force size of dialog to remain reasonable
   // if the minimum width has not been set, it will return 0
   if (!_minimum_width()) {
      _set_minimum_size(button_width*4, button_height*12);
   }

   // get the active forms client width and height in twips
   client_height := p_height;
   client_width := p_width;

   int motion_x = client_width  - ctl_invisible_button.p_x /*- ctl_invisible_button.p_width*/  - horz_margin;
   int motion_y = client_height - ctl_cancel.p_y - ctl_cancel.p_height - vert_margin;

   // adjust vertical movements
   ctl_ok.p_y     += motion_y;
   ctl_cancel.p_y += motion_y;
   ctl_help.p_y   += motion_y;

   ctl_derived_class_list.p_width = client_width - horz_margin*2;
   ctl_invisible_button.p_x += motion_x;
   ctl_derived_class_list.p_y_extent = client_height - ctl_ok.p_height - 50;
}

ctl_derived_class_list.on_change(int reason)
{
   _str tag_name='', class_to_move_to='', inner_class='', type_name='', tag_file_name='', class_name='',
     signature='', return_type='', arguments='', tag_file='';
   i := tag_flags := line_no := 0;

   class_to_move_to = _lbget_seltext();

   PUSH_DOWN_SELECTED_DERIVED_CLASS(class_to_move_to);

   struct VS_TAG_BROWSE_INFO cm = PUSH_DOWN_BROWSE_INFO();
   _str lang = _isEditorCtl()? p_LangId : _Filename2LangId(cm.file_name);
   _str tag_files[] = tags_filenamea( lang );

   _str file_name = tagGetClassFilename( tag_files, class_to_move_to, inner_class, 'c' );

   PUSH_DOWN_CLASS_NAME(class_to_move_to);
   PUSH_DOWN_CLASS_FILE_NAME(file_name);

  _str defFileName = find_class_definition_file(_form_parent(), class_to_move_to, lang);

   // Look for this cpp. If not found then blank out def file name
   if ( file_exists( defFileName ) ) {
      PUSH_DOWN_CLASS_DEF_FILE_NAME(defFileName);
   } else {
      PUSH_DOWN_CLASS_DEF_FILE_NAME(file_name);
   }

   PUSH_DOWN_CLASS_DEF_FILE_DIR(_strip_filename(PUSH_DOWN_CLASS_DEF_FILE_NAME(), 'N'));
   PUSH_DOWN_CLASS_NAME(inner_class);

   ctl_ok.p_enabled = true;

   return 0;
}

void ctl_ok.lbutton_up()
{
   // that's all folks
   _str derived_class_info = PUSH_DOWN_SELECTED_DERIVED_CLASS();
   p_active_form._delete_window(derived_class_info);
}

void ctl_derived_class_list.lbutton_double_click()
{
   // that's all folks
   _str derived_class_info = PUSH_DOWN_SELECTED_DERIVED_CLASS();
   p_active_form._delete_window(derived_class_info);
}

///////////////////////////////////////////////////////////////////////////////
/**
 * Form used for displaying options for modifiying parameters lists
 */
defeventtab _refactor_push_down_form2;
static int PUSH_DOWN_DERIVED_CLASS_DEF_SELECTED(...)[] {
   if (arg()) ctl_classes.p_user=arg(1);
   return ctl_classes.p_user;
}
static int PUSH_DOWN_TRANSACTION_HANDLE(...) {
   if (arg()) ctl_classes.p_user2=arg(1);
   return ctl_classes.p_user2;
}
static _str PUSH_DOWN_DERIVED_CLASS_DEF_FILENAME_LIST(...)[] {
   if (arg()) ctl_members.p_user=arg(1);
   return ctl_members.p_user;
}
static bool PUSH_DOWN_REFERRED_CLASSES(...)[] {
   if (arg()) ctl_members.p_user2=arg(1);
   return ctl_members.p_user2;
}

void ctl_ok.on_create(_str member_name, int member_line_no, int handle, _str class_name, _str derived_class, 
                      struct MemberInfo memberInfo[], _str derived_class_list[], _str ext, _str fallback_classfile)
{
   int tree_id, selected_member = -1;
   ctl_ok.p_enabled = false;

   PUSH_DOWN_TRANSACTION_HANDLE(handle);
   PUSH_DOWN_DERIVED_CLASS_LIST(derived_class_list);
   PUSH_DOWN_CLASS_NAME(class_name);
   PUSH_DOWN_SELECTED_DERIVED_CLASS( derived_class);

   // set up tree column info
   ctl_members._TreeSetColButtonInfo(0, ctl_members.p_width, 0, 0, "Class Members");

   // For no icon
   bitmap_function  := tag_get_bitmap_for_type(SE_TAG_TYPE_FUNCTION);
   bitmap_prototype := tag_get_bitmap_for_type(SE_TAG_TYPE_PROTO);
   bitmap_variable  := tag_get_bitmap_for_type(SE_TAG_TYPE_VAR);
   bitmap_class     := tag_get_bitmap_for_type(SE_TAG_TYPE_CLASS);
   bitmap_interface := tag_get_bitmap_for_type(SE_TAG_TYPE_INTERFACE);
   int bitmap_stop = _find_or_add_picture("_f_stop.svg");
   set_name_info(bitmap_stop, "This symbol can not be moved");

   ctl_members._TreeBeginUpdate(TREE_ROOT_INDEX);
   int i, nMember;
   for (nMember = 0; nMember < memberInfo._length(); nMember++) {
      int bitmapid_normal     = _pic_treecb_blank;
      int bitmapid_selected   = _pic_treecb_blank;

      if (memberInfo[nMember].explicitRefOutsideClass == true) {
         bitmapid_normal = bitmapid_selected = bitmap_stop;
      } else if (memberInfo[nMember].memberType == 'proto') {
         bitmapid_normal = bitmapid_selected = bitmap_prototype;
      } else if (memberInfo[nMember].memberType == 'func') {
         bitmapid_normal = bitmapid_selected = bitmap_function;
      } else if (memberInfo[nMember].memberType == 'var') {
         bitmapid_normal = bitmapid_selected = bitmap_variable;
      } else if (memberInfo[nMember].memberType == 'class') {
         bitmapid_normal = bitmapid_selected = bitmap_class;
      } else if (memberInfo[nMember].memberType == 'interface') {
         bitmapid_normal = bitmapid_selected = bitmap_interface;
      }     

      if (memberInfo[nMember].hidden) {
         continue;
      }

      if (memberInfo[nMember].description != '') {

         // Is this the member that the user originally selected?
         // If so mark it as checked.
         // Set the user info to the index into the the class's typeInfo
         // that this member is located.
         checked := TCB_UNCHECKED;
         if (memberInfo[nMember].lineNo == member_line_no && pos(member_name, memberInfo[nMember].description) != 0 &&
                        !memberInfo[nMember].explicitRefOutsideClass) {
            selected_member = nMember;
            checked = TCB_CHECKED;
         }
         memberInfo[nMember].treeIndex = ctl_members._TreeAddItem(TREE_ROOT_INDEX, memberInfo[nMember].description, TREE_ADD_AS_CHILD, 
                                                                  bitmapid_normal, bitmapid_selected, TREE_NODE_LEAF, 0,
                                                                  memberInfo[nMember]);
         ctl_members._TreeSetCheckable(memberInfo[nMember].treeIndex, 1, 0);
         ctl_members._TreeSetCheckState(memberInfo[nMember].treeIndex, checked);
      }
   }
   ctl_members._TreeEndUpdate(TREE_ROOT_INDEX);

   ctl_class_member_description.p_caption = "Move members from class '"class_name"' to class '"derived_class"'";
   // Select the first class by default
//   _str caption = ctl_members._TreeGetCaption(1);
//   ctl_members._TreeAdjustLastColButtonWidth();
   ctl_members._TreeAdjustColumnWidths(0);

   ctl_classes._TreeSetColButtonInfo(0, ctl_classes.p_width intdiv 2, 0, 0, "Class");
   ctl_classes._TreeSetColButtonInfo(1, ctl_classes.p_width intdiv 2, 0, 0, "Filename");

   _str class_def_filename_list[] = null;
   int class_def_selected[] = null;
   for (i=0; i < derived_class_list._length(); i++) {
      _str class_def_file = find_class_definition_file(_form_parent(), derived_class_list[i], ext);

      // Could not find a file to stick the definition in. Default to original file.
      if (class_def_file == "") {
         class_def_file = fallback_classfile;
      }
      class_def_filename_list[class_def_filename_list._length()] = class_def_file;
      if (derived_class == derived_class_list[i]) {
         class_def_selected[class_def_selected._length()] = 1;
      } else {
         class_def_selected[class_def_selected._length()] = 0;
      }
   }

   // Update dependencies
   if (selected_member != -1) {
      ctl_dependencies._TreeBeginUpdate(TREE_ROOT_INDEX, "T");
      ctl_dependencies._TreeDelete(TREE_ROOT_INDEX, "C");

      // Add dependencies for the initial item to the list.
      for (i = 0; i < memberInfo[selected_member].dependencies._length(); i++) {
         _str descrip = memberInfo[selected_member].dependencies[i].description;

         tree_id = ctl_dependencies._TreeAddItem(TREE_ROOT_INDEX, descrip, 
                                                 TREE_ADD_AS_CHILD, 0, 0, -1, 0,
                                                 memberInfo[selected_member].dependencies[i]);
      }
      ctl_dependencies._TreeEndUpdate(TREE_ROOT_INDEX);
   }
 
   unresolvedDependencies := updateDependencies(ctl_members);

   // Don't let the person leave if there are still dependencies that have not been checked.
   if (unresolvedDependencies == true) {
      ctl_ok.p_enabled = false;
   } else {
      ctl_ok.p_enabled = true;
   }

   PUSH_DOWN_DERIVED_CLASS_DEF_FILENAME_LIST(class_def_filename_list);
   PUSH_DOWN_DERIVED_CLASS_DEF_SELECTED(class_def_selected);
   PUSH_DOWN_MEMBER_INFO(memberInfo);
}

void refresh_class_list()
{
   bool referred[] = PUSH_DOWN_REFERRED_CLASSES();
   _str derived_classes[] = PUSH_DOWN_DERIVED_CLASS_LIST();
   int class_def_selected[] = PUSH_DOWN_DERIVED_CLASS_DEF_SELECTED();

   // Display classes that will be moved to.
   // Need to remember if a previous class had been checked??
   // Color red if need to be checked?
   ctl_classes._TreeBeginUpdate(TREE_ROOT_INDEX, "T");
   ctl_classes._TreeDelete(TREE_ROOT_INDEX, "C");
   for (i := 0; i < derived_classes._length(); i++) {
      // Skip original class
      if (derived_classes[i] == PUSH_DOWN_CLASS_NAME()) continue;

      // If this class refers to this member or this class happens to be the original target class
      // then stick it in the list.
      if (referred[i] || (derived_classes[i] == PUSH_DOWN_SELECTED_DERIVED_CLASS())) {
         _str def_filename[] = PUSH_DOWN_DERIVED_CLASS_DEF_FILENAME_LIST();
         if (i < derived_classes._length() && i < def_filename._length() && i < class_def_selected._length()) {
            line :=  derived_classes[i] :+ "\t" :+ def_filename[i] :+ "\t" :+ class_def_selected[i];
            nodeIndex := ctl_classes._TreeAddItem(TREE_ROOT_INDEX, line, TREE_ADD_AS_CHILD, -1, -1, class_def_selected[i], class_def_selected[i]? TREENODE_BOLD : TREENODE_FORCECOLOR, i);
            ctl_classes._TreeSetCheckable(nodeIndex, 1, 0);
            ctl_classes._TreeSetCheckState(nodeIndex, class_def_selected[i]? TCB_CHECKED:TCB_UNCHECKED);
         }
      }
   }
   ctl_classes._TreeEndUpdate(TREE_ROOT_INDEX);
}

void ctl_browse_class_def.lbutton_up()
{
   _str derived_classes[] = PUSH_DOWN_DERIVED_CLASS_LIST();

   wid := p_window_id;

   treeIndex := ctl_classes._TreeCurIndex();
   if (treeIndex <= 0) {
      return;
   }

   int index = ctl_classes._TreeGetUserInfo(treeIndex);

   _str def_filename[] = PUSH_DOWN_DERIVED_CLASS_DEF_FILENAME_LIST();

   result := _OpenDialog('-modal',
                         'Select cpp to insert members', // Title
                         '*.*',                                          // Wild Cards
                         '*.*',                                          // File Filters
                         OFN_FILEMUSTEXIST,                                // OFN flags
                         '.cpp',                                           // Default extension
                         _strip_filename( def_filename[index], 'P' ),       // Initial name
                         _strip_filename( def_filename[index], 'N' )                            // Initial directory
                         );

   if (result=='') {
      return;
   }

   found := false;
   refactor_c_push_down_find_class_in_file(PUSH_DOWN_TRANSACTION_HANDLE(), derived_classes[index], result, found);

   p_window_id=wid.p_prev;

   if (!found) {
      _message_box("Cannot move to file that does not refer to destination class", "Push Down");
      return;
   }

   def_filename[index] = result;
   PUSH_DOWN_DERIVED_CLASS_DEF_FILENAME_LIST(def_filename);

   refresh_class_list();
}

void _refactor_push_down_form2.on_resize()
{
   // width/height of OK, Cancel, Help buttons (all are the same)
   int button_width  = ctl_ok.p_width;
   int button_height = ctl_ok.p_height;
   int horz_margin   = ctl_members.p_x;
   int vert_margin   = ctl_class_member_description.p_y;

   // force size of dialog to remain reasonable
   // if the minimum width has not been set, it will return 0
   if (!_minimum_width()) {
      _set_minimum_size(button_width*4, button_height*12);
   }

   // get the active forms client width and height in twips
   client_height := p_height;
   client_width := p_width;

   int motion_x = client_width  - ctl_members.p_width - ctl_members.p_x - horz_margin - 250;
   int motion_y = client_height - ctl_cancel.p_y - ctl_cancel.p_height - vert_margin;

   // client height minus everything but the tree controls.
   int trees_vertical_space = client_height - ctl_class_member_description.p_height;
   trees_vertical_space -= ctl_dependencies_description.p_height;
   trees_vertical_space -= ctl_dependencies_label.p_height;
   trees_vertical_space -= ctl_ok.p_height;
   trees_vertical_space -= vert_margin*2;
   trees_vertical_space -= 200;

   // adjust vertical movements
   ctl_members.p_height = trees_vertical_space intdiv 3;
   ctl_classes.p_height = trees_vertical_space intdiv 3;
   ctl_dependencies.p_height = trees_vertical_space intdiv 3;

   ctl_ok.p_y     = client_height - vert_margin - ctl_ok.p_height + 100;
   ctl_cancel.p_y = client_height - vert_margin - ctl_ok.p_height + 100;
   ctl_help.p_y   = client_height - vert_margin - ctl_ok.p_height + 100;
   ctl_dependencies_label.p_y = ctl_members.p_y + ctl_classes.p_height + 100;
   ctl_dependencies_description.p_y = ctl_dependencies_label.p_y_extent + 
                              ctl_dependencies.p_height + 100;
   ctl_dependencies.p_y = ctl_dependencies_label.p_y_extent;
   ctl_classes.p_y = ctl_dependencies_description.p_y_extent;

   ctl_members.p_width += motion_x;
   ctl_classes.p_width += motion_x;
   ctl_dependencies.p_width += motion_x;
   sizeBrowseButtonToTextBox(ctl_dependencies_description.p_window_id, ctl_browse_class_def.p_window_id, 0, ctl_classes.p_x_extent);

   // adjust the tree column widths
   ctl_members._TreeAdjustLastColButtonWidth();
   ctl_classes._TreeAdjustLastColButtonWidth();
}

void ctl_members.on_change(int reason,int index,int col=-1,_str &text='')
{
   int i, j, tree_id, showChildren, moreFlags;

   _str derived_classes[] = PUSH_DOWN_DERIVED_CLASS_LIST();

   // On selection change show selection's dependencies

   // Create and initialize list of bools indicating whether this class needs to have
   // members pushed to it.
   bool referred[]=null;
   for (i = 0; i < derived_classes._length(); i++) {
      referred[i] = false;
   }

   i = ctl_members._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (i > 0) {
      MemberInfo memberInfo = (MemberInfo)ctl_members._TreeGetUserInfo(i);
      ctl_members._TreeGetInfo(i, showChildren, 0, 0, moreFlags);

      // Go through reference list to see if this member is used referred to by any
      // of the derived classes.
      if (showChildren == 0) {
         for (j = 0; j < memberInfo.referred_to_in_class._length(); j++) {
            if (memberInfo.referred_to_in_class[j] > 0) {
               referred[j] = true;
            }
         }
      }
      i = ctl_members._TreeGetNextSiblingIndex(i);
   }

   if (reason == CHANGE_EXPANDED || reason == CHANGE_COLLAPSED || reason == CHANGE_SELECTED) {
      ctl_dependencies._TreeBeginUpdate(TREE_ROOT_INDEX, "T");
      ctl_dependencies._TreeDelete(TREE_ROOT_INDEX, "C");

      MemberInfo memberInfo = (MemberInfo)ctl_members._TreeGetUserInfo(index);

//     if (memberInfo.explicitRefOutsideClass == true) {
//         say("explicit ref outside class index = "index);
//         ctl_members._TreeSetInfo(index, 1, -1, -1, 0);
//         return;
//      }
      // Add dependencies for current selection to list.
      for (i = 0; i < memberInfo.dependencies._length(); i++) {
         _str descrip = memberInfo.dependencies[i].description;

         tree_id = ctl_dependencies._TreeAddItem(TREE_ROOT_INDEX, descrip, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF, 0, memberInfo.dependencies[i]);
      }
      ctl_dependencies._TreeEndUpdate(TREE_ROOT_INDEX);
   }

   unresolvedDependencies := updateDependencies(ctl_members);

   // If any of the classes that are listed are not checked then don't let the user leave.
   int treeIndex;
   classUnchecked := false;
   i = ctl_classes._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (i > 0) {
      ctl_classes._TreeGetInfo(i, showChildren, 0, 0, moreFlags);

      if (showChildren == 0) {
         classUnchecked = true;
         break;
      }
      i = ctl_classes._TreeGetNextSiblingIndex(i);
   }

   // Don't let the user leave if there are still dependencies that have not been checked.
   if (unresolvedDependencies == true || classUnchecked == true) {
      ctl_ok.p_enabled = false;
   } else {
      ctl_ok.p_enabled = true;
   }

   // Change current selection to the item that was just checked/unchecked.
   if (reason == CHANGE_EXPANDED || reason == CHANGE_COLLAPSED || reason==CHANGE_CHECK_TOGGLED) {
      ctl_members._TreeSetCurIndex(index);
   }

   PUSH_DOWN_REFERRED_CLASSES(referred);

   refresh_class_list();
}

void ctl_classes.on_change(int reason,int tree_index,int col=-1,_str &text='')
{
   if (tree_index < 0) {
      return;
   }

   int i, class_def_selected[] = PUSH_DOWN_DERIVED_CLASS_DEF_SELECTED();

   int showChildren, moreFlags;
   // Need to keep track of checked state of each potential derived class so that when going from
   // member to member and the class list changes that the derived classes selected will be remembered.
   ctl_classes._TreeGetInfo(tree_index, showChildren, 0, 0, moreFlags);
   int index = ctl_classes._TreeGetUserInfo(tree_index);
   if (index < 0) {
      return;
   }

   if (reason == CHANGE_COLLAPSED) {
      class_def_selected[index] = 0;
   } else if (reason == CHANGE_EXPANDED) {
      class_def_selected[index] = 1;
   } else if (reason == CHANGE_CHECK_TOGGLED) {
      if (ctl_classes._TreeGetCheckState(tree_index) == TCB_CHECKED) {
         ctl_classes._TreeSetInfo(tree_index, -1, 0, 0, TREENODE_BOLD);
         class_def_selected[index] = 1;
      } else {
         ctl_classes._TreeSetInfo(tree_index, -1, 0, 0, 0);
         class_def_selected[index] = 0;
      }
   }

//   say("class_def_selected["index"]="class_def_selected[index]);

   PUSH_DOWN_DERIVED_CLASS_DEF_SELECTED(class_def_selected);

   // If any of the classes that are listed are not checked then don't let the user leave.
   int treeIndex;
   classUnchecked := false;
   i = ctl_classes._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (i > 0) {
      checked := ctl_classes._TreeGetCheckState(i);
      if (checked == TCB_UNCHECKED) {
         classUnchecked = true;
         break;
      }
      i = ctl_classes._TreeGetNextSiblingIndex(i);
   }

   struct MemberInfo memberInfoList[] = PUSH_DOWN_MEMBER_INFO();
   unresolvedDependencies := updateDependencies(ctl_members);

   // Don't let the user leave if there are still dependencies that have not been checked.
   if (classUnchecked == true || unresolvedDependencies == true) {
      ctl_ok.p_enabled = false;
   } else {
      ctl_ok.p_enabled = true;
   }
}

void ctl_ok.lbutton_up()
{

   int class_def_selected[] = PUSH_DOWN_DERIVED_CLASS_DEF_SELECTED();
   int members_to_move[] = null;
   int i, show_children, node_index;
   has_global_dependency := false;

   // Go through tree items finding the nodes that are expanded(checked) and 
   // add them to the list of members to be moved.
   node_index = ctl_members._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (node_index > 0) {
      // This the the member info class. Member index is the index into the type info
      // for the original class for this member.
      MemberInfo member_info = (MemberInfo)ctl_members._TreeGetUserInfo(node_index);

      // Expanded in our implementation means checked
      checked := ctl_members._TreeGetCheckState(node_index);
      if (checked == TCB_CHECKED) {
         members_to_move[ members_to_move._length() ] = member_info.memberIndex;
         for (i = 0 ; i < member_info.dependencies._length(); i++) {
            if (member_info.dependencies[i].isAGlobal) {
               has_global_dependency = true;
               break;
            }
         }
      }

      node_index = ctl_members._TreeGetNextIndex(node_index);
   }

   if (has_global_dependency) {
      int result = _message_box("At least one member to be moved is dependent on a global variable or function.\n" :+
                   "This might cause a compile error if this is not accessible in the member's new location.\n" :+
                   "Do you want to continue?","Pull Up", MB_OK | MB_OKCANCEL);
      if (result == IDCANCEL) {
         return; 
      }
   }

   // Turn array into string so that it can be passed back from dialog
   // and can be passed into refactoring C code.
   _str s_members_to_move = members_to_move._length() :+ '@';
   for (i = 0; i < members_to_move._length(); i++) {
      s_members_to_move :+= members_to_move[i] :+ '@';
   }

   // Add list of classes and list of class def filenames to return from this dialog.
   _str class_def_filename_list[] = PUSH_DOWN_DERIVED_CLASS_DEF_FILENAME_LIST();
   _str derived_classes[] = PUSH_DOWN_DERIVED_CLASS_LIST();

   // How many classes does the user want to move members to.
   num_classes_to_move_to := 0;
   for (i = 0; i < derived_classes._length(); i++) {
      if (class_def_selected[i] == 1) {
         num_classes_to_move_to++;
      }
   }

   // Build list of classes and their def files to move members to.
   s_class_defs :=  num_classes_to_move_to :+ '@'; 
   for (i = 0; i < derived_classes._length(); i++) {
      if (class_def_selected[i] == 1) {
         s_class_defs :+= derived_classes[i] :+ '@' :+ class_def_filename_list[i] :+ '@';
      }
   }

   s_members_to_move :+= '$' :+ s_class_defs;

//   say("s_members_to_move="s_members_to_move);

   // that's all folks
   p_active_form._delete_window(s_members_to_move);
}

defeventtab _refactor_extract_class_form;
static const EC_SUPER=        0;
static const EC_TRANSHANDLE=  1;
static const EC_MEMBERINFO=   2;
static const EC_CLASS=        3;
static const EC_H_FILE=       4;
static const EC_C_FILE=       5;
void _ctltree_member_list.on_create(int nTransactionHandle = -1,
                                    struct VS_TAG_BROWSE_INFO cm = null,
                                    _str dependency_files[] = null,
                                    struct ExtractClassMI (&memberInfo)[] = null,
                                    bool bExtractSuper = false)
{
   _SetDialogInfo(EC_TRANSHANDLE, nTransactionHandle);
   _SetDialogInfo(EC_SUPER,       bExtractSuper);

   //-//say("_ctltree_member_list.on_create: bExtractSuper="bExtractSuper);
   //-//int j = 0;
   //-//for ( j = 0; j < dependency_files._length(); ++j ) {
   //-//   say("_ctltree_member_list.on_create: file["j"] = "dependency_files[j]);
   //-//}
   // set up tree column info
   _TreeSetColButtonInfo(0, p_width, 0, 0, "Class Members");
   if ( -1 == nTransactionHandle || null == cm ) {
      //say('_ctltree_member_list.on_create: Null arguments');
      return;
   } else {
      //struct MemberInfo memberInfo[] = null;
      //parse_members_info(members_info, memberInfo);
      //struct ExtractClassMI memberInfo[] = null;
      int nMemberCnt = refactor_c_extract_class_num_members(nTransactionHandle);
      if ( nMemberCnt <= 0 ) {
         return;
      }

      for ( i := 0; i < nMemberCnt; ++i ) {
         nMemberIdx := -1;
         int nMemberAccess = VSREFACTOR_ACCESS_PUBLIC;
         _str strMember, strSymbolName, strTypeName, strLocation, strLineNumber;
         refactor_c_extract_class_get_member(nTransactionHandle, 
                                             i,
                                             nMemberIdx,
                                             strMember,
                                             strSymbolName,
                                             strTypeName,
                                             strLocation,
                                             strLineNumber,
                                             nMemberAccess);

         memberInfo[i].m_nTreeIdx      = -1;
         memberInfo[i].m_tAccess       = nMemberAccess;
         memberInfo[i].m_nMemberIdx    = nMemberIdx;
         memberInfo[i].m_sMember       = strMember;
         memberInfo[i].m_sSymbolName   = strSymbolName;
         memberInfo[i].m_sTypeName     = strTypeName;
         memberInfo[i].m_sLocation     = strLocation;
         memberInfo[i].m_sLineNumber   = strLineNumber;

         int numDeps = refactor_c_extract_class_num_dependencies(nTransactionHandle, i);
         int d = 0, nDepMemberIdx = -1;
         _str strDepSymbolName, strDepDescription, strDepTypeName;
         bDepIsAGlobal := false;
         for ( d = 0; d < numDeps; ++d ) {
            refactor_c_extract_class_get_dependency(nTransactionHandle,
                                                    i,
                                                    d,
                                                    nDepMemberIdx,
                                                    strDepSymbolName,
                                                    strDepDescription,
                                                    strDepTypeName,
                                                    bDepIsAGlobal);
            //say("_ctltree_member_list.on_create: depMemberIdx = "nDepMemberIdx);
            memberInfo[i].m_dependencies[d].crossDependencyMemberIndex  = -1;
            memberInfo[i].m_dependencies[d].defFilename                 = "";
            memberInfo[i].m_dependencies[d].defSeekPosition             = 0;
            memberInfo[i].m_dependencies[d].memberIndex                 = nDepMemberIdx;
            memberInfo[i].m_dependencies[d].symbolName                  = strDepSymbolName;
            memberInfo[i].m_dependencies[d].description                 = strDepDescription;
            memberInfo[i].m_dependencies[d].typeName                    = strDepTypeName;
            memberInfo[i].m_dependencies[d].isAGlobal                   = bDepIsAGlobal;
         }
      }

      // Set the user info to the index into the the class's typeInfo
      // that this member is located.
      for ( i = 0; i < memberInfo._length(); i++ ) {

         tagFlags := SE_TAG_FLAG_PUBLIC;
         if ( memberInfo[i].m_tAccess == VSREFACTOR_ACCESS_PROTECTED ) {
            tagFlags = SE_TAG_FLAG_PROTECTED;
         } else if ( memberInfo[i].m_tAccess == VSREFACTOR_ACCESS_PRIVATE ) {
            tagFlags = SE_TAG_FLAG_PRIVATE;
         }

         bitmapid_overlay := 0;
         bitmapid_normal := tag_get_bitmap_for_type(tag_get_type_id(memberInfo[i].m_sTypeName), tagFlags, bitmapid_overlay);

         if (memberInfo[i].m_sMember != '') {
            treeIndex := _TreeAddItem(TREE_ROOT_INDEX, memberInfo[i].m_sMember, TREE_ADD_AS_CHILD, 
                                      bitmapid_overlay, bitmapid_normal, TREE_NODE_LEAF, 0,
                                      memberInfo[i]);
            _TreeSetCheckable(treeIndex, 1, 0);
            _TreeSetCheckState(treeIndex, TCB_CHECKED);
            memberInfo[i].m_nTreeIdx = treeIndex;
            _TreeSetUserInfo(treeIndex, memberInfo[i]);
            //say("_ctltree_member_list.on_create: _TreeAddItem="memberInfo[i].m_nTreeIdx" access="access" memberInfo[i].m_tAccess="memberInfo[i].m_tAccess);
            //-//say("_ctltree_member_list.on_create: _TreeAddItem="memberInfo[i].m_nTreeIdx" memberInfo[i].m_sSymbolName="memberInfo[i].m_sSymbolName);
         }
      }
   }

   _SetDialogInfo(EC_MEMBERINFO, memberInfo);
}

//void _ctltree_dependency_list.on_create(int nTransactionHandle = -1,
//                                        struct VS_TAG_BROWSE_INFO cm = null,
//                                        _str dependency_files[] = null,
//                                        struct ExtractClassMI (&memberInfo)[] = null,
//                                        bool bExtractSuper = false)
//{
//   _TreeSetColButtonInfo(0, p_width, 0, 0, "Dependencies for: ");
//}

void _refactor_extract_class_form.on_load()
{
   bExtractSuper := _GetDialogInfo(EC_SUPER);
   if ( bExtractSuper ) {
      p_caption = "Extract Super Class";
      p_help    = "Extract super class (C++ Refactoring)";
   }

   // Change the focus to the member tree
   _ctltree_member_list._set_focus();

   nMember := _ctltree_member_list._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   _ctltree_member_list._TreeSelectLine(nMember);
   
   //ctl_class_member_description.p_caption = "Move members from class '"class_name"' to class '"super_class"'";
   _ctltree_member_list._TreeAdjustColumnWidths(0);

   ExtractClassMI memberInfo = (ExtractClassMI)_ctltree_member_list._TreeGetUserInfo(nMember);

   _ctltree_dependency_list._TreeSetColButtonInfo(0, _ctltree_dependency_list.p_width, 0, 0, "Dependencies for: " :+ memberInfo.m_sSymbolName);

   handle_change(CHANGE_SELECTED, nMember);
}

void _refactor_extract_class_form.on_resize()
{
   // width/height of OK, Cancel, Help buttons (all are the same)
   int button_width  = ctl_ok.p_width;
   int button_height = ctl_ok.p_height;
   int horz_margin   = _ctltree_member_list.p_x;
   int vert_margin   = _ctltree_member_list.p_y;

   // force size of dialog to remain reasonable
   // if the minimum width has not been set, it will return 0
   if (!_minimum_width()) {
      _set_minimum_size(button_width*4, button_height*12);
   }

   // get the active forms client width and height in twips
   int client_height = _dy2ly(SM_TWIP, p_active_form.p_client_height);
   int client_width  = _dx2lx(SM_TWIP, p_active_form.p_client_width);

   int motion_x = client_width  - _ctltree_member_list.p_width - _ctltree_member_list.p_x - horz_margin;
   int motion_y = client_height - ctl_cancel.p_y - ctl_cancel.p_height - vert_margin;

   // client height minus everything but the tree controls.
   int trees_vertical_space = client_height /*- ctl_class_member_description.p_height*/;
   //trees_vertical_space -= ctl_dependencies_description.p_height;
   trees_vertical_space -= ctl_ok.p_height;
   trees_vertical_space -= vert_margin*2;
   trees_vertical_space -= 200;

   // adjust vertical movements
   _ctltree_member_list.p_height = trees_vertical_space intdiv 2;
   _ctltree_dependency_list.p_height = trees_vertical_space intdiv 2;
   ctl_ok.p_y     = client_height - vert_margin - ctl_ok.p_height + 30;
   ctl_cancel.p_y = client_height - vert_margin - ctl_ok.p_height + 30;
   ctl_help.p_y   = client_height - vert_margin - ctl_ok.p_height + 30;
   //ctl_dependencies_description.p_y = ctl_members.p_y_extent + 100;
   //_ctltree_dependency_list.p_y = ctl_dependencies_description.p_y_extent;
   _ctltree_dependency_list.p_y = _ctltree_member_list.p_y_extent + 100;

   _ctltree_member_list.p_width += motion_x;
   _ctltree_dependency_list.p_width += motion_x;

   // adjust the tree column widths
   _ctltree_member_list._TreeAdjustLastColButtonWidth();
   _ctltree_dependency_list._TreeAdjustLastColButtonWidth();
}

bool update_EC(typeless tree_control, int reason, struct ExtractClassMI (&memberInfoList)[])
{
   int i, j, treeIndex, nDependency, moreFlags;
   showChildren := 0;
   memberIsChecked := 0;
   unresolvedDependencies := false;

   //for ( i = 0; i < memberInfoList._length(); ++i ) {
   //   ExtractClassMI _mi = memberInfoList[i];
   //   say( "MI["i"].m_sMember="memberInfoList[i].m_sMember" treeIdx="memberInfoList[i].m_nTreeIdx);
   //   for ( j = 0; j < memberInfoList[i].m_dependencies._length(); ++j ) {
   //      say( "   DEP["j"].memberIndex="memberInfoList[i].m_dependencies[j].memberIndex);
   //      say( "   DEP["j"].description="memberInfoList[i].m_dependencies[j].description);
   //      say( "   DEP["j"].isAGlobal="memberInfoList[i].m_dependencies[j].isAGlobal);
   //   }
   //}

   // Make all selected nodes bold and make all nodes not red.
   i = _ctltree_member_list._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (i > 0) {
      memberIsChecked = tree_control._TreeGetCheckState(i);
      if (memberIsChecked == TCB_CHECKED) {
         tree_control._TreeSetInfo(i, TREE_NODE_LEAF, -1, -1, TREENODE_BOLD);
      } else {
         tree_control._TreeSetInfo(i, TREE_NODE_LEAF, -1, -1, 0);
      }
      i = tree_control._TreeGetNextSiblingIndex(i);
   }

   // Make all selected nodes bold and make all nodes not red.
   i = _ctltree_member_list._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (i > 0) {
      memberFlags := 0;
      ExtractClassMI memberInfo = (ExtractClassMI)tree_control._TreeGetUserInfo(i);
      memberIsChecked = tree_control._TreeGetCheckState(i);
      tree_control._TreeGetInfo(i, showChildren, 0, 0, memberFlags);
      //-//say("update_EC: MI_tree_idx["memberInfo.m_nTreeIdx"]="memberInfo.m_sSymbolName" memberIsChecked="memberIsChecked" nDeps="memberInfo.m_dependencies._length());

      if (memberIsChecked == TCB_CHECKED) {
         for (nDependency = 0; nDependency < memberInfo.m_dependencies._length(); nDependency++) {
            int memberIdx = memberInfo.m_dependencies[nDependency].memberIndex;
            //-//say("update_EC: dep["nDependency"] memberIdx="memberIdx" member="memberInfo.m_dependencies[nDependency].symbolName);
            if (memberIdx != -1) {
               int dTreeIndex = memberInfoList[memberIdx].m_nTreeIdx;
               //-//say("update_EC: dTreeIndex VF = "dTreeIndex._varformat());
               //-//say("update_EC: dep["nDependency"] name="memberInfoList[memberIdx].m_sSymbolName" dTreeIndex="dTreeIndex);

               ExtractClassMI dMemberInfo = (ExtractClassMI)tree_control._TreeGetUserInfo(dTreeIndex);
               //-//say("update_EC: dMemberInfo VF = "dMemberInfo._varformat());
               //-//say("update_EC: dMemberInfo.m_nTreeIdx VF = "dMemberInfo.m_nTreeIdx._varformat());
               //-//say("update_EC: dMemberInfo.m_nTreeIdx    = "dMemberInfo.m_nTreeIdx);

               treeIndex = dMemberInfo.m_nTreeIdx;

               if (treeIndex != -1) {
                  memberIsChecked = tree_control._TreeGetCheckState(treeIndex);
                  if ( memberIsChecked == TCB_UNCHECKED ) {
                     tree_control._TreeSetInfo(treeIndex, TREE_NODE_LEAF, -1, -1, TREENODE_FORCECOLOR);
                  }
                  ExtractClassMI dDepInfo = (ExtractClassMI)tree_control._TreeGetUserInfo(treeIndex);
                  //-//say("  deps: dep_tree_idx["treeIndex"]="dDepInfo.m_sSymbolName);
                  //-//say("  deps: dDepInfo VF = "dDepInfo._varformat());
                  //-//say("  deps: dDepInfo.m_nTreeIdx VF = "dDepInfo.m_nTreeIdx._varformat());
                  //-//say("  deps: dDepInfo.m_nTreeIdx    = "dDepInfo.m_nTreeIdx);
               }
            }
         }
      }

      // Any red members means some dependencies have not been resolved.
      if (memberIsChecked == TCB_UNCHECKED && (memberFlags & TREENODE_FORCECOLOR)) {
         unresolvedDependencies = true;
      }

      i = tree_control._TreeGetNextSiblingIndex(i);
   }
   return unresolvedDependencies;
}
void _ctltree_member_list.on_change(int reason,int index,int col=-1,_str &text='')
{
   handle_change(reason,index,col,text);
}

void handle_change(int reason,int index,int col=-1,_str &text='')
{
   int i, nDependency, treeIndex, tree_id, showChildren, moreFlags;

   //say("_ctltree_member_list.on_change: index="index" reason="reason);
   // On selection change show selection's dependencies
   //if (reason == CHANGE_COLLAPSED) {
   //   _ctltree_member_list._TreeSetInfo(index, 0, -1, -1, TREENODE_BOLD);
   //} else if (reason == CHANGE_EXPANDED) {
   //   _ctltree_member_list._TreeSetInfo(index, 1, -1, -1, 0);
   //}

   if (reason == CHANGE_EXPANDED || reason == CHANGE_COLLAPSED || reason == CHANGE_SELECTED || reason == CHANGE_CHECK_TOGGLED) {
      _ctltree_dependency_list._TreeBeginUpdate(TREE_ROOT_INDEX, "T");
      _ctltree_dependency_list._TreeDelete(TREE_ROOT_INDEX, "C");

      ExtractClassMI memberInfo = (ExtractClassMI)_ctltree_member_list._TreeGetUserInfo(index);

      _ctltree_dependency_list._TreeSetColButtonInfo(0, _ctltree_dependency_list.p_width, 0, 0, "Dependencies for: " :+ memberInfo.m_sSymbolName);

      // Add dependencies for current selection to list.
      for (i = 0; i < memberInfo.m_dependencies._length(); i++) {
         _str descrip = memberInfo.m_dependencies[i].description;
         _str type    = memberInfo.m_dependencies[i].typeName;

         bitmapid_normal   := tag_get_bitmap_for_type(tag_get_type_id(type)); 
         tree_id = _ctltree_dependency_list._TreeAddItem(TREE_ROOT_INDEX, descrip, 
                                                         TREE_ADD_AS_CHILD, 
                                                         bitmapid_normal, bitmapid_normal, 
                                                         -1, 0,
                                                         memberInfo.m_dependencies[i]);
      }
      _ctltree_dependency_list._TreeEndUpdate(TREE_ROOT_INDEX);
   }

   //struct ExtractClassMI memberInfoList[] = _ctltree_member_list.p_user;
   struct ExtractClassMI memberInfoList[] = _GetDialogInfo(EC_MEMBERINFO);
   //say("_ctltree_member_list.on_change: VF = "memberInfoList[0].m_nTreeIdx._varformat());
   //say("memberInfoList len= "memberInfoList._length());
   //say("memberInfoList[0].m_nTreeIdx= "memberInfoList[0].m_nTreeIdx);

   unresolvedDependencies := update_EC(_ctltree_member_list, reason, memberInfoList);


   // Don't let the person leave if there are still dependencies that have not been checked.
   if (unresolvedDependencies == true) {
      ctl_ok.p_enabled = false;
   } else {
      ctl_ok.p_enabled = true;
   }

   // Change current selection to the item that was just checked/unchecked.
   if (reason == CHANGE_EXPANDED || reason == CHANGE_COLLAPSED || reason == CHANGE_CHECK_TOGGLED) {
      _ctltree_member_list._TreeSetCurIndex(index);
   }
}

void ctl_ok.lbutton_up()
{
   int members_to_move[];

   // Go through tree items finding the nodes that are expanded(checked) and 
   // add them to the list of members to be moved.
   int node_index = _ctltree_member_list._TreeGetFirstChildIndex(TREE_ROOT_INDEX),i, show_children;
   while (node_index > 0) {
      _ctltree_member_list._TreeGetInfo(node_index, show_children);

      // This the the member info class. Member index is the index into the type info
      // for the original class for this member.
      ExtractClassMI member_info = (ExtractClassMI)_ctltree_member_list._TreeGetUserInfo(node_index);

      // Expanded in our implementation means checked
      checked := _ctltree_member_list._TreeGetCheckState(node_index);
      if (checked == TCB_CHECKED) {
         members_to_move[ members_to_move._length() ] = member_info.m_nMemberIdx;
         for (i = 0 ; i < member_info.m_dependencies._length(); i++) {
            if (member_info.m_dependencies[i].isAGlobal) {
               //has_global_dependency = true;
               break;
            }
         }
      }

      node_index = _ctltree_member_list._TreeGetNextIndex(node_index);
   }

   _str strClass = _param1;//"newClass";
   _str strFileC = _param2;//"newClass.cpp";
   _str strFileH = _param3;//"newClass.h";

/*    int nHandle = _GetDialogInfo(1);                            */
/*    int nStatus = refactor_add_project_file(nHandle, strFileC); */
/*    if ( nStatus < 0 ) {                                         */
/*       refactor_cancel_transaction(nHandle);                    */
/*       p_active_form._delete_window(nStatus);                   */
/*       return;                                                  */
/*    }                                                           */

/*    nStatus = refactor_add_project_file(nHandle, strFileC);  */
/*    if ( nStatus < 0 ) {                                      */
/*       refactor_cancel_transaction(nHandle);                 */
/*       p_active_form._delete_window(nStatus);                */
/*       return;                                               */
/*    }                                                        */

   _SetDialogInfo(EC_CLASS,  strClass);
   _SetDialogInfo(EC_H_FILE, strFileH);
   _SetDialogInfo(EC_C_FILE, strFileC);

   int nStatus = refactor_c_extract_class( _GetDialogInfo(EC_TRANSHANDLE),
                                           _GetDialogInfo(EC_CLASS),
                                           _GetDialogInfo(EC_H_FILE),
                                           _GetDialogInfo(EC_C_FILE),
                                           members_to_move,
                                           _GetDialogInfo(EC_SUPER));
   p_active_form._delete_window(nStatus);
}
ctl_cancel.lbutton_up()
{
   p_active_form._delete_window(1);
}

defeventtab _refactor_extract_class_file;
static const ECF_SRC_DIFF= 1;
static const ECF_HDR_DIFF= 2;

bool check_filename(typeless ctrl_file, typeless ctrl_class)
{
   file_name := ctrl_file.p_text;
   class_name := ctrl_class.p_text;
   fext := "";
   ffile := "";
   if ( file_name != '' ) {
      fext  = _get_extension(file_name, true);
      ffile = _strip_filename(file_name, 'PE');
      //-//say('check_filename: file_name='file_name' ffile='ffile' class_name='class_name);
   } 
   return(ffile :== class_name);
}

void ctl_ok.on_create(bool bExtractSuper=false)
{
   _refactor_extract_class_file_initial_alignment();

   _SetDialogInfo(EC_SUPER,       bExtractSuper);
   _SetDialogInfo(ECF_SRC_DIFF,   0);
   _SetDialogInfo(ECF_HDR_DIFF,   0);

   if ( bExtractSuper ) {
      p_active_form.p_caption = "Extract Super Class";
      p_active_form.p_help    = "Extract super class (C++ Refactoring)";
   }

   ctltext_source_file.p_enabled       = false;
   ctl_browse_source_button.p_enabled  = false;
   ctltext_header_file.p_enabled       = false;
   ctl_browse_header_button.p_enabled  = false;
   ctl_ok.p_enabled                    = false;
}

void ctltext_class_name.on_change()
{
   if (ctltext_class_name.p_text == '') {
      ctltext_source_file.p_enabled       = false;
      ctl_browse_source_button.p_enabled  = false;
      ctltext_header_file.p_enabled       = false;
      ctl_browse_header_button.p_enabled  = false;
      ctl_ok.p_enabled                    = false;
      return;
   } else {
      ctltext_source_file.p_enabled       = true;
      ctl_browse_source_button.p_enabled  = true;
      ctltext_header_file.p_enabled       = true;
      ctl_browse_header_button.p_enabled  = true;
      ctl_ok.p_enabled                    = true;
   }

   if ( _GetDialogInfo(ECF_SRC_DIFF) != 1 ) {
      if ( ctltext_source_file.p_text != '' ) {
         _str fext, fpath;
         fext  = _get_extension(ctltext_source_file.p_text, true);
         fpath = _strip_filename(ctltext_source_file.p_text, 'N');

         ctltext_source_file.p_text = fpath :+ ctltext_class_name.p_text :+ fext;
      } else {
         fpath := _strip_filename(_edit_window().p_buf_name, 'N');
         ctltext_source_file.p_text = fpath;
         if ( !lastpos(FILESEP, fpath) ) {
            ctltext_source_file.p_text = ctltext_source_file.p_text :+ FILESEP;
         } 
         ctltext_source_file.p_text = ctltext_source_file.p_text :+ ctltext_class_name.p_text :+ '.cpp';
      }
   } else {
      if ( check_filename(ctltext_source_file, ctltext_class_name) ) {
         if ( ctltext_source_file.p_text != '' ) {
            _str fext, fpath;
            fext  = _get_extension(ctltext_source_file.p_text, true);
            fpath = _strip_filename(ctltext_source_file.p_text, 'N');

            ctltext_source_file.p_text = fpath :+ ctltext_class_name.p_text :+ fext;
         } else {
            fpath := _strip_filename(_edit_window().p_buf_name, 'N');
            ctltext_source_file.p_text = fpath;
            if ( !lastpos(FILESEP, fpath) ) {
               ctltext_source_file.p_text = ctltext_source_file.p_text :+ FILESEP;
            } 
            ctltext_source_file.p_text = ctltext_source_file.p_text :+ ctltext_class_name.p_text :+ '.cpp';
         }
         _SetDialogInfo(ECF_SRC_DIFF, 0);
      }
   }
   
   if ( _GetDialogInfo(ECF_HDR_DIFF) != 1 ) {
      if ( ctltext_header_file.p_text != '' ) {
         _str fext, fpath;
         fext  = _get_extension(ctltext_header_file.p_text, true);
         fpath = _strip_filename(ctltext_header_file.p_text, 'N');
         ctltext_header_file.p_text = fpath :+ ctltext_class_name.p_text :+ fext;
      } else {
         fpath := _strip_filename(_edit_window().p_buf_name, 'N');
         ctltext_header_file.p_text = fpath;
         if ( !lastpos(FILESEP, fpath) ) {
            ctltext_header_file.p_text = ctltext_header_file.p_text :+ FILESEP;
         } 
         ctltext_header_file.p_text = ctltext_header_file.p_text :+ ctltext_class_name.p_text :+ '.h';
         //say("ctltext_class_name.on_change: path="fpath" class_name=");
      }
   } else {
      if ( check_filename(ctltext_header_file, ctltext_class_name) ) {
         if ( ctltext_header_file.p_text != '' ) {
            _str fext, fpath;
            fext  = _get_extension(ctltext_header_file.p_text, true);
            fpath = _strip_filename(ctltext_header_file.p_text, 'N');
            ctltext_header_file.p_text = fpath :+ ctltext_class_name.p_text :+ fext;
         } else {
            fpath := _strip_filename(_edit_window().p_buf_name, 'N');
            ctltext_header_file.p_text = fpath;
            if ( !lastpos(FILESEP, fpath) ) {
               ctltext_header_file.p_text = ctltext_header_file.p_text :+ FILESEP;
            } 
            ctltext_header_file.p_text = ctltext_header_file.p_text :+ ctltext_class_name.p_text :+ '.h';
            //say("ctltext_class_name.on_change: path="fpath" class_name=");
         }
         _SetDialogInfo(ECF_HDR_DIFF, 0);
      }
   }
}
void ctltext_source_file.on_change() {
   src_file := ctltext_source_file.p_text;
   if ( src_file != '' ) {
      _SetDialogInfo( ECF_SRC_DIFF, !check_filename(ctltext_source_file, ctltext_class_name) );
   } else {
      _SetDialogInfo(ECF_SRC_DIFF, 0);
   }
}
void ctltext_header_file.on_change() {
   hdr_file := ctltext_header_file.p_text;
   if ( hdr_file != '' ) {
      _SetDialogInfo( ECF_HDR_DIFF, !check_filename(ctltext_header_file, ctltext_class_name) );
   } else {
      _SetDialogInfo(ECF_HDR_DIFF, 0);
   }
}
void ctl_browse_source_button.lbutton_up()
{
   wid := p_window_id;

   path := "";
   if ( ctltext_source_file.p_text != '') {
      path = _strip_filename(ctltext_source_file.p_text, 'N');
   }

   // create new source file
   _str result=_OpenDialog('-modal',
                          'Create source file',                   // Title
                          '*.cpp;*.cc;*.cp;*.cxx;*.c++;*.c',      // Wild Cards
                          '*.cpp;*.cc;*.cp;*.cxx;*.c++;*.c,*.*',  // File Filters
                          OFN_SAVEAS,                             // OFN flags
                          '.cpp',                                 // Default extension
                          ctltext_class_name.p_text:+".cpp",      // Initial name
                          path                                    // Initial directory
                         );


   p_window_id=wid.p_prev;

   if ( result=='' ) {
      return;
   }
   result=strip(result,'B','"');

   if ( _strip_filename(result, 'PE') :!= ctltext_class_name.p_text ) {
      _SetDialogInfo(ECF_SRC_DIFF, 1);
   }

   ctltext_source_file.p_text = result;
}
void ctl_browse_header_button.lbutton_up()
{
   wid := p_window_id;

   // create new header file
   _str result=_OpenDialog('-modal',
                          'Extract class header file location',   // Title
                          '*.h;*.hpp;*.hxx;*.h++',                // Wild Cards
                          "*.h;*.hpp;*.hxx;*.h++,*.*",            // File Filters
                          OFN_SAVEAS,                             // OFN flags
                          '.h',                                   // Default extension
                          ctltext_class_name.p_text:+".h",        // Initial name
                          ""                                      // Initial directory
                         );

   p_window_id=wid.p_prev;

   if ( result=='' ) {
      return;
   }
   result=strip(result,'B','"');

   if ( _strip_filename(result, 'PE') :!= ctltext_class_name.p_text ) {
      _SetDialogInfo(ECF_HDR_DIFF, 1);
   }
   ctltext_header_file.p_text = result;
}

void ctl_cancel.lbutton_up()
{
   p_active_form._delete_window("cancel");
}

void ctl_ok.lbutton_up()
{
   class_name := ctltext_class_name.p_text;
   hdr_file_name := ctltext_header_file.p_text;
   src_file_name := ctltext_source_file.p_text;
   bSaveHdrFile  := bSaveSrcFile := true;
   bExtractSuper := _GetDialogInfo(EC_SUPER);
   int src_tview_id, hdr_tview_id, status, orig_view_id;

   orig_view_id   = _create_temp_view(hdr_tview_id);
   p_buf_name     = hdr_file_name;
   p_UTF8         = _load_option_UTF8(p_buf_name);
   _SetEditorLanguage();

   guard :=  "__" :+ upcase(_strip_filename(hdr_file_name, 'PE')) :+ "_" :+ upcase(_get_extension(hdr_file_name)) :+ "__";

   insert_line("#ifndef " :+ guard);
   insert_line("#define " :+ guard);
   insert_line("");
   insert_line("class " :+ class_name);
   insert_line("{");
   insert_line("public:");
   insert_line("    " :+ class_name :+ "()  {}");
   insert_line("   ~" :+ class_name :+ "()  {}");
   insert_line("};");
   insert_line("");
   insert_line("#endif // " :+ guard);

   if ( file_exists(hdr_file_name) ) {
      status=_message_box(nls("%s already exists.",hdr_file_name)"\n\n":+
                nls("Do you want to replace it?"),
                p_active_form.p_caption,
                MB_YESNOCANCEL|MB_ICONQUESTION,IDNO
                );
      if (status!=IDYES) {
         bSaveHdrFile  = false;
      }
   }
   if ( bSaveHdrFile ) {
      status=_save_file(build_save_options(p_buf_name));
      p_window_id=orig_view_id;
      _delete_temp_view(hdr_tview_id);
      if ( status ) {
         _message_box(nls("Could not save file '%s1'\n%s2",hdr_file_name,get_message(status)));
      }
   }

   orig_view_id   = _create_temp_view(src_tview_id);
   p_buf_name     = src_file_name;
   p_UTF8         = _load_option_UTF8(p_buf_name);
   _SetEditorLanguage();
   
   insert_line('#include "'_strip_filename(hdr_file_name, 'P')'"');
   insert_line("");
   
   if ( file_exists(src_file_name) ) {
      status=_message_box(nls("%s already exists.",src_file_name)"\n\n":+
                nls("Do you want to replace it?"),
                p_active_form.p_caption,
                MB_YESNOCANCEL|MB_ICONQUESTION,IDNO
                );
      if (status!=IDYES) {
         bSaveSrcFile  = false;
      }
   }

   if ( bSaveSrcFile ) {
      status=_save_file(build_save_options(p_buf_name));
      p_window_id=orig_view_id;
      _delete_temp_view(src_tview_id);
      if ( status ) {
         _message_box(nls("Could not save file '%s1'\n%s2",src_file_name,get_message(status)));
      }
   }

/*    if ( !bSaveHdrFile || !bSaveSrcFile ) {     */
/*       p_active_form._delete_window("error");  */
/*    } else {                                   */
      _param1 = class_name;
      _param2 = src_file_name;
      _param3 = hdr_file_name;
      p_active_form._delete_window();
/*    } */
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _refactor_extract_class_file_initial_alignment()
{
   orig_y := ctllabel_info.p_y;
   rightAlign := p_active_form.p_width - ctllabel_info.p_x;

   // size the buttons to the textbox
   ctltext_class_name.p_x_extent = rightAlign;
   ctllabel_info.p_y = orig_y;
   sizeBrowseButtonToTextBox(ctltext_header_file.p_window_id, ctl_browse_header_button.p_window_id, 0, rightAlign);
   sizeBrowseButtonToTextBox(ctltext_source_file.p_window_id, ctl_browse_source_button.p_window_id, 0, rightAlign);
}
