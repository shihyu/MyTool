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
#include "blob.sh"
#include "vsockapi.sh"
#import "ftp.e"
#import "ftpq.e"
#import "ini.e"
#import "main.e"
#import "sftp.e"
#import "stdprocs.e"
#import "env.e"
#import "cfg.e"
#endregion

// SFTP Version
static const SFTP_VERSION= 3;

// Maximum amount can read/write in a SSH_FXP_READ/SSH_FXP_WRITE operation
static const SFTP_MAX_XFERLEN= (32*1024);

static _str SSH_COMMAND() {
   return ("ssh":+EXTENSION_EXE);
}
static int _sftpPacketPeek(FtpConnProfile *fcp_p,int type=0);


/**
 * Assemble a command line to start the ssh client according to
 * the settings stored in the connection profile.
 *
 * @param fcp_p Pointer to ftpConnProfile_t struct which is the
 *              connection profile.
 *
 * @return Command line on success, "" on error.
 */
static _str _sftpSSHClientCmdline(FtpConnProfile *fcp_p)
{
   _str ssh_exe;
   _str msg;
   _str user,host;
   _str cmdline;
   path := "";
   typeless status=0;

   ssh_exe=fcp_p->global_options.sshexe;
   if( ssh_exe=="" ) {
      // Try the bin directory
      path=get_env("VSLICKBIN1");
      _maybe_append_filesep(path);
      path :+= SSH_COMMAND();
      if( file_match('-p 'path,1)=="" ) {
         // Try the PATH
         path=path_search(SSH_COMMAND());
         if( path!="" ) {
            path=absolute(path);
            msg="The SlickEdit SFTP client requires the OpenSSH ssh client ":+
                "(or a client of equivalent functionality) to operate. If the client below is ":+
                "not the ssh client that should be used, then answer No and use the ":+
                "SSH/SFTP tab of the FTP Options dialog to specify the correct client.\n\n":+
                "Found ssh client program \"":+SSH_COMMAND():+"\" at the following location:\n\n":+
                _strip_filename(path,'N'):+"\n\n":+
                "Use this client program?";
            status=_message_box(msg,"",MB_YESNO|MB_ICONQUESTION);
            if( status!=IDYES ) {
               return("");
            }
            // User agreed to use this client, so make it the default for all
            // SFTP connection profiles.
            _plugin_set_property(VSCFGPACKAGE_FTP,VSCFGPROFILE_FTP_OPTIONS,VSCFGPROFILE_FTP_VERSION,'sshexe',path);
         }
      }
      ssh_exe=path;
   }
   if( ssh_exe=="" ) {
      return("");
   }
   // Set this here so that we do not get prompted twice about the location of
   // the ssh client program when the non-Cygwin path for SSH_ASKPASS fails the
   // first time around.
   fcp_p->global_options.sshexe=ssh_exe;
   user=fcp_p->userId;
   host=fcp_p->host;
   _str subsystem=fcp_p->global_options.sshsubsystem;
   if( subsystem=="" ) {
      // Assume the default
      subsystem="sftp";
   }
   port_option := "";
   _str port=fcp_p->port;
   if( isinteger(port) && port>0 && port <65536 ) {
      port_option=' -p 'port;
   }
   PreferredAuthentications_option := "";
   //PreferredAuthentications_option='"-oPreferredAuthentications password,publickey,hostbased"';
   switch( fcp_p->sshAuthType ) {
   case SSHAUTHTYPE_KEYBOARD_INTERACTIVE:
      PreferredAuthentications_option='"-oPreferredAuthentications keyboard-interactive"';
      break;
   case SSHAUTHTYPE_PASSWORD:
      PreferredAuthentications_option='"-oPreferredAuthentications password"';
      break;
   case SSHAUTHTYPE_PUBLICKEY:
      PreferredAuthentications_option='"-oPreferredAuthentications publickey"';
      break;
   case SSHAUTHTYPE_HOSTBASED:
      PreferredAuthentications_option='"-oPreferredAuthentications hostbased"';
      break;
   default:
      // Auto
      // Try them all in an order which should be successful in minimal time
      PreferredAuthentications_option='"-oPreferredAuthentications publickey,keyboard-interactive,password,hostbased"';
   }

   // IP version supported
   ipVersion_option := "";
   int ipVersion = _default_option(VSOPTION_IPVERSION_SUPPORTED);
   if( ipVersion == VSIPVERSION_4 ) {
      ipVersion_option = "-4";
   } else if( ipVersion == VSIPVERSION_6 ) {
      ipVersion_option = "-6";
   }

   cmdline=_maybe_quote_filename(ssh_exe);
   if( _ftpdebug&FTPDEBUG_SSH_VERBOSE ) {
      cmdline :+= " -v -v -v";
   }
   cmdline :+= ' "-oStrictHostKeyChecking no" "-oFallBackToRsh no" "-oForwardX11 no" "-oForwardAgent no" "-oClearAllForwardings yes" 'PreferredAuthentications_option' 'ipVersion_option' 'port_option' -l'user' -s "-oProtocol 2" 'host' 'subsystem;

   return(cmdline);
}

bool _sftpQTimedOut(FtpQEvent *e_p)
{
   double elapsed=((double)_time('B')-e_p->start+1)/1000;   // Seconds
   if( elapsed>=e_p->fcp.timeout ) {
      return(true);
   }

   return(false);
}

void _sftpCheckErrorsOnOff(FtpConnProfile *fcp_p,int onoff)
{
   fcp_p->ssh_checkerrors= (onoff!=0);

   return;
}
/**
 * Read off whole lines of error output from the error pipe of the ssh client.
 *
 * <p>
 * Note:<br>
 * Since only whole lines are read off, the vs-ssh-askpass: will stay on
 * the error pipe until explicitly read off by the responsible event handler,
 * unless more errors follow it.
 * </p>
 */
void _sftpCheckErrors(FtpConnProfile *fcp_p)
{
   if( !fcp_p->ssh_checkerrors ) {
      return;
   }

   //fsay('_sftpCheckErrors: in');
   int herr=fcp_p->ssh_herr;
   err_msg := "";
   // Limiting the amount of information we read off the error pipe prevents
   // a connection from running away with error output.
   typeless status=0;
   buf := "";
   len := 1024;
   while( len>2 && _PipeIsReadable(herr)>0 ) {
      // Peek for a line
      status=_PipeRead(herr,buf,len,1);
      if( status ) {
         err_msg="Error reading ssh client error pipe. status="status;
         break;
      }
      if( buf=="" ) break;
      //fsay('_sftpCheckErrors: buflen='length(buf)'  buf='buf);
#if __EBCDIC__
      p := pos('\13|\21',buf,1,'er');
#else
      p := pos('\13|\10',buf,1,'er');
#endif
      if( !p ) break;   // We want at least one whole line
      if( substr(buf,p,1)=="\015" ) ++p;   // Get the linefeed after the carriage-return too
      // An entire line is ready, so read it off
      status=_PipeRead(herr,buf,p,0);
      if( status ) {
         err_msg="Error reading ssh client error pipe. status="status;
         break;
      }
      err_msg=buf;
      len -= length(buf);
      err_msg=stranslate(err_msg,'','\13','er');
#if __EBCDIC__
      err_msg=stranslate(err_msg,'','\21','er');
#else
      err_msg=stranslate(err_msg,'','\10','er');
#endif
      if( err_msg!="" ) {
         //fsay('length(err_msg)='length(err_msg)'  err_msg='err_msg);
         fcp_p->prevStatusLine=fcp_p->lastStatusLine;
         fcp_p->lastStatusLine=err_msg;
         _ftpLog(fcp_p,err_msg);
      }
   }

   //fsay('_sftpCheckErrors: out');
   return;
}

/**
 * Drain the read end of the pipe specified by mode by reading off all
 * available data. This is useful for getting rid of errors and warnings
 * that can be safely ignored (e.g. "Could not create directory '/home/usename/.ssh'.").
 *
 * <p>
 * @param fcp_p Pointer to ftpConnProfile_t struct representing connection.
 * @param mode  0=input pipe (default), 1=err pipe
 * </p>
 */
static void _sftpDrainPipe(FtpConnProfile *fcp_p,int mode=0)
{
   _str buf,bufout;
   int hpipe;

   if( !fcp_p ) {
      return;
   }

   if( mode==0 ) {
      hpipe=fcp_p->ssh_hin;
   } else if( mode==1 ) {
      hpipe=fcp_p->ssh_herr;
   } else {
      return;
   }
   if( hpipe<0 ) {
      // Invalid pipe handle
      return;
   }

   bufout="";
   while( _PipeIsReadable(hpipe) ) {
      buf="";
      _PipeRead(hpipe,buf,0,0);
      bufout :+= buf;
   }
   if( bufout!="" ) {
      _ftpLog(fcp_p,"Ignoring messages from ssh client:");
      _ftpLog(fcp_p,bufout);
   }

   return;
}

/**
 * Determine whether an entire packet of the specified type is
 * ready to be read off the pipe.
 *
 * @param fcp_p Pointer to ftpConnProfile_t connection profile struct.
 * @param type  Packet type. Set to 0 to get the next packet on the
 *              pipe of any type.
 *
 * @return >0 packet type if packet available,
 *         =0 if packet type or no packet available,
 *         <0 on error.
 */
static int _sftpPacketPeek(FtpConnProfile *fcp_p,int type=0)
{
   int hin;
   int hblob;
   int nofbytes;
   int dlen;
   int t;

   hin=fcp_p->ssh_hin;
   hblob=_BlobAlloc(0);
   if( hblob<0 ) {
      // Error
      return(hblob);
   }
   nofbytes=_PipeReadToBlob(hblob,hin,4,1);
   if( nofbytes!=4 ) {
      _BlobFree(hblob);
      if( nofbytes<0 ) {
         // Error
         return(nofbytes);
      } else if( nofbytes<4 ) {
         // Not enough data available yet
         return(0);
      }
   }
   _BlobSetOffset(hblob,0,0);
   _BlobGetInt32(hblob,dlen,1);
   // Since we are peeking, the data is still on the pipe, so must
   // account for it by resetting offset back to 0.
   _BlobSetOffset(hblob,0,0);
   nofbytes=_PipeReadToBlob(hblob,hin,dlen+4,1);
   if( nofbytes!=(dlen+4) ) {
      _BlobFree(hblob);
      if( nofbytes<0 ) {
         // Error
         return(nofbytes);
      } else if( nofbytes<(dlen+4) ) {
         // Not enough data available yet
         return(0);
      }
   }
   _BlobSetOffset(hblob,4,0);
   _BlobGetChar(hblob,t);
   if( type!=0 && t!=type ) {
      // Correct packet is not available
      _BlobFree(hblob);
      return(0);
   }

   // Packet is ready to read off pipe
   _BlobFree(hblob);
   return(t);
}

/**
 * Get an entire packet of the specified type off the pipe and store
 * in blob. This function only retrieves packet data, not the length
 * and type. The packet type is returned. The offset into the packet
 * is set to 0 so that reading from the beginning of the packet can
 * be done right away.
 *
 * @param fcp_p   Pointer to ftpConnProfile_t connection profile struct.
 * @param type    Packet type. Set to 0 to get the next packet on the
 *                pipe of any type.
 * @param hpacket Set on return. Handle to blob that holds the packet data.
 *
 * @return >0 packet type on success,
 *         =0 if packet type or no packet available,
 *         <0 on error.
 */
static int _sftpPacketGet(FtpConnProfile *fcp_p,int type,int &hpacket)
{
   int hin;
   int nofbytes;
   int dlen;
   int t;
   int hblob;

   // Check for packet availability
   t=_sftpPacketPeek(fcp_p,type);
   if( t<=0 ) {
      return(t);
   }

   hin=fcp_p->ssh_hin;
   hblob=_BlobAlloc(0);
   if( hblob<0 ) {
      // Error
      return(hblob);
   }

   // Read off the packet length
   nofbytes=_PipeReadToBlob(hblob,hin,4,0);
   if( nofbytes!=4 ) {
      // This should never happen
      _BlobFree(hblob);
      return(ERROR_READING_FILE_RC);
   }
   _BlobSetOffset(hblob,0,0);
   _BlobGetInt32(hblob,dlen,1);
   nofbytes=_PipeReadToBlob(hblob,hin,dlen,0);
   if( nofbytes!=dlen ) {
      // This should never happen
      _BlobFree(hblob);
      return(ERROR_READING_FILE_RC);
   }
   // Read off the type
   _BlobSetOffset(hblob,4,0);
   _BlobGetChar(hblob,t);
   // Copy actual packet data (everything after the length, type)
   // into the packet we return.
   hpacket=_BlobAlloc(0);
   if( hpacket<0 ) {
      // Error
      _BlobFree(hblob);
      return(hpacket);
   }
   nofbytes=_BlobCopy(hpacket,hblob,-1);
   if( nofbytes<0 ) {
      // Error
      _BlobFree(hblob);
      _BlobFree(hpacket);
      return(nofbytes);
   }

   if( _ftpdebug&(FTPDEBUG_LOG_PROXY|FTPDEBUG_SAY_EVENTS) ) {
      _str msg;
      msg=nls("Received packet: type=%s  len=%s",t,_BlobGetLen(hpacket));
      if( _ftpdebug&FTPDEBUG_LOG_PROXY ) {
         _ftpLog(fcp_p,msg);
      }
      if( _ftpdebug&FTPDEBUG_SAY_EVENTS ) {
         say(msg);
      }
   }

   // Set offset to beginning so we can start reading from the packet right away
   _BlobSetOffset(hpacket,0,0);
   #if 0
   _BlobSetOffset(hblob,0,0);
   hfile=_FileOpen("out",1);
   _BlobWriteToFile(hblob,hfile,-1);
   _FileClose(hfile);
   #endif

   _BlobFree(hblob);

   return(t);
}

/**
 * Send an packet of the specified type to the pipe. This function
 * accepts packet data without the length and type, then creates
 * a full packet with length, type, and packet payload to send.
 *
 * <p>
 * Note:<br>
 * The caller is responsible for freeing the original packet passed in.
 * </p>
 *
 * @param fcp_p   Pointer to ftpConnProfile_t connection profile struct.
 * @param type    Packet type.
 * @param hpacket Handle to blob that holds the packet data.
 *
 * @return 0 on success, <0 on error.
 */
static int _sftpPacketSend(FtpConnProfile *fcp_p,int type,int hpacket)
{
   int hblob;
   int len;
   int nofbytes;

   len=_BlobGetLen(hpacket);
   if( len<0 ) {
      // Error
      return(len);
   }

   if( _ftpdebug&(FTPDEBUG_LOG_PROXY|FTPDEBUG_SAY_EVENTS) ) {
      _str msg;
      msg=nls("Sending packet: type=%s  len=%s",type,len);
      if( _ftpdebug&FTPDEBUG_LOG_PROXY ) {
         _ftpLog(fcp_p,msg);
      }
      if( _ftpdebug&FTPDEBUG_SAY_EVENTS ) {
         say(msg);
      }
   }

   // Allocate enough room for length, type, and packet payload
   hblob=_BlobAlloc(4+1+len);
   if( hblob<0 ) {
      // Error
      return(hblob);
   }
   // Put packet type+payload length
   _BlobPutInt32(hblob,1+len,1);
   // Put packet type
   _BlobPutChar(hblob,type);
   // Put packet payload
   _BlobSetOffset(hpacket,0,0);
   nofbytes=_BlobCopy(hblob,hpacket,len);
   if( nofbytes<0 ) {
      // Error
      _BlobFree(hblob);
      return(nofbytes);
   }
   len=_BlobGetLen(hblob);
   _BlobSetOffset(hblob,0,0);
   nofbytes=_PipeWriteFromBlob(hblob,fcp_p->ssh_hout,len);
   #if 0
   if( type==SSH_FXP_WRITE ) {
      _BlobSetOffset(hblob,0,0);
      hfile=_FileOpen("out",1);
      _BlobWriteToFile(hblob,hfile,len);
      _FileClose(hfile);
   }
   #endif
   _BlobFree(hblob);
   if( nofbytes!=len ) {
      return(ERROR_WRITING_FILE_RC);
   }

   return(0);
}

/**
 * Allocate a handle to an L-String. An L-String is an internal
 * representation of a non-ascii-z string. These strings can contain
 * any byte data including null (ascii 0). Read the L-String from the
 * handle to the packet provided, starting at current offset into the
 * packet.
 *
 * <p>
 * Explanation:<br>
 * SFTP servers will allocate "strings" of the form "\0\0\0\0",
 * which do not lend themselves to passing around without getting
 * mangled. Allocating a handle to the L-String keeps it safe from
 * mangling.
 * </p>
 *
 * <p>
 * Note:<br>
 * This function will not restore the original offset for the packet,
 * so caller is responsible for saving/restoring the original offset.
 * </p>
 *
 * @param hpacket Handle to packet data containing L-String.
 *
 * @return Handle >=0 on success, <0 on error.
 */
static int _sftpLstrAllocFromPacket(int hpacket)
{
   int handle;
   int len;

   _BlobGetInt32(hpacket,len,1);
   handle=_BlobAlloc(4+len);
   if( handle<0 ) {
      return(handle);
   }
   _BlobPutInt32(handle,len,1);
   _BlobCopy(handle,hpacket,len);

   return(handle);
}

/**
 * Retrieve the L-String referenced by hlstr and write into packet,
 * referenced by hpacket, starting at its current offset.
 *
 * @param hlstr   Abstracted handle to L-String.
 * @param hpacket Destination packet for L-String.
 *
 * @return 0 on success, <0 on error.
 */
static int _sftpLstrWriteToPacket(int hlstr,int hpacket)
{
   int offset;
   int len;

   if( hlstr<0 || hpacket<0 ) {
      return(INVALID_ARGUMENT_RC);
   }
   offset=_BlobSetOffset(hlstr,0,0);
   if( offset<0 ) {
      // Error
      return(offset);
   }
   _BlobGetInt32(hlstr,len,1);
   _BlobPutInt32(hpacket,len,1);
   _BlobCopy(hpacket,hlstr,len);

   return(0);
}

static void _sftpAttrsInit(SftpAttrs *attrs_p)
{
   attrs_p->flags=0;
   attrs_p->size=0;
   attrs_p->uid=0;
   attrs_p->gid=0;
   attrs_p->permissions=0;
   attrs_p->atime=0;
   attrs_p->mtime=0;
   attrs_p->extended_data._makeempty();

   return;
}

void _sftpQEHandler_StartConnProfile(FtpQEvent *e_p)
{
   FtpQEvent event = *e_p;   // Make a copy
   log_buf_name := "";
   typeless status=0;
   msg := "";

   // Start a connection profile
   switch( event.state ) {
   case QS_BEGIN:
      // Event begins
      //
      // Turn on error pipe checking
      _sftpCheckErrorsOnOff(&event.fcp,1);
      // Create a log buffer for this connection (if necessary).
      // If there is already a log buffer associated with this profile, then
      // it normally means that the connection is being restarted.
      if( event.fcp.logBufName=="" ) {
         log_buf_name=_ftpCreateLogBuffer();
         if( log_buf_name=="" ) {
            // Do not need a message box because _ftpCreateLogBuffer() took care of that
            msg="Cannot start connection profile: Unable to create log buffer. Connection is aborted.";
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,ERROR_OPENING_FILE_RC);
            return;
         }
         event.fcp.logBufName=log_buf_name;
         _ftpLog(&event.fcp,"*** Log started on ":+_date():+" at ":+_time('M'));
      }
      _ftpEnQ(QE_SSH_START,QS_BEGIN,0,&event.fcp);
      return;
      break;
   case QS_ERROR:
      // An error occurred setting up the connection profile to start
      _ftpDeleteLogBuffer(&event.fcp);
      _ftpQEventDisplayError(event);
      return;
      break;
   case QS_ABORT:
      // Event aborted
      _ftpDeleteLogBuffer(&event.fcp);
      return;
      break;
   case QS_END:
      // Event ends
      break;
   default:
      // Should never get here
      msg="Unknown FTP queue event state: ":+event.state:+" for event ":+event.event;
      _message_box(msg,FTP_ERRORBOX_TITLE,MB_OK|MB_ICONEXCLAMATION);
      break;
   }

   return;
}

void _sftpQEHandler_SSHStart(FtpQEvent *e_p)
{
   FtpQEvent event = *e_p;   // Make a copy
   typeless status=0;
   cmdline := "";
   msg := "";

   use_cygwin_path := false;
   if( !event.info[0]._isempty() ) {
      if( event.info._length()>0 ) {
         use_cygwin_path= (event.info[0]!="" && event.info[0]);
      }
   }

   switch( event.state ) {
   case QS_BEGIN:
      // Event begins
      //
      // Assemble the ssh client command line to shell
      cmdline=_sftpSSHClientCmdline(&event.fcp);
      if( cmdline=="" ) {
         if( event.fcp.global_options.sshexe!="" ) {
            msg='Cannot start ssh client: Cannot find ssh executable "':+event.fcp.global_options.sshexe:+'"';
         } else {
            msg='Cannot start ssh client: Cannot find ssh executable.';
            msg=msg:+
                "\n\n":+
                "The SlickEdit SFTP client requires the OpenSSH ssh client ":+
                "(or a client of equivalent functionality) to operate. Use the ":+
                "SSH/SFTP tab of the FTP Options dialog to specify the correct client.";
            if (_isUnix()) {
               msg=msg:+
                   "\n\n":+
                   "UNIX users should check if a ssh client is already available on their ":+
                   "system. If not, then download and build the source for the ssh client from ":+
                   "www.openssh.com";
            } else {
               msg=msg:+
                   "\n\n":+
                   "Windows users can obtain the ssh client by downloading and installing the ":+
                   "Cygwin package (www.cygwin.com) and making sure to choose the \"openssh\" ":+
                   "package during install.";
            }

         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,FILE_NOT_FOUND_RC);
         return;
      }
      // Need to set DISPLAY and SSH_ASKPASS env vars temporarily so that the ssh client knows to
      // use alternate vs-ssh-askpass utility for password prompting.
      _str askpass_path=editor_name('P'):+VS_SSH_ASKPASS_COMMAND;
      if( file_match('-p '_maybe_quote_filename(askpass_path),1)=="" ) {
         msg="\"":+VS_SSH_ASKPASS_COMMAND:+"\" not found";
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,FILE_NOT_FOUND_RC);
         return;
      }

      if (_isWindows()) {
         // Cygwin 1.7.2-2 (24March2010) breaks path-search when resolving
         // a path using DOS-backslash separators, so we must translate to
         // UNIX separator. Reading through their cygwin mailing list, it
         // sounds like they are aware of the problem and might get around
         // to fixing it eventually. It should be safe for us to make this
         // a permanent fix though because it is backward compatible with
         // 1.7.1.
         askpass_path = translate(askpass_path,'/','\');
      }

      if( use_cygwin_path ) {
         // Convert the SSH_ASKPASS path to a Cygwin-style path
         _str old_path=askpass_path;
         askpass_path=_path2cygwin(askpass_path);
         if( askpass_path=="" ) {
            // Error
            msg="Cannot start ssh client: Invalid Cygwin path attempting to convert \""old_path"\"";
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,PATH_NOT_FOUND_RC);
            return;
         }
      }
      old_display := get_env("DISPLAY");
      if( old_display=="" ) {
         set_env("DISPLAY",":0.0");
      }
      old_ssh_askpass := get_env("SSH_ASKPASS");
      set_env("SSH_ASKPASS",askpass_path);
      _ftpLog(&event.fcp,"Shelling SSH client...");
      if( _ftpdebug&FTPDEBUG_LOG_PROXY ) {
         _ftpLog(&event.fcp,"ssh cmdline="cmdline);
      }

      // Set VS_SSH_ASKPASS_ARGS in order to pass options to vs-ssh-askpass utility
      vs_ssh_askpass_args := "";
      // We just so happen to know that the default width x height for
      // vs-ssh-askpass is 400 x 100, so we can do a decent job of centering
      // it within the app frame.
      int x = _mdi.p_x + (_mdi.p_width - 400) intdiv 2;
      int y = _mdi.p_y + (_mdi.p_height - 100) intdiv 2;
      vs_ssh_askpass_args :+= ' --geometry 'x','y;
      // Do we have a saved password?
      plain := "";
      if( event.fcp.savePassword && event.fcp.password!="" ) {
         status=vssDecrypt(event.fcp.password,plain);
         if( status ) {
            msg="Cannot authenticate: Error retrieving password";
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
            return;
         }
      }
      if( plain!="" ) {
         vs_ssh_askpass_args :+= ' --password "'plain'"';
      }
      set_env(VS_SSH_ASKPASS_ARGS_ENVVAR,vs_ssh_askpass_args);

      hin := hout := herr := 0;
      //say('_sftpQEHandler_SSHStart: cmdline='cmdline);
      typeless hprocess=_PipeProcess(cmdline,hin,hout,herr,'H');

      // Set the env vars back so that ssh clients started in OS shells that
      // were spawned from the editor do not get messed up.

      set_env(VS_SSH_ASKPASS_ARGS_ENVVAR);

      if( old_display=="" ) {
         // Windows, so DISPLAY env var is usually not set
         set_env("DISPLAY");
      }
      if( old_ssh_askpass!="" ) {
         set_env("SSH_ASKPASS",old_ssh_askpass);
      } else {
         set_env("SSH_ASKPASS");
      }
      if( hprocess<0 ) {
         msg="Cannot start ssh client: Error running SSH client. status=":+hprocess;
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,hprocess);
         return;
      }
      event.fcp.ssh_hprocess=hprocess;
      event.fcp.ssh_hin=hin;
      event.fcp.ssh_hout=hout;
      event.fcp.ssh_herr=herr;
      //_message_box('_sftpQEHandler_SSHStart: hprocess='hprocess'  hin='hin'  hout='hout'  herr='herr);
      _ftpEnQ(QE_SFTP_INIT,QS_BEGIN,0,&event.fcp);
      return;
      break;
   case QS_ERROR:
      // An error occurred getting the ssh connection, so clean up
      _ftpDeleteLogBuffer(&event.fcp);
      _ftpQEventDisplayError(event);
      return;
      break;
   case QS_ABORT:
      // Event aborted
      _ftpDeleteLogBuffer(&event.fcp);
      return;
      break;
   case QS_END:
      // Event ends
      break;
   default:
      // Should never get here
      msg="Unknown FTP queue event state: ":+event.state:+" for event ":+event.event;
      _message_box(msg,FTP_ERRORBOX_TITLE,MB_OK|MB_ICONEXCLAMATION);
      break;
   }

   return;
}

void _sftpQEHandler_SFTPInit(FtpQEvent *e_p)
{
   FtpQEvent event;
   _str buf;
   _str LastStatusLine;
   _str PrevStatusLine;
   int hpacket;
   int status;
   msg := "";
   line := "";
   cwd := "";

   event= *e_p;   // Make a copy

   switch( event.state ) {
   case QS_BEGIN:
      // Event begins

      // Probably not necessary, but we drain the input pipe of any
      // errors/warnings so that when we try to read off the first packet (SSH_FXP_VERSION),
      // we do not try to interpret garbage.
      _sftpDrainPipe(&event.fcp,0);
      // Allocate a packet
      hpacket=_BlobAlloc(0);
      // Data payload
      _BlobPutInt32(hpacket,SFTP_VERSION,1);
      // Send the packet
      status=_sftpPacketSend(&event.fcp,SSH_FXP_INIT,hpacket);
      _BlobFree(hpacket);
      if( status ) {
         _sftpCheckErrors(&event.fcp);
         msg="Cannot initialize SFTP: Error sending SSH_FXP_INIT packet. status="status;
         line=event.fcp.lastStatusLine;
         if( line!="" ) {
            msg :+= "\n\n":+line;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_MAYBE_WAITING_FOR_PROMPT,0,&event.fcp);
      return;
      break;

   case QS_MAYBE_WAITING_FOR_PROMPT:

      // Look for the vs-ssh-askpass: prompt on stderr. That is our signal
      // that user is being prompted for password and we should wait until
      // done.

      // _sftpCheckErrors() only takes whole lines, so it will not
      // consume the prompt if we call it now.
      LastStatusLine=event.fcp.lastStatusLine;
      PrevStatusLine=event.fcp.prevStatusLine;
      _sftpCheckErrors(&event.fcp);
      buf="";
      status=_PipeRead(event.fcp.ssh_herr,buf,length(VS_SSH_ASKPASS_PROMPT),1);
      if( status ) {
         if (_isWindows()) {
            delay(100);
            if( _PipeIsProcessExited(event.fcp.ssh_hprocess) ) {
               // It is possible that, for Cygwin ssh clients, we need to Cygwin-ize
               // the path.
               _PipeCloseProcess(event.fcp.ssh_hprocess);
               msg="Trying Cygwin-style path for SSH_ASKPASS value...";
               // Check to see if we have already tried the Cygwin-ized path
               if( LastStatusLine!=msg && event.fcp.lastStatusLine!=msg &&
                   PrevStatusLine!=msg && event.fcp.prevStatusLine!=msg ) {
                  // Set LastStatusLine so we can check it in a second pass, so that
                  // we do not keep trying to reconnect forever
                  event.fcp.lastStatusLine=msg;
                  _ftpLog(&event.fcp,msg);
                  // Pass 1 to indicate we are restarting ssh with Cygwin-ized path
                  _ftpEnQ(QE_SSH_START,QS_BEGIN,0,&event.fcp,1);
                  return;
               }
            }
         }
         msg="Cannot authenticate: Error waiting for password prompt. status="status;
         if( event.fcp.lastStatusLine!="" ) {
            msg :+= "\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }
#if 0 /* DEBUG */
      if( buf!="" ) {
         say('_sftpQEHandler_SFTPInit: h1 - buf='buf);
      }
#endif
      if( buf:==VS_SSH_ASKPASS_PROMPT ) {
         // We have a password prompt, so wait until we get "vs-ssh-askpass done."
         // to signal that user has entered password.
         status=_PipeRead(event.fcp.ssh_herr,buf,length(VS_SSH_ASKPASS_PROMPT),0);
         if( status ) {
            msg="Cannot authenticate: Error retrieving password prompt. "status;
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
            return;
         }
         // Wait for "vs-ssh-askpass done." message
         _ftpEnQ(event.event,QS_WAITING_FOR_DONE,0,&event.fcp);
         return;
      }

      // If we got here, then there was no prompt, so check for SSH_FXP_VERSION packet.
      // Fall thru

   case QS_FXP_INIT_WAITING_FOR_REPLY:
      // Expecting SSH_FXP_VERSION packet

#if 0 /* DEBUG */
      if( file_match('-p out',1)=="" ) {
         hblob=_BlobAlloc(0);
         nofbytes=_PipeReadToBlob(hblob,event.fcp.ssh_hin,1024,1);
         if( nofbytes>0 ) {
            hf=_FileOpen("out",1);
            _BlobSetOffset(hblob,0,0);
            _BlobWriteToFile(hblob,hf,nofbytes);
            _FileClose(hf);
         }
         _BlobFree(hblob);
      }
#endif
      int type=_sftpPacketGet(&event.fcp,0,hpacket);
      if( type<0 ) {
         // Error
         _sftpCheckErrors(&event.fcp);
         line=event.fcp.lastStatusLine;
         msg=nls("Cannot initialize SFTP: Error waiting for SSH_FXP_VERSION packet. status=%s",type);
         if( event.fcp.lastStatusLine!="" ) {
            msg :+= "\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,type);
         return;
      }
      if( type==0 ) {

         // Packet not ready, so keep waiting

         // If all goes well, then we will not get a reply. Otherwise look
         // for a "Permission denied..." message.
         _sftpCheckErrors(&event.fcp);
         line = event.fcp.lastStatusLine;
         if( line!="" ) {
            if( substr(line,1,length("Permission denied"))=="Permission denied" ) {

               if( pos("please try again",line) ) {
                  // We only want to restart ssh if we had a saved password
                  // to begin with, since prompting would have been suppressed
                  // in vs-ssh-askpass with the --password argument.
                  if( event.fcp.savePassword && event.fcp.password!="" ) {

                     // Bad password, so retry

                     // Clear out the last status line so we do not get it again
                     // and mistakenly think the password was bad.
                     event.fcp.lastStatusLine="";
                     // Clear out the password to force a prompt
                     event.fcp.password="";
                     // Kill ssh so that we can restart with password prompting turned on
                     int pid = _PipeGetProcessPid(event.fcp.ssh_hprocess);
                     if( pid>0 ) {
                        int exit_code;
                        _kill_process_tree(pid,exit_code);
                     }
                     _ftpEnQ(QE_SSH_START,QS_BEGIN,0,&event.fcp);
                     return;
                  } else {
                     // ssh will take care of re-running vs-ssh-askpass,
                     // so fall through.
                  }

               } else {
                  // Probably ran out of retries, so bail
                  msg="Cannot authenticate: Failed to connect to "event.fcp.host".\n\n":+line;
                  _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,VSRC_FTP_CANNOT_AUTHENTICATE);
                  return;
               }
            }
            // If we got here, then it was some other error message. Probably
            // failure to run un-Cygwinized path for vs-ssh-askpass under Windows,
            // OR
            // we well through because the user needed to be re-prompted for the
            // password.
            delay(100);
            if( _PipeIsProcessExited(event.fcp.ssh_hprocess) ) {
               _sftpCheckErrors(&event.fcp);
               _PipeCloseProcess(event.fcp.ssh_hprocess);
               msg="Cannot authenticate: Received error.";
               if( event.fcp.lastStatusLine!="" ) {
                  msg :+= "\n\n":+event.fcp.lastStatusLine;
               }
               _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,VSRC_FTP_CANNOT_AUTHENTICATE);
               return;
            }
         }

         if( _sftpQTimedOut(&event) ) {
            // Timed out
            msg="Cannot initialize SFTP: Timed out waiting for SFTP server version";
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,SOCK_TIMED_OUT_RC);
            return;
         }
         _ftpReQ(event.event,QS_MAYBE_WAITING_FOR_PROMPT,event.start,&event.fcp);
         return;
      }

      // Packet is ready

      if( type!=SSH_FXP_VERSION ) {
         // Unexpected
         _BlobFree(hpacket);
         msg="Cannot initialize SFTP: Packet of type ("type") unexpected";
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,VSRC_FTP_BAD_RESPONSE);
         return;
      }
      version := 0;
      _BlobGetInt32(hpacket,version,1);
      if( version!=SFTP_VERSION ) {
         _BlobFree(hpacket);
         msg="Cannot initialize SFTP: Incompatible protocol version returned by server ("version")";
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,INVALID_ARGUMENT_RC);
         return;
      }
      _BlobFree(hpacket);
      // Hard-code the host type to UNIX
      event.fcp.system=FTPSYST_UNIX;
      // Success, now change to default remote working directory
      cwd=event.fcp.defRemoteDir;
      if( cwd=="" ) {
         cwd=".";
      }
      _ftpEnQ(QE_SFTP_STAT,QS_BEGIN,0,&event.fcp,cwd);
      return;
      break;

   case QS_WAITING_FOR_DONE:

      // Look for the "vs-ssh-askpass done." on stderr. That is our signal
      // that user has entered the password.

      // _sftpCheckErrors() only takes whole lines, so it will not
      // consume the message if we call it now.
      LastStatusLine=event.fcp.lastStatusLine;
      PrevStatusLine=event.fcp.prevStatusLine;
      _sftpCheckErrors(&event.fcp);
      buf="";
      int max_len = max( length(VS_SSH_ASKPASS_DONE), length(VS_SSH_ASKPASS_CANCELLED) );
      status=_PipeRead(event.fcp.ssh_herr,buf,max_len,1);
      if( status ) {
         msg="Cannot authenticate: Error waiting for password done message. status="status;
         if( event.fcp.lastStatusLine!="" ) {
            msg :+= "\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }
#if 0 /* DEBUG */
      if( buf!="" ) {
         say('_sftpQEHandler_SFTPInit: h2 - buf='buf);
      }
#endif
      if( substr(buf,1,length(VS_SSH_ASKPASS_DONE)):==VS_SSH_ASKPASS_DONE ) {
         // We have the "vs-ssh-askpass done." message
         status=_PipeRead(event.fcp.ssh_herr,buf,length(VS_SSH_ASKPASS_DONE),0);
         if( status ) {
            msg="Cannot authenticate: Error retrieving password done message. "status;
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
            return;
         }
         // Password might be wrong, so might get prompted again
         _ftpEnQ(event.event,QS_MAYBE_WAITING_FOR_PROMPT,0,&event.fcp);
         return;
      } else if( substr(buf,1,length(VS_SSH_ASKPASS_CANCELLED)):==VS_SSH_ASKPASS_CANCELLED ) {
         // User cancelled password dialog, so we are out of here
         _PipeRead(event.fcp.ssh_herr,buf,length(VS_SSH_ASKPASS_CANCELLED),0);
         _ftpEnQ(event.event,QS_ABORT,0,&event.fcp);
         return;
      }
      // The user could take their time typing in a password, so we will
      // wait forever. The user can always hit the Abort button if something
      // is wrong.
      _ftpEnQ(event.event,event.state,0,&event.fcp);
      break;

   case QS_ERROR:
      {
         _ftpDeleteLogBuffer(&event.fcp);
         // ssh will keep on prompting for authentication unless we kill it
         int pid = _PipeGetProcessPid(event.fcp.ssh_hprocess);
         if( pid>0 ) {
            int exit_code;
            _kill_process_tree(pid,exit_code);
         }
         //_PipeTerminateProcess(event.fcp.ssh_hprocess);
         _PipeCloseProcess(event.fcp.ssh_hprocess);
         _ftpQEventDisplayError(event);
         return;
      }
      // An error occurred sending init packet, so clean up
      break;
   case QS_ABORT:
      // Event aborted
      {
         _ftpDeleteLogBuffer(&event.fcp);
         // ssh will keep on prompting for authentication unless we kill it
         int pid = _PipeGetProcessPid(event.fcp.ssh_hprocess);
         if( pid>0 ) {
            int exit_code;
            _kill_process_tree(pid,exit_code);
         }
         //_PipeTerminateProcess(event.fcp.ssh_hprocess);
         _PipeCloseProcess(event.fcp.ssh_hprocess);
         return;
      }
      break;
   case QS_END:
      // Event ends
      break;
   default:
      // Should never get here
      msg="Unknown FTP queue event state: ":+event.state:+" for event ":+event.event;
      _message_box(msg,FTP_ERRORBOX_TITLE,MB_OK|MB_ICONEXCLAMATION);
      break;
   }

   return;
}

void _sftpQEHandler_Stat(FtpQEvent *e_p)
{
   FtpQEvent event;
   _str rpath,apath;
   // Canonical name structure returned when event finishes
   SftpName cname;
   SftpAttrs attrs;
   int hpacket;
   int status;
   int err_code;
   _str err_msg;
   SftpName names[];

   event= *e_p;   // Make a copy

   msg := "";
   line := "";

   rpath="";
   if( event.info._length()>0 ) {
      rpath=event.info[0];
   }
   cname._makeempty();
   if( event.info._length()>1 ) {
      cname= (SftpName)event.info[1];
   }

   switch( event.state ) {
   case QS_BEGIN:
      // Event begins
      if( rpath=="" ) {
         msg=nls("Cannot stat \"%s\"",rpath);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,INVALID_ARGUMENT_RC);
         return;
      } else {
         if( rpath=="." && event.fcp.remoteCwd=="" ) {
            // User wants the initial current directory
         } else {
            // Relative to what we say the current working directory is
            rpath=_ftpAbsolute(&event.fcp,rpath);
         }
      }
      // Allocate a packet
      hpacket=_BlobAlloc(0);
      // Data payload
      _BlobPutInt32(hpacket,_sftpNextOpId(&event.fcp),1);
      _BlobPutInt32(hpacket,length(rpath),1);
      _BlobPutString(hpacket,rpath);
      // Send the packet
      status=_sftpPacketSend(&event.fcp,SSH_FXP_REALPATH,hpacket);
      _BlobFree(hpacket);
      if( status ) {
         _sftpCheckErrors(&event.fcp);
         msg=nls("Cannot stat \"%s\": Error sending SSH_FXP_REALPATH packet. status=%s",rpath,status);
         line=event.fcp.lastStatusLine;
         if( line!="" ) {
            msg :+= "\n\n":+line;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_FXP_NAME_WAITING_FOR_REPLY,0,&event.fcp,rpath,cname);
      return;
      break;
   case QS_FXP_NAME_WAITING_FOR_REPLY:
      // Expecting SSH_FXP_NAME packet
      int type=_sftpPacketGet(&event.fcp,0,hpacket);
      if( type<0 ) {
         // Error
         _sftpCheckErrors(&event.fcp);
         line=event.fcp.lastStatusLine;
         msg=nls("Cannot stat \"%s\": Error waiting for SSH_FXP_NAME packet. status=%s",rpath,type);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,type);
         return;
      }
      if( type==0 ) {
         // Packet not ready, so keep waiting
         if( _sftpQTimedOut(&event) ) {
            // Timed out
            msg=nls("Cannot stat \"%s\": Timed out waiting for current working directory",rpath);
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,SOCK_TIMED_OUT_RC);
            return;
         }
         _ftpReQ(event.event,event.state,event.start,&event.fcp,rpath,cname);
         return;
      }
      // Packet is ready
      if( type!=SSH_FXP_NAME ) {
         if( type==SSH_FXP_STATUS ) {
            id := 0;
            status=_sftpPacketParseStatus(hpacket,id,err_code,err_msg);
            _BlobFree(hpacket);
            if( status ) {
               msg=nls("Cannot stat \"%s\": Unable to parse the SSH_FXP_STATUS packet. status=%s",rpath,status);
               _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
               return;
            }
            msg=nls("Cannot stat \"%s\": Unable to canonicalize the path",rpath);
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,VSRC_FTP_CANNOT_STAT);
            return;
         }
         // Unexpected
         _BlobFree(hpacket);
         msg=nls("Cannot stat \"%s\": Packet of type (%s) unexpected",rpath,type);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,VSRC_FTP_BAD_RESPONSE);
         return;
      }
      // Only 1 name to parse out, the canonical name
      names._makeempty();
      id := 0;
      status=_sftpPacketParseName(hpacket,id,names);
      if( status ) {
         _BlobFree(hpacket);
         msg=nls("Cannot stat \"%s\": Unable to parse the SSH_FXP_NAME packet. status=%s",rpath,status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }
      if( names._length()<1 ) {
         _BlobFree(hpacket);
         msg=nls("Cannot stat \"%s\": Cannot check target",rpath);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,VSRC_FTP_CANNOT_STAT);
         return;
      }
      _BlobFree(hpacket);
      // Success
      // Set absolute path information in sftpName_t structure.
      // The attributes are empty in this SSH_FXP_NAME packet, so must get
      // them with a SSH_FXP_STAT operation.
      cname.filename=names[0].filename;
      cname.longname=names[0].longname;
      // Allocate a packet
      hpacket=_BlobAlloc(0);
      // Data payload
      _BlobPutInt32(hpacket,_sftpNextOpId(&event.fcp),1);
      _BlobPutInt32(hpacket,length(cname.filename),1);
      _BlobPutString(hpacket,cname.filename);
      // Send the packet
      status=_sftpPacketSend(&event.fcp,SSH_FXP_STAT,hpacket);
      _BlobFree(hpacket);
      if( status ) {
         _sftpCheckErrors(&event.fcp);
         msg=nls("Cannot stat \"%s\": Error sending SSH_FXP_STAT packet. status=%s",rpath,status);
         line=event.fcp.lastStatusLine;
         if( line!="" ) {
            msg :+= "\n\n":+line;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_FXP_ATTRS_WAITING_FOR_REPLY,0,&event.fcp,rpath,cname);
      return;
      break;
   case QS_FXP_ATTRS_WAITING_FOR_REPLY:
      // Expecting SSH_FXP_ATTRS packet
      type=_sftpPacketGet(&event.fcp,0,hpacket);
      if( type<0 ) {
         // Error
         _sftpCheckErrors(&event.fcp);
         line=event.fcp.lastStatusLine;
         msg=nls("Cannot stat \"%s\": Error waiting for SSH_FXP_ATTRS packet. status=%s",rpath,type);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,type);
         return;
      }
      if( type==0 ) {
         // Packet not ready, so keep waiting
         if( _sftpQTimedOut(&event) ) {
            // Timed out
            msg=nls("Cannot stat \"%s\": Timed out waiting for current working directory",rpath);
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,SOCK_TIMED_OUT_RC);
            return;
         }
         _ftpReQ(event.event,event.state,event.start,&event.fcp,rpath,cname);
         return;
      }
      // Packet is ready
      if( type!=SSH_FXP_ATTRS ) {
         if( type==SSH_FXP_STATUS ) {
            status=_sftpPacketParseStatus(hpacket,id,err_code,err_msg);
            _BlobFree(hpacket);
            if( status ) {
               msg=nls("Cannot stat \"%s\": Unable to parse the SSH_FXP_STATUS packet. status=%s",rpath,status);
               _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
               return;
            }
            msg=nls("Cannot stat \"%s\": Unable to canonicalize the path",rpath);
            msg :+= "\n\n("err_code") "err_msg;
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,VSRC_FTP_CANNOT_STAT);
            return;
         }
         // Unexpected
         _BlobFree(hpacket);
         msg=nls("Cannot stat \"%s\": Packet of type (%s) unexpected",rpath,type);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,VSRC_FTP_BAD_RESPONSE);
         return;
      }
      // Check that attributes say that it is a directory
      attrs._makeempty();
      status=_sftpPacketParseAttrs(hpacket,id,&attrs);
      _BlobFree(hpacket);
      if( status ) {
         msg=nls("Cannot stat \"%s\": Unable to parse the SSH_FXP_ATTRS packet. status=%s",rpath,status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }
      // Success
      // Set and return the sftpName_t structure containing stat info
      cname.attrs=attrs;
      _ftpEnQ(event.event,QS_END,0,&event.fcp,rpath,cname);
      return;
      break;
   case QS_ERROR:
      // An error occurred with stat
      _ftpQEventDisplayError(event);
      return;
      break;
   case QS_ABORT:
      // Event aborted
      return;
      break;
   case QS_END:
      // Event ends
      break;
   default:
      // Should never get here
      msg="Unknown FTP queue event state: ":+event.state:+" for event ":+event.event;
      _message_box(msg,FTP_ERRORBOX_TITLE,MB_OK|MB_ICONEXCLAMATION);
      break;
   }

   return;
}

void _sftpQEHandler_Dir(FtpQEvent *e_p)
{
   FtpQEvent event;
   SftpAttrs attrs;
   SftpDirectory dirlist;
   SftpName templist[];
   int len;
   // The SFTP server's idea of a string handle is "\0\0\0\0" which
   // does not lend itself to being passed around without getting
   // mangled, so we use a indirect handle to the handle.
   int hhandle;
   int i;

   event= *e_p;   // Make a copy

   dirlist._makeempty();
   templist._makeempty();
   hhandle= -1;
   if( !event.info[0]._isempty() ) {
      if( event.info._length()>0 ) {
         dirlist= (SftpDirectory)event.info[0];
      }
      if( event.info._length()>1 ) {
         hhandle=event.info[1];
      }
   }

   attrs._makeempty();

   typeless hpacket=0;
   typeless status=0;
   typeless line=0;
   typeless type=0;
   typeless id=0;
   typeless err_code=0;
   typeless err_msg='';
   msg := "";

   switch( event.state ) {
   case QS_BEGIN:
      // Event begins
      //
      // Send a SSH_FXP_OPENDIR packet to open a directory for reading
      //
      // Allocate a packet
      hpacket=_BlobAlloc(0);
      // Data payload
      _BlobPutInt32(hpacket,_sftpNextOpId(&event.fcp),1);
      _BlobPutInt32(hpacket,length(event.fcp.remoteCwd),1);
      _BlobPutString(hpacket,event.fcp.remoteCwd);
      status=_sftpPacketSend(&event.fcp,SSH_FXP_OPENDIR,hpacket);
      _BlobFree(hpacket);
      if( status ) {
         _sftpCheckErrors(&event.fcp);
         line=event.fcp.lastStatusLine;
         msg="Cannot list directory: Error sending SSH_FXP_OPENDIR packet. status="status;
         if( line!="" ) {
            msg :+= "\n\n":+line;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_FXP_HANDLE_WAITING_FOR_REPLY,0,&event.fcp,dirlist,hhandle);
      return;
      break;
   case QS_FXP_HANDLE_WAITING_FOR_REPLY:
      // Expecting SSH_FXP_HANDLE packet
      type=_sftpPacketGet(&event.fcp,0,hpacket);
      if( type<0 ) {
         // Error
         _sftpCheckErrors(&event.fcp);
         line=event.fcp.lastStatusLine;
         msg=nls("Cannot list directory: Error waiting for SSH_FXP_HANDLE packet. status=%s",type);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,type);
         return;
      }
      if( type==0 ) {
         // Packet not ready, so keep waiting
         if( _sftpQTimedOut(&event) ) {
            // Timed out
            msg="Cannot list directory: Timed out waiting for directory handle";
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,SOCK_TIMED_OUT_RC);
            return;
         }
         _ftpReQ(event.event,event.state,event.start,&event.fcp,dirlist,hhandle);
         return;
      }
      // Packet is ready
      if( type!=SSH_FXP_HANDLE ) {
         if( type==SSH_FXP_STATUS ) {
            status=_sftpPacketParseStatus(hpacket,id,err_code,err_msg);
            _BlobFree(hpacket);
            if( status ) {
               msg="Cannot list directory: Unable to parse the SSH_FXP_STATUS packet. status="status;
               _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
               return;
            }
            msg="Cannot list directory: Error opening \""event.fcp.remoteCwd"\"";
            msg :+= "\n\n("err_code") "err_msg;
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,-1);
            return;
         }
         // Unexpected
         _BlobFree(hpacket);
         msg="Cannot list directory: Packet of type ("type") unexpected";
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,VSRC_FTP_BAD_RESPONSE);
         return;
      }
      // Skip over id
      _BlobSetOffset(hpacket,4,0);
      // Get the handle
      // Create the indirect handle to the handle, so that we can pass
      // it around without it getting mangled.
      hhandle=_sftpLstrAllocFromPacket(hpacket);
      if( hhandle<0 ) {
         // Error
         _BlobFree(hpacket);
         msg="Cannot list directory: Error allocating handle to handle. status="hhandle;
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,hhandle);
         return;
      }
      #if 0
      fsay('1 handle_len='handle_len'  handle='handle);
      _BlobSetOffset(hpacket,4,0);
      hfile=_FileOpen("out1",1);
      _BlobWriteToFile(hpacket,hfile,-1);
      _FileClose(hfile);
      #endif
      _BlobFree(hpacket);
      // Success, now start reading the contents of the directory
      // Fall through
   case QS_FXP_READDIR:
      // Issue a SSH_FXP_READDIR packet to get more directory entries
      //
      // Allocate a packet
      hpacket=_BlobAlloc(0);
      // Data payload
      _BlobPutInt32(hpacket,_sftpNextOpId(&event.fcp),1);
      // Fetch the string handle from the indirected handle into the packet
      _sftpLstrWriteToPacket(hhandle,hpacket);
      // Send the packet
      status=_sftpPacketSend(&event.fcp,SSH_FXP_READDIR,hpacket);
      _BlobFree(hpacket);
      if( status ) {
         _BlobFree(hhandle);
         _sftpCheckErrors(&event.fcp);
         msg="Cannot list directory: Error sending SSH_FXP_READDIR packet. status="status;
         line=event.fcp.lastStatusLine;
         if( line!="" ) {
            msg :+= "\n\n":+line;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_FXP_NAME_WAITING_FOR_REPLY,0,&event.fcp,dirlist,hhandle);
      return;
      break;
   case QS_FXP_NAME_WAITING_FOR_REPLY:
      // Expecting SSH_FXP_NAME packet
      type=_sftpPacketGet(&event.fcp,0,hpacket);
      if( type<0 ) {
         // Error
         _BlobFree(hhandle);
         _sftpCheckErrors(&event.fcp);
         line=event.fcp.lastStatusLine;
         msg=nls("Cannot list directory: Error waiting for SSH_FXP_NAME packet. status=%s",type);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,type);
         return;
      }
      if( type==0 ) {
         // Packet not ready, so keep waiting
         if( _sftpQTimedOut(&event) ) {
            // Timed out
            _BlobFree(hhandle);
            msg="Cannot list directory: Timed out waiting for current working directory";
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,SOCK_TIMED_OUT_RC);
            return;
         }
         _ftpReQ(event.event,event.state,event.start,&event.fcp,dirlist,hhandle);
         return;
      }
      // Packet is ready
      if( type!=SSH_FXP_NAME ) {
         if( type==SSH_FXP_STATUS ) {
            status=_sftpPacketParseStatus(hpacket,id,err_code,err_msg);
            _BlobFree(hpacket);
            if( status ) {
               _BlobFree(hhandle);
               msg="Cannot list directory: Unable to parse the SSH_FXP_STATUS packet. status="status;
               _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
               return;
            }
            if( err_code==SSH_FX_EOF ) {
               // No more files in the directory, so we are done
               // Allocate a packet
               hpacket=_BlobAlloc(0);
               // Data payload
               _BlobPutInt32(hpacket,_sftpNextOpId(&event.fcp),1);
               _sftpLstrWriteToPacket(hhandle,hpacket);
               // Send the packet
               status=_sftpPacketSend(&event.fcp,SSH_FXP_CLOSE,hpacket);
               _BlobFree(hpacket);
               if( status ) {
                  _BlobFree(hhandle);
                  _sftpCheckErrors(&event.fcp);
                  msg="Cannot list directory: Error sending SSH_FXP_CLOSE packet. status="status;
                  line=event.fcp.lastStatusLine;
                  if( line!="" ) {
                     msg :+= "\n\n":+line;
                  }
                  _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
                  return;
               }
               _BlobFree(hhandle);
               hhandle= -1;
               _ftpEnQ(event.event,QS_FXP_STATUS_WAITING_FOR_REPLY,0,&event.fcp,dirlist,hhandle);
               return;
            }
            _BlobFree(hhandle);
            msg="Cannot list directory: Error reading \""event.fcp.remoteCwd"\"";
            msg :+= "\n\n("err_code") "err_msg;
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,-1);
            return;
         }
         // Unexpected
         _BlobFree(hhandle);
         _BlobFree(hpacket);
         msg="Cannot list directory: Packet of type ("type") unexpected";
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,VSRC_FTP_BAD_RESPONSE);
         return;
      }
      // Check that attributes say it is a directory
      status=_sftpPacketParseName(hpacket,id,templist);
      _BlobFree(hpacket);
      if( status ) {
         _BlobFree(hhandle);
         msg="Cannot list directory: Unable to parse the SSH_FXP_NAME packet. status="status;
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }
      // Add them to the ongoing directory listing
      for( i=0;i<templist._length();++i ) {
         //say('templist['i'].filename='templist[i].filename'  mtime='templist[i].attrs.mtime);
         dirlist.names[dirlist.names._length()]=templist[i];
      }
      // Success, now get more directory entries
      _ftpEnQ(event.event,QS_FXP_READDIR,0,&event.fcp,dirlist,hhandle);
      return;
      break;
   case QS_FXP_STATUS_WAITING_FOR_REPLY:
      // Expecting SSH_FXP_STATUS packet
      type=_sftpPacketGet(&event.fcp,0,hpacket);
      if( type<0 ) {
         // Error
         _sftpCheckErrors(&event.fcp);
         line=event.fcp.lastStatusLine;
         msg=nls("Cannot list directory: Error waiting for SSH_FXP_STATUS packet. status=%s",type);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,type);
         return;
      }
      if( type==0 ) {
         // Packet not ready, so keep waiting
         if( _sftpQTimedOut(&event) ) {
            // Timed out
            msg="Cannot list directory: Timed out waiting for close";
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,SOCK_TIMED_OUT_RC);
            return;
         }
         _ftpReQ(event.event,event.state,event.start,&event.fcp,dirlist,hhandle);
         return;
      }
      // Packet is ready
      if( type!=SSH_FXP_STATUS ) {
         // Unexpected
         _BlobFree(hpacket);
         msg="Cannot list directory: Packet of type ("type") unexpected";
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,VSRC_FTP_BAD_RESPONSE);
         return;
      }
      status=_sftpPacketParseStatus(hpacket,id,err_code,err_msg);
      _BlobFree(hpacket);
      if( status ) {
         msg="Cannot list directory: Unable to parse the SSH_FXP_STATUS packet. status="status;
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }
      if( err_code!=SSH_FX_OK ) {
         // Error closing directory listing
         msg="Cannot list directory: Unable to close";
         msg :+= "\n\n("err_code") "err_msg;
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,-1);
         return;
      }
      // Success
      _ftpEnQ(event.event,QS_END,0,&event.fcp,dirlist,hhandle);
      return;
      break;
   case QS_ERROR:
      // An error occurred with CWD
      _ftpQEventDisplayError(event);
      return;
      break;
   case QS_ABORT:
      // Event aborted
      return;
      break;
   case QS_END:
      // Event ends
      //
      // Free the handle to handle
      if( hhandle>=0 ) {
         _BlobFree(hhandle);
      }
      break;
   default:
      // Should never get here
      msg="Unknown FTP queue event state: ":+event.state:+" for event ":+event.event;
      _message_box(msg,FTP_ERRORBOX_TITLE,MB_OK|MB_ICONEXCLAMATION);
      break;
   }

   return;
}

void _sftpQEHandler_Get(FtpQEvent *e_p)
{
   FtpQEvent event;
   FtpRecvCmd rcmd;
   SftpAttrs attrs;
   // Relative path requested
   _str rpath;
   // Canonacalized absolute path derived from rpath
   _str apath;
   int len;
   // The SFTP server's idea of a string handle is "\0\0\0\0" which
   // does not lend itself to being passed around without getting
   // mangled, so we use a indirect handle to the handle.
   int hhandle;
   int hfile;
   int i;

   event= *e_p;   // Make a copy

   rcmd= (FtpRecvCmd)event.info[0];   // This is not optional
   rpath=rcmd.cmdargv[0];
   hfile= -1;
   if( rcmd.hfile._varformat()!=VF_EMPTY ) {
      hfile=rcmd.hfile;
   }
   hhandle= -1;
   if( rcmd.hhandle._varformat()!=VF_EMPTY ) {
      hhandle=rcmd.hhandle;
   }

   typeless hpacket=0;
   typeless status=0;
   typeless line=0;
   typeless type=0;
   typeless id=0;
   typeless err_code=0;
   typeless err_msg='';
   typeless offset=0;
   msg := "";

   switch( event.state ) {
   case QS_BEGIN:
      // Event begins
      //
      // Figure out the absolute path to open
      apath=_ftpAbsolute(&event.fcp,rpath);
      // No attributes for open
      _sftpAttrsInit(&attrs);
      // Send a SSH_FXP_OPEN packet to open a file for reading
      //
      // Allocate a packet
      hpacket=_BlobAlloc(0);
      // Data payload
      _BlobPutInt32(hpacket,_sftpNextOpId(&event.fcp),1);
      _BlobPutInt32(hpacket,length(apath),1);
      _BlobPutString(hpacket,apath);
      _BlobPutInt32(hpacket,SSH_FXF_READ,1);
      _sftpPacketPutAttrs(hpacket,&attrs);
      status=_sftpPacketSend(&event.fcp,SSH_FXP_OPEN,hpacket);
      _BlobFree(hpacket);
      if( status ) {
         _sftpCheckErrors(&event.fcp);
         line=event.fcp.lastStatusLine;
         msg=nls("Cannot open file %s: Error sending SSH_FXP_OPEN packet. status=%s",rpath,status);
         if( line!="" ) {
            msg :+= "\n\n":+line;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_FXP_HANDLE_WAITING_FOR_REPLY,0,&event.fcp,rcmd);
      return;
      break;
   case QS_FXP_HANDLE_WAITING_FOR_REPLY:
      // Expecting SSH_FXP_HANDLE packet
      type=_sftpPacketGet(&event.fcp,0,hpacket);
      if( type<0 ) {
         // Error
         _sftpCheckErrors(&event.fcp);
         line=event.fcp.lastStatusLine;
         msg=nls("Cannot open file %s: Error waiting for SSH_FXP_HANDLE packet. status=%s",rpath,type);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,type);
         return;
      }
      if( type==0 ) {
         // Packet not ready, so keep waiting
         if( _sftpQTimedOut(&event) ) {
            // Timed out
            msg=nls("Cannot open file %s: Timed out waiting for handle",rpath);
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,SOCK_TIMED_OUT_RC);
            return;
         }
         _ftpReQ(event.event,event.state,event.start,&event.fcp,rcmd);
         return;
      }
      // Packet is ready
      if( type!=SSH_FXP_HANDLE ) {
         if( type==SSH_FXP_STATUS ) {
            status=_sftpPacketParseStatus(hpacket,id,err_code,err_msg);
            _BlobFree(hpacket);
            if( status ) {
               msg=nls("Cannot open file %s: Unable to parse the SSH_FXP_STATUS packet. status=%s",rpath,status);
               _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
               return;
            }
            msg=nls("Cannot open file %s: Received SSH_FXP_STATUS packet",rpath);
            msg :+= "\n\n("err_code") "err_msg;
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,ERROR_OPENING_FILE_RC);
            return;
         }
         // Unexpected
         _BlobFree(hpacket);
         msg=nls("Cannot open file %s: Packet of type (%s) unexpected",rpath,type);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,VSRC_FTP_BAD_RESPONSE);
         return;
      }
      // Skip over id
      _BlobSetOffset(hpacket,4,0);
      // Get the handle
      // Create the indirect handle to the handle, so that we can pass
      // it around without it getting mangled.
      hhandle=_sftpLstrAllocFromPacket(hpacket);
      _BlobFree(hpacket);
      if( hhandle<0 ) {
         // Error
         msg=nls("Cannot open file %s: Error allocating handle to handle. status=%s",rpath,hhandle);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,hhandle);
         return;
      }
      // Success
      // Assign the SFTP handle to the structure so we can pass it to events easily (and clean up easily)
      rcmd.hhandle=hhandle;
      // Now get the attributes on the open file so that we can know the size
      // and update the progress gauge.
      //
      // Allocate a packet
      hpacket=_BlobAlloc(0);
      // Data payload
      _BlobPutInt32(hpacket,_sftpNextOpId(&event.fcp),1);
      // Fetch the string handle from the indirected handle into the packet
      _sftpLstrWriteToPacket(hhandle,hpacket);
      // Send the packet
      status=_sftpPacketSend(&event.fcp,SSH_FXP_FSTAT,hpacket);
      _BlobFree(hpacket);
      if( status ) {
         _sftpCheckErrors(&event.fcp);
         msg=nls("Cannot open file %s: Error sending SSH_FXP_FSTAT packet. status=%s",rpath,status);
         line=event.fcp.lastStatusLine;
         if( line!="" ) {
            msg :+= "\n\n":+line;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
         return;
      }
      // Fall through
      event.state=QS_FXP_ATTRS_WAITING_FOR_REPLY;
   case QS_FXP_ATTRS_WAITING_FOR_REPLY:
      // Expecting SSH_FXP_ATTRS packet
      type=_sftpPacketGet(&event.fcp,0,hpacket);
      if( type<0 ) {
         // Error
         _sftpCheckErrors(&event.fcp);
         line=event.fcp.lastStatusLine;
         msg=nls("Cannot open file %s: Error waiting for SSH_FXP_ATTRS packet. status=%s",rpath,type);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,type);
         return;
      }
      if( type==0 ) {
         // Packet not ready, so keep waiting
         if( _sftpQTimedOut(&event) ) {
            // Timed out
            msg=nls("Cannot open file %s: Timed out waiting for SSH_FXP_ATTRS",rpath);
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,SOCK_TIMED_OUT_RC);
            return;
         }
         _ftpReQ(event.event,event.state,event.start,&event.fcp,rcmd);
         return;
      }
      // Packet is ready
      if( type!=SSH_FXP_ATTRS ) {
         if( type==SSH_FXP_STATUS ) {
            status=_sftpPacketParseStatus(hpacket,id,err_code,err_msg);
            _BlobFree(hpacket);
            if( status ) {
               msg=nls("Cannot open file %s: Unable to parse the SSH_FXP_STATUS packet. status=%s",rpath,status);
               _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
               return;
            }
            msg=nls("Cannot open file %s: Unable to stat the path",rpath);
            msg :+= "\n\n("err_code") "err_msg;
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,VSRC_FTP_CANNOT_STAT);
            return;
         }
         // Unexpected
         _BlobFree(hpacket);
         msg=nls("Cannot open file %s: Packet of type (%s) unexpected",rpath,type);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,VSRC_FTP_BAD_RESPONSE);
         return;
      }
      attrs._makeempty();
      status=_sftpPacketParseAttrs(hpacket,id,&attrs);
      _BlobFree(hpacket);
      if( status ) {
         msg=nls("Cannot open file %s: Unable to parse the SSH_FXP_ATTRS packet. status=%s",rpath,status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
         return;
      }
      rcmd.size = attrs.size;
      //_message_box('rcmd.size='rcmd.size);
      // Open a file to accept the transfer. File is opened and truncated.
      hfile=_FileOpen(rcmd.dest,1);
      if( hfile<0 ) {
         // Error
         msg=nls("Cannot open file %s: Error creating local destination file \"%s\". status=%s",rpath,rcmd.dest,hfile);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,hfile);
         return;
      }
      rcmd.hfile=hfile;
      // Start reading the contents of the file starting at offset=0
      rcmd.offset=0;
      // Fall through
   case QS_FXP_READ:
      // Issue a SSH_FXP_READ packet to get more of the file
      //
      // File offset at which to start reading
      offset=rcmd.offset;
      // Length to read
      len=SFTP_MAX_XFERLEN;
      // Allocate a packet
      hpacket=_BlobAlloc(0);
      // Data payload
      _BlobPutInt32(hpacket,_sftpNextOpId(&event.fcp),1);
      // Fetch the string handle from the indirected handle into the packet
      _sftpLstrWriteToPacket(hhandle,hpacket);
      // Offset
      _BlobPutInt64(hpacket,offset,1);
      // Length to read
      _BlobPutInt32(hpacket,len,1);
      // Send the packet
      status=_sftpPacketSend(&event.fcp,SSH_FXP_READ,hpacket);
      _BlobFree(hpacket);
      if( status ) {
         _sftpCheckErrors(&event.fcp);
         msg=nls("Cannot open file %s: Error sending SSH_FXP_READ packet. status=%s",rpath,status);
         line=event.fcp.lastStatusLine;
         if( line!="" ) {
            msg :+= "\n\n":+line;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_FXP_DATA_WAITING_FOR_REPLY,0,&event.fcp,rcmd);
      return;
      break;
   case QS_FXP_DATA_WAITING_FOR_REPLY:
      // Expecting SSH_FXP_DATA packet
      type=_sftpPacketGet(&event.fcp,0,hpacket);
      if( type<0 ) {
         // Error
         _sftpCheckErrors(&event.fcp);
         line=event.fcp.lastStatusLine;
         msg=nls("Cannot open file %s: Error waiting for SSH_FXP_DATA packet. status=%s",rpath,type);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,type);
         return;
      }
      if( type==0 ) {
         // Packet not ready, so keep waiting
         if( _sftpQTimedOut(&event) ) {
            // Timed out
            msg=nls("Cannot open file %s: Timed out waiting for SSH_FXP_DATA packet",rpath);
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,SOCK_TIMED_OUT_RC);
            return;
         }
         _ftpReQ(event.event,event.state,event.start,&event.fcp,rcmd);
         return;
      }
      // Packet is ready
      if( type!=SSH_FXP_DATA ) {
         if( type==SSH_FXP_STATUS ) {
            status=_sftpPacketParseStatus(hpacket,id,err_code,err_msg);
            _BlobFree(hpacket);
            if( status ) {
               msg=nls("Cannot open file %s: Unable to parse the SSH_FXP_STATUS packet. status=%s",rpath,status);
               _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
               return;
            }
            if( err_code==SSH_FX_EOF ) {
               // No more to read
               //
               // Update the progress gauge
               if( rcmd.progressCb ) {
                  line="Receiving "rpath;
                  (*rcmd.progressCb)(line,rcmd.size,rcmd.size);
               }
               // Close the local destination file
               _FileClose(hfile);
               rcmd.hfile= -1;
               // Allocate a packet
               hpacket=_BlobAlloc(0);
               // Data payload
               _BlobPutInt32(hpacket,_sftpNextOpId(&event.fcp),1);
               _sftpLstrWriteToPacket(hhandle,hpacket);
               // Send the packet
               status=_sftpPacketSend(&event.fcp,SSH_FXP_CLOSE,hpacket);
               _BlobFree(hpacket);
               if( status ) {
                  _sftpCheckErrors(&event.fcp);
                  msg=nls("Cannot open file %s: Error sending SSH_FXP_CLOSE packet. status=%s",rpath,status);
                  line=event.fcp.lastStatusLine;
                  if( line!="" ) {
                     msg :+= "\n\n":+line;
                  }
                  _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
                  return;
               }
               _BlobFree(hhandle);
               rcmd.hhandle= -1;
               _ftpEnQ(event.event,QS_FXP_STATUS_WAITING_FOR_REPLY,0,&event.fcp,rcmd);
               return;
            }
            _BlobFree(hhandle);
            msg=nls("Cannot open file %s: Received SSH_FXP_STATUS packet",rpath);
            msg :+= "\n\n("err_code") "err_msg;
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,ERROR_OPENING_FILE_RC);
            return;
         }
         // Unexpected
         _BlobFree(hpacket);
         msg=nls("Cannot open file %s: Packet of type (%s) unexpected",rpath,type);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,VSRC_FTP_BAD_RESPONSE);
         return;
      }
      // Write the data to file
      //
      // Skip the id to get to the actual data
      _BlobSetOffset(hpacket,4,0);
      _BlobGetInt32(hpacket,len,1);
      status=_sftpPacketWriteToFile(hpacket,hfile,len);
      _BlobFree(hpacket);
      if( status ) {
         msg=nls("Cannot open file %s: Error writing to local file %s. status=%s",rpath,rcmd.dest,status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
         return;
      }
      //_ftpLog(&event.fcp,"Read "len" bytes of "rcmd.size" bytes.");
      rcmd.offset+=len;
      // Update the progress gauge
      if( rcmd.progressCb ) {
         line="Receiving "rpath;
         (*rcmd.progressCb)(line,rcmd.offset,rcmd.size);
      }
      // Success
      // Now get more data
      _ftpEnQ(event.event,QS_FXP_READ,0,&event.fcp,rcmd);
      return;
      break;
   case QS_FXP_STATUS_WAITING_FOR_REPLY:
      // Expecting SSH_FXP_STATUS packet for SSH_FXP_CLOSE operation
      type=_sftpPacketGet(&event.fcp,0,hpacket);
      if( type<0 ) {
         // Error
         _sftpCheckErrors(&event.fcp);
         line=event.fcp.lastStatusLine;
         msg=nls("Cannot open file %s: Error waiting for SSH_FXP_STATUS packet. status=%s",rpath,type);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,type);
         return;
      }
      if( type==0 ) {
         // Packet not ready, so keep waiting
         if( _sftpQTimedOut(&event) ) {
            // Timed out
            msg=nls("Cannot open file %s: Timed out waiting for close",rpath);
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,SOCK_TIMED_OUT_RC);
            return;
         }
         _ftpReQ(event.event,event.state,event.start,&event.fcp,rcmd);
         return;
      }
      // Packet is ready
      if( type!=SSH_FXP_STATUS ) {
         // Unexpected
         _BlobFree(hpacket);
         msg=nls("Cannot open file %s: Packet of type (%s) unexpected",rpath,type);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,VSRC_FTP_BAD_RESPONSE);
         return;
      }
      status=_sftpPacketParseStatus(hpacket,id,err_code,err_msg);
      _BlobFree(hpacket);
      if( status ) {
         msg=nls("Cannot open file %s: Unable to parse the SSH_FXP_STATUS packet. status=%s",rpath,status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
         return;
      }
      if( err_code!=SSH_FX_OK ) {
         // Error
         msg=nls("Cannot open file %s: Unable to close",rpath);
         msg :+= "\n\n("err_code") "err_msg;
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,ERROR_CLOSING_FILE_RC);
         return;
      }
      // Success
      _ftpEnQ(event.event,QS_END,0,&event.fcp,rcmd);
      return;
      break;
   case QS_ERROR:
      // An error occurred with SFTP get
      //
      // Clean up
      if( hfile>=0 ) {
         _FileClose(hfile);
      }
      if( hhandle>=0 ) {
         _BlobFree(hhandle);
      }
      _ftpQEventDisplayError(event);
      return;
      break;
   case QS_ABORT:
      // Event aborted
      //
      // Clean up
      if( hfile>=0 ) {
         _FileClose(hfile);
      }
      if( hhandle>=0 ) {
         _BlobFree(hhandle);
      }
      // Drain the pipe of all aborted packets so we can recover
      _sftpDrainPipe(&event.fcp,0);
      return;
      break;
   case QS_END:
      // Event ends
      //
      // Free the handle to handle
      if( hhandle>=0 ) {
         _BlobFree(hhandle);
      }
      break;
   default:
      // Should never get here
      msg="Unknown FTP queue event state: ":+event.state:+" for event ":+event.event;
      _message_box(msg,FTP_ERRORBOX_TITLE,MB_OK|MB_ICONEXCLAMATION);
      break;
   }

   return;
}

void _sftpQEHandler_Put(FtpQEvent *e_p)
{
   FtpQEvent event;
   FtpSendCmd scmd;
   SftpAttrs attrs;
   // Relative path
   _str rpath;
   // Canonacalized absolute path derived from rpath
   _str apath;
   int len;
   int nofbytes;
   int lenOffset;
   // The SFTP server's idea of a string handle is "\0\0\0\0" which
   // does not lend itself to being passed around without getting
   // mangled, so we use a indirect handle to the handle.
   int hhandle;
   int hfile;
   int i;

   event= *e_p;   // Make a copy

   scmd= (FtpSendCmd)event.info[0];   // This is not optional
   rpath=scmd.cmdargv[0];
   hfile= -1;
   if( scmd.hfile._varformat()!=VF_EMPTY ) {
      hfile=scmd.hfile;
   }
   hhandle= -1;
   if( scmd.hhandle._varformat()!=VF_EMPTY ) {
      hhandle=scmd.hhandle;
   }

   typeless hpacket=0;
   typeless status=0;
   typeless line=0;
   typeless type=0;
   typeless id=0;
   typeless err_code=0;
   typeless err_msg='';
   typeless offset=0;
   msg := "";

   switch( event.state ) {
   case QS_BEGIN:
      // Event begins
      //
      // Figure out the absolute path to open
      apath=_ftpAbsolute(&event.fcp,rpath);
      // No attributes for open
      _sftpAttrsInit(&attrs);
      // Send a SSH_FXP_OPEN packet to open a file for reading
      //
      // Allocate a packet
      hpacket=_BlobAlloc(0);
      // Data payload
      _BlobPutInt32(hpacket,_sftpNextOpId(&event.fcp),1);
      _BlobPutInt32(hpacket,length(apath),1);
      _BlobPutString(hpacket,apath);
      _BlobPutInt32(hpacket,SSH_FXF_WRITE|SSH_FXF_CREAT|SSH_FXF_TRUNC,1);
      _sftpPacketPutAttrs(hpacket,&attrs);
      status=_sftpPacketSend(&event.fcp,SSH_FXP_OPEN,hpacket);
      _BlobFree(hpacket);
      if( status ) {
         _sftpCheckErrors(&event.fcp);
         line=event.fcp.lastStatusLine;
         msg=nls("Cannot write file %s: Error sending SSH_FXP_OPEN packet. status=%s",rpath,status);
         if( line!="" ) {
            msg :+= "\n\n":+line;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_FXP_HANDLE_WAITING_FOR_REPLY,0,&event.fcp,scmd);
      return;
      break;
   case QS_FXP_HANDLE_WAITING_FOR_REPLY:
      // Expecting SSH_FXP_HANDLE packet
      type=_sftpPacketGet(&event.fcp,0,hpacket);
      if( type<0 ) {
         // Error
         _sftpCheckErrors(&event.fcp);
         line=event.fcp.lastStatusLine;
         msg=nls("Cannot write file %s: Error waiting for SSH_FXP_HANDLE packet. status=%s",rpath,type);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,type);
         return;
      }
      if( type==0 ) {
         // Packet not ready, so keep waiting
         if( _sftpQTimedOut(&event) ) {
            // Timed out
            msg=nls("Cannot write file %s: Timed out waiting for handle",rpath);
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,SOCK_TIMED_OUT_RC);
            return;
         }
         _ftpReQ(event.event,event.state,event.start,&event.fcp,scmd);
         return;
      }
      // Packet is ready
      if( type!=SSH_FXP_HANDLE ) {
         if( type==SSH_FXP_STATUS ) {
            status=_sftpPacketParseStatus(hpacket,id,err_code,err_msg);
            _BlobFree(hpacket);
            if( status ) {
               msg=nls("Cannot write file %s: Unable to parse the SSH_FXP_STATUS packet. status=%s",rpath,status);
               _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
               return;
            }
            msg=nls("Cannot write file %s: Received SSH_FXP_STATUS packet",rpath);
            msg :+= "\n\n("err_code") "err_msg;
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,ERROR_WRITING_FILE_RC);
            return;
         }
         // Unexpected
         _BlobFree(hpacket);
         msg=nls("Cannot write file %s: Packet of type (%s) unexpected",rpath,type);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,VSRC_FTP_BAD_RESPONSE);
         return;
      }
      // Skip over id
      _BlobSetOffset(hpacket,4,0);
      // Get the handle
      // Create the indirect handle to the handle, so that we can pass
      // it around without it getting mangled.
      hhandle=_sftpLstrAllocFromPacket(hpacket);
      _BlobFree(hpacket);
      if( hhandle<0 ) {
         // Error
         msg=nls("Cannot write file %s: Error allocating handle to handle. status=%s",rpath,hhandle);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,hhandle);
         return;
      }
      // Success
      // Assign the SFTP handle to the structure so we can pass it to events easily (and clean up easily)
      scmd.hhandle=hhandle;
      // Open the local file to transfer.
      hfile=_FileOpen(scmd.src,0);
      if( hfile<0 ) {
         // Error
         msg=nls("Cannot write file %s: Error opening local source file \"%s\". status=%s",rpath,scmd.src,hfile);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,hfile);
         return;
      }
      scmd.hfile=hfile;
      // Start writing the contents of the file starting at offset=0
      scmd.offset=0;
      // Fall through
   case QS_FXP_WRITE:
      // Issue a SSH_FXP_WRITE packet to write more of the file
      //
      // File offset at which to start writing
      offset=scmd.offset;
      // Length to read
      len=SFTP_MAX_XFERLEN;
      // Allocate a packet
      hpacket=_BlobAlloc(0);
      // Data payload
      _BlobPutInt32(hpacket,_sftpNextOpId(&event.fcp),1);
      // Fetch the string handle from the indirected handle into the packet
      _sftpLstrWriteToPacket(hhandle,hpacket);
      // Offset
      _BlobPutInt64(hpacket,offset,1);
      // Length to write
      lenOffset=_BlobGetOffset(hpacket);
      _BlobPutInt32(hpacket,len,1);
      // Data to write
      nofbytes=_BlobReadFromFile(hpacket,hfile,len);
      //_message_box("_sftpQEHandler_Put: nofbytes="nofbytes"  len="len);
      if( nofbytes<len ) {
         // Less than len bytes left in file which probably means no more
         // left to read, so revise the length field of the packet.
         len=nofbytes;
         _BlobSetOffset(hpacket,lenOffset,0);
         _BlobPutInt32(hpacket,len,1);
      }
      if( len==0 ) {
         // No more to write, so close the remote file
         _FileClose(hfile);
         hfile= -1;
         // Clear the packet
         _BlobInit(hpacket);
         // Data payload
         _BlobPutInt32(hpacket,_sftpNextOpId(&event.fcp),1);
         // Fetch the string handle from the indirected handle into the packet
         _sftpLstrWriteToPacket(hhandle,hpacket);
         // Send the packet
         status=_sftpPacketSend(&event.fcp,SSH_FXP_CLOSE,hpacket);
         _BlobFree(hpacket);
         if( status ) {
            _sftpCheckErrors(&event.fcp);
            msg=nls("Cannot write file %s: Error sending SSH_FXP_CLOSE packet. status=%s",rpath,status);
            line=event.fcp.lastStatusLine;
            if( line!="" ) {
               msg :+= "\n\n":+line;
            }
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
            return;
         }
         // Update the progress gauge
         if( scmd.progressCb ) {
            line="Uploading "rpath;
            (*scmd.progressCb)(line,scmd.size,scmd.size);
         }
         // Success
         _ftpEnQ(event.event,QS_FXP_STATUS_WAITING_FOR_REPLY,0,&event.fcp,scmd);
         return;
      }
      // Send the packet
      status=_sftpPacketSend(&event.fcp,SSH_FXP_WRITE,hpacket);
      _BlobFree(hpacket);
      if( status ) {
         _sftpCheckErrors(&event.fcp);
         msg=nls("2 Cannot write file %s: Error sending SSH_FXP_WRITE packet. status=%s",rpath,status);
         line=event.fcp.lastStatusLine;
         if( line!="" ) {
            msg :+= "\n\n":+line;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
         return;
      }
      scmd.offset+=len;
      // Update the progress gauge
      if( scmd.progressCb ) {
         line="Uploading "rpath;
         (*scmd.progressCb)(line,scmd.offset,scmd.size);
      }
      // Success
      _ftpEnQ(event.event,QS_FXP_WRITESTATUS_WAITING_FOR_REPLY,0,&event.fcp,scmd);
      return;
      break;
   case QS_FXP_WRITESTATUS_WAITING_FOR_REPLY:
      // Expecting SSH_FXP_STATUS packet for SSH_FXP_WRITE operation
      type=_sftpPacketGet(&event.fcp,0,hpacket);
      if( type<0 ) {
         // Error
         _sftpCheckErrors(&event.fcp);
         line=event.fcp.lastStatusLine;
         msg=nls("Cannot write file %s: Error waiting for SSH_FXP_STATUS packet (on SSH_FXP_WRITE). status=%s",rpath,type);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,type);
         return;
      }
      if( type==0 ) {
         // Packet not ready, so keep waiting
         if( _sftpQTimedOut(&event) ) {
            // Timed out
            msg=nls("Cannot write file %s: Timed out waiting for write status",rpath);
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,SOCK_TIMED_OUT_RC);
            return;
         }
         _ftpReQ(event.event,event.state,event.start,&event.fcp,scmd);
         return;
      }
      // Packet is ready
      if( type!=SSH_FXP_STATUS ) {
         // Unexpected
         _BlobFree(hpacket);
         msg=nls("Cannot write file %s: Packet of type (%s) unexpected",rpath,type);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,VSRC_FTP_BAD_RESPONSE);
         return;
      }
      status=_sftpPacketParseStatus(hpacket,id,err_code,err_msg);
      _BlobFree(hpacket);
      if( status ) {
         msg=nls("Cannot write file %s: Unable to parse the SSH_FXP_STATUS packet. status=%s",rpath,status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
         return;
      }
      if( err_code!=SSH_FX_OK ) {
         // Error closing directory listing
         msg=nls("Cannot write file %s: Unable to write",rpath);
         msg :+= "\n\n("err_code") "err_msg;
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,ERROR_WRITING_FILE_RC);
         return;
      }
      // Success
      _ftpEnQ(event.event,QS_FXP_WRITE,0,&event.fcp,scmd);
      return;
      break;
   case QS_FXP_STATUS_WAITING_FOR_REPLY:
      // Expecting SSH_FXP_STATUS packet for SSH_FXP_CLOSE operation
      type=_sftpPacketGet(&event.fcp,0,hpacket);
      if( type<0 ) {
         // Error
         _sftpCheckErrors(&event.fcp);
         line=event.fcp.lastStatusLine;
         msg=nls("Cannot write file %s: Error waiting for SSH_FXP_STATUS packet (on SSH_FXP_CLOSE). status=%s",rpath,type);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,type);
         return;
      }
      if( type==0 ) {
         // Packet not ready, so keep waiting
         if( _sftpQTimedOut(&event) ) {
            // Timed out
            msg=nls("Cannot write file %s: Timed out waiting for close",rpath);
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,SOCK_TIMED_OUT_RC);
            return;
         }
         _ftpReQ(event.event,event.state,event.start,&event.fcp,scmd);
         return;
      }
      // Packet is ready
      if( type!=SSH_FXP_STATUS ) {
         // Unexpected
         _BlobFree(hpacket);
         msg=nls("Cannot write file %s: Packet of type (%s) unexpected",rpath,type);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,VSRC_FTP_BAD_RESPONSE);
         return;
      }
      status=_sftpPacketParseStatus(hpacket,id,err_code,err_msg);
      _BlobFree(hpacket);
      if( status ) {
         msg=nls("Cannot write file %s: Unable to parse the SSH_FXP_STATUS packet. status=%s",rpath,status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
         return;
      }
      if( err_code!=SSH_FX_OK ) {
         // Error
         msg=nls("Cannot write file %s: Unable to close",rpath);
         msg :+= "\n\n("err_code") "err_msg;
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,ERROR_WRITING_FILE_RC);
         return;
      }
      // Success
      _ftpEnQ(event.event,QS_END,0,&event.fcp,scmd);
      return;
      break;
   case QS_ERROR:
      // An error occurred with SFTP put
      //
      // Clean up
      if( hfile>=0 ) {
         _FileClose(hfile);
      }
      if( hhandle>=0 ) {
         _BlobFree(hhandle);
      }
      _ftpQEventDisplayError(event);
      return;
      break;
   case QS_ABORT:
      // Event aborted
      //
      // Clean up
      if( hfile>=0 ) {
         _FileClose(hfile);
      }
      if( hhandle>=0 ) {
         _BlobFree(hhandle);
      }
      return;
      break;
   case QS_END:
      // Event ends
      //
      // Free the handle to handle
      if( hhandle>=0 ) {
         _BlobFree(hhandle);
      }
      break;
   default:
      // Should never get here
      msg="Unknown FTP queue event state: ":+event.state:+" for event ":+event.event;
      _message_box(msg,FTP_ERRORBOX_TITLE,MB_OK|MB_ICONEXCLAMATION);
      break;
   }

   return;
}

void _sftpQEHandler_Remove(FtpQEvent *e_p)
{
   FtpQEvent event;
   _str rpath,apath;

   event= *e_p;   // Make a copy

   rpath="";
   if( event.info._length()>0 ) {
      rpath=event.info[0];
   }

   typeless hpacket=0;
   typeless status=0;
   typeless line=0;
   typeless type=0;
   typeless id=0;
   typeless err_code=0;
   typeless err_msg='';
   msg := "";

   switch( event.state ) {
   case QS_BEGIN:
      // Event begins
      if( rpath=="" ) {
         msg=nls("Cannot remove \"%s\"",rpath);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rpath,msg,INVALID_ARGUMENT_RC);
         return;
      } else {
         // Relative to what we say the current working directory is
         apath=_ftpAbsolute(&event.fcp,rpath);
      }
      // Allocate a packet
      hpacket=_BlobAlloc(0);
      // Data payload
      _BlobPutInt32(hpacket,_sftpNextOpId(&event.fcp),1);
      _BlobPutInt32(hpacket,length(apath),1);
      _BlobPutString(hpacket,apath);
      // Send the packet
      status=_sftpPacketSend(&event.fcp,SSH_FXP_REMOVE,hpacket);
      _BlobFree(hpacket);
      if( status ) {
         _sftpCheckErrors(&event.fcp);
         msg=nls("Cannot remove \"%s\": Error sending SSH_FXP_REMOVE packet. status=%s",rpath,status);
         line=event.fcp.lastStatusLine;
         if( line!="" ) {
            msg :+= "\n\n":+line;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rpath,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_FXP_STATUS_WAITING_FOR_REPLY,0,&event.fcp,rpath);
      return;
      break;
   case QS_FXP_STATUS_WAITING_FOR_REPLY:
      // Expecting SSH_FXP_STATUS packet for SSH_FXP_REMOVE operation
      type=_sftpPacketGet(&event.fcp,0,hpacket);
      if( type<0 ) {
         // Error
         _sftpCheckErrors(&event.fcp);
         line=event.fcp.lastStatusLine;
         msg=nls("Cannot remove \"%s\": Error waiting for SSH_FXP_STATUS packet. status=%s",rpath,type);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rpath,msg,type);
         return;
      }
      if( type==0 ) {
         // Packet not ready, so keep waiting
         if( _sftpQTimedOut(&event) ) {
            // Timed out
            msg=nls("Cannot remove \"%s\": Timed out waiting for status",rpath);
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rpath,msg,SOCK_TIMED_OUT_RC);
            return;
         }
         _ftpReQ(event.event,event.state,event.start,&event.fcp,rpath);
         return;
      }
      // Packet is ready
      if( type!=SSH_FXP_STATUS ) {
         // Unexpected
         _BlobFree(hpacket);
         msg=nls("Cannot remove \"%s\": Packet of type (%s) unexpected",rpath,type);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rpath,msg,VSRC_FTP_BAD_RESPONSE);
         return;
      }
      status=_sftpPacketParseStatus(hpacket,id,err_code,err_msg);
      _BlobFree(hpacket);
      if( status ) {
         msg=nls("Cannot remove \"%s\": Unable to parse the SSH_FXP_STATUS packet. status=%s",rpath,status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rpath,msg,status);
         return;
      }
      if( err_code!=SSH_FX_OK ) {
         // Error
         msg=nls("Cannot remove \"%s\"",rpath);
         msg :+= "\n\n("err_code") "err_msg;
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rpath,msg,-1);
         return;
      }
      // Success
      _ftpEnQ(event.event,QS_END,0,&event.fcp,rpath);
      return;
      break;
   case QS_ERROR:
      // An error occurred with remove
      _ftpQEventDisplayError(event);
      return;
      break;
   case QS_ABORT:
      // Event aborted
      return;
      break;
   case QS_END:
      // Event ends
      break;
   default:
      // Should never get here
      msg="Unknown FTP queue event state: ":+event.state:+" for event ":+event.event;
      _message_box(msg,FTP_ERRORBOX_TITLE,MB_OK|MB_ICONEXCLAMATION);
      break;
   }

   return;
}

void _sftpQEHandler_Rmdir(FtpQEvent *e_p)
{
   FtpQEvent event;
   _str rpath,apath;

   event= *e_p;   // Make a copy

   rpath="";
   if( event.info._length()>0 ) {
      rpath=event.info[0];
   }

   typeless hpacket=0;
   typeless status=0;
   typeless line=0;
   typeless type=0;
   typeless id=0;
   typeless err_code=0;
   typeless err_msg='';
   msg := "";

   switch( event.state ) {
   case QS_BEGIN:
      // Event begins
      if( rpath=="" ) {
         msg=nls("Cannot remove directory \"%s\"",rpath);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rpath,msg,INVALID_ARGUMENT_RC);
         return;
      } else {
         // Relative to what we say the current working directory is
         apath=_ftpAbsolute(&event.fcp,rpath);
      }
      // Allocate a packet
      hpacket=_BlobAlloc(0);
      // Data payload
      _BlobPutInt32(hpacket,_sftpNextOpId(&event.fcp),1);
      _BlobPutInt32(hpacket,length(apath),1);
      _BlobPutString(hpacket,apath);
      // Send the packet
      status=_sftpPacketSend(&event.fcp,SSH_FXP_RMDIR,hpacket);
      _BlobFree(hpacket);
      if( status ) {
         _sftpCheckErrors(&event.fcp);
         msg=nls("Cannot remove directory \"%s\": Error sending SSH_FXP_RMDIR packet. status=%s",rpath,status);
         line=event.fcp.lastStatusLine;
         if( line!="" ) {
            msg :+= "\n\n":+line;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rpath,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_FXP_STATUS_WAITING_FOR_REPLY,0,&event.fcp,rpath);
      return;
      break;
   case QS_FXP_STATUS_WAITING_FOR_REPLY:
      // Expecting SSH_FXP_STATUS packet for SSH_FXP_RMDIR operation
      type=_sftpPacketGet(&event.fcp,0,hpacket);
      if( type<0 ) {
         // Error
         _sftpCheckErrors(&event.fcp);
         line=event.fcp.lastStatusLine;
         msg=nls("Cannot remove directory \"%s\": Error waiting for SSH_FXP_STATUS packet. status=%s",rpath,type);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rpath,msg,type);
         return;
      }
      if( type==0 ) {
         // Packet not ready, so keep waiting
         if( _sftpQTimedOut(&event) ) {
            // Timed out
            msg=nls("Cannot remove directory \"%s\": Timed out waiting for status",rpath);
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rpath,msg,SOCK_TIMED_OUT_RC);
            return;
         }
         _ftpReQ(event.event,event.state,event.start,&event.fcp,rpath);
         return;
      }
      // Packet is ready
      if( type!=SSH_FXP_STATUS ) {
         // Unexpected
         _BlobFree(hpacket);
         msg=nls("Cannot remove directory \"%s\": Packet of type (%s) unexpected",rpath,type);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rpath,msg,VSRC_FTP_BAD_RESPONSE);
         return;
      }
      status=_sftpPacketParseStatus(hpacket,id,err_code,err_msg);
      _BlobFree(hpacket);
      if( status ) {
         msg=nls("Cannot remove directory \"%s\": Unable to parse the SSH_FXP_STATUS packet. status=%s",rpath,status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rpath,msg,status);
         return;
      }
      if( err_code!=SSH_FX_OK ) {
         // Error
         msg=nls("Cannot remove directory \"%s\"",rpath);
         msg :+= "\n\n("err_code") "err_msg;
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rpath,msg,-1);
         return;
      }
      // Success
      _ftpEnQ(event.event,QS_END,0,&event.fcp,rpath);
      return;
      break;
   case QS_ERROR:
      // An error occurred with rmdir
      _ftpQEventDisplayError(event);
      return;
      break;
   case QS_ABORT:
      // Event aborted
      return;
      break;
   case QS_END:
      // Event ends
      break;
   default:
      // Should never get here
      msg="Unknown FTP queue event state: ":+event.state:+" for event ":+event.event;
      _message_box(msg,FTP_ERRORBOX_TITLE,MB_OK|MB_ICONEXCLAMATION);
      break;
   }

   return;
}

void _sftpQEHandler_Mkdir(FtpQEvent *e_p)
{
   FtpQEvent event;
   _str rpath,apath;
   SftpAttrs attrs;

   event= *e_p;   // Make a copy

   typeless hpacket=0;
   typeless status=0;
   typeless line=0;
   typeless type=0;
   typeless id=0;
   typeless err_code=0;
   typeless err_msg='';
   msg := "";

   rpath="";
   if( event.info._length()>0 ) {
      rpath=event.info[0];
   }

   switch( event.state ) {
   case QS_BEGIN:
      // Event begins
      if( rpath=="" ) {
         msg=nls("Cannot create directory \"%s\"",rpath);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rpath,msg,INVALID_ARGUMENT_RC);
         return;
      } else {
         // Relative to what we say the current working directory is
         apath=_ftpAbsolute(&event.fcp,rpath);
      }
      // Creation attributes for directory
      _sftpAttrsInit(&attrs);
      attrs.flags=SSH_FILEXFER_ATTR_PERMISSIONS;
      attrs.permissions=0777;
      // Allocate a packet
      hpacket=_BlobAlloc(0);
      // Data payload
      _BlobPutInt32(hpacket,_sftpNextOpId(&event.fcp),1);
      _BlobPutInt32(hpacket,length(apath),1);
      _BlobPutString(hpacket,apath);
      _sftpPacketPutAttrs(hpacket,&attrs);
      // Send the packet
      status=_sftpPacketSend(&event.fcp,SSH_FXP_MKDIR,hpacket);
      _BlobFree(hpacket);
      if( status ) {
         _sftpCheckErrors(&event.fcp);
         msg=nls("Cannot create directory \"%s\": Error sending SSH_FXP_MKDIR packet. status=%s",rpath,status);
         line=event.fcp.lastStatusLine;
         if( line!="" ) {
            msg :+= "\n\n":+line;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rpath,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_FXP_STATUS_WAITING_FOR_REPLY,0,&event.fcp,rpath);
      return;
      break;
   case QS_FXP_STATUS_WAITING_FOR_REPLY:
      // Expecting SSH_FXP_STATUS packet for SSH_FXP_MKDIR operation
      type=_sftpPacketGet(&event.fcp,0,hpacket);
      if( type<0 ) {
         // Error
         _sftpCheckErrors(&event.fcp);
         line=event.fcp.lastStatusLine;
         msg=nls("Cannot create directory \"%s\": Error waiting for SSH_FXP_STATUS packet. status=%s",rpath,type);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rpath,msg,type);
         return;
      }
      if( type==0 ) {
         // Packet not ready, so keep waiting
         if( _sftpQTimedOut(&event) ) {
            // Timed out
            msg=nls("Cannot create directory \"%s\": Timed out waiting for status",rpath);
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rpath,msg,SOCK_TIMED_OUT_RC);
            return;
         }
         _ftpReQ(event.event,event.state,event.start,&event.fcp,rpath);
         return;
      }
      // Packet is ready
      if( type!=SSH_FXP_STATUS ) {
         // Unexpected
         _BlobFree(hpacket);
         msg=nls("Cannot create directory \"%s\": Packet of type (%s) unexpected",rpath,type);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rpath,msg,VSRC_FTP_BAD_RESPONSE);
         return;
      }
      status=_sftpPacketParseStatus(hpacket,id,err_code,err_msg);
      _BlobFree(hpacket);
      if( status ) {
         msg=nls("Cannot create directory \"%s\": Unable to parse the SSH_FXP_STATUS packet. status=%s",rpath,status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rpath,msg,status);
         return;
      }
      if( err_code!=SSH_FX_OK ) {
         // Error
         msg=nls("Cannot create directory \"%s\"",rpath);
         msg :+= "\n\n("err_code") "err_msg;
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rpath,msg,ERROR_CREATING_DIRECTORY_RC);
         return;
      }
      // Success
      _ftpEnQ(event.event,QS_END,0,&event.fcp,rpath);
      return;
      break;
   case QS_ERROR:
      // An error occurred with mkdir
      _ftpQEventDisplayError(event);
      return;
      break;
   case QS_ABORT:
      // Event aborted
      return;
      break;
   case QS_END:
      // Event ends
      break;
   default:
      // Should never get here
      msg="Unknown FTP queue event state: ":+event.state:+" for event ":+event.event;
      _message_box(msg,FTP_ERRORBOX_TITLE,MB_OK|MB_ICONEXCLAMATION);
      break;
   }

   return;
}

void _sftpQEHandler_Rename(FtpQEvent *e_p)
{
   FtpQEvent event;
   _str frompath,afrompath;
   _str topath,atopath;

   event= *e_p;   // Make a copy

   frompath="";
   if( event.info._length()>0 ) {
      frompath=event.info[0];
   }
   topath="";
   if( event.info._length()>1 ) {
      topath=event.info[1];
   }

   typeless hpacket=0;
   typeless status=0;
   typeless line=0;
   typeless type=0;
   typeless id=0;
   typeless err_code=0;
   typeless err_msg='';
   msg := "";

   switch( event.state ) {
   case QS_BEGIN:
      // Event begins
      if( frompath=="" ) {
         msg=nls("Cannot rename from \"%s\"",frompath);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,frompath,topath,msg,INVALID_ARGUMENT_RC);
         return;
      } else if( topath=="" ) {
         msg=nls("Cannot rename to \"%s\"",topath);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,frompath,topath,msg,INVALID_ARGUMENT_RC);
         return;
      } else {
         // Relative to what we say the current working directory is
         afrompath=_ftpAbsolute(&event.fcp,frompath);
         atopath=_ftpAbsolute(&event.fcp,topath);
      }
      // Allocate a packet
      hpacket=_BlobAlloc(0);
      // Data payload
      _BlobPutInt32(hpacket,_sftpNextOpId(&event.fcp),1);
      _BlobPutInt32(hpacket,length(afrompath),1);
      _BlobPutString(hpacket,afrompath);
      _BlobPutInt32(hpacket,length(atopath),1);
      _BlobPutString(hpacket,atopath);
      // Send the packet
      status=_sftpPacketSend(&event.fcp,SSH_FXP_RENAME,hpacket);
      _BlobFree(hpacket);
      if( status ) {
         _sftpCheckErrors(&event.fcp);
         msg=nls("Cannot rename \"%s\": Error sending SSH_FXP_MKDIR packet. status=%s",frompath,topath,status);
         line=event.fcp.lastStatusLine;
         if( line!="" ) {
            msg :+= "\n\n":+line;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,frompath,topath,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_FXP_STATUS_WAITING_FOR_REPLY,0,&event.fcp,frompath);
      return;
      break;
   case QS_FXP_STATUS_WAITING_FOR_REPLY:
      // Expecting SSH_FXP_STATUS packet for SSH_FXP_MKDIR operation
      type=_sftpPacketGet(&event.fcp,0,hpacket);
      if( type<0 ) {
         // Error
         _sftpCheckErrors(&event.fcp);
         line=event.fcp.lastStatusLine;
         msg=nls("Cannot rename \"%s\": Error waiting for SSH_FXP_STATUS packet. status=%s",frompath,topath,type);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,frompath,topath,msg,type);
         return;
      }
      if( type==0 ) {
         // Packet not ready, so keep waiting
         if( _sftpQTimedOut(&event) ) {
            // Timed out
            msg=nls("Cannot rename \"%s\": Timed out waiting for status",frompath);
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,frompath,topath,msg,SOCK_TIMED_OUT_RC);
            return;
         }
         _ftpReQ(event.event,event.state,event.start,&event.fcp,frompath);
         return;
      }
      // Packet is ready
      if( type!=SSH_FXP_STATUS ) {
         // Unexpected
         _BlobFree(hpacket);
         msg=nls("Cannot rename \"%s\": Packet of type (%s) unexpected",frompath,topath,type);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,frompath,topath,msg,VSRC_FTP_BAD_RESPONSE);
         return;
      }
      status=_sftpPacketParseStatus(hpacket,id,err_code,err_msg);
      _BlobFree(hpacket);
      if( status ) {
         msg=nls("Cannot rename \"%s\": Unable to parse the SSH_FXP_STATUS packet. status=%s",frompath,topath,status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,frompath,topath,msg,status);
         return;
      }
      if( err_code!=SSH_FX_OK ) {
         // Error
         msg=nls("Cannot rename \"%s\"",frompath);
         msg :+= "\n\n("err_code") "err_msg;
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,frompath,topath,msg,-1);
         return;
      }
      // Success
      _ftpEnQ(event.event,QS_END,0,&event.fcp,frompath);
      return;
      break;
   case QS_ERROR:
      // An error occurred with mkdir
      _ftpQEventDisplayError(event);
      return;
      break;
   case QS_ABORT:
      // Event aborted
      return;
      break;
   case QS_END:
      // Event ends
      break;
   default:
      // Should never get here
      msg="Unknown FTP queue event state: ":+event.state:+" for event ":+event.event;
      _message_box(msg,FTP_ERRORBOX_TITLE,MB_OK|MB_ICONEXCLAMATION);
      break;
   }

   return;
}

void _sftpQEHandler_EndConnProfile(FtpQEvent *e_p)
{
   FtpQEvent event;

   event= *e_p;   // Make a copy

   // Ending a connection
   switch( event.state ) {
   case QS_BEGIN:
      // Event begins
      {
         int pid = _PipeGetProcessPid(event.fcp.ssh_hprocess);

         // Closing the ssh client process will close all i/o handles too
         _PipeCloseProcess(event.fcp.ssh_hprocess);
   
         // Must be certain the 'ssh' process ends.
         // On UNIX we have started noticing that it does not end
         // gracefully when we close the pipes.
         if( pid != 0 && _IsProcessRunning(pid) ) {
            int exit_code;
            _kill_process_tree(pid,exit_code);
         }
   
         return;
      }
      break;
   case QS_ERROR:
      // An error occurred closing the ssh client process
      _ftpQEventDisplayError(event);
      // Fall thru to QS_END
   case QS_ABORT:
      // Event aborted - fall thru to QS_END
   case QS_END:
      // Event ends
      return;
      break;
   default:
      // Should never get here
      msg := "Unknown FTP queue event state: ":+event.state:+" for event ":+event.event;
      _message_box(msg,FTP_ERRORBOX_TITLE,MB_OK|MB_ICONEXCLAMATION);
      break;
   }

   return;
}

