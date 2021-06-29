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
#import "ftp.e"
#import "ftpq.e"
#import "ftpopen.e"
#import "main.e"
#import "sftpparse.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "files.e"
#endregion


void __sftpopenCwdCB( FtpQEvent *pEvent, typeless isLink="" )
{
   FtpQEvent event;
   FtpConnProfile fcp;
   FtpConnProfile *fcp_p;
   SftpName cname;
   _str rpath,apath;
   int formWid;

   formWid = _ftpopenQFormWid();
   if( 0==formWid ) {
      // This should never happen
      return;
   }

   event= *((FtpQEvent *)(pEvent));
   fcp=event.fcp;

   is_link := ( isLink!="" && isLink );

   if( _ftpQEventIsError(event) ) {
      // Fix things up in case the user had typed a bogus path and hit ENTER
      _ftpopenUpdateSession(false);
   }

   msg := "";

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
            ftpopenOpenLinks();
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
         // We did not find the matching connection profile, so bail out
         return;
      }
      fcp_p->remoteCwd=fcp.remoteCwd;

      // _ftpopenUpdateSession() already handles asynchronous operations
      _ftpopenUpdateSession(true);
      return;
   }

   return;
}
void __sftpopenCwdLinkCB( FtpQEvent *pEvent )
{
   __sftpopenCwdCB(pEvent,true);
}

void __sftpopenUpdateSessionCB( FtpQEvent *pEvent )
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

   typeless i=0;
   typeless status=0;
   msg := "";
   temp_path := "";
   list_filename := "";

   // We just listed the contents of the current working directory.
   // Now stick it in the remote tree view.
   dirlist= (SftpDirectory)event.info[0];
   if( _ftpdebug&FTPDEBUG_SAVE_LIST ) {
      // Make a copy of the structured and raw listing
      temp_path=_temp_path();
      _maybe_append_filesep(temp_path);
      list_filename=temp_path:+"$list";
      orig_view_id := p_window_id;
      temp_view_id := 0;
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
      status=_save_file("+o "_maybe_quote_filename(list_filename));
      if( status ) {
         msg="Failed to create debug listing \""list_filename"\". status="status;
         ftpConnDisplayError(&fcp,msg);
      }
      _delete_temp_view(temp_view_id);
      p_window_id=orig_view_id;
   }
   status=_sftpCreateDir(&fcp,&dirlist);
   if( status ) return;

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
      // We did not find the matching connection profile, so bail out
      return;
   }
   fcp_p->remoteDir=fcp.remoteDir;
   fcp_p->remoteCwd=fcp.remoteCwd;

   profileWid := remoteWid := 0;
   formWid := _ftpopenQFormWid();
   if( !formWid ) return;
   if( _ftpopenFindAllControls(formWid,profileWid,remoteWid) ) {
      // This should never happen
      return;
   }
   remotecwdWid := formWid._find_control("_ctl_remote_cwd");
   if( !remotecwdWid ) return;
   noconnWid := formWid._find_control("_ctl_no_connection");
   if( !noconnWid ) return;

   cwd := "";

   _ftpopenChangeRemoteDirOnOff(0);
   status=remoteWid._ftpopenRefreshDir(fcp_p);
   _ftpopenChangeRemoteDirOnOff(1);
   if( !status ) {
      remoteWid._ftpRemoteRestorePos();
      remoteWid._ftpRemoteSavePos();
      remoteWid.p_visible=true;
      remotecwdWid.p_visible=true;
      cwd=fcp_p->remoteCwd;
      _ftpopenChangeRemoteCwdOnOff(0);
      _ftpAddCwdHist(fcp_p->cwdHist,cwd);
      remotecwdWid.p_text=cwd;
      remotecwdWid._set_sel(1,length(cwd)+1);
      _ftpopenChangeRemoteCwdOnOff(1);
      call_list('_ftpCwdHistoryAddRemove_',formWid);
   }
   noconnWid.p_visible= !remoteWid.p_visible;

   _MaybeUpdateFTPClient(profileWid.p_text);
}

void __sftpopenDelFile2CB( FtpQEvent *pEvent, typeless isPopping="" );
void __sftpopenDelFile3CB( FtpQEvent *pEvent );
void __sftpopenDelFile1CB( FtpQEvent *pEvent )
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
   cwd := "";

   if( _ftpQEventIsError(event) || _ftpQEventIsAbort(event) ) {
      // Check for "fake" file/directory
      formWid = _ftpopenQFormWid();
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
         _ftpopenUpdateSession(true);
      } else {
         _ftpopenUpdateSession(false);
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
               _ftpopenProgressCB("Deleting ":+filename,0,0);
               fcp.postedCb=(typeless)__sftpopenDelFile1CB;
               _ftpSyncEnQ(QE_SFTP_REMOVE,QS_BEGIN,0,&fcp,filename);
               return;
            } else if( file.type&FTPFILETYPE_DIR ) {
               // Directory
               if( fcp.recurseDirs ) {
                  // We are pushing another directory, so push the directory name
                  // onto the .extra stack so we know which directory to RMD after
                  // we pop it.
                  _str dirnames[];
                  dirnames= (_str [])fcp.extra;
                  dirnames[dirnames._length()]=filename;
                  fcp.extra=dirnames;
                  // __sftpopenDelFile2CB() processes the listing
                  fcp.postedCb=(typeless)__sftpopenDelFile2CB;
                  _ftpSyncEnQ(QE_SFTP_STAT,QS_BEGIN,0,&fcp,filename);
                  return;
               } else {
                  // Attempt to remove the directory
                  _ftpopenProgressCB("Deleting ":+filename,0,0);
                  fcp.postedCb=(typeless)__sftpopenDelFile1CB;
                  _ftpSyncEnQ(QE_SFTP_RMDIR,QS_BEGIN,0,&fcp,filename);
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
            fcp.postedCb=(typeless)__sftpopenDelFile3CB;
            //_message_box("__sftpopenDelFile2CB: rmdir - dirname="dirname"  RemoteCWD="fcp.RemoteCWD);
            _ftpSyncEnQ(QE_SFTP_RMDIR,QS_BEGIN,0,&fcp,dirname);
            return;
         }
      }
   }

   if( fcp.autoRefresh ) {
      _ftpopenUpdateSession(true);
   } else {
      _ftpopenUpdateSession(false);
   }

   return;
}

/**
 * Callback used when changing directory and retrieving a listing.
 */
void __sftpopenDelFile2CB( FtpQEvent *pEvent, typeless isPopping="" )
{
   FtpQEvent event;
   SftpDirectory dirlist;
   SftpName cname;
   FtpConnProfile fcp;
   FtpConnProfile *fcp_p;

   event= *((FtpQEvent *)(pEvent));
   fcp=event.fcp;

   // Indicates that we are in the middle of popping back to the previous
   // directory. No need to do a listing.
   popping := (isPopping!="" && isPopping);

   typeless status=0;
   cwd := "";
   msg := "";

   if( _ftpQEventIsError(event) || _ftpQEventIsAbort(event) ) {
      if( !_ftpQEventIsError(event) ) {
         // User aborted
         return;
      }
      do_cleanup := true;
      if( !popping ) {
         if( event.event==QE_SFTP_STAT ) {
            cwd=event.info[0];
            msg="Failed to change directory to ":+cwd:+
                "\n\nContinue?";
            status=_message_box(msg,"FTP",MB_YESNO);
            if( status==IDYES ) {
               // fcp.LocalCWD was set in __sftpopenDelFile1CB(), so
               // set it back.
               fcp.localCwd=fcp.dir_stack[fcp.dir_stack._length()-1].localcwd;
               event._makeempty();
               event.fcp=fcp;
               event.event=QE_NONE;
               event.state=QS_NONE;
               event.start=0;
               // __sftpopenDelFile1CB() processes the next file/directory
               __sftpopenDelFile1CB(&event);
               return;
            }
         }
      }
      if( do_cleanup ) {
         // If we got here then we need to clean up
         formWid := _ftpopenQFormWid();
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
            if( formWid ) _ftpopenUpdateSession(false);
         }
         return;
      }
   }

   rpath := "";
   apath := "";
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
      do_cleanup := false;
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
         _ftpopenUpdateSession(true);
         return;
      }
      fcp.remoteCwd=apath;
      fcp.postedCb=(typeless)__sftpopenDelFile2CB;
      _ftpSyncEnQ(QE_SFTP_DIR,QS_BEGIN,0,&fcp);
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
         _ftpopenUpdateSession(true);
         return;
      } else {
         // Refresh the remote listing so the user sees what is going on
         _ftpopenRefresh(&fcp);

         // Note that fcp.LocalCWD was set in __sftpopenDelFile1CB() in
         // anticipation of the push.
         _ftpDirStackPush(fcp.localCwd,fcp.remoteCwd,&fcp.remoteDir,fcp.dir_stack);
         fcp.postedCb=null;
         event._makeempty();
         event.fcp=fcp;
         event.event=QE_NONE;
         event.state=QS_NONE;
         event.start=0;
         // __sftpopenDelFile1CB() processes the next file directory
         __sftpopenDelFile1CB(&event);
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
      _ftpopenRefresh(&fcp);
   }

   // __sftpopenDelFile1CB() processes the next file directory
   __sftpopenDelFile1CB(&event);

   return;
}

/**
 * Callback used when popping a directory.
 */
void __sftpopenDelFile3CB( FtpQEvent *pEvent )
{
   // The second argument tells __sftpopenDelFile2CB() that we are
   // popping the top directory off the stack. No need to do a listing.
   __sftpopenDelFile2CB(pEvent,1);

   return;
}

void __sftpopenConnectCB( FtpQEvent *pEvent, typeless isReconnecting="" )
{
   FtpQEvent event;
   FtpConnProfile fcp;
   int formWid;
   int profileWid,operationWid,nofbytesWid;
   _str CwdHist[];
   _str rpath,apath;
   SftpName cname;
   msg := "";

   event= *((FtpQEvent *)(pEvent));
   reconnecting := ( isReconnecting!="" && isReconnecting );

   formWid = _ftpopenQFormWid();
   if( formWid ) {
      profileWid=formWid._find_control("_ctl_profile");
      operationWid=formWid._find_control("_ctl_operation");
      nofbytesWid=formWid._find_control("_ctl_nofbytes");
   }
   fcp=event.fcp;

   if( _ftpQEventIsError(event) || _ftpQEventIsAbort(event) ) {

      if( event.event == QE_SFTP_STAT ) {
         // The only thing that failed is changing directory
         rpath = (_str)event.info[0];
         if( rpath != '.' ) {
            // Try '.' for the HOME directory
            if( reconnecting ) {
               fcp.postedCb = (typeless)__sftpopenConnect2CB;
            } else {
               fcp.postedCb = (typeless)__sftpopenConnectCB;
            }
            _ftpEnQ(QE_SFTP_STAT,QS_BEGIN,0,&fcp,'.');
            return;
         }
         // Cannot even get the HOME directory, so default to root directory
         fcp.remoteCwd = '/';

         // Fall through

      } else {
         // More serious error
         operationWid.p_caption="";
         nofbytesWid.p_caption="";
         return;
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

   _ftpGetCwdHist(fcp.profileName,CwdHist);
   fcp.cwdHist=CwdHist;
   typeless htindex="";
   typeless status=_ftpAddCurrentConnProfile(&fcp,htindex);

   if( !formWid ) {
      // This could happen if user closes Project toolbar in the middle
      // of the connection attempt.
      return;
   }

   if( !reconnecting ) {
      profileWid._ftpopenFillProfiles(true);
      profileWid._ftpopenChangeProfile(htindex);
      _ftpopenUpdateSession(true);
      call_list('_ftpProfileAddRemove_',formWid);
   }

   operationWid.p_caption="Connected";
   nofbytesWid.p_caption="";
}
/**
 * Used when reconnecting a lost connection.
 */
void __sftpopenConnect2CB( FtpQEvent *pEvent )
{
   __sftpopenConnectCB(pEvent,true);
}
