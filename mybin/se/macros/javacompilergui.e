////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47788 $
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
#include "tagsdb.sh"
#import "cjava.e"
#import "guicd.e"
#import "guiopen.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "picture.e"
#import "projconv.e"
#import "refactor.e"
#import "stdprocs.e"
#import "tagform.e"
#import "tags.e"
#endregion

void get_java_compiler_configs(JavaCompilerConfiguration (&configs)[])
{
   _str filename=_ConfigPath():+COMPILER_CONFIG_FILENAME;

   boolean config_is_open=refactor_config_is_open( filename )!=0;
   if (config_is_open) {
      refactor_config_open( filename );
   }

   if( refactor_config_count() <= 0 ) {
      generate_default_configs();
   }

   _str compiler_name='';
   _str compiler_type='';
   _str compiler_root='';

   int num_configs = refactor_config_count();
   int num_jars;

   int config_index;
   int jar_index;
   int num_java_configs = 0;

   for (config_index=0; config_index<num_configs; ++config_index) {
      refactor_config_get_type(config_index,compiler_type); 
      if (compiler_type :== "java") {
         refactor_config_get_name(config_index, compiler_name);
         refactor_config_get_java_source(compiler_name, compiler_root);
   
         configs[num_java_configs].name=compiler_name;
         configs[num_java_configs].root=compiler_root;

         num_jars=refactor_config_count_jars(compiler_name);
   
         for (jar_index=0; jar_index<num_jars; ++jar_index) {
            refactor_config_get_jar(compiler_name,jar_index,configs[num_java_configs].jars[jar_index]);
         }
         num_java_configs++;
      }
   }

   if (!config_is_open) {
      refactor_config_close();
   }
}

static void write_java_configs(JavaCompilerConfiguration (&configs)[])
{
   _str filename=_ConfigPath():+COMPILER_CONFIG_FILENAME;

   boolean config_is_open=refactor_config_is_open( filename )!=0;
   refactor_config_open( filename );

   refactor_config_delete_all_type('java');

   for (config_index:=0;config_index<configs._length();++config_index) {
      _str jars='';
      int inc_index;
      for (inc_index=0;inc_index<configs[config_index].jars._length();++inc_index) {
         if (inc_index==0) {
            jars=configs[config_index].jars[inc_index];
         } else {
            strappend(jars,PATHSEP:+configs[config_index].jars[inc_index]);
         }
      }
      refactor_config_add_java(configs[config_index].name,
                               configs[config_index].root,
                               jars);
   }

   refactor_config_save(filename);

   if (!config_is_open) {
      refactor_config_close();
   }
}

_str add_new_java_compiler()
{
   _str jre_root = '';
   boolean recognized_jdk = false;
   jre_name := prompt_for_new_compiler_name(jre_root, recognized_jdk);
   if (jre_name == '') {
      return '';
   }

   // Check for duplicate
   JavaCompilerConfiguration configs[];
   get_java_compiler_configs(configs);
   if( find_compiler_configuration_index( configs, jre_name) != -1 ) {
      _message_box("Error: Configuration \"" jre_name"\" already exists");
      return '';
   }

   int config_index=configs._length();
   configs[config_index].name=jre_name;
   configs[config_index].root=jre_root;
   configs[config_index].jars._makeempty();
   if (recognized_jdk) {
      _str sys_jars = java_get_jdk_jars(jre_root);
      while (sys_jars:!="") {
         _str jar_file;
         parse sys_jars with jar_file PATHSEP sys_jars;
         configs[config_index].jars[configs[config_index].jars._length()] = jar_file;
      }
   }

   write_java_configs(configs);

   show("-xy -modal _java_compiler_properties_form", jre_name);

   return jre_name;
}

/**
 * This module implements Java compiler properties dialog.
 *
 * @since 12.0 
 */

defeventtab _java_compiler_properties_form;

#define NO_CONFIGS "No compilers found"
// These are used with _GetDialogInfo and _SetDialogInfo
#define JAVA_COMP_PROP_ACTIVE_CONFIG     (0)         // int
#define JAVA_COMP_PROP_SELECTED_CONFIG   (1)         // int
#define JAVA_COMP_PROP_ALL_CONFIGS       (2)         // CompilerConfiguration[]
#define JAVA_COMP_PROP_SELECTED_INC      (3)         // int
#define JAVA_COMP_PROP_MODIFIED          (4)         // boolean - whether configuration has been modified

#region Options Dialog Helper Functions

void _java_compiler_properties_form_init_for_options()
{
   ctl_ok.p_visible = false;
   ctl_cancel.p_visible = false;
   ctl_help.p_visible = false;
}

void _java_compiler_properties_form_save_settings()
{
   _SetDialogInfo(JAVA_COMP_PROP_MODIFIED, false);
}

boolean _java_compiler_properties_form_is_modified()
{
   return _GetDialogInfo(JAVA_COMP_PROP_MODIFIED);
}

boolean _java_compiler_properties_form_apply()
{
   JavaCompilerConfiguration configs[] = _GetDialogInfo(JAVA_COMP_PROP_ALL_CONFIGS);
   // Don't let user leave this dialog until they have selected an active valid configuration.
   // This should only happen if there are no active configs when the dialog is brought up initially
   // or if they delete the active configuration
   int active_index=_GetDialogInfo(JAVA_COMP_PROP_ACTIVE_CONFIG);
   if( active_index < 0) {
      if (configs._length() > 0) {
         _message_box( "Choose a default configuration." );
         return false;
      } else {
         // If there are no configs, clear out the def var and close
         def_active_java_config = "";
         _config_modify_flags(CFGMODIFY_DEFVAR);
         write_and_save_configs();
         _TagCallList(TAGFILE_ADD_REMOVE_CALLBACK_PREFIX,'','');
         _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
         return true;
      }
   }

   int config_index=_GetDialogInfo(JAVA_COMP_PROP_SELECTED_CONFIG);

   // If the currently selected configuration is not the active configuration,
   // ask them if they would like to make it active
   if ( config_index != active_index ) {
      int response = _message_box('Do you want to make "'configs[config_index].name'" the default configuration?',"SlickEdit", MB_YESNO);
      if (response == IDYES) {
         active_index=config_index;
      }
   }

   _str orig_active_config = def_active_java_config;
   def_active_java_config = configs[active_index].name;
   _config_modify_flags(CFGMODIFY_DEFVAR);

   write_and_save_configs();
   
   // configuration has changed?
   if (!ctl_ok.p_visible && orig_active_config != def_active_java_config) {
      _TagCallList(TAGFILE_ADD_REMOVE_CALLBACK_PREFIX,'','');
      _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
   }

   return true;
}

#endregion Options Dialog Helper Functions

void ctl_ok.on_create(_str selConfig = '')
{
   _java_compiler_properties_form_initial_alignment();

   _str filename=_ConfigPath():+COMPILER_CONFIG_FILENAME;

   boolean config_is_open=refactor_config_is_open( filename )!=0;
   if (config_is_open) {
      refactor_config_open( filename );
   }

   if( refactor_config_count() <= 0 ) {
      generate_default_configs();
   }

   JavaCompilerConfiguration configs[];

   _str compiler_name='';
   _str compiler_type='';
   _str compiler_root='';

   int num_configs = refactor_config_count();
   int num_jars;

   int config_index;
   int jar_index;
   int num_java_configs = 0;

   for (config_index=0; config_index<num_configs; ++config_index) {
      refactor_config_get_type(config_index,compiler_type); 
      if (compiler_type :== "java") {
         refactor_config_get_name(config_index, compiler_name);
         refactor_config_get_java_source(compiler_name, compiler_root);
   
         configs[num_java_configs].name=compiler_name;
         configs[num_java_configs].root=compiler_root;

         num_jars=refactor_config_count_jars(compiler_name);
   
         for (jar_index=0; jar_index<num_jars; ++jar_index) {
            refactor_config_get_jar(compiler_name,jar_index,configs[num_java_configs].jars[jar_index]);
         }
         num_java_configs++;
      }
   }

   if (!config_is_open) {
      refactor_config_close();
   }

   // If there's no default, but we have some configs...set last one as the default 
   if (def_active_java_config == "" && num_java_configs > 0 && configs[configs._length()] != null) {
      def_active_java_config = configs[configs._length()].name;
   }

   if (selConfig == '') {
      selConfig = def_active_java_config;
   } 

   selIndex := 0;
   activeIndex := -1;
   // If default config exists then set the combo box to that one
   for (config_index=0; config_index<num_java_configs; ++config_index) {
      if (configs[config_index].name:== selConfig) {
         selIndex = config_index;
      }
      if (configs[config_index].name:== def_active_java_config) {
         activeIndex = config_index;
      }
   }

   _SetDialogInfo(JAVA_COMP_PROP_ACTIVE_CONFIG,activeIndex);
   _SetDialogInfo(JAVA_COMP_PROP_SELECTED_CONFIG,selIndex);

   _SetDialogInfo(JAVA_COMP_PROP_ALL_CONFIGS,configs);
   _SetDialogInfo(JAVA_COMP_PROP_SELECTED_INC,0);

   update_java_config_list();
}

void ctl_ok.lbutton_up()
{
   _str orig_active_config = def_active_java_config;

   if (_java_compiler_properties_form_apply()) {
      p_active_form._delete_window(def_active_java_config);
   
      // configuration has changed?
      if (orig_active_config != def_active_java_config) {
         _TagCallList(TAGFILE_ADD_REMOVE_CALLBACK_PREFIX,'','');
         _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
      }
   }
}


/**
 * Used to show the refactoring options menu set to a particuar configuration
 * without changing the active configuration
 */
void _java_compiler_set_config(_str compiler_name)
{
   JavaCompilerConfiguration configs[]=_GetDialogInfo(JAVA_COMP_PROP_ALL_CONFIGS);
   int config_index=find_compiler_configuration_index(configs,compiler_name);

   if (config_index>=0) {
      ctl_compiler_name.p_line = config_index + 1;
      ctl_compiler_name._lbselect_line();
   }
}

static void update_java_config_list()
{
   // save this before we clear the list - it might get reset
   selIndex := _GetDialogInfo(JAVA_COMP_PROP_SELECTED_CONFIG);
   ctl_compiler_name._lbclear();

   JavaCompilerConfiguration configs[] = _GetDialogInfo(JAVA_COMP_PROP_ALL_CONFIGS);

   int config_index;
   for (config_index=0; config_index<configs._length(); ++config_index) {
      ctl_compiler_name._lbadd_item(configs[config_index].name);
   }

   if (configs._length()==0) {
      ctl_compiler_name._lbadd_item(NO_CONFIGS);
   }

   // now pick the right one
   if (selIndex >= 0 && selIndex < configs._length()) {
      ctl_compiler_name.p_line = selIndex + 1;
      if (ctl_compiler_name._lbget_seltext() != configs[selIndex].name) {
         ctl_compiler_name._lbselect_line();
      }
   }
   // call event either way
   call_event(CHANGE_CLINE, selIndex + 1, ctl_compiler_name, ON_CHANGE, 'W');
}

static void update_java_config_properties()
{
   // get all data
   JavaCompilerConfiguration configs[]=_GetDialogInfo(JAVA_COMP_PROP_ALL_CONFIGS);
   int config_index=_GetDialogInfo(JAVA_COMP_PROP_SELECTED_CONFIG);

   if ((config_index<0) || (config_index>=configs._length())) {
      config_index=0;
   }

   // clear other controls
   ctl_root.p_text="";
   ctl_system_libraries._lbclear();

   int active_config=_GetDialogInfo(JAVA_COMP_PROP_ACTIVE_CONFIG);
   if (active_config<0) {
      // If there's only one config, set it as the default
      if (configs._length() == 1) {
         active_config = 0;
      } else {
         ctl_active_configuration.p_caption = "Default: None";
      }
   }

   if (config_index >= configs._length()) {
      // can happen if there are no configs
      ctl_delete_compiler.p_enabled=false;
      ctl_copy_compiler.p_enabled=false;
      ctl_make_active.p_enabled=false;
      ctl_build_tagfile.p_enabled=false;
      ctl_root_label.p_enabled=false;
      ctl_root.p_enabled=false;
      ctl_system_libraries_label.p_enabled=false;
      ctl_system_libraries.p_enabled=false;
      ctl_add_jar.p_enabled=false;
      ctl_delete_jar.p_enabled=false;
      return;
   }

   _str config_name=configs[config_index].name;
   int num_jars=configs[config_index].jars._length();

   ctl_root.p_text=configs[config_index].root;

   int jar_index;
   for (jar_index=0;jar_index<num_jars;++jar_index) {
      ctl_system_libraries._lbadd_item(configs[config_index].jars[jar_index]);
   }

   jar_index=_GetDialogInfo(JAVA_COMP_PROP_SELECTED_INC);
   if (num_jars>0) {
      if (jar_index>=num_jars) {
         jar_index=num_jars-1;
      }
      ctl_system_libraries.p_line=jar_index+1;
      ctl_system_libraries._lbselect_line();
   }

   ctl_delete_compiler.p_enabled=true;
   ctl_copy_compiler.p_enabled=true;
   ctl_make_active.p_enabled=true;
   ctl_build_tagfile.p_enabled=true;
   ctl_root_label.p_enabled=true;
   ctl_root.p_enabled=true;
   ctl_system_libraries_label.p_enabled=true;
   ctl_system_libraries.p_enabled=true;
   ctl_add_jar.p_enabled=true;
   ctl_delete_jar.p_enabled=num_jars>0;

   if (active_config>=0) {
      ctl_active_configuration.p_caption = "Default: " :+ configs[active_config].name;
      _SetDialogInfo(JAVA_COMP_PROP_ACTIVE_CONFIG, active_config);
   }
}

void ctl_compiler_name.on_change(int reason, int index)
{
   if( reason != CHANGE_CLINE && reason != CHANGE_CLINE_NOTVIS ) {
      return;
   }

   // the combo index is 1-based, so we need to subtract one to match it
   // to our config array entries
   _SetDialogInfo(JAVA_COMP_PROP_SELECTED_CONFIG, index - 1);
   _SetDialogInfo(JAVA_COMP_PROP_SELECTED_INC, 0);

   update_java_config_properties();
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _java_compiler_properties_form_initial_alignment()
{
   rightAlign := ctl_compiler_frame.p_width - ctl_system_libraries.p_x;
   alignUpDownListButtons(ctl_system_libraries, rightAlign, ctl_add_jar.p_window_id,
                          ctl_delete_jar.p_window_id);
}

void _java_compiler_properties_form.on_resize()
{
   // width/height of OK, Cancel, Help buttons (all are the same)
   int button_width  = ctl_ok.p_width;
   int button_height = ctl_ok.p_height;
   int horz_margin   = ctl_compiler_frame.p_x;
   int vert_margin   = ctl_compiler_name.p_y;

   if (!ctl_ok.p_visible) {
      button_width = button_height = 0;
   } else {
      // force size of dialog to remain reasonable
      // have we set the min size yet?  if not, min width will be 0
      if (!_minimum_width()) {
         _set_minimum_size(button_width*6, button_height*15);
      }
   }

   // get the active forms client width and height in twips
   int clientHeight = p_height;
   int clientWidth = p_width;

   // use the 'Help' button to compute the sizing motion
   int motion_y = clientHeight-vert_margin-ctl_ok.p_y-button_height;
   int motion_x = clientWidth-horz_margin-ctl_copy_compiler.p_x-ctl_copy_compiler.p_width;

   ctl_ok.p_y     += motion_y;
   ctl_cancel.p_y += motion_y;
   ctl_help.p_y   += motion_y;
   ctl_compiler_frame.p_height += motion_y;
   ctl_system_libraries.p_height = ctl_compiler_frame.p_height - ctl_system_libraries.p_y - vert_margin;

   ctl_compiler_name.p_width += motion_x;
   ctl_add_compiler.p_x += motion_x;
   ctl_delete_compiler.p_x += motion_x;
   ctl_copy_compiler.p_x += motion_x;
   ctl_make_active.p_x += motion_x;
   ctl_build_tagfile.p_x += motion_x;
   ctl_compiler_frame.p_width += motion_x;
   ctl_add_jar.p_x += motion_x;
   ctl_delete_jar.p_x += motion_x;
   ctl_root.p_width += motion_x;
   ctl_system_libraries_label.p_width += motion_x;
   ctl_system_libraries.p_width += motion_x;
   // align the right edges of the compilers drop down and the active compiler
   // so that the active compiler never overlaps the "Make Active" button
   ctl_active_configuration.p_width = ctl_compiler_name.p_x + ctl_compiler_name.p_width - ctl_active_configuration.p_x;
}

static int find_compiler_configuration_index(JavaCompilerConfiguration (&configs)[],_str compiler)
{
   int num_configs=configs._length();
   int config_index;

   for (config_index=0;config_index<num_configs;++config_index) {
      if (configs[config_index].name:==compiler) {
         return config_index;
      }
   }

   return -1;
}

static void write_and_save_configs()
{
   JavaCompilerConfiguration configs[]=_GetDialogInfo(JAVA_COMP_PROP_ALL_CONFIGS);
   int config_index=_GetDialogInfo(JAVA_COMP_PROP_SELECTED_CONFIG);

   write_java_configs(configs);

   _GetLatestJDK(true);
}


static _str prompt_for_new_compiler_name(_str &jre_root, boolean &recognized_jdk)
{
   int wid=p_window_id;
   jre_root= _ChooseDirDialog("Select the root directory of the JRE installation (contains bin):");
   if (jre_root == '') {
      return '';
   }
   p_window_id=wid;
  
   _str jre_name =  get_jdk_from_root(jre_root); 
   recognized_jdk = false;

   if (jre_name == '') {
      int button = _message_box("SlickEdit was unable to determine the type or version of the JRE installation.\n":+
                   "Click OK to manually create a configuration for this directory.","SlickEdit",MB_OKCANCEL);
      if (button == IDCANCEL) {
         return '';
      }
       // prompt for name, check for duplicate, and add to list
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
      jre_name = _param1; 
   } else {
      recognized_jdk = true;
   }

   return jre_name;
}

static void get_new_compiler()
{
   _str jre_root = '';
   boolean recognized_jdk = false;
   jre_name := prompt_for_new_compiler_name(jre_root, recognized_jdk);

   // user cancelled
   if (jre_name == '') return;

   // Check for duplicate
   JavaCompilerConfiguration configs[]=_GetDialogInfo(JAVA_COMP_PROP_ALL_CONFIGS);
   if( find_compiler_configuration_index( configs, jre_name) != -1 ) {
      _message_box("Error: Configuration \"" jre_name"\" already exists");
      return;
   }

   int config_index=configs._length();
   configs[config_index].name=jre_name;
   configs[config_index].root=jre_root;
   configs[config_index].jars._makeempty();
   if (recognized_jdk) {
      _str sys_jars = java_get_jdk_jars(jre_root);
      while (sys_jars:!="") {
         _str jar_file;
         parse sys_jars with jar_file PATHSEP sys_jars;
         configs[config_index].jars[configs[config_index].jars._length()] = jar_file;
      }
   }

   _SetDialogInfo(JAVA_COMP_PROP_ALL_CONFIGS,configs);
   _SetDialogInfo(JAVA_COMP_PROP_SELECTED_CONFIG,config_index);
   _SetDialogInfo(JAVA_COMP_PROP_SELECTED_INC,0);
   _SetDialogInfo(JAVA_COMP_PROP_MODIFIED, true);

   update_java_config_list();
}

static _str add_compilers_callback(int sl_event,_str &result, _str info)
{
   if (sl_event!=SL_ONDEFAULT) {
      return '';
   }

   _nocheck _control _sellist;
   int status=_sellist._lbfind_selected(1);

   result='';
   while (!status) {
      if (result:=='') {
         result=_sellist.p_line-1;
      } else {
         strappend(result,',');
         strappend(result,_sellist.p_line-1);
      }

      status=_sellist._lbfind_selected(0);
   }
   return(1);
}

void ctl_add_compiler.lbutton_up()
{
   boolean made_changes=false;
   JavaCompilerConfiguration configs[]=_GetDialogInfo(JAVA_COMP_PROP_ALL_CONFIGS);

   _str new_names[];
   _str new_sources[];

   _str java_config_names[];
   _str java_config_sources[];
   _str jdkPath = '';
   getJavaIncludePath(java_config_sources, jdkPath, java_config_names);

   int index;
   for (index=0;index<java_config_names._length();++index) {
      if (find_compiler_configuration_index(configs,java_config_names[index])<0) {
         new_names[new_names._length()] = java_config_names[index];
         new_sources[new_sources._length()] = java_config_sources[index];
      }
   }

   boolean prompt_for_new = false;
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

         if ( (index>=0) && (index < new_names._length() - 1) ) {
            int config_index=configs._length();
            configs[config_index].name = new_names[index];
            configs[config_index].root = new_sources[index];

            _str jars = java_get_jdk_jars(new_sources[index]);
            while (jars:!="") {
               _str jar_file;
               parse jars with jar_file PATHSEP jars;
               configs[config_index].jars[configs[config_index].jars._length()] = jar_file;
            }
            _SetDialogInfo(JAVA_COMP_PROP_ALL_CONFIGS,configs);
            _SetDialogInfo(JAVA_COMP_PROP_SELECTED_CONFIG,config_index);
            _SetDialogInfo(JAVA_COMP_PROP_SELECTED_INC,0);
            _SetDialogInfo(JAVA_COMP_PROP_MODIFIED, true);

            update_java_config_list();
         } else {
            prompt_for_new = true;
         }
      }
   } else {
      prompt_for_new = true;
   }

   if (prompt_for_new) {
      get_new_compiler();
   }
}

void ctl_delete_compiler.lbutton_up()
{
   JavaCompilerConfiguration configs[]=_GetDialogInfo(JAVA_COMP_PROP_ALL_CONFIGS);
   int config_index=_GetDialogInfo(JAVA_COMP_PROP_SELECTED_CONFIG);

   configs._deleteel(config_index);

   int active_index=_GetDialogInfo(JAVA_COMP_PROP_ACTIVE_CONFIG);
   if (active_index==config_index) {
      _SetDialogInfo(JAVA_COMP_PROP_ACTIVE_CONFIG,-1);
   } else if (active_index>config_index) {
      _SetDialogInfo(JAVA_COMP_PROP_ACTIVE_CONFIG,active_index-1);
   }

   // check if deleting the last configuration
   if (config_index==configs._length()) {
      --config_index;
   }

   _SetDialogInfo(JAVA_COMP_PROP_ALL_CONFIGS,configs);
   _SetDialogInfo(JAVA_COMP_PROP_SELECTED_CONFIG,config_index);
   _SetDialogInfo(JAVA_COMP_PROP_SELECTED_INC,0);
   _SetDialogInfo(JAVA_COMP_PROP_MODIFIED, true);

   update_java_config_list();
}

void ctl_copy_compiler.lbutton_up()
{
   JavaCompilerConfiguration configs[]=_GetDialogInfo(JAVA_COMP_PROP_ALL_CONFIGS);
   int config_index=_GetDialogInfo(JAVA_COMP_PROP_SELECTED_CONFIG);

   // prompt for name, check for duplicate, and add to list
   // prompt for new name
   _str newName="";
   _str promptResult = show("-modal _textbox_form",
                            "Enter the name for the new configuration",
                            0,
                            "",
                            "",
                            "",
                            "",
                            "Configuration name:" configs[config_index].name );
   if (promptResult == "") {
      // user cancelled operation
      return;
   }

   newName = _param1;

   // Check for duplicate
   int existing_index=find_compiler_configuration_index(configs,newName);
   if( existing_index >= 0 ) {
      _message_box("Error: Configuration name \"" newName "\" already exists");

      // select the config they just tried to add
      if (existing_index != config_index) {
         ctl_compiler_name.p_line = existing_index + 1;
         ctl_compiler_name._lbselect_line();
      }
      return;
   }

   int new_config_index=configs._length();
   configs[new_config_index] = configs[config_index];
   configs[new_config_index].name = newName;

   _SetDialogInfo(JAVA_COMP_PROP_ALL_CONFIGS, configs);
   _SetDialogInfo(JAVA_COMP_PROP_SELECTED_CONFIG, new_config_index);
   _SetDialogInfo(JAVA_COMP_PROP_MODIFIED, true);

   update_java_config_list();
}

void ctl_make_active.lbutton_up()
{
   active_config := _GetDialogInfo(JAVA_COMP_PROP_SELECTED_CONFIG);

   // set the current as the default
   _SetDialogInfo(JAVA_COMP_PROP_MODIFIED, true);
   _SetDialogInfo(JAVA_COMP_PROP_ACTIVE_CONFIG, active_config);

   // show this on the gui
   JavaCompilerConfiguration configs[]=_GetDialogInfo(JAVA_COMP_PROP_ALL_CONFIGS);
   ctl_active_configuration.p_caption = "Default: " :+ configs[active_config].name;
}

void ctl_build_tagfile.lbutton_up()
{
   JavaCompilerConfiguration configs[]=_GetDialogInfo(JAVA_COMP_PROP_ALL_CONFIGS);
   int config_index=_GetDialogInfo(JAVA_COMP_PROP_SELECTED_CONFIG);
   _str config_name = configs[config_index].name;

   write_and_save_configs();
   useThread := _is_background_tagging_enabled(AUTOTAG_LANGUAGE_NO_THREADS);
   refactor_build_compiler_tagfile(config_name, 'java', false, useThread);
}

ctl_root.on_lost_focus()
{
   JavaCompilerConfiguration configs[]=_GetDialogInfo(JAVA_COMP_PROP_ALL_CONFIGS);
   int config_index=_GetDialogInfo(JAVA_COMP_PROP_SELECTED_CONFIG);

   configs[config_index].root=p_text;

   _SetDialogInfo(JAVA_COMP_PROP_ALL_CONFIGS,configs);
   _SetDialogInfo(JAVA_COMP_PROP_MODIFIED, true);
   update_java_config_properties();
}

void ctl_add_jar.lbutton_up()
{
   JavaCompilerConfiguration configs[]=_GetDialogInfo(JAVA_COMP_PROP_ALL_CONFIGS);
   int config_index=_GetDialogInfo(JAVA_COMP_PROP_SELECTED_CONFIG);

     // browse for header file
   _str initial_dir = configs[config_index].root;
   _str result=_OpenDialog('-modal',
                          'Select jar file', // Title
                          '*.jar',                                          // Wild Cards
                          "Jar Files (*.jar)",                          // File Filters
                          OFN_FILEMUSTEXIST|OFN_ALLOWMULTISELECT,       // OFN flags
                          '.jar',                                           // Default extension
                          "",       // Initial name
                          initial_dir                                // Initial directory
                         );
   result=strip(result,'B','"');
   if ( result=='' ) {
      return;
   }
   _str cur='';
   for (;;) {
      cur=parse_file(result);
      cur=strip(cur,'B','"');
      if (cur=='') break;
      cur=maybe_quote_filename(cur);
      configs[config_index].jars[configs[config_index].jars._length()]=cur;
   }
   configs[config_index].jars._sort('F');

   _SetDialogInfo(JAVA_COMP_PROP_ALL_CONFIGS,configs);
   _SetDialogInfo(JAVA_COMP_PROP_MODIFIED, true);

   ctl_compiler_name.p_line = config_index + 1;
}

void ctl_delete_jar.lbutton_up()
{
   JavaCompilerConfiguration configs[]=_GetDialogInfo(JAVA_COMP_PROP_ALL_CONFIGS);
   int config_index=_GetDialogInfo(JAVA_COMP_PROP_SELECTED_CONFIG);
   int cur_inc=_GetDialogInfo(JAVA_COMP_PROP_SELECTED_INC);

   if ( (cur_inc>=0) && (cur_inc<configs[config_index].jars._length())) {
      configs[config_index].jars._deleteel(cur_inc);

      _SetDialogInfo(JAVA_COMP_PROP_ALL_CONFIGS,configs);
      if (cur_inc>=configs[config_index].jars._length()) {
         _SetDialogInfo(JAVA_COMP_PROP_SELECTED_INC,cur_inc-1);
      }
      _SetDialogInfo(JAVA_COMP_PROP_MODIFIED, true);
      ctl_compiler_name.p_line = config_index + 1;
   }

}

void ctl_system_libraries.on_change(int reason)
{
   if (reason==CHANGE_SELECTED) {
      _SetDialogInfo(JAVA_COMP_PROP_SELECTED_INC,p_line-1);
   }
}
