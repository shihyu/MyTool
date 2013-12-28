////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47587 $
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
#require "se/debug/pydbgp/PydbgpOptions.e"
#import "se/debug/pydbgp/pydbgputil.e"
#import "env.e"
#import "gwt.e"
#import "listbox.e"
#import "main.e"
#import "mprompt.e"
#import "projconv.e"
#import "stdprocs.e"
#import "stdcmds.e"
#import "se/debug/pydbgp/pydbgp.e"
#import "debug.e"
#import "wkspace.e"
#import "project.e"
#import "compile.e"
#require "se/debug/pydbgp/PydbgpConnectionProgressDialog.e"
#import "treeview.e"
#import "guiopen.e"
#import "tbopen.e"
#import "guicd.e"
#import "picture.e"
#import "controls.e"
#import "sstab.e"
#endregion

#define PYDBGP_VERSION "1.1.0-1"
#define GWT_TAB_CAPTION "Google"

using namespace se.debug.pydbgp;

struct PythonOptions {
   // Interpreter arguments
   _str interpreterArgs;
   // Default file to run. If blank then current file is run.
   _str defaultFile;
   // Arguments to script file
   _str scriptArgs;
   // App engine location 
   _str gwtAppEngine;
   // App version 
   _str gwtAppVersion;
   // Port 
   _str gwtPort;
   // ID 
   _str gwtID;
};

static _str getPydbgpDir()
{
   _str resource_dir = get_env('VSROOT');
   _maybe_strip_filesep(resource_dir);
   resource_dir = resource_dir:+FILESEP:+'resource';

   _str tools_dir = resource_dir:+FILESEP:+'tools';

   _str pydbgp_dir = tools_dir:+FILESEP:+'pydbgp-'PYDBGP_VERSION;
   if( !isdirectory(pydbgp_dir) ) {
      return "";
   }
   return pydbgp_dir;
}

static PythonOptions makeDefaultPythonOptions(PythonOptions& python_opts=null)
{
   python_opts.interpreterArgs = "";
   python_opts.defaultFile = "";
   python_opts.scriptArgs = "";
   python_opts.gwtAppEngine = "";
   python_opts.gwtAppVersion = "";
   python_opts.gwtPort = "";
   python_opts.gwtID = "";
   return python_opts;
}

static void getProjectPythonOptionsForConfig(int projectHandle, _str config, PythonOptions& python_opts)
{
   // Guarantee sane values
   PythonOptions default_python_opts;
   makeDefaultPythonOptions(default_python_opts);
   _str interpreterArgs = default_python_opts.interpreterArgs;
   _str defaultFile = default_python_opts.defaultFile;
   _str scriptArgs = default_python_opts.scriptArgs;
   _str gwtAppEngine = default_python_opts.gwtAppEngine;
   _str gwtVersion = default_python_opts.gwtAppVersion;
   _str gwtPort = default_python_opts.gwtPort;
   _str gwtID = default_python_opts.gwtID;

   int node = _ProjectGet_ConfigNode(projectHandle,config);
   if( node >= 0 ) {
      //int opt_node = _xmlcfg_find_simple(projectHandle,"List[@Name='Python Options']",node);
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
      parse cmdline with . '"%(SLICKEDIT_PYTHON_EXE)"' interpreterArgs '%(SLICKEDIT_PYTHON_EXECUTE_ARGS)' rest;
      defaultFile = parse_file(rest);
      interpreterArgs = strip(interpreterArgs);
      defaultFile = strip(strip(defaultFile),'B','"');
      if( defaultFile == '%f' ) {
         defaultFile = "";
      }

      // scriptArgs
      scriptArgs = _ProjectGet_TargetOtherOptions(projectHandle,target_node);

      // gwt specific stuff
      if (_ProjectGet_AppType(projectHandle) == APPTYPE_GWT) {
         if (pos('dev_appserver.py',defaultFile) != 0) {
            gwtAppEngine = _strip_filename(defaultFile,'N');
            if (_charAt(gwtAppEngine,1) == '"') {
               gwtAppEngine = substr(gwtAppEngine,2);
            }
         }
         parse scriptArgs with . '-p ' auto port ' ' .;
         if (isinteger(port)) {
            gwtPort = port;
         }
         _gwt_parseProjectYAMLFile(gwtVersion, gwtID);
      }
   }
   python_opts.interpreterArgs = interpreterArgs;
   python_opts.defaultFile = defaultFile;
   python_opts.scriptArgs = scriptArgs;
   python_opts.gwtAppEngine = gwtAppEngine;
   python_opts.gwtAppVersion = gwtVersion;
   python_opts.gwtPort = gwtPort;
   python_opts.gwtID = gwtID;
}

static void getProjectPythonOptions(int projectHandle, _str (&configList)[], PythonOptions (&python_opts_list):[])
{
   foreach( auto config in configList ) {
      PythonOptions opts;
      getProjectPythonOptionsForConfig(projectHandle,config,opts);
      python_opts_list:[config] = opts;
   }
}

static void setProjectOptionsForConfig(int projectHandle, _str config, PythonOptions& python_opts, PydbgpOptions& pydbgp_opts)
{
   //
   // Execute
   //

   int target_node = _ProjectGet_TargetNode(projectHandle,"Execute",config);
   _str cmdline = '"%(SLICKEDIT_PYTHON_EXE)"';
   if( python_opts.interpreterArgs != "" ) {
      cmdline = cmdline' 'python_opts.interpreterArgs;
   }
   if (_ProjectGet_AppType(projectHandle) == APPTYPE_GWT) {
      _str port = '8080';
      if (python_opts.gwtPort != '' && isinteger(python_opts.gwtPort)) {
         port = python_opts.gwtPort;
      }
      parse python_opts.scriptArgs with auto prefix '-p ' auto portInScript ' .' auto suffix;
      // As long as we can find the '-p PORT .' portion of the scriptArgs, update the port information
      // to reflect what is in the 'Port' field of the Google tab.
      if (isinteger(portInScript)) {
         python_opts.scriptArgs = prefix :+ '-p 'port' .' :+ suffix;
      }
      _gwt_pythonWriteAppInfo(python_opts.gwtAppVersion, python_opts.gwtID);
   } 
   cmdline = cmdline' %(SLICKEDIT_PYTHON_EXECUTE_ARGS)';
   if( python_opts.defaultFile != "" ) {
      cmdline = cmdline" "maybe_quote_filename(python_opts.defaultFile)" %~other";
   } else {
      cmdline = cmdline' "%f" %~other';
   }
   _ProjectSet_TargetCmdLine(projectHandle,target_node,cmdline,"",python_opts.scriptArgs);

   //
   // Deploy (GWT) 
   //
   // update, possibly create DeployScript target here
   if (_ProjectGet_AppType(projectHandle) == APPTYPE_GWT) {
      _str deployScript = python_opts.gwtAppEngine;
      _maybe_append_filesep(deployScript);
      deployScript :+= 'appcfg.py';
      int deployNode = _ProjectGet_TargetNode(projectHandle,"DeployScript",config);
      if (deployNode >= 0) {
         _ProjectSet_TargetCmdLine(projectHandle,deployNode,maybe_quote_filename(deployScript));
      } else {
         _ProjectAdd_Target(projectHandle,'DeployScript',maybe_quote_filename(deployScript),'',config,"Never","");
      }
      _ProjectSave(projectHandle);
   }

   //
   // Debug
   //

   //target_node = _ProjectGet_TargetNode(projectHandle,"Debug",config);
   //_ProjectSet_TargetCmdLine(projectHandle,target_node,"python_debug","Slick-C");

   //
   // Python Options, pydbgp Options
   //

   int config_node = _ProjectGet_ConfigNode(projectHandle,config);

   //
   // Python Options
   //

   int opt_node = _xmlcfg_find_simple(projectHandle,"List[@Name='Python Options']",config_node);

   // Clear out old options
   if( opt_node >= 0 ) {
      _xmlcfg_delete(projectHandle,opt_node,false);
   }
   opt_node = _xmlcfg_add(projectHandle,config_node,VPJTAG_LIST,VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add_attribute(projectHandle,opt_node,"Name","Python Options",0);

   //// DefaultFile
   //int node = _xmlcfg_add(projectHandle,opt_node,VPJTAG_ITEM,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   //_xmlcfg_add_attribute(projectHandle,node,"Name","DefaultFile",0);
   //_xmlcfg_add_attribute(projectHandle,node,"Value",python_opts.defaultFile,0);

   //
   // pydbgp Options
   //

   opt_node = _xmlcfg_find_simple(projectHandle,"List[@Name='pydbgp Options']",config_node);

   // Clear out old options
   if( opt_node >= 0 ) {
      _xmlcfg_delete(projectHandle,opt_node,false);
   }
   opt_node = _xmlcfg_add(projectHandle,config_node,VPJTAG_LIST,VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add_attribute(projectHandle,opt_node,"Name","pydbgp Options",0);

   // ServerHost
   int node = _xmlcfg_add(projectHandle,opt_node,VPJTAG_ITEM,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add_attribute(projectHandle,node,"Name","ServerHost",0);
   _xmlcfg_add_attribute(projectHandle,node,"Value",pydbgp_opts.serverHost,0);

   // ServerPort
   node = _xmlcfg_add(projectHandle,opt_node,VPJTAG_ITEM,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add_attribute(projectHandle,node,"Name","ServerPort",0);
   _xmlcfg_add_attribute(projectHandle,node,"Value",pydbgp_opts.serverPort,0);

   // ListenInBackground
   node = _xmlcfg_add(projectHandle,opt_node,VPJTAG_ITEM,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add_attribute(projectHandle,node,"Name","ListenInBackground",0);
   _xmlcfg_add_attribute(projectHandle,node,"Value",(int)pydbgp_opts.listenInBackground,0);

   // Remote Mappings
   PydbgpRemoteFileMapping remote_file_map;
   foreach( remote_file_map in pydbgp_opts.remoteFileMap ) {
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
   node = _xmlcfg_add(projectHandle,opt_node,VPJTAG_ITEM,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add_attribute(projectHandle,node,"Name","show_hidden",0);
   _xmlcfg_add_attribute(projectHandle,node,"Value",(int)pydbgp_opts.dbgp_features.show_hidden,0);
}

static void setProjectOptions(int projectHandle, _str (&configList)[], PythonOptions (&python_opts_list):[], PydbgpOptions (&pydbgp_opts_list):[])
{
   foreach( auto config in configList ) {
      setProjectOptionsForConfig(projectHandle,config,python_opts_list:[config],pydbgp_opts_list:[config]);
   }
}

static _str guessPythonExePath()
{
   if( def_python_exe_path != "" ) {
      // No guessing necessary
      return def_python_exe_path;
   }
   _str exePath = path_search("python"EXTENSION_EXE);
   return exePath;
}

/**
 * Callback called from _project_command to prepare the 
 * environment for running python command-line interpreter. The 
 * value found in def_python_exe_path takes precedence. If not 
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
int _python_set_environment(int projectHandle=-1, _str config="", _str target="",
                            boolean quiet=false, _str& error_hint=null)
{
   if( _project_name == "" ) {
      return 0;
   }

   target = lowcase(target);
   if( target == "python options" ) {
      // If user selects Build>Python Options tool then the Python Options dialog could
      // come up twice if the Python interpreter is not set. This would
      // happen because _project_command() calls us before executing any tool
      // in order to get the environment set up.
      return 0;
   }

   // Help for the user in case of error
   error_hint = "Set the Python interpreter (\"Build\",\"Python Options\").";

   if( projectHandle < 0 ) {
      _ProjectGet_ActiveConfigOrExt(_project_name,projectHandle,config);
   }

   boolean isPythonProject = ( strieq("python",_ProjectGet_Type(projectHandle,config)) );

   // Restore the original environment. This is done so the
   // path for python.exe is not appended over and over.
   _restore_origenv(true);

   _str pythonExePath = "";
   if( def_python_exe_path != "" ) {
      // Use def_python_exe_path
      pythonExePath = def_python_exe_path;
   } else {
      if( !isPythonProject ) {
         // Prompt user for interpreter
         int status = _mdi.textBoxDialog("Python Interpreter",
                                         0,
                                         0,
                                         "",
                                         "OK,Cancel:_cancel\tSet the Python interpreter so the program can be found. \nSpecify the path to 'python"EXTENSION_EXE"'.",  // Button List
                                         "",
                                         "-bf Python interpreter:":+guessPythonExePath());
         if( status < 0 ) {
            // Probably COMMAND_CANCELLED_RC
            return status;
         }

         // Save the values entered and mark the configuration as modified
         def_python_exe_path = _param1;
         _config_modify_flags(CFGMODIFY_DEFVAR);
         pythonExePath = def_python_exe_path;
      } else {
         // Show Python Options dialog and let user set it from there
         pythonoptions('-setting-environment');
         pythonExePath = def_python_exe_path;
      }
   }

   // Make sure we got a path
   if( pythonExePath == "" ) {
      return COMMAND_CANCELLED_RC;
   }

   // Set the environment
   set_env('SLICKEDIT_PYTHON_EXE',pythonExePath);
   _str pythonDir = _strip_filename(pythonExePath,'N');
   _maybe_strip_filesep(pythonDir);
   // PATH
   _str path = _replace_envvars("%PATH%");
   _maybe_prepend(path,PATHSEP);
   path = pythonDir:+path;
   set("PATH="path);

   // Success
   return 0;
}

/**
 * Prepares the environment for running python command-line 
 * interpreter. 
 *
 * @return 0 on success, <0 on error.
 */
_command int set_python_environment()
{
   int status = _python_set_environment();
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
_str _python_parse_project_command(_str command,
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
      PythonOptions python_opts;
      getProjectPythonOptionsForConfig(handle,config,python_opts);
   
      // We are only interested in inspecting the command if the user has
      // specified to use the current buffer. We assume that if they specified
      // a DefaultFile in Options that they know what they are doing.
      if( python_opts.defaultFile == "" && pos('%f',command) && buf_name != "" ) {
         // Validate buffer name
         _str langId = _Filename2LangId(buf_name);
         if( langId != 'py' ) {
            _str msg = nls('"%s" does not appear to be a runnable script.',buf_name);
            msg = msg"\n\nContinue to execute this script?";
            msg = msg"\n\n"'Note: You can choose a default script to run from the Options dialog ("Build", "Python Options")';
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
int _python_project_command_status(int projectHandle, _str config,
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
   // it has executed a target that returns void (e.g. 'pythonoptions').
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

   if( _project_DebugCallbackName != "pydbgp" ) {
      // Not an Pydbgp debugger project. Nothing wrong with that, but
      // we cannot do anything with it.
      return 0;
   }

   int status = 0;

   do {

      // Assemble debugger_args
      _str debugger_args = "";
      debugger_args = debugger_args' -socket='socket_or_status;
      // Pass the project remote-directory <=> local-directory mappings
      PythonOptions python_opts;
      getProjectPythonOptionsForConfig(projectHandle,config,python_opts);
      PydbgpOptions pydbgp_opts;
      pydbgp_project_get_options_for_config(projectHandle,config,pydbgp_opts);
      PydbgpRemoteFileMapping map;
      foreach( map in pydbgp_opts.remoteFileMap ) {
         if( map.remoteRoot != "" && map.localRoot != "" ) {
            debugger_args = debugger_args' -map='map.remoteRoot':::'map.localRoot;
         }
      }
      // DBGp features
      debugger_args = debugger_args' -feature-set=show_hidden='pydbgp_opts.dbgp_features.show_hidden;
   
      // Attempt to start debug session
      status = debug_begin("pydbgp","","","",def_debug_timeout,null,debugger_args);

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
_command int python_debug()
{
   if( _project_name == "" ) {
      // What are we doing here?
      _str msg = "No project. Cannot debug.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return INVALID_ARGUMENT_RC;
   }

   if( _project_DebugCallbackName != "pydbgp" ) {
      // What are we doing here?
      _str msg = "Project does not support pydbgp. Cannot debug.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return INVALID_ARGUMENT_RC;
   }

   PydbgpOptions pydbgp_opts;
   pydbgp_project_get_options_for_config(_ProjectHandle(),GetCurrentConfigName(),pydbgp_opts);
   if( pydbgp_opts.serverHost == "" || pydbgp_opts.serverPort == "" ) {
      _str msg = "Invalid pydbgp parameters. Cannot debug.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return INVALID_ARGUMENT_RC;
   }

   int status_or_socket = 0;

   // We do not want the possiblility of the passive connection monitor
   // attempting to start a debug session right in the middle of things
   // because it also recognized a pending connection. That would get
   // very confusing.
   int old_almost_active = (int)pydbgp_almost_active();
   pydbgp_almost_active(1);

   do {

      boolean already_listening = pydbgp_is_listening(pydbgp_opts.serverHost,pydbgp_opts.serverPort);
      if( !already_listening || !pydbgp_is_pending(pydbgp_opts.serverHost,pydbgp_opts.serverPort) ) {
   
         // Must EXECUTE and listen for resulting connection from debugger engine

         _str pydbgp_dir = getPydbgpDir();
         if( pydbgp_dir == "" ) {
            _str msg = "Could not find pydbgp directory. Cannot start debugger.";
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            status_or_socket = PATH_NOT_FOUND_RC;
            break;
         }

         if( !already_listening ) {
            // Must provision a one-shot server before EXECUTE, otherwise pydbgp will fail
            // the connection test to us.
            pydbgp_watch(pydbgp_opts.serverHost,pydbgp_opts.serverPort);
         }

         // Note:
         // Cygwin python.exe not supported.
         // Cygwin python.exe cannot deal with path arguments (e.g. the debugee)
         // that are not Cygwin-ized. We would have to cygwin-ize the script passed
         // into pydbgp.py and PYTHONPATH environment variable value. We can deal with
         // the path to 'pydbgp.py' here, but we have no control over the script that
         // project_execute() will run.

         // Get the actual host:port the server is listening on.
         // This is necessary since the user may have elected to use a
         // dynamically allocated port and we need to pass the actual
         // listener address to pydbgp.py.
         _str host = pydbgp_opts.serverHost;
         _str port = pydbgp_opts.serverPort;
         pydbgp_get_server_address(host,port);

         _str pydbgp_exe = maybe_quote_filename(pydbgp_dir'/bin/pydbgp_bootstrapper.py');
         // -S : Do not 'import site' on initialization because it can mess with pydbgp.pl
         // -u : Unbuffered binary stdout/stderr allows Build window to print output as-it-comes
         _str pydbgp_cmdline = '-S -u 'pydbgp_exe' -d 'host':'port' -k slickedit';
         //say('python_debug: pydbgp_cmdline='pydbgp_cmdline);

         _str old_args = get_env("SLICKEDIT_PYTHON_EXECUTE_ARGS");
         if( old_args == "" && rc == STRING_NOT_FOUND_RC ) {
            old_args = null;
         }
         set_env("SLICKEDIT_PYTHON_EXECUTE_ARGS",pydbgp_cmdline);
         // Note: We are appending to the end of PYTHONPATH, so it does
         // no harm to leave PYTHONPATH modified since it only contains
         // subbdirectories with debug-specific modules. Besides, attempting
         // to set the directory back on UNIX causes a big delay when starting
         // a debug session since loop_until_on_last_process_buffer_command()
         // waits for the .process buffer prompt to become available before
         // allowing debugging to begin.
         _str pythonpath = get_env("PYTHONPATH");
         if( 0 == pos(PATHSEP:+pydbgp_dir,pythonpath,1,'e') ) {
            set("PYTHONPATH="get_env("PYTHONPATH"):+PATHSEP:+pydbgp_dir);
         }
         int override_flags = 0;
#if !__UNIX__
         // Force script to be shelled to console
         //override_flags |= OVERRIDE_CAPTUREOUTPUTWITH_PROCESSBUFFER;
#endif
         status_or_socket = (int)_project_command2('execute',false,false,override_flags);
         //set("PYTHONPATH="old_pythonpath);
         set_env("SLICKEDIT_PYTHON_EXECUTE_ARGS",old_args);

         if( status_or_socket != 0 ) {
            // Error. project_execute should have taken care of displaying any message.
            if( !already_listening ) {
               // Clean up the one-shot server we created
               pydbgp_shutdown(pydbgp_opts.serverHost,pydbgp_opts.serverPort);
            }
            break;
         }
         // Fall through to actively waiting for connection
      }
   
      se.debug.pydbgp.PydbgpConnectionProgressDialog dlg;
      int timeout = 1000*def_debug_timeout;
      status_or_socket = pydbgp_wait_and_accept(pydbgp_opts.serverHost,pydbgp_opts.serverPort,timeout,&dlg,false);

      if( !already_listening ) {
         // Clean up the one-shot server we created
         pydbgp_shutdown(pydbgp_opts.serverHost,pydbgp_opts.serverPort);
      } else {
         if( status_or_socket < 0 ) {
            // Error. Was it serious?
            if( status_or_socket != COMMAND_CANCELLED_RC && status_or_socket != SOCK_TIMED_OUT_RC ) {
               _str msg = "You just failed to accept a connection from pydbgp. The error was:\n\n" :+
                          get_message(status_or_socket)" ("status_or_socket")\n\n" :+
                          "Would you like to stop listening for a connection?";
               int result = _message_box(msg,"",MB_YESNO|MB_ICONQUESTION);
               if( result == IDYES ) {
                  pydbgp_shutdown(pydbgp_opts.serverHost,pydbgp_opts.serverPort);
                  sticky_message(nls("Server listening at %s:%s has been shut down.",pydbgp_opts.serverHost,pydbgp_opts.serverPort));
               } else {
                  // Clear the last error, so the watch timer does not pick
                  // it up and throw up on the user a second time.
                  pydbgp_clear_last_error(pydbgp_opts.serverHost,pydbgp_opts.serverPort);
               }
            } else {
               // Clear the last error, so the watch timer does not pick
               // it up and throw up on the user a second time.
               pydbgp_clear_last_error(pydbgp_opts.serverHost,pydbgp_opts.serverPort);
            }
         }

         // Note: The server takes care of resuming any previous watch
      }
      //say('python_debug: h1 - status_or_socket='status_or_socket);

   } while( false );

   pydbgp_almost_active(old_almost_active);

   return status_or_socket;
}

#define PYTHONOPTS_FORM_MINWIDTH  8175
#define PYTHONOPTS_FORM_MINHEIGHT 7950

defeventtab _python_options_form;

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _python_options_form_initial_alignment()
{
   // form level
   rightAlign := ctl_current_config.p_x + ctl_current_config.p_width;
   sizeBrowseButtonToTextBox(ctl_python_exe_path.p_window_id, ctl_browse_python_exe.p_window_id, 0, rightAlign);

   // run tab
   rightAlign = ctl_script_args.p_x + ctl_script_args.p_width;
   sizeBrowseButtonToTextBox(ctl_default_file.p_window_id, ctl_browse_default_file.p_window_id, 0, rightAlign);
   sizeBrowseButtonToTextBox(ctl_interpreter_args.p_window_id, ctl_interpreter_arg_button.p_window_id, 0, rightAlign);

   // google tab
   sizeBrowseButtonToTextBox(ctl_appengine_loc.p_window_id, ctl_appengine_browse.p_window_id);
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

static void getFormOptions(PythonOptions& python_opts, PydbgpOptions& pydbgp_opts)
{

   // Do we have the Google tab?
   boolean hasGoogleTab = ctl_options_tab.sstTabExists(GWT_TAB_CAPTION);

   makeDefaultPythonOptions(python_opts);

   //
   // Run tab
   //

   // Interpreter arguments
   python_opts.interpreterArgs = ctl_interpreter_args.p_text;
   // Default file
   python_opts.defaultFile = ctl_default_file.p_text;
   // Script arguments
   python_opts.scriptArgs = ctl_script_args.p_text;

   //
   // Debug tab
   //

   pydbgp_opts.serverHost = ctl_server_host.p_text;
   if( ctl_default_port.p_value ) {
      pydbgp_opts.serverPort = "0";
   } else {
      pydbgp_opts.serverPort = ctl_server_port.p_text;
   }
   pydbgp_opts.listenInBackground = (ctl_listen_on_startup.p_value != 0);
   // DBGp features
   pydbgp_opts.dbgp_features.show_hidden = (ctl_show_hidden.p_value != 0);

   //
   // Remote Mappings tab
   //

   pydbgp_opts.remoteFileMap._makeempty();
   int index = ctl_mappings._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while( index >= 0 ) {
      _str mapline = ctl_mappings._TreeGetCaption(index);
      _str localRoot="";
      _str remoteRoot="";
      parse mapline with remoteRoot"\t"localRoot;
      int i = pydbgp_opts.remoteFileMap._length();
      pydbgp_opts.remoteFileMap[i].localRoot = localRoot;
      pydbgp_opts.remoteFileMap[i].remoteRoot = remoteRoot;
      index = ctl_mappings._TreeGetNextSiblingIndex(index);
   }

   //
   // Google tab
   //

   if (hasGoogleTab) {
      python_opts.gwtAppEngine = ctl_appengine_loc.p_text;
      python_opts.gwtAppVersion = ctl_version.p_text;
      python_opts.gwtPort = ctl_port.p_text;
      python_opts.gwtID = ctl_id.p_text;
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

static boolean validateFormOptions(PythonOptions& python_opts, PydbgpOptions& pydbgp_opts)
{
   getFormOptions(python_opts,pydbgp_opts);

   // Used to flag duplicate remote-to-local mappings
   int remote2local_dup_set:[] = null;

   int i, n=pydbgp_opts.remoteFileMap._length();
   for( i=0; i < n; ++i ) {

      // Remote root is the pivot, so we should never have an empty remote-root-directory entry
      _str remoteRoot = pydbgp_opts.remoteFileMap[i].remoteRoot;
      if( remoteRoot == "" ) {
         // Park the user on the problem
         _str msg = nls("Missing remote directory.");
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         ctl_options_tab.sstActivateTabByCaption("Remote Mappings");
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
         ctl_options_tab.sstActivateTabByCaption("Remote Mappings");
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
      _str localRoot = pydbgp_opts.remoteFileMap[i].localRoot;
      if( localRoot == "" || !isdirectory(localRoot) ) {
         // Park the user on the problem
         _str msg = "";
         if( remoteRoot == "" ) {
            msg = nls("Missing local directory.");
         } else {
            msg = nls("Invalid local directory '%s'.",localRoot);
         }
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         ctl_options_tab.sstActivateTabByCaption("Remote Mappings");
         p_window_id = ctl_mappings;
         _set_focus();
         selectMapping(i+1);
         return false;
      }

   }

   if( pydbgp_opts.serverHost == "" ) {
      _str msg = "Invalid/missing pydbgp host";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      ctl_options_tab.sstActivateTabByCaption("Debug");
      p_window_id = ctl_server_host;
      _set_sel(1,length(p_text)+1);
      _set_focus();
      return false;
   }
   if( pydbgp_opts.serverPort == "0" ) {
      // Dynamic port is okay
   } else if( pydbgp_opts.serverPort == "" || vssServiceNameToPort(pydbgp_opts.serverPort) < 0 ) {
      _str msg = "Invalid/missing pydbgp port";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      ctl_options_tab.sstActivateTabByCaption("Debug");
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
                                     PythonOptions (&all_python_opts):[],
                                     PythonOptions& default_python_opts,
                                     PydbgpOptions (&all_pydbgp_opts):[],
                                     PydbgpOptions& default_pydbgp_opts)
{
   if( default_python_opts == null ) {
      // Fall back to generic default options
      makeDefaultPythonOptions(default_python_opts);
   }
   PythonOptions python_opts = null;
   if( default_pydbgp_opts == null ) {
      // Fall back to generic default options
      pydbgp_make_default_options(default_pydbgp_opts);
   }
   PydbgpOptions pydbgp_opts = null;

   if( config == ALL_CONFIGS ) {
      // If options do not match across all configs, then use default options instead
      python_opts = default_python_opts;
      pydbgp_opts = default_pydbgp_opts;
      _str last_cfg;
      _str cfg;

      // python_opts
      last_cfg = "";
      foreach( cfg=>. in all_python_opts ) {
         if( last_cfg != "" ) {
            if( all_python_opts:[last_cfg] != all_python_opts:[cfg] ) {
               // No match, so use default options
               python_opts = default_python_opts;
               break;
            }
         }
         // Match (or first config)
         python_opts = all_python_opts:[cfg];
         last_cfg = cfg;
      }

      // pydbgp_opts
      last_cfg = "";
      foreach( cfg=>. in all_pydbgp_opts ) {
         if( last_cfg != "" ) {
            if( all_pydbgp_opts:[last_cfg] != all_pydbgp_opts:[cfg] ) {
               // No match, so use default options
               pydbgp_opts = default_pydbgp_opts;
               break;
            }
         }
         // Match (or first config)
         pydbgp_opts = all_pydbgp_opts:[cfg];
         last_cfg = cfg;
      }
   } else {
      python_opts = all_python_opts:[config];
      pydbgp_opts = all_pydbgp_opts:[config];
   }

   // Do we have the Google tab?
   boolean hasGoogleTab = ctl_options_tab.sstTabExists(GWT_TAB_CAPTION);

   //
   // Run tab
   //

   // Interpreter arguments
   ctl_interpreter_args.p_text = python_opts.interpreterArgs;
   // Default file
   ctl_default_file.p_text = python_opts.defaultFile;
   // Script arguments
   ctl_script_args.p_text = python_opts.scriptArgs;

   //
   // Debug tab
   //

   // Local host
   ctl_server_host.p_text = pydbgp_opts.serverHost;
   // Local port
   if( pydbgp_opts.serverPort == "0" || pydbgp_opts.serverPort == "" ) {
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
      ctl_server_port.p_text = pydbgp_opts.serverPort;
   }
   ctl_default_port.call_event(ctl_default_port,LBUTTON_UP,'w');
   // Listen on startup
   ctl_listen_on_startup.p_value = (int)pydbgp_opts.listenInBackground;
   // DBGp features
   ctl_show_hidden.p_value = (int)pydbgp_opts.dbgp_features.show_hidden;

   //
   // Remote Mappings tab
   //

   resetMappingsTree();
   int i, n=pydbgp_opts.remoteFileMap._length();
   for( i=0; i < n; ++i ) {
      _str mapline = pydbgp_opts.remoteFileMap[i].remoteRoot"\t"pydbgp_opts.remoteFileMap[i].localRoot;
      int index = ctl_mappings._TreeAddItem(TREE_ROOT_INDEX,mapline,TREE_ADD_AS_CHILD,0,0,-1);
   }

   //
   // Google tab
   //

   if (hasGoogleTab) {
      ctl_appengine_loc.p_text = python_opts.gwtAppEngine;
      ctl_version.p_text = python_opts.gwtAppVersion;
      ctl_port.p_text = python_opts.gwtPort;
      ctl_id.p_text = python_opts.gwtID;
   }
}

static void savePythonOptionsForConfig(_str config, PythonOptions& python_opts, PythonOptions (&all_python_opts):[])
{
   // Gather up all affected config names
   _str configIndices[] = null;
   if( config == ALL_CONFIGS ) {
      // All configurations get the same settings
      _str cfg;
      foreach( cfg=>. in all_python_opts ) {
         configIndices[configIndices._length()] = cfg;
      }
   } else {
      configIndices[0] = config;
   }

   // Now save options for affected configs
   int i;
   for( i=0; i < configIndices._length(); ++i ) {
      _str cfg = configIndices[i];
      all_python_opts:[cfg] = python_opts;
   }
}

static void savePydbgpOptionsForConfig(_str config, PydbgpOptions& pydbgp_opts, PydbgpOptions (&all_pydbgp_opts):[])
{
   // Gather up all affected config names
   _str configIndices[];
   if( config == ALL_CONFIGS ) {
      // All configurations get the same settings
      _str cfg;
      foreach( cfg=>. in all_pydbgp_opts ) {
         configIndices[configIndices._length()] = cfg;
      }
   } else {
      configIndices[0] = config;
   }

   // Now save options for affected configs
   int i;
   for( i=0; i < configIndices._length(); ++i ) {
      _str cfg = configIndices[i];
      all_pydbgp_opts:[cfg] = pydbgp_opts;
   }
}

static boolean changeCurrentConfig(_str config)
{
   boolean success = false;

   int old_changing_config = (int)changingCurrentConfig(1);

   do {

      _str lastConfig = _GetDialogInfoHt("lastConfig");
      PythonOptions python_opts;
      PydbgpOptions pydbgp_opts;
      if( !validateFormOptions(python_opts,pydbgp_opts) ) {
         // Bad options
         break;
      }
   
      // All good, save these settings
      PythonOptions (*pAllPythonOpts):[] = _GetDialogInfoHtPtr("allPythonOpts");
      PydbgpOptions (*pAllPydbgpOpts):[] = _GetDialogInfoHtPtr("allPydbgpOpts");
      savePythonOptionsForConfig(lastConfig,python_opts,*pAllPythonOpts);
      savePydbgpOptionsForConfig(lastConfig,pydbgp_opts,*pAllPydbgpOpts);
   
      // Set form options for new config.
      // "All Configurations" case:
      // If switching to "All Configurations" and configs do not match, then use
      // last options for the default. This is better than blasting the user's
      // settings completely with generic default options.
      lastConfig = config;
      _SetDialogInfoHt("lastConfig",lastConfig);
      setFormOptionsFromConfig(lastConfig,
                               *pAllPythonOpts,python_opts,
                               *pAllPydbgpOpts,pydbgp_opts);
      success = true;

   } while( false );

   changingCurrentConfig(old_changing_config);

   return success;
}

void ctl_current_config.on_change(int reason)
{
   maybeDisableGoogleTab();

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
   _str wildCards = "*.py";
   _str format_list = "";
   parse def_file_types with 'Python Files' +0 format_list',';
   if( format_list == "" ) {
      // Fall back
      format_list = "Python Files (*.py)";
   }

   // Try to be smart about the initial directory
   int projectHandle = _GetDialogInfoHt("projectHandle");
   _str init_dir = _ProjectGet_WorkingDir(projectHandle);

   _str result = _OpenDialog("-modal",
                             "Default File",
                             wildCards,
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

static void selectInterpreterArgMenu()
{
   int index = find_index("_temp_interpreter_arg_menu",oi2type(OI_MENU));
   if( index > 0 ) {
      delete_name(index);
   }
   index = insert_name("_temp_interpreter_arg_menu",oi2type(OI_MENU));
   _str caption;
   _menu_insert(index,-1,0,"Ignore PYTHON* &environment variables",'ctlinsert -E ');
   _menu_insert(index,-1,0,"&Optimize generated bytecode slightly",'ctlinsert -O ');
   _menu_insert(index,-1,0,"Don't imply 'import &site' on initialization",'ctlinsert -S ');
   _menu_insert(index,-1,0,"&Unbuffered binary stdout and stderr",'ctlinsert -u ');
   int menu_handle = p_active_form._menu_load(index,'P');
   // Show the menu
   int x = 100;
   int y = 100;
   x = mou_last_x('M') - x;
   y = mou_last_y('M') - y;
   _lxy2dxy(p_scale_mode,x,y);
   _map_xy(p_window_id,0,x,y,SM_PIXEL);
   int flags = VPM_LEFTALIGN|VPM_RIGHTBUTTON;
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

void ctl_browse_python_exe.lbutton_up()
{
#if __UNIX__
   _str wildcards = "";
#else
   _str wildcards = "Executable Files (*.exe;*.com;*.bat;*.cmd)";
#endif
   _str format_list = wildcards;

   // Try to be smart about the initial filename directory
   _str init_dir = "";
   _str init_filename = ctl_python_exe_path.p_text;
   if( init_filename == "" ) {
      init_filename = guessPythonExePath();
   }
   if( init_filename != "" ) {
      // Strip off the 'python' exe to leave the directory
      init_dir = _strip_filename(init_filename,'N');
      _maybe_strip_filesep(init_dir);
      // Strip directory off 'php' exe to leave filename-only
      init_filename = _strip_filename(init_filename,'P');
   }

   _str result = _OpenDialog("-modal",
                             "Python Interpreter",
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
   ctl_pydbgp_note.p_backcolor = 0x80000022;
#endif

   // Get rid of scrollbars if possible
   ctl_pydbgp_note._minihtml_ShrinkToFit();
}

static void onCreateRemoteMappingsTab()
{
   // Mappings tree
   int col_width = ctl_mappings.p_width intdiv 2;
   int remain_width = ctl_mappings.p_width - 2*col_width;
   int wid=p_window_id;
   p_window_id=ctl_mappings;
   _TreeSetColButtonInfo(0,col_width,0,-1,"Remote Directory");
   _TreeSetColButtonInfo(1,col_width+remain_width,0,-1,"Local Directory");
   _TreeSetColEditStyle(0,TREE_EDIT_TEXTBOX);
   _TreeSetColEditStyle(1,TREE_EDIT_TEXTBOX);
   p_window_id=wid;

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

   _python_options_form_initial_alignment();

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
      if( strieq(_ProjectGet_Type(projectHandle,configList[i]),"python") ) {
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

   PythonOptions allPythonOpts:[] = null;
   PydbgpOptions allPydbgpOpts:[] = null;
   getProjectPythonOptions(projectHandle,configList,allPythonOpts);
   pydbgp_project_get_options(projectHandle,configList,allPydbgpOpts);

   _SetDialogInfoHt("configList",configList);
   _SetDialogInfoHt("lastConfig",lastConfig);
   _SetDialogInfoHt("allPythonOpts",allPythonOpts);
   _SetDialogInfoHt("allPydbgpOpts",allPydbgpOpts);

   // Initialize form with options.
   // Note: Cannot simply call ctl_current_config.ON_CHANGE because
   // we do not want initial values validated (they might not be valid).
   // Note: It is not possible (through the GUI) to bring up the
   // options dialog without at least 1 configuration.
   setFormOptionsFromConfig(lastConfig,
                            allPythonOpts,allPythonOpts:[ configList[0] ],
                            allPydbgpOpts,allPydbgpOpts:[ configList[0] ]);
   ctl_python_exe_path.p_text = guessPythonExePath();

   if( tabName == "" ) {
      ctl_options_tab._retrieve_value();
   } else {
      // Select the proper tab
      ctl_options_tab.sstActivateTabByCaption(tabName);
   }
}

void _python_options_form.on_load()
{
   boolean setting_environment = 0 != _GetDialogInfoHt("setting_environment");

   if( setting_environment ) {
      _str pythonExePath = ctl_python_exe_path.p_text;
      _str msg = "";
      if( pythonExePath != "" ) {
         msg = "Warning: The Python interpreter has been automatically found for this project.";
         msg = msg :+ "\n\nPlease verify the Python interpreter is correct on the Options dialog that follows (\"Build\", \"Python Options\").";
      } else {
         msg = "Warning: The Python interpreter is not set for this project.";
         msg = msg :+ "Please set the Python interpreter on the Options dialog that follows (\"Build\", \"Python Options\").";
      }
      p_window_id = ctl_python_exe_path;
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
   PythonOptions (*pAllPythonOpts):[] = _GetDialogInfoHtPtr("allPythonOpts");
   PydbgpOptions (*pAllPydbgpOpts):[] = _GetDialogInfoHtPtr("allPydbgpOpts");
   setProjectOptions(projectHandle,configList,*pAllPythonOpts,*pAllPydbgpOpts);

   // Python interpreter
   _str pythonExePath = ctl_python_exe_path.p_text;
   if( pythonExePath != def_python_exe_path ) {
      def_python_exe_path = pythonExePath;
      // Flag state file modified
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }

   // Do not shutdown/restart the server if we are in the middle
   // of prompting for environment settings in order to start a
   // debugging session (otherwise you pull the rug/server out
   // from under the pydbgp monitor).
   boolean setting_environment = 0 != _GetDialogInfoHt("setting_environment");
   if( !setting_environment ) {
      // Inform that the project config has changed, which will
      // trigger a server restart, or leave it shut down if
      // listenInBackground=false. Must _post_call this since
      // the project settings are not saved yet.
      _post_call(find_index('_prjconfig_pydbgp',PROC_TYPE));
   }

   // Success
   p_active_form._delete_window(0);
}

void ctl_cancel.lbutton_up()
{
   p_active_form._delete_window("");
}

static void onResizeGoogleTab(int deltax, int deltay)
{
   // App engine location 
   ctl_appengine_loc.p_width += deltax;
   // App engine location browse button 
   ctl_appengine_browse.p_x += deltax;
   // Version
   ctl_version.p_width += deltax;
   // Port
   ctl_port.p_width += deltax;
   // ID  
   ctl_id.p_width += deltax;
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

static void onResizeDebugSessionFrame()
{
}

static void onResizePydbgpFrame()
{
}

static void onResizeDebugTab(int deltax, int deltay)
{
   // Debug session frame
   ctl_debug_session_frame.p_width += deltax;
   ctl_pydbgp_frame.onResizeDebugSessionFrame();

   // Pydbgp server settings frame
   ctl_pydbgp_frame.p_width += deltax;
   ctl_pydbgp_frame.onResizePydbgpFrame();
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

static void onResizeOptions(int deltax, int deltay, boolean hasGoogleTab=false)
{
   onResizeRunTab(deltax, deltay);
   onResizeDebugTab(deltax, deltay);
   onResizeRemoteMappingsTab(deltax, deltay);
   if (hasGoogleTab) {
      onResizeGoogleTab(deltax, deltay);
   }
}

void _python_options_form.on_resize()
{
   // Enforce sanity on size
   // if the minimum width has not been set, it will return 0
   if (!_minimum_width()) {
      _set_minimum_size(PYTHONOPTS_FORM_MINWIDTH, PYTHONOPTS_FORM_MINHEIGHT);
   }

   boolean hasGoogleTab = ctl_options_tab.sstTabExists(GWT_TAB_CAPTION);

   deltax := p_width - (ctl_current_config.p_x + ctl_current_config.p_width + 180);
   deltay := p_height - (ctl_ok.p_y + ctl_ok.p_height + 180);

   // Settings for:
   ctl_current_config.p_width += deltax;
   // OK, Cancel
   ctl_ok.p_y += deltay;
   ctl_cancel.p_y = ctl_ok.p_y;
   // Python interpreter:
   ctl_python_exe_path.p_width += deltax;
   ctl_python_exe_path.p_y += deltay;
   ctl_browse_python_exe.p_x += deltax;
   ctl_browse_python_exe.p_y += deltay;
   ctl_python_exe_path_label.p_y += deltay;

   // Tab control
   ctl_options_tab.p_width += deltax;
   ctl_options_tab.p_height += deltay;
   ctl_options_tab.onResizeOptions(deltax, deltay, hasGoogleTab);

}

static void maybeDisableGoogleTab()
{
   int projectHandle = _GetDialogInfoHt("projectHandle");
   _str configList[];
   boolean isGwt = false;
   _ProjectGet_ConfigNames(projectHandle,configList);
   if (p_text==ALL_CONFIGS) {
      int i;
      for (i=0;i<configList._length();++i) {
         _str AppType=_ProjectGet_AppType(projectHandle,configList[i]);
         if (strieq(AppType,APPTYPE_GWT)) {
            isGwt=true;
         }
      }
   } else {
      _str AppType=_ProjectGet_AppType(projectHandle,p_text);
      if (strieq(AppType,APPTYPE_GWT)) {
         isGwt=true;
      }
   }

   if( !isGwt ) {
      int wid = p_window_id;
      p_window_id = ctl_options_tab;
      int OldActiveTab = p_ActiveTab;
      if( sstActivateTabByCaption(GWT_TAB_CAPTION) ) {
         int newActiveTab = p_ActiveTab;
         _deleteActive();
         p_window_id = p_parent;
         if( newActiveTab != OldActiveTab ) {
            p_ActiveTab = OldActiveTab;
         }
      }
      p_window_id=wid;
   }

}

_command void pythonoptions(_str options="")
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
   typeless result = ctlbutton_wid.call_event('_python_options_form 'options,ctlbutton_wid,LBUTTON_UP,'w');
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
