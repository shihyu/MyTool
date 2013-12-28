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
#include "vsockapi.sh"
#import "files.e"
#import "ftp.e"
#import "sftpq.e"
#import "stdprocs.e"
#endregion

/** Timer interval used when there are ftp events to be processed. 0.1 seconds */
#define FTPQTIMER_INTERVAL (100)
/**
 * Timer interval used when there are no ftp events to be processed (for KeepAlive).
 * 30.5 seconds (not 30.0 seconds because of the KeepAlive interval).
 */
#define FTPQTIMER_SLOW_INTERVAL (30500)

/**
 * Pointer-to-function for current ftp timer callback. This is used to keep
 * track of whether we are using the slow timer callback or not.
 */
typedef void (*pfnftpQTimerCallback_tp)();

static pfnftpQTimerCallback_tp pfnftpQTimerCallback;
static _str _ftpVSProxyPath="";
/** Used when processing ftp events. */
int _ftpQTimer= -1;

// true=Process events asynchronously on a timer (slower)
static boolean gFtpAsync = false;

// Global to indicate we are wrapped in a synchronous event loop for
// FTP events (_ftpSyncEnQ).
boolean gInFtpSyncEnQ = false;

// Global to indicate we are wrapped in a idle event loop for
// FTP events (_ftpIdleEnQ).
boolean gInFtpIdleEnQ = false;

// See ftp.sh, need to be defined outside of header file
// for compatibility with #import, otherwise it is just declared
// and the variable isn't instantiated before this definit runs
FtpFileHist _ftpFileHist:[];
FtpConnProfile _ftpCurrentConnections:[];

definit()
{
   if( arg(1)!='L' ) {
      // Do not blow away the queue if loading
      _ftpQ._makeempty();
   }

   gInFtpSyncEnQ=false;
   gInFtpIdleEnQ=false;

   // Q timer
   #if 1
   if( arg(1)=='L') {
      _ftpQKillTimer();
   }
   _ftpQTimer= -2;   // -1 is for the get_event() timer
   _ftpQSmartStartTimer();
   if( arg(1)=='L' ) {
      // If we are reloading because a timer died we will want to re-enable
      // all forms.
      call_list('_ftpQIdle_');
   }
   #endif

   _ftpVSProxyPath="";

   rc=0;
}

typedef void (*pfnEnQ_tp)(int e, int state, double start, FtpConnProfile *fcp_p, ...);

FtpQEvent _ftpEnQ(int e, int state, double start, FtpConnProfile *fcp_p, ...);
FtpQEvent _ftpSyncEnQ(int e, int state, double start, FtpConnProfile *fcp_p, ...);

/**
 * Idle EnQ. Queues event synchronously when the user has been idle. Used by
 * FTP Client tool window for faster operations.
 * 
 * @return The event enQ'ed for this connection profile.
 * null is returned on error.
 */
void _ftpIdleEnQ(int e, int state, double start, FtpConnProfile *fcp_p,...)
{
   int nofargs = arg();
   switch( nofargs ) {
   case 4:
      _ftpEnQ(e,state,start,fcp_p);
      break;
   case 5:
      _ftpEnQ(e,state,start,fcp_p,arg(5));
      break;
   case 6:
      _ftpEnQ(e,state,start,fcp_p,arg(5),arg(6));
      break;
   case 7:
      _ftpEnQ(e,state,start,fcp_p,arg(5),arg(6),arg(7));
      break;
   case 8:
      _ftpEnQ(e,state,start,fcp_p,arg(5),arg(6),arg(7),arg(8));
      break;
   case 9:
      _ftpEnQ(e,state,start,fcp_p,arg(5),arg(6),arg(7),arg(8),arg(9));
      break;
   case 10:
      _ftpEnQ(e,state,start,fcp_p,arg(5),arg(6),arg(7),arg(8),arg(9),arg(10));
      break;
   default:
      _message_box("_ftpSyncEnQ: Too many arguments.","",MB_OK|MB_ICONEXCLAMATION);
   }
   if( gFtpAsync ) {
      // That's it. Let the timer callback take care of the rest.
      return;
   }
   if( gInFtpIdleEnQ ) {
      // We are already wrapped in a idle EnQ loop.
      // Do NOT recursively call ourselves.
      return;
   }
   gInFtpIdleEnQ=true;

   // Fast loop until the user is not idle
   boolean cancel = false;
   while( _ftpQ._length() > 0 && _idle_time_elapsed()>1000 ) {
      _ftpQTimerCallback();
      process_events(cancel);
      delay(1);
   }

   gInFtpIdleEnQ=false;
}

/**
 * Synchronous EnQ. Much faster. Used by FTP Open tool window for faster
 * operations.
 * 
 * @param e
 * @param state
 * @param start
 * @param fcp_p
 * 
 * @return The last event processed for this connection profile.
 * If asynchronous operations are forced (gFtpAsync==true) or we
 * are already wrapped in a call to _ftpSyncEnQ(), then the event
 * enQ'ed is returned. null is returned on error.
 */
FtpQEvent _ftpSyncEnQ(int e, int state, double start, FtpConnProfile *fcp_p, ...)
{
   FtpQEvent event;

   int nofargs = arg();
   switch( nofargs ) {
   case 4:
      event=_ftpEnQ(e,state,start,fcp_p);
      break;
   case 5:
      event=_ftpEnQ(e,state,start,fcp_p,arg(5));
      break;
   case 6:
      event=_ftpEnQ(e,state,start,fcp_p,arg(5),arg(6));
      break;
   case 7:
      event=_ftpEnQ(e,state,start,fcp_p,arg(5),arg(6),arg(7));
      break;
   case 8:
      event=_ftpEnQ(e,state,start,fcp_p,arg(5),arg(6),arg(7),arg(8));
      break;
   case 9:
      event=_ftpEnQ(e,state,start,fcp_p,arg(5),arg(6),arg(7),arg(8),arg(9));
      break;
   case 10:
      event=_ftpEnQ(e,state,start,fcp_p,arg(5),arg(6),arg(7),arg(8),arg(9),arg(10));
      break;
   default:
      _message_box("_ftpSyncEnQ: Too many arguments.","",MB_OK|MB_ICONEXCLAMATION);
      return null;
   }
   if( gFtpAsync ) {
      // That's it. Let the timer callback take care of the rest.
      return event;
   }
   if( gInFtpSyncEnQ ) {
      // We are already wrapped in a synchronous EnQ loop.
      // Do NOT recursively call ourselves.
      return event;
   }
   gInFtpSyncEnQ=true;

   // If we got here, then operations are synchronous (faster)
   //double t1 = (double)_time('b');
   //say('_ftpSyncEnQ: start='_time('m'));
   FtpQEvent lastevent;
   lastevent._makeempty();
   lastevent.event=0;
   lastevent.start=0;
   lastevent.state=0;
   lastevent.fcp = *fcp_p;
   _str thisProfileName = fcp_p->profileName;
   int thisInstance = fcp_p->instance;
   boolean cancel = false;
   while( _ftpQ._length() > 0 ) {
      if( _ftpQ[0].fcp.profileName==thisProfileName &&
          _ftpQ[0].fcp.instance==thisInstance ) {

         lastevent=_ftpQ[0];
      }
      _ftpQTimerCallback();
      process_events(cancel);
      delay(1);
   }
   //double t2 = (double)_time('b');
   //say('_ftpSyncEnQ: end='_time('m')'  duration='(t2-t1)/1000.0);

   gInFtpSyncEnQ=false;
   
   return lastevent;
}

FtpQEvent _ftpEnQ(int e, int state, double start, FtpConnProfile *fcp_p, ...)
{
   FtpQEvent event;

   if( e<QE_FIRST || e>QE_LAST ) {
      _message_box("Unknown FTP queue event: ":+e,FTP_ERRORBOX_TITLE,MB_OK|MB_ICONEXCLAMATION);
      return null;
   }
   if( state<QS_FIRST || state>QS_LAST ) {
      _message_box("Unknown FTP queue event state: ":+state,FTP_ERRORBOX_TITLE,MB_OK|MB_ICONEXCLAMATION);
      return null;
   }

   // Notify all ftp-related forms that they are busy
   call_list('_ftpQBusy_');

   event._makeempty();
   event.event=e;
   event.state=state;

   if( fcp_p ) {
      // Make a copy because it may not be in _ftpCurrentConnections yet
      event.fcp= *fcp_p;
      //_ftpDebugSayConnProfile(fcp_p);
   }
   if( start>0 ) {
      // Starting time specified. This usually means we are waiting for
      // something to happen, so we keep track of an original starting
      // time so we can test for a timeout condition.
      event.start=start;
   } else {
      event.start= (double)_time('B');
      // This is a buffered reply from the ftp server or SE proxy.
      // We only initialize to "" if we are starting an event.
      // This is most important when re-queueing *_WAITING_FOR_REPLY
      // event states where we want to clear the Reply field when
      // just starting to receive the reply.
      event.fcp.reply="";
   }
   int i;
   for( i=5;i<=arg();++i ) {
      event.info[event.info._length()]=arg(i);
   }

   // The event is always tacked onto the end of the queue with the
   // following exceptions:
   //
   // 1. We are starting a connection with a profile matching event.fcp
   boolean found_it=false;
   for( i=0;i<_ftpQ._length();++i ) {
      // Note that we do not check the Instance field because there is none set yet
      if( _ftpQ[i].fcp.profileName==event.fcp.profileName ) {
         switch( event.event ) {
         case QE_START_CONN_PROFILE:
         case QE_SSH_START_CONN_PROFILE:
         case QE_PROXY_CONNECT:
         case QE_RELAY_CONNECT:
         case QE_PROXY_OPEN:
         case QE_OPEN:
         case QE_USER:
         case QE_PASS:
         //case QE_CWD:
         //case QE_PWD:
            found_it=true;
            break;
         }
         if( found_it ) break;
      }
   }
   if( found_it ) {
      // Found it. Now shift all elements starting with this one so we can
      // jam this one in.
      int j;
      for( j=_ftpQ._length()-1;j>=i;--j ) {
         _ftpQ[j+1]=_ftpQ[j];
      }
      _ftpQ[i]=event;
   } else {
      _ftpQ[_ftpQ._length()]=event;
   }

   // Start the timer that will handle events
   _ftpQSmartStartTimer();

   return event;
}

/**
 * Queue the event at the front of the event queue for the connection profile
 * pointed to by fcp_p.
 */
void _ftpReQ(int e,int state,double start,FtpConnProfile *fcp_p,...)
{
   FtpQEvent event;

   if( e<=0 || e>QE_LAST ) {
      _message_box("Unknown FTP queue event: ":+e,FTP_ERRORBOX_TITLE,MB_OK|MB_ICONEXCLAMATION);
      return;
   }
   if( state<=0 || state>QS_LAST ) {
      _message_box("Unknown FTP queue event state: ":+state,FTP_ERRORBOX_TITLE,MB_OK|MB_ICONEXCLAMATION);
      return;
   }

   // Notify all ftp-related forms that they are busy
   call_list('_ftpQBusy_');

   event._makeempty();
   event.event=e;
   event.state=state;
   if( fcp_p ) {
      event.fcp= *fcp_p;   // Make a copy because it may not be in _ftpCurrentConnections yet
   }
   if( start>0 ) {
      // Starting time specified. This usually means we are waiting for
      // something to happen, so we keep track of an original starting
      // time so we can test for a timeout condition.
      event.start=start;
   } else {
      event.start= (double)_time('B');
      // This is a buffered reply from the ftp server or SE proxy.
      // We only initialize to "" if we are starting an event.
      // This is most important when re-queueing *_WAITING_FOR_REPLY
      // event states where we want to clear the Reply field when
      // just starting to receive the reply.
      event.fcp.reply="";
   }
   int i;
   for( i=5;i<=arg();++i ) {
      event.info[event.info._length()]=arg(i);
   }

   // Now find the first event in the queue that matches the connection
   // profile pointed to by fcp_p and stick the new event on the front.
   boolean found_it=false;
   for( i=0;i<_ftpQ._length();++i ) {
      if( _ftpQ[i].fcp.profileName==fcp_p->profileName &&
          _ftpQ[i].fcp.instance==fcp_p->instance ) {
         found_it=true;
         break;
      }
   }
   if( found_it ) {
      // Found it. Now shift all elements starting with this one so we can
      // jam this one in.
      int j;
      for( j=_ftpQ._length()-1;j>=i;--j ) {
         _ftpQ[j+1]=_ftpQ[j];
      }
      _ftpQ[i]=event;
   } else {
      // This is the first event in the queue for this connection profile,
      // so just tack it on the end of the queue.
      _ftpQ[_ftpQ._length()]=event;
   }

   // Start the timer that will handle events
   _ftpQSmartStartTimer();

   return;
}

void _ftpDeQ()
{
   if( _ftpQ._length()>0 ) {
      _ftpQ._deleteel(0);
   }

   return;
}

/**
 * Test event for error state. 
 * 
 * @param event  Event to test.
 * 
 * @return true if event was an error.
 */
boolean _ftpQEventIsError(FtpQEvent& event)
{
   return( event.state == QS_ERROR );
}

/**
 * Test event for abort state. 
 * 
 * @param event  Event to test.
 * 
 * @return true if event was an abort.
 */
boolean _ftpQEventIsAbort(FtpQEvent& event)
{
   return ( event.state == QS_ABORT || event.state == QS_ABORT_WAITING_FOR_REPLY );
}

/**
 * Get string message associated with an event. Currently only 
 * events in an error state have messages. 
 * 
 * @param event      Event to get message for.
 * 
 * @return String message, "" if no message associated with 
 *         event.
 */
_str _ftpQEventGetMessage(FtpQEvent& event)
{
   _str msg = "";

   if( event.state == QS_ERROR ) {
      // Message is always next-to-last in the info[] array
      msg = (_str)event.info[event.info._length() - 2];
   }

   return msg;
}

/**
 * Get status associated with an event. Currently only events in
 * an error state have a status. 
 * 
 * @param event  Event to get status for.
 * 
 * @return Integer status, 0 if no status associated with event.
 */
int _ftpQEventGetStatus(FtpQEvent& event)
{
   int status = 0;

   if( event.state == QS_ERROR ) {
      // Status is always last in the info[] array
      status = (int)event.info[event.info._length() - 1];
   }

   return status;
}

/**
 * Display error message associated with event. If event state
 * is not an error, then nothing is displayed and this function
 * quietly returns. If there is no error-display callback then 
 * this function does nothing. 
 *
 * @param event  Event to display error status for.
 */
void _ftpQEventDisplayError(FtpQEvent& event)
{
   if( event.state == QS_ERROR && event.fcp.errorCb ) {
      // Message is always next-to-last in the info[] array
      _str msg = (_str)event.info[event.info._length() - 2];
      (*event.fcp.errorCb)(msg);
   }
}

int _ftpQCheckResponse(FtpQEvent *e_p,boolean quiet,_str &response,boolean vsproxy)
{
   FtpQEvent event = *e_p;   // Make a copy
   typeless status=0;
   _str msg="";
   _str buf='';                // Temporary read buffer
   boolean done=false;

   if( vsproxy ) {
      if( !vssIsConnectionAlive(event.fcp.vsproxy_sock) ) {
         return(VSRC_FTP_CONNECTION_DEAD);
      }
   } else {
      if( !vssIsConnectionAlive(event.fcp.sock) ) {
         //say('_ftpQCheckResponse: connection closed');
         return(SOCK_CONNECTION_CLOSED_RC);
      }
   }

   buf="";
   response="";

   double elapsed=((double)_time('B')-event.start+1)/1000;   // Seconds

   _str reply=event.fcp.reply;
   #if 1
   if( vsproxy ) {
      status=vssSocketRecvToZStr(event.fcp.vsproxy_sock,buf,0,0);
   } else {
      status=vssSocketRecvToZStr(event.fcp.sock,buf,0,0);
   }
   if( status ) {
      return(status);
   }
   buf=_MultiByteToUTF8(buf);
   reply=reply:+buf;
   #else
   for(;;) {
      // If the ftp server sends replies in more than 1 send(), then
      // a single recv() on the socket might only retrieve the first
      // send(). Therefore we loop.
      if( vsproxy ) {
         status=vssSocketRecvToZStr(event.fcp.vsproxy_sock,buf,0,0);
      } else {
         status=vssSocketRecvToZStr(event.fcp.sock,buf,0,0);
      }
      if( status ) {
         return(status);
      }
      if( buf=="" ) break;
      buf=_MultiByteToUTF8(buf);
      reply=reply:+buf;
   }
   #endif

   int reply_len=length(reply);
   e_p->fcp.reply=reply;   // We DO want to pass this back
   if( vsproxy ) {
      if( reply=="" || length(reply)<3 || last_char(reply)!=EOL ) {
         // Did not get a complete response yet, so re-queue.
         // Unless timed out. We are expecting atleast something
         // like:
         //
         // +ok
         if( elapsed>event.fcp.timeout ) {
            return(SOCK_TIMED_OUT_RC);
         }
         return(VSRC_FTP_WAITING_FOR_REPLY);
      }
   } else {
      if( reply=="" || length(reply)<4 || last_char(reply)!=EOL ) {
         // Did not get a complete response yet, so re-queue.
         // Unless timed out. We are expecting atleast something
         // like:
         //
         // 257-
         if( elapsed>event.fcp.timeout ) {
            return(SOCK_TIMED_OUT_RC);
         }
         return(VSRC_FTP_WAITING_FOR_REPLY);
      }
   }

   int i=1;
   _str ch=substr(reply,i,1);
   if( vsproxy ) {
      done=true;   // We do not need this if vsproxy==true
      if( ch=='-' ) {
         status=VSRC_FTP_BAD_RESPONSE;
      }
   } else {
      done=false;
      if( substr(reply,i+3,1)=='-' ) {
         // A '-' after the code means there is more to follow
         done=false;
      } else {
         done=true;
      }
      if( ch=='4' || ch=='5' ) {
         status=VSRC_FTP_BAD_RESPONSE;
      }
   }

   // Capture the first line and save it
   _str line=substr(reply,i);
#if __EBCDIC__
   int p=pos('\13|\21',line,1,'er');
#else
   int p=pos('\13|\10',line,1,'er');
#endif
   if( p ) {
      line=substr(line,1,p-1);
   }
   if( !vsproxy ) {
      // We actually do want to store this in the original structure
      if( line!="" ) {
         e_p->fcp.prevStatusLine=e_p->fcp.lastStatusLine;
         e_p->fcp.lastStatusLine=line;
      }
   }

   while( i<=reply_len ) {
      if( substr(reply,i,1)=="\n" ) {
         // +1 to skip the newline, +3 to skip the 3 digit code (or "+ok")
         if( (i+1+3)<=reply_len ) {
            // +1 to get the first char after the newline
            ch=substr(reply,i+1,1);
            if( vsproxy ) {
               if( ch=='-' ) {
                  status=VSRC_FTP_BAD_RESPONSE;
               }
            } else {
               if( substr(reply,i+1+3,1)=='-' ) {
                  // A '-' after the code means there is more to follow
                  done=false;
               } else {
                  done=true;
               }
               if( ch=='4' || ch=='5' ) {
                  status=VSRC_FTP_BAD_RESPONSE;
               }
            }

            // Capture the first line and save it
            line=substr(reply,i+1);
#if __EBCDIC__
            p=pos('\13|\21',line,1,'er');
#else
            p=pos('\13|\10',line,1,'er');
#endif
            if( p ) {
               line=substr(line,1,p-1);
            }
            if( !vsproxy ) {
               // We actually do want to store this in the original structure
               if( line!="" ) {
                  e_p->fcp.prevStatusLine=e_p->fcp.lastStatusLine;
                  e_p->fcp.lastStatusLine=line;
               }
            }
         }
      }
      ++i;
   }

   if( !done ) {
      // We looked at all the data and now we're tossing the results
      // because we're not done yet. Unless we timed out.
      if( elapsed>event.fcp.timeout ) {
         return(SOCK_TIMED_OUT_RC);
      }
      return(VSRC_FTP_WAITING_FOR_REPLY);
   }
   e_p->fcp.reply="";

   if( !quiet || _ftpdebug&FTPDEBUG_LOG_PROXY ) {
      // Log the response from the ftp server/SE proxy
      _ftpLog(&event.fcp,reply);
   }

   response=reply;

   return(status);
}

void _ftpQEHandler_StartConnProfile(FtpQEvent *e_p)
{
   FtpQEvent event = *e_p;  // Make a copy
   typeless status=0;
   _str response="";
   _str msg="";

   // Start a connection profile
   switch( event.state ) {
   case QS_BEGIN:
      // Event begins
      //
      // Initialize sockets layer
      int idx=find_index("vssIsInit",PROC_TYPE);
      if( !idx || !index_callable(idx) ) {
         msg="Could not find vssInit";
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,SOCK_INIT_FAILED_RC);
         return;
      }
      if( !vssIsInit() ) {
         // Start sockets layer
         status=vssInit();
         if( status ) {
            msg="Could not initialize sockets layer.  ":+_ftpGetMessage(status);
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         }
      }

      // Create a log buffer for this connection (if necessary).
      // If there is already a log buffer associated with this profile, then
      // it normally means that the connection is being restarted.
      if( event.fcp.logBufName=="" ) {
         _str log_buf_name=_ftpCreateLogBuffer();
         if( log_buf_name=="" ) {
            // Do not need a message box because _ftpCreateLogBuffer() took care of that
            msg="Unable to create log buffer. Connection is aborted.";
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,ERROR_OPENING_FILE_RC);
            return;
         }
         event.fcp.logBufName=log_buf_name;
         _ftpLog(&event.fcp,"*** Log started on ":+_date():+" at ":+_time('M'));
      }
      _ftpEnQ(QE_PROXY_CONNECT,QS_BEGIN,0,&event.fcp);
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

void _ftpQEHandler_ProxyConnect(FtpQEvent *e_p)
{
   FtpQEvent event = *e_p;   // Make a copy
   typeless status=0;
   _str response="";
   _str msg="";
   _str temp_host="";
   _str cmdline="";
   typeless temp_port="";

   // Listening for vsproxy to connect a control socket to us
   switch( event.state ) {
   case QS_BEGIN:
      // Event begins
      if( _ftpVSProxyPath=="" ) {
         #if 1
         _ftpVSProxyPath=editor_name('P'):+VSPROXY_COMMAND;
         #else
         _ftpVSProxyPath=path_search(VSPROXY_COMMAND,"VSLICKBIN","");
         if( _ftpVSProxyPath=="" ) {
            msg='Cannot find "':+VSPROXY_COMMAND:+" in VSLICKBIN path";
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,FILE_NOT_FOUND_RC);
            return;
         }
         #endif
      }
      #if 1
      // Some users have mysterious problem where vsproxy.exe cannot
      // connect back to their own host name, so use loopback ip
      // address instead.
      vssGetHostAddress("",temp_host);
      //say('_ftpQEHandler_ProxyConnect: temp_host='temp_host);
      //temp_host="127.0.0.1";
      #else
      status=vssGetMyHostName(temp_host);
      temp_host=_MultiByteToUTF8(temp_host);
      if( status ) {
         msg="Error getting local host info.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }
      #endif
      // "0" means to dynamically assign next available port
      int temp_sock=0;
      status=vssSocketOpen(_UTF8ToMultiByte(temp_host),"0",temp_sock,1,SOCKDEF_CONNECT_TIMEOUT);
      if( status ) {
         msg="Error listening for a SlickEdit proxy connection on ":+temp_host:+".  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }
      // Get the port that was dynamically assigned
      status=vssGetLocalSocketInfo(temp_sock,temp_host,temp_port);
      if( status ) {
         msg="Error retrieving local host info for listen on SlickEdit proxy connection.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }
      temp_host=_MultiByteToUTF8(temp_host);
      temp_port=_MultiByteToUTF8(temp_port);
      _ftpLog(&event.fcp,"Listening for SlickEdit proxy connection on ":+temp_host:+":":+temp_port);
      //say('QE_PROXY_CONNECT/QS_BEGIN - temp_sock='temp_sock'  temp_host='temp_host'  temp_port='temp_port);
      event.fcp.vsproxy_sock=temp_sock;   // This socket will change once a connection is accepted
      cmdline=maybe_quote_filename(_ftpVSProxyPath)' -nounicode ';
      int ipVersionSupported = _default_option(VSOPTION_IPVERSION_SUPPORTED);
      if( ipVersionSupported == VSIPVERSION_4 ) {
         cmdline=cmdline:+" -4";
      } else if( ipVersionSupported == VSIPVERSION_6 ) {
         cmdline=cmdline:+" -6";
      }
      cmdline=cmdline:+" ":+temp_host:+" ":+temp_port;
      if( _ftpdebug&FTPDEBUG_VSPROXY ) {
         cmdline=cmdline:+" -debug";
      }
      int pid=0;
      //say('_ftpQEHandler_ProxyConnect: cmdline='cmdline);
      status=shell(cmdline,"QPAN","",pid);
      if( status ) {
         msg="Error running SlickEdit proxy.  ":+status;
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }
      event.fcp.vsproxy_pid=pid;
      _ftpEnQ(event.event,QS_LISTENING,event.start,&event.fcp);
      return;
      break;
   case QS_LISTENING:
      status=vssSocketAcceptConn(event.fcp.vsproxy_sock);
      if( status ) {
         if( status==SOCK_NO_CONN_PENDING_RC ) {
            double elapsed=((double)_time('B')-event.start+1)/1000;   // Seconds
            if( elapsed>FTPDEF_TIMEOUT ) {
               // We timed out
               msg="Timed out waiting for control connection from SlickEdit proxy";
               _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,SOCK_TIMED_OUT_RC);
            } else {
               // No connection attempt has been made yet, so nothing has
               // changed. Re-queue with the same start time.
               _ftpEnQ(event.event,event.state,event.start,&event.fcp);
            }
            return;
         } else {
            msg="Error waiting for control connection from SlickEdit proxy.  ":+_ftpGetMessage(status);
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
            return;
         }
      } else {
         // We now have a control connection with the SE proxy.
         // Now we need to open a relay connection for communication
         // directly with the ftp server.
         status=vssGetLocalSocketInfo(event.fcp.vsproxy_sock,temp_host,temp_port);
         if( status ) {
            msg="Error retrieving local host info for connection accept from SlickEdit proxy.  ":+_ftpGetMessage(status);
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
            return;
         }
         temp_host=_MultiByteToUTF8(temp_host);
         temp_port=_MultiByteToUTF8(temp_port);
         _ftpLog(&event.fcp,"Connection accepted from SlickEdit proxy on ":+temp_host:+":":+temp_port);
         _ftpEnQ(QE_RELAY_CONNECT,QS_BEGIN,0,&event.fcp);
         return;
      }
      return;
      break;
   case QS_ERROR:
      // An error occurred getting the proxy connection, so clean up
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

void _ftpQEHandler_RelayConnect(FtpQEvent *e_p)
{
   FtpQEvent event = *e_p;   // Make a copy
   typeless status=0;
   _str response="";
   _str msg="";
   typeless temp_host="";
   typeless temp_port="";

   // Listening for vsproxy to connect a relay socket to us
   switch( event.state ) {
   case QS_BEGIN:
      // Event begins
      status=vssGetLocalSocketInfo(event.fcp.vsproxy_sock,temp_host,temp_port);
      if( status ) {
         msg="Error opening a relay connection.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }
      temp_host=_MultiByteToUTF8(temp_host);
      temp_port=_MultiByteToUTF8(temp_port);
      int temp_sock=0;
      status=vssSocketOpen(_UTF8ToMultiByte(temp_host),"0",temp_sock,1,SOCKDEF_CONNECT_TIMEOUT);
      if( status ) {
         msg="Error opening a relay connection.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }
      // Get the port that was dynamically assigned
      status=vssGetLocalSocketInfo(temp_sock,temp_host,temp_port);
      if( status ) {
         msg="Error opening a relay connection.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }
      temp_host=_MultiByteToUTF8(temp_host);
      temp_port=_MultiByteToUTF8(temp_port);
      event.fcp.sock=temp_sock;   // This socket will change once a connection is accepted
      status=_ftpVSProxyCommand(&event.fcp,"OPENRELAY",temp_host,temp_port);
      if( status ) {
         msg="Error opening a relay connection.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_LISTENING,event.start,&event.fcp);
      return;

      break;
   case QS_LISTENING:
      status=vssSocketAcceptConn(event.fcp.sock);
      if( status ) {
         if( status==SOCK_NO_CONN_PENDING_RC ) {
            double elapsed=((double)_time('B')-event.start+1)/1000;   // Seconds
            if( elapsed>FTPDEF_TIMEOUT ) {
               // We timed out
               msg="Timed out waiting for relay connection from SlickEdit proxy";
               _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,SOCK_TIMED_OUT_RC);
            } else {
               // No connection attempt has been made yet, so nothing has
               // changed. Re-queue with the same start time.
               _ftpEnQ(event.event,event.state,event.start,&event.fcp);
            }
            return;
         } else {
            msg="Error waiting for relay connection from SlickEdit proxy.  ":+_ftpGetMessage(status);
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
            return;
         }
         break;
      }
      _ftpEnQ(event.event,QS_WAITING_FOR_REPLY,0,&event.fcp);
      return;
      break;
   case QS_WAITING_FOR_REPLY:
      // Waiting for the OPENRELAY response from the SE proxy
      status=_ftpQCheckResponse(&event,true,response,true);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp);
         return;
      }
      if( status ) {
         msg="Error with OPENRELAY response from SlickEdit proxy.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }
      parse response with status .;
      if( status=="+ok" ) {
         // We now have a relay connection with the SE proxy.
         // Now we need to open a connection with the ftp server
         // through the control connection.
         _ftpEnQ(QE_PROXY_OPEN,QS_BEGIN,0,&event.fcp);
         return;
      } else {
         // Should never get here
         msg="Unexpected response from SlickEdit proxy:\n\n":+response;
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,VSRC_FTP_BAD_RESPONSE);
         return;
      }
      break;
   case QS_ERROR:
      // An error occurred getting the relay connection, so clean up
      _ftpDeleteLogBuffer(&event.fcp);
      if( event.fcp.vsproxy_sock!=INVALID_SOCKET ) {
         _ftpVSProxyCommand(&event.fcp,"QUIT");
         vssSocketClose(event.fcp.vsproxy_sock);
         event.fcp.vsproxy_sock=INVALID_SOCKET;
         event.fcp.vsproxy_pid= -1;
      }
      _ftpQEventDisplayError(event);
      break;
   case QS_ABORT:
      _ftpDeleteLogBuffer(&event.fcp);
      if( event.fcp.vsproxy_sock!=INVALID_SOCKET ) {
         _ftpVSProxyCommand(&event.fcp,"QUIT");
         vssSocketClose(event.fcp.vsproxy_sock);
         event.fcp.vsproxy_sock=INVALID_SOCKET;
         event.fcp.vsproxy_pid= -1;
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

void _ftpQEHandler_ProxyOpen(FtpQEvent *e_p)
{
   FtpQEvent event = *e_p;   // Make a copy
   typeless status=0;
   _str response="";
   _str msg="";

   // Connection to ftp server is being opened through SE proxy
   switch( event.state ) {
   case QS_BEGIN:
      // Event begins
      boolean use_firewall= (event.fcp.useFirewall && event.fcp.global_options.fwenable);
      if( use_firewall ) {
         if( event.fcp.global_options.fwtype==FTPOPT_FWTYPE_USERAT ) {
            status=_ftpVSProxyCommand(&event.fcp,"OPEN",event.fcp.global_options.fwhost,event.fcp.global_options.fwport);
            if( status ) {
               msg="Error OPENing firewall connection: ":+event.fcp.global_options.fwhost:+":":+event.fcp.global_options.fwport:+".  ":+_ftpGetMessage(status);
               _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
               return;
            }
            _ftpEnQ(event.event,QS_WAITING_FOR_REPLY,0,&event.fcp);
            return;
         } else if( event.fcp.global_options.fwtype==FTPOPT_FWTYPE_OPEN ) {
            status=_ftpVSProxyCommand(&event.fcp,"OPEN",event.fcp.global_options.fwhost,event.fcp.global_options.fwport);
            if( status ) {
               msg="Error OPENing firewall connection: ":+event.fcp.global_options.fwhost:+":":+event.fcp.global_options.fwport:+".  ":+_ftpGetMessage(status);
               _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
               return;
            }
            _ftpEnQ(event.event,QS_WAITING_FOR_REPLY,0,&event.fcp);
            return;
         } else if( event.fcp.global_options.fwtype==FTPOPT_FWTYPE_USERLOGON ) {
            status=_ftpVSProxyCommand(&event.fcp,"OPEN",event.fcp.global_options.fwhost,event.fcp.global_options.fwport);
            if( status ) {
               msg="Error OPENing firewall connection: ":+event.fcp.global_options.fwhost:+":":+event.fcp.global_options.fwport:+".  ":+_ftpGetMessage(status);
               _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
               return;
            }
            _ftpEnQ(event.event,QS_WAITING_FOR_REPLY,0,&event.fcp);
            return;
         } else if( event.fcp.global_options.fwtype==FTPOPT_FWTYPE_ROUTER ) {
            // This is transparent to the SE proxy and will usually be a
            // router firewall. The only thing unique about a "Router"
            // firewall is that it uses passive (PASV) transfers.
            status=_ftpVSProxyCommand(&event.fcp,"OPEN",event.fcp.host,event.fcp.port);
            if( status ) {
               msg="Error OPENing connection: ":+event.fcp.host:+":":+event.fcp.port:+".  ":+_ftpGetMessage(status);
               _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
               return;
            }
            _ftpEnQ(event.event,QS_WAITING_FOR_REPLY,0,&event.fcp);
            return;
         } else {
            // This should never happen
            msg="Undefined firewall/proxy type";
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,VSRC_FTP_BAD_CONFIG);
            return;
         }
      } else {
         status=_ftpVSProxyCommand(&event.fcp,"OPEN",event.fcp.host,event.fcp.port);
         if( status ) {
            msg="Error OPENing connection: ":+event.fcp.host:+":":+event.fcp.port:+".  ":+_ftpGetMessage(status);
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
            return;
         }
         _ftpEnQ(event.event,QS_WAITING_FOR_REPLY,0,&event.fcp);
         return;
      }
      break;
   case QS_WAITING_FOR_REPLY:
      // Waiting for the OPEN response from the SE proxy
      status=_ftpQCheckResponse(&event,true,response,true);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp);
         return;
      }
      if( status ) {
         msg="Error OPENing connection to ftp server from SlickEdit proxy.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }
      // Expecting something like:
      //
      // +ok Connected to [192.168.30.5]:21 from [192.168.0.165]:2670
      _str temp_host, temp_port;
      parse response with status 'Connected to ' temp_host .;
      if( status=="+ok" ) {
         // Need to cache the actual remote FTP server address in order to
         // determine if FTP server is IPv4 or IPv6. This determines whether
         // to use PASV or EPSV for example.
         parse temp_host with '['temp_host']:'temp_port;
         event.fcp.remote_address = temp_host;
         // Now we need to check the sign-on response from the ftp server
         _ftpEnQ(QE_OPEN,QS_BEGIN,0,&event.fcp);
         return;
      } else {
         // Should never get here
         msg="Unexpected response from SlickEdit proxy:\n\n":+response;
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,VSRC_FTP_BAD_RESPONSE);
         return;
      }
      break;
   case QS_ERROR:
      // An error occurred getting the ftp connection through the SE proxy, so clean up
      _ftpDeleteLogBuffer(&event.fcp);
      if( event.fcp.sock!=INVALID_SOCKET ) {
         vssSocketClose(event.fcp.sock);
         event.fcp.sock=INVALID_SOCKET;
      }
      if( event.fcp.vsproxy_sock!=INVALID_SOCKET ) {
         _ftpVSProxyCommand(&event.fcp,"QUIT");
         vssSocketClose(event.fcp.vsproxy_sock);
         event.fcp.vsproxy_sock=INVALID_SOCKET;
         event.fcp.vsproxy_pid= -1;
      }
      _ftpQEventDisplayError(event);
      return;
      break;
   case QS_ABORT:
      // Event aborted
      _ftpDeleteLogBuffer(&event.fcp);
      if( event.fcp.sock!=INVALID_SOCKET ) {
         vssSocketClose(event.fcp.sock);
         event.fcp.sock=INVALID_SOCKET;
      }
      if( event.fcp.vsproxy_sock!=INVALID_SOCKET ) {
         _ftpVSProxyCommand(&event.fcp,"QUIT");
         vssSocketClose(event.fcp.vsproxy_sock);
         event.fcp.vsproxy_sock=INVALID_SOCKET;
         event.fcp.vsproxy_pid= -1;
      }
      return;
      break;
   case QS_END:
      // Event ends
      break;
   default:
      // Should never get here
      msg="Unknown FTP queue event state: ":+event.state:+" for event ":+event.event;
      _message_box(msg,FTP_ERRORBOX_TITLE,MB_OK|MB_ICONEXCLAMATION);
      return;
   }

   return;
}

void _ftpQEHandler_Open(FtpQEvent *e_p)
{
   FtpQEvent event = *e_p;   // Make a copy
   typeless status=0;
   _str response="";
   _str msg="";

   // Now we are logging on to the ftp server through the relay connection
   switch( event.state ) {
   case QS_BEGIN:
      // Event begins
      // Fall thru to QS_WAITING_FOR_REPLY (they are really the same thing)
      event.state=QS_WAITING_FOR_REPLY;
   case QS_WAITING_FOR_REPLY:
      // Waiting for the connection response from ftp server
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp);
         return;
      }
      if( status ) {
         msg="Error connecting to: ":+event.fcp.host:+":":+event.fcp.port:+".  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }

      boolean use_firewall= (event.fcp.useFirewall && event.fcp.global_options.fwenable);
      if( use_firewall ) {
         if( event.fcp.global_options.fwtype==FTPOPT_FWTYPE_USERLOGON ) {
            // We must first logon to the firewall
            _ftpEnQ(QE_FIREWALL_SPECIAL,QS_BEGIN,0,&event.fcp);
            return;
         } else if( event.fcp.global_options.fwtype==FTPOPT_FWTYPE_OPEN ) {
            // We must first OPEN the site
            _ftpEnQ(QE_FIREWALL_SPECIAL,QS_BEGIN,0,&event.fcp);
            return;
         }
      }

      if( event.fcp.system==FTPSYST_AUTO ) {
         // Special check for a Hummingbird or VxWorks host because they
         // do not support the SYST command.
         //
         // If this is a non-router type firewall then delay the check until
         // we get the banner from the actual host.
         if( (!use_firewall || event.fcp.global_options.fwtype==FTPOPT_FWTYPE_ROUTER) ) {
            if( pos('Hummingbird Communications',response) ) {
               event.fcp.system=FTPSYST_HUMMINGBIRD;
            } else if( pos('VxWorks',response) ) {
               event.fcp.system=FTPSYST_VXWORKS;
            }
         }
      }

      // Now we must send "USER userid"
      if( event.fcp.savePassword ) {
         _ftpEnQ(QE_USER,QS_BEGIN,0,&event.fcp);
      } else {
         // User must be prompted
         _ftpEnQ(QE_USER,QS_PROMPT,0,&event.fcp);
      }
      return;
      break;
   case QS_ERROR:
      // An error occurred logging on to ftp server
      _ftpDeleteLogBuffer(&event.fcp);
      if( event.fcp.sock!=INVALID_SOCKET ) {
         vssSocketClose(event.fcp.sock);
         event.fcp.sock=INVALID_SOCKET;
      }
      if( event.fcp.vsproxy_sock!=INVALID_SOCKET ) {
         _ftpVSProxyCommand(&event.fcp,"QUIT");
         vssSocketClose(event.fcp.vsproxy_sock);
         event.fcp.vsproxy_sock=INVALID_SOCKET;
         event.fcp.vsproxy_pid= -1;
      }
      _ftpQEventDisplayError(event);
      return;
   case QS_ABORT:
      // Event aborted
      _ftpDeleteLogBuffer(&event.fcp);
      if( event.fcp.sock!=INVALID_SOCKET ) {
         vssSocketClose(event.fcp.sock);
         event.fcp.sock=INVALID_SOCKET;
      }
      if( event.fcp.vsproxy_sock!=INVALID_SOCKET ) {
         _ftpVSProxyCommand(&event.fcp,"QUIT");
         vssSocketClose(event.fcp.vsproxy_sock);
         event.fcp.vsproxy_sock=INVALID_SOCKET;
         event.fcp.vsproxy_pid= -1;
      }
      return;
   default:
      // Should never get here
      msg="Unknown FTP queue event state: ":+event.state:+" for event ":+event.event;
      _message_box(msg,FTP_ERRORBOX_TITLE,MB_OK|MB_ICONEXCLAMATION);
      return;
   }

   return;
}

/*
 * This function handles firewalls that are more complex. Like those that
 * require a user to logon to the firewall before opening an ftp site, or
 * those that require an "OPEN" to be issued.
 */
void _ftpQEHandler_FirewallSpecial(FtpQEvent *e_p)
{
   FtpQEvent event = *e_p;   // Make a copy
   typeless status=0;
   _str response="";
   _str msg="";

   switch( event.state ) {
   case QS_BEGIN:
      // Event begins
      boolean use_firewall= (event.fcp.useFirewall && event.fcp.global_options.fwenable);
      if( use_firewall ) {
         if( event.fcp.global_options.fwtype==FTPOPT_FWTYPE_USERLOGON ) {
            _str fwuser=event.fcp.global_options.fwuserid;
            _str fwpass=event.fcp.global_options.fwpassword;
            if( fwuser=="" || fwpass=="" ) {
               _ftpEnQ(event.event,QS_PROMPT,0,&event.fcp);
               return;
            }
            status=_ftpCommand(&event.fcp,false,"USER",fwuser);
            if( status ) {
               msg="Error sending logon USER to firewall host: ":+event.fcp.global_options.fwhost:+":":+event.fcp.global_options.fwport:+".  ":+_ftpGetMessage(status);
               _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
               return;
            }
            _ftpEnQ(event.event,QS_FWUSER_WAITING_FOR_REPLY,0,&event.fcp);
            return;
         } else if( event.fcp.global_options.fwtype==FTPOPT_FWTYPE_OPEN ) {
            _str host=event.fcp.host;
            // As far as I can tell, other ftp clients ignore the port
            // setting when using this firewall type, so we will too.
            status=_ftpCommand(&event.fcp,false,"OPEN",host);
            if( status ) {
               msg="Error sending OPEN to firewall host: ":+event.fcp.global_options.fwhost:+":":+event.fcp.global_options.fwport:+".  ":+_ftpGetMessage(status);
               _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
               return;
            }
            _ftpEnQ(event.event,QS_FWOPEN_WAITING_FOR_REPLY,0,&event.fcp);
            return;
         } else {
            // This should never happen, but we'll pass it on through
            _ftpEnQ(QE_USER,QS_BEGIN,0,&event.fcp);
            return;
         }
      }
      return;
      break;
   case QS_PROMPT:
      // Prompt for firewall userid/password
      _str result:[];
      result._makeempty();
      _str user=event.fcp.global_options.fwuserid;
      _str pass=event.fcp.global_options.fwpassword;
      if( pass!="" ) {
         typeless plain="";
         status=vssDecrypt(pass,plain);
         if( status ) {
            event.fcp.global_options.fwpassword="";
            msg="Error retrieving firewall password";
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
            return;
         }
         pass=plain;
      }
      _str caption="Firewall Logon";
      status=show("-modal _ftpUserPass_form",&result,caption,user,pass);
      if( status=='' || status!=0 ) {
         // The use cancelled, so we're done. Now cleanup
         _ftpDeleteLogBuffer(&event.fcp);
         if( event.fcp.sock!=INVALID_SOCKET ) {
            vssSocketClose(event.fcp.sock);
         }
         if( event.fcp.vsproxy_sock!=INVALID_SOCKET ) {
            _ftpVSProxyCommand(&event.fcp,"QUIT");
            vssSocketClose(event.fcp.vsproxy_sock);
            event.fcp.vsproxy_sock=INVALID_SOCKET;
            event.fcp.vsproxy_pid= -1;
         }
         _ftpEnQ(event.event,QS_ABORT,0,&event.fcp);
         return;
      }
      user=result:["user"];
      pass=result:["pass"];
      event.fcp.global_options.fwuserid=user;
      if( pass!="" ) {
         _str cipher="";
         status=vssEncrypt(pass,cipher);
         if( status ) {
            event.fcp.password="";
            msg="Error saving firewall password";
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
            return;
         }
         event.fcp.global_options.fwpassword=cipher;
      } else {
         event.fcp.password=pass;
      }
      _ftpEnQ(event.event,QS_BEGIN,0,&event.fcp);
      return;
      break;
   case QS_FWUSER_WAITING_FOR_REPLY:
      // Waiting for the firewall user logon response
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp);
         return;
      }
      if( status ) {
         msg="Error with firewall user logon.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }
      // Now we must send "PASS fwpass"
      use_firewall= (event.fcp.useFirewall && event.fcp.global_options.fwenable);
      if( use_firewall ) {
         if( event.fcp.global_options.fwtype==FTPOPT_FWTYPE_USERLOGON ) {
            _str fwpass=event.fcp.global_options.fwpassword;
            if( fwpass!="" ) {
               _str plain="";
               status=vssDecrypt(fwpass,plain);
               if( status ) {
                  msg="Error retrieving firewall password";
                  _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
                  return;
               }
               fwpass=plain;
            }
            status=_ftpPass(&event.fcp,fwpass);
            if( status ) {
               msg="Error sending logon PASS to firewall host: ":+event.fcp.global_options.fwhost:+":":+event.fcp.global_options.fwport:+".  ":+_ftpGetMessage(status);
               _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
               return;
            }
            _ftpEnQ(event.event,QS_FWPASS_WAITING_FOR_REPLY,0,&event.fcp);
            return;
         } else {
            // This should never happen
            msg="This firewall does not support a user/pass logon";
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,VSRC_FTP_BAD_CONFIG);
            return;
         }
      } else {
         // This should never happen
         msg="Error attempting to logon to firewall when there is no firewall setup";
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,VSRC_FTP_BAD_CONFIG);
         return;
      }
      return;
      break;
   case QS_FWPASS_WAITING_FOR_REPLY:
      // Waiting for the firewall password response
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp);
         return;
      }
      if( status ) {
         msg="Error with firewall user logon.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }
      // Now we must logon to the ftp server
      if( event.fcp.savePassword ) {
         _ftpEnQ(QE_USER,QS_BEGIN,0,&event.fcp);
      } else {
         // User must be prompted
         _ftpEnQ(QE_USER,QS_PROMPT,0,&event.fcp);
      }
      return;
      break;
   case QS_FWOPEN_WAITING_FOR_REPLY:
      // Waiting for the firewall OPEN response
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp);
         return;
      }
      if( status ) {
         msg="Error with firewall OPEN response.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }

      if( event.fcp.system==FTPSYST_AUTO ) {
         // Special check for a Hummingbird or VxWorks host because they
         // do not support the SYST command.
         //
         // We do this check here because we get the banner from the host
         // only after going through these firewalls.
         if( pos('Hummingbird Communications',response) ) {
            event.fcp.system=FTPSYST_HUMMINGBIRD;
         } else if( pos('VxWorks',response) ) {
            event.fcp.system=FTPSYST_VXWORKS;
         }
      }

      // Now we must logon to the ftp server
      if( event.fcp.savePassword ) {
         _ftpEnQ(QE_USER,QS_BEGIN,0,&event.fcp);
      } else {
         // User must be prompted
         _ftpEnQ(QE_USER,QS_PROMPT,0,&event.fcp);
      }
      return;
      break;
   case QS_ERROR:
      // An error occurred logging on to firewall
      _ftpDeleteLogBuffer(&event.fcp);
      if( event.fcp.sock!=INVALID_SOCKET ) {
         vssSocketClose(event.fcp.sock);
         event.fcp.sock=INVALID_SOCKET;
      }
      if( event.fcp.vsproxy_sock!=INVALID_SOCKET ) {
         _ftpVSProxyCommand(&event.fcp,"QUIT");
         vssSocketClose(event.fcp.vsproxy_sock);
         event.fcp.vsproxy_sock=INVALID_SOCKET;
         event.fcp.vsproxy_pid= -1;
      }
      _ftpQEventDisplayError(event);
      return;
   case QS_ABORT:
      // Event aborted
      _ftpDeleteLogBuffer(&event.fcp);
      if( event.fcp.sock!=INVALID_SOCKET ) {
         vssSocketClose(event.fcp.sock);
         event.fcp.sock=INVALID_SOCKET;
      }
      if( event.fcp.vsproxy_sock!=INVALID_SOCKET ) {
         _ftpVSProxyCommand(&event.fcp,"QUIT");
         vssSocketClose(event.fcp.vsproxy_sock);
         event.fcp.vsproxy_sock=INVALID_SOCKET;
         event.fcp.vsproxy_pid= -1;
      }
      return;
   default:
      // Should never get here
      msg="Unknown FTP queue event state: ":+event.state:+" for event ":+event.event;
      _message_box(msg,FTP_ERRORBOX_TITLE,MB_OK|MB_ICONEXCLAMATION);
      return;
   }

   return;
}

void _ftpQEHandler_User(FtpQEvent *e_p)
{
   FtpQEvent event = *e_p;   // Make a copy
   typeless status=0;
   _str response="";
   _str msg="";

   // Sending user id to ftp server
   switch( event.state ) {
   case QS_BEGIN:
      // Event begins
      boolean use_firewall= (event.fcp.useFirewall && event.fcp.global_options.fwenable);
      if( use_firewall ) {
         if( event.fcp.global_options.fwtype==FTPOPT_FWTYPE_USERAT ||
             event.fcp.global_options.fwtype==FTPOPT_FWTYPE_USERLOGON ) {
            _str fwuser=event.fcp.userId:+'@':+event.fcp.host;
            status=_ftpCommand(&event.fcp,false,"USER",fwuser);
            if( status ) {
               msg="Error sending USER to firewall host: ":+event.fcp.global_options.fwhost:+":":+event.fcp.global_options.fwport:+".  ":+_ftpGetMessage(status);
               _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
               return;
            }
            _ftpEnQ(QE_USER,QS_WAITING_FOR_REPLY,0,&event.fcp);
            return;
         } else if( event.fcp.global_options.fwtype==FTPOPT_FWTYPE_OPEN ) {
            // The "OPEN host" is done, so now we just login to the
            // ftp server as usual.
            status=_ftpCommand(&event.fcp,false,"USER",event.fcp.userId);
            if( status ) {
               msg="Error sending USER to firewall host: ":+event.fcp.global_options.fwhost:+":":+event.fcp.global_options.fwport:+".  ":+_ftpGetMessage(status);
               _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
               return;
            }
            _ftpEnQ(QE_USER,QS_WAITING_FOR_REPLY,0,&event.fcp);
            return;
         } else if( event.fcp.global_options.fwtype==FTPOPT_FWTYPE_ROUTER ) {
            // Fall thru to sending the "USER" line. The only unique thing
            // about this firewall type is that it requires passive (PASV)
            // transfers (usually through a router).
         } else {
            // This should never happen
            msg="Undefined firewall/proxy type";
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,VSRC_FTP_BAD_CONFIG);
            return;
         }
      }
      status=_ftpCommand(&event.fcp,false,"USER",event.fcp.userId);
      if( status ) {
         msg="Error sending USER to ftp host: ":+event.fcp.host:+":":+event.fcp.port:+".  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }
      _ftpEnQ(QE_USER,QS_WAITING_FOR_REPLY,0,&event.fcp);
      return;
      break;
   case QS_PROMPT:
      // Prompt for userid/password
      _str result:[];
      result._makeempty();
      _str user=event.fcp.userId;
      _str pass=event.fcp.password;
      if( !event.fcp.anonymous && pass!="" ) {
         _str plain="";
         status=vssDecrypt(pass,plain);
         if( status ) {
            event.fcp.password="";
            msg="Error retrieving password";
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
            return;
         }
         pass=plain;
      }
      _str caption="";
      if( !event.info._isempty() ) {
         caption=event.info[0];   // This is probably a bad response from ftp server
      }
      status=show("-modal _ftpUserPass_form",&result,caption,user,pass);
      if( status=='' || status!=0 ) {
         // The user cancelled, so we are done. Now cleanup
         _ftpDeleteLogBuffer(&event.fcp);
         if( event.fcp.sock!=INVALID_SOCKET ) {
            vssSocketClose(event.fcp.sock);
         }
         if( event.fcp.vsproxy_sock!=INVALID_SOCKET ) {
            _ftpVSProxyCommand(&event.fcp,"QUIT");
            vssSocketClose(event.fcp.vsproxy_sock);
            event.fcp.vsproxy_sock=INVALID_SOCKET;
            event.fcp.vsproxy_pid= -1;
         }
         _ftpEnQ(event.event,QS_ABORT,0,&event.fcp);
         return;
      }
      user=result:["user"];
      pass=result:["pass"];
      event.fcp.userId=user;
      if( event.fcp.anonymous ) {
         event.fcp.password=pass;
      } else {
         if( pass!="" ) {
            _str cipher="";
            status=vssEncrypt(pass,cipher);
            if( status ) {
               event.fcp.password="";
               msg="Error saving password";
               _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
               return;
            }
            event.fcp.password=cipher;
         } else {
            event.fcp.password=pass;
         }
      }
      _ftpEnQ(event.event,QS_BEGIN,0,&event.fcp);
      return;
      break;
   case QS_WAITING_FOR_REPLY:
      // Waiting for the USER response from ftp server
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp);
         return;
      }
      if( status ) {
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            // Retry the user/pass.
            // The last argument is an overriding caption for the
            // dialog that prompts for userid/password. This is so
            // the user sees the bad response from the ftp server.
            _ftpEnQ(event.event,QS_PROMPT,0,&event.fcp,event.fcp.lastStatusLine);
            return;
         }
         msg="Error connecting to: ":+event.fcp.host:+":":+event.fcp.port:+".  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }

      if( event.fcp.system==FTPSYST_AUTO ) {
         boolean used_firewall= (event.fcp.useFirewall && event.fcp.global_options.fwenable);
         if( used_firewall ) {
            if( event.fcp.global_options.fwtype==FTPOPT_FWTYPE_USERAT ||
                event.fcp.global_options.fwtype==FTPOPT_FWTYPE_USERLOGON ) {
               // Special check for a Hummingbird or VxWorks host because they
               // do not support the SYST command.
               //
               // We do this check here because we get the banner from the host
               // only after going through these firewalls.
               if( pos('Hummingbird Communications',response) ) {
                  event.fcp.system=FTPSYST_HUMMINGBIRD;
               } else if( pos('VxWorks',response) ) {
                  event.fcp.system=FTPSYST_VXWORKS;
               }
            }
         }
      }

      _str code="";
      boolean nopassword=false;
      parse response with code .;
      code=strip(code,'T','-');
      if( isinteger(code) && substr(code,1,1)=='2' ) nopassword=true;
      if( nopassword ) {
         // A password is not required for this login.
         // Now we must set/get the current working directory (CWD).
         _ftpEnQ(QE_CWD,QS_BEGIN,0,&event.fcp,event.fcp.defRemoteDir);
         return;
      } else {
         // Now we must send "PASS password"
         _ftpEnQ(QE_PASS,QS_BEGIN,0,&event.fcp);
         return;
      }
      break;
   case QS_ERROR:
      // An error occurred logging on to ftp server
      _ftpDeleteLogBuffer(&event.fcp);
      if( event.fcp.sock!=INVALID_SOCKET ) {
         vssSocketClose(event.fcp.sock);
         event.fcp.sock=INVALID_SOCKET;
      }
      if( event.fcp.vsproxy_sock!=INVALID_SOCKET ) {
         _ftpVSProxyCommand(&event.fcp,"QUIT");
         vssSocketClose(event.fcp.vsproxy_sock);
         event.fcp.vsproxy_sock=INVALID_SOCKET;
         event.fcp.vsproxy_pid= -1;
      }
      _ftpQEventDisplayError(event);
      return;
      break;
   case QS_ABORT:
      // Event aborted
      _ftpDeleteLogBuffer(&event.fcp);
      if( event.fcp.sock!=INVALID_SOCKET ) {
         vssSocketClose(event.fcp.sock);
         event.fcp.sock=INVALID_SOCKET;
      }
      if( event.fcp.vsproxy_sock!=INVALID_SOCKET ) {
         _ftpVSProxyCommand(&event.fcp,"QUIT");
         vssSocketClose(event.fcp.vsproxy_sock);
         event.fcp.vsproxy_sock=INVALID_SOCKET;
         event.fcp.vsproxy_pid= -1;
      }
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

void _ftpQEHandler_Pass(FtpQEvent *e_p)
{
   FtpQEvent event = *e_p;   // Make a copy
   typeless status=0;
   _str response="";
   _str msg="";

   // Sending password to ftp server
   switch( event.state ) {
   case QS_BEGIN:
      // Event begins
      _str pass=event.fcp.password;
      if( !event.fcp.anonymous && pass!="" ) {
         // Must decrypt
         _str plain="";
         status=vssDecrypt(pass,plain);
         if( status ) {
            msg="Error retrieving password";
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
            return;
         }
         pass=plain;
      }
      status=_ftpPass(&event.fcp,pass);
      if( status ) {
         msg="Error sending PASS to ftp host: ":+event.fcp.host:+":":+event.fcp.port:+".  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_WAITING_FOR_REPLY,0,&event.fcp);
      return;
      break;
   case QS_WAITING_FOR_REPLY:
      // Waiting for the PASS response from ftp server
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp);
         return;
      }
      if( status ) {
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            // Retry the user/pass.
            // The last argument is an overriding caption for the
            // dialog that prompts for userid/password. This is so
            // the user sees the bad response from the ftp server.
            _ftpEnQ(QE_USER,QS_PROMPT,0,&event.fcp,event.fcp.lastStatusLine);
            return;
         }
         msg="Error connecting to: ":+event.fcp.host:+":":+event.fcp.port:+".  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }
      // Now we must set/get the current working directory (CWD)
      _ftpEnQ(QE_CWD,QS_BEGIN,0,&event.fcp,event.fcp.defRemoteDir);
      return;
      break;
   case QS_ERROR:
      // An error occurred logging on to ftp server
      _ftpDeleteLogBuffer(&event.fcp);
      if( event.fcp.sock!=INVALID_SOCKET ) {
         vssSocketClose(event.fcp.sock);
         event.fcp.sock=INVALID_SOCKET;
      }
      if( event.fcp.vsproxy_sock!=INVALID_SOCKET ) {
         _ftpVSProxyCommand(&event.fcp,"QUIT");
         vssSocketClose(event.fcp.vsproxy_sock);
         event.fcp.vsproxy_sock=INVALID_SOCKET;
         event.fcp.vsproxy_pid= -1;
      }
      _ftpQEventDisplayError(event);
      return;
      break;
   case QS_ABORT:
      // Event aborted
      _ftpDeleteLogBuffer(&event.fcp);
      if( event.fcp.sock!=INVALID_SOCKET ) {
         vssSocketClose(event.fcp.sock);
         event.fcp.sock=INVALID_SOCKET;
      }
      if( event.fcp.vsproxy_sock!=INVALID_SOCKET ) {
         _ftpVSProxyCommand(&event.fcp,"QUIT");
         vssSocketClose(event.fcp.vsproxy_sock);
         event.fcp.vsproxy_sock=INVALID_SOCKET;
         event.fcp.vsproxy_pid= -1;
      }
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

void _ftpQEHandler_Cdup(FtpQEvent *e_p)
{
   FtpQEvent event = *e_p;   // Make a copy
   typeless status=0;
   _str response="";
   _str msg="";

   // CDUP to the parent directory
   switch( event.state ) {
   case QS_BEGIN:
      // Event begins
      status=_ftpCommand(&event.fcp,false,"CDUP");
      if( status ) {
         msg="Error sending CDUP.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_WAITING_FOR_REPLY,0,&event.fcp);
      return;
      break;
   case QS_WAITING_FOR_REPLY:
      // Waiting for the CDUP response from ftp server
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp);
         return;
      }
      if( status ) {
         msg="Error changing remote directory.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }
      // We are expecting something like:
      //
      // 250 "/pub/demos" is new cwd.
      //
      // Only use PWD to actually get the current working directory, even after
      // successful CDUP because we could be changing directory on a symbolic link.
      // PWD would return something completely different in this case.  Also can
      // not depend on CDUP to give the new current working directory like PWD.
      _ftpEnQ(QE_PWD,QS_BEGIN,0,&event.fcp);
      return;
      break;
   case QS_ERROR:
      // An error occurred with CDUP
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

void _ftpQEHandler_Cwd(FtpQEvent *e_p)
{
   FtpQEvent event = *e_p;   // Make a copy
   typeless status=0;
   _str response="";
   _str msg="";
   _str cwd;
   _str pre_cmds[];
   _str cmdline="";

   cwd="";
   pre_cmds._makeempty();
   if( !event.info[0]._isempty() ) {
      if( event.info._length()>0 ) {
         cwd=event.info[0];
      }
      if( event.info._length()>1 ) {
         pre_cmds=event.info[1];
      }
   }

   switch( event.state ) {
   case QS_CMD_BEFORE_BEGIN:
      // Special case for CWDs. Issue a command before proceeding.
      // Example: OS/400 hosts issue a NAMEFMT command to set the
      // file system before changing directory.
      if( cwd=="" ) {
         // There is nothing to process, not even a directory
         _ftpEnQ(event.event,QS_BEGIN,0,&event.fcp);
         return;
      }
      if( !pre_cmds._length() ) {
         // This should never happen
         _ftpEnQ(event.event,QS_BEGIN,0,&event.fcp,cwd);
         return;
      }
      cmdline=pre_cmds[0];
      pre_cmds._deleteel(0);
      status=_ftpCommand(&event.fcp,false,cmdline);
      if( status ) {
         msg="Error sending command: ":+cmdline:+".  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_CMD_BEFORE_WAITING_FOR_REPLY,0,&event.fcp,cwd,pre_cmds);
      return;
      break;
   case QS_CMD_BEFORE_WAITING_FOR_REPLY:
      // Waiting for the command response from ftp server
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,cwd,pre_cmds);
         return;
      }
      if( status ) {
         msg="Error with command response.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }
      if( pre_cmds._length() ) {
         // More pre commands to process
         _ftpEnQ(event.event,QS_CMD_BEFORE_BEGIN,0,&event.fcp,cwd,pre_cmds);
      } else {
         // Now we can start the CWD
         _ftpEnQ(event.event,QS_BEGIN,0,&event.fcp,cwd);
      }
      return;
      break;
   case QS_BEGIN:
      // Event begins
      if( cwd!="" ) {
         #if 0
         if( event.fcp.System==FTPSYST_MVS ) {
            // Make sure this is not an HFS file system
            currcwd=event.fcp.RemoteCWD;
            if( currcwd!="" && substr(currcwd,1,1)!='/' && substr(cwd,1,1)!='/' &&
                (substr(cwd,1,1)!="'" || last_char(cwd)!="'") ) {
               // We have to make the directory absolute by enclosing with
               // single-quotes. Otherwise it would be relative to the
               // current PDS.
               cwd=strip(cwd,'B',"'");
               cwd="'":+cwd:+"'";
            }
         }
         #endif
         status=_ftpCommand(&event.fcp,false,"CWD",cwd);
         if( status ) {
            msg="Error sending CWD.  ":+_ftpGetMessage(status);
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
            return;
         }
         _ftpEnQ(event.event,QS_WAITING_FOR_REPLY,0,&event.fcp);
      } else {
         // There is no directory to change to, so just get the current working directory.
         //
         // Only use PWD to actually get the current working directory, even after
         // successful CWD because we could be changing directory on a symbolic link.
         // PWD would return something completely different in this case.  Also can
         // not depend on CDUP to give the new current working directory like PWD.
         _ftpEnQ(QE_PWD,QS_BEGIN,0,&event.fcp);
      }
      return;
      break;
   case QS_WAITING_FOR_REPLY:
      // Waiting for the CWD response from ftp server
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp);
         return;
      }
      if( status ) {
         msg="Error changing remote directory.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }
      // We are expecting something like:
      //
      // 250 "/home/slick/www-slickedit" is new cwd.
      //
      // Only use PWD to actually get the current working directory, even after
      // successful CWD because we could be changing directory on a symbolic link.
      // PWD would return something completely different in this case.  Also can
      // not depend on CDUP to give the new current working directory like PWD.
      _ftpEnQ(QE_PWD,QS_BEGIN,0,&event.fcp);
      return;
      break;
   case QS_ERROR:
      // An error occurred with CWD
      // The CWD handler must be silent for the error, since it does not know
      // whether we are trying to process a link. The post-callback will handle
      // the error message.
      //_ftpQEventDisplayError(event);
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

void _ftpQEHandler_Pwd(FtpQEvent *e_p)
{
   FtpQEvent event = *e_p;   // Make a copy
   typeless status=0;
   _str response="";
   _str msg="";
   _str pwd="";
   _str rest="";

   switch( event.state ) {
   case QS_BEGIN:
      // Event begins
      status=_ftpCommand(&event.fcp,false,"PWD");
      if( status ) {
         msg="Error sending PWD.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_WAITING_FOR_REPLY,0,&event.fcp);
      return;
      break;
   case QS_WAITING_FOR_REPLY:
      // Waiting for the PWD response from ftp server
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp);
         return;
      }
      if( status ) {
         msg="Error getting remote current working directory.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }
      // We are expecting something like:
      //
      // 257 "/home/slick/www-slickedit" is cwd.
      //
      // Strip off the linebreak char(s)
      response=translate(response,"","\r\n");
      pwd="";
      int syst=event.fcp.system;
      if( syst==FTPSYST_AUTO || syst==FTPSYST_MVS || syst==FTPSYST_VXWORKS ) {
         // Special check for PWD output like this:
         //
         // 257 HFS directory / is the working directory.
         //
         // or this:
         //
         // 257 Current directory is "/"
         //
         // where the working directory is not the first thing in the
         // string AND it might not be quoted.
         //
         // Parse off the result code
         parse response with . rest;
         rest=strip(rest);
         if( pos('^HFS directory ',rest,1,'r') ) {
            // MVS
            parse response with . 'HFS directory ' pwd .;
            pwd=strip(pwd,'B','"');   // Just in case
         } else if( pos('^Current directory is',rest,1,'ir') ) {
            // VxWorks
            parse response with . 'Current directory is' pwd .;
            pwd=strip(pwd,'B','"');
         }
      }
      if( pwd=="" ) {
         parse response with . pwd;
         pwd=strip(pwd);
         if( substr(pwd,1,1)=='"' ) {
            int i=lastpos('"',pwd);
            if( i ) {
               // A directory enclosed by quotes could have spaces in it,
               // so take the whole quoted string.
               pwd=substr(pwd,1,i);
            } else {
               // Strip off trailing non-directory text
               parse pwd with '"' pwd .;
            }
         } else {
            // Strip off trailing non-directory text
            parse pwd with pwd .;
         }
         pwd=strip(pwd,'B','"');
         // Some MVS hosts put inner single-quotes on the working directory
         pwd=strip(pwd,'B',"'");
         if( pwd=="" ) {
            // This should never happen
            msg="Attempt to change working directory failed.\n\n":+
                "PWD returned:\n\n":+'""';
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,PATH_NOT_FOUND_RC);
            return;
         }
      }
      event.fcp.remoteCwd=pwd;
      _ftpEnQ(event.event,QS_END,0,&event.fcp);
      return;
      break;
   case QS_ERROR:
      // An error occurred with PWD
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

void _ftpQEHandler_Syst(FtpQEvent *e_p)
{
   FtpQEvent event = *e_p;   // Make a copy
   typeless status=0;
   _str response="";
   _str msg="";

   switch( event.state ) {
   case QS_BEGIN:
      // Event begins
      status=_ftpCommand(&event.fcp,false,"SYST");
      if( status ) {
         msg="Error sending SYST.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_WAITING_FOR_REPLY,0,&event.fcp);
      return;
      break;
   case QS_WAITING_FOR_REPLY:
      // Waiting for the SYST response from ftp server
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp);
         return;
      }
      if( status ) {
         if( status!=VSRC_FTP_BAD_RESPONSE ) {
            msg="Error getting system name.\n\n":+event.fcp.lastStatusLine;
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         } else {
            // This ftp server does not support the SYST command
            _ftpLog(&event.fcp,"SYST command not supported");
         }
         if( event.fcp.system==FTPSYST_AUTO ) {
            // No way of finding host type automatically
            event.fcp.system=FTPSYST_DEFAULT;
         }
         return;
      }
      // We are expecting something like:
      //
      // 215 Windows_NT version 4.0
      if( event.fcp.system==FTPSYST_AUTO ) {
         // Auto, so figure it out
         typeless syst="";
         parse response with . syst;
         syst=strip(syst,'T',"\n");
         syst=strip(syst,'T',"\r");
         if( pos('UNIX',syst) == 1 ) {
            event.fcp.system=FTPSYST_UNIX;
         } else if( pos('Windows_NT',syst,1,'i') ) {
            event.fcp.system=FTPSYST_WINNT;
         } else if( pos('OS/2',syst) ) {
            event.fcp.system=FTPSYST_OS2;
         } else if( pos('VOS',syst,1,'iw') ) {
            event.fcp.system=FTPSYST_VOS;
         } else if( pos('MVS',syst,1,'iw') ) {
            event.fcp.system=FTPSYST_MVS;
         } else if( pos('VMS',syst,1,'iw') ) {
            if( pos('MultiNet',syst,1,'i') ) {
               event.fcp.system=FTPSYST_VMS_MULTINET;
            } else {
               event.fcp.system=FTPSYST_VMS;
            }
         } else if( pos('VM',syst,1,'iw') ) {
            if( pos('VM/ESA',syst) ) {
               event.fcp.system=FTPSYST_VMESA;
            } else {
               event.fcp.system=FTPSYST_VM;
            }
         } else if( pos('OS/400',syst) ) {
            event.fcp.system=FTPSYST_OS400;
         } else if( pos('Netware',syst) ) {
            event.fcp.system=FTPSYST_NETWARE;
         } else if( pos('MACOS',syst,1,'iw') ) {
            event.fcp.system=FTPSYST_MACOS;
         } else if( pos('VxWorks',syst,1,'iw') ) {
            // VxWorks hosts do not support the SYST command, but we
            // will put this here for completeness. Maybe they will
            // support it in future.
            event.fcp.system=FTPSYST_VXWORKS;
         } else {
            event.fcp.system=FTPSYST_DEFAULT;
         }
      }
      _ftpEnQ(event.event,QS_END,0,&event.fcp);
      return;
      break;
   case QS_ERROR:
      // An error occurred with SYST
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

void _ftpQEHandler_Mkd(FtpQEvent *e_p)
{
   FtpQEvent event = *e_p;   // Make a copy
   typeless status=0;
   _str response="";
   _str msg="";
   _str path="";

   if( !event.info._isempty() ) {
      path= (_str)event.info[0];
   }

   switch( event.state ) {
   case QS_BEGIN:
      // Event begins
      if( event.info[0]._isempty() || event.info[0]=="" ) {
         // Nothing to make
         msg="Not enough arguments for MKD";
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,path,msg,INVALID_ARGUMENT_RC);
         return;
      }
      status=_ftpCommand(&event.fcp,false,"MKD",path);
      if( status ) {
         msg="Error sending MKD.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,path,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_WAITING_FOR_REPLY,0,&event.fcp,path);
      return;
      break;
   case QS_WAITING_FOR_REPLY:
      // Waiting for the MKD response from ftp server
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,path);
         return;
      }
      if( status ) {
         msg="Error making remote directory.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,path,msg,status);
         return;
      }
      // We are expecting something like:
      //
      // 257 MKD command successful.
      return;   // Done
      break;
   case QS_ERROR:
      // An error occurred with MKD
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

void _ftpQEHandler_Dele(FtpQEvent *e_p)
{
   FtpQEvent event = *e_p;   // Make a copy
   typeless status=0;
   _str response="";
   _str msg="";
   _str path="";

   if( !event.info._isempty() ) {
      path= (_str)event.info[0];
   }

   switch( event.state ) {
   case QS_BEGIN:
      // Event begins
      if( event.info[0]._isempty() || event.info[0]=="" ) {
         // Nothing to delete
         msg="Not enough arguments for DELE";
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,path,msg,INVALID_ARGUMENT_RC);
         return;
      }
      status=_ftpCommand(&event.fcp,false,"DELE",path);
      if( status ) {
         msg="Error sending DELE.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,path,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_WAITING_FOR_REPLY,0,&event.fcp,path);
      return;
      break;
   case QS_WAITING_FOR_REPLY:
      // Waiting for the MKD response from ftp server
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,path);
         return;
      }
      if( status ) {
         msg="Error deleting file.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,path,msg,status);
         return;
      }
      // We are expecting something like:
      //
      // 250 DELE command successful.
      return;   // Done
      break;
   case QS_ERROR:
      // An error occurred with DELE
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

void _ftpQEHandler_Rmd(FtpQEvent *e_p)
{
   FtpQEvent event = *e_p;   // Make a copy
   typeless status=0;
   _str response="";
   _str msg="";
   _str path="";

   if( !event.info._isempty() ) {
      path= (_str)event.info[0];
   }

   switch( event.state ) {
   case QS_BEGIN:
      // Event begins
      if( event.info[0]._isempty() || event.info[0]=="" ) {
         // Nothing to delete
         msg="Not enough arguments for RMD";
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,path,msg,INVALID_ARGUMENT_RC);
         return;
      }
      status=_ftpCommand(&event.fcp,false,"RMD",path);
      if( status ) {
         msg="Error sending RMD.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,path,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_WAITING_FOR_REPLY,0,&event.fcp,path);
      return;
      break;
   case QS_WAITING_FOR_REPLY:
      // Waiting for the MKD response from ftp server
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,path);
         return;
      }
      if( status ) {
         msg="Error removing directory.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,path,msg,status);
         return;
      }
      // We are expecting something like:
      //
      // 250 RMD command successful.
      return;   // Done
      break;
   case QS_ERROR:
      // An error occurred with RMD
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

void _ftpQEHandler_Rename(FtpQEvent *e_p)
{
   FtpQEvent event = *e_p;   // Make a copy
   typeless status=0;
   _str response="";
   _str msg="";
   _str path="";

   _str rnfr="",rnto="";
   if( event.info._length()>=2 ) {
      rnfr=event.info[0];
      rnto=event.info[1];
   }

   switch( event.state ) {
   case QS_BEGIN:
      // Event begins
      if( event.info._length()<2 ) {
         // Nothing to rename
         msg="Not enough arguments for RENAME";
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rnfr,rnto,msg,INVALID_ARGUMENT_RC);
         return;
      }
      status=_ftpCommand(&event.fcp,false,"RNFR",rnfr);
      if( status ) {
         msg="Error sending RNFR.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rnfr,rnto,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_RNFR_WAITING_FOR_REPLY,0,&event.fcp,rnfr,rnto);
      return;
      break;
   case QS_RNFR_WAITING_FOR_REPLY:
      // Waiting for the RNFR response from ftp server
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,rnfr,rnto);
         return;
      }
      if( status ) {
         msg="Error with RNFR":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rnfr,rnto,msg,status);
         return;
      }
      // We are expecting something like:
      //
      // 350 File exists, ready for destination name
      status=_ftpCommand(&event.fcp,false,"RNTO",rnto);
      if( status ) {
         msg="Error sending RNTO.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rnfr,rnto,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_RNTO_WAITING_FOR_REPLY,0,&event.fcp,rnfr,rnto);
      return;   // Done
      break;
   case QS_RNTO_WAITING_FOR_REPLY:
      // Waiting for the RNTO response from ftp server
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,rnfr,rnto);
         return;
      }
      if( status ) {
         msg="Error with RNTO":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rnfr,rnto,msg,status);
         return;
      }
      // We are expecting something like:
      //
      // 250 RNTO command successful.
      return;
      break;
   case QS_ERROR:
      // An error occurred with RENAME
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

void _ftpQEHandler_RecvCmd(FtpQEvent *e_p)
{
   FtpQEvent event = *e_p;   // Make a copy
   FtpRecvCmd rcmd = (FtpRecvCmd)event.info[0];
   typeless status=0;
   _str response="";
   _str msg="";
   _str line="";
   _str rest="";
   int i=0;
   _str cmd="";
   _str cwd="";
   _str curr_cwd="";
   _str remote_path="";
   _str orig_cwd="";
   _str cmdline="";
   _str pwd="";
   _str temp_host;
   _str temp_port;
   _str info;

   switch( event.state ) {
   case QS_BEGIN:
      // Event begins
      if( rcmd.pasv ) {
         if( pos(':',event.fcp.remote_address) ) {
            // IPv6 must use EPSV.
            // Performing a passive transfer. Issue a "EPSV" command so the FTP
            // server will return an address and port we can read from. Client
            // (SE) initiates connection with FTP server.
            _ftpEnQ(event.event,QS_EPSV_BEGIN,0,&event.fcp,rcmd);
         } else {
            // IPv4 can use old PASV.
            // Performing a passive transfer. Issue a "PASV" command so the FTP
            // server will return an address and port we can read from. Client
            // (SE) initiates connection with FTP server.
            _ftpEnQ(event.event,QS_PASV_BEGIN,0,&event.fcp,rcmd);
         }
         return;
      } else {
         // Active transfer. Issue a "LISTENDATA" command to the SE proxy
         // to get an available address/port for the FTP server to transfer
         // data to.
         _ftpEnQ(event.event,QS_PROXY_LISTENDATA_BEGIN,0,&event.fcp,rcmd);
         return;
      }
      break;
   case QS_CMD_BEFORE_BEGIN:
      // Special case for RETRs. Issue a command before proceeding.
      // Example: OS/400 hosts issue a NAMEFMT command to set the
      // file system before RETRieving a file.
      if( !rcmd.pre_cmds._length() ) {
         // This should never happen
         _ftpEnQ(event.event,QS_BEGIN,0,&event.fcp,rcmd);
         return;
      }
      cmdline=rcmd.pre_cmds[0];
      rcmd.pre_cmds._deleteel(0);
      status=_ftpCommand(&event.fcp,false,cmdline);
      if( status ) {
         msg="Error sending command: ":+cmdline:+".  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_CMD_BEFORE_WAITING_FOR_REPLY,0,&event.fcp,rcmd);
      return;
      break;
   case QS_CMD_BEFORE_WAITING_FOR_REPLY:
      // Waiting for the command response from ftp server
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,rcmd);
         return;
      }
      if( status ) {
         msg="Error with command response.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
         return;
      }
      if( rcmd.pre_cmds._length() ) {
         // More pre commands to process
         _ftpEnQ(event.event,QS_CMD_BEFORE_BEGIN,0,&event.fcp,rcmd);
      } else {
         // Now we can start the receive
         _ftpEnQ(event.event,QS_BEGIN,0,&event.fcp,rcmd);
      }
      return;
      break;
   case QS_CWD_BEFORE_BEGIN:
      // Special case for RETRs. We must change to the destination
      // directory before RETRieving the file. VM is a host that requires
      // this.
      cmdline=rcmd.cmdargv[0];
      for( i=1;i<rcmd.cmdargv._length();++i ) {
         cmdline=cmdline:+" ":+rcmd.cmdargv[i];
      }
      parse cmdline with cmd remote_path .;
      if( upcase(cmd)=='RETR' ) {
         cwd=_ftpStripFilename(&event.fcp,remote_path,'NS');
         curr_cwd=event.fcp.remoteCwd;
         if( !_ftpFileEq(&event.fcp,cwd,curr_cwd) ) {
            // We need to keep track of the original remote working
            // directory so we can change back to it when we are done.
            rcmd.orig_cwd=curr_cwd;
            #if 0
            if( event.fcp.System==FTPSYST_MVS ) {
               // Make sure this is not an HFS file system
               if( substr(curr_cwd,1,1)!='/' &&
                   (substr(cwd,1,1)!="'" || last_char(cwd)!="'") ) {
                  // We have to make the directory absolute by enclosing with
                  // single-quotes. Otherwise it would be relative to the
                  // current PDS.
                  cwd=strip(cwd,'B',"'");
                  cwd="'":+cwd:+"'";
               }
            }
            #endif
            status=_ftpCommand(&event.fcp,false,"CWD",cwd);
            if( status ) {
               msg="Error sending CWD ":+cwd:+" command.  ":+_ftpGetMessage(status);
               _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
               return;
            }
            _ftpEnQ(event.event,QS_CWD_BEFORE_WAITING_FOR_REPLY,0,&event.fcp,rcmd);
            return;
         }
      }
      _ftpEnQ(event.event,QS_BEGIN,0,&event.fcp,rcmd);
      return;
      break;
   case QS_CWD_BEFORE_WAITING_FOR_REPLY:
      // Waiting for the CWD response from ftp server
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,rcmd);
         return;
      }
      if( status ) {
         msg="Error changing remote directory.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
         return;
      }
      status=_ftpCommand(&event.fcp,false,"PWD");
      if( status ) {
         msg="Error sending PWD command.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_PWD_BEFORE_WAITING_FOR_REPLY,0,&event.fcp,rcmd);
      return;
      break;
   case QS_PWD_BEFORE_WAITING_FOR_REPLY:
      // Waiting for the PWD response from ftp server
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,rcmd);
         return;
      }
      if( status ) {
         msg="Error getting remote current working directory.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
         return;
      }
      // We are expecting something like:
      //
      // 257 "/home/slick/www-slickedit" is cwd.
      //
      // Strip off the linebreak char(s)
      response=translate(response,"","\r\n");
      pwd="";
      int syst=event.fcp.system;
      if( syst==FTPSYST_MVS || syst==FTPSYST_VXWORKS ) {
         // Special check for PWD output like this:
         //
         // 257 HFS directory / is the working directory.
         //
         // or this:
         //
         // 257 Current directory is "/"
         //
         // where the working directory is not the first thing in the
         // string AND it might not be quoted.
         //
         // Parse off the result code
         parse response with . rest;
         rest=strip(rest);
         if( pos('^HFS directory ',rest,1,'r') ) {
            parse response with . 'HFS directory ' pwd .;
            pwd=strip(pwd,'B','"');   // Just in case
         } else if( pos('^Current directory is',rest,1,'ir') ) {
            // VxWorks
            parse response with . 'Current directory is' pwd .;
            pwd=strip(pwd,'B','"');
         }
      }
      if( pwd=="" ) {
         parse response with . pwd;
         pwd=strip(pwd);
         if( substr(pwd,1,1)=='"' ) {
            i=lastpos('"',pwd);
            if( i ) {
               // A directory enclosed by quotes could have spaces in it,
               // so take the whole quoted string.
               pwd=substr(pwd,1,i);
            } else {
               // Strip off trailing non-directory text
               parse pwd with '"' pwd .;
            }
         } else {
            // Strip off trailing non-directory text
            parse pwd with pwd .;
         }
         pwd=strip(pwd,'B','"');
         // Some MVS hosts put inner single-quotes on the working directory
         pwd=strip(pwd,'B',"'");
         if( pwd=="" ) {
            // This should never happen
            msg="Attempt to change working directory failed.\n\n":+
                "PWD returned:\n\n":+'""';
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,PATH_NOT_FOUND_RC);
            return;
         }
      }
      event.fcp.remoteCwd=pwd;
      // Now we can start the receive
      _ftpEnQ(event.event,QS_BEGIN,0,&event.fcp,rcmd);
      return;
      break;
   case QS_PASV_BEGIN:
      status=_ftpCommand(&event.fcp,false,"PASV");
      if( status ) {
         msg="Error sending PASV.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_PASV_WAITING_FOR_REPLY,0,&event.fcp,rcmd);
      return;
      break;
   case QS_PASV_WAITING_FOR_REPLY:
      // Waiting for the PASV response from ftp server
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,rcmd);
         return;
      }
      if( status ) {
         msg="Error obtaining PASV response.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
            return;
         }
      }
      // We are expecting something like:
      //
      // 227 Entering passive mode (192,168,0,1,16,51)
      i=pos('{#0\(:i\,:i\,:i\,:i\,:i\,:i\)}',response,1,'er');
      if( !i ) {
         msg="Could not determine address/port from PASV";
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,INVALID_ARGUMENT_RC);
         return;
      }
      typeless a1,a2,a3,a4,p1,p2;
      parse substr(response,pos('S0'),pos('0')) with '(' a1 ',' a2 ',' a3 ',' a4 ',' p1 ',' p2 ')';
      temp_host = a1'.'a2'.'a3'.'a4;
      temp_port = (_str)((p1<<8)+p2);
      rcmd.datahost=temp_host;
      rcmd.dataport=temp_port;
      _ftpEnQ(event.event,QS_PROXY_OPENDATA_BEGIN,0,&event.fcp,rcmd);
      return;
      break;
   case QS_EPSV_BEGIN:
      status = _ftpCommand(&event.fcp,false,"EPSV");
      if( status != 0 ) {
         msg = "Error sending EPSV.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_EPSV_WAITING_FOR_REPLY,0,&event.fcp,rcmd);
      return;
      break;
   case QS_EPSV_WAITING_FOR_REPLY:
      // Waiting for the EPSV response from ftp server
      status = _ftpQCheckResponse(&event,false,response,false);
      if( status == VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,rcmd);
         return;
      }
      if( status != 0 ) {
         msg="Error obtaining EPSV response.  ":+_ftpGetMessage(status);
         if( status == VSRC_FTP_BAD_RESPONSE ) {
            msg = msg:+"\n\n":+event.fcp.lastStatusLine;
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
            return;
         }
      }
      // We are expecting something like:
      //
      // 227 Entering Extended Passive Mode (|||6446|)
      i = pos('{#0\(\|\|\|:i\|\)}',response,1,'er');
      if( i == 0 ) {
         msg = "Could not determine address/port from EPSV";
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,INVALID_ARGUMENT_RC);
         return;
      }
      parse substr(response,pos('S0'),pos('0')) with '(|||' temp_port '|)';
      // Use the cached connection address for the remote FTP server
      rcmd.datahost = event.fcp.remote_address;
      rcmd.dataport = temp_port;
      _ftpEnQ(event.event,QS_PROXY_OPENDATA_BEGIN,0,&event.fcp,rcmd);
      return;
      break;
   case QS_PROXY_OPENDATA_BEGIN:
      status = _ftpVSProxyCommand(&event.fcp,"OPENDATA",rcmd.datahost,rcmd.dataport);
      if( status != 0 ) {
         msg = "Error sending OPENDATA to SlickEdit proxy.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_PROXY_OPENDATA_WAITING_FOR_REPLY,0,&event.fcp,rcmd);
      return;
      break;
   case QS_PROXY_OPENDATA_WAITING_FOR_REPLY:
      // Waiting for the OPENDATA response from SE proxy
      status=_ftpQCheckResponse(&event,true,response,true);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,rcmd);
         return;
      }
      if( status ) {
         msg="Error with OPENDATA response from SlickEdit proxy.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_TYPE_BEGIN,0,&event.fcp,rcmd);
      return;
      break;
   case QS_PROXY_LISTENDATA_BEGIN:
      status=_ftpVSProxyCommand(&event.fcp,"LISTENDATA");
      if( status ) {
         msg="Error sending LISTENDATA to SlickEdit proxy.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_PROXY_LISTENDATA_WAITING_FOR_REPLY,0,&event.fcp,rcmd);
      return;
      break;
   case QS_PROXY_LISTENDATA_WAITING_FOR_REPLY:
      // Waiting for the LISTENDATA response from SE proxy
      status=_ftpQCheckResponse(&event,true,response,true);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,rcmd);
         return;
      }
      if( status ) {
         msg="Error with LISTENDATA response from SlickEdit proxy.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
         return;
      }

      // Expecting something like:
      //
      // +ok Listening at [192.168.0.1]:1025 (4,1)
      i=pos('\[[~\[\]]#\]\::i',response,1,'er');
      if( !i ) {
         msg="Could not determine address/port from LISTENDATA response:\n\n":+
             response;
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,INVALID_ARGUMENT_RC);
         return;
      }
      parse substr(response,i) with '['temp_host']' ':' temp_port .;
      rcmd.datahost=temp_host;
      rcmd.dataport=temp_port;
      if( pos(':',rcmd.datahost) ) {
         // IPv6 addresses must use EPRT command
         _ftpEnQ(event.event,QS_EPRT_BEGIN,0,&event.fcp,rcmd);
      } else {
         // IPv4 addresses can use old PORT command
         _ftpEnQ(event.event,QS_PORT_BEGIN,0,&event.fcp,rcmd);
      }
      return;
      break;
   case QS_PORT_BEGIN:
      // Active transfer. Issue a "PORT" command so the FTP server knows
      // where to connect to on the client side (SE). Firewalls do not
      // like this method because the FTP server initiates the connection
      // to the client (SE).
      //
      // Now issue the "PORT" command with the host and port info we got
      // from LISTENDATA, so that the FTP server knows where to connect.
      temp_host=rcmd.datahost;
      temp_port=rcmd.dataport;
      parse temp_host with a1 '.' a2 '.' a3 '.' a4;
      p1= (int)((int)temp_port>>8) & 0x000000ff;
      p2= (int)temp_port & 0x000000ff;
      info=a1','a2','a3','a4','p1','p2;
      status=_ftpCommand(&event.fcp,false,"PORT",info);
      if( status ) {
         msg="Error sending PORT command.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_PORT_WAITING_FOR_REPLY,0,&event.fcp,rcmd);
      return;
      break;
   case QS_PORT_WAITING_FOR_REPLY:
      // Waiting for the PORT response from the ftp server
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,rcmd);
         return;
      }
      if( status ) {
         msg="Error with PORT response.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
         return;
      }

      // Expecting something like:
      //
      // 200 PORT command successful.
      _ftpEnQ(event.event,QS_TYPE_BEGIN,0,&event.fcp,rcmd);
      return;
      break;
   case QS_EPRT_BEGIN:
      {
         // Active transfer. Issue a "EPRT" command so the FTP server knows
         // where to connect to on the client side (SE). Firewalls do not
         // like this method because the FTP server initiates the connection
         // to the client (SE).
         //
         // Now issue the "EPRT" command with the host and port info we got
         // from LISTENDATA, so that the FTP server knows where to connect.
         temp_host = rcmd.datahost;
         temp_port = rcmd.dataport;
         info = "";
         if( pos(':',temp_host) > 0 ) {
            // IPv6 address
            info = "|2|"temp_host"|"temp_port"|";
         } else {
            // IPv4 address
            info = "|1|"temp_host"|"temp_port"|";
         }
         status = _ftpCommand(&event.fcp,false,"EPRT",info);
         if( status != 0 ) {
            msg="Error sending EPRT command.  ":+_ftpGetMessage(status);
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
            return;
         }
         _ftpEnQ(event.event,QS_EPRT_WAITING_FOR_REPLY,0,&event.fcp,rcmd);
         return;
      }
      break;
   case QS_EPRT_WAITING_FOR_REPLY:
      // Waiting for the EPRT response from the ftp server
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,rcmd);
         return;
      }
      if( status ) {
         msg="Error with EPRT response.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
         return;
      }

      // Expecting something like:
      //
      // 200 EPRT command successful.
      _ftpEnQ(event.event,QS_TYPE_BEGIN,0,&event.fcp,rcmd);
      return;
      break;
   case QS_TYPE_BEGIN:
      status=_ftpType(&event.fcp,rcmd.xfer_type);
      if( status ) {
         msg="Error sending TYPE.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_TYPE_WAITING_FOR_REPLY,0,&event.fcp,rcmd);
      return;
      break;
   case QS_TYPE_WAITING_FOR_REPLY:
      // Waiting for the TYPE response from ftp server
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,rcmd);
         return;
      }
      if( status ) {
         msg="Error with TYPE response.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
         return;
      }
      // We are expecting something like:
      //
      // 200 Type okay.
      _ftpEnQ(event.event,QS_CMD_BEGIN,0,&event.fcp,rcmd);
      return;
      break;
   case QS_CMD_BEGIN:
      int hosttype=event.fcp.system;
      if( hosttype==FTPSYST_VM || hosttype==FTPSYST_VMESA ) {
         cmdline=rcmd.cmdargv[0];
         for( i=1;i<rcmd.cmdargv._length();++i ) {
            cmdline=cmdline:+" ":+rcmd.cmdargv[i];
         }
         parse cmdline with cmd remote_path rest;
         if( upcase(cmd)=='RETR' ) {
            // Special case for RETRs. We must reconstruct the remote path
            // so that we are only RETRieving the filename (no path). This is
            // because VM has no concept of downloading from a CMS minidisk
            // other than the one that is current. The path that we are
            // stripping off was for our benefit alone so that we would know
            // which minidisk to receive from.
            _str filename=_ftpStripFilename(&event.fcp,remote_path,'P');
            status=_ftpCommand(&event.fcp,false,cmd,filename,rest);
         } else {
            status=_ftpCommand(&event.fcp,false,rcmd.cmdargv);
         }
      } else {
         status=_ftpCommand(&event.fcp,false,rcmd.cmdargv);
      }
      if( status ) {
         msg="Error sending ":+rcmd.cmdargv[0]:+" command.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_CMD_WAITING_FOR_REPLY,0,&event.fcp,rcmd);
      return;
      break;
   case QS_CMD_WAITING_FOR_REPLY:
      // Waiting for the command response from ftp server
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,rcmd);
         return;
      }
      if( status && event.fcp.ignoreListErrors && upcase(rcmd.cmdargv[0])=="LIST" ) {
         // We are instructed to ignore all errors from the LIST command.
         // This is usually because the host is MVS and is giving an error
         // when the directory has no contents, instead of just returning
         // a 0 byte listing.
         //
         // Create a 0 byte file to be processed.
         int temp_view_id=0;
         int orig_view_id=_create_temp_view(temp_view_id);
         if( orig_view_id!="" ) {
            if( !_on_line0() ) _delete_line();
            _save_file('+o ':+maybe_quote_filename(rcmd.dest));
            _delete_temp_view(temp_view_id);
            p_window_id=orig_view_id;
            // Now pick up after the end of a transfer
            if( rcmd.post_cmds._length()>0 ) {
               _ftpEnQ(event.event,QS_CMD_AFTER_BEGIN,0,&event.fcp,rcmd);
            } else if( rcmd.orig_cwd._varformat()!=VF_EMPTY && rcmd.orig_cwd!="" ) {
               _ftpEnQ(event.event,QS_CWD_AFTER_BEGIN,0,&event.fcp,rcmd);
            } else {
               _ftpEnQ(event.event,QS_END,0,&event.fcp,rcmd);
            }
            return;
         }
      }
      if( status ) {
         msg="Error with ":+rcmd.cmdargv[0]:+" response.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
         return;
      }
      int size=0;
      i=pos('\(:i bytes',response,1,'er');
      if( i ) {
         typeless temp="";
         parse substr(response,i) with '(' temp 'bytes' ')';
         if( isinteger(temp) && temp>=0 ) {
            size= (int)temp;
         }
      }
      rcmd.size= (int)size;
      _ftpEnQ(event.event,QS_PROXY_RECVDATA_BEGIN,0,&event.fcp,rcmd);
      return;
      break;
   case QS_PROXY_RECVDATA_BEGIN:
      _str options="";
      if( rcmd.xfer_type==FTPXFER_ASCII ) {
         // Translate newlines into the local newline format
         options=options:+" +L";

         // For non-binary transfer on S/390, tell vsproxy to convert
         // the data to EBCDIC.
         if (machine() == "S390") options=options:+" +E";
      }
      status=_ftpVSProxyCommand(&event.fcp,"RECVDATA",options,maybe_quote_filename(rcmd.dest));
      if( status ) {
         msg="Error sending RECVDATA to SlickEdit proxy.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_PROXY_RECVDATA_WAITING_FOR_REPLY,0,&event.fcp,rcmd);
      return;
      break;
   case QS_PROXY_RECVDATA_WAITING_FOR_REPLY:
      // Waiting for the RECVDATA response from SE proxy
      status=_ftpQCheckResponse(&event,true,response,true);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,rcmd);
         return;
      }
      if( status ) {
         msg="Error with RECVDATA response from SlickEdit proxy.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
         return;
      }

      // Expecting something like:
      //
      // +ok Receiving to file "c:\temp\1110001.4"
      _ftpEnQ(event.event,QS_PROXY_DATASTAT_BEGIN,0,&event.fcp,rcmd);
      return;
      break;
   case QS_PROXY_DATASTAT_BEGIN:
      status=_ftpVSProxyCommand(&event.fcp,"DATASTAT");
      if( status ) {
         msg="Error sending DATASTAT to SlickEdit proxy.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_PROXY_DATASTAT_WAITING_FOR_REPLY,0,&event.fcp,rcmd);
      return;
      break;
   case QS_PROXY_DATASTAT_WAITING_FOR_REPLY:
      // Waiting for the DATASTAT response from SE proxy
      status=_ftpQCheckResponse(&event,true,response,true);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,rcmd);
         return;
      }
      if( status ) {
         msg="Error with DATASTAT response from SlickEdit proxy.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
         return;
      }
      // Expecting something like:
      //
      // +ok 1024
      // OR
      // +ok Done
      i=lastpos('+ok',response);
      if( !i ) {
         msg="Error with DATASTAT response from SlickEdit proxy:\n\n":+
             response;
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,INVALID_ARGUMENT_RC);
         return;
      }
      parse substr(response,i) with '+ok' status .;
      status=strip(status);
      status=strip(status,'T',"\n");
      status=strip(status,'T',"\r");
      if( lowcase(status)=='done' ) {
         // Transfer complete
         if( rcmd.progressCb ) {
            line=rcmd.cmdargv[0];
            for( i=1;i<rcmd.cmdargv._length();++i ) {
               line=line:+" ":+rcmd.cmdargv[i];
            }
            (*rcmd.progressCb)(line,rcmd.size,rcmd.size);
         }
         _ftpEnQ(event.event,QS_PROXY_CLOSEDATA_BEGIN,0,&event.fcp,rcmd);
         return;
      } else if( isinteger(status) ) {
         // Transfer still in progress
         if( rcmd.progressCb ) {
            line=rcmd.cmdargv[0];
            for( i=1;i<rcmd.cmdargv._length();++i ) {
               line=line:+" ":+rcmd.cmdargv[i];
            }
            (*rcmd.progressCb)(line,(int)status,rcmd.size);
         }
         _ftpEnQ(event.event,QS_PROXY_DATASTAT_BEGIN,0,&event.fcp,rcmd);
         return;
      } else {
         // No idea what this is
         //_message_box("status=["status"]\n\nresponse="response);
         msg="Error with DATASTAT response from SlickEdit proxy:\n\n":+
             response;
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,INVALID_ARGUMENT_RC);
         return;
      }
      break;
   case QS_PROXY_CLOSEDATA_BEGIN:
      status=_ftpVSProxyCommand(&event.fcp,"CLOSEDATA");
      if( status ) {
         msg="Error sending CLOSEDATA to SlickEdit proxy.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_PROXY_CLOSEDATA_WAITING_FOR_REPLY,0,&event.fcp,rcmd);
      return;
      break;
   case QS_PROXY_CLOSEDATA_WAITING_FOR_REPLY:
      // Waiting for the CLOSEDATA response from SE proxy
      status=_ftpQCheckResponse(&event,true,response,true);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,rcmd);
         return;
      }
      if( status ) {
         msg="Error with CLOSEDATA response from SlickEdit proxy.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
         return;
      }

      // Expecting something like:
      //
      // +ok Received 16384 bytes to file "c:\temp\1110001.4"
      _ftpEnQ(event.event,QS_END_TRANSFER_WAITING_FOR_REPLY,0,&event.fcp,rcmd);
      return;
      break;
   case QS_END_TRANSFER_WAITING_FOR_REPLY:
      // Waiting for the response from ftp server that tells us the transfer
      // is complete.
      boolean prelim_reply=false;
      line=event.fcp.lastStatusLine;
      if( line!="" ) {
         _str code=substr(line,1,3);
         if( isinteger(code) && substr(code,1,1)==1 ) {
            prelim_reply=true;
         }

      }
      if( prelim_reply ) {
         // Still waiting for a reply from the ftp server
         status=_ftpQCheckResponse(&event,false,response,false);
         if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
            _ftpReQ(event.event,event.state,event.start,&event.fcp,rcmd);
            return;
         }
         if( status ) {
            msg="Error with ":+rcmd.cmdargv[0]:+" response.  ":+_ftpGetMessage(status);
            if( status==VSRC_FTP_BAD_RESPONSE ) {
               msg=msg:+"\n\n":+event.fcp.lastStatusLine;
            }
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
            return;
         }
      }
      if( rcmd.post_cmds._length()>0 ) {
         _ftpEnQ(event.event,QS_CMD_AFTER_BEGIN,0,&event.fcp,rcmd);
      } else if( rcmd.orig_cwd._varformat()!=VF_EMPTY && rcmd.orig_cwd!="" ) {
         _ftpEnQ(event.event,QS_CWD_AFTER_BEGIN,0,&event.fcp,rcmd);
      } else {
         _ftpEnQ(event.event,QS_END,0,&event.fcp,rcmd);
      }
      return;
      break;
   case QS_CMD_AFTER_BEGIN:
      // Special case for RETRs. Issue a command after receiving.
      // Example: OS/400 hosts issue a NAMEFMT command to set the
      // file system after RETRieving a file.
      if( rcmd.post_cmds._length()>0 ) {
         cmdline=rcmd.post_cmds[0];
         rcmd.post_cmds._deleteel(0);
         status=_ftpCommand(&event.fcp,false,cmdline);
         if( status ) {
            msg="Error sending command: ":+cmdline:+".  ":+_ftpGetMessage(status);
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
            return;
         }
         _ftpEnQ(event.event,QS_CMD_AFTER_WAITING_FOR_REPLY,0,&event.fcp,rcmd);
         return;
      }
      _ftpEnQ(event.event,QS_END,0,&event.fcp,rcmd);
      return;
      break;
   case QS_CMD_AFTER_WAITING_FOR_REPLY:
      // Waiting for the command response from ftp server
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,rcmd);
         return;
      }
      if( status ) {
         msg="Error with command response.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
         return;
      }
      if( rcmd.post_cmds._length() ) {
         // More post commands to process
         _ftpEnQ(event.event,QS_CMD_AFTER_BEGIN,0,&event.fcp,rcmd);
      } else {
         // Now we can end the receive
         _ftpEnQ(event.event,QS_END,0,&event.fcp,rcmd);
      }
      return;
      break;
   case QS_CWD_AFTER_BEGIN:
      // Special case for RETRs. We must change back to the original
      // remote working directory after RETRieving the file. VM is a host
      // that requires this.
      if( rcmd.orig_cwd._varformat()!=VF_EMPTY && rcmd.orig_cwd!="" ) {
         cwd=event.fcp.remoteCwd;
         orig_cwd=rcmd.orig_cwd;
         if( !_ftpFileEq(&event.fcp,cwd,orig_cwd) ) {
            #if 0
            if( event.fcp.System==FTPSYST_MVS ) {
               // Make sure this is not an HFS file system
               if( substr(cwd,1,1)!='/' &&
                   (substr(orig_cwd,1,1)!="'" || last_char(orig_cwd)!="'") ) {
                  // We have to make the directory absolute by enclosing with
                  // single-quotes. Otherwise it would be relative to the
                  // current PDS.
                  orig_cwd=strip(orig_cwd,'B',"'");
                  orig_cwd="'":+orig_cwd:+"'";
               }
            }
            #endif
            status=_ftpCommand(&event.fcp,false,"CWD",orig_cwd);
            if( status ) {
               msg="Error sending CWD ":+orig_cwd:+" command.  ":+_ftpGetMessage(status);
               _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
               return;
            }
            _ftpEnQ(event.event,QS_CWD_AFTER_WAITING_FOR_REPLY,0,&event.fcp,rcmd);
            return;
         }
      }
      _ftpEnQ(event.event,QS_END,0,&event.fcp,rcmd);
      return;
      break;
   case QS_CWD_AFTER_WAITING_FOR_REPLY:
      // Waiting for the CWD response from ftp server
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,rcmd);
         return;
      }
      if( status ) {
         msg="Error changing remote directory.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
         return;
      }
      status=_ftpCommand(&event.fcp,false,"PWD");
      if( status ) {
         msg="Error sending PWD command.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_PWD_AFTER_WAITING_FOR_REPLY,0,&event.fcp,rcmd);
      return;
      break;
   case QS_PWD_AFTER_WAITING_FOR_REPLY:
      // Waiting for the PWD response from ftp server
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,rcmd);
         return;
      }
      if( status ) {
         msg="Error getting remote current working directory.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
         return;
      }
      // We are expecting something like:
      //
      // 257 "/home/slick/www-slickedit" is cwd.
      //
      // Strip off the linebreak char(s)
      response=translate(response,"","\r\n");
      pwd="";
      syst=event.fcp.system;
      if( syst==FTPSYST_MVS || syst==FTPSYST_VXWORKS ) {
         // Special check for PWD output like this:
         //
         // 257 HFS directory / is the working directory.
         //
         // or this:
         //
         // 257 Current directory is "/"
         //
         // where the working directory is not the first thing in the
         // string AND it might not be quoted.
         //
         // Parse off the result code
         parse response with . rest;
         rest=strip(rest);
         if( pos('^HFS directory ',rest,1,'r') ) {
            parse response with . 'HFS directory ' pwd .;
            pwd=strip(pwd,'B','"');   // Just in case
         } else if( pos('^Current directory is',rest,1,'ir') ) {
            // VxWorks
            parse response with . 'Current directory is' pwd .;
            pwd=strip(pwd,'B','"');
         }
      }
      if( pwd=="" ) {
         parse response with . pwd;
         pwd=strip(pwd);
         if( substr(pwd,1,1)=='"' ) {
            i=lastpos('"',pwd);
            if( i ) {
               // A directory enclosed by quotes could have spaces in it,
               // so take the whole quoted string.
               pwd=substr(pwd,1,i);
            } else {
               // Strip off trailing non-directory text
               parse pwd with '"' pwd .;
            }
         } else {
            // Strip off trailing non-directory text
            parse pwd with pwd .;
         }
         pwd=strip(pwd,'B','"');
         // Some MVS hosts put inner single-quotes on the working directory
         pwd=strip(pwd,'B',"'");
         if( pwd=="" ) {
            // This should never happen
            msg="Attempt to change working directory failed.\n\n":+
                "PWD returned:\n\n":+'""';
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,PATH_NOT_FOUND_RC);
            return;
         }
      }
      event.fcp.remoteCwd=pwd;
      // Now we can start the send
      _ftpEnQ(event.event,QS_END,0,&event.fcp,rcmd);
      return;
      break;
   case QS_ERROR:
      // An error occurred with receving data
      _ftpVSProxyCommand(&event.fcp,"ABORTDATA");
      if( upcase(rcmd.cmdargv[0])=="LIST" ) {
         // Just in case (this will usually fail with FILE_NOT_FOUND_RC)
         delete_file(rcmd.dest);
      }
      _ftpQEventDisplayError(event);
      return;
      break;
   case QS_ABORT:
      // Event aborted
      //
      // We might have gotten a message from the SE proxy
      // already, so check.
      event.fcp.reply="";
      event.start=0;
      status=_ftpQCheckResponse(&event,true,response,true);
      //_message_box("1 status="status"  response="response);
      if( status ) {
         // Don't care
      }

      status=_ftpCommand(&event.fcp,false,"ABOR");

      // The SE proxy gives no response to ABORTDATA
      _ftpVSProxyCommand(&event.fcp,"ABORTDATA");

      //_message_box("ABOR sent");
      if( status ) {
         msg="Error sending ABOR.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_ABORT_WAITING_FOR_REPLY,0,&event.fcp,rcmd);
      return;
      break;
   case QS_ABORT_WAITING_FOR_REPLY:
      // Waiting for the response from ftp server that tells us the status
      // of the abort.
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,rcmd);
         return;
      }
      if( status ) {
         msg="Error with ABOR response.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,rcmd,msg,status);
         return;
      }
      if( upcase(rcmd.cmdargv[0])=="LIST" ) {
         // Just in case (this will usually fail with FILE_NOT_FOUND_RC)
         delete_file(rcmd.dest);
      }
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

void _ftpQEHandler_SendCmd(FtpQEvent *e_p)
{
   FtpQEvent event = *e_p;   // Make a copy
   FtpSendCmd scmd = (FtpSendCmd)event.info[0];
   typeless status=0;
   _str response="";
   _str cmdline="";
   _str msg="";
   _str cmd="";
   _str remote_path="";
   _str pwd="";
   _str cwd="";
   _str curr_cwd="";
   _str orig_cwd="";
   _str rest="";
   _str line="";
   _str filename="";
   typeless temp_host="";
   typeless temp_port="";
   int i=0;

   switch( event.state ) {
   case QS_BEGIN:
      // Event begins
      if( scmd.pasv ) {
         if( pos(':',event.fcp.remote_address) ) {
            // IPv6 must use EPSV.
            // Performing a passive transfer. Issue a "EPSV" command so the FTP
            // server will return an address and port we can read from. Client
            // (SE) initiates connection with FTP server.
            _ftpEnQ(event.event,QS_EPSV_BEGIN,0,&event.fcp,scmd);
         } else {
            // IPv4 can use old PASV.
            // Performing a passive transfer. Issue a "PASV" command so the FTP
            // server will return an address and port we can read from. Client
            // (SE) initiates connection with FTP server.
            _ftpEnQ(event.event,QS_PASV_BEGIN,0,&event.fcp,scmd);
         }
         return;
      } else {
         // Active transfer. Issue a "LISTENDATA" command to the SE proxy
         // to get an available address/port for the FTP server to receive
         // data from
         _ftpEnQ(event.event,QS_PROXY_LISTENDATA_BEGIN,0,&event.fcp,scmd);
         return;
      }
      break;
   case QS_CMD_BEFORE_BEGIN:
      // Special case for STORs. Issue a command before proceeding.
      // Example: OS/400 hosts issue a NAMEFMT command to set the
      // file system before STORing a file.
      if( !scmd.pre_cmds._length() ) {
         // This should never happen
         _ftpEnQ(event.event,QS_BEGIN,0,&event.fcp,scmd);
         return;
      }
      cmdline=scmd.pre_cmds[0];
      scmd.pre_cmds._deleteel(0);
      status=_ftpCommand(&event.fcp,false,cmdline);
      if( status ) {
         msg="Error sending command: ":+cmdline:+".  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_CMD_BEFORE_WAITING_FOR_REPLY,0,&event.fcp,scmd);
      return;
      break;
   case QS_CMD_BEFORE_WAITING_FOR_REPLY:
      // Waiting for the command response from ftp server
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,scmd);
         return;
      }
      if( status ) {
         msg="Error with command response.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
         return;
      }
      if( scmd.pre_cmds._length() ) {
         // More pre commands to process
         _ftpEnQ(event.event,QS_CMD_BEFORE_BEGIN,0,&event.fcp,scmd);
      } else {
         // Now we can start the send
         _ftpEnQ(event.event,QS_BEGIN,0,&event.fcp,scmd);
      }
      return;
      break;
   case QS_CWD_BEFORE_BEGIN:
      // Special case for STORs. We must change to the destination
      // directory before STORing the file. VM is a host that requires
      // this.
      cmdline=scmd.cmdargv[0];
      for( i=1;i<scmd.cmdargv._length();++i ) {
         cmdline=cmdline:+" ":+scmd.cmdargv[i];
      }
      parse cmdline with cmd remote_path .;
      if( upcase(cmd)=='STOR' ) {
         cwd=_ftpStripFilename(&event.fcp,remote_path,'NS');
         curr_cwd=event.fcp.remoteCwd;
         if( !_ftpFileEq(&event.fcp,cwd,curr_cwd) ) {
            // We need to keep track of the original remote working
            // directory so we can change back to it when we are done.
            scmd.orig_cwd=curr_cwd;
            #if 0
            if( event.fcp.System==FTPSYST_MVS ) {
               // Make sure this is not an HFS file system
               if( substr(curr_cwd,1,1)!='/' &&
                   (substr(cwd,1,1)!="'" || last_char(cwd)!="'") ) {
                  // We have to make the directory absolute by enclosing with
                  // single-quotes. Otherwise it would be relative to the
                  // current PDS.
                  cwd=strip(cwd,'B',"'");
                  cwd="'":+cwd:+"'";
               }
            }
            #endif
            status=_ftpCommand(&event.fcp,false,"CWD",cwd);
            if( status ) {
               msg="Error sending CWD ":+cwd:+" command.  ":+_ftpGetMessage(status);
               _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
               return;
            }
            _ftpEnQ(event.event,QS_CWD_BEFORE_WAITING_FOR_REPLY,0,&event.fcp,scmd);
            return;
         }
      }
      _ftpEnQ(event.event,QS_BEGIN,0,&event.fcp,scmd);
      return;
      break;
   case QS_CWD_BEFORE_WAITING_FOR_REPLY:
      // Waiting for the CWD response from ftp server
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,scmd);
         return;
      }
      if( status ) {
         msg="Error changing remote directory.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
         return;
      }
      status=_ftpCommand(&event.fcp,false,"PWD");
      if( status ) {
         msg="Error sending PWD command.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_PWD_BEFORE_WAITING_FOR_REPLY,0,&event.fcp,scmd);
      return;
      break;
   case QS_PWD_BEFORE_WAITING_FOR_REPLY:
      // Waiting for the PWD response from ftp server
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,scmd);
         return;
      }
      if( status ) {
         msg="Error getting remote current working directory.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
         return;
      }
      // We are expecting something like:
      //
      // 257 "/home/slick/www-slickedit" is cwd.
      //
      // Strip off the linebreak char(s)
      response=translate(response,"","\r\n");
      pwd="";
      int syst=event.fcp.system;
      if( syst==FTPSYST_MVS || syst==FTPSYST_VXWORKS ) {
         // Special check for PWD output like this:
         //
         // 257 HFS directory / is the working directory.
         //
         // or this:
         //
         // 257 Current directory is "/"
         //
         // where the working directory is not the first thing in the
         // string AND it might not be quoted.
         //
         // Parse off the result code
         parse response with . rest;
         rest=strip(rest);
         if( pos('^HFS directory ',rest,1,'r') ) {
            parse response with . 'HFS directory ' pwd .;
            pwd=strip(pwd,'B','"');   // Just in case
         } else if( pos('^Current directory is',rest,1,'ir') ) {
            // VxWorks
            parse response with . 'Current directory is' pwd .;
            pwd=strip(pwd,'B','"');
         }
      }
      if( pwd=="" ) {
         parse response with . pwd;
         pwd=strip(pwd);
         if( substr(pwd,1,1)=='"' ) {
            i=lastpos('"',pwd);
            if( i ) {
               // A directory enclosed by quotes could have spaces in it,
               // so take the whole quoted string.
               pwd=substr(pwd,1,i);
            } else {
               // Strip off trailing non-directory text
               parse pwd with '"' pwd .;
            }
         } else {
            // Strip off trailing non-directory text
            parse pwd with pwd .;
         }
         pwd=strip(pwd,'B','"');
         // Some MVS hosts put inner single-quotes on the working directory
         pwd=strip(pwd,'B',"'");
         if( pwd=="" ) {
            // This should never happen
            msg="Attempt to change working directory failed.\n\n":+
                "PWD returned:\n\n":+'""';
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,VSRC_FTP_CANNOT_STAT);
            return;
         }
      }
      event.fcp.remoteCwd=pwd;
      // Now we can start the send
      _ftpEnQ(event.event,QS_BEGIN,0,&event.fcp,scmd);
      return;
      break;
   case QS_PASV_BEGIN:
      status=_ftpCommand(&event.fcp,false,"PASV");
      if( status ) {
         msg="Error sending PASV.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_PASV_WAITING_FOR_REPLY,0,&event.fcp,scmd);
      return;
      break;
   case QS_PASV_WAITING_FOR_REPLY:
      // Waiting for the PASV response from ftp server
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,scmd);
         return;
      }
      if( status ) {
         msg="Error obtaining PASV response.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
            return;
         }
      }
      // We are expecting something like:
      //
      // 227 Entering passive mode (192,168,0,1,16,51)
      i=pos('{#0\(:i\,:i\,:i\,:i\,:i\,:i\)}',response,1,'er');
      if( !i ) {
         msg="Could not determine address/port from PASV";
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,INVALID_ARGUMENT_RC);
         return;
      }
      typeless a1, a2, a3, a4, p1, p2;
      parse substr(response,pos('S0'),pos('0')) with '(' a1 ',' a2 ',' a3 ',' a4 ',' p1 ',' p2 ')';
      temp_host=a1'.'a2'.'a3'.'a4;
      temp_port= (p1<<8)+p2;
      scmd.datahost=temp_host;
      scmd.dataport=temp_port;
      _ftpEnQ(event.event,QS_PROXY_OPENDATA_BEGIN,0,&event.fcp,scmd);
      return;
      break;
   case QS_EPSV_BEGIN:
      status = _ftpCommand(&event.fcp,false,"EPSV");
      if( status != 0 ) {
         msg = "Error sending EPSV.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_EPSV_WAITING_FOR_REPLY,0,&event.fcp,scmd);
      return;
      break;
   case QS_EPSV_WAITING_FOR_REPLY:
      // Waiting for the EPSV response from ftp server
      status = _ftpQCheckResponse(&event,false,response,false);
      if( status == VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,scmd);
         return;
      }
      if( status != 0 ) {
         msg="Error obtaining EPSV response.  ":+_ftpGetMessage(status);
         if( status == VSRC_FTP_BAD_RESPONSE ) {
            msg = msg:+"\n\n":+event.fcp.lastStatusLine;
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
            return;
         }
      }
      // We are expecting something like:
      //
      // 227 Entering Extended Passive Mode (|||6446|)
      i = pos('{#0\(\|\|\|:i\|\)}',response,1,'er');
      if( i == 0 ) {
         msg = "Could not determine address/port from EPSV";
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,INVALID_ARGUMENT_RC);
         return;
      }
      parse substr(response,pos('S0'),pos('0')) with '(|||' temp_port '|)';
      // Use the cached connection address for the remote FTP server
      scmd.datahost = event.fcp.remote_address;
      scmd.dataport = temp_port;
      _ftpEnQ(event.event,QS_PROXY_OPENDATA_BEGIN,0,&event.fcp,scmd);
      return;
      break;
   case QS_PROXY_OPENDATA_BEGIN:
      status=_ftpVSProxyCommand(&event.fcp,"OPENDATA",scmd.datahost,scmd.dataport);
      if( status ) {
         msg="Error sending OPENDATA to SlickEdit proxy.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_PROXY_OPENDATA_WAITING_FOR_REPLY,0,&event.fcp,scmd);
      return;
      break;
   case QS_PROXY_OPENDATA_WAITING_FOR_REPLY:
      // Waiting for the OPENDATA response from SE proxy
      status=_ftpQCheckResponse(&event,true,response,true);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,scmd);
         return;
      }
      if( status ) {
         msg="Error with OPENDATA response from SlickEdit proxy.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_TYPE_BEGIN,0,&event.fcp,scmd);
      return;
      break;
   case QS_PROXY_LISTENDATA_BEGIN:
      //say('event.fcp.vsproxy_sock='event.fcp.vsproxy_sock);
      status=_ftpVSProxyCommand(&event.fcp,"LISTENDATA");
      if( status ) {
         msg="Error sending LISTENDATA to SlickEdit proxy.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_PROXY_LISTENDATA_WAITING_FOR_REPLY,0,&event.fcp,scmd);
      return;
      break;
   case QS_PROXY_LISTENDATA_WAITING_FOR_REPLY:
      // Waiting for the LISTENDATA response from SE proxy
      status=_ftpQCheckResponse(&event,true,response,true);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,scmd);
         return;
      }
      if( status ) {
         msg="Error with LISTENDATA response from SlickEdit proxy.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
         return;
      }

      // Expecting something like:
      //
      // +ok Listening at [192.168.0.1]:1025 (4,1)
      i=pos('\[[~\[\]]#\]\::i',response,1,'er');
      if( !i ) {
         msg="Could not determine address/port from LISTENDATA response:\n\n":+
             response;
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,INVALID_ARGUMENT_RC);
         return;
      }
      parse substr(response,i) with '['temp_host']' ':' temp_port .;
      scmd.datahost=temp_host;
      scmd.dataport=temp_port;
      if( pos(':',scmd.datahost) ) {
         // IPv6 addresses must use EPRT command
         _ftpEnQ(event.event,QS_EPRT_BEGIN,0,&event.fcp,scmd);
      } else {
         // IPv4 addresses can use old PORT command
         _ftpEnQ(event.event,QS_PORT_BEGIN,0,&event.fcp,scmd);
      }
      return;
      break;
   case QS_PORT_BEGIN:
      // Active transfer. Issue a "PORT" command so the FTP server knows
      // where to connect to on the client side (SE). Firewalls do not
      // like this method because the FTP server initiates the connection
      // to the client (SE).
      //
      // Now issue the "PORT" command with the host and port info we got
      // from LISTENDATA, so that the FTP server knows where to connect.
      temp_host=scmd.datahost;
      temp_port=scmd.dataport;
      parse temp_host with a1 '.' a2 '.' a3 '.' a4;
      p1= (int)(temp_port>>8) & 0x000000ff;
      p2= temp_port & 0x000000ff;
      _str info=a1','a2','a3','a4','p1','p2;
      status=_ftpCommand(&event.fcp,false,"PORT",info);
      if( status ) {
         msg="Error sending PORT command.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_PORT_WAITING_FOR_REPLY,0,&event.fcp,scmd);
      return;
      break;
   case QS_PORT_WAITING_FOR_REPLY:
      // Waiting for the PORT response from the ftp server
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,scmd);
         return;
      }
      if( status ) {
         msg="Error with PORT response.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
         return;
      }

      // Expecting something like:
      //
      // 200 PORT command successful.
      _ftpEnQ(event.event,QS_TYPE_BEGIN,0,&event.fcp,scmd);
      return;
      break;
   case QS_EPRT_BEGIN:
      {
         // Active transfer. Issue a "EPRT" command so the FTP server knows
         // where to connect to on the client side (SE). Firewalls do not
         // like this method because the FTP server initiates the connection
         // to the client (SE).
         //
         // Now issue the "EPRT" command with the host and port info we got
         // from LISTENDATA, so that the FTP server knows where to connect.
         temp_host = scmd.datahost;
         temp_port = scmd.dataport;
         info = "";
         if( pos(':',temp_host) > 0 ) {
            // IPv6 address
            info = "|2|"temp_host"|"temp_port"|";
         } else {
            // IPv4 address
            info = "|1|"temp_host"|"temp_port"|";
         }
         status = _ftpCommand(&event.fcp,false,"EPRT",info);
         if( status != 0 ) {
            msg="Error sending EPRT command.  ":+_ftpGetMessage(status);
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
            return;
         }
         _ftpEnQ(event.event,QS_EPRT_WAITING_FOR_REPLY,0,&event.fcp,scmd);
         return;
      }
      break;
   case QS_EPRT_WAITING_FOR_REPLY:
      // Waiting for the EPRT response from the ftp server
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,scmd);
         return;
      }
      if( status ) {
         msg="Error with EPRT response.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
         return;
      }

      // Expecting something like:
      //
      // 200 EPRT command successful.
      _ftpEnQ(event.event,QS_TYPE_BEGIN,0,&event.fcp,scmd);
      return;
      break;
   case QS_TYPE_BEGIN:
      status=_ftpType(&event.fcp,scmd.xfer_type);
      if( status ) {
         msg="Error sending TYPE.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_TYPE_WAITING_FOR_REPLY,0,&event.fcp,scmd);
      return;
      break;
   case QS_TYPE_WAITING_FOR_REPLY:
      // Waiting for the TYPE response from ftp server
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,scmd);
         return;
      }
      if( status ) {
         msg="Error with TYPE response.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
         return;
      }
      // We are expecting something like:
      //
      // 200 Type okay.
      _ftpEnQ(event.event,QS_CMD_BEGIN,0,&event.fcp,scmd);
      return;
      break;
   case QS_CMD_BEGIN:
      int hosttype=event.fcp.system;
      if( hosttype==FTPSYST_VM || hosttype==FTPSYST_VMESA ) {
         cmdline=scmd.cmdargv[0];
         for( i=1;i<scmd.cmdargv._length();++i ) {
            cmdline=cmdline:+" ":+scmd.cmdargv[i];
         }
         parse cmdline with cmd remote_path rest;
         if( upcase(cmd)=='STOR' ) {
            // Special case for STORs. We must reconstruct the remote path
            // so that we are only STORing the filename (no path). This is
            // because VM has no concept of uploading to a CMS minidisk
            // other than the one that is current. The path that we are
            // stripping off was for our benefit alone so that we would know
            // which minidisk to save to.
            filename=_ftpStripFilename(&event.fcp,remote_path,'P');
            status=_ftpCommand(&event.fcp,false,cmd,filename,rest);
         } else {
            status=_ftpCommand(&event.fcp,false,scmd.cmdargv);
         }
      } else {
         status=_ftpCommand(&event.fcp,false,scmd.cmdargv);
      }
      if( status ) {
         msg="Error sending ":+scmd.cmdargv[0]:+" command.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_CMD_WAITING_FOR_REPLY,0,&event.fcp,scmd);
      return;
      break;
   case QS_CMD_WAITING_FOR_REPLY:
      // Waiting for the command response from ftp server
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,scmd);
         return;
      }
      if( status ) {
         msg="Error with ":+scmd.cmdargv[0]:+" response.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_PROXY_SENDDATA_BEGIN,0,&event.fcp,scmd);
      return;
      break;
   case QS_PROXY_SENDDATA_BEGIN:
      _str options="";
      if( scmd.xfer_type==FTPXFER_ASCII ) {
         // Translate newlines into the NVT newline format (\r\n) before
         // sending. This allows the ftp server to correctly translate
         // newlines into its own local newline format.
         options=options:+" +D";

         // For non-binary transfer on S/390, tell vsproxy to convert
         // the data to EBCDIC.
         if (machine() == "S390") options=options:+" +E";
      }
      status=_ftpVSProxyCommand(&event.fcp,"SENDDATA",options,maybe_quote_filename(scmd.src));
      if( status ) {
         msg="Error sending SENDDATA to SlickEdit proxy.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_PROXY_SENDDATA_WAITING_FOR_REPLY,0,&event.fcp,scmd);
      return;
      break;
   case QS_PROXY_SENDDATA_WAITING_FOR_REPLY:
      // Waiting for the SENDDATA response from SE proxy
      status=_ftpQCheckResponse(&event,true,response,true);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,scmd);
         return;
      }
      if( status ) {
         msg="Error with SENDDATA response from SlickEdit proxy.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
         return;
      }

      // Expecting something like:
      //
      // +ok Sending from file "c:\temp\1110001.4"
      _ftpEnQ(event.event,QS_PROXY_DATASTAT_BEGIN,0,&event.fcp,scmd);
      return;
      break;
   case QS_PROXY_DATASTAT_BEGIN:
      status=_ftpVSProxyCommand(&event.fcp,"DATASTAT");
      if( status ) {
         msg="Error sending DATASTAT to SlickEdit proxy.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_PROXY_DATASTAT_WAITING_FOR_REPLY,0,&event.fcp,scmd);
      return;
      break;
   case QS_PROXY_DATASTAT_WAITING_FOR_REPLY:
      // Waiting for the DATASTAT response from SE proxy
      status=_ftpQCheckResponse(&event,true,response,true);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,scmd);
         return;
      }
      if( status ) {
         msg="Error with DATASTAT response from SlickEdit proxy.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
         return;
      }
      // Expecting something like:
      //
      // +ok 1024
      // OR
      // +ok Done
      i=lastpos('+ok',response);
      if( !i ) {
         msg="Error with DATASTAT response from SlickEdit proxy:\n\n":+
             response;
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,INVALID_ARGUMENT_RC);
         return;
      }
      parse substr(response,i) with '+ok' status .;
      status=strip(status);
      status=strip(status,'T',"\n");
      status=strip(status,'T',"\r");
      if( lowcase(status)=='done' ) {
         // Transfer complete
         if( scmd.progressCb ) {
            line=scmd.cmdargv[0];
            for( i=1;i<scmd.cmdargv._length();++i ) {
               line=line:+" ":+scmd.cmdargv[i];
            }
            (*scmd.progressCb)(line,scmd.size,scmd.size);
         }
         _ftpEnQ(event.event,QS_PROXY_CLOSEDATA_BEGIN,0,&event.fcp,scmd);
         return;
      } else if( isinteger(status) ) {
         // Transfer still in progress
         if( scmd.progressCb ) {
            line=scmd.cmdargv[0];
            for( i=1;i<scmd.cmdargv._length();++i ) {
               line=line:+" ":+scmd.cmdargv[i];
            }
            //say('line='line'  status='status'  size='scmd.size);
            (*scmd.progressCb)(line,(int)status,scmd.size);
         }
         _ftpEnQ(event.event,QS_PROXY_DATASTAT_BEGIN,0,&event.fcp,scmd);
         return;
      } else {
         // No idea what this is
         //_message_box("status=["status"]\n\nresponse="response);
         msg="Error with DATASTAT response from SlickEdit proxy:\n\n":+
             response;
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,INVALID_ARGUMENT_RC);
         return;
      }
      break;
   case QS_PROXY_CLOSEDATA_BEGIN:
      status=_ftpVSProxyCommand(&event.fcp,"CLOSEDATA");
      if( status ) {
         msg="Error sending CLOSEDATA to SlickEdit proxy.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_PROXY_CLOSEDATA_WAITING_FOR_REPLY,0,&event.fcp,scmd);
      return;
      break;
   case QS_PROXY_CLOSEDATA_WAITING_FOR_REPLY:
      // Waiting for the CLOSEDATA response from SE proxy
      status=_ftpQCheckResponse(&event,true,response,true);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,scmd);
         return;
      }
      if( status ) {
         msg="Error with CLOSEDATA response from SlickEdit proxy.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
         return;
      }

      // Expecting something like:
      //
      // +ok Received 16384 bytes to file "c:\temp\1110001.4"
      _ftpEnQ(event.event,QS_END_TRANSFER_WAITING_FOR_REPLY,0,&event.fcp,scmd);
      return;
      break;
   case QS_END_TRANSFER_WAITING_FOR_REPLY:
      // Waiting for the response from ftp server that tells us the transfer
      // is complete.
      boolean prelim_reply=false;
      line=event.fcp.lastStatusLine;
      if( line!="" ) {
         _str code=substr(line,1,3);
         if( isinteger(code) && substr(code,1,1)==1 ) {
            prelim_reply=true;
         }

      }
      if( prelim_reply ) {
         status=_ftpQCheckResponse(&event,false,response,false);
         if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
            _ftpReQ(event.event,event.state,event.start,&event.fcp,scmd);
            return;
         }
         if( status ) {
            msg="Error with ":+scmd.cmdargv[0]:+" response.  ":+_ftpGetMessage(status);
            if( status==VSRC_FTP_BAD_RESPONSE ) {
               msg=msg:+"\n\n":+event.fcp.lastStatusLine;
            }
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
            return;
         }
      }
      if( scmd.post_cmds._length()>0 ) {
         _ftpEnQ(event.event,QS_CMD_AFTER_BEGIN,0,&event.fcp,scmd);
      } else if( scmd.orig_cwd._varformat()!=VF_EMPTY && scmd.orig_cwd!="" ) {
         _ftpEnQ(event.event,QS_CWD_AFTER_BEGIN,0,&event.fcp,scmd);
      } else {
         _ftpEnQ(event.event,QS_END,0,&event.fcp,scmd);
      }
      return;
      break;
   case QS_CMD_AFTER_BEGIN:
      // Special case for STORs. Issue a command after sending.
      // Example: OS/400 hosts issue a NAMEFMT command to set the
      // file system after STORing a file.
      if( scmd.post_cmds._length()>0 ) {
         cmdline=scmd.post_cmds[0];
         scmd.post_cmds._deleteel(0);
         status=_ftpCommand(&event.fcp,false,cmdline);
         if( status ) {
            msg="Error sending command: ":+cmdline:+".  ":+_ftpGetMessage(status);
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
            return;
         }
         _ftpEnQ(event.event,QS_CMD_AFTER_WAITING_FOR_REPLY,0,&event.fcp,scmd);
         return;
      }
      _ftpEnQ(event.event,QS_END,0,&event.fcp,scmd);
      return;
      break;
   case QS_CMD_AFTER_WAITING_FOR_REPLY:
      // Waiting for the command response from ftp server
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,scmd);
         return;
      }
      if( status ) {
         msg="Error with command response.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
         return;
      }
      if( scmd.post_cmds._length() ) {
         // More post commands to process
         _ftpEnQ(event.event,QS_CMD_AFTER_BEGIN,0,&event.fcp,scmd);
      } else {
         // Now we can end the send
         _ftpEnQ(event.event,QS_END,0,&event.fcp,scmd);
      }
      return;
      break;
   case QS_CWD_AFTER_BEGIN:
      // Special case for STORs. We must change back to the original
      // remote working directory after STORing the file. VM is a host
      // that requires this.
      if( scmd.orig_cwd._varformat()!=VF_EMPTY && scmd.orig_cwd!="" ) {
         cwd=event.fcp.remoteCwd;
         orig_cwd=scmd.orig_cwd;
         if( !_ftpFileEq(&event.fcp,cwd,orig_cwd) ) {
            #if 0
            if( event.fcp.System==FTPSYST_MVS ) {
               // Make sure this is not an HFS file system
               if( substr(cwd,1,1)!='/' &&
                   (substr(orig_cwd,1,1)!="'" || last_char(orig_cwd)!="'") ) {
                  // We have to make the directory absolute by enclosing with
                  // single-quotes. Otherwise it would be relative to the
                  // current PDS.
                  orig_cwd=strip(orig_cwd,'B',"'");
                  orig_cwd="'":+orig_cwd:+"'";
               }
            }
            #endif
            status=_ftpCommand(&event.fcp,false,"CWD",orig_cwd);
            if( status ) {
               msg="Error sending CWD ":+orig_cwd:+" command.  ":+_ftpGetMessage(status);
               _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
               return;
            }
            _ftpEnQ(event.event,QS_CWD_AFTER_WAITING_FOR_REPLY,0,&event.fcp,scmd);
            return;
         }
      }
      _ftpEnQ(event.event,QS_END,0,&event.fcp,scmd);
      return;
      break;
   case QS_CWD_AFTER_WAITING_FOR_REPLY:
      // Waiting for the CWD response from ftp server
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,scmd);
         return;
      }
      if( status ) {
         msg="Error changing remote directory.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
         return;
      }
      status=_ftpCommand(&event.fcp,false,"PWD");
      if( status ) {
         msg="Error sending PWD command.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_PWD_AFTER_WAITING_FOR_REPLY,0,&event.fcp,scmd);
      return;
      break;
   case QS_PWD_AFTER_WAITING_FOR_REPLY:
      // Waiting for the PWD response from ftp server
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,scmd);
         return;
      }
      if( status ) {
         msg="Error getting remote current working directory.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
         return;
      }
      // We are expecting something like:
      //
      // 257 "/home/slick/www-slickedit" is cwd.
      //
      // Strip off the linebreak char(s)
      response=translate(response,"","\r\n");
      pwd="";
      syst=event.fcp.system;
      if( syst==FTPSYST_MVS || syst==FTPSYST_VXWORKS ) {
         // Special check for PWD output like this:
         //
         // 257 HFS directory / is the working directory.
         //
         // or this:
         //
         // 257 Current directory is "/"
         //
         // where the working directory is not the first thing in the
         // string AND it might not be quoted.
         //
         // Parse off the result code
         parse response with . rest;
         rest=strip(rest);
         if( pos('^HFS directory ',rest,1,'r') ) {
            parse response with . 'HFS directory ' pwd .;
            pwd=strip(pwd,'B','"');   // Just in case
         } else if( pos('^Current directory is',rest,1,'ir') ) {
            // VxWorks
            parse response with . 'Current directory is' pwd .;
            pwd=strip(pwd,'B','"');
         }
      }
      if( pwd=="" ) {
         parse response with . pwd;
         pwd=strip(pwd);
         if( substr(pwd,1,1)=='"' ) {
            i=lastpos('"',pwd);
            if( i ) {
               // A directory enclosed by quotes could have spaces in it,
               // so take the whole quoted string.
               pwd=substr(pwd,1,i);
            } else {
               // Strip off trailing non-directory text
               parse pwd with '"' pwd .;
            }
         } else {
            // Strip off trailing non-directory text
            parse pwd with pwd .;
         }
         pwd=strip(pwd,'B','"');
         // Some MVS hosts put inner single-quotes on the working directory
         pwd=strip(pwd,'B',"'");
         if( pwd=="" ) {
            // This should never happen
            msg="Attempt to change working directory failed.\n\n":+
                "PWD returned:\n\n":+'""';
            _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,PATH_NOT_FOUND_RC);
            return;
         }
      }
      event.fcp.remoteCwd=pwd;
      // Now we can end the send
      _ftpEnQ(event.event,QS_END,0,&event.fcp,scmd);
      return;
      break;
   case QS_ERROR:
      // An error occurred with receving data
      _ftpVSProxyCommand(&event.fcp,"ABORTDATA");
      _ftpQEventDisplayError(event);
      return;
      break;
   case QS_ABORT:
      // Event aborted
      //
      // We might have gotten a message from the SE proxy
      // already, so check.
      event.fcp.reply="";
      event.start=0;
      status=_ftpQCheckResponse(&event,true,response,true);
      //_message_box("1 status="status"  response="response);
      if( status ) {
         // Do not care
      }

      status=_ftpCommand(&event.fcp,false,"ABOR");

      // The SE proxy gives no response to ABORTDATA
      _ftpVSProxyCommand(&event.fcp,"ABORTDATA");

      //_message_box("ABOR sent");
      if( status ) {
         msg="Error sending ABOR.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_ABORT_WAITING_FOR_REPLY,0,&event.fcp,scmd);
      return;
      break;
   case QS_ABORT_WAITING_FOR_REPLY:
      // Waiting for the response from ftp server that tells us the status
      // of the abort.
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp,scmd);
         return;
      }
      if( status ) {
         msg="Error with ABOR response.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,scmd,msg,status);
         return;
      }
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

void _ftpQEHandler_EndConnProfile(FtpQEvent *e_p)
{
   FtpQEvent event = *e_p;   // Make a copy
   typeless status=0;
   _str response="";
   _str msg="";

   // Ending a connection
   switch( event.state ) {
   case QS_BEGIN:
      // Event begins
      status=_ftpCommand(&event.fcp,false,"QUIT");
      #if 1
      if( status ) {
         // Don't really care. We're blasting out of here
         msg="Error sending QUIT to ftp server.  ":+_ftpGetMessage(status);
         _ftpLog(&event.fcp,msg);
         _ftpEnQ(event.event,QS_END,0,&event.fcp);
         return;
      }
      #else
      if( status ) {
         msg="Error sending QUIT to ftp server.  ":+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }
      #endif
      event.fcp.timeout=3;   // Don't wait forever for the sign-off response from ftp server
      _ftpEnQ(event.event,QS_WAITING_FOR_REPLY,0,&event.fcp);
      return;
      break;
   case QS_WAITING_FOR_REPLY:
      // Waiting for the QUIT response from ftp server
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp);
         return;
      }
      #if 1
      if( status ) {
         // Don't really care. We're blasting out of here
         msg="Error with QUIT response.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpLog(&event.fcp,msg);
         _ftpEnQ(event.event,QS_END,0,&event.fcp);
         return;
      }
      #else
      if( status ) {
         msg="Error with QUIT response.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.LastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,msg,status);
         return;
      }
      #endif
      _ftpEnQ(event.event,QS_END,0,&event.fcp);
      return;
      break;
   case QS_ERROR:
      // An error occurred with QUIT
      _ftpQEventDisplayError(event);
      // Fall thru to QS_END
   case QS_ABORT:
      // Event aborted - fall thru to QS_END
   case QS_END:
      // Event ends
      if( event.fcp.sock!=INVALID_SOCKET ) {
         vssSocketClose(event.fcp.sock);
         event.fcp.sock=INVALID_SOCKET;
      }
      // Now we must terminate the SE proxy application
      _ftpEnQ(QE_PROXY_QUIT,QS_BEGIN,0,&event.fcp);
      return;
      break;
   default:
      // Should never get here
      msg="Unknown FTP queue event state: ":+event.state:+" for event ":+event.event;
      _message_box(msg,FTP_ERRORBOX_TITLE,MB_OK|MB_ICONEXCLAMATION);
      break;
   }

   return;
}

void _ftpQEHandler_ProxyQuit(FtpQEvent *e_p)
{
   FtpQEvent event = *e_p;   // Make a copy
   typeless status=0;
   _str response="";
   _str msg="";

   // Kill the SE proxy application
   switch( event.state ) {
   case QS_BEGIN:
      // Event begins
      if( event.fcp.sock!=INVALID_SOCKET ) {
         vssSocketClose(event.fcp.sock);
         event.fcp.sock=INVALID_SOCKET;
      }
      if( event.fcp.vsproxy_sock!=INVALID_SOCKET ) {
         // This will terminate the SE proxy application
         _ftpVSProxyCommand(&event.fcp,"QUIT");
         vssSocketClose(event.fcp.vsproxy_sock);
         event.fcp.vsproxy_sock=INVALID_SOCKET;
         event.fcp.vsproxy_pid= -1;     
      }
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

void _ftpQEHandler_KeepAlive(FtpQEvent *e_p)
{
   FtpQEvent event = *e_p;   // Make a copy
   typeless status=0;
   _str response="";
   _str msg="";
   typeless i;

   switch( event.state ) {
   case QS_BEGIN:
      // Event begins
      status=_ftpCommand(&event.fcp,true,"NOOP");
      if( status ) {
         // Do not care.
         // Find the matching current connection profile and max out the
         // Idle field so that it will not be idle again.
         for( i._makeempty();; ) {
            _ftpCurrentConnections._nextel(i);
            if( i._isempty() ) break;
            if( event.fcp.profileName==_ftpCurrentConnections:[i].profileName &&
                event.fcp.instance==_ftpCurrentConnections:[i].instance ) {
               // Update last idle time
               _ftpCurrentConnections:[i].idle=MAXINT;
               break;
            }
         }
         return;
      }
      _ftpEnQ(event.event,QS_WAITING_FOR_REPLY,0,&event.fcp);
      return;
      break;
   case QS_WAITING_FOR_REPLY:
      // Waiting for the NOOP response from ftp server
      status=_ftpQCheckResponse(&event,true,response,false);
      if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
         _ftpReQ(event.event,event.state,event.start,&event.fcp);
         return;
      }
      for( i._makeempty();; ) {
         _ftpCurrentConnections._nextel(i);
         if( i._isempty() ) break;
         if( event.fcp.profileName==_ftpCurrentConnections:[i].profileName &&
             event.fcp.instance==_ftpCurrentConnections:[i].instance ) {
            // Update last idle time
            if( status ) {
               // Max out the Idle field so that it will not be idle again
               _ftpCurrentConnections:[i].idle=MAXINT;
            } else {
               _ftpCurrentConnections:[i].idle= (double)_time('B');
            }
            break;
         }
      }
      if( status ) {
         // Don't care
      }
      return;
      break;
   case QS_ABORT:
      // Event aborted
      break;
   case QS_ERROR:
      // An error occurred with keep alive (NOOP)
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

void _ftpQEHandler_CustomCmd(FtpQEvent *e_p)
{
   FtpQEvent event= *e_p;   // Make a copy
   FtpCustomCmd ccmd = (FtpCustomCmd)event.info[0];
   typeless status=0;
   _str response="";
   _str msg="";

   switch( event.state ) {
   case QS_BEGIN:
      // Event begins
      status=_ftpCommand(&event.fcp,false,ccmd.cmdargv);
      if( status ) {
         _str line=ccmd.cmdargv[0];
         int i;
         for( i=1;i<ccmd.cmdargv._length();++i ) {
            line=line:+" ":+ccmd.cmdargv[i];
         }
         msg='Error sending command "':+line:+'".  ':+_ftpGetMessage(status);
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,ccmd,msg,status);
         return;
      }
      _ftpEnQ(event.event,QS_WAITING_FOR_REPLY,0,&event.fcp,ccmd);
      return;
      break;
   case QS_WAITING_FOR_REPLY:
      // Waiting for the custom command response from ftp server
      status=_ftpQCheckResponse(&event,false,response,false);
      if( status ) {
         if( status==VSRC_FTP_WAITING_FOR_REPLY ) {
            _ftpReQ(event.event,event.state,event.start,&event.fcp,ccmd);
            return;
         }
         msg="Error with ":+ccmd.cmdargv[0]:+" response.  ":+_ftpGetMessage(status);
         if( status==VSRC_FTP_BAD_RESPONSE ) {
            msg=msg:+"\n\n":+event.fcp.lastStatusLine;
         }
         _ftpEnQ(event.event,QS_ERROR,0,&event.fcp,ccmd,msg,status);
         return;
      }
      // Done
      return;
   case QS_ABORT:
      // Event aborted
      break;
   case QS_ERROR:
      // Error
      _ftpQEventDisplayError(event);
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

void _ftpQKeepAliveCheck()
{
   FtpConnProfile *fcp_p;
   FtpConnProfile fcp;

   typeless i;
   for( i._makeempty();; ) {
      _ftpCurrentConnections._nextel(i);
      if( i._isempty() ) {
         break;
      }
      fcp_p=_ftpCurrentConnections._indexin(i);
      if( fcp_p->serverType==FTPSERVERTYPE_FTP && fcp_p->keepAlive ) {
         // Check how long the current connection has been idle
         // and keep it alive (if necessary).
         double idle= ((double)_time('B') - fcp_p->idle)/1000;   // Seconds
         if( idle>KEEP_ALIVE_IDLETIME && _ftpIsConnectionAlive(fcp_p) ) {
            if( _ftpQ._length()>0 ) {
               if( _ftpQ[0].fcp.profileName==fcp_p->profileName &&
                   _ftpQ[0].fcp.instance==fcp_p->instance &&
                   _ftpQ[0].event==QE_KEEP_ALIVE ) {
                  // We are already in a QE_KEEP_ALIVE event for this
                  // connection profile, so don't do another.
                  continue;
               }
            }
            fcp= *fcp_p;   // Make a copy
            fcp.postedCb=null;
            _ftpEnQ(QE_KEEP_ALIVE,QS_BEGIN,0,&fcp);
         }
      }
   }

   return;
}

#if 0
// Check for any spontaneous or left-over messages from the ftp server
void _ftpQIdle_CheckResponse()
{
   ftpConnProfile_t *fcp_p;
   ftpConnProfile_t fcp;
   ftpQEvent_t event;

   for( i._makeempty();; ) {
      _ftpCurrentConnections._nextel(i);
      if( i._isempty() ) break;
      fcp_p=_ftpCurrentConnections._indexin(i);
      fcp= *fcp_p;   // Make a copy
      fcp.PostedCB=0;   // Paranoid
      // Fake event
      event._makeempty();
      event.event=0;
      event.state=0;
      event.fcp=fcp;
      event.start=0;
      status=_ftpQCheckResponse(&event,false,dummy,false);
      if( status ) {
         // Don't care
      }
   }

   return;
}
#endif

void _ftpQTimerCallback()
{
   FtpQEvent event;

   outer:
   do {

      if( _ftpQ._length()<1 ) {
         _ftpQKeepAliveCheck();
         if( _ftpQ._length()<1 ) {
            break;
         }
      }

      event=_ftpQ[0];   // Make a copy
      _ftpDeQ();
      if( _ftpdebug&FTPDEBUG_SAY_EVENTS ) {
         say(__Qevent2name(event.event)'/'__Qstate2name(event.state));
      }

      // Find the matching connection profile and update its idle time
      typeless i;
      for( i._makeempty();; ) {
         _ftpCurrentConnections._nextel(i);
         if( i._isempty() ) break;
         if( event.fcp.profileName==_ftpCurrentConnections:[i].profileName &&
             event.fcp.instance==_ftpCurrentConnections:[i].instance ) {
            // Update last idle time
            _ftpCurrentConnections:[i].idle= (double)_time('B');
            break;
         }
      }

      if( event.fcp.serverType==FTPSERVERTYPE_SFTP ) {
         // Check for error output from ssh client
         _sftpCheckErrors(&event.fcp);
      }

      switch( event.event ) {
      case QE_START_CONN_PROFILE:
         _ftpQEHandler_StartConnProfile(&event);
         break;
      case QE_PROXY_CONNECT:
         _ftpQEHandler_ProxyConnect(&event);
         break;
      case QE_RELAY_CONNECT:
         _ftpQEHandler_RelayConnect(&event);
         break;
      case QE_PROXY_OPEN:
         _ftpQEHandler_ProxyOpen(&event);
         break;
      case QE_OPEN:
         _ftpQEHandler_Open(&event);
         break;
      case QE_FIREWALL_SPECIAL:
         _ftpQEHandler_FirewallSpecial(&event);
         break;
      case QE_USER:
         _ftpQEHandler_User(&event);
         break;
      case QE_PASS:
         _ftpQEHandler_Pass(&event);
         break;
      case QE_CDUP:
         _ftpQEHandler_Cdup(&event);
         break;
      case QE_CWD:
         _ftpQEHandler_Cwd(&event);
         break;
      case QE_PWD:
         _ftpQEHandler_Pwd(&event);
         break;
      case QE_SYST:
         _ftpQEHandler_Syst(&event);
         break;
      case QE_MKD:
         _ftpQEHandler_Mkd(&event);
         break;
      case QE_DELE:
         _ftpQEHandler_Dele(&event);
         break;
      case QE_RMD:
         _ftpQEHandler_Rmd(&event);
         break;
      case QE_RENAME:
         _ftpQEHandler_Rename(&event);
         break;
      case QE_RECV_CMD:
         _ftpQEHandler_RecvCmd(&event);
         break;
      case QE_SEND_CMD:
         _ftpQEHandler_SendCmd(&event);
         break;
      case QE_END_CONN_PROFILE:
         _ftpQEHandler_EndConnProfile(&event);
         break;
      case QE_PROXY_QUIT:
         _ftpQEHandler_ProxyQuit(&event);
         break;
      case QE_KEEP_ALIVE:
         _ftpQEHandler_KeepAlive(&event);
         break;
      case QE_CUSTOM_CMD:
         _ftpQEHandler_CustomCmd(&event);
         break;

      case QE_SSH_START_CONN_PROFILE:
         _sftpQEHandler_StartConnProfile(&event);
         break;
      case QE_SSH_START:
         _sftpQEHandler_SSHStart(&event);
         break;
#if 0
      case QE_SSH_AUTH_PASSWORD:
         _sftpQEHandler_SSHAuthPassword(&event);
         break;
#endif
      case QE_SFTP_INIT:
         _sftpQEHandler_SFTPInit(&event);
         break;
      case QE_SFTP_STAT:
         _sftpQEHandler_Stat(&event);
         break;
      case QE_SFTP_DIR:
         _sftpQEHandler_Dir(&event);
         break;
      case QE_SFTP_GET:
         _sftpQEHandler_Get(&event);
         break;
      case QE_SFTP_PUT:
         _sftpQEHandler_Put(&event);
         break;
      case QE_SFTP_REMOVE:
         _sftpQEHandler_Remove(&event);
         break;
      case QE_SFTP_RMDIR:
         _sftpQEHandler_Rmdir(&event);
         break;
      case QE_SFTP_MKDIR:
         _sftpQEHandler_Mkdir(&event);
         break;
      case QE_SFTP_RENAME:
         _sftpQEHandler_Rename(&event);
         break;
      case QE_SSH_END_CONN_PROFILE:
         _sftpQEHandler_EndConnProfile(&event);
         break;

      case QE_ERROR:
         _message_box(event.info[0],FTP_ERRORBOX_TITLE,MB_OK|MB_ICONEXCLAMATION);
         break;
      default:
         // Should never get here
         _str msg="Unknown FTP queue event : ":+event.event;
         _message_box(msg,FTP_ERRORBOX_TITLE,MB_OK|MB_ICONEXCLAMATION);
         break outer;
      }

      // Start/stop/restart the timer
      _ftpQSmartStartTimer();

      if( _ftpQ._length()<1 ) {
         // We just went idle
         call_list('_ftpQIdle_');
      }

      if( !event.fcp.postedCb ) {
         // Done
         break;
      }

      if( _ftpQ._length()<1 ) {
         // We are idle, so call any callback functions
         (*event.fcp.postedCb)(&event);
         break;
      } else {
         // If the processed event was the last event for that particular
         // connection profile, then call its callback function.
         boolean last=true;
         for( i=0;i<_ftpQ._length();++i ) {
            if( _ftpQ[i].fcp.profileName==event.fcp.profileName &&
                _ftpQ[i].fcp.instance==event.fcp.instance ) {
               last=false;
               break;
            }
         }
         if( last ) {
            (*event.fcp.postedCb)(&event);
            break;
         }
      }

   } while( false );

   return;
}

/**
 * A pointer to this function is assigned to pfnftpQTimerCallback so that
 * we can tell when the timer callback is for the slow timer interval or
 * not.
 */
void _ftpQSlowTimerCallback()
{
   _ftpQTimerCallback();

   return;
}

/**
 * There are 3 cases this function handles:<br>
 * <ol>
 *   <li>Do not start the timer if there are no active connections
 *   <li>If there are active connections, but no events to be processed,
 *       then start the timer with a slow interval (for KeepAlive).
 *   <li>If there are active connections, and events to be processed,
 *       then start the timer with the fast interval.
 * </ol>
 */
void _ftpQSmartStartTimer()
{
   boolean connections=false;
   boolean events=false;
   typeless i;
   i._makeempty();
   _ftpCurrentConnections._nextel(i);
   if( !(i._isempty()) ) {
      connections=true;
   }
   if( _ftpQ._length()>0 ) {
      events=true;
   }
   // You can have events without connections if you are just starting a connection
   if( connections || events ) {
      if( events ) {
         // Need fast interval
         boolean slow= (pfnftpQTimerCallback!=_ftpQTimerCallback);
         if( slow || _ftpQTimer<0 ) {
            // Reallocate the timer with the fast interval
            _ftpQKillTimer();
            pfnftpQTimerCallback=_ftpQTimerCallback;
            _ftpQTimer=_set_timer(FTPQTIMER_INTERVAL,pfnftpQTimerCallback);
         }
      } else {
         if( connections ) {
            // Need slow interval
            boolean fast= (pfnftpQTimerCallback!=_ftpQSlowTimerCallback);
            if( fast || _ftpQTimer<0 ) {
               // Reallocate the timer with the slow interval
               _ftpQKillTimer();
               pfnftpQTimerCallback=_ftpQSlowTimerCallback;
               _ftpQTimer=_set_timer(FTPQTIMER_SLOW_INTERVAL,pfnftpQTimerCallback);
            }
         } else {
            _ftpQKillTimer();
         }
      }
   } else {
      _ftpQKillTimer();
   }

   return;
}

void _ftpQKillTimer()
{
   _kill_timer(_ftpQTimer);
   _ftpQTimer= -2;   // -1 is for the get_event() timer
   pfnftpQTimerCallback=null;

   return;
}

static _str __Qevent2name(int e)
{
   switch( e ) {
   case QE_START_CONN_PROFILE:
      return("QE_START_CONN_PROFILE");
      break;
   case QE_PROXY_CONNECT:
      return("QE_PROXY_CONNECT");
      break;
   case QE_RELAY_CONNECT:
      return("QE_RELAY_CONNECT");
      break;
   case QE_PROXY_OPEN:
      return("QE_PROXY_OPEN");
      break;
   case QE_OPEN:
      return("QE_OPEN");
      break;
   case QE_SYST:
      return("QE_SYST");
      break;
   case QE_FIREWALL_SPECIAL:
      return("QE_FIREWALL_SPECIAL");
      break;
   case QE_USER:
      return("QE_USER");
      break;
   case QE_PASS:
      return("QE_PASS");
      break;
   case QE_CDUP:
      return("QE_CDUP");
      break;
   case QE_CWD:
      return("QE_CWD");
      break;
   case QE_PWD:
      return("QE_PWD");
      break;
   case QE_DELE:
      return("QE_DELE");
      break;
   case QE_MKD:
      return("QE_MKD");
      break;
   case QE_RMD:
      return("QE_RMD");
      break;
   case QE_RENAME:
      return("QE_RENAME");
      break;
   case QE_RECV_CMD:
      return("QE_RECV_CMD");
      break;
   case QE_SEND_CMD:
      return("QE_SEND_CMD");
      break;
   case QE_END_CONN_PROFILE:
      return("QE_END_CONN_PROFILE");
      break;
   case QE_PROXY_QUIT:
      return("QE_PROXY_QUIT");
      break;
   case QE_KEEP_ALIVE:
      return("QE_KEEP_ALIVE");
      break;
   case QE_CUSTOM_CMD:
      return("QE_CUSTOM_CMD");
      break;

   case QE_SSH_START_CONN_PROFILE:
      return("QE_SSH_START_CONN_PROFILE");
      break;
   case QE_SSH_START:
      return("QE_SSH_START");
      break;
   case QE_SFTP_INIT:
      return("QE_SFTP_INIT");
      break;
   case QE_SSH_AUTH_PASSWORD:
      return("QE_SSH_AUTH_PASSWORD");
      break;
   case QE_SFTP_STAT:
      return("QE_SFTP_STAT");
      break;
   case QE_SFTP_DIR:
      return("QE_SFTP_DIR");
      break;
   case QE_SFTP_GET:
      return("QE_SFTP_GET");
      break;
   case QE_SFTP_PUT:
      return("QE_SFTP_PUT");
      break;
   case QE_SFTP_REMOVE:
      return("QE_SFTP_REMOVE");
      break;
   case QE_SFTP_RMDIR:
      return("QE_SFTP_RMDIR");
      break;
   case QE_SFTP_MKDIR:
      return("QE_SFTP_MKDIR");
      break;
   case QE_SFTP_RENAME:
      return("QE_SFTP_RENAME");
      break;
   case QE_SSH_END_CONN_PROFILE:
      return("QE_SSH_END_CONN_PROFILE");
      break;

   case QE_ERROR:
      return("QE_ERROR");
      break;
   }

   return("UNKNOWN=":+e);
}

static _str __Qstate2name(int s)
{
   switch( s ) {
   case QS_BEGIN:
      return("QS_BEGIN");
      break;
   case QS_WAITING_FOR_REPLY:
      return("QS_WAITING_FOR_REPLY");
      break;
   case QS_LISTENING:
      return("QS_LISTENING");
      break;
   case QS_PROMPT:
      return("QS_PROMPT");
      break;
   case QS_PORT_BEGIN:
      return("QS_PORT_BEGIN");
      break;
   case QS_PORT_WAITING_FOR_REPLY:
      return("QS_PORT_WAITING_FOR_REPLY");
      break;
   case QS_PASV_BEGIN:
      return("QS_PASV_BEGIN");
      break;
   case QS_PASV_WAITING_FOR_REPLY:
      return("QS_PASV_WAITING_FOR_REPLY");
      break;
   case QS_EPRT_BEGIN:
      return("QS_EPRT_BEGIN");
      break;
   case QS_EPRT_WAITING_FOR_REPLY:
      return("QS_EPRT_WAITING_FOR_REPLY");
      break;
   case QS_EPSV_BEGIN:
      return("QS_EPSV_BEGIN");
      break;
   case QS_EPSV_WAITING_FOR_REPLY:
      return("QS_EPSV_WAITING_FOR_REPLY");
      break;
   case QS_PROXY_OPENDATA_BEGIN:
      return("QS_PROXY_OPENDATA_BEGIN");
      break;
   case QS_PROXY_OPENDATA_WAITING_FOR_REPLY:
      return("QS_PROXY_OPENDATA_WAITING_FOR_REPLY");
      break;
   case QS_PROXY_LISTENDATA_BEGIN:
      return("QS_PROXY_LISTENDATA_BEGIN");
      break;
   case QS_PROXY_LISTENDATA_WAITING_FOR_REPLY:
      return("QS_PROXY_LISTENDATA_WAITING_FOR_REPLY");
      break;
   case QS_TYPE_BEGIN:
      return("QS_TYPE_BEGIN");
      break;
   case QS_TYPE_WAITING_FOR_REPLY:
      return("QS_TYPE_WAITING_FOR_REPLY");
      break;
   case QS_CMD_BEGIN:
      return("QS_CMD_BEGIN");
      break;
   case QS_CMD_WAITING_FOR_REPLY:
      return("QS_CMD_WAITING_FOR_REPLY");
      break;
   case QS_PROXY_RECVDATA_BEGIN:
      return("QS_PROXY_RECVDATA_BEGIN");
      break;
   case QS_PROXY_RECVDATA_WAITING_FOR_REPLY:
      return("QS_PROXY_RECVDATA_WAITING_FOR_REPLY");
      break;
   case QS_PROXY_SENDDATA_BEGIN:
      return("QS_PROXY_SENDDATA_BEGIN");
      break;
   case QS_PROXY_SENDDATA_WAITING_FOR_REPLY:
      return("QS_PROXY_SENDDATA_WAITING_FOR_REPLY");
      break;
   case QS_PROXY_DATASTAT_BEGIN:
      return("QS_PROXY_DATASTAT_BEGIN");
      break;
   case QS_PROXY_DATASTAT_WAITING_FOR_REPLY:
      return("QS_PROXY_DATASTAT_WAITING_FOR_REPLY");
      break;
   case QS_PROXY_CLOSEDATA_BEGIN:
      return("QS_PROXY_CLOSEDATA_BEGIN");
      break;
   case QS_PROXY_CLOSEDATA_WAITING_FOR_REPLY:
      return("QS_PROXY_CLOSEDATA_WAITING_FOR_REPLY");
      break;
   case QS_END_TRANSFER_WAITING_FOR_REPLY:
      return("QS_END_TRANSFER_WAITING_FOR_REPLY");
      break;
   case QS_CWD_BEFORE_BEGIN:
      return("QS_CWD_BEFORE_BEGIN");
      break;
   case QS_CWD_BEFORE_WAITING_FOR_REPLY:
      return("QS_CWD_BEFORE_WAITING_FOR_REPLY");
      break;

   case QS_CMD_BEFORE_BEGIN:
      return("QS_CMD_BEFORE_BEGIN");
      break;
   case QS_CMD_BEFORE_WAITING_FOR_REPLY:
      return("QS_CMD_BEFORE_WAITING_FOR_REPLY");
      break;
   case QS_CMD_AFTER_BEGIN:
      return("QS_CMD_BEFORE_BEGIN");
      break;
   case QS_CMD_AFTER_WAITING_FOR_REPLY:
      return("QS_CMD_BEFORE_WAITING_FOR_REPLY");
      break;

   case QS_PWD_BEFORE_WAITING_FOR_REPLY:
      return("QS_PWD_BEFORE_WAITING_FOR_REPLY");
      break;
   case QS_CWD_AFTER_BEGIN:
      return("QS_CWD_BEFORE_BEGIN");
      break;
   case QS_CWD_AFTER_WAITING_FOR_REPLY:
      return("QS_CWD_BEFORE_WAITING_FOR_REPLY");
      break;
   case QS_PWD_AFTER_WAITING_FOR_REPLY:
      return("QS_PWD_BEFORE_WAITING_FOR_REPLY");
      break;
   case QS_RNFR_WAITING_FOR_REPLY:
      return("QS_RNFR_WAITING_FOR_REPLY");
      break;
   case QS_RNTO_WAITING_FOR_REPLY:
      return("QS_RNTO_WAITING_FOR_REPLY");
      break;
   case QS_ERROR:
      return("QS_ERROR");
      break;
   case QS_ABORT:
      return("QS_ABORT");
      break;
   case QS_ABORT_WAITING_FOR_REPLY:
      return("QS_ABORT_WAITING_FOR_REPLY");
      break;
   case QS_FWUSER_WAITING_FOR_REPLY:
      return("QS_FWUSER_WAITING_FOR_REPLY");
      break;
   case QS_FWPASS_WAITING_FOR_REPLY:
      return("QS_FWPASS_WAITING_FOR_REPLY");
      break;
   case QS_FWOPEN_WAITING_FOR_REPLY:
      return("QS_FWOPEN_WAITING_FOR_REPLY");
      break;

   case QS_WAITING_FOR_PROMPT:
      return("QS_WAITING_FOR_PROMPT");
      break;
   case QS_MAYBE_WAITING_FOR_PROMPT:
      return("QS_MAYBE_WAITING_FOR_PROMPT");
      break;
   case QS_WAITING_FOR_DONE:
      return("QS_WAITING_FOR_DONE");
      break;

   case QS_FXP_INIT_WAITING_FOR_REPLY:
      return("QS_FXP_INIT_WAITING_FOR_REPLY");
      break;
   case QS_FXP_STATUS_WAITING_FOR_REPLY:
      return("QS_FXP_STATUS_WAITING_FOR_REPLY");
      break;
   case QS_FXP_ATTRS_WAITING_FOR_REPLY:
      return("QS_FXP_ATTRS_WAITING_FOR_REPLY");
      break;
   case QS_FXP_HANDLE_WAITING_FOR_REPLY:
      return("QS_FXP_HANDLE_WAITING_FOR_REPLY");
      break;
   case QS_FXP_NAME_WAITING_FOR_REPLY:
      return("QS_FXP_NAME_WAITING_FOR_REPLY");
      break;
   case QS_FXP_READDIR:
      return("QS_FXP_READDIR");
      break;
   case QS_FXP_READ:
      return("QS_FXP_READ");
      break;
   case QS_FXP_DATA_WAITING_FOR_REPLY:
      return("QS_FXP_DATA_WAITING_FOR_REPLY");
      break;
   case QS_PASSWORD:
      return("QS_PASSWORD");
      break;
   case QS_FXP_WRITESTATUS_WAITING_FOR_REPLY:
      return("QS_FXP_WRITESTATUS_WAITING_FOR_REPLY");
      break;

   case QS_END:
      return("QS_END");
      break;
   }

   return("UNKNOWN=":+s);
}

