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
#include "xml.sh"
#import "compile.e"
#import "listbox.e"
#import "main.e"
#import "packs.e"
#import "picture.e"
#import "projconv.e"
#import "project.e"
#import "projutil.e"
#import "stdprocs.e"
#import "wkspace.e"
#import "fileproject.e"
#endregion

static _str gProjectName;
static int gProjectHandle;
static int gOrigProjectHandle;
static bool gIsProjectTemplate;
static bool gIsProjectTemplate;
static int gIsExtensionProject;

defeventtab _project_config_form;


int _OnUpdate_project_config(CMDUI &cmdui,int target_wid,_str command)
{
   if (_workspace_filename=='' || _project_name=='') {
      return(MF_GRAYED);
   }
   return(MF_ENABLED);
}

//#define USE_FILES            ctlok.p_user
static int SEL_CONFIG_LINENUM(...) {
   if (arg()) ctlConfigNew.p_user=arg(1);
   return ctlConfigNew.p_user;
}
static int CHANGING_CONFIG(...) {
   if (arg()) ctlCancel.p_user=arg(1);
   return ctlCancel.p_user;
}
static int NO_RECURSIVE_CHANGE(...) {
   if (arg()) ctlSetActive.p_user=arg(1);
   return ctlSetActive.p_user;
}
static ProjectConfig CURRENT_CONFIG_LIST(...)[] {
   if (arg()) ctlConfigDelete.p_user=arg(1);
   return ctlConfigDelete.p_user;
}


void ctlok.on_destroy()
{
   _xmlcfg_close(gProjectHandle);
}
ctlok.on_create(int ProjectHandle,bool IsProjectTemplate,int IsExtensionProject)
{
   _project_config_form_initial_alignment();

   gOrigProjectHandle=ProjectHandle;
   gIsProjectTemplate=IsProjectTemplate;
   gIsExtensionProject=IsExtensionProject;
   gProjectName=_xmlcfg_get_filename(ProjectHandle);

   // Make a copy of the original XML so we can cancel
   gProjectHandle=_xmlcfg_create(_xmlcfg_get_filename(ProjectHandle),VSENCODING_UTF8);
   _xmlcfg_copy(gProjectHandle,TREE_ROOT_INDEX,ProjectHandle,TREE_ROOT_INDEX,VSXMLCFG_COPY_CHILDREN);
   _xmlcfg_set_modify(gProjectHandle,0);

   // Internals.
   CHANGING_CONFIG(0); // Flag: 1=prevent recursion back to ctlConfigList.on_change()
   SEL_CONFIG_LINENUM(0);  // line number of selected configuration
   NO_RECURSIVE_CHANGE(0); // Flag: 1=inhibit recursive change to this control

   //say(gProjectName);
   // Get the list of configurations in the current project.

   associated := 0;
   int array[];
   ProjectConfig configList[];
   if (!IsProjectTemplate && !gIsExtensionProject && _IsWorkspaceAssociated(_workspace_filename)) {
      ctlConfigNew.p_enabled=false;
      ctlConfigDelete.p_enabled=false;
      int status = getProjectConfigs(gProjectName,configList, associated);
      if (status) return(status);
   } else {
      _ProjectGet_Configs(gProjectHandle,array);
      int i;
      for (i=0;i<array._length();++i) {
         configList[i].config=_xmlcfg_get_attribute(gProjectHandle,array[i],'Name');
         configList[i].objdir=_xmlcfg_get_attribute(gProjectHandle,array[i],'ObjectDir');
      }
   }
   // Fill the list box.
   _control ctltree1;
   wid := p_window_id;
   p_window_id=ctltree1;
   int i;
   for (i=0; i<configList._length(); i++) {
      _TreeAddItem(TREE_ROOT_INDEX,configList[i].config,TREE_ADD_AS_CHILD,_pic_fldopen,_pic_fldopen,-1);
   }
   if (!configList._length()) {
      ctlSetActive.p_enabled=false;
   }
   CURRENT_CONFIG_LIST(configList);


   // If config list is empty, disable combo textbox and Delete button.
   if (!configList._length()) {
      ctltree1.p_enabled = false;
      ctlConfigNew._set_focus();
      return(0);
   }
   if (configList._length()<2) {
      ctlConfigDelete.p_enabled = false;
   }

   index := 0;
   state := bm1 := bm2 := flags := 0;
   // IF we are NOT customing a project template and NOT customizing a single file language specific profile
   if (!gIsProjectTemplate && gIsExtensionProject!=2) {
      // Select the active configuration. If there is no active configuration,
      // select the first configuration in the list, if there is one.
      //_str activeConfig='';
      _str activeConfig;
      if (gIsExtensionProject) {
         activeConfig=_fileProjectConfig();
      } else {
         activeConfig=getActiveProjectConfig(gProjectName);
      }
      if (activeConfig == "") {
         //listwid.top();
         index=_TreeGetFirstChildIndex(TREE_ROOT_INDEX);
         _TreeGetInfo(index,state,bm1,bm2,flags);
         _TreeSetInfo(index,state,bm1,bm2,flags|TREENODE_BOLD);
      } else {
         // Separate objdir and config text.
         _str activeconfigtext=activeConfig;

         // Search for the matching active configuration.
         activeConfigLine := -1;
         for (i=0; i<configList._length(); i++) {
            if (activeconfigtext == configList[i].config) {
               activeConfigLine = i;
               break;
            }
         }
         if (activeConfigLine>-1) {
            //listwid.p_line = activeConfigLine;
            _TreeCurLineNumber(activeConfigLine);
            index=_TreeCurIndex();
            _TreeGetInfo(index,state,bm1,bm2,flags);
            _TreeSetInfo(index,state,bm1,bm2,flags|TREENODE_BOLD);
         } else {
            _TreeTop();
            //listwid.top();
         }
      }
   } else {
      ctlSetActive.p_enabled=false;
   }
   SEL_CONFIG_LINENUM(_TreeCurLineNumber());
   _str configinfo = _TreeGetCaption(_TreeCurIndex());
   //_str objdir = parseProjectConfigObjDir(configinfo, configList[listwid.p_line-1].objdir);
   _str objdir = parseProjectConfigObjDir(configinfo, configList[_TreeCurLineNumber()].objdir);
   selectProjectConfig(configinfo, objdir);
   p_window_id=wid;
   return(0);
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _project_config_form_initial_alignment()
{
   rightAlign := ctltree1.p_x_extent;
}

static bool BoldNodeExists()
{
   state := bm1 := bm2 := flags := 0;
   wid := p_window_id;
   _control ctltree1;
   p_window_id=ctltree1;
   index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   for (;index>-1;) {
      _TreeGetInfo(index,state,bm1,bm2,flags);
      if (flags&TREENODE_BOLD) {
         p_window_id=wid;
         return(true);
      }
      index=_TreeGetNextSiblingIndex(index);
   }
   p_window_id=wid;
   return(false);
}

static void UnboldAll()
{
   state := bm1 := bm2 := flags := 0;
   wid := p_window_id;
   _control ctltree1;
   p_window_id=ctltree1;
   index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   for (;index>-1;) {
      _TreeGetInfo(index,state,bm1,bm2,flags);
      _TreeSetInfo(index,state,bm1,bm2,flags&~TREENODE_BOLD);
      index=_TreeGetNextSiblingIndex(index);
   }
   p_window_id=wid;
}

static void BoldCurNode()
{
   wid := p_window_id;
   _control ctltree1;
   p_window_id=ctltree1;
   index := _TreeCurIndex();
   state := bm1 := bm2 := flags := 0;
   _TreeGetInfo(index,state,bm1,bm2,flags);
   _TreeSetInfo(index,state,bm1,bm2,flags|TREENODE_BOLD);
   p_window_id=wid;
}

void ctlSetActive.lbutton_up()
{
   UnboldAll();
   BoldCurNode();
   ctlok._set_focus();
}


// Copy the selected configuration text into the configuration text box
// and select it.
static void selectProjectConfig(_str config, _str objdir)
{
   // Set the config textbox.
   CHANGING_CONFIG(1); // Prevent recursion
   SEL_CONFIG_LINENUM(ctltree1._TreeCurLineNumber());
/*
   oldROState := ctlConfigText.p_ReadOnly;
   ctlConfigText.p_ReadOnly = false;
   ctlConfigText.p_text = config;
   ctlConfigText._set_sel(1, length(config)+1);
   ctlConfigText.p_ReadOnly = oldROState;
*/
   CHANGING_CONFIG(0);
}

/*void ctlConfigText.down,'C-K'()
{
   ctltree1._TreeDown();
}

void ctlConfigText.up,'C-I'()
{
   ctltree1._TreeUp();
}*/

void ctltree1.on_change(int reason)
{
   // Prevent recursion.
   if (CHANGING_CONFIG() == 1) return;

   // Set flag to prevent recursion.
   CHANGING_CONFIG(1);

   // Update the configuration list.
   if (reason == CHANGE_OTHER) {
      // Sync the text from the textbox and the corresponding
      // item in the listbox.
      //_str newtext = ctlConfigText.p_text;
      ctltree1._TreeCurLineNumber(SEL_CONFIG_LINENUM());

      // Update the array.
      ProjectConfig configList[];
      configList = CURRENT_CONFIG_LIST();
      //configList[ctltree1._TreeCurLineNumber()].config = newtextu;
      CURRENT_CONFIG_LIST(configList);
   } else if (reason == CHANGE_SELECTED) {
      // Update the text box component of the combo box.
      ProjectConfig configList[];
      configList = CURRENT_CONFIG_LIST();
      _str seltext = ctltree1._TreeGetCaption(_TreeCurIndex());
      _str objdir = parseProjectConfigObjDir(seltext, configList[ctltree1._TreeCurLineNumber()].objdir);
      selectProjectConfig(seltext,objdir);
   }

   // Clear the recursion flag.
   CHANGING_CONFIG(0);
}

void ctltree1.enter()
{
   ctlok.call_event(ctlok,LBUTTON_UP);
}

void ctlConfigNew.lbutton_up()
{
   // Enable the previously disable controls.
   if (ctltree1.p_enabled == false) {
      //ctlConfigText.p_enabled = true;
      ctlConfigDelete.p_enabled = true;
      ctltree1.p_enabled = true;
   }

   // Add new entry in array.
   wid := p_window_id;
   p_window_id=ctltree1;
   _TreeBottom();
   //_str text = '"CFG=New Configuration"';
   int index=_TreeCurIndex(),flags=0;
   if (index<0) {
      index=TREE_ROOT_INDEX;
      flags=TREE_ADD_AS_CHILD;
   }
   ProjectConfig configList[];
   configList = CURRENT_CONFIG_LIST();

   int SysTemplatesHandle=_ProjectOpenTemplates();
   typeless result=show('-modal _project_config_new_form',configList,SysTemplatesHandle);
   if (result=='') {
      _xmlcfg_close(SysTemplatesHandle);
      return;
   }
   _str NewConfigName=_param1;
   _str CopyFromConfig=_param2;
   int array[];
   _ProjectGet_Configs(gProjectHandle,array);
   int NewConfigNode;
   if (pos(';',CopyFromConfig)) {
      CopyFromTemplate := true;
      TemplateName := "";
      parse CopyFromConfig with TemplateName ';' CopyFromConfig;

      int Node=_ProjectTemplatesGet_TemplateNode(SysTemplatesHandle,TemplateName);
      Node=_ProjectTemplatesGet_TemplateConfigNode(SysTemplatesHandle,Node,CopyFromConfig);
      NewConfigNode=_xmlcfg_copy(gProjectHandle,array[array._length()-1],SysTemplatesHandle,Node,0);
      _ProjectTemplateExpand(SysTemplatesHandle,gProjectHandle);
   } else {
      NewConfigNode=_xmlcfg_copy(gProjectHandle,array[array._length()-1],gProjectHandle,_ProjectGet_ConfigNode(gProjectHandle,CopyFromConfig),0);
   }
   _xmlcfg_set_attribute(gProjectHandle,NewConfigNode,'Name',NewConfigName);
   _xmlcfg_close(SysTemplatesHandle);

   int newIndex=_TreeAddItem(index,NewConfigName,flags,_pic_fldopen,_pic_fldopen,-1);

   /*int newIndex=_TreeAddItem(index,text,flags,_pic_fldopen,_pic_fldopen,-1);
   ProjectConfig configList[];
   configList = CURRENT_CONFIG_LIST();
   PackageInfo pkgInfo;
   status=PromptForConfig(configList,pkgInfo);
   if (status) {
      _TreeDelete(newIndex);
      return;
   }*/
   count := configList._length();
   configList[count].config = NewConfigName;
   configList[count].objdir = "";
   //pkgInfo
   CURRENT_CONFIG_LIST(configList);


   // Append new line to listbox.
   ctltree1._TreeBottom();
   selectProjectConfig(ctltree1._TreeGetCaption(ctltree1._TreeCurIndex()),"");
   ctltree1._TreeBottom();
   //ctlConfigText._set_focus();
   ctltree1._set_focus();
   ctlConfigDelete.p_enabled = true;
   if (!BoldNodeExists()) {
      BoldCurNode();
   }
   p_window_id=wid;
}

/*void ctlConfigText.on_change()
{
   // Prevent recursion.
   if (CHANGING_CONFIG() == 1) return;

   // Set flag to prevent recursion.
   CHANGING_CONFIG(1);

   // Sync the text from the textbox and the corresponding
   // item in the listbox.
   newtext := ctlConfigText.p_text;
   ctltree1._TreeCurLineNumber(SEL_CONFIG_LINENUM());
   ctltree1._TreeSetCaption(ctltree1._TreeCurIndex(),newtext);

   // Update the array.
   ProjectConfig configList[];
   configList = CURRENT_CONFIG_LIST();
   configList[ctltree1._TreeCurLineNumber()].config = newtext;
   CURRENT_CONFIG_LIST(configList);

   // Clear the recursion flag.
   CHANGING_CONFIG(0);
}*/

void ctlConfigDelete.lbutton_up()
{
   // Special case for empty list.
   if (ctltree1._TreeGetFirstChildIndex(TREE_ROOT_INDEX)<0) {
      return;
   }


   // Delete current item from config list box.
   int ii = SEL_CONFIG_LINENUM();


   _str config=ctltree1._TreeGetCaption(ctltree1._TreeCurIndex());
   int Node=_ProjectGet_ConfigNode(gProjectHandle,config);
   _xmlcfg_delete(gProjectHandle,Node);
   ctltree1._TreeCurLineNumber(ii);
   ctltree1._TreeDelete(ctltree1._TreeCurIndex());

   // Remove item from config array.
   ProjectConfig configList[];
   configList = CURRENT_CONFIG_LIST();
   configList._deleteel(ii);
   CURRENT_CONFIG_LIST(configList);

   ChildIndex := ctltree1._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   // For empty list, clear the textbox.
   if (ChildIndex < 0) {
      //CHANGING_CONFIG(1); // prevent recursion
      //ctlConfigText.p_text = "";
      //CHANGING_CONFIG(0);
      //ctlConfigDelete.p_enabled = false;

      // Disable the controls.
      //ctlConfigText.p_enabled = false;
      ctlConfigDelete.p_enabled = false;
      ctltree1.p_enabled=false;
      ctlConfigNew._set_focus();
      return;
   }else{
      SiblingIndex := ctltree1._TreeGetNextSiblingIndex(ChildIndex);
      if (SiblingIndex<0) {
         ctlConfigDelete.p_enabled = false;
      }
   }

   // Select new configuration in list.

   ii=ctltree1._TreeCurLineNumber();
   SEL_CONFIG_LINENUM(ii);
   _str seltext = ctltree1._TreeGetCaption(ctltree1._TreeCurIndex());
   _str objdir = parseProjectConfigObjDir(seltext, configList[ii].objdir);
   selectProjectConfig(seltext, objdir);


   ctltree1._TreeCurLineNumber(ii);
   //ctlConfigText._set_focus();
   if (!BoldNodeExists()) {
      BoldCurNode();
   }
   ctltree1._set_focus();
}

void ctlok.lbutton_up()
{
   // Check to see if any of the original configurations has been
   // changed.
   ProjectConfig configList[];
   configList = CURRENT_CONFIG_LIST(); // current values

   int modified = _xmlcfg_get_modify(gProjectHandle);

   wid := p_window_id;
   p_window_id=ctltree1;

   state := bm1 := bm2 := flags := 0;
   index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   i := 0;
   for (;index>-1;++i) {
      _TreeGetInfo(index,state,bm1,bm2,flags);
      if (flags&TREENODE_BOLD) {
         break;
      }
      index=_TreeGetNextSiblingIndex(index);
   }

   p_window_id=wid;
   ConfigName := "";
   if (i<configList._length()) {
      ConfigName=configList[i].config;
   }
   _param1=ConfigName;
   //_param2=configList[i].objdir','configList[i].config;
   // Nothing was changed!
   if (!modified) {
      // Since only the active config changed, just say we cancelled.
      p_active_form._delete_window(0);
      return;
   }
   // Copy the new xml back to the original

   _xmlcfg_delete(gOrigProjectHandle,TREE_ROOT_INDEX,true);
   _xmlcfg_copy(gOrigProjectHandle,TREE_ROOT_INDEX,gProjectHandle,TREE_ROOT_INDEX,VSXMLCFG_COPY_CHILDREN);

   //_ProjectCache_Update(gProjectName);  Project properites dialog does this

   p_active_form._delete_window(1);
   return;
}

// Check to see if the configuration ii specified in configList1
// is the same as the one stored in configList2.
// Retn: 1 same, 0 not
static int isConfigSame(int ii, ProjectConfig (&configList1)[]
                        ,ProjectConfig (&configList2)[])
{
   int i;
   for (i=0; i<configList2._length(); i++) {
      if (configList1[ii].config == configList2[i].config
          && configList1[ii].objdir :== configList2[i].objdir) {
         // Found it and it is the same.
         return(1);
      }
   }

   // Either it is not found or a match was not found.
   return(0);
}
// Parse the project configuration objdir from the config text and
// the specified objdir. The algorithm goes like this:
//    1. If objdir is non-blank, return it.
//    2. If configinfo has format  "something - word odir",
//       odir will be returned.
//    3. "" returned
static _str parseProjectConfigObjDir(_str configinfo, _str objdir)
{
   if (objdir != "") return(objdir);
   //11:59am 8/13/1999
   //Dan added BUILD_SPEC for Tornado 2.0
   if (pos('CFG={?*}($|")',configinfo,1,'ri') ) {
      objdir=_vcGetObjDir(configinfo);
      return(objdir);
   }else if (pos('BUILD_SPEC={?@}($|)',configinfo,1,'ri')) {
      parse substr(configinfo,pos('S0'),pos('0')) with objdir;
      if (objdir!='') {
         objdir='.'FILESEP:+objdir;
         _maybe_append_filesep(objdir);
      }
      return(objdir);
   }
   return("");
}

defeventtab _project_config_new_form;


ctlok.on_create(ProjectConfig configList[],int SysTemplatesHandle)
{
   // add our configs to the "copy from" combo box
   for (i := 0; i < configList._length(); i++) {
      ctlcopy_settings_from._lbadd_item(configList[i].config);
   }
   ctlcopy_settings_from._lbsort('i');

   // go to the bottom and
   ctlcopy_settings_from._lbbottom();

   // get project template notes, too
   int array[];
   _ProjectTemplatesGet_TemplateNodes(SysTemplatesHandle, array);

   for (i=0; i<array._length(); ++i) {

      // get the name attribute
      _str Name=_xmlcfg_get_attribute(SysTemplatesHandle,array[i],'Name');
      
      // see if this template should be shown
      if(!_ignoreProjectPackage(SysTemplatesHandle, array[i],false)) continue;

      // get the config names, add them to the list
      typeless ConfigList[];
      _xmlcfg_find_simple_array(SysTemplatesHandle,"Config",ConfigList,array[i]);
      for (j := 0; j < ConfigList._length(); ++j) {
         ctlcopy_settings_from._lbadd_item(Name:+';':+_xmlcfg_get_attribute(SysTemplatesHandle,ConfigList[j],'Name'));
      }
   }

   ctlcopy_settings_from._lbtop();
   ctlcopy_settings_from.p_text = ctlcopy_settings_from._lbget_text();
}

ctlok.lbutton_up()
{
   newName := ctlnew_config_name.p_text;
   if (newName=='') {
      _message_box(nls("New configuration must have a name"));
      return('');
   }
   if (ctlcopy_settings_from._lbfind_item(newName) >= 0) {
      _message_box(nls("A configuration named '%s1' already exists",newName));
      return('');
   }
   // Because we create directories based on configurations names don't allow some annoying
   // Windows or UNIX file characters
   // Can't allow double quotes since double quotes are used in C attribute
   // Shouldn't allow single quote so C attribute is more readable.
   chars := ';"''<>?*\/:$%';
   if (pos('['_escape_re_chars(chars)']',newName,1,'r')) {
      _message_box(nls("Invalid characters in configuration name"));
      return('');
   }
   _param1=newName;
   _param2=ctlcopy_settings_from.p_text;
   p_active_form._delete_window(0);
   return(0);
}
