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
#import "guiopen.e"
#import "listbox.e"
#import "main.e"
#import "menu.e"
#import "mprompt.e"
#import "project.e"
#import "projutil.e"
#import "stdprocs.e"
#import "treeview.e"
#import "wkspace.e"
#import "window.e"
#import "files.e"
#endregion

static typeless LAST_TREE_INDEX(...) {
   if (arg()) ctltree1.p_user=arg(1);
   return ctltree1.p_user;
}
static typeless IN_ON_CHANGE(...) {
   if (arg()) ctldelete.p_user=arg(1);
   return ctldelete.p_user;
}
static typeless LIST_MODIFIED(...) {
   if (arg()) ctlopen.p_user=arg(1);
   return ctlopen.p_user;
}

//#define WORKSPACE_FOLDER_VCPP "Visual C++ Workspaces"
//#define WORKSPACE_FOLDER_CPP  "C/C++ Workspaces"
//#define WORKSPACE_FOLDER_JAVA "Java Workspaces"
const WORKSPACE_FOLDER_SAMPLES= "Sample Workspaces";

void _RemoveFileFromWorkspaceManager(_str Filename,_str ProjectFilename="")
{
   if (def_workspace_info._length()==0) {
      return;
   }
   Filename=_encode_vsenvvars(Filename,true,false);
   while(MaybeAddFileToWorkspaceList(def_workspace_info,Filename,false,true,ProjectFilename));
}
void _RenameInWorkspaceManager(_str old_dir,_str new_dir,bool isDirectory) {
   if (def_workspace_info._length()==0) {
      return;
   }
   RenameInWorkspaceManager(def_workspace_info,old_dir,new_dir,isDirectory);
}
static void cleanup_def_workspace_info(WORKSPACE_LIST (&workspace_info)[]=def_workspace_info) {
   for (i:=0;i<workspace_info._length();++i) {

      if ((workspace_info[i] == null)
          || !(workspace_info[i] instanceof "WORKSPACE_LIST")
          || !isinteger(workspace_info[i].isFolder)
          || (workspace_info[i].filename!=null && workspace_info[i].filename._varformat()!=VF_LSTR)
          || (workspace_info[i].caption._varformat()!=VF_LSTR)
          || (workspace_info[i].isFolder && !length(workspace_info[i].caption))
          || (!workspace_info[i].isFolder && workspace_info[i].filename._varformat()!=VF_LSTR)
          || (workspace_info[i].projectname!=null && workspace_info[i].projectname._varformat()!=VF_LSTR)
          ) {
         workspace_info._deleteel(i);
         _config_modify_flags(CFGMODIFY_DEFVAR);
         --i;
      } else {
         if (workspace_info[i].isFolder) {
            cleanup_def_workspace_info(workspace_info[i].u.list);
         }
      }
   }
}
void _AddFilesToWorkspaceManager(_str Filename,_str FolderName="",_str ProjectFilename="")
{
   cleanup_def_workspace_info();
   if (def_workspace_info._length()==0) {
      def_workspace_info=null;
      InitTree(def_workspace_info);
   }
   /*say("f="Filename);
   say("folder="FolderName);
   say("p="ProjectFilename);*/
   if (Filename!="" && ProjectFilename=="") {
      ProjectFilename=_WorkspaceGet_CurrentProject(Filename);
      /*say("h2 p="ProjectFilename);*/
   }
   /*
   Filename=_encode_vsenvvars(Filename,true,false);
   if (ProjectFilename != "") {
      ProjectFilename=_encode_vsenvvars(ProjectFilename,true,false);
   } 
   */ 
   if (FolderName=="") {
      /*say("f="Filename);
      say("folder="FolderName);
      say("p="ProjectFilename);
      if (ProjectFilename=="") {
         _StackDump();
      } */
      MaybeAddFileToWorkspaceList(def_workspace_info,Filename,false,false,ProjectFilename);
   }else {
      AddFolderToWorkspaceList(def_workspace_info,Filename,FolderName,ProjectFilename);
   }
}

static _str decode_caption(WORKSPACE_LIST &entry)
{
   if (!entry.caption._isempty() && !entry.filename._isempty() &&
       _file_eq(entry.caption,entry.filename)) {
      return(_replace_envvars(entry.caption));
   }
   return(entry.caption);
}
static void AddFolderToWorkspaceList(WORKSPACE_LIST (&workspaceInfo)[],_str Filename,_str FolderName,_str ProjectFilename)
{
   int i;
   for (i=0;i<workspaceInfo._length();++i) {
      // I think this should be case insensitive.  We may want this to use file_eq.
      if (workspaceInfo[i].isFolder && strieq(FolderName,decode_caption(workspaceInfo[i]))) {
         MaybeAddFileToWorkspaceList(workspaceInfo[i].u.list,Filename,false,false,ProjectFilename);
      }
   }
}

/**
 *
 * @param workspaceInfo
 * @param filename
 * @return Returns true if found file
 */
static bool MaybeAddFileToWorkspaceList(WORKSPACE_LIST (&workspaceInfo)[],_str filename,bool isFolder=false,bool doDelete=false,_str ProjectFilename="") {
   FirstFileIndex := -1;
   int i;
   for (i=0;i<workspaceInfo._length();++i) {
      if (!workspaceInfo[i].isFolder) {
         if (FirstFileIndex<0) FirstFileIndex=i;
         projectname  := "";
         projectindex := workspaceInfo[i]._fieldindex("projectname");
         if (projectindex > 0 && projectindex < workspaceInfo[i]._length()) {
            projectname=workspaceInfo[i]._getfield(projectindex);
            if (projectname==null) projectname="";
         }
         //say("cmp f="filename);
         //say("cmp f="workspaceInfo[i].filename);
         if (_file_eq(filename,workspaceInfo[i].filename)) {
            //say("cmp p="ProjectFilename);
            //say("cmp p="projectname);
            if (_file_eq(ProjectFilename,projectname)) {
               if (doDelete) {
                  _config_modify_flags(CFGMODIFY_DEFVAR);
                  workspaceInfo._deleteel(i);
               }
               return(true);
            } else if (doDelete && (ProjectFilename=="") && (projectname!="")) {
               // When doing a delete, if ProjectFilename=="" want to delete all projects for this workspace.
               _config_modify_flags(CFGMODIFY_DEFVAR);
               workspaceInfo._deleteel(i);--i;
            }
         }
      } else {
         // IF this workspace is already in a folder
         if(MaybeAddFileToWorkspaceList(workspaceInfo[i].u.list,filename,true,doDelete,ProjectFilename)) {
            // We are done
            return(true);
         }
      }
   }
   if (isFolder || doDelete) {
      return(false);
   }
   if (FirstFileIndex<0) FirstFileIndex=0;
   ExistingCaption := "";
   len := workspaceInfo._length();
   //say("ADDING f="filename);
   //say("     p="ProjectFilename);
   workspaceInfo[len].caption=ExistingCaption;
   workspaceInfo[len].filename=filename;
   workspaceInfo[len].projectname=ProjectFilename;
   workspaceInfo[len].isFolder=false;
   _config_modify_flags(CFGMODIFY_DEFVAR);
   return(true);
}
/**
 *
 * @param workspaceInfo
 * @param filename
 * @return Returns true if found file
 */
static void RenameInWorkspaceManager(WORKSPACE_LIST (&workspaceInfo)[],_str old_dir,_str new_dir,bool isDirectory) {
   FirstFileIndex := -1;
   int i;
   for (i=0;i<workspaceInfo._length();++i) {
      if (!workspaceInfo[i].isFolder) {
         if (FirstFileIndex<0) FirstFileIndex=i;
         projectname  := "";
         projectindex := workspaceInfo[i]._fieldindex("projectname");
         if (projectindex > 0 && projectindex < workspaceInfo[i]._length()) {
            projectname=workspaceInfo[i]._getfield(projectindex);
            if (projectname==null) projectname="";
         }
         //say("cmp f="filename);
         //say("cmp f="workspaceInfo[i].filename);
         filename:=workspaceInfo[i].filename;
         if (isDirectory) {
            if (_file_eq(old_dir,substr(filename,1,length(old_dir)))) {
               workspaceInfo[i].filename=new_dir:+substr(filename,length(old_dir)+1);
               _config_modify_flags(CFGMODIFY_DEFVAR);
            }
            if (projectname!='' && _file_eq(old_dir,substr(projectname,1,length(old_dir)))) {
               workspaceInfo[i].projectname=new_dir:+substr(projectname,length(old_dir)+1);
               _config_modify_flags(CFGMODIFY_DEFVAR);
            }
         } else {
            if (_file_eq(old_dir,filename)) {
               workspaceInfo[i].filename=new_dir;
               _config_modify_flags(CFGMODIFY_DEFVAR);
            }
            if (projectname!='' && _file_eq(old_dir,projectname)) {
               workspaceInfo[i].projectname=new_dir;
               _config_modify_flags(CFGMODIFY_DEFVAR);
            }
         }
      } else {
         RenameInWorkspaceManager(workspaceInfo[i].u.list,old_dir,new_dir,isDirectory);
      }
   }
}


static int GetFilesFromHistory(_str (&WorkspaceFiles)[])
{
   if (_default_option(VSOPTION_DONT_READ_CONFIG_FILES)) {
      return 0;
   }
   restore_filename := editor_name("r");
   if (restore_filename==""){
      restore_filename=editor_name('p'):+_WINDOW_CONFIG_FILE;
      if (restore_filename==""){
         return(0);
      }
   }
   temp_view_id := 0;
   orig_view_id := 0;
   typeless status=_open_temp_view(restore_filename,temp_view_id,orig_view_id);
   if (status) return(status);
   WorkspaceFiles=null;
   //Parse through the vrestore file real quick and just pick out the workspace
   //files.
   for (;;) {
      get_line(auto line);
      _str rtype;
      parse line with rtype line;
      if (rtype=="WORKSPACE:") {
         typeless numlines;
         parse line with numlines .;
         down(numlines);
         int i;
         for (i=0;i<numlines;++i) {
            get_line(line);
            WorkspaceFiles[WorkspaceFiles._length()]=line;
            up();
         }
         if (down()) break;
      } else{
         typeless count=0;
         if (rtype=="SCREEN:") {
            count=1;
         }else{
            parse line with count .;
         }
         if (count=="" || !isinteger(count) || count==0) {
            count=1;
         }else ++count;
         if (down(count)) break;
      }
   }
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   return(0);
}

/**
 * Displays the Organize All Workspaces dialog box which allows you to 
 * organize your workspaces which appear in the All Workspaces menu 
 * of the Project menu
 * 
 * @see project_build
 * @see project_rebuild
 * @see project_debug
 * @see project_execute
 * @see project_user1
 * @see project_user2
 * @see workspace_open
 * @see project_compile
 * @see project_edit
 * @see project_load
 * @see new
 * @see workspace_insert
 * @see workspace_dependencies
 * @see workspace_set_active
 * @see workspace_properties
 * @see workspace_close
 * @see workspace_organize
 * 
 * @categories Project_Functions
 */ 
_command workspace_organize() name_info(','VSARG2_REQUIRES_PROJECT_SUPPORT)
{
   show("-modal -xy _workspace_organize_form");
}

defeventtab _workspace_organize_form;

static const MIN_TREE_WIDTH= 3480;
static const PATH_SEP=     ">>>";
static const NODE_SEP=     ">*<";

void _workspace_organize_form.on_resize()
{
   int xbuffer=ctltree1.p_x;
   int clientwidth=_dx2lx(SM_TWIP,p_client_width);
   ctltree1.p_width=max(clientwidth-(ctlclose.p_width+(3*xbuffer)),MIN_TREE_WIDTH);
   ctlclose.p_x=ctltree1.p_x_extent+xbuffer;
   ctlopen.p_x=ctlnewinstance.p_x=ctlmove_up.p_x=ctlmove_down.p_x=ctladd_file.p_x=ctladd_folder.p_x=ctlmove.p_x=ctldelete.p_x/*=ctlscan.p_x*/=ctlclose.p_x;

   int clientheight=_dy2ly(SM_TWIP,p_client_height);
   int ybuffer=ctlfilter.p_y;
   int HeightOfStuffAtBottom=ctltree1.p_y+
                             ctlcaption.p_height+ybuffer+
                             ctlfilename.p_height+(ybuffer*2)+
                             ctlprojectfilename.p_height+(ybuffer*2);
                             /*ctldescription_label.p_height+ybuffer+
                             ctldescription.p_height+ybuffer+
                             (clientheight intdiv 5);*/
   ctltree1.p_height=max(clientheight-HeightOfStuffAtBottom,ctlmove_down.p_y+(ctlmove_down.p_height intdiv 2));
   ctlcaption.p_y=ctltree1.p_y_extent+ybuffer;

   int CapLabelY=ctlcaption.p_y;
   int diff=ctlcaption.p_height-ctlcaption_label.p_height;
   if (diff>0) {
      diff=diff intdiv 2;
      CapLabelY+=diff;
   }
   ctlcaption_label.p_y=CapLabelY;
   ctlcaption_label.p_visible=ctldescription_label.p_visible=
      ctlfilename_label.p_visible=false;

   ctlfilename.p_y=ctlcaption.p_y_extent+ybuffer;
   int FilenameLabelY=ctlfilename.p_y;
   diff=ctlfilename.p_height-ctlfilename_label.p_height;
   if (diff>0) {
      diff=diff intdiv 2;
      FilenameLabelY+=diff;
   }
   ctlfilename_label.p_y=FilenameLabelY;
   ctlfilename.p_width=(ctltree1.p_x_extent) - ctlfilename.p_x;

   ctlprojectfilename.p_y=ctlfilename.p_y_extent+ybuffer;
   int ProjectFilenameLabelY=ctlprojectfilename.p_y;
   diff=ctlprojectfilename.p_height-ctlprojectfilename_label.p_height;
   if (diff>0) {
      diff=diff intdiv 2;
      ProjectFilenameLabelY+=diff;
   }
   ctlprojectfilename_label.p_y=ProjectFilenameLabelY;
   ctlprojectfilename.p_width=(ctltree1.p_x_extent) - ctlprojectfilename.p_x;

   ctlprojectfilename.p_width=ctlcaption.p_width=ctlfilename.p_width;

   ctldescription.p_y=ctldescription_label.p_y=p_active_form.p_height+200;

   ctlcaption_label.p_visible=ctldescription_label.p_visible=
      ctlprojectfilename_label.p_visible=ctlfilename_label.p_visible=true;
}
void ctlfilter.on_change() {
   ctltree1._TreeFilter(p_text,TREE_ROOT_INDEX);
}

static void InitTree(WORKSPACE_LIST (&workspaceInfo)[])
{
   _config_modify_flags(CFGMODIFY_DEFVAR);
   workspaceInfo=null;

   maybeAddSampleProjectsToTree(workspaceInfo);
}

void maybeAddSampleProjectsToTree(WORKSPACE_LIST (&workspaceInfo)[])
{
   if ( !_haveContextTagging()) {
      return;
   }
   if( (def_workspace_flags&WORKSPACE_OPT_COPYSAMPLES)) {
      // we want to insert this at the very beginning
      WORKSPACE_LIST samples;
      samples.isFolder = true;
      samples.caption = WORKSPACE_FOLDER_SAMPLES;

      workspaceInfo._insertel(samples, 0);
      _maybeCopySampleProjects();

#if 0
      _str samplesPath;
      if (_isUnix()) {
         samplesPath = _localSampleProjectsPath();
         _AddFilesToWorkspaceManager(samplesPath:+VSSAMPLEWORKSPACECPP:+"cpp.vpw",WORKSPACE_FOLDER_SAMPLES);
         _AddFilesToWorkspaceManager(samplesPath:+VSSAMPLEWORKSPACECLANG:+"clang.vpw",WORKSPACE_FOLDER_SAMPLES);
         _AddFilesToWorkspaceManager(samplesPath:+VSSAMPLEWORKSPACEJAVA:+"java.vpw",WORKSPACE_FOLDER_SAMPLES);
      } else {
         samplesPath=_localSampleProjectsPath();
         //_AddFilesToWorkspaceManager(samplesPath'DevStudio\2010\VS2010.sln',WORKSPACE_FOLDER_SAMPLES);
         _AddFilesToWorkspaceManager(samplesPath'DevStudio\2013\VS2013.sln',WORKSPACE_FOLDER_SAMPLES);
         _AddFilesToWorkspaceManager(samplesPath'DevStudio\2015\VS2015.sln',WORKSPACE_FOLDER_SAMPLES);
         if (_haveDebugging()) {
            _AddFilesToWorkspaceManager(samplesPath:+VSSAMPLEWORKSPACECPP:+"cpp.vpw",WORKSPACE_FOLDER_SAMPLES);
            _AddFilesToWorkspaceManager(samplesPath:+VSSAMPLEWORKSPACECLANG:+"clang.vpw",WORKSPACE_FOLDER_SAMPLES);
            _AddFilesToWorkspaceManager(samplesPath:+VSSAMPLEWORKSPACEJAVA:+"java.vpw",WORKSPACE_FOLDER_SAMPLES);
         }
      }
#endif
   }
}

/**
 * Return the local path the sample projects.
 */
_str _localSampleProjectsPath()
{
   return(_ConfigPath():+"SampleProjects":+FILESEP);
}

/**
 * Return the global path the sample projects.
 */
_str _globalSampleProjectsPath()
{
   return(_getSlickEditInstallPath():+"SampleProjects":+FILESEP);
}

void ctlcaption.on_change() {
   NewCaption := p_text;
   wid := p_window_id;
   p_window_id=ctltree1;
   index := _TreeCurIndex();
   if (index>-1) {
      state := bm1 := bm2 := flags := 0;
      _TreeGetInfo(index,state,bm1,bm2);
      isFolder := (bm1==_pic_fldclos || bm1==_pic_fldopen);
      if (!isFolder) {
         if (NewCaption=="") {
            SetCaptionWasBlank(index,true);
            filename:=GetFilename(index);
            projectname:=GetProjectFilename(index);
            projectname=absolute(projectname,_strip_filename(filename,'N'));
            NewCaption=filename;
            if (projectname != "") {
               NewCaption :+= "\t"relative(projectname,_strip_filename(filename,'N')); 
            }
         } else {
            SetCaptionWasBlank(index,false);
         }
      }
      _TreeSetCaption(index,NewCaption);
      if (!IN_ON_CHANGE()) LIST_MODIFIED(1);
   }
   p_window_id=wid;
}

void ctlfilename.on_change()
{
   Filename := strip(p_text,'B','"');
   wid := p_window_id;
   p_window_id=ctltree1;
   index := _TreeCurIndex();
   if (index>-1) {
      SetFilename(index,Filename);
      if (!IN_ON_CHANGE()) LIST_MODIFIED(1);
   }
   p_window_id=wid;
}

void ctlprojectfilename.on_change()
{
   Filename := strip(ctlfilename.p_text,'B','"');
   ProjectFilename := strip(p_text,'B','"');
   wid := p_window_id;
   p_window_id=ctltree1;
   index := _TreeCurIndex();
   if (index>-1) {
      SetFilename(index,Filename,ProjectFilename);
      if (!IN_ON_CHANGE()) LIST_MODIFIED(1);
   }
   p_window_id=wid;
}

static const DESCRIPTION_LENGTH_LIMIT= 1024;

static _str CommandsValidWhenFullTable:[]={
   "cursor-up"                 => "",
   "cursor-down"               => "",
   "cursor-left"               => "",
   "cursor-right"              => "",
   "page-up"                   => "",
   "page-down"                 => "",
   "rubout"                    =>"",
   "linewrap-rubout"           =>"",
   "linewrap-delete-char"      =>"",
   "vi-forward-delete-char"    =>"",
   "delete-char"               =>"",
   "cut-line"                  =>"",
   "join-line"                 =>"",
   "cut"                       =>"",
   "delete-line"               =>"",
   "brief-delete"              =>"",
   "find-next"                 =>"",
   "search-again"              =>"",
   "ispf-rfind"                =>"",
   "find-prev"                 =>"",
   "undo"                      =>"",
   "undo-cursor"               =>"",
   "select-line"               =>"",
   "brief-select-line"         =>"",
   "select-char"               =>"",
   "brief-select-char"         =>"",
   "cua-select"                =>"",
   "deselect"                  =>"",
   "copy-to-clipboard"         =>"",
   "copy-word"                 =>"",
   "bottom-of-buffer"          =>"",
   "top-of-buffer"             =>"",
   "page-up"                   =>"",
   "vi-page-up"                =>"",
   "page-down"                 =>"",
   "vi-page-down"              =>"",
   "cursor-left"               =>"",
   "vi-cursor-left"            =>"",
   "cursor-right"              =>"",
   "vi-cursor-right"           =>"",
   "cursor-up"                 =>"",
   "vi-prev-line"              =>"",
   "cursor-down"               =>"",
   "vi-next-line"              =>"",
   "begin-line"                =>"",
   "begin-line-text-toggle"    =>"",
   "brief-home"                =>"",
   "vi-begin-line"             =>"",
   "vi-begin-line-insert-mode" =>"",
   "brief-end"                 =>"",
   "end-line"                  =>"",
   "end-line-text-toggle"      =>"",
   "end-line-ignore-trailing-blanks"=>"",
   "vi-end-line"               =>"",
   "vi-end-line-append-mode"   =>"",
   "mou-click"                 =>"",
   "mou-extend-selection"      =>"",
   "mou-select-word"           =>"",
   "mou-select-line"           =>"",
   "cut-end-line"              =>"",
   "cut-word"                  =>"",
   "delete-word"               =>"",
   "prev-word"                 =>"",
   "next-word"                 =>"",
   "find-matching-paren"       =>"",
   "search-forward"            =>"",
   "search-backward"           =>"",
   "gui-find-backward"         =>"",
   "right-side-of-window"      =>"",
   "left-side-of-window"       =>"",
   "vi-restart-word"           =>"",
   "vi-begin-next-line"        =>"",
   "insert-toggle"             =>""
};

void ctldescription.\0-\129()
{
   oldModify:=p_modify;
   p_modify=false;
   _str lastevent=last_event();
   int key_index=event2index(lastevent);
   name_index := eventtab_index(_default_keys,_default_keys,key_index);
   command_name := name_name(name_index);

   if (p_buf_size>DESCRIPTION_LENGTH_LIMIT) {
      if (command_name=="" ||
          !CommandsValidWhenFullTable._indexin(command_name)) {
         _message_box(nls("Descriptions cannot currently exceed %s1 bytes",DESCRIPTION_LENGTH_LIMIT));
         return;
      }
   }
   if (command_name!="") {
      command_index := find_index(command_name);
      if (command_index && index_callable(command_index)) {
         call_index(command_index);
      }
   }else{
      _insert_text(lastevent);
   }

   //Check p_modify because if the user has been warned already, we do not
   //want to warn them over and over if they are just cursoring around
   if (p_modify && p_buf_size+length(lastevent)>DESCRIPTION_LENGTH_LIMIT) {
      _message_box(nls("Descriptions cannot currently exceed %s1 bytes",DESCRIPTION_LENGTH_LIMIT));
   }
   p_modify=oldModify;
}

void ctlclose.on_create()
{
   _workspace_organize_form_initial_alignment();

   // Create headers for tree control columns
   ctltree1._TreeSetColButtonInfo(0,  2000,  TREE_BUTTON_IS_FILENAME, -1,  "Workspace");
   ctltree1._TreeSetColButtonInfo(1,  1000,  TREE_BUTTON_IS_FILENAME, -1,  "Project");
   ctltree1._TreeSetHeaderClickable(0, 0);

   cleanup_def_workspace_info();
   //If we are bringing the dialog up for the first time, set things up.
   if (def_workspace_info==null || def_workspace_info._length()==0) {
      InitTree(def_workspace_info);
   }

   // Insert root item for "All Workspaces"
   wid := p_window_id;
   p_window_id=ctltree1;
   NewIndex := _TreeAddItem(TREE_ROOT_INDEX,"All Workspaces",TREE_ADD_AS_CHILD,_pic_fldclos,_pic_fldopen,TREE_NODE_EXPANDED);

   // try to remove duplicate entries
   _upgrade_workspace_manager_remove_duplicates(def_workspace_info);

   FillInWorkspaceTree(def_workspace_info,NewIndex);
   ctltree1.call_event(CHANGE_SELECTED,ctltree1._TreeCurIndex(),ctltree1,ON_CHANGE,'W');

   _TreeExpandAll();
   _TreeSizeColumnToContents(0);
   _TreeCollapseAll();

   // expanded whatever nodes were expanded in a previous run of this form
   restoreExpandedNodes();

   // make sure the path leading to the current workspace is expanded
   current := _TreeSearch(TREE_ROOT_INDEX, _workspace_filename, 'T');
   if (current > 0) {
      parent := _TreeGetParentIndex(current);
      while (parent > 0) {
         _TreeSetInfo(parent, TREE_NODE_EXPANDED);
         parent = _TreeGetParentIndex(parent);
      }
   }

   p_window_id=wid;
}

static void _workspace_organize_form_initial_alignment()
{
   // make sure all the buttons are evenly sized, based on the widest button, which is auto-sized
   ctlopen.p_width = ctlnewinstance.p_width=ctladd_folder.p_width = ctlmove.p_width = ctlmove_up.p_width = ctlmove_down.p_width =
      ctldelete.p_width = ctlclose.p_width = ctladd_file.p_width;

   ctltree1.p_width = ctlopen.p_x - 120 - ctltree1.p_x;
}

static void saveExpandedNodes()
{
   wid := p_window_id;
   p_window_id = ctltree1;

   // get our list of expanded nodes
   expandedList := findExpandedChildren(TREE_ROOT_INDEX, "");

   // save it for the future
   _append_retrieve(0, expandedList, p_active_form.p_name".ctltree1");

   p_window_id = wid;
}

static _str findExpandedChildren(int parent, _str parentPath)
{
   expandedList := "";
   int expanded;

   if (parentPath != "") parentPath :+= PATH_SEP;

   // go through the children and see what is expanded
   child := _TreeGetFirstChildIndex(parent);
   while (child > 0) {
      _TreeGetInfo(child, expanded);
      if (expanded == TREE_NODE_EXPANDED) {
         thisPath := parentPath :+ _TreeGetCaption(child);
         expandedList :+= thisPath;

         childrenList := findExpandedChildren(child, thisPath);
         if (childrenList != "") {
            expandedList :+= NODE_SEP :+ childrenList;
         }
      } 

      child = _TreeGetNextSiblingIndex(child);
   }

   return expandedList;
}

static void restoreExpandedNodes()
{
   wid := p_window_id;
   _control ctltree1;
   p_window_id = ctltree1;

   // first we collapse everything
   _TreeCollapseAll();

   expandedList := ctltree1._retrieve_value();
   
   while (expandedList != "") {
      path := "";
      parse expandedList with path (NODE_SEP) expandedList;

      node := TREE_ROOT_INDEX;
      while (path != "") {
         caption := "";
         parse path with caption (PATH_SEP) path;
         
         node = _TreeSearch(node, caption);
         if (node < 0) path = "";
      }

      if (node > 0) {
         _TreeSetInfo(node, TREE_NODE_EXPANDED);
      }
   }

   p_window_id = wid;
}

static _str FormatFilename(_str Filename)
{
   PathFirstName := _strip_filename(Filename,'P');
   PathFirstName :+= "\t"PathFirstName=_strip_filename(Filename,'M');
   return(PathFirstName);
}

static _str UnformatFilename(_str FormatedFilename)
{
   _str filename, path;
   parse FormatedFilename with filename "\t" path;
   return(path);
}

static void FillInWorkspaceTree(WORKSPACE_LIST workspaceInfo[],int TreeControlParentIndex)
{
   i := 0;
   int AddFlags=TREE_ADD_AS_CHILD;
   int LastTreeControlIndex=TreeControlParentIndex;
   for (i=0;i<workspaceInfo._length();++i) {
      int pic1=_pic_file;
      int pic2=_pic_file;
      moreflags := 0;

      _str filename=workspaceInfo[i].filename;
      _str caption=workspaceInfo[i].caption;
      captionWasBlank := caption=="";;
      if (filename==null) {
         filename="";
      }
      if (caption==null) {
         caption="";
      }
      projectname  := "";
      projectindex := workspaceInfo[i]._fieldindex("projectname");
      if (projectindex > 0 && projectindex < workspaceInfo[i]._length()) {
         projectname=workspaceInfo[i]._getfield(projectindex);
         if (projectname==null) projectname="";
      }
      if (filename!="") {
         if (_file_eq(filename,caption)) {
            filename=_replace_envvars(filename);
            caption=_replace_envvars(caption);
         } else {
            filename=_replace_envvars(filename);
         }
      }
      if (projectname != "") {
         projectname=_replace_envvars(projectname);
         projectname=absolute(projectname,_strip_filename(filename,'N'));
      }
      if (caption=="" || _file_eq(filename,caption)) {
         caption=filename;
         if (projectname != "") {
            caption :+= "\t"relative(projectname,_strip_filename(filename,'N')); 
         }
      }

      if (workspaceInfo[i].isFolder) {
         pic1=_pic_fldclos;
         pic2=_pic_fldopen;
      }else{
         if (filename!="" && _file_eq(filename,_workspace_filename)) {
            if (_file_eq(projectname,_project_name) || (projectname=="") != (_project_name=="")) {
               moreflags=TREENODE_BOLD;  
            }
         }
         //Filename=FormatFilename(Filename);
      }
      if (AddFlags==TREE_ADD_AS_CHILD) {
         state := 0;
         _TreeGetInfo(LastTreeControlIndex,state);
         if (state!=TREE_NODE_EXPANDED) {
            _TreeSetInfo(LastTreeControlIndex,TREE_NODE_EXPANDED);
         }
      }
      LastTreeControlIndex=_TreeAddItem(LastTreeControlIndex,caption,AddFlags,pic1,pic2,workspaceInfo[i].isFolder?TREE_NODE_COLLAPSED:TREE_NODE_LEAF,moreflags);
      if (!workspaceInfo[i].isFolder) {
         SetFilename(LastTreeControlIndex,filename,projectname);
         SetCaptionWasBlank(LastTreeControlIndex,captionWasBlank);
         SetDescription(LastTreeControlIndex,workspaceInfo[i].u.description);
      }
      if (workspaceInfo[i].u.list._varformat()==VF_ARRAY) {
         FillInWorkspaceTree(workspaceInfo[i].u.list,LastTreeControlIndex);
      }
      AddFlags=0;
   }
}
static void maybe_make_column_width_bigger(int col) {
   int orig_width=_TreeColWidth(col);
   _TreeSizeColumnToContents(col);
   if (_TreeColWidth(col)<orig_width) {
      _TreeColWidth(col,orig_width);
   }
}

void ctladd_folder.lbutton_up()
{
   ctltree1.AddFolderButton();
   ctltree1.maybe_make_column_width_bigger(0);
}

void ctladd_file.lbutton_up()
{
   if (!ctltree1.AddFileButton()) {
      ctltree1.maybe_make_column_width_bigger(0);
   }
}

/**
 * Add a workspace to the Organize All Workspaces menu.
 * 
 * @return 'true' if they select to open the workspace now.
 */
static bool AddFileButton()
{
   index := _TreeCurIndex();
   //int depth=_TreeGetDepth(index);
   ParentState := bm1 := bm2 := 0;
   _TreeGetInfo(index,ParentState,bm1,bm2);
   ParentIndex := -1;
   Flags := 0;
   RelationIndex := -1;
   if (bm1==_pic_fldclos || bm1==_pic_fldopen) {
      ParentIndex=index;
      Flags=TREE_ADD_AS_CHILD;
      RelationIndex=ParentIndex;
   }else{
      ParentIndex=_TreeGetParentIndex(index);
      RelationIndex=index;
      //No Flags, add after "RelationIndex"
   }
   _str format_list=_GetWorkspaceExtensionList();
   _str WorkspaceFilename=_OpenDialog("-new -mdi -modal",
                             "Add Workspace File",
                             "",     // Initial wildcards
                             format_list,  // file types
                             OFN_FILEMUSTEXIST,
                             WORKSPACE_FILE_EXT,      // Default extensions
                             "",      // Initial filename
                             "",      // Initial directory
                             "",      // Reserved
                             "Standard Open dialog box"
                            );
   if (WorkspaceFilename=="") return false;
   WorkspaceFilename = strip(WorkspaceFilename,"B", '"');

   // check to see if this file is already in there
   NewIndex := FindWorkspaceInTree(TREE_ROOT_INDEX, WorkspaceFilename);
   if (NewIndex < 0) {
      // not already there, add it
      NewIndex=_TreeAddItem(RelationIndex,WorkspaceFilename,Flags,_pic_file,_pic_file,TREE_NODE_LEAF);
      SetFilename(NewIndex,WorkspaceFilename);
   } else {
      ParentIndex=_TreeGetParentIndex(NewIndex);
      _TreeGetInfo(index,ParentState,bm1,bm2);
   }

   if (ParentState!=TREE_NODE_EXPANDED) {
      _TreeSetInfo(ParentIndex,TREE_NODE_EXPANDED);
   }
   _TreeSetCurIndex(NewIndex);
   ctltree1.call_event(CHANGE_SELECTED,ctltree1._TreeCurIndex(),ctltree1,ON_CHANGE,'W');
   int result=_message_box(nls("Do you wish to open this workspace now?\n\nThis dialog will be closed."),"",MB_YESNO);
   LIST_MODIFIED(1);
   _set_focus();
   if (result==IDYES) {
      ctlopen.call_event(ctlopen,LBUTTON_UP);
      return true;
   }
   return false;
}

/*
//5:29:53 PM 9/2/00
//Was going to do this, but I am not sure if INS should add a folder or a file.
void ctltree1."ins"()
{
   AddFolderButton();
}*/

static void AddFolderButton()
{
   index := _TreeCurIndex();
   //int depth=_TreeGetDepth(index);
   ParentState := bm1 := bm2 := 0;
   _TreeGetInfo(index,ParentState,bm1,bm2);
   ParentCaption := "";
   ParentIndex := -1;
   if (bm1==_pic_fldclos || bm1==_pic_fldopen) {
      ParentCaption=_TreeGetCaption(index);
      ParentIndex=index;
   }else{
      ParentIndex=_TreeGetParentIndex(index);
      ParentCaption=_TreeGetCaption(ParentIndex);
   }
   typeless result=show("-modal _textbox_form",
               "New Folder Name",
               0,   // flags
               "",                           // width ("" or 0 uses default)
               "New Folder Name dialog",     // Optional help item
               "",                           // Buttons and captions
               "",                           // Retrieve name
               "New Folder Name:"
               );
   if (result=="") return;
   if (_param1=="") return;
   _str NewFolderName=_param1;

   // add folder after the last folder index
   LastFolderIndex := 0;
   index = _TreeGetFirstChildIndex(ParentIndex);
   while (index >= 0) {
      if (isFolder(index)) LastFolderIndex=index;
      index = _TreeGetNextSiblingIndex(index);
   }
   NewFolderIndex := 0;
   if (LastFolderIndex > 0) {
      NewFolderIndex = _TreeAddItem(LastFolderIndex,NewFolderName,TREE_ADD_AFTER,_pic_fldclos,_pic_fldopen,TREE_NODE_EXPANDED);
   } else {
      NewFolderIndex = _TreeAddItem(ParentIndex,NewFolderName,TREE_ADD_AS_FIRST_CHILD,_pic_fldclos,_pic_fldopen,TREE_NODE_EXPANDED);
   }
   if (ParentState!=TREE_NODE_EXPANDED) {
      _TreeSetInfo(ParentIndex,TREE_NODE_EXPANDED);
   }
   _TreeSetCurIndex(NewFolderIndex);
   LIST_MODIFIED(1);
   _set_focus();
}

static bool areMultipleItemsSelected()
{
   index := _TreeGetNextSelectedIndex(1, auto info);
   if (index < 0) return false;

   // see if there is a second selection
   index = _TreeGetNextSelectedIndex(0, info);
   return index > 0;
}

static void EnabledOpenButton()
{
   if (areMultipleItemsSelected()) {
      ctlopen.p_enabled=false;
      ctlnewinstance.p_enabled=false;
   } else {
      index := _TreeCurIndex();
      ctlopen.p_enabled=isTreeItemWorkspaceFile(index)/* && (FindWorkspaceInTree(index,_workspace_filename) < 0)*/;
      ctlnewinstance.p_enabled=ctlopen.p_enabled;
   }
}

static void EnableDeleteButton()
{
   // get what's selected
   common_parent := -1;
   int selected[];
   _TreeGetSelectionIndices(selected);

   for (i := 0; i < selected._length(); i++) {
      if (selected[i] == _TreeGetFirstChildIndex(TREE_ROOT_INDEX) ||
          FindWorkspaceInTree(selected[i],_workspace_filename) > 0 ) {
         ctldelete.p_enabled=false;
         return;
      }
      if (common_parent >= 0 && _TreeGetParentIndex(selected[i]) != common_parent) {
         ctldelete.p_enabled=false;
         return;
      }
      common_parent = _TreeGetParentIndex(selected[i]);
   }

   ctldelete.p_enabled=true;
}

static void EnableMoveToFolderButton()
{
   // get what's selected
   common_parent := -1;
   int selected[];
   _TreeGetSelectionIndices(selected);

   for (i := 0; i < selected._length(); i++) {
      if ( isFolder(selected[i]) ) {
         ctlmove.p_enabled=false;
         return;
      }
      if (common_parent >= 0 && _TreeGetParentIndex(selected[i]) != common_parent) {
         ctlmove.p_enabled=false;
         return;
      }
      common_parent = _TreeGetParentIndex(selected[i]);
   }

   ctlmove.p_enabled=true;
}

static bool isFolder(int index) {
   if (index==TREE_ROOT_INDEX) return true;
   child_index := _TreeGetFirstChildIndex(index);
   if (child_index>=0) {
      return true;
   }
   state := bm1 := bm2 := flags := 0;
   _TreeGetInfo(index,state,bm1,bm2);
   if (bm1==_pic_fldclos || bm1==_pic_fldopen) {
      return true;
   }
   return false;
}
static int FindWorkspaceInTree(int index, _str filename)
{
   if (isFolder(index)) {
      index=_TreeGetFirstChildIndex(index);
      while (index>=0) {
         found:=FindWorkspaceInTree(index,filename);
         if (found >= 0) return found;
         index = _TreeGetNextSiblingIndex(index);
      }
      return -1;
   }

   // Leaf node
   _str thisFilename=GetFilename(index);
   if (_file_eq(thisFilename,filename)) {
      return index;
   }
   return -1;
}

void ctltree1.on_change(int reason,int index)
{
   if (IN_ON_CHANGE()==1) return;
   IN_ON_CHANGE(1);
   switch (reason) {
   case CHANGE_SELECTED:
      EnabledOpenButton();
      EnableMoveButtons();
      EnableDeleteButton();
      ctldescription.SaveDescriptionText();
      typeless status=SetFilenameAndDescription();
      if (status) {
         _TreeSetCurIndex(LAST_TREE_INDEX());
         IN_ON_CHANGE(0);
         return;
      }
      EnableDescriptionEtc();
      break;
   case CHANGE_LEAF_ENTER:
      ctlopen.call_event(ctlopen,LBUTTON_UP);
      return;//Have to return here because dialog is deleted
   }
   LAST_TREE_INDEX(_TreeCurIndex());
   IN_ON_CHANGE(0);
}

static void SaveDescriptionText()
{
   if (LAST_TREE_INDEX()=="") {
      return;
   }
   text := "";
   _getMacroText(text);
   wid := p_window_id;
   p_window_id=ctltree1;
   SetDescription(LAST_TREE_INDEX(),text);
   LIST_MODIFIED(1);
   p_window_id=wid;
}

static int SetFilenameAndDescription()
{
   CurIndex := _TreeCurIndex();
   if (isTreeItemWorkspaceFile(CurIndex)) {
      ctlfilename.p_text=strip(GetFilename(CurIndex),'B','"');
      ctlprojectfilename.p_text=strip(GetProjectFilename(CurIndex),'B','"');
      ctldescription._setMacroText(GetDescription(CurIndex));
      if (GetCaptionWasBlank(CurIndex)) {
         ctlcaption.p_text="";
      } else {
         ctlcaption.p_text=_TreeGetCaption(CurIndex);
      }
   } else {
      ctldescription._lbclear();
      ctlcaption.p_text=_TreeGetCaption(CurIndex);
   }
   return(0);
}

static void EnableDescriptionEtc()
{
   CurIndex := _TreeCurIndex();
   state := bm1 := bm2 := flags := 0;
   _TreeGetInfo(CurIndex,state,bm1,bm2);
   if (CurIndex==_TreeGetFirstChildIndex(TREE_ROOT_INDEX)) {
      ctlcaption.p_enabled=false;
   }else{
      ctlcaption.p_enabled=true;
   }
   if (bm1==_pic_fldclos || bm1==_pic_fldopen) {
      ctlfilename.p_enabled=false;
      ctlfilename.p_text="";
      ctlprojectfilename.p_enabled=false;
      ctlprojectfilename.p_text="";
      ctldescription_label.p_enabled=ctldescription.p_enabled=false;
   }else{
      ctlfilename.p_enabled=false;
      ctlprojectfilename.p_enabled=false;
      ctldescription_label.p_enabled=ctldescription.p_enabled=true;
   }
}

static void EnableMoveButtons()
{
   if (areMultipleItemsSelected()) {
      ctlmove.p_enabled=false;
      ctlmove_up.p_enabled=false;
      ctlmove_down.p_enabled=false;
      ctltree1.EnableMoveToFolderButton();
   } else {
      ctlmove_down.p_enabled=ctltree1._TreeFindMoveDown(ctltree1._TreeCurIndex(),ctltree1._TreeGetFirstChildIndex(TREE_ROOT_INDEX),auto ToIndex,auto AddFlags);
      ctlmove_up.p_enabled=ctltree1._TreeFindMoveUp(ctltree1._TreeCurIndex(),ctltree1._TreeGetFirstChildIndex(TREE_ROOT_INDEX),ToIndex,AddFlags);
      ctlmove.p_enabled = (ctltree1._TreeCurIndex() != ctltree1._TreeGetFirstChildIndex(TREE_ROOT_INDEX));
   }
}

void ctlnewinstance.lbutton_up()
{
   if (!_default_option(VSOPTION_ALLOW_FILE_LOCKING)) {
      _message_box("Your configuration can't be shared with multiple instances because file locking is disabled (-sul invocation option)");
      return;
   }
   if (!(def_exit_flags & SAVE_CONFIG_IMMEDIATELY_SHARE_CONFIG)) {
      result:=_message_box("Sharing your config needs to be enabled.\n\nDo you want to enable sharing your config with multiple instances?","",MB_YESNOCANCEL);
      if (result!=IDYES) {
         return;
      }
      def_exit_flags=SAVE_CONFIG_IMMEDIATELY_SHARE_CONFIG;
      _config_modify_flags(CFGMODIFY_DEFVAR);
      _maybe_save_config();
      _ConfigUpdateShareMode();
   }

   ctlopen.call_event(true,ctlopen,LBUTTON_UP,'W');
}
void ctlopen.lbutton_up(bool newInstance=false)
{
   wid := p_window_id;
   p_window_id=ctltree1;
   index := _TreeCurIndex();
   if (!isTreeItemWorkspaceFile(index)) {
      //This can happen from a call event.
      return;
   }
   _str WorkspaceFilename=GetFilename(index);
   if (!file_exists(WorkspaceFilename)) {
      _message_box(nls("File '%s1' does not exist",WorkspaceFilename));
      p_window_id=wid;
      return;
   }
   _str ProjectFilename=GetProjectFilename(index);
   if (!file_exists(ProjectFilename)) {
      ProjectFilename="";
   }
   p_window_id=wid;
   //p_active_form._delete_window();
   ctlclose.call_event(ctlclose,LBUTTON_UP);
   if (ProjectFilename!="") {
      workspace_open(_maybe_quote_filename(WorkspaceFilename)" "_maybe_quote_filename(ProjectFilename),'','',true,true,true,newInstance?1:0);
   } else {
      workspace_open(_maybe_quote_filename(WorkspaceFilename),'','',true,true,true,newInstance?1:0);
   }
}

void ctlclose.lbutton_up()
{
   wid := p_window_id;
   p_window_id=ctltree1;
   AllWorkspaceIndex := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   ctltree1.call_event(CHANGE_SELECTED,ctltree1._TreeCurIndex(),ctltree1,ON_CHANGE,'W');
   if (LIST_MODIFIED()==1) {
      def_workspace_info=null;
      GetTreeData(def_workspace_info,0,_TreeGetFirstChildIndex(AllWorkspaceIndex));
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
   p_window_id=wid;

   saveExpandedNodes();

   p_active_form._delete_window();

}

static _str GetFilename(int index)
{
   UserInfo := _TreeGetUserInfo(index);
   parse UserInfo with auto OldFilename "\1" auto OldDescription "\1" auto OldProjectFilename "\1" auto OldCaptionWasBlank;
   return(OldFilename);
}

static _str GetProjectFilename(int index)
{
   UserInfo := _TreeGetUserInfo(index);
   parse UserInfo with auto OldFilename "\1" auto OldDescription "\1" auto OldProjectFilename "\1" auto OldCaptionWasBlank;
   return(OldProjectFilename);
}

static _str GetDescription(int index)
{
   UserInfo := _TreeGetUserInfo(index);
   parse UserInfo with auto OldFilename "\1" auto OldDescription "\1" auto OldProjectFilename "\1" auto OldCaptionWasBlank;
   return(OldDescription);
}
static bool GetCaptionWasBlank(int index)
{
   UserInfo := _TreeGetUserInfo(index);
   parse UserInfo with auto OldFilename "\1" auto OldDescription "\1" auto OldProjectFilename "\1" auto OldCaptionWasBlank;
   return OldCaptionWasBlank?true:false;
}


static void SetFilename(int index,_str Filename,_str ProjectFilename="")
{
   UserInfo := _TreeGetUserInfo(index);
   parse UserInfo with auto OldFilename "\1" auto OldDescription "\1" auto OldProjectFilename "\1" auto OldCaptionWasBlank;
   if (ProjectFilename=="") ProjectFilename=OldProjectFilename;
   _TreeSetUserInfo(index,Filename"\1"OldDescription"\1"ProjectFilename"\1"OldCaptionWasBlank);
}

static void SetCaptionWasBlank(int index,bool captionWasBlank)
{
   UserInfo := _TreeGetUserInfo(index);
   parse UserInfo with auto OldFilename "\1" auto OldDescription "\1" auto OldProjectFilename "\1" auto OldCaptionWasBlank;
   _TreeSetUserInfo(index,OldFilename"\1"OldDescription"\1"OldProjectFilename"\1"captionWasBlank);
}

static void SetDescription(int index,_str Description)
{
   if (Description._isempty()) Description="";
   UserInfo := _TreeGetUserInfo(index);
   if ( UserInfo == null ) return;
   parse UserInfo with auto OldFilename "\1" auto OldDescription "\1" auto OldProjectFilename "\1" auto OldCaptionWasBlank;
   _TreeSetUserInfo(index,OldFilename"\1"Description"\1"OldProjectFilename"\1"OldCaptionWasBlank);
}

void GetTreeData(WORKSPACE_LIST (&WorkspaceInfo)[],int ArrayIndex,int TreeControlIndex)
{
   for (;;) {
      if (TreeControlIndex<=0) return;
      caption := _TreeGetCaption(TreeControlIndex, 0);
      state := bm1 := bm2 := flags := 0;
      _TreeGetInfo(TreeControlIndex,state,bm1,bm2);
      if (bm1==_pic_fldclos || bm1==_pic_fldopen) {
         WorkspaceInfo[ArrayIndex].isFolder=true;
         WorkspaceInfo[ArrayIndex].caption=caption;
      }else{
         WorkspaceInfo[ArrayIndex].isFolder=false;
         if (caption._isempty() || GetCaptionWasBlank(TreeControlIndex)) caption="";
         _str filename=GetFilename(TreeControlIndex);
         _str projectname=_encode_vsenvvars(GetProjectFilename(TreeControlIndex),true,false);
         if (_file_eq(filename,caption)) {
            filename=_encode_vsenvvars(filename,true,false);
            caption=_encode_vsenvvars(filename,true,false);
         } else {
            filename=_encode_vsenvvars(filename,true,false);
         }
         WorkspaceInfo[ArrayIndex].caption=caption;
         WorkspaceInfo[ArrayIndex].filename=filename;
         WorkspaceInfo[ArrayIndex].projectname=projectname;
         WorkspaceInfo[ArrayIndex].u.description=GetDescription(TreeControlIndex);
      }
      cIndex := _TreeGetFirstChildIndex(TreeControlIndex);
      if (cIndex>-1) {
         GetTreeData(WorkspaceInfo[ArrayIndex].u.list,0,cIndex);
      }
      TreeControlIndex=_TreeGetNextSiblingIndex(TreeControlIndex);
      ++ArrayIndex;
   }
}

void ctlmove.lbutton_up()
{
   typeless result=show("-modal _workspace_organize_move_form",ctltree1,ctltree1._TreeCurIndex());
   if (result!="") {
      int index=result;
      wid := p_window_id;
      p_window_id=ctltree1;
      //index=_TreeGetParentIndex(index);
      //Ok, now we just have to copy everything from the one to the other.
      if (areMultipleItemsSelected()) {
         _TreeGetSelectionIndices(auto selected);
         for (i := 0; i < selected._length(); i++) {
            MoveTree(selected[i],index);
            _TreeDelete(selected[i]);
         }
      } else {
         OldIndex := _TreeCurIndex();
         MoveTree(OldIndex,index);
         //_TreeSetCurIndex(index);
         _TreeDelete(OldIndex);
      }
      LIST_MODIFIED(1);
      ctltree1.call_event(CHANGE_SELECTED,ctltree1._TreeCurIndex(),ctltree1,ON_CHANGE,'W');
      p_window_id=wid;
   }
   ctltree1._set_focus();
}

static void MoveTree(int FromIndex,int ToIndex,bool TraverseSiblings=false)
{
   int NewParentIndex=ToIndex;
   first := 1;
   for (;;) {
      if (FromIndex<0) break;
      Caption := _TreeGetCaption(FromIndex);
      state := bm1 := bm2 := flags := 0;
      _TreeGetInfo(FromIndex,state,bm1,bm2,flags);
      typeless Data=_TreeGetUserInfo(FromIndex);
      int NewIndex=_TreeAddItem(ToIndex,Caption,TREE_ADD_AS_CHILD,bm1,bm2,state,flags,Data);
      if (first && !TraverseSiblings) {
         //This should be the first copy
         _TreeSetCurIndex(NewIndex);
      }

      // make sure the parent folder node is expanded to show the goodies
      _TreeSetInfo(ToIndex,TREE_NODE_EXPANDED);

      ChildIndex := _TreeGetFirstChildIndex(FromIndex);
      if (ChildIndex>-1) {
         MoveTree(ChildIndex,NewIndex,true);
      }
      if (!TraverseSiblings) break;
      FromIndex=_TreeGetNextSiblingIndex(FromIndex);
      first=0;
   }
}

static bool check_all_workspaces_sort_option() 
{
   if (def_workspace_flags & WORKSPACE_OPT_NO_SORT_PROJECTS) {
      return true;
   }
   response := _message_box(nls("The All Workspaces menu is sorted.\n\nDo you want to disable sorting and manually arrange the Workspace menu?"), "", MB_YESNO);
   if (response == IDYES) {
      def_workspace_flags |= WORKSPACE_OPT_NO_SORT_PROJECTS;
      _config_modify_flags(CFGMODIFY_DEFVAR);
      return true;
   }
   return false;
}

void ctlmove_up.lbutton_up()
{
   if (!check_all_workspaces_sort_option()) {
      return;
   }
   wid := p_window_id;
   p_window_id=ctltree1;

   CurIndex := _TreeCurIndex();
   int ToIndex;
   int AddFlags;
   if(!_TreeFindMoveUp(_TreeCurIndex(),_TreeGetFirstChildIndex(TREE_ROOT_INDEX),ToIndex,AddFlags)) {
      return;
   }
   //IN_ON_CHANGE(1);
   _TreeMoveItem(CurIndex,ToIndex,AddFlags);
   if(ctlfilter.p_text!='') ctlfilter.p_text='';
   //IN_ON_CHANGE(0);
   _set_focus();
   LIST_MODIFIED(1);
   EnableMoveButtons();
   p_window_id=wid;
}

void ctlmove_down.lbutton_up()
{
   if (!check_all_workspaces_sort_option()) {
      return;
   }
   wid := p_window_id;
   p_window_id=ctltree1;
   CurIndex := _TreeCurIndex();
   int ToIndex;
   int AddFlags;
   if(!_TreeFindMoveDown(_TreeCurIndex(),_TreeGetFirstChildIndex(TREE_ROOT_INDEX),ToIndex,AddFlags)) {
      return;
   }
   /*say("To Caption="_TreeGetCaption(ToIndex));
   if (AddFlags==TREE_ADD_BEFORE) {
      say("   TREE_ADD_BEFORE");
   } else if (AddFlags==TREE_ADD_AFTER) {
      say("   TREE_ADD_AFTER");
   } else if (AddFlags==TREE_ADD_AS_CHILD) {
      say("   TREE_ADD_AS_CHILD");
   } else if (AddFlags==TREE_ADD_AS_FIRST_CHILD) {
      say("   TREE_ADD_AS_FIRST_CHILD");
   } */
   //IN_ON_CHANGE(1);
   _TreeMoveItem(CurIndex,ToIndex,AddFlags);
   if(ctlfilter.p_text!='') ctlfilter.p_text='';
   //IN_ON_CHANGE(0);
   _set_focus();
   LIST_MODIFIED(1);
   EnableMoveButtons();
   p_window_id=wid;
}

void ctltree1.del()
{
   DeleteButton();
}

void ctldelete.lbutton_up()
{
   DeleteButton();
}

/**
 * Returns whether the given index in the workspace tree is a 
 * workspace file.  If not, then it is a folder containing 
 * workspaces. 
 * 
 * @param index 
 * 
 * @return bool
 */
static bool isTreeItemWorkspaceFile(int index)
{
   state := bm1 := bm2 := flags := 0;
   _TreeGetInfo(index, state, bm1, bm2);

   return (bm1 == _pic_file);
}

static int countChildWorkspaces(int index)
{
   count := 0;

   // go through the children
   child := _TreeGetFirstChildIndex(index);
   while (child > 0) {

      // see if it's a folder or a workspace
      if (isTreeItemWorkspaceFile(child)) {
         count++;
      } else {
         count += countChildWorkspaces(child);
      }

      child = _TreeGetNextSiblingIndex(child);
   }

   return count;
}

static void DeleteButton()
{
   if (!ctldelete.p_enabled) {
      _beep();
      return;
   }
   LAST_TREE_INDEX("");
   wid := p_window_id;
   p_window_id=ctltree1;

   // get what's selected
   int selected[];
   _TreeGetSelectionIndices(selected);
   selected._sort("N");

   // how many workspaces?  maybe overkill, but we are fancy
   remainingFiles := 0;
   int status, index;
   for (i := 0; i < selected._length(); i++) {
      index = selected[i];

      if (isTreeItemWorkspaceFile(index)) {
         remainingFiles++;
      } else {
         remainingFiles += countChildWorkspaces(index);
      }
   }
   // 2 means prompt to delete
   doDeleteFiles := 2;

   for (i = 0; i < selected._length(); i++) {
      index = selected[i];

      // find out if it's a folder or a workspace file
      if (isTreeItemWorkspaceFile(index)) {
         status = p_window_id.MaybeDeleteWorkspaceFromTree(index, remainingFiles, doDeleteFiles);
      } else {
         status = p_window_id.MaybeDeleteFolderFromTree(index, true, remainingFiles, doDeleteFiles);
      }
      if (status) return;
   }

   p_window_id=wid;
   ctltree1._set_focus();
}

static int MaybeDeleteFolderFromTree(int index, bool promptDelete, int& remainingFiles, int& doDeleteFiles)
{
   name := _TreeGetCaption(index);
   ChildIndex := _TreeGetFirstChildIndex(index);

   // if there are children, make sure they understand they're deleting those too
   if (promptDelete && ChildIndex > 0) {
      text := "Do you wish to remove the folder '"name"' and all the child folders and workspaces from your All Workspaces menu?";
      int result=_message_box(text, "Delete Folder", MB_YESNO);
      if (result==IDNO) {
         return(COMMAND_CANCELLED_RC);
      }
   }

   // go through all the children
   status := 0;
   for (;;) {
      if (ChildIndex<0) break;
      NextIndex := _TreeGetNextSiblingIndex(ChildIndex);
      if (isTreeItemWorkspaceFile(ChildIndex)) {
         status = MaybeDeleteWorkspaceFromTree(ChildIndex, remainingFiles, doDeleteFiles);
      }else{
         status=MaybeDeleteFolderFromTree(ChildIndex, false, remainingFiles, doDeleteFiles);
      }
      if (status) return(status);
      ChildIndex=NextIndex;
   }

   // now delete the folder
   _TreeDelete(index);

   return(0);
}
static bool workspace_exists_elsewhere_in_tree(int folder_index,_str workspace,int skip_index) {
   
   index := _TreeGetFirstChildIndex(folder_index);
   while (index>=0) {
      if (isFolder(index)) {
         if(workspace_exists_elsewhere_in_tree(index,workspace,skip_index)) {
            return true;
         }
      } else if (index!=skip_index) {
         if (file_eq(GetFilename(index),workspace)) {
            return true;
         }
      }
      index=_TreeGetNextSiblingIndex(index);
   }
   
   return false;
}

static int MaybeDeleteWorkspaceFromTree(int index, int& remainingFiles, int &doDeleteFiles)
{
   WorkspaceFilename := GetFilename(index);
   if (!workspace_exists_elsewhere_in_tree(_TreeGetFirstChildIndex(TREE_ROOT_INDEX),WorkspaceFilename,index)) {
      result := (doDeleteFiles == 1) ? IDYES : IDNO;
      if (doDeleteFiles == 2) {
         text := "\t-html Do you wish to permamently delete files associated with the workspace '"WorkspaceFilename"'?\n-html Warning: All projects in the workspace will be deleted.\n-html Note: No source files will be deleted.";
         buttons := "&Yes,&No,Cancel:_cancel"text;
         cbText := (remainingFiles > 1) ? "-checkbox Perform this action for the remaining "remainingFiles" workspaces." : "";

         result = textBoxDialog("Delete Workspace",           // caption
                                 0,                            // flags
                                 0,                            // textbox width
                                 "",                           // help item
                                 buttons, 
                                 "",
                                 cbText);

         if (_param1 == 1) {
            doDeleteFiles = (result == IDYES) ? 1 : 0;
         }
      }

      if (result == COMMAND_CANCELLED_RC) return result;

      if (result == 1) { // YES
         // they're cleaning house now
         if (_file_eq(WorkspaceFilename,_workspace_filename)) {
            workspace_close();
         }

         _str Files[]=null;
         _GetWorkspaceFiles(WorkspaceFilename,Files);
         WorkspacePath := _strip_filename(WorkspaceFilename,'N');

         // Delete all the project files
         for (i := 0; i < Files._length(); ++i) {
            recycle_file(absolute(Files[i],WorkspacePath));
         }

         // Delete the tag file
         tag_file := VSEWorkspaceTagFilename(WorkspaceFilename);
         if (file_exists(tag_file)) delete_file(tag_file);

         // Delete the workspace state (history) file
         history_file := VSEWorkspaceStateFilename(WorkspaceFilename);
         if (file_exists(history_file)) recycle_file(history_file);

         // Delete the workspace file
         recycle_file(VSEWorkspaceFilename(WorkspaceFilename));
      } // else NO
   }
   // either way, remove it from the list
   _menu_remove_workspace_hist(WorkspaceFilename,false);
   _TreeDelete(index);
   remainingFiles--;

   return 0;
}

defeventtab _workspace_organize_move_form;

void ctlok.on_create(int ParentTreeWID,int ExcludeId)
{
   ctltree1.CopyParentTree(ParentTreeWID,ctltree1,ParentTreeWID._TreeGetFirstChildIndex(TREE_ROOT_INDEX),TREE_ROOT_INDEX,ExcludeId);
}

int ctlok.lbutton_up()
{
   int index=ctltree1._TreeGetUserInfo(ctltree1._TreeCurIndex());
   p_active_form._delete_window(index);
   return(index);
}

ctltree1.lbutton_double_click()
{
   ctlok.call_event(ctlok,LBUTTON_UP);
}

ctltree1.enter()
{
   ctlok.call_event(ctlok,LBUTTON_UP);
}

static void CopyParentTree(int ParentTreeWID,int NewTreeWid,int ParentTreeIndex,
                           int NewTreeParentIndex,int ExcludeId)
{
   for (;;) {
      if (ParentTreeIndex<0) {
         break;
      }
      wid := p_window_id;
      p_window_id=ParentTreeWID;
      state := bm1 := bm2 := flags := 0;
      _TreeGetInfo(ParentTreeIndex,state,bm1,bm2);
      if ((bm1==_pic_fldclos || bm1==_pic_fldopen) &&
          ParentTreeIndex!=ExcludeId) {
         Caption := _TreeGetCaption(ParentTreeIndex);
         int NewTreeNewIndex=NewTreeWid._TreeAddItem(NewTreeParentIndex,Caption,TREE_ADD_AS_CHILD,_pic_fldclos,_pic_fldopen,TREE_NODE_LEAF,0,ParentTreeIndex);
         NewTreeWid._TreeGetInfo(NewTreeParentIndex,state);
         if (state!=TREE_NODE_EXPANDED) NewTreeWid._TreeSetInfo(NewTreeParentIndex,TREE_NODE_EXPANDED);
         cindex := _TreeGetFirstChildIndex(ParentTreeIndex);
         if (cindex>-1) {
            NewTreeWid.CopyParentTree(ParentTreeWID,NewTreeWid,cindex,NewTreeNewIndex,ExcludeId);
         }
      }
      ParentTreeIndex=_TreeGetNextSiblingIndex(ParentTreeIndex);
      p_window_id=wid;
   }
}

void _workspace_organize_move_form.on_resize()
{
   int xbuffer=ctltree1.p_x;
   int clientwidth=_dx2lx(SM_TWIP,p_client_width);
   ctltree1.p_width=clientwidth-(2*xbuffer);

   int clientheight=_dy2ly(SM_TWIP,p_client_height);
   int ybuffer=ctltree1.p_y;
   ctltree1.p_height=clientheight-(ctlok.p_height+(3*ybuffer));
   ctlok.p_y=ctltree1.p_y_extent+ybuffer;
   ctlok.p_next.p_y=ctlok.p_y;
}

void _AddWorkspaceTreeToMenu()
{
   int menu_handle=_mdi.p_menu_handle;
   if (!menu_handle) return;

   AllWorkspacesHandle := 0;
   itempos := 0;
   int status=_menu_find(menu_handle, "AllWorkspaces", AllWorkspacesHandle,
                     itempos, "C");
   if (!status) {
      _menu_delete(AllWorkspacesHandle,itempos);
   }
   status=_menu_find(menu_handle,"project-edit",AllWorkspacesHandle,itempos,'M');
   if (status) {
      return;
   }
   //status=_menu_add_hist(filename,_mdi.p_menu_handle,"&Project","wkspchist","workspace-open","ncw|wkspcopen",WKSPCHIST_HELP,WKSPCHIST_MESSAGE);

   // try to remove duplicate entries (only once, or if history chagnes)
   static int last_num_workspace_info;
   if (last_num_workspace_info != def_workspace_info._length()) {
      _upgrade_workspace_manager_remove_duplicates(def_workspace_info);
      last_num_workspace_info = def_workspace_info._length();
   }

   int flags=MF_SUBMENU;
   int submenu_handle=_menu_insert(AllWorkspacesHandle,
                                    -1,
                                    flags,       // flags
                                    "&All Workspaces",
                                    "",   // command
                                    "AllWorkspaces",    // category
                                    "",  // help command
                                    ""       // help message
                                    );
   cleanup_def_workspace_info();
   AddWorkspacesToMenu(submenu_handle,def_workspace_info);
   // Insert the menu separator if it is not already there.
   _str dash_category=WKSPHIST_CATEGORY;
   dash_mh := dash_pos := 0;
   status=_menu_find(menu_handle,dash_category,dash_mh,dash_pos,'c');
   if (status) {
      temp_handle := 0;
      _menu_find(menu_handle, "AllWorkspaces", temp_handle,itempos, "C");
      _menu_insert(temp_handle,itempos,MF_ENABLED,"-","",dash_category);
   }
}

static void getWorkspaceProjectAndCaption(WORKSPACE_LIST &info, _str &wkspacename, _str &projectname, _str &caption)
{
   caption = info.caption;
   if (caption==null) caption="";

   wkspacename = info.filename;
   if (wkspacename==null) wkspacename="";

   projectname = "";
   projectindex := info._fieldindex("projectname");
   if (projectindex > 0 && projectindex < info._length()) {
      projectname = info._getfield(projectindex);
   }
   if (projectname==null) {
      projectname="";
   }

   if (wkspacename!="") {
      if (_file_eq(wkspacename,caption)) {
         wkspacename=_replace_envvars(wkspacename);
         caption=_replace_envvars(caption);
      } else {
         wkspacename=_replace_envvars(wkspacename);
      }
   }

   if (projectname!="") {
      projectname=_replace_envvars(projectname);
      projectname=absolute(projectname,_strip_filename(wkspacename,'N'));
   }
   if (caption=="") {
      caption=wkspacename;
   }
}
static int compareWorkspaceInfo(WORKSPACE_LIST &lhs,  WORKSPACE_LIST &rhs)
{
   if (lhs.isFolder && rhs.isFolder) {
      return stricmp(lhs.caption, rhs.caption);
   }
   if (lhs.isFolder) return -1;
   if (rhs.isFolder) return 1;
   lhsWkspaceName := rhsWkspaceName := "";
   lhsProjectName := rhsProjectName := "";
   lhsCaption     := rhsCaption     := "";
   getWorkspaceProjectAndCaption(lhs, lhsWkspaceName, lhsProjectName, lhsCaption);
   getWorkspaceProjectAndCaption(rhs, rhsWkspaceName, rhsProjectName, rhsCaption);
   compareStatus := stricmp(_strip_filename(lhsWkspaceName,'P'), _strip_filename(rhsWkspaceName,'P'));
   if (compareStatus != 0) return compareStatus;
   compareStatus = stricmp(lhsWkspaceName, rhsWkspaceName);
   if (compareStatus != 0) return compareStatus;
   compareStatus = stricmp(_strip_filename(lhsProjectName,'P'), _strip_filename(rhsProjectName,'P'));
   if (compareStatus != 0) return compareStatus;
   compareStatus = stricmp(lhsProjectName, rhsProjectName);
   if (compareStatus != 0) return compareStatus;
   lhsCaption = _make_fhist_caption(lhsCaption,WKSPHIST_CATEGORY,lhsProjectName);
   rhsCaption = _make_fhist_caption(rhsCaption,WKSPHIST_CATEGORY,rhsProjectName);
   compareStatus = stricmp(lhsCaption, rhsCaption);
   if (compareStatus != 0) return compareStatus;
   return 0;
}
static void AddWorkspacesToMenu(int ParentMenuHandle,WORKSPACE_LIST workspaceInfo[],int depth=0)
{
   if (def_workspace_info._length()==0) {
      def_workspace_info=null;
      InitTree(def_workspace_info);
      workspaceInfo=def_workspace_info;
   }

   // sort by workspace name, workspace path, and project name
   if (!(def_workspace_flags & WORKSPACE_OPT_NO_SORT_PROJECTS)) {
      workspaceInfo._sort("",0,-1,compareWorkspaceInfo);
   }

   _str duplicate_captions:[];
   for (i:=0;i<workspaceInfo._length();++i) {
      // watch out for bad data
      if (workspaceInfo[i] == null) continue;

      // construct the caption for this item
      filename := projectname := caption := "";
      getWorkspaceProjectAndCaption(workspaceInfo[i], filename, projectname, caption);

      // watch out for missing caption (also implies missing workspace file name)
      if (caption == "") continue;

      // now get the rest of the info for the menu entry
      flags := 0;
      command := "";
      help_message := "";
      if (workspaceInfo[i].isFolder) {
         flags=MF_SUBMENU;
         command="";
         if (workspaceInfo[i].u.list._varformat()!=VF_ARRAY) {
            flags|=MF_GRAYED;
         }
         help_message="";
      }else{
         command="workspace-open "_maybe_quote_filename(filename);
         if (projectname != "") command :+= " "_maybe_quote_filename(projectname);
         help_message="Opens workspace "caption;
      }
      if (_workspace_filename!="" && _file_eq(filename,_workspace_filename)) {
         if (_file_eq(projectname,_project_name) || (projectname=="") != (_project_name=="")) {
            flags|=MF_CHECKED;
         }
      }
      if (!workspaceInfo[i].isFolder) {
         caption = _make_fhist_caption(caption,WKSPHIST_CATEGORY,projectname);
         if (duplicate_captions._indexin(caption)) {
            if (duplicate_captions:[caption] == command || (def_workspace_flags & WORKSPACE_OPT_NO_PROJECT_HIST)) {
               continue;
            }
         } else {
            duplicate_captions:[caption] = command;
         }
      }

      // insert the item into the menu
      int NewMenuHandle=_menu_insert(ParentMenuHandle,
                                     -1,
                                     flags,       // flags
                                     caption,     // caption
                                     command,     // command
                                     "",          // category
                                     "",          // help command
                                     help_message);

      // recursively add sub-menus
      if (workspaceInfo[i].isFolder) {
         if (workspaceInfo[i].u.list._varformat()==VF_ARRAY) {
            AddWorkspacesToMenu(NewMenuHandle, workspaceInfo[i].u.list, depth+1);
         }
      }
   }
}

