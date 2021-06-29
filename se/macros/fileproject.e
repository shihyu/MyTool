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
#include 'slick.sh'
#import 'cfg.e'
#import 'xmldoc.e'
#import 'projconv.e'
#import 'stdprocs.e'
#import 'projutil.e'
#import 'main.e'
#import 'mprompt.e'
#import 'setupext.e'
#import 'listbox.e'
#import 'stdprocs.e'
#import 'tbview.e'
#import 'stdcmds.e'
#import 'files.e'
#import 'wkspace.e'
#import 'debug.e'
#import 'debuggui.e'
#import 'sellist2.e'
#import 'restore.e'
#import 'ini.e'
#import 'se/ui/mainwindow.e'
#endregion

/*
possible enhancements to single file projects support 
   * (Google has problems here) Google Web Toolkit for Python
   * Google Web Toolkit for Go (new regular project support for this too)
   * Real time error notifications
   * Create express edition configuration for C++
   * PHP single file profile
 
   * auto set up environment automatically for "cl.exe"
   * auto set up environment automatically for "csc.exe"
   * smarter buildfirst support (Ueful for C#)
   * Unit Test support
 
*/

#define FILEPROJECT_DEBUG 0
struct FILEPROJECT_INFO {
   int m_handle;
   _str m_config;
   _str m_state;
};
FILEPROJECT_INFO gfp_File2Handle:[];
FILEPROJECT_INFO gfp_Lang2Handle:[];
_str gfp_curLangId='';
_str gfp_curAbsFilename='';
int gfp_curProject= -1;
_str gfp_curConfig;
_str gfp_origState;
bool gfp_curHaveFileSpecificProject=false;
// Needed if convert cached lang project to file project.
bool gfp_curChanged=true;
int gfp_inSetCurrent=0;


int gfp_curEditOrigProfileProject=-1;
int gfp_curEditProfileProject=-1;
_str gfp_curEditProfileLangId='';
_str gfp_curEditProfileName='';
/*
 Save break points when switch files and not debugging.
 restore break points when switch files and not debugging.
 Not sure when to save other debug info.
*/

void _fileProjectInit() {
   gfp_File2Handle._makeempty();
   gfp_Lang2Handle._makeempty();
   gfp_curLangId='';
   gfp_curAbsFilename='';
   gfp_curProject= -1;
   gfp_curConfig='';
   gfp_curHaveFileSpecificProject=false;
   gfp_curEditOrigProfileProject= -1;
   gfp_curEditProfileProject= -1;
   gfp_curEditProfileLangId='';
   gfp_curEditProfileName='';
   gfp_curChanged=true;
   gfp_origState='';

   gfp_inSetCurrent=0;
}

/*definit() {
   if (arg(1)!='L') {
      _fileProjectInit();
   }
   gfp_inSetCurrent=0;
} */
int _fileProjectHandle() {
   return gfp_curProject;
}
_str _fileProjectConfig() {
   return gfp_curConfig;
}
void _fileProjectSaveStateChanges() {
   if (gfp_curProject>=0) {
      haveDebugInfo := _project_DebugCallbackName!='';
      if (haveDebugInfo) {
         // Save the file project state
         //say('b4 gen *************************');
         _fileProjectGenState2(auto state);
         if (state!=gfp_origState) {
            //say('af gen *************************');
            //_message_box('state changed len1='length(state)' 'length(gfp_origState));
            _fileProjectSaveCurrent(gfp_curProject,state);
         } else {
            //say('NO CHANGE');
         }
      }
   }
}
void _fileProjectClose() {
   if (gfp_curProject>=0) {
#if FILEPROJECT_DEBUG
      say('_fileProjectClose');
#endif
      haveDebugInfo := _project_DebugCallbackName!='';
      _fileProjectSaveStateChanges();
      // Send off the _prjclose_ events
      workspace_close_project(true);
      if (_project_DebugCallbackName!='') {
         _project_DebugCallbackName='';
         _DebugUpdateMenu();
      } else {
         _project_DebugCallbackName='';
      }
      if (haveDebugInfo) {
         _wkspace_close_debug();
      }
      _fileProjectResetCurrent();
      gfp_curChanged=true;
      // May need this.
      //call_list('_prjconfig_');  // Active config changed
   }
}

int _fileProjectSetCurrent(_str langId,_str absFilename,_str &config) {
   if (!(_tbDebugQMode() || gfp_inSetCurrent) || gfp_curProject<0) {
      absFilename=_file_case(absFilename);
      if (langId==gfp_curLangId && absFilename:==gfp_curAbsFilename && !gfp_curChanged) {
         config=gfp_curConfig;
         return gfp_curProject;
      }
      ++gfp_inSetCurrent;
      _fileProjectClose();
      if (gin_restore) {
         //_StackDump();
         langId='';
         absFilename='';
         gfp_curConfig=true;
      }
      state := "";
      handle:=_fileProjectSetCurrent2(langId,absFilename,config,state);
      if (handle<0) {
         handle=_fileProjectCreateDefault(langId,absFilename,config);
      }
      new_DebugCallbackName := _ProjectGet_DebugCallbackName(handle);
      // DJB 03-18-2008
      // Integrated .NET debugging is no longer available as of SlickEdit 2008
      if (new_DebugCallbackName=="dotnet") new_DebugCallbackName="";
#if FILEPROJECT_DEBUG
      say('new_DebugCallbackName='new_DebugCallbackName);
#endif
      if (new_DebugCallbackName!=_project_DebugCallbackName) {
         _project_DebugCallbackName=new_DebugCallbackName;
         _DebugUpdateMenu();
      }
      //say('DebugCallbackName='_project_DebugCallbackName' DebugConfig='_project_DebugConfig);
      //say('fileProjectOpen 'gfp_curAbsFilename);
      if (state!='' && new_DebugCallbackName!='') {
         _fileProjectRestoreState(state);
      }
      call_list('_prjopen_',true);
      //say('setcur: statelen='length(state));
      if (new_DebugCallbackName!='') {
         if (state=='') {
            _fileProjectGenState2(state);
            //say('setcur: h2 statelen='length(state));
         }
         gfp_origState=state;
      }
      //call_list('_prjconfig_');  // Active config changed. I don't think we need this.
      --gfp_inSetCurrent;
   } 
   config=gfp_curConfig;
   return gfp_curProject;
}
static int _fileProjectSetCurrent2(_str langId,_str absFilename,_str &config,_str &state=null) {
   absFilename=_file_case(absFilename);
   if (langId:==gfp_curLangId && absFilename:==gfp_curAbsFilename && !gfp_curChanged) {
      config=gfp_curConfig;
      return gfp_curProject;
   }
   gfp_curProject= -1;
   gfp_curLangId=langId;
   gfp_curAbsFilename=absFilename;
   gfp_curConfig='';
   gfp_curHaveFileSpecificProject=false;
   gfp_curChanged=false;
   
   fileKey := langId:+"\1":+absFilename;
   FILEPROJECT_INFO *pinfo;
   pinfo=gfp_File2Handle._indexin(fileKey);
   if (pinfo) {
      gfp_curHaveFileSpecificProject=true;
      gfp_curProject=pinfo->m_handle;
      config=gfp_curConfig=pinfo->m_config;
      state=pinfo->m_state;
      return gfp_curProject;
   }
   // Check for a file specific project first.
   project_node := -1;
   int handle;
   handle=_plugin_get_property_xml(vsCfgPackage_for_Lang(gfp_curLangId),VSCFGPROFILE_FILEPROJECTS,gfp_curAbsFilename);
   if (handle>=0) {
      int dest_handle;
       project_node=_xmlcfg_find_simple(handle,'/p/Project',0);
   } 
   int dest_handle;
   state='';
   if (project_node<0) {
      pinfo=gfp_Lang2Handle._indexin(langId);
      if (pinfo) {
         gfp_curProject=pinfo->m_handle;
         config=gfp_curConfig=pinfo->m_config;
         state=pinfo->m_state;
         return gfp_curProject;
      }
      _str profileName=_plugin_get_property(VSCFGPACKAGE_LANGUAGE,langId,VSCFGP_FILEPROJECT_DEFAULT_PROFILE);
      dest_handle= -1;
      if (profileName!='') {
         dest_handle=_plugin_get_property_xml(vsCfgPackage_for_LangFileProjectProfiles(langId),profileName,'content');
      }
      if (dest_handle<0) {
         // Try picking one of the profiles
         //_str profileNames[];
         //_fileProjectListProfiles(langId,profileNames);
         //if (profileNames._length()) {
         //   dest_handle=_plugin_get_property_xml(vsCfgPackage_for_LangFileProjectProfiles(langId),profileNames[0],'content');
         //}
         if (dest_handle<0) {
            FILEPROJECT_INFO info;
            info.m_handle= -1;
            info.m_config= '';
            info.m_state='';
            // Odd error. fileproject_default_profile points to a deleted profile.
            gfp_Lang2Handle:[langId]=info;
         }
         return -1;
      }
      // Convert this template to a <project>
      int node=_xmlcfg_get_first_child(dest_handle,0);
      _xmlcfg_set_name(dest_handle,node,'Project');
      _xmlcfg_delete_attribute(dest_handle,node,VSXMLCFG_PROPERTY_NAME);
      //_xmlcfg_set_attribute(dest_handle,node,'ProfileName',_plugin_append_profile_name(vsCfgPackage_for_LangFileProjectProfiles(langId),profileName));
      //_showxml(dest_handle);
      //_ProjectAddCreateAttributes(handle);
      //gfp_Lang2Handle:[langId]=dest_handle;
      if (handle>=0) {
         _xmlcfg_close(handle);
      }
      gfp_curProject=dest_handle;
   } else {
      gfp_curHaveFileSpecificProject=true;
      // We found file specific project sttings for this file.
      dest_handle=_xmlcfg_create('',VSENCODING_UTF8);
      _xmlcfg_copy(dest_handle,0,handle,project_node,VSXMLCFG_COPY_AS_CHILD);
      gfp_curProject=dest_handle;
      config_node:=_xmlcfg_find_simple(handle,'/p/ActiveConfig');
      if (config_node>=0) {
         gfp_curConfig=_xmlcfg_get_attribute(handle,config_node,'Name');
      }
      state_node:=_xmlcfg_find_simple(handle,'/p/State');
      if (state_node>=0) {
         state_node=_xmlcfg_get_first_child(handle,state_node,VSXMLCFG_NODE_PCDATA);
         if (state_node>=0) {
            state=_xmlcfg_get_value(handle,state_node);
            state=stranslate(state,"","\r");
            if (substr(state,1,1):=="\n") {
               state=substr(state,2);
            }
         }
      }
      _xmlcfg_close(handle);
   }
   _str List[];
   _ProjectGet_ConfigNames(dest_handle,List);
   if (gfp_curConfig=='') {
      // Set the first config as current
      if (List._length()) {
         gfp_curConfig=List[0];
      }
   } else {
      found := false;
      for (i:=0;i<List._length();++i) {
         if (strieq(List[i],gfp_curConfig)) {
            found=true;
            break;
         }
      }
      if (!found) {
         if (List._length()) {
            gfp_curConfig=List[0];
         }
      }
   }
   FILEPROJECT_INFO info;
   info.m_handle= dest_handle;
   info.m_config= gfp_curConfig;
   info.m_state=state;

   if (project_node<0) {
      gfp_Lang2Handle:[langId]=info;
   } else {
      gfp_File2Handle:[fileKey]= info;
   }

   config=gfp_curConfig;
   gfp_curProject=dest_handle;
   return dest_handle;
}
static int _fileProjectSetDefaultXml(int dest_handle,_str langId) {
   int dest_project_node=_xmlcfg_set_path(dest_handle,'/Project');
   if (langId!='') {
      _str prjtemplates=_getSysconfigPath():+'projects':+FILESEP:+VSCFGFILE_PRJTEMPLATES;
      int status;
      int handle=_xmlcfg_open(prjtemplates,status);
      if (handle<0) {
         // Bad things are going to happen.
         say("Can't load "prjtemplates);
         return -1;
      }
      int node=_xmlcfg_find_simple(handle,"/Templates/Template[@Name='(Other)']/Config");
      _xmlcfg_copy(dest_handle,dest_project_node,handle,node,VSXMLCFG_COPY_AS_CHILD);
      gfp_curConfig=_xmlcfg_get_attribute(handle,node,'Name');
      _xmlcfg_close(handle);
      // Replace references of %<e with %n

      typeless foundNodes[];
      ss := "/Project/Config/Menu/Target/Exec[contains(@CmdLine,'%<e')]";
      _xmlcfg_find_simple_array(dest_handle, ss, foundNodes);
      ss = "/Project/Config/PostBuildCommands/Exec[contains(@CmdLine,'%<e')]";
      _xmlcfg_find_simple_array(dest_handle, ss, foundNodes, FindFlags:VSXMLCFG_FIND_APPEND);
      ss = "/Project/Config/PreBuildCommands/Exec[contains(@CmdLine,'%<e')]";
      _xmlcfg_find_simple_array(dest_handle, ss, foundNodes, FindFlags:VSXMLCFG_FIND_APPEND);

      foreach (auto attrNode in foundNodes) {
         _str cmdline=_xmlcfg_get_attribute(dest_handle,attrNode,'CmdLine');
         cmdline=stranslate(cmdline,'%n','%<e');
         _xmlcfg_set_attribute(dest_handle,attrNode,'CmdLine',cmdline);
      }
   }
   return 0;
}
int _fileProjectCreateDefault(_str langId,_str absFilename,_str &config) {
   absFilename=_file_case(absFilename);
   fileKey := langId:+"\1":+absFilename;
   
   gfp_curProject= -1;
   gfp_curLangId=langId;
   gfp_curAbsFilename=absFilename;
   gfp_curConfig='';
   gfp_curHaveFileSpecificProject=true;
   gfp_curChanged=false;

   int dest_handle=_xmlcfg_create('',VSENCODING_UTF8);
   if(_fileProjectSetDefaultXml(dest_handle,langId)) {
      return -1;
   }

   FILEPROJECT_INFO info;
   info.m_handle= dest_handle;
   info.m_config= gfp_curConfig;
   info.m_state= '';

   gfp_File2Handle:[fileKey]= info;

   config=gfp_curConfig;
   gfp_curProject=dest_handle;
   return dest_handle;
}
int _fileProjectSetCurrentOrCreate(int &editorctl_wid,_str &config) {
   editorctl_wid=p_window_id;
   if (!_isEditorCtl()) {
      if (_no_child_windows()) {
         _message_box(nls("There must be a window to set up single file project information."));
         return -1;
      }
      editorctl_wid=_mdi.p_child;
   }
   return _fileProjectSetCurrent(editorctl_wid.p_LangId,editorctl_wid.p_buf_name,config);
}
void _fileProjectSetActiveConfig(_str config) {
   if (gfp_curProject<0) {
      // File project not open?
      return;
   }
   _str List[];
   _ProjectGet_ConfigNames(gfp_curProject,List);
   found := false;
   for (i:=0;i<List._length();++i) {
      if (strieq(List[i],config)) {
         found=true;
         break;
      }
   }
   if (!found) {
      return;
   }
   gfp_curConfig=config;
   int cur_handle=_plugin_get_property_xml(vsCfgPackage_for_Lang(gfp_curLangId),VSCFGPROFILE_FILEPROJECTS,gfp_curAbsFilename);
   if (cur_handle<0) {
      /* This can happen if the active file has no file or language specific configs.
         In that case, we create some file specific XML in memory with _fileProjectCreateDefault()
         but don't write out the .cfg.xml data. Then if this function gets called, we need
         to save everything (not just the config).
       
         I don't think we do this sequence anywhere but this is here just in case we eventually do
         this.
      */ 
      _fileProjectSaveCurrent(gfp_curProject);
   } else {
      cur_config_node:=_xmlcfg_set_path(cur_handle,'/p/ActiveConfig','Name',gfp_curConfig);
      state := "";
      _fileProjectGenState(cur_handle,state);

      _config_modify_flags(CFGMODIFY_OPTION);
      _plugin_set_property_xml(vsCfgPackage_for_Lang(gfp_curLangId),VSCFGPROFILE_FILEPROJECTS,VSCFGPROFILE_FILEPROJECTS_VERSION,gfp_curAbsFilename,cur_handle);

      // Update our cached config too.
      if (gfp_curHaveFileSpecificProject) {
         FILEPROJECT_INFO *pinfo;
         fileKey := gfp_curLangId:+"\1":+gfp_curAbsFilename;
         pinfo=gfp_File2Handle._indexin(fileKey);
         if (pinfo) {
            pinfo->m_config=gfp_curConfig;
            pinfo->m_state=state;
         }
      }
   }
   call_list('_prjconfig_');  // Active config changed
}
static void _fileProjectRestoreState(_str state) {
   int temp_wid;
   orig_view_id:=_create_temp_view(temp_wid);
   p_newline="\n";
   int hints = RH_NO_RESTORE_FILES;
   hints |= RH_NO_RESTORE_LAYOUT;
   hints |=RH_NO_RESET_LAYOUT;
   state=strip(state,'T');
   if (_last_char(state):=="\n") {
      state=substr(state,1,length(state)-1);
   }
   _insert_text(state);
#if FILEPROJECT_DEBUG
   say('N='p_Noflines' RESTORE**************************************************');
   top();
   state=get_text(p_buf_size);
   top();up();
   while (!down()) {
      get_line(auto line);
      say(line);
   }
#endif
   top();
   //say('ignoring RESTORE f='gfp_curAbsFilename);
   restore('N', temp_wid, _strip_filename(gfp_curAbsFilename,'N'), hints);
   //say('RESTORE**************************************************');
   _delete_temp_view(temp_wid);
   activate_window(orig_view_id);
}
static void _fileProjectGenState2(_str &state) {
   int temp_wid;
   orig_view_id:=_create_temp_view(temp_wid);
   p_newline="\n";
#if FILEPROJECT_DEBUG
   say('SAVE**************************************************');
#endif
   debug_maybe_initialize();
   _sr_debug('','','',_strip_filename(gfp_curAbsFilename,'N'),true);
   _write_monitor_configs_for_fileprojects();
   //_srmon_debug_layout('','');
   //say('savedbg: 'gfp_curAbsFilename);
   //_showbuf(p_window_id,false);
   top();
   state=get_text(p_buf_size);
#if FILEPROJECT_DEBUG
   top();up();
   while (!down()) {
      get_line(auto line);
      say(line);
   }
   say('N='p_Noflines' SAVE**************************************************');
#endif
   _delete_temp_view(temp_wid);
   activate_window(orig_view_id);
}
static void _fileProjectGenState(int cur_handle,_str &state) {
   cur_state_node:=_xmlcfg_set_path(cur_handle,'/p/State');
   if (gfp_curAbsFilename!='' && _project_DebugCallbackName!='') {
      if (state=='') {
         _fileProjectGenState2(state);
      }
      _xmlcfg_delete(cur_handle,cur_state_node,true);
      text := "\n":+state;
      _xmlcfg_add(cur_handle,cur_state_node,text,VSXMLCFG_NODE_PCDATA,VSXMLCFG_ADD_AS_CHILD);
   } else {
      state='';
      _xmlcfg_delete(cur_handle,cur_state_node);
   }
}
int _fileProjectSaveCurrent(int handle,_str state='') {
   if (gfp_curProject<0) {
      // File project not open?
      return 0;
   }
   int project_node=_xmlcfg_get_first_child(handle,0);
   if (project_node<0) {
      // Odd error. <profile> Document element missing.
      return 0;
   }
   if (gfp_curProject!=handle && gfp_curHaveFileSpecificProject) {
      int dest_project_node=_xmlcfg_get_first_child(handle,0);
      if (dest_project_node<0) {
         return 0;
      }
      _xmlcfg_delete(gfp_curProject,dest_project_node,true);
      _xmlcfg_copy(gfp_curProject,dest_project_node,handle,project_node,VSXMLCFG_COPY_CHILDREN);
   }
   int cur_handle=_plugin_get_property_xml(vsCfgPackage_for_Lang(gfp_curLangId),VSCFGPROFILE_FILEPROJECTS,gfp_curAbsFilename);
   if (cur_handle<0) {
      // New file specific settings for this file.
      cur_handle=_xmlcfg_create('',VSENCODING_UTF8);
   }
   int cur_project_node=_xmlcfg_set_path(cur_handle,'/p/Project');
   // Replace the <Project> settings for this single file project
   _xmlcfg_delete(cur_handle,cur_project_node,true);
   _xmlcfg_copy(cur_handle,cur_project_node,handle,project_node,VSXMLCFG_COPY_CHILDREN);
   // IF we are creating file specific project data for the first time
   if (!gfp_curHaveFileSpecificProject) {
      // Record the profile name
      cur_project_node=_xmlcfg_find_simple(cur_handle,'/p/Project');
      if (cur_project_node>0) {
         _str defaultProfileName=_plugin_get_property(VSCFGPACKAGE_LANGUAGE,gfp_curLangId,VSCFGP_FILEPROJECT_DEFAULT_PROFILE);
         if (defaultProfileName!='') {
            _xmlcfg_set_attribute(cur_handle,cur_project_node,'ProfileName',defaultProfileName);
         }
      }

   }


   _str List[];
   _ProjectGet_ConfigNames(gfp_curProject,List);
   if (gfp_curConfig=='') {
      // Set the first config as current
      if (List._length()) {
         gfp_curConfig=List[0];
      }
   } else {
      found := false;
      for (i:=0;i<List._length();++i) {
         if (strieq(List[i],gfp_curConfig)) {
            found=true;
            break;
         }
      }
      if (!found) {
         if (List._length()) {
            gfp_curConfig=List[0];
         }
      }
   }
   //say('gfp_curConfig='gfp_curConfig);
   cur_config_node:=_xmlcfg_set_path(cur_handle,'/p/ActiveConfig','Name',gfp_curConfig);
   _fileProjectGenState(cur_handle,state);

   _config_modify_flags(CFGMODIFY_OPTION);
   _plugin_set_property_xml(vsCfgPackage_for_Lang(gfp_curLangId),VSCFGPROFILE_FILEPROJECTS,VSCFGPROFILE_FILEPROJECTS_VERSION,gfp_curAbsFilename,cur_handle);
   if (!gfp_curHaveFileSpecificProject) {
      gfp_curChanged=true;
   }
#if 1
   // This will happen automatically the next time we request a project for this file.
   if (!gfp_curHaveFileSpecificProject) {
      gfp_curHaveFileSpecificProject=true;
      // Cache the file specific project sttings for this file.
      dest_handle:=_xmlcfg_create('',VSENCODING_UTF8);
      _xmlcfg_copy(dest_handle,0,handle,project_node,VSXMLCFG_COPY_AS_CHILD);
      //gfp_curProject=dest_handle;
      fileKey := gfp_curLangId:+"\1":+gfp_curAbsFilename;
      FILEPROJECT_INFO info;
      info.m_handle= dest_handle;
      info.m_config= gfp_curConfig;
      info.m_state= state;
      gfp_File2Handle:[fileKey]= info;
   } else {
      // Update our cached config too.
      FILEPROJECT_INFO *pinfo;
      fileKey := gfp_curLangId:+"\1":+gfp_curAbsFilename;
      pinfo=gfp_File2Handle._indexin(fileKey);
      if (pinfo) {
         pinfo->m_config=gfp_curConfig;
         pinfo->m_state=state;
      }
   }
#endif

   _xmlcfg_close(cur_handle);

   maybeResetLanguageProjectToolList(1);
   return 0;
}
void _buffer_renamed_fileProject(int buf_id,_str old_buf_name,_str new_buf_name,int buf_flags) {
   handle:=_plugin_get_property_xml(vsCfgPackage_for_Lang(p_LangId),VSCFGPROFILE_FILEPROJECTS,_file_case(old_buf_name));
   if (handle<0) {
      return;
   }
   // Copy the file specifc project settings to new filename.
   active_config_node:=_xmlcfg_find_simple(handle,"/p/Project/ActiveConfig");
   curConfig := "";
   if (active_config_node>=0) {
      curConfig=_xmlcfg_get_attribute(handle,active_config_node,'Name');
   }
   if (curConfig=='') {
      _str List[];
      _xmlcfg_find_simple_array(handle,"/p":+VPJX_CONFIG"/@Name",List,TREE_ROOT_INDEX,VSXMLCFG_FIND_VALUES);
      if (List._length()) {
         curConfig=List[0];
      }
   }
   state := "";
   _fileProjectGenState(handle,state);

   _config_modify_flags(CFGMODIFY_OPTION);
   _plugin_set_property_xml(vsCfgPackage_for_Lang(p_LangId),VSCFGPROFILE_FILEPROJECTS,VSCFGPROFILE_FILEPROJECTS_VERSION,_file_case(new_buf_name),handle);

   dest_handle:=_xmlcfg_create('',VSENCODING_UTF8);
   int project_node=_xmlcfg_find_simple(handle,"/p/Project");
   if (project_node) {
      _xmlcfg_copy(dest_handle,0,handle,project_node,VSXMLCFG_COPY_AS_CHILD);
   }
   _xmlcfg_close(handle);

   fileKey := p_LangId:+"\1":+_file_case(new_buf_name);
   FILEPROJECT_INFO info;
   info.m_handle= dest_handle;
   info.m_config= curConfig;
   info.m_state= state;
   gfp_File2Handle:[fileKey]= info;

   // This is probably over kill but just in case something weird is going on.
   maybeResetLanguageProjectToolList(1);
}
void _fileProjectWriteTemp(_str projectFileName,_str buf_name,int handle,_str config) {
   temp_handle:=_xmlcfg_create('',VSENCODING_UTF8);
   _xmlcfg_copy(temp_handle,0,handle,0,VSXMLCFG_COPY_CHILDREN);
   FilesNode:=_ProjectGet_FilesNode(temp_handle,true);
   Node:=_xmlcfg_add(temp_handle,FilesNode,'F',VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_set_attribute(temp_handle,Node,'N',_NormalizeFile(_strip_filename(buf_name,'p')));
   _xmlcfg_save(temp_handle,-1,VSXMLCFG_SAVE_ONE_LINE_IF_ONE_ATTR,projectFileName);
   _xmlcfg_close(temp_handle);
   workspace_hist:=_strip_filename(projectFileName,'e'):+WORKSPACE_STATE_FILE_EXT;
   _ini_set_value(workspace_hist,"ActiveConfig",_strip_filename(projectFileName,'P'),','config,_fpos_case);
}
static void _fileProjectResetCurrent() {
   gfp_curLangId='';
   gfp_curAbsFilename='';
   gfp_curProject= -1;
   gfp_curConfig='';
   gfp_curChanged=true;
   maybeResetLanguageProjectToolList(1);
}
void _fileProjectRecache() {
   typeless i;
   for (i._makeempty();;) {
      FILEPROJECT_INFO info=gfp_File2Handle._nextel(i);
      if (i._isempty()) break;
      //if (info.m_handle!=gfp_curProject) {
         _xmlcfg_close(info.m_handle);
      //}
   }
   gfp_File2Handle._makeempty();

   for (i._makeempty();;) {
      FILEPROJECT_INFO info=gfp_Lang2Handle._nextel(i);
      if (i._isempty()) break;
      //if (info.m_handle!=gfp_curProject) {
         _xmlcfg_close(info.m_handle);
      //}
   }
   gfp_Lang2Handle._makeempty();

   //handle=_fileProjectSetCurrent(gfp_curLangId,gfp_curAbsFilename,auto config);
   _fileProjectResetCurrent();
}

void _fileProjectListProfiles(_str langId,_str (&profileNames)[]) {
   _plugin_list_profiles(vsCfgPackage_for_LangFileProjectProfiles(langId),profileNames);
}

int _fileProjectEditProfileHandle() {
   return gfp_curEditProfileProject;
}
int _fileProjectEditProfile(_str langId,_str profileName) {
   if (gfp_curEditProfileProject>=0) {
      _xmlcfg_close(gfp_curEditProfileProject);gfp_curEditProfileProject= -1;
      _xmlcfg_close(gfp_curEditOrigProfileProject);gfp_curEditOrigProfileProject= -1;
   }
   int dest_handle=_plugin_get_property_xml(vsCfgPackage_for_LangFileProjectProfiles(langId),profileName,'content');
   if (dest_handle<0) {
      return -1;
   }
   gfp_curEditOrigProfileProject=dest_handle;
   dest_handle=_plugin_get_property_xml(vsCfgPackage_for_LangFileProjectProfiles(langId),profileName,'content');
   // Convert this template to a <project>
   int node=_xmlcfg_get_first_child(dest_handle,0);
   _xmlcfg_set_name(dest_handle,node,'Project');
   _xmlcfg_delete_attribute(dest_handle,node,VSXMLCFG_PROPERTY_NAME);
   //_xmlcfg_set_attribute(dest_handle,node,'ProfileName',_plugin_append_profile_name(vsCfgPackage_for_LangFileProjectProfiles(langId),profileName));
   //_showxml(dest_handle);
   gfp_curEditProfileProject=dest_handle;
   gfp_curEditProfileLangId=langId;
   gfp_curEditProfileName=profileName;

   return dest_handle;
}
static void _fileProjectPropagateChanges(int orig_content_handle,int new_content_handle,_str langId,_str origProfileName,_str newProfileName='') {
   // Study all the file projects for this language.
   fileprojects_handle:=_plugin_get_profile(vsCfgPackage_for_Lang(gfp_curLangId),VSCFGPROFILE_FILEPROJECTS);
   if (fileprojects_handle<0) {
      // There are no file specifics projects. All files using language specific settings
      return;
   }

   //_showxml(fileprojects_handle);
   _str array[];
   fileprojects_modified := false;
   _xmlcfg_find_simple_array(fileprojects_handle,"/profile/p/Project",array);
   for (i:=0;i<array._length();++i) {
      int node=(int)array[i];
      _str copiedFrom=_xmlcfg_get_attribute(fileprojects_handle,node,"ProfileName");
      //say('copiedFrom='copiedFrom);
      if (strieq(copiedFrom,origProfileName)) {
         int temp_handle=_xmlcfg_create('',VSENCODING_UTF8);
         int project_index=_xmlcfg_set_path(temp_handle,"/p");
         _xmlcfg_set_attribute(temp_handle,project_index,'n','content');
         _xmlcfg_copy(temp_handle,project_index,fileprojects_handle,node,VSXMLCFG_COPY_CHILDREN);
         _xmlcfg_save_to_string(auto string1,temp_handle,0,VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE|VSXMLCFG_SAVE_UNIX_EOL,project_index);
         //_showxml(temp_handle,project_index);
         _xmlcfg_close(temp_handle);
         //_showxml(orig_content_handle);
         project_index=_xmlcfg_find_simple(orig_content_handle,"/p");
         if (project_index>=0) {
            _xmlcfg_save_to_string(auto string2,orig_content_handle,0,VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE|VSXMLCFG_SAVE_UNIX_EOL,project_index);
            //_showxml(orig_content_handle,project_index);
            if (string1!=string2) {
               /*say('CHANGED');
               dsay('CHANGED');
               dsay('string1='string1);
               dsay('string2='string2);*/
            } else {
               //say('NO change');
               int parent=_xmlcfg_get_parent(fileprojects_handle,node);
               _str absFilename=_xmlcfg_get_attribute(fileprojects_handle,parent,'n');
               // Delete the children of this project
               _xmlcfg_delete(fileprojects_handle,node,true);
               project_node:=_xmlcfg_find_simple(new_content_handle,"/Project");
               if (project_node<0) {
                  project_node=_xmlcfg_find_simple(new_content_handle,"/p");
               }
               //say('new project_node='project_node);_showxml(new_content_handle);
               if (project_node>=0) {
                  _xmlcfg_copy(fileprojects_handle,node,new_content_handle,project_node,VSXMLCFG_COPY_CHILDREN);
                  if (newProfileName!='') {
                     _xmlcfg_set_attribute(fileprojects_handle,node,'ProfileName',newProfileName);
                     // Must remove break points because don't know if new project supports debugging
                     state_node:=_xmlcfg_find_simple(fileprojects_handle,'State',parent);
                     //_message_box('state_node='state_node' n='_xmlcfg_get_name(fileprojects_handle,parent));
                     if (state_node>=0) {
                        _xmlcfg_delete(fileprojects_handle,state_node);
                     }
                  }
                  fileKey := langId:+"\1":+absFilename;
                  FILEPROJECT_INFO *pinfo;
                  pinfo=gfp_File2Handle._indexin(fileKey);
                  if (pinfo) {
                     //_message_box('b4 change');_showxml(pinfo->m_handle);
                     new_project_node:=_xmlcfg_get_first_child(pinfo->m_handle,0);
                     _xmlcfg_delete(pinfo->m_handle,new_project_node,true);
                     _xmlcfg_copy(pinfo->m_handle,new_project_node,new_content_handle,project_node,VSXMLCFG_COPY_CHILDREN);
                     //_message_box('after change');_showxml(pinfo->m_handle);
                     maybeResetLanguageProjectToolList(1);
                  }
                  fileprojects_modified=true;
               }
            }
         }
      }
   }
   if (fileprojects_modified) {
      //_message_box('modified');_showxml(fileprojects_handle);
      _config_modify_flags(CFGMODIFY_OPTION);
      _plugin_set_profile(fileprojects_handle);
      maybeResetLanguageProjectToolList(1);
   }
   _xmlcfg_close(fileprojects_handle);

}
/**
 * Used to save an edited profile. handle is a copy of the 
 * profile xml and does not use instance XML for the "current" 
 * profile.
 *  
 *  
 * @param handle
 * @param langId
 * @param profileName
 * 
 * @return 
 */
int _fileProjectSaveProfile(int handle,_str langId=null,_str profileName=null) {
   if (langId==null) {
      langId=gfp_curEditProfileLangId;
   }
   if (profileName==null) {
      profileName=gfp_curEditProfileName;
   }
   status:=_plugin_prompt_save_profile(vsCfgPackage_for_LangFileProjectProfiles(langId),profileName);
   if (status) {
      // User cancelled save.
      return 0;
   }
   _fileProjectPropagateChanges(gfp_curEditOrigProfileProject,handle,langId,profileName);

   gfp_curEditProfileName=profileName;
   int dest_handle=handle;
   int dest_project_node=_xmlcfg_get_first_child(dest_handle,0);
   _str defaultProfileName=_plugin_get_property(VSCFGPACKAGE_LANGUAGE,langId,VSCFGP_FILEPROJECT_DEFAULT_PROFILE);
   // Check if we need to update the cache for this language
   if (defaultProfileName!='' && strieq(profileName,defaultProfileName)) {
      FILEPROJECT_INFO *pinfo;
      pinfo=gfp_Lang2Handle._indexin(langId);
      if (pinfo) {
         // We need to update the cache for this language.
         int project_node=_xmlcfg_get_first_child(pinfo->m_handle,0);
         _xmlcfg_delete(pinfo->m_handle,project_node,true);
         _xmlcfg_copy(pinfo->m_handle,project_node,dest_handle,dest_project_node,VSXMLCFG_COPY_CHILDREN);
         gfp_curChanged=true;
         maybeResetLanguageProjectToolList(1);
      }
   }
   doc_node:=_xmlcfg_get_first_child_element(dest_handle);
   orig_name:=_xmlcfg_get_name(dest_handle,doc_node);
   _xmlcfg_set_name(dest_handle,doc_node,VSXMLCFG_PROPERTY);
   //_showxml(dest_handle);
   _config_modify_flags(CFGMODIFY_OPTION);
   _plugin_set_property_xml(vsCfgPackage_for_LangFileProjectProfiles(langId),profileName,VSCFGPROFILE_FILEPROJECTS_VERSION,'content',dest_handle);
   _xmlcfg_set_name(dest_handle,doc_node,orig_name);
   return 0;
}
void _fileProjectAddProfile(_str langId,_str profileName,_str copyFrom='') {
   _str profileNames[];
   _fileProjectListProfiles(langId,profileNames);
   for (i:=0;i<profileNames._length();++i) {
      if (strieq(profileNames[i],profileName)) {
         _message_box(nls('Profile %s already exists',profileName));
         return;
      }
   }

   dest_handle := -1;
   if (copyFrom!='') {
      dest_handle=_fileProjectEditProfile(langId,copyFrom);
   }
   if (dest_handle<0) {
      // If this profile does not exists, create a new one.
      _str prjtemplates=_getSysconfigPath():+'projects':+FILESEP:+VSCFGFILE_PRJTEMPLATES;
      int status;
      int handle=_xmlcfg_open(prjtemplates,status);
      if (handle<0) {
         // Bad things are going to happen.
         say("Can't load "prjtemplates);
         return;
      }
      int node=_xmlcfg_find_simple(handle,"/Templates/Template[@Name='(Other)']/Config");
      dest_handle=_xmlcfg_create('',VSENCODING_UTF8);
      int dest_project_node=_xmlcfg_set_path(dest_handle,'/Project');
      _xmlcfg_copy(dest_handle,dest_project_node,handle,node,VSXMLCFG_COPY_AS_CHILD);
      gfp_curConfig=_xmlcfg_get_attribute(handle,node,'Name');
      _xmlcfg_close(handle);
   }
   _fileProjectSaveProfile(dest_handle,langId,profileName);

   if (dest_handle==gfp_curEditProfileProject) {
      _xmlcfg_close(gfp_curEditProfileProject);gfp_curEditProfileProject= -1;
      _xmlcfg_close(gfp_curEditOrigProfileProject);gfp_curEditOrigProfileProject= -1;
   } else {
      // We created a new template which needs to be closed.
      _xmlcfg_close(dest_handle);
   }
}
int _fileProjectDeleteProfile(_str langId=null,_str profileName=null) {
   operating_on_current_file_project := false;
   if (gfp_curProject>=0 && gfp_curLangId==langId) {
      if(_tbDebugQMode()) {
         if (!gfp_curHaveFileSpecificProject) {
            _message_box("Can't delete this profile while referencing it in debug mode");
            return 1;
         }
      }
      old_curHaveFileSpecificProject := gfp_curHaveFileSpecificProject;
      // Save break points if there are any
      _fileProjectSaveStateChanges();
      int cur_handle=_plugin_get_property_xml(vsCfgPackage_for_Lang(gfp_curLangId),VSCFGPROFILE_FILEPROJECTS,gfp_curAbsFilename);
      if (cur_handle<0) {
         //say('modifycurrent PROFILE NOT MODIFIED');
         operating_on_current_file_project=true;
      } else {
         //say('modifycurrent PROFILE MODIFIED temp='cur_handle);
         _xmlcfg_close(cur_handle);
         // IF we are still accessing the language specific xml
         if (!old_curHaveFileSpecificProject) {
            // Reopen this project so we access the file specific (not language specific) project xml
            _fileProjectSetCurrent(langId,gfp_curAbsFilename,auto config);
            maybeResetLanguageProjectToolList(1);
         }
      }
   }

   if (operating_on_current_file_project) {
      /*_str fileKey=gfp_curLangId:+"\1":+gfp_curAbsFilename;
      FILEPROJECT_INFO *pinfo;
      pinfo=gfp_File2Handle._indexin(fileKey);
      if (pinfo) {
         _xmlcfg_close(pinfo->m_handle);
         gfp_File2Handle._deleteel(fileKey);
      } */
      _fileProjectClose();
      _fileProjectResetCurrent();
      maybeResetLanguageProjectToolList(1);
   } else {
      FILEPROJECT_INFO *pinfo;
      pinfo=gfp_Lang2Handle._indexin(langId);
      if (pinfo) {
         _xmlcfg_close(pinfo->m_handle);
         gfp_Lang2Handle._deleteel(langId);
         //_str defaultProfileName=_plugin_get_property(VSCFGPACKAGE_LANGUAGE,langId,VSCFGP_FILEPROJECT_DEFAULT_PROFILE);
         //maybeResetLanguageProjectToolList(1);
      }
   }
   _plugin_delete_profile(vsCfgPackage_for_LangFileProjectProfiles(langId),profileName);
   return 0;
}
void _fileProjectSetDefaultProfile(_str langId,_str profileName) {
   _str origProfileName=_plugin_get_property(VSCFGPACKAGE_LANGUAGE,langId,VSCFGP_FILEPROJECT_DEFAULT_PROFILE);
   if (!strieq(origProfileName,profileName)) {
      int orig_handle=_plugin_get_property_xml(vsCfgPackage_for_LangFileProjectProfiles(langId),origProfileName,'content');
      if (orig_handle>=0) {
         int new_handle=_plugin_get_property_xml(vsCfgPackage_for_LangFileProjectProfiles(langId),profileName,'content');
         _fileProjectPropagateChanges(orig_handle,new_handle,langId,origProfileName, profileName);
         _xmlcfg_close(orig_handle);
         _xmlcfg_close(new_handle);
      }
   }

   if (!(gfp_curProject>=0 && gfp_curLangId==langId && _tbDebugQMode())) {
      if (profileName!='') {
         int dest_handle=_plugin_get_property_xml(vsCfgPackage_for_LangFileProjectProfiles(langId),profileName,'content');
         int dest_project_node=_xmlcfg_get_first_child(dest_handle,0);
         FILEPROJECT_INFO *pinfo;
         pinfo=gfp_Lang2Handle._indexin(langId);
         if (pinfo && pinfo->m_handle > 0) {
            int project_node=_xmlcfg_get_first_child(pinfo->m_handle,0);
            _xmlcfg_delete(pinfo->m_handle,project_node,true);
            _xmlcfg_copy(pinfo->m_handle,project_node,dest_handle,dest_project_node,VSXMLCFG_COPY_CHILDREN);
            _fileProjectClose();
            _fileProjectResetCurrent();
         }
      }
   }
  // IF all profiles were deleted.
   if (profileName=='') {
      handle:=_plugin_get_profile(VSCFGPACKAGE_LANGUAGE,langId);
      index:=_xmlcfg_get_first_child(handle,TREE_ROOT_INDEX);
      if (index>=0) {
         index=_xmlcfg_find_property(handle,index,VSCFGP_FILEPROJECT_DEFAULT_PROFILE);
         if (index>=0) {
            _xmlcfg_delete(handle,index);
         }
         _config_modify_flags(CFGMODIFY_OPTION);
         _plugin_set_profile(handle);
         _xmlcfg_close(handle);
      }
      return;
   }
   _config_modify_flags(CFGMODIFY_OPTION);
   _plugin_set_property(VSCFGPACKAGE_LANGUAGE,langId,VSCFGPROFILE_LANGUAGE_VERSION,VSCFGP_FILEPROJECT_DEFAULT_PROFILE,profileName);
}
/*
   Click Add...or copy button
      _fileProjectAddProfile(...)
      _fileProjectSetDefaultProfile(...)
   Click Edit ... button.
      handle=_fileProfileEditProfile(...)
*/
static const FILEPROJECT_LANGUAGE_ID= "fileproject_langId";
static const FILEPROJECT_ORIG_DEFAULT_PROFILE= "fileproject_origDefaultProfile";
defeventtab _file_project_profiles_form;
void ctlprofiles.on_change(int reason,int index)
{
    //say('reason='reason);
    update_buttons();
}
#if 0
void ctlprofiles.on_create() {
   langId := _get_language_form_lang_id();
   if (langId==null || langId=='') langId='py';
   _SetDialogInfoHt(FILEPROJECT_LANGUAGE_ID,langId);

   default_profile:=_plugin_get_property(VSCFGPACKAGE_LANGUAGE,langId,VSCFGP_FILEPROJECT_DEFAULT_PROFILE);
   update_profile_list(default_profile);
   update_buttons();
   _SetDialogInfoHt(FILEPROJECT_ORIG_DEFAULT_PROFILE,default_profile);
}
#endif
static void update_buttons() {
   langId := _GetDialogInfoHt(FILEPROJECT_LANGUAGE_ID);
   if (langId==null || langId=='') langId='py';
   index:=ctlprofiles._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   if (index<0) {
      ctledit.p_enabled=false;
      ctldelete.p_enabled=false;
      ctlcreatecopy.p_caption="New...";
      ctlsetdefault.p_enabled=false;
      return;
   }
   index=ctlprofiles._TreeCurIndex();
   ctlcreatecopy.p_caption="Copy...";
   ctlcreatecopy.p_enabled=true;
   ctledit.p_enabled=true;
   ctlsetdefault.p_enabled=true;
   profileName := ctlprofiles._TreeGetCaption(index);
   if (_plugin_has_builtin_profile(vsCfgPackage_for_LangFileProjectProfiles(langId),profileName)) {
      ctldelete.p_enabled=false;
   } else {
      ctldelete.p_enabled=true;
   }
}
static void update_profile_list(_str default_profile) {
   langId := _GetDialogInfoHt(FILEPROJECT_LANGUAGE_ID);
   //ctlprofiles._lbclear();
   ctlprofiles._TreeDelete(TREE_ROOT_INDEX,'C');
   _str profileNames[];
   _fileProjectListProfiles(langId,profileNames);
   for (i:=0;i<profileNames._length();++i) {
      ctlprofiles._TreeAddItem(TREE_ROOT_INDEX,profileNames[i],TREE_ADD_AS_CHILD,0,0,TREE_NODE_LEAF);
      //ctlprofiles._lbadd_item(profileNames[i]);
   }
   if (default_profile=='' && profileNames._length()>0) {
      default_profile=profileNames[0];
   }
   if (default_profile!='') {
      int index=ctlprofiles._TreeSearch(TREE_ROOT_INDEX,default_profile,'i');
      if (index>0) {
         ctlprofiles._TreeSetInfo(index,TREE_NODE_LEAF,-1,-1,TREENODE_BOLD);
         ctlprofiles._TreeSetCurIndex(index);
      }
   }
   update_buttons();
}
void ctldelete.lbutton_up() {
   langId := _GetDialogInfoHt(FILEPROJECT_LANGUAGE_ID);
   index:=ctlprofiles._TreeCurIndex();
   if (index<0) {
      return;
   }
   ctlprofiles._TreeGetInfo(index,auto showChildren,auto nonCurrentBMIndex,auto currentBMIndex,auto nodeFlags,auto lineNumber);
   profileName := ctlprofiles._TreeGetCaption(index);
   status := _message_box("Are you sure you want to delete the profile '"profileName"'?  This action can not be undone.", "Confirm Profile Delete", MB_YESNO | MB_ICONEXCLAMATION);
   if (status == IDYES) {
      status=_fileProjectDeleteProfile(langId, profileName);
      if (status) {
         return;
      }
      ctlprofiles._TreeDelete(index);
      //IF the node we deleted was bold
      if (nodeFlags & TREENODE_BOLD) {
         index=ctlprofiles._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
         if (index>0) {
            index=ctlprofiles._TreeCurIndex();
            ctlprofiles._TreeSetInfo(index,TREE_NODE_LEAF,-1,-1,TREENODE_BOLD);
         }
      }
      update_buttons();
   }
}
void ctledit.lbutton_up() {
   langId := _GetDialogInfoHt(FILEPROJECT_LANGUAGE_ID);
   index:=ctlprofiles._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   if (index<0) {
      return;
   }
   _str orig_profileNames[];
   _fileProjectListProfiles(langId,orig_profileNames);

   _str profileName=ctlprofiles._TreeGetCaption(ctlprofiles._TreeCurIndex());
   handle:=_fileProjectEditProfile(langId,profileName);
   if (handle<0) {
      return;
   }
   displayName := '"'profileName'"';
   /*_MDICurrent().*/show('-modal -xy _project_form',displayName,handle);

   // We may have a added a profile
   _str profileNames[];
   _fileProjectListProfiles(langId,profileNames);
   if (profileNames._length()!=orig_profileNames._length()) {
      update_profile_list(gfp_curEditProfileName);
   }
}
void ctlcreatecopy.lbutton_up() {
   langId := _GetDialogInfoHt(FILEPROJECT_LANGUAGE_ID);
   curProfileName := "";
   index:=ctlprofiles._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   if (index>0) {
      curProfileName = ctlprofiles._TreeGetCaption(ctlprofiles._TreeCurIndex());
   }
   _str profileName;
   status:=_plugin_prompt_add_profile(vsCfgPackage_for_LangFileProjectProfiles(langId),profileName,curProfileName);
   if (status) {
      return;
   }

   _fileProjectAddProfile(langId, profileName, curProfileName);
   update_profile_list(profileName);
}

void ctlsetdefault.lbutton_up() {
   langId := _GetDialogInfoHt(FILEPROJECT_LANGUAGE_ID);
   index:=ctlprofiles._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   if (index<0) {
      return;
   }
   profileName := ctlprofiles._TreeGetCaption(ctlprofiles._TreeCurIndex());
   update_profile_list(profileName);
}


/*void _file_project_profiles_form_restore_state(_str options) {
    beautifier_schedule_deferred_update(100, p_active_form, '_bc_update_preview_cb');
} */

void _file_project_profiles_form_init_for_options(_str langId)
{
   //langId := _get_language_form_lang_id();
   //if (langId==null || langId=='') langId='py';
   _SetDialogInfoHt(FILEPROJECT_LANGUAGE_ID,langId);

   default_profile:=_plugin_get_property(VSCFGPACKAGE_LANGUAGE,langId,VSCFGP_FILEPROJECT_DEFAULT_PROFILE);
   update_profile_list(default_profile);
   _SetDialogInfoHt(FILEPROJECT_ORIG_DEFAULT_PROFILE,default_profile);
}

/*void _file_project_profiles_form_cancel()
{
   // Cancel the timer, in case the user was remarkably quick.
   beautifier_schedule_deferred_update(-1, p_active_form);
   _SetDialogInfoHt(BEAUT_PROFILE_CHANGED, 0);
} */
static _str _findDefaultProfile() {
   default_profile := "";
   index:=ctlprofiles._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (index>0) {
      ctlprofiles._TreeGetInfo(index,auto showChildren,auto nonCurrentBMIndex,auto currentBMIndex,auto nodeFlags,auto lineNumber);
      if (nodeFlags & TREENODE_BOLD) {
         default_profile=ctlprofiles._TreeGetCaption(index);
         break;
      }
      index=ctlprofiles._TreeGetNextSiblingIndex(index);
   }
   return default_profile;
}
bool _file_project_profiles_form_apply()
{
   langId := _GetDialogInfoHt(FILEPROJECT_LANGUAGE_ID);
   _str default_profile=_findDefaultProfile();
   _fileProjectSetDefaultProfile(langId,default_profile);
   _SetDialogInfoHt(FILEPROJECT_ORIG_DEFAULT_PROFILE,default_profile);
   return true;
}

bool _file_project_profiles_form_is_modified()
{
   origDefaultProfileName:=_GetDialogInfoHt(FILEPROJECT_ORIG_DEFAULT_PROFILE);
   _str default_profile=_findDefaultProfile();

   return !strieq(origDefaultProfileName,default_profile);
}
_str _file_project_profiles_form_export_settings(_str &file, _str &args, _str langId)
{
   error := '';
   dest_handle:=_xmlcfg_create('',VSENCODING_UTF8);
   NofProfiles:=_xmlcfg_export_profiles(dest_handle,vsCfgPackage_for_LangFileProjectProfiles(langId));
   NofProfiles+=_xmlcfg_export_profile(dest_handle,vsCfgPackage_for_Lang(langId),VSCFGPROFILE_FILEPROJECTS);
   if (!NofProfiles) {
      _xmlcfg_close(dest_handle);
      return error;
   }

   default_profile:=_plugin_get_property(VSCFGPACKAGE_LANGUAGE,langId,VSCFGP_FILEPROJECT_DEFAULT_PROFILE);
   _xmlcfg_export_property(dest_handle,VSCFGPACKAGE_LANGUAGE,langId,VSCFGPROFILE_LANGUAGE_VERSION,VSCFGP_FILEPROJECT_DEFAULT_PROFILE,default_profile);
   justName:=vsCfgPackage_for_LangFileProjectProfiles(langId)'.cfg.xml';
   destFilename:=file:+justName;
   status:=_xmlcfg_save(dest_handle,-1,VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE,destFilename);
   if (status) {
      error=get_message(status);
   }
   //_showxml(dest_handle);
   _xmlcfg_close(dest_handle);
   file=justName;
   return error;
}

_str _file_project_profiles_form_import_settings(_str &file, _str &args, _str langId)
{
   error := '';
   if (file!='') {
      if(gfp_curProject && _tbDebugQMode()) {
         return "Can't import single file project profiles while debugging a single file project";
      }
      _xmlcfg_import_from_file(file);
      _fileProjectRecache();
   }
   return error;
}
void _config_reload_fileproject() {
   // Empty the language project cache
   gfp_Lang2Handle._makeempty();
   // Empty as much of the file project cache as possible.
   if (gfp_curProject>=0) {
      //say('have cur project');
      //say('gfp_curLangId='gfp_curLangId);
      //say('gfp_curAbsFilename='gfp_curAbsFilename);
      fileKey := gfp_curLangId:+"\1":+gfp_curAbsFilename;
      if (!gfp_File2Handle._indexin(fileKey)) {
         // We are lost
         return;
      }
      cur_info:=gfp_File2Handle:[fileKey];
      FILEPROJECT_INFO info;
      foreach (auto k => info in gfp_File2Handle) {
         if (k!=fileKey) {
            if(isinteger(info.m_handle) && info.m_handle>=0) {
               _xmlcfg_close(info.m_handle);
            } else {
               //say('info.handle has bad value');
            }
         } else {
            //say('found fileKey');
         }
      }
      gfp_File2Handle._makeempty();
      gfp_File2Handle:[fileKey]=cur_info;
   } else {
      FILEPROJECT_INFO info;
      foreach (auto k => info in gfp_File2Handle) {
         if(isinteger(info.m_handle) && info.m_handle>=0) {
            _xmlcfg_close(info.m_handle);
         }
      }
      gfp_File2Handle._makeempty();
   }
}

