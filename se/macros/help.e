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
#include "eclipse.sh"
#include "hthelp.sh"
#include "pip.sh"
#include "xml.sh"
#import "codehelp.e"
#import "compile.e"
#import "context.e"
#import "dlgman.e"
#import "doscmds.e"
#import "html.e"
#import "listbox.e"
#import "main.e"
#import "optionsxml.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "treeview.e"
#import "util.e"
#import "math.e"
#endregion

static _str help_class_number;
static _str help_class_type;

_str def_bottom_border;
_str _retrieve;

#if 1 /* __PCDOS__ */
// No longer used, kept for backwards compatibility
_str def_msdn_coll;
#endif 

_str def_word_help_url="http://www.google.com/search?ie=UTF-8&q=%(mode-name)%%20%c";


/**
 * Displays <i>message_text</i> in message box with an information 
 * icon displayed to the left of the message.  This function is typically 
 * used to display help information messages.
 * 
 * @param string     message to display
 * 
 * @see popup_message
 * @see _message_box
 * @see help
 * @see message
 * @see messageNwait
 * @see sticky_message
 * @see clear_message
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
_command void popup_imessage(_str string="")
{
   popup_message(string,MB_OK|MB_ICONINFORMATION);
}
/**
 * Displays <i>message_text</i> in message box with an exclamation 
 * point displayed to the left of the message.  Use the new and more 
 * powerful <b>_message_box</b> function instead of this function.  
 * This function is typically used with the <b>_post_call</b> function to 
 * display an error message box during <b>on_got_focus</b> or 
 * <b>on_lost_focus</b> events.
 * 
 * @param string     message to display
 * @param flags      message box flags (MB_*)
 * @param title      message box title
 * 
 * @see popup_imessage
 * @see _message_box
 * @see help
 * @see message
 * @see messageNwait
 * @see sticky_message
 * @see clear_message
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
_command void popup_message(_str string="", typeless flags="", _str title="")
{
   if (flags==''){
      flags=MB_OK|MB_ICONEXCLAMATION;
   }
   if (title=='') {
      title=editor_name('a');  // Application name
   }
   // Parse off switches
   for (;;) {
      string=strip(string,'L');
      if (substr(string,1,1)!='-'){
         break;
      }
      option := "";
      parse string with option string;
      switch(lowcase(option)){
      case '-title':
         title=strip(parse_file(string),'B','"');
         break;
      }
   }
   _message_box(string,title,flags);
}

/**
 * Displays the message corresponding to error number error_code.
 * Displays the message 
 * get_message 
 */
void popup_nls_message(int error_code, ...)
{
   msg := "";
   switch (arg()) {
   case 1:
      msg = get_message(error_code);
      break;
   case 2:
      msg = get_message(error_code, arg(2));
      break;
   case 3:
      msg = get_message(error_code, arg(2), arg(3));
      break;
   case 4:
      msg = get_message(error_code, arg(2), arg(3), arg(4));
      break;
   case 5:
      msg = get_message(error_code, arg(2), arg(3), arg(4), arg(5));
      break;
   default:
      msg = "Modify popup_get_message() to support more arguments.";
      say(msg);
      break;
   }
   popup_message(msg);
}

/**
 * Launches the help index page.
 * 
 * @param help_file URL of the help index page.  DO make sure that this path
 * is a valid URL in UNIX build e.g. file:///opt/slickedit/.....
 */
static void _help_contents(_str help_file)
{
   typeless status=_syshtmlhelp(help_file);
   _help_error(status,help_file,'');
}

static _str escapeURISpecialChars(_str str,bool doublePercents=false) {
    int i;
    _str result=str;
    for (i=1;i<=length(result);++i) {
       ch := substr(result,i,1);
       if (isalpha(ch) || isdigit(ch) || ch=='_' || ch=='.' || ch=='_' || ch=='~') {
          continue;
       }
       temp := _dec2hex(_asc(ch),16);
       if (length(temp)<1) {
          temp='0'temp;
       }
       if (doublePercents) {
          temp='%%'temp;
       } else {
          temp='%'temp;
       }
       //say('b4 i='i' result='result);
       result=substr(result,1,i-1):+temp:+substr(result,i+1);
       //say('af i='i' result='result);
       i+=length(temp)-1;
    }
    return result;
}

int _word_help(_str help_file,_str word,bool ImmediateHelp=false,bool maybeWordHelp=false)
{
   if(isEclipsePlugin()) {
      _eclipse_help(word);
      return 0;
   }
   if(isVisualStudioPlugin()) {
      return 0;
   }

   // currently if maybe_word_help!=0 then help_file must be vslick.hlp
   if (maybeWordHelp && !_isEditorCtl()) {
      _help_contents(help_file);
      return(0);
   }
   if (_isEditorCtl() && word=='' && (
       _file_eq('.'_get_extension(p_buf_name),_macro_ext) ||
       _file_eq('.'_get_extension(p_buf_name),'.sh'))) {
      help_file=_help_filename('');
   }
   allHelpWorkDone := false;
   start_col := 0;
   _str ext=_get_extension(help_file);
   if (word=='') {
      if( _isEditorCtl()) {
         word=_CodeHelpCurWord(allHelpWorkDone);
         if (word!='') {
            // When we are in code help, pressing F1 is like press Ctrl+F1 (word help)
            maybeWordHelp=false;
         }
         if (allHelpWorkDone) {
            return(0);
         }
         if (word=='') {
            word=cur_word(start_col);
         }
      }
      if (word=='') {
         if (_isUnix() || !_file_eq(ext,'idx') ) {
            if (maybeWordHelp) {
               _help_contents(help_file);
               return(0);
            } else {
               message(nls('No word at cursor'));
               return(0);
            }
         }
      }
   }

   if( _isEditorCtl() && word!='') {
      _str extension=_get_extension(p_buf_name);
      if ( _file_eq('.'extension,_macro_ext) || _file_eq(extension,'cmd') ||
         (_file_eq(extension,'sh')) ) {
         _str new_keyword=h_match_exact(word);
         if (new_keyword=='') {
            if (maybeWordHelp) {
               _help_contents(help_file);
               return(0);
            }
            _message_box(nls("Help item '%s' not found",word));
            return(STRING_NOT_FOUND_RC);
         }
         word=new_keyword;
         html_keyword_help(_help_filename(''),word);
         return(0);
      }
   }

   typeless status=0;
   if( _isEditorCtl()) {
      if (def_use_word_help_url && word!='') {
         set_env('mode-name',escapeURISpecialChars(p_mode_name,true));
         _str url=_parse_project_command(def_word_help_url,'','',escapeURISpecialChars(word,true));
         set_env('mode-name',null);
         goto_url(url);
         return 0;
      }
   }
   if (_isUnix()) {
      if( _isEditorCtl()) {
         status=man(word);
         if (status && maybeWordHelp) {
            _help_contents(help_file);
            return(0);
         }
         return(status);
      } else {
         mou_hour_glass(true);
         int wid=_find_formobj("_unixman_form","n");
         if (wid) {
            _nocheck _control ctlfind;
            _nocheck _control ctleditorctl;
            wid._set_foreground_window();
            wid.ctleditorctl._set_focus();
            wid.ctlfind.call_event(word,1,wid.ctlfind,on_create,"");
            mou_hour_glass(false);
            return(0);
         }
         status=show("-xy -app _unixman_form",word,0);
         mou_hour_glass(false);
         return(status);
      }
   } else {
      if (maybeWordHelp) {
         help_file=_help_filename('');
      }
      if (word=='') {
         _help_contents(help_file);
         return(0);
      }
      status=html_keyword_help(help_file,word,true);
      return(0);
   }
}

/**
 * SDK word help.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Miscellaneous_Functions
 * 
 * @deprecated Use {@link help()} 
 */ 
_command wh(_str word="") name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   return(_word_help('',word));
}
/**
 * SDK word help.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Miscellaneous_Functions
 * 
 * @deprecated Use {@link help()} 
 */ 
_command wh2(_str word="") name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   return(_word_help('',word));
}

/**
 * SDK word help.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Miscellaneous_Functions
 * 
 * @deprecated Use {@link help()} 
 */ 
_command wh3(_str word="") name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   return(_word_help('',word));
}
_command qh(_str word="") name_info(','VSARG2_ICON|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if (word=='') {
      junk := 0;
      word=cur_word(junk);
   }
   dos('qh 'word);
}

_str _help_filename(_str file_spec="")
{
   if (file_spec=='') {
      file_spec=_help_file_spec;
   }
   if(file_spec=='') {
      file_spec=_getSlickEditInstallPath():+'help':+FILESEP:+SLICK_HELP_FILE;
      if (!file_exists(file_spec)) {
         // Not sure if this if is needed but keep it for now.
         if (_isUnix()) {
            _message_box(nls("Can't find help file '%s'",SLICK_HELP_FILE));
            //_message_box(nls("Can't find help file '%s",SLICK_HELP_FILE))
         } else {
            _message_box(nls("Can't find help file '%s'",file_spec));
            //_message_box(nls("Can't find help file '%s",SLICK_HELP_FILE))
         }
      }
      if (file_spec!='') {
         _help_file_spec=absolute(file_spec);
         file_spec=_help_file_spec;
      }
      return(file_spec);
   }
   if (pos('+',file_spec)) {
      return(file_spec);
   }
   _str temp=slick_path_search(file_spec,"S");
   if (temp=='') {
      _message_box(nls("Can't find help file '%s'",file_spec));
      return('');
   }
   if (file_spec=='' && temp!='') {
      _help_file_spec=absolute(temp);
   }
   temp=_parse_project_command(temp, '', '', '');
   return(temp);
}
static _str hmpu_sellist_callback(int sl_event,_str &result,_str info)
{
   if (sl_event==SL_ONDEFAULT) {
      // check that the item in the combo box is a valid Slick-C identifier
      result=_sellist._lbget_text();
      _param1=_sellist.p_line-1;
      return(1);
   }
   return('');
}
_str h_match_pick_url(_str name,bool &CrossReferenceMultiplyDefined=false,_str helpindex_filename=SLICK_HELPINDEX_FILE,bool quiet=false,bool justVerifyHaveKeyword=false,int xmlcfg_helpindex_handle= -1)
{
   CrossReferenceMultiplyDefined=false;
   int IndexTopicNodes[];
   filename := "";
   int handle=xmlcfg_helpindex_handle;
   if (handle<0) {
      filename=_getSlickEditInstallPath():+'help':+FILESEP:+helpindex_filename;
      //filename=_maybe_quote_filename(_config_path():+SLICK_HELPLIST_FILE);
      int status;
      handle=_xmlcfg_open(filename,status);
      if (handle<0) {
         if ( handle==FILE_NOT_FOUND_RC ) {
            _message_box(nls("File '%s' not found",filename));
         } else {
            _message_box(nls("Error loading help file '%s'",filename));
         }
         return('');
      }
   }
   
   int key;
   if (pos("'",name)) {
      key=_xmlcfg_find_simple(handle,'/indexdata/key[strieq(@name,"'name'")]');
   } else {
      key=_xmlcfg_find_simple(handle,"/indexdata/key[strieq(@name,'"name"')]");
   }

   if (key<0) {
      if (xmlcfg_helpindex_handle<0) _xmlcfg_close(handle);
      if (!quiet) {
         _message_box(nls("%s1 not found in the help index",name));
      }
      return('');
   }
   return _xmlcfg_get_attribute(handle,key,"url");
#if 0
   _str array[];
   _str array_url[];
   _xmlcfg_find_simple_array(handle,"topic/@name",array,key,VSXMLCFG_FIND_VALUES);
   _xmlcfg_find_simple_array(handle,"topic/@url",array_url,key,VSXMLCFG_FIND_VALUES);
   if (xmlcfg_helpindex_handle<0) _xmlcfg_close(handle);
   if (!array._length()) {
      if (!quiet) {
         _message_box(nls("Error in help file.  No URL's for help index item '%s1'",name));
      }
      return('');
   }
   if (array._length()==1 || justVerifyHaveKeyword ) {
      return(array_url[0]);
   }
   CrossReferenceMultiplyDefined=1;
   
   typeless result=show('-modal _sellist_form',
                        'Choose a Help Topic',
                        SL_DEFAULTCALLBACK|SL_SELECTCLINE, // flags
                        array,   // input_data
                        "OK", // buttons
                        '',   // help item
                        '',   // font
                        hmpu_sellist_callback   // Call back function
                       );
   if (result=='') {
      return('');
   }
   return(array_url[_param1]);
#endif
}

_str h_match_exact(_str name)
{
   view_id := 0;
   get_window_id(view_id);
   activate_window(VSWID_HIDDEN);
   //tname=lowcase(translate(name,'_','-'));
   typeless result=h_match(name,1);
   for (;;) {
      if (result=='') {
          h_match(name,2);
          activate_window(view_id);
          return('');
      }
      if (strieq(name,result) /*lowcase(translate(result,'_','-'))*/) {
          h_match(name,2);
          activate_window(view_id);
          return(result);
      }
      result=h_match(name,0);
   }
}
int gxmlcfg_help_index_handle;
static _str ghm_array[];
static int ghm_i;
_str h_match(_str &name,int find_first)
{
   filename := "";
   tname := lowcase(translate(name,'_','-'));
   if ( find_first ) {
      if ( find_first:==2 ) {
         ghm_array._makeempty();
         return('');
      }
      ghm_array._makeempty();ghm_i=0;
      if (!gxmlcfg_help_index_handle) {
         filename=_getSlickEditInstallPath():+'help':+FILESEP:+SLICK_HELPINDEX_FILE;
         //filename=_maybe_quote_filename(_config_path():+SLICK_HELPLIST_FILE);
         int status;
         int handle=_xmlcfg_open(filename,status);
         if (handle<0) {
            if ( handle==FILE_NOT_FOUND_RC ) {
               _message_box(nls("File '%s' not found",filename));
            } else {
               _message_box(nls("Error loading help file '%s'",filename));
            }
            return('');
         }
         gxmlcfg_help_index_handle=handle;
      }
      _xmlcfg_find_simple_array(gxmlcfg_help_index_handle,"/indexdata/key/@name",ghm_array,TREE_ROOT_INDEX,VSXMLCFG_FIND_VALUES);
      //name=_escape_re_chars(translate(name,"\n\n","-_"));
      //name=stranslate(name,'[\-_]',"\n");
      //status=search('^ ('name'|:ghm_i, 'name')','ri@');
   }
   for (;;) {
      if (ghm_i>=ghm_array._length()) {
         return('');
      }
      if (length(ghm_array[ghm_i])>=length(name) && 
          strieq(tname,substr(translate(ghm_array[ghm_i],'_','-'),1,length(name)))
          ) {
         break;
      }
      ++ghm_i;
   }
   ++ghm_i;
   return(ghm_array[ghm_i-1]);
}
static _help_error(int status,_str in_filenames,_str word)
{
   if (status==STRING_NOT_FOUND_RC) {
      _message_box(nls('No help on %s',word));
      return('');
   }
   if (status==FILE_NOT_FOUND_RC) {
      filename := "";
      _str filenames=in_filenames;
      for (;;) {
         parse filenames with filename '+' filenames ;
         filename=strip(filename,'B');
         if (filename=='') {
            _message_box(nls("File '%s' not found.",in_filenames));
            return('');
         }
         _str ext=_get_extension(filename);
         typeless result=slick_path_search(filename);
         if (result=='') {
            _message_box(nls("File '%s' not found.",filename));
            return('');
         }
      }
   }
}
static _str EmulateHelpItem()
{
   if (def_keys == "vcpp-keys") {
      return "Visual C++ Emulation Keys";
   }
   return longEmulationName(def_keys) :+ " Emulation Keys";
}
static int html_keyword_help(_str filename,_str keyword,bool show_contents_if_keyword_not_found=false)
{
   junk := false;
   name:=_strip_filename(filename,'PE');
   if (name=='slickedit5') {
      name='slickedit';
   }
   index_filename := name:+"index.xml";
   _str url=h_match_pick_url(keyword,junk,index_filename,show_contents_if_keyword_not_found,_isUnix());
   if (url=='') {
      _help_contents(filename);
      return(1);
   }
   return(_syshtmlhelp(filename,HH_DISPLAY_TOPIC,url));
}
/**
 * <p>The help command allows you to use the command line to get help on a 
 * specific help item or get context sensitive help. 
 *  
 * <p>By default, F1 displays context sensitive help for the word at the cursor. 
 * When you are not in any context, help on table of contents is displayed.</p>
 * 
 * <p>When no parameters and there is a word at the cursor, 
 * context sensitive help for the current word is provided. A URL search is done based
 * on the configuration macro variable "def_word_help_url" which
 * builds a url search which combines the word and the mode
 * name. For Slick-C, the help index is searched for the word.
 * 
 * <p>The <i>keyword</i> parameter may specify a help index item stored
 * in "slickeditindex.xml". It's the same list display in the help
 * index. You don't have to memorize every help item. Use the
 * space bar and '?' keys (completion) to help you enter the
 * name. If you are looking at some macro source code and want
 * help on a function, invoke the
 * <b>help</b> command and specify the name of the function (or just press F1).
 * Browse some of the features on the Help menu. You may find
 * them useful as well. If you specify "-search" for
 * <i>name</i>, the help search tab is displayed. If you specify
 * "-contents" for <i>name</i>, the help contents tab is
 * displayed.  If you specify "-index" for <i>name</i>, the help
 * index tab is displayed.</p>
 * 
 * <p>Press the ESC key to toggle the cursor to the command line.</p>
 *
 * @example
 * <pre>
 *    help windows keys
 *    help slickedit keys
 *    help emacs keys
 *    help brief keys
 *    help regular expressions
 *    help operators
 *    help substr
 *    help _control
 *    help -index
 * </pre>
 * 
 *
 * @categories Miscellaneous_Functions
 * 
 */
_command help(_str keyword="", _str filename="") name_info(HELP_ARG','VSARG2_CMDLINE)
{
   if(isEclipsePlugin()) {
      _str url = h_match_pick_url(keyword);
      if (url != '') {
         _eclipse_help(url);
      }
      return 0;
   }
   if(isVisualStudioPlugin()) {
      return 0;
   }

   i := 0;
   first_ch := "";
   command := "";
   typeless status=0;
   url := "";

   if ( p_window_id==_cmdline && keyword=='' && filename=='') {
      /* Check if a command is on the command line */
      _cmdline.get_command(command);
      parse command with command .;
      first_ch=substr(command,1,1);
      i=pos('[~A-Za-z0-9_\-]',command,1,'r');
      if ( i ) {
         command=substr(command,1,i-1);
      }
      if ( isdigit(first_ch) ) {
         command='0';
      } else if ( ! isalpha(first_ch) ) {
         command=first_ch;
      }
      if ( command!='' ) {
         if (def_keys=='ispf-keys' && h_match_exact('ispf-'lowcase(command))!='') {
            return(help('ispf-'lowcase(command)));
         }
         if (h_match_exact(command)!='') {
            return(help(command));
         }
         ucommand := stranslate(command, '_', '-');
         if (h_match_exact(ucommand)!='') {
            return(help(ucommand));
         }
         // Show table of contents item
         keyword='';
      }
   }
   orig_filename := filename;
   filename=_help_filename(filename);
   if (filename=='') {
      return(1);
   }
   if ( keyword=='') {
      _word_help(filename,'',false,true);
      // Show table of contents

      //status=_syshelp(filename,'',HELP_CONTENTS);
      //_help_error(status,filename,'');
      return(1);
   }
   if (lowcase(keyword)=='-contents') {
      _help_contents(filename);
      return(1);
   }
   if (lowcase(keyword)=='-index') {
      status=_syshtmlhelp(filename,HH_DISPLAY_INDEX);
      _help_error(status,filename,'');
      return(1);
   }
   if (lowcase(keyword)=='-using') {
      _message_box('-using option no longer supported');
      return(1);
   }
   if (lowcase(keyword)=='-search') {
      status=_syshtmlhelp(filename,HH_DISPLAY_SEARCH);
      _help_error(status,filename,'');
      return(1);
   }
   if (lowcase(keyword)=='summary of keys') {
      keyword=EmulateHelpItem();
   }
   if (orig_filename==''){
      if (def_error_check_help_items) {
         new_keyword := "";
         if (def_keys=='ispf-keys') {
            new_keyword=h_match_exact('ispf-'lowcase(keyword));
         }
         if (new_keyword=='') {
            new_keyword=h_match_exact(keyword);
         }
         if (new_keyword=='') {
            new_keyword=h_match_exact(stranslate(keyword, '_', '-'));
         }
         if (new_keyword=='') {
            _message_box(nls("Help item '%s' not found",keyword));
            return(STRING_NOT_FOUND_RC);
         }
         keyword=new_keyword;
      }
   }
   if (def_error_check_help_items) {
      _str ext=_get_extension(filename);
      if ( _file_eq(ext,'chm') || _file_eq(ext,'htm') || _file_eq(ext,'qhc')) {
         status=html_keyword_help(filename,keyword);
      }else if ( _file_eq(ext,'hlp') ) {
         _syshelp(filename,keyword);
      }
   } else {
      status=_syshtmlhelp(filename,HH_KEYWORD_LOOKUP,keyword);
      _help_error(status,filename,keyword);
   }

   // log this event in the Product Improvement Program
   if (_pip_on) {
      name := p_name;
      if (p_object == OI_EDITOR) {
         name = p_mode_name' file';
      }
      _pip_log_help_event(keyword, p_object, name);
   }

   return(0);
}

// static _str get_system_browser_command()
// {
//    // Predefined list of browsers to search for and their command
//    // to open a URL (%f).
//    _str browser_list[][];
//    browser_list._makeempty();
//    int i = 0;
//    browser_list[i][0] = "firefox";
//    browser_list[i++][1] = "'%f'";
//    browser_list[i][0] = "mozilla";
//    browser_list[i++][1] = "-remote 'openURL('%f')'";
//    browser_list[i][0] = "netscape";
//    browser_list[i++][1] = "-remote 'openURL('%f')'";
//
//    int size = browser_list._length();
//    for (i = 0; i < size; ++i) {
//       _str browser_path = path_search(browser_list[i][0]);
//       if (!browser_path._isempty()) {
//          // System browser found.
//          _str cmd = browser_path' 'browser_list[i][1];
//          return cmd;
//       }
//    }
//    return '';
// }
//
// /**
//  * Open a specified URL using user's web browser of choice.
//  *
//  * @param url URL to open.  Must be well-formatted (e.g.
//  *            file:///path/to/file).
//  */
// void launch_web_browser(_str url='')
// {
//    if (_isMac() || !__UNIX__) {
//       // Use the old way for Mac for now.  But we need to revisit
//       // this after beta and fix it the right way.
//       goto_url(url, true);
//       return;
//    }
//    _str browser_cmd = get_system_browser_command();
//    if (!browser_cmd._isempty()) {
//       browser_cmd = stranslate(browser_cmd, url, '%f');
//       shell(browser_cmd, 'A');
//    }
// }

defeventtab _comboisearch_form;
void list1.lbutton_double_click()
{
   _ok.call_event(_ok,lbutton_up);
}
_ok.on_create()
{
   list1.p_completion=HELP_ARG;
   list1.p_ListCompletions=false;
   _str filename=_getSlickEditInstallPath():+'help':+FILESEP:+SLICK_HELPINDEX_FILE;
   //filename=_maybe_quote_filename(_config_path():+SLICK_HELPLIST_FILE);
   int status;
   int handle=_xmlcfg_open(filename,status);
   if (handle<0) {
      if ( handle==FILE_NOT_FOUND_RC ) {
         _message_box(nls("File '%s' not found",filename));
      } else {
         _message_box(nls("Error loading help file '%s'",filename));
      }
      return('');
   }
   _str array[];
   _xmlcfg_find_simple_array(handle,"/indexdata/key/@name",array,TREE_ROOT_INDEX,VSXMLCFG_FIND_VALUES);
   _xmlcfg_close(handle);
   int wid=list1.p_window_id;
   int i;
   for (i=0;i<array._length();++i) {
      wid._lbadd_item(array[i]);
   }

   //list1.p_cb_list_box.search('^ :i,','@r','');
   list1._lbtop();
   list1._lbselect_line();
   return('');
}

void list1.on_change(int reason)
{
   switch (reason) {
   case CHANGE_OTHER:
      list1._lbselect_line();
      list1.line_to_top();
   }
}

void _ok.lbutton_up()
{
   p_active_form._delete_window(list1._lbget_text());
}
