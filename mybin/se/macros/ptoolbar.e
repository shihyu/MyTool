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
#include "project.sh"
#include "scc.sh"
#include "xml.sh"
#require "se/lang/api/ExtensionSettings.e"
#import "backtag.e"
#import "compile.e"
#import "complete.e"
#import "context.e"
#import "cvs.e"
#import "dir.e"
#import "files.e"
#import "guiopen.e"
#import "ini.e"
#import "listproc.e"
#import "main.e"
#import "makefile.e"
#import "menu.e"
#import "mprompt.e"
#import "picture.e"
#import "projconv.e"
#import "project.e"
#import "projmake.e"
#import "projutil.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "tags.e"
#import "tbprojectcb.e"
#import "toast.e"
#import "toolbar.e"
#import "treeview.e"
#import "xmlcfg.e"
#import "unittest.e"
#import "util.e"
#import "vc.e"
#import "vstudiosln.e"
#import "wkspace.e"
#endregion

using se.lang.api.ExtensionSettings;

defeventtab _yesToAll_form;

void ctlYes.on_create(_str question="", _str caption="", boolean showNoToAll=true)
{
   ctlMsg.p_caption = question;
   p_active_form.p_caption = caption;
   ctlNoToAll.p_enabled=showNoToAll;
   ctlNoToAll.p_visible=showNoToAll;
   parse question with question "\n" .;
   int x = ctlMsg._text_width(question);
   if (x > ctlMsg.p_width) {
      x = x - ctlMsg.p_width + 100;
      ctlMsg.p_width = ctlMsg.p_width + x;
      p_active_form.p_width = p_active_form.p_width + x;
      ctlCancel.p_x = ctlCancel.p_x + x;
   }
}

void yesToAllExit(_str msg)
{
   int fid;
   fid= p_active_form;
   fid._delete_window(msg);
}

void ctlYes.lbutton_up()
{
   yesToAllExit("YES");
}

void ctlYesToAll.lbutton_up()
{
   yesToAllExit("YESTOALL");
}

void ctlNoToAll.lbutton_up()
{
   yesToAllExit("NOTOALL");
}

void ctlNo.lbutton_up()
{
   yesToAllExit("NO");
}

void ctlCancel.lbutton_up()
{
   yesToAllExit("CANCEL");
}
#if __OS390__  || __TESTS390__
void _on_popup2_os390(_str menu_name,int menu_handle)
{
   if (menu_name=='_projtools_menu') {
      _menu_insert(menu_handle,-1,0,"-");
      _menu_insert(menu_handle,-1,0,"Dataset Filename","ctlinsert %df");
      _menu_insert(menu_handle,-1,0,"Dataset Member","ctlinsert %dm");
      _menu_insert(menu_handle,-1,0,"Dataset without member","ctlinsert %ds");
      _menu_insert(menu_handle,-1,0,"Dataset without last qualifier","ctlinsert %ds1");
      _menu_insert(menu_handle,-1,0,"Dataset without last 2 qualifiers","ctlinsert %ds2");
      _menu_insert(menu_handle,-1,0,"Dataset without last 3 qualifiers","ctlinsert %ds3");
      _menu_insert(menu_handle,-1,0,"First qualifier","ctlinsert %dq1");
      _menu_insert(menu_handle,-1,0,"Second qualifier","ctlinsert %dq2");
      _menu_insert(menu_handle,-1,0,"Third qualifier","ctlinsert %dq3");
   }
}
#endif

defeventtab _tbprojects_form;

#if __MACOSX__
void _tbprojects_form.'C-A'-'C-Z',F2-F4,'a-m-a'-'a-m-z','c-a-a'-'c-a-z','M-A'-'M-Z','S-M-A'-'S-M-Z'()
#else
void _tbprojects_form.'C-A'-'C-Z',F2-F4,f6-F12,C_F12,'c-a-a'-'c-a-z','a-0'-'a-9'()
#endif
{
   _control _proj_tooltab_tree;
   if (last_event():==C_V && p_name=='_proj_tooltab_tree') {
      projecttbPaste();
      return;
   }
   if (last_event():==C_C && p_name=='_proj_tooltab_tree') {
      projecttbCopy();
      return;
   }
   if (last_event():==C_X  && p_name=='_proj_tooltab_tree') {
      projecttbCut();
      return;
   }
   _smart_toolbar_hotkey();
}

void _proj_tooltab_tree.on_create(_str projectName="")
{
   if (projectName == "") {
      projectName= _project_name;
   }
   _TreeColWidth(0, 5000);  // Just init to some value

   #if __MACOSX__
   macSetShowsFocusRect(p_window_id, 0);
   #endif

   // Add files
   toolbarUpdateFilterList(projectName);

   toolbarRestoreState();
}

void toolbarSaveExpansion()
{
   int formid= _find_object("_tbprojects_form","N");
   if (!formid) {
      return;
   }
   _str array[];
   formid._proj_tooltab_tree._GetProjTreeStates(array);
   int temp_view_id=0;
   int orig_view_id=_create_temp_view(temp_view_id);
   int i;
   for (i=0;i<array._length();++i) {
      insert_line(array[i]);
   }
   _str workspaceStateFileName = VSEWorkspaceStateFilename(_workspace_filename);
   _ini_put_section(workspaceStateFileName,"TreeExpansion2",temp_view_id);
   activate_window(orig_view_id);
}

void _tbprojects_form.on_destroy()
{
   if (_workspace_filename!='') {
      toolbarSaveExpansion();
   }
   // Call user-level2 ON_DESTROY so that tool window docking info is saved
   call_event(p_window_id,ON_DESTROY,'2');
}
void _proj_tooltab_tree.on_destroy()
{
   // moved to form's on_destroy
}

static void resizeProjects()
{
   int clientW = _dx2lx(p_active_form.p_xyscale_mode,p_active_form.p_client_width);
   int clientH = _dy2ly(p_active_form.p_xyscale_mode,p_active_form.p_client_height);

   _proj_tooltab_tree.p_width=clientW;
   _proj_tooltab_tree.p_height=clientH;
}

void _tbprojects_form.on_resize()
{
   resizeProjects();
}

static void delayedSizeColumnToContents(int wid)
{
   if ( _iswindow_valid(wid) && wid.p_name=="_proj_tooltab_tree" ) {
      wid._TreeSizeColumnToContents(0);
   }
}

//2:37pm 7/20/2000 Tested after move from project.e
void _proj_tooltab_tree.on_change(int reason, int index)
{
   switch (reason) {
   case CHANGE_COLLAPSED:
      // do nothing for CHANGE_COLLAPSED
      break;
   case CHANGE_LEAF_ENTER:
      if ( _projecttbIsProjectFileNode(index) ) {
         _str curproject=_projecttbTreeGetCurProjectName(-1,true);
         _str caption= _TreeGetCaption(index);
         _str name="";
         _str fullPath="";
         parse caption with name "\t" fullPath;
         fullPath=absolute(fullPath,_strip_filename(curproject,'N'));
         projecttbMaybeEditFile(index, name, fullPath);
         return;
      }else if ( _projecttbIsProjectNode(index) && 
                 _TreeGetFirstChildIndex(index)<0 ) {
         _TreeGetInfo(index,auto state);
         toolbarBuildFilterList(_projecttbTreeGetCurProjectName(index),index);
         _TreeSetInfo(index,(int)!state);
         // Rebuilding the filter list for the project just expanded
         // will re-set the current index. Refocus the project node
         _TreeSetCurIndex(index);
      }
      break;
   case CHANGE_EXPANDED:
      if (_projecttbIsProjectNode(index)
          && _TreeGetFirstChildIndex(index)<0
          ) {
         toolbarBuildFilterList(_projecttbTreeGetCurProjectName(index),index);
         // Rebuilding the filter list for the project just expanded
         // will re-set the current index. Refocus the project node
         _TreeSetCurIndex(index);
      } else {
         _post_call(delayedSizeColumnToContents,p_window_id);
      }
   }
}
// Desc: Get the filter application command and use file association that
//       correspond to the filter name.
// Retn: 0 found item, 1 not found
//2:41pm 7/20/2000 Tested after move from project.e
static int projecttbGetFileAssociationCommand(_str filePath, _str & appCommand ,int & assocType)
{
   // initialize variables!
   appCommand = '';
   assocType = 0;

   ext := _get_extension(filePath);
   if(ext != '') {
      ext = lowcase(ext);
      appCommand = ExtensionSettings.getOpenApplication(ext, '');
      assocType = (int)ExtensionSettings.getUseFileAssociation(ext);
   }

   return(1);
}

//2:40pm 7/20/2000 Tested after move from project.e
static void projecttbMaybeEditFile(int index, _str name, _str fullPath)
{
   // Determine if file type association needs to be applied
   // to this file. These are defined in defaults.e where you
   // see setup_association calls.
   int assocType;
   _str appCommand;
   projecttbGetFileAssociationCommand(fullPath, appCommand, assocType);

#if __UNIX__
   // On Unix, we don't have file type association. This should be false
   // all the time on Unix anyway. This is only a precaution in case
   // something slips thru the crack.
   assocType= 0;
#endif
   if (substr(fullPath,1,1)=='*') {
      fullPath=substr(fullPath,2);
   }

   // If file association is not used, check the application
   // command and use it instead.
   if (!assocType) {
      if (appCommand != "") {
         _projecttbRunAppCommand(appCommand, maybe_quote_filename(fullPath));
      } else {
         edit(maybe_quote_filename(fullPath),EDIT_DEFAULT_FLAGS);
      }
      return;
   }

   _str msg="";
   typeless status=0;

#if 1
   if (machine()=='WINDOWS') {
#if __NT__
      /*
         ON Windows XP, "open" and "edit" don't seem to work but "null" does.
         On NT "null" seems to work too.  I don't really know what's going on here
         but since null works, it doesn't matter.
      */
      status=NTShellExecute(null,fullPath,"","");
      //status=NTShellExecute("open",fullPath,"","");
      if (status<=32) {
         switch (status) {
         case 0:
            msg='Out of memory/resources';
            break;
         case 1:
            // I seem to get this code if there is no association in the registry
            msg='Possible missing association';
            break;
         case 2:
            msg='File not found';
            break;
         case 3:
            msg='Path not found';
            break;
         case 11:
            msg='Bad format';
            break;
         case 26:
            msg='Sharing violation';
            break;
         case 27:
            msg='Invalid/incomplete association';
            break;
         case 28:
            msg='DDE timed out';
            break;
         case 29:
            msg='DDE failed';
            break;
         case 30:
            msg='DDE busy';
            break;
         case 31:
            msg='No association';
            break;
         default:
            msg='Unknown error';
         }
         if ( status==2 || status==3 ) {
            // File not found OR Path not found
            _message_box(msg:+"\n\nUnable to open ":+fullPath);
         } else {
            projecttbOptionalEdit(msg:+"\n\nUnable to open ", fullPath, fullPath);
         }
         //projecttbOptionalEdit("Unable to open ", fullPath, fullPath);
      }
#endif
   } else {
      edit(maybe_quote_filename(fullPath),EDIT_DEFAULT_FLAGS);
      return;
   }
#else
   // Look up the file association table and run the proper program:
   // Currently only valid for Win95 and NT.  For other platforms,
   // just edit the file in the editor.
   if ((_win32s() != 2) && (substr(machine(),1,2) != "NT")) {
      edit(maybe_quote_filename(fullPath),EDIT_DEFAULT_FLAGS);
      return;
   }

   // Look up registry for associated application:
   _str ext= lowcase(get_extension(name));
   if (ext== "") {
      edit(maybe_quote_filename(fullPath),EDIT_DEFAULT_FLAGS);
      return;
   }
   _str value;
   _str regKey;
   regKey= "SOFTWARE\\Classes\\." :+ ext;
   value= _ntRegQueryValue(HKEY_LOCAL_MACHINE, regKey,"");
   if (value== "") {
      projecttbOptionalEdit("Unable to determine associated application for file ",
                            name, fullPath);
      return;
   }
   _str appExe;
   regKey= "SOFTWARE\\Classes\\" :+ value :+ "\\shell\\open\\command";
   appExe= _ntRegQueryValue(HKEY_LOCAL_MACHINE, regKey, "");
   if (appExe== "") {
      projecttbOptionalEdit("Unable to locate associated application for file ",
                            name, fullPath);
      return;
   }
   //say( "appExe="appExe );
   _str exeCmd;
   if (parseExeAndFileCommand(appExe, fullPath, exeCmd)) {
      projecttbOptionalEdit("Unable to execute associated application for file ",
                            name, fullPath);
      return;
   }
   //say( "exeCmd="exeCmd );
   ec= shell( exeCmd, 'AN' );
   if (ec) {
      projecttbOptionalEdit("Unable to execute ", exeCmd, fullPath);
   }
#endif
}
static void projecttbOptionalEdit(_str msg, _str name, _str fullPath)
{
   int idval;
   idval= _message_box(msg :+ name :+ ".\n\nEdit file in SlickEdit?",
                        "", MB_YESNO|MB_ICONQUESTION);
   if (idval== IDNO) return;
   edit(maybe_quote_filename(fullPath),EDIT_DEFAULT_FLAGS);
   return;
}

//2:42pm 7/20/2000 Tested after move from project.e
_command int projecttbSetCurProject() name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   if (p_name!='_proj_tooltab_tree') {
      return(1);
   }
   int curIndex=_TreeCurIndex();
   _str WholePath=_projecttbTreeGetCurProjectName(curIndex);
   workspace_set_active(WholePath);
   return(0);
}

typedef void (*pfnTreeSelCallback_tp)(int index,_str name,_str fullPath);

// Tree must be active
static void TreeWithSelection(pfnTreeSelCallback_tp pfn)
{
   int currIndex;
   _str name='', fullPath='';
   int treeWid=p_window_id;
   int info;
   for (ff:=1;;ff=0) {
      int index=_TreeGetNextSelectedIndex(ff,info);
      if (index<0) break;
      if (getTreeFile(treeWid, index, name, fullPath)) {
         continue;
      }
      (*pfn)(index,name,fullPath);
      p_window_id=treeWid;
   }
}

//2:40pm 7/20/2000 Tested after move from project.e
_command projecttbEditFile() name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   int treeWid, currIndex;
   _str name, fullPath;
   treeWid= _find_object("_tbprojects_form._proj_tooltab_tree",'N');
   if (treeWid) {
      treeWid.TreeWithSelection(projecttbMaybeEditFile);
   }
}

//2:43pm 7/20/2000 Tested after move from project.e
_command projecttbCheckin() name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   int treeWid, currIndex;
   _str name, fullPath;
   if (getCurrentTreeFile(treeWid, currIndex, name, fullPath)) {
      return(0);
   }
   //checkin("", fullPath);
   vccheckin(fullPath);
}

//2:43pm 7/20/2000 Tested after move from project.e
_command projecttbCheckout() name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   int treeWid, currIndex;
   _str name, fullPath;
   if (getCurrentTreeFile(treeWid, currIndex, name, fullPath)) {
      return(0);
   }
   //checkout("", fullPath);
   vccheckout(fullPath);
}

//2:44pm 7/20/2000 Tested after move from project.e
// shackett: changed the default value of allowDependentProjects to be true.  If you look at the logic,
// if this is true and the current node is not a project, then it just keeps getting the parent until 
// that parent is a project.  If this is false, then it just keeps getting the parent up to a depth 
// of 1, and assumes that's get's the immediate parent and assumes the current project.  The first case 
// really covers the second.
_str _projecttbTreeGetCurProjectName(int index=-1,boolean allowDependentProjects=true,int &ProjectIndex= -1)
{
   if (index<0) {
      index=_TreeCurIndex();
   }
   if (index==TREE_ROOT_INDEX) {
      return(_project_name);
   }
   if (allowDependentProjects) {
      while (!_projecttbIsProjectNode(index)) {
         if (index==TREE_ROOT_INDEX) {
            return(_project_name);
         }
         index=_TreeGetParentIndex(index);
      }
   } else {
      while (_TreeGetDepth(index)>1) {
         index=_TreeGetParentIndex(index);
      }
   }

   _str ProjectName="";
   _str name=_TreeGetCaption(index);
   _str relpath="";
   parse name with name "\t" relpath;
   if (_IsEclipseWorkspaceFilename(_workspace_filename)) {
      // For eclipse we only put the name of the file and the directory, but
      // not the whole file.  It looks a little more like the way Eclipse
      // actually does things that way.
      ProjectName=VSEProjectFilename(_AbsoluteToWorkspace(relpath:+name:+PRJ_FILE_EXT));
   }else{
      ProjectName=VSEProjectFilename(_AbsoluteToWorkspace(relpath));
   }
   ProjectIndex=index;
   return(ProjectName);
}

static _str _projecttbTreeGetCurFolderPath(int index = -1)
{
   if (index<0) {
      index=_TreeCurIndex();
   }

   // this only makes sense in directory view
   projName := _projecttbTreeGetCurProjectName(index);
   handle := _ProjectHandle(projName);
   if (!_projecttbIsFolderNode()) {
      return '';
   }

   // we have to build a path
   path := '';

   autoFolders := _ProjectGet_AutoFolders(handle);
   if (strieq(autoFolders, VPJ_AUTOFOLDERS_DIRECTORYVIEW)) {
      // start with our folder name
      caption := _TreeGetCaption(index);
      path = caption;
   
      // go up until we get a project node
      index = _TreeGetParentIndex(index);
      while (!_projecttbIsProjectNode(index)) {
         caption = _TreeGetCaption(index);
         path = caption :+ FILESEP :+ path;
   
         index = _TreeGetParentIndex(index);
      }
   
      // we should be at a project node now
      caption = _TreeGetCaption(index);
      parse caption with auto name "\t" auto projPath;
      if (!_IsEclipseWorkspaceFilename(_workspace_filename)) {
         // For eclipse we only put the name of the file and the directory, but
         // not the whole file.  It looks a little more like the way Eclipse
         // actually does things that way.
         projPath = _strip_filename(projPath, 'N');
      }
      path = _AbsoluteToWorkspace(projPath) :+ path;
   } else if (strieq(autoFolders, VPJ_AUTOFOLDERS_PACKAGEVIEW)) {

      // start with our folder name
      path = _TreeGetCaption(index);
      stranslate(path, FILESEP, '.');
   
      // get the project node (should be one up)
      index = _TreeGetParentIndex(index);
   
      // we should be at a project node now
      caption := _TreeGetCaption(index);
      parse caption with auto name "\t" auto projPath;
      if (!_IsEclipseWorkspaceFilename(_workspace_filename)) {
         // For eclipse we only put the name of the file and the directory, but
         // not the whole file.  It looks a little more like the way Eclipse
         // actually does things that way.
         projPath = _strip_filename(projPath, 'N');
      }
      path = _AbsoluteToWorkspace(projPath) :+ path;
   }

   return path;
}

#define YesToAll(a,b) (a&&status==2)
#define NoRemove(a,b) ( (a && b==3) || (!a && b==2))

//3:26pm 7/20/2000 Tested after move from project.e
static int RemoveFromProjectAndVC(_str fullPath,
                                  boolean &LastPromptRemove=false,
                                  boolean &LastPromptVC=false,
                                  boolean &DeleteFromDisk=false,
                                  boolean UseYesToAll=true,
                                  _str CurProjectName=_project_name,
                                  boolean CacheProjects_TagFileAlreadyOpen=false)
{
   _str buttons="";
   int status = 0;
   if (!LastPromptRemove) {
      if (UseYesToAll) {
         buttons="Yes,Yes to &All,No,Cancel:_cancel\tRemove file '"fullPath"' from project?";
      }else{
         buttons="Yes,No,Cancel:_cancel\tRemove file '"fullPath"' from project?";
      }
      status=textBoxDialog('Remove Files From Project',
                           0,
                           0,
                           "",
                           buttons,
                           "",
                           "-checkbox Delete permanently from disk:0");
      if( status<0 ) {
         return(status);
      }
      if (YesToAll(UseYesToAll,status)) {
         LastPromptRemove=true;
      }
      DeleteFromDisk= ( _param1 == 1 );
   }
   boolean DontRemove=NoRemove(UseYesToAll,status);

   if (!DontRemove) {
      status=project_remove_filelist(CurProjectName,maybe_quote_filename(fullPath),CacheProjects_TagFileAlreadyOpen);
      if( status==0 && DeleteFromDisk ) {
         status=recycle_file(fullPath);
         if( status!=0 ) {
            _str msg = "Warning: Could not delete file. "get_message(status):+"\n\n":+
                       fullPath;
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            return status;
         }
      }
   }
   _str Files[];
   Files._makeempty();
   if ( (machine()=='WINDOWS' && _isscc() && _SCCProjectIsOpen() ) ||
        _VCSCommandIsValid(VCS_REMOVE) ) {
      status=0;
      if (!LastPromptVC) {
         buttons="Yes,Yes to &All,No,Cancel:_cancel\tRemove file '"fullPath"' from version control?";
         status=textBoxDialog('Remove Files From Version Control',
                              0,
                              0,
                              "",
                              buttons);
         if (status<0) {
            return(status);
         }
         if (status==2) {
            LastPromptVC=true;
         }
      }
      if ( LastPromptVC || status==1 ) {
         status = vcremove(fullPath,true);
      }
      //if (LastPromptVC || status==1) {
      //   if (_isscc(_GetVCSystemName()) && machine()=='WINDOWS') {
      //      Files[0]=fullPath;
      //      _SccRemove(Files,'');
      //   } else {
      //      int temp_view_id=0;
      //      int orig_view_id=_create_temp_view(temp_view_id);
      //      p_window_id=orig_view_id;
      //      status=_misc_cl_vc_command(VCS_REMOVE,temp_view_id,fullPath,_GetVCSystemName(),0);
      //      if (status) {
      //         show('-modal _vc_error_form',temp_view_id);
      //      }
      //   }
      //}
   }
   return(0);
}

int _OnUpdate_projecttbRefilter(CMDUI &cmdui,int target_wid,_str command)
{
   if (target_wid && target_wid.p_object==OI_TREE_VIEW) {
      if (_workspace_filename=='') {
         return(MF_GRAYED);
      }
      _str ProjectName=target_wid._projecttbTreeGetCurProjectName();
      int handle=_ProjectHandle(ProjectName);

      if (_IsWorkspaceAssociated(_workspace_filename) && !_ProjectIs_SupportedXMLVariation(handle)
         ) {
         return(MF_GRAYED);
      }

      _str AutoFolders=_ProjectGet_AutoFolders(handle);
      if (strieq(AutoFolders,VPJ_AUTOFOLDERS_CUSTOMVIEW)) {
         return(MF_ENABLED);
      }
   }
   return(MF_GRAYED);
}
_command void projecttbRefilter() name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   int result=_message_box("Warning:  Refiltering files will reorganize all files including those you have manually placed in folders.\n\nContinue?",'',MB_YESNO|MB_ICONEXCLAMATION);
   if (result!=IDYES) {
      return;
   }
   int treeWid=p_window_id;
   _str ProjectName=_projecttbTreeGetCurProjectName();
   int handle=_ProjectHandle(ProjectName);

   if (_ProjectIs_SupportedXMLVariation(handle)) {
      handle=_ProjectGet_AssociatedHandle(handle);
   }
   _ProjectRefilter(handle);
   _ProjectSave(handle);
   _WorkspaceCache_Update();
   toolbarUpdateWorkspaceList();
}
_command void projecttbRefilterWildcards() name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   def_refilter_wildcards = (int)!(def_refilter_wildcards != 0);
   projecttbRefilter();
}

int _OnUpdate_projecttbRefilterWildcards(CMDUI &cmdui,int target_wid,_str command)
{
   return def_refilter_wildcards ? MF_CHECKED : MF_UNCHECKED;
}

int _OnUpdate_projecttbPaste(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdate_projecttbCut(cmdui,target_wid,command,true));
}
static boolean _ParentFolderCopied(int index)
{
   int showchildren=0, bm1=0, bm2NOLONGERUSED=0;
   while (index!=TREE_ROOT_INDEX) {
      index=_TreeGetParentIndex(index);
      _TreeGetInfo(index,showchildren,bm1,bm2NOLONGERUSED);
      if (bm1==_pic_tfldclosdisabled) {
         return(true);
      }
   }
   return(false);
}
static void AdjustFileConfigs(int DestHandle,int DestNode)
{
   _str configs=_xmlcfg_get_attribute(DestHandle,DestNode,'C');
   if (configs!='') {
      _str newconfigs='';
      int count=0;
      for (;;) {
         _str name=parse_file(configs,false);
         if (name=='') {
            break;
         }
         int ConfigNode=_ProjectGet_ConfigNode(DestHandle,name);
         if (ConfigNode>=0) {
            strappend(newconfigs,' 'always_quote_filename(name));
            ++count;
         }
      }
      int array[];
      _ProjectGet_Configs(DestHandle,array);
      if (count>=array._length()) {
         _xmlcfg_delete_attribute(DestHandle,DestNode,'C');
      } else {
         _xmlcfg_set_attribute(DestHandle,DestNode,'C',strip(newconfigs));
      }
   }
}
static void AdjustFolderCopy(int DestHandle,int SourceHandle,int Node,int (&DestFileToNode):[],int (&SourceFileToNode):[],_str option,
                             _str (&NewFilesList)[],_str (&DeletedFilesList)[],
                             int (&ExtToNodeHashTab):[],
                             int (&ObjectInfo):[],_str (&ConfigInfo)[]
                             )
{
   XMLVARIATIONS xmlv;
   _ProjectGet_XMLVariations(DestHandle,xmlv);
   //_message_box('N='FolderName' 2='Node2);
   if (SourceHandle==DestHandle && option=='T') {
   } else {
      _str FolderName=_xmlcfg_get_attribute(DestHandle,Node,'Name');
      _xmlcfg_set_attribute(DestHandle,Node,'Name','');
      int Node2=_ProjectGet_FolderNode(DestHandle,FolderName);
      if (Node2>=0) {
         int i;
         for (i=2;;++i) {
            Node2=_ProjectGet_FolderNode(DestHandle,FolderName' 'i);
            if (Node2<0) {
               break;
            }
         }
         _xmlcfg_set_attribute(DestHandle,Node,'Name',FolderName' 'i);
      } else {
         _xmlcfg_set_attribute(DestHandle,Node,'Name',FolderName);
      }
      _str filters=_ProjectGet_FolderFiltersAttr(DestHandle,Node);
      boolean MakeUpFilter=false;
      if (filters=='') {
         int *pnode=ExtToNodeHashTab._indexin('');
         if (pnode && *pnode!=_ProjectGet_FilesNode(DestHandle)) {
            MakeUpFilter=true;
         }
      } else {
         for (;;) {
            _str ext="";
            parse filters with ext ';' filters;
            parse ext with "*." ext;
            if (ext=='' && filters=='') {
               break;
            }
            if (ext!='') {
               if (ExtToNodeHashTab._indexin(lowcase(ext))) {
                  MakeUpFilter=true;
                  break;
               }
            }
         }
      }
      if (MakeUpFilter) {
         int i;
         for (i=1;;++i) {
            if (!ExtToNodeHashTab._indexin(i)) {
               break;
            }
         }
         _ProjectSet_FolderFiltersAttr(DestHandle,Node,'*.'i);
         ExtToNodeHashTab:[i]=Node;
      }
   }
   Node=_xmlcfg_get_first_child(DestHandle,Node);
   for (;Node>=0;) {
      int NextNode=_xmlcfg_get_next_sibling(DestHandle,Node);
      if (_xmlcfg_get_name(DestHandle,Node):==VPJTAG_FOLDER) {
         AdjustFolderCopy(DestHandle,SourceHandle,Node,DestFileToNode,SourceFileToNode,option,NewFilesList,DeletedFilesList,ExtToNodeHashTab,ObjectInfo,ConfigInfo);
      } else {
         _str RelFilename=translate(_xmlcfg_get_attribute(DestHandle,Node,xmlv.vpjattr_n),FILESEP,FILESEP2);
         _str DestRelFilename=_RelativeToProject(_AbsoluteToProject(RelFilename,_xmlcfg_get_filename(SourceHandle)),_xmlcfg_get_filename(DestHandle));
         if (SourceHandle!=DestHandle) {
            NewFilesList[NewFilesList._length()]=DestRelFilename;
         }
         int *pnode2=DestFileToNode._indexin(_file_case(DestRelFilename));
         int Node2=(pnode2)?*pnode2:-1;
         // IF this file is already in the project
         //_message_box('RelFilename='RelFilename' n2='Node2);
         if (Node2>=0) {
            /* move the old one and delete this one
            */
            *pnode2=_xmlcfg_copy(DestHandle,Node,DestHandle,Node2,0);
            _xmlcfg_delete(DestHandle,Node2);
            _xmlcfg_delete(DestHandle,Node);    // Delete this one
            Node2=*pnode2;
         } else {
            // Adjust the configs
            Node2=Node;
            AdjustFileConfigs(DestHandle,Node2);
            _ProjectSet_ObjectFileInfo(DestHandle,ObjectInfo,ConfigInfo,Node2,DestRelFilename);
         }

         _xmlcfg_set_attribute(DestHandle,Node2,xmlv.vpjattr_n,_NormalizeFile(DestRelFilename,xmlv.doNormalizeFile));
         DestFileToNode:[_file_case(DestRelFilename)]=Node2;
         if (option=='T') {
            SourceFileToNode._deleteel(_file_case(RelFilename));
            if (SourceHandle!=DestHandle) {
               DeletedFilesList[DeletedFilesList._length()]=RelFilename;
            }
         }
      }
      Node=NextNode;
   }
}
static void _CopyCutItems(int index,int DestTreeParentIndex,int DestHandle,int &DestNode,int &DestNodeFlags,int DestParent,int &DestParentFlags,int SourceHandle,int &error,int (&DestFileToNode):[],int (&SourceFileToNode):[],
                          _str (&NewFilesList)[],
                          _str (&DeletedFilesList)[],
                          int (&ObjectInfo):[],_str (&ConfigInfo)[])
{
   typeless array[];
   _str caption="";
   _str filename="";
   _str RelFilename="";
   typeless showchildren=0, option=0, bm1=0, bm2NOLONGERUSED=0;

   XMLVARIATIONS xmlv;
   _ProjectGet_XMLVariations(DestHandle,xmlv);
   index=_TreeGetFirstChildIndex(index);
   for (;index>=0;) {
      int next_index=_TreeGetNextSiblingIndex(index);
      _TreeGetInfo(index,showchildren,bm1,bm2NOLONGERUSED);
      if (bm1==_pic_doc_d && !_ParentFolderCopied(index)) {
         caption=_TreeGetCaption(index);
         parse caption with "\t" filename;
         parse _TreeGetUserInfo(index) with option' 'bm1' 'bm2NOLONGERUSED;

         RelFilename=_RelativeToProject(filename,_xmlcfg_get_filename(SourceHandle));
         _str DestRelFilename=_RelativeToProject(filename,_xmlcfg_get_filename(DestHandle));
         int *pnode=SourceFileToNode._indexin(_file_case(RelFilename));
         int Node=(pnode)?*pnode:-1;
         //_message_box('Node='Node' RelFilename='RelFilename' n='_xmlcfg_get_filename(SourceHandle));

         int *pnode2=DestFileToNode._indexin(_file_case(DestRelFilename));
         int Node2=(pnode2)?*pnode2:-1;
         if (Node2>=0) {
            // Move this source file
            *pnode2=DestNode=_xmlcfg_copy(DestHandle,DestNode,DestHandle,Node2,DestNodeFlags);
            _xmlcfg_set_attribute(DestHandle,DestNode,xmlv.vpjattr_n,_NormalizeFile(DestRelFilename,xmlv.doNormalizeFile));
            DestNodeFlags=0;
            _xmlcfg_delete(DestHandle,Node2);
            if (option=='T') {
               if (SourceHandle!=DestHandle) {
                  _xmlcfg_delete(SourceHandle,Node);
               }
               SourceFileToNode._deleteel(_file_case(RelFilename));
               DeletedFilesList[DeletedFilesList._length()]=RelFilename;
            }
            index=next_index;
            continue;
         }

         // Won't be able to find wildcard expand files since they are not expanded in the XML project file
         if (Node>=0) {
            DestNode=_xmlcfg_copy(DestHandle,DestNode,SourceHandle,Node,DestNodeFlags);
            _xmlcfg_set_attribute(DestHandle,DestNode,xmlv.vpjattr_n,_NormalizeFile(DestRelFilename,xmlv.doNormalizeFile));
            _ProjectSet_ObjectFileInfo(DestHandle,ObjectInfo,ConfigInfo,DestNode,DestRelFilename);
            DestFileToNode:[_file_case(DestRelFilename)]=DestNode;
            DestNodeFlags=0;
            if (option=='T') {
               _xmlcfg_delete(SourceHandle,Node);
               SourceFileToNode._deleteel(_file_case(RelFilename));
               if (SourceHandle!=DestHandle) {
                  // Add to files removed from source project.
                  DeletedFilesList[DeletedFilesList._length()]=RelFilename;
               }
            }

            parse _TreeGetUserInfo(index) with option' 'bm1;
            /*caption=_TreeGetCaption(index);
            _TreeGetInfo(index,showchildren,bm1,bm2NOLONGERUSED,moreflags);
            parse _TreeGetUserInfo(index) with bm1;
            parse caption with "\t" filename;
            _TreeAddItem(DestTreeParentIndex,caption,TREE_ADD_AS_CHILD,bm1,bm2NOLONGERUSED,showchildren,moreflags);
            _TreeDelete(index);*/
            if (SourceHandle!=DestHandle) {
               AdjustFileConfigs(DestHandle,DestNode);
            }
         } else {
            error=2;
         }
      } else if (bm1==_pic_tfldclosdisabled && !_ParentFolderCopied(index)) {
         //_message_box('folder');
         _str FolderName=_TreeGetCaption(index);
         int Node=_ProjectGet_FolderNode(SourceHandle,FolderName);

         int flags=0;
         if (DestParentFlags) {
            _xmlcfg_find_simple_array(DestHandle,xmlv.vpjtag_folder,array,DestParent);
            if (!array._length()) {
               int FirstChild=_xmlcfg_get_first_child(DestHandle,DestParent);
               if (FirstChild>=0) {
                  DestParent=FirstChild;
                  flags=VSXMLCFG_COPY_BEFORE;
               } else {
                  flags=VSXMLCFG_COPY_AS_CHILD;
               }
            } else {
               DestParent=array[array._length()-1];
            }
            DestParentFlags=0;
         }
         int ExtToNodeHashTab:[];
         _ProjectGet_ExtToNode(DestHandle,ExtToNodeHashTab);
         DestParent=_xmlcfg_copy(DestHandle,DestParent,SourceHandle,Node,flags);
         parse _TreeGetUserInfo(index) with option' 'bm1;
         AdjustFolderCopy(DestHandle,SourceHandle,DestParent,DestFileToNode,SourceFileToNode,option,NewFilesList,DeletedFilesList,ExtToNodeHashTab,ObjectInfo,ConfigInfo);
         if (option=='T') {
            _xmlcfg_delete(SourceHandle,Node);
         }

         /*caption=_TreeGetCaption(index);
         _TreeGetInfo(index,showchildren,bm1,bm2NOLONGERUSED,moreflags);
         parse _TreeGetUserInfo(index) with bm1' 'bm2NOLONGERUSED;
         _TreeAddItem(DestTreeParentIndex,caption,TREE_ADD_AS_CHILD,bm1,bm2NOLONGERUSED,showchildren,moreflags);*/
         //_TreeDelete(index);
      }
      if (showchildren>=0) {
         if (_projecttbIsProjectNode(index)) {
            SourceHandle=_ProjectHandle(_projecttbTreeGetCurProjectName(index));
            if (_ProjectIs_SupportedXMLVariation(SourceHandle)) {
               SourceHandle=_ProjectGet_AssociatedHandle(SourceHandle);
            }

            _ProjectGet_FileToNodeHashTab(SourceHandle,SourceFileToNode);
            _str DeletedFilesList2[];
            _CopyCutItems(index,DestTreeParentIndex, DestHandle,DestNode,DestNodeFlags,DestParent,DestParentFlags,SourceHandle,error,DestFileToNode,SourceFileToNode,NewFilesList,DeletedFilesList2,ObjectInfo,ConfigInfo);
            if (_xmlcfg_get_modify(SourceHandle) && SourceHandle!=DestHandle) {
               _ProjectSave(SourceHandle);
               // regenerate the makefile
               _maybeGenerateMakefile(_xmlcfg_get_filename(SourceHandle));
            }
            /*
               Not sure what to do for VCS yet.

              _MaybeAddFilesToVC(NewFilesList);
              //_AddAndRemoveFilesFromVC(NewFilesList,null,ProjectName);
            */
         } else {
            _CopyCutItems(index,DestTreeParentIndex,DestHandle,DestNode,DestNodeFlags,DestParent,DestParentFlags,SourceHandle,error,DestFileToNode,SourceFileToNode,NewFilesList,DeletedFilesList,ObjectInfo,ConfigInfo);
         }
      }
      index=next_index;
   }
}
_command void projecttbPaste() name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   if (_workspace_filename=='') {
      return;
   }
   if (!_isProjectTBCommandSupported('projecttbPaste')) return;
   _str ProjectName=_projecttbTreeGetCurProjectName();
   int DestHandle=_ProjectHandle(ProjectName);
   if (!_ProjectIs_AddDeleteFolderSupported(DestHandle)) {
      return;
   }
   if (_ProjectIs_SupportedXMLVariation(DestHandle)) {
      DestHandle=_ProjectGet_AssociatedHandle(DestHandle);
   }

   _str AutoFolders=_ProjectGet_AutoFolders(DestHandle);
   if (!strieq(AutoFolders,VPJ_AUTOFOLDERS_CUSTOMVIEW)) {
      _message_box("The AutoFolder setting must be 'Custom View' to paste");
      return;
   }
   if (_TreeGetDepth(_TreeCurIndex())<1) {
      return;
   }
   int DestTreeParentIndex=_TreeCurIndex();
   int DestParentFlags=VSXMLCFG_ADD_AS_CHILD;
   if (_projecttbIsProjectFileNode()) {
      DestTreeParentIndex=_TreeGetParentIndex(DestTreeParentIndex);
   }
   //if (_projecttbIsProjectFileNode()) {
   //   parse _TreeGetCaption(_TreeCurIndex()) with "\t" filename;
   //   RelFilename=_RelativeToProject(filename,ProjectName);

   int DestParent=0;
   if (_projecttbIsProjectNode(DestTreeParentIndex)) {
      DestParent=_ProjectGet_FilesNode(DestHandle);
   } else if (_projecttbIsFolderNode(DestTreeParentIndex)) {
      _str FolderName=_TreeGetCaption(DestTreeParentIndex);
      DestParent=_ProjectGet_FolderNode(DestHandle,FolderName);
   } else {
      return;
   }
   int DestNode=DestParent;
   int DestNodeFlags=VSXMLCFG_ADD_AS_CHILD;
   int error=0;
   int DestFileToNode:[];
   _ProjectGet_FileToNodeHashTab(DestHandle,DestFileToNode);
   _str NewFilesList[];

   int DollarTable:[];
   _str ConfigurationNames[];
   _ProjectGet_ObjectFileInfo(DestHandle,DollarTable,ConfigurationNames);

   _CopyCutItems(TREE_ROOT_INDEX,DestTreeParentIndex,DestHandle,DestNode,DestNodeFlags,DestParent,DestParentFlags,-1,error,DestFileToNode,null,NewFilesList,null,DollarTable,ConfigurationNames);

    /*
       Not sure what to do for VCS yet.

      _MaybeAddFilesToVC(NewFilesList);
      //_AddAndRemoveFilesFromVC(NewFilesList,null,ProjectName);
   */

   if (error) {
      switch (error) {
      case 2:
         _message_box("Can't Cut/Paste files from a wildcard expansion");
         break;
      }
   }

   int ExtToNodeHashTab:[];
   _ProjectGet_ExtToNode(DestHandle,ExtToNodeHashTab);

   _ProjectSortFolderNodesInHashTable(DestHandle,ExtToNodeHashTab);
   _ProjectSave(DestHandle);

   // regenerate the makefile
   _maybeGenerateMakefile(_xmlcfg_get_filename(DestHandle));

   _WorkspaceCache_Update();
   toolbarUpdateWorkspaceList();
}
int _OnUpdate_projecttbCut(CMDUI &cmdui,int target_wid,_str command,boolean doPaste=false)
{
   if (target_wid && target_wid.p_object==OI_TREE_VIEW) {
      if (_workspace_filename=='') {
         return(MF_GRAYED);
      }
      if (target_wid._projecttbIsWorkspaceItemNode()) {
         return(MF_ENABLED);
      }
      _str ProjectName=target_wid._projecttbTreeGetCurProjectName();
      int handle=_ProjectHandle(ProjectName);
      if (_ProjectIs_SupportedXMLVariation(handle)) {
         handle=_ProjectGet_AssociatedHandle(handle);
      }

      if ((!_ProjectIs_CutPasteSupported(handle))) {
         return(MF_GRAYED);
      }

      // if file/folder not found, it was added by a wildcard so disable
      // most of the operations on the menu
      _str caption = _TreeGetCaption(_TreeCurIndex());
      if(target_wid._projecttbIsFolderNode()) {
         if(target_wid._projecttbIsWildcardFolderNode() || _ProjectGet_FolderNode(handle, caption) < 0) {
            return MF_GRAYED;
         }
      } else if (doPaste && target_wid._projecttbIsProjectNode(-1,false)) {
      } else {
         _str name, fullpath;
         parse caption with name "\t" fullpath;
         if(_ProjectGet_FileNode(handle, _RelativeToProject(fullpath)) < 0) {
            return MF_GRAYED;
         }
      }

      _str AutoFolders=_ProjectGet_AutoFolders(handle);
      if (strieq(AutoFolders,VPJ_AUTOFOLDERS_CUSTOMVIEW)) {
         return(MF_ENABLED);
      }
   }
   return(MF_GRAYED);
}
static boolean _isProjectTBCommandSupported(_str command)
{
   CMDUI cmdui;
   cmdui.menu_handle=0;
   cmdui.menu_pos=0;
   cmdui.inMenuBar=0;
   cmdui.button_wid=1;
   _OnUpdateInit(cmdui,p_window_id);
   cmdui.button_wid=0;
   int mfflags=_OnUpdate(cmdui,p_window_id,command);
   if (!(mfflags&MF_ENABLED)) {
      // This error message is wrong in many cases so
      // just do nothing.
      //_message_box(nls("Delete not allowed for files added from wildcards"));
      return(false);
   }
   return(true);
}
int _OnUpdate_projecttbCopy(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdate_projecttbCut(cmdui,target_wid,command));
}
_command void projecttbCopy() name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   if (!_isProjectTBCommandSupported('projecttbCopy')) return;
   projecttbCut('C');
}
_command void projecttbCut(_str option='') name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   if (option=='') {
      if (!_isProjectTBCommandSupported('projecttbCut')) return;

      option='T';
   }
   if (_workspace_filename=='') {
      return;
   }
   /*
      Only cut selected files and folders items if AutoFolders is Custom View
   */

   boolean AddDeleteFileErrorDisplayed=false;
   boolean AddDeleteFolderErrorDisplayed=false;

   int showchildren=0, bm1=0, bm2NOLONGERUSED=0;
   int index=0;
   int info;
   for (ff:=1;;ff=0) {
      index=_TreeGetNextSelectedIndex(ff,info);
      if (index<0) break;
      if (_projecttbIsProjectFileNode(index)) {
         _str ProjectName=_projecttbTreeGetCurProjectName(index);
         if (_CanWriteFileSection(ProjectName)) {
            _TreeGetInfo(index,showchildren,bm1);
            _TreeSetInfo(index,showchildren,_pic_doc_d);
            _TreeSetUserInfo(index,option' 'bm1);
         } else if (!AddDeleteFileErrorDisplayed) {
            AddDeleteFileErrorDisplayed=true;
            ProjectName=_projecttbTreeGetCurProjectName(index);
            _message_box(nls("You can't copy/delete files from the associated project '%s1'",ProjectName));
         }
      } else if (_projecttbIsFolderNode(index)) {
         _str ProjectName=_projecttbTreeGetCurProjectName(index);
         int handle=_ProjectHandle(ProjectName);
         _str AutoFolders=_ProjectGet_AutoFolders(handle);
         boolean error=false;
         if (!strieq(AutoFolders,VPJ_AUTOFOLDERS_CUSTOMVIEW)) {
            error=1;
            if (!AddDeleteFolderErrorDisplayed) {
               AddDeleteFileErrorDisplayed=true;
               _message_box(nls("You can't copy/delete folders when in package or directory view."));
            }
         } else if (!_ProjectIs_AddDeleteFolderSupported(handle)) {
            error=1;
            if (!AddDeleteFolderErrorDisplayed) {
               AddDeleteFileErrorDisplayed=true;
               _message_box(nls("You can't delete folders from the associated project '%s1'",ProjectName));
            }
         }
         if (!error) {
            _TreeGetInfo(index,showchildren,bm1);
            _TreeSetUserInfo(index,option' 'bm1);
            _TreeSetInfo(index,showchildren,_pic_tfldclosdisabled,_pic_tfldopendisabled);
         }
      }
   }
}
int _OnUpdate_projecttbMoveDown(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdate_projecttbAddFolder(cmdui,target_wid,command,1));
}
_command void projecttbMoveDown() name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   projecttbMoveUp('1');
}
int _OnUpdate_projecttbMoveUp(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdate_projecttbAddFolder(cmdui,target_wid,command,-1));
}
_command void projecttbMoveUp(_str doDown='') name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   _str ProjectName=_projecttbTreeGetCurProjectName();

   int handle=_ProjectHandle(ProjectName);
   if (_ProjectIs_SupportedXMLVariation(handle)) {
      handle=_ProjectGet_AssociatedHandle(handle);
   }
   XMLVARIATIONS xmlv;
   _ProjectGet_XMLVariations(handle,xmlv);

   // Must be at folder.
   // Add folder inside this folder
   typeless array[]; array._makeempty();
   _str FolderName=_TreeGetCaption(_TreeCurIndex());
   int Node=_ProjectGet_FolderNode(handle,FolderName);
   _xmlcfg_find_simple_array(handle,xmlv.vpjtag_folder,array,_xmlcfg_get_parent(handle,Node));

   int i;
   for (i=0;i<array._length();++i) {
      if (strieq(_xmlcfg_get_attribute(handle,array[i],'Name'),FolderName)) {
         break;
      }
   }
   if (doDown!='') {
      _xmlcfg_copy(handle,array[i+1],handle,Node,0);
      _TreeMoveDown(_TreeCurIndex());
   } else {
      _xmlcfg_copy(handle,array[i-1],handle,Node,VSXMLCFG_COPY_BEFORE);
      _TreeMoveUp(_TreeCurIndex());
   }
   _xmlcfg_delete(handle,Node);

   _ProjectSave(handle);
   //_WorkspaceCache_Update();
   //toolbarUpdateWorkspaceList();
}
_command void projecttbDependencies() name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   _str ProjectName=_projecttbTreeGetCurProjectName();

   workspace_dependencies(ProjectName);
}
int _OnUpdate_projecttbAutoFolders(CMDUI &cmdui,int target_wid,_str command)
{
   _str args="";
   parse command with . args;
   if (target_wid && target_wid.p_object==OI_TREE_VIEW) {
      if (_workspace_filename=='') {
         return(MF_GRAYED);
      }
      _str ProjectName=target_wid._projecttbTreeGetCurProjectName();

      if (_IsVisualStudioWorkspaceFilename(_workspace_filename)) {
         _str makefilename=_ProjectGet_AssociatedFile(_ProjectHandle(ProjectName));
         if (GetVSStandardAppName(_get_extension(makefilename,true)):!='') {
            if(strieq(args,VPJ_AUTOFOLDERS_CUSTOMVIEW) ){
               return(MF_GRAYED);
            }
         }
      } else if(_IsJBuilderAssociatedWorkspace(_workspace_filename)) {
         // only support custom view for jbuilder
         if(!strieq(args, VPJ_AUTOFOLDERS_CUSTOMVIEW)) {
            return MF_GRAYED;
         }
      }

      _str AutoFolders=_ProjectGet_AutoFolders(_ProjectHandle(ProjectName));
      if (strieq(AutoFolders,args)) {
         return(MF_CHECKED|MF_ENABLED);
      }
   }
   return(MF_ENABLED);
}
_command void projecttbAutoFolders(_str newAutoFolders="") name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   _str ProjectName=_projecttbTreeGetCurProjectName();

   int handle=_ProjectHandle(ProjectName);

   _str AutoFolders=_ProjectGet_AutoFolders(handle);
   if (strieq(AutoFolders,VPJ_AUTOFOLDERS_CUSTOMVIEW) && !strieq(newAutoFolders,VPJ_AUTOFOLDERS_CUSTOMVIEW) ) {
      int result=_message_box("Warning:  This will reorganize all files including those you have manually placed in folders.  Switching back to Custom View will not restore your file organization.\n\nContinue?",'',MB_YESNO|MB_ICONEXCLAMATION);
      if (result!=IDYES) {
         return;
      }
   }
   _ProjectSet_AutoFolders(handle,newAutoFolders);
   _ProjectSave(handle);
   _WorkspaceCache_Update();
   toolbarUpdateWorkspaceList();
}
static int gProjectHandle;
static _str gSkipFolderName;
int projecttbCheck(_str text, _str option)
{
   if (option=='F') {
      if (text=='') {
         _message_box('Must specify a folder name');
         return(1);
      }
      if (strieq(gSkipFolderName,text)) {
         return(0);
      }
      int Node=_ProjectGet_FolderNode(gProjectHandle,text);
      if (Node>=0) {
         _message_box('A folder by this name already exists');
         return(1);
      }
      return(0);
   }
   int ExtToNodeHashTab:[];
   _ProjectGet_ExtToNode(gProjectHandle,ExtToNodeHashTab,gSkipFolderName);
   if (text=='' || text=='*.*' || text=='*') {
      return(0);
#if 0
      int Node=ExtToNodeHashTab:[''];
      if(Node!=_ProjectGet_FilesNode(gProjectHandle)) {
         FolderName=_xmlcfg_get_attribute(gProjectHandle,ExtToNodeHashTab:[''],'Name');
         _message_box(nls("The '%s' folder already has this filter",FolderName));
         return(1);
      }
      return(0);
#endif
   }
   _str value="";
   for (;;) {
      parse text with value ';' text;
      if (value=='' && text=='') {
         break;
      }
      _str ext=lowcase(_get_extension(value));
      if (substr(value,1,2)!='*.' || ext=='') {
         _message_box("Filters must start with '*.' and contain an extension");
         return(1);
      }
      if(ExtToNodeHashTab._indexin(ext)) {
         _str FolderName=_xmlcfg_get_attribute(gProjectHandle,ExtToNodeHashTab:[ext],'Name');
         _message_box(nls("The '%s' folder already has this filter",FolderName));
         return(1);
      }
   }
   return(0);

}
int _OnUpdate_projecttbAddFolder(CMDUI &cmdui,int target_wid,_str command,int CheckFolderMoveUpDown=0)
{
   if (target_wid && target_wid.p_object==OI_TREE_VIEW) {
      // do we have a workspace open here?
      if (_workspace_filename=='') {
         return(MF_GRAYED);
      }

      // check for a folder node under a workspace node
      _str wksp_ext=_get_extension(_workspace_filename,true);
      // we do not allow this for visual studio workspaces
      if (file_eq(wksp_ext,VISUAL_STUDIO_SOLUTION_EXT)) {
         int index = _TreeCurIndex();
         // we automatically allow folders to be added to workspaces or workspace folders
         if ((_projecttbIsWorkspaceNode(index) == true) ||
             (_projecttbIsWorkspaceFolderNode(index) == true)) {
            return MF_ENABLED; 
         } else {
            if (CheckFolderMoveUpDown) {
               return MF_GRAYED; 
            }
            // supported visual studio types
            _str ProjectName=target_wid._projecttbTreeGetCurProjectName();
            if (_ProjectIs_vcxproj(_ProjectHandle(ProjectName))) {
               return MF_ENABLED; 
            }
            return MF_GRAYED;
         }
      } 

      // get a handle to our project
      _str ProjectName=target_wid._projecttbTreeGetCurProjectName();
      int handle=_ProjectHandle(ProjectName);

      // do we even support adding folders to this project?
      if (!_ProjectIs_AddDeleteFolderSupported(handle)) {
         return(MF_GRAYED);
      }

      if (_ProjectIs_SupportedXMLVariation(handle)) {
         handle=_ProjectGet_AssociatedHandle(handle);
      }
      XMLVARIATIONS xmlv;
      _ProjectGet_XMLVariations(handle,xmlv);

      // if folder not found, it was added by a wildcard so disable
      // most of the operations on the menu
      _str folderName = _TreeGetCaption(_TreeCurIndex());
      if(_projecttbIsWildcardFolderNode() || 
         (target_wid._projecttbIsFolderNode() && _ProjectGet_FolderNode(handle, folderName) < 0)) {
         return MF_GRAYED;
      }

      // what is our view?
      _str AutoFolders=_ProjectGet_AutoFolders(handle);
      // we only allow this in custom view
      if (strieq(AutoFolders,VPJ_AUTOFOLDERS_CUSTOMVIEW)) {
         if (CheckFolderMoveUpDown) {
            int Node=_ProjectGet_FolderNode(handle,folderName);

            // if folder not found, it was added by a wildcard so disable
            // most of the operations on the menu
            if(Node < 0) {
               return MF_GRAYED;
            } else {
               typeless array[]; array._makeempty();
               _xmlcfg_find_simple_array(handle,xmlv.vpjtag_folder,array,_xmlcfg_get_parent(handle,Node));
               if (array._length()<2) {
                  return(MF_GRAYED);
               }
               int i;
               for (i=0;i<array._length();++i) {
                  if (strieq(_xmlcfg_get_attribute(handle,array[i],xmlv.vpjattr_folderName),folderName)) {
                     break;
                  }
               }
               // Move down
               if (CheckFolderMoveUpDown>0) {
                  if (i>=array._length()-1) {
                     return(MF_GRAYED);
                  }
               } else {
                  if (i<=0) {
                     return(MF_GRAYED);
                  }
               }
            }
         }
         return(MF_ENABLED);
      }
   }
   return(MF_GRAYED);
}

_command void projecttbAddFolder() name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   _str projectName = _projecttbTreeGetCurProjectName();
   gProjectHandle=_ProjectHandle(projectName);

   int index=_TreeCurIndex();
   // check for a folder node under a workspace node
   _str wksp_ext=_get_extension(_workspace_filename,true);
   // handle cases for Visual Studio projects
   if (file_eq(wksp_ext,VISUAL_STUDIO_SOLUTION_EXT)) {
      // only do this is it's a workspace or workspace folder node
      if ((_projecttbIsWorkspaceNode(index) == true) || 
          (_projecttbIsWorkspaceFolderNode(index) == true)) {
         InsertVSWorkspaceFolder(_workspace_filename);
         return;
      }

      // supported visual studio types
      if (_ProjectIs_vcxproj(gProjectHandle)) {
         projectName = _AbsoluteToProject(_ProjectGet_AssociatedFile(gProjectHandle), projectName);
         InsertVCXProjFolder(projectName);
         return; 
      }
      return;
   }

   // get a handle to our project
   if (_ProjectIs_SupportedXMLVariation(gProjectHandle)) {
      gProjectHandle=_ProjectGet_AssociatedHandle(gProjectHandle);
   }

   XMLVARIATIONS xmlv;
   _ProjectGet_XMLVariations(gProjectHandle,xmlv);
   gSkipFolderName='';
   typeless status=show('-modal _textbox_form',
               'Add Folder',
               0,  //TB_RETRIEVE_INIT, //Flags
               '', //width
               '', //help item
               '', // "OK,Apply to &All,Cancel:_cancel\tCopy file '"SourceFilename"' to",//Button List
               '', //retrieve name
               '-e projecttbCheck:F Folder Name:',
               '-e projecttbCheck:* Filters (ex. *.cpp;*.h):'
               );

   // did they cancel out?
   if (status=='') {
      return;
   }

   // Must be at folder.
   // Add folder inside this folder
   int Node;
   if (_projecttbIsProjectNode()) {
      Node=_xmlcfg_set_path2(gProjectHandle,xmlv.vpjx_files,xmlv.vpjtag_folder,xmlv.vpjattr_folderName,_param1);
   } else {
      // Must be at folder.
      // Add folder inside this folder
      _str FolderName=_TreeGetCaption(_TreeCurIndex());
      Node=_ProjectGet_FolderNode(gProjectHandle,FolderName);
      typeless array[]; array._makeempty();
      _xmlcfg_find_simple_array(gProjectHandle,VPJTAG_FOLDER,array,Node);
      if (!array._length()) {
         int FirstChild=_xmlcfg_get_first_child(gProjectHandle,Node);
         if (FirstChild>=0) {
            Node=_xmlcfg_add(gProjectHandle,FirstChild,xmlv.vpjtag_folder,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_BEFORE);
         } else {
            Node=_xmlcfg_add(gProjectHandle,Node,xmlv.vpjtag_folder,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
         }
      } else {
         Node=_xmlcfg_add(gProjectHandle,array[array._length()-1],xmlv.vpjtag_folder,VSXMLCFG_NODE_ELEMENT_START_END,0);
      }
      _xmlcfg_set_attribute(gProjectHandle,Node,xmlv.vpjattr_folderName,_param1);
   }
   _ProjectSet_FolderFiltersAttr(gProjectHandle,Node,_param2);

   _ProjectSave(gProjectHandle);
   /*
     Since we can loose changes, we are better off making the user choose the "Refilter" menu item.

   result=_message_box("Do you want to refilter the files?",'',MB_YESNOCANCEL,IDNO);
   if (result==IDYES) {
      projecttbRefilter();
      return;
   }
   */
   _WorkspaceCache_Update();
   toolbarUpdateWorkspaceList();
}
int _OnUpdate_projecttbAddNewFile(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdate_projecttbAddFiles(cmdui,target_wid,command,true));
}
_command void projecttbAddNewFile() name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   // set the current project to the selected project
   _str ProjectName=_projecttbTreeGetCurProjectName();
   _str old_project_name=_project_name;
   workspace_set_active(ProjectName,false,false,false);

   // see if we selected a folder in directory structure
   curPath := getcwd();
   newPath := _projecttbTreeGetCurFolderPath();
   if (newPath != '') {
      pwd(newPath);
   }

   // show the new file dialog
   typeless result=show('-modal -mdi _workspace_new_form','f2');

   // go back to our old directory
   if (newPath != '') {
      pwd(curPath);
   }

   // set our old project back again
   workspace_set_active(old_project_name,false,false,false);

   // nothing to do here
   if (result=='') {
      return;
   }

   // add the files then
   _projecttbAddFiles2(_param1);
}
int _OnUpdate_projecttbAddFiles(CMDUI &cmdui,int target_wid,_str command,boolean doNewFile=false)
{
   // make sure we have a tree, please
   if (target_wid && target_wid.p_object==OI_TREE_VIEW) {

      // is add/delete disabled in this workspace?
      if (_workspace_filename=='' ||
          (_IsWorkspaceAssociated(_workspace_filename) && !_IsAddDeleteSupportedWorkspaceFilename(_workspace_filename))) {
         return(MF_GRAYED);
      }

      // is this a workspace item node?
      if (target_wid._projecttbIsWorkspaceItemNode()) {
         return(MF_ENABLED);
      }

      if (command:=='projecttbAddTree' && target_wid._projecttbIsProjectNode(target_wid._TreeCurIndex(),false)) {
         return(MF_GRAYED);
      }

      // get a handle to this project
      _str ProjectName=target_wid._projecttbTreeGetCurProjectName();
      int handle = _ProjectHandle(ProjectName);
      if (_ProjectIs_SupportedXMLVariation(handle)) {
         handle=_ProjectGet_AssociatedHandle(handle);

      } else if (_ProjectIs_vcxproj(handle)) {
         if (command:=='projecttbAddTree') {
            return(MF_GRAYED);
         }
         return(MF_ENABLED);
      }

      // if folder not found, it was added by a wildcard so disable
      // most of the operations on the menu
      _str folderName = target_wid._TreeGetCaption(target_wid._TreeCurIndex());
      if(_projecttbIsWildcardFolderNode() || (target_wid._projecttbIsFolderNode() && _ProjectGet_FolderNode(handle, folderName) < 0)) {
         return MF_GRAYED;
      }

      // what is our view?
      _str AutoFolders=_ProjectGet_AutoFolders(handle);
      if (strieq(AutoFolders,VPJ_AUTOFOLDERS_CUSTOMVIEW) || 
          (strieq(AutoFolders,VPJ_AUTOFOLDERS_DIRECTORYVIEW))) {
         return(MF_ENABLED);
      }

      // enable for java package view
      if (strieq(AutoFolders, VPJ_AUTOFOLDERS_PACKAGEVIEW)/* && doNewFilecommand :== 'projecttbAddNewFile'*/){
          if (strieq(_ProjectGet_Type(handle,GetCurrentConfigName(ProjectName)),'java')) {
             return(MF_ENABLED);
          }
      }
   }
   return(MF_GRAYED);
}

static void _projecttbAddFiles2(_str newfilename=null,_str ProjectName='',_str FolderName=null)
{
   if (ProjectName=='') {
      ProjectName=_projecttbTreeGetCurProjectName();
   }
   int handle=_ProjectHandle(ProjectName);
   _str AssocProjectName=_ProjectGet_AssociatedFile(handle);
   _str AutoFolders=_ProjectGet_AutoFolders(handle);
   if (_ProjectIs_SupportedXMLVariation(handle)) {
      handle = _ProjectGet_AssociatedHandle(handle);

   } else if (_ProjectIs_vcxproj(handle)) {
      if (newfilename==null) {
         // init the callback so it clears its cache
         projectPropertiesAddFilesCallback("");

         // see if we selected a folder in directory structure
         newPath := _projecttbTreeGetCurFolderPath();

         typeless result=_OpenDialog("-modal",
                            'Add Source Files',// title
                            _last_wildcards,// Initial wildcards
                            def_file_types','EXTRA_FILE_FILTERS,
                            OFN_NOCHANGEDIR|OFN_FILEMUSTEXIST|OFN_SET_LAST_WILDCARDS,
                            "", // Default extension
                            ""/*wildcards*/, // Initial filename
                            newPath,// Initial directory
                            "",
                            "",
                            projectPropertiesAddFilesCallback); // include item callback

         // cleanup after the callback so it clears its cache
         projectPropertiesAddFilesCallback("");
         if (result=='') return;
         newfilename = result;
      }

      InsertVCXProjFile(_AbsoluteToProject(AssocProjectName, ProjectName), newfilename);
      _WorkspaceCache_Update();
      toolbarUpdateWorkspaceList();
      _maybeGenerateMakefile(ProjectName);
      call_list("_prjupdate_");
      return;

   } else if(_IsWorkspaceAssociated(_workspace_filename)) {
      // Must adding a single newfile
      _str old_project_name=_project_name;
      workspace_set_active(ProjectName,false,false,false);
      project_add_file(newfilename);
      workspace_set_active(old_project_name,false,false,false);
      return;
   }

   XMLVARIATIONS xmlv;
   _ProjectGet_XMLVariations(handle,xmlv);

   int orig_view_id=p_window_id;

   int FolderNode;
   if (FolderName!=null) {
      if (FolderName=='') {
         FolderNode=_ProjectGet_FilesNode(handle);
      } else {
         FolderNode=_ProjectGet_FolderNode(handle,FolderName);
         if (FolderNode<0) {
            _message_box(nls("Folder '%s' not found in project",FolderName));
            return;
         }
      }
   } else {
      if (_projecttbIsProjectNode(_TreeCurIndex())) {
         FolderNode=_ProjectGet_FilesNode(handle);
      } else {
         FolderName=_TreeGetCaption(_TreeCurIndex());
         FolderNode=_ProjectGet_FolderNode(handle,FolderName);
      }
   }

   int filelist_view_id=0;
   if (newfilename==null) {
      // init the callback so it clears its cache
      projectPropertiesAddFilesCallback("");

      // see if we selected a folder in directory structure
      newPath := _projecttbTreeGetCurFolderPath();

      typeless result=_OpenDialog("-modal",
                         'Add Source Files',// title
                         _last_wildcards,// Initial wildcards
                         def_file_types','EXTRA_FILE_FILTERS,
                         OFN_NOCHANGEDIR|OFN_FILEMUSTEXIST|OFN_ALLOWMULTISELECT|OFN_SET_LAST_WILDCARDS,
                         "", // Default extension
                         ""/*wildcards*/, // Initial filename
                         newPath,// Initial directory
                         "",
                         "",
                         projectPropertiesAddFilesCallback); // include item callback

      // cleanup after the callback so it clears its cache
      projectPropertiesAddFilesCallback("");

      //chdir(olddir,1);
      if (result=='') return;
      _create_temp_view(filelist_view_id);
      p_window_id=filelist_view_id;
      _str file_spec_list = result;
      while (file_spec_list != '') {
         _str file_spec = parse_file(file_spec_list);
         insert_file_list(file_spec' -v +p -d');
      }
   } else {
      _create_temp_view(filelist_view_id);
      p_window_id=filelist_view_id;
      insert_line(newfilename);
   }

   int DollarTable:[];
   _str ConfigurationNames[];
   _ProjectGet_ObjectFileInfo(handle,DollarTable,ConfigurationNames);

   int FileToNode:[];
   _ProjectGet_FileToNodeHashTab(handle,FileToNode);
   int Node=FolderNode;
   int flags=VSXMLCFG_ADD_AS_CHILD;

   _str filename="";
   _str NewFilesList[];
   p_line=0;
   _str path=_strip_filename(ProjectName,'N');
   boolean useVCPPFiles = false;
   _str ext = _get_extension(AssocProjectName, true);
   if (file_eq(ext, VISUAL_STUDIO_VCPP_PROJECT_EXT) || 
       file_eq(ext, VISUAL_STUDIO_INTEL_CPP_PROJECT_EXT)) {
      useVCPPFiles = true;
   }

   for (;;) {
      if (down()) {
         break;
      }
      get_line(filename);
      filename=strip(filename);
      if (_DataSetIsFile(filename)) {
         filename=upcase(filename);
      }
      _str RelFilename=relative(filename,path);
      if (useVCPPFiles) {
         RelFilename = ConvertToVCPPRelFilename(RelFilename, _strip_filename(useVCPPFiles,'N'));
      }
      int *pnode=FileToNode._indexin(_file_case(RelFilename));
      if (!pnode) {
         Node=_xmlcfg_add(handle,Node,xmlv.vpjtag_f,(useVCPPFiles) ? VSXMLCFG_NODE_ELEMENT_START : VSXMLCFG_NODE_ELEMENT_START_END,flags);
         flags=0;
         _xmlcfg_set_attribute(handle,Node,xmlv.vpjattr_n,_NormalizeFile(RelFilename,xmlv.doNormalizeFile));

         // if this is an ant build file, set the Type attribute
         if(_IsAntBuildFile(_AbsoluteToProject(RelFilename))) {
            _xmlcfg_set_attribute(handle, Node, "Type", "Ant");
            // if this is an ant build file, set the Type attribute
         } else if(_IsNAntBuildFile(_AbsoluteToProject(RelFilename))) {
            _xmlcfg_set_attribute(handle, Node, "Type", "NAnt");
         // if this is a makefile, set the Type attribute
         }else if(_IsMakefile(_AbsoluteToProject(RelFilename))) {
            _xmlcfg_set_attribute(handle, Node, "Type", "Makefile");
         }

         _ProjectSet_ObjectFileInfo(handle,DollarTable,ConfigurationNames,Node,RelFilename);
         NewFilesList[NewFilesList._length()]=filename;
      }
   }
   _xmlcfg_sort_on_attribute(handle,FolderNode,xmlv.vpjattr_n,'2P',xmlv.vpjtag_folder,xmlv.vpjattr_folderName,'2P');

   if (strieq(AutoFolders,VPJ_AUTOFOLDERS_PACKAGEVIEW) ||
       strieq(AutoFolders,VPJ_AUTOFOLDERS_DIRECTORYVIEW)
       ) {
      _ProjectAutoFolders(handle);
   }

   _ProjectSave(handle);
   _str TagFilename=_GetWorkspaceTagsFilename();
   useThread := _is_background_tagging_enabled(AUTOTAG_WORKSPACE_NO_THREADS);
   tag_add_viewlist(TagFilename,filelist_view_id,ProjectName,false,newfilename==null,useThread);
   //_delete_temp_view(filelist_view_id);
   activate_window(orig_view_id);

   _AddAndRemoveFilesFromVC(NewFilesList,null,ProjectName);
   _WorkspaceCache_Update();
   toolbarUpdateWorkspaceList();

   // regenerate the makefile
   _maybeGenerateMakefile(ProjectName);

   call_list("_prjupdate_");
}
_command void projecttbAddFiles() name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   if (_projecttbIsWorkspaceItemNode()) {
      _str result=_OpenDialog("-modal",
                              'Add Source Files',// title
                              _last_wildcards,// Initial wildcards
                              '',
                              OFN_NOCHANGEDIR|OFN_FILEMUSTEXIST|OFN_ALLOWMULTISELECT);

      if (result:!='') {
         _str workspace_ext=_get_extension(_workspace_filename,true);

         if (file_eq(workspace_ext,VISUAL_STUDIO_SOLUTION_EXT)) {
            AddSolutionItems(result);
         }
      }
      return;
   }
   _projecttbAddFiles2();
}
int _OnUpdate_projecttbAddTree(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdate_projecttbAddFiles(cmdui,target_wid,command));
}

int _OnUpdate_projecttbAddTreeOrWildcard(CMDUI &cmdui,int target_wid,_str command)
{
   return (add_tree_allowed(target_wid)|| add_wildcard_allowed()) ? MF_ENABLED : MF_GRAYED;
}

static boolean add_tree_allowed(int targetWid)
{
   return(_OnUpdate_projecttbAddFiles(null, targetWid, 'projecttbAddTree') == MF_ENABLED);
}

static boolean add_wildcard_allowed()
{
   // well, we have to have a workspace, and it needs to be one of ours
   if (_workspace_filename=='' || _IsWorkspaceAssociated(_workspace_filename)) {
      return false;
   }

   // can't add wildcards to projects...
   if (_projecttbIsProjectNode(_TreeCurIndex(),false)) {
      return false;
   }

   _str ProjectName=_projecttbTreeGetCurProjectName();
   int handle = _ProjectHandle(ProjectName);
   if (_ProjectIs_SupportedXMLVariation(handle)) {
      handle=_ProjectGet_AssociatedHandle(handle);
   }

   // if folder not found, it was added by a wildcard so disable
   // most of the operations on the menu
   _str folderName = _TreeGetCaption(_TreeCurIndex());
   if(_projecttbIsWildcardFolderNode() || _ProjectGet_FolderNode(handle, folderName) < 0) {
      return false;
   }

   // we only allow this in custom view
   _str AutoFolders=_ProjectGet_AutoFolders(handle);
   if (strieq(AutoFolders,VPJ_AUTOFOLDERS_CUSTOMVIEW)) {
      return true;
   }

   // just forget it
   return false;
}

_command void projecttbAddTreeOrWildcard() name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   showWildcard := add_wildcard_allowed();

   // we allow them to add tree on a workspace node
   if (_projecttbIsWorkspaceItemNode()) {

      typeless result=show('-modal -xy _project_add_tree_or_wildcard_form',
                  'Add Tree',
                  ALLFILES_RE,
                  false,
                  true,
                  '',
                  showWildcard);

      if (result== "") {
         return;
      }
// _param1 - trees to add (array of paths)
// _param2 - recursive?
// _param3 - follow symlinks?
// _param4 - exclude filespecs (array of filespecs)
// _param5 - add as wildcard
      _str workspace_ext=_get_extension(_workspace_filename,true);
      if (file_eq(workspace_ext,VISUAL_STUDIO_SOLUTION_EXT)) {
         _str optimize_option=(_param3)?'':' +o';
         _str recursive_option=(_param2)?'+t':'-t';
         AddTreeSolutionItems(_param1, recursive_option:+optimize_option,_param4);
      }

      _param1._makeempty();
      _param4._makeempty();
      return;
   }

   // otherwise, we have a project node

   int orig_view_id=p_window_id;
   _str ProjectName=_projecttbTreeGetCurProjectName();

   int handle=_ProjectHandle(ProjectName);
   if (_ProjectIs_SupportedXMLVariation(handle)) {
      handle=_ProjectGet_AssociatedHandle(handle);
   }

   // figure out what our default wildcards will be
   _str extension="";
   _str wildcards='';
   boolean attempt_retrieval=true;
   int status=tag_read_db(_GetWorkspaceTagsFilename());
   if (status >= 0) {
      status=tag_find_language(auto lang);
      if (!status) {
         wildcards=_GetWildcardsForLanguage(lang);
         _GetWildcardsForTagFile(false,wildcards);
         attempt_retrieval=false;
         //say('extension='extension);
         //say('wildcards='wildcards);
      }
      tag_reset_find_language();
      tag_close_db(null,true);
   }
   if (wildcards=='') {
      if (strieq(_ProjectGet_Type(handle,GetCurrentConfigName(ProjectName)),'java')) {
         wildcards=_GetWildcardsForLanguage('java');
         _GetWildcardsForTagFile(false,wildcards);
         attempt_retrieval=false;
         //say('wildcards='wildcards);
      }
   }
   if (wildcards=='') {
      wildcards=_default_c_wildcards();
   }

   // see if we selected a folder in directory structure
   curPath := getcwd();
   newPath := _projecttbTreeGetCurFolderPath();
   if (newPath != '') {
      pwd(newPath);
   }

   int fid;
   fid= p_active_form;
   typeless result=show('-modal -xy _project_add_tree_or_wildcard_form',
               'Add Tree',
               wildcards,
               false,
               true,
               '',
               showWildcard);
   if (result== "") {
      return;
   }

   // go back to our old directory
   if (newPath != '') {
      pwd(curPath);
   }
// _param1 - trees to add (array of paths)
// _param2 - recursive?
// _param3 - follow symlinks?
// _param4 - exclude filespecs (array of filespecs)
// _param5 - add as wildcard

   if (_param5) {
      projecttbAddWildcardsToProject(ProjectName, handle, _param1, _param4, _param2, _param3);
   } else {
      projecttbAddTreeToProject(ProjectName, handle, _param1, _param4, _param2, _param3);
   }

   _param1._makeempty();
   _param4._makeempty();

   _WorkspaceCache_Update();
   toolbarUpdateWorkspaceList();

   // regenerate the makefile
   _maybeGenerateMakefile(ProjectName);

   mou_hour_glass(0);
   clear_message();
}

static void projecttbAddWildcardsToProject(_str ProjectName, int handle, _str (&filesList)[], _str (&excludesList)[], boolean recursive, boolean followSymlinks)
{
   // put the excludes in string form
   excludes := '';
   for (i := 0; i < excludesList._length(); ++i) {
      excludes :+= excludesList[i]';';
   }
   excludes = strip(excludes, 't', ';');

   _str FolderName=_TreeGetCaption(_TreeCurIndex());
   int FolderNode=_ProjectGet_FolderNode(handle,FolderName);

   int OrigProjectFileList;
   GetProjectFiles(ProjectName, OrigProjectFileList,'',null,'',true,true,false,handle);

   // go through each node in our file to add it
   _str NewFilesList[];
   for (i = 0; i < filesList._length(); i++) {
      _str RelFilename=_RelativeToProject(filesList[i], ProjectName);

      // maybe it's already in there?
      int Node=_ProjectGet_FileNode(handle,RelFilename);
      if (Node<0) {

         // do the actual adding now
         Node=_xmlcfg_add(handle, FolderNode, VPJTAG_F, VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
         _xmlcfg_set_attribute(handle,Node,'N',_NormalizeFile(RelFilename));
         _xmlcfg_set_attribute(handle,Node,'Recurse', recursive);
         _xmlcfg_set_attribute(handle,Node,'Excludes', _NormalizeFile(excludes));

         NewFilesList[NewFilesList._length()]=_AbsoluteToProject(filesList[i],ProjectName);
      }
   }

   //Now sort the buffer...
   _xmlcfg_sort_on_attribute(handle,FolderNode,'N','2P',VPJTAG_FOLDER,'Name','2P');
   _ProjectSave(handle);

   activate_window(OrigProjectFileList);
   sort_buffer('-fc');
   _remove_duplicates(_fpos_case);

   //_showbuf(new_all_files_view_id);
   int new_all_files_view_id=0;
   GetProjectFiles(ProjectName, new_all_files_view_id,'',null,'',true,true,false,handle);
   activate_window(new_all_files_view_id);
   sort_buffer('-fc');
   _remove_duplicates(_fpos_case);

   _str DeletedFilesList[];
   useThread := _is_background_tagging_enabled(AUTOTAG_WORKSPACE_NO_THREADS);
   if (useThread) {

      _ActivateAlert(ALERT_GRP_BACKGROUND_ALERTS, ALERT_TAGGING_WORKSPACE, 'Updating workspace tag file', '', 1);
      call_list("_LoadBackgroundTaggingSettings");
      rebuildFlags := VS_TAG_REBUILD_CHECK_DATES;
      rebuildFlags |= VS_TAG_REBUILD_DO_REFS;
      _DiffFileListsFromViews(new_all_files_view_id, OrigProjectFileList, NewFilesList, DeletedFilesList);
      _ConvertViewToAbsolute(new_all_files_view_id, _strip_filename(ProjectName, 'n'));
      tag_build_tag_file_from_view(project_tags_filename(),
                                   rebuildFlags,
                                   new_all_files_view_id);
      if (def_tagging_logging) {
         loggingMessage := nls("Starting background tag file update for '%s1' because a wildcard was added", project_tags_filename());
         dsay("BACKGROUND TAGGING(":+_time('M'):+"): ":+loggingMessage, TAGGING_LOG);
      }

   } else {
      _TagUpdateFromViews(project_tags_filename(),new_all_files_view_id,
                          OrigProjectFileList,false,ProjectName,
                          NewFilesList,DeletedFilesList,0,useThread);
   }

   _delete_temp_view(new_all_files_view_id);
   _delete_temp_view(OrigProjectFileList);
   _AddAndRemoveFilesFromVC(NewFilesList,DeletedFilesList);

}

static void projecttbAddTreeToProject(_str ProjectName, int handle, _str (&filesList)[], _str (&excludesList)[], boolean recursive, boolean followSymlinks)
{
   _str FolderName=_TreeGetCaption(_TreeCurIndex());
   int FolderNode=_ProjectGet_FolderNode(handle,FolderName);

   XMLVARIATIONS xmlv;
   _ProjectGet_XMLVariations(handle, xmlv);

   // Find all files in tree:
   mou_hour_glass(1);
   message('SlickEdit is finding all files in tree');

   recursiveString := recursive ? '+t' : '-t';
   optimizeString := followSymlinks ? '' : '+o';

   formwid := p_active_form;
   filelist_view_id := 0;
   orig_view_id := _create_temp_view(filelist_view_id);
   p_window_id = filelist_view_id;

   // put all the files into one string
   all_files := '';
   for (i := 0; i < _param1._length(); ++i) {
      file := maybe_quote_filename(strip(absolute(filesList[i]),'B','"'));
      all_files = all_files' 'file;
   }

   // now add the excludes on
   if (excludesList._length() > 0) {
      all_files = all_files' -exclude';
      for (i = 0; i < excludesList._length(); ++i) {
         file := maybe_quote_filename(strip(excludesList[i], 'B', '"'));
         all_files = all_files' 'file;
      }
   }

   // +W option supports multiple file specs but must specify switches
   // before files when you use this option.
   insert_file_list(recursiveString' 'optimizeString' +W +L -v +p -d 'all_files);
   p_line=0;
   _str NewFilesList[];

   int DollarTable:[];
   _str ConfigurationNames[];
   _ProjectGet_ObjectFileInfo(handle,DollarTable,ConfigurationNames);

   int FileToNode:[];
   _ProjectGet_FileToNodeHashTab(handle,FileToNode);
   int Node=FolderNode;
   int flags=VSXMLCFG_ADD_AS_CHILD;

   _str filename="";
   _str path=_strip_filename(ProjectName,'N');
   // Insert tree file list into project source file list:
   top();up();
   while (!down()) {
      get_line(filename);
      filename=strip(filename);
      if (filename=='') break;
      if (_DataSetIsFile(filename)) {
         filename=upcase(filename);
      }
      //4:15pm 7/11/2000
      //Changing for multiple configs...
      //fid._srcfile_list._lbadd_item(filename);
      //_srcfile_list._lbadd_item(relative(filename,strip_filename(gProjectName,'N')));
      _str RelFilename=relative(filename,path);
      int *pnode=FileToNode._indexin(_file_case(RelFilename));
      if (!pnode) {
         Node=_xmlcfg_add(handle,Node,xmlv.vpjtag_f,VSXMLCFG_NODE_ELEMENT_START_END,flags);
         flags=0;
         _xmlcfg_set_attribute(handle,Node,xmlv.vpjattr_n,_NormalizeFile(RelFilename,xmlv.doNormalizeFile));
         _ProjectSet_ObjectFileInfo(handle,DollarTable,ConfigurationNames,Node,RelFilename);
         NewFilesList[NewFilesList._length()]=filename;
      }
   }

   //Now sort the buffer...
   _xmlcfg_sort_on_attribute(handle,FolderNode,xmlv.vpjattr_n,'2P',xmlv.vpjtag_folder,xmlv.vpjattr_folderName,'2P');
   _ProjectSave(handle);
   _str TagFilename=_GetWorkspaceTagsFilename();
   //_showbuf(filelist_view_id);
   useThread := _is_background_tagging_enabled(AUTOTAG_WORKSPACE_NO_THREADS);
   tag_add_viewlist(TagFilename,filelist_view_id,ProjectName,false,true,useThread);
   //_delete_temp_view(filelist_view_id);
   activate_window(orig_view_id);

   _AddAndRemoveFilesFromVC(NewFilesList,null,ProjectName);
}

_command void projecttbOpenFiles() name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   _str ProjectName=_projecttbTreeGetCurProjectName();
   project_load(maybe_quote_filename(ProjectName));
}
int _OnUpdate_projecttbOpenFiles(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdate_projecttbAddFolder(cmdui,target_wid,command));
}

int _OnUpdate_projecttbFolderProperties(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdate_projecttbAddFolder(cmdui,target_wid,command));
}
_command void projecttbFolderProperties() name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   gProjectHandle=_ProjectHandle(_projecttbTreeGetCurProjectName());
   if (_ProjectIs_SupportedXMLVariation(gProjectHandle)) {
      gProjectHandle=_ProjectGet_AssociatedHandle(gProjectHandle);
   }
   _str FolderName=_TreeGetCaption(_TreeCurIndex());
   int Node=_ProjectGet_FolderNode(gProjectHandle,FolderName);
   gSkipFolderName=FolderName;

   typeless status=show('-modal _textbox_form',
               'Folder Properties',
               0,  //TB_RETRIEVE_INIT, //Flags
               5000, //width
               '', //help item
               '', // "OK,Apply to &All,Cancel:_cancel\tCopy file '"SourceFilename"' to",//Button List
               '', //retrieve name
               '-e projecttbCheck:F Folder Name:'FolderName,
               '-e projecttbCheck:* Filters (ex. *.cpp;*.h):'_ProjectGet_FolderFiltersAttr(gProjectHandle,Node)
              );
   if (status=='') {
      return;
   }
   _xmlcfg_set_attribute(gProjectHandle,Node,'Name',_param1);
   _ProjectSet_FolderFiltersAttr(gProjectHandle,Node,_param2);
   _ProjectSave(gProjectHandle);
   /*
     Since we can loose changes, we are better off making the user choose the "Refilter" menu item.

   result=_message_box("Do you want to refilter the files?",'',MB_YESNOCANCEL,IDNO);
   if (result==IDYES) {
      projecttbRefilter();
      return;
   }
   */
   _WorkspaceCache_Update();
   toolbarUpdateWorkspaceList();
}

//2:44pm 7/20/2000 Tested after move from project.e
_command void projecttbCompile() name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   int treeWid, currIndex;
   _str name, fullPath;
   if (getCurrentTreeFile(treeWid, currIndex, name, fullPath)) {
      return;
   }
   _str cur_project_name=treeWid._projecttbTreeGetCurProjectName();

   _str old_project_name=_project_name;
   //_project_name=cur_project_name;
   workspace_set_active(cur_project_name);
   project_compile(fullPath);
   //_project_name=old_project_name;
   workspace_set_active(old_project_name);
}
_command void projecttbBuildCommand(_str cmdline='') name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   _str cmd="", args="";
   parse cmdline with cmd args;
   cmd=stranslate(cmd,'-','_');
   if (cmd=='project-compile') {
      projecttbCompile();
      return;
   }
   _str ProjectName=_projecttbTreeGetCurProjectName();
   _str fullPath;
   if (_projecttbIsProjectFileNode()) {
      int treeWid, currIndex;
      _str name;
      if (getCurrentTreeFile(treeWid, currIndex, name, fullPath)) {
         return;
      }
   }

   _str old_project_name=_project_name;
   workspace_set_active(ProjectName,false,false,false);
   //_project_name=VSEProjectFilename(fullPath);

   _str cwd=getcwd();
   if (cmd=='project-usertool') {
      project_usertool(args,false,true,0,fullPath);
   }else if (cmd=='project-build') {
      project_build("build",false,true,0,fullPath);
   } else if( cmd == 'project-execute' ) {
      project_execute("execute",false,true,0,fullPath);
   } else {
      execute(cmdline);
   }
   _str path=getcwd();
   if (last_char(cwd)!=FILESEP) cwd=cwd:+FILESEP;
   if (last_char(path)!=FILESEP) path=path:+FILESEP;
   if (!file_eq(path,cwd)) {
      // WARNING: sending a cd command to the process buffer here
      // might screw up an error message because this is asynchronous
      //cd(cwd);
   }
   //_project_name=old_project_name;
   workspace_set_active(old_project_name,false,false,false);
}


_command projecttbGenerateMakefile() name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   int treeWid, currIndex;
   _str name, fullPath;
   if (getCurrentTreeFile(treeWid, currIndex, name, fullPath)) {
      return(0);
   }


   _str old_project_name=_project_name;
   workspace_set_active(VSEProjectFilename(fullPath),false,false,false);
   //_project_name=VSEProjectFilename(fullPath);

   _str cwd=getcwd();
   generate_makefile(_project_name, "", true, true);
   _str path=getcwd();
   if (last_char(cwd)!=FILESEP) cwd=cwd:+FILESEP;
   if (last_char(path)!=FILESEP) path=path:+FILESEP;
   if (!file_eq(path,cwd)) {
      // WARNING: sending a cd command to the process buffer here
      // might screw up an error message because this is asynchronous
      //cd(cwd);
   }
   //_project_name=old_project_name;
   workspace_set_active(VSEProjectFilename(old_project_name),false,false,false);
}

int _OnUpdate_projecttbAddToProject(CMDUI &cmdui,int target_wid,_str command)
{
   if (target_wid && target_wid.p_object==OI_TREE_VIEW) {
      if (_workspace_filename=='' ||
          (_IsWorkspaceAssociated(_workspace_filename) && !_IsAddDeleteSupportedWorkspaceFilename(_workspace_filename))) {
         return(MF_GRAYED);
      }
      return(MF_ENABLED);
   }
   return(MF_GRAYED);
}
//3:10pm 7/20/2000 Tested after move from project.e
_command void projecttbAddToProject() name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   if (_project_name=="") {
      return;
   }
   _macro_delete_line();
   project_edit(PROJECTPROPERTIES_TABINDEX_FILES);
}

int _OnUpdate_projecttbRemove(CMDUI &cmdui,int target_wid,_str command)
{
   if (target_wid && target_wid.p_object==OI_TREE_VIEW) {
      if (_workspace_filename=='') {
         return(MF_GRAYED);
      }
      if (target_wid._projecttbIsWorkspaceItemNode()) {
         return(MF_ENABLED);
      }

      _str ProjectName=target_wid._projecttbTreeGetCurProjectName();
      int handle=_ProjectHandle(ProjectName);
      if (_ProjectIs_SupportedXMLVariation(handle)) {
         handle=_ProjectGet_AssociatedHandle(handle);
      }

      if (target_wid._projecttbIsFolderNode()) {
         if (_ProjectIs_vcxproj(handle)) {
            return(MF_ENABLED);
         } else if (!_ProjectIs_AddDeleteFolderSupported(handle)) {
            return(MF_GRAYED);
         }

         // if folder not found, it was added by a wildcard so disable
         // most of the operations on the menu
         //
         // NOTE: the folder containing the wildcard is allowed to be
         //       deleted, just not anything added by the wildcard itself
         _str folderName = _TreeGetCaption(_TreeCurIndex());
         if(_ProjectGet_FolderNode(handle, folderName) < 0) {
            return MF_GRAYED;
         }

         _str AutoFolders=_ProjectGet_AutoFolders(handle);
         if (strieq(AutoFolders,VPJ_AUTOFOLDERS_CUSTOMVIEW)) {
            return(MF_ENABLED);
         }
         return(MF_GRAYED);
      }
      if (target_wid._projecttbIsProjectFileNode()) {
         if (_IsWorkspaceAssociated(_workspace_filename) && !_IsAddDeleteSupportedWorkspaceFilename(_workspace_filename)) {
            return(MF_GRAYED);
         }
         if (_ProjectIs_vcxproj(handle)) {
            return(MF_ENABLED);
         }

         // if file not found, it was added by a wildcard so disable
         // most of the operations on the menu
         _str caption = _TreeGetCaption(_TreeCurIndex());
         _str name, fullpath;
         parse caption with name "\t" fullpath;

         relFilename := _RelativeToProject(fullpath, ProjectName);
         if (_IsVisualStudioWorkspaceFilename(_workspace_filename)) {
            _str assocFileName = _xmlcfg_get_filename(handle);
            if (file_eq(_get_extension(assocFileName,true), VISUAL_STUDIO_VCPP_PROJECT_EXT)) {
               relFilename = ConvertToVCPPRelFilename(relFilename, _strip_filename(assocFileName,'N'));
            }
         }
         if(_ProjectGet_FileNode(handle, relFilename) < 0) {
            return MF_GRAYED;
         }
      }
      if (target_wid._projecttbIsWorkspaceItemNode()) {
         _str workspace_ext=_get_extension(_workspace_filename,true);
         if (file_eq(workspace_ext,VISUAL_STUDIO_SOLUTION_EXT)) {
            if (target_wid._projecttbIsWorkspaceFileNode()) {
               return(MF_ENABLED);
            }
         }
         return(MF_GRAYED);
      }
      return(MF_ENABLED);
   }
   return(MF_GRAYED);
}
static boolean _ParentNodeSelected(int index)
{
   int showchildren=0, bm1=0, bm2NOLONGERUSED=0, moreflags=0;
   while (index!=TREE_ROOT_INDEX) {
      index=_TreeGetParentIndex(index);
      if (_TreeIsSelected(index)) {
         return(true);
      }
   }
   return(false);
}
_command void projecttbRemove() name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   if (_workspace_filename=='') {
      return;
   }
   /*
      Only cut selected files and folders items if AutoFolders is Custom View
   */

   boolean AddDeleteFileErrorDisplayed=false;
   boolean AddDeleteFolderErrorDisplayed=false;
   boolean AddDeleteProjectErrorDisplayed=false;
   boolean LastPromptRemove=false;
   boolean LastPromptVC=false;
   boolean DeleteFromDisk=false;

   int showchildren=0, bm1=0, bm2NOLONGERUSED=0, moreflags=0;
   int count=0;
   int info;
   int index=_TreeGetNextSelectedIndex(1,info);
   if (index<0) {
      index = _TreeCurIndex();
      _TreeSelectLine(index);
   }
   int HitProject:[];
   _str TagFilename=project_tags_filename();
   int open_status=tag_open_db(TagFilename);
   if (open_status < 0) {
      //_message_box(nls("Unable to open tag file %s",TagFilename));
   }

   typeless result=0;
   _str fullPath="";
   _str depname="";
   _str pname="";
   for (ff:=1;;ff=0) {
      index=_TreeGetNextSelectedIndex(ff,info);
      if (index<0){
         break;
      }
      if (_projecttbIsProjectFileNode(index) && !_ParentNodeSelected(index)) {
         if (_projecttbIsWorkspaceItemNode(index)) {
            _str workspace_ext=_get_extension(_workspace_filename,true);
            if (file_eq(workspace_ext,VISUAL_STUDIO_SOLUTION_EXT)) {
               RemoveSolutionItem(index);
            }
         } else {
            _str ProjectName=_projecttbTreeGetCurProjectName(index);
            int handle=_ProjectHandle(ProjectName);
            if (_ProjectIs_vcxproj(handle)) {
               parse _TreeGetCaption(index) with "\t"fullPath;
               DeleteVCXProjFile(_AbsoluteToProject(_ProjectGet_AssociatedFile(handle), ProjectName), fullPath);
            } else if (_CanWriteFileSection(ProjectName)) {
               parse _TreeGetCaption(index) with "\t"fullPath;
               //RelFilename=_RelativeToProject(fullPath,ProjectName);
               HitProject:[handle]=1;
               DeleteFromDisk=( LastPromptRemove && DeleteFromDisk );
               RemoveFromProjectAndVC(fullPath,LastPromptRemove,LastPromptVC,DeleteFromDisk,true,ProjectName,true);
            } else if(!AddDeleteFileErrorDisplayed){
               AddDeleteFileErrorDisplayed=true;
               ProjectName=_projecttbTreeGetCurProjectName(index);
               _message_box(nls("You can't copy/delete files from the associated project '%s1'",ProjectName));
            }
         }
         call_list("_prjupdate_");
      } else if (_projecttbIsFolderNode(index) && !_ParentNodeSelected(index)) {
         // Check for a special folder property containing a GUID
         // These are VS2005 solution item folders, and need to be deleted differently
         boolean isVS2005SolutionFolder = false;
         _str folderGuid = '';
         typeless retVal = _TreeGetUserInfo(index);
         if(retVal != '')
         {
            folderGuid = (_str)retVal;
            _str guidRE = ':h:8-(:h:4-):3:h:12';
            if(pos(guidRE, folderGuid, 1, 'R'))
            {
               isVS2005SolutionFolder = true;
            }
            else
            {
               folderGuid = '';
            }
         }
         if (!isVS2005SolutionFolder) {
            _str ProjectName=_projecttbTreeGetCurProjectName(index);
            int handle=_ProjectHandle(ProjectName);
            _str AutoFolders=_ProjectGet_AutoFolders(handle);
            boolean error=false;
            if (!strieq(AutoFolders,VPJ_AUTOFOLDERS_CUSTOMVIEW)) {
               error=1;
               if (!AddDeleteFolderErrorDisplayed) {
                  AddDeleteFileErrorDisplayed=true;
                  _message_box(nls("You can't remove folders from this associated project."));
               }
            } else if (_ProjectIs_vcxproj(handle)) {
               error=1;
               DeleteVCXProjFolder(_AbsoluteToProject(_ProjectGet_AssociatedFile(handle), ProjectName));

            } else if (!_ProjectIs_AddDeleteFolderSupported(handle)) {
               error=1;
               if (!AddDeleteFolderErrorDisplayed) {
                  AddDeleteFileErrorDisplayed=true;
                  _message_box(nls("You can't delete folders from the associated project '%s1'",ProjectName));
               }
            }
            if (!error) {
               _str FolderName=_TreeGetCaption(index);
               result=_message_box("Are you sure you want to delete the folder '"FolderName"'?",'',MB_YESNO);
               if (result!=IDYES) {
                  return;
               }
               if (_ProjectIs_SupportedXMLVariation(handle)) {
                  handle=_ProjectGet_AssociatedHandle(handle);
               }
               int Node=_ProjectGet_FolderNode(handle,FolderName);
               _xmlcfg_delete(handle,Node);
               _ProjectSave(handle);
            }
         }
         else {
            // TODO: Method to delete an entire VS2005
            // solution item folder
            _str FolderName=_TreeGetCaption(index);
            result=_message_box("Are you sure you want to delete the folder '"FolderName"'?",'',MB_YESNO);
            if (result!=IDYES) {
               return;
            }
            RemoveSolutionItemFolder2005(folderGuid);
         }
         
      } else if (_projecttbIsDependencyNode(index)) {
         if (_IsWorkspaceAssociated(_workspace_filename)) {
            if (!AddDeleteProjectErrorDisplayed) {
               AddDeleteProjectErrorDisplayed=true;
               _message_box(nls("You cannot remove this dependency because this is an associated workspace."));
            }
            continue;
         }
         _str ProjectName=_projecttbTreeGetCurProjectName(index);
         depname=_RelativeToWorkspace(_projecttbTreeGetCurProjectName(index,true));
         result=_message_box(nls("Remove dependency %s1 from project %s2?",depname,_RelativeToWorkspace(ProjectName)),"",MB_YESNO);
         if (result!=IDYES) {
            return;
         }
         int handle=_ProjectHandle(ProjectName);
         _ProjectRemove_Dependency(handle,depname);
         _ProjectSave(handle);
      } else if (_projecttbIsProjectNode(index)) {
         if(!_IsAddDeleteProjectsSupportedWorkspaceFilename(_workspace_filename)) {
            if (!AddDeleteProjectErrorDisplayed) {
               AddDeleteProjectErrorDisplayed=true;
               _message_box(nls("You cannot remove this project because this is an associated workspace."));
            }
            continue;
         }
         pname=GetProjectDisplayName(_projecttbTreeGetCurProjectName(index,true));
         result=_message_box(nls("Remove project %s1 from workspace %s2?",pname,_workspace_filename),"",MB_OKCANCEL);
         if (result!= IDOK) {
            return;
         }
         _macro('M',_macro('s'));//This is always called from another func, so recording
                                 //get shut off.
         workspace_remove(pname,'',false);
         //toolbarUpdateWorkspaceList();
      }
   }
   typeless handle;
   for (handle._makeempty();;) {
      HitProject._nextel(handle);
      if (handle._isempty()) {
         break;
      }
      _str AutoFolders=_ProjectGet_AutoFolders(handle);
      if (strieq(AutoFolders,VPJ_AUTOFOLDERS_PACKAGEVIEW) ||
          strieq(AutoFolders,VPJ_AUTOFOLDERS_DIRECTORYVIEW)
          ) {
         _ProjectAutoFolders(handle);
      }
      _ProjectSave(handle);
      // regenerate the makefile
      _maybeGenerateMakefile(_xmlcfg_get_filename(handle));
   }
   _TagCallList(TAGFILE_MODIFIED_CALLBACK_PREFIX,TagFilename);
   _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
   if (open_status >= 0) {
      tag_close_db('',1);
   }
   _WorkspaceCache_Update();
   toolbarUpdateWorkspaceList();
}
//3:28pm 7/20/2000 Tested after move from project.e
_command projecttbRefresh() name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   _str ProjectName=_projecttbTreeGetCurProjectName();
   if (ProjectName!='') {
      int handle=_ProjectHandle(ProjectName);
      _str AutoFolders=_ProjectGet_AutoFolders(handle);
      if (strieq(AutoFolders,VPJ_AUTOFOLDERS_PACKAGEVIEW) ||
          strieq(AutoFolders,VPJ_AUTOFOLDERS_DIRECTORYVIEW)
          ) {
         _ProjectAutoFolders(handle);
         _ProjectSave(handle);
      }
   }
   workspace_refresh();
}

//3:25pm 7/20/2000 Tested after move from project.e
// Retn:  0 for OK, 1 for non-file item, -1 for no project toolbar (error)
static int getCurrentTreeFile(int & treeWid, int & currIndex,
                              _str & name, _str & fullpath,
                              _str &ProjectName='')
{
   treeWid= _find_object("_tbprojects_form._proj_tooltab_tree",'N');
   if (treeWid == 0) {
      return -1;
   }
   currIndex= treeWid._TreeCurIndex();
   return(getTreeFile(treeWid,currIndex,name,fullpath,ProjectName));
}

//3:25pm 7/20/2000 Tested after move from project.e
// Retn:  0 for OK, 1 for non-file item, -1 for no project toolbar (error)
int getTreeFile(int treeWid, int index,
                       _str & name, _str & fullpath,
                       _str &ProjectName='')
{
   // check for no tree wid
   if (treeWid <= 0) {
      return -1;
   }
   int formWid;
   _str caption= treeWid._TreeGetCaption(index);
   _str name1="", fullPath1="";
   parse caption with name1 "\t" fullPath1;
   if (substr(name1,1,1)=='*') name1=substr(name1,2);
   if (substr(fullPath1,1,1)=='*') fullPath1=substr(fullPath1,2);
   name= name1;
   //fullpath= strip_filename(_workspace_filename,'N'):+fullPath1;
   fullpath=_AbsoluteToWorkspace(fullPath1);
   if (_IsEclipseWorkspaceFilename(_workspace_filename) && _projecttbIsProjectNode(index)) {
      // For eclipse we only put the name of the file and the directory, but
      // not the whole file.  It looks a little more like the way Eclipse
      // actually does things that way.
      fullpath=VSEProjectFilename(_AbsoluteToWorkspace(fullpath:+name));
   }
   if ((index== TREE_ROOT_INDEX) || (fullpath== "")) {
      return(1);
   }
   ProjectName=_projecttbTreeGetCurProjectName(index);
   return(0);
}

_command projecttbRetagFile() name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   int treeWid, currIndex;
   _str name, fullPath;
   if (getCurrentTreeFile(treeWid, currIndex, name, fullPath)) {
      return(0);
   }
   int temp_view_id=0;
   int orig_view_id=0;
   boolean inmem=false;
   int status=_open_temp_view(fullPath,temp_view_id,orig_view_id,'',inmem,false,true);
   if (status) return(status);
   _str FileList=project_tags_filename();
   _str DoneList='';
   boolean ff=1;
   for (;;) {
      _str CurTagFilename=next_tag_file2(FileList,false);
      if (CurTagFilename=='') break;
      //We don't want to repeat files, and tags_filename sometimes
      //returns a string with duplicates.
      if (pos(' 'CurTagFilename' ',DoneList,'',_fpos_case)) continue;
      status=tag_open_db(CurTagFilename);
      if (status >= 0) {
         message('Retagging 'p_buf_name);
         status=RetagCurrentFile(false);
         clear_message();
         DoneList=DoneList' 'CurTagFilename' ';
         status=tag_close_db(CurTagFilename,1);
      }
      //tag_open_db(CurTagFilename);
   }
   _delete_temp_view(temp_view_id);
   p_window_id=orig_view_id;
}

int _OnUpdate_projecttbRetagWorkspace(CMDUI &cmdui,int target_wid,_str command)
{
   if (_workspace_filename=='') {
      return(MF_GRAYED);
   }
   return(MF_ENABLED);
}

//Changed this to do workspaces.  Left the old name...
_command projecttbRetagProject,projecttbRetagWorkspace() name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   _str oldprojectname=_project_name;
   boolean IsToolbar=false;
   _str old_project_name='';
   if (p_name==PROJECT_TOOLBAR_NAME) {
      IsToolbar=true;
      _str cap=_TreeGetCaption(_TreeCurIndex());
      _str new_project_name="";
      parse cap with "\t" new_project_name;
      old_project_name=_project_name;
      _project_name=new_project_name;
   }

   workspace_retag();

   if (IsToolbar) {
      _project_name=old_project_name;
   }
   _project_name=oldprojectname;
}

//3:30pm 7/20/2000 Tested after move from project.e
void _proj_tooltab_tree.ins()
{
   projecttbAddToProject();
}
//3:30pm 7/20/2000 Tested after move from project.e
void _proj_tooltab_tree.del()
{
   if (!_isProjectTBCommandSupported('projecttbRemove')) return;

   projecttbRemove();
}
//3:30pm 7/20/2000 Tested after move from project.e
void _proj_tooltab_tree.rbutton_up()
{
   int tree_index=_TreeCurIndex();
   int state,bm1,bm2NOLONGERUSED,node_flags;
   if ( !_TreeIsSelected(tree_index) ) {
      _TreeSelectLine(tree_index,true);
      _TreeRefresh();
   }
   boolean isAntBuildFile = _projecttbIsAntBuildFileNode();
   boolean isNAntBuildFile = _projecttbIsNAntBuildFileNode();
   boolean isMakefile = _projecttbIsMakefileNode();

   _str name='';
   _str fullPath='';
   if (_projecttbIsWorkspaceFileNode()) {
      name='_projecttb_workspace_file_menu';
   } else if (_projecttbIsWorkspaceFolderNode()) {
      name='_projecttb_workspace_folder_menu';
   } else if (_projecttbIsWorkspaceNode()) {
      name='_projecttb_workspace_menu';
   } else if (_projecttbIsProjectNode()) {
      name='_projecttb_project_menu';
   } else if (_projecttbIsFolderNode()) {
      name='_projecttb_folder_menu';
   } else if (_projecttbIsProjectFileNode() || isAntBuildFile || isNAntBuildFile) {
      name='_projecttb_file_menu';
   }
   int index;
   index=find_index(name,oi2type(OI_MENU));
   if (!index) {
      return;
   }
   //_TreeGetInfo(_TreeCurIndex(),state,bm1,bm2NOLONGERUSED,flags);
   /*if (!(flags&TREENODE_SELECTED)) {
      _TreeSetAllFlags(0,TREENODE_SELECTED);
      _TreeSetInfo(_TreeCurIndex(),state,bm1,bm2NOLONGERUSED,flags|TREENODE_SELECTED);
   } */
   int menu_handle=p_active_form._menu_load(index,'P');
   _str menu_name=name;   // Need this for the call_list later

   int numSelectedItems, startSelectedItem, endSelectedItem;
   int status=0;
   int submenu_handle=0, submenu_pos=0;
   if (name=='_projecttb_folder_menu') {
      // Are we inserting something into the folder context menu? We must be
      // on a folder node...
      _str ProjectName=_projecttbTreeGetCurProjectName();
      if (ProjectName != '' && strieq(_ProjectGet_Type(_ProjectHandle(ProjectName), GetCurrentConfigName(ProjectName)), 'java')) {
         status=_menu_find(menu_handle,'projecttbFolderProperties',submenu_handle,submenu_pos,'M');
         if (!status) {
            _utDisplayProjectContextMenu(ProjectName, submenu_handle, submenu_pos);
         }
         // enable add class/interface/enum for java package view
         if (strieq(_ProjectGet_AutoFolders(_ProjectHandle()),VPJ_AUTOFOLDERS_PACKAGEVIEW)) {
            int mh = 0, mp = 0, smh = 0, smp = 0;
            status = _menu_find(menu_handle, 'ncw', mh, mp);
            status = _menu_find(mh, 'projecttbAddNewFile', smh, smp, 'M');
            _menu_insert(smh, ++smp,MF_ENABLED,'New Class...','add_java_item Java Class','');
            _menu_insert(smh, ++smp,MF_ENABLED,'New Interface...','add_java_item Java Interface','');
            _menu_insert(smh, ++smp,MF_ENABLED,'New Enum...','add_java_item Java Enum','');
            _menu_insert(smh, ++smp,MF_ENABLED,'New Item From Template...','add_java_item','');
         }
      }
   }

   if (name=='_projecttb_project_menu' || name=='_projecttb_file_menu') {
      _str ProjectName=_projecttbTreeGetCurProjectName();
      if (ProjectName != '' && strieq(_ProjectGet_Type(_ProjectHandle(ProjectName), GetCurrentConfigName(ProjectName)), 'java')) {
         if (name=='_projecttb_file_menu') {
            submenu_pos=_menu_find_loaded_menu_caption(menu_handle,"Compile");
         } else {
            submenu_pos=_menu_find_loaded_menu_caption(menu_handle,'-',submenu_handle);
         }
         if (submenu_pos>=0) {
            _utDisplayProjectContextMenu(ProjectName, menu_handle, submenu_pos);
         }
      }
   }

   int vc_menu_handle=0;
   int dest_vc_index=_menu_find_loaded_menu_caption(menu_handle,"Version Control",vc_menu_handle);
   // IF this menu has a version control menu
   if (dest_vc_index>=0) {
      AddVCMenu(vc_menu_handle);
   }
   int compile_index=_menu_find_loaded_menu_caption(menu_handle,"Compile");
   // IF this menu needs the build menu commands
   if (compile_index>=0) {
      _menu_delete(menu_handle,compile_index);

      _str ProjectName=_projecttbTreeGetCurProjectName();
      int beforeNofitems=_menu_info(menu_handle);

      // if this is an ant build file, list the targets
      if(isAntBuildFile || isMakefile || isNAntBuildFile) {
         // add ant/makefile build targets
         parse _TreeGetCaption(_TreeCurIndex()) with name "\t" fullPath;
         _str mkfileType = '';
         if(isAntBuildFile) {
            mkfileType = "ant";
         } else if(isNAntBuildFile){
            mkfileType = "nant";
         } else if(isMakefile){
            mkfileType = "makefile";
         }
         _addTargetMenuItems(menu_handle, compile_index, ProjectName, fullPath, mkfileType);

      } else if (_projecttbIsProjectFileNode()) {
         int treeWid, currIndex;
         if (getCurrentTreeFile(treeWid, currIndex, name, fullPath)) {
            return;
         }
         _AddBuildMenuItems(menu_handle,compile_index,_Filename2LangId(fullPath),1,'projecttbBuildCommand ',ProjectName);
      } else {
         _AddBuildMenuItems(menu_handle,compile_index,'',2,'projecttbBuildCommand ',ProjectName);
      }
      int Nofitems=_menu_info(menu_handle)-beforeNofitems;
      // Check for two -- in a row

      if (compile_index>0) {
         --compile_index;
      }
      _str prevCaption='';
      for (;compile_index<_menu_info(menu_handle);++compile_index) {
         _str caption;
         int mf_flags=0;
         _menu_get_state(menu_handle,compile_index,mf_flags,'P',caption);
         if (prevCaption=='-' && caption=='-') {
            _menu_delete(menu_handle,compile_index);
            --compile_index;
         }
         prevCaption=caption;
      }

      initMenuSetActiveConfig(menu_handle, _no_child_windows(), ProjectName);
   }

   int formWid;
   formWid= _find_object("_tbprojects_form",'N');
   if (!formWid) return;
   int treeWid;
   treeWid= formWid._proj_tooltab_tree.p_window_id;
   int currIndex;
   currIndex= treeWid._TreeCurIndex();
   _str caption;
   caption= treeWid._TreeGetCaption(currIndex);
   parse caption with name "\t" fullPath;

   // If a file is not selected, disable file operations:
   int Depth=_TreeGetDepth(currIndex);
   if (!_projecttbIsProjectFileNode(currIndex)
       //_projecttbIsProjectNode(currIndex) ||
       //_projecttbIsFolderNode(currIndex)
       ) {
      _menu_set_state(menu_handle, "projecttbCompile", MF_GRAYED, 'M');
      _menu_set_state(menu_handle, "projecttbEditFile", MF_GRAYED, 'M');
      _menu_set_state(menu_handle, "projecttbCheckin", MF_GRAYED, 'M');
      _menu_set_state(menu_handle, "projecttbCheckout", MF_GRAYED, 'M');
      _menu_set_state(menu_handle, "projecttbRetagFile", MF_GRAYED, 'M');
   }
   if (!_projecttbIsProjectNode(currIndex)) {
      _menu_set_state(menu_handle, "projecttbBuild", MF_GRAYED, 'M');
      _menu_set_state(menu_handle, "projecttbRebuild", MF_GRAYED, 'M');
      _menu_set_state(menu_handle, "projecttbGenerateMakefile", MF_GRAYED, 'M');
   } else {
      // add ant/makefile build targets (inserts above first separator)
      _addTargetSubmenu(menu_handle, _projecttbTreeGetCurProjectName());

      // makefile generation not supported for all project types
      if(!_project_supports_makefile_generation(_projecttbTreeGetCurProjectName(-1,true))) {
         _menu_set_state(menu_handle, "projecttbGenerateMakefile", MF_GRAYED, 'M');
      }
   }
   // IF there are no projects in this workspace
   if (_project_name== "") {
      _menu_set_state(menu_handle, "projecttbAddToProject", MF_GRAYED, 'M');
      _menu_set_state(menu_handle, "projecttbRetagProject", MF_GRAYED, 'M');
      _menu_set_state(menu_handle, "project_edit", MF_GRAYED, 'M');
      _menu_set_state(menu_handle, "projecttbCompile", MF_GRAYED, 'M');
   }

   // Show the menu:
   int x=VSDEFAULT_INITIAL_MENU_OFFSET_X;
   int y=VSDEFAULT_INITIAL_MENU_OFFSET_Y;
   x=mou_last_x('M')-x;y=mou_last_y('M')-y;
   _lxy2dxy(p_scale_mode,x,y);
   _map_xy(p_window_id,0,x,y,SM_PIXEL);
   int flags=VPM_LEFTALIGN|VPM_RIGHTBUTTON;
   _KillToolButtonTimer();
   //TreeDisablePopup(DelaySetting);
   //get_window_id(orig_view_id);
   call_list('_on_popup_',translate(menu_name,'_','-'),menu_handle);
   status=_menu_show(menu_handle,flags,x,y);
   //activate_window(orig_view_id);
   _menu_destroy(menu_handle);
   //TreeEnablePopup(DelaySetting);
}

static void AddVCMenu(int vc_menu_handle)
{
   if ( _VCIsSpecializedSystem(_GetVCSystemName())) {
      _CVSAddTreeMenu(vc_menu_handle);
   }else{
      // Copy the contents of this menu from the _ext_menu_default menu
      int temp=find_index("_ext_menu_default",oi2type(OI_MENU));
      int src_vc_index=_menu_find_caption(temp,"Version Control");
      if ( src_vc_index ) {
         int child=src_vc_index.p_child;
         int firstchild=child;
         for (;;) {
            _str item_text=stranslate(child.p_caption,'','&');
            //_message_box('vc_menu_handle='vc_menu_handle);
            //_menu_insert(vc_menu_handle,-1,MF_ENABLED,'a','b','c','h','m');
            int status=_menu_insert(vc_menu_handle,-1,MF_ENABLED,child.p_caption,child.p_command,child.p_categories,child.p_help,child.p_message);
            child=child.p_next;
            if (child==firstchild) {
               break;
            }
         }
      }
   }
}

// Desc: If the application command is a VSE _command, use it. Otherwise
//       look for the program in the path and use it.
void _projecttbRunAppCommand(_str appCommand, _str fullPath)
{
   // Build the actual command:
   _str command, temp, pgmname;
   int status;
   command= _parse_project_command(appCommand, fullPath, _project_name, "");
   temp= command;
   pgmname= parse_file(temp);

   // If there is a VSE command, use it. Otherwise look for program in the
   // path and, if found, use it instead.
   int index= find_index(pgmname, COMMAND_TYPE);
   if (index) {
      status= execute(command, '');
   } else {
      temp= slick_path_search(pgmname, 'p');
      if (temp=='') {
         _str message2= ".\n\nGo to Tools > Options > Languages > File Extension Manager to edit the application associated with this file extension.";
         _message_box(nls("Program %s not found",pgmname)message2);
      }
      //messageNwait("projecttbRunAppCommand command="command);
      status= shell(command,'ap');
   }
}

int _OnUpdate_projecttbBuildCommand(CMDUI &cmdui,int target_wid,_str command)
{
   _str remainder, cmdname;
   parse command with cmdname remainder;  // we want the arguments
   _str args[];
   _utSplitString(remainder, args, " ");
   if (args._length() >= 1) {
      int index=find_index('_OnUpdate_projecttbBuildCommand_'args[0],PROC_TYPE);
      if (index_callable(index)) {
         typeless status=0;
         if (target_wid) {
            p_window_id=target_wid;
            status=call_index(cmdui,target_wid,remainder,index);
         } else {
            status=call_index(cmdui,target_wid,remainder,index);
         }
         return(status);
      }
   }
   return _OnUpdateDefault(cmdui, target_wid, command);
}

int _OnUpdate_projecttbBuildCommand_project_usertool(CMDUI &cmdui,int target_wid,_str command)
{
   _str remainder, cmdname;
   parse command with cmdname remainder;  // we want the arguments
   _str args[];
   _utSplitString(remainder, args, " ");
   if (args._length() >= 1) {
      int index=find_index('_OnUpdate_projecttbBuildCommand_project_usertool_'args[0],PROC_TYPE);
      if (index_callable(index)) {
         typeless status=0;
         if (target_wid) {
            p_window_id=target_wid;
            status=call_index(cmdui,target_wid,remainder,index);
         } else {
            status=call_index(cmdui,target_wid,remainder,index);
         }
         return(status);
      }
   }
   return _OnUpdateDefault(cmdui, target_wid, command);
}

int _OnUpdate_projecttbBuildCommand_project_usertool_unittest(CMDUI &cmdui,int target_wid,_str command)
{
   if (cmdui.menu_handle == 0) {
      return MF_ENABLED;
   }

   int hTree = _find_object('_tbprojects_form._proj_tooltab_tree');
   numSelected := hTree._TreeGetNumSelectedItems();
   if (_projecttbTreeGetCurProjectName() != _project_name) {
      return MF_GRAYED;
   }
   else if (numSelected > 1) {
      return MF_GRAYED;
   }
   else {
      return MF_ENABLED;
   }
}

_command projecttbAddNewBuildTool() name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   // figure out which project was selected for this action
   int treeWid, currIndex;
   _str name, fullPath;
   if (getCurrentTreeFile(treeWid, currIndex, name, fullPath)) {
      return 0;
   }

   _str old_project_name=_project_name;
   workspace_set_active(VSEProjectFilename(fullPath),false,false,false);

   wid := p_window_id;
   p_window_id = _mdi;
   project_tool_wizard();

   p_window_id = wid;

   workspace_set_active(VSEProjectFilename(old_project_name),false,false,false);
}
