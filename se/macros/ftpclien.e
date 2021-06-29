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
#include "toolbar.sh"
#include "ftp.sh"
#import "drvlist.e"
#import "eclipse.e"
#import "fileman.e"
#import "files.e"
#import "ftp.e"
#import "ftpopen.e"
#import "ftpparse.e"
#import "ftpq.e"
#import "listbox.e"
#import "makefile.e"
#import "picture.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "se/ui/toolwindow.e"
#import "tbcontrols.e"
#import "treeview.e"
#import "dlgman.e"
#import "help.e"
#endregion


static const TBFTPCLIENT_FORM_NAME= "_tbFTPClient_form";

int _ftpclientQFormWid()
{
   int formWid;
   if (isEclipsePlugin()) {
      formWid = _find_formobj(ECLIPSE_FTPCLIENT_CONTAINERFORM_NAME,'n');
      if (formWid > 0) {
         formWid = formWid.p_child;
      }
   } else {
      formWid=_find_formobj(TBFTPCLIENT_FORM_NAME,'n');
   }
   return formWid;
}

_command void ftpClient() name_info(','VSARG2_NCW|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   if (!_haveFTP()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION_1ARG, "FTP");
      return;
   }
   formWid := _ftpclientQFormWid();
   show_tool_window(TBFTPCLIENT_FORM_NAME);
   if( formWid ) {
      msg := "";
      switch( formWid.p_DockingArea ) {
      case DOCKAREAPOS_BOTTOM:
         msg="The FTP Client toolbar is already visible at the bottom";
         break;
      case DOCKAREAPOS_LEFT:
         msg="The FTP Client toolbar is already visible on the left side";
         break;
      case DOCKAREAPOS_RIGHT:
         msg="The FTP Client toolbar is already visible on the right side";
         break;
      case DOCKAREAPOS_TOP:
         msg="The FTP Client toolbar is already visible at the top";
         break;
      }
      if( msg!="" ) {
         ftpDisplayInfo(msg);
      }
   }
}

static const FTPTOOLTAB_DIR= (0);
static const FTPTOOLTAB_LOG= (1);
static bool gchangetab_allowed=true;
static _str LOCALCWD;
static _str LOCALFILTER;
static int LOCALSORTFLAGS=0;
static typeless LOCALTREEPOS="";
static int REMOTESORTFLAGS=0;
static typeless REMOTETREEPOS="";

static bool gchangeprofile_allowed=true;
bool _ftpclientChangeProfileOnOff(_str onoff="")
{
   if( onoff != "" ) {
      gchangeprofile_allowed=(onoff != "0");
   }

   return (gchangeprofile_allowed);
}

static bool gchangedrvlist_allowed=true;
bool _ftpclientChangeDrvListOnOff(_str onoff="")
{
   if( onoff != "" ) {
      gchangedrvlist_allowed=(onoff != "0");
   }

   return (gchangedrvlist_allowed);
}

static bool gchangelocalcwd_allowed=true;
bool _ftpclientChangeLocalCwdOnOff(_str onoff="")
{
   if( onoff != "" ) {
      gchangelocalcwd_allowed=(onoff != "0");
   }

   return (gchangelocalcwd_allowed);
}

static bool gchangelocaldir_allowed=true;
bool _ftpclientChangeLocalDirOnOff(_str onoff="")
{
   if( onoff!="" ) {
      gchangelocaldir_allowed=(onoff!="0");
   }

   return (gchangelocaldir_allowed);
}

static bool gchangeremotecwd_allowed=true;
bool _ftpclientChangeRemoteCwdOnOff(_str onoff="")
{
   if( onoff!="" ) {
      gchangeremotecwd_allowed=(onoff!="0");
   }

   return (gchangeremotecwd_allowed);
}

static bool gchangeremotedir_allowed=true;
bool _ftpclientChangeRemoteDirOnOff(_str onoff="")
{
   if( onoff!="" ) {
      gchangeremotedir_allowed=(onoff!="0");
   }

   return (gchangeremotedir_allowed);
}

defeventtab _tbFTPClient_form;

_tbFTPClient_form.'C-M'()
{
   if (isEclipsePlugin()) {
      eclipse_maximize_part();
   }
}

_tbFTPClient_form.'F12'()
{
   if (isEclipsePlugin()) {
      eclipse_activate_editor();
   } else if (def_keys == 'eclipse-keys') {
      activate_editor();
   }
}

// This expects the active window to be a combo box
void _ftpclientFillProfiles(bool set_textbox)
{
   oldchangeprofile_allowed := _ftpclientChangeProfileOnOff();
   _ftpclientChangeProfileOnOff(0);
   profile_name := p_text;
   _lbclear();
   typeless i;
   for( i._makeempty();; ) {
      _ftpCurrentConnections._nextel(i);
      if( i._isempty() ) break;
      _lbadd_item(i);
   }
   if( p_Noflines ) {
      _lbsort('AI');
      if( set_textbox ) {
         _lbselect_line();
         p_text=_lbget_seltext();
      } else if( profile_name != '' ) {
         // We get here when profiles have been added/removed
         // from the list, but we do not want the current item
         // selected to change.
         _lbfind_and_select_item(profile_name, 'i');
      }
   }
   _ftpclientChangeProfileOnOff(oldchangeprofile_allowed);
}

static void oncreateTabControl(_str activeTab="")
{
   _ftpclientChangeProfileOnOff(0);

   // If active tab is specified as arg(2).  Otherwise, use the saved value.
   if( activeTab!="" ) {
      p_ActiveTab=(int)activeTab;
   } else {
      _retrieve_value();
   }

   _ctl_profile.p_text="";
   _ctl_profile._ftpclientFillProfiles(true);
   _str profile=_ctl_profile._retrieve_value();
   _ctl_profile._lbfind_and_select_item(profile);

   _ftpclientChangeProfileOnOff(1);

   _ctl_progress_label1.p_caption="";
   _ctl_progress_label2.p_caption="";
   _ctl_progress.p_value=0;
}

static void oncreateDirTab()
{
   _ctl_local_dir.p_multi_select=MS_EXTENDED;
   _ctl_remote_dir.p_multi_select=MS_EXTENDED;

   _ctl_remote_dir.p_visible=false;
   _ctl_remote_cwd.p_visible=false;
   _ctl_no_connection.p_visible=true;
   if (_isUnix()) {
      _ctl_local_drvlist.p_visible=false;   // Paranoid - this is taken care of in _UpdateSession()
   } else {
      _ctl_local_drvlist.p_visible=true;
   }
   LOCALCWD="";
   LOCALFILTER=ALLFILES_RE;
   LOCALSORTFLAGS=FTPSORTFLAG_NAME|FTPSORTFLAG_ASCEND;
   LOCALTREEPOS="";
   REMOTESORTFLAGS=FTPSORTFLAG_NAME|FTPSORTFLAG_ASCEND;
   REMOTETREEPOS="";

   // Horizontal scroll bars
   _str val=_retrieve_value("_tbFTPClient_form._ctl_local_dir.p_scroll_bars");
   if( !isinteger(val) || val<SB_NONE || val>SB_BOTH ) val=SB_BOTH;
   _ctl_local_dir.p_scroll_bars= (int)val;
   if( (_ctl_local_dir.p_scroll_bars)&SB_HORIZONTAL ) {
      _ctl_local_dir.p_delay= -1;
   } else {
      _ctl_local_dir.p_delay= 0;
   }
   val=_retrieve_value("_tbFTPClient_form._ctl_remote_dir.p_scroll_bars");
   if( !isinteger(val) || val<SB_NONE || val>SB_BOTH ) val=SB_BOTH;
   _ctl_remote_dir.p_scroll_bars= (int)val;
   if( (_ctl_remote_dir.p_scroll_bars)&SB_HORIZONTAL ) {
      _ctl_remote_dir.p_delay= -1;
   } else {
      _ctl_remote_dir.p_delay= 0;
   }

   // Local current working directory history
   _ftpclientChangeLocalCwdOnOff(0);
   _ctl_local_cwd._retrieve_list();
   _ctl_local_cwd._lbtop();
   _str cwd=_ctl_local_cwd._lbget_text();
   // Used to restore the original local current working directory
   LOCALCWD=cwd;
   _ftpclientChangeLocalCwdOnOff(1);
}

// This expects the active window to be an edit control
void _ftpclientAttachLog(_str log_buf_name)
{
   // Attach the log buffer to the edit control on the "Log" tab.
   // Note: Not worrying about getting rid of the original buffer that
   // gets created with an edit control because it will get deleted
   // when ftp client toolbar is destroyed.
   p_visible=true;
   int orig_buf_id=p_buf_id;
   for(;;) {
      if( p_buf_name==log_buf_name ) break;
      _next_buffer('HR');
      if( p_buf_id==orig_buf_id ) break;
   }
   if( p_buf_name==log_buf_name ) {
      bottom();
   }
   //p_window_id=orig_view_id;
}

static void oncreateLogTab()
{
   _ctl_log.p_visible=false;
   _ctl_no_log.p_visible=true;
}

void _ctl_ftp_sstab.on_create()
{
   gchangetab_allowed=false;
   _ctl_ftp_sstab.oncreateTabControl();
   _ctl_ftp_sstab.oncreateDirTab();
   _ctl_ftp_sstab.oncreateLogTab();
   gchangetab_allowed=true;

   _ctl_ftp_sstab.call_event(_ctl_ftp_sstab,ON_RESIZE,'W');

   _ctl_profile.call_event(CHANGE_SELECTED,_ctl_profile,ON_CHANGE,'W');
}

void _ctl_local_cwd.on_create()
{
   if (!_ctl_local_drvlist.p_visible || p_text == '') {
      return;
   }
   if (_isWindows()) {
      cwd := p_text;
      if (cwd == '') {
         return;
      }
      _ftpclientChangeDrvListOnOff(0);
      if( substr(cwd,1,2)=='\\' ) {
         // A UNC path is the local current working directory
         _str server, root, uncroot;
         parse cwd with '\\' server '\' root '\' .;
         uncroot='\\':+server:+'\':+root;
         _ctl_local_drvlist._dvldrive(lowcase(uncroot));
      } else {
         drive := substr(cwd,1,2);
         _ctl_local_drvlist._dvldrive(lowcase(drive));
      }
      _ftpclientChangeDrvListOnOff(1);
   }
}

_tbFTPClient_form.on_load()
{
   // Take focus off the toolbar after the on_create()'s are done
   p_window_id=_mdi.p_child;
   _set_focus();
}

void _ctl_ftp_sstab.on_destroy()
{
   // Remember active tab
   int val=_ctl_ftp_sstab.p_ActiveTab;
   _append_retrieve(_ctl_ftp_sstab,val);

   // Remember the active profile
   _append_retrieve(_ctl_profile,_ctl_profile.p_text);

   // Remember horizontal scroll bar settings
   _append_retrieve(0,_ctl_local_dir.p_scroll_bars,"_tbFTPClient_form._ctl_local_dir.p_scroll_bars");
   _append_retrieve(0,_ctl_remote_dir.p_scroll_bars,"_tbFTPClient_form._ctl_remote_dir.p_scroll_bars");

   // Remember local current working directory history
   _append_retrieve(_ctl_local_cwd,_ctl_local_cwd.p_text);
}

void _ctl_ftp_sstab.on_change(int reason)
{
   if( !gchangetab_allowed ) return;

   if( reason==CHANGE_TABACTIVATED ) {
      // Force a resize
      p_active_form.call_event(p_active_form,ON_RESIZE,'W');
   }
}

/**
 * Update connect, disconnect, ascii, binary, etc. buttons at 
 * top of tool window. 
 *
 * <p>
 *
 * Note: This function expects the active window to be the form.
 * 
 * @param fcp_p  Current connection.
 */
static void _ftpclientUpdateButtonBar(FtpConnProfile* fcp_p)
{
   if( !fcp_p ) {
      return;
   }

   asciiWid := _find_control("_ctl_ascii");
   binWid := _find_control("_ctl_binary");
   if( asciiWid > 0 && binWid > 0 ) {
      int xfer_type = fcp_p->xferType;
      if( fcp_p->serverType != FTPSERVERTYPE_FTP ) {
         // The transfer-type is ignored by all server types that
         // are not FTP (e.g. SFTP), but we hard-code it here so
         // that the user understands that _all_ transfers will
         // be BINARY.
         xfer_type = FTPXFER_BINARY;
      }
      switch( xfer_type ) {
      case FTPXFER_ASCII:
         asciiWid.p_value = 1;
         asciiWid.p_style = PSPIC_BUTTON;
         binWid.p_style = PSPIC_FLAT_BUTTON;
         // Pass arg(1)==1 to tell the event handler not to do special
         // processing for the server type. Otherwise we get a message
         // about "setting the transfer mode not supported" for the
         // case of non-FTP server types (e.g. SFTP).
         asciiWid.call_event(1,asciiWid,LBUTTON_UP,'W');
         break;
      case FTPXFER_BINARY:
         binWid.p_value = 1;
         binWid.p_style = PSPIC_BUTTON;
         asciiWid.p_style = PSPIC_FLAT_BUTTON;
         // Pass arg(1)==1 to tell the event handler not to do special
         // processing for the server type. Otherwise we get a message
         // about "setting the transfer mode not supported" for the
         // case of non-FTP server types (e.g. SFTP).
         binWid.call_event(1,binWid,LBUTTON_UP,'W');
         break;
      default:
         // This should never happen
         ASSERT(false);
         asciiWid.p_value = 0;
         binWid.p_value = 0;
         binWid.p_style = PSPIC_FLAT_BUTTON;
         asciiWid.p_style = PSPIC_FLAT_BUTTON;
      }

      // Set visibility for ascii/binary transfer-type buttons
      // Explanation:
      // Hide the buttons for non-FTP (e.g. SFTP) connections so 
      // the user is not confused, since those types of connections
      // are always binary.
      visible := ( fcp_p->serverType == FTPSERVERTYPE_FTP );
      asciiWid.p_visible = visible;
      binWid.p_visible = visible;
      int prevWid = asciiWid.p_prev;
      if( prevWid.p_object == OI_IMAGE && prevWid.p_style == PSPIC_TOOLBAR_DIVIDER_VERT ) {
         prevWid.p_visible = visible;
      }
   }
}

// This expects the active window to be a combo box
int _ftpclientChangeProfile(_str profile_name="")
{
   FtpConnProfile *fcp_p;
   FtpXferType xfer_type;
   bool oldchangeprofile_allowed;
   int formWid,asciiWid,binWid;
   typeless status;

   oldchangeprofile_allowed=_ftpclientChangeProfileOnOff();
   _ftpclientChangeProfileOnOff(0);
   if( profile_name == "" ) {
      // Get the profile in the text box
      profile_name=p_text;
   }

   if( profile_name=="" ) {
      // This should only happen when there are no connections
      if( !p_Noflines ) _ftpclientFillProfiles(false);
      if( p_Noflines ) {
         _lbtop();
         profile_name=_lbget_text();
      }
      if( profile_name=="" ) {
         p_text="";
         _ftpclientChangeProfileOnOff(oldchangeprofile_allowed);
         return(0);
      }
   }

   //messageNwait(_ftpCurrentConnections._isempty()'  '_ftpCurrentConnections._indexin(profile_name));
   //messageNwait('profile_name='profile_name);
   if( !_ftpCurrentConnections._indexin(profile_name) ) {
      // Remove this profile from the combo box
      _ftpclientFillProfiles(false);
      _lbtop();
      _lbselect_line();
      p_text=_lbget_seltext();
      profile_name=p_text;
   } else {
      // Always find the profile name in case the user just opened a new connection
      if( _lbfind_and_select_item(profile_name, 'i') ) {
         // This normally happens when user connects with "Connect..." button
         _ftpclientFillProfiles(false);
         _lbfind_and_select_item(profile_name, 'i');
      }
   }
   fcp_p=_ftpCurrentConnections._indexin(profile_name);
   if( fcp_p ) {
      formWid = _ftpclientQFormWid();
      _ftpclientUpdateButtonBar(fcp_p);
      if( fcp_p->logBufName=="" ) {
         ftpDisplayWarning('Warning:  Forced to create a log for profile "':+profile_name:+'"');
         _str log_buf_name=_ftpCreateLogBuffer();
         if( log_buf_name=="" ) {
            // _ftpCreateLogBuffer() will take care of error messages to user
            _ftpclientChangeProfileOnOff(oldchangeprofile_allowed);
            return(1);
         }
         fcp_p->logBufName=log_buf_name;
         _ftpLog(fcp_p,"*** Log started on ":+_date():+" at ":+_time('M'));
      }
   }
   _ftpclientChangeProfileOnOff(oldchangeprofile_allowed);

   return 0;
}

//#define isvalid_field_width(w) (isinteger(w) && w>0)
static const FTPDIR_FIELDGAP= (300);
// This expects the active window to be a tree view.
// Sets up column widths in the directory listing.
static void _RefreshLocalDirFields()
{
   // Right now this just calls the refresh for the ftp directory listing,
   // but it might change in the future if the format of the local listing
   // becomes different from the remote listing.
   _RefreshRemoteDirFields();
}

/** 
 * This function expects the active window to be a tree view.
 * <p>
 * Refreshes the local directory listing. Specify
 * <code>quiet=true</code> if you do not want to see error
 * messages. 
 * </p>
 *
 * @param fcp_p 
 * @param quiet 
 *
 * @return 0 on success, non-zero on error.
 */
static int _RefreshLocalDir(FtpConnProfile* fcp_p, bool quiet=false)
{
   if ( !fcp_p ) {
      return 1;
   }

   int name_sort_flags = _ftpTreeSortFlags(0);
   int size_sort_flags = _ftpTreeSortFlags(1);
   int modified_sort_flags = _ftpTreeSortFlags(2);
   int attribs_sort_flags = _ftpTreeSortFlags(3);

   bool sort_by_name = 0 != (name_sort_flags & (TREE_BUTTON_SORT | TREE_BUTTON_SORT_DESCENDING));
   bool sort_by_size = 0 != (size_sort_flags & (TREE_BUTTON_SORT | TREE_BUTTON_SORT_DESCENDING));
   bool sort_by_modified = 0 != (modified_sort_flags & (TREE_BUTTON_SORT | TREE_BUTTON_SORT_DESCENDING));
   bool sort_by_attribs = 0 != (attribs_sort_flags & (TREE_BUTTON_SORT | TREE_BUTTON_SORT_DESCENDING));
   // Sort by Name is default if no other sorting specified
   sort_by_name = sort_by_name || (!sort_by_size && !sort_by_modified && !sort_by_attribs);

   bool descending = 0 != ((name_sort_flags | size_sort_flags | modified_sort_flags | attribs_sort_flags) & TREE_BUTTON_SORT_DESCENDING);

   // Generate a temp view with the local file listing
   tree_view_id := p_window_id;
   temp_view_id := 0;
   if ( _create_temp_view(temp_view_id) == '' ) {
      // _create_temp_view() took care of error messages
      if ( !quiet ) {
         ftpDisplayError("Unable to retrieve local directory list");
      }
      return 1;
   }
   _delete_line();
   _str cwd = fcp_p->localCwd;
   if ( cwd == '' ) {
      cwd = getcwd();
      fcp_p->localCwd = cwd;
   }
   // User might have setup '.' or some relative path as the current
   // local working directory, so resolve it.
   _str orig_cwd = cwd;
   cwd = isdirectory(_maybe_quote_filename(cwd), 1);
   if ( cwd == '' || cwd == '0' ) {
      _delete_temp_view(temp_view_id);
      p_window_id = tree_view_id;
      cwd = getcwd();
      if ( !quiet ) {
         ftpDisplayError("The following directory does not exist:\n\n":+
                         orig_cwd:+"\n\nThe new local working directory is:\n\n":+
                         cwd);
      }
   }
   fcp_p->localCwd = cwd;
   _maybe_append_filesep(cwd);
   filespec :=  cwd :+ ALLFILES_RE;
   int status = insert_file_list(_maybe_quote_filename(filespec):+' +ADV');
   if ( status && status != FILE_NOT_FOUND_RC ) {
      // Failed, so try the current working directory
      curcwd := getcwd();
      _maybe_append_filesep(curcwd);
      if ( cwd != curcwd ) {
         cwd = curcwd;
         fcp_p->localCwd = cwd;
         if ( !quiet ) {
            _str msg="Unable to retrieve local directory list for:\n\n":+orig_cwd:+
                "\n\nThe new local working directory is:\n\n":+cwd;
            ftpDisplayError(msg);
         }
         filespec = cwd :+ ALLFILES_RE;
         status = insert_file_list(_maybe_quote_filename(filespec):+' +ADV');
      }
      if ( status ) {
         _delete_temp_view(temp_view_id);
         p_window_id = tree_view_id;
         if ( !quiet ) {
            _str msg="Unable to retrieve local directory list for:\n\n":+orig_cwd:+
                "\n\n":+get_message(status);
         }
         return status;
      }
   }

   // Fill in the file list. The format is:
   //
   // 11444   7-15-1997  10:15p ----A  ftp.c
   _str filter = fcp_p->localFileFilter;
   if ( filter == '' ) {
      filter = ALLFILES_RE;
   }
   top(); up();
   p_window_id = tree_view_id;
   _TreeDelete(TREE_ROOT_INDEX, 'C');
   for (;;) {
      p_window_id = temp_view_id;
      if ( down() ) {
         break;
      }
      if ( _line_length(true) == _line_length(false) ) {
         break;
      }
      line := "";
      get_line(line);
      typeless size, modified, attribs, filename;
      typeless date, time;
      parse line with size date time attribs filename;
      if ( filename == '.' || filename == '..' ) {
         continue;
      }
      if ( !pos('d', lowcase(attribs), 1, 'e') && filter != ALLFILES_RE ) {
         match := false;
         _str list = filter;
         while ( list != '' ) {
            filespec = parse_file(list);
            filespec = strip(filespec, 'B', '"');
            if ( filespec == '' ) {
               continue;
            }
            if ( _FilespecMatches(filespec, filename) ) {
               // Found a match
               match = true;
               break;
            }
         }
         if ( !match ) {
            continue;
         }
      }

      //
      // caption
      //

      if ( !isinteger(size) ) {
         // Probably the "<DIR>" of a directory
         size = 0;
      }
      // 12-31-2000 + pad-2-spaces = 12 chars
      modified = _pad(date, 12, ' ', 'R') :+ time;

      p_window_id = tree_view_id;
      int picidx = _pic_ftpfile;
      if ( pos('d', lowcase(attribs), 1, 'e') ) {
         picidx = _pic_ftpfold;
      }
      caption :=  filename"\t"size"\t"modified"\t"attribs;

      //
      // user-info for sorting
      //

      // Use this for primary/secondary sort on directories/files
      int type = (pos('d',lowcase(attribs), 1, 'e')) ? FTPFILETYPE_DIR : 0;
      _str hint = _ftpTypeFlags2SortHint(type, name_sort_flags);
      // Append lowcased filename for case-insensitive sort
      ui_name :=  hint'-'lowcase(filename);
      // 20 places will cover > 1EB in decimal
      _str ui_size = _pad(size, 20, '0', 'L');
      _str ui_modified = _file_date(absolute(filename, fcp_p->localCwd), 'B');
      _str ui_attribs = attribs;
      userInfo :=  ui_name"\t"ui_size"\t"ui_modified"\t"ui_attribs;
      // We sort by a specific column by making sure its user-info is prepended to tree item's user-info
      if ( sort_by_name ) {
         userInfo = ui_name"\t"userInfo;
      } else if ( sort_by_size ) {
         userInfo = ui_size"\t"userInfo;
      } else if ( sort_by_modified ) {
         userInfo = ui_modified"\t"userInfo;
      } else if ( sort_by_attribs ) {
         userInfo = ui_attribs"\t"userInfo;
      }
      int idx = _TreeAddItem(TREE_ROOT_INDEX, caption, TREE_ADD_AS_CHILD, picidx, picidx, -1, 0, userInfo);
   }
   _delete_temp_view(temp_view_id);
   p_window_id = tree_view_id;
   // Add the up-one-level ".."
   // Setting userinfo to '!' ('~' if descending sort) guarantees it will get to top of tree when sorted
   _str userInfo = descending ? '~' : '!';
   _TreeAddItem(TREE_ROOT_INDEX, "..\t\t\t", TREE_ADD_AS_CHILD, _pic_ftpcdup, _pic_ftpcdup, -1, 0, userInfo);

   // Sort!
   // Note that user-info set by _ftpTreeAddItem() determines which column is sorted on (Name, Size, Modified, Attributes)
   opts := 'E';
   if ( descending ) {
      opts :+= 'D';
   }
   _TreeSortUserInfo(TREE_ROOT_INDEX, opts);
   _RefreshLocalDirFields();
   _TreeTop();
   _TreeRefresh();

   return 0;
}

//#define isvalid_field_width(w) (isinteger(w) && w>0)
static const FTPDIR_FIELDGAP= (300);

/**
 * This expects the active window to be a tree view. Sets up 
 * column widths in the directory listing. 
 */
static void _RefreshRemoteDirFields()
{
   if ( _TreeGetDepth(TREE_ROOT_INDEX) ) {
      // Nothing to process
      return;
   }

   filename_width := 0;
   size_width := 0;
   modified_width := 0;
   attribs_width := 0;
   idx := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   for (;;) {
      caption := _TreeGetCaption(idx);
      _str filename, size, modified, attribs;
      parse caption with filename "\t" size "\t" modified "\t" attribs;

      // Find the longest widths for each field in the tree
      int width = _text_width(filename);
      if ( width > filename_width ) filename_width = width;
      width = _text_width(size);
      if ( width > size_width ) size_width = width;
      width = _text_width(modified);
      if ( width > modified_width ) modified_width = width;
      width = _text_width(attribs);
      if ( width > attribs_width ) attribs_width = width;

      idx = _TreeGetNextSiblingIndex(idx);
      if ( idx < 0 ) {
         break;
      }
   }

   // filename_width must include the width of the file/folder bitmap
   filename_width += 16 * _twips_per_pixel_x();

   // Set column widths, flags, captions

   // Name
   // Don't use TREE_COL_SORT_FILENAME here, we always want case insensitive
   _TreeSetColButtonInfo(0, filename_width + FTPDIR_FIELDGAP, TREE_BUTTON_PUSHBUTTON, 0, 'Name');
   // Size
   _TreeSetColButtonInfo(1, size_width + FTPDIR_FIELDGAP, TREE_BUTTON_PUSHBUTTON, 0, 'Size');
   // Modified
   _TreeSetColButtonInfo(2, modified_width + FTPDIR_FIELDGAP, TREE_BUTTON_PUSHBUTTON, 0, 'Modified');
   // Attributes
   _TreeSetColButtonInfo(3, attribs_width + FTPDIR_FIELDGAP, TREE_BUTTON_PUSHBUTTON, 0, 'Attributes');
}

/** 
 * This function expects the active window to be a tree view.
 * <p>
 * Refreshes the remote directory listing based on the raw listing
 * stored in <code>fcp_p->remoteDir</code>.
 * </p>
 *
 * @param fcp_p 
 *
 * @return 0 on success, non-zero on error.
 */
int _ftpclientRefreshRemoteDir(FtpConnProfile* fcp_p)
{
   FtpFile files[];

   if ( !fcp_p ) {
      return 1;
   }

   int name_sort_flags = _ftpTreeSortFlags(0);
   int size_sort_flags = _ftpTreeSortFlags(1);
   int modified_sort_flags = _ftpTreeSortFlags(2);
   int attribs_sort_flags = _ftpTreeSortFlags(3);

   bool descending = 0 != ((name_sort_flags | size_sort_flags | modified_sort_flags | attribs_sort_flags) & TREE_BUTTON_SORT_DESCENDING);

   // Fill in the file list
   _TreeDelete(TREE_ROOT_INDEX, 'C');
   files = fcp_p->remoteDir.files;
   int i, n = files._length();
   for ( i = 0; i < n; ++i ) {
      if ( files[i].filename == '.' || files[i].filename == '..' ) {
         continue;
      }
      _ftpTreeAddItem(files[i], name_sort_flags, size_sort_flags, modified_sort_flags, attribs_sort_flags);
   }
   // Add the up-one-level ".."
   // Setting userinfo to '!' ('~' if descending sort) guarantees it will get to top of tree regardless of which column is sorted
   _str userInfo = descending ? '~' : '!';
   _TreeAddItem(TREE_ROOT_INDEX, "..\t\t\t", TREE_ADD_AS_CHILD, _pic_ftpcdup, _pic_ftpcdup, -1, 0, userInfo);

   // Sort!
   // Note that user-info set by _ftpTreeAddItem() determines which column is sorted on (Name, Size, Modified, Attributes)
   opts := 'E';
   if ( descending ) {
      opts :+= 'D';
   }
   _TreeSortUserInfo(TREE_ROOT_INDEX, opts);
   _RefreshRemoteDirFields();
   _TreeTop();
   _TreeRefresh();

   return 0;
}

// Needed this for the ftpfile_match() completion function
FtpConnProfile *ftpclientGetCurrentConnProfile()
{
   formWid := _ftpclientQFormWid();
   if( !formWid ) return(null);

   return (formWid.GetCurrentConnProfile());
}

static int _UpdateLocalSession()
{
   FtpConnProfile *fcp_p;
   FtpConnProfile fake;   // Used when there is no current connection

   fcp_p=GetCurrentConnProfile();
   cwd := "";
   if( fcp_p ) {
      cwd=fcp_p->localCwd;
      LOCALFILTER=fcp_p->localFileFilter;
      LOCALSORTFLAGS=fcp_p->localSortFlags;
   } else {
      // There is no current connection, so fake one
      cwd=LOCALCWD;
      if( cwd=="" ) {
         cwd=getcwd();
         LOCALCWD=cwd;
      }
      _ftpInitConnProfile(fake);
      fake.localCwd=cwd;
      fake.localFileFilter=LOCALFILTER;
      fake.localSortFlags=LOCALSORTFLAGS;
      fcp_p=&fake;
   }

   // Generate local directory list
   mou_hour_glass(true);
   _ftpclientChangeLocalDirOnOff(0);
   typeless status=_ctl_local_dir._RefreshLocalDir(fcp_p);
   _ftpclientChangeLocalDirOnOff(1);
   mou_hour_glass(false);
   if( !status ) {
      _ctl_local_dir._ftpclientLocalRestorePos();
      _ctl_local_dir._ftpclientLocalSavePos();
      cwd=fcp_p->localCwd;
      LOCALCWD=cwd;
      _ftpclientChangeLocalCwdOnOff(0);
      _ctl_local_cwd._lbfind_and_delete_item(cwd,_fpos_case);
      // Add the directory to the top of the list box
      _ctl_local_cwd._lbdeselect_line();
      _ctl_local_cwd.p_line=0;
      _ctl_local_cwd._lbadd_item(cwd);
      _ctl_local_cwd.p_text=cwd;
      _ctl_local_cwd._set_sel(1,length(cwd)+1);
      // Remember local current working directory history.
      // Must do this here because exiting the editor does not call a control's
      // ON_DESTROY event.
      _append_retrieve(_ctl_local_cwd,_ctl_local_cwd.p_text);
      _ftpclientChangeLocalCwdOnOff(1);

      if (_isWindows()) {
         cwd=fcp_p->localCwd;
         _ftpclientChangeDrvListOnOff(0);
         if( substr(cwd,1,2)=='\\' ) {
            // A UNC path is the local current working directory
            _str server, root, uncroot;
            parse cwd with '\\' server '\' root '\' .;
            uncroot='\\':+server:+'\':+root;
            _ctl_local_drvlist._dvldrive(lowcase(uncroot));
         } else {
            drive := substr(cwd,1,2);
            _ctl_local_drvlist._dvldrive(lowcase(drive));
         }
         _ftpclientChangeDrvListOnOff(1);
      }
      return 0;
   }

   return 1;
}

void _ftpclientUpdateLocalSession()
{
   int formWid;

   formWid=_ftpclientQFormWid();
   if( formWid==0 ) {
      return;
   }
   formWid._UpdateLocalSession();
}

/**
 * Show progress for transfer on the FTP tool window. 
 * 
 * @param operation       Short descriptive for operation being 
 *                        performed.
 * @param nofbytes        Number of bytes transferred so far. 
 *                        Note that this is typeless since it
 *                        could be larger than an int/long.
 * @param total_nofbytes  Total number of bytes to transfer. 
 *                        Note that this is typeless since it
 *                        could be larger than an int/long.
 */
void _ftpclientProgressCB(_str operation, typeless nofbytes, typeless total_nofbytes)
{
   _str caption;
   _str nofbytes_text, total_nofbytes_text;
   int val;

   formWid := _ftpclientQFormWid();
   if( !formWid ) {
      return;
   }
   label1Wid := formWid._find_control('_ctl_progress_label1');
   if( !label1Wid ) {
      return;
   }
   label2Wid := formWid._find_control('_ctl_progress_label2');
   if( !label2Wid ) {
      return;
   }
   gaugeWid := formWid._find_control('_ctl_progress');
   if( !gaugeWid ) {
      return;
   }
   groupWid := formWid._find_control('_ctl_group1');
   if( !groupWid ) {
      return;
   }
   buttonWid := formWid._find_control('_ctl_abort');
   if( !buttonWid ) {
      return;
   }
   //say('nofbytes='nofbytes'  total_nofbytes='total_nofbytes);

   // Max the label widths
   int max1_width = (buttonWid.p_x - groupWid.p_x) - 2*_dx2lx(SM_TWIP,4);
   if( max1_width < 0 ) {
      max1_width = 0;
   }
   label1Wid.p_x = groupWid.p_x;
   label1Wid.p_width = max1_width;
   int max2_width = (gaugeWid.p_x - groupWid.p_x) - 2*_dx2lx(SM_TWIP,4);
   if( max2_width < 0 ) {
      max2_width = 0;
   }
   label2Wid.p_x = label1Wid.p_x;
   label2Wid.p_width = max2_width;

   label1_text := strip(operation);
   label2_text := "";
   //label1_text = "Really long long long long long long operation";
   if( nofbytes == total_nofbytes ) {
      label2_text = 'Complete';
      gaugeWid.p_value = 100;
   } else if( nofbytes >= 0 && total_nofbytes > 0 && nofbytes <= total_nofbytes ) {
      nofbytes_text = nofbytes;
      if( nofbytes > 1024 ) {
         nofbytes_text = round( nofbytes/1024, 0 );
         nofbytes_text :+= 'K';
      }
      if( total_nofbytes > 1024*1024 ) {
         total_nofbytes_text = round( total_nofbytes / (1024*1024), 1 );
         total_nofbytes_text :+= 'M';
      } else if( total_nofbytes > 1024 ) {
         total_nofbytes_text = round( total_nofbytes / 1024, 1 );
         total_nofbytes_text :+= 'K';
      }
      label2_text = nofbytes_text:+' / ':+total_nofbytes_text;

      val = (int)(100.0 * ((double)nofbytes / (double)total_nofbytes));
      gaugeWid.p_value = val;
   } else {
      label2_text = nofbytes:+' bytes';
      gaugeWid.p_value = 0;
   }

   label1Wid.p_caption = label1_text;
   label2Wid.p_caption = label2_text;
}

void __ftpclientUpdateRemoteSessionCB( FtpQEvent *pEvent )
{
   FtpQEvent event;
   FtpRecvCmd rcmd;
   FtpConnProfile fcp;
   FtpConnProfile *fcp_p;

   typeless i=0;
   typeless status=0;
   cmd := "";
   msg := "";

   event= *((FtpQEvent *)(pEvent));
   rcmd= (FtpRecvCmd)event.info[0];
   fcp=event.fcp;

   if( _ftpQEventIsError(event) || _ftpQEventIsAbort(event) ) {
      if( event.event==QE_RECV_CMD && _ftpQEventIsError(event) ) {
         rcmd= (FtpRecvCmd)event.info[0];
         parse rcmd.cmdargv[0] with cmd .;
         if( upcase(cmd)=="LIST" && fcp.resolveLinks ) {
            // Ask the user if they would like to retry the listing without resolving links
            msg='The error you received may have been caused by the "Resolve links" ':+
                'option you have turned ON for this connection profile.':+"\n\n":+
                'The "Resolve links" option can be turned OFF permanently from the ':+
                'Advanced tab of the "Create FTP Profile" dialog ("File"..."FTP"...':+
                '"Profile Manager", pick a profile and click "Edit").':+"\n\n":+
                'Turn OFF "Resolve links" for this session?';
            status=_message_box(msg,FTP_ERRORBOX_TITLE,MB_YESNO|MB_ICONQUESTION);
            if( status==IDYES ) {
               // User wants to retry the LIST w/out resolving links, so
               // turn off ResolveLinks and fake us into thinking we just
               // did a PWD in order to force a re-listing.
               event.event=QE_PWD;
               event.state=0;
               fcp.resolveLinks=false;
               // Find the matching connection profile in current connections
               // so we can change its ResolveLinks field.
               fcp_p=null;
               for( i._makeempty();; ) {
                  _ftpCurrentConnections._nextel(i);
                  if( i._isempty() ) break;
                  FtpConnProfile currentconn=_ftpCurrentConnections:[i];
                  if( _ftpCurrentConnections:[i].profileName==fcp.profileName &&
                      _ftpCurrentConnections:[i].instance==fcp.instance ) {
                     // Found it
                     fcp_p= &(_ftpCurrentConnections:[i]);
                     break;
                  }
               }
               if( fcp_p ) {
                  fcp_p->resolveLinks=fcp.resolveLinks;
               }
            } else {
               // Nothing to do
               return;
            }
         } else if( upcase(cmd)=="LIST" ) {
            if( fcp.system==FTPSYST_MVS && !fcp.ignoreListErrors && substr(fcp.remoteCwd,1,1)!='/' ) {
               msg="Some MVS hosts return an error when listing the ":+
                   "contents of an empty PDS\n\nIgnore this error?";
               status=_message_box(msg,"FTP",MB_YESNO);
               if( status==IDYES ) {
                  // Ignore all LIST errors for this session
                  fcp.ignoreListErrors=true;
                  // Find the matching connection profile in current connections
                  // so we can change its IgnoreListErrors field.
                  fcp_p=null;
                  for( i._makeempty();; ) {
                     _ftpCurrentConnections._nextel(i);
                     if( i._isempty() ) break;
                     FtpConnProfile currentconn=_ftpCurrentConnections:[i];
                     if( _ftpCurrentConnections:[i].profileName==fcp.profileName &&
                         _ftpCurrentConnections:[i].instance==fcp.instance ) {
                        // Found it
                        fcp_p= &(_ftpCurrentConnections:[i]);
                        break;
                     }
                  }
                  if( fcp_p ) {
                     fcp_p->ignoreListErrors=fcp.ignoreListErrors;
                  }
               }
            }
            // Fool this callback into thinking we got a 0 byte listing
            temp_view_id := 0;
            int orig_view_id=_create_temp_view(temp_view_id);
            if( orig_view_id=="" ) return;
            if( !_on_line0() ) _delete_line();
            _save_file('+o '_maybe_quote_filename(rcmd.dest));
            _delete_temp_view(temp_view_id);
            p_window_id=orig_view_id;
            event.event=QE_RECV_CMD;
            event.state=0;
         } else {
            // Nothing to do
            return;
         }
      } else {
         // Nothing to do
         return;
      }
   }

   if( event.event==QE_PWD ) {
      // We just printed the current working directory.
      // Now we must list its contents.

      /*
      typedef struct RecvCmd_s {
         bool pasv;
         _str cmdargv[];
         _str dest;
         _str datahost;
         _str dataport;
         int  size;
         pfnProgressCallback_tp ProgressCB;
      } RecvCmd_t;
      */
      typeless tempCB = __ftpclientUpdateRemoteSessionCB;
      fcp.postedCb = tempCB;
      typeless pasv= (fcp.useFirewall && fcp.global_options.fwenable && fcp.global_options.fwpasv );
      typeless cmdargv;
      cmdargv._makeempty();
      cmdargv[cmdargv._length()] = "LIST";
      // LIST gets really confused with more than one
      // option switch (it interprets the second option
      // as a filespec??), so we have to glom all options
      // together. Example: '-AL' instead of '-A -L'
      options := '-';
      if( fcp.system == FTPSYST_UNIX ) {
         options :+= 'A';
      }
      if( fcp.resolveLinks ) {
         options :+= 'L';
      }
      if( options != '-' ) {
         cmdargv[cmdargv._length()] = options;
      }
      _str dest=mktemp();
      if( dest=="" ) {
         msg="Unable to create temp file for remote directory listing";
         ftpDisplayError(msg);
         return;
      }
      datahost := "";
      dataport := "";
      size := 0;
      // Always transfer listings ASCII
      FtpXferType xfer_type = FTPXFER_ASCII;
      rcmd.pasv=pasv;
      rcmd.cmdargv=cmdargv;
      rcmd.dest=dest;
      rcmd.datahost=datahost;
      rcmd.dataport=dataport;
      rcmd.size=size;
      rcmd.xfer_type=xfer_type;
      rcmd.progressCb=_ftpclientProgressCB;
      _ftpIdleEnQ(QE_RECV_CMD,QS_BEGIN,0,&fcp,rcmd);
      return;
   }

   if( _ftpdebug&FTPDEBUG_SAVE_LIST ) {
      // Make a copy of the raw listing
      temp_path := _temp_path();
      _maybe_append_filesep(temp_path);
      list_filename := temp_path:+"$list";
      copy_file(rcmd.dest,list_filename);
   }
   status=_ftpParseDir(&fcp,fcp.remoteDir,fcp.remoteFileFilter,rcmd.dest);
   typeless status2=delete_file(rcmd.dest);
   if( status2 && status2!=FILE_NOT_FOUND_RC && status2!=PATH_NOT_FOUND_RC ) {
      msg='Warning: Could not delete temp file "':+rcmd.dest:+'".  ':+_ftpGetMessage(status2);
      ftpDisplayError(msg);
   }
   if( status ) {
      formWid := _ftpclientQFormWid();
      if( !formWid ) return;
      noconnWid := formWid._find_control("_ctl_no_connection");
      if( noconnWid ) {
         noconnWid.p_caption="(No listing)";
      }
      msg="Could not create remote directory listing";
      ftpDisplayError(msg);
      return;
   }

   // Find the matching connection profile in current connections
   // so we can update its stored remote directory listing.
   fcp_p=null;
   for( i._makeempty();; ) {
      _ftpCurrentConnections._nextel(i);
      if( i._isempty() ) break;
      FtpConnProfile currentconn=_ftpCurrentConnections:[i];
      if( _ftpCurrentConnections:[i].profileName==fcp.profileName &&
          _ftpCurrentConnections:[i].instance==fcp.instance ) {
         // Found it
         fcp_p= &(_ftpCurrentConnections:[i]);
         break;
      }
   }
   if( !fcp_p ) {
      // We didn't find the matching connection profile, so bail out
      return;
   }
   fcp_p->remoteDir=fcp.remoteDir;
   fcp_p->remoteCwd=fcp.remoteCwd;

   sstabWid := 0;
   profileWid := 0;
   localWid := 0;
   remoteWid := 0;
   formWid := _ftpclientQFormWid();
   if( !formWid ) return;
   if( _ftpclientFindAllControls(formWid,sstabWid,profileWid,localWid,remoteWid) ) {
      // This should never happen
      return;
   }
   remotecwdWid := formWid._find_control("_ctl_remote_cwd");
   if( !remotecwdWid ) return;
   noconnWid := formWid._find_control("_ctl_no_connection");
   if( !noconnWid ) return;
   logWid := formWid._find_control("_ctl_log");
   if( !logWid ) return;
   nologWid := formWid._find_control("_ctl_no_log");
   if( !nologWid ) return;

   cwd := "";
   _ftpclientChangeRemoteDirOnOff(0);
   status=remoteWid._ftpclientRefreshRemoteDir(fcp_p);
   _ftpclientChangeRemoteDirOnOff(1);
   if( !status ) {
      remoteWid._ftpRemoteRestorePos();
      remoteWid._ftpRemoteSavePos();
      remoteWid.p_visible=true;
      remotecwdWid.p_visible=true;
      cwd=fcp_p->remoteCwd;
      _ftpclientChangeRemoteCwdOnOff(0);
      _ftpAddCwdHist(fcp_p->cwdHist,cwd);
      remotecwdWid.p_text=cwd;
      remotecwdWid._set_sel(1,length(cwd)+1);
      _ftpclientChangeRemoteCwdOnOff(1);
      call_list('_ftpCwdHistoryAddRemove_',formWid);
   }
   noconnWid.p_visible= !remoteWid.p_visible;

   // Attach the current connection profile's log buffer to the "Log" tab
   if( fcp_p->logBufName!="" ) {
      logWid.p_visible=true;
      nologWid.p_visible=false;
      logWid._ftpclientAttachLog(fcp_p->logBufName);
   } else {
      logWid.p_visible=false;
      nologWid.p_visible=true;
   }

   _MaybeUpdateFTPTab(profileWid.p_text);
}

// Attach the current connection profile's directory listing, log buffer,etc.
// Note: force=true means force a refresh of the current connection
static void _UpdateRemoteSession(bool force)
{
   FtpConnProfile fcp;

   FtpConnProfile *fcp_p = GetCurrentConnProfile();
   if ( fcp_p ) {

      if ( force || fcp_p->remoteDir._isempty() ) {
         fcp = *fcp_p;   // Make a copy
         if ( fcp.serverType == FTPSERVERTYPE_SFTP ) {
            fcp.postedCb = (typeless)__sftpclientUpdateRemoteSessionCB;
            _ftpSyncEnQ(QE_SFTP_DIR, QS_BEGIN, 0, &fcp);
         } else {
            // FTP
            fcp.postedCb = (typeless)__ftpclientUpdateRemoteSessionCB;
            _ftpSyncEnQ(QE_PWD, QS_BEGIN, 0, &fcp);
         }
         return;
      }

      // Generate remote directory list
      _ftpclientChangeRemoteDirOnOff(0);
      int status = _ctl_remote_dir._ftpclientRefreshRemoteDir(fcp_p);
      _ftpclientChangeRemoteDirOnOff(1);
      if ( !status ) {
         _ctl_remote_dir._ftpRemoteRestorePos();
         _ctl_remote_dir._ftpRemoteSavePos();
         _ctl_remote_dir.p_visible = true;
         _ctl_remote_cwd.p_visible = true;
         _str cwd = fcp_p->remoteCwd;
         _ftpclientChangeRemoteCwdOnOff(0);
         _ctl_remote_cwd._ftpclientFillCwdHistory(false);
         // Not strictly necessary since cwd should already be in the history, but it can't hurt
         _ftpAddCwdHist(fcp_p->cwdHist, cwd);
         _ctl_remote_cwd.p_text = cwd;
         _ctl_remote_cwd._set_sel(1, length(cwd) + 1);
         _ftpclientChangeRemoteCwdOnOff(1);
      }
      _ctl_no_connection.p_visible = !_ctl_remote_dir.p_visible;

      // Attach the current connection profile's log buffer to the "Log" tab
      if ( fcp_p->logBufName != '' ) {
         _ctl_log.p_visible = true;
         _ctl_no_log.p_visible = false;
         _ctl_log._ftpclientAttachLog(fcp_p->logBufName);
      } else {
         _ctl_log.p_visible = false;
         _ctl_no_log.p_visible = true;
      }
      return;
   } else {
      _ctl_remote_dir.p_visible = false;
      _ctl_remote_cwd.p_visible = false;
      _ctl_no_connection.p_visible = true;
      _ctl_log.p_visible = false;
      _ctl_no_log.p_visible = true;
   }

   _MaybeUpdateFTPTab(_ctl_profile.p_text);
}

void _ftpclientUpdateRemoteSession(bool force)
{
   int formWid;

   formWid=_ftpclientQFormWid();
   if( formWid==0 ) {
      return;
   }
   formWid._UpdateRemoteSession(force);
}

static void _UpdateSession(bool force)
{
   _UpdateLocalSession();
   _UpdateRemoteSession(force);
}

void _ftpclientUpdateSession(bool force)
{
   int formWid;

   formWid=_ftpclientQFormWid();
   if( formWid==0 ) {
      return;
   }
   formWid._UpdateSession(force);
}

void _ctl_profile.on_change(int reason)
{
   if( !_ftpclientChangeProfileOnOff() ) return;

   _ctl_profile._ftpclientChangeProfile();
   // Remember current profile.
   // Must do this here because exiting the editor does not call a control's
   // ON_DESTROY event.
   _append_retrieve(_ctl_profile,_ctl_profile.p_text);
   _ctl_profile._UpdateSession(false);
}

static void _ftpclientMaybeReconnect(FtpConnProfile* fcp_p)
{
   if( !_ftpIsConnectionAlive(fcp_p) ) {
      _ftpLog(fcp_p,"Lost connection on ":+_date():+" at ":+_time('m'):+". Attempting to reconnect...");
      // fcp_p could be a pointer into the _ftpCurrentConnections:[]
      // hash table, so make a copy so that _ftpclientDisconnect() can
      // successfully remove the connection from the hash table.
      FtpConnProfile fcp = *fcp_p;
      // Restart the connection.
      // IMPORTANT:
      // fcp will not be updated by _ftpclient* functions, but
      // the last event processed will contain a most-recent
      // copy of the connection that we can use to set fcp
      // contents with.
      FtpQEvent le; // last event
      le.event=0;
      le.state=0;
      le.start=0;
      le.fcp= fcp;
      _str remoteCwd = fcp_p->remoteCwd;
      _str localCwd = fcp_p->localCwd;
      _ftpclientDisconnect(&fcp,true,true,le);
      fcp = le.fcp;
      // Set .DefRemoteHostDir, .DefLocalHostDir so user gets restored
      // to exactly where they were before they were disconnected.
      fcp.defRemoteDir=remoteCwd;
      fcp.defLocalDir=localCwd;
      _ftpclientConnect(&fcp,true,true,le);
      // le.fcp should contain the final connected profile, so
      // copy it into fcp_p now.
      *fcp_p = le.fcp;
   }
}

void __ftpclientConnectCB( FtpQEvent *pEvent, typeless isReconnecting="" )
{
   FtpQEvent event;
   FtpConnProfile fcp;
   _str CwdHist[];

   event= *((FtpQEvent *)(pEvent));
   reconnecting := ( isReconnecting!="" && isReconnecting );

   fcp=event.fcp;
   fcp.postedCb=null;   // Paranoid
   formWid := _ftpclientQFormWid();
   profileWid := label1Wid := label2Wid := progressWid := 0;
   if( formWid ) {
      profileWid=formWid._find_control("_ctl_profile");
      label1Wid=formWid._find_control("_ctl_progress_label1");
      label2Wid=formWid._find_control("_ctl_progress_label2");
      progressWid=formWid._find_control("_ctl_progress");
   }

   if( _ftpQEventIsError(event) || _ftpQEventIsAbort(event) ) {
      if( event.event!=QE_CWD && event.event!=QE_PWD && event.event!=QE_SYST ) {
         if( formWid>0 ) {
            label1Wid.p_caption="";
            label2Wid.p_caption="";
            progressWid.p_value=0;
         }
         return;
      }
      // The only thing that failed is:
      //   Changing directory, so use '/'
      //   OR
      //   Issuing the SYST command to get the operating system name
      if( event.event==QE_CWD || event.event==QE_PWD ) {
         switch( fcp.system ) {
         case FTPSYST_VMS:
         case FTPSYST_VMS_MULTINET:
            fcp.remoteCwd='>';
            break;
         case FTPSYST_VOS:
            // No idea what to set this to
            fcp.remoteCwd="";
            break;
         case FTPSYST_VM:
         case FTPSYST_VMESA:
            // No idea what to set this to
            fcp.remoteCwd="";
            break;
         case FTPSYST_MVS:
            // No idea what to set this to
            fcp.remoteCwd="";
            break;
         case FTPSYST_OS2:
            // No idea what to set this to
            fcp.remoteCwd="";
            break;
         case FTPSYST_OS400:
            // No idea what to set this to
            fcp.remoteCwd="";
            break;
         case FTPSYST_NETWARE:
         case FTPSYST_MACOS:
         case FTPSYST_VXWORKS:
         case FTPSYST_UNIX:
         default:
            fcp.remoteCwd="/";
         }
      }
   }

   if( event.event==QE_CWD || event.event==QE_PWD ) {
      // Still need to get operating system name
      if( reconnecting ) {
         // Must be synchronous in order connect BEFORE attempting operations
         fcp.postedCb=(typeless)__ftpclientConnect2CB;
         _ftpSyncEnQ(QE_SYST,QS_BEGIN,0,&fcp);
      } else {
         fcp.postedCb=(typeless)__ftpclientConnectCB;
         _ftpIdleEnQ(QE_SYST,QS_BEGIN,0,&fcp);
      }
      return;
   }

   // Now set the local current working direcotry
   _str cwd=fcp.defLocalDir;
   cwd=strip(cwd);
   if( cwd=="" ) cwd=getcwd();
   _maybe_strip_filesep(cwd);
   typeless isdir=isdirectory(_maybe_quote_filename(cwd));
   if( (isdir=="" || isdir=="0") && !isuncdirectory(cwd) ) {
      // Not a valid local directory
      cwd=getcwd();
      ftpDisplayWarning("Warning: Unable to change to local directory:\n\n":+
                        fcp.defLocalDir:+"\n\nThe local current working directory is:\n\n":+
                        cwd);
   }
   fcp.localCwd=cwd;

   _ftpGetCwdHist(fcp.profileName,CwdHist);
   fcp.cwdHist=CwdHist;
   typeless htindex;
   _ftpAddCurrentConnProfile(&fcp,htindex);

   if( formWid==0 ) {
      // This could happen if user closes FTP Client toolbar in the middle
      // of the connection attempt.
      return;
   }
   if( !reconnecting ) {
      profileWid._ftpclientFillProfiles(true);
      profileWid._ftpclientChangeProfile(htindex);
      formWid._UpdateSession(true);
      call_list('_ftpProfileAddRemove_',formWid);
   }

   label1Wid.p_caption="Connected";
   label2Wid.p_caption="";
   progressWid.p_value=100;
}
/**
 * Used when reconnecting a lost connection.
 */
void __ftpclientConnect2CB( FtpQEvent *pEvent )
{
   __ftpclientConnectCB(pEvent, true);
}

/**
 * Start a connection profile to S/FTP server.
 * 
 * @param fcp_p Pointer to ftpConnProfile_t connection profile
 *              structure.
 * @param sync  Set to true to specify a synchronous connect
 *              (i.e. does not return until connection is complete).
 * @param reconnecting (optional). Set to true if this profile is being
 *                     reconnected in order to keep existing log buffer
 *                     and currently selected items in the tree view.
 *                     A call to _ftpopenDisconnect() usually precedes
 *                     this function.
 *                     Defaults to false.
 * @param last_event   (optional). The last event processed. Use this to
 *                     check for error/abort conditions, and to harvest
 *                     a connection for further processing.
 */
static void _ftpclientConnect(FtpConnProfile* fcp_p, bool sync,
                              bool reconnecting=false, FtpQEvent& lastEvent=null)
{
   FtpConnProfile fcp;
   FtpQEvent le;

   fcp = *fcp_p;

   // Note:
   // sync parameter is ignored for now. Operations are always
   // synchronous. The user will still have the opportunity to
   // cancel the connection in progress, so this is okay.
   if( fcp.serverType==FTPSERVERTYPE_SFTP ) {
      // SFTP
      if( reconnecting ) {
         fcp.postedCb= (typeless)__sftpclientConnect2CB;
      } else {
         fcp.postedCb= (typeless)__sftpclientConnectCB;
      }
      le = _ftpSyncEnQ(QE_SSH_START_CONN_PROFILE,QS_BEGIN,0,&fcp);
   } else {
      // FTP
      if( reconnecting ) {
         fcp.postedCb= (typeless)__ftpclientConnect2CB;
      } else {
         fcp.postedCb= (typeless)__ftpclientConnectCB;
      }
      le = _ftpSyncEnQ(QE_START_CONN_PROFILE,QS_BEGIN,0,&fcp);
   }
   if( lastEvent!=null ) {
      lastEvent=le;
   }
}

void _ftpProfileAddRemove_ftpclient(typeless fromFormWid=0)
{
   formWid := _ftpclientQFormWid();
   if( !formWid || formWid == fromFormWid ) {
      return;
   }
   profileWid := formWid._find_control('_ctl_profile');
   profileWid._ftpclientFillProfiles(false);
}

/**
 * Start a connection to S/FTP server.
 */
_command void ftpclientConnect() name_info(','VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   FtpConnProfile fcp;

   fcp._makeempty();
   typeless status=show("-modal _ftpProfileManager_form",&fcp);
   if( status ) {
      return;
   }

   formWid := _ftpclientQFormWid();
   if( formWid>0 ) {
      _control _ctl_progress_lable1, _ctl_progress_label2, _ctl_progress;
      formWid._ctl_progress_label1.p_caption="Connecting...";
      formWid._ctl_progress_label2.p_caption="";
      formWid._ctl_progress.p_value=0;
   }
   _ftpclientConnect(&fcp,true);
}

void _ctl_connect.lbutton_up()
{
   ftpclientConnect();
}

void __ftpclientDisconnectCB( FtpQEvent *pEvent, typeless isReconnecting="" )
{
   FtpQEvent event;

   event= *((FtpQEvent *)(pEvent));
   reconnecting := ( isReconnecting!="" && isReconnecting );

   if( !reconnecting ) {
      _ftpDeleteLogBuffer(&event.fcp);   // Paranoid
   }
   _ftpRemoveCurrentConnProfile(&event.fcp);

   formWid := _ftpclientQFormWid();
   if( formWid==0 ) {
      // This could happen if user closes FTP Client toolbar in the middle
      // of the connection attempt.
      return;
   }
   profileWid := formWid._find_control("_ctl_profile");
   label1Wid := formWid._find_control("_ctl_progress_label1");
   label2Wid := formWid._find_control("_ctl_progress_label2");
   gaugeWid := formWid._find_control("_ctl_progress");

   if( !reconnecting ) {
      profileWid._ftpclientFillProfiles(true);
      profileWid._ftpclientChangeProfile();
   }

   if( formWid._ctl_profile.p_text=="" ) {
      // No more connections, so leave a final message
      label1Wid.p_caption="Disconnected";
      label2Wid.p_caption="";
      gaugeWid.p_value=0;
   } else {
      label1Wid.p_caption="";
      label2Wid.p_caption="";
      gaugeWid.p_value=0;
   }

   if( !reconnecting ) {
      profileWid._UpdateSession(false);
      call_list('_ftpProfileAddRemove_',formWid);
   }
}
/**
 * Used when reconnecting a lost connection.
 */
void __ftpclientDisconnect2CB( FtpQEvent *pEvent )
{
   __ftpclientDisconnectCB(pEvent, true);
}

/**
 * Disconnect a connection to S/FTP server.
 * 
 * @param fcp_p Pointer to ftpConnProfile_t connection profile
 *              structure.
 * @param sync  Set to true to specify a synchronous disconnect
 *              (i.e. does not return until disconnection is complete).
 * @param reconnecting (optional). Set to true if this profile is being
 *                     reconnected in order to keep existing log buffer
 *                     and currently selected items in the tree view.
 *                     A call to _ftpopenConnect() is expected to follow
 *                     this function.
 *                     Defaults to false.
 * @param last_event   (optional). The last event processed. Use this to
 *                     check for error/abort conditions, and to harvest
 *                     a connection for further processing.
 */
static void _ftpclientDisconnect(FtpConnProfile* fcp_p, bool sync,
                                 bool reconnecting=false, FtpQEvent& lastEvent=null)
{
   _ftpSaveCwdHist(fcp_p->profileName,fcp_p->cwdHist);
   FtpQEvent le;
   // Note:
   // Both FTP _and_ SFTP can use the same callback.
   //
   // Note:
   // sync parameter is ignored for now. Operations are always
   // synchronous.
   if( reconnecting ) {
      fcp_p->postedCb= (typeless)__ftpclientDisconnect2CB;
   } else {
      fcp_p->postedCb= (typeless)__ftpclientDisconnectCB;
   }
   if( fcp_p->serverType==FTPSERVERTYPE_SFTP ) {
      le = _ftpSyncEnQ(QE_SSH_END_CONN_PROFILE,QS_BEGIN,0,fcp_p);
   } else {
      // FTP
      le = _ftpSyncEnQ(QE_END_CONN_PROFILE,QS_BEGIN,0,fcp_p);
   }
   if( lastEvent!=null ) {
      lastEvent=le;
   }
}

/**
 * Disconnect active connection to S/FTP server.
 */
_command void ftpclientDisconnect() name_info(','VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   _control _ctl_profile, _ctl_progress_label1, _ctl_progress_label2, _ctl_progress;
   formWid := _ftpclientQFormWid();
   if( formWid==0 ) {
      // Nothing to do
      return;
   }

   FtpConnProfile* fcp_p = formWid.GetCurrentConnProfile();

   if( fcp_p ) {
      formWid._ctl_progress_label1.p_caption="Disconnecting...";
      formWid._ctl_progress_label2.p_caption="";
      formWid._ctl_progress.p_value=0;
      _ftpclientDisconnect(fcp_p,true);
   }
   formWid._ctl_profile._ftpclientChangeProfile();
   formWid._ctl_profile._UpdateSession(false);
}

void _ctl_disconnect.lbutton_up()
{
   FtpConnProfile* fcp_p = p_active_form.GetCurrentConnProfile();
   if( fcp_p ) {
      _ftpclientDisconnect(fcp_p,true);
   }
}

static void _UpdateFTPTabXferType()
{
   FtpConnProfile *fcp_p;
   int formWid;
   int asciiWid;
   int binWid;
   int xfer_type;

   formWid=_ftpclientQFormWid();
   if( !formWid ) return;
   fcp_p=formWid.GetCurrentConnProfile();
   if( !fcp_p ) return;
   profileWid := formWid._find_control("_ctl_profile");
   if( !profileWid ) return;
   thisprofile := profileWid.p_text;

   // _ftpopenQFormWid() gets the FTP Open tool window id (not the FTP Client)
   formWid=_ftpopenQFormWid();
   //formWid=_find_formobj("_tbFTPOpen_form","N");
   if( !formWid ) return;
   profileWid=formWid._find_control("_ctl_profile");
   if( !profileWid ) return;

   if( thisprofile!=profileWid.p_text ) return;

   xfer_type=fcp_p->xferType;   // This had better match what is displayed

   asciiWid=formWid._find_control("_ctl_ascii");
   if( !asciiWid ) return;   // This should never happen
   binWid=formWid._find_control("_ctl_binary");
   if( !binWid ) return;   // This should never happen
   asciiWid.p_value=binWid.p_value=0;
   asciiWid.p_style=binWid.p_style=PSPIC_FLAT_BUTTON;
   if( xfer_type==FTPXFER_ASCII ) {
      asciiWid.p_value=1;
      asciiWid.p_style=PSPIC_BUTTON;
      binWid.p_value=0;
   } else if( xfer_type==FTPXFER_BINARY ) {
      asciiWid.p_value=0;
      binWid.p_value=1;
      binWid.p_style=PSPIC_BUTTON;
   }
}

void _ctl_ascii.lbutton_up(_str arg1="")
{
   FtpConnProfile *fcp_p;
   nocheck := (arg1!="" && arg1);

   // Both ASCII and Binary cannot be on at the same time
   _ctl_ascii.p_value=1;
   _ctl_ascii.p_style=PSPIC_BUTTON;
   _ctl_binary.p_value=0;
   _ctl_binary.p_style=PSPIC_FLAT_BUTTON;

   fcp_p=GetCurrentConnProfile();
   if( fcp_p ) {
      if( !nocheck && fcp_p->serverType!=FTPSERVERTYPE_FTP ) {
         // Transfer type buttons are disabled for non-FTP server types
         // because the user does not have a choice.
         p_value= (int)(p_value==0);
         _ctl_binary.p_value= (int)(_ctl_binary.p_value==0);
         p_style=_ctl_binary.p_style=PSPIC_FLAT_BUTTON;
         msg := "Setting the transfer mode is not supported for this server type";
         ftpDisplayError(msg);
         return;
      }

      if( p_value ) {
         fcp_p->xferType=FTPXFER_ASCII;
      } else {
         fcp_p->xferType=FTPXFER_BINARY;
      }
   }

   _UpdateFTPTabXferType();
}

void _ctl_binary.lbutton_up(_str arg1="")
{
   FtpConnProfile *fcp_p;
   nocheck := (arg1!="" && arg1);

   // Both ASCII and Binary cannot be on at the same time
   _ctl_binary.p_value=1;
   _ctl_binary.p_style=PSPIC_BUTTON;
   _ctl_ascii.p_value=0;
   _ctl_ascii.p_style=PSPIC_FLAT_BUTTON;

   fcp_p=GetCurrentConnProfile();
   if( fcp_p ) {
      if( !nocheck && fcp_p->serverType!=FTPSERVERTYPE_FTP ) {
         // Transfer type buttons are disabled for non-FTP server types
         // because the user does not have a choice.
         p_value= (int)(p_value==0);
         _ctl_ascii.p_value= (int)(_ctl_ascii.p_value==0);
         p_style=_ctl_ascii.p_style=PSPIC_FLAT_BUTTON;
         msg := "Setting the transfer mode is not supported for this server type";
         ftpDisplayError(msg);
         return;
      }
      if( p_value ) {
         fcp_p->xferType=FTPXFER_BINARY;
      } else {
         fcp_p->xferType=FTPXFER_ASCII;
      }
   }

   _UpdateFTPTabXferType();
}

void __ftpclientAbortCB( FtpQEvent *pEvent )
{
   FtpQEvent event;
   FtpConnProfile fcp;

   event= *((FtpQEvent *)(pEvent));

   fcp=event.fcp;
   if( !_ftpQEventIsError(event) ) {
      formWid := _ftpclientQFormWid();
      if( !formWid ) return;
      label1Wid := formWid._find_control("_ctl_progress_label1");
      if( !label1Wid ) return;
      label2Wid := formWid._find_control("_ctl_progress_label2");
      if( !label2Wid ) return;
      progressWid := formWid._find_control("_ctl_progress");
      if( !progressWid ) return;
      label1Wid.p_caption="Aborted";
      label2Wid.p_caption="";
      progressWid.p_value=0;
   }
}

void _ctl_abort.lbutton_up()
{
   FtpQEvent event;

   if( _ftpQ._length()<1 ) {
      call_list('_ftpQIdle_');
      return;
   }

   event=_ftpQ[0];

   // Find all events in the queue that match this one and delete them.
   int i;
   for( i=0;i<_ftpQ._length();++i ) {
      if( _ftpQ[i].event==event.event ) {
         _ftpQ._deleteel(i);
      }
   }

   if( event.state==QS_ABORT_WAITING_FOR_REPLY ) {
      // The user wants to abort the abort
      if( _ftpQ._length()<1 ) call_list('_ftpQIdle_');
      return;
   }

   // We queue it this way because the original event might have had
   // optional data in the info field that we don't want to lose.
   event.state=QS_ABORT;
   event.start=0;
   _ctl_progress_label1.p_caption="Aborting...";
   _ctl_progress_label2.p_caption="";
   _ctl_progress.p_value=0;
   event.fcp.postedCb=(typeless)__ftpclientAbortCB;
   _ftpQ[0]=event;
}

int _ftpclientFindAllControls(int formWid,
                              int &sstabWid,
                              int &profilecbWid,
                              int &localtreeWid,
                              int &remotetreeWid)
{
   sstabWid=formWid._find_control("_ctl_ftp_sstab");
   if( !sstabWid ) return(1);
   profilecbWid=formWid._find_control("_ctl_profile");
   if( !profilecbWid ) return(1);
   localtreeWid=sstabWid._find_control("_ctl_local_dir");
   if( !localtreeWid ) return(1);
   remotetreeWid=sstabWid._find_control("_ctl_remote_dir");
   if( !remotetreeWid ) return(1);

   return 0;
}

// Common to both local and remote context menus
_command void ftpclientAutoRefresh() name_info(','VSARG2_NCW|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   FtpConnProfile *fcp_p;
   int formWid;

   formWid=_ftpclientQFormWid();
   if( !formWid ) return;
   fcp_p=formWid.GetCurrentConnProfile();
   if( !fcp_p ) return;
   // Toggle AutoRefresh
   fcp_p->autoRefresh= !(fcp_p->autoRefresh);
   if( fcp_p->autoRefresh ) {
      // AutoRefresh was just turned ON, so force a refresh
      formWid._UpdateRemoteSession(true);
   }
}

// Used by both ftpclientUpload() and ftpclientDownload() and their
// callback functions to refresh the local and remote sides of the
// FTP Client toolbar during a recursive transfer. This allows the
// user to see what is going on.
//
// Optional second argument:
// 'L' to only refresh the local side of the client.
// 'R' to only refresh the remote site of the client.
void _ftpclientUpDownLoadRefresh(FtpConnProfile *fcp_p, _str option="")
{
   int formwid,localtree_wid,remotetree_wid,localcwd_wid,remotecwd_wid;
   option=upcase(option);

   // Refresh the local and remote listings so the user sees what is going on
   formwid=_ftpclientQFormWid();
   if( formwid ) {
      // Refresh only remote?
      if( option!='R' ) {
         localtree_wid=formwid._find_control("_ctl_local_dir");
         localcwd_wid=formwid._find_control("_ctl_local_cwd");
         if( localcwd_wid ) {
            old_gchangelocalcwd_allowed := _ftpclientChangeLocalCwdOnOff();
            _ftpclientChangeLocalCwdOnOff(0);
            localcwd_wid.p_text=fcp_p->localCwd;
            _ftpclientChangeLocalCwdOnOff(old_gchangelocalcwd_allowed);
         }
         if( localtree_wid ) {
            localtree_wid._RefreshLocalDir(fcp_p);
         }
      }
      // Refresh only local?
      if( option!='L' ) {
         remotetree_wid=formwid._find_control("_ctl_remote_dir");
         remotecwd_wid=formwid._find_control("_ctl_remote_cwd");
         if( remotecwd_wid ) {
            old_gchangeremotecwd_allowed := _ftpclientChangeRemoteCwdOnOff();
            _ftpclientChangeRemoteCwdOnOff(0);
            remotecwd_wid.p_text=fcp_p->remoteCwd;
            _ftpclientChangeRemoteCwdOnOff(old_gchangeremotecwd_allowed);
         }
         if( remotetree_wid ) {
            remotetree_wid._ftpclientRefreshRemoteDir(fcp_p);
         }
      }
   }
}

void __ftpclientUpload2CB( FtpQEvent *pEvent, _str isPopping="", _str doOverrideList="" );
void __ftpclientUpload3CB( FtpQEvent *pEvent );
void __ftpclientUpload4CB( FtpQEvent *pEvent );
void __ftpclientUpload1CB( FtpQEvent *pEvent )
{
   FtpQEvent event;
   FtpConnProfile fcp;
   FtpConnProfile *fcp_p;
   FtpSendCmd scmd;
   FtpFile file;
   int formWid;
   typeless status=0;
   msg := "";
   cwd := "";

   event= *((FtpQEvent *)(pEvent));
   fcp=event.fcp;
   fcp.postedCb=null;

   formWid=_ftpclientQFormWid();

   if( _ftpQEventIsError(event) || _ftpQEventIsAbort(event) ) {
      formWid=_ftpclientQFormWid();
      // Update the local session back to original
      if( formWid ) formWid._UpdateLocalSession();
      if( !_ftpQEventIsError(event) ) {
         // User aborted
         return;
      }
      // Should only get here when a STOR or MKD failed
      if( event.event!=QE_SEND_CMD && event.event!=QE_MKD ) return;
      if( event.event==QE_SEND_CMD ) {
         scmd= (FtpSendCmd)event.info[0];
         msg='Failed to upload "':+scmd.src:+'"':+
             "\n\nContinue?";
      } else {
         // MKD failed
         _str dirname=event.info[0];
         msg='Failed to make directory "':+dirname:+'"':+
             "\n\nContinue?";
      }
      status=_message_box(msg,"FTP",MB_YESNO);
      if( status!=IDYES ) {
         // Update remote session back to original and stop
         if( fcp.remoteCwd!=fcp.dir_stack[0].remotecwd ) {
            cwd=fcp.dir_stack[0].remotecwd;
            if( fcp.system==FTPSYST_MVS ) {
               if( substr(cwd,1,1)!='/' ) {
                  // Make it absolute for MVS
                  cwd="'":+cwd:+"'";
               }
            }
            ftpclientChangeRemoteDir(cwd);
         } else {
            if( formWid ) formWid._UpdateRemoteSession(false);
         }
         return;
      }
      // Continue with next file/directory
   }

   filename := "";
   typeless size=0;
   if( !fcp.recurseDirs && !fcp.autoRefresh ) {
      // Create "faked" entries in the remote listing that will be visible
      fcp_p=_ftpIsCurrentConnProfile(fcp.profileName,fcp.instance);
      if( fcp_p ) {
         if( !event.info._isempty() ) {
            FtpFile ftpFile;
            int type=FTPFILETYPE_CREATED;
            if( event.event==QE_SEND_CMD ) {
               scmd= (FtpSendCmd)event.info[0];
               filename=scmd.cmdargv[1];
               size=scmd.size;
            } else if( event.event==QE_MKD ) {
               filename= (_str)event.info[0];
               size=0;
               type |= FTPFILETYPE_DIR;
            }
            ftpFile._makeempty();
            _ftpFakeFile(&ftpFile,filename,type,size);
            _ftpInsertFile(fcp_p,ftpFile);
         }
      }
   }

   localcwd := "";
   remotecwd := "";
   filter := strip(fcp.localFileFilter);
   if( filter=="" ) filter=ALLFILES_RE;
   while( fcp.dir_stack._length()>0 ) {
      int idx=_ftpDirStackNext(fcp.dir_stack);
      while( idx>=0 ) {
         _ftpDirStackGetFile(fcp.dir_stack,file);
         if( file._isempty() ) {
            // This should never happen
            idx=_ftpDirStackNext(fcp.dir_stack);
            continue;
         }
         filename=file.filename;
         if( filename=="." || filename==".." ) {
            idx=_ftpDirStackNext(fcp.dir_stack);
            continue;
         } else {
            _ftpDirStackGetLocalCwd(fcp.dir_stack,localcwd);
            _ftpDirStackGetRemoteCwd(fcp.dir_stack,remotecwd);
            if( !(file.type&FTPFILETYPE_DIR) ) {
               // File

               if( filter!=ALLFILES_RE ) {
                  // Match on the filter
                  match := false;
                  _str list=filter;
                  while( list!="" ) {
                     _str filespec=parse_file(list);
                     filespec=strip(filespec,'B','"');
                     if( filespec=="" ) continue;
                     if( _FilespecMatches(filespec,filename) ) {
                        // Found a match
                        match=true;
                        break;
                     }
                  }
                  if( !match ) {
                     idx=_ftpDirStackNext(fcp.dir_stack);
                     continue;
                  }
               }

               _str cmdargv[];
               scmd._makeempty();
               cmdargv._makeempty();
               cmdargv[0]="STOR";
               cmdargv[1]=_ftpUploadCase(&fcp,filename);
               scmd.cmdargv=cmdargv;
               scmd.datahost=scmd.dataport="";
               src := localcwd;
               _maybe_append_filesep(src);
               src :+= filename;
               // Double check to see if exists and to get size for progress gauge
               line := file_match('-P +V ':+_maybe_quote_filename(src),1);
               if( line=="" ) {
                  status=_message_box("The following file does not exist:\n\n":+src:+"\n\nContinue?",
                                      FTP_ERRORBOX_TITLE,MB_OK|MB_YESNO);
                  if( status==IDYES ) {
                     idx=_ftpDirStackNext(fcp.dir_stack);
                     continue;
                  }
                  return;

               }
               scmd.src=src;
               size=substr(line,DIR_SIZE_COL,DIR_SIZE_WIDTH);
               if( !isinteger(size) ) {
                  // This should never happen
                  size=0;
               }
               scmd.size = size;
               scmd.pasv= (fcp.useFirewall && fcp.global_options.fwenable && fcp.global_options.fwpasv);
               scmd.xfer_type=fcp.xferType;
               scmd.progressCb=_ftpclientProgressCB;
               fcp.postedCb=(typeless)__ftpclientUpload1CB;
               _ftpIdleEnQ(QE_SEND_CMD,QS_BEGIN,0,&fcp,scmd);
               return;
            } else if( file.type&FTPFILETYPE_DIR ) {
               // Directory
               local_path := localcwd;
               _maybe_append_filesep(local_path);
               local_path :+= filename;
               flags := 0;
               if( _ftpExists(&fcp,filename,flags) ) {
                  if( flags&FTPFILETYPE_DIR ) {
                     if( fcp.recurseDirs ) {
                        // Directory already exists, so CWD to it
                        // Set fcp.LocalCWD for the push
                        fcp.localCwd=local_path;
                        fcp.postedCb=(typeless)__ftpclientUpload2CB;
                        _ftpIdleEnQ(QE_CWD,QS_BEGIN,0,&fcp,filename);
                        return;
                     } else {
                        // Directory already exists, so process next file/directory
                        idx=_ftpDirStackNext(fcp.dir_stack);
                        continue;
                     }
                  } else {
                     // File exists with the same name as directory name
                     FtpConnProfile fcp_temp;
                     fcp_temp=fcp;
                     fcp_temp.remoteCwd=remotecwd;
                     _str path=_ftpAbsolute(&fcp_temp,filename);
                     msg='Cannot create directory.':+"\n\n":+'The directory "':+filename:+'" already exists as ':+
                         'a file in':+"\n\n":+path:+"\n\nContinue?";
                     status=_message_box(msg,"FTP",MB_OK|MB_YESNO);
                     if( status==IDYES ) {
                        idx=_ftpDirStackNext(fcp.dir_stack);
                        continue;
                     }
                     return;
                  }
               }
               if( fcp.recurseDirs ) {
                  // __ftpclientUpload2CB() processes the MKD then CWD's to it
                  // Set fcp.LocalCWD for the push
                  fcp.localCwd=local_path;
                  fcp.postedCb=(typeless)__ftpclientUpload2CB;
               } else {
                  // __ftpclientUpload1CB() processes the next file/directory
                  // after the successful MKD.
                  fcp.postedCb=(typeless)__ftpclientUpload4CB;
               }
               _ftpIdleEnQ(QE_MKD,QS_BEGIN,0,&fcp,filename);
               return;
            }
         }
         // This should be unreachable
         idx=_ftpDirStackNext(fcp.dir_stack);
      }
      // Pop this directory listing off the stack
      _ftpDirStackPop(fcp.dir_stack);
      // The .extra member stores a stack of remote working directories
      // to match up with the local directories, so we must pop it too.
      FtpDirectory remotedirs[];
      remotedirs=(FtpDirectory [])fcp.extra;
      remotedirs._deleteel(remotedirs._length()-1);
      fcp.extra=remotedirs;
      if( fcp.dir_stack._length()>0 ) {
         // Change the local directory back to previous
         fcp.localCwd=fcp.dir_stack[fcp.dir_stack._length()-1].localcwd;
         // fcp.RemoteCWD will be correct after the CWD/PWD
         // Change the listing back to previous
         fcp.remoteDir=fcp.dir_stack[fcp.dir_stack._length()-1].dir;
         // CWD back to original directory
         cwd=fcp.dir_stack[fcp.dir_stack._length()-1].remotecwd;
         if( fcp.system==FTPSYST_MVS ) {
            if( substr(cwd,1,1)!='/' ) {
               // Make it absolute for MVS
               cwd="'":+cwd:+"'";
            }
         }
         // __ftpclientUpload3CB() processes the CWD/PWD
         fcp.postedCb=(typeless)__ftpclientUpload3CB;
         _ftpIdleEnQ(QE_CWD,QS_BEGIN,0,&fcp,cwd);
         return;
      }
   }
   if( formWid ) {
      if( fcp.recurseDirs || fcp.autoRefresh ) {
         formWid._UpdateRemoteSession(true);
      } else {
         formWid._UpdateRemoteSession(false);
      }
      formWid._UpdateLocalSession();
   }
}

/**
 * Callback used when changing directory and retrieving a listing.
 */
void __ftpclientUpload2CB( FtpQEvent *pEvent, _str isPopping="", _str doOverrideList="" )
{
   FtpQEvent event;
   FtpRecvCmd rcmd;
   FtpConnProfile fcp;
   FtpConnProfile *fcp_p;
   cwd := "";
   cmd := "";
   msg := "";
   typeless status=0;
   typeless status2=0;
   typeless i=0;

   event= *((FtpQEvent *)(pEvent));
   fcp=event.fcp;

   // Indicates that we are in the middle of popping back to the previous
   // directory. No need to do a listing.
   popping := (isPopping != "");

   // Indicates that we should override LISTing the current remote working
   // directory. Probably because the directory we changed to is known to be
   // empty because we just MKD'ed it.
   override_list := (doOverrideList != "");

   if( _ftpQEventIsError(event) || _ftpQEventIsAbort(event) ) {
      if( !_ftpQEventIsError(event) ) {
         // User aborted
         return;
      }
      do_cleanup := true;
      if( !popping ) {
         if( event.event==QE_RECV_CMD ) {
            rcmd= (FtpRecvCmd)event.info[0];
            parse rcmd.cmdargv[0] with cmd .;
            if( upcase(cmd)!="LIST" ) return;
            if( fcp.resolveLinks ) {
               // Ask the user if they would like to retry the listing without resolving links
               msg='The error you received may have been caused by the "Resolve links" ':+
                   'option you have turned ON for this connection profile.':+"\n\n":+
                   'The "Resolve links" option can be turned OFF permanently from the ':+
                   'Advanced tab of the "Create FTP Profile" dialog ("File"..."FTP"...':+
                   '"Profile Manager", pick a profile and click "Edit").':+"\n\n":+
                   'Turn OFF "Resolve links" for this session?';
               status=_message_box(msg,FTP_ERRORBOX_TITLE,MB_YESNO|MB_ICONQUESTION);
               if( status==IDYES ) {
                  // User wants to retry the LIST w/out resolving links, so
                  // turn off ResolveLinks and fake us into thinking we just
                  // did a PWD in order to force a re-listing.
                  event.event=QE_PWD;
                  event.state=0;
                  fcp.resolveLinks=false;
                  // Find the matching connection profile in current connections
                  // so we can change its ResolveLinks field.
                  fcp_p=null;
                  for( i._makeempty();; ) {
                     _ftpCurrentConnections._nextel(i);
                     if( i._isempty() ) break;
                     FtpConnProfile currentconn=_ftpCurrentConnections:[i];
                     if( _ftpCurrentConnections:[i].profileName==fcp.profileName &&
                         _ftpCurrentConnections:[i].instance==fcp.instance ) {
                        // Found it
                        fcp_p= &(_ftpCurrentConnections:[i]);
                        break;
                     }
                  }
                  if( fcp_p ) {
                     fcp_p->resolveLinks=fcp.resolveLinks;
                  }
                  do_cleanup=false;
               }
            } else {
               if( fcp.system==FTPSYST_MVS && !fcp.ignoreListErrors && substr(fcp.remoteCwd,1,1)!='/' ) {
                  msg="Some MVS hosts return an error when listing the ":+
                      "contents of an empty PDS\n\nIgnore this error?";
                  status=_message_box(msg,"FTP",MB_YESNO);
                  if( status==IDYES ) {
                     // Ignore LIST errors from now until the end of this operation
                     fcp.ignoreListErrors=true;
                     do_cleanup=false;
                  }
               } else {
                  msg="Error listing the contents of\n\n":+fcp.remoteCwd:+
                      "\n\nContinue?";
                  status=_message_box(msg,"FTP",MB_YESNO);
                  if( status==IDYES ) {
                     // User elected to continue
                     do_cleanup=false;
                  }
               }
               if( !do_cleanup ) {
                  // Fool this callback into thinking we got a 0 byte listing
                  temp_view_id := 0;
                  int orig_view_id=_create_temp_view(temp_view_id);
                  if( orig_view_id=="" ) return;
                  if( !_on_line0() ) _delete_line();
                  _save_file('+o '_maybe_quote_filename(rcmd.dest));
                  _delete_temp_view(temp_view_id);
                  p_window_id=orig_view_id;
                  event.event=QE_RECV_CMD;
                  event.state=0;
               }
            }
         } else if( event.event==QE_CWD ) {
            cwd=event.info[0];
            msg="Failed to change directory to ":+cwd:+
                "\n\nContinue?";
            status=_message_box(msg,"FTP",MB_YESNO);
            if( status==IDYES ) {
               // fcp.LocalCWD was set in __ftpclientUpload1CB(), so
               // set it back.
               fcp.localCwd=fcp.dir_stack[fcp.dir_stack._length()-1].localcwd;
               event._makeempty();
               event.fcp=fcp;
               event.event=QE_NONE;
               event.state=QS_NONE;
               event.start=0;
               // __ftpclientUpload1CB() processes the next file directory
               __ftpclientUpload1CB(&event);
               return;
            }
         }
      }
      if( do_cleanup ) {
         // If we got here then we need to clean up
         formWid := _ftpclientQFormWid();
         // Update the local session back to original
         if( formWid ) formWid._UpdateLocalSession();
         // Update remote session back to original and stop
         if( fcp.remoteCwd!=fcp.dir_stack[0].remotecwd ) {
            cwd=fcp.dir_stack[0].remotecwd;
            if( fcp.system==FTPSYST_MVS ) {
               if( substr(cwd,1,1)!='/' ) {
                  // Make it absolute for MVS
                  cwd="'":+cwd:+"'";
               }
            }
            ftpclientChangeRemoteDir(cwd);
         } else {
            if( formWid ) formWid._UpdateRemoteSession(false);
         }
         return;
      }
      // Fall through - this usually happens if user elected to retry
      // the listing with fcp.ResolveLinks=false or ignore LIST errors.
   }

   if( event.event==QE_MKD ) {
      // We just created a directory.
      // Now we must change to it.
      cwd=event.info[0];
      // __ftpclientUpload4CB() tells us not to list the directory we will
      // have changed to because it was just created and, therefore, is
      // empty.
      fcp.postedCb=(typeless)__ftpclientUpload4CB;
      _ftpIdleEnQ(QE_CWD,QS_BEGIN,0,&fcp,cwd);
      return;
   }

   dest := "";
   if( !popping && event.event==QE_PWD ) {
      if( override_list ) {
         // List was overridden. Probably because the directory we changed to
         // is known to be empty because we just MKD'ed it.
         //
         // Fool this callback into thinking we got a 0 byte listing.
         dest=mktemp();
         if( dest=="" ) {
            msg="Unable to create temp file for remote directory listing";
            ftpDisplayError(msg);
            return;
         }
         rcmd._makeempty();
         rcmd.dest=dest;
         event.info[0]=rcmd;
         temp_view_id := 0;
         int orig_view_id=_create_temp_view(temp_view_id);
         if( orig_view_id=="" ) return;
         if( !_on_line0() ) _delete_line();
         _save_file('+o '_maybe_quote_filename(rcmd.dest));
         _delete_temp_view(temp_view_id);
         p_window_id=orig_view_id;
         event.event=QE_RECV_CMD;
         event.state=0;
         // Fall thru to list processing below
      } else {
         // We just printed the current working directory.
         // Now we must list its contents.

         /*
         typedef struct RecvCmd_s {
            bool pasv;
            _str cmdargv[];
            _str dest;
            _str datahost;
            _str dataport;
            int  size;
            pfnProgressCallback_tp ProgressCB;
         } RecvCmd_t;
         */
         fcp.postedCb=(typeless)__ftpclientUpload2CB;
         typeless pasv= (fcp.useFirewall && fcp.global_options.fwenable && fcp.global_options.fwpasv );
         typeless cmdargv;
         cmdargv._makeempty();
         cmdargv[0]="LIST";
         if( fcp.resolveLinks ) {
            cmdargv[cmdargv._length()]="-L";
         }
         dest=mktemp();
         if( dest=="" ) {
            msg="Unable to create temp file for remote directory listing";
            ftpDisplayError(msg);
            return;
         }
         datahost := "";
         dataport := "";
         size := 0;
         xfer_type := FTPXFER_ASCII;   // Always transfer listings ASCII
         rcmd.pasv=pasv;
         rcmd.cmdargv=cmdargv;
         rcmd.dest=dest;
         rcmd.datahost=datahost;
         rcmd.dataport=dataport;
         rcmd.size=size;
         rcmd.xfer_type=xfer_type;
         rcmd.progressCb=_ftpclientProgressCB;
         _ftpIdleEnQ(QE_RECV_CMD,QS_BEGIN,0,&fcp,rcmd);
         return;
      }
   }

   if( !popping ) {
      rcmd= (FtpRecvCmd)event.info[0];
      if( _ftpdebug&FTPDEBUG_SAVE_LIST ) {
         // Make a copy of the raw listing
         temp_path := _temp_path();
         _maybe_append_filesep(temp_path);
         list_filename := temp_path:+"$list";
         copy_file(rcmd.dest,list_filename);
      }
      status=_ftpParseDir(&fcp,fcp.remoteDir,fcp.remoteFileFilter,rcmd.dest);
      status2=delete_file(rcmd.dest);
      if( status2 && status2!=FILE_NOT_FOUND_RC && status2!=PATH_NOT_FOUND_RC ) {
         msg='Warning: Could not delete temp file "':+rcmd.dest:+'".  ':+_ftpGetMessage(status2);
         ftpDisplayError(msg);
      }
      if( status ) {
         // Set the local current working directory back to previous
         fcp.localCwd=fcp.dir_stack[fcp.dir_stack._length()-1].localcwd;
         // fcp.RemoteCWD will be set by the CWD/PWD
         // Set the remote directory listing back to previous
         FtpDirectory remotedirs[];
         remotedirs=(FtpDirectory [])fcp.extra;
         fcp.remoteDir=remotedirs[remotedirs._length()-1];
         // CWD back to original directory
         cwd=fcp.dir_stack[fcp.dir_stack._length()-1].remotecwd;
         if( fcp.system==FTPSYST_MVS ) {
            if( substr(cwd,1,1)!='/' ) {
               // Make it absolute for MVS
               cwd="'":+cwd:+"'";
            }
         }
         // __ftpclientUpload3CB() processes the CWD/PWD
         fcp.postedCb=(typeless)__ftpclientUpload3CB;
         _ftpIdleEnQ(QE_CWD,QS_BEGIN,0,&fcp,cwd);
         return;
      } else {
         // Note that fcp.LocalCWD was set in __ftpclientUpload1CB() in
         // anticipation of the push.
         // Must build a local list to push
         FtpDirectory localdir;
         status = _ftpGenLocalDir(&fcp,localdir,fcp.localFileFilter,fcp.localCwd);
         if( status ) {
            if( status!=FILE_NOT_FOUND_RC ) {
               msg="Unable to create a local directory listing for\n\n":+
                   fcp.localCwd:+"\n\n":+get_message(status):+"\n\nContinue?";
               status=_message_box(msg,"FTP",MB_OK|MB_YESNO);
               if( status!=IDYES ) {
                  return;
               }
            }
            // Set the local current working directory back to previous
            fcp.localCwd=fcp.dir_stack[fcp.dir_stack._length()-1].localcwd;
            // fcp.RemoteCWD will be set by the CWD/PWD
            // Set the remote directory listing back to previous
            FtpDirectory remotedirs[];
            remotedirs=(FtpDirectory [])fcp.extra;
            fcp.remoteDir=remotedirs[remotedirs._length()-1];
            // CWD back to original directory
            cwd=fcp.dir_stack[fcp.dir_stack._length()-1].remotecwd;
            if( fcp.system==FTPSYST_MVS ) {
               if( substr(cwd,1,1)!='/' ) {
                  // Make it absolute for MVS
                  cwd="'":+cwd:+"'";
               }
            }
            // __ftpclientUpload3CB() processes the CWD/PWD
            fcp.postedCb=(typeless)__ftpclientUpload3CB;
            _ftpIdleEnQ(QE_CWD,QS_BEGIN,0,&fcp,cwd);
            return;
         }

         #if 1
         // Refresh the local and remote listings so the user sees what is going on
         _ftpclientUpDownLoadRefresh(&fcp);
         #endif

         _ftpDirStackPush(fcp.localCwd,fcp.remoteCwd,&localdir,fcp.dir_stack);
         // The .extra member stores a stack of remote working directories
         // to match up with the local directories, so we must push it too.
         FtpDirectory remotedirs[];
         remotedirs=(FtpDirectory [])fcp.extra;
         remotedirs[remotedirs._length()]=fcp.remoteDir;
         fcp.extra=remotedirs;
         fcp.postedCb=null;
         event._makeempty();
         event.fcp=fcp;
         event.event=QE_NONE;
         event.state=QS_NONE;
         event.start=0;
         // __ftpclientUpload1CB() processes the next file directory
         __ftpclientUpload1CB(&event);
         return;
      }
   }

   // If we got here then we must have just finished popping back to a
   // previous directory, so process the next file directory.
   fcp.postedCb=null;
   if( fcp.dir_stack._length()>0 ) {
      // Change the local directory back to previous
      fcp.localCwd=fcp.dir_stack[fcp.dir_stack._length()-1].localcwd;
      // fcp.RemoteCWD should already be correct
      // Change the remote listing back to previous
      FtpDirectory remotedirs[];
      remotedirs=(FtpDirectory [])fcp.extra;
      fcp.remoteDir=remotedirs[remotedirs._length()-1];

      #if 1
      // Refresh the local and remote listings so the user sees what is going on
      _ftpclientUpDownLoadRefresh(&fcp);
      #endif
   }
   event._makeempty();
   event.fcp=fcp;
   event.event=QE_NONE;
   event.state=QS_NONE;
   event.start=0;
   // __ftpclientUpload1CB() processes the next file directory
   __ftpclientUpload1CB(&event);
}

/**
 * Callback used when popping a directory.
 */
void __ftpclientUpload3CB( FtpQEvent *pEvent )
{
   // The second argument tells __ftpclientUpload2CB() that we are
   // popping the top directory off the stack. No need to do a listing.
   __ftpclientUpload2CB(pEvent, 1);
}

/**
 * Callback used when we just CWD/PWD'ed to a directory that is known
 * to be empty. Probably because the directory we changed to is known to
 * be empty because we just MKD'ed it.
 */
void __ftpclientUpload4CB( FtpQEvent *pEvent )
{
   // The third argument tells __ftpclientUpload2CB() that we do not
   // want to do the LIST command after a CWD/PWD.
   __ftpclientUpload2CB(pEvent, "", 1);
}

_command void ftpclientUpload() name_info(','VSARG2_NCW|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   FtpConnProfile *fcp_p;
   FtpConnProfile fcp;
   FtpDirectory dir;
   FtpFile file;
   FtpQEvent event;
   int formWid;
   sstabWid := 0;
   profileWid := 0;
   localWid := 0;
   remoteWid := 0;

   formWid=_ftpclientQFormWid();
   if( !formWid ) return;
   if( _ftpclientFindAllControls(formWid,sstabWid,profileWid,localWid,remoteWid) ) return;
   fcp_p=formWid.GetCurrentConnProfile();
   if( !fcp_p ) return;
   fcp= *fcp_p;   // Make a copy

   // Check for directories selected
   typeless dirs=false;
   nofselected := 0;
   idx := 0;
   caption := "";
   filename := "";
   typeless size=0;
   typeless modified = '';
   typeless attribs='';
   typeless userinfo='';

   idx=localWid._TreeGetNextSelectedIndex(1,auto treeSelectInfo);
   while( idx>=0 ) {
      caption=localWid._TreeGetCaption(idx);
      parse caption with filename "\t" size "\t" modified "\t" attribs;
      if ( filename != '..' ) {
         int flags = localWid._ftpTreeItemUserInfo2TypeFlags(idx);
         // Filename OR directory
         if ( testFlag(flags, FTPFILETYPE_DIR) ) {
            dirs = true;
            break;
         }
      }
      idx=localWid._TreeGetNextSelectedIndex(0,treeSelectInfo);
   }
   #if 1
   // Decided not to prompt user on upload
   fcp.recurseDirs=true;
   #else
   fcp.RecurseDirs=false;
   if( dirs ) {
      msg="Recursively upload directories?";
      status=_message_box(msg,"FTP",MB_YESNO);
      if( status==IDYES ) {
         fcp.RecurseDirs=true;
      }
   }
   #endif

   // Populate a local directory list with only the selected items
   dir._makeempty();
   dir.flags=0;
   index := 0;
   ff := 1;
   treeSelectInfo = 0;

   for(;;) {
      index=localWid._TreeGetNextSelectedIndex(ff, treeSelectInfo);ff=0;
      if( index<0 ) break;
      caption=localWid._TreeGetCaption(index);
      parse caption with filename "\t" .;
      file._makeempty();
      file.filename=filename;

      // Fill unimportant fields
      file.attribs="";
      file.day=0;
      file.group="";
      file.month="";
      file.owner="";
      file.refs=0;
      file.size=0;
      file.time="";
      file.mtime = '';
      file.year=0;

      int flags = localWid._ftpTreeItemUserInfo2TypeFlags(index);
      file.type = flags & (FTPFILETYPE_DIR | FTPFILETYPE_LINK);
      dir.files[dir.files._length()] = file;
   }

   _ftpclientMaybeReconnect(&fcp);

   _ftpDirStackClear(fcp.dir_stack);
   _ftpDirStackPush(fcp.localCwd,fcp.remoteCwd,&dir,fcp.dir_stack);
   // The .extra member stores a stack of remote working directories
   // to match up with the local directories, so we must push it too.
   FtpDirectory remotedirs[];
   remotedirs._makeempty();
   remotedirs[remotedirs._length()]=fcp.remoteDir;
   fcp.extra=remotedirs;
   event._makeempty();
   event.event=QE_NONE;
   event.state=QS_NONE;
   event.fcp=fcp;
   event.start=0;
   if( fcp.serverType==FTPSERVERTYPE_SFTP ) {
      __sftpclientUpload1CB(&event);
   } else {
      // FTP
      __ftpclientUpload1CB(&event);
   }
}

void __ftpclientManualUploadCB( FtpQEvent *pEvent )
{
   FtpQEvent event;
   FtpConnProfile fcp;
   FtpConnProfile *fcp_p;
   FtpSendCmd scmd;

   event= *((FtpQEvent *)(pEvent));

   fcp=event.fcp;
   if( !_ftpQEventIsError(event) && !_ftpQEventIsAbort(event) ) {
      formWid := _ftpclientQFormWid();
      if( !formWid ) return;

      fcp_p=_ftpIsCurrentConnProfile(fcp.profileName,fcp.instance);
      if( fcp_p ) {
         if( !event.info._isempty() ) {
            dest_dir := "";
            _str curr_dir=_ftpAbsolute(fcp_p,"junk");
            curr_dir=_ftpStripFilename(fcp_p,curr_dir,'NS');
            scmd= (FtpSendCmd)event.info[0];
            if( fcp.serverType==FTPSERVERTYPE_SFTP ) {
               dest_dir=_ftpAbsolute(fcp_p,scmd.cmdargv[0]);
            } else {
               // FTP
               dest_dir=_ftpAbsolute(fcp_p,scmd.cmdargv[1]);
            }
            dest_dir=_ftpStripFilename(fcp_p,dest_dir,'NS');
            if( _ftpFileEq(fcp_p,curr_dir,dest_dir) ) {
               // The desination is the same as the current remote
               // working directory, so refresh the listing.
               if( fcp.autoRefresh ) {
                  formWid._UpdateRemoteSession(true);
               } else {
                  // Create "faked" entries in the remote listing that will be visible
                  FtpFile file;
                  filename := "";
                  int type=FTPFILETYPE_CREATED;
                  if( fcp.serverType==FTPSERVERTYPE_SFTP ) {
                     filename=_ftpAbsolute(fcp_p,scmd.cmdargv[0]);
                  } else {
                     // FTP
                     filename=_ftpAbsolute(fcp_p,scmd.cmdargv[1]);
                  }
                  filename=_ftpStripFilename(fcp_p,filename,'P');
                  int size=scmd.size;
                  file._makeempty();
                  _ftpFakeFile(&file,filename,type,size);
                  _ftpInsertFile(fcp_p,file);
                  formWid._UpdateRemoteSession(false);
               }
            }
         }
      }
   }
}

_command void ftpclientManualUpload() name_info(','VSARG2_NCW|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   FtpConnProfile *fcp_p;
   FtpConnProfile fcp;
   FtpSendCmd scmd;
   _str cmdargv[];

   formWid := _ftpclientQFormWid();
   if( !formWid ) return;
   fcp_p=formWid.GetCurrentConnProfile();
   if( !fcp_p ) return;
   fcp= *fcp_p;   // Make a copy

   // Remember the last filename
   _str local_path=_retrieve_value("_tbFTPClient_form.ManualUpload.LastFilename");

   // Prompt for the local path
   typeless result=show("-modal _ftpManualDownload_form",local_path,0,fcp_p->xferType,"Manual Upload");
   if( result=="" ) {
      // User cancelled
      return;
   }
   local_path=strip(_param1);
   if( local_path=="" ) return;

   // Remember the last filename
   _append_retrieve(0,local_path,"_tbFTPClient_form.ManualUpload.LastFilename");

   i := 0;
   filename := "";
   path := "";
   remote_path := strip(_param2);
   xfer_type := (FtpXferType)_param3;

   local_path=strip(local_path,'B','"');
   if( remote_path=="" ) {
      // Upload to current remote working directory with same filename
      filename=_strip_filename(local_path,'P');
      remote_path=_ftpUploadCase(&fcp,filename);
   } else {
      // User specified a destination
      // Ignored if not MVS host
      mvs_pds := false;
      switch( fcp.system ) {
      case FTPSYST_VMS:
      case FTPSYST_VMS_MULTINET:
         i=lastpos(']',remote_path);
         if( !i ) {
            // Relative to current directory
            path="";
            filename=remote_path;
         } else {
            // Absolute
            path=substr(remote_path,1,i);
            filename=substr(remote_path,i+1);
         }
         // VMS filenames have version numbers at the end (e.g. ";1").
         // We want to save the file without the version number.
         ver := "";
         parse filename with filename ';' ver;
         remote_path=path:+_ftpUploadCase(&fcp,filename);
         break;
      case FTPSYST_VOS:
         if( substr(remote_path,1,1)=='/' ) remote_path=substr(remote_path,2);
         i=lastpos('>',remote_path);
         if( !i ) {
            // Relative to current directory
            path="";
            filename=remote_path;
         } else {
            path=substr(remote_path,1,i);
            filename=substr(remote_path,i+1);
         }
         remote_path=path:+_ftpUploadCase(&fcp,filename);
         break;
      case FTPSYST_VM:
      case FTPSYST_VMESA:
         if( substr(remote_path,1,1)=='/' ) remote_path=substr(remote_path,2);
         // We had to dream up an absolute filespec format because VM
         // has no concept of it. 'path' = CMS minidisk.
         if( !pos('/',remote_path) ) {
            // Relative to current directory
            remote_path=_ftpUploadCase(&fcp,remote_path);
         } else {
            // Absolute
            parse remote_path with path '/' filename;
            remote_path=path:+'/':+_ftpUploadCase(&fcp,filename);
         }
         break;
      case FTPSYST_MVS:
         mvs_quoted := (substr(remote_path,1,1)=="'" && _last_char(remote_path)=="'");
         if( mvs_quoted ) {
            remote_path=strip(remote_path,'B',"'");
         }
         remote_path=_ftpConvertSEtoMVSFilename(remote_path);
         if( substr(remote_path,1,1)=='/' || (!mvs_quoted && substr(fcp.remoteCwd,1,1)=='/') ) {
            // HFS format which mimics Unix
            i=lastpos('/',remote_path);
            if( !i ) {
               // Relative to current HFS directory
               path="";
               filename=remote_path;
            } else {
               path=substr(remote_path,1,i);
               filename=substr(remote_path,i+1);
            }
            remote_path=path:+_ftpUploadCase(&fcp,filename);
         } else {
            // PDS or SDS format
            if( _last_char(remote_path)==')' ) {
               // PDS member
               parse remote_path with path '(' filename ')';
               remote_path=path:+'(':+_ftpUploadCase(&fcp,filename):+')';
            } else {
               // SDS or unknown
               if( mvs_quoted ) {
                  // Absolute SDS
                  i=pos('.',remote_path);
                  path=substr(remote_path,1,i);
                  filename=substr(remote_path,i+1);
                  remote_path=path:+_ftpUploadCase(&fcp,filename);
               } else {
                  remote_path=_ftpUploadCase(&fcp,remote_path);
               }
            }
         }
         if( mvs_quoted ) {
            remote_path="'":+remote_path:+"'";
         }
         break;
      case FTPSYST_OS2:
         if( substr(remote_path,1,1)=='/' ) remote_path=substr(remote_path,2);
         i=lastpos('/',remote_path);
         if( !i ) {
            // Relative to current directory
            path="";
            filename=remote_path;
         } else {
            path=substr(remote_path,1,i);
            filename=substr(remote_path,i+1);
         }
         remote_path=path:+_ftpUploadCase(&fcp,filename);
         break;
      case FTPSYST_OS400:
         remote_path=_ftpConvertSEtoOS400Filename(remote_path);
         if( substr(remote_path,1,1)=='/' || substr(fcp.remoteCwd,1,1)=='/' ) {
            // IFS format which mimics Unix
            i=lastpos('/',remote_path);
            if( !i ) {
               // Relative to current IFS directory
               path="";
               filename=remote_path;
            } else {
               path=substr(remote_path,1,i);
               filename=substr(remote_path,i+1);
            }
            remote_path=path:+_ftpUploadCase(&fcp,filename);
         } else {
            // LFS format
            libname := file := member := "";
            parse remote_path with libname '/' file '.' member;
            remote_path=libname:+'/':+file;
            if( member!="" ) {
               remote_path :+= '.':+_ftpUploadCase(&fcp,member);
            }
         }
         break;
      case FTPSYST_WINNT:
      case FTPSYST_HUMMINGBIRD:
         if( substr(fcp.remoteCwd,1,1)=='/' ) {
            // Unix style
            i=lastpos('/',remote_path);
            if( !i ) {
               // Relative to current directory
               path="";
               filename=remote_path;
            } else {
               path=substr(remote_path,1,i);
               filename=substr(remote_path,i+1);
            }
            remote_path=path:+_ftpUploadCase(&fcp,filename);
         } else {
            // DOS style
            i=lastpos("\\",remote_path);
            if( !i ) {
               // Relative to current directory
               path="";
               filename=remote_path;
            } else {
               path=substr(remote_path,1,i);
               filename=substr(remote_path,i+1);
            }
            remote_path=path:+_ftpUploadCase(&fcp,filename);
         }
         break;
      case FTPSYST_NETWARE:
      case FTPSYST_MACOS:
      case FTPSYST_VXWORKS:
      case FTPSYST_UNIX:
      default:
         i=lastpos('/',remote_path);
         if( !i ) {
            // Relative to current directory
            path="";
            filename=remote_path;
         } else {
            path=substr(remote_path,1,i);
            filename=substr(remote_path,i+1);
         }
         remote_path=path:+_ftpUploadCase(&fcp,filename);
      }
   }
   _str src=_ftpLocalAbsolute(&fcp,local_path);
   // Double check to see if exists and to get size for progress gauge
   line := file_match('-P +V ':+_maybe_quote_filename(src),1);
   if( line=="" ) {
      ftpDisplayError("The following file does not exist:\n\n":+src);
      return;

   }
   typeless size=substr(line,DIR_SIZE_COL,DIR_SIZE_WIDTH);
   if( !isinteger(size) ) {
      // This should never happen
      size=0;
   }

   _ftpclientMaybeReconnect(&fcp);

   if( fcp.serverType==FTPSERVERTYPE_SFTP ) {
      fcp.postedCb=(typeless)__ftpclientManualUploadCB;
      cmdargv._makeempty();
      cmdargv[0]=remote_path;
      scmd.cmdargv=cmdargv;
      scmd.xfer_type=xfer_type;
      scmd.datahost=scmd.dataport="";  // Ignored
      scmd.src=src;
      scmd.size= size;
      scmd.pasv=false;   // Ignored
      scmd.xfer_type=FTPXFER_BINARY;   // Ignored
      scmd.progressCb=_ftpclientProgressCB;
      // Members used specifically by SFTP
      scmd.hfile= -1;
      scmd.hhandle= -1;
      scmd.offset=0;
      _ftpIdleEnQ(QE_SFTP_PUT,QS_BEGIN,0,&fcp,scmd);
   } else {
      // FTP
      fcp.postedCb=(typeless)__ftpclientManualUploadCB;
      cmdargv._makeempty();
      cmdargv[0]="STOR";
      cmdargv[1]=remote_path;
      scmd.cmdargv=cmdargv;
      scmd.xfer_type=xfer_type;
      scmd.datahost=scmd.dataport="";
      scmd.src=src;
      scmd.size= size;
      scmd.pasv= (fcp.useFirewall && fcp.global_options.fwenable && fcp.global_options.fwpasv);
      scmd.xfer_type=fcp.xferType;
      scmd.progressCb=_ftpclientProgressCB;
      _ftpIdleEnQ(QE_SEND_CMD,QS_BEGIN,0,&fcp,scmd);
   }
}

_command void ftpclientOpenLocalFile() name_info(','VSARG2_NCW|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   FtpConnProfile *fcp_p;
   FtpConnProfile fake;

   sstabWid := profileWid := localWid := remoteWid := 0;
   formWid := _ftpclientQFormWid();
   if( !formWid ) return;
   if( _ftpclientFindAllControls(formWid,sstabWid,profileWid,localWid,remoteWid) ) return;
   fcp_p=formWid.GetCurrentConnProfile();
   if( !fcp_p ) {
      // We have no current connection, so fake one
      _ftpInitConnProfile(fake);
      fake.localCwd=LOCALCWD;
      fake.localFileFilter=LOCALFILTER;
      fcp_p=&fake;
   }
   nofselected := localWid._TreeGetNumSelectedItems();
   if( !nofselected ) return;
   mou_hour_glass(true);
   idx := localWid._TreeGetNextSelectedIndex(1,auto treeSelectInfo);
   while( idx>=0 ) {
      caption := localWid._TreeGetCaption(idx);
      filename := "";
      parse caption with filename "\t" .;
      if ( filename == '..' ) {
         idx = localWid._TreeGetNextSelectedIndex(0, treeSelectInfo);
         continue;
      } else {
         int flags = localWid._ftpTreeItemUserInfo2TypeFlags(idx);
         if ( !testFlag(flags, FTPFILETYPE_DIR) ) {
            // We have a file so open it
            cwd := fcp_p->localCwd;
            _maybe_append_filesep(cwd);
            path := cwd:+filename;
            int status=edit(_maybe_quote_filename(path),EDIT_DEFAULT_FLAGS);
            if( status ) {
               msg := 'Error opening file "':+filename:+'".  ':+_ftpGetMessage(status);
               ftpDisplayError(msg);
               break;
            }
         } else if ( testFlag(flags, FTPFILETYPE_DIR) ) {
            // Directory
            idx = localWid._TreeGetNextSelectedIndex(0, treeSelectInfo);
            continue;
         }
      }
      idx = localWid._TreeGetNextSelectedIndex(0, treeSelectInfo);
   }
   refresh();
}

#if 1 /* !__UNIX__ */
_command void ftpclientViewLocalFile() name_info(','VSARG2_NCW|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   if (_isUnix()) return;
   FtpConnProfile *fcp_p;
   FtpConnProfile fake;

   sstabWid := profileWid := localWid := remoteWid := 0;
   formWid := _ftpclientQFormWid();
   if( !formWid ) return;
   if( _ftpclientFindAllControls(formWid,sstabWid,profileWid,localWid,remoteWid) ) return;
   fcp_p=formWid.GetCurrentConnProfile();
   if( !fcp_p ) {
      // We have no current connection, so fake one
      _ftpInitConnProfile(fake);
      fake.localCwd=LOCALCWD;
      fake.localFileFilter=LOCALFILTER;
      fcp_p=&fake;
   }
   nofselected := localWid._TreeGetNumSelectedItems();
   if( !nofselected ) return;
   mou_hour_glass(true);
   idx := localWid._TreeGetNextSelectedIndex(1,auto treeSelectInfo);
   while( idx>=0 ) {
      caption := localWid._TreeGetCaption(idx);
      filename := "";
      parse caption with filename "\t" .;
      if( filename==".." ) {
         idx=localWid._TreeGetNextSelectedIndex(0,treeSelectInfo);
         continue;
      } else {
         int flags = localWid._ftpTreeItemUserInfo2TypeFlags(idx);
         if( !testFlag(flags, FTPFILETYPE_DIR) ) {
            // We have a file so open it
            cwd := fcp_p->localCwd;
            _maybe_append_filesep(cwd);
            path := cwd:+filename;
            int status=_ShellExecute(path);
            if( status<=32 ) {
               msg := 'Error viewing file "':+filename;
               ftpDisplayError(msg);
               break;
            }
         } else if ( testFlag(flags, FTPFILETYPE_DIR) ) {
            // Directory
            idx = localWid._TreeGetNextSelectedIndex(0, treeSelectInfo);
            continue;
         }
      }
      idx = localWid._TreeGetNextSelectedIndex(0, treeSelectInfo);
   }
   refresh();
}
#endif

_command void ftpclientChangeLocalDir(_str cwd="") name_info(','VSARG2_NCW|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   FtpConnProfile *fcp_p;
   FtpConnProfile fake;   // Used when there is no connection
   int formWid;

   formWid=_ftpclientQFormWid();
   if( !formWid ) return;
   fcp_p=GetCurrentConnProfile();
   if( !fcp_p ) {
      // There is currently no connection, so make a fake connection profile
      _ftpInitConnProfile(fake);
      fake.localCwd=LOCALCWD;
      if( fake.localCwd=="" ) {
         fake.localCwd=getcwd();
      }
      fake.localFileFilter=LOCALFILTER;
      fcp_p=&fake;
   }
   typeless result=0;
   if( cwd=="" ) {
      // Prompt for the local directory
      #if 1
      //result=show("-modal _ftpChangeDir_form","Change local directory","",fcp_p,FTPLOCALDIR_ARG);
      result=show("-modal _ftpChangeDir_form","Change local directory","",fcp_p,DIR_ARG);
      #else
      result=show("-modal _textbox_form","Change local directory",0,"","?Type the local directory you would like to change to","","","Directory");
      #endif
      if( result=="" ) {
         // User cancelled
         return;
      }
      cwd=strip(_param1);
      if( cwd=="" ) return;
   }
   if (_isUnix()) {
      if( substr(cwd,1,1)!=FILESEP ) {
         // Relative to local current working directory
         path := fcp_p->localCwd;
         _maybe_append_filesep(path);
         cwd=path:+cwd;
      }
   } else {
      if( substr(cwd,1,1)==FILESEP && substr(cwd,1,2)!='\\' ) {
         // Relative to current drive or unc root
         cwd=_ftpLocalAbsolute(fcp_p,cwd);
      } else {
         drive := substr(cwd,1,2);
         if( !isdrive(drive) && drive!='\\' ) {
            // Relative to local current working directory
            path := fcp_p->localCwd;
            _maybe_append_filesep(path);
            cwd=path:+cwd;
         }
      }
   }
   _str orig_cwd=cwd;
   cwd=isdirectory(_maybe_quote_filename(cwd));   // Resolve
   if( (cwd=="" || cwd=="0") && !isuncdirectory(orig_cwd) ) {
      msg := 'Unable to change to the local working directory "'orig_cwd'"';
      ftpDisplayError(msg);
      return;
   }
   // Append FILESEP
   cwd=isdirectory(_maybe_quote_filename(cwd),1);
   _str old_LocalCWD=fcp_p->localCwd;
   LOCALCWD=cwd;
   fcp_p->localCwd=cwd;
   mou_hour_glass(true);
   if( _UpdateLocalSession() ) {
      LOCALCWD=old_LocalCWD;
      fcp_p->localCwd=old_LocalCWD;
   }
}

_command void ftpclientMkLocalDir(_str path="") name_info(','VSARG2_NCW|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   FtpConnProfile *fcp_p;
   FtpConnProfile fake;   // Used when there is no connection
   int formWid;

   formWid=_ftpclientQFormWid();
   if( !formWid ) return;
   if( path=="" ) {
      // Prompt for the local directory to make
      typeless result=show("-modal _textbox_form","Make local directory",0,"","?Type the local directory you would like to make","","","Directory");
      if( result=="" ) {
         // User cancelled
         return;
      }
      path=_param1;
      if( path=="" ) return;
   }
   fcp_p=formWid.GetCurrentConnProfile();
   if( !fcp_p ) {
      // There is no connection, so fake it
      _ftpInitConnProfile(fake);
      fake.localCwd=LOCALCWD;
      fake.localFileFilter=LOCALFILTER;
      fcp_p=&fake;
   }
   // This test is ok under UNIX
   if( !isdrive(substr(path,1,2)) && substr(path,1,2)!='\\' ) {
      // We have a relative path, so make it absolute
      cwd := fcp_p->localCwd;
      _maybe_append_filesep(cwd);
      if (_isUnix()) {
         if( substr(path,1,1)!=FILESEP ) {
            path=cwd:+path;
         }
      } else {
         if( substr(path,1,1)==FILESEP ) {
            // Relative to the current drive
            if( substr(cwd,1,2)=='\\' ) {
               // UNC path
               _str server, share;
               parse cwd with '\\' server '\' share '\';
               path='\\':+server:+'\':+share:+path;
            } else {
               drive := substr(cwd,1,2);
               path=drive:+path;
            }
         } else {
            path=cwd:+path;
         }
      }
   }
   mou_hour_glass(true);
   typeless status=make_path(path);
   if( status ) {
      ftpDisplayError("Unable to make local working directory.  ":+_ftpGetMessage(status));
      return;
   }
   _UpdateLocalSession();
}

_command void ftpclientDelLocalFile() name_info(','VSARG2_NCW|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   FtpConnProfile *fcp_p;
   FtpConnProfile fake;   // When we have no remote connection

   sstabWid := profileWid := localWid := remoteWid := 0;
   formWid := _ftpclientQFormWid();
   if( !formWid ) return;
   if( _ftpclientFindAllControls(formWid,sstabWid,profileWid,localWid,remoteWid) ) return;
   fcp_p=formWid.GetCurrentConnProfile();
   if( !fcp_p ) {
      // We have no current connection, so fake one
      _ftpInitConnProfile(fake);
      fake.localCwd=LOCALCWD;
      fake.localFileFilter=LOCALFILTER;
      fcp_p=&fake;
   }
   nofselected := localWid._TreeGetNumSelectedItems();
   if( !nofselected ) return;

   // Check for directories selected
   dirs := false;
   idx := localWid._TreeGetNextSelectedIndex(1,auto treeSelectInfo);
   while( idx>=0 ) {
      caption := localWid._TreeGetCaption(idx);
      _str filename, size, modified, attribs;
      parse caption with filename "\t" size "\t" modified "\t" attribs;
      if ( filename != '..' ) {
         int flags = localWid._ftpTreeItemUserInfo2TypeFlags(idx);
         // Filename OR directory
         if ( testFlag(flags, FTPFILETYPE_DIR) ) {
            dirs = true;
            break;
         }
      }
      idx = localWid._TreeGetNextSelectedIndex(0, treeSelectInfo);
   }

   msg := "Delete ":+nofselected:+" files/directories";
   if( dirs ) {
      msg :+= " and their contents";
   }
   msg :+= "?";
   int status=_message_box(msg,"FTP",MB_YESNO|MB_ICONQUESTION);
   if( status!=IDYES ) return;

   mou_hour_glass(true);
   idx=localWid._TreeGetNextSelectedIndex(1,treeSelectInfo);
   while( idx>=0 ) {
      caption := localWid._TreeGetCaption(idx);
      filename := "";
      parse caption with filename "\t" .;
      if( filename==".." ) {
         idx=localWid._TreeGetNextSelectedIndex(0,treeSelectInfo);
         continue;
      } else {
         int flags = localWid._ftpTreeItemUserInfo2TypeFlags(idx);
         if ( !testFlag(flags, FTPFILETYPE_DIR) ) {
            // We have a file so delete it
            cwd := fcp_p->localCwd;
            _maybe_append_filesep(cwd);
            path := cwd:+filename;
            status=delete_file(path);
            if( status ) {
               msg='Error deleting file "':+filename:+'".  ':+_ftpGetMessage(status):+
                   "\n\nContinue?";
               int status2=_message_box(msg,"",MB_YESNO);
               if( status2!=IDYES ) {
                  break;
               }
            }
         } else if ( testFlag(flags, FTPFILETYPE_DIR) ) {
            // We have a directory so recursively delete it and its contents
            cwd := fcp_p->localCwd;
            _maybe_append_filesep(cwd);
            path := cwd:+filename;
            status=_ftpLocalRmdir(path);
            if( status ) {
               msg='Error removing directory "':+filename:+'"':+
                   "\n\nContinue?";
               int status2=_message_box(msg,"",MB_YESNO);
               if( status2!=IDYES ) {
                  break;
               }
            }
         }
      }
      idx = localWid._TreeGetNextSelectedIndex(0, treeSelectInfo);
   }
   formWid._UpdateLocalSession();
}

void _ctl_local_dir.'DEL'()
{
   ftpclientDelLocalFile();
}

_command void ftpclientRenameLocalFile() name_info(','VSARG2_NCW|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   FtpConnProfile *fcp_p;
   FtpConnProfile fake;

   sstabWid := profileWid := localWid := remoteWid := 0;
   formWid := _ftpclientQFormWid();
   if( !formWid ) return;
   if( _ftpclientFindAllControls(formWid,sstabWid,profileWid,localWid,remoteWid) ) return;
   fcp_p=formWid.GetCurrentConnProfile();
   if( !fcp_p ) {
      // There is currently no connection, so make a fake connection profile
      _ftpInitConnProfile(fake);
      fake.localCwd=LOCALCWD;
      fake.localFileFilter=LOCALFILTER;
      fcp_p=&fake;
   }

   nofselected := localWid._TreeGetNumSelectedItems();
   if( !nofselected || nofselected>1 ) return;
   idx := localWid._TreeCurIndex();
   if( idx<0 ) return;
   caption := localWid._TreeGetCaption(idx);
   rnfr := "";
   parse caption with rnfr "\t" .;
   if( rnfr==".." ) {
      return;
   } else {
      local_path := fcp_p->localCwd;
      _maybe_append_filesep(local_path);
      rnfr=local_path:+rnfr;
      typeless status=show("-modal _textbox_form","Rename ":+rnfr:+" to...",0,"","?Specify a filename to rename to","","","Rename to:":+rnfr);
      if( status=="" ) {
         // User cancelled
         return;
      }
      _str rnto=_param1;
      if( rnto=="" ) {
         return;
      }
      // If the user did not give an absolute path, then assume it is
      // relative to the local current working directory of the current
      // session.
      if (_isUnix()) {
         if( substr(rnto,1,1)!=FILESEP ) {
            rnto=local_path:+rnto;
         }
      } else {
         if( substr(rnto,1,1)==FILESEP ) {
            // Assume relative to current drive
            drive := _ctl_local_drvlist.p_text;
            if( drive=="" ) {
               // This should never happen
               ftpDisplayError("No relative drive!");
               return;
            }
            rnto=drive:+rnto;
         } else if( !isdrive(substr(rnto,1,2)) && substr(rnto,1,2)!='\\' ) {
            rnto=local_path:+rnto;
         }
      }
      rnto_dir := _strip_filename(rnto,'N');
      rnto_filename := _strip_filename(rnto,'P');
      orig_rnto_dir := rnto_dir;
      rnto_dir=isdirectory(rnto_dir);
      if( rnto_dir=="" || rnto_dir=="0" ) {
         ftpDisplayError("Directory:\n\n":+orig_rnto_dir:+"\n\nDoes not exist!");
         return;
      }
      _maybe_append_filesep(rnto_dir);
      rnto=rnto_dir:+rnto_filename;
      //_message_box("rnfr="rnfr"\n\nrnto="rnto);
      status=_file_move(rnto,rnfr);
      if( status ) {
         ftpDisplayError('Failed to rename "':+rnfr:+'".  ':+_ftpGetMessage(status));
         return;
      }
      _UpdateLocalSession();
      return;
   }
}

_command void ftpclientLocalSort(_str line="") name_info(','VSARG2_NCW|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   int formWid;
   int sortflags;
   FtpConnProfile *fcp_p;

   formWid=_ftpclientQFormWid();
   if( !formWid ) return;

   fcp_p=formWid.GetCurrentConnProfile();
   if( !fcp_p ) {
      // No connection
      sortflags=LOCALSORTFLAGS;
   } else {
      sortflags=fcp_p->localSortFlags;
   }
   int type= sortflags & ~(FTPSORTFLAG_ASCEND|FTPSORTFLAG_DESCEND);
   if( !type ) {
      // Sort by name by default
      sortflags |= FTPSORTFLAG_NAME;
   }
   if( (sortflags&(FTPSORTFLAG_ASCEND|FTPSORTFLAG_DESCEND))==0 ) {
      // Sort in ascending order by default
      sortflags |= FTPSORTFLAG_ASCEND;
   }

   while( line!="" ) {
      option := "";
      parse line with option line;
      option=strip(translate(option,'  ','+-',''));
      option=upcase(option);
      switch( option ) {
      case 'N':
         sortflags |= FTPSORTFLAG_NAME;
         break;
      case 'E':
         sortflags |= FTPSORTFLAG_EXT;
         break;
      case 'S':
         sortflags |= FTPSORTFLAG_SIZE;
         break;
      case 'D':
         sortflags |= FTPSORTFLAG_DATE;
         break;
      case 'OA':
         sortflags |= FTPSORTFLAG_ASCEND;
         break;
      case 'OD':
         sortflags |= FTPSORTFLAG_DESCEND;
         break;
      default:
         // Invalid option
      }
   }

   LOCALSORTFLAGS=sortflags;
   if( fcp_p ) {
      fcp_p->localSortFlags=sortflags;
   }

   formWid._UpdateLocalSession();
}

_command void ftpclientLocalHScrollbar() name_info(','VSARG2_NCW|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   sstabWid := profileWid := localWid := remoteWid := 0;
   formWid := _ftpclientQFormWid();
   if( !formWid ) return;
   if( _ftpclientFindAllControls(formWid,sstabWid,profileWid,localWid,remoteWid) ) return;
   int scroll_bars=localWid.p_scroll_bars;
   if( scroll_bars&SB_HORIZONTAL ) {
      // Turn horizontal scroll bar OFF, turn popup ON
      localWid.p_scroll_bars &= ~(SB_HORIZONTAL);
      localWid.p_delay=0;
   } else {
      // Turn horizontal scroll bar ON, turn popup OFF
      localWid.p_scroll_bars |= SB_HORIZONTAL;
      localWid.p_delay= -1;
   }
   // Remember horizontal scroll bar settings.
   // Must do this here because exiting the editor does not call a control's
   // ON_DESTROY event.
   _append_retrieve(0,_ctl_local_dir.p_scroll_bars,"_tbFTPClient_form._ctl_local_dir.p_scroll_bars");
}

_command void ftpclientRefreshLocalSession() name_info(','VSARG2_NCW|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   int formWid;

   formWid=_ftpclientQFormWid();
   if( !formWid ) return;
   formWid._UpdateLocalSession();
}

_command void ftpclientLocalFilter() name_info(','VSARG2_NCW|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   FtpConnProfile *fcp_p;
   int formWid;

   formWid=_ftpclientQFormWid();
   if( !formWid ) return;
   _str filter=LOCALFILTER;
   if( filter=="" ) filter=ALLFILES_RE;
   typeless status=show("-modal _textbox_form","Local file filter",TB_RETRIEVE,"","?Specify the file filter for file listings. Separate multiple filters with a space.\n\nExample: *.html *.shtml","","ftpFilter","Filter:":+filter);
   if( status=="" ) {
      // User cancelled
      return;
   }
   filter=_param1;
   if( filter=="" ) return;
   fcp_p=formWid.GetCurrentConnProfile();
   LOCALFILTER=filter;
   if( fcp_p ) {
      fcp_p->localFileFilter=filter;
   }
   formWid._UpdateLocalSession();
}

void __ftpclientDownload2CB( FtpQEvent *pEvent, _str isPopping="" );
void __ftpclientDownload3CB( FtpQEvent *pEvent );
void __ftpclientDownload1CB( FtpQEvent *pEvent, typeless doDownloadLinks="" )
{
   FtpQEvent event;
   FtpConnProfile fcp;
   FtpRecvCmd rcmd;
   FtpFile file;
   int formWid;

   event= *((FtpQEvent *)(pEvent));
   fcp=event.fcp;
   fcp.postedCb=null;

   msg := "";
   cwd := "";
   ext := "";
   filename := "";
   localcwd := "";
   remotecwd := "";
   member := "";
   file_and_member := "";
   local_path := "";
   path := "";
   typeless status=0;

   download_links := ( doDownloadLinks!="" && doDownloadLinks );

   if( _ftpQEventIsError(event) || _ftpQEventIsAbort(event) ) {
      formWid=_ftpclientQFormWid();
      // Update the local session back to original
      if( 0!=formWid ) {
         formWid._UpdateLocalSession();
      }
      if( !_ftpQEventIsError(event) ) {
         // User aborted
         return;
      }
      // Should only get here when a RETR failed
      if( event.event!=QE_RECV_CMD ) {
         return;
      }
      rcmd= (FtpRecvCmd)event.info[0];
      msg='Failed to download "':+rcmd.cmdargv[rcmd.cmdargv._length()-1]:+'"':+
          "\n\nContinue?";
      status=_message_box(msg,"FTP",MB_YESNO);
      if( status!=IDYES ) {
         // Update remote session back to original and stop
         if( fcp.remoteCwd!=fcp.dir_stack[0].remotecwd ) {
            cwd=fcp.dir_stack[0].remotecwd;
            if( fcp.system==FTPSYST_MVS ) {
               if( substr(cwd,1,1)!='/' ) {
                  // Make it absolute for MVS
                  cwd="'":+cwd:+"'";
               }
            }
            ftpclientChangeRemoteDir(cwd);
         } else {
            if( 0!=formWid ) {
               formWid._UpdateRemoteSession(false);
            }
         }
         return;
      }
      // Continue with next file/directory
   } else {
      // Just get done downloading?
      if( event.event==QE_RECV_CMD ) {
         // Refresh the local listing so the user sees what is going on.
         // Comment out the line below if downloading to a slow network
         // drive so local refreshes do not take forever.
         //_ftpclientUpDownLoadRefresh(&fcp,'L');
      }
   }

   FtpDirStack* ds_popped = null;
   filter := strip(fcp.remoteFileFilter);
   if( filter=="" ) {
      filter=FTP_ALLFILES_RE;
   }
   while( fcp.dir_stack._length()>0 ) {
      int idx=_ftpDirStackNext(fcp.dir_stack);
      while( idx>=0 ) {
         _ftpDirStackGetFile(fcp.dir_stack,file);
         if( file._isempty() ) {
            // This should never happen
            idx=_ftpDirStackNext(fcp.dir_stack);
            continue;
         }
         filename=file.filename;
         if( filename=="." || filename==".." ) {
            idx=_ftpDirStackNext(fcp.dir_stack);
            continue;
         } else {
            _ftpDirStackGetLocalCwd(fcp.dir_stack,localcwd);
            _ftpDirStackGetRemoteCwd(fcp.dir_stack,remotecwd);
            if( (fcp.system==FTPSYST_UNIX || (fcp.system==FTPSYST_MVS && substr(fcp.remoteCwd,1,1)=='/')) &&
                file.type&FTPFILETYPE_LINK ) {
               // Get rid of the link part
               parse filename with filename '->' .;
               filename=strip(filename);
            }
            if( !(file.type&(FTPFILETYPE_DIR|FTPFILETYPE_LINK)) ||
                ((fcp.downloadLinks || download_links) && file.type&FTPFILETYPE_LINK) ) {
               // File

               if( filter!=FTP_ALLFILES_RE ) {
                  // Match on the filter
                  match := false;
                  _str list=filter;
                  while( list!="" ) {
                     _str filespec=parse_file(list);
                     filespec=strip(filespec,'B','"');
                     if( filespec=="" ) {
                        continue;
                     }
                     if( _RemoteFilespecMatches(&fcp,filespec,filename) ) {
                        // Found a match
                        match=true;
                        break;
                     }
                  }
                  if( !match ) {
                     idx=_ftpDirStackNext(fcp.dir_stack);
                     continue;
                  }
               }

               fcp.postedCb=(typeless)__ftpclientDownload1CB;
               _str cmdargv[];
               cmdargv._makeempty();
               cmdargv[0]="RETR";
               cmdargv[1]=filename;
               rcmd.cmdargv=cmdargv;
               rcmd.datahost=rcmd.dataport="";
               dest := localcwd;
               _maybe_append_filesep(dest);
               switch( fcp.system ) {
               case FTPSYST_VMS:
               case FTPSYST_VMS_MULTINET:
                  // VMS filenames have version numbers at the end (e.g. ";1").
                  // We want to save the file without the version number.
                  parse filename with filename ';' .;
                  break;
               case FTPSYST_OS400:
                  if( substr(remotecwd,1,1)=='/' ) {
                     file_system := "";
                     parse remotecwd with '/' file_system '/' .;
                     file_system=upcase(file_system);
                     if( file_system=="QSYS.LIB" ) {
                        ext=upcase(_get_extension(filename));
                        if( ext=="FILE" ) {
                           // This is a QSYS.LIB file that has members.
                           // What they really want is the member whose
                           // name is the same as the file but with the
                           // extension changed to '.MBR'.
                           member=_strip_filename(filename,'E');
                           member :+= ".MBR";
                           file_and_member=filename:+'/':+member;
                           // We are now retrieving the member of the file
                           rcmd.cmdargv[1]=file_and_member;
                           // The local destination will be only the member name
                           filename=member;
                        }
                     }
                  } else {
                     // LFS
                     if( !pos('.',filename) ) {
                        // This is a LFS file that has members.
                        // What they really want is the member whose
                        // name is the same as the file.
                        member=filename;
                        file_and_member=filename:+'.':+member;
                        // We are now retrieving the member of the file
                        rcmd.cmdargv[1]=file_and_member;
                        #if 1
                        // If we don't keep it in the FILE.MEMBER form, then
                        // the user would have a difficult time uploading
                        // the member back into the correct file.
                        filename=file_and_member;
                        #else
                        // The local destination will be only the member name
                        filename=member;   // I know, it is the same as filename
                        #endif
                     }
                  }
                  break;
               }
               dest :+= filename;
               rcmd.dest=dest;
               rcmd.pasv= (fcp.useFirewall && fcp.global_options.fwenable && fcp.global_options.fwpasv);
               rcmd.progressCb=_ftpclientProgressCB;
               rcmd.size=0;
               rcmd.xfer_type=fcp.xferType;
               _ftpIdleEnQ(QE_RECV_CMD,QS_BEGIN,0,&fcp,rcmd);
               return;
            } else if( file.type&FTPFILETYPE_DIR ) {
               // Directory
               local_path=localcwd;
               _maybe_append_filesep(local_path);
               local_path :+= filename;
               path=isdirectory(_maybe_quote_filename(local_path));
               if( path=="" || path=="0" ) {

                  if( file_exists(local_path) ) {
                     // This is a plain file.
                     // What to do, what to do.
                     msg="Attempting to download link:\n":+
                         "\t"filename"\n":+
                         "to local plain file:\n":+
                         "\t"_maybe_quote_filename(local_path)"\n\n":+
                         "Replace?";
                     status=_message_box(msg,FTP_INFOBOX_TITLE,MB_YESNOCANCEL|MB_ICONQUESTION);
                     if( status==IDYES ) {
                        status=delete_file(local_path);
                        if( 0!=status ) {
                           msg="Failed to delete local file:\n\n":+
                               _maybe_quote_filename(local_path);
                           ftpDisplayError(msg);
                           return;
                        }

                     } else if( status==IDNO ) {
                        // Next file/directory
                        idx=_ftpDirStackNext(fcp.dir_stack);
                        continue;

                     } else {
                        // IDCANCEL

                        // Restore back to original working directories

                        // Restore local working directory
                        _ftpclientUpdateLocalSession();
                        // Restore remote working directory
                        if( fcp.remoteCwd!=fcp.dir_stack[0].remotecwd ) {
                           cwd=fcp.dir_stack[0].remotecwd;
                           if( fcp.system==FTPSYST_MVS ) {
                              if( substr(cwd,1,1)!='/' ) {
                                 // Make it absolute for MVS
                                 cwd="'":+cwd:+"'";
                              }
                           }
                           ftpclientChangeRemoteDir(cwd);
                        } else {
                           if( 0!=formWid ) {
                              formWid._UpdateRemoteSession(false);
                           }
                        }
                        return;
                     }

                  } else {
                     status=make_path(local_path);
                     if( status ) {
                        msg='Unable to create local directory "':+local_path:+'".  ':+
                            _ftpGetMessage(status);
                        ftpDisplayError(msg);
                        return;
                     }
                  }
               }
               if( fcp.recurseDirs ) {
                  // Set this now so it is easy to pick up in
                  // __ftpclientDownload2CB() when we push.
                  fcp.localCwd=local_path;
                  // __ftpclientDownload2CB() processes the CWD/PWD and listing
                  fcp.postedCb=(typeless)__ftpclientDownload2CB;
                  _ftpIdleEnQ(QE_CWD,QS_BEGIN,0,&fcp,filename);
                  return;
               }
            }
         }
         idx=_ftpDirStackNext(fcp.dir_stack);
      }
      // Pop this directory listing off the stack
      ds_popped=_ftpDirStackPop(fcp.dir_stack);
      if( fcp.dir_stack._length()>0 ) {
         // Change the local directory back to previous
         fcp.localCwd=fcp.dir_stack[fcp.dir_stack._length()-1].localcwd;
         // fcp.RemoteCWD will be correct after the CWD/PWD
         // Change the listing back to previous
         fcp.remoteDir=fcp.dir_stack[fcp.dir_stack._length()-1].dir;
         // CWD back to original directory
         cwd=fcp.dir_stack[fcp.dir_stack._length()-1].remotecwd;
         if( fcp.system==FTPSYST_MVS ) {
            if( substr(cwd,1,1)!='/' ) {
               // Make it absolute for MVS
               cwd="'":+cwd:+"'";
            }
         }
         // __ftpclientDownload3CB() processes the CWD/PWD
         fcp.postedCb=(typeless)__ftpclientDownload3CB;
         _ftpIdleEnQ(QE_CWD,QS_BEGIN,0,&fcp,cwd);
         return;
      }
   }

   // If we got here, then we are done with the download, so refresh everything
   formWid=_ftpclientQFormWid();
   if( formWid ) {
      formWid._UpdateLocalSession();
      formWid._UpdateRemoteSession(false);
      if( ds_popped ) {
         // Restore last known position in tree
         typeless p = ds_popped->tree_pos;
         if( p!="" ) {
            remoteWid := formWid._find_control('_ctl_remote_dir');
            if( remoteWid>0 ) {
               remoteWid._ftpRemoteRestorePos(p);
            }
         }
      }
   }
}

/**
 * Callback used when changing directory and retrieving a listing.
 */
void __ftpclientDownload2CB( FtpQEvent *pEvent, _str isPopping="" )
{
   FtpQEvent event;
   FtpRecvCmd rcmd;
   FtpConnProfile fcp;
   FtpConnProfile *fcp_p;
   typeless status=0;
   typeless status2=0;
   cmd := "";
   msg := "";
   cwd := "";

   event= *((FtpQEvent *)(pEvent));
   fcp=event.fcp;

   // Indicates that we are in the middle of popping back to the previous
   // directory. No need to do a listing.
   popping := (isPopping != "");

   if( _ftpQEventIsError(event) || _ftpQEventIsAbort(event) ) {
      if( !_ftpQEventIsError(event) ) {
         // User aborted
         return;
      }
      do_cleanup := true;
      if( !popping ) {
         if( event.event==QE_RECV_CMD ) {
            rcmd= (FtpRecvCmd)event.info[0];
            parse rcmd.cmdargv[0] with cmd .;
            if( upcase(cmd)!="LIST" ) {
               return;
            }
            if( fcp.resolveLinks ) {
               // Ask the user if they would like to retry the listing without resolving links
               msg='The error you received may have been caused by the "Resolve links" ':+
                   'option you have turned ON for this connection profile.':+"\n\n":+
                   'The "Resolve links" option can be turned OFF permanently from the ':+
                   'Advanced tab of the "Create FTP Profile" dialog ("File"..."FTP"...':+
                   '"Profile Manager", pick a profile and click "Edit").':+"\n\n":+
                   'Turn OFF "Resolve links" for this session?';
               status=_message_box(msg,FTP_ERRORBOX_TITLE,MB_YESNO|MB_ICONQUESTION);
               if( status==IDYES ) {
                  // User wants to retry the LIST w/out resolving links, so
                  // turn off ResolveLinks and fake us into thinking we just
                  // did a PWD in order to force a re-listing.
                  event.event=QE_PWD;
                  event.state=0;
                  fcp.resolveLinks=false;
                  // Find the matching connection profile in current connections
                  // so we can change its ResolveLinks field.
                  fcp_p=null;
                  typeless i;
                  for( i._makeempty();; ) {
                     _ftpCurrentConnections._nextel(i);
                     if( i._isempty() ) {
                        break;
                     }
                     FtpConnProfile currentconn=_ftpCurrentConnections:[i];
                     if( _ftpCurrentConnections:[i].profileName==fcp.profileName &&
                         _ftpCurrentConnections:[i].instance==fcp.instance ) {
                        // Found it
                        fcp_p= &(_ftpCurrentConnections:[i]);
                        break;
                     }
                  }
                  if( fcp_p ) {
                     fcp_p->resolveLinks=fcp.resolveLinks;
                  }
                  do_cleanup=false;
               }
            } else {
               if( fcp.system==FTPSYST_MVS && !fcp.ignoreListErrors && substr(fcp.remoteCwd,1,1)!='/' ) {
                  msg="Some MVS hosts return an error when listing the ":+
                      "contents of an empty PDS\n\nIgnore this error?";
                  status=_message_box(msg,"FTP",MB_YESNO);
                  if( status==IDYES ) {
                     // Ignore LIST errors from now until the end of this operation
                     fcp.ignoreListErrors=true;
                     do_cleanup=false;
                  }
               } else {
                  msg="Error listing the contents of\n\n":+fcp.remoteCwd:+
                      "\n\nContinue?";
                  status=_message_box(msg,"FTP",MB_YESNO);
                  if( status==IDYES ) {
                     // User elected to continue
                     do_cleanup=false;
                  }
               }
               if( !do_cleanup ) {
                  // Set the directory listing back to what it was
                  fcp.remoteDir=fcp.dir_stack[fcp.dir_stack._length()-1].dir;
                  // CWD back to original directory
                  cwd=fcp.dir_stack[fcp.dir_stack._length()-1].remotecwd;
                  if( fcp.system==FTPSYST_MVS ) {
                     if( substr(cwd,1,1)!='/' ) {
                        // Make it absolute for MVS
                        cwd="'":+cwd:+"'";
                     }
                  }
                  // __ftpclientDownload3CB() processes the CWD/PWD
                  fcp.postedCb=(typeless)__ftpclientDownload3CB;
                  _ftpIdleEnQ(QE_CWD,QS_BEGIN,0,&fcp,cwd);
                  return;
               }
            }
         } else if( event.event==QE_CWD ) {
            // Failed to change directory.
            // If this is a symbolic link, then attempt to download
            // as a file instead.
            status = IDNO;
            // Flag to override fcp.DownloadLinks
            download_links := false;
            FtpFile file;
            _ftpDirStackGetFile(fcp.dir_stack,file);
            if( !file._isempty() && 0!=(file.type & FTPFILETYPE_LINK) ) {
               // We created a local directory in the process of attempting
               // to download this link as a directory, so attempt to
               // (non-recursively) remove it.
               _str local_path = fcp.localCwd;
               if( local_path!="" && isdirectory(local_path) ) {
                  status=rmdir(local_path);
                  if( status ) {
                     msg = "Warning: Failed to clean up directory after failed CWD:\n\n" :+
                           local_path;
                     _message_box(msg,FTP_ERRORBOX_TITLE,MB_YESNO|MB_ICONEXCLAMATION);
                  }
               }
               // Back up and try downloading link as a file
               _ftpDirStackPrev(fcp.dir_stack);
               status=IDYES;
               download_links=true;
            } else {
               // Ask the user if they want to continue after the failure
               // on this one file/directory.
               cwd=event.info[0];
               msg="Failed to change directory to ":+cwd:+
                   "\n\nContinue?";
               status=_message_box(msg,"FTP",MB_YESNO);
            }
            if( status==IDYES ) {
               // fcp.LocalCWD was set in __ftpclientDownload1CB(), so
               // set it back.
               fcp.localCwd=fcp.dir_stack[fcp.dir_stack._length()-1].localcwd;
               event._makeempty();
               event.fcp=fcp;
               event.event=QE_NONE;
               event.state=QS_NONE;
               event.start=0;
               // __ftpclientDownload1CB() processes the next file directory
               __ftpclientDownload1CB(&event,download_links);
               return;
            }
         }
      }
      if( do_cleanup ) {
         // If we got here then we need to clean up
         formWid := _ftpclientQFormWid();
         // Update the local session back to original
         if( formWid ) formWid._UpdateLocalSession();
         // Update remote session back to original and stop
         if( fcp.remoteCwd!=fcp.dir_stack[0].remotecwd ) {
            cwd=fcp.dir_stack[0].remotecwd;
            if( fcp.system==FTPSYST_MVS ) {
               if( substr(cwd,1,1)!='/' ) {
                  // Make it absolute for MVS
                  cwd="'":+cwd:+"'";
               }
            }
            ftpclientChangeRemoteDir(cwd);
         } else {
            if( 0!=formWid ) {
               formWid._UpdateRemoteSession(false);
            }
         }
         return;
      }
      // Fall through - this usually happens if user elected to retry
      // the listing with fcp.ResolveLinks=false or ignore LIST errors.
   }

   if( !popping && event.event==QE_PWD ) {
      // We just printed the current working directory.
      // Now we must list its contents.

      /*
      typedef struct RecvCmd_s {
         bool pasv;
         _str cmdargv[];
         _str dest;
         _str datahost;
         _str dataport;
         int  size;
         pfnProgressCallback_tp ProgressCB;
      } RecvCmd_t;
      */
      fcp.postedCb=(typeless)__ftpclientDownload2CB;
      typeless pasv= (fcp.useFirewall && fcp.global_options.fwenable && fcp.global_options.fwpasv );
      typeless cmdargv;
      cmdargv._makeempty();
      cmdargv[0]="LIST";
      if( fcp.resolveLinks ) {
         cmdargv[cmdargv._length()]="-L";
      }
      _str dest=mktemp();
      if( dest=="" ) {
         msg="Unable to create temp file for remote directory listing";
         ftpDisplayError(msg);
         return;
      }
      datahost := "";
      dataport := "";
      size := 0;
      xfer_type := FTPXFER_ASCII;   // Always transfer listings ASCII
      rcmd.pasv=pasv;
      rcmd.cmdargv=cmdargv;
      rcmd.dest=dest;
      rcmd.datahost=datahost;
      rcmd.dataport=dataport;
      rcmd.size=size;
      rcmd.xfer_type=xfer_type;
      rcmd.progressCb=_ftpclientProgressCB;
      _ftpIdleEnQ(QE_RECV_CMD,QS_BEGIN,0,&fcp,rcmd);
      return;
   }

   if( !popping ) {
      rcmd= (FtpRecvCmd)event.info[0];
      if( _ftpdebug&FTPDEBUG_SAVE_LIST ) {
         // Make a copy of the raw listing
         temp_path := _temp_path();
         _maybe_append_filesep(temp_path);
         list_filename := temp_path:+"$list";
         copy_file(rcmd.dest,list_filename);
      }
      status=_ftpParseDir(&fcp,fcp.remoteDir,fcp.remoteFileFilter,rcmd.dest);
      status2=delete_file(rcmd.dest);
      if( status2 && status2!=FILE_NOT_FOUND_RC && status2!=PATH_NOT_FOUND_RC ) {
         msg='Warning: Could not delete temp file "':+rcmd.dest:+'".  ':+_ftpGetMessage(status2);
         ftpDisplayError(msg);
      }
      if( status ) {
         // Set the directory listing back to what it was
         fcp.remoteDir=fcp.dir_stack[fcp.dir_stack._length()-1].dir;
         // CWD back to original directory
         cwd=fcp.dir_stack[fcp.dir_stack._length()-1].remotecwd;
         if( fcp.system==FTPSYST_MVS ) {
            if( substr(cwd,1,1)!='/' ) {
               // Make it absolute for MVS
               cwd="'":+cwd:+"'";
            }
         }
         // __ftpclientDownload3CB() processes the CWD/PWD
         fcp.postedCb=(typeless)__ftpclientDownload3CB;
         _ftpIdleEnQ(QE_CWD,QS_BEGIN,0,&fcp,cwd);
         return;
      } else {
         #if 1
         // Refresh the remote listing so the user sees what is going on
         _ftpclientUpDownLoadRefresh(&fcp);
         #endif

         // Note that fcp.LocalCWD was set in __ftpclientDownload1CB() in
         // anticipation of the push.
         _ftpDirStackPush(fcp.localCwd,fcp.remoteCwd,&fcp.remoteDir,fcp.dir_stack);
         fcp.postedCb=null;
         event._makeempty();
         event.fcp=fcp;
         event.event=QE_NONE;
         event.state=QS_NONE;
         event.start=0;
         // __ftpclientDownload1CB() processes the next file directory
         __ftpclientDownload1CB(&event);
         return;
      }
   }

   // If we got here then we must have just finished popping back to a
   // previous directory, so process the next file directory.
   fcp.postedCb=null;
   if( fcp.dir_stack._length()>0 ) {
      // Change the local directory back to previous
      fcp.localCwd=fcp.dir_stack[fcp.dir_stack._length()-1].localcwd;
      // fcp.RemoteCWD should already be correct
      // Change the listing back to previous
      fcp.remoteDir=fcp.dir_stack[fcp.dir_stack._length()-1].dir;

      #if 1
      // Refresh the remote listing so the user sees what is going on
      _ftpclientUpDownLoadRefresh(&fcp);
      #endif
   }
   event._makeempty();
   event.fcp=fcp;
   event.event=QE_NONE;
   event.state=QS_NONE;
   event.start=0;
   // __ftpclientDownload1CB() processes the next file directory
   __ftpclientDownload1CB(&event);
}

/**
 * Callback used when popping a directory.
 */
void __ftpclientDownload3CB( FtpQEvent *pEvent )
{
   // The second argument tells __ftpclientDownload2CB() that we are
   // popping the top directory off the stack. No need to do a listing.
   __ftpclientDownload2CB(pEvent,1);
}

_command void ftpclientDownload(typeless downloadLinks = "") name_info(','VSARG2_NCW|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   FtpConnProfile *fcp_p;
   FtpConnProfile fcp;
   FtpQEvent event;
   bool download_links;   // Download folder links as files?
   FtpDirectory dir;
   FtpFile file;

   sstabWid := profileWid := localWid := remoteWid := 0;
   formWid := _ftpclientQFormWid();
   if( 0==formWid ) {
      return;
   }
   if( _ftpclientFindAllControls(formWid,sstabWid,profileWid,localWid,remoteWid) ) {
      return;
   }
   fcp_p=formWid.GetCurrentConnProfile();
   if( !fcp_p ) {
      return;
   }
   fcp= *fcp_p;   // Make a copy
   fcp.downloadLinks= ( downloadLinks!="" && downloadLinks );

   // Check for directories selected
   dirs := false;
   idx := remoteWid._TreeGetNextSelectedIndex(1,auto treeSelectInfo);
   while( idx>=0 ) {
      caption := remoteWid._TreeGetCaption(idx);
      _str filename, size, modified, attribs;
      parse caption with filename "\t" size "\t" modified "\t" attribs;
      if( filename!=".." ) {
         int flags = remoteWid._ftpTreeItemUserInfo2TypeFlags(idx);
         // Filename OR directory
         if ( testFlag(flags, FTPFILETYPE_DIR) ) {
            dirs = true;
            break;
         }
      }
      idx = remoteWid._TreeGetNextSelectedIndex(0, treeSelectInfo);
   }

   #if 1
   // Decided not to prompt user on download
   fcp.recurseDirs=true;
   #else
   fcp.RecurseDirs=false;
   if( dirs ) {
      msg="Recursively download directories?";
      status=_message_box(msg,"FTP",MB_YESNO);
      if( status==IDYES ) {
         fcp.RecurseDirs=true;
      }
   }
   #endif

   // Populate a remote directory list with only the selected items
   dir._makeempty();
   dir.flags=0;
   ff := 1;
   treeSelectInfo = 0;

   for(;;) {
      index := remoteWid._TreeGetNextSelectedIndex(ff, treeSelectInfo);
      ff=0;
      if( index<0 ) break;
      caption := remoteWid._TreeGetCaption(index);
      filename := "";
      parse caption with filename "\t" .;
      file._makeempty();
      file.filename=filename;

      // Fill unimportant fields
      file.attribs="";
      file.day=0;
      file.group="";
      file.month="";
      file.owner="";
      file.refs=0;
      file.size=0;
      file.time="";
      file.mtime = '';
      file.year=0;

      int flags = remoteWid._ftpTreeItemUserInfo2TypeFlags(index);
      file.type = flags & (FTPFILETYPE_DIR | FTPFILETYPE_LINK);
      dir.files[dir.files._length()] = file;
   }

   _ftpclientMaybeReconnect(&fcp);

   _ftpDirStackClear(fcp.dir_stack);
   _ftpDirStackPush(fcp.localCwd,fcp.remoteCwd,&dir,fcp.dir_stack);
   // Save the last position in tree so can restore it when done
   typeless p;
   remoteWid._ftpRemoteSavePos(p);
   _ftpDirStackSetRemoteTreePos(fcp.dir_stack,p);
   event._makeempty();
   event.event=QE_NONE;
   event.state=QS_NONE;
   event.fcp=fcp;
   event.start=0;
   if( fcp.serverType==FTPSERVERTYPE_SFTP ) {
      __sftpclientDownload1CB(&event);
   } else {
      // FTP
      __ftpclientDownload1CB(&event);
   }
}

_command void ftpclientDownloadLinks() name_info(','VSARG2_NCW|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   ftpclientDownload(1);
}

void __ftpclientManualDownloadCB( FtpQEvent *pEvent )
{
   FtpQEvent event;
   FtpConnProfile fcp;

   event= *((FtpQEvent *)(pEvent));

   fcp=event.fcp;
   if( !_ftpQEventIsError(event) && !_ftpQEventIsAbort(event) ) {
      formWid := _ftpclientQFormWid();
      if( !formWid ) return;
      formWid._UpdateLocalSession();
      return;
   }
}

_command void ftpclientManualDownload() name_info(','VSARG2_NCW|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   FtpConnProfile *fcp_p;
   FtpConnProfile fcp;
   FtpRecvCmd rcmd;
   _str cmdargv[];

   formWid := _ftpclientQFormWid();
   if( 0==formWid ) {
      return;
   }
   fcp_p=formWid.GetCurrentConnProfile();
   if( !fcp_p ) {
      return;
   }
   fcp= *fcp_p;   // Make a copy

   // Remember the last filename
   _str remote_path=_retrieve_value("_tbFTPClient_form.ManualDownload.LastFilename");

   // Prompt for the remote path
   typeless result=show("-modal _ftpManualDownload_form",remote_path,0,fcp_p->xferType,"Manual Download",fcp_p);
   if( result=="" ) {
      // User cancelled
      return;
   }
   remote_path=strip(_param1);
   if( remote_path=="" ) return;

   // Remember the last filename
   _append_retrieve(0,remote_path,"_tbFTPClient_form.ManualDownload.LastFilename");

   localpath := strip(_param2);

   xfer_type := (FtpXferType)_param3;

   // OS/400 LFS member?
   os400_lfs := (fcp_p->system==FTPSYST_OS400 && _param4!=0);

   if( os400_lfs ) {
      // This is an OS/400 LFS member, so already absolute.
      // Nothing to do.
   } else {
      remote_path=_ftpAbsolute(&fcp,remote_path);
   }

   i := 0;
   filename := "";
   ext := "";
   member := "";
   file_and_member := "";
   switch( fcp.system ) {
   case FTPSYST_VMS:
   case FTPSYST_VMS_MULTINET:
      i=lastpos(']',remote_path);
      if( i ) {
         filename=substr(remote_path,i+1);
         parse filename with filename ';' .;
      }
      break;
   case FTPSYST_VOS:
      i=lastpos('>',remote_path);
      if( i ) {
         filename=substr(remote_path,i+1);
      }
      break;
   case FTPSYST_VM:
   case FTPSYST_VMESA:
      i=lastpos('/',remote_path);
      if( i ) {
         filename=substr(remote_path,i+1);
      }
      break;
   case FTPSYST_MVS:
      remote_path=_ftpConvertSEtoMVSFilename(remote_path);
      if( substr(remote_path,1,1)=='/' ) {
         // HFS file system which mimics Unix
         i=lastpos('/',remote_path);
         filename=substr(remote_path,i+1);
      } else {
         // PDS or SDS format
         if( _last_char(remote_path)==')' ) {
            // PDS member
            parse remote_path with . '(' filename ')';
         } else {
            // SDS
            i=pos('.',remote_path);
            if( i ) {
               filename=substr(remote_path,i+1);
            } else {
               filename=remote_path;
            }
         }
      }
      break;
   case FTPSYST_OS2:
      // OS/2 is flexible about file separators. Both '/' and '\' are allowed
      remote_path=translate(remote_path,'/','\');
      i=lastpos('/',remote_path);
      if( i ) {
         filename=substr(remote_path,i+1);
      }
      break;
   case FTPSYST_OS400:
      remote_path=_ftpConvertSEtoOS400Filename(remote_path);
      if( substr(remote_path,1,1)=='/' ) {
         // IFS file system which mimics Unix
         i=lastpos('/',remote_path);
         filename=substr(remote_path,i+1);
         file_system := "";
         parse remote_path with '/' file_system '/' .;
         file_system=upcase(file_system);
         if( file_system=="QSYS.LIB" ) {
            ext=upcase(_get_extension(filename));
            if( ext=="FILE" ) {
               // This is a QSYS.LIB file that has members.
               // What they really want is the member whose
               // name is the same as the file but with the
               // extension changed to '.MBR'.
               member=_ftpStripFilename(&fcp,remote_path,'PE');
               member :+= ".MBR";
               file_and_member=remote_path:+'/':+member;
               // We are now retrieving the member of the file
               remote_path=file_and_member;
               // The local destination will be only the member name
               filename=member;
            }
         }
      } else {
         // LFS format
         libname := "";
         parse remote_path with libname '/' filename;
         if( !pos('.',filename) ) {
            // This is a Library File System (LFS) file
            // that has members. What they really want
            // is the member whose name is the same as
            // the file.
            member=filename;
            file_and_member=filename:+'.':+member;
            // We are now retrieving the member of the file
            remote_path=libname:+'/':+file_and_member;
            // The local destination will be only the member name
            filename=file_and_member;
         }
      }
      break;
   case FTPSYST_WINNT:
   case FTPSYST_HUMMINGBIRD:
      if( substr(fcp.remoteCwd,1,1)=='/' ) {
         // Unix style
         i=lastpos('/',remote_path);
         if( i ) {
            filename=substr(remote_path,i+1);
         }
      } else {
         // DOS style
         i=lastpos("\\",remote_path);
         if( i ) {
            filename=substr(remote_path,i+1);
         }
      }
      break;
   case FTPSYST_NETWARE:
   case FTPSYST_MACOS:
   case FTPSYST_VXWORKS:
   case FTPSYST_UNIX:
   default:
      i=lastpos('/',remote_path);
      if( i ) {
         filename=substr(remote_path,i+1);
      }
   }
   if( filename=="" ) {
      msg := "Invalid remote filename";
      ftpDisplayError(msg);
      return;
   }
   if( localpath=="" ) {
      // Download to current local working directory with same filename
      localpath=fcp.localCwd;
      _maybe_append_filesep(localpath);
      localpath :+= filename;
   } else {
      // User specified a destination
      localpath=_ftpLocalAbsolute(&fcp,localpath);
      if( isdirectory(localpath) ) {
         // Same filename, different directory
         _maybe_append_filesep(localpath);
         localpath :+= filename;
      }
   }

   _ftpclientMaybeReconnect(&fcp);

   if( fcp.serverType==FTPSERVERTYPE_SFTP ) {
      fcp.postedCb=(typeless)__ftpclientManualDownloadCB;
      cmdargv._makeempty();
      cmdargv[0]=remote_path;
      rcmd.cmdargv=cmdargv;
      rcmd.xfer_type=FTPXFER_BINARY;   // Ignored
      rcmd.datahost=rcmd.dataport="";  // Ignored
      rcmd.dest=localpath;
      rcmd.pasv=false;   // Ignored
      rcmd.progressCb=_ftpopenProgressDlgCB;
      rcmd.size=0;
      // Members used specifically by SFTP
      rcmd.hfile= -1;
      rcmd.hhandle= -1;
      rcmd.offset=0;
      _ftpIdleEnQ(QE_SFTP_GET,QS_BEGIN,0,&fcp,rcmd);
   } else {
      // FTP
      fcp.postedCb=(typeless)__ftpclientManualDownloadCB;
      cmdargv._makeempty();
      cmdargv[0]="RETR";
      cmdargv[1]=remote_path;
      rcmd.cmdargv=cmdargv;
      rcmd.xfer_type=xfer_type;
      rcmd.datahost=rcmd.dataport="";
      rcmd.dest=localpath;
      rcmd.pasv= (fcp.useFirewall && fcp.global_options.fwenable && fcp.global_options.fwpasv);
      rcmd.progressCb=_ftpclientProgressCB;
      rcmd.size=0;
      int hosttype=fcp.system;
      if( hosttype==FTPSYST_OS400 ) {
         _str pre_cmdargv[],post_cmdargv[];
         _str pre_cmds[];
         _str post_cmds[];
         pre_cmds._makeempty();
         post_cmds._makeempty();
         remote_path=rcmd.cmdargv[1];
         if( substr(remote_path,1,1)=='/' ) {
            // Remote path is IFS which mimics Unix
            pre_cmds[0]="SITE NAMEFMT 1";
            if( substr(fcp.remoteCwd,1,1)!='/' ) {
               // We have to put it back into LFS file system
               post_cmds[0]="SITE NAMEFMT 0";
            }
         } else {
            // Remote path is LFS
            bool change_dir= (substr(fcp.remoteCwd,1,1)=='/' &&
                         !_ftpFileEq(&fcp,substr(fcp.remoteCwd,1,length("/QSYS.LIB")),"/QSYS.LIB"));
            if( change_dir ) {
               // Can only issue a "NAMEFMT 0" from /QSYS.LIB/
               pre_cmds[0]="CWD /QSYS.LIB";
            }
            pre_cmds[pre_cmds._length()]="SITE NAMEFMT 0";
            if( substr(fcp.remoteCwd,1,1)=='/' ) {
               // We have to put it back into IFS file system
               post_cmds[0]="SITE NAMEFMT 1";
               if( change_dir ) {
                  post_cmds[1]="CWD ":+fcp.remoteCwd;
               }
            }
         }
         rcmd.pre_cmds=pre_cmds;
         rcmd.post_cmds=post_cmds;
         _ftpIdleEnQ(QE_RECV_CMD,QS_CMD_BEFORE_BEGIN,0,&fcp,rcmd);
      } else if( hosttype==FTPSYST_VM || hosttype==FTPSYST_VMESA ) {
         _ftpIdleEnQ(QE_RECV_CMD,QS_CWD_BEFORE_BEGIN,0,&fcp,rcmd);
      } else {
         _ftpIdleEnQ(QE_RECV_CMD,QS_BEGIN,0,&fcp,rcmd);
      }
   }
}

#if 0
void __ftpclientChangeRemoteDirCB( ftpQEvent_t *pEvent )
{
   ftpQEvent_t event;
   ftpConnProfile_t fcp;
   int formWid;

   event= *((ftpQEvent_t *)(pEvent));

   fcp=event.fcp;   // Make a copy

   if( !_ftpQEventIsError(event) && !_ftpQEventIsAbort(event) ) {
      formWid=_ftpclientQFormWid();
      if( !formWid ) return;
      formWid._UpdateRemoteSession(true);
      return;
   }
}
#endif

_command void ftpclientChangeRemoteDir(_str cwd="", 
                                       typeless isOS400LFS="", 
                                       typeless isLink="") name_info(','VSARG2_NCW|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   FtpConnProfile *fcp_p;
   FtpConnProfile fcp;
   int formWid;

   formWid=_ftpclientQFormWid();
   if( 0==formWid ) {
      return;
   }
   fcp_p=formWid.GetCurrentConnProfile();
   if( !fcp_p ) {
      return;
   }

   os400_lfs := ( isOS400LFS!="" && isOS400LFS );

   typeless result=0;
   if( cwd=="" ) {
      // Prompt for the remote directory
      result=show("-modal _ftpChangeDir_form","Change remote directory","",fcp_p);
      if( result=="" ) {
         // User cancelled
         return;
      }
      cwd=_param1;
      os400_lfs= (fcp_p->system==FTPSYST_OS400 && _param2!=0);
      if( cwd=="" ) return;
   }
   is_link := ( isLink!="" && isLink );

   // Make a copy
   fcp = *fcp_p;

   _ftpclientMaybeReconnect(&fcp);

   if( fcp.serverType==FTPSERVERTYPE_SFTP ) {
      if( is_link ) {
         fcp.postedCb=(typeless)__sftpclientCwdLinkCB;
      } else {
         fcp.postedCb=(typeless)__sftpclientCwdCB;
      }
      _ftpSyncEnQ(QE_SFTP_STAT,QS_BEGIN,0,&fcp,cwd);
   } else {
      // FTP
      if( is_link ) {
         fcp.postedCb=(typeless)__ftpclientCwdLinkCB;
      } else if( cwd == ".." ) {
         fcp.postedCb=(typeless)__ftpclientCdupCB;
      } else {
         fcp.postedCb=(typeless)__ftpclientCwdCB;
      }
      if( fcp.system==FTPSYST_OS400 ) {
         _str pre_cmds[];
         pre_cmds._makeempty();
         if( substr(fcp.remoteCwd,1,1)!='/' &&  substr(cwd,1,1)=='/' ) {
            // Changing from LFS to IFS
            pre_cmds[0]="SITE NAMEFMT 1";
         } else {
            if( substr(fcp.remoteCwd,1,1)=='/' && substr(cwd,1,1)!='/' && os400_lfs ) {
               // Changing from IFS to LFS
               change_dir := (!_ftpFileEq(&fcp,substr(fcp.remoteCwd,1,length("/QSYS.LIB")),"/QSYS.LIB"));
               if( change_dir ) {
                  // Can only issue a "NAMEFMT 0" from /QSYS.LIB/
                  pre_cmds[0]="CWD /QSYS.LIB";
               }
               pre_cmds[pre_cmds._length()]="SITE NAMEFMT 0";
            }
         }
         if( pre_cmds._length() ) {
            _ftpSyncEnQ(QE_CWD,QS_CMD_BEFORE_BEGIN,0,&fcp,cwd,pre_cmds);
         } else {
            _ftpSyncEnQ(QE_CWD,QS_BEGIN,0,&fcp,cwd);
         }
      } else if( cwd == ".." ) {
         _ftpSyncEnQ(QE_CDUP,QS_BEGIN,0,&fcp);
      } else {
         _ftpSyncEnQ(QE_CWD,QS_BEGIN,0,&fcp,cwd);
      }
   }
}

_command void ftpclientChangeRemoteDirLink(_str filename="") name_info(','VSARG2_NCW|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   // Get rid of the link part
   parse filename with filename '->' .;
   filename=strip(filename);
   ftpclientChangeRemoteDir(filename,false,true);
}

void __ftpclientMkRemoteDirCB( FtpQEvent *pEvent )
{
   FtpQEvent event;
   FtpConnProfile fcp;
   FtpConnProfile *fcp_p;
   int formWid;

   event= *((FtpQEvent *)(pEvent));

   fcp=event.fcp;
   if( _ftpQEventIsError(event) || _ftpQEventIsAbort(event) ) {
      // Nothing to do
      return;
   }

   fcp_p=_ftpIsCurrentConnProfile(fcp.profileName,fcp.instance);
   if( !fcp_p ) return;   // This should never happen

   curr_dir := "";
   root_dir := "";
   new_dir := "";
   if( !event.info._isempty() ) {
      new_dir=event.info[0];
   }
   if( new_dir!="" ) {
      curr_dir=_ftpAbsolute(fcp_p,"junk");
      curr_dir=_ftpStripFilename(fcp_p,curr_dir,'NS');
      root_dir=_ftpAbsolute(fcp_p,new_dir);
      root_dir=_ftpStripFilename(fcp_p,root_dir,'NS');
      if( !_ftpFileEq(fcp_p,curr_dir,root_dir) ) {
         // The newly created directory is outside of the current remote
         // working directory, so no need to refresh the listing.
         return;
      }
   }

   // _UpdateRemoteSession() will take care of asynchronous refresh
   formWid=_ftpclientQFormWid();
   if( !formWid ) return;
   if( fcp.autoRefresh ) {
      formWid._UpdateRemoteSession(true);
   } else {
      // Auto refresh is OFF, so fake the directory entry
      if( new_dir!="" ) {
         FtpFile file;
         file._makeempty();
         _ftpFakeFile(&file,new_dir,FTPFILETYPE_DIR|FTPFILETYPE_CREATED,0);
         _ftpInsertFile(fcp_p,file);
         formWid._UpdateRemoteSession(false);
      }
   }
}

_command void ftpclientMkRemoteDir(_str path="") name_info(','VSARG2_NCW|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   FtpConnProfile *fcp_p;
   FtpConnProfile fcp;
   int formWid;

   formWid=_ftpclientQFormWid();
   if( !formWid ) return;
   fcp_p=formWid.GetCurrentConnProfile();
   if( !fcp_p ) return;
   typeless result=0;
   if( path=="" ) {
      // Prompt for the remote directory to make
      result=show("-modal _textbox_form","Make remote directory",0,"","?Type the remote directory you would like to make","","","Directory");
      if( result=="" ) {
         // User cancelled
         return;
      }
      path=_param1;
      if( path=="" ) return;
   }
   fcp= *fcp_p;   // Make a copy

   _ftpclientMaybeReconnect(&fcp);

   // Note that we can use the same callback for both FTP _and_ SFTP
   fcp.postedCb=(typeless)__ftpclientMkRemoteDirCB;
   if( fcp.serverType==FTPSERVERTYPE_SFTP ) {
      _ftpSyncEnQ(QE_SFTP_MKDIR,QS_BEGIN,0,&fcp,path);
   } else {
      // FTP
      _ftpSyncEnQ(QE_MKD,QS_BEGIN,0,&fcp,path);
   }
}

void __ftpclientDelRemoteFile2CB( FtpQEvent *pEvent, typeless isPopping="" );
void __ftpclientDelRemoteFile3CB( FtpQEvent *pEvent );
void __ftpclientDelRemoteFile1CB( FtpQEvent *pEvent )
{
   FtpQEvent event;
   FtpConnProfile fcp;
   FtpConnProfile *fcp_p;
   FtpFile file;
   int formWid;

   event= *((FtpQEvent *)(pEvent));
   fcp=event.fcp;
   fcp.postedCb=null;

   filename := "";

   if( _ftpQEventIsError(event) || _ftpQEventIsAbort(event) ) {
      // Check for "fake" file/directory
      formWid=_ftpclientQFormWid();
      if( !formWid ) return;
      fcp_p=_ftpIsCurrentConnProfile(fcp.profileName,fcp.instance);
      if( !fcp_p ) return;   // This should never happen
      filename="";
      if( !event.info._isempty() ) {
         filename=event.info[0];
      }
      if( filename!="" ) {
         FtpFile ftpFile;
         int i,len=fcp_p->remoteDir.files._length();
         for( i=0;i<len;++i ) {
            ftpFile=fcp_p->remoteDir.files[i];
            if( filename==ftpFile.filename && ftpFile.type&FTPFILETYPE_FAKED ) {
               // This is a faked file/directory, so delete it because
               // it never existed in the first place.
               if( event.event==QE_DELE && !(ftpFile.type&FTPFILETYPE_DIR) ) {
                  // File
                  fcp_p->remoteDir.files._deleteel(i);
               } else if( event.event==QE_RMD && ftpFile.type&FTPFILETYPE_DIR ) {
                  // Directory
                  fcp_p->remoteDir.files._deleteel(i);
               }
            }
         }
      }
      // Make sure that we check the fcp that was passed in with the event,
      // not the original connection profile's.
      if( fcp.autoRefresh ) {
         formWid._UpdateRemoteSession(true);
      } else {
         formWid._UpdateRemoteSession(false);
      }
      formWid._UpdateLocalSession();
      return;
   }

   while( fcp.dir_stack._length()>0 ) {
      int idx=_ftpDirStackNext(fcp.dir_stack);
      while( idx>=0 ) {
         _ftpDirStackGetFile(fcp.dir_stack,file);
         if( file._isempty() ) {
            // This should never happen
            idx=_ftpDirStackNext(fcp.dir_stack);
            continue;
         }
         filename=file.filename;
         if( filename=="." || filename==".." ) {
            idx=_ftpDirStackNext(fcp.dir_stack);
            continue;
         } else {
            localcwd := "";
            remotecwd := "";
            _ftpDirStackGetLocalCwd(fcp.dir_stack,localcwd);
            _ftpDirStackGetRemoteCwd(fcp.dir_stack,remotecwd);
            if( (fcp.system==FTPSYST_UNIX || (fcp.system==FTPSYST_MVS && substr(fcp.remoteCwd,1,1)=='/')) &&
                file.type&FTPFILETYPE_LINK ) {
               // Get rid of the link part
               parse filename with filename '->' .;
               filename=strip(filename);
            }
            if( 0==(file.type & FTPFILETYPE_DIR) || 0!=(file.type & FTPFILETYPE_LINK) ) {
               // File or symbolic link.
               // Note:
               // Symbolic links must be deleted like files. RMD will _not_
               // work on a symbolic link.
               _ftpclientProgressCB("DELE ":+filename,0,0);
               fcp.postedCb=(typeless)__ftpclientDelRemoteFile1CB;
               _ftpIdleEnQ(QE_DELE,QS_BEGIN,0,&fcp,filename);
               return;
            } else if( file.type&FTPFILETYPE_DIR ) {
               // Directory
               if( fcp.recurseDirs ) {
                  // Set this now so it is easy to pick up in
                  // __ftpclientDelRemoteFile2CB() when we push.
                  //fcp.LocalCWD=local_path;
                  // We are pushing another directory, so push the directory name
                  // onto the .extra stack so we know which directory to RMD after
                  // we pop it.
                  _str dirnames[];
                  dirnames= (_str [])fcp.extra;
                  dirnames[dirnames._length()]=filename;
                  fcp.extra=dirnames;
                  // __ftpclientDelRemoteFile2CB() processes the CWD/PWD and listing
                  fcp.postedCb=(typeless)__ftpclientDelRemoteFile2CB;
                  _ftpIdleEnQ(QE_CWD,QS_BEGIN,0,&fcp,filename);
                  return;
               } else {
                  // Attempt to remove the directory
                  _ftpclientProgressCB("RMD ":+filename,0,0);
                  fcp.postedCb=(typeless)__ftpclientDelRemoteFile1CB;
                  _ftpIdleEnQ(QE_RMD,QS_BEGIN,0,&fcp,filename);
                  return;
               }
            }
         }
         idx=_ftpDirStackNext(fcp.dir_stack);
      }
      // Pop this directory listing off the stack
      _ftpDirStackPop(fcp.dir_stack);
      if( fcp.dir_stack._length()>0 ) {
         // Change the local directory back to previous
         fcp.localCwd=fcp.dir_stack[fcp.dir_stack._length()-1].localcwd;
         // fcp.RemoteCWD will be correct after the CWD/PWD
         // Change the listing back to previous
         fcp.remoteDir=fcp.dir_stack[fcp.dir_stack._length()-1].dir;
         // CWD back to original directory
         _str cwd=fcp.dir_stack[fcp.dir_stack._length()-1].remotecwd;
         if( fcp.system==FTPSYST_MVS ) {
            if( substr(cwd,1,1)!='/' ) {
               // Make it absolute for MVS
               cwd="'":+cwd:+"'";
            }
         }
         // __ftpclientDelRemoteFile3CB() processes the CWD/PWD
         fcp.postedCb=(typeless)__ftpclientDelRemoteFile3CB;
         _ftpIdleEnQ(QE_CWD,QS_BEGIN,0,&fcp,cwd);
         return;
      }
   }

   formWid=_ftpclientQFormWid();
   if( formWid ) {
      if( fcp.autoRefresh ) {
         formWid._UpdateRemoteSession(true);
      } else {
         formWid._UpdateRemoteSession(false);
      }
      formWid._UpdateLocalSession();
   }
}

/**
 * Callback used when changing directory and retrieving a listing.
 */
void __ftpclientDelRemoteFile2CB( FtpQEvent *pEvent, typeless isPopping="" )
{
   FtpQEvent event;
   FtpRecvCmd rcmd;
   FtpConnProfile fcp;
   FtpConnProfile *fcp_p;
   cmd := "";
   msg := "";
   cwd := "";
   typeless status=0;

   event= *((FtpQEvent *)(pEvent));
   fcp=event.fcp;

   // Indicates that we are in the middle of popping back to the previous
   // directory. No need to do a listing.
   popping := (isPopping != "");

   if( _ftpQEventIsError(event) || _ftpQEventIsAbort(event) ) {
      if( !_ftpQEventIsError(event) ) {
         // User aborted
         return;
      }
      do_cleanup := true;
      if( !popping ) {
         if( event.event==QE_RECV_CMD ) {
            rcmd= (FtpRecvCmd)event.info[0];
            parse rcmd.cmdargv[0] with cmd .;
            if( upcase(cmd)!="LIST" ) return;
            if( fcp.resolveLinks ) {
               // Ask the user if they would like to retry the listing without resolving links
               msg='The error you received may have been caused by the "Resolve links" ':+
                   'option you have turned ON for this connection profile.':+"\n\n":+
                   'The "Resolve links" option can be turned OFF permanently from the ':+
                   'Advanced tab of the "Create FTP Profile" dialog ("File"..."FTP"...':+
                   '"Profile Manager", pick a profile and click "Edit").':+"\n\n":+
                   'Turn OFF "Resolve links" for this session?';
               status=_message_box(msg,FTP_ERRORBOX_TITLE,MB_YESNO|MB_ICONQUESTION);
               if( status==IDYES ) {
                  // User wants to retry the LIST w/out resolving links, so
                  // turn off ResolveLinks and fake us into thinking we just
                  // did a PWD in order to force a re-listing.
                  event.event=QE_PWD;
                  event.state=0;
                  fcp.resolveLinks=false;
                  // Find the matching connection profile in current connections
                  // so we can change its ResolveLinks field.
                  fcp_p=null;
                  typeless i;
                  for( i._makeempty();; ) {
                     _ftpCurrentConnections._nextel(i);
                     if( i._isempty() ) break;
                     FtpConnProfile currentconn=_ftpCurrentConnections:[i];
                     if( _ftpCurrentConnections:[i].profileName==fcp.profileName &&
                         _ftpCurrentConnections:[i].instance==fcp.instance ) {
                        // Found it
                        fcp_p= &(_ftpCurrentConnections:[i]);
                        break;
                     }
                  }
                  if( fcp_p ) {
                     fcp_p->resolveLinks=fcp.resolveLinks;
                  }
                  do_cleanup=false;
               }
            } else {
               if( fcp.system==FTPSYST_MVS && !fcp.ignoreListErrors && substr(fcp.remoteCwd,1,1)!='/' ) {
                  msg="Some MVS hosts return an error when listing the ":+
                      "contents of an empty PDS\n\nIgnore this error?";
                  status=_message_box(msg,"FTP",MB_YESNO);
                  if( status==IDYES ) {
                     // Ignore LIST errors from now until the end of this operation
                     fcp.ignoreListErrors=true;
                     do_cleanup=false;
                  }
               } else {
                  msg="Error listing the contents of\n\n":+fcp.remoteCwd:+
                      "\n\nContinue?";
                  status=_message_box(msg,"FTP",MB_YESNO);
                  if( status==IDYES ) {
                     // User elected to continue
                     do_cleanup=false;
                  }
               }
               if( !do_cleanup ) {
                  // Set the directory listing back to what it was
                  fcp.remoteDir=fcp.dir_stack[fcp.dir_stack._length()-1].dir;
                  // CWD back to original directory
                  cwd=fcp.dir_stack[fcp.dir_stack._length()-1].remotecwd;
                  if( fcp.system==FTPSYST_MVS ) {
                     if( substr(cwd,1,1)!='/' ) {
                        // Make it absolute for MVS
                        cwd="'":+cwd:+"'";
                     }
                  }
                  // __ftpclientDelRemoteFile3CB() processes the CWD/PWD
                  fcp.postedCb=(typeless)__ftpclientDelRemoteFile3CB;
                  _ftpIdleEnQ(QE_CWD,QS_BEGIN,0,&fcp,cwd);
                  return;
               }
            }
         } else if( event.event==QE_CWD ) {
            cwd=event.info[0];
            msg="Failed to change directory to ":+cwd:+
                "\n\nContinue?";
            status=_message_box(msg,"FTP",MB_YESNO);
            if( status==IDYES ) {
               // fcp.LocalCWD was set in __ftpclientDelRemoteFile1CB(), so
               // set it back.
               fcp.localCwd=fcp.dir_stack[fcp.dir_stack._length()-1].localcwd;
               event._makeempty();
               event.fcp=fcp;
               event.event=QE_NONE;
               event.state=QS_NONE;
               event.start=0;
               // __ftpclientDelRemoteFile1CB() processes the next file directory
               __ftpclientDelRemoteFile1CB(&event);
               return;
            }
         }
      }
      if( do_cleanup ) {
         // If we got here then we need to clean up
         formWid := _ftpclientQFormWid();
         // Update the local session back to original
         if( formWid ) formWid._UpdateLocalSession();
         // Update remote session back to original and stop
         if( fcp.remoteCwd!=fcp.dir_stack[0].remotecwd ) {
            cwd=fcp.dir_stack[0].remotecwd;
            if( fcp.system==FTPSYST_MVS ) {
               if( substr(cwd,1,1)!='/' ) {
                  // Make it absolute for MVS
                  cwd="'":+cwd:+"'";
               }
            }
            ftpclientChangeRemoteDir(cwd);
         } else {
            if( formWid ) formWid._UpdateRemoteSession(false);
         }
         return;
      }
      // Fall through - this usually happens if user elected to retry
      // the listing with fcp.ResolveLinks=false or ignore LIST errors.
   }

   if( !popping && event.event==QE_PWD ) {
      // We just printed the current working directory.
      // Now we must list its contents.

      /*
      typedef struct RecvCmd_s {
         bool pasv;
         _str cmdargv[];
         _str dest;
         _str datahost;
         _str dataport;
         int  size;
         pfnProgressCallback_tp ProgressCB;
      } RecvCmd_t;
      */
      fcp.postedCb=(typeless)__ftpclientDelRemoteFile2CB;
      typeless pasv= (fcp.useFirewall && fcp.global_options.fwenable && fcp.global_options.fwpasv );
      typeless cmdargv;
      cmdargv._makeempty();
      cmdargv[0]="LIST";
      if( fcp.resolveLinks ) {
         cmdargv[cmdargv._length()]="-L";
      }
      _str dest=mktemp();
      if( dest=="" ) {
         msg="Unable to create temp file for remote directory listing";
         ftpDisplayError(msg);
         return;
      }
      datahost := "";
      dataport := "";
      size := 0;
      xfer_type := FTPXFER_ASCII;   // Always transfer listings ASCII
      rcmd.pasv=pasv;
      rcmd.cmdargv=cmdargv;
      rcmd.dest=dest;
      rcmd.datahost=datahost;
      rcmd.dataport=dataport;
      rcmd.size=size;
      rcmd.xfer_type=xfer_type;
      rcmd.progressCb=_ftpclientProgressCB;
      _ftpIdleEnQ(QE_RECV_CMD,QS_BEGIN,0,&fcp,rcmd);
      return;
   }

   if( !popping ) {
      rcmd= (FtpRecvCmd)event.info[0];
      if( _ftpdebug&FTPDEBUG_SAVE_LIST ) {
         // Make a copy of the raw listing
         temp_path := _temp_path();
         _maybe_append_filesep(temp_path);
         list_filename := temp_path:+"$list";
         copy_file(rcmd.dest,list_filename);
      }
      status=_ftpParseDir(&fcp,fcp.remoteDir,fcp.remoteFileFilter,rcmd.dest);
      typeless status2=delete_file(rcmd.dest);
      if( status2 && status2!=FILE_NOT_FOUND_RC && status2!=PATH_NOT_FOUND_RC ) {
         msg='Warning: Could not delete temp file "':+rcmd.dest:+'".  ':+_ftpGetMessage(status2);
         ftpDisplayError(msg);
      }
      if( status ) {
         // Set the directory listing back to what it was
         fcp.remoteDir=fcp.dir_stack[fcp.dir_stack._length()-1].dir;
         // CWD back to original directory
         cwd=fcp.dir_stack[fcp.dir_stack._length()-1].remotecwd;
         if( fcp.system==FTPSYST_MVS ) {
            if( substr(cwd,1,1)!='/' ) {
               // Make it absolute for MVS
               cwd="'":+cwd:+"'";
            }
         }
         // __ftpclientDelRemoteFile3CB() processes the CWD/PWD
         fcp.postedCb=(typeless)__ftpclientDelRemoteFile3CB;
         _ftpIdleEnQ(QE_CWD,QS_BEGIN,0,&fcp,cwd);
         return;
      } else {
         #if 1
         // Refresh the remote listing so the user sees what is going on
         _ftpclientUpDownLoadRefresh(&fcp);
         #endif

         // Note that fcp.LocalCWD was set in __ftpclientDelRemoteFile1CB() in
         // anticipation of the push.
         _ftpDirStackPush(fcp.localCwd,fcp.remoteCwd,&fcp.remoteDir,fcp.dir_stack);
         fcp.postedCb=null;
         event._makeempty();
         event.fcp=fcp;
         event.event=QE_NONE;
         event.state=QS_NONE;
         event.start=0;
         // __ftpclientDelRemoteFile1CB() processes the next file directory
         __ftpclientDelRemoteFile1CB(&event);
         return;
      }
   }

   // If we got here then we must have just finished popping back to a
   // previous directory, so process the next file/directory or RMD
   // the directory we just popped from.
   fcp.postedCb=null;
   _str dirnames[];
   dirnames= (_str [])fcp.extra;
   if( event.event==QE_PWD ) {
      if( fcp.dir_stack._length()>0 ) {
         // Change the local directory back to previous
         fcp.localCwd=fcp.dir_stack[fcp.dir_stack._length()-1].localcwd;
         // fcp.RemoteCWD should already be correct
         // Change the listing back to previous
         fcp.remoteDir=fcp.dir_stack[fcp.dir_stack._length()-1].dir;
      }
      if( dirnames._length()>0 ) {
         // We just finished popping back a directory, so now we must
         // RMD the directory name itself.
         _str dirname=dirnames[dirnames._length()-1];
         dirnames._deleteel(dirnames._length()-1);
         fcp.extra=dirnames;
         fcp.postedCb=(typeless)__ftpclientDelRemoteFile3CB;
         _ftpIdleEnQ(QE_RMD,QS_BEGIN,0,&fcp,dirname);
         return;
      }
   }
   // Finished the RMD of the original directory, so process the next
   // file/directory.
   event._makeempty();
   event.fcp=fcp;
   event.event=QE_NONE;
   event.state=QS_NONE;
   event.start=0;

   #if 1
   // If dirnames._length()==0 then it means we are back to the original
   // directory listing which only consists of the selected files/directories.
   // So the user doesn't see a curtailed listing and think that more files
   // than they specified were deleted, we defer the refresh.
   if( dirnames._length()>0 ) {
      // Refresh the remote listing so the user sees what is going on
      _ftpclientUpDownLoadRefresh(&fcp);
   }
   #endif

   // __ftpclientDelRemoteFile1CB() processes the next file directory
   __ftpclientDelRemoteFile1CB(&event);
}

/**
 * Callback used when popping a directory.
 */
void __ftpclientDelRemoteFile3CB( FtpQEvent *pEvent )
{
   // The second argument tells __ftpclientDelRemoteFile2CB() that we are
   // popping the top directory off the stack. No need to do a listing.
   __ftpclientDelRemoteFile2CB(pEvent, 1);
}

_command void ftpclientDelRemoteFile() name_info(','VSARG2_NCW|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   FtpConnProfile *fcp_p;
   FtpConnProfile fcp;
   FtpDirectory dir;
   FtpFile file;
   FtpQEvent event;

   sstabWid := profileWid := localWid := remoteWid := 0;
   formWid := _ftpclientQFormWid();
   if( !formWid ) return;
   if( _ftpclientFindAllControls(formWid,sstabWid,profileWid,localWid,remoteWid) ) return;
   fcp_p=formWid.GetCurrentConnProfile();
   if( !fcp_p ) return;

   nofselected := remoteWid._TreeGetNumSelectedItems();
   if( !nofselected ) return;
   fcp= *fcp_p;   // Make a copy

   // Check for directories selected
   dirs := false;
   if( nofselected ) {
      idx := remoteWid._TreeGetNextSelectedIndex(1,auto treeSelectInfo);
      while( idx>=0 ) {
         caption := remoteWid._TreeGetCaption(idx);
         _str filename, size, modified, attribs;
         parse caption with filename "\t" size "\t" modified "\t" attribs;
         if ( filename != '..' ) {
            int flags = remoteWid._ftpTreeItemUserInfo2TypeFlags(idx);
            // Filename OR directory
            if ( testFlag(flags, FTPFILETYPE_DIR) ) {
               dirs = true;
               break;
            }
         }
         idx=remoteWid._TreeGetNextSelectedIndex(0,treeSelectInfo);
      }
   }

   msg := "Delete ":+nofselected:+" files/directories";
   if( dirs ) {
      msg :+= " and their contents";
   }
   msg :+= "?";
   typeless status=_message_box(msg,"FTP",MB_YESNO|MB_ICONQUESTION);
   if( status!=IDYES ) return;

   if( dirs ) {
      // Force autorefresh if recursively deleting directories
      fcp.autoRefresh=true;
   }

   fcp.recurseDirs=true;

   // Populate a remote directory list with only the selected items
   dir._makeempty();
   dir.flags=0;
   ff := 1;
   int treeSelectInfo; 

   for(;;) {
      index := remoteWid._TreeGetNextSelectedIndex(ff, treeSelectInfo);
      ff=0;
      if( index<0 ) break;
      caption := remoteWid._TreeGetCaption(index);
      filename := "";
      parse caption with filename "\t" .;
      file._makeempty();
      file.filename=filename;

      // Fill unimportant fields
      file.attribs="";
      file.day=0;
      file.group="";
      file.month="";
      file.owner="";
      file.refs=0;
      file.size=0;
      file.time="";
      file.mtime = '';
      file.year=0;

      int flags = remoteWid._ftpTreeItemUserInfo2TypeFlags(index);
      file.type = flags & (FTPFILETYPE_DIR | FTPFILETYPE_LINK);
      dir.files[dir.files._length()] = file;
   }

   _ftpclientMaybeReconnect(&fcp);

   _ftpDirStackClear(fcp.dir_stack);
   _ftpDirStackPush(fcp.localCwd,fcp.remoteCwd,&dir,fcp.dir_stack);
   // .extra field holds a stack of directory names so we know the name of
   // the directory to RMD after we pop it.
   fcp.extra._makeempty();
   // Override RemoteFileFilter with FTP_ALLFILES_RE so that selected
   // directories' contents are completely deleted.
   fcp.remoteFileFilter=FTP_ALLFILES_RE;
   event._makeempty();
   event.event=QE_NONE;
   event.state=QS_NONE;
   event.fcp=fcp;
   event.start=0;
   if( fcp.serverType==FTPSERVERTYPE_SFTP ) {
      __sftpclientDelRemoteFile1CB(&event);
   } else {
      // FTP
      __ftpclientDelRemoteFile1CB(&event);
   }
}

void _ctl_remote_dir.'DEL'()
{
   ftpclientDelRemoteFile();
}

void __ftpclientRenameRemoteFileCB( FtpQEvent *pEvent )
{
   FtpQEvent event;
   FtpConnProfile fcp;
   FtpConnProfile *fcp_p;
   int formWid;

   event= *((FtpQEvent *)(pEvent));

   fcp=event.fcp;
   if( _ftpQEventIsError(event) || _ftpQEventIsAbort(event) ) {
      // Nothing to do
      return;
   }

   formWid=_ftpclientQFormWid();
   if( !formWid ) return;
   // _UpdateRemoteSession() will take care of asynchronous refresh
   if( fcp.autoRefresh ) {
      formWid._UpdateRemoteSession(true);
   } else {
      // Auto refresh is OFF, so fake the directory entry
      fcp_p=_ftpIsCurrentConnProfile(fcp.profileName,fcp.instance);
      if( !fcp_p ) return;   // This should never happen
      rnfr := "";
      rnto := "";
      if( event.info._length()>=2 ) {
         rnfr=event.info[0];
         rnto=event.info[1];
      }
      if( rnfr!="" && rnto!="" ) {
         FtpFile file;
         _str path_rnfr=_ftpAbsolute(fcp_p,rnfr);
         path_rnfr=_ftpStripFilename(fcp_p,path_rnfr,'N');
         _str path_rnto=_ftpAbsolute(fcp_p,rnto);
         path_rnto=_ftpStripFilename(fcp_p,path_rnto,'N');
         // If moved==true then the file/directory was moved outside of
         // the current remote working directory. Therefore it should
         // not be visible, so delete it from the list.
         moved := !_ftpFileEq(fcp_p,path_rnfr,path_rnto);
         int i,len=fcp_p->remoteDir.files._length();
         for( i=0;i<len;++i ) {
            file=fcp_p->remoteDir.files[i];
            if( rnfr==file.filename ) {
               if( moved ) {
                  fcp_p->remoteDir.files._deleteel(i);
               } else {
                  // Just change the name of the file and flag it as RENAMED
                  file.filename=rnto;
                  file.type |= FTPFILETYPE_RENAMED;
                  fcp_p->remoteDir.files[i]=file;
               }
               break;
            }
         }
         formWid._UpdateRemoteSession(false);
      }
   }
}

_command void ftpclientRenameRemoteFile() name_info(','VSARG2_NCW|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   FtpConnProfile *fcp_p;
   FtpConnProfile fcp;

   sstabWid := profileWid := localWid := remoteWid := 0;
   formWid := _ftpclientQFormWid();
   if( !formWid ) return;
   if( _ftpclientFindAllControls(formWid,sstabWid,profileWid,localWid,remoteWid) ) return;
   fcp_p=formWid.GetCurrentConnProfile();
   if( !fcp_p ) return;

   nofselected := remoteWid._TreeGetNumSelectedItems();
   if( !nofselected || nofselected>1 ) return;
   idx := remoteWid._TreeCurIndex();
   rnfr := "";
   if( idx<0 ) return;
   caption := remoteWid._TreeGetCaption(idx);
   parse caption with rnfr "\t" .;
   if( rnfr==".." ) {
      return;
   } else {
      int flags = remoteWid._ftpTreeItemUserInfo2TypeFlags(idx);
      if ( (fcp_p->system == FTPSYST_UNIX || (fcp_p->system == FTPSYST_MVS && substr(fcp_p->remoteCwd,1,1) == '/')) 
           && testFlag(flags, FTPFILETYPE_LINK) ) {

         // Get rid of the link part
         parse rnfr with rnfr '->' .;
         rnfr=strip(rnfr);
      }
      typeless status=show("-modal _textbox_form","Rename ":+rnfr:+" to...",0,"","?Specify a filename to rename to","","","Rename to:":+rnfr);
      if( status=="" ) {
         // User cancelled
         return;
      }
      _str rnto=_param1;
      if( rnto=="" ) {
         return;
      }

      // Make a copy
      fcp= *fcp_p;

      _ftpclientMaybeReconnect(&fcp);

      // Note that both FTP _and_ SFTP can use the same callback
      fcp.postedCb=(typeless)__ftpclientRenameRemoteFileCB;
      if( fcp.serverType==FTPSERVERTYPE_SFTP ) {
         _ftpSyncEnQ(QE_SFTP_RENAME,QS_BEGIN,0,&fcp,rnfr,rnto);
      } else {
         // FTP
         _ftpSyncEnQ(QE_RENAME,QS_BEGIN,0,&fcp,rnfr,rnto);
      }
      return;
   }
}

void __ftpclientCustomCmdCB( FtpQEvent *pEvent )
{
   FtpQEvent event;
   FtpConnProfile fcp;
   FtpCustomCmd ccmd;

   event= *((FtpQEvent *)(pEvent));

   fcp=event.fcp;
   fcp.postedCb=(typeless)__ftpclientCustomCmdCB;   // Paranoid
   ccmd= (FtpCustomCmd)event.info[0];
   if( !_ftpQEventIsError(event) && !_ftpQEventIsAbort(event) ) {
      _str pattern=ccmd.pattern;
      if( pos('%f',pattern) ) {
         int idx=_ftpTodoFindNext();
         if( idx>=0 ) {
            caption := "";
            _ftpTodoGetCaption(caption);
            _str filename, size, modified, attribs;
            parse caption with filename "\t" size "\t" modified "\t" attribs;
            info := "";
            _ftpTodoGetUserInfo(info);
            info=lowcase(info);
            if( (fcp.system==FTPSYST_UNIX || (fcp.system==FTPSYST_MVS && substr(fcp.remoteCwd,1,1)=='/')) &&
                pos("l",info) ) {
               // Get rid of the link part
               parse filename with filename '->' .;
               filename=strip(filename);
            }
            cmdline := stranslate(pattern,filename,'%f','');
            if( cmdline=="" ) {
               msg := 'Your custom command evaluates to ""';
               ftpDisplayError(msg);
               return;
            }
            ccmd.cmdargv[0]=cmdline;
            _ftpIdleEnQ(QE_CUSTOM_CMD,QS_BEGIN,0,&fcp,ccmd);
            return;
         }
         // That was the last one
      } else {
         // The command was only sent once, so we are done
      }
   }

   if( pos('%f',ccmd.pattern) ) {
      // We were operating on files, so refresh the remote listing
      formWid := _ftpclientQFormWid();
      if( formWid ) {
         formWid._UpdateRemoteSession(true);
      }
   }
}

_command void ftpclientCustomCmd() name_info(','VSARG2_NCW|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   FtpConnProfile *fcp_p;
   FtpConnProfile fcp;
   int formWid;
   FtpCustomCmd ccmd;

   formWid=_ftpclientQFormWid();
   if( !formWid ) return;
   treeWid := formWid._find_control("_ctl_remote_dir");
   if( !treeWid ) return;
   fcp_p=formWid.GetCurrentConnProfile();
   if( !fcp_p ) return;
   if( fcp_p->serverType!=FTPSERVERTYPE_FTP ) {
      msg := "Custom commands not supported for this server type";
      ftpDisplayError(msg);
      return;
   }
   // We use the fake name ftpCustomCmd to keep track of retrieve info.
   // Because we use the same retrieve name for both the FTP Client toolbar
   // and the FTP open tab, they share retrieve history.
   typeless status=show("-modal _textbox_form","FTP Custom Command",TB_RETRIEVE|TB_RETRIEVE_INIT,"","?Substitutions:\n\n%f - Remote filename (no path)\n\nExample: To give full permissions to selected files in the tree, issue the command:\n\nSITE CHMOD 777 %f","","ftpCustomCmd","Command");
   if( status=="" ) {
      // User cancelled
      return;
   }
   _str pattern=_param1;
   if( pattern=="" ) {
      return;
   }

   // Make a copy
   fcp = *fcp_p;

   _ftpclientMaybeReconnect(&fcp);

   ccmd._makeempty();
   ccmd.pattern=pattern;
   fcp.postedCb=(typeless)__ftpclientCustomCmdCB;
   if( pos('%f',pattern) ) {
      // We are acting on selected files in the tree
      nofselected := treeWid._TreeGetNumSelectedItems();
      if( nofselected ) {
         treeWid._ftpTodoGetList();
         int idx=_ftpTodoFindNext();
         if( idx>=0 ) {
            caption := "";
            _ftpTodoGetCaption(caption);
            _str filename, size, modified, attribs;
            parse caption with filename "\t" size "\t" modified "\t" attribs;
            info := "";
            _ftpTodoGetUserInfo(info);
            info=lowcase(info);
            if( (fcp.system==FTPSYST_UNIX || (fcp.system==FTPSYST_MVS && substr(fcp.remoteCwd,1,1)=='/')) &&
                pos("l",info) ) {
               // Get rid of the link part
               parse filename with filename '->' .;
               filename=strip(filename);
            }
            cmdline := stranslate(pattern,filename,'%f','');
            if( cmdline=="" ) {
               msg := 'Your custom command evaluates to ""';
               ftpDisplayError(msg);
               return;
            }
            ccmd.cmdargv[0]=cmdline;
            _ftpSyncEnQ(QE_CUSTOM_CMD,QS_BEGIN,0,&fcp,ccmd);
         }
      } else {
         msg := "Your custom command requires atleast one file to be selected";
         ftpDisplayError(msg);
      }
   } else {
      // Send the command line once
      ccmd.cmdargv[0]=ccmd.pattern;
      _ftpSyncEnQ(QE_CUSTOM_CMD,QS_BEGIN,0,&fcp,ccmd);
   }
}

_command void ftpclientRemoteHScrollbar() name_info(','VSARG2_NCW|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   sstabWid := profileWid := localWid := remoteWid := 0;
   formWid := _ftpclientQFormWid();
   if( !formWid ) return;
   if( _ftpclientFindAllControls(formWid,sstabWid,profileWid,localWid,remoteWid) ) return;
   int scroll_bars=remoteWid.p_scroll_bars;
   if( scroll_bars&SB_HORIZONTAL ) {
      // Turn horizontal scroll bar OFF, turn popup ON
      remoteWid.p_scroll_bars &= ~(SB_HORIZONTAL);
      remoteWid.p_delay=0;
   } else {
      // Turn horizontal scroll bar ON, turn popup OFF
      remoteWid.p_scroll_bars |= SB_HORIZONTAL;
      remoteWid.p_delay= -1;
   }
   // Remember horizontal scroll bar settings.
   // Must do this here because exiting the editor does not call a control's
   // ON_DESTROY event.
   _append_retrieve(0,_ctl_remote_dir.p_scroll_bars,"_tbFTPClient_form._ctl_remote_dir.p_scroll_bars");
}

_command void ftpclientRemoteFilter() name_info(','VSARG2_NCW|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   FtpConnProfile *fcp_p;
   FtpConnProfile fcp;
   int formWid;

   formWid=_ftpclientQFormWid();
   if( !formWid ) return;
   fcp_p=formWid.GetCurrentConnProfile();
   if( !fcp_p ) return;
   _str filter=fcp_p->remoteFileFilter;
   if( filter=="" ) filter=FTP_ALLFILES_RE;
   typeless status=show("-modal _textbox_form","Remote file filter",TB_RETRIEVE,"","?Specify the file filter for file listings. Separate multiple filters with a space.\n\nExample: *.html *.shtml","","ftpFilter","Filter:":+filter);
   if( status=="" ) {
      // User cancelled
      return;
   }
   filter=_param1;
   if( filter=="" ) return;
   fcp_p->remoteFileFilter=filter;

   // Make a copy
   fcp = *fcp_p;

   _ftpclientMaybeReconnect(&fcp);
   formWid._UpdateRemoteSession(true);
}

_command void ftpclientRefreshRemoteSession() name_info(','VSARG2_NCW|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   FtpConnProfile *fcp_p;
   FtpConnProfile fcp;

   fcp_p=ftpclientGetCurrentConnProfile();
   if( fcp_p ) {
      formWid := _ftpclientQFormWid();
      if( formWid!=0 ) {

         // Make a copy
         fcp = *fcp_p;

         _ftpclientMaybeReconnect(&fcp);
         formWid._UpdateRemoteSession(true);
      }
   }
}

// This expects the active window to be a tree view.
// Saves the scroll position and the current item in the tree,
// the local working directory, profile, and instance.
// Use _ftpclientLocalRestorePos() to restore.
static void _ftpclientLocalSavePos()
{
   FtpConnProfile *fcp_p;
   typeless tree_pos;
   int formWid;

   typeless instance=0;
   profile := "";
   cwd := "";
   p := "";
   _TreeSavePos(tree_pos);
   formWid=_ftpclientQFormWid();
   if( formWid ) {
      fcp_p=formWid.GetCurrentConnProfile();
      if( !fcp_p ) {
         cwd=LOCALCWD;
         if( cwd=="" ) cwd=".";
         profile="-";
         instance=0;
      } else {
         cwd=fcp_p->localCwd;
         if( cwd=="" ) cwd=".";
         cwd='"':+cwd:+'"';
         profile='"':+fcp_p->profileName:+'"';
         instance=fcp_p->instance;
      }
      p=cwd" "profile" "instance" "tree_pos;
   }
   LOCALTREEPOS=p;
}

// This expects the active window to be a tree view.
// Restores the scroll position and the current item in the tree.
// Use _ftpclientLocalSavePos() to save.
void _ftpclientLocalRestorePos()
{
   FtpConnProfile *fcp_p;
   typeless tree_pos;
   int formWid;
   typeless p;

   typeless instance=0;
   profile := "";
   cwd := "";
   p=LOCALTREEPOS;
   if( p=="" ) return;
   formWid=_ftpclientQFormWid();
   if( formWid ) {
      fcp_p=formWid.GetCurrentConnProfile();
      if( !fcp_p ) {
         cwd=LOCALCWD;
         if( cwd=="" ) cwd=".";
         profile="-";
         instance=0;
      } else {
         cwd=fcp_p->localCwd;
         if( cwd=="" ) cwd=".";
         profile=fcp_p->profileName;
         instance=fcp_p->instance;
      }
      typeless lrp_cwd, lrp_profile, lrp_instance;
      parse p with '"' lrp_cwd '"' '"' lrp_profile '"' lrp_instance tree_pos;
      if( tree_pos!="" ) {
         if( lrp_cwd==cwd && lrp_profile==profile && lrp_instance==instance ) {
            _TreeRestorePos(tree_pos);
            _TreeRefresh();
         }
      }
   }
}

/**
 * Use this to keep track of the current item, selected item,
 * scroll position, working directory, profile, and instance.
 * This is used to keep track of whether we need to restore
 * the current item and scroll position in the current local
 * directory listing.
 */
void _ctl_local_dir.on_change(int reason, int index, int col=-1)
{
   if ( !_ftpclientChangeLocalDirOnOff() ) {
      return;
   }

   switch ( reason ) {
   case CHANGE_BUTTON_PRESS:
      {
         //say('_ctl_remote_dir.on_change : CHANGE_BUTTON_PRESS - col='col);

         int name_sort_flags = _ftpTreeSortFlags(0);
         int size_sort_flags = _ftpTreeSortFlags(1);
         int modified_sort_flags = _ftpTreeSortFlags(2);
         int attribs_sort_flags = _ftpTreeSortFlags(3);

         opts := "";

         if ( col == 0 ) {
            // Sort by Name (directories/links, then filenames)

            // Name - set column sort flags
            opts = 'E';
            if ( name_sort_flags & TREE_BUTTON_SORT_DESCENDING ) {
               // Switch to Ascending
               name_sort_flags = TREE_BUTTON_SORT;
            } else {
               // Switch to Descending
               name_sort_flags = TREE_BUTTON_SORT_DESCENDING;
               opts :+= 'D';
            }

            // Size - reset sort flags
            size_sort_flags = size_sort_flags & ~(TREE_BUTTON_SORT | TREE_BUTTON_SORT_DESCENDING);

            // Modified - reset column sort flags
            modified_sort_flags = modified_sort_flags & ~(TREE_BUTTON_SORT | TREE_BUTTON_SORT_DESCENDING);

            // Attributes - reset column sort flags
            attribs_sort_flags = attribs_sort_flags & ~(TREE_BUTTON_SORT | TREE_BUTTON_SORT_DESCENDING);

         } else if ( col == 1 ) {
            // Sort by Size

            // Size - set column sort flags
            opts = 'E';
            if ( size_sort_flags & TREE_BUTTON_SORT_DESCENDING ) {
               // Switch to Ascending
               size_sort_flags = TREE_BUTTON_SORT;
            } else {
               // Switch to Descending
               size_sort_flags = TREE_BUTTON_SORT_DESCENDING;
               opts :+= 'D';
            }

            // Name - reset column sort flags
            name_sort_flags = name_sort_flags & ~(TREE_BUTTON_SORT | TREE_BUTTON_SORT_DESCENDING);

            // Modified - reset column sort flags
            modified_sort_flags = modified_sort_flags & ~(TREE_BUTTON_SORT | TREE_BUTTON_SORT_DESCENDING);

            // Attributes - reset column sort flags
            attribs_sort_flags = attribs_sort_flags & ~(TREE_BUTTON_SORT | TREE_BUTTON_SORT_DESCENDING);

         } else if ( col == 2 ) {
            // Sort by Modified

            // Modified - set column sort flags
            opts = 'E';
            if ( modified_sort_flags & TREE_BUTTON_SORT_DESCENDING ) {
               // Switch to Ascending
               modified_sort_flags = TREE_BUTTON_SORT;
            } else {
               // Switch to Descending
               modified_sort_flags = TREE_BUTTON_SORT_DESCENDING;
               opts :+= 'D';
            }

            // Name - reset column sort flags
            name_sort_flags = name_sort_flags & ~(TREE_BUTTON_SORT | TREE_BUTTON_SORT_DESCENDING);

            // Size - reset sort flags
            size_sort_flags = size_sort_flags & ~(TREE_BUTTON_SORT | TREE_BUTTON_SORT_DESCENDING);

            // Attributes - reset column sort flags
            attribs_sort_flags = attribs_sort_flags & ~(TREE_BUTTON_SORT | TREE_BUTTON_SORT_DESCENDING);

         } else if ( col == 3 ) {
            // Sort by Attributes

            // Attributes - set column sort flags
            opts = 'E';
            if ( attribs_sort_flags & TREE_BUTTON_SORT_DESCENDING ) {
               // Switch to Ascending
               attribs_sort_flags = TREE_BUTTON_SORT;
            } else {
               // Switch to Descending
               attribs_sort_flags = TREE_BUTTON_SORT_DESCENDING;
               opts :+= 'D';
            }

            // Name - reset column sort flags
            name_sort_flags = name_sort_flags & ~(TREE_BUTTON_SORT | TREE_BUTTON_SORT_DESCENDING);

            // Size - reset sort flags
            size_sort_flags = size_sort_flags & ~(TREE_BUTTON_SORT | TREE_BUTTON_SORT_DESCENDING);

            // Modified - reset column sort flags
            modified_sort_flags = modified_sort_flags & ~(TREE_BUTTON_SORT | TREE_BUTTON_SORT_DESCENDING);

         } else {
            // How did we get here?
            break;
         }

         // Sort flags must be set for each column BEFORE calling _ftpTreeSetAllUserInfo()
         _ftpSetTreeSortFlags(0, name_sort_flags);
         _ftpSetTreeSortFlags(1, size_sort_flags);
         _ftpSetTreeSortFlags(2, modified_sort_flags);
         _ftpSetTreeSortFlags(3, attribs_sort_flags);

         // Fix up userinfo hints so sorting works correctly
         _ftpTreeSetAllUserInfo();

         // Sort!
         _TreeSortUserInfo(TREE_ROOT_INDEX, opts);

         // HACK: After calling _TreeSortUserInfo(), we will no longer get on_change events until we "reset" the column info
         int width, flags, state;
         _str caption;
         _TreeGetColButtonInfo(col, width, flags, state, caption);
         _TreeSetColButtonInfo(col, width, flags, 0, caption);
      }
      break;
   default:
      _ftpclientLocalSavePos();
      //say('reason='reason'  'LOCALTREEPOS);
   }
}

void _ctl_local_dir.rbutton_down()
{
   // locate our mouse click
   int x=mou_last_x();
   int y=mou_last_y();
   int idx=_TreeGetIndexFromPoint(x,y,'P');

   // did we click on an item?
   if( idx>=0 ) {

      // get the first and last selected indices
      int firstidx = -1, lastidx = -1;
      int indices[];
      _TreeGetSelectionIndices(indices);
      if( indices._length() ) {
         firstidx = indices[0];
         lastidx = indices[indices._length() - 1];
      }

      // get the line numbers of the first, last, and what we clicked on
      int firstline=MAXINT;
      state := bm1 := bm2 := flags := 0;
      if( firstidx>=0 ) _TreeGetInfo(firstidx,state,bm1,bm2,flags,firstline);
      lastline := -1;
      if( lastidx>=0 ) _TreeGetInfo(lastidx,state,bm1,bm2,flags,lastline);
      line := 0;
      _TreeGetInfo(idx,state,bm1,bm2,flags,line);

      if( !indices._length() || line<firstline || line>lastline ) {
         // First deselect any lines
         _TreeDeselectAll();

         // now select what we clicked
         _TreeSetCurIndex(idx);
         _TreeSelectLine(idx);
      }
   }
}

void _ctl_local_dir.rbutton_up()
{
   FtpConnProfile *fcp_p;
   int formWid;

   menu_name := "_FTPClient_localdir_menu";
   int idx=find_index(menu_name,oi2type(OI_MENU));
   if( !idx ) {
      return;
   }
   int mh=p_active_form._menu_load(idx,'P');
   if( mh<0) {
      _message_box('Unable to load menu: "':+menu_name:+'"',"",MB_OK|MB_ICONEXCLAMATION);
      return;
   }

   formWid=_ftpclientQFormWid();
   if( !formWid ) return;
   treeWid := formWid._find_control("_ctl_local_dir");
   if( !treeWid ) return;   // Should never happen
   fcp_p=formWid.GetCurrentConnProfile();

   // If local file(s) not selected then disable file operations
   noffiles := 0;
   nofdirs := 0;
   idx=treeWid._TreeGetNextSelectedIndex(1,auto treeSelectInfo);
   while( idx>=0 ) {
      caption := treeWid._TreeGetCaption(idx);
      _str filename, size, modified, attribs;
      parse caption with filename "\t" size "\t" modified "\t" attribs;
      if( filename!=".." ) {
         int flags = treeWid._ftpTreeItemUserInfo2TypeFlags(idx);
         // Filename OR directory
         if ( !testFlag(flags, FTPFILETYPE_DIR) ) {
            ++noffiles;
         }
         if ( testFlag(flags, FTPFILETYPE_DIR) ) {
            ++nofdirs;
         }
      }
      idx = treeWid._TreeGetNextSelectedIndex(0, treeSelectInfo);
   }
   if( !fcp_p ) {
      _menu_set_state(mh,"ftpclientUpload",MF_GRAYED,'M');
      _menu_set_state(mh,"ftpclientManualUpload",MF_GRAYED,'M');
      _menu_set_state(mh,"ftpclientAutoRefresh",MF_GRAYED,'M');
   } else {
      if( fcp_p->autoRefresh ) {
         _menu_set_state(mh,"ftpclientAutoRefresh",MF_CHECKED,'M');
      } else {
         _menu_set_state(mh,"ftpclientAutoRefresh",MF_UNCHECKED,'M');
      }
   }
   if( !noffiles || nofdirs ) {
      _menu_set_state(mh,"ftpclientOpenLocalFile",MF_GRAYED,'M');
      _menu_set_state(mh,"ftpclientViewLocalFile",MF_GRAYED,'M');
   }
   // Associated files only supported on Windows
   if( machine()!='WINDOWS' ) {
      output_mh := 0;
      mpos := 0;
      int status=_menu_find(mh,"ftpclientViewLocalFile",output_mh,mpos,"M");
      if( !status ) _menu_delete(output_mh,mpos);

   }
   if( !noffiles && !nofdirs ) {
      _menu_set_state(mh,"ftpclientUpload",MF_GRAYED,'M');
      _menu_set_state(mh,"ftpclientDelLocalFile",MF_GRAYED,'M');
   }
   if( (noffiles+nofdirs)!=1 ) {
      _menu_set_state(mh,"ftpclientRenameLocalFile",MF_GRAYED,'M');
   }
   int on=treeWid.p_scroll_bars&SB_HORIZONTAL;
   if( on ) {
      _menu_set_state(mh,"ftpclientLocalHScrollbar",MF_CHECKED,'M');
   } else {
      _menu_set_state(mh,"ftpclientLocalHScrollbar",MF_UNCHECKED,'M');
   }

   // Show the menu:
   int x=VSDEFAULT_INITIAL_MENU_OFFSET_X;
   int y=VSDEFAULT_INITIAL_MENU_OFFSET_Y;
   x=mou_last_x('M')-x;y=mou_last_y('M')-y;
   _lxy2dxy(p_scale_mode,x,y);
   _map_xy(p_window_id,0,x,y,SM_PIXEL);
   int flags=VPM_LEFTALIGN|VPM_RIGHTBUTTON;
   int status=_menu_show(mh,flags,x,y);
   _menu_destroy(mh);
}

void _ctl_local_dir.'F5'()
{
   ftpclientRefreshLocalSession();
}

/**
 * Use this to keep track of the current item, selected item,
 * scroll position, working directory, profile, and instance.
 * This is used to keep track of whether we need to restore
 * the current item and scroll position in the current remote
 * directory listing.
 */
void _ctl_remote_dir.on_change(int reason, int index, int col=-1)
{
   if ( !_ftpclientChangeRemoteDirOnOff() ) {
      return;
   }

   switch ( reason ) {
   case CHANGE_BUTTON_PRESS:
      {
         //say('_ctl_remote_dir.on_change : CHANGE_BUTTON_PRESS - col='col);

         int name_sort_flags = _ftpTreeSortFlags(0);
         int size_sort_flags = _ftpTreeSortFlags(1);
         int modified_sort_flags = _ftpTreeSortFlags(2);
         int attribs_sort_flags = _ftpTreeSortFlags(3);

         opts := "";

         if ( col == 0 ) {
            // Sort by Name (directories/links, then filenames)

            // Name - set column sort flags
            opts = 'E';
            if ( name_sort_flags & TREE_BUTTON_SORT_DESCENDING ) {
               // Switch to Ascending
               name_sort_flags = TREE_BUTTON_SORT;
            } else {
               // Switch to Descending
               name_sort_flags = TREE_BUTTON_SORT_DESCENDING;
               opts :+= 'D';
            }

            // Size - reset sort flags
            size_sort_flags = size_sort_flags & ~(TREE_BUTTON_SORT | TREE_BUTTON_SORT_DESCENDING);

            // Modified - reset column sort flags
            modified_sort_flags = modified_sort_flags & ~(TREE_BUTTON_SORT | TREE_BUTTON_SORT_DESCENDING);

            // Attributes - reset column sort flags
            attribs_sort_flags = attribs_sort_flags & ~(TREE_BUTTON_SORT | TREE_BUTTON_SORT_DESCENDING);

         } else if ( col == 1 ) {
            // Sort by Size

            // Size - set column sort flags
            opts = 'E';
            if ( size_sort_flags & TREE_BUTTON_SORT_DESCENDING ) {
               // Switch to Ascending
               size_sort_flags = TREE_BUTTON_SORT;
            } else {
               // Switch to Descending
               size_sort_flags = TREE_BUTTON_SORT | TREE_BUTTON_SORT_DESCENDING;
               opts :+= 'D';
            }

            // Name - reset column sort flags
            name_sort_flags = name_sort_flags & ~(TREE_BUTTON_SORT | TREE_BUTTON_SORT_DESCENDING);

            // Modified - reset column sort flags
            modified_sort_flags = modified_sort_flags & ~(TREE_BUTTON_SORT | TREE_BUTTON_SORT_DESCENDING);

            // Attributes - reset column sort flags
            attribs_sort_flags = attribs_sort_flags & ~(TREE_BUTTON_SORT | TREE_BUTTON_SORT_DESCENDING);

         } else if ( col == 2 ) {
            // Sort by Modified

            // Modified - set column sort flags
            opts = 'E';
            if ( modified_sort_flags & TREE_BUTTON_SORT_DESCENDING ) {
               // Switch to Ascending
               modified_sort_flags = TREE_BUTTON_SORT;
            } else {
               // Switch to Descending
               modified_sort_flags = TREE_BUTTON_SORT_DESCENDING;
               opts :+= 'D';
            }

            // Name - reset column sort flags
            name_sort_flags = name_sort_flags & ~(TREE_BUTTON_SORT | TREE_BUTTON_SORT_DESCENDING);

            // Size - reset sort flags
            size_sort_flags = size_sort_flags & ~(TREE_BUTTON_SORT | TREE_BUTTON_SORT_DESCENDING);

            // Attributes - reset column sort flags
            attribs_sort_flags = attribs_sort_flags & ~(TREE_BUTTON_SORT | TREE_BUTTON_SORT_DESCENDING);

         } else if ( col == 3 ) {
            // Sort by Attributes

            // Attributes - set column sort flags
            opts = 'E';
            if ( attribs_sort_flags & TREE_BUTTON_SORT_DESCENDING ) {
               // Switch to Ascending
               attribs_sort_flags = TREE_BUTTON_SORT;
            } else {
               // Switch to Descending
               attribs_sort_flags = TREE_BUTTON_SORT_DESCENDING;
               opts :+= 'D';
            }

            // Name - reset column sort flags
            name_sort_flags = name_sort_flags & ~(TREE_BUTTON_SORT | TREE_BUTTON_SORT_DESCENDING);

            // Size - reset sort flags
            size_sort_flags = size_sort_flags & ~(TREE_BUTTON_SORT | TREE_BUTTON_SORT_DESCENDING);

            // Modified - reset column sort flags
            modified_sort_flags = modified_sort_flags & ~(TREE_BUTTON_SORT | TREE_BUTTON_SORT_DESCENDING);

         } else {
            // How did we get here?
            break;
         }

         // Sort flags must be set for each column BEFORE calling _ftpTreeSetAllUserInfo()
         _ftpSetTreeSortFlags(0, name_sort_flags);
         _ftpSetTreeSortFlags(1, size_sort_flags);
         _ftpSetTreeSortFlags(2, modified_sort_flags);
         _ftpSetTreeSortFlags(3, attribs_sort_flags);

         // Fix up userinfo hints so sorting works correctly
         _ftpTreeSetAllUserInfo();

         // Sort!
         _TreeSortUserInfo(TREE_ROOT_INDEX, opts);

         // HACK: After calling _TreeSortUserInfo(), we will no longer get on_change events until we "reset" the column info
         int width, flags, state;
         _str caption;
         _TreeGetColButtonInfo(col, width, flags, state, caption);
         _TreeSetColButtonInfo(col, width, flags, 0, caption);
      }
      break;
   default:
      _ftpRemoteSavePos();
      //say('reason='reason'  'REMOTETREEPOS);
   }
}

void _ctl_remote_dir.rbutton_down()
{
   call_event(_ctl_local_dir,RBUTTON_DOWN,'W');
}

void _ctl_remote_dir.rbutton_up()
{
   FtpConnProfile *fcp_p;
   int formWid;

   menu_name := "_FTPClient_remotedir_menu";
   int idx=find_index(menu_name,oi2type(OI_MENU));
   if( !idx ) {
      return;
   }
   int mh=p_active_form._menu_load(idx,'P');
   if( mh<0) {
      _message_box('Unable to load menu: "':+menu_name:+'"',"",MB_OK|MB_ICONEXCLAMATION);
      return;
   }

   formWid=_ftpclientQFormWid();
   if( !formWid ) return;
   treeWid := formWid._find_control("_ctl_remote_dir");
   if( !treeWid ) return;   // Should never happen
   fcp_p=formWid.GetCurrentConnProfile();

   // If a remote file/directory is not selected then disable file operations
   noffiles := 0;
   nofdirs := 0;
   noflinks := 0;
   idx=treeWid._TreeGetNextSelectedIndex(1,auto treeSelectInfo);
   while( idx>=0 ) {
      caption := treeWid._TreeGetCaption(idx);
      _str filename, size, modified, attribs;
      parse caption with filename "\t" size "\t" modified "\t" attribs;
      if( filename!=".." ) {
         int flags = treeWid._ftpTreeItemUserInfo2TypeFlags(idx);
         // Filename OR directory
         if ( !testFlag(flags, FTPFILETYPE_DIR) ) {
            ++noffiles;
         }
         if( testFlag(flags, FTPFILETYPE_DIR) ) {
            ++nofdirs;
         }
         if( testFlag(flags, FTPFILETYPE_LINK) ) {
            ++noflinks;
         }
      }
      idx = treeWid._TreeGetNextSelectedIndex(0, treeSelectInfo);
   }
   // fcp_p should always be non-null if we got here
   if( fcp_p ) {
      if( fcp_p->autoRefresh ) {
         _menu_set_state(mh,"ftpclientAutoRefresh",MF_CHECKED,'M');
      } else {
         _menu_set_state(mh,"ftpclientAutoRefresh",MF_UNCHECKED,'M');
      }
   }
   if( noffiles==0 && nofdirs==0 ) {
      _menu_set_state(mh,"ftpclientDelRemoteFile",MF_GRAYED,'M');
   }
   // Note:
   // ftpclientDownload() will try both the directory case and
   // the file case if a symobolic link is selected.
   if( noffiles==0 && nofdirs==0 ) {
      _menu_set_state(mh,"ftpclientDownload",MF_GRAYED,'M');
   }
   if( (noffiles+nofdirs)!=1 ) {
      _menu_set_state(mh,"ftpclientRenameRemoteFile",MF_GRAYED,'M');
   }
   if( noflinks==0 ) {
      _menu_set_state(mh,"ftpclientDownloadLinks",MF_GRAYED,'M');
   }
   if( fcp_p && fcp_p->serverType!=FTPSERVERTYPE_FTP ) {
      _menu_set_state(mh,"ftpclientCustomCmd",MF_GRAYED,'M');
   }
   int on=treeWid.p_scroll_bars&SB_HORIZONTAL;
   if( on ) {
      _menu_set_state(mh,"ftpclientRemoteHScrollbar",MF_CHECKED,'M');
   } else {
      _menu_set_state(mh,"ftpclientRemoteHScrollbar",MF_UNCHECKED,'M');
   }

   // Show the menu:
   int x=VSDEFAULT_INITIAL_MENU_OFFSET_X;
   int y=VSDEFAULT_INITIAL_MENU_OFFSET_Y;
   x=mou_last_x('M')-x;y=mou_last_y('M')-y;
   _lxy2dxy(p_scale_mode,x,y);
   _map_xy(p_window_id,0,x,y,SM_PIXEL);
   int flags=VPM_LEFTALIGN|VPM_RIGHTBUTTON;
   int status=_menu_show(mh,flags,x,y);
   _menu_destroy(mh);
}

void _ctl_remote_dir.'F5'()
{
   ftpclientRefreshRemoteSession();
}

void _ctl_local_drvlist.on_change(int reason)
{
   if (_isWindows()) {
      if( reason!=CHANGE_DRIVE ) return;
      if( !_ftpclientChangeDrvListOnOff() ) return;

      FtpConnProfile *fcp_p;
      FtpConnProfile fake;   // Used when there is no connection
      cwd := "";

      fcp_p=GetCurrentConnProfile();
      if( !fcp_p ) {
         // There is no current connection, so fake one
         cwd=LOCALCWD;
         if( cwd=="" ) {
            cwd=getcwd();
         }
         _ftpInitConnProfile(fake);
         fake.localCwd=cwd;
         fake.localFileFilter=LOCALFILTER;
         fcp_p=&fake;
      }
      localdrive := "";
      _str localcwd=fcp_p->localCwd;
      if( substr(localcwd,1,2)!='\\' && substr(localcwd,2,1)==':' ) {
         // We have a drive letter
         localdrive=substr(localcwd,1,1);   // Just the drive letter
      }
      drive := p_text;
      if( substr(drive,1,2)!='\\' ) {
         drive=substr(drive,1,1);   // Just the drive letter
      }
      // Change to the current working directory of drive
      if( substr(drive,1,2)=='\\' ) {
         cwd=drive;
      } else {
         cwd=getcwd(drive);
      }
      #if 1
      temp := cwd;
      _maybe_append_filesep(temp);
      temp :+= ALLFILES_RE;
      typeless isdir=isdirectory(_maybe_quote_filename(cwd),1);
      if( (isdir=="" || isdir=="0") && file_match('+d '_maybe_quote_filename(temp),1)=="" ) {
      #else
      _str temp=cwd;
      if( last_char(temp)!=FILESEP ) temp=temp:+FILESEP;
      temp :+= ALLFILES_RE;
      if( file_match('+d '_maybe_quote_filename(temp),1)=="" ) {
      #endif
         // This path no longer exists
         ftpDisplayError("The following directory does not exist:\n\n":+cwd);
         // Try to change back to the old directory
         temp=fcp_p->localCwd;
         _maybe_append_filesep(temp);
         temp :+= ALLFILES_RE;
         if( file_match('+d '_maybe_quote_filename(temp),1)=="" ) {
            // Wow! The old directory no longer exists
            cwd=getcwd();
         } else {
            cwd=fcp_p->localCwd;
         }
         if( substr(cwd,1,2)=='\\' ) {
            _str root, share;
            parse cwd with '\\' root '\' share '\' .;
            drive='\\':+root:+'\':+share;
         } else {
            parse cwd with drive ':' .;
            drive=lowcase(drive):+':';
         }
         _ftpclientChangeDrvListOnOff(0);
         _lbfind_and_select_item(drive);
         _ftpclientChangeDrvListOnOff(1);
         drive=_lbget_text();
         if( substr(drive,1,2)!='\\' ) {
            drive=substr(drive,1,1);   // Just the drive letter
         }
         cwd=getcwd(drive);
      }
      _str old_LocalCWD=fcp_p->localCwd;
      LOCALCWD=cwd;
      fcp_p->localCwd=cwd;
      if( _UpdateLocalSession() ) {
         LOCALCWD=old_LocalCWD;
         fcp_p->localCwd=old_LocalCWD;
      }
   }
}

void _ctl_local_cwd.on_change(int reason)
{
   FtpConnProfile *fcp_p;
   FtpConnProfile fake;   // Used when there is no current connection

   if( !_ftpclientChangeLocalCwdOnOff() ) {
      return;
   }
   if( reason==CHANGE_OTHER ) {
      // User probably typing in a new directory
      return;
   }

   cwd := "";
   old_LocalCWD := "";
   fcp_p=GetCurrentConnProfile();
   if( !fcp_p ) {
      _ftpInitConnProfile(fake);
      fake.localFileFilter=LOCALFILTER;
      fcp_p=&fake;
      old_LocalCWD=LOCALCWD;
      if( old_LocalCWD=="" ) {
         // This should never happen
         old_LocalCWD=getcwd();
      }
      cwd=p_text;
      if( cwd=="" ) {
         // This should never happen
         cwd=old_LocalCWD;
      }
   } else {
      old_LocalCWD=fcp_p->localCwd;
      if( old_LocalCWD=="" ) {
         // This should never happen
         old_LocalCWD=getcwd();
      }
      cwd=p_text;
      if( cwd=="" ) {
         // This should never happen
         cwd=old_LocalCWD;
      }
   }
   temp := cwd;
   _maybe_append_filesep(temp);
   temp :+= ALLFILES_RE;
   if( file_match('+d '_maybe_quote_filename(temp),1)=="" ) {
      // This path no longer exists
      cwd=getcwd();
   }
   LOCALCWD=cwd;
   fcp_p->localCwd=cwd;
   if( _UpdateLocalSession() ) {
      LOCALCWD=old_LocalCWD;
      fcp_p->localCwd=old_LocalCWD;
   }
}

void _ctl_local_cwd.'ENTER'()
{
   _ctl_local_cwd.call_event(CHANGE_PATH,_ctl_local_cwd,ON_CHANGE,'w');
}

void _ctl_local_dir.lbutton_double_click(_str filename="")
{
   FtpConnProfile *fcp_p;
   FtpConnProfile fake;   // Used when there is no connection
   cwd := "";
   orig_cwd := "";

   fcp_p=GetCurrentConnProfile();
   if( !fcp_p ) {
      // There is currently no connection, so make a fake connection profile
      cwd=LOCALCWD;
      if( cwd=="" ) {
         cwd=getcwd();
      }
      _ftpInitConnProfile(fake);
      fake.localCwd=cwd;
      fake.localFileFilter=LOCALFILTER;
      fcp_p=&fake;
   }

   idx := 0;
   path := "";
   server := "";
   sharename := "";

   if( filename=="" ) {
      // Current item in tree
      idx=_TreeCurIndex();
      caption := _TreeGetCaption(idx);
      parse caption with filename "\t" .;
   }

   filename=strip(filename);
   if( filename==".." ) {
      cwd=fcp_p->localCwd;
      _maybe_append_filesep(cwd);
      cwd :+= "..";
      orig_cwd=cwd;
      cwd=isdirectory(_maybe_quote_filename(cwd),1);   // Resolve
      if( (cwd=="" || cwd=="0") && isuncdirectory(orig_cwd) ) {
         cwd=orig_cwd;
         parse cwd with '\\' server '\' sharename '\' path '\..';
         path=substr(path,1,lastpos('\',path,1,'e')-1);   // Strip off 1 directory
         cwd='\\':+server:+'\':+sharename:+'\':+path;
      }
      if( cwd=="" ) {
         // The current working directory might be really messed up, so
         // fix it now.
         cwd = getcwd();
         ftpDisplayError("Unable to change the local working directory to:\n\n":+
                         orig_cwd:+"\n\nThe new local working directory is:\n\n":+
                         cwd);
      }
      _str old_LocalCWD=fcp_p->localCwd;
      fcp_p->localCwd=cwd;
      LOCALCWD=cwd;
      mou_hour_glass(true);
      if( _UpdateLocalSession() ) {
         LOCALCWD=old_LocalCWD;
         fcp_p->localCwd=old_LocalCWD;
      }
   } else {
      int flags = _ftpTreeItemUserInfo2TypeFlags(idx);
      if ( !testFlag(flags, FTPFILETYPE_DIR) ) {
         // We have a file so transfer it.
         // Note that ftpclientUpload() will take care of all
         // asynchronous operations.
         ftpclientUpload();
      } else if ( testFlag(flags, FTPFILETYPE_DIR) ) {
         // We have a directory so change to it
         cwd=fcp_p->localCwd;
         _maybe_append_filesep(cwd);
         cwd :+= filename;
         orig_cwd=cwd;
         cwd=isdirectory(_maybe_quote_filename(cwd),1);   // Resolve
         if( (cwd=="" || cwd=="0") && isuncdirectory(orig_cwd) ) {
            cwd=orig_cwd;
            parse cwd with '\\' server '\' sharename '\' path '\..';
            path=substr(path,1,lastpos('\',path,1,'e')-1);   // Strip off 1 directory
            cwd='\\':+server:+'\':+sharename:+'\':+path;
         }
         if( cwd=="" ) {
            // The current working directory might be really messed up, so
            // fix it now.
            cwd = getcwd();
            ftpDisplayError("Unable to change the local working directory to:\n\n":+
                            orig_cwd:+"\n\nThe new local working directory is:\n\n":+
                            cwd);
         }
         _str old_LocalCWD=fcp_p->localCwd;
         LOCALCWD=cwd;
         fcp_p->localCwd=cwd;
         mou_hour_glass(true);
         if( _UpdateLocalSession() ) {
            LOCALCWD=old_LocalCWD;
            fcp_p->localCwd=old_LocalCWD;
         }
      }
   }
}

void _ctl_local_dir.'BACKSPACE'()
{
   _ctl_local_dir.call_event("..",_ctl_local_dir,LBUTTON_DOUBLE_CLICK,'W');
}

// This expects the active window to be a combo box
void _ftpclientFillCwdHistory(bool set_textbox)
{
   FtpConnProfile *fcp_p = GetCurrentConnProfile();
   if( !fcp_p ) {
      // This should never happen
      return;
   }

   _ftpclientChangeRemoteCwdOnOff(0);
   cwd := p_text;
   _lbclear();
   int i, n=fcp_p->cwdHist._length();
   for( i=n-1; i >= 0; --i ) {
      _lbadd_item(fcp_p->cwdHist[i]);
   }
   if( p_Noflines ) {
      if( set_textbox ) {
         // Top item is MRU
         _lbtop();
         _lbselect_line();
         p_text = _lbget_seltext();
      } else if( cwd != '' ) {
         // We get here when history has been added/removed
         // from the list, but we do not want the current item
         // selected to change.
          _lbfind_and_select_item(cwd,_ftpFileCase(fcp_p));
      }
   }
   _ftpclientChangeRemoteCwdOnOff(1);
}

void _ftpCwdHistoryAddRemove_ftpclient(typeless fromFormWid)
{
   formWid := _ftpclientQFormWid();
   if( !formWid ) {
      return;
   }
   wid := formWid._find_control('_ctl_remote_cwd');
   wid._ftpclientFillCwdHistory(false);
}

void _ctl_remote_cwd.on_change(int reason)
{
   FtpConnProfile *fcp_p;
   FtpConnProfile fcp;

   if( !_ftpclientChangeRemoteCwdOnOff() ) {
      return;
   }
   if( reason==CHANGE_OTHER ) {
      // User probably typing in a new directory
      return;
   }

   fcp_p=GetCurrentConnProfile();
   if( !fcp_p ) {
      // This should never happen
      return;
   }

   _str old_RemoteCWD=fcp_p->remoteCwd;
   if( old_RemoteCWD=="" ) {
      // This should never happen
      old_RemoteCWD='/';
   }
   cwd := p_text;
   if( cwd=="" ) {
      // This should never happen
      cwd=old_RemoteCWD;
   }
   if( fcp_p->system==FTPSYST_MVS ) {
      if( substr(cwd,1,1)!='/' ) {
         // Make it absolute for MVS
         cwd="'":+cwd:+"'";
      }
   }
   os400_lfs := false;
   if( fcp_p->system==FTPSYST_OS400 ) {
      if( substr(fcp_p->remoteCwd,1,1)=='/' && substr(cwd,1,1)!='/' ) {
         os400_lfs=true;
      }
   }
   ftpclientChangeRemoteDir(cwd,os400_lfs);
}

void _ctl_remote_cwd.'ENTER'()
{
   _ctl_remote_cwd.call_event(CHANGE_PATH,_ctl_remote_cwd,ON_CHANGE,'w');
}

void __ftpclientChangeDirCB( FtpQEvent *pEvent, _str action="", typeless isLink="" )
{
   FtpQEvent event;
   FtpConnProfile fcp;
   FtpConnProfile *fcp_p;
   int formWid;

   formWid=_ftpclientQFormWid();
   if( 0==formWid ) {
      // This should never happen
      return;
   }

   event= *((FtpQEvent *)(pEvent));
   fcp=event.fcp;
   //message("event.fcp.RemoteCWD="event.fcp.RemoteCWD);

   action= upcase(action);   // Action word is always last
   if( action!="CDUP" && action!="CWD" ) {
      // This should never happen
      ftpDisplayError('Invalid action: "':+action:+'"');
      return;
   }

   is_link := ( isLink!="" && isLink );

   if( _ftpQEventIsError(event) ) {
      if( action=="CWD" && is_link &&
          (fcp.system==FTPSYST_UNIX || (fcp.system==FTPSYST_MVS && substr(fcp.remoteCwd,1,1)=='/')) ) {
         // The symbolic link is not a directory, so try to open as file instead
         ftpclientDownloadLinks();
         return;
      }
      // An error occurred with CWD.
      // The CWD handler was silent for the error, since it did not know
      // whether we were trying to process a link, so show the error message
      // now.
      _ftpQEventDisplayError(event);
      // Fix things up in case the user had typed a bogus path and hit ENTER
      formWid._UpdateRemoteSession(false);
      return;
   }

   if( !_ftpQEventIsError(event) && !_ftpQEventIsAbort(event) ) {
      // Find the matching connection profile in current connections
      // so we can update its stored remote current working directory.
      fcp_p=null;
      typeless i;
      for( i._makeempty();; ) {
         _ftpCurrentConnections._nextel(i);
         if( i._isempty() ) break;
         FtpConnProfile currentconn=_ftpCurrentConnections:[i];
         if( _ftpCurrentConnections:[i].profileName==fcp.profileName &&
             _ftpCurrentConnections:[i].instance==fcp.instance ) {
            // Found it
            fcp_p= &(_ftpCurrentConnections:[i]);
            break;
         }
      }
      if( !fcp_p ) {
         // We didn't find the matching connection profile, so bail out
         return;
      }
      fcp_p->remoteCwd=fcp.remoteCwd;

      // _UpdateRemoteSession() already handles asynchronous operations
      formWid._UpdateRemoteSession(true);
      return;
   }
}
void __ftpclientCdupCB(FtpQEvent *pEvent)
{
   __ftpclientChangeDirCB(pEvent,"CDUP");
}
void __ftpclientCwdCB(FtpQEvent *pEvent)
{
   __ftpclientChangeDirCB(pEvent,"CWD");
}
void __ftpclientCwdLinkCB(FtpQEvent *pEvent)
{
   __ftpclientChangeDirCB(pEvent,"CWD",true);
}

void _ctl_remote_dir.lbutton_double_click(_str filename="")
{
   FtpConnProfile *fcp_p;
   FtpConnProfile fcp;

   fcp_p=GetCurrentConnProfile();
   if( !fcp_p ) return;   // This should never happen

   idx := 0;
   if( filename=="" ) {
      // Current item in tree
      idx=_TreeCurIndex();
      caption := _TreeGetCaption(idx);
      parse caption with filename "\t" .;
   }
   fcp= *fcp_p;   // Make a copy
   fcp.postedCb=null;
   if( filename==".." ) {
      if( fcp.system==FTPSYST_VXWORKS ) {
         // Special case of a VxWorks host that does not support the
         // CDUP command (the only host that we know of).
         fcp.postedCb=(typeless)__ftpclientCwdCB;
         filename=fcp.remoteCwd;
         filename=strip(filename);   // Just in case
         if( filename!='/' ) {
            // Strip off the trailing '/'
            _maybe_strip(filename, '/');
            i := lastpos('/',filename);
            if( i ) {
               filename=substr(filename,1,i);
               if( filename!='/' ) {
                  // Strip off the trailing '/'
                  filename=substr(filename,1,length(filename)-1);
               }
            }
         }
         ftpclientChangeRemoteDir(filename);
         //_ftpSyncEnQ(QE_CWD,QS_BEGIN,0,&fcp,filename);
      } else {
         if( fcp.serverType==FTPSERVERTYPE_SFTP ) {
            // SFTP servers have no concept of a current working directory,
            // so we have to maintain one. Let the server resolve it.
            filename=fcp.remoteCwd;
            _maybe_append(filename, '/');
            filename :+= '..';
            ftpclientChangeRemoteDir(filename);
         } else {
            // FTP
            ftpclientChangeRemoteDir(filename);
            //fcp.PostedCB=(typeless)__ftpclientCdupCB;
            //_ftpSyncEnQ(QE_CDUP,QS_BEGIN,0,&fcp);
         }
      }
      return;
   } else {
      int flags = _ftpTreeItemUserInfo2TypeFlags(idx);
      if ( !testFlag(flags, FTPFILETYPE_DIR) ) {
         // We have a file so transfer it.
         // Note that ftpclientDownload() will take care of asynchronous
         // operations.
         ftpclientDownload();
      } else if ( testFlag(flags, FTPFILETYPE_DIR) ) {
         // We have a directory so CWD to it
         if( (fcp.system == FTPSYST_UNIX || (fcp.system==FTPSYST_MVS && substr(fcp. remoteCwd, 1, 1) == '/')) 
             && testFlag(flags, FTPFILETYPE_LINK) ) {

            // Get rid of the link part
            parse filename with filename '->' .;
            filename = strip(filename);
         }
         is_link := testFlag(flags, FTPFILETYPE_LINK);
         ftpclientChangeRemoteDir(filename, 0, is_link);
         //fcp.PostedCB=__ftpclientCwdCB;
         //_ftpSyncEnQ(QE_CWD,QS_BEGIN,0,&fcp,filename);
         return;
      }
   }
}

void _ctl_remote_dir.'BACKSPACE'()
{
   _ctl_remote_dir.call_event("..",_ctl_remote_dir,LBUTTON_DOUBLE_CLICK,'W');
}

static void getNewSSTabWH(typeless &ht,int formWid,int sstWid,int &sstabW,
                          int &sstabH)
{
   // Want same gap on left and right
   sstabW=_dx2lx(SM_TWIP,formWid.p_client_width)-2*sstWid.p_x;
   // Adjust height to account for controls on top
   int vgap=_dy2ly(SM_TWIP,4);
   sstabH=_dy2ly(SM_TWIP,formWid.p_client_height)-sstWid.p_y-vgap;
}

static void onresizeTabControl(typeless &ht)
{
   int sstabW,sstabH;
   getNewSSTabWH(ht,p_active_form,p_window_id,sstabW,sstabH);
   p_width=sstabW;
   p_height=sstabH;

   // resize toolbar buttons if necessary (allow 33% larger)
   _ctl_profile.p_y = 60;
   max_button_height := max(_ctl_profile.p_y_extent, 2*(_ctl_progress_label1.p_y_extent));
   max_button_height += (max_button_height intdiv 3);
   _ctl_connect.resizeToolButton(max_button_height);
   _ctl_disconnect.resizeToolButton(max_button_height);
   _ctl_ascii.resizeToolButton(max_button_height);
   _ctl_binary.resizeToolButton(max_button_height);
   _ctl_abort.resizeToolButton(max_button_height);
   _ctl_profile.p_y = max((max_button_height - _ctl_profile.p_height) intdiv 2, _ctl_profile.p_y);

   // Position the lefmost buttons
   space_x := _dx2lx(SM_TWIP, def_toolbar_pic_hspace);
   alignControlsHorizontal(_ctl_connect.p_x,
                           0,
                           _dy2ly(SM_TWIP,1),
                           _ctl_connect.p_window_id,
                           _ctl_disconnect.p_window_id,
                           _ctl_divider1.p_window_id,
                           _ctl_ascii.p_window_id,
                           _ctl_binary.p_window_id,
                           _ctl_divider2.p_window_id);

   _ctl_group1.p_height=_ctl_divider1.p_height+_dy2ly(SM_TWIP,4);
   _ctl_group1.p_width=_ctl_binary.p_x_extent+_dx2lx(SM_TWIP,4);

   // Position the tab control
   int tab_y = _ctl_connect.p_y_extent+_dy2ly(SM_TWIP,4);
   int prog_y = _ctl_progress_label2.p_y_extent+_dy2ly(SM_TWIP,2);
   int stop_y = _ctl_abort.p_y_extent + +_dy2ly(SM_TWIP,2);
   if (prog_y > tab_y) tab_y = prog_y;
   if (stop_y > tab_y) tab_y = stop_y;
   _ctl_ftp_sstab.p_y = tab_y;

   // Position the rightmost controls
   _ctl_progress.p_visible=false;
   _ctl_progress_label1.p_visible=false;
   _ctl_progress_label2.p_visible=false;

   // Abort button
   int new_x=(p_x+p_width)-_ctl_abort.p_width-_dx2lx(SM_TWIP,3);
   _ctl_abort.p_x=new_x;

   // Progress gauge
   new_x=_ctl_abort.p_x-_ctl_progress.p_width-_dx2lx(SM_TWIP,4);
   _ctl_progress.p_x=new_x;

   // Byte count label
   int new_width= _ctl_progress.p_x-(_ctl_group1.p_x_extent)-2*_dx2lx(SM_TWIP,4);
   if( new_width<0 ) new_width=0;
   new_x=_ctl_group1.p_x_extent+_dx2lx(SM_TWIP,4);
   _ctl_progress_label2.p_x=new_x;
   _ctl_progress_label2.p_width=new_width;

   // Operation label
   new_width=_ctl_abort.p_x-(_ctl_group1.p_x_extent)-2*_dx2lx(SM_TWIP,4);
   if( new_width<0 ) new_width=0;
   new_x=_ctl_group1.p_x_extent+_dx2lx(SM_TWIP,4);
   _ctl_progress_label1.p_x=new_x;
   _ctl_progress_label1.p_width=new_width;

   _ctl_progress.p_visible=true;
   _ctl_progress_label1.p_visible=true;
   _ctl_progress_label2.p_visible=true;
}

static void onresizeDirTab(typeless &ht)
{
   int new_x,new_y,new_width,new_height;

   if( p_ActiveTab!=FTPTOOLTAB_DIR ) return;
   int containerW = p_child.p_width;
   int containerH = p_child.p_height;

   // Resize horizontal postion and widths
   // Gap between the outer edges of the directory lists and the left/right edge of the "Dir" tab
   int lgap=_ctl_local_dir.p_x+1;
   int rgap=lgap;
   // Gap between the local and remote directory lists
   int mgap=_dx2lx(SM_TWIP,6);
   // First take care of the local directory
   new_width = (containerW intdiv 2) - lgap - (mgap intdiv 2);
   _ctl_local_dir.p_width=new_width;
   // Now the local cwd combo box width
   if (_isUnix()) {
      // Unix does not have drives, so we don't need the drive list
      _ctl_local_drvlist.p_visible=false;   // Paranoid
      _ctl_local_cwd.p_x=_ctl_local_dir.p_x;
      _ctl_local_cwd.p_width=_ctl_local_dir.p_width;
   } else {
      _ctl_local_cwd.p_width=new_width-(_ctl_local_cwd.p_x-_ctl_local_drvlist.p_x);
   }
   // Now the remote directory
   _ctl_remote_dir.p_width=new_width;
   new_x = (containerW intdiv 2) - 1 + (mgap intdiv 2);
   _ctl_remote_dir.p_x=new_x;
   // Now the remote cwd combo box x and width
   _ctl_remote_cwd.p_x=_ctl_remote_dir.p_x;
   _ctl_remote_cwd.p_width=_ctl_remote_dir.p_width;

   // Resize height
   int vgap=_ctl_local_dir.p_y-(_ctl_local_drvlist.p_y_extent-1);
   new_height=containerH-_ctl_local_dir.p_y-vgap;
   _ctl_local_dir.p_height=new_height;
   _ctl_remote_dir.p_height=new_height;

   // Center the "(No connection)" message that is normally obscured behind the remote directory list
   new_x= _ctl_remote_dir.p_x + (_ctl_remote_dir.p_width-_ctl_no_connection.p_width) intdiv 2;
   _ctl_no_connection.p_x=new_x;
   new_y= (containerH-_ctl_no_connection.p_height) intdiv 2;
   _ctl_no_connection.p_y=new_y;
}

static void onresizeLogTab(typeless &ht)
{
   int new_x,new_y,new_width,new_height;

   if( p_ActiveTab!=FTPTOOLTAB_LOG ) return;
   int containerW = p_child.p_width;
   int containerH = p_child.p_height;

   // Resize width
   new_width=containerW-2*_ctl_log.p_x;
   _ctl_log.p_width=new_width;

   // Resize height
   //new_height=containterH - _ctl_log.p_y - _ctl_log.p_x;
   new_height=containerH-_ctl_log.p_y-_ctl_log.p_x;
   _ctl_log.p_height=new_height;

   // Center the "(No log)" message that is normally obscured behind the log
   new_x= (containerW-_ctl_no_log.p_width) intdiv 2;
   _ctl_no_log.p_x=new_x;
   new_y= (containerH-_ctl_no_log.p_height) intdiv 2;
   _ctl_no_log.p_y=new_y;
}

void _tbFTPClient_form.on_resize()
{
   typeless lastW,lastH;
   typeless ht:[];
   _str info;
   int old_wid;

   //TODO: Fix treeselect calls for client.

   _ctl_ftp_sstab.onresizeTabControl(ht);
   _ctl_ftp_sstab.onresizeDirTab(ht);
   _ctl_ftp_sstab.onresizeLogTab(ht);
}

static bool _busy_override=false;
/** Gets called when the queue is processing events. */
void _ftpQBusy_ftpclient()
{
   if( _busy_override ) return;

   _enable_ftpclient(false);
}

static bool _idle_override=false;
/** Gets called when the queue is idle. */
void _ftpQIdle_ftpclient()
{
   if( _idle_override ) return;

   _enable_ftpclient(true);
}

static void _enable_children(int parent,bool enable)
{
   int firstwid,wid;

   if( !parent ) return;

   firstwid=parent.p_child;
   if( !firstwid ) return;
   wid=firstwid;
   for(;;) {
      if( wid.p_object!=OI_FORM &&   /* Don't mess with child forms that are modal */
          wid.p_name!="_ctl_abort" ) {
         if( enable ) {
            if( wid.p_mouse_pointer!=MP_DEFAULT ) wid.p_mouse_pointer=MP_DEFAULT;
         } else {
            if( wid.p_mouse_pointer!=MP_HOUR_GLASS ) wid.p_mouse_pointer=MP_HOUR_GLASS;
         }
      }
      if( wid.p_object!=OI_FORM &&   /* Don't want to enable child forms that are modal */
          wid.p_name!="_ctl_abort" && wid.p_name!="_ctl_ftp_sstab" &&
          wid.p_name!="_ctl_progress_label1" && wid.p_name!="_ctl_progress_label2" &&
          wid.p_name!="_ctl_progress" && wid.p_name!="_ctl_log" &&
          wid.p_object!=OI_HSCROLL_BAR && wid.p_object!=OI_VSCROLL_BAR ) {
         if( wid.p_enabled!=enable ) wid.p_enabled=enable;
      }
      // This allows user to view log while an operation is in progress
      if( wid.p_object!=OI_FORM &&   /* Don't mess with child forms that are modal */
          wid.p_name!="_ctl_log" && wid.p_object!=OI_HSCROLL_BAR && wid.p_object!=OI_VSCROLL_BAR ) {
         _enable_children(wid,enable);
      }
      wid=wid.p_next;
      if( wid==firstwid ) break;
   }
}

static void _enable_ftpclient(bool enable)
{
   int formWid;

   formWid=_ftpclientQFormWid();
   if( !formWid ) return;

   // We have to set p_mouse_pointer for the form for this to
   // work reliably. Should not have to do this though.
   if( enable ) {
      formWid.p_mouse_pointer=MP_DEFAULT;
   } else {
      formWid.p_mouse_pointer=MP_HOUR_GLASS;
   }
   _enable_children(formWid,enable);

   sstabWid := formWid._find_control("_ctl_ftp_sstab");
   //if( sstabWid ) sstabWid.p_enabled=enable;
   profileWid := formWid._find_control("_ctl_profile");
   //if( profileWid ) profileWid.p_enabled=enable;
   groupWid := formWid._find_control("_ctl_group1");
   if( groupWid ) {
      if( enable ) {
         label1Wid := formWid._find_control("_ctl_progress_label1");
         label2Wid := formWid._find_control("_ctl_progress_label2");
         gaugeWid := formWid._find_control("_ctl_progress");
         if( label1Wid && label2Wid && gaugeWid && groupWid ) {
            // Shrink/position the labels so it does not overlap _ctl_group1
            label1Wid.p_x=groupWid.p_x_extent+_dx2lx(SM_TWIP,4);
            label1Wid.p_width= (gaugeWid.p_x_extent-1)-label1Wid.p_x;
            label2Wid.p_x=label1Wid.p_x;
            label2Wid.p_width=gaugeWid.p_x-label2Wid.p_x-_dx2lx(SM_TWIP,4);
         }
      }
      groupWid.p_visible=enable;
   }
}

