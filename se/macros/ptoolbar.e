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
#import "se/lang/api/ExtensionSettings.e"
#import "backtag.e"
#import "compile.e"
#import "complete.e"
#import "context.e"
#import "cvs.e"
#import "dir.e"
#import "files.e"
#import "guicd.e"
#import "guiopen.e"
#import "help.e"
#import "ini.e"
#import "listproc.e"
#import "main.e"
#import "makefile.e"
#import "menu.e"
#import "mprompt.e"
#import "picture.e"
#import "projconv.e"
#import "project.e"
#import "projgui.e"
#import "projmake.e"
#import "projutil.e"
#import "seltree.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "tagrefs.e"
#import "tags.e"
#import "tbprojectcb.e"
#import "toast.e"
#import "se/ui/toolwindow.e"
#import "se/ui/twevent.e"
#import "treeview.e"
#import "xmlcfg.e"
#import "unittest.e"
#import "util.e"
#import "vc.e"
#import "vstudiosln.e"
#import "wkspace.e"
#endregion

int def_project_wildcard_refresh_folders = 0;
int def_project_wildcard_flat_file_list = 0;
bool def_project_show_relative_paths = true;
bool def_project_show_sorted_folders = false;

static const TBPROJECTS_FORM= '_tbprojects_form';
int _tbGetActiveProjectsForm()
{
   return tw_find_form(TBPROJECTS_FORM);
}
int _tbGetActiveProjectsTreeWid()
{
   form_wid := _tbGetActiveProjectsForm();
   if (!form_wid) {
      return 0;
   }
   _nocheck _control _proj_tooltab_tree;
   return form_wid._proj_tooltab_tree;
}

struct TBPROJECTS_FORM_INFO {
   int m_form_wid;
};
TBPROJECTS_FORM_INFO gtbProjectsFormList:[];

static void _init_all_formobj(TBPROJECTS_FORM_INFO (&formList):[],_str formName) {
   int last = _last_window_id();
   int i;
   for (i=1; i<=last; ++i) {
      if (_iswindow_valid(i) && i.p_object == OI_FORM && !i.p_edit) {
         if (i.p_name:==formName) {
            formList:[i].m_form_wid=i;
         }
      }
   }
}

static _str ptbCopyTree:[];
static int ptbCopyTreeFormWid = -1;

definit()   
{
   gtbProjectsFormList._makeempty();
   _init_all_formobj(gtbProjectsFormList,TBPROJECTS_FORM);
   ptbCopyTreeFormWid = -1;
   ptbCopyTree._makeempty();
}

using se.lang.api.ExtensionSettings;

defeventtab _yesToAll_form;

void ctlYes.on_create(_str question="", _str caption="", bool showNoToAll=true)
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

defeventtab _tbprojects_form;

void _tbprojects_form.'C-A'-'C-Z',F2-F4,               'c-a-a'-'c-a-z','a-m-a'-'a-m-z','M-A'-'M-Z','S-M-A'-'S-M-Z'()
//void _tbprojects_form.'C-A'-'C-Z',F2-F4,f6-F12,C_F12,'c-a-a'-'c-a-z','a-m-a'-'a-m-z','M-A'-'M-Z','S-M-A'-'S-M-Z','a-0'-'a-9'()   
{
   _control _proj_tooltab_tree;
   if ((last_event():==C_V || last_event():==name2event('M-V')) && p_name=='_proj_tooltab_tree') {
      projecttbPaste();
      return;
   }
   if ((last_event():==C_C || last_event():==name2event('M-C')) && p_name=='_proj_tooltab_tree') {
      projecttbCopy();
      return;
   }
   if ((last_event():==C_X || last_event():==name2event('M-X'))  && p_name=='_proj_tooltab_tree') {
      projecttbCut();
      return;
   }
   _smart_toolwindow_hotkey();
}
static void _bind_more_tool_window_form_keys(int keytab_index) {
   if (_isMac()) {
      return;
   }
   int index=eventtab_index(keytab_index,keytab_index,event2index(C_A));
   set_eventtab_index(keytab_index,event2index(F6),index,event2index(F12));
   set_eventtab_index(keytab_index,event2index(C_F12),index);
   set_eventtab_index(keytab_index,event2index(A_0),index,event2index(A_9));
}
void _proj_tooltab_tree.on_drop_files(int target_wid) {
   _str directory_list[];
   _str file_list[];

   for ( ;; ) {
      _str filename = _next_drop_file();
      if ( filename == '' ) {
         break;
      }
      if (isdirectory(filename)) {
         _maybe_append_filesep(filename);
         directory_list:+=filename;
         continue;
      }
      file_list:+=filename;
   }
   // Most users want to be able to edit files after they
   // are dropped on the editor. If the editor did not have
   // focus before the drag-drop operation started, then it
   // will not have focus when it is finished...unless we
   // force it. Unfortunately, we cannot call _AppHasFocus()
   // to test for application focus because it will always
   // return true during the drop operation.
   // 7/31/2013 - rb : May not be absolutely necessary since moving to Qt,
   // but should be no harm in keeping it around.
   int mdi_wid = _MDIFromChild(target_wid);
   if ( !mdi_wid ) {
      mdi_wid = _MDICurrent();
   }
   if (mdi_wid) {
      mdi_wid._set_foreground_window(VSWID_TOP);
   }

   if (directory_list._length()>0) {
      project_add_directory_folder(directory_list);
   }
   if (file_list._length()) {
      if (_project_name=='') {
         for (i:=0;i<file_list._length();++i) {
            //say('_on_drop_files : atWid='atWid.p_buf_name' ('atWid')  focus='_get_focus());
            int status = edit(_maybe_quote_filename(file_list[i]), EDIT_DEFAULT_FLAGS);
            if ( status ) {
               break;
            }
         }
         return;
      }
      status:=project_add_files_prompt_project(file_list);
      if (!status) {
         message('File(s) added to project');
      }
   }

}
// clark: I can't find any source code which creates the Projects
// tool window and passes the projectName. This can probably
// be removed.
void _proj_tooltab_tree.on_create(_str projectName="")
{
   p_AllowDropFiles=true;
   _bind_more_tool_window_form_keys(p_active_form.p_eventtab);
   TBPROJECTS_FORM_INFO info;
   i := p_active_form;
   info.m_form_wid=p_active_form;
   gtbProjectsFormList:[i]=info;

   if (projectName == "") {
      projectName= _project_name;
   }
   _TreeColWidth(0, 5000);  // Just init to some value

   if (_isMac()) {
      macSetShowsFocusRect(p_window_id, 0);
   }

   // Add files
   toolbarUpdateFilterListForForm(p_active_form,projectName);

   toolbarRestoreState(_workspace_filename,p_active_form);
}

void toolbarSaveExpansion(int form_wid= -1)
{
   if (form_wid<0) {
      form_wid=_tbGetActiveProjectsForm();
      if (!form_wid) {
         return;
      }
   }
   _str array[];
   form_wid._proj_tooltab_tree._GetProjTreeStates(array);
   temp_view_id := 0;
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
      toolbarSaveExpansion(p_active_form);
   }
   // Call user-level2 ON_DESTROY so that tool window docking info is saved
   call_event(p_window_id,ON_DESTROY,'2');
   gtbProjectsFormList._deleteel(p_active_form);
   if (ptbCopyTreeFormWid == p_active_form) {
      ptbCopyTreeFormWid = -1;
      ptbCopyTree._makeempty();
   }
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

static _str _projecttbIsDirectoryFolder(int index)
{
   typeless info = _TreeGetUserInfo(index);
   if (info) {
      if (pos("DF:{", info, 1)) {
         parse info with auto junk "DF:{" auto node "}" .;
         if (node != '') {
            return node;
         }
      }
   }
   return "";
}

static _str _projecttbGetDirectoryFolderNames(int project_handle, int index)
{
   typeless info = _TreeGetUserInfo(index);
   if (info) {
      if (pos("DF:{", info, 1)) {
         parse info with auto junk "DF:{" auto nodes "}" .;
         if (nodes != '') {
            if (project_handle < 0) {
               projName := _projecttbTreeGetCurProjectName(index);
               project_handle = _ProjectHandle(projName);
            }
            names := "";
            split(nodes, ',', auto nodelist);
            for (i := 0; i < nodelist._length(); ++i) {
               int node = (int)nodelist[i];
               n := translate(_xmlcfg_get_attribute(project_handle, node, 'N', 0), FILESEP, FILESEP2);
               _SeparateWildcardPath(n, auto p, auto name);
               _maybe_append(names, ";");
               names :+=  n;
            }
            return names;
         }
      }
   }
   return "";
}


static _str _projecttbWildcardFolderDirectory(int index)
{
   typeless info = _TreeGetUserInfo(index);
   if (info) {
      user := _TreeGetUserInfo(index);
      if (user != '') {
         parse user with "WD:{" auto wd "}"  .;
         if (wd != '') {
            return _maybe_unquote_filename(wd); 
         }
      }
   }
   return "";
}

//2:37pm 7/20/2000 Tested after move from project.e
void _proj_tooltab_tree.on_change(int reason, int index)
{
   if (index >= 0) {
      //say(index': '_TreeGetUserInfo(index));
   }
   switch (reason) {
   case CHANGE_COLLAPSED:
      // do nothing for CHANGE_COLLAPSED
      break;
   case CHANGE_LEAF_ENTER:
      if (_projecttbIsProjectFileNode(index)) {
         curproject := _projecttbTreeGetCurProjectName(-1,true);
         caption := _TreeGetCaption(index);
         name := "";
         fullPath := "";
         parse caption with name "\t" fullPath;
         fullPath=_AbsoluteToWorkspace(fullPath);
         projecttbMaybeEditFile(index, name, fullPath);
         return;
      } else if (_projecttbIsProjectNode(index) && _TreeGetFirstChildIndex(index) < 0) {
         _TreeGetInfo(index,auto state);
         toolbarBuildFilterList(_projecttbTreeGetCurProjectName(index),index);
         _TreeSetInfo(index,(int)!state);
         // Rebuilding the filter list for the project just expanded
         // will re-set the current index. Refocus the project node
         _TreeSetCurIndex(index);
      }
      break;
   case CHANGE_EXPANDED:
      if (_projecttbIsProjectNode(index) && _TreeGetFirstChildIndex(index) < 0) {
         toolbarBuildFilterList(_projecttbTreeGetCurProjectName(index),index);
         // Rebuilding the filter list for the project just expanded
         // will re-set the current index. Refocus the project node
         _TreeSetCurIndex(index);
      } else if (_projecttbIsFolderNode(index) || _projecttbIsProjectNode(index)) {
         _post_call(delayedSizeColumnToContents,p_window_id);
      } else {
         _post_call(delayedSizeColumnToContents,p_window_id);
      }
      break;
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
   if (ext != '') {
      ext = lowcase(ext);
      appCommand = ExtensionSettings.getOpenApplication(ext, '');
      assocType = (int)ExtensionSettings.getUseFileAssociation(ext);
   }

   return(1);
}

void _project_open_file(_str filename) {
   // Determine if file type association needs to be applied
   // to this file. These are defined in defaults.e where you
   // see setup_association calls.
   int assocType;
   _str appCommand;
   projecttbGetFileAssociationCommand(filename, appCommand, assocType);

   if (_isUnix()) {
      if (!_isMac()) {
         // On Unix, we don't have file type association. This should be false
         // all the time on Unix anyway. This is only a precaution in case
         // something slips thru the crack.
         assocType= 0;
      }
   }
   if (substr(filename,1,1)=='*') {
      filename=substr(filename,2);
   }

   // If file association is not used, check the application
   // command and use it instead.
   if (!assocType) {
      if (appCommand != "") {
         _projecttbRunAppCommand(appCommand, _maybe_quote_filename(absolute(filename)));
      } else {
         edit(_maybe_quote_filename(filename),EDIT_DEFAULT_FLAGS);
      }
      return;
   }

   msg := "";
   typeless status=0;

   status=_ShellExecute(absolute(filename));
   if ( status<0 ) {
      _message_box(get_message(status)' ':+ filename);
   }
}

//2:40pm 7/20/2000 Tested after move from project.e
static void projecttbMaybeEditFile(int index, _str name, _str fullPath)
{
   _project_open_file(fullPath);
}
static void projecttbOptionalEdit(_str msg, _str name, _str fullPath)
{
   int idval;
   idval= _message_box(msg :+ name :+ ".\n\nEdit file in SlickEdit?",
                       "", MB_YESNO|MB_ICONQUESTION);
   if (idval== IDNO) return;
   edit(_maybe_quote_filename(fullPath),EDIT_DEFAULT_FLAGS);
   return;
}

//2:42pm 7/20/2000 Tested after move from project.e
_command int projecttbSetCurProject() name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   if (p_name!='_proj_tooltab_tree') {
      return(1);
   }
   curIndex := _TreeCurIndex();
   WholePath := _projecttbTreeGetCurProjectName(curIndex);
   workspace_set_active(WholePath);
   return(0);
}

typedef void (*pfnTreeSelCallback_tp)(int index,_str name,_str fullPath);

// Tree must be active
static void TreeWithSelection(pfnTreeSelCallback_tp pfn)
{
   int currIndex;
   name := fullPath := "";
   treeWid := p_window_id;
   int info;
   for (ff:=1;;ff=0) {
      index := _TreeGetNextSelectedIndex(ff,info);
      if (index<0) break;
      if (_GetProjectToolWindowTreeFile(treeWid, index, name, fullPath)) {
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
   treeWid= _tbGetActiveProjectsTreeWid();
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
_str _projecttbTreeGetCurProjectName(int index=-1,bool allowDependentProjects=true,int &ProjectIndex= -1)
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

   ProjectName := "";
   name := _TreeGetCaption(index);
   relpath := "";
   parse name with name "\t" relpath;
   if (_IsEclipseWorkspaceFilename(_workspace_filename)) {
      // For eclipse we only put the name of the file and the directory, but
      // not the whole file.  It looks a little more like the way Eclipse
      // actually does things that way.
      ProjectName=VSEProjectFilename(_AbsoluteToWorkspace(relpath:+name:+PRJ_FILE_EXT));
   } else {
      ProjectName=VSEProjectFilename(_AbsoluteToWorkspace(relpath));
   }
   ProjectIndex=index;
   return(ProjectName);
}

static _str _projecttbGetDefaultSourcePath(int handle,_str projName) {
   /*
      Project Properties uses the project working directory
      when adding files. When a folder doesn't
      have a path, using the working directory
      is best because it's more consistent. Also,
      when selecting the Project, using the working directory
      is best because it's more consistent.
    
      If users complains, using the current directory
      might make sense as an alternative option. The old Project
      tool window code was very inconsistent. Sometimes,
      it used the current directory and sometimes it used
      the Project directory. 
   */
   path:=_ProjectGet_WorkingDir(_ProjectHandle());
   path=absolute(path,_file_path(projName));
   _maybe_append_filesep(path);
   //path=getcwd();
   //_maybe_append_filesep(path);
   return path;
}
static _str _projecttbTreeGetCurSourcePath(int index = -1) {
   return _projecttbTreeGetCurFolderPath(index,true);
}

static _str _projecttbTreeGetCurFolderPath(int index = -1,bool return_default_add_source_path=false)
{
   if (index<0) {
      index=_TreeCurIndex();
   }

   // this only makes sense in directory view
   projName := _projecttbTreeGetCurProjectName(index);
   handle := _ProjectHandle(projName);
   // we have to build a path
   path := '';
   if (!_projecttbIsFolderNode()) {
      if (return_default_add_source_path) {
         return _projecttbGetDefaultSourcePath(handle,projName);
      }
      return '';
   }

   autoFolders := _ProjectGet_AutoFolders(handle);
   if (_projecttbIsWorkspaceItemNode(index) && _projecttbIsWorkspaceNode(_TreeGetParentIndex(index)))  {
      path = _strip_filename(_workspace_filename, 'N');
      return path;
   }
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
      path = absolute(path,_AbsoluteToWorkspace(projPath));
      return path;
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
   } else {
      path = _AbsoluteToWorkspace(_strip_filename(projName, 'N'));
      user := _TreeGetUserInfo(index);
      if (user != '') {
         parse user with "WD:{" auto folder_wd "}"  .;
         if (folder_wd != '') {
            return _maybe_unquote_filename(folder_wd); 
         }
      }
   }

   if (return_default_add_source_path) {
      return _projecttbGetDefaultSourcePath(handle,projName);
   }
   return path;
}

static int _projecttbTreeFolderNode(int handle, int index = -1)
{  
   if (index < 0) {
      index = _TreeCurIndex();
   }

   guid := "";
   typeless user = _TreeGetUserInfo(index);
   if (user != '') {
      parse user with "GUID:" guid .;
   }
   if (!_IsWorkspaceAssociated(_workspace_filename) && (guid:=='')) {
      // folder guid required for SlickEdit projects
      return -1;
   }
   name := _TreeGetCaption(index);
   int node = _ProjectGet_FolderNode(handle, name, guid);
   return node;
}

static _str NoRemove(bool a,int b) {
   return( (a && b==3) || (!a && b==2));
}

static int RemoveVC(_str fullPath, 
                    bool &yesToAllVC=false,
                    bool &noToAllVC=false)
{
   status := 0;
   _str Files[];
   Files._makeempty();
   if ( _haveVersionControl() && ( (machine()=='WINDOWS' && _isscc() && _SCCProjectIsOpen() ) ||
                                   _VCSCommandIsValid(VCS_REMOVE)) ) {
      if (!yesToAllVC && !noToAllVC) {
         buttons := "Yes,Yes to &All,No,No to All,Cancel:_cancel\tRemove file '"fullPath"' from version control?";
         status=textBoxDialog('Remove Files From Version Control',
                              0,
                              0,
                              "",
                              buttons);
         if (status<0) {
            return(status);
         }
         if (status==2) {
            yesToAllVC=true;
         }
         if (status==4) {
            noToAllVC=true;
         }
      }
      if ( yesToAllVC || status==1 ) {
         status = vcremove(fullPath,true);
      }
   }
   return(status);
}

static int RemoveWildcardFromProject(_str fullPath,
                                     bool &yesToAllWCDelete=false,
                                     bool &yesToAllVC=false,
                                     bool &noToAllWCDelete=false,
                                     bool &noToAllVC=false,
                                     bool UseYesToAll=true,
                                     _str CurProjectName=_project_name,
                                     bool CacheProjects_TagFileAlreadyOpen=false)
{
   status := 0;
   DeleteWildcardFile := false;
   if (!yesToAllWCDelete && !noToAllWCDelete) {
      buttons := "";
      if (UseYesToAll) {
         buttons="Yes,Yes to &All,No,No to All,Cancel:_cancel\tWildcard file cannot be removed from project.  Delete file '"fullPath"' from disk?";
      } else {
         buttons="Yes,No,Cancel:_cancel\t\tWildcard file cannot be removed from project.  Delete file '"fullPath"' from disk?";
      }
      status=textBoxDialog('Delete Wildcard Files From Disk',
                           0,
                           0,
                           "",
                           buttons,
                           "",
                           "");
      if (status<0) {
         return(status);
      }
      if (UseYesToAll && status==2) {
         yesToAllWCDelete=true;
      }
      if (UseYesToAll && status==4) {
         noToAllWCDelete=true;
      }
   }

   DeleteWildcardFile = (yesToAllWCDelete || !NoRemove(UseYesToAll, status));
   if (DeleteWildcardFile) {
      status=recycle_file(fullPath);
      if ( status!=0 ) {
         _str msg = "Warning: Could not delete file. "get_message(status):+"\n\n":+
                    fullPath;
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         return status;
      }
   }
   status = RemoveVC(fullPath, yesToAllVC, noToAllVC);
   return(0);
}

//3:26pm 7/20/2000 Tested after move from project.e
static int RemoveFromProjectAndVC(_str fullPath,
                                  bool &yesToAllRemove=false,
                                  bool &yesToAllVC=false,
                                  bool &noToAllRemove=false,
                                  bool &noToAllVC=false,
                                  bool &DeleteFromDisk=false,
                                  bool UseYesToAll=true,
                                  _str CurProjectName=_project_name,
                                  bool CacheProjects_TagFileAlreadyOpen=false)
{
   buttons := "";
   status := 0;
   if (!yesToAllRemove && !noToAllRemove ) {
      if (UseYesToAll) {
         buttons="Yes,Yes to &All,No,No to All,Cancel:_cancel\tRemove file '"fullPath"' from project?";
      } else {
         buttons="Yes,No,Cancel:_cancel\tRemove file '"fullPath"' from project?";
      }
      status=textBoxDialog('Remove Files From Project',
                           0,
                           0,
                           "",
                           buttons,
                           "",
                           "-checkbox Delete permanently from disk:0");
      if ( status<0 ) {
         return(status);
      }
      if ( UseYesToAll && status==2 ) {
         yesToAllRemove=true;
      }
      if ( UseYesToAll && status==4 ) {
         noToAllRemove=true;
      }
      DeleteFromDisk= ( _param1 == 1 );
   }
   DontRemove := NoRemove(UseYesToAll,status);

   if (!DontRemove) {
      status=project_remove_filelist(CurProjectName,_maybe_quote_filename(fullPath),CacheProjects_TagFileAlreadyOpen);
      if ( status==0 && DeleteFromDisk ) {
         status=recycle_file(fullPath);
         if ( status!=0 ) {
            _str msg = "Warning: Could not delete file. "get_message(status):+"\n\n":+
                       fullPath;
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            return status;
         }
      }
   }
   status = RemoveVC(fullPath, yesToAllVC, noToAllVC);
   return(0);
}

int _OnUpdate_projecttbRefilter(CMDUI &cmdui,int target_wid,_str command)
{
   if (target_wid && target_wid.p_object==OI_TREE_VIEW) {
      if (_workspace_filename=='') {
         return(MF_GRAYED);
      }
      ProjectName := target_wid._projecttbTreeGetCurProjectName();
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
   treeWid := p_window_id;
   ProjectName := _projecttbTreeGetCurProjectName();
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
   _config_modify_flags(CFGMODIFY_DEFVAR);
   toolbarUpdateWorkspaceList();
}

int _OnUpdate_projecttbRefilterWildcards(CMDUI &cmdui,int target_wid,_str command)
{
   return def_refilter_wildcards ? MF_CHECKED : MF_UNCHECKED;
}

int _OnUpdate_projecttbPaste(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdate_projecttbCut(cmdui,target_wid,command,true));
}
static bool _ParentFolderCopied(int index)
{
   showchildren := bm1 := bm2NOLONGERUSED := 0;
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
      newconfigs := "";
      count := 0;
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
static void AdjustFolderCopy(int DestHandle,
                             int SourceHandle,
                             int Node,
                             int (&DestFileToNode):[],
                             int (&SourceFileToNode):[],
                             _str option,
                             _str (&NewFilesList)[],
                             _str (&DeletedFilesList)[],
                             int (&ExtToNodeHashTab):[],
                             int (&ObjectInfo):[],
                             _str (&ConfigInfo)[]
                            )
{
   XMLVARIATIONS xmlv;
   _ProjectGet_XMLVariations(DestHandle,xmlv);
   //_message_box('N='FolderName' 2='Node2);
   if (SourceHandle==DestHandle && option=='T') {
   } else {
      _str FolderName=_xmlcfg_get_attribute(DestHandle,Node,'Name');
      _xmlcfg_set_attribute(DestHandle,Node,'Name','');
      ParentNode := _xmlcfg_get_parent(DestHandle,Node);
      BaseName := FolderName;
      fi := 2;
      for (;;) {
         index := _xmlcfg_find_simple(DestHandle,xmlv.vpjtag_folder:+XPATH_STRIEQ(xmlv.vpjattr_folderName,FolderName), ParentNode);
         if (index < 0) {
            break;
         }
         FolderName = BaseName:+' ':+fi;
         ++fi;
      }
      _xmlcfg_set_attribute(DestHandle,Node,'Name',FolderName);
#if 0
      _str filters=_ProjectGet_FolderFiltersAttr(DestHandle,Node);
      MakeUpFilter := false;
      if (filters=='') {
         int *pnode=ExtToNodeHashTab._indexin('');
         if (pnode && *pnode!=_ProjectGet_FilesNode(DestHandle)) {
            MakeUpFilter=true;
         }
      } else {
         for (;;) {
            ext := "";
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
#endif
   }
   Node=_xmlcfg_get_first_child(DestHandle,Node);
   for (;Node>=0;) {
      int NextNode=_xmlcfg_get_next_sibling(DestHandle,Node);
      if (_xmlcfg_get_name(DestHandle,Node):==VPJTAG_FOLDER) {
         AdjustFolderCopy(DestHandle,SourceHandle,Node,DestFileToNode,SourceFileToNode,option,NewFilesList,DeletedFilesList,ExtToNodeHashTab,ObjectInfo,ConfigInfo);
         _ProjectAdd_FolderGuid(DestHandle,Node); // update folder guid
      } else {
         _str RelFilename=translate(_xmlcfg_get_attribute(DestHandle,Node,xmlv.vpjattr_n),FILESEP,FILESEP2);
         _str DestRelFilename=_RelativeToProject(_AbsoluteToProject(RelFilename,_xmlcfg_get_filename(SourceHandle)),_xmlcfg_get_filename(DestHandle));
         if (SourceHandle!=DestHandle) {
            NewFilesList :+= DestRelFilename;
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
               DeletedFilesList :+= RelFilename;
            }
         }
      }
      Node=NextNode;
   }
}

static bool _CheckDestParentNodes(int DestHandle, int SrcHandle, int DestNode, int SrcNode)
{
   if (DestHandle != SrcHandle) {
      return false;
   }
   while (DestNode >= 0) {
      if (DestNode == SrcNode) {
         return true;
      }
      DestNode = _xmlcfg_get_parent(DestHandle, DestNode);
   }
   return false;
}

static void _CopyCutItems(int index,
                          int DestTreeParentIndex,int DestHandle,
                          int &DestNode,int &DestNodeFlags,
                          int DestParent,int &DestParentFlags,
                          int SourceHandle,int &error,
                          int (&DestFileToNode):[],
                          int (&SourceFileToNode):[],
                          _str (&NewFilesList)[],
                          _str (&DeletedFilesList)[],
                          int (&ObjectInfo):[],
                          _str (&ConfigInfo)[])
{
   typeless array[];
   caption := "";
   filename := "";
   RelFilename := "";
   typeless showchildren=0, option=0, bm1=0, bm2NOLONGERUSED=0;

   XMLVARIATIONS xmlv;
   _ProjectGet_XMLVariations(DestHandle,xmlv);
   index=_TreeGetFirstChildIndex(index);
   for (;index>=0;) {
      next_index := _TreeGetNextSiblingIndex(index);
      _TreeGetInfo(index,showchildren,bm1,bm2NOLONGERUSED);
      if (ptbCopyTree._indexin(index) && bm1==_pic_doc_d && !_ParentFolderCopied(index)) {
         caption=_TreeGetCaption(index);
         parse caption with "\t" filename;
         parse ptbCopyTree:[index] with option' 'bm1;
         //parse _TreeGetUserInfo(index) with option' 'bm1' 'bm2NOLONGERUSED;
         filename = _AbsoluteToWorkspace(filename);
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
               DeletedFilesList :+= RelFilename;
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
                  DeletedFilesList :+= RelFilename;
               }
            }

            //parse _TreeGetUserInfo(index) with option' 'bm1;
            parse ptbCopyTree:[index] with option' 'bm1;
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
      } else if (ptbCopyTree._indexin(index) && bm1==_pic_tfldclosdisabled && !_ParentFolderCopied(index)) {
         int Node = _projecttbTreeFolderNode(SourceHandle, index);
         if (_CheckDestParentNodes(DestHandle, SourceHandle, DestParent, Node)) {
            DestParentName := _xmlcfg_get_attribute(DestHandle, DestParent, 'Name');
            FolderName := _xmlcfg_get_attribute(DestHandle, Node, 'Name');
            msg := nls('Destination folder "%s" is a subfolder of the source folder "%s".', DestParentName, FolderName);
            message(msg);
            index=next_index;
            continue;
         }
         flags := 0;
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
         _ProjectAdd_FolderGuid(DestHandle,DestParent);
         //parse _TreeGetUserInfo(index) with option' 'bm1;
         parse ptbCopyTree:[index] with option' 'bm1;
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
   if (ptbCopyTree._isempty()) return;

   ProjectName := _projecttbTreeGetCurProjectName();
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
   DestTreeParentIndex := _TreeCurIndex();
   int DestParentFlags=VSXMLCFG_ADD_AS_CHILD;
   if (_projecttbIsProjectFileNode()) {
      DestTreeParentIndex=_TreeGetParentIndex(DestTreeParentIndex);
   }
   //if (_projecttbIsProjectFileNode()) {
   //   parse _TreeGetCaption(_TreeCurIndex()) with "\t" filename;
   //   RelFilename=_RelativeToProject(filename,ProjectName);

   DestParent := 0;
   if (_projecttbIsProjectNode(DestTreeParentIndex)) {
      DestParent=_ProjectGet_FilesNode(DestHandle);
   } else if (_projecttbIsFolderNode(DestTreeParentIndex)) {
      DestParent = _projecttbTreeFolderNode(DestHandle, DestTreeParentIndex);
   } else {
      return;
   }
   int DestNode=DestParent;
   int DestNodeFlags=VSXMLCFG_ADD_AS_CHILD;
   error := 0;
   int DestFileToNode:[];
   _ProjectGet_FileToNodeHashTab(DestHandle,DestFileToNode);
   _str NewFilesList[];

   int DollarTable:[];
   _str ConfigurationNames[];
   _ProjectGet_ObjectFileInfo(DestHandle,DollarTable,ConfigurationNames);

   if (ptbCopyTreeFormWid >= 0 && _iswindow_valid(ptbCopyTreeFormWid) && gtbProjectsFormList._indexin(ptbCopyTreeFormWid)) {
      orig_wid := p_window_id;
      activate_window(ptbCopyTreeFormWid._proj_tooltab_tree);
      _CopyCutItems(TREE_ROOT_INDEX,DestTreeParentIndex,DestHandle,DestNode,DestNodeFlags,DestParent,DestParentFlags,-1,error,DestFileToNode,null,NewFilesList,null,DollarTable,ConfigurationNames);
      // reset tree bitmaps
      foreach (auto index => auto item in ptbCopyTree) {
         parse item with auto option' ' auto bm;
         _TreeGetInfo(index, auto showchildren);
         _TreeSetInfo(index, showchildren, (int)bm, (int)bm);
      }
      ptbCopyTree._makeempty();
      activate_window(orig_wid);
   }
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
int _OnUpdate_projecttbCut(CMDUI &cmdui,int target_wid,_str command,bool doPaste=false)
{
   if (target_wid && target_wid.p_object==OI_TREE_VIEW) {
      if (_workspace_filename=='') {
         return(MF_GRAYED);
      }
      if (target_wid._projecttbIsWorkspaceItemNode()) {
         return(MF_ENABLED);
      }
      ProjectName := target_wid._projecttbTreeGetCurProjectName();
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
      if (target_wid._projecttbIsFolderNode()) {
         if (target_wid._projecttbIsWildcardFolderNode() || _projecttbTreeFolderNode(handle) < 0) {
            return MF_GRAYED;
         }
      } else if (doPaste && target_wid._projecttbIsProjectNode(-1,false)) {
      } else {
         _str name, fullpath;
         parse caption with name "\t" fullpath;
         fullpath = _AbsoluteToWorkspace(fullpath);
         if (_ProjectGet_FileNode(handle, _RelativeToProject(fullpath)) < 0) {
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
static bool _isProjectTBCommandSupported(_str command)
{
   CMDUI cmdui;
   cmdui.menu_handle=0;
   cmdui.menu_pos=0;
   cmdui.inMenuBar=false;
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

static void _resetCopyTree(bool refreshTree=true)
{
   if (refreshTree && ptbCopyTreeFormWid >= 0 && _iswindow_valid(ptbCopyTreeFormWid) && 
       ptbCopyTreeFormWid.p_object == OI_FORM && gtbProjectsFormList._indexin(ptbCopyTreeFormWid)) {
      orig_wid := p_window_id;
      activate_window(ptbCopyTreeFormWid._proj_tooltab_tree);
      // reset tree bitmaps
      foreach (auto index => auto item in ptbCopyTree) {
         parse item with auto option' ' auto bm;
         _TreeGetInfo(index, auto showchildren);
         _TreeSetInfo(index, showchildren, (int)bm, (int)bm);
      }
      activate_window(orig_wid);
   }
   ptbCopyTreeFormWid = -1;
   ptbCopyTree._makeempty();
}

void projecttbTreeReset()
{
   _resetCopyTree(false);
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

   AddDeleteFileErrorDisplayed := false;
   AddDeleteFolderErrorDisplayed := false;
   if (ptbCopyTreeFormWid >= 0 && (ptbCopyTreeFormWid != p_active_form)) {
      _resetCopyTree();
   }

   showchildren := bm1 := bm2NOLONGERUSED := 0;
   index := 0;
   int info;
   for (ff:=1;;ff=0) {
      index=_TreeGetNextSelectedIndex(ff,info);
      if (index<0) break;
      if (_projecttbIsProjectFileNode(index)) {
         ProjectName := _projecttbTreeGetCurProjectName(index);
         if (_CanWriteFileSection(ProjectName)) {
            _TreeGetInfo(index,showchildren,bm1);
            _TreeSetInfo(index,showchildren,_pic_doc_d,_pic_doc_d);
            //_TreeSetUserInfo(index,option' 'bm1);
            ptbCopyTreeFormWid = p_active_form;
            ptbCopyTree:[index] = option' 'bm1;
         } else if (!AddDeleteFileErrorDisplayed) {
            AddDeleteFileErrorDisplayed=true;
            ProjectName=_projecttbTreeGetCurProjectName(index);
            _message_box(nls("You can't copy/delete files from the associated project '%s1'",ProjectName));
         }
      } else if (_projecttbIsFolderNode(index)) {
         ProjectName := _projecttbTreeGetCurProjectName(index);
         int handle=_ProjectHandle(ProjectName);
         _str AutoFolders=_ProjectGet_AutoFolders(handle);
         error := false;
         if (!strieq(AutoFolders,VPJ_AUTOFOLDERS_CUSTOMVIEW)) {
            error=true;
            if (!AddDeleteFolderErrorDisplayed) {
               AddDeleteFileErrorDisplayed=true;
               _message_box(nls("You can't copy/delete folders when in package or directory view."));
            }
         } else if (!_ProjectIs_AddDeleteFolderSupported(handle)) {
            error=true;
            if (!AddDeleteFolderErrorDisplayed) {
               AddDeleteFileErrorDisplayed=true;
               _message_box(nls("You can't delete folders from the associated project '%s1'",ProjectName));
            }
         }
         if (!error) {
            _TreeGetInfo(index,showchildren,bm1);
            //_TreeSetUserInfo(index,option' 'bm1);
            ptbCopyTreeFormWid = p_active_form;
            ptbCopyTree:[index] = option' 'bm1;
            _TreeSetInfo(index,showchildren,_pic_tfldclosdisabled,_pic_tfldopendisabled);
         }
      }
   }
}

int _OnUpdate_projecttbRename(CMDUI &cmdui,int target_wid,_str command,bool doPaste=false)
{
   if (target_wid && target_wid.p_object==OI_TREE_VIEW) {
      if (_workspace_filename=='') {
         return(MF_GRAYED);
      }
      index:=target_wid._TreeCurIndex();
      numSelected := target_wid._TreeGetNumSelectedItems();
      if (numSelected==1 && target_wid._projecttbIsProjectFileNode(index) && !target_wid._ParentNodeSelected(index)) {
         ProjectName := _projecttbTreeGetCurProjectName(index);
         if (_CanWriteFileSection(ProjectName)) {
            return(MF_ENABLED);
         }
      } else if (numSelected==1 && (target_wid._projecttbIsProjectNode(index) || target_wid._projecttbIsWorkspaceNode(index)) 
                 && !target_wid._ParentNodeSelected(index) &&  !_IsWorkspaceAssociated(_workspace_filename)) {
         return(MF_ENABLED);

      }
      return(MF_GRAYED);
   }
   return(MF_GRAYED);
}
_command void projecttbRename() name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   if (_workspace_filename=='') {
      return;
   }
   treeWid := p_window_id;
   assocWorkspace := _IsWorkspaceAssociated(_workspace_filename);
   index := 0;
   int info;
   for (ff:=1;;ff=0) {
      activate_window(treeWid); // just in case
      index=_TreeGetNextSelectedIndex(ff,info);
      if (index<0) {
         break;
      }
      workspace_ext := _get_extension(_workspace_filename,true);
      if ((_projecttbIsProjectFileNode(index) && !_ParentNodeSelected(index)) ||  
          _projecttbIsProjectNode(index) || 
          _projecttbIsWorkspaceNode(index) ) {
         ProjectName := _projecttbTreeGetCurProjectName(index);

         _str path;
         _str default_ext='';
         if (_projecttbIsProjectFileNode(index)) {
            if (!_CanWriteFileSection(ProjectName)) {
               return;
            }
            parse _TreeGetCaption(index) with "\t" auto fullPath;
            if (!assocWorkspace) {
               fullPath=stranslate(fullPath,'%%','%');
            }
            path = _AbsoluteToWorkspace(fullPath);
            buttons := "OK,Cancel:_cancel\tMove/Rename file '"path"' to:";
            status := show('-modal _textbox_form',
                          'Move/Rename File',
                          TB_RETRIEVE_INIT,                   // Flags
                          '',                                 // width
                          '',                                 // help item
                          buttons,                            // Button List
                          '',                                 // retrieve name not used for renames
                          '-bndf Directory/Filename:'path);
            if (status == '') return;
         } else if (_projecttbIsProjectNode(index)) {
            if (_IsWorkspaceAssociated(_workspace_filename)) {
               return;
            }
            default_ext=PRJ_FILE_EXT;
            path=GetProjectDisplayName(_projecttbTreeGetCurProjectName(index,true));
            buttons := "OK,Cancel:_cancel\tMove/Rename Project '"path"' to:";
            status := show('-modal _textbox_form',
                          'Move/Rename Project',
                          TB_RETRIEVE_INIT,                   // Flags
                          '',                                 // width
                          '',                                 // help item
                          buttons,                            // Button List
                          '',                                 // retrieve name not used for renames
                          '-bndf Directory/Filename:'path);
            if (status == '') return;
         } else {
            if (_IsWorkspaceAssociated(_workspace_filename)) {
               return;
            }
            default_ext=WORKSPACE_FILE_EXT;
            path=_workspace_filename;
            buttons := "OK,Cancel:_cancel\tMove/Rename Workspace '"path"' to:";
            status := show('-modal _textbox_form',
                          'Move/Rename Workspace',
                          TB_RETRIEVE_INIT,                   // Flags
                          '',                                 // width
                          '',                                 // help item
                          buttons,                            // Button List
                          '',                                 // retrieve name not used for renames
                          '-bndf Directory/Filename:'path);
            if (status == '') return;
         }

         // get our destination path
         destPath := strip(_param1, 'B', '"');
         if (def_unix_expansion) destPath = _unix_expansion(destPath);

         // is this even valid?
         if (destPath == '') {
            return;
         }

         // maybe add a file sep
         if (_last_char(destPath) != FILESEP && !_isRelative(destPath) && isdirectory(destPath)) {
            destPath :+= FILESEP;
         } else if (default_ext!='') {
            ext:=get_extension(destPath,true);
            if (!file_eq(ext,default_ext)) {
               strappend(destPath,default_ext);
            }
         }
         destDir := _strip_filename(destPath, 'N');
         destName := _strip_filename(destPath, 'P');

         haveDir := (destDir != '');
         haveName := (destName != '');

         // compile the destination path based on what we have
         destination := '';
         if (haveDir && haveName) {
            // new path, new filename
            destination = destPath;
         } else if (!haveDir && haveName) {
            // same path, new filename
            destination = _strip_filename(path, 'N' ) :+ destName;
         } else if (haveDir && !haveName) {
            // new dir, same filename
            destination = destDir;
            _maybe_append_filesep(destination);
            destination :+= _strip_filename(path,'P');
         }
         _rename_file(path,destination);
         //say('_projecttbIsProjectFileNode');
      } else if (_projecttbIsFolderNode(index) && !_ParentNodeSelected(index)) {
         //say('_projecttbIsFolderNode');
         //projecttbFolderProperties();
      } else if (_projecttbIsDependencyNode(index)) {
         //say('_projecttbIsDependencyNode');
      }
      break;
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
   ProjectName := _projecttbTreeGetCurProjectName();

   int handle=_ProjectHandle(ProjectName);
   if (_ProjectIs_SupportedXMLVariation(handle)) {
      handle=_ProjectGet_AssociatedHandle(handle);
   }
   XMLVARIATIONS xmlv;
   _ProjectGet_XMLVariations(handle,xmlv);

   // Must be at folder.
   // Add folder inside this folder
   typeless array[]; array._makeempty();
   int Node = _projecttbTreeFolderNode(handle);
   _xmlcfg_find_simple_array(handle,xmlv.vpjtag_folder,array,_xmlcfg_get_parent(handle,Node));

   int i;
   for (i=0;i<array._length();++i) {
      if (array[i] == Node) {
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
   toolbarUpdateWorkspaceList(p_active_form);
}
_command void projecttbDependencies() name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   ProjectName := _projecttbTreeGetCurProjectName();

   workspace_dependencies(ProjectName);
}
int _OnUpdate_projecttbDependencies(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveBuild()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   if (_project_name=='') {
      return(MF_GRAYED);
   }
   return(MF_ENABLED);
}

int _OnUpdate_projecttbAutoFolders(CMDUI &cmdui,int target_wid,_str command)
{
   args := "";
   parse command with . args;
   if (target_wid && target_wid.p_object==OI_TREE_VIEW) {
      if (_workspace_filename=='') {
         return(MF_GRAYED);
      }
      ProjectName := target_wid._projecttbTreeGetCurProjectName();

     if (_IsJBuilderAssociatedWorkspace(_workspace_filename)) {
         // only support custom view for jbuilder
         if (!strieq(args, VPJ_AUTOFOLDERS_CUSTOMVIEW)) {
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
   ProjectName := _projecttbTreeGetCurProjectName();

   int handle=_ProjectHandle(ProjectName);

   _str AutoFolders=_ProjectGet_AutoFolders(handle);
   if (strieq(AutoFolders,VPJ_AUTOFOLDERS_CUSTOMVIEW) && !strieq(newAutoFolders,VPJ_AUTOFOLDERS_CUSTOMVIEW) ) {
      int result=_message_box("Warning:  This will reorganize all files including those you have manually placed in folders.  Switching back to Custom View may not restore your file view organization.\n\nThis does not modify the location of your source files on disk.\n\nContinue?",'',MB_YESNO|MB_ICONEXCLAMATION);
      if (result!=IDYES) {
         return;
      }
   }
   _ProjectSet_AutoFolders(handle,newAutoFolders);
   _ProjectSave(handle);
   _WorkspaceCache_Update();
   toolbarUpdateWorkspaceList(-1, true);
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
      /*
      int Node=_ProjectGet_FolderNode(gProjectHandle,text);
      if (Node>=0) {
         _message_box('A folder by this name already exists');
         return(1);
      } 
      */
      return(0);
   }
   int ExtToNodeHashTab:[];
   _ProjectGet_ExtToNode(gProjectHandle,ExtToNodeHashTab,gSkipFolderName);
   if (text=='' || text=='*.*' || text=='*') {
      return(0);
#if 0
      int Node=ExtToNodeHashTab:[''];
      if (Node!=_ProjectGet_FilesNode(gProjectHandle)) {
         FolderName=_xmlcfg_get_attribute(gProjectHandle,ExtToNodeHashTab:[''],'Name');
         _message_box(nls("The '%s' folder already has this filter",FolderName));
         return(1);
      }
      return(0);
#endif
   }
   value := "";
   for (;;) {
      parse text with value ';' text;
      if (value=='' && text=='') {
         break;
      }
      ext := lowcase(_get_extension(value));
      if (substr(value,1,2)!='*.' || ext=='') {
         _message_box("Filters must start with '*.' and contain an extension");
         return(1);
      }
      if (ExtToNodeHashTab._indexin(ext)) {
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

      index := _TreeCurIndex();
      // check for a folder node under a workspace node
      _str wksp_ext=_get_extension(_workspace_filename,true);

      // we do not allow this for visual studio workspaces
      if (_file_eq(wksp_ext,VISUAL_STUDIO_SOLUTION_EXT)) {
         // we automatically allow folders to be added to workspaces or workspace folders
         if (_projecttbIsWorkspaceNode(index) || _projecttbIsWorkspaceFolderNode(index)) {
            return MF_ENABLED; 
         } else {
            if (CheckFolderMoveUpDown) {
               return MF_GRAYED; 
            }
            // supported visual studio types
            ProjectName := target_wid._projecttbTreeGetCurProjectName();
            if (_ProjectIs_vcxproj(_ProjectHandle(ProjectName))) {
               if (command:=='projecttbFolderProperties') {
                  return MF_GRAYED; 
               }
               return MF_ENABLED; 
            }
            return MF_GRAYED;
         }
      }

      if (_projecttbIsWorkspaceNode(index)) {
         return(MF_GRAYED);
      }

      // get a handle to our project
      ProjectName := target_wid._projecttbTreeGetCurProjectName();
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
      if (_projecttbIsWildcardFolderNode() || 
          (target_wid._projecttbIsFolderNode() && _projecttbTreeFolderNode(handle) < 0)) {
         return MF_GRAYED;
      }

      // what is our view?
      _str AutoFolders=_ProjectGet_AutoFolders(handle);
      // we only allow this in custom view
      if (strieq(AutoFolders,VPJ_AUTOFOLDERS_CUSTOMVIEW)) {
         folderName := _TreeGetCaption(index);
         if (CheckFolderMoveUpDown) {
            int Node = _projecttbTreeFolderNode(handle,index);

            // if folder not found, it was added by a wildcard so disable
            // most of the operations on the menu
            if (Node < 0) {
               return MF_GRAYED;
            } else {
               if (def_project_show_sorted_folders) {
                  return MF_GRAYED;
               }

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
   projectName := _projecttbTreeGetCurProjectName();
   gProjectHandle=_ProjectHandle(projectName);

   index := _TreeCurIndex();
   // check for a folder node under a workspace node
   _str wksp_ext=_get_extension(_workspace_filename,true);
   // handle cases for Visual Studio projects
   if (_file_eq(wksp_ext,VISUAL_STUDIO_SOLUTION_EXT)) {
      // only do this is it's a workspace or workspace folder node
      if (_projecttbIsWorkspaceNode(index) || _projecttbIsWorkspaceFolderNode(index)) {
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

   gSkipFolderName='';
   typeless status=show('-modal _textbox_form',
                        'Add Folder',
                        0,  //TB_RETRIEVE_INIT, //Flags
                        '', //width
                        'Folder View', //help item
                        '', // "OK,Apply to &All,Cancel:_cancel\tCopy file '"SourceFilename"' to",//Button List
                        '', //retrieve name
                        '-e projecttbCheck:F Folder Name:',
                        '-e projecttbCheck:* Filters (ex. *.cpp;*.h):'
                       );

   // did they cancel out?
   if (status=='') {
      return;
   }
   int Node= -1;
   if (_projecttbIsProjectNode()) {
      //Node=_xmlcfg_set_path2(gProjectHandle,xmlv.vpjx_files,xmlv.vpjtag_folder,xmlv.vpjattr_folderName,_param1);

   } else if (_projecttbIsWorkspaceNode()) {
      // not supported
      _message_box("Not supported");
      return;

   } else {
      // Must be at folder.
      // Add folder inside this folder
      Node = _projecttbTreeFolderNode(gProjectHandle,index);
   }
   _ProjectAdd_Folder(gProjectHandle,  _param1, _param2, Node);

   _ProjectSave(gProjectHandle);
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
   ProjectName := _projecttbTreeGetCurProjectName();
   old_project_name := _project_name;
   workspace_set_active(ProjectName,false,false,false);

   handle := _ProjectHandle(ProjectName);
   // see if we selected a folder in directory structure
   curPath := getcwd();
   newPath := _projecttbTreeGetCurSourcePath();
   if (newPath != '') {
      pwd(newPath);
   }

   option := 'f2';
   autoFolders := _ProjectGet_AutoFolders(handle);
   gProjectHandle=_ProjectHandle(ProjectName);
   bool new_file_could_be_part_of_wildcard=false;
   /* 
      It would best to list all the wildcards in
      the project and see if this new file is part
      of an existing wildcard.
   */
   if (!strieq(autoFolders, VPJ_AUTOFOLDERS_DIRECTORYVIEW) && 
       _projecttbIsFolderNode()) {
      option = 'f3';
      if (_IsWorkspaceAssociated(_workspace_filename)) {
         // wildcard project or add to specific folder
      } else {
         // IF this is a wildcard folder (no guid)
         if (_projecttbTreeFolderNode(gProjectHandle)<0) {
            new_file_could_be_part_of_wildcard=true;
         }
         option= 'f3';
      }
   }

   bool is_assoc_wildcard_project=false;

   if (_IsWorkspaceAssociated(_workspace_filename)) {
      _str AssociatedFile,AssociatedFileType;
      _GetAssociatedProjectInfo(ProjectName,AssociatedFile,AssociatedFileType);
      if (_IsMSBuildProj(_workspace_filename, AssociatedFileType)) {
         csproj_handle := _xmlcfg_open(AssociatedFile, auto xcstatus, VSXMLCFG_OPEN_REFCOUNT|VSXMLCFG_OPEN_ADD_PCDATA);
         is_assoc_wildcard_project=_csproj2005Get_AutoAddWildcards(csproj_handle);
         if (is_assoc_wildcard_project) {
            option= 'f3';
         }
         _xmlcfg_close(csproj_handle);
      }
   }


   // Pass 's' option.
   // Must save files that will be added to the project.
   // Visual Studio requires this too.

   // show the new file dialog
   typeless result=show('-modal -mdi _workspace_new_form','s'option);

   // go back to our old directory
   if (newPath != '') {
      pwd(curPath);
   }

   // set our old project back again
   workspace_set_active(old_project_name,false,false,false);

   // nothing to do here
   if (result=='' || _param1=='') {
      return;
   }
   // IF project_add_file was called
   if (option=='f2') {
      // Nothing to do
      return;
   }
   if (option :== 'f3') {
      if (is_assoc_wildcard_project) {
         /* If a new file is added under the project directory,
            assume it will be picked up by a wildcard. Otherwise,
            Assume that this new file must explicitly added.
         */
         if (beginsWith(_param1,_strip_filename(ProjectName,'n'))) {
            _str NewFilesList[];NewFilesList[0]=_param1;
            _AddAndRemoveFilesFromVC(NewFilesList,null,ProjectName);
            _WorkspaceCache_Update();
            toolbarUpdateWorkspaceList();
            // regenerate the makefile
            //_maybeGenerateMakefile(ProjectName);
            return;
         }
         // This doesn't seem to add the file to the project.
         // Will need to improve this later.
         project_add_file(_param1,false,ProjectName);
         return;
      } else if (_IsWorkspaceAssociated(_workspace_filename)) {
         // Add to this specific folder
      } else if (new_file_could_be_part_of_wildcard) {
         /* This could a lot better.
            For now, assume new file is part of a wildcard.
          
            It would best to list all the wildcards in
            the project and see if this new file is part
            of an existing wildcard.
         */

         _str NewFilesList[];NewFilesList[0]=_param1;
         _AddAndRemoveFilesFromVC(NewFilesList,null,ProjectName);
         _WorkspaceCache_Update();
         toolbarUpdateWorkspaceList();
         // regenerate the makefile
         _maybeGenerateMakefile(ProjectName);

         call_list("_prjupdate_");
         return;
      } else {
         // Add this new file to the folder specified
      }
   }

   // add the files then
   _projecttbAddFiles2(_param1, ProjectName);
}
int _OnUpdate_projecttbAddFiles(CMDUI &cmdui,int target_wid,_str command,bool doNewFile=false)
{
   // make sure we have a tree, please
   if (target_wid && target_wid.p_object==OI_TREE_VIEW) {

      index := target_wid._TreeCurIndex();
      // is add/delete disabled in this workspace?
      if (_workspace_filename=='' ||
          (_IsWorkspaceAssociated(_workspace_filename) && !_IsAddDeleteSupportedWorkspaceFilename(_workspace_filename))) {
         return(MF_GRAYED);
      }

      // is this a workspace item node?
      if (target_wid._projecttbIsWorkspaceItemNode()) {
         return(MF_ENABLED);
      }

      if (command:=='projecttbAddTree' && _IsWorkspaceAssociated(_workspace_filename) &&
          target_wid._projecttbIsProjectNode(index,false)) {
         return(MF_GRAYED);
      }

      // get a handle to this project
      ProjectName := target_wid._projecttbTreeGetCurProjectName();
      handle := _ProjectHandle(ProjectName);

      if (_IsWorkspaceAssociated(_workspace_filename)) {
         if (_IsDotNetCoreSdkProject(_ProjectGet_AssociatedHandle(handle))) {
            if (command:=='projecttbAddNewFile') {
               return(MF_ENABLED);
            }
            return(MF_GRAYED);
         }
      }

      if (_ProjectIs_SupportedXMLVariation(handle)) {
         handle=_ProjectGet_AssociatedHandle(handle);

      } else if (_ProjectIs_vcxproj(handle)) {
         if (command:=='projecttbAddTree') {
            return(MF_GRAYED);
         }
         return(MF_ENABLED);
      }

      if (target_wid._projecttbIsWildcardFolderNode(index)) {
         return(MF_GRAYED);
      }

      _str AutoFolders=_ProjectGet_AutoFolders(handle);
      if (strieq(AutoFolders,VPJ_AUTOFOLDERS_CUSTOMVIEW)) {
         if (target_wid._projecttbIsProjectNode(index)) {
            return(MF_ENABLED);
         }
         if (target_wid._projecttbIsFolderNode(index)) {
            if (command:=='projecttbAddNewFile') {
               return(MF_ENABLED);
            } else if (target_wid._projecttbTreeFolderNode(handle, index) < 0) {
               return(MF_GRAYED);
            }
         }
         return(MF_ENABLED);

      } else if (strieq(AutoFolders,VPJ_AUTOFOLDERS_DIRECTORYVIEW)) {
         if (target_wid._projecttbIsProjectNode(index) || target_wid._projecttbIsFolderNode(index)) {
            return(MF_ENABLED);
         }

      } else if (strieq(AutoFolders, VPJ_AUTOFOLDERS_PACKAGEVIEW)/* && doNewFilecommand :== 'projecttbAddNewFile'*/) {
         ptype := _ProjectGet_Type(handle,GetCurrentConfigName(ProjectName));
         if (strieq(ptype,'java') || strieq(ptype, 'groovy') || strieq(ptype, 'scala')) {
            return(MF_ENABLED);
         }
      }
   }
   return(MF_GRAYED);
}

static void _projecttbAddFiles2(_str newfilename=null,_str ProjectName="",_str FolderName=null)
{
   // get the current project name if we don't already have it
   if (ProjectName=="") {
      ProjectName = _projecttbTreeGetCurProjectName();
   }

   // see if we selected a folder in directory structure
   newPath := _projecttbTreeGetCurSourcePath();

   handle := _ProjectHandle(ProjectName);
   AssocProjectName := _ProjectGet_AssociatedFile(handle);
   AutoFolders := _ProjectGet_AutoFolders(handle);
   if (_ProjectIs_SupportedXMLVariation(handle)) {
      handle = _ProjectGet_AssociatedHandle(handle);

   } else if (_ProjectIs_vcxproj(handle)) {
      if (newfilename==null) {
         // init the callback so it clears its cache
         projectPropertiesAddFilesCallback("", ProjectName);

         result := _OpenDialog("-modal",
                               'Add Source Files',// title
                               _last_wildcards,// Initial wildcards
                               def_file_types:+',':+EXTRA_FILE_FILTERS,
                               OFN_NOCHANGEDIR|OFN_FILEMUSTEXIST|OFN_SET_LAST_WILDCARDS,
                               "", // Default extension
                               ""/*wildcards*/, // Initial filename
                               newPath,// Initial directory
                               "",
                               "",
                               getProjectPropertiesAddFilesCallback()); // include item callback

         // cleanup after the callback so it clears its cache
         projectPropertiesAddFilesCallback("");
         if (result=="") return;
         newfilename = result;
      }

      InsertVCXProjFile(_AbsoluteToProject(AssocProjectName, ProjectName), newfilename);
      _WorkspaceCache_Update();
      toolbarUpdateWorkspaceList();
      _maybeGenerateMakefile(ProjectName);
      call_list("_prjupdate_");
      return;

   } else if (_IsWorkspaceAssociated(_workspace_filename)) {
      if (newfilename==null) {
         // init the callback so it clears its cache
         projectPropertiesAddFilesCallback("", ProjectName);

         result := _OpenDialog("-modal",
                               'Add Source Files',// title
                               _last_wildcards,// Initial wildcards
                               def_file_types:+',':+EXTRA_FILE_FILTERS,
                               OFN_NOCHANGEDIR|OFN_FILEMUSTEXIST|OFN_SET_LAST_WILDCARDS,
                               "", // Default extension
                               ""/*wildcards*/, // Initial filename
                               newPath,// Initial directory
                               "",
                               "",
                               getProjectPropertiesAddFilesCallback()); // include item callback

         // cleanup after the callback so it clears its cache
         projectPropertiesAddFilesCallback("");
         if (result=="") return;
         newfilename = result;
      }
      // Must adding a single newfile
      _str old_project_name=_project_name;
      workspace_set_active(ProjectName,false,false,false);
      project_add_file(newfilename);
      workspace_set_active(old_project_name,false,false,false);
      _WorkspaceCache_Update();
      toolbarUpdateWorkspaceList();
      return;
   }

   XMLVARIATIONS xmlv;
   _ProjectGet_XMLVariations(handle,xmlv);

   orig_view_id := p_window_id;

   FolderNode := 0;
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
         FolderNode = _ProjectGet_FilesNode(handle);
      } else {
         if (strieq(AutoFolders,VPJ_AUTOFOLDERS_CUSTOMVIEW)) {
            FolderNode = _projecttbTreeFolderNode(handle);
            if (FolderNode<0) {
               _message_box(nls("Folder '%s' not found in project",FolderName));
               return;
            }
         } else {
            FolderNode = _ProjectGet_FilesNode(handle);
         }
      }
   }

   filelist_view_id := 0;
   if (newfilename==null) {
      // init the callback so it clears its cache
      projectPropertiesAddFilesCallback("", ProjectName);

      result := _OpenDialog("-modal",
                            'Add Source Files',// title
                            _last_wildcards,// Initial wildcards
                            def_file_types:+',':+EXTRA_FILE_FILTERS,
                            OFN_NOCHANGEDIR|OFN_FILEMUSTEXIST|OFN_ALLOWMULTISELECT|OFN_SET_LAST_WILDCARDS,
                            "", // Default extension
                            ""/*wildcards*/, // Initial filename
                            newPath,// Initial directory
                            "",
                            "",
                            getProjectPropertiesAddFilesCallback()); // include item callback

      // cleanup after the callback so it clears its cache
      projectPropertiesAddFilesCallback("");

      //chdir(olddir,1);
      if (result=="") return;
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

   filename := "";
   _str NewFilesList[];
   p_line=0;
   path := _strip_filename(ProjectName,'N');
   useVCPPFiles := false;
   assocProjectFile := (AssocProjectName != '');
   _str ext = _get_extension(AssocProjectName, true);
   if (_file_eq(ext, VISUAL_STUDIO_VCPP_PROJECT_EXT) || 
       _file_eq(ext, VISUAL_STUDIO_INTEL_CPP_PROJECT_EXT)) {
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
      RelFilename := relative(filename,path);
      if (useVCPPFiles) {
         RelFilename = ConvertToVCPPRelFilename(RelFilename, _strip_filename(useVCPPFiles,'N'));
      }
      if (!assocProjectFile) {
         RelFilename = stranslate(RelFilename, '%%', '%');
      }
      int *pnode=FileToNode._indexin(_file_case(RelFilename));
      if (!pnode) {
         Node=_xmlcfg_add(handle,Node,xmlv.vpjtag_f,(useVCPPFiles) ? VSXMLCFG_NODE_ELEMENT_START : VSXMLCFG_NODE_ELEMENT_START_END,flags);
         flags=0;
         _xmlcfg_set_attribute(handle,Node,xmlv.vpjattr_n,_NormalizeFile(RelFilename,xmlv.doNormalizeFile));

         // if this is an ant build file, set the Type attribute
         if (_IsAntBuildFile(_AbsoluteToProject(RelFilename))) {
            _xmlcfg_set_attribute(handle, Node, "Type", "Ant");
            // if this is an ant build file, set the Type attribute
         } else if (_IsNAntBuildFile(_AbsoluteToProject(RelFilename))) {
            _xmlcfg_set_attribute(handle, Node, "Type", "NAnt");
            // if this is a makefile, set the Type attribute
         } else if (_IsMakefile(_AbsoluteToProject(RelFilename))) {
            _xmlcfg_set_attribute(handle, Node, "Type", "Makefile");
         }

         _ProjectSet_ObjectFileInfo(handle,DollarTable,ConfigurationNames,Node,RelFilename);
         NewFilesList :+= filename;
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

      // init the callback so it clears its cache
      ProjectName := _projecttbTreeGetCurProjectName();
      projectPropertiesAddFilesCallback("", ProjectName);

      // see if we selected a folder in directory structure
      newPath := _projecttbTreeGetCurSourcePath();

      result := _OpenDialog("-modal",
                            'Add Source Files',// title
                            _last_wildcards,// Initial wildcards
                            def_file_types:+',':+EXTRA_FILE_FILTERS,
                            OFN_NOCHANGEDIR|OFN_FILEMUSTEXIST|OFN_ALLOWMULTISELECT,
                            "", // Default extension
                            ""/*wildcards*/, // Initial filename
                            newPath,// Initial directory
                            "", 
                            "", 
                            getProjectPropertiesAddFilesCallback()); // include item callback

      // cleanup after the callback so it clears its cache
      projectPropertiesAddFilesCallback("");
      if (result:!="") {
         workspace_ext := _get_extension(_workspace_filename,true);
         if (_file_eq(workspace_ext,VISUAL_STUDIO_SOLUTION_EXT)) {
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
   return(add_tree_allowed(target_wid) || add_wildcard_allowed()) ? MF_ENABLED : MF_GRAYED;
}

static bool add_tree_allowed(int targetWid)
{
   return(_OnUpdate_projecttbAddFiles(null, targetWid, 'projecttbAddTree') == MF_ENABLED);
}

static bool add_wildcard_allowed()
{
   // well, we have to have a workspace, and it needs to be one of ours
   if (_workspace_filename=='' || _IsWorkspaceAssociated(_workspace_filename)) {
      return false;
   }

   /*
   // can't add wildcards to projects...
   if (!_projecttbIsProjectNode(_TreeCurIndex(),false)) {
      return false;
   }*/

   ProjectName := _projecttbTreeGetCurProjectName();
   int handle = _ProjectHandle(ProjectName);
   _str AutoFolders=_ProjectGet_AutoFolders(handle);

   if (_ProjectIs_SupportedXMLVariation(handle)) {
      handle=_ProjectGet_AssociatedHandle(handle);
   }

   if (_projecttbIsWildcardFolderNode()) {
      return false;
   }

   if (strieq(AutoFolders,VPJ_AUTOFOLDERS_CUSTOMVIEW)) {
      if (_projecttbIsFolderNode() && _projecttbTreeFolderNode(handle) < 0) {
         return false;
      }
      return true;

   } else if (strieq(AutoFolders,VPJ_AUTOFOLDERS_DIRECTORYVIEW)) {
      if (_projecttbIsProjectNode() || _projecttbIsFolderNode()) {
         return true;
      }

   } else if (strieq(AutoFolders, VPJ_AUTOFOLDERS_PACKAGEVIEW)) {
      ptype := _ProjectGet_Type(handle,GetCurrentConfigName(ProjectName));
      if (strieq(ptype,'java') || strieq(ptype, 'groovy') || strieq(ptype, 'scala')) {
         return true;
      }
   }

   // just forget it
   return false;
}

static bool add_custom_folders()
{
   // well, we have to have a workspace, and it needs to be one of ours
   if (_workspace_filename=='' || _IsWorkspaceAssociated(_workspace_filename)) {
      return false;
   }

   ProjectName := _projecttbTreeGetCurProjectName();
   int handle = _ProjectHandle(ProjectName);

   // if folder not found, it was added by a wildcard so disable
   // most of the operations on the menu
   _str folderName = _TreeGetCaption(_TreeCurIndex());
   if (_projecttbIsWildcardFolderNode()) {
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
   addCustomFolders := add_custom_folders();
   // we allow them to add tree on a workspace node
   if (_projecttbIsWorkspaceItemNode()) {
      typeless result=show('-modal -xy _project_add_tree_or_wildcard_form',
                           'Add Tree',
                           '',          // filespec
                           true,        // attempt retrieval
                           true,         // show exclude filespec
                           '',           // project file name
                           showWildcard, // show wildcard option
                           true,         // allow ant paths
                           false);        

      if (result== "") {
         return;
      }
// _param1 - trees to add (array of paths)
// _param2 - recursive?
// _param3 - follow symlinks?
// _param4 - exclude filespecs (array of filespecs)
// _param5 - add as wildcard
      _str workspace_ext=_get_extension(_workspace_filename,true);
      if (_file_eq(workspace_ext,VISUAL_STUDIO_SOLUTION_EXT)) {
         _str optimize_option=(_param3)?'':' +o';
         _str recursive_option=(_param2)?'+t':'-t';
         AddTreeSolutionItems(_param1, _param6, recursive_option:+optimize_option,_param4);
      }

      _param1._makeempty();
      _param4._makeempty();
      return;
   }

   // otherwise, we have a project node

   orig_view_id := p_window_id;
   ProjectName := _projecttbTreeGetCurProjectName();

   int handle=_ProjectHandle(ProjectName);
   if (_ProjectIs_SupportedXMLVariation(handle)) {
      handle=_ProjectGet_AssociatedHandle(handle);
   }

   // figure out what our default wildcards will be
   extension := "";
   wildcards := "";
   attempt_retrieval := true;
   if (_haveContextTagging()) {
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
   newPath := _projecttbTreeGetCurSourcePath();
   if (newPath != '') {
      pwd(newPath);
   }

   int fid;
   fid= p_active_form;
   typeless result=show('-modal -xy _project_add_tree_or_wildcard_form',
                        'Add Tree',
                        wildcards,    // filespec
                        true,        // attempt retrieval
                        true,         // show exclude filespec
                        ProjectName,  // project file name
                        showWildcard, // show wildcard option
                        true,         // allow ant paths
                        addCustomFolders);
   if (result== "") {
      return;
   }

   // go back to our old directory
   if (newPath != '') {
      pwd(curPath);
   }
// _param1 - base path
// _param2 - recursive?
// _param3 - follow symlinks?
// _param4 - exclude filespecs (array of filespecs)
// _param5 - add as wildcard
// _param6 - include filespecs (array of include filespecs)
// _param7 - custom folders
   if (_param5) {
      int FolderNode = _projecttbTreeFolderNode(handle);

      if (_param8) {
         _projecttbAddDirectoryToProject(false,ProjectName, handle, FolderNode, _param1, _param6, _param4, _param2, _param3, _param7);
      } else {
         _projecttbAddWildcardsToProject(false, ProjectName, handle, FolderNode, _param1, _param6, _param4, _param2, _param3, _param7);
      }
   } else {
      int FolderNode=_projecttbTreeFolderNode(handle);

      // Find all files in tree:
      mou_hour_glass(true);
      message('SlickEdit is finding all files in tree');

      _projecttbAddTreeToProject(false,FolderNode,ProjectName, handle, _param1, _param6, _param4, _param2, _param3, _param7);
   }

   _param1._makeempty();
   _param4._makeempty();

   _WorkspaceCache_Update();
   toolbarUpdateWorkspaceList(-1, true);

   // regenerate the makefile
   _maybeGenerateMakefile(ProjectName);

   mou_hour_glass(false);
   clear_message();
}
void _project_before_modify_files(_str ProjectName,int handle, int &OrigProjectFileList) {
   GetProjectFiles(ProjectName, OrigProjectFileList,'',null,'',true,true,false,handle);
}
void _project_after_modify_files(_str ProjectName,int handle,int OrigProjectFileList,bool keep_OrigProjectFileList=false) {
   activate_window(OrigProjectFileList);
   sort_buffer('-fc');
   _remove_duplicates(_fpos_case);

   //_showbuf(new_all_files_view_id);
   new_all_files_view_id := 0;
   GetProjectFiles(ProjectName, new_all_files_view_id,'',null,'',true,true,false,handle);
   activate_window(new_all_files_view_id);
   sort_buffer('-fc');
   _remove_duplicates(_fpos_case);


   // Get the tag file for this project
   // Note that the project might not have a tag file.
   project_tagfile := project_tags_filename_only(ProjectName);

   _str NewFilesList[];
   _str DeletedFilesList[];
   _DiffFileListsFromViews(new_all_files_view_id, OrigProjectFileList, NewFilesList, DeletedFilesList);
   _ConvertViewToAbsolute(new_all_files_view_id, _strip_filename(ProjectName, 'n'));

   database_flags := (def_references_options & VSREF_NO_WORKSPACE_REFS)? 0:VS_DBFLAG_occurrences;
   useThread := _is_background_tagging_enabled(AUTOTAG_WORKSPACE_NO_THREADS);
   if (useThread && _haveContextTagging()) {

      alertId := _GetBuildingTagFileAlertGroupId(project_tagfile);
      _ActivateAlert(ALERT_GRP_BACKGROUND_ALERTS, alertId, 'Updating project tag file (':+_strip_filename(project_tagfile,'p'):+')', '', 1);
      call_list("_LoadBackgroundTaggingSettings");
      rebuildFlags := VS_TAG_REBUILD_CHECK_DATES;
      if (database_flags == VS_DBFLAG_occurrences) {
         rebuildFlags |= VS_TAG_REBUILD_DO_REFS;
      }

      if (project_tagfile != "") {
         tag_build_tag_file_from_view(project_tagfile,
                                      rebuildFlags,
                                      new_all_files_view_id);
         if (def_tagging_logging) {
            loggingMessage := nls("Starting background tag file update for '%s1' because a file list has changed", project_tagfile);
            dsay("BACKGROUND TAGGING(":+_time('M'):+"): ":+loggingMessage, TAGGING_LOG);
         }
         if (DeletedFilesList._length() > 0) {
            tag_remove_files_from_tag_file_in_array(project_tagfile, rebuildFlags, DeletedFilesList);
            if (def_tagging_logging) {
               loggingMessage := nls("Starting background tag file update for '%s1' because files were deleted from file list", project_tagfile);
               dsay("BACKGROUND TAGGING(":+_time('M'):+"): ":+loggingMessage, TAGGING_LOG);
            }
         }
      }

   } else if (project_tagfile != "") {
      _TagUpdateFromViews(project_tagfile,new_all_files_view_id,
                          OrigProjectFileList,false,ProjectName,
                          NewFilesList,DeletedFilesList,
                          database_flags,useThread);
   }

   _delete_temp_view(new_all_files_view_id);
   if (!keep_OrigProjectFileList) {
      _delete_temp_view(OrigProjectFileList);
   }
   p_window_id._AddAndRemoveFilesFromVC(NewFilesList,DeletedFilesList);
}

void _projecttbAddDirectoryToProject(bool onlyUpdateProjectFile, _str ProjectName, int handle, int FolderNode, _str basePath, _str (&includeList)[], _str (&excludesList)[], bool recursive, bool followSymlinks, bool showFolders)
{
   bool custom_view = strieq(_ProjectGet_AutoFolders(handle),VPJ_AUTOFOLDERS_CUSTOMVIEW);
   int FilesNode = _ProjectGet_FilesNode(handle, true);
   int ParentNode = (custom_view) ? FolderNode : FilesNode;
   if (ParentNode < 0) {
      ParentNode = FilesNode;
   }

   //includes := join(includeList, ';');
   excludes := join(excludesList, ';');

   _str RelPath = _RelativeToProject(basePath, ProjectName); 
   _maybe_append_filesep(RelPath);

   // check for dupes
   status := 0;
   foreach (auto f in includeList) {
      RelFilename := _NormalizeFile(RelPath:+f);
      if (_ProjectGet_FileNode(handle, RelFilename) >= 0) {
         result := _message_box(nls("'%s' already exists in project. Overwrite and Continue?", f),'', MB_YESNO, IDNO);
         if (result != IDYES) {
            status = -1; break;
         }
      }
   }
   if (status) {
      return;
   }

   int OrigProjectFileList;
   if (!onlyUpdateProjectFile) {
      _project_before_modify_files(ProjectName,handle,OrigProjectFileList);
   }
   foreach (f in includeList) {
      RelFilename := _NormalizeFile(RelPath:+f);
      Node := _xmlcfg_add(handle, ParentNode, VPJTAG_F, VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_set_attribute(handle, Node, 'N', RelFilename);
      _xmlcfg_set_attribute(handle, Node, 'Recurse', recursive);
      _xmlcfg_set_attribute(handle, Node, 'Excludes', _NormalizeFile(excludes));
      if (!showFolders) {
         _xmlcfg_set_attribute(handle, Node, 'L', '1');
      }
      _xmlcfg_set_attribute(handle, Node, 'D', '1');
   }
   _ProjectSave(handle);
   if (!onlyUpdateProjectFile) {
      _project_after_modify_files(ProjectName,handle,OrigProjectFileList);
   }
}

void _projecttbAddWildcardsToProject(bool onlyUpdateProjectFile, _str ProjectName, int handle, int FolderNode, _str basePath, _str (&includeList)[], _str (&excludesList)[], bool recursive, bool followSymlinks, bool showFolders)
{
   // put the excludes in string form
   excludes := join(excludesList, ';');

   int OrigProjectFileList;
   if (!onlyUpdateProjectFile) {
      _project_before_modify_files(ProjectName,handle,OrigProjectFileList);
   }

   bool custom_view = strieq(_ProjectGet_AutoFolders(handle),VPJ_AUTOFOLDERS_CUSTOMVIEW);

   int ExtToNodeHashTab:[];
   if (FolderNode < 0) {
      _ProjectGet_ExtToNode(handle,ExtToNodeHashTab);
   }

   // go through each node in our file to add it
   for (i := 0; i < includeList._length(); i++) {
      _str RelFilename=_RelativeToProject(absolute(includeList[i],basePath), ProjectName);
      // maybe it's already in there?
      int Node=_ProjectGet_WildcardNode(handle, RelFilename);
      if (Node < 0) {
         int ParentNode = (custom_view) ? FolderNode : Node;
         if (ParentNode < 0) {
            ext := lowcase(_get_extension(RelFilename));
            int *pfolder = ExtToNodeHashTab._indexin(ext);
            if (!pfolder) {
               pfolder = ExtToNodeHashTab._indexin('');
            }
            ParentNode = *pfolder;
         }
         Node=_xmlcfg_add(handle, ParentNode, VPJTAG_F, VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
         _xmlcfg_set_attribute(handle,Node,'N',_NormalizeFile(RelFilename));
         _xmlcfg_set_attribute(handle,Node,'Recurse', recursive);
         _xmlcfg_set_attribute(handle,Node,'Excludes', _NormalizeFile(excludes));
         if (!showFolders) {
            _xmlcfg_set_attribute(handle, Node, 'L', '1');
         }
      }
   }
   _ProjectSave(handle);
   if (!onlyUpdateProjectFile) {
      _project_after_modify_files(ProjectName,handle,OrigProjectFileList);
   }
}

void _projecttbAddTreeToProject(bool onlyUpdateProjectFile,int FolderNode, _str ProjectName, int handle, _str basePath, _str (&includeList)[], _str (&excludeList)[], bool recursive, bool followSymlinks, bool showFolders)
{
   XMLVARIATIONS xmlv;
   _ProjectGet_XMLVariations(handle, xmlv);

   recursiveString := recursive ? '+t' : '-t';
   optimizeString := followSymlinks ? '' : '+o';

   filelist_view_id := 0;
   orig_view_id := _create_temp_view(filelist_view_id);
   p_window_id = filelist_view_id;

   // put all the files into one string
   all_files := _maybe_quote_filename(basePath);
   for (i := 0; i < includeList._length(); ++i) {
      strappend(all_files,' -wc '_maybe_quote_filename(includeList[i]));
   }

   for (i = 0; i < excludeList._length(); ++i) {
      strappend(all_files,' -exclude '_maybe_quote_filename(excludeList[i]));
   }

   // +W option supports multiple file specs but must specify switches
   // before files when you use this option.
   insert_file_list(recursiveString' 'optimizeString' +W +L -v +p -d 'all_files);

   _str NewFilesList[];
   if (_file_eq(_get_extension(ProjectName,true), PRJ_FILE_EXT)) {
      root := _NormalizeFile(relative(basePath,_strip_filename(ProjectName,'N')));
      _VPJAddTree(ProjectName, root, handle, p_window_id, 0, FolderNode, (int)showFolders, NewFilesList);

   } else {
      p_line=0;

      int DollarTable:[];
      _str ConfigurationNames[];
      _ProjectGet_ObjectFileInfo(handle,DollarTable,ConfigurationNames);

      int FileToNode:[];
      _ProjectGet_FileToNodeHashTab(handle,FileToNode);
      int Node=FolderNode;
      int flags=VSXMLCFG_ADD_AS_CHILD;

      filename := "";
      path := _strip_filename(ProjectName,'N');
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
         RelFilename := relative(filename,path);
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
   }

   _ProjectSave(handle);
   if (!onlyUpdateProjectFile) {
      _str TagFilename=_GetWorkspaceTagsFilename();
      //_showbuf(filelist_view_id);
      useThread := _is_background_tagging_enabled(AUTOTAG_WORKSPACE_NO_THREADS);
      tag_add_viewlist(TagFilename,filelist_view_id,ProjectName,false,true,useThread);
      //_delete_temp_view(filelist_view_id);
      activate_window(orig_view_id);

      _AddAndRemoveFilesFromVC(NewFilesList,null,ProjectName);
   }
   activate_window(orig_view_id);
}

_command void projecttbOpenFiles() name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   ProjectName := _projecttbTreeGetCurProjectName();
   project_load(_maybe_quote_filename(ProjectName));
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

   _str FolderName = _TreeGetCaption(_TreeCurIndex());
   int Node = _projecttbTreeFolderNode(gProjectHandle);
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

_command void projecttbWildcardFolderProperties() name_info(',')
{
   project_name := _projecttbTreeGetCurProjectName();
   index := _TreeCurIndex();
   df := _projecttbIsDirectoryFolder(index);
   wildcard_path := _projecttbWildcardFolderDirectory(index);
   if (df :== "") {
      return;
   }
   project_handle := _ProjectHandle(project_name);

   WILDCARD_FILE_ATTRIBUTES f;
   int ParentNode = -1;
   split(df, ',', auto nodes);
   name := "";
   for (i := 0; i < nodes._length(); ++i) {
      int Node = (int)nodes[i];
      wildcard := translate(_xmlcfg_get_attribute(project_handle, Node, 'N', 0), FILESEP, FILESEP2);
      _SeparateWildcardPath(wildcard, auto p, auto n);
      _maybe_append(name, ";");
      name :+= n;

      if (i == 0) {
         f.Recurse = _xmlcfg_get_attribute(project_handle, Node, 'Recurse', 0);
         f.Excludes = translate(_xmlcfg_get_attribute(project_handle, Node, 'Excludes'), FILESEP, FILESEP2);
         f.ListMode = _xmlcfg_get_attribute(project_handle, Node, 'L', 0);
         f.DirectoryFolder = _xmlcfg_get_attribute(project_handle, Node, 'D', 0);

         ParentNode = _xmlcfg_get_parent(project_handle, Node);
      }
   }

   filename := _RelativeToProject(_AbsoluteToProject(wildcard_path:+name, project_name), project_name);
   old_filename := filename; old_f := f;
   result := modify_wildcard_properties(project_name, filename, f, true, true);
   if (!result) {
      if ((old_filename == filename) &&
          (old_f.Recurse == f.Recurse) && (old_f.Excludes == f.Excludes) &&
          (old_f.ListMode == f.ListMode) && (old_f.DirectoryFolder == f.DirectoryFolder)) {
         return;
      }

      // delete old nodes
      for (i = 0; i < nodes._length(); ++i) {
         int Node = (int)nodes[i];
         _xmlcfg_delete(project_handle, Node);
      }

      _SeparateWildcardPath(filename, wildcard_path, name);
      split(name, ';', auto namelist);

      for (i = 0; i < namelist._length(); ++i) {
         name = _RelativeToProject(wildcard_path:+namelist[i], project_name);

         // overwrite existing file nodes
         Node := _ProjectGet_FileNode(project_handle, name); 
         if (Node > 0) {
            _xmlcfg_delete(project_handle, Node);
         }

         Node = _xmlcfg_add(project_handle, ParentNode, VPJTAG_F, VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
         _xmlcfg_set_attribute(project_handle, Node, 'N', _NormalizeFile(name));
         _xmlcfg_set_attribute(project_handle, Node, 'Recurse', f.Recurse);
         if (f.Excludes != '') {
            _xmlcfg_set_attribute(project_handle, Node, 'Excludes', _NormalizeFile(f.Excludes));
         } 
         if (f.ListMode) {
            _xmlcfg_set_attribute(project_handle, Node, 'L', f.ListMode);
         }
         if (f.DirectoryFolder) {
            _xmlcfg_set_attribute(project_handle, Node, 'D', f.DirectoryFolder);
         }
      }

      _ProjectSave(project_handle);
      _WorkspaceCache_Update();
      toolbarUpdateWorkspaceList();
   }
}

//2:44pm 7/20/2000 Tested after move from project.e
_command void projecttbCompile() name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   int treeWid, currIndex;
   _str name, fullPath;
   if (getCurrentTreeFile(treeWid, currIndex, name, fullPath)) {
      return;
   }
   cur_project_name := treeWid._projecttbTreeGetCurProjectName();

   _str old_project_name=_project_name;
   //_project_name=cur_project_name;
   workspace_set_active(cur_project_name,false,false,false);
   project_compile(fullPath);
   //_project_name=old_project_name;
   workspace_set_active(old_project_name,false,false,false);
}
_command void projecttbBuildCommand(_str cmdline='') name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   cmd := args := "";
   parse cmdline with cmd args;
   cmd=stranslate(cmd,'-','_');
   if (cmd=='project-compile') {
      projecttbCompile();
      return;
   }
   ProjectName := _projecttbTreeGetCurProjectName();
   _str fullPath;
   if (_projecttbIsProjectFileNode()) {
      int treeWid, currIndex;
      _str name;
      if (getCurrentTreeFile(treeWid, currIndex, name, fullPath)) {
         return;
      }
   } else if (_projecttbIsProjectNode()) {
      // use the current buffer
      fullPath = _mdi.p_child.p_buf_name;
   }

   _str old_project_name=_project_name;
   workspace_set_active(ProjectName,false,false,false);
   //_project_name=VSEProjectFilename(fullPath);

   cwd := getcwd();
   if (cmd=='project-usertool') {
      project_usertool(args,false,true,0,fullPath);
   } else if (cmd=='project-build') {
      project_build("build",false,true,0,fullPath);
   } else if ( cmd == 'project-execute' ) {
      project_execute("execute",false,true,0,fullPath);
   } else {
      execute(cmdline);
   }
   path := getcwd();
   _maybe_append_filesep(cwd);
   _maybe_append_filesep(path);
   if (!_file_eq(path,cwd)) {
      // WARNING: sending a cd command to the process buffer here
      // might screw up an error message because this is asynchronous
      //cd(cwd);
   }
   //_project_name=old_project_name;
   workspace_set_active(old_project_name,false,false,false);
}

int _OnUpdate_projecttbGenerateMakefile(CMDUI& cmdui, int target_wid, _str command)
{
   if ( !_haveBuild() ) {
      if ( cmdui.menu_handle ) {
         _menu_delete(cmdui.menu_handle, cmdui.menu_pos);
         return(MF_DELETED | MF_REQUIRES_PRO);
      }
      return(MF_GRAYED | MF_REQUIRES_PRO);
   }
   if ( _project_name == '' ) {
      return MF_GRAYED;
   }
   return MF_ENABLED;
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

   cwd := getcwd();
   generate_makefile(_project_name, "", true, true);
   path := getcwd();
   _maybe_append_filesep(cwd);
   _maybe_append_filesep(path);
   if (!_file_eq(path,cwd)) {
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

_command void projecttbAddItemToProject() name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   ProjectFilename:=_projecttbTreeGetCurProjectName(-1,true);
   if (ProjectFilename=='') {
      return;
   }
   olddir := getcwd();
   chdir(_strip_filename(ProjectFilename,'N'),1);
   project_add_item('','','',false,ProjectFilename);
   chdir(olddir,1);
   return;
   
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

      ProjectName := target_wid._projecttbTreeGetCurProjectName();
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
         if (_projecttbTreeFolderNode(handle) < 0) {
            df := _projecttbIsDirectoryFolder(_TreeCurIndex());
            if (df != "") {
               return MF_ENABLED;
            }

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
         fullpath = _AbsoluteToWorkspace(fullpath);

         relFilename := _RelativeToProject(fullpath, ProjectName);
         if (_IsVisualStudioWorkspaceFilename(_workspace_filename)) {
            _str assocFileName = _xmlcfg_get_filename(handle);
            if (_file_eq(_get_extension(assocFileName,true), VISUAL_STUDIO_VCPP_PROJECT_EXT)) {
               relFilename = ConvertToVCPPRelFilename(relFilename, _strip_filename(assocFileName,'N'));
            }
         }
         // Allow remove of wildcard filename. Must check remove from disk or process does nothing.
         /*if(_ProjectGet_FileNode(handle, relFilename) < 0) {
            return MF_GRAYED;
         } */
      }
      if (target_wid._projecttbIsWorkspaceItemNode()) {
         _str workspace_ext=_get_extension(_workspace_filename,true);
         if (_file_eq(workspace_ext,VISUAL_STUDIO_SOLUTION_EXT)) {
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
static bool _ParentNodeSelected(int index)
{
   showchildren := bm1 := bm2NOLONGERUSED := moreflags := 0;
   while (index!=TREE_ROOT_INDEX) {
      index=_TreeGetParentIndex(index);
      if (_TreeIsSelected(index)) {
         return(true);
      }
   }
   return(false);
}

static bool isVS2005SolutionFolder(int index)
{
   if (_file_eq(_get_extension(_workspace_filename,true),VISUAL_STUDIO_SOLUTION_EXT)) {
      typeless info = _TreeGetUserInfo(index);
      if (info != '' && pos(':h:8-(:h:4-):3:h:12', info, 1, 'R')) {
         return true;
      }
   }
   return false;
}

_command void projecttbRemove() name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   if (_workspace_filename=='') {
      return;
   }
   /*
      Only cut selected files and folders items if AutoFolders is Custom View
   */

   AddDeleteFileErrorDisplayed := false;
   AddDeleteFolderErrorDisplayed := false;
   AddDeleteProjectErrorDisplayed := false;
   yesToAllRemove := false;
   yesToAllVC := false;
   noToAllRemove := false;
   noToAllVC := false;
   DeleteFromDisk := false;
   yesToAllWCDelete := false;
   noToAllWCDelete := false;


   treeWid := p_window_id;
   showchildren := bm1 := bm2NOLONGERUSED := moreflags := 0;
   count := 0;
   int info;
   index := _TreeGetNextSelectedIndex(1,info);
   if (index<0) {
      index = _TreeCurIndex();
      _TreeSelectLine(index);
   }
   int HitProject:[];
   //_str TagFilename=project_tags_filename_only();
   //open_status := 0;
   //if (_haveContextTagging()) {
   //   open_status = tag_open_db(TagFilename);
   //   if (open_status < 0) {
   //      //_message_box(nls("Unable to open tag file %s",TagFilename));
   //   }
   //}
   assocWorkspace := _IsWorkspaceAssociated(_workspace_filename);

   typeless result=0;
   fullPath := "";
   depname := "";
   pname := "";
   probably_deleted_a_file:=false;
   for (ff:=1;;ff=0) {
      activate_window(treeWid); // just in case
      index=_TreeGetNextSelectedIndex(ff,info);
      if (index<0) {
         break;
      }
      workspace_ext := _get_extension(_workspace_filename,true);
      if (_projecttbIsProjectFileNode(index) && !_ParentNodeSelected(index)) {
         if (_projecttbIsWorkspaceItemNode(index)) {
            if (_file_eq(workspace_ext,VISUAL_STUDIO_SOLUTION_EXT)) {
               RemoveSolutionItem(index);
            }
         } else {
            ProjectName := _projecttbTreeGetCurProjectName(index);
            int handle=_ProjectHandle(ProjectName);
            if (_ProjectIs_vcxproj(handle)) {
               // Visual Studio C++ project or something similar
               parse _TreeGetCaption(index) with "\t"fullPath;
               fullPath = _AbsoluteToWorkspace(fullPath);
               DeleteVCXProjFile(_AbsoluteToProject(_ProjectGet_AssociatedFile(handle), ProjectName), fullPath);
            } else {
               if (_CanWriteFileSection(ProjectName)) {
                  parse _TreeGetCaption(index) with "\t"fullPath;
                  if (!assocWorkspace) {
                     fullPath=stranslate(fullPath,'%%','%');
                  }
                  fullPath = _AbsoluteToWorkspace(fullPath);
                  relFilename := _RelativeToProject(fullPath, ProjectName);

                  if (assocWorkspace && _file_eq(workspace_ext,VISUAL_STUDIO_SOLUTION_EXT) && _IsDotNetCoreSdkProject(_ProjectGet_AssociatedHandle(handle))) {
                     // .net.Sdk project with wildcards
                     status:=DeleteVCXProjFile(_AbsoluteToProject(_ProjectGet_AssociatedFile(handle), ProjectName), fullPath);
                     if (status) {
                        result = _message_box("Delete file '"fullPath"'?",'',MB_YESNOCANCEL, IDNO);
                        if (result!=IDYES) {
                           break;
                        }
                        recycle_file(fullPath);
                     }
                  } else if (!assocWorkspace && _ProjectGet_FileNode(handle, relFilename) < 0) {
                     // handle wildcard entry
                     HitProject:[handle]=1;
                     if (!(def_vcflags&VCF_PROMPT_TO_REMOVE_DELETED_FILES)) {
                        noToAllVC=true;
                     }
                     RemoveWildcardFromProject(fullPath,yesToAllWCDelete,noToAllWCDelete,false,noToAllVC);

                  } else {
                     // Handle non-wildcard entry
                     HitProject:[handle]=1;
                     DeleteFromDisk=( yesToAllRemove && DeleteFromDisk );
                     if (!(def_vcflags&VCF_PROMPT_TO_REMOVE_DELETED_FILES)) {
                        noToAllVC=true;
                     }
                     RemoveFromProjectAndVC(fullPath,yesToAllRemove,yesToAllVC,noToAllRemove,noToAllVC,DeleteFromDisk,true,ProjectName,true);
                  }
               } else if (!AddDeleteFileErrorDisplayed) {
                  AddDeleteFileErrorDisplayed=true;
                  ProjectName=_projecttbTreeGetCurProjectName(index);
                  _message_box(nls("You can't copy/delete files from the associated project '%s1'",ProjectName));
               }
            }
         }
         probably_deleted_a_file=true;
      } else if (_projecttbIsFolderNode(index) && !_ParentNodeSelected(index)) {
         // Check for a special folder property containing a GUID
         // These are VS2005 solution item folders, and need to be deleted differently
         if (assocWorkspace && isVS2005SolutionFolder(index)) {
            // TODO: Method to delete an entire VS2005
            // solution item folder
            FolderName := _TreeGetCaption(index);
            result=_message_box("Are you sure you want to delete the folder '"FolderName"'?",'',MB_YESNO);
            if (result!=IDYES) {
               break;
            }
            folderGuid := _TreeGetUserInfo(index);
            RemoveSolutionItemFolder2005(folderGuid);

         } else {
            ProjectName := _projecttbTreeGetCurProjectName(index);
            int handle = _ProjectHandle(ProjectName);
            _str AutoFolders = _ProjectGet_AutoFolders(handle);
            if (!strieq(AutoFolders,VPJ_AUTOFOLDERS_CUSTOMVIEW)) {
               if (!AddDeleteFolderErrorDisplayed) {
                  AddDeleteFileErrorDisplayed=true;
                  _message_box(nls("You can't remove folders from this associated project."));
               }
            } else if (_ProjectIs_vcxproj(handle)) {
               FolderName := _TreeGetCaption(index);
               result=_message_box("Are you sure you want to delete the folder '"FolderName"'?",'',MB_YESNO);
               if (result!=IDYES) {
                  break;
               }
               DeleteVCXProjFolder(_AbsoluteToProject(_ProjectGet_AssociatedFile(handle), ProjectName));

            } else if (!_ProjectIs_AddDeleteFolderSupported(handle)) {
               if (!AddDeleteFolderErrorDisplayed) {
                  AddDeleteFileErrorDisplayed=true;
                  _message_box(nls("You can't delete folders from the associated project '%s1'",ProjectName));
               }

            } else {
               FolderName := _TreeGetCaption(index);
               if (_ProjectIs_SupportedXMLVariation(handle)) {
                  handle=_ProjectGet_AssociatedHandle(handle);
               }

               int Node = _projecttbTreeFolderNode(handle,index);
               if (Node >= 0) {
                  result=_message_box("Are you sure you want to delete the folder '"FolderName"'?",'',MB_YESNO);
                  if (result != IDYES) {
                     break;
                  }
                  _xmlcfg_delete(handle, Node);
                  _ProjectSave(handle);
               } else {
                   df := _projecttbIsDirectoryFolder(index);
                   if (df != "") {
                      wildcard_path := _projecttbWildcardFolderDirectory(index);
                      result = _message_box(nls('Are you sure you want to delete the wildcard folder "%s"?',wildcard_path),'',MB_YESNO);
                      if (result != IDYES) {
                         break;
                      }
                      split(df, ',', auto nodelist);
                      for (i := 0; i < nodelist._length(); ++i) {
                         Node = (int)nodelist[i];
                         _xmlcfg_delete(handle, Node);
                         _ProjectSave(handle);
                      }
                   }
               }
            }
         }

      } else if (_projecttbIsDependencyNode(index)) {
         if (_IsWorkspaceAssociated(_workspace_filename)) {
            if (!AddDeleteProjectErrorDisplayed) {
               AddDeleteProjectErrorDisplayed=true;
               _message_box(nls("You cannot remove this dependency because this is an associated workspace."));
            }
            continue;
         }
         ProjectName := _projecttbTreeGetCurProjectName(index);
         depname=_RelativeToWorkspace(_projecttbTreeGetCurProjectName(index,true));
         result=_message_box(nls("Remove dependency %s1 from project %s2?",depname,_RelativeToWorkspace(ProjectName)),"",MB_YESNO);
         if (result!=IDYES) {
            break;
         }
         int handle=_ProjectHandle(ProjectName);
         _ProjectRemove_Dependency(handle,depname);
         _ProjectSave(handle);
      } else if (_projecttbIsProjectNode(index)) {
         if (!_IsAddDeleteProjectsSupportedWorkspaceFilename(_workspace_filename)) {
            if (!AddDeleteProjectErrorDisplayed) {
               AddDeleteProjectErrorDisplayed=true;
               _message_box(nls("You cannot remove this project because this is an associated workspace."));
            }
            continue;
         }
         pname=GetProjectDisplayName(_projecttbTreeGetCurProjectName(index,true));
         result=_message_box(nls("Remove project %s1 from workspace %s2?",pname,_workspace_filename),"",MB_OKCANCEL);
         if (result!= IDOK) {
            break;
         }
         _macro('M',_macro('s'));//This is always called from another func, so recording
                                 //get shut off.
         workspace_remove(pname,'',false);
         //toolbarUpdateWorkspaceList();
      }
   }
   if (probably_deleted_a_file) {
      call_list("_prjupdate_");
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
      _ProjectUpdate_AutoTreeFolders(handle);
      _ProjectSave(handle);
      // regenerate the makefile
      _maybeGenerateMakefile(_xmlcfg_get_filename(handle));
   }
   //if (_haveContextTagging()) {
   //   if (open_status >= 0) {
   //      tag_close_db(TagFilename);
   //   }
   //   _TagCallList(TAGFILE_MODIFIED_CALLBACK_PREFIX,TagFilename);
   //   _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
   //}
   _WorkspaceCache_Update();
   toolbarUpdateWorkspaceList();
}
//3:28pm 7/20/2000 Tested after move from project.e
_command void projecttbRefresh(_str force=0) name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   orig_wid:=p_window_id;
   if (p_active_form.p_name!=TBPROJECTS_FORM) {
      tree_wid := _tbGetActiveProjectsTreeWid();
      if (!tree_wid) {
         return;
      }
      p_window_id=tree_wid;
   }
   ProjectName := _projecttbTreeGetCurProjectName();
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
   workspace_refresh(force);
   p_window_id=orig_wid;
}

//3:25pm 7/20/2000 Tested after move from project.e
// Retn:  0 for OK, 1 for non-file item, -1 for no project toolbar (error)
static int getCurrentTreeFile(int & treeWid, int & currIndex,
                              _str & name, _str & fullpath,
                              _str &ProjectName='')
{
   treeWid= _tbGetActiveProjectsTreeWid();
   if (treeWid == 0) {
      return -1;
   }
   currIndex= treeWid._TreeCurIndex();
   return(_GetProjectToolWindowTreeFile(treeWid,currIndex,name,fullpath,ProjectName));
}

//3:25pm 7/20/2000 Tested after move from project.e
// Retn:  0 for OK, 1 for non-file item, -1 for no project toolbar (error)
int _GetProjectToolWindowTreeFile(int treeWid, int index,
                                  _str & name, _str & fullpath,
                                  _str &ProjectName='')
{
   // check for no tree wid
   if (treeWid <= 0 || !_iswindow_valid(treeWid)) {
      return -1;
   }
   if ( index<0 ) return -1;
   int formWid;
   caption := treeWid._TreeGetCaption(index);
   name1 := fullPath1 := "";
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

int getAbsoluteFilenameInProjectToolWindow(int treeWID,int treeIndex,_str &filename)
{
   status := _GetProjectToolWindowTreeFile(treeWID,treeIndex,auto justname,filename);
   return status;
}

int _OnUpdate_projecttbRetagFile(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_projecttbRetagWorkspace(cmdui,target_wid,command);
}

_command projecttbRetagFile() name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Tagging");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   int treeWid, currIndex;
   _str name, fullPath;
   if (getCurrentTreeFile(treeWid, currIndex, name, fullPath)) {
      return(0);
   }
   temp_view_id := 0;
   orig_view_id := 0;
   inmem := false;
   int status=_open_temp_view(fullPath,temp_view_id,orig_view_id,'',inmem,false,true);
   if (status) return(status);
   _str FileList=project_tags_filename();
   DoneList := "";
   ff := true;
   for (;;) {
      _str CurTagFilename=next_tag_file2(FileList,false);
      if (CurTagFilename=='') break;
      //We don't want to repeat files, and tags_filename sometimes
      //returns a string with duplicates.
      if (pos(' 'CurTagFilename' ',DoneList,'',_fpos_case)) continue;
      status=tag_read_db(CurTagFilename);
      if (status >= 0) {
         message('Retagging 'p_buf_name);
         status=RetagCurrentFile(false,false,CurTagFilename);
         clear_message();
         DoneList :+= ' 'CurTagFilename' ';
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
_command projecttbRetagWorkspace() name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   _str oldprojectname=_project_name;
   IsToolbar := false;
   old_project_name := "";
   if (p_name==PROJECT_TOOLBAR_NAME) {
      IsToolbar=true;
      _str cap=_TreeGetCaption(_TreeCurIndex());
      new_project_name := "";
      parse cap with "\t" new_project_name;
      new_project_name = _AbsoluteToWorkspace(new_project_name);
      old_project_name=_project_name;
      _project_name=new_project_name;
   }

   workspace_retag();

   if (IsToolbar) {
      _project_name=old_project_name;
   }
   _project_name=oldprojectname;
}

int _OnUpdate_projecttbRetagProject(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_projecttbRetagWorkspace(cmdui,target_wid,command);
}

int _OnUpdate_projecttbShowRelativePaths(CMDUI &cmdui,int target_wid,_str command)
{
   if (def_project_show_relative_paths) {
      return MF_ENABLED|MF_CHECKED;
   }
   return MF_ENABLED|MF_UNCHECKED;
}
_command projecttbShowRelativePaths() name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   def_project_show_relative_paths = !def_project_show_relative_paths;
   _config_modify_flags(CFGMODIFY_DEFVAR);
   projecttbRefresh();
}

int _OnUpdate_projecttbSortProjects(CMDUI &cmdui,int target_wid,_str command)
{
   if (_IsWorkspaceAssociated(_workspace_filename)) {
      return MF_GRAYED|MF_CHECKED;
   }
   sort:=_WorkspaceGet_Sort(gWorkspaceHandle);
   if (sort) {
      return MF_ENABLED|MF_CHECKED;
   }
   return MF_ENABLED|MF_UNCHECKED;
}
_command projecttbSortProjects() name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   sort:=_WorkspaceGet_Sort(gWorkspaceHandle);
   _WorkspaceSet_Sort(gWorkspaceHandle,!sort);
   projecttbRefresh(1);
}

_command projecttbRetagProject() name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   _str oldprojectname=_project_name;
   IsToolbar := false;
   old_project_name := "";
   if (p_name==PROJECT_TOOLBAR_NAME) {
      IsToolbar=true;
      _str cap=_TreeGetCaption(_TreeCurIndex());
      new_project_name := "";
      parse cap with "\t" new_project_name;
      new_project_name = _AbsoluteToWorkspace(new_project_name);
      old_project_name=_project_name;
      _project_name=new_project_name;
   }

   project_retag();

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
   if (_workspace_filename=='') {
      return;
   }
   tree_index := _TreeCurIndex();
   int state, bm1, bm2NOLONGERUSED, node_flags;
   if ( !_TreeIsSelected(tree_index) ) {
      _TreeSelectLine(tree_index, true);
      _TreeRefresh();
   }
   isAntBuildFile := _projecttbIsAntBuildFileNode();
   isNAntBuildFile := _projecttbIsNAntBuildFileNode();
   isMakefile := _projecttbIsMakefileNode();

   name := "";
   fullPath := "";
   if ( _projecttbIsWorkspaceFileNode() ) {
      name = '_projecttb_workspace_file_menu';
   } else if ( _projecttbIsWorkspaceFolderNode() ) {
      name = '_projecttb_workspace_folder_menu';
   } else if ( _projecttbIsWorkspaceNode() ) {
      name = '_projecttb_workspace_menu';
   } else if ( _projecttbIsProjectNode() ) {
      name = '_projecttb_project_menu';
   } else if ( _projecttbIsFolderNode() ) {
      name = '_projecttb_folder_menu';
   } else if ( _projecttbIsProjectFileNode() || isAntBuildFile || isNAntBuildFile ) {
      name = '_projecttb_file_menu';
   }
   int index = find_index(name, oi2type(OI_MENU));
   if ( !index ) {
      return;
   }
   int menu_handle = p_active_form._menu_load(index, 'P');
   _str menu_name = name;  // Need this for the call_list later

   int numSelectedItems, startSelectedItem, endSelectedItem;
   status := 0;
   submenu_handle := submenu_pos := 0;
   if ( name == '_projecttb_folder_menu' ) {
      // Are we inserting something into the folder context menu? We must be
      // on a folder node...
      ProjectName := _projecttbTreeGetCurProjectName(tree_index);
      if ( ProjectName != '' && _utIsUnitTestEnabledForProject(ProjectName, GetCurrentConfigName(ProjectName))) {
         // Unittest items
         status = _menu_find(menu_handle, 'projecttbFolderProperties', submenu_handle, submenu_pos, 'M');
         if ( !status ) {
            _utDisplayProjectContextMenu(ProjectName, submenu_handle, submenu_pos);
         }

         // enable add class/interface/enum for java package view
         if ( strieq(_ProjectGet_AutoFolders(_ProjectHandle()), VPJ_AUTOFOLDERS_PACKAGEVIEW) ) {
            mh := mp := smh := smp := 0;
            status = _menu_find(menu_handle, 'ncw', mh, mp);
            status = _menu_find(mh, 'projecttbAddNewFile', smh, smp, 'M');
            _menu_insert(smh, ++smp,MF_ENABLED, 'New Class...', 'add_java_item Java Class', '');
            _menu_insert(smh, ++smp,MF_ENABLED, 'New Interface...', 'add_java_item Java Interface', '');
            _menu_insert(smh, ++smp,MF_ENABLED, 'New Enum...', 'add_java_item Java Enum', '');
            _menu_insert(smh, ++smp,MF_ENABLED, 'New Item From Template...', 'add_java_item', '');
         }
      }

      if (_projecttbIsDirectoryFolder(tree_index) != '') {
         status = _menu_find(menu_handle, 'projecttbFolderProperties', auto mh, auto mp, 'M');
         if (!status) {
            _menu_set_state(menu_handle, mp, MF_ENABLED, 'P', "Wildcard Properties...", 'projecttbWildcardFolderProperties');
         }
      }
   }

   if ( name=='_projecttb_project_menu' || name=='_projecttb_file_menu' ) {
      ProjectName := _projecttbTreeGetCurProjectName();
      if ( ProjectName != '' && _utIsUnitTestEnabledForProject(ProjectName, GetCurrentConfigName(ProjectName)) ) {
         if ( name == '_projecttb_file_menu' ) {
            submenu_pos = _menu_find_loaded_menu_caption(menu_handle, 'Compile');
         } else {
            submenu_pos = _menu_find_loaded_menu_caption(menu_handle, '-', submenu_handle);
         }
         if ( submenu_pos >= 0 ) {
            _utDisplayProjectContextMenu(ProjectName, menu_handle, submenu_pos);
         }
      }
   }

   vc_menu_handle := 0;
   int dest_vc_index = _menu_find_loaded_menu_caption(menu_handle, 'Version Control', vc_menu_handle);
   // IF this menu has a version control menu
   if ( dest_vc_index >= 0 ) {
      if ( _haveVersionControl() ) {
         AddVCMenu(vc_menu_handle);
      } else {
         _menu_delete(menu_handle, dest_vc_index);
      }
   }
   int compile_index = _menu_find_loaded_menu_caption(menu_handle, 'Compile');
   // IF this menu needs the build menu commands
   if ( compile_index >= 0 ) {

      _menu_delete(menu_handle, compile_index);

      ProjectName := _projecttbTreeGetCurProjectName();

      // if this is an ant build file, list the targets
      if ( isAntBuildFile || isMakefile || isNAntBuildFile ) {
         // add ant/makefile build targets
         parse _TreeGetCaption(_TreeCurIndex()) with name "\t" fullPath;
         fullPath = _AbsoluteToWorkspace(fullPath);
         mkfileType := "";
         if ( isAntBuildFile ) {
            mkfileType = "ant";
         } else if ( isNAntBuildFile ) {
            mkfileType = "nant";
         } else if ( isMakefile ) {
            mkfileType = "makefile";
         }
         _addTargetMenuItems(menu_handle, compile_index, ProjectName, fullPath, mkfileType);

      } else if ( _projecttbIsProjectFileNode() ) {
         int treeWid, currIndex;
         if ( getCurrentTreeFile(treeWid, currIndex, name, fullPath) ) {
            return;
         }

         // only commands that require a buffer - we send the file clicked in the tool window
         _AddBuildMenuItems(menu_handle, compile_index, '',''/*_Filename2LangId(fullPath)*/, 1, 'projecttbBuildCommand ', ProjectName);

      } else if ( _projecttbIsProjectNode() ) {
         // this is the project node itself, so just allow all the project commands
         // commands which require a buffer will use the current one
         // if no buffer open, that command will be grayed out automatically
         //lang := _no_child_windows() ? '' : _mdi.p_child.p_LangId;
         _AddBuildMenuItems(menu_handle, compile_index, '',''/*lang*/, 0, 'projecttbBuildCommand ', ProjectName);
      } else {
         _AddBuildMenuItems(menu_handle, compile_index, '','', 2, 'projecttbBuildCommand ', ProjectName);
      }

      // Check for two -- in a row
      if ( compile_index > 0 ) {
         --compile_index;
      }
      prevCaption := "";
      for ( ;compile_index < _menu_info(menu_handle); ++compile_index ) {
         _str caption;
         mf_flags := 0;
         _menu_get_state(menu_handle, compile_index, mf_flags, 'P', caption);
         if ( prevCaption == '-' && caption == '-' ) {
            _menu_delete(menu_handle, compile_index);
            --compile_index;
         }
         prevCaption = caption;
      }

      initMenuSetActiveConfig(menu_handle, _no_child_windows(), ProjectName);
   }

   int sort_folder_index = _menu_find_loaded_menu_caption(menu_handle, 'Show folders sorted');
   // IF this menu needs the build menu commands
   if ( sort_folder_index >= 0 ) {
      ProjectName := _projecttbTreeGetCurProjectName();
      if (!_file_eq(_get_extension(ProjectName,true), PRJ_FILE_EXT)) {
         _menu_delete(menu_handle, sort_folder_index);
      }
   }

   int treeWid = _proj_tooltab_tree;
   currIndex := treeWid._TreeCurIndex();

   // If a file is not selected, disable file operations:
   if ( !_projecttbIsProjectFileNode(currIndex) ) {
      _menu_set_state(menu_handle, 'projecttbCompile', MF_GRAYED, 'M');
      _menu_set_state(menu_handle, 'projecttbEditFile', MF_GRAYED, 'M');
      _menu_set_state(menu_handle, 'projecttbCheckin', MF_GRAYED, 'M');
      _menu_set_state(menu_handle, 'projecttbCheckout', MF_GRAYED, 'M');
      _menu_set_state(menu_handle, 'projecttbRetagFile', MF_GRAYED, 'M');
   }
   if ( !_projecttbIsProjectNode(currIndex) ) {
      _menu_set_state(menu_handle, 'projecttbBuild', MF_GRAYED, 'M');
      _menu_set_state(menu_handle, 'projecttbRebuild', MF_GRAYED, 'M');
      _menu_set_state(menu_handle, 'projecttbGenerateMakefile', MF_GRAYED, 'M');

   } else {
      // add ant/makefile build targets (inserts above first separator)
      _addTargetSubmenu(menu_handle, _projecttbTreeGetCurProjectName());

      // makefile generation not supported for all project types
      if ( !_project_supports_makefile_generation(_projecttbTreeGetCurProjectName(-1, true)) ) {
         _menu_set_state(menu_handle, 'projecttbGenerateMakefile', MF_GRAYED, 'M');
      }
   }
   // IF there are no projects in this workspace
   if ( _project_name == '' ) {
      _menu_set_state(menu_handle, 'projecttbAddToProject', MF_GRAYED, 'M');
      _menu_set_state(menu_handle, 'projecttbRetagProject', MF_GRAYED, 'M');
      _menu_set_state(menu_handle, 'project_edit', MF_GRAYED, 'M');
      _menu_set_state(menu_handle, 'projecttbCompile', MF_GRAYED, 'M');
   }

   // Show the menu:
   int x = VSDEFAULT_INITIAL_MENU_OFFSET_X;
   int y = VSDEFAULT_INITIAL_MENU_OFFSET_Y;
   x = mou_last_x('M') - x;
   y = mou_last_y('M') - y;
   _lxy2dxy(p_scale_mode, x, y);
   _map_xy(p_window_id, 0, x, y, SM_PIXEL);
   int flags = VPM_LEFTALIGN | VPM_RIGHTBUTTON;
   _KillToolButtonTimer();
   //TreeDisablePopup(DelaySetting);
   //get_window_id(orig_view_id);
   call_list('_on_popup_', translate(menu_name, '_', '-'), menu_handle);
   status = _menu_show(menu_handle, flags, x, y);
   //activate_window(orig_view_id);
   _menu_destroy(menu_handle);
   //TreeEnablePopup(DelaySetting);
}

static void AddVCMenu(int vc_menu_handle)
{
   if ( _VCIsSpecializedSystem(_GetVCSystemName())) {
      _CVSAddTreeMenu(vc_menu_handle);
   } else {
      // Copy the contents of this menu from the _ext_menu_default menu
      int temp=find_index("_ext_menu_default",oi2type(OI_MENU));
      int src_vc_index=_menu_find_caption(temp,"Version Control");
      if ( src_vc_index ) {
         int child=src_vc_index.p_child;
         int firstchild=child;
         for (;;) {
            item_text := stranslate(child.p_caption,'','&');
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
   index := find_index(pgmname, COMMAND_TYPE);
   if (index) {
      status= execute(command, '');
   } else {
      temp= slick_path_search(pgmname, 'p');
      if (temp=='') {
         message2 := ".\n\nGo to Tools > Options > Languages > File Extension Manager to edit the application associated with this file extension.";
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
      index := find_index('_OnUpdate_projecttbBuildCommand_'args[0],PROC_TYPE);
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
      index := find_index('_OnUpdate_projecttbBuildCommand_project_usertool_'args[0],PROC_TYPE);
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

   hTree := _tbGetActiveProjectsTreeWid();
   numSelected := hTree._TreeGetNumSelectedItems();
   if (_projecttbTreeGetCurProjectName() != _project_name) {
      return MF_GRAYED;
   } else if (numSelected > 1) {
      return MF_GRAYED;
   } else {
      return MF_ENABLED;
   }
}

int _OnUpdate_projecttbAddNewBuildTool(CMDUI& cmdui, int target_wid, _str command)
{
   if ( !_haveBuild() ) {
      if ( cmdui.menu_handle ) {
         _menu_delete(cmdui.menu_handle, cmdui.menu_pos);
         return(MF_DELETED | MF_REQUIRES_PRO);
      }
      return(MF_GRAYED | MF_REQUIRES_PRO);
   }
   if ( _project_name == '' ) {
      return MF_GRAYED;
   }
   return MF_ENABLED;
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

int _OnUpdate_projecttbConfigurations(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !_haveBuild() ) {
      if ( cmdui.menu_handle ) {
         _menu_delete(cmdui.menu_handle, cmdui.menu_pos);
         return(MF_DELETED | MF_REQUIRES_PRO);
      }
      return(MF_GRAYED | MF_REQUIRES_PRO);
   }
   if (_workspace_filename=='' || _project_name=='') {
      return(MF_GRAYED);
   }
   return(MF_ENABLED);
}

_command void projecttbConfigurations() name_info("," VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      return;
   }
   ProjectName := _projecttbTreeGetCurProjectName();
   project_config(ProjectName);
}

void _workspace_refresh_projecttb()
{
   _resetCopyTree(false);
}

void _wkspace_close_projecttb()
{
   _resetCopyTree(false);
}

void _workspace_opened_projecttb()
{
   _resetCopyTree(false);
}

void _prjupdate_projecttb()
{
   _resetCopyTree(false);
}

void _projecttbGetProjects(int parentIndex, int (&projects):[])
{
   index := _TreeGetFirstChildIndex(parentIndex);
   WorkspacePath := _strip_filename(_workspace_filename, 'N');
   int indexStack[];
   depth := 0;
   while (index >= 0) {
      if (_projecttbIsProjectNode(index)) {
         caption := _TreeGetCaption(index);
         parse caption with "\t" auto fullPath; 
         projects:[_AbsoluteToWorkspace(fullPath)] = index;
      } else {
         child := _TreeGetFirstChildIndex(index);
         if (child >= 0) {
            indexStack[depth] = index;
            ++depth;
            index = child;
            continue;
         }
      }
      index = _TreeGetNextSiblingIndex(index);
      while (index < 0 && depth > 0) {
         --depth;
         index = _TreeGetNextSiblingIndex(indexStack[depth]);
      }
   }
}

#if 0

// WILDCARD PROPERTIES
static typeless WILDCARD_PROPERTY_SELECT_TREE_USERDATA(...) {
   _nocheck _control ctl_cancel;
   if (arg()) ctl_cancel.p_user=arg(1);
   return ctl_cancel.p_user;
}

static bool getWildcardAttrFromNode(int handle, _str (&nodes)[], WILDCARD_FILE_ATTRIBUTES& f, int& ParentNode)
{
   for (i := 0; i < nodes._length(); ++i) {
      int Node = (int)nodes[i];
      if (Node < 0) continue;

      f.Recurse = _xmlcfg_get_attribute(handle, Node, 'Recurse', 0);
      f.Excludes = translate(_xmlcfg_get_attribute(handle, Node, 'Excludes'), FILESEP, FILESEP2);
      f.ListMode = _xmlcfg_get_attribute(handle, Node, 'L', 0);
      f.DirectoryFolder = _xmlcfg_get_attribute(handle, Node, 'D', 0);

      ParentNode = _xmlcfg_get_parent(handle, Node);
      return true;
   }
   return false;
}

static void saveModifiedWildcardProperties(int project_handle, _str projectName, _str names[], int nodes[], _str srcnodes[], _str wildcard_path, int ParentNode, WILDCARD_FILE_ATTRIBUTES& f)
{
   for (i := 0; i < names._length(); ++i) {
      int Node = nodes[i];
      filename := _RelativeToProject(_AbsoluteToProject(wildcard_path:+names[i], projectName), projectName);
      if (Node < 0) {
         Node = _xmlcfg_add(project_handle, ParentNode, VPJTAG_F, VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
         _xmlcfg_set_attribute(project_handle, Node, 'N', _NormalizeFile(filename));
      } else {
         for (j := 0; j < srcnodes._length(); ++j) {
            if (Node == (int)srcnodes[j]) {
               srcnodes._deleteel(j); break;
            }
         }
         _xmlcfg_set_attribute(project_handle, Node, 'N', _NormalizeFile(filename));
      }

      _xmlcfg_set_attribute(project_handle, Node, 'Recurse', f.Recurse);
      if (f.Excludes != '') {
         _xmlcfg_set_attribute(project_handle, Node, 'Excludes', _NormalizeFile(f.Excludes));
      } else {
         _xmlcfg_delete_attribute(project_handle, Node, 'Excludes');
      }
      if (f.ListMode) {
         _xmlcfg_set_attribute(project_handle, Node, 'L', f.ListMode);
      } else {
         _xmlcfg_delete_attribute(project_handle, Node, 'L');
      }
      if (f.DirectoryFolder) {
         _xmlcfg_set_attribute(project_handle, Node, 'D', f.DirectoryFolder);
      } else {
         _xmlcfg_delete_attribute(project_handle, Node, 'D');
      }
   }

   for (i = 0; i < srcnodes._length(); ++i) {
      int Node = (int)srcnodes[i];
      _xmlcfg_delete(project_handle, Node);
   }

   _ProjectSave(project_handle);
   _WorkspaceCache_Update();
   toolbarUpdateWorkspaceList();
}

defeventtab _project_wildcard_property_edit;
void _project_wildcard_property_edit.lbutton_up()
{
   _nocheck _control ctl_tree;

   userinfo := WILDCARD_PROPERTY_SELECT_TREE_USERDATA();
   parse userinfo with auto project_handle "\t" auto wildcard_path "\t" auto df;
   projectName := _xmlcfg_get_filename((int)project_handle);
   split(df, ',', auto origNodes);

   _str names[];
   int nodes[];
   name := "";
   index := ctl_tree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (index > 0) {
      _maybe_append(name, ";");
      name :+= ctl_tree._TreeGetCaption(index);
      names[names._length()] = ctl_tree._TreeGetCaption(index);
      nodes[nodes._length()] = ctl_tree._TreeGetUserInfo(index);
      index = ctl_tree._TreeGetNextIndex(index);
   }
   p_active_form._delete_window();

   if (name != '') {
      filename := _RelativeToProject(_AbsoluteToProject(wildcard_path:+name, projectName), projectName);
      WILDCARD_FILE_ATTRIBUTES f;
      int ParentNode;

      getWildcardAttrFromNode((int)project_handle, origNodes, f, ParentNode);
      result := modify_wildcard_properties(projectName, filename, f, true);
      if (!result) {
         _SeparateWildcardPath(filename, wildcard_path, auto n);
         saveModifiedWildcardProperties((int)project_handle, projectName, names, nodes, origNodes, wildcard_path, ParentNode, f);
      }
   }
}

defeventtab _project_wildcard_property_add;
void _project_wildcard_property_add.lbutton_up()
{
   _nocheck _control ctl_tree;

   int select_tree_wid = _find_control('ctl_tree');
   if (select_tree_wid) {
      status := textBoxDialog("Add New Wildcard to Directory Folder", 0, 3000, p_active_form.p_help, "", "", "Name");
      if (status < 0) {
         return;
      }
      new_item := _param1;

      userinfo := WILDCARD_PROPERTY_SELECT_TREE_USERDATA();
      parse userinfo with auto project_handle "\t" auto wildcard_path "\t" auto df;

      projectName := _xmlcfg_get_filename((int)project_handle);
      RelFilename := _RelativeToProject(wildcard_path, projectName):+new_item;
      Node := _ProjectGet_FileNode((int)project_handle, RelFilename);
      if (Node > 0) {
         _message_box('Wildcard already exists in project: ':+ RelFilename);
         return;
      }
      index := ctl_tree._TreeAddItem(TREE_ROOT_INDEX, new_item, TREE_ADD_AS_CHILD|TREE_ADD_SORTED_FILENAME, 0, 0, TREE_NODE_LEAF);
      ctl_tree._TreeSetUserInfo(index, -1);
      ctl_tree._TreeSizeColumnToContents(-1);
      gProjectWildcardPropertyModified = true;
   }
}

defeventtab _project_wildcard_property_close;
void _project_wildcard_property_close.lbutton_up()
{
   _nocheck _control ctl_tree;

   userinfo := WILDCARD_PROPERTY_SELECT_TREE_USERDATA();

   parse userinfo with auto project_handle "\t" auto wildcard_path "\t" auto df;
   projectName := _xmlcfg_get_filename((int)project_handle);
   split(df, ',', auto origNodes);

   _str names[];
   int nodes[];
   index := ctl_tree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (index > 0) {
      names[names._length()] = ctl_tree._TreeGetCaption(index);
      nodes[nodes._length()] = ctl_tree._TreeGetUserInfo(index);
      index = ctl_tree._TreeGetNextIndex(index);
   }
   p_active_form._delete_window();

   if (gProjectWildcardPropertyModified) {
      WILDCARD_FILE_ATTRIBUTES f;
      int ParentNode;
      getWildcardAttrFromNode((int)project_handle, origNodes, f, ParentNode);
      saveModifiedWildcardProperties((int)project_handle, projectName, names, nodes, origNodes, wildcard_path, ParentNode, f);
   }
}
#endif
