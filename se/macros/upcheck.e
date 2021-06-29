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
#include "xml.sh"
#include "pipe.sh"
#include "listbox.sh"
#import "listbox.e"
#include "license.sh"
#import "main.e"
#import "optionsxml.e"
#import "pipe.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "toast.e"
#import "treeview.e"
#import "xmlcfg.e"
#endregion


// Pointer-to-function to call when the queue processes the last event and goes idle
typedef void (*UpcheckPostEventCallback)(...);

typedef struct upcheckConnection_s {

   // Handle to upcheck.exe process
   int hprocess;

   // Handle to input pipe for upcheck.exe connection
   int hin;

   // Handle to output pipe for upcheck.exe connection
   int hout;

   // Handle to err pipe for upcheck.exe connection
   int herr;

   /**
    * Pointer-to-function to call when the queue processes the last
    * event and goes idle.
    */
   UpcheckPostEventCallback postedCb;

   /**
    * Operation defined.
    */
   typeless extra;

} upcheckConnection_t;

static const UPCHECK_QE_FIRST=    1;
static const UPCHECK_QE_START=    (UPCHECK_QE_FIRST+0);
static const UPCHECK_QE_VERSION=  (UPCHECK_QE_FIRST+1);
static const UPCHECK_QE_MANIFEST= (UPCHECK_QE_FIRST+2);
static const UPCHECK_QE_QUIT=     (UPCHECK_QE_FIRST+3);
static const UPCHECK_QE_END=      (UPCHECK_QE_FIRST+4);
static const UPCHECK_QE_ONIDLE=   (UPCHECK_QE_FIRST+5);
static const UPCHECK_QE_LAST=     UPCHECK_QE_ONIDLE;

static const UPCHECK_QS_FIRST=             1;
static const UPCHECK_QS_BEGIN=             (UPCHECK_QS_FIRST+0);
static const UPCHECK_QS_WAITING_FOR_REPLY= (UPCHECK_QS_FIRST+1);
static const UPCHECK_QS_ERROR=             (UPCHECK_QS_FIRST+2);
static const UPCHECK_QS_ABORT=             (UPCHECK_QS_FIRST+3);
static const UPCHECK_QS_END=               (UPCHECK_QS_FIRST+4);
static const UPCHECK_QS_LAST=              UPCHECK_QS_END;

typedef struct upcheckQEvent_s {


   // Event to be processed
   int event;


   // State of the event (i.e. waiting for a reply, etc.)
   int state;

   // Time (in milliseconds) that this event started
   double start;

   // upcheck.exe connection
   upcheckConnection_t ucc;

   // Additional event-defined information
   typeless info[];

} upcheckQEvent_t;

/**
 * Timer interval used when there are upcheck events to be processed.
 * 0.1 seconds (in milliseconds).
 */
static const UPCHECKQTIMER_INTERVAL= (100);

/**
 * Timer interval used when there are no upcheck events to be processed.
 * 10 minutes (in milliseconds).
 */
static const UPCHECKQTIMER_SLOW_INTERVAL= (600000);
//#define UPCHECKQTIMER_SLOW_INTERVAL (5000)

/**
 * Pointer-to-function for current timer callback. This is used to keep
 * track of whether we are using the slow timer callback or not.
 */
typedef void (*pfnupcheckQTimerCallback_tp)();

static pfnupcheckQTimerCallback_tp pfnupcheckQTimerCallback;

/** Timer used when checking for updates. */
int _upcheckQTimer= -1;

/**
 * _upcheckQ cannot be static, otherwise it would get blown away when user
 * re-load()s.
 */
upcheckQEvent_t _upcheckQ[];

/** Current upcheck connection. */
upcheckConnection_s _upcheckCurrentConnection;

/** Convert minutes to milliseconds */
#define UPCHECK_MSMINUTES(m) (m*60*1000)
/** Convert hours to milliseconds */
#define UPCHECK_MSHOURS(h) (h*60*60*1000)
/** Convert days to milliseconds */
#define UPCHECK_MSDAYS(d) (d*24*60*60*1000)

/** Update interval = 1 day = 86400000 */
#define UPCHECK_INTERVAL_1DAY UPCHECK_MSDAYS(1)

/** Update interval = 1 week = 604800000 */
#define UPCHECK_INTERVAL_1WEEK UPCHECK_MSDAYS(7)

/**
 * Default interval between update fetches. 24 hours (in milliseconds).
 * 
 * <p>
 * Note:<br>
 * This is not the same as the timer interval.
 * </p>
 */
#define UPCHECK_DEFAULT_FETCH_INTERVAL UPCHECK_INTERVAL_1DAY

double def_upcheck_fetch_interval=UPCHECK_DEFAULT_FETCH_INTERVAL;

/** Last update fetch time. This is global so it is persistent across loading. */
double _upcheck_last_fetch=0;

/** Timeout waiting for a response. 30 seconds (in milliseconds). */
static const UPCHECK_TIMEOUT= 30000;

/** Path to update.exe */
static _str _upcheckPath="";

typedef struct upcheckUpdate_s {
   _str DisplayName;
   _str PackageName;
   _str Version;
   _str Type;
   _str TimeStamp;
   _str Summary;
   _str Description;
   _str Options;
   _str Status;
   _str RemindTime;

   // Node of this update in manifest file
   int node;
} upcheckUpdate_t;

/** upcheck.exe major version supported. */
static const UPC_VER_MAJOR=       1;
/** upcheck.exe minor version supported. */
static const UPC_VER_MINOR=       0;
/** upcheck.exe revision version supported. */
static const UPC_VER_SUB=         0;
/** upcheck.exe build version supported. */
static const UPC_VER_BUILD=       0;

// Return codes used by _upcheckNotify form
static const UPCHECKNOTIFYDLG_STATUS_DISPLAYNOW=  0;
static const UPCHECKNOTIFYDLG_STATUS_REMINDLATER= 1;

static const UPCHECK_DEBUGFLAG_TIME_STAMP=  0x1;
static const UPCHECK_DEBUGFLAG_SAVE_LOG=    0x2;
static const UPCHECK_DEBUGFLAG_EXTRA_DEBUG= 0x4;
static const UPCHECK_DEBUGFLAG_SAY_DEBUG=   0x8;
int _upcheckdebug;

static void upcheckDebug(_str line) {
   if( _upcheckdebug&UPCHECK_DEBUGFLAG_EXTRA_DEBUG ) {
      upcheckLog(&_upcheckCurrentConnection,"!!! DEBUG: "line,true);
      if( _upcheckdebug&UPCHECK_DEBUGFLAG_SAY_DEBUG ) {
         say("!!! DEBUG: "line);
      }
   }
}
static void upcheckInfo(_str line) {
   upcheckLog(&_upcheckCurrentConnection,"!!! INFO: "line);
}
static void upcheckError(_str line) {
   upcheckLog(&_upcheckCurrentConnection,"!!! ERROR: "line);
}
static void upcheckWarn(_str line) {
   upcheckLog(&_upcheckCurrentConnection,"!!! WARNING: "line);
}

definit()
{
   // Do not blow away the queue if loading
   if( arg(1)!='L' ) {
      _upcheckQ._makeempty();
      _upcheckCurrentConnection._makeempty();
      _upcheckSetIdleCheck(true);
   }

   // Q timer
   if( arg(1)=='L') {
      _upcheckQKillTimer();
   }
   _upcheckQTimer= -2;   // -1 is for the get_event() timer

   // def_upcheck_fetch_interval=0 means the user does not want upcheck
   // to notify them of available updates.
   //
   // OEMs do not want upcheck popping up dialogs in their products
   // about available updates.
   if( def_upcheck_fetch_interval>0 &&
       !_OEM() &&
       !isEclipsePlugin() ) {
      _upcheckQSmartStartTimer();
   }

   _upcheckPath="";

   rc=0;
}

static void _upcheckEnQ(int e, int state, double start, upcheckConnection_t *ucc_p,...)
{
   upcheckQEvent_t event;

   if( e<UPCHECK_QE_FIRST || e>UPCHECK_QE_LAST ) {
      _message_box("Unknown update checker queue event: ":+e,"",MB_OK|MB_ICONEXCLAMATION);
      return;
   }
   if( state<UPCHECK_QS_FIRST || state>UPCHECK_QS_LAST ) {
      _message_box("Unknown update checker queue event state: ":+state,"",MB_OK|MB_ICONEXCLAMATION);
      return;
   }

   event._makeempty();
   event.event=e;
   event.state=state;

   if( ucc_p ) {
      event.ucc= *ucc_p;
   }

   if( start>0 ) {
      // Starting time specified. This usually means we are waiting for
      // something to happen, so we keep track of an original starting
      // time so we can test for a timeout condition.
      event.start=start;
   } else {
      // Starting...now
      event.start= (double)_time('B');
   }
   int i;
   for( i=5;i<=arg();++i ) {
      event.info[event.info._length()]=arg(i);
   }

   _upcheckQ[_upcheckQ._length()]=event;

   // Start the timer that will handle events
   _upcheckQSmartStartTimer();

   return;
}

/**
 * Queue the event at the front of the event queue.
 */
static void _upcheckReQ(int e, int state, double start,  upcheckConnection_t *ucc_p, ...)
{
   upcheckQEvent_t event;

   if( e<UPCHECK_QE_FIRST || e>UPCHECK_QE_LAST ) {
      _message_box("Unknown update checker queue event: ":+e,"",MB_OK|MB_ICONEXCLAMATION);
      return;
   }
   if( state<UPCHECK_QS_FIRST || state>UPCHECK_QS_LAST ) {
      _message_box("Unknown update checker queue event state: ":+state,"",MB_OK|MB_ICONEXCLAMATION);
      return;
   }

   event._makeempty();
   event.event=e;
   event.state=state;

   if( ucc_p ) {
      event.ucc= *ucc_p;
   }

   if( start>0 ) {
      // Starting time specified. This usually means we are waiting for
      // something to happen, so we keep track of an original starting
      // time so we can test for a timeout condition.
      event.start=start;
   } else {
      // Starting...now
      event.start= (double)_time('B');
   }
   int i;
   for( i=5;i<=arg();++i ) {
      event.info[event.info._length()]=arg(i);
   }

   _upcheckQ[_upcheckQ._length()]=event;

   // Start the timer that will handle events
   _upcheckQSmartStartTimer();

   return;
}

static void _upcheckDeQ()
{
   if( _upcheckQ._length()>0 ) {
      _upcheckQ._deleteel(0);
   }

   return;
}

_command void upcheck_notify() name_info(','VSARG2_NCW|VSARG2_READ_ONLY)
{
   // Pass arg(1)=true to force us through the idle code so that
   // can be notified in the normal way.
   upcheckUpdateCheck(true);
}

_command void upcheck_display() name_info(','VSARG2_NCW|VSARG2_READ_ONLY)
{
   upcheckUpdateCheck();
}

_command void upcheck_options() name_info(','VSARG2_NCW|VSARG2_READ_ONLY)
{
   upcheckOptions();
}

static void _upcheckInitConnection(upcheckConnection_t& ucc)
{
   ucc.hprocess= -1;
   ucc.hin= -1;
   ucc.hout= -1;
   ucc.herr= -1;
   ucc.postedCb=null;
   ucc.extra._makeempty();
}

static int DaysInMonth[] = {
   31    // Jan
   ,28   // Feb
   ,31   // Mar
   ,30   // Apr
   ,31   // May
   ,30   // Jun
   ,31   // Jul
   ,31   // Aug
   ,30   // Sep
   ,31   // Oct
   ,30   // Nov
   ,31   // Dec
};

/**
 * @return Milliseconds since January 1, 1970 00:00:00. Leap years are
 * not calculated, and this function is only used by upcheck, and upcheck
 * does not use outside times in combination with the time calcuated by
 * it, so there is no risk of mis-computation. Note that resolution is in
 * seconds, so this function is not suitable for millisecond resolution
 * timers (use _time('B') instead).
 */
static double _upcheckTime()
{
   time := 0.0;
   _str mo, dd, yyyy;
   parse _date('U') with mo'/'dd'/'yyyy;
   time += ((double)yyyy-1970) * 365 * 24 * 60 * 60 * 1000 +
           ((double)mo-1) * (double)DaysInMonth[(int)mo-1] * 24 * 60 * 60 * 1000 +
           ((double)dd-1) * 24 * 60 * 60 * 1000;
   _str hh, mm, ss;
   parse _time('M') with hh':'mm':'ss;
   time += (double)hh * 60 * 60 * 1000 +
           (double)mm * 60 * 1000 +
           (double)ss * 1000;

   return time;
}

static bool _timedOut(double start, double max)
{
   if( max<=0 ) {
      return false;
   }
   double current_time = (double)_time('B');
   if( start>current_time ) {
      // Start time is in the future. Depending on how far, we may never
      // time out, so force a timeout now.
      return true;
   }
   return ((current_time - start) >= max);
}

static bool _upcheckTimedOut(double start, double max)
{
   if( max<=0 ) {
      return false;
   }
   double current_time = _upcheckTime();
   if( start>current_time ) {
      // Start time is in the future. Depending on how far, we may never
      // time out, so force a timeout now.
      return true;
   }
   return ((current_time - start) >= max);
}

static void __upcheckUpdateCheckIdleCB(...);

/**
 * Default callback for processing events common to most
 * operations (e.g. MANIFEST). This callback will normally
 * be overridden by a task-specific callback.
 * 
 * @param arg(1) upcheckEvent_t object
 * @param arg(2) Alternate pointer to callback function to set
 *               the .postedCb member of the upcheckEvent_t
 *               object for queued event.
 */
static void __upcheckUpdateCheckCB(...)
{
   upcheckQEvent_t event;
   upcheckConnection_t ucc;

   event= *((upcheckQEvent_t *)(arg(1)));

   UpcheckPostEventCallback pfnAltCB = null;
   if( arg(2)!="" ) {
      pfnAltCB = (UpcheckPostEventCallback)arg(2);
   }

   ucc=event.ucc;

   if( event.state==UPCHECK_QS_ERROR || event.state==UPCHECK_QS_ABORT ) {
      // The error message (if any) is logged, so just kill the connection
      // and bail. We will try again later.
      upcheckCloseConnection();
      //_upcheckDeleteLogBuffer(&ucc);
      return;
   }

   if( pfnAltCB!=null ) {
      ucc.postedCb=pfnAltCB;
   } else {
      ucc.postedCb=__upcheckUpdateCheckCB;
   }

   switch( event.event ) {
   case UPCHECK_QE_START:
      // Successful start of connection
      _upcheckEnQ(UPCHECK_QE_VERSION,UPCHECK_QS_BEGIN,0,&ucc);
      upcheckLog(&ucc,"\n");
      upcheckLog(&ucc,"### BEGIN: Update check: ":+_date():+" at ":+_time('M'));
      return;
      break;
   case UPCHECK_QE_VERSION:
      // Successful version check
      // This is now the current connection
      _upcheckCurrentConnection=ucc;
      _upcheckCurrentConnection.postedCb=null;
      _upcheckEnQ(UPCHECK_QE_MANIFEST,UPCHECK_QS_BEGIN,0,&ucc);
      return;
      break;
   case UPCHECK_QE_MANIFEST: {
      // Successful fetch of manifest
      // Quit the connection
      _upcheckEnQ(UPCHECK_QE_QUIT,UPCHECK_QS_BEGIN,0,&ucc);
      _upcheckEnQ(UPCHECK_QE_END,UPCHECK_QS_BEGIN,0,&ucc);
      return;
      break;
   }
   case UPCHECK_QE_QUIT:
      // Now we can end the upcheck connection
      // Note:
      // Should not get here, since we queued the QUIT and END at the same
      // time.
      _upcheckEnQ(UPCHECK_QE_END,UPCHECK_QS_BEGIN,0,&ucc);
      break;
   case UPCHECK_QE_END:
      // Successful end of connection
      // Note:
      // This event will normally be overridden by a calling function
      // that performs some operation on the manifest file retrieved.
      _upcheckCurrentConnection._makeempty();
      _upcheckRemindLater();
      upcheckLog(&ucc,"### END: Update check ":+_date():+" at ":+_time('M'));
      break;
   }

   // All done
   return;
}

/**
 * Update checker callback that ONLY displays available updates
 * after the user has gone idle.
 * 
 * @param arg(1) upcheckEvent_t object
 */
static void __upcheckUpdateCheckIdleNotifyCB(...)
{
   upcheckQEvent_t event;
   upcheckConnection_t ucc;

   event= *((upcheckQEvent_t *)(arg(1)));

   ucc=event.ucc;

   if( event.state==UPCHECK_QS_ERROR || event.state==UPCHECK_QS_ABORT ) {
      // Call the default callback for normal processing
      __upcheckUpdateCheckCB(arg(1),__upcheckUpdateCheckIdleNotifyCB);
      // Even though we failed, we still want to remind later. Otherwise,
      // the update manager would run on every timer interval (10 minutes)
      // and attempt to retrieve updates from the website.
      _upcheckRemindLater();
      return;
   }

   ucc.postedCb=__upcheckUpdateCheckIdleNotifyCB;

   switch( event.event ) {
   case UPCHECK_QE_END:
      // Successful end of connection
      // Call the default callback for normal processing
      __upcheckUpdateCheckCB(arg(1),__upcheckUpdateCheckIdleNotifyCB);
      // The downloaded manifest.xml file has been passed around in the
      // .extra field of the connection, so now we can queue the on-idle
      // processing of the manifest.
      _upcheckEnQ(UPCHECK_QE_ONIDLE,UPCHECK_QS_BEGIN,0,&ucc);
      break;
   case UPCHECK_QE_ONIDLE:
      // If idle, then reconcile updates and notify user
      if( _AppHasFocus() && _idle_time_elapsed()>1000 ) {
         _str manifest_filename = ucc.extra;
         _upcheckRemindLater();
         _upcheckReconcileToUserManifest(manifest_filename);
         delete_file(manifest_filename);
         upcheckNotifyUpdates(_upcheckUserManifestFilename());
      } else {
         // Re-enqueue until we are idle
         _upcheckEnQ(UPCHECK_QE_ONIDLE,UPCHECK_QS_BEGIN,0,&ucc);
      }
      break;
   default:
      __upcheckUpdateCheckCB(arg(1),__upcheckUpdateCheckIdleNotifyCB);
   }
}

/**
 * Update checker callback that displays available updates immediately
 * after download.
 * 
 * @param arg(1) upcheckEvent_t object
 */
static void __upcheckUpdateCheckDisplayCB(...)
{
   upcheckQEvent_t event;
   upcheckConnection_t ucc;

   event= *((upcheckQEvent_t *)(arg(1)));

   ucc=event.ucc;

   if( event.state==UPCHECK_QS_ERROR || event.state==UPCHECK_QS_ABORT ) {
      // Call the default callback for normal processing
      __upcheckUpdateCheckCB(arg(1),__upcheckUpdateCheckDisplayCB);
      // Let the user know, since they were expecting to see updates displayed
      _str msg = get_message(VSRC_UPCHECK_ERROR_RETRIEVING_UPDATES)".\n\n"event.info[0];
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return;
   }

   ucc.postedCb=__upcheckUpdateCheckDisplayCB;

   switch( event.event ) {
   case UPCHECK_QE_END:
      // Successful end of connection
      // Call the default callback for normal processing
      __upcheckUpdateCheckCB(arg(1),__upcheckUpdateCheckDisplayCB);
      // The downloaded manifest.xml file has been passed around in the
      // .extra field of the connection, so now we can display them.
      _str manifest_filename = ucc.extra;
      _upcheckRemindLater();
      _upcheckReconcileToUserManifest(manifest_filename);
      delete_file(manifest_filename);
      upcheckDisplayUpdates(_upcheckUserManifestFilename());
      break;
   default:
      __upcheckUpdateCheckCB(arg(1),__upcheckUpdateCheckDisplayCB);
   }
}

/**
 * Perform an update check.
 * 
 * @param idleNotify true=Perform update check on a timer and notify
 *                   the user about updates (if any) when idle.
 *                   false=Perform immediate update check and display
 *                   updates to user.
 */
void upcheckUpdateCheck(bool idleNotify=false)
{
   upcheckConnection_t ucc;

   _upcheckInitConnection(ucc);

   if( !_upcheckCurrentConnection._isempty() ) {
      // We already have a connection, so try to use it
      int hprocess = _upcheckCurrentConnection.hprocess;
      if( hprocess<0 || _PipeIsProcessExited(hprocess) ) {
         // Close down the current connection to force a restart
         upcheckCloseConnection();
      } else {
         // Use current connection
         ucc=_upcheckCurrentConnection;
      }
   }

   if( idleNotify ) {
      // Only notify user of updates when idle
      ucc.postedCb=__upcheckUpdateCheckIdleNotifyCB;
   } else {
      ucc.postedCb=__upcheckUpdateCheckDisplayCB;
   }

   if( ucc.hprocess>=0 ) {
      // Already have a connection, so just get the updates
      _upcheckEnQ(UPCHECK_QE_MANIFEST,UPCHECK_QS_BEGIN,0,&ucc);
   } else {
      // Start the connection
      _upcheckEnQ(UPCHECK_QE_START,UPCHECK_QS_BEGIN,0,&ucc);
   }

   if( idleNotify ) {
      // Everything happens on the timer callback from here, so
      // we are done.
      return;
   }

   // If we got here, then we are performing an immediate update
   // check and displaying updates to user. All we have to do
   // is push the events through the queue in "real time" until
   // there are no more events to process. Error handling and
   // displaying the updates is taken care of by the callback.
   dummy := false;
   int formWid = show("_upcheckProgress_form");
   captionLabel := formWid._find_control("ctl_caption");
   gaugeWid := formWid._find_control("ctl_gauge");
   cancelButton := formWid._find_control("ctl_cancel");
   captionLabel.p_caption="Checking for updates.";
   while( _upcheckQ._length()>0 ) {
      int event = _upcheckQ[0].event;
      int state = _upcheckQ[0].state;
      switch( event ) {
      case UPCHECK_QE_START:
         gaugeWid.p_value=25;
         break;
      case UPCHECK_QE_VERSION:
         gaugeWid.p_value=50;
         break;
      case UPCHECK_QE_MANIFEST:
         if( state==UPCHECK_QS_END ) {
            // Things move too fast to wait for a 100% gauge on UPCHECK_QS_END,
            // so do it here when the user will have a chance to see the
            // guage at 100%
            gaugeWid.p_value=100;
         } else {
            gaugeWid.p_value=75;
         }
         break;
      case UPCHECK_QE_END:
         gaugeWid.p_value=100;
         break;
      }
      _upcheckQTimerCallback();
      process_events(dummy);
      if( cancelButton.p_user ) {
         // User cancelled
         break;
      }
      delay(1);
   }
   formWid._delete_window();
   // All done
}

/**
 * Get/set the last update fetch time.
 */
double _upcheckLastFetch(double fetchTime=null)
{
   if( fetchTime!=null && fetchTime>=0 ) {
      // Set it
      _upcheck_last_fetch = fetchTime;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
   return _upcheck_last_fetch;
}

/**
 * Bump last fetch time to now.
 */
static void _upcheckRemindLater()
{
   _upcheckLastFetch(_upcheckTime());
}

/**
 * If there are non-ignored updates in the manifest file, then
 * notify the user.
 * 
 * @param filename Manifest filename. If null, attempt to user user
 *                 manifest stored in user configuration directory.
 */
void upcheckNotifyUpdates(_str filename=null)
{
   if( filename==null ) {
      // Use manifest.xml in configuration directory
      filename=_upcheckUserManifestFilename();
   }

   // does the file even exist?
   alertOn := false;
   if( file_exists(filename) ) {

      // do we have any updates?
      upcheckUpdate_t list[]; list._makeempty();
      int status = _upcheckGetRelevantUpdates(filename,list,status);
      if( !status ) {

         // Get list of non-ignored updates
         upcheckUpdate_t not_ignored[] = list;
         _upcheckFilterUpdatesOnStatus(not_ignored,"ignored");
         _upcheckFilterUpdatesOnStatus(not_ignored,"installed");
         _upcheckFilterUpdatesOnStatus(not_ignored,"expired");
         if( not_ignored._length() > 0 ) {
            alertOn = true;
         }
      }
   }

   // do we turn the alert on or off?
   if( alertOn ) {
      _ActivateAlert(ALERT_GRP_UPDATE_ALERTS, ALERT_VERSION_UPDATES_FOUND, 
                     'Version updates are available for SlickEdit.  To see them now, click <a href="<<cmd upcheckDisplayUpdates 'filename'">here</a>.',
                     'Updates Available');
   } else {
      _UnregisterAlert(ALERT_GRP_UPDATE_ALERTS);
//    _ClearLastAlert(ALERT_GRP_UPDATE_ALERTS, ALERT_VERSION_UPDATES_FOUND);
   }

}

void upcheckDisplayUpdates(_str filename, upcheckUpdate_t (&list)[]=null)
{
   if( list==null && !file_exists(filename) ) {
      // Nothing to do!
      return;
   }

   handle := -1;
   if( list==null ) {
      int status;
      handle = _upcheckGetRelevantUpdates(filename,list,status,false);
      if( status ) {
         return;
      }
   }
   // Filter out those updates that user should never see
   _upcheckFilterUpdatesOnStatus(list,"installed");
   _upcheckFilterUpdatesOnStatus(list,"expired");
   if( list._length()<1 ) {
      // Nothing to display, so tell the user
      msg := "No new updates available.";
      _message_box(msg,"",MB_OK|MB_ICONINFORMATION);
      return;
   }

   // Guarantee that no timer events can run while our modal dialog
   // displayed.
   wasRunning := _upcheckQKillTimer();
   _str result = show("-modal -mdi _upcheck_form",list);
   if( wasRunning ) _upcheckQSmartStartTimer();

   _upcheckRemindLater();

   if( result==0 ) {
      // The updated list is passed back in _param1 global variable
      list=_param1;
      if( handle>=0 ) {
         // If an update is marked as 'show once', now's the time to set it to 'ignored'
         // so that it never gets shown again
         _upcheckIgnoreShowOnceUpdates(list);

         // Write the updated Update nodes out to user manifest file
         int i;
         for( i=0; i<list._length();++i ) {
            int node = list[i].node;
            _xmlcfg_set_attribute(handle,node,"DisplayName",list[i].DisplayName);
            _xmlcfg_set_attribute(handle,node,"PackageName",list[i].PackageName);
            _xmlcfg_set_attribute(handle,node,"Type",list[i].Type);
            _xmlcfg_set_attribute(handle,node,"Version",list[i].Version);
            _xmlcfg_set_attribute(handle,node,"Summary",list[i].Summary);
            _xmlcfg_set_attribute(handle,node,"Description",list[i].Description);
            _xmlcfg_set_attribute(handle,node,"Options",list[i].Options);
            _xmlcfg_set_attribute(handle,node,"RemindTime",list[i].RemindTime);
            _xmlcfg_set_attribute(handle,node,"Status",list[i].Status);
            _xmlcfg_set_attribute(handle,node,"TimeStamp",list[i].TimeStamp);
         }
         int status = _xmlcfg_save(handle,4,0,_upcheckUserManifestFilename());
         _xmlcfg_close(handle);
         if( status ) {
            _str msg = get_message(VSRC_UPCHECK_ERROR_SAVING_MANIFEST,_upcheckUserManifestFilename());
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         }
      }
   }
}

void upcheckOptions()
{
   wasRunning := _upcheckQKillTimer();
   show('-modal _upcheckOptions_form');
   if( wasRunning ) _upcheckQSmartStartTimer();
}

static void _upcheckOnIdle()
{
   // Check for interval timeout and
   // MDI frame not hidden (e.g. background searching, vsdiff running).
   if( _upcheckTimedOut(_upcheck_last_fetch,def_upcheck_fetch_interval) &&
       _default_option(VSOPTION_MDI_SHOW_WINDOW_FLAGS)!=SW_HIDE ) {
      // It has been more than def_upcheck_fetch_interval milliseconds
      // since the last update fetch, so time to fetch for new updates.
      //upcheckDebug('_upcheckOnIdle: checking at '_time('M'));
      upcheckUpdateCheck(true);
   }
}

void _upcheckQTimerCallback()
{
   upcheckDebug('_upcheckQTimerCallback: in at '_time('M'));

   upcheckQEvent_t event;

   if( _upcheckQ._length()<1 ) {
      if( _upcheckGetIdleCheck() ) {
         _upcheckOnIdle();
         if( _upcheckQ._length()<1 ) {
            return;
         }
      } else {
         return;
      }
   }

   event=_upcheckQ[0];   // Make a copy
   _upcheckDeQ();

   upcheckDebug('_upcheckQTimerCallback: event/state = '_upcheckQEvent2Name(event.event)'/'_upcheckQState2Name(event.state));

   switch( event.event ) {
   case UPCHECK_QE_START:
      _upcheckQEHandler_Start(&event);
      break;
   case UPCHECK_QE_VERSION:
      _upcheckQEHandler_Version(&event);
      break;
   case UPCHECK_QE_MANIFEST:
      _upcheckQEHandler_Manifest(&event);
      break;
   case UPCHECK_QE_QUIT:
      _upcheckQEHandler_Quit(&event);
      break;
   case UPCHECK_QE_END:
      _upcheckQEHandler_End(&event);
      break;
   case UPCHECK_QE_ONIDLE:
      // No handler for the idle event, so just fall through
      // to post callback processing.
      break;
   default:
      // Should never get here
      msg :=  "Unknown update checker queue event : ":+event.event;
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return;
   }

   // Start/stop/restart the timer
   _upcheckQSmartStartTimer();

   if( event.ucc.postedCb ) {
      // Call posted callback
      if( _upcheckQ._length()<1 ) {
         // We are idle, so call any callback functions
         (*event.ucc.postedCb)(&event);
      }
   }

   return;
}

/**
 * A pointer to this function is assigned to pfnupcheckQTimerCallback so that
 * we can tell when the timer callback is for the slow timer interval or
 * not.
 */
void _upcheckQSlowTimerCallback()
{
   _upcheckQTimerCallback();

   return;
}

/**
 * There are 2 cases this function handles:<br>
 * <ol>
 *   <li>If there are no queued events, then start the timer with the
 *       slow interval.
 *   <li>If there are queued events, then start thee timer with the
 *       fast interval.
 * </ol>
 */
static void _upcheckQSmartStartTimer()
{
   events := false;
   if( _upcheckQ._length()>0 ) {
      events=true;
   }

   if( events ) {
      // Need fast interval
      slow := (pfnupcheckQTimerCallback!=_upcheckQTimerCallback);
      if( slow || _upcheckQTimer<0 ) {
         // Reallocate the timer with the fast interval
         _upcheckQKillTimer();
         pfnupcheckQTimerCallback=_upcheckQTimerCallback;
         _upcheckQTimer=_set_timer(UPCHECKQTIMER_INTERVAL,pfnupcheckQTimerCallback);
      }
   } else {
      // Need slow interval
      fast := (pfnupcheckQTimerCallback!=_upcheckQSlowTimerCallback);
      if( fast || _upcheckQTimer<0 ) {
         // Reallocate the timer with the slow interval
         _upcheckQKillTimer();
         pfnupcheckQTimerCallback=_upcheckQSlowTimerCallback;
         _upcheckQTimer=_set_timer(UPCHECKQTIMER_SLOW_INTERVAL,pfnupcheckQTimerCallback);
      }
   }

   return;
}

/**
 * Kill the upcheck Q timer.
 * 
 * @return true if the timer was running before being killed,
 * false otherwise.
 */
static bool _upcheckQKillTimer()
{
   wasRunning := (_upcheckQTimer>=0);
   if (wasRunning) {
      _kill_timer(_upcheckQTimer);
   }
   _upcheckQTimer= -2;   // -1 is for the get_event() timer
   pfnupcheckQTimerCallback=null;

   return wasRunning;
}


static _str UPCHECK_COMMAND() {
   return (_isUnix()?"SlickEditUpdateMgr":"SlickEditUpdateMgr.exe");
}

static const UPCHECK_UPDATEBASE= "update.slickedit.com/updates/";

static _str _upcheckCmdline()
{
   _str msg;
   _str cmdline;

   if( _upcheckPath=="" ) {
      path := get_env("VSLICKBIN1");
      if (path:=='') {
         //get_env("VSLICKBIN1") seems to fail periodically on the Mac
         //maybe this will be more reliable
         path=editor_name('P');
      }
      _maybe_append_filesep(path);
      path :+= UPCHECK_COMMAND();
      if( file_match('-p '_maybe_quote_filename(path),1)=="" ) {
         msg=get_message(VSRC_UPCHECK_NOT_FOUND,path);
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         return "";
      }
      _upcheckPath=path;
   }
   cmdline=_maybe_quote_filename(_upcheckPath);
   _str proxy = _UrlGetProxy("http");
   if( proxy!="" ) {
      browser := "";
      if( pos(';',proxy) ) parse proxy with browser ';' proxy;
      if( browser=="" ) {
         // No browser-specific setting ("IE;"), so check for proxy
         if( proxy!="" ) {
            // Break it down and check for stupid settings
            _str host, port;
            parse proxy with host':'port;
            if( host!="" && isinteger(port) && port>0 ) {
               cmdline :+= ' -proxy 'host':'port;
            }
         }
      }
   } else {
      if (_isWindows()) {
         cmdline :+= ' -noproxy';
      }
   }

   _str updatebase = UPCHECK_UPDATEBASE;
   if( updatebase!="" ) {
      cmdline :+= ' -updatebase 'updatebase;
   }

   return(cmdline);
}

static int _upcheckCommand(_str line, upcheckConnection_t* ucc_p)
{
   if( !ucc_p || ucc_p->hprocess<0 || ucc_p->hout<0 ) {
      return ERROR_WRITING_FILE_RC;
   }

   upcheckLog(ucc_p,line);

   _maybe_append(line, "\n");
   status := _PipeWrite(ucc_p->hout,line);
   return status;
}

/**
 * Read off whole lines of output from the output pipe of the upcheck
 * connection.
 */
static int _upcheckReadResponse(upcheckConnection_t* ucc_p, _str& response)
{
   int hin = ucc_p->hin;
   status := _PipeReadLine(response,hin);
   if( !status ) {
      response=strip(response,'T');
      upcheckLog(ucc_p,response);
   }
   return status;
}

static void _upcheckParseResponse(_str response, int& status, _str& msg)
{
   _str code;

   parse response with code msg;
   if( lowcase(code)=="+ok" ) {
      status=0;
   } else {
      // Error code or unrecognized response
      status=VSRC_UPCHECK_INVALID_RESPONSE;
      if( substr(code,1,1)=='-' && isinteger(code) ) {
         // It is one of ours
         status= (int)code;
      }
      msg=get_message(status);
   }
}

static const UPCHECK_LOG_BUFNAME= ".upchecklog";

/**
 * Right now, there is only 1 upcheck log allowed, so this
 * function simply returns the name.
 */
static _str _upcheckMkLogName()
{
   return(UPCHECK_LOG_BUFNAME);
}

static _str _upcheckCreateLogBuffer()
{
   status := 0;

   log_buf_name := _upcheckMkLogName();
   if( log_buf_name=="" ) {
      msg :=  "UPCHECK: "get_message(VSRC_UPCHECK_ERROR_CREATING_LOG);
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return("");
   }

   int temp_view_id;
   int orig_view_id = _find_or_create_temp_view(temp_view_id,'',log_buf_name);
   //p_readonly_mode=true;
   p_window_id=orig_view_id;

   return(log_buf_name);
}

static void _upcheckDeleteLogBuffer(upcheckConnection_t *ucc_p)
{
   _str log_buf_name = UPCHECK_LOG_BUFNAME;
   if( log_buf_name=="" ) return;
   _find_and_delete_temp_view(log_buf_name);
   return;
}

void upcheckLog(upcheckConnection_t *ucc_p, _str buf, bool saveLog=false)
{
   _str log_buf_name = UPCHECK_LOG_BUFNAME;
   orig_view_id := p_window_id;
   if( find_view(log_buf_name)!=0 ) {
      // Try to create it
      log_buf_name=_upcheckCreateLogBuffer();
      if( log_buf_name=="" ) {
         // Error
         p_window_id=orig_view_id;
         return;
      }
      if( find_view(log_buf_name)!=0 ) {
         // Should never happen
         p_window_id=orig_view_id;
         return;
      }
      insert_line("*** Log started on ":+_date():+" at ":+_time('M'));
   }

   // Make sure we log the response on a line of its own
   bottom();
   if( _line_length()!=0 ) {
      insert_line('');
   }
   if( _upcheckdebug&UPCHECK_DEBUGFLAG_TIME_STAMP ) {
      _str temp = buf;
      while( temp!="" ) {
         _str line;
         parse temp with line '\r\n','r' temp;
         _insert_text(_time('M'):+" ":+line);
         if( temp!="" ) {
            insert_line('');
         }
      }
   } else {
      _insert_text(buf);
   }
   if( saveLog || _upcheckdebug&UPCHECK_DEBUGFLAG_SAVE_LOG ) {
      temp_path := _temp_path();
      _maybe_append_filesep(temp_path);
      log_filename :=  temp_path:+p_buf_name;
      _save_file('+o '_maybe_quote_filename(log_filename));
   }
   p_window_id=orig_view_id;
}

/**
 * Closes current upcheck.exe connection.
 */
void upcheckCloseConnection()
{
   if( !_upcheckCurrentConnection._isempty() ) {
      if( _upcheckQ._length()>0 ) {
         // Inject an ABORT state into the queue so the current event
         // can handle things gracefully if necessary.
         _upcheckQ[0].state=UPCHECK_QS_ABORT;
         // Suppress idle-check-restart of queue
         old_IdleCheck := _upcheckSetIdleCheck(false);
         // Cycle the queue
         _upcheckQTimerCallback();
         _upcheckSetIdleCheck(old_IdleCheck);
      }
      // Force a graceful QUIT of the upchecker utility
      _upcheckEnQ(UPCHECK_QE_QUIT,UPCHECK_QS_BEGIN,0,&_upcheckCurrentConnection);
      // It should take no more than a few iterations
      int i;
      for( i=0;i<3;++i ) {
         delay(1);
         // Suppress idle-check-restart of queue
         old_IdleCheck := _upcheckSetIdleCheck(false);
         // Cycle the queue
         _upcheckQTimerCallback();
         _upcheckSetIdleCheck(old_IdleCheck);
      }
   }
   _upcheckCurrentConnection._makeempty();

   return;
}

static bool gUpcheckIdleCheck = true;
/**
 * Set idle-check for _upcheckQTimerCallback and return old value.
 */
static bool _upcheckSetIdleCheck(bool value)
{
   old_value := gUpcheckIdleCheck;
   gUpcheckIdleCheck=value;
   return old_value;
}
static bool _upcheckGetIdleCheck()
{
   return gUpcheckIdleCheck;
}

/**
 * Called automatically when the editor exits. Closes current upcheck.exe
 * connection.
 *
 * @return 0
 */
int _exit_upcheck()
{
   upcheckCloseConnection();

   return(0);
}

static void _upcheckQEHandler_Start(upcheckQEvent_t *e_p)
{
   upcheckQEvent_t event;

   event= *e_p;   // Make a copy

   // Start a connection to upcheck.exe
   switch( event.state ) {
   case UPCHECK_QS_BEGIN: {
      // Event begins
      _str cmdline = _upcheckCmdline();
      event.ucc.hprocess= -1;
      int hprocess = _PipeProcess(cmdline,event.ucc.hin,event.ucc.hout,event.ucc.herr,"");
      if( hprocess<0 ) {
         _str msg = get_message(VSRC_UPCHECK_ERROR_STARTING)"  ."get_message(hprocess);
         _upcheckEnQ(event.event,UPCHECK_QS_ERROR,0,&event.ucc,msg);
         return;
      }

      event.ucc.hprocess=hprocess;
      _upcheckEnQ(event.event,UPCHECK_QS_END,0,&event.ucc);
      return;
      break;
   }
   case UPCHECK_QS_ERROR:
      // An error occurred starting connection to upcheck.exe, so clean up
      upcheckLog(&event.ucc,event.info[0]);
      //_message_box(event.info[0],"",MB_OK|MB_ICONEXCLAMATION);
      return;
      break;
   case UPCHECK_QS_ABORT:
      // Event aborted
      return;
      break;
   case UPCHECK_QS_END:
      // Event ends
      break;
   default:
      // Should never get here
      msg :=  "Unknown update checker queue event state: ":+event.state:+" for event ":+event.event;
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      break;
   }

   return;
}

static void _upcheckQEHandler_Version(upcheckQEvent_t *e_p)
{
   upcheckQEvent_t event;

   event= *e_p;   // Make a copy

   // Get update checker version and validate
   switch( event.state ) {
   case UPCHECK_QS_BEGIN: {
      // Event begins
      _upcheckCommand("VERSION",&event.ucc);
      _upcheckEnQ(event.event,UPCHECK_QS_WAITING_FOR_REPLY,0,&event.ucc);
      return;
      break;
   }
   case UPCHECK_QS_WAITING_FOR_REPLY: {
      _str line;
      int status;
      status=_upcheckReadResponse(&event.ucc,line);
      if( status ) {
         msg :=  "VERSION: "get_message(status);
         _upcheckEnQ(event.event,UPCHECK_QS_ERROR,0,&event.ucc,msg);
         return;
      }
      if( line=="" ) {
         // Check for timeout
         if( _timedOut(event.start,UPCHECK_TIMEOUT) ) {
            msg :=  "VERSION: "get_message(VSRC_UPCHECK_TIMED_OUT);
            _upcheckEnQ(event.event,UPCHECK_QS_ERROR,0,&event.ucc,msg);
            return;
         }
         // No response yet, so re-queue
         _upcheckReQ(event.event,event.state,event.start,&event.ucc);
         return;
      }
      // If we got here, then we have a response
      _str version;
      _upcheckParseResponse(line,status,version);
      if( status ) {
         // Error
         msg :=  "VERSION: "version;
         _upcheckEnQ(event.event,UPCHECK_QS_ERROR,0,&event.ucc,msg);
         return;
      }
      _str major, minor, revision, build;
      parse version with major'.'minor'.'revision'.'build;
      if( major!=UPC_VER_MAJOR || minor!=UPC_VER_MINOR ) {
         msg :=  "VERSION: "get_message(VSRC_UPCHECK_VERSION_NOT_SUPPORTED,version);
         _upcheckEnQ(event.event,UPCHECK_QS_ERROR,0,&event.ucc,msg);
         return;
      }
      // Good version, we are done
      _upcheckEnQ(event.event,UPCHECK_QS_END,0,&event.ucc);
      return;
      break;
   }
   case UPCHECK_QS_ERROR:
      // An error occurred getting the version, so clean up
      upcheckLog(&event.ucc,event.info[0]);
      //_message_box(event.info[0],"",MB_OK|MB_ICONEXCLAMATION);
      return;
      break;
   case UPCHECK_QS_ABORT:
      // Event aborted
      return;
      break;
   case UPCHECK_QS_END:
      // Event ends
      break;
   default:
      // Should never get here
      msg :=  "Unknown update checker queue event state: ":+event.state:+" for event ":+event.event;
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      break;
   }

   return;
}

static const UPCHECK_MANIFEST_DOCTYPE_TAG= "Manifest";
static const UPCHECK_MANIFEST_DTD_PATH= "http://www.slickedit.com/dtd/vse/upcheck/1.0/manifest.dtd";
static const UPCHECK_MANIFEST_VERSION= "1.0";

static int _upcheckxmlCreateManifest(_str filename="")
{
   h := -1;
   status := 0;

   do {

      h = _xmlcfg_create(filename,VSENCODING_UTF8);
      if( h<0 ) {
         status=h;
         break;
      }

      // <?xml version="1.0"?>
      int decl_node = _xmlcfg_add(h,TREE_ROOT_INDEX,"xml",VSXMLCFG_NODE_XML_DECLARATION,VSXMLCFG_ADD_AS_CHILD);
      if( decl_node<0 ) {
         status=decl_node;
         break;
      }
      _xmlcfg_set_attribute(h,decl_node,"version","1.0");

      // <!DOCTYPE Manifest SYSTEM "manifest.dtd">
      int doctype_node = _xmlcfg_add(h,TREE_ROOT_INDEX,"DOCTYPE",VSXMLCFG_NODE_DOCTYPE,VSXMLCFG_ADD_AS_CHILD);
      if( doctype_node<0 ) {
         status=doctype_node;
         break;
      }
      _xmlcfg_set_attribute(h,doctype_node,"root",UPCHECK_MANIFEST_DOCTYPE_TAG);
      _xmlcfg_set_attribute(h,doctype_node,"SYSTEM",UPCHECK_MANIFEST_DTD_PATH);

      // <Manifest Version="1.0"> ... </Manifest>
      int manifest_node = _xmlcfg_add(h,TREE_ROOT_INDEX,"Manifest",VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
      if( manifest_node<0 ) {
         status=manifest_node;
         break;
      }
      _xmlcfg_set_attribute(h,manifest_node,"Version",UPCHECK_MANIFEST_VERSION);

   } while( false );

   if( status ) {
      if( h>=0 ) _xmlcfg_close(h);
      upcheckError("Error creating manifest. "get_message(status));
      return status;
   }
   return h;
}

static bool _upcheckUpdateIsValidAttribute_Type(_str& value, bool fix=false)
{
   return (value=="message");
}

static bool _upcheckUpdateIsValidAttribute_TimeStamp(_str& value, bool fix=false)
{
   if( isinteger(value) && value>=0 ) {
      return true;
   }
   // Not valid
   if( fix ) {
      value="0";
      return true;
   }
   return false;
}

static bool _upcheckUpdateIsValidAttribute_PackageName(_str& value, bool fix=false)
{
   return (value!=null && value!="");
}

static bool _upcheckUpdateIsValidAttribute_DisplayName(_str& value, bool fix=false)
{
   return (value!=null && value!="");
}

static bool _upcheckUpdateIsValidAttribute_Description(_str& value, bool fix=false)
{
   return (value!=null && value!="");
}

static bool _upcheckUpdateIsValidAttribute_Summary(_str& value, bool fix=false)
{
   return (value!=null && value!="");
}

static bool _upcheckUpdateIsValidAttribute_Version(_str& value, bool fix=false)
{
   _str productId, version;
   _upcheckGetProductInfo(productId,version);
   _str valueMajor, valueMinor, valueRevision, valueBuild;
   // Wildcard * means any version matches
   if (value :== "*") {
      return true;
   }
   parse value with valueMajor'.'valueMinor'.' valueRevision'.'valueBuild'.' .;
   if( valueRevision == "" ) {
      valueRevision="0";
   }
   if( valueBuild == "" ) {
      valueBuild="0";
   }
   _str major, minor, revision, build;
   parse version with major'.'minor'.'revision'.'build'.' .;
   if( revision == "" ) {
      revision="0";
   }
   if( build == "" ) {
      build="0";
   }

   // We did not have an update manager before version 9.0
   if( !isinteger(valueMajor) || valueMajor<9 ) {
      return false;
   }
   if( !isinteger(valueMinor) || valueMinor<0 ) {
      return false;
   }

   return true;
}

static bool _upcheckUpdateIsValidAttribute_Options(_str& value, bool fix=false)
{
   if( value!=null ) {
      return true;
   }
   if( fix ) {
      value="";
      return true;
   }
   return false;
}

static bool _upcheckUpdateIsValidAttribute_Status(_str& value, bool fix=false)
{
   if( value=="ignored" || value=="installed" || value=="none" || value=="expired" ) {
      return true;
   }
   if( fix ) {
      value="none";
      return true;
   }
   return false;
}

static bool _upcheckUpdateIsValidAttribute_RemindTime(_str& value, bool fix=false)
{
   if( isinteger(value) && value>=0 ) {
      return true;
   }
   if( fix ) {
      value="0";
      return true;
   }
   return false;
}

/**
 * Validate Update attribute.
 * 
 * <p>
 * Note:<br>
 * Calling this function with value=null and fix=true and ht!=null is a
 * nice and quick way to populate a hash table with valid values.
 * </p>
 * 
 * @param name     Name of attribute.
 * @param value    (output). Value of attribute. If null, and ht!=null, then
 *                 value will be retrieved from hash table.
 * @param fix      If set to true, and the attribute value is not valid,
 *                 then the the value will be fix'ed. If ht!=null, then
 *                 the value in the hash table will also be fix'ed.
 *                 in which case true will be the return value, except for
 *                 those attribute values that cannot be fixed.
 * @param ht       (output). Hash table of attributes and values. This can
 *                 be null if setValid=false AND a non-null value is specified.
 * 
 * @return true if valid, false if not valid.
 */
static bool _upcheckUpdateValidateAttribute(_str name, _str& value=null,
                                               bool fix=false,
                                               bool& modified=null,
                                               _str (&ht):[]=null)
{
   if( value==null && ht!=null && ht._indexin(name) ) {
      value=ht:[name];
   }
   if( modified!=null ) {
      modified=false;
   }
   valid := false;
   _str old_value = value;
   switch( name ) {
   case "Type":
      valid=_upcheckUpdateIsValidAttribute_Type(value,fix);
      break;
   case "TimeStamp":
      valid=_upcheckUpdateIsValidAttribute_TimeStamp(value,fix);
      break;
   case "DisplayName":
      valid=_upcheckUpdateIsValidAttribute_DisplayName(value,fix);
      break;
   case "PackageName":
      valid=_upcheckUpdateIsValidAttribute_PackageName(value,fix);
      break;
   case "Version":
      valid=_upcheckUpdateIsValidAttribute_Version(value,fix);
      break;
   case "Summary":
      valid=_upcheckUpdateIsValidAttribute_Summary(value,fix);
      break;
   case "Description":
      valid=_upcheckUpdateIsValidAttribute_Description(value,fix);
      break;
   case "Options":
      valid=_upcheckUpdateIsValidAttribute_Options(value,fix);
      break;
   case "Status":
      valid=_upcheckUpdateIsValidAttribute_Status(value,fix);
      break;
   case "RemindTime":
      valid=_upcheckUpdateIsValidAttribute_RemindTime(value,fix);
      break;
   }
   // Check to see if we fix'ed an invalid value. If so, then we need to
   // update the hash table (if not null of course).
   if( old_value!=value ) {
      if( modified!=null ) {
         modified=true;
      }
      if( ht!=null && valid ) {
         ht:[name]=value;
      }
   }

   return valid;
}

/**
 * Validate Update attributes in hash table ht.
 * 
 * @param ht     (output). Hash table of attributes to validate.
 * @param fix    true=Fix invalid attribute values (if possible).
 * @param modified (output). Set to true if any attributes were modified in
 *                 order to successfully validate.
 * 
 * @return true if valid, false if not valid.
 */
static bool _upcheckValidateUpdate(_str (&ht):[], bool fix, bool& modified)
{
   _str name;
   bool modifiedAttribute;

   modifiedUpdate := false;
   modified=false;

   name="Type";
   if( !_upcheckUpdateValidateAttribute(name,null,fix,modifiedAttribute,ht) ) {
      upcheckDebug("_upcheckValidateUpdate: Invalid attribute: "name);
      return false;
   }
   modifiedUpdate = modifiedUpdate || modifiedAttribute;

   name="TimeStamp";
   if( !_upcheckUpdateValidateAttribute(name,null,fix,modifiedAttribute,ht) ) {
      upcheckDebug("_upcheckValidateUpdate: Invalid attribute: "name);
      return false;
   }
   modifiedUpdate = modifiedUpdate || modifiedAttribute;

   name="DisplayName";
   if( !_upcheckUpdateValidateAttribute(name,null,fix,modifiedAttribute,ht) ) {
      upcheckDebug("_upcheckValidateUpdate: Invalid attribute: "name);
      return false;
   }
   modifiedUpdate = modifiedUpdate || modifiedAttribute;

   name="PackageName";
   if( !_upcheckUpdateValidateAttribute(name,null,fix,modifiedAttribute,ht) ) {
      upcheckDebug("_upcheckValidateUpdate: Invalid attribute: "name);
      return false;
   }
   modifiedUpdate = modifiedUpdate || modifiedAttribute;

   name="Version";
   if( !_upcheckUpdateValidateAttribute(name,null,fix,modifiedAttribute,ht) ) {
      upcheckDebug("_upcheckValidateUpdate: Invalid attribute: "name);
      return false;
   }
   modifiedUpdate = modifiedUpdate || modifiedAttribute;

   name="Summary";
   if( !_upcheckUpdateValidateAttribute(name,null,fix,modifiedAttribute,ht) ) {
      upcheckDebug("_upcheckValidateUpdate: Invalid attribute: "name);
      return false;
   }
   modifiedUpdate = modifiedUpdate || modifiedAttribute;

   name="Description";
   if( !_upcheckUpdateValidateAttribute(name,null,fix,modifiedAttribute,ht) ) {
      upcheckDebug("_upcheckValidateUpdate: Invalid attribute: "name);
      return false;
   }
   modifiedUpdate = modifiedUpdate || modifiedAttribute;

   name="Options";
   if( !_upcheckUpdateValidateAttribute(name,null,fix,modifiedAttribute,ht) ) {
      upcheckDebug("_upcheckValidateUpdate: Invalid attribute: "name);
      return false;
   }
   modifiedUpdate = modifiedUpdate || modifiedAttribute;

   name="Status";
   if( !_upcheckUpdateValidateAttribute(name,null,fix,modifiedAttribute,ht) ) {
      upcheckDebug("_upcheckValidateUpdate: Invalid attribute: "name);
      return false;
   }
   modifiedUpdate = modifiedUpdate || modifiedAttribute;

   name="RemindTime";
   if( !_upcheckUpdateValidateAttribute(name,null,fix,modifiedAttribute,ht) ) {
      upcheckDebug("_upcheckValidateUpdate: Invalid attribute: "name);
      return false;
   }

   // All good
   upcheckDebug("_upcheckValidateUpdate: All attributes valid");
   modified=modifiedUpdate;
   return true;
}

/**
 * Retrieve all attributes from Update node into hash table and validate
 * the attributes.
 * 
 * @param handle
 * @param node
 * @param ht       (output). Hash table of attributes.
 * @param fix      true=Fix invalid attribute values (if possible).
 * @param modified (output). Set to true if any attributes were modified in
 *                 order to successfully validate. Note that the node is NOT
 *                 fixed, only the attributes in the hash table are fixed.
 * 
 * @return true if valid, false if not valid.
 */
static bool _upcheckxmlGetAndValidateUpdate(int handle, int node, _str (&ht):[], bool fix, bool& modified)
{
   int status = _xmlcfg_get_attribute_ht(handle,node,ht);
   if( status ) {
      upcheckError("UPDATE VALIDATE: Invalid Update node in manifest. "get_message(status));
      return false;
   }

   upcheckDebug("_upcheckxmlGetAndValidateUpdate: Checking Update attributes for file: "_xmlcfg_get_filename(handle)", node="node);
   valid := _upcheckValidateUpdate(ht,fix,modified);
   return valid;
}

/**
 * Reconcile single Update node of a manifest source into destination manifest.
 * 
 * @param hsrc       Handle to source manifest file.
 * @param srcnode    Source Update node.
 * @param hdst       Handle to destination manifest file to receive reconciled node.
 * @param matchFound (output). Set to true if Update match found in destination.
 * @param dstnodes[] (optional). Array of Update nodes to match on. This
 *                   is MUCH faster if you are calling this function repeatedly
 *                   to merge one manifest file into another. Otherwise, the
 *                   array has to be generated each time this function is called,
 *                   which is less efficient.
 * 
 * @return 0 on success, <0 on error.
 */
static int _upcheckxmlReconcileUpdate(int hsrc, int srcnode,
                                      int hdst,
                                      bool& matchFound,
                                      typeless dstnodes[]=null)
{
   status := 0;

   OUTER:
   do {

      if( dstnodes==null ) {
         // Build array of destination Update nodes that exist under
         // UpdateSet parent that has exact same attributes as the
         // source Update's parent UpdateSet node.
         int parent = _xmlcfg_get_parent(hsrc,srcnode);
         if( parent<0 ) {
            status=parent;
            break;
         }
         xpath_UpdateSet := "";
         status = _xmlcfg_get_xpath_from_node(hsrc,parent,xpath_UpdateSet);
         if( status ) {
            break;
         }
         status=_xmlcfg_find_simple_array(hdst,"/Manifest"xpath_UpdateSet"/Update",dstnodes);
         if( status ) {
            break;
         }
      }

      _str srcHt:[]; srcHt._makeempty();
      bool modified;
      if( !_upcheckxmlGetAndValidateUpdate(hsrc,srcnode,srcHt,true,modified) ) {
         upcheckError("UPDATE RECONCILE: Invalid Update in source manifest");
         break;
      }

      // IMPORTANT:
      // 1. As of 12.0 the Version attribute of an Update node SHOULD be the exact product version that is being targeted by the Update (e.g. 12.0.1.1, NOT 12.0).
      // You should no longer set Version=12.0 to match a product of 12.0.1 or 12.0.2, etc.
      // This is clearer to the user when being displayed the list of Updates available because
      // it will reference the exact version (e.g. 12.0.1.0) that is available.
      //
      // Exceptions to this rule occur when we give user non-version-specific notices. For example, when we
      // want to inform the user that they need to register to get their maintenance upgrade download. The
      // version we would use in this case would probably be "12.0" instead of the exact version they are using.
      // This (hopefully) tells the user that the notice is a general notice for all v12.0 users.
      //
      // 2. Multiple Update nodes with the same PackageName. DON'T DO IT. The last Update node with same PackageName in a source manifest will win,
      // and only the first Update node in the destination manifest being reconciled will ever be overwritten.
      // Example: reconciling a source manifest (from the update server) with a destination manifest (installed product), assuming all else being equal, installed product version=12.0.0.0
      // Source manifest:
      // ...
      // <Update
      //     Version="12.0.1.2"
      //     PackageName="latest_version" />
      // <Update
      //     Version="12.0.1.1"
      //     PackageName="latest_version" />
      // <Update
      //     Version="12.0.1.0"
      //     PackageName="latest_version" />
      // ...
      //
      // Destination manifest (before reconciliation):
      // ...
      // <Update
      //     Version="12.0.0.1"
      //     PackageName="latest_version" />
      // ...
      //
      // Resulting/reconciled manifest:
      // ...
      // <Update
      //     Version="12.0.1.0"
      //     PackageName="latest_version" />
      // ...
      //
      // Notice that the resulting/reconciled manifest (this is what the user ends up seeing) only contains the "12.0.1.0" Update. This is probably NOT what
      // we intended. What happened was that the last Update node (Version="12.0.1.0") overwrote the destination Update node with matching PackageName="latest_version".
      // NEVER create multiple Update nodes (under the same UpdateSet) with the same PackageName value. You are asking for trouble. The latest cumulative update/patch
      // should replace the current update/patch by simply changing the value of the Version attribute (and updating Description, TimeStamp, etc.). This way, the user's current
      // "latest_version" Update node gets replaced by the newer one. Here is how the source manifest should evolve over the course of an update/patch cycle:
      //
      // New product version is 12.0.0.0
      // (no updates)
      //
      // 12.0.1.0 patch is released
      // ...
      // <Update
      //     Version="12.0.1.0"
      //     PackageName="latest_version" />
      // ...
      //
      // 12.0.1.1 patch is released
      // ...
      // <Update
      //     Version="12.0.1.1"
      //     PackageName="latest_version" />
      // ...
      //
      // 12.0.2.0 patch is released
      // ...
      // <Update
      //     Version="12.0.2.0"
      //     PackageName="latest_version" />
      // ...
      //
      // and so on.
      found := false;
      dstnode := -1;
      int i;
      for( i=0;i<dstnodes._length();++i ) {
         dstnode = dstnodes[i];
         _str dstPackageName = _xmlcfg_get_attribute(hdst,dstnode,"PackageName","");
         //if( srcHt:["PackageName"]!=dstPackageName ) continue;
         if ( !_upcheckMatchWithWildcard(srcHt:["PackageName"],dstPackageName) ) {
            continue;
         }
         found=true;
         break;
      }
      _str dstHt:[]; dstHt._makeempty();
      if( found ) {

         if( !_upcheckxmlGetAndValidateUpdate(hdst,dstnode,dstHt,true,modified) ) {
            upcheckWarn("UPDATE RECONCILE: Invalid Update in destination manifest [PackageName="srcHt:["PackageName"]". Replaced");

            // Replace with the source Update
            dstHt=srcHt;

         } else {

            // Merge the source and destination Update

            // Type
            dstHt:["Type"]        = srcHt:["Type"];
            // TimeStamp
            dstHt:["TimeStamp"]   = srcHt:["TimeStamp"];
            // DisplayName
            dstHt:["DisplayName"] = srcHt:["DisplayName"];
            // PackageName
            dstHt:["PackageName"] = srcHt:["PackageName"];
            // Version
            dstHt:["Version"]     = srcHt:["Version"];
            // Summary
            dstHt:["Summary"]     = srcHt:["Summary"];
            // Description
            dstHt:["Description"] = srcHt:["Description"];
            // Status, RemindTime are user-defined, so leave them alone
            // if set to something other than the default.
            if( srcHt:["Status"]!="none" && dstHt:["Status"]=="none" ) {
               // Source Status trumps "none"
               dstHt:["Status"]=srcHt:["Status"];
            } else if( srcHt:["Status"]=="expired" ) {
               // Source Status="expired" trumps
               dstHt:["Status"]=srcHt:["Status"];
            } else if( srcHt:["Status"]!="expired" && dstHt:["Status"]=="expired" ) {
               // Source Status trumps "expired"
               dstHt:["Status"]=srcHt:["Status"];
            }
            if( srcHt:["RemindTime"]!="" && dstHt:["RemindTime"]=="" ) {
               dstHt:["RemindTime"]=srcHt:["RemindTime"];
            }
            if( _upcheckIsOption("-notice", srcHt:["Options"]) ) {
               _str srcNoticeID = _upcheckOptionParam("-notice", srcHt:["Options"]);
               _str dstNoticeID = _upcheckOptionParam("-notice", dstHt:["Options"]);
               if ( srcNoticeID != dstNoticeID) {
                  dstHt:["Status"] = "none";
               }
            }
            // Options
            dstHt:["Options"]     = srcHt:["Options"];
         }
      } else {
         // Not found, so insert it
         if( dstnodes._length()>0 ) {
            // Insert as sibling of last Update node
            int sib_node = dstnodes[dstnodes._length()-1];
            dstnode = _xmlcfg_add(hdst,sib_node,"Update",VSXMLCFG_NODE_ELEMENT_START_END,0);
         } else {
            // There are no destination Update nodes, so insert it as first
            // node under the destination UpdateSet parent that has exact same
            // attributes as the source Update's parent UpdateSet node.
            int parent = _xmlcfg_get_parent(hsrc,srcnode);
            if( parent<0 ) {
               status=parent;
               break;
            }
            xpath_UpdateSet := "";
            status = _xmlcfg_get_xpath_from_node(hsrc,parent,xpath_UpdateSet);
            if( status ) {
               break;
            }
            int UpdateSet_node = _xmlcfg_find_simple(hdst,"/Manifest"xpath_UpdateSet);
            if( UpdateSet_node<0 ) {
               status=UpdateSet_node;
               upcheckDebug("_upcheckxmlReconcileUpdate: Error finding UpdateSet node. "get_message(status));
               break;
            }
            dstnode = _xmlcfg_add(hdst,UpdateSet_node,"Update",VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
         }
         dstHt=srcHt;
      }
      matchFound=found;

      // Set destination Update attributes
      typeless attr_name;
      attr_name._makeempty();
      for( ;; ) {
         dstHt._nextel(attr_name);
         if( attr_name._isempty() ) break;
         _str attr_val = dstHt:[attr_name];
         _xmlcfg_set_attribute(hdst,dstnode,attr_name,attr_val);
      }

   } while( false );

   return status;
}

/**
 * Reconcile all Update nodes of a single UpdateSet from a manifest source
 * into a destination manifest.
 * 
 * @param hsrc       Handle to source manifest file.
 * @param srcnode    Source UpdateSet node.
 * @param hdst       Handle to destination manifest file to receive reconciled Update nodes.
 * @param dstnode    Destination UpdateSet node.
 * 
 * @return 0 on success, <0 on error.
 */
static int _upcheckxmlReconcileUpdates(int hsrc, int srcnode, int hdst, int dstnode)
{
   status := 0;

   OUTER:
   do {

      // Get Update nodes for source
      typeless hsrc_Update_nodes[]; hsrc_Update_nodes._makeempty();
      status=_xmlcfg_find_simple_array(hsrc,"Update",hsrc_Update_nodes,srcnode);
      if( status ) {
         break;
      }
      upcheckDebug("_upcheckxmlReconcileUpdates: "_xmlcfg_get_filename(hsrc)": found "hsrc_Update_nodes._length()" source Update nodes");

      // Get Update nodes for destination
      typeless hdst_Update_nodes[]; hdst_Update_nodes._makeempty();
      status=_xmlcfg_find_simple_array(hdst,"Update",hdst_Update_nodes,dstnode);
      if( status ) {
         break;
      }
      upcheckDebug("_upcheckxmlReconcileUpdates: found "hdst_Update_nodes._length()" destination Update nodes");

      // Reconcile source Update nodes into destination UpdateSet
      int i;
      for( i=0;i<hsrc_Update_nodes._length();++i ) {
         int node = hsrc_Update_nodes[i];
         bool found;
         status = _upcheckxmlReconcileUpdate(hsrc,node,hdst,found,hdst_Update_nodes);
         if( status ) {
            break OUTER;
         }
      }

   } while( false );

   return status;
}

static bool _upcheckUpdateSetIsValidAttribute_ProductId(_str& value, bool fix=false)
{
   return (value=="vse" || value=="ep" || value=="stu" || value=="*");
}

static bool _upcheckUpdateSetIsValidAttribute_PlatformId(_str& value, bool fix=false)
{
   return (value=="win32" || value=="win64" || value=="unix" || value=="all" ||
           value=="rs" || value=="linux32" || value=="linux64" || value=="hp" ||
           value=="sg" || value=="solsp" || value=="solx86" ||
           value=="macos" || value=="mac" ||
           value=="*");
}

static bool _upcheckUpdateSetIsValidAttribute_ForProductVersion(_str& value, bool fix=false)
{
   return (value!=null && value!="");
}

static bool _upcheckUpdateSetIsValidAttribute_SetName(_str& value, bool fix=false)
{
   if( value!=null ) {
      return true;
   }
   if( fix ) {
      value="";
      return true;
   }
   return false;
}

/**
 * Validate UpdateSet attribute.
 * 
 * @param name     Name of attribute.
 * @param value    (output). Value of attribute. If null, and ht!=null, then
 *                 value will be retrieved from hash table.
 * @param fix      If set to true, and the attribute value is not valid,
 *                 then the the value will be fix'ed. If ht!=null, then
 *                 the value in the hash table will also be fix'ed.
 *                 in which case true will be the return value, except for
 *                 those attribute values that cannot be fixed.
 * @param ht       (output). Hash table of attributes and values. This can
 *                 be null if setValid=false AND a non-null value is specified.
 * 
 * @return true if valid, false if not valid.
 */
static bool _upcheckUpdateSetValidateAttribute(_str name, _str& value=null,
                                                  bool fix=false,
                                                  bool& modified=null,
                                                  _str (&ht):[]=null)
{
   if( value==null && ht!=null && ht._indexin(name) ) {
      value=ht:[name];
   }
   if( modified!=null ) {
      modified=false;
   }
   valid := false;
   _str old_value = value;
   switch( name ) {
   case "ProductId":
      valid=_upcheckUpdateSetIsValidAttribute_ProductId(value,fix);
      break;
   case "PlatformId":
      valid=_upcheckUpdateSetIsValidAttribute_PlatformId(value,fix);
      break;
   case "ForProductVersion":
      valid=_upcheckUpdateSetIsValidAttribute_ForProductVersion(value,fix);
      break;
   case "SetName":
      valid=_upcheckUpdateSetIsValidAttribute_SetName(value,fix);
      break;
   }
   // Check to see if we fix'ed an invalid value. If so, then we need to
   // update the hash table (if not null of course).
   if( old_value!=value ) {
      if( modified!=null ) {
         modified=true;
      }
      if( ht!=null && valid ) {
         ht:[name]=value;
      }
   }

   return valid;
}

/**
 * Validate UpdateSet attributes in hash table ht.
 * 
 * @param ht     (output). Hash table of attributes to validate.
 * @param fix    true=Fix invalid attribute values (if possible).
 * @param modified (output). Set to true if any attributes were modified in
 *                 order to successfully validate.
 * 
 * @return true if valid, false if not valid.
 */
static bool _upcheckValidateUpdateSet(_str (&ht):[], bool fix, bool& modified)
{
   _str name;
   bool modifiedAttribute;

   modifiedUpdate := false;
   modified=false;

   name="ProductId";
   if( !_upcheckUpdateSetValidateAttribute(name,null,fix,modifiedAttribute,ht) ) {
      upcheckDebug("_upcheckValidateUpdateSet: Invalid attribute: "name);
      return false;
   }
   modifiedUpdate = modifiedUpdate || modifiedAttribute;

   name="PlatformId";
   if( !_upcheckUpdateSetValidateAttribute(name,null,fix,modifiedAttribute,ht) ) {
      upcheckDebug("_upcheckValidateUpdateSet: Invalid attribute: "name);
      return false;
   }
   modifiedUpdate = modifiedUpdate || modifiedAttribute;

   name="ForProductVersion";
   if( !_upcheckUpdateSetValidateAttribute(name,null,fix,modifiedAttribute,ht) ) {
      upcheckDebug("_upcheckValidateUpdateSet: Invalid attribute: "name);
      return false;
   }
   modifiedUpdate = modifiedUpdate || modifiedAttribute;

   name="SetName";
   if( !_upcheckUpdateSetValidateAttribute(name,null,fix,modifiedAttribute,ht) ) {
      upcheckDebug("_upcheckValidateUpdateSet: Invalid attribute: "name);
      return false;
   }
   modifiedUpdate = modifiedUpdate || modifiedAttribute;

   // All good
   upcheckDebug("_upcheckValidateUpdateSet: All attributes valid");
   modified=modifiedUpdate;
   return true;
}

/**
 * Retrieve all attributes from UpdateSet node into hash table and validate
 * the attributes.
 * 
 * @param handle
 * @param node
 * @param ht       (output). Hash table of attributes.
 * @param fix      true=Fix invalid attribute values (if possible).
 * @param modified (output). Set to true if any attributes were modified in
 *                 order to successfully validate. Note that the node is NOT
 *                 fixed, only the attributes in the hash table are fixed.
 * 
 * @return true if valid, false if not valid.
 */
static bool _upcheckxmlGetAndValidateUpdateSet(int handle, int node,
                                                  _str (&ht):[],
                                                  bool fix, bool& modified)
{
   int status = _xmlcfg_get_attribute_ht(handle,node,ht);
   if( status ) {
      upcheckError("UPDATESET VALIDATE: Invalid UpdateSet node in manifest. "get_message(status));
      return false;
   }

   upcheckDebug("_upcheckxmlGetAndValidateUpdateSet: Checking UpdateSet attributes for file: "_xmlcfg_get_filename(handle)", node="node);
   valid := _upcheckValidateUpdateSet(ht,fix,modified);
   return valid;
}

/**
 * Reconcile single UpdateSet node of a manifest source into destination manifest.
 * 
 * @param hsrc       Handle to source manifest file.
 * @param srcnode    Source UpdateSet node.
 * @param hdst       Handle to destination manifest file to receive reconciled node.
 * @param matchFound (output). Set to true if UpdateSet match found in destination.
 * @param dstnodes[] (optional). Array of UpdateSet nodes to match on. This
 *                   is MUCH faster if you are calling this function repeatedly
 *                   to merge one manifest file into another. Otherwise, the
 *                   array has to be generated each time this function is called,
 *                   which is less efficient.
 * 
 * @return 0 on success, <0 on error.
 */
static int _upcheckxmlReconcileUpdateSet(int hsrc, int srcnode,
                                         int hdst,
                                         bool& matchFound,
                                         typeless dstnodes[]=null)
{
   status := 0;

   do {

      if( dstnodes==null ) {
         status=_xmlcfg_find_simple_array(hdst,"/Manifest/UpdateSet",dstnodes);
         if( status ) {
            break;
         }
      }
      _str srcPlatformId = _xmlcfg_get_attribute(hsrc,srcnode,"PlatformId","");
      _str srcProductId = _xmlcfg_get_attribute(hsrc,srcnode,"ProductId","");
      _str srcForProductVersion = _xmlcfg_get_attribute(hsrc,srcnode,"ForProductVersion","");
      _str srcSetName = _xmlcfg_get_attribute(hsrc,srcnode,"SetName","");
      found := false;
      int i;
      for( i=0;i<dstnodes._length();++i ) {
         int dstnode = dstnodes[i];
         _str dstPlatformId = _xmlcfg_get_attribute(hdst,dstnode,"PlatformId","");
         //if( srcPlatformId!=dstPlatformId ) continue;
         if ( !_upcheckMatchWithWildcard(srcPlatformId,dstPlatformId) ) continue;
         _str dstProductId = _xmlcfg_get_attribute(hdst,dstnode,"ProductId","");
         //if( srcProductId!=dstProductId ) continue;
         if ( !_upcheckMatchWithWildcard(srcProductId,dstProductId) ) continue;
         _str dstForProductVersion = _xmlcfg_get_attribute(hdst,dstnode,"ForProductVersion","");
         //if( srcForProductVersion!=dstForProductVersion ) continue;
         if ( !_upcheckVersionsMatch(srcForProductVersion,dstForProductVersion) ) continue;
         _str dstSetName = _xmlcfg_get_attribute(hdst,dstnode,"SetName","");
         if( srcSetName!=dstSetName ) continue;
         // If we got here, then we have a match
         found=true;
         break;
      }
      if( found ) {
         status=_upcheckxmlReconcileUpdates(hsrc,srcnode,hdst,dstnodes[i]);
         if( status ) {
            break;
         }
      } else {
         // Not found, so insert it
         int dstnode;
         if( dstnodes._length()>0 ) {
            // Insert as sibling of last UpdateSet node
            int sib_node = dstnodes[dstnodes._length()-1];
            dstnode = _xmlcfg_add(hdst,sib_node,"UpdateSet",VSXMLCFG_NODE_ELEMENT_START,0);
         } else {
            // There are no destination UpdateSet nodes, so insert it as first node under /Manifest
            int Manifest_node = _xmlcfg_find_simple(hdst,"/Manifest");
            if( Manifest_node<0 ) {
               status=Manifest_node;
               upcheckDebug("_upcheckxmlReconcileUpdateSet: Error finding Manifest node. "get_message(status));
               break;
            }
            dstnode = _xmlcfg_add(hdst,Manifest_node,"UpdateSet",VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
         }
         _xmlcfg_set_attribute(hdst,dstnode,"PlatformId",srcPlatformId);
         _xmlcfg_set_attribute(hdst,dstnode,"ProductId",srcProductId);
         _xmlcfg_set_attribute(hdst,dstnode,"ForProductVersion",srcForProductVersion);
         _xmlcfg_set_attribute(hdst,dstnode,"SetName",srcSetName);
         status=_upcheckxmlReconcileUpdates(hsrc,srcnode,hdst,dstnode);
         if( status ) {
            // Delete the new node
            _xmlcfg_delete(hdst,dstnode);
            break;
         }
      }
      matchFound=found;

   } while( false );

   return status;
}

/**
 * Reconcile XML manifests represented by XMLCFG source handles, h1 and h2,
 * and return a handle to the reconciled XML file.
 * 
 * <p>
 * Note: Caller is responsible for closing source handles.
 * 
 * @param hsrc1
 * @param hsrc2
 * 
 * @return Reconciled XML file handle. <0 on error.
 */
static int _upcheckxmlReconcileManifests(int hsrc1, int hsrc2)
{
   status := 0;
   hdst := -1;

   OUTER:
   do {

      hdst = _upcheckxmlCreateManifest();
      if( hdst<0 ) {
         status=hdst;
         break;
      }
      int Manifest_node = _xmlcfg_find_simple(hdst,"/Manifest");
      if( Manifest_node<0 ) {
         status=Manifest_node;
         break;
      }

      ReconcileSrc1 := false;

      // Validate Manifest version for first source
      int src1_Manifest_node = _xmlcfg_find_simple(hsrc1,"/Manifest");
      if( src1_Manifest_node>=0 ) {
         _str src1_Version = _xmlcfg_get_attribute(hsrc1,src1_Manifest_node,"Version");
         if( src1_Version==UPCHECK_MANIFEST_VERSION ) {
            ReconcileSrc1=true;
         }
      }

      if( ReconcileSrc1 ) {
         // Copy first source manifest's UpdateSet nodes into the destination
         typeless hsrc1_UpdateSet_nodes[]; hsrc1_UpdateSet_nodes._makeempty();
         status=_xmlcfg_find_simple_array(hsrc1,"/Manifest/UpdateSet",hsrc1_UpdateSet_nodes);
         if( status ) {
            upcheckWarn("MANIFEST RECONCILE: Error finding UpdateSet nodes in source [1] manifest file. "get_message(status));
            hsrc1_UpdateSet_nodes._makeempty();
            status=0;
         }
         upcheckDebug("_upcheckxmlReconcileManifests: copying "hsrc1_UpdateSet_nodes._length()" source UpdateSet nodes to destination");
         int i;
         for( i=0;i<hsrc1_UpdateSet_nodes._length();++i ) {
            int node = hsrc1_UpdateSet_nodes[i];
            // Validate the node before inserting
            _str ht:[];
            bool modified;
            if( _upcheckxmlGetAndValidateUpdateSet(hsrc1,node,ht,true,modified) ) {
               if( modified ) {
                  // Attributes were modified in order for this node to successfully
                  // validate, so fix the node.
                  typeless attr_name;
                  attr_name._makeempty();
                  for( ;; ) {
                     ht._nextel(attr_name);
                     if( attr_name._isempty() ) break;
                     _str attr_val = ht:[attr_name];
                     _xmlcfg_set_attribute(hsrc1,node,attr_name,attr_val);
                  }
               }
               status=_xmlcfg_copy(hdst,Manifest_node,hsrc1,node,VSXMLCFG_COPY_AS_CHILD);
               if( status>0 || status==VSRC_XMLCFG_NO_CHILDREN_COPIED ) {
                  status=0;
               }
               if( status<0 ) {
                  upcheckWarn("MANIFEST RECONCILE: Invalid UpdateSet node in source [1] manifest file. "get_message(status));
               }
            } else {
               upcheckWarn("MANIFEST RECONCILE: Invalid UpdateSet node in source [1] manifest file. "get_message(status));
            }
         }
      }
      status=0;

      // Get UpdateSet nodes for destination
      typeless hdst_UpdateSet_nodes[]; hdst_UpdateSet_nodes._makeempty();
      status=_xmlcfg_find_simple_array(hdst,"/Manifest/UpdateSet",hdst_UpdateSet_nodes);
      if( status ) {
         break;
      }

      ReconcileSrc2 := false;

      // Validate Manifest version for second source
      int src2_Manifest_node = _xmlcfg_find_simple(hsrc2,"/Manifest");
      if( src2_Manifest_node>=0 ) {
         _str src2_Version = _xmlcfg_get_attribute(hsrc2,src2_Manifest_node,"Version");
         if( src2_Version==UPCHECK_MANIFEST_VERSION ) {
            ReconcileSrc2=true;
         }
      }

      if( ReconcileSrc2 ) {
         // Merge second source manifest's UpdateSet nodes into the destination
         typeless hsrc2_UpdateSet_nodes[]; hsrc2_UpdateSet_nodes._makeempty();
         status=_xmlcfg_find_simple_array(hsrc2,"/Manifest/UpdateSet",hsrc2_UpdateSet_nodes);
         if( status ) {
            upcheckWarn("MANIFEST RECONCILE: Error finding UpdateSet nodes in source [2] manifest file. "get_message(status));
            hsrc2_UpdateSet_nodes._makeempty();
            status=0;
         }
         int i;
         for( i=0;i<hsrc2_UpdateSet_nodes._length();++i ) {
            int node = hsrc2_UpdateSet_nodes[i];
            found := false;
            status=_upcheckxmlReconcileUpdateSet(hsrc2,node,hdst,found,hdst_UpdateSet_nodes);
            if( status ) {
               break OUTER;
            }
         }
      }

   } while( false );

   // Clean up
   if( status ) {
      if( hdst>=0 ) {
         _xmlcfg_close(hdst);
      }
      return status;
   }
   return hdst;
}

/**
 * Reconcile XML source manifest files, srcFile1 and srcFile2, and return a handle
 * to the destination reconciled XML file.
 * 
 * @param file1
 * @param file2
 * 
 * @return Reconciled XML file handle. <0 on error.
 */
int _upcheckxmlReconcileManifestFiles(_str srcFile1, _str srcFile2)
{
   status := 0;
   hsrc1 := -1;
   hsrc2 := -1;
   hdst := -1;

   do {

      hsrc1 = _xmlcfg_open(srcFile1,status);
      if( hsrc1<0 ) {
         status=hsrc1;
         break;
      }
      hsrc2 = _xmlcfg_open(srcFile2,status);
      if( hsrc2<0 ) {
         status=hsrc2;
         break;
      }
      hdst = _upcheckxmlReconcileManifests(hsrc1,hsrc2);
      if( hdst<0 ) {
         status=hdst;
         break;
      }

   } while( false );

   // Clean up
   if( hsrc1>=0 ) {
      _xmlcfg_close(hsrc1);
   }
   if( hsrc2>=0 ) {
      _xmlcfg_close(hsrc2);
   }

   if( status ) {
      if( hdst>=0 ) {
         _xmlcfg_close(hdst);
      }
      upcheckError("MANIFEST RECONCILE: "get_message(status));
      return status;
   }
   return hdst;
}

static _str _upcheckUserManifestFilename()
{
   filename := _ConfigPath();
   _maybe_append_filesep(filename);
   filename :+= "manifest.xml";
   return filename;
}

/**
 * Reconcile updates from filename into user manifest file.
 * 
 * @param filename
 * 
 * @return 0 on success, <0 on error.
 */
static int _upcheckReconcileToUserManifest(_str filename)
{
   status := 0;
   h := -1;

   do {
      
      if( !file_exists(filename) ) {
         return 0;
      }
      _str userManifestFilename = _upcheckUserManifestFilename();
      if( !file_exists(userManifestFilename) ) {
         // Create it
         upcheckInfo("Creating user manifest file: '"userManifestFilename"'");
         h = _upcheckxmlCreateManifest(userManifestFilename);
         if( h<0 ) {
            status=h;
            upcheckError("Failed to create user manifest file. "get_message(status));
            break;
         }
         status=_xmlcfg_save(h,4,0);
         if( status ) {
            upcheckError("Error saving manifest file. "get_message(status));
            break;
         }
         _xmlcfg_close(h);
         h= -1;
      }
      upcheckInfo("Reconciling '"userManifestFilename"' with '"filename"'");
      h=_upcheckxmlReconcileManifestFiles(userManifestFilename,filename);
      if( h<0 ) {
         status=h;
         upcheckError("Error reconciling manifests. "get_message(status));
         break;
      }
      status=_xmlcfg_save(h,4,0,userManifestFilename);
      if( status ) {
         upcheckError("Error saving manifest file. "get_message(status));
         break;
      }
      _xmlcfg_close(h);
      h= -1;

      // Success
      status=0;

   } while( false );

   // Clean up
   if( h>=0 ) {
      _xmlcfg_close(h);
   }

   return status;
}

static bool _upcheckIsOption(_str option,_str list)
{
   present := false;
   _str param;

   if( option!="" ) {
      option=lowcase(option);
      while( list!="" ) {
         _str o;
         parse list with o list;
         parse o with o"="param;
         if( option==lowcase(o) ) {
            present=true;
            break;
         }
      }
   }

   return present;
}

static _str _upcheckOptionParam(_str option, _str list)
{
   param := "";

   if( option!="" ) {
      option=lowcase(option);
      while( list!="" ) {
         _str o;
         parse list with o list;
         parse o with o"="param;
         if( option==lowcase(o) ) {
            break;
         }
      }
   }

   return param;
}

/**
 * Makes a version that might only include major, or only major+minor, include all
 * four of: major, minor, revision, build. For example, "9"
 * would become 9.0.0.0, "10.0" becomes "10.0.0.0", "9.0.1"
 * becomes "9.0.1.0", "12.0.1.1" remains "12.0.1.1".
 * 
 * @return A string that has major, minor, revision, and build
 *         numbers
 * 
 * @param version The input version string
 */
static _str _upcheckFixupVersion(_str version)
{
   _str major, minor, revision, build;
   parse version with major'.'minor'.'revision'.'build;
   if( minor :== "" ) {
      minor = "0";
   }
   if( revision :== "" ) {
      revision = "0";
   }
   if( build :== "" ) {
      build = "0";
   }
   newVersion :=  major'.'minor'.'revision'.'build;
   return newVersion;
}

/**
 * Given a handle to an open manifest.xml file, it will retrieve the UpdateSet(s) that
 * are relevant to this product. By "relevant", we mean matches productID, platformID,
 * and version, including wildcard '*'
 * 
 * @param h Handle to an open manifest.xml file
 * @param updateSetNodes Output array of xml nodes that will contain the relevant UpdateSets
 */
static int _upcheckGetRelevantUpdateSets(int h, int (&updateSetNodes)[])
{
   // Get the product information
   _str productID, forProductVersion;
   _upcheckGetProductInfo(productID, forProductVersion);
   _str platformID;
   _upcheckGetPlatformId(platformID);
   // Retrieve ALL the UpdateSets
   updateSetNodes._makeempty();
   xpath := "/Manifest/UpdateSet";
   int status;
   typeless nodes[];
   status = _xmlcfg_find_simple_array(h, xpath, nodes);
   if (status) {
      upcheckError("Problem getting UpdateSet nodes");
      return 1;
   }
   // Iterate through each UpdateSet and add each match to the output
   i := j := 0;
   _str attributes:[];
   upcheckDebug("PRODUCT: PlatformID: "platformID", ProductID: "productID", Version: "forProductVersion);
   for (i = 0; i < nodes._length(); i++) {
      if (_xmlcfg_get_attribute_ht(h, nodes[i], attributes)) {
         upcheckError("Problem getting attributes");
         return 1;
      }
      upcheckDebug("NODE: PlatformID: "attributes:['PlatformId']", ProductID: "attributes:['ProductId']", Version: "attributes:['ForProductVersion']);
      if (_upcheckMatchWithWildcard(attributes:['PlatformId'], platformID) &&
          _upcheckMatchWithWildcard(attributes:['ProductId'], productID) &&
          _upcheckVersionsMatch(attributes:['ForProductVersion'], forProductVersion)) {
         updateSetNodes[j] = nodes[i];
         j++;
      }
   }
   return 0;
}

/**
 * Pull updates that are relevant to this product, platform, version into
 * an array of upcheckUpdate_t.
 * 
 * @param filename Manifest file to pull updates from.
 * @param list     (output). Array of upcheckUpdate_t.
 * @param status   (output). Status of operations. You need to check this
 *                 AND the handle returned (if close=false).
 * @param handle   (output). If this is not null, then the manifest file
 *                 will be left open and passed back in this variable.
 * @param append   true=Append updates to list rather than clearing the list.
 * 
 * @return If close=false, then XMLCFG handle is returned. If close=true,
 * then status =0 on success, <0 on error. In all cases, <0 is returned
 * on error.
 */
static int _upcheckGetRelevantUpdates(_str filename, upcheckUpdate_t (&list)[],
                                      int& status,
                                      bool close=true, bool append=false)
{
   status = 0;

   if( !append ) {
      list._makeempty();
   }

   h := -1;

   OUTER:
   do {

      h = _xmlcfg_open(filename,status);
      if( h<0 ) {
         status=h;
         break;
      }

      _str ProductId, ForProductVersion;
      _upcheckGetProductInfo(ProductId,ForProductVersion);
      ForProductVersion = _upcheckFixupVersion(ForProductVersion);
      _str PlatformId;
      _upcheckGetPlatformId(PlatformId);
      UpdateSet_xpath :=  "/UpdateSet[@ProductId='"ProductId"'][@PlatformId='"PlatformId"'][@ForProductVersion='"ForProductVersion"']";
      int UpdateSet_nodes[]; UpdateSet_nodes._makeempty();
      //status=_xmlcfg_find_simple_array(h,"/Manifest"UpdateSet_xpath,UpdateSet_nodes);
      status = _upcheckGetRelevantUpdateSets(h, UpdateSet_nodes);
      if( status ) {
         upcheckWarn("GET RELEVANT UPDATES: Error retrieving UpdateSets. "get_message(status));
         break;
      }
      int i;
      for( i=0;i<UpdateSet_nodes._length();++i ) {
         typeless Update_nodes[]; Update_nodes._makeempty();
         status=_xmlcfg_find_simple_array(h,"Update",Update_nodes,UpdateSet_nodes[i]);
         if( status ) {
            break OUTER;
         }
         int j;
         for( j=0;j<Update_nodes._length();++j ) {
            _str ht:[]; ht._makeempty();
            bool modified;
            if( _upcheckxmlGetAndValidateUpdate(h,Update_nodes[j],ht,true,modified) ) {

               // Trial include/exclude options
               options :=  ht:["Options"];
               upcheckDebug("_upcheckGetRelevantUpdates: Options="options);
               if( _trial() && !_upcheckIsOption('-include-trial',options) ) {
                  // Trials not included for this update
                  upcheckDebug("_upcheckGetRelevantUpdates: ignoring non-trial update with PackageName="ht:["PackageName"]);
                  continue;
               } else if( !_trial() && _upcheckIsOption('-only-trial',options) ) {
                  // Only trials included for this update
                  upcheckDebug("_upcheckGetRelevantUpdates: ignoring trial update with PackageName="ht:["PackageName"]);
                  continue;
               }

               // Version
               upcheckDebug("_upcheckGetRelevantUpdates: Version="ht:["Version"]);
               _str unused, version;
               _upcheckGetProductInfo(unused,version);
               if( compareVSEVersions(ht:["Version"],version) < 0 ) {
                  // Version of Update in manifest is older than current product version
                  continue;
               }

               // Timestamp (e.g. build/state file)
               upcheckDebug("_upcheckGetRelevantUpdates: TimeStamp="ht:["TimeStamp"]);
               if( isinteger(ht:["TimeStamp"]) && ht:["TimeStamp"]>0 ) {
                  double TimeStamp = (double)ht:["TimeStamp"];
                  double build_date = _upcheckBuildDateToTimeStamp();
                  upcheckDebug("_upcheckGetRelevantUpdates: comparing TimeStamp="ht:["TimeStamp"]" with BuildDate="build_date);
                  if( TimeStamp<=build_date ) {
                     // The user already has this Update.
                     // OR
                     // Rare case of UpdateSet[ForProductVersion] = current product version
                     // AND Update[TimeStamp] < current build date, which means that the current
                     // version of the product is newer than this update, so do not include
                     // in list of relevant updates. This could happen during a beta as one
                     // example.
                     continue;
                  }
               }

               // We have a good update
               k := list._length();
               list[k].Description=ht:["Description"];
               list[k].DisplayName=ht:["DisplayName"];
               list[k].Options=ht:["Options"];
               list[k].PackageName=ht:["PackageName"];
               list[k].RemindTime=ht:["RemindTime"];
               list[k].Status=ht:["Status"];
               list[k].Summary=ht:["Summary"];
               list[k].TimeStamp=ht:["TimeStamp"];
               list[k].Type=ht:["Type"];
               list[k].Version=ht:["Version"];

               // This can only be used if a handle was passed in so that
               // we keep the manifest file open.
               list[k].node=Update_nodes[j];
            }
         }
      }

   } while( false );

   if( close ) {
      // Close manifest file and return status
      if( h>=0 ) {
         _xmlcfg_close(h);
      }
      return status;
   } else {
      // Leave the manifest file open and return handle,
      // unless there is an error.
      if( status ) {
         if( h>=0 ) {
            _xmlcfg_close(h);
         }
         return status;
      } else {
         // All good, so return the open handle
         return h;
      }
   }
}

/**
 * Filter for the "Status" attribute of updates in list.
 * 
 * @param list        Array of upcheckUpdate_t.
 * @param statusValue Status value to filter on.
 * @param remove      true=Delete all updates whose Status matches statusValue.
 *                    false=Delete all updates whose Status does NOT match statusValue.
 */
static void _upcheckFilterUpdatesOnStatus(upcheckUpdate_t (&list)[],
                                          _str statusValue, bool remove=true)
{
   int i;
   for( i=0;i<list._length();++i ) {
      if( remove && list[i].Status:==statusValue ) {
         list._deleteel(i);
         --i;
      } else if( !remove && list[i].Status:!=statusValue ) {
         list._deleteel(i);
         --i;
      }
   }
}

/**
 * Any update with an option "-once" has its Status set to ignored so that
 * it is never shown again.
 * 
 * @param list Array of upcheckUpdate_t
 */
static void _upcheckIgnoreShowOnceUpdates(upcheckUpdate_t (&list)[])
{
   int i;
   for( i=0;i<list._length();++i ) {
      if( _upcheckIsOption("-once",list[i].Options) || _upcheckIsOption("-notice",list[i].Options) ) {
         list[i].Status="ignored";
      }
   }
}

/**
 * Checks to see if two strings match, either by equality or by wildcard
 * 
 * @param stringA First string
 * @param stringB Second string
 */
static bool _upcheckMatchWithWildcard(_str stringA, _str stringB)
{
   if( stringA :== stringB || stringA :== "*" || stringB :== "*" ) {
      return true;
   }
   // No match
   return false;
}

/**
 * Parse a version string into major, minor, revision, and build
 * components. If any of those components is blank, fill it with
 * the wildcard "*'
 * 
 * @param version  Original version string
 * @param major    Holds the major component
 * @param minor    Holds the minor component
 * @param revision Holds the revision component
 * @param build    Holds the build component
 */
static void _upcheckFillWithWildcards(_str version, _str& major, _str& minor, _str& revision, _str& build)
{
   parse version with major'.'minor'.'revision'.'build;
   if( major :== "" ) {
      major = "*";
   }
   if( minor :== "" ) {
      minor = "*";
   }
   if( revision :== "" ) {
      revision = "*";
   }
   if( build :== "" ) {
      build = "*";
   }
}

/**
 * Checks to see if one version matches another, either by strict equality or by
 * the use of wildcards. This is NOT a good substitute for regex matching; it simply
 * allows a simpler syntax for purposes of creating manifest.xml files. For instance,
 * we can specify ForProductVersion="10.*" and it will match any of the 10-series
 * products, or "*" and it will match any version. No other wildcard is supported
 * nor is it possible to specify a '*' character anywhere other than between 
 * decimal points, e.g. "10*" is not allowed.
 * 
 * @param version1 The first version string
 * @param version2 The second version string
 */
static bool _upcheckVersionsMatch(_str version1, _str version2)
{
   _str major1, minor1, revision1, build1;
   _upcheckFillWithWildcards(version1,major1,minor1,revision1,build1);

   _str major2, minor2, revision2, build2;
   _upcheckFillWithWildcards(version2,major2,minor2,revision2,build2);

   majorMatch := _upcheckMatchWithWildcard(major1,major2);
   minorMatch := _upcheckMatchWithWildcard(minor1,minor2);
   revisionMatch := _upcheckMatchWithWildcard(revision1,revision2);
   buildMatch := _upcheckMatchWithWildcard(build1,build2);
   if( majorMatch && minorMatch && revisionMatch && buildMatch ) {
      return true;
   }
   // No match
   return false;
}

#if 0
_command void upcheck_test1()
{
   int h = _upcheckxmlReconcileManifestFiles('m:\manifest1.xml','m:\manifest2.xml');
   if( h>=0 ) {
      _xmlcfg_save(h,4,0,'m:\junk.xml');
      _xmlcfg_close(h);
   }
}

_command void upcheck_test2()
{
   upcheckUpdate_t list[]; list._makeempty();
   int status = _upcheckGetRelevantUpdates('m:\manifest1.xml',list,status);
   if( !status ) {
      int i;
      for( i=0;i<list._length();++i ) {
         fsay('***************************');
         fsay('Update #'(i+1));
         fsay('DisplayName='list[i].DisplayName);
         fsay('PackageName='list[i].PackageName);
         fsay('Type='list[i].Type);
         fsay('Version='list[i].Version);
         fsay('Summary='list[i].Summary);
         fsay('Description='list[i].Description);
         fsay('TimeStamp='list[i].TimeStamp);
         fsay('Options='list[i].Options);
         fsay('Status='list[i].Status);
         fsay('RemindTime='list[i].RemindTime);
      }
   }
}
_command void upcheck_test3()
{
   upcheckUpdate_t list[]; list._makeempty();
   int status = _upcheckGetRelevantUpdates('m:\manifest1.xml',list,status);
   if( !status ) {
      _upcheckFilterUpdatesOnStatus(list,"ignored");
      int i;
      for( i=0;i<list._length();++i ) {
         fsay('***************************');
         fsay('Update #'(i+1));
         fsay('DisplayName='list[i].DisplayName);
         fsay('PackageName='list[i].PackageName);
         fsay('Type='list[i].Type);
         fsay('Version='list[i].Version);
         fsay('Summary='list[i].Summary);
         fsay('Description='list[i].Description);
         fsay('TimeStamp='list[i].TimeStamp);
         fsay('Options='list[i].Options);
         fsay('Status='list[i].Status);
         fsay('RemindTime='list[i].RemindTime);
      }
   }
}
_command void upcheck_test4()
{
   upcheckDisplayUpdates(_upcheckUserManifestFilename());
}
_command void upcheck_test5()
{
   int build_date;
   _upcheckGetBuildDate(build_date);
   message('build_date='build_date);
}

_command void upcheck_testVersionsMatch(_str versions="")
{
   _str version1, version2;
   parse versions with version1" "version2;
   if (_upcheckVersionsMatch(version1, version2)) {
      say(version1" matches "version2);
   }
   else {
      say(version1" does NOT match "version2);
   }
}

_command void upcheck_testGetRelevantUpdateSets()
{
   fileName := "c:/development/vslick10/win/config/manifest.xml";
   int h, status;
   h = _xmlcfg_open(fileName, status);
   if (h < 0) {
      say("Problem opening xml file");
   }
   else {
      say("File opened successfully");
   }
   int updateSetNodes[];
   _upcheckGetRelevantUpdateSets(h, updateSetNodes);
   _xmlcfg_close(h);
}
#endif

static void _upcheckQEHandler_Manifest(upcheckQEvent_t *e_p)
{
   upcheckQEvent_t event;

   event= *e_p;   // Make a copy

   // Get manifest of updates available
   switch( event.state ) {
   case UPCHECK_QS_BEGIN: {
      // Event begins
      platform_id := "";
      product_id := "";
      product_version := "";
      serial := "";
      _upcheckGetPlatformId(platform_id);
      _upcheckGetProductInfo(product_id,product_version);
      _upcheckGetSerial(serial);
      _str temp_filename = mktemp();
      if( temp_filename=="" ) {
         // Uh oh
         _str msg = "MANIFEST: "get_message(VSRC_UPCHECK_ERROR_OPENING_OUTPUT_FILE,"<temp file>");
         _upcheckEnQ(event.event,UPCHECK_QS_ERROR,0,&event.ucc,msg);
         return;
      }
      _str cmdline = "MANIFEST "product_id" "serial" "product_version" "platform_id" "temp_filename;
      _upcheckCommand(cmdline,&event.ucc);
      // Stuff the temp_filename into the extra info of the connection so we
      // can get the contents on success.
      event.ucc.extra=temp_filename;
      _upcheckEnQ(event.event,UPCHECK_QS_WAITING_FOR_REPLY,0,&event.ucc);
      return;
      break;
   }
   case UPCHECK_QS_WAITING_FOR_REPLY: {
      _str line;
      int status;
      status=_upcheckReadResponse(&event.ucc,line);
      if( status ) {
         msg :=  "MANIFEST: "get_message(status);
         _upcheckEnQ(event.event,UPCHECK_QS_ERROR,0,&event.ucc,msg);
         return;
      }
      if( line=="" ) {
         // Check for timeout
         if( _timedOut(event.start,UPCHECK_TIMEOUT) ) {
            msg :=  "MANIFEST: "get_message(VSRC_UPCHECK_TIMED_OUT);
            _upcheckEnQ(event.event,UPCHECK_QS_ERROR,0,&event.ucc,msg);
            return;
         }
         // No response yet, so re-queue
         _upcheckReQ(event.event,event.state,event.start,&event.ucc);
         return;
      }
      // If we got here, then we have a response
      rest := "";
      _upcheckParseResponse(line,status,rest);
      if( status ) {
         // Error
         msg :=  "MANIFEST: "rest;
         _upcheckEnQ(event.event,UPCHECK_QS_ERROR,0,&event.ucc,msg);
         return;
      }
      // Good response, we are done
      _upcheckEnQ(event.event,UPCHECK_QS_END,0,&event.ucc);
      return;
      break;
   }
   case UPCHECK_QS_ERROR:
      // An error occurred getting the manifest, so clean up
      upcheckLog(&event.ucc,event.info[0]);
      if( !event.ucc.extra._isempty() && event.ucc.extra._varformat()==VF_LSTR ) {
         // Delete the temp_filename
         _str temp_filename = event.ucc.extra;
         delete_file(temp_filename);
      }
      //_message_box(event.info[0],"",MB_OK|MB_ICONEXCLAMATION);
      return;
      break;
   case UPCHECK_QS_ABORT:
      // Event aborted
      return;
      break;
   case UPCHECK_QS_END:
      // Event ends
      break;
   default:
      // Should never get here
      msg :=  "Unknown update checker queue event state: ":+event.state:+" for event ":+event.event;
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      break;
   }

   return;
}

static void _upcheckQEHandler_Quit(upcheckQEvent_t *e_p)
{
   upcheckQEvent_t event;

   event= *e_p;   // Make a copy

   // Quit connection to upcheck.exe
   switch( event.state ) {
   case UPCHECK_QS_BEGIN: {
      // Event begins
      _upcheckCommand("QUIT",&event.ucc);
      return;
      break;
   }
   case UPCHECK_QS_ERROR:
      // An error occurred quitting connection to upcheck.exe, so clean up
      //_message_box(event.info[0],"",MB_OK|MB_ICONEXCLAMATION);
      return;
      break;
   case UPCHECK_QS_ABORT:
      // Event aborted
      return;
      break;
   case UPCHECK_QS_END:
      // Event ends
      break;
   default:
      // Should never get here
      msg :=  "Unknown update checker queue event state: ":+event.state:+" for event ":+event.event;
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      break;
   }

   return;
}
static bool isStudioPlugin() {
   return false;
}

void _upcheckGetProductInfo(_str& productId, _str& version)
{
   _str line = get_message(SLICK_EDITOR_VERSION_RC);
   _str product;
   parse line with product 'Version' version .;
   productId="";
// 2/7/2004 - isStudioPlugin() has not been ported to 9.0 yet
   if( isStudioPlugin() ) {
      productId="stu";
   } else if( isEclipsePlugin() ) {
      productId="ep";
   } else {
      // SlickEdit
      productId="vse";
   }
}

static void _upcheckGetPlatformId(_str& platformId)
{
   _str mach = machine();
   if( mach=="WINDOWS" ) {
      platformId="win":+machine_bits();
   } else if( mach=="SPARCSOLARIS" ) {
      platformId="solsp";
   } else if( mach=="INTELSOLARIS" ) {
      platformId="solx86";
   } else if( mach=="RS6000" ) {
      platformId="rs";
   } else if( mach=="LINUX" ) {
      platformId="linux":+machine_bits();
   } else if( mach == "LINUXRPI4" ) {
      platformId = "linuxrpi4";
   } else if( mach=="SGMIPS" ) {
      platformId="sg";
   } else if( mach=="HP9000" ) {
      platformId="hp";
   } else if( mach=="MACOSX" ) {
      platformId="mac";
   } else {
      // Uh oh
   }
}

void _upcheckGetSerial(_str& serial)
{
   serial = _getSerial();
   //_str line = get_message(SERIAL_NUMBER_RC);
   //parse line with 'serial#' serial .;
}

static int MonthNumberTable:[] = {
   "January" => 1
   ,"February" => 2
   ,"March" => 3
   ,"April" => 4
   ,"May" => 5
   ,"June" => 6
   ,"July" => 7
   ,"August" => 8
   ,"September" => 9
   ,"October" => 10
   ,"November" => 11
   ,"December" => 12
};
static double _upcheckBuildDateToTimeStamp()
{
   buildDate := 0.0;
   line := _getProductBuildDate();
   _str month, day, year;
   parse line with month day ',' year;
   if( MonthNumberTable._indexin(month) ) {
      month=MonthNumberTable:[month];
      if( length(month)<2 ) {
         month='0'month;
      }
      if( length(day)<2 ) {
         day='0'day;
      }
      // Append '230000' for time part of timestamp. Since the product build date
      // does not have this, we use the 11'th hour in order to "guarantee" that an
      // applied update, which has the same date stamp as the update itself, will
      // cause the TimeStamp on the update to be earlier than the build date.
      // Example:
      // Update comes out with TimeStamp=20040215135500 (Feb 15, 2004 13:55:00)
      // The update applies a patch with Build Date=Feb 15, 2004
      // We do NOT want the user to be notified of the same update after it has
      // been applied, so set the time part of the build date returned to guarantee
      // that this cannot happen, so buildDate=20040215230000.
      line=year:+month:+day:+'230000';
      buildDate= (double)line;
   }
   return buildDate;
}

static void _upcheckQEHandler_End(upcheckQEvent_t *e_p)
{
   upcheckQEvent_t event;

   event= *e_p;   // Make a copy

   // End a connection to upcheck.exe
   switch( event.state ) {
   case UPCHECK_QS_BEGIN: {
      // Event begins
      int hprocess = event.ucc.hprocess;
      if( hprocess>=0 ) {
         if( !_PipeIsProcessExited(hprocess) ) {
            // Wait 0.1 seconds for the process to finish
            delay(10);
            if( !_PipeIsProcessExited(hprocess) ) {
               // Ah well, we tried...now terminate it
               _PipeTerminateProcess(hprocess);
            }
         }
         _PipeCloseProcess(hprocess);
      }
      // All done
      return;
      break;
   }
   case UPCHECK_QS_END:
      // Event ends
      break;
   default:
      // Should never get here
      msg :=  "Unknown update checker queue event state: ":+event.state:+" for event ":+event.event;
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      break;
   }

   return;
}

static _str _upcheckQEvent2Name(int e)
{
   switch( e ) {
   case UPCHECK_QE_START:
      return("UPCHECK_QE_START");
   case UPCHECK_QE_VERSION:
      return("UPCHECK_QE_VERSION");
   case UPCHECK_QE_MANIFEST:
      return("UPCHECK_QE_MANIFEST");
   case UPCHECK_QE_QUIT:
      return("UPCHECK_QE_QUIT");
   case UPCHECK_QE_END:
      return("UPCHECK_QE_END");
   case UPCHECK_QE_ONIDLE:
      return("UPCHECK_QE_ONIDLE");
   }

   return("UNKNOWN=":+e);
}

static _str _upcheckQState2Name(int s)
{
   switch( s ) {
   case UPCHECK_QS_BEGIN:
      return("UPCHECK_QS_BEGIN");
   case UPCHECK_QS_WAITING_FOR_REPLY:
      return("UPCHECK_QS_WAITING_FOR_REPLY");
   case UPCHECK_QS_ABORT:
      return("UPCHECK_QS_ABORT");
   case UPCHECK_QS_ERROR:
      return("UPCHECK_QS_ERROR");
   case UPCHECK_QS_END:
      return("UPCHECK_QS_END");
   }

   return("UNKNOWN=":+s);
}


// Used by all sizeable dialogs
static const UPCHECK_GAP_BORDER_X= 90;
// Used by tree controls with push buttons to compensate for gap on either
// side of caption.
static const UPCHECK_FUDGE_TREE_BUTTON_X= 200;

//////////////////////////////////////////////////////////////////////
// Begin Update Manager eventtable
//////////////////////////////////////////////////////////////////////

defeventtab _upcheck_form;

static void onCreate_ListAvailable(upcheckUpdate_t list[]);
static void onResize_ListAvailable();
static int onNext_ListAvailable(bool validate);
static int onFinish_ListAvailable(bool validate);

typedef void (*pfnOnCreate_tp)(upcheckUpdate_t list[]);
typedef void (*pfnOnResize_tp)();
typedef int (*pfnOnNext_tp)(bool);
typedef int (*pfnOnFinish_tp)(bool);

typedef struct {
   // Name of picture control slide
   _str name;
   // Window handle of picture control slide
   int wid;
   // Pointer to function to call when initializing slide
   pfnOnCreate_tp pfnOnCreate;
   // Pointer to function to call when resizing slide
   pfnOnResize_tp pfnOnResize;
   // Pointer to function to call when hitting "Next"
   // button (i.e. for validation of required fields,
   // etc.) on slide.
   pfnOnNext_tp pfnOnNext;
   // Pointer to function to call when hitting "Finish"
   // button (i.e. for validation of required fields,
   // etc.) on slide.
   pfnOnFinish_tp pfnOnFinish;
} slide_t;

static slide_t gSlides[] = {
   {'ctl_slide_ListAvailable', 0, onCreate_ListAvailable, onResize_ListAvailable, onNext_ListAvailable, onFinish_ListAvailable}
};

static int gCurrentSlide = 0;

void _upcheck_form.on_close()
{
   ctl_cancel.call_event(ctl_cancel,LBUTTON_UP,'W');

   return;
}

static void onCreate_ListAvailable(upcheckUpdate_t list[])
{
   p_active_form.p_caption = _getDialogApplicationName() :+ " - Updates";
   // Set up tree list
   ctl_update_list._TreeDelete(TREE_ROOT_INDEX,'C');
   // Create the grid
   // Pick sane values, but the column buttons will get resized
   // in the on_resize() event.
   int width;
   width = ctl_update_list._text_width("Name");
   ctl_update_list._TreeSetColButtonInfo(0,width+200,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,-1,"Name");
   width = ctl_update_list._text_width("Version");
   ctl_update_list._TreeSetColButtonInfo(1,width+200,0,-1,"Version");
   width = ctl_update_list._text_width("Status");
   ctl_update_list._TreeSetColButtonInfo(2,width+200,0,-1,"Status");

   // Populate list

   // Setting p_user=null guarantees we do not get on_change updates until we have a list
   ctl_update_list.p_user=null;

   if( list!=null ) {
      int i;
      for( i=0;i<list._length();++i ) {
         if( list[i].Status!="installed" ) {
            caption :=  list[i].DisplayName"\t"list[i].Version"\t"list[i].Status"\t"list[i].PackageName;
            ctl_update_list._TreeAddItem(TREE_ROOT_INDEX,caption,TREE_ADD_AS_CHILD,0,0,-1,TREENODE_BOLD);
         }
      }
   }
   ctl_update_list.p_user=list;
   ctl_update_list._TreeTop();
   ctl_update_list._TreeSelectLine(ctl_update_list._TreeCurIndex());
   ctl_update_list.call_event(CHANGE_OTHER,ctl_update_list,ON_CHANGE,'W');

   // These are not functional yet and would only confuse the user
   ctl_back.p_visible=false;
   ctl_next.p_visible=false;
}

static void onResize_ListAvailable()
{
   // All resizing done relative to picture control container
   int containerWidth = ctl_slide_ListAvailable.p_width;
   int containerHeight = ctl_slide_ListAvailable.p_height;

   // Preserve existing gaps
   //
   // Note: ctl_update_list.p_height is constant
   //
   // Preserve original gap between ctl_update_list and ctl_ignore_selected
   int vgap_update_list = ctl_ignore_selected.p_y - (ctl_update_list.p_y_extent);
   // Preserve original gap between ctl_ignore_selected and ctl_description_caption
   int vgap_ignore_selected = ctl_description_caption.p_y - (ctl_ignore_selected.p_y_extent);
   // Preserve original gap between ctl_description_caption and ctl_description
   int vgap_description_caption = ctl_description.p_y - (ctl_description_caption.p_y_extent);
   // Left-to-right gap between right edge of container and right edge of last control
   hgap_right := 90;
   // Top-to-bottom gap between bottom of container and bottom of last control
   vgap_bottom := 90;

   // ctl_update_list height is fixed, while ctl_description height is allowed to grow
   int descriptionHeight = containerHeight - ctl_update_list.p_y - ctl_update_list.p_height - vgap_update_list - ctl_ignore_selected.p_height - vgap_ignore_selected - ctl_description_caption.p_height - vgap_description_caption - vgap_bottom;

   // Re-position controls
   //
   // ctl_update_list
   ctl_update_list.p_x_extent = containerWidth - hgap_right;
   // ctl_ignore_selected
   ctl_ignore_selected.p_y = ctl_update_list.p_y_extent + vgap_update_list;
   // ctl_description_caption
   ctl_description_caption.p_y = ctl_ignore_selected.p_y_extent + vgap_ignore_selected;
   // ctl_description
   ctl_description.p_y = ctl_description_caption.p_y_extent + vgap_description_caption;
   ctl_description.p_width = ctl_update_list.p_width;
   ctl_description.p_height = descriptionHeight;

   // Resize column buttons in tree
   int wtree = ctl_update_list.p_width - 100 /*fudge*/;
   int wVersion = ctl_update_list._text_width("Version") + UPCHECK_FUDGE_TREE_BUTTON_X;
   // Use the longest status ("ignored") to initialize the width so we are guaranteed every status will fit
   int wStatus = ctl_update_list._text_width("ignored") + UPCHECK_FUDGE_TREE_BUTTON_X;
   int index;
   index=ctl_update_list._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while( index>=0 ) {
      caption := ctl_update_list._TreeGetCaption(index);
      _str Name, Version, Status;
      parse caption with Name"\t"Version"\t"Status"\t" .;
      int w;
      w=ctl_update_list._text_width(Version) + UPCHECK_FUDGE_TREE_BUTTON_X;
      if( w>wVersion ) {
         wVersion=w;
      }
      w=ctl_update_list._text_width(Status) + UPCHECK_FUDGE_TREE_BUTTON_X;
      if( w>wStatus ) {
         wStatus=w;
      }
      index=ctl_update_list._TreeGetNextSiblingIndex(index);
   }
   // Let the Name take up all remaining space
   int wName = wtree - wVersion - wStatus;

   ctl_update_list._TreeSetColButtonInfo(0,wName,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,-1,"Name");
   ctl_update_list._TreeSetColButtonInfo(1,wVersion,0,-1,"Version");
   ctl_update_list._TreeSetColButtonInfo(2,wStatus,0,-1,"Status");

   // Set gray background on ctl_description
   ctl_description.p_backcolor=0x80000022;
}

static int onNext_ListAvailable(bool validate)
{
   return 0;
}

static int onFinish_ListAvailable(bool validate)
{
   // Pass back the updated list in _param1 global variable
   _param1=ctl_update_list.p_user;
   return 0;
}

void ctl_update_list.on_change(int reason)
{
   upcheckUpdate_t list[] = p_user;
   if( list==null ) {
      return;
   }
   // Find the current tree node in the update list
   index := _TreeCurIndex();
   if( index<0 ) {
      return;
   }
   caption := _TreeGetCaption(index);
   _str Name, Version, Status, PkgName;
   parse caption with Name"\t"Version"\t"Status"\t"PkgName .;
   int i;
   for( i=0;i<list._length();++i ) {
      if( list[i].PackageName==PkgName && list[i].Version==Version ) {
         break;
      }
   }
   if( i<list._length() ) {
      // Found it
      ctl_description.p_text=list[i].Description;
      ctl_ignore_selected.p_value = (Status=="ignored")?(1):(0);
   }
}

/**
 * This function assumes that the update tree control is
 * the active window.
 * 
 * @param index Index to node in tree control.
 */
void _upcheckdlgIgnoreToggle(int index)
{
   caption := _TreeGetCaption(index);
   _str Name, Version, Status, PackageName;
   _str rest;
   parse caption with Name"\t"Version"\t"Status "\t" PackageName "\t" +0 rest;
   // Toggle it
   Status = (Status=="ignored")?("none"):("ignored");
   caption=Name"\t"Version"\t"Status"\t"PackageName:+rest;
   _TreeSetCaption(index,caption);
   // Now set Status in the update array
   upcheckUpdate_t list[] = ctl_update_list.p_user;
   if( list!=null ) {
      int i;
      for( i=0;i<list._length();++i ) {
         if( list[i].PackageName:==PackageName ) {
            list[i].Status=Status;
            break;
         }
      }
      ctl_update_list.p_user=list;
   }
}

void ctl_ignore_selected.lbutton_up()
{
   index := ctl_update_list._TreeCurIndex();
   if( index >=0 ) {
      ctl_update_list._upcheckdlgIgnoreToggle(index);
      ctl_update_list.call_event(CHANGE_OTHER,ctl_update_list,ON_CHANGE,'W');
   }
}

void _upcheck_form.on_resize()
{
   int formWidth = _dx2lx(SM_TWIP,p_active_form.p_client_width);
   int formHeight = _dy2ly(SM_TWIP,p_active_form.p_client_height);

   // Header at top
   // Note: ctl_header.p_height is constant.
   ctl_header.p_x=0;
   ctl_header.p_y=0;
   ctl_header.p_width=formWidth;
   ctl_header_caption.p_width=ctl_header.p_width - 2*ctl_header_caption.p_x;

   // Current slide
   gSlides[gCurrentSlide].wid.p_x=0;
   gSlides[gCurrentSlide].wid.p_y=ctl_header.p_y_extent;
   gSlides[gCurrentSlide].wid.p_width=formWidth;
   int slideHeight = formHeight - ctl_header.p_height - ctl_navigation.p_height;
   // Current slide's onResize function
   gSlides[gCurrentSlide].wid.p_height=slideHeight;
   pfnOnResize_tp pfn = gSlides[gCurrentSlide].pfnOnResize;
   if( pfn ) {
      (*pfn)();
   }

   // Navigation
   // Note: ctl_navigation.p_height is constant.
   ctl_navigation.p_x=0;
   ctl_navigation.p_y=gSlides[gCurrentSlide].wid.p_y+slideHeight;
   ctl_navigation.p_width=formWidth;
   ctl_nav_divider.p_width=ctl_navigation.p_width;
   // Preserve original gap between Finish and Cancel
   int finish_gap = ctl_cancel.p_x - (ctl_finish.p_x_extent);
   // Preserve original gap between Next and Finish
   int next_gap = ctl_finish.p_x - (ctl_next.p_x_extent);
   // Preserve original gap between Back and Next
   int back_gap = ctl_next.p_x - (ctl_back.p_x_extent);
   // Re-position the navigation buttons
   ctl_cancel.p_x = ctl_navigation.p_x_extent - ctl_cancel.p_width - UPCHECK_GAP_BORDER_X;
   ctl_finish.p_x = ctl_cancel.p_x - ctl_finish.p_width - finish_gap;
   ctl_next.p_x = ctl_finish.p_x - ctl_next.p_width - next_gap;
   ctl_back.p_x = ctl_next.p_x - ctl_back.p_width - back_gap;
}

static void _RefreshButtons()
{
   ctl_finish.p_enabled=true;
   int iback = gCurrentSlide-1;
   int inext = gCurrentSlide+1;
   ctl_next.p_enabled = (inext<gSlides._length());
   ctl_next.p_default = (inext<gSlides._length());
   ctl_finish.p_enabled = (inext>=gSlides._length());
   ctl_finish.p_default = (inext>=gSlides._length());
   ctl_back.p_enabled = (iback>=0);

   return;
}

void ctl_finish.on_create()
{
   gCurrentSlide=0;

   // Build an array of slide window handles and call each slide's
   // onCreate function.
   int i;
   for( i=0;i<gSlides._length();++i ) {
      wid := p_active_form._find_control(gSlides[i].name);
      wid.p_visible=false;
      gSlides[i].wid=wid;
      //pfnOnCreate_tp pfn = gSlides[i].pfnOnCreate;
      typeless* pfn = gSlides[i].pfnOnCreate;
      if( pfn ) {
         switch( arg() ) {
         case 0:
            (pfnOnCreate_tp*)(*pfn)(null);
            break;
         case 1:
            (pfnOnCreate_tp*)(*pfn)(arg(1));
            break;
         case 2:
            (pfnOnCreate_tp*)(*pfn)(arg(1),arg(2));
            break;
         case 3:
            (pfnOnCreate_tp*)(*pfn)(arg(1),arg(2),arg(3));
            break;
         }
      }
   }

   gSlides[0].wid.p_visible=true;

   _RefreshButtons();
}

void ctl_next.lbutton_up()
{
   _RefreshButtons();
}

void ctl_back.lbutton_up()
{
   _RefreshButtons();
}

void ctl_finish.lbutton_up()
{
   status := 0;
   pfnOnFinish_tp pfn = gSlides[gCurrentSlide].pfnOnFinish;
   if( pfn ) {
      status = (*pfn)(true);
   }
   p_active_form._delete_window(status);
}

void ctl_options.lbutton_up()
{
   upcheckOptions();
}

void ctl_cancel.lbutton_up()
{
   p_active_form._delete_window("");
}

//////////////////////////////////////////////////////////////////////
// End Update Manager eventtable
//////////////////////////////////////////////////////////////////////


static double _upcheckIntervalCaptionToValue(_str caption)
{
   double interval = -1;

   if( caption==get_message(VSRC_UPCHECK_INTERVAL_1DAY) ) {
      interval=UPCHECK_INTERVAL_1DAY;
   } else if( caption==get_message(VSRC_UPCHECK_INTERVAL_1WEEK) ) {
      interval=UPCHECK_INTERVAL_1WEEK;
   } else if( caption==get_message(VSRC_UPCHECK_INTERVAL_NEVER) ) {
      interval=0;
   }
   return interval;
}

static _str _upcheckIntervalValueToCaption(double interval)
{
   caption := "";

   if( interval==0 ) {
      caption = get_message(VSRC_UPCHECK_INTERVAL_NEVER);
   } else if( interval==UPCHECK_INTERVAL_1DAY ) {
      caption = get_message(VSRC_UPCHECK_INTERVAL_1DAY);
   } else if( interval==UPCHECK_INTERVAL_1WEEK ) {
      caption = get_message(VSRC_UPCHECK_INTERVAL_1WEEK);
   }
   return caption;
}


//////////////////////////////////////////////////////////////////////
// Begin Update Notification eventtable
//////////////////////////////////////////////////////////////////////

defeventtab _upcheckNotify_form;

void _upcheckNotify_form.on_close()
{
   // We will assume that the user wants to be reminded later if they hit
   // ESC or the close button on the dialog.
   p_active_form._delete_window(UPCHECKNOTIFYDLG_STATUS_REMINDLATER);
}

void ctl_display_now.on_create(upcheckUpdate_t list[]=null)
{
   caption := "New update(s) available.";
   // Count new updates
   nofupdates := 0;
   if( list!=null ) {
      int i;
      for( i=0;i<list._length();++i ) {
         if( list[i].Status!="ignored" && list[i].Status!="installed" ) {
            ++nofupdates;
         }
      }
   }
   if( nofupdates==1 ) {
      caption=nofupdates" new update available.";
   } else if( nofupdates>1 ) {
      caption=nofupdates" new updates available.";
   }
   ctl_message.p_caption=caption;
}

void ctl_display_now.lbutton_up()
{
   p_active_form._delete_window(UPCHECKNOTIFYDLG_STATUS_DISPLAYNOW);
}

void ctl_remind_later.lbutton_up()
{
   p_active_form._delete_window(UPCHECKNOTIFYDLG_STATUS_REMINDLATER);
}

void ctl_options.lbutton_up()
{
   upcheckOptions();
}

//////////////////////////////////////////////////////////////////////
// End Update Notification eventtable
//////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////
// Begin Update Manager Options eventtable
//////////////////////////////////////////////////////////////////////

defeventtab _upcheckOptions_form;

static void _upcheckdlgFillFetchIntervals()
{
   // Populate the list box with intervals
   ctl_fetch_interval._lbadd_item(get_message(VSRC_UPCHECK_INTERVAL_1DAY));
   ctl_fetch_interval._lbadd_item(get_message(VSRC_UPCHECK_INTERVAL_1WEEK));
   ctl_fetch_interval._lbadd_item(get_message(VSRC_UPCHECK_INTERVAL_NEVER));

   // Get the current interval
   double current_interval;
   if( isinteger(def_upcheck_fetch_interval) ) {
      current_interval=def_upcheck_fetch_interval;
      if( current_interval==0 ) {
         // That's okay, do nothing
      } else if( current_interval<0 ) {
         // <0 is not valid, so make it the default
         current_interval = UPCHECK_DEFAULT_FETCH_INTERVAL;
      } else if( current_interval>0 && current_interval<UPCHECK_INTERVAL_1DAY ) {
         // Too small, so make it the default
         current_interval = UPCHECK_DEFAULT_FETCH_INTERVAL;
      } else if( abs(current_interval-UPCHECK_INTERVAL_1DAY)<=UPCHECK_MSMINUTES(59) ) {
         // Close enough, so call it 1 day
         current_interval=UPCHECK_INTERVAL_1DAY;
      } else if( abs(current_interval-UPCHECK_INTERVAL_1WEEK)<=UPCHECK_MSHOURS(23) ) {
         // Close enough, so call it 1 week
         current_interval=UPCHECK_INTERVAL_1WEEK;
      } else {
         // Too big, so make it the default
         current_interval = UPCHECK_DEFAULT_FETCH_INTERVAL;
      }
   } else {
      // Invalid interval, so make it the default
      current_interval = UPCHECK_DEFAULT_FETCH_INTERVAL;
   }

   // Now set the current caption in the list box
   current_caption := _upcheckIntervalValueToCaption(current_interval);
   if( current_caption=="" ) {
      // Should never get here
      msg := "Invalid interval";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return;
   }
   ctl_fetch_interval._lbdeselect_all();
   ctl_fetch_interval._lbfind_and_select_item(current_caption);
}

void ctl_ok.on_create()
{
   _upcheckdlgFillFetchIntervals();
}

void ctl_ok.lbutton_up()
{
   status := 0;

   interval_caption := ctl_fetch_interval.p_text;
   double interval = _upcheckIntervalCaptionToValue(interval_caption);
   if( interval<0 ) {
      // This should never happen
      msg := "Invalid interval";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      status=1;
   } else if( interval==0 ) {
      // Tell user how to check for updates manually
      _str msg = get_message(VSRC_UPCHECK_MANUAL_CHECK_HELP);
      _message_box(msg,"",MB_OK|MB_ICONINFORMATION);
   }
   if( !status ) {
      def_upcheck_fetch_interval=interval;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
   p_active_form._delete_window(status);
}

void ctl_cancel.lbutton_up()
{
   p_active_form._delete_window("");
}

void ctl_proxy_settings.lbutton_up()
{
   config('_url_proxy_form', 'D');
}

//////////////////////////////////////////////////////////////////////
// End Update Manager Options eventtable
//////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////
// Begin Update Manager Progress eventtable
//////////////////////////////////////////////////////////////////////

defeventtab _upcheckProgress_form;

void ctl_cancel.on_create()
{
   // p_user is set to true when user clicks Cancel
   p_user=false;
}
void ctl_cancel.lbutton_up()
{
   p_user=true;
}

//////////////////////////////////////////////////////////////////////
// End Update Manager Progress eventtable
//////////////////////////////////////////////////////////////////////
