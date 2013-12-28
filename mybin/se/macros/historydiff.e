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
#pragma option(pedantic,on)
#region Imports
#include 'slick.sh'
#include 'markers.sh'
#import 'codehelp.e'
#import 'context.e'
#import 'diff.e'
#import 'diffedit.e'
#import 'listbox.e'
#import 'main.e'
#import 'picture.e'
#import 'saveload.e'
#import 'stdcmds.e'
#import 'stdprocs.e'
#import 'tags.e'
#import 'se/tags/TaggingGuard.e'
#require 'se/vc/IVersionedFile.e'
#import 'se/vc/BackupHistoryVersionedFile.e'
#import 'se/vc/SVNVersionedFile.e'
#endregion Imports

defeventtab _history_diff_form;

#define controlXExtent(a) (a.p_x+a.p_width)
#define controlYExtent(a) (a.p_y+a.p_height)
void _diffedit_UpdateForm();

void _history_diff_form.on_load()
{
   se.vc.IVersionedFile *pVersionedFile = _GetDialogInfoHt("pVersionedFile");
   retrieveValue := 0;
   _control _grabbar_horz;
   if ( *pVersionedFile instanceof se.vc.BackupHistoryVersionedFile ) {
      retrieveValue = _retrieve_value( "_history_diff_backup_history_form._grabbar_horz" );
   } else {
      retrieveValue = _retrieve_value( "_history_diff_form._grabbar_horz" );
   }

   if (retrieveValue != null && isinteger(retrieveValue)) _grabbar_horz.p_y = retrieveValue;
}

static void nextDiff(int wid)
{
   _control _ctlfile1,_ctlfile2;
   wid._DiffNextDifference(wid._ctlfile1,wid._ctlfile2);
   if ( _iswindow_valid(wid) ) {
      wid._DiffUpdateScrollThumbs(true);
   }
}

void _ctlclose.on_create(se.vc.IVersionedFile *pVersionedFile=null,_str version="",boolean useStaticFile=false)
{
   _SetDialogInfoHt("inOnCreate",1);
   _SetDialogInfoHt("pVersionedFile",pVersionedFile);
   pVersionedFile->enumerateVersions(auto versionList);
   origWID := p_window_id;
   _control ctlVersionList;
   p_window_id = ctlVersionList;
   index := TREE_ROOT_INDEX;
   flags := TREE_ADD_AS_CHILD;
   len := versionList._length();

   colWidth := ctlVersionList.p_width intdiv 3;
   ctlVersionList._TreeSetColButtonInfo(0, colWidth, -1, -1, 'Version');
   ctlVersionList._TreeSetColButtonInfo(1, colWidth, -1, -1, 'Date');
   ctlVersionList._TreeSetColButtonInfo(2, colWidth, -1, -1, 'Author');
   for ( i:=0;i<len;++i ) {
      //pVersionedFile->getVersionInfo(versionList[i],auto versionInfo="");
      //parse versionInfo with auto date auto time .;
      SVCHistoryInfo info;
      pVersionedFile->getHistoryInfo(versionList[i],info);
      if ( info!=null && info.date!=null && info.author!=null ) {
         index = _TreeAddItem(index,versionList[i]"\t"info.date"\t"info.author,flags,_pic_file,_pic_file,TREE_NODE_LEAF,0,versionList[i]);
      } else if ( info!=null && info.date!=null ) {
         index = _TreeAddItem(index,versionList[i]"\t"info.date,flags,_pic_file,_pic_file,TREE_NODE_LEAF,0,versionList[i]);
      } else {
         index = _TreeAddItem(index,versionList[i],flags,_pic_file,_pic_file,TREE_NODE_LEAF,0,versionList[i]);
      }
      flags = TREE_ADD_BEFORE;
   }
   _SetDialogInfoHt("useStaticFile",useStaticFile);
   if ( !useStaticFile ) {
      _ctlcopy_left.p_visible = false;
      _ctlcopy_left_all.p_visible = false;
      _ctlcopy_left_line.p_visible = false;
   }
   if ( version=="" ) {
      _TreeTop();
   } else {
      index = _TreeSearch(TREE_ROOT_INDEX,version"\t",'P');
      if ( index>=0 ) {
         _TreeSetCurIndex(index);
      }else {
         index = _TreeCurIndex();
         cap := _TreeGetCaption(index);
      }
   }
   p_window_id = origWID;
   if ( versionList._length()<2 ) {
      _message_box("You must have at least 2 versions of a file to use this feature");
      p_active_form._delete_window();
      return;
   }
   _SetDialogInfoHt("versionedFile",*pVersionedFile);
   _SetDialogInfoHt("versionList",versionList);
   p_active_form.p_caption = "History Diff - "pVersionedFile->typeCaption()' - 'pVersionedFile->localFilename();
   _post_call(nextDiff,p_active_form);

   _DiffAddWindow(p_active_form,false);
   _SetDialogInfoHt("inOnCreate",0);
}

void _ctlclose.lbutton_up()
{
   curVersionWID := _GetDialogInfoHt("staticFileWID");
   if ( curVersionWID!=null ) {
      if ( curVersionWID.p_modify ) {
         int result=prompt_for_save(nls("Do you wish to save changes to '%s'",curVersionWID.p_buf_name));

         switch (result) {
         case IDNO:
            origWID := p_window_id;
            p_window_id = curVersionWID;
            if (p_undo_steps) {
               while (_undo('C')!=NOTHING_TO_UNDO_RC);
               //This is to be sure that we avoid those rare cases
               //where modify is on and after all steps are undone
               //if the user has specified the -preserve option(s).
               //Also, this will bail'em out if they did not set undo
               //high enough
               p_modify=0;
            }
            p_window_id = origWID;
            clear_message();
            break;
         case IDCANCEL:
            return;
         case IDYES:
            curVersionWID.save();
         }
      }
   }

   if (_GetDialogInfo(DIFFEDIT_CONST_HAS_MODIFY)) {
      if (_GetDialogInfo(DIFFEDIT_CONST_FILE1_MODIFY)) {
         _ctlfile1.p_modify=true;
      }

      if (_GetDialogInfo(DIFFEDIT_CONST_FILE2_MODIFY)) {
         _ctlfile2.p_modify=true;
      }
   }

   p_active_form._delete_window();
}

void _ctlclose.on_destroy()
{
   versionedWIDTable := _GetDialogInfoHt("versionedWIDTable");
   foreach ( auto curKey => auto curWID in versionedWIDTable ) {
      DiffTextChangeCallback(0,curWID.p_buf_id);
      DiffFreeAllColorInfo(curWID.p_buf_id);
      _delete_temp_view(curWID);
   }
   lastOutputBufID := _GetDialogInfoHt("lastOutputBufID");
   if ( lastOutputBufID!=null ) {
      origWID := p_window_id;
      p_window_id = HIDDEN_WINDOW_ID;
      _safe_hidden_window();
      origBufID := p_buf_id;
      status := load_files('+bi 'lastOutputBufID);
      if ( !status ) {
         _delete_buffer();
         load_files('+bi 'origBufID);
      }
      p_window_id = origWID;
   }
   curVersionWID := _GetDialogInfoHt("staticFileWID");
   if ( curVersionWID!=null ) {
      curVersionWID._DiffRemoveImaginaryLines();
      curVersionWID._DiffClearLineFlags();
      DiffFreeAllColorInfo(curVersionWID.p_buf_id);
      DiffTextChangeCallback(0,curVersionWID.p_buf_id);
      _delete_temp_view(curVersionWID);
   }
   _DiffRemoveWindow(p_active_form,false);

   se.vc.IVersionedFile *pVersionedFile = _GetDialogInfoHt("pVersionedFile");
   _control _grabbar_horz;
   if ( *pVersionedFile instanceof se.vc.BackupHistoryVersionedFile ) {
      _append_retrieve(_grabbar_horz, _grabbar_horz.p_y, "_history_diff_backup_history_form._grabbar_horz" );
   } else {
      _append_retrieve(_grabbar_horz, _grabbar_horz.p_y, "_history_diff_form._grabbar_horz" );
   }
}

void _history_diff_form.on_resize()
{
   resizeDialog();
}

static void resizeDialog(typeless formWID="")
{
   origWID := p_window_id;
   if ( formWID!="" ) {
      p_window_id = formWID;
   }
   clientHeight := _dy2ly(SM_TWIP,p_client_height);
   clientWidth := _dx2lx(SM_TWIP,p_client_width);
   bufferX := ctlVersionList.p_x;
   bufferY := ctlVersionList.p_y;

   ctlframe1.p_width = clientWidth - (2*bufferX);
   widthDiv3 := ctlframe1.p_width intdiv 3;
   ctlframe1.p_height = _grabbar_horz.p_y - ctlframe1.p_y;

   ctlVersionList.p_width = widthDiv3;
   ctlminihtml1.p_height = ctlVersionList.p_height = ctlframe1.p_height-(2*bufferY);

   ctlminihtml1.p_x = controlXExtent(ctlVersionList);

   ctlminihtml1.p_width = (widthDiv3 * 2) - (2*bufferX);

   _grabbar_horz.p_x = 0;
   _grabbar_horz.p_width = clientWidth;

   ctlminihtml1.p_y = ctlVersionList.p_y;
   ctlminihtml1.p_height = ctlVersionList.p_height;

   editorArea := clientWidth;

   _ctlfile1.p_x = ctlVersionList.p_x;
   editorWidth := (editorArea-((bufferX)+vscroll1.p_width) ) intdiv 2;
   ctllabel1.p_y = ctllabel2.p_y = controlYExtent(_grabbar_horz)+bufferY;
   _ctlfile1.p_y = _ctlfile2.p_y = vscroll1.p_y = controlYExtent(ctllabel1)+bufferY;
   _ctlfile1.p_width = _ctlfile2.p_width = editorWidth;
   vscroll1.p_x=controlXExtent(_ctlfile1);
   _ctlfile2.p_x = controlXExtent(vscroll1);

   editorHeight := clientHeight-(ctlframe1.p_height+_ctlcopy_left.p_height+ctllabel1.p_height+hscroll1.p_height+_grabbar_horz.p_height+(7*bufferY));
   vscroll1.p_height = _ctlfile1.p_height = _ctlfile2.p_height = editorHeight;
   hscroll1.p_y = controlYExtent(_ctlfile1);
   hscroll1.p_x = _ctlfile1.p_x;
   hscroll1.p_width = editorWidth*2+vscroll1.p_width;


   _ctlclose.p_y = ctlNextDiff.p_y = ctlPrevDiff.p_y = _ctlfind.p_y = controlYExtent(hscroll1)+bufferY;
   ctllabel1.p_x = _ctlfile1.p_x;
   ctllabel2.p_x = _ctlfile2.p_x;

   _ctlcopy_left.p_y = _ctlcopy_left_line.p_y = _ctlcopy_left_all.p_y = _ctlclose.p_y;
   bufferXButton := ctlNextDiff.p_x - controlXExtent(_ctlclose);
   _ctlcopy_left.p_x = _ctlfile2.p_x;
   _ctlcopy_left_line.p_x = controlXExtent(_ctlcopy_left) + bufferXButton;
   _ctlcopy_left_all.p_x = controlXExtent(_ctlcopy_left_line) + bufferXButton;

   p_window_id = origWID;
}

void _grabbar_horz.lbutton_down()
{
   origWID := p_window_id;
   p_window_id = p_active_form;
   clientHeight := _dy2ly(SM_TWIP,p_client_height);
   clientWidth := _dx2lx(SM_TWIP,p_client_width);
   p_window_id = origWID;

   _ul2_image_sizebar_handler(0, clientHeight);
}

void ctlVersionList.on_change(int reason,int index)
{
   loadTreeVersion();
   _ctlfile1.refresh('A');
   _ctlfile2.refresh('A');
}

void ctlNextDiff.lbutton_up()
{
   file1WID := _ctlfile1;
   _DiffNextDifference(_ctlfile1,_ctlfile2);
   if ( _iswindow_valid(file1WID) ) {
      // _DiffNextDifference can call _ctlclose.lbutton_up
      _DiffUpdateScrollThumbs(true);
   }
}

void ctlPrevDiff.lbutton_up()
{
   _DiffNextDifference(_ctlfile1,_ctlfile2,'-');
   _DiffUpdateScrollThumbs(true);
}

void _expand_dir_panel_button.lbutton_up()
{
   p_active_form.resizeDialog();
}

static void showComments()
{
   curIndex := ctlVersionList._TreeCurIndex();
   sibIndex := ctlVersionList._TreeGetNextSiblingIndex(curIndex);
   if ( sibIndex<0 ) return;

   curVersion := ctlVersionList._TreeGetUserInfo(curIndex);
   curPrevVersion := ctlVersionList._TreeGetUserInfo(sibIndex);

   se.vc.IVersionedFile *pVersionedFile = _GetDialogInfoHt("pVersionedFile");
   SVCHistoryInfo curInfo,curPrevInfo;
   pVersionedFile->getHistoryInfo(curVersion,curInfo);
   _SetDialogInfoHt("pVersionedFile",pVersionedFile);

   ctlminihtml1.setInfo(curInfo);
}

static void setInfo(SVCHistoryInfo &info)
{
   text :="";
   if ( info==null ) return;

   if ( info.author!="" ) text=text:+'<B>Author:</B>&nbsp;'info.author'<br>';
   if ( info.date!="" ) text=text:+'<B>Date:</B>&nbsp;'info.date'<br>';
   if ( info.revisionCaption!="" ) {
      // There is a revision caption (git), this is what is displayed in the 
      // tree, so we'll add a revision under the date
      text=text:+'<B>Revision:</B>&nbsp;'info.revision'<br>';
   }
   // Replace comment string line endings with <br> to preserve formatting
   _str commentBR = stranslate(info.comment, '<br>', '\n', 'l');
   if ( commentBR!="" ) {
      text=text:+='<B>Comment:</B>&nbsp;'commentBR;
   }
   if( info.affectedFilesDetails :!= '' ) {
      text=text:+'<br><B>Changed paths:</B><font face="Menlo, Monaco, Consolas, Courier New, Monospace">'info.affectedFilesDetails'</font>';
   }
   p_text = text;
}

static void loadTreeVersionForStaticFile(boolean doFirstDifference)
{
   curIndex := _TreeCurIndex();

   curPrevVersion := _TreeGetUserInfo(curIndex);

   versionedWIDTable := _GetDialogInfoHt("versionedWIDTable");
   origLine := _ctlfile1.p_line;


   se.vc.IVersionedFile versionedFile = _GetDialogInfoHt("versionedFile");
   if ( versionedFile==null ) return;

   ctllabel1.p_caption = 'Version:Current File';
   ctllabel2.p_caption = 'Version:'curPrevVersion;

   int curVersionWID,curPrevVersionWID;
   curVersionWID = _GetDialogInfoHt("staticFileWID");

   if ( curVersionWID==null ) {
      status := _open_temp_view(versionedFile.localFilename(),curVersionWID,auto origWID,def_load_options);
      if (status) {
         _message_box("loadTreeVersion: Could not get local file");
         return;                                                     
      }
      curVersionWID._BlastUndoInfo();
      curVersionWID._undo('S');
      p_window_id = origWID;
      _SetDialogInfoHt("staticFileWID",curVersionWID);
   } else {
      curVersionWID = _GetDialogInfoHt("staticFileWID");
      curVersionWID._DiffRemoveImaginaryLines();
      curVersionWID._DiffClearLineFlags();
      DiffFreeAllColorInfo(curVersionWID.p_buf_id);
   }

   key := versionedFile.localFilename():+PATHSEP:+curPrevVersion;
   if ( versionedWIDTable:[key]==null ) {
      //curPrevVersionWID = DSExtractVersion(versionedFile.localFilename(),curPrevVersion,auto status);
      mou_hour_glass(1);
      status := versionedFile.getFile(curPrevVersion, curPrevVersionWID);
      mou_hour_glass(0);
      if (status) {
         _message_box("loadScrolledVersion:  could not get version "curPrevVersion);
         return;
      }
      versionedWIDTable:[key] = curPrevVersionWID;
      _SetDialogInfoHt("versionedWIDTable",versionedWIDTable);
   } else {
      curPrevVersionWID = versionedWIDTable:[key];
      curPrevVersionWID._DiffRemoveImaginaryLines();
      curPrevVersionWID._DiffClearLineFlags();
      DiffFreeAllColorInfo(curPrevVersionWID.p_buf_id);
   }

   diffScrollMarkupModifiedType := _GetDialogInfoHt("diffScrollMarkupModifiedType",_ctlfile1);
   if (diffScrollMarkupModifiedType!=null) {
      _ScrollMarkupRemoveType(_ctlfile1,diffScrollMarkupModifiedType);
   }
   diffScrollMarkupInsertedType := _GetDialogInfoHt("diffScrollMarkupInsertedType",_ctlfile1);
   if (diffScrollMarkupInsertedType!=null) {
      _ScrollMarkupRemoveType(_ctlfile1,diffScrollMarkupInsertedType);
   }
   diffScrollMarkupDeletedType := _GetDialogInfoHt("diffScrollMarkupDeletedType",_ctlfile1);
   if (diffScrollMarkupDeletedType!=null) {
      _ScrollMarkupRemoveType(_ctlfile1,diffScrollMarkupDeletedType);
   }

   _ctlfile1.load_files('+bi 'curVersionWID.p_buf_id);
   _ctlfile2.load_files('+bi 'curPrevVersionWID.p_buf_id);

   _DiffSetupScrollBars();
   vscroll1._ScrollMarkupSetAssociatedEditor(_ctlfile1);
   _ctlfile1._DiffClearLineFlags();
   _ctlfile2._DiffClearLineFlags();

   curVersionWID._BlastUndoInfo();
   curPrevVersionWID._BlastUndoInfo();

   langID := _Filename2LangId(versionedFile.localFilename());
   _ctlfile1._SetEditorLanguage(langID);
   _ctlfile2._SetEditorLanguage(langID);

   mou_hour_glass(1);
   Diff(_ctlfile1,
        _ctlfile2,
        def_diff_options,
        0,0,0,
        def_load_options,
        0,0,
        def_max_fast_diff_size,
        1,1,
        def_smart_diff_limit,null);
   mou_hour_glass(0);

   // If these are the first two buffers, we know the dialog just came up.
   // Find the first difference
   if ( versionedWIDTable._length()==2||doFirstDifference ) {
      _ctlfile1.top();
      _ctlfile2.top();
      _DiffNextDifference(_ctlfile1,_ctlfile2);
   } else {
      origWID := p_window_id;
      p_window_id = _ctlfile1;
      p_line = origLine;
      set_scroll_pos(p_left_edge,p_client_height intdiv 2);
      p_window_id = _ctlfile2;
      p_line = origLine;
      set_scroll_pos(p_left_edge,p_client_height intdiv 2);
      p_window_id = origWID;
   }
   _ctlfile2._DiffSetReadOnly(1);
   _DiffUpdateScrollThumbs(true);
   showComments();
}

static void loadTreeVersion(boolean doFirstDifference=false)
{
   inOnCreate := _GetDialogInfoHt("inOnCreate");
   if ( inOnCreate==1 ) {
      return;
   }
   useStaticFile := _GetDialogInfoHt("useStaticFile");

   if ( useStaticFile ) {
      loadTreeVersionForStaticFile(doFirstDifference);
      return;
   }
   curIndex := _TreeCurIndex();
   if ( curIndex==TREE_ROOT_INDEX ) return;

   sibIndex := _TreeGetNextSiblingIndex(curIndex);
   if ( sibIndex<0 ) {
      curIndex = _TreeGetPrevIndex(curIndex);
      sibIndex = _TreeGetNextSiblingIndex(curIndex);
   }

   curVersion := _TreeGetUserInfo(curIndex);
   curPrevVersion := _TreeGetUserInfo(sibIndex);

   versionedWIDTable := _GetDialogInfoHt("versionedWIDTable");
   origLine := _ctlfile1.p_line;

   se.vc.IVersionedFile versionedFile = _GetDialogInfoHt("versionedFile");
   if ( versionedFile==null ) return;

   if ( useStaticFile==true ) {
      ctllabel1.p_caption = 'Version:Current File';
   } else {
      ctllabel1.p_caption = 'Version:'curVersion;
   }
   ctllabel2.p_caption = 'Version:'curPrevVersion;
   int curVersionWID,curPrevVersionWID;
   if ( useStaticFile==true ) {
      curVersionWID = _GetDialogInfoHt("staticFileWID");
      if ( curVersionWID==null ) {
         status := _open_temp_view(versionedFile.localFilename(),curVersionWID,auto origWID,def_load_options);
         if (status) {
            _message_box("loadTreeVersion: Could not get local file");
            return;                                                     
         }
         curVersionWID._BlastUndoInfo();
         curVersionWID._undo('S');
         p_window_id = origWID;
         _SetDialogInfoHt("staticFileWID",curVersionWID);
      } else {
         curVersionWID = _GetDialogInfoHt("staticFileWID");
         curVersionWID._DiffRemoveImaginaryLines();
         curVersionWID._DiffClearLineFlags();
         DiffFreeAllColorInfo(curVersionWID.p_buf_id);
      }
   } else {
      key := versionedFile.localFilename():+PATHSEP:+curVersion;
      if ( versionedWIDTable:[key]==null ) {
         //curVersionWID = DSExtractVersion(versionedFile.localFilename(),curVersion,auto status);
         mou_hour_glass(1);
         status := versionedFile.getFile(curVersion,curVersionWID);
         mou_hour_glass(0);
         if (status) {
            _message_box("loadScrolledVersion:  could not get version "curVersion);
            return;
         }
         versionedWIDTable:[key] = curVersionWID;
         _SetDialogInfoHt("versionedWIDTable",versionedWIDTable);
      } else {
         curVersionWID = versionedWIDTable:[key];
         curVersionWID._DiffRemoveImaginaryLines();
         curVersionWID._DiffClearLineFlags();
         DiffFreeAllColorInfo(curVersionWID.p_buf_id);
      }
   }

   key := versionedFile.localFilename():+PATHSEP:+curPrevVersion;
   if ( versionedWIDTable:[key]==null ) {
      //curPrevVersionWID = DSExtractVersion(versionedFile.localFilename(),curPrevVersion,auto status);
      mou_hour_glass(1);
      status := versionedFile.getFile(curPrevVersion, curPrevVersionWID);
      mou_hour_glass(0);
      if (status) {
         _message_box("loadScrolledVersion:  could not get version "curVersion);
         return;
      }
      versionedWIDTable:[key] = curPrevVersionWID;
      _SetDialogInfoHt("versionedWIDTable",versionedWIDTable);
   } else {
      curPrevVersionWID = versionedWIDTable:[key];
      curPrevVersionWID._DiffRemoveImaginaryLines();
      curPrevVersionWID._DiffClearLineFlags();
      DiffFreeAllColorInfo(curPrevVersionWID.p_buf_id);
   }

   diffScrollMarkupModifiedType := _GetDialogInfoHt("diffScrollMarkupModifiedType",_ctlfile1);
   if (diffScrollMarkupModifiedType!=null) {
      _ScrollMarkupRemoveType(_ctlfile1,diffScrollMarkupModifiedType);
   }
   diffScrollMarkupInsertedType := _GetDialogInfoHt("diffScrollMarkupInsertedType",_ctlfile1);
   if (diffScrollMarkupInsertedType!=null) {
      _ScrollMarkupRemoveType(_ctlfile1,diffScrollMarkupInsertedType);
   }
   diffScrollMarkupDeletedType := _GetDialogInfoHt("diffScrollMarkupDeletedType",_ctlfile1);
   if (diffScrollMarkupDeletedType!=null) {
      _ScrollMarkupRemoveType(_ctlfile1,diffScrollMarkupDeletedType);
   }

   _ctlfile1.load_files('+bi 'curVersionWID.p_buf_id);
   _ctlfile2.load_files('+bi 'curPrevVersionWID.p_buf_id);
   _DiffSetupScrollBars();
   vscroll1._ScrollMarkupSetAssociatedEditor(_ctlfile1);
   _ctlfile1._DiffClearLineFlags();
   _ctlfile2._DiffClearLineFlags();

   curVersionWID._BlastUndoInfo();
   curPrevVersionWID._BlastUndoInfo();

   langID := _Filename2LangId(versionedFile.localFilename());
   _ctlfile1._SetEditorLanguage(langID);
   _ctlfile2._SetEditorLanguage(langID);

   mou_hour_glass(1);
   Diff(_ctlfile1,
        _ctlfile2,
        def_diff_options,
        0,0,0,
        def_load_options,
        0,0,
        def_max_fast_diff_size,
        1,1,
        def_smart_diff_limit,null);
   mou_hour_glass(0);

   // If these are the first two buffers, we know the dialog just came up.
   // Find the first difference
   if ( versionedWIDTable._length()==2||doFirstDifference ) {
      _ctlfile1.top();
      _ctlfile2.top();
      _DiffNextDifference(_ctlfile1,_ctlfile2);
   } else {
      origWID := p_window_id;
      p_window_id = _ctlfile1;
      p_line = origLine;
      set_scroll_pos(p_left_edge,p_client_height intdiv 2);
      p_window_id = _ctlfile2;
      p_line = origLine;
      set_scroll_pos(p_left_edge,p_client_height intdiv 2);
      p_window_id = origWID;
   }
   if ( !useStaticFile ) {
      _ctlfile1._DiffSetReadOnly(1);
   }
   _ctlfile2._DiffSetReadOnly(1);
   _DiffUpdateScrollThumbs(true);

   showComments();
}

_command void history_diff_machine(_str filename="") name_info(',')
{
   if ( _no_child_windows() ) {
      _message_box("A file must be open to use this command");
      return;
   }
   if ( filename=="" ) {
      filename = _mdi.p_child.p_buf_name;
   }
   se.vc.BackupHistoryVersionedFile backupHistoryFile(filename);
   show('-modal -xy  _history_diff_form',&backupHistoryFile);
}

_command void history_diff_machine_file(_str filename="") name_info(',')
{
   if ( _no_child_windows() ) {
      _message_box("A file must be open to use this command");
      return;
   }
   if ( filename=="" ) {
      filename = _mdi.p_child.p_buf_name;
   }
   se.vc.BackupHistoryVersionedFile backupHistoryFile(filename);
   show('-modal -xy  _history_diff_form',&backupHistoryFile,true);
}

void _HistoryDiffBackupHistoryFile(_str filename,_str version)
{
   se.vc.BackupHistoryVersionedFile backupHistoryFile(filename);
   show('-modal -xy  _history_diff_form',&backupHistoryFile,version,true);
}
