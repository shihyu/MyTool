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
#import "guicd.e"
#import "stdcmds.e"
#import "stdprocs.e"
#endregion

/*
    Tested on Version 1.0.1
*/
static const TORNADO_EXE_NAME=  "tornado.exe";
// tornado\host\x86-win32\bin\
// tornado\host\resource\help\windmanw.hlp
// Help filename relative to executable path
static const TORNADO_RELHELP_NAME=  '..\..\resource\help\windmanw.hlp';
static const TORNADO_STARTUP_TIMEOUT= 30;   // Seconds
static const TORNADO_TITLE_PREFIX= 'Tornado';


static const APPMENU_DISABLED_ERROR= 1;
static const APPMENU_GENERAL_ERROR=  2;

static _str _tornado_bin_path; // Must end with backslash


static _str get_tornado_path()
{
   if (_tornado_bin_path=="") {
      path := editor_name('p');
      // Strip win\
      path=substr(path,1,length(path)-1);
      path=_strip_filename(path,'n');
      // Strip vslick\
      path=substr(path,1,length(path)-1);
      path=_strip_filename(path,'n');
      // Now we should have tornado\host\x86-win32\bin\
      return(path);
   }
   return(_tornado_bin_path);
}
defeventtab _tornado_path_form;
void ctlok.on_create()
{
   text1.p_text=_tornado_bin_path;
   label1.p_caption=label1.p_caption:+" (":+TORNADO_EXE_NAME")";
}
void ctlok.lbutton_up()
{
   _tornado_bin_path=text1.p_text;
   _maybe_append_filesep(_tornado_bin_path);
   if (!tornado_exe_found()) {
      int result=_message_box("Tornado executable not found.\n\nDo you want to enter a different path?","",MB_YESNO);
      if (result==IDYES) {
         text1._set_focus();
         return;
      }
   }
   p_active_form._delete_window();
}
void ctlbrowse.lbutton_up()
{
   _str result = _ChooseDirDialog('',p_prev.p_text);
   if( result=='' ) {
      return;
   }
   //result=strip_options(result,dummy);
   p_prev.p_text=result;
   p_prev._end_line();
   p_prev._set_focus();
}

static bool tornado_exe_found()
{
   return(file_match("-p "_maybe_quote_filename(get_tornado_path():+TORNADO_EXE_NAME),1)!="");
}
// Returns true if tornado exectuable not found
static bool check_tornado_path()
{
   if (!tornado_exe_found()) {
      show('-modal _tornado_path_form');
      return(!tornado_exe_found());
   }
   return(false);
}
_command void tornado_apihelp(...) name_info(HELP_ARG',')
{
   if(check_tornado_path()) return;
   //filename='h:\temp\windmanw.hlp';
   _str filename=get_tornado_path():+TORNADO_RELHELP_NAME;
   _syshelp(filename,'', HELP_CONTENTS);
}

#if 0

static bool maybe_start_tornado()
{
   if (!TornadoIsUp()) {
      path=_maybe_quote_filename(_tornado_bin_path:+TORNADO_EXE_NAME);
      shell(path,'A');
      timeout=TORNADO_STARTUP_TIMEOUT;
      if (timeout>60) timeout=59;
      parse _time("M") with . ":" . ":" start_ss;
      for (;;) {
         delay(50);
         if (TornadoIsVisible()) {
            return(false);
         }

         parse _time("M") with . ":" . ":" ss;
         if (ss<start_ss) ss :+= 60;
         if (ss-start_ss>timeout) {
            _message_box("Unable to start Tornado","Timeout error");
            return(true);
         }
      }
   }
   return(false);
}
static void ntExecuteMenuItemError(int status)
{
   if (!status) {
      return;
   }
   _mdi._set_foreground_window();
   switch (status) {
   case STRING_NOT_FOUND_RC:
      _message_box("Could not find menu item");
      return;
   case APPMENU_DISABLED_ERROR:
      _message_box("This menu item is currently disabled");
      return;
   case APPMENU_GENERAL_ERROR:
      //This is sort of vague.  Could not find menu handle, or could not find window
      _message_box(nls("Could not execute menu item"));
      return;
   }
}

_command void tornado_download(...) name_info(HELP_ARG',')
{
   if(check_tornado_path()) return;
   if(maybe_start_tornado()) return;
   //download   &Debug, Do&wnload     Check for disabled
   if (_mdi.p_window_state=='M') {
      _mdi.p_window_state='N';
   }
   status=ntTornadoExecuteMenuItem("&Debug|Do&wnload...");
   ntExecuteMenuItemError(status);
}
_command void tornado_run(...) name_info(HELP_ARG',')
{
   if(check_tornado_path()) return;
   if(maybe_start_tornado()) return;
   if (_mdi.p_window_state=='M') {
      _mdi.p_window_state='N';
   }
   status=ntTornadoExecuteMenuItem("&Debug|&Run...");
   ntExecuteMenuItemError(status);
}

_command void tornado_debug(...) name_info(HELP_ARG',')
{
   if(check_tornado_path()) return;
   if(maybe_start_tornado()) return;
   if (_mdi.p_window_state=='M') {
      _mdi.p_window_state='N';
   }
   status=ntTornadoExecuteMenuItem("&Tools|&Debugger...");
   ntExecuteMenuItemError(status);
}
int ntTornadoExecuteMenuItem(_str MenuSpec)
{
   status=AppMenu('',TORNADO_TITLE_PREFIX,MenuSpec,1,1,1);
   return(status);
}
#endif

_form _tornado_path_form {
   p_backcolor=0x80000005;
   p_border_style=BDS_DIALOG_BOX;
   p_caption='Tornado Executable Directory';
   p_clip_controls=false;
   p_forecolor=0x80000008;
   p_height=2145;
   p_width=6060;
   p_x=1620;
   p_y=525;
   _label label1 {
      p_alignment=AL_LEFT;
      p_auto_size=false;
      p_backcolor=0x80000005;
      p_border_style=BDS_SUNKEN;
      p_caption='Enter the path to the tornado executable';
      p_forecolor=0x80000008;
      p_height=540;
      p_tab_index=1;
      p_width=4440;
      p_word_wrap=false;
      p_x=240;
      p_y=240;
   }
   _text_box text1 {
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_FIXED_SINGLE;
      p_completion=NONE_ARG;
      p_forecolor=0x80000008;
      p_height=285;
      p_tab_index=2;
      p_tab_stop=true;
      p_width=4470;
      p_x=180;
      p_y=1005;
      p_eventtab2=_ul2_textbox;
   }
   _command_button ctlbrowse {
      p_cancel=false;
      p_caption='&Browse...';
      p_default=false;
      p_height=315;
      p_tab_index=21;
      p_tab_stop=true;
      p_width=1200;
      p_x=4785;
      p_y=1005;
   }
   _command_button ctlok {
      p_cancel=false;
      p_caption='OK';
      p_default=true;
      p_height=375;
      p_tab_index=22;
      p_tab_stop=true;
      p_width=1215;
      p_x=240;
      p_y=1650;
   }
   _command_button  {
      p_cancel=true;
      p_caption='Cancel';
      p_default=false;
      p_height=375;
      p_tab_index=23;
      p_tab_stop=true;
      p_width=1215;
      p_x=1740;
      p_y=1650;
   }
}
