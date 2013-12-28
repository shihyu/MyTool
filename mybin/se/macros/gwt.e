////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47140 $
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
#import "stdprocs.e"
#import "stdcmds.e"
#import "applet.e"
#import "clipbd.e"
#import "compile.e"
#import "guicd.e"
#import "guiopen.e"
#import "main.e"
#import "picture.e"
#import "projconv.e"
#import "ptoolbar.e"
#import "project.e"
#import "slickc.e"
#import "tags.e"
#import "tbcmds.e"
#import "wkspace.e"
#endregion

#define GWT_USER "gwt-user.jar"
#define GWT_DEV "gwt-dev"
#define GWT_WEBAPPCREATOR "webAppCreator"
#define GWT_APPENGINE_EXE "appcfg"

static _str jarFileFilter = "JAR files (*.jar)";

_command int new_gwt_python_application()
{
   int status=show('-modal _gwt_python_form');
   if (status) {
      if (status=='') {
         return(COMMAND_CANCELLED_RC);
      } else {
         return(status);
      }
   }
   // after the dialog closes, if we have been successful, activate and refresh 'Projects' 
   _gwt_updateProjects();
   return(0);
}

defeventtab _gwt_python_form;

void _gwt_python_form.on_create()
{
   ctltag.p_value=1;
}

void _gwt_python_form.'ESC'()
{
   p_active_form._delete_window(''); 
}

void gwt_python_ok.lbutton_up()
{
   _str gwt = gwt_python_loc_box.p_text;
   _str name = strip(gwt_python_name_box.p_text);
   _str port = strip(gwt_port_box.p_text);
   // input validation...
   if (port != '' && (!isinteger(port) || (int)port <= 0)) {
      _message_box('Server port must be a positive integer.');
      return;
   }
   if (!isid_valid(name)) {
      _message_box('Application Name must be a valid identifier.');
      return;
   }
   if (!_gwt_isValidAppEngineLoc(gwt,true)) {
      return;
   }
   int tag = ctltag.p_value;
   typeless *pfnOkButton=setupGWTPythonProject;
   int status=(*pfnOkButton)(name, gwt, port, tag);
   if (!status || status==COMMAND_CANCELLED_RC) {
      p_active_form._delete_window(status);
   }
}

_command int new_gwt_application()
{
   int status=show('-modal _gwt_form');
   if (status) {
      if (status=='') {
         return(COMMAND_CANCELLED_RC);
      } else {
         return(status);
      }
   }
   // after the dialog closes, if we have been successful, activate and refresh 'Projects' 
   _gwt_updateProjects();
   return(0);
}

/**
 * Activate a refresh 'Projects' tool window.  Used after a new 
 * GWT app is created. 
 */
void _gwt_updateProjects(){
   activate_projects();
   int tree_wid = _find_object("_tbprojects_form._proj_tooltab_tree");
   if (tree_wid) {
      int orig_wid = p_window_id;
      p_window_id = tree_wid;
      projecttbRefresh();
      p_window_id = orig_wid;
   }
}

defeventtab _gwt_form;

void _gwt_form.'ESC'()
{
   p_active_form._delete_window(''); 
}

void _gwt_form.on_create()
{
   _gwt_form_initial_alignment();

   ctltag.p_value=1;
   ctlcpath.p_value=0;
   ctltagappengine.p_value=1;
   ctltagjunit.p_value=1;
   // center the picture within the correct space
   int rightBound = gwt_frame.p_x + gwt_frame.p_width;
   int leftBound = gwt_name_box.p_x + gwt_name_box.p_width;
   int centerSpace = leftBound + (rightBound - leftBound) / 2;
   ctlimage1.p_x = centerSpace - (ctlimage1.p_width / 2);
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _gwt_form_initial_alignment()
{
   rightAlign := gwt_frame.p_width - gwt_loc_label.p_x;
   sizeBrowseButtonToTextBox(gwt_loc_box.p_window_id, gwt_loc_browse.p_window_id, 0, rightAlign);
   sizeBrowseButtonToTextBox(gwt_junit_box.p_window_id, gwt_junit_browse.p_window_id, 0, rightAlign);
   sizeBrowseButtonToTextBox(gwt_appengine_loc_box.p_window_id, gwt_appengine_loc_browse.p_window_id, 0, rightAlign);
}

void gwt_ok.lbutton_up()
{
   _str package = strip(package_box.p_text);
   _str gwt = gwt_loc_box.p_text;
   _str name = strip(gwt_name_box.p_text);
   _str id = strip(gwt_id_box.p_text);
   _str appengine = gwt_appengine_loc_box.p_text;
   _str junit = gwt_junit_box.p_text;
   // input validation...
   if (!is_valid_java_package(package)) {
      _message_box('Package Name must be a valid Java package identifier.');
      return;
   }
   if (!isid_valid(name)) {
      _message_box('Application Name must be a valid Java identifier.');
      return;
   }
   if (!is_valid_gwt_app_id(id)) {
      _message_box('Application ID must be between 6 and 30 characters long, and can only ':+
                   'contain lowercase letters, numbers, and hyphens.');
      return;
   }
   int taggwt = ctltag.p_value;
   int tagappengine = ctltagappengine.p_value;
   int tagjunit = ctltagjunit.p_value;
   int setupCpath = ctlcpath.p_value;
   if (!_gwt_isValidAppEngineLoc(appengine)) {
      return;
   }
   if (!_gwt_isValidGwtLoc(gwt)) {
      return;
   }
   _str appCfgCmd = '';
   // check the gwt app engine sdk directory for validity and compose the 'update' command
   _maybe_append_filesep(appengine);
#if __UNIX__
   appCfgCmd=appengine:+'bin':+FILESEP:+GWT_APPENGINE_EXE:+'.sh';
#else
   appCfgCmd=maybe_quote_filename(appengine:+'bin':+FILESEP:+GWT_APPENGINE_EXE);
#endif
   // after input is validated, create a GWT application project
   // doing this twice now (composing these jars), so this is not optimal
   _maybe_append_filesep(gwt);
   _str gwt_user_jar = gwt :+ GWT_USER;
   _str gwt_webappcreator_script = gwt :+ GWT_WEBAPPCREATOR;
   _str gwt_dev_jar = file_match(maybe_quote_filename(gwt :+ GWT_DEV),1);
   _str gwt_jars = gwt_dev_jar :+ PATHSEP :+ gwt_user_jar :+ PATHSEP;
   typeless *pfnOkButton=setupGWTProject;
   int status=(*pfnOkButton)(gwt_webappcreator_script, name, package, gwt_jars, id, appCfgCmd, taggwt, tagappengine,
                             appengine, tagjunit, junit, setupCpath);
   if (!status || status==COMMAND_CANCELLED_RC) {
      p_active_form._delete_window(status);
   }
}

void gwt_cancel.lbutton_up()
{
   p_active_form._delete_window(''); 
}

void gwt_loc_browse.lbutton_up()
{
   int wid=p_window_id;
   _str result = _ChooseDirDialog('',p_prev.p_text);
   if ( result=='' ) {
      return;
   }
   p_window_id=wid.p_prev;
   p_text=result;
   end_line();
   _set_focus();
   return;
}

void gwt_junit_browse.lbutton_up()
{
   int wid=p_window_id;
   _str file = _OpenDialog("-modal", "Select JUnit JAR", "*.jar", jarFileFilter, OFN_FILEMUSTEXIST);
   if ( file=='' ) {
      return;
   }
   p_window_id=wid.p_prev;
   file=stranslate(file,"","\"");
   p_text=file;
   end_line();
   _set_focus();
   return;
}

/**
 * Return whether or not a string is a valid Java package.  This differs 
 * slightly from isid_valid, in that the string beginning with p_ would not be
 * invalid, and the '.' character would not be allowed. 
 * 
 * @param pkg 
 * 
 * @return boolean 
 */
boolean is_valid_java_package(_str pkg='')
{
   if (pkg=='') {
      return false;
   }
   if (pos('[~A-Za-z0-9_$\.]',pkg,1,'r')) {
      return false;
   }
   if (isinteger(substr(pkg,1,1))) {
      return false;
   }
   return true;
}

/**
 * Return whether or not a Google Application ID is valid.  A valid ID is 
 * between 6 and 30 characters long, and contains only lowercase letters, 
 * digits, and hyphens. 
 * 
 * @param id 
 * 
 * @return boolean 
 */
boolean is_valid_gwt_app_id(_str id='')
{
   if (id=='') {
      return true;
   }
   if (length(id) < 6 || length(id) > 30) {
      return false;
   }
   if (pos('[~a-z0-9\-]',id,1,'r')) {
      return false;
   }
   return true;
}

/**
 * Runs the GWT webAppCreator script, adds the appropriate files to the project, 
 * sets up the project classpath, and sets up the build/rebuild/execute/debug 
 * commands. 
 * 
 * @param webAppCreator 
 * @param name 
 * @param pkg 
 * @param gwt_jars 
 * @param appId 
 * 
 * @return int 
 */
static int setupGWTProject(_str webAppCreator='', _str name='', _str pkg='', _str gwtJARs='',
                           _str appId='', _str appCfgCmd='', int tag=0, int tagappengine=0,
                           _str appengine='', int tagjunit=0, _str junit='', int setupCpath=0)
{
   _str projectDir = _file_path(_project_name);
   int projectHandle = _ProjectHandle();
   _maybe_append_filesep(projectDir);
   // run webAppCreator to generate the project source
   _str cmd = maybe_quote_filename(webAppCreator):+' -out 'projectDir:+' '; 
   if (junit != '') {
      cmd :+= '-junit ':+maybe_quote_filename(junit):+' ';
   }
   cmd :+= pkg'.'name;
   int status = shell(cmd, 'Q');
   if (status) {
      _message_box("Unable to execute " :+ webAppCreator': 'get_message(status));
      return 1;
   }
   // add all appropriate files to the project 
   _gwt_addWildcardsToProject(projectHandle);
   parse gwtJARs with auto devjar PATHSEP auto userjar PATHSEP;
   // possibly generate the appengine-web.xml file for deploying on Google App Engine
   if (appId != '') {
      _str appEngineXML = projectDir :+ 'war' :+ FILESEP :+ 'WEB-INF' :+ FILESEP :+ 'appengine-web.xml';
      appEngineXML = maybe_quote_filename(appEngineXML);
      _gwt_createAppEngineXMLFile(appEngineXML, appId, 1);
   }
   // the project classpath must have the source directory, the war/WEB-INF/classes directory,
   // and the necessary gwt jars
   _str cpath = projectDir :+ 'src' :+ PATHSEP;
   if (setupCpath) {
      cpath = cpath :+ projectDir :+ 'war' :+ FILESEP :+ 'WEB-INF' :+ FILESEP :+ 'classes' :+ PATHSEP;
      cpath = cpath :+ projectDir :+ 'war' :+ FILESEP :+ 'WEB-INF' :+ FILESEP :+ 'lib' :+ PATHSEP;
      cpath = cpath :+ gwtJARs;
      if (appengine != '') {
         cpath = cpath :+ _gwt_findAllJars(appengine'lib'FILESEP'user'FILESEP);
         cpath = cpath :+ _gwt_findAllJars(appengine'lib'FILESEP'shared'FILESEP);
         cpath = cpath :+ _gwt_findAllJars(appengine'lib'FILESEP'appengine-tools', false);
      }
   }
   _ProjectGet_AllConfigsInfo(projectHandle,auto info, auto configList);
   // 1.7.1 and earlier uses 'HostedMode' to launch, 2.0.0 and later should use 'DevMode'
   _str launchClass = 'HostedMode';
   _str buildFile = projectDir :+ 'build.xml';
   int handle = _xmlcfg_open(buildFile, status, VSXMLCFG_OPEN_REFCOUNT);
   _str executeTarget = 'hosted';
   if (handle >=0) {
      if (_gwt_buildFileHasDevMode(handle)) {
         launchClass = 'DevMode';
         executeTarget = 'devmode';
      }
      _gwt_generateDebugTarget(handle,'com.google.gwt.dev.'launchClass,name,pkg'.'name);
      _xmlcfg_close(handle);
   }
   // loop through each config, setting the classpath and the build/execute/debug commands
   int i = 0;
   for (i = 0; i < configList._length(); i++) {
      _str cfg = configList[i];
      if (setupCpath) {
         _ProjectSet_ClassPathList(projectHandle,cpath,cfg);
      }
      _ProjectSet_TargetCmdLine(projectHandle,_ProjectGet_TargetNode(projectHandle,'build',cfg),
         'antmake -emacs -f build.xml');
      _ProjectSet_TargetCmdLine(projectHandle,_ProjectGet_TargetNode(projectHandle,'rebuild',cfg),
         'antmake -emacs -f build.xml clean build');
      _ProjectSet_TargetCmdLine(projectHandle,_ProjectGet_TargetNode(projectHandle,'execute',cfg),
         'antmake -emacs -f build.xml 'executeTarget);
      _ProjectSet_TargetBuildFirst(projectHandle,_ProjectGet_TargetNode(projectHandle,'execute',cfg),false);
      _ProjectSet_TargetCmdLine(projectHandle,_ProjectGet_TargetNode(projectHandle,'debug',cfg),
         'antmake -emacs -f build.xml debug');
      _ProjectSet_TargetBuildFirst(projectHandle,_ProjectGet_TargetNode(projectHandle,'debug',cfg),false);
      _ProjectAdd_Target(projectHandle,'DeployScript',appCfgCmd,'',cfg,"Never","");
      _ProjectAdd_Target(projectHandle,'DeployProject','gwt-deploy-app','&Deploy Project...',cfg,"Always",
                           "Slick-C");
   }
   // save the project and we are done
   _ProjectSave(projectHandle);
   def_antmake_use_classpath = 0;
   _config_modify_flags(CFGMODIFY_DEFVAR);
   // create tag file for gwt sdk
   if (tag) {
      _str gwtDir = _strip_filename(devjar,'N');
      _str version = _gwt_getVersionFromDir(gwtDir);
      _str basename = 'gwt-sdk';
      if (version != '') {
         basename :+= '-'version;
      }
      _str tagfilename=absolute(_tagfiles_path():+basename:+TAG_FILE_EXT);
      if (!ext_MaybeRecycleTagFile(auto tf, auto tagfn, 'java', basename)) {
         ext_BuildTagFile(tf, tagfilename, 'java', '', false, maybe_quote_filename(devjar):+' ':+
            maybe_quote_filename(userjar));
      }
   }
   // create tag file for appengine
   if (tagappengine && appengine != '') {
      _str basename = 'java-appengine';
      _str tagfilename=absolute(_tagfiles_path():+basename:+TAG_FILE_EXT);
      _str pathlist = maybe_quote_filename(appengine:+'lib':+FILESEP:+'user':+FILESEP:+'*.jar');
      pathlist :+= ' ' :+ maybe_quote_filename(appengine:+'lib':+FILESEP:+'shared':+FILESEP:+'*.jar');
      pathlist :+= ' ' :+ maybe_quote_filename(appengine:+'lib':+FILESEP:+'appengine-tools-api.jar');
      if (!ext_MaybeRecycleTagFile(auto tf, auto tagfn, 'java', basename)) {
         ext_BuildTagFile(tf, tagfilename, 'java', '', true, pathlist);
      }
   }
   // create tag file for junit 
   if (tagjunit && junit != '') {
      _str basename = 'junit';
      _str tagfilename=absolute(_tagfiles_path():+basename:+TAG_FILE_EXT);
      _str pathlist = maybe_quote_filename(junit);
      if (!ext_MaybeRecycleTagFile(auto tf, auto tagfn, 'java', basename)) {
         ext_BuildTagFile(tf, tagfilename, 'java', '', false, pathlist);
      }
   }
   return 0;
}

/**
 * Runs the GWT webAppCreator script, adds the appropriate files to the project, 
 * sets up the project classpath, and sets up the build/rebuild/execute/debug 
 * commands. 
 * 
 * @param webAppCreator 
 * @param name 
 * @param pkg 
 * @param gwt_jars 
 * @param appId 
 * 
 * @return int 
 */
static int setupGWTPythonProject(_str name, _str appengine, _str port, int tag)
{
   _str projectDir = _file_path(_project_name);
   int projectHandle = _ProjectHandle();
   _maybe_append_filesep(projectDir);
   _maybe_append_filesep(appengine);
   // generate the app.yaml file
   _str appEngineYAML = projectDir :+ 'app.yaml';
   appEngineYAML = maybe_quote_filename(appEngineYAML);
   _gwt_createAppEngineYAMLFile(appEngineYAML, name, 1);
   // generate the python application file
   _str appPythonFile = projectDir :+ name :+ '.py';
   appPythonFile = maybe_quote_filename(appPythonFile);
   _gwt_createAppPythonFile(appPythonFile, name, 1);
   // add the appropriate wildcards to the propject
   _ProjectAdd_Wildcard(projectHandle, "*.py","",true); 
   _ProjectAdd_Wildcard(projectHandle, "*.yaml","",true); 
   _ProjectGet_AllConfigsInfo(projectHandle,auto info, auto configList);
   if (port == '') {
      port = '8080';
   }
   _str exeLine = '"%(SLICKEDIT_PYTHON_EXE)" %(SLICKEDIT_PYTHON_EXECUTE_ARGS) ';
   exeLine :+= maybe_quote_filename(appengine:+'dev_appserver.py')' %~other';
   _str deployScript = maybe_quote_filename(appengine:+'appcfg.py');
   int i = 0;
   // loop through each config, setting the execute command
   for (i = 0; i < configList._length(); i++) {
      _str cfg = configList[i];
      int execNode = _ProjectGet_TargetNode(projectHandle,'execute',cfg);
      _ProjectSet_TargetCmdLine(projectHandle,execNode,exeLine,null,'-p 'port' .');
#if __UNIX__
      _ProjectSet_TargetRunInXterm(projectHandle,execNode,true);
      _ProjectSet_TargetCaptureOutputWith(projectHandle,execNode,"");
#endif
      _ProjectSet_TargetBuildFirst(projectHandle,_ProjectGet_TargetNode(projectHandle,'execute',cfg),false);
      _ProjectAdd_Target(projectHandle,'DeployScript',deployScript,'',cfg,"Never","");
      _ProjectAdd_Target(projectHandle,'DeployProject','gwt-deploy-app','&Deploy Project...',cfg,"Always",
         "Slick-C");
   }
   // save the project
   _ProjectSave(projectHandle);
   // possibly create tag file for gwt libraries
   if (tag) {
      _str versionFile = appengine :+ "VERSION"; 
      _str version = '';
      int status = _open_temp_view(versionFile, auto temp_wid, auto orig_wid);
      if (!status) {
         top();up();
         while (!down()) {
            get_line(auto line);
            if (pos('release: ',line) > 0) {
               parse line with . 'release: "' version '"';
               version = strip(version);
               break;
            }
         }
         _delete_temp_view(temp_wid);
         p_window_id = orig_wid;
      }
      _str basename = 'python-appengine';
      if (version != '') {
         basename :+= '-'version;
      }
      if (!ext_MaybeRecycleTagFile(auto tf, auto tagfn, 'py', basename)) {
         _str pathList = maybe_quote_filename(appengine:+'google':+FILESEP:+'*.py');
         _str tagfilename=absolute(_tagfiles_path():+basename:+TAG_FILE_EXT);
         ext_BuildTagFile(tf, tagfilename, 'py', '', true, pathList);
      }
   }
   return 0;
}

_command void gwt_deploy_app() name_info(',')
{
   show('-mdi -modal -xy _gwt_deploy_form');
}

defeventtab _gwt_deploy_form;

void gwtDeployEmailBox.'ENTER'()
{
   _nocheck _control gwtDeployBtn; 
   gwtDeployEmailBox.call_event(gwtDeployBtn,LBUTTON_UP);
}

void gwtDeployBtn.lbutton_up()
{
   _str email = strip(gwtDeployEmailBox.p_text);
   int projectHandle = _ProjectHandle();
   _str projectDir = _file_path(_project_name);
   _maybe_append_filesep(projectDir);
   boolean isJava = _ProjectGet_ActiveType() == 'java';
   // validate email
   if (!_gwt_emailIsValid(email)) {
      _message_box("Please enter a valid e-mail address.");  
      return;
   }
   int deployScriptNode = _ProjectGet_TargetNode(projectHandle,"DeployScript");
   if (deployScriptNode < 0) {
      if (isJava) {
         _message_box("The Google App Engine deploy command is not set up for this project.":+
                      " Please make sure the App Engine properties on the Java Options dialog are correct.");  
         show('-xy -wh _java_options_form',projectHandle,"Google",GetCurrentConfigName(),_project_name,0);
      } else {
         _message_box("The Google App Engine deploy command is not set up for this project.":+
                      " Please make sure the App Engine properties on the Python Options dialog are correct.");  
         show('-xy -wh _python_options_form',projectHandle,"Google",GetCurrentConfigName(),_project_name,0);
      }
      return;
   }
   _str deployScript = _ProjectGet_TargetCmdLine(projectHandle, deployScriptNode);
   _str deployCmd = '';
   if (deployScript == '') {
      if (isJava) {
         _message_box("The Google App Engine deploy command is not set up for this project.":+
                      " Please make sure the App Engine properties on the Java Options dialog are correct.");  
         show('-xy -wh _java_options_form',projectHandle,"Google",GetCurrentConfigName(),_project_name,0);
      } else {
         _message_box("The Google App Engine deploy command is not set up for this project.":+
                      " Please make sure the App Engine properties on the Python Options dialog are correct.");  
         show('-xy -wh _python_options_form',projectHandle,"Google",GetCurrentConfigName(),_project_name,0);
      }
      return;
   }
   p_active_form._delete_window(0);
   if (isJava) {
      deployCmd :+= deployScript;
      deployCmd :+= ' -e ' :+ email :+ ' update war';
   } else {
      _str python = get_env("SLICKEDIT_PYTHON_EXE");
      if (python == '') {
         _message_box("Python executable cannot be found.  Please specify location of the Python executable on the ":+
                      "Python Options dialog.");
         show('-xy -wh _python_options_form',projectHandle,"Google",GetCurrentConfigName(),_project_name,0);
         return;
      }
      deployCmd = maybe_quote_filename(python) :+ ' ' :+ deployScript :+ ' -e ' :+ email;
      deployCmd :+= ' update ' :+ maybe_quote_filename(projectDir); 
   }
   shell(deployCmd,'W');
}

void gwtCancelBtn.lbutton_up()
{
   p_active_form._delete_window(0);
}

void _gwt_deploy_form.'ESC'()
{
   p_active_form._delete_window(0);
}

/**
 * Add all appropriate wildcards to a GWT project: *.java, *.css, *.xml, *.html, 
 * and *.jar. 
 *  
 * @param handle 
 * @param excludeJava 
 */
void _gwt_addWildcardsToProject(int handle=0, boolean excludeJava=false)
{
   if (handle > 0) {
      if (!excludeJava) {
         _ProjectAdd_Wildcard(handle, "*.java","",true); 
      }
      _ProjectAdd_Wildcard(handle, "*.xml","",true); 
      _ProjectAdd_Wildcard(handle, "*.html","",true); 
      _ProjectAdd_Wildcard(handle, "*.css","",true); 
      _ProjectAdd_Wildcard(handle, "*.jar","",true); 
   }
}

/**
 * Parse a build.xml file, looking for certain targets and property nodes that 
 * indicate this is a GWT application. 
 * 
 * @param xmlBuildFile 
 * @param projectHandle 
 * @param sdkNode 
 * @param hostedNode 
 * @param gwtCP 
 * @param gwtAppName 
 * @param gwtFullName 
 * 
 * @return int 
 */
int _gwt_parseBuildFile(_str xmlBuildFile, int projectHandle, int &sdkNode, boolean &hasDevMode,
                        _str &gwtAppName, _str &gwtFullName)
{
   if (xmlBuildFile == '') {
      return 1;
   }
   int handle = _xmlcfg_open(xmlBuildFile, auto status, VSXMLCFG_OPEN_REFCOUNT);
   if(handle < 0 || status < 0) {
      return 1;
   }
   sdkNode = _xmlcfg_find_simple(handle, "/project/property[@name='gwt.sdk']");
   hasDevMode = _gwt_buildFileHasDevMode(handle);
   gwtAppName = '';
   gwtFullName = '';
   _str dir = _strip_filename(xmlBuildFile,'N');
   if(sdkNode >= 0) {
      _str val = _xmlcfg_get_attribute(handle, sdkNode, "location");
      if (val != '') {
         _maybe_append_filesep(val);
         _gwt_addWildcardsToProject(projectHandle, true);
         _str gwt_user_jar = val :+ GWT_USER;
         _str gwt_dev_jar = file_match(maybe_quote_filename(val :+ GWT_DEV),1);
         // assumes that the build.xml file is at the root of the project structure for this app
         int projectNode = _xmlcfg_find_simple(handle, "/project");
         if (projectNode >= 0) {
            gwtAppName = _xmlcfg_get_attribute(handle, projectNode, "name");
         }
         typeless hostedTargetArgNodes[];
         status = _xmlcfg_find_simple_array(handle, "/project/target[@name='hosted']/java/arg", 
                                             hostedTargetArgNodes); 
         if (hostedTargetArgNodes._length() > 0) {
            int k = 0;
            for (k = 0; k < hostedTargetArgNodes._length();k++) {
               _str argVal  = _xmlcfg_get_attribute(handle, hostedTargetArgNodes[k], "value");
               if (pos(gwtAppName,argVal) > 0 && pos('.html',argVal) == 0) {
                  gwtFullName = argVal;
               }
            }
         } else {
            typeless devmodeTargetArgNodes[];
            status = _xmlcfg_find_simple_array(handle, "/project/target[@name='devmode']/java/arg", 
                                                devmodeTargetArgNodes); 
            if (devmodeTargetArgNodes._length() > 0) {
               int k = 0;
               for (k = 0; k < devmodeTargetArgNodes._length();k++) {
                  _str argVal  = _xmlcfg_get_attribute(handle, devmodeTargetArgNodes[k], "value");
                  if (pos(gwtAppName,argVal) > 0 && pos('.html',argVal) == 0) {
                     gwtFullName = argVal;
                  }
               }
            } 
         }
         _str version = _gwt_getVersionFromDir(val);
         _str basename = 'gwt-sdk';
         if (version != '') {
            basename :+= '-'version;
         }
         _str tagfilename=absolute(_tagfiles_path():+basename:+TAG_FILE_EXT);
         if (!ext_MaybeRecycleTagFile(auto tf, auto tagfn, 'java', basename)) {
            ext_BuildTagFile(tf, tagfilename, 'java', '', false, maybe_quote_filename(gwt_dev_jar):+' ':+
               maybe_quote_filename(gwt_user_jar));
         }
      }
   }

   _xmlcfg_close(handle);
   return 0;
}

/**
 * Parse a python GWT project yaml file for the version and 
 * name of the app. 
 * 
 * @return status 
 */
int _gwt_parseProjectYAMLFile(_str &version, _str &id)
{
   _str projectDir = _file_path(_project_name);
   _maybe_append_filesep(projectDir);
   _str yamlFile = maybe_quote_filename(projectDir :+ 'app.yaml');
   if (file_exists(yamlFile)) {
      int status = _open_temp_view(yamlFile, auto temp_wid, auto orig_wid);
      if (!status) {
         top();up();
         boolean foundVersion = false;
         boolean foundID = false;
         while (!down() && (!foundVersion || !foundID)) {
            get_line(auto line);
            int index = pos('version: ',line);
            if (index > 0 && pos('api_version: ', line) == 0) {
               parse line with . 'version: ' version;
            } else if (pos('application: ',line) > 0){
               parse line with . 'application: ' id;
            }
         }
         _delete_temp_view(temp_wid);
         p_window_id = orig_wid;
         return status;
      }
   }
   return 1;
}

/**
 * Update the version of a python GWT app in the yaml file. 
 * 
 * @return status 
 */
int _gwt_pythonWriteAppInfo(_str version, _str id)
{
   int status = 1;
   _str projectDir = _file_path(_project_name);
   _maybe_append_filesep(projectDir);
   _str yamlFile = maybe_quote_filename(projectDir :+ 'app.yaml');
   if (file_exists(yamlFile)) {
      status = _open_temp_view(yamlFile, auto temp_wid, auto orig_wid);
      if (!status) {
         top();up();
         boolean foundVersion = false;
         boolean foundID = false;
         while (!down() && (!foundID || !foundVersion)) {
            get_line(auto line);
            int index = pos('version: ',line);
            if (index > 0 && pos('api_version: ', line) == 0) {
               replace_line('version: ' version);
               foundVersion = true;
            } else if (pos('application: ',line)) { 
               replace_line('application: ' id);
               foundID = true;
            }
         }
         status = _save_file("+o");
         _delete_temp_view(temp_wid);
         p_window_id = orig_wid;
      }
   }
   return status;
}

/**
 * Check email for validity.
 * 
 * @param email 
 * 
 * @return boolean 
 */
boolean _gwt_emailIsValid(_str email)
{
   if (email == '') {
      return false;
   }
   return true;
}

/**
 * Check if a directory contains a valid GWT installation. 
 * 
 * @param dir 
 * 
 * @return boolean 
 */
boolean _gwt_isValidGwtLoc(_str dir)
{
   if (dir == '' || !isdirectory(dir)) {
      _message_box('Location of Google Web Toolkit must be a directory.');
      return false;
   }
   _maybe_append_filesep(dir);
   _str gwt_user_jar = dir :+ GWT_USER;
   _str gwt_webappcreator_script = dir :+ GWT_WEBAPPCREATOR;
   _str gwt_dev_jar = file_match(maybe_quote_filename(dir :+ GWT_DEV),1);
#if !__UNIX__
   gwt_webappcreator_script = gwt_webappcreator_script :+ ".cmd";
#endif
   if (!file_exists(gwt_user_jar) || !file_exists(gwt_webappcreator_script) || !file_exists(gwt_dev_jar)) {
      _message_box('Google Web Toolkit installation is missing components, or contains an unsupported ':+
                   'version (1.5 or earlier).');
      return false;
   }
   return true;
}

/**
 * Check if a directory contains a valid Google App Engine SDK. If 'dir' is the 
 * empty string, returns true. 
 * 
 * @param dir 
 * @param python 
 * 
 * @return boolean 
 */
boolean _gwt_isValidAppEngineLoc(_str dir, boolean python=false)
{
   if (dir == '') {
      if (python) {
         _message_box('Location of Google App Engine SDK must be a directory.');
      }
      return !python;
   }
   if (!isdirectory(dir)) {
      _message_box('Location of Google App Engine SDK must be a directory.');
      return false;
   }
   _maybe_append_filesep(dir);
   _str appcfgExe = '';
   if (python) {
      appcfgExe = file_match(maybe_quote_filename(dir:+GWT_APPENGINE_EXE),1);
   } else {
      appcfgExe = file_match(maybe_quote_filename(dir:+'bin':+FILESEP:+GWT_APPENGINE_EXE),1);
   }
   if (!file_exists(appcfgExe)) {
      _message_box('Google App Engine SDK installation is missing components, or contains an unsupported ':+
                   'version (1.2.5 or earlier).');
      return false;
   }
   return true;
}

/**
 * Create a new appengine-web.xml file for deploying GWT applications on the 
 * Google AppEngine.
 * 
 * @param file 
 * @param id 
 * @param version 
 */
void _gwt_createAppEngineXMLFile(_str file, _str id, int version)
{
   int status = _open_temp_view(file,auto temp_wid,auto orig_wid,'',auto bae,false,false,0,true);
   if (!status) {
      insert_line('<?xml version="1.0" encoding="utf-8"?>');
      top_of_buffer();
      delete_line();
      down();
      insert_line('<appengine-web-app xmlns="http://appengine.google.com/ns/1.0">');
      insert_line('  <application>'id'</application>');
      insert_line('  <version>'version'</version>');
      insert_line('');
      insert_line('  <!-- Configure java.util.logging -->');
      insert_line('  <system-properties>');
      insert_line('     <property name="java.util.logging.config.file" value="WEB-INF/logging.properties"/>');
      insert_line('  </system-properties>');
      insert_line('</appengine-web-app>');
      _save_file();
      _delete_temp_view(temp_wid);
      p_window_id = orig_wid; 
   }
}

/**
 * Create a new .yaml file for deploying GWT applications on the 
 * Google AppEngine. 
 * 
 * @param file 
 * @param id 
 * @param version 
 */
void _gwt_createAppEngineYAMLFile(_str file, _str name, int version)
{
   int status = _open_temp_view(file,auto temp_wid,auto orig_wid,'',auto bae,false,false,0,true);
   if (!status) {
      insert_line('application: ' name);
      top_of_buffer();
      delete_line();
      down();
      insert_line('version: ' version);
      insert_line('runtime: python');
      insert_line('api_version: 1');
      insert_line('');
      insert_line('handlers:');
      insert_line('- url: /.*');
      insert_line('  script: ' name '.py');
      _save_file();
      _delete_temp_view(temp_wid);
      p_window_id = orig_wid; 
   }
}

/**
 * Create a new python file for a GWT application.
 * 
 * @param file
 * @param name
 * @param version
 */
void _gwt_createAppPythonFile(_str file, _str name, int version)
{
   int status = _open_temp_view(file,auto temp_wid,auto orig_wid,'',auto bae,false,false,0,true);
   if (!status) {
      insert_line('import wsgiref.handlers');
      top_of_buffer();
      delete_line();
      down();
      insert_line('');
      insert_line('from google.appengine.ext import webapp');
      insert_line('');
      insert_line('class MainHandler(webapp.RequestHandler):');
      insert_line('  def get(self):');
      insert_line("    self.response.out.write('Hello, world!')");
      insert_line('');
      insert_line('def main():');
      insert_line("  application = webapp.WSGIApplication([('/', MainHandler)],");
      insert_line('                                       debug=True)');
      insert_line('  wsgiref.handlers.CGIHandler().run(application)');
      insert_line('');
      insert_line('if __name__ == "__main__":');
      insert_line('  main()');
      _save_file();
      _delete_temp_view(temp_wid);
      p_window_id = orig_wid; 
   }
}

_str _gwt_getDebugJDWPCommand(int handle)
{
   _str address = '';
   int jdwp = _xmlcfg_find_simple(handle,'/project/target[@name="debug"]/java/jvmarg[contains(@value,"-Xrunjdwp")]');
   if (jdwp >= 0) {
      address = _xmlcfg_get_attribute(handle, jdwp, 'value');
   }
   return address;
}

void _gwt_generateDebugTarget(int handle, _str googleClass, _str name, _str qualName)
{
   int projectNode = _xmlcfg_set_path(handle,'/project');
   if (projectNode < 0) {
      return;
   }
   int debugNode = _xmlcfg_add(handle, projectNode, 'target', VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
   if (debugNode < 0) {
      return;
   }
   _xmlcfg_add_attribute(handle, debugNode, 'name', 'debug');
   _xmlcfg_add_attribute(handle, debugNode, 'depends', 'javac');
   _xmlcfg_add_attribute(handle, debugNode, 'description', 'debug target generated by SlickEdit');
   int javaNode = _xmlcfg_add(handle, debugNode, 'java', VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
   if (javaNode < 0) {
      return;
   }
   _xmlcfg_add_attribute(handle, javaNode, 'failonerror', 'true');
   _xmlcfg_add_attribute(handle, javaNode, 'fork', 'true');
   _xmlcfg_add_attribute(handle, javaNode, 'classname', googleClass);
   int cpNode = _xmlcfg_add(handle, javaNode, 'classpath', VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
   if (cpNode < 0) {
      return;
   }
   int pathelementNode = _xmlcfg_add(handle, cpNode, 'pathelement', VSXMLCFG_NODE_ELEMENT_START_END, 
                                     VSXMLCFG_ADD_AS_CHILD);
   if (pathelementNode < 0) {
      return;
   }
   _xmlcfg_add_attribute(handle, pathelementNode, 'location', 'src');
   int pathNode = _xmlcfg_add(handle, cpNode, 'path', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   if (pathNode < 0) {
      return;
   }
   _xmlcfg_add_attribute(handle, pathNode, 'refid', 'project.class.path');
   int jvmNode = _xmlcfg_add(handle, javaNode, 'jvmarg', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   if (jvmNode < 0) {
      return;
   }
   _xmlcfg_add_attribute(handle, jvmNode, 'value', '-Xmx256M');
   int jvmNodeA = _xmlcfg_add(handle, javaNode, 'jvmarg', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   if (jvmNodeA < 0) {
      return;
   }
   _xmlcfg_add_attribute(handle, jvmNodeA, 'value', '-Xdebug');
   int jvmNodeB = _xmlcfg_add(handle, javaNode, 'jvmarg', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   if (jvmNodeB < 0) {
      return;
   }
   _xmlcfg_add_attribute(handle, jvmNodeB, 'value', '-Xnoagent');
   int jvmNodeC = _xmlcfg_add(handle, javaNode, 'jvmarg', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   if (jvmNodeC < 0) {
      return;
   }
   _xmlcfg_add_attribute(handle, jvmNodeC, 'value', '-Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=8000');
   int argNode = _xmlcfg_add(handle, javaNode, 'arg', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   if (argNode < 0) {
      return;
   }
   _xmlcfg_add_attribute(handle, argNode, 'value', '-startupUrl');
   int argNodeB = _xmlcfg_add(handle, javaNode, 'arg', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   if (argNodeB < 0) {
      return;
   }
   _xmlcfg_add_attribute(handle, argNodeB, 'value', name'.html');
   int argNodeC = _xmlcfg_add(handle, javaNode, 'arg', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   if (argNodeC < 0) {
      return;
   }
   _xmlcfg_add_attribute(handle, argNodeC, 'value', qualName);
   _xmlcfg_save(handle,2,VSXMLCFG_SAVE_ALL_ON_ONE_LINE|VSXMLCFG_SAVE_PCDATA_INLINE);
}

static _str _gwt_getVersionFromDir(_str dir)
{
   _str versionFile = dir :+ "about.txt"; 
   _str version = '';
   int status = _open_temp_view(versionFile, auto temp_wid, auto orig_wid);
   if (!status) {
      top();up();
      while (!down()) {
         get_line(auto line);
         if (pos('Google Web Toolkit ',line) > 0) {
            parse line with . 'Google Web Toolkit ' version;
            version = strip(version);
            break;
         }
      }
      _delete_temp_view(temp_wid);
      p_window_id = orig_wid;
   }
   return version;
}

static boolean _gwt_buildFileHasDevMode(int handle)
{
   int devModeNode = _xmlcfg_find_simple(handle, "/project/target[@name='devmode']");
   return devModeNode >= 0;
}

static _str _gwt_findAllJars(_str dir, boolean recursive = true)
{
   _str result = '';
   _str recurse = recursive ? '+t ' : '';
   int filelist_view_id;
   int orig_view_id=_create_temp_view(filelist_view_id);
   p_window_id=filelist_view_id;
   insert_file_list(recurse'W -v +p -d 'maybe_quote_filename(dir'*.jar'));
   top(); up();
   while (!down()) {
      get_line(auto line);
      result :+= strip(line) :+ PATHSEP;
   }
   p_window_id=orig_view_id;
   _delete_temp_view(filelist_view_id);
   return result;
}
