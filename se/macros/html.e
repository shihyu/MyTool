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
#include "autocomplete.sh"
#include "slick.sh"
#include "tagsdb.sh"
#include "color.sh"
#import "se/lang/api/LanguageSettings.e"
#import "se/tags/TaggingGuard.e"
#import "sc/lang/ScopedTimeoutGuard.e"
#import "adaptiveformatting.e"
#import "alllanguages.e"
#import "autocomplete.e"
#import "c.e"
#import "ccode.e"
#import "ccontext.e"
#import "cformat.e"
#import "codehelp.e"
#import "codehelputil.e"
#import "commentformat.e"
#import "compile.e"
#import "context.e"
#import "ccontext.e"
#import "csymbols.e"
#import "cutil.e"
#import "dlgman.e"
#import "guiopen.e"
#import "hformat.e"
#import "hotspots.e"
#import "htmltool.e"
#import "ini.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "markfilt.e"
#import "math.e"
#import "notifications.e"
#import "optionsxml.e"
#import "picture.e"
#import "pmatch.e"
#import "pushtag.e"
#import "seek.e"
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "tags.e"
#import "util.e"
#import "xml.e"
#import "xmlwrap.e"
#import "xmlwrapgui.e"
#import "beautifier.e"
#import "cfg.e"
#endregion

using se.lang.api.LanguageSettings;

bool def_mozilla_modified=false; // Indicates whether the mozilla configuration has been updated.
static const VSLICKHELP_WEB_BROWSER= "VSLICKHELP_WEB_BROWSER";
static const SLICKEDIT_HOME=  "http://www.slickedit.com";
static const SLICKEDIT_FORUM='https://community.slickedit.com/index.php?board=1.0';
static const SLICKEDIT_SUPPORT=  (SLICKEDIT_HOME:+"/support/su_support.php");
static const SLICKEDIT_FAQ=  (SLICKEDIT_HOME:+"/support/faq");

//---------------------------------------------------------------------
// Code for Unix ...
static const AUTOSTART_TIMEOUT= 20;

static const BIAUTO= 0;
//#define BINNAVIGATOR 1
//#define BINNAVIGATOR4 BINNAVIGATOR
static const BIIEXPLORER= 2;
//#define BIWEBEXPLORER 3
//#define BIMOSAIC 4
static const BIOTHER= 5;
//#define BINNAVIGATOR6 6
static const BIMOZILLA= 7;
static const BISAFARI= 8;
static const BIFIREFOX= 9;
static const BICHROME= 10;

static const OSIWIN= 0;
//#define OSIOS2 1
static const OSIRESERVED= 2;
static const OSIUNIX= OSIWIN;

static _str browserNames[] = {
   "Automatic",
   "",
   "Internet Explorer",
   "",
   "",
   "Other",
   "",
   "Mozilla",
   "Safari",
   "Firefox",
   "Chrome"
};
// Browser index:
//    0 -- Automatic
//    1 -- Netscape Navigator 4
//    2 -- Internet Explorer (Windows 95/3.1/NT only)
//    3 -- Web Explorer (OS/2 only) -- NOT USED
//    4 -- Mosaic (Unix only) -- NOT USED
//    5 -- Other
//    6 -- Netscape Navigator 6
//    7 -- Mozilla
//    8 -- Safari
//    9 -- Firefox
HTML_INFO_STRUCT def_html_info = {
   { BIAUTO, BIOTHER },
   { "","","","","","","","","","","" },
   { "","","","","","","","","","","" },
   { "","","","","","","","","","","" },
   { "","","","","","","","","","","" },
   { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
};
// Other browsers:
//    0 -- Windows 95/3.1/NT
//    1 -- OS/2 -- NOT USED
//    2 -- Reserved
HTML_INFO_STRUCT def_html_other_info = {
   { BIAUTO, BIOTHER },
   { "","","" },
   { "","","" },
   { "","","" },
   { "","","" },
   { 0, 0, 0 }
};
static HTML_INFO_STRUCT info_copy;
static HTML_INFO_STRUCT info_othercopy;
static int ignore_textbox_change = 0;
static int osi = OSIWIN;
static int unixRunning = 0;

static int BROWSER_INFO_MODIFIED(...) {
   if (arg()) _program_la.p_user=arg(1);
   return _program_la.p_user;
}

static void html_add_tld_globals(int editorctl_wid, int window_id, int tree_index);

static typeless cs_ori_position;
static _str standAloneTagList[] = {
   "BR", "WBR", "IMG", "HR", "META", "LI", "SPACER", "LINK",
   "INPUT", "BASEFONT", "DT", "DD", "FRAME",
   "ISINDEX", "BASE", "PLAINTEXT", "KEYGEN"
};
static _str tagAllowedInPTag[] = {
   "B", "BIG", "BLINK", "CITE", "CODE", "EM", "FONT", "I",
   "KBD", "S", "SMALL", "STRIKE", "STRONG", "SUB", "SUP",
   "TT", "U", "VAR", "A", "IMG", "SPACER", "SPAN"
};

static SYNTAX_EXPANSION_INFO ant_space_words:[] = {
   "<project>"                             => { "<project name="" default=""> ..." },
   "<target>"                              => { "<target name=""> ..." },
   "<target> with dependencies"            => { "<target name="" depends=""> ..." },
   "<property> with name, value"           => { "<propery name="" value=""/>" },
   "<property> with name, location"        => { "<propery name="" location=""/>" },
   "<property> with file"                  => { "<propery file=""/>" },
   "<import>"                              => { "<import file=""/>" },
   "<echo>"                                => { "<echo message=""/>" },
   "<delete> fileset"                      => { "<delete> <fileset ..." },
   "<delete> referenced fileset"           => { "<delete> <fileset refid= ..." },
   "<antcall>"                             => { "<antcall target=""/>" },
   "<antcall> with params"                 => { "<antcall target=""> <params ..." },
   "<fileset>"                             => { "<fileset dir="" ..." },
   "<macrodef>"                            => { "<macrodef name="" ..." },
   "<exec>"                                => { "<exec executable=""> ..." },
   "<mkdir>"                               => { "<mkdir dir=""> ..." },
   "<jar> with params inside opening tag"  => { "<jar destfile=""/>" },
   "<jar>"                                 => { "<jar destfile=""> ..." },
};


/**
 * static hash table created to store information for
 * HTML syntax expansion.
 */
static _str gtagcache_info_lang;
static _str gtagcache_info_buf_name;
static int gtagcache_info;

/**
 * Initialize the static gtagcache_info.
 *
 * @return
 */
definit()
{
   gtagcache_info= -1;
   gtagcache_info_lang="";
   gtagcache_info_buf_name='';

}

_str get_format_setting(_str settingName,bool return_minus_one_if_disabled=true)
{
   langId := p_LangId;
   if (_html_tags_loaded(langId,p_buf_name)) {
      result:=_beautifier_get_property(gtagcache_info,settingName,"",auto apply);
      if (return_minus_one_if_disabled && !apply) {
         return -1;
      }
      return result;
   }
   return "";
}

static void _init_osi()
{
   if (!def_mozilla_modified) {
      def_mozilla_modified=true;
      _config_modify_flags(CFGMODIFY_DEFVAR);
      // Force defaults to be used.
      def_html_info.exePath[BIMOZILLA]="";
   }
   // All other OS'es use index 0.  This include all UNIX platforms.
   osi=OSIWIN;
   unixRunning = 0;
   if ( _win32s() || machine() == "WINDOWS" ) {
      osi=OSIWIN;
   } else {
      // Unix and Windows/NT share the same index to def_html_info struct.
      // We can do this because these OS'es don't share state file.
      osi=OSIUNIX;
      unixRunning = 1;
   }
}

// Desc:  View the file.  Start Netscape if necessary.
// Retn:  0 for OK, 1 for error.
static int nsViewDoc( _str filename, int overrideDDE=-1 )
{
   // Create a temporary view so that the DDE can freely
   // modify the buffer without affecting others.
   view_id := 0;
   int old_view_id = _create_temp_view( view_id );
   int status = nsViewDoc1( filename, overrideDDE );
   _delete_temp_view( view_id );
   return( status );
}
// Desc:  View the file.  Start Netscape if necessary.
// Retn:  0 for OK, 1 for error.
static int nsViewDoc1( _str filename, int overrideDDE=-1 )
{
   // Build DDE request or shell command:
   execmd := "";
   typeless useDDE=false;
   typeless app="";
   typeless topic="";
   typeless item="";
   bool usingDefaultBrowser;
   if ( buildRequest( filename, execmd, useDDE, app, topic, item, overrideDDE,usingDefaultBrowser ) ) {
      return( 1 );
   }

   typeless status=0;
   line := "";
   msg := "";
   timeout := 0;
   typeless start_ss="";
   typeless ss="";
   alternate_shell := "";
   typeless ec=0;

   if ( useDDE ) {
      if (_isWindows()) {
         _str default_execmd;
         typeless default_useDDE;
         _str default_app,default_topic,default_item;

         getDefaultBrowserInfo( BIAUTO, default_execmd, default_useDDE, default_app, default_topic, default_item );

         _str default_browser=parse_file(default_execmd,false);
         default_browser=_strip_filename(default_browser,'pe');
         _str temp = execmd;
         _str browser = parse_file(temp,false);
         browser=_strip_filename(browser,'pe');
         /*
            In order to support long url's, we use shell execute.
            DDE is limited to 255 characters.  We can use
            NTShellExecuteEx for the default browser.
         */
         if (usingDefaultBrowser || _file_eq(default_browser,browser)) {
            _str exe=_UTF8ToMultiByte(filename);
            params := "";
            int exitCode;
            int shell_status = _ShellExecute(exe,"",params);
            status = ( shell_status != 0 ) ? shell_status : 0;
            return(status);
         }
      }
      
      //messageNwait( "PREVENT CRASH...  app="app" item="item" topic="topic );

      // Try to activate the browser and get the frame/window ID:
      _str browserID;
      view_id := 0;
      int old_view_id = _create_temp_view(view_id);
      status=_dderequest("L",app,"0xFFFFFFFF,0x0","WWW_Activate");
      if (!status) {
         get_line(line);
         line = _asc(substr(line, 1, 1));
         eval_exp(browserID,line,16);
      }
      _delete_temp_view(view_id);

      if (status) {
         // Browser not running, try to start browser:
         if ( shell( execmd, 'AN' ) ) {
            msg = "Can't start browser with \n'"execmd"'.\n\n"getHowToReconfigureBrowserMsg();
            _message_box(msg);
            return( 1 );
         }
         timeout=AUTOSTART_TIMEOUT;
         if (timeout>60) timeout=59;
         parse _time("M") with . ":" . ":" start_ss;
         for (;;) {
            delay(50);
            old_view_id = _create_temp_view(view_id);
            status=_dderequest("L",app,"0xFFFFFFFF,0x0","WWW_Activate");
            if (!status) {
               get_line(line);
               line = _asc(substr(line, 1, 1));
               eval_exp(browserID,line,16);
            }
            _delete_temp_view( view_id );
            if (!status) break;
            parse _time("M") with . ":" . ":" ss;
            if (ss<start_ss) ss += 60;
            if (ss-start_ss>timeout) {
               //messageNwait( "Timed out" );
               //messageNwait( "ss="ss" start_ss="start_ss" timeout="timeout );
               break;
            }
         }
         if (status) {
            _message_box("Timed-out trying to start browser.\n\nPlease try again.");
            return( 1 );
         }
      }

      // Now that we have a window ID for the activated
      // browser, try to find its frame parent, if there is one.
      old_view_id = _create_temp_view(view_id);
      status=_dderequest("L",app,browserID:+",0x0","WWW_GetFrameParent");
      if (!status) {
         // Activate the parent frame:
         get_line(line);
         line = _asc(substr(line, 1, 1));
         eval_exp(browserID,line,16);
         status=_dderequest("L",app,browserID:+",0x0","WWW_Activate");
      }
      _delete_temp_view(view_id);

      // Send the page over:
      old_view_id = _create_temp_view(view_id);
      status=_dderequest("L",app,item,topic);
      _delete_temp_view( view_id );
   } else {
      // No DDE...  Use the actual command to start the browser AND
      // pass the buffer name:
      if ( unixRunning ) {
         execmd :+= " > /dev/null 2>&1";
         alternate_shell=path_search("sh");
         if (alternate_shell=="") alternate_shell="/bin/sh";
         ec = shell( execmd, "A",alternate_shell);
         //_message_box('ec='ec' h0 'execmd);
         if ( ec ) {
            // Failed starting browser with default command.
            // Try another format 'browerExe %F'.
            buildRequest( "", execmd, useDDE, app, topic, item );
            //_message_box("h1 "execmd);
            execmd :+= " "filename;
            //_message_box("h2 "execmd);
            ec = shell( execmd, "A" );
         }
      } else {
         ec = shell( execmd, "AN" );
      }
      if ( ec ) {
         msg = "Can't view file with \n'"execmd"'.\n\n"getHowToReconfigureBrowserMsg();
         _message_box( msg );
         return( 1 );
      }
   }
   return( 0 );
}


#region Options Dialog Helper Functions

defeventtab _html_form;

void _html_form_save_settings()
{
   BROWSER_INFO_MODIFIED(0);
}

bool _html_form_is_modified()
{
   return (BROWSER_INFO_MODIFIED() != 0);
}

void _html_form_apply()
{
   if ( BROWSER_INFO_MODIFIED() ) {
      //messageNwait( "Form info modified." );
      def_html_info = info_copy;
      def_html_other_info = info_othercopy;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
}

#endregion Options Dialog Helper Functions

void _html_form.on_resize()
{
   pad := ctllabel1.p_x;
   widthDiff := p_width - (_ctl_browser_combo.p_x_extent + pad);

   if (widthDiff) {
      _ctl_browser_combo.p_width += widthDiff;
      _program_tx.p_width += widthDiff;
      _browse1.p_x += widthDiff;
      _menu_btn.p_x += widthDiff;

      _dde_fr.p_width += widthDiff;
      _app_tx.p_width += widthDiff;
      _topic_tx.p_width += widthDiff;
      _item_tx.p_width += widthDiff;
   }
}

void _ctl_browser_combo.on_create()
{
   _init_osi();

   // fill in our combo
   for (i := 0; i < browserNames._length(); i++) {
      // there are blank ones in there, spaceholders for 
      // browsers we don't use anymore
      if (browserNames[i] != "") {

         // safari and ie on mac but not other unix
         if ((unixRunning && !_isMac()) && (i == BIIEXPLORER || i == BISAFARI)) continue;

         // no safari on Windows
         if (!unixRunning && i == BISAFARI) continue;

         _ctl_browser_combo._lbadd_item(browserNames[i]);
      }
   }

   // put these in order
   _ctl_browser_combo._lbsort();

   // line things up purdy
   sizeBrowseButtonToTextBox(_program_tx.p_window_id, _browse1.p_window_id, _menu_btn.p_window_id, _ctl_browser_combo.p_x_extent);

   // Update the controls:
   BROWSER_INFO_MODIFIED(0);
   info_copy = def_html_info;
   info_othercopy = def_html_other_info;

   // select one, that should fill in the rest of the info
   browser := browserIndexToName(info_copy.browser[osi]);
   _ctl_browser_combo._lbfind_and_select_item(browser);          
   _ctl_browser_combo.call_event(CHANGE_SELECTED, _ctl_browser_combo, ON_CHANGE, 'W');

}

void _ctl_browser_combo.on_change()
{
   index := browserNameToIndex(_ctl_browser_combo.p_text);
   if (index < 0) {
      // bogus, what do we do here?
      return;
   }

   // fill in the info for this browser
   info_copy.browser[osi] = index;
   BROWSER_INFO_MODIFIED(1);

   switch (index) {
   case BIAUTO:
      setState( 0, 0, 0, 0 );
      // Must fetch for Auto case on Windows, since older versions
      // would hard code the path to the default browser. Now we use
      // explorer.exe to open urls in default browser.
      if ( _isWindows() ) {
         info_copy.exePath[BIAUTO] = "";
      }
      break;
   case BIOTHER:
      if (unixRunning) {
         setState( 1, 0, 0, 0 );
      } else {
         setState( 1, info_othercopy.useDDE[osi], 1, 0 );
      }
      break;
   case BIIEXPLORER:
      setState( 1, info_copy.useDDE[index], 1, 1 );
      break;
   case BISAFARI:
      setState( 1, info_copy.useDDE[index], 1, 1 );
      break;
   case BIMOZILLA:
   case BIFIREFOX:
   case BICHROME:
      if (unixRunning) {
         setState( 1, 0, 0, 1 );
      } else {
         setState( 1, info_copy.useDDE[index], 1, 1 );
      }
      break;

   }

   fillBrowser(index, false);
   BROWSER_INFO_MODIFIED(1);
}

_dde_fr.lbutton_up()
{
   s := (p_value == 1);

   int bi = info_copy.browser[osi];
   if ( bi == BIOTHER ) {
      info_othercopy.useDDE[osi] = p_value;
   } else {
      info_copy.useDDE[bi] = p_value;
   }
   BROWSER_INFO_MODIFIED(1);
}

static int browserNameToIndex(_str name)
{
   for (i := 0; i < browserNames._length(); i++) {
      if (browserNames[i] == name) {
         return i;
      }
   }

   return -1;
}

static _str browserIndexToName(int index)
{
   if (index >= 0 && index < browserNames._length()) {
      return browserNames[index];
   }

   return "";
}

_browse1.lbutton_up()
{
   wid := p_window_id;
   typeless result=_OpenDialog("-modal",
                      "",                   // Dialog Box Title
                      "",                   // Initial Wild Cards
                      def_file_types,       // File Type List
                      OFN_FILEMUSTEXIST     // Flags
                      );
   if (result=="") {
      return("");
   }
   p_window_id=wid.p_prev;
   p_text=result;
   end_line();
   _set_focus();
   return("");
}
_program_tx.on_change()
{
   if ( !ignore_textbox_change ) {
      fillHTMLInfo();
   }
}
_app_tx.on_change()
{
   if ( !ignore_textbox_change ) {
      fillHTMLInfo();
   }
}

static void setState( typeless prog, 
                      typeless dde, 
                      typeless ddetoggle, 
                      typeless allowdefaults )
{
   s := false;
   if ( prog ) s = true;
   _program_la.p_enabled = s;
   _program_tx.p_enabled = s;
   _browse1.p_enabled = s;
   _menu_btn.p_enabled = s;

   if ( dde ) s = true;
   else s = false;

   if ( ddetoggle ) _dde_fr.p_enabled = true;
   else _dde_fr.p_enabled = false;
}
static void fillBrowser(int bi, bool queryNew)
{
   if ( queryNew 
        || (bi != BIOTHER && (info_copy.exePath[bi] == null || info_copy.exePath[bi] == "")) ) {

      // we don't want to deal with any textbox changes right now
      ignore_textbox_change = 1;

      // Update from current info:
      execmd := "";
      typeless useDDE=false;
      typeless app="";
      typeless topic="";
      typeless item="";

      getDefaultBrowserInfo(bi, execmd, useDDE, app, topic, item);
      if (bi == BICHROME || bi == BIFIREFOX || bi == BIMOZILLA) {
         typeless p1, p2;
         if( !parseItemParts(execmd,p1,p2) ) {
            execmd= p1 "%f" p2;
         }
      }

      // now fill everything in
      _program_tx.p_text = execmd;
      _app_tx.p_text = app;
      _topic_tx.p_text = topic;
      _item_tx.p_text = item;
      _dde_fr.p_value = useDDE;
      ignore_textbox_change = 0;
      fillHTMLInfo();
   } else if (bi == BIOTHER && info_othercopy.exePath[osi] == "") {
      execmd := "";
      typeless useDDE=false;
      typeless app="";
      typeless topic="";
      typeless item="";
      getOther( execmd, useDDE, app, topic, item );
      info_othercopy.exePath[osi] = execmd;
      fillHTMLInfo();
   } else {
      // Update from saved data:
      fillDefInfo( bi );
   }

}
// Desc:  Update the internal data structure with the new browser info.
static void fillHTMLInfo()
{
   //messageNwait( "fillHTMLInfo h1" );
   int bi = info_copy.browser[osi];
   if ( bi == BIOTHER ) {
      info_othercopy.exePath[osi] = _program_tx.p_text;
      info_othercopy.app[osi] = _app_tx.p_text;
      info_othercopy.topic[osi] = _topic_tx.p_text;
      info_othercopy.item[osi] = _item_tx.p_text;
      info_othercopy.useDDE[osi] = _dde_fr.p_value;
   } else {
      info_copy.exePath[bi] = _program_tx.p_text;
      info_copy.app[bi] = _app_tx.p_text;
      info_copy.topic[bi] = _topic_tx.p_text;
      info_copy.item[bi] = _item_tx.p_text;
      info_copy.useDDE[bi] = _dde_fr.p_value;
   }
   BROWSER_INFO_MODIFIED(1);
}
// Desc:  Update the controls with the saved values.
static void fillDefInfo( int bi )
{
   ignore_textbox_change = 1;
   if ( bi == BIOTHER ) {
      _program_tx.p_text = info_othercopy.exePath[osi];
      _app_tx.p_text = info_othercopy.app[osi];
      _topic_tx.p_text = info_othercopy.topic[osi];
      _item_tx.p_text = info_othercopy.item[osi];
      _dde_fr.p_value = info_othercopy.useDDE[osi];
   } else {
      if (info_copy.exePath._length() < bi || info_copy.exePath[bi] == null) info_copy.exePath[bi] = "";
      if (info_copy.app._length() < bi || info_copy.app[bi] == null) info_copy.app[bi] = "";
      if (info_copy.topic._length() < bi || info_copy.topic[bi] == null) info_copy.topic[bi] = "";
      if (info_copy.item._length() < bi || info_copy.item[bi] == null) info_copy.item[bi] = "";
      if (info_copy.useDDE._length() < bi || info_copy.useDDE[bi] == null) info_copy.useDDE[bi] = 0;

      _program_tx.p_text = info_copy.exePath[bi];
      _app_tx.p_text = info_copy.app[bi];
      _topic_tx.p_text = info_copy.topic[bi];
      _item_tx.p_text = info_copy.item[bi];
      _dde_fr.p_value = info_copy.useDDE[bi];
   }
   ignore_textbox_change = 0;
}
static _str getHowToReconfigureBrowserMsg() {
   // If the license manager dialog is displayed
   if (_LicenseType()== LICENSE_TYPE_NONE) {
      return("");
   }
   return("Please use Web Browser Setup dialog to specify a browser.");
}
// Desc: Build the DDE request or shell command based on current browser info.
// Retn: 0 for OK, 1 for error.
static int buildRequest( _str filename, var execmd, var useDDE,
                         var app, var topic, var item, int overrideDDE=-1,bool &usingDefaultBrowser=false)
{
   // If nothing is setup, try query for the data.
   // Otherwise, use existing data.
   typeless temp1 = "";
   int bi = def_html_info.browser[osi];
   if ( bi == BIOTHER ) {
      execmd = def_html_other_info.exePath[osi];
   } else if ( bi == BIAUTO && _isWindows() ) {
      // Must fetch for Auto case on Windows, since older versions
      // would hard code the path to the default browser. Now we use
      // explorer.exe to open urls in default browser.
      execmd = "";
   } else {
      execmd = def_html_info.exePath[bi];
   }
   if ( execmd == "" ) {
      usingDefaultBrowser=true;
      getDefaultBrowserInfo( bi, execmd, useDDE, app, topic, temp1 );
      if (_isMac() && substr(filename,1,7) == "file://") {
         getMacDefaultOpenFileURL(execmd,useDDE,app,topic,item);
      }
   } else {
      usingDefaultBrowser=false;
      if ( bi == BIOTHER ) {
         app = def_html_other_info.app[osi];
         topic = def_html_other_info.topic[osi];
         useDDE = def_html_other_info.useDDE[osi];
         temp1 = def_html_other_info.item[osi];
      } else {
         app = def_html_info.app[bi];
         topic = def_html_info.topic[bi];
         useDDE = def_html_info.useDDE[bi];
         temp1 = def_html_info.item[bi];
      }
   }
   if (_isUnix() && !_isMac()) {
      if (get_env(VSLICKHELP_WEB_BROWSER)=="") {
         // Check if we are in the Linux plugin going to the trial website - RGH
         if (!isEclipsePlugin() && !pos("http://register.slickedit.com/trial/", execmd)) {
            set_env(VSLICKHELP_WEB_BROWSER,get_env("VSLICKBIN1"):+"mozilla/mozilla");
         } else {
            // No mozilla is shipped with the plugin, so to launch a browser via the trial dialog 
            // lets just use what is in the users path - firefox, mozilla, or netscape - RGH
            _str user_browser = path_search("firefox","","P");
            if (user_browser :== "") {
               user_browser = path_search("mozilla", "", "P");
               if (user_browser :== "") {
                  user_browser = path_search("netscape", "", "P");
               }
            }
            set_env(VSLICKHELP_WEB_BROWSER, user_browser);
         }
      }
   }
   execmd=_replace_envvars2(execmd);

   if ( execmd == "" ) {
      _message_box( "No browser available.\n"getHowToReconfigureBrowserMsg() );
      return( 1 );
   }

   // SPECIAL CASE...
   // If filename is not specified, just build the exe command and don't
   // worry about whether or not DDE is used.
   msg := "";
   if ( filename == "" ) {
      temp1 = execmd;
      if ( parseBrowserStartCommand( temp1, execmd ) ) {
         msg = "Can't start browser with \n'"temp1"'.\n\n"getHowToReconfigureBrowserMsg();
         _message_box( msg );
         return( 1 );
      }
      return( 0 );
   }

   // If we need to override DDE, now's the time to do it
   if (overrideDDE == 0) {
      useDDE = false;
   }
   else if (overrideDDE == 1) {
      useDDE = true;
   }
   // Build:
   // 1.  DDE request and the command to start the browser, or
   // 2.  Command to start the browser and display the file.

   // DDE request and browser start command:
   if ( useDDE ) {
      // Build actual file embedded file name:
      typeless p1, p2;
      if ( parseItemParts( temp1, p1, p2 ) ) {
         _message_box( "DDE item is missing a %F.\n"getHowToReconfigureBrowserMsg() );
         return( 1 );
      }
      filename_was_quoted := ( (_last_char(p1)=='"' || _last_char(p1)=="'") && _last_char(p1)==_first_char(p2) );
      if( filename_was_quoted ) {
         // Some browsers are not tolerant (IE6) of spaces prepended to a quoted url (e.g. " http://www.slickedit.com/ "),
         // so make sure we never do that in the case of a quoted filename.
         item = p1:+filename:+p2;
      } else {
         // Make sure there is a space separating any options from the filename (e.g. '-nohome http://www.slickedit.com/')
         item = p1" "filename" "p2;
      }

      // Build browser start command:
      temp1 = execmd;
      if ( parseBrowserStartCommand( temp1, execmd ) ) {
         msg = "Can't start browser with \n'"temp1"'.\n\n"getHowToReconfigureBrowserMsg();
         _message_box( msg );
         return( 1 );
      }
      return( 0 );
   }

   // Browser start and view file, all in one command:
   temp1 = execmd;
   if ( parseBrowserAndFileStartCommand( temp1, filename, execmd ) ) {
      msg = "Can't start browser with \n'"temp1"'.\n\n"getHowToReconfigureBrowserMsg();
      _message_box( msg );
      return( 1 );
   }
   return( 0 );
}
// Desc:  Parse the (DDE) item string into two parts (separated by %F, %f, %1).
// Retn:  0 for OK, 1 or error.
static int parseItemParts( _str item, var p1, var p2 )
{
   parse item with p1 "%F" p2;
   if ( p1 != item ) return( 0 );
   parse item with p1 "%f" p2;
   if ( p1 != item ) return( 0 );
   parse item with p1 "%1" p2;
   if ( p1 != item ) return( 0 );
   p1 = item;
   p2 = "";
   return( 1 );
}
// Desc:  Extract and verify the exe path.
//     Remove any parameter specifiers: %F, %f
//     The extracted exe command may be quoted if it contains embedded spaces.
// Retn:  0 for OK, 1 for error.
static int parseBrowserStartCommand( _str cmd, _str &execmd )
{
#if 1
   // Specify a default page when see -remote option so that we don't try to start
   // a new browser (which may prompt the user for a profile).
   int status=parseBrowserAndFileStartCommand(cmd,"",execmd,SLICKEDIT_HOME);
   return(status);
#else
   //messageNwait("cmd="cmd);
   endw = "";
   temp = cmd;
   execmd = cmd;
   qtemp = _maybe_quote_filename(temp);
   for (;;) {
      //messageNwait( "b4 qtemp="qtemp );
      fn = file_match("-p "qtemp, 1 );
      if ( fn != "" ) {
         execmd = qtemp" "endw;
         //messageNwait( "a1 cmd="execmd );
         return( 0 );
      }
      fullpath = whichpath( qtemp );
      if ( (fullpath != "") && (fullpath == qtemp) ) {
         execmd = qtemp" "endw;
         //messageNwait( "a3 cmd="execmd );
         return( 0 );
      }
      w = strip_last_word( temp );
      //messageNwait( "w="w );
      if ( temp == "" ) {
         //messageNwait( "a2 cmd="execmd );
         return( 1 );
      }
      // Throw away any parameter specifiers:
      if ( !pos( "%F", w ) && !pos( "%f", w ) && !pos( "%1", w ) &&
           !pos( "-remote", w ) && !pos( "-url", w ) ) {
         if ( endw != "" ) endw = w" "endw;
         else endw = w;
      }
      //messageNwait( "endw="endw );
      qtemp = _maybe_quote_filename(temp);
   }
#endif
}
// Desc:  Verify the exe path.
//     The filename specifier (%F, %f) is replaced by the name of
//     the current buffer.
//
//     The extracted exe command may be quoted if it contains embedded spaces.
//     The buffer name is always quoted.
// Retn:  0 for OK, 1 for error.
static int parseBrowserAndFileStartCommand(_str cmd,_str filename,_str &execmd,_str remote_default_filename="")
{
#if 1
   typeless p1, p2;
   parseItemParts(cmd,p1,p2);
   _str pgmname=parse_file(p1,false);
   if( pgmname=="" ) {
      return(1);
   }
   pgmname=path_search(pgmname,"",'P');
   if( pgmname=="" ) {
      return(1);
   }
   if (_isUnix()) {
      // The URL can be exposed to the shell on unix systems, so we need to quote it so the shell
      // doesn't misinterpret characters like '&'.
      if (!_isMac()) {
         filename = '"'_maybe_unquote_filename(filename)'"';
      }
      name := _strip_filename(pgmname,'P');
      // For now, assume any browser that supports the -remote command supports
      // "-remote 'ping()'"
      if (pos(" -remote ",execmd,1) /*&& name=="mozilla" || name=="netscape"*/) {
         if (filename=="") {
            filename=remote_default_filename;
         }
         if (!_isMac()) {
            filename = '"'_maybe_unquote_filename(filename)'"';
         }
         int status=shell(_maybe_quote_filename(pgmname)" -remote 'ping()'");
         //_message_box("status="status);
         if (status) {
            p1="";
            p2="";
         }
      }
   }
   if (filename=="") {
      execmd=_maybe_quote_filename(pgmname);
      return(0);
   }
   filename_was_quoted := ( (_last_char(p1)=='"' || _last_char(p1)=="'") && _last_char(p1)==_first_char(p2) );
   if( filename_was_quoted ) {
      // Some browsers are not tolerant (IE6) of spaces prepended to a quoted url (e.g. " http://www.slickedit.com/ "),
      // so make sure we never do that in the case of a quoted filename.
      execmd=_maybe_quote_filename(pgmname)" "p1:+filename:+p2;
   } else {
      // Make sure there is a space separating any options from the filename (e.g. '-nohome http://www.slickedit.com/')
      execmd=_maybe_quote_filename(pgmname)" "p1" "filename" "p2;
   }
   //_message_box(execmd);
   return(0);
#else
   execmd = cmd;
   tempcmd=stranslate(cmd,filename,"%f","i");
   pgmname=parse_file(tempcmd,false);
   if (pgmname=="") {
      return(1);
   }
   pgmname=path_search(pgmname,"","P");
   if (pgmname=="") {
      return(1);
   }
   execmd=_maybe_quote_filename(pgmname)" "tempcmd;
   //_message_box("0 execmd="execmd);
   return(0);
#endif
}
// Desc:  Get the default values for the different browsers.
static void getDefaultBrowserInfo(int bi, var execmd, var useDDE, var app,
         var topic, var item )
{
   if ( bi == BIAUTO ) {
      getAuto( execmd, useDDE, app, topic, item );
   } else if ( bi == BICHROME ) {
      getChrome( execmd, useDDE, app, topic, item );
   } else if ( bi == BIMOZILLA ) {
      getMozilla( execmd, useDDE, app, topic, item );
   } else if ( bi == BIFIREFOX ) {
      getFirefox( execmd, useDDE, app, topic, item );
   } else if ( bi == BIIEXPLORER ) {
      getIE( execmd, useDDE, app, topic, item );
   } else if ( bi == BISAFARI ) {
      getSafari( execmd, useDDE, app, topic, item );
   } else {
      getOther( execmd, useDDE, app, topic, item );
   }
}
static _str get_system_browser_command()
{
   // Predefined list of browsers to search for and their command
   // to open a URL (%f).
   _str browser_list[][];
   browser_list._makeempty();
   i := 0;
   browser_list[i][0] = "firefox";
   browser_list[i++][1] = "'%f'";
   browser_list[i][0] = "mozilla";
   browser_list[i++][1] = "-remote 'openURL('%f')'";
   browser_list[i][0] = "netscape";
   browser_list[i++][1] = "-remote 'openURL('%f')'";

   size := browser_list._length();
   for (i = 0; i < size; ++i) {
      _str browser_path = path_search(browser_list[i][0]);
      if (browser_path != "") {
         // System browser found.
         cmd :=  browser_path" "browser_list[i][1];
         return cmd;
      }
   }
   return "";
}

static void getMozilla( var execmd, var useDDE, var app, var topic, var item)
{
   if ( unixRunning ) {
      _str browser_command = get_system_browser_command();
      if (browser_command != "") {
         execmd = browser_command;
      } else {
         execmd = "mozilla":+" -remote 'openURL(%F)'";
      }
      app = "";
      topic = "";
      item = "";
      useDDE = 0;
   } else {
      typeless value=_ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Classes\\MozillaHTML\\shell\\open\\command","");
      execmd = value;
      app = "";
      topic = "";
      item = "";
      useDDE = 0;
   }
}
static void getFirefox( var execmd, var useDDE, var app, var topic, var item)
{
   if ( unixRunning ) {
      // Our supplied Firefox cannot open long URLs with lots of GET data via the 
      // 'remote openURL' method if the browser is already open. This is a problem for
      // the Contact Product Support and Check Maintenance features. Fortunately, we can
      // get around this issue if we just pass the URL as the only argument to Firefox.
      //execmd = '"%('VSLICKHELP_WEB_BROWSER')"':+" -remote 'openURL(%F)'";
      execmd = "firefox":+" '%F'";
      app = "";
      topic = "";
      item = "";
      useDDE = 0;
   } else {
      typeless value=_ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Classes\\FirefoxHTML\\shell\\open\\command","");
      execmd = value;
      app = "";
      topic = "";
      item = "";
      useDDE = 0;
   }
}
static void getIE( var execmd, var useDDE, var app, var topic, var item )
{
   if (unixRunning) {
      if (_isMac()) {
         execmd = 'open -a "Internet Explorer" "%F"';
      } else {
         execmd = "";
      }
      app = "";
      topic = "";
      item = "";
      useDDE = 0;
      return;
   }
   typeless value=_ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Classes\\htmlfile\\shell\\open\\command","");
   execmd = value;
   app = "IExplore";
   topic = "WWW_OpenURL";

   item = '"%F",,0xFFFFFFFF,0x3,,,';
#if 0
   if (type :== "p") {
      item = '"http://%F",,0xFFFFFFFF,0x3,,,';
   } else{
      item = '"file:%F",,0xFFFFFFFF,0x3,,,,';
   }
#endif
   if (isEclipsePlugin())  {
      useDDE = 0;
   } else {
      useDDE = 1;
   }
}
static void getSafari( var execmd, var useDDE, var app, var topic, var item )
{
   execmd='open -a Safari "%F"';
   useDDE=0;
   app="";
   topic="";
   item="";
}
static void getWindowsDefaultOpenURL(var execmd, var useDDE, var app, var topic, var item)
{
   // explorer.exe http://path will correctly open the url in the default browser.
   // n.b. - explorer.exe does not understand urls with query strings unless you double quote them.
   // n.b. - explorer.exe will not open a url in the default browser unless prefixed with a protocol (e.g. http:).
   execmd = 'explorer.exe "%F"';
   useDDE = 0;
   app = "";
   topic = "";
   item = "";
}
static void getMacDefaultOpenURL(var execmd, var useDDE, var app, var topic, var item)
{
   execmd='open "%F"';
   useDDE=0;
   app="";
   topic="";
   item="";
}
static void getMacDefaultOpenFileURL(var execmd, var useDDE, var app, var topic, var item)
{
   //execmd='open "%F"';
   execmd="osascript -e 'tell application \"Safari\" to open location \"%F\"'";
   useDDE=0;
   app="";
   topic="";
   item="";
}
static void getChrome( var execmd, var useDDE, var app, var topic, var item)
{
   if ( unixRunning ) {
      if (_isMac()) {
         execmd = 'open -a "Google Chrome" "%F"';
      } else {
         execmd = "/opt/google/chrome/google-chrome '%f'";
      }
      app = "";
      topic = "";
      item = "";
      useDDE = 0;
   } else {
      // try this user-specific one first
      typeless value=_ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Classes\\ChromeHTML."_GetUserName()"\\shell\\open\\command","");
      if (value == "") {
         value=_ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Classes\\ChromeHTML\\shell\\open\\command","");
      }
      execmd = value;
      app = "";
      topic = "";
      item = "";
      useDDE = 0;
   }
}

/**
 * Checks for a default browser using xdg-mime.
 * 
 * @return _str command to use to open a URL
 */
static _str checkXdgMime()
{
   // ask xdg-mime what's up
   tmpFile := "xdg.tmp";
   shell("xdg-mime query default text/html > "tmpFile);

   // open up xdg.tmp to see if anything is there
   if (file_exists(tmpFile)) {
      _open_temp_view(tmpFile, auto tempWid, auto origWid);
      get_line(auto line);

      p_window_id = origWid;
      _delete_temp_view(tempWid);
      delete_file(tmpFile);
      // if there is something, it will be a .desktop file
      if (line != "" && pos(".desktop", line) > 0) {
         // we don't care what it says - the xdg-open command 
         // will take care of it
         return "xdg-open %f";
      }
   }

   // nothin'
   return "";
}

/**
 * Checks for a default browser using update-alternatives.
 * 
 * @return _str command to use to open a URL
 */
static _str checkUpdateAlternatives()
{
   // call update-alternatives --display to find out the settings
   execmd := "";
   tmpFile := "ua.tmp";
   shell("/usr/sbin/update-alternatives --display x-www-browser > "tmpFile);

   // open up tmpFile to see if anything is there
   if (file_exists(tmpFile)) {
      _open_temp_view(tmpFile, auto tempWid, auto origWid);

      // go through the output
      line := "";
      while (true) {
         get_line(line);
         // this catches a blank file
         if (line == "") break;

         // oh, it's so hacky
         if (pos("best", line)) {
            // find the starting /
            line = strip(line);
            slashPos := pos(FILESEP, line);
            if (slashPos) {
               // substr it down to just the path
               line = substr(line, slashPos);
               if (endsWith(line, ".")) {
                  line = substr(line, 1, length(line) - 1);
               }
               execmd = line :+ " %f";
               break;
            }
         }

         // quit when the file is over
         if (down()) break;
      }

      // tidy up
      p_window_id = origWid;
      _delete_temp_view(tempWid);
      delete_file(tmpFile);
   }

   return execmd;
}

// Desc:  Look up the Registry for browser information.
static void getAuto( var execmd, var useDDE, var app, var topic, var item )
{
   if (unixRunning) {
      if (_isMac()) {
         getMacDefaultOpenURL(execmd,useDDE,app,topic, item );
         return;
      }

      app = "";
      topic = "";
      item = "";
      useDDE = 0;

      // first try the $BROWSER env var
      execmd = get_env("BROWSER");
      if (execmd != "") {
         execmd :+= " %f";
         return;
      }

      // for linux, then try xdg-open
      execmd = checkXdgMime();
      if (execmd != "") return;


      // linux again, finally, update-alternatives
      execmd = checkUpdateAlternatives();
      if (execmd != "") return;

      // whatevs, just give them mozilla
      getMozilla(execmd,useDDE,app,topic,item);
      return;
   }

   // Windows
   getWindowsDefaultOpenURL(execmd, useDDE, app, topic, item);
}
static void getOther( var execmd, var useDDE, var app, var topic, var item)
{
   execmd = "";
   app = "";
   topic = "";
   item = "";
   useDDE = 0;
}
static void quotecmd( var execmd )
{
   //messageNwait( "b4 cmd="execmd );
   //p = pos( '"', execmd );
   //if ( p == 1 ) return;

   endw := "";
   _str temp = execmd;
   qtemp := _maybe_quote_filename(temp);
   for (;;) {
      //messageNwait( "b4 qtemp="qtemp );
      fn := file_match("-p "qtemp, 1 );
      if ( fn != "" ) {
         execmd = qtemp" "endw;
         //messageNwait( "a1 cmd="execmd );
         return;
      }
      _str w = strip_last_word( temp );
      if ( temp == "" ) {
         //messageNwait( "a2 cmd="execmd );
         return;
      }
      if ( w != "%1" && w != "\"%1\"" && w != "%F" ) {
         if ( endw != "" ) endw = w" "endw;
         else endw = w;
      }
      qtemp = _maybe_quote_filename(temp);
   }
}
// Desc:  Activate the browser and bring it to foreground.
// Retn:  0 for OK, < 0 for error.
static int activateBrowser(_str app)
{
   //messageNwait( "PREVENT CRASH... b4 _dderequest WWW_Activate app="app );
   item := "0xFFFFFFFF,0x0";
   topic := "WWW_Activate";
   old_view_id := p_window_id;
   typeless status=_dderequest("L",app,item,topic);
   p_window_id = old_view_id;
   //messageNwait( "after _dderequest status="status );
   return( status );
}
// Desc:  Start browser.
// Retn:  0 for OK, 1 for can't start browser.
static int startBrowser()
{
   // Build the start browser command:
   execmd := "";
   typeless useDDE=false;
   typeless app="";
   typeless topic="";
   typeless item="";
   if ( buildRequest( "", execmd, useDDE, app, topic, item ) ) {
      return( 1 );
   }

   // Try activating existing browser:
   int bi = def_html_info.browser[osi];
   if ( useDDE ) {
      typeless status = activateBrowser(app);
      if ( !status ) return( 0 );
   }

   // Start browser:
   quotecmd( execmd );
   if ( shell( execmd, 'A' ) ) {
      msg :=  "Can't start browser with \n'"execmd"'.\n\n"getHowToReconfigureBrowserMsg();
      _message_box(msg);
      return( 1 );
   }
   return( 0 );
}


/**
 * Saves the current buffer if necessary and runs an HTML
 * browser. This command is on the button bar by default.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */
_command int html_preview()  name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   // Make sure buffer is an HTML markup file:
   view_id := 0;
   _init_osi();
   if (!_LanguageInheritsFrom("html") && !_LanguageInheritsFrom("xml")) {
      int old_view_id = _create_temp_view( view_id );
      typeless status = startBrowser();
      _delete_temp_view( view_id );
      if ( status ) return( 1 )
      return( 0 );
   }
   _str filename = p_buf_name;

   // If buffer has been modified, verify save with the user:
   if ( p_modify ) {
      if ( save() ) return( 1 );
   }

   // View the document:
   mou_set_pointer( MP_HOUR_GLASS );
   int old_view_id = _create_temp_view( view_id );
   if ( nsViewDoc( filename ) ) {
      _message_box( "Can't preview file." );
   }
   _delete_temp_view( view_id );
   mou_set_pointer( MP_DEFAULT );
   return( 0 );
}
int _OnUpdate_html_preview(CMDUI cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }
   if (target_wid._LanguageInheritsFrom('html') || target_wid._LanguageInheritsFrom('xml')) {
      return(MF_ENABLED);
   }
   return(MF_GRAYED);
}


//---------------------------------------------------------------------
// Desc:  Check to see if tag is a standalone tag, having no matching
//     start and end component.
// Retn:  1 for yes, 0 for no.
static int isStandAloneTag( _str tag )
{
   tag=upcase(tag);
   int i;
   for ( i = 0; i < standAloneTagList._length(); i++ ) {
      if ( tag == standAloneTagList[i] ) {
         return( 1 );
      }
   }
   return( 0 );
}
// Desc:  Skip over the comment tag.  This skips over anything until -->
// Retn:  0 for OK, <0 for error.
static int skipOverCommentTag()
{
   // Move cursor to start char:
   typeless oPos = _nrseek();
   typeless status = _nrseek( oPos + 1 );
   if ( status == "" ) {
      status = _nrseek( oPos );
      return( -1 );
   }

   // Loop until found the matching end char:
   level := 0;
   status = search( "-->", "@h" );
   if ( status ) {
      _nrseek( oPos );
      return( -1 );
   }
   typeless seek_pos = _nrseek();
   _nrseek( seek_pos + 3 );
   return( 0 );
}
// Desc:  Skip over the tag.  Support embedded tags.
// Retn:  0 for OK, <0 for error.
static int skipOverTag()
{
   /*
   // Special case for comment tag:
   start = get_text( 4 );
   if ( start == "<!--" ) {
      return( skipOverCommentTag() );
   }
   */

   // Move cursor to start char:
   typeless oPos = _nrseek();
   typeless status = _nrseek( oPos + 1 );
   if ( status == "" ) {
      status = _nrseek( oPos );
      return( -1 );
   }

   // Loop until found the matching end char:
   level := 0;
   //status = search( "[<>]", "r@CK" );
   status = search( "[<>]", "rh@XCS" );
   for (;;) {
      if ( status ) {
         _nrseek( oPos );
         return( -1 );
      }
      ch := get_text_safe();
      if ( ch == ">" ) {
         if ( !level ) {
            typeless seek_pos = _nrseek();
            _nrseek( seek_pos + 1 );
            return( 0 );
         }
         level--;
      }
      if ( ch == "<" ) {
         level++;
      }
      status = repeat_search();
   }
   return( -1 );
}
// Match the VB <% and %> tag brace.
// Retn:  0 for OK, <0 for error.
static int matchVBTagBrace()
{
   typeless status=0;
   typeless oPos = _nrseek();
   if (get_text_safe(2) == "<%") {
      status = search("%>", "h@XCS");
      if (status) {
         _nrseek(oPos);
         return(-1);
      }
   } else {
      status = search("<%", "-h@XCS");
      if (status) {
         _nrseek(oPos);
         return(-1);
      }
   }
   return(0);
}
// Desc:  Extract the tag from the word at cursor.
// Retn:  tag, or "" if tag not found.
_str _html_GetTag( int noMove, int &startTag )
{
   startTag = 1;
   typeless seek_pos = _nrseek();
   typeless oPos = seek_pos;
   typeless startPos = seek_pos + 1;

   // CDATA strings can be huge (10,000 lines or more). Optimize that case here.
   cfg:=_clex_find(0,'g');
   if ((cfg==CFG_TAG || cfg==CFG_STRING) || (cfg!=CFG_COMMENT && get_text()=='<') && _LanguageInheritsFrom('xml') && _xml_in_cdata()) {
      tag:='![CDATA[';
      if ( noMove ) {
         _nrseek( oPos );
      } else {
         status := search(']]>','@h');
         if (!status) {
            p_col+=3;
            return tag;
         }
         _nrseek( oPos );
         return( "" );
      }
      return( tag );
   }
   
   // Bulletin Board Code tags use brackets
   typeless status = 0;
   if (_LanguageInheritsFrom("bbc")) {
      status = search("]", "h@XCS");
   } else {
      status = search(">", "h@XCS");
   }
   if ( status ) {
      _nrseek( oPos );
      return( "" );
   }
   seek_pos = _nrseek();
   tag := get_text_safe( seek_pos - startPos, startPos );
   is_start_and_end := _last_char(tag)=="/";
   tag=strip(tag,"T","/");
   tag = strip( tag, "L" );
   p := pos(":b|\n|\r", tag, 1, "r" );
   if ( p ) {
      tag =  substr( tag, 1, p-1);
   }
   if (!p_EmbeddedCaseSensitive) {
      // Use what the user has in their source code.
      //tag = case_html_tag( tag );
   }
   if ( noMove ) {
      status = _nrseek( oPos );
   } else {
      status = _nrseek( seek_pos + 1 );
   }
   if ( substr(tag,1,1) == "/" ) {
      tag = substr( tag, 2 );
      startTag = 0;
   } else if ( substr(tag,1,3) == "!--" ) {
      tag = "!--";
   }
   if (is_start_and_end) startTag=2;
   return( tag );
}
// Desc:  Skip to the beginning of the next tag.
// Retn:  0 for OK, <0 for error.
static int skipToNextTag()
{
   // Bulletin Board Code tags use brackets
   typeless oPos = _nrseek();
   status := 0;
   if (_LanguageInheritsFrom("bbc")) {
      status = search( "[", "h@XCS" );
   } else {
      status = search( "<", "h@XCS" );
   }
   if ( status ) {
      _nrseek( oPos );
      return( -1 );
   }
   return( 0 );
}
// Desc:  Skip to the beginning of the previous tag.
// Retn:  0 for OK, <0 for error.
static int skipToPrevTag()
{
   level := 0;
   typeless oPos = _nrseek();
   typeless status = _nrseek( oPos - 1 );
   if ( status == "" ) {
      status = _nrseek( oPos );
      return( -1 );
   }

   // Bulletin Board Code tags use brackets
   if (_LanguageInheritsFrom("bbc")) {
      status = search( "[\\[\\]]", "-rh@XCS" );
   } else {
      status = search( "[<>]", "-rh@XCS" );
   }

   for (;;) {
      if ( status ) {
         _nrseek( oPos );
         return( -1 );
      }
      ch := get_text_safe();
      if ( _LanguageInheritsFrom("bbc") && ch == "]" ) {
         level++;
      } else if ( ch == ">" ) {
         level++;
      } else {
         level--;
         if ( !level ) {
            return( 0 );
         }
      }
      status = repeat_search();
   }
   return( -1 );
}

// Desc:  Find the matching tag that after this one.
//     The cursor is placed at the start of the matching tag.
// Retn:  0 for match found, <0 for not found.
static int matchTagForward( _str ktag, int cursorAtEndTag, int pmatch_max_diff_ksize=MAXINT,int pmatch_max_level=MAXINT,bool canTimeout=true)
{
   int status;
   int level;

   ktag=_escape_re_chars(ktag);
   //messageNwait("h0 ktag="ktag);
   level = 0;
   //skipOverTag();
   for (;;) {
      // Bulletin Board Code tags use brackets
      _str search_str;
      if (_LanguageInheritsFrom("bbc")) {
         search_str = "\\[[ \t]@(":+ktag:+"|/":+ktag:+")";
      } else {
         search_str = "\\<[ \t]@(":+ktag:+'(\P{isXMLNameChar}|$)':+"|/":+ktag:+'(\P{isXMLNameChar}|$)':+")";
      }
      //messageNwait("search_str="search_str);
      //status = search(search_str, "ri@CK");
      status = search(search_str, "rih@XCS");
      if (status) return(-1);
      _str ch;
      int startTag;
      ch = _html_GetTag(1, startTag);
      //messageNwait("ch="ch" startTag="startTag);
      if (!startTag) {  // Found ending tag
         --level;
         if (level<0) {
            // We are lost
            return(-1);
         }
         if (!level) {
            // Bulletin Board Code tags use brackets
            if (_LanguageInheritsFrom("bbc")) {
               status = search("[", "-h@XCS");  // position the text cursor at the start of the tag
            } else {
               status = search("<", "-h@XCS");  // position the text cursor at the start of the tag
            }
            return(0);
         }
         // Bulletin Board Code tags use brackets
         if (_LanguageInheritsFrom("bbc")) {
            status = search("]", "@hXCS");  // skip to the end of the tag
         } else {
            status = search(">", "@hXCS");  // skip to the end of the tag
         }
         if (status) return(-1);
      } else if(startTag==1) {  // Nested tag
         ++level;
         if (level > pmatch_max_level) {
            // We are in too deep
            return(-1);
         }
         if (canTimeout && _CheckTimeout()) {
            // We hit our timeout
            return(-1);
         }
         // Bulletin Board Code tags use brackets
         if (_LanguageInheritsFrom("bbc")) {
            status = search("]", "@hXCS");  // skip to the end of the tag
         } else {
            status = search(">", "@hXCS");  // skip to the end of the tag
         }
         if (status) return(-1);
      } else if (startTag==2) {
         if (!level) {
            // Bulletin Board Code tags use brackets
            if (_LanguageInheritsFrom("bbc")) {
               status = search("[", "-@hXCS");  // position the text cursor at the start of the tag
            } else {
               status = search("<", "-@hXCS");  // position the text cursor at the start of the tag
            }
            return(0);
         }

         // Bulletin Board Code tags use brackets
         if (_LanguageInheritsFrom("bbc")) {
            status = search("]", "@hXCS");  // skip to the end of the tag
         } else {
            status = search(">", "@hXCS");  // skip to the end of the tag
         }
         if (status) return(-1);
      }
   }
   return(-1);
}
int _html_matchTagBackward( _str ktag, int pmatch_max_diff_ksize=MAXINT, int pmatch_max_level=MAXINT,bool canTimeout=true)
{
   int status;
   int level;

   ktag=_escape_re_chars(ktag);
   level = 0;

   // Bulletin Board Code tags use brackets
   _str search_str;
   if (_LanguageInheritsFrom("bbc")) {
      search_str = '\[(':+ktag:+'|/':+ktag:+')([ \t/\]]|$)';
   } else {
      search_str = '<(':+ktag:+'|/':+ktag:+')([ \t/>]|$)';
   }

   for (;;) {
      status = search(search_str, "-ri@hXCS");
      if (status) return(-1);
      //status = search(search_str, "-ri@CK");
      _str ch;
      int startTag;
      ch = _html_GetTag(1, startTag);
      if (!startTag) {  // Found ending tag.  Nested tag for reverse search
         ++level;
         if (level > pmatch_max_level) {
            // We are in too deep
            return(-1);
         }
         if (canTimeout && _CheckTimeout()) {
            // We hit our timeout
            return(-1);
         }
         // Bulletin Board Code tags use brackets
         if (_LanguageInheritsFrom("bbc")) {
            status = search("]", "-@hXCS");  // skip to the end of the previous tag
         } else {
            status = search(">", "-@hXCS");  // skip to the end of the previous tag
         }
         if (status) return(-1);
      } else if (startTag==1) {
         --level;
         if (level<0) {
            // We are lost
            return(-1);
         }
         if (canTimeout && _CheckTimeout()) {
            // We hit our timeout
            return(-1);
         }
         if (!level) {
            return(0);  // found matching tag and cursor also already at the beginning of the tag
         }
         // Bulletin Board Code tags use brackets
         if (_LanguageInheritsFrom("bbc")) {
            status = search("]", "-@hXCS");  // skip to the end of the previous tag
         } else {
            status = search(">", "-@hXCS");  // skip to the end of the previous tag
         }
         if (status) return(-1);
      } else {
         if (!level) {
            // We are lost
            return(-1);
         }
         // Bulletin Board Code tags use brackets
         if (_LanguageInheritsFrom("bbc")) {
            status = search("]", "-@hXCS");  // skip to the end of the previous tag
         } else {
            status = search(">", "-@hXCS");  // skip to the end of the previous tag
         }
         if (status) return(-1);
      }
   }
   return(-1);
}

// Desc:  Go to the matching tag.  If this is the end tag, go to the start tag,
//     and vice versa.
// Retn:  0 for match found, -1 for not found, -2 for standalone tag (no matching
//        start/end pair).
static int matchTag(int cursorAtEndTag, _str &direction, int pmatch_max_diff_ksize=MAXINT, int pmatch_max_level=MAXINT, bool canTimeout=true)
{
   int startTag;
   _str tag = _html_GetTag( 1, startTag );
   if ( tag == "" ) {
      return( -1 );
   }
   if ( tag == "!--" || tag=="![CDATA[") {
      return( -3 );
   }
   if ( !_LanguageInheritsFrom("xml") && isStandAloneTag(tag) ) {
      return( -2 );
   }
   typeless status=0;
   if ( startTag ) {
      status = matchTagForward( tag, cursorAtEndTag, pmatch_max_diff_ksize, pmatch_max_level,canTimeout);
      direction = "F";
   } else {
      status = _html_matchTagBackward( tag, pmatch_max_diff_ksize, pmatch_max_level,canTimeout);
      direction = "B";
   }
   return( status );
}

long matchTagOffset(_str ktag, int cursorAtEndTag) {
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
   orig_offset := _QROffset();
   returnVal := 0L;


   restore_search(s1,s2,s3,s4,s5);
   _GoToROffset(orig_offset);
   return returnVal;
}

// Desc:  Find the start of the comment tag from the end of the tag.
//     Skip over everything until <!--
// Retn:  0 for OK, <0 for error.
static int findStartCommentTag()
{
   typeless oPos = _nrseek();
   status := search( "<!--", "-@h" );
   if ( status ) {
      _nrseek( oPos );
      return( -1 );
   }
   return( 0 );
}

int findStartTag2(){
   return findStartTag();
}
// Only should be called if in CFG_STRING/CFG_TAG color or if on < before tag name.
bool _xml_in_cdata() {
   typeless p;
   save_pos(p);
   status:=search('<!\[CDATA\[|<','-rh@');
   if (!status) {
      if (match_length()==1) {
         cfg:=_clex_find(0,'g');
         if (cfg==CFG_STRING) {
            // Must be in CDATA since XML does not allow < in attribute value string.
            status=search('<![CDATA[','-h@xcs');
            if (!status) {
               return true;
            }
         }
         restore_pos(p);
         return false;
      }
      return true;
   }
   restore_pos(p);
   return false;
}

// Desc:  Find the start of a tag.  If already on a tag, do nothing.
// Retn:  0 for OK, <0 for error.
static int findStartTag()
{
   // Look forward for end tag:
   typeless oPos = _nrseek();

   // Bulletin Board Code tags use brackets
   status := 0;
   if (_LanguageInheritsFrom("bbc")) {
      status = search( "[\\[\\]]", "rh@XCS" );
   } else {
      cfg:=_clex_find(0,'g');
      // Special code for handling very large cdata string.
      if ((cfg==CFG_TAG || cfg==CFG_STRING) && _LanguageInheritsFrom('xml') && _xml_in_cdata()) {
         return 1;
      /*} else if (cfg==CFG_TAG || cfg==CFG_COMMENT) {
         typeless p;
         save_pos(p);
         status=search('<!--','-rh@');
         restore_pos(p);
         if (!status && match_length()) {
             
         } else {
            status = search( "[<>]", "rh@XCS" );
         }   */
      } else {
         status = search( "[<>]", "rh@XCS" );
      }
   }
   if ( status ) {
      _nrseek( oPos );
      return( -1 );
   }
   typeless seek_pos=0;
   ch := get_text_safe();
   if ( ch == ">" || (_LanguageInheritsFrom("bbc") && ch == "]")) {
      seek_pos = _nrseek();
      status = _nrseek( seek_pos - 1 );
      if ( status == "" ) {
         _nrseek( oPos );
         return( -1 );
      }
      if ( get_text_safe() == "-" ) {
         status = _nrseek( seek_pos - 2 );
         if ( status == "" ) {
            _nrseek( oPos );
            return( -1 );
         }
         if ( get_text_safe() == "-" ) {
            return( findStartCommentTag() );
         }
      }
   } else {
      _nrseek( oPos );
   }

   // Look backward for start tag:
   typeless startTag=0;
   tag := "";
   start := "";
   taglevel := 0;
   level := 0;
   for (;;) {
      // Bulletin Board Code tags use brackets
      if (_LanguageInheritsFrom("bbc")) {
         status = search( "[\\[\\]]", "-rh@XCS" );
      } else {
         status = search( "[<>]", "-rh@XCS" );
      }
      if ( status ) {
         _nrseek( oPos );
         return( -1 );
      }
      ch = get_text_safe();
      if ( ch == ">" || ch == "]") {
         _nrseek( oPos );
         return( -1 );

         seek_pos = _nrseek();
         status = _nrseek( seek_pos - 2 );
         if ( status == "" ) {
            _nrseek( oPos );
            return( -1 );
         }
         start = get_text_safe( 3 );
         if ( start == "-->" ) {
            status = findStartCommentTag();
         } else {
            _nrseek( seek_pos );
            level++;
         }
      } else if ( ch == "<" || ch == "[") {
         // Found start of some sort of nested tag <tag ... <...>   >
         if ( !level ) {
            return( 0 );
         }
         level--;
         // Skip over standalone tag:
         tag = _html_GetTag( 1, startTag );
         //messageNwait( "h1 tag="tag" startTag="startTag );
         if ( tag == "!--" ) {
            return( 0 );
         }
         if ( !isStandAloneTag(tag) ) {
            if ( startTag ) {
               if ( !taglevel ) {
                  return( 0 );
               }
               taglevel--;
            } else {
               taglevel++;
            }
         }
      }
      // Have to manually go back one and restart search because _html_GetTag()
      // also uses search() and that messes up the repeat_search().
      seek_pos = _nrseek();
      status = _nrseek( seek_pos - 1 );
      if ( status == "" ) {
         _nrseek( oPos );
         return( -1 );
      }
   }
   return( -1 );
}

// Desc:  Check to see if the specified tag is considered to be
//        part of the P tag.
// Retn:  1 for yes, 0 for no.
static int isTagAllowedInPtag(_str tag)
{
   tag=upcase(tag);
   int i;
   for (i=0; i<tagAllowedInPTag._length(); i++) {
      if (tag == tagAllowedInPTag[i]) {
         return(1);
      }
   }
   return(0);
}

// Desc:  Find a "reasonable" end for the <P> tag.
//        A reasonable end is another tag that terminates a P tag.
// Retn:  0 for OK, -1 for error
static int scanForEndPara()
{
   int startLine;
   startLine = p_line;

   int status, startOfTag, savepos;
   _str tag;
   while (1) {
      status = skipToNextTag();
      if (status) {
         return(-1);
      }
      savepos = _nrseek();
      tag = _html_GetTag(0, startOfTag);
      if (tag == "") {
         return(-1);
      }
      if (!isTagAllowedInPtag(tag)) {
         _nrseek(savepos);
         status = search("\n", "-rh@XCS");
         _nrseek(_nrseek()-1);
         return(0);
      }
   }
   return(0);
}
int _bbc_find_matching_word(bool quiet,int pmatch_max_diff_ksize=MAXINT,int pmatch_max_level=MAXINT)
{
   return(htool_matchtag(quiet,pmatch_max_diff_ksize,pmatch_max_level));
}
int _html_find_matching_word(bool quiet,int pmatch_max_diff_ksize=MAXINT,int pmatch_max_level=MAXINT)
{
   return(htool_matchtag(quiet,pmatch_max_diff_ksize,pmatch_max_level));
}
//---------------------------------------------------------------------
// Desc:  Match the tag component.
//
//        <FONT FACE="ITC Officina Sans Bold" POINT-SIZE=9>Hello</FONT>
//        ^                                                     ^
// Retn:  0 for OK, -1 for error.
_command int htool_matchtag(bool quiet=false,int pmatch_max_diff_ksize=MAXINT,int pmatch_max_level=MAXINT)  name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   sc.lang.ScopedTimeoutGuard timeout(def_match_paren_timeout);
   lang := p_LangId;
   if (!_LanguageInheritsFrom("html",lang) && !_LanguageInheritsFrom("xml",lang) && !_LanguageInheritsFrom("bbc", lang)) {
      if (!quiet) {
         message( "Matching HTML/XML tag pair only works with HTML/XML files." );
      }
      return( -1 );
   }

   if( _expand_tabsc()=="" ) {
      // Empty line
      if (!quiet) {
         message( "Matching HTML/XML tag pair not found!" );
      }
      return(0);
   }

   // Remember the position:
   save_pos( cs_ori_position );
   oPos := _nrseek();

   // Special case for VB code tag braces <% and %>.
   status := 0;
   if (get_text_safe(2) == "<%" || get_text_safe(2) == "%>") {
      status = matchVBTagBrace();
      if (status) {
         restore_pos(cs_ori_position);
         _nrseek(oPos);
         if (!quiet) {
            message("Matching <% %> not found!");
         }
      }
      return(0);
   }

   status = findStartTag();
   if (status < 0) {
      restore_pos( cs_ori_position );
      _nrseek( oPos );
      if (!quiet) {
         message( "Matching HTML/XML tag pair not found!" );
      }
      return 0;
   }

   oLine := p_line; 
   oCol := p_col;

   // Find the matching tag:
   status = matchTag(0, auto direction, pmatch_max_diff_ksize, pmatch_max_level, canTimeout:true);
   if ( status ) {
      restore_pos( cs_ori_position );
      _nrseek( oPos );
      if (!quiet) {
         message( "Matching HTML/XML tag pair not found!" );
      }
   }
   return 0;
}

// Desc:  Select the tag component.
//
//        <FONT FACE="ITC Officina Sans Bold" POINT-SIZE=9>Hello</FONT>
//        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
_command int htool_selectcomp()  name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   lang := p_LangId;
   if (!_LanguageInheritsFrom("html",lang) && !_LanguageInheritsFrom("xml",lang)) {
      message( "Selecting HTML tag component only works with HTML files." );
      return( -1 );
   }

   // Remember the position:
   save_pos( cs_ori_position );
   typeless oPos = _nrseek();

   findStartTag();
   oLine := p_line; 
   oCol := p_col;
   skipOverTag();

   // Tag found, select the text between the start tag and the end tag:
   temp_line := p_line; 
   temp_col := p_col;
   deselect();
   _str persistent=(def_persistent_select=="Y")?"P":"";
   mstyle := "EN"persistent;

   // Restore the original position before starting selection:
   // This prevents the 'jumping' of the view.
   restore_pos( cs_ori_position );

   // Select text:
   if ( temp_line != oLine ) {
      // Selected text spans multiple lines, do line selection:
      p_line = oLine; p_col = oCol;
      _select_line("",mstyle);
      p_line = temp_line; p_col = temp_col;
      _select_line("",mstyle);
   } else {
      // Selected text spans a single line, do character selection:
      p_line = oLine; p_col = oCol;
      _select_char("",mstyle);
      p_line = temp_line; p_col = temp_col;
      _select_char("",mstyle);
   }
   return( 0 );
}

// Desc:  Find the start and ending lines for the current tag.
// Retn:  0 for found, -1 for not found or error.
int htool_selecttag2(int & startLine, int & startCol, int & endLine, int & endCol)
{
   int startTagPos,oPos;
   typeless seek_pos=0;

   oPos = _nrseek();
   findStartTag();
   startTagPos = _nrseek();
   oLine := p_line; 
   oCol := p_col;

   // Find the matching tag:
   status := matchTag(1, auto direction, canTimeout:false);
   if (status == -1) {  // match not found
      isXml := _LanguageInheritsFrom("html", p_LangId);
      // Special case for P tag:
      // We treat the P tag special because it may and may not have
      // its matching /P.
      int startOfTag;
      _str tag;
      _nrseek(startTagPos);
      tag = _html_GetTag(0, startOfTag);

      // When we find a <P> without matching </P>,
      // scan for the next blank line or next <P> tag.
      if (!isXml && strieq(tag,"P")) {
         status = scanForEndPara();
         if (status) {
            _nrseek( oPos );
            return( -1 );
         }
      } else {
         _nrseek( oPos );
         return( -1 );
      }
   } else if (status == -2) {  // found stand alone tag
      startLine = oLine; startCol = oCol;
      //status = search(">", "r@CK");  // skip to the end of the tag
      status = search(">", "rh@XCS");  // skip to the end of the tag
      if (status) return(-1);
      seek_pos = _nrseek();
      if (_nrseek(seek_pos + 1) == "") return(-1);
   } else {
      if ( direction == "B" ) {
         int temp_line = oLine; 
         int temp_col = oCol;
         oLine = p_line; oCol = p_col;
         p_line = temp_line; 
         p_col = temp_col;
      }
      //status = search(">", "r@CK");  // skip to the end of the tag
      status = search(">", "rh@XCS");  // skip to the end of the tag
      if (status) return(-1);
      seek_pos = _nrseek();
      if (_nrseek(seek_pos + 1) == "") return(-1);
   }

   // Tag found, select the text between the start tag and the end tag:
   temp_line := p_line; 
   temp_col := p_col;

   // Select text:
   startLine = oLine; startCol = oCol;
   endLine = temp_line; endCol = temp_col;
   if ( temp_line == oLine ) {
      if (endCol > 1) endCol--;
   }
   return( 0 );
}

// Desc:  Expand the selected HTML component to include the outer tag.
// Retn:  0 for OK, -1 for can not further expand.
int htool_expandsel(int & startLine, int & startCol, int & endLine, int & endCol)
{
   // Skip to the next tag:
   if (skipToNextTag() < 0) {
      return(-1);
   }

   countPtag := 0;
   isXml := _LanguageInheritsFrom("html", p_LangId);

   // Find the next ending tag that does not have a matching starting tag:
   // If found, this is the ending of the tag that encloses the currently
   // selected tag.
   while (1) {
      // Found the ending of a tag:
      startTag := 0;
      tag := _html_GetTag(1, startTag);

      // Special case for P and /P tags:
      if (!isXml && strieq(tag,"P")) {
         // Count the nesting level.  If we find an extra /P, this means
         // that we are inside a P and /P pair:
         if (startTag) {
            countPtag++;
         } else {
            countPtag--;
         }
         if (countPtag < 0) {  // inside a P /P pair
            break;
         }

         // Skip over the P tag:
         seek_pos := _nrseek();
         if (_nrseek(seek_pos + 1) == "") return(-1);
         if (skipToNextTag() < 0) return(-1);
         continue;
      }

      // If found an end tag (/XXX), we found the next nesting level:
      if (!startTag) break;

      // Skip over stand-alone tags:
      if (isStandAloneTag(tag)) {
         seek_pos := _nrseek();
         if (_nrseek(seek_pos + 1) == "") return(-1);
         if (skipToNextTag() < 0) return(-1);
         continue;
      }

      // This is the start of a tag, jump to its matching end:
      // Find the matching end tag:
      status := matchTag(0, auto direction, canTimeout:false);
      if (status == -1) return(-1);  // matching ending tag is not found! Give up.

      // Found stand-alone tag or found the matching ending tag, just skip over it:
      seek_pos := _nrseek();
      if (_nrseek(seek_pos + 1) == "") return(-1);
      if (skipToNextTag() < 0) return(-1);
   }

   // Select this new tag:
   return(htool_selecttag2(startLine, startCol, endLine, endCol));
}

_command void goto_slickedit() name_info(','VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   goto_url(SLICKEDIT_SUPPORT);
}

_command void goto_slickedit_forum() name_info(',')
{
   goto_url(SLICKEDIT_FORUM);
}

_command void goto_faq() name_info(',')
{
   goto_url(SLICKEDIT_FAQ);
}

/**
 * Prompt user with online registration dialog.
 * 
 * @param arg1 (optional). Command line arguments passed to the
 *             online registration dialog. Defaults to "".
 *             Example: '-autorun' will only display the oneline
 *             registration dialog if the major/minor version
 *             has changed (i.e. an upgrade).
 */
_command void online_registration(_str arg1="") name_info(','VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   //goto_url("www.slickedit.com/register.htm");
   path := editor_name('P');
   path :+= "vsreg.ex";
   if( !file_exists(path) ) {
      // check if macros/vsreg.e exists (slickedit/internal development)
      path = absolute(_getSlickEditInstallPath());
      _maybe_append_filesep(path);
      path :+= "macros" FILESEP "vsreg.e";
      _str msg=get_message(VSREG_MACRO_NOT_FOUND_RC);
      if (file_exists(path)) {
         sticky_message(msg);
      } else {
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      }
      return;
   }
   cmdline := _maybe_quote_filename(path);
   if( arg1!="" ) {
      cmdline :+= " ":+arg1;
   }
   if (_isUnix()) {
      cmdline="xcom ":+cmdline;
   }
   execute(cmdline);
}
/**
 * Displays URL in Web browser.
 * 
 * @categories File_Functions
 * @param webpage                URL to go to
 * @param UseHelpBrowser         whether to use the help browser 
 *                               instead of the user's specified
 *                               browser.  As of SE2014, we no
 *                               longer use a different browser
 *                               for the help, but we left the
 *                               parameter in for fun
 * @param overrideDDE            If -1, the user's preference 
 * or using DDE is honored. If 0, DDE is not used in this case. 
 * If 1, DDE is used. 
 * 
 * @see open_url
 * @see open_url_in_assoc_app
 */
_command int goto_url(_str webpage="",bool UseHelpBrowser=false, int overrideDDE=-1) name_info(','VSARG2_MARK)
{
   start_col := 0;
   end_col := 0;
   line := "";
   if (webpage=="") {
      if (select_active()) {
         filter_init();
         filter_get_string(webpage);
         filter_restore_pos();
      } else {
         search('^|[ \t]','@rh->');  //Go back for the a space
         start_col=p_col;
         search('$|[ \t]','@rh<');   //Get to the end of the page.
         end_col=p_col;
         get_line(line);
         webpage=substr(line,start_col, end_col-start_col);
      }
      if (webpage=="") {
         // Maybe should call message() here.
         return(0);
      }
   }

   int old_browser=def_html_info.browser[OSIUNIX];
   if (UseHelpBrowser) {
      _str machineType = machine();
      if (_isMac()) {
         def_html_info.browser[OSIUNIX] = BIAUTO;
      } else if (machineType == "WINDOWS") {
         def_html_info.browser[OSIUNIX] = BIIEXPLORER;
      } else {
         def_html_info.browser[OSIUNIX] = BIMOZILLA;
      }
   }
   _init_osi();

   // View the document:
   mou_set_pointer( MP_HOUR_GLASS );
   view_id := 0;
   int old_view_id = _create_temp_view( view_id );
   int status=nsViewDoc( webpage, overrideDDE );
   // Good error message was already displayed
   _delete_temp_view( view_id );
   mou_set_pointer( MP_DEFAULT );

   if (UseHelpBrowser) {
      def_html_info.browser[OSIUNIX]=old_browser;
   }
   return(status);
}

/**
 * Callback indicating that the HTML beautify
 * settings have changed.  Reloads gtagcache_info.
 *
 * @param ext
 * @param scheme_name
 */
void _hformatSaveScheme_update(_str langId, _str scheme_name)
{
   gtagcache_info= -1;
   gtagcache_info_lang="";
   gtagcache_info_buf_name='';
}

_command void html_tab() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_ICON|VSARG2_LASTKEY|VSARG2_MARK)
{
   embedded_key();
}
_command void html_key() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_ICON|VSARG2_LASTKEY)
{
   embedded_key();
}

/**
 * Handle ENTER key in HTML editing mode.
 * This attempts to intelligently indent the next
 * line, by either indenting to the current indent
 * level, or indenting one more level deep.
 */
_command void html_enter() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_ICON|VSARG2_LASTKEY)
{
   if (ispf_common_enter()) return;
   if (command_state() || (p_active_form.p_name == "_javadoc_form")) {
      call_root_key(ENTER);
      return;
   }

   if (p_window_state :== 'I' ||
       p_SyntaxIndent<0 ||
       p_indent_style != INDENT_SMART ||
       _in_comment(true) ||
       !_html_tags_loaded() ||
       _html_expand_enter())
   {
      orig_values := null;
      int embedded_status=_EmbeddedStart(orig_values);
      if (embedded_status==1) {
         _macro('m',0);
         call_key(last_event(), "\1", "L");
         _EmbeddedEnd(orig_values);
         return; // Processing done for this key
      }
      call_root_key(ENTER);
   } else if (_argument=="") {
      _undo('S');
   }
}
bool _html_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}
bool _bbc_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return return_true_if_uses_syntax_indent_property;
}

/**
 * Inserts a new line and indents based on the indentation
 * level indicated.  Returns 0 if successful.
 */
static int indent_to_level(typeless enter_name, int indent_column = 0)
{
   if (enter_name !="nosplit-insert-line") {
      lf:=_lineflags();
      _str textAfterCursor=_expand_tabsc(p_col,-1,'S');
      if (textAfterCursor!="" || (lf&EOL_MISSING_LF)) {
         _split_line();down();
         p_col=1;_insert_text(indent_string(indent_column-1));
         return(0);
      }
   }
   if (LanguageSettings.getInsertRealIndent(p_LangId)) {
      insert_line(indent_string(indent_column-1));
   } else {
      insert_line("");
      p_col = indent_column;
   }
   return(0);
}

static bool ant_expand_space(){
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_ind := p_SyntaxIndent;
   line := "";
   get_line(line);
   line=strip(line,'T');
   orig_word := lowcase(strip(line));
   if ( p_col!=text_col(_rawText(line))+1 ) {
      return false;
   }
   _str key=min_abbrev2(orig_word,ant_space_words,"","");
   if (key == "") {
      last_event(" ");
      return false;
   }
   parse key with auto word ">" auto rest;
   line=substr(line,1,length(line)-length(orig_word)):+word;
   int width=text_col(_rawText(line),_rawLength(line)-_rawLength(word)+1,'i')-1;
   clear_hotspots();
   switch (word) {
   case "<project": {
      new_line :=  line :+ " name=\"\" basedir=\".\" default=\"\">";
      replace_line(new_line);
      end_line();
      p_col -= 2;
      add_hotspot();
      p_col -= 12;
      add_hotspot();
      p_col -= 11;
      add_hotspot();
      _save_pos2(auto p);
      insert_line(indent_string(width + syntax_ind));
      finish_ant_expansion();
      _restore_pos2(p);
      break;
   }
   case "<target": {
      depends := pos("depend",key) > 0 ? true : false;
      new_line :=  line :+ " name=\"\"";
      if (depends) {
         new_line :+= " depends=\"\">";
      } else {
         new_line :+= ">";
      }
      replace_line(new_line);
      end_line();
      p_col -= 2;
      add_hotspot();
      if (depends) {
         p_col -= 11;
         add_hotspot();
      }
      _save_pos2(auto p);
      insert_line(indent_string(width + syntax_ind));
      finish_ant_expansion();
      _restore_pos2(p);
      break;
   }
   case "<macrodef": {
      new_line :=  line :+ " name=\"\">";
      replace_line(new_line);
      end_line();
      p_col -= 2;
      add_hotspot();
      _save_pos2(auto p);
      insert_line(indent_string(width + syntax_ind));
      finish_ant_expansion();
      _restore_pos2(p);
      break;
   }
   case "<jar": {
      new_line :=  line :+ " destfile=\"\"";
      multiline := pos("params",key) > 0 ? false : true;
      if (multiline) {
         new_line :+= ">";
      } else {
         new_line :+= "/>";
      }
      replace_line(new_line);
      end_line();
      if (multiline) {
         p_col -= 2;
      } else {
         p_col -= 3;
      }
      add_hotspot();
      if (multiline) {
         _save_pos2(auto p);
         insert_line(indent_string(width + syntax_ind));
         finish_ant_expansion();
         _restore_pos2(p);
      }
      break;
   }
   case "<exec": {
      new_line :=  line :+ " executable=\"\">";
      replace_line(new_line);
      end_line();
      p_col -= 2;
      add_hotspot();
      _save_pos2(auto p);
      insert_line(indent_string(width + syntax_ind));
      finish_ant_expansion();
      _restore_pos2(p);
      break;
   }
   case "<mkdir": {
      new_line :=  line :+ " dir=\"\"/>";
      replace_line(new_line);
      end_line();
      p_col -= 3;
      add_hotspot();
      break;
   }
   case "<property": {
      file := pos("file",key) > 0 ? true : false;
      location := pos("location",key) > 0 ? true : false;
      _str new_line = line;
      if (file) {
         new_line :+= " file=\"\"/>"; 
      } else if (location) {
         new_line :+= " name=\"\" location=\"\"/>"; 
      } else {
         new_line :+= " name=\"\" value=\"\"/>"; 
      }
      replace_line(new_line);
      end_line();
      p_col-=3;
      add_hotspot();
      if (location) {
         p_col -= 12;
         add_hotspot();
      } else if (!file) {
         p_col -= 9;
         add_hotspot();
      }
      break;
   }
   case "<antcall": {
      params := pos("params",key) > 0 ? true : false;
      _str new_line = line;
      if (params) {
         new_line :+= " target=\"\">";
      } else {
         new_line :+= " target=\"\"/>";
      }
      replace_line(new_line);
      end_line();
      if (params) {
         p_col -= 2;
      } else {
         p_col -= 3;
      }
      add_hotspot();
      if (params) {
         _save_pos2(auto p);
         insert_line(indent_string(width + syntax_ind) :+ "<param name=\"\" value=\"\"/>");
         end_line();
         p_col -= 12;
         add_hotspot();
         p_col += 9;
         add_hotspot();
         finish_ant_expansion();
         _restore_pos2(p);
      }
      break;
   }
   case "<import": {
      new_line :=  line :+ " file=\"\"/>";
      replace_line(new_line);
      end_line();
      p_col -= 3;
      break;
   }
   case "<echo": {
      new_line :=  line :+ " message=\"\"/>";
      replace_line(new_line);
      end_line();
      p_col -= 3;
      break;
   }
   case "<delete": {
      ref := pos("reference",key) > 0 ? true : false;
      new_line :=  line :+ ">";
      replace_line(new_line);
      if (ref) {
         insert_line(indent_string(width + syntax_ind) :+ "<fileset refid=\"\"/>");
         p_col -= 3;
         add_hotspot();
         _save_pos2(auto p);
         insert_line("<");
         xml_slash();
         _restore_pos2(p);
      } else {
         insert_line(indent_string(width + syntax_ind) :+ "<fileset dir=\"\">");
         p_col -= 2;
         add_hotspot();
         _save_pos2(auto p);
         insert_line(indent_string(width + syntax_ind*2) :+ "<include name=\"\"/>");
         p_col -= 3;
         add_hotspot();
         insert_line(indent_string(width + syntax_ind*2) :+ "<exclude name=\"\"/>");
         p_col -= 3;
         add_hotspot();
         insert_line("<");
         xml_slash();
         insert_line("<");
         xml_slash();
         _restore_pos2(p);
      }
      break;
   }
   case "<fileset": {
      new_line :=  line :+ " dir=\"\" id=\"\">";
      replace_line(new_line);
      end_line();
      p_col -= 2;
      add_hotspot();
      p_col -= 6;
      add_hotspot();
      _save_pos2(auto p);
      insert_line(indent_string(width + syntax_ind) :+ "<include name=\"\"/>");
      p_col -= 3;
      add_hotspot();
      insert_line(indent_string(width + syntax_ind) :+ "<exclude name=\"\"/>");
      p_col -= 3;
      add_hotspot();
      insert_line("<");
      xml_slash();
      _restore_pos2(p);
      break;
   }
   default:
      return false;
   }
   show_hotspots();

   // let the user know we did something fancy
   notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);

   return true;
}

static void finish_ant_expansion(){
   add_hotspot();
   insert_line("<");
   xml_slash();
}

/**
 * HTML expansion on enter.
 * Returns false if we are done, true otherwise.
 *
 * @return
 */
bool _html_expand_enter()
{  
   if (XW_doEnter()) {
      return false;
   }
   if (p_EmbeddedLexerName != "") {
      return(true);
   }

   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_ind := p_SyntaxIndent;

   save_pos(auto p);
   _str enter_name = name_on_key(ENTER);
   line := "";
   get_line(line);
   while( line=="" && !_on_line0()) {
      up();
      get_line(line);
   }
   _first_non_blank();
   cur_indent_level := p_col;
   restore_pos(p);
   if (enter_name == "nosplit-insert-line") {
      _end_line();
   } else if (enter_name == "maybe-split-insert-line") {
      if (!_insert_state()) {
         if (down()){
            insert_line("");
         }
         p_col = 1;
         return(false);
      }
   }
   int indent_col = html_indent_col(cur_indent_level);
   if (indent_col < cur_indent_level) {
      indent_col = cur_indent_level;
   }
   restore_pos(p);
   int status = indent_to_level(enter_name,indent_col);
   return(status != 0);
}

/**
 * Returns the column where the next line should be indented to.
 *
 * @return
 */
int html_indent_col(int non_blank_col, bool paste_open_block = false)
{
   _str tag_stack[];
   save_pos(auto p);
   // figure out the current indentation level
   current_tag := "";
   end_tag := "";
   orig_col := p_col;
   indent_col := non_blank_col;
   p_col = orig_col;
   for (attempts:=0; attempts < 1000; attempts++) {
      current_tag = _html_goto_previous_tag();
      if (current_tag == "") {
         // one way or another, there are not any more tags to be found
         break;
      }
      end_tag = (substr(current_tag,1,1)=="/");
      if (end_tag) {
         current_tag = substr(current_tag,2);
      }
      if (_html_get_attr_val(current_tag,"standalone") && _html_get_attr_val(current_tag,"indent_content")) {
         // make sure that this is not an end tag
         if (end_tag) {
            // put the end tag on the stack
            tag_stack :+= current_tag;
         } else {
            if (tag_stack._length() == 0) {
               // we are done
               _first_non_blank();
               indent_col = p_col + p_SyntaxIndent;
               restore_pos(p);
               break;
            } else {
               counter := tag_stack._length()-1;
               removed := false;
               for (;counter >= 0;counter--) {
                  if (tag_stack[counter]==current_tag) {
                     tag_stack._deleteel(counter);
                     removed = true;
                     break;
                  }
               }
               if (!removed) {
                  // malformed html, so we give up
                  break;
               }
            }
         }
      }
   }
   restore_pos(p);
   return(indent_col);
}

/**
 * Returns true if the rest of the line from the cursor position is blank.
 * (except for tabs and spaces).
 * Otherwise returns false.
 *
 * @return
 */
static bool line_clear()
{
   textAfterCursor := strip(_expand_tabsc(p_col,-1,'S'));
   if (textAfterCursor!="") {
      return(false);
   } else {
      return(true);
   }
}

/**
 * Searches for an open tag that needs a closing tag
 * and inserts it at the cursor.
 */
_command void insert_close_tag() name_info(','VSARG2_MULTI_CURSOR|VSARG2_REQUIRES_EDITORCTL)
{
   if (!_html_tags_loaded() || _in_comment()) {
      return;
   }
   save_pos(auto p);

   // semi intelligent search
   current_tag := "";
   for (;;) {
      current_tag = _html_goto_previous_tag();
      if (current_tag == "") {
         break;
      }
      if (substr(current_tag,1,1)=="/"){
         // found an end tag, now find the begin tag
         int status = search('\<{':+_escape_re_chars(substr(current_tag,2))'}','-<@IRhXCS');
         if (status) {
            // malformed html, time to fall back to a simple search
            break;
         }
      } else {
         // search found an open tag that we can close
         if (_html_get_attr_val(current_tag,VSCFGP_BEAUTIFIER_END_TAG_REQUIRED)){
            restore_pos(p);
            if (_html_get_attr_val(current_tag,"standalone") && _html_get_attr_val(current_tag,"indent_content")) {
               line := "";
               get_line(line);
               if (strip(line)=="") {
                  int indent_col = html_indent_col(p_col) - p_SyntaxIndent;
                  if (indent_col>0) {
                     replace_line(indent_string(indent_col-1));
                     _end_line();
                  }
               }
            }
            _insert_text("</":+case_html_tag(current_tag)">");
            //insert_html_close_tag(current_tag);
            return;
         }
      }
   }
   restore_pos(p);
   // now we are just going to find the first open tag and go with that
   // avoids finding the tag that the cursor is on
   for (;;) {
      current_tag = _html_goto_previous_tag();
      if (current_tag == "") {
         restore_pos(p);
         break;
      }
      if (!(substr(current_tag,1,1)=="/") && _html_get_attr_val(current_tag,VSCFGP_BEAUTIFIER_END_TAG_REQUIRED)){
         restore_pos(p);
         _insert_text("</":+case_html_tag(current_tag)">");
         break;
      }
   }
}

/**
 * Searches for an open tag that needs a closing tag
 * and inserts it at the cursor.
 * Returns 0 if succesful
 */
static int insert_close_tag2()
{
   if (!_html_tags_loaded() || _in_comment()) {
      return(1);
   }
   save_pos(auto p);
   // semi intelligent search
   current_tag := "";
   for (;;) {
      current_tag = _html_goto_previous_tag();
      if (current_tag == "") {
         restore_pos(p);
         return(1);
      }
      if (substr(current_tag,1,1)=="/"){
         // found an end tag, now find the begin tag
         int status = search('\<{':+_escape_re_chars(substr(current_tag,2))'}','-<@IRhXCS');
         if (status) {
            // malformed html, time to bail
            restore_pos(p);
            return(1);
         }
      } else {
         // search found an open tag that we can close
         if (_html_get_attr_val(current_tag,VSCFGP_BEAUTIFIER_END_TAG_REQUIRED)){
            restore_pos(p);
            _insert_text("/":+case_html_tag(current_tag)">");
            if (get_text_safe(1) == ">") {
               p_col = p_col + 1;
            }
            return(0);
         }
      }
   }
}

_command void html_lt() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_ICON|VSARG2_LASTKEY)
{
   this_idx := last_index('','C');
   prev_idx := prev_index('','C');
   if (command_state() || _in_comment()) {
      call_root_key(last_event());
      return;
   }
   if (_MultiCursorAlreadyLooping()) {
      keyin(last_event());
      return;
   }
   _str key=last_event();
   if (_EmbeddedLanguageKey(key)) return;
   auto_codehelp_key();
   last_index(this_idx,'C');
   prev_index(prev_idx,'C');
}

_command void html_fs()
{
   if (command_state() || _in_comment()) {
      call_root_key(last_event());
      return;
   }
   _str key=last_event();
   if(_EmbeddedLanguageKey(key)) return;
   if (!LanguageSettings.getSyntaxExpansion(p_LangId)) {
       call_root_key(last_event());
       return;
   }
   save_pos(auto p);
   orig_col := p_col;
   status := search('\<','-<@RhXCS');
   if (!status && (p_col == orig_col -1)) {
      restore_pos(p);
      if (!insert_close_tag2()) {
         return;
      } else {
         auto_codehelp_key();
      }
   } else {
      restore_pos(p);
      auto_codehelp_key();
   }
}

/**
 * Maybe insert the matching closing tag for HTML.
 */
void maybe_insert_html_close_tag()
{
   // Bulletin Board Code tags use brackets
   current_char := get_text_safe(1);
   if (_LanguageInheritsFrom("bbc")) {
      _insert_text("]");
   } else {
      _insert_text(">");
      if (XW_isSupportedLanguage2()) {
         if (ST_doSymbolTranslation()) {
            ST_nag();
            return;
         }
      }
      if (_LanguageInheritsFrom("html") && XW_gt()) {
         return;
      }
   }
   if (current_char != ">" && _html_tags_loaded()) {
      save_pos(auto cpos);
      cursor_left();
      cursor_left();
      bgt := get_text();
      restore_pos(cpos);

      if (bgt == "/") {
         // That's already a closing tag, bail.
         return;
      }
      //figure out the current tag
      is_end_tag := false;
      current_tag := get_cur_open_tag(is_end_tag);

      // if the current tag is "" or the current tag does not require
      // an end tag then there is no work necessary
      if (current_tag == "" || is_end_tag || !req_end_tag(current_tag,p_LangId)) {
         return;
      }

      // put in the closing tag
      insert_html_close_tag(current_tag);
   }
}

/** 
 * Gets the casing method for tags.  
 * 
 * @return int       casing method - see WORDCASE_???
 */
int getTagCasing()
{
   typeless scase="";
   setting := get_format_setting(VSCFGP_BEAUTIFIER_WC_TAG_NAME);

   if (setting != "") {
      return (int)setting;
   }

   // if we're in javadoc, we need to get the html settings manually
   if (_inDocumentationComment()) {
      scase = LanguageSettings.getTagCase("html");
   } else {       // otherwise use buffer settings
      updateAdaptiveFormattingSettings(AFF_TAG_CASING);
      scase = p_tag_casing;
   }

   return scase;
}

static void fix_tag_case_at(typeless tagPos)
{
   // In some cases, lowcase/upcase_word can move the 
   // cursor - we don't want that.
   save_pos(auto p);
   restore_pos(tagPos);

   c := getTagCasing();
   switch (c) {
   case WORDCASE_CAPITALIZE:
      cap_word();
      break;
   case WORDCASE_LOWER:
      lowcase_word();
      break;
   case WORDCASE_UPPER:
      upcase_word();
      break;
   case WORDCASE_PRESERVE:
      break;
   }
   restore_pos(p);
}

/**
 * Intercepts the '>' key press in HTML and depending on the
 * HTML Syntax expansion options, potentially inserts
 * a closing HTML tag if the user just entered an open tag.
 */
_command void html_gt() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_ICON|VSARG2_LASTKEY)
{
   block_tag_closed := false;
   if (command_state() || _in_comment() || !_html_tags_loaded() || (p_active_form.p_name == "_javadoc_form")) {
      call_root_key(last_event());
      return;
   }
   if (_MultiCursorAlreadyLooping()) {
      keyin(last_event());
      return;
   }
   this_idx := last_index('','C');
   prev_idx := prev_index('','C');

   _str key=last_event();
   check_embedded := !(p_EmbeddedLexerName == "CFScript" &&  key == ">"); 
   if(check_embedded && p_EmbeddedLexerName != "") {
      if (!_EmbeddedLanguageKey(key)) {
         call_root_key(key);
      }
      return;
   }

   // block comment handling?
   if (_xml_gt_comment()) {
      return;
   }

   // Get position of tag so we can fixup it's case after we add in the '>' and
   // optional closing tag.
   typeless tagPos;
   fixupTag := false;

   save_pos(auto cursorPos);
   if (_html_goto_previous_tag() != "") {
      right();
      save_pos(tagPos);
      fixupTag = true;
   }
   restore_pos(cursorPos);

   if (_LanguageInheritsFrom("bbc") != (key=="]")) {
      call_root_key(last_event());
      return;
   }
   if (! LanguageSettings.getSyntaxExpansion(p_LangId)) {
       call_root_key(last_event());
       if (fixupTag) {
          fix_tag_case_at(tagPos);
       }
       return;
   }
   maybe_insert_html_close_tag();
   if (fixupTag) {
      fix_tag_case_at(tagPos);
   }
   last_index(this_idx,'C');
   prev_index(prev_idx,'C');
}

_command void html_space() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   if ( command_state() ) {
      call_root_key(' ');
      return;
   }

   if (p_SyntaxIndent<0 || !doExpandSpace(p_LangId) || length(last_event())!=1) {
      call_root_key(last_event());
      return;
   }
   if (_LanguageInheritsFrom("ant") && ant_expand_space()) {
      return;
   }
   auto_codehelp_key();
}

/**
 * Loads the relevant HTML info from disk into a static
 * hash table for html syntax expansion features.
 *
 * @return returns 0 if successful
 */
static int load_tag_info(_str lang="",_str buf_name='')
{
   if (lang == "") {
      if (p_object == OI_EDITOR) {
         lang = p_LangId;
         buf_name=p_buf_name;
      } else {
         lang = "html";          
      }
   }

   if (lang == "phpscript") {
      lang = "html";  // Enclosing HTML config.
   }

   if (lang == "tld" || (!_LanguageInheritsFrom("html", lang) && !_LanguageInheritsFrom("xml", lang))) {
      return -1;
   }
   gtagcache_info=_beautifier_cache_get(lang,buf_name);
   gtagcache_info_lang = lang;
   gtagcache_info_buf_name=buf_name;
   return(0);
}

/**
 * Determines if the table of html tags has been loaded
 * from disk into the static hash table gtagcache_info.
 * If the table has not been loaded, it gets loaded.  If it
 * cannot be loaded, return false.
 *
 * @return
 */
bool _html_tags_loaded(_str langId="html",_str buf_name='')
{
   if (gtagcache_info<0 || gtagcache_info_lang != langId || gtagcache_info_buf_name!=buf_name) {
      int status = load_tag_info(langId,buf_name);

      return (status == 0);
   }
   return(gtagcache_info>=0);
}

/**
 * Only meant to be called by html-gt.  Returns the current tag,
 * and sets end_tag to true if it is an end tag.
 *
 * Assumes that a '>' was just entered
 *
 * @param end_tag
 *
 * @return
 */
static _str get_cur_open_tag(bool &end_tag)
{
   tag_stack := 0;
   save_pos(auto p);
   // to move the cursor off of the '>' that was just inserted
   left();
   left();
   search_flags := "-<@RhXCS";
   if (_inDocumentationComment()) search_flags = '-<@RhCc';
   typeless status = 0;

   // Bulletin Board Code tags use brackets
   if (_LanguageInheritsFrom("bbc")) {
      search('{(\[(/|)[~ \t/\]\[]#(/\]|))|(])}',search_flags);
   } else {
      search('{(\<(/|)[~ \t/\>\<]#(/\>|))|(>)}',search_flags);
   }

   // outer loop searching for beginning of tags, inner loop searching for end
   for (;;) {
      if (status) {
         // did not find a '<'
         restore_pos(p);
         end_tag = false;
         return("");
      }
      _str current_tag=get_text_safe(match_length());
      if (current_tag == ">" || current_tag == "]") {
         tag_stack++;
      } else {
         if (tag_stack > 0 && pos("<",current_tag)) {
            tag_stack--;
         } else {
            end_tag = (substr(current_tag,2,1)=="/");
            if (end_tag) {
               current_tag = substr(current_tag,3);
            } else {
               current_tag = substr(current_tag,2);
            }
            restore_pos(p);
            return(current_tag);
         }
      }
      status = repeat_search();
   }
}

/**
 * Moves the cursor to the next html tag to the left of the cursor.
 * Returns '' and restores the cursor postion if no tag is found.
 * Otherwise, the tag is returned and the cursor is on the '<'.
 *
 * @return
 */
_str _html_goto_previous_tag()
{
   save_pos(auto p);
   // avoids finding the tag that the cursor is on
   if (!_in_comment() && get_text_safe() == "<"){
      if (p_col == 1) {
         if (up()){
            return("");
         }
         _end_line();
      } else {
         left();
      }
   }
   typeless status = search('\<{(/|)[~ \t/\>\<]#}','-<@RhXCS');
   for(;;){
      if (status) {
         // did not find a '<'
         restore_pos(p);
         return("");
      }
      // if we landed in an embedded language, search again
      if (p_EmbeddedLexerName != "") {
         status = repeat_search();
      } else {
         break;
      }
   }
   return(get_text_safe(match_length('0'),match_length('S0')));
}


/**
 * Returns true if we can match the current tag to it's end tag.
 */
static bool has_matching_end_tag()
{
   save_pos(auto p);
   left();
   orig_pos := _QROffset();
   int status = find_matching_paren(true);
   if (status < 0) {
      restore_pos(p);
      return false;
   }
   found_it := (_QROffset() != orig_pos);
   restore_pos(p);
   return found_it;
}

static bool get_tag_eo_insert_end_tag(int ibeautifier,_str tag) {
   end_tag:=_beautifier_get_tag_property(ibeautifier,tag,VSCFGP_BEAUTIFIER_END_TAG);
   end_tag_required:=_beautifier_get_tag_property(ibeautifier,tag,VSCFGP_BEAUTIFIER_END_TAG_REQUIRED);
   if (isinteger(end_tag) && isinteger(end_tag_required)) {
      return end_tag && end_tag_required;
   }
   return false;
}
/**
 * Returns true if an end tag should be inserted for cur_tag.
 *
 * @param cur_tag
 * @return
 */
static bool req_end_tag(_str cur_tag,_str langId)
{
   if (_LanguageInheritsFrom("html", langId)/* || langId == 'xhtml'*/) {
      cur_tag = lowcase(cur_tag);
   }
   cur_tag=_beautifier_resolve_tag(gtagcache_info,cur_tag);
   
   return (get_tag_eo_insert_end_tag(gtagcache_info,cur_tag) && (line_clear() || !has_matching_end_tag()));
}

static typeless intern_get_attr_val(_str tag, _str attribute)
{
   tag=_beautifier_resolve_tag(gtagcache_info,tag);
   if (attribute=="standalone") {
      return _beautifier_get_tag_standalone(gtagcache_info,tag);
   } else if (attribute=="indent_content") {
      indent_tags:=_beautifier_get_tag_property(gtagcache_info,tag,VSCFGP_BEAUTIFIER_INDENT_TAGS);
      if (!isinteger(indent_tags)) indent_tags=0;
      return indent_tags;
   } else if (attribute=="bl_within") {
      indent_tags:=_beautifier_get_tag_property(gtagcache_info,tag,VSCFGP_BEAUTIFIER_INDENT_TAGS);
      if (!isinteger(indent_tags)) indent_tags=0;
      return indent_tags;
   }
   return _beautifier_get_tag_property(gtagcache_info,tag,attribute,0 /* default value */);
}

/**
 * Given a tag and formatting attribute,
 * returns the value of that attriubte.  Used for
 * html syntax expansion.
 *
 * @param tag       The tag in question.
 * @param attribute The formatting attribute whose value will be returned.
 * @return
 */
typeless _html_get_attr_val(_str tag, _str attribute)
{
   tag = lowcase(tag);

   return intern_get_attr_val(tag,attribute);
}

typeless _get_attr_val(_str langId, _str tag, _str attribute)
{
   if (_LanguageInheritsFrom("html", langId)/* || langId == "xhtml"*/) {
      return _html_get_attr_val(tag, attribute);
   } else {
      return intern_get_attr_val(tag,attribute);
   }
}

/**
 * Inserts the close tag for the given tag.
 *
 * @param endtag
 */
static void insert_html_close_tag( _str endtag = "")
{
   tagopen  := case_html_tag(endtag);
   tagclose := tagopen;

   // Bulletin Board Code tags use brackets
   if (_LanguageInheritsFrom("bbc")) {
      tagopen = "[":+tagopen:+"]";
      tagclose   = "[/":+tagclose:+"]";
   } else {
      tagopen = "<":+tagopen:+">";
      tagclose   = "</":+tagclose:+">";
   }

   typeless standalone_val = _html_get_attr_val(endtag,"standalone");
   if (standalone_val) {
      set_surround_mode_start_line();
      indent := _html_get_attr_val(endtag,"indent_content");
      insert_block_close_tags(tagopen,tagclose,indent);
      set_surround_mode_end_line(p_line+1);
      do_surround_mode_keys();
   } else {
      insert_single_line_close_tags(tagclose);
   }
}

/**
 * Inserts the closing tag for HTML tags that are not
 * block tags (inline).
 *
 * @param end_tag
 */
static void insert_single_line_close_tags(_str end_tag)
{
   p := _QROffset();
   _str tagname = end_tag;
   _insert_text(end_tag);   //Insert the end tag
   _GoToROffset(p);
}

/**
 * Inserts the closing HTML tag for block tags.
 *
 * @param begin_tag
 * @param end_tag
 * @param indent
 */
static void insert_block_close_tags(_str begin_tag,_str end_tag, _str indent = "0")
{
   prefix := "";
   if (_inDocumentationComment()) {
      if (_inJavadoc()) {
         prefix="* ";
      } else if (_inXMLDoc()) {
         prefix="/// ";
      } else if (_inDocumentationComment(style:CODEHELP_DOXYGEN_PREFIX)) {
         prefix="* ";
      } else if (_inDocumentationComment(style:CODEHELP_DOXYGEN_PREFIX1)) {
         prefix="//! ";
      }
   }
   orig_col := p_col;
   if (_expand_tabsc(1,p_col-1)!="") {
      _first_non_blank();
   }
   indent_col := p_col;
   p_col=orig_col;
   textAfterCursor := _expand_tabsc(p_col,-1,'S');
   if (textAfterCursor!="") {
      _delete_text(-1);
      insert_line(indent_string(indent_col-1):+prefix:+textAfterCursor);
      up();
   }
   _first_non_blank();
   if (LanguageSettings.getInsertRealIndent(p_LangId)) {
      if (indent) {
         insert_line(indent_string(indent_col + p_SyntaxIndent - 1) :+ prefix);
      } else {
         insert_line(indent_string(indent_col-1) :+ prefix);
      }
   } else {
      insert_line(indent_string(indent_col-1) :+ prefix);
   }
   if (end_tag!="") {
      insert_line(indent_string(indent_col-1) :+ prefix :+ end_tag);
      up();
   }
   p_col=indent_col+length(prefix);
   if (indent) {
      p_col += p_SyntaxIndent;
   }
}

_command void ast(_str lang = p_LangId) name_info(',')
{
   autoSymbolTransEditor(lang);
}

/*End HTML Options Form*/

defeventtab html_keys;
def  " "= html_space;
def  "%"= auto_codehelp_key;
def  "&"= auto_codehelp_key;
def  "("= auto_functionhelp_key;
def  "*"= html_key;
def  "."= auto_codehelp_key;
def  "/"= auto_codehelp_key;
def  ":"= html_key;
def  "<"= html_lt;
def  "="= auto_codehelp_key;
def  ">"= html_gt;
def  "-"= xml_dash;
def  "["= html_lt;
def  "]"= html_gt;
def  "{"= html_key;
def  "}"= html_key;
def  "ENTER"= html_enter;
def  "TAB"= html_tab;

static _str gtkinfo;
static _str gtk;

static _str html_next_sym()
{
   if (p_col>_text_colc()) {
      if(down()) {
         gtk=gtkinfo="";
         return("");
      }
      _begin_line();
   }
   typeless status=0;
   ch := get_text_safe();
   //say("html_next_sym: ch="ch);
   if (ch=="" || 
       (ch=="<" && _clex_find(0,'g')==CFG_COMMENT && !_inDocumentationComment()) ||
       (ch=="[" && _clex_find(0,'g')==CFG_COMMENT && _LanguageInheritsFrom("bbc"))) {
      status=_clex_skip_blanks("ch");
      if (status) {
         gtk=gtkinfo="";
         return(gtk);
      }
      return(html_next_sym());
   }
   start_col := 0;
   start_line := 0;
   if ((ch=='"' || ch=="'" ) && _clex_find(0,"g")==CFG_STRING) {
      start_col=p_col;
      start_line=p_line;
      status=_clex_find(STRING_CLEXFLAG,'n');
      if (status) {
         _end_line();
      } else if (p_col==1) {
         up();_end_line();
      }
      gtk=TK_STRING;
      gtkinfo=_expand_tabsc(start_col,p_col-start_col+1);
      return(gtk);
   }
   word_chars := _clex_identifier_chars();
   if (pos('['word_chars']',ch,1,'r')) {
      start_col=p_col;
      if(_clex_find(0,'g')==CFG_NUMBER) {
         for (;;) {
            if (p_col>_text_colc()) break;
            right();
            if(_clex_find(0,'g')!=CFG_NUMBER) {
               break;
            }
         }
         gtk=TK_NUMBER;
         gtkinfo=_expand_tabsc(start_col,p_col-start_col+1);
         return(gtk);
      }
      //search('[~'p_word_chars']|$','@r');
      _TruncSearchLine('[~'word_chars']|$','r');
      gtk=TK_ID;
      gtkinfo=_expand_tabsc(start_col,p_col-start_col);
      return(gtk);
   }
   right();
   if (ch=="<" && get_text_safe()=="/") {
      right();
      gtk=gtkinfo="</";
      return(gtk);

   }
   if (_LanguageInheritsFrom("bbc") && ch=="[" && get_text_safe()=="/") {
      right();
      gtk=gtkinfo="[/";
      return(gtk);

   }
   gtk=gtkinfo=ch;
   return(gtk);

}
static _str html_prev_sym()
{
   // For better performance with html_prev_sym() and _clex_find(),
   // temporarily turn off soft wrap.
   // Warning: This messes up save_pos/restore_pos (but not callers save_pos/restore_pos)
   // Remove this if it causes problems
   // Remove if reimplement html_prev_sym to use token list.
   old_SoftWrap:=p_SoftWrap;p_SoftWrap=false;
   status:=html_prev_sym2();
   p_SoftWrap=old_SoftWrap;
   return status;
}
static _str html_prev_sym2()
{
   ch := get_text_safe();
   //say("html_prev_sym: ch="ch);
   while (ch==" " && _inDocumentationComment() && p_col > 1) {
      left();
      return html_prev_sym();
   }
   typeless status=0;
   if (ch=="\n" || ch=="\r" || ch=="" || 
       (ch==">" && _clex_find(0,'g')==CFG_COMMENT && !_inDocumentationComment() ) ||
       (ch=="]" && _clex_find(0,'g')==CFG_COMMENT && _LanguageInheritsFrom("bbc"))) {
      status=_clex_skip_blanks('-h');
      if (status) {
         gtk=gtkinfo="";
         return(gtk);
      }
      return(html_prev_sym());
   }
   typeless end_col=0;
   if ((ch=='"' || ch=="'" ) && _clex_find(0,'g')==CFG_STRING) {
      end_col=p_col;
      status=_clex_find(STRING_CLEXFLAG,'-n');
      if (status) {
         _end_line();
      } else if (p_col==1) {
         up();_end_line();
      }
      gtk=TK_STRING;
      gtkinfo=_expand_tabsc(p_col,end_col-p_col+1);
      return(gtk);
   }
   if ((ch=='"' || ch=="'" ) && _inDocumentationComment() && p_col > 1) {
      end_col=p_col;
      save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
      left();
      status = search(ch, '-<@hCc');
      if (status || p_col==1) {
         gtk=gtkinfo="";
         return(gtk);
      }
      restore_search(s1,s2,s3,s4,s5);
      left();
      gtk=TK_STRING;
      gtkinfo=_expand_tabsc(p_col,end_col-p_col+1);
      return(gtk);
   }
   word_chars := _clex_identifier_chars();
   if (pos('['word_chars']',ch,1,'r')) {
      end_col=p_col+1;
      if(_clex_find(0,'g')==CFG_NUMBER) {
         for (;;) {
            if (p_col==1) break;
            left();
            if(_clex_find(0,'g')!=CFG_NUMBER) {
               right();
               break;
            }
         }
         gtk=TK_NUMBER;
         gtkinfo=_expand_tabsc(p_col,end_col-p_col);
      } else {
         search('[~'word_chars']\c|^\c','@rh-');
         gtk=TK_ID;
         gtkinfo=_expand_tabsc(p_col,end_col-p_col);
      }
      if (p_col==1) {
         up();_end_line();
      } else {
         left();
      }
      return(gtk);
   }
   if (get_text_safe(2,(int)_QROffset()-1)=="<%") {
      left();left();
      gtk=gtkinfo="<%";
      return(gtk);
   }
   // Bulletin Board Code tags use brackets
   if (ch=="<" || ch=="&" || ch=="%" || 
       (ch=="[" && _LanguageInheritsFrom("bbc"))) {
      gtk=gtkinfo=ch;
      return(gtk);
   }
   if (p_col==1) {
      up();_end_line();
      if (_on_line0()) {
         gtk=gtkinfo="";
         return(gtk);
      }
      gtk=gtkinfo=ch;
      return(gtk);
   }
   left();
   if (ch=="/" && get_text_safe()=="<") {
      left();
      gtk=gtkinfo="</";
      return(gtk);
   }
   // Bulletin Board Code tags use brackets
   if (ch=="/" && get_text_safe()=="[" && _LanguageInheritsFrom("bbc")) {
      left();
      gtk=gtkinfo="[/";
      return(gtk);
   }

   gtk=gtkinfo=ch;
   return(gtk);

}
static int html_before_id(_str &prefixexp,int &prefixexpstart_offset,
                          _str &lastid,int &info_flags,int depth=0) {
   typeless start=_time("b");
   // For better performance with html_prev_sym() and _clex_find(),
   // temporarily turn off soft wrap.
   // Warning: This messes up save_pos/restore_pos (but not callers save_pos/restore_pos)
   // Remove this if it causes problems
   // Remove if reimplement html_prev_sym to use token list.
   old_SoftWrap:=p_SoftWrap;p_SoftWrap=false;
   status:=html_before_id2(prefixexp,prefixexpstart_offset,lastid,info_flags, depth);
   p_SoftWrap=old_SoftWrap;
   //say('t='((typeless)_time('b')-start));
   return status;
}
static int html_before_id2(_str &prefixexp,int &prefixexpstart_offset,
                          _str &lastid,int &info_flags, int depth=0)
{
   count := 0;
   tag_name := "";
   for (;;) {
      if (_chdebug) {
         isay(depth, "html_before_id2: gtk="gtk" gtkinfo="gtkinfo" prefixexp="prefixexp);
      }
      switch (gtk) {
      case "=":
      case TK_ID:
      case TK_STRING:
      case TK_NUMBER:
         operator_found:=false;
         if (gtk=="=") {
            operator_found=true;
            gtk=html_prev_sym();
            if (gtk==TK_ID) {
               prefixexp=gtkinfo"=";
            }
            if (_chdebug) {
               isay(depth, "html_before_id2: BEFORE EQUALS gtk="gtk" gtkinfo="gtkinfo" prefixexp="prefixexp);
            }
         }
         max_count := 100;
         peformance_tweak_done := false;
         while (count++ < max_count) {
            if (gtk==TK_ID) {
               tag_name=gtkinfo;
               if (_chdebug) {
                  isay(depth, "html_before_id2: ID tagname="tag_name" prefixexp="prefixexp);
               }
               if (!operator_found && !peformance_tweak_done) {
                  right();
                  color:=_clex_find(0,'g');
                  nextch:=get_text_safe();
                  left();
                  // IF we are in the middle of a paragraph of words (i.e. not inside <> or [])
                  if (_chdebug) {
                     isay(depth, "html_before_id2: color="color" ch="nextch"=");
                  }
                  if (color!=CFG_TAG && color!=CFG_UNKNOWN_TAG && color!=CFG_ATTRIBUTE  && color!=CFG_UNKNOWN_ATTRIBUTE && color!=CFG_XHTMLELEMENTINXSL && color!=CFG_KEYWORD && color!=CFG_STRING) {
                     // Lets get out of here quick since this loop can take multiple seconds.
                     count=max_count-2;
                     peformance_tweak_done=true;
                     if (_chdebug) {
                        isay(depth, "html_before_id2: FAST BREAK FROM LOOP");
                     }
                  }
               }
            } else if (gtk=="</" || gtk==">") {
               // we are lost here
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            } else if (gtk=="[/" || gtk=="]" && _LanguageInheritsFrom("bbc")) {
               // we are lost here
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            } else if (gtk=="<" || gtk=="[") {
               if (gtk=="[" && !_LanguageInheritsFrom("bbc")) {
                  return(VSCODEHELPRC_CONTEXT_NOT_VALID);
               }
               if (isdigit(_first_char(tag_name))) {
                  return(VSCODEHELPRC_CONTEXT_NOT_VALID);
               }
               prefixexpstart_offset=(int)point('s');
               prefixexp="<"tag_name" "prefixexp;
               if (_chdebug) {
                  isay(depth, "html_before_id2: NEXT gtk="gtk" gtkinfo="gtkinfo" prefixexp="prefixexp);
               }
               return(0);
            } else if (gtk=="@") {
               prefixexp="@ "prefixexp;
               // keep searching
            } else if (gtk=="<%") {
               prefixexpstart_offset=(int)point('s')+1;
               prefixexp="<%"prefixexp;
               return(0);
            } else if (gtk=="=") {
               gtk=html_prev_sym();
               operator_found=true;
               continue;
            }
            gtk=html_prev_sym();
            operator_found=false;
            if (_chdebug) {
               isay(depth, "html_before_id2: NEXT gtk="gtk" gtkinfo="gtkinfo" prefixexp="prefixexp);
            }
         }
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      case "@":
         gtk=html_prev_sym();
         if (gtk=="<%") {
            prefixexpstart_offset=(int)point('s')+1;
            prefixexp="<%@ ";
            if (_chdebug) {
               isay(depth, "html_before_id2: <%@ CASE prefixexp="prefixexp);
            }
            return(0);
         }
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      case "%":
      case "&":
      case "<":
      case "</":
      case "[":
      case "[/":
         prefixexpstart_offset=(int)point('s')+1;
         prefixexp=gtkinfo;
         ch := get_text_safe(1,_nrseek()+1);
         if (_chdebug) {
            isay(depth, "html_before_id2: ENTITY ch="ch" prefixexp="prefixexp);
         }
         if (ch == " " || ch == "\t") {
            return(VSCODEHELPRC_CONTEXT_NOT_VALID);
         }
         return(0);
      default:
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      }
   }
}

/**
 * <B>Hook Function</B> -- _ext_get_expression_info
 * <P>
 * If this function is not implemented, the editor will
 * default to using {@link _do_default_get_expression_info()}, which simply
 * returns the current identifier under the cursor and no prefix
 * expression.
 * <P>
 * This function is used to get information about the code at
 * the current buffer location, including the current ID under
 * the cursor, the expression before the current ID, and other
 * supplementary information useful to list-members.
 * <P>
 * The caller must check whether text is in a comment or string.
 * For now, set info_flags to 0.  In the future we could
 * have a LASTID_FOLLOWED_BY_PAREN flag and optionally do an
 * exact match instead of a prefix match.
 *
 * @param PossibleOperator       Was the last character typed an operator?
 * @param idexp_info             (reference) VS_TAG_IDEXP_INFO whose members are set by this call.
 *
 * @return int
 *      return 0 if successful<BR>
 *      return 1 if expression too complex<BR>
 *      return 2 if not valid operator
 *
 * @since 11.0
 */
int _dtd_get_expression_info(bool PossibleOperator,VS_TAG_IDEXP_INFO &idexp_info,
                             VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   //p_word_chars=p_word_chars:+'%;';
   int status=_html_get_expression_info(PossibleOperator,idexp_info,visited,depth);
   //p_word_chars=substr(p_word_chars,1,length(p_word_chars)-2);
   return(status);
}

int bbc_proc_search(_str &proc_name,int find_first)
{
   proc_name="";
   return(STRING_NOT_FOUND_RC);
}
int _bbc_get_expression_info(bool PossibleOperator, VS_TAG_IDEXP_INFO &idexp_info,
                             VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _html_get_expression_info(PossibleOperator, idexp_info, visited, depth);
}

/**
 * <B>Hook Function</B> -- _ext_get_expression_info
 * <P>
 * If this function is not implemented, the editor will
 * default to using {@link _do_default_get_expression_info()}, which simply
 * returns the current identifier under the cursor and no prefix
 * expression.
 * <P>
 * This function is used to get information about the code at
 * the current buffer location, including the current ID under
 * the cursor, the expression before the current ID, and other
 * supplementary information useful to list-members.
 * <P>
 * The caller must check whether text is in a comment or string.
 * For now, set info_flags to 0.  In the future we could
 * have a LASTID_FOLLOWED_BY_PAREN flag and optionally do an
 * exact match instead of a prefix match.
 *
 * @param PossibleOperator       Was the last character typed an operator?
 * @param idexp_info             (reference) VS_TAG_IDEXP_INFO whose members are set by this call.
 *
 * @return int
 *      return 0 if successful<BR>
 *      return 1 if expression too complex<BR>
 *      return 2 if not valid operator
 *
 * @since 11.0
 */
int _html_get_expression_info(bool PossibleOperator, VS_TAG_IDEXP_INFO &idexp_info,
                              VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   // For better performance with html_prev_sym() and _clex_find(),
   // temporarily turn off soft wrap.
   // Warning: This messes up save_pos/restore_pos (but not callers save_pos/restore_pos)
   // Remove this if it causes problems
   // Remove if reimplement html_prev_sym to use token list.
   old_SoftWrap:=p_SoftWrap;p_SoftWrap=false;
   status:=_html_get_expression_info2(PossibleOperator,idexp_info,visited,depth);
   p_SoftWrap=old_SoftWrap;
   return status;
}
static int _html_get_expression_info2(bool PossibleOperator, VS_TAG_IDEXP_INFO &idexp_info,
                                      VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (_chdebug) {
      isay(depth, "_html_get_expression_info: IN");
   }
   tag_idexp_info_init(idexp_info);
   idexp_info.errorArgs._makeempty();
   idexp_info.otherinfo="";
   done := false;
   status := 0;
   idexp_info.info_flags=VSAUTOCODEINFO_DO_LIST_MEMBERS;
   typeless orig_pos;
   save_pos(orig_pos);
   word_chars := _clex_identifier_chars();
   VS_TAG_IDEXP_INFO orig_idexp_info = idexp_info;
   if (PossibleOperator) {
      left();
      ch := get_text_safe();
      if (_chdebug) {
         isay(depth, "_html_get_expression_info2: OPERATOR ch="ch);
      }
      switch (ch) {
      case "[":
         if (_LanguageInheritsFrom("bbc")) {
            idexp_info.lastid="";
            idexp_info.lastidstart_col=p_col+1;
            idexp_info.lastidstart_offset=(int)point('s')+1;
            idexp_info.prefixexpstart_offset=(int)point('s');
            idexp_info.prefixexp=ch;
            done=true;
            break;
         }
         restore_pos(orig_pos);
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      case "<":
      case "&":
      case "%":
         idexp_info.lastid="";
         idexp_info.lastidstart_col=p_col+1;
         idexp_info.lastidstart_offset=(int)point('s')+1;
         idexp_info.prefixexpstart_offset=(int)point('s');
         idexp_info.prefixexp=ch;
         done=true;
         break;
      case "/":
         left();
         ch=get_text_safe();
         if (ch=="<") {
            idexp_info.lastid="";
            idexp_info.lastidstart_col=p_col+2;
            idexp_info.lastidstart_offset=(int)point('s')+2;
            idexp_info.prefixexpstart_offset=(int)point('s');
            idexp_info.prefixexp="</";
            done=true;
            break;
         }
         restore_pos(orig_pos);
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      case "=":
         idexp_info.lastid="";
         idexp_info.lastidstart_col=p_col+1;
         idexp_info.lastidstart_offset=(int)point('s')+1;
         gtk=html_prev_sym();
         status=html_before_id(idexp_info.prefixexp,idexp_info.prefixexpstart_offset,idexp_info.lastid,idexp_info.info_flags,depth+1);
         done=true;
         break;
      case "@":
         gtk=html_prev_sym();
         if (gtk=="<%") {
            idexp_info.prefixexp="<%@ ";
            done=true;
            break;
         }
         restore_pos(orig_pos);
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      case " ":
         {
            // If the space is in a string lets forget about this
            if(_clex_find(0,'g')==CFG_STRING) {
               // This is an unquoted string
               restore_pos(orig_pos);
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
         }
         // Clark.  ******START SPEED UP CODE****************
         _clex_find(0,'g');  // Make sure color coding is update-to-date
         int flags=_lineflags();
         if (_expand_tabsc(1,p_col-1)=="" &&
             !_clex_InComment(flags)   // Here we are taking advantion of the fact that this function
                                       // indicates we are in a comment when we are just inside a tag and
                                       // its attributes.
             ) {
            restore_pos(orig_pos);
            return(VSCODEHELPRC_CONTEXT_NOT_VALID);
         }
         // Clark.  ******END SPEED UP CODE****************
         idexp_info.lastid="";
         idexp_info.lastidstart_col=p_col+1;
         idexp_info.lastidstart_offset=(int)point('s')+1;
         gtk=html_prev_sym();
         //say("_html_get_expression_info: gtk="gtk" gtkinfo="gtkinfo);
         status=html_before_id(idexp_info.prefixexp,idexp_info.prefixexpstart_offset,idexp_info.lastid,idexp_info.info_flags,depth+1);
         done=true;
         break;
      default:
         restore_pos(orig_pos);
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      }
      if (done) {
         restore_pos(orig_pos);
         ch=get_text_safe();
         if (ch!=" " && pos('['word_chars']',ch,1,'r') &&
             !_TruncSearchLine('[~'word_chars']|$','r')) {
            end_col := p_col;
            restore_pos(orig_pos);
            idexp_info.lastid=_expand_tabsc(p_col,end_col-p_col);
         }
         return(status);
      }
   } else {
      // check color coding to see that we are not in a comment
      cfg := _clex_find(0,'g');
      if (cfg==CFG_COMMENT) {
         //return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      }
      if (_chdebug) {
         isay(depth, "_html_get_expression_info2: cfg="cfg" ch="get_text_safe()"=");
      }
      // check if we are in a string or number
      if (cfg==CFG_STRING || cfg==CFG_NUMBER) {
         int orig_cfg=cfg;
         left();
         cfg=_clex_find(0,'g');
         ch := get_text_safe();
         right();
         if (_chdebug) {
            isay(depth, "_html_get_expression_info2: cfg="cfg" ch="ch);
         }
         if (cfg==CFG_STRING || cfg==CFG_NUMBER) {
            orig_col := p_col;
            orig_line := p_line;
            int clex_flag=(cfg==CFG_STRING)? STRING_CLEXFLAG:NUMBER_CLEXFLAG;

            int clex_status;
            // CDATA strings can be huge (10,000 lines or more). Optimize that case here.
            if (_LanguageInheritsFrom('xml') && _xml_in_cdata()) {
               // Put cursor on the last [ which is tag color.
               p_col+=8;
            } else {
               clex_status=_clex_find(clex_flag,'n-');
               if (clex_status) {
                  restore_pos(orig_pos);
                  return(VSCODEHELPRC_CONTEXT_NOT_VALID);
               }
            }
            clex_status=_clex_find(clex_flag,'o');
            if (clex_status) {
               restore_pos(orig_pos);
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            str_offset := 0;//(cfg==CFG_STRING)? 1:0;
            int start_col=p_col+str_offset;
            int start_offset=(int)point('s')+str_offset;
            clex_status=_clex_find(clex_flag,'n');
            if (clex_status || p_line > orig_line) {
               restore_pos(orig_pos);
               //say("_html_get_expression_info: 3");
               //return(VSCODEHELPRC_CONTEXT_NOT_VALID);
               _end_line();
            }
            int end_col = p_col-str_offset;
            clex_status=_clex_find(clex_flag,'o-');
            if (clex_status) {
               restore_pos(orig_pos);
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            idexp_info.prefixexp="";
            idexp_info.lastidstart_col=start_col;
            idexp_info.lastidstart_offset=start_offset;
            idexp_info.prefixexpstart_offset=idexp_info.lastidstart_offset;
            idexp_info.lastid=_expand_tabsc(start_col,end_col-start_col);
            //say("_html_get_expression_info: lastid="idexp_info.lastid);
            p_col=start_col-1;
            if (get_text_safe()=='"' || get_text_safe()=="'") {
               left();
            }
            gtk=html_prev_sym();
            idexp_info.info_flags|=VSAUTOCODEINFO_IN_STRING_OR_NUMBER;
            status=html_before_id(idexp_info.prefixexp,idexp_info.prefixexpstart_offset,idexp_info.lastid,idexp_info.info_flags,depth+1);
            restore_pos(orig_pos);
            return(status);
         }
      }
      // IF we are not on an id character.
      left();
      ch := get_text_safe();
      cfg=_clex_find(0,'g');
      if (_chdebug) {
         isay(depth, "_html_get_expression_info2: HERE ch="ch" cfg="cfg);
      }
      if (pos('[~'word_chars']',ch,1,'r') || (cfg==CFG_NUMBER || cfg==CFG_STRING)) {
         //left();
         ch=get_text_safe();
         prevch:=get_text_safe(1,(int)point('s')-1);
         if (_chdebug) {
            isay(depth, "_html_get_expression_info2: NOT AN ID CHAR ch="ch" prevch="prevch);
         }
         if (ch=="&" || ch=="%" || ch=="<" || ch=="[" || 
             (ch=="/" && prevch=="<") ||
             (ch=="/" && prevch=="[" && _LanguageInheritsFrom("bbc"))) {
            idexp_info.lastid="";
            idexp_info.lastidstart_col=p_col+1;
            idexp_info.lastidstart_offset=(int)point('s')+1;
            idexp_info.prefixexpstart_offset=(int)point('s');
            if (_chdebug) {
               isay(depth, "_html_get_expression_info2: ENTITY, START OR END TAG, prefixexp="idexp_info.prefixexp);
            }
            right();
            if (!_TruncSearchLine('[~'word_chars']|$','r')) {
               end_col := p_col;
               restore_pos(orig_pos);
               idexp_info.lastid=_expand_tabsc(p_col,end_col-p_col);
            }
            if (ch=="&") {
               idexp_info.prefixexp="&";
            } else if (ch=="%") {
               idexp_info.prefixexp="%";
            } else if (ch=="<") {
               idexp_info.prefixexp="<";
            } else if (ch=="/" && prevch=="<") {
               idexp_info.prefixexp="</";
               --idexp_info.prefixexpstart_offset;
            } else if (ch=="[") {
               idexp_info.prefixexp="[";
            } else {
               idexp_info.prefixexp="[/";
               --idexp_info.prefixexpstart_offset;
            }
            restore_pos(orig_pos);
            return(0);
         } else if (ch=="'" || ch=='"' || isdigit(ch)) {
            cfg=_clex_find(0,'g');
            if (_chdebug) {
               isay(depth, "_html_get_expression_info2: QUOTE cfg="cfg);
            }
            if (cfg!=CFG_STRING) {
               restore_pos(orig_pos);
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            idexp_info.lastid="";
            idexp_info.lastidstart_col=p_col+1;
            idexp_info.lastidstart_offset=(int)point('s')+1;
            right();
            cfg=_clex_find(0,'g');
            if (cfg!=CFG_STRING) {
               p_col=idexp_info.lastidstart_col-1;
               clex_status := _clex_find(STRING_CLEXFLAG,'n-');
               if (clex_status) {
                  restore_pos(orig_pos);
                  if (_chdebug) {
                     isay(depth, "_html_get_expression_info2: DID NOT FIND CHAR BEFORE STRING");
                  }
                  return(VSCODEHELPRC_CONTEXT_NOT_VALID);
               }
               clex_status=_clex_find(STRING_CLEXFLAG,'o');
               if (clex_status) {
                  restore_pos(orig_pos);
                  if (_chdebug) {
                     isay(depth, "_html_get_expression_info2: DID NOT FIND START OF STRING");
                  }
                  return(VSCODEHELPRC_CONTEXT_NOT_VALID);
               }
               //right();
               idexp_info.lastid=get_text_safe(idexp_info.lastidstart_col-p_col);
               idexp_info.lastidstart_col=p_col;
               idexp_info.lastidstart_offset=(int)point('s');
               left();
               ch=get_text_safe();
               if (_chdebug) {
                  isay(depth, "_html_get_expression_info2: STRING, lastid="idexp_info.lastid" ch="ch);
               }
            }
         } else if (ch=="@") {
            lp_offset := 1;
            while (get_text_safe(1,(int)point('s')-lp_offset)==" ") ++lp_offset;
            if (get_text_safe(2,(int)point('s')-lp_offset-1)=="<%") {
               idexp_info.lastid="";
               idexp_info.lastidstart_col=p_col+1;
               idexp_info.lastidstart_offset=(int)point('s')+1;
               idexp_info.prefixexp="<%@ ";
               idexp_info.prefixexpstart_offset=(int)point('s')-lp_offset-1;
               restore_pos(orig_pos);
               return(0);
            }
         }
         if (ch=="=" || ch==" ") {
            if (!length(idexp_info.lastid) || idexp_info.lastidstart_offset==0) {
               idexp_info.lastid="";
               idexp_info.lastidstart_col=p_col+1;
               idexp_info.lastidstart_offset=(int)point('s')+1;
               save_pos(auto attr_pos);
               right();
               if (!_TruncSearchLine('[~'word_chars']|$','r')) {
                  end_col := p_col;
                  restore_pos(orig_pos);
                  idexp_info.lastid=_expand_tabsc(p_col,end_col-p_col);
               }
               restore_pos(attr_pos);
            }
            done=true;
         }
      }
      if (!done) {
         // IF we are not on an id character.
         if (pos('[~'word_chars']',get_text_safe(),1,'r')) {
            restore_pos(orig_pos);
            idexp_info.prefixexp="";
            idexp_info.lastid="";
            idexp_info.lastidstart_col=p_col;
            idexp_info.lastidstart_offset=(int)point('s');
            //prefixexpstart_offset=lastidstart_offset;
            gtk=html_prev_sym();
            restore_pos(orig_pos);
            return(0);
         }

         int old_TruncateLength=p_TruncateLength;p_TruncateLength=0;
         //search('[~'p_word_chars']|$','r@');
         _TruncSearchLine('[~'word_chars'"]|$','r');
         end_col := p_col;
         left();
         search('[~'word_chars'"]\c|^\c','-rh@');
         idexp_info.lastid=_expand_tabsc(p_col,end_col-p_col);
         idexp_info.lastidstart_col=p_col;
         idexp_info.lastidstart_offset=(int)point('s');
         //prefixexpstart_offset=lastidstart_offset;
         if(p_col==1) {
            up();_end_line();
         } else {
            left();
            ch=get_text_safe();
            if (ch=="'" || ch=='"') {
               left();
            }
         }
         p_TruncateLength=old_TruncateLength;
      }
   }
   idexp_info.prefixexp="";
   ch := get_text_safe();
   if (_chdebug) {
      isay(depth, "_html_get_expression_info2: MAY HAVE AN ID CHAR: ch="ch);
   }
   //if (idexp_info.lastid == "" && (ch == " " || ch == "\t" || ch == "*")) {
   //   restore_pos(orig_pos);
   //   ch = get_text_safe();
   //   if (_chdebug) {
   //      isay(depth, "_html_get_expression_info2: SPECIAL CASE, ch="ch);
   //   }
   //   if (pos('[~'word_chars']',ch,1,'r')) {
   //      idexp_info.lastidstart_col=p_col;
   //      idexp_info.lastidstart_offset=(int)point('s');
   //      idexp_info.prefixexpstart_offset = idexp_info.lastidstart_offset;
   //      if (_chdebug) {
   //         isay(depth, "_html_get_expression_info2: SPECIAL CASE STOP HERE");
   //      }
   //      return 0;
   //   }
   //}
   gtk=html_prev_sym();
   if (_chdebug) {
      isay(depth, "_html_get_expression_info2: gtk="gtk" gtkinfo="gtkinfo);
   }
   status=html_before_id(idexp_info.prefixexp,idexp_info.prefixexpstart_offset,idexp_info.lastid,idexp_info.info_flags,depth+1);
   restore_pos(orig_pos);
   if (status < 0) idexp_info = orig_idexp_info;
   return(status);
}

/**
 * List keywords from the current language, extracted from the
 * keyword list in the color coding setup.
 * Current object must be editor control.
 *
 * @param lastid          name to search for
 * @param start_or_end    -1 means end tags only, 1 means start tags only
 * @param num_matches     number of matches found
 * @param max_matches     maximum number of matches to find
 *
 * @return 0 on success.
 */
static int _HtmlListKeywords(_str keyword_class, 
                             _str keyword_name,
                             _str lastid,
                             bool is_attrib, 
                             _str clip_prefix, 
                             int start_or_end, 
                             int &num_matches,
                             int max_matches,
                             bool exact_match,
                             bool case_sensitive)
{
   // look up the lexer definition for the current mode
   _str lexer_name=p_EmbeddedLexerName;
   if (lexer_name=="") {
      lexer_name=p_lexer_name;
   }
   handle:=_plugin_get_profile(VSCFGPACKAGE_COLORCODING_PROFILES,lexer_name);
   if (handle<0) {
      return 0;
   }
   /*
     k,csk,
     mlckeywords
     keywordattrs   keyword_name!=""
     atttrvalues    keyword_name!=""
   
   */
   tag_type := "label";
   profile_node:=_xmlcfg_set_path(handle,"/profile");
   _str re;
   if (keyword_class=="mlckeywords") {
      re='^'VSXMLCFG_PROPERTY_SEPARATOR:+'[^'VSXMLCFG_PROPERTY_SEPARATOR']*':+VSXMLCFG_PROPERTY_SEPARATOR:+'[^'VSXMLCFG_PROPERTY_SEPARATOR']*':+VSXMLCFG_PROPERTY_SEPARATOR:+'$';
      tag_type = "tag";
   } else if (keyword_class=="keywordattrs") {
      // Match tag name
      re='^'VSXMLCFG_PROPERTY_SEPARATOR:+'[^'VSXMLCFG_PROPERTY_SEPARATOR']*':+VSXMLCFG_PROPERTY_SEPARATOR:+_escape_re_chars(keyword_name):+VSXMLCFG_PROPERTY_SEPARATOR:+'$';
      tag_type = "attr";
   } else if (keyword_class=="attrvalues") {
      //list value for attribute, don't care what tag
      re='^'VSXMLCFG_PROPERTY_SEPARATOR:+'[^'VSXMLCFG_PROPERTY_SEPARATOR']*':+VSXMLCFG_PROPERTY_SEPARATOR:+'[^'VSXMLCFG_PROPERTY_SEPARATOR']*':+VSXMLCFG_PROPERTY_SEPARATOR:+_escape_re_chars(keyword_name)'$';
      tag_type = "enumc";
   } else {
      if (keyword_class=="csk") keyword_class="k";
      re='^'keyword_class:+VSXMLCFG_PROPERTY_SEPARATOR;
   }
   int array[];
   _xmlcfg_list_properties(array,handle,profile_node,re,'ir');

   // adjust lastid and lastid_prefix for clipping prefix
   if (clip_prefix!="") {
      lastid=clip_prefix:+clip_prefix;
   }

   // create a temporary view and search for the keywords
   for (i:=0;i<array._length();++i) {
      int node=array[i];
      line := "";
      if (keyword_class=="mlckeywords") {
         list:=_xmlcfg_get_attribute(handle,node,VSXMLCFG_PROPERTY_NAME);
         //re='^'VSXMLCFG_PROPERTY_SEPARATOR:+'[^'VSXMLCFG_PROPERTY_SEPARATOR']*':+VSXMLCFG_PROPERTY_SEPARATOR:+'$';
         j := 2;
         _pos_parse_wordsep(j,list,VSXMLCFG_PROPERTY_SEPARATOR,VSSTRWF_NONE,"`");
         cur:=_pos_parse_wordsep(j,list,VSXMLCFG_PROPERTY_SEPARATOR,VSSTRWF_NONE,"`");
         if (cur==null) {
            // This isn't supposed to happen
            continue;
         }
         _html_insert_context_tag_item(cur,
                                       lastid, is_attrib,
                                       clip_prefix, start_or_end,
                                       num_matches, max_matches,
                                       exact_match, case_sensitive,
                                       "", tag_type);
         continue;
      } else if (keyword_class=="keywordattrs") {
         line=_xmlcfg_get_attribute(handle,node,VSXMLCFG_PROPERTY_VALUE);
      } else if (keyword_class=="attrvalues") {
         line=_xmlcfg_get_attribute(handle,node,VSXMLCFG_PROPERTY_VALUE);
      } else {
         parse _xmlcfg_get_attribute(handle,node,VSXMLCFG_PROPERTY_NAME) with auto section (VSXMLCFG_PROPERTY_SEPARATOR) auto cur;
         doAdd := _clex_is_simple_keyword(handle,node);
         if (doAdd) {
            _html_insert_context_tag_item(cur,
                                          lastid, is_attrib,
                                          clip_prefix, start_or_end,
                                          num_matches, max_matches,
                                          exact_match, case_sensitive,
                                          "", tag_type);
         }
         continue;
      }
      //say("_CodeHelpListKeywords(): line="line);
      for (;;) {
         _str cur=parse_file(line,true,true);
         //parse line with cur line;
         if (cur=="") break;
         _html_insert_context_tag_item(cur,
                                       lastid, is_attrib,
                                       clip_prefix, start_or_end,
                                       num_matches, max_matches,
                                       exact_match, case_sensitive,
                                       "", tag_type);
      }
   }
   _xmlcfg_close(handle);
   return(0);
}
void _html_insert_context_tag_item(_str cur, _str lastid,
                                   bool is_attrib,
                                   _str clip_prefix, 
                                   int start_or_end, 
                                   int &num_matches, int max_matches,
                                   bool exact_match=false,
                                   bool case_sensitive=false,
                                   _str tag_file="",
                                   _str tag_type="label",
                                   VS_TAG_BROWSE_INFO *pargs=null,
                                   int depth=0)
{
//   say("_html_insert_context_tag_item");
   tag_init_tag_browse_info(auto cm);
   if (pargs!=null) {
      cm = *pargs;
   }

   cur_prefix := cur;
   if (!exact_match) {
      cur_prefix = substr(cur,1,length(lastid));
   }
   if (cur_prefix:==lastid || (!case_sensitive && strieq(cur_prefix,lastid))) {
      if (clip_prefix=="&") {
         // do not change case of entities
      } else if (substr(cur,1,1)=="/") {
         if (start_or_end > 0) {
            return;
         }
         cur = "/"case_html_tag(substr(cur,2),is_attrib);
      } else {
         if (start_or_end < 0) {
            return;
         }
         cur = case_html_tag(cur,is_attrib,lastid);
      }
      if (clip_prefix!="" && pos(clip_prefix,cur)==1) {
         cur=substr(cur,length(clip_prefix)+1);
      }

      cm.tag_database = tag_file;
      cm.member_name = cur;
      cm.type_name = tag_type;
      tag_insert_match_browse_info(cm);
      num_matches++;
   }
}
static void _html_insert_context_tag_array(_str (&list)[],
                                           _str lastid,
                                           bool is_attrib,
                                           _str clip_prefix, 
                                           int start_or_end,
                                           int &num_matches,
                                           int max_matches,
                                           bool exact_match,
                                           bool case_sensitive)
{
   int i,count=list._length();
   for (i=0;i<count;++i) {
      _html_insert_context_tag_item(list[i], lastid, is_attrib,
                                    clip_prefix, start_or_end, 
                                    num_matches, max_matches,
                                    exact_match, case_sensitive);
   }
}

_str _langUpcase(_str &s)
{
   if (p_EmbeddedCaseSensitive) {
      return(s);
   }
   return(upcase(s));
}
static _str dtd_element_attr_array[]=
{
   "ANY","EMPTY","()","(#PCDATA)","(#PCDATA|)*",
};
static _str dtd_attlist_attr_type_array[]=
{
   "CDATA","()","ID","IDREF","IDREFS","NMTOKEN","NMTOKENS","ENTITY","ENTITIES","NOTATION"
};
static _str dtd_attlist_cdata_options_array[]=
{
   "#REQUIRED","#IMPLIED","#FIXED"
};
static _str dtd_notation_attr_array[]=
{
   "SYSTEM","PUBLIC"
};
static _str dtd_encodings_array[]=
{
   '"UTF-8"',
   '"UTF-16"',
   '"ISO-10646-UCS-2"',
   '"ISO-10646-UCS-4"',
   '"ISO-8859-"',
   '"ISO-8859-1"',
   '"ISO-8859-2"',
   '"ISO-8859-3"',
   '"ISO-8859-4"',
   '"ISO-8859-5"',
   '"ISO-8859-6"',
   '"ISO-8859-7"',
   '"ISO-8859-8"',
   '"ISO-8859-9"',
   '"ISO-8859-10"',
   '"ISO-2022-JP"',
   '"Shift_JIS"',
   '"EUC-JP"',
   '"windows-1252"',
};

/**
 * Find a list of tags matching the given identifier after
 * evaluating the prefix expression.
 *
 * @param errorArgs          array of strings for error message arguments
 *                           refer to codehelp.e VSCODEHELPRC_
 * @param prefixexp          prefix of expression (from _[ext]_get_expression_info
 * @param lastid             last identifier in expression
 * @param lastidstart_offset seek position of last identifier
 * @param info_flags         bitset of VS_CODEHELPFLAG_*
 * @param otherinfo          used in some cases for extra information
 *                           tied to info_flags
 * @param find_parents       for a virtual class function, list all
 *                           overloads of this function
 * @param max_matches        maximum number of matches to locate
 * @param exact_match        if true, do an exact match, otherwise
 *                           perform a prefix match on lastid
 * @param case_sensitive     if true, do case sensitive name comparisons
 * @param filter_flags       bitset of VS_TAGFILTER_*
 * @param context_flags      bitset of VS_TAGCONTEXT_*
 * @param visited            hash table of prior results
 * @param depth              depth of recursive search
 *
 * @return
 *   The number of matches found or <0 on error (one of VSCODEHELPRC_*,
 *   errorArgs must be set).
 */
int _html_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                            _str lastid,int lastidstart_offset,
                            int info_flags,typeless otherinfo,
                            bool find_parents,int max_matches,
                            bool exact_match,bool case_sensitive,
                            SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                            SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
                            VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                            VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // handle javadoc tag handling case
   if (_chdebug) {
      isay(depth, "_html_find_context_tags: prefixexp="prefixexp" lastid="lastid);
   }
   tag_return_type_init(prefix_rt);
   errorArgs._makeempty();
   lang := p_LangId;

   // switch language mode to HTML or XMLDOC depending on mode
   if (!_LanguageInheritsFrom("html") && 
       !_LanguageInheritsFrom("xmldoc") && 
       !_LanguageInheritsFrom("xml") &&
       (_clex_find(0, "g") == CFG_COMMENT) && _inDocComment()) {
      _html_MaybeBuildTagFile(auto tfindex);
      lang = "html";
      if (_inXMLDoc()) {
         lang = "xmldoc";
         _xmldoc_MaybeBuildTagFile(tfindex);
      }
   }

   //say('lang='lang);
   root_count := 0;
   lastid_prefix := lastid;
   tag_files := tags_filenamea(lang);
   if (_LanguageInheritsFrom("dtd", lang)) {
      tag_files._makeempty();
   }

   // Need this for XML
   extra_tag_file := _xml_GetConfigTagFile();
   if (_chdebug) {
      isay(depth, "_html_find_context_tags: extra_tag_file="extra_tag_file);
   }
   if (extra_tag_file != "") {
      tag_files :+= extra_tag_file;
   }

   // Need this for HTML
   extra_jsp_tag_file := _jsp_GetConfigTagFile();
   if (extra_jsp_tag_file != "") {
     tag_files :+= extra_jsp_tag_file;
   }
//   html_add_tld_globals(editorctl_wid, p_window_id, root_root);

   tag_name := "";
   attribute_name := "";
   _str NamespacesHashtab:[];

   switch (substr(prefixexp,1,1)) {
   case "":
   case " ":
      // list tags for entities or comments
      break;
   case "&":
      // list entity names
      if (tag_files._length() > 0) {
         tag_list_context_globals(0, 0, lastid,
                                  false, tag_files,
                                  SE_TAG_FILTER_CONSTANT,
                                  SE_TAG_CONTEXT_ANYTHING,
                                  root_count, max_matches,
                                  exact_match, case_sensitive,
                                  visited, depth+1);
      } else if (root_count==0) {
         _HtmlListKeywords("csk","",
                           lastid,false,"&",0,
                           root_count,max_matches,
                           exact_match,case_sensitive);
         _HtmlListKeywords("k","",
                           lastid,false,"&",0,
                           root_count,max_matches,
                           exact_match,case_sensitive);
      }

      // insert entities defined in the DTD
      if (_LanguageInheritsFrom("xml")) {
         _xml_get_current_namespaces(NamespacesHashtab, depth+1);
         if (_chdebug) {
            idump(depth+1, NamespacesHashtab, "_html_find_context_tags H"__LINE__": NamespacesHashtab");
         }
         _mapxml_init_file(doForceUpdate:false, addTagsToColorCoding:false, depth+1);
         _xml_insert_namespace_context_entities(NamespacesHashtab,
                                                lastid, lastid_prefix,
                                                root_count, max_matches,
                                                exact_match, case_sensitive, depth+1);
      }
      break;
   case "%":
      // list parameter entity names
      if (_LanguageInheritsFrom("dtd")) {

         typeless line_offset="";
         parse point() with line_offset .;
         text := "";  // text before the cursor
         if (line_offset<lastidstart_offset) {
            text = get_text_safe(lastidstart_offset-line_offset,line_offset);
         }
         parse text with auto w1 auto w2;

         // IF we are not defining an entity
         if ( w1 != "<!ENTITY" ) {
            tag_list_context_globals(0, 0, lastid, 
                                     true, null,
                                     SE_TAG_FILTER_DEFINE,
                                     SE_TAG_CONTEXT_ANYTHING,
                                     root_count, max_matches,
                                     exact_match, case_sensitive,
                                     visited, depth+1);
         }
      }
      break;
   case "[":
   case "<":
      if (substr(prefixexp,1,1) == "[") {
         parse prefixexp with "[" prefixexp;
      } else {
         parse prefixexp with "<" prefixexp;
      }
      is_end_tag := false;
      if (substr(prefixexp,1,1)=="/") {
         is_end_tag=true;
         prefixexp=substr(prefixexp,2);
      }
      parse prefixexp with tag_name attribute_name "=";

      // language type determination
      isHTML := (_LanguageInheritsFrom("html", lang) || _LanguageInheritsFrom("xhtml"));
      isXML  := (_LanguageInheritsFrom("xml"));
      isXSD  := (_LanguageInheritsFrom("xsd"));
      isDTD  := (_LanguageInheritsFrom("dtd"));

      if (_last_char(prefixexp)=="=") {

         // strip quotes off of word
         strippedLeadingQuotes := false;
         strippedTrailingQuotes := false;
         if (substr(lastid,1,1)=='"') {
            strippedLeadingQuotes = true;
            lastid=strip(lastid,'B','"');
            lastid_prefix=strip(lastid_prefix,'B','"');
         } else if (substr(lastid,1,1)=="'") {
            strippedLeadingQuotes = true;
            lastid=strip(lastid,'B','"');
            lastid_prefix=strip(lastid_prefix,'B',"'");
         } else if (_last_char(lastid)=='"') {
            strippedLeadingQuotes=true;
            lastid=strip(lastid,'B','"');
         } else if (_last_char(lastid)=='"') {
            strippedLeadingQuotes=true;
            lastid=strip(lastid,'T','"');
         } else if (_last_char(lastid)=="'") {
            strippedLeadingQuotes=true;
            lastid=strip(lastid,'T',"'");
         }

         // compute arguments for listing files
         extraDir  := "";
         extraFile := strip(lastid, "B", "\"");
         last_slash := lastpos("/", lastid);
         if (last_slash==0) {
            last_slash = lastpos("\\", lastid);
         }
         if (last_slash) {
            extraDir  = substr(lastid,1,last_slash);
            extraFile = substr(lastid,last_slash+1);
         }

         // list values for attributes
         if (tag_name == "?xml") {
            if (attribute_name=="version") {
               _html_insert_context_tag_item( '"1.0"',
                                              lastid, true, "", 0,
                                              root_count, max_matches,
                                              exact_match, case_sensitive);
            } else if (attribute_name=="encoding") {
               _html_insert_context_tag_array( dtd_encodings_array,
                                               lastid, true, "", 0,
                                               root_count, max_matches,
                                               exact_match, case_sensitive);
            }

         } else if (isHTML && lowcase(attribute_name)=="src" && lowcase(tag_name)=="img") {

            // image files for HTML img tag, src attribute
            root_count += insert_files_of_extension(0, 0, 
                                                    p_buf_name,
                                                    ";gif;jpg;jpeg;png;bmp;tiff;pdf;ps;",
                                                    false, extraDir, true,
                                                    extraFile, exact_match);

         } else if (isHTML && (lowcase(attribute_name)=="id" || lowcase(attribute_name)=="class")) {

            // list ids from style sheet
            tag_list_context_globals(0, 0, lastid,
                                     true, null,
                                     SE_TAG_FILTER_MEMBER_VARIABLE,
                                     SE_TAG_CONTEXT_ALLOW_ANONYMOUS,
                                     root_count, max_matches,
                                     exact_match, case_sensitive,
                                     visited, depth+1);

            VS_TAG_BROWSE_INFO allIDs[];
            tag_get_all_matches(allIDs);
            tag_pop_matches();
            n := allIDs._length();
            return_type := (lowcase(attribute_name)=="id") ? "css-id" : "css-class";
            for (i:=0; i<n; ++i) {
               if (allIDs[i].return_type == return_type) {
                  allIDs[i].flags &= ~SE_TAG_FLAG_ANONYMOUS; // unanonymize tag
                  tag_insert_match_info(allIDs[i]);
               }
            }

         } else if (isHTML && lowcase(substr(attribute_name,1,2))=="on") {

            parse lastid with lastid "(";
            tag_list_context_globals(0, 0, lastid,
                                     true, null,
                                     SE_TAG_FILTER_ANY_PROCEDURE,
                                     SE_TAG_CONTEXT_ANYTHING,
                                     root_count, max_matches,
                                     exact_match, case_sensitive,
                                     visited, depth+1);

         } else if (isHTML && lowcase(attribute_name)=="href" && substr(lastid,1,1)=="#") {

            // list local HREF's
            lastid=substr(lastid,2);
            lastid_prefix=substr(lastid_prefix,2);
            tag_list_context_globals(0, 0, lastid,
                                     true, null,
                                     SE_TAG_FILTER_LABEL,
                                     SE_TAG_CONTEXT_ANYTHING,
                                     root_count, max_matches,
                                     exact_match, case_sensitive,
                                     visited, depth+1);

         } else if (isHTML && lowcase(attribute_name)=="href") {

            if (lastid == "") {
               // list local HREF's, with prepended '#'
               tag_push_matches();
               tag_list_context_globals(0, 0, lastid,
                                        true, null,
                                        SE_TAG_FILTER_LABEL,
                                        SE_TAG_CONTEXT_ANYTHING,
                                        root_count, max_matches,
                                        exact_match, case_sensitive,
                                        visited, depth+1);

               VS_TAG_BROWSE_INFO allAnchors[];
               tag_get_all_matches(allAnchors);
               tag_pop_matches();
               n := allAnchors._length();
               for (i:=0; i<n; ++i) {
                  allAnchors[i].member_name = "#":+allAnchors[i].member_name;
                  tag_insert_match_info(allAnchors[i]);
               }
            }

            // list files matching the given extension in the current directory
            root_count += insert_files_of_extension(0, 0,
                                                    p_buf_name,
                                                    ";html;xml;cfml;jsp;asp;php;xhtml;rhtml;pdf;",
                                                    true, extraDir, true,
                                                    extraFile,
                                                    exact_match );

         } else if (isXSD && (attribute_name=="type" || attribute_name=="base")) {

            parse lastid with lastid "(";
            tag_list_context_globals(0, 0, lastid,
                                     true, null,
                                     SE_TAG_FILTER_ANY_STRUCT,
                                     SE_TAG_CONTEXT_ANYTHING,
                                     root_count, max_matches,
                                     exact_match, case_sensitive,
                                     visited, depth+1);
            tag_list_context_globals(0, 0, lastid,
                                     true, tag_files,
                                     SE_TAG_FILTER_PROPERTY,
                                     SE_TAG_CONTEXT_ANYTHING,
                                     root_count, max_matches,
                                     exact_match, case_sensitive,
                                     visited, depth+1);

         } else if (isXSD && (attribute_name=="substitutionGroup" || attribute_name=="ref")) {

            parse lastid with lastid "(";
            tag_list_context_globals(0, 0, lastid,
                                     true, null,
                                     SE_TAG_FILTER_MISCELLANEOUS,
                                     SE_TAG_CONTEXT_ANYTHING,
                                     root_count, max_matches,
                                     exact_match, case_sensitive,
                                     visited, depth+1);

         } else if (_LanguageInheritsFrom("xmldoc", lang)) {

            // THIS IS JUST A PLACEHOLDER FOR THE REAL CODE FOR XMLDOC
            // What is supposed to go here???
            parse lastid with lastid "(";
            tag_list_context_globals(0, 0, lastid,
                                     true, null,
                                     SE_TAG_FILTER_MISCELLANEOUS,
                                     SE_TAG_CONTEXT_ANYTHING,
                                     root_count, max_matches,
                                     exact_match, case_sensitive,
                                     visited, depth+1);

         } else if( tag_name == "jsp:setProperty" || tag_name == "jsp:getProperty" ) {

            // Look only at globals in this file. UseBean ids only apply to setProperties and getProperties
            // in the same file. 
            _str this_file_only[];
            this_file_only[ this_file_only._length() ] = p_buf_name;

            // Find all of the beans defined by the useBean statements.
            // Beans are defined as vars but are really in the global space. 
            // This is so that they can be differientiated from true 
            // globals(gvars).
            tag_list_globals_of_type(0, 0, this_file_only, 
                                     SE_TAG_TYPE_VAR, 0, 0,
                                     root_count, max_matches,
                                     visited, depth+1);

         } else {

            if (_chdebug) {
               isay(depth, "_html_find_context_tags: H"__LINE__" num_matches="tag_get_num_of_matches());
               idump(depth+1, tag_files, "_html_find_context_tags H"__LINE__": tag_files");
            }
            if (tag_files._length() > 0) {
               tag_push_matches();
               num_matches := 0;
               return_type := "";
               if (tag_list_in_class(attribute_name,tag_name,0,0,tag_files,
                                     num_matches,1,SE_TAG_FILTER_MEMBER_VARIABLE,
                                     SE_TAG_CONTEXT_ONLY_INCLASS,
                                     true,false,null,null,visited,depth+1)) {
                  if (num_matches >= 1) {
                     tag_get_detail2(VS_TAGDETAIL_match_return_only,1,return_type);
                     tag_get_detail2(VS_TAGDETAIL_match_class,1,tag_name);
                     if (_chdebug) {
                        isay(depth, "_html_find_context_tags H"__LINE__": return_type="return_type);
                        isay(depth, "_html_find_context_tags H"__LINE__": tag_name="tag_name);
                     }
                  }
               }
               tag_pop_matches();
               tag_list_in_class(lastid_prefix, tag_name":"attribute_name,
                                 0, 0, tag_files,
                                 root_count, max_matches,
                                 SE_TAG_FILTER_ENUM,SE_TAG_CONTEXT_ONLY_INCLASS,
                                 exact_match, case_sensitive,
                                 null, null, visited, depth+1);
               if (root_count==0 && return_type!="") {
                  tag_list_in_class("", return_type,
                                    0, 0, tag_files,
                                    root_count, max_matches,
                                    SE_TAG_FILTER_ENUM,SE_TAG_CONTEXT_ONLY_INCLASS,
                                    exact_match, case_sensitive,
                                    null, null, visited, depth+1);
                  if (p_LangId == "docbook" && root_count == 0) {
                     _str tempLastid = lastid;
                     int status2 = find_tag_matches(join(tag_files, PATHSEP), lastid, false, max_matches);
                     root_count = tag_get_num_of_matches();
                  }
               }
            }
            if (_chdebug) {
               isay(depth, "_html_find_context_tags: H"__LINE__" num_matches="tag_get_num_of_matches());
            }
            if (_LanguageInheritsFrom("xml")) {
               _xml_get_current_namespaces(NamespacesHashtab, depth+1);
               if (_chdebug) {
                  idump(depth+1, NamespacesHashtab, "_html_find_context_tags H"__LINE__": NamespacesHashtab");
               }
               _mapxml_init_file(doForceUpdate:false, addTagsToColorCoding:false, depth+1);
               _xml_insert_namespace_context_tags_attr_values(NamespacesHashtab,
                                                              lastid, lastid_prefix,
                                                              tag_name, attribute_name,
                                                              true, "", 
                                                              root_count, max_matches, 0,
                                                              exact_match, case_sensitive, 
                                                              visited, depth+1);
               if (_chdebug) {
                  isay(depth, "_html_find_context_tags: H"__LINE__" num_matches="tag_get_num_of_matches());
               }
            }
            if (isHTML && root_count==0) {
               _HtmlListKeywords("attrvalues",
                                 upcase(attribute_name)"("upcase(tag_name)")",
                                 lastid,true,"",0,
                                 root_count,max_matches,
                                 exact_match,case_sensitive);
               if (_chdebug) {
                  isay(depth, "_html_find_context_tags: H"__LINE__" num_matches="tag_get_num_of_matches());
               }
               if (root_count==0) {
                  _HtmlListKeywords("attrvalues",
                                    upcase(attribute_name),
                                    lastid,true,"",0,
                                    root_count,max_matches,
                                    exact_match, case_sensitive);
                  if (_chdebug) {
                     isay(depth, "_html_find_context_tags: H"__LINE__" num_matches="tag_get_num_of_matches());
                  }
               }
            }
            if (attribute_name=="idref" || attribute_name=="idrefs" || attribute_name=="linkend") {
               tag_list_context_globals(0, 0, lastid,
                                        true, null,
                                        SE_TAG_FILTER_LABEL,
                                        SE_TAG_CONTEXT_ANYTHING,
                                        root_count, max_matches,
                                        exact_match, case_sensitive,
                                        visited, depth+1);
               if (_chdebug) {
                  isay(depth, "_html_find_context_tags: H"__LINE__" num_matches="tag_get_num_of_matches());
               }
            }
         }

         // Put quotes around all the captions
         VS_TAG_BROWSE_INFO allAttributes[];
         tag_get_all_matches(allAttributes);
         tag_clear_matches();
         n := allAttributes._length();
         for (i:=0; i<n; i++) {
            cap := allAttributes[i].member_name;
            if (substr(cap,1,1)!='"' && substr(cap,1,1)!="'") {
               allAttributes[i].member_name = _xml_quote_attr(cap);
            }
            tag_insert_match_info(allAttributes[i]);
         }

      } else if (tag_name!="" && _last_char(prefixexp)==" ") {

         if (tag_name!="!DOCTYPE" && tag_name!="!NOTATION") {

            if (tag_name=="?xml") {
               line_offset := "";
               parse point() with line_offset .;
               text := "";  // text before the cursor
               if (line_offset<lastidstart_offset) {
                  text = get_text_safe(lastidstart_offset-(int)line_offset,(int)line_offset);
               }
               // This only works if everthing is on the same line 
               // but this is typically the case.
               b4 := encoding := version  := "";
               parse text with b4 "version[ \t]*=","r" version "encoding[ \t]*=","r" encoding;
               if (version=="") {
                  _html_insert_context_tag_item("version", lastid, 
                                                true, "", 0,
                                                root_count, max_matches, 
                                                exact_match, case_sensitive);
               } else if (encoding=="") {
                  _html_insert_context_tag_item("encoding", lastid,
                                                true, "", 0,
                                                root_count, max_matches,
                                                exact_match, case_sensitive);
               } else {
                  _html_insert_context_tag_item("standalone", lastid,
                                                true, "", 0,
                                                root_count, max_matches,
                                                exact_match, case_sensitive);
               }

            } else {

               // first list XML namespace attributes
               if (_LanguageInheritsFrom("xml")) {
                  _xml_get_current_namespaces(NamespacesHashtab, depth+1);
                  if (_chdebug) {
                     idump(depth+1, NamespacesHashtab, "_html_find_context_tags H"__LINE__": NamespacesHashtab");
                  }
                  _mapxml_init_file(doForceUpdate:false, addTagsToColorCoding:false, depth+1);
                  _xml_insert_namespace_context_tags_attrs(NamespacesHashtab,
                                                           lastid,lastid_prefix, 
                                                           tag_name, true, "", 
                                                           root_count, max_matches, 0,
                                                           exact_match, case_sensitive,
                                                           visited, depth+1);
                  if (_chdebug) {
                     isay(depth, "_html_find_context_tags: number of XML attributes="root_count);
                  }
               }
               // list attribute names
               if (tag_files._length() > 0) {
                  if (_chdebug) {
                     isay(depth, "_html_find_context_tags: list attributes in tag file: tag_name="tag_name);
                  }
                  tag_list_in_class(lastid_prefix, tag_name, 0, 0, tag_files,
                                    root_count, max_matches,
                                    SE_TAG_FILTER_MEMBER_VARIABLE,SE_TAG_CONTEXT_ONLY_INCLASS,
                                    exact_match, case_sensitive, 
                                    null, null, visited, depth+1);
                  if (_chdebug) {
                     isay(depth, "_html_find_context_tags H"__LINE__": num attributes in tag files="root_count);
                  }
               } else if (!_LanguageInheritsFrom("xml") && root_count==0) {
                  if (_chdebug) {
                     isay(depth, "_html_find_context_tags: list attribute keywords from color coding");
                  }
                  _HtmlListKeywords("keywordattrs",
                                    upcase(tag_name),
                                    lastid,true,"",0,
                                    root_count,max_matches,
                                    exact_match, case_sensitive);
               }
               // if we do not have a DTD or Schema, 
               // the attr name could be just any tag that was used elsewhere
               if (_LanguageInheritsFrom("xml") && root_count==0) {
                  if (_chdebug) {
                     isay(depth, "_html_find_context_tags: look for attributes used in this file");
                  }
                  attr_name := "";
                  type_name := "";
                  seekpos := 0;
                  cid := tag_find_context_iterator(lastid, exact_match, case_sensitive, false, null);
                  while (cid > 0) {
                     tag_get_detail2(VS_TAGDETAIL_context_type, cid, attr_name);
                     tag_get_detail2(VS_TAGDETAIL_context_type, cid, type_name);
                     tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, cid, seekpos);
                     if (_chdebug) {
                        isay(depth, "_html_find_context_tags: attr_name="attr_name);
                     }
                     if (type_name == "var" && seekpos != lastidstart_offset) {
                        tag_insert_match_fast(VS_TAGMATCH_context, cid);
                        if (++root_count > max_matches) break;
                     }
                     if (_CheckTimeout()) break;
                     cid = tag_next_context_iterator(lastid, cid, exact_match, case_sensitive, false, null);
                  }
               }
               // adjust casing of HTML attributes to preserve user-typed case
               if (!p_LangCaseSensitive) {
                  if (_chdebug) {
                     isay(depth, "_html_find_context_tags: lowcase matched attributes");
                  }
                  VS_TAG_BROWSE_INFO matches[];
                  tag_get_all_matches(matches);
                  tag_clear_matches();
                  for (i:=0; i<matches._length(); i++) {
                     if (matches[i].class_name != "" && tag_tree_type_is_data(matches[i].type_name=="var")) {
                        matches[i].member_name = case_html_tag(matches[i].member_name, true, lastid);
                     }
                     tag_insert_match_info(matches[i]);
                  }
               }
            }
         }

      } else {

         // make sure namesapce info and tag files are set up for XML
         if (_LanguageInheritsFrom("xml")) {
            _xml_get_current_namespaces(NamespacesHashtab, depth+1);
            if (_chdebug) {
               idump(depth+1, NamespacesHashtab, "_html_find_context_tags H"__LINE__": NamespacesHashtab");
            }
            _mapxml_init_file(doForceUpdate:false, addTagsToColorCoding:false, depth+1);
         }

         // Look up the parent tag in this XML context and find what tags
         // are allowed in it's context model.
         bool tagsAllowedInContextModel:[] = null;
         parent_tag_name := "";
         if (isXML || isXSD || isHTML) {
            save_pos(auto before_parent_pos);
            status := _xml_parent(parent_tag_name);
            if (status > 0 && parent_tag_name != "") {
               if (_chdebug) {
                  isay(depth, "_html_find_context_tags: parent tag="parent_tag_name);
               }
               if (is_end_tag) {
                  tagsAllowedInContextModel:[parent_tag_name] = true;
                  if (isHTML || !case_sensitive) {
                     tagsAllowedInContextModel:[lowcase(parent_tag_name)] = true;
                     tagsAllowedInContextModel:[upcase(parent_tag_name)]  = true;
                  }
                  if (_chdebug) {
                     isay(depth, "_html_find_context_tags: ONLY MATCHING END TAG ALLOWED IN CONTEXT: "parent_tag_name);
                  }
               } else {
                  tag_push_matches();
                  num_parent_tags := 0;
                  _xml_insert_namespace_context_tags(NamespacesHashtab,
                                                     parent_tag_name, parent_tag_name,
                                                     is_attrib:false, 
                                                     clip_prefix:"", 
                                                     start_or_end:0,
                                                     num_parent_tags, max_matches,
                                                     exact_match:true, case_sensitive:true, 
                                                     insertTagDatabaseNames:false,
                                                     depth+1);
                  tag_list_context_globals(0, 0, 
                                           parent_tag_name, true, 
                                           tag_files, 
                                           SE_TAG_FILTER_MISCELLANEOUS, 
                                           SE_TAG_CONTEXT_ANYTHING, 
                                           num_parent_tags, 10, 
                                           true, case_sensitive, 
                                           visited, depth+1);
                  num_parent_tags = tag_get_num_of_matches();
                  for (i:=1; i<=num_parent_tags; i++) {
                     tag_get_match_browse_info(i, auto parent_cm);
                     if (_chdebug) {
                        tag_browse_info_dump(parent_cm, "_html_find_contxt_tags: parent_cm["i"]:", depth+1);
                     }
                     // if the length is greater than 2000, it might have been a
                     // truncated content model, if so, just list everything
                     if (parent_cm.arguments != null && length(parent_cm.arguments) < 2000) {
                        // special cases for a few content models that do not allow child tags
                        if (parent_cm.arguments == "ANY") {
                           tagsAllowedInContextModel._makeempty();
                           break;
                        } else if (parent_cm.arguments == "CDATA" || 
                                   parent_cm.arguments == "#PCDATA" || 
                                   parent_cm.arguments == "EMPTY") {
                           continue;
                        }
                        word_re := _clex_identifier_re();
                        word_re = stranslate(word_re, '', '?');
                        arg_pos := 1;
                        loop {
                           status = pos(word_re, parent_cm.arguments, arg_pos, 'r');
                           if (status <= 0) break;
                           arg_pos = status+pos('');
                           child_tag_name := get_match_substr(parent_cm.arguments);
                           if (!tagsAllowedInContextModel._indexin(child_tag_name)) {
                              tagsAllowedInContextModel:[child_tag_name] = true;
                              if (isHTML || !case_sensitive) {
                                 tagsAllowedInContextModel:[lowcase(child_tag_name)] = true;
                                 tagsAllowedInContextModel:[upcase(child_tag_name)]  = true;
                              }
                              if (_chdebug) {
                                 isay(depth, "_html_find_context_tags: ALLOWED IN CONTEXT: "child_tag_name);
                              }
                           }
                        }
                     }
                  }
                  tag_pop_matches();
               }
            }
            restore_pos(before_parent_pos);
         }

         // first insert tags from namespaces
         if (_LanguageInheritsFrom("xml")) {
            _xml_insert_namespace_context_tags(NamespacesHashtab,
                                               lastid, lastid_prefix,
                                               is_attrib:false, 
                                               clip_prefix:"", 
                                               start_or_end:0,
                                               root_count, max_matches,
                                               exact_match, case_sensitive:true, 
                                               insertTagDatabaseNames:false,
                                               depth+1,
                                               tagsAllowedInContextModel);
         }

         if(_LanguageInheritsFrom("html", lang)) {
            _html_insert_namespace_context_tags(lastid, lastid_prefix,
                                                is_attrib:false, 
                                                clip_prefix:"", 
                                                start_or_end:0,
                                                root_count, max_matches,
                                                exact_match, case_sensitive:true, 
                                                insertTagDatabaseNames:false,
                                                depth+1,
                                                tagsAllowedInContextModel);
         }

         // special cases for DTDs
         if (isDTD) {
            typeless line_offset="";
            parse point() with line_offset .;
            w1 := w2 := w3 := text := "";  // text before the cursor
            if (line_offset<lastidstart_offset) {
               text=get_text_safe(lastidstart_offset-line_offset,line_offset);
            }
            if (tag_name=="!ELEMENT") {
               parse text with w1 w2 w3;
               if (w1=="<!ELEMENT" && w2!="" && (w3=="" || !pos('[ \t]',w3,1,'r'))) {
               //if (w1=='<!ELEMENT' && w2!="" && last_char(text)=="") {
                  // Since its hard to remember what the syntax is,
                  // we insert more than just an identifier some times.
                  // The down side is that the list terminates when we type a
                  // non-identifier character like '('.  But this seems reasonable.
                  _html_insert_context_tag_array( dtd_element_attr_array,
                                                  lastid,true,"", 0,
                                                  root_count, max_matches,
                                                  exact_match, case_sensitive);
               }
            } else if (tag_name=="!ATTLIST") {
               parse text with w1 w2;
               // Here we try to support case where first attribute is defined
               // on the same line.  Obviously this code is line dependent.  If this
               // is a problem, we can change it later.
               if (w1=="<!ATTLIST" && pos('[ \t]',w2,1,'r')) {
                  parse text with . . w1 w2;
               }
               if (w1=="<!ATTLIST") {
                  tag_list_context_globals(0, 0, lastid,
                                           true, null,
                                           SE_TAG_FILTER_MISCELLANEOUS,
                                           SE_TAG_CONTEXT_ANYTHING,
                                           root_count, max_matches,
                                           exact_match, case_sensitive,
                                           visited, depth+1);
               } else if(w1!="" && w1!=">" && (w2=="" || !pos('[ \t]',w2,1,'r'))) {
                  _html_insert_context_tag_array( dtd_attlist_attr_type_array,
                                                  lastid, true, "", 0,
                                                  root_count, max_matches, 
                                                  exact_match, case_sensitive);

               } else if(w2=="CDATA" || w2=="ID" || w2=="IDREF" || w2=="IDREFS" || w2=="NMTOKEN" || w2=="NMTOKENS" ||
                         w2=="ENTITY" || w2=="ENTITIES") {
                  _html_insert_context_tag_array( dtd_attlist_cdata_options_array,
                                                  lastid, true, "", 0,
                                                  root_count, max_matches,
                                                  exact_match, case_sensitive);
               }
            } else if (tag_name=="!NOTATION" || tag_name=="!ENTITY") {
               parse text with w1 w2 w3;
               if (w1=="<"tag_name && w2!="" && (w3=="" || !pos('[ \t]',w3,1,'r'))) {
                  _html_insert_context_tag_array( dtd_notation_attr_array,
                                                  lastid, true, "", 0,
                                                  root_count, max_matches,
                                                  exact_match, case_sensitive);
               }
            } else if (tag_name=="?xml") {
               // This only works if everthing is on the same line but this is typically the case.
               typeless encoding="";
               parse text with . "version[ \t]*=",'r' version "encoding[ \t]*=",'r' encoding;
               if (version=="") {
                  _html_insert_context_tag_item( "version", 
                                                 lastid, true, "", 0,
                                                 root_count, max_matches, 
                                                 exact_match, case_sensitive);
               } else {
                  _html_insert_context_tag_item( "encoding", 
                                                 lastid, true,"", 0,
                                                 root_count, max_matches,
                                                 exact_match, case_sensitive);
               }
            }
         }

         // adjust for listing start or end tags
         maybe_end_tag_context_flags := SE_TAG_CONTEXT_ANYTHING;
         maybe_end_tag_prefix := "";
         if (is_end_tag) {
            maybe_end_tag_context_flags = SE_TAG_CONTEXT_ONLY_NON_FINAL;
            maybe_end_tag_prefix = "/";
         }

         // list tag names or end tag names matching prefix expression
         if (tag_files._length() > 0) {
            VS_TAG_BROWSE_INFO matched_tags[];
            tag_push_matches();
            num_tags := 0;
            tag_list_context_globals(0, 0, lastid,
                                     false, tag_files,
                                     SE_TAG_FILTER_MISCELLANEOUS,
                                     SE_TAG_CONTEXT_ANYTHING|maybe_end_tag_context_flags,
                                     num_tags, max_matches,
                                     exact_match, case_sensitive,
                                     visited, depth+1);
            num_tags = tag_get_num_of_matches();
            for (i:=1; i<=num_tags; i++) {
               tag_get_match_browse_info(i, auto cmi);
               if (_chdebug) {
                  isay(depth+1, "_html_find_context_tags H"__LINE__": CANDIDATE TAG="cmi.member_name" tag_file="cmi.tag_database);
               }
               // only allowing tags from the parent tags content model?
               if (tagsAllowedInContextModel._length() > 0) {
                  if (isHTML || !case_sensitive) {
                     if (!tagsAllowedInContextModel._indexin(upcase(cmi.member_name))) {
                        if (_chdebug) {
                           isay(depth+1, "_html_find_context_tags H"__LINE__": SKIPPING TAG="cmi.member_name", NOT ALLOWED IN CONTEXT");
                        }
                        continue;
                     }
                  } else {
                     if (!tagsAllowedInContextModel._indexin(cmi.member_name)) {
                        if (_chdebug) {
                           isay(depth+1, "_html_find_context_tags H"__LINE__": SKIPPING XML TAG="cmi.member_name", NOT ALLOWED IN CONTEXT");
                        }
                        continue;
                     }
                  }
               }
               cmi.arguments="";
               matched_tags :+= cmi;
            }
            tag_pop_matches();
            foreach (auto cmi in matched_tags) {
               tag_insert_match_info(cmi);
               root_count++;
            }

            // try again if no tags matched the context
            if (root_count == 0 && lastid != "") {
               if (_chdebug) {
                  isay(depth+1, "_html_find_context_tags H"__LINE__": LISTING TAGS MATCHING: "lastid);
               }
               tag_list_context_globals(0, 0, lastid,
                                        false, tag_files,
                                        SE_TAG_FILTER_MISCELLANEOUS,
                                        SE_TAG_CONTEXT_ANYTHING|maybe_end_tag_context_flags,
                                        root_count, max_matches,
                                        exact_match, case_sensitive,
                                        visited, depth+1);
            }

         }
         if (root_count==0) {
            _HtmlListKeywords("mlckeywords","",
                              lastid,false,
                              maybe_end_tag_prefix,1,
                              root_count, max_matches,
                              exact_match,case_sensitive);
         }

         // if we do not have a DTD or Schema, 
         // the tag name could be just any tag that was used elsewhere
         if (_LanguageInheritsFrom("xml")) {
            bool tagsInserted:[];
            type_name := "";
            seekpos := 0;
            cid := tag_find_context_iterator(lastid, exact_match, case_sensitive, false, null);
            while (cid > 0) {
               // check that we did not already insert a tag with this name
               tag_get_detail2(VS_TAGDETAIL_context_name, cid, tag_name);
               if (tagsInserted._indexin(tag_name)) {
                  cid = tag_next_context_iterator(lastid, cid, exact_match, case_sensitive, false, null);
                  continue;
               }
               // only allowing tags from the parent tags content model?
               tag_get_detail2(VS_TAGDETAIL_context_type, cid, type_name);
               if (type_name == "taguse" || type_name == "tag") {
                  if (tagsAllowedInContextModel._length() > 0) {
                     if (!tagsAllowedInContextModel._indexin(tag_name)) {
                        cid = tag_next_context_iterator(lastid, cid, exact_match, case_sensitive, false, null);
                        continue;
                     }
                  }
               }
               tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, cid, seekpos);
               if (type_name == "taguse" && seekpos != lastidstart_offset) {
                  tag_get_context_info(cid, auto cmi);
                  cmi.arguments="";
                  tag_insert_match_info(cmi);
                  tagsInserted:[cmi.member_name] = true;
                  if (++root_count > max_matches) break;
               } else if (type_name == "tag" && seekpos != lastidstart_offset) {
                  tag_get_context_info(cid, auto cmi);
                  cmi.arguments="";
                  tag_insert_match_info(cmi);
                  tagsInserted:[cmi.member_name] = true;
                  if (++root_count > max_matches) break;
               }
               if (_CheckTimeout()) break;
               cid = tag_next_context_iterator(lastid, cid, exact_match, case_sensitive, false, null);
            }
         }

         // adjust case of HTML tags to match user-typed tags
         if (!p_LangCaseSensitive) {
            VS_TAG_BROWSE_INFO matches[];
            tag_get_all_matches(matches);
            tag_clear_matches();
            for (i:=0; i<matches._length(); i++) {
               if (matches[i].class_name == "" && matches[i].type_name=="tag") {
                  matches[i].member_name = case_html_tag(matches[i].member_name, false, lastid);
               }
               tag_insert_match_info(matches[i]);
            }
         }
      }
      break;

   default:
      // messed up here
      errorArgs[1]=prefixexp;
      return(VSCODEHELPRC_UNABLE_TO_EVALUATE_CONTEXT);
   }

   if (_chdebug) {
      tag_dump_matches("_html_find_context_tags", depth);
   }

   // Return 0 indicating success if anything was found
   errorArgs[1] = lastid;
   return (root_count == 0)? VSCODEHELPRC_NO_SYMBOLS_FOUND:0;
}

int _bbc_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                           _str lastid,int lastidstart_offset,
                           int info_flags,typeless otherinfo,
                           bool find_parents,int max_matches,
                           bool exact_match,bool case_sensitive,
                           SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                           SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
                           VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                           VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   return _html_find_context_tags(errorArgs,
                                  prefixexp,lastid,lastidstart_offset,
                                  info_flags,otherinfo,find_parents,
                                  max_matches,exact_match,case_sensitive,
                                  filter_flags,context_flags,
                                  visited,depth,prefix_rt);
}

/**
 * @see _html_get_decl
 */
_str _xml_get_decl(_str lang,
                    VS_TAG_BROWSE_INFO &info,
                    int flags=0,
                    _str decl_indent_string="",
                    _str access_indent_string="")
{
   return(_html_get_decl(lang,info,flags,decl_indent_string,access_indent_string));
}
_str _dtd_get_decl(_str lang,
                    VS_TAG_BROWSE_INFO &info,
                    int flags=0,
                    _str decl_indent_string="",
                    _str access_indent_string="")
{
   return(_html_get_decl(lang,info,flags,decl_indent_string,access_indent_string));
}
/**
 * Format the given tag for display as the an HTML tag or entity.
 * delegates to _c_get_decl for tag types that are not HTML.
 *
 * @param lang           Current language ID {@see p_LangId} 
 * @param info           tag information
 *                       <UL>
 *                       <LI>info.class_name
 *                       <LI>info.member_name
 *                       <LI>info.type_name;
 *                       <LI>info.flags;
 *                       <LI>info.return_type;
 *                       <LI>info.arguments
 *                       <LI>info.exceptions
 *                       </UL>
 * @param flags          bitset of VSCODEHELPDCLFLAG_*
 * @param decl_indent_string    string to indent declaration with.
 * @param access_indent_string  string to indent public: with.
 *
 * @return string holding formatted declaration.
 *
 * @see _c_get_decl
 */
_str _html_get_decl(_str lang, VS_TAG_BROWSE_INFO &info, int flags=0,
                    _str decl_indent_string="",
                    _str access_indent_string="")
{
   tag_name := info.member_name;
   verbose := (flags&VSCODEHELPDCLFLAG_VERBOSE) != 0;

   switch (info.type_name) {
   case "tag":
   case "taguse":
      if (!verbose) {
         return decl_indent_string"<"tag_name;
      }
      if (substr(tag_name,1,1)=="%" || substr(tag_name,1,1)=="?") {
         return decl_indent_string:+"<"tag_name" ... "substr(tag_name,1,1)">";
      }
      if (info.flags & SE_TAG_FLAG_FINAL) {
         return decl_indent_string:+"<"tag_name">";
      } else {
         return decl_indent_string:+"<"tag_name"> ... </"tag_name">";
      }
   case "group":
   case "var":
   case "attr":
      if (!verbose) {
         return decl_indent_string"<"info.class_name" "tag_name;
      }
      return decl_indent_string:+"<"info.class_name" "tag_name"=...>";
   case "const":
      if (info.class_name=="") {
         return decl_indent_string:+"&"tag_name";";
      }
      break;
   case "enumc":
      if (lastpos(":",info.class_name)) {
         tag_name   = substr(info.class_name,1,pos('s')-1);
         attr_name := substr(info.class_name,pos('s')+1);
         if (verbose) {
            return decl_indent_string:+"<"tag_name" "attr_name"=\""info.member_name"\">";
         }
         return decl_indent_string:+"<"tag_name" "attr_name"=\""info.member_name;
      }
      break;
   default:
      break;
   }
   // delegate to C version for anything not HTML specific
   return _c_get_decl(lang,info,flags,decl_indent_string,access_indent_string);
}

/**
 * @see _html_get_decl
 */
_str _bbc_get_decl(_str lang, VS_TAG_BROWSE_INFO &info, int flags=0,
                   _str decl_indent_string="",
                   _str access_indent_string="")
{
//   say("_bbc_get_decl: type_name="type_name);
   tag_name := info.member_name;
   verbose := (flags&VSCODEHELPDCLFLAG_VERBOSE) != 0;

   switch (info.type_name) {
   case "tag":
   case "taguse":
      if (!verbose) {
         return decl_indent_string:+"["tag_name;
      }
      if (info.flags & SE_TAG_FLAG_FINAL) {
         return decl_indent_string:+"["tag_name"]";
      } else {
         return decl_indent_string:+"["tag_name"] ... [/"tag_name"]";
      }
   case "group":
   case "var":
      if (!verbose) {
         return decl_indent_string:+"["info.class_name" "tag_name;
      }
      return decl_indent_string:+"["info.class_name" "tag_name"=...]";
   case "const":
      if (info.class_name=="") {
         return decl_indent_string:+":"tag_name;
      }
      break;
   case "enumc":
      if (lastpos(":",info.class_name)) {
         tg_name := substr(info.class_name,1,pos("s")-1);
         attr_name := substr(info.class_name,pos("s")+1);
         return decl_indent_string:+"["tg_name" "attr_name"=\""info.member_name"\"]";
      }
      break;
   default:
      break;
   }
   // delegate to C version for anything not HTML specific
   return _c_get_decl(lang,info,flags,decl_indent_string,access_indent_string);
}

_str _xml_quote_attr(_str attrvalue)
{
   if (!pos('"',attrvalue)) {
      return('"'attrvalue'"');
   }
   if (!pos("'",attrvalue)) {
      return("'"attrvalue"'");
   }
   typeless result="";
   int start;
   for (start=1;;) {
      if (start>length(attrvalue)) {
         return(result);
      }
      i := pos('"',attrvalue,start);
      if (!i) {
         result :+= '"'substr(attrvalue,start)'"';
         return(result);
      }
      if (i>start) {
         result :+= '"'substr(attrvalue,start,i-start)'"';
      }
      result :+= "'\"'";
      start=i+1;
   }
}

void _html_autocomplete_before_replace(AUTO_COMPLETE_INFO &word,
                                       VS_TAG_IDEXP_INFO &idexp_info, 
                                       _str terminationKey="")
{
   if (idexp_info == null || idexp_info.prefixexp == null) {
      return;
   }

   lch := _last_char(idexp_info.prefixexp);
   switch (lch) {
   case "<":
   case "/":
      // tag name or end tag
      word.insertWord = case_html_tag(word.insertWord, false, idexp_info.lastid);
      break;
   case " ":
      // attribute name
      word.insertWord = case_html_tag(word.insertWord, true, idexp_info.lastid);
      break;
   case "&":
      // append semicolon if there isn't one
      if (_first_char(word.insertWord) != "&" && 
          _last_char(word.insertWord)  != ";" &&
          terminationKey != ";" && get_text_safe() != ";") {
         word.insertWord :+= ";";
      }
      break;
   case "%":
      // don't change case of entities
      break;
   case "=":
      // attribute value
      parse idexp_info.prefixexp with auto tag_name auto attrname;
      isFunction := (word.symbol != null && tag_tree_type_is_func(word.symbol.type_name));
      if (!isFunction && !strieq(attrname,"href") && !strieq(attrname,"src")) {
         word.insertWord = case_html_tag(word.insertWord, true, idexp_info.lastid);
      }
      break;
   default:
      break;
   }
}

void _xml_autocomplete_before_replace(AUTO_COMPLETE_INFO &word,
                                      VS_TAG_IDEXP_INFO &idexp_info, 
                                      _str terminationKey="")
{
   _html_autocomplete_before_replace(word, idexp_info, terminationKey);
}

bool _html_autocomplete_after_replace(AUTO_COMPLETE_INFO &word,
                                         VS_TAG_IDEXP_INFO &idexp_info, 
                                         _str terminationKey="")
{
   if (idexp_info == null || idexp_info.prefixexp == null) {
      return true;
   }
   if (_first_char(idexp_info.prefixexp) != "<") {
      return true;
   }

   // parse the tag name and attribute name out of the prefix expression
   parse idexp_info.prefixexp with "<" auto tag_name auto attribute_name "=";
   fixFileSeparator := "";
   if (lowcase(tag_name)=="img" && lowcase(attribute_name)=="src") {
      fixFileSeparator = true;
   }
   if (lowcase(attribute_name)=="href") {
      fixFileSeparator = true;
   }
   if (_last_char(idexp_info.prefixexp) != "=") {
      fixFileSeparator = false;
   }

   // this is only an issue for HTML and XHTML modes.
   isHTML := (_LanguageInheritsFrom("html") || _LanguageInheritsFrom("xhtml"));

   // fix directory names with trailing path separators
   if ( isHTML && fixFileSeparator ) {
      lc := _last_char(word.insertWord);
      if (terminationKey:==FILESEP || terminationKey:==FILESEP2) {
         if (lc == "\'" || lc == "\"") {
            lc = substr(word.insertWord, length(word.insertWord)-1, 1);
            if (lc != FILESEP && lc != FILESEP2) return false;
            left();
         } 
         if (lc == FILESEP || lc == FILESEP2) {
            left();
            _delete_char();
         }
      } else if (terminationKey:==ENTER || terminationKey:==TAB || terminationKey:==" ") {
         if (lc == "\'" || lc == "\"") {
            lc = substr(word.insertWord, length(word.insertWord)-1, 1);
            if (lc != FILESEP && lc != FILESEP2) return false;
            left();
            autocomplete();
            return false;
         }
      }
   }

   // if we are replacing the tag name, and they hit ENTER, TAB or SPACE,
   // then go directly into function help.
   if ((terminationKey==ENTER || terminationKey=="") && idexp_info.prefixexp == "<" ) {
      function_argument_help();
      auto_codehelp_key();
      return false;
   }

   // Here we autoamtically insert the '=' after selecting an attribute.
   // Unknown processing instructions and tags with start with '!' (!DOCTYPE, !ELEMENT, etc.) don't get here.
   if ((terminationKey == ENTER || terminationKey=="") && 
       tag_name != "" && attribute_name=="" &&
       _first_char(tag_name) != "!" && _first_char(tag_name) != "?" &&
       _last_char(idexp_info.prefixexp) == " ") {
      last_event("=");
      auto_codehelp_key();
      return false;
   }

   // finished, not a special case
   return true;
}

bool _xml_autocomplete_after_replace(AUTO_COMPLETE_INFO &word,
                                      VS_TAG_IDEXP_INFO &idexp_info, 
                                      _str terminationKey="")
{
   return _html_autocomplete_after_replace(word, idexp_info, terminationKey);
}

/**
 * Context Tagging&reg; hook function for function (tag) help.
 * Finds the start location of an HTML tag and the tag name.
 *
 * @param errorArgs                array of strings for error message arguments
 *                                 refer to codehelp.e VSCODEHELPRC_*
 * @param OperatorTyped            When true, user has just typed last
 *                                 character of operator.
 *                                 Example: p-> &lt;Cursor Here&gt;
 *                                 This should be false if cursorInsideArgumentList is true.
 * @param cursorInsideArgumentList When true, user requested function help
 *                                 when the cursor was inside an argument list.
 *                                 Example: MessageBox(...,&lt;Cursor Here&gt;...)
 *                                 Here we give help on MessageBox
 * @param FunctionNameOffset       (reference) Offset to start of function name.
 * @param ArgumentStartOffset      (reference) Offset to start of first argument
 * @param flags                    (reference) function help flags
 *
 * @return 0 when successful
 * <PRE>
 *   VSCODEHELPRC_CONTEXT_NOT_VALID
 *   VSCODEHELPRC_NOT_IN_ARGUMENT_LIST
 *   VSCODEHELPRC_NO_HELP_FOR_FUNCTION
 * </PRE>
 *
 * @see _do_function_help
 * @see _do_default_fcthelp_get
 * @see _do_default_fcthelp_get_start
 */
int _html_fcthelp_get_start(_str (&errorArgs)[],
                            bool OperatorTyped,
                            bool cursorInsideArgumentList,
                            int &FunctionNameOffset,
                            int &ArgumentStartOffset,
                            int &flags,
                            int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   VS_TAG_IDEXP_INFO idexp_info;
   tag_idexp_info_init(idexp_info);
   struct VS_TAG_RETURN_TYPE visited:[];

   int status=_html_get_expression_info(OperatorTyped, idexp_info, visited);
   errorArgs = idexp_info.errorArgs;
   flags = idexp_info.info_flags;

   // not a tag, or an end tag, then skip function help
   if (substr(idexp_info.prefixexp,1,1)!="<" || substr(idexp_info.prefixexp,1,2)=="</") {
      return VSCODEHELPRC_NOT_IN_ARGUMENT_LIST;
   }
   // find start of tag name
   offset := 2;
   word_chars := _clex_identifier_chars();
   while (offset<length(idexp_info.prefixexp) && !pos('['word_chars'!%]',substr(idexp_info.prefixexp,offset,1),1,'r')) {
      ++offset;
   }
   FunctionNameOffset=idexp_info.prefixexpstart_offset+offset;
   ArgumentStartOffset=idexp_info.lastidstart_offset;
   return(0);
}
/**
 * @see _html_fcthelp_get_start
 */
int _xml_fcthelp_get_start(_str (&errorArgs)[],
                           bool OperatorTyped,
                           bool cursorInsideArgumentList,
                           int &FunctionNameOffset,
                           int &ArgumentStartOffset,
                           int &flags,
                           int depth=0)
{
   return(
      _html_fcthelp_get_start(
         errorArgs,
         OperatorTyped,
         cursorInsideArgumentList,
         FunctionNameOffset,
         ArgumentStartOffset,flags,
         depth));
}

/**
 * Context Tagging&reg; hook function for retrieving the information about
 * each tag possibly matching the current tag that help has been
 * requested for.
 *
 * If there is no help for the tag, a non-zero value is returned
 * and a message is usually displayed.
 *
 * If the end of the statement is found, a non-zero value is
 * returned.  This happens when a user types the closing greater
 * than '>' sign or does some weird paste of statements.
 *
 * If there is no help for a tag and it is not the first
 * function, FunctionHelp_list is filled in with a message
 * <PRE>
 *     FunctionHelp_list._makeempty();
 *     FunctionHelp_list[0].proctype=message;
 *     FunctionHelp_list[0].argstart[0]=1;
 *     FunctionHelp_list[0].arglength[0]=0;
 *     FunctionHelp_list[0].return_type=0;
 * </PRE>
 *
 * @param errorArgs                 array of strings for error message arguments
 *                                  refer to codehelp.e VSCODEHELPRC_*
 * @param FunctionHelp_list         Structure is initially empty.
 *                                  FunctionHelp_list._isempty()==true
 *                                  You may set argument lengths to 0.
 *                                  See VSAUTOCODE_ARG_INFO structure in slick.sh.
 * @param FunctionHelp_list_changed (reference)Indicates whether the data in
 *                                  FunctionHelp_list has been changed.
 *                                  Also indicates whether current
 *                                  parameter being edited has changed.
 * @param FunctionHelp_cursor_x     (reference) Indicates the cursor x position
 *                                  in pixels relative to the edit window
 *                                  where to display the argument help.
 * @param FunctionHelp_HelpWord     Keyword to supply to help system
 * @param FunctionNameStartOffset   The text between this point and
 *                                  ArgumentEndOffset needs to be parsed
 *                                  to determine the new argument help.
 * @param flags                     function help flags (from fcthelp_get_start)
 *
 * @return
 *   Returns 0 if we want to continue with function argument
 *   help.  Otherwise a non-zero value is returned and a
 *   message is usually displayed.
 *   <PRE>
 *      1   Not a valid context
 *      2-9  (not implemented yet)
 *      10   Context expression too complex
 *      11   No help found for current function
 *      12   Unable to evaluate context expression
 *   </PRE>
 *
 * @see _do_function_help
 * @see _do_default_fcthelp_get_start
 * @see _c_fcthelp_get
 */
int _html_fcthelp_get(_str (&errorArgs)[],
                      VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                      bool &FunctionHelp_list_changed,
                      int &FunctionHelp_cursor_x,
                      _str &FunctionHelp_HelpWord,
                      int FunctionNameStartOffset,
                      int flags,
                      VS_TAG_BROWSE_INFO symbol_info=null,
                      VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // what happened last time were were here?
   static VS_TAG_IDEXP_INFO prev_info;

   static _str prev_FunctionName;
   static int  prev_FunctionOffset;
   static int  prev_ParamNum;

   VS_TAG_IDEXP_INFO idexp_info;
   tag_idexp_info_init(idexp_info);
   idexp_info.info_flags = flags;

   int status=_html_get_expression_info(false, idexp_info, visited, depth+1);

   // not a tag, or an end tag, then skip function help
   if (substr(idexp_info.prefixexp,1,1)!="<" || substr(idexp_info.prefixexp,1,2)=="</") {
      return VSCODEHELPRC_NOT_IN_ARGUMENT_LIST;
   }

   // compute the tag name column
   save_pos(auto p);
   _GoToROffset(idexp_info.prefixexpstart_offset);
   start_col := p_col;
   restore_pos(p);
   if (!p_IsTempEditor) {
      FunctionHelp_cursor_x=(start_col-p_col)*p_font_width+p_cursor_x;
   }

   // decompose prefixexp into tag name and current attribute
   tag_name := attr_name := "";
   parse idexp_info.prefixexp with "<" tag_name attr_name;
   if (pos("=",attr_name) && tag_name!="") {
      parse attr_name with attr_name "=";
   } else {
      attr_name=idexp_info.lastid;
   }
   if (tag_name=="") {
      tag_name=idexp_info.lastid;
      attr_name="";
   }
   FunctionHelp_HelpWord=tag_name;

   // has the function help changed since last time?
   FunctionHelp_list_changed=false;
   if(FunctionHelp_list._isempty()) {
      FunctionHelp_list_changed=true;
      prev_FunctionName="";
      prev_FunctionOffset=-1;
   }
   // check if anything has changed
   if (prev_info.prefixexp :== idexp_info.prefixexp &&
       prev_FunctionName :== tag_name &&
       prev_info.prefixexpstart_offset :== idexp_info.prefixexpstart_offset &&
       prev_info.otherinfo :== idexp_info.otherinfo &&
       prev_info.info_flags == flags &&
       prev_info.lastidstart_col == idexp_info.lastidstart_col) {
      return(0);
   }

   // list the tags matching the given tag name
   typeless tag_files=tags_filenamea(p_LangId);
   _str extra_tag_file=_xml_GetConfigTagFile();
   if (extra_tag_file!="") {
      tag_files[tag_files._length()]=extra_tag_file;
   }

   tag_clear_matches();
   tag_count := 0;
   if (tag_files._length() > 0) {
      tag_list_context_globals(0,0,tag_name,false,tag_files,
                               SE_TAG_FILTER_MISCELLANEOUS,
                               SE_TAG_CONTEXT_ANYTHING,
                               tag_count,def_tag_max_function_help_protos,
                               true,false,visited,depth+1);
      // trick it into finding tag with 'xsd' prefix to get tagdoc
      if (tag_count==0 && _LanguageInheritsFrom("xsd")) {
         prefix := "";
         if (pos(":",tag_name)) {
            parse tag_name with prefix ":" . ;
         }
         if (prefix!="xsd") {
            tag_name=_xml_retargetNamespace(tag_name,prefix,"xsd");
            tag_list_context_globals(0,0,tag_name,false,tag_files,
                                     SE_TAG_FILTER_MISCELLANEOUS,
                                     SE_TAG_CONTEXT_ANYTHING,
                                     tag_count,def_tag_max_function_help_protos,
                                     true,false,visited,depth+1);
         }
      }
   }
   if (tag_count==0) {
      _HtmlListKeywords("mlckeywords","",
                        tag_name,false,"",0,
                        tag_count, def_tag_max_list_members_symbols,
                        true, false);
   }
#if 0
   // The current algorithm for handling XML namspaces makes this a bit ugly to do.
   // We need to rethink how we want to do this.  One possibility is constructing temp
   // tag files that we delete when the editor terminates.  This would require retagging
   // a .dtd, .tagdoc, or .xsd file using a specific namespace prefix for each tag
   // (not sure how hard this is).
   if (p_LangId=='xml') {
      _xml_get_current_namespaces(auto NamespacesHashtab, depth+1);

      //say("tag_count="tag_count);
      /*_xml_insert_namespace_context_globals(
         NamespacesHashtab,
         0,-1,0,
         tag_name, //lastid,
         tag_name, //lastid_prefix,
         true,"",tag_count);
      */
#if 1
      _xml_insert_namespace_context_tags(
         NamespacesHashtab,
         0,-1,0,
         tag_name, //lastid,
         tag_name, //lastid_prefix,
         true,"",tag_count,
         def_tag_max_list_members_symbols,0,true,true);
#endif
      //say("after tag_count="tag_count);
   }
#endif

   // put the tags into the function help list
   int i,n=tag_get_num_of_matches();
   if (n==0) {
      return(VSCODEHELPRC_NO_HELP_FOR_FUNCTION);
   }
   k := 0;
   for (i=1; i<=n; ++i) {
      // set up the function help info list
      tag_get_match_browse_info(i, auto cm);
      tag_name = cm.member_name;
      tag_autocode_arg_info_from_browse_info(FunctionHelp_list[k], cm, prototype:"");
      FunctionHelp_list[k].arglength[0]=length(cm.member_name);
      FunctionHelp_list[k].argstart[0]=2;
      FunctionHelp_list[k].ParamName=attr_name;

      // get the attributes and add them to the prototype
      tag_push_matches();
      prototype := "<"tag_name;
      attr_count := 0;
      if (tag_files._length() > 0) {
         tag_list_in_class("", tag_name, 0, 0, tag_files,
                           attr_count, def_tag_max_list_members_symbols,
                           SE_TAG_FILTER_MEMBER_VARIABLE,SE_TAG_CONTEXT_ONLY_INCLASS,
                           false, false, null, null, visited, depth+1);
      }
      if (attr_count==0) {
         _HtmlListKeywords("keywordattrs",
                           upcase(tag_name),"",true,"",0,
                           attr_count,def_tag_max_list_members_symbols,
                           true,false);
      }
      int j,m=tag_get_num_of_matches();
      for (j=1; j<=m; ++j) {
         tag_get_match_browse_info(j, cm);
         tag_name = cm.member_name;
         FunctionHelp_list[k].arglength[j]=length(tag_name)+length(cm.return_type)+1;
         FunctionHelp_list[k].argstart[j]=length(prototype)+2;
         prototype :+= " "cm.member_name"="cm.return_type;
         if (attr_name=="" && prev_ParamNum!=0) {
            FunctionHelp_list_changed=true;
         } else if (attr_name!="" && strieq(cm.member_name,attr_name)) {
            FunctionHelp_list[k].ParamNum=j;
            FunctionHelp_list[k].ParamType=cm.return_type;
            if (prev_ParamNum!=j) {
               FunctionHelp_list_changed=true;
            }
            prev_info.prefixexp  = idexp_info.prefixexp;
            prev_info.otherinfo  = idexp_info.otherinfo;
            prev_info.info_flags = idexp_info.info_flags;
            prev_info.lastidstart_col  = idexp_info.lastidstart_col;
            prev_ParamNum   = j;
         }
      }
      tag_pop_matches();

      // next please
      prototype :+= ">";
      FunctionHelp_list[k].prototype=prototype;
      ++k;
   }

   // has anything changed?
   if (tag_name!=prev_FunctionName || prev_FunctionOffset!=idexp_info.prefixexpstart_offset) {
      FunctionHelp_list_changed=true;
      prev_FunctionName=tag_name;
      prev_info.prefixexpstart_offset=idexp_info.prefixexpstart_offset;
   }

   // find a matching tag in the database or color coding
   return(0);
}

/**
 * @see _html_fcthelp_get
 */
int _xml_fcthelp_get(_str (&errorArgs)[],
                     VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                     bool &FunctionHelp_list_changed,
                     int &FunctionHelp_cursor_x,
                     _str &FunctionHelp_HelpWord,
                     int FunctionNameStartOffset,
                     int flags,
                     VS_TAG_BROWSE_INFO symbol_info=null,
                     VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return(
      _html_fcthelp_get(
         errorArgs,
         FunctionHelp_list,
         FunctionHelp_list_changed,
         FunctionHelp_cursor_x,
         FunctionHelp_HelpWord,
         FunctionNameStartOffset,
         flags, symbol_info,
         visited, depth));
}

void _mapjsp_init_file(int editorctl_wid, bool doUpdate=false)
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   editorctl_wid._UpdateContext(true);

   // Find all the jsp taglib definitions in this file
   // and stick them in a hash table where the key is the prefix and the value is the uri.
   // prefixes should be unique in this file so key off of them. The uri's should be different but could be the same.
   // Each uri corresponds to a tld file that should be parsed and have their contents stored in a temporary
   // tagfile under a namespace/package whose name is the prefix associated with the uri.
   // Example taglib:
   // <%@ taglib uri="C:\public\JSP-Stuff\cwp-taglib.tld" prefix="foo2" %>
   //
   // TODO: As a first pass the uri have to be the exact file location. Real uri's are unique identifiers stored
   // in a web.xml file. The identifiers in the web.xml then reference an actual file location. Instead of
   // trying to find and parse the web.xml file the plan is to ask the user for the location of the file associated
   // with this uri and store this file in the config along with the associated uri and prefix for each taglib directive.
   // This config will be mapped to a particular jsp/html file and will also store the name and location of the tag database
   // that will contain all of the symbols generated by parsing each tld file and prepending the symbols in that file with the 
   // prefix.

   save_pos(auto p2);
   top();

   // Get the information on all the taglibs in this jsp file. taglib_info witll
   // contain an @ delimited string starting with a length followed by a uri and @ and then
   // a prefix for each taglib directive in the jsp.
   taglib_info := "";
   index := _FindLanguageCallbackIndex("vs%s-get-taglib-infos",p_LangId);
   if(index) {
      status := call_index(p_window_id, "", taglib_info, index); 
   }

   restore_pos(p2);

   // Parse all of the taglibs and then parse all the tlds associated with the
   // taglibs building a tag database filled with the tld info's prepended with
   // the prefix associated with each taglib.
   if (taglib_info != "") {
      _mapjsp_create_tagfile(editorctl_wid, doUpdate, taglib_info);
      _jsp_addTagsToColorCoding(editorctl_wid);
   }
}

static bool local_file_exists(_str path) {
   return file_exists(path) && pos(":", path) == 0;
}

static int _mapjsp_create_tagfile(int editorctl_wid, bool ForceUpdate, _str taglib_info)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   int i, temp_view_id, orig_view_id=p_window_id, status=0;

   // Get tagfile and list of uris with their associated filenames from the config file.
   _str tagfile=editorctl_wid._jsp_GetConfigTagFile();

   typeless num_prefixes="";
   parse taglib_info with num_prefixes "@" taglib_info;

   // Ask about any uri's that we don't have valid files for.
   // Don't intermix with opening tempviews or else goofy stuff happens.
   // Needs to remain two separate loops.
   _str file_name,file_names[];
   _str temp_taglib_info = taglib_info;
   _str PrefixHashtab:[]=null;
   _str UriHashtab:[]=null;

   // Get our saved mapping of prefixes to filenames if it exists.
   int prefixHashTableExists = editorctl_wid._jsp_GetConfigPrefixToUriHash(PrefixHashtab);
   int uriHashTableExists = editorctl_wid._jsp_GetConfigUriToFileHash(UriHashtab);

   typeless result=0;
   for(i=0; i < (int)num_prefixes; i++)  {
      _str prefix, uri;
   
      parse temp_taglib_info with uri "@" prefix "@" temp_taglib_info;
 
      if(uriHashTableExists && !UriHashtab:[uri]._isempty()) {
         file_name=UriHashtab:[uri];
      } else {
         file_name=uri;
      }

      if(!local_file_exists(file_name)) {
         if (ForceUpdate) {
            result=_OpenDialog("-modal",
                               "Locate TLD file associated with the uri '" :+ uri :+ "'",                   // Dialog Box Title
                               "",                   // Initial Wild Cards
                               "XML/JSP TagLib Files (*.tld;*.xml)",       // File Type List
                               OFN_FILEMUSTEXIST     // Flags
                               );
            if (result=="") {
               return 0;
            }
            file_name=result;         
         } else {
            // Don't save a URL, we don't want to pull from the network in this case.
            continue;
         }
      }

      file_names[file_names._length()] = file_name;
      PrefixHashtab:[prefix] = uri;
      UriHashtab:[uri] = file_name;
   }

   if (tagfile=="") {
      tagfile=mktemp(1,TAG_FILE_EXT);
   }

   editorctl_wid._clex_jspSetConfig(ForceUpdate, _jsp_MakeConfig(tagfile, PrefixHashtab, UriHashtab));

   tag_close_db(tagfile);
   status=tag_create_db(tagfile);
   if (status < 0) {
      return(status);
   }

   // Go through all tld files imported into this jsp file and add
   // their tags to the temporary tag file associated with JSP.
   index := _FindLanguageCallbackIndex("vs%s-list-tags-with-prefix","tld");
   if(index) {
      for(i=0; i < (int)num_prefixes; i++) {
         _str prefix, uri;
   
         parse taglib_info with uri "@" prefix "@" taglib_info;

         // Was it skipped because it wasn't a local file or uri mapping?
         if (file_names[i]._length() == 0) {
            continue;
         }

         // Check to see if this uri is already in the config and has an associated filename
         // If not then see if the uri exists and if it does not then prompt for the location.
   
         // Go through TLD files opening up a temporary buffer and listing tags
         // for the TLD. They should go into a temporary JSP tag file.
         status=_open_temp_view(file_names[i], temp_view_id, orig_view_id);
   
         if(!status) {
            tag_lock_context(); 
            status=tag_insert_file_start(file_names[i]);
            tag_clear_embedded();
            tag_set_date(p_buf_name,"1111":+substr(p_file_date,5),0,null,p_LangId);

            // Insert tags with the taglib prefix
            status = call_index(temp_view_id, file_names[i], prefix, index);  

            // Empty prefix will insert tags with the shortname of the taglib defined in the tld
            status = call_index(temp_view_id, file_names[i], "", index); 

            status=tag_insert_file_end();

            _delete_temp_view(temp_view_id);
            tag_unlock_context(); 
         }
   
         p_window_id=orig_view_id;
      }
   }

   tag_close_db(null,true);
   activate_window(orig_view_id);

   return 0;   
}

static void _jsp_addTagsToColorCoding(int editorctl_wid, int cfg_color=CFG_TAG)
{
   if (!_haveContextTagging()) {
      return;
   }

   // Open and check if we failed to read tag database
   status := tag_read_db(editorctl_wid._jsp_GetConfigTagFile());
   if (status < 0) return;

   // Can't nest find_global and find_in_class since they step all over each other
   // so make a temp array of all the keywords and then get the attributes later.
   _str keywords[]=null;
   status=tag_find_global(SE_TAG_TYPE_TAG,0,0);
   for (;!status;) {
      tag_get_tag_browse_info(auto cm);
      if (!(cm.flags& SE_TAG_FLAG_FINAL)) {
         keywords :+= cm.member_name;
      }
      status=tag_next_global(SE_TAG_TYPE_TAG,0,0);
   }
   tag_reset_find_in_class();

   // Gather the attributes for each keyword into a space delimited list to
   // insert into the lexer for jsp(html)
   for(i:=0; i < keywords._length(); i++) {

      // Create attribute list
      attributes := "";
      status=tag_find_in_class(keywords[i]);
      for (;!status;) {
         tag_get_detail(VS_TAGDETAIL_name, auto attribute_name);
         attributes :+= attribute_name :+ " ";
         status=tag_next_in_class();
      }
      tag_reset_find_in_class();

      editorctl_wid._clex_jspAddKeywordAttrs(keywords[i], attributes, cfg_color);
   }

   tag_close_db(editorctl_wid._jsp_GetConfigTagFile());
}

static void html_add_tld_globals(int editorctl_wid, int window_id, int tree_index)
{
   _str tagfile=editorctl_wid._jsp_GetConfigTagFile();

   _str tld_file_list[]=null;
   tld_file_list[0]=tagfile;

   if(tagfile!= "") {
      window_id.tag_push_matches();
      tag_clear_matches();
      num_matches := 0;
      tag_list_context_globals(window_id,tree_index, "", false, tld_file_list, 
                               SE_TAG_FILTER_MISCELLANEOUS,SE_TAG_CONTEXT_ANYTHING,
                               num_matches, def_tag_max_list_members_symbols, 
                               false, false);
      window_id.tag_pop_matches();
   }
}

// These are essentially the same as the xml versions but the hash table
// maps prefixes to tld files.
static _str _jsp_MakeConfig(_str tagfile,_str (&PrefixHashtab):[], _str (&UriHashtab):[])
{
   string1 := "";
   typeless i;
   typeless value="";
   for (i=null;;) {
      value=PrefixHashtab._nextel(i);
      if (i==null) {
         break;
      }
      if (string1=="") {
         string1=i"="value;
      } else {
         string1 :+= ";"i"="value;
      }
   }

   string2 := "";
   for (i=null;;) {
      value=UriHashtab._nextel(i);
      if (i==null) {
         break;
      }
      if (string2=="") {
         string2=i"="value;
      } else {
         string2 :+= ";"i"="value;
      }
   }
   //say("s="string);
   return(tagfile"|"string1"|"string2);
}
_str _jsp_GetConfigTagFile()
{
   _str tagfile,string1,string2;
   parse _clex_jspGetConfig() with tagfile"|"string1"|"string2;
   return(tagfile);
}

int _jsp_GetConfigPrefixToUriHash(_str (&PrefixHashtable):[])
{
   _str prefix, file_name, string, tagfile, string1, string2;

   parse _clex_jspGetConfig() with tagfile"|"string1"|"string2;

   if(string1=="") return 0; // Config is empty no hash table created.

   while(string1 != "") {
      parse string1 with prefix "=" file_name ";" string1;
      PrefixHashtable:[prefix]=file_name;
   }
   return 1; // Hash table info found and hash table created.
}

int _jsp_GetConfigUriToFileHash(_str (&UriHashtable):[])
{
   _str uri, file_name, string, tagfile, string1, string2;

   parse _clex_jspGetConfig() with tagfile"|"string1"|"string2;

   if(string2=="") return 0; // Config is empty no hash table created.

   while(string2 != "") {
      parse string2 with uri "=" file_name ";" string2;
      UriHashtable:[uri]=file_name;
   }
   return 1; // Hash table info found and hash table created.
}

static void _html_insert_namespace_context_tags(_str lastid, _str lastid_prefix,
                                                bool is_attrib,
                                                _str clip_prefix, 
                                                int start_or_end,
                                                int &num_matches, int max_matches,
                                                bool exact_match=false,
                                                bool case_sensitive=false,
                                                bool insertTagDatabaseNames=false,
                                                int depth=0,
                                                bool (&tagsAllowedInContextModel):[]=null)
{
   _str only_prefix=null;
   i := pos(":",lastid_prefix);
   if (i) {
      only_prefix=substr(lastid_prefix,1,i-1);
   }

   _str PrefixHashTable:[]=null;
   _jsp_GetConfigPrefixToUriHash(PrefixHashTable);

   typeless prefix;
   for (prefix._makeempty();;) {
       PrefixHashTable._nextel(prefix);
       if (prefix._isempty()) break;
       if (only_prefix!=null && prefix!=only_prefix) {
          continue;
       }

       tag_filename := _jsp_GetConfigTagFile();
       tag_read_db(tag_filename);

       status := tag_find_global(SE_TAG_TYPE_TAG,0,0);
       for (;!status;) {
          tag_get_tag_browse_info(auto cm);
          tag_name := cm.member_name;
          //tag_get_detail(VS_TAGDETAIL_arguments,
          i=pos(":",tag_name);
          if (i) {
             tag_name=substr(tag_name,i+1);
          }

          if (prefix!="") {
             tag_name=prefix:+":":+tag_name;
          }

          if (exact_match && tag_name!=lastid_prefix) {
             status=tag_next_global(SE_TAG_TYPE_TAG,0,0);
             continue;
          }
          temp_prefix := lastid_prefix;
          if (insertTagDatabaseNames) {
             tag_name = cm.member_name;
             temp_prefix=tag_name;
          }

          tag_init_tag_browse_info(auto args);
          args.file_name=cm.file_name;
          args.line_no=cm.line_no;
          args.class_name=cm.class_name;
          args.flags=cm.flags;

          if (start_or_end==0) {

             // only allowing tags from the parent tags content model?
             if (tagsAllowedInContextModel._length() > 0) {
                if (!tagsAllowedInContextModel._indexin(upcase(cm.member_name)) && !tagsAllowedInContextModel._indexin(upcase(tag_name))) {
                   if (_chdebug) {
                      isay(depth, "_html_insert_namespace_context_tags: NOT ALLOWED IN CONTEXT, tag_name="tag_name"=");
                   }
                   status=tag_next_global(SE_TAG_TYPE_TAG,0,0);
                   continue;
                }
             }

             _html_insert_context_tag_item(tag_name,
                                           exact_match? lastid:lastid_prefix,
                                           false, "", start_or_end,
                                           num_matches, max_matches,
                                           exact_match, case_sensitive,
                                           tag_filename,cm.type_name,&args);

          } else if (!(cm.flags & SE_TAG_FLAG_FINAL)) {
             _html_insert_context_tag_item(/*"/"*/tag_name,
                                                  exact_match? lastid:lastid_prefix,
                                                  false,"", 0,
                                                  num_matches, max_matches,
                                                  exact_match, case_sensitive,
                                                  tag_filename,cm.type_name,&args);
          }
          if (exact_match) {
             break;
          }
          status=tag_next_global(SE_TAG_TYPE_TAG,0,0);
       }
   }
   tag_reset_find_in_class();
}

///////////////////////////////////////////////////////////////////////////////
/**
 * Strip any html HREF tags out of the given string.
 * This is used for displaying the message properly
 * in certain HTML controls where following a link is
 * not supported.
 * 
 * @param msg     Message to process
 * 
 * @return <code>msg</code> with href tags stripped out
 */
_str strip_html_hrefs(_str msg)
{
   int i;
   for (i=1;;) {
      i=pos("<a href=",msg,i,'i');
      if (!i) {
         break;
      }
      j := pos(">",msg,i);
      if (j) {
         msg=substr(msg,1,i-1):+substr(msg,j+1);
         j=pos("</a>",msg,i);
         if (j) {
            msg=substr(msg,1,j-1):+substr(msg,j+4);
         }
      }
   }
   return msg;
}

///////////////////////////////////////////////////////////////////////////////

/**
 * Callback for determining if the current line is the first line
 * of a block tag.
 * <p> 
 * Note that this function is also called for HTML, CFML,
 * XHTML, XSD, TLD, and all other languages that inherit from XML.
 * </p>
 * 
 * @param first_line
 * @param last_line
 * @param num_first_lines
 * @param num_last_lines
 * 
 * @return bool
 */
bool _xml_find_surround_lines(int &first_line, int &last_line, 
                                 int &num_first_lines, int &num_last_lines, 
                                 bool &indent_change, 
                                 bool ignoreContinuedStatements=false) 
{
   indent_change = true;

   // keep track of the first line, check that it starts with "<"
   first_line = p_RLine;
   _first_non_blank();
   if (get_text_safe() != "<") {
      return false;
   }

   // check that we have a tag name next
   right();
   color := _clex_find(0, "g");
   if (color != CFG_KEYWORD && color != CFG_TAG && color != CFG_UNKNOWN_TAG && color != CFG_XHTMLELEMENTINXSL) {
      return false;
   }

   // find the end of the same tag name
   status := search(">", "@hXcs");
   if (status) {
      return false;
   }

   // check that we are at the end of the line, not counting comments
   orig_line := p_RLine;
   save_pos(auto p);
   p_col++;
   _clex_skip_blanks("h");
   if (p_RLine==orig_line && !at_end_of_line()) { 
      return false;
   }

   // this is the start of the surrounded text
   restore_pos(p);
   num_first_lines = p_RLine - first_line + 1;

   // find the matching tag
   status = find_matching_paren(true);
   if (status) {
      return false;
   }

   // make sure the end tag is the first thing on the line
   orig_col := p_col;
   _first_non_blank();
   if (p_col < orig_col) {
      return false;
   }

   // look for end of the end tag
   status = search(">", "@hXcs");
   if (status) {
      return false;
   }

   // this is the end of the surround block (the end tag)
   num_last_lines=1;
   last_line = p_RLine;

   // check for short end tag
   if (p_col > 1) {
      p_col--;
      if (get_text(2)=="/>") num_last_lines=0;
      p_col++;
   }

   // make sure that it is at the end of the line
   p_col++;
   _clex_skip_blanks("h");
   if (p_RLine==last_line && !at_end_of_line()) {
      return false;
   }

   // success
   return true;
}
bool _html_find_surround_lines(int &first_line, int &last_line, 
                                  int &num_first_lines, int &num_last_lines, 
                                  bool &indent_change, 
                                  bool ignoreContinuedStatements=false) 
{
   return _xml_find_surround_lines(first_line, last_line, num_first_lines, num_last_lines, indent_change, ignoreContinuedStatements);
}

_str hformat_default_embedded()
{
   if (_html_tags_loaded()) {
      return _beautifier_get_property(gtagcache_info,"default_embedded_lang");
   }

   return "phpscript";
}


bool markup_is_inline_tag(_str langId, _str tagName, _str buf_name)
{
   if (_html_tags_loaded(langId,buf_name)) {
      a := _get_attr_val(langId, tagName, "lb_within");
      return a == "0";
   }
   return false;
}

int markup_standalone(_str tagName)
{
   langId := p_LangId;
   if (_html_tags_loaded(langId,p_buf_name)) {
      return _get_attr_val(langId, tagName, "standalone");
   }
   return 0;
}

int markup_num_lines_before(_str tagName)
{
   langId := p_LangId;
   if (_html_tags_loaded(langId,p_buf_name)) {
      av := _get_attr_val(langId, tagName, VSCFGP_BEAUTIFIER_BL_BEFORE_START_TAG);

      if (isinteger(av)) {
         return (int)av;
      } else {
         return 0;
      }
   }
   return 0;
}

int markup_num_lines_after(_str tagName)
{
   langId := p_LangId;
   if (_html_tags_loaded(langId,p_buf_name)) {
      av := _get_attr_val(langId, tagName, VSCFGP_BEAUTIFIER_BL_AFTER_END_TAG);

      if (isinteger(av)) {
         return (int)av;
      } else {
         return 0;
      }
   }
   return 0;
}

bool markup_endtag(_str tagName)
{
   langId := p_LangId;
   if (_html_tags_loaded(langId,p_buf_name)) {
      return _get_attr_val(langId, tagName, VSCFGP_BEAUTIFIER_END_TAG) != "0";
   }

   return true;
}

bool markup_indent_content(_str tagName)
{
   langId := p_LangId;
   if (_html_tags_loaded(langId,p_buf_name)) {
      return _get_attr_val(langId, tagName, "indent_content") != "0";
   }

   return true;
}

bool markup_end_tag_required(_str langId, _str tagName,_str buf_name)
{
   if (_html_tags_loaded(langId,buf_name)) {
      endtag := _get_attr_val(langId, tagName, VSCFGP_BEAUTIFIER_END_TAG);
      endtag_required := _get_attr_val(langId, tagName, VSCFGP_BEAUTIFIER_END_TAG_REQUIRED);

      return endtag != "0" && endtag_required != "0";
   }

   return true;
}

// Returns line wrap length, or -1 if it is not enabled.
int markup_line_wrapping_length(_str langId,_str buf_name)
{
   if (_html_tags_loaded(langId,buf_name)) {
      maximum_line_length:=_beautifier_get_property(gtagcache_info,VSCFGP_BEAUTIFIER_MAX_LINE_LEN);
      if (isinteger(maximum_line_length)) {
         return max(maximum_line_length,6);
      }
   }

   return -1;
}

int markup_syntax_indent()
{
   langId := p_LangId;
   if(_html_tags_loaded(langId,p_buf_name)) {
      indent:=_beautifier_get_property(gtagcache_info,VSCFGP_BEAUTIFIER_SYNTAX_INDENT);
      if (isinteger(indent)) {
         return (int)indent;
      }
   }
   return 4;
}

_str markup_get_tab_setting()
{
   langId := p_LangId;
   if (_html_tags_loaded(langId,p_buf_name)) {
      value:=_beautifier_get_property(gtagcache_info,VSCFGP_BEAUTIFIER_TAB_SIZE);
      if (isinteger(value)) {
         return "+"value;
      }
   }

   return "+4";
}

/**
 * Convert a SlickEdit color (CFG_*) to a string appropriate for using 
 * in an HTML &lt;font color="#rrggbb"&gt; tag, or HTML style tag. 
 * 
 * @param cfg             Color coding constant
 * @param get_bg_color    If 'true', get the background color, otherwise get foreground setting.
 * 
 * @return Returns a string of the form #RRGGBB, padded with leading zeroes if necessary.
 */
_str cfg_color_to_html_color(int cfg, bool get_bg_color=false)
{
   color_info := _default_color(cfg);
   parse color_info with auto fg auto bg .;
   rgb := (int)(get_bg_color? bg : fg);
   b := (rgb & 0xFF); rgb = rgb intdiv 256;
   g := (rgb & 0xFF); rgb = rgb intdiv 256;
   r := (rgb & 0xFF); 
   rgb = _rgb(r,g,b);
   html_color := _dec2hex(rgb,16,6);
   return "#":+html_color;
}

