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
#import "clipbd.e"
#import "cvsutil.e"
#import "diff.e"
#import "dirlist.e"
#import "diffprog.e"
#import "fileman.e"
#import "files.e"
#import "filewatch.e"
#import "guicd.e"
#import "guiopen.e"
#import "help.e"
#import "main.e"
#import "menu.e"
#import "mprompt.e"
#import "listbox.e"
#import "picture.e"
#import "ptoolbar.e"
#import "seltree.e"
#import "sellist2.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "svcautodetect.e"
#import "svc.e"
#import "svccomment.e"
#import "treeview.e"
#import "vc.e"
#import "wkspace.e"
#require "se/vc/IVersionControl.e"
#require "se/lang/api/ExtensionSettings.e"
#endregion

using se.vc.IVersionControl;
using se.lang.api.ExtensionSettings;

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
   if ( ctlupdate.p_caption==SVC_UPDATE_CAPTION_UPDATE ) {
      ctlupdate.call_event(ctlupdate,LBUTTON_UP);
   }
}

void _SVCGUIUpdateDialog(SVC_UPDATE_INFO (&fileStatusList)[],_str path,_str moduleName,
                         bool modal=false,_str VCSystemName="",STRARRAY &pathsToUpdate=null,
                         _str workspaceOrProject="")
{
   if ( VCSystemName=="") VCSystemName = svc_get_vc_system();
   IVersionControl *pInterface = svcGetInterface(VCSystemName);
   if ( pInterface==null ) return;
   modalOption := "";
   if ( modal ) modalOption = " -modal ";
   int formid=show('-xy -app -new ':+modalOption:+' _svc_mfupdate_form',fileStatusList,path,moduleName,VCSystemName,pathsToUpdate,workspaceOrProject);
   if ( !modal ) {
      if ( workspaceOrProject=="" ) {
         formid.p_active_form.p_caption=pInterface->getSystemNameCaption():+' ':+formid.p_active_form.p_caption;
      } else {
         formid.p_active_form.p_caption=pInterface->getSystemNameCaption():+' Update 'workspaceOrProject;
      }
   }
}

void ctlclose.on_create(SVC_UPDATE_INFO (&fileStatusList)[]=null,_str path="",
                        _str moduleName="",_str VCSystemName="",
                        STRARRAY pathsToUpdate=null)
{
   ctllocal_path_label.p_caption = LOCAL_ROOT_LABEL:+path;
   ctlrep_label.p_caption = "Repository:":+moduleName;
   origWID := p_window_id;

   _nocheck _control ctltree1;
   p_window_id = ctltree1;
   SVCSetupTree(fileStatusList,path,moduleName,VCSystemName,pathsToUpdate);
   p_window_id = origWID;
}

void ctlhistory.lbutton_up()
{
   VCSystemName := _GetDialogInfoHt("VCSystemName");
   if ( VCSystemName=="") VCSystemName = svc_get_vc_system();
   IVersionControl *pInterface = svcGetInterface(VCSystemName);
   if ( pInterface==null ) return;

   index := ctltree1._TreeCurIndex();
   if ( index<0 ) return;
   filename := svcGetFilenameFromUpdateTree(index);
   if ( filename=="" ) return;
   svc_history(filename);
}

static void diffGUIUpdate(INTARRAY &selectedIndexList,STRARRAY &selectedFileList,INTARRAY (&selectedFileBitmaps)[],bool &filesModifiedInDiff)
{
   VCSystemName := _GetDialogInfoHt("VCSystemName");
   if ( VCSystemName=="") VCSystemName = svc_get_vc_system();
   IVersionControl *pInterface = svcGetInterface(VCSystemName);
   if ( pInterface==null ) return;

   // If no items were selected, add the current item
   if ( selectedIndexList==null || selectedIndexList._length()==0 ) {
      index := _TreeCurIndex();
      if ( index >= 0 ) {
         ctltree1._TreeGetInfo(index,auto state,auto bm1,0,0,auto junk, -1, auto overlays);
         filename := svcGetFilenameFromUpdateTree(index);
         selectedIndexList   :+= index;
         selectedFileBitmaps :+= overlays;
         selectedFileList    :+= filename;
      }
   }

   len := selectedIndexList._length();
   for ( i:=0;i<len;++i ) {
      filename := selectedFileList[i];
      if ( filename=="" ) continue;
      orig_file_date := _file_date(filename,'B');
      curOverlays := selectedFileBitmaps[i];
      svcGetStatesFromOverlays(curOverlays,auto hadAddedOverlay,auto hadDeletedOverlay,auto hadModOverlay,auto hadDateOverlay,auto hadCheckoutOverlay, auto hadUnknownOverlay, i==0);
      if ( hadModOverlay && hadDateOverlay) {
         STRARRAY captions;
         pInterface->getCurLocalRevision(filename,auto curLocalRevision);
         pInterface->getCurRevision(filename,auto curRevision);
         captions[0]='Compare local version of 'filename' 'curLocalRevision' with remote version 'curLocalRevision;
         captions[1]='Compare local version of 'filename' 'curLocalRevision' with remote version 'curRevision;
         captions[2]='Compare remote version of 'filename' 'curLocalRevision' with remote version 'curRevision;
         int result=RadioButtons("Newer version exists",captions,1,'cvs_diff');
         if ( result==COMMAND_CANCELLED_RC ) {
            return;
         } else if ( result==1 ) {
            svc_diff_with_tip(filename,curLocalRevision,"",true);
         } else if ( result==2 ) {
            svc_diff_with_tip(filename,curRevision,"",true);
         } else if ( result==3 ) {
            status := pInterface->getFile(filename,curLocalRevision,auto curLocalRevisionRemoteWID);
            if ( status ) {
               _message_box(nls(get_message(VSRC_SVC_COULD_NOT_GET_REMOTE_REPOSITORY_INFORMATION,filename':'curLocalRevision)));
               return;
            }
            status = pInterface->getFile(filename,curRevision,auto curRemoteRevisionWID);
            if ( status ) {
               _message_box(nls(get_message(VSRC_SVC_COULD_NOT_GET_REMOTE_REPOSITORY_INFORMATION,filename':'curRevision)));
               return;
            }
            pInterface->getLocalFileURL(filename,auto URL);
            diff('-modal -r1 -r2 -file1title "'URL' 'curLocalRevision'" -file2title "'URL' 'curRevision'" -viewid1 -viewid2 'curLocalRevisionRemoteWID' 'curRemoteRevisionWID);
            _delete_temp_view(curRemoteRevisionWID);
            _delete_temp_view(curLocalRevisionRemoteWID);
         }
      } else if ( hadCheckoutOverlay ) {
         pInterface->getFileStatus(filename,auto fileStatus);
         if ( fileStatus&SVC_STATUS_UPDATED_IN_INDEX ) {
            STRARRAY captions;
            captions[0]='Compare local version of 'filename' with last committed version';
            captions[1]='Compare local version of 'filename' with staged version';
            captions[2]='Compare staged version of 'filename' with last commited version';
            int result=RadioButtons("Staged version exists",captions,1,'cvs_diff');
            if ( result==COMMAND_CANCELLED_RC ) {
               return;
            }
            if ( result==1 ) {
               svc_diff_with_tip(filename,"",VCSystemName,true);
            }else if ( result==2 ) {
               status := _open_temp_view(filename,auto curLocalFileWID,auto origWID);
               p_window_id = origWID;
               if ( !status ) {
                  status = pInterface->getFile(filename,"",auto curStagedRevisionWID,true);
                  if ( !status ) {
                     pInterface->getLocalFileURL(filename,auto URL);
                     pInterface->getCurLocalRevision(filename,auto curLocalRevision);
                     pInterface->getCurRevision(filename,auto curRevision);
                     diff('-modal -r1 -r2 -file1title "'URL' 'curLocalFileWID'(local)" -file2title "'URL'(staged) 'curRevision'" -viewid1 -viewid2 'curLocalFileWID' 'curStagedRevisionWID);
                     _delete_temp_view(curStagedRevisionWID);
                  }
                  _delete_temp_view(curLocalFileWID);
               }
            }else if ( result==3 ) {
               status := pInterface->getFile(filename,"",auto curStagedRevisionWID,true);
               if ( !status ) {
                  pInterface->getLocalFileURL(filename,auto URL);
                  status = pInterface->getFile(filename,"",auto curRemoteRevisionWID);
                  if ( !status ) {
                     pInterface->getCurLocalRevision(filename,auto curLocalRevision);
                     pInterface->getCurRevision(filename,auto curRevision);
                     diff('-modal -r1 -r2 -file1title "'URL' 'curLocalRevision'(staged)" -file2title "'URL' 'curRevision'" -viewid1 -viewid2 'curStagedRevisionWID' 'curRemoteRevisionWID);
                     _delete_temp_view(curStagedRevisionWID);
                  }
                  _delete_temp_view(curRemoteRevisionWID);
               }
            }
         }
      } else if ( hadModOverlay && pInterface->getBaseRevisionSpecialName() != "") {
         svc_diff_with_tip(filename,pInterface->getBaseRevisionSpecialName(),VCSystemName,true);
      } else {
         svc_diff_with_tip(filename,"",VCSystemName,true);
      }
      diff_file_date := _file_date(filename,'B');
      if (diff_file_date != orig_file_date) {
         filesModifiedInDiff = true;
      }
   }
}

void ctldiff.lbutton_up()
{
   VCSystemName := _GetDialogInfoHt("VCSystemName");
   if ( VCSystemName=="") VCSystemName = svc_get_vc_system();
   IVersionControl *pInterface = svcGetInterface(VCSystemName);
   if ( pInterface==null ) return;

   filesModifiedInDiff := false;
   int selectedIndexList[];
   _str selectedFileList[];
   int selectedFileBitmaps[][];
   int info;

   origWID := p_window_id;
   origFID := p_active_form;
   p_window_id = ctltree1;
   // Add all the selected items
   for ( ff:=1;;ff=0 ) {
      index := _TreeGetNextCheckedIndex(ff,info);
      if ( index<0 ) break;
      ctltree1._TreeGetInfo(index,auto state,auto bm1,0,0,auto junk, -1, auto overlays);
      filename := svcGetFilenameFromUpdateTree(index);
      selectedIndexList   :+= index;
      selectedFileBitmaps :+= overlays;
      selectedFileList    :+= filename;
   }
   p_window_id = origWID;

   ctltree1.diffGUIUpdate(selectedIndexList,selectedFileList,selectedFileBitmaps, filesModifiedInDiff);

   if (filesModifiedInDiff) {
      origFID._SVCUpdateRefreshAfterOperation(selectedFileList,selectedIndexList,null,pInterface,false);
   }
   origFID.ctltree1._set_focus();
}

void ctlupdate.lbutton_up()
{
   VCSystemName := _GetDialogInfoHt("VCSystemName");
   if ( VCSystemName=="") VCSystemName = svc_get_vc_system();
   IVersionControl *pInterface = svcGetInterface(VCSystemName);
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

   mou_hour_glass(true);
   origWID := p_window_id;
   origFID := p_active_form;
   p_window_id = ctltree1;
   // Add all the selected items
   _str fileTable:[];
   directoriesAreInList := false;
   info := 0;
   for ( ff:=1;;ff=0 ) {
      index := _TreeGetNextCheckedIndex(ff,info);
      if ( index<0 ) break;
      if ( index==TREE_ROOT_INDEX ) continue;
      if ( _TreeGetCheckState(index)==TCB_CHECKED ) {
         selectedIndexList :+= index;
         filename := svcGetFilenameFromUpdateTree(index,true);
//         if (last_char(filename)==FILESEP) continue;
         selectedFileList :+= filename;
         if ( _last_char(filename)==FILESEP ) {
            directoriesAreInList = true;
         }
         fileTable:[_file_case(filename)] = "";
      }
   }

   // If no items were selected, add the current item
   if ( selectedIndexList._length()==0 ) {
      index := _TreeCurIndex();
      if ( index>=0 )selectedIndexList :+= index;
      filename := svcGetFilenameFromUpdateTree(index);
      selectedFileList :+= filename;
   }
   p_window_id = origWID;

   refreshAfterOperation := true;
   status := 0;
   if ( isUpdateButton ) {
      if ( pInterface->getSystemSpecificFlags()&SVC_UPDATE_PATHS_RECURSIVE &&
           directoriesAreInList
           ) {
         removeChildFiles(selectedFileList);
      }
      status = pInterface->updateFiles(selectedFileList);
   } else if ( isCommitButton ) {
      STRARRAY removedItems;
      if ( pInterface->getSystemSpecificFlags()&SVC_UPDATE_PATHS_RECURSIVE &&
           directoriesAreInList
           ) {
         if ( def_svc_logging ) {
            logSelectedList(selectedFileList,"ctlupdate.lbutton_up 10 list");
         }
         removeChildFiles(selectedFileList);
         if ( def_svc_logging ) {
            logSelectedList(selectedFileList,"ctlupdate.lbutton_up 20 list");
         }
      }
      if ( def_svc_logging ) {
         logSelectedList(selectedFileList,"ctlupdate.lbutton_up 30 list");
      }
      useSVCCommentAndCommit := pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_GET_COMMENT_AND_COMMIT;
      if (useSVCCommentAndCommit) {
         _SVCGetCommentAndCommit(selectedFileList,selectedIndexList,fileTable,pInterface,p_active_form);
         refreshAfterOperation = false;
      } else {
         status = pInterface->commitFiles(selectedFileList);
      }
#if 0 //1:10pm 5/14/2019
      if ( removedItems._length()>0 ) {
         _reload_vc_buffers(removedItems);
         _retag_vc_buffers(removedItems);
      }
#endif
   } else if ( isAddButton ) {
      ctltree1.maybeRemoveParentItems(selectedIndexList,selectedFileList);
      status = pInterface->addFiles(selectedFileList);
   } else if ( isMergeButton ) {
      if (!_haveMerge()) {
         popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Merge");
      } else {
         // We only allow the merge button for a single file
         status = pInterface->mergeFile(selectedFileList[0]);
      }
   }
   _filewatchRefreshFiles(selectedFileList);
   if ( status ) {
      // If something failed, or a commit was cancelled, we don't want to clear
      // the checkboxes below
      return;
   }

   if (refreshAfterOperation) _SVCUpdateRefreshAfterOperation(selectedFileList,selectedIndexList,fileTable,pInterface,!isAddButton,isAddButton == true);
   if ( status ) return;
   p_window_id = origWID;
   origFID.ctltree1._set_focus();
}

static void maybeRemoveParentItems(INTARRAY &selectedIndexList,STRARRAY &selectedFileList)
{
   // Go through the selectedIndexList, and figure out which items in 
   // selectedFileList have "normal" parents.  Add those parent paths to 
   // pathsToRemove.
   info := 0;
   STRHASHTAB pathsToRemove;
   for ( ff:=1;;ff=0 ) {
      index := _TreeGetNextCheckedIndex(ff,info);
      if ( index<0 ) break;
      if ( index==TREE_ROOT_INDEX ) continue;
      if ( _TreeGetCheckState(index)==TCB_CHECKED ) {
         filename := svcGetFilenameFromUpdateTree(index,true);
         parentIndex := _TreeGetParentIndex(index);
         _TreeGetInfo(parentIndex,auto state,auto bm1,auto bm2);
         if ( bm1==_pic_fldopen ) {
            parentCaption := _TreeGetCaption(parentIndex);
            pathsToRemove:[_file_case(parentCaption)] = "";
         }
      }
   }

   // Go through pathsToRemove and take out the items out of selectedFileList
   foreach (auto curPath => auto junk in pathsToRemove) {
      len := selectedFileList._length();
      for (i:=len-1;i>=0;--i) {
         if ( _file_eq(curPath,selectedFileList[i]) ) {
            selectedFileList._deleteel(i);
         }
      }
   }
}

static void logSelectedList(STRARRAY &selectedFileList,_str label)
{
   dsay('logSelectedList','svc');
   dsay(label,'svc');

   len := selectedFileList._length();
   for (i:=0;i<len;++i) {
      dsay('   'selectedFileList[i],'svc');
   }
}

static void buildPathIndexTable(int (&pathIndexTable):[], int tree_index=TREE_ROOT_INDEX)
{
   node_index := _TreeGetFirstChildIndex(tree_index);
   while (node_index > 0) {
      file_name := svcGetFilenameFromUpdateTree(node_index);
      pathIndexTable:[_file_case(file_name)] = node_index;
      _TreeGetInfo(node_index, auto state);
      if (state >= 0) {
         _maybe_append_filesep(file_name);
         pathIndexTable:[_file_case(file_name)] = node_index;
         buildPathIndexTable(pathIndexTable,node_index);
      }
      node_index = _TreeGetNextSiblingIndex(node_index);
   }
}

void _SVCUpdateRefreshAfterOperation(STRARRAY &selectedFileList,
                                     INTARRAY &selectedIndexList,
                                     _str (&fileTable):[],
                                     IVersionControl *pInterface,
                                     bool uncheck=true,
                                     bool isAdd=false)
{
//   INTARRAY selectedIndexList;
   
   SVCFileStatus dirStatusInfo:[];
   int pathIndexTable:[];
   // now got thru and set appropriate pictures
   len := selectedFileList._length();
   p_window_id = ctltree1;
   buildPathIndexTable(pathIndexTable);
   //_dump_var(pathIndexTable);
   for ( i:=0;i<len;++i ) {
      SVC_UPDATE_INFO curFileInfo;
      curFileInfo.filename = selectedFileList[i];
      curFileInfo.status = SVC_STATUS_NONE;
      //say("refreshAfterOperation: file="curFileInfo.filename);
      
      // For the case of a diff, the fileTable can be null
      if ( fileTable!=null ) fileTable._deleteel(_file_case(selectedFileList[i]));

      if ( _last_char(curFileInfo.filename)==FILESEP ) {
         //say("refreshAfterOperation: DIRECTORY");

         if (!dirStatusInfo._indexin(_file_case(curFileInfo.filename))) {
            status := pInterface->getMultiFileStatus(curFileInfo.filename,auto fileStatusList);
            SVCUpdateCheckedItemsToData(fileStatusList,isAdd,curFileInfo.filename);
            if (status == 0) {
               for (j:=0; j<fileStatusList._length(); j++) {
                  dirStatusInfo:[_file_case(fileStatusList[j].filename)] = fileStatusList[j].status;
                  //say("refreshAfterOperation: found file status for: "fileStatusList[j].filename);
               }
            }
         }

      } else {

         // have we already done this file?
         status := FILE_NOT_FOUND_RC;
         if (dirStatusInfo._indexin(_file_case(curFileInfo.filename))) {
            curFileInfo.status = dirStatusInfo:[_file_case(curFileInfo.filename)];
            //say("refreshAfterOperation: FILE ALREADY DONE");
            status = 0;
         }

         // haven't found status for this file yet, so try directory.
         curPath := _file_path(curFileInfo.filename);
         _maybe_append_filesep(curPath);
         if (status && len > 1) {
            if (dirStatusInfo._indexin(_file_case(curPath))) {
               //say("refreshAfterOperation: PATH ALREADY DONE");
               status = 0;
            } else {
               //say("refreshAfterOperation: CHECKING FILE PATH");
               // get multiple file status for the directory containing this file
               status = pInterface->getMultiFileStatus(curPath,auto fileStatusList,SVC_UPDATE_PATH,true);
               SVCUpdateCheckedItemsToData(fileStatusList,isAdd);
               if (status == 0) {
                  dirStatusInfo:[_file_case(curPath)] = SVC_STATUS_NONE;
                  for (j:=0; j<fileStatusList._length(); j++) {
                     dirStatusInfo:[_file_case(fileStatusList[j].filename)] = fileStatusList[j].status;
                     //say("refreshAfterOperation: found file status for: "fileStatusList[j].filename);
                     if (_file_eq(fileStatusList[j].filename, curFileInfo.filename)) {
                        curFileInfo.status = fileStatusList[j].status;
                        //say("refreshAfterOperation: THAT'S THE FILE WE WERE LOOKING FOR!");
                     }
                  }
               }
            }
         }

         // Get the status from the version control system
         if (status) {
            //say("refreshAfterOperation: CHECKING INDIVIDUAL FILE STATUS");
            status = pInterface->getFileStatus(curFileInfo.filename,curFileInfo.status);
            dirStatusInfo:[_file_case(curFileInfo.filename)] = curFileInfo.status;
            if ( status ) break;
         }

         // Get the picture for the status
         _SVCGetFileBitmap(curFileInfo,auto bitmap,auto overlays=null);
         moddedPathIndex := pathIndexTable:[_file_case(curPath)];
         //say("refreshAfterOperation: looking up index of "curPath" => "((modedPathIndex==null)? "null":modedPathIndex));
         if ( moddedPathIndex==null ) {
            moddedPathIndex = _TreeSearch(TREE_ROOT_INDEX,_file_case(curPath),'T'_fpos_case);
            if (moddedPathIndex > 0) pathIndexTable:[_file_case(curPath)] = moddedPathIndex;
            //say("refreshAfterOperation: TREE SEARCH FOR "curPath" => "modedPathIndex);
         }
         // If the new picture doesn't match, set the new picture
         modedIndex := pathIndexTable:[_file_case(curFileInfo.filename)];
         //say("refreshAfterOperation: looking up index of "curFileInfo.filename" => "((modedIndex==null)? "null":modedIndex));
         if ( modedIndex==null ) {
            modedIndex = _TreeSearch(moddedPathIndex,_strip_filename(curFileInfo.filename,'P'),_fpos_case);
            if (modedIndex > 0) pathIndexTable:[_file_case(curFileInfo.filename)] = modedIndex;
            //say("refreshAfterOperation: TREE SEARCH FOR "curFileInfo.filename" => "modedIndex);
         }
         if ( modedIndex>=0 ) {
            _TreeGetInfo(modedIndex,auto state,auto curBitmap,curBitmap, 0,auto lineNumber, -1,auto origOverlays);
            if ( origOverlays!=overlays ) {
               _TreeSetInfo(modedIndex,state,bitmap,bitmap,0,1,-1,overlays);
            }
         }
         if ( fileTable!=null ) {
            // For the case of a diff, the fileTable can be null
            foreach ( auto curFilename => auto curValue in fileTable ) {
               curPath = _file_path(_file_case(curFilename));
               moddedPathIndex = pathIndexTable:[curPath];
               //say("refreshAfterOperation: looking up path index of "curPath" => "((modePathIndex==null)? "null":modePathIndex));
               if ( moddedPathIndex==null ) {
                  moddedPathIndex = _TreeSearch(TREE_ROOT_INDEX,curPath,'T'_fpos_case);
                  //say("refreshAfterOperation: TREE SEARCH FOR path index of "curPath" => "modePathIndex);
                  if (moddedPathIndex > 0) pathIndexTable:[curPath] = moddedPathIndex;
               }
               fileIndex := pathIndexTable:[_file_case(curFilename)];
               //say("refreshAfterOperation: looking up file index of "curFilename" => "((fileIndex==null)? "null":fileIndex));
               if (fileIndex == null) {
                  fileIndex = _TreeSearch(TREE_ROOT_INDEX,_strip_filename(curFilename,'P'),'T'_fpos_case);
                  if (fileIndex > 0) pathIndexTable:[_file_case(curFilename)] = fileIndex;
                  //say("refreshAfterOperation: TREE SEARCH for file index of "curFilename" => "fileIndex);
               }
               if ( fileIndex>=0 ) {
                  _TreeGetInfo(fileIndex,auto state, auto origBitmap,origBitmap, 0,auto lineNumber, -1,auto origOverlays);
                  if ( origOverlays!=overlays ) {
                     _TreeSetInfo(fileIndex,state,_pic_cvs_file,_pic_cvs_file,0,1,-1,overlays);
                  }
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

/**
 * Remove files from <B>selectedFileList</B> that are children 
 * of directories that are also in <B>selectedFileList</B>.
 * 
 * @param selectedFileList list of files and directories that 
 *                         were selected in the dialog
 */
static void removeChildFiles(STRARRAY &selectedFileList)
{
   len := selectedFileList._length();
   STRHASHTAB dirTable;
   INTARRAY dirIndexes;

   // Go through and find all the directories and store them in a hashtable
   for ( i:=0;i<len;++i ) {
      curFile := _file_case(selectedFileList[i]);
      if ( _last_char(curFile)==FILESEP ) {
         dirTable:[_file_case(curFile)] = "";
         dirIndexes :+= i;
      }
   }

   // Go through all the files.  If the file is in a directory that will be 
   // updated already because it is a directory that will be updated, queue 
   // that file to be removed.
   STRHASHTAB usedDirs;
   INTARRAY delList;
   for ( i=0;i<len;++i ) {
      curFile := _file_case(selectedFileList[i]);
      if ( _last_char(curFile)!=FILESEP ) {
         curPath := _file_path(curFile);
         if ( dirTable:[_file_case(curPath)]!=null ) {
            // This file will be handled by the directory
            delList :+= i;
            usedDirs:[_file_case(curFile)] = "";
         }
      }
   }
   // Go through the list of files backwards, and delete the files that we do
   // not need. Actually, we're sorting the array descending, so we can go 
   // through it forwards.
   delList._sort('ND');
   len = delList._length();
   for ( i=0;i<len;++i ) {
      selectedFileList._deleteel(delList[i]);
   }
}


static _str getParentPath(_str path)
{
   _maybe_strip_filesep(path);
   return _strip_filename(path,'N');
}

static _str revertSelTreeCallback(int sl_event, typeless user_data, typeless info=null)
{
   // We don't want the DEL key to do antyhing
   switch (sl_event) {
   case SL_ONDELKEY:
      return "";
   case SL_ONDEFAULT:
      return 0;
   case SL_ONCLOSE:
      return 0;
   }
   return "";
}


bool svc_user_confirms_revert(STRARRAY &selectedFileList)
{
   msg := "This operation will revert the following files:\n";
   len := selectedFileList._length();
   // First go through and find any blank items and remove them
   for (i:=selectedFileList._length()-1;i>=0;--i) {
      if ( selectedFileList[i]=="" ) {
         selectedFileList._deleteel(i);
      }
   }
   len = selectedFileList._length();
   // If we have 5 items or less, use a message box to show the user the files
   // being reverted
   if ( selectedFileList._length()<=5 ) {
      for ( i =0; i< len; ++i) {
         msg :+= "\n"selectedFileList[i];
      }
      msg :+= "\n\nContinue?";
      result := _message_box(nls(msg),"", MB_YESNO);
      if (result==IDYES) return true;
      return false;
   }

   // Show the user a list of the files to be reverted
   status := select_tree(selectedFileList,callback:revertSelTreeCallback,caption:"Revert the following files?",SL_DESELECTALL|SL_DEFAULTCALLBACK);
   if ( status<0 ) {
      // Negative return code, probably COMMAND_CANCELLED_RC
      return false;
   }
   // It will return us the currently selected item, but we're going to do 
   // all items.  Return true.
   return true;
}

void ctlrevert.lbutton_up()
{
   // The revert button is currently only visible or invisible.  There is no 
   // other possible caption to concern ourselves with.  Since the button will
   // only be visible when it is possible to press it, we can simplly get our
   // information and perform the revert
   isAddButton := p_caption==SVC_UPDATE_CAPTION_ADD;
   VCSystemName := _GetDialogInfoHt("VCSystemName");
   if ( VCSystemName=="") VCSystemName = svc_get_vc_system();
   IVersionControl *pInterface = svcGetInterface(VCSystemName);
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
      selectedIndexList :+= index;
      selectedFileList :+= svcGetFilenameFromUpdateTree(index);
   }

   // If no items were selected, add the current item
   if ( selectedIndexList._length()==0 ) {
      index := _TreeCurIndex();
      if ( index>=0 ){
         selectedIndexList :+= index;
         selectedFileList :+= svcGetFilenameFromUpdateTree(index);
      }
   }
   p_window_id = origWID;

   if ( !svc_user_confirms_revert(selectedFileList) ) {
      return;
   }

   status := pInterface->revertFiles(selectedFileList);
   _filewatchRefreshFiles(selectedFileList);

   _str fileTable:[];
   // now got thru and set appropriate pictures
   len := selectedFileList._length();
   for ( i:=0;i<len;++i ) {
      fileTable:[_file_case(selectedFileList[i])] = "";
   }

   _SVCUpdateRefreshAfterOperation(selectedFileList,selectedIndexList,fileTable,pInterface);

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
   isMergeButton := p_caption==SVC_UPDATE_CAPTION_MERGE;

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
      selectedIndexList :+= index;
      selectedFileList :+= svcGetFilenameFromUpdateTree(index);
   }

   // If no items were selected, add the current item
   if ( selectedIndexList._length()==0 ) {
      index := _TreeCurIndex();
      if ( index>=0 )selectedIndexList :+= index;
      filename := svcGetFilenameFromUpdateTree(index);
      selectedFileList :+= filename;
   }
   p_window_id = origWID;

   if ( selectedFileList._length()==0 ) {
      _message_box(nls("No files selected"));
      return;
   }

   autoVCSystem := svc_get_vc_system(selectedFileList[0]);
   IVersionControl *pInterface = svcGetInterface(autoVCSystem);
   if ( pInterface==null ) return;

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
      _SVCGetFileBitmap(curFileInfo,auto bitmap,auto overlays);

      // If the new picture doesn't match, set the new picture
      p_window_id = ctltree1;
      _TreeGetInfo(selectedIndexList[i],auto state,auto curBitmap);
      _TreeSetInfo(selectedIndexList[i],state,bitmap,bitmap,0,1,-1,overlays);
      p_window_id = origWID;
   }

   mou_hour_glass(false);
   if ( status ) return;
   origFID.ctltree1._set_focus();
}

// Remove CVSGetFilenameFromUpdateTree when this solidifies
static _str svcGetFilenameFromUpdateTree(int index=-1,bool allowFolders=false, bool allowUnkownFolders=false, int treeWID=ctltree1)
{
   wid := p_window_id;
   p_window_id=treeWID;
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
   filename := "";
   if ( bmindex1==_pic_cvs_file
        || bmindex1==_pic_cvs_file_qm
        || bmindex1==_pic_file_old
        || bmindex1==_pic_file_old_mod
        || bmindex1==_pic_file_mod
        || bmindex1==_pic_file_mod_prop
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
        || bmindex1==_pic_cvs_fld_date
        || bmindex1==_pic_cvs_fld_mod_date
        || bmindex1==_pic_filep
      ) {
      filename=_TreeGetCaption(curindex);
      filename=_TreeGetCaption(_TreeGetParentIndex(curindex)):+filename;
      if ( bmindex1==_pic_cvs_fld_qm ) {
         filename :+= FILESEP;
      }
   } else if ( bmindex1==_pic_cvs_fld_qm && allowUnkownFolders ) {
      filename=_TreeGetCaption(curindex);
      filename=_TreeGetCaption(_TreeGetParentIndex(curindex)):+filename;
      filename :+= FILESEP;
   } else if (    bmindex1==_pic_cvs_fld_m
               || bmindex1==_pic_cvs_fld_p
               || bmindex1==_pic_cvs_fld_qm
               || bmindex1==_pic_cvs_fld_mod
               || (allowFolders && bmindex1==_pic_fldopen)
             ) {
      filename=_TreeGetCaption(curindex);
   }
   p_window_id=wid;
   return(filename);
}


static void getWorkspaceFilesHt(STRARRAY &workspaceFileList, STRHASHTAB &workspaceFileHT)
{
   foreach (auto curFile in workspaceFileList) {
      workspaceFileHT:[_file_case(curFile)] = curFile;
   }
}

static bool haveWildcardsInWorkspace(STRARRAY &projectFileList)
{
   len := projectFileList._length();
   for (i:=0;i<len;++i) {
      int project_handle=_ProjectHandle(projectFileList[i]);
      _xmlcfg_find_simple_array(project_handle,
                                VPJX_FILES"//"VPJTAG_F:+
                                //XPATH_CONTAINS('N','['_escape_re_chars(WILDCARD_CHARS)']','r'),
                                XPATH_CONTAINS('N','['_escape_re_chars(WILDCARD_CHARS)']','r'),
                                auto refiltered,TREE_ROOT_INDEX,VSXMLCFG_FIND_VALUES);
      if (refiltered._length()) return true;
   }
   return false;
}

static void SVCSetupTree(SVC_UPDATE_INFO (&fileStatusList)[],_str rootPath,_str moduleName,_str VCSystemName,STRARRAY &pathsToUpdate)
{
   if ( VCSystemName=="") VCSystemName = svc_get_vc_system();
   IVersionControl *pInterface = svcGetInterface(VCSystemName);
   if ( pInterface==null ) return;
   _SetDialogInfoHt("VCSystemName",VCSystemName);
   rootPath = strip(rootPath,'B','"');
   _maybe_append_filesep(rootPath);
   len := pathsToUpdate._length();
   int pathIndexes:[]=null;
   if ( pathsToUpdate._length()>0 ) {
      for (i:=0;i<len;++i) {
         curRootIndex :=_TreeAddItem(TREE_ROOT_INDEX,pathsToUpdate[i],TREE_ADD_AS_CHILD,_pic_fldopen,_pic_fldopen);
         _TreeSetCheckable(curRootIndex,1,1);
         _SVCSeedPathIndexes(pathsToUpdate[i],pathIndexes,curRootIndex);
      }
   } else {
      rootIndex :=_TreeAddItem(TREE_ROOT_INDEX,rootPath,TREE_ADD_AS_CHILD,_pic_fldopen,_pic_fldopen);
      _TreeSetCheckable(rootIndex,1,1);
      _SVCSeedPathIndexes(rootPath,pathIndexes,rootIndex);
   }
   len = fileStatusList._length();
   
   _getProjectFilesInWorkspace(_workspace_filename,auto projectFileList);
   haveWildcards := false;
   if ( def_svc_update_only_shows_wkspace_files ) {
      haveWildcards = haveWildcardsInWorkspace(projectFileList);
   }
   STRARRAY workspaceFileList;
   STRHASHTAB workspaceFileHT;
   if ( def_svc_update_only_shows_wkspace_files && haveWildcards ) {
      _getWorkspaceFiles(_workspace_filename, workspaceFileList);
      getWorkspaceFilesHt(workspaceFileList, workspaceFileHT);
      getWorkspaceFilesHt(projectFileList, workspaceFileHT);
   }


   for ( i:=0;i<len;++i ) {
      if ( def_svc_update_only_shows_wkspace_files && haveWildcards ) {
         if ( workspaceFileHT:[_file_case(fileStatusList[i].filename)] == null ) {
            continue;
         }
      }
      curPath := _file_path(fileStatusList[i].filename);
      if ( _last_char(fileStatusList[i].filename)==FILESEP ) {
         curPath = fileStatusList[i].filename;
         _maybe_append_filesep(curPath);
         pathIndex := _SVCGetPathIndex(curPath,rootPath,pathIndexes);
         _SVCGetFileBitmap(fileStatusList[i],auto bmIndex,auto overlays);
         _TreeGetInfo(pathIndex,auto state, auto bm1);
         _TreeSetInfo(pathIndex,state,bmIndex,bmIndex,0,1,-1,overlays);
         _TreeSetCheckable(pathIndex,1,0);
      } else {
         parentIndex := -1;
         // If a directory needs to be updated, or committed, it will come 
         // through as a filename without a trailing FILESEP.  Need to check for
         // that.
         if ( isdirectory(fileStatusList[i].filename) ) {
            parentIndex = _SVCGetPathIndex(fileStatusList[i].filename:+FILESEP,rootPath,pathIndexes);
         } else {
            parentIndex = _SVCGetPathIndex(curPath,rootPath,pathIndexes);
         }
         skip := def_svc_update_only_shows_controlled_files && (fileStatusList[i].status&SVC_STATUS_NOT_CONTROLED);
         if ( !skip ) {
            _SVCGetFileBitmap(fileStatusList[i],auto bmIndex,auto overlays);
            newIndex := _TreeAddItem(parentIndex,_strip_filename(fileStatusList[i].filename,'P'),TREE_ADD_AS_CHILD,bmIndex,bmIndex,-1);
            _TreeSetInfo(newIndex,-1,bmIndex,bmIndex, 0, 1, -1, overlays);
            _TreeSetCheckable(newIndex,1,0);
         }
      }
   }
   origWID := p_window_id;
   p_window_id = ctltree1;
   // Have to be sure the version control system will always list files under 
   // empty folders before we remove empty folders
   if (pInterface->listsFilesInUncontrolledDirectories()) removeEmptyFolders();
   _TreeSortTree();
   p_window_id = origWID;
}

static void removeEmptyFolders()
{
   INTARRAY delList;
   index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   for (;;) {
      if (index<0) break;
      _TreeGetInfo(index,auto state, auto bm1);
      if ( bm1==_pic_fldopen ) {
         childIndex := _TreeGetFirstChildIndex(index);
         if ( childIndex<0 ) {
            delList :+= index;
         }
      }
      index = _TreeGetNextIndex(index);
   }
   len := delList._length();
   for (i:=0;i<len;++i) {
      _TreeDelete(delList[i]);
   }
}

static void SVCUpdateCheckedItemsToData(SVC_UPDATE_INFO (&fileStatusList)[],bool isAdd=false,
                                        _str topFilename="")
{
   SVC_UPDATE_INFO statusTable:[];
   len := fileStatusList._length();
   for ( i:=0;i<len;++i ) {
      // Have to be sure we have the FILESEP in case we wind up adding this item
      // to the tree at the bottom of the function.
      if ( isdirectory(fileStatusList[i].filename) ) _maybe_append_filesep(fileStatusList[i].filename);
      statusTable:[_file_case(fileStatusList[i].filename)] = fileStatusList[i];
   }
   info := 0;
   for ( ff:=1;;ff=0 ) {
      index := _TreeGetNextCheckedIndex(ff,info);
      if (ff==1 && index<0) {
         // Do this in case the item was not actually checked, the user just
         // wants to operate on the current item.
         index = _TreeCurIndex();
      }
      if ( index<0 ) break;
      curFilename := svcGetFilenameFromUpdateTree(index);
      if ( length(curFilename) < length(topFilename)) {
         continue;
      }
      _TreeGetInfo(index,auto state,auto bm1);
      
      bmIndex := bm1;
      INTARRAY overlays;
      if ( statusTable:[_file_case(curFilename)]==null ) {
         if ( _last_char(curFilename)==FILESEP || isdirectory(curFilename) ) {
            bmIndex = _pic_fldopen;
         } else {
            bmIndex = _pic_cvs_file;
         }
      } else {
         _SVCGetFileBitmap(statusTable:[_file_case(curFilename)],bmIndex,overlays);
      }
      // Delete the item from the hash table.  This is so that when we get to 
      // the bottom of the function we know that anything left can be added
      statusTable._deleteel(_file_case(curFilename));
      _TreeSetInfo(index,state,bmIndex,bmIndex,0,1,-1,overlays);
   }

   // If we are updating after an add operation, the rest of the items in the 
   // hashtable need to be added to the tree
   if ( isAdd ) {
      int pathIndexes:[]=null;
      getLocalRootFromDialog(auto rootPath);
      typeless j;
      seedCurrentDirectories(pathIndexes);
      for (j._makeempty();;) {
         statusTable._nextel(j);
         if (j._isempty()) break;
         curPath := j;
         pathIndex := _SVCGetPathIndex(_strip_filename(curPath,'N'),rootPath,pathIndexes);
         if (pathIndex>=0) {
            _SVCGetFileBitmap(statusTable:[_file_case(curPath)],auto bmIndex,auto overlays);
            curPath = _strip_filename(curPath,'P');
            findIndex := _TreeSearch(pathIndex,curPath);
            if ( findIndex<0 ) {
               int newIndex = _TreeAddItem(pathIndex,curPath,TREE_ADD_AS_CHILD,bmIndex,bmIndex,-1);
               _TreeSetCheckable(newIndex,1,1);
            } else {
               _TreeGetInfo(findIndex,auto state);
               _TreeSetInfo(findIndex,state,bmIndex,bmIndex,0,1,-1,overlays);
               _TreeSetCheckable(findIndex,1,1);
            }
         }
      }
   }
   ctltree1._TreeSortTree();
}

static void seedCurrentDirectories(int (&pathIndexes):[]) 
{
   index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);

   for (;;) {
      if (index<0) break;
      _TreeGetInfo(index,auto state,auto bm1);
      if ( bm1==_pic_cvs_fld_p
           || bm1==_pic_cvs_fld_qm
           || bm1==_pic_cvs_fld_date
           || bm1==_pic_cvs_fld_mod_date
           || bm1==_pic_fldopen ) {
         cap := _TreeGetCaption(index);
         pathIndexes:[_file_path(cap)] = index;
      }
      index = _TreeGetNextIndex(index);
   }
}

static _str getStatus(SVC_UPDATE_INFO &fileStatus) {
   str:=fileStatus.filename' ';
   if (fileStatus.status&SVC_STATUS_SCHEDULED_FOR_ADDITION) str :+= '|SVC_STATUS_SCHEDULED_FOR_ADDITION';
   if (fileStatus.status&SVC_STATUS_SCHEDULED_FOR_DELETION) str :+= '|SVC_STATUS_SCHEDULED_FOR_DELETION';
   if (fileStatus.status&SVC_STATUS_MODIFIED) str :+= '|SVC_STATUS_MODIFIED';
   if (fileStatus.status&SVC_STATUS_CONFLICT) str :+= '|SVC_STATUS_CONFLICT';
   if (fileStatus.status&SVC_STATUS_EXTERNALS_DEFINITION) str :+= '|SVC_STATUS_EXTERNALS_DEFINITION';
   if (fileStatus.status&SVC_STATUS_IGNORED) str :+= '|SVC_STATUS_IGNORED';
   if (fileStatus.status&SVC_STATUS_NOT_CONTROLED) str :+= '|SVC_STATUS_NOT_CONTROLED';
   if (fileStatus.status&SVC_STATUS_MISSING) str :+= '|SVC_STATUS_MISSING';
   if (fileStatus.status&SVC_STATUS_NODE_TYPE_CHANGED) str :+= '|SVC_STATUS_NODE_TYPE_CHANGED';
   if (fileStatus.status&SVC_STATUS_PROPS_MODIFIED) str :+= '|SVC_STATUS_PROPS_MODIFIED';
   if (fileStatus.status&SVC_STATUS_PROPS_ICONFLICT) str :+= '|SVC_STATUS_PROPS_ICONFLICT';
   if (fileStatus.status&SVC_STATUS_LOCKED) str :+= '|SVC_STATUS_LOCKED';
   if (fileStatus.status&SVC_STATUS_SCHEDULED_WITH_COMMIT) str :+= '|SVC_STATUS_SCHEDULED_WITH_COMMIT';
   if (fileStatus.status&SVC_STATUS_SWITCHED) str :+= '|SVC_STATUS_SWITCHED';
   if (fileStatus.status&SVC_STATUS_NEWER_REVISION_EXISTS) str :+= '|SVC_STATUS_NEWER_REVISION_EXISTS';
   if (fileStatus.status&SVC_STATUS_TREE_ADD_CONFLICT) str :+= '|SVC_STATUS_TREE_ADD_CONFLICT';
   if (fileStatus.status&SVC_STATUS_TREE_DEL_CONFLICT) str :+= '|SVC_STATUS_TREE_DEL_CONFLICT';
   if (fileStatus.status&SVC_STATUS_EDITED) str :+= '|SVC_STATUS_EDITED';
   if (fileStatus.status&SVC_STATUS_NO_LOCAL_FILE) str :+= '|SVC_STATUS_NO_LOCAL_FILE';
   if (fileStatus.status&SVC_STATUS_PROPS_NEWER_EXISTS) str :+= '|SVC_STATUS_PROPS_NEWER_EXISTS';
   if (fileStatus.status&SVC_STATUS_DELETED) str :+= '|SVC_STATUS_DELETED';
   if (fileStatus.status&SVC_STATUS_UNMERGED) str :+= '|SVC_STATUS_UNMERGED';
   if (fileStatus.status&SVC_STATUS_COPIED_IN_INDEX) str :+= '|SVC_STATUS_COPIED_IN_INDEX';
   if (fileStatus.status&SVC_STATUS_UPDATED_IN_INDEX) str :+= '|SVC_STATUS_UPDATED_IN_INDEX';
   if (!fileStatus.status) str:+= '|SVC_STATUS_NONE';
   return str;
}

static void _SVCGetFileBitmap(SVC_UPDATE_INFO &fileStatus,int &bitmap1, INTARRAY &overlays,
                              int defaultBitmap=_pic_cvs_file,
                              int defaultBitmapFolder=_pic_fldopen)
{
   if ( _last_char(fileStatus.filename)==FILESEP ) {
      bitmap1=_pic_fldopen;
   } else {
      bitmap1=_pic_cvs_file;
   }
   if ( fileStatus.status & SVC_STATUS_NOT_CONTROLED ) {
      overlays :+=  _pic_file_unkown_overlay;
   }
   if ( fileStatus.status & SVC_STATUS_MISSING ) {
      overlays :+=  _pic_file_deleted_overlay;
   }
   if ( fileStatus.status & SVC_STATUS_UPDATED_IN_INDEX ) {
      overlays :+=  _pic_file_add_overlay;
   }
   if ( fileStatus.status & SVC_STATUS_SCHEDULED_FOR_DELETION ) {
      overlays :+=  _pic_file_deleted_overlay;
   }
   if ( fileStatus.status & SVC_STATUS_SCHEDULED_FOR_ADDITION ) {
      overlays :+=  _pic_file_add_overlay;
   }
   if ( fileStatus.status & SVC_STATUS_TREE_ADD_CONFLICT ) {
      overlays :+=  _pic_file_add_overlay;
      overlays :+=  _pic_file_conflict_overlay;
   }
   if ( fileStatus.status & SVC_STATUS_TREE_DEL_CONFLICT ) {
      overlays :+=  _pic_file_deleted_overlay;
      overlays :+=  _pic_file_conflict_overlay;
   }
   if ( fileStatus.status & SVC_STATUS_UNMERGED ) {
      overlays :+=  _pic_file_not_merged_overlay;
   }
   if ( fileStatus.status & SVC_STATUS_COPIED_IN_INDEX ) {
      overlays :+=  _pic_file_copied_overlay;
   }
   if ( fileStatus.status & SVC_STATUS_LOCKED ) {
      overlays :+=  _pic_file_locked_overlay;
   }

   if ( fileStatus.status & SVC_STATUS_CONFLICT ) {
      overlays :+=  _pic_file_conflict_overlay;
   }else{
      if ( fileStatus.status & SVC_STATUS_MODIFIED ) {
         overlays :+=  _pic_file_mod_overlay;
      }
      if ( fileStatus.status & SVC_STATUS_NEWER_REVISION_EXISTS ) {
         overlays :+=  _pic_file_date_overlay;
      }
   }
}

void ctlcollapse.lbutton_up()
{
   p_active_form.call_event(p_active_form,ON_RESIZE);
   if ( p_value == 1 ) {
      ctltree1.call_event(CHANGE_SELECTED,ctltree1._TreeCurIndex(),ctltree1,ON_CHANGE,'W');
   }
}

void _svc_mfupdate_form.on_resize()
{
   int xbuffer=ctltree1.p_x;
   int client_width=_dx2lx(SM_TWIP,p_client_width);
   int client_height=_dy2ly(SM_TWIP,p_client_height);

   ctltree1.p_width=/*ctltree2.p_width=*/client_width-(2*xbuffer);
   ctlrep_label.p_x=ctltree1.p_x+(ctltree1.p_width intdiv 2);

   if ( ctlcollapse.p_value==0 ) {
      ctltree1.p_height=client_height-(ctltree1.p_y+ctlclose.p_height+ctlcollapse.p_height+(xbuffer*5));
      ctlcollapse.p_y = ctltree1.p_y_extent+xbuffer;
      ctlcollapse.p_next.p_y = ctlcollapse.p_y;
      ctlminihtml1.p_visible = false;

      ctlclose.p_y=ctlcollapse.p_y_extent+(xbuffer);

      ctlmerge.p_y=ctlupdate_all.p_y=ctlrevert.p_y=ctlhistory.p_y=ctldiff.p_y=ctlupdate.p_y=ctlclose.p_y;
   } else {
      ctltree1.p_height=client_height-(ctltree1.p_y+ctlclose.p_height+ctlcollapse.p_height+(xbuffer*5)+ctlminihtml1.p_height);
      ctlcollapse.p_y = ctltree1.p_y_extent+xbuffer;
      ctlcollapse.p_next.p_y = ctlcollapse.p_y;
      ctlminihtml1.p_visible = true;
      ctlminihtml1.p_y = ctlcollapse.p_y_extent+xbuffer;
      ctlminihtml1.p_width = ctltree1.p_width;

      ctlclose.p_y=ctlminihtml1.p_y_extent+(xbuffer);

      ctlmerge.p_y=ctlupdate_all.p_y=ctlrevert.p_y=ctlhistory.p_y=ctldiff.p_y=ctlupdate.p_y=ctlclose.p_y;
   }

   // Shrink the path for the Repository if necessary
   repositoryList := _GetDialogInfoHt("CaptionRepository");
   if ( repositoryList!=null ) {
      parse ctlrep_label.p_caption with auto label ':' auto rest;
      labelWidth := ctlrep_label._text_width(label);
      wholeLabelWidth := (client_width - ctlrep_label.p_x) - labelWidth;
      wholeCaption := label':'ctlrep_label._ShrinkFilename(strip(repositoryList),wholeLabelWidth);
      ctlrep_label.p_caption = wholeCaption;
   }
   if ( ctllocal_path_label.p_x_extent > ctlrep_label.p_x ) {
      ctlrep_label.p_x = ctllocal_path_label.p_x_extent+(2*_twips_per_pixel_x());
   }
}

static void _SVCSeedPathIndexes(_str Path,int (&PathTable):[],int SeedIndex)
{
   PathTable:[_file_case(Path)]=SeedIndex;
}

static int getParentPathIndex(_str Path,int (&PathTable):[])
{
   parentPath := _parent_path(Path);
   if ( PathTable:[parentPath]!=null ) {
      return PathTable:[parentPath];
   }
   return TREE_ROOT_INDEX;
}

static bool isChildPath(_str Path,_str BasePath)
{
   if ( _file_eq( substr(Path,1,length(BasePath)),BasePath ) ) {
      return true;
   }
   return false;
}

static _str getCommonChildPath(_str Path,_str BasePath)
{
   while (!isChildPath(Path,BasePath)) {
      BasePath = _parent_path(BasePath);
      if ( BasePath=="" 
           || (_isWindows() && length(BasePath)<=2)
           ) {
         break;
      }
   }
   return BasePath;
}

int _SVCGetPathIndex(_str Path,_str BasePath,int (&PathTable):[],
                     int ExistFolderIndex=_pic_fldopen,
                     int NoExistFolderIndex=_pic_cvs_fld_m,
                     _str OurFilesep=FILESEP,
                     int state=1,
                     int checkable=1)
{
   if ( !isChildPath(Path,BasePath) ) {
      BasePath = getCommonChildPath(Path,BasePath);
   }

   _str PathsToAdd[];int count=0;
   _str OtherPathsToAdd[];
   Othercount := 0;
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
      tPath := _strip_filename(Path,'N');
      if (_file_eq(Path:+OurFilesep,BasePath) || _file_eq(tPath,Path)) break;
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

void ctltree1.c_o()
{
   index := _TreeCurIndex();
   if (index>0) {
      filename := svcGetFilenameFromUpdateTree(index,false,true);
      if ( filename!="" ) {
         svc_rclick_command('open '_maybe_quote_filename(filename));
      }
   }
}

void ctltree1.on_change(int reason,int index=-1)
{
   inOnChange := _GetDialogInfoHt("inTreeOnChange");
   if ( index<0 || inOnChange==1 ) {
      svcEnableGUIUpdateButtons();
      return;
   }
   if ( inOnChange==1 ) {
      return;
   }
   _SetDialogInfoHt("inTreeOnChange",1);
   filename := svcGetFilenameFromUpdateTree(index);
   VCSystemName := svc_get_vc_system(filename);
   IVersionControl *pInterface = svcGetInterface(VCSystemName);
   if ( pInterface==null ) {
      _SetDialogInfoHt("inTreeOnChange",0);
      return;
   }
   path := _TreeGetCaption(index);
   int state,bmindex1;
   _TreeGetInfo(index,state,bmindex1,bmindex1,auto flags,auto lineNumber,-1,auto overlays);
   Nofselected := _TreeGetNumSelectedItems();

   if (Nofselected>1) {
      ctlhistory.p_enabled=false;
   }
   switch ( reason ) {
   case CHANGE_SELECTED:
      {
         if ( ctlcollapse.p_value==1 && filename!="" && _last_char(filename) != FILESEP &&
              bmindex1!=_pic_cvs_file_qm) {
            SVCHistoryInfo historyInfo[];
            status := pInterface->getHistoryInformation(filename,historyInfo,SVC_HISTORY_NO_BRANCHES|SVC_HISTORY_LAST_ENTRY_ONLY);
            if ( !status && historyInfo._length()>=1 ) {
               setVersionInfo(index,historyInfo[historyInfo._length()-1]);

               if ( index>-1 ) {
                  HISTORY_USER_INFO info = ctltree1._TreeGetUserInfo(index);
                  if ( VF_IS_STRUCT(info) ) {
                     _TextBrowserSetHtml(ctlminihtml1,"");
                     len := info.lineArray._length();
                     infoStr := "";
                     for ( i:=0;i<len;++i ) {
                        infoStr :+= "\n":+info.lineArray[i];
                     }
                     _TextBrowserSetHtml(ctlminihtml1,infoStr);
                  } else {
                     _TextBrowserSetHtml(ctlminihtml1,"");
                  }
               } else {
                  _TextBrowserSetHtml(ctlminihtml1,"");
               }
            } else {
               _TextBrowserSetHtml(ctlminihtml1,"");
            }
         } else {
            _TextBrowserSetHtml(ctlminihtml1,"");
         }
      }
      break;
   case CHANGE_LEAF_ENTER:
      int numSelected = ctltree1._TreeGetNumSelectedItems();
      if (numSelected==1) {
#if 1 //4:54pm 3/11/2020
         origWID := p_window_id;
         diffGUIUpdate(null,null,null,auto filesModifiedInDiff=false);
         if ( filesModifiedInDiff ) {
            SVC_UPDATE_INFO info;
            info.filename = filename;
            SVCFileStatus fileStatus;
            status := pInterface->getFileStatus(info.filename,info.status);
            if ( status ) break;

            // Get the overlay for the status
            origOverlays := overlays;
            overlays = null;
            _SVCGetFileBitmap(info,auto bitmap,overlays);

            p_window_id = origWID;
            if (origOverlays!=overlays) {
               _TreeSetInfo(index,state,bitmap,bitmap,0,1,-1,overlays);
            }
            origWID._set_focus();
         } else {
            p_window_id = origWID;
            origWID._set_focus();
         }
#else
         // Only want to do this if there is one file selected, otherwise
         // it was likely somebody selecting multiple items and accidentally
         // double clicking
         //ctldiff.call_event(ctldiff,LBUTTON_UP);
         if ( filename=="" ) return;
         formWID := p_active_form;
         wid     := p_window_id;
         orig_file_date := _file_date(filename,'B');
         {
            if ( bmindex1==_pic_file_old_mod || bmindex1==_pic_file_old_mod ) {
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
                  svc_diff_with_tip(filename,curLocalRevision,"",true);
               } else if ( result==2 ) {
                  svc_diff_with_tip(filename,curRevision,"",true);
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
            } else if ( bmindex1==_pic_file_mod && pInterface->getBaseRevisionSpecialName() != "") {
               svc_diff_with_tip(filename,pInterface->getBaseRevisionSpecialName(),VCSystemName,true);
            } else if ( bmindex1!=_pic_cvs_file_qm ) {
               svc_diff_with_tip(filename,"",VCSystemName,true);
            }
         }
         diff_file_date := _file_date(filename,'B');
         if (diff_file_date != orig_file_date) {
            SVC_UPDATE_INFO info;
            info.filename = filename;
            SVCFileStatus fileStatus;
            status := pInterface->getFileStatus(info.filename,info.status);
            if ( status ) break;

            // Get the picture for the status
            _SVCGetFileBitmap(info,auto bitmap,overlays);

            p_window_id = wid;
            _TreeGetInfo(index,state,auto curBitmap);
            _TreeSetInfo(index,state,bitmap,bitmap,0,1,-1,overlays);
            wid._set_focus();
         } else {
            p_window_id = wid;
            wid._set_focus();
         }

#endif
      }
      break;
   }
   svcEnableGUIUpdateButtons();
   _SetDialogInfoHt("inTreeOnChange",0);
}

static void setVersionInfo(int index,SVCHistoryInfo &historyInfo)
{
//   say('setVersionInfo historyInfo.revision='historyInfo.revision' comment='historyInfo.comment);
   _str lineArray[];
   if ( historyInfo.author!="" ) lineArray[lineArray._length()]='<B>Author:</B>&nbsp;'historyInfo.author'<br>';
   if ( historyInfo.date!="" && historyInfo.date!=0) {
      ftime := strftime("%c",historyInfo.date);
      if ( ftime == "" ) {
         // If this would not convert cleanly, display the date we have
         ftime = historyInfo.date;
      }
      lineArray[lineArray._length()]='<B>Date:</B>&nbsp;':+ftime'<br>';
   }
   if ( historyInfo.revisionCaption!="" ) {
      // There is a revision caption (git), this is what is displayed in the 
      // tree, so we'll add a revision under the date
      lineArray[lineArray._length()]='<B>Revision:</B>&nbsp;'historyInfo.revision'<br>';
   }
   if ( historyInfo.changelist!=null && historyInfo.changelist!="" ) {
      lineArray[lineArray._length()]='<B>Changelist:</B>&nbsp;'historyInfo.changelist'<br>';
   }
   // Replace comment string line endings with <br> to preserve formatting
   commentBR := stranslate(historyInfo.comment, '<br>', '\n', 'l');
   if ( commentBR!="" ) {
      lineArray[lineArray._length()]='<B>Comment:</B>&nbsp;'commentBR;
   }
   if( historyInfo.affectedFilesDetails :!= '' ) {
      lineArray[lineArray._length()]='<br><B>Changed paths:</B><font face="Menlo, Monaco, Consolas, Courier New, Monospace">'historyInfo.affectedFilesDetails'</font>';
   }
   HISTORY_USER_INFO info;
   info.actualRevision = historyInfo.revision;
   info.lineArray      = lineArray;
   ctltree1._TreeSetUserInfo(index,info);
}

void ctltree1.rbutton_up()
{
   index := _TreeCurIndex();
   filename := svcGetFilenameFromUpdateTree(index,false,true);

   _TreeGetInfo(index,auto state,auto bm1);
   isUpdate := bm1==_pic_file_old||bm1==_pic_file_old_mod||bm1==_pic_file_mod_prop;
   isCommit := bm1==_pic_file_mod||_pic_cvs_filep;

   int MenuIndex=find_index("_svc_update_rclick",oi2type(OI_MENU));
   int menu_handle=_mdi._menu_load(MenuIndex,'P');

   int x,y;
   mou_get_xy(x,y);

   copyPathCaption := "Copy filename to clipboard";
   if ( filename!="" ) {
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

      _menu_find(menu_handle,"svc-rclick-command createShelf",auto outputHandle,auto outputPos,'M');
      if ( outputPos>=0 ) {
         len := def_svc_all_shelves._length();
         if ( len>0 ) {
            testHandle := _menu_insert(menu_handle,++outputPos,MF_SUBMENU,"Add to shelf");
            if ( testHandle ) {
               for ( i:=0;i<len;++i ) {
                  _menu_insert(testHandle,i,MF_ENABLED,def_svc_all_shelves[i],'svc-rclick-command addToShelf '_maybe_quote_filename(def_svc_all_shelves[i])' '_maybe_quote_filename(filename));
               }
            }
         }
      }

      // Next menu item is history
      _menu_get_state(menu_handle,menuItem,flags,'P',caption,command);
      _menu_set_state(menu_handle,menuItem,flags,'P',caption' 'filename);

      ++menuItem;
      // Next menu item is history diff
      _menu_get_state(menu_handle,menuItem,flags,'P',caption,command);
      _menu_set_state(menu_handle,menuItem,flags,'P',caption' 'filename,'svc-history-diff 'filename);

      ++menuItem;
      // Next menu item is -
      ++menuItem;
      // Next menu item is open
      _menu_get_state(menu_handle,menuItem,flags,'P',caption,command);
      _menu_set_state(menu_handle,menuItem,flags,'P',caption' 'filename,'svc-rclick-command open '_maybe_quote_filename(filename));
   }
   menuItem := _menu_find_loaded_menu_caption(menu_handle,"Deselect out of date");
   // Next menu item is -
   ++menuItem;
   ++menuItem;
   _menu_get_state(menu_handle,menuItem,auto flags,'P',auto caption,auto command);
   if ( last_char(filename) == FILESEP ) {
      copyPathCaption = "Copy path to clipboard";
   }
   _menu_set_state(menu_handle,menuItem,flags,'P',copyPathCaption, command' '_maybe_quote_filename(filename));

   int status=_menu_show(menu_handle,VPM_RIGHTBUTTON,x-1,y-1);
   _menu_destroy(menu_handle);
}

void ctltree1.del()
{
   curIndex := _TreeCurIndex();
   if (curIndex<0) return;
   _TreeGetInfo(curIndex,auto state,auto bm1, auto bm2, auto nodeFlags,auto lineNumber, -1, auto overlays);
   indexHasUnknownOverlay := false;
   svcGetStatesFromOverlays(overlays,hadUnknownOverlay:indexHasUnknownOverlay);
   if (indexHasUnknownOverlay) {
      filename := _TreeGetCaption(_TreeGetParentIndex(curIndex)):+_TreeGetCaption(curIndex);
      status := _message_box(nls("Are you sure you want to delete the file '%s'",filename),"",MB_YESNO);
      if ( status==IDYES ) {
         orig := def_delete_uses_recycle_bin;
         def_delete_uses_recycle_bin = true;
         status = recycle_file(filename);
         def_delete_uses_recycle_bin = orig;
         if ( !status ) {
            _TreeDelete(curIndex);
         }
      }
      return;
   }
   VCSystemName := _GetDialogInfoHt("VCSystemName");
   if ( VCSystemName=="") VCSystemName = svc_get_vc_system();
   IVersionControl *pInterface = svcGetInterface(VCSystemName);
   if ( pInterface==null ) return;

   origWID := p_window_id;
   p_window_id = ctltree1;
   INTARRAY selectedIndexList;
   STRARRAY selectedFileList;

   mou_hour_glass(true);
   origFID := p_active_form;
   p_window_id = ctltree1;
   // Add all the selected items
   _str fileTable:[];
   directoriesAreInList := false;
   info := 0;
   for ( ff:=1;;ff=0 ) {
      index := _TreeGetNextCheckedIndex(ff,info);
      if ( index<0 ) break;
      if ( index==TREE_ROOT_INDEX ) continue;
      if ( _TreeGetCheckState(index)==TCB_CHECKED ) {
         selectedIndexList :+= index;
         filename := svcGetFilenameFromUpdateTree(index,true);
//         if (last_char(filename)==FILESEP) continue;
         selectedFileList :+= filename;
         if ( _last_char(filename)==FILESEP ) {
            directoriesAreInList = true;
         }
         fileTable:[_file_case(filename)] = "";
      }
   }

   // If no items were selected, add the current item
   if ( selectedIndexList._length()==0 ) {
      index := _TreeCurIndex();
      if ( index>=0 )selectedIndexList :+= index;
      filename := svcGetFilenameFromUpdateTree(index);
      selectedFileList :+= filename;
   }
   p_window_id = origWID;
   status := pInterface->removeFiles(selectedFileList);
   _filewatchRefreshFiles(selectedFileList);
   _SVCUpdateRefreshAfterOperation(selectedFileList,selectedIndexList,fileTable,pInterface);
   mou_hour_glass(false);
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

static void svcEnableRevertButton(bool checkForUpdateDashC)
{
   ctlrevert.p_visible=true;
}

static void svcGetStatesFromOverlays(INTARRAY &overlays,
                                     bool &hadAddedOverlay=false,
                                     bool &hadDeletedOverlay=false,
                                     bool &hadModOverlay=false,
                                     bool &hadDateOverlay=false,
                                     bool &hadCheckoutOverlay=false,
                                     bool &hadUnknownOverlay=false,
                                     bool initialize=true)
{
   if ( initialize ) {
      hadAddedOverlay = false;
      hadDeletedOverlay = false;
      hadModOverlay = false;
      hadDateOverlay = false;
      hadCheckoutOverlay = false;
      hadUnknownOverlay = false;
   }
   len := overlays._length();
   for (i:=0; i<len; ++i) {
      curOverlay := overlays[i];
      if ( curOverlay==_pic_file_add_overlay) {
         hadAddedOverlay=true;
      }
      if ( curOverlay==_pic_file_deleted_overlay ) {
         hadDeletedOverlay=true;
      }
      if ( curOverlay==_pic_file_mod_overlay ) {
         hadModOverlay = true;
      }
      if ( curOverlay==_pic_file_date_overlay ) {
         hadDateOverlay = true;
      }
      if ( curOverlay==_pic_file_checkout_overlay ) {
         hadCheckoutOverlay = true;
      }
      if ( curOverlay==_pic_file_unkown_overlay ) {
         hadUnknownOverlay = true;
      }
   }
}

static void svcEnableGUIUpdateButtons()
{
   VCSystemName := _GetDialogInfoHt("VCSystemName");
   if ( VCSystemName=="" || VCSystemName==null ) VCSystemName = svc_get_vc_system();
   IVersionControl *pInterface = svcGetInterface(VCSystemName);
   if ( pInterface==null ) return;

   systemName := lowcase(pInterface->getSystemNameCaption());

   isCVS := systemName=="cvs";
   isHg  := systemName=="hg";
   checkForUpdateDashC := isCVS;
   wid := p_window_id;
   p_window_id=ctltree1;
   curindex := _TreeCurIndex();
   int state,bmindex1,bmindex2;
   _TreeGetInfo(curindex,state,bmindex1,bmindex2);
   bmindex := -1;
   last_selected := -1;
   valid_bitmaps := "";
   invalid := false;
   bm1 := 0;
   addedFile   := false;
   deletedFile := false;
   oldModFile  := false;
   directoriesAreSelected := false;
   selinfo := 0;
   checkedItem := false;
   canDiffFile := false;
   hadModOverlay := false;
   hadDateOverlay := false;
   hadAddedOverlay := false;
   hadDeletedOverlay := false;
   hadCheckoutOverlay := false;
   hadUnknownOverlay := false;
   int indexTable:[][];
   i:=0;
   INTARRAY overlays = null;
   for ( ff:=1;;ff=0,++i ) {
      index := _TreeGetNextCheckedIndex(ff,selinfo);
      if ( index<1 ) {
         break;
      }
      checkedItem = true;
      _TreeGetInfo(index,state,bm1,bm1,0,auto lineNumber, -1, overlays);
      if ( bm1== _pic_fldopen && overlays._length()>0 ) {
         directoriesAreSelected = true;
      }
      svcGetStatesFromOverlays(overlays,hadAddedOverlay,hadDeletedOverlay,hadModOverlay,hadDateOverlay,hadCheckoutOverlay,hadUnknownOverlay,ff==1);
      if ( hadAddedOverlay && hadDeletedOverlay && hadModOverlay && hadDateOverlay && hadCheckoutOverlay && hadUnknownOverlay) {
         // If we've had everything, we can stop looking
         break;
      }
      overlays = null;
   }
   //say('svcEnableGUIUpdateButtons checkedItem='checkedItem' directoriesAreSelected='directoriesAreSelected);

   if ( !checkedItem ) {
      index := _TreeCurIndex();
      _TreeGetInfo(index,state,bm1,bm1,0,auto lineNumber,-1,overlays);
      if ( bm1== _pic_fldopen && overlays._length()>0 ) {
         directoriesAreSelected = true;
      }
      svcGetStatesFromOverlays(overlays,hadAddedOverlay,hadDeletedOverlay,hadModOverlay,hadDateOverlay,hadCheckoutOverlay,hadUnknownOverlay);
   }
   p_window_id=ctlupdate;
   if ( (hadModOverlay || hadDateOverlay) && !(hadDeletedOverlay || hadAddedOverlay || directoriesAreSelected || hadCheckoutOverlay) ) {
      ctlhistory.p_enabled=true;
      ctldiff.p_enabled=true;
      if ( hadDateOverlay ) {
         ctlupdate.p_enabled=true;
      } else {
         ctlupdate.p_enabled=false;
      }
      ctlrevert.p_visible=true;
      ctlmerge.p_visible=false;
      if (hadDateOverlay) {
         p_caption=SVC_UPDATE_CAPTION_UPDATE;
      } else {
         p_caption = pInterface->getCaptionForCommand(SVC_COMMAND_COMMIT);
      }
      p_enabled=true;
   } else if ( hadUnknownOverlay ) {
      ctlhistory.p_enabled=false;
      ctldiff.p_enabled=false;
      ctlupdate.p_enabled=false;
      ctlupdate_all.p_enabled=false;
      ctlrevert.p_visible=false;
      ctlmerge.p_visible=false;
      p_enabled=true;
      p_caption=SVC_UPDATE_CAPTION_ADD;
   } else if ( hadDeletedOverlay || hadAddedOverlay || hadCheckoutOverlay ) {
      if ( hadAddedOverlay ) {
         ctlhistory.p_enabled=false;
         ctldiff.p_enabled=false;
      }else{
         ctlhistory.p_enabled=true;
         ctldiff.p_enabled=true;
      }
      ctlupdate.p_enabled=false;
      ctlupdate_all.p_enabled=false;
      ctlrevert.p_visible=true;
      ctlmerge.p_visible=false;

      p_enabled=true;
      p_caption = pInterface->getCaptionForCommand(SVC_COMMAND_COMMIT);
   }
   hadNoOverlays := !hadModOverlay && !hadDateOverlay && !hadDeletedOverlay && !addedFile && !hadCheckoutOverlay;
   if ( directoriesAreSelected && hadNoOverlays ) {
      ctlhistory.p_enabled=false;
      ctldiff.p_enabled=false;
      ctlupdate.p_enabled=false;
      ctlupdate_all.p_enabled=false;
      ctlrevert.p_visible=false;
      ctlmerge.p_visible=false;
      p_enabled=false;
      p_caption=SVC_UPDATE_CAPTION_ADD;
   }

   int button_width=max(p_width,_text_width(p_caption)+400);
   if ( button_width>p_width ) {
      orig_button_width := p_width;
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

   int numselected = ctltree1._TreeGetNumSelectedItems();
   if ( numselected>1 && ctlupdate.p_enabled && ctlupdate.p_caption==SVC_UPDATE_CAPTION_MERGE ) {
      // Do not allow merge for multiple files
      ctlupdate.p_enabled = false;
   }

   p_window_id=wid;
}
struct ShelfFileInfo {
   _str filename;
   _str revision;
   _str commentArray[];
   _str baseFile;
   _str modFile;
};

struct ShelfInfo {
   _str shelfName;
   _str localRoot;
   _str baseRoot; // Only need this if creating shelf from multi-file diff
   _str VCSystemName;
   _str commentArray[];
   ShelfFileInfo fileList[];
};

int mfdiffCreateShelf()
{
   _nocheck _control ctlpath1label;
   _nocheck _control ctlpath2label;
   _nocheck _control tree1;
   _nocheck _control tree2;
   int info;
   STRARRAY captions;
   path1 := ctlpath1label.p_caption;
   path2 := ctlpath2label.p_caption;

   parse path1 with 'Path &1:' path1;
   parse path2 with 'Path &2:' path2;
   int numSelected=0;
   INTARRAY selectedIndexList;
   for (ff:=1;;ff=0,++numSelected) {
      index := _TreeGetNextSelectedIndex(ff,info);
      if (index<0) break;
      selectedIndexList :+= index;
   }

#if 0 //12:59pm 8/8/2019
   captions[0] = "Use "path1" as the base";
   captions[1] = "Use "path2" as the base";
   status := RadioButtons("Create Shelf",captions);
   if (status==COMMAND_CANCELLED_RC) return status;
#endif

   modPathWID := p_window_id;
   basePathWID := modPathWID==tree1?tree1:tree2;
   basePath := "";
   localPath := "";
   if (basePathWID == tree1) {
      basePath = path2;
      localPath = path1;
   } else if (basePathWID == tree2) {
      basePath = path1;
      localPath = path2;
   }
   status := 0;



   ShelfInfo shelf;
   promptForNewShelfName(shelf.shelfName);
   if ( shelf.shelfName=="" ) return COMMAND_CANCELLED_RC;
   mou_hour_glass(true);
   STRARRAY selectedFileVersionList;
   shelf.VCSystemName = "";

   do {
      origWID := p_window_id;
      origFID := p_active_form;
      // Add all the selected items
      shelf.localRoot = localPath;
      _maybe_append_filesep(basePath);
      shelf.baseRoot = basePath;
      // If no items were selected, add the current item
      if ( selectedIndexList._length()==0 ) {
         index := _TreeCurIndex();
         if ( index>=0 )selectedIndexList :+= index;
         _TreeGetInfo(index,auto state,auto bm1);
      }

      len := selectedIndexList._length();
      if ( len==0 ) {
         return COMMAND_CANCELLED_RC;
      }

      for ( i:=0;i<len;++i ) {
         curIndex := selectedIndexList[i];
         if ( curIndex<0 ) break;
         curFilename := svcGetFilenameFromUpdateTree(curIndex,false,false,p_window_id);
         if ( curFilename=="" || _last_char(curFilename)==FILESEP ) continue;

         ShelfFileInfo curFile;
         curFile.filename = relative(curFilename,shelf.localRoot);
         curFile.revision = "mfdiff";
         if ( curFile.filename!="" ) {
            shelf.fileList :+= curFile;
         }
      }
      mou_hour_glass(false);
      len = shelf.fileList._length();
      if ( len ) {
         zipFilename := shelf.shelfName;
         if ( !path_exists(getShelfBasePath()) ) {
            make_path(getShelfBasePath());
         }
         if ( !status ) {
            guiEditShelf(&shelf,zipFilename,false);
            removeFileFromList(zipFilename);
            def_svc_all_shelves._insertel(zipFilename,0);
            _config_modify_flags(CFGMODIFY_DEFVAR);
         }
      }
   } while (false);
   mou_hour_glass(false);
   return status;
}

static int svcCreateShelf()
{
   ShelfInfo shelf;
   promptForNewShelfName(shelf.shelfName);
   if ( shelf.shelfName=="" ) return COMMAND_CANCELLED_RC;
   mou_hour_glass(true);
   STRARRAY selectedFileVersionList;
   int info;

   status := 0;
   mou_hour_glass(true);
   do {
      origWID := p_window_id;
      origFID := p_active_form;
      p_window_id = ctltree1;
      // Add all the selected items
      getLocalRootFromDialog(shelf.localRoot);
      _maybe_append_filesep(shelf.localRoot);
      INTARRAY selectedIndexList;
      for ( ff:=1;;ff=0 ) {
         index := _TreeGetNextCheckedIndex(ff,info);
         if ( index<0 ) break;
         selectedIndexList :+= index;
      }
      // If no items were selected, add the current item
      if ( selectedIndexList._length()==0 ) {
         index := _TreeCurIndex();
         if ( index>=0 )selectedIndexList :+= index;
         ctltree1._TreeGetInfo(index,auto state,auto bm1);
      }

      len := selectedIndexList._length();
      if ( len==0 ) {
         return COMMAND_CANCELLED_RC;
      }

      autoVCSystem := svc_get_vc_system(selectedIndexList[0]);
      IVersionControl *pInterface = svcGetInterface(autoVCSystem);
      if ( pInterface==null ) return VSRC_SVC_COULD_NOT_GET_VC_INTERFACE_RC;

      shelf.VCSystemName = pInterface->getSystemNameCaption();

      for ( i:=0;i<len;++i ) {
         curIndex := selectedIndexList[i];
         if ( curIndex<0 ) break;
         curFilename := svcGetFilenameFromUpdateTree(curIndex);
         if ( curFilename=="" || _last_char(curFilename)==FILESEP ) continue;

         curLocalRevision := "";

         status = pInterface->getFileStatus(curFilename,auto fileStatus=SVC_STATUS_NONE,checkForUpdates:false);

         if ( !_file_eq(shelf.localRoot,substr(curFilename,1,length(shelf.localRoot))) ) {
            child := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
            if ( child > 0) {
               shelf.localRoot = _TreeGetCaption(child);
            }
         }

         ShelfFileInfo curFile;
         curFile.filename = relative(curFilename,shelf.localRoot);
         curFile.revision = "";
         curRevision := "";
         if ( !status && !(fileStatus&SVC_STATUS_NOT_CONTROLED) ) {
            pInterface->getCurRevision(curFilename,curRevision,"",true);
            status = pInterface->getCurLocalRevision(curFilename,curLocalRevision,true);
            curFile.revision = curLocalRevision;
         }
         if ( curFile.filename!="" ) {
            shelf.fileList :+= curFile;
            selectedFileVersionList :+= curRevision;
         }
      }
      mou_hour_glass(false);
      len = shelf.fileList._length();
      if ( len ) {
         warnAboutOutOfDateFiles := false;
         for (i=0;i<len;++i) {
            curFilename := shelf.fileList[i];

            if ( selectedFileVersionList[i] != shelf.fileList[i].revision ) {
               warnAboutOutOfDateFiles = true;
            }
         }
         if ( warnAboutOutOfDateFiles ) {
            result := _message_box(nls("You have files that are not up-to-date.\n\nDo you still wish to create the shelf?"),"",MB_YESNOCANCEL);
            if (result != IDYES) {
               status = 1;break;
            }
         }
         shelf.VCSystemName = pInterface->getSystemNameCaption();
         zipFilename := shelf.shelfName;
         if ( !path_exists(getShelfBasePath()) ) {
            make_path(getShelfBasePath());
         }
         if ( !status ) {
            guiEditShelf(&shelf,zipFilename,false);
            result := _message_box(nls("Revert these files now?"),"",MB_YESNO);
            if ( result==IDYES ) {
               ctlrevert.call_event(ctlrevert,LBUTTON_UP);
            }
            removeFileFromList(zipFilename);
            def_svc_all_shelves._insertel(zipFilename,0);
            _config_modify_flags(CFGMODIFY_DEFVAR);
         }
      }
   } while (false);
   mou_hour_glass(false);
   return status;
}

static _str getCheckedFileList()
{
   checkedFileList := "";
   int info;
   for (ff:=1;;ff=0) {
      index := _TreeGetNextCheckedIndex(ff,info);
      if ( index<0 ) break;
      if ( _TreeGetFirstChildIndex(index)==-1 ) {
         parent := _TreeGetParentIndex(index);
         parentCaption := _TreeGetCaption(parent);
         caption := _TreeGetCaption(index);
         checkedFileList :+= ' '_maybe_quote_filename(parentCaption:+caption);
      }
   }
   return checkedFileList;
}

_command void svc_rclick_command(_str commandLine="") name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      return;
   }
   command := parse_file(commandLine);
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
   case "createshelf":
      {
         svcCreateShelf();
         clearChecks();
      }
      break;
   case "addtoshelf":
      {
         zipFilename := strip(parse_file(commandLine),'B','"');
         filename := strip(parse_file(commandLine),'B','"');
         checkedFileList := getCheckedFileList();
         if (checkedFileList=="") {
            index = _TreeCurIndex();
            parent := _TreeGetParentIndex(index);
            parentCaption := _TreeGetCaption(parent);
            checkedFileList = parentCaption:+_TreeGetCaption(index);
         }
         status := svcAddControlledFileToShelf(zipFilename,checkedFileList);
         if ( !status ) {
            result := _message_box(nls("Revert these files now?"),"",MB_YESNO);
            if ( result==IDYES ) {
               ctlrevert.call_event(ctlrevert,LBUTTON_UP);
            }
         }
         clearChecks();
      }
      break;
   case "commit":
   case "update":
      {
         IVersionControl *pInterface = svcGetInterface(svc_get_vc_system());
         if ( pInterface==null ) return;

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
         _SVCUpdateRefreshAfterOperation(selectedFileList,selectedIndexList,fileTable,pInterface);
      }
      break;
   case "history":
      {
         IVersionControl *pInterface = svcGetInterface(svc_get_vc_system());
         if ( pInterface==null ) return;

         filename := parse_file(commandLine);
         saveChecks(auto checkList);
         clearChecks();
         _TreeSetCheckState(index,TCB_CHECKED);
         ctlhistory.call_event(ctlhistory,LBUTTON_UP);
         clearChecks();
         restoreChecks(checkList);
      }
      break;
   case "historydiff":
      {
         filename := parse_file(commandLine);
         saveChecks(auto checkList);
         clearChecks();
         _TreeSetCheckState(index,TCB_CHECKED);
         svc_history_diff(filename);
         clearChecks();
         restoreChecks(checkList);
      }
      break;
   case "open":
      {
         filename := parse_file(commandLine);
         ext := _get_extension(filename);
         if(ext != '') {
            ext = lowcase(ext);
            appCommand := ExtensionSettings.getOpenApplication(ext, '');
            assocType := (int)ExtensionSettings.getUseFileAssociation(ext);

            if (!assocType) {
               if (appCommand != "") {
                  _projecttbRunAppCommand(appCommand, _maybe_quote_filename(absolute(filename)));
               } else {
                  edit(_maybe_quote_filename(filename),EDIT_DEFAULT_FLAGS);
               }
               return;
            }

            status := _ShellExecute(absolute(filename));
            if ( status<0 ) {
               _message_box(get_message(status)' ':+ filename);
            }
         } else {
            // extensionless file
            edit(_maybe_quote_filename(filename),EDIT_DEFAULT_FLAGS);
         }
      }
      break;
   case "copypathtoclipboard":
      {
         filename := parse_file(commandLine);
         push_clipboard(filename);
      }
      break;
   }
}

int _checkForshelf(_str shelfName)
{
   if ( shelfExists(shelfName) ) {
      result := _message_box(nls("A shelf named %s already exists.\n\nOverwrite?",shelfName),"",MB_YESNOCANCEL);
      if (result==IDYES) return 0;
      return 1;
   }
   return 0;
}

static void promptForNewShelfName(_str &shelfName)
{
   shelfName = "";
   initialDirectory := getShelfBasePath();
   make_path(initialDirectory);
   result := _OpenDialog('-modal',
                      'Create Shelf zip file',                   // Dialog Box Title
                      '',                   // Initial Wild Cards
                      'Zip Files (*.zip)',
                      OFN_SAVEAS,
                      'zip',
                      '',
                      initialDirectory
                      );
   shelfName = strip(result,'B','"');
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
         selectedIndexList :+= index;
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
         selectedIndexList :+= index;
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

static void updateSelectModified(bool select=true,int index=TREE_ROOT_INDEX)
{
   for (;index>=0;) {
      childIndex := _TreeGetFirstChildIndex(index);
      if ( childIndex>=0 ) {
         updateSelectModified(select,childIndex);
      }
      _TreeGetInfo(index,auto state,auto bm1);
      if ( bm1==_pic_file_mod || bm1==_pic_file_old_mod || bm1==_pic_file_mod_prop ) {
         if ( select ) {
            _TreeSetCheckState(index,TCB_CHECKED);
         } else {
            _TreeSetCheckState(index,TCB_UNCHECKED);
         }
      }
      index = _TreeGetNextSiblingIndex(index);
   }
}

static void updateSelectOutOfDate(bool select=true,int index=TREE_ROOT_INDEX,bool includeMod=true)
{
   for (;index>=0;) {
      childIndex := _TreeGetFirstChildIndex(index);
      if ( childIndex>=0 ) {
         updateSelectOutOfDate(select,childIndex,includeMod);
      }
      _TreeGetInfo(index,auto state,auto bm1);
      if ( bm1==_pic_file_old ||
           (bm1==_pic_cvs_fld_date) ||
           (bm1==_pic_cvs_fld_mod_date) ||
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

static void getLocalRootFromDialog(_str &localRoot)
{
   parse ctllocal_path_label.p_caption with (LOCAL_ROOT_LABEL) localRoot;
}

static int copyFilesToShelf(ShelfInfo &shelf,_str modsRootPath)
{
   _maybe_append_filesep(modsRootPath);
   
   len := shelf.fileList._length();
   for (i:=0;i<len;++i) {
      destFilename := modsRootPath:+shelf.fileList[i].filename;
      destPath := _file_path(destFilename);

      if ( !path_exists(destPath) ) make_path(destPath);

      status := copy_file(shelf.localRoot:+shelf.fileList[i].filename,destFilename);
      if ( status ) {
         _message_box(nls("Could not copy '%s' to '%s'",shelf.fileList[i].filename,destFilename));
         return status;
      }
   }
   return 0;
}

static int getCleanFilesToShelf(IVersionControl *pInterface,
                                ShelfInfo &shelf,
                                _str baseRootPath)
{
   _maybe_append_filesep(baseRootPath);
   
   len := shelf.fileList._length();
   for (i:=0;i<len;++i) {
      base_rev := shelf.fileList[i].revision;
      if ( base_rev == "" ) continue;
      if (pInterface->getBaseRevisionSpecialName() != "") {
         base_rev = pInterface->getBaseRevisionSpecialName();
      }

      status := pInterface->getFile(shelf.localRoot:+shelf.fileList[i].filename,base_rev,auto newFileWID=0);
      // If we get a status the file may not exist in version control, but this
      // is actually OK.

      destFilename := baseRootPath:+shelf.fileList[i].filename;
      destPath := _file_path(destFilename);

      if ( !path_exists(destPath) ) make_path(destPath);

      status = newFileWID._save_file('+o '_maybe_quote_filename(destFilename));
      _delete_temp_view(newFileWID);
   }
   return 0;
}

static int writeManifestZipFile(_str zipFilename,ShelfInfo &shelf)
{
   status := writeManifestZipFileToTemp(zipFilename,shelf,auto tempFilename);
   if ( !status ) {
      _ZipClose(zipFilename);
      STRARRAY tempSourceArray,tempDestArray;
      tempSourceArray[0] = tempFilename;
      tempDestArray[0]   = "manifest.xml";
      status = _ZipAppend(zipFilename,tempSourceArray,auto zipStatus,tempDestArray);
      delete_file(tempFilename);
   }

   return status;
}

static int writeManifestZipFileToTemp(_str zipFilename,ShelfInfo &shelf,_str &tempFilename)
{
   tempFilename = "";
   manifestFilename := zipFilename:+FILESEP:+"manifest.xml";
   xmlhandle := _xmlcfg_create(manifestFilename,VSENCODING_UTF8,VSXMLCFG_CREATE_IF_EXISTS_CLEAR);
   if ( xmlhandle<0 ) {
      return xmlhandle;
   }
   shelfNode := _xmlcfg_add(xmlhandle,TREE_ROOT_INDEX,"Shelf",VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add_attribute(xmlhandle,shelfNode,"Name",shelf.shelfName);
   _xmlcfg_add_attribute(xmlhandle,shelfNode,"LocalRoot",stranslate(shelf.localRoot,'/',FILESEP));
   _xmlcfg_add_attribute(xmlhandle,shelfNode,"VCSystemName",shelf.VCSystemName);

   commentArray := shelf.commentArray;
   addComment(xmlhandle,shelfNode,commentArray);

   STRARRAY relativeFileList;
   foreach (auto curFileInfo in shelf.fileList) {
      relativeFileList :+= relative(curFileInfo.filename, shelf.localRoot);
   }

   filesNode := _xmlcfg_add(xmlhandle,shelfNode,"Files",VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
   len := shelf.fileList._length();
   for (i:=0;i<len;++i) {
       curNode := _xmlcfg_add(xmlhandle,filesNode,"File",VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
       _xmlcfg_set_attribute(xmlhandle,curNode,"N",stranslate(relativeFileList[i],'/',FILESEP));
       _xmlcfg_set_attribute(xmlhandle,curNode,"V",shelf.fileList[i].revision);
       commentArray = shelf.fileList[i].commentArray;
       addComment(xmlhandle,curNode,commentArray);
   }
   tempFilename = mktemp();
   status := _xmlcfg_save(xmlhandle,-1,VSXMLCFG_SAVE_ONE_LINE_IF_ONE_ATTR,tempFilename);
   return status;
}

static void addComment(int xmlhandle,int nodeIndex,STRARRAY &commentArray)
{
   commentLen := commentArray._length();
   comment := "";
   for (j:=0;j<commentArray._length();++j) {
      comment :+= commentArray[j]"\n";
   }
   comment = substr(comment,1,length(comment)-1);
   commentIndex := _xmlcfg_add(xmlhandle,nodeIndex,comment,VSXMLCFG_NODE_PCDATA,VSXMLCFG_ADD_AS_CHILD);
}

static const SHELVES_PATH= "shelves";

static _str getShelfBasePath()
{
   return _ConfigPath():+SHELVES_PATH:+FILESEP;
}

static bool shelfExists(_str shelfName)
{
   shelfPath := getShelfBasePath():+shelfName'.zip';
   return file_exists(shelfPath);
}

defeventtab _svc_shelf_review_form;
void ctlclose.on_create()
{
   sizeBrowseButtonToTextBox(ctlLocalRoot.p_window_id, ctlbrowse.p_window_id);
}

defeventtab _svc_shelf_form;

static const ROOT_PATH_CAPTION=     "Root Path: ";
static const UNSHELVE_PATH_CAPTION= "Unshelve to: ";
static const SHELF_COMMENT_CAPTION= "Comment: ";
static const SHELF_LOCALROOT_CAPTION= "Shelf root: ";
static const LOCAL_ROOT_LABEL=      "Local Path: ";

void ctlclose.on_create(_str zipFilename="",ShelfInfo *pshelf=null,bool *pPromptToRefresh=null,bool *pRefreshZipFile=null)
{
   len := pshelf->fileList._length();
   int pathTable:[];
   STRHASHTAB versionTable;
   STRHASHTABARRAY commentTable;
   commentTable:[PATHSEP] = pshelf->commentArray;
   for (i:=0;i<len;++i) {
      relFilename:= stranslate(pshelf->fileList[i].filename,FILESEP,'/');
      curPath := stranslate(_file_path(pshelf->fileList[i].filename),FILESEP,'/');
      pathIndex := ctltree1._SVCGetPathIndex(curPath,"",pathTable,_pic_fldopen,_pic_fldopen);
      if ( pathIndex>=0 ) {
         ctltree1._TreeAddItem(pathIndex,_strip_filename(relFilename,'P'),TREE_ADD_AS_CHILD,_pic_file,_pic_file,-1,0,relFilename);
      }
      versionTable:[relFilename] = pshelf->fileList[i].revision;
      commentTable:[_file_case(relFilename)] = pshelf->fileList[i].commentArray;
   }
   ctledit1._lbclear();
   ctledit2._lbclear();

   p_active_form.p_caption = zipFilename;

   _SetDialogInfoHt("pathTable",pathTable);
   _SetDialogInfoHt("zipFilename",zipFilename);
   _SetDialogInfoHt("pshelf",pshelf);

   _SetDialogInfoHt("commentTable",commentTable);
   _SetDialogInfoHt("versionTable",versionTable);
   _SetDialogInfoHt("pPromptToRefresh",pPromptToRefresh);
   _SetDialogInfoHt("pRefreshZipFile",pRefreshZipFile);
   ctlrootPathLabel.p_caption = ROOT_PATH_CAPTION:+pshelf->localRoot;
   ctledit1.fillInEditor(commentTable:[PATHSEP]);
}

void ctlok.lbutton_up()
{
   ctltree1.call_event(CHANGE_SELECTED,ctltree1._TreeCurIndex(),ctltree1,ON_CHANGE,'W');
   // We're using a pointer to a shelf.  Certain things are already filled in
   // (most notably localRoot).
   ShelfInfo *pshelf = _GetDialogInfoHt("pshelf");
   commentTable := _GetDialogInfoHt("commentTable");
   versionTable := _GetDialogInfoHt("versionTable");
   pPromptToRefresh := _GetDialogInfoHt("pPromptToRefresh");
   pRefreshZipFile := _GetDialogInfoHt("pRefreshZipFile");

   ctltree1.getFileListFromTree(auto relFileList);
   ShelfFileInfo fileList[];
   pshelf->commentArray = commentTable:[PATHSEP];

   len := relFileList._length();
   for (i:=0;i<len;++i) {
      ShelfFileInfo cur;
      cur.filename = relFileList[i];
      cur.commentArray = commentTable:[_file_case(cur.filename)];
      fileList :+= cur;
   }
   pshelf->fileList = fileList;
   if ( pPromptToRefresh!=null && pRefreshZipFile!=null && *pPromptToRefresh==true ) {
      result := _message_box(nls("Refresh source files?"),"",MB_YESNO);
      *pRefreshZipFile = (result==IDYES);
   }
   p_active_form._delete_window(0);
}

void ctladd.lbutton_up()
{
   ShelfInfo *pshelf = _GetDialogInfoHt("pshelf");
   manifestFilename := _GetDialogInfoHt("manifestFilename");
   versionTable := _GetDialogInfoHt("versionTable");
   pathTable := _GetDialogInfoHt("pathTable");
   _control ctlrootPathLabel;

   // SHOW OPEN DIALOG, LET USER PICK FILE. ADD TO VERSION TABLE, 
   // ADD TO TREE, ETC
   result := _OpenDialog('-modal',
                         'Select file to add',// Dialog Box Title
                         '',                  // Initial Wild Cards
                         '',
                         OFN_FILEMUSTEXIST);
   if ( result=="" ) {
      return;
   }
   filename := strip(result,'B','"');

   zipFilename := p_active_form.p_caption;
   status := svcAddControlledFileToShelf(zipFilename,filename);
   if ( !status ) {
      origWID := p_window_id;
      p_window_id = ctltree1;
      childIndex := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      if (childIndex>0) {
         pathTable:[_TreeGetCaption(childIndex)] = childIndex;
      }
      index := _SVCGetPathIndex(_file_path(filename),stranslate(pshelf->localRoot,FILESEP,'/'),pathTable);
      if ( index > 0 ) {
         _TreeAddItem(index,_strip_filename(filename,'P'),TREE_ADD_AS_CHILD,_pic_file,_pic_file,-1);
      }
      p_window_id = origWID;
   }
}

static void getFileListFromTree(STRARRAY &relativeFileList,int index = TREE_ROOT_INDEX,_str path="")
{
   index = _TreeGetFirstChildIndex(index);
   for (;;) {
      if ( index<0 ) break;
      _TreeGetInfo(index,auto state,auto bm1,auto bm2);
      cap := _TreeGetCaption(index);
      if ( bm1==_pic_file ) {
         if (_TreeGetParentIndex(index)==TREE_ROOT_INDEX) {
            relativeFileList :+= path:+cap;
         } else {
            relativeFileList :+= _TreeGetCaption(_TreeGetParentIndex(index)):+path:+cap;
         }
      }
      index = _TreeGetNextIndex(index);
   }
}

void ctltree1.on_change(int reason,int index)
{
   inOnChange := _GetDialogInfoHt("inOnChange");
   if ( inOnChange==1 ) return;
   _SetDialogInfoHt("inOnChange",1);

   switch ( reason ) {
   case CHANGE_SELECTED:
      _TreeGetInfo(index,auto state,auto bm1);
      if ( bm1 != _pic_file ) {
         ctledit2.p_enabled = ctledit1.p_prev.p_enabled = false;
         _SetDialogInfoHt("lastSelected",index);

         commentTable := _GetDialogInfoHt("commentTable");
         STRARRAY commentArray;
         ctledit1.getCommentFromEditor(commentArray);
         commentTable:[PATHSEP] = commentArray;
         _SetDialogInfoHt("commentTable",commentTable);

      } else {
         ctledit2.p_enabled = ctledit1.p_prev.p_enabled = true;
         commentTable := _GetDialogInfoHt("commentTable");
         lastIndex := _GetDialogInfoHt("lastSelected");
         if ( lastIndex!=null ) {
            lastWholePath := _TreeGetUserInfo(lastIndex);

            STRARRAY commentArray;
            ctledit1.getCommentFromEditor(commentArray);
            commentTable:[PATHSEP] = commentArray;

            commentArray = null;

            ctledit2.getCommentFromEditor(commentArray);
            commentTable:[lastWholePath] = commentArray;
            _SetDialogInfoHt("commentTable",commentTable);
         }
         wholePath := _TreeGetUserInfo(index);
         wid := p_window_id;
         ctledit1.fillInEditor(commentTable:[PATHSEP]);
         ctledit2.fillInEditor(commentTable:[wholePath]);
         p_window_id = wid;
         _SetDialogInfoHt("lastSelected",index);
      }
   }
   _SetDialogInfoHt("inOnChange",0);
}

static void getCommentFromEditor(STRARRAY &commentArray)
{
   top();up();
   while (!down()) {
      get_line(auto curLine);
      commentArray :+= curLine;
   }
}

static void fillInEditor(STRARRAY &commentArray)
{
   _lbclear();
   len := commentArray._length();
   for (i:=0;i<len;++i) {
      insert_line(commentArray[i]);
   }
}

void _svc_shelf_form.on_resize()
{
   clientWidth  := _dx2lx(SM_TWIP,p_active_form.p_client_width);
   clientHeight := _dy2ly(SM_TWIP,p_active_form.p_client_height);
   xbuffer := ctlrootPathLabel.p_x;
   ybuffer := ctlrootPathLabel.p_y;

   treeWidth := (clientWidth intdiv 3) - xbuffer;
   ctltree1.p_width = treeWidth;

   treeHeight := clientHeight - (ctlrootPathLabel.p_height+ctlclose.p_height+(4*ybuffer));
   ctltree1.p_height = treeHeight;
   ctlok.p_y = ctladd.p_y = ctlclose.p_y = ctltree1.p_y_extent+ybuffer;

   editorHeight := (ctltree1.p_height - ctledit2.p_prev.p_height) intdiv 2;
   ctledit1.p_height = editorHeight;
   ctledit2.p_prev.p_y = ctledit1.p_y_extent+ybuffer;
   ctledit2.p_y = ctledit2.p_prev.p_y_extent+ybuffer;
   ctledit2.p_height = editorHeight-ybuffer;

   editX := ctltree1.p_x_extent + xbuffer;
   ctledit1.p_x = ctledit1.p_prev.p_x = ctledit2.p_x = ctledit2.p_prev.p_x = editX;

   ctledit1.p_width = ctledit2.p_width = clientWidth - (treeWidth+(3*xbuffer));

   ShelfInfo *pshelf = _GetDialogInfoHt("pshelf");
   ctlrootPathLabel.p_caption = ROOT_PATH_CAPTION:+ctlrootPathLabel._ShrinkFilename(pshelf->localRoot,treeWidth-ctlrootPathLabel._text_width("Root path:"));
}

static int svcUnshelve(_str manifestFilename,_str unhelveRootDir)
{
   xmlhandle := _xmlcfg_open(manifestFilename,auto status,VSXMLCFG_OPEN_ADD_PCDATA);
   if ( xmlhandle<0 ) {
      return status;
   }
   _xmlcfg_close(xmlhandle);
   return 0;
}

STRARRAY def_svc_all_shelves = null;
_str def_svc_user_shelves;

// Set to true if we loaded the shelves and there were none.
static bool  gNoShelves = false;

void svcEnumerateShelves(bool loadFromDisk=false)
{
   // If the user specified load from disk or we have no shelves loaded, go 
   // look for them.
   if ( loadFromDisk || (def_svc_all_shelves==null && !gNoShelves) ) {
      def_svc_all_shelves = null;
      gNoShelves = false;
      shelfBasePath := getShelfBasePath();
      for (ff:=1;;ff=0) {
         shelf := file_match(_maybe_quote_filename(shelfBasePath'*.zip'),ff);
         if ( shelf=="" ) {
            break;
         }
         curManifestFilename := shelf:+FILESEP:+"manifest.xml";
         def_svc_all_shelves :+= shelf;
      }

      userShelfList := def_svc_user_shelves;
      for (;;) {
         curShelf := parse_file(userShelfList);
         if ( curShelf=="" ) break;
         if ( file_exists(curShelf) ) {
            def_svc_all_shelves :+= curShelf;
         }
      }

      if ( def_svc_all_shelves._length()==0 ) gNoShelves = true;
   }
   _config_modify_flags(CFGMODIFY_DEFVAR);
}

_command void svc_list_shelves() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return;
   }
   if ( def_svc_all_shelves._length()==0 ) {
      svcEnumerateShelves();
   }
   show('-modal _svc_shelf_list_form');
}


_command void svc_open_shelf(_str shelfPath="") name_info(FILENEW_ARG','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return;
   }

   result := "";
   if (file_exists(shelfPath) && get_extension(shelfPath) == "zip") {
      result = shelfPath;
   } else {
      result = _OpenDialog('-modal',
                           'Select shelf file to open',// Dialog Box Title
                           '*.zip',                    // Initial Wild Cards
                           'Zip Files (*.zip)',
                           OFN_FILEMUSTEXIST,
                           "", "", shelfPath);
   }
   if ( result=="" ) {
      return;
   }
   zipFilename := strip(result,'B','"');
   status := _open_temp_view(zipFilename"/manifest.xml",auto tempWID,auto origWID);
   if ( status ) {
      _message_box("This is not a valid shelf file");
      return;
   }
   p_window_id = origWID;
   _delete_temp_view(tempWID);

   loadShelf(zipFilename,auto shelf);
#if 0 //11:19am 8/2/2019
   if ( lowcase(shelf.VCSystemName)!=lowcase(svc_get_vc_system()) ) {
      _message_box(nls("You cannot unshelve this because it was shelved from '%s' and the current version control system is '%s'",shelf.VCSystemName,svc_get_vc_system()));
      return;
   }
#endif

   // compose prompt for directory to unshelf to
   unshelf_prompt := nls("Do you wish to unshelve to this directory?");
   localRoot := origLocalRoot := shelf.localRoot;
   if ( !path_exists(localRoot) ) {

      // Check to see if there is a version control system, this could be from
      // a multi-file diff
      if ( shelf.VCSystemName != "" ) {
         pInterface := svcGetInterface(shelf.VCSystemName);
         if ( pInterface!=null ) {
            localRoot = pInterface->localRootPath();
         }
      }

      if ( localRoot=="" || localRoot==origLocalRoot ) {
         unshelf_prompt = nls("Local root '%s' does not exist<br>You must unshelve to a different directory",shelf.localRoot);
      } else {
         // Change this so we don't get more bad roots
         _SetDialogInfoHt("localRoot",localRoot);
      }
   }

   // retrieve new directory name
   result = textBoxDialog(nls("Unshelve Files To:"),
                          0,      // flags,
                          0,      // textbox width
                          "",     // help item
                          "OK,Cancel:_cancel\t-html "unshelf_prompt,
                          "",     // retrieve name
                          "-bd Directory:"localRoot);  // prompt
   if (result==COMMAND_CANCELLED_RC) return;
   shelf.localRoot = strip(_param1,'B','"');
   _maybe_append_filesep(shelf.localRoot);

   show('-modal _svc_unshelve_form',shelf,zipFilename);
}

static _str getFileStatusString(int curFileStatus)
{
   fileStatusString := "";
   if (curFileStatus&SVC_STATUS_SCHEDULED_FOR_ADDITION) {
      fileStatusString = "added for addition";
   }
   if (curFileStatus&SVC_STATUS_SCHEDULED_FOR_DELETION) {
      if ( fileStatusString!="" ) fileStatusString :+= " and is ";
      fileStatusString :+= "scheduled for addition";
   }
   if (curFileStatus&SVC_STATUS_MODIFIED) {
      if ( fileStatusString!="" ) fileStatusString :+= " and is ";
      fileStatusString :+= "locally modified";
   }
   if (curFileStatus&SVC_STATUS_CONFLICT) {
      if ( fileStatusString!="" ) fileStatusString :+= " and is ";
      fileStatusString :+= "in conflict";
   }
   if (curFileStatus&SVC_STATUS_IGNORED) {
      if ( fileStatusString!="" ) fileStatusString :+= " and is ";
      fileStatusString :+= "ignored";
   }
   if (curFileStatus&SVC_STATUS_MISSING) {
      if ( fileStatusString!="" ) fileStatusString :+= " and is ";
      fileStatusString :+= "missing";
   }
   if (curFileStatus&SVC_STATUS_NEWER_REVISION_EXISTS) {
      if ( fileStatusString!="" ) fileStatusString :+= " and is ";
      fileStatusString :+= "out of date";
   }
   if (curFileStatus&SVC_STATUS_TREE_ADD_CONFLICT) {
      if ( fileStatusString!="" ) fileStatusString :+= " and is ";
      fileStatusString :+= "in tree conflict";
   }
   if (curFileStatus&SVC_STATUS_TREE_DEL_CONFLICT) {
      if ( fileStatusString!="" ) fileStatusString :+= " and is ";
      fileStatusString :+= "in delete conflict";
   }
   if (curFileStatus&SVC_STATUS_DELETED) {
      if ( fileStatusString!="" ) fileStatusString :+= " and is ";
      fileStatusString :+= "deleted";
   }
   if (curFileStatus&SVC_STATUS_UNMERGED) {
      if ( fileStatusString!="" ) fileStatusString :+= " and is ";
      fileStatusString :+= "unmerged";
   }
   return fileStatusString;
}

static int loadShelf(_str zipFilename,ShelfInfo &shelf)
{
   manifestFilename := zipFilename:+FILESEP:+"manifest.xml";
   xmlhandle := _xmlcfg_open(manifestFilename,auto status,VSXMLCFG_OPEN_ADD_PCDATA);
   if ( xmlhandle<0 ) return status;
   index := _xmlcfg_find_simple(xmlhandle,"/Shelf");
   if ( index>=0 ) {
      shelf.shelfName = _xmlcfg_get_attribute(xmlhandle,index,"Name");
      shelf.localRoot = _xmlcfg_get_attribute(xmlhandle,index,"LocalRoot");
      shelf.VCSystemName = _xmlcfg_get_attribute(xmlhandle,index,"VCSystemName");
      shelf.localRoot = stranslate(shelf.localRoot, FILESEP, FILESEP2);

      // Get and save the comment for the shelf itself
      commentNode := _xmlcfg_get_first_child(xmlhandle,index);
      getComment(xmlhandle,commentNode,shelf.commentArray);
   }
   _xmlcfg_find_simple_array(xmlhandle,"/Shelf/Files/File",auto indexArray);


   baseDir := _file_path(manifestFilename):+"base":+FILESEP;
   modsDir := _file_path(manifestFilename):+"mods":+FILESEP;
   len := indexArray._length();
   for (i:=0;i<len;++i) {
      ShelfFileInfo temp;
      temp.filename = _xmlcfg_get_attribute(xmlhandle,(int)indexArray[i],"N");
      temp.revision = _xmlcfg_get_attribute(xmlhandle,(int)indexArray[i],"V");
      temp.baseFile = baseDir:+temp.filename;
      temp.modFile  = modsDir:+temp.filename;
      temp.filename = stranslate(temp.filename, FILESEP, FILESEP2);

      // Get and save the comment for each file
      commentNode := _xmlcfg_get_first_child(xmlhandle,(int)indexArray[i]);
      getComment(xmlhandle,commentNode,temp.commentArray);
      shelf.fileList :+= temp;
   }
   _xmlcfg_close(xmlhandle);

   return status;
}

static void getComment(int xmlhandle,int nodeIndex,STRARRAY &commentArray)
{
   if ( nodeIndex>=0 ) {
      comment := strip(_xmlcfg_get_value(xmlhandle,nodeIndex));
      for (;;) {
         parse comment with auto cur "\n" comment;
         if ( cur=="" ) break;
         if ( cur!="\r" ) {
            commentArray :+= strip(cur);
         }
      }
   }
}

static _str getShelfTitle(_str manifestFilename)
{
   status := _open_temp_view(manifestFilename,auto manifestWID,auto origWID);
   xmlhandle := _xmlcfg_open_from_buffer(manifestWID,status,VSXMLCFG_OPEN_ADD_PCDATA);
   nodeIndex := _xmlcfg_get_first_child(xmlhandle,TREE_ROOT_INDEX);
   shelfTitle := "";
   if (nodeIndex>=0) {
      shelfTitle = _xmlcfg_get_attribute(xmlhandle,nodeIndex,"Name");
   }
   _xmlcfg_close(xmlhandle);
   return shelfTitle;
}

static _str getShelfLocalRoot(_str manifestFilename)
{
   xmlhandle := _xmlcfg_open(manifestFilename,auto status,VSXMLCFG_OPEN_ADD_PCDATA);
   nodeIndex := _xmlcfg_get_first_child(xmlhandle,TREE_ROOT_INDEX);
   shelfRoot := "";
   if (nodeIndex>=0) {
      shelfRoot = _xmlcfg_get_attribute(xmlhandle,nodeIndex,"LocalRoot");
      shelfRoot = stranslate(shelfRoot, FILESEP, FILESEP2);
   }
   _xmlcfg_close(xmlhandle);
   return shelfRoot;
}

defeventtab _svc_unshelve_form;

void ctlclose.on_create(ShelfInfo shelf=null,_str zipFilename="")
{
   if ( shelf==null ) return;
   IVersionControl *pInterface = svcGetInterface(svc_get_vc_system());
   if ( pInterface==null ) return;

   _SetDialogInfoHt("shelf",shelf);
   p_active_form.p_caption = "Unshelve ":+shelf.shelfName;

   // Initially, we will assume we are unshelving back where we shelved from
   _SetDialogInfoHt("localRoot",stranslate(shelf.localRoot,FILESEP,'/'));
   _SetDialogInfoHt("zipFilename",zipFilename);
   setLocalRootCaption();
   addUnshelveFilesToTree();
   ctlresolve.p_enabled = false;
   ctlunshelve.p_enabled = false;
   checkForConflicts();
}

void ctlclose.on_destroy()
{
   STRHASHTAB fileTab = _GetDialogInfoHt("fileTab");
   foreach (auto curTempFile => auto curFile in fileTab) {
      if ( substr(curFile,1,1)=='>' ) {
         delete_file(substr(curFile,2));
      }
   }
}

static void addUnshelveFilesToTree()
{
   localRoot := _GetDialogInfoHt("localRoot");
   ShelfInfo shelf = _GetDialogInfoHt("shelf");

   IVersionControl *pInterface = svcGetInterface(svc_get_vc_system());
   if ( pInterface==null ) return;
   origWID := p_window_id;
   p_window_id = ctltree1;

   _TreeDelete(TREE_ROOT_INDEX,'C');
   int pathIndexes:[]=null;
   rootPathIndex := _TreeAddItem(TREE_ROOT_INDEX,localRoot,TREE_ADD_AS_CHILD,_pic_fldopen,_pic_fldopen);
   _SVCSeedPathIndexes(localRoot,pathIndexes,rootPathIndex);
   len := shelf.fileList._length();
   numFiles := 0;
   for (i:=0;i<len;++i) {
      curFile := shelf.fileList[i];

      curFile.filename = stranslate(curFile.filename,FILESEP,'/');
      curFile.baseFile = stranslate(curFile.baseFile,FILESEP,'/');
      curFile.modFile = stranslate(curFile.modFile,FILESEP,'/');

      curFilename := localRoot:+curFile.filename;
      // Check to see if the file is absolute
      if ( substr(curFile.filename,2,1)==':' ||  substr(curFile.filename,1,1)=='/') {
         curFilename = curFile.filename;
      }
      curPath     := _file_path(curFilename);
      pathIndex := _SVCGetPathIndex(curPath,"",pathIndexes,_pic_fldopen,_pic_fldopen,FILESEP,1,0);
      nodeIndex := _TreeAddItem(pathIndex,_strip_filename(curFilename,'P'),TREE_ADD_AS_CHILD,_pic_file,_pic_file,TREE_NODE_COLLAPSED);
      ++numFiles;

      _SetDialogInfoHt("baseFilename:"nodeIndex,curFile.baseFile);

      _SetDialogInfoHt("modsFilename:"nodeIndex,curFile.modFile);

      _SetDialogInfoHt("curFilename:"nodeIndex,curFilename);

      if ( curFile.revision!="" ) {
         _TreeAddItem(nodeIndex,_strip_filename(curFilename,'P')' (base - clean version 'curFile.revision' from shelf)',TREE_ADD_AS_CHILD,_pic_file,_pic_file,TREE_NODE_LEAF,0,curFile.baseFile);
         _TreeAddItem(nodeIndex,_strip_filename(curFilename,'P')' (rev1 - modified version 'curFile.revision' from shelf)',TREE_ADD_AS_CHILD,_pic_file,_pic_file,TREE_NODE_LEAF,0,curFile.modFile);
         _TreeAddItem(nodeIndex,_strip_filename(curFilename,'P')' (rev2 - local file in '_strip_filename(curFilename,'N')')',TREE_ADD_AS_CHILD,_pic_file,_pic_file,TREE_NODE_LEAF,0,curFile.revision);
      } else {
         if ( file_exists(curFilename) ) {
            _TreeAddItem(nodeIndex,_strip_filename(curFilename,'P')' (local version 'curFile.revision')',TREE_ADD_AS_CHILD,_pic_file,_pic_file,TREE_NODE_LEAF,0,curFilename);
            _TreeAddItem(nodeIndex,_strip_filename(curFilename,'P')' (shelved version 'curFile.revision')',TREE_ADD_AS_CHILD,_pic_file,_pic_file,TREE_NODE_LEAF,0,curFile.modFile);
         } else {
            index := _TreeAddItem(nodeIndex,_strip_filename(curFilename,'P')' (shelved version 'curFile.revision')',TREE_ADD_AS_CHILD,_pic_file,_pic_file,TREE_NODE_LEAF,0,curFile.modFile);
         }
      }
   }
   _SetDialogInfoHt("numFiles",numFiles);
   _SetDialogInfoHt("resolvedFiles",0);
   p_window_id = origWID;
}

void _svc_unshelve_form.on_resize()
{
   labelWID := ctltree1.p_prev;
   clientWidth  := _dx2lx(SM_TWIP,p_active_form.p_client_width);
   clientHeight := _dy2ly(SM_TWIP,p_active_form.p_client_height);
   xbuffer := ctlLocalRoot.p_x;
   ybuffer := ctlLocalRoot.p_y;

   ctltree1.p_width = clientWidth - (2*xbuffer);
   ctltree1.p_y = labelWID.p_y_extent+ybuffer;
   ctltree1.p_height = clientHeight - (ctlcheckForConflicts.p_height+ctltree1.p_y+(3*ybuffer));
   ctlhelp.p_y = ctlunshelve.p_y = ctlclose.p_y = ctlcheckForConflicts.p_y = ctlresolve.p_y = ctltree1.p_y_extent + ybuffer;

   buttonBuffer := ctlcheckForConflicts.p_x-ctlclose.p_x_extent;

//   ctlresolve.p_x = ctlcheckForConflicts._ControlExtentX()+buttonBuffer;
//   ctlunshelve.p_x = ctlresolve._ControlExtentX()+buttonBuffer;

   // For the local root label, set the width, but call a function to set 
   // the caption.  We have to do this because setLocalRootCaption() calls 
   // _ShrinkFilename based on the current width
   ctlLocalRoot.p_width = ctltree1.p_width - (ctlbrowse.p_width+xbuffer);
   setLocalRootCaption();
}

static void setLocalRootCaption()
{
   xbuffer := ctlLocalRoot.p_x;
   localRoot := _GetDialogInfoHt("localRoot");
   localRootWidth := ctlLocalRoot.p_width-ctlLocalRoot._text_width(UNSHELVE_PATH_CAPTION);
   ctlLocalRoot.p_caption = UNSHELVE_PATH_CAPTION:+ctlLocalRoot._ShrinkFilename(localRoot,localRootWidth);

   ctlbrowse.resizeToolButton(ctlLocalRoot.p_height);
   ctlbrowse.p_y = ctlLocalRoot.p_y;
   ctlbrowse.p_x = ctlLocalRoot.p_x_extent + xbuffer;
}                           
                           
void ctlbrowse.lbutton_up()
{
   _str localRoot = _GetDialogInfoHt("localRoot");
   _str result = _ChooseDirDialog("Directory to Unshelve to",localRoot);
   if ( result=='' ) return;

   localRoot = result;
   _SetDialogInfoHt("localRoot",localRoot);
   setLocalRootCaption();
   addUnshelveFilesToTree();

   // If we change the unshelve location, we have to start over with checking
   // for and resolving of conflicts
   ctlcheckForConflicts.p_enabled = true;
   ctlresolve.p_enabled = false;
   ctlunshelve.p_enabled = false;
   checkForConflicts();
}

void ctltree1.on_change(int reason,int index)
{
   switch ( reason ) {
   case CHANGE_CHECK_TOGGLED:
      checked := _TreeGetCheckState(index);
      if ( !checked ) {
         decrementResolved();
      } else if ( checked==1 ) {
         incrementResolved();
      }
      break;
   }
}

static int getConflictList(STRARRAY &conflictFileList,int gaugeFormWID, STRHASHTAB &newFileTable)
{
   status := ctltree1.getConflictListFromTree(ctltree1._TreeGetFirstChildIndex(TREE_ROOT_INDEX),conflictFileList,gaugeFormWID, newFileTable);
   return status;
}

static int getConflictListFromTree(int index,STRARRAY &conflictFileList,int gaugeFormWID,STRHASHTAB &newFileTable)
{
   status := 0;
   ShelfInfo shelf = _GetDialogInfoHt("shelf");
   for (;;) {
      if (index<0) break;
      fileIsNew := false;
      _TreeGetInfo(index,auto state,auto bm1,auto bm2);
      childIndex := _TreeGetFirstChildIndex(index);
      cap := _TreeGetCaption(index);

      if ( bm1==_pic_fldopen ) {
         status = getConflictListFromTree(childIndex,conflictFileList,gaugeFormWID,newFileTable);
         if ( status ) return status;
      } else if ( bm1==_pic_file ) {
         baseFilename := "";
         rev1Filename := "";
         rev2Revision := "";

         baseFilename = _TreeGetUserInfo(childIndex);
         rev1Index := _TreeGetNextSiblingIndex(childIndex);
         if ( rev1Index>0 ) {
            rev1Filename = _TreeGetUserInfo(rev1Index);
            rev2Index := _TreeGetNextSiblingIndex(rev1Index);
            if ( rev2Index>0 ) {
               rev2Revision = _TreeGetUserInfo(rev2Index);
            }
         }
         localFilename := _TreeGetCaption(_TreeGetParentIndex(index)):+cap;
         // Look to see if any merges are happening at all
         if ( rev1Filename=="" && rev2Revision=="" ) {
            // Just the single file, no conflicts to have
         } else if (rev2Revision=="" && shelf.VCSystemName!="") {
            gaugeFormWID._DiffSetProgressMessage("Checking for conflicts",baseFilename,"");
            status = have2WayConflict(baseFilename,rev1Filename,auto conflict=false);
            if ( status || conflict ) {
               conflictFileList :+= localFilename;
            }
         } else {
            gaugeFormWID._DiffSetProgressMessage("Checking for conflicts",localFilename,"");
            status = have3WayConflict(baseFilename,rev1Filename,rev2Revision,localFilename,auto conflict=false,fileIsNew);
            if ( status || conflict ) {
               if ( !fileIsNew || conflict ) {
                  conflictFileList :+= localFilename;
               } else if ( fileIsNew ) {
                  newFileTable:[_file_case(localFilename)] = localFilename;
                  status = 0;
               }
            }
         }
         progress_increment(gaugeFormWID);
         _nocheck _control gauge1,label1,label2;
         gaugeFormWID.label1.refresh();
         gaugeFormWID.label2.refresh();
         orig_wid:=p_window_id;
         process_events(auto cancel=false);
         p_window_id=orig_wid;
         if ( status ) break;
      }
      index = _TreeGetNextSiblingIndex(index);
   }
   return status;
}

static void checkItemsNotInConflict(STRARRAY &conflictFileList,STRHASHTAB &newFileTable)
{
   checkItemsNotInConflictInTree(_TreeGetFirstChildIndex(TREE_ROOT_INDEX),conflictFileList,newFileTable);
}

static void checkItemsNotInConflictInTree(int index,STRARRAY &conflictFileList,STRHASHTAB &newFileTable)
{
   STRHASHTAB conflictFileTable;
   len := conflictFileList._length();
   for (i:=0;i<len;++i) {
      conflictFileTable:[_file_case(conflictFileList[i])] = "";
   }
   for (;;) {
      if (index<0) break;
      _TreeGetInfo(index,auto state,auto bm1,auto bm2,auto nodeFlags);
      childIndex := _TreeGetFirstChildIndex(index);
      cap := _TreeGetCaption(index);

      if ( bm1==_pic_fldopen ) {
         checkItemsNotInConflictInTree(childIndex,conflictFileList,newFileTable);
      } else if ( bm1==_pic_file ) {

         localFilename := _TreeGetCaption(_TreeGetParentIndex(index)):+cap;
         if ( !conflictFileTable._indexin(_file_case(localFilename)) &&
              !newFileTable._indexin(_file_case(localFilename)) ) {
            // There were no conflicts
            _TreeSetCheckState(index,1,0);
            _TreeSetCheckable(index,0,0);
            _TreeSetInfo(index,TREE_NODE_COLLAPSED,bm1,bm2,nodeFlags&~TREENODE_FORCECOLOR);
         } else {
            _TreeSetInfo(index,TREE_NODE_EXPANDED,bm1,bm2,nodeFlags|TREENODE_FORCECOLOR);
         }

      }
      index = _TreeGetNextSiblingIndex(index);
   }
}

static int have2WayConflict(_str localFilename,_str modFilename,bool &conflict)
{
   status := _open_temp_view(localFilename,auto localWID,auto origWID);
   if (status) return status;

   status = _open_temp_view(modFilename,auto modWID,auto origWID2);
   if (status) return status;

   conflict = FastBinaryCompare(localWID,0,modWID,0) != 0;

   _delete_temp_view(localWID);
   _delete_temp_view(modWID);
   p_window_id = origWID;
   return status;
}

static int have3WayConflict(_str baseFilename,_str rev1Filename,_str rev2Revision,_str localFilename,bool &conflict,bool &fileIsNew)
{
   fileIsNew = false;
   IVersionControl *pInterface = svcGetInterface(svc_get_vc_system());
   if ( pInterface==null ) {
      _message_box(get_message(VSRC_SVC_COULD_NOT_GET_VC_INTERFACE_RC,svc_get_vc_system()));
      return VSRC_SVC_COULD_NOT_GET_VC_INTERFACE_RC;
   }
   baseWID := 0;
   rev1WID := 0;
   rev2WID := 0;
   origWID := 0;
   status  := 0;
   do {
      baseFilename = stranslate(baseFilename,'/::/','//');
      status = _open_temp_view(baseFilename,baseWID,origWID);
      if ( status ) break;

      rev1Filename = stranslate(rev1Filename,'/::/','//');
      status = _open_temp_view(rev1Filename,rev1WID,auto origWID2);
      if ( status ) break;

//      status = pInterface->enumerateVersions(localFilename,auto versions);
//      if ( status ) break;

//      status = pInterface->getFile(localFilename,versions[versions._length()-1],rev2WID);
      status = _open_temp_view(localFilename,rev2WID,auto origWID3);
      if ( status ) {
         if ( status!=FILE_NOT_FOUND_RC ) break;
         fileIsNew = true;
         // Nothing to compare to, can't have a conflict
         break;
      }

      // if the base and local file match, then we can not have conflicts.
      if (!fileIsNew && FastBinaryCompare(baseWID,0,rev2WID,0) == 0) {
         conflict=false;
         break;
      }

      if ( !fileIsNew ) {
         conflict = conflictExists(baseWID,rev1WID,rev2WID)!=0;
      }
   } while (false);
   if ( baseWID ) _delete_temp_view(baseWID);
   if ( rev1WID ) _delete_temp_view(rev1WID);
   if ( rev2WID ) _delete_temp_view(rev2WID);
   if ( origWID ) p_window_id = origWID;
   return status;
}

void checkForConflicts()
{
   IVersionControl *pInterface = svcGetInterface(svc_get_vc_system());
   if ( pInterface==null ) {
      _message_box(get_message(VSRC_SVC_COULD_NOT_GET_VC_INTERFACE_RC,svc_get_vc_system()));
      return;
   }
   localRoot := _GetDialogInfoHt("localRoot");
   if ( !path_exists(localRoot) ) {
      _message_box(nls("Local root '%s' does not exist\n\nYou must unshelve to a different directory",localRoot));
      p_active_form.p_visible = true;
      ctlbrowse.call_event(ctlbrowse,LBUTTON_UP);
      return;
   }

   ShelfInfo shelf = _GetDialogInfoHt("shelf");
   numfiles := shelf.fileList._length();
   gaugeFormWID := show('-mdi _difftree_progress_form');
   progress_set_min_max(gaugeFormWID,0,numfiles*2);
   _nocheck _control gauge1;
   gaugeFormWID.refresh();
   SVCDisplayOutput(nls("Checking for conflicts in %s",localRoot),true);
   status := getConflictList(auto conflictFileList,gaugeFormWID,auto newFileTable);
   activeFormVisible := p_active_form.p_visible;
   if ( !status ) {
      len := conflictFileList._length();
      ctltree1.checkItemsNotInConflict(conflictFileList,newFileTable);
      if ( conflictFileList._length()!=0 ) {
         ctlresolve.p_enabled = true;
         activeFormVisible = true;
      }
   } else {
      _message_box(nls("You must resolve version control errors before continuing."));
      gaugeFormWID._delete_window();
      return;
   }
   progress_set_min_max(gaugeFormWID,0,(numfiles*2)-conflictFileList._length());
   ctltree1.mergeCheckedItems(auto mergedFileList,gaugeFormWID,newFileTable);
   p_active_form.p_visible = activeFormVisible;
   ctlcheckForConflicts.p_enabled = false;
   gaugeFormWID._delete_window();

   if ( ctlresolve.p_enabled ) {
      ctlresolve.p_default = true;
   } else {
      ctlunshelve.p_default = true;
      ctlunshelve.call_event(ctlunshelve,LBUTTON_UP);
   }
}

void ctlcheckForConflicts.lbutton_up()
{
   checkForConflicts();
}

static int mergeCheckedItems(STRARRAY &mergedFileList,int gaugeFormWID,STRHASHTAB &newFileTable)
{
   gaugeFormWID._DiffSetProgressMessage("Merging files","","");
   status := mergeCheckedItemsInTree(_TreeGetFirstChildIndex(TREE_ROOT_INDEX),mergedFileList,gaugeFormWID,newFileTable:newFileTable);
   return status;
}

static int mergeCheckedItemsInTree(int index,STRARRAY &mergedFileList,int gaugeFormWID,int curNum=0,STRHASHTAB &newFileTable=null)
{
   IVersionControl *pInterface = svcGetInterface(svc_get_vc_system());
   if ( pInterface==null ) {
      _message_box(get_message(VSRC_SVC_COULD_NOT_GET_VC_INTERFACE_RC,svc_get_vc_system()));
      return VSRC_SVC_COULD_NOT_GET_VC_INTERFACE_RC;
   }

   STRHASHTAB conflictFileTable;
   status := 0;
   for (i:=curNum;;++i) {
      if (index<0) break;
      if ( progress_cancelled() ) return COMMAND_CANCELLED_RC;

      _TreeGetInfo(index,auto state,auto bm1,auto bm2,auto nodeFlags);
      childIndex := _TreeGetFirstChildIndex(index);
      cap := _TreeGetCaption(index);

      if ( bm1==_pic_fldopen ) {
         status = mergeCheckedItemsInTree(childIndex,mergedFileList,gaugeFormWID,curNum,newFileTable);
         if ( status ) return status;
      } else if ( bm1==_pic_file ) {
         baseFilename := "";
         rev1Filename := "";
         rev2Revision := "";

         _nocheck _control gauge1;
         gaugeFormWID.refresh();
         baseFilename = _TreeGetUserInfo(childIndex);
         rev1Index := _TreeGetNextSiblingIndex(childIndex);
         if ( rev1Index>0 ) {
            rev1Filename = _TreeGetUserInfo(rev1Index);
            rev2Index := _TreeGetNextSiblingIndex(rev1Index);
            if ( rev2Index>0 ) {
               rev2Revision = _TreeGetUserInfo(rev2Index);
            }
         }

         parentIndex := _TreeGetParentIndex(index);
         localFilename := _TreeGetCaption(parentIndex):+cap;
         _nocheck _control gauge1,label1,label2;
         gaugeFormWID._DiffSetProgressMessage("Checking for conflicts",localFilename,"");
         gaugeFormWID.label1.refresh();
         gaugeFormWID.label2.refresh();
         gaugeFormWID.refresh();

         checked := _TreeGetCheckState(index,0);
         if ( checked ) {
            STRHASHTAB fileTab = _GetDialogInfoHt("fileTab");
            if ( rev2Revision=="" || (rev2Revision=="mfdiff" && !file_exists(localFilename)) ) {
               // Just the single file, no conflicts to have
               SVCDisplayOutput(nls("New file: %s",localFilename));
               fileTab:[_file_case(localFilename)] = baseFilename;
               incrementResolved();
            } else {
               // Merge files.  Base is the clean file in the shelf, rev1 is the mod 
               // version from the shelf, rev2 is the current version of the file on
               // disk. Output is a temp file.  We will copy the temp file over when 
               // the user clicks the "unshelve" button
               //
               // If the base and the local file name match exactly, we can just
               // mark this one to be copied in, there is no merge operation required.

               if (FastRawFileCompare(localFilename, baseFilename) == 0) {
                  SVCDisplayOutput(nls("Copying file: %s",rev1Filename));

                  baseFilename = stranslate(baseFilename,'/::/','//');
                  rev1Filename = stranslate(rev1Filename,'/::/','//');
                  fileTab:[_file_case(localFilename)] = '>'rev1Filename;
                  incrementResolved();

               } else {

                  tempOutput := mktemp();
                  createBlankFile(tempOutput);

                  SVCDisplayOutput(nls("Merging file: %s to %s",localFilename,tempOutput));

                  rev2WID := 0;
                  //status = pInterface->enumerateVersions(localFilename,auto versions);
                  //if ( status ) break;
                  
                  baseFilename = stranslate(baseFilename,'/::/','//');
                  rev1Filename = stranslate(rev1Filename,'/::/','//');
                  status = merge('-smart -saveoutput -noeditoutput -quiet -noeol '_maybe_quote_filename(baseFilename)' '_maybe_quote_filename(rev1Filename)' 'localFilename' '_maybe_quote_filename(tempOutput));
                  p_window_id = ctltree1;

                  fileTab:[_file_case(localFilename)] = '>'tempOutput;
                  incrementResolved();
               }
            }
            progress_increment(gaugeFormWID);
            orig_wid:=p_window_id;
            process_events(auto cancel=false);
            p_window_id=orig_wid; // restore tree wid if it got changed.
            _SetDialogInfoHt("fileTab",fileTab);
         }
         if ( status ) break;
      }
      index = _TreeGetNextSiblingIndex(index);
   }

   return status;
}

static void incrementResolved()
{
   resolvedFiles := _GetDialogInfoHt("resolvedFiles");
   if ( resolvedFiles==null ) resolvedFiles = 0;
   ++resolvedFiles;

   numFiles := _GetDialogInfoHt("numFiles");
   _SetDialogInfoHt("resolvedFiles",resolvedFiles);

   if ( resolvedFiles >= numFiles ) {
      ctlunshelve.p_enabled = true;
   }
}

static void decrementResolved()
{
   resolvedFiles := _GetDialogInfoHt("resolvedFiles");
   if ( resolvedFiles==null ) resolvedFiles = 0;
   --resolvedFiles;

   numFiles := _GetDialogInfoHt("numFiles");
   _SetDialogInfoHt("resolvedFiles",resolvedFiles);

   if ( resolvedFiles >= numFiles ) {
      ctlunshelve.p_enabled = false;
   }
}

static int mergeSaveCallback(_str filename,int WID)
{
   status := WID._save_file('+o '_maybe_quote_filename(filename));
   return status;

}

static void createBlankFile(_str filename)
{
//   origCreated := _create_temp_view(auto tempWID=0);
//   status := tempWID._save_file('+o 'filename);
   status :=_open_temp_view(filename,auto tempWID,auto origWID,'+t');
   tempWID._save_file('+o');
   p_window_id = origWID;
//   p_window_id = origCreated;
   _delete_temp_view(tempWID);
}

static int findFirstConflictRecursive(int index)
{
   _TreeGetInfo(index,auto state,auto bm1,auto bm2,auto nodeFlags);
   if ( nodeFlags&TREENODE_FORCECOLOR ) {
      return index;
   }
   for (;;) {
      childIndex := _TreeGetFirstChildIndex(index);
      if ( childIndex>-1 ) {
         status := findFirstConflictRecursive(childIndex);
         if ( status>=0 ) return status;
      }
      index = _TreeGetNextSiblingIndex(index);
      if (index<0) break;
      _TreeGetInfo(index,state,bm1,bm2,nodeFlags);
      if ( nodeFlags&TREENODE_FORCECOLOR ) {
         return index;
      }
   }
   return -1;
}

static int findFirstConflict()
{
   return findFirstConflictRecursive(TREE_ROOT_INDEX);
}

void ctlresolve.lbutton_up()
{
   IVersionControl *pInterface = svcGetInterface(svc_get_vc_system());
   if ( pInterface==null ) {
      _message_box(get_message(VSRC_SVC_COULD_NOT_GET_VC_INTERFACE_RC,svc_get_vc_system()));
      return;
   }
   _str localRoot = _GetDialogInfoHt("localRoot");
   if ( !path_exists(localRoot) ) {
      _message_box(nls("Local root '%s' does not exist\n\nYou must unshelve to a different directory"));
      p_active_form.p_visible = true;
      ctlbrowse.call_event(ctlbrowse,LBUTTON_UP);
      return;
   }
   status := 0;
   origWID := p_window_id;
   p_window_id = ctltree1;

   tempOutputFile := mktemp();
   createBlankFile(tempOutputFile);

   do {
      index := _TreeCurIndex();
      // Be sure index is the "top" with the nodes that represent versions to merge
      // as the children
      _TreeGetInfo(index,auto state,auto bm1,auto bm2,auto nodeFlags);
      if ( state==TREE_NODE_LEAF ) {
         index = _TreeGetParentIndex(index);
      } else if ( !(nodeFlags & TREENODE_FORCECOLOR) ) {
         index = findFirstConflict();
         if ( index>=0 ) {
            _TreeSetCurIndex(index);
         }
      }

      baseFilename := _GetDialogInfoHt("baseFilename:"index);
      modsFilename := _GetDialogInfoHt("modsFilename:"index);
      curFilename  := _GetDialogInfoHt("curFilename:"index);
//      curRevision  := _GetDialogInfoHt("curRevision:"index);
      curRevision := "";
      //status = pInterface->enumerateVersions(curFilename,auto versionList,true);
      //if (!status) {
      //   curRevision = versionList[versionList._length()-1];
      //}
      if (pInterface->getBaseRevisionSpecialName() != "") {
         curRevision = pInterface->getBaseRevisionSpecialName();
      } else {
         status = pInterface->getCurLocalRevision(curFilename, curRevision, true);
      }

#if 0 //1:15pm 7/25/2013
      say('ctlresolve.lbutton_up curFilename='curFilename);
      pInterface->getFileStatus(curFilename,auto curFileStatus);
      if ( curFileStatus&SVC_STATUS_MODIFIED ) {
         result := _message_box(nls("%s is modified and you will lose the changes\n\nContinue?",curFilename),"",MB_YESNO);
         break;
      }
#endif

      isReadOnly := false;
      curFileExists := file_exists(curFilename);
      if ( curFileExists ) {
         isReadOnly = localShelfFileIsReadOnly(curFilename);
         if ( isReadOnly ) {
            result := _message_box(nls("'%s' is read only.\n\n%s now?",curFilename,pInterface->getCaptionForCommand(SVC_COMMAND_EDIT,false)),"",MB_YESNOCANCEL);
            if ( result==IDYES ) {
               pInterface->editFile(curFilename);
            }else if ( result==IDCANCEL ) {
               break;
            }
         }
      }

      if ( curRevision!="" ) {
         // Merge files.  Base is the clean file in the shelf, rev1 is the mod 
         // version from the shelf, rev2 is the current version of the file on
         // disk. Output is a temp file.  We will copy the temp file over when 
         // the user clicks the "unshelve" button

         baseTitle := '-basefilecaption " '_strip_filename(curFilename,'P')' (clean base version)"';
         rev1Title := '-rev1filecaption " '_strip_filename(curFilename,'P')' (modified shelf version)"';
         rev2Title := '-rev2filecaption " '_strip_filename(curFilename,'P')' (current 'curFilename' version)"';
         outputTitle := '-outputfilecaption " '_strip_filename(tempOutputFile,'P')' (temp version)"';
         baseFilename = stranslate(baseFilename,'/::/','//');
         modsFilename = stranslate(modsFilename,'/::/','//');
         status = merge('-savecallback 'mergeSaveCallback' -noeol -smart -forceconflict -noeditoutput -saveoutput 'baseTitle' 'rev1Title' 'rev2Title' 'outputTitle' '_maybe_quote_filename(baseFilename)' '_maybe_quote_filename(modsFilename)' 'curFilename' '_maybe_quote_filename(tempOutputFile));
         if ( _file_size(tempOutputFile)>0 ) {
            // If we saved the file, the conflict is resolved to the user's
            // satisfaction.  Save the filename on the index's user info and
            // set the node checked.

            // bringing up the merge dialog and closing it probably changed the
            // active window.
            p_window_id = ctltree1;

            STRHASHTAB fileTab = _GetDialogInfoHt("fileTab");
            fileTab:[_file_case(curFilename)] = '>'tempOutputFile;
            _SetDialogInfoHt("fileTab",fileTab);

            incrementResolved();
            _TreeSetCheckState(index,1,0);
            _TreeSetCheckable(index,0,0);
         }
      } else {
         if ( curFileExists ) {
            // We don't have to copy etc.  We diffed "into" the actual local 
            // file
            diff('-modal -file2title "'_strip_filename(curFilename,'P')' (from shelf)" '_maybe_quote_filename(curFilename)' '_maybe_quote_filename(modsFilename));
            p_window_id = ctltree1;

            incrementResolved();
            _TreeSetCheckState(index,1,0);
            _TreeSetCheckable(index,0,0);
         }
      }

   } while (false);

   resolvedFiles := _GetDialogInfoHt("resolvedFiles");
   if ( resolvedFiles==null ) resolvedFiles = 0;
   numFiles := _GetDialogInfoHt("numFiles");
   if ( numFiles==null ) numFiles = 0;
   if ( numFiles==resolvedFiles ) {
      ctlresolve.p_default = false;
      ctlunshelve.p_default = true;
   }

   p_window_id = origWID;
}

void ctlunshelve.lbutton_up()
{
   STRHASHTAB fileTab = _GetDialogInfoHt("fileTab");
   zipFilename := _GetDialogInfoHt("zipFilename");
   localRoot := _GetDialogInfoHt("localRoot");

   STRARRAY roFileArray;
   foreach (auto curFile => auto curTempFile in fileTab) {
      ro := localShelfFileIsReadOnly(curFile);
      if ( ro ) {
         roFileArray :+= curFile;
      }
   }

   len := roFileArray._length();
   if ( len ) {
      result := _message_box(nls("%s of the files to be written to are read only.\n\nCheck out read only files now?",len),"",MB_YESNO);
      if ( result!=IDYES ) {
         _message_box(nls("Cannot unshelve because of read only files"));
         return;
      }
      IVersionControl *pInterface = svcGetInterface(svc_get_vc_system());
      if ( pInterface==null ) {
         _message_box(get_message(VSRC_SVC_COULD_NOT_GET_VC_INTERFACE_RC,svc_get_vc_system()));
         return;
      }
      status := pInterface->editFiles(roFileArray);
      if ( status ) {
         return;
      }
      for (i:=0;i<len;++i) {
         _filewatchRefreshFile(roFileArray[i]);
      }
   }
   foreach (auto destFilename=> auto sourceFilename in fileTab) {
      ch := substr(fileTab:[destFilename],1,1);
      if (ch=='>') {
         fileTab:[destFilename] = substr(sourceFilename,2);
      }
   }
   justZipName := _strip_filename(zipFilename,'PE');
   backupPath := getShelfBasePath():+'backup_'justZipName;
   origBackupPath := backupPath;
   for (i:=0;;++i) {
      backupPath = origBackupPath'.'i;
      if (!path_exists(backupPath)) break;
   }

   STRHASHTAB backupFiles;
   foreach (destFilename=> sourceFilename in fileTab) {
      curDestFilename := substr(destFilename,length(localRoot)+1);
      backupFiles:[destFilename] = backupPath:+FILESEP:+curDestFilename;
   }

   status := show('-modal _svc_unshelve_summary_form',fileTab,backupFiles);
   if ( status!=1 ) {
      if ( !p_active_form.p_visible ) {
         p_active_form._delete_window();
      }
      return;
   }

   SVCDisplayOutput(nls("Unshelving %s to %s",zipFilename,localRoot));
   foreach (sourceFilename => auto backupFilename in backupFiles) {
      //say('ctlunshelve.lbutton_up backup 'sourceFilename' to 'backupFilename);
      curBackupPath := _file_path(backupFilename);
      if ( !path_exists(curBackupPath) ) {
         make_path(curBackupPath);
      }
      SVCDisplayOutput(nls("Backing up %s to %s",sourceFilename,backupFilename));
      copy_file(sourceFilename,backupFilename);
   }

   STRARRAY retagArray;
   totalStatus := 0;
   foreach (destFilename=> sourceFilename in fileTab) {
      ch := substr(sourceFilename,1,1);
      if ( ch=='>' ) {
         sourceFilename = substr(sourceFilename,2);
      }
      _LoadEntireBuffer(destFilename);
      status = copy_file(sourceFilename,destFilename);
      if ( !status ) {
         SVCDisplayOutput(nls("Copy %s to %s",sourceFilename,destFilename));
         STRARRAY tempArray;
         tempArray[0] = destFilename;
         retagArray :+= destFilename;
         origWID := _create_temp_view(auto tempWID);
         _reload_vc_buffers(tempArray);
         p_window_id = origWID;
         _delete_temp_view(tempWID);
      } else {
         totalStatus = status;
         _message_box(nls("Could not copy %s to %s\n\n%s",sourceFilename,destFilename,get_message(status)));
         SVCDisplayOutput(nls("Could not copy %s to %s",sourceFilename,destFilename));
         SVCDisplayOutput(nls("   %s",get_message(status)));
      }
   }
   manifestFilename := zipFilename:+FILESEP:+"manifest.xml";
   xmlhandle := _xmlcfg_open(manifestFilename,status,VSXMLCFG_OPEN_ADD_PCDATA);
   if ( !status ) {
      // Set Unshelved attribute in manifest file and append it to the shelf.
      // We use this in the list dialog
      index := _xmlcfg_get_first_child(xmlhandle,TREE_ROOT_INDEX);
      if ( index>=0 ) {
         _xmlcfg_set_attribute(xmlhandle,index,"Unshelved",1);
         tempFilename := mktemp();
         status = _xmlcfg_save(xmlhandle,-1,VSXMLCFG_SAVE_ONE_LINE_IF_ONE_ATTR,tempFilename);
         _ZipClose(zipFilename);
         STRARRAY tempSourceArray,tempDestArray;
         tempSourceArray[0] = tempFilename;
         tempDestArray[0] = "manifest.xml";
         status = _ZipAppend(zipFilename,tempSourceArray,auto zipStatus,tempDestArray);
         delete_file(tempFilename);
      }
   }
   _retag_vc_buffers(retagArray);
   if ( !totalStatus ) {
      _message_box(nls("Files unshelved successfully"));
      p_active_form._delete_window(0);
   }
}

static bool localShelfFileIsReadOnly(_str filename)
{
   if ( !file_exists(filename) ) return false;
   attrs := file_list_field(filename,DIR_ATTR_COL,DIR_ATTR_WIDTH);
   ro := false;
   if (_isUnix()) {
      ro=!pos('w',attrs,'','i');
   } else {
      status := _open_temp_view(filename,auto temp_wid,auto orig_wid);
      ro = !_WinFileIsWritable(temp_wid);
      _delete_temp_view(temp_wid);
      p_window_id = orig_wid;
   }
   return ro;
}

defeventtab _svc_shelf_list_form;
void ctlbrowse.lbutton_up()
{
   parse ctlShelfRootLabel.p_caption with (SHELF_LOCALROOT_CAPTION) auto localRoot;
   _str result = _ChooseDirDialog("Directory to Review to",localRoot);
   if ( result=='' ) return;

   ctlShelfRootLabel.p_caption = SHELF_LOCALROOT_CAPTION:+result;
   ctlbrowse.p_x = ctlShelfRootLabel.p_x_extent;
}

void ctlclose.on_create()
{
   p_active_form.p_caption = "Shelf List";

   fillInItemsFromList();
}

static void fillInItemsFromList(bool setButtonWidths=true)
{
   origWID := p_window_id;
   p_window_id = ctltree1;
   if ( setButtonWidths ) {
      _TreeSetColButtonInfo(0,1500,TREE_BUTTON_IS_FILENAME,-1,"Filename");
      _TreeSetColButtonInfo(1,1000,0,-1,"Status");
      _TreeSetColButtonInfo(2,5000,0,-1,"Path");
   }

   _TreeDelete(TREE_ROOT_INDEX,'C');
   len := def_svc_all_shelves._length();
   for (i:=0;i<len;++i) {
      zipFilename := def_svc_all_shelves[i];
      manifestFilename := def_svc_all_shelves[i]:+FILESEP:+"manifest.xml";
      xmlhandle := _xmlcfg_open(manifestFilename,auto status,VSXMLCFG_OPEN_ADD_PCDATA);
      unshelved := false;
      if ( !status ) {
         index := _xmlcfg_get_first_child(xmlhandle,TREE_ROOT_INDEX);
         if ( index>=0 ) {
            unshelved = _xmlcfg_get_attribute(xmlhandle,index,"Unshelved",false);
         }
         _xmlcfg_close(xmlhandle);
      }
      caption := _strip_filename(def_svc_all_shelves[i],'P'):+"\t":+(unshelved?"Unshelved":"Shelved"):+"\t":+_file_path(def_svc_all_shelves[i]);
      _TreeAddItem(TREE_ROOT_INDEX,caption,TREE_ADD_AS_CHILD,0,0,TREE_NODE_LEAF);
   }
   index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);

   // Be sure we refresh the dialog to match the currently selected item
   call_event(CHANGE_SELECTED,index,ctltree1,ON_CHANGE,'W');

   p_window_id = origWID;
}

void ctlMoveShelfUp.lbutton_up()
{
   origWID := p_window_id;
   p_window_id = ctltree1;

   index := _TreeCurIndex();
   if ( index<0 ) return;
   indexAbove := _TreeGetPrevIndex(index);
   if ( indexAbove<0 ) return;

   cap := _TreeGetCaption(index);
   _TreeDelete(index);
   newIndex := _TreeAddItem(indexAbove,cap,TREE_ADD_BEFORE,0,0,TREE_NODE_LEAF);
   _TreeSetCurIndex(newIndex);
      
   getShelfListFromTree();      
   call_event(CHANGE_SELECTED,_TreeCurIndex(),ctltree1,ON_CHANGE,'W');

   p_window_id = origWID;
}

void ctlMoveShelfDown.lbutton_up()
{
   origWID := p_window_id;
   p_window_id = ctltree1;

   index := _TreeCurIndex();
   if ( index<0 ) return;
   indexBelow := _TreeGetNextIndex(index);
   if ( indexBelow<0 ) return;

   cap := _TreeGetCaption(index);
   _TreeDelete(index);
   newIndex := _TreeAddItem(indexBelow,cap,0,0,0,TREE_NODE_LEAF);
   _TreeSetCurIndex(newIndex);
      
   getShelfListFromTree();      
   call_event(CHANGE_SELECTED,_TreeCurIndex(),ctltree1,ON_CHANGE,'W');

   p_window_id = origWID;
}

void ctlRemoveShelf.lbutton_up()
{
   origWID := p_window_id;
   p_window_id = ctltree1;

   index := _TreeCurIndex();
   if ( index<0 ) return;
   _TreeDelete(index);
      
   getShelfListFromTree();      
   if ( def_svc_all_shelves._length()==0 ) {
      gNoShelves = true;
   }
   call_event(CHANGE_SELECTED,_TreeCurIndex(),ctltree1,ON_CHANGE,'W');

   p_window_id = origWID;
}

void ctlAddShelf.lbutton_up()
{
   origWID := p_window_id;
   p_window_id = ctltree1;
   index := _TreeCurIndex();
   ln := -1;
   
   // Use >0 because we do not want the root index
   if ( index>0 ) {
      ln = _TreeGetLineNumber(index);
   }
   call_event(CHANGE_SELECTED,_TreeCurIndex(),ctltree1,ON_CHANGE,'W');
   p_window_id = origWID;
   openShelf(ln+1);
}

static void getShelfListFromTree()
{
   orig_def_svc_all_shelves := def_svc_all_shelves;
   def_svc_all_shelves = null;
   index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   for (;;) {
      if ( index<0 ) break;
      cap := _TreeGetCaption(index);
      parse cap with auto name auto shelfStatus auto path;
      def_svc_all_shelves :+= path:+name;
      index = _TreeGetNextSiblingIndex(index);
   }
   if ( def_svc_all_shelves!=orig_def_svc_all_shelves ) {
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
}

void _svc_shelf_list_form.on_resize()
{
   // set mininum size for this form
   if (!_minimum_width()) {
      _set_minimum_size(ctlclose.p_width*7, ctlclose.p_height*8);
   }

   labelWID := ctltree1.p_prev;
   clientWidth  := _dx2lx(SM_TWIP,p_active_form.p_client_width);
   clientHeight := _dy2ly(SM_TWIP,p_active_form.p_client_height);
   xbuffer := labelWID.p_x;
   ybuffer := labelWID.p_y;

   treeWidth1 := clientWidth - ctlAddShelf.p_width - (3*xbuffer);
   treeWidth2 := clientWidth - (2*xbuffer);
   ctltree1.p_width = treeWidth1;
   ctltree2.p_width = treeWidth2;
   ctltree1.p_y = labelWID.p_y_extent+ybuffer;
   treeArea := clientHeight - ctlclose.p_height;
   ctltree2.p_height = ctltree1.p_height = (treeArea intdiv 2) - ((7*ybuffer) + ctllabel1.p_height);
   ctlcommentLabel.p_y = ctltree1.p_y_extent+ybuffer;
   ctlShelfRootLabel.p_y = ctlcommentLabel.p_y_extent+ybuffer;
   ctlbrowse.p_y = ctlShelfRootLabel.p_y;
   ctlbrowse.p_x = ctlShelfRootLabel.p_x_extent + xbuffer;
   ctlbrowse.resizeToolButton(ctlShelfRootLabel.p_height);
   
   alignUpDownListButtons(ctltree1.p_window_id, 0,
                          ctlAddShelf.p_window_id, 
                          ctlMoveShelfUp.p_window_id,
                          ctlMoveShelfDown.p_window_id,
                          ctlRemoveShelf.p_window_id);

   ctltree2.p_prev.p_y = ctlShelfRootLabel.p_y_extent+ybuffer;
   ctltree2.p_y = ctltree2.p_prev.p_y_extent+ybuffer;

   alignControlsHorizontal(ctltree2.p_x, ctltree2.p_y_extent + ybuffer,
                           xbuffer,
                           ctlunshelve.p_window_id,
                           ctlclose.p_window_id,
                           ctledit.p_window_id,
                           ctldelete.p_window_id,
                           ctlopen.p_window_id,
                           ctlreview.p_window_id);

}

static void removeFileFromList(_str filename)
{
   INTARRAY delList;
   len := def_svc_all_shelves._length();
   for ( i:=0;i<len;++i ) {
      if ( _file_eq(filename,def_svc_all_shelves[i]) ) {
         delList :+= i;
      }
   }
   removed := false;
   len = delList._length();
   for ( i=len;i>0;--i ) {
      def_svc_all_shelves._deleteel(delList[i-1]);
      removed = true;
   }
   if ( removed ) {
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
}

static void openShelf(int arrayIndex=0)
{
   result := _OpenDialog('-modal',
                         'Select file to add',                   // Dialog Box Title
                         '*.zip',// Initial Wild Cards
                         'Zip Files (*.zip)',
                         OFN_FILEMUSTEXIST);
   if ( result=="" ) {
      return;
   }
   filename := result;
   if (!pos(' '_maybe_quote_filename(filename)' ',' 'def_svc_user_shelves' ',1,_fpos_case)) {
      removeFileFromList(filename);
      def_svc_all_shelves._insertel(filename,arrayIndex);
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
   fillInItemsFromList(false);
   index := ctltree1._TreeSearch(TREE_ROOT_INDEX,_strip_filename(filename,'P')"\tShelved\t"_file_path(filename),'r');
   if (index<0) {
      index = ctltree1._TreeSearch(TREE_ROOT_INDEX,_strip_filename(filename,'P')"\tUnshelved\t"_file_path(filename),'r');
   }
   if (index>0) {
      ctltree1._TreeSetCurIndex(index);
   }
}

void ctlopen.lbutton_up()
{
   openShelf();
}

static void getShelfFileInfo(_str &baseFilename,_str &modFilename,_str &localFilename,_str &baseRevision)
{
   zipFilename := ctltree1.zipFilenameFromTree();
   ShelfInfo shelf = _GetDialogInfoHt("shelves."zipFilename);
   if ( shelf==null ) {
      status := loadShelf(zipFilename,shelf);
      if ( status ) return;
      _SetDialogInfoHt("shelves."zipFilename,shelf);
   }
   index := ctltree2._TreeCurIndex();
   parse ctlShelfRootLabel.p_caption with (SHELF_LOCALROOT_CAPTION) auto localRoot;
   pathAndName := ctltree2._TreeGetCaption(index);
   localFilename = localRoot:+pathAndName;
   baseFilename  = zipFilename:+FILESEP"base":+FILESEP:+pathAndName;
   modFilename  = zipFilename:+FILESEP"mods":+FILESEP:+pathAndName;

   // Have to find the file in the shelf to get the base file revision
   len := shelf.fileList._length();
   for (i:=0;i<len;++i) {
      if ( _file_eq(shelf.fileList[i].filename,stranslate(pathAndName,'/',FILESEP)) ) {
         baseRevision = shelf.fileList[i].revision;
      }
   }
}

void ctlreview.lbutton_up()
{
   origWID := p_window_id;
   p_window_id = ctltree1;

   getShelfFileInfo(auto baseFile,auto modFile,auto localFilename,auto baseRevision);

   origWID = _create_temp_view(auto tempWID);
   p_window_id = origWID;

   if ( baseRevision!="" ) {
      merge('-showchanges -noeditoutput -bouti -nosave -readonlyoutput '_maybe_quote_filename(baseFile)' '_maybe_quote_filename(modFile)' '_maybe_quote_filename(localFilename)' 'tempWID.p_buf_id);
   } else {
      status := _open_temp_view(modFile,tempWID,origWID);
      if ( !status ) {
         tempWID._SetEditorLanguage();
         p_window_id = origWID;
         _showbuf(tempWID,false,"-new -modal",localFilename);
      }
   }

   _delete_temp_view(tempWID);

   p_window_id = origWID;
}

static _str zipFilenameFromTree(int index=-1)
{
   if (index==-1) index = _TreeCurIndex();
   if ( index<0 ) return("");
   caption := _TreeGetCaption(index);
   parse caption with auto zipName "\t" auto shelfStatus "\t" auto zipFilePath;
   zipFilename := zipFilePath:+zipName;
   return zipFilename;
}

void ctltree1.on_change(int reason,int index)
{
   onChange := _GetDialogInfoHt("onChange");
   if ( onChange==1 ) return;

   _SetDialogInfoHt("onChange",1);
   if (index>0 && !(index==TREE_ROOT_INDEX && !p_ShowRoot) ) {
      ctledit.p_enabled = ctlunshelve.p_enabled = ctldelete.p_enabled = true;
      ctlMoveShelfUp.p_enabled = ctlMoveShelfDown.p_enabled = ctlRemoveShelf.p_enabled = true;
      switch ( reason ) {
      case CHANGE_SELECTED:
         {
            ShelfInfo shelves:[] = _GetDialogInfoHt("shelves");

            zipFilename := zipFilenameFromTree(index);
            manifestFilename := zipFilename:+FILESEP:+"manifest.xml";
            ShelfInfo curShelf = shelves:[_file_case(manifestFilename)];
            if ( curShelf==null ) {
               status := loadShelf(zipFilename,curShelf);
               shelves:[_file_case(manifestFilename)] = curShelf;
               _SetDialogInfoHt("shelves",shelves);
            }
            if ( curShelf!=null ) {
               startOfComment := curShelf.commentArray[0];
               if ( startOfComment==null ) startOfComment="";

               ctlcommentLabel.p_caption = SHELF_COMMENT_CAPTION:+startOfComment;
               ctlShelfRootLabel.p_caption = SHELF_LOCALROOT_CAPTION:+stranslate(curShelf.localRoot,FILESEP,'/');
               ctlbrowse.p_x = ctlShelfRootLabel.p_x_extent + 60;
               len := curShelf.fileList._length();
               ctltree2._TreeDelete(TREE_ROOT_INDEX,'C');
               for (i:=0;i<len;++i) {
                  ctltree2._TreeAddItem(TREE_ROOT_INDEX,stranslate(curShelf.fileList[i].filename,FILESEP,'/'),TREE_ADD_AS_CHILD,_pic_file,_pic_file,TREE_NODE_LEAF);
               }
            }
         }
         break;
      case CHANGE_LEAF_ENTER:
         ctlunshelve.call_event(ctlunshelve,LBUTTON_UP);
         break;
      }
   } else {
      ctledit.p_enabled = ctlunshelve.p_enabled = ctldelete.p_enabled = false;
      ctlMoveShelfUp.p_enabled = ctlMoveShelfDown.p_enabled = ctlRemoveShelf.p_enabled = false;
      ctltree2._TreeDelete(TREE_ROOT_INDEX,'C');
   }
   _SetDialogInfoHt("onChange",0);
}

void ctledit.lbutton_up()
{
   origWID := p_window_id;
   p_window_id = ctltree1;
   zipFilename := zipFilenameFromTree();
   if ( zipFilename!="" ) {
      loadShelf(zipFilename,auto shelf);
      guiEditShelf(&shelf,zipFilename);
   }
   p_window_id = origWID;
   ctltree1._set_focus();
}

static int guiEditShelf(ShelfInfo *pshelf,_str zipFilename,bool promptToRefresh=true)
{
   refreshZipFile := true;
   if ( pshelf->fileList._length()==0 ) {
      return COMMAND_CANCELLED_RC;
   }
   status := show('-modal _svc_shelf_form',zipFilename,pshelf,&promptToRefresh,&refreshZipFile);
   if ( status==0 ) {
      if ( refreshZipFile ) {
         writeZipFileShelf(zipFilename,*pshelf);
      }
   }
   return 0;
}

static int writeZipFileShelf(_str zipFilename,ShelfInfo &shelf)
{
   IVersionControl *pInterface=null;
   if (shelf.VCSystemName!="") {
      pInterface = svcGetInterface(shelf.VCSystemName);
      if ( pInterface==null ) return VSRC_SVC_COULD_NOT_GET_VC_INTERFACE_RC;
   }

   _control ctlrootPathLabel;

   STRARRAY relFileList,destFileList,sourceFileList;
   // relFileList is a list from the tree.  Now we have to make lists so that
   // we have mods and base versions of each one.  Start with the dest filnnames
   len := shelf.fileList._length();
   for ( i:=0;i<len;++i ) {
      destName := "mods/"strip(shelf.fileList[i].filename,'B','"');
      if ( substr(shelf.fileList[i].filename,1,1)=='/') {
         destName = "mods/::"strip(shelf.fileList[i].filename,'B','"');
      }
      destFileList :+= destName;
   }
   for ( i=0;i<len;++i ) {
      destName := "base/"strip(shelf.fileList[i].filename,'B','"');
      if ( substr(shelf.fileList[i].filename,1,1)=='/') {
         destName = "base/::"strip(shelf.fileList[i].filename,'B','"');
      }
      destFileList :+= destName;
   }
   // Now the source filenames.  Get the mods first, they're the local files
   for ( i=0;i<len;++i ) {
      curFilename := shelf.localRoot:+shelf.fileList[i].filename;
      if ( substr(shelf.fileList[i].filename,2,1)==':' ||  substr(shelf.fileList[i].filename,1,1)=='/') {
         curFilename = shelf.fileList[i].filename;
      }
      sourceFileList :+= curFilename;
   }
   mou_hour_glass(true);
   STRARRAY tempFileList;
   for ( i=0;i<len;++i ) {
      curFilename := shelf.baseRoot!=null ? shelf.baseRoot:+shelf.fileList[i].filename :shelf.localRoot:+shelf.fileList[i].filename;
      // Check to see if the file is absolute
      if ( substr(shelf.fileList[i].filename,2,1)==':' ||  substr(shelf.fileList[i].filename,1,1)=='/') {
         curFilename = shelf.fileList[i].filename;
      }
      if (shelf.VCSystemName!="") {
         status := pInterface->getCurLocalRevision(curFilename,shelf.fileList[i].revision,true);
         if ( status ) {
            _message_box("Could not get revision for %s",curFilename);
            return 1;
         }
      } else {
         if (file_exists(curFilename)) {
            shelf.fileList[i].revision = "mfdiff";
         }
      }
      base_rev := shelf.fileList[i].revision;
      if (shelf.fileList[i].revision=="") {
         if (pInterface && pInterface->getBaseRevisionSpecialName() != "") {
            base_rev = pInterface->getBaseRevisionSpecialName();
         } else {
            base_rev = "mfdiffBase";
         }
      }
      baseFileWID := 0;
      if (pInterface) {
         pInterface->getFile(curFilename,base_rev,baseFileWID);
      } else {
         status := _open_temp_view(curFilename,baseFileWID,auto origWID);
         if (status) {
            // We are creating a shelf from a multi-file diff, and there is no
            // base file.  Simulate the way we handle this in a version control
            // shelf.
            origWID = _create_temp_view(baseFileWID);
         }
         p_window_id = origWID;
      }

      baseFileSrc := mktemp();
      if (baseFileWID!=0) {
         baseFileWID._save_file('+o 'baseFileSrc);
         _delete_temp_view(baseFileWID);
         tempFileList :+= baseFileSrc;
         sourceFileList :+= baseFileSrc;
      }
   }


   _maybe_strip_filesep(zipFilename);
   _str tempFilename;
   status := writeManifestZipFileToTemp(zipFilename,shelf,tempFilename);
   sourceFileList :+= tempFilename;
   destFileList :+= "manifest.xml";
   _ZipClose(zipFilename);
   zipFilename = strip(zipFilename,'B','"');
   status = _ZipCreate(zipFilename,sourceFileList,auto zipStatus,destFileList);

   delete_file(tempFilename);
   len = tempFileList._length();
   for ( i=0;i<len;++i ) {
      delete_file(tempFileList[i]);
   }
   mou_hour_glass(false);

   return 0;
}


_command void svc_add_to_shelf(_str cmdLine="") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return;
   }
   zipFilename := parse_file(cmdLine);
   filename := parse_file(cmdLine);

   svcAddControlledFileToShelf(zipFilename,filename);

   removeFileFromList(zipFilename);
   def_svc_all_shelves._insertel(zipFilename,0);
   _config_modify_flags(CFGMODIFY_DEFVAR);
}

static int svcAddControlledFileToShelf(_str zipFilename,_str fileList)
{
   if ( fileList=="" ) return COMMAND_CANCELLED_RC;
   firstFilename := get_first_file(fileList);
   autoVCSystem := svc_get_vc_system(firstFilename);

   zipFilename = strip(zipFilename,'B','"');

   IVersionControl *pInterface = svcGetInterface(autoVCSystem);
   if ( pInterface==null ) {
      _message_box(get_message(VSRC_SVC_COULD_NOT_GET_VC_INTERFACE_RC,autoVCSystem));
      return VSRC_SVC_COULD_NOT_GET_VC_INTERFACE_RC;
   }
   status := loadShelf(zipFilename,auto shelf);
   if ( status ) {
      _message_box(nls("Could not open shelf file '%s'",zipFilename));
      return status;
   }
   STRARRAY srcFileList;
   STRARRAY destFileList;

   mou_hour_glass(true);
   for (;;) {
      filename := parse_file(fileList);
      if ( filename=="" ) break;
      absoluteFilename := false;
      shelf.localRoot = stranslate(shelf.localRoot,FILESEP,'/');
      if ( !_file_eq(shelf.localRoot,substr(filename,1,length(shelf.localRoot))) ) {
         result :=  _message_box(nls("Shelf '%s' has root '%s'.\n\nThis file will be added with an absolute filename. Continue?",zipFilename,shelf.localRoot),"",MB_YESNO);
         if ( result != IDYES ) {
            return 1;
         }
         absoluteFilename = true;
      }
      relFilename := relative(filename,shelf.localRoot);
      if ( absoluteFilename ) {
         relFilename = absolute(filename);
      }
      len := shelf.fileList._length();
      found := false;
      for (i:=0;i<len;++i) {
         if ( _file_eq(relFilename,shelf.fileList[i].filename) ) {
            found = true;break;
         }
      }
      // For now allow this if we found it, this way we refresh the items
      STRARRAY commentArray;

      ShelfFileInfo file;

      status = pInterface->getCurRevision(filename,auto curRevision,"",true);
      status = pInterface->getCurLocalRevision(filename,auto curLocalRevision,true);

      baseFileSrc := "";
      baseFileDest := "";
      if ( curLocalRevision!="" ) {
         pInterface->getFile(filename,curLocalRevision,auto baseFileWID);
         baseFileSrc = mktemp();
         baseFileWID._save_file('+o 'baseFileSrc);
         _delete_temp_view(baseFileWID);

         baseFileDest = "base/"stranslate(relFilename,'/',FILESEP);
      }

      modFileSrc := filename;
      modFileDest := "mods/"stranslate(relFilename,'/',FILESEP);

      if ( !found ) {
         file.filename = relFilename;
         file.baseFile = baseFileDest;
         file.commentArray = commentArray;
         file.modFile = modFileDest;
         file.revision = curLocalRevision;
         shelf.fileList :+= file;
      }
      srcFileList :+= baseFileSrc;
      destFileList :+= baseFileDest;
      srcFileList :+= modFileSrc;
      destFileList :+= modFileDest;
   }
   _ZipClose(zipFilename);
   status = _ZipAppend(zipFilename,srcFileList,auto zipStatus,destFileList);
   writeManifestZipFile(zipFilename,shelf);
   if ( !status ) {
      removeFileFromList(zipFilename);
      def_svc_all_shelves._insertel(zipFilename,0);
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
   mou_hour_glass(false);

   return status;
}

static void getShelfPaths(_str manifestFilename,_str &shelfPath,_str &baseFilePath,_str &modFilePath)
{
   shelfPath = _file_path(manifestFilename);
   _maybe_append_filesep(shelfPath);
   baseFilePath = shelfPath:+"base";
   _maybe_append_filesep(baseFilePath);
   modFilePath  = shelfPath:+"mods";
   _maybe_append_filesep(modFilePath);
}

void ctlunshelve.lbutton_up()
{
   mou_hour_glass(true);
   do {
      origWID := p_window_id;
      p_window_id = ctltree1;
      zipFilename := zipFilenameFromTree();
      if ( zipFilename!="" ) {
         loadShelf(zipFilename,auto shelf);
#if 0 //9:53am 8/20/2019
         if ( lowcase(shelf.VCSystemName)!=lowcase(svc_get_vc_system()) ) {
            _message_box(nls("You cannot unshelve this because it was shelved from '%s' and the current version control system is '%s'",shelf.VCSystemName,svc_get_vc_system()));
            break;
         }
#endif
         parse ctlShelfRootLabel.p_caption with (SHELF_LOCALROOT_CAPTION) auto localRoot;
         shelf.localRoot = localRoot;

         // compose prompt for directory to unshelf to
         unshelf_prompt := nls("Do you wish to unshelve to this directory?");
         if ( !path_exists(shelf.localRoot) ) {
            unshelf_prompt = nls("Local root '%s' does not exist<br>You must unshelve to a different directory",shelf.localRoot);
         }

         // retrieve new directory name
         result := textBoxDialog(nls("Unshelve Files To:"),
                                 0,      // flags,
                                 0,      // textbox width
                                 "",     // help item
                                 "OK,Cancel:_cancel\t-html "unshelf_prompt,
                                 "",     // retrieve name
                                 "-bd Directory:"shelf.localRoot);  // prompt
         if (result==COMMAND_CANCELLED_RC) return;
         shelf.localRoot = _param1;

         status := show('-modal -hidden _svc_unshelve_form',shelf,zipFilename);
         if ( !status ) {
            p_active_form._delete_window(0);
            return;
         }
      }
      p_window_id = origWID;
      mou_hour_glass(false);
      ctltree1._set_focus();
   } while (false);
   mou_hour_glass(false);
}

static void deleteCurrentItemInTree()
{
   index := _TreeCurIndex();
   if ( index<0 ) return;

   cap := _TreeGetCaption(index);
   parse cap with auto name auto status auto path;
   zipFilename := path:+name;
   result := _message_box(nls("Delete file '%s'?",zipFilename),"",MB_YESNO);
   if ( result==IDYES ) {
      orig := def_delete_uses_recycle_bin;
      def_delete_uses_recycle_bin = true;
      recycle_file(zipFilename);
      def_delete_uses_recycle_bin = orig;
      _TreeDelete(index);
      getShelfListFromTree();
      if ( def_svc_all_shelves._length()==0 ) {
         gNoShelves = true;
      }
      call_event(CHANGE_SELECTED,_TreeCurIndex(),ctltree1,ON_CHANGE,'W');
   }
}

void ctldelete.lbutton_up()
{
   ctltree1.deleteCurrentItemInTree();
}

void ctltree1.del()
{
   ctltree1.deleteCurrentItemInTree();
}


defeventtab _svc_unshelve_summary_form;

void ctlok.on_create(STRHASHTAB copyFileTab=null,STRHASHTAB backupFileTab=null)
{
   cap := "Unshelving will perform the following operations:<P>";
   cap :+= "<FONT size='2'><UL>";
   foreach (auto curFile => auto tempFile in copyFileTab) {
      if ( substr(tempFile,1,1)=='>' ) {
         tempFile = substr(tempFile,2);
      }
      cap :+= "<LI> backup "curFile" to "backupFileTab:[curFile]"</LI>";
      cap :+= "<LI> copy "tempFile" to "curFile"</LI>";
   }
   cap :+= "</UL></FONT>";
   ctlminihtml1.p_text = cap;
}

void _svc_unshelve_summary_form.on_resize()
{
   xbuf := ctlminihtml1.p_x;
   ybuf := ctlminihtml1.p_y;

   clientWidth  := _dx2lx(SM_TWIP,p_active_form.p_client_width);
   clientHeight := _dy2ly(SM_TWIP,p_active_form.p_client_height);

   ctlminihtml1.p_width = clientWidth - (2*xbuf);
   ctlminihtml1.p_height = clientHeight - ((3*xbuf)+ctlok.p_height);

   ctlok.p_y = ctlok.p_next.p_y = ctlminihtml1.p_y_extent+ybuf;
}

void ctlok.lbutton_up()
{
   p_active_form._delete_window(1);
}

defeventtab _svc_new_shelf_form;

void ctlok.on_create()
{
   ctltree1._dlpath(_ConfigPath():+SHELVES_PATH);
}

void _svc_new_shelf_form.on_resize()
{
   labelWID := p_child;
   xbuf := labelWID.p_x;
   ybuf := ctltext1.p_y;

   clientWidth  := _dx2lx(SM_TWIP,p_active_form.p_client_width);
   clientHeight := _dy2ly(SM_TWIP,p_active_form.p_client_height);

   ctltext1.p_width = (clientWidth-ctltext1.p_x) - xbuf;
   ctltree1.p_width = ctltext1.p_width;

   ctltree1.p_height = clientHeight - (ctltext1.p_height+ctlok.p_height+(4*ybuf));

   ctlok.p_y = ctlok.p_next.p_y = ctltree1.p_y_extent+ybuf;
}

void ctlok.lbutton_up()
{
   if ( ctltext1.p_text=="" ) return;
   path := ctltree1._dlpath():+ctltext1.p_text;
   _param1 = path;
   p_active_form._delete_window(1);
}

void _init_menu_shelving(int menu_handle,int no_child_windows,bool is_popup_menu=false)
{
   filename := "";
   if (no_child_windows) {
      return;
   }else{
      filename = _mdi.p_child.p_buf_name;
   }

   status := 0;
   submenuHandle := -1;
   if ( !is_popup_menu ) {
      status = _menu_find_loaded_menu_caption_prefix(menu_handle,"Tools", submenuHandle);
   } else submenuHandle = menu_handle;
   if (status>=0) {
      status = _menu_find_loaded_menu_caption_prefix(submenuHandle,"Shelves",submenuHandle);
      if (status>=0) {
         index := _menu_find_loaded_menu_caption_prefix(submenuHandle,"Add to shelf");
         if (index>=0) {
            _menu_delete(submenuHandle,index);
         }
         len := def_svc_all_shelves._length();
         VCSystem := svc_get_vc_system(_file_path(filename));
         if ( len>0 && VCSystem!="" ) {
            testHandle := _menu_insert(submenuHandle,-1,MF_SUBMENU,"Add to shelf using "VCSystem);
            if ( testHandle ) {
               for ( i:=0;i<len;++i ) {
                  _menu_insert(testHandle,i,MF_ENABLED,def_svc_all_shelves[i],'svc-add-to-shelf '_maybe_quote_filename(def_svc_all_shelves[i])' '_maybe_quote_filename(filename));
               }
            }
         }
      }
   }
}

void _on_popup_shelving(_str menu_name,int menu_handle)
{
   _init_menu_shelving(menu_handle,_no_child_windows(),true);
}

