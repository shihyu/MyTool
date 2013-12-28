////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47587 $
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
#include "ftp.sh"
#include "eclipse.sh"
#import "files.e"
#import "ftp.e"
#import "ftpparse.e"
#import "ftpq.e"
#import "guiopen.e"
#import "last.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tbcmds.e"
#import "toolbar.e"
#import "treeview.e"
#import "eclipse.e"
#import "util.e"
#endregion

#define FTPTOOLTAB_DIR (0)
#define FTPTOOLTAB_LOG (1)

static boolean gchangeprofile_allowed=true;

int _ftpopenQFormWid()
{
   int formWid;
   if (isEclipsePlugin()) {
      formWid = _find_object(ECLIPSE_FTPOPEN_CONTAINERFORM_NAME,'n');
      if (formWid > 0) {
         formWid = formWid.p_child;
      }
   } else {
      formWid=_find_object(TBFTPOPEN_FORM_NAME,'n');
   }
   return formWid;
}

boolean _ftpopenChangeProfileOnOff( _str onoff="" )
{
   if( onoff != "" ) {
      gchangeprofile_allowed=(onoff!="0");
   }

   return(gchangeprofile_allowed);
}

static boolean gchangeremotecwd_allowed=true;
boolean _ftpopenChangeRemoteCwdOnOff( _str onoff="" )
{
   if( onoff != "" ) {
      gchangeremotecwd_allowed=(onoff!="0");;
   }

   return(gchangeremotecwd_allowed);
}

static boolean gchangeremotedir_allowed=true;
boolean _ftpopenChangeRemoteDirOnOff( _str onoff="" )
{
   if( onoff != "" ) {
      gchangeremotedir_allowed=(onoff!="0");;
   }

   return(gchangeremotedir_allowed);
}

defeventtab _tbFTPOpen_form;

_tbFTPOpen_form.'F12'()
{
   if (isEclipsePlugin()) {
      eclipse_activate_editor();
   } else if (def_keys == 'eclipse-keys') {
      activate_editor();
   }
}

_tbFTPOpen_form.'C-M'()
{
   if (isEclipsePlugin()) {
      eclipse_maximize_part();
   }
}

// This expects the active window to be a combo box
void _ftpopenFillProfiles(boolean set_textbox)
{
   boolean oldchangeprofile_allowed=_ftpopenChangeProfileOnOff();
   _ftpopenChangeProfileOnOff(0);
   _str profile_name = p_text;
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
         _lbfind_and_select_item(profile_name,'i');
      }
   }
   _ftpopenChangeProfileOnOff(oldchangeprofile_allowed);

   return;
}

static void oncreateFTPOpen()
{
   // Current connections
   _ftpopenChangeProfileOnOff(0);
   _ctl_profile.p_text="";
   _ctl_profile._ftpopenFillProfiles(true);
   typeless profile=_ctl_profile._retrieve_value();
   _ctl_profile._lbfind_and_select_item(profile);
   _ftpopenChangeProfileOnOff(1);

   // Remote session
   _ctl_remote_dir.p_multi_select=MS_EXTENDED;
   _ctl_remote_dir.p_visible=false;
   _ctl_remote_cwd.p_visible=false;
   _ctl_no_connection.p_visible=true;

   _ctl_operation.p_caption="";
   _ctl_nofbytes.p_caption="";

   // Horizontal scroll bars
   typeless val=_retrieve_value("_tbFTPOpen_form._ctl_remote_dir.p_scroll_bars");
   if( !isinteger(val) || val<SB_NONE || val>SB_BOTH ) val=SB_BOTH;
   _ctl_remote_dir.p_scroll_bars= (int)val;
   if( (_ctl_remote_dir.p_scroll_bars)&SB_HORIZONTAL ) {
      _ctl_remote_dir.p_delay= -1;
   } else {
      _ctl_remote_dir.p_delay= 0;
   }
}

void _ctl_profile.on_create()
{
   oncreateFTPOpen();
   _ctl_profile.call_event(CHANGE_SELECTED,_ctl_profile,ON_CHANGE,'W');
}

void _ctl_profile.on_destroy()
{
   // Remember the active profile
   _append_retrieve(_ctl_profile,_ctl_profile.p_text);

   // Remember horizontal scroll bar settings
   _append_retrieve(0,_ctl_remote_dir.p_scroll_bars,"_tbFTPOpen_form._ctl_remote_dir.p_scroll_bars");

   return;
}

/**
 * Resize the controls in the FTP tab.
 * Used by the plugin to resize the FTP tab
 * @param availW available width
 * @param availH available height
 */
void resizeFTPTabControls(int availW, int availH)
{
   onresizeFTPOpen();
   int new_width,new_height,new_x,new_y;
   int containerW = availW;
   int containerH = availH;

   #if 1
   int progress_height= _dy2ly(SM_TWIP,4)+_ctl_bottom_divider.p_height+_dy2ly(SM_TWIP,4)+_ctl_operation.p_height+_dy2ly(SM_TWIP,4)+_ctl_nofbytes.p_height+_dy2ly(SM_TWIP,4);
   #else
   int progress_height= _dy2ly(SM_TWIP,4)+_ctl_bottom_divider.p_height+_dy2ly(SM_TWIP,4)+_ctl_operation.p_height+_dy2ly(SM_TWIP,4)+_ctl_progress.p_height+_ctl_nofbytes.p_height+_dy2ly(SM_TWIP,8);
   #endif

   // Picture group
   _ctl_group.p_width=containerW;
   _ctl_group.p_height=containerH-progress_height;

   // Width
   new_width=containerW-2*_ctl_profile.p_x-_dy2ly(SM_TWIP,2);
   _ctl_profile.p_width=new_width;
   _ctl_remote_cwd.p_width=new_width;
   _ctl_remote_dir.p_width=new_width;

   // Height
   new_height=containerH-_ctl_remote_dir.p_y-progress_height;
   _ctl_remote_dir.p_height=new_height;
   _ctl_remote_cwd.p_y = _ctl_connect.p_y+_ctl_connect.p_height+_dy2ly(SM_TWIP,4);
   _ctl_remote_dir.p_y = _ctl_remote_cwd.p_y+_ctl_remote_cwd.p_height+_dy2ly(SM_TWIP,4);

   // Bitmap buttons and divider
   _ctl_disconnect.p_x= _ctl_connect.p_x+_ctl_connect.p_width+_dx2lx(SM_TWIP,4);
   _ctl_divider1.p_x= _ctl_disconnect.p_x+_ctl_disconnect.p_width+_dx2lx(SM_TWIP,4);
   _ctl_divider1.p_height=_ctl_disconnect.p_height;
   _ctl_ascii.p_x= _ctl_divider1.p_x+_ctl_divider1.p_width+_dx2lx(SM_TWIP,4);
   _ctl_binary.p_x= _ctl_ascii.p_x+_ctl_ascii.p_width+_dx2lx(SM_TWIP,2);

   // Center the "(No connection)" caption
   new_x= (containerW-_ctl_no_connection.p_width)/2;
   new_y= _ctl_remote_cwd.p_y + ((_ctl_remote_dir.p_y+new_height) - _ctl_remote_cwd.p_y)/2;
   _ctl_no_connection.p_x=new_x;
   _ctl_no_connection.p_y=new_y;

   // Bottom controls
   _ctl_bottom_divider.p_y=_ctl_group.p_y+_ctl_group.p_height+_dy2ly(SM_TWIP,4);
   _ctl_bottom_divider.p_width=containerW-2*_dx2lx(SM_TWIP,4);

   #if 1
   _ctl_operation.p_y=_ctl_bottom_divider.p_y+_ctl_bottom_divider.p_height+_dy2ly(SM_TWIP,4);
   _ctl_nofbytes.p_y=_ctl_operation.p_y+_ctl_operation.p_height+_dy2ly(SM_TWIP,4);
   new_width=containerW-2*_ctl_operation.p_x - _dx2lx(SM_TWIP,4) - _ctl_abort.p_width;
   _ctl_operation.p_width=new_width;
   _ctl_nofbytes.p_width=new_width;
   #else
   _ctl_operation.p_y=_ctl_bottom_divider.p_y+_ctl_bottom_divider.p_height+_dy2ly(SM_TWIP,4);
   _ctl_progress.p_y=_ctl_operation.p_y+_ctl_operation.p_height+_dy2ly(SM_TWIP,4);
   _ctl_nofbytes.p_y=_ctl_progress.p_y+_ctl_progress.p_height;
   new_width=containerW-2*_ctl_progress.p_x - _dx2lx(SM_TWIP,4) - _ctl_abort.p_width;
   _ctl_operation.p_width=new_width;
   _ctl_progress.p_width=new_width;
   _ctl_nofbytes.p_width=new_width;
   #endif

   new_x=_ctl_operation.p_x+new_width+_dx2lx(SM_TWIP,4);
   _ctl_abort.p_x=new_x;
   _ctl_abort.p_y=_ctl_bottom_divider.p_y+_ctl_bottom_divider.p_height;
}

static void onresizeFTPOpen(int availW= -1, int availH= -1)
{
   int new_width,new_height,new_x,new_y,old_wid;
   int containerW, containerH;
   if (isEclipsePlugin()) {
      int ftpContainer = _ftpopenQFormWid();
      if(!ftpContainer) return;
      old_wid = p_window_id;
      p_window_id = ftpContainer;
      eclipse_resizeContainer(ftpContainer);
      containerW  = ftpContainer.p_parent.p_width;
      containerH  = ftpContainer.p_parent.p_height;
   } else {
      if( availW<0 || availH<0 ) {
         containerW=_dx2lx(p_active_form.p_xyscale_mode,p_active_form.p_client_width);
         containerH=_dy2ly(p_active_form.p_xyscale_mode,p_active_form.p_client_height);
      } else {
         containerW=availW;
         containerH=availH;
      }
   }

   #if 1
   int progress_height= _dy2ly(SM_TWIP,4)+_ctl_bottom_divider.p_height+_dy2ly(SM_TWIP,4)+_ctl_operation.p_height+_dy2ly(SM_TWIP,4)+_ctl_nofbytes.p_height+_dy2ly(SM_TWIP,4);
   #else
   int progress_height= _dy2ly(SM_TWIP,4)+_ctl_bottom_divider.p_height+_dy2ly(SM_TWIP,4)+_ctl_operation.p_height+_dy2ly(SM_TWIP,4)+_ctl_progress.p_height+_ctl_nofbytes.p_height+_dy2ly(SM_TWIP,8);
   #endif

   // Picture group
   _ctl_group.p_width=containerW;
   _ctl_group.p_height=containerH-progress_height;

   // Width
   new_width=containerW-2*_ctl_profile.p_x-_dy2ly(SM_TWIP,2);
   _ctl_profile.p_width=new_width;
   _ctl_remote_cwd.p_width=new_width;
   _ctl_remote_dir.p_width=new_width;

   // Height
   _ctl_remote_cwd.p_y = _ctl_connect.p_y+_ctl_connect.p_height+_dy2ly(SM_TWIP,4);
   _ctl_remote_dir.p_y = _ctl_remote_cwd.p_y+_ctl_remote_cwd.p_height+_dy2ly(SM_TWIP,4);
   new_height=containerH-_ctl_remote_dir.p_y-progress_height;
   _ctl_remote_dir.p_height=new_height;

   // Bitmap buttons and divider
   _ctl_disconnect.p_x= _ctl_connect.p_x+_ctl_connect.p_width+_dx2lx(SM_TWIP,4);
   _ctl_divider1.p_x= _ctl_disconnect.p_x+_ctl_disconnect.p_width+_dx2lx(SM_TWIP,4);
   _ctl_divider1.p_height=_ctl_disconnect.p_height;
   _ctl_ascii.p_x= _ctl_divider1.p_x+_ctl_divider1.p_width+_dx2lx(SM_TWIP,4);
   _ctl_binary.p_x= _ctl_ascii.p_x+_ctl_ascii.p_width+_dx2lx(SM_TWIP,2);

   // Center the "(No connection)" caption
   new_x= (containerW-_ctl_no_connection.p_width)/2;
   new_y= _ctl_remote_cwd.p_y + ((_ctl_remote_dir.p_y+new_height) - _ctl_remote_cwd.p_y)/2;
   _ctl_no_connection.p_x=new_x;
   _ctl_no_connection.p_y=new_y;

   // Bottom controls
   _ctl_bottom_divider.p_y=_ctl_group.p_y+_ctl_group.p_height+_dy2ly(SM_TWIP,4);
   _ctl_bottom_divider.p_width=containerW-2*_dx2lx(SM_TWIP,4);

   #if 1
   _ctl_operation.p_y=_ctl_bottom_divider.p_y+_ctl_bottom_divider.p_height+_dy2ly(SM_TWIP,4);
   _ctl_nofbytes.p_y=_ctl_operation.p_y+_ctl_operation.p_height+_dy2ly(SM_TWIP,4);
   new_width=containerW-2*_ctl_operation.p_x - _dx2lx(SM_TWIP,4) - _ctl_abort.p_width;
   _ctl_operation.p_width=new_width;
   _ctl_nofbytes.p_width=new_width;
   #else
   _ctl_operation.p_y=_ctl_bottom_divider.p_y+_ctl_bottom_divider.p_height+_dy2ly(SM_TWIP,4);
   _ctl_progress.p_y=_ctl_operation.p_y+_ctl_operation.p_height+_dy2ly(SM_TWIP,4);
   _ctl_nofbytes.p_y=_ctl_progress.p_y+_ctl_progress.p_height;
   new_width=containerW-2*_ctl_progress.p_x - _dx2lx(SM_TWIP,4) - _ctl_abort.p_width;
   _ctl_operation.p_width=new_width;
   _ctl_progress.p_width=new_width;
   _ctl_nofbytes.p_width=new_width;
   #endif

   new_x=_ctl_operation.p_x+new_width+_dx2lx(SM_TWIP,4);
   _ctl_abort.p_x=new_x;
   _ctl_abort.p_y=_ctl_bottom_divider.p_y+_ctl_bottom_divider.p_height;
   if (isEclipsePlugin()) {
      p_window_id = old_wid;
   }
}

void _tbFTPOpen_form.on_resize()
{
   onresizeFTPOpen();
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
static void _ftpopenUpdateButtonBar(FtpConnProfile* fcp_p)
{
   if( !fcp_p ) {
      return;
   }

   int asciiWid = _find_control("_ctl_ascii");
   int binWid = _find_control("_ctl_binary");
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
      boolean visible = ( fcp_p->serverType == FTPSERVERTYPE_FTP );
      asciiWid.p_visible = visible;
      binWid.p_visible = visible;
      int prevWid = asciiWid.p_prev;
      if( prevWid.p_object == OI_IMAGE && prevWid.p_style == PSPIC_TOOLBAR_DIVIDER_VERT ) {
         prevWid.p_visible = visible;
      }
   }
}

// This expects the active window to be a combo box
int _ftpopenChangeProfile(_str profile_name="")
{
   FtpConnProfile *fcp_p;

   boolean oldchangeprofile_allowed=_ftpopenChangeProfileOnOff();
   _ftpopenChangeProfileOnOff(0);
   if ( profile_name == "" ) {
      // Get the profile in the text box
      profile_name=p_text;
   }

   if( profile_name=="" ) {
      // This should only happen when there are no connections
      if( !p_Noflines ) _ftpopenFillProfiles(false);
      if( p_Noflines ) {
         _lbtop();
         profile_name=_lbget_text();
      }
      if( profile_name=="" ) {
         p_text="";
         _ftpopenChangeProfileOnOff(oldchangeprofile_allowed);
         return(0);
      }
   }

   //messageNwait(_ftpCurrentConnections._isempty()'  '_ftpCurrentConnections._indexin(profile_name));
   //messageNwait('profile_name='profile_name);
   if( !_ftpCurrentConnections._indexin(profile_name) ) {
      // Remove this profile from the combo box
      _ftpopenFillProfiles(false);
      _lbtop();
      _lbselect_line();
      p_text=_lbget_seltext();
      profile_name=p_text;
   } else {
      // Always find the profile name in case the user just opened a new connection
      typeless status=_lbfind_and_select_item(profile_name,'i');
      if( status ) {
         // This normally happens when user connects with "Connect..." button
         _ftpopenFillProfiles(false);
         _lbfind_and_select_item(profile_name,'i');
      }
      _lbselect_line();
      p_text=_lbget_seltext();
   }
   fcp_p=_ftpCurrentConnections._indexin(profile_name);
   if( fcp_p ) {
      int formWid = _ftpopenQFormWid();
      _ftpopenUpdateButtonBar(fcp_p);
      if( fcp_p->logBufName=="" ) {
         ftpConnDisplayWarning(fcp_p,'Warning:  Forced to create a log for profile "':+profile_name:+'"');
         _str log_buf_name=_ftpCreateLogBuffer();
         if( log_buf_name=="" ) {
            // _ftpCreateLogBuffer() will take care of error messages to user
            _ftpopenChangeProfileOnOff(oldchangeprofile_allowed);
            return(1);
         }
         fcp_p->logBufName=log_buf_name;
         _ftpLog(fcp_p,"*** Log started on ":+_date():+" at ":+_time('M'));
      }
   }
   _ftpopenChangeProfileOnOff(oldchangeprofile_allowed);

   return(0);
}

//#define isvalid_field_width(w) (isinteger(w) && w>0)
#define FTPDIR_FIELDGAP (300)
/**
 * This expects the active window to be a tree view.
 * Sets up column widths in the directory listing.
 */
static void _RefreshDirFields()
{
   if( _TreeGetDepth(TREE_ROOT_INDEX) ) return;   // Nothing to process

   int filename_width=0;
   int size_width=0;
   int date_width=0;
   int time_width=0;
   int attribs_width=0;
   int idx=_TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   for(;;) {
      _str caption=_TreeGetCaption(idx);
      _str filename, size, date, time, attribs;
      parse caption with filename "\t" size "\t" date "\t" time "\t" attribs;

      // Find the longest widths for each field in the tree
      int width=_text_width(filename);
      if( width>filename_width ) filename_width=width;
      width=_text_width(size);
      if( width>size_width ) size_width=width;
      width=_text_width(date);
      if( width>date_width ) date_width=width;
      width=_text_width(time);
      if( width>time_width ) time_width=width;
      width=_text_width(attribs);
      if( width>attribs_width ) attribs_width=width;

      idx=_TreeGetNextSiblingIndex(idx);
      if(idx<0) break;
   }

   // filename_width must include the width of the file/folder bitmap
   filename_width += 16*_twips_per_pixel_x();

   //say('_RefreshDirFields: filename_width='filename_width);
   //say('_RefreshDirFields: size_width='size_width);
   //say('_RefreshDirFields: date_width='date_width);
   //say('_RefreshDirFields: time_width='time_width);
   //say('_RefreshDirFields: attribs_width='attribs_width);

   // Set column widths, captions
   int flags = -1;
   int state = -1;
   _TreeSetColButtonInfo(0, filename_width+FTPDIR_FIELDGAP, flags, state, 'Name');
   _TreeSetColButtonInfo(1, size_width+FTPDIR_FIELDGAP,     flags, state, 'Size');
   _TreeSetColButtonInfo(2, date_width+FTPDIR_FIELDGAP,     flags, state, 'Date');
   _TreeSetColButtonInfo(3, time_width+FTPDIR_FIELDGAP,     flags, state, 'Time');
   _TreeSetColButtonInfo(4, attribs_width+FTPDIR_FIELDGAP,  flags, state, 'Attributes');
}

/**
 * This expects the active window to be a tree view.
 */
int _ftpopenRefreshDir(FtpConnProfile *fcp_p)
{
   FtpFile files[];

   if( !fcp_p ) return(1);

   // Fill in the file list
   _TreeDelete(TREE_ROOT_INDEX,"C");   // Clear the tree out
   files=fcp_p->remoteDir.files;
   int filename_width=0;
   int size_width=0;
   int date_width=0;
   int time_width=0;
   int attribs_width=0;
   int i;
   for( i=0;i<files._length();++i ) {
      if( files[i].filename=="." || files[i].filename==".." ) {
         continue;
      }
      int picidx=_pic_ftpfile;
      int type=files[i].type;
      if( type&FTPFILETYPE_DIR ) {
         if( type&FTPFILETYPE_LINK ) {
            picidx=_pic_ftplfol;
         } else if( type&FTPFILETYPE_FAKED ) {
            picidx=_pic_ftpfod;
         } else {
            picidx=_pic_ftpfold;
         }
      } else if( type&FTPFILETYPE_LINK ) {
         if( type&FTPFILETYPE_FAKED ) {
            picidx=_pic_ftpfild;
         } else {
            picidx=_pic_ftplfil;
         }
      } else {
         if( type&FTPFILETYPE_FAKED ) {
            picidx=_pic_ftpfild;
         }
      }
      _str filename=files[i].filename;
      int size=files[i].size;
      _str date=files[i].month' 'files[i].day' 'files[i].year;
      _str time=files[i].time;
      _str attribs=files[i].attribs;
      _str caption=filename"\t"size"\t"date"\t"time"\t"attribs;
      // Use this for primary/secondary sort on directories/files
      _str info="";
      if( type&FTPFILETYPE_DIR ) {
         // Directory name
         info=info:+"D";
      } else {
         // File name
         info=info:+"F";
      }
      if( type&FTPFILETYPE_LINK ) {
         info=info:+"L";
      }
      if( type&FTPFILETYPE_FAKED ) {
         info=info:+"T";
      }
      int idx=_TreeAddItem(TREE_ROOT_INDEX,caption,TREE_ADD_AS_CHILD,picidx,picidx,-1,0,info);
   }
   int nidx=0;
   int idx=_TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   if( idx<0 ) {
      // No children, just add ".."
      // Setting userinfo to "0" guarantees it will get to top of tree when sorted
      nidx=_TreeAddItem(TREE_ROOT_INDEX,"..\t\t\t\t",TREE_ADD_AS_CHILD,_pic_ftpcdup,_pic_ftpcdup,-1,0,"0");   // Add the up-one-level ".."
   } else {
      // Setting userinfo to "0" guarantees it will get to top of tree when sorted
      nidx=_TreeAddItem(idx,"..\t\t\t\t",TREE_ADD_BEFORE,_pic_ftpcdup,_pic_ftpcdup,-1,0,"0");
   }
   _TreeSortUserInfo(TREE_ROOT_INDEX,"FE","");   // Sort by directories/links, then filenames
   _RefreshDirFields();
   _TreeTop();
   _TreeRefresh();

   return(0);
}

// Needed this for the ftpfile_match() completion function
FtpConnProfile *ftpopenGetCurrentConnProfile()
{
   int formWid=_ftpopenQFormWid();
   if( !formWid ) return(null);

   return(formWid.GetCurrentConnProfile());
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
void _ftpopenProgressCB(_str operation, typeless nofbytes, typeless total_nofbytes)
{
   int formWid = _ftpopenQFormWid();
   if( !formWid ) {
      return;
   }
   int operationWid = formWid._find_control('_ctl_operation');
   int nofbytesWid = formWid._find_control('_ctl_nofbytes');
   //say('operation='operation'  nofbytes='nofbytes'  total_nofbytes='total_nofbytes);
   if( operationWid ) {
      operationWid.p_caption = operation;
   }
   if( nofbytes == total_nofbytes ) {
      if( nofbytesWid ) {
         nofbytesWid.p_caption = 'Complete';
      }
   } else if( nofbytes >= 0 && total_nofbytes > 0 && nofbytes <= total_nofbytes ) {
      if( nofbytesWid ) {
         nofbytesWid.p_caption = nofbytes:+' / ':+total_nofbytes:+' bytes';
      }
   } else {
      if( nofbytesWid ) {
         nofbytesWid.p_caption = nofbytes:+' bytes';
      }
   }
}

/**
 * Show progress for transfer on the FTP tool window and the FTP
 * progress dialog. 
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
void _ftpopenProgressDlgCB(_str operation, typeless nofbytes, typeless total_nofbytes)
{
   _ftpopenProgressCB(operation,nofbytes,total_nofbytes);

   int formWid = _find_object('_ftpProgress_form','N');
   if( !formWid ) {
      return;
   }
   formWid.p_caption = operation;
   int progressWid = formWid._find_control('_ctl_progress');
   int nofbytesWid = formWid._find_control('_ctl_nofbytes');
   if( nofbytes == total_nofbytes ) {
      if( progressWid ) {
         progressWid.p_value = 100;
      }
      if( nofbytesWid ) {
         nofbytesWid.p_caption = 'Complete';
      }
   } else if( nofbytes >= 0 && total_nofbytes > 0 && nofbytes <= total_nofbytes ) {
      if( progressWid ) {
         int val;
         val = (int)(100.0 * ((double)nofbytes / (double)total_nofbytes));
         progressWid.p_value = val;
      }
      if( nofbytesWid ) {
         _str nofbytes_text = nofbytes;
         if( nofbytes > 1024 ) {
            nofbytes_text = round( nofbytes / 1024, 0 );
            nofbytes_text = nofbytes_text:+'K';
         }
         _str total_nofbytes_text = '';
         if( total_nofbytes > 1024*1024 ) {
            total_nofbytes_text = round( total_nofbytes / (1024*1024), 1 );
            total_nofbytes_text = total_nofbytes_text:+'M';
         } else if( total_nofbytes > 1024 ) {
            total_nofbytes_text = round( total_nofbytes / 1024, 1 );
            total_nofbytes_text = total_nofbytes_text:+'K';
         }
         nofbytesWid.p_caption = nofbytes_text:+' / ':+total_nofbytes_text;
      }
   } else {
      if( progressWid ) {
         progressWid.p_value = 0;
      }
      if( nofbytesWid ) {
         nofbytesWid.p_caption = nofbytes:+' bytes';
      }
   }
}

void __ftpopenUpdateSessionCB( FtpQEvent* pEvent )
{
   FtpQEvent event;
   FtpRecvCmd rcmd;
   FtpConnProfile fcp;
   FtpConnProfile *fcp_p;

   event= *((FtpQEvent *)(pEvent));
   fcp=event.fcp;
   _str cmd="";
   _str msg="";
   typeless status=0;

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
                     fcp_p->ignoreListErrors=fcp.ignoreListErrors;
                  }
               }
            }
            // Fool this callback into thinking we got a 0 byte listing
            int temp_view_id=0;
            int orig_view_id=_create_temp_view(temp_view_id);
            if( orig_view_id=="" ) return;
            if( !_on_line0() ) _delete_line();
            _save_file('+o 'maybe_quote_filename(rcmd.dest));
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
         boolean pasv;
         _str cmdargv[];
         _str dest;
         _str datahost;
         _str dataport;
         int  size;
         pfnProgressCallback_tp ProgressCB;
      } RecvCmd_t;
      */
      fcp.postedCb=(typeless)__ftpopenUpdateSessionCB;
      typeless pasv= (fcp.useFirewall && fcp.global_options.fwenable && fcp.global_options.fwpasv );
      _str cmdargv[];
      cmdargv._makeempty();
      cmdargv[cmdargv._length()] = "LIST";
      // LIST gets really confused with more than one
      // option switch (it interprets the second option
      // as a filespec??), so we have to glom all options
      // together. Example: '-AL' instead of '-A -L'
      _str options = '-';
      if( fcp.system == FTPSYST_UNIX ) {
         options = options:+'A';
      }
      if( fcp.resolveLinks ) {
         options = options:+'L';
      }
      if( options != '-' ) {
         cmdargv[cmdargv._length()] = options;
      }
      _str dest=mktemp();
      if( dest=="" ) {
         msg="Unable to create temp file for remote directory listing";
         ftpConnDisplayError(&fcp,msg);
         return;
      }
      _str datahost="";
      _str dataport="";
      int size=0;
      rcmd.pasv=pasv;
      rcmd.cmdargv=cmdargv;
      rcmd.dest=dest;
      rcmd.datahost=datahost;
      rcmd.dataport=dataport;
      rcmd.size=size;
      rcmd.xfer_type=FTPXFER_ASCII;   // Always transfer listings ASCII
      rcmd.progressCb=_ftpopenProgressCB;
      _ftpEnQ(QE_RECV_CMD,QS_BEGIN,0,&fcp,rcmd);
      return;
   }

   // We just listed the contents of the current working directory.
   // Now stick it in the remote tree view.
   rcmd= (FtpRecvCmd)event.info[0];
   if( _ftpdebug&FTPDEBUG_SAVE_LIST ) {
      // Make a copy of the raw listing
      _str temp_path=_temp_path();
      if( last_char(temp_path)!=FILESEP ) temp_path=temp_path:+FILESEP;
      _str list_filename=temp_path:+"$list";
      copy_file(rcmd.dest,list_filename);
   }
   status=_ftpParseDir(&fcp,fcp.remoteDir,fcp.remoteFileFilter,rcmd.dest);
   typeless status2=delete_file(rcmd.dest);
   if( status2 && status2!=FILE_NOT_FOUND_RC && status2!=PATH_NOT_FOUND_RC ) {
      msg='Warning: Could not delete temp file "':+rcmd.dest:+'".  ':+_ftpGetMessage(status2);
      ftpConnDisplayError(&fcp,msg);
   }
   if( status ) return;

   // Find the matching connection profile in current connections
   // so we can update its stored remote directory listing.
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
      // We did not find the matching connection profile, so bail out
      return;
   }
   fcp_p->remoteDir=fcp.remoteDir;
   fcp_p->remoteCwd=fcp.remoteCwd;

   int profileWid=0, remoteWid=0;
   int formWid=_ftpopenQFormWid();
   if( !formWid ) return;
   if( _ftpopenFindAllControls(formWid,profileWid,remoteWid) ) {
      // This should never happen
      return;
   }
   int remotecwdWid=formWid._find_control("_ctl_remote_cwd");
   if( !remotecwdWid ) return;
   int noconnWid=formWid._find_control("_ctl_no_connection");
   if( !noconnWid ) return;

   _ftpopenChangeRemoteDirOnOff(0);
   status=remoteWid._ftpopenRefreshDir(fcp_p);
   _ftpopenChangeRemoteDirOnOff(1);
   if( !status ) {
      remoteWid._ftpRemoteRestorePos();
      remoteWid._ftpRemoteSavePos();
      remoteWid.p_visible=true;
      remotecwdWid.p_visible=true;
      _str cwd=fcp_p->remoteCwd;
      _ftpopenChangeRemoteCwdOnOff(0);
      _ftpAddCwdHist(fcp_p->cwdHist,cwd);
      remotecwdWid.p_text=cwd;
      remotecwdWid._set_sel(1,length(cwd)+1);
      _ftpopenChangeRemoteCwdOnOff(1);
      call_list('_ftpCwdHistoryAddRemove_',formWid);
   }
   noconnWid.p_visible= !remoteWid.p_visible;

   _MaybeUpdateFTPClient(profileWid.p_text);

   if( _jaws_mode() ) {
      // Put focus in listing
      p_window_id=remoteWid;
      _set_focus();
   }
}

// Attach the current connection profile's directory listing, log buffer,etc.
// Note: force=true means force a refresh of the current connection
static void _UpdateSession(boolean force)
{
   FtpConnProfile *fcp_p;
   FtpConnProfile fcp;

   fcp_p=GetCurrentConnProfile();
   if( fcp_p ) {

      if( force || fcp_p->remoteDir._isempty() ) {
         fcp= *fcp_p;   // Make a copy
         if( fcp.serverType==FTPSERVERTYPE_SFTP ) {
            fcp.postedCb=(typeless)__sftpopenUpdateSessionCB;
            _ftpSyncEnQ(QE_SFTP_DIR,QS_BEGIN,0,&fcp);
         } else {
            // FTP
            fcp.postedCb=(typeless)__ftpopenUpdateSessionCB;
            _ftpSyncEnQ(QE_PWD,QS_BEGIN,0,&fcp);
         }
         return;
      }

      // Update the remote current working directory list
      _ftpopenChangeRemoteDirOnOff(0);
      int status=_ctl_remote_dir._ftpopenRefreshDir(fcp_p);
      _ftpopenChangeRemoteDirOnOff(1);
      if( !status ) {
         _ctl_remote_dir._ftpRemoteRestorePos();
         _ctl_remote_dir._ftpRemoteSavePos();
         _ctl_remote_dir.p_visible=true;
         _ctl_remote_cwd.p_visible=true;
         _str cwd=fcp_p->remoteCwd;
         _ftpopenChangeRemoteCwdOnOff(0);
         _ftpAddCwdHist(fcp_p->cwdHist,cwd);
         _ctl_remote_cwd.p_text=cwd;
         _ctl_remote_cwd._set_sel(1,length(cwd)+1);
         _ftpopenChangeRemoteCwdOnOff(1);
      }
      _ctl_no_connection.p_visible= !_ctl_remote_dir.p_visible;
      return;
   } else {
      _ctl_remote_dir.p_visible=false;
      _ctl_remote_cwd.p_visible=false;
      _ctl_no_connection.p_visible=true;
   }

   _MaybeUpdateFTPClient(_ctl_profile.p_text);

   return;
}

void _ftpopenUpdateSession(boolean force)
{
   int formWid;

   formWid=_ftpopenQFormWid();
   if( !formWid ) return;
   formWid._UpdateSession(force);

   return;
}

void _ctl_profile.on_change(int reason, typeless forceChange="")
{
   if( !_ftpopenChangeProfileOnOff() ) return;
   boolean force= (forceChange!="" && forceChange);
   _ctl_profile._ftpopenChangeProfile();
   // Remember current profile.
   // Must do this here because exiting the editor does not call a control's
   // ON_DESTROY event.
   _append_retrieve(_ctl_profile,_ctl_profile.p_text);
   _ctl_profile._UpdateSession(force);
}

static void _ftpopenMaybeReconnect(FtpConnProfile* fcp_p)
{
   if( !_ftpIsConnectionAlive(fcp_p) ) {
      _ftpLog(fcp_p,"Lost connection on ":+_date():+" at ":+_time('m'):+". Attempting to reconnect...");
      // fcp_p could be a pointer into the _ftpCurrentConnections:[]
      // hash table, so make a copy so that _ftpopenDisconnect() can
      // successfully remove the connection from the hash table.
      FtpConnProfile fcp = *fcp_p;
      // Restart the connection.
      // IMPORTANT:
      // fcp will not be updated by _ftpopen* functions, but
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
      _ftpopenDisconnect(&fcp,true,true,le);
      fcp = le.fcp;
      // Set .DefRemoteHostDir, .DefLocalHostDir so user gets restored
      // to exactly where they were before they were disconnected.
      fcp.defRemoteDir=remoteCwd;
      fcp.defLocalDir=localCwd;
      _ftpopenConnect(&fcp,true,true,le);
      // le.fcp should contain the final connected profile, so
      // copy it into fcp_p now.
      *fcp_p = le.fcp;
   }
}

void __ftpopenConnectCB( FtpQEvent* pEvent, typeless isReconnecting="" )
{
   FtpQEvent event;
   FtpConnProfile fcp;
   int formWid;
   _str CwdHist[];

   event= *((FtpQEvent *)(pEvent));
   boolean reconnecting = ( isReconnecting!="" && isReconnecting );

   formWid=_ftpopenQFormWid();
   int profileWid=0, operationWid=0, nofbytesWid=0;
   if( formWid>0 ) {
      profileWid=formWid._find_control("_ctl_profile");
      operationWid=formWid._find_control("_ctl_operation");
      nofbytesWid=formWid._find_control("_ctl_nofbytes");
   }
   fcp=event.fcp;

   if( _ftpQEventIsError(event) || _ftpQEventIsAbort(event) ) {
      if( event.event!=QE_CWD && event.event!=QE_PWD && event.event!=QE_SYST ) {
         if( formWid>0 ) {
            operationWid.p_caption="";
            nofbytesWid.p_caption="";
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
            // No idea what to set this to
            fcp.remoteCwd="";
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
      // Still need to get host type
      if( reconnecting ) {
         fcp.postedCb=(typeless)__ftpopenConnect2CB;
      } else {
         fcp.postedCb=(typeless)__ftpopenConnectCB;
      }
      _ftpEnQ(QE_SYST,QS_BEGIN,0,&fcp);
      return;
   }

   _ftpGetCwdHist(fcp.profileName,CwdHist);
   fcp.cwdHist=CwdHist;
   _str htindex=0;
   typeless status=_ftpAddCurrentConnProfile(&fcp,htindex);

   if( formWid==0 ) {
      // This could happen if user closes Project toolbar in the middle
      // of the connection attempt.
      return;
   }
   if( !reconnecting ) {
      profileWid._ftpopenFillProfiles(true);
      profileWid._ftpopenChangeProfile(htindex);
      formWid._UpdateSession(true);
      call_list('_ftpProfileAddRemove_',formWid);
   }

   operationWid.p_caption="Connected";
   nofbytesWid.p_caption="";

   return;
}
/**
 * Used when reconnecting a lost connection.
 */
void __ftpopenConnect2CB( FtpQEvent* pEvent )
{
   __ftpopenConnectCB(pEvent, true);
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
static void _ftpopenConnect(FtpConnProfile* fcp_p, boolean sync,
                            boolean reconnecting=false, FtpQEvent& lastEvent=null)
{
   FtpConnProfile fcp;

   fcp = *fcp_p;

   if( fcp.serverType==FTPSERVERTYPE_SFTP ) {
      // SFTP
      if( reconnecting ) {
         fcp.postedCb= (typeless)__sftpopenConnect2CB;
      } else {
         fcp.postedCb= (typeless)__sftpopenConnectCB;
      }
   } else {
      // FTP
      if( reconnecting ) {
         fcp.postedCb= (typeless)__ftpopenConnect2CB;
      } else {
         fcp.postedCb= (typeless)__ftpopenConnectCB;
      }
   }
   // Note:
   // sync parameter is ignored for now. Operations are always
   // synchronous. The user will still have the opportunity to
   // cancel the connection in progress, so this is okay.
   if( _jaws_mode() ) {
      // Synchronous connect-with-progress for JAWS mode users
      boolean need_connect;
      _ftpSynchronousConnect(&fcp,need_connect,false);
   } else {
      FtpQEvent le;
      if( fcp.serverType==FTPSERVERTYPE_SFTP ) {
         // SFTP
         le = _ftpSyncEnQ(QE_SSH_START_CONN_PROFILE,QS_BEGIN,0,&fcp);
      } else {
         // FTP
         le = _ftpSyncEnQ(QE_START_CONN_PROFILE,QS_BEGIN,0,&fcp);
      }
      if( lastEvent!=null ) {
         lastEvent=le;
      }
   }
}

void _ftpProfileAddRemove_ftpopen(typeless fromFormWid=0)
{
   int formWid = _ftpopenQFormWid();
   if( !formWid || formWid == fromFormWid ) {
      return;
   }
   int profileWid = formWid._find_control('_ctl_profile');
   profileWid._ftpopenFillProfiles(false);
}

/**
 * Start a connection to S/FTP server.
 */
_command void ftpopenConnect()
{
   FtpConnProfile fcp;

   fcp._makeempty();
   _str caption = "Connect";
   typeless status=0;
   if( p_DockingArea!=0 ) {
      status=_mdi.show("-modal _ftpProfileManager_form",&fcp,caption);
   } else {
      status=show("-modal _ftpProfileManager_form",&fcp,caption);
   }
   if( status ) {
      return;
   }

   int formWid = _ftpopenQFormWid();
   if( formWid>0 ) {
      _control _ctl_operation, _ctl_nofbytes;
      formWid._ctl_operation.p_caption="Connecting...";
      formWid._ctl_nofbytes.p_caption="";
   }
   _ftpopenConnect(&fcp,true);
}

void _ctl_connect.lbutton_up()
{
   ftpopenConnect();
}

void __ftpopenDisconnectCB( FtpQEvent* pEvent, typeless isReconnecting="" )
{
   FtpQEvent event;

   event= *((FtpQEvent *)(pEvent));
   boolean reconnecting = ( isReconnecting!='' && isReconnecting );

   if( !reconnecting ) {
      _ftpDeleteLogBuffer(&event.fcp);
   }
   _ftpRemoveCurrentConnProfile(&event.fcp);

   int formWid = _ftpopenQFormWid();
   if( formWid==0 ) {
      // This could happen if user closes Project toolbar in the middle
      // of the connection attempt.
      return;
   }

   if( !reconnecting ) {
      _control _ctl_profile, _ctl_operation, _ctl_nofbytes;
      formWid._ctl_profile._ftpopenFillProfiles(true);
      formWid._ctl_profile._ftpopenChangeProfile();
      if( formWid._ctl_profile.p_text=="" ) {
         // No more connections, so leave a final message
         formWid._ctl_operation.p_caption="Disconnected";
         formWid._ctl_nofbytes.p_caption="";
      } else {
         formWid._ctl_operation.p_caption="";
         formWid._ctl_nofbytes.p_caption="";
      }
      formWid._ctl_profile._UpdateSession(false);
      call_list('_ftpProfileAddRemove_',formWid);
   }
}
/**
 * Used for reconnecting in the case of a lost connection.
 */
void __ftpopenDisconnect2CB( FtpQEvent* pEvent )
{
   __ftpopenDisconnectCB(pEvent, true);
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
static void _ftpopenDisconnect(FtpConnProfile* fcp_p, boolean sync,
                               boolean reconnecting=false, FtpQEvent& lastEvent=null)
{
   _ftpSaveCwdHist(fcp_p->profileName,fcp_p->cwdHist);
   FtpQEvent le;
   // Note:
   // Both FTP _and_ SFTP can use the same callback
   //
   // Note:
   // sync parameter is ignored for now. Operations are always
   // synchronous.
   if( reconnecting ) {
      fcp_p->postedCb= (typeless)__ftpopenDisconnect2CB;
   } else {
      fcp_p->postedCb= (typeless)__ftpopenDisconnectCB;
   }
   if( fcp_p->serverType==FTPSERVERTYPE_SFTP ) {
      // SFTP
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
_command void ftpopenDisconnect()
{
   _control _ctl_operation, _ctl_nofbytes;
   int formWid = _ftpopenQFormWid();
   if( formWid==0 ) {
      // Nothing to do
      return;
   }

   FtpConnProfile* fcp_p = formWid.GetCurrentConnProfile();
   if( fcp_p ) {
      formWid._ctl_operation.p_caption="Disconnecting...";
      formWid._ctl_nofbytes.p_caption="";
      _ftpopenDisconnect(fcp_p,true);
      return;
   }
   formWid._ctl_profile._ftpopenChangeProfile();
   formWid._ctl_profile._UpdateSession(false);
}

void _ctl_disconnect.lbutton_up()
{
   _control _ctl_profile;
   int formWid = p_active_form;

   FtpConnProfile* fcp_p = formWid.GetCurrentConnProfile();
   if( fcp_p ) {
      _ftpopenDisconnect(fcp_p,true);
   }
   formWid._ctl_profile._ftpopenChangeProfile();
   formWid._ctl_profile._UpdateSession(false);
}

static void _UpdateFTPClientXferType()
{
   FtpConnProfile *fcp_p;
   int formWid;
   int asciiWid;
   int binWid;
   int xfer_type;

   formWid=_ftpopenQFormWid();
   if( !formWid ) return;
   fcp_p=formWid.GetCurrentConnProfile();
   if( !fcp_p ) return;
   int profileWid=formWid._find_control("_ctl_profile");
   if( !profileWid ) return;
   _str thisprofile=profileWid.p_text;

   formWid=_find_object("_tbFTPClient_form","N");
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
   if( xfer_type==FTPXFER_ASCII ) {
      asciiWid.p_value=1;
      binWid.p_value=0;
      binWid.p_style=PSPIC_FLAT_BUTTON;
      asciiWid.p_style=PSPIC_BUTTON;
   } else if( xfer_type==FTPXFER_BINARY ) {
      asciiWid.p_value=0;
      binWid.p_value=1;
      binWid.p_style=PSPIC_BUTTON;
      asciiWid.p_style=PSPIC_FLAT_BUTTON;
   }

   return;
}

static boolean _ftpIsConnected()
{
   FtpConnProfile* fcp_p = ftpopenGetCurrentConnProfile();
   if( !fcp_p ) {
      return false;
   }
   return ( _ftpIsConnectionAlive(fcp_p) );
}
int _OnUpdate_ftpDisconnect(CMDUI &cmdui,int target_wid,_str command)
{
   int wid=_find_object('_tbFTPOpen_form._ctl_disconnect','N');
   if (!wid) {
      wid=_find_object('_tbFTPClient_form._ctl_disconnect','N');
   }
   if (!wid || !_ftpIsConnected()) {
      return(MF_GRAYED);
   }
   return(MF_ENABLED);
}
_command void ftpDisconnect()
{
   int wid=_find_object('_tbFTPOpen_form._ctl_disconnect','N');
   if (!wid) {
      wid=_find_object('_tbFTPClient_form._ctl_disconnect','N');
   }
   wid.call_event(wid,LBUTTON_UP,'W');
}
int _OnUpdate_ftpBinaryToggle(CMDUI &cmdui,int target_wid,_str command)
{
   int wid=_find_object('_tbFTPOpen_form._ctl_binary','N');
   if (!wid) {
      wid=_find_object('_tbFTPClient_form._ctl_binary','N');
   }
   if (!wid || !_ftpIsConnected()) {
      return(MF_GRAYED);
   }
   if (wid.p_value) {
      return(MF_ENABLED|MF_CHECKED);
   }
   return(MF_ENABLED);
}
_command void ftpBinaryToggle()
{
   int wid=_find_object('_tbFTPOpen_form._ctl_binary','N');
   if (!wid) {
      wid=_find_object('_tbFTPClient_form._ctl_binary','N');
   }
   if (!wid) {
      return;
   }
   // If we a are already in binary mode
   if (wid.p_value) {
      wid=wid.p_prev;
   }
   wid.p_value=1;
   wid.call_event(wid,LBUTTON_UP,'W');
}
void _ctl_ascii.lbutton_up(typeless doNoCheck="")
{
   FtpConnProfile *fcp_p;
   boolean nocheck= (doNoCheck!="" && doNoCheck);

   // Both ASCII and Binary cannot be on at the same time
   _ctl_binary.p_value=0;
   _ctl_binary.p_style=PSPIC_FLAT_BUTTON;
   _ctl_ascii.p_value=1;
   _ctl_ascii.p_style=PSPIC_BUTTON;

   fcp_p=GetCurrentConnProfile();
   if( fcp_p ) {
      if( !nocheck && fcp_p->serverType!=FTPSERVERTYPE_FTP ) {
         // Transfer type buttons are disabled for non-FTP server types
         // because the user does not have a choice.
         p_value= (int)(p_value==0);
         _ctl_binary.p_value= (int)(_ctl_binary.p_value==0);
         _ctl_ascii.p_style=_ctl_binary.p_style=PSPIC_FLAT_BUTTON;
         _str msg="Setting the transfer mode is not supported for this server type";
         ftpConnDisplayError(fcp_p,msg);
         return;
      }
      if( p_value ) {
         fcp_p->xferType=FTPXFER_ASCII;
      } else {
         fcp_p->xferType=FTPXFER_BINARY;
      }
   }

   _UpdateFTPClientXferType();

   return;
}

void _ctl_binary.lbutton_up(typeless doNoCheck="")
{
   FtpConnProfile *fcp_p;
   boolean nocheck= (doNoCheck!="" && doNoCheck);

   // Both ASCII and Binary cannot be on at the same time
   _ctl_ascii.p_value=0;
   _ctl_ascii.p_style=PSPIC_FLAT_BUTTON;
   _ctl_binary.p_value=1;
   _ctl_binary.p_style=PSPIC_BUTTON;

   fcp_p=GetCurrentConnProfile();
   if( fcp_p ) {
      if( !nocheck && fcp_p->serverType!=FTPSERVERTYPE_FTP ) {
         // Transfer type buttons are disabled for non-FTP server types
         // because the user does not have a choice.
         p_value= (int)(p_value==0);
         _ctl_ascii.p_value= (int)(_ctl_ascii.p_value==0);
         _ctl_ascii.p_style=_ctl_binary.p_style=PSPIC_FLAT_BUTTON;
         _str msg="Setting the transfer mode is not supported for this server type";
         ftpConnDisplayError(fcp_p,msg);
         return;
      }
      if( p_value ) {
         fcp_p->xferType=FTPXFER_BINARY;
      } else {
         fcp_p->xferType=FTPXFER_ASCII;
      }
   }

   _UpdateFTPClientXferType();

   return;
}

void __ftpopenAbortCB( FtpQEvent* pEvent )
{
   FtpQEvent event;
   FtpConnProfile fcp;

   event= *((FtpQEvent *)(pEvent));

   fcp=event.fcp;
   if( !_ftpQEventIsError(event) ) {
      int formWid=_ftpopenQFormWid();
      if( !formWid ) return;
      int operationWid=formWid._find_control("_ctl_operation");
      if( !operationWid ) return;
      int nofbytesWid=formWid._find_control("_ctl_nofbytes");
      if( !nofbytesWid ) return;
      operationWid.p_caption="Aborted";
      nofbytesWid.p_caption="";
   }

   return;
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
   _ctl_operation.p_caption="Aborting...";
   _ctl_nofbytes.p_caption="";
   event.fcp.postedCb=(typeless)__ftpopenAbortCB;
   _ftpQ[0]=event;

   return;
}

int _ftpopenFindAllControls(int formWid,
                            int &profilecbWid,
                            int &remotetreeWid)
{
   profilecbWid=formWid._find_control("_ctl_profile");
   if( !profilecbWid ) return(1);
   remotetreeWid=formWid._find_control("_ctl_remote_dir");
   if( !remotetreeWid ) return(1);

   return(0);
}

boolean _ftpDataSetIsFile()
{
   if (_DataSetIsFile(p_buf_name)) {
      return(true);
   }
   if (substr(p_DocumentName,1,6):!='ftp://') {
      return(false);
   }
   _str dsname="";
   parse p_DocumentName with '//' . '//' dsname '/';
   return(dsname:!='');
}

_str _ftpGetFileTypeFromQualifier()
{
   if (_DataSetIsFile(p_buf_name)) {
      return(_getFileTypeFromQualifier(p_buf_name));
   }
   if (substr(p_DocumentName,1,6):!='ftp://') {
      return('');
   }
   _str dsname="";
   parse p_DocumentName with '//' . '//' dsname '/';
   if(dsname:=='') {
      return('');
   }
   return(_getFileTypeFromQualifier('',dsname));
}

int _ftpDoRecvCmd(FtpConnProfile *fcp_p,FtpRecvCmd *rcmd_p)
{
   _str action="";
   if( fcp_p->serverType==FTPSERVERTYPE_FTP ) {
      action=upcase(rcmd_p->cmdargv[0]);
      if( action!="RETR" ) {
         // This should never happen
         ftpConnDisplayError(fcp_p,'Invalid action: "':+action:+'"');
         return(1);
      }
   }
   // Let's try to get the encoding right
   _str edit_options="";
   _str ext = _get_extension(rcmd_p->dest);
   if( _LanguageInheritsFrom('xml',_Ext2LangId(ext)) ) {
      edit_options="+FAUTOXML";
   } else {
      edit_options="+FAUTOUNICODE";
   }
   typeless status=_mdi.p_child.edit(edit_options' 'maybe_quote_filename(rcmd_p->dest));
   if( status ) {
      _str msg='Unable to open local file "':+rcmd_p->dest:+'".  ':+_ftpGetMessage(status);
      ftpConnDisplayError(fcp_p,msg);
      return(1);
   }

   // Mark this file as binary if we downloaded it binary
   if( fcp_p->serverType!=FTPSERVERTYPE_SFTP ) {
      if( rcmd_p->xfer_type==FTPXFER_BINARY ) {
         _mdi.p_child._ftpSetBinary(true);
      }
   }

   _str document_name='ftp://':+fcp_p->host;
   _str remote_path=rcmd_p->extra;   // This is the fully qualified remote path
   if( substr(remote_path,1,1)!='/' ) document_name=document_name:+'/';
   if( fcp_p->system==FTPSYST_MVS ) {
      // Special SlickEdit '//' document name format for datasets
      remote_path=_ftpConvertMVStoSEFilename(remote_path);
      if( substr(remote_path,1,2)=='//' ) {
         // We want '//', not '///'
         document_name=document_name:+substr(remote_path,2);
      } else {
         document_name=document_name:+remote_path;
      }
   } else if( fcp_p->system==FTPSYST_OS400 ) {
      // Special SlickEdit '//' document name format for LFS files
      remote_path=_ftpConvertOS400toSEFilename(remote_path);
      if( substr(remote_path,1,2)=='//' ) {
         // We want '//', not '///'
         document_name=document_name:+substr(remote_path,2);
      } else {
         document_name=document_name:+remote_path;
      }
   } else {
      document_name=document_name:+remote_path;
   }
   _mdi.p_child.docname(document_name);
   if (_mdi.p_child._ftpDataSetIsFile() &&
          (_default_option(VSOPTION_PACKFLAGS1) & (VSPACKFLAG1_PKGA))) {
      _mdi.p_child.p_AutoSelectLanguage=true;
      _UpdateEditorLanguage(_mdi.p_child/*,true*/);
      //say('doc='_mdi.p_child.p_DocumentName);
      //say('ext='_mdi.p_child.p_LangId);
   }
   refresh();

   return(0);
}

void __ftpopenOpenCB( FtpQEvent* pEvent )
{
   FtpQEvent event;
   FtpConnProfile fcp;
   FtpRecvCmd rcmd;
   FtpFile files[];
   FtpFile next_file;

   event= *((FtpQEvent *)(pEvent));
   fcp=event.fcp;
   fcp.postedCb=null;
   // Note:
   // The .DownloadLinks is an operation-defined member, so we must
   // use the value defined for the event, not the connection.
   boolean download_links = fcp.downloadLinks;

   if( _ftpQEventIsError(event) || _ftpQEventIsAbort(event) ) {
      // Nothing to do
      return;
   }

   if( event.event==QE_RECV_CMD || event.event==QE_SFTP_GET ) {
      rcmd=event.info[0];
      if(_ftpDoRecvCmd(&fcp,&rcmd)) {
         // _ftpDoRecvCmd took care of any messages
         return;
      }
   }

   // We are done.
   // Find the next selected file/directory.
   FtpConnProfile *fcp_p;
   int profileWid=0, remoteWid=0;
   int formWid=_ftpopenQFormWid();
   if( !formWid ) return;   // This should never happen
   if( _ftpopenFindAllControls(formWid,profileWid,remoteWid) ) {
      return;
   }
   fcp_p=formWid.GetCurrentConnProfile();
   if( !fcp_p ) {
      // This should never happen
      return;
   }
   fcp= *fcp_p;   // Make a copy
   fcp.postedCb=null;
   if( 0==remoteWid._TreeGetNumSelectedItems() ) {
      // This could happen if the user docked/undocked/killed
      // the Project toolbar in the middle of transferring.
      return;
   }
   _str ext="";
   _str temp="";
   _str member="";
   _str file_and_member="";
   int idx=remoteWid._TreeGetNextSelectedIndex(1,auto treeSelectInfo);
   while( idx>=0 ) {
      _str caption=remoteWid._TreeGetCaption(idx);
      _str filename, size, date, time, attribs;
      parse caption with filename "\t" size "\t" date "\t" time "\t" attribs .;
      if( filename!=".." ) {
         _str info=remoteWid._TreeGetUserInfo(idx);
         info=lowcase(info);
         if( pos("f",info) || (download_links && pos("l",info)) ) {
            // File
            if( (fcp.system==FTPSYST_UNIX || (fcp.system==FTPSYST_MVS && substr(fcp.remoteCwd,1,1)=='/')) &&
                pos("l",info) ) {
               // Get rid of the link part
               parse filename with filename '->' .;
               filename=strip(filename);
            }

            _str dest=_ftpAbsolute(&fcp,filename);

            switch( fcp.system ) {
            case FTPSYST_VMS:
            case FTPSYST_VMS_MULTINET:
               // VMS filenames have version numbers at the end (e.g. ";1").
               // We don't want the version number.
               parse dest with dest ';' .;
               break;
            case FTPSYST_OS400:
               if( substr(dest,1,1)=='/' ) {
                  // IFS file system which mimics Unix
                  _str file_system="";
                  parse dest with '/' file_system '/' .;
                  file_system=upcase(file_system);
                  if( file_system=="QSYS.LIB" ) {
                     ext=upcase(_get_extension(filename));
                     if( ext=="FILE" ) {
                        // This is a QSYS.LIB file that has members.
                        // What they really want is the member whose
                        // name is the same as the file but with the
                        // extension changed to '.MBR'. This member
                        // will be subdirectoried from the file name.
                        member=_strip_filename(filename,'E');
                        member=member:+".MBR";
                        dest=dest:+'/':+member;
                        file_and_member=filename:+'/':+member;
                        // We are now retrieving the member of the file
                        filename=file_and_member;
                     }
                  }
               } else {
                  // LFS
                  _str libname="";
                  _str fname="";
                  parse dest with libname '/' fname;
                  if( !pos('.',fname) ) {
                     // This is a LFS file that has members.
                     // What they really want is the member whose
                     // name is the same as the file.
                     member=fname;
                     dest=dest:+'.':+member;
                     file_and_member=fname:+'.':+member;
                     // We are now retrieving the member of the file
                     filename=file_and_member;
                  }
               }
               break;
            }

            // Check for an already existing buffer with this document name
            _str document_name='ftp://':+fcp.host;
            if( substr(dest,1,1)!='/' ) document_name=document_name:+'/';
            if( fcp.system==FTPSYST_MVS ) {
               // Special SlickEdit '//' document name format for datasets
               temp=_ftpConvertMVStoSEFilename(dest);
               if( substr(temp,1,2)=='//' ) {
                  // We want '//', not '///'
                  document_name=document_name:+substr(temp,2);
               } else {
                  document_name=document_name:+dest;
               }
            } else if( fcp.system==FTPSYST_OS400 ) {
               // Special SlickEdit '//' document name format LFS files
               temp=_ftpConvertOS400toSEFilename(dest);
               if( substr(temp,1,2)=='//' ) {
                  // We want '//', not '///'
                  document_name=document_name:+substr(temp,2);
               } else {
                  document_name=document_name:+dest;
               }
            } else {
               document_name=document_name:+dest;
            }
            info=buf_match(document_name,1,"EVD");
            if( info!="" ) {
               typeless buf_id="";
               parse info with buf_id . . .;
               edit("+bi ":+buf_id);
               idx=remoteWid._TreeGetNextSelectedIndex(0,treeSelectInfo);
               continue;
            }

            _str localpath="";
            if( fcp.system==FTPSYST_MVS ) {
               // A single-quoted path indicates it is already absolute
               localpath=_ftpRemoteToLocalPath(&fcp,"'"dest"'");
            } else {
               localpath=_ftpRemoteToLocalPath(&fcp,dest);
            }
            if( localpath=="" ) {
               ftpConnDisplayError(&fcp,"Unable to create local filename");
               return;
            }
            if( fcp.serverType==FTPSERVERTYPE_SFTP ) {
               fcp.postedCb=(typeless)__ftpopenOpenCB;
               // Note:
               // The .DownloadLinks is an operation-defined member, so we must
               // use the value defined for the last event, not the connection.
               fcp.downloadLinks=download_links;
               // It is easier to re-use RecvCmd_t for SFTP transactions even
               // though we do not use all the members.
               FtpRecvCmd sftp_rcmd;
               _str cmdargv[];
               cmdargv._makeempty();
               cmdargv[0]=filename;
               sftp_rcmd.cmdargv=cmdargv;
               sftp_rcmd.datahost=sftp_rcmd.dataport="";  // Ignored
               sftp_rcmd.xfer_type=FTPXFER_BINARY;   // Ignored
               sftp_rcmd.extra=dest;   // Save this so we know how to set p_DocumentName
               sftp_rcmd.dest=localpath;
               sftp_rcmd.pasv=0;   // Ignored
               sftp_rcmd.progressCb=_ftpopenProgressDlgCB;
               sftp_rcmd.size=0;
               _ftpEnQ(QE_SFTP_GET,QS_BEGIN,0,&fcp,sftp_rcmd);
            } else {
               // FTP
               fcp.postedCb=(typeless)__ftpopenOpenCB;
               // Note:
               // The .DownloadLinks is an operation-defined member, so we must
               // use the value defined for the last event, not the connection.
               fcp.downloadLinks=download_links;
               FtpRecvCmd retr_rcmd;
               _str cmdargv[];
               cmdargv._makeempty();
               cmdargv[0]="RETR";
               cmdargv[1]=filename;
               int xfer_type=fcp.xferType;
               retr_rcmd.cmdargv=cmdargv;
               retr_rcmd.datahost=retr_rcmd.dataport="";
               retr_rcmd.xfer_type=xfer_type;
               retr_rcmd.extra=dest;   // Save this so we know how to set p_DocumentName
               retr_rcmd.dest=localpath;
               retr_rcmd.pasv= (fcp.useFirewall && fcp.global_options.fwenable && fcp.global_options.fwpasv);
               retr_rcmd.progressCb=_ftpopenProgressDlgCB;
               retr_rcmd.size=0;
               _ftpEnQ(QE_RECV_CMD,QS_BEGIN,0,&fcp,retr_rcmd);
            }
         } else if( pos("d",info) ) {
            // Directory
            idx=remoteWid._TreeGetNextSelectedIndex(0,treeSelectInfo);
            continue;
         }
         return;
      }
   }

   return;
}

_command void ftpopenOpen(typeless doDownloadLinks="") name_info(','VSARG2_NCW|VSARG2_READ_ONLY)
{
   FtpConnProfile *fcp_p;
   FtpConnProfile fcp;

   int profileWid=0, remoteWid=0;
   int formWid=_ftpopenQFormWid();
   if( 0==formWid ) {
      return;
   }

   if( _ftpopenFindAllControls(formWid,profileWid,remoteWid) ) {
      return;
   }
   fcp_p=formWid.GetCurrentConnProfile();
   if( !fcp_p ) {
      return;
   }
   // Make a copy
   fcp = *fcp_p;

   _ftpopenMaybeReconnect(&fcp);

   _str ext="";
   _str temp="";
   _str member="";
   _str file_and_member="";
   
   int idx = remoteWid._TreeGetNextSelectedIndex(1, auto selectInfo); 
   while( idx>=0 ) {
      _str caption=remoteWid._TreeGetCaption(idx);
      _str filename, size, date, time, attribs;
      parse caption with filename "\t" size "\t" date "\t" time "\t" attribs .;
      if( filename==".." ) {
         continue;
      } else {
         _str info=remoteWid._TreeGetUserInfo(idx);
         info=lowcase(info);
         // Open links as files?
         fcp.downloadLinks= ( doDownloadLinks!="" && doDownloadLinks );
         fcp.postedCb=null;
         if( pos("f",info) || (fcp.downloadLinks && pos("l",info)) ) {
            // File
            if( (fcp.system==FTPSYST_UNIX || (fcp.system==FTPSYST_MVS && substr(fcp.remoteCwd,1,1)=='/')) &&
                pos("l",info) ) {
               // Get rid of the link part
               parse filename with filename '->' .;
               filename=strip(filename);
            }

            _str dest=_ftpAbsolute(&fcp,filename);

            switch( fcp.system ) {
            case FTPSYST_VMS:
            case FTPSYST_VMS_MULTINET:
               // VMS filenames have version numbers at the end (e.g. ";1").
               // We don't want the version number.
               parse dest with dest ';' .;
               break;
            case FTPSYST_OS400:
               if( substr(dest,1,1)=='/' ) {
                  // IFS file system which mimics Unix
                  _str file_system="";
                  parse dest with '/' file_system '/' .;
                  file_system=upcase(file_system);
                  if( file_system=="QSYS.LIB" ) {
                     ext=upcase(_get_extension(filename));
                     if( ext=="FILE" ) {
                        // This is a QSYS.LIB file that has members.
                        // What they really want is the member whose
                        // name is the same as the file but with the
                        // extension changed to '.MBR'. This member
                        // will be subdirectoried from the file name.
                        member=_strip_filename(filename,'E');
                        member=member:+".MBR";
                        dest=dest:+'/':+member;
                        file_and_member=filename:+'/':+member;
                        // We are now retrieving the member of the file
                        filename=file_and_member;
                     }
                  }
               } else {
                  // LFS
                  _str libname="";
                  _str fname="";
                  parse dest with libname '/' fname;
                  if( !pos('.',fname) ) {
                     // This is a LFS file that has members.
                     // What they really want is the member whose
                     // name is the same as the file.
                     member=fname;
                     dest=dest:+'.':+member;
                     file_and_member=fname:+'.':+member;
                     // We are now retrieving the member of the file
                     filename=file_and_member;
                  }
               }
               break;
            }

            // Check for an already existing buffer with this document name
            _str document_name='ftp://':+fcp.host;
            if( fcp.system==FTPSYST_MVS ) {
               // Special SlickEdit '//' document name format for datasets
               temp=_ftpConvertMVStoSEFilename(dest);
               if( substr(temp,1,2)=='//' ) {
                  // Dataset
                  document_name=document_name:+temp;
               } else {
                  document_name=document_name:+dest;
               }
            } else if( fcp.system==FTPSYST_OS400 ) {
               // Special SlickEdit '//' document name format for LFS files
               temp=_ftpConvertOS400toSEFilename(dest);
               if( substr(temp,1,2)=='//' ) {
                  // LFS
                  document_name=document_name:+temp;
               } else {
                  document_name=document_name:+dest;
               }
            } else {
               document_name=document_name:+dest;
            }
            info=buf_match(document_name,1,"EVD");
            if( info!="" ) {
               typeless buf_id="";
               parse info with buf_id . . .;
               edit("+bi ":+buf_id);
               idx=remoteWid._TreeGetNextSelectedIndex(0, selectInfo);
               continue;
            }

            _str localpath="";
            if( fcp.system==FTPSYST_MVS ) {
               // A single-quoted path indicates an MVS path that is already absolute
               localpath=_ftpRemoteToLocalPath(&fcp,"'"dest"'");
            } else {
               localpath=_ftpRemoteToLocalPath(&fcp,dest);
            }
            if( localpath=="" ) {
               ftpConnDisplayError(&fcp,"Unable to create local filename");
               return;
            }
            if( fcp.serverType==FTPSERVERTYPE_SFTP ) {
               fcp.postedCb=(typeless)__ftpopenOpenCB;
               // It is easier to re-use RecvCmd_t for SFTP transactions even
               // though we do not use all the members.
               FtpRecvCmd rcmd;
               _str cmdargv[];
               cmdargv._makeempty();
               cmdargv[0]=filename;
               rcmd.cmdargv=cmdargv;
               rcmd.datahost=rcmd.dataport="";  // Ignored
               rcmd.xfer_type=FTPXFER_BINARY;   // Ignored
               rcmd.extra=dest;   // Save this so we know how to set p_DocumentName
               rcmd.dest=localpath;
               rcmd.pasv=0;   // Ignored
               rcmd.progressCb=_ftpopenProgressDlgCB;
               rcmd.size=0;
               // Members used specifically by SFTP
               rcmd.hfile= -1;
               rcmd.hhandle= -1;
               rcmd.offset=0;
               _ftpEnQ(QE_SFTP_GET,QS_BEGIN,0,&fcp,rcmd);
            } else {
               // FTP
               fcp.postedCb=(typeless)__ftpopenOpenCB;
               FtpRecvCmd rcmd;
               _str cmdargv[];
               cmdargv._makeempty();
               cmdargv[0]="RETR";
               cmdargv[1]=filename;
               int xfer_type=fcp.xferType;
               rcmd.cmdargv=cmdargv;
               rcmd.datahost=rcmd.dataport="";
               rcmd.xfer_type=xfer_type;
               rcmd.extra=dest;   // Save this so we know how to set p_DocumentName
               rcmd.dest=localpath;
               rcmd.pasv= (fcp.useFirewall && fcp.global_options.fwenable && fcp.global_options.fwpasv);
               rcmd.progressCb=_ftpopenProgressDlgCB;
               rcmd.size=0;
               _ftpEnQ(QE_RECV_CMD,QS_BEGIN,0,&fcp,rcmd);
            }
            break;
         } else if( pos("d",info) ) {
            // Directory
            idx=remoteWid._TreeGetNextSelectedIndex(0, selectInfo);
            continue;
         }
      }
      idx=remoteWid._TreeGetNextSelectedIndex(0, selectInfo);
   }

   if( _ftpQ._length()<1 ) return;

   gftpAbort=false;
   formWid=show("_ftpProgress_form");
   if( !formWid ) {
      _message_box('Could not show form: "_ftpProgress_form"','',MB_OK|MB_ICONEXCLAMATION);
      return;
   }
   for(;;) {
      process_events(gftpAbort);
      if( gftpAbort ) {
         FtpQEvent event;

         if( _ftpQ._length()<1 ) break;
         event=_ftpQ[0];

         // Find all events in the queue that match this one and delete them.
         int i;
         for( i=0;i<_ftpQ._length();++i ) {
            if( _ftpQ[i].event==event.event ) {
               _ftpQ._deleteel(i);
            }
         }

         event.state=QS_ABORT;
         event.start=0;
         // We queue it this way because the original event might have had
         // optional data in the info field that we don't want to lose.
         _ftpQ[0]=event;
         break;
      }
      if( _ftpQ._length()<1 ) {
         // We are done
         break;
      } else {
         // If the processed event was the last event for that particular
         // connection profile, then we are done
         boolean last=true;
         int i;
         for( i=0;i<_ftpQ._length();++i ) {
            if( _ftpQ[i].fcp.profileName==fcp.profileName &&
                _ftpQ[i].fcp.instance==fcp.instance ) {
               last=false;
               break;
            }
         }
         if( last ) {
            break;
         }
      }
      _ftpQTimerCallback();
      // Yield!
      delay(1);
   }
   formWid._delete_window();

   return;
}

_command void ftpopenOpenLinks() name_info(','VSARG2_NCW|VSARG2_READ_ONLY)
{
   ftpopenOpen(1);
}

void __ftpopenManualOpenCB( FtpQEvent* pEvent )
{
   FtpQEvent event;
   FtpConnProfile fcp;
   FtpRecvCmd rcmd;

   event= *((FtpQEvent *)(pEvent));

   if( _ftpQEventIsError(event) || _ftpQEventIsAbort(event) ) {
      // Nothing to do
      return;
   }

   fcp=event.fcp;
   if( event.event==QE_RECV_CMD || event.event==QE_SFTP_GET ) {
      rcmd=event.info[0];
      if(_ftpDoRecvCmd(&fcp,&rcmd)) {
         // _ftpDoRecvCmd took care of any messages
         return;
      }
   }

   return;
}

_command void ftpopenManualOpen(...) name_info(','VSARG2_NCW|VSARG2_READ_ONLY)
{
   FtpConnProfile *fcp_p;
   FtpConnProfile fcp;
   // Note: We use RecvCmd_t for SFTP transactions even though we do not use all the members.
   FtpRecvCmd rcmd;
   _str cmdargv[];

   int profileWid=0, remoteWid=0;
   int formWid=_ftpopenQFormWid();
   if( 0==formWid ) {
      return;
   }
   if( _ftpopenFindAllControls(formWid,profileWid,remoteWid) ) {
      return;
   }
   fcp_p=formWid.GetCurrentConnProfile();
   if( !fcp_p ) {
      return;
   }
   fcp= *fcp_p;   // Make a copy

   // Remember the last filename
   _str remote_path=_retrieve_value("_tbFTPOpen_form.ManualOpen.LastFilename");

   // Prompt for the remote path
   typeless result=show("-modal _ftpManualDownload_form",remote_path,0,fcp_p->xferType,"Manual Open",fcp_p);
   if( result=="" ) {
      // User cancelled
      return;
   }
   remote_path=strip(_param1);
   if( remote_path=="" ) return;

   // Remember the last filename
   _append_retrieve(0,remote_path,"_tbFTPOpen_form.ManualOpen.LastFilename");

   // _param2 not used
   int xfer_type= (int)_param3;

   // OS/400 LFS member?
   boolean os400_lfs= (fcp_p->system==FTPSYST_OS400 && _param4!=0);

   // _ftpAbsolute() will strip off any quotes
   boolean mvs_quoted= (fcp_p->system==FTPSYST_MVS && substr(remote_path,1,1)=="'" && last_char(remote_path)=="'");

   _str dest="";
   if( os400_lfs ) {
      // This is an OS/400 LFS member, so already absolute
      dest=remote_path;
   } else {
      dest=_ftpAbsolute(&fcp,remote_path);
   }

   _str ext="";
   _str temp="";
   _str filename="";
   _str member="";
   _str file_and_member="";
   switch( fcp.system ) {
   case FTPSYST_VMS:
   case FTPSYST_VMS_MULTINET:
      // VMS filenames have version numbers at the end (e.g. ";1").
      // We don't want the version number.
      parse dest with dest ';' .;
      break;
   case FTPSYST_OS400:
      if( substr(dest,1,1)=='/' ) {
         // IFS file system which mimics Unix
         _str file_system="";
         parse dest with '/' file_system '/' .;
         file_system=upcase(file_system);
         if( file_system=="QSYS.LIB" ) {
            filename=_ftpStripFilename(&fcp,dest,'P');
            ext=upcase(_get_extension(filename));
            if( ext=="FILE" ) {
               // This is a QSYS.LIB file that has members.
               // What they really want is the member whose
               // name is the same as the file but with the
               // extension changed to '.MBR'. This member
               // will be subdirectoried from the file name.
               member=_strip_filename(filename,'E');
               member=member:+".MBR";
               dest=dest:+'/':+member;
               file_and_member=filename:+'/':+member;
               // We are now retrieving the member of the file
               remote_path=file_and_member;
            }
         }
      } else {
         // LFS
         _str libname="", fname="";
         parse dest with libname '/' fname;
         if( !pos('.',fname) ) {
            // This is a LFS file that has members.
            // What they really want is the member whose
            // name is the same as the file.
            member=fname;
            dest=dest:+'.':+member;
            file_and_member=fname:+'.':+member;
            // We are now retrieving the member of the file
            remote_path=file_and_member;
         }
      }
      break;
   }

   // Check for an already existing buffer with this document name
   _str document_name='ftp://':+fcp.host;
   if( fcp.system==FTPSYST_MVS ) {
      // Special SlickEdit '//' document name format for datasets
      temp=_ftpConvertMVStoSEFilename(dest);
      if( substr(temp,1,2)=='//' ) {
         // Dataset
         document_name=document_name:+temp;
      } else {
         document_name=document_name:+dest;
      }
   } else if( fcp.system==FTPSYST_OS400 ) {
      // Special SlickEdit '//' document name format for datasets
      temp=_ftpConvertOS400toSEFilename(dest);
      if( substr(temp,1,2)=='//' ) {
         // LFS
         document_name=document_name:+temp;
      } else {
         document_name=document_name:+dest;
      }
   } else {
      document_name=document_name:+dest;
   }
   _str info=buf_match(document_name,1,"EVD");
   if( info!="" ) {
      typeless buf_id="";
      parse info with buf_id . . .;
      edit("+bi ":+buf_id);
      return;
   }

   _ftpopenMaybeReconnect(&fcp);

   _str localpath="";
   if( fcp.system==FTPSYST_MVS && substr(dest,1,1)!='/' ) {
      localpath=_ftpRemoteToLocalPath(&fcp,"'"dest"'");
   } else {
      localpath=_ftpRemoteToLocalPath(&fcp,dest);
   }
   if( localpath=="" ) {
      ftpConnDisplayError(&fcp,"Unable to create local filename");
      return;
   }
   if( fcp.serverType==FTPSERVERTYPE_SFTP ) {
      fcp.postedCb=(typeless)__ftpopenManualOpenCB;
      cmdargv._makeempty();
      cmdargv[0]=remote_path;
      rcmd.cmdargv=cmdargv;
      rcmd.xfer_type=FTPXFER_BINARY;   // Ignored
      rcmd.datahost=rcmd.dataport="";  // Ignored
      rcmd.dest=localpath;
      rcmd.extra=dest;   // Save this so we know how to set p_DocumentName
      rcmd.pasv=0;   // Ignored
      rcmd.progressCb=_ftpopenProgressDlgCB;
      rcmd.size=0;
      // Members used specifically by SFTP
      rcmd.hfile= -1;
      rcmd.hhandle= -1;
      rcmd.offset=0;
      _ftpEnQ(QE_SFTP_GET,QS_BEGIN,0,&fcp,rcmd);
   } else {
      fcp.postedCb=(typeless)__ftpopenManualOpenCB;
      cmdargv._makeempty();
      cmdargv[0]="RETR";
      cmdargv[1]=remote_path;
      rcmd.cmdargv=cmdargv;
      rcmd.xfer_type=xfer_type;
      rcmd.datahost=rcmd.dataport="";
      rcmd.dest=localpath;
      rcmd.extra=dest;   // Save this so we know how to set p_DocumentName
      rcmd.pasv= (fcp.useFirewall && fcp.global_options.fwenable && fcp.global_options.fwpasv);
      rcmd.progressCb=_ftpopenProgressDlgCB;
      rcmd.size=0;
      int hosttype=fcp.system;
      if( hosttype==FTPSYST_OS400 ) {
         _str pre_cmdargv[],post_cmdargv[];
         _str pre_cmds[], post_cmds[];
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
            boolean change_dir= (substr(fcp.remoteCwd,1,1)=='/' &&
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
         _ftpEnQ(QE_RECV_CMD,QS_CMD_BEFORE_BEGIN,0,&fcp,rcmd);
      } else if( hosttype==FTPSYST_VM || hosttype==FTPSYST_VMESA ) {
         _ftpEnQ(QE_RECV_CMD,QS_CWD_BEFORE_BEGIN,0,&fcp,rcmd);
      } else {
         _ftpEnQ(QE_RECV_CMD,QS_BEGIN,0,&fcp,rcmd);
      }
   }

   if( _ftpQ._length()<1 ) return;

   gftpAbort=false;
   formWid=show("_ftpProgress_form");
   if( !formWid ) {
      _message_box('Could not show form: "_ftpProgress_form"','',MB_OK|MB_ICONEXCLAMATION);
      return;
   }
   for(;;) {
      process_events(gftpAbort);
      if( gftpAbort ) {
         FtpQEvent event;

         if( _ftpQ._length()<1 ) break;
         event=_ftpQ[0];

         // Find all events in the queue that match this one and delete them.
         int i;
         for( i=0;i<_ftpQ._length();++i ) {
            if( _ftpQ[i].event==event.event ) {
               _ftpQ._deleteel(i);
            }
         }

         event.state=QS_ABORT;
         event.start=0;
         // We queue it this way because the original event might have had
         // optional data in the info field that we don't want to lose.
         _ftpQ[0]=event;
         break;
      }
      if( _ftpQ._length()<1 ) {
         // We are done
         break;
      } else {
         // If the processed event was the last event for that particular
         // connection profile, then we are done
         boolean last=true;
         int i;
         for( i=0;i<_ftpQ._length();++i ) {
            if( _ftpQ[i].fcp.profileName==fcp.profileName &&
                _ftpQ[i].fcp.instance==fcp.instance ) {
               last=false;
               break;
            }
         }
         if( last ) {
            break;
         }
      }
      _ftpQTimerCallback();
      // Yield!
      delay(1);
   }
   formWid._delete_window();

   return;
}

_command void ftpopenNew() name_info(','VSARG2_NCW|VSARG2_READ_ONLY)
{
   FtpConnProfile *fcp_p;

   int formWid=_ftpopenQFormWid();
   if( !formWid ) return;
   fcp_p=formWid.GetCurrentConnProfile();
   if( !fcp_p ) return;
   // Prompt for the new file
   _str remote_path=fcp_p->remoteCwd;

   // Remember the last filename
   _str last_path=_retrieve_value("_tbFTPOpen_form.NewRemoteFile.LastFilename");
   // Remember the last edit options for this profile
   typeless edit_options = '';
   _str arProfileName = fcp_p->profileName;
   if( arProfileName != null && arProfileName != '' ) {
      // urlencode so regex search in _retrieve_value/_append_retrieve()
      // works on profile names containing non-alphanumeric characters.
      arProfileName = urlencode(arProfileName);
      edit_options = _retrieve_value(nls("_tbFTPOpen_form.%s.NewRemoteFile.EditOptions",arProfileName));
   }

   typeless result=show("-modal _ftpNew_form",last_path,0,"New FTP File",fcp_p,edit_options);
   if( result=="" ) {
      // User cancelled
      return;
   }
   remote_path=strip(_param1);
   if( remote_path=="" ) return;
   typeless xfer_type=_param2;
   if( !isinteger(xfer_type) || xfer_type<FTPXFER_ASCII || xfer_type>FTPXFER_BINARY ) {
      xfer_type=FTPXFER_ASCII;
   }
   edit_options = _param3;

   // Remember the last filename
   _append_retrieve(0,remote_path,"_tbFTPOpen_form.NewRemoteFile.LastFilename");
   // Remember the last edit options for this profile
   if( arProfileName != null && arProfileName != '' ) {
      _append_retrieve(0,edit_options,nls("_tbFTPOpen_form.%s.NewRemoteFile.EditOptions",arProfileName));
   }

   remote_path=_ftpAbsolute(fcp_p,remote_path);
   _str local_path=_ftpRemoteToLocalPath(fcp_p,remote_path);
   if( remote_path=="" ) {
      ftpConnDisplayError(fcp_p,"Unable to create a locally mapped filename");
      return;
   }
   int i=0;
   _str path="";
   _str filename="";
   _str document_name="";
   switch( fcp_p->system ) {
   case FTPSYST_MVS:
      document_name='ftp://':+fcp_p->host;
      path=_ftpConvertMVStoSEFilename(remote_path);
      i=lastpos('/',path);
      filename=substr(path,i+1);
      path=substr(path,1,i);
      document_name=document_name:+path:+_ftpUploadCase(fcp_p,filename);
      break;
   case FTPSYST_OS400:
      document_name='ftp://':+fcp_p->host;
      path=_ftpConvertOS400toSEFilename(remote_path);
      i=lastpos('/',path);
      filename=substr(path,i+1);
      path=substr(path,1,i);
      document_name=document_name:+path:+_ftpUploadCase(fcp_p,filename);
      break;
   default:
      // Leave any path separator on
      path=_ftpStripFilename(fcp_p,remote_path,'N');
      filename=_ftpStripFilename(fcp_p,remote_path,'P');
      document_name='ftp://':+fcp_p->host;
      if( substr(remote_path,1,1)!='/' ) {
         // Must have a preceding '/' even if we are on a host
         // like VOS or VMS because we need to delimit the hostname
         // from the beginning of the path.
         document_name=document_name:+'/';
      }
      document_name=document_name:+path:+_ftpUploadCase(fcp_p,filename);
   }

   // Make sure it is not already open
   _str info=buf_match(document_name,1,"EVD");
   if( info!="" ) {
      typeless buf_id="";
      parse info with buf_id . . .;
      edit("+bi ":+buf_id);
      refresh();
      _str msg='The file "':+document_name:+'" is already open';
      ftpConnDisplayInfo(fcp_p,msg);
      return;
   }
   typeless status=edit(edit_options:+' +t ':+maybe_quote_filename(local_path));
   if( !status ) {
      // Mark this file as binary if we created it binary
      if( xfer_type==FTPXFER_BINARY ) {
         _mdi.p_child._ftpSetBinary(true);
      }
      FtpFile file;
      _mdi.p_child.docname(document_name);
      //_mdi.p_child.p_ModifyFlags |= MODIFYFLAG_FTP_NEED_TO_SAVE;
      refresh();
      // Create a "fake" place marker file that will be visible in the remote listing
      _str curr_dir="";
      _str root_dir="";
      if( fcp_p->system==FTPSYST_MVS &&
          fcp_p->remoteDir.flags&FTPDIRTYPE_MVS_VOLUME &&
          last_char(remote_path)!=')' &&
          _ftpFileEq(fcp_p,fcp_p->remoteCwd,substr(remote_path,1,length(fcp_p->remoteCwd))) ) {
         // A SDS of the current directory
         curr_dir=root_dir=fcp_p->remoteCwd;
      } else {
         curr_dir=_ftpAbsolute(fcp_p,"junk");
         curr_dir=_ftpStripFilename(fcp_p,curr_dir,'NS');
         root_dir=remote_path;
         root_dir=_ftpStripFilename(fcp_p,root_dir,'NS');
      }
      if( _ftpFileEq(fcp_p,curr_dir,root_dir) ) {
         // The new file is in the current remote working directory
         if( fcp_p->system==FTPSYST_MVS &&
             fcp_p->remoteDir.flags&FTPDIRTYPE_MVS_VOLUME &&
             last_char(remote_path)!=')' &&
             _ftpFileEq(fcp_p,fcp_p->remoteCwd,substr(remote_path,1,length(fcp_p->remoteCwd))) ) {
            // A SDS of the current directory
            filename=substr(remote_path,length(fcp_p->remoteCwd)+1);
         } else {
            filename=_ftpStripFilename(fcp_p,remote_path,'P');
         }
         file._makeempty();
         _ftpFakeFile(&file,filename,FTPFILETYPE_CREATED,0);
         _ftpInsertFile(fcp_p,file);
         formWid._UpdateSession(false);
      }
   } else {
      _str msg="Unable to open locally mapped filename";
      ftpConnDisplayError(fcp_p,msg);
   }

   return;
}

_command void ftpopenOpenLocalFiles() name_info(','VSARG2_NCW|VSARG2_READ_ONLY)
{
   FtpConnProfile *fcp_p;

   int formWid=_ftpopenQFormWid();
   if( !formWid ) return;
   fcp_p=formWid.GetCurrentConnProfile();
   if( !fcp_p ) return;

   // Prompt for local files
   _str remote_path=fcp_p->remoteCwd;
   switch( fcp_p->system ) {
   case FTPSYST_VMS:
   case FTPSYST_VMS_MULTINET:
      // Don't mess with it
      break;
   case FTPSYST_VOS:
      if( last_char(remote_path)!='>' ) {
         remote_path=remote_path:+'>';
      }
      break;
   case FTPSYST_VM:
   case FTPSYST_VMESA:
      // Dont mess with it
      break;
   case FTPSYST_MVS:
      if( substr(remote_path,1,1)=='/' ) {
         // HFS file system which mimics Unix
         if( last_char(remote_path)!='/' ) remote_path=remote_path:+'/';
      } else {
         // PDS or SDS format - Don't mess with it
      }
      break;
   case FTPSYST_OS2:
      // OS/2 is flexible about file separators. Both '/' and '\' are allowed
      _str fsep='/';
      if( pos('^[a-zA-Z]\:\\',fcp_p->remoteCwd,1,'er') ) {
         fsep='\';
      }
      if( last_char(remote_path)!=fsep ) remote_path=remote_path:+fsep;
      break;
   case FTPSYST_OS400:
      if( substr(remote_path,1,1)=='/' ) {
         // IFS file system which mimics Unix
         if( last_char(remote_path)!='/' ) remote_path=remote_path:+'/';
      } else {
         // LFS format which puts a '/' after the library name
         if( last_char(remote_path)!='/' ) remote_path=remote_path:+'/';
      }
      break;
   case FTPSYST_WINNT:
   case FTPSYST_HUMMINGBIRD:
      fsep='/';
      if( substr(remote_path,1,1)!='/' ) {
         // DOS style
         fsep="\\";
      }
      if( last_char(remote_path)!=fsep ) remote_path=remote_path:+fsep;
      break;
   case FTPSYST_NETWARE:
   case FTPSYST_MACOS:
   case FTPSYST_VXWORKS:
   case FTPSYST_UNIX:
   default:
      if( last_char(remote_path)!='/' ) remote_path=remote_path:+'/';
   }

   typeless result=_OpenDialog("-modal",
                               "Specify local filenames to map to ":+remote_path,       // Dialog Box Title
                               ALLFILES_RE,                                             // Initial Wild Cards
                               def_file_types,                                          // File Type List
                               OFN_ALLOWMULTISELECT|OFN_FILEMUSTEXIST|OFN_NOCHANGEDIR|OFN_EDIT,  // Flags
                               "",
                               "",
                               "",
                               "",
                               "?Specify local filenames to map to ":+remote_path);
   if( result=="" ) {
      // User cancelled
      return;
   }

   if( fcp_p->remoteDir.flags&FTPDIRTYPE_MVS_VOLUME && last_char(remote_path)!='.' ) {
      // This should never happen
      remote_path=remote_path:+'.';
   }

   // Make sure we do not count switches as filenames
   result=strip(result);
   _str edit_switches = "";
   while( first_char(result) == '+' || first_char(result) == '-' ) {
      _str option = parse_file(result);
      edit_switches=edit_switches" "option;
      result=strip(result,'L');
   }

   for(;;) {
      _str local_path=parse_file(result);
      local_path=strip(local_path,'B','"');
      _str filename=_strip_filename(local_path,'P');
      _str document_name="";
      _str path="";
      switch( fcp_p->system ) {
      case FTPSYST_MVS:
         if( substr(fcp_p->remoteCwd,1,1)!='/' ) {
            // PDS or SDS format
            path=strip(remote_path,'L','/');
            if( fcp_p->remoteDir.flags&FTPDIRTYPE_MVS_VOLUME ) {
               // SDS
               document_name='ftp://':+fcp_p->host;
               document_name=document_name:+'//':+remote_path:+_ftpUploadCase(fcp_p,filename);
            } else {
               // PDS member
               document_name='ftp://':+fcp_p->host;
               document_name=document_name:+'//':+remote_path:+'/':+_ftpUploadCase(fcp_p,filename);
            }
         } else {
            // HFS file system which mimics Unix
            document_name='ftp://':+fcp_p->host;
            if( substr(remote_path,1,1)!='/' ) {
               document_name=document_name:+'/';
            }
            document_name=document_name:+remote_path:+_ftpUploadCase(fcp_p,filename);
         }
         break;
      case FTPSYST_OS400:
         if( substr(fcp_p->remoteCwd,1,1)!='/' ) {
            // LFS format
            path=strip(remote_path,'L','/');
            document_name='ftp://':+fcp_p->host;
            document_name=document_name:+'//':+remote_path:+_ftpUploadCase(fcp_p,filename);
         } else {
            // IFS file system which mimics Unix
            document_name='ftp://':+fcp_p->host;
            if( substr(remote_path,1,1)!='/' ) {
               document_name=document_name:+'/';
            }
            document_name=document_name:+remote_path:+_ftpUploadCase(fcp_p,filename);
         }
         break;
      default:
         document_name='ftp://':+fcp_p->host;
         if( substr(remote_path,1,1)!='/' ) {
            // Must have a preceding '/' even if we are on a host
            // like VOS or VMS because we need to delimit the hostname
            // from the beginning of the path.
            document_name=document_name:+'/';
         }
         document_name=document_name:+remote_path:+_ftpUploadCase(fcp_p,filename);
      }
      typeless status=edit(edit_switches" "maybe_quote_filename(local_path));
      if( !status ) {
         FtpFile file;
         _mdi.p_child.docname(document_name);
         _mdi.p_child.p_ModifyFlags |= MODIFYFLAG_FTP_NEED_TO_SAVE;
         refresh();
         // Create a "fake" place marker file that will be visible in the remote listing
         file._makeempty();
         _ftpFakeFile(&file,filename,FTPFILETYPE_CREATED,0);
         _ftpInsertFile(fcp_p,file);
      }
      if( result=="" ) break;
   }
   formWid._UpdateSession(false);

   return;
}

#if 0
void __ftpopenChangeDirCB( ftpQEvent_t* pEvent )
{
   ftpQEvent_t event;
   ftpConnProfile_t fcp;

   event= *((ftpQEvent_t *)(pEvent));

   fcp=event.fcp;   // Make a copy

   if( !_ftpQEventIsError(event) && !_ftpQEventIsAbort(event) ) {
      formWid=_ftpQFormWid();
      if( !formWid ) return;
      formWid._UpdateSession(true);
      return;
   }

   return;
}
#endif

void __ftpopenCwdCB( FtpQEvent* pEvent );
void __ftpopenCwdLinkCB( FtpQEvent* pEvent );
_command void ftpopenChangeDir(_str cwd="", typeless isOS400LFS="", typeless isLink="") name_info(','VSARG2_NCW|VSARG2_READ_ONLY)
{
   FtpConnProfile *fcp_p;
   FtpConnProfile fcp;

   int formWid=_ftpopenQFormWid();
   if( !formWid ) return;
   fcp_p=formWid.GetCurrentConnProfile();
   if( !fcp_p ) return;
   boolean os400_lfs = (isOS400LFS!="" && isOS400LFS);
   if( cwd=="" ) {
      // Prompt for the remote directory
      typeless result=show("-modal _ftpChangeDir_form","Change remote directory","",fcp_p);
      if( result=="" ) {
         // User cancelled
         return;
      }
      cwd=_param1;
      os400_lfs= (fcp_p->system==FTPSYST_OS400 && _param2!=0);
      if( cwd=="" ) return;
   }
   boolean is_link = ( isLink!="" && isLink );

   // Make a copy
   fcp = *fcp_p;

   _ftpopenMaybeReconnect(&fcp);

   if( fcp.serverType==FTPSERVERTYPE_SFTP ) {
      if( is_link ) {
         fcp.postedCb=(typeless)__sftpopenCwdLinkCB;
      } else {
         fcp.postedCb=(typeless)__sftpopenCwdCB;
      }
      _ftpSyncEnQ(QE_SFTP_STAT,QS_BEGIN,0,&fcp,cwd);
   } else {
      // FTP
      if( is_link ) {
         fcp.postedCb=(typeless)__ftpopenCwdLinkCB;
      } else if( cwd == ".." ) {
         fcp.postedCb=(typeless)__ftpopenCdupCB;
      } else {
         fcp.postedCb=(typeless)__ftpopenCwdCB;
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
               boolean change_dir= (!_ftpFileEq(&fcp,substr(fcp.remoteCwd,1,length("/QSYS.LIB")),"/QSYS.LIB"));
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

   return;
}

/**
 * Used from context menu to open a symbolic link.
 */
_command void ftpopenChangeDirLink(_str filename="") name_info(','VSARG2_NCW|VSARG2_READ_ONLY)
{
   // Get rid of the link part
   parse filename with filename '->' .;
   filename=strip(filename);
   ftpopenChangeDir(filename,false,true);
}

void __ftpopenMkDirCB( FtpQEvent* pEvent )
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

   _str curr_dir="";
   _str root_dir="";
   _str new_dir="";
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

   // _UpdateSession() will take care of asynchronous refresh
   formWid=_ftpopenQFormWid();
   if( !formWid ) return;
   if( fcp.autoRefresh ) {
      formWid._UpdateSession(true);
   } else {
      // Auto refresh is OFF, so fake the directory entry
      if( new_dir!="" ) {
         FtpFile file;
         file._makeempty();
         _ftpFakeFile(&file,new_dir,FTPFILETYPE_DIR|FTPFILETYPE_CREATED,0);
         _ftpInsertFile(fcp_p,file);
         formWid._UpdateSession(false);
      }
   }

   return;
}

_command void ftpopenMkDir(_str path="") name_info(','VSARG2_NCW|VSARG2_READ_ONLY)
{
   FtpConnProfile *fcp_p;
   FtpConnProfile fcp;

   int formWid=_ftpopenQFormWid();
   if( !formWid ) return;
   fcp_p=formWid.GetCurrentConnProfile();
   if( !fcp_p ) return;
   if( path=="" ) {
      // Prompt for the remote directory to make
      typeless result=show("-modal _textbox_form","Make remote directory",0,"","?Type the remote directory you would like to make","","","Directory");
      if( result=="" ) {
         // User cancelled
         return;
      }
      path=_param1;
      if( path=="" ) return;
   }
   fcp= *fcp_p;   // Make a copy

   _ftpopenMaybeReconnect(&fcp);

   // Note: FTP _and_ SFTP can use the same callback in this case
   fcp.postedCb=(typeless)__ftpopenMkDirCB;
   if( fcp.serverType==FTPSERVERTYPE_SFTP ) {
      _ftpSyncEnQ(QE_SFTP_MKDIR,QS_BEGIN,0,&fcp,path);
   } else {
      // FTP
      _ftpSyncEnQ(QE_MKD,QS_BEGIN,0,&fcp,path);
   }

   return;
}

/**
 * Used by ftpopenDelFile() and its callback functions to refresh the remote
 * side of the FTP open tab during a recursive delete. This allows the user
 * to see what is going on.
 */
void _ftpopenRefresh(FtpConnProfile *fcp_p)
{
   int formwid,tree_wid,cwd_wid;

   // Refresh the local and remote listings so the user sees what is going on
   formwid=_ftpopenQFormWid();
   if( formwid ) {
      tree_wid=formwid._find_control("_ctl_remote_dir");
      cwd_wid=formwid._find_control("_ctl_remote_cwd");
      if( tree_wid ) {
         tree_wid._ftpopenRefreshDir(fcp_p);
      }
      if( cwd_wid ) {
         boolean old_gchangeremotecwd_allowed=_ftpopenChangeRemoteCwdOnOff();
         _ftpopenChangeRemoteCwdOnOff(0);
         cwd_wid.p_text=fcp_p->remoteCwd;
         _ftpopenChangeRemoteCwdOnOff(old_gchangeremotecwd_allowed);
      }
   }
}

void __ftpopenDelFile2CB( FtpQEvent* pEvent, typeless isPopping="" );
void __ftpopenDelFile3CB( FtpQEvent* pEvent );
void __ftpopenDelFile1CB( FtpQEvent* pEvent )
{
   FtpQEvent event;
   FtpConnProfile fcp;
   FtpConnProfile *fcp_p;
   FtpFile file;
   int formWid;
   _str filename="";

   event= *((FtpQEvent *)(pEvent));
   fcp=event.fcp;
   fcp.postedCb=null;

   if( _ftpQEventIsError(event) || _ftpQEventIsAbort(event) ) {
      // Check for "fake" file/directory
      formWid=_ftpopenQFormWid();
      if( !formWid ) return;
      fcp_p=_ftpIsCurrentConnProfile(fcp.profileName,fcp.instance);
      if( !fcp_p ) return;   // This should never happen
      filename="";
      if( !event.info._isempty() ) {
         filename=event.info[0];
      }
      if( filename!="" ) {
         int i,len=fcp_p->remoteDir.files._length();
         for( i=0;i<len;++i ) {
            file=fcp_p->remoteDir.files[i];
            if( filename==file.filename && file.type&FTPFILETYPE_FAKED ) {
               // This is a faked file/directory, so delete it because
               // it never existed in the first place.
               if( event.event==QE_DELE && !(file.type&FTPFILETYPE_DIR) ) {
                  // File
                  fcp_p->remoteDir.files._deleteel(i);
               } else if( event.event==QE_RMD && file.type&FTPFILETYPE_DIR ) {
                  // Directory
                  fcp_p->remoteDir.files._deleteel(i);
               }
            }
         }
      }
      // Make sure that we check the fcp that was passed in with the event,
      // not the original connection profile's.
      if( fcp.autoRefresh ) {
         formWid._UpdateSession(true);
      } else {
         formWid._UpdateSession(false);
      }
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
            _str localcwd="";
            _str remotecwd="";
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
               _ftpopenProgressCB("DELE ":+filename,0,0);
               fcp.postedCb=(typeless)__ftpopenDelFile1CB;
               _ftpSyncEnQ(QE_DELE,QS_BEGIN,0,&fcp,filename);
               return;
            } else if( file.type&FTPFILETYPE_DIR ) {
               // Directory
               if( fcp.recurseDirs ) {
                  // Set this now so it is easy to pick up in
                  // __ftpopenDelFile2CB() when we push.
                  //fcp.LocalCWD=local_path;
                  // We are pushing another directory, so push the directory name
                  // onto the .extra stack so we know which directory to RMD after
                  // we pop it.
                  _str dirnames[];
                  dirnames= (_str [])fcp.extra;
                  dirnames[dirnames._length()]=filename;
                  fcp.extra=dirnames;
                  // __ftpopenDelFile2CB() processes the CWD/PWD and listing
                  fcp.postedCb=(typeless)__ftpopenDelFile2CB;
                  _ftpSyncEnQ(QE_CWD,QS_BEGIN,0,&fcp,filename);
                  return;
               } else {
                  // Attempt to remove the directory
                  _ftpopenProgressCB("RMD ":+filename,0,0);
                  fcp.postedCb=(typeless)__ftpopenDelFile1CB;
                  _ftpSyncEnQ(QE_RMD,QS_BEGIN,0,&fcp,filename);
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
         // __ftpopenDelFile3CB() processes the CWD/PWD
         fcp.postedCb=(typeless)__ftpopenDelFile3CB;
         _ftpSyncEnQ(QE_CWD,QS_BEGIN,0,&fcp,cwd);
         return;
      }
   }

   formWid=_ftpopenQFormWid();
   if( formWid ) {
      if( fcp.autoRefresh ) {
         formWid._UpdateSession(true);
      } else {
         formWid._UpdateSession(false);
      }
   }

   return;
}

/**
 * Callback used when changing directory and retrieving a listing.
 */
void __ftpopenDelFile2CB( FtpQEvent* pEvent, typeless isPopping="" )
{
   FtpQEvent event;
   FtpRecvCmd rcmd;
   FtpConnProfile fcp;
   FtpConnProfile *fcp_p;
   boolean popping;

   event= *((FtpQEvent *)(pEvent));
   fcp=event.fcp;

   // Indicates that we are in the middle of popping back to the previous
   // directory. No need to do a listing.
   popping= (isPopping!="");

   _str cmd="";
   _str cwd="";
   _str msg="";
   typeless status=0;

   if( _ftpQEventIsError(event) || _ftpQEventIsAbort(event) ) {
      if( !_ftpQEventIsError(event) ) {
         // User aborted
         return;
      }
      boolean do_cleanup=true;
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
                  // __ftpopenDelFile3CB() processes the CWD/PWD
                  fcp.postedCb=(typeless)__ftpopenDelFile3CB;
                  _ftpSyncEnQ(QE_CWD,QS_BEGIN,0,&fcp,cwd);
                  return;
               }
            }
         } else if( event.event==QE_CWD ) {
            cwd=event.info[0];
            msg="Failed to change directory to ":+cwd:+
                "\n\nContinue?";
            status=_message_box(msg,"FTP",MB_YESNO);
            if( status==IDYES ) {
               // fcp.LocalCWD was set in __ftpopenDelFile1CB(), so
               // set it back.
               fcp.localCwd=fcp.dir_stack[fcp.dir_stack._length()-1].localcwd;
               event._makeempty();
               event.fcp=fcp;
               event.event=QE_NONE;
               event.state=QS_NONE;
               event.start=0;
               // __ftpopenDelFile1CB() processes the next file/directory
               __ftpopenDelFile1CB(&event);
               return;
            }
         }
      }
      if( do_cleanup ) {
         // If we got here then we need to clean up
         int formWid=_ftpopenQFormWid();
         // Update remote session back to original and stop
         if( fcp.remoteCwd!=fcp.dir_stack[0].remotecwd ) {
            cwd=fcp.dir_stack[0].remotecwd;
            if( fcp.system==FTPSYST_MVS ) {
               if( substr(cwd,1,1)!='/' ) {
                  // Make it absolute for MVS
                  cwd="'":+cwd:+"'";
               }
            }
            ftpopenChangeDir(cwd);
         } else {
            if( formWid ) formWid._UpdateSession(false);
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
         boolean pasv;
         _str cmdargv[];
         _str dest;
         _str datahost;
         _str dataport;
         int  size;
         pfnProgressCallback_tp ProgressCB;
      } RecvCmd_t;
      */
      fcp.postedCb=(typeless)__ftpopenDelFile2CB;
      boolean pasv= (fcp.useFirewall && fcp.global_options.fwenable && fcp.global_options.fwpasv );
      _str cmdargv[];
      cmdargv._makeempty();
      cmdargv[0]="LIST";
      if( fcp.resolveLinks ) {
         cmdargv[cmdargv._length()]="-L";
      }
      _str dest=mktemp();
      if( dest=="" ) {
         msg="Unable to create temp file for remote directory listing";
         ftpConnDisplayError(&fcp,msg);
         return;
      }
      _str datahost="";
      _str dataport="";
      int size=0;
      int xfer_type=FTPXFER_ASCII;   // Always transfer listings ASCII
      rcmd.pasv=pasv;
      rcmd.cmdargv=cmdargv;
      rcmd.dest=dest;
      rcmd.datahost=datahost;
      rcmd.dataport=dataport;
      rcmd.size=size;
      rcmd.xfer_type=xfer_type;
      rcmd.progressCb=_ftpopenProgressCB;
      _ftpSyncEnQ(QE_RECV_CMD,QS_BEGIN,0,&fcp,rcmd);
      return;
   }

   if( !popping ) {
      rcmd= (FtpRecvCmd)event.info[0];
      if( _ftpdebug&FTPDEBUG_SAVE_LIST ) {
         // Make a copy of the raw listing
         _str temp_path=_temp_path();
         if( last_char(temp_path)!=FILESEP ) temp_path=temp_path:+FILESEP;
         _str list_filename=temp_path:+"$list";
         copy_file(rcmd.dest,list_filename);
      }
      status=_ftpParseDir(&fcp,fcp.remoteDir,fcp.remoteFileFilter,rcmd.dest);
      typeless status2=delete_file(rcmd.dest);
      if( status2 && status2!=FILE_NOT_FOUND_RC && status2!=PATH_NOT_FOUND_RC ) {
         msg='Warning: Could not delete temp file "':+rcmd.dest:+'".  ':+_ftpGetMessage(status2);
         ftpConnDisplayWarning(&fcp,msg);
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
         // __ftpopenDelFile3CB() processes the CWD/PWD
         fcp.postedCb=(typeless)__ftpopenDelFile3CB;
         _ftpSyncEnQ(QE_CWD,QS_BEGIN,0,&fcp,cwd);
         return;
      } else {
         #if 1
         // Refresh the remote listing so the user sees what is going on
         _ftpopenRefresh(&fcp);
         #endif

         // Note that fcp.LocalCWD was set in __ftpopenDelFile1CB() in
         // anticipation of the push.
         _ftpDirStackPush(fcp.localCwd,fcp.remoteCwd,&fcp.remoteDir,fcp.dir_stack);
         fcp.postedCb=null;
         event._makeempty();
         event.fcp=fcp;
         event.event=QE_NONE;
         event.state=QS_NONE;
         event.start=0;
         // __ftpopenDelFile1CB() processes the next file directory
         __ftpopenDelFile1CB(&event);
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
         fcp.postedCb=(typeless)__ftpopenDelFile3CB;
         _ftpSyncEnQ(QE_RMD,QS_BEGIN,0,&fcp,dirname);
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
      _ftpopenRefresh(&fcp);
   }
   #endif

   // __ftpopenDelFile1CB() processes the next file directory
   __ftpopenDelFile1CB(&event);

   return;
}

/**
 * Callback used when popping a directory.
 */
void __ftpopenDelFile3CB( FtpQEvent* pEvent )
{
   // The second argument tells __ftpopenDelFile2CB() that we are
   // popping the top directory off the stack. No need to do a listing.
   __ftpopenDelFile2CB(pEvent,1);

   return;
}

_command void ftpopenDelFile() name_info(','VSARG2_NCW|VSARG2_READ_ONLY)
{
   FtpConnProfile *fcp_p;
   FtpConnProfile fcp;
   FtpDirectory dir;
   FtpFile file;
   FtpQEvent event;

   int profileWid=0, remoteWid=0;
   int formWid=_ftpopenQFormWid();
   if( !formWid ) return;
   if( _ftpopenFindAllControls(formWid,profileWid,remoteWid) ) return;
   fcp_p=formWid.GetCurrentConnProfile();
   if( !fcp_p ) return;

   nofselected := remoteWid._TreeGetNumSelectedItems();
   if( !nofselected ) return;
   fcp= *fcp_p;   // Make a copy

   // Check for directories selected
   boolean dirs=false;
   int idx=remoteWid._TreeGetNextSelectedIndex(1,auto treeSelectInfo);
   while( idx>=0 ) {
      _str caption=remoteWid._TreeGetCaption(idx);
      _str filename, size, date, time, attribs;
      parse caption with filename "\t" size "\t" date "\t" time "\t" attribs;
      if( filename!=".." ) {
         _str userinfo=remoteWid._TreeGetUserInfo(idx);
         userinfo=lowcase(userinfo);
         // Filename OR directory
         if( pos("d",userinfo) ) {
            dirs=true;
            break;
         }
      }
      idx=remoteWid._TreeGetNextSelectedIndex(0,treeSelectInfo);
   }

   _str msg="Delete ":+nofselected:+" files/directories";
   if( dirs ) {
      msg=msg:+" and their contents";
   }
   msg=msg:+"?";
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
   int info;
   for(ff:=1;;ff=0) {
      int index=remoteWid._TreeGetNextSelectedIndex(ff,info);
      if( index<0 ) break;
      _str caption=remoteWid._TreeGetCaption(index);
      _str filename="";
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
      file.year=0;

      _str userinfo=remoteWid._TreeGetUserInfo(index);
      userinfo=lowcase(userinfo);
      file.type=0;
      if( pos("d",userinfo) ) {
         file.type |= FTPFILETYPE_DIR;
      }
      if( pos("l",userinfo) ) {
         file.type |= FTPFILETYPE_LINK;
      }
      dir.files[dir.files._length()]=file;
   }

   _ftpopenMaybeReconnect(&fcp);

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
      __sftpopenDelFile1CB(&event);
   } else {
      // FTP
      __ftpopenDelFile1CB(&event);
   }

   return;
}

void _ctl_remote_dir.'DEL'()
{
   ftpopenDelFile();

   return;
}

void __ftpopenRenameFileCB( FtpQEvent* pEvent )
{
   FtpQEvent event;
   FtpConnProfile fcp;
   FtpConnProfile *fcp_p;

   event= *((FtpQEvent *)(pEvent));

   fcp=event.fcp;
   if( _ftpQEventIsError(event) || _ftpQEventIsAbort(event) ) {
      // Nothing to do
      return;
   }

   int formWid=_ftpopenQFormWid();
   if( !formWid ) return;
   // _UpdateSession() will take care of asynchronous refresh
   if( fcp.autoRefresh ) {
      formWid._UpdateSession(true);
   } else {
      // Auto refresh is OFF, so fake the directory entry
      fcp_p=_ftpIsCurrentConnProfile(fcp.profileName,fcp.instance);
      if( !fcp_p ) return;   // This should never happen
      _str rnfr="";
      _str rnto="";
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
         boolean moved= !_ftpFileEq(fcp_p,path_rnfr,path_rnto);
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
         formWid._UpdateSession(false);
      }
   }

   return;
}

_command void ftpopenRenameFile() name_info(','VSARG2_NCW|VSARG2_READ_ONLY)
{
   FtpConnProfile *fcp_p;
   FtpConnProfile fcp;
   int profileWid=0, remoteWid=0;
   int formWid=_ftpopenQFormWid();
   if( !formWid ) return;
   if( _ftpopenFindAllControls(formWid,profileWid,remoteWid) ) return;
   fcp_p=formWid.GetCurrentConnProfile();
   if( !fcp_p ) return;

   nofselected := remoteWid._TreeGetNumSelectedItems();
   if( !nofselected || nofselected>1 ) return;
   int idx=remoteWid._TreeCurIndex();
   if( idx<0 ) return;
   _str caption=remoteWid._TreeGetCaption(idx);
   _str rnfr="";
   parse caption with rnfr "\t" .;
   if( rnfr==".." ) {
      return;
   } else {
      _str info=remoteWid._TreeGetUserInfo(idx);
      info=lowcase(info);
      if( (fcp_p->system==FTPSYST_UNIX || (fcp_p->system==FTPSYST_MVS && substr(fcp_p->remoteCwd,1,1)=='/')) &&
          pos("l",info) ) {
         // Get rid of the link part
         parse rnfr with rnfr '->' .;
         rnfr=strip(rnfr);
      }
      typeless status=show("-modal _textbox_form","Rename ":+rnfr:+" to...",0,"","?Specify a filename to rename to","","","Rename to");
      if( status=="" ) {
         // User cancelled
         return;
      }
      _str rnto=_param1;
      if( rnto=="" ) {
         return;
      }

      // Make a copy
      fcp = *fcp_p;

      _ftpopenMaybeReconnect(&fcp);

      // Note: FTP _and_ SFTP can use the same callback in this case
      fcp.postedCb=(typeless)__ftpopenRenameFileCB;
      if( fcp.serverType==FTPSERVERTYPE_SFTP ) {
         _ftpSyncEnQ(QE_SFTP_RENAME,QS_BEGIN,0,&fcp,rnfr,rnto);
      } else {
         // FTP
         _ftpSyncEnQ(QE_RENAME,QS_BEGIN,0,&fcp,rnfr,rnto);
      }
      return;
   }
}

void __ftpopenCustomCmdCB( FtpQEvent* pEvent )
{
   FtpQEvent event;
   FtpConnProfile fcp;
   FtpCustomCmd ccmd;

   event= *((FtpQEvent *)(pEvent));

   fcp=event.fcp;
   fcp.postedCb=(typeless)__ftpopenCustomCmdCB;   // Paranoid
   ccmd=event.info[0];
   if( !_ftpQEventIsError(event) && !_ftpQEventIsAbort(event) ) {
      _str pattern=ccmd.pattern;
      if( pos('%f',pattern) ) {
         int idx=_ftpTodoFindNext();
         if( idx>=0 ) {
            _str caption="";
            _ftpTodoGetCaption(caption);
            _str info="";
            _ftpTodoGetUserInfo(info);
            info=lowcase(info);
            _str filename, size, date, time, attribs;
            parse caption with filename "\t" size "\t" date "\t" time "\t" attribs;
            if( (fcp.system==FTPSYST_UNIX || (fcp.system==FTPSYST_MVS && substr(fcp.remoteCwd,1,1)=='/')) &&
                pos("l",info) ) {
               // Get rid of the link part
               parse filename with filename '->' .;
               filename=strip(filename);
            }
            _str cmdline=stranslate(pattern,filename,'%f','');
            if( cmdline=="" ) {
               _str msg='Your custom command evaluates to ""';
               ftpConnDisplayError(&fcp,msg);
               return;
            }
            ccmd.cmdargv[0]=cmdline;
            _ftpEnQ(QE_CUSTOM_CMD,QS_BEGIN,0,&fcp,ccmd);
            return;
         }
         // That was the last one
      } else {
         // The command was only sent once, so we are done
      }
   }

   if( pos('%f',ccmd.pattern) ) {
      // We were operating on files, so refresh the remote listing
      int formWid=_ftpopenQFormWid();
      if( formWid ) {
         formWid._UpdateSession(true);
      }
   }

   return;
}

_command void ftpopenCustomCmd() name_info(','VSARG2_NCW|VSARG2_READ_ONLY)
{
   FtpConnProfile *fcp_p;
   FtpConnProfile fcp;
   int formWid;
   FtpCustomCmd ccmd;

   formWid=_ftpopenQFormWid();
   if( !formWid ) return;
   int treeWid=formWid._find_control("_ctl_remote_dir");
   if( !treeWid ) return;
   fcp_p=formWid.GetCurrentConnProfile();
   if( !fcp_p ) return;
   if( fcp_p->serverType!=FTPSERVERTYPE_FTP ) {
      _str msg="Custom commands not supported for this server type";
      ftpConnDisplayError(fcp_p,msg);
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
   fcp= *fcp_p;

   _ftpopenMaybeReconnect(&fcp);

   ccmd._makeempty();
   ccmd.pattern=pattern;
   fcp.postedCb=(typeless)__ftpopenCustomCmdCB;
   if( pos('%f',pattern) ) {
      // We are acting on selected files in the tree
      nofselected := treeWid._TreeGetNumSelectedItems();
      if( nofselected ) {
         treeWid._ftpTodoGetList();
         int idx=_ftpTodoFindNext();
         if( idx>=0 ) {
            _str caption="";
            _ftpTodoGetCaption(caption);
            _str info="";
            _ftpTodoGetUserInfo(info);
            info=lowcase(info);
            _str filename, size, date, time, attribs;
            parse caption with filename "\t" size "\t" date "\t" time "\t" attribs;
            if( (fcp.system==FTPSYST_UNIX || (fcp.system==FTPSYST_MVS && substr(fcp.remoteCwd,1,1)=='/')) &&
                pos("l",info) ) {
               // Get rid of the link part
               parse filename with filename '->' .;
               filename=strip(filename);
            }
            _str cmdline=stranslate(pattern,filename,'%f','');
            if( cmdline=="" ) {
               _str msg='Your custom command evaluates to ""';
               ftpConnDisplayError(&fcp,msg);
               return;
            }
            ccmd.cmdargv[0]=cmdline;
            _ftpSyncEnQ(QE_CUSTOM_CMD,QS_BEGIN,0,&fcp,ccmd);
         }
      } else {
         _str msg="Your custom command requires atleast one file to be selected";
         ftpConnDisplayError(&fcp,msg);
      }
   } else {
      // Send the command line once
      ccmd.cmdargv[0]=pattern;
      _ftpSyncEnQ(QE_CUSTOM_CMD,QS_BEGIN,0,&fcp,ccmd);
   }

   return;
}

_command void ftpopenFilter() name_info(','VSARG2_NCW|VSARG2_READ_ONLY)
{
   FtpConnProfile *fcp_p;
   FtpConnProfile fcp;

   int formWid=_ftpopenQFormWid();
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

   _ftpopenMaybeReconnect(&fcp);
   formWid._UpdateSession(true);

   return;
}

_command void ftpopenRefreshSession() name_info(','VSARG2_NCW|VSARG2_READ_ONLY)
{
   FtpConnProfile *fcp_p;
   FtpConnProfile fcp;

   fcp_p=ftpopenGetCurrentConnProfile();
   if( fcp_p ) {
      int formWid = _ftpopenQFormWid();
      if( formWid!=0 ) {
         // Make a copy
         fcp = *fcp_p;
         _ftpopenMaybeReconnect(&fcp);
         formWid._UpdateSession(true);
      }
   }
}

_command void ftpopenAutoRefresh() name_info(','VSARG2_NCW|VSARG2_READ_ONLY)
{
   FtpConnProfile *fcp_p;
   FtpConnProfile fcp;
   int formWid;

   formWid=_ftpopenQFormWid();
   if( !formWid ) return;
   fcp_p=formWid.GetCurrentConnProfile();
   if( !fcp_p ) return;
   // Toggle AutoRefresh
   fcp_p->autoRefresh= !(fcp_p->autoRefresh);
   if( fcp_p->autoRefresh ) {
      // AutoRefresh was just turned ON, so force a refresh

      // Make a copy
      fcp = *fcp_p;
      _ftpopenMaybeReconnect(&fcp);
      formWid._UpdateSession(true);
   }

   return;
}

_command void ftpopenHScrollbar() name_info(','VSARG2_NCW|VSARG2_READ_ONLY)
{
   int profileWid=0, treeWid=0;
   int formWid=_ftpopenQFormWid();
   if( !formWid ) return;
   if( _ftpopenFindAllControls(formWid,profileWid,treeWid) ) return;
   int scroll_bars=treeWid.p_scroll_bars;
   if( scroll_bars&SB_HORIZONTAL ) {
      // Turn horizontal scroll bar OFF, turn popup ON
      treeWid.p_scroll_bars &= ~(SB_HORIZONTAL);
      treeWid.p_delay=0;
   } else {
      // Turn horizontal scroll bar ON, turn popup OFF
      treeWid.p_scroll_bars |= SB_HORIZONTAL;
      treeWid.p_delay= -1;
   }

   // Remember horizontal scroll bar settings.
   // Must do this here because exiting the editor does not call a control's
   // ON_DESTROY event.
   _append_retrieve(0,_ctl_remote_dir.p_scroll_bars,"_tbFTPOpen_form._ctl_remote_dir.p_scroll_bars");

   return;
}

_command void ftpopenViewLog() name_info(','VSARG2_NCW|VSARG2_READ_ONLY)
{
   FtpConnProfile *fcp_p;

   fcp_p=GetCurrentConnProfile();
   if( !fcp_p ) return;
   show("-modal -xy _ftpLog_form",fcp_p,fcp_p->host);

   return;
}

void _ctl_remote_dir.context()
{
   int x=0;
   int y=0;
   _map_xy(p_window_id,0,x,y,SM_PIXEL);
   _ctl_remote_dir.call_event(x,y,_ctl_remote_dir,RBUTTON_UP,'W');
}

/**
 * Use this to keep track of the current item, selected item,
 * scroll position, working directory, profile, and instance.
 * This is used to keep track of whether we need to restore
 * the current item and scroll position in the current remote
 * directory listing.
 */
void _ctl_remote_dir.on_change(int reason)
{
   if( !_ftpopenChangeRemoteDirOnOff() ) return;

   _ftpRemoteSavePos();
   //say('reason='reason'  'REMOTETREEPOS);

   return;
}

void _ctl_remote_dir.rbutton_down()
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
      int state=0, bm1=0, bm2=0, flags=0;
      if( firstidx>=0 ) _TreeGetInfo(firstidx,state,bm1,bm2,flags,firstline);
      int lastline=-1;
      if( lastidx>=0 ) _TreeGetInfo(lastidx,state,bm1,bm2,flags,lastline);
      int line=0;
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

void _ctl_remote_dir.rbutton_up(int x=-1,int y=-1)
{
   FtpConnProfile *fcp_p;
   int formWid;

   _str menu_name="_FTPOpen_menu";
   int idx=find_index(menu_name,oi2type(OI_MENU));
   if( !idx ) {
      return;
   }
   int mh=p_active_form._menu_load(idx,'P');
   if( mh<0) {
      _message_box('Unable to load menu: "':+menu_name:+'"','',MB_OK|MB_ICONEXCLAMATION);
      return;
   }

   formWid=_ftpopenQFormWid();
   if( !formWid ) return;
   int treeWid=formWid._find_control("_ctl_remote_dir");
   if( !treeWid ) return;   // Should never happen
   fcp_p=formWid.GetCurrentConnProfile();

   // If a remote file/directory is not selected then disable file operations
   int noffiles=0;
   int nofdirs=0;
   int noflinks=0;
   nofselected := treeWid._TreeGetNumSelectedItems();
   if( nofselected>0 ) {
      idx=treeWid._TreeGetNextSelectedIndex(1,auto treeSelectInfo);
      while( idx>=0 ) {
         _str caption=treeWid._TreeGetCaption(idx);
         _str filename, size, date, time, attribs;
         parse caption with filename "\t" size "\t" date "\t" time "\t" attribs;
         if( filename!=".." ) {
            _str userinfo=treeWid._TreeGetUserInfo(idx);
            userinfo=lowcase(userinfo);
            // Filename
            if( pos("f",userinfo) ) {
               ++noffiles;
            }
            if( pos("d",userinfo) ) {
               ++nofdirs;
            }
            if( pos("l",userinfo) ) {
               ++noflinks;
            }
         }
         idx=treeWid._TreeGetNextSelectedIndex(0,treeSelectInfo);
      }
   }
   // fcp_p should always be non-null if we got here
   if( fcp_p ) {
      if( fcp_p->autoRefresh ) {
         _menu_set_state(mh,"ftpopenAutoRefresh",MF_CHECKED,'M');
      } else {
         _menu_set_state(mh,"ftpopenAutoRefresh",MF_UNCHECKED,'M');
      }
   }
   if( noffiles==0 && nofdirs==0 ) {
      _menu_set_state(mh,"ftpopenDelFile",MF_GRAYED,'M');
   }
   if( noffiles==0 ) {
      if( nofselected==1 && noflinks==nofselected ) {
         // A link to a directory or file is the only thing
         // selected, so be smart and try to open it.
         // ftpopenChangeDirLink() will try both the directory
         // and the file case.
         int index = treeWid._TreeGetNextSelectedIndex(1,auto treeSelectInfo);
         _str item = treeWid._TreeGetCaption(index);
         _str filename;
         parse item with filename "\t" .;
         int flags;
         _str caption;
         _menu_get_state(mh,"ftpopenOpen",flags,'M',caption);
         _menu_set_state(mh,"ftpopenOpen",flags,'M',caption,"ftpopenChangeDirLink "filename);
      } else {
         _menu_set_state(mh,"ftpopenOpen",MF_GRAYED,'M');
      }
   }
   if( (noffiles+nofdirs)!=1 ) {
      _menu_set_state(mh,"ftpopenRenameFile",MF_GRAYED,'M');
   }
   if( noflinks==0 ) {
      _menu_set_state(mh,"ftpopenOpenLinks",MF_GRAYED,'M');
   }
   if( fcp_p && fcp_p->serverType!=FTPSERVERTYPE_FTP ) {
      _menu_set_state(mh,"ftpopenCustomCmd",MF_GRAYED,'M');
   }
   int on=treeWid.p_scroll_bars&SB_HORIZONTAL;
   if( on ) {
      _menu_set_state(mh,"ftpopenHScrollbar",MF_CHECKED,'M');
   } else {
      _menu_set_state(mh,"ftpopenHScrollbar",MF_UNCHECKED,'M');
   }

   if (x==y && x==-1) {
      x=VSDEFAULT_INITIAL_MENU_OFFSET_X;y=VSDEFAULT_INITIAL_MENU_OFFSET_Y;
      x=mou_last_x('M')-x;y=mou_last_y('M')-y;
      _lxy2dxy(p_scale_mode,x,y);
      _map_xy(p_window_id,0,x,y,SM_PIXEL);
   }
   // Show the menu:
   int flags=VPM_LEFTALIGN|VPM_RIGHTBUTTON;
   int status=_menu_show(mh,flags,x,y);
   _menu_destroy(mh);
}

void _ctl_remote_dir.'F5'()
{
   ftpopenRefreshSession();

   return;
}

// This expects the active window to be a combo box
void _ftpopenFillCwdHistory(boolean set_textbox)
{
   FtpConnProfile *fcp_p = GetCurrentConnProfile();
   if( !fcp_p ) {
      // This should never happen
      return;
   }

   _ftpopenChangeRemoteCwdOnOff(0);
   _str cwd = p_text;
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
   _ftpopenChangeRemoteCwdOnOff(1);
}

void _ftpCwdHistoryAddRemove_ftpopen(typeless fromFormWid)
{
   int formWid = _ftpopenQFormWid();
   if( !formWid ) {
      return;
   }
   int wid = formWid._find_control('_ctl_remote_cwd');
   wid._ftpopenFillCwdHistory(false);
}

void _ctl_remote_cwd.on_change(int reason)
{
   FtpConnProfile *fcp_p;
   FtpConnProfile fcp;

   if( !_ftpopenChangeRemoteCwdOnOff() ) {
      return;
   }
   if( reason==CHANGE_OTHER ) {
      // User probably typing in a new directory
      return;
   }

   fcp_p=GetCurrentConnProfile();
   if( !fcp_p ) return;   // This should never happen

   _str old_RemoteCWD=fcp_p->remoteCwd;
   if( old_RemoteCWD=="" ) {
      // This should never happen
      old_RemoteCWD='/';
   }
   _str cwd=p_text;
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
   boolean os400_lfs=false;
   if( fcp_p->system==FTPSYST_OS400 ) {
      if( substr(fcp_p->remoteCwd,1,1)=='/' && substr(cwd,1,1)!='/' ) {
         os400_lfs=true;
      }
   }
   ftpopenChangeDir(cwd,os400_lfs);
}

void _ctl_remote_cwd.'ENTER'()
{
   _ctl_remote_cwd.call_event(CHANGE_PATH,_ctl_remote_cwd,ON_CHANGE,'w');
}

void __ftpopenChangeDirCB( FtpQEvent* pEvent, _str action="", typeless isLink="" )
{
   FtpQEvent event;
   FtpConnProfile fcp;
   FtpConnProfile *fcp_p;
   int formWid;

   formWid=_ftpopenQFormWid();
   if( !formWid ) return;   // This should never happen

   event= *((FtpQEvent *)(pEvent));
   fcp=event.fcp;
   //message("event.fcp.RemoteCWD="event.fcp.RemoteCWD);

   action= upcase(action);
   if( action!="CDUP" && action!="CWD" ) {
      // This should never happen
      ftpConnDisplayError(&fcp,'Invalid action: "':+action:+'"');
      return;
   }

   boolean is_link = (isLink!="" && isLink );

   if( _ftpQEventIsError(event) ) {
      if( action=="CWD" && is_link &&
          (fcp.system==FTPSYST_UNIX || (fcp.system==FTPSYST_MVS && substr(fcp.remoteCwd,1,1)=='/')) ) {
         // The symbolic link is not a directory, so try to open as file instead
         ftpopenOpenLinks();
         return;
      }
      // An error occurred with CWD.
      // The CWD handler was silent for the error, since it did not know
      // whether we were trying to process a link, so show the error message
      // now.
      _ftpQEventDisplayError(event);
      // Fix things up in case the user had typed a bogus path and hit ENTER
      formWid._UpdateSession(false);
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
         // We did not find the matching connection profile, so bail out
         return;
      }
      fcp_p->remoteCwd=fcp.remoteCwd;

      // _UpdateSession() already handles asynchronous operations
      formWid._UpdateSession(true);
      return;
   }

   return;
}
void __ftpopenCdupCB( FtpQEvent* pEvent )
{
   __ftpopenChangeDirCB(pEvent,"CDUP");
}
void __ftpopenCwdCB( FtpQEvent* pEvent )
{
   __ftpopenChangeDirCB(pEvent,"CWD");
}
void __ftpopenCwdLinkCB( FtpQEvent* pEvent )
{
   __ftpopenChangeDirCB(pEvent,"CWD",true);
}

void _ctl_remote_dir.'ENTER',lbutton_double_click(_str filename="")
{
   FtpConnProfile *fcp_p;
   FtpConnProfile fcp;

   fcp_p=GetCurrentConnProfile();
   if( !fcp_p ) return;   // This should never happen

   _str caption="";
   int idx=0;
   if( filename=="" ) {
      // Current item in tree
      idx=_TreeCurIndex();
      caption=_TreeGetCaption(idx);
      parse caption with filename "\t" .;
   }
   fcp= *fcp_p;   // Make a copy
   fcp.postedCb=null;
   if( filename==".." ) {
      if( fcp.system==FTPSYST_VXWORKS ) {
         // Special case of a VxWorks host that does not support the
         // CDUP command (the only host that we know of).
         fcp.postedCb=(typeless)__ftpopenCwdCB;
         filename=fcp.remoteCwd;
         filename=strip(filename);   // Just in case
         if( filename!='/' ) {
            if( last_char(filename)=='/' ) {
               // Strip off the trailing '/'
               filename=substr(filename,1,length(filename)-1);
            }
            int i=lastpos('/',filename);
            if( i ) {
               filename=substr(filename,1,i);
               if( filename!='/' ) {
                  // Strip off the trailing '/'
                  filename=substr(filename,1,length(filename)-1);
               }
            }
         }
         ftpopenChangeDir(filename);
         //_ftpSyncEnQ(QE_CWD,QS_BEGIN,0,&fcp,filename);
      } else {
         if( fcp.serverType==FTPSERVERTYPE_SFTP ) {
            // SFTP servers have no concept of a current working directory,
            // so we have to maintain one. Let the server resolve it.
            filename=fcp.remoteCwd;
            if( last_char(filename)!='/' ) filename=filename'/';
            filename=filename'..';
            ftpopenChangeDir(filename);
         } else {
            // FTP
            ftpopenChangeDir(filename);
            //fcp.PostedCB=(typeless)__ftpopenCdupCB;
            //_ftpSyncEnQ(QE_CDUP,QS_BEGIN,0,&fcp);
         }
      }
      return;
   } else {
      _str info=_TreeGetUserInfo(idx);
      info=lowcase(info);
      if( pos("f",info) ) {
         // We have a file so transfer it.
         // Note that ftpopenOpen() will take care of asynchronous
         // operations.
         ftpopenOpen();
      } else if( pos("d",info) ) {
         // We have a directory so CWD to it
         if( (fcp.system==FTPSYST_UNIX || (fcp.system==FTPSYST_MVS && substr(fcp.remoteCwd,1,1)=='/')) &&
             pos("l",info) ) {
            // Get rid of the link part
            parse filename with filename '->' .;
            filename=strip(filename);
         }
         boolean is_link = ( 0!=pos("l",info) );
         ftpopenChangeDir(filename,0,is_link);
         //fcp.PostedCB=__ftpopenCwdCB;
         //_ftpSyncEnQ(QE_CWD,QS_BEGIN,0,&fcp,filename);
         return;
      }
   }
}

void _ctl_remote_dir.'BACKSPACE'()
{
   _ctl_remote_dir.call_event("..",_ctl_remote_dir,LBUTTON_DOUBLE_CLICK,'W');
}

static boolean _busy_override=false;
/**
 * Gets called when the queue is processing events.
 * Only gets called once when the queue receives the first
 * event after being idle.
 */
void _ftpQBusy_ftpopen()
{
   //say('_ftpQBusy_ftpopen: in');
   if( _busy_override ) return;

   _enable_ftpopen(false);

   //say('_ftpQBusy_ftpopen: out');

   return;
}

static boolean _idle_override=false;
/**
 * Gets called when the queue is idle.
 * Only gets called once when the queue process the last
 * event and then goes idle.
 */
void _ftpQIdle_ftpopen()
{
   FtpConnProfile *fcp_p;

   if( _idle_override ) return;

   _enable_ftpopen(true);


   return;
}

static void _enable_children(int parent,boolean enable)
{
   int firstwid,wid;

   if( !parent ) return;

   firstwid=parent.p_child;
   if( !firstwid ) return;
   wid=firstwid;
   for(;;) {
      if( wid.p_name!="_ctl_abort" ) {
         if( enable ) {
            if( wid.p_mouse_pointer!=MP_DEFAULT ) wid.p_mouse_pointer=MP_DEFAULT;
         } else {
            if( wid.p_mouse_pointer!=MP_HOUR_GLASS ) wid.p_mouse_pointer=MP_HOUR_GLASS;
         }
         //_enable_children(wid,enable);
      }
      wid=wid.p_next;
      if( wid==firstwid ) break;
   }

   return;
}

static void _enable_ftpopen(boolean enable)
{
   int formWid = _ftpopenQFormWid();
   if( formWid==0 ) {
      return;
   }
   // I have to set p_mouse_pointer for the form for this to
   // work reliably. Shouldn't have to do this though.
   if( !_tbIsWidActive(formWid) || enable ) {
      formWid.p_mouse_pointer=MP_DEFAULT;
      //sstabWid.p_mouse_pointer=MP_DEFAULT;
      //_enable_children(formWid,true);
   } else {
      formWid.p_mouse_pointer=MP_HOUR_GLASS;
      //sstabWid.p_mouse_pointer=MP_HOUR_GLASS;
      //_enable_children(formWid,false);
   }

   int groupWid=formWid._find_control("_ctl_group");
   if( groupWid ) groupWid.p_enabled=enable;

   return;
}

_command int ftpOpen(typeless forceConnect="") name_info(','VSARG2_NCW|VSARG2_READ_ONLY)
{
   int formWid;
   FtpConnProfile *fcp_p;

   boolean force_connect = (forceConnect!="");

   activate_ftp();
   formWid=_find_object("_tbFTPOpen_form");
   if( formWid==0 ) {
      _str msg="Could not show _tbFTPOpen_form!";
      _message_box(msg,'',MB_OK|MB_ICONEXCLAMATION);
      return 1;
   }
   fcp_p=formWid.GetCurrentConnProfile();
   if( !fcp_p || force_connect ) {
      // There are no connections at present.
      // Rather than present the user with a blank tab we will "click"
      // the Connect button for them.
      int buttonWid = formWid._find_control("_ctl_connect");
      if( buttonWid ) {
         buttonWid.call_event(buttonWid,LBUTTON_UP,'W');
      }
   }

   return 0;
}


/**
 * Open a connection to an S/FTP site identified by the
 * profile name.
 * 
 * @param cmdline A command line of the form: <br>
 *                <br>
 *                [+Q] profile-name
 *                <br>
 *                <br>
 *                where: <br>
 *                +Q Quiet. Do not display any warnings or errors.
 * 
 * @return 0 on success, non-zero on failure.
 */
_command int ftpopenOpenByProfile(_str cmdline="")
{
   // Parse cmdline into options and profile name
   _str options="";
   _str profile_name = strip_options(cmdline,options);
   boolean ht_opt:[]; ht_opt._makeempty();
   while( options!="" ) {
      _str opt;
      parse options with opt options;
      opt=upcase(strip(opt,'B'));
      // Strip off the +/-
      opt=substr(opt,2);
      ht_opt:[opt]=true;
   }

   // Make sure the FTP tab is showing
   activate_ftp();

   if( profile_name=="" ) {
      if( !ht_opt._indexin("Q") ) {
         _str msg = "Missing profile name";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      }
      return 1;
   }
   if(! _ftpIsConnProfile(profile_name) ) {
      if( !ht_opt._indexin("Q") ) {
         _str msg = "Profile \""profile_name"\"not found";
         _message_box(msg,'',MB_OK|MB_ICONEXCLAMATION);
      }
      return 1;
   }

   FtpConnProfile fcp;
   int status = _ftpOpenConnProfile(profile_name,&fcp);
   if( status ) {
      // Uh oh
      return status;
   }
   _ftpopenConnect(&fcp,true);

   // All good
   return 0;
}

#if 0
_command int ftpEdit(_str address="") name_info(','VSARG2_LASTKEY|VSARG2_NCW|VSARG2_READ_ONLY)
{
   _str host,port,path,profile;
   ftpConnProfile_t fcp;
   ftpFileHist_t *p1;
   ftpFileHistFile_t *p2;

   key_or_cmdline=_executed_from_key_or_cmdline(name_name(last_index('','C')));

   host=port=path=profile="";

   if( key_or_cmdline ) {
      address=prompt(address,'FTP Edit');
   }
   if( address=='' ) return(0);   // User probably cancelled

   status=0;
   for( ;; ) {   // Use this in place of a goto as a way to quickly handle errors
      if( !vssIsInit() ) {
         status=vssInit();
         if( status ) break;
      }
      status=_ftpParseAddress(address,host,port,path);
      if( status ) break;
      if( port=='' ) {
         port='ftp';
      }

      // Check for an already existing buffer with this document name
      document_name='ftp://':+host;
      if( substr(path,1,1)!='/' ) document_name=document_name:+'/';
      document_name=document_name:+path;
      #if 0
      buf_name=_ftpDocMatch(document_name);
      if( buf_name!="" ) {
         edit("+b ":+buf_name);
         return(0);
      }
      #else
      info=buf_match(document_name,1,"EVD");
      if( info!="" ) {
         parse info with . . . buf_name;
         edit("+b ":+maybe_quote_filename(buf_name));
         return(0);
      }
      #endif

      fcp._makeempty();
      // arg(4)=true means to connect after succesful creation of the connection profile
      status=_ftpHHWCreateConnProfile(host,port,&fcp,true);
      if( status ) break;

      // First check _ftpFileHist for recently opened files that have a locally mapped filename
      xfer_type=fcp.XferType;
      p1=_ftpFileHist._indexin(fcp.Host);
      if( p1 ) {
         p2=p1->files._indexin(path);
         if( p2 ) {
            local_path=p2->local_path;
            i=lastpos('/',local_path);
            if( i ) {
               temp_path=substr(local_path,1,i-1);
               temp_name=substr(local_path,i+1);
               if( file_match('+D -P +X ':+maybe_quote_filename(path),1)=="" ) {
                  // Path does not exist
                  p1->files._deleteel(path);
                  local_path=_ftpRemoteToLocalPath(&fcp,path);
               } else {
                  //xfer_type=p2->xfer_type;
               }
            } else {
               // This should never happen
               p1->files._deleteel(path);
               local_path=_ftpRemoteToLocalPath(&fcp,path);
            }
         } else {
            // No local mapping in _ftpFileHist
            local_path=_ftpRemoteToLocalPath(&fcp,path);
         }
      } else {
         local_path=_ftpRemoteToLocalPath(&fcp,path);
      }
      if( local_path=="" ) {
         _message_box("Unable to create local filename",FTP_ERRORBOX_TITLE,MB_OK|MB_ICONEXCLAMATION);
         return(FTP_ERROR_CREATING_LOCAL_FILE_RC);
      }
      if( xfer_type!=FTPXFER_ASCII && xfer_type!=FTPXFER_BINARY ) {
         // Invalid transfer type, so prompt
         xfer_type=show("-modal _ftpDownload_form",path);
         if( xfer_type=="" ) return(0);   // User cancelled
      }
      old_XferType=fcp.XferType;
      fcp.XferType=xfer_type;
      status=_ftpRetr(&fcp,path,local_path);
      fcp.XferType=old_XferType;
      if( status ) break;
      _ftpFileHist:[fcp.Host].files:[path].local_path="";
      if( _ftpUseShortFilenames() ) {
         // Add it to the hash table of opened files - these will be written
         // to the user ini file.
         // NOTE: We only add entries to _ftpFileHist when we are on an 8.3
         //       file system, but we ALWAYS check to see if there is a
         //       remote-to-local filename mapping when we create the local
         //       filename because we might end up with 2 copies of the same
         //       file. This could happen if the user switches from NT (long
         //       file names), to OS/2 (short file names).
         _ftpFileHist:[fcp.Host].files:[path].local_path=local_path;
      }
      //_ftpFileHist:[fcp.Host].files:[path].xfer_type=fcp.XferType;
      // We assemble the document name again because the user might have
      // changed the host name if prompted with the _ftpCreateProfile_form
      // dialog.
      document_name='ftp://':+fcp.Host;
      if( substr(path,1,1)!='/' ) document_name=document_name:+'/';
      document_name=document_name:+path;
      options="";
      status=edit(options:+maybe_quote_filename(local_path));
      if( status ) break;
      // Mark this file as binary if we downloaded it binary
      if( fcp.XferType==FTPXFER_BINARY ) {
         _mdi.p_child._ftpSetBinary(true);
      }
      _mdi.p_child.docname(document_name);

      break;
   }
   // Save these for later error reporting
   ftpedit_status=status;
   laststatusline=fcp.LastStatusLine;

   //_ftpEndConnProfile(&fcp);

   if( ftpedit_status ) {
      if( ftpedit_status!=COMMAND_CANCELLED_RC ) {
         if( ftpedit_status==VSRC_FTP_BAD_RESPONSE ) {
            _message_box(_ftpGetMessage(ftpedit_status):+"\n\n":+laststatusline,FTP_ERRORBOX_TITLE,MB_OK|MB_ICONEXCLAMATION);
         } else {
            if( status==SOCK_SOCKET_NOT_CONNECTED_RC ) {
               // Means that the host name resolved, but cannot connect to it
               _message_box("Unable to connect to ":+host:+":":+port:+"\n\n":+_ftpGetMessage(status),FTP_ERRORBOX_TITLE,MB_OK|MB_ICONEXCLAMATION);
            } else {
               _ftpError(status);
            }
         }
      }
   }

   return(status);
}
#endif

