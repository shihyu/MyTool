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
#include "minihtml.sh"
#import "codehelp.e"
#import "dlgman.e"
#import "main.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "xml.e"
#import "optionsxml.e"
#import "help.e"
#import "recmacro.e"
#import "se/datetime/DateTime.e"
#import "se/datetime/DateTimeDuration.e"
#import "se/ui/toolwindow.e"
#import "toolbar.e"
#import "seltree.e"
#import "sc/util/Rect.e"
#include "alerts.sh"
#endregion


// animate the toast on the way up? (1=yes, 0=no)
int def_alerts_animate_up = 0;
// animate the toast on the way down? (1=yes, 0=no)
int def_alerts_animate_down = 0;
// the amount of time the toast stays up (in seconds)
int def_alerts_popup_duration = 6;
// whether or not popup toast messages are enabled (1=yes, 0=no)
int def_alert_popups_enabled = 1;


// handle for the popup message timer
static int gToastTimerHandle = -1;  
// number of times timer callback has been called
static typeless gToastStartTime= '';   
// window id of button whose message we are currently displaying
static int gToastWid = 0; 
static int gToastOrigHeight = 100;
static int gToastOrigWidth = 100;
static bool gMenuIsShowing = false;
static bool gForceCloseRequested = false;
// we precompute the ticks per second
static int gTicksPerSecond = 20;
static ALERT_REQUEST gMessageQueue[];

// the timer rate is 50ms which means that it will tick 20 times per second
static const TOAST_TIMER_RATE = 50;
// the toast animate time is the amount of time that an animation up or down
// should take.  We're shooting for a quarter second, which will be 10 timer ticks
static const TOAST_ANIMATE_TIME = 5;

/**
 * Initializer for the module
 */
definit()
{
   gToastTimerHandle = -1;
   gToastStartTime= 0;
   gToastWid = 0;
   gToastOrigHeight = 100;
   gToastOrigWidth = 100;
   // ok, 0.8 is a magic numer to account for missed timer events because
   // of the high timer rate
   gTicksPerSecond = (int)(((double)1000 / (double)TOAST_TIMER_RATE) * 0.8);
   gMessageQueue._makeempty();
}

/**
 * Used for appending numeric items to a string and creating a 
 * correst concatenation. 
 * 
 * @param src - the string to append to.
 * @param thing - the name of the thing to append
 * @param thingCount - the number of things
 * @param expectedLength - the length of the thing to add (if 
 *                       it's less than the expected length, the
 *                       the number will be padded with 0s).
 *  
 * Example - AppendNumericThing('1 minute', 'second', 10, 4) 
 * returns '1 minute, 0010 seconds'
 */
static _str AppendNumericThing(_str src, _str thing, int thingCount, int expectedLength = 1)
{
   if (thingCount == 0) {
      return src;
   }
   if (src != '') {
      src :+= ', ';
   }
   _str temp = (_str)thingCount;
   if (temp._length() < expectedLength) {
      temp = _pad(temp, expectedLength, '0', 'L');
   }
   if (thingCount == 1) {
      temp :+= ' 'thing;
   } else if (thingCount > 1) {
      temp :+= ' 'thing's';
   }
   return src :+ temp;
}

/**
 * Thius callback function just hides the close/cancel button, 
 * since there's already an ok button. 
 */
static _str test_select_cb(int reason, typeless user_data, typeless info=null)
{
   if (reason == SL_ONINITFIRST) {
      cancelBtnWid := _find_control("ctl_cancel");
      cancelBtnWid.p_visible = false;
   } 
   return '';
}

/**
 * This is called by the suatus icon area when the user clicks 
 * on an ALERT_TYPE_IN_PROCESS icon. 
 *  
 * @param inProcessItems - Any alerts that have been started but 
 *                       not yet finished.
 */
void showAlertGroupInProcessItems(ALERT_REQUEST inProcessItems[]=null)
{
   // make sure there's stuff in the list
   if ((inProcessItems == null) || (inProcessItems._length() == 0)) {
      _message_box("There are no active background processes.");
      return;
   }

   _str caps[];
   _str keys[];
   headings := "Process,Message,Start Time,Duration";
   for (i := 0; i < inProcessItems._length(); i++) {
      ALERT_REQUEST alertRequest = inProcessItems[i];
      se.datetime.DateTime timeStamp = se.datetime.DateTime.fromTimeB(alertRequest.TimeStampB);
      // build the timestamp string
      _str timestampStr = timeStamp.month()'-'timeStamp.day()'-'timeStamp.year()' ';
      timestampStr :+= timeStamp.hour()':'_pad((_str)timeStamp.minute(), 2, '0', 'L')':'_pad((_str)timeStamp.second(), 2, '0', 'L');
      // build the duration string
      int currentTime = (int)_time('g');
      int alertTime = (int)alertRequest.TimeStampG;
      int duration = currentTime - alertTime;
      durationStr := "";
      int days = duration intdiv (24 * 60 * 60);
      durationStr = AppendNumericThing(durationStr, 'day', days);
      duration -= (days * 24 * 60 * 60);
      int hours = duration intdiv (60 * 60);
      durationStr = AppendNumericThing(durationStr, 'hour', hours);
      duration -= (hours * 60 * 60);
      int minutes = duration intdiv (60);
      durationStr = AppendNumericThing(durationStr, 'minute', minutes);
      duration -= (minutes * 60);
      int seconds = duration;
      durationStr = AppendNumericThing(durationStr, 'second', seconds);
      caps[caps._length()] = alertRequest.AlertName"\t"alertRequest.Message"\t"timestampStr"\t"durationStr;
   }
   int flags = SL_SELECTCLINE |
               SL_DESELECTALL |
               SL_COLWIDTH |
               SL_CLOSEBUTTON |
               SL_XY_WIDTH_HEIGHT |
               SL_DEFAULTCALLBACK;
   select_tree(caps, keys, null, null, null,
               test_select_cb, '', "Background Processes",
               flags, headings, '', false, '', 'backgroundProcesses');
}

_command void showNotificationsToolbar() name_info(',')
{
   activate_tool_window('_tbnotification_form');
}

_command void showCurrentAlertOptions() name_info(',')
{
   // make sure there's an alert to show
   if (gMessageQueue._length() == 0) {
      return;
   }
   // handle the options request
   ALERT_REQUEST alertReq = gMessageQueue[0];
   if (alertReq.ConfigPath != '') {
      option := alertReq.ConfigOption;
      if (option == '') option = 'N';
      config(alertReq.ConfigPath, option);
   }
}

_command void configureAlerts() name_info(',')
{
   config("Application Options > Notifications");
}

_command void showCurrentAlertHelp() name_info(',')
{
   // make sure there's an alert to show
   if (gMessageQueue._length() == 0) {
      return;
   }
   // handle the options request
   ALERT_REQUEST alertReq = gMessageQueue[0];
   if (alertReq.HelpID != '') {
      help(alertReq.HelpID);
   }
}

_command void disableAlertPopups() name_info(',')
{
   // disable the alert popups
   def_alert_popups_enabled = 0;
   // flag that we're updating the state file
   _config_modify_flags(CFGMODIFY_DEFVAR);
}

_str getAlertsBitmapPath()
{
   return _getSlickEditInstallPath() :+ VSE_BITMAPS_DIR :+ FILESEP :+ 'status_alerts' :+ FILESEP;
}

static _str buildToastHeader(ALERT_REQUEST alertRequest)
{
   _xlat_default_font(CFG_STATUS, auto fontName, auto pointSizex10, auto fontFlags, auto fontHeight);
   pointSize := (pointSizex10 intdiv 10);
   if (pointSize < 6) pointSize=6;
   if (pointSize > 10) {
      pointSize  = pointSizex10*3 intdiv 40;
      fontHeight = fontHeight*3 intdiv 4;
   }
   header := "<pre style=\"font-family:":+fontName:+";font-size:":+pointSize:+"pt\">";
   header :+= "<img height=":+_dquote(fontHeight):+" width=":+_dquote(fontHeight):+" src="_dquote("vslick://":+alertRequest.AlertIconFileName):+">&nbsp;";
   header :+= "<b>" :+ alertRequest.Header :+ "</b></pre>";
   return header;
}

static _str buildToastBody(ALERT_REQUEST alertRequest)
{
   _xlat_default_font(CFG_STATUS, auto fontName, auto pointSizex10, auto fontFlags, auto fontHeight);
   pointSize := (pointSizex10 intdiv 10);
   if (pointSize < 6) pointSize=6;
   if (pointSize > 10) {
      pointSize  = pointSizex10*3 intdiv 40;
      fontHeight = fontHeight*3 intdiv 4;
   }
   body := "<pre style=\"font-family:":+fontName:+";font-size:":+pointSize:+"pt\">";
   body :+= alertRequest.Message;
   body :+= "</pre>";
   return body;
}

static void setHtmlText(_str content)
{
   _str font_name;
   int font_size;

   _codehelp_set_minihtml_fonts(_default_font(CFG_FUNCTION_HELP), _default_font(CFG_FUNCTION_HELP_FIXED), font_name, font_size);
   p_PaddingX = 120;
   p_PaddingY = 90;
   p_word_wrap = false;
   p_text = content;
   origWid := p_window_id;
   _minihtml_ShrinkToFit();
   p_window_id = origWid; 
}

/**
 * Returns whether the menu down image should be visible
 */
static bool shouldMenuDropdownBeVisible()
{
   // make sure there's an alert to show
   if (gMessageQueue._length() == 0) {
      return false;
   }
   ALERT_REQUEST alertRequest = gMessageQueue[0];
   // if the alert has help or unique configuration for the option, it is visible
   if (alertRequest.ConfigPath != '') {
      return true;
   }
   if (alertRequest.HelpID != '') {
      return true;
   }
   // if this is editing notifications or background notifications, it is visible
   if (alertRequest.AlertGroupID == ALERT_GRP_EDITING_ALERTS || 
       alertRequest.AlertGroupID == ALERT_GRP_WARNING_ALERTS || 
       alertRequest.AlertGroupID == ALERT_GRP_BACKGROUND_ALERTS) {
      return true;
   }
   // if we got here, then it should not be visible
   return false;
}

void showToastMessage(ALERT_REQUEST alertRequest)
{
   // determine the frame width
   int fw = _dx2lx(SM_TWIP,ctlpicture1._frame_width());
   int fh = _dy2ly(SM_TWIP,ctlpicture1._frame_width());

   p_active_form.p_MouseActivate = MA_NOACTIVATE;

   // position the picture that frames it
   ctlpicture1.p_y = 0;
   ctlpicture1.p_x = 0;

   // first, set the header text and shrink it to fit the text
   ctlminihtml1.p_x = fw;
   ctlminihtml1.p_y = fh;
   _str header = buildToastHeader(alertRequest);
   ctlminihtml1.setHtmlText(header);

   // now size the message HTML
   ctlminihtml2.p_x = fw;
   ctlminihtml2.p_y = ctlminihtml1.p_y_extent + 15;
   ctlminihtml2.p_height = 5000;

   _str msg = buildToastBody(alertRequest);
   ctlminihtml2.setHtmlText(msg);

   // 6/22/2017 - rb
   // Set background color of form to listbox background color which will
   // match the background color of minihtml control. Now everything has
   // the same background color.
   p_active_form.p_backcolor = 0x80000021;

   // now load the menu and close buttons
   imgX := 9;
   imgY := 9;
   _dxy2lxy(SM_TWIP, imgX, imgY);
   bitmapsDir := _getSlickEditInstallPath():+VSE_BITMAPS_DIR:+FILESEP;
   imgMenu.p_style = PSPIC_FLAT_MONO_BUTTON;
   imgMenu.p_picture = _find_or_add_picture(bitmapsDir:+"dialogs":+FILESEP:+"_cbarrow_mono.ico");
   imgMenu.p_width = imgX;
   imgMenu.p_height = imgY;
   imgMenu.p_y = fh + 30;
   imgMenu.p_visible = shouldMenuDropdownBeVisible();
   imgClose.p_style = PSPIC_FLAT_MONO_BUTTON;
   imgClose.p_picture = _find_or_add_picture(bitmapsDir:+"dialogs":+FILESEP:+"_xclose_mono.bmp");
   imgClose.p_width = imgX;
   imgClose.p_height = imgY;
   imgClose.p_y = fh + 30;

   // now position them
   int buttonAreaWidth = imgMenu.p_width + imgClose.p_width + 120;
   int minTotalTopWidth = ctlminihtml1.p_width + buttonAreaWidth;
   actualWidth := 0;
   int actualHeight = ctlminihtml2.p_y_extent;
   if (minTotalTopWidth > ctlminihtml2.p_width) {
      // this gets run when the top html control plus the two buttons
      // are longer than the lower html control
      ctlminihtml2.p_width = minTotalTopWidth;
   } // else the top html control plus the two buttons
     // is shorter then the lower html control

   imgClose.p_x = ctlminihtml2.p_width - imgClose.p_width - 45;
   imgMenu.p_x = imgClose.p_x - imgMenu.p_width - 30;
   actualWidth = ctlminihtml2.p_width;

   ctlimage1.p_y = ctlminihtml1.p_y_extent;
   ctlimage1.p_x = 120 + fw;
   ctlimage1.p_width = actualWidth - 240;

   // now size the picture frame surrounding it
   ctlpicture1.p_width = actualWidth + fw * 2;
   ctlpicture1.p_height = actualHeight + fh * 2;

   // now size the form itself
   p_width = ctlpicture1.p_width;
   p_height = ctlpicture1.p_height;

   // this is a workaround for a linux eclipse plugin problem where the
   // close and menu buttons on the toast message are not showing up
   // correctly...it has no ill effects 
   if (_isUnix() && isEclipsePlugin()) {
      ctlminihtml1.p_x = 20;
   }
}

static bool isMouseOverToastWindow()
{
   retVal := false;
   // determine if there's an active toast window and if the mouse is over it
   if (_iswindow_valid(gToastWid)) {
      // get the current mouse location
      mouseX := 0;
      mouseY := 0;
      mou_get_xy(mouseX, mouseY);
      sc.util.Rect rect = sc.util.Rect.mapFromWid(gToastWid);
      retVal = rect.contains(mouseX, mouseY);
   }
   return retVal;
}

void _toastTimerCallback()
{
   // determine if there's an active toast window and if the mouse is over it
   if (_iswindow_valid(gToastWid) && _AppHasFocus()) {
      // if the mouse is hovering over the toast window, keep showing it
      if ((isMouseOverToastWindow() == true) && (gForceCloseRequested == false)) {
         return;
      }
      // if toast is suspended, keep showing it
      if (gMenuIsShowing == true) {
         return;
      }
   }


   typeless currentTime = _time('b');
   // see if the time has expired on the toast
   if ((currentTime-gToastStartTime) >= def_alerts_popup_duration*1000 ||
       !_AppHasFocus() ) {
      //say('current time = 'currentTime);
      //say('start time =   'gToastStartTime);
      //say('DEACTIVATE!');
      // get the current alert request
      if (!_AppHasFocus()) {
         // Clearem all if SlickEdit does not have focus
         while (gMessageQueue._length() > 0) {
            // handle the options request
            ALERT_REQUEST alertReq = gMessageQueue[0];
            // deactivate this alert if it's a simple notification type
            if (alertReq.DeactivateOnCompletion == 1) {
               _DeactivateAlert(alertReq.AlertGroupID, alertReq.AlertID);
            }
            // remove the current message from the queue
            gMessageQueue._deleteel(0);
         }
      } else {
         if (gMessageQueue._length() > 0) {
            // handle the options request
            ALERT_REQUEST alertReq = gMessageQueue[0];
            // deactivate this alert if it's a simple notification type
            if (alertReq.DeactivateOnCompletion == 1) {
               _DeactivateAlert(alertReq.AlertGroupID, alertReq.AlertID);
            }
            // remove the current message from the queue
            gMessageQueue._deleteel(0);
         }
      }
      // reset the flags
      gForceCloseRequested = false;
      gToastStartTime = _time('b');
      // kill the window
      if (_iswindow_valid(gToastWid)) {
         gToastWid._delete_window();
         gToastWid = 0;
      }
   }
   // if we have no pending messages, great, clean up
   if (gMessageQueue._length() == 0) {
      // see if the timer has expired for this
      _kill_timer(gToastTimerHandle);
      gToastTimerHandle = -1;
      return;
   }
   // do all the nasty window positioning stuff
   showX := 0;
   showY := 0;
   if (isEclipsePlugin()) {
      eclipse_coords := "";
      _eclipse_get_toast_coords(eclipse_coords);
      split(eclipse_coords,",", auto coords);
      if (coords != null && coords._length() == 6) {
         // coords[0] = app width, coords[1] = app x coord, coords[2] = app frame width
         showX = (int)coords[0] + (int)coords[1] - (int)coords[2];
         // coords[3] = app y coord, coords[4] = height, coords[5] = app frame height
         showY = (int)coords[3] + (int)coords[4] - (int)coords[5];
      }
   } else {
      int mdi_wid=_MDICurrent();
      showX = VSWID_STATUS.p_width + mdi_wid.p_x + mdi_wid._left_width();
      showY = mdi_wid.p_y_extent + mdi_wid._top_height() - VSWID_STATUS.p_height;
   }
   _dxy2lxy(SM_TWIP, showX, showY);
   // if the toast popup form isn't showing, then make it
   if (!_iswindow_valid(gToastWid)) {
      ALERT_REQUEST alertRequest = gMessageQueue[0];
      gToastWid=show('-desktop -hidden -nocenter _toast_form');
      gToastWid.showToastMessage(alertRequest);
      gToastOrigWidth = gToastWid.p_width;
      gToastOrigHeight = gToastWid.p_height;
      showX -= gToastOrigWidth;
      gToastWid._move_window(showX, showY, gToastOrigWidth, gToastOrigHeight);
      if (_AppHasFocus() && alertRequest.ShowPopup == 1) {
         gToastWid._ShowWindow(SW_SHOWNOACTIVATE);
      } else {
         //gToastWid.p_visible = false;
      } 
   }
   // this code manages the actual popup and crouch down behavior
   increment := 0;
   if ((currentTime-gToastStartTime) <=TOAST_ANIMATE_TIME*1000) {
   //if (gToastNumTimerEvents <= TOAST_ANIMATE_TIME) {
      if (false /*def_alerts_animate_up == 1*/) {
         // popup stuff here
         //increment = (int)(((double)gToastNumTimerEvents / (double)TOAST_ANIMATE_TIME) * (double)gToastOrigHeight);
         gToastWid.p_height = increment;
         gToastWid.p_y = showY - increment;
      } else {
         gToastWid.p_y = showY - gToastOrigHeight;
      }
   } else if ((currentTime-gToastStartTime) >= (def_alerts_popup_duration-TOAST_ANIMATE_TIME)*1000) {
      if (false /*def_alerts_animate_down == 1*/) {
         // crouch down stuff here
         //increment = (int)(((double)(popupDurationTimerTicks - gToastNumTimerEvents) / TOAST_ANIMATE_TIME) * (double)gToastOrigHeight);
         gToastWid.p_height = increment;
         gToastWid.p_y = showY - increment;
      } else {
         gToastWid.p_y = showY - gToastOrigHeight;
      }
   }
}

void make_a_toast(ALERT_REQUEST alertRequest)
{
   // only continue if popups are enabled
   if ((def_alert_popups_enabled == 0) && (!alertRequest.IsHoverRequest)) {
      return;
   }
   // if we're showing a toast and this is a hover request, then just exit
   if ((_iswindow_valid(gToastWid)) && (alertRequest.IsHoverRequest)) {
      return;
   }
   // add the message to the message stack
   gMessageQueue[gMessageQueue._length()] = alertRequest;
   // see if we need to start the timer
   if (gToastTimerHandle < 0) {
      gToastStartTime = _time('b');
      gToastTimerHandle = _set_timer(TOAST_TIMER_RATE, _toastTimerCallback);
   }
}

void kill_a_toast()
{
   // flag that we are forcefully closing this window
   gForceCloseRequested = true;
   // set the start time to 0 to trick it into thinking it's ended
   gToastStartTime = 0;
}

defeventtab _toast_form;

void ctlminihtml1.on_change(int reason,_str hrefText)
{
   if (reason==CHANGE_CLICKED_ON_HTML_LINK) {
       // is this a command or function we should run? 
       if (substr(hrefText,1,6)=='<<cmd') {
           cmdStr := substr(hrefText,7);
           cmd := "";
           params := "";
           parse cmdStr with cmd params;
           index := find_index(cmd, COMMAND_TYPE|PROC_TYPE);
           if (index && index_callable(index)) {
              // get the active window
              int curWid = _mdi;
              get_window_id(curWid);
              // activate the MDI window
              activate_window(_mdi);
              if (params == '') {
                 call_index(index);
              } else {
                 call_index(params,index);
              }
              // restore the current window
              if (_iswindow_valid(curWid)) {
                 activate_window(curWid);
              }
           }
           return;
       }
   }
}

void imgClose.on_destroy()
{
   gToastWid=0;
}

void imgClose.lbutton_up()
{
   // kill the toast!
   kill_a_toast();
}

/**
 * Builds the drop down menu for a toast message
 */
static void makeToastDropDownList()
{
   // make sure there's an alert to show
   if (gMessageQueue._length() == 0) {
      return;
   }
   ALERT_REQUEST alertRequest = gMessageQueue[0];
   
   // create a temporary menu to show
   menuName := '_temp_toast_drop_down_menu';
   // see if the menu is already open
   int index = find_index(menuName, oi2type(OI_MENU));
   if (index) {
      // yes!  just toggle it off, don't reshow it
      delete_name(index);
      return;
   }
   index = insert_name("_temp_toast_drop_down_menu",oi2type(OI_MENU));

   // make the menus based on the current alert request
   showSeperator := false;
   if (alertRequest.ConfigPath != '') {
      _menu_insert(index, -1, 0, 'Go to options for 'alertRequest.AlertName, 'showCurrentAlertOptions', '', 'Configure options for 'alertRequest.AlertName);
      showSeperator = true;
   }
   if (alertRequest.HelpID != '') {
      _menu_insert(index, -1, 0, 'Show help for 'alertRequest.AlertName, 'showCurrentAlertHelp', '', 'Read more about 'alertRequest.AlertName);
      showSeperator = true;
   }
   // if this is editing notifications or background notifications, we can configure them
   if (showSeperator == true) {
      _menu_insert(index, -1, 0, '-', '', '', '');
   }
   _menu_insert(index, -1, 0, 'Configure notifications', 'configureAlerts', '', 'Configure notifications messages');

   int menu_handle = p_active_form._menu_load(index,'P');
   // show the menu
   x := 100;
   y := 100;
   x = mou_last_x('M') - x;
   y = mou_last_y('M') - y;
   _lxy2dxy(p_scale_mode, x, y);
   _map_xy(p_window_id, 0, x, y, SM_PIXEL);
   int flags = VPM_RIGHTALIGN | VPM_LEFTBUTTON;
   // indicate that the menu is active so that any toast doesn't go away
   gMenuIsShowing = true;
   int status = _menu_show(menu_handle, flags, x, y);
   // flag that the menu is done
   gMenuIsShowing = false;
   _menu_destroy(menu_handle);
   // Delete temporary menu resource
   delete_name(index);
}

void imgMenu.lbutton_up()
{
   makeToastDropDownList();
}


