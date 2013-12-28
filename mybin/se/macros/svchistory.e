////////////////////////////////////////////////////////////////////////////////////
// $Revision: 48969 $
////////////////////////////////////////////////////////////////////////////////////
// Copyright 2013 SlickEdit Inc. 
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
#include 'slick.sh'
#pragma option(pedantic,on)
#region Imports
#include "slick.sh"
#include "subversion.sh"
#include "markers.sh"
#include "cvs.sh"
#include "svc.sh"
#include "diff.sh"
#import "backtag.e"
#import "cvs.e"
#import "diff.e"
#import "difftags.e"
#import "main.e"
#import "menu.e"
#import "sellist.e"
#import "sellist2.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "subversion.e"
#import "svc.e"
#import "treeview.e"
#import "vc.e"
#require "se/vc/IVersionControl.e"
#import "se/vc/Perforce.e"
//#import "se/vc/Subversion.e"
#endregion

using se.vc.IVersionControl;

static void initHistoryInfo(SVCHistoryInfo &temp,_str revision="",_str author="",
                            _str date_and_time="",_str comment="",
                            _str affectedFilesDetails="",int pic=-1,boolean expandable=false,
                            boolean hidden=false,_str revisionCaption="",STRARRAY &tagNames=null) {
   temp.revision = revision;
   temp.author   = author;
   temp.date     = date_and_time;
   temp.comment  = comment;
   temp.affectedFilesDetails = affectedFilesDetails;
   temp.picIndex  = pic;

   temp.lsibIndex = -1;
   temp.rsibIndex = -1;
   temp.firstChildIndex = -1;
   temp.parentIndex = -1;

   temp.expandable = expandable;
   temp.hidden     = hidden;

   temp.revisionCaption = revisionCaption;
   temp.tagNames = tagNames;
}

int addHistoryItem(int curIndex,SVCHistoryAddFlags addFlags,SVCHistoryInfo (&historyInfo)[],boolean expandable,
                   int pic=-1,
                   _str revision="",
                   _str author="",_str date_and_time="",
                   _str comment="",_str affectedFilesDetails="",
                   _str revisionCaption="",
                   STRARRAY &tagNames=null)
{
   newIndex := -1;
   if ( historyInfo._length()==0 ) {
      SVCHistoryInfo temp;
      initHistoryInfo(temp);
      temp.revision = "root";
      historyInfo[0] = temp;
   }
   if ( curIndex==0 && !(addFlags&ADDFLAGS_ASCHILD) ) {
      return -1;
   }

   newIndex = historyInfo._length();
   SVCHistoryInfo temp;
   initHistoryInfo(temp,revision,author,date_and_time,comment,affectedFilesDetails,pic,expandable,false,revisionCaption,tagNames);
   historyInfo[newIndex] = temp;
   SVCHistoryInfo *pNew = &historyInfo[newIndex];
   SVCHistoryInfo *pCur = &historyInfo[curIndex];
   if ( addFlags&ADDFLAGS_ASCHILD ) {
      pNew->parentIndex = curIndex;
      if ( pCur->firstChildIndex==-1 ) {
         pCur->firstChildIndex = newIndex;
      } else {
         SVCHistoryInfo *pCurChild = null;
         for ( curChildIndex:=pCur->firstChildIndex;curChildIndex>=0; ) {
            pCurChild = &historyInfo[curChildIndex];
            if ( pCurChild->rsibIndex<0 ) break;
            curChildIndex = pCurChild->rsibIndex;
         }
         pCurChild->rsibIndex = newIndex;
      }
   } else if ( addFlags&ADDFLAGS_SIBLINGBEFORE ) {
      pNew->lsibIndex = pCur->lsibIndex;
      pNew->rsibIndex = curIndex;
      pNew->parentIndex = pCur->parentIndex;
      SVCHistoryInfo *pLast = null;
      if ( pCur->lsibIndex>=0 ) pLast=&historyInfo[pCur->lsibIndex];
      if ( pLast!=null) pLast->rsibIndex = newIndex;
      pCur->lsibIndex = newIndex;
      SVCHistoryInfo *pParent=&historyInfo[pCur->parentIndex];
      if ( pParent->firstChildIndex==curIndex ) {
         pParent->firstChildIndex=newIndex;
      }
   } else if ( addFlags&ADDFLAGS_SIBLINGAFTER ) {
      pNew->lsibIndex = curIndex;
      pNew->rsibIndex = pCur->rsibIndex;
      pNew->parentIndex = pCur->parentIndex;
      pCur->rsibIndex = newIndex;
   }

   return newIndex;
}

#if 0
static void dumpItems(int index,SVCHistoryInfo (&SVCHistoryInfo)[],int indent=0)
{
   if ( indent==0 ) say('dumpItems ***********************************************************');
   indentStr := substr("",1,indent*3,'-');
   for ( ;; ) {
//      say('dumpItems indent='indent' index='index);
      if ( index<0 ) break;
      SVCHistoryInfo *pCur = &SVCHistoryInfo[index];
      say(indentStr:+pCur->revision);
      if ( pCur->firstChildIndex>=0 ) {
         dumpItems(pCur->firstChildIndex,SVCHistoryInfo,indent+1);
      }
      index = pCur->rsibIndex;
   }
}

_command void test_history_tree() name_info(',')
{
   SVCHistoryInfo SVCHistoryInfo[];
   int index1 = addHistoryItem(0,ADDFLAGS_ASCHILD,SVCHistoryInfo,_pic_file,"1");
   //int index2 = addHistoryItem(index1,ADDFLAGS_SIBLINGAFTER,SVCHistoryInfo,_pic_file,"2");
   //int index3 = addHistoryItem(index2,ADDFLAGS_SIBLINGAFTER,SVCHistoryInfo,_pic_file,"3");


   int index1_1 = addHistoryItem(index1,ADDFLAGS_SIBLINGBEFORE,SVCHistoryInfo,_pic_file,"1.1");
   //int index1_2 = addHistoryItem(index1,ADDFLAGS_SIBLINGBEFORE,SVCHistoryInfo,_pic_file,"1.2");
   //int index1_3 = addHistoryItem(index1,ADDFLAGS_SIBLINGBEFORE,SVCHistoryInfo,_pic_file,"1.3");
   //int index1_4 = addHistoryItem(index1,ADDFLAGS_SIBLINGBEFORE,SVCHistoryInfo,_pic_file,"1.4");
   //int index1_5 = addHistoryItem(index1,ADDFLAGS_SIBLINGBEFORE,SVCHistoryInfo,_pic_file,"1.5");

   //int index4 = addHistoryItem(index3,ADDFLAGS_SIBLINGAFTER,SVCHistoryInfo,_pic_file,"4");
   //int index4_1 = addHistoryItem(index4,ADDFLAGS_ASCHILD,SVCHistoryInfo,_pic_file,"4.1");
   //int index4_1_1 = addHistoryItem(index4_1,ADDFLAGS_ASCHILD,SVCHistoryInfo,_pic_file,"4.1.1");
   //int index5 = addHistoryItem(index4,ADDFLAGS_SIBLINGAFTER,SVCHistoryInfo,_pic_file,"5");


   dumpItems(0,SVCHistoryInfo);
}
#endif

defeventtab _svc_history_form;
void _svc_history_form.on_load()
{
   ctltree1._set_focus();
}

void _svc_history_form.on_destroy()
{
   windowsToClose := _GetDialogInfoHt("windowsToClose");
   foreach (auto key => auto value in windowsToClose) {
//      say('_svc_history_form.on_destroy deleting 'key);
      _delete_temp_view(key);
   }
}

/**
 * Stores info on a tree node in the history dialog for that revision
 * @param index index of node to store data on
 * @param author Author from Subversion
 * @param date_and_time date/time from Subversion
 * @param comment Comment from Subversion 
 * @param affectedPaths List of all file paths affected by this revision 
 */
static void setVersionInfo(int index,SVCHistoryInfo &historyInfo)
{
//   say('setVersionInfo historyInfo.revision='historyInfo.revision' comment='historyInfo.comment);
   _str lineArray[];
   if ( historyInfo.author!="" ) lineArray[lineArray._length()]='<B>Author:</B>&nbsp;'historyInfo.author'<br>';
   if ( historyInfo.date!="" ) lineArray[lineArray._length()]='<B>Date:</B>&nbsp;'historyInfo.date'<br>';
   if ( historyInfo.revisionCaption!="" ) {
      // There is a revision caption (git), this is what is displayed in the 
      // tree, so we'll add a revision under the date
      lineArray[lineArray._length()]='<B>Revision:</B>&nbsp;'historyInfo.revision'<br>';
   }
   // Replace comment string line endings with <br> to preserve formatting
   _str commentBR = stranslate(historyInfo.comment, '<br>', '\n', 'l');
   if ( commentBR!="" ) {
      lineArray[lineArray._length()]='<B>Comment:</B>&nbsp;'commentBR;
   }
   if( historyInfo.affectedFilesDetails :!= '' ) {
      lineArray[lineArray._length()]='<br><B>Changed paths:</B><font face="Menlo, Monaco, Consolas, Courier New, Monospace">'historyInfo.affectedFilesDetails'</font>';
   }
   lineArray[lineArray._length()]="<br><A href='expandTags("index")'>See List of Changed Symbols</A>";
   HISTORY_USER_INFO info;
   info.actualRevision = historyInfo.revision;
   info.lineArray      = lineArray;
   _TreeSetUserInfo(index,info);
}

static void fillInTreeRecursive(SVCHistoryInfo *pNode,SVCHistoryInfo (&historyInfo)[],int treeviewIndex)
{
   for ( parentIndex:=true;;parentIndex=false ) {
      addFlags := 0;
      if ( parentIndex ) {
         addFlags = TREE_ADD_AS_CHILD;
      }
      showChildren := TREE_NODE_EXPANDED;
      if ( pNode->firstChildIndex<0 ) {
         showChildren = TREE_NODE_LEAF;
      }
      caption := pNode->revision;
      if ( pNode->revisionCaption!="" ) caption = pNode->revisionCaption;
      if ( pNode->tagNames!=null ) {
         caption = caption' (';
         len := pNode->tagNames._length();
         for (i:=0;i<len;++i) {
            caption = caption:+pNode->tagNames[i]',';
         }
         caption = substr(caption,1,length(caption)-1)')';
      }
      treeviewIndex = _TreeAddItem(treeviewIndex,caption,addFlags,pNode->picIndex,pNode->picIndex,showChildren);
      setVersionInfo(treeviewIndex,*pNode);
      if ( pNode->firstChildIndex>=0 ) {
         SVCHistoryInfo *pFirstChild = &historyInfo[pNode->firstChildIndex];
         if ( pFirstChild!=null ) {
            fillInTreeRecursive(pFirstChild,historyInfo,treeviewIndex);
         }
      }
      if ( pNode->rsibIndex<0 ) break;
      pNode = &historyInfo[pNode->rsibIndex];
   }
}

/**
 * Look for string <B>revision</B> in history tree
 * 
 * @param revision revision as it would appear in the tree
 */
static void selectRevisionInTree(_str revision)
{
   int index=_TreeSearch(TREE_ROOT_INDEX,revision,'it');
   if ( index>-1 ) {
      int state,bm1,bm2,flags;
      _TreeGetInfo(index,state,bm1,bm2,flags);
      _TreeSetInfo(index,state,bm1,bm2,flags|TREENODE_BOLD);
      _TreeSetCurIndex(index);
   }
}

static void fillInDialog(SVCHistoryInfo (&historyInfo)[],SVCHistoryFileInfo &dialogInfo)
{
   SVCHistoryInfo *pRoot = &historyInfo[0];
   if ( pRoot->firstChildIndex>=0 ) {
      SVCHistoryInfo *pFirstChild = &historyInfo[pRoot->firstChildIndex];
      if ( pFirstChild!=null ) {
         ctltree1._TreeDelete(TREE_ROOT_INDEX,'C');
         ctltree1.fillInTreeRecursive(pFirstChild,historyInfo,TREE_ROOT_INDEX);
      }
   }
   if ( dialogInfo!=null ) {
      statusDescription := "";
      if ( (dialogInfo.fileStatus&(SVC_STATUS_MODIFIED|SVC_STATUS_NEWER_REVISION_EXISTS) )
           == (SVC_STATUS_MODIFIED|SVC_STATUS_NEWER_REVISION_EXISTS) ) {
         statusDescription='<FONT color=red>Locally modified</FONT> and <FONT color=red>Needs update</FONT>';
         ctlupdate.p_caption = UPDATE_BUTTON_CAPTION;
         ctlupdate.p_enabled = true;
         ctlrevert.p_enabled = true;
      }else if ( dialogInfo.fileStatus&SVC_STATUS_MODIFIED ) {
         statusDescription='<FONT color=red>Locally modified</FONT>';
         ctlupdate.p_caption = COMMIT_BUTTON_CAPTION;
         ctlupdate.p_enabled = true;
         ctlrevert.p_enabled = true;
      }else if ( dialogInfo.fileStatus&SVC_STATUS_NEWER_REVISION_EXISTS ) {
         ctlupdate.p_caption = UPDATE_BUTTON_CAPTION;
         ctlupdate.p_enabled = true;
         ctlrevert.p_enabled = true;
         statusDescription='<FONT color=red>Needs update</FONT>';
      } else {
         IVersionControl *pVCI = svcGetInterface(def_vc_system);
         if ( pVCI==null || !(pVCI->commandsAvailable()&SVC_COMMAND_AVAILABLE_EDIT) ) {
            ctlupdate.p_caption = UPDATE_BUTTON_CAPTION;
            ctlupdate.p_enabled = false;
         } else {
            if ( dialogInfo.fileStatus&SVC_STATUS_EDITED ) {
               ctlupdate.p_caption = UPDATE_BUTTON_CAPTION;
               ctlupdate.p_enabled = false;
               ctlrevert.p_enabled = true;
            } else {
               ctlupdate.p_caption = EDIT_BUTTON_CAPTION;
               ctlupdate.p_enabled = true;
               ctlrevert.p_enabled = false;
            }
         }
         statusDescription='Up-to-date';
      }
      if ( dialogInfo.fileStatus&SVC_STATUS_EDITED ) {
         statusDescription=statusDescription', Edited';
      }

      ctlminihtml1.p_text = "<B>File:</B>"dialogInfo.localFilename"<BR>"\
         "<B>URL:</B>"dialogInfo.URL"<BR>"\
         "<B>Revision:</B>"dialogInfo.currentRevision"<BR>"\
         "<B>Status:</B>"statusDescription;

      ctltree1.selectRevisionInTree(dialogInfo.revisionCaptionToSelectInTree);
      ctltree1.call_event(CHANGE_SELECTED,ctltree1._TreeCurIndex(),ctltree1,ON_CHANGE,'W');
   }
}

void ctlclose.on_create(SVCHistoryInfo (&historyInfo)[]=null,SVCHistoryFileInfo &dialogInfo=null)
{
   IVersionControl *pVCI = svcGetInterface(def_vc_system);
   p_active_form.p_caption = pVCI->getSystemNameCaption()" History";
   // HAVE TO MOVE THIS!!!
   ctlminihtml1.p_backcolor=0x80000022;
   ctlminihtml2.p_backcolor=0x80000022;
   //ctlminihtml1.SVNSetFileInfo(filename);
   if ( historyInfo!=null ) {
      fillInDialog(historyInfo,dialogInfo);
   }
}

void ctltree1.rbutton_up()
{
   int MenuIndex=find_index("_cvs_history_rclick_menu",oi2type(OI_MENU));
   int menu_handle=_mdi._menu_load(MenuIndex,'P');

   if ( menu_handle<0 ) {
      // Error loading menu
      return;
   }
   int output_handle,output_pos;
   status := _menu_find(menu_handle,"cvs-history-toggle-empty-branches",output_handle,output_pos,'M');
   if ( !status ) {
      hiddenIndexes := _GetDialogInfoHt("hiddenIndexes");
      _menu_get_state(menu_handle,0,auto menuFlags,'p',auto menuCaption);
      if ( hiddenIndexes!=null ) {
         _menu_set_state(menu_handle,0,menuFlags,'p',"Show empty branches");
      }else{
         _menu_set_state(menu_handle,0,menuFlags,'p',"Hide empty branches");
      }
   }
   int x,y;
   mou_get_xy(x,y);
   status = _menu_show(menu_handle,VPM_RIGHTBUTTON,x-1,y-1);
}


static _str GetVCSystemNameFromHistoryDialog()
{
   _str DialogPrefix='';
   parse p_active_form.p_caption with DialogPrefix .;
   switch (lowcase(DialogPrefix)) {
   case 'log':
      return('cvs');
   case 'cvs':
      return('cvs');
   case 'subversion':
      return('svn');
   case 'git':
      return('git');
   case 'mercurial':
      return('hg');
   }
   return('');
}

void ctlrefresh.lbutton_up()
{
   status := 0;
   filename := localFilenameFromHistoryDialog();
   refreshDialog(filename);
}

static void refreshDialog(_str filename)
{
   IVersionControl *pVCI = svcGetInterface(def_vc_system);
   if ( pVCI==null ) {
      return;
   }
   mou_hour_glass(true);
   do {
      SVCHistoryInfo historyInfo[];
      SVCHistoryFileInfo dialogInfo;
      SVCInitDialogInfo(dialogInfo);
      status := pVCI->getHistoryInformation(filename,historyInfo);
      if ( status ) break;
      status = pVCI->getCurRevision(filename,auto curRevision="");
      dialogInfo.localFilename = filename;
      if ( !status ) {
         dialogInfo.currentRevision = curRevision;
      }
      status = pVCI->getCurLocalRevision(filename,auto curLocalRevision="");
      if ( !status ) {
         dialogInfo.currentLocalRevision = curLocalRevision;
         dialogInfo.revisionCaptionToSelectInTree = '#' curLocalRevision;
      }
      status = pVCI->getLocalFileURL(filename,auto URL="");
      if ( !status ) {
         dialogInfo.URL = URL;
      }
      status = pVCI->getFileStatus(filename,auto fileStatus=0);
      if ( !status ) {
         dialogInfo.fileStatus = fileStatus;
      }
      if ( historyInfo!=null ) {
         fillInDialog(historyInfo,dialogInfo);
      }
   } while ( false );
   mou_hour_glass(false);
}

int _cvs_history_refresh_button(_str DialogFilename='')
{
   int fid=0;
   if ( DialogFilename!='' ) {
      int last=_last_window_id();
      int i;
      for ( i=1;i<=last;++i ) {
         if ( !_iswindow_valid(i) ) continue;
         if ( i.p_name=='_cvs_history_form'  && i.p_caption=='Log info for 'DialogFilename ) {
            fid=i;
         }
      }
   } else {
      fid=p_active_form;
   }
   if ( !fid ) {
      return(0);
   }
   _str filename=fid._CVSGetFilenameFromHistoryDialog();
   int temp_view_id;_str ErrorFilename;
   int status=_CVSGetLogInfoForFile(filename,temp_view_id,ErrorFilename);
   if ( status ) {
      return(status);
   }

   _SetDialogInfoHt('DELETING_TREE',1);
   fid.ctltree1._TreeDelete(TREE_ROOT_INDEX,'C');
   _SetDialogInfoHt('DELETING_TREE',0);
   fid.ctltree1.call_event(CHANGE_SELECTED,fid.ctltree1._TreeCurIndex(),fid.ctltree1,ON_CHANGE,'W');
   fid.p_caption='Log info for 'filename;

   _delete_temp_view(temp_view_id);
   delete_file(ErrorFilename);
   return(0);
}

#if 0 //9:11am 3/4/2013
static void fillInTags(int index,_str prevVersion,_str selectedVersion)
{
   IVersionControl *pVCI = svcGetInterface(def_vc_system);
   if ( pVCI==null ) return;


   filename := localFilenameFromHistoryDialog();
   pVCI->getFile(filename,prevVersion,auto prevWID);
   pVCI->getFile(filename,selectedVersion,auto curWID);

   _DiffExpandTagsForSVCHistory(prevWID,curWID,index,filename,prevVersion,selectedVersion);
   _delete_temp_view(prevWID);
   _delete_temp_view(curWID);
}
#endif
static void fillInTagsHTML(int index,_str prevVersion,_str selectedVersion)
{
   IVersionControl *pVCI = svcGetInterface(def_vc_system);
   if ( pVCI==null ) return;


   filename := localFilenameFromHistoryDialog();
   pVCI->getFile(filename,prevVersion,auto prevWID);
   pVCI->getFile(filename,selectedVersion,auto curWID);

   _DiffExpandTagsForSVCHistoryHTML(prevWID,curWID,index,filename,prevVersion,selectedVersion);
   // Don't delete views here, we will do it when the dialog closes
   windowsToClose := _GetDialogInfoHt("windowsToClose");
   windowsToClose:[prevWID] = '';
   windowsToClose:[curWID]  = '';
   _SetDialogInfoHt("windowsToClose",windowsToClose);

   versionToWID := _GetDialogInfoHt("versionToWID");
   versionToWID:[prevVersion]      = prevWID;
   versionToWID:[selectedVersion]  = curWID;
   _SetDialogInfoHt("versionToWID",versionToWID);
}

void ctltree1.on_change(int reason,int changingindex)
{
   if ( _GetDialogInfoHt('DELETING_TREE')==1 ) {
      return;
   }
   if ( changingindex<0 ) {
      return;
   }
   switch ( reason ) {
   case CHANGE_EXPANDED:
      {
         int state,bm1;
         _TreeGetInfo(changingindex,state,bm1);
         if ( bm1!=_pic_file ) {
            break;
         }
      }
   case CHANGE_SELECTED:
      {
         int index=_svcGetVersionIndex(changingindex,true);
         if ( index<0 ) {
            ctldiff.p_enabled=false;
            ctlview.p_enabled=false;
         } else {
            ctldiff.p_enabled=true;
            ctlview.p_enabled=true;
         }
         int wid=p_window_id;
         p_window_id=ctlminihtml2;
         if ( index>-1 ) {
            HISTORY_USER_INFO info = ctltree1._TreeGetUserInfo(index);
            if ( VF_IS_STRUCT(info) ) {
               _TextBrowserSetHtml(ctlminihtml2,"");
               len := info.lineArray._length();
               infoStr := "";
               for ( i:=0;i<len;++i ) {
                  infoStr = infoStr:+"\n":+info.lineArray[i];
               }
               _TextBrowserSetHtml(ctlminihtml2,infoStr);
            } else {
               _TextBrowserSetHtml(ctlminihtml2,"");
            }
         } else {
            _TextBrowserSetHtml(ctlminihtml2,"");
         }
         p_window_id=wid;
         break;
      }
   }
}

void ctlminihtml2.on_change(int reason,_str href="")
{
   if ( href=="" ) return;
   IVersionControl *pVCI = svcGetInterface(def_vc_system);
   if ( pVCI==null ) return;

   parse href with auto command '(' auto args ')' ;
   if ( command=="" ) return;


   switch (lowcase(command)) {
   case 'expandtags':
      {
         index := (int)args;
         curIndex := index;
         prevIndex := ctltree1._TreeGetPrevIndex(curIndex);
         if ( prevIndex>=0 ) {
//            selectedVersion := ctltree1._TreeGetCaption(curIndex);
//            prevVersion := ctltree1._TreeGetCaption(prevIndex);
            HISTORY_USER_INFO selectedVersionInfo = ctltree1._TreeGetUserInfo(curIndex);
            HISTORY_USER_INFO prevVersionInfo = ctltree1._TreeGetUserInfo(prevIndex);
            ctltree1.fillInTagsHTML(index,prevVersionInfo.actualRevision,selectedVersionInfo.actualRevision);
         }
         break;
      }
   case 'diff':
      {
         curIndex := ctltree1._TreeCurIndex();
         prevIndex := ctltree1._TreeGetPrevSiblingIndex(curIndex);
         selectedVersion := ctltree1._TreeGetCaption(curIndex);
         prevVersion := ctltree1._TreeGetCaption(prevIndex);

         origFID := p_active_form;
         parse args with auto wid1 ',' auto wid2 ',' auto firstLine1 ',' auto lastLine1 ',' auto firstLine2 ',' auto lastLine2;
         diff('-modal -r1 -r2 -file1title "Version 'selectedVersion'" -file2title "Version 'prevVersion'" -range1:'firstLine2','lastLine2' -range2:'firstLine1','lastLine1' -viewid1 -viewid2 'wid2' 'wid1);
         origFID._set_focus();
         break;
      }
   case 'view':
      {
         parse args with auto wid ',' auto firstLine ',' auto lastLine ',' auto addedOrRemoved;

         if ( !isinteger(wid) ||!isinteger(firstLine) || !isinteger(lastLine) ) return;

         origWID := _create_temp_view(auto tempWID);

         p_window_id = (int)wid;
         markid := _alloc_selection();
         p_line=(int)firstLine;
         _select_line(markid);
         p_line=(int)lastLine;
         _select_line(markid);

         p_window_id = tempWID;
         _copy_to_cursor(markid);
         _free_selection(markid);

         p_window_id = origWID;
         _showbuf(tempWID,false,"-new -modal","View "addedOrRemoved" function");
         _delete_temp_view(tempWID);
         break;
      }
   }
}

int _svcGetVersionIndex(int index=-1, boolean convertBranches=false)
{
   if ( index==-1 ) {
      index=_TreeCurIndex();
   }
   int state,bm1;
   _TreeGetInfo(index,state,bm1);
   if ( bm1==_pic_branch ) {
      return index;
   } else if ( bm1!=_pic_file ) {
      return(-1);
   }
   return(index);
}

void _svc_history_form.on_resize()
{
   int client_width=_dx2lx(SM_TWIP,p_client_width);
   int client_height=_dy2ly(SM_TWIP,p_client_height);

   int xbuffer=ctlminihtml1.p_x;
   ctlminihtml1.p_width=(/*2**/(client_width intdiv 2))-(xbuffer*2);
   ctltree1.p_x=ctlminihtml1.p_x+ctlminihtml1.p_width+xbuffer;
   ctltree1.p_width=(client_width intdiv 2)-(xbuffer);
   ctltree1.p_height=ctlminihtml1.p_height;

   int ybuffer=ctlminihtml1.p_y;

   client_height-=ctlclose.p_height;
   ctlminihtml1.p_height=(2*(client_height intdiv 3))-(ybuffer*3);

   ctltree1.p_height=ctlminihtml1.p_height;

   ctlminihtml2.p_width=client_width-(xbuffer*2);
   ctlminihtml2.p_height=(client_height intdiv 3)-(ybuffer);
   ctlminihtml2.p_y=ctltree1.p_y+ctltree1.p_height+ybuffer;
   ctlclose.p_y=ctlminihtml2.p_y+ctlminihtml2.p_height+ybuffer;
   ctlclose.p_next.p_y=ctlclose.p_y;
   ctlclose.p_next.p_next.p_y=ctlclose.p_y;
   ctlview.p_y=ctlrevert.p_y=ctlrefresh.p_y=ctlupdate.p_y=ctlclose.p_y;
}

static _str localFilenameFromHistoryDialog()
{
   parse ctlminihtml1.p_text with "<B>File:</B>" auto filename '<BR>';
   return filename;
}

static void diffMenuButton()
{
   int menu_index=find_index("_svc_history_menu",oi2type(OI_MENU));
   int diff_menu_index=_menu_find_caption(menu_index,"Diff");
   int menu_handle=_mdi._menu_load(diff_menu_index,'P');
   int flags=VPM_LEFTBUTTON;
   int x=_lx2dx(SM_TWIP,ctldiff.p_x);
   int y=_ly2dy(SM_TWIP,ctldiff.p_y+ctldiff.p_height);
   _map_xy(p_active_form,0,x,y,SM_PIXEL);
   _menu_show(menu_handle,flags,x,y);
}

void ctldiff.lbutton_up(int reason=0)
{
   if( reason == CHANGE_SPLIT_BUTTON ) {
      // Drop-down menu
      diffMenuButton();
      return;
   }
   diffLocalFileWithPastVersion();
}

void ctlview.lbutton_up()
{
   curIndex := ctltree1._TreeCurIndex();
   if ( curIndex<0 ) return;
   IVersionControl *pVCI = svcGetInterface(def_vc_system);
   if ( pVCI==null ) return;

   currentVersionCaption := ctltree1._TreeGetCaption(curIndex);

   localFilename := localFilenameFromHistoryDialog();
   versionNumber := "";
   pVCI->getVersionNumberFromVersionCaption(currentVersionCaption,versionNumber);
   status := pVCI->getFile(localFilename,versionNumber,auto fileWID);
   if ( status ) return;

   status = pVCI->getRemoteFilename(localFilename,auto remoteFilename);
   if ( status ) return;

   origFormID := p_active_form;
   _showbuf(fileWID.p_buf_id,true,'-new -modal',remoteFilename' (Version 'versionNumber')','S',true);
   _delete_temp_view(fileWID);
   origFormID.ctltree1._set_focus();
}

void ctlupdate.lbutton_up()
{
   curIndex := ctltree1._TreeCurIndex();
   if ( curIndex<0 ) return;
   IVersionControl *pVCI = svcGetInterface(def_vc_system);
   if ( pVCI==null ) return;

   localFilename := localFilenameFromHistoryDialog();
   if ( p_caption==UPDATE_BUTTON_CAPTION ) {
      pVCI->updateFile(localFilename);
   } else if ( p_caption==EDIT_BUTTON_CAPTION ) {
      pVCI->editFile(localFilename);
   }
   refreshDialog(localFilename);

   ctltree1._set_focus();
}

void ctlrevert.lbutton_up()
{
   curIndex := ctltree1._TreeCurIndex();
   if ( curIndex<0 ) return;
   IVersionControl *pVCI = svcGetInterface(def_vc_system);
   if ( pVCI==null ) return;

   localFilename := localFilenameFromHistoryDialog();
   status := pVCI->revertFile(localFilename);
   if ( !status ) {
      refreshDialog(localFilename);
   }

   ctltree1._set_focus();
}

static int svcHistoryGetVersionsFromHistoryTree(_str &ver1,_str &ver2='',int &index1=-1,int &index2=-1)
{
   int wid=p_window_id;
   p_window_id=ctltree1;
   int index=_TreeCurIndex();
   int state,bm1;
   _TreeGetInfo(index,state,bm1);

   while ( bm1==_pic_branch ) {
      index=_TreeGetParentIndex(index);
      if ( index<0 ) {
         return(1);
      }
      _TreeGetInfo(index,state,bm1);
   }
   if ( index==TREE_ROOT_INDEX ) {
      return(1);
   }
   IVersionControl *pVCI = svcGetInterface(def_vc_system);
   if ( pVCI==null ) {
      return 1;
   }
   
   ver1Caption := ctltree1._TreeGetCaption(index);

   versionNumber := "";
   pVCI->getVersionNumberFromVersionCaption(ver1Caption,ver1);

   index1 = index;

   for ( ;; ) {
      sibindex := _TreeGetPrevSiblingIndex(index);
      if ( sibindex<0 ) {
         sibindex = _TreeGetParentIndex(index);
         if ( sibindex<0 ) {
            return(1);
         }
      }
      index = sibindex;
      _TreeGetInfo(index,state,bm1);
      if ( bm1!=_pic_branch ) break;
   }
   if ( index==TREE_ROOT_INDEX ) {
      return(1);
   }
   ver2Caption := ctltree1._TreeGetCaption(index);
   pVCI->getVersionNumberFromVersionCaption(ver2Caption,ver2);
   index2 = index;

   p_window_id=wid;
   return(0);
}

int _OnUpdate_svc_history_diff_predecessor(CMDUI &cmdui,int target_wid,_str command)
{
   if( target_wid.p_name != '_svc_history_form' &&
       target_wid.p_parent.p_name != '_svc_history_form' ) {
      return(MF_GRAYED);
   }
   _str ver1='',ver2='';
   int status=svcHistoryGetVersionsFromHistoryTree(ver1,ver2);
   if ( status ) {
      return(MF_GRAYED);
   }
   _menu_set_state(cmdui.menu_handle,cmdui.menu_pos,0,'P','Diff version 'ver1' with version 'ver2);
   return(MF_ENABLED);
}
int _OnUpdate_svc_history_diff_past(CMDUI &cmdui,int target_wid,_str command)
{
   if( target_wid.p_name != '_svc_history_form' &&
       target_wid.p_parent.p_name != '_svc_history_form' ) {

      return(MF_GRAYED);
   }
   _str ver1='',ver2='';
   int status=svcHistoryGetVersionsFromHistoryTree(ver1,ver2);
   if ( status ) {
      return(MF_GRAYED);
   }
   status=_menu_set_state(cmdui.menu_handle,cmdui.menu_pos,0,'P','Diff version 'ver1' with other version...');
   return(MF_ENABLED);
}

static _str gURLTable:[];

_command void svc_history_diff_local()
{
   if ( p_active_form.p_name!='_svc_history_form' ) {
      // Do not want to run this from the command line, etc.
      return;
   }
//   localFilename := localFilenameFromHistoryDialog();
//   svc_diff_with_tip(localFilename);
   diffLocalFileWithPastVersion();
}

static void diffLocalFileWithPastVersion()
{
   curIndex := ctltree1._TreeCurIndex();
   if ( curIndex<0 ) return;
   IVersionControl *pVCI = svcGetInterface(def_vc_system);
   if ( pVCI==null ) return;

   currentVersionCaption := ctltree1._TreeGetCaption(curIndex);

   localFilename := localFilenameFromHistoryDialog();

   versionNumber := "";

   // Look to see if there was a revision caption.  If there was, we will use
   // that revision
   index := ctltree1._TreeCurIndex();
   HISTORY_USER_INFO info = ctltree1._TreeGetUserInfo(index);
   len := info.lineArray._length();
   for (i:=0;i<len;++i) {
      curLine := info.lineArray[i];
      parse curLine with "<B>Revision:</B>&nbsp;" versionNumber "<br>";
      if ( versionNumber!="" ) break;
   }

   // If we did not find a revision caption, Use the caption and get the 
   // revision number from that
   if ( versionNumber == "" ) {
      pVCI->getVersionNumberFromVersionCaption(currentVersionCaption,versionNumber);
   }

   origFormID := p_active_form;
   pVCI->diffLocalFile(localFilename,versionNumber);
   origFormID.ctltree1._set_focus();
}

_command void svc_history_diff_predecessor()
{
   if ( p_active_form.p_name!='_svc_history_form' ) {
      // Do not want to run this from the command line, etc.
      return;
   }
   int wid=ctltree1;
   _str ver1='',ver2='';
   int status=svcHistoryGetVersionsFromHistoryTree(ver1,ver2,auto treeIndex1,auto treeIndex2);
   if ( status ) return;
   IVersionControl *pVCI = svcGetInterface(def_vc_system);
   if ( pVCI==null ) return;

   localFilename := localFilenameFromHistoryDialog();
   _str remoteFilename='';
   status = pVCI->getRemoteFilename(localFilename,remoteFilename);
   if ( status ) return;
   // Have to do some extra work to get the branches for each file to be sure we
   // are comparing the right files.
   ctltree1.getSVCURLFromTreeIndex(auto fileURL1="",treeIndex1,ver1,remoteFilename);
   ctltree1.getSVCURLFromTreeIndex(auto fileURL2="",treeIndex2,ver2,remoteFilename); 
   if ( fileURL1!="" && fileURL2!="" ) {
      SVCDiffTwoURLs(fileURL1,fileURL2,ver1,ver2);
   }else{
      if ( remoteFilename=="" ) {
         remoteFilename = localFilename;
      }
      svcDiffPastVersions(remoteFilename,ver1,ver2);
   }
   wid._set_focus();
}       

static int svcHistoryDiffPast(_str filename)
{
   _nocheck _control ctltree1;
   _str ver1='';
   int status=svcHistoryGetVersionsFromHistoryTree(ver1);

   _control ctltree1;
   int tree1=p_active_form.ctltree1;

   int wid=show('_svc_get_past_version_form',"Choose other version",'"'ver1'"',_pic_branch' '_pic_symbol' '_pic_symbold' '_pic_symbold2' '_pic_symbolm' '_pic_symbolp);
   _TreeCopy(TREE_ROOT_INDEX,TREE_ROOT_INDEX,tree1,wid.ctltree1);
   _str result=_modal_wait(wid);
   if ( result=='' ) {
      return(COMMAND_CANCELLED_RC);
   }
   _str ver2=result;
   IVersionControl *pVCI = svcGetInterface(def_vc_system);
   if ( pVCI==null ) return -1;

   pVCI->getVersionNumberFromVersionCaption(ver2,ver2);

   localFilename := localFilenameFromHistoryDialog();
   _str remoteFilename='';
   status = pVCI->getRemoteFilename(localFilename,remoteFilename);
   if ( status ) return(1);

   svcDiffPastVersions(localFilename,ver1,ver2);

   tree1._set_focus();
   return(0);
}

_command void svc_history_diff_past()
{
   if ( p_active_form.p_name!='_svc_history_form' ) {
      // Do not want to run this from the command line, etc.
      return;
   }
//   _str ver1='',ver2='';
//   int status=_SVNGetVersionsFromHistoryTree(ver1,ver2);
//   if ( status ) return;
   IVersionControl *pVCI = svcGetInterface(def_vc_system);
   if ( pVCI==null ) return;
   localFilename := localFilenameFromHistoryDialog();
   status := pVCI->getRemoteFilename(localFilename,auto remoteFilename);
   if ( status ) return;
   svcHistoryDiffPast(remoteFilename);
}


static void getSVCURLFromTreeIndex(_str &fileURL,int treeIndex,_str version,_str remoteFilename)
{
   fileURL = "";
   url := gURLTable:[treeIndex];
   if ( url!=null ) {
      fileURL = url;
   } else {
      fileURL = remoteFilename;
   }
}

static int SVCDiffTwoURLs(_str fileURL1,_str fileURL2,_str ver1,_str ver2)
{
   IVersionControl *pVCI = svcGetInterface(def_vc_system);
   if ( pVCI==null ) return 1;

   status := pVCI->getFile(fileURL1,ver1,auto fileWID1);
   if ( status ) return status;

   status = pVCI->getFile(fileURL2,ver2,auto fileWID2);
   if ( status ) return status;
   if ( fileWID1<0 || fileWID2<0 ) {
      return SVC_COULD_NOT_GET_CURRENT_VERSION_FILE;
   }

   diff('-modal -r1 -r2 -bi1 -bi2 -file1title "'fileURL1' (Version'ver1')" -file2title "'fileURL2' (Version'ver2')"' fileWID1.p_buf_id' 'fileWID2.p_buf_id);

   _delete_temp_view(fileWID1);
   _delete_temp_view(fileWID2);

   return 0;
}

static int svcDiffPastVersions(_str remoteFilename,_str ver1,_str ver2)
{
   IVersionControl *pVCI = svcGetInterface(def_vc_system);
   if ( pVCI==null ) return 1;

   status := pVCI->getFile(remoteFilename,ver1,auto fileWID1);
   if ( status ) return status;

   status = pVCI->getFile(remoteFilename,ver2,auto fileWID2);
   if ( status ) return status;

   status = diff('-modal -r1 -r2 -bi1 -bi2 -file1title "'remoteFilename' (Version'ver1')" -file2title "'remoteFilename' (Version'ver2')"' fileWID1.p_buf_id' 'fileWID2.p_buf_id);

   _delete_temp_view(fileWID1);
   _delete_temp_view(fileWID2);

   return status;
}

defeventtab _svc_get_past_version_form;

_str svcGetRevisionString(int index)
{
   _str version=_TreeGetCaption(index);
   parse version with version " -- " . ;
   return strip(version);
}

void ctlok.on_create(_str caption='',_str DisableCapList='',_str DisableBMList='')
{
   if ( caption!='' ) {
      p_active_form.p_caption=caption;
   }
   _SetDialogInfoHt("disableList",DisableCapList'|'DisableBMList);
}

void ctlok.lbutton_up()
{
   _str version=ctltree1.svcGetRevisionString(ctltree1._TreeCurIndex());
   p_active_form._delete_window(version);
}

void ctltree1.ENTER()
{
   ctlok.call_event(ctlok,LBUTTON_UP);
}

void ctltree1.on_change(int reason,int index)
{
   if ( index<0 ) return;

   switch ( reason ) {
   case CHANGE_LEAF_ENTER:
      {
         ctlok.call_event(ctlok,LBUTTON_UP);
         break;
      }
   case CHANGE_SELECTED:
      {
         IVersionControl *pVCI = svcGetInterface(def_vc_system);
         if ( pVCI==null ) return;

         versionCap := svcGetRevisionString(index);
         pVCI->getVersionNumberFromVersionCaption(versionCap,auto versionNumber);
         _str DisableCapList,DisableBMList;
         parse _GetDialogInfoHt("disableList") with DisableCapList'|'DisableBMList;
         int state,bm1;
         _TreeGetInfo(index,state,bm1);
         if ( pos('"'versionNumber'"',DisableCapList) || pos(' 'bm1' ',' 'DisableBMList' ') ) {
            ctlok.p_enabled=0;
         } else {
            ctlok.p_enabled=1;
         }
         break;
      }
   }
}

void _svc_get_past_version_form.on_resize()
{
   int client_width=_dx2lx(SM_TWIP,p_client_width);
   int client_height=_dy2ly(SM_TWIP,p_client_height);
   int xbuffer=ctltree1.p_x;
   int ybuffer=ctltree1.p_y;

   ctltree1.p_width=client_width-(xbuffer*2);

   ctltree1.p_height=client_height-ctlok.p_height-(xbuffer*3);

   ctlok.p_y=ctlok.p_next.p_y=ctltree1.p_x+ctltree1.p_height+ybuffer;
}
