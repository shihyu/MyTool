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
#include "tagsdb.sh"
#include "rte.sh"
#import "se/debug/pydbgp/pydbgputil.e"
#require "se/debug/dbgp/DBGpOptions.e"
#import "debuggui.e"
#import "dir.e"
#import "context.e"
#import "env.e"
#import "gwt.e"
#import "help.e"
#import "listbox.e"
#import "main.e"
#import "mprompt.e"
#import "projconv.e"
#import "stdprocs.e"
#import "stdcmds.e"
#import "se/debug/pydbgp/pydbgp.e"
#import "debug.e"
#import "wkspace.e"
#import "os2cmds.e"
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
#import "fileproject.e"
#import "compile.e"
#import "se/tags/TaggingGuard.e";
#endregion

static const PYDBGP_VERSION= "1.3.0";
static const GWT_TAB_CAPTION= "Google";

using namespace se.debug.pydbgp;
using namespace se.debug.dbgp;

struct PyRemoteFileMapping {
   // Example: /var/www/cgi-bin/
   _str remoteRoot;
   // Example: c:\inetpub\wwwroot\cgi\
   _str localRoot;
};

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
   _str debugListenHost;
   _str debugListenPort;

   PyRemoteFileMapping remoteFileMap[];
};

static _str getPydbgpDir()
{
   _str resource_dir = _getSlickEditInstallPath();
   _maybe_strip_filesep(resource_dir);
   resource_dir :+= FILESEP:+'resource';

   tools_dir :=  resource_dir:+FILESEP:+'tools';

   pydbgp_dir :=  tools_dir:+FILESEP:+'pydbgp-'PYDBGP_VERSION;
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
   python_opts.debugListenHost = "127.0.0.1";
   python_opts.debugListenPort = "5678";
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
   PyRemoteFileMapping remoteFileMap[];  remoteFileMap._makeempty();

   python_opts.debugListenHost = default_python_opts.debugListenHost;
   python_opts.debugListenPort = default_python_opts.debugListenPort;

   int node = _ProjectGet_ConfigNode(projectHandle,config);
   if( node >= 0 ) {
      int opt_node = _xmlcfg_find_simple(projectHandle,"List[@Name='Python Options']",node);
      if( opt_node >= 0 ) {
         vnode := _xmlcfg_find_simple(projectHandle, "Item[@Name='ServerListenHost']", opt_node);
         if (vnode >= 0) {
            python_opts.debugListenHost = _xmlcfg_get_attribute(projectHandle, vnode, "Value", default_python_opts.debugListenHost);
         } 

         vnode = _xmlcfg_find_simple(projectHandle, "Item[@Name='ServerListenPort']", opt_node);
         if (vnode >= 0) {
            python_opts.debugListenPort = _xmlcfg_get_attribute(projectHandle, vnode, "Value", default_python_opts.debugListenPort);
         }

         _str nodes[];
         if( 0 == _xmlcfg_find_simple_array(projectHandle,"List[@Name='Map']",nodes,opt_node,0) ) {
            _str remoteRoot, localRoot;
            foreach( auto map_node in nodes ) {
               remoteRoot = "";
               localRoot = "";
               node = _xmlcfg_find_simple(projectHandle,"Item[@Name='RemoteRoot']",(int)map_node);
               if( node >=0  ) {
                  remoteRoot = _xmlcfg_get_attribute(projectHandle,node,"Value","");
               }
               node = _xmlcfg_find_simple(projectHandle,"Item[@Name='LocalRoot']",(int)map_node);
               if( node >=0  ) {
                  localRoot = _xmlcfg_get_attribute(projectHandle,node,"Value","");
               }
               i := remoteFileMap._length();
               remoteFileMap[i].remoteRoot = remoteRoot;
               remoteFileMap[i].localRoot = localRoot;
            }
         }
      }

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
   python_opts.remoteFileMap = remoteFileMap;
}

static void getProjectPythonOptions(int projectHandle, _str (&configList)[], PythonOptions (&python_opts_list):[])
{
   foreach( auto config in configList ) {
      PythonOptions opts;
      getProjectPythonOptionsForConfig(projectHandle,config,opts);
      python_opts_list:[config] = opts;
   }
}

static void setProjectOptionsForConfig(int projectHandle, _str config, PythonOptions& python_opts, DBGpOptions& pydbgp_opts)
{
   //
   // Execute
   //

   int target_node = _ProjectGet_TargetNode(projectHandle,"Execute",config);
   cmdline := '"%(SLICKEDIT_PYTHON_EXE)"';
   if( python_opts.interpreterArgs != "" ) {
      cmdline :+= ' 'python_opts.interpreterArgs;
   }
   if (_ProjectGet_AppType(projectHandle) == APPTYPE_GWT) {
      port := "8080";
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
   cmdline :+= ' %(SLICKEDIT_PYTHON_EXECUTE_ARGS)';
   if( python_opts.defaultFile != "" ) {
      cmdline :+= " "_maybe_quote_filename(python_opts.defaultFile)" %~other";
   } else {
      cmdline :+= ' "%f" %~other';
   }

   curCmdLine := _ProjectGet_TargetCmdLine(projectHandle, target_node, false);

   // The user may have added program arguments here - if their command line is the same as what we've built up, 
   // minus any script arguments the user tacked on, leave the command line as it is.  In theory, we don't need to 
   // rebuild the command line for these types of changes once the cmdline is in the "%(PYTHON_EXE) %(EXECUTE_ARGS)..." form;
   // But we still need to support it so we can deal correctly with project commandlines from older versions.
   if (!beginsWith(curCmdLine, cmdline, false)) {
      _ProjectSet_TargetCmdLine(projectHandle,target_node,cmdline,"",python_opts.scriptArgs);
   } else {
      _ProjectSet_TargetOtherOptions(projectHandle, target_node, python_opts.scriptArgs);
   }

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
         _ProjectSet_TargetCmdLine(projectHandle,deployNode,_maybe_quote_filename(deployScript));
      } else {
         _ProjectAdd_Target(projectHandle,'DeployScript',_maybe_quote_filename(deployScript),'',config,"Never","");
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

   // ServerHost
   int node = _xmlcfg_add(projectHandle,opt_node,VPJTAG_ITEM,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add_attribute(projectHandle,node,"Name","ServerListenHost",0);
   _xmlcfg_add_attribute(projectHandle,node,"Value",python_opts.debugListenHost,0);

   // ServerPort
   node = _xmlcfg_add(projectHandle,opt_node,VPJTAG_ITEM,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add_attribute(projectHandle,node,"Name","ServerListenPort",0);
   _xmlcfg_add_attribute(projectHandle,node,"Value",python_opts.debugListenPort,0);

   // Remote Mappings
   PyRemoteFileMapping remote_file_map;
   foreach( remote_file_map in python_opts.remoteFileMap ) {
      // Must have trailing path separators.
      _maybe_append_filesep(remote_file_map.localRoot);
      _maybe_append_filesep(remote_file_map.remoteRoot);

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
   node = _xmlcfg_add(projectHandle,opt_node,VPJTAG_ITEM,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
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

   // DBGp features
   node = _xmlcfg_add(projectHandle,opt_node,VPJTAG_ITEM,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add_attribute(projectHandle,node,"Name","show_hidden",0);
   _xmlcfg_add_attribute(projectHandle,node,"Value",(int)pydbgp_opts.dbgp_features.show_hidden,0);
}

static void setProjectOptions(int projectHandle, _str (&configList)[], PythonOptions (&python_opts_list):[], DBGpOptions (&pydbgp_opts_list):[])
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

_str getPythonExePath(bool isPythonProject, bool& pathModified) 
{
   pythonExePath := "";
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
         rteForceUpdate();
      } else {
         // Show Python Options dialog and let user set it from there
         pythonoptions('-setting-environment');
         pythonExePath = def_python_exe_path;
      }
   }

   return pythonExePath;
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
                            bool quiet=false, _str& error_hint=null)
{
   if (projectHandle<0) {
      if( _project_name == "" && _fileProjectHandle()<0) {
         return 0;
      }
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

   isPythonProject := ( strieq("python",_ProjectGet_Type(projectHandle,config)) );

   // Restore the original environment. This is done so the
   // path for python.exe is not appended over and over.

   pythonExePath := getPythonExePath(isPythonProject, auto exe_path_modified);
   _restore_origenv(exe_path_modified);

   // Make sure we got a path
   if( pythonExePath == "" ) {
      return COMMAND_CANCELLED_RC;
   }

   // Set the environment
   set_env('SLICKEDIT_PYTHON_EXE',pythonExePath);
   set('SLICKEDIT_PYTHON_EXE='pythonExePath);
   pythonDir := _strip_filename(pythonExePath,'N');
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
_command int set_python_environment() name_info(','VSARG2_REQUIRES_PRO_EDITION)
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
            msg :+= "\n\nContinue to execute this script?";
            msg :+= "\n\n"'Note: You can choose a default script to run from the Options dialog ("Build", "Python Options")';
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
 * Start debugging session. 
 *
 * @return >0 socket connection on success, <0 on error. 
 */
_command int python_debug(_str cmdArgs = '') name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build system");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   /*if( _project_name == "" ) {
      // What are we doing here?
      msg := "No project. Cannot debug.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return INVALID_ARGUMENT_RC;
   } */

   if( _project_DebugCallbackName != "dap" && _project_DebugCallbackName != 'pydbgp' ) {
      // What are we doing here?
      msg := "Project does not support pydap. Cannot debug.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return INVALID_ARGUMENT_RC;
   }


   //TODO: get from our configuration.
   status := 0;
   _str dbgArguments, dbgWorkingDir, dbgStep;

   if (cmdArgs != '') {
      parse cmdArgs with 'debugWorkingDir=' dbgWorkingDir '|debugArguments=' dbgArguments'|stepType='dbgStep;
   }

   handle := 0;
   config := "";
   _ProjectGet_ActiveConfigOrExt(_project_name,handle,config);

   getProjectPythonOptionsForConfig(handle, config, auto pyopts);
   host := pyopts.debugListenHost;
   port := pyopts.debugListenPort;

   if (dbgWorkingDir == '') {
      // Even when we aren't called from debug-run-with-arguments, we still need to override the 
      // workingDir, because we want to use the working directory setting from the "Debug" target
      // when we invoke the execute target below.
      node := _ProjectGet_TargetNode(handle,'debug',config);
      if (node >= 0) {
         dbgWorkingDir = _getRunFromDirectory(handle, node,_isEditorCtl(false)?p_buf_name:'');
      }
   }

   if (dbgArguments == '') {
      // Get the other arguments set on the execute command, and use those.
      node := _ProjectGet_TargetNode(handle, 'execute', config);
      if (node >= 0) {
         dbgArguments = _parse_project_command(_ProjectGet_TargetOtherOptions(handle,node), 
                                               p_buf_name, _project_name, '');
      }
   }

   PythonOptions opts;

   // build ptvsd command line to wait for us to connect.
   getProjectPythonOptionsForConfig(handle, config, opts);
   exePath := getPythonExePath(true, auto wasModified);
   if (exePath == '') {
      _message_box('Can not run debugger without a path to the Python interpreter');
      return FILE_NOT_FOUND_RC;
   } else if (!file_exists(exePath)) {
      _message_box('No Python interpreter found at 'exePath);
      return FILE_NOT_FOUND_RC;
   }
   exePath = _maybe_quote_filename(exePath);
   ptvsdroot := get_env('VSROOT')'resource/tools/ptvsd';
   runningActiveBuffer := opts.defaultFile == '';
   scriptFile := runningActiveBuffer ?  _maybe_quote_filename(p_buf_name)
                                     :  _parse_project_command(opts.defaultFile, 
                                                               p_buf_name,
                                                               _project_name,
                                                               '');
   scriptFile = _maybe_quote_filename(scriptFile);
   exArgs := get_env('SLICKEDIT_PYTHON_EXECUTE_ARGS');
   interpArgs := _parse_project_command(opts.interpreterArgs, p_buf_name, 
                                        _project_name, '');
   cmdline := exePath' -u 'interpArgs' 'exArgs' "'ptvsdroot'" --host 'host' --port 'port :+
      ' --wait "'ptvsdroot'/se_wrapper_script.py" 'scriptFile' 'dbgArguments;

   cd('+p 'dbgWorkingDir);
   concur_command(cmdline);

   dbgArgs := '';
   if (dbgStep == 'into') {
      // We have to help the debugger by finding and passing in the first executable line in the
      // current script.
      int tmpv, origv;
      rc := 0;
      if (!runningActiveBuffer) {
         rc = _open_temp_view(scriptFile, tmpv, origv, '', true, false, true);
      }
      python_debug_find_first_exe_line(auto script, auto line);
      if (script != '') {
         dbgArgs = '--first 'script'!'line;
      }

      if (!runningActiveBuffer && rc == 0) {
         activate_window(origv);
         _delete_temp_view(tmpv);
      }
   }
   return debug_begin('dap', host, port, '', def_debug_timeout, null, dbgArgs, null, dbgStep);
}

static const PYTHONOPTS_FORM_MINWIDTH=  8175;
static const PYTHONOPTS_FORM_MINHEIGHT= 7950;

defeventtab _python_options_form;

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _python_options_form_initial_alignment()
{
   // form level
   rightAlign := ctl_current_config.p_x_extent;
   sizeBrowseButtonToTextBox(ctl_python_exe_path.p_window_id, ctl_browse_python_exe.p_window_id, 0, rightAlign);

   // run tab
   rightAlign = ctl_script_args.p_x_extent;
   sizeBrowseButtonToTextBox(ctl_default_file.p_window_id, ctl_browse_default_file.p_window_id, 0, rightAlign);
   sizeBrowseButtonToTextBox(ctl_interpreter_args.p_window_id, ctl_interpreter_arg_button.p_window_id, 0, rightAlign);

   // google tab
   sizeBrowseButtonToTextBox(ctl_appengine_loc.p_window_id, ctl_appengine_browse.p_window_id);
}

static bool changingCurrentConfig(int value=-1)
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

static bool changingMappings(int value=-1)
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

static void getFormOptions(PythonOptions& python_opts, DBGpOptions& pydbgp_opts)
{

   // Do we have the Google tab?
   hasGoogleTab := ctl_options_tab.sstTabExists(GWT_TAB_CAPTION);

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

   python_opts.debugListenHost = ctl_server_host.p_text;
   python_opts.debugListenPort = ctl_server_port.p_text;
   //
   // Remote Mappings tab
   //

   python_opts.remoteFileMap._makeempty();
   index := ctl_mappings._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while( index >= 0 ) {
      mapline := ctl_mappings._TreeGetCaption(index);
      localRoot := "";
      remoteRoot := "";
      parse mapline with remoteRoot"\t"localRoot;
      i := python_opts.remoteFileMap._length();
      python_opts.remoteFileMap[i].localRoot = localRoot;
      python_opts.remoteFileMap[i].remoteRoot = remoteRoot;
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
   state := bm1 := bm2 := flags := 0;
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

static bool validateFormOptions(PythonOptions& python_opts, DBGpOptions& pydbgp_opts)
{
   getFormOptions(python_opts,pydbgp_opts);

   // Used to flag duplicate remote-to-local mappings
   int remote2local_dup_set:[] = null;

   int i, n=python_opts.remoteFileMap._length();
   for( i=0; i < n; ++i ) {

      // Remote root is the pivot, so we should never have an empty remote-root-directory entry
      _str remoteRoot = python_opts.remoteFileMap[i].remoteRoot;
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
      _str localRoot = python_opts.remoteFileMap[i].localRoot;
      if( localRoot == "" || !isdirectory(localRoot) ) {
         // Park the user on the problem
         msg := "";
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

   if( python_opts.debugListenHost == "" ) {
      msg := "Invalid/missing pydbgp host";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      ctl_options_tab.sstActivateTabByCaption("Debug");
      p_window_id = ctl_server_host;
      _set_sel(1,length(p_text)+1);
      _set_focus();
      return false;
   }
   if( python_opts.debugListenPort == "0" ) {
      // Dynamic port is okay
   } else if( python_opts.debugListenHost == "" || vssServiceNameToPort(python_opts.debugListenPort) < 0 ) {
      msg := "Invalid/missing debug adapter port";
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
                                     DBGpOptions (&all_pydbgp_opts):[],
                                     DBGpOptions& default_pydbgp_opts)
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
   DBGpOptions pydbgp_opts = null;

   if( config == PROJ_ALL_CONFIGS ) {
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
   hasGoogleTab := ctl_options_tab.sstTabExists(GWT_TAB_CAPTION);

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
   ctl_server_host.p_text = python_opts.debugListenHost;
   // Local port
   if( python_opts.debugListenPort == "0" || python_opts.debugListenPort == "" ) {
      // The specified port will be disabled because the user chose a
      // system-provided port, but leave whatever is there in case they
      // change their mind and want to switch back while the dialog is
      // still up.
      if( ctl_server_port.p_text == "" ) {
         // Stuff a default value in there
         ctl_server_port.p_text = "5678";
      }
   } else {
      ctl_server_port.p_text = python_opts.debugListenPort;
   }
   // Listen on startup

   //
   // Remote Mappings tab
   //

   resetMappingsTree();
   int i, n=python_opts.remoteFileMap._length();
   for( i=0; i < n; ++i ) {
      mapline :=  python_opts.remoteFileMap[i].remoteRoot"\t"python_opts.remoteFileMap[i].localRoot;
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
   if( config == PROJ_ALL_CONFIGS ) {
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

static void savePydbgpOptionsForConfig(_str config, DBGpOptions& pydbgp_opts, DBGpOptions (&all_pydbgp_opts):[])
{
   // Gather up all affected config names
   _str configIndices[];
   if( config == PROJ_ALL_CONFIGS ) {
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

static bool changeCurrentConfig(_str config)
{
   success := false;

   int old_changing_config = (int)changingCurrentConfig(1);

   do {

      _str lastConfig = _GetDialogInfoHt("lastConfig");
      PythonOptions python_opts;
      DBGpOptions pydbgp_opts;
      if( !validateFormOptions(python_opts,pydbgp_opts) ) {
         // Bad options
         break;
      }
   
      // All good, save these settings
      PythonOptions (*pAllPythonOpts):[] = _GetDialogInfoHtPtr("allPythonOpts");
      DBGpOptions (*pAllPydbgpOpts):[] = _GetDialogInfoHtPtr("allPydbgpOpts");
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
   wildCards := "*.py";
   format_list := "";
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
   if( index) {
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
   x := 100;
   y := 100;
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
   status := 0;
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
   mapline :=  remoteRoot"\t"localRoot;
   ctl_mappings._TreeAddItem(TREE_ROOT_INDEX,mapline,TREE_ADD_AS_CHILD,0,0,-1);
}

void ctl_map_remove.lbutton_up()
{
   index := ctl_mappings._TreeCurIndex();
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
   _str wildcards = _isUnix()?"":"Executable Files (*.exe;*.com;*.bat;*.cmd)";
   _str format_list = wildcards;

   // Try to be smart about the initial filename directory
   init_dir := "";
   init_filename := ctl_python_exe_path.p_text;
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

static void onCreateRunTab()
{
}

static void onCreateDebugTab()
{
   if (_isUnix()) {
      // Dialog color
      ctl_pydbgp_note.p_backcolor = 0x80000022;
   }

   // Get rid of scrollbars if possible
   ctl_pydbgp_note._minihtml_ShrinkToFit();
}

static void onCreateRemoteMappingsTab()
{
   // Mappings tree
   int col_width = ctl_mappings.p_width intdiv 2;
   int remain_width = ctl_mappings.p_width - 2*col_width;
   wid := p_window_id;
   p_window_id=ctl_mappings;
   _TreeSetColButtonInfo(0,col_width,0,-1,"Remote Directory");
   _TreeSetColButtonInfo(1,col_width+remain_width,0,-1,"Local Directory");
   _TreeSetColEditStyle(0,TREE_EDIT_TEXTBOX);
   _TreeSetColEditStyle(1,TREE_EDIT_TEXTBOX);
   p_window_id=wid;

   if (_isUnix()) {
      // Dialog color
      ctl_remote_mappings_note.p_backcolor = 0x80000022;
   }

   // Get rid of scrollbars if possible
   ctl_remote_mappings_note._minihtml_ShrinkToFit();
}

void ctl_ok.on_create(int projectHandle, _str options="", _str currentConfig="",
                     _str projectFilename=_project_name, bool isProjectTemplate=false)
{
   _SetDialogInfoHt("projectHandle",projectHandle);
   _SetDialogInfoHt("isProjectTemplate",isProjectTemplate);

   _python_options_form_initial_alignment();

   // Parse options passed in
   setting_environment := false;
   tabName := "";
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
   orig_wid := p_window_id;

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
   _lbadd_item(PROJ_ALL_CONFIGS);
   _lbtop();
   if( _lbfind_and_select_item(currentConfig) ) {
      _lbfind_and_select_item(PROJ_ALL_CONFIGS, '', true);
   }
   _str lastConfig = _lbget_text();

   p_window_id = orig_wid;
   changingCurrentConfig(0);

   PythonOptions allPythonOpts:[] = null;
   DBGpOptions allPydbgpOpts:[] = null;
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
   setting_environment := 0 != _GetDialogInfoHt("setting_environment");

   if( setting_environment ) {
      pythonExePath := ctl_python_exe_path.p_text;
      msg := "";
      if( pythonExePath != "" ) {
         msg = "Warning: The Python interpreter has been automatically found for this project.";
         msg :+= "\n\nPlease verify the Python interpreter is correct on the Options dialog that follows (\"Build\", \"Python Options\").";
      } else {
         msg = "Warning: The Python interpreter is not set for this project.";
         msg :+= "Please set the Python interpreter on the Options dialog that follows (\"Build\", \"Python Options\").";
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
   DBGpOptions (*pAllPydbgpOpts):[] = _GetDialogInfoHtPtr("allPydbgpOpts");
   setProjectOptions(projectHandle,configList,*pAllPythonOpts,*pAllPydbgpOpts);

   // Python interpreter
   pythonExePath := ctl_python_exe_path.p_text;
   if( pythonExePath != def_python_exe_path ) {
      def_python_exe_path = pythonExePath;
      // Flag state file modified
      _config_modify_flags(CFGMODIFY_DEFVAR);
      rteForceUpdate();
   }

   // Do not shutdown/restart the server if we are in the middle
   // of prompting for environment settings in order to start a
   // debugging session (otherwise you pull the rug/server out
   // from under the pydbgp monitor).
   setting_environment := 0 != _GetDialogInfoHt("setting_environment");
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

static void onResizeOptions(int deltax, int deltay, bool hasGoogleTab=false)
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

   hasGoogleTab := ctl_options_tab.sstTabExists(GWT_TAB_CAPTION);

   deltax := p_width - (ctl_current_config.p_x_extent + 180);
   deltay := p_height - (ctl_ok.p_y_extent + 180);

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

   // Debug
   ctl_server_host.p_width += deltax;
   ydist := 100;
   followy := ctl_pydbgp_note.p_y + ctl_pydbgp_note.p_height + ydist;

   ctllabel8.p_y = followy;
   ctl_server_host.p_y = followy;
   followy += ctl_server_host.p_height + ydist;

   ctllabel17.p_y = followy;
   ctl_server_port.p_y = followy;
   followy += ctl_server_host.p_height + ydist;

   ctl_pydbgp_frame.p_height = followy - ctl_pydbgp_frame.p_y + 200;
}

static void maybeDisableGoogleTab()
{
   int projectHandle = _GetDialogInfoHt("projectHandle");
   _str configList[];
   isGwt := false;
   _ProjectGet_ConfigNames(projectHandle,configList);
   if (p_text==PROJ_ALL_CONFIGS) {
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
      wid := p_window_id;
      p_window_id = ctl_options_tab;
      OldActiveTab := p_ActiveTab;
      if( sstActivateTabByCaption(GWT_TAB_CAPTION) ) {
         newActiveTab := p_ActiveTab;
         _deleteActive();
         p_window_id = p_parent;
         if( newActiveTab != OldActiveTab ) {
            p_ActiveTab = OldActiveTab;
         }
      }
      p_window_id=wid;
   }

}

_command void pythonoptions(_str options="") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build system");
      return;
   }

   int project_prop_wid;
   mou_hour_glass(true);
   projectFilesNotNeeded(1);
   if (_project_name=='') {
      handle:=_fileProjectSetCurrentOrCreate(auto editorctl_wid,auto config);
      if (handle<0) {
         return;
      }
      displayName := _strip_filename(editorctl_wid.p_buf_name,'P')' - 'editorctl_wid.p_buf_name;
      project_prop_wid = show('-hidden -app -xy _project_form',displayName,handle);
   } else {
      project_prop_wid = show('-hidden -app -xy _project_form',_project_name,_ProjectHandle(_project_name));
   }
   mou_hour_glass(false);
   configName := GetCurrentConfigName();
   ctlbutton_wid := project_prop_wid._find_control('ctlcommand_options');
   typeless result = ctlbutton_wid.call_event('_python_options_form 'options,configName,ctlbutton_wid,LBUTTON_UP,'w');
   ctltooltree_wid := project_prop_wid._find_control('ctlToolTree');
   int status = ctltooltree_wid._TreeSearch(TREE_ROOT_INDEX,'Execute','i');
   if( status < 0 ) {
      _message_box('EXECUTE command not found');
   } else {
      if( result == '' ) {
         opencancel_wid := project_prop_wid._find_control('_opencancel');
         opencancel_wid.call_event(opencancel_wid,LBUTTON_UP,'w');
      } else {
         ok_wid := project_prop_wid._find_control('_ok');
         ok_wid.call_event(ok_wid,LBUTTON_UP,'w');
      }
   }
   projectFilesNotNeeded(0);
}

defeventtab _debug_dap_remote_form;
void ctl_ok.on_create()
{
   session_name := '';
   ctl_sessions.debug_load_session_names('dap', session_name);
   ctl_host.p_text = ctl_host._retrieve_value();
   ctl_port.p_text = ctl_port._retrieve_value();
   ctlminihtml1.p_backcolor = 0x80000022;
}

static void validation_err(_str msg, int ctl)
{
   _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
   ctl._set_sel(1,length(ctl.p_text)+1);
   ctl._set_focus();
}

void ctl_ok.lbutton_up()
{
   host := ctl_host.p_text;
   if( host == "" ) {
      validation_err("Invalid host.", ctl_host);
      return;
   }

   port := ctl_port.p_text;
   if( port == "" ) {
      validation_err("Invalid port.", ctl_port);
      return;
   }

   dbgArgs := '--remote';
   handle := 0;
   config := "";
   _ProjectGet_ActiveConfigOrExt(_project_name,handle,config);
   getProjectPythonOptionsForConfig(handle, config, auto pyopts);

   if (pyopts.remoteFileMap._length() > 0) {
      dbgArgs :+= ' --map (';
      foreach (auto map in pyopts.remoteFileMap) {
         dbgArgs :+= map.localRoot;
         dbgArgs :+= ':';
         dbgArgs :+= map.remoteRoot;
         dbgArgs :+= '!';
      }
      dbgArgs :+= ')';
   }

   ctl_host._append_retrieve(ctl_host, ctl_host.p_text);
   ctl_port._append_retrieve(ctl_port, ctl_port.p_text);
   
   attach_info := 'file='host','port',path=,args='dbgArgs',session='ctl_sessions.p_text;
   p_active_form._delete_window(attach_info);
}

void _debug_dap_remote_form.on_resize()
{
   hspace := 200;
   vspace := 120;

   lmargin := ctlframe1.p_x = hspace;
   ctlframe1.p_width = p_width - 2*hspace;

   ctlminihtml1.p_x = hspace;
   ctlminihtml1.p_width = ctlframe1.p_width - 2*hspace;

   y := ctlminihtml1.p_y + ctlminihtml1.p_height + vspace;

   ctllabel1.p_x = lmargin;
   ctllabel1.p_y = y;
   ctlx := ctllabel1.p_x + ctllabel1.p_width + hspace intdiv 4;
   ctl_host.p_x = ctlx;
   ctl_host.p_y = y;
   ctl_host.p_width = ctlframe1.p_width - ctl_host.p_x - hspace;
   y += ctl_host.p_height + vspace;

   ctlportlabel.p_x = lmargin;
   ctlportlabel.p_y = y;
   ctl_port.p_x = ctlx;
   ctl_port.p_y = y;
   ctl_port.p_width = ctlframe1.p_width - ctl_port.p_x - hspace;
   y += ctl_port.p_height + vspace;

   ctllabel2.p_x = lmargin;
   ctllabel2.p_y = y;
   ctl_sessions.p_x = ctlx;
   ctl_sessions.p_y = y;
   ctl_sessions.p_width = ctlframe1.p_width - ctl_sessions.p_x - hspace;
   y += ctl_sessions.p_height + vspace;

   buttony := p_height - vspace - ctl_ok.p_height;
   ctlframe1.p_height = buttony - vspace - ctlframe1.p_y;

   ctl_cancel.p_x = p_width - hspace - ctl_cancel.p_width;
   ctl_cancel.p_y = buttony;
   ctl_ok.p_x = ctl_cancel.p_x - hspace - ctl_ok.p_width;
   ctl_ok.p_y = buttony;
}

static bool is_breakable_statement(_str t)
{
   return (t == 'statement' || t == 'if' || t == 'var' || t == 'lvar' || t == 'call' || t == 'loop' ||
           t == 'return' || t == 'assign' || t == 'switch');
}

// Helper for the debugger, to allow us to step into a script, 
// and get a reasonable place to stop execution.  Will set `file` to 
// '' if no executable line in the file can be found.
void python_debug_find_first_exe_line(_str& file, int& line)
{
   file = '';
   line = -1;
   if (p_LangId != 'py') return;

   save_pos(auto spos);
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContext(true,true,VS_UPDATEFLAG_statement);
   n := tag_get_num_of_statements();
   i := 1;

   while (i < n) {
      tag_get_statement_browse_info(i, auto cm);
      if (is_breakable_statement(cm.type_name)) {
         // First toplevel statement. 
         _GoToROffset(cm.seekpos);
         file = p_buf_name;
         line = p_line;
         restore_pos(spos);
         return;
      } else if (cm.type_name == 'try') {
         // Just break on first statement in try body.
         _GoToROffset(cm.seekpos);
         file = p_buf_name;
         line = p_line + 1;
         restore_pos(spos);
         return;
      } else if (cm.type_name == 'package') {
         // These cover the entire file, so just advance to the next.
         i++;
      } else {
         // We only want to look at top level statements, so skip
         // over whole tag.
         ends := cm.end_seekpos;
         i++;
         while (i < n) {
            tag_get_statement_browse_info(i, cm);
            if (cm.seekpos > ends) {
               break;
            }
            i++;
         }
      }
   }
   restore_pos(spos);
}

