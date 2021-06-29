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
#include "plugin.sh"
#import "clipbd.e"
#import "compile.e"  
#import "dir.e"
#import "dlgeditv.e"
#import "eclipse.e"
#import "files.e"
#import "hex.e"
#import "ini.e"
#import "listbox.e"
#import "main.e"
#import "moveedge.e"
#import "mprompt.e"
#import "proctree.e"
#import "recmacro.e"
#import "saveload.e"
#import "sellist.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tbfilelist.e"
#import "tbview.e"
#import "se/ui/mainwindow.e"
#import "se/ui/twevent.e"
#import "toolbar.e"
#import "util.e"
#import "vc.e"
#import "window.e"
#import "wkspace.e"
#import "se/color/SymbolColorAnalyzer.e"
#import "fileman.e"
#import "autosave.e"
#import "put.e"
#import "beautifier.e"
#import "cfg.e"
#import "seek.e"
#endregion

static int window_config_id;
static _str clean_up_buf_ids;
static int dsRestoredENQ:[];

static const READONLY_ON= 0x1;
static const READONLY_SET_BY_USER= 0x2;
_str _no_resize;

/**
 * @return Returns the directory used to store auto restore files (see 
 * <b>auto_restore</b> command).
 * 
 * @categories File_Functions
 * 
 */ 
_str restore_path(typeless mustExist="")
{
   path := get_env(_SLICKRESTORE);
   if ( rc ) {
      path=_ConfigPath();
      if (path=='') {
         path=editor_name('p');
      }
      /* If directory must exist and it does not.  */
      if ( mustExist && !isdirectory(path) ) {
         path='';
      }
   }
   _maybe_append_filesep(path);
   return(path);

}

/*
  Read in the window configuration file and create the same window/buffer
  size and positions.

    arg(1)     _str restore_option (Optional).  String of one or more
               of the following option letters.

                 N indicates restore without restore files.
                 R indicates restore everything.
                 G Just restore global info because we already
                   restore other information from the project file.
                 I Restoring from editor invocation.

    arg(2)     _str view_id (Optional).  View id which correndponds
               to restore file data.  Cursor should be at first
               line of restore information.

  To auto restore your own data define a global (not static)
  function that starts with "_sr_" or "_srg_".  The return type
  of your function is int.  Return 0 if successful.

  When SAVING restore information your function is called as follows:

    _sr_mymarker();    The function must use LOWER CASE letters only.
                       Sorry, we needed this for backward compatibility.
                       Your function should use insert_line(...) to
                       insert a header line as follows:

                         mymarker:  NoflinesWhichFollowThisLine [UserData]

                       mymarker: Must be the same name as the function
                       after the "_sr_".  UserData is optional.

  Note:  If you want your restore information stored globally
         (Not per project), prefix your function name with
         "_srg_" instead of "_sr_".

  When RESTORING, your function is called as follows

    _sr_mymarker(_str restore_option,_str LineAfterColon,
                bool RestoringFromInvocation);

       restore_option     "N" or "R".  The N option indicates that files
                          are not being restored.  This occurs when the
                          user specifies a file argument from the command
                          line.
       LineAfterColon     Header line from auto restore buffer not including
                          leading mymarker: data.

       RestoringFromInvocation   'true' if restoring from an editor invocation.
                                 You may not want you information changed
                                 when the user switches projects.

*/
static bool gHitLayoutSection;
static bool gHitOldToolbarsSection;
static bool gHitGlobalSection;

/**
 * Resumes the last edit session which was terminated by the 
 * <b>safe_exit</b> command.  The <b>safe_exit</b> command will 
 * save the window/buffer configuration only if auto restore is set to on.  
 * When auto restore is on and the editor is invoked with no file or 
 * command parameters, the <b>restore</b> command is automatically 
 * invoked.  SlickEdit stores auto restore information in
 * the file "vrestore.slk". You may define an environment
 * variable called VSLICKRESTORE and assign it a path where you
 * want SlickEdit to look for this file.
 *
 * <p>
 *
 * <code>hints</code> are 1 or more of
 * <code>AutoRestoreHint</code>. 
 *
 * @param options 
 * @param alternate_view_id 
 * @param relativeToDir 
 * @param hints 
 * 
 * @see auto_restore
 * @see save_window_config
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
_command restore(_str options='', int alternate_view_id=0, _str relativeToDir=null, int hints=0)
{
   /* Due to a crash bug in the new tool window code. Can't display the Output tool window 
      during Auto Restore. The gin_restore variable indicates whether the the code is in auto
      restore.
   */

   ++gin_restore;
   gdelayed_activateOutputWindow=false;
   int result=_restore(options,alternate_view_id,relativeToDir,hints);
   --gin_restore;
   if ( gdelayed_activateOutputWindow ) {
      formwid := activateOutputWindow(false);
      if (!_no_child_windows()) {
          _mdi.p_child._set_focus();
      }
   }

   // up-front work is done, idle time counter starts now
   _reset_idle();

   return result;
}
static int _restore(_str restore_options='', int alternate_view_id=0, _str relativeToDir=null, int hints=0) {
   //say('restore : restore_options='restore_options);
   //say('restore : alternate_view_id='alternate_view_id);
   //say('restore : hints='hints);

   //this is a little bit of a hack.
   //the quit() function for the file
   //will try to call in to eclipse to close the editor
   //if this flag isn't set.  We have to set it back at all
   //return points as well.
  if ( isEclipsePlugin() ) {
      setInternalCallFromEclipse(true);
   }

   RestoringFromInvocation := false;
   restore_options = upcase(restore_options);
   if ( pos('I', restore_options) ) {
      RestoringFromInvocation = true;
   }

   if ( RestoringFromInvocation && (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_WINDOW) ) {
      _mdi._ShowWindow();
   }

   typeless status=0;
   restore_filename := "";
   alternate_buf_id := 0;
   temp_view_id := 0;
   junk_view_id := 0;
   restoring_from_autosave := false;
   restoring_workspace := false;
   int orig_def_restore_flags=def_restore_flags;
   _str saved_by_edition='';

   if ( alternate_view_id ) {
      clean_up_buf_ids = '';
      activate_window(alternate_view_id);
      alternate_buf_id = p_buf_id;
   } else {
      if ( _default_option(VSOPTION_DONT_READ_CONFIG_FILES) ) {
         return 0;
      }
      activate_window(VSWID_HIDDEN);
      restore_filename = editor_name("r");
      if ( restore_filename == '' ) {
         restore_filename = editor_name('p'):+_WINDOW_CONFIG_FILE;
         if ( restore_filename == '' ){
            if ( isEclipsePlugin() ) {
               setInternalCallFromEclipse(false);
            }
            return 0;
         }
      }
      status = _open_temp_view(restore_filename, temp_view_id, junk_view_id);
      if ( status ) {
         if ( status == NEW_FILE_RC ) {
            _delete_buffer();
         }
         reset_window_layout();
         if ( isEclipsePlugin() ) {
             setInternalCallFromEclipse(false);
          }
         return 1;
      }
      if (RestoringFromInvocation) {
         get_line(auto maybe_config_monitors_line);
         typeless count;
         parse maybe_config_monitors_line with auto first_word count .;
         if (first_word=='MONITOR_CONFIGS:' && isinteger(count)) {
            down(count);
         }

         down(2);
         get_line(auto invocation_info);
         if (substr(invocation_info,1,16):=='INVOCATION-INFO:') {
            parse invocation_info with ':' . auto inAutoRestore auto str_restoring_workspace saved_by_edition .;
            restoring_from_autosave= (inAutoRestore!=0) && _default_option(VSOPTION_NEW_OPTION)!=2;
            restoring_workspace= (str_restoring_workspace!=0);
            if (restoring_from_autosave) {
               def_restore_flags|=RF_WORKSPACE|RF_PROJECTFILES;
            }
         }
         top();
         if (restoring_from_autosave) {
            // We have to restore files since there are modified files which need to be restored.
            restore_options='I';
         } else if (restoring_workspace && restore_options=='IN'  && (def_restore_flags&RF_WORKSPACE) && (def_restore_flags&RF_PROJECTFILES)) {
            restore_options='I';
         }
      }
      clean_up_buf_ids = '';
   }
   restoreFiles := !testFlag(hints, RH_NO_RESTORE_FILES) || restoring_from_autosave;
   restoreLayout := !testFlag(hints, RH_NO_RESTORE_LAYOUT);
   resetLayout := !testFlag(hints, RH_NO_RESET_LAYOUT);
   restoringFromProject := testFlag(hints, RH_RESTORING_FROM_PROJECT);

   if ( pos('G', restore_options) ) {
      // Only restore global info.
      // v19 : Since tool-window layout is no longer global we need to force it off.
      restoreLayout = false;
      // If we are not restoring the layout, then it makes no sense to reset it 
      // when we don't find what we weren't looking for.
      resetLayout = false;
   }

   vanilla_restore_case := ( !alternate_view_id && _file_eq(_strip_filename(restore_filename,'P'), _WINDOW_CONFIG_FILE) );
   gHitLayoutSection = false;
   gHitOldToolbarsSection = false;
   gHitGlobalSection = false;
   orig_actapp := def_actapp;
   def_actapp |= ACTAPP_DONT_RELOAD_ON_SWITCHBUF;
   status = restore2(restore_options, relativeToDir, restoreFiles, restoreLayout, restoringFromProject);
   def_actapp = orig_actapp;
   def_restore_flags=orig_def_restore_flags;
   autorestore_from_lower_edition:=saved_by_edition!='' && _edition_to_number(_editionid())>_edition_to_number(saved_by_edition);
   if ( autorestore_from_lower_edition || 
        (!gHitLayoutSection && resetLayout &&
        (gHitGlobalSection || vanilla_restore_case || restoreLayout) 
        )
      ) {

      // Nuke it from orbit. It's the only way to be sure.
      // Note that if we hit an old TOOLBARS5 section (gHitOldToolbarsSection==true), then
      // we do NOT reset toolbars.
      reset_window_layout(!gHitOldToolbarsSection);
   }
   view_id := 0;
   if ( alternate_view_id ) {
      get_window_id(view_id);
      activate_window(alternate_view_id);
      if (p_buf_name != '.process') {
         p_buf_id = alternate_buf_id;
      }
      activate_window(view_id);
   } else {
      get_window_id(view_id);
      _delete_temp_view(temp_view_id);
      if ( view_id != temp_view_id ) {
         activate_window(view_id);
      }
   }
   if ( isEclipsePlugin() ) {
      setInternalCallFromEclipse(false);
   }

   return status;
}

static bool screen_size_changed;

static int restore2(_str restore_options, _str relativeToDir, bool restoreFiles, bool restoreLayout, bool restoringFromProject,int restoreOnlyFloatingLayout=-1)
{
   // Initialize data set ENQ failed list.
   dsRestoredENQ._makeempty();
   dsRestoredENQ:["JUNK"] = 0; // force this var to be a hash table

   view_id := 0;
   _open_temp_view('',window_config_id,view_id,'+bi 'p_buf_id);

   do_one_window := false;
   typeless mdi_state="";
   JustRestoreGlobalInfo := false;
   RestoringFromInvocation := false;
   inAutoSave := false;
   restore_options=upcase(restore_options);
   if (pos("I",restore_options)) {
      restore_options=stranslate(restore_options,"","I");
      RestoringFromInvocation=true;
   }
   // IF we already restored from project and just want to restore
   //    global auto restore info.
   if (pos("G",restore_options)) {
      restore_options=stranslate(restore_options,"","G");
      JustRestoreGlobalInfo=true;
      restore_options="N";
   }
   callback_prefix := "_sr_";
   typeless screen_size_line="";
   if (!(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_SAVERESTORE_EDIT_WINDOWS)) {
      restore_options='N';
   }

   typeless status=0;
   typeless width=0;
   typeless height=0;
   typeless mdi_x, mdi_y, mdi_width, mdi_height;
   typeless count=0;
   v := "";
   buf := "";
   typeless line = '';
   type := "";
   ntype := "";
   rtype := "";
   bi_info := "";
   viewline := "";
   bufferline := "";
   WorkspaceCallbackIndex := 0;
   WorkspaceLine := -1;
   screen_size_changed = false;
   int modified_temp_name2buf_id:[];
   bool unable_to_restore_file:[];
   _str monitor_config=_get_monitor_config();
   _str first_monitor_config='';
   bool in_monitor_configs=false;
   AUTORESTORE_MONITOR_CONFIG monitor_configs:[];
   monitor_configs._makeempty();
   bool monitor_configs_defined=false;
   for (;;) {
      // Try to skip reading garbage
      for (;;) {
         get_line(line);
         if (pos('^:v\:',line,1,'r')) {
            break;
         }
         if(down()) {
            line='';
            break;
         }
      }
      if (line:=='') {
         status=0;
         break;
      }
      parse line with rtype line;
      //say('ro='restore_options' ln='p_line' rtype=<'rtype'> 'line);
      // IF we are restoring files
      if ( restore_options != 'N' ) {
         if ( rtype == 'WINDOW:' ) {
            status = down();
            get_line(buf);
            parse buf with type bufferline;
            if ( !status && type=='BUFFER:' ) {
               down();
               get_line(v);
               activate_window(view_id);
               parse v with . viewline;
               if ( restoreFiles ) {
                  status = process_window(line, bufferline, viewline, relativeToDir,modified_temp_name2buf_id,unable_to_restore_file,inAutoSave);
               } else {
                  status = 0;
               }
            } else {

               if ( !status ) {
                  up();
               }

               /* 
                  Now that the 10.0 code always gives buffer and view data for windows,
                  just don't create the window for this case and users can just
                  create a new window and the do a next buffer.
               */
               status = 0;
            }
            if ( status == PROCESS_ALREADY_RUNNING_RC ) {
               // already open or will be opened later
               status = 0;
            } else if ( status ) {
               //clean_up();
               if ( status != NEW_FILE_RC ) {
                  _message_box('Restore: 'get_message(status));
               }
               break;
               //return(status);
            }
            get_window_id(view_id);

         } else if ( rtype == 'BUFFER:' ) {
            down();
            get_line(bi_info);
            parse bi_info with ntype bi_info;
            down();
            get_line(viewline);
            parse viewline with ntype viewline;
            activate_window(view_id);
            if ( restoreFiles ) {
               load_file_status := 0;
               status = process_buffer(line, '', bi_info, relativeToDir, load_file_status,modified_temp_name2buf_id,unable_to_restore_file,true,inAutoSave);
               if ( status == PROCESS_ALREADY_RUNNING_RC ) {
                  // already open or will be opened later
                  status = 0;
               } else if ( status ) {
                  //clean_up()
                  if ( status != NEW_FILE_RC ) {
                     _message_box('Restore: 'get_message(status));
                  }
                  break;
                  //return(status)
               } else {
                  process_view(viewline);
               }
            }
         } else if ( rtype == 'MARK:' ) {
            if ( restoreFiles ) {
               restore_select_data();
            }
         /*} else if( rtype == 'MDISTATE:' ) {
            parse line with count .;
            if ( (int)count > 0 ) {
               down();
               state := "";
               get_line(state);
               down(--count);
               if ( restoreFiles ) {
                  process_mdistate(state);
               }
            }*/
         }
      }
      if ( rtype == 'RETRIEVE:' ) {
         restore_retrieve_data(line);
      } else if ( rtype == 'DIALOGS:') {
         _xsrg_dialogs('R', line/*,RestoringFromInvocation*/);
      } else if ( rtype == 'GSTART:' ) {
         gHitGlobalSection = true;
         callback_prefix = '_srg_';
      } else if ( rtype == 'GEND:' ) {
         callback_prefix = '_sr_';
         if ( JustRestoreGlobalInfo && !in_monitor_configs) {
            //messageNwait("restore2: JustRestoreGlobalInfo="JustRestoreGlobalInfo);
            status = 0;
            break;
         }
         if (!JustRestoreGlobalInfo && restoreFiles && !restoringFromProject) {
            // Process the screen entry. 
            // Do this BEFORE hitting "WINDOW:" entries. We need screen_size_changed set.
            // screen_size_changed is only needed for OEM's (not SlickEdit) that use editor control.

            AUTORESTORE_MONITOR_CONFIG *pmonitor_config=null;
            if (_default_option(VSOPTION_AUTORESTORE_MULTIPLE_MONITOR_CONFIGS)) {
               pmonitor_config=monitor_configs._indexin(_get_monitor_config());
            }
            if (!pmonitor_config) {
               pmonitor_config=monitor_configs._indexin(first_monitor_config);
            }
            if (pmonitor_config) {
               line=pmonitor_config->m_screen;

               screen_size_line = line;
               parse line with width height mdi_x mdi_y mdi_width mdi_height . . . . . . . .   . auto fs;
               /* If screen size different */
               if ( _screen_height() != height || _screen_width() != width ) {
                  screen_size_changed = true;
               } else if ( _configMigrated() ) {
                  // The application attempted to restore its geometry BEFORE the config was migrated,
                  // so would have failed to find a config. This only happens when a config is migrated.
                  // Fix it up now.
                  _mdi._move_window(mdi_x, mdi_y, mdi_width, mdi_height);
               }

               // DJB 03-14-2007 -- restore fullscreen mode
               if ( fs == 1 ) {
                  fullscreen(1);
               }
            }
         }

      } else if ( rtype == 'SCREEN:' /*&& !JustRestoreGlobalInfo && restoreFiles && !restoringFromProject*/ ) {
         if (first_monitor_config=='') first_monitor_config=monitor_config;
         monitor_configs:[monitor_config].m_screen=line;
#if 0
         screen_size_line = line;
         parse line with width height mdi_x mdi_y mdi_width mdi_height . . . . . . . .   . auto fs;
         /* If screen size different */
         if ( _screen_height() != height || _screen_width() != width ) {
            screen_size_changed = true;
         } else if ( _configMigrated() ) {
            // The application attempted to restore its geometry BEFORE the config was migrated,
            // so would have failed to find a config. This only happens when a config is migrated.
            // Fix it up now.
            _mdi._move_window(mdi_x, mdi_y, mdi_width, mdi_height);
         }

         // DJB 03-14-2007 -- restore fullscreen mode
         if ( fs == 1 ) {
            fullscreen(1);
         }
#endif

      } else if ( rtype == 'MONITOR_CONFIG:') {
         parse line with count line;
         if (first_monitor_config=='') first_monitor_config=line;
         monitor_config=line;
         monitor_configs:[monitor_config].m_monitor_config=monitor_config;

      } else if ( rtype == 'END_MONITOR_CONFIGS:') {
         monitor_configs_defined=true;
         in_monitor_configs=false;
      } else if ( rtype == 'MONITOR_CONFIGS:') {
         in_monitor_configs=true;
      } else if ( pos('_LAYOUT',rtype) || pos('_WINDOW',rtype) || pos('MONCFG_',rtype)) {
         //say('hit layout stuff rtype='rtype);
         if (first_monitor_config=='') first_monitor_config=monitor_config;

         parse line with count .;
         _begin_line();
         typeless start_seek= _nrseek();
         // DEBUG_WINDOW2 does not have a count
         if (isinteger(count)) {
            down(count);
         }
         _end_line();
         _str text=get_text(_nrseek()-start_seek,start_seek);
         text=stranslate(text,"","\r");

         if (callback_prefix=='_sr_') {
            monitor_configs:[monitor_config].m_project_mon_info:[rtype]=text;
         } else {
            monitor_configs:[monitor_config].m_global_mon_info:[rtype]=text;
         }
      } else if( rtype == 'MDISTATE:' ) {
         if (first_monitor_config=='') first_monitor_config=monitor_config;
         parse line with count .;
         if ( (int)count > 0 ) {
            down();
            state := "";
            get_line(state);
            down(--count);
            monitor_configs:[monitor_config].m_mdistate=state;

            /*if ( restoreFiles ) {
               process_mdistate(state);
            } */
         }
      } else if ( rtype == 'CWD:' && (def_restore_flags & RF_CWD) &&
                  (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_SAVERESTORE_CWD) ) {

         if ( !JustRestoreGlobalInfo ) {
            //chdir(line,1);
            // Don't have to call cd here, but we must do call_list
            // and it make sense to do process_cd
            cd('-a '_maybe_quote_filename(absolute(line, relativeToDir)));
         }
      } else if ( rtype == 'AUTOSAVE:') {
         inAutoSave=true && _default_option(VSOPTION_NEW_OPTION)!=2;
      }

      if ( rtype == 'APP_LAYOUT:' ) {
         gHitLayoutSection = true;
      }
      if ( rtype == 'TOOLBARS5:' ) {
         gHitOldToolbarsSection = true;
      }

      if ( !pos(rtype, 'MONITOR_CONFIGS:END_MONITOR_CONFIGS:MONITOR_CONFIG:SCREEN:GSTART:GEND:CWD:RETRIEVE:DIALOGS:MARK:WINDOW:BUFFER:BI:VIEW:MDISTATE:') && 
           !pos('_LAYOUT',rtype) && !pos('_WINDOW',rtype) && !pos('MONCFG_',rtype) // Stored in monitor_configs and processed specially.
           ) {
         //_mdi.p_visible=true;messageNwait("rtype="rtype);
         name :=  callback_prefix:+strip(lowcase(rtype), '', ':');
         index := find_index(name, PROC_TYPE);
         // IF there is a callable function
         if ( index_callable(index) ) {

            typeHandled := false;

            // do we want to restore a workspace?
            if ( rtype == 'WORKSPACE:' ) {
               if ( !gHitLayoutSection ) {
                  //4:52pm 2/10/2000
                  //We do not want to run the workspace restore until after the
                  //toolbar restore has run.
                  //This is because a SCC version control system being initialized
                  //may cause output to the Output toolbar, which would show the
                  //output toolbar.  Restore would then show another copy.
                  WorkspaceCallbackIndex=index;
                  WorkspaceLine = p_line;
                  parse line with count .;
                  down(count);

                  typeHandled = true;
               }

            } else if ( rtype == 'APP_LAYOUT:' && !restoreLayout ) {
               parse line with count .;
               down(count);
               typeHandled = true;
            }

            if ( !typeHandled ) {
               // just call the callback for this one
               _str a1 = restore_options;
               if ( a1 == '' ) {
                  a1 = 'R';
               }
               status = call_index(a1, line, RestoringFromInvocation, relativeToDir, index);
               if ( status ) {
                  break;
               }
            }
         } else {
            // Skip over lines that cannot be processed
            parse line with count .;
            if ( isnumber(count) ) {
               down(count);
            }
         }
      }
      activate_window(window_config_id);
      if ( down() ) {
         status = 0;
         break;
      }
   }
   activate_window(window_config_id);
   // if ( restore_options != 'N' ) {
   AUTORESTORE_MONITOR_CONFIG *pmonitor_config=null;
   if (_default_option(VSOPTION_AUTORESTORE_MULTIPLE_MONITOR_CONFIGS)) {
      pmonitor_config=monitor_configs._indexin(_get_monitor_config());
   }
   if (!pmonitor_config) {
      pmonitor_config=monitor_configs._indexin(first_monitor_config);
   }
   if (pmonitor_config) {
      // screen line already processsed
      if (restoreFiles && restore_options != 'N' ) {
         if (!pmonitor_config->m_mdistate._isempty()) {
            process_mdistate(pmonitor_config->m_mdistate);
            activate_window(window_config_id);
         }
      }
      if(restoreOnlyFloatingLayout<0) {
         restoreOnlyFloatingLayout=(RestoringFromInvocation?0:1);
      }
      if (!pmonitor_config->m_global_mon_info._isempty()) {
         apply_autorestore_layout_info(pmonitor_config->m_global_mon_info,'_srgmon_',RestoringFromInvocation, relativeToDir, restoreLayout, restore_options, restoreOnlyFloatingLayout);
         activate_window(window_config_id);
      }
      if (!pmonitor_config->m_project_mon_info._isempty()) {
         apply_autorestore_layout_info(pmonitor_config->m_project_mon_info,'_srmon_',RestoringFromInvocation, relativeToDir, restoreLayout, restore_options, restoreOnlyFloatingLayout);
         activate_window(window_config_id);
      }
   }
   merge_monitor_configs(monitor_configs);
   activate_window(window_config_id);


   if ( WorkspaceCallbackIndex ) {
      //4:54pm 2/10/2000
      //Deferred calling the workspace callback earlier.
      //4:52pm 2/10/2000
      //We do not want to run the workspace restore until after the
      //toolbar restore has run.
      //This is because a SCC version control system being initialized
      //may cause output to the Output toolbar, which would show the
      //output toolbar.  Restore would then show another copy.
      save_pos(auto p);
      p_line = WorkspaceLine;
      get_line(line);
      parse line with rtype line;
      _str a1 = restore_options;
      if ( a1 == '' ) {
         a1 = 'R';
      }
      if ( RestoringFromInvocation && line != '' && line != '0' ) {
         restore_info := line;
         restore_name := parse_file(restore_info, false);
         restore_name = parse_file(restore_info, false);
         restore_name = _strip_filename(restore_name, 'P');
         _SplashScreenStatus('Opening workspace: 'restore_name);
      }
      typeless status2 = call_index(a1, line, RestoringFromInvocation, WorkspaceCallbackIndex);
      if ( status2 ) {
         clean_up();
         return(status2);
      }
      activate_window(window_config_id);
      restore_pos(p);
   }
   if ( status ) {
      clean_up();
      return(status);
   }
   //messageNwait('after loop');
   activate_window(view_id);
   clean_up();

   if (!(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_SAVERESTORE_EDIT_WINDOWS)) {
   } else {
      if (screen_size_line!="") {
         set_screen_size(screen_size_line,do_one_window,mdi_state,RestoringFromInvocation);
      }
   }
   // IF we are restoring files AND MDI screen size changed AND
   //    we are not in one file per window mode
   if (restore_options!='N' && do_one_window && def_one_file=='') {
      one_window();
   }
#if 0
   if (mdi_state!='') {
      // Unfortunately change the state to iconized does not work.
      if (mdi_state!='I') {
         _mdi.p_window_state=mdi_state;
      }
   }
#endif
   //old_line=line;
   return(0);
}
static void apply_autorestore_layout_info(_str (&mon_info):[], _str callback_prefix, bool RestoringFromInvocation, _str relativeToDir, bool restoreLayout, _str restore_options,int restoreOnlyFloatingLayout) {
   //say('callback='callback_prefix' inv='RestoringFromInvocation' layout='restoreLayout' restore_options='restore_options);
   orig_wid:=_create_temp_view(auto temp_wid);
   typeless count=0;
   _str text;
   _str rtype;
   foreach (rtype=>text in mon_info) {
      activate_window(temp_wid);
      _lbclear();
      if (text!='') {
         _insert_text(text);
         top();
         get_line(auto line);
         parse line with rtype line;
         name :=  callback_prefix:+strip(lowcase(rtype), '', ':');
         index := find_index(name, PROC_TYPE);
         // IF there is a callable function
         if ( index_callable(index) ) {
            //say('proc='name_name(index));
            typeHandled := false;

            if ( rtype == 'APP_LAYOUT:' && !restoreLayout ) {
               parse line with count .;
               down(count);
               typeHandled = true;
            }

            if ( !typeHandled ) {
               // just call the callback for this one
               _str a1 = restore_options;
               if ( a1 == '' ) {
                  a1 = 'R';
               }
               status := call_index(a1, line, RestoringFromInvocation, relativeToDir, restoreOnlyFloatingLayout,index);
               if ( status ) {
                  break;
               }
            }
         }
      }
   }
   _delete_temp_view(temp_wid);
}
static void merge_autorestore_info(_str (&mon_info):[],_str (&dest_mon_info):[]) {
   _str text;
   _str rtype;
   foreach (rtype=>text in mon_info) {
      if (text!='') {
         dest_mon_info:[rtype]=text;
      }
   }
}
static void merge_monitor_configs(AUTORESTORE_MONITOR_CONFIG (&monitor_configs):[]) {
   AUTORESTORE_MONITOR_CONFIG config;
   _str monitor_config;
   foreach (monitor_config=>config in monitor_configs) {
      if(config.m_monitor_config==null) {
         config.m_monitor_config=_get_monitor_config();
      }
      if (config.m_monitor_config=='') {
         continue;
      }
      gautorestore_monitor_configs:[monitor_config].m_monitor_config=config.m_monitor_config;
      if (config.m_screen!=null && config.m_screen!='') {
         gautorestore_monitor_configs:[monitor_config].m_screen=config.m_screen;
      }
      if (config.m_mdistate!=null && config.m_mdistate!='') {
         gautorestore_monitor_configs:[monitor_config].m_mdistate=config.m_mdistate;
      }
      if (!config.m_global_mon_info._isempty()) {
         merge_autorestore_info(config.m_global_mon_info,gautorestore_monitor_configs:[monitor_config].m_global_mon_info);
         //gautorestore_monitor_configs:[monitor_config].m_global_mon_info=config.m_global_mon_info;
      }
      if (!config.m_project_mon_info._isempty()) {
         merge_autorestore_info(config.m_project_mon_info,gautorestore_monitor_configs:[monitor_config].m_project_mon_info);
         //gautorestore_monitor_configs:[monitor_config].m_project_mon_info=config.m_project_mon_info;
      }
   }
}
static void restore_select_data()
{
#if 0
   line := "";
   get_line(line);
   line_type := "";
   mt := "";
   buf_name := "";
   typeless start_line=0;
   typeless start_col=0;
   typeless last_line=0;
   typeless end_col=0;

    //MARK: MT=BLOCK BN="f:\temp\junk-utf8s.txt" SL=.527 SC=3 LL=.544 EC=5

   parse line with line_type 'MT='mt'BN='buf_name'SL='start_line'SC='start_col'LL='last_line'EC='end_col;
   temp_view_id := 0;
   this_buf := 0;
   int status=_open_temp_view(strip(strip(buf_name),'B','"'),temp_view_id,this_buf,'+b');
   if ( status) {
      clear_message();
      return;
   }
   _deselect();
   _goto_rpoint(start_line);p_col=start_col;select_it(mt,'');
   _goto_rpoint(last_line);p_col=end_col;select_it(mt,'');
   _delete_temp_view(temp_view_id);
   activate_window(this_buf);
#endif
}
static _str process_window(_str line,_str bufferline,_str viewline,_str relativeToDir,int (&modified_temp_name2buf_id):[],bool (&unable_to_restore_file):[],bool inAutoSave)
{
   typeless x=0, y=0, width=0, height=0, icon_x=0, icon_y=0, state=0;
   typeless wf="", wt="", font_info="";
   typeless dup_id="";
   typeless minimap_info='';
   parse line with x y width height icon_x icon_y state 'WF=' wf 'WT=' wt '"' font_info '"' 'DID='dup_id' MI="'minimap_info'"' .;
   if (font_info=='') {
      font_info=_default_font(CFG_WINDOW_TEXT);
   }

   // Trying to zoom during autorestore causes problems (e.g. tabs partially show when they should be hidden).
   // Since _MDIRestoreState() takes care of the layout (including zoomed windows), we just force 'N' for the
   // window-state.
   // TODO - Stop storing window-state with autorestore info??
   state = 'N';

   _str orig_state=state;
   if (machine()=='WINDOWS' && state=='I' && icon_x) {
      state='N';
   }
   font_name := "";
   typeless font_size=0;
   typeless font_flags=0;
   typeless charset=0;
   parse font_info with font_name "," font_size "," font_flags","charset;
   if (!isinteger(charset)) {
      charset=VSCHARSET_DEFAULT;
   }
   view_id := 0;
   get_window_id(view_id);
   load_file_status := 0;
   _no_resize=1;
   typeless status=0;
   if (screen_size_changed) {
      status=process_buffer(bufferline,'+i','',relativeToDir,load_file_status,modified_temp_name2buf_id,unable_to_restore_file,false,inAutoSave);
   } else {
      status=process_buffer(bufferline,'+i:'x' 'y' 'width' 'height' 'state,'',relativeToDir,load_file_status,modified_temp_name2buf_id,unable_to_restore_file,false,inAutoSave);
   }
   _no_resize='';
   /* messageNwait('status='status) */
   if ( status || !p_HasBuffer || load_file_status) {
      return(status);
   }
   p_old_x=x;p_old_y=y;p_old_width=width;p_old_height=height;
   if (icon_x>=0) {
      _no_resize=1;
      _MDIChildSetWindow(x,y,width,height,'N',icon_x,icon_y);
      if (machine()=='WINDOWS' && orig_state=='I') {
         p_window_state='I';
      }
      _no_resize='';
   }
   /* p_window_state=state */
   p_window_flags=wf;
   p_tile_id=wt;
   if(isinteger(dup_id)) {
      p_mdi_child_duplicate_id=dup_id;
   }

   //Process Font Information
   if (font_name!='') {
      p_redraw=false;
      p_font_name = font_name;
      p_font_size = font_size;
      p_font_bold = font_flags & F_BOLD;
      p_font_italic = font_flags & F_ITALIC;
      p_font_strike_thru = font_flags & F_STRIKE_THRU;
      p_font_underline = font_flags & F_UNDERLINE;
      p_font_charset= charset;
      p_redraw=true;
   }
   if (p_minimap_wid) {
      typeless minimap_font_name,minimap_font_size,minimap_width_is_fixed,minimap_width;
      parse minimap_info with minimap_font_name','minimap_font_size','minimap_width_is_fixed','minimap_width;
      if (minimap_font_name=='-') minimap_font_name='*';// Allow - to mean blank too.
      if (minimap_font_name!='*' || minimap_font_size!='') {
         p_minimap_wid.p_redraw=false;
         if (minimap_font_name!='*') {
            p_minimap_wid.p_font_name=minimap_font_name;
         }
         if (minimap_font_size!='') {
            p_minimap_wid.p_font_size=minimap_font_size;
         }
         p_minimap_wid.p_redraw=true;
      }
      if (minimap_width_is_fixed!='') p_minimap_wid.p_minimap_width_is_fixed=minimap_width_is_fixed;
      if (minimap_width!='') p_minimap_wid.p_minimap_width=minimap_width;
   }
   //End Process Font Information

   return(process_view(viewline));
}
static _str process_view(_str line)
{
   if ( line!='' && !beginsWith(p_buf_name,'.process')) {
      typeless ln="", cl="", le="", cx="", cy="", wi="", bi="";
      typeless hex_toppage="", hex_nibble="", hex_field="", hex_Nofcols="",hex_bytes_per_col="";
      parse line with 'LN=' ln ' CL=' cl ' LE=' le ' CX=' cx ' CY=' cy ' WI=' wi ' BI=' bi ' HT='hex_toppage' HN='hex_nibble' HF='hex_field' HC='hex_Nofcols' HB='hex_bytes_per_col .;
      cy *= p_font_height;
      cx *= p_font_width;
      _goto_rpoint(ln);
      typeless offset="";
      parse cl with '.' offset;
      if (offset!='') {
         try_EOR := (offset<0);
         if (try_EOR) {
            offset= -offset;
         }
         _GoToROffset(offset);
         if (p_col==1 && try_EOR) {
            up();_end_line();
         }
      }
      if (hex_toppage!=''/* && !p_UTF8*/) {
         p_hex_toppage=hex_toppage;
         p_hex_nibble=hex_nibble;p_hex_field=hex_field;
         p_hex_Nofcols=hex_Nofcols;
         if (isinteger(hex_bytes_per_col)) {
            p_hex_bytes_per_col=hex_bytes_per_col;
         }
      }
      /* if (pos('test.e',p_buf_name)) {trace} */
      if (offset=='') {
         p_col=cl;
      }
      set_scroll_pos(le,cy);
      /* message 'buf_name='p_buf_name' cy='cy' p_cursor_y='p_cursor_y' p_ch='p_client_height' font_name='p_font_name;get_event('r'); */
   }
   return(0);

}
static _str process_buffer(_str buf_info,_str window_options,_str bufferProperties,_str relativeToDir,int &load_file_status,int (&modified_temp_name2buf_id):[],bool (&unable_to_restore_file):[],bool setModifiedTempHash=false,bool inAutoSave=false)
{
   rest := "";
   parse buf_info with 'BN=' rest;
   _str bn=_replace_envvars2(parse_file(rest));
   _str orig_bn=bn;
   if (relativeToDir!=null) {
      bn=strip(bn,'B','"');
      if (bn=='') {
         bn=orig_bn;
      } else if (bn != '.process') {
         bn='"'absolute(bn,relativeToDir)'"';
      }
   }
   DocumentName := strip(parse_file(rest),'B','"');
   modified_temp_name := strip(parse_file(rest),'B','"');
   if (bn!='.process' && modified_temp_name!='') {
      if (setModifiedTempHash) {
         bn='"'modified_temp_name'"';
      } else {
         if (modified_temp_name2buf_id._indexin(modified_temp_name)) {
            bn="+bi "modified_temp_name2buf_id:[modified_temp_name];
         }
      }
   }
   typeless margins="", tabs="", word_wrap_style="";
   typeless indent_with_tabs="", ShowSpecialChars="";
   typeless indent_style="", buf_width="", undo_steps="";
   typeless readonly_flags="", showeof="", shownlchars="";
   typeless binary="", mode_name="", hex_mode="";
   typeless ModifyFlags="", TruncateLength="", MaxLineLength="";
   typeless AutoSelectLanguage="", line_numbers_len="", LCFlags="";
   typeless caps="", encoding="", encoding_set_by_user="";
   CLscheme := SCscheme := "";
   typeless SCenabled="", SCerrors="";
   typeless AutoLeftMargin,FixedWidthRightMargin;
   typeless hex_mode_reload_encoding="";
   typeless hex_mode_reload_buf_width="";
   typeless spell_check_while_typing="";
   typeless soft_wrap_flags='';
   typeless show_minimap='';
   typeless show_statements="";
   if ( bufferProperties!='' ) {
      parse bufferProperties with 'MA=' margins ' TABS=' tabs ' WWS=' word_wrap_style ' IWT=' indent_with_tabs 'ST=' ShowSpecialChars 'IN=' indent_style 'BW=' buf_width 'US=' undo_steps 'RO='readonly_flags 'SE=' showeof 'SN='shownlchars 'BIN='binary 'MN='mode_name"\t" 'HM='hex_mode' MF='ModifyFlags' TL='TruncateLength' MLL='MaxLineLength' ASE='AutoSelectLanguage' LNL='line_numbers_len' LCF='LCFlags' CAPS='caps' E='encoding' ESBU2='encoding_set_by_user' CL="'CLscheme'" SC="'SCscheme'" SCE='SCenabled' SCU='SCerrors' ALM='AutoLeftMargin' FWRM='FixedWidthRightMargin' HMRE='hex_mode_reload_encoding' HMRBW='hex_mode_reload_buf_width' SPCWT='spell_check_while_typing' SWF='soft_wrap_flags' SM='show_minimap' STAT='show_statements .;
   }
   if ( bn =='' ) {
      // bn should never be ''.  This code is here for completeness.
      return(FILE_NOT_FOUND_RC);
   }
   if ( buf_width==0 || buf_width=='' ) {
      buf_width='';
   } else {
      buf_width='+'buf_width;
   }
   /* messageNwait('window_options='window_options); */
   /* messageNwait('bn='bn); */
   typeless options="";
   typeless status=0;
   typeless result=0;
   special_case_hex_mode := false;
   if (strip(bn,'B','"')=='.process') {
      load_file_status=status=load_files('-w +q 'window_options' +b .process');
      if (def_restore_flags & RF_PROCESS) {
         _post_call(find_index("restore_build_window", COMMAND_TYPE));
         load_file_status = status = PROCESS_ALREADY_RUNNING_RC;
      }
   } else {
      options='';
      if (bufferProperties!='') {
         if (strip(binary))  {
            if (binary==1) {
               options :+= ' +lb';
            } else {
               options :+= ' +l8';
            }
         } else {
            if (strip(shownlchars)) options=options' +ln';
            if (strip(showeof)) options=options' +le';
         }
      }
      if (hex_mode==HM_HEX_ON && 
          (  (isinteger(hex_mode_reload_encoding) && hex_mode_reload_encoding)
           ||(isinteger(hex_mode_reload_buf_width) && hex_mode_reload_buf_width)
          )
         ) { 
         // This is a bit of desparation here for hex mode to place the cursor better.
         // If this causes a problem, it can be removed and the cursor will be off by
         // a little bit.
         options :+= ' +fu';
         special_case_hex_mode=true;
      } else {
         // IF encoding is valid AND the encoding was set by the user (not NULL<0)
         if (isinteger(encoding) && !(isinteger(encoding_set_by_user) && encoding_set_by_user<0)) {
            options :+= ' '_EncodingToOption(encoding);
         }
      }
      //say('bn='bn' setModifiedTempHash='setModifiedTempHash);
      // Time more quickly if accessing network file which is no longer accessible
      if (unable_to_restore_file._indexin(bn) || _findFirstTimeOut(strip(strip(bn),'B','"'),2000,0)) {
         //say('TIMEOUT');
         unable_to_restore_file:[bn]=true;
         p_window_id=_mdi._edit_window();
         if (setModifiedTempHash) {
            //say('case 1 NEW_FILE_RC');
            edit('-w +t');
            p_buf_name=strip(strip(bn),'B','"');
            load_file_status=status=NEW_FILE_RC;
         } else {
            //say('case 2 bn='bn);
            typeless buf_id=buf_match(strip(strip(bn),'B','"'),1,'XI');
            if (buf_id=='') {
               //say('no buf_id use load_files bufferProperties='bufferProperties);
               // This isn't supposted to happen. End up with extra window doing this. Better than a worse probles.
               edit('-w +t');
               p_buf_name=strip(strip(bn),'B','"');
               load_file_status=status=NEW_FILE_RC;
            } else {
               edit('-w +bi 'buf_id);
               //say('buf_id='buf_id' bufferProperties='bufferProperties' wid='p_window_id);
               load_file_status=status=0;
            }
         }
      }  else {
         if (modified_temp_name!='') {
            // Don't want file history to show modified temp file names
            orig_def_max_filehist:=def_max_filehist;
            def_max_filehist=0;
            load_file_status=status=edit('-w 'window_options" "options" "buf_width " "bn,EDIT_NOUNICONIZE|EDIT_NOADDHIST,0);
            def_max_filehist=orig_def_max_filehist;
         } else {
            load_file_status=status=edit('-w 'window_options" "options" "buf_width " "bn,EDIT_NOUNICONIZE|EDIT_NOADDHIST,0);
         }
         //say('bn='bn' status='status);
         // Treat other errors besides file not found just like file not found.
         if (status && status!=NEW_FILE_RC) {
            p_window_id=_mdi._edit_window();
            edit('-w +t');
            p_buf_name=strip(strip(bn),'B','"');
            load_file_status=status=NEW_FILE_RC;
            //say('other error bufferProperties='bufferProperties' wid='p_window_id);
         }
         if (status) {
            /* Note: 
                _message_box displayed below for untitled files that can't be restored (very unusual)
                _message_box displayed below for AutoSave temp files that can't be restored (also very unusual)
            */ 
            unable_to_restore_file:[bn]=bn==orig_bn && !inAutoSave;
         }
      }
      if (modified_temp_name!='') {
         if (setModifiedTempHash) {
            orig_bn=strip(orig_bn,'B','"');
            if (status==NEW_FILE_RC) {
               // IF a modified AutoSave file could not be restored (temp file failed to load--not for unnamed AutoSave file)
               if (orig_bn!='') {
                  _delete_buffer();
                  // orig_bn is the name of the name of the user's file
                  // Ok to have history here
                  edit('-w 'window_options" "options" "buf_width " "_maybe_quote_filename(orig_bn),EDIT_NOUNICONIZE|EDIT_NOADDHIST,0);
               }
            }
            if (!status || status==NEW_FILE_RC) {
               modified_temp_name2buf_id:[modified_temp_name]=p_buf_id;
               name_file(orig_bn,false);
               /* For autosave, the current language mode is based on the wrong filename.
                  correct the language mode here. 
               */
               if (inAutoSave) {
                  _SetEditorLanguage(_Filename2LangId(orig_bn,F2LI_NO_CHECK_OPEN_BUFFERS));
               }
               p_modified_temp_name=modified_temp_name;
               p_modify=true;
               orig_undo_steps:=p_undo_steps;
               p_undo_steps=0;
               p_undo_steps=orig_undo_steps;
               if (status==NEW_FILE_RC) {
                  p_modify=false;
               }
               if (!status) {
                  typeless bfiledate=_file_date(p_buf_name,'B');
                  if (bfiledate!='') {
                     p_file_date=bfiledate;
                  }
               }
            }
            if (status) {
               if (orig_bn!='') {
                  _message_box(nls("WARNING: Modified AutoSave file '%s' could not be restored",orig_bn));
               } else {
                  if (inAutoSave) {
                     _message_box(nls("WARNING: Modified unnamed AutoSave file '%s' could not be restored",modified_temp_name));
                  } else {
                     _message_box(nls("WARNING: Modified unnamed file '%s' could not be restored",modified_temp_name));
                  }
               }
            }
         }
      }
   }
   if ( status ) {
      if ( status!=NEW_FILE_RC && status!=FILE_NOT_FOUND_RC && status!=PATH_NOT_FOUND_RC
           && status!=MEMBER_IN_USE_RC
           && status!=DATASET_IN_USE_RC
           && status!=DATASET_OR_MEMBER_IN_USE_RC
           ) {
         return(status);
      }
      if (status==NEW_FILE_RC /* && modified_temp_name==""*/) {
         clean_up_buf_ids :+= " "p_buf_id;
      }
   } else {
      if (DocumentName!="") {
         docname(DocumentName);
      }
      if (bufferProperties!='') {
         // IF we are in readonly mode
         readonly_flags=strip(readonly_flags);
         if (!isinteger(readonly_flags)) readonly_flags=0;
         if (strip(bn,'B','"')!='.process') {
            _restore_filepos(p_buf_name);
         }
         if (isinteger(encoding_set_by_user)) {
            p_encoding_set_by_user=encoding_set_by_user;
            //say('put back');
         }
         if( readonly_flags & READONLY_ON) {
            read_only_mode();
            p_readonly_set_by_user=(readonly_flags & READONLY_SET_BY_USER);
            if (def_actapp&ACTAPP_AUTOREADONLY) maybe_set_readonly();
         } else {
            p_readonly_set_by_user=(readonly_flags & READONLY_SET_BY_USER);
            p_readonly_mode=false;
         } 
         // IF have mode name
         if (mode_name!='') {
            // Get extension from mode name
            lang := "";
            if (_ModenameEQ(mode_name,'fundamental') || _ModenameEQ(mode_name,'Plain Text')) {
               lang = _Modename2LangId('fundamental');
               if (p_LangId:!=lang) {
                  _SetEditorLanguage('fundamental',false,false,false,false,special_case_hex_mode);
               }
            } else {
               if (strieq(mode_name,'Windows PowerShell')) {
                  mode_name='PowerShell';
               }
               lang = _Modename2LangId(mode_name);
               // Made this changes so that _xml_init_file() did not get called twice.
               if (p_LangId:!=lang) {
                  _SetEditorLanguage(lang,false,false,false,false,special_case_hex_mode);
               }
            }
            if (def_actapp&ACTAPP_AUTOREADONLY) maybe_set_readonly();
#if 0
            // Get extension from mode name
            typeless junk="";
            lang=_Modename2LangId(mode_name);
            if (lang=='') {
               if (_ModenameEQ(mode_name,'Fundamental') || _ModenameEQ(mode_name,'Plain Text')) {
                  fundamental_mode();
               }
            } else {
               _SetEditorLanguage(lang);
            }
#endif
         }
         /* call _SetEditorLanguage() */
         p_margins=margins;
         if(tabs!='') p_tabs=tabs;
         p_word_wrap_style=word_wrap_style;
         if(isinteger(indent_with_tabs)) p_indent_with_tabs=indent_with_tabs;
         if(isinteger(spell_check_while_typing)) {
            if (p_buf_size>def_use_fundamental_mode_ksize*1024) {
               spell_check_while_typing=0;
            }
            p_spell_check_while_typing=spell_check_while_typing;
         }
         p_ShowSpecialChars=ShowSpecialChars;
         p_indent_style=indent_style;
         p_undo_steps=undo_steps;
         if (isinteger(hex_mode)) {
            if (special_case_hex_mode) {
               p_hex_mode=hex_mode;
               if (p_hex_mode==HM_HEX_ON && isinteger(hex_mode_reload_encoding)) {
                  p_hex_mode_reload_encoding=hex_mode_reload_encoding;
               }
               if (p_hex_mode==HM_HEX_ON && isinteger(hex_mode_reload_buf_width)) {
                  p_hex_mode_reload_buf_width=hex_mode_reload_buf_width;
               }
            } else {
               if (!p_hex_mode && hex_mode) {
                  if (hex_mode==HM_HEX_ON) { 
                     hex();
                  } else {
                     linehex();
                  }
               } else {
                  p_hex_mode=hex_mode;
               }
            }
         }
         if (isinteger(ModifyFlags)) {
            p_ModifyFlags|=(ModifyFlags& MODIFYFLAG_FTP_NEED_TO_SAVE);
         }
         if (isinteger(TruncateLength)) {
            p_TruncateLength=TruncateLength;
         }
         if (!p_MaxLineLength && isinteger(MaxLineLength)) {
            p_MaxLineLength=MaxLineLength;
         }
         if (isinteger(AutoSelectLanguage)) {
            p_AutoSelectLanguage=AutoSelectLanguage;
         }
         if (isinteger(line_numbers_len)) {
            p_line_numbers_len=line_numbers_len;
         }
         if (isinteger(LCFlags)) {
            p_LCBufFlags=LCFlags;
         }
         if (isinteger(caps)) {
            p_caps=caps;
         }
         if (CLscheme == def_color_scheme && SCscheme != "") {
            _SetSymbolColoringSchemeName(SCscheme);
         }
         if (isinteger(SCenabled)) _SetSymbolColoringEnabled(SCenabled);
         if (isinteger(SCerrors))  _SetSymbolColoringErrors(SCerrors);
         if (isinteger(AutoLeftMargin)) {
            p_AutoLeftMargin=AutoLeftMargin;
         }
         if (isinteger(FixedWidthRightMargin)) {
            p_FixedWidthRightMargin=FixedWidthRightMargin;
         }
         if (isinteger(soft_wrap_flags)) {
            p_SoftWrap=(soft_wrap_flags&1)?true:false;
            p_SoftWrapOnWord=(soft_wrap_flags&2)?true:false;
         }
         if (isinteger(show_minimap)) {
            p_show_minimap=(show_minimap)?true:false;
         }
         if (isinteger(show_statements)) {
            _SetShowStatementsInDefs(show_statements);
         }
      }
   }
   return(0);


}

static bool process_mdistate(_str state)
{
   // RESTORESTATE_NONAMEMATCH = Only match on p_tile_id when restoring.
   // This prevents the following scenario:
   // 1) MFPW (Multiple Files Per Window is on)
   // 2) Edit existing file.
   // 3) Edit temporary file ('edit +t').
   // 4) Split temporary file window.
   // 5) Exit and restart - temporary window was not found by name+p_tile_id and 
   //    split layout was collapsed.
   //
   // RESTORESTATE_NONAMEMATCH only matches on p_tile_id, which will be shared by
   // the previous buffer and cause it to be swapped into the window previously
   // occupied by the temporary file.
   return _MDIRestoreState(state, WLAYOUT_MDIAREA, RESTORESTATE_NONAMEMATCH | RESTORESTATE_POSTCLEANUP);
}

static void clean_up()
{
   p_window_id=_mdi._edit_window();
   _delete_temp_view(window_config_id);
   for (;;) {
      id := "";
      parse clean_up_buf_ids with id clean_up_buf_ids;
      if ( id=='' ) {
         break;
      }
      int status=edit('+bi 'id);
      if (!status) {
         /*
             Here we are using close_buffer() instead of _delete_buffer()
             to fix a bug in our X windows HP SoftBench support.  Note
             that it is possible for close_buffer() to be called here
             where the buffer was not created by calling the edit()
             command.
         */
         close_buffer(false,true /* Allow delete_buffer on hidden window. */);
      }
   }
   p_window_id=_mdi._edit_window();
}

static void write_monitor_layout_info(_str (&mon_info):[],_str only_for_this_rtype='') {
   _str text;
   _str rtype;
   bool hit_one=false;
   foreach (rtype=>text in mon_info) {
      if (text!='') {
         if (only_for_this_rtype=='' || only_for_this_rtype==rtype) {
            insert_line('');
            hit_one=true;
            if (_last_char(text)!="\n") {
               _insert_text(text"\n");
            } else {
               _insert_text(text);
            }
         }
      }
   }
   if (hit_one) {
      if (!_delete_line()) {
         up();
      }
      _end_line();
   }
}
static void write_monitor_configs(bool exclude_global_info,_str relativeToDir) {
   mdi_x := 0;
   mdi_y := 0;
   mdi_width := 0;
   mdi_height := 0;
   mdi_ix := 0;
   mdi_iy := 0;
   mdiclient_width := 0;
   mdiclient_height := 0;
   window_state := "";
   fullScreenMode := _tbFullScreenQMode();
   if ( (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_WINDOW) ) {
      _mdi._get_window(mdi_x, mdi_y, mdi_width, mdi_height, 'N', mdi_ix, mdi_iy);
      window_state = _mdi.p_window_state;
      if ( window_state == 'I' ){
         window_state = 'N';
      }
      typeless junk = '';
      _mdi._MDIClientGetWindow(junk, junk, mdiclient_width, mdiclient_height);
   } else {
      mdi_x = 0;
      mdi_y = 0;
      mdi_width = 0;
      mdi_height = 0;
      mdi_ix = 0;
      mdi_iy = 0;
      mdiclient_width = 0;
      mdiclient_height = 0;
      window_state = 'N';
   }


   insert_line('');  // MONITOR_CONFIGS: <count>    -- fix this later.
   int monitor_configs_linenum=p_line;

   // Write the current monitor configuration
   insert_line('');  // MONITOR_CONFIG: <count> config   -- fix this later.
   int monitor_config_linenum=p_line;
   _str screen_line = 'SCREEN: '_screen_width()' '_screen_height()' 'mdi_x' 'mdi_y' 'mdi_width :+
                      ' 'mdi_height' 'mdi_ix' 'mdi_iy' 'window_state :+
                      ' 0 0 0 0 'mdiclient_width' 'mdiclient_height' 'fullScreenMode;
   insert_line(screen_line);
   write_mdistate_data(p_window_id);
   // _current_layout_export_settings doesn't support relativeToDir
   if ( !exclude_global_info ) {
      insert_line('GSTART:');
      call_list('_srgmon_');//, '', '', '', relativeToDir);
      insert_line('GEND:');
   }
   call_list('_srmon_'); //, '', '', '', relativeToDir);
   int orig_line;
   _str active_monitor_config=_get_monitor_config();
   //say('active_monitor_config='active_monitor_config);
   orig_line=p_line;
   p_line=monitor_config_linenum;
   replace_line('MONITOR_CONFIG: '(orig_line-monitor_config_linenum)' 'active_monitor_config);
   p_line=orig_line;


   if (_default_option(VSOPTION_AUTORESTORE_MULTIPLE_MONITOR_CONFIGS)) {
      // Write all the monitor configs except the current which was already written.
      AUTORESTORE_MONITOR_CONFIG config;
      _str monitor_config;
      foreach (monitor_config=>config in gautorestore_monitor_configs) {
         if (config.m_monitor_config=='' || config.m_monitor_config==active_monitor_config) {
            continue;
         }
         //say('other active=<'active_monitor_config'>');
         //say('other mon_config=<'config.m_monitor_config'>');
         insert_line('');  // MONITOR_CONFIG: <count> config   -- fix this later.
         monitor_config_linenum=p_line;
         if (config.m_screen!=null && config.m_screen!='') {
            insert_line('SCREEN: 'config.m_screen);
         }
         if (config.m_mdistate!=null && config.m_mdistate!='') {
            insert_line('MDISTATE: 1');
            insert_line(config.m_mdistate);
         }
         if ( !exclude_global_info && !config.m_global_mon_info._isempty()) {
            insert_line('GSTART:');
            write_monitor_layout_info(config.m_global_mon_info);
            insert_line('GEND:');
         }
         write_monitor_layout_info(config.m_project_mon_info);
         orig_line=p_line;
         p_line=monitor_config_linenum;
         replace_line('MONITOR_CONFIG: '(orig_line-monitor_config_linenum)' 'monitor_config);
         p_line=orig_line;
      }
   }
   insert_line('END_MONITOR_CONFIGS:');
   orig_line=p_line;
   p_line=monitor_configs_linenum;
   replace_line('MONITOR_CONFIGS: '(orig_line-monitor_configs_linenum));
   p_line=orig_line;
}
void _write_monitor_configs_for_fileprojects() {
   insert_line('');  // MONITOR_CONFIGS: <count>    -- fix this later.
   int monitor_configs_linenum=p_line;

   // Write the current monitor configuration
   insert_line('');  // MONITOR_CONFIG: <count> config   -- fix this later.
   int monitor_config_linenum=p_line;
   _srmon_debug_layout('','');
   int orig_line;
   _str active_monitor_config=_get_monitor_config();
   //say('active_monitor_config='active_monitor_config);
   orig_line=p_line;
   p_line=monitor_config_linenum;
   replace_line('MONITOR_CONFIG: '(orig_line-monitor_config_linenum)' 'active_monitor_config);
   p_line=orig_line;


   if (_default_option(VSOPTION_AUTORESTORE_MULTIPLE_MONITOR_CONFIGS)) {
      // Write all the monitor configs except the current which was already written.
      AUTORESTORE_MONITOR_CONFIG config;
      _str monitor_config;
      foreach (monitor_config=>config in gautorestore_monitor_configs) {
         if (config.m_monitor_config=='' || config.m_monitor_config==active_monitor_config) {
            continue;
         }
         write_monitor_layout_info(config.m_project_mon_info,'DEBUG_LAYOUT:');
         orig_line=p_line;
         p_line=monitor_config_linenum;
         replace_line('MONITOR_CONFIG: '(orig_line-monitor_config_linenum)' 'monitor_config);
         p_line=orig_line;
      }
   }
   insert_line('END_MONITOR_CONFIGS:');
   orig_line=p_line;
   p_line=monitor_configs_linenum;
   replace_line('MONITOR_CONFIGS: '(orig_line-monitor_configs_linenum));
   p_line=orig_line;
}
bool _project_save_restore_done;
static int _recursion_restore_modified;

/**
 * Save application auto restore information.  All auto restore
 * information is stored in the "vrestore.slk" file. 
 *
 * <p>
 *
 * Set <code>exclude_global_info=true</code> if you do not want
 * to save global (e.g. dialog retrieval, command history,
 * clipboards, open file history, etc.). 
 *
 * <p>
 *
 * Optionally save to an <code>alternate_view_id</code> instead
 * of "vrestore.slk". 
 *
 * <p>
 *
 * Set <code>exiting_editor=true</code> if the application will
 * be exiting immediately after. 
 *
 * <p>
 *
 * Optionally set <code>relativeToDir</code> to store file name
 * paths relative to a specific directory.
 *
 * @param exclude_global_info 
 * @param alternate_view_id 
 * @param exiting_editor 
 * @param relativeToDir 
 * 
 * @return 0 on success, < 0 on error.
 * 
 * @see restore
 * @see auto_restore
 * 
 * @categories File_Functions
 * 
 */ 
_command save_window_config(bool exclude_global_info=false, int alternate_view_id=0, bool exiting_editor=false, _str relativeToDir=null,bool restore_unnamed_as_modified=false,bool restore_named_as_modified=false,bool inAutoSave=false)
{
   if ( _default_option(VSOPTION_CANT_WRITE_CONFIG_FILES) ) {
      return 0;
   }

   // DJB 03-14-2007 - do not leave fullscreen mode
   //fullscreen(0);
   
   _save_all_filepos();
   orig_view_id := 0;
   get_window_id(orig_view_id);
   p_window_id = _mdi.p_child;
   home_view := 0;
   get_window_id(home_view);
   activate_window(VSWID_HIDDEN);
   _str rpath = restore_path(0);

   restore_view_id := 0;
   typeless status = 0;
   if ( alternate_view_id ) {
      activate_window(alternate_view_id);
   } else {
      status = 1;
      restore_filename :=  rpath:+_WINDOW_CONFIG_FILE;
      if ( buf_match(restore_filename, 1, 'he') != '' ) {
         status = _open_temp_view(restore_filename, restore_view_id, auto orig_wid, '', auto buffer_already_exists, true, false, 0, true);
      }
      if ( status ) {
         _create_temp_view(restore_view_id, '', restore_filename);
         status=0;
      }
   }
   if ( !status ) {
      p_encoding=VSENCODING_UTF8;
      p_UTF8 = true;
   }

   typeless p = 0;
   get_window_id(restore_view_id);
   int buf_id = p_buf_id;
   b4_cwd_linenum:=p_line;
   insert_line('CWD: '((relativeToDir == null) ? getcwd() : relative(getcwd(), relativeToDir)));
   if (!exclude_global_info) {
      insert_line('INVOCATION-INFO: 0 'inAutoSave' '(_workspace_filename!='')' '_editionid());
   }
   if (inAutoSave) {
      insert_line("AUTOSAVE: 0");
   }

   if ( !exclude_global_info ) {
      insert_line('GSTART:');
      typeless gstart;
      save_pos(gstart);
      // Add the retrieve information.
      write_retrieve_data(restore_view_id);
      /* call external global save/restore functions. */
      _project_save_restore_done = false;
      _srg_workspace();
      _srg_tbfilelist();
      _project_save_restore_done = true;
      call_list('_srg_');
      _project_save_restore_done = false;

      _save_pos2(p);
      if ( exiting_editor ) {
         if ( find_index('_tw_exiting_editor', PROC_TYPE) ) {
            _tw_exiting_editor();
         }
      }

      restore_pos(gstart);
      _xsrg_dialogs();
      _restore_pos2(p);
      insert_line('GEND:');
   }
   // Have to do this in a weird order because need to call _tw_exiting_editor() above before
   // this is done.
   _save_pos2(auto pm);
   p_line=b4_cwd_linenum;
   write_monitor_configs(exclude_global_info,relativeToDir);
   _restore_pos2(pm);


   /* For each buffer write non-active view information. */
   word := "";
   rest := "";
   activate_window(VSWID_HIDDEN);
   load_files('+m +bi 'restore_view_id.p_buf_id);
   not_on_disk_list := "";
   int restore_process = (def_restore_flags & RF_PROCESS);
   buf_id = p_buf_id;
   bool bufferDataWritten:[];  // Indicates which buffers we need windows for.

   // if the home_view is maximized, make sure we save the last buffer
   // this fixes the issue of an unsaved buffer being the home_view, 
   // which keeps the maximized state from being saved
   lastBuffer := 0;
   if ( home_view.p_window_state == 'M' ) {
      lastBuffer = -1;
   }
   for ( ;; ) {
      _next_buffer('H');
      if ( p_buf_id == buf_id ) {
         break;
      }
      parse p_buf_name with word rest;
      if ( !(p_buf_flags & VSBUFFLAG_HIDDEN) &&
           (
             (_need_to_save() && ( p_buf_name != ''|| _AllowRestoreModified(restore_unnamed_as_modified)) ) ||
             (p_buf_name=='.process' && restore_process)
           ) ) {
         do_restore_modified := _AllowRestoreModified(restore_unnamed_as_modified);
         if ( (p_buf_name!='.process' &&  do_restore_modified )
               || file_exists(p_buf_name) ||
              (p_buf_name == '.process' && restore_process) ) {
            if (do_restore_modified && p_modify) {
               if (p_modified_temp_name=='') {
                  _CreateModifiedTempName();
               }
               // Make sure autosave does not delete this temp file.
               _as_removefilename(p_modified_temp_name);
               status=0;
               // Don't want to save the modified file contents twice.
               if (!(p_ModifyFlags &MODIFYFLAG_AUTOSAVE_DONE) || !file_exists(p_modified_temp_name)) {
                  status=_SaveModifiedTempName();
                  if (status) {
                     // Odd error. Could be out of disk space or something unusual.
                     if (!alternate_view_id) {
                        _delete_temp_view(restore_view_id);
                     }
                     activate_window(home_view);
                     activate_window(orig_view_id);
                     _str msg=nls("Unable to save '%s2' to '%s2'.\n",p_buf_name,p_modified_temp_name);
                     _message_box(msg' 'get_message(status));
                     return 1;
                  }
               }
            }

            bufferDataWritten:[p_buf_id] = true;
            write_buffer_data(relativeToDir, restore_view_id, true,restore_named_as_modified);
            write_view_data(restore_view_id);

            // check to see if we are keeping track of the last buffer
            if ( p_buf_id == home_view.p_buf_id ) {
               lastBuffer = 0;  // we will be writing this anyway, so just turn off the last buffer mess
            } else if ( lastBuffer ) {
               lastBuffer = p_buf_id;
            }

         } else {
            not_on_disk_list :+= ' 'p_buf_id;
         }
      }
      /*if (p_modify && p_modified_temp_name!='' && !_AllowRestoreModified(restore_unnamed_as_modified)) {
         _as_addfilename(p_modified_temp_name);
         p_modified_temp_name='';
      } */
   }
   /* for every window enter window, buffer, and view info */
   activate_window(home_view);

   if ( !_no_child_windows() ) {
      first_window_id := p_window_id;
      for ( ;; ) {
         // our direction depends on the next window style
         // we want to restore the same order that we had
         if ( _default_option(VSOPTION_NEXTWINDOWSTYLE) == 1 ) {
            _prev_window('HF');
         } else {
            _next_window('HF');
         }
         /* write out the window's data */
         if ( p_window_id != VSWID_HIDDEN ) {
            int orig_buf_id = p_buf_id;
            int i;
            for ( i=0;; ++i ) {
               if ( bufferDataWritten._indexin(p_buf_id) ) {
                  write_window_data(restore_view_id, (i == 0), (p_buf_id == lastBuffer));
                  write_buffer_data(relativeToDir, restore_view_id,false,restore_named_as_modified);
                  write_view_data(restore_view_id);
                  if (p_buf_id != orig_buf_id ) {
                     // Changing the buffer id will force the editor out of
                     // scroll mode (p_scroll_left_edge==-1).  This is called 
                     // from autosave, so we really don't want the scroll 
                     // postion to be changed.  This is not perfect, it will
                     // still have problems if a buffer is not named ( like 
                     // a list buffer ).
                     p_buf_id = orig_buf_id;
                  }
                  break;
               }
               if ( def_one_file != '' ) {
                  break;
               }
               _prev_buffer();
               if ( p_buf_id == orig_buf_id ) {
                  break;
               }
            }
         }
         if ( p_window_id == first_window_id ) {
            break;
         }
      }
      write_mdistate_data(restore_view_id);
   }

   /* save and exit the status file */
   activate_window(restore_view_id);
   write_select_data();
   //IF we are save data to global auto restore file.
   /* call external save/restore functions. */
   call_list('_sr_', '', '', '', relativeToDir);
   status = 0;
   if ( !alternate_view_id ) {
      if ( rpath != '' && rpath == _ConfigPath() ) {
         status = _create_config_path();
      }
      if ( !status ) {
         status = _save_file('+o');
         /* Don't care if get error. */
         status = 0;
      }
      _delete_temp_view(restore_view_id);
      activate_window(home_view);
      //activate_window home_view
      if ( status < 0 ) {
         message(get_message(status));
      }
   }
   activate_window(orig_view_id);
   return status;

}
static _str gload_named_state_name;
/** 
 * Saves auto-restore information for files and/or tool 
 * windows/toolbars. 
 *  
 * @param sectionName   Optional name of auto-restore info. You 
 *                      will be prompted if sectionName is
 *                      blank.
 * @param save_files    Indicates whether files will be saved
 *                      and restored.
 * @param save_layout   Indicates whether tool window and tool 
 *                      bars will be saved and restored.
 */
_command void save_named_state(_str sectionName="",bool save_files=true, bool save_layout=true) name_info(',')
{
   // This really should have had a .ini extension. Too late now.
   _str filename='windowstate.slk';
   if (save_files) {
      if (save_layout) {
         filename='state.ini';
      } else {
         filename='windowstate.slk';
      }
   } else/* if (save_layout)*/ {
      filename='layoutstate.ini';
   }
   gload_named_state_name=filename;
   filename = _ConfigPath():+filename;

   msg:=save_files?(save_layout?"Save Named State":"Save Named File States"):"Save Named Layout";

   if ( sectionName=="" ) {
      _ini_get_sections_list(filename,auto sectionList);
      result := "";
      if ( sectionList==null ) {
         // If there are no section names stored already,
         // just prompt for a name.
         result = textBoxDialog(msg,
                                0,
                                0,
                                "",//"Save Named State",
                                "",
                                "",
                                msg);
         if ( result==COMMAND_CANCELLED_RC ) {
            return;
         }
         result = _param1;
      } else {
         // If there are names, show the list with a combobox
         // so they can pick or type a new name.
         result = show('-modal _sellist_form',
                       msg,
                       SL_SELECTCLINE|SL_COMBO,
                       sectionList,
                       "Save,&Delete",     // Buttons
                       "",//"Save Named State", // Help Item
                       "",                 // Font
                       _load_named_state_callback
                       );
      }
      if ( result=="" ) return;
      sectionName = result;
   }
   int orig_view_id=_create_temp_view(auto state_view_id);
   p_window_id=orig_view_id;
   save_window_config(true,state_view_id);
   p_window_id=orig_view_id;
   int status=_ini_put_section(filename,sectionName,state_view_id);
}
_command void save_named_layout(_str sectionName="") name_info(',') {
   save_named_state(sectionName,false,true);
}
_command void save_named_files(_str sectionName="") name_info(',') {
   save_named_state(sectionName,true,false);
}


static _str _load_named_state_callback(int reason, var result, _str key)
{
   _nocheck _control _sellist;
   _nocheck _control _sellistok;
   if (key == 3) {
      item := _sellist._lbget_text();
      filename := _ConfigPath():+gload_named_state_name;
      status := _ini_delete_section(filename,item);
      if ( !status ) {
         _sellist._lbdelete_item();
      }
   }
   return "";
}

/**
 * Restores previously saved files and/or tool windows/toolbars
 *  
 * @param sectionName   Optional name of auto-restore info. You 
 *                      will be prompted if sectionName is
 *                      blank.
 * @param save_files    Indicates whether files will be 
 *                      restored.
 * @param save_layout   Indicates whether tool window and tool 
 *                      bars will be restored.
 */
_command void load_named_state(_str sectionName="",bool save_files=true,bool save_layout=true) name_info(',')
{
   _str filename='windowstate.slk';
   if (save_files) {
      if (save_layout) {
         filename='state.ini';  // Will restore everything
      } else {
         filename='windowstate.slk';  // Only restore files
      }
   } else/* if (save_layout)*/ {
      filename='layoutstate.ini';    // Only restore tool windows and toolbars
   }
   gload_named_state_name=filename;
   filename = _ConfigPath():+filename;
   if ( sectionName=="" ) {
      _ini_get_sections_list(filename,auto sectionList);
      if (sectionList==null || sectionList._length()==0) {
         if (save_files) {
            if (save_layout) {
               _message_box('There are no named states');
            } else {
               _message_box('There are no named file states');
            }
         } else/* if (save_layout)*/ {
            _message_box('There are no named layouts');
         }
         return;
      }
      msg:=save_files?(save_layout?"Load Named State":"Load Named File States"):"Load Named Layout";
      result := show('-modal _sellist_form',
                     msg,
                     SL_SELECTCLINE,
                     sectionList,
                     "Load,&Delete",     // Buttons
                     "", //Load Named State", // Help Item
                     "",                 // Font
                     _load_named_state_callback
                     );
      if ( result=="" ) {
         return;
      }
      sectionName = result;
   }
   status := _ini_get_section(filename,sectionName,auto tempWID);
   if ( status ) return ;
   origWID := p_window_id;
   p_window_id = tempWID;
   if (save_files) {
      _close_all2();
      p_window_id = tempWID;
   }
   restore2(save_files?'':'N','', save_files?true:false, true, true,save_layout?0:-1);
   if ( _iswindow_valid(origWID) ) {
      p_window_id = origWID;
   }
   _delete_temp_view(tempWID);
}
_command void load_named_layout(_str sectionName="") name_info(',') {
   load_named_state(sectionName,false,true);
}

_command void load_named_files(_str sectionName="") name_info(',') {
   load_named_state(sectionName,true,false);
}

static void write_select_data()
{
   // Would need to add support for proportional font column selections.
   // Even when this code works, it not very valuable so drop support
   // for this for now.
#if 0
   if ( _select_type()!='' && _select_type('','S')!='C' ) {
      start_col := end_col := buf_id := 0;
      buf_name := "";
      _get_selinfo(start_col,end_col,buf_id,'',buf_name);
      temp_view_id := 0;
      orig_view_id := 0;
      int status=_open_temp_view(buf_name,temp_view_id,orig_view_id,'+b');
      if ( status ) {
         clear_message();
      } else {
         _begin_select();
         typeless start_line=_get_rpoint();
         up();int lfb=_lineflags();
         _end_select();
         typeless last_line=_get_rpoint();
         up();int lfe=_lineflags();
         _delete_temp_view(temp_view_id);
         activate_window(orig_view_id);
         if (!(lfb & EOL_MISSING_LF) && !(lfe & EOL_MISSING_LF)) {
            insert_line("MARK: MT="_select_type()' BN="'buf_name'" SL='start_line' SC='start_col' LL='last_line' EC='end_col);
         }
      }
   }
#endif
}

static void write_window_data(int buf,bool specifyFont,bool forceMaximized)
{
   this_buf := 0;
   get_window_id(this_buf);
   x := y := width := height := icon_x := icon_y := 0;
   _MDIChildGetWindow(x,y,width,height,'N',icon_x,icon_y);
   out := "WINDOW: ";
   font_info := "";
   minimap_info:='*,,,';   // minimap-font-name,minimap-font-size,minimap-width-is-fixed,minimap-width

   if (specifyFont) {
      // see if our current font matches the default
      font_info = '"':+p_font_name:+",":+p_font_size",":+_font_props2flags()",":+p_font_charset:+'"';
      default_font_info := '"'strip(_default_font(CFG_WINDOW_TEXT), 'T',',')'"';
      if (font_info == default_font_info) {
         font_info = '",,,"';
      }
      if (p_minimap_wid) {
         int cfg=CFG_SBCS_DBCS_MINIMAP_WINDOW;
         if (p_UTF8) {
            cfg=CFG_UNICODE_MINIMAP_WINDOW;
         }
         parse _default_font(cfg) with auto minimap_font_name',' auto minimap_font_size',';
         if (strieq(minimap_font_name,p_minimap_wid.p_font_name)) {
            minimap_font_name='*'; // Can't uses empty string because that's valid and the typical default.
         } else {
            minimap_font_name=p_minimap_wid.p_font_name;
         }
         if (minimap_font_size==p_minimap_wid.p_font_size) {
            minimap_font_size='';
         } else {
            minimap_font_size=p_minimap_wid.p_font_size;
         }
         _str minimap_width_is_fixed='';
         if (_default_option(VSOPTION_MINIMAP_WIDTH_IS_FIXED)!=p_minimap_wid.p_minimap_width_is_fixed) {
            minimap_width_is_fixed=p_minimap_wid.p_minimap_width_is_fixed;
         }
         _str minimap_width='';
         if (_default_option(VSOPTION_MINIMAP_WIDTH)!=p_minimap_wid.p_minimap_width) {
            minimap_width=p_minimap_wid.p_minimap_width;
         }
         minimap_info=minimap_font_name','minimap_font_size','minimap_width_is_fixed','minimap_width;
      }
   } else {
      font_info = '",,,"';
   }
   windowState := forceMaximized ? 'M' : p_window_state;

   out=out:+x' 'y' 'width:+' 'height' 'icon_x' 'icon_y' 'windowState' ':+
       ' WF='p_window_flags:+' WT='p_tile_id' 'font_info:+' DID='p_mdi_child_duplicate_id' MI="'minimap_info'"';
   activate_window(buf);
   insert_line(out);
   activate_window(this_buf);
}
static void write_view_data(int buf)
{
   this_buf := 0;
   get_window_id(this_buf);
   out := "VIEW: ";
   cx := p_cursor_x;
   cy := p_cursor_y;
   cy=cy intdiv p_font_height;
   cx=cx intdiv p_font_width;
   _str col=p_col;
   _save_pos2(auto p);
   up();int lf=_lineflags();
   _restore_pos2(p);
   if (lf & EOL_MISSING_LF) {
      // Calculate number of characters past the end of the line
      offset := _QROffset();
      if (p_col>=_text_colc()+1) {
         offset= -offset;
      }
      col='.'offset;
   }

   out :+= 'LN='_get_rpoint()' CL='col' LE='_WinGetLeftEdge(0,false)' CX='cx:+
           ' CY='cy' WI='p_window_id' BI='p_buf_id' HT='p_hex_toppage:+
           ' HN='p_hex_nibble' HF='p_hex_field' HC='p_hex_Nofcols' HB='p_hex_bytes_per_col;
   activate_window(buf);
   insert_line(out);
   activate_window(this_buf);
}
static void write_buffer_data(_str relativeToDir,int buf,bool insertBufferInfo,bool restore_named_as_modified)
{
   buf_name := "";
   this_buf := 0;
   get_window_id(this_buf);
   if (relativeToDir==null || p_buf_name=='') {
      buf_name=p_buf_name;
   } else {
      buf_name=relative(p_buf_name,relativeToDir);
   }
   out := "";
   _str modified_temp_name=p_modified_temp_name;
   if (buf_name!='' && !restore_named_as_modified) {
      modified_temp_name='';
   }
   out='BUFFER: BN="'buf_name'"'  '"'p_DocumentName'"' '"'modified_temp_name'"';
   int readonly_flags=(p_readonly_mode)?READONLY_ON:0;
   if (p_readonly_set_by_user) {
      readonly_flags|=READONLY_SET_BY_USER;
   }

   // symbol coloring options
   se.color.SymbolColorRuleBase scc;
   CLscheme := def_color_scheme;
   SCscheme := _GetSymbolColoringSchemeName();
   if (SCscheme == def_symbol_color_profile) {
      SCscheme = "";
   }
   _str SCenabled = _QSymbolColoringEnabled();
   _str SCerrors  = _QSymbolColoringErrors();
   if (SCenabled == _QSymbolColoringEnabled(true)) SCenabled = "";
   if (SCerrors  == _QSymbolColoringErrors(true))  SCerrors  = "";

   // show statements in the Defs tool window?
   _str DEFStatements = _QShowStatementsInDefs();
   if (DEFStatements == _QShowStatementsInDefs(p_LangId,true)) DEFStatements = "";

   _str indent_with_tabs=p_indent_with_tabs;
   _str tabs=p_tabs;
   /* 
      Calling _GetDefaultLanguageOptions doesn't seem to effect
      performance. Probably because settings are cached.
    
      _GetDefaultLanguageOptions does sync with beautifier settings.
      After that we apply language overrides to get the final default
      settings.
   */

   VS_LANGUAGE_OPTIONS langOptions;
   _GetDefaultLanguageOptions(p_LangId, langOptions);
   if (_default_option(VSOPTION_EDITORCONFIG_FLAGS)) {
      _LangOptionsApplyOverrides(langOptions,p_LangId,p_buf_name);
   }

   if(indent_with_tabs==(_LangOptionsGetPropertyInt32(langOptions,VSLANGPROPNAME_INDENT_WITH_TABS,0)!=0)) {
      indent_with_tabs='';
   }
   typeless tvalue=_LangOptionsGetProperty(langOptions,VSLANGPROPNAME_TABS);
   if (isinteger(tvalue)) {
      if (tabs==('1 '(1+tvalue))) {
         tabs='';
      }
   }
   _str soft_wrap=_LangGetProperty(p_LangId,VSLANGPROPNAME_SOFT_WRAP);
   _str soft_wrap_on_word=_LangGetProperty(p_LangId,VSLANGPROPNAME_SOFT_WRAP);
   soft_wrap_flags := "";
   if ( soft_wrap!=p_SoftWrap || soft_wrap_on_word!=p_SoftWrapOnWord) {
      soft_wrap_flags=(p_SoftWrap?1:0)|(p_SoftWrapOnWord?2:0);
   }
   spell_check_while_typing := "";
   if (_LangGetPropertyInt32(p_LangId,VSLANGPROPNAME_SPELL_CHECK_WHILE_TYPING,0)!=p_spell_check_while_typing) {
      spell_check_while_typing=p_spell_check_while_typing;
   }
   _str show_minimap='';
   if (p_show_minimap!=_LangGetProperty(p_LangId,VSLANGPROPNAME_SHOW_MINIMAP)) {
      show_minimap=p_show_minimap;
   }
   _str mode_name=p_mode_name;
   if (p_buf_name!='') {
      if (_Filename2LangId(p_buf_name,F2LI_NO_CHECK_OPEN_BUFFERS|F2LI_NO_CHECK_PERFILE_DATA):==p_LangId) {
         mode_name='';
      }
   }
      
  out2 := "BI: MA="p_margins:+
             " TABS="tabs:+
             " WWS="p_word_wrap_style:+
             " IWT="indent_with_tabs:+
             " ST="p_ShowSpecialChars:+
             " IN="p_indent_style:+
             " BW="p_buf_width:+
             " US="p_undo_steps:+
             " RO="readonly_flags:+
             " SE=" p_showeof:+
             " SN=0 BIN="p_binary:+
             " MN="mode_name:+
             "\tHM="p_hex_mode:+
             " MF="p_ModifyFlags:+
             " TL="p_TruncateLength:+
             " MLL="p_MaxLineLength:+
             " ASE="p_AutoSelectLanguage:+
             " LNL="p_line_numbers_len:+
             " LCF="p_LCBufFlags:+
             " CAPS="p_caps:+
             " E="p_encoding:+
             " ESBU2="p_encoding_set_by_user:+
             " CL="_dquote(CLscheme):+
             " SC="_dquote(SCscheme):+
             " SCE="SCenabled:+
             " SCU="SCerrors:+
             " ALM="p_AutoLeftMargin:+
             " FWRM="p_FixedWidthRightMargin:+
             " HMRE="p_hex_mode_reload_encoding:+
             " HMRBW="p_hex_mode_reload_buf_width:+
             " SPCWT="spell_check_while_typing:+
             " SWF="soft_wrap_flags:+
             " SM="show_minimap:+
             " STAT="DEFStatements;
   activate_window(buf);
   insert_line(out);
   if ( insertBufferInfo ) {  /* Insert buffer info? */
      insert_line(out2);
   }
   activate_window(this_buf);
}

static void write_mdistate_data(int restore_wid)
{
   int orig_wid;
   get_window_id(orig_wid);

   state := "";
   _MDISaveState(state, WLAYOUT_MDIAREA);
   activate_window(restore_wid);
   noflines := 1;
   insert_line('MDISTATE: ':+noflines);
   insert_line(state);

   activate_window(orig_wid);
}

static void write_retrieve_data(int view_id)
{
   typeless mark=_alloc_selection();
   if ( mark<0) {
      return;
   }
   activate_window(VSWID_RETRIEVE);
   top();
   // Check for embedded carriage return or line feed
   // Can't save retrieve info if there is an embedded cr or lf
   if (_embedded_crlf()) {
      bottom();
      activate_window(view_id);
      _free_selection(mark);
      return;
   }
   _select_line(mark);
   bottom();
   _select_line(mark);
   int Noflines=count_lines_in_selection(mark);
   activate_window(view_id);
   insert_line("RETRIEVE: "Noflines);
   _copy_to_cursor(mark);
   bottom();
   _free_selection(mark);
}
static void restore_retrieve_data(int Noflines)
{
   if ( ! Noflines ) {
      return;
   }
   typeless mark=_alloc_selection();
   if ( mark<0) {
      down(Noflines);
      return;
   }
   view_id := 0;
   get_window_id(view_id);
   down();
   _select_line(mark);
   down(Noflines-1);
   _select_line(mark);
   activate_window(VSWID_RETRIEVE);
   if ( !_line_length()) {
      _delete_line();
   }
   _copy_to_cursor(mark);
   _free_selection(mark);
   bottom();
   activate_window(view_id);
}
static void set_screen_size(typeless line,var do_one_window,var mdi_state,bool RestoreFromInvocation)
{
   typeless width=0, height=0, mdi_x=0, mdi_y=0, mdi_width=0, mdi_height=0, mdi_ix=0, mdi_iy=0, ifl=0, dft=0, ifr=0, ufb=0, client_width=0, client_height=0;
   parse line with width height mdi_x mdi_y mdi_width mdi_height mdi_ix mdi_iy mdi_state ifl dft ifr ufb client_width client_height ;
   /* If screen size different */
   if ( _screen_height()!=height || _screen_width()!=width ) {
      do_one_window=1;
   }
#if 0
   if ( ifl<_mdi.p_in_from_left || dft<_mdi.p_down_from_top || ifr<_mdi.p_in_from_right || ufb<_mdi.p_up_from_bottom) {
      do_one_window=1;
   }
#endif
   typeless junk=0;
   mdiclient_width := mdiclient_height := 0;
   _mdi._MDIClientGetWindow(junk,junk,mdiclient_width,mdiclient_height);
   if ( client_width=="" || client_width>mdiclient_width || client_height>mdiclient_height) {
      //do_one_window=1;
   }
   if (!RestoreFromInvocation) {
      // Don't want to restore position of icon.  Let Windows determine position
      // so that the icon does not overlap an existing icon.
      if (mdi_state!='M' && mdi_state!='N') {
         mdi_state='N';
      }
      if (mdi_width && mdi_height) {
         _mdi._move_window(mdi_x,mdi_y,mdi_width,mdi_height,"N" /*mdi_state*/);
         _mdi.p_window_state=mdi_state;
      }
   } else if(mdi_state=='N') {
      // Make sure mdi frame is visible on any monitor
      _mdi._CenterIfFormNotVisible();
   }
}

static void _goto_rpoint(typeless line)
{
   line=strip(line);
   if ( substr(line,1,1)=='.' ) {
      typeless p=substr(line,2);
      typeless status=_GoToROffset(p);
      if ( status ) {
         clear_message();
         if ( p>0 ) {
            bottom();
         }
      }
      _begin_line();
   } else {
      p_RLine=line;
   }
}
static _str _get_rpoint()
{
   save_pos(auto p);
   _begin_line();
   result := '.'_QROffset();
   restore_pos(p);
   return(result);
}

int _srg_open(_str option='',_str info='')
{
   if ( option=='R' || option=='N' ) {
      parse info with . _last_open_path"\t"_last_open_cwd;
   } else {
      insert_line('OPEN: 0 '_last_open_path"\t"_last_open_cwd);
   }
   return(0);
}
int _srg_debug_window(_str option='',_str info='')
{
   // deprecated restore callback
   // DEBUG_WINDOW: x y z
   //    x is not number of lines to read
   return(0);
}
int _srgmon_debug_window2(_str option='',_str info='')
{
   typeless x,y,w,h;
   if ( option=='R' || option=='N' ) {
      _DebugWindowRestore(info);
   } else {
      _DebugWindowSave(info);
      insert_line('DEBUG_WINDOW2: 'info);
   }
   return(0);
}
int _srg_alert_history(_str option='',_str info='')
{
   typeless x,y,w,h;
   if ( option=='R' || option=='N' ) {
      parse info with . info;
      _SetAlertHistory(info);
   } else {
      _DebugWindowSave(info);
      insert_line('ALERT_HISTORY: 0 '_GetAlertHistory());
   }
   return(0);
}
static _str _editionid() {
   if (_isProEdition()) {
      return 'P';
   }
   if (_isStandardEdition()) {
      return 'S';
   }
   if (_isCommunityEdition()) {
      return 'C';
   }
   return '';
}
static int _edition_to_number(_str editionid) {
   switch (editionid) {
   case 'P':
      return 3;
   case 'S':
      return 2;
   case 'C':
      return 1;
   }
   return 100;
}

