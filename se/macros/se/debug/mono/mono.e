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
#include "project.sh"
#import "compile.e"
#import "debug.e"
#import "debuggui.e"
#import "diffprog.e"
#import "guicd.e"
#import "guiopen.e"
#import "help.e"
#import "listbox.e"
#import "main.e"
#import "picture.e"
#import "project.e"
#import "projconv.e"
#import "projutil.e"
#import "seltree.e"
#import "stdprocs.e"
#import "tags.e"
#import "treeview.e"
#import "wkspace.e"
#endregion

/**
 * Placeholder command for launching JDWP debugger
 * 
 * @return int 
 */
_command int debug_mono_start() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   return 0;
}
int _OnUpdate_debug_mono_start(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   return(MF_ENABLED);
}

///////////////////////////////////////////////////////////////////////////
// Callbacks for Mono debugger integration
//
bool _mono_ToolbarSupported(_str FormName)
{
   switch (FormName) {
   case '_tbdebug_regs_form':
   case '_tbdebug_memory_form':
      return(false);
   }
   return(true);
}

//debug=copts: |dialog:_java_options_form:Debugger|readonly|menu: Debug:&Debugcmd: mono --debugger-agent="transport=dt_socket,address=$ADDRESS:$PORT"
bool _mono_ConfigNeedsDebugMenu(_str debug_command)
{
   return (pos('--debugger-agent=',debug_command,1,'i')!=0);
}
bool _mono_DebugCommandCaptureOutputRequiresConcurrentProcess(_str debug_command)
{
   return (debug_command=='' || pos('--debugger-agent=',debug_command,1,'i')!=0);
}


///////////////////////////////////////////////////////////////////////////
// Callbacks for Mono debugger attach form
//
defeventtab _debug_mono_attach_form;
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
   max_width := ctl_session_combo.debug_load_session_names("mono", session_name);
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
// Callbacks for Mono debug other executable attach form
//
defeventtab _debug_mono_executable_form;
static void debug_gui_executable_ok(_str command)
{
   // verify that the core file was specified
   program_name := ctl_file.p_text;
   program_args := ctl_args.p_text;
   if (program_name=='') {
      debug_message("Expecting a Java class or jar file!",0,true);
      ctl_file._set_focus();
      return;
   } else if (!file_exists(_maybe_unquote_filename(program_name))) {
      debug_message(program_name,FILE_NOT_FOUND_RC,true);
      return;
   }

   // get the working directory specified
   dir_name := ctl_dir.p_text;
   if (dir_name != '' && !file_exists(_maybe_unquote_filename(dir_name))) {
      debug_message(dir_name,FILE_NOT_FOUND_RC,true);
      return;
   }

   // get the session name
   session_name := ctl_session_combo.p_text;
   
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
   max_width := ctl_session_combo.debug_load_session_names("mono", session_name);
   max_width += 500;
   if (max_width > ctl_session_combo.p_width) {
      p_active_form.p_width += (max_width - ctl_session_combo.p_width);
      ctl_dir.p_width = max_width;
      ctl_file.p_width = max_width;
      ctl_args.p_width = max_width;
      ctl_session_combo.p_width = max_width;
   }

   // align the browse buttons to the text boxes
   _debug_mono_executable_form_initial_alignment();

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
static void _debug_mono_executable_form_initial_alignment()
{
   sizeBrowseButtonToTextBox(ctl_file, ctl_find_exec.p_window_id);
   sizeBrowseButtonToTextBox(ctl_dir, ctl_find_dir.p_window_id);
}

///////////////////////////////////////////////////////////////////////////
// Callbacks for JDWP to get the list of exceptions
//

/**
 * Insert the set of Mono Exceptions into the given list (current object)
 */
void dbg_mono_list_exceptions(_str (&exception_list)[])
{
   if (!_haveContextTagging()) {
      return;
   }
   // parallel arrays of classes and inheritance status
   _str class_name,class_parents;
   _str class_list[];
   _str parent_list[];
   _str sorted_list[];
   int result_list[];
   int class_hash:[];

   // show progress form
   gauge_form := progress_show("Finding Exception Classes",100);

   // save the original setting for the array size warning
   orig_threshold := _default_option(VSOPTION_WARNING_ARRAY_SIZE);
   curr_threshold := orig_threshold;

   // get all the classes from the Java tag files
   tag_files := tags_filenamea("cs");
   i := 0;
   tag_filename := next_tag_filea(tag_files,i,false,true);
   while (tag_filename!="") {
      status := tag_find_class(class_name);
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
         if (class_parents=="" && class_name!="System.Exception" && class_name!="System/Exception") {
            status=tag_next_class(class_name);
            continue;
         }
         // normalize the class name and add to lists
         sorted_list :+= class_name"\t"class_parents;
         // next please
         status=tag_next_class(class_name);
      }
      tag_reset_find_class();
      tag_filename=next_tag_filea(tag_files,i,false,true);
   }
   class_hash._makeempty();

   gauge_wid := progress_gauge(gauge_form);
   gauge_wid.p_max=sorted_list._length();
   sorted_list._sort();

   // sort the class list, parent list, and result list
   n := sorted_list._length();
   for (i=0; i<n; ++i) {
      parse sorted_list[i] with class_name "\t" class_parents;
      class_list :+= class_name;
      parent_list :+= class_parents;
      result_list :+= (class_name=="System.Exception" || class_name=="System/Exception")? 1:-1;
   }

   // insert each class that derives from 'Exception'
   VS_TAG_RETURN_TYPE visited:[];
   exception_list._makeempty();
   for (i=0; i<n; ++i) {
      if (debug_class_derives_from(i,"System.Exception",class_list,parent_list,result_list,tag_files,visited,1) ||
          debug_class_derives_from(i,"System/Exception",class_list,parent_list,result_list,tag_files,visited,1)) {
         class_name=class_list[i];
         debug_translate_class_name(class_name);
         exception_list :+= class_name;
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

