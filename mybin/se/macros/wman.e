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
#import "guiopen.e"
#import "listbox.e"
#import "main.e"
#import "menu.e"
#import "project.e"
#import "projutil.e"
#import "stdprocs.e"
#import "treeview.e"
#import "wkspace.e"
#endregion

#define LAST_TREE_INDEX ctltree1.p_user
#define IN_ON_CHANGE    ctldelete.p_user
#define LIST_MODIFIED   ctlopen.p_user

#define WORKSPACE_FOLDER_VCPP 'Visual C++ Workspaces'
#define WORKSPACE_FOLDER_CPP  'C/C++ Workspaces'
#define WORKSPACE_FOLDER_JAVA 'Java Workspaces'
#define WORKSPACE_FOLDER_SAMPLES 'Sample Workspaces'
#define WORKSPACE_FOLDER_TORNADO 'Tornado Workspaces'

void _RemoveFileFromWorkspaceManager(_str Filename)
{
   if (def_workspace_info._length()==0) {
      return;
   }
   Filename=_encode_vsenvvars(Filename,true,false);
   while(MaybeAddFile(def_workspace_info,Filename,false,true));
}

void _AddFilesToWorkspaceManager(_str Filename,_str FolderName='')
{
   if (def_workspace_info._length()==0) {
      def_workspace_info=null;
      InitTree(def_workspace_info);
   }
   Filename=_encode_vsenvvars(Filename,true,false);
   if (FolderName=='') {
      MaybeAddFile(def_workspace_info,Filename);
   }else {
      AddFile2(def_workspace_info,Filename,FolderName);
   }
}

static _str decode_caption(WORKSPACE_LIST &entry)
{
   if (!entry.caption._isempty() && !entry.filename._isempty() &&
       file_eq(entry.caption,entry.filename)) {
      return(_replace_envvars(entry.caption));
   }
   return(entry.caption);
}
static void AddFile2(WORKSPACE_LIST (&workspaceInfo)[],_str Filename,_str FolderName)
{
   int i;
   for (i=0;i<workspaceInfo._length();++i) {
      //if(workspaceInfo[i].isFolder) say('FolderName='FolderName' 'decode_caption(workspaceInfo[i]));
      if (workspaceInfo[i].isFolder &&
          // I think this should be case insensitive.  We may want this to use
          // file_eq.
          strieq(FolderName,decode_caption(workspaceInfo[i]))
          ) {
         MaybeAddFile(workspaceInfo[i].u.list,Filename);
         // For now, we don't need to recurse
         //AddFile2(workspaceInfo[i].u.list,Filename,FolderName);
      }
   }
}

/**
 *
 * @param workspaceInfo
 * @param Filename
 * @return Returns true if found file
 */
static boolean MaybeAddFile(WORKSPACE_LIST (&workspaceInfo)[],_str filename,boolean isFolder=false,boolean doDelete=false)
{
   int FirstFileIndex=-1;
   int i;
   for (i=0;i<workspaceInfo._length();++i) {
      if (!workspaceInfo[i].isFolder) {
         if (FirstFileIndex<0) FirstFileIndex=i;
         if (file_eq(filename,workspaceInfo[i].filename)) {
            if (doDelete) {
               _config_modify_flags(CFGMODIFY_DEFVAR);
               workspaceInfo._deleteel(i);
            }
            return(true);
         }
      } else {
         // IF this workspace is already in a folder
         if(MaybeAddFile(workspaceInfo[i].u.list,filename,true,doDelete)) {
            // We are done
            return(true);
         }
      }
   }
   if (isFolder || doDelete) {
      return(false);
   }
   if (FirstFileIndex<0) FirstFileIndex=0;
   _str ExistingCaption='';
   int len=workspaceInfo._length();
   workspaceInfo[len].caption=ExistingCaption;
   workspaceInfo[len].filename=filename;
   workspaceInfo[len].isFolder=0;
   _config_modify_flags(CFGMODIFY_DEFVAR);
   return(true);
}


static int GetFilesFromHistory(_str (&WorkspaceFiles)[])
{
   if (_default_option(VSOPTION_DONT_READ_CONFIG_FILES)) {
      return 0;
   }
   _str restore_filename=editor_name("r");
   if (restore_filename==''){
      restore_filename=editor_name('p'):+_WINDOW_CONFIG_FILE;
      if (restore_filename==''){
         return(0);
      }
   }
   int temp_view_id=0;
   int orig_view_id=0;
   typeless status=_open_temp_view(restore_filename,temp_view_id,orig_view_id);
   if (status) return(status);
   WorkspaceFiles=null;
   //Parse through the vrestore file real quick and just pick out the workspace
   //files.
   for (;;) {
      get_line(auto line);
      _str rtype;
      parse line with rtype line;
      if (rtype=='WORKSPACE:') {
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
         if (rtype=='SCREEN:') {
            count=1;
         }else{
            parse line with count .;
         }
         if (count=='' || !isinteger(count) || count==0) {
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
   show('-modal -xy _workspace_organize_form');
}

defeventtab _workspace_organize_form;

#define MIN_TREE_WIDTH 3480
#define PATH_SEP     '>>>'
#define NODE_SEP     '>*<'

void _workspace_organize_form.on_resize()
{
   int xbuffer=ctltree1.p_x;
   int clientwidth=_dx2lx(SM_TWIP,p_client_width);
   ctltree1.p_width=max(clientwidth-(ctlclose.p_width+(3*xbuffer)),MIN_TREE_WIDTH);
   ctlclose.p_x=ctltree1.p_x+ctltree1.p_width+xbuffer;
   ctlopen.p_x=ctlmove_up.p_x=ctlmove_down.p_x=ctladd_file.p_x=ctladd_folder.p_x=ctlmove.p_x=ctldelete.p_x/*=ctlscan.p_x*/=ctlclose.p_x;

   int clientheight=_dy2ly(SM_TWIP,p_client_height);
   int ybuffer=ctltree1.p_y;
   int HeightOfStuffAtBottom=ybuffer+ctlcaption.p_height+ybuffer+
                             ctlfilename.p_height+(ybuffer*2);
                             /*ctldescription_label.p_height+ybuffer+
                             ctldescription.p_height+ybuffer+
                             (clientheight intdiv 5);*/
   ctltree1.p_height=max(clientheight-HeightOfStuffAtBottom,ctlmove_down.p_y+(ctlmove_down.p_height intdiv 2));
   ctlcaption.p_y=ctltree1.p_y+ctltree1.p_height+ybuffer;

   int CapLabelY=ctlcaption.p_y;
   int diff=ctlcaption.p_height-ctlcaption_label.p_height;
   if (diff>0) {
      diff=diff intdiv 2;
      CapLabelY+=diff;
   }
   ctlcaption_label.p_y=CapLabelY;
   ctlcaption_label.p_visible=ctldescription_label.p_visible=
      ctlfilename_label.p_visible=0;

   ctlfilename.p_y=ctlcaption.p_y+ctlcaption.p_height+ybuffer;
   int FilenameLabelY=ctlfilename.p_y;
   diff=ctlfilename.p_height-ctlfilename_label.p_height;
   if (diff>0) {
      diff=diff intdiv 2;
      FilenameLabelY+=diff;
   }
   ctlfilename_label.p_y=FilenameLabelY;
   ctlfilename.p_width=(ctltree1.p_x + ctltree1.p_width) - ctlfilename.p_x;
   ctlcaption.p_width=ctlfilename.p_width;

   ctldescription.p_y=ctldescription_label.p_y=p_active_form.p_height+200;

   ctlcaption_label.p_visible=ctldescription_label.p_visible=
      ctlfilename_label.p_visible=1;
}

static void InitTree(WORKSPACE_LIST (&workspaceInfo)[])
{
   _config_modify_flags(CFGMODIFY_DEFVAR);
   workspaceInfo=null;

   maybeAddSampleProjectsToTree(workspaceInfo);
}

void maybeAddSampleProjectsToTree(WORKSPACE_LIST (&workspaceInfo)[])
{
   if( def_workspace_options&WORKSPACE_OPT_COPYSAMPLES ) {
      // we want to insert this at the very beginning
      WORKSPACE_LIST samples;
      samples.isFolder = 1;
      samples.caption = WORKSPACE_FOLDER_SAMPLES;

      workspaceInfo._insertel(samples, 0);

      _str samplesPath;
#if __UNIX__
      samplesPath = _localSampleProjectsPath();
      _AddFilesToWorkspaceManager(samplesPath:+VSSAMPLEWORKSPACECPP:+"cpp.vpw",WORKSPACE_FOLDER_SAMPLES);
      _AddFilesToWorkspaceManager(samplesPath:+VSSAMPLEWORKSPACEJAVA:+"java.vpw",WORKSPACE_FOLDER_SAMPLES);
#else
      samplesPath=_localSampleProjectsPath();
      _AddFilesToWorkspaceManager(samplesPath'DevStudio\vc9\VS2008.sln',WORKSPACE_FOLDER_SAMPLES);
      _AddFilesToWorkspaceManager(samplesPath'DevStudio\vc10\VS2010.sln',WORKSPACE_FOLDER_SAMPLES);
      _AddFilesToWorkspaceManager(samplesPath'ucpp\cpp.vpw',WORKSPACE_FOLDER_SAMPLES);
      _AddFilesToWorkspaceManager(samplesPath:+VSSAMPLEWORKSPACEJAVA:+"java.vpw",WORKSPACE_FOLDER_SAMPLES);
#endif
   }
}

/**
 * Return the local path the sample projects.
 */
_str _localSampleProjectsPath()
{
   return(_ConfigPath():+'SampleProjects':+FILESEP);
}

/**
 * Return the global path the sample projects.
 */
_str _globalSampleProjectsPath()
{
   return(get_env('VSROOT'):+"SampleProjects":+FILESEP);
}

void ctlcaption.on_change()
{
   _str NewCaption=p_text;
   int wid=p_window_id;
   p_window_id=ctltree1;
   int index=_TreeCurIndex();
   if (index>-1) {
      _TreeSetCaption(index,NewCaption);
      if (!IN_ON_CHANGE) LIST_MODIFIED=1;
   }
   p_window_id=wid;
}

void ctlfilename.on_change()
{
   _str Filename=p_text;
   int wid=p_window_id;
   p_window_id=ctltree1;
   int index=_TreeCurIndex();
   if (index>-1) {
      SetFilename(index,Filename);
      if (!IN_ON_CHANGE) LIST_MODIFIED=1;
   }
   p_window_id=wid;
}

#define DESCRIPTION_LENGTH_LIMIT 1024

static _str CommandsValidWhenFullTable:[]={
   "cursor-up"                 => '',
   "cursor-down"               => '',
   "cursor-left"               => '',
   "cursor-right"              => '',
   "page-up"                   => '',
   "page-down"                 => '',
   "rubout"                    =>'',
   "linewrap-rubout"           =>'',
   "linewrap-delete-char"      =>'',
   "vi-forward-delete-char"    =>'',
   "delete-char"               =>'',
   "cut-line"                  =>'',
   "join-line"                 =>'',
   "cut"                       =>'',
   "delete-line"               =>'',
   "brief-delete"              =>'',
   "find-next"                 =>'',
   "search-again"              =>'',
   "ispf-rfind"                =>'',
   "find-prev"                 =>'',
   "undo"                      =>'',
   "undo-cursor"               =>'',
   "select-line"               =>'',
   "brief-select-line"         =>'',
   "select-char"               =>'',
   "brief-select-char"         =>'',
   "cua-select"                =>'',
   "deselect"                  =>'',
   "copy-to-clipboard"         =>'',
   "copy-word"                 =>'',
   "bottom-of-buffer"          =>'',
   "top-of-buffer"             =>'',
   "page-up"                   =>'',
   "vi-page-up"                =>'',
   "page-down"                 =>'',
   "vi-page-down"              =>'',
   "cursor-left"               =>'',
   "vi-cursor-left"            =>'',
   "cursor-right"              =>'',
   "vi-cursor-right"           =>'',
   "cursor-up"                 =>'',
   "vi-prev-line"              =>'',
   "cursor-down"               =>'',
   "vi-next-line"              =>'',
   "begin-line"                =>'',
   "begin-line-text-toggle"    =>'',
   "brief-home"                =>'',
   "vi-begin-line"             =>'',
   "vi-begin-line-insert-mode" =>'',
   "brief-end"                 =>'',
   "end-line"                  =>'',
   "vi-end-line"               =>'',
   "vi-end-line-append-mode"   =>'',
   "mou-click"                 =>'',
   "mou-extend-selection"      =>'',
   "mou-select-word"           =>'',
   "mou-select-line"           =>'',
   "cut-end-line"              =>'',
   "cut-word"                  =>'',
   "delete-word"               =>'',
   "prev-word"                 =>'',
   "next-word"                 =>'',
   "find-matching-paren"       =>'',
   "search-forward"            =>'',
   "search-backward"           =>'',
   "gui-find-backward"         =>'',
   "right-side-of-window"      =>'',
   "left-side-of-window"       =>'',
   "vi-restart-word"           =>'',
   "vi-begin-next-line"        =>'',
   "insert-toggle"             =>''
};

void ctldescription.\0-\129()
{
   boolean oldModify=p_modify;
   p_modify=0;
   _str lastevent=last_event();
   int key_index=event2index(lastevent);
   int name_index=eventtab_index(_default_keys,_default_keys,key_index);
   _str command_name=name_name(name_index);

   if (p_buf_size>DESCRIPTION_LENGTH_LIMIT) {
      if (command_name=='' ||
          !CommandsValidWhenFullTable._indexin(command_name)) {
         _message_box(nls("Descriptions cannot currently exceed %s1 bytes",DESCRIPTION_LENGTH_LIMIT));
         return;
      }
   }
   if (command_name!='') {
      int command_index=find_index(command_name);
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

   //If we are bringing the dialog up for the first time, set things up.
   if (def_workspace_info==null) {
      InitTree(def_workspace_info);
   }

   int wid=p_window_id;
   p_window_id=ctltree1;
   int NewIndex=_TreeAddItem(TREE_ROOT_INDEX,"All Workspaces",TREE_ADD_AS_CHILD,_pic_fldclos,_pic_fldopen,TREE_NODE_EXPANDED);

   FillInWorkspaceTree(def_workspace_info,NewIndex);
   ctltree1.call_event(CHANGE_SELECTED,ctltree1._TreeCurIndex(),ctltree1,ON_CHANGE,'W');

   // expanded whatever nodes were expanded in a previous run of this form
   restoreExpandedNodes();
   _TreeSizeColumnToContents(0);

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
   ctlopen.p_width = ctladd_folder.p_width = ctlmove.p_width = ctlmove_up.p_width = ctlmove_down.p_width =
      ctldelete.p_width = ctlclose.p_width = ctladd_file.p_width;

   ctltree1.p_width = ctlopen.p_x - 120 - ctltree1.p_x;
}

static void saveExpandedNodes()
{
   int wid = p_window_id;
   p_window_id = ctltree1;

   // get our list of expanded nodes
   expandedList := findExpandedChildren(TREE_ROOT_INDEX, '');

   // save it for the future
   _append_retrieve(0, expandedList, p_active_form.p_name'.ctltree1');

   p_window_id = wid;
}

static _str findExpandedChildren(int parent, _str parentPath)
{
   expandedList := '';
   int expanded;

   if (parentPath != '') parentPath :+= PATH_SEP;

   // go through the children and see what is expanded
   child := _TreeGetFirstChildIndex(parent);
   while (child > 0) {
      _TreeGetInfo(child, expanded);
      if (expanded == TREE_NODE_EXPANDED) {
         thisPath := parentPath :+ _TreeGetCaption(child);
         expandedList :+= thisPath;

         childrenList := findExpandedChildren(child, thisPath);
         if (childrenList != '') {
            expandedList :+= NODE_SEP :+ childrenList;
         }
      } 

      child = _TreeGetNextSiblingIndex(child);
   }

   return expandedList;
}

static void restoreExpandedNodes()
{
   int wid = p_window_id;
   _control ctltree1;
   p_window_id = ctltree1;

   // first we collapse everything
   _TreeCollapseAll();

   expandedList := ctltree1._retrieve_value();
   
   while (expandedList != '') {
      path := '';
      parse expandedList with path NODE_SEP expandedList;

      node := TREE_ROOT_INDEX;
      while (path != '') {
         caption := '';
         parse path with caption PATH_SEP path;
         
         node = _TreeSearch(node, caption);
         if (node < 0) path = '';
      }

      if (node > 0) {
         _TreeSetInfo(node, TREE_NODE_EXPANDED);
      }
   }

   p_window_id = wid;
}

static _str FormatFilename(_str Filename)
{
   _str PathFirstName=_strip_filename(Filename,'P');
   PathFirstName=PathFirstName"\t"PathFirstName=_strip_filename(Filename,'M');
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
   int i=0;
   int AddFlags=TREE_ADD_AS_CHILD;
   int LastTreeControlIndex=TreeControlParentIndex;
   for (i=0;i<workspaceInfo._length();++i) {
      int pic1=_pic_file;
      int pic2=_pic_file;
      int moreflags=0;

      _str filename=workspaceInfo[i].filename;
      _str caption=workspaceInfo[i].caption;
      if (filename==null) {
         filename='';
      }
      if (caption==null) {
         caption='';
      }
      if (filename!='') {
         if (file_eq(filename,caption)) {
            filename=_replace_envvars(filename);
            caption=_replace_envvars(caption);
         } else {
            filename=_replace_envvars(filename);
         }
      }
      if (caption=='') {
         caption=filename;
      }

      if (workspaceInfo[i].isFolder) {
         pic1=_pic_fldclos;
         pic2=_pic_fldopen;
      }else{
         if (file_eq(filename,_workspace_filename) &&
             filename!='') {
            moreflags=TREENODE_BOLD;
         }
         //Filename=FormatFilename(Filename);
      }
      if (AddFlags==TREE_ADD_AS_CHILD) {
         int state=0;
         _TreeGetInfo(LastTreeControlIndex,state);
         if (state!=TREE_NODE_EXPANDED) {
            _TreeSetInfo(LastTreeControlIndex,TREE_NODE_EXPANDED);
         }
      }
      LastTreeControlIndex=_TreeAddItem(LastTreeControlIndex,caption,AddFlags,pic1,pic2,TREE_NODE_LEAF,moreflags);
      if (!workspaceInfo[i].isFolder) {
         SetFilename(LastTreeControlIndex,filename);
         SetDescription(LastTreeControlIndex,workspaceInfo[i].u.description);
      }
      if (workspaceInfo[i].u.list._varformat()==VF_ARRAY) {
         FillInWorkspaceTree(workspaceInfo[i].u.list,LastTreeControlIndex);
      }
      AddFlags=0;
   }
}

void ctladd_folder.lbutton_up()
{
   ctltree1.AddFolderButton();
}

void ctladd_file.lbutton_up()
{
   ctltree1.AddFileButton();
}

static void AddFileButton()
{
   int index=_TreeCurIndex();
   //int depth=_TreeGetDepth(index);
   int ParentState=0, bm1=0, bm2=0;
   _TreeGetInfo(index,ParentState,bm1,bm2);
   int ParentIndex=-1;
   int Flags=0;
   int RelationIndex=-1;
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
   _str WorkspaceFilename=_OpenDialog('-new -mdi -modal',
                             'Add Workspace File',
                             '',     // Initial wildcards
                             format_list,  // file types
                             OFN_FILEMUSTEXIST,
                             WORKSPACE_FILE_EXT,      // Default extensions
                             '',      // Initial filename
                             '',      // Initial directory
                             '',      // Reserved
                             "Standard Open dialog box"
                            );
   if (WorkspaceFilename=='') return;
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
   int result=_message_box(nls("Do you wish to open this workspace now?"),'',MB_YESNOCANCEL);
   LIST_MODIFIED=1;
   _set_focus();
   if (result==IDYES) {
      ctlopen.call_event(ctlopen,LBUTTON_UP);
   }
}

/*
//5:29:53 PM 9/2/00
//Was going to do this, but I am not sure if INS should add a folder or a file.
void ctltree1.'ins'()
{
   AddFolderButton();
}*/

static void AddFolderButton()
{
   int index=_TreeCurIndex();
   //int depth=_TreeGetDepth(index);
   int ParentState=0, bm1=0, bm2=0;
   _TreeGetInfo(index,ParentState,bm1,bm2);
   _str ParentCaption='';
   int ParentIndex=-1;
   if (bm1==_pic_fldclos || bm1==_pic_fldopen) {
      ParentCaption=_TreeGetCaption(index);
      ParentIndex=index;
   }else{
      ParentIndex=_TreeGetParentIndex(index);
      ParentCaption=_TreeGetCaption(ParentIndex);
   }
   typeless result=show('-modal _textbox_form',
               'New Folder Name',
               0,   // flags
               '',                           // width ('' or 0 uses default)
               'New Folder Name dialog',     // Optional help item
               '',                           // Buttons and captions
               '',                           // Retrieve name
               'New Folder Name:'
               );
   if (result=='') return;
   if (_param1=='') return;
   _str NewFolderName=_param1;

   int NewFolderIndex=_TreeAddItem(ParentIndex,NewFolderName,TREE_ADD_AS_CHILD,_pic_fldclos,_pic_fldopen,TREE_NODE_LEAF);
   if (ParentState!=TREE_NODE_EXPANDED) {
      _TreeSetInfo(ParentIndex,TREE_NODE_EXPANDED);
   }
   _TreeSetCurIndex(NewFolderIndex);
   LIST_MODIFIED=1;
   _set_focus();
}

static void EnabledOpenButton()
{
   int index=ctltree1._TreeCurIndex();
   int state=0, bm1=0, bm2=0, flags=0;
   ctltree1._TreeGetInfo(index,state,bm1,bm2,flags);
   ctlopen.p_enabled=(bm1==_pic_file && !(flags&TREENODE_BOLD));
}

static void EnableDeleteButton()
{
   // determine if this is or contains the current workspace
   int index=ctltree1._TreeCurIndex();
   int state=0, bm1=0, bm2=0, flags=0;
   ctltree1._TreeGetInfo(index,state,bm1,bm2,flags);
   if (bm1 == _pic_file) {

   }

   int CurIndex=_TreeCurIndex();
   if ( CurIndex==_TreeGetFirstChildIndex(TREE_ROOT_INDEX) ||
        FindWorkspaceInTree(CurIndex,_workspace_filename) > 0 ) {
      ctldelete.p_enabled=0;
   }else ctldelete.p_enabled=1;
}

static boolean isFolder(int index) {
   if (index==TREE_ROOT_INDEX) return true;
   int child_index=_TreeGetFirstChildIndex(index);
   if (child_index>=0) {
      return true;
   }
   int state=0, bm1=0, bm2=0, flags=0;
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
   if (file_eq(thisFilename,filename)) {
      return index;
   }
   return -1;
}

void ctltree1.on_change(int reason,int index)
{
   if (IN_ON_CHANGE==1) return;
   IN_ON_CHANGE=1;
   switch (reason) {
   case CHANGE_SELECTED:
      EnabledOpenButton();
      EnableMoveButtons();
      EnableDeleteButton();
      ctldescription.SaveDescriptionText();
      typeless status=SetFilenameAndDescription();
      if (status) {
         _TreeSetCurIndex(LAST_TREE_INDEX);
         IN_ON_CHANGE=0;
         return;
      }
      EnableDescriptionEtc();
      break;
   case CHANGE_LEAF_ENTER:
      ctlopen.call_event(ctlopen,LBUTTON_UP);
      return;//Have to return here because dialog is deleted
   }
   LAST_TREE_INDEX=_TreeCurIndex();
   IN_ON_CHANGE=0;
}

static void SaveDescriptionText()
{
   if (LAST_TREE_INDEX=='') {
      return;
   }
   _str text="";
   _getMacroText(text);
   int wid=p_window_id;
   p_window_id=ctltree1;
   SetDescription(LAST_TREE_INDEX,text);
   LIST_MODIFIED=1;
   p_window_id=wid;
}

static int SetFilenameAndDescription()
{
   int CurIndex=_TreeCurIndex();
   ctlcaption.p_text=_TreeGetCaption(CurIndex);
   int state=0, bm1=0, bm2=0, flags=0;
   _TreeGetInfo(CurIndex,state,bm1,bm2);
   if (bm1==_pic_file) {
      ctlfilename.p_text=GetFilename(CurIndex);
      ctldescription._setMacroText(GetDescription(CurIndex));
   }else ctldescription._lbclear();
   return(0);
}

static void EnableDescriptionEtc()
{
   int CurIndex=_TreeCurIndex();
   int state=0, bm1=0, bm2=0, flags=0;
   _TreeGetInfo(CurIndex,state,bm1,bm2);
   if (CurIndex==_TreeGetFirstChildIndex(TREE_ROOT_INDEX)) {
      ctlcaption.p_enabled=0;
   }else{
      ctlcaption.p_enabled=1;
   }
   if (bm1==_pic_fldclos || bm1==_pic_fldopen) {
      ctlfilename.p_enabled=0;
      ctlfilename.p_text='';
      ctldescription_label.p_enabled=ctldescription.p_enabled=0;
   }else{
//    ctlfilename.p_enabled=1;
      ctlfilename.p_enabled=0;
      ctldescription_label.p_enabled=ctldescription.p_enabled=1;
   }
}

static void EnableMoveButtons()
{
   int CurIndex=_TreeCurIndex();
   int AllIndex=_TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   //int ParentIndex=_TreeGetParentIndex(CurIndex);
   if (CurIndex==AllIndex) {
      ctlmove.p_enabled=0;
   }else{
      ctlmove.p_enabled=1;
   }
   if (CurIndex==AllIndex ||
       _TreeGetPrevIndex(CurIndex)==AllIndex) {
      ctlmove_up.p_enabled=0;
   }else{
      ctlmove_up.p_enabled=1;
   }
   if (CurIndex==AllIndex ||
       _TreeGetNextIndex(CurIndex)<0) {
      ctlmove_down.p_enabled=0;
   }else{
      ctlmove_down.p_enabled=1;
   }
   int state=0, bm1=0, bm2=0, flags=0;
   _TreeGetInfo(CurIndex,state,bm1,bm2);
   if ( (bm1==_pic_fldopen || bm1==_pic_fldclos) &&
         _TreeGetNextSiblingIndex(CurIndex)<0) {
      ctlmove_down.p_enabled=0;
   }
}

void ctlopen.lbutton_up()
{
   int wid=p_window_id;
   p_window_id=ctltree1;
   int index=_TreeCurIndex();
   int state=0, bm1=0, bm2=0, flags=0;
   _TreeGetInfo(index,state,bm1);
   if (bm1!=_pic_file) {
      //This can happen from a call event.
      return;
   }
   _str WorkspaceFilename=GetFilename(index);
   if (!file_exists(WorkspaceFilename)) {
      _message_box(nls("File '%s1' does not exist",WorkspaceFilename));
      p_window_id=wid;
      return;
   }
   p_window_id=wid;
   //p_active_form._delete_window();
   ctlclose.call_event(ctlclose,LBUTTON_UP);
   workspace_open(WorkspaceFilename);
}

void ctlclose.lbutton_up()
{
   int wid=p_window_id;
   p_window_id=ctltree1;
   int AllWorkspaceIndex=_TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   ctltree1.call_event(CHANGE_SELECTED,ctltree1._TreeCurIndex(),ctltree1,ON_CHANGE,'W');
   if (LIST_MODIFIED==1) {
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
   _str UserInfo=_TreeGetUserInfo(index);
   _str Filename, Description;
   parse UserInfo with Filename "\1" Description;
   return(Filename);
}

static _str GetDescription(int index)
{
   _str UserInfo=_TreeGetUserInfo(index);
   _str Filename, Description;
   parse UserInfo with Filename "\1" Description;
   return(Description);
}

static void SetFilename(int index,_str Filename)
{
   _str UserInfo=_TreeGetUserInfo(index);
   _str OldFilename, Description;
   parse UserInfo with OldFilename "\1" Description;
   _TreeSetUserInfo(index,Filename"\1"Description);
}

static void SetDescription(int index,_str Description)
{
   if (Description._isempty()) Description='';
   _str UserInfo=_TreeGetUserInfo(index);
   _str Filename, OldDescription;
   parse UserInfo with Filename "\1" OldDescription;
   _TreeSetUserInfo(index,Filename"\1"Description);
}

void GetTreeData(WORKSPACE_LIST (&WorkspaceInfo)[],int ArrayIndex,int TreeControlIndex)
{
   for (;;) {
      if (TreeControlIndex<0) return;
      _str caption=_TreeGetCaption(TreeControlIndex);
      int state=0, bm1=0, bm2=0, flags=0;
      _TreeGetInfo(TreeControlIndex,state,bm1,bm2);
      if (bm1==_pic_fldclos || bm1==_pic_fldopen) {
         WorkspaceInfo[ArrayIndex].isFolder=1;
         WorkspaceInfo[ArrayIndex].caption=caption;
      }else{
         WorkspaceInfo[ArrayIndex].isFolder=0;
         if (caption._isempty()) caption='';
         _str filename=GetFilename(TreeControlIndex);
         if (file_eq(filename,caption)) {
            filename=_encode_vsenvvars(filename,true,false);
            caption=_encode_vsenvvars(filename,true,false);
         } else {
            filename=_encode_vsenvvars(filename,true,false);
         }
         WorkspaceInfo[ArrayIndex].caption=caption;
         WorkspaceInfo[ArrayIndex].filename=filename;
         WorkspaceInfo[ArrayIndex].u.description=GetDescription(TreeControlIndex);
      }
      int cIndex=_TreeGetFirstChildIndex(TreeControlIndex);
      if (cIndex>-1) {
         GetTreeData(WorkspaceInfo[ArrayIndex].u.list,0,cIndex);
      }
      TreeControlIndex=_TreeGetNextSiblingIndex(TreeControlIndex);
      ++ArrayIndex;
   }
}

void ctlmove.lbutton_up()
{
   typeless result=show('-modal _workspace_organize_move_form',ctltree1,ctltree1._TreeCurIndex());
   if (result!='') {
      int index=result;
      int wid=p_window_id;
      p_window_id=ctltree1;
      //index=_TreeGetParentIndex(index);
      //Ok, now we just have to copy everything from the one to the other.
      int OldIndex=_TreeCurIndex();
      MoveTree(OldIndex,index);
      //_TreeSetCurIndex(index);
      _TreeDelete(OldIndex);
      LIST_MODIFIED=1;
      ctltree1.call_event(CHANGE_SELECTED,ctltree1._TreeCurIndex(),ctltree1,ON_CHANGE,'W');
      p_window_id=wid;
   }
   ctltree1._set_focus();
}

static void MoveTree(int FromIndex,int ToIndex,boolean TraverseSiblings=false)
{
   int NewParentIndex=ToIndex;
   int first=1;
   for (;;) {
      if (FromIndex<0) break;
      _str Caption=_TreeGetCaption(FromIndex);
      int state=0, bm1=0, bm2=0, flags=0;
      _TreeGetInfo(FromIndex,state,bm1,bm2,flags);
      typeless Data=_TreeGetUserInfo(FromIndex);
      int NewIndex=_TreeAddItem(ToIndex,Caption,TREE_ADD_AS_CHILD,bm1,bm2,state,flags,Data);
      if (first && !TraverseSiblings) {
         //This should be the first copy
         _TreeSetCurIndex(NewIndex);
      }

      _TreeGetInfo(ToIndex,state);
      if (state!=TREE_NODE_EXPANDED) _TreeSetInfo(ToIndex,TREE_NODE_EXPANDED);

      int ChildIndex=_TreeGetFirstChildIndex(FromIndex);
      if (ChildIndex>-1) {
         MoveTree(ChildIndex,NewIndex,true);
      }
      if (!TraverseSiblings) break;
      FromIndex=_TreeGetNextSiblingIndex(FromIndex);
      first=0;
   }
}

void ctlmove_up.lbutton_up()
{
   int wid=p_window_id;
   p_window_id=ctltree1;
   int CurIndex=_TreeCurIndex();
   int CurParentIndex=_TreeGetParentIndex(CurIndex);

   int AboveIndex;
   int state=0, bm1=0, bm2=0, flags=0;
   _TreeGetInfo(CurIndex,state,bm1,bm2);
   if (bm1==_pic_fldclos || bm1==_pic_fldopen) {
      AboveIndex=_TreeGetPrevSiblingIndex(CurIndex);
      if (AboveIndex<0) {
         AboveIndex=_TreeGetPrevIndex(CurIndex);
         if (AboveIndex<0) return;
      }
   }else{
      AboveIndex=_TreeGetPrevIndex(CurIndex);
   }

   int AboveParentIndex=_TreeGetParentIndex(AboveIndex);
   int AddFlags=0;
   if (AboveParentIndex==CurParentIndex) {
      AddFlags=TREE_ADD_BEFORE;
   }else{
      if (AboveIndex==CurParentIndex) {
         AboveIndex=_TreeGetPrevIndex(AboveIndex);
         if (AboveIndex<0) return;
      }
      _TreeGetInfo(AboveIndex,state,bm1,bm2);
      if (bm1==_pic_file) {
         AddFlags=0;//Add after AboveIndex
      }else if (bm1==_pic_fldclos || bm1==_pic_fldopen) {
         AddFlags=0;//Add after AboveIndex
         int index=_TreeGetFirstChildIndex(AboveIndex);
         if (index>-1) AboveIndex=index;
      }
   }
   _TreeGetInfo(CurIndex,state,bm1,bm2,flags);
   _str Caption=_TreeGetCaption(CurIndex);
   typeless UserInfo=_TreeGetUserInfo(CurIndex);
   int NewItem=_TreeAddItem(AboveIndex,Caption,AddFlags,bm1,bm2,state,flags,UserInfo);
   //4:32:07 PM 9/22/2000
   //Order is important here:  Have to be sure the user info is set before
   //we set the current index and cause an on_change
   _TreeSetCurIndex(NewItem);
   if (bm1==_pic_fldclos || bm1==_pic_fldopen) {
      int ChildIndex=_TreeGetFirstChildIndex(CurIndex);
      MoveTree(ChildIndex,NewItem,true);
   }
   _TreeDelete(CurIndex);
   _set_focus();
   LIST_MODIFIED=1;
   EnableMoveButtons();
   p_window_id=wid;
}

void ctlmove_down.lbutton_up()
{
   int wid=p_window_id;
   p_window_id=ctltree1;
   int CurIndex=_TreeCurIndex();
   int CurParentIndex=_TreeGetParentIndex(CurIndex);
   int state=0, bm1=0, bm2=0, flags=0;
   _TreeGetInfo(CurIndex,state,bm1,bm2);
   int BelowIndex=0;
   if (bm1==_pic_fldclos || bm1==_pic_fldopen) {
      BelowIndex=_TreeGetNextSiblingIndex(CurIndex);
      if (BelowIndex<0) {
         BelowIndex=_TreeGetNextIndex(CurIndex);
         if (BelowIndex<0) return;
      }
   }else{
      BelowIndex=_TreeGetNextIndex(CurIndex);
   }
   int BelowParentIndex=_TreeGetParentIndex(BelowIndex);
   int AddFlags=0;
   if (BelowParentIndex==CurParentIndex && (bm1==_pic_fldclos||bm1==_pic_fldopen)) {
      AddFlags=0;
   }else{
      _TreeGetInfo(BelowIndex,state,bm1,bm2);
      if (bm1==_pic_file) {
         AddFlags=0;
      }else if (bm1==_pic_fldclos || bm1==_pic_fldopen) {
         int index=_TreeGetFirstChildIndex(BelowIndex);
         if (index>-1) {
            BelowIndex=index;
            AddFlags=TREE_ADD_BEFORE;
         }else {
            AddFlags=TREE_ADD_AS_CHILD;
         }
      }
   }
   _TreeGetInfo(CurIndex,state,bm1,bm2,flags);
   _str Caption=_TreeGetCaption(CurIndex);
   typeless UserInfo=_TreeGetUserInfo(CurIndex);
   int NewItem=_TreeAddItem(BelowIndex,Caption,AddFlags,bm1,bm2,state,flags,UserInfo);
   //4:32:07 PM 9/22/2000
   //Order is important here:  Have to be sure the user info is set before
   //we set the current index and cause an on_change
   _TreeSetCurIndex(NewItem);
   if (bm1==_pic_fldclos || bm1==_pic_fldopen) {
      int ChildIndex=_TreeGetFirstChildIndex(CurIndex);
      MoveTree(ChildIndex,NewItem,true);
   }
   _TreeDelete(CurIndex);
   _set_focus();
   LIST_MODIFIED=1;
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

static void DeleteButton()
{
   if (!ctldelete.p_enabled) {
      _beep();
      return;
   }
   LAST_TREE_INDEX='';
   int wid=p_window_id;
   p_window_id=ctltree1;
   int index=_TreeCurIndex();
   DeleteFromTree(index);
   p_window_id=wid;
   ctltree1._set_focus();
}

static void DeleteFromTree(int index)
{
   int state=0, bm1=0, bm2=0, flags=0;
   _TreeGetInfo(index,state,bm1,bm2);
   if (bm1==_pic_file) {
      MaybeDeleteWorkspaceFromTree(index);
   }else{
      MaybeDeleteFolderFromTree(index);
   }
}

static int MaybeDeleteFolderFromTree(int index)
{
   _str FolderFilename=_TreeGetCaption(index);
   int result=_message_box(nls("Do you wish to remove the folder '%s1' from your All Workspaces menu?",FolderFilename),'',MB_YESNOCANCEL);
   if (result!=IDYES) {
      return(COMMAND_CANCELLED_RC);
   }
   int ChildIndex=_TreeGetFirstChildIndex(index);
   for (;;) {
      if (ChildIndex<0) break;
      int NextIndex=_TreeGetNextSiblingIndex(ChildIndex);
      int state=0, bm1=0, bm2=0, flags=0;
      _TreeGetInfo(ChildIndex,state,bm1,bm2);
      if (bm1==_pic_file) {
         MaybeDeleteWorkspaceFromTree(ChildIndex,false);
      }else{
         int status=MaybeDeleteFolderFromTree(ChildIndex);
         if (status) return(status);
      }
      ChildIndex=NextIndex;
   }
   _TreeDelete(index);
   return(0);
}

static void MaybeDeleteWorkspaceFromTree(int index,boolean GiveListWarning=true)
{
   _str WorkspaceFilename=GetFilename(index);
   if (GiveListWarning) {
      int result=_message_box(nls("Do you wish to remove '%s1' from your All Workspaces menu?",WorkspaceFilename),'',MB_YESNOCANCEL);
      if (result!=IDYES) {
         return;
      }
   }
   int result=_message_box(nls("Do you wish to permamently delete files associated with the workspace '%s1'?\n\nWarning: All projects in the workspace will be deleted.\n\nNote: No source files will be deleted.",WorkspaceFilename),'',MB_YESNO);
   if (result==IDYES) {
      if (file_eq(WorkspaceFilename,_workspace_filename)) {
         workspace_close();
      }
      _str Files[]=null;
      _GetWorkspaceFiles(WorkspaceFilename,Files);
      _str WorkspacePath=_strip_filename(WorkspaceFilename,'N');
      //Delete all the project files
      int i;
      for (i=0;i<Files._length();++i) {
         delete_file(absolute(Files[i],WorkspacePath));
      }
      //Delete the tag file
      delete_file(_strip_filename(WorkspaceFilename,'E'):+TAG_FILE_EXT);
      // Delete the workspace state (history) file
      delete_file(_strip_filename(WorkspaceFilename,'E'):+WORKSPACE_STATE_FILE_EXT);
      //Delete the workspace file
      delete_file(VSEWorkspaceFilename(WorkspaceFilename));
   }
   _menu_remove_workspace_hist(WorkspaceFilename,false);
   _TreeDelete(index);
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
      int wid=p_window_id;
      p_window_id=ParentTreeWID;
      int state=0, bm1=0, bm2=0, flags=0;
      _TreeGetInfo(ParentTreeIndex,state,bm1,bm2);
      if ((bm1==_pic_fldclos || bm1==_pic_fldopen) &&
          ParentTreeIndex!=ExcludeId) {
         _str Caption=_TreeGetCaption(ParentTreeIndex);
         int NewTreeNewIndex=NewTreeWid._TreeAddItem(NewTreeParentIndex,Caption,TREE_ADD_AS_CHILD,_pic_fldclos,_pic_fldopen,TREE_NODE_LEAF,0,ParentTreeIndex);
         NewTreeWid._TreeGetInfo(NewTreeParentIndex,state);
         if (state!=TREE_NODE_EXPANDED) NewTreeWid._TreeSetInfo(NewTreeParentIndex,TREE_NODE_EXPANDED);
         int cindex=_TreeGetFirstChildIndex(ParentTreeIndex);
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
   ctlok.p_y=ctltree1.p_y+ctltree1.p_height+ybuffer;
   ctlok.p_next.p_y=ctlok.p_y;
}

void _AddWorkspaceTreeToMenu()
{
   int menu_handle=_mdi.p_menu_handle;
   if (!menu_handle) return;

   int AllWorkspacesHandle=0;
   int itempos=0;
   int status=_menu_find(menu_handle, "AllWorkspaces", AllWorkspacesHandle,
                     itempos, "C");
   if (!status) {
      _menu_delete(AllWorkspacesHandle,itempos);
   }
   status=_menu_find(menu_handle,"project-edit",AllWorkspacesHandle,itempos,'M');
   if (status) {
      return;
   }
   //status=_menu_add_hist(filename,_mdi.p_menu_handle,'&Project','wkspchist','workspace-open','ncw|wkspcopen',WKSPCHIST_HELP,WKSPCHIST_MESSAGE);

   int flags=MF_SUBMENU;
   int submenu_handle=_menu_insert(AllWorkspacesHandle,
                                    -1,
                                    flags,       // flags
                                    "&All Workspaces",
                                    '',   // command
                                    "AllWorkspaces",    // category
                                    "",  // help command
                                    ''       // help message
                                    );
   AddWorkspacesToMenu(submenu_handle,def_workspace_info);
   // Insert the menu separator if it is not already there.
   _str dash_category=WKSPHIST_CATEGORY;
   int dash_mh=0, dash_pos=0;
   status=_menu_find(menu_handle,dash_category,dash_mh,dash_pos,'c');
   if (status) {
      int temp_handle=0;
      _menu_find(menu_handle, "AllWorkspaces", temp_handle,itempos, "C");
      _menu_insert(temp_handle,itempos,MF_ENABLED,'-','',dash_category);
   }
}

static void AddWorkspacesToMenu(int ParentMenuHandle,WORKSPACE_LIST workspaceInfo[])
{
   if (def_workspace_info._length()==0) {
      def_workspace_info=null;
      InitTree(def_workspace_info);
      workspaceInfo=def_workspace_info;
   }
   int i;
   for (i=0;i<workspaceInfo._length();++i) {
      int flags=0;
      _str command='';
      _str help_message='';
      _str caption=workspaceInfo[i].caption;
      _str filename=workspaceInfo[i].filename;
      if (filename==null) {
         filename='';
      }
      if (caption==null) {
         caption='';
      }
      if (filename!='') {
         if (file_eq(filename,caption)) {
            filename=_replace_envvars(filename);
            caption=_replace_envvars(caption);
         } else {
            filename=_replace_envvars(filename);
         }
      }
      if (caption=='') {
         caption=filename;
      }
      if (workspaceInfo[i].isFolder) {
         flags=MF_SUBMENU;
         command='';
         if (workspaceInfo[i].u.list._varformat()!=VF_ARRAY) {
            flags|=MF_GRAYED;
         }
         help_message='';
      }else{
         command='workspace-open 'filename;
         help_message='Opens workspace 'caption;
      }
      if (_workspace_filename!='' &&
          file_eq(filename,_workspace_filename)) {
         flags|=MF_CHECKED;
      }
      int NewMenuHandle=_menu_insert(ParentMenuHandle,
                                     -1,
                                     flags,       // flags
                                     _make_fhist_caption(caption,WKSPHIST_CATEGORY),
                                     command,   // command
                                     "",    // category
                                     "",  // help command
                                     help_message
                                     );
      if (workspaceInfo[i].isFolder) {
         if (workspaceInfo[i].u.list._varformat()==VF_ARRAY) {
            AddWorkspacesToMenu(NewMenuHandle,workspaceInfo[i].u.list);
         }
      }
   }
}

