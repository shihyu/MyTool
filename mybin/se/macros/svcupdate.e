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
#include "svc.sh"
#import "cvs.e"
#import "cvsutil.e"
#import "diff.e"
#import "dirlist.e"
#import "fileman.e"
#import "filewatch.e"
#import "guicd.e"
#import "guiopen.e"
#import "main.e"
#import "mprompt.e"
#import "listbox.e"
#import "seltree.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "svc.e"
#import "treeview.e"
#import "vc.e"
#require "se/vc/IVersionControl.e"
#endregion

using se.vc.IVersionControl;

#define controlXExtent(a) (a.p_x+a.p_width)
#define controlYExtent(a) (a.p_y+a.p_height)
defeventtab _svc_mfupdate_form;
void ctlupdate_all.lbutton_up()
{
   _str Captions[];
   Captions[0]='Update only new files and files that are not modified';
   Captions[1]='Update all files that are not in conflict';

   int result=RadioButtons("Update all files",Captions,1,'cvs_update_all');
   updateAll := false;
   if ( result==COMMAND_CANCELLED_RC ) {
      return;
   } else if ( result==1 ) {
   } else if ( result==2 ) {
      updateAll = true;
   }
   // Select all the out of date files.
   ctltree1.updateSelectOutOfDate(true,TREE_ROOT_INDEX,updateAll);

   // Be sure the buttons are enabled right
   svcEnableGUIUpdateButtons();

   // Call the button, but first be sure it is an update button
   if ( ctlupdate.p_caption==UPDATE_CAPTION_UPDATE ) {
      ctlupdate.call_event(ctlupdate,LBUTTON_UP);
   }
}

void _SVCGUIUpdateDialog(SVC_UPDATE_INFO (&fileStatusList)[],_str path,_str moduleName,
                         boolean modal=false)
{
   IVersionControl *pInterface = svcGetInterface(def_vc_system);
   if ( pInterface==null ) return;
   modalOption := "";
   if ( modal ) modalOption = " -modal ";
   int formid=show('-xy -app -new ':+modalOption:+' _svc_mfupdate_form',fileStatusList,path,moduleName);
   if ( !modal ) {
      formid.p_active_form.p_caption=pInterface->getSystemNameCaption():+' ':+formid.p_active_form.p_caption;
   }
}

void ctlclose.on_create(SVC_UPDATE_INFO (&fileStatusList)[]=null,_str path="",_str moduleName="")
{
   ctllocal_path_label.p_caption = "Local Path:":+path;
   ctlrep_label.p_caption = "Repository:":+moduleName;
   origWID := p_window_id;

   _nocheck _control ctltree1;
   p_window_id = ctltree1;
   SVCSetupTree(fileStatusList,path,moduleName);
   p_window_id = origWID;
}

void ctlhistory.lbutton_up()
{
   IVersionControl *pInterface = svcGetInterface(def_vc_system);
   if ( pInterface==null ) return;

   index := ctltree1._TreeCurIndex();
   if ( index<0 ) return;
   filename := svcGetFilenameFromUpdateTree(index);
   if ( filename=="" ) return;
   svc_history(filename);
   ctltree1._set_focus();
}

void ctldiff.lbutton_up()
{
   IVersionControl *pInterface = svcGetInterface(def_vc_system);
   if ( pInterface==null ) return;

   INTARRAY selectedIndexList;
   STRARRAY selectedFileList;
   INTARRAY oldModFileDiff;
   int info;

   origWID := p_window_id;
   origFID := p_active_form;
   p_window_id = ctltree1;
   // Add all the selected items
   for ( ff:=1;;ff=0 ) {
      index := _TreeGetNextCheckedIndex(ff,info);
      if ( index<0 ) break;
      ARRAY_APPEND(selectedIndexList,index);
      ctltree1._TreeGetInfo(index,auto state,auto bm1);
      if ( bm1==_pic_file_old_mod ) {
         ARRAY_APPEND(oldModFileDiff,1);
      } else {
         ARRAY_APPEND(oldModFileDiff,0);
      }

   }

   // If no items were selected, add the current item
   if ( selectedIndexList._length()==0 ) {
      index := _TreeCurIndex();
      if ( index>=0 )ARRAY_APPEND(selectedIndexList,index);
      ctltree1._TreeGetInfo(index,auto state,auto bm1);
      if ( bm1==_pic_file_old_mod ) {
         ARRAY_APPEND(oldModFileDiff,1);
      } else {
         ARRAY_APPEND(oldModFileDiff,0);
      }
   }
   p_window_id = origWID;

   len := selectedIndexList._length();
   for ( i:=0;i<len;++i ) {
      filename := svcGetFilenameFromUpdateTree(selectedIndexList[i]);
      ARRAY_APPEND(selectedFileList,filename);
      if ( filename=="" ) continue;
      if ( oldModFileDiff[i]==1 ) {
         STRARRAY captions;
         pInterface->getCurLocalRevision(filename,auto curLocalRevision);
         pInterface->getCurRevision(filename,auto curRevision);
         captions[0]='Compare local version 'curLocalRevision' with remote version 'curLocalRevision;
         captions[1]='Compare local version 'curLocalRevision' with remote version 'curRevision;
         captions[2]='Compare remote version 'curLocalRevision' with remote version 'curRevision;
         int result=RadioButtons("Newer version exists",captions,1,'cvs_diff');
         if ( result==COMMAND_CANCELLED_RC ) {
            return;
         } else if ( result==1 ) {
            svc_diff_with_tip(filename,curLocalRevision);
         } else if ( result==2 ) {
            svc_diff_with_tip(filename,curRevision);
         } else if ( result==3 ) {
//            both_remote=true;
//            version_to_compare=curRevision;
            status := pInterface->getFile(filename,curLocalRevision,auto curLocalRevisionRemoteWID);
            if ( !status ) {
               status = pInterface->getFile(filename,curRevision,auto curRemoteRevisionWID);
               if ( !status ) {
                  pInterface->getLocalFileURL(filename,auto URL);
                  diff('-modal -r1 -r2 -file1title "'URL' 'curLocalRevision'" -file2title "'URL' 'curRevision'" -viewid1 -viewid2 'curLocalRevisionRemoteWID' 'curRemoteRevisionWID);
                  _delete_temp_view(curRemoteRevisionWID);
               }
               _delete_temp_view(curLocalRevisionRemoteWID);
            }
         }
      } else {
         svc_diff_with_tip(filename);
      }
   }
   origFID.refreshAfterOperaiton(selectedFileList,selectedIndexList,null,pInterface,false);
   origFID.ctltree1._set_focus();
}

void ctlupdate.lbutton_up()
{
   IVersionControl *pInterface = svcGetInterface(def_vc_system);
   if ( pInterface==null ) return;

   isUpdateButton := lowcase(stranslate(p_caption,"",'&'))==lowcase(pInterface->getCaptionForCommand(SVC_COMMAND_UPDATE,false));
   isCommitButton := lowcase(stranslate(p_caption,"",'&'))==lowcase(pInterface->getCaptionForCommand(SVC_COMMAND_COMMIT,false));
   isMergeButton :=  lowcase(stranslate(p_caption,"",'&'))==lowcase(pInterface->getCaptionForCommand(SVC_COMMAND_MERGE,false));
   isAddButton :=    lowcase(stranslate(p_caption,"",'&'))==lowcase(pInterface->getCaptionForCommand(SVC_COMMAND_ADD,false));

#if 0 //9:27am 4/4/2013
   say('ctlupdate.lbutton_up isUpdateButton='isUpdateButton);
   say('ctlupdate.lbutton_up isCommitButton='isCommitButton);
   say('ctlupdate.lbutton_up isMergeButton='isMergeButton);
   say('ctlupdate.lbutton_up isAddButton='isAddButton);
#endif

   INTARRAY selectedIndexList;
   STRARRAY selectedFileList;
   int info;

   mou_hour_glass(true);
   origWID := p_window_id;
   origFID := p_active_form;
   p_window_id = ctltree1;
   // Add all the selected items
   _str fileTable:[];
   directoriesAreInList := false;
   for ( ff:=1;;ff=0 ) {
      index := _TreeGetNextCheckedIndex(ff,info);
      if ( index<0 ) break;
      if ( index==TREE_ROOT_INDEX ) continue;
      if ( _TreeGetCheckState(index)==TCB_CHECKED ) {
         ARRAY_APPEND(selectedIndexList,index);
         filename := svcGetFilenameFromUpdateTree(index,true);
         if (last_char(filename)==FILESEP) continue;
         ARRAY_APPEND(selectedFileList,filename);
         if ( last_char(filename)==FILESEP ) {
            directoriesAreInList = true;
         }
         fileTable:[_file_case(filename)] = "";
      }
   }

   // If no items were selected, add the current item
   if ( selectedIndexList._length()==0 ) {
      index := _TreeCurIndex();
      if ( index>=0 )ARRAY_APPEND(selectedIndexList,index);
      filename := svcGetFilenameFromUpdateTree(index);
      ARRAY_APPEND(selectedFileList,filename);
   }
   p_window_id = origWID;

   status := 0;
   if ( isUpdateButton ) {
      if ( pInterface->getSystemSpecificFlags()&SVC_UPDATE_PATHS_RECURSIVE &&
           directoriesAreInList
           ) {
#if 0 //8:45am 3/28/2013
         caption := pInterface->getCaptionForCommand(SVC_COMMAND_UPDATE,false);
         status = _message_box(nls("You have directories selected, this will %s all files under the directories. \n\nContinue?",caption),"",MB_YESNOCANCEL);
         if ( status!=IDYES ) {
            return;
         }
#endif
         removeChildFiles(selectedFileList);
      }
      status = pInterface->updateFiles(selectedFileList);
   } else if ( isCommitButton ) {
      if ( pInterface->getSystemSpecificFlags()&SVC_UPDATE_PATHS_RECURSIVE &&
           directoriesAreInList
           ) {
#if 0 //8:45am 3/28/2013
         caption := pInterface->getCaptionForCommand(SVC_COMMAND_COMMIT,false);
         status = _message_box(nls("You have directories selected, this will %s all files under the directories. \n\nContinue?",caption),"",MB_YESNOCANCEL);
         if ( status!=IDYES ) {
            return;
         }
#endif
         removeChildFiles(selectedFileList);
      }
      status = pInterface->commitFiles(selectedFileList);
   } else if ( isAddButton ) {
      status = pInterface->addFiles(selectedFileList);
   } else if ( isMergeButton ) {
      // We only allow the merge button for a single file
      status = pInterface->mergeFile(selectedFileList[0]);
   }
   _filewatchRefreshFiles(selectedFileList);
   if ( status ) {
      // If something failed, or a commit was cancelled, we don't want to clear
      // the checkboxes below
      return;
   }

   refreshAfterOperaiton(selectedFileList,selectedIndexList,fileTable,pInterface);
   if ( status ) return;
   p_window_id = origWID;
   origFID.ctltree1._set_focus();
}

static void refreshAfterOperaiton(STRARRAY &selectedFileList,INTARRAY selectedIndexList,_str (&fileTable):[],IVersionControl *pInterface,boolean uncheck=true)
{
//   INTARRAY selectedIndexList;
   
   int pathIndexTable:[];
   // now got thru and set appropriate pictures
   len := selectedFileList._length();
   p_window_id = ctltree1;
   for ( i:=0;i<len;++i ) {
      SVC_UPDATE_INFO curFileInfo;
      curFileInfo.filename = selectedFileList[i];
      
      // For the case of a diff, the fileTable can be null
      if ( fileTable!=null ) fileTable._deleteel(_file_case(selectedFileList[i]));

      if ( last_char(curFileInfo.filename)==FILESEP ) {
         status := pInterface->getMultiFileStatus(curFileInfo.filename,auto fileStatusList);
         SVCUpdateCheckedItemsToData(fileStatusList);
      } else {
         // Get the status from the version control system
         status := pInterface->getFileStatus(curFileInfo.filename,curFileInfo.status);
         if ( status ) break;

         // Get the picture for the status
         _SVCGetFileBitmap(curFileInfo,auto bitmap);

         curPath := _file_path(_file_case(curFileInfo.filename));
         modedPathIndex := pathIndexTable:[curPath];
         if ( modedPathIndex==null ) {
            modedPathIndex = _TreeSearch(TREE_ROOT_INDEX,curPath,'T'_fpos_case);
            pathIndexTable:[curPath] = modedPathIndex;
         }
         // If the new picture doesn't match, set the new picture
         modedIndex := _TreeSearch(modedPathIndex,_strip_filename(curFileInfo.filename,'P'),_fpos_case);
         if ( modedIndex>=0 ) {
            _TreeGetInfo(modedIndex,auto state,auto curBitmap);
            if ( curBitmap!=bitmap ) {
               _TreeSetInfo(modedIndex,state,bitmap);
            }
         }
         if ( fileTable!=null ) {
            // For the case of a diff, the fileTable can be null
            foreach ( auto curFilename => auto curValue in fileTable ) {
               curPath = _file_path(_file_case(curFilename));
               modePathIndex := pathIndexTable:[curPath];
               if ( modePathIndex==null ) {
                  modePathIndex = _TreeSearch(TREE_ROOT_INDEX,curPath,'T'_fpos_case);
                  pathIndexTable:[curPath] = modePathIndex;
               }
               fileIndex := _TreeSearch(TREE_ROOT_INDEX,_strip_filename(curFilename,'P'),'T'_fpos_case);
               if ( fileIndex>=0 ) {
                  _TreeGetInfo(fileIndex,auto state);
                  _TreeSetInfo(fileIndex,state,_pic_cvs_file);
               }
            }
         }
      }
   }
   if ( uncheck ) {
      foreach ( auto curIndex in selectedIndexList ) {
         _TreeSetCheckState(curIndex,TCB_UNCHECKED);
      }
   }
   svcEnableGUIUpdateButtons();

   mou_hour_glass(false);
}

static void removeChildFiles(STRARRAY &selectedFileList)
{
   len := selectedFileList._length();
   STRHASHTAB dirTable;
   INTARRAY dirIndexes;

   for ( i:=0;i<len;++i ) {
      curFile := _file_case(selectedFileList[i]);
      if ( last_char(curFile)==FILESEP ) {
         dirTable:[curFile] = "";
         ARRAY_APPEND(dirIndexes,i);
      }
   }
   INTARRAY delList;
   for ( i=0;i<len;++i ) {
      curFile := _file_case(selectedFileList[i]);
      if ( last_char(curFile)!=FILESEP ) {
         curPath := _file_path(curFile);
         if ( dirTable:[curPath]!=null ) {
            // This file will be handled by the directory
            ARRAY_APPEND(delList,i);
         }
      }
   }
   // Now let's see if we can get rid of any directories.
   len = dirIndexes._length();
   for ( i=0;i<len;++i ) {
      parentPath := _file_case(getParentPath(selectedFileList[dirIndexes[i]]));
      if ( dirTable:[parentPath]!=null ) {
         ARRAY_APPEND(delList,dirIndexes[i]);
      }
   }

   len = delList._length();
   for ( i=len-1;i>=0;--i ) {
      selectedFileList._deleteel(delList[i]);
   }
}


static _str getParentPath(_str path)
{
   if ( last_char(path)==FILESEP ) {
      path = substr(path,1,length(path)-1);
   }
   return _strip_filename(path,'N');
}

void ctlrevert.lbutton_up()
{
   // The revert button is currently only visible or invisible.  There is no 
   // other possible caption to concern ourselves with.  Since the button will
   // only be visible when it is possible to press it, we can simplly get our
   // information and perform the revert
   isAddButton := p_caption==SVC_UPDATE_CAPTION_ADD;
   IVersionControl *pInterface = svcGetInterface(def_vc_system);
   if ( pInterface==null ) return;

   INTARRAY selectedIndexList;
   STRARRAY selectedFileList;
   int info;

   mou_hour_glass(true);
   origWID := p_window_id;
   origFID := p_active_form;
   p_window_id = ctltree1;

   // Add all the selected items
   for ( ff:=1;;ff=0 ) {
      index := _TreeGetNextCheckedIndex(ff,info);
      if ( index<0 ) break;
      ARRAY_APPEND(selectedIndexList,index);
      ARRAY_APPEND(selectedFileList,svcGetFilenameFromUpdateTree(index));
   }

   // If no items were selected, add the current item
   if ( selectedIndexList._length()==0 ) {
      index := _TreeCurIndex();
      if ( index>=0 ){
         ARRAY_APPEND(selectedIndexList,index);
         ARRAY_APPEND(selectedFileList,svcGetFilenameFromUpdateTree(index));
      }
   }
   p_window_id = origWID;

   status := pInterface->revertFiles(selectedFileList);
   _filewatchRefreshFiles(selectedFileList);

   _str fileTable:[];
   // now got thru and set appropriate pictures
   len := selectedFileList._length();
   for ( i:=0;i<len;++i ) {

      SVC_UPDATE_INFO curFileInfo;
      curFileInfo.filename = selectedFileList[i];

      // Get the status from the version control system
      status = pInterface->getFileStatus(curFileInfo.filename,curFileInfo.status);
      if ( status ) break;
      fileTable:[_file_case(curFileInfo.filename)] = "";

      // Get the picture for the status
      _SVCGetFileBitmap(curFileInfo,auto bitmap);

      // If the new picture doesn't match, set the new picture
      p_window_id = ctltree1;
      _TreeGetInfo(selectedIndexList[i],auto state,auto curBitmap);
      if ( curBitmap!=bitmap ) {
         _TreeSetInfo(selectedIndexList[i],state,bitmap);
      }
      p_window_id = origWID;
   }

   refreshAfterOperaiton(selectedFileList,selectedIndexList,fileTable,pInterface);

   mou_hour_glass(false);
   if ( status ) return;
   origFID.ctltree1._set_focus();
}

void ctlmerge.lbutton_up()
{
   // The revert button is currently only visible or invisible.  There is no 
   // other possible caption to concern ourselves with.  Since the button will
   // only be visible when it is possible to press it, we can simplly get our
   // information and perform the revert
   isResolveButton := p_caption==SVC_UPDATE_CAPTION_RESOLVE;
   IVersionControl *pInterface = svcGetInterface(def_vc_system);
   if ( pInterface==null ) return;

   INTARRAY selectedIndexList;
   STRARRAY selectedFileList;
   int info;

   mou_hour_glass(true);
   origWID := p_window_id;
   origFID := p_active_form;
   p_window_id = ctltree1;

   // Add all the selected items
   for ( ff:=1;;ff=0 ) {
      index := _TreeGetNextCheckedIndex(ff,info);
      if ( index<0 ) break;
      ARRAY_APPEND(selectedIndexList,index);
      ARRAY_APPEND(selectedFileList,svcGetFilenameFromUpdateTree(index));
   }

   // If no items were selected, add the current item
   if ( selectedIndexList._length()==0 ) {
      index := _TreeCurIndex();
      if ( index>=0 )ARRAY_APPEND(selectedIndexList,index);
      filename := svcGetFilenameFromUpdateTree(index);
      ARRAY_APPEND(selectedFileList,filename);
   }
   p_window_id = origWID;

   status := 0;
   if ( isResolveButton ) {
      status = pInterface->resolveFiles(selectedFileList);
   }
   _filewatchRefreshFiles(selectedFileList);

   // now got thru and set appropriate pictures
   len := selectedFileList._length();
   for ( i:=0;i<len;++i ) {

      SVC_UPDATE_INFO curFileInfo;
      curFileInfo.filename = selectedFileList[i];

      // Get the status from the version control system
      status = pInterface->getFileStatus(curFileInfo.filename,curFileInfo.status);
      if ( status ) break;

      // Get the picture for the status
      _SVCGetFileBitmap(curFileInfo,auto bitmap);

      // If the new picture doesn't match, set the new picture
      p_window_id = ctltree1;
      _TreeGetInfo(selectedIndexList[i],auto state,auto curBitmap);
      if ( curBitmap!=bitmap ) {
         _TreeSetInfo(selectedIndexList[i],state,bitmap);
      }
      p_window_id = origWID;
   }

   mou_hour_glass(false);
   if ( status ) return;
   origFID.ctltree1._set_focus();
}

// Remove CVSGetFilenameFromUpdateTree when this solidifies
static _str svcGetFilenameFromUpdateTree(int index=-1,boolean allowFolders=false)
{
   int wid=p_window_id;
   p_window_id=ctltree1;
   int curindex=index;
   if ( curindex==-1 ) {
      curindex=_TreeCurIndex();

      if ( _TreeGetNumSelectedItems()==1 ) {
         int info;
         selIndex := _TreeGetNextCheckedIndex(1,info);
         if ( selIndex>=0 && selIndex!=curindex ) curindex=selIndex;
      }
   }
   int state,bmindex1,bmindex2;
   _TreeGetInfo(curindex,state,bmindex1,bmindex2);
   _str filename='';
   if ( bmindex1==_pic_cvs_file
        || bmindex1==_pic_cvs_file_qm
        || bmindex1==_pic_file_old
        || bmindex1==_pic_file_old_mod
        || bmindex1==_pic_file_mod
        || bmindex1==_pic_cvs_filep
        || bmindex1==_pic_cvs_filem
        || bmindex1==_pic_cvs_file_new
        || bmindex1==_pic_cvs_file_obsolete
        || bmindex1==_pic_cvs_file_conflict
        || bmindex1==_pic_cvs_file_conflict_updated
        || bmindex1==_pic_cvs_file_conflict_local_added
        || bmindex1==_pic_cvs_file_conflict_local_deleted
        || bmindex1==_pic_cvs_file_error
        || bmindex1==_pic_cvs_filem_mod
        || bmindex1==_pic_file_del
      ) {
      filename=_TreeGetCaption(curindex);
      filename=_TreeGetCaption(_TreeGetParentIndex(curindex)):+filename;
      if ( bmindex1==_pic_cvs_fld_qm ) {
         filename=filename:+FILESEP;
      }
   } else if (    bmindex1==_pic_cvs_fld_m
               || bmindex1==_pic_cvs_fld_p
               || bmindex1==_pic_cvs_fld_qm
               || bmindex1==_pic_cvs_fld_date
               || bmindex1==_pic_cvs_fld_mod
               || (allowFolders && bmindex1==_pic_fldopen)
             ) {
      filename=_TreeGetCaption(curindex);
   }
   p_window_id=wid;
   return(filename);
}

static void SVCSetupTree(SVC_UPDATE_INFO (&fileStatusList)[],_str rootPath,_str moduleName)
{
   IVersionControl *pInterface = svcGetInterface(def_vc_system);
   if ( pInterface==null ) return;
   rootPath = strip(rootPath,'B','"');
   _maybe_append_filesep(rootPath);
   rootIndex :=_TreeAddItem(TREE_ROOT_INDEX,rootPath,TREE_ADD_AS_CHILD,_pic_fldopen,_pic_fldopen);
   _TreeSetCheckable(rootIndex,1,1);
   int pathIndexes:[]=null;
   _SVCSeedPathIndexes(rootPath,pathIndexes,rootIndex);
   len := fileStatusList._length();
   for ( i:=0;i<len;++i ) {
      curPath := _file_path(fileStatusList[i].filename);
      if ( isdirectory(fileStatusList[i].filename) ) {
         curPath = fileStatusList[i].filename;
         _maybe_append_filesep(curPath);
         pathIndex := _SVCGetPathIndex(curPath,rootPath,pathIndexes);
         _SVCGetFileBitmap(fileStatusList[i],auto bmIndex);
         _TreeGetInfo(pathIndex,auto state, auto bm1);
         _TreeSetInfo(pathIndex,state,bmIndex);
         _TreeSetCheckable(pathIndex,1,0);
      } else {
         parentIndex := _SVCGetPathIndex(curPath,rootPath,pathIndexes);
         _SVCGetFileBitmap(fileStatusList[i],auto bmIndex);
         newIndex := _TreeAddItem(parentIndex,_strip_filename(fileStatusList[i].filename,'P'),TREE_ADD_AS_CHILD,bmIndex,bmIndex,-1);
         _TreeSetCheckable(newIndex,1,0);
      }
   }
   ctltree1._TreeSortTree();
}

static void SVCUpdateCheckedItemsToData(SVC_UPDATE_INFO (&fileStatusList)[])
{
   SVC_UPDATE_INFO statusTable:[];
   len := fileStatusList._length();
   for ( i:=0;i<len;++i ) {
      statusTable:[_file_case(fileStatusList[i].filename)] = fileStatusList[i];
   }
   info := 0;
   for ( ff:=1;;ff=0 ) {
      index := _TreeGetNextCheckedIndex(ff,info);
      if ( index<0 ) break;
      curFilename := svcGetFilenameFromUpdateTree(index);
      _TreeGetInfo(index,auto state,auto bm1);
      
      bmIndex := bm1;
      if ( statusTable:[_file_case(curFilename)]==null ) {
         if ( last_char(curFilename)==FILESEP || isdirectory(curFilename) ) {
            bmIndex = _pic_fldopen;
         } else {
            bmIndex = _pic_cvs_file;
         }
      } else {
         _SVCGetFileBitmap(statusTable:[_file_case(curFilename)],bmIndex);
      }
      _TreeSetInfo(index,state,bmIndex);
   }
   ctltree1._TreeSortTree();
}

static void _SVCGetFileBitmap(SVC_UPDATE_INFO &fileStatus,int &bitmap1,int defaultBitmap=_pic_cvs_file,int defaultBitmapFolder=_pic_fldopen)
{
   if ( last_char(fileStatus.filename)==FILESEP ) {
      bitmap1=defaultBitmapFolder;
   } else {
      bitmap1=defaultBitmap;
   }
   if ( fileStatus.status & SVC_STATUS_NOT_CONTROLED ) {
      if ( isdirectory(fileStatus.filename) ) {
         bitmap1=_pic_cvs_fld_qm;
      } else {
         bitmap1=_pic_cvs_file_qm;
      }
      return;
   }
   if ( fileStatus.status & SVC_STATUS_MISSING ) {
      bitmap1=_pic_file_del;
      return;
   }
   if ( fileStatus.status & SVC_STATUS_SCHEDULED_FOR_DELETION ) {
      if ( isdirectory(fileStatus.filename) ) {
         bitmap1=_pic_cvs_fld_m;
      }else{
         bitmap1=_pic_cvs_filem_mod;
      }
      return;
   }
   if ( fileStatus.status & SVC_STATUS_SCHEDULED_FOR_ADDITION ) {
      if ( isdirectory(fileStatus.filename) ) {
         bitmap1=_pic_cvs_fld_p;
      }else{
         bitmap1=_pic_cvs_filep;
      }
      return;
   }
   if ( fileStatus.status & SVC_STATUS_TREE_ADD_CONFLICT ) {
      bitmap1 = _pic_cvs_file_conflict_local_added;
      return;
   }
   if ( fileStatus.status & SVC_STATUS_TREE_DEL_CONFLICT ) {
      bitmap1 = _pic_cvs_file_conflict_local_deleted;
      return;
   }
   if ( fileStatus.status & SVC_STATUS_UNMERGED ) {
      bitmap1 = _pic_cvs_file_not_merged;
      return;
   }
   if ( fileStatus.status & SVC_STATUS_COPIED_IN_INDEX ) {
      bitmap1 = _pic_cvs_file_copied;
      return;
   }

   if ( fileStatus.status & SVC_STATUS_CONFLICT ) {
      bitmap1=_pic_cvs_file_conflict;
   }else{
      if ( fileStatus.status & SVC_STATUS_MODIFIED ) {
         if ( fileStatus.status & SVC_STATUS_NEWER_REVISION_EXISTS ) {
            bitmap1=_pic_file_old_mod;
         }else{
            bitmap1=_pic_file_mod;
         }
      }else if ( fileStatus.status & SVC_STATUS_NEWER_REVISION_EXISTS ) {
         if ( last_char(fileStatus.filename)==FILESEP || 
              _strip_filename(fileStatus.filename,'p')=='.' || 
              isdirectory(fileStatus.filename) ) {
            if ( isdirectory(fileStatus.filename) ) {
               bitmap1=_pic_cvs_fld_date;
            }else{
               bitmap1=_pic_cvs_fld_m;
            }
         }else{
            if ( file_exists(fileStatus.filename) ) {
               bitmap1=_pic_file_old;
            }else{
               bitmap1=_pic_cvs_file_new;
            }
         }
      } else if ( fileStatus.status & SVC_STATUS_PROPS_MODIFIED ) {
         if ( isdirectory(fileStatus.filename) ) {
            bitmap1=_pic_cvs_fld_mod;
         } else {
            bitmap1=_pic_file_mod_prop;
         }
      } else if ( fileStatus.status & SVC_STATUS_PROPS_NEWER_EXISTS ) {
         if ( isdirectory(fileStatus.filename) ) {
            bitmap1=_pic_cvs_fld_date;
         }
      } 
      if ( fileStatus.status & SVC_STATUS_DELETED ) {
         bitmap1=_pic_cvs_filem;
      }
   }
}

void _svc_mfupdate_form.on_resize()
{
   int xbuffer=ctltree1.p_x;
   int client_width=_dx2lx(SM_TWIP,p_client_width);
   int client_height=_dy2ly(SM_TWIP,p_client_height);

   ctltree1.p_width=/*ctltree2.p_width=*/client_width-(2*xbuffer);
   ctlrep_label.p_x=ctltree1.p_x+(ctltree1.p_width intdiv 2);

   ctltree1.p_height=client_height-(ctltree1.p_y+ctlclose.p_height+(xbuffer*5));

   ctlclose.p_y=ctltree1.p_y+ctltree1.p_height+(xbuffer*2);

   ctlmerge.p_y=ctlupdate_all.p_y=ctlrevert.p_y=ctlhistory.p_y=ctldiff.p_y=ctlupdate.p_y=ctlclose.p_y;

   // Shrink the path for the Repository if necessary
   repositoryList := _GetDialogInfoHt("CaptionRepository");
   if ( repositoryList!=null ) {
      parse ctlrep_label.p_caption with auto label ':' auto rest;
      labelWidth := ctlrep_label._text_width(label);
      wholeLabelWidth := (client_width - ctlrep_label.p_x) - labelWidth;
      wholeCaption := label':'ctlrep_label._ShrinkFilename(strip(repositoryList),wholeLabelWidth);
      ctlrep_label.p_caption = wholeCaption;
   }
   if ( controlXExtent(ctllocal_path_label) > ctlrep_label.p_x ) {
      ctlrep_label.p_x = controlXExtent(ctllocal_path_label)+(2*_twips_per_pixel_x());
   }
}

static void _SVCSeedPathIndexes(_str Path,int (&PathTable):[],int SeedIndex)
{
   PathTable:[_file_case(Path)]=SeedIndex;
}

static int _SVCGetPathIndex(_str Path,_str BasePath,int (&PathTable):[],
                            int ExistFolderIndex=_pic_fldopen,
                            int NoExistFolderIndex=_pic_cvs_fld_m,
                            _str OurFilesep=FILESEP,
                            int state=1,
                            int checkable=1)
{
   _str PathsToAdd[];int count=0;
   _str OtherPathsToAdd[];
   int Othercount=0;
   Path=strip(Path,'B','"');
   BasePath=strip(BasePath,'B','"');
   if (PathTable._indexin(_file_case(Path))) {
      return(PathTable:[_file_case(Path)]);
   }
   int Parent=TREE_ROOT_INDEX;
   for (;;) {
      if (Path=='') {
         break;
      }
      PathsToAdd[count++]=Path;
      Path=substr(Path,1,length(Path)-1);
      _str tPath=_strip_filename(Path,'N');
      if (file_eq(Path:+OurFilesep,BasePath) || file_eq(tPath,Path)) break;
      if (isunc_root(Path)) break;
      Path=tPath;
      if (PathTable._indexin(_file_case(Path))) {
         Parent=PathTable:[_file_case(Path)];
         break;
      }
   }
   PathsToAdd._sort('F');
   int i;
   for (i=0;i<PathsToAdd._length();++i) {
      int bmindex;
      if ( isdirectory(PathsToAdd[i] )) {
         bmindex=ExistFolderIndex;
      }else{
         bmindex=NoExistFolderIndex;
      }
      Parent=_TreeAddItem(Parent,
                          PathsToAdd[i],
                          TREE_ADD_AS_CHILD/*|TREE_ADD_SORTED_FILENAME*/,
                          bmindex,
                          bmindex,
                          state);
      isTriState := checkable;
      _TreeSetCheckable(Parent,checkable,isTriState);
      PathTable:[_file_case(PathsToAdd[i])]=Parent;
   }
   return(Parent);
}

void ctltree1.on_change(int reason,int index=-1)
{
   inOnChange := _GetDialogInfoHt("inTreeOnChange");
   if ( index<0 || inOnChange==1 ) {
      return;
   }
   _SetDialogInfoHt("inTreeOnChange",1);
   IVersionControl *pInterface = svcGetInterface(def_vc_system);
   if ( pInterface==null ) {
      _SetDialogInfoHt("inTreeOnChange",0);
      return;
   }
   _str path=_TreeGetCaption(index);
   int state,bmindex1;
   _TreeGetInfo(index,state,bmindex1);
   Nofselected := _TreeGetNumSelectedItems();

   if (Nofselected>1) {
      ctlhistory.p_enabled=false;
   }
   switch ( reason ) {
   case CHANGE_LEAF_ENTER:
      int numSelected = ctltree1._TreeGetNumSelectedItems();
      if (numSelected==1) {
         // Only want to do this if there is one file selected, otherwise
         // it was likely somebody selecting multiple items and accidentally
         // double clicking
         //ctldiff.call_event(ctldiff,LBUTTON_UP);
         filename := svcGetFilenameFromUpdateTree(index);
         if ( filename=="" ) return;
         formWID := p_active_form;
         wid     := p_window_id;
         ctldiff.call_event(ctldiff,LBUTTON_UP);

         SVC_UPDATE_INFO info;
         info.filename = filename;
         SVCFileStatus fileStatus;
         status := pInterface->getFileStatus(info.filename,info.status);
         if ( status ) break;

         // Get the picture for the status
         _SVCGetFileBitmap(info,auto bitmap);

         _TreeGetInfo(index,state,auto curBitmap);
         _TreeSetInfo(index,state,bitmap);

         p_window_id = wid;
         wid._set_focus();
      }
      break;
   }
   svcEnableGUIUpdateButtons();
   _SetDialogInfoHt("inTreeOnChange",0);
}

void ctltree1.rbutton_up()
{
   index := _TreeCurIndex();
   filename := svcGetFilenameFromUpdateTree(index);
   if ( filename=="" ) return;

   _TreeGetInfo(index,auto state,auto bm1);
   isUpdate := bm1==_pic_file_old||bm1==_pic_file_old_mod;
   isCommit := bm1==_pic_file_mod||_pic_cvs_filep;

   int MenuIndex=find_index("_svc_update_rclick",oi2type(OI_MENU));
   int menu_handle=_mdi._menu_load(MenuIndex,'P');

   int x,y;
   mou_get_xy(x,y);

   menuItem := 0;
   // First menu item is diff
   _menu_get_state(menu_handle,menuItem,auto flags,'P',auto caption="",auto command="");
   _menu_set_state(menu_handle,menuItem,flags,'P',caption' 'filename);
   ++menuItem;

   // Second menu item is update or commit, depending on what is selected (not checked)
   updateButtonCaption := ctlupdate.p_caption;
   _menu_get_state(menu_handle,menuItem,flags,'P',caption,command);
   if ( isUpdate ) {
      _menu_set_state(menu_handle,menuItem,flags,'P','Update 'filename,'svc_rclick_command update 'filename);
      ++menuItem;
   } else if ( isCommit ) {
      _menu_set_state(menu_handle,menuItem,flags,'P','Commit 'filename,'svc_rclick_command commit 'filename);
      ++menuItem;
   } else {
      _menu_delete(menu_handle,menuItem);
   }

   // Final menu item is history
   _menu_get_state(menu_handle,menuItem,flags,'P',caption,command);
   _menu_set_state(menu_handle,menuItem,flags,'P',caption' 'filename);

   int status=_menu_show(menu_handle,VPM_RIGHTBUTTON,x-1,y-1);
}

static void svcGetValidBitmaps(int BitmapIndex,_str &ValidBitmaps,_str systemName)
{
   if ( pos(' 'BitmapIndex' ',' 'SVC_BITMAP_LIST_UPDATE' ') ) {
      ValidBitmaps=SVC_BITMAP_LIST_UPDATE;
   }else if ( pos(' 'BitmapIndex' ',' 'SVC_BITMAP_LIST_COMMITABLE' ') ) {
      ValidBitmaps=SVC_BITMAP_LIST_COMMITABLE;
   }else if ( pos(' 'BitmapIndex' ',' 'SVC_BITMAP_LIST_ADD' ') ) {
      ValidBitmaps=SVC_BITMAP_LIST_ADD;
   }else if ( pos(' 'BitmapIndex' ',' 'SVC_BITMAP_LIST_CONFLICT' ') ) {
      ValidBitmaps=SVC_BITMAP_LIST_CONFLICT;
   }else if ( systemName=="hg" && pos(' 'BitmapIndex' ',' 'SVC_BITMAP_LIST_FOLDER' ') ) {
      ValidBitmaps=SVC_BITMAP_LIST_FOLDER;
   }
}

static void svcEnableRevertButton(boolean checkForUpdateDashC)
{
   if ( checkForUpdateDashC ) {
      ctlrevert.p_visible=_CVSUpdateDashCAvailable();
   }else{
      ctlrevert.p_visible=1;
   }
}

static void svcEnableGUIUpdateButtons()
{
   IVersionControl *pInterface = svcGetInterface(def_vc_system);
   if ( pInterface==null ) return;

   systemName := lowcase(pInterface->getSystemNameCaption());

   isCVS := systemName=="cvs";
//   isSVN := systemName=="svn";
   isHg  := systemName=="hg";
   checkForUpdateDashC := isCVS;
   int wid=p_window_id;
   p_window_id=ctltree1;
   int curindex=_TreeCurIndex();
   int state,bmindex1,bmindex2;
   _TreeGetInfo(curindex,state,bmindex1,bmindex2);
   int bmindex=-1;
   int last_selected=-1;
   _str valid_bitmaps='';
   boolean invalid=false;
   int bm1=0;
   addedFile   := false;
   deletedFile := false;
   oldModFile  := false;
   directoriesAreSelected := false;
   boolean no_real_selection=false;
   int selinfo=-1;
   checkedItem := false;
   for ( ff:=1;;ff=0 ) {
      int index=_TreeGetNextCheckedIndex(ff,selinfo);
      if ( index<1 ) {
         break;
         if (ff) {
            // If this is the first time through and we got nothing selected,
            // use the current index and break out of the loop this time through
            no_real_selection=true;
            index=_TreeCurIndex();
         }else break;
      }
      checkedItem = true;
      _TreeGetInfo(index,state,bm1);
      if ( bm1==_pic_cvs_filep ) {
         // We had an added file bitmap
         addedFile=true;
      }
      if ( bm1==_pic_cvs_filem || bm1==_pic_file_del || bm1==_pic_cvs_filem_mod ) {
         // We had a deleted file bitmap
         deletedFile=true;
      }
      if ( bm1==_pic_file_old_mod ) {
         // We had an modified file that is also out of date
         oldModFile=true;
      }
      if (valid_bitmaps=='') {
         svcGetValidBitmaps(bm1,valid_bitmaps,systemName);
      }
      if (!pos(' 'bm1' ',' 'valid_bitmaps' '_pic_fldopen' ')) {
         valid_bitmaps='';
      }
      if ( bm1==_pic_fldopen || bm1==_pic_cvs_fld_date || bm1==_pic_cvs_fld_mod ) {
         directoriesAreSelected = true;
      }
      if ( no_real_selection ) break;
   }

   if ( !checkedItem ) {
      index := _TreeCurIndex();
      _TreeGetInfo(index,state,bm1);
      svcGetValidBitmaps(bm1,valid_bitmaps,systemName);
      if (!pos(' 'bm1' ',' 'valid_bitmaps' '_pic_fldopen' ')) {
         valid_bitmaps='';
      }
   }

   p_window_id=ctlupdate;

   if (valid_bitmaps=='') {
      ctlhistory.p_enabled=0;
      ctldiff.p_enabled=0;
      if ( directoriesAreSelected ) {
         ctlupdate.p_enabled=1;
      } else {
         ctlupdate.p_enabled=0;
      }
      ctlrevert.p_visible=0;
      ctlmerge.p_visible=0;
   }else if ( valid_bitmaps==BITMAP_LIST_ADD ) {
      p_caption=UPDATE_CAPTION_ADD;
      p_enabled=1;
      ctldiff.p_enabled=0;
      ctlmerge.p_visible=0;
      ctlrevert.p_visible=0;
   }else if ( valid_bitmaps==BITMAP_LIST_CONFLICT ) {
      ctldiff.p_enabled=1;
      p_enabled=1;
      if ( pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_MERGE ) {
         p_caption=SVC_UPDATE_CAPTION_MERGE;
         svcEnableRevertButton(checkForUpdateDashC);

         // the update Button is already the Merge button, so the Merge button 
         // becomes the resolve button
         ctlmerge.p_caption = "Resolve";
         ctlmerge.p_visible=1;
      }else if ( isCVS ) {
         p_caption=UPDATE_CAPTION_UPDATE;
         ctlrevert.p_visible=_CVSUpdateDashCAvailable();
         if (def_cvs_flags&CVS_SHOW_MERGE_BUTTON) {
            ctlmerge.p_visible=1;
         }
      }
   }else if ( valid_bitmaps==BITMAP_LIST_COMMITABLE ) {
      p_caption = pInterface->getCaptionForCommand(SVC_COMMAND_COMMIT);
      p_enabled=1;
      ctldiff.p_enabled=1;
      if ( addedFile ) {
         ctlrevert.p_visible=0;
      }else if (deletedFile) {
         ctlrevert.p_visible = 0;
         ctldiff.p_enabled   = 0;
      }else{
         svcEnableRevertButton(checkForUpdateDashC);
      }
      ctlmerge.p_visible=0;
   }else if ( valid_bitmaps==BITMAP_LIST_UPDATE ) {
      p_caption=UPDATE_CAPTION_UPDATE;
      p_enabled=1;
      if ( bm1!=_pic_cvs_file_new
           && bm1!=_pic_cvs_fld_m ) {
         ctldiff.p_enabled=1;
      } else {
         ctldiff.p_enabled=0;
      }
      ctlrevert.p_visible=0;
      ctlmerge.p_visible=0;
      if ( oldModFile ) {
         svcEnableRevertButton(checkForUpdateDashC);
      }
      if (deletedFile) {
         ctlrevert.p_visible = 0;
         ctldiff.p_enabled   = 0;
      }
   }else if ( valid_bitmaps==BITMAP_LIST_FOLDER && isHg ) {
      p_caption = pInterface->getCaptionForCommand(SVC_COMMAND_COMMIT);
      p_enabled=1;
      ctldiff.p_enabled=0;
      ctlrevert.p_visible=1;
      ctlupdate_all.p_enabled=1;
   }
   int button_width=max(p_width,_text_width(p_caption)+400);
   if ( button_width>p_width ) {
      int orig_button_width=p_width;
      p_width=button_width;
      int width_difference=(button_width-orig_button_width);
      ctlupdate_all.p_x+=width_difference;
      ctlrevert.p_x+=width_difference;
   }

   p_window_id = ctltree1;
   index := _TreeCurIndex();
   if ( index>=0 ) {
      _TreeGetInfo(index,state,bm1);
   }
   boolean file_bitmap=(bm1==_pic_file_old||
                        bm1==_pic_file_old_mod ||
                        bm1==_pic_file_mod||
                        bm1==_pic_cvs_file_conflict||
                        bm1==_pic_cvs_file_conflict_updated);

   int numselected = ctltree1._TreeGetNumSelectedItems();
   ctlhistory.p_enabled=(numselected<=1) && file_bitmap;
   if ( numselected>1 && ctlupdate.p_enabled && ctlupdate.p_caption==SVC_UPDATE_CAPTION_MERGE ) {
      // Do not allow merge for multiple files
      ctlupdate.p_enabled = 0;
   }

   p_window_id=wid;
}
_command void svc_rclick_command(_str commandLine="") name_info(',')
{
   command := parse_file(commandLine);
   IVersionControl *pInterface = svcGetInterface(def_vc_system);
   if ( pInterface==null ) return;

   index := _TreeCurIndex();

   switch ( lowcase(command) ) {
   case "select":
      {
         if ( commandLine=="mod" ) {
            updateSelectModified();
         }
         if ( commandLine=="update" ) {
            updateSelectOutOfDate();
         }
      }
      break;
   case "deselect":
      {
         if ( commandLine=="mod" ) {
            updateSelectModified(false);
         }
         if ( commandLine=="update" ) {
            updateSelectOutOfDate(false);
         }
      }
      break;
   case "diff":
      {
         saveChecks(auto checkList);
         clearChecks();
         _TreeSetCheckState(index,TCB_CHECKED);
         ctldiff.call_event(ctldiff,LBUTTON_UP);
         clearChecks();
         restoreChecks(checkList);
      }
      break;
   case "commit":
   case "update":
      {
         filename := parse_file(commandLine);
         if ( lowcase(command)=="update" ) {
            pInterface->updateFile(filename);
         } else if ( lowcase(command)=="commit" ) {
            pInterface->commitFile(filename);
         }

         _str selectedFileList[];
         selectedFileList[0] = filename;
         INTARRAY selectedIndexList;
         selectedIndexList[0] = index;
         _str fileTable:[];
         fileTable:[_file_case(filename)] = "";
         refreshAfterOperaiton(selectedFileList,selectedIndexList,fileTable,pInterface);
      }
      break;
   case "history":
      {
         filename := parse_file(commandLine);
         saveChecks(auto checkList);
         clearChecks();
         _TreeSetCheckState(index,TCB_CHECKED);
         ctlhistory.call_event(ctlhistory,LBUTTON_UP);
         clearChecks();
         restoreChecks(checkList);
      }
      break;
   }
}

static void promptForNewShelfName(_str &shelfName)
{
   shelfName = "";
   status := textBoxDialog("Shelf Name",TB_RETRIEVE_INIT,0,"shelvefiles","","shelvefiles","Shelf name");
   if ( status!=1 ) return;
   shelfName = _param1;
}

static void saveChecks(INTARRAY &selectedIndexList)
{
   int info;

   mou_hour_glass(true);
   origWID := p_window_id;
   origFID := p_active_form;
   p_window_id = ctltree1;
   // Add all the selected items
   _str fileTable:[];
   directoriesAreInList := false;
   for ( ff:=1;;ff=0 ) {
      index := _TreeGetNextCheckedIndex(ff,info);
      if ( index<0 ) break;
      if ( index==TREE_ROOT_INDEX ) continue;
      if ( _TreeGetCheckState(index)==TCB_CHECKED ) {
         ARRAY_APPEND(selectedIndexList,index);
      }
   }
}

static void clearChecks()
{
   int info;
   INTARRAY selectedIndexList;

   mou_hour_glass(true);
   origWID := p_window_id;
   origFID := p_active_form;
   p_window_id = ctltree1;
   // Add all the selected items
   _str fileTable:[];
   directoriesAreInList := false;
   for ( ff:=1;;ff=0 ) {
      index := _TreeGetNextCheckedIndex(ff,info);
      if ( index<0 ) break;
      if ( index==TREE_ROOT_INDEX ) continue;
      if ( _TreeGetCheckState(index)==TCB_CHECKED ) {
         ARRAY_APPEND(selectedIndexList,index);
      }
   }
   foreach ( auto curIndex in selectedIndexList ) {
      _TreeSetCheckState(curIndex,TCB_UNCHECKED);
   }
}

static void restoreChecks(INTARRAY &selectedIndexList)
{
   foreach (auto curIndex in selectedIndexList) {
      _TreeSetCheckState(curIndex,TCB_CHECKED);
   }
}

static void updateSelectModified(boolean select=true,int index=TREE_ROOT_INDEX)
{
   for (;index>=0;) {
      childIndex := _TreeGetFirstChildIndex(index);
      if ( childIndex>=0 ) {
         updateSelectModified(select,childIndex);
      }
      _TreeGetInfo(index,auto state,auto bm1);
      if ( bm1==_pic_file_mod || bm1==_pic_file_old_mod ) {
         if ( select ) {
            _TreeSetCheckState(index,TCB_CHECKED);
         } else {
            _TreeSetCheckState(index,TCB_UNCHECKED);
         }
      }
      index = _TreeGetNextSiblingIndex(index);
   }
}

static void updateSelectOutOfDate(boolean select=true,int index=TREE_ROOT_INDEX,boolean includeMod=true)
{
   for (;index>=0;) {
      childIndex := _TreeGetFirstChildIndex(index);
      if ( childIndex>=0 ) {
         updateSelectOutOfDate(select,childIndex,includeMod);
      }
      _TreeGetInfo(index,auto state,auto bm1);
      if ( bm1==_pic_file_old ||
           (bm1==_pic_cvs_fld_date) ||
           (bm1==_pic_cvs_filem) ||
           (bm1==_pic_file_old_mod && includeMod) ) {
         if ( select ) {
            _TreeSetCheckState(index,TCB_CHECKED);
         } else {
            _TreeSetCheckState(index,TCB_UNCHECKED);
         }
      }
      index = _TreeGetNextSiblingIndex(index);
   }
}
