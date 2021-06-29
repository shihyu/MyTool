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
#include "git.sh"
#include "svc.sh"
#import "se/vc/IVersionControl.e"
#import "clipbd.e"
#import "diff.e"
#import "git.e"
#import "listbox.e"
#import "main.e"
#import "mprompt.e"
#import "projconv.e"
#import "picture.e"
#import "pipe.sh"
#import "sellist2.e"
#import "stdprocs.e"
#import "treeview.e"
#import "wkspace.e"
#import "svc.e"
#import "varedit.e"
#endregion

static const SHORT_HASH_LENGTH= 7;

using se.vc.IVersionControl;
using sc.lang.String;

defeventtab _git_repository_browser_form;

void _git_repository_browser_form.on_load()
{
   ctlGraphTree._set_focus();
}

STRARRAY def_git_browser_url_list;

// Set to -1 to load all
int def_git_browser_single_load_limit = 100;
int def_git_browser_current_branch_only = 0;

static _str GLastPath(...)[] {
   if (arg()) ctlGraphTree.p_user=arg(1);
   return ctlGraphTree.p_user;
}

static void movePath(bool moveDown)
{
   _SetDialogInfoHt("movingNode",1);
   index := _TreeCurIndex();
   if ( moveDown ) {
      nextIndex := _TreeGetNextSiblingIndex(index);
      if(nextIndex == -1) return;
      _TreeMoveDown(index);
   } else {
      prevIndex := _TreeGetPrevSiblingIndex(index);
      if(prevIndex == -1) return;
      _TreeMoveUp(index);
   }
   _SetDialogInfoHt("movingNode",0);
}

void ctlclose.lbutton_up()
{
   if ( def_git_browser_current_branch_only!=_GetDialogInfoHt("def_git_browser_current_branch_only") ) {
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
   p_active_form._delete_window();
}

void ctlMovePathUp.lbutton_up()
{
   ctlPathTree.movePath(false);
}

void ctlMovePathDown.lbutton_up()
{
   ctlPathTree.movePath(true);
}

static int gChangeSelectedTimer = -1;
static int gFindHashTimer = -1;

/**
 * Must be called with treeview as current window ID
 * 
 * @param searchText text to search for.  Searches author name, 
 *                   author email, and comment.  Will search
 *                   version hash if <B>searchText</B> is at
 *                   least 5 characters long
 */
static void filterTree(_str searchText)
{
   if ( _GitGetBranchInfoRunning() ) {
      _message_box("Please wait until list is completely filled in");
      return;
   }
   STRHASHTAB foundHashes;
   hashInPrevBranchSettting := ctlGraphTree._TreeGetCaption(ctlGraphTree._TreeCurIndex(),REVISION_COLUMN);
   _SetDialogInfoHt("hashInPrevBranchSettting",hashInPrevBranchSettting);
   status := ctlGraphTree._GitFilterTree(searchText, foundHashes);
   if ( gChangeSelectedTimer>=0 ) _kill_timer(gChangeSelectedTimer);
   gChangeSelectedTimer = _set_timer(50,treeChangeSelectedCallback,p_active_form' 'ctlGraphTree._TreeCurIndex());
}

void ctlsearch.lbutton_up()
{
   filterTree(ctlsearch_text.p_text);
}

void ctlsearch_clear.lbutton_up()
{
   ctlsearch_text.p_text = "";
   ctlsearch_text._begin_line();
   filterTree("");
}

void ctlsearch_text.enter()
{
   filterTree(p_text);
}

void ctlsearch_text.down()
{
   ctlGraphTree._set_focus();
}

static void resizeDialog(bool showStaged)
{
   ctllabel1.p_x = 90;
   ctllabel1.p_y = 90;
   ctlsearch_text.p_prev.p_y = ctllabel1.p_y;
   ctlsearch_text.p_y = ctllabel1.p_y_extent - ctlsearch_text.p_height;
   ctlSingleBranch.p_y = ctllabel1.p_y_extent - ctlSingleBranch.p_height;

   xbuffer := p_child.p_x;
   ybuffer := p_child.p_y;

   clientWidth := _dx2lx(SM_TWIP,p_client_width);
   clientHeight := _dy2ly(SM_TWIP,p_client_height);

   ctlHorzDivider.p_auto_size = false;
   ctlHorzDivider.p_x = xbuffer;
   ctlHorzDivider.p_width = clientWidth - 2*xbuffer;
   ctlHorzDivider.p_height = 2*ybuffer;

   bottomSpace := clientHeight - (ctlHorzDivider.p_y_extent);
   if ( p_visible && bottomSpace<2000 ) {
      ctlHorzDivider.p_y = clientHeight - 2000;
   }

   ctlPathTree.p_y = ctllabel1.p_y_extent + ybuffer;
   ctlPathTree.p_x = ctllabel1.p_x;
   ctlPathTree.p_width = ctlVertDivider.p_x - xbuffer;
   ctlPathTree.p_height = ctlHorzDivider.p_y - ctlPathTree.p_y;

   if (ctlHorzDivider.p_y < ctlRemovePath.p_y_extent) {
      ctlHorzDivider.p_y = ctlRemovePath.p_y_extent;
   }

   alignUpDownListButtons(ctlPathTree.p_window_id, rightAlign:0,  
                          ctlAddPath.p_window_id, 
                          ctlMovePathUp.p_window_id,
                          ctlMovePathDown.p_window_id,
                          ctlRemovePath.p_window_id);

   ctlVertDivider.p_auto_size = false;
   ctlVertDivider.p_y = ctlRemovePath.p_y_extent + ybuffer;
   ctlVertDivider.p_height = ctlPathTree.p_y_extent - ctlVertDivider.p_y;
   ctlVertDivider.p_width = ctlRemovePath.p_width;

   ctlGraphTree.p_y = ctllabel1.p_y_extent + ybuffer;
   ctlGraphTree.p_x = ctlRemovePath.p_x_extent + PADDING_BETWEEN_LIST_AND_CONTROLS;
   ctlGraphTree.p_width = clientWidth - (ctlVertDivider.p_x_extent) - xbuffer;
   ctlGraphTree.p_height = ctlPathTree.p_height;
   ctlsearch_text.p_prev.p_x = ctlGraphTree.p_x;
   ctlsearch_text.p_x = ctlsearch_text.p_prev.p_x_extent + xbuffer;
   ctlsearch.p_x = ctlsearch_text.p_x_extent + xbuffer;
   sizeBrowseButtonToTextBox(ctlsearch_text.p_window_id, ctlsearch.p_window_id);


   ctlminihtml1.p_prev.p_y = ctlHorzDivider.p_y_extent;
   ctlminihtml1.p_y = ctlminihtml1.p_prev.p_y_extent + ybuffer;
   ctlminihtml1.p_width = ctlVertDividerBottom.p_x - xbuffer - (_twips_per_pixel_x()*2);
   ctlminihtml1.p_height = clientHeight - ctlHorzDivider.p_y_extent - ctlminihtml1.p_prev.p_height - ctldiff.p_height - (3*ybuffer);

   ctlStagedFilesTree.p_visible = showStaged!=0;
   ctlminihtml1.p_visible = showStaged==0;
   ctlminihtml1.p_prev.p_visible = showStaged==0;

   ctlModifiedFilesTree.p_prev.p_y = ctlminihtml1.p_prev.p_y;
   ctlModifiedFilesTree.p_y = ctlminihtml1.p_y;

   ctlVertDividerBottom.p_y = ctlminihtml1.p_y;
   ctlModifiedFilesTree.p_height = ctlminihtml1.p_height;
   ctlVertDividerBottom.p_height = ctlModifiedFilesTree.p_height;
   if ( showStaged ) {
      ctldiffWithCurrent.p_visible = true;
      ctlStagedFilesTree.p_prev.p_visible = true;
      ctlStagedFilesTree.p_x = ctlminihtml1.p_x;
      ctlStagedFilesTree.p_y = ctlminihtml1.p_y;
      ctlStagedFilesTree.p_width = ctlminihtml1.p_width;
      ctlStagedFilesTree.p_height = ctlModifiedFilesTree.p_height;
      ctlStagedFilesTree.p_prev.p_x = ctlminihtml1.p_prev.p_x;
      ctlStagedFilesTree.p_prev.p_y = ctlminihtml1.p_prev.p_y;
      ctlclose.p_x = ctlStagedFilesTree.p_x;
      ctldiffWithCurrent.p_y = ctlStagedFilesTree.p_y_extent + ybuffer;
      ctldiffWithCurrent.p_x = ctlclose.p_x_extent + xbuffer;
      ctlclose.p_y = ctldiffWithCurrent.p_y;
   } else {
      ctldiffWithCurrent.p_visible = false;
      ctlStagedFilesTree.p_prev.p_visible = false;
      ctlclose.p_x = ctlminihtml1.p_x;
      ctlclose.p_y = ctlminihtml1.p_y_extent + ybuffer;
   }
   ctlModifiedFilesTree.p_x = ctlminihtml1.p_x_extent + xbuffer; 
   ctlModifiedFilesTree.p_prev.p_x = ctlModifiedFilesTree.p_x;
   ctlModifiedFilesTree.p_width = clientWidth - (ctlVertDividerBottom.p_x_extent) - xbuffer;

   ctldiff.p_x = ctlModifiedFilesTree.p_x;
   ctlhistory.p_x = ctldiff.p_x_extent + xbuffer;
   ctlhistorydiff.p_x = ctlhistory.p_x_extent + xbuffer;
   ctlhistory.p_y = ctlhistorydiff.p_y = ctldiff.p_y = ctlModifiedFilesTree.p_y_extent+ybuffer;

   ctlSingleBranch.p_x = ctlsearch.p_x_extent + xbuffer;
   ctlSingleBranch.p_y = ctlsearch_text.p_y;
}

void ctlSingleBranch.lbutton_up()
{
   if ( def_git_browser_current_branch_only==1 ) {
      def_git_browser_current_branch_only = 0;
   } else {
      def_git_browser_current_branch_only = 1;
   }
   ctlsearch_text.p_text="";
   // We want to re-fill the tree whether it has changed or not, this p_user is
   // checked in _GitGetBranchInfo(), which will be called from the on_change
   // event we're calling
   GLastPath("");
   _GitBranchClose();
   hashInPrevBranchSettting := ctlGraphTree._TreeGetCaption(ctlGraphTree._TreeCurIndex(),REVISION_COLUMN);
   ctlPathTree.call_event(CHANGE_SELECTED,ctlPathTree._TreeCurIndex(),ctlPathTree,ON_CHANGE,'W');
   _SetDialogInfoHt("hashInPrevBranchSettting",hashInPrevBranchSettting);
   if ( gChangeSelectedTimer>=0 ) _kill_timer(gChangeSelectedTimer);
   gChangeSelectedTimer = _set_timer(50,treeChangeSelectedCallback,p_active_form' 'ctlGraphTree._TreeCurIndex());
}

void ctlGraphTree.c_c()
{
   commitID := getCurHashFromTree();
   GitCommitInfo curCommit;
   initCommit(curCommit);
   gitExePath := _GitGetExePath();
   path := ctlPathTree._TreeGetCaption(ctlPathTree._TreeCurIndex());
   status := _GitGetCommitInfo(gitExePath,path,commitID,curCommit);
   _copy_text_to_clipboard(curCommit.hash);
}

_command void git_repobrowser_menu(_str arg1="") name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   switch ( arg1 ) {
   case "copy-long-hash":
      commitID := getCurHashFromTree();
      GitCommitInfo curCommit;
      initCommit(curCommit);
      gitExePath := _GitGetExePath();
      path := ctlPathTree._TreeGetCaption(ctlPathTree._TreeCurIndex());
      status := _GitGetCommitInfo(gitExePath,path,commitID,curCommit);
      _copy_text_to_clipboard(curCommit.hash);
      break;
   case "copy-short-hash":
      commitID = getCurHashFromTree();
      _copy_text_to_clipboard(commitID);
      break;
   case "copy-all-filenames":
      copyAllFilenamesToClipboard();
      break;
   case "copy-current-filename":
      copyCurrentFilenameToClipboard();
      break;
   }
}

void _git_repository_browser_form.on_resize()
{
   resizeDialog(getCurHashFromTree()=="");
}

static void getVertGrabbarMinMax(int &min, int &max)
{
   min = max = 0;
   min = ctldiffWithCurrent.p_x_extent;
   clientWidth := _dx2lx(SM_TWIP,p_active_form.p_client_width);
   max = clientWidth - (ctlhistorydiff.p_x_extent - ctldiff.p_x) - ctlclose.p_x;
}

int ctlVertDivider.lbutton_down()
{
   // figure out orientation
   min := 0;
   max := 0;

   getVertGrabbarMinMax(min, max);

   _ul2_image_sizebar_handler(min, max);

   return(0);
}

static void getHorzGrabbarMinMax(int &min, int &max)
{
   min = max = 0;
   min = _dy2ly(SM_TWIP, 20*4); // space for four small buttons
   clientHeight := _dx2lx(SM_TWIP,p_active_form.p_client_height);
   max = clientHeight - ctlclose.p_width;
}

int ctlHorzDivider.lbutton_down()
{
   // figure out orientation
   min := 0;
   max := 0;

   getHorzGrabbarMinMax(min, max);

   _ul2_image_sizebar_handler(min, max);

   return(0);
}

static const GRAPH_COLUMN=       0;
static const DESCRIPTION_COLUMN= 1;
static const DATE_COLUMN=        2;
static const AUTHOR_COLUMN=      3;
static const REVISION_COLUMN=    4;
static const INDEX_COLUMN=       5;

static int getRepoRootPath(_str path,_str &rootRepoPath)
{
   origPath := getcwd();
   chdir(path);
   IVersionControl *pInterface = svcGetInterface("Git");
   if ( pInterface==null ) {
      _message_box(get_message(VSRC_SVC_COULD_NOT_GET_VC_INTERFACE_RC,def_vc_system));
      return VSRC_SVC_COULD_NOT_GET_VC_INTERFACE_RC;
   }
   rootRepoPath = pInterface->localRootPath();
   if ( rootRepoPath=="" ) {
      chdir(origPath,1);
      return VSRC_SVC_COULD_NOT_GET_REMOTE_REPOSITORY_INFORMATION;
   }
   status := 0;
   if ( isinteger(rootRepoPath) ) {
      status = (int)rootRepoPath;
   }
   _maybe_append_filesep(rootRepoPath);
   chdir(origPath,1);
   return status;
}

static bool haveRootRepoPath(_str rootRepoPath,STRARRAY &browserURLList)
{
   _maybe_append_filesep(rootRepoPath);
   len := browserURLList._length();
   for (i:=0;i<len;++i) {
      if ( _file_eq(rootRepoPath,browserURLList[i]) ) {
         return true;
      }
   }
   return false;
}

void ctlclose.on_create(_str repoPath="")
{
   _SetDialogInfoHt("inOnCreate", 1);
   gChangeSelectedTimer= -1;
   _nocheck _control ctlGraphTree;
   origwid := p_window_id;
   p_window_id = ctlGraphTree;
   _TreeSetColButtonInfo(GRAPH_COLUMN,1300,0,0,"Graph");
   _TreeSetColButtonInfo(DESCRIPTION_COLUMN,3000,0,0,"Description");
   _TreeSetColButtonInfo(DATE_COLUMN,1800,0,0,"Date");
   _TreeSetColButtonInfo(AUTHOR_COLUMN,2000,0,0,"Author");
   _TreeSetColButtonInfo(REVISION_COLUMN,1000,TREE_BUTTON_AL_RIGHT,0,"Revision");
   p_CustomDelegate = TREE_CUSTOM_DELEGATE_GIT_BRANCHES;
   p_window_id = origwid;

   _SetDialogInfoHt("def_git_browser_url_list",def_git_browser_url_list);
   len := def_git_browser_url_list._length();
   IVersionControl *pInterface = svcGetInterface("Git");
   if ( pInterface==null ) {
      _message_box(get_message(VSRC_SVC_COULD_NOT_GET_VC_INTERFACE_RC,def_vc_system));
      return;
   }

   // A workspace could have multiple git reposiotries, try to figure out what
   // the current one is.
   status := getRepoRootPath(repoPath,auto rootRepoPath);
   if ( status==VSRC_SVC_COULD_NOT_GET_VC_INTERFACE_RC ) return;
   if ( !status && !haveRootRepoPath(rootRepoPath,def_git_browser_url_list) && repoPath!="" && rootRepoPath!="" ) {
      status = _message_box(nls("You do not have a repository set up for the current file's path (%s).\n\nWould you like to add '%s' to the repository list?",repoPath,rootRepoPath),"",MB_YESNOCANCEL);
      if (status == IDCANCEL) {
         p_active_form._delete_window();
         return;
      }
      if ( status == IDYES ) {
         ARRAY_APPEND(def_git_browser_url_list,rootRepoPath);
         len = def_git_browser_url_list._length();
      }
   }
   
   origwid = p_window_id;
   p_window_id = ctlPathTree;
   for ( i:=0 ; i<len; ++i ) {
      int new_node_index=_TreeAddItem(TREE_ROOT_INDEX,def_git_browser_url_list[i],TREE_ADD_AS_CHILD,_pic_fldopen,_pic_fldopen,TREE_NODE_LEAF);
   }
   index := _TreeSearch(TREE_ROOT_INDEX,rootRepoPath,_fpos_case);
   if ( index>0 ) {
      _TreeSetCurIndex(index);
   }
   p_window_id = origwid;

   ctlGraphTree._TreeRetrieveColButtonWidths();

   retrieveValue := ctlHorzDivider._moncfg_retrieve_value();
   if (retrieveValue != null && isinteger(retrieveValue)) ctlHorzDivider.p_y = retrieveValue;
   retrieveValue = ctlVertDivider._moncfg_retrieve_value();
   if (retrieveValue != null && isinteger(retrieveValue)) ctlVertDivider.p_x = retrieveValue;
   retrieveValue = ctlVertDividerBottom._moncfg_retrieve_value();
   if (retrieveValue != null && isinteger(retrieveValue)) ctlVertDividerBottom.p_x = retrieveValue;
   ctlSingleBranch.p_value = def_git_browser_current_branch_only;
   _SetDialogInfoHt("def_git_browser_current_branch_only",def_git_browser_current_branch_only);
   _SetDialogInfoHt("inOnCreate", 0);
   ctlPathTree.call_event(CHANGE_SELECTED,ctlPathTree._TreeCurIndex(),ctlPathTree,ON_CHANGE,'W');
}

void _cb_exitbefore_save_config_git_repository_browser()
{
   wid := _find_formobj('_git_repository_browser_form','N');
   if ( wid ) {
      // Be sure on destroy gets called so we save the list of repositories
      // and update the position of the dividers
      wid._delete_window();
   }
}

void ctlclose.on_destroy()
{
   if ( gChangeSelectedTimer>=0 ) _kill_timer(gChangeSelectedTimer);
   gChangeSelectedTimer = -1;

   if ( gFindHashTimer>=0 ) _kill_timer(gFindHashTimer);
   gFindHashTimer = -1;

   _GitBranchClose();
   git_browser_url_list := _GetDialogInfoHt("def_git_browser_url_list");

   wid := p_window_id;
   p_window_id = ctlPathTree;
   childIndex := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   def_git_browser_url_list = null;
   for (;;) {
      if (childIndex<0 ) break;
      cap := _TreeGetCaption(childIndex);
      ARRAY_APPEND(def_git_browser_url_list,cap);
      childIndex = _TreeGetNextSiblingIndex(childIndex);
   }

   if ( git_browser_url_list!=def_git_browser_url_list ) {
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }

   p_window_id = wid;
   ctlGraphTree._TreeAppendColButtonWidths();

   _moncfg_append_retrieve(ctlHorzDivider, ctlHorzDivider.p_y, "_git_repository_browser_form.ctlHorzDivider" );
   _moncfg_append_retrieve(ctlVertDivider, ctlVertDivider.p_x, "_git_repository_browser_form.ctlVertDivider" );
   _moncfg_append_retrieve(ctlVertDividerBottom, ctlVertDividerBottom.p_x, "_git_repository_browser_form.ctlVertDividerBottom" );
}

void ctlPathTree.on_change(int reason,int index)
{
   movingNode := _GetDialogInfoHt("movingNode");
   if ( movingNode == 1 ) {
      return;
   }
   inOnCreate := _GetDialogInfoHt("inOnCreate");
   if ( inOnCreate==1 ) {
      return;
   }

   if ( reason==CHANGE_SELECTED ) {
      _SetDialogInfoHt("haveBranchHashEnd",null);
      path := _TreeGetCaption(index);
      if ( def_git_browser_current_branch_only ) {
         IVersionControl *pInterface = svcGetInterface("Git");
         if ( pInterface==null ) {
            _message_box(get_message(VSRC_SVC_COULD_NOT_GET_VC_INTERFACE_RC,def_vc_system));
            return;
         }
         branchName := "";
         if ( def_git_browser_current_branch_only ) {
            status := pInterface->getLocalFileBranch(path,branchName);
            if ( status ) {
               _message_box(get_message(VSRC_SVC_COULD_NOT_GET_INFO,path));
               return;
            }
         }
         _GitBranchClose();
         ctlGraphTree._GitGetBranchInfo(path,_GitGetExePath(),0,branchName);
      } else {
         _GitBranchClose();
         ctlGraphTree._GitGetBranchInfo(path,_GitGetExePath());
      }
      ctlsearch_text.p_text="";
      ctlModifiedFilesTree._TreeDelete(TREE_ROOT_INDEX,'C');
      ctlStagedFilesTree._TreeDelete(TREE_ROOT_INDEX,'C');
      ctldiffWithCurrent.p_enabled = false;
      ctldiff.p_enabled = false;
      ctlhistory.p_enabled = false;
      ctlhistorydiff.p_enabled = false;
   }
}

static void initCommit(GitCommitInfo &commit)
{
   commit.hash = "";
   commit.parentHash = "";
   commit.authorName = "";
   commit.authorEmail = "";
   commit.committerDate = "";
   commit.dateTime = "";
   commit.comment = "";
}

static void findHashNodeCallback(int fid)
{
   findHashTimerRecurseCount := _GetDialogInfoHt("findHashTimerRecurseCount",fid);
   if ( findHashTimerRecurseCount==null ) {
      findHashTimerRecurseCount = 0;
      _SetDialogInfoHt("findHashTimerRecurseCount", findHashTimerRecurseCount, fid);
   }
   ++findHashTimerRecurseCount;
   if ( findHashTimerRecurseCount > 1 ) {
      _SetDialogInfoHt("findHashTimerRecurseCount", findHashTimerRecurseCount, fid);
      return;
   }
   if ( gFindHashTimer>=0 ) {
      _kill_timer(gFindHashTimer);
      gFindHashTimer = -1;
   }
   origWID := p_window_id;
   p_window_id = fid;
   found := false;

   do {
      if ( _GetDialogInfoHt("haveBranchHashEnd",(int)fid)==1 ) {
         break;
      }
      branchEndHash := getShortHash(_GitCurBranchEndHash());
      if ( branchEndHash=="" ) {
         break;
      }
      hashIndex := ctlGraphTree.searchForHash(branchEndHash);
      if (hashIndex<=0) {
         break;
      }
      ctlGraphTree._TreeSetCurIndex(hashIndex);
      _SetDialogInfoHt("haveBranchHashEnd",1,(int)fid);
      found = true;
   } while (false);

   p_window_id = origWID;
   --findHashTimerRecurseCount;
   _SetDialogInfoHt("findHashTimerRecurseCount", findHashTimerRecurseCount, fid);
}

static void treeChangeSelectedCallback(int info)
{
   if ( gChangeSelectedTimer>=0 ) _kill_timer(gChangeSelectedTimer);
   gChangeSelectedTimer = -1;

   parse info with auto fid auto index;
   if ( !fid.ctlGraphTree.treeHasCommitItem() ) return;
   if ( !_iswindow_valid((int)fid) ) return;
   if (fid.ctlGraphTree._TreeCurIndex()!=index) {
      return;
   }
   origWID := p_window_id;
   p_window_id = fid.ctlGraphTree;

   // This is the last hash we used to fill in the dialog.  It can be null
   lastHash := _GetDialogInfoHt("lastHash",(int)fid);
   lastHash = lastHash==null?"":lastHash;

   hash := getCurHashFromTree();
   if ( (lastHash=="" && hash!="") ||
        (lastHash!="" && hash=="") ) {
      // Have to do this to make staged file tree visible/invisible
      p_active_form.resizeDialog(hash=="");
   }
   GitCommitInfo curCommit;
   initCommit(curCommit);
   gitExePath := _GitGetExePath();
   path := ctlPathTree._TreeGetCaption(ctlPathTree._TreeCurIndex());

   hashInPrevBranchSettting := _GetDialogInfoHt("hashInPrevBranchSettting",(int)fid);
   if ( hashInPrevBranchSettting!=null && _TreeGetFirstChildIndex(TREE_ROOT_INDEX)!=-1 ) {
      lastHashIndex := _TreeSearch(TREE_ROOT_INDEX,hashInPrevBranchSettting,"",null,REVISION_COLUMN);
      if ( lastHashIndex>=0 ) {
         _TreeSetCurIndex(lastHashIndex);
         hash = lastHash;
         // Cheap way to scroll current node into view
         if ( !_TreeUp() ) {
            _TreeDown();
         }
         p_active_form.resizeDialog(hashInPrevBranchSettting=="");
      }
      _SetDialogInfoHt("hashInPrevBranchSettting",null,(int)fid);
   }
   if ( hash!="" ) {
      status := _GitGetCommitInfo(gitExePath,path,hash,curCommit);
      if ( !status ) {
         branchIndexes := _TreeGetUserInfo((int)index);
         if ( hash!="" ) fillInHTML(curCommit,branchIndexes);
         fillInFiles(curCommit);
      } else {
         ctlminihtml1.p_text = "";
         ctlModifiedFilesTree._TreeDelete(TREE_ROOT_INDEX,'C');
      }
   } else {
      if ( ctlGraphTree._TreeGetFirstChildIndex(TREE_ROOT_INDEX)>0 ) {
         _str allDiffInfo:[]:[][];
         status := _GitGetDiffInfo(path,gitExePath,allDiffInfo,hash);
         
         ctlModifiedFilesTree.fillInSpecificFiles(allDiffInfo:[path]:["local"]);
         ctlStagedFilesTree.fillInSpecificFiles(allDiffInfo:[path]:["staged"]);
      } else {
         ctlModifiedFilesTree._TreeDelete(TREE_ROOT_INDEX, 'C');
         ctlStagedFilesTree._TreeDelete(TREE_ROOT_INDEX, 'C');
      }
   }
   _SetDialogInfoHt("lastHash",hash,(int)fid);

//   gFindHashTimer = _set_timer(50,findHashNodeCallback,p_active_form);

   p_window_id = origWID;
}

static bool treeHasCommitItem()
{
   haveCommitItem := _GetDialogInfoHt("haveCommitItem");
   if ( haveCommitItem==1 ) return true;
   firstChildIndex := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   if ( firstChildIndex<0 ) return false;
   firstCommitIndex := _TreeGetNextSiblingIndex(firstChildIndex);
   if ( firstCommitIndex<0 ) return false;
   _SetDialogInfoHt("haveCommitItem", 1);
   return true;
}

void ctlGraphTree.on_change(int reason,int index)
{
   IVersionControl *pInterface = svcGetInterface("Git");
   if ( pInterface==null ) {
      return;
   }
   if ( !treeHasCommitItem() ){
      return;
   }
   if ( reason==CHANGE_SELECTED ) {
      if ( gChangeSelectedTimer>=0 )_kill_timer(gChangeSelectedTimer);
      if ( gFindHashTimer>=0 ) _kill_timer(gFindHashTimer);
      gFindHashTimer = -1;
      gChangeSelectedTimer = _set_timer(50,treeChangeSelectedCallback,p_active_form' 'index);
   }
}

void ctlGraphTree.c_f()
{
   _param1='';
   result := textBoxDialog("Find Hash",TB_RETRIEVE_INIT,0,'',RetrieveName:"git find hash",prompt1:"Hash:");

   if ( result=='' ) {
      return;
   }
   _str hash=_param1;
   index := searchForHash(hash);
   if ( index<0 ) {
      _message_box(nls("Could not find '%s'.\n\nThis hash may not be loaded yet.",hash));
      return;
   }
   _TreeSetCurIndex(index);
}

void ctlGraphTree.rbutton_up()
{
   int MenuIndex=find_index("_git_repository_browser_menu",oi2type(OI_MENU));
   int menu_handle=_mdi._menu_load(MenuIndex,'P');

   int x,y;
   mou_get_xy(x,y);

   commitID := getCurHashFromTree();
   if ( commitID=="" ) {
      // If commitID=="", we're on the "uncomitted changes line"
      _menu_get_state(menu_handle,0,auto flags,'P');
      _menu_set_state(menu_handle,0,MF_GRAYED,'P');
      _menu_get_state(menu_handle,1,flags,'P');
      _menu_set_state(menu_handle,1,MF_GRAYED,'P');
   }
   int status=_menu_show(menu_handle,VPM_RIGHTBUTTON,x-1,y-1);
   _menu_destroy(menu_handle);
}

void ctlGraphTree.C_HOME()
{
   ctlGraphTree._TreeTop();
}

void ctlGraphTree.C_END()
{
   ctlGraphTree._TreeBottom();
}

static void showFilesMenu()
{
   int MenuIndex=find_index("_git_repository_browser_files_menu",oi2type(OI_MENU));
   int menu_handle=_mdi._menu_load(MenuIndex,'P');

   int x,y;
   mou_get_xy(x,y);

   firstChildIndex := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   if ( firstChildIndex<0 ) {
      // If there are no files, nothing to copy
      _menu_get_state(menu_handle,0,auto flags,'P');
      _menu_set_state(menu_handle,0,MF_GRAYED,'P');
   }
   int status=_menu_show(menu_handle,VPM_RIGHTBUTTON,x-1,y-1);
   _menu_destroy(menu_handle);
}

void ctlStagedFilesTree.rbutton_up()
{
   showFilesMenu();
}

void ctlModifiedFilesTree.rbutton_up()
{
   showFilesMenu();
}

static int searchForHash(_str hash)
{
   childIndex := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   for (;;) {
      if ( childIndex<0 ) break;
      curHash := getCurHashFromTree(childIndex);
      str1 :=  substr(hash,1,min(length(hash),length(curHash)));
      str2 :=  substr(curHash,1,min(length(hash),length(curHash)));
      if ( str1==str2 && curHash!="" ) return childIndex;
      childIndex = _TreeGetNextSiblingIndex(childIndex);
   }
   return -1;
}

void ctlminihtml1.on_change(int reason,_str href="")
{
   parse href with auto type ':' auto rest;
   switch ( type ) {
   case "hash":
      hash := rest;
      index := ctlGraphTree.searchForHash(hash);
      if ( index>0 ) {
         ctlGraphTree._TreeSetCurIndex(index);
      }
      break;
   }
}

static _str getShortHash(_str hash)
{
   return substr(hash,1,SHORT_HASH_LENGTH);
}

static void fillInHTML(GitCommitInfo &commit,INTARRAY &branchIndexes)
{
   if (commit.hash._varformat()==VF_EMPTY) {
      return;
   }
   shortHash := commit.parentHash;
   _str html = '<B>Author: </B>'commit.authorName"<br>"\
               '<B>Email: </B>'commit.authorEmail"<br>"\
               '<B>Date: </B>'commit.committerDate"<br>"\
               '<B>Comment: </B>';
   len := commit.longComment._length();
   for (i:=0;i<len;++i) {
      html :+= commit.longComment[i];
      if ( i<len-1 ) {
         html :+= "<br>";
      }
   }
   html :+= "<br>";
   html:+='<B>Revision: </B>'commit.hash"<br>"\
          '<B>Parents: </B><A href=hash:'shortHash'>'shortHash'</A>';
   if ( commit.otherParents!=null ) {
      len = commit.otherParents._length();
      for (i=0;i<len;++i) {
         html :+= ', <A href=hash:'commit.otherParents[i]'>'commit.otherParents[i]'</A>';
      }
      html :+= '<BR>';
   }
   html :+= '<BR>';
   html :+= 'Contained in branches:<BR>';
   for (i=0;i<branchIndexes._length();++i) {
      curBranchIndex := branchIndexes[i];
      curBranchName := _GitGetBranchName(curBranchIndex);
      html :+= '<A href=hash:'_GitGetBranchHash(curBranchIndex)'>'curBranchName'</A><BR>';
   }
   ctlminihtml1.p_text = html;
}

static void fillInSpecificFiles(STRARRAY &files)
{
   _TreeDelete(TREE_ROOT_INDEX,'C');
   len := files._length();
   for ( i:=0; i<len; ++i ) {
      _TreeAddItem(TREE_ROOT_INDEX,stranslate(files[i],FILESEP,FILESEP2),TREE_ADD_AS_CHILD,_pic_file,_pic_file,-1);
   }
}

static void fillInFiles(GitCommitInfo &commit)
{
   modifiedLen := commit.modifiedFiles._length();
   stagedLen := commit.stagedFiles._length();
   if ( modifiedLen==0 ) {
      ctldiff.p_enabled = false;
      ctlhistory.p_enabled = false;
      ctlhistorydiff.p_enabled = false;
   } else {
      ctldiff.p_enabled = true;
      ctlhistory.p_enabled = true;
      ctlhistorydiff.p_enabled = true;
   }
   ctlModifiedFilesTree.fillInSpecificFiles(commit.modifiedFiles);
   ctlStagedFilesTree.fillInSpecificFiles(commit.stagedFiles);
   if ( commit.stagedFiles._length() == 0) {
      ctldiffWithCurrent.p_enabled = false;
   } else {
      ctldiffWithCurrent.p_enabled = true;
   }
}

void ctlAddPath.lbutton_up()
{
   IVersionControl *pInterface = svcGetInterface("Git");
   if ( pInterface==null ) {
      return;
   }
   _param1='';
   _str result = show('-modal _textbox_form',
                      'Add Reprository Path', // Form caption
                      0,  //flags
                      '', //use default textbox width
                      '', //Help item.
                      '', //Buttons and captions
                      'svn add repository', //Retrieve Name
                      '-c 'DIRNOQUOTES_ARG:+_chr(0)' -bd Path:'
                     );

   if ( result=='' ) {
      return;
   }
   _str pathName=_param1;
   _maybe_append_filesep(pathName);
   if ( pathName=="" ) return;

   origPath := getcwd();
   chdir(pathName,1);
   gitRepositoryPath := pInterface->localRootPath();
   chdir(origPath);

   if ( gitRepositoryPath=="" || gitRepositoryPath==VSRC_SVC_COULD_NOT_PULL_FROM_REPOSITORY ) {
      _message_box(nls("'%s' is not a valid Git repository",pathName));
      return;
   }

   if ( !_file_eq(pathName,gitRepositoryPath) ) {
      _message_box(nls("The root for this repository, '%s' will be added",gitRepositoryPath));
   }

   origWID := p_window_id;
   _control ctlPathTree;
   p_window_id = ctlPathTree;
   int index=_TreeSearch(TREE_ROOT_INDEX,gitRepositoryPath);
   if ( index>=0 ) {
      _message_box(nls("'%s' is already in the browser",gitRepositoryPath));
      _TreeSetCurIndex(index);
      p_window_id = origWID;
      return;
   }
   int new_node_index=_TreeAddItem(TREE_ROOT_INDEX,gitRepositoryPath,TREE_ADD_AS_CHILD,_pic_fldopen,_pic_fldopen,TREE_NODE_LEAF);
   _TreeSetCurIndex(new_node_index);
   p_window_id = origWID;
   return;
}

void ctlRemovePath.lbutton_up()
{
   wid := p_window_id;
   p_window_id = ctlPathTree;
   index := _TreeCurIndex();
   if ( index>=0 ) {
      _TreeDelete(index);
      ctlPathTree.call_event(CHANGE_SELECTED,_TreeCurIndex(),ctlPathTree,ON_CHANGE,'W');
   }
   p_window_id = wid;
}

void ctlModifiedFilesTree.on_change(int reason,int index)
{
   if ( reason==CHANGE_LEAF_ENTER ) {
      ctldiff.call_event(ctldiff,LBUTTON_UP);
   }
}

void ctlModifiedFilesTree.c_c()
{
   status := getLocalFilename(ctlModifiedFilesTree,auto localFilename);
   if (status) {
      _message_box(get_message(VSRC_SVC_COULD_NOT_GET_REMOTE_FILE));
      return;
   }
   _copy_text_to_clipboard(localFilename);
}

static void copyCurrentFilenameToClipboard()
{
   status := getLocalFilename(p_window_id,auto localFilename);
   if (status) {
      _message_box(get_message(VSRC_SVC_COULD_NOT_GET_REMOTE_FILE));
      return;
   }
   _copy_text_to_clipboard(localFilename);
}

static void copyAllFilenamesToClipboard()
{
   fileNameList := "";
   childIndex := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   for (append := false ;; append = true) {
      if ( childIndex<0 ) break;
      status := getLocalFilename(p_window_id,auto localFilename,childIndex);
      if (status) {
         _message_box(get_message(status));
         return;
      }
      _copy_text_to_clipboard(localFilename,append);
      childIndex = _TreeGetNextSiblingIndex(childIndex);
   }
}

void ctlStagedFilesTree.c_c()
{
    status := getLocalFilename(ctlStagedFilesTree,auto localFilename);
    if (status) {
       _message_box(get_message());
       return;
    }
   _copy_text_to_clipboard(localFilename);
}

static int getLocalFilename(int treeWID,_str &localFilename, int index=-1)
{
   localFilename = "";
   IVersionControl *pInterface = svcGetInterface("Git");
   if ( pInterface==null ) {
      return VSRC_SVC_COULD_NOT_GET_VC_INTERFACE_RC;
   }
   origPath := getcwd();
   path := ctlPathTree._TreeGetCaption(ctlPathTree._TreeCurIndex());
   if ( path!="" ) {
      status := chdir(path,1);
      if ( status ) return status;
   }
   localRoot := pInterface->localRootPath();
   if ( localRoot=="" ) {
      return VSRC_SVC_COULD_NOT_GET_REMOTE_REPOSITORY_INFORMATION;
   }
   chdir(origPath);
   if ( index<0 ) {
      index = treeWID._TreeCurIndex();
   }
   justFile := treeWID._TreeGetCaption(index);
   localFilename = localRoot:+justFile;
   return 0;
}

static void getParentList(GitCommitInfo &curCommit,STRARRAY &parentList)
{
   if ( curCommit.parentHash!="" ) {
      ARRAY_APPEND(parentList,getShortHash(curCommit.parentHash));
   }
   len := curCommit.otherParents._length();
   for (i:=0;i<len;++i) {
      ARRAY_APPEND(parentList,getShortHash(curCommit.otherParents[i]));
   }
}

static void showGitOutput(_str localFilename,STRHASHTABARRAY &diffInfo)
{
   fileData := diffInfo:[_file_case(localFilename)];
   origWID := _create_temp_view(auto tempWID);
   len := fileData._length();
   for (i:=0;i<len;++i) {
      insert_line(fileData[i]);
   }
   p_window_id = origWID;
   _showbuf(tempWID,false,"-new -modal",localFilename);
   _delete_temp_view(tempWID);
}

static const SHOW_GIT_DIFF_OUTPUT=       1;
static const LOAD_UNTIL_PARENT_IS_FOUND= 2;

void ctldiff.lbutton_up()
{
   IVersionControl *pInterface = svcGetInterface("Git");
   if ( pInterface==null ) {
      return;
   }
   curIndex := ctlGraphTree._TreeCurIndex();
   status := getLocalFilename(ctlModifiedFilesTree,auto localFilename);
   if (status) {
      _message_box(get_message(status));
      return;
   }
   version1 := getCurHashFromTree();

   commitID := getCurHashFromTree();
   GitCommitInfo curCommit;
   initCommit(curCommit);
   gitExePath := _GitGetExePath();
   path := ctlPathTree._TreeGetCaption(ctlPathTree._TreeCurIndex());
   status = _GitGetCommitInfo(gitExePath,path,commitID,curCommit);

   getParentList(curCommit,auto parentList);
   version2 := "";
   if ( parentList._length()==0 ) {
      STRARRAY captions;
      len := parentList._length();
      ARRAY_APPEND(captions,"View Git output");
      ARRAY_APPEND(captions,"Load until parent version is found");
      int result=RadioButtons("Parent Version Not Loaded",captions,1,'gitBrowseRepository');
      if ( result==COMMAND_CANCELLED_RC ) {
         return;
      }
      if ( result==SHOW_GIT_DIFF_OUTPUT ) {
         _str diffInfo:[]:[][] = _GetDialogInfoHt("gitOutput");
         if ( diffInfo:[_file_case(path)]==null ) {
            _GitGetDiffInfo(path,gitExePath,diffInfo,curCommit.hash);
            _SetDialogInfoHt("gitOutput",diffInfo);
         }
         showGitOutput(localFilename,diffInfo:[_file_case(path)]);
         return;
      } else if ( result==LOAD_UNTIL_PARENT_IS_FOUND ) {
         for (;;) {
            // Load more information
            ctlGraphTree._GitGetBranchInfo(path,_GitGetExePath(),1);

            // Wait for thread to finish
            for (;_GitGettingInfo();) {
            }

            // Get the info for this commit
            _GitGetCommitInfo(gitExePath,path,commitID,curCommit);

            // Get the current parent list
            getParentList(curCommit,parentList);

            // If there's anything in the list, we're done
            if ( parentList._length()>0 ) {
               version2  = parentList[0];
               break;
            }
         }
      }
   } else if ( parentList._length()==1 ) {
      version2 = parentList[0];
   } else {
      STRARRAY captions;
      len := parentList._length();
      for ( i:=0;i<len;++i ) {
         captions[i] = "Compare version ":+version1" with "parentList[i];
      }
      int result=RadioButtons("Multiple Parents Exist",captions,1,'gitBrowseRepository');
      if ( result==COMMAND_CANCELLED_RC ) {
         return;
      }
      version2 = parentList[result -1];
   }

   file1WID := 0;
   if ( version1!="" ) {
      status = pInterface->getFile(localFilename,version1,file1WID);
      if ( status ) {
         _message_box(nls("Could not get version '%s' of '%s'",version1,localFilename));
         return;
      }
   }
   status = pInterface->getFile(localFilename,version2,auto file2WID);
   if ( status ) {
      _message_box(nls("Could not get version '%s' of '%s'",version2,localFilename));
      return;
   }
   if ( version1!="" ) {
      diff('-modal -bi1 -bi2 -r1 -r2 -RegisterAsMFDChild 'p_active_form' -file1title '_maybe_quote_filename(localFilename':'getShortHash(version1))'  -file2title '_maybe_quote_filename(localFilename':'getShortHash(version2))' 'file1WID.p_buf_id' 'file2WID.p_buf_id);
      _delete_temp_view(file1WID);
   } else {
      diff('-modal -bi2 -r2 -RegisterAsMFDChild 'p_active_form' -file1title '_maybe_quote_filename(localFilename':locally modified')'  -file2title '_maybe_quote_filename(localFilename':'getShortHash(version2))' '_maybe_quote_filename(localFilename)' 'file2WID.p_buf_id);
   }
   _delete_temp_view(file2WID);
}

void ctldiffWithCurrent.lbutton_up()
{
   IVersionControl *pInterface = svcGetInterface("Git");
   if ( pInterface==null ) {
      return;
   }
   status := getLocalFilename(ctlStagedFilesTree,auto localFilename);
   if (status) {
      _message_box(get_message(status));
      return;
   }

   commitID := getCurHashFromTree();
   GitCommitInfo curCommit;
   initCommit(curCommit);
   gitExePath := _GitGetExePath();
   path := ctlPathTree._TreeGetCaption(ctlPathTree._TreeCurIndex());
   status = _GitGetCommitInfo(gitExePath,path,commitID,curCommit);

   status = pInterface->getFile(localFilename,curCommit.parentHash,auto file2WID);
   if ( status ) {
      _message_box(nls("Could not get version '%s' of '%s'",curCommit.parentHash,localFilename));
      return;
   }
   diff('-modal -bi2 -r2 -RegisterAsMFDChild 'p_active_form' -file1title '_maybe_quote_filename(localFilename':locally modified')'  -file2title '_maybe_quote_filename(localFilename':'getShortHash(curCommit.parentHash))' '_maybe_quote_filename(localFilename)' 'file2WID.p_buf_id);
   _delete_temp_view(file2WID);
}

static _str getCurHashFromTree(int index=-1)
{
   if ( index==-1 ) index = ctlGraphTree._TreeCurIndex();
   version := ctlGraphTree._TreeGetCaption(index,REVISION_COLUMN);
   return version;
}

static _str getCurDirectoryFromTree()
{
   line := ctlPathTree._TreeGetCaption(ctlPathTree._TreeCurIndex());
   _maybe_append_filesep(line);
   return line;
}

static _str getCurBranchFromTree()
{
   branchIndex := ctlGraphTree._TreeGetUserInfo(ctlGraphTree._TreeCurIndex());
   branchName := _GitGetBranchName(branchIndex);
   return branchName;
}

void ctlhistory.lbutton_up()
{
   repositoryPath := getCurDirectoryFromTree();
   origPath := getcwd();
   status := chdir(repositoryPath,1);
   if ( status ) {
      _message_box(nls("Could not change to directory '%s'.\n\n%s",repositoryPath,get_message(status)));
      return;
   }
   status = getLocalFilename(ctlModifiedFilesTree,auto localFilename);
   if (status) {
      _message_box(get_message(status));
      return;
   }
   curRevision := getCurHashFromTree();
   // Go ahead and be sure we're set to git
   IVersionControl *pInterface = svcGetInterface("Git");
   if ( pInterface==null ) {
      _message_box(get_message(VSRC_SVC_COULD_NOT_GET_VC_INTERFACE_RC,def_vc_system));
      return;
   }
   commitID := getCurHashFromTree();
   status = pInterface->getBranchForCommit(commitID,auto branchForCommit="",getCurDirectoryFromTree());
   origdef_vc_system := def_vc_system;
   def_vc_system = "Git";
   svc_history(localFilename,SVC_HISTORY_NOT_SPECIFIED,branchName:branchForCommit/*,curRevision,false,branchName*/);
   def_vc_system := origdef_vc_system;
}

void ctlhistorydiff.lbutton_up()
{
   status := getLocalFilename(ctlModifiedFilesTree,auto localFilename);
   if (status) {
      _message_box(get_message(status));
      return;
   }
   origdef_vc_system := def_vc_system;
   commitID := getCurHashFromTree();
   branchName := getCurBranchFromTree();
   def_vc_system = "Git";
   origPath := getcwd();
   curPath := _file_path(localFilename);
   chdir(curPath);
   IVersionControl *pInterface = svcGetInterface("Git");
   if ( pInterface==null ) {
      _message_box(get_message(VSRC_SVC_COULD_NOT_GET_VC_INTERFACE_RC,def_vc_system));
      return;
   }
   status = pInterface->getBranchForCommit(commitID,auto branchForCommit="",getCurDirectoryFromTree());
   svc_history_diff(localFilename,branchForCommit);
   chdir(origPath);
   def_vc_system := origdef_vc_system;
}

_command void git_gui_browse_repository() name_info(',')
{
   wid := show("-xy -app _git_repository_browser_form");
}
