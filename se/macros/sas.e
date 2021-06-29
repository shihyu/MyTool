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
#include "tagsdb.sh"
#include "color.sh"
#import "se/lang/api/LanguageSettings.e"
#import "adaptiveformatting.e"
#import "alias.e"
#import "autocomplete.e"
#import "c.e"
#import "cfcthelp.e"
#import "codehelp.e"
#import "codehelputil.e"
#import "compile.e"
#import "complete.e"
#import "context.e"
#import "cutil.e"
#import "csymbols.e"
#import "error.e"
#import "main.e"
#import "notifications.e"
#import "setupext.e"
#import "slickc.e"
#import "stdprocs.e"
#import "surround.e"
#import "tags.e"
#import "util.e"
#endregion

using se.lang.api.LanguageSettings;

/**
 *
 * SAS language support
 *
 */

static const SAS_PREFIXES=    ' proc data ';
static const BEGIN_SAS_LOG= '------------------Begin SAS Log File------------------';
static const END_SAS_LOG= '-------------------End SAS Log File-------------------';
static const BEGIN_SAS_EXECUTE= '--------------------Executing SAS---------------------';
static const END_SAS_EXECUTE= '----------------SAS Finished Executing----------------';

static _str gtkinfo;
static _str gtk;
static _str log_file = '';
static int sTimerHandles:[];
static SYNTAX_EXPANSION_INFO sas_space_words:[] = {
   'proc'     => { "proc ... ;" },
   'data'     => { "data ... ; ... run;" },
   '%macro'   => { "%macro ... ; ... %mend ... ;" },
   'if'       => { "if ... then ..." },
   'do'       => { "do ... ; ... end;" },
};

defeventtab sas_keys;
def '('=auto_functionhelp_key;
def ' '=sas_space;

definit()
{
   sTimerHandles=null;
}

/**
 * Build the SAS tag file which contains all the built-in SAS
 * functions and documentation found in "SAS.tagdoc".
 *
 * @param tfindex Name index of standard SAS tag file
 * @return 0 on success, nonzero on error.
 */
int _sas_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   return(ext_MaybeBuildTagFile(tfindex,'sas','sas',"SAS Libraries", "", false, withRefs, useThread, forceRebuild));
}

/**
 * Scan for function definitions in a SAS file.
 */
int sas_proc_search(_str &proc_name, int find_first)
{
   static _str kw_map:[];
   if (kw_map._isempty()) {
      kw_map:["%global"] = "gvar";
      kw_map:["%let"]    = "const";
      kw_map:["%macro"]  = "define";
      kw_map:["proc"]    = "proc";
      kw_map:["data"]    = "prop";
      kw_map:["var"]     = "lvar";
   }

   static _str re_map:[];
   if (re_map._isempty()) {
      re_map:["TYPE"] = "[%](let|macro|global)|proc|data";
      re_map:["RETURN"] = "?#";
      re_map:["ARGS"] = "?#";
   }

   return _generic_regex_proc_search('^( *:i |) *<<<TYPE>>>:b<<<NAME>>>(=<<<RETURN>>>;|\(<<<ARGS>>>\)|)', proc_name, find_first!=0, "", re_map, kw_map);
}

/**
 * @see _c_fcthelp_get_start
 */
int _sas_fcthelp_get_start(_str (&errorArgs)[],
                           bool OperatorTyped,
                           bool cursorInsideArgumentList,
                           int &FunctionNameOffset,
                           int &ArgumentStartOffset,
                           int &flags,
                           int depth=0)
{
   return(_c_fcthelp_get_start(errorArgs,OperatorTyped,
                               cursorInsideArgumentList,
                               FunctionNameOffset,
                               ArgumentStartOffset,flags,
                               depth));
}
/**
 * @see _c_fcthelp_get
 */
int _sas_fcthelp_get(_str (&errorArgs)[],
                     VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                     bool &FunctionHelp_list_changed,
                     int &FunctionHelp_cursor_x,
                     _str &FunctionHelp_HelpWord,
                     int FunctionNameStartOffset,
                     int flags,
                     VS_TAG_BROWSE_INFO symbol_info=null,
                     VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return(_c_fcthelp_get(errorArgs,
                         FunctionHelp_list,FunctionHelp_list_changed,
                         FunctionHelp_cursor_x,
                         FunctionHelp_HelpWord,
                         FunctionNameStartOffset,
                         flags, symbol_info,
                         visited, depth));
}

/**
 * Used for SAS syntax expansion on space.
 */
_command void sas_space() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   if ( command_state() ) {
      call_root_key(' ');
      return;
   }
   if ( command_state() || ! doExpandSpace(p_LangId) || p_SyntaxIndent<0 ||
        _in_comment() || sas_expand_space() ) {
      if ( command_state() ) {
         call_root_key(' ');
      } else {
         keyin(' ');
      }
   } else if (_argument=='') {
      _undo('S');
   }
   sas_codehelp_key();
}
bool _sas_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return return_true_if_uses_syntax_indent_property;
}

/**
 * Provides syntax expansion on space for SAS.
 * 
 * @return 
 */
static _str sas_expand_space()
{
   if(_EmbeddedLanguageKey(last_event())) return(0);

   status := 0;
   get_line(auto tline);
   if (p_TruncateLength) {
      tline=substr(tline,1,_TruncateLengthC());
      tline=strip(tline,'T');
   }
   line := strip(tline,'T');
   if ( p_col!=text_col(_rawText(line))+1 ) {
      return(1);
   }
   word := strip(tline,'L');
   if ( pos(' 'word'=',' 'def_cobol_levels' ') ) {
      typeless column=eq_name2value(word,def_cobol_levels);
      if ( isinteger(column) ) {
         replace_line(indent_string(column-1):+strip(tline)' ');
         _end_line();
         return(0);
      }
   }
   aliasfilename := "";
   sample := strip(line);
   orig_word := lowcase(strip(line));
   word=min_abbrev2(orig_word,sas_space_words,'',aliasfilename);

   // can we expand an alias?
   if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return expandResult;
   }

   if ( word=='' ) return(1);
   int leading_chars=verify(line,' '\t,'')-1;
   linenum_space := substr(line,1,leading_chars);
   int linenum_chars=text_col(linenum_space,leading_chars);
   leading_space := substr('',1,text_col(linenum_space,linenum_chars));
   set_surround_mode_start_line();

   doNotify := true;
   if (word=='proc') {
      replace_line(_word_case(linenum_space:+'proc  ;',false,sample));
      p_col=text_col(leading_space)+6;
   } else if (word=='if') {
      replace_line(_word_case(linenum_space:+'if  then',false,sample));
      p_col=text_col(leading_space)+4;
      set_surround_mode_end_line(p_line+1,0);
   } else if (word=='data') {
      replace_line(_word_case(linenum_space:+'data  ;',false,sample));
      insert_line(_word_case(linenum_space:+'run;',false,sample));
      up();
      p_col=text_col(leading_space)+6;
   } else if (word == '%macro') {
      replace_line(_word_case(linenum_space:+'%macro  ;',false,sample));
      insert_line(_word_case(linenum_space:+'%mend  ;',false,sample));
      up();
      p_col=text_col(leading_space)+8;
   } else if (word=='do') {
      replace_line(_word_case(linenum_space:+'do  ;',false,sample));
      insert_line(_word_case(linenum_space:+'end;',false,sample));
      set_surround_mode_end_line();
      up();
      p_col=text_col(leading_space)+4;
   } else  {
      newLine := linenum_space:+word' ';
      replace_line(newLine);
      _end_line();search('([~ ]|^)\c','@rh-');++p_col;
      doNotify = (newLine != tline);
   }

   if (!do_surround_mode_keys(false, NF_SYNTAX_EXPANSION) && doNotify) {
      // notify user that we did something unexpected
      notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
   }

   return status;
}

_str _sas_keyword_case(_str s, bool confirm=true, _str sample="")
{
   return _word_case(s, confirm, sample);
}

int _sas_get_syntax_completions(var words, _str prefix="", int min_abbrev=0)
{
   return AutoCompleteGetSyntaxSpaceWords(words, sas_space_words, prefix, min_abbrev);
}
/**
 * SAS codehelp key - used for syntax expansion on space.
 */
_command void sas_codehelp_key() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if (!command_state()) {
      left();
      int cfg=_clex_find(0,'g');
      right();
      if (!_in_comment() && cfg!=CFG_STRING) {
         int p;
         save_pos(p);
         word_chars := _clex_identifier_chars();
         if (pos('['word_chars']',get_text(),1,'r')) {
            left();
         }
         gtk=sas_prev_sym();
         _str word_before=(gtk==TK_ID)? gtkinfo:'';
         word_before=upcase(strip(word_before));
         gtk=sas_prev_sym_same_line();
         _str word_before_word_before=(gtk==TK_ID)? gtkinfo:'';
         word_before_word_before=upcase(strip(word_before_word_before));
         int word_before_col=(word_before_word_before!='')? p_col:1;
         restore_pos(p);
         if (word_before=='') return;
         if ((pos(' 'word_before' ',SAS_PREFIXES,1,'i') &&
             (_GetCodehelpFlags()&VSCODEHELPFLAG_AUTO_LIST_MEMBERS))) {
            _do_list_members(OperatorTyped:true, DisplayImmediate:false);
         }
      }
   }
}

/**
 * Borrowed from cob_prev_sym_same_line().
 * 
 * @return 
 */
static _str sas_prev_sym_same_line()
{
   orig_linenum := p_line;
   _str result=sas_prev_sym();
   //messageNwait('h1 gtkinfo='gtkinfo);
   if (p_line!=orig_linenum && (p_col<=_text_colc() || p_line!=orig_linenum-1)) {
      //messageNwait('h2');
      gtk=gtkinfo="";
      return(gtk);
   }
   return(result);
}

/**
 * Borrowed from cob_prev_sym().
 * 
 * @return 
 */
static _str sas_prev_sym()
{
   ch := get_text();
   if (ch=="\n" || ch=="\r" || ch=='' || _clex_find(0,'g')==CFG_COMMENT) {
      int status=_clex_skip_blanks('-');
      if (status) {
         gtk=gtkinfo='';
         return(gtk);
      }
      return(sas_prev_sym());
   }
   if (_clex_find(0,'g')==CFG_LINENUM) {
      int clex_status=_clex_find(LINENUM_CLEXFLAG,'n-');
      if (clex_status) {
         gtk=gtkinfo='';
         return(gtk);
      }
      return(sas_prev_sym());
   }
   if ((ch=='"' || ch=="'" ) && _clex_find(0,'g')==CFG_STRING) {
      int end_col=p_col+1;
      for (;;) {
         if (p_col==1) break;
         left();
         if(_clex_find(0,'g')!=CFG_STRING) {
            right();
            break;
         }
      }
      gtk=TK_STRING;
      gtkinfo=_expand_tabsc(p_col,end_col-p_col);
      if (p_col==1) {
         up();_end_line();
      } else {
         left();
      }
      return(gtk);
   }
   word_chars := _clex_identifier_chars();
   if (pos('['word_chars']',ch,1,'r')) {
      int end_col=p_col+1;
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
   if (ch==':' && get_text()==':') {
      left();
      gtk=gtkinfo='::';
      return(gtk);
   }
   gtk=gtkinfo=ch;
   return(gtk);

}

/**
 * Get SAS Root location from registry
 * 
 * @returns Path to SAS root including trailing slash if found in registry; empty string otherwise
 * 
 **/
_str getSASRoot()
{
   if (_isUnix()) {
      return "";
   }
   key := 'Software\SAS Institute Inc.\The SAS System';
   sashome := _ntRegGetLatestVersionValue(HKEY_LOCAL_MACHINE, key, '', 'DefaultRoot');
   if (sashome=="") {
      return "";
   }
   sashome :+= '\';

   return sashome;
}

/**
 * Helper function used to execute SAS commands and display
 * the log file in the process buffer.
 * 
 * @return 
 */
_command void sassubmit()
{
   _str full_name=p_buf_name;
   _str filename;
   _str file_ext;
   sas_command := "";
   int process_id;
   log_file = '';

   if (p_LangId != 'sas') {
      message('Warning:  This file does not appear to be a SAS file.');
   }
   int i;
   for (i=1;i<=arg();++i) {
      sas_command :+= arg(i);
      // parse file names out of the args
      if (pos('log=',arg(i))) {
         // log file
         parse arg(i) with 'log=' log_file;
      }
   }
   // check to see if the command line appears to include a valid sas executable
   sas_executable := "";
   parse arg(1) with sas_executable . ;
   if (!file_exists(sas_executable) && pos('sas',sas_executable,1,'I')) {
      _str sas_path = path_search('sas','PATH','P');
      if (sas_path == '') {
         sas_path = getSASRoot();
         if (sas_path =='') {
            _message_box('Error:  The SAS executable could not be found.  Add the directory of the SAS executable to your PATH.');
            return;
         }
         sas_command = sas_path:+sas_command;
      }
   }
   // if no log file name was found, assume it is
   // the same as the sas source file, in the same location
   if (log_file=='') {
      log_file = _strip_filename(full_name,'E'):+'.log';
   }
   int status = start_process(false,true,true);
   if (!_process_info('R')) {
      // could not invoke the process buffer
      message('ERROR: - You will not be able to view the SAS log file automatically.');
   } else {
      clear_pbuffer();
      status = _process_info('R');
      _str current_line;
      up();
      insert_line(BEGIN_SAS_EXECUTE);
      insert_line('Executing command: 'sas_command);
   }
   shell(sas_command,'PANB','',process_id);
   ReloadFileAfterProcessTerminates(log_file,process_id);
}

/**
 * Gets called when the designated SAS command is done executing.
 * Inserts the SAS log file into the process buffer so that
 * users can see error messages.
 * 
 * @param filename
 * 
 * @return 
 */
static int sas_process_buffer(_str filename='')
{
   if (filename=='') {
      message('ERROR: Could not process the SAS log file.');
      return(1);
   }
   int temp_view_id;
   int orig_view_id;
   orig_view_id = p_window_id;
   int status = start_process(false,true,true);
   if (!_process_info('R')) {
      // could not invoke the process buffer
      message('ERROR: Could not start the build tab.');
      p_window_id = orig_view_id;
      return(status);
   }
   get_line(auto current_line);
   insert_line(END_SAS_EXECUTE);
   insert_line(BEGIN_SAS_LOG);
   if (def_line_insert=='B') {
      down();
   } else {
      insert_line('');
   }
   start_line := p_line;
   bottom_of_buffer();
   up();
   status = fix_sas_log(filename);
   if (status == 1) {
      message('ERROR: Could not process the SAS log file.');
      return(status);
   }
   status = search(current_line,'@h');
   bottom_of_buffer();
   up();
   insert_line(END_SAS_LOG);
   p_line = start_line;
   _begin_line();
   set_next_error();
   return(0);
}

/**
 * Fixes the SAS log file ouput by removing line breaks and triplicate data.
 * 
 * @param filename
 * 
 * @return 
 */
int fix_sas_log(_str filename)
{
   int temp_view_id, orig_view_id;
   int status = _open_temp_view(filename,temp_view_id,orig_view_id);
   if (status) {
      // open temp view failed
      return(1);
   }
   if (machine()=='WINDOWS') {
      _str curr_buf=p_buf_name;
      curr_buf=_maybe_quote_filename(curr_buf);
      top();
      up();
      int changes_made;
      status = search('\x0D[~\x0A]','@Rh','\x0D\x0A',changes_made);
   }
   // now delete all duplicate lines
   _remove_duplicates();
   int new_markid=_alloc_selection();    
   top();
   status = _select_line(new_markid);
   bottom();
   status=_select_line(new_markid);
   if (status) {
      clear_message();
      _delete_temp_view(temp_view_id);
      p_window_id = orig_view_id;
      return(1);
   }
   p_window_id = orig_view_id;
   status=_copy_to_cursor(new_markid);
   _free_selection(new_markid);
   _delete_temp_view(temp_view_id);
   return(status);
}

/**
 * Part 2 of the timer used to detect when the designated SAS command
 * is done executing.
 * 
 * @param filename
 * @param pid
 */
static void ReloadFileAfterProcessTerminates2(_str NameAndId)
{
   _str filename=parse_file(NameAndId);
   filename=strip(filename,'B','"');
   int pid=(int)NameAndId;
   if (!_IsProcessRunning(pid)) {
      _kill_timer(sTimerHandles:[pid]);
      sTimerHandles._deleteel(pid);
      int status = sas_process_buffer(filename);
      if (status) {
         message('Unable to display SAS log file.');
      }
      refresh();
   }
}

/**
 * Timer used to detect when the designated SAS command
 * is done executing.
 * 
 * @param filename
 * @param pid
 */
void ReloadFileAfterProcessTerminates(_str filename,int pid)
{
   filename=_maybe_quote_filename(filename);
   sTimerHandles:[pid]=_set_timer(1000,ReloadFileAfterProcessTerminates2,filename' 'pid);
}
