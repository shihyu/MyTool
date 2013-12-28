////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47870 $
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
#include "pipe.sh"
#include "vsockapi.sh"
#import "complete.e"
#import "fileman.e"
#import "ftpclien.e"
#import "ftpopen.e"
#import "ftpq.e"
#import "guiopen.e"
#import "ini.e"
#import "listbox.e"
#import "main.e"
#import "optionsxml.e"
#import "picture.e"
#import "savecfg.e"
#import "saveload.e"
#import "seek.e"
#import "sstab.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "treeview.e"
#import "util.e"
#endregion

#define _ftpUseShortFilenames() (machine()=="WINDOWS" && _win32s()==1)

#define FTPBM_FTPCDUP "_ftpcdup.ico"
#define FTPBM_FTPFILE "_ftpfile.ico"
#define FTPBM_FTPFOLD "_ftpfold.ico"
#define FTPBM_FTPLFOL "_ftplfol.ico"
#define FTPBM_FTPLFIL "_ftplfil.ico"
#define FTPBM_FTPFILD "_ftpfild.ico"
#define FTPBM_FTPFOD  "_ftpfod.ico"
#define FTPBM_FTPNFIL "_ftpfild.ico"
#define FTPBM_FTPNFOL "_ftpfod.ico"
#define FTPBM_FTPDFIL "_ftpfild.ico"
#define FTPBM_FTPDFOL "_ftpfod.ico"
#define FTPBM_FTPRFIL "_ftpfild.ico"
#define FTPBM_FTPRFOL "_ftpfod.ico"

static int _MaybeLoadPicture(_str filename)
{
   if( filename=="" ) return(-1);
   return(_update_picture(-1,filename));
}

_command void ftp_default_options() name_info(',')
{
   config("_ftpOptions_form", 'D');
}

/**
 * Flag current FTP buffer as binary or ascii.
 * 
 * @param binary true specifies that buffer should be transferred binary.
 *               false specifies that buffer should be transferred ascii.
 *               Note that this flag has no effect on SFTP buffers because
 *               SFTP only supports binary transfers (as it should be).
 */
void _ftpSetBinary(boolean binary)
{
   if( binary ) {
      p_buf_flags |= VSBUFFLAG_FTP_BINARY;
   } else {
      p_buf_flags &= ~(VSBUFFLAG_FTP_BINARY);
   }
}
/**
 * @return true if current buffer should be uploaded/transferred
 * binary.
 */
boolean _ftpGetBinary()
{
   return ( 0!=(p_buf_flags & VSBUFFLAG_FTP_BINARY) );
}

int gftp_todo_view_id=0;
static boolean gIniInitDone;
static _str _ftpUserIniFilename;

definit()
{
   gIniInitDone=false;
   _ftpUserIniFilename="";

   if( arg(1)!='L' ) {
      gftp_todo_view_id=0;
   }

   if( arg(1)!='L' ) {   // Don't blow away list of existing connections if loading
      _ftpCurrentConnections._makeempty();
      _ftpFileHist._makeempty();
   }

   if (arg(1)=='L') {
      // Pictures
      _pic_ftpcdup=_MaybeLoadPicture(FTPBM_FTPCDUP);
      _pic_ftpfile=_MaybeLoadPicture(FTPBM_FTPFILE);
      _pic_ftpfold=_MaybeLoadPicture(FTPBM_FTPFOLD);
      _pic_ftplfol=_MaybeLoadPicture(FTPBM_FTPLFOL);
      _pic_ftplfil=_MaybeLoadPicture(FTPBM_FTPLFIL);
      _pic_ftpfild=_MaybeLoadPicture(FTPBM_FTPFILD);
      _pic_ftpfod= _MaybeLoadPicture(FTPBM_FTPFOD);
      _pic_ftpnfil=_MaybeLoadPicture(FTPBM_FTPNFIL);
      _pic_ftpnfol=_MaybeLoadPicture(FTPBM_FTPNFOL);
      _pic_ftpdfil=_MaybeLoadPicture(FTPBM_FTPDFIL);
      _pic_ftpdfol=_MaybeLoadPicture(FTPBM_FTPDFOL);
      _pic_ftprfil=_MaybeLoadPicture(FTPBM_FTPRFIL);
      _pic_ftprfol=_MaybeLoadPicture(FTPBM_FTPRFOL);

   }
   _ftpsave_override=0;

   rc=0;
}

/**
 * Message box notification method for FTP error messages.
 *
 * @param msg  Error message.
 */
void ftpDisplayError(_str msg)
{
   _message_box(msg,FTP_ERRORBOX_TITLE,MB_OK|MB_ICONEXCLAMATION);
}

/**
 * Message box notification method for FTP warning messages.
 *
 * @param msg  Warning message.
 */
void ftpDisplayWarning(_str msg)
{
   _message_box(msg,FTP_WARNINGBOX_TITLE,MB_OK|MB_ICONEXCLAMATION);
}

/**
 * Message box notification method for FTP info messages.
 *
 * @param msg  Info message.
 */
void ftpDisplayInfo(_str msg)
{
   _message_box(msg,FTP_INFOBOX_TITLE,MB_OK|MB_ICONINFORMATION);
}

/**
 * Connection-specific notification method for FTP error 
 * messages. If there is no error-display callback then this 
 * function does nothing. 
 *
 * @param fcp_p  Connection profile.
 * @param msg    Error message.
 */
void ftpConnDisplayError(FtpConnProfile* fcp_p, _str msg)
{
   if( fcp_p->errorCb ) {
      (*fcp_p->errorCb)(msg);
   }
}

/**
 * Connection-specific notification method for FTP warning 
 * messages. If there is no warning-display callback then this 
 * function does nothing. 
 *
 * @param fcp_p  Connection profile.
 * @param msg    Warning message.
 */
void ftpConnDisplayWarning(FtpConnProfile* fcp_p, _str msg)
{
   if( fcp_p->warnCb ) {
      (*fcp_p->warnCb)(msg);
   }
}

/**
 * Connection-specific notification method for FTP info 
 * messages. If there is no info-display callback then this 
 * function does nothing. 
 *
 * @param fcp  Connection profile.
 * @param msg  Info message.
 */
void ftpConnDisplayInfo(FtpConnProfile* fcp_p, _str msg)
{
   if( fcp_p->infoCb ) {
      (*fcp_p->infoCb)(msg);
   }
}

/**
 * Operates on active form which must be an instance of either _tbFTPOpen_form
 * or _tbFTPClient_form.
 * <p>
 * Return a pointer to the active connection profile displayed in the form.
 * 
 * @return Pointer to active connection profile. 0 no active profiles.
 */
FtpConnProfile *GetCurrentConnProfile()
{
   FtpConnProfile *fcp_p = null;
   _control _ctl_profile;

   _str profile = _ctl_profile.p_text;
   if( profile!="" && !_ftpCurrentConnections._isempty() && _ftpCurrentConnections._indexin(profile) ) {
      fcp_p=_ftpCurrentConnections._indexin(profile);
   }

   return(fcp_p);
}

/**
 * Maintains a stack of directories for recursive operations (e.g.
 * upload, download). Each time this function is called a new
 * directory list is pushed onto the stack. Call _ftpDirStackPop()
 * to pop a directory listing off the stack.
 * <P>
 * Also used to keep track of tree items even after the user kills
 * the FTP Client toolbar. Very useful if the user starts downloading
 * multiple items and then kills the toolbar.
 */
void _ftpDirStackPush(_str localcwd,_str remotecwd,FtpDirectory *dir_p,FtpDirStack (&ds)[])
{
   FtpDirStack ds_entry;

   ds_entry.next= -1;
   ds_entry.localcwd=localcwd;
   ds_entry.remotecwd=remotecwd;
   ds_entry.dir= *dir_p;
   ds_entry.tree_pos="";
   ds[ds._length()]=ds_entry;

   return;
}
FtpDirStack* _ftpDirStackPop(FtpDirStack (&ds)[])
{
   static FtpDirStack ds_popped;

   if( ds._length()<1 ) {
      return null;
   }
   ds_popped = ds[ds._length()-1];
   ds._deleteel(ds._length()-1);

   return (&ds_popped);
}
void _ftpDirStackClear(FtpDirStack (&ds)[])
{
   ds._makeempty();

   return;
}
int _ftpDirStackNext(FtpDirStack (&ds)[])
{
   if( ds._length()<1 ) {
      return(-1);
   }
   int next=ds[ds._length()-1].next;
   ++next;
   if( next>=ds[ds._length()-1].dir.files._length() ) {
      return(-1);
   }
   ds[ds._length()-1].next=next;

   return(next);
}
int _ftpDirStackPrev(FtpDirStack (&ds)[])
{
   if( ds._length()<1 ) {
      return(-1);
   }
   int next=ds[ds._length()-1].next;
   --next;
   if( next<0 ) {
      next= -1;
   }
   ds[ds._length()-1].next=next;

   return(next+1);
}
void _ftpDirStackGetFile(FtpDirStack ds[],FtpFile &file)
{
   file._makeempty();
   if( ds._length()<1 ) {
      return;
   }
   int next=ds[ds._length()-1].next;
   if( next>=ds[ds._length()-1].dir.files._length() ) {
      return;
   }
   file=ds[ds._length()-1].dir.files[next];

   return;
}
void _ftpDirStackGetLocalCwd(FtpDirStack ds[],_str &localcwd)
{
   if( ds._length()<1 ) {
      return;
   }
   localcwd=ds[ds._length()-1].localcwd;

   return;
}
void _ftpDirStackSetLocalCwd(FtpDirStack (&ds)[],_str localcwd)
{
   if( ds._length()<1 ) {
      return;
   }
   ds[ds._length()-1].localcwd=localcwd;

   return;
}
void _ftpDirStackGetRemoteCwd(FtpDirStack ds[],_str &remotecwd)
{
   if( ds._length()<1 ) {
      return;
   }
   remotecwd=ds[ds._length()-1].remotecwd;

   return;
}
void _ftpDirStackSetRemoteCwd(FtpDirStack (&ds)[],_str remotecwd)
{
   if( ds._length()<1 ) {
      return;
   }
   ds[ds._length()-1].remotecwd=remotecwd;

   return;
}
void _ftpDirStackSetRemoteTreePos(FtpDirStack (&ds)[], typeless p)
{
   if( ds._length()<1 ) {
      return;
   }
   ds[ds._length()-1].tree_pos=p;
}

// Used by _ftpRemoteSavePos, _ftpRemoteRestorePos.
static typeless REMOTETREEPOS="";

/**
 * This expects the active window to be a tree view.
 * <p>
 * Saves the scroll position and the current item in the tree,
 * the remote working directory, profile, and instance.
 * <p>
 * Use _ftpRemoteRestorePos() to restore.
 * 
 * @param p (output). Position to store. Defaults to global REMOTETREEPOS
 *          if not provided.
 */
void _ftpRemoteSavePos(typeless& p=REMOTETREEPOS)
{
   FtpConnProfile *fcp_p;
   typeless tree_pos;
   typeless p2;
   int formWid = p_active_form;

   p2="";
   _TreeSavePos(tree_pos);
   fcp_p=formWid.GetCurrentConnProfile();
   if( fcp_p ) {
      _str cwd=fcp_p->remoteCwd;
      if( cwd=="" ) {
         // This should never happen
         cwd=".";
      }
      cwd='"':+cwd:+'"';
      _str profile='"':+fcp_p->profileName:+'"';
      int instance=fcp_p->instance;
      p2=cwd" "profile" "instance" "tree_pos;
   }
   p=p2;

   return;
}

/**
 * This expects the active window to be a tree view.
 * <p>
 * Restores the scroll position and the current item in the tree.
 * <p>
 * Use _ftpRemoteSavePos() to save.
 * 
 * @param p Position to restore. Defaults to global REMOTETREEPOS
 *          if not provided.
 */
void _ftpRemoteRestorePos(typeless p=REMOTETREEPOS)
{
   FtpConnProfile *fcp_p;
   typeless tree_pos;
   int formWid = p_active_form;

   if( p=="" ) {
      return;
   }
   fcp_p=formWid.GetCurrentConnProfile();
   if( fcp_p ) {
      _str cwd=fcp_p->remoteCwd;
      if( cwd=="" ) {
         // This should never happen
         cwd=".";
      }
      _str profile=fcp_p->profileName;
      int instance=fcp_p->instance;
      _str lrp_cwd='';
      _str lrp_profile='';
      _str lrp_instance='';
      parse p with '"' lrp_cwd '"' '"' lrp_profile '"' lrp_instance tree_pos;
      if( tree_pos!="" ) {
         if( lrp_cwd==cwd && lrp_profile==profile && lrp_instance==instance ) {
            _TreeRestorePos(tree_pos);
            _TreeRefresh();
         }
      }
   }

   return;
}

#if 1
/**
 * Recursively delete a directory and its contents.
 */
int _ftpLocalRmdir(_str path)
{
   int status=_DelTree(path,true);

   return(status);
}
#else
/**
 * Recursively delete the contents of a directory (but not the directory
 * itself).
 */
static int _ftpLocalRmdir2(_str path)
{
   status=0;

   orig_view_id=_create_temp_view(temp_view_id);
   if( orig_view_id=="" ) return(1);
   if( last_char(path)!=FILESEP ) path=path:+FILESEP;
   filespec=path:+ALLFILES_RE;
   status=insert_file_list(maybe_quote_filename(filespec):+' +ADV');
   if( status ) {
      _delete_temp_view(temp_view_id);
      p_window_id=orig_view_id;
      if( status==FILE_NOT_FOUND_RC ) {
         return(0);
      }
      return(status);
   }
   top();up();
   while( !down() ) {
      get_line(line);
      filename=strip(substr(line,DIR_FILE_COL));
      if( filename=="." || filename==".." ) continue;
      size=strip(substr(line,DIR_SIZE_COL,DIR_SIZE_WIDTH));
      attribs=strip(substr(line,DIR_ATTR_COL,DIR_ATTR_WIDTH));
      full_path=path:+filename;
      if( upcase(size)=="<DIR>" || pos('d',lowcase(attribs)) ) {
         // Directory, so recursively remove it
         linenum=p_line;   // Save this in case switching views messes with it
         status=_ftpLocalRmdir2(full_path);
         if( status ) break;
         p_line=linenum;
         // Now must remove the directory itself
         status=_chmod("-rhs ":+maybe_quote_filename(full_path));
         if( status ) {
            msg="Error CHMODing directory:\n\n":+full_path;
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            break;
         }
         status=rmdir(full_path);
         if( status ) {
            msg="Error removing directory:\n\n":+full_path;
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            break;
         }
         continue;
      }
      // File, so delete it
      status=_chmod("-rhs ":+maybe_quote_filename(full_path));
      if( status ) {
         //say('status='status'  full_path='full_path);
         msg="Error CHMODing file:\n\n":+full_path;
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         break;
      }
      status=delete_file(full_path);
      if( status ) {
         msg="Error deleting file:\n\n":+full_path;
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         break;
      }
   }
   _delete_temp_view(temp_view_id);
   p_window_id=orig_view_id;

   return(status);
}

/**
 * Recursively delete a directory and its contents.
 */
int _ftpLocalRmdir(_str path)
{
   status=_ftpLocalRmdir2(path);
   if( !status ) {
      // Now delete the base directory we started from
      if( last_char(path)==FILESEP ) path=substr(path,1,length(path)-1);
      status=_chmod("-rhs ":+maybe_quote_filename(path));
      if( status ) {
         msg="Error CHMODing directory:\n\n":+path;
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      } else {
         status=rmdir(path);
         if( status ) {
            msg="Error removing directory:\n\n":+path;
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         }
      }
   }

   return(status);
}
#endif

/**
 * Used to keep track of tree items even after the user kills the
 * FTP Client toolbar. Very useful if the user starts downloading
 * multiple items and then kills the toolbar.
 * <P>
 * This function assumes the active object is a tree view.
 */
void _ftpTodoGetList()
{
   int tree_wid;

   // Have to save this because messing with views changes the active object
   tree_wid=p_window_id;

   int orig_view_id=0;
   if( !gftp_todo_view_id ) {
      orig_view_id=_create_temp_view(gftp_todo_view_id);
      p_buf_name=".FTP todo list";
      p_buf_flags|=VSBUFFLAG_THROW_AWAY_CHANGES;
   } else {
      get_window_id(orig_view_id);
      activate_window(gftp_todo_view_id);
      _lbclear();
   }
   int info;
   for( ff:=1;;ff=0 ) {
      int index=tree_wid._TreeGetNextSelectedIndex(ff,info);
      if( index<0 ) {
         break;
      }
      _str caption=tree_wid._TreeGetCaption(index);
      _str userinfo=tree_wid._TreeGetUserInfo(index);
      insert_line(caption""userinfo);
   }
   top();up();
   activate_window(orig_view_id);

   return;
}
int _ftpTodoFindNext()
{
   int orig_view_id=0;
   get_window_id(orig_view_id);
   activate_window(gftp_todo_view_id);
   if( down() ) {
      activate_window(orig_view_id);
      return(-1);
   }
   int next=p_line;
   activate_window(orig_view_id);
   return(next);
}
void _ftpTodoGetCaption(_str &caption)
{
   int orig_view_id=0;
   get_window_id(orig_view_id);
   activate_window(gftp_todo_view_id);
   _str line='';
   get_line(line);
   parse line with caption "" .;
   activate_window(orig_view_id);

   return;
}
void _ftpTodoGetUserInfo(_str &userinfo)
{
   int orig_view_id=0;
   get_window_id(orig_view_id);
   activate_window(gftp_todo_view_id);
   _str line='';
   get_line(line);
   parse line with . "" userinfo;
   activate_window(orig_view_id);

   return;
}

boolean isuncdirectory(_str path)
{
   if( substr(path,1,2)!='\\' ) return(false);
#if __UNIX__
   return(false);
#elif __PCDOS__
   if( last_char(path)!=FILESEP ) path=path:+FILESEP;
   if (file_match('+d ':+maybe_quote_filename(path:+ALLFILES_RE),1)=='') {
      return(false);
   }
#else
   What about this os
#endif

   return(true);
}

/**
 * htindex is the hash table index that this connection was stored under.
 * In most cases htindex will be the same as the ProfileName, except for
 * the case of there being more than one instance of a connection. In this
 * case htindex will be the ProfileName with an instance number appended
 * to it.
 *
 * @example
 * Sunsite [2]   <--- where the '[2]' represents the 2nd instance of a
 *                    connection to Sunsite
 */
int _ftpAddCurrentConnProfile(FtpConnProfile *fcp_p,_str &htindex)
{
   int greatest_instance;

   if( fcp_p->profileName=="" ) return(1);

   // If there is more than one instance of this connection profile,
   // then update the Instance field accordingly. Find the highest
   // Instance number and increment that since the user might have
   // killed instance 3 out of a total 10 instances.
   greatest_instance= -1;
   _str profile_name=fcp_p->profileName;
   htindex=profile_name;
   int instance=0;
   typeless i;
   for( i._makeempty();; ) {
      _ftpCurrentConnections._nextel(i);
      if( i._isempty() ) break;
      if( _ftpCurrentConnections:[i].profileName==profile_name ) {
         instance=_ftpCurrentConnections:[i].instance;
         if( instance>greatest_instance ) {
            greatest_instance=instance;
         }
      }
   }
   fcp_p->instance=greatest_instance+1;
   if( fcp_p->instance>0 ) {
      // Remember: Display instances as 1-based starting with the 2nd instance
      instance=fcp_p->instance+1;
      htindex=htindex:+" [":+instance:+"]";
   }
   fcp_p->postedCb=null;
   _ftpCurrentConnections:[htindex]= *fcp_p;

   return(0);
}

/**
 * NOTE: If the pointer passed into this function points directly to an
 *       element of the _ftpCurrentConnections:[] hash table, then that
 *       pointer will not be valid after this function returns.
 */
void _ftpRemoveCurrentConnProfile(FtpConnProfile *fcp_p)
{
   _str profile_name = fcp_p->profileName;
   if( profile_name=="" ) {
      // This should never happen
      return;
   }
   int instance = fcp_p->instance;

   // Find the current connection profile with matching ProfileName and Instance
   typeless i;
   for( i._makeempty();; ) {
      _ftpCurrentConnections._nextel(i);
      if( i._isempty() ) break;
      if( _ftpCurrentConnections:[i].profileName==profile_name &&
          _ftpCurrentConnections:[i].instance==instance ) {

         //_ftpCurrentConnections:[i]._makeempty();
         _ftpCurrentConnections._deleteel(i);
         break;
      }
   }
}

FtpConnProfile * _ftpIsCurrentConnProfile(_str ProfileName, _str instanceID="")
{
   int instance;

   if( ProfileName=="" ) return(null);
   instance= -1;
   if( instanceID!="" && isinteger(instanceID) ) {
      instance= (int)instanceID;
   }

   typeless i;
   for( i._makeempty();; ) {
      _ftpCurrentConnections._nextel(i);
      if( i._isempty() ) break;
      if( _ftpCurrentConnections:[i].profileName==ProfileName ) {
         if( instance>=0  ) {
            if( _ftpCurrentConnections:[i].instance==instance ) {
               return(&(_ftpCurrentConnections:[i]));
            }
         } else {
            return(&(_ftpCurrentConnections:[i]));
         }
      }
   }

   return(null);
}

/**
 * Attempts to find FTP connection profile name(s) that match the host name
 * passed in. The result is an array of strings which represent a list of
 * all matching FTP connection profile names.
 *
 * @param Host        Name of the host to match
 * @param ProfileName Array of profile names matching Host.
 *
 * @return 0 if match(es) are found. Otherwise non-zero is returned.
 */
int _ftpHostNameToCurrentConnection(_str Host,_str (&ProfileName)[])
{
   _str temparr[];

   // Find all profiles matching Host
   temparr._makeempty();
   typeless i;
   for( i._makeempty();; ) {
      _ftpCurrentConnections._nextel(i);
      if( i._isempty() ) break;
      if( _ftpCurrentConnections:[i].host==Host ) temparr[temparr._length()]=i;
   }
   if( temparr._length() ) {
      ProfileName=temparr;
      return(0);
   }

   return(1);   // No match for Host
}

#define HHWCCP_NEW "[New]"
static _str _hhwccpCallback(int reason,_str &result,_str button)
{
   if( reason==SL_ONDEFAULT ) {  // Enter key
      _str profile=_sellist._lbget_text();
      result=profile;
      return(1);
   }
   boolean user_button=reason==SL_ONUSERBUTTON;
   if( reason!=SL_ONUSERBUTTON ) return("");
   switch( button ) {
   case 4:
      result=HHWCCP_NEW;
      return(1);
   }

   return("");
}

/**
 * This function attempts to create a connection profile by any means
 * possible. It checks the list of current connections, the profiles
 * stored in the user ftp ini file, and then, finally, brings up a
 * dialog so that the user can create their own.
 *
 * <p>
 * Note:<br>
 * HHW is short for Heck or High Water.
 * </p>
 *
 * @param Host    Host name
 * @param Port    Connection port (e.g. "ftp" or 21)
 * @param fcp_p   Pointer to a connection profile structure
 * @param Connect If true then the created connection profile is started
 *                (or maybe restarted if it was in the list of current
 *                connections).
 *
 * @return 0 if connection profile is created successfully. Otherwise
 * non-zero is returned.
 */
int _ftpHHWCreateConnProfile(_str Host,_str Port,FtpConnProfile *fcp_p)
{
   _ftpInitConnProfile(*fcp_p);
   _str profile;

   profile="";

   // Check for current connections matching host
   _str list[];
   typeless result=0;
   if( !_ftpHostNameToCurrentConnection(Host,list) ) {
      // There are 1 or more current FTP connections matching this host
      if( list._length()>1 ) {
         // We have more than 1 match, so make user pick
         result=show("-modal _sellist_form","Multiple Matching Connections Found",SL_DEFAULTCALLBACK,list,"OK,&New","?Pick from the list of current connections or create a new connection","",_hhwccpCallback);
         if( result=="" ) return(COMMAND_CANCELLED_RC);
         profile=result;
         if( profile!=HHWCCP_NEW ) {
            *fcp_p=_ftpCurrentConnections:[profile];
         }
      } else {
         *fcp_p=_ftpCurrentConnections:[list[0]];
      }
      if( profile!=HHWCCP_NEW ) {
         if( fcp_p->profileName!="" ) {
            return(0);
         } else {
            return(1);
         }
      }
      // Fall thru
   }

   // If there is not a current connection OR the user specified to create
   // a new connection profile.
   if( fcp_p->profileName=="" ) {
      // Prompt for login info
      typeless status=show("-modal _ftpProfileManager_form",fcp_p);
      if( status ) {
         if( status=="" ) {
            // User cancelled
            return(COMMAND_CANCELLED_RC);
         }
         return(status);
      }
   }

   return(0);
}

void _ftpLog(FtpConnProfile *fcp_p,_str buf)
{
   if( fcp_p->logBufName=="" ) return;

   int orig_view_id=p_window_id;
   if(find_view(fcp_p->logBufName)) {
      return;
   }

   // Make sure we log the response on a line of its own
   bottom();
   if( _line_length()!=0 ) {
      insert_line('');
   }
   typeless temp='';
   _str line='';
   if( _ftpdebug&FTPDEBUG_TIME_STAMP ) {
      temp=buf;
      while( temp!="" ) {
         parse temp with line '\r\n','r' temp;
         _insert_text(_time('M'):+" ":+line);
         if( temp!="" ) {
            insert_line('');
         }
      }
   } else {
      _insert_text(buf);
   }
   if( _ftpdebug&FTPDEBUG_SAVE_LOG ) {

      temp_path := _log_path();
      _maybe_append_filesep(temp_path);

      _str log_filename='';
      if( _win32s()==1 ) {
         // 8.3
         log_filename=temp_path:+"ftplog";
      } else {
         log_filename=temp_path:+p_buf_name;
      }
      typeless status=save_file(maybe_quote_filename(log_filename),'+o');
   }
   p_window_id=orig_view_id;

   // Make sure we are always at the bottom of the log window on the toolbar
   _control _ctl_ftp_sstab;
   int ftpclient_wid = _find_object("_tbFTPClient_form","N");
   if( ftpclient_wid > 0 ) {
      int sstab_wid = ftpclient_wid._ctl_ftp_sstab;
      SSTABCONTAINERINFO info;
      int i, n=sstab_wid.p_NofTabs;
      for( i=0; i < n; ++i ) {
         sstab_wid._getTabInfo(i,info);
         if( stranslate(info.caption,'','&') == "Log" ) {
            int log_wid = sstab_wid._find_control("_ctl_log");
            if( log_wid > 0 ) {
               if( log_wid.p_buf_name == fcp_p->logBufName ) {
                  // We only refresh the log if it is for this connection
                  log_wid.bottom();
                  log_wid.refresh();
               }
            }
         }
      }
   }
}

/**
 * Send a command to an FTP socket. Handle any error condition sent back
 * throught the socket. If quiet is true then the command itself is not
 * logged.
 *
 * @param fcp_p       Pointer to current connection struct.
 * @param quiet       true=Do not log command.
 * @param cmd         Command to send to FTP socket (i.e. - "USER", "PASV", etc.).
 *                    If this argument is an array then it is in the format:
 *                    cmd[0] = Name of the command
 *                    cmd[1] ... cmd[n] = Arguments to the command
 *                    and all other argument are ignored.
 * @param arg1...argN Additional arguments to append to cmd.
 *
 * @return 0 if successful. Common return codes are:
 *   SOCK_NOT_INIT_RC
 *   SOCK_TIMED_OUT_RC
 */
int _ftpCommand(FtpConnProfile *fcp_p,boolean quiet,typeless cmd,...)
{
   if( !vssIsConnectionAlive(fcp_p->sock) ) {
      _ftpLog(fcp_p,"Connection lost");
      return(VSRC_FTP_CONNECTION_DEAD);
   }
   int i=0;
   _str line='';
   if( cmd._varformat()==VF_ARRAY ) {
      // We have an array representing the command and arguments
      line=strip(cmd[0]);
      for( i=1;i<cmd._length();++i ) {
         line=line" "cmd[i];
      }
   } else {
      // Append additional arguments
      line=strip(cmd);
      if( substr(line,length(line),1)=="\n" ) {   // Strip eol
         if( substr(line,length(line)-1,1)=="\r" ) {
            line=substr(line,1,length(line)-2);
         } else {
            line=substr(line,1,length(line)-1);
         }
      }
      for( i=4;i<=arg();++i ) {
         line=line" "arg(i);
      }
   }

   // Log any responses that may have come in already.
   // This could happen if we aborted a command before we got the
   // response, or if the ftp server spontaneously sent a message.
   FtpQEvent event;   // Fake event
   event._makeempty();
   event.event=0;
   event.fcp= *fcp_p;
   event.start=0;
   event.state=0;
   _str dummy='';
   int status=_ftpQCheckResponse(&event,false,dummy,false);
   if( status ) {
      // Don't care
   }

   if( !quiet || _ftpdebug ) {
      _ftpLog(fcp_p,line);
   }

   //line=line:+EOL;
   line=line:+"\r\n";   // Use telnet NVT protocol linebreak
   status=vssSocketSendZ(fcp_p->sock,_UTF8ToMultiByte(line));

   return(status);
}

int _ftpPass(FtpConnProfile *fcp_p,_str pass)
{
   if( !vssIsConnectionAlive(fcp_p->sock) ) {
      _ftpLog(fcp_p,"Connection lost");
      return(VSRC_FTP_CONNECTION_DEAD);
   }
   //line="PASS ":+pass:+EOL;
   _str line="PASS ":+pass:+"\r\n";   // Use telnet NVT protocol linebreak
   _ftpLog(fcp_p,"PASS (hidden)");
   int status=vssSocketSendZ(fcp_p->sock,_UTF8ToMultiByte(line));

   return(status);
}

int _ftpType(FtpConnProfile* fcp_p, FtpXferType override_xfer_type=0)
{
   FtpXferType xfer_type = fcp_p->xferType;
   if( override_xfer_type != 0 ) {
      xfer_type = override_xfer_type;
   }
   // Ascii or Binary transfer?
   int status = 0;
   switch( xfer_type ) {
   case FTPXFER_ASCII:
      status = _ftpCommand(fcp_p,false,"TYPE","A");
      break;
   case FTPXFER_BINARY:
      status = _ftpCommand(fcp_p,false,"TYPE","I");
      break;
   default:
      // Should never get here
      status = _ftpCommand(fcp_p,false,"TYPE","I");
   }

   return(status);
}

/**
 * Convert a remote path from SlickEdit's format for MVS files
 * to the MVS FTP native format.
 * <P>
 * Note: It is assumed that remote_path is absolute.
 *
 * @example
 * <PRE>
 *   SlickEdit      MVS Native FTP
 *   ------------------------------------
 *   //PDS.NAME/MEMBER     PDS.NAME(MEMBER)
 *   //SDSNAME             SDSNAME
 * </PRE>
 */
_str _ftpConvertSEtoMVSFilename(_str remote_path)
{
   if( substr(remote_path,1,2)=='//' ) {
      remote_path=substr(remote_path,3);
      if( pos('/',remote_path) ) {
         // PDS member
         _str pds, member;
         parse remote_path with pds '/' member;
         remote_path=pds:+'(':+member:+')';
      } else {
         // SDS
         // Nothing to do
      }
   }

   return(remote_path);
}

/**
 * Convert a remote path from MVS FTP native format to SlickEdit's
 * format.
 * <P>
 * Note: It is assumed that remote_path is absolute.
 *
 * @example
 * <PRE>
 *   MVS Native FTP        SlickEdit
 *   --------------------------------------
 *   PDS.NAME(MEMBER)      //PDS.NAME/MEMBER
 *   SDSNAME               //SDSNAME
 * </PRE>
 */
_str _ftpConvertMVStoSEFilename(_str remote_path)
{
   if( substr(remote_path,1,1)!='/' &&
       pos('^[~\.]#(\.[~\.]#)@(\.|)(\([~\(]#\)|)',remote_path,1,'r') ) {
      if( last_char(remote_path)==')' ) {
         // PDS member
         _str pds, member;
         parse remote_path with pds '(' member ')';
         remote_path='//':+pds:+'/':+member;
      } else {
         // SDS
         remote_path='//':+remote_path;
      }
   }

   return(remote_path);
}

/**
 * Convert a remote path from SlickEdit's format for OS/400 LFS files
 * to the OS/400 FTP native format.
 * <P>
 * Note: It is assumed that remote_path is absolute.
 *
 * @example
 * <PRE>
 *   SlickEdit                OS/400 Native FTP
 *   --------------------------------------------
 *   //LIBNAME/FILE/MEMBER    LIBNAME/FILE.MEMBER
 * </PRE>
 */
_str _ftpConvertSEtoOS400Filename(_str remote_path)
{
   if( substr(remote_path,1,2)=='//' ) {
      remote_path=substr(remote_path,3);
      _str libname, file, member;
      parse remote_path with libname '/' file '/' member;
      remote_path=libname:+'/':+file;
      if( member!="" ) {
         remote_path=remote_path:+'.':+member;
      }
   }

   return(remote_path);
}

/**
 * Convert a remote path from OS/400 FTP native format for LFS files to
 * SlickEdit's format.
 * <P>
 * Note: It is assumed that remote_path is absolute.
 *
 * @example
 * <PRE>
 *   OS/400 Native FTP        SlickEdit
 *   ----------------------------------------------
 *   LIBNAME/FILE.MEMBER      //LIBNAME/FILE/MEMBER
 * </PRE>
 */
_str _ftpConvertOS400toSEFilename(_str remote_path)
{
   if( substr(remote_path,1,1)!='/' &&
       pos('^[~/.]#/[~/.]#(\.[~/.]#|)',remote_path,1,'r') ) {
      _str libname, file, member;
      parse remote_path with libname '/' file '.' member;
      remote_path='//':+libname:+'/':+file;
      if( member!="" ) {
         remote_path=remote_path:+'/':+member;
      }
   }

   return(remote_path);
}

_str _ftpLocalAbsolute(FtpConnProfile *fcp_p,_str local_path)
{
   _str localcwd=fcp_p->localCwd;
   _str abs_path=absolute(maybe_quote_filename(local_path),localcwd);

   return(abs_path);
}

_str _ftpAbsolute(FtpConnProfile* fcp_p, _str remote_path, _str toDir=null)
{
   // Relative directory to use when forming absolute path
   _str remoteCWD;
   if( toDir != null ) {
      // Use specific relative-directory
      remoteCWD = toDir;
   } else {
      // Use the current relative-directory
      remoteCWD = fcp_p->remoteCwd;
   }

   _str return_path = '';
   _str cwd = '';
   switch( fcp_p->system ) {
   case FTPSYST_VMS:
   case FTPSYST_VMS_MULTINET:
      if( pos('^[~\[]@\:\[?@\]',remote_path,1,'r') ) {
         // Already absolute
         return_path = remote_path;
      } else {
         cwd = remoteCWD;
         return_path = cwd:+remote_path;
      }
      break;
   case FTPSYST_VOS:
      if( pos('^[~\>]@\>',remote_path,1,'r') ) {
         // Already absolute
         return_path = remote_path;
      } else {
         cwd = remoteCWD;
         if( last_char(cwd) != '>' ) {
            cwd = cwd:+'>';
         }
         return_path = cwd:+remote_path;
      }
      break;
   case FTPSYST_VM:
   case FTPSYST_VMESA:
      // VM has no concept of an absolute filename, so make up one
      if( substr(remote_path,1,1) == '/' ) {
         // Already absolute
         return_path = remote_path;
      } else {
         // This is a CMS minidisk
         cwd = remoteCWD;
         return_path = '/':+cwd:+'/':+remote_path;
      }
      break;
   case FTPSYST_MVS:
      // Absolute dataset paths are enclosed by single-quotes
      boolean mvs_quoted = ( substr(remote_path,1,1) == "'" && last_char(remote_path) == "'" );
      if( mvs_quoted ) {
         remote_path = strip(remote_path,'B',"'");
      }
      remote_path = _ftpConvertSEtoMVSFilename(remote_path);
      if( substr(remote_path,1,1) == '/' ) {
         // HFS file system which mimics Unix
         // Already absolute
         return_path = remote_path;
      } else if( mvs_quoted ) {
         // Single-quoted therefore absolute
         // Already absolute
         return_path = remote_path;
      } else {
         // Relative
         if( substr(remoteCWD,1,1) == '/' ) {
            // HFS file system which mimics Unix
            cwd = remoteCWD;
            if( last_char(cwd) != '/' ) {
               cwd=cwd:+'/';
            }
            return_path = cwd:+remote_path;
         } else {
            if( pos('^[~\.]#(\.[~\.]#)@(\.|)\([~\(]#\)',remote_path,1,'r') ) {
               // PDS member
               cwd = remoteCWD;
               if( last_char(cwd) != '.' ) {
                  cwd = cwd:+'.';
               }
               return_path = cwd:+remote_path;
            } else if( pos('.',remote_path) || fcp_p->remoteDir.flags & FTPDIRTYPE_MVS_VOLUME ) {
               // SDS format
               cwd = remoteCWD;
               if( last_char(cwd) != '.' ) {
                  cwd=cwd:+'.';
               }
               return_path = cwd:+remote_path;
            } else {
               // PDS format
               cwd = remoteCWD;
               return_path = cwd:+'(':+remote_path:+')';
            }
         }
      }
      break;
   case FTPSYST_OS2:
      // OS/2 is flexible about file separators. Both '/' and '\' are allowed
      remote_path = translate(remote_path,'/','\');
      if( pos('^[a-zA-Z]\:/$',substr(remote_path,1,3),1,'er') ) {
         // Already absolute
         return_path = remote_path;
      } else {
         cwd = remoteCWD;
         // OS/2 is flexible about file separators. Both '/' and '\' are allowed
         cwd = translate(cwd,'/','\');
         if( last_char(cwd) != '/' ) {
            cwd = cwd:+'/';
         }
         return_path = cwd:+remote_path;
      }
      break;
   case FTPSYST_OS400:
      remote_path = _ftpConvertSEtoOS400Filename(remote_path);
      if( substr(remote_path,1,1) == '/' ) {
         // IFS format
         // Already absolute
         return_path = remote_path;
      } else {
         // IFS or LFS
         cwd = remoteCWD;
         if( substr(cwd,1,1) == '/' ) {
            // IFS
            if( last_char(cwd) != '/' ) {
               cwd = cwd:+'/';
            }
            return_path = cwd:+remote_path;
         } else {
            // LFS
            _str libname, filename;
            parse remote_path with libname '/' filename;
            if( libname != "" && filename != "" ) {
               // Already absolute
               return_path = remote_path;
            } else {
               // Relative to current library
               if( last_char(cwd) != '/' ) {
                  cwd = cwd:+'/';
               }
               return_path = cwd:+remote_path;
            }
         }
      }
      break;
   case FTPSYST_WINNT:
   case FTPSYST_HUMMINGBIRD:
      if( substr(remote_path,1,1) == '/' ) {
         // Unix style
         // Already absolute
         return_path = remote_path;
      } else {
         if( pos('^[a-zA-Z]\:\\',remote_path,1,'er') ) {
            // DOS style
            // Already absolute
            return_path = remote_path;
         } else {
            // Relative
            cwd = remoteCWD;
            if( substr(cwd,1,1) == '/' ) {
               // Unix style
               if( last_char(cwd) != '/' ) {
                  cwd = cwd:+'/';
               }
               return_path = cwd:+remote_path;
            } else {
               // DOS style
               if( last_char(cwd) != "\\" ) {
                  cwd = cwd:+"\\";
               }
               return_path = cwd:+remote_path;
            }
         }
      }
      break;
   case FTPSYST_NETWARE:
   case FTPSYST_MACOS:
   case FTPSYST_VXWORKS:
   case FTPSYST_UNIX:
   default:
      if( substr(remote_path,1,1) == '/' ) {
         // Already absolute
         return_path = remote_path;
      } else {
         cwd = remoteCWD;
         if( last_char(cwd) != '/' ) {
            cwd = cwd:+'/';
         }
         return_path = cwd:+remote_path;
      }
   }

   return(return_path);
}

boolean _ftpIsDir(FtpConnProfile *fcp_p,_str remote_path)
{
   boolean isdir=false;
   _str path='';
   _str filename='';
   switch( fcp_p->system ) {
   case FTPSYST_VMS:
   case FTPSYST_VMS_MULTINET:
      if( pos('^[~\[]@\:\[?@\]',remote_path,1,'r') ) {
         parse remote_path with . '[' path ']' filename;
         if( filename=="" ) isdir=true;
      }
      break;
   case FTPSYST_VOS:
      if( last_char(remote_path)=='>' ) isdir=true;
      break;
   case FTPSYST_VM:
   case FTPSYST_VMESA:
      // Since VM has no concept of a CMS minidisk other than the current
      // one, we might get passed a path with leading and trailing '/'s
      // which is the format we dreamed up to represent a distinct minidisk.
      remote_path=strip(remote_path,'B','/');
      if( pos('^[A-Za-z0-9$#@+-:_]#\.[A-Za-z0-9$#@+-:_]#$',remote_path,1,'er') ) {
         isdir=true;
      }
      break;
   case FTPSYST_MVS:
      boolean mvs_quoted= (substr(remote_path,1,1)=="'" && last_char(remote_path)=="'");
      if( mvs_quoted ) {
         remote_path=strip(remote_path,'B',"'");
      }
      if( substr(remote_path,1,1)=='/' ) {
         // HFS file system which mimics Unix OR SlickEdit '//' dataset format
         if( substr(remote_path,1,2)=='//' ) {
            // SE '//' dataset format
            remote_path=substr(remote_path,3);
            if( last_char(remote_path)=='/' ) {
               isdir=true;
            } else {
               if( pos('^[~\.]#\.$',remote_path,1,'ir') ) {
                  // Qualifier
                  isdir=true;
               }
            }
         } else {
            // HFS
            if( last_char(remote_path)=='/' ) isdir=true;
         }
      } else {
         // PDS or SDS format
         if( pos('^[~\.]#\.$',remote_path,1,'ir') ) {
            // Qualifier
            isdir=true;
         }
      }
      break;
   case FTPSYST_OS2:
      // OS/2 is flexible about file separators. Both '/' and '\' are allowed
      remote_path=translate(remote_path,'/','\');
      if( last_char(remote_path)=='/' ) isdir=true;
      break;
   case FTPSYST_OS400:
      if( last_char(remote_path)=='/' ) isdir=true;
      break;
   case FTPSYST_NETWARE:
   case FTPSYST_MACOS:
   case FTPSYST_VXWORKS:
   case FTPSYST_UNIX:
   default:
      if( last_char(remote_path)=='/' ) isdir=true;
   }

   return(isdir);
}

_str _ftpUploadCase(FtpConnProfile *fcp_p,_str filename)
{
   if( fcp_p->uploadCase==FTPFILECASE_LOWER ) {
      return(lowcase(filename));
   } else if( fcp_p->uploadCase==FTPFILECASE_PRESERVE ) {
      return(filename);
   } else {
      // FTPFILECASE_UPPER
      return(upcase(filename));
   }
}

/**
 * Strip off parts of filename.
 * <P>
 * 'P' = path <BR>
 * 'S' = file separator (e.g. '/' for Unix hosts) <BR>
 * 'N' = name <BR>
 * 'E' = extension <BR>
 * 'V' = version number (VM hosts use these)
 *
 * @param fcp_p
 *
 * @param remote_path
 *
 * @param options
 *
 * @return
 */
_str _ftpStripFilename(FtpConnProfile *fcp_p,_str remote_path,_str options)
{
   _str path, filesep, filename, ext, version;
   path=filesep=filename=ext=version="";
   int i=0;
   switch( fcp_p->system ) {
   case FTPSYST_VMS:
   case FTPSYST_VMS_MULTINET:
      if( substr(remote_path,1,1)=='/' ) remote_path=substr(remote_path,2);
      i=lastpos(']',remote_path);
      if( i ) {
         path=substr(remote_path,1,i);
         filename=substr(remote_path,i+1);
      } else {
         path="";
         filename=remote_path;
      }
      filesep='';
      // VMS filenames have version numbers at the end (e.g. ";1")
      parse filename with filename ';' version;
      break;
   case FTPSYST_VOS:
      if( substr(remote_path,1,1)=='/' ) remote_path=substr(remote_path,2);
      i=lastpos('>',remote_path);
      if( i ) {
         path=substr(remote_path,1,i);
         filename=substr(remote_path,i+1);
         filesep='';
         if( last_char(path)=='>' ) {
            path=substr(path,1,length(path)-1);
            filesep='>';
         }
      } else {
         path="";
         filename=remote_path;
         filesep='';
      }
      break;
   case FTPSYST_VM:
   case FTPSYST_VMESA:
      if( substr(remote_path,1,1)=='/' ) remote_path=substr(remote_path,2);
      // We had to dream up an absolute filespec format because VM
      // has no concept of it. 'path' = CMS minidisk.
      i=lastpos('/',remote_path);
      if( i ) {
         path=substr(remote_path,1,i);
         filename=substr(remote_path,i+1);
         filesep='';
         if( last_char(path)=='/' ) {
            path=substr(path,1,length(path)-1);
            filesep='/';
         }
      } else {
         path="";
         filename=remote_path;
         filesep='';
      }
      break;
   case FTPSYST_MVS:
      remote_path=strip(remote_path,'B',"'");
      remote_path=_ftpConvertSEtoMVSFilename(remote_path);
      if( substr(remote_path,1,1)!='/' && pos('^[~\.]#(\.[~\.]#)@(\.|)(\([~\(]#\)|)',remote_path,1,'er') ) {
         // PDS or SDS format
         if( last_char(remote_path)==')' ) {
            // PDS format
            parse remote_path with path '(' filename ')';
         } else {
            // SDS format
            i=pos('.',remote_path);
            if( i ) {
               path=substr(remote_path,1,i);
               filename=substr(remote_path,i+1);
            } else {
               path="";
               filename=remote_path;
            }
         }
         filesep='';
      } else {
         // HFS format which mimics Unix
         i=lastpos('/',remote_path);
         if( i ) {
            path=substr(remote_path,1,i);
            filename=substr(remote_path,i+1);
            filesep='';
            if( last_char(path)=='/' ) {
               path=substr(path,1,length(path)-1);
               filesep='/';
            }
         } else {
            path="";
            filename=remote_path;
            filesep='';
         }
      }
      break;
   case FTPSYST_OS2:
      remote_path=translate(remote_path,'/','\');
      if( substr(remote_path,1,1)=='/' ) remote_path=substr(remote_path,2);
      i=lastpos('/',remote_path);
      if( i ) {
         path=substr(remote_path,1,i);
         filename=substr(remote_path,i+1);
         filesep='';
         if( last_char(path)=='/' ) {
            path=substr(path,1,length(path)-1);
            filesep='/';
         }
      } else {
         path="";
         filename=remote_path;
         filesep='';
      }
      break;
   case FTPSYST_OS400:
      remote_path=_ftpConvertSEtoOS400Filename(remote_path);
      if( substr(remote_path,1,1)=='/' ) {
         // IFS format
         i=lastpos('/',remote_path);
         if( i ) {
            path=substr(remote_path,1,i);
            filename=substr(remote_path,i+1);
            filesep='';
            if( last_char(path)=='/' ) {
               path=substr(path,1,length(path)-1);
               filesep='/';
            }
         } else {
            path="";
            filename=remote_path;
            filesep='';
         }
      } else {
         // LFS format
         parse remote_path with path '/' filename;
         filesep='';
         if( pos('/',remote_path) ) {
            filesep='/';
         }
      }
      break;
   case FTPSYST_WINNT:
   case FTPSYST_HUMMINGBIRD:
      if( substr(remote_path,1,1)=='/' ) {
         // Unix style
         i=lastpos('/',remote_path);
         if( i ) {
            path=substr(remote_path,1,i);
            filename=substr(remote_path,i+1);
            filesep='';
            if( last_char(path)=='/' ) {
               path=substr(path,1,length(path)-1);
               filesep='/';
            }
         } else {
            path="";
            filename=remote_path;
            filesep='';
         }
      } else {
         // DOS style
         i=lastpos("\\",remote_path);
         if( i ) {
            path=substr(remote_path,1,i);
            filename=substr(remote_path,i+1);
            filesep='';
            if( last_char(path)=="\\" ) {
               path=substr(path,1,length(path)-1);
               filesep="\\";
            }
         } else {
            path="";
            filename=remote_path;
            filesep='';
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
         path=substr(remote_path,1,i);
         filename=substr(remote_path,i+1);
         filesep='';
         if( last_char(path)=='/' ) {
            path=substr(path,1,length(path)-1);
            filesep='/';
         }
      } else {
         path="";
         filename=remote_path;
         filesep='';
      }
   }
   i=lastpos('.',filename);
   _str name='';
   if( i ) {
      name=substr(filename,1,i-1);
      ext=substr(filename,i+1);
   } else {
      name=filename;
      ext="";
   }

   _str return_value="";
   options=upcase(options);
   if( !pos('P',options) ) {
      return_value=return_value:+path;
      if( !pos('S',options) || !pos('N',options) ) {
         return_value=return_value:+filesep;
      }
   }
   if( !pos('N',options) ) {
      return_value=return_value:+name;
      if( !pos('E',options) && ext!="" ) {
         return_value=return_value:+'.':+ext;
         if( !pos('V',options) && version!="" ) {
            return_value=return_value:+';':+version;
         }
      }
   }

   return(return_value);
}

boolean _ftpFileEq(FtpConnProfile *fcp_p,_str file1,_str file2)
{
   _str fcase=_ftpFileCase(fcp_p);
   if( upcase(fcase)=='E' ) {
      return(file1:==file2);
   } else {
      return(strieq(file1,file2));
   }
}

_str _ftpFileCase(FtpConnProfile *fcp_p)
{
   _str fcase;

   fcase="";
   switch( fcp_p->system ) {
   case FTPSYST_MVS:
      if( substr(fcp_p->remoteCwd,1,1)=='/' ) {
         // HFS file system which mimics Unix
         fcase='e';
      } else {
         // PDS format
         fcase='i';
      }
      break;
   case FTPSYST_OS2:
      fcase='i';
      break;
   case FTPSYST_OS400:
      fcase='i';
      break;
   case FTPSYST_UNIX:
      fcase='e';
      break;
   case FTPSYST_VM:
   case FTPSYST_VMESA:
      fcase='i';
      break;
   case FTPSYST_VMS:
   case FTPSYST_VMS_MULTINET:
      fcase='i';
      break;
   case FTPSYST_VOS:
      fcase='e';
      break;
   case FTPSYST_WINNT:
   case FTPSYST_HUMMINGBIRD:
      // We believe that it is case-insensitive whether using Unix or DOS style
      fcase='i';
      break;
   case FTPSYST_NETWARE:
      fcase='e';
      break;
   case FTPSYST_MACOS:
      fcase='e';
      break;
   case FTPSYST_VXWORKS:
      fcase='e';
      break;
   default:
      fcase='e';
   }

   return(fcase);
}

boolean _RemoteFilespecMatches(FtpConnProfile *fcp_p,_str filespec,_str filename,_str fcase="")
{
   if( fcase=="" ) {
      fcase=_ftpFileCase(fcp_p);
   }
   if( fcase=="" ) fcase='e';
   filespec=strip(filespec);
   if( filespec=='*' ) return(true);
   _str filespec_re=stranslate(filespec,'?*','*');
   filespec_re=stranslate(filespec_re,'\\','\');

   switch( fcp_p->system ) {
   case FTPSYST_OS2:
   case FTPSYST_WINNT:
   case FTPSYST_HUMMINGBIRD:
      if( substr(filespec_re,length(filespec_re)-2,2)=='.*' ) {
         filespec_re=substr(filespec_re,1,length(filespec_re)-2):+'(.|)?*';
      }
      break;
   }

   filespec_re='^'filespec_re'$';
   int p=pos(filespec_re,filename,1,'r'fcase);
   return( p!=0 );
}

/**
 * Checks if name is a valid file/directory/link in the connection
 * profile's current working directory. If the file/directory/link exists,
 * then flags are set to the type flags for the matching entry.
 */
boolean _ftpExists(FtpConnProfile *fcp_p,_str name,int &flags)
{
   FtpFile file;

   int i,len=fcp_p->remoteDir.files._length();
   for( i=0;i<len;++i ) {
      file=fcp_p->remoteDir.files[i];
      if( _ftpFileEq(fcp_p,file.filename,name) ) {
         flags=file.type;
         return(true);
      }
   }

   return(false);
}

void _ftpFakeFile(FtpFile *file, _str filename, int type, typeless size)
{
   (*file)._makeempty();
   file->attribs="";
   _str month, day, year;
   parse _date('U') with month '/' day '/' year;
   switch( (int)month ) {
   case 1:
      month='Jan';
      break;
   case 2:
      month='Feb';
      break;
   case 3:
      month='Mar';
      break;
   case 4:
      month='Apr';
      break;
   case 5:
      month='May';
      break;
   case 6:
      month='Jun';
      break;
   case 7:
      month='Jul';
      break;
   case 8:
      month='Aug';
      break;
   case 9:
      month='Sep';
      break;
   case 10:
      month='Oct';
      break;
   case 11:
      month='Nov';
      break;
   case 12:
      month='Dec';
      break;
   }
   file->day= (int)day;
   file->month=month;
   file->year= (int)year;
   _str time=_time('M');
   _str hours, minutes;
   parse time with hours ':' minutes ':' .;
   time=hours:+':':+minutes;
   file->time=time;
   file->filename=filename;
   file->group="";
   file->owner="";
   file->refs=0;
   file->size=size;
   file->type=type;
}

// Insert a file/folder into the current remote file listing
void _ftpInsertFile(FtpConnProfile *fcp_p,FtpFile insert)
{
   FtpFile file;

   int i,len=fcp_p->remoteDir.files._length();
   for( i=0;i<len;++i ) {
      file=fcp_p->remoteDir.files[i];
      if( _ftpFileEq(fcp_p,file.filename,insert.filename) ) {
         fcp_p->remoteDir.files._deleteel(i);
         break;
      }
   }
   len=fcp_p->remoteDir.files._length();
   fcp_p->remoteDir.files[len]=insert;
}

/**
 * Tests whether there is an FTP operation currently
 * in progress. This is an especially useful test to make before exiting
 * the editor.
 */
boolean _ftpInProgress()
{
   if( _ftpQ._length()<1 ) return(false);

   int i;
   for( i=0;i<_ftpQ._length();++i ) {
      if( _ftpQ[i].event!=QE_END_CONN_PROFILE &&
          _ftpQ[i].event!=QE_KEEP_ALIVE ) {
         return(true);
      }
   }

   return(false);
}

boolean _ftpIsConnectionAlive(FtpConnProfile *fcp_p)
{
   boolean alive;

   if( fcp_p->serverType==FTPSERVERTYPE_SFTP ) {
      alive= ( fcp_p->ssh_hprocess>=0 && _PipeIsProcessExited(fcp_p->ssh_hprocess)==0 );
   } else {
      // FTP
      alive= ( fcp_p->sock!=INVALID_SOCKET &&
               _IsProcessRunning(fcp_p->vsproxy_pid) &&
               vssIsConnectionAlive(fcp_p->sock)!=0 &&
               vssIsConnectionAlive(fcp_p->vsproxy_sock)!=0 );
   }

   return(alive);
}

// Use this to optimize the number of updates
static boolean _in_MaybeUpdate=false;

/**
 * Used to update the session on the FTP Client toolbar.
 * FTP Client session will be updated if its profile matches
 * the one passed in.
 */
void _MaybeUpdateFTPClient(_str profile)
{
   int clientformWid;
   int clientprofileWid;

   if( _in_MaybeUpdate ) return;

   // Update the FTP Client toolbar.
   // IF visible AND we can find the profile combo box.
   // IF there is no active connection OR the FTP Client toolbar is showing
   // the same connection as profile name passed in.
   clientformWid=_find_object("_tbFTPClient_form","N");
   if( !clientformWid ) return;
   clientprofileWid=clientformWid._find_control("_ctl_profile");
   if( !clientprofileWid ) return;
   if( profile=="" || clientprofileWid.p_text=="" || clientprofileWid.p_text==profile ) {
      _in_MaybeUpdate=true;
      clientprofileWid.call_event(CHANGE_SELECTED,clientprofileWid,ON_CHANGE,'W');
      #if 1
      // Now synch up the progress labels between the 2 toolbars
      int openformWid=_find_object("_tbFTPOpen_form","N");
      if( openformWid ) {
         int clientlabel1Wid=clientformWid._find_control("_ctl_progress_label1");
         int clientlabel2Wid=clientformWid._find_control("_ctl_progress_label2");
         int openlabel1Wid=openformWid._find_control("_ctl_operation");
         int openlabel2Wid=openformWid._find_control("_ctl_nofbytes");
         if( clientlabel1Wid && clientlabel2Wid && openlabel1Wid && openlabel2Wid ) {
            clientlabel1Wid.p_caption=openlabel1Wid.p_caption;
            clientlabel2Wid.p_caption=openlabel2Wid.p_caption;
         }
      }
      #endif
      _in_MaybeUpdate=false;
   }
}

/**
 * Used to update the session on the FTP Open tab.
 * FTP Open tab session will be updated if its profile matches
 * the one passed in.
 */
void _MaybeUpdateFTPTab(_str profile)
{
   int openformWid;
   int openprofileWid;

   if( _in_MaybeUpdate ) return;

   // Update the FTP Open tab.
   // IF visible AND we can find the profile combo box.
   // IF there is no active connection OR the FTP open tab is showing
   // the same connection as profile name passed in.
   openformWid=_find_object("_tbFTPOpen_form","N");
   if( !openformWid ) return;
   openprofileWid=openformWid._find_control("_ctl_profile");
   if( !openprofileWid ) return;
   if( profile=="" || openprofileWid.p_text=="" || openprofileWid.p_text==profile ) {
      _in_MaybeUpdate=true;
      // '1' as the second argument forces a refresh
      openprofileWid.call_event(CHANGE_SELECTED,0,openprofileWid,ON_CHANGE,'W');
      #if 1
      // Now synch up the progress labels between the 2 toolbars
      int clientformWid=_find_object("_tbFTPClient_form","N");
      if( clientformWid ) {
         int openlabel1Wid=openformWid._find_control("_ctl_operation");
         int openlabel2Wid=openformWid._find_control("_ctl_nofbytes");
         int clientlabel1Wid=clientformWid._find_control("_ctl_progress_label1");
         int clientlabel2Wid=clientformWid._find_control("_ctl_progress_label2");
         if( openlabel1Wid && openlabel2Wid && clientlabel1Wid && clientlabel2Wid ) {
            openlabel1Wid.p_caption=clientlabel1Wid.p_caption;
            openlabel2Wid.p_caption=clientlabel2Wid.p_caption;
         }
      }
      #endif
      _in_MaybeUpdate=false;
   }
}

/**
 * Used for serious debugging.
 */
void _ftpDebugSayConnProfile(FtpConnProfile *fcp_p)
{
   say('ProfileName='fcp_p->profileName);
   say('Instance='fcp_p->instance);
   say('Host='fcp_p->host);
   say('UserID='fcp_p->userId);
   say('Password='fcp_p->password);
   say('Anonymous='fcp_p->anonymous);
   say('SavePassword='fcp_p->savePassword);
   say('XferType='fcp_p->xferType);
   say('DefRemoteHostDir='fcp_p->defRemoteDir);
   say('DefLocalDir='fcp_p->defLocalDir);
   say('Port='fcp_p->port);
   say('Timeout='fcp_p->timeout);
   say('UseFW='fcp_p->useFirewall);
   say('KeepAlive='fcp_p->keepAlive);
   say('UploadCase='fcp_p->uploadCase);
   say('ResolveLinks='fcp_p->resolveLinks);
   say('Options.email='fcp_p->global_options.email);
   say('Options.deflocaldir='fcp_p->global_options.deflocaldir);
   say('Options.put='fcp_p->global_options.put);
   say('Options.resolvelinks='fcp_p->global_options.resolvelinks);
   say('Options.timeout='fcp_p->global_options.timeout);
   say('Options.port='fcp_p->global_options.port);
   say('Options.keepalive='fcp_p->global_options.keepalive);
   say('Options.uploadcase='fcp_p->global_options.uploadcase);
   say('Options.fwhost='fcp_p->global_options.fwhost);
   say('Options.fwport='fcp_p->global_options.fwport);
   say('Options.fwuserid='fcp_p->global_options.fwuserid);
   say('Options.fwpassword='fcp_p->global_options.fwpassword);
   say('Options.fwtype='fcp_p->global_options.fwtype);
   say('Options.fwpasv='fcp_p->global_options.fwpasv);
   say('Options.fwenable='fcp_p->global_options.fwenable);
   say('Options.sshexe='fcp_p->global_options.sshexe);
   say('Options.sshsubsystem='fcp_p->global_options.sshsubsystem);
   say('LastStatusLine='fcp_p->lastStatusLine);
   say('PrevStatusLine='fcp_p->prevStatusLine);
   say('sock='fcp_p->sock);
   say('vsproxy_sock='fcp_p->vsproxy_sock);
   say('vsproxy_pid='fcp_p->vsproxy_pid);
   say('ssh_hprocess='fcp_p->ssh_hprocess);
   say('ssh_hin='fcp_p->ssh_hin);
   say('ssh_hout='fcp_p->ssh_hout);
   say('ssh_herr='fcp_p->ssh_herr);
   say('ssh_checkerrors='fcp_p->ssh_checkerrors);
   say('sftp_opid='fcp_p->sftp_opid);
   say('VSProxy='fcp_p->vsproxy);
   say('LogBufName='fcp_p->logBufName);
   say('RemoteDir._varformat()='fcp_p->remoteDir._varformat());
   //say('RemoteDir.files._length()='fcp_p->RemoteDir.files._length());
   say('LocalCWD='fcp_p->localCwd);
   say('RemoteCWD='fcp_p->remoteCwd);
   say('CwdHist._length()='fcp_p->cwdHist._length());
   say('LocalFileFilter='fcp_p->localFileFilter);
   say('RemoteFileFilter='fcp_p->remoteFileFilter);
   say('LocalSortFlags='fcp_p->localSortFlags);
   say('RemoteSortFlags='fcp_p->remoteSortFlags);
   say('AutoRefresh='fcp_p->autoRefresh);
   say('RemoteRoot='fcp_p->remoteRoot);
   say('LocalRoot='fcp_p->localRoot);
   say('Reply='fcp_p->reply);
   say('Idle='fcp_p->idle);
   say('ServerType='fcp_p->serverType);
   say('SSHAuthType='fcp_p->sshAuthType);
   say('System='fcp_p->system);
   say('PostedCB='fcp_p->postedCb);
   say('errorCb='fcp_p->errorCb);
   say('warnCb='fcp_p->warnCb);
   say('infoCb='fcp_p->infoCb);
   say('DirStack._length()='fcp_p->dir_stack._length());
   say('RecurseDirs='fcp_p->recurseDirs);
   say('IgnoreListErrors='fcp_p->ignoreListErrors);
   say('extra._varformat()='fcp_p->extra._varformat());

   return;
}

_str (*result_p):[];
defeventtab _ftpUserPass_form;
_ctl_ok.on_create(typeless pResults="", _str caption="", _str user="", _str pass="")
{
   result_p=null;
   // If this is not a pointer to a hash table, then the results go to never-never land
   if( pResults._varformat()==VF_PTR ) {
      result_p=pResults;
   }
   _ctl_pass.p_Password=true;
   if( caption!="" ) {
      p_active_form.p_caption=caption;
   }
   _ctl_user.p_text=user;
   _ctl_pass.p_text=pass;
}

_ftpUserPass_form.on_load()
{
   if( _ctl_user.p_text!="" ) {
      // Put focus on password since that is probably what the user wants
      p_window_id=_ctl_pass;
      _set_sel(1,length(p_text));
      _set_focus();
   }
}

_ctl_ok.lbutton_up()
{
   _str list:[];

   if( result_p ) {
      (*result_p)._makeempty();
      (*result_p):["user"]=_ctl_user.p_text;
      (*result_p):["pass"]=_ctl_pass.p_text;
   }

   p_active_form._delete_window(0);
}

_ctl_cancel.lbutton_up()
{
   p_active_form._delete_window('');
}

defeventtab _ftpUpload_form;
void _ctl_yes.on_create(_str filename="", _str transferType="", _str transferFlags="")
{
   FtpXferType xfer_type = 0;
   if( isinteger(transferType) && transferType>0 ) {
      xfer_type= (FtpXferType)transferType;
   }
   FtpXferFlags flags = 0;
   if( isinteger(transferFlags) && transferFlags>0 ) {
      flags = (FtpXferFlags)transferFlags;
   }

   _str msg=_ctl_msg.p_caption;
   msg=stranslate(msg,filename,'%s','i');
   _ctl_msg.p_caption=msg;

   if( xfer_type!=FTPXFER_ASCII && xfer_type!=FTPXFER_BINARY ) {
      // Assume it's ascii since the file is opened in a text editor
      xfer_type=FTPXFER_ASCII;
   }
   _ctl_xfer_ascii.p_value=_ctl_xfer_binary.p_value=0;
   if( xfer_type&FTPXFER_ASCII ) {
      _ctl_xfer_ascii.p_value=1;
   } else {
      _ctl_xfer_binary.p_value=1;
   }
   if( flags&FTPXFERFLAG_NOCHOICE ) {
      // Probably SFTP which always transfers binary
      _ctl_xfer_frame.p_visible = false;
      // Dialog looks stupid with all that blank space, so adjust up
      _ctl_msg2.p_y = _ctl_xfer_frame.p_y;
      _ctl_yes.p_y -= _ctl_xfer_frame.p_height;
      _ctl_no.p_y = _ctl_yes.p_y;
      p_active_form.p_height -= _ctl_xfer_frame.p_height;

   }
}

void _ftpUpload_form.on_load()
{
   p_window_id=_ctl_yes;
   _set_focus();
}

void _ctl_yes.lbutton_up()
{
   FtpXferType xfer_type = 0;
   if( _ctl_xfer_ascii.p_value ) {
      xfer_type = FTPXFER_ASCII;
   } else if( _ctl_xfer_binary.p_value ) {
      xfer_type = FTPXFER_BINARY;
   } else {
      // This should never happen
      ftpDisplayInfo("You must choose ASCII or BINARY upload");
      return;
   }

   p_active_form._delete_window((_str)xfer_type);
}

void _ctl_no.lbutton_up()
{
   p_active_form._delete_window('');
}

void _ftpUpload_form.'ESC'()
{
   _ctl_no.call_event(_ctl_no,LBUTTON_UP,'W');
}

defeventtab _ftpDownload_form;
void _ctl_ok.on_create(_str filename="", _str transferType="")
{
   FtpXferType xfer_type = 0;
   if( isinteger(transferType) && transferType>0 ) {
      xfer_type = (FtpXferType)transferType;
   }

   _str msg=_ctl_msg.p_caption;
   msg=stranslate(msg,filename,'%s','i');
   _ctl_msg.p_caption=msg;

   if( xfer_type!=FTPXFER_ASCII && xfer_type!=FTPXFER_BINARY ) {
      // Assume it's ascii since the file is opened in a text editor
      xfer_type=FTPXFER_ASCII;
   }
   _ctl_xfer_ascii.p_value=_ctl_xfer_binary.p_value=0;
   if( xfer_type&FTPXFER_ASCII ) {
      _ctl_xfer_ascii.p_value=1;
   } else {
      _ctl_xfer_binary.p_value=1;
   }
}

void _ctl_ok.lbutton_up()
{
   FtpXferType xfer_type = 0;
   if( _ctl_xfer_ascii.p_value ) {
      xfer_type=FTPXFER_ASCII;
   } else if( _ctl_xfer_binary.p_value ) {
      xfer_type=FTPXFER_BINARY;
   } else {
      // This should never happen
      ftpDisplayInfo("You must choose ASCII or BINARY download");
      return;
   }

   p_active_form._delete_window((_str)xfer_type);
}

void _ctl_cancel.lbutton_up()
{
   p_active_form._delete_window('');
}

// Temporary array of filenames
static _str _fm_files[];
// Current index into _fm_files[]. This will be 0 if find_first=1
static int _fm_idx=0;
_str ftpfile_match(_str name,int find_first)
{
   FtpConnProfile *fcp_p;

   fcp_p=null;
   // What you return depends on which toolbar you are in
   int formWid=_find_object("_ftpManualDownload_form","N");
   if( !formWid ) return("");
   _str form_name=formWid.p_parent.p_active_form.p_name;
   if( form_name=="_tbFTPClient_form" ) {
      fcp_p=ftpclientGetCurrentConnProfile();
   } else if( form_name=="_tbFTPOpen_form" ) {
      fcp_p=ftpopenGetCurrentConnProfile();
   }
   if( !fcp_p ) return("");
   if( find_first ) {
      _fm_files._makeempty();
      int i;
      for( i=0;i<(fcp_p->remoteDir.files._length());++i ) {
         _fm_files[i]=fcp_p->remoteDir.files[i].filename;
         int type=fcp_p->remoteDir.files[i].type;
         if( type&FTPFILETYPE_DIR ) {
            switch( fcp_p->system ) {
            case FTPSYST_VOS:
               _fm_files[i]=_fm_files[i]:+'>';
               break;
            case FTPSYST_OS2:
               // OS/2 is flexible about file separators. Both '/' and '\' are allowed
               _str fsep='/';
               if( pos('^[a-zA-Z]\:\\',fcp_p->remoteCwd,1,'er') ) {
                  fsep='\';
               }
               _fm_files[i]=_fm_files[i]:+fsep;
               break;
            default:
               _fm_files[i]=_fm_files[i]:+'/';
            }
         }
      }
      _fm_files._sort();
      _fm_idx=0;
   }
   _str filespec=name:+'*';
   for( ;_fm_idx<_fm_files._length(); ) {
      _str filename=_fm_files[_fm_idx++];
      boolean isdir=false;
      if( _RemoteFilespecMatches(fcp_p,filespec,filename) ) {
         last_char=substr(filename,length(filename),1);
         switch( last_char ) {
         case FTPSYST_VOS:
            isdir= (last_char=='>');
            break;
         case FTPSYST_OS2:
            // OS/2 is flexible about file separators. Both '/' and '\' are allowed
            _str fsep='/';
            if( pos('^[a-zA-Z]\:\\',fcp_p->remoteCwd,1,'er') ) {
               fsep='\';
            }
            isdir= (last_char==fsep);
            break;
         default:
            isdir= (last_char=='/');
         }
         _arg_complete= (_arg_complete && !isdir);
         return(filename);
      }
   }

   return("");
}

_str ftplocalfile_match(_str name,int find_first,_str doDirMatch="")
{
   FtpConnProfile *fcp_p;

   // Do a directory only match?
   boolean dir_match= (doDirMatch!="");

   fcp_p=null;
   int formWid=_find_object("_ftpManualDownload_form","N");
   if( !formWid ) {
      // Maybe it is _ftpChangeDir_form
      formWid=_find_object("_ftpChangeDir_form","N");
   }
   if( !formWid ) return("");
   // What you return depends on which toolbar you are in
   _str form_name=formWid.p_parent.p_active_form.p_name;
   if( form_name=="_tbFTPClient_form" ) {
      fcp_p=ftpclientGetCurrentConnProfile();
   } else if( form_name=="_tbFTPOpen_form" ) {
      fcp_p=ftpopenGetCurrentConnProfile();
   }
   if( !fcp_p ) return("");

   name=strip(name,'B','"');
   _str orig_name=name;
   name=_ftpLocalAbsolute(fcp_p,name);
   if( dir_match ) {
      name=file_match('+d +x "'name,find_first);
   } else {
      name=file_match('"'name,find_first);
   }
   _str option="";
   boolean last_char_is_filesep=last_char(name):==FILESEP;
   if( name:!="" ) {
      _arg_complete=(_arg_complete && !last_char_is_filesep);
      // Did they type the absolute path in themselves?
      if( !file_eq(orig_name,substr(name,1,length(orig_name))) ) {
         name=_strip_filename(name,'P');
      }
   }
   name=maybe_quote_filename(name);
   if( last_char_is_filesep ) {
      name=strip(name,'T','"');
   }

   return(_escape_unix_expansion(name));
}
_str ftplocaldir_match(_str name,int find_first)
{
   // arg(3)=1 means to do a directory only match
   return(ftplocalfile_match(name,find_first,1));
}

defeventtab _ftpManualDownload_form;
void _ctl_ok.on_create(_str src_filename="", _str dest_filename="",
                       int xferType=0, _str caption="",
                       FtpConnProfile *fcp_p = null)
{
   if( caption!="" ) {
      p_active_form.p_caption=caption;
   }

   _ctl_src_fname.p_text=src_filename;
   _ctl_dest_fname.p_text=dest_filename;

   FtpXferType xfer_type = xferType;
   if( xfer_type != FTPXFER_ASCII && xfer_type != FTPXFER_BINARY ) {
      if( fcp_p ) {
         xfer_type = fcp_p->xferType;
      } else {
         // Assume it's ascii since the file is opened in a text editor
         xfer_type = fcp_p->xferType;
      }
   }
   _ctl_xfer_ascii.p_value = _ctl_xfer_binary.p_value = 0;
   if( xfer_type & FTPXFER_ASCII ) {
      _ctl_xfer_ascii.p_value = 1;
   } else {
      _ctl_xfer_binary.p_value = 1;
   }
   if( fcp_p && fcp_p->serverType == FTPSERVERTYPE_SFTP ) {
      // SFTP is always a binary transfer, so this is noise to the user
      ctl_xfer_panel.p_visible = false;
   }

   if( pos("Upload",p_active_form.p_caption) ) {
      _ctl_src_fname.p_completion=FTPLOCALFILE_ARG;
      _ctl_dest_fname.p_completion=FTPFILE_ARG;
   } else {
      _ctl_src_fname.p_completion=FTPFILE_ARG;
      _ctl_dest_fname.p_completion=FTPLOCALFILE_ARG;
      if( pos("Open",p_active_form.p_caption) ) {
         // Called from FTP Open
         ctl_dst_panel.p_visible = false;
      }
   }

   if( !fcp_p || fcp_p->system != FTPSYST_OS400 ) {
      _ctl_os400_lfs.p_visible = false;
   }
}

void _ftpManualDownload_form.on_resize()
{
   if( !ctl_dst_panel.p_visible ) {
      // Pull everything below up
      int cy = ctl_xfer_panel.p_y - ctl_dst_panel.p_y;
      ctl_xfer_panel.p_y -= cy;
      ctl_button_panel.p_y -= cy;
      p_active_form.p_height -= cy;
   }
   if( !ctl_xfer_panel.p_visible ) {
      // Pull everything below up
      int cy = ctl_button_panel.p_y - ctl_xfer_panel.p_y;
      ctl_button_panel.p_y -= cy;
      p_active_form.p_height -= cy;
   }
}

void _ctl_ok.lbutton_up()
{
   _str src_filename=_ctl_src_fname.p_text;
   if( src_filename=="" ) {
      p_window_id=_ctl_src_fname;
      _set_focus();
      _str msg="You must specify a source filename";
      ftpDisplayInfo(msg);
      return;
   }
   _str dest_filename = ctl_dst_panel.p_visible ? _ctl_dest_fname.p_text : '';

   FtpXferType xfer_type = FTPXFER_BINARY;
   if( _ctl_xfer_ascii.p_value ) {
      xfer_type = FTPXFER_ASCII;
   } else if( _ctl_xfer_binary.p_value ) {
      xfer_type = FTPXFER_BINARY;
   } else {
      // This should never happen
      ASSERT(false);
   }

   boolean os400_lfs = (_ctl_os400_lfs.p_visible && _ctl_os400_lfs.p_value != 0 );

   _param1 = src_filename;
   _param2 = ctl_dst_panel.p_visible ? dest_filename : '';
   _param3 = xfer_type;
   _param4 = os400_lfs;

   p_active_form._delete_window(0);
}

void _ctl_cancel.lbutton_up()
{
   p_active_form._delete_window('');
}

void _ftpManualDownload_form.'ESC'()
{
   _ctl_cancel.call_event(_ctl_cancel,LBUTTON_UP,'W');
}

void _ctl_help.lbutton_up()
{
   _str msg='';
   if( pos("Upload",p_active_form.p_caption) ) {
      msg="Use this dialog to specify a file to upload. The source file does ":+
          "not have to reside in the current local working directory.";
   } else {
      msg="Use this dialog to specify a file to download/open. The source file ":+
          "does not have to reside in the current remote working directory.";
      if( _ctl_os400_lfs.p_visible ) {
         msg = msg :+
             "\n\n" :+
             "OS/400 users note:\n\n":+
             "":+'Select "OS/400 Library File System member" ':+
             "if you are downloading/opening an old style ":+
             "Library File System library member.";
      } else {
         msg = msg :+
             "\n\n" :+
             "VM users note:\n\n":+
             "To specify the path to a file on a CMS minidisk, " :+
             "other than the current minidisk, prefix the ":+
             "name of the file with '/minidisk/filename'.\n\n":+
             "Example: \n" :+
             "To specify the file INDEX.HTM on the " :+
             "WEB.191 minidisk you would use:\n\n":+
             "\t/WEB.191/INDEX.HTM";
      }
   }
   ftpDisplayInfo(msg);
}

defeventtab _ftpNew_form;
void _ctl_ok.on_create(_str remote_filename='', 
                       int xferType=0, 
                       _str caption='',
                       FtpConnProfile* fcp_p=null,
                       _str edit_options='')
{
   _SetDialogInfoHt('FtpConnProfile',fcp_p);

   if( caption != "" ) {
      p_active_form.p_caption = caption;
   }

   _ctl_fname.p_text = remote_filename;

   FtpXferType xfer_type = xferType;
   if( xfer_type != FTPXFER_ASCII && xfer_type != FTPXFER_BINARY ) {
      if( fcp_p ) {
         xfer_type = fcp_p->xferType;
      } else {
         // Assume it's ascii since the file is opened in a text editor
         xfer_type = fcp_p->xferType;
      }
   }
   _ctl_xfer_ascii.p_value = _ctl_xfer_binary.p_value = 0;
   if( xfer_type == FTPXFER_ASCII ) {
      _ctl_xfer_ascii.p_value = 1;
   } else {
      _ctl_xfer_binary.p_value = 1;
   }
   if( fcp_p && fcp_p->serverType == FTPSERVERTYPE_SFTP ) {
      // SFTP is always a binary transfer, so this is noise to the user
      ctl_xfer_panel.p_visible = false;
   }

   ctl_lf_local.p_value = 1;
   ctl_lf_dos.p_value   = 0;
   ctl_lf_unix.p_value  = 0;
   ctl_lf_mac.p_value   = 0;
   _str opt;
   while( edit_options != '' ) {
      parse edit_options with opt edit_options;
      switch( lowcase(opt) ) {
      case '+fd':
         // Windows/DOS line format
         ctl_lf_local.p_value = 0;
         ctl_lf_dos.p_value = 1;
         ctl_lf_unix.p_value = 0;
         ctl_lf_mac.p_value = 0;
         break;
      case '+fu':
         // UNIX line format
         ctl_lf_local.p_value = 0;
         ctl_lf_dos.p_value = 0;
         ctl_lf_unix.p_value = 1;
         ctl_lf_mac.p_value = 0;
         break;
      case '+fm':
         // Mac line format
         ctl_lf_local.p_value = 0;
         ctl_lf_dos.p_value = 0;
         ctl_lf_unix.p_value = 0;
         ctl_lf_mac.p_value = 1;
         break;
      }
   }
}

void _ftpNew_form.on_resize()
{
   if( !ctl_xfer_panel.p_visible ) {
      // Pull everything below up
      int cy = ctl_lineformat_panel.p_y - ctl_xfer_panel.p_y;
      ctl_lineformat_panel.p_y -= cy;
      ctl_button_panel.p_y -= cy;
      p_active_form.p_height -= cy;
   }
}

void _ctl_ok.lbutton_up()
{
   _str remote_filename=_ctl_fname.p_text;
   if( remote_filename=="" ) {
      p_window_id=_ctl_fname;
      _set_focus();
      _str msg="You must specify a new filename";
      ftpDisplayInfo(msg);
      return;
   }

   FtpXferType xfer_type = FTPXFER_BINARY;
   if( _ctl_xfer_ascii.p_value ) {
      xfer_type = FTPXFER_ASCII;
   } else if( _ctl_xfer_binary.p_value ) {
      xfer_type = FTPXFER_BINARY;
   } else {
      // This should never happen
      ASSERT(false);
   }

   _str edit_options = '';
   if( ctl_lf_dos.p_value ) {
      edit_options = edit_options' +fd';
   } else if( ctl_lf_unix.p_value ) {
      edit_options = edit_options' +fu';
   } else if( ctl_lf_mac.p_value ) {
      edit_options = edit_options' +fm';
   }

   _param1 = remote_filename;
   _param2 = xfer_type;
   _param3 = edit_options;

   p_active_form._delete_window(0);
}

void _ctl_cancel.lbutton_up()
{
   p_active_form._delete_window('');
}

void _ftpNew_form.'ESC'()
{
   _ctl_cancel.call_event(_ctl_cancel,LBUTTON_UP,'W');
}

void _ctl_help.lbutton_up()
{
   FtpConnProfile* fcp_p = _GetDialogInfoHt('FtpConnProfile');

   _str msg = "Specify the new remote file.":+
       "\n\n" :+
       "If you do not give a full path then it will be relative to ";
   if( fcp_p ) {
      msg = msg :+ fcp_p->remoteCwd;
   } else {
      msg = msg :+ "the current working directory.";
   }
   ftpDisplayInfo(msg);
}

defeventtab _ftpChangeDir_form;
void _ctl_ok.on_create(_str caption="", _str init_dir="",
                       FtpConnProfile *fcp_p = null,
                       _str completion=NONE_ARG)
{
   if( caption!="" ) {
      p_active_form.p_caption=caption;
   }
   _ctl_dir.p_text=init_dir;
   _ctl_dir.p_completion=completion;
   _ctl_dir.p_ListCompletions=false;
   if( fcp_p && fcp_p->system!=FTPSYST_OS400 ) {
      _ctl_os400_lfs.p_enabled=false;
   }
}

void _ftpChangeDir_form.on_load()
{
   p_window_id=_ctl_dir;
   _set_focus();
   _set_sel(1,length(p_text));
}

void _ctl_ok.lbutton_up()
{
   _param1=_ctl_dir.p_text;
   _param2= (_ctl_os400_lfs.p_enabled && _ctl_os400_lfs.p_value!=0);
   p_active_form._delete_window(0);
}

void _ctl_cancel.lbutton_up()
{
   p_active_form._delete_window("");
}

void _ctl_help.lbutton_up()
{
   _str msg='';
   if( pos("local",p_active_form.p_caption,1,'i') ) {
      // Local dir
      msg="Type the local directory you would like to change to.";
   } else {
      // Remote dir
      msg="Type the remote directory you would like to change to.\n\n":+
          "OS/400 users note:\n":+
          "\t":+'Check ON "OS/400 Library File System" if you are changing':+"\n":+
          "\tdirectory to an old style Library File System library.";
   }
   ftpDisplayInfo(msg);
}

static void _RetrieveFileHist()
{
   _ftpFileHist._makeempty();
   int ini_view_id=0;
   int orig_view_id=0;
   int status=_open_temp_view(FTPUserIniFilename(),ini_view_id,orig_view_id);
   if( status ) return;
   p_window_id=ini_view_id;
   top();
   _str line='';
   _str host='';
   _str remote_path='';
   _str local_path='';
   status=search('^\[sitemap\-','@ir');
   while( !status ) {
      get_line(line);
      parse line with '[' 'sitemap-' host ']';
      host=strip(host);
      if( host=="" ) {
         // This should never happen
         status=repeat_search();
         continue;
      }
      while( !down() ) {
         get_line(line);
         if( line=="" ) continue;
         if( substr(line,1,1)=='[' ) break;   // At next section
         parse line with '"' remote_path '"' '=' '"' local_path '"';
         remote_path=strip(remote_path);
         local_path=strip(local_path);
         if( remote_path=="" || local_path=="" ) continue;   // This should never happen
         _ftpFileHist:[host].files:[remote_path].local_path=local_path;
      }
      status=repeat_search();
   }

   return;
}

static void _SaveFileHist()
{
   typeless host,remote_path;

   int orig_view_id=p_window_id;
   int temp_view_id=0;
   if( _create_temp_view(temp_view_id)=="" ) return;
   _delete_line();

   for( host._makeempty();; ) {
      _ftpFileHist._nextel(host);
      if( host._isempty() ) break;
      for( remote_path._makeempty();; ) {
         _ftpFileHist:[host].files._nextel(remote_path);
         if( remote_path._isempty() ) break;
         _str local_path=_ftpFileHist:[host].files:[remote_path].local_path;
         insert_line('"'remote_path'"="'local_path'"');
      }
   }
}

/**
 * Closes all current FTP connections.
 */
void _ftpCloseAllConnections()
{
   FtpConnProfile *fcp_p;

   typeless i;
   for( i._makeempty();; ) {
      _ftpCurrentConnections._nextel(i);
      if( i._isempty() ) break;
      fcp_p=_ftpCurrentConnections._indexin(i);
      if( fcp_p->sock!=INVALID_SOCKET ) {
         _ftpCommand(fcp_p,false,"QUIT");
      }
      if( fcp_p->vsproxy_sock!=INVALID_SOCKET ) {
         _ftpVSProxyCommand(fcp_p,"QUIT");
      }
   }
   _ftpCurrentConnections._makeempty();   // Just in case

   return;
}

_command void ftpCloseAllConnections() name_info(','VSARG2_NCW|VSARG2_READ_ONLY)
{
   _ftpCloseAllConnections();
}

#define FTPTEMP_DIR 'ftp'
#define FTPTEMP_FILE_PREFIX "vsftp"

// Return the path to save temporary ftp files with the trailing FILESEP
static _str _ftpTempPath()
{
   _str path=get_env("VSLICKFTP");
   if( path=="" ) {
      // Use defaults
      path=_ConfigPath();
      path=path:+FTPTEMP_DIR;
   }
   if( last_char(path)!=FILESEP ) path=path:+FILESEP;

   return(path);
}

_str _ftpMktemp()
{
   typeless status=0;
   _str path=_ftpTempPath();
   if( last_char(path)==FILESEP ) path=substr(path,1,length(path)-1);   // Strip trailing FILESEP
   if( file_match('+d +x -p ':+maybe_quote_filename(path),1)=="" ) {
      // The path to save downloaded ftp files is not created yet, so create it
      status=make_path(path);   // make_path() takes care of multiple directories
      if( status ) {
         ftpDisplayError('Unable to create ftp temporary path "':+path:+'".  ':+get_message(status));
         return("");
      }
   }
   path=path:+FILESEP;   // Tack the trailing FILESEP back on

   _str prefix=FTPTEMP_FILE_PREFIX;
   if( length(prefix)>=8 ) {
      // This should not happen. Never pick a prefix as large as the
      // name(no extension) part of an 8.3 filename.
      prefix=substr(prefix,1,7);
   }
   int prefix_len=length(prefix);

   int maxmajor= (int)substr("",1,8-prefix_len,"9");
   int maxminor=999;
   int i,j;
   for( i=0;i<maxmajor;++i ) {
      for( j=0;j<maxminor;++j ) {
         _str name=path:+prefix:+substr("",1,8-prefix_len-length(i),"0"):+i:+".":+substr("",1,3-length(j),"0"):+j;
         if( file_match('-p 'maybe_quote_filename(name),1)=="" ) {
            return(name);
         }
      }
   }

   return("");   // There are a lot of temp files if this happens
}

/**
 * Expects the name of the file, including the full path, to work.
 * We follow the same algorithm as _ftpMktemp() so that it is easy to change
 * the FTPTEMP_FILE_PREFIX constant.
 */
boolean _ftpIsTempFilename(_str name)
{
   _str temp_path=_ftpTempPath();
   if( last_char(temp_path)!=FILESEP ) temp_path=temp_path:+FILESEP;

   _str name_path=_file_case(_strip_filename(name,'N'));
   if( _file_case(temp_path)!=name_path ) return(false);

   _str prefix=FTPTEMP_FILE_PREFIX;
   if( length(prefix)>=8 ) {
      // This should not happen. Never pick a prefix as large as the
      // name(no extension) part of an 8.3 filename.
      prefix=substr(prefix,1,7);
   }
   int prefix_len=length(prefix);
   _str name_re=_escape_re_chars(prefix);

   int maxmajor= (int)substr("",1,8-prefix_len,"9");
   int maxminor= (int)substr("",1,3,"9");
   int i;
   for( i=0;i<length(maxmajor);++i ) {
      name_re=name_re:+':d';
   }
   name_re=name_re:+".";
   for( i=0;i<length(maxminor);++i ) {
      name_re=name_re:+':d';
   }
   name_re=_file_case(name_re);
   if( pos(name_re,_strip_filename(_file_case(name),'P'),1,'er')==1 ) return(true);

   return(false);
}

static _str _MaybeLongTo8Dot3(_str filename)
{
   _str new_filename;
   _str ext='';

   if( filename=="" ) return("");
   new_filename=filename;
   if( _ftpUseShortFilenames() ) {
      // Long filenames are not supported, so shorten the filename to 8.3
      if( pos('.',new_filename)!=lastpos('.',new_filename) ) {
         // There is more than one '.' in the filename, so translate all '.'
         // except the last one (the extension of the file is important
         // for selecting the mode.
         ext=substr(new_filename,lastpos('.',new_filename)+1);
         new_filename=stranslate(substr(new_filename,1,lastpos('.',new_filename)-1),"",".","e");
         new_filename=new_filename:+".":+ext;
      }
      _str name='';
      parse new_filename with name '.' ext;
      if( length(name)>8 ) {
         name=substr(name,1,8);
      }
      if( length(ext)>3 ) {
         ext=substr(ext,1,3);
      }
      new_filename=name;
      if( ext!="" ) {
         new_filename=new_filename:+".":+ext;
      }
   }

   return(new_filename);
}

#if __UNIX__
   #define FTPXLAT_FILENAME_CHARSET "\t"
#else
   #define FTPXLAT_FILENAME_CHARSET "[]:\\/<>|=+;,\t"
#endif
/**
 * Maps a remote path (host+path), to a local directory
 * The local path is guaranteed to exist when this function returns
 * successfully.
 * <P>
 * Note that the remote_path passed in is assumed to be absolute.
 * <P>
 * Note about 8.3 file systems: <BR>
 * This function does not care if you are on an 8.3 file system and 2
 * or more distinct ftp host paths map to the same local path. It DOES
 * care if 2 or more remote filenames map to the same local filename
 * and will try to generate a unique name in this case.
 */
_str _ftpRemoteToLocalPath(FtpConnProfile *fcp_p,_str remote_path)
{
   boolean isdir;

   boolean mvs_quoted= (fcp_p->system==FTPSYST_MVS && substr(remote_path,1,1)=="'" && last_char(remote_path)=="'");
   if( mvs_quoted ) {
      remote_path=strip(remote_path,'B',"'");
   }
   switch( fcp_p->system ) {
   case FTPSYST_MVS:
      remote_path=_ftpConvertSEtoMVSFilename(remote_path);
      break;
   case FTPSYST_OS400:
      remote_path=_ftpConvertSEtoOS400Filename(remote_path);
      break;
   }

   _str host=fcp_p->host;
   if( host=="" || remote_path=="" ) return("");

   _str remoteroot='';
   _str path_only='';
   _str localroot='';
   _str filename='';
   _str libname='';
   _str file='';
   _str temp='';
   _str name='';
   _str ver='';
   _str msg='';
   _str member='';
   _str append_path='';
   _str return_path='';
   if( fcp_p->remoteRoot!="" && fcp_p->localRoot!="" ) {
      // This connection profile already has remote-to-local mapping
      // set up, so use it.
      remoteroot=strip(fcp_p->remoteRoot);
      path_only=_ftpStripFilename(fcp_p,remote_path,'N');
      if( fcp_p->system==FTPSYST_VM || fcp_p->system==FTPSYST_VMESA ) {
         if( last_char(path_only)=='/' ) {
            path_only=substr(path_only,1,length(path_only)-1);
         }
      }
      if( _ftpFileEq(fcp_p,substr(path_only,1,length(remoteroot)),remoteroot) ) {
         // Map it
         localroot=fcp_p->localRoot;
         if( last_char(localroot)!=FILESEP ) localroot=localroot:+FILESEP;

         switch( fcp_p->system ) {
         case FTPSYST_VMS:
         case FTPSYST_VMS_MULTINET:
            if( !pos('^[~\[]@\:\[?@\]',remoteroot,1,'r') ) {
               // Invalid remote root path
               msg='Invalid remote root path "':+remoteroot:+'" for ':+
                   'connection profile:':+"\n\n":+'"':+fcp_p->profileName:+'"';
               ftpConnDisplayError(fcp_p,msg);
               return("");
            }
            parse remote_path with . '[' temp ']' filename;
            append_path="";
            while( temp!="" ) {
               parse temp with name '.' temp;
               name=_MaybeLongTo8Dot3(name);
               // Translate illegal characters
               name=translate(name,"",FTPXLAT_FILENAME_CHARSET,'_');
               append_path=append_path:+name:+FILESEP;
            }
            parse filename with filename ';' ver;
            append_path=append_path:+_MaybeLongTo8Dot3(filename);
            return_path=localroot:+append_path;
            break;
         case FTPSYST_VOS:
            if( !pos('^[~\>]@\>',remoteroot,1,'r') ) {
               // Invalid remote root path
               msg='Invalid remote root path "':+remoteroot:+'" for ':+
                   'connection profile:':+"\n\n":+'"':+fcp_p->profileName:+'"';
               ftpConnDisplayError(fcp_p,msg);
               return("");
            }
            parse remote_path with . '>' temp;
            append_path="";
            while( temp!="" ) {
               parse temp with name '>' temp;
               name=_MaybeLongTo8Dot3(name);
               // Translate illegal characters
               name=translate(name,"",FTPXLAT_FILENAME_CHARSET,'_');
               append_path=append_path:+name;
               if( temp!="" ) append_path=append_path:+FILESEP;
            }
            return_path=localroot:+append_path;
            break;
         case FTPSYST_VM:
         case FTPSYST_VMESA:
            // Look for a CMS minidisk
            if( !pos('^[A-Za-z0-9$#@+-:_]#\.[A-Za-z0-9$#@+-:_]#$',remoteroot,1,'r') ) {
               // Invalid remote root path
               msg='Invalid remote root path "':+remoteroot:+'" for ':+
                   'connection profile:':+"\n\n":+'"':+fcp_p->profileName:+'"';
               ftpConnDisplayError(fcp_p,msg);
               return("");
            }
            name=_ftpStripFilename(fcp_p,remote_path,'P');
            name=_MaybeLongTo8Dot3(name);
            // Translate illegal characters
            name=translate(name,"",FTPXLAT_FILENAME_CHARSET,'_');
            append_path=name;
            return_path=localroot:+append_path;
            break;
         case FTPSYST_MVS:
            if( substr(remote_path,1,1)=='/' ) {
               // HFS file system which mimics Unix
               if( last_char(remoteroot)!='/' ) remoteroot=remoteroot:+'/';
               temp=substr(remote_path,length(remoteroot)+1);
               append_path="";
               while( temp!="" ) {
                  parse temp with name '/' temp;
                  name=_MaybeLongTo8Dot3(name);
                  // Translate illegal characters
                  name=translate(name,"",FTPXLAT_FILENAME_CHARSET,'_');
                  append_path=append_path:+name;
                  if( temp!="" ) append_path=append_path:+FILESEP;
               }
               return_path=localroot:+append_path;
            } else {
               // PDS or SDS format
               if( !pos('^[~\.]#(\.[~\.]#)@(\.|)',remoteroot,1,'r') ) {
                  // Invalid remote root path
                  msg='Invalid remote root path "':+remoteroot:+'" for ':+
                      'connection profile:':+"\n\n":+'"':+fcp_p->profileName:+'"';
                  ftpConnDisplayError(fcp_p,msg);
                  return("");
               }
               if( last_char(remote_path)==')' ) {
                  // PDS member
                  #if 1
                  // This will really mess up if remoteroot is not a valid path
                  temp=remoteroot;
                  if( last_char(temp)!='.' ) temp=temp:+'.';
                  temp=substr(remote_path,length(temp)+1);
                  parse temp with temp '(' filename ')';
                  append_path="";
                  while( temp!="" ) {
                     parse temp with name '.' temp;
                     name=_MaybeLongTo8Dot3(name);
                     // Translate illegal characters
                     name=translate(name,"",FTPXLAT_FILENAME_CHARSET,'_');
                     append_path=append_path:+name:+FILESEP;
                  }
                  #else
                  parse remote_path with temp '(' filename ')';
                  // Parse off the qualifier/path component
                  i=pos('.',temp);
                  if( i ) {
                     parse temp with qualifier '.' name;
                     qualifier=_MaybeLongTo8Dot3(qualifier);
                     qualifier=translate(qualifier,"",FTPXLAT_FILENAME_CHARSET,'_');
                     name=_MaybeLongTo8Dot3(name);
                     name=translate(name,"",FTPXLAT_FILENAME_CHARSET,'_');
                     append_path=qualifier:+FILESEP:+name:+FILESEP;
                  } else {
                     // This should never happen
                     temp=_MaybeLongTo8Dot3(temp);
                     temp=translate(temp,"",FTPXLAT_FILENAME_CHARSET,'_');
                     append_path=temp:+FILESEP;
                  }
                  #endif
               } else {
                  // SDS
                  // This will really mess up if remoteroot is not a valid path
                  temp=remoteroot;
                  if( last_char(temp)!='.' ) temp=temp:+'.';
                  filename=substr(remote_path,length(temp)+1);
                  append_path="";
               }
               append_path=append_path:+_MaybeLongTo8Dot3(filename);
               return_path=localroot:+append_path;
            }
            break;
         case FTPSYST_OS2:
            // OS/2 is flexible about file separators. Both '/' and '\' are allowed
            remoteroot=translate(remoteroot,'/','\');
            remote_path=translate(remote_path,'/','\');
            if( last_char(remoteroot)!='/' ) remoteroot=remoteroot:+'/';
            temp=substr(remote_path,length(remoteroot)+1);
            append_path="";
            while( temp!="" ) {
               parse temp with name '/' temp;
               name=_MaybeLongTo8Dot3(name);
               // Translate illegal characters
               name=translate(name,"",FTPXLAT_FILENAME_CHARSET,'_');
               append_path=append_path:+name;
               if( temp!="" ) append_path=append_path:+FILESEP;
            }
            return_path=localroot:+append_path;
            break;
         case FTPSYST_OS400:
            if( substr(remote_path,1,1)=='/' ) {
               // IFS file system which mimics Unix
               if( last_char(remoteroot)!='/' ) remoteroot=remoteroot:+'/';
               temp=substr(remote_path,length(remoteroot)+1);
               append_path="";
               while( temp!="" ) {
                  parse temp with name '/' temp;
                  name=_MaybeLongTo8Dot3(name);
                  // Translate illegal characters
                  name=translate(name,"",FTPXLAT_FILENAME_CHARSET,'_');
                  append_path=append_path:+name;
                  if( temp!="" ) append_path=append_path:+FILESEP;
               }
               return_path=localroot:+append_path;
            } else {
               // LFS format
               if( !pos('^[~/.]#(/([~/.]#|)|)$',remoteroot,1,'r') ) {
                  // Invalid remote root path
                  msg='Invalid remote root path "':+remoteroot:+'" for ':+
                      'connection profile:':+"\n\n":+'"':+fcp_p->profileName:+'"';
                  ftpConnDisplayError(fcp_p,msg);
                  return("");
               }
               // If there is not already a '/', then this is an LFS library
               if( !pos('/',remoteroot) ) remoteroot=remoteroot:+'/';
               temp=substr(remote_path,length(remoteroot)+1);
               if( pos('.',temp) ) {
                  parse temp with file '.' member;
               } else {
                  // Just the member
                  file="";
                  member=temp;
               }
               if( file!="" ) {
                  file=_MaybeLongTo8Dot3(file);
                  file=translate(file,"",FTPXLAT_FILENAME_CHARSET,'_');
                  append_path=file;
               }
               if( member!="" ) {
                  member=_MaybeLongTo8Dot3(member);
                  member=translate(member,"",FTPXLAT_FILENAME_CHARSET,'_');
                  append_path=append_path:+FILESEP:+member;
               }
               return_path=localroot:+append_path;
            }
            break;
         case FTPSYST_WINNT:
         case FTPSYST_HUMMINGBIRD:
            if( substr(remote_path,1,1)=='/' ) {
               // Unix style
               if( last_char(remoteroot)!='/' ) remoteroot=remoteroot:+'/';
               temp=substr(remote_path,length(remoteroot)+1);
               append_path="";
               while( temp!="" ) {
                  parse temp with name '/' temp;
                  name=_MaybeLongTo8Dot3(name);
                  // Translate illegal characters
                  name=translate(name,"",FTPXLAT_FILENAME_CHARSET,'_');
                  append_path=append_path:+name;
                  if( temp!="" ) append_path=append_path:+FILESEP;
               }
               return_path=localroot:+append_path;
            } else {
               // DOS style
               if( last_char(remoteroot)!="\\" ) remoteroot=remoteroot:+"\\";
               temp=substr(remote_path,length(remoteroot)+1);
               append_path="";
               while( temp!="" ) {
                  parse temp with name "\\" temp;
                  name=_MaybeLongTo8Dot3(name);
                  // Translate illegal characters
                  name=translate(name,"",FTPXLAT_FILENAME_CHARSET,'_');
                  append_path=append_path:+name;
                  if( temp!="" ) append_path=append_path:+FILESEP;
               }
               return_path=localroot:+append_path;
            }
            break;
         case FTPSYST_NETWARE:
         case FTPSYST_MACOS:
         case FTPSYST_VXWORKS:
         case FTPSYST_UNIX:
         default:
            if( last_char(remoteroot)!='/' ) remoteroot=remoteroot:+'/';
            temp=substr(remote_path,length(remoteroot)+1);
            append_path="";
            while( temp!="" ) {
               parse temp with name '/' temp;
               name=_MaybeLongTo8Dot3(name);
               // Translate illegal characters
               name=translate(name,"",FTPXLAT_FILENAME_CHARSET,'_');
               append_path=append_path:+name;
               if( temp!="" ) append_path=append_path:+FILESEP;
            }
            return_path=localroot:+append_path;
         }
         // Make sure the local path exists
         _str temp_path=return_path;
         int i=lastpos(FILESEP,temp_path);
         if( i ) {
            temp_path=substr(temp_path,1,i-1);
         }
         if( !isdrive(temp_path) && file_match('+d +x -p ':+maybe_quote_filename(temp_path),1)=="" ) {
            // The path is not created yet, so create it
            int status=make_path(temp_path);   // make_path() takes care of multiple directories
            if( status ) {
               ftpConnDisplayError(fcp_p,'Unable to create ftp local path "':+temp_path:+'".  ':+get_message(status));
               return("");
            }
         }
         return(return_path);
      }
   }

   int i=0;
   _str remote_filename='';
   _str local_path='';
   isdir=_ftpIsDir(fcp_p,remote_path);
   _str path=remote_path;
   _str root=_MaybeLongTo8Dot3(host);
   // Translate illegal characters. Especially important for
   // IPv6 literal addresses (e.g. fe80::250:8dff:fed5:337c)
   // on Windows because of illegal ':' character.
   root = translate(root,"",FTPXLAT_FILENAME_CHARSET,'_');

   switch( fcp_p->system ) {
   case FTPSYST_VMS:
   case FTPSYST_VMS_MULTINET:
      if( !pos('^[~\[]@\:\[?@\]',path,1,'r') ) {
         // Invalid remote path
         msg='Invalid remote path "':+path:+'" for ':+
             'connection profile:':+"\n\n":+'"':+fcp_p->profileName:+'"';
         ftpConnDisplayError(fcp_p,msg);
         return("");
      }
      parse path with . '[' path ']' filename ';' ver;
      remote_filename=filename;
      local_path="";
      while( path!="" ) {
         parse path with name '.' path;
         name=_MaybeLongTo8Dot3(name);
         // Translate illegal characters
         name=translate(name,"",FTPXLAT_FILENAME_CHARSET,'_');
         local_path=local_path:+FILESEP:+name;
      }
      break;
   case FTPSYST_VOS:
      if( !pos('^[~\>]@\>',path,1,'r') ) {
         // Invalid remote path
         msg='Invalid remote path "':+path:+'" for ':+
             'connection profile:':+"\n\n":+'"':+fcp_p->profileName:+'"';
         ftpConnDisplayError(fcp_p,msg);
         return("");
      }
      parse path with . '>' path;
      remote_filename="";
      i=lastpos('>',path);
      if( i ) {
         remote_filename=substr(path,i+1);
         path=substr(path,1,i);
      }
      local_path="";
      while( path!="" ) {
         parse path with name '>' path;
         name=_MaybeLongTo8Dot3(name);
         // Translate illegal characters
         name=translate(name,"",FTPXLAT_FILENAME_CHARSET,'_');
         local_path=local_path:+FILESEP:+name;
      }
      break;
   case FTPSYST_VM:
   case FTPSYST_VMESA:
      path=_ftpStripFilename(fcp_p,path,'NS');
      if( !pos('^[A-Za-z0-9$#@+-:_]#\.[A-Za-z0-9$#@+-:_]#$',path,1,'r') ) {
         // Invalid remote path
         msg='Invalid remote path "':+path:+'" for ':+
             'connection profile:':+"\n\n":+'"':+fcp_p->profileName:+'"';
         ftpConnDisplayError(fcp_p,msg);
         return("");
      }
      name=_ftpStripFilename(fcp_p,remote_path,'P');
      name=_MaybeLongTo8Dot3(name);
      remote_filename=name;
      // Translate illegal characters
      local_path=FILESEP:+translate(path,"",FTPXLAT_FILENAME_CHARSET,'_');
      break;
   case FTPSYST_MVS:
      if( substr(path,1,1)=='/' ) {
         // HFS file system which mimics Unix
         remote_filename=_ftpStripFilename(fcp_p,path,'P');
         path=_ftpStripFilename(fcp_p,path,'N');
         if( substr(path,1,1)=='/' ) path=substr(path,2);
         local_path="";
         while( path!="" ) {
            parse path with name '/' path;
            name=_MaybeLongTo8Dot3(name);
            // Translate illegal characters
            name=translate(name,"",FTPXLAT_FILENAME_CHARSET,'_');
            local_path=local_path:+FILESEP:+name;
         }
      } else {
         // PDS or SDS format
         if( !pos('^[~\.]#(\.[~\.]#)@(\.|)(\([~\(]#\)|)',path,1,'r') ) {
            // Invalid remote path
            msg='Invalid remote path "':+path:+'" for ':+
                'connection profile:':+"\n\n":+'"':+fcp_p->profileName:+'"';
            ftpConnDisplayError(fcp_p,msg);
            return("");
         }
         if( last_char(path)!=')' ) {
            // SDS format
            i=pos('.',path);
            if( i ) {
               remote_filename=substr(path,i+1);
               path=substr(path,1,i);
               path=_MaybeLongTo8Dot3(path);
               path=translate(path,"",FTPXLAT_FILENAME_CHARSET,'_');
               local_path=FILESEP:+path;
            } else {
               // There will be problems if this is not already absolute
               remote_filename=path;
               local_path=FILESEP;
            }
         } else {
            // PDS format
            parse path with path '(' filename ')';
            remote_filename=filename;
            path=_MaybeLongTo8Dot3(path);
            path=translate(path,"",FTPXLAT_FILENAME_CHARSET,'_');
            local_path=FILESEP:+path;
         }
      }
      break;
   case FTPSYST_OS2:
      // OS/2 is flexible about file separators. Both '/' and '\' are allowed
      path=translate(path,'/','\');
      if( substr(path,1,1)=='/' ) path=substr(path,2);
      remote_filename="";
      i=lastpos('/',path);
      if( i ) {
         remote_filename=substr(path,i+1);
         path=substr(path,1,i);
      }
      local_path="";
      while( path!="" ) {
         parse path with name '/' path;
         name=_MaybeLongTo8Dot3(name);
         // Translate illegal characters
         name=translate(name,"",FTPXLAT_FILENAME_CHARSET,'_');
         local_path=local_path:+FILESEP:+name;
      }
      break;
   case FTPSYST_OS400:
      if( substr(path,1,1)=='/' ) {
         // IFS file system which mimics Unix
         remote_filename=_ftpStripFilename(fcp_p,path,'P');
         path=_ftpStripFilename(fcp_p,path,'N');
         if( substr(path,1,1)=='/' ) path=substr(path,2);
         local_path="";
         while( path!="" ) {
            parse path with name '/' path;
            name=_MaybeLongTo8Dot3(name);
            // Translate illegal characters
            name=translate(name,"",FTPXLAT_FILENAME_CHARSET,'_');
            local_path=local_path:+FILESEP:+name;
         }
      } else {
         // LFS format
         parse path with libname '/' file '.' member;
         if( libname=="" || file=="" ) {
            // Invalid remote path
            msg='Invalid remote path "':+path:+'"';
            ftpConnDisplayError(fcp_p,msg);
            return("");
         }
         libname=_MaybeLongTo8Dot3(libname);
         libname=translate(libname,"",FTPXLAT_FILENAME_CHARSET,'_');
         local_path=FILESEP:+libname;
         if( member!="" ) {
            file=_MaybeLongTo8Dot3(file);
            file=translate(file,"",FTPXLAT_FILENAME_CHARSET,'_');
            local_path=local_path:+FILESEP:+file;
            remote_filename=member;
         } else {
            remote_filename=file;
         }
      }
      break;
   case FTPSYST_WINNT:
   case FTPSYST_HUMMINGBIRD:
      if( substr(path,1,1)=='/' ) {
         // Unix style
         remote_filename=_ftpStripFilename(fcp_p,path,'P');
         path=_ftpStripFilename(fcp_p,path,'N');
         if( substr(path,1,1)=='/' ) path=substr(path,2);
         local_path="";
         while( path!="" ) {
            parse path with name '/' path;
            name=_MaybeLongTo8Dot3(name);
            // Translate illegal characters
            name=translate(name,"",FTPXLAT_FILENAME_CHARSET,'_');
            local_path=local_path:+FILESEP:+name;
         }
      } else {
         // DOS style
         remote_filename=_ftpStripFilename(fcp_p,path,'P');
         path=_ftpStripFilename(fcp_p,path,'N');
         local_path="";
         while( path!="" ) {
            parse path with name "\\" path;
            name=_MaybeLongTo8Dot3(name);
            // Translate illegal characters
            name=translate(name,"",FTPXLAT_FILENAME_CHARSET,'_');
            local_path=local_path:+FILESEP:+name;
         }
      }
      break;
   case FTPSYST_NETWARE:
   case FTPSYST_MACOS:
   case FTPSYST_VXWORKS:
   case FTPSYST_UNIX:
   default:
      remote_filename=_ftpStripFilename(fcp_p,path,'P');
      path=_ftpStripFilename(fcp_p,path,'N');
      if( substr(path,1,1)=='/' ) path=substr(path,2);
      local_path="";
      while( path!="" ) {
         parse path with name '/' path;
         name=_MaybeLongTo8Dot3(name);
         // Translate illegal characters
         name=translate(name,"",FTPXLAT_FILENAME_CHARSET,'_');
         local_path=local_path:+FILESEP:+name;
      }
   }
   _str local_filename=_MaybeLongTo8Dot3(remote_filename);
   // This tells us if the filename part was shortened to 8.3
   boolean filename_was_reduced= (!isdir && local_filename!=remote_filename);
   local_path=root:+local_path;
   typeless status=0;

   path=_ftpTempPath();
   if( last_char(path)!=FILESEP ) path=path:+FILESEP;
   local_path=path:+local_path;
   if( last_char(local_path)==FILESEP ) local_path=substr(local_path,1,length(local_path)-1);
   if( file_match('+d +x -p ':+maybe_quote_filename(local_path),1)=="" ) {
      // The path is not created yet, so create it
      //messageNwait('local_path='local_path);
      status=make_path(local_path);   // make_path() takes care of multiple directories
      if( status ) {
         ftpConnDisplayError(fcp_p,'Unable to create ftp local path "':+local_path:+'".  ':+get_message(status));
         return("");
      }
   }
   local_path=local_path:+FILESEP;
   return_path=local_path;
   if( local_filename!="" ) {

      // Translate illegal characters
      local_filename=translate(local_filename,"",FTPXLAT_FILENAME_CHARSET,'_');

      return_path=return_path:+local_filename;
      if( filename_was_reduced ) {
         /* The local path name was shortened because we are on an 8.3 file
          * system. We must not blast the file on disk, but rather generate
          * a filename that will be unique.
          */
         _str ext,found;
         parse local_filename with name '.' ext;
         filename=return_path;
         found=file_match("-p "maybe_quote_filename(filename),1);
         for( i=0;i<10;++i ) {
            if( found=="" ) break;
            filename=local_path:+strip(substr(name,1,length(name)-1)):+i;
            // The extension is important to selecting the mode, so don't mess with it
            if( ext!="" ) filename=filename:+".":+ext;
            found=file_match("-p "maybe_quote_filename(filename),0);
         }
         if( found!="" ) {
            // Try again
            for( i=10;i<100;++i ) {
               if( found=="" ) break;
               filename=local_path:+strip(substr(name,1,length(name)-2)):+i;
               // The extension is important to selecting the mode, so don't mess with it
               if( ext!="" ) filename=filename:+".":+ext;
               found=file_match("-p "maybe_quote_filename(filename),0);
            }
         }
         if( found!="" ) {
            // Give up
            ftpConnDisplayError(fcp_p,"Unable to create ftp local filename.\n\nYou need to clean out the directory:\n\n":+local_path);
            return("");
         }
         return_path=filename;
      }
   }

   return(return_path);
}

/**
 * Expects the name of the file, including the full path, to work.
 */
boolean _ftpIsLocalFilename(_str name)
{
   _str temp_path=_ftpTempPath();
   if( last_char(temp_path)!=FILESEP ) temp_path=temp_path:+FILESEP;
   temp_path=_file_case(temp_path);

   _str name_path=_file_case(_strip_filename(name,'N'));
   if( pos(temp_path,name_path)==1 ) return(true);

   return(false);
}

boolean ftpIsFTPDocname(_str name)
{
   return( lowcase(substr(name,1,length('ftp://')))=='ftp://' );
}

/**
 * Called when the editor exits. Closes all current FTP connections. Also
 * clears out the array of current connections so they are not needlessly
 * taking up space in the state file. Since the last connections are not
 * stored in the state file, security-conscious users do not have to worry
 * about sending us their state file for tech support reasons because we
 * will have no access to their connection info.
 * <P>
 * Note: _cbsave_ftp() and _cbquit_ftp() take care of the user saving and
 * quitting an FTP file respectively.
 *
 * @return 0
 */
int _exit_ftp()
{
   _str errors;
   _str excluded;

   // Now make sure we don't need to upload any buffers and delete any
   // temporary ftp files that might (but should not be), left over.
   //
   // First build a list of ftp buffers that are active and exclude these
   // from deletion. IF WE DECIDE TO PUT IN AN OPTION NOT TO AUTORESTORE
   // FTP BUFFERS, THEN WE MUST -OR- IN THE VSBUFFLAG_THROW_AWAY_CHANGES flag into
   // p_buf_flags.
   excluded=" ";
   typeless status=0;
   _str buf_name='';
   _str document_name='';
   int orig_view_id=0;
   int orig_wid=p_window_id;
   activate_window(VSWID_HIDDEN);
   _safe_hidden_window();
   int first_buf_id=p_buf_id;
   for(;;) {
      if( !(p_buf_flags&VSBUFFLAG_HIDDEN) ) {
         buf_name=p_buf_name;
         document_name=p_DocumentName;
         if( ftpIsFTPDocname(document_name) ) {
            // Check to see if we need to upload it
            if( !p_modify && p_ModifyFlags&MODIFYFLAG_FTP_NEED_TO_SAVE ) {
               // 1 as third argument forces a prompt-for-save regardless
               // of the global options.
               if( p_buf_flags&VSBUFFLAG_FTP_UPLOAD_IN_PROGRESS ) {
                  // This buffer is currently being uploaded.
                  // That means it is already saved on disk, so it is safe to
                  // quit the buffer.
                  return(0);
               }
               p_buf_flags |= VSBUFFLAG_FTP_UPLOAD_IN_PROGRESS;
               orig_view_id=p_window_id;
               status=_ftpSave(buf_name,document_name,true);
               p_window_id=orig_view_id;
               p_buf_flags &= ~(VSBUFFLAG_FTP_UPLOAD_IN_PROGRESS);
            }
            if( _ftpIsTempFilename(buf_name) ) {
               excluded=excluded:+_file_case(buf_name):+" ";
            }
         }
      }
      _next_buffer('HNR');
      if( p_buf_id==first_buf_id ) break;
   }
   activate_window(orig_wid);

   errors="";
   _str temp_path=_ftpTempPath();
   if( last_char(temp_path)!=FILESEP ) temp_path=temp_path:+FILESEP;
   _str name=file_match("-d ":+maybe_quote_filename(temp_path:+FTPTEMP_FILE_PREFIX:+ALLFILES_RE),1);
   while( name!="" ) {
      if( !pos(" ":+_file_case(name):+" ",excluded,1) ) {
         status=delete_file(name);
         if( status ) {
            // Note the error and continue
            if( errors!="" ) errors="\n":+errors;
            errors=errors:+name:+" - ":+get_message(status);
         }
      }
      name=file_match("-d ":+maybe_quote_filename(temp_path:+FTPTEMP_FILE_PREFIX:+ALLFILES_RE),0);
   }
   if( errors!="" ) {
      ftpDisplayWarning("Warning:  Unable to delete the following ftp files:\n\n":+
                        errors);
   }

   // Close down all socket connections gracefully and exit the sockets layer
   typeless i;
   i._makeempty();
   _ftpCurrentConnections._nextel(i);
   if( !i._isempty() ) {
      int idx=find_index("vssIsInit",PROC_TYPE);
      if( idx && index_callable(idx) ) {
         _ftpCloseAllConnections();
         if( vssIsInit() ) vssExit();   // Exit sockets layer
      }
   }

   // Empty all globals
   _ftpCurrentConnections._makeempty();
   _ftpFileHist._makeempty();
   _ftpQ._makeempty();


   return(0);
}

_command int ResetSockets() name_info(','VSARG2_NCW|VSARG2_READ_ONLY)
{
   // Exit sockets layer
   if( vssIsInit() ) vssExit();
   int status=vssInit(SOCKDEF_CONNECT_TIMEOUT);
   //status=vssInit(5000);
   if( status ) {
      _message_box("Unable to initialize sockets layer.  ":+get_message(status),'',MB_OK|MB_ICONEXCLAMATION);
      return(status);
   }

   return(0);
}

int _ftpSynchronousDisconnect(FtpConnProfile *fcp_p,boolean quiet=false)
{
   boolean progress_already_visible;
   int formWid=0;
   int orig_view_id=0;
   boolean success;

   success=false;
   gftpAbort=false;
   orig_view_id=p_window_id;

   if( !quiet ) {
      // If the progress form is already visible, then use it
      formWid=_find_object("_ftpProgress_form",'N');
      progress_already_visible= (formWid!=0);
      if( !formWid ) {
         formWid=show("_ftpProgress_form");
      }
      if( !formWid ) {
         if( !quiet ) {
            _message_box('Could not show form: "_ftpProgress_form"','',MB_OK|MB_ICONEXCLAMATION);
         }
         return(1);
      }
   }

   // Do not start anything new until the queue empties
   if( _ftpQ._length() ) {
      if( formWid ) {
         formWid.p_caption="Waiting for current operation to finish...";
      }
      for(;;) {
         process_events(gftpAbort);
         if( gftpAbort ) break;
         _ftpQTimerCallback();
         if( _ftpQ._length()<1 ) break;
      }
   }
   if( gftpAbort ) {
      // User did not want to wait for the current operation to finish
      if( formWid && !progress_already_visible ) {
         formWid._delete_window();
      }
      return(COMMAND_CANCELLED_RC);
   }

   int status=0;
   _str start_caption='';
   if( formWid ) {
      start_caption="Disconnecting from ":+fcp_p->profileName;
      formWid.p_caption=start_caption;
   }
   // fcp_p->PostedCB already set by caller
   if( fcp_p->serverType==FTPSERVERTYPE_SFTP ) {
      // SFTP
      _ftpEnQ(QE_SSH_END_CONN_PROFILE,QS_BEGIN,0,fcp_p);
   } else {
      // FTP
      _ftpEnQ(QE_END_CONN_PROFILE,QS_BEGIN,0,fcp_p);
   }

   if( _ftpQ._length()<1 ) {
      // This should never happen
      return(1);
   }

   FtpQEvent event;
   FtpQEvent lastevent;
   lastevent._makeempty();
   lastevent.event=0;
   lastevent.start=0;
   lastevent.state=0;
   _ftpInitConnProfile(lastevent.fcp);
   for(;;) {
      process_events(gftpAbort);
      if( gftpAbort ) {
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
         if( _ftpQEventIsError(lastevent) || _ftpQEventIsAbort(lastevent) ) {
            // Connection failed, so bail out
            break;
         }
         // Completed successfully
         success=true;
         break;
      } else {
         // If the processed event was the last event for that particular
         // connection profile, then we are done
         boolean last=true;
         int i;
         for( i=0;i<_ftpQ._length();++i ) {
            if( _ftpQ[i].fcp.profileName==fcp_p->profileName &&
                _ftpQ[i].fcp.instance==fcp_p->instance ) {
               last=false;
               break;
            }
         }
         if( last ) {
            success=true;
            break;
         }
      }

      // We are only interested in this event if it matches the
      // connection profile that we are connecting for.
      if( _ftpQ[0].fcp.profileName==fcp_p->profileName ) {
         if( fcp_p->serverType==FTPSERVERTYPE_SFTP ) {
            // IF we have gotten to the STAT event AND we don't already have a process handle
            if( _ftpQ[0].event==QE_SSH_END_CONN_PROFILE && _ftpQ[0].state==QS_END ) {
               // Disconnected
               *fcp_p=_ftpQ[0].fcp;
               // Cleanup process handles and clear out the directory listing
               // so that a reconnect will succeed.
               fcp_p->ssh_hprocess= -1;
               fcp_p->ssh_hin= -1;
               fcp_p->ssh_hout= -1;
               fcp_p->ssh_herr= -1;
               fcp_p->remoteDir._makeempty();
               // Drive the progress guage to 100%
               _ftpopenProgressDlgCB("Disconnected.",100,100);
               process_events(gftpAbort);
            }
         } else {
            // FTP
            //
            // IF we have gotten to the SYST event AND we do not already have a socket.
            if( _ftpQ[0].event==QE_END_CONN_PROFILE && _ftpQ[0].state==QS_END ) {
               // Disconnected
               *fcp_p=_ftpQ[0].fcp;
               fcp_p->sock= INVALID_SOCKET;
               // Drive the progress guage to 100%
               _ftpopenProgressDlgCB("Disconnected.",100,100);
               process_events(gftpAbort);
            }
         }
         lastevent=_ftpQ[0];
      }
      _ftpQTimerCallback();
      // Sleep for 0.05sec
      delay(5);
   }
   if( formWid && !progress_already_visible ) {
      formWid._delete_window();
      p_window_id=orig_view_id;
   }

   return( (success)?(0):(1) );
}

int _ftpSynchronousConnect(FtpConnProfile *fcp_p,boolean &need_connect,boolean quiet=false)
{
   int formWid;
   boolean success;
   int orig_view_id;
   _str start_caption;
   boolean progress_already_visible;
   int status;

   need_connect=false;
   if( _ftpIsConnectionAlive(fcp_p) ) {
      // Connection is already alive. No need to resuscitate.
      return(0);
   }

   // Must cleanly disconnect first if necessary, so that resources are freed
   //
   // Save and restore the posted callback function passed in with connection
   // profile.
   FtpPostEventCallback pCB;
   pCB=fcp_p->postedCb;
   fcp_p->postedCb=null;
   status=_ftpSynchronousDisconnect(fcp_p,quiet);
   fcp_p->postedCb=pCB;
   if( status ) {
      return(status);
   }
   // Invalidate SFTP process handle
   fcp_p->ssh_hprocess= -1;
   // Invalidate FTP socket handle
   fcp_p->sock= INVALID_SOCKET;

   need_connect=true;
   success=false;
   gftpAbort=false;
   orig_view_id=p_window_id;
   // If the progress form is already visible, then use it
   formWid=_find_object("_ftpProgress_form",'N');
   progress_already_visible= (formWid!=0);
   if( !formWid ) {
      formWid=show("_ftpProgress_form");
   }
   if( !formWid ) {
      if( !quiet ) {
         _message_box('Could not show form: "_ftpProgress_form"','',MB_OK|MB_ICONEXCLAMATION);
      }
      return(1);
   }

   // Do not start anything new until the queue empties
   if( _ftpQ._length() ) {
      formWid.p_caption="Waiting for current operation to finish...";
      for(;;) {
         process_events(gftpAbort);
         if( gftpAbort ) break;
         _ftpQTimerCallback();
         if( _ftpQ._length()<1 ) break;
      }
   }
   if( gftpAbort ) {
      // User did not want to wait for the current operation to finish
      if( !progress_already_visible ) {
         formWid._delete_window();
      }
      return(COMMAND_CANCELLED_RC);
   }

   // Reconnect

   status=0;
   // Set .DefRemoteHostDir, .DefLocalHostDir so user gets restored
   // to exactly where they were before they were disconnected.
   if( fcp_p->remoteCwd != "" ) {
      fcp_p->defRemoteDir=fcp_p->remoteCwd;
   }
   if( fcp_p->localCwd != "" ) {
      fcp_p->defLocalDir=fcp_p->localCwd;
   }
   _str CwdHist[];
   _ftpGetCwdHist(fcp_p->profileName,CwdHist);
   fcp_p->cwdHist=CwdHist;
   // Need to start the connection, so queue it first
   start_caption="Connecting to ":+fcp_p->profileName;
   formWid.p_caption=start_caption;
   // fcp_p->PostedCB already set by caller
   if( fcp_p->serverType==FTPSERVERTYPE_SFTP ) {
      _ftpEnQ(QE_SSH_START_CONN_PROFILE,QS_BEGIN,0,fcp_p);
   } else {
      _ftpEnQ(QE_START_CONN_PROFILE,QS_BEGIN,0,fcp_p);
   }

   if( _ftpQ._length()<1 ) {
      // This should never happen
      return(1);
   }

   FtpQEvent event;
   FtpQEvent lastevent;
   lastevent._makeempty();
   lastevent.event=0;
   lastevent.start=0;
   lastevent.state=0;
   _ftpInitConnProfile(lastevent.fcp);
   for(;;) {
      process_events(gftpAbort);
      if( gftpAbort ) {
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
         if( _ftpQEventIsError(lastevent) || _ftpQEventIsAbort(lastevent) ) {
            // Connection failed, so bail out
            break;
         }
         // Completed successfully
         success=true;
         break;
      } else {
         // If the processed event was the last event for that particular
         // connection profile, then we are done
         boolean last=true;
         int i;
         for( i=0;i<_ftpQ._length();++i ) {
            if( _ftpQ[i].fcp.profileName==fcp_p->profileName &&
                _ftpQ[i].fcp.instance==fcp_p->instance ) {
               last=false;
               break;
            }
         }
         if( last ) {
            success=true;
            break;
         }
      }

      // We are only interested in this event if it matches the
      // connection profile that we are connecting for.
      if( _ftpQ[0].fcp.profileName==fcp_p->profileName ) {
         if( fcp_p->serverType==FTPSERVERTYPE_SFTP ) {
            // IF we have gotten to the STAT event AND we don't already have a process handle
            if( _ftpQ[0].event==QE_SFTP_STAT && _ftpQ[0].state==QS_END &&
                fcp_p->ssh_hprocess<0 ) {
               // We are far enough along to harvest the connection
               *fcp_p=_ftpQ[0].fcp;
               // Drive the progress guage to 100%
               _ftpopenProgressDlgCB("Connected.",100,100);
               process_events(gftpAbort);
               // The last event completed was STAT, so we must
               // harvest the remote working directory now so that
               // the directory listing after the save does not fail
               // because the current remote working directory is
               // not known.
               SftpName cname;
               _str rpath;
               _str apath;
               _str msg='';
               // Extract the absolute remote working directory and check to
               // be sure it is valid.
               rpath= (_str)_ftpQ[0].info[0];
               cname= (SftpName)_ftpQ[0].info[1];
               apath=cname.filename;
               // Check that attributes say that it is a directory
               if( !(cname.attrs.flags&SSH_FILEXFER_ATTR_PERMISSIONS) ) {
                  msg=nls("Cannot change directory: Cannot check target");
                  ftpConnDisplayError(fcp_p,msg);
               }
               if( !S_ISDIR(cname.attrs.permissions) ) {
                  msg=nls("Cannot change directory: \"%s\" is not a directory",apath);
                  ftpConnDisplayError(fcp_p,msg);
               }
               fcp_p->remoteCwd=apath;
            }
         } else {
            // FTP
            //
            // IF we have gotten to the SYST event AND we do not already have a socket.
            if( _ftpQ[0].event==QE_SYST && _ftpQ[0].state==QS_END &&
                fcp_p->sock==INVALID_SOCKET ) {
               // We are far enough along to harvest the connection
               *fcp_p=_ftpQ[0].fcp;
               // Drive the progress guage to 100%
               _ftpopenProgressDlgCB("Connected.",100,100);
               process_events(gftpAbort);
            }
         }
         lastevent=_ftpQ[0];
      }
      _ftpQTimerCallback();
      // Sleep for 0.05sec
      delay(5);
   }
   if( !progress_already_visible ) {
      formWid._delete_window();
      p_window_id=orig_view_id;
   }

   return( (success)?(0):(1) );
}

static void __ftpSystCB( FtpQEvent *pEvent )
{
   FtpQEvent event;
   FtpConnProfile fcp;

   event= *((FtpQEvent *)(pEvent));

   fcp=event.fcp;
   if( _ftpQEventIsError(event) || _ftpQEventIsAbort(event) ) {
      if( event.event!=QE_CWD && event.event!=QE_PWD && event.event!=QE_SYST ) {
         // We were starting a connection, so clean up
         _ftpDeleteLogBuffer(&fcp);
         fcp.postedCb=null;
         _ftpEnQ(QE_END_CONN_PROFILE,QS_BEGIN,0,&fcp);
         return;
      }

      // The only thing that failed is:
      //   Changing directory, so use a default
      //
      //   or
      //
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

   // Now get the system type
   fcp.postedCb=null;   // Paranoid
   _ftpEnQ(QE_SYST,QS_BEGIN,0,&fcp);

   return;
}

static void __ftpSaveAddConnProfileCB( FtpQEvent *pEvent )
{
   FtpQEvent event;
   FtpConnProfile fcp;

   event= *((FtpQEvent *)(pEvent));

   fcp=event.fcp;
   if( _ftpQEventIsError(event) || _ftpQEventIsAbort(event) ) {
      if( event.event!=QE_CWD && event.event!=QE_PWD && event.event!=QE_SYST && event.event!=QE_SFTP_STAT ) {
         // We were starting a connection, so clean up
         _ftpDeleteLogBuffer(&fcp);
         fcp.postedCb=null;
         if( fcp.serverType==FTPSERVERTYPE_SFTP ) {
            _ftpEnQ(QE_SSH_END_CONN_PROFILE,QS_BEGIN,0,&fcp);
         } else {
            // FTP
            _ftpEnQ(QE_END_CONN_PROFILE,QS_BEGIN,0,&fcp);
         }
         return;
      }

      // The only thing that failed is:
      //   Changing directory, so use a default
      //
      //   or
      //
      //   Issuing the SYST command to get the operating system name
      if( event.event==QE_CWD || event.event==QE_PWD || event.event==QE_SFTP_STAT ) {
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

   // Now set the local current working directory
   _str cwd=fcp.defLocalDir;
   cwd=strip(cwd);
   if( cwd=="" ) cwd=getcwd();
   if( last_char(cwd)==FILESEP ) cwd=substr(cwd,1,length(cwd)-1);
   typeless isdir=isdirectory(maybe_quote_filename(cwd));
   if( (isdir=="" || isdir=="0") && !isuncdirectory(cwd) ) {
      // Not a valid local directory
      cwd=getcwd();
      ftpConnDisplayWarning(&fcp,
                            "Warning: Unable to change to local directory:\n\n":+
                            fcp.defLocalDir:+"\n\nThe local current working directory is:\n\n":+
                            cwd);
   }
   fcp.localCwd=cwd;

   fcp.postedCb=null;   // Paranoid
   typeless htindex=0;
   _ftpAddCurrentConnProfile(&fcp,htindex);

   return;
}

void _init_menu_ftp(int menu_handle, int no_child_windows)
{
   if (_jaws_mode()) {
      int submenu_handle=0;
      int submenu_pos=0;
      int status=_menu_find(menu_handle,'ftpBinaryToggle',submenu_handle,submenu_pos,'M');
      if (!status) {
         return;
      }
      status=_menu_find(menu_handle,'ftpUpload',submenu_handle,submenu_pos,'M');
      if (status) {
         return;
      }
      //_menu_insert(submenu_handle,-1,MF_ENABLED,'Binary Transfer','ftpBinaryToggle','',
      int wid=_find_object('_tbFTPOpen_form._ctl_binary','N');
      if (!wid) {
         wid=_find_object('_tbFTPClient_form._ctl_binary','N');
      }
      if (wid) {
         _menu_insert(submenu_handle,-1,MF_ENABLED,'&Binary Transfer','ftpBinaryToggle','','popup-imessage Toggles binary transfer mode','Toggles binary transfer mode');
         _menu_insert(submenu_handle,-1,MF_ENABLED,'&Disconnect','ftpDisconnect','','popup-imessage Disconnect FTP session','Disconnect FTP session');
      }
   }
}
int _OnUpdate_ftpUpload(CMDUI &cmdui,int target_wid,_str command)
{
   if( !target_wid || !target_wid._isEditorCtl() ) {
      return(MF_GRAYED);
   }
   if( !ftpIsFTPDocname(target_wid.p_DocumentName) ) {
      return(MF_GRAYED);
   }

   return(MF_ENABLED);
}

_command int ftpUpload()
{
   if( !ftpIsFTPDocname(p_DocumentName) ) {
      _str msg="This is not an FTP document!";
      ftpDisplayError(msg);
      return(1);
   }

   // Already saved, so upload it
   if( p_buf_flags&VSBUFFLAG_FTP_UPLOAD_IN_PROGRESS ) {
      // Currently uploading
      return(0);
   }

   if( p_modify ) {
      return(save());
   }
   p_buf_flags |= VSBUFFLAG_FTP_UPLOAD_IN_PROGRESS;
   int status=_ftpSave(p_buf_name,p_DocumentName,true);   // Third argument forces a prompt
   p_buf_flags &= ~(VSBUFFLAG_FTP_UPLOAD_IN_PROGRESS);

   return(status);
}

static _str _ftpAssembleUploadPath(FtpConnProfile *fcp_p,_str remote_path,boolean quiet)
{
   _str path='';
   _str filename='';
   _str file='';
   // Used by OS/400
   _str member='';
   // Used by hosts that have filename with version number (VMS)
   _str ver='';
   // Used by MVS
   boolean mvs_pds=false;
   int i=0;

   switch( fcp_p->system ) {
   case FTPSYST_VMS:
   case FTPSYST_VMS_MULTINET:
      if( substr(remote_path,1,1)=='/' ) remote_path=substr(remote_path,2);
      i=lastpos(']',remote_path);
      if( !i ) {
         if( !quiet ) {
            ftpConnDisplayError(fcp_p,"Invalid remote path:\n\n":+remote_path);
         }
         return("");
      }
      path=substr(remote_path,1,i);
      filename=substr(remote_path,i+1);
      // VMS filenames have version numbers at the end (e.g. ";1").
      // We want to save the file without the version number.
      parse filename with filename ';' ver;
      break;
   case FTPSYST_VOS:
      if( substr(remote_path,1,1)=='/' ) remote_path=substr(remote_path,2);
      i=lastpos('>',remote_path);
      if( !i ) {
         if( !quiet ) {
            ftpConnDisplayError(fcp_p,"Invalid remote path:\n\n":+remote_path);
         }
         return("");
      }
      path=substr(remote_path,1,i);
      filename=substr(remote_path,i+1);
      break;
   case FTPSYST_VM:
   case FTPSYST_VMESA:
      if( substr(remote_path,1,1)=='/' ) remote_path=substr(remote_path,2);
      // We had to dream up an absolute filespec format because VM
      // has no concept of it. 'path' = CMS minidisk.
      parse remote_path with path '/' filename;
      break;
   case FTPSYST_MVS:
      if( substr(remote_path,1,2)=='//' ) {
         // PDS or SDS format
         remote_path=substr(remote_path,3);
         if( pos('/',remote_path) ) {
            // PDS member
            mvs_pds=true;
            parse remote_path with path '/' filename;
         } else {
            // SDS
            i=pos('.',remote_path);
            if( i ) {
               path=substr(remote_path,1,i);
               filename=substr(remote_path,i+1);
            } else {
               path="";
               filename=remote_path;
            }
         }
      } else {
         // HFS format which mimics Unix
         i=lastpos('/',remote_path);
         if( !i ) {
            if( !quiet ) {
               ftpConnDisplayError(fcp_p,"Invalid remote path:\n\n":+remote_path);
            }
            return("");
         }
         path=substr(remote_path,1,i);
         filename=substr(remote_path,i+1);
      }
      break;
   case FTPSYST_OS2:
      if( substr(remote_path,1,1)=='/' ) remote_path=substr(remote_path,2);
      i=lastpos('/',remote_path);
      if( !i ) {
         if( !quiet ) {
            ftpConnDisplayError(fcp_p,"Invalid remote path:\n\n":+remote_path);
         }
         return("");
      }
      path=substr(remote_path,1,i);
      filename=substr(remote_path,i+1);
      break;
   case FTPSYST_OS400:
      if( substr(remote_path,1,2)=='//' ) {
         // LFS format
         remote_path=substr(remote_path,3);
         if( !pos('/',remote_path) ) {
            if( !quiet ) {
               ftpConnDisplayError(fcp_p,"Invalid remote path:\n\n":+remote_path);
            }
            return("");
         }
         parse remote_path with path '/' filename;
         parse filename with file '/' member;
         filename=file:+'.':+member;
      } else {
         // IFS format which mimics Unix
         i=lastpos('/',remote_path);
         if( !i ) {
            if( !quiet ) {
               ftpConnDisplayError(fcp_p,"Invalid remote path:\n\n":+remote_path);
            }
            return("");
         }
         path=substr(remote_path,1,i);
         filename=substr(remote_path,i+1);
      }
      break;
   case FTPSYST_WINNT:
   case FTPSYST_HUMMINGBIRD:
      if( pos('^[a-zA-Z]\:\\',substr(remote_path,2,3),1,'er') ) {
         // DOS style
         // Strip off the leading '/'
         remote_path=substr(remote_path,2);
         i=lastpos("\\",remote_path);
         if( !i ) {
            ftpConnDisplayError(fcp_p,"Invalid remote path:\n\n":+remote_path);
            return("");
         }
         path=substr(remote_path,1,i);
         filename=substr(remote_path,i+1);
      } else {
         // Unix style
         i=lastpos('/',remote_path);
         if( !i ) {
            ftpConnDisplayError(fcp_p,"Invalid remote path:\n\n":+remote_path);
            return("");
         }
         path=substr(remote_path,1,i);
         filename=substr(remote_path,i+1);
      }
      break;
   case FTPSYST_NETWARE:
   case FTPSYST_MACOS:
   case FTPSYST_VXWORKS:
   case FTPSYST_UNIX:
   default:
      i=lastpos('/',remote_path);
      if( !i ) {
         if( !quiet ) {
            ftpConnDisplayError(fcp_p,"Invalid remote path:\n\n":+remote_path);
         }
         return("");
      }
      path=substr(remote_path,1,i);
      filename=substr(remote_path,i+1);
   }
   if( filename=="" ) {
      if( !quiet ) {
         _str msg="Invalid remote filename:\n\n":+remote_path;
         ftpConnDisplayError(fcp_p,msg);
      }
      return("");
   }
   switch( fcp_p->system ) {
   case FTPSYST_MVS:
      if( substr(path,1,1)=='/' ) {
         // HFS which mimics Unix
         remote_path=path:+_ftpUploadCase(fcp_p,filename);
      } else {
         // PDS or SDS format
         if( mvs_pds ) {
            // PDS member
            remote_path="'":+path:+'(':+_ftpUploadCase(fcp_p,filename):+')':+"'";
         } else {
            // SDS
            remote_path="'";
            if( path!="" ) {
               remote_path=remote_path:+path;
               if( last_char(remote_path)!='.' ) remote_path=remote_path:+'.';
            }
            remote_path=remote_path:+_ftpUploadCase(fcp_p,filename):+"'";
         }
      }
      break;
   case FTPSYST_VM:
   case FTPSYST_VMESA:
      // VM has no concept of an absolute path outside of the current
      // CMS minidisk, so we have to make up a format.
      // 'path' = current CMS minidisk
      remote_path='/':+path:+'/':+_ftpUploadCase(fcp_p,filename);
      break;
   case FTPSYST_OS400:
      if( substr(path,1,1)=='/' ) {
         // IFS which mimics Unix
         remote_path=path:+_ftpUploadCase(fcp_p,filename);
      } else {
         // LFS
         remote_path=path:+'/';
         parse filename with file '.' member;
         if( member!="" ) {
            remote_path=remote_path:+file:+'.':+_ftpUploadCase(fcp_p,member);
         } else {
            remote_path=remote_path:+_ftpUploadCase(fcp_p,file);
         }
      }
      break;
   default:
      remote_path=path:+_ftpUploadCase(fcp_p,filename);
   }

   return(remote_path);
}

static int _ftpSave(_str local_path,_str remote_address, 
                    boolean force_prompt=false, boolean quiet=false,
                    FtpXferType xfer_type=0)
{
   FtpConnProfile fcp;
   FtpQEvent event;
   FtpSendCmd scmd;
   boolean need_connect=false;

   if( remote_address=="" ) {
      remote_address=p_DocumentName;
   }

   // FTP document?
   if( !ftpIsFTPDocname(remote_address) ) {
      return(0);
   }

   // quiet is overridden by force_prompt
   _str pre_cmds[];
   _str post_cmds[];
   int status=0;
   p_ModifyFlags |= MODIFYFLAG_FTP_NEED_TO_SAVE;
   FtpOptions fo;
   _ftpGetOptions(fo);
   // Should we be uploading?
   if( !(fo.put==FTPOPT_ALWAYS_PUT || fo.put==FTPOPT_PROMPTED_PUT || force_prompt) ) {
      return(0);
   }

   _str host='';
   _str port='';
   _str remote_path='';
   status=_ftpParseAddress(remote_address,host,port,remote_path);
   if( status ) {
      if( !quiet ) {
         ftpDisplayError(_ftpGetMessage(status));
      }
      return(status);
   }
   // Do we already have a transfer type?
   if( xfer_type!=FTPXFER_BINARY && xfer_type!=FTPXFER_ASCII ) {
      if( _ftpGetBinary() ) {
         xfer_type=FTPXFER_BINARY;
      } else {
         xfer_type=FTPXFER_ASCII;
      }
   }
   fcp._makeempty();
   status=_ftpHHWCreateConnProfile(host,port,&fcp);
   if( status ) {
      if( status!=COMMAND_CANCELLED_RC && !quiet ) {
         ftpDisplayError("Unable to open a connection.  ":+_ftpGetMessage(status));
      }
      return(status);
   }
   if( !quiet && (fo.put==FTPOPT_PROMPTED_PUT || force_prompt) ) {
      int xfer_flags = 0;
      if( fcp.serverType == FTPSERVERTYPE_SFTP ) {
         xfer_flags |= FTPXFERFLAG_NOCHOICE;
      }
      xfer_type=show("-modal _ftpUpload_form",remote_address,xfer_type,xfer_flags);
      if( xfer_type=="" ) {
         // User cancelled or said "No"
         return(0);
      }
   }
   if( fcp.serverType!=FTPSERVERTYPE_FTP ) {
      // Probably SFTP where transfers are always binary
      xfer_type=FTPXFER_BINARY;
   }
   fcp.xferType=xfer_type;
   status=_ftpParseAddress(remote_address,host,port,remote_path);
   if( status ) {
      if( !quiet ) {
         ftpDisplayError('Unable to save "':+remote_address:+'".  ':+_ftpGetMessage(status));
      }
      return(status);
   }

   // Delay filling in the STOR path until after we are sure we know
   // what type of host we are uploading to.
   //cmdargv[1]=remote_path;
   //scmd.cmdargv=cmdargv;

   _str line=file_match("-p +v "maybe_quote_filename(local_path),1);
   if( line=="" ) {
      if( !quiet ) {
         _str msg='The local file "':+local_path:+'" associated with the remote file ':+
             '"':+remote_address:+'" does not exist';
         ftpDisplayError(msg);
      }
      return(FILE_NOT_FOUND_RC);
   }
   typeless size = substr(line,DIR_SIZE_COL,DIR_SIZE_WIDTH);

   boolean success=false;
   gftpAbort=false;
   int orig_view_id=p_window_id;
   int formWid=show("_ftpProgress_form");
   if( !formWid ) {
      if( !quiet ) {
         _message_box('Could not show form: "_ftpProgress_form"','',MB_OK|MB_ICONEXCLAMATION);
      }
      return(1);
   }

   // Do not start anything new until the queue empties
   if( _ftpQ._length() ) {
      formWid.p_caption="Waiting for current operation to finish...";
      for(;;) {
         process_events(gftpAbort);
         if( gftpAbort ) break;
         _ftpQTimerCallback();
         if( _ftpQ._length()<1 ) break;
      }
   }
   if( gftpAbort ) {
      // User did not want to wait for the current operation to finish
      formWid._delete_window();
      return(1);
   }

   status=0;
   fcp.postedCb=null;
   _str start_caption="";
   // orig_cwd is used to keep track of the original remote working
   // directory in case the save fails mid-way and we have to change
   // it back. VM hosts require this when STORing files to a CMS
   // minidisk other than the current minidisk.
   _str orig_cwd="";
   if( fcp.serverType==FTPSERVERTYPE_SFTP ) {
      fcp.postedCb=null;
   } else {
      fcp.postedCb=(typeless)__ftpSystCB;
   }
   // need_connect will tell us if we had to start a connection
   status=_ftpSynchronousConnect(&fcp,need_connect,quiet);
   if( status ) {
      // Connect failed or was cancelled
      formWid._delete_window();
      return(status);
   }
   if( need_connect ) {
      // A connection had to be established.
      // If this was a reconnect, then we must remove this particular
      // connection profile from the list of current connections, so
      // that it can be re-added. If this was _not_ a reconnect, then
      // this call will quietly fail.
      _ftpRemoveCurrentConnProfile(&fcp);
   }

   // We can now assemble the upload path because we are sure
   // of the host type.
   // If something went wrong then _ftpAssembleUploadPath() will
   // take care of alerting the user (if quiet=false).
   remote_path=_ftpAssembleUploadPath(&fcp,remote_path,quiet);
   if( remote_path=="" ) return(1);

   if( fcp.serverType==FTPSERVERTYPE_SFTP ) {
      fcp.postedCb=null;
      if( need_connect ) {
         // If we needed to connect prior to the upload, then this
         // callback will take care of getting the listing after
         // we are done uploading.
         fcp.postedCb=(typeless)__ftpSaveAddConnProfileCB;
      }
      scmd._makeempty();
      scmd.xfer_type=FTPXFER_BINARY;   // Ignored by SFTP
      _str cmdargv[];
      cmdargv._makeempty();
      cmdargv[0]=remote_path;
      scmd.cmdargv=cmdargv;
      scmd.datahost=scmd.dataport="";   // Ignored by SFTP
      scmd.src=local_path;
      scmd.pasv=0;   // Ignored by SFTP
      scmd.size=size;
      scmd.progressCb=_ftpopenProgressDlgCB;
      // Members used specifically by SFTP
      scmd.hfile= -1;
      scmd.hhandle= -1;
      scmd.offset=0;
      _ftpEnQ(QE_SFTP_PUT,QS_BEGIN,0,&fcp,scmd);
   } else {
      // FTP
      fcp.postedCb=null;
      if( need_connect ) {
         // If we needed to connect prior to the upload, then this
         // callback will take care of getting the listing after
         // we are done uploading.
         fcp.postedCb=(typeless)__ftpSaveAddConnProfileCB;
      }
      scmd._makeempty();
      scmd.xfer_type=xfer_type;
      _str cmdargv[];
      cmdargv._makeempty();
      cmdargv[0]="STOR";
      cmdargv[1]=remote_path;
      scmd.cmdargv=cmdargv;
      scmd.datahost=scmd.dataport="";
      scmd.src=local_path;
      scmd.pasv= (fcp.useFirewall && fcp.global_options.fwenable && fcp.global_options.fwpasv);
      scmd.size=size;
      scmd.progressCb=_ftpopenProgressDlgCB;

      orig_cwd=fcp.remoteCwd;
      int hosttype=fcp.system;
      if( hosttype==FTPSYST_OS400 ) {
         _str pre_cmdargv[],post_cmdargv[];
         pre_cmds._makeempty();
         post_cmds._makeempty();
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
         scmd.pre_cmds=pre_cmds;
         scmd.post_cmds=post_cmds;
         _ftpEnQ(QE_SEND_CMD,QS_CMD_BEFORE_BEGIN,0,&fcp,scmd);
      } else if( hosttype==FTPSYST_VM || hosttype==FTPSYST_VMESA ) {
         _ftpEnQ(QE_SEND_CMD,QS_CWD_BEFORE_BEGIN,0,&fcp,scmd);
      } else {
         _ftpEnQ(QE_SEND_CMD,QS_BEGIN,0,&fcp,scmd);
      }
   }
   if( _ftpQ._length()<1 ) {
      // This should never happen
      return(1);
   }

   FtpQEvent lastevent;
   lastevent._makeempty();
   lastevent.event=0;
   lastevent.start=0;
   lastevent.state=0;
   _ftpInitConnProfile(lastevent.fcp);
   for(;;) {
      process_events(gftpAbort);
      if( gftpAbort ) {
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
         if( _ftpQEventIsError(lastevent) || _ftpQEventIsAbort(lastevent) ) {
            // Upload failed, so bail out
            break;
         }
         // Completed successfully
         success=true;
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
            success=true;
            break;
         }
      }

      // We are only interested in this event if it matches the
      // connection profile that we are saving for.
      if( _ftpQ[0].fcp.profileName==fcp.profileName ) {
         lastevent=_ftpQ[0];
      }
      _ftpQTimerCallback();
      // Sleep for 0.05sec
      delay(5);
   }
   formWid._delete_window();
   p_window_id=orig_view_id;
   if( success ) {
      p_ModifyFlags &= ~(MODIFYFLAG_FTP_NEED_TO_SAVE);
      _MaybeUpdateFTPTab("");
      //_MaybeUpdateFTPClient("");
   } else {
      status=1;
      if( lastevent.fcp.remoteCwd!=orig_cwd ) {
         if( orig_cwd!="" ) {
            _ftpLog(&lastevent.fcp,"Failed during STOR. CWD back to ":+orig_cwd);
            _ftpEnQ(QE_CWD,QS_BEGIN,0,&lastevent.fcp,orig_cwd);
         }
      }
   }

   return(status);
}

/**
 * Copy/upload an arbitrary local file system file.
 * 
 * @param line Command line. 
 * <pre>
 * Usage: ftpCopy [+-A|+-B] [+-PROMPT] <source> <dest> 
 * +-A      Upload ASCII. Determined by current
 *          connection by default. Note: Meaningless
 *          for SFTP connection since they are always
 *          binary.
 * +-B      Upload BINARY.  Determined by current
 *          connection by default. Note: Meaningless
 *          for SFTP connection since they are always
 *          binary.
 * +-PROMPT Prompt for connection profile when it cannot be 
 *          determined automatically. No prompting by
 *          default.
 * <source> Local file path. 
 * <dest>   Remote file path in the form: ftp://host/path/filename.ext
 *          IMPORTANT: All parts of the remote path are REQUIRED.
 * </pre> 
 *
 * @example
 * ftpCopy d:\local\path\to\ftp.e ftp://hostname/path/ftp.e
 * 
 * @return 0 on success.
 */
_command int ftpCopy(_str line="") name_info(','VSARG2_NCW|VSARG2_READ_ONLY)
{
   FtpConnProfile* fcp_p;

   if( line == "" ) {
      _str msg = "Not enough arguments. Usage: ftpCopy [+-A|+-B] [+-PROMPT] <source> <dest>";
      message(msg);
      return 1;
   }

   FtpXferType xfer_type = 0;
   boolean prompt = false;
   _str src = "";
   _str dest = "";
   _str opt = '';
   _str ch = '';

   while( line != "" ) {
      //parse line with opt line;
      opt = parse_file(line,false);
      ch = substr(opt,1,1);
      if( ch == '+' || ch == '-' ) {
         opt = lowcase(substr(opt,2));
         switch( opt ) {
         case 'a':
            xfer_type = FTPXFER_ASCII;
            break;
         case 'b':
            xfer_type = FTPXFER_BINARY;
            break;
         case 'prompt':
            prompt = true;
            break;
         default:
            // Unknown option
         }
         continue;
      }
      if( src == "" ) {
         src = opt;
      } else if( dest == "" ) {
         dest = opt;
      } else {
         // Unknown
      }
   }

   if( src == "" || dest == "" ) {
      _str msg = "Not enough arguments. Usage: ftpCopy [+-A|+-B] [+-PROMPT] <source> <dest>";
      message(msg);
      return 1;
   }

   // Check for correct format already
   int status = 0;
   _str host = "";
   _str port = "";
   _str path = "";
   if( substr(dest,1,length("ftp://")) != "ftp://" ) {
      status = _ftpParseAddress(dest,host,port,path);
      if( 0 == status ) {
         dest = "ftp://" :+ host;
         if( port != "" ) {
            dest = dest :+ ":":+port;
         }
         dest = dest :+ path;
      } else {
         // Find the current connection for the FTP Client toolbar and use it
         fcp_p = ftpclientGetCurrentConnProfile();
         if( !fcp_p ) {
            // Try the FTP Open tab on the Project toolbar
            fcp_p = ftpopenGetCurrentConnProfile();
         }
         if( !fcp_p ) {
            _str msg = "No host name";
            message(msg);
            return 1;
         }
         dest = _ftpAbsolute(fcp_p,dest);
         dest = "ftp://" :+ fcp_p->host :+ dest;
      }
   }

   // Current connection?
   fcp_p = ftpclientGetCurrentConnProfile();
   if( !fcp_p ) {
      // Okay, try the FTP Open tool window
      fcp_p = ftpopenGetCurrentConnProfile();
   }

   // Source
   if( fcp_p ) {
      // Make the source absolute relative to the local side of the FTP Client
      src = _ftpLocalAbsolute(fcp_p,src);
   } else {
      // Use the editor's current working directory
      src = absolute(src);
   }

   // Transfer type
   if( fcp_p && xfer_type != FTPXFER_ASCII && xfer_type != FTPXFER_BINARY ) {
      xfer_type = fcp_p->xferType;
   }

   int temp_wid, orig_wid;
   status = _open_temp_view(src,temp_wid,orig_wid);
   if( status == 0 ) {
      int orig_buf_flags = p_buf_flags;
      p_buf_flags |= VSBUFFLAG_FTP_UPLOAD_IN_PROGRESS;
      status = _ftpSave(src,dest,false,true,xfer_type);
      p_buf_flags = orig_buf_flags;
      _delete_temp_view(temp_wid);
      p_window_id = orig_wid;
   }
   return status;
}

int _cbsave_ftp(...)
{
   if( p_modify ) {
      // This could happen if the user did a save() to a filename other than
      // the current buffer name. Blow out if this is the case.
      return(0);
   }

   if( p_buf_flags&VSBUFFLAG_FTP_UPLOAD_IN_PROGRESS ) {
      // This file is currently being uploaded
      return(0);
   }

   int status=0;
   if( ftpIsFTPDocname(p_DocumentName) ) {
      // This is also set in _ftpSave()
      // We MUST set this even before checking to see if we are _in_quit
      // or _ftpsave_override because a quit() would fail to upload the
      // file because MODIFYFLAG_FTP_NEED_TO_SAVE was never set.
      p_ModifyFlags |= MODIFYFLAG_FTP_NEED_TO_SAVE;
      if( _in_quit || _ftpsave_override ) {
         // quit() calls save(), so we would end up prompting the user
         // twice with the upload prompt.
         //
         // or
         //
         // A macro is overriding the upload.
         return(0);
      }
      int orig_view_id=p_window_id;
      p_buf_flags |= VSBUFFLAG_FTP_UPLOAD_IN_PROGRESS;
      status=_ftpSave(p_buf_name,p_DocumentName);
      p_window_id=orig_view_id;
      p_buf_flags &= ~(VSBUFFLAG_FTP_UPLOAD_IN_PROGRESS);
   }

   return(status);
}

static int gSaveStatus=0;
int _cbquit_ftp(int buf_id,_str buf_name,_str document_name,int buf_flags)
{
   int status;

   status=0;
   gSaveStatus=0;
   if( ftpIsFTPDocname(document_name) ) {
      // We do not have to worry about saving because quit() took care of
      // that, but we do have to worry about the buffer not being uploaded
      // yet.
      if( p_ModifyFlags&MODIFYFLAG_FTP_NEED_TO_SAVE ) {
         if( p_buf_flags&VSBUFFLAG_FTP_UPLOAD_IN_PROGRESS ) {
            // This buffer is currently being uploaded.
            // We should not attempt to save it again.
            gSaveStatus=0;
            return(0);
         }
         p_buf_flags |= VSBUFFLAG_FTP_UPLOAD_IN_PROGRESS;
         int orig_view_id=p_window_id;
         // 1 as third argument forces a prompt-for-save regardless
         // of the global options.
         status=_ftpSave(buf_name,document_name,true);
         gSaveStatus=status;
         p_window_id=orig_view_id;
         p_buf_flags &= ~(VSBUFFLAG_FTP_UPLOAD_IN_PROGRESS);
      }
   }

   return(status);
}

int _cbquit2_ftp(int buf_id,_str buf_name,_str document_name,int buf_flags)
{
   //messageNwait('_cbquit2_ftp: buf_name='buf_name'  document_name='document_name);
   if( ftpIsFTPDocname(document_name) ) {
      // This test will always short-circuit on _ftpIsLocalFilename() because
      // it only checks the path, but we left in _ftpIsTempFilename() in case
      // _ftpIsLocalFilename() gets more picky later.
      if( _ftpIsLocalFilename(buf_name) || _ftpIsTempFilename(buf_name) ) {
         if( p_buf_flags&VSBUFFLAG_FTP_UPLOAD_IN_PROGRESS ) {
            // This buffer is currently being uploaded.
            // We cannot delete it because we would get "Access denied".
            return(1);
         }
         if( !_in_project_close ) {
            if( gSaveStatus ) {
               ftpDisplayWarning('Warning: Upload failed on "':+document_name:+'"':+
                                 "\n\nThe local copy still resides at:\n\n":+
                                 '"':+buf_name:+'"');
               return(1);
            }
            int status=delete_file(buf_name);
            if( status && status!=FILE_NOT_FOUND_RC ) {
               ftpDisplayWarning('Warning: Unable to delete the temporary ftp file "':+buf_name:+'"');
               return(1);
            }
         }
      }
   }

   return(0);
}

int _ftpVSProxyCommand(FtpConnProfile *fcp_p,typeless cmd,...)
{
   if( !vssIsConnectionAlive(fcp_p->vsproxy_sock) ) {
      return(VSRC_FTP_CONNECTION_DEAD);
   }
   _str line='';
   int i=0;
   if( cmd._varformat()==VF_ARRAY ) {
      // We have an array representing the command and arguments
      line=strip(cmd[0]);
      for( i=1;i<cmd._length();++i ) {
         line=line" "cmd[i];
      }
   } else {
      // Append additional arguments
      line=strip(cmd);
      if( substr(line,length(line),1)=="\n" ) {   // Strip eol
         if( substr(line,length(line)-1,1)=="\r" ) {
            line=substr(line,1,length(line)-2);
         } else {
            line=substr(line,1,length(line)-1);
         }
      }
      for( i=3;i<=arg();++i ) {
         line=line" "arg(i);
      }
   }

   // Log any responses that may have come in already.
   // This could happen if we aborted a command before we got the
   // response.
   FtpQEvent event;   // Fake event
   event._makeempty();
   event.event=0;
   event.fcp= *fcp_p;
   event.start=0;
   event.state=0;
   _str dummy='';
   int status=_ftpQCheckResponse(&event,true,dummy,true);
   if( status ) {
      // Do not care
   }

   if( _ftpdebug&FTPDEBUG_LOG_PROXY ) {
      _ftpLog(fcp_p,line);
   }

   line=line:+EOL;
   //messageNwait('line='line);
   status=vssSocketSendZ(fcp_p->vsproxy_sock,_UTF8ToMultiByte(line));
   //say(_MultiByteToUTF8(_UTF8ToMultiByte(line)));

   return(status);
}

_str FTPUserIniFilename()
{
   if( gIniInitDone ) {
      return(_ftpUserIniFilename);
   }
   _ftpUserIniFilename=usercfg_path_search(VSCFGFILE_USER_FTP);
   // _ftpUserIniFilename may be ''

   gIniInitDone=true;

   return(_ftpUserIniFilename);
}

_str FTPMaybeCreateUserIniFile()
{
   int status=0;
   _str filenopath=VSCFGFILE_USER_FTP;

   usercfg_init_write(filenopath);

   _str filename=_ConfigPath():+filenopath;
   if( file_match("-p "maybe_quote_filename(filename),1)=="" ) {
      // Doesn't exist so create it
      int temp_view_id=0;
      int orig_view_id=_create_temp_view(temp_view_id);
      if( orig_view_id=="" ) {
         _message_box('Cannot find or create configuration file "':+VSCFGFILE_USER_FTP:+'"','',MB_OK|MB_ICONEXCLAMATION);
         return("");
      }
      p_UTF8=0;

      _delete_line();

      // Insert default common options
      insert_line("[options]");
      _insert_text("\n":+FTP_DEFAULT_OPTIONS);
      insert_line("");   // Separate profile sections w/ blank line

#if 0 /* FTP no longer supported on slickedit.com */

      // Insert SlickEdit ftp site info
      insert_line("[profile-":+FTP_SLICKEDIT_PROFILE_NAME:+"]");
      // host=
      // userid=
      // password=
      // anonymous=
      // savepassword=
      // defremotehostdir=
      // deflocaldir=
      // remotefilter=
      // localfilter=
      // xfertype=
      // port=
      // timeout=
      // keepalive=
      // usefw=
      // uploadcase=
      _insert_text("\n":+FTP_SLICKEDIT_PROFILE_DATA);
      insert_line("");   // Separate profile sections w/ blank line
#endif

      p_buf_name=filename;
      status=_save_config_file();
      if( status ) {
         filename="";
      }
      activate_window(orig_view_id);
      _delete_temp_view(temp_view_id);
   }

   if( status ) {
      return("");
   } else {
      _ftpUserIniFilename=filename;
      gIniInitDone=true;
   }

   return(filename);
}

void _ftpInitConnProfile(FtpConnProfile &fcp)
{
   FtpOptions fo;

   fcp.profileName="";
   fcp.instance=0;
   fcp.host="";
   fcp.userId="";
   fcp.password="";
   fcp.anonymous=false;
   fcp.savePassword=true;
   fcp.defRemoteDir="";
   fcp.defLocalDir="";
   fcp.xferType=FTPXFER_BINARY;
   fcp.port=FTPDEF_PORT;
   fcp.timeout=FTPDEF_TIMEOUT;
   fcp.keepAlive=false;
   fcp.uploadCase=FTPFILECASE_PRESERVE;
   fcp.resolveLinks=false;
   fcp.useFirewall=false;
   fcp.global_options._makeempty();
   fcp.lastStatusLine="";
   fcp.prevStatusLine="";
   fcp.sock=INVALID_SOCKET;
   fcp.vsproxy_sock=INVALID_SOCKET;
   fcp.vsproxy_pid= -1;
   fcp.vsproxy=true;
   fcp.logBufName="";
   fcp.remoteDir._makeempty();
   fcp.localCwd="";
   fcp.remoteCwd="";
   fcp.cwdHist._makeempty();
   fcp.localFileFilter=ALLFILES_RE;
   fcp.remoteFileFilter=FTP_ALLFILES_RE;
   fcp.localSortFlags=0;
   fcp.remoteSortFlags=0;
   fcp.autoRefresh=true;
   fcp.remoteRoot="";
   fcp.localRoot="";
   fcp.reply="";
   fcp.idle=MAXINT;
   fcp.system=FTPSYST_AUTO;

   fcp.serverType=FTPSERVERTYPE_FTP;
   fcp.sshAuthType=SSHAUTHTYPE_AUTO;
   fcp.ssh_checkerrors=true;
   fcp.ssh_hin= -1;
   fcp.ssh_hout= -1;
   fcp.ssh_herr= -1;
   fcp.ssh_hprocess= -1;
   fcp.sftp_opid=0;

   // Sanity please for default callbacks
   fcp.postedCb=null;
   fcp.errorCb = ftpDisplayError;
   fcp.warnCb = ftpDisplayWarning;
   fcp.infoCb = ftpDisplayInfo;

   fcp.dir_stack._makeempty();
   fcp.recurseDirs=false;
   fcp.ignoreListErrors=false;
   fcp.downloadLinks=false;
   fcp.extra._makeempty();
   fcp.remote_address="";
   if( !_ftpGetOptions(fo) ) {
      if( fcp.anonymous ) {
         fcp.userId=FTPDEF_ANONYMOUS_USERID;
         fcp.password=fo.email;
      }
      fcp.defLocalDir=fo.deflocaldir;
      fcp.port=fo.port;
      fcp.timeout=fo.timeout;
      fcp.keepAlive=fo.keepalive;
      fcp.uploadCase=fo.uploadcase;
      fcp.resolveLinks=fo.resolvelinks;
      fcp.useFirewall=fo.fwenable;
      fcp.global_options=fo;
   }

   return;
}

/**
 * Used to quickly check if there is a profile by the name ProfileName in the
 * user ftp ini file.
 */
boolean _ftpIsConnProfile(_str ProfileName)
{
   int temp_view_id=0;
   int orig_view_id=0;
   int status=_open_temp_view(FTPUserIniFilename(),temp_view_id,orig_view_id);
   if( status ) {
      return(false);
   }
   p_window_id=temp_view_id;
   top();
   status=search('^\[profile-':+ProfileName:+'\][ \t]@$','er@');
   _delete_temp_view(temp_view_id);
   p_window_id=orig_view_id;   // Just in case
   if( !status ) {
      // Found a match
      return(true);
   }

   return(false);
}

int _ftpOpenConnProfile(_str ProfileName,FtpConnProfile *fcp_p)
{
   (*fcp_p)._makeempty();
   _ftpInitConnProfile(*fcp_p);

   int orig_view_id=p_window_id;
   int temp_view_id=0;
   int status=_ini_get_section(FTPUserIniFilename(),"profile-":+strip(ProfileName),temp_view_id);
   if( status ) {
      ftpDisplayError('Error opening profile "':+ProfileName:+'".  ':+get_message(status));
      return(status);
   }
   _str line='';
   p_window_id=temp_view_id;
   fcp_p->profileName=ProfileName;
   top();up();
   for( ;; ) {
      if( down() ) break;
      get_line(line);
      if( line=='' ) continue;
      _str varble='';
      _str val='';
      parse line with varble '=' val;
      varble=strip(varble);
      val=strip(val);
      switch( varble ) {
      case 'host':
         fcp_p->host=val;
         break;
      case 'servertype':
         if( !isinteger(val) ) {
            val=FTPSERVERTYPE_FTP;
         }
         fcp_p->serverType= (int)val;
         break;
      case 'sshauthtype':
         if( !isinteger(val) ) {
            val=SSHAUTHTYPE_AUTO;
         }
         fcp_p->sshAuthType= (int)val;
         break;
      case 'hosttype':
         if( !isinteger(val) ) {
            val=FTPSYST_AUTO;
         }
         fcp_p->system= (int)val;
         break;
      case 'userid':
         fcp_p->userId=val;
         break;
      case 'password':
         fcp_p->password=val;
         break;
      case 'anonymous':
         fcp_p->anonymous= (isinteger(val) && val);
         break;
      case 'savepassword':
         fcp_p->savePassword= (isinteger(val) && val);
         break;
      case 'defremotehostdir':
         fcp_p->defRemoteDir=val;
         break;
      case 'deflocaldir':
         fcp_p->defLocalDir=val;
         break;
      case 'remotefilter':
         fcp_p->remoteFileFilter=val;
         break;
      case 'localfilter':
         fcp_p->localFileFilter=val;
         break;
      case 'autorefresh':
         if( isinteger(val) ) {
            fcp_p->autoRefresh= (val!=0);
         }
         break;
      case 'remoteroot':
         fcp_p->remoteRoot=val;
         break;
      case 'localroot':
         fcp_p->localRoot=val;
         break;
      case 'xfertype':
         if( !isinteger(val) || val<FTPXFER_ASCII || val>FTPXFER_BINARY ) {
            val=FTPXFER_BINARY;
         }
         fcp_p->xferType= (FtpXferType)val;
      case 'port':
         if( isinteger(val) && val>0 && val<=65535 ) {
            fcp_p->port= (int)val;
         }
         break;
      case 'timeout':
         if( isinteger(val) ) {
            fcp_p->timeout= (int)val;
         }
         break;
      case 'keepalive':
         fcp_p->keepAlive= (isinteger(val) && val);
         break;
      case 'uploadcase':
         if( isinteger(val) && val>=FTPFILECASE_PRESERVE && val<=FTPFILECASE_UPPER ) {
            fcp_p->uploadCase= (int)val;
         }
         break;
      case 'resolvelinks':
         fcp_p->resolveLinks= (isinteger(val) && val);
         break;
      case 'usefw':
         fcp_p->useFirewall= (isinteger(val) && val);
         break;
      default:
         // Should never get here, but will allow it
         break;
      }
   }
   _delete_temp_view(temp_view_id);
   p_window_id=orig_view_id;   // Just in case

   if( fcp_p->host=='' ) {
      ftpDisplayError('Missing host name for profile "':+fcp_p->profileName:+'"');
      return(1);
   }

   return(0);
}

int _ftpSaveConnProfile(FtpConnProfile *fcp_p)
{
   int temp_view_id=0;
   int orig_view_id=_create_temp_view(temp_view_id);
   if( orig_view_id=="" ) {
      // Don't need to display error because _create_temp_view() already did
      return(1);
   }

   _delete_line();
   insert_line("host=":+fcp_p->host);
   insert_line("servertype=":+fcp_p->serverType);
   insert_line("sshauthtype=":+fcp_p->sshAuthType);
   insert_line("hosttype=":+fcp_p->system);
   insert_line("userid=":+fcp_p->userId);
   insert_line("password=":+fcp_p->password);   // Password is already encrypted
   insert_line("anonymous=":+fcp_p->anonymous);
   insert_line("savepassword=":+fcp_p->savePassword);
   insert_line("defremotehostdir=":+fcp_p->defRemoteDir);
   insert_line("deflocaldir=":+fcp_p->defLocalDir);
   insert_line("remotefilter=":+fcp_p->remoteFileFilter);
   insert_line("localfilter=":+fcp_p->localFileFilter);
   insert_line("autorefresh=":+fcp_p->autoRefresh);
   insert_line("remoteroot=":+fcp_p->remoteRoot);
   insert_line("localroot=":+fcp_p->localRoot);
   insert_line("xfertype=":+fcp_p->xferType);
   insert_line("port=":+fcp_p->port);
   insert_line("timeout=":+fcp_p->timeout);
   insert_line("usefw=":+fcp_p->useFirewall);
   insert_line("keepalive=":+fcp_p->keepAlive);
   insert_line("uploadcase=":+fcp_p->uploadCase);
   insert_line("resolvelinks=":+fcp_p->resolveLinks);
   insert_line("");   // Separate profile sections w/ blank line

   // FTPMaybeCreateUserIniFile() takes care of the error message
   if( FTPMaybeCreateUserIniFile()=="" ) return(1);

   p_window_id=orig_view_id;
   int status=_ini_put_section(FTPUserIniFilename(),"profile-":+strip(fcp_p->profileName),temp_view_id);
   p_window_id=orig_view_id;   // Just in case

   return(status);
}

int _ftpDeleteConnProfile(_str ProfileName)
{
   // FTPMaybeCreateUserIniFile() takes care of the error message
   if( FTPMaybeCreateUserIniFile()=="" ) return(1);

   int status=_ini_delete_section(FTPUserIniFilename(),"profile-":+ProfileName);

   return(status);
}

/**
 * Note that the most recent entries are at the end of the array.
 * This makes it easier to add new entries.
 */
int def_maxcombohist;   // Use this to limit the number of entries
int _ftpSaveCwdHist(_str ProfileName,_str CwdHist[])
{
   int orig_view_id=p_window_id;
   int temp_view_id=0;
   int status=_ini_get_section(FTPUserIniFilename(),'profile-':+strip(ProfileName),temp_view_id);
   if( status ) return(status);
   p_window_id=temp_view_id;

   // Get rid of old history
   top();
   int dummy=0;
   search('^cwdhist:i @=?@\n','@ir','',dummy);

   // Insert the new history.
   // Remember that the most recent entries are at the end, so reverse.
   bottom();
   int len=CwdHist._length();

   // Upper limit of def_maxcombohist
   int first=0;
   if( len>def_maxcombohist ) {
      first=0+(len-def_maxcombohist);
   }

   int i;
   for( i=len-1;i>=first;--i ) {
      _str cwd=CwdHist[i];
      insert_line('cwdhist':+(len-i-1):+'=':+cwd);
   }

   // FTPMaybeCreateUserIniFile() takes care of the error message
   if( FTPMaybeCreateUserIniFile()=="" ) return(1);

   // _ini_put_section() takes care of deleting the view
   _ini_put_section(FTPUserIniFilename(),"profile-":+strip(ProfileName),temp_view_id);
   //_delete_temp_view(temp_view_id);
   p_window_id=orig_view_id;

   return(0);
}

/**
 * Note that the most recent entries are at the end of the array.
 * This makes it easier to add new entries.
 */
int _ftpGetCwdHist(_str ProfileName,_str (&CwdHist)[])
{
   _str templist[];   // Use a temporary list so we can reverse the order easily

   templist._makeempty();
   CwdHist._makeempty();

   int temp_view_id=0;
   int orig_view_id=p_window_id;
   int status=_ini_get_section(FTPUserIniFilename(),'profile-':+strip(ProfileName),temp_view_id);
   if( status ) return(status);
   p_window_id=temp_view_id;

   top();
   status=search('^cwdhist:i','@ir');
   while( !status ) {
      _str line='';
      get_line(line);
      _str cwd='';
      parse line with . '=' cwd;
      cwd=strip(cwd);
      if( cwd!="" ) {
         templist[templist._length()]=cwd;
      }

      // Upper limit of def_maxcombohist
      if( templist._length() >= def_maxcombohist ) break;

      status=repeat_search();
   }
   _delete_temp_view(temp_view_id);

   // Now reverse the order because the most recent entries were last
   int i=0;
   for( i=templist._length()-1;i>=0;--i ) {
      CwdHist[CwdHist._length()]=templist[i];
   }

   return(0);
}

/**
 * Note that the most recent entries are at the end of the array.
 * This makes it easier to add new entries.
 */
void _ftpAddCwdHist(_str (&CwdHist)[],_str Cwd)
{
   if( Cwd=="" ) return;

   // Upper limit of def_maxcombohist
   if( CwdHist._length() >= def_maxcombohist ) {
      int n=def_maxcombohist-CwdHist._length()+1;
      CwdHist._deleteel(0,n);
   }

   // Delete duplicates
   int i;
   for( i=0;i<CwdHist._length();++i ) {
      if( CwdHist[i]==Cwd ) {
         CwdHist._deleteel(i);
      }
   }

   // Add the new entry
   CwdHist[CwdHist._length()]=Cwd;

   return;
}

/**
 * Attempts to find FTP connection profile name(s) that match the host name
 * passed in. The result is an array of strings which represent a list of
 * all matching FTP connection profile names.
 *
 * @param Host        Name of the host to match
 * @param ProfileName Array of profile names matching Host.
 *
 * @return 0 if match(es) are found. Otherwise non-zero is returned.
 */
int _ftpHostNameToProfileName(_str Host,_str (&ProfileName)[])
{
   _str temparr[];

   int temp_view_id=0;
   int orig_view_id=0;
   int status=_open_temp_view(FTPUserIniFilename(),temp_view_id,orig_view_id);
   if( status ) {
      _message_box('Cannot find configuration file "':+FTPUserIniFilename():+'"','',MB_OK|MB_ICONEXCLAMATION);
      return(1);
   }
   top();
   temparr._makeempty();
   status=search('^\[','er@');
   while( !status ) {
      _str line='';
      get_line(line);
      _str profilename='';
      parse line with '[profile-' profilename ']';
      profilename=strip(profilename);
      if( profilename=='' ) {
         // This should never happen
         status=repeat_search();
         continue;
      }
      for( ;; ) {
         if( down() ) break;
         get_line(line);
         if( substr(line,1,1)=='[' ) {
            // Get off the section line so the repeat_search()
            // does not skip over it.
            up();
            break;   // We hit the next section unexpectedly
         }
         _str varble='';
         _str val='';
         parse line with varble '=' val;
         varble=strip(varble);
         val=strip(val);
         if( varble=="host" ) {
            if( val==Host ) {
               temparr[temparr._length()]=profilename;
            }
            break;
         }
      }
      status=repeat_search();
   }
   _delete_temp_view(temp_view_id);
   p_window_id=orig_view_id;

   if( temparr._length() ) {
      ProfileName=temparr;
      return(0);
   }

   // No match for Host
   return(1);
}

void _ftpInitOptions(FtpOptions &fo)
{
   fo.email=FTPDEF_ANONYMOUS_PASS;
   fo.deflocaldir="";
   fo.put=FTPOPT_PROMPTED_PUT;
   fo.resolvelinks=false;
   fo.timeout=FTPDEF_TIMEOUT;
   fo.port=FTPDEF_PORT;
   fo.keepalive=false;
   fo.uploadcase=FTPFILECASE_PRESERVE;
   fo.fwhost="";
   fo.fwport=FTPDEF_PORT;
   fo.fwuserid="";
   fo.fwpassword="";
   fo.fwtype=FTPOPT_FWTYPE_USERAT;
   fo.fwpasv=false;
   fo.fwenable=false;
   fo.sshexe="";
   fo.sshsubsystem="sftp";

   return;
}

int _ftpGetOptions(FtpOptions &fo)
{
   int temp_view_id=0;
   int orig_view_id=0;
   int status=_open_temp_view(FTPUserIniFilename(),temp_view_id,orig_view_id);
   if( status ) {
      // No user config file yet, so setup some default options
      _ftpInitOptions(fo);
      return(0);
   }
   p_window_id=temp_view_id;
   top();
   status=search('^\[options]','er@');
   if( status ) {
      // Did not find an [options] section, so setup some default options
      _ftpInitOptions(fo);
   } else {
      _ftpInitOptions(fo);   // This will catch any that were not in the ini file
      for( ;; ) {
         if( down() ) break;
         _str line='';
         get_line(line);
         if( line=='' ) continue;
         if( substr(line,1,1)=='[' ) break;   // Start of next section
         _str varble='';
         _str val='';
         parse line with varble '=' val;
         varble=strip(varble);
         val=strip(val);
         switch( varble ) {
         case 'email':
            fo.email=val;
            break;
         case 'deflocaldir':
            fo.deflocaldir=val;
            break;
         case 'put':
            fo.put= (int)val;
            break;
         case 'resolvelinks':
            fo.resolvelinks= (isinteger(val) && val);
            break;
         case 'timeout':
            if( !isinteger(val) || val<=0 ) {
               val=FTPDEF_TIMEOUT;
            }
            fo.timeout= (int)val;
            break;
         case 'port':
            if( !isinteger(val) || val<=0 || val>65535 ) {
               val=FTPDEF_PORT;
            }
            fo.port= (int)val;
            break;
         case 'keepalive':
            fo.keepalive= (isinteger(val) && val);
            break;
         case 'uploadcase':
            if( !isinteger(val) || val<FTPFILECASE_PRESERVE || val>FTPFILECASE_UPPER ) {
               val=FTPFILECASE_PRESERVE;
            }
            fo.uploadcase= (int)val;
            break;
         case 'fwhost':
            fo.fwhost=val;
            break;
         case 'fwport':
            if( !isinteger(val) || val<=0 || val>65535 ) {
               val=FTPDEF_PORT;
            }
            fo.fwport= (int) val;
            break;
         case 'fwuserid':
            fo.fwuserid=val;
            break;
         case 'fwpassword':
            fo.fwpassword=val;
            break;
         case 'fwtype':
            if( !isinteger(val) || val<FTPOPT_FWTYPE_USERAT || val>FTPOPT_FWTYPE_USERLOGON ) {
               val=FTPOPT_FWTYPE_USERAT;
            }
            fo.fwtype= (int)val;
            break;
         case 'fwpasv':
            fo.fwpasv= (isinteger(val) && val);
            break;
         case 'fwenable':
            fo.fwenable=(isinteger(val) && val);
            break;
         case 'sshexe':
            fo.sshexe=val;
            break;
         case 'sshsubsystem':
            fo.sshsubsystem=val;
            break;
         default:
            // Should never get here, but will allow it
            break;
         }
      }
   }
   _delete_temp_view(temp_view_id);
   p_window_id=orig_view_id;

   return(0);
}

int _ftpSaveOptions(FtpOptions *fo_p)
{
   int temp_view_id=0;
   int orig_view_id=_create_temp_view(temp_view_id);
   if( orig_view_id=="" ) {
      // Don't need to display error because _create_temp_view() already did
      return(1);
   }
   _delete_line();
   insert_line("email=":+fo_p->email);
   insert_line("deflocaldir=":+fo_p->deflocaldir);
   insert_line("put=":+fo_p->put);
   int val= (int)fo_p->resolvelinks;
   insert_line("resolvelinks=":+val);
   insert_line("timeout=":+fo_p->timeout);
   insert_line("port=":+fo_p->port);
   val= (int)fo_p->keepalive;
   insert_line("keepalive=":+val);
   insert_line("uploadcase=":+fo_p->uploadcase);
   insert_line("fwhost=":+fo_p->fwhost);
   insert_line("fwport=":+fo_p->fwport);
   insert_line("fwuserid=":+fo_p->fwuserid);
   insert_line("fwpassword=":+fo_p->fwpassword);   // Already encrypted
   insert_line("fwtype=":+fo_p->fwtype);
   val= (int)fo_p->fwpasv;
   insert_line("fwpasv=":+val);
   val= (int)fo_p->fwenable;
   insert_line("fwenable=":+val);
   insert_line("sshexe=":+fo_p->sshexe);
   insert_line("sshsubsystem=":+fo_p->sshsubsystem);
   insert_line("");   // Separate profile sections w/ blank line

   // FTPMaybeCreateUserIniFile() takes care of the error message
   if( FTPMaybeCreateUserIniFile()=="" ) return(1);

   p_window_id=orig_view_id;
   int status=_ini_put_section(FTPUserIniFilename(),"options",temp_view_id);
   p_window_id=orig_view_id;   // Just in case

   return(status);
}

/**
 * Parses the address string into host, port, and path.
 *
 * @param address a string of the form [ftp://] + hostname + [:port] + path
 * @param host    accepts the parsed hostname
 * @param port    accepts the parsed port (can be a port number or named service)
 * @param path    accepts the parsed path
 *
 * @return 0 if successful. Non-zero is returned for a badly formed address.
 */
int _ftpParseAddress(_str address,_str &host,_str &port,_str &path)
{
   _str rest='';
   parse address with '(ftp\://|)','r' rest;
   parse rest with host '/' +0 path;
   if( host=='' ) {
      return(SOCK_BAD_HOST_RC);
   }
   // 3/2/2007 - rb
   // Sorry, but literal IPv6 addresses have colons (':') in the address.
   // We never used the port part of the parsed host anyway, so just get rid
   // of it. We could support the port again if we changed to a bracketed
   // IPv6 literal [address]:port format, but I do not think that is warranted.
   //parse host with host ':' port;

   if( path=='' ) {
      path='.';
   }

   return(0);
}

/**
 * Translates a return code into a message string.
 *
 * @param retcode return code from either a macro call, vsockapi.dll, or the editor
 *
 * @return String representation of the return code retcode.
 */
_str _ftpGetMessage(int retcode)
{
   if( retcode < 0 ) {
      return( get_message(retcode) );
   } else if( retcode > 0 ) {
      switch( retcode ) {
      default:
         return("Unknown error");
      }
   }

   // retcode==0
   return("");
}

_str _ftpMkLogName()
{
   int maxtail=1000;
   int i,pad_len=length(maxtail-1);   // e.g. maxtail=10 gives us 0-9
   for( i=0;i<maxtail;++i ) {
      name := 'ftp'substr("",1,pad_len-length(i),"0"):+i'.log';
      if( buf_match(name,1,'HEB')=="" ) {
         return(name);
      }
   }

   return("");   // There are a lot of log buffers if this happens
}

/**
 * Find buffer with p_DocumentName matching exactly document_name.
 * p_buf_name of the matching document is returned on success, otherwise
 * "" is returned.
 */
_str _ftpDocMatch(_str document_name)
{
   _str buf_name="";
   int orig_buf_id=_mdi.p_child.p_buf_id;
   for(;;) {
      if( !(_mdi.p_child.p_buf_flags&VSBUFFLAG_HIDDEN) && _mdi.p_child.p_DocumentName:==document_name ) {
         // Found a match
         buf_name=_mdi.p_child.p_buf_name;
         break;
      }
      _mdi.p_child._next_buffer('HR');
      if( _mdi.p_child.p_buf_id==orig_buf_id ) break;
   }
   _mdi.p_child.p_buf_id=orig_buf_id;

   return(buf_name);
}

_str _ftpCreateLogBuffer()
{
   int status=0;

   _str log_name=_ftpMkLogName();
   if( log_name=="" ) {
      ftpDisplayError("Unable to create log");
      return("");
   }

   int orig_view_id=p_window_id;
   int temp_view_id;
   _create_temp_view(temp_view_id);
   p_buf_name=log_name;_delete_line();
   p_buf_flags=VSBUFFLAG_THROW_AWAY_CHANGES|VSBUFFLAG_HIDDEN;
   p_readonly_mode=true;
   p_window_id=orig_view_id;

   return(log_name);
}

void _ftpDeleteLogBuffer(FtpConnProfile *fcp_p)
{
   _str log_buf_name=fcp_p->logBufName;
   if( log_buf_name=="" ) return;
   _find_and_delete_temp_view(log_buf_name);
   fcp_p->logBufName="";
   return;
}

static int _ftpservertype_list:[] = {
    "FTP"      => FTPSERVERTYPE_FTP
   ,"SFTP/SSH" => FTPSERVERTYPE_SFTP
};

static int _sshauthtype_list:[] = {
   "Auto"        => SSHAUTHTYPE_AUTO
   ,"Keyboard-Interactive"   => SSHAUTHTYPE_KEYBOARD_INTERACTIVE
   ,"Password"   => SSHAUTHTYPE_PASSWORD
   ,"Public key" => SSHAUTHTYPE_PUBLICKEY
   ,"Host based" => SSHAUTHTYPE_HOSTBASED
};

static int _ftpos_list:[] = {
    "Auto"           => FTPSYST_AUTO
   ,"Hummingbird NT" => FTPSYST_HUMMINGBIRD
   ,"Microsoft NT"   => FTPSYST_WINNT
   ,"MACOS"          => FTPSYST_MACOS
   ,"MVS"            => FTPSYST_MVS
   ,"Netware"        => FTPSYST_NETWARE
   ,"OS/2"           => FTPSYST_OS2
   ,"OS/400"         => FTPSYST_OS400
   ,"UNIX"           => FTPSYST_UNIX
   ,"VM"             => FTPSYST_VM
   ,"VM/ESA"         => FTPSYST_VMESA
   ,"VMS"            => FTPSYST_VMS
   ,"VMS Multinet"   => FTPSYST_VMS_MULTINET
   ,"VOS"            => FTPSYST_VOS
   ,"VxWorks"        => FTPSYST_VXWORKS
};

#define FCPDATAP  _ctl_profile_sstab.p_user
#define FCPFLAGS  _ctl_ok.p_user
#define FCPUSERID _ctl_user.p_user
#define FCPPASS   _ctl_pass.p_user
#define FCPORIG_PROFILENAME _ctl_profile.p_user

_control _ctl_user;
_control _ctl_pass;

#define FCPTAB_GENERAL  (0)
#define FCPTAB_ADVANCED (1)

static boolean gchange_server_type=true;
static boolean gchange_auth_type=true;
static boolean gchange_server_port=true;
static int gchange_old_server_type= -1;

defeventtab _ftpCreateProfile_form;
static int oncreateGeneral()
{
   FtpConnProfile *fcpdata_p;

   fcpdata_p=FCPDATAP;

   _ctl_profile.p_text=fcpdata_p->profileName;
   FCPORIG_PROFILENAME=_ctl_profile.p_text;

   _ctl_host.p_text=fcpdata_p->host;

   // Fill the "Server type" list
   gchange_server_type=false;
   int type = fcpdata_p->serverType;
   _str type_name = "FTP";
   typeless i;
   for( i._makeempty();; ) {
      _ftpservertype_list._nextel(i);
      if( i._isempty() ) break;
      _ctl_server_type._lbadd_item(i);
      // Current server type for this connection profile
      if( _ftpservertype_list:[i]==type ) type_name=i;
   }
   _ctl_server_type._lbsort();
   _ctl_server_type._lbdeselect_all();
   _ctl_server_type._lbfind_and_select_item(type_name, '', true);
   gchange_server_type=true;
   // Used by _ctl_server_type.on_change()
   gchange_old_server_type=_ftpservertype_list:[type_name];

   // Fill the "Auth type" list
   gchange_auth_type=false;
   type=fcpdata_p->sshAuthType;
   type_name="Password";
   for( i._makeempty();; ) {
      _sshauthtype_list._nextel(i);
      if( i._isempty() ) break;
      ctl_auth_type._lbadd_item(i);
      // Current auth type for this connection profile
      if( _sshauthtype_list:[i]==type ) type_name=i;
   }
   ctl_auth_type._lbsort();
   ctl_auth_type._lbdeselect_all();
   ctl_auth_type._lbfind_and_select_item(type_name, '', true);
   gchange_auth_type=true;

   // Fill the "Host type" list
   type=fcpdata_p->system;
   type_name="Auto";
   for( i._makeempty();; ) {
      _ftpos_list._nextel(i);
      if( i._isempty() ) break;
      _ctl_host_type._lbadd_item(i);
      // Current host type for this connection profile
      if( _ftpos_list:[i]==type ) type_name=i;
   }
   _ctl_host_type._lbsort();
   _ctl_host_type._lbdeselect_all();
   _ctl_host_type._lbfind_and_select_item(type_name, '', true);

   _ctl_anonymous.p_value=(int)fcpdata_p->anonymous;

   if( !_ctl_anonymous.p_value ) _ctl_pass.p_Password=true;

   _ctl_user.p_text=fcpdata_p->userId;

   int status=0;
   typeless plain='';
   if( fcpdata_p->password!="" ) {
      if( _ctl_pass.p_Password ) {
         _str pass=fcpdata_p->password;
         status=vssDecrypt(fcpdata_p->password,plain);
         if( !status ) {
            _ctl_pass.p_text=plain;
            plain="";
         } else {
            _ctl_pass.p_text="";
            ftpDisplayError("Error retrieving password");
         }
      } else {
         _ctl_pass.p_text=fcpdata_p->password;
      }
   } else {
      _ctl_pass.p_text="";
   }

   _ctl_remotedir.p_text=fcpdata_p->defRemoteDir;

   _ctl_localdir.p_text=fcpdata_p->defLocalDir;

   _ctl_remotefilter.p_text=fcpdata_p->remoteFileFilter;

   _ctl_localfilter.p_text=fcpdata_p->localFileFilter;

   _ctl_xfer_ascii.p_value=_ctl_xfer_binary.p_value=0;
   FtpXferType xfer_type = fcpdata_p->xferType;
   if( !isinteger((int)xfer_type) || xfer_type<FTPXFER_ASCII || xfer_type>FTPXFER_BINARY ) {
      xfer_type=FTPXFER_BINARY;
   }
   switch( xfer_type ) {
   case FTPXFER_ASCII:
      _ctl_xfer_ascii.p_value=1;
      break;
   case FTPXFER_BINARY:
      _ctl_xfer_binary.p_value=1;
      break;
   }

   _ctl_savepass.p_value=(int)fcpdata_p->savePassword;

   FCPUSERID="";
   FCPPASS="";

   return(0);
}

static int oncreateAdvanced()
{
   FtpConnProfile *fcpdata_p;

   fcpdata_p=FCPDATAP;

   _ctl_timeout.p_text=fcpdata_p->timeout;

   int port=fcpdata_p->port;
   if( !isinteger(port) || port<=0 || port>65535 ) {
      // This should never happen
      port=FTPDEF_PORT;
      if( fcpdata_p->serverType==FTPSERVERTYPE_SFTP ) {
         port=SFTPDEF_PORT;
      }
   }
   _ctl_port.p_text=port;

   _ctl_keepalive.p_value= (int)fcpdata_p->keepAlive;

   _ctl_use_fw.p_value= (int)fcpdata_p->useFirewall;
   _ctl_use_fw.p_enabled=fcpdata_p->global_options.fwenable;

   _ctl_uploadcase_preserve.p_value=_ctl_uploadcase_lower.p_value=_ctl_uploadcase_upper.p_value=0;
   int option=fcpdata_p->uploadCase;
   if( !isinteger(option) || option<FTPFILECASE_PRESERVE || option>FTPFILECASE_UPPER ) {
      option=FTPFILECASE_PRESERVE;
   }
   switch( option ) {
   case FTPFILECASE_PRESERVE:
      _ctl_uploadcase_preserve.p_value=1;
      break;
   case FTPFILECASE_LOWER:
      _ctl_uploadcase_lower.p_value=1;
      break;
   case FTPFILECASE_UPPER:
      _ctl_uploadcase_upper.p_value=1;
      break;
   }

   _ctl_resolve_links.p_value= (int)fcpdata_p->resolveLinks;

   _ctl_autorefresh.p_value= (int)fcpdata_p->autoRefresh;

   _ctl_remote_root.p_text=fcpdata_p->remoteRoot;
   _ctl_local_root.p_text=fcpdata_p->localRoot;

   return(0);
}

void _ctl_ok.on_create(FtpConnProfile *fcp_p=null, int flags=0, _str caption="")
{
   FCPDATAP=fcp_p;
   FCPFLAGS=flags;
   if( caption=="" ) {
      caption="Add FTP Profile";
   }

   // Login dialog OR profile creation?
   if( FCPFLAGS&FCPFLAG_LOGIN ) {
      caption="Login";
   } else if( FCPFLAGS&FCPFLAG_EDIT ) {
      caption="Edit FTP Profile";
   }
   p_active_form.p_caption=caption;

   // Allow user to save profile settings?
   if( FCPFLAGS&FCPFLAG_SAVEPROFILEOFF ) {
      _ctl_saveprofile.p_value=0;
   } else {
      _ctl_saveprofile.p_value=1;
   }

   // Hide the "Save profile" checkbox?
   if( FCPFLAGS&FCPFLAG_HIDESAVEPROFILE ) {
      _ctl_saveprofile.p_visible=false;
   } else {
      _ctl_saveprofile.p_visible=true;
   }

   // Disable the "Profile name" text box?
   if( FCPFLAGS&FCPFLAG_DISABLEPROFILE ) {
      _ctl_profile.p_enabled=false;
   }

   if( oncreateGeneral() ) {
      p_active_form._delete_window(1);
      return;
   }
   if( oncreateAdvanced() ) {
      p_active_form._delete_window(1);
      return;
   }
   // We only want to change the port number when the user actually
   // changes the server type by clicking on the "Server type" combo
   // box.
   gchange_server_port=false;
   _ctl_server_type.call_event(CHANGE_SELECTED,_ctl_server_type,ON_CHANGE,'W');
   ctl_auth_type.call_event(CHANGE_SELECTED,ctl_auth_type,ON_CHANGE,'W');
   gchange_server_port=true;

   return;
}

void _ftpCreateProfile_form.on_load()
{
   _str type_name=_ctl_server_type.p_text;
   int type=_ftpservertype_list:[type_name];

   if( _ctl_profile.p_text=="" ) {
      p_window_id=_ctl_profile;
      _set_focus();
   } else if( type!=FTPSERVERTYPE_SFTP && _ctl_host.p_text=="" ) {
      p_window_id=_ctl_host;
      _set_focus();
   } else if( _ctl_user.p_text!="" ) {
      p_window_id=_ctl_pass;
      _set_focus();
   } else {
      p_window_id=_ctl_user;
      _set_focus();
   }

   return;
}

static int GetGeneralOptions(FtpConnProfile *fcp_p)
{
   _str profile=_ctl_profile.p_text;
   if( profile=="" ) {
      _ctl_profile_sstab.p_ActiveTab=FCPTAB_GENERAL;
      p_window_id=_ctl_profile;
      _set_focus();
      _message_box('Must have a profile name!','',MB_OK|MB_ICONEXCLAMATION);
      return(1);
      //profile=strip(_ctl_host.p_text);
   }

   _str host=strip(_ctl_host.p_text);
   if( host=="" ) {
      _ctl_profile_sstab.p_ActiveTab=FCPTAB_GENERAL;
      p_window_id=_ctl_host;
      _set_focus();
      _message_box('Must have a host!','',MB_OK|MB_ICONEXCLAMATION);
      return(1);
   }

   _str server_type=strip(_ctl_server_type.p_text);
   if( server_type=="" ) {
      _ctl_profile_sstab.p_ActiveTab=FCPTAB_GENERAL;
      p_window_id=_ctl_server_type;
      _set_focus();
      _message_box('Must have a server type!','',MB_OK|MB_ICONEXCLAMATION);
      return(1);
   } else if( !_ftpservertype_list._indexin(server_type) ) {
      // This should never happen
      _message_box('Server type not in list. Resetting to "FTP"','',MB_OK|MB_ICONEXCLAMATION);
      p_window_id=_ctl_server_type;
      _set_focus();
      _ctl_server_type.p_text="FTP";
      return(1);
   }

   _str auth_type = strip(ctl_auth_type.p_text);
   if( auth_type=="" ) {
      _ctl_profile_sstab.p_ActiveTab=FCPTAB_GENERAL;
      p_window_id=ctl_auth_type;
      _set_focus();
      _message_box('Must have an auth type!','',MB_OK|MB_ICONEXCLAMATION);
      return(1);
   } else if( 0 == _sshauthtype_list._indexin(auth_type) ) {
      // This should never happen
      _message_box('Auth type not in list. Resetting to "Password"','',MB_OK|MB_ICONEXCLAMATION);
      p_window_id=ctl_auth_type;
      _set_focus();
      ctl_auth_type.p_text="Password";
      return(1);
   }

   _str host_type=strip(_ctl_host_type.p_text);
   if( host_type=="" ) {
      _ctl_profile_sstab.p_ActiveTab=FCPTAB_GENERAL;
      p_window_id=_ctl_host_type;
      _set_focus();
      _message_box('Must have a host type!','',MB_OK|MB_ICONEXCLAMATION);
      return(1);
   } else if( !_ftpos_list._indexin(host_type) ) {
      // This should never happen
      _message_box('Host type not in list. Resetting to "Auto"','',MB_OK|MB_ICONEXCLAMATION);
      p_window_id=_ctl_host_type;
      _set_focus();
      _ctl_host_type.p_text="Auto";
      return(1);
   }

   _str user=strip(_ctl_user.p_text);
   if( user=='' ) {
      _ctl_profile_sstab.p_ActiveTab=FCPTAB_GENERAL;
      p_window_id=_ctl_user;
      _set_focus();
      _message_box('Must have a user ID!','',MB_OK|MB_ICONEXCLAMATION);
      return(1);
   }

   typeless cipher='';
   _str pass=_ctl_pass.p_text;
   if( _ctl_pass.p_Password ) {
      // Encrypt it
      if( !vssEncrypt(pass,cipher) ) {
         pass=cipher;
      } else {
         _message_box("Error saving password",'',MB_OK|MB_ICONEXCLAMATION);
         pass="";
      }
   }

   _str remotedir=_ctl_remotedir.p_text;

   _str localdir=_ctl_localdir.p_text;

   _str remotefilter=_ctl_remotefilter.p_text;

   _str localfilter=_ctl_localfilter.p_text;

   FtpXferType xfer_type = 0;
   if( _ctl_xfer_ascii.p_value ) {
      xfer_type = FTPXFER_ASCII;
   } else if( _ctl_xfer_binary.p_value ) {
      xfer_type = FTPXFER_BINARY;
   } else {
      // This should never happen
      _ctl_profile_sstab.p_ActiveTab=FCPTAB_GENERAL;
      p_window_id=_ctl_user;
      _set_focus();
      _message_box("Must choose a transfer type!",'',MB_OK|MB_ICONEXCLAMATION);
      return(1);
   }

   typeless anonymous=_ctl_anonymous.p_value;

   typeless savepass=_ctl_savepass.p_value;

   fcp_p->profileName=profile;
   fcp_p->host=host;
   fcp_p->serverType=_ftpservertype_list:[server_type];
   fcp_p->sshAuthType=_sshauthtype_list:[auth_type];
   fcp_p->system=_ftpos_list:[host_type];
   fcp_p->userId=user;
   fcp_p->password=pass;
   fcp_p->anonymous=anonymous;
   fcp_p->savePassword=savepass;
   fcp_p->defRemoteDir=remotedir;
   fcp_p->defLocalDir=localdir;
   fcp_p->remoteFileFilter=remotefilter;
   fcp_p->localFileFilter=localfilter;
   fcp_p->xferType=xfer_type;

   return(0);
}

static int onokGeneral()
{
   int status;

   status=GetGeneralOptions(FCPDATAP);

   return(status);
}

static int GetAdvancedOptions(FtpConnProfile *fcp_p)
{
   int status=0;
   typeless timeout=_ctl_timeout.p_text;
   if( !isinteger(timeout) || timeout<1 ) {
      _ctl_profile_sstab.p_ActiveTab=FCPTAB_ADVANCED;
      p_window_id=_ctl_timeout;
      _set_sel(1,length(p_text)+1);
      _set_focus();
      _message_box("Timeout must be a positive integer value",'',MB_OK|MB_ICONEXCLAMATION);
      return(1);
   }

   typeless port=_ctl_port.p_text;
   if( !isinteger(port) || port<1 ) {
      _ctl_profile_sstab.p_ActiveTab=FCPTAB_ADVANCED;
      p_window_id=_ctl_port;
      _set_sel(1,length(p_text)+1);
      _set_focus();
      _message_box("Port must be a positive integer value",'',MB_OK|MB_ICONEXCLAMATION);
      return(1);
   }

   typeless keepalive=_ctl_keepalive.p_value;

   boolean usefw= (_ctl_use_fw.p_value && _ctl_use_fw.p_enabled);

   int uploadcase=0;
   if( _ctl_uploadcase_preserve.p_value ) {
      uploadcase=FTPFILECASE_PRESERVE;
   } else if( _ctl_uploadcase_lower.p_value ) {
      uploadcase=FTPFILECASE_LOWER;
   } else if( _ctl_uploadcase_upper.p_value ) {
      uploadcase=FTPFILECASE_UPPER;
   } else {
      _ctl_profile_sstab.p_ActiveTab=FCPTAB_ADVANCED;
      p_window_id=_ctl_uploadcase_preserve;
      _set_focus();
      _message_box("You must decide how your files will be cased when uploaded!",'',MB_OK|MB_ICONEXCLAMATION);
      return(1);
   }

   typeless resolvelinks=_ctl_resolve_links.p_value;

   typeless autorefresh=_ctl_autorefresh.p_value;

   typeless remoteroot=strip(_ctl_remote_root.p_text);
   if( remoteroot!="" ) {
      /* Doing this check relies on the assumption that GetGeneralOptions()
       * was called first, so that fcp_p->System is set.
       */
      boolean isdir=false;
      switch( fcp_p->system ) {
      case FTPSYST_VMS:
      case FTPSYST_VMS_MULTINET:
         if( pos('^[~\[]@\:\[?@\]$',remoteroot,1,'r') ) {
            isdir=true;
         }
         break;
      case FTPSYST_VOS:
         if( pos('^[~\>]@\>',remoteroot,1,'r') ) {
            isdir=true;
         }
         break;
      case FTPSYST_VM:
      case FTPSYST_VMESA:
         // VM uses CMS minidisks
         if( pos('^[~\.]#(\.[~\.]#|)',remoteroot,1,'er') ) {
            isdir=true;
         }
         break;
      case FTPSYST_MVS:
         if( substr(remoteroot,1,1)=='/' ) {
            // HFS file system which mimics Unix
            if( substr(remoteroot,1,1)=='/' ) {
               isdir=true;
            }
         } else {
            // PDS format
            if( pos('^[~\.]#(\.[~\.]#)@$',remoteroot,1,'r') ) {
               isdir=true;
            }
         }
         break;
      case FTPSYST_OS2:
         // OS/2 is flexible about file separators. Both '/' and '\' are allowed
         remoteroot=translate(remoteroot,'/','\');
         if( pos('^[a-zA-Z]\:/$',substr(remoteroot,1,3),1,'er') ) {
            isdir=true;
         }
         break;
      case FTPSYST_OS400:
         if( substr(remoteroot,1,1)=='/' ) {
            // IFS file system which mimics Unix
            if( substr(remoteroot,1,1)=='/' ) {
               isdir=true;
            }
         } else {
            // LFS format
            if( pos('^[~/.]#$',remoteroot,1,'r') ) {
               isdir=true;
            }
         }
         break;
      case FTPSYST_WINNT:
      case FTPSYST_HUMMINGBIRD:
         if( substr(remoteroot,1,1)=='/' ) {
            // Unix style
            if( substr(remoteroot,1,1)=='/' ) {
               isdir=true;
            }
         } else {
            // DOS style
            if( pos('^[a-zA-Z]\:\\',substr(remoteroot,1,3),1,'er') ) {
               isdir=true;
            }
         }
         break;
      case FTPSYST_NETWARE:
      case FTPSYST_UNIX:
      default:
         if( substr(remoteroot,1,1)=='/' ) {
            isdir=true;
         }
      }
      if( !isdir ) {
         // Warn the user
         _str msg='The remote root path under "Remote to local directory mapping" ':+
             "does not appear to be an absolute path.\n\n":+
             'This warning can come up if you have chosen "Auto" for the "Host type"':+
             "when you will be connecting to a non-UNIX host (i.e. VM, MVS, OS/400, etc.).\n\n":+
             "Would you like to keep this setting?";
         status=_message_box(msg,'',MB_YESNO|MB_ICONEXCLAMATION);
         if( status!=IDYES ) {
            _ctl_profile_sstab.p_ActiveTab=FCPTAB_ADVANCED;
            p_window_id=_ctl_remote_root;
            _set_sel(1,length(p_text)+1);
            _set_focus();
            return(1);
         }
      }
   }
   _str localroot=strip(_ctl_local_root.p_text);
   if( localroot!="" ) {
      #if __UNIX__
      if( substr(localroot,1,1)!=FILESEP ) {
         _ctl_profile_sstab.p_ActiveTab=FCPTAB_ADVANCED;
         p_window_id=_ctl_local_root;
         _set_sel(1,length(p_text)+1);
         _set_focus();
         _str msg="You must specify an absolute local path or leave blank!\n\nExample: /my-www-dir/";
         _message_box(msg,'',MB_OK|MB_ICONEXCLAMATION);
         return(1);
      }
      #else
      _str drive=substr(localroot,1,2);
      if( !isdrive(drive) && drive!='\\' ) {
         _ctl_profile_sstab.p_ActiveTab=FCPTAB_ADVANCED;
         p_window_id=_ctl_local_root;
         _set_sel(1,length(p_text)+1);
         _set_focus();
         _str msg="You must specify an absolute local path or leave blank!\n\nExample: c:\\webdir\\";
         _message_box(msg,'',MB_OK|MB_ICONEXCLAMATION);
         return(1);
      }
      #endif
   }

   fcp_p->timeout=timeout;
   fcp_p->port=port;
   fcp_p->keepAlive= (keepalive!=0);
   fcp_p->useFirewall= (usefw!=0);
   fcp_p->uploadCase=uploadcase;
   fcp_p->resolveLinks= (resolvelinks!=0);
   fcp_p->autoRefresh= (autorefresh!=0);
   fcp_p->remoteRoot=remoteroot;
   fcp_p->localRoot=localroot;

   return(0);
}

static int onokAdvanced()
{
   int status;

   status=GetAdvancedOptions(FCPDATAP);

   return(status);
}

void _ctl_ok.lbutton_up()
{
   FtpConnProfile *fcpdata_p;
   FtpConnProfile save_fcp;

   fcpdata_p=FCPDATAP;

   if( onokGeneral() ) return;
   if( onokAdvanced() ) return;

   int status=0;
   if( (_ctl_saveprofile.p_visible && _ctl_saveprofile.p_value) ||
       !(FCPFLAGS&FCPFLAG_NOSAVEPROFILE) ) {
      if( FCPORIG_PROFILENAME!=fcpdata_p->profileName &&
          _ftpIsConnProfile(fcpdata_p->profileName) ) {
         // Saving to a new name that already exists
         status=_message_box('Profile "':+fcpdata_p->profileName:+'" already exists':+
                      "\n\nOverwrite?",'',MB_YESNO|MB_ICONQUESTION);
         if( status!=IDYES ) {
            p_window_id=_ctl_profile;
            _set_sel(1,length(p_text)+1);
            _set_focus();
            return;
         }
      }
      save_fcp= *fcpdata_p;
      if( !save_fcp.savePassword ) {
         // If the user did not want to save password then don't. But we still
         // want to pass it back in case the caller needs it for some reason.
         save_fcp.password="";
      }
      status=_ftpSaveConnProfile(&save_fcp);
      if( status ) {
         _message_box("Unable to save connection profile",'',MB_OK|MB_ICONEXCLAMATION);
         return;
      }
   }
   p_active_form._delete_window(0);

   return;
}

void _ctl_server_type.on_change(int reason)
{
   if( !gchange_server_type ) {
      return;
   }

   _str type_name = _ctl_server_type.p_text;
   int type = _ftpservertype_list:[type_name];
   boolean enabled = ( type==FTPSERVERTYPE_FTP );

   //
   // General tab
   //

   // 'Password' is the only authentication type allowed for FTP, so
   // disable the "Auth type" combo if FTP.
   ctl_auth_type.p_enabled= !enabled;
   _ctl_host_type.p_enabled=enabled;
   _ctl_transfer_type_frame.p_enabled=enabled;
   _ctl_xfer_ascii.p_enabled=enabled;
   _ctl_xfer_binary.p_enabled=enabled;

   // Advanced tab
   _ctl_keepalive.p_enabled=enabled;
   _ctl_resolve_links.p_enabled=enabled;
   _ctl_use_fw.p_enabled=enabled;
   if( gchange_server_port ) {
      // Did the user select the same type as was there from the list box?
      // If so, then do not change the port value.
      if( gchange_old_server_type!=type ) {
         _str port=FTPDEF_PORT;
         if( type==FTPSERVERTYPE_SFTP ) {
            port=SFTPDEF_PORT;
         }
         _ctl_port.p_text=port;
         gchange_old_server_type=type;
      }
   }

   return;
}

void ctl_auth_type.on_change(int reason)
{
   if( !gchange_auth_type ) {
      return;
   }

   _str type_name = _ctl_server_type.p_text;
   int type = _ftpservertype_list:[type_name];
   if( type==FTPSERVERTYPE_FTP ) {
      // How did we get here?
      // This combo should only be enabled for SFTP!
      return;
   }
}

void _ctl_anonymous.lbutton_up()
{
   FtpConnProfile *fcpdata_p;

   fcpdata_p=FCPDATAP;

   if( p_value ) {
      FCPUSERID=strip(_ctl_user.p_text);
      _ctl_user.p_text=FTPDEF_ANONYMOUS_USERID;
      _ctl_pass.p_Password=false;
      _str pass=fcpdata_p->global_options.email;
      if( pass=="" ) {
         pass=FTPDEF_ANONYMOUS_PASS;
      }
      _ctl_pass.p_text=pass;
   } else {
      if( FCPUSERID!=FTPDEF_ANONYMOUS_USERID ) {
         // Do not want to revert to previous userid if the user put a
         // userid in other than "anonymous".
         _ctl_user.p_text=FCPUSERID;
      } else {
         _ctl_user.p_text=FTPDEF_ANONYMOUS_USERID;
      }
      _ctl_pass.p_Password=true;
   }
   // Put the focus on the Password field if it is blank
   if( _ctl_pass.p_text=="" ) {
      p_window_id=_ctl_pass;
      _set_focus();
      _set_sel(1,length(p_text));
   }
}

void _ctl_cancel.lbutton_up()
{
   p_active_form._delete_window('');
}

#define FTPOPTIONSTAB_GENERAL  (0)
#define FTPOPTIONSTAB_ADVANCED (1)
#define FTPOPTIONSTAB_FIREWALL (2)
#define FTPOPTIONSTAB_SSH      (3)
#define FTPOPTIONSTAB_DEBUG    (4)
defeventtab _ftpOptions_form;

#region Options Dialog Helper Functions

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _ftpOptions_form_initial_alignment()
{
   tabWidth := _ctl_options_sstab.p_child.p_width;
   sizeBrowseButtonToTextBox(_ctl_ssh_exe.p_window_id, _ctl_browse_ssh_exe.p_window_id, 0, tabWidth - 120);
}

void _ftpOptions_form_init_for_options()
{
   _ctl_ok.p_visible = false;
   _ctl_cancel.p_visible = false;
   _ctl_help.p_visible = false;
}

boolean _ftpOptions_form_apply()
{
   FtpOptions fo;

   if( onokGeneralOptions(&fo) ) return false;
   if( onokAdvancedOptions(&fo) ) return false;
   if( onokFirewallOptions(&fo) ) return false;
   if( onokSSHOptions(&fo) ) return false;
   if( onokDebugOptions(&fo) ) return false;

   if( _ftpSaveOptions(&fo) ) return false;

   return true;
}

#endregion Options Dialog Helper Functions

static int oncreateGeneralOptions(FtpOptions *fo_p)
{
   _ctl_anon_email.p_text=fo_p->email;

   _ctl_deflocaldir.p_text=fo_p->deflocaldir;

   _ctl_put_option1.p_value=_ctl_put_option2.p_value=_ctl_put_option3.p_value=0;
   int option=fo_p->put;
   if( !isinteger(option) || option<FTPOPT_EXPLICIT_PUT || option>FTPOPT_ALWAYS_PUT ) {
      option=FTPOPT_PROMPTED_PUT;
   }
   switch( option ) {
   case FTPOPT_EXPLICIT_PUT:
      _ctl_put_option1.p_value=1;
      break;
   case FTPOPT_PROMPTED_PUT:
      _ctl_put_option2.p_value=1;
      break;
   case FTPOPT_ALWAYS_PUT:
      _ctl_put_option3.p_value=1;
      break;
   }

   _ctl_resolve_links.p_value= (int)fo_p->resolvelinks;

   return(0);
}

static int oncreateAdvancedOptions(FtpOptions *fo_p)
{
   int timeout=fo_p->timeout;
   if( !isinteger(timeout) || timeout<=0 ) {
      timeout=FTPDEF_TIMEOUT;
   }
   _ctl_timeout.p_text=timeout;

   int port=fo_p->port;
   if( !isinteger(port) || port<=0 || port>65535 ) {
      port=FTPDEF_PORT;
   }
   _ctl_port.p_text=port;

   _ctl_keepalive.p_value= (int)fo_p->keepalive;

   _ctl_uploadcase_preserve.p_value=_ctl_uploadcase_lower.p_value=_ctl_uploadcase_upper.p_value=0;
   int option=fo_p->uploadcase;
   if( !isinteger(option) || option<FTPFILECASE_PRESERVE || option>FTPFILECASE_UPPER ) {
      option=FTPFILECASE_PRESERVE;
   }
   switch( option ) {
   case FTPFILECASE_PRESERVE:
      _ctl_uploadcase_preserve.p_value=1;
      break;
   case FTPFILECASE_LOWER:
      _ctl_uploadcase_lower.p_value=1;
      break;
   case FTPFILECASE_UPPER:
      _ctl_uploadcase_upper.p_value=1;
      break;
   }

   return(0);
}

static int oncreateFirewallOptions(FtpOptions *fo_p)
{
   boolean require_host,require_port,require_user,require_pass;

   _ctl_pasv.p_value= (int)fo_p->fwpasv;
   _ctl_pasv.p_user=_ctl_pasv.p_value;
   _ctl_fw_type1.p_value=_ctl_fw_type2.p_value=_ctl_fw_type3.p_value=0;
   int type=fo_p->fwtype;
   if( !isinteger(type) || type<FTPOPT_FWTYPE_USERAT || type>FTPOPT_FWTYPE_USERLOGON ) {
      type=FTPOPT_FWTYPE_USERAT;
   }
   switch( type ) {
   case FTPOPT_FWTYPE_USERAT:
      _ctl_fw_type1.p_value=1;
      break;
   case FTPOPT_FWTYPE_OPEN:
      _ctl_fw_type2.p_value=1;
      break;
   case FTPOPT_FWTYPE_USERLOGON:
      _ctl_fw_type3.p_value=1;
      break;
   case FTPOPT_FWTYPE_ROUTER:
      _ctl_fw_type4.p_value=1;
      break;
   }

   _ctl_fw_host.p_text=fo_p->fwhost;

   int port=fo_p->fwport;
   if( !isinteger(port) || port<=0 || port >65535 ) {
      port=FTPDEF_PORT;
   }
   _ctl_fw_port.p_text=port;

   _ctl_fw_user.p_text=fo_p->fwuserid;

   int status=0;
   _ctl_fw_pass.p_Password=true;
   _str plain="";
   _str cipher=fo_p->fwpassword;
   if( cipher!="" ) {
      status=vssDecrypt(cipher,plain);
      if( status ) {
         _message_box("Error retrieving password",'',MB_OK|MB_ICONEXCLAMATION);
      }
   }
   _ctl_fw_pass.p_text=plain;

   _ctl_enable_fw.p_value= (int)fo_p->fwenable;
   _ctl_enable_fw.call_event(_ctl_enable_fw,LBUTTON_UP,'W');

   return(0);
}

static int oncreateSSHOptions(FtpOptions *fo_p)
{
   _ctl_ssh_exe.p_text=fo_p->sshexe;

   _ctl_ssh_subsystem.p_text=fo_p->sshsubsystem;

   return(0);
}

static int oncreateDebugOptions(FtpOptions *fo_p)
{
   if( _ftpdebug&FTPDEBUG_LOG_PROXY ) {
      _ctl_log_proxy.p_value=1;
   }
   if( _ftpdebug&FTPDEBUG_SSH_VERBOSE ) {
      _ctl_ssh_verbose.p_value=1;
   }
   if( _ftpdebug&FTPDEBUG_SAY_EVENTS ) {
      _ctl_say_events.p_value=1;
   }
   if( _ftpdebug&FTPDEBUG_SAVE_LOG ) {
      _ctl_save_log.p_value=1;
   }
   if( _ftpdebug&FTPDEBUG_TIME_STAMP ) {
      _ctl_time_stamp.p_value=1;
   }
   if( _ftpdebug&FTPDEBUG_SAVE_LIST ) {
      _ctl_save_list.p_value=1;
   }
   if( _ftpdebug&FTPDEBUG_VSPROXY ) {
      _ctl_vsproxy.p_value=1;
   }

   return(0);
}

int _ctl_ok.on_create()
{
   FtpOptions fo;

   if( _ftpGetOptions(fo) ) return(1);
   if( oncreateGeneralOptions(&fo) ) return(1);
   if( oncreateAdvancedOptions(&fo) ) return(1);
   if( oncreateFirewallOptions(&fo) ) return(1);
   if( oncreateSSHOptions(&fo) ) return(1);
   if( oncreateDebugOptions(&fo) ) return(1);

   _ftpOptions_form_initial_alignment();

   return(0);
}

static int onokGeneralOptions(FtpOptions *fo_p)
{
   fo_p->email=_ctl_anon_email.p_text;

   fo_p->deflocaldir=_ctl_deflocaldir.p_text;

   int option=0;
   if( _ctl_put_option1.p_value ) {
      option=FTPOPT_EXPLICIT_PUT;
   } else if( _ctl_put_option2.p_value ) {
      option=FTPOPT_PROMPTED_PUT;
   } else if( _ctl_put_option3.p_value ) {
      option=FTPOPT_ALWAYS_PUT;
   } else {
      _ctl_options_sstab.p_ActiveTab=FTPOPTIONSTAB_GENERAL;
      p_window_id=_ctl_put_option1;
      _set_focus();
      _message_box("You must decide how your files will be uploaded on save!",'',MB_OK|MB_ICONEXCLAMATION);
      return(1);
   }
   fo_p->put=option;

   fo_p->resolvelinks= (_ctl_resolve_links.p_value!=0);

   return(0);
}

static int onokAdvancedOptions(FtpOptions *fo_p)
{
   typeless timeout=_ctl_timeout.p_text;
   if( !isinteger(timeout) || timeout<=0 ) {
      _ctl_options_sstab.p_ActiveTab=FTPOPTIONSTAB_ADVANCED;
      p_window_id=_ctl_timeout;
      _set_sel(1,length(p_text)+1);
      _set_focus();
      _message_box("Timeout must be a positive integer greater than 0",'',MB_OK|MB_ICONEXCLAMATION);
      return(1);
   }
   fo_p->timeout=timeout;

   typeless port=_ctl_port.p_text;
   if( !isinteger(port) || port<=0 || port>65535 ) {
      _ctl_options_sstab.p_ActiveTab=FTPOPTIONSTAB_ADVANCED;
      p_window_id=_ctl_port;
      _set_sel(1,length(p_text)+1);
      _set_focus();
      _message_box("Port must be in the range 1-65535",'',MB_OK|MB_ICONEXCLAMATION);
      return(1);
   }
   fo_p->port=port;

   fo_p->keepalive= (_ctl_keepalive.p_value!=0);

   int option=0;
   if( _ctl_uploadcase_preserve.p_value ) {
      option=FTPFILECASE_PRESERVE;
   } else if( _ctl_uploadcase_lower.p_value ) {
      option=FTPFILECASE_LOWER;
   } else if( _ctl_uploadcase_upper.p_value ) {
      option=FTPFILECASE_UPPER;
   } else {
      _ctl_options_sstab.p_ActiveTab=FTPOPTIONSTAB_ADVANCED;
      p_window_id=_ctl_uploadcase_preserve;
      _set_focus();
      _message_box("You must decide how your files will be cased when uploaded!",'',MB_OK|MB_ICONEXCLAMATION);
      return(1);
   }
   fo_p->uploadcase=option;

   return(0);
}

static int onokFirewallOptions(FtpOptions *fo_p)
{
   fo_p->fwenable= (_ctl_enable_fw.p_value!=0);

   boolean require_host=true;
   boolean require_port=true;
   boolean require_user=false;
   boolean require_pass=false;
   int type=0;
   if( _ctl_fw_type1.p_value ) {
      type=FTPOPT_FWTYPE_USERAT;
   } else if( _ctl_fw_type2.p_value ) {
      type=FTPOPT_FWTYPE_OPEN;
   } else if( _ctl_fw_type3.p_value ) {
      type=FTPOPT_FWTYPE_USERLOGON;
      //require_user=true;
      //require_pass=true;
   } else if( _ctl_fw_type4.p_value ) {
      type=FTPOPT_FWTYPE_ROUTER;
      require_host=false;
      require_port=false;
   } else {
      if( fo_p->fwenable ) {
         // Firewall/proxy is enabled, so this has to be correct
         _ctl_options_sstab.p_ActiveTab=FTPOPTIONSTAB_FIREWALL;
         p_window_id=_ctl_fw_type1;
         _set_focus();
         _message_box("You must choose the type of firewall/proxy!",'',MB_OK|MB_ICONEXCLAMATION);
         return(1);
      } else {
         // Firewall/proxy is not enabled, so just set the value to a default
         type=FTPOPT_FWTYPE_USERAT;
      }
   }
   fo_p->fwtype=type;

   _str host=_ctl_fw_host.p_text;
   if( fo_p->fwenable && require_host && host=="" ) {
      // Firewall/proxy is enabled, so this has to be correct
      _ctl_options_sstab.p_ActiveTab=FTPOPTIONSTAB_FIREWALL;
      p_window_id=_ctl_fw_host;
      _set_focus();
      _message_box("This firewall/proxy type requires a host!",'',MB_OK|MB_ICONEXCLAMATION);
      return(1);
   }
   fo_p->fwhost=host;

   typeless port=_ctl_fw_port.p_text;
   if( !isinteger(port) || port<=0 || port>65535 ) {
      if( fo_p->fwenable && require_port ) {
         // Firewall/proxy is enabled, so this has to be correct
         _ctl_options_sstab.p_ActiveTab=FTPOPTIONSTAB_FIREWALL;
         p_window_id=_ctl_port;
         _set_sel(1,length(p_text)+1);
         _set_focus();
         _message_box("Port must be in the range 1-65535",'',MB_OK|MB_ICONEXCLAMATION);
         return(1);
      } else {
         // Firewall/proxy is not enabled, so just set the value to a default
         port=FTPDEF_PORT;
      }
   }
   fo_p->fwport=port;

   _str user=_ctl_fw_user.p_text;
   if( fo_p->fwenable && require_user && user=="" ) {
      // Firewall/proxy is enabled, so this has to be correct
      _ctl_options_sstab.p_ActiveTab=FTPOPTIONSTAB_FIREWALL;
      p_window_id=_ctl_fw_user;
      _set_focus();
      _message_box("This firewall/proxy type requires a user id!",'',MB_OK|MB_ICONEXCLAMATION);
      return(1);
   }
   fo_p->fwuserid=user;

   int status=0;
   _str cipher="";
   _str plain=_ctl_fw_pass.p_text;
   if( plain!="" ) {
      status=vssEncrypt(plain,cipher);
      if( status ) {
         _message_box("Error saving firewall/proxy password",'',MB_OK|MB_ICONEXCLAMATION);
         if( fo_p->fwenable ) {
            // Firewall/proxy is enabled, so this is serious
            return(1);
         }
      }
   }
   fo_p->fwpassword=cipher;

   if( fo_p->fwtype==FTPOPT_FWTYPE_ROUTER ) {
      // Router firewalls ALWAYS use passive transfers
      fo_p->fwpasv=true;
   } else {
      fo_p->fwpasv= (_ctl_pasv.p_value!=0);
   }

   return(0);
}

static int onokSSHOptions(FtpOptions *fo_p)
{
   int status=0;
   _str sshexe=_ctl_ssh_exe.p_text;
   if( sshexe!="" && file_match('-p 'sshexe,1)=="" ) {
      _ctl_options_sstab.p_ActiveTab=FTPOPTIONSTAB_SSH;
      p_window_id=_ctl_ssh_exe;
      _set_sel(1,length(p_text)+1);
      _set_focus();
      _str msg="\""sshexe"\" not found.\n\nContinue?";
      status=_message_box(msg,'',MB_YESNO|MB_ICONQUESTION);
      if( status!=IDYES ) {
         return(1);
      }
   }
   _str sshexe_nopath=_strip_filename(sshexe,'PE');
   if( sshexe_nopath=="sftp" ) {
      _ctl_options_sstab.p_ActiveTab=FTPOPTIONSTAB_SSH;
      p_window_id=_ctl_ssh_exe;
      _set_sel(1,length(p_text)+1);
      _set_focus();
      _str msg="\"You need to specify the path to the 'ssh' executable, not 'sftp'.";
      status=_message_box(msg,'',MB_OK|MB_ICONEXCLAMATION);
      return(1);
   }
   fo_p->sshexe=sshexe;

   _str sshsubsystem=_ctl_ssh_subsystem.p_text;
   if( sshsubsystem=="" ) {
      // Quietly set it back to default
      sshsubsystem=SFTPDEF_SUBSYSTEM;
   }
   fo_p->sshsubsystem=sshsubsystem;

   return(0);
}

static int onokDebugOptions(FtpOptions *fo_p)
{
   int flags;

   flags=0;
   if( _ctl_log_proxy.p_value ) {
      flags |= FTPDEBUG_LOG_PROXY;
   }
   if( _ctl_ssh_verbose.p_value ) {
      flags |= FTPDEBUG_SSH_VERBOSE;
   }
   if( _ctl_say_events.p_value ) {
      flags |= FTPDEBUG_SAY_EVENTS;
   }
   if( _ctl_save_log.p_value ) {
      flags |= FTPDEBUG_SAVE_LOG;
   }
   if( _ctl_time_stamp.p_value ) {
      flags |= FTPDEBUG_TIME_STAMP;
   }
   if( _ctl_save_list.p_value ) {
      flags |= FTPDEBUG_SAVE_LIST;
   }
   if( _ctl_vsproxy.p_value ) {
      flags |= FTPDEBUG_VSPROXY;
   }
   if( flags!=_ftpdebug ) {
      _ftpdebug=flags;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }

   return(0);
}

int _ctl_ok.lbutton_up()
{

   if( _ftpOptions_form_apply() ) {
      p_active_form._delete_window(0);
      return(0);
   } else {
      return( 1 );
   }
}

void _ctl_cancel.lbutton_up()
{
   p_active_form._delete_window('');
}

void _ctl_browse_ssh_exe.lbutton_up()
{
   _control _ctl_ssh_exe;

   typeless result=_OpenDialog('-modal',
                      'Choose SSH Executable', // Dialog Box Title
                      '',                      // Initial Wild Cards
                      "Executables (*.exe)",   // File Type List
                      OFN_FILEMUSTEXIST        // Flags
                      );
   p_window_id=_ctl_ssh_exe;
   _set_focus();
   if( result=="" ) {
      return;
   }
   p_text=result;

   return;
}

void _ctl_fw_type1.lbutton_up()
{
   boolean require_host=true;
   boolean require_port=true;
   boolean require_user=false;
   boolean require_pass=false;
   _ctl_pasv.p_enabled=true;
   _ctl_pasv.p_value=_ctl_pasv.p_user;
   _ctl_fw_host.p_enabled=require_host;
   _ctl_fw_port.p_enabled=require_port;
   _ctl_fw_user.p_enabled=require_user;
   _ctl_fw_pass.p_enabled=require_pass;

   return;
}

void _ctl_fw_type2.lbutton_up()
{
   boolean require_host=true;
   boolean require_port=true;
   boolean require_user=false;
   boolean require_pass=false;
   _ctl_pasv.p_enabled=true;
   _ctl_pasv.p_value=_ctl_pasv.p_user;
   _ctl_fw_host.p_enabled=require_host;
   _ctl_fw_port.p_enabled=require_port;
   _ctl_fw_user.p_enabled=require_user;
   _ctl_fw_pass.p_enabled=require_pass;

   return;
}

void _ctl_fw_type3.lbutton_up()
{
   boolean require_host=true;
   boolean require_port=true;
   boolean require_user=true;
   boolean require_pass=true;
   _ctl_pasv.p_enabled=true;
   _ctl_pasv.p_value=_ctl_pasv.p_user;
   _ctl_fw_host.p_enabled=require_host;
   _ctl_fw_port.p_enabled=require_port;
   _ctl_fw_user.p_enabled=require_user;
   _ctl_fw_pass.p_enabled=require_pass;

   return;
}

void _ctl_fw_type4.lbutton_up()
{
   // Router based firewalls ALWAYS use PASV transfers
   boolean require_host=false;
   boolean require_port=false;
   boolean require_user=false;
   boolean require_pass=false;
   _ctl_pasv.p_value=1;
   _ctl_pasv.p_enabled=false;
   _ctl_fw_host.p_enabled=require_host;
   _ctl_fw_port.p_enabled=require_port;
   _ctl_fw_user.p_enabled=require_user;
   _ctl_fw_pass.p_enabled=require_pass;

   return;
}

void _ctl_pasv.lbutton_up()
{
   /* Used to remember what the previous value was when the user switches to
    * "Router" type, then to some other type.
    */
   p_user=p_value;
}

void _ctl_enable_fw.lbutton_up()
{
   boolean enabled= (p_value!=0);
   _ctl_fw_host.p_enabled=enabled;
   _ctl_fw_port.p_enabled=enabled;
   _ctl_fw_user.p_enabled=enabled;
   _ctl_fw_pass.p_enabled=enabled;
   _ctl_fw_type1.p_enabled=enabled;
   _ctl_fw_type2.p_enabled=enabled;
   _ctl_fw_type3.p_enabled=enabled;
   _ctl_fw_type4.p_enabled=enabled;
   _ctl_pasv.p_enabled=enabled;
   if( enabled ) {
      if( _ctl_fw_type1.p_value ) {
         _ctl_fw_type1.call_event(_ctl_fw_type1,LBUTTON_UP,'W');
      } else if( _ctl_fw_type2.p_value ) {
         _ctl_fw_type2.call_event(_ctl_fw_type2,LBUTTON_UP,'W');
      } else if( _ctl_fw_type3.p_value ) {
         _ctl_fw_type3.call_event(_ctl_fw_type3,LBUTTON_UP,'W');
      } else if( _ctl_fw_type4.p_value ) {
         _ctl_fw_type3.call_event(_ctl_fw_type4,LBUTTON_UP,'W');
      }
   }

   return;
}

#define FPMDATAP _ctl_connect.p_user
defeventtab _ftpProfileManager_form;
static int _fpmFillProfileList()
{
   FTPMaybeCreateUserIniFile();

   _ctl_list._lbclear();
   int temp_view_id=0;
   int orig_view_id=0;
   int status=_open_temp_view(FTPUserIniFilename(),temp_view_id,orig_view_id);
   if( status ) {
      // Nothing to fill with
      return(0);
   }
   _str line='';
   _str profile='';
   p_window_id=temp_view_id;
   top();
   status=search('^\[profile\-','@ir');
   while( !status ) {
      get_line(line);
      parse line with '[profile-' profile ']';
      if( profile=="" ) {
         // This should never happen
         continue;
      }
      p_window_id=orig_view_id;
      _ctl_list._lbadd_item(profile);
      p_window_id=temp_view_id;
      status=repeat_search();
   }
   _delete_temp_view(temp_view_id);
   p_window_id=orig_view_id;
   _ctl_list._lbsort('AI');
   _ctl_list._lbtop();
   //_ctl_list._lbselect_line();

   return(0);
}

void _ctl_connect.on_create(FtpConnProfile* fcp_p=null, _str caption=null)
{
   _ftpProfileManager_form_initial_alignment();

   FPMDATAP = null;
   if( fcp_p ) {
      FPMDATAP = fcp_p;
   }
   if( !FPMDATAP ) {
      // Only allow the user to add/delete/edit connection profiles
      _ctl_connect.p_enabled = false;
   }

   if( _fpmFillProfileList() ) {
      _message_box("Unable to create connection profile list",'',MB_OK|MB_ICONEXCLAMATION);
      p_active_form._delete_window(1);
      return;
   }

   p_window_id=_ctl_list;
   if( p_Noflines ) {
      _lbdeselect_all();
      _lbtop();
      _str last_item='';
      int status=_ini_get_value(FTPUserIniFilename(),"Profile Manager","lastprofile",last_item);
      if( !status ) {
         _lbsearch(last_item,'E');
      }
      _lbselect_line();
   }
   if( caption!=null ) {
      p_active_form.p_caption=caption;
   }

   // call the list on_change event so the buttons will be enabled properly
   _ctl_list.call_event(_ctl_list, ON_CHANGE);
}

static void _ftpProfileManager_form_initial_alignment()
{
   _ctl_options.p_x = (ctlHelpLabelFilter.p_x + ctlHelpLabelFilter.p_width) - _ctl_options.p_width;
}

void _ctl_connect.lbutton_up()
{
   FtpConnProfile *fcpdata_p;

   fcpdata_p=FPMDATAP;

   _str profile=_ctl_list._lbget_seltext();
   if( profile=="" ) {
      _message_box("Select a profile to connect to",'',MB_OK|MB_ICONINFORMATION);
      return;
   }
   int status=_ftpOpenConnProfile(profile,fcpdata_p);
   if( !status ) {
      // FTPMaybeCreateUserIniFile() takes care of any error message
      if( FTPMaybeCreateUserIniFile()!="" ) {
         _str last_item=_ctl_list._lbget_seltext();
         _ini_set_value(FTPUserIniFilename(),"Profile Manager","lastprofile",last_item);
      }
   }

   p_active_form._delete_window(status);

   return;
}

void _ctl_list.rbutton_up()
{
   if( !_lbisline_selected() ) {
      _lbdeselect_all();
      _lbselect_line();
   }

   FtpConnProfile *fcp_p;
   int formWid;

   _str menu_name="_ftpProfileManager_menu";
   int idx=find_index(menu_name,oi2type(OI_MENU));
   if( !idx ) {
      return;
   }
   int mh=p_active_form._menu_load(idx,'P');
   if( mh<0) {
      _message_box('Unable to load menu: "':+menu_name:+'"',"",MB_OK|MB_ICONEXCLAMATION);
      return;
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

void _ctl_list.on_change()
{
   // just see whether we have a current item and enable/disable buttons accordingly
   enabled := (_lbget_seltext() != '');
   _ctl_delete.p_enabled = _ctl_edit.p_enabled = _ctl_rename.p_enabled = _ctl_copy.p_enabled = enabled;
   // FPMDATAP == null when run from ftpProfileManager() (i.e. not connecting)
   _ctl_connect.p_enabled = ( FPMDATAP && enabled );
}

void _ctl_list.lbutton_double_click()
{
   if( _ctl_connect.p_enabled ) _ctl_connect.call_event(_ctl_connect,LBUTTON_UP,'W');

   return;
}

_command void ftpProfileManager() name_info(','VSARG2_NCW|VSARG2_READ_ONLY)
{
   if( p_DockingArea!=0 ) {
      _mdi.show("-modal _ftpProfileManager_form");
   } else {
      show("-modal _ftpProfileManager_form");
   }
}

_command void ftpProfileManagerAdd() name_info(','VSARG2_NCW|VSARG2_READ_ONLY)
{
   FtpConnProfile fcp;

   int formWid=_find_object("_ftpProfileManager_form","N");
   if( !formWid ) return;
   int listWid=formWid._find_control("_ctl_list");
   if( !listWid ) return;
   fcp._makeempty();
   _ftpInitConnProfile(fcp);
   typeless status=show("-modal _ftpCreateProfile_form",&fcp,FCPFLAG_HIDESAVEPROFILE);
   if( status ) {
      if( status!="" ) {   // Check for command cancelled
         ftpDisplayError("Unable to create connection profile");
      }
      return;
   }
   if( fcp.profileName!="" ) {
      listWid._lbadd_item(fcp.profileName);
      listWid._lbsort('AI');
      // Scroll the new profile into view at the top of the list
      listWid._lbsearch(fcp.profileName,'E');
      listWid._lbselect_line();
      if( listWid.p_line==0 ) listWid._lbtop();

      // call the on_change event so the buttons will be enabled properly
      listWid.call_event(listWid, ON_CHANGE);
   }

   return;
}

void _ctl_add.lbutton_up()
{
   ftpProfileManagerAdd();

   return;
}

_command void ftpProfileManagerDelete() name_info(','VSARG2_NCW|VSARG2_READ_ONLY)
{
   FtpConnProfile fcp;

   int formWid=_find_object("_ftpProfileManager_form","N");
   if( !formWid ) return;
   int listWid=formWid._find_control("_ctl_list");
   if( !listWid ) return;
   _str profile=listWid._lbget_seltext();
   if( profile!="" ) {
      int result=_message_box('Delete profile "':+profile:+'"':+"\n\nAre you sure?","FTP",MB_YESNO|MB_ICONQUESTION);
      if( result!=IDYES ) return;
      int status=_ftpDeleteConnProfile(profile);
      if( status ) {
         ftpDisplayError("Unable to delete connection profile");
         return;
      }
      listWid._lbdelete_item();

      // call the on_change event so the buttons will be enabled properly
      listWid.call_event(listWid, ON_CHANGE);
   }

   return;
}

void _ctl_delete.lbutton_up()
{
   ftpProfileManagerDelete();

   return;
}

_command void ftpProfileManagerEdit() name_info(','VSARG2_NCW|VSARG2_READ_ONLY)
{
   FtpConnProfile fcp;

   int formWid=_find_object("_ftpProfileManager_form","N");
   if( !formWid ) return;
   int listWid=formWid._find_control("_ctl_list");
   if( !listWid ) return;
   _str profile=listWid._lbget_seltext();
   if( profile!="" ) {
      fcp._makeempty();
      int status=_ftpOpenConnProfile(profile,&fcp);
      if( status ) {
         ftpDisplayError("Unable to open connection profile");
         return;
      }
      int flags=FCPFLAG_HIDESAVEPROFILE|FCPFLAG_DISABLEPROFILE|FCPFLAG_EDIT;
      status=show("-modal _ftpCreateProfile_form",&fcp,flags);
      if( status ) {
         if( status!="" ) {   // Check for command cancelled
            ftpDisplayError("Unable to save connection profile");
         }
         return;
      }
   }

   return;
}

void _ctl_edit.lbutton_up()
{
   ftpProfileManagerEdit();

   return;
}

_command void ftpProfileManagerRename() name_info(','VSARG2_NCW|VSARG2_READ_ONLY)
{
   typeless status=0;
   int formWid=_find_object("_ftpProfileManager_form","N");
   if( !formWid ) return;
   int listWid=formWid._find_control("_ctl_list");
   if( !listWid ) return;
   _str old_profile=listWid._lbget_seltext();
   if( old_profile!="" ) {
      typeless result=show("-modal _textbox_form","Rename Profile",0,"","","","","New profile name:":+old_profile);
      if( result=="" ) {
         // User cancelled
         return;
      }

      // FTPMaybeCreateUserIniFile() takes care of the error message
      if( FTPMaybeCreateUserIniFile()=="" ) return;

      _str new_profile=strip(_param1);
      if( new_profile=="" ) return;
      if( _ftpIsConnProfile(new_profile) ) {
         _str msg='The profile "':+new_profile:+'" already exists.':+
             "\n\nReplace it?";
         status=_message_box(msg,'',MB_OK|MB_ICONQUESTION|MB_YESNO);
         if( status!=IDYES ) return;
         status=_ini_delete_section(FTPUserIniFilename(),"profile-":+new_profile);
         if( status ) {
            msg="Error deleting profile [":+new_profile:+"].  ":+get_message(status);
            ftpDisplayError(msg);
            return;
         }
      }
      int ini_view_id=0;
      int orig_view_id=0;
      status=_open_temp_view(FTPUserIniFilename(),ini_view_id,orig_view_id);
      if( status ) return;
      p_window_id=ini_view_id;
      top();
      status=search('^\[profile\-':+_escape_re_chars(old_profile):+']','@ir');
      if( status ) {
         _str msg='Could not find profile "':+old_profile:+'" in ':+FTPUserIniFilename();
         ftpDisplayError(msg);
         _delete_temp_view(ini_view_id);
         p_window_id=orig_view_id;
         return;
      }
      replace_line('[profile-':+new_profile:+']');
      status=_save_config_file();
      _delete_temp_view(ini_view_id);
      p_window_id=orig_view_id;
      if( status ) {
         _str msg='Unable to save "':+FTPUserIniFilename():+'".  ':+_ftpGetMessage(status);
         ftpDisplayError(msg);
      } else {
         formWid._fpmFillProfileList();
         // Scroll the new profile into view at the top of the list
         listWid._lbsearch(new_profile,'E');
         listWid._lbselect_line();
      }
   }

   return;
}

void _ctl_rename.lbutton_up()
{
   ftpProfileManagerRename();

   return;
}

_command void ftpProfileManagerCopy() name_info(','VSARG2_NCW|VSARG2_READ_ONLY)
{
   FtpConnProfile fcp;

   typeless result=0;
   typeless status=0;
   int formWid=_find_object("_ftpProfileManager_form","N");
   if( !formWid ) return;
   int listWid=formWid._find_control("_ctl_list");
   if( !listWid ) return;
   _str from_profile=listWid._lbget_seltext();
   if( from_profile!="" ) {
      result=show("-modal _textbox_form","Copy Profile [":+from_profile:+"]",0,"",'?Specify the new profile name that will be a duplicate of "':+from_profile:+'"',"","","New profile name:":+from_profile);
      if( result=="" ) {
         // User cancelled
         return;
      }

      // FTPMaybeCreateUserIniFile() takes care of the error message
      if( FTPMaybeCreateUserIniFile()=="" ) return;

      _str to_profile=strip(_param1);
      if( to_profile=="" ) return;
      if( _ftpIsConnProfile(to_profile) ) {
         _str msg='The profile "':+to_profile:+'"\n\nalready exists.':+
             "\n\nReplace it?";
         status=_message_box(msg,'',MB_OK|MB_ICONQUESTION|MB_YESNO);
         if( status!=IDYES ) return;
      }
      int orig_view_id=p_window_id;
      int temp_view_id=0;
      status=_ini_get_section(FTPUserIniFilename(),"profile-":+from_profile,temp_view_id);
      if( status ) {
         _str msg="Error retrieving profile [":+from_profile:+"].  ":+get_message(status);
         ftpDisplayError(msg);
         return;
      }
      p_window_id=temp_view_id;
      status=_ini_put_section(FTPUserIniFilename(),"profile-":+to_profile,temp_view_id);
      if( status ) {
         if( p_window_id==temp_view_id ) {
            _delete_temp_view(temp_view_id);
            p_window_id=orig_view_id;
         }
         _str msg="Error writing profile [":+to_profile:+"].  ":+get_message(status);
         ftpDisplayError(msg);
         return;
      }
      p_window_id=orig_view_id;
      // Refresh the profile list
      formWid._fpmFillProfileList();
      listWid._lbsearch(to_profile,'E');
      listWid._lbselect_line();
   }

   return;
}

void _ctl_copy.lbutton_up()
{
   ftpProfileManagerCopy();

   return;
}

void _ctl_options.lbutton_up()
{
   ftp_default_options();

   return;
}

void _ctl_close.lbutton_up()
{
   if( _ctl_list.p_nofselected>0 ) {
      // FTPMaybeCreateUserIniFile() takes care of any error message
      if( FTPMaybeCreateUserIniFile()!="" ) {
         _str last_item=_ctl_list._lbget_seltext();
         _ini_set_value(FTPUserIniFilename(),"Profile Manager","lastprofile",last_item);
      }
   }
   p_active_form._delete_window('');

   return;
}

defeventtab _ftpLog_form;

// This expects the active window to be an edit control
static void _AttachLog(_str log_buf_name)
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

   return;
}

void _ctl_ok.on_create(FtpConnProfile *fcp_p=null, _str caption="")
{
   if( caption!="" ) {
      p_active_form.p_caption="FTP Log - ":+strip(caption);
   }
   if( fcp_p ) {
      _ctl_log.p_visible=true;
      _ctl_no_log.p_visible=false;
      _ctl_log._AttachLog(fcp_p->logBufName);
   } else {
      _ctl_log.p_visible=false;
      _ctl_no_log.p_visible=true;
   }

   return;
}

void _ctl_ok.lbutton_up()
{
   p_active_form._delete_window();

   return;
}

_ftpLog_form.on_resize()
{
   int formW=_dx2lx(SM_TWIP,p_active_form.p_client_width);
   int formH=_dy2ly(SM_TWIP,p_active_form.p_client_height);

   _ctl_log.p_width=formW-2*_ctl_log.p_x;
   _ctl_log.p_height=formH-2*_dy2ly(SM_TWIP,4)-_ctl_ok.p_height;

   _ctl_ok.p_x= (int)(formW-_ctl_ok.p_width)/2;
   _ctl_ok.p_y=_ctl_log.p_y+_ctl_log.p_height+_dy2ly(SM_TWIP,4)-1;
}

defeventtab _ftpProgress_form;
_ctl_abort.on_create(_str caption="")
{
   _ctl_progress.p_value=0;
   _ctl_nofbytes.p_caption="";
   if( caption!="" ) {
      // This is a starting caption that will probably get overwritten
      // if there is a callback that updates this form.
      p_active_form.p_caption=caption;
   }
}

_ctl_abort.lbutton_up()
{
   gftpAbort=true;
}

