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
#import "fileman.e"
#import "put.e"
#import "savecfg.e"
#import "sellist.e"
#import "stdprocs.e"
#import "stdcmds.e"
#import "subversion.e"
#import "svcupdate.e"
#import "vc.e"
#import "vi.e"
#import "vicmode.e"
#endregion

using se.vc.IVersionControl;
using se.lang.String;

const SVC_COMMENT_FILENAME= 'svc_comment.txt';
static _str SVCGetCommentFilename()
{
   return(_ConfigPath():+SVC_COMMENT_FILENAME);
}

defeventtab _svc_comment_form;
void _svc_comment_form.on_destroy()
{
   // See if we needc to restore Vim mode
   if ( def_keys=="vi-keys" ) {
      origVIMode := _GetDialogInfoHt("origVIMode");
      ctledit1.vi_switch_mode(origVIMode);
   }
}
void ctlok.lbutton_up()
{
   orig_view_id1 := p_window_id;
   p_window_id = ctledit1.p_window_id;
   comments := "";
   top();
   _str line;
   do {
      get_line_raw(line);
      comments :+= strip(line, 'T') :+ "\n";
   } while (!down());
   _param3 = strip(comments, 'B', "\n\r");
   //say(comments);
   p_window_id = orig_view_id1;

   status := ctledit1._save_file("+o ":+_maybe_quote_filename(_GetDialogInfoHt("comment_filename")));
   _param1=(ctlapply_to_all.p_value && ctlapply_to_all.p_visible);
   _param2=ctltag_name.p_text;
   _param4=ctlauthor_name.p_text;
   int copy_comment_to_clipboard=ctlcopy_to_clipboard.p_value;

   _save_form_response();
   wid := p_window_id;
   p_window_id=ctledit1;

   int old_markid=_duplicate_selection('');

   int new_markid=_alloc_selection();
   top();_select_line(new_markid);
   bottom();
   status=_select_line(new_markid);
   if (status) clear_message();

   int temp_view_id,orig_view_id;
   status=_open_temp_view(SVCGetCommentFilename(),temp_view_id,orig_view_id);
   if (status) {
      status=_open_temp_view(SVCGetCommentFilename(),temp_view_id,orig_view_id,'+t');
   }
   if (!status) {
      delete_all();
      status=_copy_to_cursor(new_markid);
      status=_save_config_file();
   }

   status=_show_selection(new_markid);
   if (status) clear_message();

   if (copy_comment_to_clipboard) {
      copy_to_clipboard();
   }

   _show_selection(old_markid);
   p_window_id=orig_view_id;
   _free_selection(new_markid);
   _delete_temp_view(temp_view_id);

   p_window_id=wid;
   p_active_form._delete_window(status);
}

static int get_prev_visible_control()
{
   wid := p_window_id;
   while (!wid.p_visible) {
      wid=wid.p_prev;
      if ( wid==p_window_id ) break;
   }
   return(wid);
}

void _svc_comment_form_initial_alignment()
{
   // these labels are auto-sized - make sure they line up nicely
   if ( ctltag_name.p_visible || ctlauthor_name.p_visible ) {
      labelWidth := ctlauthor_name.p_visible ? ctlauthor_name.p_prev.p_width : 0;
      if ( ctltag_name.p_visible && ctltag_name.p_prev.p_width > labelWidth ) {
         labelWidth = ctltag_name.p_prev.p_width;
      }

      ctltag_name.p_x = ctlauthor_name.p_x = ctltag_name.p_prev.p_x + labelWidth + 20;
      ctltag_name.p_width = ctlauthor_name.p_width = (ctledit1.p_x_extent) - ctltag_name.p_x;
   }

   // now space everything out - some things will not be visible
   shift := 0;
   if ( !ctlapply_to_all.p_visible ) {
      shift = ctlapply_to_all.p_height + 90;
   }

   if ( ctltag_name.p_visible ) {
      // shift up
      ctltag_name.p_y -= shift;
      ctltag_name.p_prev.p_y -= shift;
   } else {
      // add to the shift - adds the control height and the padding b/t it and the control before
      shift += ctltag_name.p_height + 180;
   }

   if ( ctlauthor_name.p_visible ) {
      // shift up
      ctlauthor_name.p_y -= shift;
      ctlauthor_name.p_prev.p_y -= shift;
   } else {
      // add to the shift - adds the control height and the padding b/t it and the control before
      shift += ctlauthor_name.p_height + 120;
   }

   // shift buttons up
   ctlok.p_y -= shift;
   ctlcancel.p_y = ctlok.p_y;

   // no need to make the form smaller - this will handled in on_resize
}

void _svc_comment_form.on_resize()
{
   // get the padding values
   int xbuffer=ctledit1.p_x;
   int ybuffer=ctledit1.p_prev.p_y;

   xDiff := p_width - (ctledit1.p_width + 2 * xbuffer);
   yDiff := p_height - (ctlok.p_y_extent + ybuffer);

   ctledit1.p_width += xDiff;
   ctltag_name.p_width += xDiff;
   ctlauthor_name.p_width += xDiff;

   // we can just move everything down.  some things are invisible, but the shift should be right
   ctledit1.p_height += yDiff;
   ctlcopy_to_clipboard.p_y += yDiff;
   ctlapply_to_all.p_y += yDiff;
   ctltag_name.p_y += yDiff;
   ctltag_name.p_prev.p_y += yDiff;
   ctlauthor_name.p_y += yDiff;
   ctlauthor_name.p_prev.p_y += yDiff;
   ctlok.p_y += yDiff;
   ctlcancel.p_y += yDiff;

}

static void svc_select_comment(int editctl_wid)
{
   editctl_wid.select_all_line();
}

void ctlok.on_create(_str comment_filename='',_str file_being_checked_in='',
                     bool show_apply_to_all=true,bool show_tag=true,bool show_author=false,
                     _str commitCommand="")
{
   ctledit1.p_SoftWrap=true;
   ctledit1.p_SoftWrapOnWord=true;
   _SetDialogInfoHt("comment_filename",comment_filename);
   ctlapply_to_all.p_visible=show_apply_to_all;
   ctledit1.p_prev.p_caption='Comment for 'file_being_checked_in':';
   ctledit1.p_spell_check_while_typing = true;

   // Setting the coding will automatically set p_UTF8
   if (_GetDefaultEncoding()==VSENCODING_UTF8) {
      ctledit1.p_encoding=VSENCODING_UTF8;
   } else {
      ctledit1.p_encoding=VSCP_ACTIVE_CODEPAGE;
   }
   ctledit1.top();
   ctledit1.get_line(auto line);

   _retrieve_prev_form();
   ctledit1.top();
   ctledit1.get_line(line);
   if ( def_cvs_flags&CVS_RESTORE_COMMENT ) {
      wid := p_window_id;
      p_window_id=ctledit1;
      _delete_line();
      _str prev_comment_filename=SVCGetCommentFilename();
      int status=get(_maybe_quote_filename(prev_comment_filename));
      if (p_Noflines) {
         _post_call(svc_select_comment,p_window_id);
      }
      p_window_id=wid;
   }
   if ( show_tag ) {
      if ( !(def_cvs_flags&CVS_RESTORE_TAGS) ) {
         ctltag_name.p_text='';
      }
   }else{
      ctltag_name.p_visible=ctltag_name.p_prev.p_visible=false;
   }

   if ( !show_author ) {
      ctlauthor_name.p_visible = ctlauthor_label.p_visible = false;
   }

   // See if we need to put editor into Vim insert mode
   if ( def_keys=="vi-keys" ) {
      _SetDialogInfoHt("origVIMode",ctledit1.vi_get_vi_mode());
      ctledit1.vi_insert_mode();
   }
   // aligns everything now that we have made some controls invisible
   _svc_comment_form_initial_alignment();
   ctledit1.top();
   ctledit1.get_line(line);
}

/**
 * Returns true if <b>string</B> contains non printable characters
 * @param string string to check for non printable characters
 * 
 * @return bool  true if <b>string</B> contains non printable characters 
 *  
 * @categories String_Functions
 */
static bool HasNonPrintChars(_str string)
{
   len := length(string);
   int i;
   for ( i=1;i<=len;++i ) {
      ch := substr(string,i,1);
      if ( !isprint(ch) ) {
         return(true);
      }
   }
   return(false);
}

defeventtab _svc_comment_and_commit_form;

void _svc_comment_and_commit_form.on_resize()
{
   // get the padding values
   int xbuffer=ctledit1.p_x;
   int ybuffer=ctledit1.p_prev.p_y;

   xDiff := p_width - (ctledit1.p_width + 2 * xbuffer);
   yDiff := p_height - (ctlok.p_y_extent + ybuffer);

   ctledit1.p_width += xDiff;

   // we can just move everything down.  some things are invisible, but the shift should be right
   ctledit1.p_height += yDiff;
   ctlcopy_to_clipboard.p_y += yDiff;
   ctlapply_to_all.p_y += yDiff;
   ctlok.p_y += yDiff;
   ctlcancel.p_y += yDiff;
}

static _str getFileList(STRARRAY &files)
{
   fileList := "";

   len := files._length();
   for (i:=0;i<len;++i) {
      fileList = fileList' 'files[i];

      // If file list goes much past this nobody will ever see it
      if (length(fileList)>80) {
         fileList :+= " and "(i)" more";
         break;
      }
   }

   // Get rid of leading space
   fileList = substr(fileList,2);
   return fileList;
}

static int writeToTargetFile(_str (&localFilenames)[],_str &targetFilename) {
   origWID := _create_temp_view(auto fileListWID);
   len := localFilenames._length();
   if ( def_svc_logging ) {
      dsay('writeToTargetFile top','svc');
   }
   for ( i:=0;i<len;++i ) {
      curFileName := localFilenames[i];
      _maybe_strip_filesep(curFileName);
      insert_line(strip(curFileName,'B','"'));
      if ( def_svc_logging ) {
         dsay('   curFileName='curFileName,'svc');
      }
   }
   targetFilename = mktemp();
   status := _save_file("+o "targetFilename);
   p_window_id = origWID;
   _delete_temp_view(fileListWID);
   return status;
}

static void SVCCommentSetFocus(int wid)
{
   if (_iswindow_valid(wid)) {
      wid._set_focus();
   }
}

int _SVCGetCommentAndCommit(STRARRAY &files,INTARRAY &selectedIndexList,STRHASHTAB &fileTable,IVersionControl *pInterface,int updateFormWID=null)
{
   tag:='';
   int formWID=show('-xy -new _svc_comment_and_commit_form',files,selectedIndexList,fileTable,pInterface,updateFormWID);
   if ( formWID=='' ) {
      return(COMMAND_CANCELLED_RC);
   }
   _post_call(SVCCommentSetFocus,formWID.ctledit1);
   return(0);
}

void ctlok.on_create(STRARRAY &files=null, INTARRAY &selectedIndexList=null,STRHASHTAB &fileTable=null,IVersionControl *pInterface=null,int updateFormWID=0)
{
   _retrieve_prev_form();
   if (files._length()==1) {
      p_active_form.p_caption = "Commit "files[0];
   } else {
      p_active_form.p_caption = "Commit "files._length()" files";
   }
   fileListCaption := getFileList(files);
   ctledit1.p_prev.p_caption = "Comment for: "fileListCaption;
   _SetDialogInfoHt("files",files);
   _SetDialogInfoHt("selectedIndexList",selectedIndexList);
   _SetDialogInfoHt("pInterface",pInterface);
   _SetDialogInfoHt("updateFormWID",updateFormWID);
   _SetDialogInfoHt("fileTable",fileTable);

   _str prev_comment_filename=SVCGetCommentFilename();
   ctledit1.delete_all();
   int status=ctledit1.get(_maybe_quote_filename(prev_comment_filename));
   if (ctledit1) {
      _post_call(svc_select_comment,ctledit1);
   }

   ybuf := ctlapply_to_all.p_y - ctlcopy_to_clipboard.p_y_extent;
   pullup := 0;
   useApplyToAll := files._length()==1 ? false:true;
   if (useApplyToAll) {
      ctlapply_to_all.p_visible = true;
   } else {
      pullup += ctlapply_to_all.p_height + ybuf;
      ctlapply_to_all.p_visible = false;
   }
   ctlok.p_y -= pullup;
   ctlcancel.p_y -= pullup;
   p_active_form.p_height -= pullup;
}

void ctlok.lbutton_up()
{
   commentFilename := SVCGetCommentFilename();
   status := ctledit1._save_file("+o ":+commentFilename);
   if (status) {
      return;
   }
   files := _GetDialogInfoHt("files");
   origFiles := files;
   selectedIndexList := _GetDialogInfoHt("selectedIndexList");
   fileTable := _GetDialogInfoHt("filetable");
   IVersionControl *pInterface = _GetDialogInfoHt("pInterface");
   updateFormWID := _GetDialogInfoHt("updateFormWID");
   if (pInterface==null) return;
   exeStr := _maybe_quote_filename(_SVNGetExePath());

   allDone := false;

   applyToAll := ctlapply_to_all.p_visible && ctlapply_to_all.p_value;

   fileListCaption := getFileList(files);
   ctledit1.p_prev.p_caption = "Comment for: "fileListCaption;
   STRARRAY curFilenameList;
   if (applyToAll) {
      curFilenameList = files;
   } else {
      curFilenameList[0] = files[0];
      files._deleteel(0);
   }
   status = pInterface->commitFiles(curFilenameList,commentFilename,SVC_COMMIT_OPTION_COMMENT_IS_FILENAME);

   // Remove and directories from the list to reload and retag.  We'll grab 
   // the removed items elsewhere and reload/retag them.
   localFilenames := _GetDialogInfoHt("localFilenames");
   len := localFilenames._length();
   for ( i:=len-1;i>=0;--i ) {
      if ( _last_char(localFilenames[i])==FILESEP ) {
         localFilenames._deleteel(i);
      }
   }
   _reload_vc_buffers(localFilenames);
   _retag_vc_buffers(localFilenames);

   allDone = applyToAll || files._length()==0;
   fileListCaption = getFileList(files);
   ctledit1.p_prev.p_caption = "Comment for: "fileListCaption;
   _SetDialogInfoHt("files",files);
   _save_form_response();


   if (updateFormWID!=null && _iswindow_valid(updateFormWID) && pos("Update",updateFormWID.p_caption)) {
      updateFormWID._SVCUpdateRefreshAfterOperation(origFiles,selectedIndexList,fileTable,pInterface);
   }
   if (files._length()==1) {
      p_active_form.p_caption = "Commit "files[0];
   } else {
      p_active_form.p_caption = "Commit "files._length()" files";
   }
   fileListCaption = getFileList(files);
   ctledit1.p_prev.p_caption = "Comment for: "fileListCaption;
   if (allDone) p_active_form._delete_window();
}

