////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47103 $
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
#import "combobox.e"
#import "listbox.e"
#import "main.e"
#import "stdprocs.e"
#import "mprompt.e"
#endregion

#define DRVLIST_PIC_LSPACE_Y 60    // Extra line spacing for list box.
#define DRVLIST_PIC_LINDENT_X 60   // Indent for list box bitmap.
#define DVRLIST_PIC_SPACE_Y 80     // Extra text box line spacing.
#define DVRLIST_PIC_INDENT_X 100   // Indent for text box bitmap.

//
//    User level 2 inheritance for DRIVE LIST
//
defeventtab _ul2_drvlist _inherit _ul2_combobx;
static void _init_drive_combo()
{
   p_display_list_on_down_key=true;
   if (p_style!=PSCBO_NOEDIT) {
      p_style=PSCBO_NOEDIT;
   }
   if (__UNIX__) {
      // No drive list bitmaps for OS/2 or UNIX
      _insert_drive_list();
      _dvldrive('');
      p_object_modify=0;
      p_picture=0;
      p_pic_space_y=0;
      p_pic_point_scale=0;
      return;
   }
   p_redraw=0;
   int picture=0;
   p_picture=0;
   _insert_drive_list();

   // 6/6/2011 - rb
   // p_picture is really just a boolean that tells the combobox to insert
   // lines with pictures. It is required to be set before massaging the
   // list with pictures or else the first item will not have a picture.
   // In time we may refactor this code and deprecate this particular use
   // of p_picture.
   p_picture = _pic_drfixed;

   top();up();
   for (;;) {
      if (down()) break;
      _str line=_lbget_text();
      _str dt=_drive_type(line);
      if (dt==DRIVE_NOROOTDIR) {
         int status=_lbdelete_item();
         // If deleted last line
         if (status) break;
         up();
         continue;
      } else if (dt==DRIVE_FIXED) {
         picture=_pic_drfixed;
      } else if (dt==DRIVE_CDROM){
         picture=_pic_drcdrom;
      } else if (machine() == 'WINDOWS' && dt==DRIVE_REMOTE){
#if !__UNIX__
         _str filename=NTNetGetConnection(line);
         if (filename!='') {
            line=line:+' 'filename;
         }
#endif
         picture=_pic_drremov;
      } else {
         picture=_pic_drremov;
      }
      if (!__UNIX__) {
         _lbset_item(line,DRVLIST_PIC_LINDENT_X,picture);
      } else {
         _lbset_item(line);
      }
   }
   _str drive=lowcase(substr(getcwd(),1,2));
   if (_drive_type(drive)==DRIVE_FIXED) {
      picture=_pic_drfixed;
   } else {
      picture=_pic_drremov;
   }
   //p_cb_text_box.p_picture=picture
   //p_cb_text_box.p_text=drive
   p_pic_indent_x=DVRLIST_PIC_INDENT_X;
   p_pic_space_y=DVRLIST_PIC_SPACE_Y;
   p_pic_point_scale=8;
   p_picture=picture;
   p_pic_space_y=DRVLIST_PIC_LSPACE_Y;
   /* Setting p_redraw her for list box see to fix a but
      where p_object_modify gets set.
      I think a better fix would be to change the USERREFRESH
      for a combo box.
   */
   p_redraw=1;
   _dvldrive('');
   p_redraw=1;
   p_object_modify=0;
}


void _ul2_drvlist.on_create2()
{
   _init_drive_combo();
}


/** 
 * @return  This function is not available under UNIX.  Returns and 
 * optionally sets the current drive being displayed in a drive list 
 * combo box.  Drive may be a drive letter followed by a colon or a 
 * UNC root name (Network \\server\sharename).  This function does not 
 * cause an <b>on_change</b> event to occur.
 * 
 * @appliesTo  Drive_List
 * @categories Drive_List_Methods
 */
_str _dvldrive(...)
{
   if (!arg()) {
      return(p_user2);
   }
   _str param=arg(1);
   if (param=='') {
      param=getcwd();
   }
   _str filename='';
   _str drive='';
   int picture=0;
   if (isunc_root(param)) {
      p_text=param;
      picture=_pic_drfixed;
      // Check if this unc_name has been inserted into the combo box
      status := _cbi_search(_fpos_case,'$');
      if (status) {
         top();
         up();
         if (!__UNIX__) {
            _lbadd_item(param,DRVLIST_PIC_LINDENT_X,picture);
         } else {
            _lbadd_item(param);
         }
         _lbselect_line();
      }
      drive=param;
      if (last_char(drive)==FILESEP) {
         drive=substr(drive,1,length(drive)-1);
      }
   } else {
      drive=lowcase(substr(param,1,2));
      if (_drive_type(drive)==DRIVE_FIXED) {
         picture=_pic_drfixed;
      } else {
         picture=_pic_drremov;
      }
   }
   if (machine()=='WINDOWS') {
#if !__UNIX__
      if (substr(drive,2,1)==':') {
         _str justdrive='';
         parse drive with justdrive .;
         if (_drive_type(justdrive)==DRIVE_REMOTE) {
            drive=justdrive;
            filename=NTNetGetConnection(justdrive);
            if (filename!='') {
               drive=drive:+' 'filename;
            }
            p_user2=justdrive;
            p_text=drive;
         }  else {
            p_user2=drive;
            p_text=drive;
         }
      } else {
         p_user2=drive;
         p_text=drive;
      }
#endif
   } else {
      p_user2=drive;
      p_text=drive;
   }
   if (!__UNIX__) {
      p_picture=picture;
   }
   _lbselect_line();
   return('');
}
#if 0
_ul2_drvlist.on_change(int reason)
{
   if (reason==CHANGE_CLINE_NOTVIS2) {
      call_event(DROP_UP,defeventtab _ul2_drvlist,on_drop_down,'e');
   }
}
#endif
_ul2_drvlist.on_drop_down(int reason)
{
   switch (reason) {
   case DROP_UP:
      _str drive=_lbget_text();
      if (drive!='' && drive!=_dvldrive()) {
         if (isdrive(drive)) {
            /* Check for drive not ready. */
            for (;;) {
               file_match('+d 'drive,1);
               typeless status=rc;
               if (_win32s()==1 && rc==FILE_NOT_FOUND_RC) {
                  _str curdir=getcwd();
                  status=chdir(drive,1);
                  chdir(curdir,1);
                  if (status) {
                     status=DRIVE_NOT_READY_RC;
                  }
               }
               if (!status || status==FILE_NOT_FOUND_RC) break;
               switch (status) {
               case DRIVE_NOT_READY_RC:
                  status=_message_box(nls("Drive %s not ready.  Make sure the drive door is closed.",drive),
                               p_active_form.p_caption,
                               MB_RETRYCANCEL);
                  break;
               default:
                  status=_message_box(nls("Windows is unable to read drive %s.  Make sure the drive door is closed and that the\ndisk is formatted and free of errors.",drive),
                               p_active_form.p_caption,
                               MB_RETRYCANCEL);
               }
               if (status==IDCANCEL) {
                  // Restore original drive
                  _dvldrive(_dvldrive());
                  return('');
               }
            }
         }
         _dvldrive(drive);
         call_event(CHANGE_DRIVE,p_window_id,ON_CHANGE,'');
      }
   }
}

