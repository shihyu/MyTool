////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47272 $
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
#import "fileman.e"
#import "ftp.e"
#import "ftpclien.e"
#import "ftpparse.e"
#import "ftpq.e"
#import "main.e"
#import "makefile.e"
#import "sftpparse.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "files.e"
#endregion


void __sftpclientConnectCB( FtpQEvent *pEvent, typeless isReconnecting="" )
{
   FtpQEvent event;
   FtpConnProfile fcp;
   _str CwdHist[];
   _str rpath,apath;
   SftpName cname;
   _str msg="";

   event= *((FtpQEvent *)(pEvent));
   boolean reconnecting = ( isReconnecting!="" && isReconnecting );

   fcp=event.fcp;
   fcp.postedCb=null;   // Paranoid
   int profileWid=0, label1Wid=0, label2Wid=0, progressWid=0;
   int formWid=_ftpclientQFormWid();
   if( formWid ) {
      profileWid=formWid._find_control("_ctl_profile");
      label1Wid=formWid._find_control("_ctl_progress_label1");
      label2Wid=formWid._find_control("_ctl_progress_label2");
      progressWid=formWid._find_control("_ctl_progress");
   }

   if( _ftpQEventIsError(event) || _ftpQEventIsAbort(event) ) {
      if( event.event!=QE_SFTP_STAT ) {
         label1Wid.p_caption="";
         label2Wid.p_caption="";
         progressWid.p_value=0;
         return;
      }
      // The only thing that failed is changing directory
      if( event.event==QE_SFTP_STAT ) {
         rpath= (_str)event.info[0];
         if( rpath!="." ) {
            // Try '.' for the HOME directory
            if( reconnecting ) {
               // Must be synchronous when reconnecting so connection
               // happens BEFORE operations.
               fcp.postedCb=(typeless)__sftpclientConnect2CB;
               _ftpSyncEnQ(QE_SFTP_STAT,QS_BEGIN,0,&fcp,".");
            } else {
               fcp.postedCb=(typeless)__sftpclientConnectCB;
               _ftpIdleEnQ(QE_SFTP_STAT,QS_BEGIN,0,&fcp,".");
            }
            return;
         }
         // Cannot even get the HOME directory, so default to root directory
         fcp.remoteCwd="/";
         //return;
      }
   } else {
      // Extract the absolute remote working directory and check to
      // be sure it is valid.
      rpath= (_str)event.info[0];
      cname= (SftpName)event.info[1];
      apath=cname.filename;
      // Check that attributes say that it is a directory
      if( !(cname.attrs.flags&SSH_FILEXFER_ATTR_PERMISSIONS) ) {
         msg=nls("Cannot change directory: Cannot check target");
         ftpConnDisplayError(&fcp,msg);
         return;
      }
      if( !S_ISDIR(cname.attrs.permissions) ) {
         msg=nls("Cannot change directory: \"%s\" is not a directory",apath);
         ftpConnDisplayError(&fcp,msg);
         return;
      }
      fcp.remoteCwd=apath;
   }

   // Now set the local current working direcotry
   _str cwd=fcp.defLocalDir;
   cwd=strip(cwd);
   if( cwd=="" ) cwd=getcwd();
   if( last_char(cwd)==FILESEP ) cwd=substr(cwd,1,length(cwd)-1);
   typeless isdir=isdirectory(maybe_quote_filename(cwd));
   if( (isdir=="" || isdir=="0") && !isuncdirectory(cwd) ) {
      // Not a valid local directory
      cwd=getcwd();
      ftpConnDisplayWarning(&fcp,"Warning: Unable to change to local directory:\n\n":+
                            fcp.defLocalDir:+"\n\nThe local current working directory is:\n\n":+
                            cwd);
   }
   fcp.localCwd=cwd;

   _ftpGetCwdHist(fcp.profileName,CwdHist);
   fcp.cwdHist=CwdHist;
   typeless htindex="";
   _ftpAddCurrentConnProfile(&fcp,htindex);

   if( !formWid ) {
      // This could happen if user closes FTP Client toolbar in the middle
      // of the connection attempt.
      return;
   }
   if( !reconnecting ) {
      profileWid._ftpclientFillProfiles(true);
      profileWid._ftpclientChangeProfile(htindex);
      _ftpclientUpdateSession(true);
      call_list('_ftpProfileAddRemove_',formWid);
   }

   label1Wid.p_caption="Connected";
   label2Wid.p_caption="";
   progressWid.p_value=100;

   return;
}
/**
 * Used when reconnecting a lost connection.
 */
void __sftpclientConnect2CB( FtpQEvent *pEvent )
{
   __sftpclientConnectCB(pEvent, true);
}

void __sftpclientCwdCB( FtpQEvent *pEvent, typeless isLink="" )
{
   FtpQEvent event;
   FtpConnProfile fcp;
   FtpConnProfile *fcp_p;
   SftpName cname;
   _str rpath,apath;
   int formWid;
   _str msg="";

   formWid = _ftpclientQFormWid();
   if( !formWid ) return;   // This should never happen

   event= *((FtpQEvent *)(pEvent));
   fcp=event.fcp;

   boolean is_link = ( isLink!="" && isLink );

   if( _ftpQEventIsError(event) ) {
      // Fix things up in case the user had typed a bogus path and hit ENTER
      _ftpclientUpdateSession(false);
   }

   if( !_ftpQEventIsError(event) && !_ftpQEventIsAbort(event) ) {
      // Extract the absolute remote working directory and check to
      // be sure it is valid.
      rpath= (_str)event.info[0];
      cname= (SftpName)event.info[1];
      apath=cname.filename;
      // Check that attributes say that it is a directory
      if( !(cname.attrs.flags&SSH_FILEXFER_ATTR_PERMISSIONS) ) {
         msg=nls("Cannot change directory: Cannot check target");
         ftpConnDisplayError(&fcp,msg);
         return;
      }
      if( !S_ISDIR(cname.attrs.permissions) ) {
         if( is_link ) {
            // The symbolic link is not a directory, so try to open as file instead
            ftpclientDownloadLinks();
            return;
         }
         msg=nls("Cannot change directory: \"%s\" is not a directory",apath);
         ftpConnDisplayError(&fcp,msg);
         return;
      }
      fcp.remoteCwd=apath;

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

      // _ftpclientUpdateRemoteSession() already handles asynchronous operations
      _ftpclientUpdateRemoteSession(true);
      return;
   }
}
void __sftpclientCwdLinkCB( FtpQEvent *pEvent )
{
   __sftpclientCwdCB(pEvent, true);
}

void __sftpclientUpdateRemoteSessionCB( FtpQEvent *pEvent )
{
   FtpQEvent event;
   SftpDirectory dirlist;
   FtpConnProfile fcp;
   FtpConnProfile *fcp_p;

   event= *((FtpQEvent *)(pEvent));
   fcp=event.fcp;

   if( _ftpQEventIsError(event) || _ftpQEventIsAbort(event) ) {
      // Nothing to do
      return;
   }

   _str msg="";
   _str temp_path="";
   _str list_filename="";
   typeless status=0;

   // We just listed the contents of the current working directory.
   // Now stick it in the remote tree view.
   dirlist= (SftpDirectory)event.info[0];
   if( _ftpdebug&FTPDEBUG_SAVE_LIST ) {
      // Make a copy of the structured and raw listing
      temp_path=_temp_path();
      if( last_char(temp_path)!=FILESEP ) temp_path=temp_path:+FILESEP;
      list_filename=temp_path:+"$list";
      int orig_view_id=p_window_id;
      int temp_view_id=0;
      if( _create_temp_view(temp_view_id)=="" ) {
         msg="Unable to create a temp view for directory listing";
         _message_box(msg,'',MB_OK|MB_ICONEXCLAMATION);
         return;
      }
      p_window_id=temp_view_id;
      // Structured listing
      insert_line("Structured listing:");
      insert_line("");
      insert_line("filename\tsize\tuid\tgid\tatime\tmtime\tpermissions");
      int i;
      for( i=0;i<dirlist.names._length();++i ) {
         insert_line(dirlist.names[i].filename"\t"dirlist.names[i].attrs.size"\t"dirlist.names[i].attrs.uid"\t"dirlist.names[i].attrs.gid"\t"dirlist.names[i].attrs.atime"\t"dirlist.names[i].attrs.mtime"\t"dirlist.names[i].attrs.permissions);
      }
      // Long listing
      insert_line("");
      insert_line("");
      insert_line("Long listing:");
      insert_line("");
      for( i=0;i<dirlist.names._length();++i ) {
         insert_line(dirlist.names[i].longname);
      }
      status=_save_file("+o "maybe_quote_filename(list_filename));
      if( status ) {
         msg="Failed to create debug listing \""list_filename"\". status="status;
         ftpConnDisplayError(&fcp,msg);
      }
      _delete_temp_view(temp_view_id);
      p_window_id=orig_view_id;
   }
   status=_sftpCreateDir(&fcp,&dirlist);
   if( status ) {
      int formWid = _ftpclientQFormWid();
      if( !formWid ) return;
      int noconnWid=formWid._find_control("_ctl_no_connection");
      if( noconnWid ) {
         noconnWid.p_caption="(No listing)";
      }
      msg="Could not create remote directory listing";
      ftpConnDisplayError(&fcp,msg);
      return;
   }

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

   int sstabWid=0, profileWid=0, localWid=0, remoteWid=0;
   int formWid = _ftpclientQFormWid();
   if( !formWid ) return;
   if( _ftpclientFindAllControls(formWid,sstabWid,profileWid,localWid,remoteWid) ) {
      // This should never happen
      return;
   }
   int remotecwdWid=formWid._find_control("_ctl_remote_cwd");
   if( !remotecwdWid ) return;
   int noconnWid=formWid._find_control("_ctl_no_connection");
   if( !noconnWid ) return;
   int logWid=formWid._find_control("_ctl_log");
   if( !logWid ) return;
   int nologWid=formWid._find_control("_ctl_no_log");
   if( !nologWid ) return;

   _ftpclientChangeRemoteDirOnOff(0);
   status=remoteWid._ftpclientRefreshRemoteDir(fcp_p);
   _ftpclientChangeRemoteDirOnOff(1);
   if( !status ) {
      remoteWid._ftpRemoteRestorePos();
      remoteWid._ftpRemoteSavePos();
      remoteWid.p_visible=true;
      remotecwdWid.p_visible=true;
      _str cwd=fcp_p->remoteCwd;
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

void __sftpclientDelRemoteFile2CB( FtpQEvent *pEvent, typeless isPopping="" );
void __sftpclientDelRemoteFile3CB( FtpQEvent *pEvent );
void __sftpclientDelRemoteFile1CB( FtpQEvent *pEvent )
{
   FtpQEvent event;
   FtpConnProfile fcp;
   FtpConnProfile *fcp_p;
   FtpFile file;
   int formWid;

   event= *((FtpQEvent *)(pEvent));
   fcp=event.fcp;
   fcp.postedCb=null;
   _str filename="";
   _str cwd="";

   if( _ftpQEventIsError(event) || _ftpQEventIsAbort(event) ) {
      // Check for "fake" file/directory
      formWid = _ftpclientQFormWid();
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
               if( event.event==QE_SFTP_REMOVE && !(file.type&FTPFILETYPE_DIR) ) {
                  // File
                  fcp_p->remoteDir.files._deleteel(i);
               } else if( event.event==QE_SFTP_RMDIR && file.type&FTPFILETYPE_DIR ) {
                  // Directory
                  fcp_p->remoteDir.files._deleteel(i);
               }
            }
         }
      }
      // Make sure that we check the fcp that was passed in with the event,
      // not the original connection profile's.
      if( fcp.autoRefresh ) {
         _ftpclientUpdateSession(true);
      } else {
         _ftpclientUpdateSession(false);
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
               _ftpclientProgressCB("Deleting ":+filename,0,0);
               fcp.postedCb=(typeless)__sftpclientDelRemoteFile1CB;
               _ftpIdleEnQ(QE_SFTP_REMOVE,QS_BEGIN,0,&fcp,filename);
               return;
            } else if( file.type&FTPFILETYPE_DIR ) {
               // Directory
               if( fcp.recurseDirs ) {
                  // We are pushing another directory, so push the directory name
                  // onto the .extra stack so we know which directory to RMDIR after
                  // we pop it.
                  _str dirnames[];
                  dirnames= (_str [])fcp.extra;
                  dirnames[dirnames._length()]=filename;
                  fcp.extra=dirnames;
                  // __sftpclientDelRemoteFile2CB() processes the listing
                  fcp.postedCb=(typeless)__sftpclientDelRemoteFile2CB;
                  _ftpIdleEnQ(QE_SFTP_STAT,QS_BEGIN,0,&fcp,filename);
                  return;
               } else {
                  // Attempt to remove the directory
                  _ftpclientProgressCB("Deleting ":+filename,0,0);
                  fcp.postedCb=(typeless)__sftpclientDelRemoteFile1CB;
                  _ftpIdleEnQ(QE_SFTP_RMDIR,QS_BEGIN,0,&fcp,filename);
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
         // fcp.RemoteCWD will be correct after popping to previous directory
         // Change the listing back to previous
         fcp.remoteDir=fcp.dir_stack[fcp.dir_stack._length()-1].dir;
         // Change directory back to original directory
         cwd=fcp.dir_stack[fcp.dir_stack._length()-1].remotecwd;
         if( fcp.system==FTPSYST_MVS ) {
            if( substr(cwd,1,1)!='/' ) {
               // Make it absolute for MVS
               cwd="'":+cwd:+"'";
            }
         }
         fcp.remoteCwd=cwd;

         // Remove the directory we just popped
         _str dirnames[];
         dirnames= (_str [])fcp.extra;
         if( dirnames._length()>0 ) {
            // We just finished popping back a directory, so now we must
            // RMDIR the directory name itself.
            _str dirname=dirnames[dirnames._length()-1];
            dirnames._deleteel(dirnames._length()-1);
            fcp.extra=dirnames;
            fcp.postedCb=(typeless)__sftpclientDelRemoteFile3CB;
            //_message_box("__sftpclientDelRemoteFile2CB: rmdir - dirname="dirname"  RemoteCWD="fcp.RemoteCWD);
            _ftpIdleEnQ(QE_SFTP_RMDIR,QS_BEGIN,0,&fcp,dirname);
            return;
         }
      }
   }

   if( fcp.autoRefresh ) {
      _ftpclientUpdateSession(true);
   } else {
      _ftpclientUpdateSession(false);
   }

   return;
}

/**
 * Callback used when changing directory and retrieving a listing.
 */
void __sftpclientDelRemoteFile2CB( FtpQEvent *pEvent, typeless isPopping="" )
{
   FtpQEvent event;
   SftpDirectory dirlist;
   _str rpath,apath;
   SftpName cname;
   FtpConnProfile fcp;
   FtpConnProfile *fcp_p;

   event= *((FtpQEvent *)(pEvent));
   fcp=event.fcp;

   typeless status=0;
   _str cwd="";
   _str msg="";

   // Indicates that we are in the middle of popping back to the previous
   // directory. No need to do a listing.
   boolean popping= (isPopping!="");

   if( _ftpQEventIsError(event) || _ftpQEventIsAbort(event) ) {
      if( !_ftpQEventIsError(event) ) {
         return;
      }
      boolean do_cleanup=true;
      if( !popping ) {
         if( event.event==QE_SFTP_STAT ) {
            cwd=event.info[0];
            msg="Failed to change directory to ":+cwd:+
                "\n\nContinue?";
            status=_message_box(msg,"FTP",MB_YESNO);
            if( status==IDYES ) {
               // fcp.LocalCWD was set in __sftpclientDelRemoteFile1CB(), so
               // set it back.
               fcp.localCwd=fcp.dir_stack[fcp.dir_stack._length()-1].localcwd;
               event._makeempty();
               event.fcp=fcp;
               event.event=QE_NONE;
               event.state=QS_NONE;
               event.start=0;
               // __sftpclientDelRemoteFile1CB() processes the next file/directory
               __sftpclientDelRemoteFile1CB(&event);
               return;
            }
         }
      }
      if( do_cleanup ) {
         // Update remote and local session back to original and stop
         // Since SFTP does not support changing directory server-side,
         // all we have to do now is refresh the listing.
         if( fcp.remoteCwd!=fcp.dir_stack[0].remotecwd ) {
            _ftpclientUpdateSession(true);
         } else {
            _ftpclientUpdateSession(false);
         }
         return;
      }
   }

   if( !popping && event.event==QE_SFTP_STAT ) {
      // We just stat'ed the current working directory.
      // Now we must list its contents.
      //
      // Extract the absolute remote working directory and check to
      // be sure it is valid.
      rpath= (_str)event.info[0];
      cname= (SftpName)event.info[1];
      apath=cname.filename;
      // Check that attributes say that it is a directory
      boolean do_cleanup=false;
      if( !(cname.attrs.flags&SSH_FILEXFER_ATTR_PERMISSIONS) ) {
         msg=nls("Cannot change directory: Cannot check target");
         ftpConnDisplayError(&fcp,msg);
         do_cleanup=true;
      } else if( !S_ISDIR(cname.attrs.permissions) ) {
         msg=nls("Cannot change directory: \"%s\" is not a directory",apath);
         ftpConnDisplayError(&fcp,msg);
         do_cleanup=true;
      }
      if( do_cleanup ) {
         // If we got here then we need to clean up after an error.
         // Since SFTP does not support changing directory server-side,
         // all we have to do now is refresh the listing.
         _ftpclientUpdateSession(true);
         return;
      }
      fcp.remoteCwd=apath;
      fcp.postedCb=(typeless)__sftpclientDelRemoteFile2CB;
      _ftpIdleEnQ(QE_SFTP_DIR,QS_BEGIN,0,&fcp);
      return;
   }

   if( !popping ) {
      // We just got a directory listing
      dirlist= (SftpDirectory)event.info[0];
      status=_sftpCreateDir(&fcp,&dirlist);
      if( status ) {
         // If we got here then we need to clean up after an error.
         // Since SFTP does not support changing directory server-side,
         // all we have to do now is refresh the listing.
         _ftpclientUpdateSession(true);
         return;
      } else {
         // Refresh the remote listing so the user sees what is going on
         _ftpclientUpDownLoadRefresh(&fcp,'R');

         // Note that fcp.LocalCWD was set in __sftpclientDelRemoteFile1CB() in
         // anticipation of the push.
         _ftpDirStackPush(fcp.localCwd,fcp.remoteCwd,&fcp.remoteDir,fcp.dir_stack);
         fcp.postedCb=null;
         event._makeempty();
         event.fcp=fcp;
         event.event=QE_NONE;
         event.state=QS_NONE;
         event.start=0;
         // __sftpclientDelRemoteFile1CB() processes the next file directory
         __sftpclientDelRemoteFile1CB(&event);
         return;
      }
   }

   // If we got here then we must have just finished popping back to a
   // previous directory, so process the next file/directory.
   fcp.postedCb=null;
   _str dirnames[];
   dirnames= (_str [])fcp.extra;
   // Finished the RMDIR of the original directory, so process the next
   // file/directory.
   event._makeempty();
   event.fcp=fcp;
   event.event=QE_NONE;
   event.state=QS_NONE;
   event.start=0;

   // If dirnames._length()==0 then it means we are back to the original
   // directory listing which only consists of the selected files/directories.
   // So the user doesn't see a curtailed listing and think that more files
   // than they specified were deleted, we defer the refresh.
   if( dirnames._length()>0 ) {
      // Refresh the remote listing so the user sees what is going on
      _ftpclientUpDownLoadRefresh(&fcp,'R');
   }

   // __sftpclientDelRemoteFile1CB() processes the next file directory
   __sftpclientDelRemoteFile1CB(&event);

   return;
}

/**
 * Callback used when popping a directory.
 */
void __sftpclientDelRemoteFile3CB( FtpQEvent *pEvent )
{
   // The second argument tells __sftpclientDelRemoteFile2CB() that we are
   // popping the top directory off the stack. No need to do a listing.
   __sftpclientDelRemoteFile2CB(pEvent,1);

   return;
}

void __sftpclientDownload2CB( FtpQEvent *pEvent, typeless isPopping="" );
void __sftpclientDownload3CB( FtpQEvent *pEvent );
void __sftpclientDownload1CB( FtpQEvent *pEvent, typeless doDownloadLinks="" )
{
   FtpQEvent event;
   FtpConnProfile fcp;
   FtpRecvCmd rcmd;
   FtpFile file;
   int formWid;

   event= *((FtpQEvent *)(pEvent));
   fcp=event.fcp;
   fcp.postedCb=null;

   typeless status=0;
   _str filename="";
   _str msg="";
   _str ext="";
   _str cwd="";
   _str member="";
   _str file_and_member="";
   _str local_path="";
   _str path="";

   boolean download_links = ( doDownloadLinks!="" && doDownloadLinks );

   if( _ftpQEventIsError(event) || _ftpQEventIsAbort(event) ) {
      // Update the local session back to original
      _ftpclientUpdateLocalSession();
      if( !_ftpQEventIsError(event) ) {
         // User aborted
         return;
      }
      // Should only get here when a GET failed
      if( event.event!=QE_SFTP_GET ) return;
      rcmd= (FtpRecvCmd)event.info[0];
      msg='Failed to download "':+rcmd.cmdargv[0]:+'"':+
          "\n\nContinue?";
      status=_message_box(msg,"FTP",MB_YESNO);
      if( status!=IDYES ) {
         // Update remote and local session back to original and stop
         // Since SFTP does not support changing directory server-side,
         // all we have to do now is refresh the listing.
         if( fcp.remoteCwd!=fcp.dir_stack[0].remotecwd ) {
            _ftpclientUpdateSession(true);
         } else {
            _ftpclientUpdateSession(false);
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
   _str filter=strip(fcp.remoteFileFilter);
   if( filter=="" ) filter=FTP_ALLFILES_RE;
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
            if( !(file.type&(FTPFILETYPE_DIR|FTPFILETYPE_LINK)) ||
                ((fcp.downloadLinks || download_links) && file.type&FTPFILETYPE_LINK) ) {
               // File

               if( filter!=FTP_ALLFILES_RE ) {
                  // Match on the filter
                  boolean match=false;
                  _str list=filter;
                  while( list!="" ) {
                     _str filespec=parse_file(list);
                     filespec=strip(filespec,'B','"');
                     if( filespec=="" ) continue;
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

               _str dest=localcwd;
               if( last_char(dest)!=FILESEP ) dest=dest:+FILESEP;
               switch( fcp.system ) {
               case FTPSYST_VMS:
               case FTPSYST_VMS_MULTINET:
                  // VMS filenames have version numbers at the end (e.g. ";1").
                  // We want to save the file without the version number.
                  parse filename with filename ';' .;
                  break;
               case FTPSYST_OS400:
                  if( substr(remotecwd,1,1)=='/' ) {
                     _str file_system="";
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
                           member=member:+".MBR";
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
               dest=dest:+filename;

               fcp.postedCb=(typeless)__sftpclientDownload1CB;
               _str cmdargv[];
               cmdargv._makeempty();
               cmdargv[0]=filename;
               rcmd.cmdargv=cmdargv;
               rcmd.datahost=rcmd.dataport="";   // Ignored
               rcmd.dest=dest;
               rcmd.pasv=0;   // Ignored
               rcmd.progressCb=_ftpclientProgressCB;
               rcmd.size=0;
               rcmd.xfer_type=FTPXFER_BINARY;   // Ignored

               // Members used specifically by SFTP
               rcmd.hfile= -1;
               rcmd.hhandle= -1;
               rcmd.offset=0;
               _ftpIdleEnQ(QE_SFTP_GET,QS_BEGIN,0,&fcp,rcmd);
               return;
            } else if( file.type&FTPFILETYPE_DIR ) {
               // Directory
               local_path=localcwd;
               if( last_char(local_path)!=FILESEP ) local_path=local_path:+FILESEP;
               local_path=local_path:+filename;
               path=isdirectory(maybe_quote_filename(local_path));
               if( path=="" || path=="0" ) {

                  if( file_exists(local_path) ) {
                     // This is a plain file.
                     // What to do, what to do.
                     msg="Attempting to download link:\n":+
                         "\t"filename"\n":+
                         "to local plain file:\n":+
                         "\t"maybe_quote_filename(local_path)"\n\n":+
                         "Replace?";
                     status=_message_box(msg,FTP_INFOBOX_TITLE,MB_YESNOCANCEL|MB_ICONQUESTION);
                     if( status==IDYES ) {
                        status=delete_file(local_path);
                        if( 0!=status ) {
                           msg="Failed to delete local file:\n\n":+
                               maybe_quote_filename(local_path);
                           ftpConnDisplayError(&fcp,msg);
                           return;
                        }

                     } else if( status==IDNO ) {
                        // Next file/directory
                        idx=_ftpDirStackNext(fcp.dir_stack);
                        continue;

                     } else {
                        // IDCANCEL

                        // Restore remote and local working directory back to original and stop.
                        // Note:
                        // Since SFTP does not support changing directory server-side,
                        // all we have to do now is refresh the listing.
                        _ftpclientUpdateLocalSession();
                        if( fcp.remoteCwd!=fcp.dir_stack[0].remotecwd ) {
                           _ftpclientUpdateSession(true);
                        } else {
                           _ftpclientUpdateSession(false);
                        }
                        return;
                     }

                  } else {
                     status=make_path(local_path);
                     if( status ) {
                        msg='Unable to create local directory "':+local_path:+'".  ':+
                            _ftpGetMessage(status);
                        ftpConnDisplayError(&fcp,msg);
                        return;
                     }
                  }
               }
               if( fcp.recurseDirs ) {
                  // Set this now so it is easy to pick up in
                  // __sftpclientDownload2CB() when we push.
                  fcp.localCwd=local_path;
                  // __sftpclientDownload2CB() processes the change directory and listing
                  fcp.postedCb=(typeless)__sftpclientDownload2CB;
                  _ftpIdleEnQ(QE_SFTP_STAT,QS_BEGIN,0,&fcp,filename);
                  return;
               }
            }
         }
         idx=_ftpDirStackNext(fcp.dir_stack);
      }
      // Pop this directory listing off the stack
      ds_popped = _ftpDirStackPop(fcp.dir_stack);
      if( fcp.dir_stack._length()>0 ) {
         // Change the local directory back to previous
         fcp.localCwd=fcp.dir_stack[fcp.dir_stack._length()-1].localcwd;
         // fcp.RemoteCWD will be correct after the change directory
         // Change the listing back to previous
         fcp.remoteDir=fcp.dir_stack[fcp.dir_stack._length()-1].dir;
         // Change directory back to original directory
         cwd=fcp.dir_stack[fcp.dir_stack._length()-1].remotecwd;
         if( fcp.system==FTPSYST_MVS ) {
            if( substr(cwd,1,1)!='/' ) {
               // Make it absolute for MVS
               cwd="'":+cwd:+"'";
            }
         }
         fcp.remoteCwd=cwd;
      }
   }

   formWid=_ftpclientQFormWid();
   if( formWid>0 ) {
      _ftpclientUpdateLocalSession(/*false*/);
      _ftpclientUpdateRemoteSession(false);
      if( ds_popped ) {
         // Restore last known position in tree
         typeless p = ds_popped->tree_pos;
         if( p!="" ) {
            if( formWid>0 ) {
               int remoteWid = formWid._find_control('_ctl_remote_dir');
               if( remoteWid>0 ) {
                  remoteWid._ftpRemoteRestorePos(p);
               }
            }
         }
      }
   }

   return;
}

/**
 * Callback used when changing directory and retrieving a listing.
 */
void __sftpclientDownload2CB( FtpQEvent *pEvent, typeless isPopping="" )
{
   FtpQEvent event;
   SftpDirectory dirlist;
   _str rpath,apath;
   SftpName cname;
   FtpConnProfile fcp;
   FtpConnProfile *fcp_p;
   boolean popping;

   event= *((FtpQEvent *)(pEvent));
   fcp=event.fcp;

   // Indicates that we are in the middle of popping back to the previous
   // directory. No need to do a listing.
   popping= (isPopping!="");

   typeless status=0;
   _str cwd="";
   _str msg="";

   if( _ftpQEventIsError(event) || _ftpQEventIsAbort(event) ) {
      if( !_ftpQEventIsError(event) ) {
         // User aborted
         return;
      }
      boolean do_cleanup=true;
      if( !popping ) {
         if( event.event==QE_SFTP_STAT ) {
            cwd=event.info[0];
            msg="Failed to change directory to ":+cwd:+
                "\n\nContinue?";
            status=_message_box(msg,"FTP",MB_YESNO);
            if( status==IDYES ) {
               // fcp.LocalCWD was set in __sftpclientDownload1CB(), so
               // set it back.
               fcp.localCwd=fcp.dir_stack[fcp.dir_stack._length()-1].localcwd;
               event._makeempty();
               event.fcp=fcp;
               event.event=QE_NONE;
               event.state=QS_NONE;
               event.start=0;
               // __sftpclientDownload1CB() processes the next file directory
               __sftpclientDownload1CB(&event);
               return;
            }
         }
      }
      if( do_cleanup ) {
         // Update remote and local session back to original and stop
         // Since SFTP does not support changing directory server-side,
         // all we have to do now is refresh the listing.
         if( fcp.remoteCwd!=fcp.dir_stack[0].remotecwd ) {
            _ftpclientUpdateSession(true);
         } else {
            _ftpclientUpdateSession(false);
         }
         return;
      }
   }

   if( !popping && event.event==QE_SFTP_STAT ) {
      // We just stat'ed the current working directory.
      // Now we must list its contents.
      //
      // Extract the absolute remote working directory and check to
      // be sure it is valid.
      rpath= (_str)event.info[0];
      cname= (SftpName)event.info[1];
      apath=cname.filename;
      // Check that attributes say that it is a directory
      boolean do_cleanup=false;
      if( !(cname.attrs.flags&SSH_FILEXFER_ATTR_PERMISSIONS) ) {
         msg=nls("Cannot change directory: Cannot check target");
         ftpConnDisplayError(&fcp,msg);
         do_cleanup=true;
      } else if( !S_ISDIR(cname.attrs.permissions) ) {
         // If this is a symbolic link, then attempt to download
         // as a file instead.
         FtpFile file;
         _ftpDirStackGetFile(fcp.dir_stack,file);
         if( !file._isempty() && 0!=(file.type & FTPFILETYPE_LINK) ) {
            // We created a local directory in the process of attempting
            // to download this links as a directory, so attempt to
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
            // fcp.LocalCWD was set in __sftpclientDownload1CB(), so
            // set it back.
            fcp.localCwd=fcp.dir_stack[fcp.dir_stack._length()-1].localcwd;
            event._makeempty();
            event.fcp=fcp;
            event.event=QE_NONE;
            event.state=QS_NONE;
            event.start=0;
            // Flag to override fcp.DownloadLinks
            boolean download_links = true;
            // __sftpclientDownload1CB() processes the next file directory
            __sftpclientDownload1CB(&event,download_links);
            return;
         }
         msg=nls("Cannot change directory: \"%s\" is not a directory",apath);
         ftpConnDisplayError(&fcp,msg);
         do_cleanup=true;
      }
      if( do_cleanup ) {
         // If we got here then we need to clean up after an error.
         // Since SFTP does not support changing directory server-side,
         // all we have to do now is refresh the listing.
         _ftpclientUpdateSession(true);
         return;
      }
      fcp.remoteCwd=apath;
      fcp.postedCb=(typeless)__sftpclientDownload2CB;
      _ftpIdleEnQ(QE_SFTP_DIR,QS_BEGIN,0,&fcp);
      return;
   }

   if( !popping ) {
      // We just got a directory listing
      dirlist= (SftpDirectory)event.info[0];
      status=_sftpCreateDir(&fcp,&dirlist);
      if( status ) {
         // If we got here then we need to clean up after an error.
         // Since SFTP does not support changing directory server-side,
         // all we have to do now is refresh the listing.
         _ftpclientUpdateSession(true);
         return;
      } else {
         // Refresh the remote listing so the user sees what is going on
         _ftpclientUpDownLoadRefresh(&fcp,'R');

         // Note that fcp.LocalCWD was set in __sftpclientDelRemoteFile1CB() in
         // anticipation of the push.
         _ftpDirStackPush(fcp.localCwd,fcp.remoteCwd,&fcp.remoteDir,fcp.dir_stack);
         fcp.postedCb=null;
         event._makeempty();
         event.fcp=fcp;
         event.event=QE_NONE;
         event.state=QS_NONE;
         event.start=0;
         // __sftpclientDownload1CB() processes the next file directory
         __sftpclientDownload1CB(&event);
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
      // Refresh the remote and local listing so the user sees what is going on
      _ftpclientUpDownLoadRefresh(&fcp);
      #endif
   }
   event._makeempty();
   event.fcp=fcp;
   event.event=QE_NONE;
   event.state=QS_NONE;
   event.start=0;
   // __sftpclientDownload1CB() processes the next file directory
   __sftpclientDownload1CB(&event);

   return;
}

/**
 * Callback used when popping a directory.
 */
void __sftpclientDownload3CB( FtpQEvent *pEvent )
{
   // The second argument tells __sftpclientDownload2CB() that we are
   // popping the top directory off the stack. No need to do a listing.
   __sftpclientDownload2CB(pEvent,1);

   return;
}

void __sftpclientUpload2CB( FtpQEvent *pEvent, typeless isPopping="", typeless doOverrideList="" );
void __sftpclientUpload3CB( FtpQEvent *pEvent );
void __sftpclientUpload4CB( FtpQEvent *pEvent );
void __sftpclientUpload1CB( FtpQEvent *pEvent )
{
   FtpQEvent event;
   FtpConnProfile fcp;
   FtpConnProfile *fcp_p;
   FtpSendCmd scmd;
   FtpFile file;

   event= *((FtpQEvent *)(pEvent));
   fcp=event.fcp;
   fcp.postedCb=null;

   typeless status=0;
   typeless size=0;
   _str filename="";
   _str dirname="";
   _str cwd="";
   _str msg="";
   _str src="";
   _str line="";
   _str local_path="";
   _str path="";

   if( _ftpQEventIsError(event) || _ftpQEventIsAbort(event) ) {
      // Update the local session back to original
      _ftpclientUpdateLocalSession();
      if( !_ftpQEventIsError(event) ) {
         // User aborted
         return;
      }
      // Should only get here when a PUT or MKDIR failed
      if( event.event!=QE_SFTP_PUT && event.event!=QE_SFTP_MKDIR ) return;
      if( event.event==QE_SFTP_PUT ) {
         scmd= (FtpSendCmd)event.info[0];
         msg='Failed to upload "':+scmd.src:+'"':+
             "\n\nContinue?";
      } else {
         // MKDIR failed
         dirname=event.info[0];
         msg='Failed to make directory "':+dirname:+'"':+
             "\n\nContinue?";
      }
      status=_message_box(msg,"FTP",MB_YESNO);
      if( status!=IDYES ) {
         // Update remote and local session back to original and stop
         // Since SFTP does not support changing directory server-side,
         // all we have to do now is refresh the listing.
         if( fcp.remoteCwd!=fcp.dir_stack[0].remotecwd ) {
            _ftpclientUpdateSession(true);
         } else {
            _ftpclientUpdateSession(false);
         }
         return;
      }
      // Continue with next file/directory
   }

   if( !fcp.recurseDirs && !fcp.autoRefresh ) {
      // Create "faked" entries in the remote listing that will be visible
      fcp_p=_ftpIsCurrentConnProfile(fcp.profileName,fcp.instance);
      if( fcp_p ) {
         if( !event.info._isempty() ) {
            int type=FTPFILETYPE_CREATED;
            if( event.event==QE_SFTP_PUT ) {
               scmd= (FtpSendCmd)event.info[0];
               filename=scmd.cmdargv[0];
               size=scmd.size;
            } else if( event.event==QE_SFTP_MKDIR ) {
               filename= (_str)event.info[0];
               size=0;
               type |= FTPFILETYPE_DIR;
            }
            file._makeempty();
            _ftpFakeFile(&file,filename,type,size);
            _ftpInsertFile(fcp_p,file);
         }
      }
   }

   _str filter=strip(fcp.localFileFilter);
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
            _str localcwd="";
            _str remotecwd="";
            _ftpDirStackGetLocalCwd(fcp.dir_stack,localcwd);
            _ftpDirStackGetRemoteCwd(fcp.dir_stack,remotecwd);
            if( !(file.type&FTPFILETYPE_DIR) ) {
               // File

               if( filter!=ALLFILES_RE ) {
                  // Match on the filter
                  boolean match=false;
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
               cmdargv[0]=_ftpUploadCase(&fcp,filename);
               scmd.cmdargv=cmdargv;
               scmd.datahost=scmd.dataport="";   // Ignored
               src=localcwd;
               if( last_char(src)!=FILESEP ) src=src:+FILESEP;
               src=src:+filename;
               // Double check to see if exists and to get size for progress gauge
               line=file_match('-P +V ':+maybe_quote_filename(src),1);
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
               scmd.pasv=0;   // Ignored
               scmd.xfer_type=FTPXFER_BINARY;   // Ignored
               scmd.progressCb=_ftpclientProgressCB;
               fcp.postedCb=(typeless)__sftpclientUpload1CB;

               // Members used specifically by SFTP
               scmd.hfile= -1;
               scmd.hhandle= -1;
               scmd.offset=0;
               _ftpIdleEnQ(QE_SFTP_PUT,QS_BEGIN,0,&fcp,scmd);
               return;
            } else if( file.type&FTPFILETYPE_DIR ) {
               // Directory
               local_path=localcwd;
               if( last_char(local_path)!=FILESEP ) local_path=local_path:+FILESEP;
               local_path=local_path:+filename;
               int flags=0;
               if( _ftpExists(&fcp,filename,flags) ) {
                  if( flags&FTPFILETYPE_DIR ) {
                     if( fcp.recurseDirs ) {
                        // Directory already exists, so change directory to it
                        // Set fcp.LocalCWD for the push
                        fcp.localCwd=local_path;
                        fcp.postedCb=(typeless)__sftpclientUpload2CB;
                        _ftpIdleEnQ(QE_SFTP_STAT,QS_BEGIN,0,&fcp,filename);
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
                     path=_ftpAbsolute(&fcp_temp,filename);
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
                  // __sftpclientUpload2CB() processes the MKDIR then changes directory to it
                  // Set fcp.LocalCWD for the push
                  fcp.localCwd=local_path;
                  fcp.postedCb=(typeless)__sftpclientUpload2CB;
               } else {
                  // __sftpclientUpload1CB() processes the next file/directory
                  // after the successful MKDIR.
                  fcp.postedCb=(typeless)__sftpclientUpload4CB;
               }
               _ftpIdleEnQ(QE_SFTP_MKDIR,QS_BEGIN,0,&fcp,filename);
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
         // fcp.RemoteCWD will be correct after the change directory
         // Change the listing back to previous
         fcp.remoteDir=fcp.dir_stack[fcp.dir_stack._length()-1].dir;
         // Change directory back to original directory
         cwd=fcp.dir_stack[fcp.dir_stack._length()-1].remotecwd;
         if( fcp.system==FTPSYST_MVS ) {
            if( substr(cwd,1,1)!='/' ) {
               // Make it absolute for MVS
               cwd="'":+cwd:+"'";
            }
         }
         // __sftpclientUpload3CB() processes the change directory
         fcp.postedCb=(typeless)__sftpclientUpload3CB;
         _ftpIdleEnQ(QE_SFTP_STAT,QS_BEGIN,0,&fcp,cwd);
         return;
      }
   }
   if( fcp.recurseDirs || fcp.autoRefresh ) {
      _ftpclientUpdateRemoteSession(true);
   } else {
      _ftpclientUpdateRemoteSession(false);
   }
   _ftpclientUpdateLocalSession();

   return;
}

/**
 * Callback used when changing directory and retrieving a listing.
 */
void __sftpclientUpload2CB( FtpQEvent *pEvent, 
                            typeless isPopping="", 
                            typeless doOverrideList="" )
{
   FtpQEvent event;
   SftpDirectory dirlist;
   _str rpath,apath;
   SftpName cname;
   FtpConnProfile fcp;
   FtpConnProfile *fcp_p;

   event= *((FtpQEvent *)(pEvent));
   fcp=event.fcp;

   // Indicates that we are in the middle of popping back to the previous
   // directory. No need to do a listing.
   boolean popping= (isPopping!="" && isPopping);

   // Indicates that we should override DIR on the current remote working
   // directory. Probably because the directory we changed to is known to be
   // empty because we just MKDIR'ed it.
   boolean override_list= (doOverrideList!="");

   typeless status=0;
   _str cwd="";
   _str msg="";

   if( _ftpQEventIsError(event) || _ftpQEventIsAbort(event) ) {
      if( !_ftpQEventIsError(event) ) {
         // User aborted
         return;
      }
      boolean do_cleanup=true;
      if( !popping ) {
         if( event.event==QE_SFTP_STAT ) {
            cwd=event.info[0];
            msg="Failed to change directory to ":+cwd:+
                "\n\nContinue?";
            status=_message_box(msg,"FTP",MB_YESNO);
            if( status==IDYES ) {
               // fcp.LocalCWD was set in __sftpclientUpload1CB(), so
               // set it back.
               fcp.localCwd=fcp.dir_stack[fcp.dir_stack._length()-1].localcwd;
               event._makeempty();
               event.fcp=fcp;
               event.event=QE_NONE;
               event.state=QS_NONE;
               event.start=0;
               // __sftpclientUpload1CB() processes the next file directory
               __sftpclientUpload1CB(&event);
               return;
            }
         }
      }
      if( do_cleanup ) {
         // Update remote and local session back to original and stop
         // Since SFTP does not support changing directory server-side,
         // all we have to do now is refresh the listing.
         if( fcp.remoteCwd!=fcp.dir_stack[0].remotecwd ) {
            _ftpclientUpdateSession(true);
         } else {
            _ftpclientUpdateSession(false);
         }
         return;
      }
   }

   if( event.event==QE_SFTP_MKDIR ) {
      // We just created a directory.
      // Now we must change to it.
      cwd=event.info[0];
      // __sftpclientUpload4CB() tells us not to list the directory we will
      // have changed to because it was just created and, therefore, is
      // empty.
      fcp.postedCb=(typeless)__sftpclientUpload4CB;
      _ftpIdleEnQ(QE_SFTP_STAT,QS_BEGIN,0,&fcp,cwd);
      return;
   }

   if( !popping && event.event==QE_SFTP_STAT ) {
      // We just STAT'ed the current working directory.
      //
      // Extract the absolute remote working directory and check to
      // be sure it is valid.
      rpath= (_str)event.info[0];
      cname= (SftpName)event.info[1];
      apath=cname.filename;
      // Check that attributes say that it is a directory
      boolean do_cleanup=false;
      if( !(cname.attrs.flags&SSH_FILEXFER_ATTR_PERMISSIONS) ) {
         msg=nls("Cannot change directory: Cannot check target");
         ftpConnDisplayError(&fcp,msg);
         do_cleanup=true;
      } else if( !S_ISDIR(cname.attrs.permissions) ) {
         msg=nls("Cannot change directory: \"%s\" is not a directory",apath);
         ftpConnDisplayError(&fcp,msg);
         do_cleanup=true;
      }
      if( do_cleanup ) {
         // If we got here then we need to clean up after an error.
         // Since SFTP does not support changing directory server-side,
         // all we have to do now is refresh the listing.
         _ftpclientUpdateSession(true);
         return;
      }
      fcp.remoteCwd=apath;
      if( override_list ) {
         // List was overridden. Probably because the directory we changed to
         // is known to be empty because we just MKDIR'ed it.
         //
         // Fool this callback into thinking we got a 0 byte listing.
         event.event=QE_SFTP_DIR;
         event.state=0;
         dirlist._makeempty();
         dirlist.flags=0;
         dirlist.names._makeempty();
         event.info[0]=dirlist;
         // Fall thru to list processing below
      } else {
         // Now we must list its contents.
         fcp.postedCb=(typeless)__sftpclientUpload2CB;
         _ftpIdleEnQ(QE_SFTP_DIR,QS_BEGIN,0,&fcp);
         return;
      }
   }

   if( !popping ) {
      // We just got a directory listing
      dirlist= (SftpDirectory)event.info[0];
      status=_sftpCreateDir(&fcp,&dirlist);
      if( status ) {
         // If we got here then we need to clean up after an error.
         // Since SFTP does not support changing directory server-side,
         // all we have to do now is refresh the listing.
         _ftpclientUpdateSession(true);
         return;
      } else {
         // Note that fcp.LocalCWD was set in __sftpclientUpload1CB() in
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
            // status==FILE_NOT_FOUND_RC means an empty list.
            // Set the local current working directory back to previous
            fcp.localCwd=fcp.dir_stack[fcp.dir_stack._length()-1].localcwd;
            // fcp.RemoteCWD will be set by the remote change directory
            // Set the remote directory listing back to previous
            FtpDirectory remotedirs[];
            remotedirs=(FtpDirectory [])fcp.extra;
            fcp.remoteDir=remotedirs[remotedirs._length()-1];
            // Change directory back to original directory
            cwd=fcp.dir_stack[fcp.dir_stack._length()-1].remotecwd;
            if( fcp.system==FTPSYST_MVS ) {
               if( substr(cwd,1,1)!='/' ) {
                  // Make it absolute for MVS
                  cwd="'":+cwd:+"'";
               }
            }
            // __sftpclientUpload3CB() processes the change directory
            fcp.postedCb=(typeless)__sftpclientUpload3CB;
            _ftpIdleEnQ(QE_SFTP_STAT,QS_BEGIN,0,&fcp,cwd);
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
         // __sftpclientUpload1CB() processes the next file directory
         __sftpclientUpload1CB(&event);
         return;
      }
   }

   // If we got here then we must have just finished popping back to a
   // previous directory, so process the next file directory.
   fcp.postedCb=null;
   if( fcp.dir_stack._length()>0 ) {
      // Change the local directory back to previous
      fcp.localCwd=fcp.dir_stack[fcp.dir_stack._length()-1].localcwd;
      fcp.remoteCwd=fcp.dir_stack[fcp.dir_stack._length()-1].remotecwd;
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
   // __sftpclientUpload1CB() processes the next file directory
   __sftpclientUpload1CB(&event);

   return;
}

/**
 * Callback used when popping a directory.
 */
void __sftpclientUpload3CB( FtpQEvent *pEvent )
{
   // The second argument tells __sftpclientUpload2CB() that we are
   // popping the top directory off the stack. No need to do a listing.
   __sftpclientUpload2CB(pEvent,1);

   return;
}

/**
 * Callback used when we just changed to directory that is known
 * to be empty. Probably because the directory we changed to is known to
 * be empty because we just MKDIR'ed it.
 */
void __sftpclientUpload4CB( FtpQEvent *pEvent )
{
   // The third argument tells __sftpclientUpload2CB() that we do not
   // want to do the DIR after changing directory.
   __sftpclientUpload2CB(pEvent,"",1);

   return;
}
