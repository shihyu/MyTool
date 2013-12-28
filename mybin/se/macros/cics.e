////////////////////////////////////////////////////////////////////////////////////
// $Revision: 48910 $
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
#include "autocomplete.sh"
#include "color.sh"
#require "se/lang/api/LanguageSettings.e"
#import "adaptiveformatting.e"
#import "c.e"
#import "cbrowser.e"
#import "codehelp.e"
#import "codehelputil.e"
#import "context.e"
#import "cutil.e"
#import "math.e"
#import "pmatch.e"
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#endregion

using se.lang.api.LanguageSettings;

/*
   Support Functions for CICS embedded in cobol
*/

// used by _CreateLanguage
#define CICS_MODE_NAME        'CICS'
#define CICS_LANGUAGE_ID      'cics'

/**
 * @deprecated Use {@link LanguageSettings_API}
 */
boolean def_cics_autocase=0;

/** 
 * These are used by cics_next_sym() and cics_prev_sym(). 
 */
static _str gtkinfo;
static _str gtk;
static int gtklen;

// used by _cics_fcthelp_get
static _str gLastContext_FunctionReplaced;
static _str gLastContext_FunctionName;
static int gLastContext_FunctionOffset;

defeventtab cics_keys;
def  ' '= cics_space;
def  '-'= cob_maybe_case_word;
def  '0'-'9'= cob_maybe_case_word;
def  'A'-'Z'= cob_maybe_case_word;
def  '_'= cob_maybe_case_word;
def  'a'-'z'= cob_maybe_case_word;
def  'ENTER'= cics_enter;
def  'BACKSPACE'= cob_maybe_case_backspace;

// called when CICS module is loaded
defload()
{
   _str setup_info='MN='CICS_MODE_NAME',TABS=+8,MA=1 74 1,':+
               'KEYTAB='CICS_MODE_NAME'-keys,WW=0,IWT=0,ST='DEFAULT_SPECIAL_CHARS',':+
               'IN=2,WC=A-Za-z0-9"_\-,LN='CICS_MODE_NAME',CF=1,';
   _str compile_info='0 cics *;';
   _str syntax_info='4 1 1 1 4 1 0';
   _str be_info='';
   int kt_index=0;
   _CreateLanguage(CICS_LANGUAGE_ID, CICS_MODE_NAME,
                   setup_info, compile_info, syntax_info, be_info);
   _CreateExtension('cics', CICS_LANGUAGE_ID);
}

/**
 * This commands switches the current buffer into CICS mode.
 */
_command void cics_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage('cics');
}

/**
 * Handler for ENTER key in CICS mode
 */
_command void cics_enter() name_info(','VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   if (ispf_common_enter()) return;
   if ( command_state()) {
      call_root_key(ENTER);
   } else if ( p_window_state:=='I' || p_SyntaxIndent<0 || p_indent_style!=INDENT_SMART ) {
      call_root_key(ENTER);
   } else if ( _in_comment(true) ) {  
      call_root_key(ENTER);
   } else if ( _maybeSplitLineComment() ) {
      // handled
   } else if ( _cics_expand_enter() ) {  
      call_root_key(ENTER);
      if (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_MEMBERS) {
         _do_list_members(true,false);
      }
   } else if (_argument=='') {
      _undo('S');
   }
}
/**
 * Handler for SPACE key in CICS mode
 */
_command void cics_space() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if ( command_state() || ! doExpandSpace(p_LangId) || p_SyntaxIndent<0 || _in_comment() ||
        ext_expand_space()) {
      if ( command_state() ) {
         call_root_key(' ');
      } else {
         keyin(' ');
         if (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_MEMBERS) {
            _do_list_members(true,false);
         }
      }
   } else if (_argument=='') {
      _undo('S');
   }
}

/**************************************************************
  do syntax expansion later, leave this for place-holder
 **************************************************************/


/* Returns non-zero number if pass through to enter key required */
boolean _cics_expand_enter()
{
   int status=0;
   _str line; get_line(line);
   line=strip(line,'t');
   int indent_col=1;

   if (pos('(', line) && last_char(line)==')') {
      save_pos(auto p);
      p_col=pos('s');
      prev_full_word();
      indent_col=p_col;
      restore_pos(p);
      indent_on_enter(0,indent_col);
      return(false);
   }

   if (pos('(', line) && last_char(line)!=')') {
      indent_on_enter(0,pos('s')+1);
      return(false);
   }

   if (!pos('(', line)) {
      updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
      syntax_indent := p_SyntaxIndent;
      
      indent_on_enter(syntax_indent);
      return(false);
   }

   return(true);
}

/**
 * Build the CICS tag file which contains all the built-in CICS functions and documentation found in "cics.tagdoc".
 *
 * @param tfindex Name index of standard CICS tag file
 * @return 0 on success, nonzero on error.
 */
int _cics_MaybeBuildTagFile(int &tfindex)
{
   return ext_MaybeBuildTagFile(tfindex,'cics','cics',"CICS Libraries");
}

// search for CICS command matches
static int cics_is_function_name(_str name, typeless tag_files, boolean exact_match)
{
   int i=0;
   _str tag_filename=next_tag_filea(tag_files,i,false,true);
   while (tag_filename != '') {
      int status = tag_find_prefix(name,false,'');
      _str tag_name='';
      tag_get_detail(VS_TAGDETAIL_name,tag_name);
      tag_reset_find_tag();
      parse tag_name with tag_name '<' .;
      tag_name=upcase(strip(tag_name));
      if (strieq(tag_name,name)) {
         return 1;
      }
      if (!exact_match && pos(name,tag_name,1,'i')==1) {
         return 1;
      }
      tag_filename=next_tag_filea(tag_files,i,false,true);
   }
   return 0;
}

// return start offset of the CICS command section
static long cics_find_command_start()
{
   save_pos(auto p);
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);

   // try to find the beginning of the CICS statement
   long cics_offset=0;
   if (p_EmbeddedLexerName!='') {
      int status=_clex_find(0,'S-');
#ifndef CLEX_FIND_IS_WORKING
      if (status==STRING_NOT_FOUND_RC) {
         top();_begin_line();
      }
      status=_clex_find(0,'E');
      cics_offset=_QROffset();
#endif
   } else {
      if (!search('exec','-ihwCk@')) {
         cics_offset=_QROffset();
      }
   }
   restore_search(s1,s2,s3,s4,s5);
   restore_pos(p);
   return(cics_offset);
}

// search for start of parameter list
// returns 0 on success, <0 if not in param value
static int cics_find_param_start(_str &ch)
{
   long cics_offset=cics_find_command_start();

   // try to find the beginning of the CICS statement
   if (get_text()!='(') {
      save_pos(auto p);
      save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
      search('[()]|^','-rh@');
      while (get_text()==')') {
         if (find_matching_paren(true) || _QROffset() < cics_offset) {
            restore_pos(p);
            save_search(s1,s2,s3,s4);
            return(1);
         }
         left();
         search('[()]|^','-rh@');
      }
      if (get_text()!='(') {
         restore_pos(p);
         save_search(s1,s2,s3,s4,s5);
         return(1);
      }
      restore_search(s1,s2,s3,s4,s5);
   }
   ch=get_text();
   return(0);
}

/**
 * If this function is not implemented, the editor will
 * default to using _do_default_get_expression_info(), which simply
 * returns the current identifier under the cursor and no prefix
 * expression.
 * <p>
 * This function is used to get information about the code at
 * the current buffer location, including the current ID under
 * the cursor, the expression before the current ID, and other
 * supplementary information useful to list-members.
 * <p>
 * <b>Note:</b> caller must check whether text is in a comment or string.
 * <p>
 * <b>Note:</b> for now, set info_flags to 0.  In the future we could
 * have a LASTID_FOLLOWED_BY_PAREN flag and optionally do an
 * exact match instead of a prefix match.
 * <p>
 * This function is called when:
 * <ul>
 * <li> possibly operator typed like ( or .
 * <li> return 1 if not valid operator
 * <li> return 1 if expression too complex or invalid context
 * </ul>
 * <p>
 * Identifier just typed (curr char not id) or on identifier
 *
 * <p><b>CASE 1</b>: list all CICS application functions
 * <pre>EXEC CICS <i>&lt;Here&gt;</i></pre>
 * <ul>
 * <li> prefixexp=""
 * <li> lastid=""
 * <li> lastidstart_col=column after "CICS "
 * <li> infoflags=VSAUTOCODEINFO_DO_LIST_MEMBERS
 * </ul>
 *
 * <p><b>CASE 2</b>: list all CICS application functions with prefix REC
 * <pre>EXEC CICS REC<i>&lt;Here&gt;</i></pre>
 * <ul>
 * <li> prefixexp=""
 * <li> lastid="REC"
 * <li> lastidstart_col=column after "CICS "
 * <li> infoflags=VSAUTOCODEINFO_DO_LIST_MEMBERS
 * </ul>
 *
 * <p><b>CASE 3</b>: list all CICS application functions with prefix RECEIVE
 * <pre>EXEC CICS RECEIVE<i>&lt;Here&gt;</i></pre>
 * <ul>
 * <li> prefixexp=""
 * <li> lastid="RECEIVE"
 * <li> lastidstart_col=column after "CICS "
 * <li> infoflags=VSAUTOCODEINFO_DO_LIST_MEMBERS
 * </ul>
 *
 * <p><b>CASE 4</b>: list all CICS application functions with prefix "RECEIVE "
 * <pre>EXEC CICS RECEIVE <i>&lt;Here&gt;</i></pre>
 * <ul>
 * <li> prefixexp="RECEIVE "
 * <li> lastid=""
 * <li> lastidstart_col=column after "RECEIVE "
 * <li> infoflags=VSAUTOCODEINFO_DO_LIST_MEMBERS
 * </ul>
 *
 * <p><b>CASE 5</b>: list variables which can be passed as an argument here
 * <pre>EXEC CICS RECEIVE MAP(<i>&lt;Here&gt;</i></pre>
 * <ul>
 * <li> prefixexp="RECEIVE MAP("
 * <li> lastid=""
 * <li> lastidstart_col=column after "MAP("
 * <li> infoflags=VSAUTOCODEINFO_DO_LIST_MEMBERS
 * </ul>
 *
 * <p><b>CASE 6</b>: list parameters allowed for "RECEIVE MAP" function
 * <pre>EXEC CICS RECEIVE MAP(name) <i>&lt;Here&gt;</i></pre>
 * <ul>
 * <li> prefixexp="RECEIVE MAP"
 * <li> lastid=""
 * <li> lastidstart_col=column after "MAP(name) "
 * <li> infoflags=VSAUTOCODEINFO_DO_LIST_MEMBERS
 * </ul>
 *
 * <p><b>CASE 7</b>: list parameters allowed for "RECEIVE MAP" function with prefix "MAPS"
 * <pre>EXEC CICS RECEIVE MAP(name) MAPS<i>&lt;Here&gt;</i></pre>
 * <ul>
 * <li> prefixexp="RECEIVE MAP"
 * <li> lastid=""
 * <li> lastidstart_col=column after "MAP(name) "
 * <li> infoflags=VSAUTOCODEINFO_DO_LIST_MEMBERS
 * </ul>
 *
 * <p><b>CASE 8</b>: list variables which can be passed as an argument here
 * <pre>EXEC CICS RECEIVE MAP(name) MAPSSET(<i>&lt;Here&gt;</i></pre>
 * <ul>
 * <li> prefixexp="RECEIVE MAP MAPSET("
 * <li> lastid=""
 * <li> lastidstart_col=column after "MAPSET( "
 * <li> infoflags=VSAUTOCODEINFO_DO_LIST_MEMBERS
 * </ul>
 *
 * <p><b>CASE 9</b>: list variables which can be passed as an argument here with prefix "src-"
 * <pre>EXEC CICS RECEIVE MAP(name) MAPSSET(src-<i>&lt;Here&gt;</i></pre>
 * <ul>
 * <li> prefixexp="RECEIVE MAP MAPSET("
 * <li> lastid="src-"
 * <li> lastidstart_col=column after "MAPSET( "
 * <li> infoflags=VSAUTOCODEINFO_DO_LIST_MEMBERS
 * </ul>
 *
 * <p><b>CASE 10</b>: list variables which can be passed as an argument here with prefix "src-"
 * <pre>EXEC CICS RECEIVE MAP(name) MAPSSET(msname) ASIS <i>&lt;Here&gt;</i></pre>
 * <ul>
 * <li> prefixexp="RECEIVE MAP"
 * <li> lastid=""
 * <li> lastidstart_col=column after "ASIS "
 * <li> infoflags=VSAUTOCODEINFO_DO_LIST_MEMBERS
 * </ul>
 *
 * @param PossibleOperator  Last character might be an operator?
 * @param id_expinfo       (reference) VS_TAG_IDEXP_INFO which contains all the information set by this function
 * 
 *
 * @return
 *  <ul>
 *  <li>0 if successful
 *  <li>1 if expression too complex
 *  <li>2 if not valid operator
 * </ul>
 * @since 11.0
 */
int _cics_get_expression_info(boolean PossibleOperator, VS_TAG_IDEXP_INFO &idexp_info,
                              VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   // initialize reference arguments
   tag_idexp_info_init(idexp_info);
   idexp_info.info_flags=VSAUTOCODEINFO_DO_LIST_MEMBERS;

   // save seek position and search options
   typeless p, s1, s2, s3, s4;
   save_pos(p);
   save_search(s1,s2,s3,s4);

   // search for the start of the embedded context (just after EXEC CICS)
   // [IDEA] why not just search backwards for "EXEC CICS"?
   int status=0;
   long orig_seekpos=_QROffset();
   long last_seekpos=p_RBufSize;
   if (p_EmbeddedLexerName!='') {
      // YES: first search for the end of the embedded context
      status=_clex_find(0,'S');
      if (!status) {
         last_seekpos=_QROffset();
      }
      // YES: then search for the beginning of the embedded context
      //      in another words, search for non-embedded source
      restore_pos(p);
   }
   long start_seekpos=cics_find_command_start();
   _GoToROffset(start_seekpos);

   // get the CICS command name, no matter how many words it is
   typeless tag_files = tags_filenamea(p_LangId);
   _str cmd='';
   _str cmd_prefix='';
   _str cmd_found='';
   cics_next_sym();
   int cmd_col=p_col-gtklen;
   int cmd_seekpos=(int)_QROffset()-gtklen;
   int cmd_endpos=(int)_QROffset();
   while ((gtk==TK_ID || gtk==TK_NUMBER) &&
          (_QROffset() < last_seekpos) /* &&
          (orig_seekpos >= _QROffset()-gtklen)*/ ) {
      cmd_found=strip(cmd_found' 'upcase(gtkinfo));
      if (cics_is_function_name(cmd_found,tag_files,true)) {
         cmd=cmd_found;
         cmd_prefix=cmd_found;
         cmd_endpos=(int)_QROffset();
      } else if (get_text()==' ' && cics_is_function_name(cmd_found' ',tag_files,false)) {
         cmd_prefix=cmd_found;
         cmd_endpos=(int)_QROffset()+1;
      } else if (cics_is_function_name(cmd_found,tag_files,false)) {
         cmd_prefix=cmd_found;
         cmd_endpos=(int)_QROffset();
      } else if (orig_seekpos < _QROffset() &&
                 cics_is_function_name(substr(cmd_found,1,length(cmd_found)-(int)(_QROffset()-orig_seekpos)),tag_files,false)) {
         if (cmd=='') {
            cmd_prefix=cmd_found;
            cmd_endpos=(int)_QROffset();
         }
         break;
      } else if (cmd_prefix!='') {
         break;
      }
      cics_next_sym();
      if (_QROffset()-gtklen > last_seekpos) {
         gtk='';
         gtkinfo='';
         gtklen=0;
      }
   }
   //say("_cics_getidexp: found="cmd_found' prefix='cmd_prefix' cmd='cmd);

   // is the cursor within the CICS command name?
   if (cmd_seekpos <= orig_seekpos && orig_seekpos <= cmd_endpos) {
      _GoToROffset(cmd_endpos);
      idexp_info.lastid=_expand_tabsc(cmd_col,p_col-cmd_col);
      idexp_info.lastidstart_col=cmd_col;
      idexp_info.lastidstart_offset=cmd_seekpos;
      idexp_info.info_flags|=VSAUTOCODEINFO_ALLOW_SPACE_IN_LIST_MEMBERS;
      restore_pos(p);
      restore_search(s1,s2,s3,s4);
      return(0);
   }

   // is the cursor before the CICS command name?
   if (orig_seekpos < cmd_seekpos && idexp_info.lastid!='') {
      idexp_info.lastid='';
      restore_pos(p);
      restore_search(s1,s2,s3,s4);
      return(1);
   }

   // we have found the CICS command name,
   // that is our prefix expression
   idexp_info.prefixexp=cmd;

   // cursor is past the command name, but before first parameter
   if ((gtk==TK_ID||gtk==TK_NUMBER) && cmd_endpos < orig_seekpos && orig_seekpos <= _QROffset()) {
      if (cmd=='') {
         restore_pos(p);
         idexp_info.lastid=cmd_found;
         idexp_info.lastid=_expand_tabsc(cmd_col,p_col-cmd_col);
         idexp_info.lastidstart_col=cmd_col;
         idexp_info.lastidstart_offset=cmd_seekpos;
         idexp_info.info_flags|=VSAUTOCODEINFO_ALLOW_SPACE_IN_LIST_MEMBERS;
      } else {
         idexp_info.lastid=gtkinfo;
         idexp_info.lastidstart_col=(p_col-gtklen);
         idexp_info.lastidstart_offset=((int)_QROffset()-gtklen);
      }
      restore_pos(p);
      restore_search(s1,s2,s3,s4);
      return(0);

   }

   // go back to original seek position
   word_chars := _clex_identifier_chars();
   status=0;
   restore_pos(p);
   if (PossibleOperator) {

      left();
      _str ch=get_text();
      if (!cics_find_param_start(ch)) {
         idexp_info.info_flags=VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN|VSAUTOCODEINFO_DO_FUNCTION_HELP;
         idexp_info.lastidstart_col=p_col;  // need this for function pointer case
         left();
         search('[~ \t]|^','-rh@');
         // maybe there was a function pointer expression
         if (pos('[~'word_chars']',get_text(),1,'r')) {
            status=1;
         } else {
            int end_col=p_col+1;
            search('[~'word_chars']\c|^\c','-rh@');
            idexp_info.lastid=_expand_tabsc(p_col,end_col-p_col);
            idexp_info.otherinfo=_expand_tabsc(p_col,end_col-p_col);
            //restore_pos(p);
            //lastid='';
            idexp_info.lastidstart_col=p_col;
            idexp_info.lastidstart_offset=(int)point('s');
         }
      } else if (ch==' ') {
         idexp_info.info_flags=VSAUTOCODEINFO_DO_FUNCTION_HELP|VSAUTOCODEINFO_ALLOW_SPACE_IN_LIST_MEMBERS;
         right();
         idexp_info.lastid='';
         idexp_info.lastidstart_col=p_col;
         idexp_info.lastidstart_offset=(int)point('s');
      } else {
         status=1;
      }

   } else {

      _str ch=get_text();
      int done=0;
      // IF we are not on an id character.
      if (pos('[~'word_chars']',get_text(),1,'r')) {
         int first_col = 1;
         if (p_col > 1) {
            first_col=0;
            left();
         }
         if (pos('[~'word_chars']',get_text(),1,'r')) {
            right();
            if (get_text()=='(') {
               idexp_info.info_flags|=VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN;
            }
            idexp_info.lastid="";
            idexp_info.lastidstart_col=p_col-first_col;
            idexp_info.lastidstart_offset=(int)point('s');
            done=1;
         }
      }
      if(!done) {
         int old_TruncateLength=p_TruncateLength;p_TruncateLength=0;
         _TruncSearchLine('[~'word_chars']|$','r');
         int end_col=p_col;
         // Check if this is a function call
         _TruncSearchLine('[~ \t]|$','r');
         if (get_text()=='(') {
            idexp_info.info_flags|=VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN;
         }
         p_col=end_col;

         left();
         search('[~'word_chars']\c|^\c','-rh@');
         idexp_info.lastid=_expand_tabsc(p_col,end_col-p_col);
         idexp_info.lastidstart_col=p_col;
         idexp_info.lastidstart_offset=(int)point('s');
         p_TruncateLength=old_TruncateLength;

      }

      // Check if this is a function call
      left();
      ch=get_text();
      if (!cics_find_param_start(ch)) {
         cics_prev_sym();
         if (gtk=='(') {
            idexp_info.info_flags=VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN|VSAUTOCODEINFO_DO_FUNCTION_HELP;
            cics_prev_sym();
            if (gtk==TK_ID || gtk==TK_NUMBER) {
               idexp_info.otherinfo=gtkinfo;
            }
         }
      }
   }

   restore_pos(p);
   restore_search(s1,s2,s3,s4);
   return(status);
}

/**
 * Useful utility function for getting the next token, symbol, or
 * identifier from the current cursor location.  Returns results
 * through the global variables gtk and gtkinfo.  (See above).
 * Returns the value assigned to gtk (a string)
 *
 * @return next token or ''
 */
static _str cics_next_sym()
{
   if (p_col>_text_colc()) {
      if(down()) {
         gtk=gtkinfo='';
         gtklen=0;
         return(gtk);
      }
      _begin_line();
   }
   int status=0;
   _str ch=get_text();
   if (ch=='' || (ch=='*' && _clex_find(0,'g')==CFG_COMMENT)) {
      status=_clex_skip_blanks();
      if (status) {
         gtk=gtkinfo='';
         gtklen=0;
         return(gtk);
      }
      return(cics_next_sym());
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
      gtklen=length(gtkinfo);
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
         gtklen=length(gtkinfo);
         return(gtk);
      }
      search('[~'word_chars']|$','@rh');
      gtk=TK_ID;
      gtkinfo=_expand_tabsc(start_col,p_col-start_col);
      gtklen=length(gtkinfo);
      return(gtk);
   }
   right();
   gtk=gtkinfo=ch;
   gtklen=length(gtkinfo);
   return(gtk);
}

/**
 * Useful utility function for getting the previous token on the
 * same linenext token, symbol, or '' if the previous token is
 * on a different line.
 *
 * @return _str
 *    previous token or '' if no previous token on current line
 */
static _str cics_prev_sym_same_line()
{
   if (gtk!='(') {
      return(cics_prev_sym());
   }
   int orig_linenum=p_line;
   _str result=cics_prev_sym();
   if (p_line!=orig_linenum && (p_col<=_text_colc() || p_line!=orig_linenum-1) ) {
      gtk=gtkinfo="";
      gtklen=0;
      return(gtk);
   }
   return(result);
}

/**
 * Useful utility function for getting the previous token, symbol, or
 * identifier from the current cursor location.  Returns results
 * through the global variables gtk and gtkinfo.  (See above).
 * Returns the value assigned to gtk (a string).
 *
 * @return _str
 *    previous token or ''
 */
static _str cics_prev_sym()
{
   _str ch=get_text();
   if (ch=="\n" || ch=="\r" || ch=='' || (ch=='/' && _clex_find(0,'g')==CFG_COMMENT)) {
      int status=_clex_skip_blanks('-');
      if (status) {
         gtk=gtkinfo='';
         gtklen=0;
         return(gtk);
      }
      return(cics_prev_sym());
   }
   int end_col=0;
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
         gtklen=length(gtkinfo);
      } else {
         search('[~'word_chars']\c|^\c','@rh-');
         gtk=TK_ID;
         gtkinfo=_expand_tabsc(p_col,end_col-p_col);
         gtklen=length(gtkinfo);
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
         gtklen=0;
         return(gtk);
      }
      gtk=gtkinfo=ch;
      gtklen=length(gtkinfo);
      return(gtk);
   }
   left();
   gtk=gtkinfo=ch;
   gtklen=length(gtkinfo);
   return(gtk);

}

// list matching arguments and insert into tree control (current object)
static void cics_list_arguments(int tree_wid, int tree_index,
                                typeless tag_files, _str prefixexp, _str lastid_prefix,
                                int &num_items, int max_items)
{
   int cics_file_id=0;
   int cics_line_no=0;
   int i=0;
   _str tag_filename = next_tag_filea(tag_files,i,false,true);
   while (tag_filename!='') {
      int status = tag_find_prefix(prefixexp);
      while (!status) {

         _str cics_file_name;
         tag_get_detail(VS_TAGDETAIL_file_name,cics_file_name);
         tag_get_detail(VS_TAGDETAIL_file_line,cics_line_no);
         tag_get_detail(VS_TAGDETAIL_file_id,cics_file_id);
         if (cics_file_name!='' && isnumber(cics_line_no) && cics_line_no>0) {
            // parse signature and map out argument ranges
            _str signature='';
            tag_get_detail(VS_TAGDETAIL_arguments,signature);
            int  arg_pos  = 0;
            _str argument = cb_next_arg(signature, arg_pos, 1);
            while (argument != '') {
               if (lastid_prefix=='' || pos(lastid_prefix,argument,1,'i')==1) {
                  int k=tag_tree_insert_tag(tree_wid,tree_index,0,1,TREE_ADD_AS_CHILD,argument,'param',cics_file_name,cics_line_no,'',0,0);
                  if (k>0) {
                     tag_tree_set_user_info(tree_wid,k,0,cics_file_id,(int)cics_line_no);
                  }
                  num_items++;
                  if (num_items++ > max_items) {
                     break;
                  }
               }
               argument = cb_next_arg(signature, arg_pos, 0);
            }
         }
         status = tag_next_prefix(prefixexp);
      }
      tag_reset_find_tag();
      tag_filename = next_tag_filea(tag_files,i,false,true);
   }
}

boolean _cics_autocomplete_after_replace(AUTO_COMPLETE_INFO &word,
                                         VS_TAG_IDEXP_INFO &idexp_info, 
                                         _str terminationKey="")
{

   // does this caption have a parenthesis? (is it a function?)
   have_paren := false;
   caption := word.displayWord;
   info_flags := 0;
   last_id := word.insertWord;
   if (idexp_info != null) {
      info_flags = idexp_info.info_flags;
      last_id = idexp_info.lastid;
   }
   if (pos('(', caption)) {
      caption = substr(caption, 1, pos('S')-1);
      have_paren = true;
   }
   if (pos('<',caption)) {
      gLastContext_FunctionReplaced=caption;
      caption = strip(substr(caption, 1, pos('S')-1));
   }
   if (pos('[',caption)) {
      caption = substr(caption, 1, pos('S')-1);
      have_paren=(terminationKey=='(');
   }
   boolean do_space=false;
   boolean start_function_help=true;
   if (terminationKey:==' ' &&
       (_GetCodehelpFlags() & VSCODEHELPFLAG_SPACE_INSERTS_SPACE)) {
       if (substr(caption, length(last_id)+1, 1)==' ' && pos(last_id, caption, 1, 'i')==1) {
          start_function_help=false;
       }
       do_space=true;
   }
   
   // if we have an open paren, then insert open paren and go directly
   // into function help, unless name is already followed by a paren.
   // kind of language specific...
   if (have_paren && terminationKey=="" &&
       !(info_flags&VSAUTOCODEINFO_IN_JAVADOC_COMMENT) &&
       !(info_flags&VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) &&
       (_GetCodehelpFlags() & VSCODEHELPFLAG_INSERT_OPEN_PAREN)) {
      last_event('(');
      auto_functionhelp_key();
      return false;
   }
   if (do_space) {
      last_event(' ');
      if (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_FUNCTION_HELP) {
         if (start_function_help) {
            _do_function_help(true,false);
         }
      }
      if (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_MEMBERS) {
         _do_list_members(true,false);
      }
      return false;
   }

   return true;
}

/**
 * <B>Hook Function</B> -- _[ext]_find_context_tags
 * <p>
 * Find a list of tags matching the given identifier after
 * evaluating the prefix expression.
 *
 * @param errorArgs         array of strings for error message arguments
 *                          refer to codehelp.e VSCODEHELPRC_*
 * @param prefixexp         prefix of expression (from _[ext]_get_expression_info
 * @param lastid            last identifier in expression
 * @param lastidstart_offset seek position of last identifier
 * @param info_flags        bitset of VS_CODEHELPFLAG_*
 * @param otherinfo         used in some cases for extra information
 *                          tied to info_flags
 * @param find_parents      for a virtual class function, list all
 *                          overloads of this function
 * @param max_matches       maximum number of matches to locate
 * @param exact_match       if true, do an exact match, otherwise
 *                          perform a prefix match on lastid
 * @param case_sensitive    if true, do case sensitive name comparisons
 * @param visited           hash table of prior results
 * @param depth             depth of recursive search
 *
 * @return
 * The number of matches found or <0 on error (one of VSCODEHELPRC_*,
 * errorArgs must be set).
 */
int _cics_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                         _str lastid,int lastidstart_offset,
                         int info_flags,typeless otherinfo,
                         boolean find_parents,int max_matches,
                         boolean exact_match,boolean case_sensitive,
                         int filter_flags=VS_TAGFILTER_ANYTHING,
                         int context_flags=VS_TAGCONTEXT_ALLOW_locals,
                         VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   //say("_cics_find_context_tags("prefixexp","lastid","otherinfo")");
   errorArgs._makeempty();
   tag_clear_matches();
   num_matches := 0;
   tag_files := tags_filenamea(p_LangId);
   if ((context_flags & VS_TAGCONTEXT_ONLY_locals) ||
       (context_flags & VS_TAGCONTEXT_ONLY_this_file)) {
      tag_files._makeempty();
   }

   // no prefix expression, list CICS function names
   if (prefixexp == '') {

      tag_list_context_globals(0,0,lastid,false,tag_files,
                               VS_TAGFILTER_PROTO,
                               VS_TAGCONTEXT_ANYTHING,
                               num_matches,max_matches,
                               exact_match,case_sensitive,
                               visited, depth);
      tag_list_context_globals(0,0,lastid' ',false,tag_files,
                               VS_TAGFILTER_PROTO,
                               VS_TAGCONTEXT_ANYTHING,
                               num_matches,max_matches,
                               false,case_sensitive);

   // prefix expression is not null, but no parameter name, so list parameters
   } else if (otherinfo == '') {

      tag_list_context_globals(0,0,prefixexp,false,tag_files,
                               VS_TAGFILTER_PROTO,
                               VS_TAGCONTEXT_ANYTHING,
                               num_matches,max_matches,
                               exact_match,case_sensitive,
                               visited, depth);
      tag_list_context_globals(0,0,prefixexp' ',false,tag_files,
                               VS_TAGFILTER_PROTO,
                               VS_TAGCONTEXT_ANYTHING,
                               num_matches,max_matches,
                               false,case_sensitive);

   // argument to parameter, list data members in current context
   } else {
      int cur_line_no=0;
      int cur_tag_flags=0;
      int cur_type_id=0;
      _str cur_class_name='';
      _str cur_tag_name='';
      _str cur_type_name='';
      _str cur_class_only='';
      _str cur_package_name='';
      int context_id = tag_get_current_context(cur_tag_name,cur_tag_flags,
                                               cur_type_name,cur_type_id,
                                               cur_class_name,cur_class_only,
                                               cur_package_name);
      tag_files = tags_filenamea('cob');
      //int pushtag_flags=VS_TAGFILTER_ANYDATA;
      //int context_flags=VS_TAGCONTEXT_ANYTHING;
      if (cur_class_name=='') {
         cur_class_name=cur_class_name;
         tag_list_any_symbols(0, 0, lastid, null,
                              filter_flags, 
                              context_flags|VS_TAGCONTEXT_ALLOW_locals,
                              num_matches,max_matches,
                              exact_match, case_sensitive);
         tag_list_symbols_in_context( lastid, cur_class_name, 
                                      0, 0, null, p_buf_name, 
                                      num_matches, max_matches, 
                                      filter_flags, context_flags, 
                                      exact_match, case_sensitive, 
                                      visited, depth );
      }
      if (cur_class_name!='') {
         tag_list_in_class(lastid,cur_class_name,
                           0,0,tag_files,
                           num_matches,max_matches,
                           filter_flags,context_flags,
                           exact_match,case_sensitive,
                           null,null,visited);
      }
   }

   // Return 0 indicating success if anything was found
   errorArgs[1] = strip(upcase(prefixexp)' 'upcase(lastid));
   return (num_matches <= 0)? VSCODEHELPRC_NO_SYMBOLS_FOUND:0;
}


/**
 * Context Tagging&reg; hook function for function help.  Finds the start
 * location of a function call and the function name.
 *
 * @param errorArgs array of strings for error message arguments
 *                  refer to codehelp.e VSCODEHELPRC_
 * @param OperatorTyped
 *                  When true, user has just typed last
 *                  character of operator.
 *                  Example: <CODE>p-></CODE>&lt;Cursor Here&gt;
 *                  This should be false if cursorInsideArgumentList is true.
 * @param cursorInsideArgumentList
 *                  When true, user requested function help
 *                  when the cursor was inside an argument list.
 *                  Example: <CODE>MessageBox(...,</CODE>&lt;Cursor Here&gt;<CODE>...)</CODE>
 *                  Here we give help on MessageBox
 * @param FunctionNameOffset
 *                  (reference) Offset to start of function name.
 * @param ArgumentStartOffset
 *                  (reference) Offset to start of first argument
 * @param flags     (reference) function help flags
 * @return <UL>
 *         <LI>0    Successful
 *         <LI>VSCODEHELPRC_CONTEXT_NOT_VALID
 *         <LI>VSCODEHELPRC_NOT_IN_ARGUMENT_LIST
 *         <LI>VSCODEHELPRC_NO_HELP_FOR_FUNCTION
 *         </UL>
 */
int _cics_fcthelp_get_start(_str (&errorArgs)[],
                           boolean OperatorTyped,
                           boolean cursorInsideArgumentList,
                           int &FunctionNameOffset,
                           int &ArgumentStartOffset,
                           int &flags
                          )
{
   //say("_cics_fcthelp_get_start");
   errorArgs._makeempty();
   flags=0;
   _str ch='';
   int status=0;
   typeless orig_pos;
   save_pos(orig_pos);
   if (!ginFunctionHelp && cursorInsideArgumentList) {
      status=search('[()]','-rh@xcs');
      if (!status) {
         ch=get_text();
      }
      restore_pos(orig_pos);
   }

   long cics_offset=cics_find_command_start();
   int orig_col=p_col;
   int orig_line=p_line;
   status=search('[()]','-rh@xcs');
   if (!status && p_line==orig_line && p_col==orig_col) {
      status=repeat_search();
   }
   ArgumentStartOffset = -1;
   word_chars := _clex_identifier_chars();
   for (;;) {
      if (status) {
         break;
      }
      ch=get_text();

      // close parenthesis, just skip over the matched pair
      if (ch==')' && find_matching_paren(true)) {
         restore_pos(orig_pos);
         return(1);
      }
      // scanned past the start of the command?
      if (_QROffset() < cics_offset) {
         if (ArgumentStartOffset < 0) {
            _GoToROffset(cics_offset);
            search('[^ \t]','@rh');
            FunctionNameOffset=(int)point('s');
            ArgumentStartOffset=(int)point('s');
            restore_pos(orig_pos);
            return(0);
         } else {
            break;
         }
      }

      typeless p,p1,p2,p3,p4;
      save_pos(p);
      if(p_col==1){up();_end_line();} else {left();}
      save_search(p1,p2,p3,p4);
      // clex_skip_blanks hangs in embedded CICS
      // I think that _clex_find has a bug.
      //_clex_skip_blanks('-');
      search('[~ \t\n\r]','-rh@x');
      restore_search(p1,p2,p3,p4);
      _str ch1=get_text();
      restore_pos(p);

      // open parenthese, get the identifier before it
      if (ch=='(') {
         if (pos('['word_chars']',ch1,1,'r')) {
            ArgumentStartOffset=(int)point('s')+1;
         } else {
            if (OperatorTyped && ArgumentStartOffset== -1 && ch1!=')') {
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            if (ch1==')') {
               ArgumentStartOffset=(int)point('s')+1;
            }
         }
      }

      // next please...
      status=repeat_search();
   }
   if (ArgumentStartOffset>=0) {
      goto_point(ArgumentStartOffset);
   }
   ArgumentStartOffset=(int)point('s');
   left();
   left();
   search('[~ \t]|^','-rh@');
   if (pos('[~'word_chars']',get_text(),1,'r')) {
      if (get_text()==')') {
         FunctionNameOffset=ArgumentStartOffset-1;
         return(0);
      } else {
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      }
   } else {
      search('[~'word_chars']\c|^\c','-rh@');
      FunctionNameOffset=(int)point('s');
   }
   return(0);
}

/**
 * Context Tagging&reg; hook function for retrieving the information about
 * each function possibly matching the current function call that
 * function help has been requested on.
 * <p>
 * <b>Note:</b> If there is no help for the first function,
 * a non-zero value is returned and message is usually displayed.
 * <p>
 * If the end of the statement is found, a non-zero value is
 * returned.  This happens when a user to the closing brace
 * to the outer most function caller or does some weird
 * paste of statements.
 * <p>
 * If there is no help for a function and it is not the first
 * function, FunctionHelp_list is filled in with a message
 * <pre>
 *     FunctionHelp_list._makeempty();
 *     FunctionHelp_list[0].proctype=message;
 *     FunctionHelp_list[0].argstart[0]=1;
 *     FunctionHelp_list[0].arglength[0]=0;
 *     FunctionHelp_list[0].return_type=0;
 * </pre>
 * <p>
 * The CICS version of this function is used to provide help when
 * entering arguments to a CICS function call.
 * For example:
 * <pre>
 *    ISSUE CONFIRMATION CONVID(name) STATE(cvda)
 *                                \____ cursor here
 * </pre>
 * Function help will show the following prototype for the CONFID argument
 * of the ISSUE CONFIRMATION function, and the documentation for the
 * ISSUE CONFORMATION function will be displayed below it.
 * <ul>
 * <hr>
 * ISSUE CONFIFIRMATION <b>CONVID(name)</b> STATE(cvda)
 * <hr>
 * [documentation for ISSUE CONFIRMATION, scrolled to CONVID argument.
 * <hr>
 * </ul>
 *
 * @param errorArgs                  array of strings for error message arguments
 *                                   refer to codehelp.e VSCODEHELPRC_*
 * @param FunctionHelp_list          Structure is initially empty.
 *                                   FunctionHelp_list._isempty()==true
 *                                   You may set argument lengths to 0.
 *                                   See VSAUTOCODE_ARG_INFO structure in slick.sh.
 * @param FunctionHelp_list_changed  (reference)Indicates whether the data in
 *                                   FunctionHelp_list has been changed.
 *                                   Also indicates whether current
 *                                   parameter being edited has changed.
 * @param FunctionHelp_cursor_x      (reference) Indicates the cursor x position
 *                                   in pixels relative to the edit window
 *                                   where to display the argument help.
 * @param FunctionHelp_HelpWord      Help topic to look up for this item
 * @param FunctionNameStartOffset    The text between this point and
 *                                   ArgumentEndOffset needs to be parsed
 *                                   to determine the new argument help.
 * @param flags                      function help flags (from fcthelp_get_start)
 *
 * @return int
 *    Returns 0 if we want to continue with function argument
 *    help.  Otherwise a non-zero value is returned and a
 *    message is usually displayed.
 *    <dl compact>
 *    <dt> 1    <dd> Not a valid context
 *    <dt> 2-9  <dd> (not implemented yet)
 *    <dt> 10   <dd> Context expression too complex
 *    <dt> 11   <dd> No help found for current function
 *    <dt> 12   <dd> Unable to evaluate context expression
 *    </dl>
 */
int _cics_fcthelp_get(_str (&errorArgs)[],
                      VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                      boolean &FunctionHelp_list_changed,
                      int &FunctionHelp_cursor_x,
                      _str &FunctionHelp_HelpWord,
                      int FunctionNameStartOffset,
                      int flags,
                      VS_TAG_BROWSE_INFO symbol_info=null,
                      VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   //say("_cics_fcthelp_get");
   errorArgs._makeempty();
   // avoid recalculating the expression when we don't have to
   static _str prev_prefixexp;
   static _str prev_otherinfo;
   static _str prev_ParamName;
   static int  prev_ParamNum;
   static int  prev_info_flags;

   FunctionHelp_list_changed=0;
   if(FunctionHelp_list._isempty()) {
      FunctionHelp_list_changed=1;
      gLastContext_FunctionName="";
      gLastContext_FunctionOffset=-1;
   }
   typeless p;
   typeless cursor_offset=point('s');
   save_pos(p);
   int orig_left_edge=p_left_edge;
   goto_point(FunctionNameStartOffset);
   // struct class
   int status=search('[()]','rh@xcs');
   //boolean found_function_pointer=false;
   int ParamNum_stack[];
   int offset_stack[];  // offset of this function open parenthesis
   int stack_top=0;
   ParamNum_stack[stack_top]=0;
   ++stack_top;
   ParamNum_stack[stack_top]=0;
   offset_stack[stack_top]=FunctionNameStartOffset;

   VS_TAG_IDEXP_INFO idexp_info;
   tag_idexp_info_init(idexp_info);

   for (;;) {
      if (status) {
         break;
      }
      _str ch=get_text();
      //say('cursor_offset='cursor_offset' p='point('s')' ch='ch);
      if (cursor_offset<=point('s')) {
         break;
      }
      if (ch==')') {
         --stack_top;
         if (stack_top<=0 /*&& (!found_function_pointer && stack_top<0)*/) {
            // The close paren has been entered for the outer most function
            // We are done.
            restore_pos(p);
            return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
         }
         //found_function_pointer = false;
         status=repeat_search();
         continue;
      }
      if (ch=='(') {
         // Determine if this is a new function
         ++stack_top;
         ParamNum_stack[stack_top]=1;
         offset_stack[stack_top]=(int)point('s');
         status=repeat_search();
         continue;
      }
      word_chars := _clex_identifier_chars();
      if (pos('[~'word_chars']',get_text(1,match_length('s')-1),1,'r') &&
          pos('[~'word_chars']',get_text(1,match_length('s')+match_length()),1,'r')) {
         restore_pos(p);
         return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
      }
      status=repeat_search();
   }
   typeless tag_files = tags_filenamea(p_LangId);
//   _str lastid="";
//   _str prefixexp="";
//   int lastidstart_col,lastidstart_offset;
//   int info_flags;
//   typeless otherinfo;
   for (;;--stack_top) {
      if (stack_top<=0) {
         restore_pos(p);
         return(VSCODEHELPRC_NO_HELP_FOR_FUNCTION);
      }
      goto_point(offset_stack[stack_top]);
      boolean has_parenthesis = (get_text()=='(');
      if (has_parenthesis) {
         goto_point(offset_stack[stack_top]+1);
      }
      status=_cics_get_expression_info(true,idexp_info,visited,depth);
      idexp_info.errorArgs[1] = idexp_info.lastid;
      if (_chdebug) {
         say('prefixexp='idexp_info.prefixexp' lastid='idexp_info.lastid' lastidstart_col='idexp_info.lastidstart_col' info_flags='dec2hex(idexp_info.info_flags)' otherinfo='idexp_info.otherinfo' status='status);
      }
      if (!status) {
         // get parameter number and cursor position
         int ParamNum=ParamNum_stack[stack_top];
         _str ParamName="";
         if (idexp_info.otherinfo!=null) {
            parse idexp_info.otherinfo with ParamName '(' .;
         }
         set_scroll_pos(orig_left_edge,p_col);

         // check if anything has changed
         if (prev_prefixexp :== idexp_info.prefixexp &&
             gLastContext_FunctionName :== idexp_info.lastid &&
             gLastContext_FunctionOffset :== idexp_info.lastidstart_col &&
             prev_otherinfo :== idexp_info.otherinfo &&
             prev_info_flags == idexp_info.info_flags &&
             prev_ParamName  == ParamName) {
            if (!p_IsTempEditor) {
                FunctionHelp_cursor_x=(idexp_info.lastidstart_col-p_col)*p_font_width+p_cursor_x;
            }
             break;
         }

         // find matching symbols
         int tag_flags=0;
         boolean globals_only=false;
         _str type_name='';
         _str class_name='';
         _str signature='';
         _str return_type='';
         _str match_list[];
         _str match_symbol = idexp_info.lastid;
         _str match_class="";
         _str match_tag = "";
         int  match_flags = VS_TAGFILTER_PROTO;

         // find symbols matching the given class
         int num_matches = 0;
         tag_clear_matches();

         // find tags matching this function
         if (idexp_info.prefixexp=='' && idexp_info.lastid!='') {
            idexp_info.prefixexp=idexp_info.lastid;
         }
         tag_list_context_globals(0,0,idexp_info.prefixexp,false,tag_files,
                                  VS_TAGFILTER_PROTO,VS_TAGCONTEXT_ONLY_funcs,
                                  num_matches,def_tag_max_function_help_protos,
                                  false,false);

         // check if the symbol was on the kill list for this extension
         if (_check_killfcts(match_symbol, match_class, flags)) {
            continue;
         }

         // remove duplicates from the list of matches
         int unique_indexes[]; unique_indexes._makeempty();
         _str duplicate_indexes[];
         removeDuplicateFunctions(unique_indexes,duplicate_indexes);
         int num_unique = unique_indexes._length();
         int i,j;
         for (i=0; i<num_unique; i++) {
            j = unique_indexes[i];
            _str tag_file,proc_name,file_name;
            int line_no;
            tag_get_match(j,tag_file,proc_name,type_name,
                          file_name,line_no,class_name,tag_flags,
                          signature,return_type);
            // maybe kick out if already have match or more matches to check
            if (match_list._length()>0 || i+1<num_unique) {
               if (file_eq(file_name,p_buf_name) && line_no:==p_line) {
                  continue;
               }
               if (tag_tree_type_is_class(type_name)) {
                  continue;
               }
               if (signature=='' && (tag_flags & VS_TAGFLAG_extern)) {
                  continue;
               }
            }
            _str taginfo=tag_tree_compose_tag(proc_name,class_name,type_name,tag_flags,signature,return_type);
            match_list[match_list._length()] = proc_name "\t" signature "\t" return_type "\t" file_name "\t" line_no "\t" taginfo;
         }

         // get rid of any duplicate entries
         match_list._sort();
         _aremove_duplicates(match_list, false);

         // translate functions into struct needed by function help
         boolean found_param_name = false;
         if (match_list._length()>0) {
            FunctionHelp_list._makeempty();
            FunctionHelp_HelpWord = match_symbol;

            // move the last function involved in a replace tag to the front of list
            if (gLastContext_FunctionReplaced!='' &&
                pos(match_symbol,gLastContext_FunctionReplaced,1,'i')==1) {
               for (i=0; i<match_list._length(); i++) {
                  _str match_tag_name;
                  parse match_list[i] with match_tag_name "\t" .;
                  if (strieq(match_tag_name,gLastContext_FunctionReplaced)) {
                     if (i!=0) {
                        _str tmp=match_list[0];
                        match_list[0]=match_list[i];
                        match_list[i]=tmp;
                     }
                     break;
                  }
               }
            }

            for (i=0; i<match_list._length(); i++) {
               int k = FunctionHelp_list._length();
               if (k >= def_tag_max_function_help_protos) break;
               _str match_tag_name, match_file_name;
               _str match_line_no, match_taginfo, tag_trailer;
               parse match_list[i] with match_tag_name "\t" signature "\t" return_type "\t" match_file_name "\t" match_line_no "\t" match_taginfo;
               parse match_tag_name with . '<' tag_trailer;
               if (tag_trailer!='') tag_trailer='<'tag_trailer;
               cics_fix_tagname(match_tag_name,signature,true);
               FunctionHelp_list[k].prototype = match_tag_name:+tag_trailer' 'signature;
               int base_length = length(match_tag_name:+tag_trailer);
               FunctionHelp_list[k].argstart[0]=1;
               FunctionHelp_list[k].arglength[0]=length(match_tag_name);
               FunctionHelp_list[k].ParamNum=ParamNum;
               FunctionHelp_list[k].ParamName='';
               FunctionHelp_list[k].ParamType='';
               FunctionHelp_list[k].tagList[0].comment_flags=0;
               FunctionHelp_list[k].tagList[0].comments=null;
               FunctionHelp_list[k].tagList[0].filename=match_file_name;
               FunctionHelp_list[k].tagList[0].linenum=(int)match_line_no;
               FunctionHelp_list[k].tagList[0].taginfo=match_taginfo;

               // parse signature and map out argument ranges
               int  arg_pos  = 0;
               _str argument = cb_next_arg(signature, arg_pos, 1);
               while (argument != '') {
                  j = FunctionHelp_list[k].argstart._length();
                  FunctionHelp_list[k].argstart[j]=base_length+arg_pos;
                  FunctionHelp_list[k].arglength[j]=length(argument);
                  _str arg_name;
                  parse argument with arg_name '(' .;
                  if (strieq(arg_name,ParamName)) {
                     found_param_name=true;
                     ParamNum=FunctionHelp_list[k].ParamNum=j;
                     FunctionHelp_list[k].ParamName=arg_name;
                  }
                  argument = cb_next_arg(signature, arg_pos, 0);
               }
            }
            // If we had some with matching param name, but others without,
            // delete the ones not having the matching name
            if (found_param_name) {
               for (i=0; i<FunctionHelp_list._length(); ++i) {
                  if (FunctionHelp_list[i].ParamName=='') {
                     FunctionHelp_list._deleteel(i);
                     i--;
                  }
               }
            }
            // Found some matches?
            if (FunctionHelp_list._length() > 0) {
               if (!strieq(prev_ParamName,ParamName)) {
                  FunctionHelp_list_changed=1;
               }
               prev_prefixexp  = idexp_info.prefixexp;
               prev_otherinfo  = idexp_info.otherinfo;
               prev_info_flags = idexp_info.info_flags;
               prev_ParamName  = ParamName;
               prev_ParamNum   = ParamNum;
               if (!p_IsTempEditor) {
                  FunctionHelp_cursor_x=(idexp_info.lastidstart_col-p_col)*p_font_width+p_cursor_x;
               }
               break;
            }
         }
      }
   }
   if (idexp_info.lastid!=gLastContext_FunctionName ||
       gLastContext_FunctionOffset!=idexp_info.lastidstart_offset) {
       FunctionHelp_list_changed=1;
       gLastContext_FunctionName=idexp_info.lastid;
       gLastContext_FunctionOffset=idexp_info.lastidstart_offset;
   }
   restore_pos(p);
   return(0);
}

/**
 * This function is used to format a declaration in the correct
 * manner for a particular language.  It is used as a hook function
 * [_[lang]_get_decl()] by Context Tagging&reg; when displaying a
 * function or variable prototype in list-members or function help.
 * It also can be used for generating declarations, such as when
 * virtual functions are overridden.
 * <P><B>INPUT</B>
 * <PRE>
 *    info.class_name
 *    info.member_name
 *    info.type_name;
 *    info.flags;
 *    info.return_type;
 *    info.arguments
 *    info.exceptions
 * </PRE>
 * <p>
 * The two most important items formated by the CICS hook function are:
 * <ul compact>
 * <li>functions -- function prototypes are CICS functions, just show name
 * <li>variables -- variables are always formated like COBOL variables
 * </ul>
 * <p>
 * If the verbose flags is passed, the declaration is prefaced with
 * EXEC CICS and also includes the parameter list for the function.
 *
 * @param lang   value of p_LangId (ignored, always cics)
 * @param info   struct containing complete tag details,
 *               see description above for details on which
 *               fields are used and which are not used
 * @param flags  bitset of flags used for code generation (VSCODEHELPDCLFLAG_*)
 *               <ul>
 *               <li> VSCODEHELPDCLFLAG_OUTPUT_IN_CLASS_DEF -- generate code for class definition
 *               <li> VSCODEHELPDCLFLAG_VERBOSE             -- verbose output, includes modifiers
 *               <li> VSCODEHELPDCLFLAG_SHOW_CLASS          -- show class name if there is one
 *               <li> VSCODEHELPDCLFLAG_SHOW_ACCESS         -- show access specifiers
 *               </ul>
 * @param decl_indent_string
 *               string containing spaces or tabs for line indentation
 * @param access_indent_string
 *               string containg spaces or tabs for access specifier indention
 *
 * @return string containing declaration.
 */
_str _cics_get_decl(_str lang,VS_TAG_BROWSE_INFO &info,int flags=0,
                    _str decl_indent_string="",_str access_indent_string="")
{
   int tag_flags=info.flags;
   _str tag_name=info.member_name;
   _str type_name=info.type_name;
   int verbose=(flags&VSCODEHELPDCLFLAG_VERBOSE);
   int show_class=(flags&VSCODEHELPDCLFLAG_SHOW_CLASS);
   _str result='';
   _str proto='';

   //say("_cics_get_decl: type_name="type_name);
   switch (type_name) {
   case 'proc':         // procedure or command
   case 'proto':        // function prototype
   case 'constr':       // class constructor
   case 'destr':        // class destructor
   case 'func':         // function
   case 'procproto':    // Prototype for procedure
   case 'subfunc':      // Nested function or cobol paragraph
   case 'subproc':      // Nested procedure or cobol paragraph
      _str before_return=decl_indent_string;
      _str arguments='';
      if (verbose) {
         before_return=_word_case("EXEC CICS ");
         arguments=info.arguments;
         cics_fix_tagname(tag_name,arguments);
         arguments=stranslate(arguments,'',',');
      }
      result=before_return:+tag_name' 'arguments;
      return(result);

   case 'define':       // preprocessor macro definition
      return(decl_indent_string'>>':+_word_case("CONSTANT"):+' ':+tag_name:+' ':+_word_case("IS"):+' 'info.return_type);

   case 'typedef':      // type definition
      return(decl_indent_string:+_word_case('type'):+' 'tag_name' = 'info.return_type:+info.arguments);

   case 'gvar':         // global variable declaration
   case 'var':          // member of a class / struct / package
   case 'lvar':         // local variable declaration
   case 'prop':         // property
   case "param":        // function or procedure parameter
   case 'group':        // Container variable
      return(decl_indent_string:+tag_name' 'info.return_type);

   case 'class':        // class definition
   case 'interface':    // interface, eg, for Java
      if (type_name=='class') {
         type_name="CLASS-ID";
      } else {
         type_name="INTERFACE-ID";
      }
      return decl_indent_string:+_word_case(type_name):+'. 'tag_name'.';

   case 'label':        // label
      return(decl_indent_string:+_word_case("LABEL"):+' 'tag_name':');

   case 'import':       // package import or using
      return(decl_indent_string:+_word_case("IMPORT"):+' 'tag_name':');

   case 'friend':       // C++ friend relationship
      return(decl_indent_string:+_word_case('FRIEND')' 'tag_name:+info.arguments);

   case 'include':      // C++ include or Ada with (dependency)
      return(decl_indent_string:+_word_case('COPY')' 'tag_name'.');

   case 'form':         // GUI Form or window
      return(decl_indent_string:+'_form 'tag_name);
   case 'menu':         // GUI Menu
      return(decl_indent_string:+'_menu 'tag_name);
   case 'control':      // GUI Control or Widget
      return(decl_indent_string:+'_control 'tag_name);
   case 'eventtab':     // GUI Event table
      return(decl_indent_string:+'defeventtab 'tag_name);

   case 'const':        // pascal constant
      proto='';
      strappend(proto,info.member_name);
      strappend(proto," "_word_case("IS")" "info.return_type);
      return(proto);

   case "file":         // COBOL file descriptor
      proto=_word_case('SELECT')' ';
      strappend(proto,info.member_name);
      strappend(proto," "_word_case("IS")" "info.return_type);
      return(proto);

   case "database":     // SQL/OO Database
   case "table":        // Database Table
   case "column":       // Database Column
   case "index":        // Database index
   case "view":         // Database view
   case "trigger":      // Database trigger
   case "cursor":       // Database result set cursor
      return(decl_indent_string:+_word_case(type_name)' 'tag_name);

   default:
      proto=decl_indent_string;
      strappend(proto,info.member_name);
      if (info.return_type!='') {
         strappend(proto,' '_word_case('IS')' 'info.return_type);
      }
      return(proto);
   }
}

/**
 * Modify a CICS function name, as stored in the database
 * and the argument list to adjust for the more unusual
 * CICS functions.
 *
 * @param tag_name  (reference) Name of functions, maybe be adjusted to remove
 *                  the first named argument, if it matches the last word of the
 *                  function name
 * @param arguments (reference) parameter list, first parameter may be modified
 *                  to move ancillary information
 * @param remove_brackets
 *                  Remove &lt; line comment information &gt;
 */
static void cics_fix_tagname(_str &tag_name, _str &arguments, boolean remove_brackets=false)
{
   _str first_arg, before_lt, after_lt;
   parse arguments with first_arg ',' .;
   parse tag_name with before_lt '<' after_lt;
   if (remove_brackets) {
      tag_name=strip(before_lt);
      after_lt='';
   }
   word_chars := _clex_identifier_chars();
   int p=pos('['word_chars']#[ \t]*$',before_lt,1,'r');
   if (p > 1) {
      _str first_word='';
      _str last_word=strip(substr(before_lt,p));
      parse first_arg with first_word '(' .;
      if (strieq(first_word,last_word)) {
         tag_name=strip(substr(before_lt,1,p-1));
         if (after_lt!='') {
            arguments = first_arg' <'after_lt', 'arguments;
         }
      }
   }
}

/**
 * CICS proc search function, this is just a place-holder, since there
 * are no CICS declarations to find.  The purpose of this function is
 * simply so that _istagging_supported() succeeds.
 *
 * @param proc_name  Set to the empty string
 * @param find_first find first declaration or next (ignored)
 * @return STRING_NOT_FOUND_RC, indicating nothing was found
 */
_str cics_proc_search(_str &proc_name, int find_first)
{
   proc_name='';
   return(STRING_NOT_FOUND_RC);
}
