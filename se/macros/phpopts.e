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
#require "se/debug/xdebug/XdebugOptions.e"
#import "se/debug/xdebug/xdebug.e"
#import "se/debug/xdebug/xdebugutil.e"
#import "se/debug/xdebug/xdebugprojutil.e"
#import "se/debug/dbgp/dbgputil.e"
#import "compile.e"
#import "controls.e"
#import "backtag.e"
#import "debug.e"
#import "env.e"
#import "files.e"
#import "guicd.e"
#import "guiopen.e"
#import "help.e"
#import "html.e"
#import "listbox.e"
#import "main.e"
#import "mprompt.e"
#import "picture.e"
#import "projconv.e"
#import "project.e"
#import "sstab.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tbopen.e"
#import "treeview.e"
#import "wizard.e"
#import "wkspace.e"
#require "se/debug/xdebug/XdebugConnectionProgressDialog.e"
#endregion

using namespace se.debug.xdebug;

static _str mapCaption2Value(_str (&maps)[], _str caption)
{
   foreach( auto ii=>auto item in maps ) {
      _str cap, val;
      parse item with cap'='val;
      if( cap == caption ) {
         // Found it
         return val;
      }
   }
   // Not found
   return "";
}
static _str mapValue2Caption(_str (&maps)[], _str value)
{
   foreach( auto ii=>auto item in maps ) {
      _str cap, val;
      parse item with cap'='val;
      if( val == value ) {
         // Found it
         return cap;
      }
   }
   // Not found
   return "";
}

// Not using a hash table so we can guarantee order of iteration
static _str gRunModeMap[] = {
   "Local web server (launches in browser)=web-local"
   ,"Remote web server (launches in browser)=web-remote"
   ,"Local script (command line)=cli-local"
   //,"Remote script (command line)=cli-remote"
};

static _str mapRunModeCaption2Value(_str caption)
{
   return mapCaption2Value(gRunModeMap,caption);
}
static _str mapRunModeValue2Caption(_str value)
{
   return mapValue2Caption(gRunModeMap,value);
}

// Not using a hash table so we can guarantee order of iteration
static _str gAcceptConnectionsMap[] = {
   "Prompt me to accept=prompt"
   ,"Always accept=always"
   ,"Never accept=never"
};

static _str mapAcceptConnectionsCaption2Value(_str caption)
{
   return mapCaption2Value(gAcceptConnectionsMap,caption);
}
static _str mapAcceptConnectionsValue2Caption(_str value)
{
   return mapValue2Caption(gAcceptConnectionsMap,value);
}

// Not using a hash table so we can guarantee order of iteration
static _str gBreakInSessionMap[] = {
   "Break on first line of script=step-into"
   ,"Run to first breakpoint=run"
};

static _str mapBreakInSessionCaption2Value(_str caption)
{
   return mapCaption2Value(gBreakInSessionMap,caption);
}
static _str mapBreakInSessionValue2Caption(_str value)
{
   return mapValue2Caption(gBreakInSessionMap,value);
}

struct PhpUrlMapping {
   // Example: http://www.slickedit.com/
   _str remoteUrl;
   // localRoot is the primary-key with XdebugRemoteFileMapping
   // Example: c:\inetpub\wwwroot\
   _str localRoot;
};

struct PhpOptions {
   // Application type: 'web-local', 'web-remote', 'script-local', 'script-remote'
   _str appType;
   // Default url/file to run. If blank then current file is run.
   _str defaultFile;
   // remote-url<=>local-root file mappings
   PhpUrlMapping urlMap[];
   // Script arguments (standalone scripts)
   _str scriptArgs;
   // Interpreter arguments (standalone scripts)
   _str interpreterArgs;
};

static PhpOptions makeDefaultPhpOptions(PhpOptions& php_opts=null)
{
   php_opts.appType = "web-local";
   php_opts.defaultFile = "";
   php_opts.urlMap = null;
   php_opts.scriptArgs = "";
   php_opts.interpreterArgs = "";
   return php_opts;
}

static bool isAppTypeWeb(_str appType)
{
   return ( substr(appType,1,length("web-")) == "web-" );
}

static bool isAppTypeCli(_str appType)
{
   return ( substr(appType,1,length("cli-")) == "cli-" );
}

static bool isAppTypeLocal(_str appType)
{
   return ( length(appType) > length("-local") &&
            substr(appType,length(appType)-length("-local")+1) == "-local" );
}

static bool isAppTypeRemote(_str appType)
{
   return ( length(appType) > length("-remote") &&
            substr(appType,length(appType)-length("-remote")+1) == "-remote" );
}

static void getProjectPhpOptionsForConfig(int projectHandle, _str config, PhpOptions& php_opts)
{
   // Guarantee sane values
   PhpOptions default_php_opts;
   makeDefaultPhpOptions(default_php_opts);
   _str appType = default_php_opts.appType;
   _str defaultFile = default_php_opts.defaultFile;
   _str scriptArgs = default_php_opts.scriptArgs;
   _str interpreterArgs = default_php_opts.interpreterArgs;
   PhpUrlMapping urlMap[] = default_php_opts.urlMap;

   int node = _ProjectGet_ConfigNode(projectHandle,config);
   if( node >= 0 ) {
      int opt_node = _xmlcfg_find_simple(projectHandle,"List[@Name='PHP Options']",node);
      if( opt_node >= 0 ) {

         // AppType
         node = _xmlcfg_find_simple(projectHandle,"Item[@Name='AppType']",opt_node);
         if( node >=0  ) {
            appType = _xmlcfg_get_attribute(projectHandle,node,"Value",appType);
         }

         // DefaultFile
         node = _xmlcfg_find_simple(projectHandle,"Item[@Name='DefaultFile']",opt_node);
         if( node >=0  ) {
            defaultFile = _xmlcfg_get_attribute(projectHandle,node,"Value",defaultFile);
         }

         // ScriptArguments
         // Note: We cannot just store this with the Execute commandline since PHP
         // projects can switch between a standalone script or web page. Otherwise
         // we would lose the setting when the user switched.
         node = _xmlcfg_find_simple(projectHandle,"Item[@Name='ScriptArguments']",opt_node);
         if( node >=0  ) {
            scriptArgs = _xmlcfg_get_attribute(projectHandle,node,"Value",scriptArgs);
         }

         // InterpreterArguments
         // Note: We cannot just store this with the Execute commandline since PHP
         // projects can switch between a standalone script or web page. Otherwise
         // we would lose the setting when the user switched.
         node = _xmlcfg_find_simple(projectHandle,"Item[@Name='InterpreterArguments']",opt_node);
         if( node >=0  ) {
            interpreterArgs = _xmlcfg_get_attribute(projectHandle,node,"Value",interpreterArgs);
         }

         // URL mappings
         _str nodes[];
         if( 0 == _xmlcfg_find_simple_array(projectHandle,"List[@Name='Map']",nodes,opt_node,0) ) {
            _str remoteUrl, localRoot;
            foreach( auto ii=>auto map_node in nodes ) {
               remoteUrl = "";
               localRoot = "";
               node = _xmlcfg_find_simple(projectHandle,"Item[@Name='RemoteUrl']",(int)map_node);
               if( node >=0  ) {
                  remoteUrl = _xmlcfg_get_attribute(projectHandle,node,"Value","");
               }
               node = _xmlcfg_find_simple(projectHandle,"Item[@Name='LocalRoot']",(int)map_node);
               if( node >=0  ) {
                  localRoot = _xmlcfg_get_attribute(projectHandle,node,"Value","");
               }
               i := urlMap._length();
               urlMap[i].remoteUrl = remoteUrl;
               urlMap[i].localRoot = localRoot;
            }
         }
      }
   }
   php_opts.appType = appType;
   php_opts.defaultFile = defaultFile;
   php_opts.scriptArgs = scriptArgs;
   php_opts.interpreterArgs = interpreterArgs;
   php_opts.urlMap = urlMap;
}

static void getProjectPhpOptions(int projectHandle, _str (&configList)[], PhpOptions (&php_opts_list):[])
{
   foreach( auto ii=>auto config in configList ) {
      PhpOptions opts;
      getProjectPhpOptionsForConfig(projectHandle,config,opts);
      php_opts_list:[config] = opts;
   }
}

static void setProjectOptionsForConfig(int projectHandle, _str config, PhpOptions& php_opts, XdebugOptions& xdebug_opts)
{
   //
   // Execute
   //

   int target_node = _ProjectGet_TargetNode(projectHandle,"Execute",config);
   if( isAppTypeWeb(php_opts.appType) ) {
      _ProjectSet_TargetCmdLine(projectHandle,target_node,"php_execute %(SLICKEDIT_PHP_EXECUTE_ARGS)","Slick-C","");
   } else {
      // 'cli-local' or 'cli-remote'
      cmdline := '"%(SLICKEDIT_PHP_EXE)"';
      if( php_opts.interpreterArgs != "" ) {
         cmdline :+= ' 'php_opts.interpreterArgs;
      }
      if( php_opts.defaultFile != "" ) {
         cmdline :+= ' '_maybe_quote_filename(php_opts.defaultFile)' %~other';
      } else {
         cmdline :+= ' "%f" %~other';
      }
      _ProjectSet_TargetCmdLine(projectHandle,target_node,cmdline,"",php_opts.scriptArgs);
   }

   //
   // Debug
   //

   //target_node = _ProjectGet_TargetNode(projectHandle,"Debug",config);
   //_ProjectSet_TargetCmdLine(projectHandle,target_node,"php_debug","Slick-C");

   //
   // PHP Options, Xdebug Options
   //

   int config_node = _ProjectGet_ConfigNode(projectHandle,config);

   //
   // PHP Options
   //

   int opt_node = _xmlcfg_find_simple(projectHandle,"List[@Name='PHP Options']",config_node);

   // Clear out old options
   if( opt_node >= 0 ) {
      _xmlcfg_delete(projectHandle,opt_node,false);
   }
   opt_node = _xmlcfg_add(projectHandle,config_node,VPJTAG_LIST,VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add_attribute(projectHandle,opt_node,"Name","PHP Options",0);

   // AppType
   int node = _xmlcfg_add(projectHandle,opt_node,VPJTAG_ITEM,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add_attribute(projectHandle,node,"Name","AppType",0);
   _xmlcfg_add_attribute(projectHandle,node,"Value",php_opts.appType,0);

   // DefaultFile
   node = _xmlcfg_add(projectHandle,opt_node,VPJTAG_ITEM,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add_attribute(projectHandle,node,"Name","DefaultFile",0);
   _xmlcfg_add_attribute(projectHandle,node,"Value",php_opts.defaultFile,0);

   // ScriptArguments
   // Note: We cannot just store this with the Execute commandline since PHP
   // projects can switch between a standalone script or web page. Otherwise
   // we would lose the setting when the user switched.
   node = _xmlcfg_add(projectHandle,opt_node,VPJTAG_ITEM,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add_attribute(projectHandle,node,"Name","ScriptArguments",0);
   _xmlcfg_add_attribute(projectHandle,node,"Value",php_opts.scriptArgs,0);

   // InterpreterArguments
   // Note: We cannot just store this with the Execute commandline since PHP
   // projects can switch between a standalone script or web page. Otherwise
   // we would lose the setting when the user switched.
   node = _xmlcfg_add(projectHandle,opt_node,VPJTAG_ITEM,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add_attribute(projectHandle,node,"Name","InterpreterArguments",0);
   _xmlcfg_add_attribute(projectHandle,node,"Value",php_opts.interpreterArgs,0);

   // URL maps
   PhpUrlMapping url_map;
   foreach( auto ii=>url_map in php_opts.urlMap ) {
      // Map
      int map_node = _xmlcfg_add(projectHandle,opt_node,VPJTAG_LIST,VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_add_attribute(projectHandle,map_node,"Name","Map",0);
      // RemoteUrl
      node = _xmlcfg_add(projectHandle,map_node,VPJTAG_ITEM,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_add_attribute(projectHandle,node,"Name","RemoteUrl",0);
      _xmlcfg_add_attribute(projectHandle,node,"Value",url_map.remoteUrl,0);
      // LocalRoot
      node = _xmlcfg_add(projectHandle,map_node,VPJTAG_ITEM,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_add_attribute(projectHandle,node,"Name","LocalRoot",0);
      _xmlcfg_add_attribute(projectHandle,node,"Value",url_map.localRoot,0);
   }

   //
   // Xdebug Options
   //

   opt_node = _xmlcfg_find_simple(projectHandle,"List[@Name='Xdebug Options']",config_node);

   // Clear out old options
   if( opt_node >= 0 ) {
      _xmlcfg_delete(projectHandle,opt_node,false);
   }
   opt_node = _xmlcfg_add(projectHandle,config_node,VPJTAG_LIST,VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add_attribute(projectHandle,opt_node,"Name","Xdebug Options",0);

   // ServerHost
   node = _xmlcfg_add(projectHandle,opt_node,VPJTAG_ITEM,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add_attribute(projectHandle,node,"Name","ServerHost",0);
   _xmlcfg_add_attribute(projectHandle,node,"Value",xdebug_opts.serverHost,0);

   // ServerPort
   node = _xmlcfg_add(projectHandle,opt_node,VPJTAG_ITEM,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add_attribute(projectHandle,node,"Name","ServerPort",0);
   _xmlcfg_add_attribute(projectHandle,node,"Value",xdebug_opts.serverPort,0);

   // ListenInBackground
   node = _xmlcfg_add(projectHandle,opt_node,VPJTAG_ITEM,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add_attribute(projectHandle,node,"Name","ListenInBackground",0);
   _xmlcfg_add_attribute(projectHandle,node,"Value",(int)xdebug_opts.listenInBackground,0);

   // StayInDebugger
   node = _xmlcfg_add(projectHandle,opt_node,VPJTAG_ITEM,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add_attribute(projectHandle,node,"Name","StayInDebugger",0);
   _xmlcfg_add_attribute(projectHandle,node,"Value",(int)xdebug_opts.stayInDebugger,0);

   // AcceptConnections
   node = _xmlcfg_add(projectHandle,opt_node,VPJTAG_ITEM,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add_attribute(projectHandle,node,"Name","AcceptConnections",0);
   _xmlcfg_add_attribute(projectHandle,node,"Value",xdebug_opts.acceptConnections,0);

   // BreakInSession
   node = _xmlcfg_add(projectHandle,opt_node,VPJTAG_ITEM,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add_attribute(projectHandle,node,"Name","BreakInSession",0);
   _xmlcfg_add_attribute(projectHandle,node,"Value",xdebug_opts.breakInSession,0);

   // DBGp features

   // show_hidden
   node = _xmlcfg_add(projectHandle,opt_node,VPJTAG_ITEM,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add_attribute(projectHandle,node,"Name","show_hidden",0);
   _xmlcfg_add_attribute(projectHandle,node,"Value",(int)xdebug_opts.dbgp_features.show_hidden,0);

   // Remote file maps
   XdebugRemoteFileMapping remote_file_map;
   foreach( ii=>remote_file_map in xdebug_opts.remoteFileMap ) {
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
}

static void setProjectOptions(int projectHandle, _str (&configList)[], PhpOptions (&php_opts_list):[], XdebugOptions (&xdebug_opts_list):[])
{
   foreach( auto ii=>auto config in configList ) {
      setProjectOptionsForConfig(projectHandle,config,php_opts_list:[config],xdebug_opts_list:[config]);
   }
}

static _str mapLocalToUrl(_str local_filename, PhpUrlMapping (&fileMap)[])
{
   result := "";
   longestLocalRoot := "";
   longestRemoteUrl := "";

   // Consistent file separator please
   local_filename = translate(local_filename,'/','\');

   PhpUrlMapping map;
   foreach( auto ii=>map in fileMap ) {
      _str localRoot = map.localRoot;
      _maybe_append_filesep(localRoot);

      // Consistent file separator please
      localRoot = translate(localRoot,'/','\');

      if( length(localRoot) < length(local_filename) &&
          _file_eq(substr(local_filename,1,length(localRoot)),localRoot) ) {

          if( length(localRoot) > length(longestLocalRoot) &&
              map.remoteUrl != "" ) {

             longestLocalRoot = localRoot;
             longestRemoteUrl = map.remoteUrl;
          }
      }
   }
   if( longestLocalRoot != "" ) {
      _maybe_append(longestRemoteUrl,'/');
      result = longestRemoteUrl:+substr(local_filename,length(longestLocalRoot)+1);
   }
   return result;
}

static _str guessPhpExePath()
{
   if( def_php_exe_path != "" ) {
      // No guessing necessary
      return def_php_exe_path;
   }
   _str exePath = path_search('php'EXTENSION_EXE);
   return exePath;
}

/**
 * Callback called from _project_command to prepare the 
 * environment for running php command-line interpreter. The 
 * value found in def_php_exe_path takes precedence. If not 
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
int _php_set_environment(int projectHandle=-1, _str config="", _str target="",
                         bool quiet=false, _str& error_hint=null)
{
   if( _project_name == "" ) {
      return 0;
   }

   target = lowcase(target);
   if( target == "php options" ) {
      // If user selects Build>PHP Options tool then the PHP Options dialog could
      // come up twice if the PHP interpreter path is not set. This would
      // happen because _project_command() calls us before executing any tool
      // in order to get the environment set up.
      return 0;
   } else if( target == "debug" ) {
      // Debug calls Execute, so no need to set the environment twice
      return 0;
   }

   // Help for the user in case of error
   error_hint = "Set the PHP interpreter (\"Build\",\"PHP Options\").";

   if( projectHandle < 0 ) {
      _ProjectGet_ActiveConfigOrExt(_project_name,projectHandle,config);
   }

   isPhpProject := ( strieq("php",_ProjectGet_Type(projectHandle,config)) );
   if( isPhpProject ) {
      PhpOptions php_opts;
      getProjectPhpOptionsForConfig(projectHandle,config,php_opts);
      if( isAppTypeWeb(php_opts.appType) ) {
         // Web apps do not require a local installation of php to run
         return 0;
      }
   }

   // Restore the original environment. This is done so the
   // path for php.exe is not appended over and over.

   phpExePath := "";
   if( def_php_exe_path != "" ) {
      _restore_origenv(false);
      // Use def_php_exe_path
      phpExePath = def_php_exe_path;
   } else {
      _restore_origenv(true);
      if( !isPhpProject ) {
         // Prompt user for php path
         int status = _mdi.textBoxDialog("PHP Interpreter",
                                         0,
                                         0,
                                         "",
                                         "OK,Cancel:_cancel\tSet the PHP interpreter path so the program can be found. \nSpecify the path to 'php"EXTENSION_EXE"'.",  // Button List
                                         "",
                                         "-bf PHP interpreter:":+guessPhpExePath());
         if( status < 0 ) {
            // Probably COMMAND_CANCELLED_RC
            return status;
         }

         // Save the values entered and mark the configuration as modified
         def_php_exe_path = _param1;
         _config_modify_flags(CFGMODIFY_DEFVAR);
         phpExePath = def_php_exe_path;
      } else {
         // Show PHP Options dialog and let user set it from there
         phpoptions('-setting-environment');
         phpExePath = def_php_exe_path;
      }
   }

   // Make sure we got a path
   if( phpExePath == "" ) {
      return COMMAND_CANCELLED_RC;
   }

   // Set the environment
   set_env('SLICKEDIT_PHP_EXE',phpExePath);
   phpDir := _strip_filename(phpExePath,'N');
   _maybe_strip_filesep(phpDir);
   // PATH
   _str path = _replace_envvars("%PATH%");
   _maybe_append(path,PATHSEP);
   path :+= phpDir;
   set("PATH="path);

   // Success
   return 0;
}

/**
 * Prepares the environment for running php command-line 
 * interpreter. 
 *
 * @return 0 on success, <0 on error.
 */
_command int set_php_environment() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   int status = _php_set_environment();
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
_str _php_parse_project_command(_str command,
                                _str buf_name,
                                _str project_name,
                                _str cword,
                                _str argline='',
                                _str target='',
                                _str class_path='',
                                int handle=0, _str config='')
{
   //say('_php_parse_project_command: command='command);
   _str result = _parse_project_command(command,buf_name,project_name,cword,argline,target,class_path);

   do {

      if( stricmp('execute',target) != 0 ) {
         // We are only interested in Execute (and Debug via Execute)
         break;
      }
   
      if( handle <= 0 || config == "" ) {
         _ProjectGet_ActiveConfigOrExt(_project_name,handle,config);
      }
      PhpOptions php_opts;
      getProjectPhpOptionsForConfig(handle,config,php_opts);
   
      if( isAppTypeWeb(php_opts.appType) ) {
         // We need to be a more permissive about what can be launched in a web
         // page since we have no idea what the web server will actually serve up.
         // Besides, this code will never be hit in a project because php_execute
         // takes care of validation.
         break;
      }

      // We are only interested in inspecting the command if the user has
      // specified to use the current buffer. We assume that if they specified
      // a DefaultFile in Options that they know what they are doing.
      if( php_opts.defaultFile == "" && pos('%f',command) && buf_name != "" ) {
         // Validate buffer name
         _str langId = _Filename2LangId(buf_name);
         if( langId != 'html' && langId != 'phpscript' ) {
            _str msg = nls('"%s" does not appear to be a runnable script.',buf_name);
            msg :+= "\n\nContinue to execute this script?";
            msg :+= "\n\n"'Note: You can choose a default script to run from the Options dialog ("Build", "PHP Options")';
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
 * @param debugArguments       Custom program arguments to launch 
 *                             debug session with
 * @param debugWorkingDir      Custom working directory to 
 *                             launch debug session in 
 *
 * @return 0 on success, <0 on error.
 */
int _php_project_command_status(int projectHandle, _str config,
                                int socket_or_status,
                                _str cmdline,
                                _str target,
                                _str buf_name,
                                _str word,
                                _str debugStepType,
                                bool quiet,
                                _str& error_hint,
                                _str debugArguments="",
                                _str debugWorkingDir="")
{
   // Necessary because _project_command will pass us null status when
   // it has executed a target that returns void (e.g. 'phpoptions').
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

   if( _project_DebugCallbackName != "xdebug" ) {
      // Not an Xdebug debugger project. Nothing wrong with that, but
      // we cannot do anything with it.
      return 0;
   }

   status := 0;

   do {

      // Assemble debugger_args
      debugger_args := "";
      debugger_args :+= ' -socket='socket_or_status;
      // Pass the project remote-directory <=> local-directory mappings
      PhpOptions php_opts;
      getProjectPhpOptionsForConfig(projectHandle,config,php_opts);
      XdebugOptions xdebug_opts;
      xdebug_project_get_options_for_config(projectHandle,config,xdebug_opts);
      // Stay in debugger mode after the last DBGp session terminates?
      if( xdebug_opts.stayInDebugger ) {
         debugger_args :+= ' -stay-in-debugger';
      }
      if( isAppTypeRemote(php_opts.appType) ) {
         XdebugRemoteFileMapping map;
         foreach( auto ii=>map in xdebug_opts.remoteFileMap ) {
            if( map.remoteRoot != "" && map.localRoot != "" ) {
               debugger_args :+= ' -map='map.remoteRoot':::'map.localRoot;
            }
         }
      }
      // DBGp features
      debugger_args :+= ' 'se.debug.dbgp.dbgp_make_debugger_args(xdebug_opts.dbgp_features);
   
      // Attempt to start debug session
      status = debug_begin("xdebug","","",debugArguments,def_debug_timeout,null,debugger_args,debugWorkingDir);

   } while( false );

   if( status != 0 && socket_or_status >= 0 ) {
      // Error
      // Do not want to orphan a connected socket, so close it now.
      vssSocketClose(socket_or_status);
   }
   return status;
}

/**
 * Launch file as url in web browser.
 *
 * @return 0 on success, <0 on error.
 */
_command int php_execute(_str args="") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build system");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if( _project_name == "" ) {
      // What are we doing here?
      msg := "No project. Cannot execute.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return INVALID_ARGUMENT_RC;
   }

   PhpOptions php_opts;
   getProjectPhpOptionsForConfig(_ProjectHandle(),GetCurrentConfigName(),php_opts);
   if( !isAppTypeWeb(php_opts.appType) ) {
      // What are we doing here?
      _str msg = "Current configuration is not set to \"Web\". Cannot execute.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return INVALID_ARGUMENT_RC;
   }

   local_filename := "";
   if( php_opts.defaultFile == "" ) {
      // Use current file
      if( !_no_child_windows() ) {
         local_filename = _mdi.p_child.p_buf_name;
      }
   } else {
      local_filename = php_opts.defaultFile;
      local_filename = strip(local_filename,'B','"');
   }
   if( local_filename == "" ) {
      // Error
      msg := "No file. Cannot execute.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return INVALID_ARGUMENT_RC;
   } else if( !file_exists(local_filename) ) {
      // Error
      _str msg = nls("File \"%s\" does not exist or is not saved. Cannot execute.",local_filename);
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return INVALID_ARGUMENT_RC;
   }
   _str url = mapLocalToUrl(local_filename,php_opts.urlMap);
   if( url == "" ) {
      _str msg = nls("Could not map local file to url:\n\n%s\n\nCannot launch web page.",local_filename);
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return INVALID_ARGUMENT_RC;
   }
   if( args != "" ) {
      _maybe_strip(args, '?', stripFromFront:true);
      url :+= '?'args;
   }
   message(nls('Launching: %s ...',url));
   int status = goto_url(url);
   if( status != 0 ) {
      // Error. goto_url took care of displaying message to user.
      return status;
   }

   // All good
   return 0;
}

/**
 * Start debugging session. 
 *
 * @return >0 socket connection on success, <0 on error. 
 */
_command int php_debug(_str cmdArgs = '') name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if( _project_name == "" ) {
      // What are we doing here?
      msg := "No project. Cannot debug.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return INVALID_ARGUMENT_RC;
   }

   if( _project_DebugCallbackName != "xdebug" ) {
      // What are we doing here?
      msg := "Project does not support Xdebug. Cannot debug.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return INVALID_ARGUMENT_RC;
   }

   XdebugOptions xdebug_opts;
   xdebug_project_get_options_for_config(_ProjectHandle(),GetCurrentConfigName(),xdebug_opts);
   if( xdebug_opts.serverHost == "" || xdebug_opts.serverPort == "" ) {
      msg := "Invalid Xdebug parameters. Cannot debug.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return INVALID_ARGUMENT_RC;
   }

   status_or_socket := 0;

   // We do not want the possiblility of the passive connection monitor
   // attempting to start a debug session right in the middle of things
   // because it also recognized a pending connection. That would get
   // very confusing.
   int old_almost_active = (int)xdebug_almost_active();
   xdebug_almost_active(1);

   do {

      // Reset XDEBUG_CONFIG environment variable after running command?
      // Set to null to indicate no reset.
      _str old_xdebug_config = null;
      already_listening := xdebug_is_listening(xdebug_opts.serverHost,xdebug_opts.serverPort);
      if( !already_listening || !xdebug_is_pending(xdebug_opts.serverHost,xdebug_opts.serverPort) ) {
   
         if( !already_listening ) {
            // Must provision a one-shot server before EXECUTE, otherwise Xdebug will fail
            // the connection test to us.
            xdebug_watch(xdebug_opts.serverHost,xdebug_opts.serverPort);
         }
   
         dbgArgs := dbgWorkingDir := "";
         if ( cmdArgs != '' ) {
            parseDebugParameters(cmdArgs, dbgArgs, dbgWorkingDir);
         }

         // Must EXECUTE and listen for resulting connection from debugger engine
         PhpOptions php_opts;
         getProjectPhpOptionsForConfig(_ProjectHandle(),GetCurrentConfigName(),php_opts);
         if ( isAppTypeWeb(php_opts.appType) ) {
            old_value := get_env('SLICKEDIT_PHP_EXECUTE_ARGS');
            if( old_value == "" && rc == STRING_NOT_FOUND_RC ) {
               old_value = null;
            }
            dbgArgs = strip(dbgArgs, 'L', '?');
            dbgArgs = strip(dbgArgs, 'B', '&');
            php_execute_args := "XDEBUG_SESSION_START=slickedit";
            if ( dbgArgs != '' ) {
               php_execute_args :+= '&'dbgArgs;
            }
            set_env("SLICKEDIT_PHP_EXECUTE_ARGS", php_execute_args);
            status_or_socket = (int)project_execute();
            set_env("SLICKEDIT_PHP_EXECUTE_ARGS", old_value);
         } else {
            // Command-line script
            old_xdebug_config = get_env('XDEBUG_CONFIG');
            xdebug_config := '"idekey=slickedit"';
            set('XDEBUG_CONFIG='xdebug_config);
            override_flags := 0;
            if ( _isWindows() ) {
               // Force script to be shelled to console
               //override_flags |= OVERRIDE_CAPTUREOUTPUTWITH_PROCESSBUFFER;
            }
            status_or_socket = (int)_project_command2('execute', false, false, override_flags, false, 'go', '', dbgArgs, dbgWorkingDir);
            //set('XDEBUG_CONFIG='old_xdebug_config);
         }
         if( status_or_socket != 0 ) {
            // Error. project_execute should have taken care of displaying any message.
            if( !already_listening ) {
               // Clean up the one-shot server we created
               xdebug_shutdown(xdebug_opts.serverHost,xdebug_opts.serverPort);
            }
            break;
         }
         // Fall through to actively waiting for connection
      }
   
      se.debug.xdebug.XdebugConnectionProgressDialog dlg;
      int timeout = 1000*def_debug_timeout;
      status_or_socket = xdebug_wait_and_accept(xdebug_opts.serverHost,xdebug_opts.serverPort,timeout,&dlg,false);

      // Set XDEBUG_CONFIG back so Execute tool does not inadvertantly start a debug session
      if( old_xdebug_config != null ) {
         //set('XDEBUG_CONFIG='old_xdebug_config);
         _post_call(set,'XDEBUG_CONFIG='old_xdebug_config);
      }

      if( !already_listening ) {
         // Clean up the one-shot server we created
         xdebug_shutdown(xdebug_opts.serverHost,xdebug_opts.serverPort);
      } else {
         if( status_or_socket < 0 ) {
            // Error. Was it serious?
            if( status_or_socket != COMMAND_CANCELLED_RC && status_or_socket != SOCK_TIMED_OUT_RC ) {
               _str msg = "You just failed to accept a connection from Xdebug. The error was:\n\n" :+
                          get_message(status_or_socket)" ("status_or_socket")\n\n" :+
                          "Would you like to stop listening for a connection?";
               int result = _message_box(msg,"",MB_YESNO|MB_ICONQUESTION);
               if( result == IDYES ) {
                  xdebug_shutdown(xdebug_opts.serverHost,xdebug_opts.serverPort);
                  sticky_message(nls("Server listening at %s:%s has been shut down.",xdebug_opts.serverHost,xdebug_opts.serverPort));
               } else {
                  // Clear the last error, so the watch timer does not pick
                  // it up and throw up on the user a second time.
                  xdebug_clear_last_error(xdebug_opts.serverHost,xdebug_opts.serverPort);
               }
            } else {
               // Clear the last error, so the watch timer does not pick
               // it up and throw up on the user a second time.
               xdebug_clear_last_error(xdebug_opts.serverHost,xdebug_opts.serverPort);
            }
         }

         // Note: The server takes care of resuming any previous watch
      }
      //say('php_debug: h1 - status_or_socket='status_or_socket);

   } while( false );

   xdebug_almost_active(old_almost_active);

   return status_or_socket;
}

static const PHPOPTS_FORM_MINWIDTH=  8175;
static const PHPOPTS_FORM_MINHEIGHT= 7950;

defeventtab _php_options_form;

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _php_options_form_initial_alignment()
{
   // form level
   rightAlign := ctl_current_config.p_x_extent;
   sizeBrowseButtonToTextBox(ctl_php_exe_path.p_window_id, ctl_browse_php_exe.p_window_id, 0, rightAlign);

   // run tab
   rightAlign = ctl_script_args.p_x_extent;
   sizeBrowseButtonToTextBox(ctl_default_file.p_window_id, ctl_browse_default_file.p_window_id, 0, rightAlign);
   sizeBrowseButtonToTextBox(ctl_interpreter_args.p_window_id, ctl_interpreter_arg_button.p_window_id, 0, rightAlign);
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

static bool changingRunAs(int value=-1)
{
   typeless old_value = _GetDialogInfoHt("changingRunAs");
   if( old_value == null ) {
      old_value = false;
   }
   if( value >= 0 ) {
      _SetDialogInfoHt("changingRunAs",(value!=0));
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

static bool changingAcceptConnections(int value=-1)
{
   typeless old_value = _GetDialogInfoHt("changingAcceptConnections");
   if( old_value == null ) {
      old_value = false;
   }
   if( value >= 0 ) {
      _SetDialogInfoHt("changingAcceptConnections",(value!=0));
   }
   return ( old_value != 0 );
}

static bool changingBreakInSession(int value=-1)
{
   typeless old_value = _GetDialogInfoHt("changingBreakInSession");
   if( old_value == null ) {
      old_value = false;
   }
   if( value >= 0 ) {
      _SetDialogInfoHt("changingBreakInSession",(value!=0));
   }
   return ( old_value != 0 );
}

static void getFormOptions(PhpOptions& php_opts, XdebugOptions& xdebug_opts)
{
   //
   // Run tab
   //

   // Run as
   php_opts.appType = mapRunModeCaption2Value(ctl_run_as.p_text);

   // Default file
   php_opts.defaultFile = ctl_default_file.p_text;

   // Script arguments
   php_opts.scriptArgs = strip(ctl_script_args.p_text);

   // Interpreter arguments
   php_opts.interpreterArgs = strip(ctl_interpreter_args.p_text);

   // File mapping
   php_opts.urlMap._makeempty();
   xdebug_opts.remoteFileMap._makeempty();
   index := ctl_mappings._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while( index >= 0 ) {
      mapline := ctl_mappings._TreeGetCaption(index);
      localRoot := "";
      remoteRoot := "";
      remoteUrl := "";
      parse mapline with localRoot"\t"remoteRoot"\t"remoteUrl;
      i := php_opts.urlMap._length();
      php_opts.urlMap[i].localRoot = localRoot;
      php_opts.urlMap[i].remoteUrl = remoteUrl;
      xdebug_opts.remoteFileMap[i].localRoot = localRoot;
      xdebug_opts.remoteFileMap[i].remoteRoot = remoteRoot;
      index = ctl_mappings._TreeGetNextSiblingIndex(index);
   }

   //
   // Debug tab
   //

   xdebug_opts.serverHost = ctl_server_host.p_text;
   xdebug_opts.serverPort = ctl_server_port.p_text;
   xdebug_opts.listenInBackground = (ctl_listen_on_startup.p_value != 0);
   xdebug_opts.stayInDebugger = (ctl_stay_in_debugger.p_value != 0);
   xdebug_opts.acceptConnections = mapAcceptConnectionsCaption2Value(ctl_accept_connections.p_text);
   xdebug_opts.breakInSession = mapBreakInSessionCaption2Value(ctl_break_in_session.p_text);
   // DBGp features
   xdebug_opts.dbgp_features.show_hidden = (ctl_show_hidden.p_value != 0);
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

static bool validateFormOptions(PhpOptions& php_opts, XdebugOptions& xdebug_opts)
{
   getFormOptions(php_opts,xdebug_opts);

   // Note:
   // Standalone scripts do not use mappings. We will store them with the
   // project in case the user decides to change the apptype later.

   if( isAppTypeWeb(php_opts.appType) ) {

      nLocalRoot := 0;
      nRemoteRoot := 0;
      nRemoteUrl := 0;

      // Used to flag duplicate local-to-url entries
      int local2url_dup_set:[] = null;
      // Used to flag duplicate remote-to-local entries
      int remote2local_dup_set:[] = null;

      int result = IDNO;
      // Note: php_opts and xdebug_opts are in-sync, so we can
      // get away with iterating over both with one index.
      int i, n=php_opts.urlMap._length();
      for( i=0; i < n; ++i ) {

         // Both local-to-url and remote-to-local mappings pivot on the local-directory.
         // It is (almost) never okay to have an invalid local-directory.
         // 4/6/2012 - rb
         // Exception: Team of developers, each with their own local source directories,
         // mappings (stored with project) in version control. In this use-case, and as
         // long as there are neither local-to-url nor remote-to-local duplicates, then
         // prompt user to allow.
         _str localRoot = php_opts.urlMap[i].localRoot;
         if( localRoot == "" ) {
            // Park the user on the problem
            _str msg = nls("Missing local directory.");
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            ctl_options_tab.sstActivateTabByCaption("Run");
            p_window_id = ctl_mappings;
            _set_focus();
            selectMapping(i+1);
            return false;
         } else if( result != IDYESTOALL && !isdirectory(localRoot) ) {
            // Park the user on the problem
            _str msg = nls("Local directory '%s' does not exist.\n\nAllow?",localRoot);
            result = _message_box(msg,"",IDYES|IDNO|IDYESTOALL|MB_ICONQUESTION);
            if( result != IDYES && result != IDYESTOALL ) {
               ctl_options_tab.sstActivateTabByCaption("Run");
               p_window_id = ctl_mappings;
               _set_focus();
               selectMapping(i+1);
               return false;
            }
         }

         // local-to-url mapping duplicate check
         _str remoteUrl = php_opts.urlMap[i].remoteUrl;
         if( remoteUrl != "" && local2url_dup_set._indexin(pathToHashKey(localRoot)) ) {
            // Park the user on the problem
            _str msg = nls("More than one entry for local-to-url mapping:\n\n%s",localRoot);
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            ctl_options_tab.sstActivateTabByCaption("Run");
            p_window_id = ctl_mappings;
            _set_focus();
            selectMapping(i+1);
            return false;
         }
         // New local-to-url mapping
         local2url_dup_set:[pathToHashKey(localRoot)] = 1;
         ++nLocalRoot;

         if( remoteUrl != "" ) {
            ++nRemoteUrl;
         }

         // remote-to-local duplicate check
         _str remoteRoot = xdebug_opts.remoteFileMap[i].remoteRoot;
         if( remoteRoot != "" ) {
            if( remote2local_dup_set._indexin(pathToHashKey(remoteRoot)) ) {
               // Park the user on the problem
               _str msg = nls("More than one entry for remote-to-local mapping:\n\n%s",remoteRoot);
               _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
               ctl_options_tab.sstActivateTabByCaption("Run");
               p_window_id = ctl_mappings;
               _set_focus();
               selectMapping(i+1);
               return false;
            }
            // New remote-to-local mapping
            remote2local_dup_set:[pathToHashKey(remoteRoot)] = 1;
            ++nRemoteRoot;
         }
      }

      if( nLocalRoot == 0 ) {
         msg := "Please specify at least one mapping.";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         ctl_options_tab.sstActivateTabByCaption("Run");
         p_window_id = ctl_mappings;
         _set_focus();
         return false;
      }
      if( nRemoteUrl == 0 ) {
         msg := "Please specify a URL.";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         ctl_options_tab.sstActivateTabByCaption("Run");
         p_window_id = ctl_mappings;
         _set_focus();
         return false;
      }
      if( nRemoteRoot == 0 && isAppTypeRemote(php_opts.appType) ) {
         msg := "Please specify a remote directory.";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         ctl_options_tab.sstActivateTabByCaption("Run");
         p_window_id = ctl_mappings;
         _set_focus();
         return false;
      }
   }

   if( xdebug_opts.serverHost == "" ) {
      msg := "Invalid/missing Xdebug host";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      ctl_options_tab.sstActivateTabByCaption("Debug");
      p_window_id = ctl_server_host;
      _set_sel(1,length(p_text)+1);
      _set_focus();
      return false;
   }
   if( xdebug_opts.serverPort == "" || vssServiceNameToPort(xdebug_opts.serverPort) < 0 ) {
      msg := "Invalid/missing Xdebug port";
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
                                     PhpOptions (&all_php_opts):[],
                                     PhpOptions& default_php_opts,
                                     XdebugOptions (&all_xdebug_opts):[],
                                     XdebugOptions& default_xdebug_opts)
{
   if( default_php_opts == null ) {
      // Fall back to generic default options
      makeDefaultPhpOptions(default_php_opts);
   }
   PhpOptions php_opts = null;
   if( default_xdebug_opts == null ) {
      // Fall back to generic default options
      xdebug_make_default_options(default_xdebug_opts);
   }
   XdebugOptions xdebug_opts = null;

   if( config == PROJ_ALL_CONFIGS ) {
      // If options do not match across all configs, then use default options instead
      php_opts = default_php_opts;
      xdebug_opts = default_xdebug_opts;
      _str last_cfg;
      _str cfg;

      // php_opts
      last_cfg = "";
      foreach( cfg=>. in all_php_opts ) {
         if( last_cfg != "" ) {
            if( all_php_opts:[last_cfg] != all_php_opts:[cfg] ) {
               // No match, so use default options
               php_opts = default_php_opts;
               break;
            }
         }
         // Match (or first config)
         php_opts = all_php_opts:[cfg];
         last_cfg = cfg;
      }

      // xdebug_opts
      last_cfg = "";
      foreach( cfg=>. in all_xdebug_opts ) {
         if( last_cfg != "" ) {
            if( all_xdebug_opts:[last_cfg] != all_xdebug_opts:[cfg] ) {
               // No match, so use default options
               xdebug_opts = default_xdebug_opts;
               break;
            }
         }
         // Match (or first config)
         xdebug_opts = all_xdebug_opts:[cfg];
         last_cfg = cfg;
      }
   } else {
      php_opts = all_php_opts:[config];
      xdebug_opts = all_xdebug_opts:[config];
   }

   //
   // Run tab
   //

   // Default file
   ctl_default_file.p_text = php_opts.defaultFile;

   // Script arguments
   ctl_script_args.p_text = php_opts.scriptArgs;

   // Interpreter arguments
   ctl_interpreter_args.p_text = php_opts.interpreterArgs;

   // File mapping
   resetMappingsTree();
   int i, n=php_opts.urlMap._length();
   for( i=0; i < n; ++i ) {
      _str localRoot = php_opts.urlMap[i].localRoot;
      if( localRoot == null ) {
         localRoot = "";
      }
      _str remoteRoot = xdebug_opts.remoteFileMap[i].remoteRoot;
      if( remoteRoot == null ) {
         remoteRoot = "";
      }
      _str remoteUrl = php_opts.urlMap[i].remoteUrl;
      if( remoteUrl == null ) {
         remoteUrl = "";
      }
      mapline :=  localRoot"\t"remoteRoot"\t"remoteUrl;
      int index = ctl_mappings._TreeAddItem(TREE_ROOT_INDEX,mapline,TREE_ADD_AS_CHILD,0,0,-1);
   }

   // Run as
   int old_changingRunAs = (int)changingRunAs(1);
   ctl_run_as.p_text = "";
   foreach( auto ii=>auto item in gRunModeMap ) {
      _str cap, val;
      parse item with cap'='val;
      if( php_opts.appType == val ) {
         // Found it
         ctl_run_as._lbfind_and_select_item(cap);
         break;
      }
   }
   if( ctl_run_as.p_text == "" ) {
      // Bad
      _message_box("Warning: Could not find run mode type: '":+php_opts.appType:+"'.","",MB_OK|MB_ICONEXCLAMATION);
      ctl_run_as._lbtop();
      ctl_run_as._lbselect_line();
      ctl_run_as.p_text = ctl_run_as._lbget_text();
   }
   changingRunAs(old_changingRunAs);
   ctl_run_as.call_event(CHANGE_CLINE,ctl_run_as,ON_CHANGE,'w');

   //
   // Debug tab
   //

   ctl_server_host.p_text = xdebug_opts.serverHost;
   ctl_server_port.p_text = xdebug_opts.serverPort;
   ctl_listen_on_startup.p_value = (int)xdebug_opts.listenInBackground;
   ctl_stay_in_debugger.p_value = (int)xdebug_opts.stayInDebugger;

   // When a debugger connection is requested:
   int old_changingAcceptConnections = (int)changingAcceptConnections(1);
   ctl_accept_connections.p_text = "";
   foreach( ii=>item in gAcceptConnectionsMap ) {
      _str cap, val;
      parse item with cap'='val;
      if( xdebug_opts.acceptConnections == val ) {
         // Found it
         ctl_accept_connections._lbfind_and_select_item(cap);
         break;
      }
   }
   if( ctl_accept_connections.p_text == "" ) {
      // Bad
      _message_box("Warning: Could not find item for AcceptConnections: '":+xdebug_opts.acceptConnections:+"'.","",MB_OK|MB_ICONEXCLAMATION);
      ctl_accept_connections._lbtop();
      ctl_accept_connections._lbselect_line();
      ctl_accept_connections.p_text = ctl_accept_connections._lbget_text();
   }
   changingAcceptConnections(old_changingAcceptConnections);
   ctl_accept_connections.call_event(CHANGE_CLINE,ctl_accept_connections,ON_CHANGE,'w');
   ctl_listen_on_startup.call_event(ctl_listen_on_startup,LBUTTON_UP,'w');

   // Break in a new debugger session
   int old_changingBreakInSession = (int)changingBreakInSession(1);
   ctl_break_in_session.p_text = "";
   foreach( ii=>item in gBreakInSessionMap ) {
      _str cap, val;
      parse item with cap'='val;
      if( xdebug_opts.breakInSession == val ) {
         // Found it
         ctl_break_in_session._lbfind_and_select_item(cap);
         break;
      }
   }
   if( ctl_break_in_session.p_text == "" ) {
      // Bad
      _message_box("Warning: Could not find item for BreakInSession: '":+xdebug_opts.breakInSession:+"'.","",MB_OK|MB_ICONEXCLAMATION);
      ctl_break_in_session._lbtop();
      ctl_break_in_session._lbselect_line();
      ctl_break_in_session.p_text = ctl_break_in_session._lbget_text();
   }
   changingBreakInSession(old_changingBreakInSession);
   ctl_break_in_session.call_event(CHANGE_CLINE,ctl_break_in_session,ON_CHANGE,'w');

   // DBGp features
   ctl_show_hidden.p_value = (int)xdebug_opts.dbgp_features.show_hidden;
}

static void savePhpOptionsForConfig(_str config, PhpOptions& php_opts, PhpOptions (&all_php_opts):[])
{
   // Gather up all affected config names
   _str configIndices[] = null;
   if( config == PROJ_ALL_CONFIGS ) {
      // All configurations get the same settings
      _str cfg;
      foreach( cfg=>. in all_php_opts ) {
         configIndices[configIndices._length()] = cfg;
      }
   } else {
      configIndices[0] = config;
   }

   // Now save options for affected configs
   int i;
   for( i=0; i < configIndices._length(); ++i ) {
      _str cfg = configIndices[i];
      all_php_opts:[cfg] = php_opts;
   }
}

static void saveXdebugOptionsForConfig(_str config, XdebugOptions& xdebug_opts, XdebugOptions (&all_xdebug_opts):[])
{
   // Gather up all affected config names
   _str configIndices[];
   if( config == PROJ_ALL_CONFIGS ) {
      // All configurations get the same settings
      _str cfg;
      foreach( cfg=>. in all_xdebug_opts ) {
         configIndices[configIndices._length()] = cfg;
      }
   } else {
      configIndices[0] = config;
   }

   // Now save options for affected configs
   int i;
   for( i=0; i < configIndices._length(); ++i ) {
      _str cfg = configIndices[i];
      all_xdebug_opts:[cfg] = xdebug_opts;
   }
}

static bool changeCurrentConfig(_str config)
{
   success := false;

   int old_changing_config = (int)changingCurrentConfig(1);

   do {

      _str lastConfig = _GetDialogInfoHt("lastConfig");
      PhpOptions php_opts;
      XdebugOptions xdebug_opts;
      if( !validateFormOptions(php_opts,xdebug_opts) ) {
         // Bad options
         break;
      }
   
      // All good, save these settings
      PhpOptions (*pAllPhpOpts):[] = _GetDialogInfoHtPtr("allPhpOpts");
      XdebugOptions (*pAllXdebugOpts):[] = _GetDialogInfoHtPtr("allXdebugOpts");
      savePhpOptionsForConfig(lastConfig,php_opts,*pAllPhpOpts);
      saveXdebugOptionsForConfig(lastConfig,xdebug_opts,*pAllXdebugOpts);
   
      // Set form options for new config.
      // "All Configurations" case:
      // If switching to "All Configurations" and configs do not match, then use
      // last options for the default. This is better than blasting the user's
      // settings completely with generic default options.
      lastConfig = config;
      _SetDialogInfoHt("lastConfig",lastConfig);
      setFormOptionsFromConfig(lastConfig,
                               *pAllPhpOpts,php_opts,
                               *pAllXdebugOpts,xdebug_opts);
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

void ctl_run_as.on_change(int reason)
{
   if( changingRunAs() ) {
      return;
   }
   _str appType = mapRunModeCaption2Value(p_text);
   is_web := isAppTypeWeb(appType);

   ctl_script_args.p_enabled = !is_web;
   ctl_interpreter_args.p_enabled = !is_web;
   ctl_interpreter_arg_button.p_enabled = !is_web;

   ctl_mapping_frame.p_enabled = is_web;
   // Disabling the frame is not enough to give a good visual
   // indication, so must disable more.
   ctl_mappings.p_enabled = is_web;
   ctl_map_add.p_enabled = is_web;
   ctl_map_remove.p_enabled = is_web;

   if( ctl_mapping_frame.p_enabled ) {
#if 0 //4:50pm 9/1/2011
      int width, flags, state;
      _str caption;
      ctl_mappings._TreeGetColButtonInfo(1,width,flags,state,caption);
      if( isAppTypeLocal(appType) ) {
         // Local web server - remote-root is same as local-root, so
         // disable editing "Remote directory" column.
         flags &= ~TREE_BUTTON_EDITABLE;
      } else {
         // Remote web server
         flags |= TREE_BUTTON_EDITABLE;
      }
      ctl_mappings._TreeSetColButtonInfo(1,width,flags,state,caption);
#else
      flags := 0;
      if( !isAppTypeLocal(appType) ) flags=TREE_EDIT_TEXTBOX;
      ctl_mappings._TreeSetColEditStyle(1,flags);
#endif
   }
}

void ctl_browse_default_file.lbutton_up()
{
   wildcards := "PHP Files (*.php;*.php3)";
   format_list := "";
   parse def_file_types with 'HTML Files' +0 format_list',';
   if( format_list == "" ) {
      // Fall back
      format_list = "HTML Files (*.htm;*.html;*.shtml;*.asp;*.jsp;*.php;*.php3;*.rhtml;*.css)";
   }

   // Try to be smart about the initial directory
   int projectHandle = _GetDialogInfoHt("projectHandle");
   _str init_dir = _ProjectGet_WorkingDir(projectHandle);
   if( isAppTypeWeb(mapRunModeCaption2Value(ctl_run_as.p_text)) ) {
      // Web app. Find a mapping that has a URL since it is probably
      // what they want.
      PhpOptions php_opts;
      getFormOptions(php_opts,null);
      PhpUrlMapping map;
      foreach( auto ii=>map in php_opts.urlMap ) {
         // .localRoot should never be "", but check anyway
         if( map.remoteUrl != "" && map.localRoot != "" ) {
            init_dir = map.localRoot;
            break;
         }
      }
   } else {
      // Command-line script, so the default is fine.
   }

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

_command void ctlinsertPhpInterpreterArg(_str text="", _str delim='%') name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   _str opt;
   parse text with opt text;
   if( opt == '-c' || opt == '-d' ) {

      textbox_wid := p_active_form._find_control('ctl_interpreter_args');

      // Preserve selection in text box
      int start_pos, end_pos;
      textbox_wid._get_sel(start_pos,end_pos);

      result := "";
      if( opt == '-c' ) {
         // Prompt for config path
         result = _ChooseDirDialog("Choose php.ini Directory","","",CDN_PATH_MUST_EXIST);
         if( result != "" ) {
            _maybe_strip_filesep(result);
            result = '-c '_maybe_quote_filename(result);
         }
      } else {
         // -d foo[=bar]
         _str name, value;
         int status = _mdi.textBoxDialog("-d name[=value]",
                                         0,
                                         0,
                                         "",
                                         "OK,Cancel:_cancel\tDefine INI entry name=value pair.",  // Button List
                                         "",
                                         "Name:",
                                         "Value:");
         if( status < 0 || _param1 == "" ) {
            // Probably COMMAND_CANCELLED_RC
            return;
         }

         result = '-d '_param1;
         if( _param2 != "" ) {
            result :+= '='_param2;
         }
      }

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
      ctlinsert(result' ',delim);

      return;
   }
   // Nothing special
   ctlinsert(text,delim);
}

static void selectInterpreterArgMenu()
{
   int index = find_index("_temp_interpreter_arg_menu",oi2type(OI_MENU));
   if( index ) {
      delete_name(index);
   }
   index = insert_name("_temp_interpreter_arg_menu",oi2type(OI_MENU));
   _str caption;
   _menu_insert(index,-1,0,"&Look for php.ini in this directory",'ctlinsertPhpInterpreterArg -c <path> ');
   _menu_insert(index,-1,0,"&Define INI entry foo with value 'bar'",'ctlinsertPhpInterpreterArg -d foo[=bar] ');
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
   _str appType = mapRunModeCaption2Value(ctl_run_as.p_text);
   is_apptype_local := isAppTypeLocal(appType);
   // Note: Assumed to be a web-type apptype since we would not be here otherwise

   // Prompt user for local-root, remote-root, remote-url
   status := 0;
   if( is_apptype_local ) {
      status = _mdi.textBoxDialog("File Mapping",
                                  0,
                                  ctl_mappings.p_width,
                                  "",
                                  "OK,Cancel:_cancel\tSpecify the local directory along with its corresponding URL. Specify the remote directory of the web server.",  // ButtonNCaption list
                                  "",
                                  "-bd Local directory:",
                                  "URL:");
   } else {
      // Remote apptype, so must include prompt for remote-dir
      status = _mdi.textBoxDialog("File Mapping",
                                  0,
                                  ctl_mappings.p_width,
                                  "",
                                  "OK,Cancel:_cancel\tSpecify the local directory along with its corresponding URL. Specify the remote directory of the web server.",  // ButtonNCaption list
                                  "",
                                  "-bd Local directory:",
                                  "URL:",
                                  "Remote directory:");
   }
   if( status < 0 ) {
      // Probably COMMAND_CANCELLED_RC
      return;
   }

   _str localRoot = _param1;
   _str remoteUrl = _param2;
   remoteRoot := "";
   if( is_apptype_local ) {
      remoteRoot = localRoot;
   } else {
      remoteRoot = _param3;
   }
   mapline :=  localRoot"\t"remoteRoot"\t"remoteUrl;
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
      // Note: isAppTypeWeb==true is implicit because command-line
      // scripts do not use mappings.
      if( col == 0 && isAppTypeLocal(mapRunModeCaption2Value(ctl_run_as.p_text)) ) {
         // Local web server - remote-root is same as local-root
         mapline := _TreeGetCaption(index);
         _str remoteUrl;
         parse mapline with ."\t"."\t"remoteUrl;
         mapline = text"\t"text"\t"remoteUrl;
         _TreeSetCaption(index,mapline);
      }
      break;
   }
}

void ctl_mappings.'DEL'()
{
   ctl_map_remove.call_event(ctl_map_remove,LBUTTON_UP,'w');
}

void ctl_browse_php_exe.lbutton_up()
{
   _str wildcards = _isUnix()?"":"Executable Files (*.exe;*.com;*.bat;*.cmd)";
   _str format_list = wildcards;

   // Try to be smart about the initial filename and directory
   init_dir := "";
   init_filename := ctl_php_exe_path.p_text;
   if( init_filename == "" ) {
      init_filename = guessPhpExePath();
   }
   if( init_filename != "" ) {
      // Strip off the 'php' exe to leave the directory
      init_dir = _strip_filename(init_filename,'N');
      _maybe_strip_filesep(init_dir);
      // Strip directory off 'php' exe to leave filename-only
      init_filename = _strip_filename(init_filename,'P');
   }

   _str result = _OpenDialog("-modal",
                             "PHP Interpreter",
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

void ctl_listen_on_startup.lbutton_up()
{
   ctl_accept_connections.p_enabled = ( p_value != 0 );
}

void ctl_accept_connections.on_change(int reason)
{
   if( changingAcceptConnections() ) {
      return;
   }
}

void ctl_break_in_session.on_change(int reason)
{
   if( changingBreakInSession() ) {
      return;
   }
}

static void onCreateRunTab()
{
   // Run as
   changingRunAs(1);
   foreach( auto ii=>auto item in gRunModeMap ) {
      _str cap, val;
      parse item with cap'='val;
      ctl_run_as._lbadd_item(cap);
   }
   ctl_run_as._lbtop();
   ctl_run_as._lbselect_line();
   ctl_run_as.p_text = ctl_run_as._lbget_text();
   changingRunAs(0);

   // Mappings tree
   int col_width = ctl_mappings.p_width intdiv 3;
   int remain_width = ctl_mappings.p_width - 3*col_width;
   ctl_mappings._TreeSetColButtonInfo(0,col_width,0,-1,"Local Directory");
   ctl_mappings._TreeSetColEditStyle(0,TREE_EDIT_TEXTBOX);
   ctl_mappings._TreeSetColButtonInfo(1,col_width,0,-1,"Remote Directory");
   ctl_mappings._TreeSetColEditStyle(1,TREE_EDIT_TEXTBOX);
   ctl_mappings._TreeSetColButtonInfo(2,col_width+remain_width,0,-1,"URL");
   ctl_mappings._TreeSetColEditStyle(2,TREE_EDIT_TEXTBOX);
}

static void onCreateDebugTab()
{
   if (_isUnix()) {
      // Dialog color
      ctl_xdebug_note.p_backcolor = 0x80000022;
   }

   // Get rid of scrollbars if possible
   ctl_xdebug_note._minihtml_ShrinkToFit();

   // When a debugger connection is requested:
   changingAcceptConnections(1);
   foreach( auto ii=>auto item in gAcceptConnectionsMap ) {
      _str cap, val;
      parse item with cap'='val;
      ctl_accept_connections._lbadd_item(cap);
   }
   ctl_accept_connections._lbtop();
   ctl_accept_connections._lbselect_line();
   ctl_accept_connections.p_text = ctl_accept_connections._lbget_text();
   changingAcceptConnections(0);

   // Break in a new debugger session:
   changingBreakInSession(1);
   foreach( ii=>item in gBreakInSessionMap ) {
      _str cap, val;
      parse item with cap'='val;
      ctl_break_in_session._lbadd_item(cap);
   }
   ctl_break_in_session._lbtop();
   ctl_break_in_session._lbselect_line();
   ctl_break_in_session.p_text = ctl_break_in_session._lbget_text();
   changingBreakInSession(0);
}

void ctl_ok.on_create(int projectHandle, _str options="", _str currentConfig="",
                     _str projectFilename=_project_name, bool isProjectTemplate=false)
{
   _SetDialogInfoHt("projectHandle",projectHandle);
   _SetDialogInfoHt("isProjectTemplate",isProjectTemplate);

   _php_options_form_initial_alignment();

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

   changingCurrentConfig(1);
   orig_wid := p_window_id;

   p_window_id = ctl_current_config.p_window_id;
   _str configList[];
   _ProjectGet_ConfigNames(projectHandle,configList);
   int i;
   for( i=0; i < configList._length(); ++i ) {
      if( strieq(_ProjectGet_Type(projectHandle,configList[i]),"php") ) {
         _lbadd_item(configList[i]);
         continue;
      }
      // This config does not belong
      configList._deleteel(i);
      --i;
   }
   // "All Configurations" config
   _lbadd_item(PROJ_ALL_CONFIGS);
   if( _lbfind_and_select_item(currentConfig) ) {
      _lbfind_and_select_item(PROJ_ALL_CONFIGS, '', true);
   }
   lastConfig := ctl_current_config.p_text;

   p_window_id = orig_wid;
   changingCurrentConfig(0);

   PhpOptions allPhpOpts:[] = null;
   XdebugOptions allXdebugOpts:[] = null;
   getProjectPhpOptions(projectHandle,configList,allPhpOpts);
   xdebug_project_get_options(projectHandle,configList,allXdebugOpts);

   _SetDialogInfoHt("configList",configList);
   _SetDialogInfoHt("lastConfig",lastConfig);
   _SetDialogInfoHt("allPhpOpts",allPhpOpts);
   _SetDialogInfoHt("allXdebugOpts",allXdebugOpts);

   // Initialize form with options.
   // Note: Cannot simply call ctl_current_config.ON_CHANGE because
   // we do not want initial values validated (they might not be valid).
   // Note: It is not possible (through the GUI) to bring up the
   // options dialog without at least 1 configuration.
   setFormOptionsFromConfig(lastConfig,
                            allPhpOpts,allPhpOpts:[ configList[0] ],
                            allXdebugOpts,allXdebugOpts:[ configList[0] ]);
   ctl_php_exe_path.p_text = guessPhpExePath();

   if( tabName == "" ) {
      ctl_options_tab._retrieve_value();
   } else {
      // Select the proper tab
      ctl_options_tab.sstActivateTabByCaption("tabName");
   }
}

void _php_options_form.on_load()
{
   setting_environment := 0 != _GetDialogInfoHt("setting_environment");

   if( setting_environment ) {
      phpExePath := ctl_php_exe_path.p_text;
      msg := "";
      if( phpExePath != "" ) {
         msg = "Warning: The PHP interpreter path has been automatically found for this project.";
         msg :+= "\n\nPlease verify the PHP interpreter is correct on the Options dialog that follows (\"Build\", \"PHP Options\").";
      } else {
         msg = "Warning: The PHP interpreter path is not set for this project.";
         msg :+= "Please set the PHP interpreter on the Options dialog that follows (\"Build\", \"PHP Options\").";
      }
      p_window_id = ctl_php_exe_path;
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
   PhpOptions (*pAllPhpOpts):[] = _GetDialogInfoHtPtr("allPhpOpts");
   XdebugOptions (*pAllXdebugOpts):[] = _GetDialogInfoHtPtr("allXdebugOpts");
   setProjectOptions(projectHandle,configList,*pAllPhpOpts,*pAllXdebugOpts);

   // PHP interpreter path
   phpExePath := ctl_php_exe_path.p_text;
   if( phpExePath != def_php_exe_path ) {
      def_php_exe_path = phpExePath;
      // Flag state file modified
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }

   // Do not shutdown/restart the server if we are in the middle
   // of prompting for environment settings in order to start a
   // debugging session (otherwise you pull the rug/server out
   // from under the Xdebug monitor).
   setting_environment := 0 != _GetDialogInfoHt("setting_environment");
   if( !setting_environment ) {
      // Inform that the project config has changed, which will
      // trigger a server restart, or leave it shut down if
      // listenInBackground=false. Must _post_call this since
      // the project settings are not saved yet.
      _post_call(find_index('_prjconfig_xdebug',PROC_TYPE));
   }

   // Success
   p_active_form._delete_window(0);
}

void ctl_cancel.lbutton_up()
{
   p_active_form._delete_window("");
}

static void onResizeMappingFrame(int deltax, int deltay)
{
   // ctl_mappings tree
   ctl_mappings.p_width += deltax;
   ctl_mappings.p_height += deltay;
   // Add, Remove buttons
   ctl_map_remove.p_x += deltax;
   ctl_map_remove.p_y += deltay;
   ctl_map_add.p_x += deltax;
   ctl_map_add.p_y += deltay;
}

static void onResizeRunFrame(int deltax, int deltay)
{
   // Default file
   ctl_default_file.p_width += deltax;
   // Default file browse button
   ctl_browse_default_file.p_x += deltax;
   // Script arguments
   ctl_script_args.p_width += deltax;
   // Interpreter arguments
   ctl_interpreter_args.p_width += deltax;
   // Interpreter argument menu button
   ctl_interpreter_arg_button.p_x += deltax;
}

static void onResizeRunTab(int deltax, int deltay)
{
   // Run as
   ctl_run_as.p_width += deltax;
   // Run frame
   ctl_run_frame.p_width += deltax;
   onResizeRunFrame(deltax, deltay);
   // File mapping frame
   ctl_mapping_frame.p_width += deltax;
   ctl_mapping_frame.p_height += deltay;
   onResizeMappingFrame(deltax, deltay);
}

static void onResizeXdebugFrame()
{
}

static void onResizeDebugTab(int deltax, int deltay)
{
   // Xdebug server settings frame
   ctl_xdebug_frame.p_width += deltax;
}

static void onResizeOptions(int deltax, int deltay)
{
   onResizeRunTab(deltax, deltay);
   onResizeDebugTab(deltax, deltay);
}

void _php_options_form.on_resize()
{
   // Enforce sanity on size
   // if the minimum width has not been set, it will return 0
   if (!_minimum_width()) {
      _set_minimum_size(PHPOPTS_FORM_MINWIDTH, PHPOPTS_FORM_MINHEIGHT);
   }

   deltax := p_width - (ctl_current_config.p_x_extent + 180);
   deltay := p_height - (ctl_ok.p_y_extent + 180);

   // Settings for:
   ctl_current_config.p_width += deltax;
   // OK, Cancel
   ctl_ok.p_y += deltay;
   ctl_cancel.p_y = ctl_ok.p_y;
   // PHP interpreter:
   ctl_php_exe_path.p_width += deltax;
   ctl_php_exe_path.p_y += deltay;
   ctl_browse_php_exe.p_x += deltax;
   ctl_browse_php_exe.p_y += deltay;
   ctl_php_exe_path_label.p_y += deltay;

   // Tab control
   ctl_options_tab.p_width += deltax;
   ctl_options_tab.p_height += deltay;
   ctl_options_tab.onResizeOptions(deltax, deltay);
}

_command void phpoptions(_str options="") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build system");
      return;
   }
   if( _project_name == "" ) {
      // What are we doing here?
      msg := "No project. Cannot set options.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return;
   }

   mou_hour_glass(true);
   projectFilesNotNeeded(1);
   int project_prop_wid = show('-hidden -app -xy _project_form',_project_name,_ProjectHandle(_project_name));
   mou_hour_glass(false);
   configName := GetCurrentConfigName();
   ctlbutton_wid := project_prop_wid._find_control('ctlcommand_options');
   typeless result = ctlbutton_wid.call_event('_php_options_form 'options,configName,ctlbutton_wid,LBUTTON_UP,'w');
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

//
// PHP project wizard
//

defeventtab _php_wizard_form;

/**
 * Skip the n'th slide?
 * 
 * @param num        Slide number to skip. Slide numbers start 
 *                   at 0.
 * @param new_value  Set to 1 (true) to skip. Set to 0 (false) 
 *                   to NOT skip. Set to -1 to retrieve current
 *                   value.
 * 
 * @return True if slide will be skipped.
 */
static bool skipSlideByNumber(int num, int new_value=-1)
{
   WIZARD_INFO* info = _WizardGetPointerToInfo();

   if( new_value != -1 ) {
      info->callbackTable:['ctlslide'num'.skip'] = new_value !=0 ? 1 : null;
   }
   return ( info->callbackTable:['ctlslide'num'.skip'] != null );
}

/**
 * Skip the "Web Server URL" slide?
 * 
 * @param new_value  Set to 1 (true) to skip. Set to 0 (false) 
 *                   to NOT skip. Set to -1 to retrieve current
 *                   value.
 * 
 * @return True if slide will be skipped.
 */
static bool skipUrlSlide(int new_value=-1)
{
   return skipSlideByNumber(1,new_value);
}

/**
 * Skip the "Local Document Directory" slide?
 * 
 * @param new_value  Set to 1 (true) to skip. Set to 0 (false) 
 *                   to NOT skip. Set to -1 to retrieve current
 *                   value.
 * 
 * @return True if slide will be skipped.
 */
static bool skipLocalSlide(int new_value=-1)
{
   return skipSlideByNumber(2,new_value);
}

/**
 * Skip the "Remote Document Directory" slide?
 * 
 * @param new_value  Set to 1 (true) to skip. Set to 0 (false) 
 *                   to NOT skip. Set to -1 to retrieve current
 *                   value.
 * 
 * @return True if slide will be skipped.
 */
static bool skipRemoteSlide(int new_value=-1)
{
   return skipSlideByNumber(3,new_value);
}

static _str createUrlHint(PhpOptions* php_opts)
{
   hint := "";
   if( isAppTypeRemote(php_opts->appType) ) {
      // Remote web app
      hint = 'http://myhost.com/content';
   } else {
      // Local web app
      hint = 'http://localhost/content';
   }
   return hint;
}

static int phpwiz_slide0_create()
{
   _nocheck _control ctlslide0;
   _nocheck _control ctl_apptype_web_local;
   _nocheck _control ctl_apptype_web_remote;
   _nocheck _control ctl_apptype_cli_local;

   // Stuff default PHP options into the form
   PhpOptions php_opts;
   makeDefaultPhpOptions(php_opts);
   _SetDialogInfoHt("PhpOptions",php_opts,ctlslide0.p_active_form);
   // Stuff default Xdebug options into the form
   XdebugOptions xdebug_opts;
   xdebug_make_default_options(xdebug_opts);
   _SetDialogInfoHt("XdebugOptions",xdebug_opts,ctlslide0.p_active_form);
   // Add files from local root directory to project automatically?
   _SetDialogInfoHt("add_local_root_files",false,ctlslide0.p_active_form);

   // Default apptype
   if( isAppTypeWeb(php_opts.appType) ) {
      if( isAppTypeLocal(php_opts.appType) ) {
         ctl_apptype_web_local.p_value = 1;
         skipUrlSlide(0);
         skipLocalSlide(0);
         skipRemoteSlide(1);
      } else {
         // Remote
         ctl_apptype_web_remote.p_value = 1;
         skipUrlSlide(0);
         skipLocalSlide(0);
         skipRemoteSlide(0);
      }
   } else {
      // Command-line script
      ctl_apptype_cli_local.p_value = 1;
      skipUrlSlide(1);
      skipLocalSlide(1);
      skipRemoteSlide(1);
   }

   // All good
   return 0;
}

static int phpwiz_slide0_shown()
{
   // All good
   return 0;
}

static int phpwiz_slide0_next()
{
   _nocheck _control ctlslide0;
   _nocheck _control ctl_apptype_web_local;
   _nocheck _control ctl_apptype_web_remote;
   _nocheck _control ctl_apptype_cli_local;

   // Retrieve project options
   PhpOptions* php_opts = _GetDialogInfoHtPtr("PhpOptions",ctlslide0.p_active_form);
   XdebugOptions* xdebug_opts = _GetDialogInfoHtPtr("XdebugOptions",ctlslide0.p_active_form);

   if( ctl_apptype_web_local.p_value != 0 ) {
      php_opts->appType = "web-local";
      skipUrlSlide(0);
      skipLocalSlide(0);
      skipRemoteSlide(1);
   } else if( ctl_apptype_web_remote.p_value != 0 ) {
      php_opts->appType = "web-remote";
      skipUrlSlide(0);
      skipLocalSlide(0);
      skipRemoteSlide(0);
   } else if( ctl_apptype_cli_local.p_value != 0 ) {
      // Command line local script
      php_opts->appType = "cli-local";
      skipUrlSlide(1);
      skipLocalSlide(1);
      skipRemoteSlide(1);
   } else {
      _assert(false,"Should not get here");
      return INVALID_ARGUMENT_RC;
   }

   // All good
   return 0;
}

static int phpwiz_slide1_create()
{
   _nocheck _control ctlslide0;
   _nocheck _control ctl_url;
   _nocheck _control ctl_url_hint;

   // Retrieve project options
   PhpOptions* php_opts = _GetDialogInfoHtPtr("PhpOptions",ctlslide0.p_active_form);

   // Initial URL?
   if( php_opts->urlMap._length() > 0 ) {
      ctl_url.p_text = php_opts->urlMap[0].remoteUrl;
   } else {
      if( isAppTypeLocal(php_opts->appType) ) {
         ctl_url.p_text = "http://localhost";
      } else {
         ctl_url.p_text = "";
      }
   }

   // All good
   return 0;
}

static int phpwiz_slide1_shown()
{
   _nocheck _control ctlslide0;
   _nocheck _control ctl_url;
   _nocheck _control ctl_url_hint;

   // Retrieve project options
   PhpOptions* php_opts = _GetDialogInfoHtPtr("PhpOptions",ctlslide0.p_active_form);

   // Customize URL hint based on local or remote web app
   ctl_url_hint.p_caption = 'Example: 'createUrlHint(php_opts);

   // All good
   return 0;
}

static int phpwiz_slide1_next()
{
   _nocheck _control ctlslide0;
   _nocheck _control ctl_url;
   _nocheck _control ctl_url_hint;

   // Retrieve project options
   PhpOptions* php_opts = _GetDialogInfoHtPtr("PhpOptions",ctlslide0.p_active_form);

   // localRoot gets set on the next slide
   localRoot := "";

   remoteUrl := ctl_url.p_text;
   if( remoteUrl == "" ) {
      _str msg = nls("Please provide a valid URL (example: %s).",createUrlHint(php_opts));
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      p_window_id = ctl_url;
      _set_sel(1,length(p_text)+1);
      _set_focus();
      return 1;
   } else if( substr(lowcase(remoteUrl),1,length("http")) != "http" &&
              substr(lowcase(remoteUrl),1,length("http")) != "https" ) {

      _str msg = nls("Invalid URL (example: %s).",createUrlHint(php_opts));
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      p_window_id = ctl_url;
      _set_sel(1,length(p_text)+1);
      _set_focus();
      return 1;
   }

   // Set project options
   php_opts->urlMap[0].remoteUrl = remoteUrl;
   php_opts->urlMap[0].localRoot = localRoot;

   // All good
   return 0;
}

static int phpwiz_slide2_create()
{
   _nocheck _control ctlslide0;
   _nocheck _control ctl_local_root;
   _nocheck _control ctl_local_url_reminder;
   _nocheck _control ctl_browse_dir;

   // Retrieve project options
   PhpOptions* php_opts = _GetDialogInfoHtPtr("PhpOptions",ctlslide0.p_active_form);
   sizeBrowseButtonToTextBox(ctl_local_root.p_window_id, ctl_browse_dir.p_window_id, 0, ctlslide0.p_active_form.p_width - ctl_local_root.p_prev.p_x);

   _str localRoot = php_opts->urlMap[0].localRoot;
   if( localRoot != "" ) {
      // We have an initial local root directory, so use it
      ctl_local_root.p_text = localRoot;
   } else {
      // Local root directory not set yet, default to project working directory
      ctl_local_root.p_text = _parse_project_command('%rw','',_project_name,'');
   }

   // All good
   return 0;
}

static int phpwiz_slide2_shown()
{
   _nocheck _control ctlslide0;
   _nocheck _control ctl_local_root;
   _nocheck _control ctl_local_url_reminder;

   // Retrieve project options
   PhpOptions* php_opts = _GetDialogInfoHtPtr("PhpOptions",ctlslide0.p_active_form);

   // URL
   ctl_local_url_reminder.p_caption = php_opts->urlMap[0].remoteUrl;

   // Add files from this directory to my project?
   ctl_add_local_root_files.p_enabled = ( ctl_local_root.p_text != "" );

   // All good
   return 0;
}

static int phpwiz_slide2_next()
{
   _nocheck _control ctlslide0;
   _nocheck _control ctl_local_root;

   // Retrieve project options
   PhpOptions* php_opts = _GetDialogInfoHtPtr("PhpOptions",ctlslide0.p_active_form);
   XdebugOptions* xdebug_opts = _GetDialogInfoHtPtr("XdebugOptions",ctlslide0.p_active_form);
   bool* add_local_root_files = _GetDialogInfoHtPtr("add_local_root_files",ctlslide0.p_active_form);

   localRoot := ctl_local_root.p_text;
   if( localRoot == "" ) {
      msg := "Invalid local root directory.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      p_window_id = ctl_local_root;
      _set_sel(1,length(p_text)+1);
      _set_focus();
      return 1;
   } else if( !isdirectory(localRoot) ) {
      msg := "Local root directory does not exist.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      p_window_id = ctl_local_root;
      _set_sel(1,length(p_text)+1);
      _set_focus();
      return 1;
   }

   // Set project options
   php_opts->urlMap[0].localRoot = localRoot;
   // Note: urlMap[0].remoteUrl set in previous slide

   // Note:
   // php_opts use local_root<=>remote_url mappings
   // xdebug_opts use local_root<=>remote_root mappings
   // Both mappings share local_root in common.

   xdebug_opts->remoteFileMap[0].localRoot = localRoot;
   if( isAppTypeWeb(php_opts->appType) ) {
      if( isAppTypeLocal(php_opts->appType) ) {
         // Web-local app, so set remoteRoot same as localRoot
         xdebug_opts->remoteFileMap[0].remoteRoot = localRoot;
      } else {
         // Web-remote app
         // remoteRoot will be set in the "Remote Document Directory" slide
         xdebug_opts->remoteFileMap[0].remoteRoot = "";
      }
   }

   // Add files from this directory to my project?
   *add_local_root_files = ( ctl_add_local_root_files.p_enabled && ctl_add_local_root_files.p_value != 0 );

   // All good
   return 0;
}

static int phpwiz_slide3_create()
{
   _nocheck _control ctl_remote_root;
   _nocheck _control ctl_remote_root_hint;

   // Retrieve project options
   XdebugOptions* xdebug_opts = _GetDialogInfoHtPtr("XdebugOptions",ctlslide0.p_active_form);

   // Initial remote root directory
   ctl_remote_root.p_text = xdebug_opts->remoteFileMap[0].remoteRoot;

   // Remote root directory hint
   ctl_remote_root_hint.p_caption = 'Example: /var/www/html/content';

   // All good
   return 0;
}

static int phpwiz_slide3_shown()
{
   _nocheck _control ctlslide0;
   _nocheck _control ctl_remote_url_reminder;
   _nocheck _control ctl_remote_local_reminder;
   _nocheck _control ctl_remote_root;
   _nocheck _control ctl_remote_root_hint;

   // Retrieve project options
   PhpOptions* php_opts = _GetDialogInfoHtPtr("PhpOptions",ctlslide0.p_active_form);
   XdebugOptions* xdebug_opts = _GetDialogInfoHtPtr("XdebugOptions",ctlslide0.p_active_form);

   // URL reminder
   ctl_remote_url_reminder.p_caption = php_opts->urlMap[0].remoteUrl;

   // Local root directory reminder
   ctl_remote_local_reminder.p_caption = php_opts->urlMap[0].localRoot;

   // Remote root directory
   if( ctl_remote_root.p_text != "" ) {
      // User has already set the remote root directory, so no need for a hint
      ctl_remote_root_hint.p_visible = false;
   } else {
      // User has not chosen a remote directory yet, so show them a little hint
      ctl_remote_root_hint.p_visible = true;
   }

   // All good
   return 0;
}

static int phpwiz_slide3_next()
{
   _nocheck _control ctlslide0;
   _nocheck _control ctl_remote_url_reminder;
   _nocheck _control ctl_remote_root;

   // Retrieve project options
   PhpOptions* php_opts = _GetDialogInfoHtPtr("PhpOptions",ctlslide0.p_active_form);
   XdebugOptions* xdebug_opts = _GetDialogInfoHtPtr("XdebugOptions",ctlslide0.p_active_form);

   remoteRoot := ctl_remote_root.p_text;
   if( remoteRoot == "" ) {
      msg := "Invalid remote root directory.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      p_window_id = ctl_remote_root;
      _set_sel(1,length(p_text)+1);
      _set_focus();
      return 1;
   }

   // Set project options
   xdebug_opts->remoteFileMap[0].remoteRoot = remoteRoot;

   // All good
   return 0;
}

static int phpwiz_slide4_create()
{
   _nocheck _control ctl_summary;

   if (_isUnix()) {
      // Dialog color
      ctl_summary.p_backcolor = 0x80000022;
   }

   // All good
   return 0;
}

static int phpwiz_slide4_shown()
{
   _nocheck _control ctlslide0;
   _nocheck _control ctl_summary;

   // Retrieve project options
   PhpOptions* php_opts = _GetDialogInfoHtPtr("PhpOptions",ctlslide0.p_active_form);
   XdebugOptions* xdebug_opts = _GetDialogInfoHtPtr("XdebugOptions",ctlslide0.p_active_form);
   bool* add_local_root_files = _GetDialogInfoHtPtr("add_local_root_files",ctlslide0.p_active_form);

   text := "";
   text :+= '<p style="font-family:'VSDEFAULT_DIALOG_FONT_NAME'; font-size:10pt">';
   if( isAppTypeWeb(php_opts->appType) ) {
      if( isAppTypeLocal(php_opts->appType) ) {
         text :+= '<dt><b>Application type:</b> <dd>Local web server</dd></dt>';
      } else {
         // Remote
         text :+= '<dt><b>Application type:</b> <dd>Remote web server</dd></dt>';
      }
      text :+= nls('<dt><b>Local directory:</b> <dd>%s</dd></dt>',php_opts->urlMap[0].localRoot);
      text :+= nls('<dt><b>URL:</b> <dd>%s</dd></dt>',php_opts->urlMap[0].remoteUrl);
      if( php_opts->urlMap[0].localRoot != xdebug_opts->remoteFileMap[0].remoteRoot ) {
         text :+= nls('<dt><b>Remote directory:</b> <dd>%s</dd></dt>',xdebug_opts->remoteFileMap[0].remoteRoot);
      }
   } else {
      text :+= '<dt><b>Application type:</b> <dd>Local script</dd></dt>';
   }
   text :+= nls('<dt><b>Debug listener:</b> <dd>%s on port %s</dd></dt>',xdebug_opts->serverHost,xdebug_opts->serverPort);
   text :+= '';
   text :+= '</p>';
   text :+= '<p style="font-family:'VSDEFAULT_DIALOG_FONT_NAME'; font-size:10pt">';
   if( *add_local_root_files ) {
      text :+= nls('<dt><b>Files will be added to project from:</b> <dd>%s</dd></dt>',php_opts->urlMap[0].localRoot);
   } else {
      text :+= '<dt><b>Files will not be added to project.</b> <dd>You can add files from Project>Project Properties menu</dd></dt>';
   }
   text :+= '</p>';
   ctl_summary.p_text = text;

   // All good
   return 0;
}

static int phpwiz_slide4_next()
{
   // All good
   return 0;
}

static int phpwiz_finish()
{
   _nocheck _control ctlslide0;

   // Retrieve project options
   PhpOptions* php_opts = _GetDialogInfoHtPtr("PhpOptions",ctlslide0.p_active_form);
   XdebugOptions* xdebug_opts = _GetDialogInfoHtPtr("XdebugOptions",ctlslide0.p_active_form);
   bool* add_local_root_files = _GetDialogInfoHtPtr("add_local_root_files",ctlslide0.p_active_form);

   // Bonus options
   xdebug_opts->acceptConnections = 'prompt';
   xdebug_opts->breakInSession = 'step-into';
   xdebug_opts->stayInDebugger = isAppTypeWeb(php_opts->appType);

   // Save project options for all configs
   int projectHandle = _ProjectHandle();
   _str configList[] = null;
   _ProjectGet_ConfigNames(projectHandle,configList);
   foreach( auto ii=>auto config in configList ) {
      setProjectOptionsForConfig(projectHandle,config,*php_opts,*xdebug_opts);
   }

   // Did user elect to have local-root directory files added to project?
   if( *add_local_root_files ) {

      _str localRoot = php_opts->urlMap[0].localRoot;
      _maybe_strip_filesep(localRoot);
      if( localRoot != "" ) {

         // Assemble list of files to add
         int temp_wid;
         int orig_wid = _create_temp_view(temp_wid);
         _delete_line();
         _str lang = _Ext2LangId('php');
         _str wildcards = _GetWildcardsForLanguage(lang);
         filespec := "";
         while( wildcards != "" ) {
            parse wildcards with filespec ';' wildcards;
            insert_file_list('-d +t +p -v 'localRoot:+FILESEP:+filespec);
         }
         _str file_list[] = null;
         _str rel_list[] = null;
         _str f;
         top(); up();
         while( !down() ) {
            get_line(f);
            if( f != "" ) {
               f = strip(f);
               file_list[file_list._length()] = f;
               rel_list[rel_list._length()] = _RelativeToProject(f);
            }
         }
         _delete_temp_view(temp_wid);
         p_window_id = orig_wid;

         // Add list of files to project for all configs
         if( file_list._length() > 0 ) {
            _ProjectAdd_Files(projectHandle,rel_list);
            AddFilesToTagFile(file_list);
            toolbarUpdateFilterList(_project_name);
         }
      }
   }

   //// If no files yet, bring up Project Properties dialog and put them on the Files tab
   //int files_node = _ProjectGet_FilesNode(projectHandle);
   //if( files_node >=0  ) {
   //   _str nodeList[] = null;
   //   _xmlcfg_find_simple_array(projectHandle,'//'VPJTAG_F,nodeList,files_node);
   //   if( nodeList._length() == 0 ) {
   //      project_edit(PROJECTPROPERTIES_TABINDEX_FILES);
   //   }
   //}

   // Save the project file
   _ProjectSave(projectHandle);
   // Let everybody know there's a new project in town
   call_list('_prjupdate_');

   // Make sure project init gets done for Xdebug
   _prjconfig_xdebug();

   // All good
   return 0;
}

void ctl_browse_dir.lbutton_up()
{
   textbox_wid := p_prev;
   _str localRoot = _parse_project_command(textbox_wid.p_text,"",_project_name,"");
   localRoot = absolute(localRoot,_strip_filename(_project_name,'N'));
   _str result = _ChooseDirDialog("",localRoot,"",CDN_PATH_MUST_EXIST);
   if( result == "" ) {
      return;
   }

   textbox_wid.p_text = result;
   textbox_wid._set_focus();
}

_command int php_project_wizard() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build system");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   WIZARD_INFO info;

   // Set up callback table
   info.callbackTable._makeempty();
   // Application Type
   info.callbackTable:["ctlslide0.create"] = phpwiz_slide0_create;
   info.callbackTable:["ctlslide0.shown"]  = phpwiz_slide0_shown;
   info.callbackTable:["ctlslide0.next"]   = phpwiz_slide0_next;
   info.callbackTable:["ctlslide0.skip"]   = null;
   // Web Server URL
   info.callbackTable:["ctlslide1.create"] = phpwiz_slide1_create;
   info.callbackTable:["ctlslide1.shown"]  = phpwiz_slide1_shown;
   info.callbackTable:["ctlslide1.next"]   = phpwiz_slide1_next;
   info.callbackTable:["ctlslide1.skip"]   = null;
   // Local Document Directory
   info.callbackTable:["ctlslide2.create"] = phpwiz_slide2_create;
   info.callbackTable:["ctlslide2.shown"]  = phpwiz_slide2_shown;
   info.callbackTable:["ctlslide2.next"]   = phpwiz_slide2_next;
   info.callbackTable:["ctlslide2.skip"]   = null;
   // Remote Document Directory
   info.callbackTable:["ctlslide3.create"] = phpwiz_slide3_create;
   info.callbackTable:["ctlslide3.shown"]  = phpwiz_slide3_shown;
   info.callbackTable:["ctlslide3.next"]   = phpwiz_slide3_next;
   info.callbackTable:["ctlslide3.skip"]   = null;
   // Summary
   info.callbackTable:["ctlslide4.create"] = phpwiz_slide4_create;
   info.callbackTable:["ctlslide4.shown"]  = phpwiz_slide4_shown;
   info.callbackTable:["ctlslide4.next"]   = phpwiz_slide4_next;
   info.callbackTable:["ctlslide4.skip"]   = null;
   // Finish
   info.callbackTable:["finish"]           = phpwiz_finish;

   // The form with all the slides
   info.parentFormName = "_php_wizard_form";

   // Wizard caption
   info.dialogCaption = "Create PHP Project";

   // Start the wizard
   int status = _Wizard(&info);

   return status;
}

