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
#require 'se/vc/IVersionedFile.e'
#import 'se/tags/TaggingGuard.e'
#import 'se/vc/BackupHistoryVersionedFile.e'
#import 'se/vc/SVNVersionedFile.e'
#import 'codehelp.e'
#import 'context.e'
#import 'files.e'
#import 'guiopen.e'
#import 'diff.e'
#import 'diffedit.e'
#import "help.e"
#import 'listbox.e'
#import 'main.e'
#import 'picture.e'
#import 'saveload.e'
#import 'sellist.e'
#import 'stdcmds.e'
#import 'stdprocs.e'
#import 'tags.e'
#import 'treeview.e'
#endregion Imports

defeventtab _history_diff_form;
void ctltypetoggle.lbutton_up()
{
   if ( !_haveProDiff() ) {
      return;
   }
   if ( p_caption == "Source Diff" ) {
      p_caption = "Line Diff";
   } else if ( p_caption == "Line Diff" ) {
      p_caption = "Source Diff";
   }
   _ctlfile1._undo('S');
   _ctlfile2._undo('S');
   ctlVersionList.loadTreeVersion(false);
}

void ctlcomment.lbutton_up()
{
   se.vc.IVersionedFile *pVersionedFile = _GetDialogInfoHt("pVersionedFile");
   if ( pVersionedFile==null ) return;
   version := getCurrentVersionFromList();
   if ( version<0 ) return;
   filename := pVersionedFile->localFilename();
   comment := "";
   pVersionedFile->getHistoryInfo(version,auto info);
   if ( info.comment != null ) {
      comment = info.comment;
   }

   int result=show('-modal -xy _tbdeltacomments_form',filename,comment,version);
   if ( result=='' ) {
      return;
   }
   comment = strip(_param1, 'T');
   if (comment != null) {
      pVersionedFile->setComment(version,comment);
   }
   thirdFieldIsComment := _GetDialogInfoHt("thirdFieldIsComment");
   if (thirdFieldIsComment==true) {
      setCommentInList(comment);
   }
   info.comment = comment;
   ctlminihtml1.setInfo(info);
}

void ctlopen.lbutton_up()
{
   se.vc.IVersionedFile *pVersionedFile = _GetDialogInfoHt("pVersionedFile");
   if ( pVersionedFile==null ) return;
   version := getCurrentVersionFromList();
   if ( version<0 ) return;
   status := pVersionedFile->getFile(version,auto fileWID);
   if ( !status ) {
      fileWID.p_DocumentName = "Version "version" of "pVersionedFile->localFilename();
      fileWID.p_modify = true;
      _mdi.p_child.edit('+bi 'fileWID.p_buf_id);
   }
}

static _str getCurrentVersionFromList()
{
   version := -1;
   origWID := p_window_id;
   _control ctlVersionList;
   p_window_id = ctlVersionList;
   index := _TreeCurIndex();
   cap := _TreeGetCaption(index);
   parse cap with version "\t" .;
   if ( isinteger(cap) ) version = (int) cap;
   p_window_id = origWID;
   return version;
}

static _str getVersionBelowFromList()
{
   version := -1;
   origWID := p_window_id;
   _control ctlVersionList;
   p_window_id = ctlVersionList;
   index := _TreeCurIndex();
   if ( index<0 ) return -1;
   index = _TreeGetNextIndex(index);
   if ( index<0 ) return -1;
   cap := _TreeGetCaption(index);
   parse cap with version "\t" .;
   if ( isinteger(cap) ) version = (int) cap;
   p_window_id = origWID;
   return version;
}

static int setCommentInList(_str comment)
{
   version := -1;
   origWID := p_window_id;
   _control ctlVersionList;
   p_window_id = ctlVersionList;
   index := _TreeCurIndex();
   cap := _TreeGetCaption(index);
   parse cap with version "\t" auto date "\t" .;
   _TreeSetCaption(index,comment,2);
   p_window_id = origWID;
   return version;
}

void ctlsave_as.lbutton_up()
{
   format_list := "Current Format,DOS Format,UNIX Format,Macintosh Format";
   unixflags := 0;
   if (_isUnix()) {
      _str attrs=file_list_field(_ctlfile1.p_buf_name,DIR_ATTR_COL,DIR_ATTR_WIDTH);
      w := pos('w',attrs,'','i');
      if (!w && attrs!='') {
         unixflags=OFN_READONLY;
      }
   }
   se.vc.IVersionedFile *pVersionedFile = _GetDialogInfoHt("pVersionedFile");
   if ( pVersionedFile==null ) return;
   filename := pVersionedFile->localFilename();
   _str init_filename;
   if (_FileQType(filename)==VSFILETYPE_NORMAL_FILE) {
      init_filename=_maybe_quote_filename(filename);
   } else {
      init_filename=_maybe_quote_filename(_strip_filename(filename,'P'));
   }
   typeless result=_OpenDialog('-new -modal',
                               'Save As',
                               '',     // Initial wildcards
                               format_list,  // file types
                               OFN_SAVEAS|OFN_SAVEAS_FORMAT|OFN_KEEPOLDFILE|OFN_PREFIXFLAGS|OFN_ADD_TO_PROJECT|unixflags,
                               def_ext,      // Default extensions
                               init_filename, // Initial filename
                               '',      // Initial directory
                               '',      // Reserved
                               "Save As dialog box"
                              );
   //messageNwait('_param1='_param1);
   if (result=='') {
      return;
   }
   _ctlfile2._save_file(result);
}

void _history_diff_form.on_load()
{
   se.vc.IVersionedFile *pVersionedFile = _GetDialogInfoHt("pVersionedFile");
   retrieveValueGrabBarHorz := 0;

   if ( *pVersionedFile instanceof se.vc.BackupHistoryVersionedFile ) {
      retrieveValueGrabBarHorz = _moncfg_retrieve_value( "_history_diff_backup_history_form._grabbar_horz" );
   } else {
      retrieveValueGrabBarHorz = _moncfg_retrieve_value( "_history_diff_form._grabbar_horz" );
   }

   if (retrieveValueGrabBarHorz != null && isinteger(retrieveValueGrabBarHorz)) _grabbar_horz.p_y = retrieveValueGrabBarHorz;
}

void _ctlclose.on_create(se.vc.IVersionedFile *pVersionedFile=null,_str version="",
                         bool useStaticFile=false,bool thirdFieldIsComment=false)
{
   _SetDialogInfoHt("inOnCreate",1);
   _SetDialogInfoHt("inOnResize",0);
   if ( !_haveProDiff() ) {
      ctltypetoggle.p_enabled = false;
      ctltypetoggle.p_visible = false;
      // Move help button to left one button
      ctltypetoggle.p_next.p_x = ctltypetoggle.p_x;
   }
   _SetDialogInfoHt("pVersionedFile",pVersionedFile);
   localFilename := pVersionedFile->localFilename();
   status := DSUpgradeArchive(localFilename);
   status = pVersionedFile->enumerateVersions(auto versionList);
   if ( status ) {
      p_active_form._delete_window();
      return;
   }
   origWID := p_window_id;
   _control ctlVersionList;
   p_window_id = ctlVersionList;
   index := TREE_ROOT_INDEX;
   flags := TREE_ADD_AS_CHILD;
   len := versionList._length();

   colWidth := ctlVersionList.p_width intdiv 3;
   ctlVersionList._TreeSetColButtonInfo(0, colWidth, -1, -1, 'Version');
   ctlVersionList._TreeSetColButtonInfo(1, colWidth, TREE_BUTTON_AL_CENTER, -1, 'Date');
   if ( thirdFieldIsComment ) {
      ctlVersionList._TreeSetColButtonInfo(2, colWidth, -1, -1, 'Comment');
   } else {
      ctlVersionList._TreeSetColButtonInfo(2, colWidth, -1, -1, 'Author');
   }
   firstIndex := -1;
   for ( i:=0;i<len;++i ) {
      //pVersionedFile->getVersionInfo(versionList[i],auto versionInfo="");
      //parse versionInfo with auto date auto time .;
      SVCHistoryInfo info;
      pVersionedFile->getHistoryInfo(versionList[i],info);
      date := "";
      if ( info.date != null ) {
         date = info.date;
      }
      if ( info!=null && info.date!=null && info.comment!=null && thirdFieldIsComment  ) {
         index = _TreeAddItem(index,versionList[i]"\t"date"\t"info.comment,flags,_pic_file,_pic_file,TREE_NODE_LEAF,0,versionList[i]);
         _setDateForTreeFromVCString(index,1,date);
      } else if ( info!=null && info.date!=null && info.author!=null ) {
         index = _TreeAddItem(index,versionList[i]"\t"date"\t"info.author,flags,_pic_file,_pic_file,TREE_NODE_LEAF,0,versionList[i]);
         _setDateForTreeFromVCString(index,1,date);
      } else if ( info!=null && info.date!=null ) {
         index = _TreeAddItem(index,versionList[i]"\t"date,flags,_pic_file,_pic_file,TREE_NODE_LEAF,0,versionList[i]);
         _setDateForTreeFromVCString(index,1,date);
      } else {
         index = _TreeAddItem(index,versionList[i],flags,_pic_file,_pic_file,TREE_NODE_LEAF,0,versionList[i]);
      }
      firstIndex = index;
      flags = TREE_ADD_BEFORE;
      if ( ctltype_combo.p_text==LOCAL_FILE_CAPTION ) {
         // Maybe Disable last item
         if (i==0) {
            _TreeGetInfo(index,auto state, auto bm1, auto bm2,auto nodeFlags);
            _TreeSetInfo(index,state,bm1,bm2,nodeFlags|TREENODE_DISABLED);
         }
      }
   }
   //if (!useStaticFile) {
   //   index = _TreeAddItem(index,LOCAL_FILE_CAPTION,flags,_pic_file,_pic_file,TREE_NODE_LEAF,0,-1);
   //}
   _SetDialogInfoHt("useStaticFile",useStaticFile);
   _SetDialogInfoHt("thirdFieldIsComment",thirdFieldIsComment);
   if ( !useStaticFile ) {
      _ctlcopy_left.p_visible = false;
      _ctlcopy_left_all.p_visible = false;
      _ctlcopy_left_line.p_visible = false;
   }
   if ( version=="" ) {
      if ( firstIndex>=0 ) {
         _TreeSetCurIndex(firstIndex);
      }
   } else {
      index = _TreeSearch(TREE_ROOT_INDEX,version"\t",'P');
      if ( index>=0 ) {
         _TreeSetCurIndex(index);
      } else {
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
   typeCaption := pVersionedFile->typeCaption();
   if ( lowcase(typeCaption)=="backup history" ) {
      p_active_form.p_caption = "Backup History - "pVersionedFile->localFilename(version);
   } else {
      p_active_form.p_caption = "History Diff - "pVersionedFile->typeCaption()' - 'pVersionedFile->localFilename(version);
   }

   _DiffAddWindow(p_active_form,false);
   _SetDialogInfoHt("inOnCreate",0);

   // Delete blank buffers that came with the editor controls
   _ctlfile1._delete_buffer();
   _ctlfile2._delete_buffer();

   // Have to set up info so we get things right when _ctlfile1.on_destroy is
   // called.
   DIFF_MISC_INFO misc;
   InitMiscDiffInfo(misc, 'historydiff');
   _SetDialogInfo(DIFFEDIT_CONST_MISC_INFO, misc, _ctlfile1);

   status = ctlVersionList.loadTreeVersion(true);
   if ( status ) {
      // Don't do cleanup
      _SetDialogInfoHt("noOnDestroy",1);
      p_active_form._delete_window();
      return;
   }
   if ( pVersionedFile->commandsAvailable()&se.vc.VFC_SETCOMMENT ) {
      ctlcomment.p_visible = true;
      ctlopen.p_visible = true;
   } else {
      ctlcomment.p_visible = false;
      ctlopen.p_visible = false;
   }

   _ctlfile1.p_MouseActivate=MA_ACTIVATE;
   _ctlfile2.p_MouseActivate=MA_ACTIVATE;

   _ctlfile1._DiffSetWindowFlags();
   _ctlfile2._DiffSetWindowFlags();
   // This is important, without it bookmarks set by using the current context
   // combo boxes will not be cleared.
   _SetDialogInfo(DIFFEDIT_CONST_BUFFER_INFO1,_ctlfile1.p_buf_id' 0 0',_ctlfile1);
   _SetDialogInfo(DIFFEDIT_CONST_BUFFER_INFO2,_ctlfile2.p_buf_id' 0 0',_ctlfile1);
   _SetDialogInfoHt("inOnCreate",0);
}

void _setDateForTreeFromVCString(int index,int col,_str datestr)
{
   year := "";
   month:= "";
   date := "";
   hh   := "";
   mm   := "";
   secs := "";
   if ( !pos('/',datestr) && !pos('-',datestr) ) {
      datestr = strftime("%m/%d/%y %H:%M:%S",datestr);
      parse datestr with month'/'date '/' year  hh':' mm':' secs;
   } else {
      parsech := '/';
      if ( pos('-',datestr) ) parsech = "-";
      parse datestr with year (parsech) month (parsech) date  hh':' mm':' secs;
   }
   if ( length(year)==2 ) {
      if ( year<88 ) {
         year = "20"year;
      } else {
         year = "19"year;
      }
   }
   secs = substr(secs,1,2);
   if ( isinteger(year) && 
        isinteger(month) &&
        isinteger(date) &&
        isinteger(hh) &&
        isinteger(mm) &&
        isinteger(secs) ) {
      _TreeSetDateTime(index,col,(int)year,(int)month,(int)date,(int)hh,(int)mm,(int)secs);
   }
}

void _ctlclose.lbutton_up()
{
   if ( _ctlfile1.p_modify && ctltype_combo.p_text==LOCAL_FILE_CAPTION ) {
      DIFF_MISC_INFO misc = _DiffGetMiscInfo();
      filename := _diffGetFilenameFromDialog(misc,'1');
      int result=prompt_for_save(nls("Do you wish to save changes to '%s'",filename));
      
      switch (result) {
      case IDNO:
#if 0 //12:56pm 10/2/2018
            // 10/2/2018
            // Don't have to do this because this buffer is a copy.  If we're 
            // not saving it we don't have to worry about this
            origWID := p_window_id;
            p_window_id = curVersionWID;
            if (p_undo_steps) {
               while (_undo('C')!=NOTHING_TO_UNDO_RC);
               //This is to be sure that we avoid those rare cases
               //where modify is on and after all steps are undone
               //if the user has specified the -preserve option(s).
               //Also, this will bail'em out if they did not set undo
               //high enough
               p_modify=false;
            }
            p_window_id = origWID;
            clear_message();
#endif
            break;
      case IDCANCEL:
         return;
      case IDYES:
         _ctlfile1._diff_save();
         break;
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

static int gChangeSelectedTimer = -1;

void _ctlclose.on_destroy()
{
   if ( gChangeSelectedTimer>=0 ) {
      _kill_timer(gChangeSelectedTimer);
      gChangeSelectedTimer = -1;
   }
   if ( _GetDialogInfoHt("noOnDestroy")==1 ) return;
   versionedWIDTable := _GetDialogInfoHt("versionedWIDTable");
   _ctlfile1.load_files('+b .command');
   _ctlfile2.load_files('+b .command');
   foreach ( auto curKey => auto curWID in versionedWIDTable ) {
      if (curWID!=null && curWID!=0) {
         DiffTextChangeCallback(0,curWID.p_buf_id);
         DiffFreeAllColorInfo(curWID.p_buf_id);
         _delete_temp_view(curWID);
      }
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
      curVersionWID_SoftWrap := _GetDialogInfoHt("staticFileHadSoftWrap");
      if (curVersionWID_SoftWrap!=null) {
         curVersionWID.p_SoftWrap = curVersionWID_SoftWrap;
      }
      DiffFreeAllColorInfo(curVersionWID.p_buf_id);
      DiffTextChangeCallback(0,curVersionWID.p_buf_id);

      _delete_temp_view(curVersionWID);
   }
   _DiffRemoveWindow(p_active_form,false);

   se.vc.IVersionedFile *pVersionedFile = _GetDialogInfoHt("pVersionedFile");
   _control _grabbar_horz;

   // We only want one version stored for the these combo boxes, so save/restore
   // def_maxcombohist and temporarily set it to 1
   origMaxComboHist := def_maxcombohist;
   def_maxcombohist = 1;
   if ( *pVersionedFile instanceof se.vc.BackupHistoryVersionedFile ) {
      _moncfg_append_retrieve(_grabbar_horz, _grabbar_horz.p_y, "_history_diff_backup_history_form._grabbar_horz" );
      _moncfg_append_retrieve( ctltype_combo, ctltype_combo.p_text, "_history_diff_backup_history_form.ctltype_combo" );
   } else {
      _moncfg_append_retrieve(_grabbar_horz, _grabbar_horz.p_y, "_history_diff_form._grabbar_horz" );
      _moncfg_append_retrieve( ctltype_combo, ctltype_combo.p_text, "_history_diff_form.ctltype_combo" );
   }
   def_maxcombohist = origMaxComboHist;

   DIFF_MISC_INFO misc = _DiffGetMiscInfo();
   if ( misc!=null && misc.MarkId1!=-1 ) {
      _free_selection(misc.MarkId1);
   }
}

void _history_diff_form.on_resize()
{
   inOnResize := _GetDialogInfoHt("inOnResize");
   if (inOnResize==null) {
      inOnResize = 0;
   }
   ++inOnResize;
   _SetDialogInfoHt("inOnResize",inOnResize);
   resizeDialog();
   --inOnResize;
   _SetDialogInfoHt("inOnResize",inOnResize);
}
 
static void resizeDialog(typeless formWID="")
{
   origWID := p_window_id;
   if ( formWID!="" ) {
      p_window_id = formWID;
   }
   if ( !(p_window_flags & VSWFLAG_ON_RESIZE_ALREADY_CALLED) ) {
      ctlVersionList._TreeSizeColumnToContents(-1);
   }
   clientHeight := _dy2ly(SM_TWIP,p_active_form.p_client_height);
   clientWidth := _dx2lx(SM_TWIP,p_active_form.p_client_width);
   bufferX := ctlVersionList.p_x;
   bufferY := ctlVersionList.p_y;

   ctlframe1.p_width = clientWidth - (2*bufferX);
   widthDiv3 := ctlframe1.p_width intdiv 3;
   ctlframe1.p_y_extent = _grabbar_horz.p_y ;

   ctlVersionList.p_width = widthDiv3;
   ctlminihtml1.p_height = ctlVersionList.p_height = ctlframe1.p_height-(2*bufferY);

   ctlminihtml1.p_x = ctlVersionList.p_x_extent;

   ctlminihtml1.p_width = (widthDiv3 * 2) - (2*bufferX);

   _grabbar_horz.p_x = 0;
   _grabbar_horz.p_width = clientWidth;

   ctlminihtml1.p_y = ctlVersionList.p_y;
   ctlminihtml1.p_height = ctlVersionList.p_height;

   editorArea := clientWidth;

   _ctlfile1.p_x = ctlVersionList.p_x;
   editorWidth := (editorArea-((bufferX)+vscroll1.p_width) ) intdiv 2;
   ctltype_combo.p_y = ctllabel1.p_y = ctllabel2.p_y = _grabbar_horz.p_y_extent+bufferY;
   ctltype_combo.p_width = _ctlfile1.p_x_extent-ctltype_combo.p_x;
   ctllabel2.p_y = ctllabel1.p_y;
   ctlcontextCombo1.p_y = ctlcontextCombo2.p_y = ctltype_combo.p_y_extent+bufferY;
   ctlcontextCombo1.p_width = ctlcontextCombo2.p_width = _ctlfile1.p_width = _ctlfile2.p_width = editorWidth;
   
   if (_haveCurrentContextToolBar() && !(def_diff_edit_flags&DIFFEDIT_HIDE_CURRENT_CONTEXT)) {
      _ctlfile1.p_y = _ctlfile2.p_y = vscroll1.p_y = ctlcontextCombo1.p_y_extent+bufferY;
   } else {
      _ctlfile1.p_y = _ctlfile2.p_y = vscroll1.p_y = ctlcontextCombo1.p_y;
      ctlcontextCombo1.p_height=0;
   }

   vscroll1.p_x=_ctlfile1.p_x_extent;
   _ctlfile2.p_x = vscroll1.p_x_extent;

   editorHeight := clientHeight-(ctlframe1.p_height+_ctlcopy_left.p_height+ctltype_combo.p_height+ctlcontextCombo1.p_height+hscroll1.p_height+_grabbar_horz.p_height+(9*bufferY));
   vscroll1.p_height = _ctlfile1.p_height = _ctlfile2.p_height = editorHeight;
   hscroll1.p_y = _ctlfile1.p_y_extent;
   hscroll1.p_x = _ctlfile1.p_x;
   hscroll1.p_width = editorWidth*2+vscroll1.p_width;

   ctlcomment.p_y = ctlopen.p_y = ctlsave_as.p_y = _ctlclose.p_y = ctlNextDiff.p_y = ctlPrevDiff.p_y = ctltypetoggle.p_y = ctltypetoggle.p_next.p_y = _ctlfind.p_y = hscroll1.p_y_extent+bufferY;
   ctllabel1.p_x = ctlcontextCombo1.p_x = _ctlfile1.p_x;
   ctllabel2.p_x = ctlcontextCombo2.p_x = _ctlfile2.p_x;

   _ctlcopy_left.p_y = _ctlcopy_left_line.p_y = _ctlcopy_left_all.p_y = _ctlclose.p_y;
   bufferXButton := ctlNextDiff.p_x - _ctlclose.p_x_extent;
   _ctlcopy_left.p_x = _ctlfile2.p_x;
   _ctlcopy_left_line.p_x = _ctlcopy_left.p_x_extent + bufferXButton;
   _ctlcopy_left_all.p_x = _ctlcopy_left_line.p_x_extent + bufferXButton;
   if ( !_ctlcopy_left.p_visible ) {
      ctlsave_as.p_x = _ctlcopy_left.p_x;
      ctlopen.p_x = _ctlcopy_left_line.p_x;
      ctlcomment.p_x = _ctlcopy_left_all.p_x;
   } else {
      ctlsave_as.p_x = _ctlcopy_left_all.p_x_extent + bufferXButton;
      ctlopen.p_x = ctlsave_as.p_x_extent + bufferXButton;
      ctlcomment.p_x = ctlopen.p_x_extent + bufferXButton;
   }

   buttonBuffer := ctlNextDiff.p_x-_ctlclose.p_x_extent;

   _ctlcopy_left_line.p_x = _ctlcopy_left.p_x_extent+buttonBuffer;
   _ctlcopy_left_all.p_x  = _ctlcopy_left_line.p_x_extent+buttonBuffer;
   ctlsave_as.p_x = _ctlcopy_left_all.p_x_extent+buttonBuffer;
   ctlopen.p_x = ctlsave_as.p_x_extent+buttonBuffer;
   ctlcomment.p_x = ctlopen.p_x_extent+buttonBuffer;

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

static void treeChangeSelectedCallback(_str info)
{
   if ( gChangeSelectedTimer>=0 ) {
      _kill_timer(gChangeSelectedTimer);
      gChangeSelectedTimer = -1;
   }
   parse info with auto WID auto index;
   origWID := p_window_id;
   p_window_id = (int)WID;
   curIndex := _TreeCurIndex();
   if ( curIndex != index ) {
      p_window_id = origWID;
      return;
   }

   loadTreeVersion();
   refresh('A');

   p_window_id = origWID;
}

void ctlVersionList.on_change(int reason,int index)
{
   inOnCreate := _GetDialogInfoHt("inOnCreate");
   if ( inOnCreate==1 ) return;

   if (reason==CHANGE_SELECTED) {
      if (gChangeSelectedTimer>0) {
         _kill_timer(gChangeSelectedTimer);
         gChangeSelectedTimer = -1;
      }
      gChangeSelectedTimer = _set_timer(400,treeChangeSelectedCallback,p_window_id' 'index);
   }
}

_command void history_diff_context_menu_command(_str command="") name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   if (!_haveBackupHistory()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION_1ARG, "Backup History");
      return;
   }
   changed := false;
   useStaticFile := _GetDialogInfoHt("useStaticFile");
   switch ( command ) {
   case "incremental":
      _SetDialogInfoHt("useStaticFile",0);
      changed = true;
      break;
   case "static":
      _SetDialogInfoHt("useStaticFile",1);
      changed = true;
      break;
   }
   if ( changed ) {
      loadTreeVersion();
      _ctlfile1.refresh('A');
      _ctlfile2.refresh('A');
   }
}

void ctlNextDiff.lbutton_up()
{
   file1WID := _ctlfile1;
   _DiffNextDifference(_ctlfile1,_ctlfile2,'','',false);
   if ( _iswindow_valid(file1WID) ) {
      // _DiffNextDifference can call _ctlclose.lbutton_up
      _DiffUpdateScrollThumbs(true);
      _DiffSetNeedRefresh(true);
   }
}

void ctlPrevDiff.lbutton_up()
{
   _DiffNextDifference(_ctlfile1,_ctlfile2,'-','',false);
   _DiffUpdateScrollThumbs(true);
   _DiffSetNeedRefresh(true);
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
   text := "";
   if ( info==null ) return;

   if ( info.author!="" ) text :+= '<B>Author:</B>&nbsp;'info.author'<br>';
   if ( info.date!="" && info.date != 0 ) text :+= '<B>Date:</B>&nbsp;':+info.date:+'<br>';
   if ( info.revisionCaption!="" ) {
      // There is a revision caption (git), this is what is displayed in the 
      // tree, so we'll add a revision under the date
      text :+= '<B>Revision:</B>&nbsp;'info.revision'<br>';
   }
   // Replace comment string line endings with <br> to preserve formatting
   commentBR := stranslate(info.comment, '<br>', '\n', 'l');
   if ( commentBR!="" ) {
      text :+= '<B>Comment:</B>&nbsp;'commentBR;
   }
   if ( info.affectedFilesDetails!=null && info.affectedFilesDetails :!= '' ) {
      text :+= '<br><B>Changed `paths:</B><font face="Menlo, Monaco, Consolas, Courier New, Monospace">'info.affectedFilesDetails'</font>';
   }
   static int callbackIndex;
   if ( callbackIndex==0 ) {
      callbackIndex = find_index('_svc_format_html',PROC_TYPE);
   }
   if ( callbackIndex && index_callable(callbackIndex) ) {
      call_index(text,callbackIndex);
   }
   p_text = text;
}

int gDiffSkipUpdateCallback = 0;

void ctltype_combo.on_change(int reason)
{
   if (_GetDialogInfoHt("initializingComboBox")==1) return;

   if ( p_text == LOCAL_FILE_CAPTION ) {
      _SetDialogInfoHt("useStaticFile",1);
      ctlVersionList.history_diff_context_menu_command("static");
   } else {
      _SetDialogInfoHt("useStaticFile",0);
      ctlVersionList.history_diff_context_menu_command("incremental");
   }
}

static void setupTypeComboBox(_str version,bool setVersionCurrent)
{
   if (_GetDialogInfoHt("initializingComboBox")==1) return;
   _SetDialogInfoHt("initializingComboBox",1);
   do {
      if ( ctltype_combo._lbsearch(version)==0 ) {
         break;
      }
      ctltype_combo._lbclear();
      ctltype_combo._lbadd_item(LOCAL_FILE_CAPTION);
      ctltype_combo._lbadd_item(version);
      if (setVersionCurrent) {
         ctltype_combo.p_text = version;
      }
   } while (false);

   _SetDialogInfoHt("initializingComboBox",0);
}

#if 0
static int _countWindows(int bufID)
{
   count :=0;
   mdiChild := 0;
   for (i:=1;i<=_last_window_id();++i) {
      if ( _iswindow_valid(i) &&
           i != HIDDEN_WINDOW_ID &&
           i.p_object==OI_EDITOR &&
          i.p_HasBuffer && i.p_buf_id == bufID && !i.p_IsMinimap && !i.p_IsTempEditor && !(i.p_buf_flags&VSBUFFLAG_HIDDEN) ) {
         if (i.p_mdi_child) {
            ++mdiChild;
         }
         say('_countWindows i='i' i.p_buf_name='i.p_buf_name);
         ++count;
      }
   }
   say('_countWindows mdiChild='mdiChild);
   return count;
}
#endif

//_command void test_show_window_count() name_info(',') {
//   say('test_show_window_count _countWindows(p_buf_id)='_countWindows(p_buf_id)); }

bool offerToSendToSupport()
{
   status := _message_box(nls("Would you like to send these files to SlickEdit Support?"), MB_YESNOCANCEL);
   return status == IDYES;
}

static int loadTreeVersionForStaticFile(bool doFirstDifference)
{
//   say('********************************************************************************');
   t10 := _time('b');
   _ctlcopy_left.p_visible = true;
   _ctlcopy_left_all.p_visible = true;
   _ctlcopy_left_line.p_visible = true;
   curIndex := _TreeCurIndex();
   infoWID := _ctlfile1;

   curPrevVersion := _TreeGetUserInfo(curIndex);
   setupTypeComboBox(curPrevVersion,false);

   versionedWIDTable := _GetDialogInfoHt("versionedWIDTable");
   origLine := _ctlfile1.p_line;


   se.vc.IVersionedFile versionedFile = _GetDialogInfoHt("versionedFile");
   if ( versionedFile==null ) {
      return 0;
   }
   invalidVersionTable := _GetDialogInfoHt("invalidVersionTable");

   ctllabel2.p_caption = 'Version:'curPrevVersion;

   int curVersionWID,curPrevVersionWID;
   curVersionWID = _GetDialogInfoHt("staticFileWID");

   status := 0;
   if ( curVersionWID==null ) {
      DIFF_MISC_INFO misc = _DiffGetMiscInfo();
      status = _open_temp_view(versionedFile.localFilename(),curVersionWID,auto origWID,def_load_options);
      if (status) {
         _message_box("Could not get local file");
         return status;                                                     
      }
      origBufID := curVersionWID.p_buf_id;
      origCurVersionWID := curVersionWID;
      curVersionWID = _GetViewWithRegion(curVersionWID,1,curVersionWID.p_Noflines,auto markid,curVersionWID.p_newline,curVersionWID.p_readonly_mode,infoWID);
      _delete_temp_view(origCurVersionWID);
      misc.WholeFileBufId1 = origBufID;
      misc.MarkId1 = markid;
      p_window_id = origWID;
      _DiffSetMiscInfo(misc);
      _SetDialogInfoHt("staticFileWID",curVersionWID);

      // We'll shut p_SoftWrap off later, but _SetEditorLanguage will turn it back on,
      // so wait until that and shut it off for both buffers.
      _SetDialogInfoHt("staticFileHadSoftWrap",curVersionWID.p_SoftWrap);
   } else {
      curVersionWID = _GetDialogInfoHt("staticFileWID");
      curVersionWID._DiffRemoveImaginaryLines();
      curVersionWID._DiffClearLineFlags();
      DiffFreeAllColorInfo(curVersionWID.p_buf_id);
   }
   origReadOnly := curVersionWID.p_readonly_mode;

   t11 := _time('b');
   key := versionedFile.localFilename():+PATHSEP:+curPrevVersion:+ctltypetoggle.p_caption;
   if ( invalidVersionTable:[curPrevVersion] == 1) status = DS_INVALID_CHECKSUM_RC;
   if ( versionedWIDTable:[key]==null ) {
      //curPrevVersionWID = DSExtractVersion(versionedFile.localFilename(),curPrevVersion,auto status);
      mou_hour_glass(true);
      status = versionedFile.getFile(curPrevVersion, curPrevVersionWID);
      if ( status ) {
         _ctlcopy_left.p_enabled = _ctlcopy_left_line.p_enabled = _ctlcopy_left_all.p_enabled = false;
         if (invalidVersionTable:[curPrevVersion]==null) {
            localFilename := versionedFile.localFilename();
            _message_box(get_message(status,curPrevVersion, localFilename, DSGetArchiveFilename(localFilename)));
            // Don't delete this buffer's WID, because it will cause a Slick-C stack
            // if the user doesn't immediately close the dialog.
            //_delete_temp_view(curVersionWID);
            invalidVersionTable:[curPrevVersion] = status;
            _SetDialogInfoHt("invalidVersionTable",invalidVersionTable);
         } else {
            status = invalidVersionTable:[curPrevVersion];
         }
      } else {
         status = invalidVersionTable:[curPrevVersion];
      }
      curPrevVersionWID.p_DocumentName = 'version 'curPrevVersion' of 'versionedFile.localFilename();
      mou_hour_glass(false);
      versionedWIDTable:[key] = curPrevVersionWID;
      _SetDialogInfoHt("versionedWIDTable",versionedWIDTable);
   } else {
      curPrevVersionWID = versionedWIDTable:[key];
      curPrevVersionWID._DiffRemoveImaginaryLines();
      curPrevVersionWID._DiffClearLineFlags();
      DiffFreeAllColorInfo(curPrevVersionWID.p_buf_id);
      status = invalidVersionTable:[curPrevVersion];
   }
   t15 := _time('b');
//   say('loadTreeVersionForStaticFile diff 15 time='(int)t15-(int)t11);

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

   // We already did file 1 where the initial command was called.  No need to 
   // use _diffStartNewUndoStep here, this file will be thrown away.
   _ctlfile2._undo('S');

   _DiffSetupScrollBars();
   _DiffSetupHorizontalScrollBar();
   vscroll1._ScrollMarkupSetAssociatedEditor(_ctlfile1);

   t20 := _time('b');
   _ctlfile1._DiffClearLineFlags();
   _ctlfile2._DiffClearLineFlags();


   //curVersionWID._BlastUndoInfo();
   //curPrevVersionWID._BlastUndoInfo();

   t29 := _time('b');
//   say('loadTreeVersionForStaticFile diff 29 time='(int)t29-(int)t20);
   langID := _Filename2LangId(versionedFile.localFilename());
   t30 := _time('b');
//   say('loadTreeVersionForStaticFile diff 30 time='(int)t30-(int)t29);
   _ctlfile1._SetEditorLanguage(langID);
   _ctlfile2._SetEditorLanguage(langID);
   t32 := _time('b');
//   say('loadTreeVersionForStaticFile diff 32 time='(int)t32-(int)t30);
   _ctlfile1.p_SoftWrap = false;
   _ctlfile2.p_SoftWrap = false;
   t34 := _time('b');
//   say('loadTreeVersionForStaticFile diff 34 time='(int)t34-(int)t32);

   mou_hour_glass(true);

   _ctlfile2.p_readonly_mode = true;
   if ( !status ) {
      balancedFiles := false;
      if ( _haveProDiff() && ctltypetoggle.p_caption=="Line Diff" ) {
         status = _DiffBalanceFiles(_ctlfile1,_ctlfile2,balancedFiles,0,
                                     (def_diff_flags & (DIFF_SKIP_ALL_COMMENTS|DIFF_SKIP_LINE_NUMBERS)),
                                     (def_diff_flags & DIFF_USE_SOURCE_DIFF_TOKEN_MAPPINGS)? def_sourcediff_token_mappings:null);
      }

      DIFF_INFO info;
      info.iViewID1 = _ctlfile1;
      info.iViewID2 = _ctlfile2;
      info.iOptions = def_diff_flags;
      info.iNumDiffOutputs = 0;
      info.iIsSourceDiff = false;
      info.loadOptions = def_load_options;
      info.iGaugeWID = 0;
      info.iMaxFastFileSize = def_max_fast_diff_size;
      info.lineRange1 = 1;
      info.lineRange2 = 1;
      info.iSmartDiffLimit = def_smart_diff_limit;
      info.imaginaryText = null;
      info.tokenExclusionMappings=null;

      //t40 := _time('b');
   //   say('loadTreeVersionForStaticFile diff 40 time='(int)t40-(int)t34);
      Diff(info,0);
   }
   mou_hour_glass(false);
   resizeDialog();
   //t60 := _time('b');

   // Can get callbacks that the entire file changed.  We can safely ignore them
   // because we set all the lines up correctly when we did the Diff above.
   ++gDiffSkipUpdateCallback;
   refresh('A');
   --gDiffSkipUpdateCallback;

   origLine1 := _ctlfile1.p_line;
   origLine2 := _ctlfile2.p_line;
   //t80 := _time('b');
//   say('loadTreeVersionForStaticFile 80 time='(int)t80-(int)t60);
   // If these are the first two buffers, we know the dialog just came up.
   // Find the first difference
   _str t100=0;
   if ( versionedWIDTable._length()==2||doFirstDifference ) {
      _ctlfile1.top();
      _ctlfile2.top();
      _DiffNextDifference(_ctlfile1,_ctlfile2,'','No Messages');
      _DiffSetNeedRefresh(true);
      t100 = _time('b');
//      say('loadTreeVersionForStaticFile 100 time='(int)t100-(int)t80);
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
   //t200 := _time('b');
//   say('loadTreeVersionForStaticFile 200 time='(int)t200-(int)t100);

   if ( origLine1!=_ctlfile1.p_line ||
        origLine2!=_ctlfile2.p_line ) {
      _ctlfile1.p_scroll_left_edge = -1;
      _ctlfile2.p_scroll_left_edge = -1;
   }
   t220 := _time('b');
//   say('loadTreeVersionForStaticFile 220 time='(int)t220-(int)t200);

   _ctlfile1._DiffSetReadOnly((int)origReadOnly);
   _ctlfile1.p_readonly_mode = origReadOnly!=0;
   _ctlfile2._DiffSetReadOnly(1);
   BHSetupScrollBars();
   _DiffUpdateScrollThumbs(true);
   showComments();
   //curVersionWID._BlastUndoInfo();
   //curPrevVersionWID._BlastUndoInfo();
   //t300 := _time('b');
//   say('loadTreeVersionForStaticFile 300 time='(int)t300-(int)t220);
//   say('loadTreeVersionForStaticFile total 300 time='(int)t300-(int)t10);
   return 0;
}

static void BHSetupScrollBars()
{
   vscroll1.p_max=_ctlfile1.p_Noflines-_ctlfile1.p_char_height;

   vscroll1.p_large_change=_ctlfile1.p_char_height-1;
   _DiffVscrollSetLast(vscroll1.p_value);

   _DiffHscrollSetLast(hscroll1.p_value);
}


static int loadTreeVersion(bool doFirstDifference=false)
{
   inOnCreate := _GetDialogInfoHt("inOnCreate");
   if ( inOnCreate==1 ) {
      return 0;
   }
   useStaticFile := _GetDialogInfoHt("useStaticFile");

   if ( useStaticFile ) {
      status := loadTreeVersionForStaticFile(doFirstDifference);
      return status;
   }
   invalidVersionTable := _GetDialogInfoHt("invalidVersionTable");
   _ctlcopy_left.p_visible = false;
   _ctlcopy_left_all.p_visible = false;
   _ctlcopy_left_line.p_visible = false;
   curIndex := _TreeCurIndex();
   if ( curIndex==TREE_ROOT_INDEX ) {
      return 0;
   }

   sibIndex := _TreeGetNextSiblingIndex(curIndex);
   if ( sibIndex<0 ) {
      curIndex = _TreeGetPrevIndex(curIndex);
      sibIndex = _TreeGetNextSiblingIndex(curIndex);
   }

   curVersion := _TreeGetUserInfo(curIndex);
   setupTypeComboBox(curVersion,true);
   curPrevVersion := _TreeGetUserInfo(sibIndex);

   versionedWIDTable := _GetDialogInfoHt("versionedWIDTable");
   origLine := _ctlfile1.p_line;

   se.vc.IVersionedFile versionedFile = _GetDialogInfoHt("versionedFile");
   if ( versionedFile==null ) return 0;

   ctllabel2.p_caption = 'Version:'curPrevVersion;
   int curVersionWID,curPrevVersionWID;

   status := 0;

   filename := versionedFile.localFilename(curVersion);
   // This is an absolute filename.  If we don't start with a '/' or have a ':'
   // as the second character, we have something that's not local (probably 
   // launched from repository browser)
   if ( substr(filename,1,1)!='/' && substr(filename,2,1)!=':' ) {
      ctltype_combo.p_enabled = false;
   }
   key := filename:+PATHSEP:+curVersion;
   if ( versionedWIDTable:[key]==null ) {
      //curVersionWID = DSExtractVersion(versionedFile.localFilename(),curVersion,auto status);
      mou_hour_glass(true);
      status = 0;
      if (curVersion < 0) {
         status = versionedFile.getLocalFile(curVersionWID);
      } else {
         status = versionedFile.getFile(curVersion, curVersionWID);
      }
      if ( status ) {
         if (invalidVersionTable:[curVersion]==null) {
            localFilename := versionedFile.localFilename();
            // Don't delete this buffer's WID, because it will cause a Slick-C stack
            // if the user doesn't immediately close the dialog.
            //_delete_temp_view(curVersionWID);
            invalidVersionTable:[curVersion] = status;
            _SetDialogInfoHt("invalidVersionTable",invalidVersionTable);
         }
      }
      if (status) {
         _message_box(get_message(status,curVersion,filename,DSGetArchiveFilename(filename)));
         return status;
      } else {
         curVersionWID.p_DocumentName = 'version 'curVersion' of 'versionedFile.localFilename();
      }
      mou_hour_glass(false);
      versionedWIDTable:[key] = curVersionWID;
      _SetDialogInfoHt("versionedWIDTable",versionedWIDTable);
   } else {
      curVersionWID = versionedWIDTable:[key];
      if (curVersionWID!=null && curVersionWID!=0) {
         curVersionWID._DiffRemoveImaginaryLines();
         curVersionWID._DiffClearLineFlags();
         DiffFreeAllColorInfo(curVersionWID.p_buf_id);
      }
      status = invalidVersionTable:[curVersion];
   }

   key = versionedFile.localFilename():+PATHSEP:+curPrevVersion;
   if ( versionedWIDTable:[key]==null ) {
      //curPrevVersionWID = DSExtractVersion(versionedFile.localFilename(),curPrevVersion,auto status);
      mou_hour_glass(true);
      status = 0;
      if (curPrevVersion < 0) {
         status = versionedFile.getLocalFile(curPrevVersionWID);
      } else {
         status = versionedFile.getFile(curPrevVersion, curPrevVersionWID);
         if ( status ) {
            if (invalidVersionTable:[curPrevVersion] == null) {
               localFilename := versionedFile.localFilename();
               // Don't delete this buffer's WID, because it will cause a Slick-C stack
               // if the user doesn't immediately close the dialog.
               //_delete_temp_view(curVersionWID);
               invalidVersionTable:[curPrevVersion] = status;
               _SetDialogInfoHt("invalidVersionTable",invalidVersionTable);
            } else {
               status = invalidVersionTable:[curPrevVersion];
            }
         } else {
            status = invalidVersionTable:[curPrevVersion];
         }
      }
      if ( curPrevVersionWID!=0 ) {
         curPrevVersionWID.p_DocumentName = 'version 'curPrevVersion' of 'versionedFile.localFilename();
      } else {
         // Probably this version of the file doesn't exist.  This can happen in
         // Git.
         origWID := _create_temp_view(curPrevVersionWID);
         p_window_id = origWID;
         status = 0;
      }
      mou_hour_glass(false);
      if (status) {
         localFilename := versionedFile.localFilename();
         _message_box(get_message(status,curPrevVersion,localFilename,DSGetArchiveFilename(localFilename)));
      }
      versionedWIDTable:[key] = curPrevVersionWID;
      _SetDialogInfoHt("versionedWIDTable",versionedWIDTable);
   } else {
      curPrevVersionWID = versionedWIDTable:[key];
      if (curPrevVersionWID) {
         curPrevVersionWID._DiffRemoveImaginaryLines();
         curPrevVersionWID._DiffClearLineFlags();
      }
      DiffFreeAllColorInfo(curPrevVersionWID.p_buf_id);
      status = invalidVersionTable:[curPrevVersion];
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

   if (curVersionWID==0) {
      _ctlfile1.delete_all();
   } else {
      status = _ctlfile1.load_files('+bi 'curVersionWID.p_buf_id);
   }
   if (curPrevVersionWID==0) {
      _ctlfile2.delete_all();
   } else {
      _ctlfile2.load_files('+bi 'curPrevVersionWID.p_buf_id);
   }

   if ( !useStaticFile ) {
      _ctlfile1._DiffSetReadOnly(1);
      _ctlfile1.p_readonly_mode = true;
   }
   _ctlfile2._DiffSetReadOnly(1);
   _ctlfile2.p_readonly_mode = true;

   if (!status || status==null) {
      _DiffSetupScrollBars();
      _DiffSetupHorizontalScrollBar();
      vscroll1._ScrollMarkupSetAssociatedEditor(_ctlfile1);
      _ctlfile1._DiffClearLineFlags();
      _ctlfile2._DiffClearLineFlags();

      if (curVersionWID) curVersionWID._BlastUndoInfo();

      langID := _Filename2LangId(versionedFile.localFilename());
      _ctlfile1._SetEditorLanguage(langID);
      _ctlfile2._SetEditorLanguage(langID);
      _ctlfile1.p_SoftWrap = false;
      _ctlfile2.p_SoftWrap = false;

      mou_hour_glass(true);
      DIFF_INFO info;
      info.iViewID1 = _ctlfile1;
      info.iViewID2 = _ctlfile2;
      info.iOptions = def_diff_flags;
      info.iNumDiffOutputs = 0;
      info.iIsSourceDiff = false;
      info.loadOptions = def_load_options;
      info.iGaugeWID = 0;
      info.iMaxFastFileSize = def_max_fast_diff_size;
      info.lineRange1 = 1;
      info.lineRange2 = 1;
      info.iSmartDiffLimit = def_smart_diff_limit;
      info.imaginaryText = null;
      info.tokenExclusionMappings=null;
      t10 := _time('b');
      Diff(info,0);
   }
   t20 := _time('b');
//   say('loadTreeVersion Diff time='(int)t20-(int)t10);
   mou_hour_glass(false);
   resizeDialog();

   // If these are the first two buffers, we know the dialog just came up.
   // Find the first difference
   if ( versionedWIDTable._length()==2||doFirstDifference ) {
      _ctlfile1.top();
      _ctlfile2.top();
      _DiffNextDifference(_ctlfile1,_ctlfile2);
      _DiffSetNeedRefresh(true);
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
   _DiffUpdateScrollThumbs(true);
   ctlVersionList.setLastTreeNodeEnabled(ctltype_combo.p_text);

   showComments();
   return 0;
}

static void setLastTreeNodeEnabled(_str type)
{
   curTreeIndex := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   origIndex := _TreeCurIndex();

   lastIndex := curTreeIndex;
   for (;;) {
      nextIndex := _TreeGetNextIndex(lastIndex);
      if (nextIndex) break;
      lastIndex = nextIndex;
   }

   _TreeGetInfo(lastIndex, auto state, auto bm1, auto bm2, auto nodeFlags);
   if (type==LOCAL_FILE_CAPTION) {
      _TreeSetInfo(lastIndex, state, bm1, bm2, nodeFlags|TREENODE_DISABLED);
   } else {
      _TreeSetInfo(lastIndex, state, bm1, bm2,nodeFlags&~TREENODE_DISABLED);
   }

   _TreeSetCurIndex(origIndex);
}

bool _historyDiffUseLocalFile(_str controlName,bool defaultValue)
{
   // Figure out whether to intially show the local file or show the last 
   // version as the file on the left
   retrieveValueTypeCombo := _get_form_response(controlName, 1);
   _split_form_response_vars(retrieveValueTypeCombo,auto tuples);
   if ( tuples:["cb ctltype_combo"]!=null ) {
      retrieveValueTypeCombo = tuples:["cb ctltype_combo"];
   }
   localDiff := false;
   if (retrieveValueTypeCombo != null && retrieveValueTypeCombo==LOCAL_FILE_CAPTION ) {
      localDiff = true;
   } else if ( retrieveValueTypeCombo=="" ) {
      return defaultValue;
   }
   return localDiff;
}

_command void history_diff_machine(_str filename="") name_info(','VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   if (!_haveBackupHistory()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION_1ARG, "Backup History");
      return;
   }
   if ( _no_child_windows() && filename=="") {
      _message_box("A file must be open to use this command");
      return;
   }
   if ( filename=="" ) {
      filename = _MDICurrentChild(_MDICurrent()).p_buf_name;
   }
   se.vc.BackupHistoryVersionedFile backupHistoryFile(filename);
   show('-modal -xy  _history_diff_form',&backupHistoryFile);
}

_command void history_diff_machine_file(_str filename="") name_info(','VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   if (!_haveBackupHistory()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION_1ARG, "Backup History");
      return;
   }
   if ( _no_child_windows() && filename=="") {
      _message_box("A file must be open to use this command");
      return;
   }
   if ( filename=="" ) {
      filename = _MDICurrentChild(_MDICurrent()).p_buf_name;
   }

   se.vc.BackupHistoryVersionedFile backupHistoryFile(filename);
   localDiff := _historyDiffUseLocalFile("_history_diff_backup_history_form.ctltype_combo",true);

   show('-modal -xy  _history_diff_form',&backupHistoryFile,"",localDiff,true);
}

void _HistoryDiffBackupHistoryFile(_str filename,_str version)
{
   se.vc.BackupHistoryVersionedFile backupHistoryFile(filename);
   show('-modal -xy  _history_diff_form',&backupHistoryFile,version,true,true);
}
