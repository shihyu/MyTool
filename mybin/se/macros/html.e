////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50363 $
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
#require "se/lang/api/LanguageSettings.e"
#import "se/tags/TaggingGuard.e"
#import "adaptiveformatting.e"
#import "alllanguages.e"
#import "autocomplete.e"
#import "c.e"
#import "ccode.e"
#import "cformat.e"
#import "codehelp.e"
#import "codehelputil.e"
#import "commentformat.e"
#import "compile.e"
#import "context.e"
#import "csymbols.e"
#import "cutil.e"
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
#endregion

using se.lang.api.LanguageSettings;

boolean def_mozilla_modified=false; // Indicates whether the mozilla configuration has been updated.
#define VSLICKHELP_WEB_BROWSER 'VSLICKHELP_WEB_BROWSER'
#define SLICKEDIT_HOME  'http://www.slickedit.com'
#define SLICKEDIT_SUPPORT  (SLICKEDIT_HOME:+'/support/su_support.php')
#define SLICKEDIT_FAQ  (SLICKEDIT_HOME:+'/support/faq')

//---------------------------------------------------------------------
// Code for Unix ...
#define AUTOSTART_TIMEOUT 20

#define BIAUTO 0
//#define BINNAVIGATOR 1
//#define BINNAVIGATOR4 BINNAVIGATOR
#define BIIEXPLORER 2
//#define BIWEBEXPLORER 3
//#define BIMOSAIC 4
#define BIOTHER 5
//#define BINNAVIGATOR6 6
#define BIMOZILLA 7
#define BISAFARI 8
#define BIFIREFOX 9
#define BICHROME 10

#define OSIWIN 0
//#define OSIOS2 1
#define OSIRESERVED 2
#define OSIUNIX OSIWIN

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
static int info_modified = 0;
static int osi = OSIWIN;
static int unixRunning = 0;

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
   '<project>'                             => { "<project name="" default=""> ..." },
   '<target>'                              => { "<target name=""> ..." },
   '<target> with dependencies'            => { "<target name="" depends=""> ..." },
   '<property> with name, value'           => { "<propery name="" value=""/>" },
   '<property> with name, location'        => { "<propery name="" location=""/>" },
   '<property> with file'                  => { "<propery file=""/>" },
   '<import>'                              => { "<import file=""/>" },
   '<echo>'                                => { "<echo message=""/>" },
   '<delete> fileset'                      => { "<delete> <fileset ..." },
   '<delete> referenced fileset'           => { "<delete> <fileset refid= ..." },
   '<antcall>'                             => { "<antcall target=""/>" },
   '<antcall> with params'                 => { "<antcall target=""> <params ..." },
   '<fileset>'                             => { "<fileset dir="" ..." },
   '<macrodef>'                            => { "<macrodef name="" ..." },
   '<exec>'                                => { "<exec executable=""> ..." },
   '<mkdir>'                               => { "<mkdir dir=""> ..." },
   '<jar> with params inside opening tag'  => { "<jar destfile=""/>" },
   '<jar>'                                 => { "<jar destfile=""> ..." },
};

static void adjust_filespec(_str &vslickpathfilename)
{
#if !__UNIX__
   _str comspec=get_env("COMSPEC")" /c";
   if (file_eq(substr(vslickpathfilename,1,length(comspec)),comspec)) {
      vslickpathfilename=strip(substr(vslickpathfilename,length(comspec)+1));
       if (file_match("-p "vslickpathfilename".bat",1)!="") {
          vslickpathfilename=vslickpathfilename".bat";
          return;
       }
      if (file_match("-p "vslickpathfilename".cmd",1)!="") {
         vslickpathfilename=vslickpathfilename".cmd";
         return;
      }
   }
#endif
}
static _str whichpath( _str filename )
{
   if (filename=="") {
      return( "" );
   }
   // We want this one to act like user typed command on command line
   // except we don't look for internal editor commands.
   _str vslickpathfilename=slick_path_search(filename,"M");
   // We want this one to act like user is at shell prompt.
   _str pathfilename=path_search(filename,"","P");
   adjust_filespec(vslickpathfilename);
   adjust_filespec(pathfilename);
   //sticky_message("VSLICKPATH found <"vslickpathfilename">   PATH found <"pathfilename">");
   return( pathfilename );
}
static void _init_osi()
{
   if (!def_mozilla_modified) {
      def_mozilla_modified=true;
      _config_modify_flags(CFGMODIFY_DEFVAR);
      // Force defaults to be used.
      def_html_info.exePath[BIMOZILLA]='';
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
   int view_id=0;
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
   _str execmd='';
   typeless useDDE=false;
   typeless app="";
   typeless topic="";
   typeless item="";
   boolean usingDefaultBrowser;
   if ( buildRequest( filename, execmd, useDDE, app, topic, item, overrideDDE,usingDefaultBrowser ) ) {
      return( 1 );
   }

   typeless status=0;
   _str line="";
   _str msg="";
   int timeout=0;
   typeless start_ss="";
   typeless ss="";
   _str alternate_shell="";
   typeless ec=0;

   if ( useDDE ) {
#if __PCDOS__
      _str default_execmd;
      typeless default_useDDE;
      _str default_app,default_topic,default_item;

      getDefaultBrowserInfo( BIAUTO, default_execmd, default_useDDE, default_app, default_topic, default_item );

      _str default_browser=parse_file(default_execmd,false);
      default_browser=_strip_filename(default_browser,'pe');
      _str browser=parse_file(execmd,false);
      browser=_strip_filename(browser,'pe');
      /*
         In order to support long url's, we use shell execute.
         DDE is limited to 255 characters.  We can use
         NTShellExecuteEx for the default browser.
      */
      if (usingDefaultBrowser || file_eq(default_browser,browser)) {
         _str exe=_UTF8ToMultiByte(filename);
         _str params= "";
         int exitCode;
         int shell_status = NTShellExecuteEx("",exe,params,"",exitCode);
         status = ( shell_status != 0 ) ? shell_status : exitCode;
         return(status);
      }
#endif
      
      //messageNwait( "PREVENT CRASH...  app="app" item="item" topic="topic );

      // Try to activate the browser and get the frame/window ID:
      _str browserID;
      int view_id = 0;
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
            if (ss<start_ss) ss=ss+60;
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
         execmd = execmd" > /dev/null 2>&1";
         alternate_shell=path_search('sh');
         if (alternate_shell=='') alternate_shell='/bin/sh';
         ec = shell( execmd, "A",alternate_shell);
         //_message_box('ec='ec' h0 'execmd);
         if ( ec ) {
            // Failed starting browser with default command.
            // Try another format 'browerExe %F'.
            buildRequest( "", execmd, useDDE, app, topic, item );
            //_message_box('h1 'execmd);
            execmd = execmd" "filename;
            //_message_box('h2 'execmd);
            ec = shell( execmd, "A" );
         }
      } else {
         ec = shell( execmd, 'AN' );
      }
      if ( ec ) {
         msg = "Can't view file with \n'"execmd"'.\n\n"getHowToReconfigureBrowserMsg();
         _message_box( msg );
         return( 1 );
      }
   }
   return( 0 );
}


defeventtab _html_form;

#region Options Dialog Helper Functions

void _html_form_init_for_options()
{
   _ok.p_visible = false;
   _cancel.p_visible = false;
   _help.p_visible = false;
   _default.p_y = _ok.p_y;
}

void _html_form_save_settings(_str settings:[])
{
   info_modified = 0;
}

boolean _html_form_is_modified(_str settings:[])
{
   return (info_modified != 0);
}

void _html_form_apply()
{
   if ( info_modified ) {
      //messageNwait( "Form info modified." );
      def_html_info = info_copy;
      def_html_other_info = info_othercopy;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
}

#endregion Options Dialog Helper Functions

_useDDE_tb.lbutton_up()
{
   boolean s=false;
   if ( p_value == 1 ) {
      s = true;
   }
   toggleUseDDE( s );
   int bi = info_copy.browser[osi];
   if ( bi == BIOTHER ) {
      info_othercopy.useDDE[osi] = _useDDE_tb.p_value;
   } else {
      info_copy.useDDE[bi] = p_value;
   }
   info_modified = 1;
}
_browse1.lbutton_up()
{
   int wid=p_window_id;
   typeless result=_OpenDialog('-modal',
                      '',                   // Dialog Box Title
                      '',                   // Initial Wild Cards
                      def_file_types,       // File Type List
                      OFN_FILEMUSTEXIST     // Flags
                      );
   if (result=='') {
      return('');
   }
   p_window_id=wid.p_prev;
   p_text=result;
   end_line();
   _set_focus();
   return('');
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
_default.lbutton_up()
{
   int bi;
   if ( _auto_rb.p_value ) {
      bi = BIAUTO;
   } else if ( _chrome.p_value ) {
      bi = BICHROME;
   } else if ( _mozilla_rb.p_value ) {
      bi = BIMOZILLA;
   } else if ( _ie_rb.p_value ) {
      bi = BIIEXPLORER;
   } else if ( _sf_rb.p_value ) {
      bi = BISAFARI;
   } else if ( _firefox_rb.p_value ) {
      bi = BIFIREFOX;
   }

   fillBrowser(bi, 1);
}
_auto_rb.lbutton_up()
{
   setBrowser( BIAUTO );
   fillBrowser(BIAUTO, 0);
   setState( 0, 0, 0, 0 );
}
_chrome.lbutton_up()
{
   int bi = BICHROME;
   setBrowser( bi );
   setState( 1, info_copy.useDDE[bi], 1, 1 );
   fillBrowser(bi, 0);
}
_mozilla_rb.lbutton_up()
{
   int bi = BIMOZILLA;
   setBrowser( bi );
   setState( 1, info_copy.useDDE[bi], 1, 1 );
   fillBrowser(bi, 0);
}
_firefox_rb.lbutton_up()
{
   int bi = BIFIREFOX;
   setBrowser( bi );
   setState( 1, info_copy.useDDE[bi], 1, 1 );
   fillBrowser(bi, 0);
}
_ie_rb.lbutton_up()
{
   int bi = BIIEXPLORER;
   setBrowser( bi );
   setState( 1, info_copy.useDDE[bi], 1, 1 );
   fillBrowser(bi, 0);
}
_sf_rb.lbutton_up()
{
   int bi = BISAFARI;
   setBrowser( bi );
   setState( 1, info_copy.useDDE[bi], 1, 1 );
   fillBrowser(bi, 0);
}
_other_rb.lbutton_up()
{
   setBrowser( BIOTHER );
   if ( unixRunning ) {
      setState( 1, 0, 0, 0 );
   } else {
      setState( 1, info_othercopy.useDDE[osi], 1, 0 );
   }
   fillBrowser(BIOTHER, 0);
}
_ok.on_create()
{
   _html_form_initial_alignment();

   _init_osi();
   // Update the controls:
   info_modified = 0;
   info_copy = def_html_info;
   info_othercopy = def_html_other_info;
   fillWithHTMLInfo();

   // Disable OS specific controls:
   if ( unixRunning ) {
      _ie_rb.p_enabled = _isMac();
      _sf_rb.p_enabled = _isMac();
   } else {
      _sf_rb.p_enabled = false;
   }
}
_ok.lbutton_up()
{
   _html_form_apply();
   p_active_form._delete_window( 1 );
}
_cancel.lbutton_up()
{
   p_active_form._delete_window( 0 );
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _html_form_initial_alignment()
{
   sizeBrowseButtonToTextBox(_program_tx, _browse1, 0, _default.p_x + _default.p_width);
}

static void setBrowser( int b )
{
   if ( b == BIAUTO ) {
      _chrome.p_value = 0;
      _mozilla_rb.p_value = 0;
      _ie_rb.p_value = 0;
      _sf_rb.p_value = 0;
      _other_rb.p_value = 0;
      _firefox_rb.p_value = 0;
   } else if ( b == BICHROME ) {
      _auto_rb.p_value = 0;
      _mozilla_rb.p_value = 0;
      _ie_rb.p_value = 0;
      _sf_rb.p_value = 0;
      _other_rb.p_value = 0;
      _firefox_rb.p_value = 0;
   } else if ( b == BIMOZILLA ) {
      _auto_rb.p_value = 0;
      _chrome.p_value = 0;
      _ie_rb.p_value = 0;
      _sf_rb.p_value = 0;
      _other_rb.p_value = 0;
      _firefox_rb.p_value = 0;
   } else if ( b == BIFIREFOX ) {
      _auto_rb.p_value = 0;
      _chrome.p_value = 0;
      _ie_rb.p_value = 0;
      _sf_rb.p_value = 0;
      _other_rb.p_value = 0;
      _mozilla_rb.p_value = 0;
   } else if ( b == BIIEXPLORER ) {
      _auto_rb.p_value = 0;
      _chrome.p_value = 0;
      _mozilla_rb.p_value = 0;
      _sf_rb.p_value = 0;
      _other_rb.p_value = 0;
      _firefox_rb.p_value = 0;
   } else if ( b == BISAFARI ) {
      _auto_rb.p_value = 0;
      _chrome.p_value = 0;
      _mozilla_rb.p_value = 0;
      _ie_rb.p_value = 0;
      _other_rb.p_value = 0;
      _firefox_rb.p_value = 0;
   } else if ( b == BIOTHER ) {
      _auto_rb.p_value = 0;
      _chrome.p_value = 0;
      _mozilla_rb.p_value = 0;
      _ie_rb.p_value = 0;
      _sf_rb.p_value = 0;
      _firefox_rb.p_value = 0;
   }
   info_copy.browser[osi] = b;
   info_modified = 1;
}
static void setState( typeless prog, 
                      typeless dde, 
                      typeless ddetoggle, 
                      typeless allowdefaults )
{
   boolean s=false;
   if ( prog ) s = true;
   _program_la.p_enabled = s;
   _program_tx.p_enabled = s;
   _browse1.p_enabled = s;

   if ( dde ) s = true;
   else s = false;
   _dde_fr.p_enabled = s;
   _app_la.p_enabled = s;
   _app_tx.p_enabled = s;
   _topic_la.p_enabled = s;
   _topic_tx.p_enabled = s;
   _item_la.p_enabled = s;
   _item_tx.p_enabled = s;

   if ( ddetoggle ) _useDDE_tb.p_enabled = true;
   else _useDDE_tb.p_enabled = false;

   if ( allowdefaults ) _default.p_enabled = true;
   else _default.p_enabled = false;
}
static void fillBrowser(int bi, boolean queryNew)
{
   if (queryNew ||
       (bi != BIOTHER && (info_copy.exePath[bi] == null || info_copy.exePath[bi] == ""))) {

      // we don't want to deal with any textbox changes right now
      ignore_textbox_change = 1;

      // Update from current info:
      _str execmd='';
      typeless useDDE=false;
      typeless app="";
      typeless topic="";
      typeless item="";

      getDefaultBrowserInfo(bi, execmd, useDDE, app, topic, item);
      if (bi == BICHROME || bi == BIFIREFOX || bi == BIMOZILLA) {
         typeless p1, p2;
         if( !parseItemParts(execmd,p1,p2) ) {
            execmd= p1 '%f' p2;
         }
      }

      // now fill everything in
      _program_tx.p_text = execmd;
      _app_tx.p_text = app;
      _topic_tx.p_text = topic;
      _item_tx.p_text = item;
      _useDDE_tb.p_value = useDDE;
      ignore_textbox_change = 0;
      fillHTMLInfo();
   } else if (bi == BIOTHER && info_othercopy.exePath[osi] == "") {
      _str execmd='';
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
   updateUseDDE();
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
      info_othercopy.useDDE[osi] = _useDDE_tb.p_value;
   } else {
      info_copy.exePath[bi] = _program_tx.p_text;
      info_copy.app[bi] = _app_tx.p_text;
      info_copy.topic[bi] = _topic_tx.p_text;
      info_copy.item[bi] = _item_tx.p_text;
      info_copy.useDDE[bi] = _useDDE_tb.p_value;
   }
   info_modified = 1;
}
// Desc:  Update the controls with internal data.
static void fillWithHTMLInfo()
{
   int bi = info_copy.browser[osi];
   if ( bi == BIAUTO ) {
      _auto_rb.p_value = 1;
      setBrowser( bi );
      setState( 0, 0, 0, 0 );
   } else if ( bi == BICHROME ) {
      _chrome.p_value = 1;
      setBrowser( bi );
      if ( unixRunning ) {
         setState( 1, 0, 0, 1 );
      } else {
         setState( 1, info_copy.useDDE[bi], 1, 1 );
      }
   } else if ( bi == BIMOZILLA ) {
      _mozilla_rb.p_value = 1;
      setBrowser( bi );
      if ( unixRunning ) {
         setState( 1, 0, 0, 1 );
      } else {
         setState( 1, info_copy.useDDE[bi], 1, 1 );
      }
   } else if ( bi == BIFIREFOX ) {
      _firefox_rb.p_value = 1;
      setBrowser( bi );
      if ( unixRunning ) {
         setState( 1, 0, 0, 1 );
      } else {
         setState( 1, info_copy.useDDE[bi], 1, 1 );
      }
   } else if ( bi == BIIEXPLORER ) {
      _ie_rb.p_value = 1;
      setBrowser( bi );
      setState( 1, info_copy.useDDE[bi], 1, 1 );
   } else if ( bi == BISAFARI ) {
      _sf_rb.p_value = 1;
      setBrowser( bi );
      setState( 1, 0, 0, 1 );
   } else {
      _other_rb.p_value = 1;
      setBrowser( BIOTHER );
      if ( unixRunning ) {
         setState( 1, 0, 0, 0 );
      } else {
         setState( 1, info_copy.useDDE[osi], 1, 0 );
      }
   }
   fillBrowser(bi, 0);
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
      _useDDE_tb.p_value = info_othercopy.useDDE[osi];
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
      _useDDE_tb.p_value = info_copy.useDDE[bi];
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
                         var app, var topic, var item, int overrideDDE=-1,boolean &usingDefaultBrowser=false)
{
   // If nothing is setup, try query for the data.
   // Otherwise, use existing data.
   typeless temp1 = "";
   int bi = def_html_info.browser[osi];
   if ( bi == BIOTHER ) execmd = def_html_other_info.exePath[osi];
   else execmd = def_html_info.exePath[bi];
   if ( execmd == "" ) {
      usingDefaultBrowser=true;
      getDefaultBrowserInfo( bi, execmd, useDDE, app, topic, temp1 );
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
#if __UNIX__ && !__MACOSX__
   if (get_env(VSLICKHELP_WEB_BROWSER)=='') {
      // Check if we are in the Linux plugin going to the trial website - RGH
      if (!isEclipsePlugin() && !pos("http://register.slickedit.com/trial/", execmd)) {
         set_env(VSLICKHELP_WEB_BROWSER,get_env('VSLICKBIN1'):+'mozilla/mozilla');
      } else {
         // No mozilla is shipped with the plugin, so to launch a browser via the trial dialog 
         // lets just use what is in the users path - firefox, mozilla, or netscape - RGH
         _str user_browser = path_search('firefox',"","P");
         if (user_browser :== '') {
            user_browser = path_search('mozilla', "", "P");
            if (user_browser :== '') {
               user_browser = path_search('netscape', "", "P");
            }
         }
         set_env(VSLICKHELP_WEB_BROWSER, user_browser);
      }
   }
#endif
   execmd=_replace_envvars2(execmd);

   if ( execmd == "" ) {
      _message_box( "No browser available.\n"getHowToReconfigureBrowserMsg() );
      return( 1 );
   }

   // SPECIAL CASE...
   // If filename is not specified, just build the exe command and don't
   // worry about whether or not DDE is used.
   _str msg="";
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
      boolean filename_was_quoted = ( (last_char(p1)=='"' || last_char(p1)=="'") && last_char(p1)==first_char(p2) );
      if( filename_was_quoted ) {
         // Some browsers are not tolerant (IE6) of spaces prepended to a quoted url (e.g. " http://www.slickedit.com/ "),
         // so make sure we never do that in the case of a quoted filename.
         item = p1:+filename:+p2;
      } else {
         // Make sure there is a space separating any options from the filename (e.g. '-nohome http://www.slickedit.com/')
         item = p1' 'filename' 'p2;
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
   parse item with p1 '%F' p2;
   if ( p1 != item ) return( 0 );
   parse item with p1 '%f' p2;
   if ( p1 != item ) return( 0 );
   parse item with p1 '%1' p2;
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
   int status=parseBrowserAndFileStartCommand(cmd,'',execmd,SLICKEDIT_HOME);
   return(status);
#else
   //messageNwait("cmd="cmd);
   endw = "";
   temp = cmd;
   execmd = cmd;
   qtemp = maybe_quote_filename(temp);
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
      qtemp = maybe_quote_filename(temp);
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
static int parseBrowserAndFileStartCommand(_str cmd,_str filename,_str &execmd,_str remote_default_filename='')
{
#if 1
   typeless p1, p2;
   parseItemParts(cmd,p1,p2);
   _str pgmname=parse_file(p1,false);
   if( pgmname=="" ) {
      return(1);
   }
   pgmname=path_search(pgmname,'','P');
   if( pgmname=="" ) {
      return(1);
   }
#if __UNIX__
   _str name=_strip_filename(pgmname,'P');
   // For now, assume any browser that supports the -remote command supports
   // "-remote 'ping()'"
   if (pos(' -remote ',execmd,1) /*&& name=='mozilla' || name=='netscape'*/) {
      if (filename=='') {
         filename=remote_default_filename;
      }
      filename="'"filename"'";
      int status=shell(maybe_quote_filename(pgmname)" -remote 'ping()'");
      //_message_box('status='status);
      if (status) {
         p1='';
         p2='';
      }
   }
#endif
   if (filename=='') {
      execmd=maybe_quote_filename(pgmname);
      return(0);
   }
   boolean filename_was_quoted = ( (last_char(p1)=='"' || last_char(p1)=="'") && last_char(p1)==first_char(p2) );
   if( filename_was_quoted ) {
      // Some browsers are not tolerant (IE6) of spaces prepended to a quoted url (e.g. " http://www.slickedit.com/ "),
      // so make sure we never do that in the case of a quoted filename.
      execmd=maybe_quote_filename(pgmname)' 'p1:+filename:+p2;
   } else {
      // Make sure there is a space separating any options from the filename (e.g. '-nohome http://www.slickedit.com/')
      execmd=maybe_quote_filename(pgmname)' 'p1' 'filename' 'p2;
   }
   //_message_box(execmd);
   return(0);
#else
   execmd = cmd;
   tempcmd=stranslate(cmd,filename,'%f','i');
   pgmname=parse_file(tempcmd,false);
   if (pgmname=='') {
      return(1);
   }
   pgmname=path_search(pgmname,'','P');
   if (pgmname=='') {
      return(1);
   }
   execmd=maybe_quote_filename(pgmname)' 'tempcmd;
   //_message_box('0 execmd='execmd);
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
   int i = 0;
   browser_list[i][0] = "firefox";
   browser_list[i++][1] = "'%f'";
   browser_list[i][0] = "mozilla";
   browser_list[i++][1] = "-remote 'openURL('%f')'";
   browser_list[i][0] = "netscape";
   browser_list[i++][1] = "-remote 'openURL('%f')'";

   int size = browser_list._length();
   for (i = 0; i < size; ++i) {
      _str browser_path = path_search(browser_list[i][0]);
      if (browser_path != '') {
         // System browser found.
         _str cmd = browser_path' 'browser_list[i][1];
         return cmd;
      }
   }
   return '';
}

static void getMozilla( var execmd, var useDDE, var app, var topic, var item)
{
   if ( unixRunning ) {
      _str browser_command = get_system_browser_command();
      if (browser_command != '') {
         execmd = browser_command;
      } else {
         execmd = '"%('VSLICKHELP_WEB_BROWSER')"':+" -remote 'openURL(%F)'";
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
      execmd = '"%('VSLICKHELP_WEB_BROWSER')"':+" ' %F'";
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
         execmd = '';
      }
      app = '';
      topic = '';
      item = '';
      useDDE = 0;
      return;
   }
   typeless value=_ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Classes\\htmlfile\\shell\\open\\command","");
   execmd = value;
   app = "IExplore";
   topic = "WWW_OpenURL";

   item = '"%F",,0xFFFFFFFF,0x3,,,';
#if 0
   if (type :== 'p') {
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
   app='';
   topic='';
   item='';
}
static void getMacDefaultOpenURL(var execmd, var useDDE, var app, var topic, var item)
{
   execmd='open "%F"';
   useDDE=0;
   app='';
   topic='';
   item='';
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
      if (value == '') {
         value=_ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Classes\\ChromeHTML\\shell\\open\\command","");
      }
      execmd = value;
      app = "";
      topic = "";
      item = "";
      useDDE = 0;
   }
}
// Desc:  Look up the Registry for browser information.
static void getAuto( var execmd, var useDDE, var app, var topic, var item )
{
   if (unixRunning) {
      if (_isMac()) {
         getMacDefaultOpenURL(execmd,useDDE,app,topic, item );
         return;
      }
      getMozilla(execmd,useDDE,app,topic,item);
      return;
   }

   _str regComp =_ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Classes\\.htm","");
   if ( regComp == "FirefoxHTML" ) {
      getFirefox( execmd, useDDE, app, topic, item );
   } else if ( regComp == "htmlfile" || regComp=="htmfile") {
      getIE( execmd, useDDE, app, topic, item );
   } else {
      execmd = "";
      app = "";
      topic = "";
      item = "";
      useDDE = 0;
   }
}
static void getOther( var execmd, var useDDE, var app, var topic, var item)
{
   execmd = "";
   app = "";
   topic = "";
   item = "";
   useDDE = 0;
}
static void toggleUseDDE( boolean s )
{
   _dde_fr.p_enabled = s;
   _app_la.p_enabled = s;
   _app_tx.p_enabled = s;
   _topic_la.p_enabled = s;
   _topic_tx.p_enabled = s;
   _item_la.p_enabled = s;
   _item_tx.p_enabled = s;
}
static void updateUseDDE()
{
   if (_useDDE_tb.p_enabled && _useDDE_tb.p_value) toggleUseDDE( true );
   else toggleUseDDE( false );
}
static void quotecmd( var execmd )
{
   //messageNwait( "b4 cmd="execmd );
   //p = pos( '"', execmd );
   //if ( p == 1 ) return;

   _str endw = "";
   _str temp = execmd;
   _str qtemp = maybe_quote_filename(temp);
   for (;;) {
      //messageNwait( "b4 qtemp="qtemp );
      _str fn = file_match("-p "qtemp, 1 );
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
      qtemp = maybe_quote_filename(temp);
   }
}
// Desc:  Activate the browser and bring it to foreground.
// Retn:  0 for OK, < 0 for error.
static int activateBrowser(_str app)
{
   //messageNwait( "PREVENT CRASH... b4 _dderequest WWW_Activate app="app );
   _str item = "0xFFFFFFFF,0x0";
   _str topic = "WWW_Activate";
   int old_view_id = p_window_id;
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
   _str execmd='';
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
      _str msg = "Can't start browser with \n'"execmd"'.\n\n"getHowToReconfigureBrowserMsg();
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
   int view_id = 0;
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


//---------------------------------------------------------------------
// Desc:  Check to see if tag is a standalone tag, having no matching
//     start and end component.
// Retn:  1 for yes, 0 for no.
static int isStandAloneTag( _str tag )
{
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
   int level = 0;
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
   int level = 0;
   //status = search( "[<>]", "r@CK" );
   status = search( "[<>]", "rh@XCS" );
   for (;;) {
      if ( status ) {
         _nrseek( oPos );
         return( -1 );
      }
      _str ch = get_text_safe();
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
   if (get_text_safe(2) == '<%') {
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

   // Bulletin Board Code tags use brackets
   typeless status = 0;
   if (_LanguageInheritsFrom('bbc')) {
      status = search("]", "h@XCS");
   } else {
      status = search(">", "h@XCS");
   }
   if ( status ) {
      _nrseek( oPos );
      return( "" );
   }
   seek_pos = _nrseek();
   _str tag = get_text_safe( seek_pos - startPos, startPos );
   boolean is_start_and_end=last_char(tag)=='/';
   tag=strip(tag,'T','/');
   tag = strip( tag, "L" );
   int p = pos(":b|\n|\r", tag, 1, "r" );
   if ( p ) {
      tag =  substr( tag, 1, p-1);
   }
   if (!p_EmbeddedCaseSensitive) {
      tag = case_html_tag( tag );
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
   int status = 0;
   if (_LanguageInheritsFrom('bbc')) {
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
   int level = 0;
   typeless oPos = _nrseek();
   typeless status = _nrseek( oPos - 1 );
   if ( status == "" ) {
      status = _nrseek( oPos );
      return( -1 );
   }

   // Bulletin Board Code tags use brackets
   if (_LanguageInheritsFrom('bbc')) {
      status = search( "[\\[\\]]", "-rh@XCS" );
   } else {
      status = search( "[<>]", "-rh@XCS" );
   }

   for (;;) {
      if ( status ) {
         _nrseek( oPos );
         return( -1 );
      }
      _str ch = get_text_safe();
      if ( _LanguageInheritsFrom('bbc') && ch == "]" ) {
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
static int matchTagForward( _str ktag, int cursorAtEndTag )
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
      if (_LanguageInheritsFrom('bbc')) {
         search_str = "\\[[ \t]@(":+ktag:+"|/":+ktag:+")";
      } else {
         search_str = "\\<[ \t]@(":+ktag:+"|/":+ktag:+")";
      }
      //messageNwait("search_str="search_str);
      //status = search(search_str, "ri@CK");
      status = search(search_str, "rih@XCS");
      if (status) return(-1);
      _str ch;
      int startTag;
      ch = _html_GetTag(1, startTag);
      //messageNwait('ch='ch' startTag='startTag);
      if (!startTag) {  // Found ending tag
         --level;
         if (level<0) {
            // We are lost
            return(-1);
         }
         if (!level) {
            // Bulletin Board Code tags use brackets
            if (_LanguageInheritsFrom('bbc')) {
               status = search("[", "-h@XCS");  // position the text cursor at the start of the tag
            } else {
               status = search("<", "-h@XCS");  // position the text cursor at the start of the tag
            }
            return(0);
         }
         // Bulletin Board Code tags use brackets
         if (_LanguageInheritsFrom('bbc')) {
            status = search("]", "@hXCS");  // skip to the end of the tag
         } else {
            status = search(">", "@hXCS");  // skip to the end of the tag
         }
         if (status) return(-1);
      } else if(startTag==1) {  // Nested tag
         ++level;
         // Bulletin Board Code tags use brackets
         if (_LanguageInheritsFrom('bbc')) {
            status = search("]", "@hXCS");  // skip to the end of the tag
         } else {
            status = search(">", "@hXCS");  // skip to the end of the tag
         }
         if (status) return(-1);
      } else if (startTag==2) {
         if (!level) {
            // Bulletin Board Code tags use brackets
            if (_LanguageInheritsFrom('bbc')) {
               status = search("[", "-@hXCS");  // position the text cursor at the start of the tag
            } else {
               status = search("<", "-@hXCS");  // position the text cursor at the start of the tag
            }
            return(0);
         }

         // Bulletin Board Code tags use brackets
         if (_LanguageInheritsFrom('bbc')) {
            status = search("]", "@hXCS");  // skip to the end of the tag
         } else {
            status = search(">", "@hXCS");  // skip to the end of the tag
         }
         if (status) return(-1);
      }
   }
   return(-1);
}
int _html_matchTagBackward( _str ktag )
{
   int status;
   int level;

   ktag=_escape_re_chars(ktag);
   level = 0;

   // Bulletin Board Code tags use brackets
   _str search_str;
   if (_LanguageInheritsFrom('bbc')) {
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
         // Bulletin Board Code tags use brackets
         if (_LanguageInheritsFrom('bbc')) {
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
         if (!level) {
            return(0);  // found matching tag and cursor also already at the beginning of the tag
         }
         // Bulletin Board Code tags use brackets
         if (_LanguageInheritsFrom('bbc')) {
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
         if (_LanguageInheritsFrom('bbc')) {
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
static int matchTag( int cursorAtEndTag, var direction )
{
   int startTag;
   _str tag = _html_GetTag( 1, startTag );
   if ( tag == "" ) {
      return( -1 );
   }
   if ( tag == "!--" ) {
      return( -3 );
   }
   if ( !_LanguageInheritsFrom('xml') && isStandAloneTag(tag) ) {
      return( -2 );
   }
   typeless status=0;
   if ( startTag ) {
      status = matchTagForward( tag, cursorAtEndTag );
      direction = "F";
   } else {
      status = _html_matchTagBackward( tag );
      direction = "B";
   }
   return( status );
}

long matchTagOffset(_str ktag, int cursorAtEndTag) {
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
   long orig_offset = _QROffset();
   long returnVal = 0;


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
   int status = search( "<!--", "-@h" );
   if ( status ) {
      _nrseek( oPos );
      return( -1 );
   }
   return( 0 );
}

int findStartTag2(){
   return findStartTag();
}

// Desc:  Find the start of a tag.  If already on a tag, do nothing.
// Retn:  0 for OK, <0 for error.
static int findStartTag()
{
   // Look forward for end tag:
   typeless oPos = _nrseek();

   // Bulletin Board Code tags use brackets
   int status = 0;
   if (_LanguageInheritsFrom('bbc')) {
      status = search( "[\\[\\]]", "rh@XCS" );
   } else {
      status = search( "[<>]", "rh@XCS" );
   }
   if ( status ) {
      _nrseek( oPos );
      return( -1 );
   }
   typeless seek_pos=0;
   _str ch = get_text_safe();
   if ( ch == ">" || (_LanguageInheritsFrom('bbc') && ch == "]")) {
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
   _str tag="";
   _str start="";
   int taglevel = 0;
   int level = 0;
   for (;;) {
      // Bulletin Board Code tags use brackets
      if (_LanguageInheritsFrom('bbc')) {
         status = search( "[\\[\\]]", "-rh@XCS" );
      } else {
         status = search( "[<>]", "-rh@XCS" );
      }
      if ( status ) {
         _nrseek( oPos );
         return( -1 );
      }
      ch = get_text_safe();
      if ( ch == ">" || ch == ']') {
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
      } else if ( ch == "<" || ch == '[') {
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
int _bbc_find_matching_word(boolean quiet)
{
   return(htool_matchtag(quiet));
}
int _html_find_matching_word(boolean quiet)
{
   return(htool_matchtag(quiet));
}
//---------------------------------------------------------------------
// Desc:  Match the tag component.
//
//        <FONT FACE="ITC Officina Sans Bold" POINT-SIZE=9>Hello</FONT>
//        ^                                                     ^
// Retn:  0 for OK, -1 for error.
_command int htool_matchtag(boolean quiet=false)  name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   _str lang = p_LangId;
   if (!_LanguageInheritsFrom("html",lang) && !_LanguageInheritsFrom("xml",lang) && !_LanguageInheritsFrom('bbc', lang)) {
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
   typeless oPos = _nrseek();

   // Special case for VB code tag braces <% and %>.
   typeless status=0;
   if (get_text_safe(2) == '<%' || get_text_safe(2) == '%>') {
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

   int oLine = p_line; 
   int oCol = p_col;

   // Find the matching tag:
   typeless direction=0;
   status = matchTag( 0, direction );
   if ( status ) {
      restore_pos( cs_ori_position );
      _nrseek( oPos );
      if (!quiet) {
         message( "Matching HTML/XML tag pair not found!" );
      }
   }
   return( 0 );
}

// Desc:  Select the tag component.
//
//        <FONT FACE="ITC Officina Sans Bold" POINT-SIZE=9>Hello</FONT>
//        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
_command int htool_selectcomp()  name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   _str lang = p_LangId;
   if (!_LanguageInheritsFrom("html",lang) && !_LanguageInheritsFrom("xml",lang)) {
      message( "Selecting HTML tag component only works with HTML files." );
      return( -1 );
   }

   // Remember the position:
   save_pos( cs_ori_position );
   typeless oPos = _nrseek();

   findStartTag();
   int oLine = p_line; 
   int oCol = p_col;
   skipOverTag();

   // Tag found, select the text between the start tag and the end tag:
   int temp_line = p_line; 
   int temp_col = p_col;
   deselect();
   _str persistent=(def_persistent_select=='Y')?'P':'';
   _str mstyle='EN'persistent;

   // Restore the original position before starting selection:
   // This prevents the 'jumping' of the view.
   restore_pos( cs_ori_position );

   // Select text:
   if ( temp_line != oLine ) {
      // Selected text spans multiple lines, do line selection:
      p_line = oLine; p_col = oCol;
      _select_line('',mstyle);
      p_line = temp_line; p_col = temp_col;
      _select_line('',mstyle);
   } else {
      // Selected text spans a single line, do character selection:
      p_line = oLine; p_col = oCol;
      _select_char('',mstyle);
      p_line = temp_line; p_col = temp_col;
      _select_char('',mstyle);
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
   int oLine = p_line; 
   int oCol = p_col;

   // Find the matching tag:
   typeless direction=0;
   int status;
   status = matchTag( 1, direction );
   if (status == -1) {  // match not found
      // Special case for P tag:
      // We treat the P tag special because it may and may not have
      // its matching /P.
      int startOfTag;
      _str tag;
      _nrseek(startTagPos);
      tag = _html_GetTag(0, startOfTag);

      // When we find a <P> without matching </P>,
      // scan for the next blank line or next <P> tag.
      if (tag == "P") {
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
   int temp_line = p_line; 
   int temp_col = p_col;

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

   int countPtag;
   countPtag = 0;

   // Find the next ending tag that does not have a matching starting tag:
   // If found, this is the ending of the tag that encloses the currently
   // selected tag.
   while (1) {
      // Found the ending of a tag:
      int startTag;
      _str tag;
      tag = _html_GetTag(1, startTag);

      // Special case for P and /P tags:
      if (tag == "P") {
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
         int seek_pos;
         seek_pos = _nrseek();
         if (_nrseek(seek_pos + 1) == "") return(-1);
         if (skipToNextTag() < 0) return(-1);
         continue;
      }

      // If found an end tag (/XXX), we found the next nesting level:
      if (!startTag) break;

      // Skip over stand-alone tags:
      if (isStandAloneTag(tag)) {
         int seek_pos;
         seek_pos = _nrseek();
         if (_nrseek(seek_pos + 1) == "") return(-1);
         if (skipToNextTag() < 0) return(-1);
         continue;
      }

      // This is the start of a tag, jump to its matching end:
      // Find the matching end tag:
      _str direction;
      typeless status = matchTag( 0, direction );
      if (status == -1) return(-1);  // matching ending tag is not found! Give up.

      // Found stand-alone tag or found the matching ending tag, just skip over it:
      int seek_pos;
      seek_pos = _nrseek();
      if (_nrseek(seek_pos + 1) == "") return(-1);
      if (skipToNextTag() < 0) return(-1);
   }

   // Select this new tag:
   return(htool_selecttag2(startLine, startCol, endLine, endCol));
}

_command void goto_slickedit() name_info(','HELP_ARG2|NCW_ARG2|ICON_ARG2|EDITORCTL_ARG2)
{
   goto_url(SLICKEDIT_SUPPORT);
}

_command void goto_faq() name_info(','HELP_ARG2|NCW_ARG2|ICON_ARG2|EDITORCTL_ARG2)
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
_command void online_registration(_str arg1="") name_info(',')
{
   //goto_url('www.slickedit.com/register.htm');
   _str path=editor_name('P');
   path=path:+'vsreg.ex';
   if( !file_exists(path) ) {
      // check if macros/vsreg.e exists (slickedit/internal development)
      path = absolute(get_env('VSROOT'));
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
   _str cmdline=maybe_quote_filename(path);
   if( arg1!="" ) {
      cmdline=cmdline:+" ":+arg1;
   }
#if __UNIX__
   cmdline="xcom ":+cmdline;
#endif
   execute(cmdline);
}
/**
 * Displays URL in Web browser.
 * 
 * @categories File_Functions
 * @param webpage URL to go to
 * @param UseHelpBrowser
 * @param overrideDDE If -1, the user's preference for using DDE is
 * honored. If 0, DDE is not used in this case. If 1, DDE is used.
 * 
 * @see open_url
 * @see open_url_in_assoc_app
 */
_command int goto_url(_str webpage="",boolean UseHelpBrowser=false, int overrideDDE=-1) name_info(','VSARG2_MARK)
{
   int start_col=0;
   int end_col=0;
   _str line="";
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
      if (webpage=='') {
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
   int view_id = 0;
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
 * Goto a URL in a safe, controlled manner. What we do is basically convert all
 * '&' characters in the URL into '\&' on Unix (but not MacOS) and then use the
 * help browser to open the URL
 * 
 * @param URL The URL to go to
 */
void safe_goto_url(_str URL, boolean UseHelpBrowser=false, int overrideDDE=-1)
{
   if (!_isMac() && machine() != "WINDOWS") {
      URL = stranslate(URL, "\\&", "&");
   }

   goto_url(URL, UseHelpBrowser, overrideDDE);
}

defeventtab _html_tagoptions_form;
// hash table to store changes to per tag settings
static _str changed_tags:[]:[];
static boolean change_radio = false;

/**
 * static hash table created to store information for
 * HTML syntax expansion.
 */

static _str tag_info:[]:[];

/**
 * Initialize the static tag_info.
 *
 * @return
 */
definit()
{
   tag_info._makeempty();
}

/**
 * Callback indicating that the HTML beautify
 * settings have changed.  Reloads tag_info.
 *
 * @param ext
 * @param scheme_name
 */
void _hformatSaveScheme_update(_str ext, _str scheme_name)
{
   if (upcase(ext) == 'HTML' && upcase(scheme_name) == 'DEFAULT') {
      // clear the table out of memory
      tag_info._makeempty();
      // load the updated table
      typeless status = _html_tags_loaded();
   }
}

_command void html_tab() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_ICON|VSARG2_LASTKEY|VSARG2_MARK)
{
   embedded_key();
}
_command void html_key() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_ICON|VSARG2_LASTKEY)
{
   embedded_key();
}

/**
 * Handle ENTER key in HTML editing mode.
 * This attempts to intelligently indent the next
 * line, by either indenting to the current indent
 * level, or indenting one more level deep.
 */
_command void html_enter() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_ICON|VSARG2_LASTKEY)
{
   if (ispf_common_enter()) return;
   if (command_state() || (p_active_form.p_name == '_javadoc_form')) {
      call_root_key(ENTER);
      return;
   }

   if (p_window_state :== 'I' ||
       p_SyntaxIndent<0 ||
       p_indent_style != INDENT_SMART ||
       _in_comment(1) ||
       !_html_tags_loaded() ||
       _html_expand_enter())
   {
      typeless orig_values=null;
      int embedded_status=_EmbeddedStart(orig_values);
      if (embedded_status==1) {
         _macro('m',0);
         call_key(last_event(), "\1", "L");
         _EmbeddedEnd(orig_values);
         return; // Processing done for this key
      }
      call_root_key(ENTER);
   } else if (_argument=='') {
      _undo('S');
   }
}

/**
 * Inserts a new line and indents based on the indentation
 * level indicated.  Returns 0 if successful.
 */
static int indent_to_level(typeless enter_name, int indent_column = 0)
{
   if (enter_name !='nosplit-insert-line') {
      _str textAfterCursor=_expand_tabsc(p_col,-1,'S');
      if (textAfterCursor!="") {
         _delete_text(-1);
         insert_line(indent_string(indent_column-1):+textAfterCursor);
         first_non_blank();
         return(0);
      }
   }
   if (LanguageSettings.getInsertRealIndent(p_LangId)) {
      insert_line(indent_string(indent_column-1));
   } else {
      insert_line('');
      p_col = indent_column;
   }
   return(0);
}

static boolean ant_expand_space(){
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;
   _str line='';
   get_line(line);
   line=strip(line,'T');
   _str orig_word=lowcase(strip(line));
   if ( p_col!=text_col(_rawText(line))+1 ) {
      return false;
   }
   _str key=min_abbrev2(orig_word,ant_space_words,name_info(p_index),'');
   if (key == "") {
      last_event(' ');
      return false;
   }
   parse key with auto word ">" auto rest;
   line=substr(line,1,length(line)-length(orig_word)):+word;
   int width=text_col(_rawText(line),_rawLength(line)-_rawLength(word)+1,'i')-1;
   clear_hotspots();
   switch (word) {
   case '<project': {
      _str new_line = line :+ " name=\"\" basedir=\".\" default=\"\">";
      replace_line(new_line);
      end_line();
      p_col -= 2;
      add_hotspot();
      p_col -= 12;
      add_hotspot();
      p_col -= 11;
      add_hotspot();
      _save_pos2(auto p);
      insert_line(indent_string(width + syntax_indent));
      finish_ant_expansion();
      _restore_pos2(p);
      break;
   }
   case '<target': {
      boolean depends = pos('depend',key) > 0 ? true : false;
      _str new_line = line :+ " name=\"\"";
      if (depends) {
         new_line = new_line :+ " depends=\"\">";
      } else {
         new_line = new_line :+ ">";
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
      insert_line(indent_string(width + syntax_indent));
      finish_ant_expansion();
      _restore_pos2(p);
      break;
   }
   case '<macrodef': {
      _str new_line = line :+ " name=\"\">";
      replace_line(new_line);
      end_line();
      p_col -= 2;
      add_hotspot();
      _save_pos2(auto p);
      insert_line(indent_string(width + syntax_indent));
      finish_ant_expansion();
      _restore_pos2(p);
      break;
   }
   case '<jar': {
      _str new_line = line :+ " destfile=\"\"";
      boolean multiline = pos('params',key) > 0 ? false : true;
      if (multiline) {
         new_line = new_line :+ ">";
      } else {
         new_line = new_line :+ "/>";
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
         insert_line(indent_string(width + syntax_indent));
         finish_ant_expansion();
         _restore_pos2(p);
      }
      break;
   }
   case '<exec': {
      _str new_line = line :+ " executable=\"\">";
      replace_line(new_line);
      end_line();
      p_col -= 2;
      add_hotspot();
      _save_pos2(auto p);
      insert_line(indent_string(width + syntax_indent));
      finish_ant_expansion();
      _restore_pos2(p);
      break;
   }
   case '<mkdir': {
      _str new_line = line :+ " dir=\"\"/>";
      replace_line(new_line);
      end_line();
      p_col -= 3;
      add_hotspot();
      break;
   }
   case '<property': {
      boolean file = pos('file',key) > 0 ? true : false;
      boolean location = pos('location',key) > 0 ? true : false;
      _str new_line = line;
      if (file) {
         new_line = new_line :+ " file=\"\"/>"; 
      } else if (location) {
         new_line = new_line :+ " name=\"\" location=\"\"/>"; 
      } else {
         new_line = new_line :+ " name=\"\" value=\"\"/>"; 
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
   case '<antcall': {
      boolean params = pos('params',key) > 0 ? true : false;
      _str new_line = line;
      if (params) {
         new_line = new_line :+ " target=\"\">";
      } else {
         new_line = new_line :+ " target=\"\"/>";
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
         insert_line(indent_string(width + syntax_indent) :+ "<param name=\"\" value=\"\"/>");
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
   case '<import': {
      _str new_line = line :+ " file=\"\"/>";
      replace_line(new_line);
      end_line();
      p_col -= 3;
      break;
   }
   case '<echo': {
      _str new_line = line :+ " message=\"\"/>";
      replace_line(new_line);
      end_line();
      p_col -= 3;
      break;
   }
   case '<delete': {
      boolean ref = pos('reference',key) > 0 ? true : false;
      _str new_line = line :+ ">";
      replace_line(new_line);
      if (ref) {
         insert_line(indent_string(width + syntax_indent) :+ "<fileset refid=\"\"/>");
         p_col -= 3;
         add_hotspot();
         _save_pos2(auto p);
         insert_line("<");
         xml_slash();
         _restore_pos2(p);
      } else {
         insert_line(indent_string(width + syntax_indent) :+ "<fileset dir=\"\">");
         p_col -= 2;
         add_hotspot();
         _save_pos2(auto p);
         insert_line(indent_string(width + syntax_indent*2) :+ "<include name=\"\"/>");
         p_col -= 3;
         add_hotspot();
         insert_line(indent_string(width + syntax_indent*2) :+ "<exclude name=\"\"/>");
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
   case '<fileset': {
      _str new_line = line :+ " dir=\"\" id=\"\">";
      replace_line(new_line);
      end_line();
      p_col -= 2;
      add_hotspot();
      p_col -= 6;
      add_hotspot();
      _save_pos2(auto p);
      insert_line(indent_string(width + syntax_indent) :+ "<include name=\"\"/>");
      p_col -= 3;
      add_hotspot();
      insert_line(indent_string(width + syntax_indent) :+ "<exclude name=\"\"/>");
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
boolean _html_expand_enter()
{  
   if (XW_doEnter()) {
      return false;
   }
   if (p_EmbeddedLexerName != '') {
      return(true);
   }

   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;

   save_pos(auto p);
   _str enter_name = name_on_key(ENTER);
   _str line="";
   get_line(line);
   while( line=='' && !_on_line0()) {
      up();
      get_line(line);
   }
   first_non_blank();
   int cur_indent_level = p_col;
   restore_pos(p);
   if (enter_name == 'nosplit-insert-line') {
      _end_line();
   } else if (enter_name == 'maybe-split-insert-line') {
      if (!_insert_state()) {
         if (down()){
            insert_line('');
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
int html_indent_col(int non_blank_col, boolean paste_open_block = false)
{
   _str tag_stack[];
   tag_stack._makeempty();
   save_pos(auto p);
   // figure out the current indentation level
   _str current_tag="";
   _str end_tag="";
   int orig_col = p_col;
   int indent_col = non_blank_col;
   p_col = orig_col;
   for (;;) {
      current_tag = _html_goto_previous_tag();
      if (current_tag == '') {
         // one way or another, there are not any more tags to be found
         break;
      }
      end_tag = (substr(current_tag,1,1)=='/');
      if (end_tag) {
         current_tag = substr(current_tag,2);
      }
      if (_html_get_attr_val(current_tag,'standalone') && _html_get_attr_val(current_tag,'indent_content')) {
         // make sure that this is not an end tag
         if (end_tag) {
            // put the end tag on the stack
            tag_stack[tag_stack._length()] = current_tag;
         } else {
            if (tag_stack._length() == 0) {
               // we are done
               first_non_blank();
               indent_col = p_col + p_SyntaxIndent;
               restore_pos(p);
               break;
            } else {
               int counter = tag_stack._length()-1;
               boolean removed = false;
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
static boolean line_clear()
{
   _str textAfterCursor=strip(_expand_tabsc(p_col,-1,'S'));
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
_command void insert_close_tag()
{
   if (!_html_tags_loaded() || _in_comment()) {
      return;
   }
   save_pos(auto p);

   // semi intelligent search
   _str current_tag="";
   for (;;) {
      current_tag = _html_goto_previous_tag();
      if (current_tag == '') {
         break;
      }
      if (substr(current_tag,1,1)=='/'){
         // found an end tag, now find the begin tag
         int status = search('\<{':+_escape_re_chars(substr(current_tag,2))'}','-<@IRhXCS');
         if (status) {
            // malformed html, time to fall back to a simple search
            break;
         }
      } else {
         // search found an open tag that we can close
         if (_html_get_attr_val(current_tag,'endtag_required')){
            restore_pos(p);
            if (_html_get_attr_val(current_tag,'standalone') && _html_get_attr_val(current_tag,'indent_content')) {
               _str line="";
               get_line(line);
               if (strip(line)=='') {
                  int indent_col = html_indent_col(p_col) - p_SyntaxIndent;
                  if (indent_col>0) {
                     replace_line(indent_string(indent_col-1));
                     _end_line();
                  }
               }
            }
            _insert_text('</':+case_html_tag(current_tag)'>');
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
      if (current_tag == '') {
         restore_pos(p);
         break;
      }
      if (!(substr(current_tag,1,1)=='/') && _html_get_attr_val(current_tag,'endtag_required')){
         restore_pos(p);
         _insert_text('</':+case_html_tag(current_tag)'>');
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
   _str current_tag="";
   for (;;) {
      current_tag = _html_goto_previous_tag();
      if (current_tag == '') {
         restore_pos(p);
         return(1);
      }
      if (substr(current_tag,1,1)=='/'){
         // found an end tag, now find the begin tag
         int status = search('\<{':+_escape_re_chars(substr(current_tag,2))'}','-<@IRhXCS');
         if (status) {
            // malformed html, time to bail
            restore_pos(p);
            return(1);
         }
      } else {
         // search found an open tag that we can close
         if (_html_get_attr_val(current_tag,'endtag_required')){
            restore_pos(p);
            _insert_text('/':+case_html_tag(current_tag)'>');
            if (get_text_safe(1) == '>') {
               p_col = p_col + 1;
            }
            return(0);
         }
      }
   }
}

_command void html_lt() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_ICON|VSARG2_LASTKEY)
{
   if (command_state() || _in_comment()) {
      call_root_key(last_event());
      return;
   }
   _str key=last_event();
   if (_EmbeddedLanguageKey(key)) return;
   auto_codehelp_key();
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
   int orig_col = p_col;
   int status = search('\<','-<@RhXCS');
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
   _str current_char = get_text_safe(1);
   if (_LanguageInheritsFrom('bbc')) {
      _insert_text(']');
   } else {
      _insert_text('>');
      if (XW_isSupportedLanguage2()) {
         if (ST_doSymbolTranslation()) {
            ST_nag();
            return;
         }
      }
      if (_LanguageInheritsFrom('html') && XW_gt()) {
         return;
      }
   }
   if (current_char != '>' && _html_tags_loaded()) {
      //figure out the current tag
      boolean is_end_tag = false;
      _str current_tag = get_cur_open_tag(is_end_tag);

      // if the current tag is '' or the current tag does not require
      // an end tag then there is no work necessary
      if (current_tag == '' || is_end_tag || !req_end_tag(current_tag)) {
         return;
      }

      // put in the closing tag
      insert_html_close_tag(current_tag);
   }
}

/**
 * Intercepts the '>' key press in HTML and depending on the
 * HTML Syntax expansion options, potentially inserts
 * a closing HTML tag if the user just entered an open tag.
 */
_command void html_gt() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_ICON|VSARG2_LASTKEY)
{
   boolean block_tag_closed = false;
   if (command_state() || _in_comment() || !_html_tags_loaded() || (p_active_form.p_name == '_javadoc_form')) {
      call_root_key(last_event());
      return;
   }
   _str key=last_event();
   if(_EmbeddedLanguageKey(key)) return;
   if (_LanguageInheritsFrom('bbc') != (key==']')) {
      call_root_key(last_event());
      return;
   }

   if (! LanguageSettings.getSyntaxExpansion(p_LangId)) {
       call_root_key(last_event());
       return;
   }
   maybe_insert_html_close_tag();
}

_command void html_space() name_info(','VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
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
static int load_tag_info()
{
   tag_info._makeempty();
   int temp_view_id=0;
   typeless status = _ini_get_section(FormatUserIniFilename(),"html-scheme-"HF_DEFAULT_SCHEME_NAME,temp_view_id);
   if (status) {
      HFormatMaybeCreateDefaultScheme();
      status = _ini_get_section(FormatUserIniFilename(),"html-scheme-"HF_DEFAULT_SCHEME_NAME,temp_view_id);
      if (status) {
         return(1);
      }
   }
   _str line="";
   _str tagname="";
   _str attribute="";
   _str value="";
   int orig_view_id=p_window_id;
   p_window_id=temp_view_id;
   while (!down()) {
      get_line(line);
      // check to make sure that we are really getting the information we are looking for
      if (pos('^tag\*?*\*?@$',line,1,'R')) {
         // we have data that we want
         parse line with 'tag*' tagname '*' attribute '=' value;
         tag_info:[tagname]:[attribute] = value;
      }
   }
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   typeless i;
   for( i._makeempty();; ) {
      tag_info._nextel(i);
      if( i._isempty() ) break;
      // if there is no eo_insert_endtag field, create one and set it equal to endtag_required
      if (tag_info:[i]:['eo_insert_endtag']._isempty()) {
         if (!(tag_info:[i]:['endtag']._isempty()) && !(tag_info:[i]:['endtag_required']._isempty())) {
            tag_info:[i]:['eo_insert_endtag'] = tag_info:[i]:['endtag'] && tag_info:[i]:['endtag_required'];
         } else {
            tag_info:[i]:['eo_insert_endtag'] = 0;
         }
         changed_tags:[i]:['eo_insert_endtag'] = 1;
      }
   }
   if (!changed_tags._isempty()) {
      save_html_changes();
   }
   return(0);
}

/**
 * Determines if the table of html tags has been loaded
 * from disk into the static hash table tag_info.
 * If the table has not been loaded, it gets loaded.  If it
 * cannot be loaded, return false.
 *
 * @return
 */
boolean _html_tags_loaded()
{
   if (tag_info._isempty()) {
      int status = load_tag_info();
      if (status) {
         return(false);
      }
   }
   return(true);
}

/**
 * On exit, this function gets rid of the static hash table created for HTML
 * syntax expansion.
 */
void _before_write_state_htmlexp()
{
   tag_info._makeempty();
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
static _str get_cur_open_tag(boolean &end_tag)
{
   int tag_stack = 0;
   save_pos(auto p);
   // to move the cursor off of the '>' that was just inserted
   left();
   left();
   _str search_flags = '-<@RhXCS';
   if (_inJavadoc()) search_flags = '-<@RhCc';
   typeless status = 0;

   // Bulletin Board Code tags use brackets
   if (_LanguageInheritsFrom('bbc')) {
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
         return('');
      }
      _str current_tag=get_text_safe(match_length());
      if (current_tag == '>' || current_tag == ']') {
         tag_stack++;
      } else {
         if (tag_stack > 0 && pos('<',current_tag)) {
            tag_stack--;
         } else {
            end_tag = (substr(current_tag,2,1)=='/');
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
   if (!_in_comment() && get_text_safe() == '<'){
      if (p_col == 1) {
         if (up()){
            return('');
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
         return('');
      }
      // if we landed in an embedded language, search again
      if (p_EmbeddedLexerName != '') {
         status = repeat_search();
      } else {
         break;
      }
   }
   return(get_text_safe(match_length('0'),match_length('S0')));
}


/**
 * Moves the cursor to the next html tag to the right of the cursor.
 * Returns '' and restores the cursor postion if no tag is found.
 * Otherwise, the tag is returned and the cursor is on the '<'.
 *
 * Restricts search within current mark
 * @return
 */
static _str goto_next_tag()
{
   save_pos(auto p);
   int status = search('\<{(/|)[~ \t/\>\<]#}','+>M@RhXCS');
   for(;;){
      if (status) {
         // did not find a '<'
         restore_pos(p);
         return('');
      }
      // if we landed in an embedded language, search again
      if (p_EmbeddedLexerName != '') {
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
static boolean has_matching_end_tag()
{
   save_pos(auto p);
   left();
   long orig_pos = _QROffset();
   int status = find_matching_paren(true);
   if (status < 0) {
      restore_pos(p);
      return false;
   }
   boolean found_it = (_QROffset() != orig_pos);
   restore_pos(p);
   return found_it;
}

/**
 * Returns true if an end tag should be inserted for cur_tag.
 *
 * @param cur_tag
 * @return
 */
static boolean req_end_tag(_str cur_tag)
{
   return (_html_get_attr_val(cur_tag,'eo_insert_endtag') && (line_clear() || !has_matching_end_tag()));
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
   tag = upcase(tag);
   if (tag_info:[tag]._isempty()) {
      return(0);
   }
   if (tag_info:[tag]:[attribute]._isempty()) {
      return(0);
   }
   typeless value = tag_info:[tag]:[attribute];
   return(value);
}

/**
 * Inserts the close tag for the given tag.
 *
 * @param endtag
 */
static void insert_html_close_tag( _str endtag = '')
{
   _str tagopen = case_html_tag(endtag);
   _str tagclose = tagopen;

   // Bulletin Board Code tags use brackets
   if (_LanguageInheritsFrom('bbc')) {
      tagopen = '[':+tagopen:+']';
      tagclose   = '[/':+tagclose:+']';
   } else {
      tagopen = '<':+tagopen:+'>';
      tagclose   = '</':+tagclose:+'>';
   }

   typeless standalone_val = _html_get_attr_val(endtag,'standalone');
   if (standalone_val) {
      set_surround_mode_start_line();
      int indent = _html_get_attr_val(endtag,'indent_content');
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
   typeless p;
   _save_pos2(p);     //Save the current cursor position
   _str tagname = end_tag;
   typeless standalone_val = _html_get_attr_val(end_tag, 'standalone');
   typeless begin_val = _html_get_attr_val(end_tag, 'noflines_before');
   typeless after_val = _html_get_attr_val(end_tag, 'noflines_after');
   _insert_text(end_tag);   //Insert the end tag
   _restore_pos2(p);
}

/**
 * Inserts the closing HTML tag for block tags.
 *
 * @param begin_tag
 * @param end_tag
 * @param indent
 */
static void insert_block_close_tags(_str begin_tag,_str end_tag, _str indent = '0')
{
   _str prefix = "";
   if (_inJavadoc()) prefix='* ';
   int orig_col=p_col;
   if (_expand_tabsc(1,p_col-1)!="") {
      first_non_blank();
   }
   int indent_col=p_col;
   p_col=orig_col;
   _str textAfterCursor=_expand_tabsc(p_col,-1,'S');
   if (textAfterCursor!="") {
      _delete_text(-1);
      insert_line(indent_string(indent_col-1):+prefix:+textAfterCursor);
      up();
   }
   first_non_blank();
   if (LanguageSettings.getInsertRealIndent(p_LangId)) {
      if (indent) {
         insert_line(indent_string(indent_col + p_SyntaxIndent - 1) :+ prefix);
      } else {
         insert_line(indent_string(indent_col-1) :+ prefix);
      }
   } else {
      insert_line(indent_string(indent_col-1) :+ prefix);
   }
   if (end_tag!='') {
      insert_line(indent_string(indent_col-1) :+ prefix :+ end_tag);
      up();
   }
   p_col=indent_col+length(prefix);
   if (indent) {
      p_col=p_col+p_SyntaxIndent;
   }
}

/**
 * Catches the cancel event/button from the html options
 * dialog and undoes any changes that were made.
 */
void ctl_cancel_button.lbutton_up()
{
   undo_html_changes();
   p_active_form._delete_window('');
}

/**
 * Catches the OK button press from the html options dialog
 * and saves any changes that were made.
 */
void ctl_ok_button.lbutton_up()
{
   save_html_changes();
   // set the auto insert '>' option if the value changed
   p_active_form._delete_window('');
}

/**
 * Removes the selected tag from the config file on disk and from memory.
 */
void ctl_remtag_button.lbutton_up()
{
   if( !ctl_taglist.p_Nofselected ) {
      return;
   }
   _str tagname=ctl_taglist._lbget_seltext();
   if( tagname!="" ) {
      int result=_message_box('Remove tag 'tagname'?','', MB_YESNO|MB_ICONQUESTION);
      if (result!=IDYES) return;
      typeless i;
      for( i._makeempty();; ) {
         tag_info:[tagname]._nextel(i);
         if( i._isempty() ) break;
         _ini_delete_value(FormatUserIniFilename(),"html-scheme-"HF_DEFAULT_SCHEME_NAME,'tag*'tagname'*'i);
      }
      tag_info._deleteel(tagname);
      ctl_taglist._lbdelete_item();
      ctl_taglist._lbselect_line();
      ctl_taglist.call_event(CHANGE_SELECTED,ctl_taglist,ON_CHANGE,'W');
   }
   return;
}

/**
 * Adds a given tag to uformat.ini and loads it into memory
 * for use with html syntax expansion.
 */
void ctl_addtag_button.lbutton_up()
{
   _str tags:[];
   typeless status=show("-modal _textbox_form","Add Tag",0,"","Type in the name of the tag you want to add without <>","","","Tag");
   if( status=="" ) {
      // User probably cancelled
      return;
   }
   typeless tagname=_param1;
   if( tagname=="" ) {
      return;
   }
   tagname=strip(tagname,'L','<');
   tagname=strip(tagname,'T','>');
   //tagname=case_html_tag(tagname);
   tagname=upcase(tagname);

   if( tag_info._indexin(tagname) ) {
      _str msg='Tag "':+tagname:+'" already exists.';
      status=_message_box(msg,"",MB_OK);
      return;
   }
   tag_info:[tagname]:["reformat_content"]=true;
   tag_info:[tagname]:["indent_content"]=false;
   tag_info:[tagname]:["literal_content"]=false;
   tag_info:[tagname]:["preserve_body"]=false;
   tag_info:[tagname]:["preserve_position"]=false;
   tag_info:[tagname]:["standalone"]=true;
   tag_info:[tagname]:["noflines_before"]=1;
   tag_info:[tagname]:["noflines_after"]=1;
   tag_info:[tagname]:["endtag"]=true;
   tag_info:[tagname]:["eo_insert_endtag"]=true;

   changed_tags:[tagname]:['reformat_content'] = 1;
   changed_tags:[tagname]:['indent_content'] = 1;
   changed_tags:[tagname]:['literal_content'] = 1;
   changed_tags:[tagname]:['preserve_body'] = 1;
   changed_tags:[tagname]:['preserve_position'] = 1;
   changed_tags:[tagname]:['standalone'] = 1;
   changed_tags:[tagname]:['noflines_before'] = 1;
   changed_tags:[tagname]:['noflines_after'] = 1;
   changed_tags:[tagname]:['endtag'] = 1;
   changed_tags:[tagname]:['eo_insert_endtag'] = 1;

   ctl_taglist._lbadd_item(tagname);
   ctl_taglist._lbtop();
   ctl_taglist._lbsort('I');
   ctl_taglist._lbsearch(tagname,'e');
   ctl_taglist._lbselect_line();
   ctl_taglist.call_event(CHANGE_SELECTED,ctl_taglist,ON_CHANGE,'W');
   return;
}

/**
 * Gets the currently selected item from the listbox and
 * verifies that the html tag information is available.
 *
 * @return
 */
static _str get_cur_item()
{
   typeless item="", indent=0, picture_index=0;
   ctl_taglist._lbget_item(item, indent, picture_index);
   if (!_html_tags_loaded()) {
      ctl_endtag_check.p_enabled = false;
      ctl_autoinsert_check.p_enabled = false;
      ctl_indent_check.p_enabled = false;
      ctl_inline_radio.p_enabled = false;
      ctl_block_radio.p_enabled = false;
      return('');
   }
   return(item);
}

/**
 * Throws away any changes made on the html options dialog and reloads the table.
 */
static void undo_html_changes()
{
   changed_tags._makeempty();
   tag_info._makeempty();
   boolean status = _html_tags_loaded();
}

/**
 * Saves any changes made in the html dialog out to uformat.ini.
 */
static void save_html_changes()
{
   if (changed_tags._isempty()) {
      // nothing changed, so there is nothing to update
      return;
   }
   int temp_view_id=0;
   typeless status = _ini_get_section(FormatUserIniFilename(),"html-scheme-"HF_DEFAULT_SCHEME_NAME,temp_view_id);
   if (status) {
      // getting the section failed, could not save changes to disk
      message('Could not save configuration changes!');
      return;
   }
   int orig_view_id = p_window_id;
   p_window_id = temp_view_id;
   top();
   _begin_line();
   typeless p;
   _save_pos2(p);
   typeless i,j;
   for( i._makeempty();; ) {
      changed_tags._nextel(i);
      if( i._isempty() ) break;
      for( j._makeempty();; ) {
         changed_tags:[i]._nextel(j);
         if( j._isempty() ) break;
         status = search('^tag\*'i'\*'j,'+<R@hI');
         if (status != 0) {
            // search failed, need to add the value
            insert_line('tag*'i'*'j'='tag_info:[i]:[j]);
         } else {
            replace_line('tag*'i'*'j'='tag_info:[i]:[j]);
         }
         _restore_pos2(p);
      }
   }
   // sorts the section
   status = sort_buffer();
   p_window_id = orig_view_id;
   // replaces the section in uformat.ini
   _ini_put_section(FormatUserIniFilename(),"html-scheme-"HF_DEFAULT_SCHEME_NAME,temp_view_id);
   // flush the list of dirty tags
   changed_tags._makeempty();
}

/**
 * The state of the end tag check box was changed.  This
 * code enables and disables various buttons on the html
 * options dialog and loads the changes into memory.  The
 * "change" flag is also set for the given tag so that the
 * changes can be potentially written to disk later.
 */
void ctl_endtag_check.lbutton_up()
{
   typeless item = get_cur_item();
   if (item == '') {
      return;
   }
   if (ctl_endtag_check.p_value) {
      ctl_autoinsert_check.p_enabled = true;
      if (ctl_autoinsert_check.p_value) {
         ctl_inline_radio.p_enabled = true;
         ctl_block_radio.p_enabled = true;
         if (ctl_block_radio.p_value) {
            ctl_indent_check.p_enabled = true;
         } else {
            ctl_indent_check.p_enabled = false;
         }
      } else {
         ctl_inline_radio.p_enabled = false;
         ctl_block_radio.p_enabled = false;
         ctl_indent_check.p_enabled = false;
      }
   } else {
      ctl_autoinsert_check.p_enabled = true;
      ctl_indent_check.p_enabled = false;
      ctl_inline_radio.p_enabled = false;
      ctl_block_radio.p_enabled = false;
   }
   tag_info:[item]:['endtag'] = ctl_endtag_check.p_value;
   changed_tags:[item]:['endtag'] = 1;
}

/**
 * The state of the insert end tag automatically check box
 * was changed.  This code enables and disables various
 * buttons on the html options dialog and loads the changes
 * into memory.  The "change" flag is also set for the given
 * tag so that the changes can be potentially written to
 * disk later.
 */
void ctl_autoinsert_check.lbutton_up()
{
   typeless item = get_cur_item();
   if (item == '') {
      return;
   }
   if (ctl_autoinsert_check.p_value) {
      ctl_inline_radio.p_enabled = true;
      ctl_block_radio.p_enabled = true;
      if (ctl_block_radio.p_value) {
         ctl_indent_check.p_enabled = true;
      }
   } else {
      ctl_indent_check.p_enabled = false;
      ctl_inline_radio.p_enabled = false;
      ctl_block_radio.p_enabled = false;
   }
   tag_info:[item]:['eo_insert_endtag'] = ctl_autoinsert_check.p_value;
   changed_tags:[item]:['eo_insert_endtag'] = 1;
}

/**
 * The indent content check box was changed. This loads
 * the change into memory and sets the "change" flag for
 * the given tag so that the change can be potentially
 * written to disk later.
 */
void ctl_indent_check.lbutton_up()
{
   typeless item = get_cur_item();
   if (item == '') {
      return;
   }
   tag_info:[item]:['indent_content'] = ctl_indent_check.p_value;
   changed_tags:[item]:['indent_content'] = 1;
}

/**
 * The inline radio button was changed. This loads
 * the change into memory and sets the "change" flag for
 * the given tag so that the change can be potentially
 * written to disk later.
 */
void ctl_inline_radio.lbutton_up()
{
   if (change_radio) {
      return;
   }
   ctl_indent_check.p_enabled = false;
   typeless item = get_cur_item();
   if (item == '') {
      return;
   }
   tag_info:[item]:['standalone'] = ctl_block_radio.p_value;
   changed_tags:[item]:['standalone'] = 1;
}

/**
 * The block radio button was changed. This loads
 * the change into memory and sets the "change" flag for
 * the given tag so that the change can be potentially
 * written to disk later.
 */
void ctl_block_radio.lbutton_up()
{
   if (change_radio) {
      return;
   }
   ctl_indent_check.p_enabled = false;
   typeless item = get_cur_item();
   if (item == '') {
      return;
   }
   ctl_indent_check.p_enabled = true;
   tag_info:[item]:['standalone'] = ctl_block_radio.p_value;
   changed_tags:[item]:['standalone'] = 1;
}

/**
 * Catches the on change event from the listbox
 * and adjusts the values of the radio buttons
 * and check boxes according to the new current line.
 */
void ctl_taglist.on_change(int reason)
{
   typeless item = get_cur_item();
   if (item == '') {
      return;
   }
   ctl_autoinsert_check.p_enabled = true;
   typeless eo_insert_endtag = _html_get_attr_val(item, 'eo_insert_endtag');
   typeless standalone = _html_get_attr_val(item, 'standalone');
   typeless indent_content = _html_get_attr_val(item, 'indent_content');
   ctl_autoinsert_check.p_enabled = true;
   ctl_inline_radio.p_enabled = true;
   ctl_block_radio.p_enabled = true;
   ctl_indent_check.p_enabled = true;
   ctl_autoinsert_check.p_value = eo_insert_endtag;
   change_radio = true;
   if (standalone) {
      ctl_block_radio.p_value = 1;
   } else {
      ctl_inline_radio.p_value = 1;
   }
   change_radio = false;
   ctl_indent_check.p_value = indent_content;
   if (eo_insert_endtag) {
      if (standalone) {
      } else {
         ctl_indent_check.p_enabled = false;
      }
   } else {
      ctl_inline_radio.p_enabled = false;
      ctl_block_radio.p_enabled = false;
      ctl_indent_check.p_enabled = false;
   }
}

/**
 * The on create event for the list box on the html options
 * dialog.  Makes sure the tags database is loaded, and
 * populates the list box with all available tags.
 */
void ctl_taglist.on_create()
{
   changed_tags._makeempty();
   ctl_taglist._lbclear();
   if (!_html_tags_loaded()) {
      ctl_autoinsert_check.p_enabled = true;
      ctl_indent_check.p_enabled = false;
      ctl_inline_radio.p_enabled = false;
      ctl_block_radio.p_enabled = false;
      ctl_endtag_check.p_enabled = false;
      message('Failed to load tag information from disk.');
      return;
   }
   // now populate the list box
   typeless i;
   for( i._makeempty();; ) {
      tag_info._nextel(i);
      if( i._isempty() ) break;
      ctl_taglist._lbadd_item(case_html_tag(i));
   }
   ctl_taglist._lbsort('I');
   ctl_taglist._lbtop();
   ctl_taglist._lbselect_line();
   // send the on_change call back for the list box
   ctl_taglist.call_event(CHANGE_SELECTED,ctl_taglist,ON_CHANGE,'W');
}

defeventtab _html_extform;

#region Options Dialog Helper Functions

void _html_extform_init_for_options(_str langID)
{
   // load our scheme names
   if (_find_control('XW_selectSchemeDB')) {
      _str schemeNames[];
      XW_schemeNamesM(schemeNames);
      XW_selectSchemeDB._lbclear();
      for (i := 0; i < schemeNames._length(); i++) {
         XW_selectSchemeDB._lbadd_item(schemeNames[i]);
      }
   }

   if (langID == 'xml' || langID == 'xhtml' || langID == 'docbook' || langID == 'xsd' || langID == 'vpj') {
      ctlframe1.p_visible = ctlframe2.p_visible = ctlframe4.p_visible =
         ctlframe3.p_visible = ctlaspdialect.p_visible = false;
      html_file_path.p_visible = false;
      html_filename.p_visible = false;
      html_color_name.p_visible = false;
      html_align_tabs.p_visible = false;
      num_quotes.p_visible = false;
      sword_quotes.p_visible = false;
   } else if (langID == 'cfml') {
      ctl_XW_autoSymbolTrans_check.p_visible = false;
      ctl_XW_autoSymbolTrans_button.p_visible = false;
      ctl_xml_validate_on_open.p_visible = false;
   } else if (langID == 'tld') {
      ctlframe3.p_visible = false;
      ctlaspdialect.p_visible = false;
      html_file_path.p_visible = false;
      html_filename.p_visible = false;
      html_color_name.p_visible = false;
      html_align_tabs.p_visible = false;
      ctl_XW_autoSymbolTrans_check.p_visible = false;
      ctl_XW_autoSymbolTrans_button.p_visible = false;
      ctlframe5.p_visible = false;
      ctl_xml_validate_on_open.p_visible = false;
   } else {
      ctl_xml_validate_on_open.p_visible = false;
   }
   _html_extform_shift_controls();

   // adaptive formatting stuff
   setAdaptiveLinks(langID);

   _language_form_init_for_options(langID, _html_extform_get_value, 
                                   _language_formatting_form_is_lang_included);

   if (_find_control('ctl_XW_autoSymbolTrans_check')) {
      call_event(ctl_XW_autoSymbolTrans_check.p_window_id, LBUTTON_UP);
   }
}

static void _html_extform_shift_controls()
{
   // left column
   shift := 0;

   // tags
   if (!ctlframe1.p_visible) {
      shift += ctlframe2.p_y - ctlframe1.p_y;
   }

   // attributes
   if (!ctlframe2.p_visible) {
      shift += ctlframe4.p_y - ctlframe2.p_y;
   } else {
      ctlframe2.p_y -= shift;
   }

   // single word values
   if (!ctlframe4.p_visible) {
      shift += ctlframe3.p_y - ctlframe4.p_y;
   } else {
      ctlframe4.p_y -= shift;
   }

   // hex values
   if (!ctlframe3.p_visible) {
      shift += ctlframe5.p_y - ctlframe3.p_y;
   } else {
      ctlframe3.p_y -= shift;
   }

   // auto formatting options
   ctlframe5.p_y -= shift;

   // right column
   shift = 0;

   // embedded asp dialect
   if (!ctlaspdialect.p_visible) {
      shift = html_file_path.p_y - ctlaspdialect.p_y;
   }

   // use paths for file entries
   if (!html_file_path.p_visible) {
      shift += html_filename.p_y - html_file_path.p_y;
   } else {
      html_file_path.p_y -= shift;
   }

   // use lower case filename when inserting links
   if (!html_filename.p_visible) {
      shift += num_quotes.p_y - html_filename.p_y;
   } else {
      html_filename.p_y -= shift;
   }

   // use quotes for numerical
   if (!num_quotes.p_visible) {
      shift += sword_quotes.p_y - num_quotes.p_y;
   } else {
      num_quotes.p_y -= shift;
   }

   // use quotes for single word
   if (!sword_quotes.p_visible) {
      shift += html_color_name.p_y - sword_quotes.p_y;
   } else {
      sword_quotes.p_y -= shift;
   }

   // insert colors using color names
   if (!html_color_name.p_visible) {
      shift += html_align_tabs.p_y - html_color_name.p_y;
   } else {
      html_color_name.p_y -= shift;
   }

   // use <div> tags
   if (!html_align_tabs.p_visible) {
      shift += ctl_xml_validate_on_open.p_y - html_align_tabs.p_y;
   } else {
      html_align_tabs.p_y -= shift;
   }

   // auto validate on open
   if (!ctl_xml_validate_on_open.p_visible) {
      shift += ctl_XW_autoSymbolTrans_check.p_y - ctl_xml_validate_on_open.p_y;
   } else {
      ctl_xml_validate_on_open.p_y -= shift;
   }

   // auto symbol translation (check and button)
   if (!ctl_XW_autoSymbolTrans_check.p_visible) {
      shift += ctlframe5.p_y - ctl_XW_autoSymbolTrans_check.p_y;
   } else {
      ctl_XW_autoSymbolTrans_button.p_y -= shift;
      ctl_XW_autoSymbolTrans_check.p_y -= shift;
   }

}

_str _html_extform_get_value(_str controlName, _str langId)
{
   _str value = null;

   switch (controlName) {
   case 'ctlvbscript':
   case 'ctljscript':
   case 'ctlvisualbasic':
   case 'ctlcsharp':
   case 'ctljava':
   case 'ctlperl':
   case 'ctlpython':
   case 'ctlruby':
      index := find_index(VSHTML_ASP_LEXER_NAME,MISC_TYPE);
      if (!index) {
         index = insert_name(VSHTML_ASP_LEXER_NAME,MISC_TYPE, "VBScript");
      }
      switch (name_info(index)) {
      case "JScript":
      case "JavaScript":
         value = 'ctljscript';
         break;
      case "VB":
      case "Visual Basic":
         value = 'ctlvisualbasic';
         break;
      case "C#":
      case "CSharp":
         value = 'ctlcsharp';
         break;
      case "Ruby":
         value = 'ctlruby';
         break;
      case "Perl":
         value = 'ctlperl';
         break;
      case "Python":
         value = 'ctlpython';
         break;
      case "J#":
      case "Java":
         value = 'ctljava';
         break;
      case "VBScript":
      default: // "VBScript":
         value = 'ctlvbscript';
         break;
      }
      break;
   case 'html_file_path':
      value = (int)LanguageSettings.getUsePathsForFileEntries(langId);
      break;
   case 'html_filename':
      value = (int)LanguageSettings.getLowercaseFilenamesWhenInsertingLinks(langId);
      break;
   case 'num_quotes':
      value = (int)LanguageSettings.getQuotesForNumericValues(langId);
      break;
   case 'sword_quotes':
      value = (int)LanguageSettings.getQuotesForSingleWordValues(langId);
      break;
   case 'html_color_name':
      value = (int)LanguageSettings.getUseColorNames(langId);
      break;
   case 'html_align_tabs':
      value = (int)LanguageSettings.getUseDivTagsForAlignment(langId);
      break;
   case 'ctl_xml_validate_on_open':
      value = (int)LanguageSettings.getAutoValidateOnOpen(langId);
      break;
   case 'ctl_autoCorrelateStartEnd':
      value = (int)LanguageSettings.getAutoCorrelateStartEndTags(langId);
      break;
   default:
      value = _language_formatting_form_get_value(controlName, langId);
      break;
   }
   
   return value;
}

boolean _html_extform_apply()
{
   _language_form_apply(_html_extform_apply_control);

   return true;
}

_str _html_extform_apply_control(_str controlName, _str langId, _str value)
{
   updateString := '';

   switch (controlName) {
   case 'ctlvbscript':
      setHtmlEmbeddedAspLexer('VBScript');
      break;
   case 'ctljscript':
      setHtmlEmbeddedAspLexer('JScript');
      break;
   case 'ctlvisualbasic':
      setHtmlEmbeddedAspLexer('Visual Basic');
      break;
   case 'ctlcsharp':
      setHtmlEmbeddedAspLexer('CSharp');
      break;
   case 'ctljava':
      setHtmlEmbeddedAspLexer('Java');
      break;
   case 'ctlruby':
      setHtmlEmbeddedAspLexer('Ruby');
      break;
   case 'ctlperl':
      setHtmlEmbeddedAspLexer('Perl');
      break;
   case 'ctlpython':
      setHtmlEmbeddedAspLexer('Python');
      break;
   case 'html_file_path':
      LanguageSettings.setUsePathsForFileEntries(langId, (int)value != 0);
      break;
   case 'html_filename':
      LanguageSettings.setLowercaseFilenamesWhenInsertingLinks(langId, (int)value != 0);
      break;
   case 'num_quotes':
      LanguageSettings.setQuotesForNumericValues(langId, (int)value != 0);
      set_html_scheme_value('quote_numval', (int)value, true);
      break;
   case 'sword_quotes':
      LanguageSettings.setQuotesForSingleWordValues(langId, (int)value != 0);
      set_html_scheme_value('quote_wordval', (int)value, true);
      break;
   case 'html_color_name':
      LanguageSettings.setUseColorNames(langId, (int)value != 0);
      break;
   case 'html_align_tabs':
      LanguageSettings.setUseDivTagsForAlignment(langId, (int)value != 0);
      break;
   case 'ctl_xml_validate_on_open':
      LanguageSettings.setAutoValidateOnOpen(langId, (int)value != 0);
      break;
   case 'ctl_autoCorrelateStartEnd':
      LanguageSettings.setAutoCorrelateStartEndTags(langId, (int)value != 0);
      break;
   default:
      updateString = _language_formatting_form_apply_control(controlName, langId, value);
      break;
   }

   return updateString;
}

static void setHtmlEmbeddedAspLexer(_str lexer)
{
   index := find_index(VSHTML_ASP_LEXER_NAME, MISC_TYPE);
   if (index) {
      if (name_info(index) :!= lexer) {
         set_name_info(index, lexer);
      }
   } else {
      index = insert_name(VSHTML_ASP_LEXER_NAME, MISC_TYPE, lexer);
   }
}

#endregion Options Dialog Helper Functions

_html_extform.on_destroy()
{
   _language_form_on_destroy();
}

void ctl_XW_autoSymbolTrans_button.lbutton_up()
{
   autoSymbolTransEditor(_get_language_form_lang_id());
}

void ctl_XW_autoSymbolTrans_check.lbutton_up()
{
   ctl_XW_autoSymbolTrans_button.p_enabled = (ctl_XW_autoSymbolTrans_check.p_value == 1 ? true : false);
}

_command void ast(_str lang = p_LangId) name_info(',')
{
   autoSymbolTransEditor(lang);
}

/*End HTML Options Form*/

defeventtab html_keys;
def  ' '= html_space;
def  '%'= auto_codehelp_key;
def  '&'= auto_codehelp_key;
def  '('= auto_functionhelp_key;
def  '*'= html_key;
def  '.'= auto_codehelp_key;
def  '/'= auto_codehelp_key;
def  ':'= html_key;
def  '<'= html_lt;
def  '='= auto_codehelp_key;
def  '>'= html_gt;
def  '['= html_lt;
def  ']'= html_gt;
def  '{'= html_key;
def  '}'= html_key;
def  'ENTER'= html_enter;
def  'TAB'= html_tab;

static _str gtkinfo;
static _str gtk;

static _str html_next_sym()
{
   if (p_col>_text_colc()) {
      if(down()) {
         gtk=gtkinfo='';
         return('');
      }
      _begin_line();
   }
   typeless status=0;
   _str ch=get_text_safe();
   //say("html_next_sym: ch="ch);
   if (ch=='' || 
       (ch=='<' && _clex_find(0,'g')==CFG_COMMENT && !_inJavadoc()) ||
       (ch=='[' && _clex_find(0,'g')==CFG_COMMENT && _LanguageInheritsFrom('bbc'))) {
      status=_clex_skip_blanks('ch');
      if (status) {
         gtk=gtkinfo='';
         return(gtk);
      }
      return(html_next_sym());
   }
   int start_col=0;
   int start_line=0;
   if ((ch=='"' || ch=="'" ) && _clex_find(0,'g')==CFG_STRING) {
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
   if (ch=='<' && get_text_safe()=='/') {
      right();
      gtk=gtkinfo='</';
      return(gtk);

   }
   if (_LanguageInheritsFrom('bbc') && ch=='[' && get_text_safe()=='/') {
      right();
      gtk=gtkinfo='[/';
      return(gtk);

   }
   gtk=gtkinfo=ch;
   return(gtk);

}
static _str html_prev_sym()
{
   _str ch=get_text_safe();
   //say("html_prev_sym: ch="ch);
   while (ch==' ' && _inJavadoc() && p_col > 1) {
      left();
      return html_prev_sym();
   }
   typeless status=0;
   if (ch=="\n" || ch=="\r" || ch=='' || 
       (ch=='>' && _clex_find(0,'g')==CFG_COMMENT && !_inJavadoc() ) ||
       (ch==']' && _clex_find(0,'g')==CFG_COMMENT && _LanguageInheritsFrom('bbc'))) {
      status=_clex_skip_blanks('-h');
      if (status) {
         gtk=gtkinfo='';
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
   if ((ch=='"' || ch=="'" ) && _inJavadoc() && p_col > 1) {
      end_col=p_col;
      save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
      left();
      status = search(ch, '-<@hCc');
      if (status || p_col==1) {
         gtk=gtkinfo='';
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
   if (get_text_safe(2,(int)_QROffset()-1)=='<%') {
      left();left();
      gtk=gtkinfo='<%';
      return(gtk);
   }
   // Bulletin Board Code tags use brackets
   if (ch=='<' || ch=='&' || ch=='%' || 
       (ch=='[' && _LanguageInheritsFrom('bbc'))) {
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
   if (ch=='/' && get_text_safe()=='<') {
      left();
      gtk=gtkinfo='</';
      return(gtk);
   }
   // Bulletin Board Code tags use brackets
   if (ch=='/' && get_text_safe()=='[' && _LanguageInheritsFrom('bbc')) {
      left();
      gtk=gtkinfo='[/';
      return(gtk);
   }

   gtk=gtkinfo=ch;
   return(gtk);

}
static int html_before_id(_str &prefixexp,int &prefixexpstart_offset,
                          _str &lastid,int &info_flags)
{
   int count=0;
   _str tag_name='';
   for (;;) {
      switch (gtk) {
      case '=':
      case TK_ID:
      case TK_STRING:
      case TK_NUMBER:
         if (gtk=='=') {
            gtk=html_prev_sym();
            if (gtk==TK_ID) {
               prefixexp=gtkinfo'=';
            }
         }
         while (count++ < 100) {
            if (gtk==TK_ID) {
               tag_name=gtkinfo;
            } else if (gtk=='</' || gtk=='>') {
               // we are lost here
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            } else if (gtk=='[/' || gtk==']' && _LanguageInheritsFrom('bbc')) {
               // we are lost here
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            } else if (gtk=='<' || gtk=='[') {
               if (gtk=='[' && !_LanguageInheritsFrom('bbc')) {
                  return(VSCODEHELPRC_CONTEXT_NOT_VALID);
               }
               if (isdigit(first_char(tag_name))) {
                  return(VSCODEHELPRC_CONTEXT_NOT_VALID);
               }
               prefixexpstart_offset=(int)point('s');
               prefixexp='<'tag_name' 'prefixexp;
               return(0);
            } else if (gtk=='@') {
               prefixexp='@ 'prefixexp;
               // keep searching
            } else if (gtk=='<%') {
               prefixexpstart_offset=(int)point('s')+1;
               prefixexp='<%'prefixexp;
               return(0);
            }
            gtk=html_prev_sym();
         }
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      case '@':
         gtk=html_prev_sym();
         if (gtk=='<%') {
            prefixexpstart_offset=(int)point('s')+1;
            prefixexp='<%@ ';
            return(0);
         }
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      case '%':
      case '&':
      case '<':
      case '</':
      case '[':
      case '[/':
         prefixexpstart_offset=(int)point('s')+1;
         prefixexp=gtkinfo;
         ch := get_text_safe(1,_nrseek()+1);
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
int _dtd_get_expression_info(boolean PossibleOperator,VS_TAG_IDEXP_INFO &idexp_info,
                             VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   //p_word_chars=p_word_chars:+'%;';
   int status=_html_get_expression_info(PossibleOperator,idexp_info,visited,depth);
   //p_word_chars=substr(p_word_chars,1,length(p_word_chars)-2);
   return(status);
}

_str bbc_proc_search(_str &proc_name,int find_first)
{
   return STRING_NOT_FOUND_RC;
}
int _bbc_get_expression_info(boolean PossibleOperator, VS_TAG_IDEXP_INFO &idexp_info,
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
int _html_get_expression_info(boolean PossibleOperator, VS_TAG_IDEXP_INFO &idexp_info,
                              VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
//   say("_html_get_expression_info: ");
   tag_idexp_info_init(idexp_info);
   idexp_info.errorArgs._makeempty();
   idexp_info.otherinfo="";
   boolean done=false;
   int status=0;
   idexp_info.info_flags=VSAUTOCODEINFO_DO_LIST_MEMBERS;
   typeless orig_pos;
   save_pos(orig_pos);
   word_chars := _clex_identifier_chars();
   VS_TAG_IDEXP_INFO orig_idexp_info = idexp_info;
   if (PossibleOperator) {
      left();
      _str ch=get_text_safe();
      switch (ch) {
      case '[':
         if (_LanguageInheritsFrom('bbc')) {
            idexp_info.lastid='';
            idexp_info.lastidstart_col=p_col+1;
            idexp_info.lastidstart_offset=(int)point('s')+1;
            idexp_info.prefixexpstart_offset=(int)point('s');
            idexp_info.prefixexp=ch;
            done=true;
            break;
         }
         restore_pos(orig_pos);
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      case '<':
      case '&':
      case '%':
         idexp_info.lastid='';
         idexp_info.lastidstart_col=p_col+1;
         idexp_info.lastidstart_offset=(int)point('s')+1;
         idexp_info.prefixexpstart_offset=(int)point('s');
         idexp_info.prefixexp=ch;
         done=true;
         break;
      case '/':
         left();
         ch=get_text_safe();
         if (ch=='<') {
            idexp_info.lastid='';
            idexp_info.lastidstart_col=p_col+2;
            idexp_info.lastidstart_offset=(int)point('s')+2;
            idexp_info.prefixexpstart_offset=(int)point('s');
            idexp_info.prefixexp='</';
            done=true;
            break;
         }
         restore_pos(orig_pos);
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      case '=':
         idexp_info.lastid='';
         idexp_info.lastidstart_col=p_col+1;
         idexp_info.lastidstart_offset=(int)point('s')+1;
         gtk=html_prev_sym();
         status=html_before_id(idexp_info.prefixexp,idexp_info.prefixexpstart_offset,idexp_info.lastid,idexp_info.info_flags);
         done=true;
         break;
      case '@':
         gtk=html_prev_sym();
         if (gtk=='<%') {
            idexp_info.prefixexp='<%@ ';
            done=true;
            break;
         }
         restore_pos(orig_pos);
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      case ' ':
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
         if (_expand_tabsc(1,p_col-1)=='' &&
             !_clex_InComment(flags)   // Here we are taking advantion of the fact that this function
                                       // indicates we are in a comment when we are just inside a tag and
                                       // its attributes.
             ) {
            restore_pos(orig_pos);
            return(VSCODEHELPRC_CONTEXT_NOT_VALID);
         }
         // Clark.  ******END SPEED UP CODE****************
         idexp_info.lastid='';
         idexp_info.lastidstart_col=p_col+1;
         idexp_info.lastidstart_offset=(int)point('s')+1;
         gtk=html_prev_sym();
         //say("_html_get_expression_info: gtk="gtk" gtkinfo="gtkinfo);
         status=html_before_id(idexp_info.prefixexp,idexp_info.prefixexpstart_offset,idexp_info.lastid,idexp_info.info_flags);
         done=true;
         break;
      default:
         restore_pos(orig_pos);
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      }
      if (done) {
         restore_pos(orig_pos);
         ch=get_text_safe();
         if (ch!=' ' && pos('['word_chars']',ch,1,'r') &&
             !_TruncSearchLine('[~'word_chars']|$','r')) {
            int end_col=p_col;
            restore_pos(orig_pos);
            idexp_info.lastid=_expand_tabsc(p_col,end_col-p_col);
         }
         return(status);
      }
   } else {
      // check color coding to see that we are not in a comment
      int cfg=_clex_find(0,'g');
      if (cfg==CFG_COMMENT) {
         //return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      }
      // check if we are in a string or number
      if (cfg==CFG_STRING || cfg==CFG_NUMBER) {
         int orig_cfg=cfg;
         left();cfg=_clex_find(0,'g');
         _str ch=get_text_safe();right();
         if (cfg==CFG_STRING || cfg==CFG_NUMBER) {
            int orig_col=p_col;
            int orig_line=p_line;
            int clex_flag=(cfg==CFG_STRING)? STRING_CLEXFLAG:NUMBER_CLEXFLAG;
            int clex_status=_clex_find(clex_flag,'n-');
            if (clex_status) {
               restore_pos(orig_pos);
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            clex_status=_clex_find(clex_flag,'o');
            if (clex_status) {
               restore_pos(orig_pos);
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            int str_offset=0;//(cfg==CFG_STRING)? 1:0;
            int start_col=p_col+str_offset;
            int start_offset=(int)point('s')+str_offset;
            clex_status=_clex_find(clex_flag,'n');
            if (clex_status || p_line > orig_line) {
               restore_pos(orig_pos);
               //say("_html_get_expression_info: 3");
               //return(VSCODEHELPRC_CONTEXT_NOT_VALID);
               _end_line();
            }
            clex_status=_clex_find(clex_flag,'o-');
            if (clex_status) {
               restore_pos(orig_pos);
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            idexp_info.prefixexp='';
            idexp_info.lastidstart_col=start_col;
            idexp_info.lastidstart_offset=start_offset;
            idexp_info.prefixexpstart_offset=idexp_info.lastidstart_offset;
            idexp_info.lastid=_expand_tabsc(start_col,orig_col-start_col);
            p_col=start_col-1;
            if (get_text_safe()=='"' || get_text_safe()=="'") {
               left();
            }
            gtk=html_prev_sym();
            idexp_info.info_flags|=VSAUTOCODEINFO_IN_STRING_OR_NUMBER;
            status=html_before_id(idexp_info.prefixexp,idexp_info.prefixexpstart_offset,idexp_info.lastid,idexp_info.info_flags);
            restore_pos(orig_pos);
            return(status);
         }
      }
      // IF we are not on an id character.
      left();
      _str ch=get_text_safe();
      if (pos('[~'word_chars']',ch,1,'r')) {
         //left();
         ch=get_text_safe();
         prevch:=get_text_safe(1,(int)point('s')-1);
         if (ch=='&' || ch=='%' || ch=='<' || ch=='[' || 
             (ch=='/' && prevch=='<') ||
             (ch=='/' && prevch=='[' && _LanguageInheritsFrom('bbc'))) {
            idexp_info.lastid='';
            idexp_info.lastidstart_col=p_col+1;
            idexp_info.lastidstart_offset=(int)point('s')+1;
            idexp_info.prefixexpstart_offset=(int)point('s');
            right();
            if (!_TruncSearchLine('[~'word_chars']|$','r')) {
               int end_col=p_col;
               restore_pos(orig_pos);
               idexp_info.lastid=_expand_tabsc(p_col,end_col-p_col);
            }
            if (ch=='&') {
               idexp_info.prefixexp='&';
            } else if (ch=='%') {
               idexp_info.prefixexp='%';
            } else if (ch=='<') {
               idexp_info.prefixexp='<';
            } else if (ch=='/' && prevch=='<') {
               idexp_info.prefixexp='</';
               --idexp_info.prefixexpstart_offset;
            } else if (ch=='[') {
               idexp_info.prefixexp='[';
            } else {
               idexp_info.prefixexp='[/';
               --idexp_info.prefixexpstart_offset;
            }
            restore_pos(orig_pos);
            return(0);
         } else if (ch=="'" || ch=='"') {
            cfg=_clex_find(0,'g');
            if (cfg!=CFG_STRING) {
               restore_pos(orig_pos);
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            idexp_info.lastid='';
            idexp_info.lastidstart_col=p_col+1;
            idexp_info.lastidstart_offset=(int)point('s')+1;
            right();
            cfg=_clex_find(0,'g');
            if (cfg!=CFG_STRING) {
               p_col=idexp_info.lastidstart_col-1;
               int clex_status=_clex_find(STRING_CLEXFLAG,'n-');
               if (clex_status) {
                  restore_pos(orig_pos);
                  return(VSCODEHELPRC_CONTEXT_NOT_VALID);
               }
               clex_status=_clex_find(STRING_CLEXFLAG,'o');
               if (clex_status) {
                  restore_pos(orig_pos);
                  return(VSCODEHELPRC_CONTEXT_NOT_VALID);
               }
               right();
               idexp_info.lastid=get_text_safe(idexp_info.lastidstart_col-p_col);
               idexp_info.lastidstart_col=p_col;
               idexp_info.lastidstart_offset=(int)point('s');
            }
         } else if (ch=='@') {
            int lp_offset=1;
            while (get_text_safe(1,(int)point('s')-lp_offset)==' ') ++lp_offset;
            if (get_text_safe(2,(int)point('s')-lp_offset-1)=='<%') {
               idexp_info.lastid='';
               idexp_info.lastidstart_col=p_col+1;
               idexp_info.lastidstart_offset=(int)point('s')+1;
               idexp_info.prefixexp='<%@ ';
               idexp_info.prefixexpstart_offset=(int)point('s')-lp_offset-1;
               restore_pos(orig_pos);
               return(0);
            }
         }
         if (ch=='=' || ch==' ') {
            idexp_info.lastid='';
            idexp_info.lastidstart_col=p_col+1;
            idexp_info.lastidstart_offset=(int)point('s')+1;
            done=true;
         }
      }
      if (!done) {
         // IF we are not on an id character.
         if (pos('[~'word_chars']',get_text_safe(),1,'r')) {
            restore_pos(orig_pos);
            idexp_info.prefixexp='';
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
         int end_col=p_col;
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
   idexp_info.prefixexp='';
   _str ch=get_text_safe();
   if (idexp_info.lastid == "" && (ch == " " || ch == "\t" || ch == "*")) {
      restore_pos(orig_pos);
      if (pos('[~'word_chars']',get_text_safe(),1,'r')) {
         idexp_info.lastidstart_col=p_col;
         idexp_info.lastidstart_offset=(int)point('s');
         idexp_info.prefixexpstart_offset = idexp_info.lastidstart_offset;
         return 0;
      }
   }
   gtk=html_prev_sym();
   status=html_before_id(idexp_info.prefixexp,idexp_info.prefixexpstart_offset,idexp_info.lastid,idexp_info.info_flags);
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
                             boolean is_attrib, 
                             _str clip_prefix, 
                             int start_or_end, 
                             int &num_matches,
                             int max_matches,
                             boolean exact_match,
                             boolean case_sensitive)
{
   //say("_HtmlListKeywords("lastid","lastid_prefix","p_mode_name","keyword_class","keyword_name")");
   // look up the lexer definition for the current mode
   _str lexer_name=p_EmbeddedLexerName;
   if (lexer_name=='') {
      lexer_name=p_lexer_name;
   }
   _str filename=_FindLexerFile(lexer_name);

   // adjust lastid and lastid_prefix for clipping prefix
   if (clip_prefix!='') {
      lastid=clip_prefix:+clip_prefix;
   }

   // create a temporary view and search for the keywords
   int orig_wid=p_window_id;
   int temp_view_id=0;
   if (_ini_get_section(filename,lexer_name,temp_view_id)) {
      return(1);
   }
   int orig_view_id=p_window_id;
   p_window_id=temp_view_id;
   top();up();
   if (keyword_name!='') {
      keyword_name=keyword_name' ';
   }
   while (!search('^'keyword_class' @= @'_escape_re_chars(keyword_name),'@rih>')) {
      _str line="";
      get_line(line);
      _end_line();
      //say("_CodeHelpListKeywords(): line="line);
      parse line with . '=' line;
      if (keyword_name!='') {
         parse line with . line;
      }
      for (;;) {
         _str cur=parse_file(line,true,true);
         //parse line with cur line;
         if (cur=='') break;
         orig_wid._html_insert_context_tag_item(cur,
                                                lastid, is_attrib,
                                                clip_prefix, start_or_end,
                                                num_matches, max_matches,
                                                exact_match, case_sensitive);
      }
   }
   // restore the original view
   _delete_temp_view(temp_view_id);
   p_window_id=orig_view_id;
   p_window_id=orig_wid;
   return(0);
}
void _html_insert_context_tag_item(_str cur, _str lastid,
                                   boolean is_attrib,
                                   _str clip_prefix, 
                                   int start_or_end, 
                                   int &num_matches, int max_matches,
                                   boolean exact_match=false,
                                   boolean case_sensitive=false,
                                   _str tag_file='',
                                   typeless tag_type=VS_TAGTYPE_label,
                                   HTML_INSERT_TAG_ARGS *pargs=null
                                   )
{
//   say("_html_insert_context_tag_item");
   _str file_name='';
   int line_no=0;
   _str class_name='';
   int tag_flags=0;
   _str signature='';
   if (pargs!=null) {
      file_name=pargs->file_name;
      line_no=pargs->line_no;
      class_name=pargs->class_name;
      tag_flags=pargs->tag_flags;
      signature=pargs->signature;
   }

   if (cur:==lastid || (!case_sensitive && strieq(cur,lastid))) {
      if (clip_prefix=='&') {
         // do not change case of entities
      } else if (substr(cur,1,1)=='/') {
         if (start_or_end > 0) {
            return;
         }
         cur = '/'case_html_tag(substr(cur,2),is_attrib);
      } else {
         if (start_or_end < 0) {
            return;
         }
         cur = case_html_tag(cur,is_attrib);
      }
      if (clip_prefix!='' && pos(clip_prefix,cur)==1) {
         cur=substr(cur,length(clip_prefix)+1);
      }
      tag_insert_match(tag_file,cur,tag_type,file_name,line_no,class_name,tag_flags,signature);
      num_matches++;
   }
}
static void _html_insert_context_tag_array(_str (&list)[],
                                           _str lastid,
                                           boolean is_attrib,
                                           _str clip_prefix, 
                                           int start_or_end,
                                           int &num_matches,
                                           int max_matches,
                                           boolean exact_match,
                                           boolean case_sensitive)
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
   'ANY','EMPTY','()','(#PCDATA)','(#PCDATA|)*',
};
static _str dtd_attlist_attr_type_array[]=
{
   'CDATA','()','ID','IDREF','IDREFS','NMTOKEN','NMTOKENS','ENTITY','ENTITIES','NOTATION'
};
static _str dtd_attlist_cdata_options_array[]=
{
   '#REQUIRED','#IMPLIED','#FIXED'
};
static _str dtd_notation_attr_array[]=
{
   'SYSTEM','PUBLIC'
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
                            boolean find_parents,int max_matches,
                            boolean exact_match,boolean case_sensitive,
                            int filter_flags=VS_TAGFILTER_ANYTHING,
                            int context_flags=VS_TAGCONTEXT_ALLOW_locals,
                            VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   // handle javadoc tag handling case
   //say("_html_find_context_tags: prefixexp="prefixexp" lastid="lastid);
   errorArgs._makeempty();
   lang := p_LangId;

   // switch language mode to HTML or XMLDOC depending on mode
   if (!_LanguageInheritsFrom("html") && 
       !_LanguageInheritsFrom("xmldoc") && 
       !_LanguageInheritsFrom("xml") &&
       (_clex_find(0, "g") == CFG_COMMENT) && _inDocComment()) {
      lang = _inJavadoc()? "html" : "xmldoc";
   }

   //say('lang='lang);
   int root_count=0;
   _str lastid_prefix=lastid;
   typeless tag_files = tags_filenamea(lang);
   if (_LanguageInheritsFrom("dtd", lang)) {
      tag_files._makeempty();
   }
   // Need this for XML
   _str extra_tag_file=_xml_GetConfigTagFile();
   if (extra_tag_file!='') {
      tag_files[tag_files._length()]=extra_tag_file;
   }

   // Need this for HTML
   _str extra_jsp_tag_file=_jsp_GetConfigTagFile();
   if (extra_jsp_tag_file!='') {
     tag_files[tag_files._length()]=extra_jsp_tag_file;
   }
//   html_add_tld_globals(editorctl_wid, p_window_id, root_root);

   _str tag_name="";
   _str attribute_name="";

   switch (substr(prefixexp,1,1)) {
   case '':
   case ' ':
      // list tags for entities or comments
      break;
   case '&':
      // list entity names
      if (tag_files._length() > 0) {
         tag_list_context_globals(0, 0, lastid,
                                  false, tag_files,
                                  VS_TAGFILTER_CONSTANT,
                                  VS_TAGCONTEXT_ANYTHING,
                                  root_count, max_matches,
                                  exact_match, case_sensitive,
                                  visited, depth);
      } else if (root_count==0) {
         _HtmlListKeywords('cskeywords','',
                           lastid,false,'&',0,
                           root_count,max_matches,
                           exact_match,case_sensitive);
         _HtmlListKeywords('keywords','',
                           lastid,false,'&',0,
                           root_count,max_matches,
                           exact_match,case_sensitive);
      }
      break;
   case '%':
      // list parameter entity names
      if (_LanguageInheritsFrom('dtd')) {

         typeless line_offset="";
         parse point() with line_offset .;
         _str text='';  // text before the cursor
         if (line_offset<lastidstart_offset) {
            text = get_text_safe(lastidstart_offset-line_offset,line_offset);
         }
         parse text with auto w1 auto w2;

         // IF we are not defining an entity
         if ( w1 != '<!ENTITY' ) {
            tag_list_context_globals(0, 0, lastid, 
                                     true, null,
                                     VS_TAGFILTER_DEFINE,
                                     VS_TAGCONTEXT_ANYTHING,
                                     root_count, max_matches,
                                     exact_match, case_sensitive,
                                     visited, depth);
         }
      }
      break;
   case '[':
   case '<':
      if (substr(prefixexp,1,1) == '[') {
         parse prefixexp with '[' prefixexp;
      } else {
         parse prefixexp with '<' prefixexp;
      }
      is_end_tag := false;
      if (substr(prefixexp,1,1)=='/') {
         is_end_tag=true;
         prefixexp=substr(prefixexp,2);
      }
      parse prefixexp with tag_name attribute_name '=';

      // language type determination
      isHTML := (_LanguageInheritsFrom("html") || _LanguageInheritsFrom("xhtml"));
      isXML  := (_LanguageInheritsFrom("xml"));
      isXSD  := (_LanguageInheritsFrom("xsd"));
      isDTD  := (_LanguageInheritsFrom("dtd"));

      if (last_char(prefixexp)=='=') {
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
         } else if (last_char(lastid)=='"') {
            strippedLeadingQuotes=true;
            lastid=strip(lastid,'B','"');
         } else if (last_char(lastid)=='"') {
            strippedLeadingQuotes=true;
            lastid=strip(lastid,'T','"');
         } else if (last_char(lastid)=="'") {
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
            if (attribute_name=='version') {
               _html_insert_context_tag_item( '"1.0"',
                                              lastid, true, '', 0,
                                              root_count, max_matches,
                                              exact_match, case_sensitive);
            } else if (attribute_name=='encoding') {
               _html_insert_context_tag_array( dtd_encodings_array,
                                               lastid, true, '', 0,
                                               root_count, max_matches,
                                               exact_match, case_sensitive);
            }

         } else if (isHTML && lowcase(attribute_name)=='src' && lowcase(tag_name)=='img') {

            // image files for HTML img tag, src attribute
            root_count += insert_files_of_extension(0, 0, 
                                                    p_buf_name,
                                                    ";gif;jpg;jpeg;png;bmp;tiff;pdf;ps;",
                                                    false, extraDir, true,
                                                    extraFile, exact_match);

         } else if (isHTML && (lowcase(attribute_name)=='id' || lowcase(attribute_name)=='class')) {

            // list ids from style sheet
            tag_list_context_globals(0, 0, lastid,
                                     true, null,
                                     VS_TAGFILTER_VAR,
                                     VS_TAGCONTEXT_ALLOW_anonymous,
                                     root_count, max_matches,
                                     exact_match, case_sensitive,
                                     visited, depth);

            VS_TAG_BROWSE_INFO allIDs[];
            tag_get_all_matches(allIDs);
            tag_pop_matches();
            n := allIDs._length();
            return_type := (lowcase(attribute_name)=='id') ? 'css-id' : 'css-class';
            for (i:=0; i<n; ++i) {
               if (allIDs[i].return_type == return_type) {
                  allIDs[i].flags &= ~VS_TAGFLAG_anonymous; // unanonymize tag
                  tag_insert_match_info(allIDs[i]);
               }
            }

         } else if (isHTML && lowcase(substr(attribute_name,1,2))=='on') {

            parse lastid with lastid '(';
            tag_list_context_globals(0, 0, lastid,
                                     true, null,
                                     VS_TAGFILTER_ANYPROC,
                                     VS_TAGCONTEXT_ANYTHING,
                                     root_count, max_matches,
                                     exact_match, case_sensitive,
                                     visited, depth);

         } else if (isHTML && lowcase(attribute_name)=='href' && substr(lastid,1,1)=='#') {

            // list local HREF's
            lastid=substr(lastid,2);
            lastid_prefix=substr(lastid_prefix,2);
            tag_list_context_globals(0, 0, lastid,
                                     true, null,
                                     VS_TAGFILTER_LABEL,
                                     VS_TAGCONTEXT_ANYTHING,
                                     root_count, max_matches,
                                     exact_match, case_sensitive,
                                     visited, depth);

         } else if (isHTML && lowcase(attribute_name)=='href') {

            if (lastid == "") {
               // list local HREF's, with prepended '#'
               tag_push_matches();
               tag_list_context_globals(0, 0, lastid,
                                        true, null,
                                        VS_TAGFILTER_LABEL,
                                        VS_TAGCONTEXT_ANYTHING,
                                        root_count, max_matches,
                                        exact_match, case_sensitive,
                                        visited, depth);

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

         } else if (isXSD && (attribute_name=='type' || attribute_name=='base')) {

            parse lastid with lastid '(';
            tag_list_context_globals(0, 0, lastid,
                                     true, null,
                                     VS_TAGFILTER_ANYSTRUCT,
                                     VS_TAGCONTEXT_ANYTHING,
                                     root_count, max_matches,
                                     exact_match, case_sensitive,
                                     visited, depth);
            tag_list_context_globals(0, 0, lastid,
                                     true, tag_files,
                                     VS_TAGFILTER_PROPERTY,
                                     VS_TAGCONTEXT_ANYTHING,
                                     root_count, max_matches,
                                     exact_match, case_sensitive,
                                     visited, depth);

         } else if (isXSD && (attribute_name=='substitutionGroup' || attribute_name=='ref')) {

            parse lastid with lastid '(';
            tag_list_context_globals(0, 0, lastid,
                                     true, null,
                                     VS_TAGFILTER_MISCELLANEOUS,
                                     VS_TAGCONTEXT_ANYTHING,
                                     root_count, max_matches,
                                     exact_match, case_sensitive,
                                     visited, depth);

         } else if (_LanguageInheritsFrom("xmldoc")) {

            // THIS IS JUST A PLACEHOLDER FOR THE REAL CODE FOR XMLDOC
            // What is supposed to go here???
            parse lastid with lastid '(';
            tag_list_context_globals(0, 0, lastid,
                                     true, null,
                                     VS_TAGFILTER_MISCELLANEOUS,
                                     VS_TAGCONTEXT_ANYTHING,
                                     root_count, max_matches,
                                     exact_match, case_sensitive,
                                     visited, depth);

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
                                     VS_TAGTYPE_var, 0, 0,
                                     root_count, max_matches);

         } else {

            if (tag_files._length() > 0) {
               tag_push_matches();
               int num_matches=0;
               _str return_type='';
               if (tag_list_in_class(attribute_name,tag_name,0,0,tag_files,
                                     num_matches,1,VS_TAGFILTER_VAR,
                                     VS_TAGCONTEXT_ONLY_inclass,
                                     true,false,null,null,visited,depth)) {
                  if (num_matches >= 1) {
                     tag_get_detail2(VS_TAGDETAIL_match_return_only,1,return_type);
                     tag_get_detail2(VS_TAGDETAIL_match_class,1,tag_name);
                  }
               }
               tag_pop_matches();
               tag_list_in_class(lastid_prefix, tag_name':'attribute_name,
                                 0, 0, tag_files,
                                 root_count, max_matches,
                                 VS_TAGFILTER_ENUM,VS_TAGCONTEXT_ONLY_inclass,
                                 exact_match, case_sensitive,
                                 null, null, visited, depth);
               if (root_count==0 && return_type!='') {
                  tag_list_in_class('', return_type,
                                    0, 0, tag_files,
                                    root_count, max_matches,
                                    VS_TAGFILTER_ENUM,VS_TAGCONTEXT_ONLY_inclass,
                                    exact_match, case_sensitive,
                                    null, null, visited, depth);
                  if (p_LangId == 'docbook' && root_count == 0) {
                     _str tempLastid = lastid;
                     int status2 = find_tag_matches(join(tag_files, PATHSEP), lastid);
                     root_count = tag_get_num_of_matches();
                  }
               }
            }
            if (_LanguageInheritsFrom('xml')) {
               _str NamespacesHashtab:[];
               _xml_get_current_namespaces(NamespacesHashtab);
               _xml_insert_namespace_context_tags_attr_values(
                  NamespacesHashtab,
                  0,0,0,
                  lastid,
                  lastid_prefix,
                  tag_name,
                  attribute_name,true,'',root_count,
                  max_matches,
                  0,exact_match,visited
                  );
            }
            if (isHTML && root_count==0) {
               _HtmlListKeywords('attrvalues',
                                 upcase(attribute_name)'('upcase(tag_name)')',
                                 lastid,true,'',0,
                                 root_count,max_matches,
                                 exact_match,case_sensitive);
               if (root_count==0) {
                  _HtmlListKeywords('attrvalues',
                                    upcase(attribute_name),
                                    lastid,true,'',0,
                                    root_count,max_matches,
                                    exact_match, case_sensitive);
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

      } else if (tag_name!='' && last_char(prefixexp)==' ') {

         if (tag_name!='!DOCTYPE' && tag_name!='!NOTATION') {

            if (tag_name=='?xml') {
               line_offset := "";
               parse point() with line_offset .;
               text := "";  // text before the cursor
               if (line_offset<lastidstart_offset) {
                  text = get_text_safe(lastidstart_offset-(int)line_offset,(int)line_offset);
               }
               // This only works if everthing is on the same line 
               // but this is typically the case.
               b4 := encoding := version  := "";
               parse text with b4 "version[ \t]*=",'r' version "encoding[ \t]*=",'r' encoding;
               if (version=='') {
                  _html_insert_context_tag_item('version', lastid, 
                                                true, '', 0,
                                                root_count, max_matches, 
                                                exact_match, case_sensitive);
               } else if (encoding=='') {
                  _html_insert_context_tag_item('encoding', lastid,
                                                true, '', 0,
                                                root_count, max_matches,
                                                exact_match, case_sensitive);
               } else {
                  _html_insert_context_tag_item('standalone', lastid,
                                                true, '', 0,
                                                root_count, max_matches,
                                                exact_match, case_sensitive);
               }

            } else {

               // first list XML namespace attributes
               if (_LanguageInheritsFrom('xml')) {
                  _str NamespacesHashtab:[];
                  _xml_get_current_namespaces(NamespacesHashtab);
                  _xml_insert_namespace_context_tags_attrs(
                     NamespacesHashtab,
                     0,-1,0,
                     lastid,lastid_prefix, tag_name,true,'',root_count,
                     max_matches,
                     0,exact_match,visited
                     );
               }
               // list attribute names
               if (tag_files._length() > 0) {
                  tag_list_in_class(lastid_prefix, tag_name, 0, 0, tag_files,
                                    root_count, max_matches,
                                    VS_TAGFILTER_VAR,VS_TAGCONTEXT_ONLY_inclass,
                                    exact_match, case_sensitive, 
                                    null, null, visited, depth);
               } else if (!_LanguageInheritsFrom('xml') && root_count==0) {
                  _HtmlListKeywords('keywordattrs',
                                    upcase(tag_name),
                                    lastid,true,'',0,
                                    root_count,max_matches,
                                    exact_match, case_sensitive);
               }
               // if we do not have a DTD or Schema, 
               // the attr name could be just any tag that was used elsewhere
               if (_LanguageInheritsFrom('xml') && root_count==0) {
                  type_name := "";
                  seekpos := 0;
                  cid := tag_find_context_iterator(lastid, exact_match, case_sensitive, false, null);
                  while (cid > 0) {
                     tag_get_detail2(VS_TAGDETAIL_context_type, cid, type_name);
                     tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, cid, seekpos);
                     if (type_name == "var" && seekpos != lastidstart_offset) {
                        tag_insert_match_fast(VS_TAGMATCH_context, cid);
                        if (++root_count > max_matches) break;
                     }
                     if (_CheckTimeout()) break;
                     cid = tag_next_context_iterator(lastid, cid, exact_match, case_sensitive, false, null);
                  }
               }
            }
         }

      } else {

         // first insert tags from namespaces
         if (_LanguageInheritsFrom('xml')) {
            _str NamespacesHashtab:[];
            _xml_get_current_namespaces(NamespacesHashtab);
            _xml_insert_namespace_context_tags(NamespacesHashtab,
                                               lastid, lastid_prefix,
                                               false, '', 0,
                                               root_count, max_matches,
                                               exact_match, true);
         }

         if(_LanguageInheritsFrom('html')) {
            _html_insert_namespace_context_tags(lastid, lastid_prefix,
                                                false, '', 0,
                                                root_count, max_matches,
                                                exact_match, true);
         }

         // special cases for DTDs
         if (isDTD) {
            typeless line_offset="";
            parse point() with line_offset .;
            w1 := w2 := w3 := text := "";  // text before the cursor
            if (line_offset<lastidstart_offset) {
               text=get_text_safe(lastidstart_offset-line_offset,line_offset);
            }
            if (tag_name=='!ELEMENT') {
               parse text with w1 w2 w3;
               if (w1=='<!ELEMENT' && w2!='' && (w3=='' || !pos('[ \t]',w3,1,'r'))) {
               //if (w1=='<!ELEMENT' && w2!='' && last_char(text)=='') {
                  // Since its hard to remember what the syntax is,
                  // we insert more than just an identifier some times.
                  // The down side is that the list terminates when we type a
                  // non-identifier character like '('.  But this seems reasonable.
                  _html_insert_context_tag_array( dtd_element_attr_array,
                                                  lastid,true,'', 0,
                                                  root_count, max_matches,
                                                  exact_match, case_sensitive);
               }
            } else if (tag_name=='!ATTLIST') {
               parse text with w1 w2;
               // Here we try to support case where first attribute is defined
               // on the same line.  Obviously this code is line dependent.  If this
               // is a problem, we can change it later.
               if (w1=='<!ATTLIST' && pos('[ \t]',w2,1,'r')) {
                  parse text with . . w1 w2;
               }
               if (w1=='<!ATTLIST') {
                  tag_list_context_globals(0, 0, lastid,
                                           true, null,
                                           VS_TAGFILTER_MISCELLANEOUS,
                                           VS_TAGCONTEXT_ANYTHING,
                                           root_count, max_matches,
                                           exact_match, case_sensitive,
                                           visited, depth);
               } else if(w1!='' && w1!='>' && (w2=='' || !pos('[ \t]',w2,1,'r'))) {
                  _html_insert_context_tag_array( dtd_attlist_attr_type_array,
                                                  lastid, true, '', 0,
                                                  root_count, max_matches, 
                                                  exact_match, case_sensitive);

               } else if(w2=='CDATA' || w2=='ID' || w2=='IDREF' || w2=='IDREFS' || w2=='NMTOKEN' || w2=='NMTOKENS' ||
                         w2=='ENTITY' || w2=='ENTITIES') {
                  _html_insert_context_tag_array( dtd_attlist_cdata_options_array,
                                                  lastid, true, '', 0,
                                                  root_count, max_matches,
                                                  exact_match, case_sensitive);
               }
            } else if (tag_name=='!NOTATION' || tag_name=='!ENTITY') {
               parse text with w1 w2 w3;
               if (w1=='<'tag_name && w2!='' && (w3=='' || !pos('[ \t]',w3,1,'r'))) {
                  _html_insert_context_tag_array( dtd_notation_attr_array,
                                                  lastid, true, '', 0,
                                                  root_count, max_matches,
                                                  exact_match, case_sensitive);
               }
            } else if (tag_name=='?xml') {
               // This only works if everthing is on the same line but this is typically the case.
               typeless encoding="";
               parse text with . "version[ \t]*=",'r' version "encoding[ \t]*=",'r' encoding;
               if (version=='') {
                  _html_insert_context_tag_item( 'version', 
                                                 lastid, true, '', 0,
                                                 root_count, max_matches, 
                                                 exact_match, case_sensitive);
               } else {
                  _html_insert_context_tag_item( 'encoding', 
                                                 lastid, true,'', 0,
                                                 root_count, max_matches,
                                                 exact_match, case_sensitive);
               }
            }
         }

         // list tag names or end tag names
         if (is_end_tag) {
            if (tag_files._length() > 0) {
               // list end tags matching prefix expression
               tag_list_context_globals(0, 0, lastid,
                                        false, tag_files,
                                        VS_TAGFILTER_MISCELLANEOUS,
                                        VS_TAGCONTEXT_ONLY_non_final,
                                        root_count, max_matches,
                                        exact_match, case_sensitive,
                                        visited, depth);
            }
            if (root_count==0) {
               _HtmlListKeywords('mlckeywords','',
                                 lastid,false,'/',0,
                                 root_count,max_matches,
                                 exact_match, case_sensitive);
            }
         } else {
            // list any tags matching prefix expression
            if (tag_files._length() > 0) {
               tag_list_context_globals(0, 0, lastid,
                                        false, tag_files,
                                        VS_TAGFILTER_MISCELLANEOUS,
                                        VS_TAGCONTEXT_ANYTHING,
                                        root_count, max_matches,
                                        exact_match, case_sensitive,
                                        visited, depth);
            }
            if (root_count==0) {
               _HtmlListKeywords('mlckeywords','',
                                 lastid,false,'',1,
                                 root_count, max_matches,
                                 exact_match,case_sensitive);
            }
         }

         // if we do not have a DTD or Schema, 
         // the tag name could be just any tag that was used elsewhere
         if (_LanguageInheritsFrom('xml')) {
            type_name := "";
            seekpos := 0;
            cid := tag_find_context_iterator(lastid, exact_match, case_sensitive, false, null);
            while (cid > 0) {
               tag_get_detail2(VS_TAGDETAIL_context_type, cid, type_name);
               tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, cid, seekpos);
               if (type_name == "taguse" && seekpos != lastidstart_offset) {
                  tag_get_context_info(cid, auto cmi);
                  cmi.arguments="";
                  tag_insert_match_info(cmi);
                  if (++root_count > max_matches) break;
               }
               if (_CheckTimeout()) break;
               cid = tag_next_context_iterator(lastid, cid, exact_match, case_sensitive, false, null);
            }
         }
      }
      break;

   default:
      // messed up here
      errorArgs[1]=prefixexp;
      return(VSCODEHELPRC_UNABLE_TO_EVALUATE_CONTEXT);
   }

   // Return 0 indicating success if anything was found
   errorArgs[1] = lastid;
   return (root_count == 0)? VSCODEHELPRC_NO_SYMBOLS_FOUND:0;
}

int _bbc_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                            _str lastid,int lastidstart_offset,
                            int info_flags,typeless otherinfo,
                            boolean find_parents,int max_matches,
                            boolean exact_match,boolean case_sensitive,
                            int filter_flags=VS_TAGFILTER_ANYTHING,
                            int context_flags=VS_TAGCONTEXT_ALLOW_locals,
                           VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _html_find_context_tags(errorArgs,
                                  prefixexp,lastid,lastidstart_offset,
                                  info_flags,otherinfo,find_parents,
                                  max_matches,exact_match,case_sensitive,
                                  filter_flags,context_flags,visited,depth);
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
   _str tag_name=info.member_name;

//   say("_html_get_decl: type_name="type_name);
   switch (info.type_name) {
   case 'tag':
      if (substr(tag_name,1,1)=='%' || substr(tag_name,1,1)=='?') {
         return decl_indent_string:+"<"tag_name" ... "substr(tag_name,1,1)">";
      }
      if (info.flags & VS_TAGFLAG_final) {
         return decl_indent_string:+"<"tag_name">";
      } else {
         return decl_indent_string:+"<"tag_name"> ... </"tag_name">";
      }
   case 'group':
   case 'var':
      return decl_indent_string:+"<"info.class_name" "tag_name"=...>";
   case 'const':
      if (info.class_name=='') {
         return decl_indent_string:+"&"tag_name";";
      }
      break;
   case 'enumc':
      if (lastpos(':',info.class_name)) {
         _str tg_name = substr(info.class_name,1,pos('s')-1);
         _str attr_name = substr(info.class_name,pos('s')+1);
         return decl_indent_string:+"<"tg_name" "attr_name"=\""info.member_name"\">";
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
   _str tag_name=info.member_name;
   switch (info.type_name) {
   case 'tag':
      if (info.flags & VS_TAGFLAG_final) {
         return decl_indent_string:+"["tag_name"]";
      } else {
         return decl_indent_string:+"["tag_name"] ... [/"tag_name"]";
      }
   case 'group':
   case 'var':
      return decl_indent_string:+"["info.class_name" "tag_name"=...]";
   case 'const':
      if (info.class_name=='') {
         return decl_indent_string:+':'tag_name;
      }
      break;
   case 'enumc':
      if (lastpos(':',info.class_name)) {
         _str tg_name = substr(info.class_name,1,pos('s')-1);
         _str attr_name = substr(info.class_name,pos('s')+1);
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
   typeless result='';
   int start;
   for (start=1;;) {
      if (start>length(attrvalue)) {
         return(result);
      }
      int i=pos('"',attrvalue,start);
      if (!i) {
         result=result:+'"'substr(attrvalue,start)'"';
         return(result);
      }
      if (i>start) {
         result=result:+'"'substr(attrvalue,start,i-start)'"';
      }
      result=result:+"'\"'";
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

   lch := last_char(idexp_info.prefixexp);
   switch (lch) {
   case '<':
   case '/':
      // tag name or end tag
      word.insertWord = case_html_tag(word.insertWord, false);
      break;
   case ' ':
      // attribute name
      word.insertWord = case_html_tag(word.insertWord, true);
      break;
   case '&':
      // append semicolon if there isn't one
      if (first_char(word.insertWord) != "&" && 
          last_char(word.insertWord)  != ";" &&
          terminationKey != ";" && get_text_safe() != ";") {
         word.insertWord :+= ";";
      }
      break;
   case '%':
      // don't change case of entities
      break;
   case '=':
      // attribute value
      parse idexp_info.prefixexp with auto tag_name auto attrname;
      isFunction := (word.symbol != null && tag_tree_type_is_func(word.symbol.type_name));
      if (!isFunction && !strieq(attrname,"href") && !strieq(attrname,"src")) {
         word.insertWord = case_html_tag(word.insertWord,true);
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

boolean _html_autocomplete_after_replace(AUTO_COMPLETE_INFO &word,
                                         VS_TAG_IDEXP_INFO &idexp_info, 
                                         _str terminationKey="")
{
   if (idexp_info == null || idexp_info.prefixexp == null) {
      return true;
   }
   if (first_char(idexp_info.prefixexp) != "<") {
      return true;
   }

   // parse the tag name and attribute name out of the prefix expression
   parse idexp_info.prefixexp with '<' auto tag_name auto attribute_name '=';
   fixFileSeparator := "";
   if (lowcase(tag_name)=="img" && lowcase(attribute_name)=="src") {
      fixFileSeparator = true;
   }
   if (lowcase(attribute_name)=="href") {
      fixFileSeparator = true;
   }
   if (last_char(idexp_info.prefixexp) != "=") {
      fixFileSeparator = false;
   }

   // this is only an issue for HTML and XHTML modes.
   isHTML := (_LanguageInheritsFrom("html") || _LanguageInheritsFrom("xhtml"));

   // fix directory names with trailing path separators
   if ( isHTML && fixFileSeparator ) {
      lc := last_char(word.insertWord);
      switch (terminationKey) {
      case FILESEP:
      case FILESEP2:
         if (lc == "\'" || lc == "\"") {
            lc = substr(word.insertWord, length(word.insertWord)-1, 1);
            if (lc != FILESEP && lc != FILESEP2) return false;
            left();
         } 
         if (lc == FILESEP || lc == FILESEP2) {
            left();
            _delete_char();
         }
         break;
      case ENTER:
      case TAB:
      case " ":
         if (lc == "\'" || lc == "\"") {
            lc = substr(word.insertWord, length(word.insertWord)-1, 1);
            if (lc != FILESEP && lc != FILESEP2) return false;
            left();
            autocomplete();
            return false;
         }
         break;
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
       first_char(tag_name) != "!" && first_char(tag_name) != "?" &&
       last_char(idexp_info.prefixexp) == " ") {
      last_event("=");
      auto_codehelp_key();
      return false;
   }

   // finished, not a special case
   return true;
}

boolean _xml_autocomplete_after_replace(AUTO_COMPLETE_INFO &word,
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
                            boolean OperatorTyped,
                            boolean cursorInsideArgumentList,
                            int &FunctionNameOffset,
                            int &ArgumentStartOffset,
                            int &flags
                           )
{
   VS_TAG_IDEXP_INFO idexp_info;
   tag_idexp_info_init(idexp_info);
   struct VS_TAG_RETURN_TYPE visited:[];

   int status=_html_get_expression_info(OperatorTyped, idexp_info, visited);
   errorArgs = idexp_info.errorArgs;
   flags = idexp_info.info_flags;

   // not a tag, or an end tag, then skip function help
   if (substr(idexp_info.prefixexp,1,1)!='<' || substr(idexp_info.prefixexp,1,2)=='</') {
      return VSCODEHELPRC_NOT_IN_ARGUMENT_LIST;
   }
   // find start of tag name
   int offset=2;
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
                            boolean OperatorTyped,
                            boolean cursorInsideArgumentList,
                            int &FunctionNameOffset,
                            int &ArgumentStartOffset,
                            int &flags
                           )
{
   return(
      _html_fcthelp_get_start(
         errorArgs,
         OperatorTyped,
         cursorInsideArgumentList,
         FunctionNameOffset,
         ArgumentStartOffset,flags));
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
                      boolean &FunctionHelp_list_changed,
                      int &FunctionHelp_cursor_x,
                      _str &FunctionHelp_HelpWord,
                      int FunctionNameStartOffset,
                      int flags,
                      VS_TAG_BROWSE_INFO symbol_info=null,
                      VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
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
   if (substr(idexp_info.prefixexp,1,1)!='<' || substr(idexp_info.prefixexp,1,2)=='</') {
      return VSCODEHELPRC_NOT_IN_ARGUMENT_LIST;
   }

   // compute the tag name column
   save_pos(auto p);
   _GoToROffset(idexp_info.prefixexpstart_offset);
   int start_col=p_col;
   restore_pos(p);
   if (!p_IsTempEditor) {
      FunctionHelp_cursor_x=(start_col-p_col)*p_font_width+p_cursor_x;
   }

   // decompose prefixexp into tag name and current attribute
   _str tag_name='',attr_name='';
   parse idexp_info.prefixexp with '<' tag_name attr_name;
   if (pos('=',attr_name) && tag_name!='') {
      parse attr_name with attr_name '=';
   } else {
      attr_name=idexp_info.lastid;
   }
   if (tag_name=='') {
      tag_name=idexp_info.lastid;
      attr_name='';
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
   if (extra_tag_file!='') {
      tag_files[tag_files._length()]=extra_tag_file;
   }

   tag_clear_matches();
   int tag_count=0;
   if (tag_files._length() > 0) {
      tag_list_context_globals(0,0,tag_name,false,tag_files,
                               VS_TAGFILTER_MISCELLANEOUS,
                               VS_TAGCONTEXT_ANYTHING,
                               tag_count,def_tag_max_function_help_protos,
                               true,false);
      // trick it into finding tag with 'xsd' prefix to get tagdoc
      if (tag_count==0 && _LanguageInheritsFrom('xsd')) {
         _str prefix='';
         if (pos(':',tag_name)) {
            parse tag_name with prefix ':' . ;
         }
         if (prefix!='xsd') {
            tag_name=_xml_retargetNamespace(tag_name,prefix,'xsd');
            tag_list_context_globals(0,0,tag_name,false,tag_files,
                                     VS_TAGFILTER_MISCELLANEOUS,
                                     VS_TAGCONTEXT_ANYTHING,
                                     tag_count,def_tag_max_function_help_protos,
                                     true,false);
         }
      }
   }
   if (tag_count==0) {
      _HtmlListKeywords('mlckeywords','',
                        tag_name,false,'',0,
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
      _str NamespacesHashtab:[];
      _xml_get_current_namespaces(NamespacesHashtab);

      //say('tag_count='tag_count);
      /*_xml_insert_namespace_context_globals(
         NamespacesHashtab,
         0,-1,0,
         tag_name, //lastid,
         tag_name, //lastid_prefix,
         true,'',tag_count);
      */
#if 1
      _xml_insert_namespace_context_tags(
         NamespacesHashtab,
         0,-1,0,
         tag_name, //lastid,
         tag_name, //lastid_prefix,
         true,'',tag_count,
         def_tag_max_list_members_symbols,0,true,true);
#endif
      //say('after tag_count='tag_count);
   }
#endif

   // put the tags into the function help list
   int i,n=tag_get_num_of_matches();
   if (n==0) {
      return(VSCODEHELPRC_NO_HELP_FOR_FUNCTION);
   }
   int k=0;
   for (i=1; i<=n; ++i) {
      _str tag_file,type_name,file_name,class_name,signature,return_type;
      int line_no,tag_flags;
      tag_get_match(i,tag_file,tag_name,type_name,file_name,line_no,
                    class_name,tag_flags,signature,return_type);

      // set up the function help info list
      _str taginfo=tag_tree_compose_tag(tag_name,class_name,type_name,tag_flags,signature,return_type);
      FunctionHelp_list[k].arglength[0]=length(tag_name);
      FunctionHelp_list[k].argstart[0]=2;
      FunctionHelp_list[k].ParamName=attr_name;
      FunctionHelp_list[k].ParamType='';
      FunctionHelp_list[k].ParamNum=0;
      FunctionHelp_list[k].prototype='';
      FunctionHelp_list[k].tagList[0].comment_flags=0;
      FunctionHelp_list[k].tagList[0].comments=null;
      FunctionHelp_list[k].tagList[0].filename=file_name;
      FunctionHelp_list[k].tagList[0].linenum=line_no;
      FunctionHelp_list[k].tagList[0].taginfo=taginfo;
      //say('f='file_name);
      //say("line_no="line_no);

      // get the attributes and add them to the prototype
      tag_push_matches();
      _str prototype="<"tag_name;
      int attr_count=0;
      if (tag_files._length() > 0) {
         tag_list_in_class('', tag_name, 0, 0, tag_files,
                           attr_count, def_tag_max_list_members_symbols,
                           VS_TAGFILTER_VAR,VS_TAGCONTEXT_ONLY_inclass,
                           false, false);
      }
      if (attr_count==0) {
         _HtmlListKeywords('keywordattrs',
                           upcase(tag_name),'',true,'',0,
                           attr_count,def_tag_max_list_members_symbols,
                           true,false);
      }
      int j,m=tag_get_num_of_matches();
      for (j=1; j<=m; ++j) {
         tag_get_match(j,tag_file,tag_name,type_name,file_name,line_no,
                       class_name,tag_flags,signature,return_type);
         FunctionHelp_list[k].arglength[j]=length(tag_name)+length(return_type)+1;
         FunctionHelp_list[k].argstart[j]=length(prototype)+2;
         prototype=prototype:+' 'tag_name'='return_type;
         if (attr_name=='' && prev_ParamNum!=0) {
            FunctionHelp_list_changed=true;
         } else if (attr_name!='' && strieq(tag_name,attr_name)) {
            FunctionHelp_list[k].ParamNum=j;
            FunctionHelp_list[k].ParamType=return_type;
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
      prototype=prototype'>';
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
                     boolean &FunctionHelp_list_changed,
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

void _mapjsp_init_file(int editorctl_wid, boolean doUpdate=false)
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
   _str taglib_info="";
   index := _FindLanguageCallbackIndex('vs%s-get-taglib-infos',p_LangId);
   if(index) {
      int status = call_index(p_window_id, '', taglib_info, index); 
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

static int _mapjsp_create_tagfile(int editorctl_wid, boolean ForceUpdate, _str taglib_info)
{
   int i, temp_view_id, orig_view_id=p_window_id, status=0;

   // Get tagfile and list of uris with their associated filenames from the config file.
   _str tagfile=editorctl_wid._jsp_GetConfigTagFile();

   typeless num_prefixes="";
   parse taglib_info with num_prefixes '@' taglib_info;

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
   
      parse temp_taglib_info with uri '@' prefix '@' temp_taglib_info;
 
      if(uriHashTableExists && !UriHashtab:[uri]._isempty()) {
         file_name=UriHashtab:[uri];
      } else {
         file_name=uri;
      }

      if(ForceUpdate && !file_exists(file_name)) {
         result=_OpenDialog('-modal',
                            "Locate TLD file associated with the uri '" :+ uri :+ "'",                   // Dialog Box Title
                            '',                   // Initial Wild Cards
                            "XML/JSP TagLib Files (*.tld;*.xml)",       // File Type List
                            OFN_FILEMUSTEXIST     // Flags
                            );
         if (result=='') {
            return 0;
         }
         file_name=result;         
      }

      file_names[file_names._length()] = file_name;
      PrefixHashtab:[prefix] = uri;
      UriHashtab:[uri] = file_name;
   }

   if (tagfile=='') {
      tagfile=mktemp(1,'.vtg');
   }

   editorctl_wid._clex_jspSetConfig(ForceUpdate, _jsp_MakeConfig(tagfile, PrefixHashtab, UriHashtab));

   tag_close_db(tagfile);
   status=tag_create_db(tagfile);
   if (status < 0) {
      return(status);
   }

   // Go through all tld files imported into this jsp file and add
   // their tags to the temporary tag file associated with JSP.
   index := _FindLanguageCallbackIndex('vs%s-list-tags-with-prefix','tld');
   if(index) {
      for(i=0; i < (int)num_prefixes; i++) {
         _str prefix, uri;
   
         parse taglib_info with uri '@' prefix '@' taglib_info;

         // Check existence of URI. If the uri does not exist
         // then prompt the user for the location of the uri and then
         // store the mapping of the uri to the file in the jspConfig.
         // If the uri does exist then make a mapping to itself.

         // Check to see if this uri is already in the config and has an associated filename
         // If not then see if the uri exists and if it does not then prompt for the location.
   
         // Go through TLD files opening up a temporary buffer and listing tags
         // for the TLD. They should go into a temporary JSP tag file.
         status=_open_temp_view(file_names[i], temp_view_id, orig_view_id);
   
         if(!status) {
            tag_lock_context(); 
            status=tag_insert_file_start(file_names[i]);
            tag_clear_embedded();
            tag_set_date(p_buf_name,'1111':+substr(p_file_date,5));

            // Insert tags with the taglib prefix
            status = call_index(temp_view_id, file_names[i], prefix, index);  

            // Empty prefix will insert tags with the shortname of the taglib defined in the tld
            status = call_index(temp_view_id, file_names[i], '', index); 

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

static void _jsp_addTagsToColorCoding(int editorctl_wid, int cfg_color=CFG_KEYWORD)
{
   int i, status=tag_read_db(editorctl_wid._jsp_GetConfigTagFile());

   _str keywords[]=null;

   // Failed to read tag database
   if (status < 0) return;

   _str tag_name="";
   _str tag_type="";
   _str file_name="";
   int line_no=0;
   _str class_name="";
   int tag_flags=0;

   // Can't nest find_global and find_in_class since they step all over each other
   // so make a temp array of all the keywords and then get the attributes later.
   status=tag_find_global(VS_TAGTYPE_tag,0,0);
   for (;!status;) {
      tag_get_info(tag_name,tag_type,file_name,line_no,class_name,tag_flags);
      if (!(tag_flags& VS_TAGFLAG_final)) {
         keywords[keywords._length()] = tag_name;
      }
      status=tag_next_global(VS_TAGTYPE_tag,0,0);
   }
   tag_reset_find_in_class();

   // Gather the attributes for each keyword into a space delimited list to
   // insert into the lexer for jsp(html)
   for(i=0; i < keywords._length(); i++) {
      _str attributes="";

      // Create attribute list
      status=tag_find_in_class(keywords[i]);
      for (;!status;) {
         _str attribute_name;
         tag_get_detail(VS_TAGDETAIL_name, attribute_name);
         attributes = attributes :+ attribute_name :+ ' ';
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
      int num_matches=0;
      tag_list_context_globals(window_id,tree_index, "", false, tld_file_list, 
                               VS_TAGFILTER_MISCELLANEOUS,VS_TAGCONTEXT_ANYTHING,
                               num_matches, def_tag_max_list_members_symbols, false, false);
      window_id.tag_pop_matches();
   }
}

// These are essentially the same as the xml versions but the hash table
// maps prefixes to tld files.
static _str _jsp_MakeConfig(_str tagfile,_str (&PrefixHashtab):[], _str (&UriHashtab):[])
{
   _str string1='';
   typeless i;
   typeless value="";
   for (i=null;;) {
      value=PrefixHashtab._nextel(i);
      if (i==null) {
         break;
      }
      if (string1=='') {
         string1=i'='value;
      } else {
         string1=string1';'i'='value;
      }
   }

   _str string2='';
   for (i=null;;) {
      value=UriHashtab._nextel(i);
      if (i==null) {
         break;
      }
      if (string2=='') {
         string2=i'='value;
      } else {
         string2=string2';'i'='value;
      }
   }
   //say('s='string);
   return(tagfile'|'string1'|'string2);
}
_str _jsp_GetConfigTagFile()
{
   _str tagfile,string1,string2;
   parse _clex_jspGetConfig() with tagfile'|'string1'|'string2;
   return(tagfile);
}

int _jsp_GetConfigPrefixToUriHash(_str (&PrefixHashtable):[])
{
   _str prefix, file_name, string, tagfile, string1, string2;

   parse _clex_jspGetConfig() with tagfile'|'string1'|'string2;

   if(string1=='') return 0; // Config is empty no hash table created.

   while(string1 != '') {
      parse string1 with prefix '=' file_name ';' string1;
      PrefixHashtable:[prefix]=file_name;
   }
   return 1; // Hash table info found and hash table created.
}

int _jsp_GetConfigUriToFileHash(_str (&UriHashtable):[])
{
   _str uri, file_name, string, tagfile, string1, string2;

   parse _clex_jspGetConfig() with tagfile'|'string1'|'string2;

   if(string2=='') return 0; // Config is empty no hash table created.

   while(string2 != '') {
      parse string2 with uri '=' file_name ';' string2;
      UriHashtable:[uri]=file_name;
   }
   return 1; // Hash table info found and hash table created.
}

static void _html_insert_namespace_context_tags(_str lastid, _str lastid_prefix,
                                                boolean is_attrib,
                                                _str clip_prefix, 
                                                int start_or_end,
                                                int &num_matches, int max_matches,
                                                boolean exact_match=false,
                                                boolean case_sensitive=false,
                                                boolean insertTagDatabaseNames=false
                                               )
{
   _str only_prefix=null;
   int i=pos(':',lastid_prefix);
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

       _str tag_filename = _jsp_GetConfigTagFile();

       int status=tag_find_global(VS_TAGTYPE_tag,0,0);
       for (;!status;) {
          _str orig_tag_name="";
          _str tag_type="";
          _str file_name="";
          int line_no=0;
          _str class_name="";
          int tag_flags=0;
          tag_get_info(orig_tag_name,tag_type,file_name,line_no,class_name,tag_flags);
          _str tag_name=orig_tag_name;
          //tag_get_detail(VS_TAGDETAIL_arguments,
          i=pos(':',tag_name);
          if (i) {
             tag_name=substr(tag_name,i+1);
          }

          if (prefix!='') {
             tag_name=prefix:+':':+tag_name;
          }

          if (exact_match && tag_name!=lastid_prefix) {
             status=tag_next_global(VS_TAGTYPE_tag,0,0);
             continue;
          }
          _str temp_prefix=lastid_prefix;
          if (insertTagDatabaseNames) {
             tag_name=orig_tag_name;
             temp_prefix=tag_name;
          }

          HTML_INSERT_TAG_ARGS args;
          args.file_name=file_name;
          args.line_no=line_no;
          args.class_name=class_name;
          args.tag_flags=tag_flags;
          args.signature='';

          if (start_or_end==0) {
             _html_insert_context_tag_item(
                tag_name,
                lastid, false, '', start_or_end,
                num_matches, max_matches,
                exact_match, false,
                tag_filename,tag_type,&args
                );

          } else if (!(tag_flags& VS_TAGFLAG_final)) {
             _html_insert_context_tag_item(
                /*"/"*/tag_name,
                lastid,false,'', 0,
                num_matches, max_matches,
                false, false,
                tag_filename,tag_type,&args
                );
          }
          if (exact_match) {
             break;
          }
          status=tag_next_global(VS_TAGTYPE_tag,0,0);
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
      i=pos('<a href=',msg,i,'i');
      if (!i) {
         break;
      }
      int j=pos('>',msg,i);
      if (j) {
         msg=substr(msg,1,i-1):+substr(msg,j+1);
         j=pos('</a>',msg,i);
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
 * @return boolean
 */
boolean _xml_find_surround_lines(int &first_line, int &last_line, 
                                 int &num_first_lines, int &num_last_lines, 
                                 boolean &indent_change, 
                                 boolean ignoreContinuedStatements=false) 
{
   indent_change = true;

   // keep track of the first line, check that it starts with "<"
   first_line = p_RLine;
   first_non_blank();
   if (get_text_safe() != '<') {
      return false;
   }

   // check that we have a tag name next
   right();
   color := _clex_find(0, 'g');
   if (color != CFG_KEYWORD && color != CFG_UNKNOWNXMLELEMENT && color != CFG_XHTMLELEMENTINXSL) {
      return false;
   }

   // find the end of the same tag name
   status := search('>', "@hXcs");
   if (status) {
      return false;
   }

   // check that we are at the end of the line, not counting comments
   orig_line := p_RLine;
   save_pos(auto p);
   p_col++;
   _clex_skip_blanks('h');
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
   int orig_col=p_col;
   first_non_blank();
   if (p_col < orig_col) {
      return false;
   }

   // look for end of the end tag
   status = search('>', "@hXcs");
   if (status) {
      return false;
   }

   // this is the end of the surround block (the end tag)
   num_last_lines=1;
   last_line = p_RLine;

   // check for short end tag
   if (p_col > 1) {
      p_col--;
      if (get_text(2)=='/>') num_last_lines=0;
      p_col++;
   }

   // make sure that it is at the end of the line
   p_col++;
   _clex_skip_blanks('h');
   if (p_RLine==last_line && !at_end_of_line()) {
      return false;
   }

   // success
   return true;
}
boolean _html_find_surround_lines(int &first_line, int &last_line, 
                                  int &num_first_lines, int &num_last_lines, 
                                  boolean &indent_change, 
                                  boolean ignoreContinuedStatements=false) 
{
   return _xml_find_surround_lines(first_line, last_line, num_first_lines, num_last_lines, indent_change, ignoreContinuedStatements);
}

