////////////////////////////////////////////////////////////////////////////////////
// $Revision:  $
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
#require "se/debug/rdbgp/RdbgpOptions.e"
#import "se/debug/rdbgp/rdbgputil.e"
#import "se/debug/rdbgp/rdbgp.e"
#require "se/debug/rdbgp/RdbgpConnectionProgressDialog.e"
#import "se/debug/dbgp/dbgputil.e"
#import "listbox.e"
#import "main.e"
#import "mprompt.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "projconv.e"
#import "env.e"
#import "debug.e"
#import "wkspace.e"
#import "project.e"
#import "compile.e"
#import "treeview.e"
#import "guiopen.e"
#import "picture.e"
#import "tbopen.e"
#import "guicd.e"
#import "controls.e"
#endregion

#define RDBGP_VERSION "2.0"

using namespace se.debug.rdbgp;

struct RubyOptions {
   // Interpreter arguments
   _str interpreterArgs;
   // Default file to run. If blank then current file is run.
   _str defaultFile;
   // Arguments to script file
   _str scriptArgs;
};

static _str getRdbgpDir()
{
   _str resource_dir = get_env('VSROOT');
   _maybe_strip_filesep(resource_dir);
   resource_dir = resource_dir:+FILESEP:+'resource';

   _str tools_dir = resource_dir:+FILESEP:+'tools';

   _str rdbgp_dir = tools_dir:+FILESEP:+'rdbgp-'RDBGP_VERSION;
   if( !isdirectory(rdbgp_dir) ) {
      return "";
   }
   return rdbgp_dir;
}

static RubyOptions makeDefaultRubyOptions(RubyOptions& ruby_opts=null)
{
   ruby_opts.interpreterArgs = "";
   ruby_opts.defaultFile = "";
   ruby_opts.scriptArgs = "";
   return ruby_opts;
}

static void getProjectRubyOptionsForConfig(int projectHandle, _str config, RubyOptions& ruby_opts)
{
   // Guarantee sane values
   RubyOptions default_ruby_opts;
   makeDefaultRubyOptions(default_ruby_opts);
   _str interpreterArgs = default_ruby_opts.interpreterArgs;
   _str defaultFile = default_ruby_opts.defaultFile;
   _str scriptArgs = default_ruby_opts.scriptArgs;

   int node = _ProjectGet_ConfigNode(projectHandle,config);
   if( node >= 0 ) {
      //int opt_node = _xmlcfg_find_simple(projectHandle,"List[@Name='Ruby Options']",node);
      //if( opt_node >= 0 ) {
      //
      //   // DefaultFile
      //   node = _xmlcfg_find_simple(projectHandle,"Item[@Name='DefaultFile']",opt_node);
      //   if( node >=0  ) {
      //      defaultFile = _xmlcfg_get_attribute(projectHandle,node,"Value",defaultFile);
      //   }
      //}

      int target_node = _ProjectGet_TargetNode(projectHandle,"Execute",config);

      // interpreterArgs, defaultFile
      _str cmdline = _ProjectGet_TargetCmdLine(projectHandle,target_node,false);
      _str rest;
      parse cmdline with . '"%(SLICKEDIT_RUBY_EXE)"' interpreterArgs '%(SLICKEDIT_RUBY_EXECUTE_ARGS)' rest;
      defaultFile = parse_file(rest);
      interpreterArgs = strip(interpreterArgs);
      defaultFile = strip(strip(defaultFile),'B','"');
      if( defaultFile == '%f' ) {
         defaultFile = "";
      }

      // scriptArgs
      scriptArgs = _ProjectGet_TargetOtherOptions(projectHandle,target_node);
   }
   ruby_opts.interpreterArgs = interpreterArgs;
   ruby_opts.defaultFile = defaultFile;
   ruby_opts.scriptArgs = scriptArgs;
}

static void getProjectRubyOptions(int projectHandle, _str (&configList)[], RubyOptions (&ruby_opts_list):[])
{
   foreach( auto config in configList ) {
      RubyOptions opts;
      getProjectRubyOptionsForConfig(projectHandle,config,opts);
      ruby_opts_list:[config] = opts;
   }
}

static void setProjectOptionsForConfig(int projectHandle, _str config, RubyOptions& ruby_opts, RdbgpOptions& rdbgp_opts)
{
   //
   // Execute
   //

   int target_node = _ProjectGet_TargetNode(projectHandle,"Execute",config);
   _str cmdline = '"%(SLICKEDIT_RUBY_EXE)"';
   if( ruby_opts.interpreterArgs != "" ) {
      cmdline = cmdline' 'ruby_opts.interpreterArgs;
   }
   cmdline = cmdline' %(SLICKEDIT_RUBY_EXECUTE_ARGS)';
   if( ruby_opts.defaultFile != "" ) {
      cmdline = cmdline" "maybe_quote_filename(ruby_opts.defaultFile)" %~other";
   } else {
      cmdline = cmdline' "%f" %~other';
   }
   _ProjectSet_TargetCmdLine(projectHandle,target_node,cmdline,"",ruby_opts.scriptArgs);

   //
   // Debug
   //

   //target_node = _ProjectGet_TargetNode(projectHandle,"Debug",config);
   //_ProjectSet_TargetCmdLine(projectHandle,target_node,"ruby_debug","Slick-C");

   //
   // Ruby Options, rdbgp Options
   //

   int config_node = _ProjectGet_ConfigNode(projectHandle,config);

   //
   // Ruby Options
   //

   int opt_node = _xmlcfg_find_simple(projectHandle,"List[@Name='Ruby Options']",config_node);

   // Clear out old options
   if( opt_node >= 0 ) {
      _xmlcfg_delete(projectHandle,opt_node,false);
   }
   opt_node = _xmlcfg_add(projectHandle,config_node,VPJTAG_LIST,VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add_attribute(projectHandle,opt_node,"Name","Ruby Options",0);

   //// DefaultFile
   //int node = _xmlcfg_add(projectHandle,opt_node,VPJTAG_ITEM,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   //_xmlcfg_add_attribute(projectHandle,node,"Name","DefaultFile",0);
   //_xmlcfg_add_attribute(projectHandle,node,"Value",ruby_opts.defaultFile,0);

   //
   // rdbgp Options
   //

   opt_node = _xmlcfg_find_simple(projectHandle,"List[@Name='rdbgp Options']",config_node);

   // Clear out old options
   if( opt_node >= 0 ) {
      _xmlcfg_delete(projectHandle,opt_node,false);
   }
   opt_node = _xmlcfg_add(projectHandle,config_node,VPJTAG_LIST,VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add_attribute(projectHandle,opt_node,"Name","rdbgp Options",0);

   // ServerHost
   int node = _xmlcfg_add(projectHandle,opt_node,VPJTAG_ITEM,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add_attribute(projectHandle,node,"Name","ServerHost",0);
   _xmlcfg_add_attribute(projectHandle,node,"Value",rdbgp_opts.serverHost,0);

   // ServerPort
   node = _xmlcfg_add(projectHandle,opt_node,VPJTAG_ITEM,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add_attribute(projectHandle,node,"Name","ServerPort",0);
   _xmlcfg_add_attribute(projectHandle,node,"Value",rdbgp_opts.serverPort,0);

   // ListenInBackground
   node = _xmlcfg_add(projectHandle,opt_node,VPJTAG_ITEM,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add_attribute(projectHandle,node,"Name","ListenInBackground",0);
   _xmlcfg_add_attribute(projectHandle,node,"Value",(int)rdbgp_opts.listenInBackground,0);

   // Remote Mappings
   RdbgpRemoteFileMapping remote_file_map;
   foreach( remote_file_map in rdbgp_opts.remoteFileMap ) {
      // Map
      int map_node = _xmlcfg_add(projectHandle,opt_node,VPJTAG_LIST,VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_add_attribute(projectHandle,map_node,"Name","Map",0);
      // RemoteRoot
      node = _xmlcfg_add(projectHandle,map_node,VPJTAG_ITEM,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_add_attribute(projectHandle,node,"Name","RemoteRoot",0);
      _xmlcfg_add_attribute(projectHandle,node,"Value",remote_file_map.remoteRoot,0);
      // LocalRoot
      node = _xmlcfg_add(projectHandle,map_node,VPJTAG_ITEM,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_add_attribute(projectHandle,node,"Name","LocalRoot",0);
      _xmlcfg_add_attribute(projectHandle,node,"Value",remote_file_map.localRoot,0);
   }

   // DBGp features
   // Not used yet.
   //node = _xmlcfg_add(projectHandle,opt_node,VPJTAG_ITEM,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   //_xmlcfg_add_attribute(projectHandle,node,"Name","feature_name",0);
   //_xmlcfg_add_attribute(projectHandle,node,"Value",(int)rdbgp_opts.dbgp_features.feature_name,0);
}

static void setProjectOptions(int projectHandle, _str (&configList)[], RubyOptions (&ruby_opts_list):[], RdbgpOptions (&rdbgp_opts_list):[])
{
   foreach( auto config in configList ) {
      setProjectOptionsForConfig(projectHandle,config,ruby_opts_list:[config],rdbgp_opts_list:[config]);
   }
}

static _str guessRubyExePath()
{
   if( def_ruby_exe_path != "" ) {
      // No guessing necessary
      return def_ruby_exe_path;
   }
   _str exePath = path_search("ruby"EXTENSION_EXE);
   return exePath;
}

/**
 * Callback called from _project_command to prepare the 
 * environment for running ruby command-line interpreter. The 
 * value found in def_ruby_exe_path takes precedence. If not 
 * found, the environment will be checked for existing values. 
 * If all else fails, a path search will be performed. 
 *
 * @param projectHandle  Project handle. Set to -1 to use 
 *                       current project. Defaults to -1.
 * @param config         Project configuration name. Set to "" 
 *                       to use current configuration. Defaults
 *                       to "".
 * @param target         Project target name (e.g. "Execute", 
 *                       "Compile", etc.).
 * @param quiet          Set to true if you do not want to 
 *                       display error messages to user.
 *                       Defaults to false.
 * @param error_hint     (out) Set to a user-friendly message on 
 *                       error suitable for display in a message.
 *
 * @return 0 on success, <0 on error.
 */
int _ruby_set_environment(int projectHandle=-1, _str config="", _str target="",
                            boolean quiet=false, _str& error_hint=null)
{
   if( _project_name == "" ) {
      return 0;
   }

   target = lowcase(target);
   if( target == "ruby options" ) {
      // If user selects Build>Ruby Options tool then the Ruby Options dialog could
      // come up twice if the Ruby interpreter is not set. This would
      // happen because _project_command() calls us before executing any tool
      // in order to get the environment set up.
      return 0;
   }

   // Help for the user in case of error
   error_hint = "Set the Ruby interpreter (\"Build\",\"Ruby Options\").";

   if( projectHandle < 0 ) {
      _ProjectGet_ActiveConfigOrExt(_project_name,projectHandle,config);
   }

   boolean isRubyProject = ( strieq("ruby",_ProjectGet_Type(projectHandle,config)) );

   // Restore the original environment. This is done so the
   // path for ruby.exe is not appended over and over.
   _restore_origenv(true);

   _str rubyExePath = "";
   if( def_ruby_exe_path != "" ) {
      // Use def_ruby_exe_path
      rubyExePath = def_ruby_exe_path;
   } else {
      if( !isRubyProject ) {
         // Prompt user for interpreter
         int status = _mdi.textBoxDialog("Ruby Interpreter",
                                         0,
                                         0,
                                         "",
                                         "OK,Cancel:_cancel\tSet the Ruby interpreter so the program can be found. \nSpecify the path to 'ruby"EXTENSION_EXE"'.",  // Button List
                                         "",
                                         "-bf Ruby interpreter:":+guessRubyExePath());
         if( status < 0 ) {
            // Probably COMMAND_CANCELLED_RC
            return status;
         }

         // Save the values entered and mark the configuration as modified
         def_ruby_exe_path = _param1;
         _config_modify_flags(CFGMODIFY_DEFVAR);
         rubyExePath = def_ruby_exe_path;
      } else {
         // Show Ruby Options dialog and let user set it from there
         rubyoptions('-setting-environment');
         rubyExePath = def_ruby_exe_path;
      }
   }

   // Make sure we got a path
   if( rubyExePath == "" ) {
      return COMMAND_CANCELLED_RC;
   }

   // Set the environment
   set_env('SLICKEDIT_RUBY_EXE',rubyExePath);
   _str rubyDir = _strip_filename(rubyExePath,'N');
   _maybe_strip_filesep(rubyDir);
   // PATH
   _str path = _replace_envvars("%PATH%");
   _maybe_prepend(path,PATHSEP);
   path = rubyDir:+path;
   set("PATH="path);

   // Success
   return 0;
}

/**
 * Prepares the environment for running ruby command-line 
 * interpreter. 
 *
 * @return 0 on success, <0 on error.
 */
_command int set_ruby_environment()
{
   int status = _ruby_set_environment();
   return status;
}

/**
 * Project package-specific front-end to 
 * _parse_project_command() used to validate and process the
 * command that is about to be run. The argument descriptions
 * are the same as for _parse_project_command(), so see the help
 * for _parse_project_command for parameter help.
 *
 * @param command       See _parse_project_command.
 * @param buf_name      See _parse_project_command.
 * @param project_name  See _parse_project_command.
 * @param cword         See _parse_project_command.
 * @param argline       See _parse_project_command.
 * @param target        See _parse_project_command.
 * @param class_path    See _parse_project_command.
 * @param handle        Project handle. Set to 0 to use active 
 *                      project. Defaults to 0.
 * @param config        Current project config. Set to '' to use 
 *                      active project config. Defaults to ''.
 *
 * @return Parsed and validated command line on success, "" on 
 *         error.
 */
_str _ruby_parse_project_command(_str command,
                                 _str buf_name,
                                 _str project_name,
                                 _str cword,
                                 _str argline='',
                                 _str target='',
                                 _str class_path='',
                                 int handle=0, _str config='')
{
   _str result = _parse_project_command(command,buf_name,project_name,cword,argline,target,class_path);

   do {

      if( stricmp('execute',target) != 0 ) {
         // We are only interested in Execute (and Debug via Execute)
         break;
      }
   
      if( handle <= 0 || config == "" ) {
         _ProjectGet_ActiveConfigOrExt(_project_name,handle,config);
      }
      RubyOptions ruby_opts;
      getProjectRubyOptionsForConfig(handle,config,ruby_opts);
   
      // We are only interested in inspecting the command if the user has
      // specified to use the current buffer. We assume that if they specified
      // a DefaultFile in Options that they know what they are doing.
      if( ruby_opts.defaultFile == "" && pos('%f',command) && buf_name != "" ) {
         // Validate buffer name
         _str langId = _Filename2LangId(buf_name);
         if( langId != 'ruby' ) {
            _str msg = nls('"%s" does not appear to be a runnable script.',buf_name);
            msg = msg"\n\nContinue to execute this script?";
            msg = msg"\n\n"'Note: You can choose a default script to run from the Options dialog ("Build", "Ruby Options")';
            int status = _message_box(msg,"",MB_YESNO|MB_ICONQUESTION);
            if( status != IDYES ) {
               // User cancels
               result = "";
               break;
            }
         }
      }

   } while( false );

   return result;
}

/**
 * Callback called from _project_command with result of project
 * command run. 
 * 
 * @param projectHandle  Project handle. Set to -1 to use 
 *                       current project. Defaults to -1.
 * @param config         Project configuration name. Set to "" 
 *                       to use current configuration. Defaults
 *                       to "".
 * @param socket_or_status  Native socket handle to connect 
 *                          debugger to or <0 error.
 * @param cmdline        The commandline run that resulted in 
 *                       'result'.
 * @param target         Project target name (e.g. "Debug", 
 *                       "Execute", "Compile", etc.).
 * @param buf_name       Original buf_name argument passed in to 
 *                       _project_command.
 * @param word           Original current word passed in to 
 *                       _project_command.
 * @param debugStepType  Original debugStepType ('go', 'into', 
 *                       'reload') passed in to
 *                       _project_command.
 * @param quiet          Set to true if you do not want to 
 *                       display error messages to user.
 *                       Defaults to false.
 * @param error_hint     (out) Set to a user-friendly message on 
 *                       error suitable for display in a message.
 *
 * @return 0 on success, <0 on error.
 * @param quiet 
 * @param error_hint 
 * 
 * @return int 
 */
int _ruby_project_command_status(int projectHandle, _str config,
                                   int socket_or_status,
                                   _str cmdline,
                                   _str target,
                                   _str buf_name,
                                   _str word,
                                   _str debugStepType,
                                   boolean quiet,
                                   _str& error_hint)
{
   // Necessary because _project_command will pass us null status when
   // it has executed a target that returns void (e.g. 'rubyoptions').
   if( socket_or_status._varformat() != VF_INT ) {
      socket_or_status = 0;
   }

   if( lowcase(target) != 'debug' ) {
      // We are only interested in Debug command,
      // so return original status.
      return socket_or_status;
   }

   if( socket_or_status < 0 ) {
      // Debug command failed, so go no further
      return socket_or_status;
   }

   if( _project_DebugCallbackName != "rdbgp" ) {
      // Not a rdbgp debugger project. Nothing wrong with that, but
      // we cannot do anything with it.
      return 0;
   }

   int status = 0;

   do {

      // Assemble debugger_args
      _str debugger_args = "";
      debugger_args = debugger_args' -socket='socket_or_status;
      // Pass the project remote-directory <=> local-directory mappings
      RubyOptions ruby_opts;
      getProjectRubyOptionsForConfig(projectHandle,config,ruby_opts);
      RdbgpOptions rdbgp_opts;
      rdbgp_project_get_options_for_config(projectHandle,config,rdbgp_opts);
      RdbgpRemoteFileMapping map;
      foreach( map in rdbgp_opts.remoteFileMap ) {
         if( map.remoteRoot != "" && map.localRoot != "" ) {
            debugger_args = debugger_args' -map='map.remoteRoot':::'map.localRoot;
         }
      }
      // DBGp features
      debugger_args = debugger_args' 'se.debug.dbgp.dbgp_make_debugger_args(rdbgp_opts.dbgp_features);
   
      // Attempt to start debug session
      status = debug_begin("rdbgp","","","",def_debug_timeout,null,debugger_args);

   } while( false );

   if( status != 0 && socket_or_status >= 0 ) {
      // Error
      // Do not want to orphan a connected socket, so close it now.
      vssSocketClose(socket_or_status);
   }
   return status;
}

/**
 * Start debugging session. 
 *
 * @return >0 socket connection on success, <0 on error. 
 */
_command int ruby_debug()
{
   if( _project_name == "" ) {
      // What are we doing here?
      _str msg = "No project. Cannot debug.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return INVALID_ARGUMENT_RC;
   }

   if( _project_DebugCallbackName != "rdbgp" ) {
      // What are we doing here?
      _str msg = "Project does not support rdbgp. Cannot debug.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return INVALID_ARGUMENT_RC;
   }

   RdbgpOptions rdbgp_opts;
   rdbgp_project_get_options_for_config(_ProjectHandle(),GetCurrentConfigName(),rdbgp_opts);
   if( rdbgp_opts.serverHost == "" || rdbgp_opts.serverPort == "" ) {
      _str msg = "Invalid rdbgp parameters. Cannot debug.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return INVALID_ARGUMENT_RC;
   }

   int status_or_socket = 0;

   // We do not want the possiblility of the passive connection monitor
   // attempting to start a debug session right in the middle of things
   // because it also recognized a pending connection. That would get
   // very confusing.
   int old_almost_active = (int)rdbgp_almost_active();
   rdbgp_almost_active(1);

   do {

      boolean already_listening = rdbgp_is_listening(rdbgp_opts.serverHost,rdbgp_opts.serverPort);
      if( !already_listening || !rdbgp_is_pending(rdbgp_opts.serverHost,rdbgp_opts.serverPort) ) {
   
         // Must EXECUTE and listen for resulting connection from debugger engine

         _str rdbgp_dir = getRdbgpDir();
         if( rdbgp_dir == "" ) {
            _str msg = "Could not find rdbgp directory. Cannot start debugger.";
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            status_or_socket = PATH_NOT_FOUND_RC;
            break;
         }
#if __NT__
         // 9/4/2010 - rb
         // Ruby require() cannot deal with DOS back-slash (\) file-separators when built on
         // mingw platform (e.g. RUBY_PLATFORM=i386-mingw), so must translate to forward-slash (/).
         // Converting to FILESEP2 should be safe for all cases, so go ahead and get it out of the
         // way now.
         rdbgp_dir = translate(rdbgp_dir,FILESEP2,FILESEP,'');
#endif

         if( !already_listening ) {
            // Must provision a one-shot server before EXECUTE, otherwise rdbgp will fail
            // the connection test to us.
            rdbgp_watch(rdbgp_opts.serverHost,rdbgp_opts.serverPort);
         }

         // Note:
         // Cygwin ruby.exe not supported.
         // Cygwin ruby.exe cannot deal with path arguments (e.g. the debugee)
         // that are not Cygwin-ized. We would have to cygwin-ize the script passed
         // into rdbgp.rb and RUBYDB_LIB environment variable value. We can deal with
         // the path to 'rdbgp.rb' here, but we have no control over the script that
         // project_execute() will run.

         // Get the actual host:port the server is listening on.
         // This is necessary since the user may have elected to use a
         // dynamically allocated port and we need to pass the actual
         // listener address to rdbgp.rb.
         _str host = rdbgp_opts.serverHost;
         _str port = rdbgp_opts.serverPort;
         rdbgp_get_server_address(host,port);

         _str rdbgp_exe = maybe_quote_filename(rdbgp_dir'/rdbgp.rb');
         // -I : path to rdbgp base directory
         // -r : require the rdbgp.rb file before executing/debugging target script
         _str rdbgp_cmdline = '-I'maybe_quote_filename(rdbgp_dir)' -r 'rdbgp_exe;
         //say('ruby_debug: rdbgp_cmdline='rdbgp_cmdline);

         _str old_args = get_env("SLICKEDIT_RUBY_EXECUTE_ARGS");
         if( old_args == "" && rc == STRING_NOT_FOUND_RC ) {
            old_args = null;
         }
         set_env("SLICKEDIT_RUBY_EXECUTE_ARGS",rdbgp_cmdline);
         // RUBYDB_OPTS
         set("RUBYDB_OPTS=HOST="host" PORT="port);

         int override_flags = 0;
#if !__UNIX__
         // Force script to be shelled to console
         //override_flags |= OVERRIDE_CAPTUREOUTPUTWITH_PROCESSBUFFER;
#endif
         status_or_socket = (int)_project_command2('execute',false,false,override_flags);
         set_env("SLICKEDIT_RUBY_EXECUTE_ARGS",old_args);

         if( status_or_socket != 0 ) {
            // Error. project_execute should have taken care of displaying any message.
            if( !already_listening ) {
               // Clean up the one-shot server we created
               rdbgp_shutdown(rdbgp_opts.serverHost,rdbgp_opts.serverPort);
            }
            break;
         }
         // Fall through to actively waiting for connection
      }
   
      se.debug.rdbgp.RdbgpConnectionProgressDialog dlg;
      int timeout = 1000*def_debug_timeout;
      status_or_socket = rdbgp_wait_and_accept(rdbgp_opts.serverHost,rdbgp_opts.serverPort,timeout,&dlg,false);

      if( !already_listening ) {
         // Clean up the one-shot server we created
         rdbgp_shutdown(rdbgp_opts.serverHost,rdbgp_opts.serverPort);
      } else {
         if( status_or_socket < 0 ) {
            // Error. Was it serious?
            if( status_or_socket != COMMAND_CANCELLED_RC && status_or_socket != SOCK_TIMED_OUT_RC ) {
               _str msg = "You just failed to accept a connection from rdbgp. The error was:\n\n" :+
                          get_message(status_or_socket)" ("status_or_socket")\n\n" :+
                          "Would you like to stop listening for a connection?";
               int result = _message_box(msg,"",MB_YESNO|MB_ICONQUESTION);
               if( result == IDYES ) {
                  rdbgp_shutdown(rdbgp_opts.serverHost,rdbgp_opts.serverPort);
                  sticky_message(nls("Server listening at %s:%s has been shut down.",rdbgp_opts.serverHost,rdbgp_opts.serverPort));
               } else {
                  // Clear the last error, so the watch timer does not pick
                  // it up and throw up on the user a second time.
                  rdbgp_clear_last_error(rdbgp_opts.serverHost,rdbgp_opts.serverPort);
               }
            } else {
               // Clear the last error, so the watch timer does not pick
               // it up and throw up on the user a second time.
               rdbgp_clear_last_error(rdbgp_opts.serverHost,rdbgp_opts.serverPort);
            }
         }

         // Note: The server takes care of resuming any previous watch
      }
      //say('ruby_debug: h1 - status_or_socket='status_or_socket);

   } while( false );

   rdbgp_almost_active(old_almost_active);

   return status_or_socket;
}

#define RUBYOPTS_FORM_MINWIDTH  8175
#define RUBYOPTS_FORM_MINHEIGHT 7950

defeventtab _ruby_options_form;

static void getTabNames(_str (&tabNames)[])
{
   _str field1, field2, field3, field4, field5;
   _str field6, field7, field8, field9, field10;
   _str field11, caption="";
   int i;
   for( i=0; i < p_NofTabs; ++i ) {
      SSTABCONTAINERINFO info;
      if (_getTabInfo(i, info)) {
         tabNames[tabNames._length()] = strip(info.caption,'B','"');
      }
   }
}

static boolean changingCurrentConfig(int value=-1)
{
   typeless old_value = _GetDialogInfoHt("changingCurrentConfig");
   if( old_value == null ) {
      old_value = false;
   }
   if( value >= 0 ) {
      _SetDialogInfoHt("changingCurrentConfig",(value!=0));
   }
   return ( old_value != 0 );
}

static boolean changingMappings(int value=-1)
{
   typeless old_value = _GetDialogInfoHt("changingMappings");
   if( old_value == null ) {
      old_value = false;
   }
   if( value >= 0 ) {
      _SetDialogInfoHt("changingMappings",(value!=0));
   }
   return ( old_value != 0 );
}

static void getFormOptions(RubyOptions& ruby_opts, RdbgpOptions& rdbgp_opts)
{
   //
   // Run tab
   //

   // Interpreter arguments
   ruby_opts.interpreterArgs = ctl_interpreter_args.p_text;
   // Default file
   ruby_opts.defaultFile = ctl_default_file.p_text;
   // Script arguments
   ruby_opts.scriptArgs = ctl_script_args.p_text;

   //
   // Debug tab
   //

   rdbgp_opts.serverHost = ctl_server_host.p_text;
   if( ctl_default_port.p_value ) {
      rdbgp_opts.serverPort = "0";
   } else {
      rdbgp_opts.serverPort = ctl_server_port.p_text;
   }
   rdbgp_opts.listenInBackground = (ctl_listen_on_startup.p_value != 0);
   // DBGp features
   // Not used yet.
   //rdbgp_opts.dbgp_features.feature_name = (ctl_feature_name.p_value != 0);
   rdbgp_opts.dbgp_features.show_hidden = 0;

   //
   // Remote Mappings tab
   //

   rdbgp_opts.remoteFileMap._makeempty();
   int index = ctl_mappings._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while( index >= 0 ) {
      _str mapline = ctl_mappings._TreeGetCaption(index);
      _str localRoot="";
      _str remoteRoot="";
      parse mapline with remoteRoot"\t"localRoot;
      int i = rdbgp_opts.remoteFileMap._length();
      rdbgp_opts.remoteFileMap[i].localRoot = localRoot;
      rdbgp_opts.remoteFileMap[i].remoteRoot = remoteRoot;
      index = ctl_mappings._TreeGetNextSiblingIndex(index);
   }
}

static void activateOptionsTab(_str tabName)
{
   _str tabNames[] = null;
   ctl_options_tab.getTabNames(tabNames);
   int i, n=tabNames._length();
   for( i=0; i < n; ++i ) {
      if( strieq(tabName,tabNames[i]) ) {
         ctl_options_tab.p_ActiveTab = i;
      }
   }
}

static void selectMapping(int index)
{
   int old_value = (int)changingMappings(1);
   _TreeDeselectAll();
   int state=0, bm1=0, bm2=0, flags=0;
   _TreeSelectLine(index);
   changingMappings(old_value);
   ctl_mappings.call_event(CHANGE_LEAF_ENTER,index,ctl_mappings,ON_CHANGE,'w');
}

static _str normalizePath(_str path)
{
   // Normalize FILESEP
   _str npath = translate(path,FILESEP,FILESEP2);
   // Normalize trailing FILESEP
   _maybe_strip_filesep(npath);
   return npath;
}

static _str pathToHashKey(_str path)
{
   _str key = normalizePath(path);

   // Convert all back-slashes to forward-slashes
   key = translate(key,'/','\');

   if( substr(key,2,1) == ":" ) {
      // DOS paths get stored lower-case
      key = lowcase(key);
   } else if( substr(key,1,2) == "\\\\" ) {
      // Windows UNC paths get stored lower-case
      key = lowcase(key);
   } else {
      key = _file_case(key);
   }

   return key;
}

static boolean validateFormOptions(RubyOptions& ruby_opts, RdbgpOptions& rdbgp_opts)
{
   getFormOptions(ruby_opts,rdbgp_opts);

   // Used to flag duplicate remote-to-local mappings
   int remote2local_dup_set:[] = null;

   int i, n=rdbgp_opts.remoteFileMap._length();
   for( i=0; i < n; ++i ) {

      // Remote root is the pivot, so we should never have an empty remote-root-directory entry
      _str remoteRoot = rdbgp_opts.remoteFileMap[i].remoteRoot;
      if( remoteRoot == "" ) {
         // Park the user on the problem
         _str msg = nls("Missing remote directory.");
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         activateOptionsTab("Remote Mappings");
         p_window_id = ctl_mappings;
         _set_focus();
         selectMapping(i+1);
         return false;
      }

      // remote-to-local duplicate check
      if( remote2local_dup_set._indexin(pathToHashKey(remoteRoot)) ) {
         // Park the user on the problem
         _str msg = nls("More than one entry for remote directory:\n\n%s",remoteRoot);
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         activateOptionsTab("Remote Mappings");
         p_window_id = ctl_mappings;
         _set_focus();
         selectMapping(i+1);
         return false;
      }
      // New remote-to-local mapping
      remote2local_dup_set:[pathToHashKey(remoteRoot)] = 1;

      // Invalid local-root-directory check
      // Note: It is okay for more than one unique remote-directory to map to the
      // same local-directory, so no check for duplicates on local-directory.
      _str localRoot = rdbgp_opts.remoteFileMap[i].localRoot;
      if( localRoot == "" || !isdirectory(localRoot) ) {
         // Park the user on the problem
         _str msg = "";
         if( remoteRoot == "" ) {
            msg = nls("Missing local directory.");
         } else {
            msg = nls("Invalid local directory '%s'.",localRoot);
         }
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         activateOptionsTab("Remote Mappings");
         p_window_id = ctl_mappings;
         _set_focus();
         selectMapping(i+1);
         return false;
      }

   }

   if( rdbgp_opts.serverHost == "" ) {
      _str msg = "Invalid/missing rdbgp host";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      activateOptionsTab("Debug");
      p_window_id = ctl_server_host;
      _set_sel(1,length(p_text)+1);
      _set_focus();
      return false;
   }
   if( rdbgp_opts.serverPort == "0" ) {
      // Dynamic port is okay
   } else if( rdbgp_opts.serverPort == "" || vssServiceNameToPort(rdbgp_opts.serverPort) < 0 ) {
      _str msg = "Invalid/missing rdbgp port";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      activateOptionsTab("Debug");
      p_window_id = ctl_server_port;
      _set_sel(1,length(p_text)+1);
      _set_focus();
      return false;
   }

   // All good
   return true;
}

static void resetMappingsTree()
{
   // Clear the tree
   ctl_mappings._TreeDelete(TREE_ROOT_INDEX,'C');
}

static void setFormOptionsFromConfig(_str config,
                                     RubyOptions (&all_ruby_opts):[],
                                     RubyOptions& default_ruby_opts,
                                     RdbgpOptions (&all_rdbgp_opts):[],
                                     RdbgpOptions& default_rdbgp_opts)
{
   if( default_ruby_opts == null ) {
      // Fall back to generic default options
      makeDefaultRubyOptions(default_ruby_opts);
   }
   RubyOptions ruby_opts = null;
   if( default_rdbgp_opts == null ) {
      // Fall back to generic default options
      rdbgp_make_default_options(default_rdbgp_opts);
   }
   RdbgpOptions rdbgp_opts = null;

   if( config == ALL_CONFIGS ) {
      // If options do not match across all configs, then use default options instead
      ruby_opts = default_ruby_opts;
      rdbgp_opts = default_rdbgp_opts;
      _str last_cfg;
      _str cfg;

      // ruby_opts
      last_cfg = "";
      foreach( cfg=>. in all_ruby_opts ) {
         if( last_cfg != "" ) {
            if( all_ruby_opts:[last_cfg] != all_ruby_opts:[cfg] ) {
               // No match, so use default options
               ruby_opts = default_ruby_opts;
               break;
            }
         }
         // Match (or first config)
         ruby_opts = all_ruby_opts:[cfg];
         last_cfg = cfg;
      }

      // rdbgp_opts
      last_cfg = "";
      foreach( cfg=>. in all_rdbgp_opts ) {
         if( last_cfg != "" ) {
            if( all_rdbgp_opts:[last_cfg] != all_rdbgp_opts:[cfg] ) {
               // No match, so use default options
               rdbgp_opts = default_rdbgp_opts;
               break;
            }
         }
         // Match (or first config)
         rdbgp_opts = all_rdbgp_opts:[cfg];
         last_cfg = cfg;
      }
   } else {
      ruby_opts = all_ruby_opts:[config];
      rdbgp_opts = all_rdbgp_opts:[config];
   }

   //
   // Run tab
   //

   // Interpreter arguments
   ctl_interpreter_args.p_text = ruby_opts.interpreterArgs;
   // Default file
   ctl_default_file.p_text = ruby_opts.defaultFile;
   // Script arguments
   ctl_script_args.p_text = ruby_opts.scriptArgs;

   //
   // Debug tab
   //

   // Local host
   ctl_server_host.p_text = rdbgp_opts.serverHost;
   // Local port
   if( rdbgp_opts.serverPort == "0" || rdbgp_opts.serverPort == "" ) {
      ctl_default_port.p_value = 1;
      ctl_specified_port.p_value = 0;
      // The specified port will be disabled because the user chose a
      // system-provided port, but leave whatever is there in case they
      // change their mind and want to switch back while the dialog is
      // still up.
      if( ctl_server_port.p_text == "" ) {
         // Stuff a default value in there
         ctl_server_port.p_text = "9000";
      }
   } else {
      ctl_default_port.p_value = 0;
      ctl_specified_port.p_value = 1;
      ctl_server_port.p_text = rdbgp_opts.serverPort;
   }
   ctl_default_port.call_event(ctl_default_port,LBUTTON_UP,'w');
   // Listen on startup
   ctl_listen_on_startup.p_value = (int)rdbgp_opts.listenInBackground;
   // DBGp features
   // Not used yet.
   //ctl_feature_name.p_value = (int)rdbgp_opts.dbgp_features.feature_name;

   //
   // Remote Mappings tab
   //

   resetMappingsTree();
   int i, n=rdbgp_opts.remoteFileMap._length();
   for( i=0; i < n; ++i ) {
      _str mapline = rdbgp_opts.remoteFileMap[i].remoteRoot"\t"rdbgp_opts.remoteFileMap[i].localRoot;
      int index = ctl_mappings._TreeAddItem(TREE_ROOT_INDEX,mapline,TREE_ADD_AS_CHILD,0,0,-1);
   }
}

static void saveRubyOptionsForConfig(_str config, RubyOptions& ruby_opts, RubyOptions (&all_ruby_opts):[])
{
   // Gather up all affected config names
   _str configIndices[] = null;
   if( config == ALL_CONFIGS ) {
      // All configurations get the same settings
      _str cfg;
      foreach( cfg=>. in all_ruby_opts ) {
         configIndices[configIndices._length()] = cfg;
      }
   } else {
      configIndices[0] = config;
   }

   // Now save options for affected configs
   int i;
   for( i=0; i < configIndices._length(); ++i ) {
      _str cfg = configIndices[i];
      all_ruby_opts:[cfg] = ruby_opts;
   }
}

static void saveRdbgpOptionsForConfig(_str config, RdbgpOptions& rdbgp_opts, RdbgpOptions (&all_rdbgp_opts):[])
{
   // Gather up all affected config names
   _str configIndices[];
   if( config == ALL_CONFIGS ) {
      // All configurations get the same settings
      _str cfg;
      foreach( cfg=>. in all_rdbgp_opts ) {
         configIndices[configIndices._length()] = cfg;
      }
   } else {
      configIndices[0] = config;
   }

   // Now save options for affected configs
   int i;
   for( i=0; i < configIndices._length(); ++i ) {
      _str cfg = configIndices[i];
      all_rdbgp_opts:[cfg] = rdbgp_opts;
   }
}

static boolean changeCurrentConfig(_str config)
{
   boolean success = false;

   int old_changing_config = (int)changingCurrentConfig(1);

   do {

      _str lastConfig = _GetDialogInfoHt("lastConfig");
      RubyOptions ruby_opts;
      RdbgpOptions rdbgp_opts;
      if( !validateFormOptions(ruby_opts,rdbgp_opts) ) {
         // Bad options
         break;
      }
   
      // All good, save these settings
      RubyOptions (*pAllRubyOpts):[] = _GetDialogInfoHtPtr("allRubyOpts");
      RdbgpOptions (*pAllRdbgpOpts):[] = _GetDialogInfoHtPtr("allRdbgpOpts");
      saveRubyOptionsForConfig(lastConfig,ruby_opts,*pAllRubyOpts);
      saveRdbgpOptionsForConfig(lastConfig,rdbgp_opts,*pAllRdbgpOpts);
   
      // Set form options for new config.
      // "All Configurations" case:
      // If switching to "All Configurations" and configs do not match, then use
      // last options for the default. This is better than blasting the user's
      // settings completely with generic default options.
      lastConfig = config;
      _SetDialogInfoHt("lastConfig",lastConfig);
      setFormOptionsFromConfig(lastConfig,
                               *pAllRubyOpts,ruby_opts,
                               *pAllRdbgpOpts,rdbgp_opts);
      success = true;

   } while( false );

   changingCurrentConfig(old_changing_config);

   return success;
}

void ctl_current_config.on_change(int reason)
{
   if( changingCurrentConfig() ) {
      return;
   }
   if( reason != CHANGE_CLINE ) {
      return;
   }

   changingCurrentConfig(1);
   if( !changeCurrentConfig(p_text) ) {
      // Set config back to last good config
      _str lastConfig = _GetDialogInfoHt("lastConfig");
      p_text = lastConfig;
   }
   changingCurrentConfig(0);
}

void ctl_browse_default_file.lbutton_up()
{
   _str wildcards = "Ruby Files (*.rb;*.rby)";
   _str format_list = "";
   parse def_file_types with 'Ruby Files' +0 format_list',';
   if( format_list == "" ) {
      // Fall back
      format_list = "Ruby Files (*.rb;*.rby)";
   }

   // Try to be smart about the initial directory
   int projectHandle = _GetDialogInfoHt("projectHandle");
   _str init_dir = _ProjectGet_WorkingDir(projectHandle);

   _str result = _OpenDialog("-modal",
                             "Default File",
                             wildcards,
                             format_list,
                             0,            // OFN_* flags
                             "",           // Default extensions
                             "",           // Initial filename
                             init_dir,     // Initial directory
                             "",           // Retrieve name
                             ""            // Help topic
                            );
   if( result != "" ) {
      p_prev.p_text = result;
      p_prev._set_focus();
   }
}

_command void ctlinsertRubyInterpreterArg(_str text="", _str delim='%')
{
   if( substr(text,1,length('-I')) == '-I' ) {

      int textbox_wid = p_active_form._find_control('ctl_interpreter_args');

      // Preserve selection in text box
      int start_pos, end_pos;
      textbox_wid._get_sel(start_pos,end_pos);

      // Prompt for $LOAD_PATH directory
      _str result = _ChooseDirDialog("Choose Include Directory","","",CDN_PATH_MUST_EXIST);

      // Restore selection in text box
      textbox_wid._set_sel(start_pos,end_pos);

      if( result == "" ) {
         // User cancelled
         return;
      }

      // ctlinsert expects the active window to be the menu button and
      // steps back from there to the text box.
      p_window_id = textbox_wid.p_next;

      // Insert the option
      _maybe_strip_filesep(result);
      ctlinsert('-I'maybe_quote_filename(result)' ',delim);
      return;
   }
   // Nothing special
   ctlinsert(text,delim);
}

static void selectInterpreterArgMenu()
{
   int index = find_index("_temp_interpreter_arg_menu",oi2type(OI_MENU));
   if( index > 0 ) {
      delete_name(index);
   }
   index = insert_name("_temp_interpreter_arg_menu",oi2type(OI_MENU));
   _str caption;
   _menu_insert(index,-1,0,"Specify $LOAD_PATH directory (-Idirectory, several -I's allowed)",'ctlinsertRubyInterpreterArg -Idirectory ');
   _menu_insert(index,-1,0,"Turn warnings on (-w)",'ctlinsertRubyInterpreterArg -w ');
   _menu_insert(index,-1,0,"Set warning level silence (-W0)",'ctlinsertRubyInterpreterArg -W0 ');
   _menu_insert(index,-1,0,"Set warning level medium (-W1)",'ctlinsertRubyInterpreterArg -W1 ');
   _menu_insert(index,-1,0,"Set warning level verbose (-W2)",'ctlinsertRubyInterpreterArg -W2 ');
   _menu_insert(index,-1,0,"Turn on tainting checks (-T)",'ctlinsertRubyInterpreterArg -T ');
   int menu_handle = p_active_form._menu_load(index,'P');
   // Show the menu
   int x = 100;
   int y = 100;
   x = mou_last_x('M') - x;
   y = mou_last_y('M') - y;
   _lxy2dxy(p_scale_mode,x,y);
   _map_xy(p_window_id,0,x,y,SM_PIXEL);
   int flags = VPM_LEFTALIGN|VPM_RIGHTBUTTON;
   //_KillToolTipMessages();
   _KillToolButtonTimer();
   int status = _menu_show(menu_handle,flags,x,y);
   _menu_destroy(menu_handle);
   // Delete temporary menu resource
   delete_name(index);
}

void ctl_interpreter_arg_button.lbutton_down()
{
   p_window_id = ctl_interpreter_args;
   if( _get_sel() == 1 && p_sel_length == 0 ) {
      // Let them know that they will be replacing the entire string
      _set_sel(1,length(p_text)+1);
   }
   p_window_id = ctl_interpreter_arg_button;
   selectInterpreterArgMenu();
}

void ctl_map_add.lbutton_up()
{
   // Prompt user for remote-root, local-root
   int status = 0;
   status = _mdi.textBoxDialog("Remote Mapping",
                               0,
                               ctl_mappings.p_width,
                               "",
                               "OK,Cancel:_cancel\tSpecify the remote directory along with its corresponding local directory.",  // ButtonNCaption list
                               "",
                               "Remote directory:",
                               "-bd Local directory:");
   if( status < 0 ) {
      // Probably COMMAND_CANCELLED_RC
      return;
   }

   _str remoteRoot = _param1;
   _str localRoot = _param2;
   _str mapline = remoteRoot"\t"localRoot;
   ctl_mappings._TreeAddItem(TREE_ROOT_INDEX,mapline,TREE_ADD_AS_CHILD,0,0,-1);
}

void ctl_map_remove.lbutton_up()
{
   int index = ctl_mappings._TreeCurIndex();
   if( index > 0 ) {
      ctl_mappings._TreeDelete(index);
   }
}

void ctl_mappings.on_change(int reason, int index=-1, int col=-1, _str text="")
{
   switch( reason ) {
   case CHANGE_EDIT_CLOSE:
      break;
   }
}

void ctl_mappings.'DEL'()
{
   ctl_map_remove.call_event(ctl_map_remove,LBUTTON_UP,'w');
}

void ctl_browse_ruby_exe.lbutton_up()
{
#if __UNIX__
   _str wildcards = "";
#else
   _str wildcards = "Executable Files (*.exe;*.com;*.bat;*.cmd)";
#endif
   _str format_list = wildcards;

   // Try to be smart about the initial filename and directory
   _str init_dir = "";
   _str init_filename = ctl_ruby_exe_path.p_text;
   if( init_filename == "" ) {
      init_filename = guessRubyExePath();
   }
   if( init_filename != "" ) {
      // Strip off the 'ruby' exe to leave the directory
      init_dir = _strip_filename(init_filename,'N');
      _maybe_strip_filesep(init_dir);
      // Strip directory off 'ruby' exe to leave filename-only
      init_filename = _strip_filename(init_filename,'P');
   }

   _str result = _OpenDialog("-modal",
                             "Ruby Interpreter",
                             wildcards,
                             format_list,
                             0,             // OFN_* flags
                             "",            // Default extensions
                             init_filename, // Initial filename
                             init_dir,      // Initial directory
                             "",            // Retrieve name
                             ""             // Help topic
                            );
   if( result != "" ) {
      result = strip(result,'B','"');
      p_prev.p_text = result;
      p_prev._set_focus();
   }
}

void ctl_default_port.lbutton_up()
{
   // Enable/disable specific port choice
   ctl_server_port.p_enabled = ( 0 == ctl_default_port.p_value );
}

static void onCreateRunTab()
{
}

static void onCreateDebugTab()
{
#if __UNIX__
   // Dialog color
   ctl_rdbgp_note.p_backcolor = 0x80000022;
#endif

   // Get rid of scrollbars if possible
   ctl_rdbgp_note._minihtml_ShrinkToFit();
}

static void onCreateRemoteMappingsTab()
{
   // Mappings tree
   int col_width = ctl_mappings.p_width intdiv 2;
   int remain_width = ctl_mappings.p_width - 2*col_width;
   ctl_mappings._TreeSetColButtonInfo(0,col_width,0/*TREE_BUTTON_EDITABLE*/,-1,"Remote Directory");
   ctl_mappings._TreeSetColButtonInfo(1,col_width+remain_width,0/*TREE_BUTTON_EDITABLE*/,-1,"Local Directory");
   ctl_mappings._TreeSetColEditStyle(0,TREE_EDIT_TEXTBOX);
   ctl_mappings._TreeSetColEditStyle(1,TREE_EDIT_TEXTBOX);

#if __UNIX__
   // Dialog color
   ctl_remote_mappings_note.p_backcolor = 0x80000022;
#endif

   // Get rid of scrollbars if possible
   ctl_remote_mappings_note._minihtml_ShrinkToFit();
}

void ctl_ok.on_create(int projectHandle, _str options="", _str currentConfig="",
                     _str projectFilename=_project_name, boolean isProjectTemplate=false)
{
   _SetDialogInfoHt("projectHandle",projectHandle);
   _SetDialogInfoHt("isProjectTemplate",isProjectTemplate);

   _ruby_options_form_initial_alignment();

   // Parse options passed in
   boolean setting_environment = false;
   _str tabName = "";
   while( options != "" ) {
      _str opt;
      parse options with opt options;
      switch( lowcase(opt) ) {
      case '-setting-environment':
         setting_environment = true;
         break;
      default:
         tabName = opt;
      }
   }
   _SetDialogInfoHt("setting_environment",setting_environment);

   onCreateRunTab();
   onCreateDebugTab();
   onCreateRemoteMappingsTab();

   changingCurrentConfig(1);
   int orig_wid = p_window_id;

   p_window_id = ctl_current_config;
   _str configList[];
   _ProjectGet_ConfigNames(projectHandle,configList);
   int i;
   for( i=0; i < configList._length(); ++i ) {
      if( strieq(_ProjectGet_Type(projectHandle,configList[i]),"ruby") ) {
         _lbadd_item(configList[i]);
         continue;
      }
      // This config does not belong
      configList._deleteel(i);
      --i;
   }
   // "All Configurations" config
   _lbadd_item(ALL_CONFIGS);
   _lbtop();
   if( _lbfind_and_select_item(currentConfig) ) {
      _lbfind_and_select_item(ALL_CONFIGS, '', true);
   }
   _str lastConfig = _lbget_text();

   p_window_id = orig_wid;
   changingCurrentConfig(0);

   RubyOptions allRubyOpts:[] = null;
   RdbgpOptions allRdbgpOpts:[] = null;
   getProjectRubyOptions(projectHandle,configList,allRubyOpts);
   rdbgp_project_get_options(projectHandle,configList,allRdbgpOpts);

   _SetDialogInfoHt("configList",configList);
   _SetDialogInfoHt("lastConfig",lastConfig);
   _SetDialogInfoHt("allRubyOpts",allRubyOpts);
   _SetDialogInfoHt("allRdbgpOpts",allRdbgpOpts);

   // Initialize form with options.
   // Note: Cannot simply call ctl_current_config.ON_CHANGE because
   // we do not want initial values validated (they might not be valid).
   // Note: It is not possible (through the GUI) to bring up the
   // options dialog without at least 1 configuration.
   setFormOptionsFromConfig(lastConfig,
                            allRubyOpts,allRubyOpts:[ configList[0] ],
                            allRdbgpOpts,allRdbgpOpts:[ configList[0] ]);
   ctl_ruby_exe_path.p_text = guessRubyExePath();

   if( tabName == "" ) {
      ctl_options_tab._retrieve_value();
   } else {
      // Select the proper tab
      activateOptionsTab(tabName);
   }
}

void _ruby_options_form.on_load()
{
   boolean setting_environment = 0 != _GetDialogInfoHt("setting_environment");

   if( setting_environment ) {
      _str rubyExePath = ctl_ruby_exe_path.p_text;
      _str msg = "";
      if( rubyExePath != "" ) {
         msg = "Warning: The Ruby interpreter has been automatically found for this project.";
         msg = msg :+ "\n\nPlease verify the Ruby interpreter is correct on the Options dialog that follows (\"Build\", \"Ruby Options\").";
      } else {
         msg = "Warning: The Ruby interpreter is not set for this project.";
         msg = msg :+ "Please set the Ruby interpreter on the Options dialog that follows (\"Build\", \"Ruby Options\").";
      }
      p_window_id = ctl_ruby_exe_path;
      _set_sel(1,length(p_text)+1);
      _set_focus();
      _message_box(msg,"",MB_OK|MB_ICONQUESTION);
   }
}

void ctl_ok.lbutton_up()
{
   // Trigger current form settings validation
   if( !changeCurrentConfig(ctl_current_config.p_text) ) {
      // Error
      return;
   }

   // Save all configs for project
   int projectHandle = _GetDialogInfoHt("projectHandle");
   _str configList[] = _GetDialogInfoHt("configList");
   RubyOptions (*pAllRubyOpts):[] = _GetDialogInfoHtPtr("allRubyOpts");
   RdbgpOptions (*pAllRdbgpOpts):[] = _GetDialogInfoHtPtr("allRdbgpOpts");
   setProjectOptions(projectHandle,configList,*pAllRubyOpts,*pAllRdbgpOpts);

   // Ruby interpreter
   _str rubyExePath = ctl_ruby_exe_path.p_text;
   if( rubyExePath != def_ruby_exe_path ) {
      def_ruby_exe_path = rubyExePath;
      // Flag state file modified
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }

   // Do not shutdown/restart the server if we are in the middle
   // of prompting for environment settings in order to start a
   // debugging session (otherwise you pull the rug/server out
   // from under the rdbgp monitor).
   boolean setting_environment = 0 != _GetDialogInfoHt("setting_environment");
   if( !setting_environment ) {
      // Inform that the project config has changed, which will
      // trigger a server restart, or leave it shut down if
      // listenInBackground=false. Must _post_call this since
      // the project settings are not saved yet.
      _post_call(find_index('_prjconfig_rdbgp',PROC_TYPE));
   }

   // Success
   p_active_form._delete_window(0);
}

void ctl_cancel.lbutton_up()
{
   p_active_form._delete_window("");
}

static void onResizeRunTab(int deltax, int deltay)
{
   // Interpreter arguments
   ctl_interpreter_args.p_width += deltax;
   // Interpreter argument menu button
   ctl_interpreter_arg_button.p_x += deltax;
   // Default file
   ctl_default_file.p_width += deltax;
   // Default file browse button
   ctl_browse_default_file.p_x += deltax;
   // Script arguments
   ctl_script_args.p_width += deltax;
}

static void onResizeRdbgpFrame()
{
}

static void onResizeDebugTab(int deltax, int deltay)
{
   // Debug session frame
   //ctl_debug_session_frame.p_width = childW - ctl_debug_session_frame.p_x - 180;
   //ctl_rdbgp_frame.onResizeDebugSessionFrame();

   // rdbgp server settings frame
   ctl_rdbgp_frame.p_width += deltax;
   ctl_rdbgp_frame.onResizeRdbgpFrame();
}


static void onResizeRemoteMappingsTab(int deltax, int deltay)
{
   // ctl_mappings tree
   ctl_mappings.p_width += deltax;
   ctl_mappings.p_height += deltay;
   // Add, Remove buttons
   ctl_map_remove.p_x += deltax;
   ctl_map_remove.p_y += deltay;
   ctl_map_add.p_x += deltax;
   ctl_map_add.p_y = ctl_map_remove.p_y;
}

static void onResizeOptions(int deltax, int deltay)
{
   onResizeRunTab(deltax, deltay);
   onResizeDebugTab(deltax, deltay);
   onResizeRemoteMappingsTab(deltax, deltay);
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _ruby_options_form_initial_alignment()
{
   // form level
   rightAlign := ctl_current_config.p_x + ctl_current_config.p_width;
   sizeBrowseButtonToTextBox(ctl_ruby_exe_path.p_window_id, ctl_browse_ruby_exe.p_window_id, 0, rightAlign);

   // run tab
   rightAlign = ctl_script_args.p_x + ctl_script_args.p_width;
   sizeBrowseButtonToTextBox(ctl_default_file.p_window_id, ctl_browse_default_file.p_window_id, 0, rightAlign);
   sizeBrowseButtonToTextBox(ctl_interpreter_args.p_window_id, ctl_interpreter_arg_button.p_window_id, 0, rightAlign);
}

void _ruby_options_form.on_resize()
{
   // Enforce sanity on size
   // if the minimum width has not been set, it will return 0
   if (!_minimum_width()) {
      _set_minimum_size(RUBYOPTS_FORM_MINWIDTH, RUBYOPTS_FORM_MINHEIGHT);
   }

   deltax := p_width - (ctl_current_config.p_x + ctl_current_config.p_width + 180);
   deltay := p_height - (ctl_ok.p_y + ctl_ok.p_height + 180);

   // Settings for:
   ctl_current_config.p_width += deltax;
   // OK, Cancel
   ctl_ok.p_y += deltay;
   ctl_cancel.p_y = ctl_ok.p_y;
   // Ruby interpreter:
   ctl_ruby_exe_path.p_width += deltax;
   ctl_ruby_exe_path.p_y += deltay;
   ctl_browse_ruby_exe.p_x += deltax;
   ctl_browse_ruby_exe.p_y += deltay;
   ctl_ruby_exe_path_label.p_y += deltay;

   // Tab control
   ctl_options_tab.p_width += deltax;
   ctl_options_tab.p_height += deltay;
   ctl_options_tab.onResizeOptions(deltax, deltay);
}

_command void rubyoptions(_str options="")
{
   if( _project_name == "" ) {
      // What are we doing here?
      _str msg = "No project. Cannot set options.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return;
   }

   mou_hour_glass(1);
   projectFilesNotNeeded(1);
   int project_prop_wid = show('-hidden -app -xy _project_form',_project_name,_ProjectHandle(_project_name));
   mou_hour_glass(0);
   int ctlbutton_wid = project_prop_wid._find_control('ctlcommand_options');
   typeless result = ctlbutton_wid.call_event('_ruby_options_form 'options,ctlbutton_wid,LBUTTON_UP,'w');
   int ctltooltree_wid = project_prop_wid._find_control('ctlToolTree');
   int status = ctltooltree_wid._TreeSearch(TREE_ROOT_INDEX,'Execute','i');
   if( status < 0 ) {
      _message_box('EXECUTE command not found');
   } else {
      if( result == '' ) {
         int opencancel_wid = project_prop_wid._find_control('_opencancel');
         opencancel_wid.call_event(opencancel_wid,LBUTTON_UP,'w');
      } else {
         int ok_wid = project_prop_wid._find_control('_ok');
         ok_wid.call_event(ok_wid,LBUTTON_UP,'w');
      }
   }
   projectFilesNotNeeded(0);
}
