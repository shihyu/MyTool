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
#include "color.sh"
#require "se/lang/api/LanguageSettings.e"
#import "adaptiveformatting.e"
#import "alias.e"
#import "autocomplete.e"
#import "c.e"
#import "cbrowser.e"
#import "codehelp.e"
#import "codehelputil.e"
#import "context.e"
#import "cutil.e"
#import "guicd.e"
#import "listproc.e"
#import "main.e"
#import "notifications.e"
#import "os2cmds.e"
#import "pmatch.e"
#import "project.e"
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "tags.e"
#endregion

using se.lang.api.LanguageSettings;

/*
   TODO
      - Add signature for function definitions
      - Does this language have global?
      - improve tagging function headers for function headings
        which continue onto multiple lines.

Features implemented by this macro

   These features will will save you lots of typing
   and allow you to produce well formatted code
   much more quickley.

   *  SmartPaste(R).  Automatically indents pasted code to the
      correct nesting level.
   *  Syntax expansion.  Inserts templates when space bar is
      pressed.
   *  Syntax indenting.  Automatically indents when the ENTER
      key is pressed to the correct nesting level.
   *  Auto keyword case.  By default, keywords are automatically
      changed to upper case for better readability.
   *  Selective display of function headings and function
      listing in Procs Tab.
   *  Auto-line coninuations.  Dollar signs are automatically
      inserted when statements are split.
   *  Word help Ctrl+F1

Built-in Space bar aliases

   CASE  OF
   ENDCASE

   IF  THEN BEGIN
   ENDIF

   COMMON

   PRO
   END

   FUNCTION
   END

   FOR  DO BEGIN
   ENDFOR

   WHILE  DO BEGIN
   ENDWHILE

   REPEAT BEGIN
   ENDREP UNTIL

*/

#define VSAUTOCODEINFO_PVWAVE_IS_FUNC   0x1000000
#define VSAUTOCODEINFO_PVWAVE_IS_PROC   0x2000000
#define VSAUTOCODEINFO_PVWAVE_LASTID_FOLLOWED_BY_COMMA  0x4000000


#define STRIP_FUNCTION_KEYWORDS 1

#define PRO_MODE_NAME   'PV-WAVE'
#define PRO_LANGUAGE_ID 'pro'

boolean def_pro_autocase=1;

static int gWordEndOffset=-1;
static _str gWord="";
static _str gLastKeywordList[];

// Must end with backslash
// windows c:\vni\wave\bin\bin.i386nt\wave\
// unix    /usr/local/vni/wave/bin/
//         wvsetup.sh
//
#if __UNIX__
_str def_wave_bin_path='/usr/local/vni/wave/bin/';
#define WAVE_EXE_NAME 'wave'
#else
_str def_wave_bin_path='c:\vni\wave\bin\bin.i386nt\';
#define WAVE_EXE_NAME 'wave.exe'
#endif

static boolean gCheckedIfTagFileBuilt_pro=false;

defload()
{

   // Don't let carriage return erase process buffer lines
   _default_option(VSOPTION_PROCESS_BUFFER_CR_ERASE_LINE,0);

   _str setup_info='MN='PRO_MODE_NAME',TABS=+3,MA=1 74 1,':+
              'KEYTAB=pro-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=A-Za-z0-9_,LN=PV-WAVE,CF=1,LNL=0,';
   _str compile_info='';
   _str syntax_info='3 1 1 1 0 1 0';
   
   _CreateLanguage(PRO_LANGUAGE_ID, PRO_MODE_NAME,
                   setup_info, compile_info, syntax_info);
   _CreateExtension('pro', PRO_LANGUAGE_ID);

   kt_index := find_index('pro-keys', EVENTTAB_TYPE);
   if (kt_index) {
      set_eventtab_index(kt_index,event2index(name2event(' ')),
                         find_index('pro_space',COMMAND_TYPE));
      set_eventtab_index(kt_index,event2index(name2event('ENTER')),
                         find_index('pro_enter',COMMAND_TYPE));
   }

   // Configure a extension specific project

   int orig_view_id=0;
   get_window_id(orig_view_id);
#if 0
   // Not enough users of pvwave to rewrite this for now.
   _str section_name='.pro';
   _str filename=usercfg_path_search(VSCFGFILE_USER_EXTPROJECTS);
   int temp_view_id=0;
   int status=_ini_get_section(filename,section_name,temp_view_id);
   if (!status) {
      _delete_temp_view(temp_view_id);
   }
   filename=usercfg_init_write(VSCFGFILE_USER_EXTPROJECTS);
   // Find not found or section not found
   if (status) {
      _create_temp_view(temp_view_id);
      _delete_line();
      insert_line('INCLUDEDIRS=');
      insert_line("COMPILE=\1cmd: compile_wave %f");
      insert_line('MAKE=');
      insert_line('DEBUG=');
      insert_line('USER1=');
      insert_line('USER2=');

      _ini_replace_section(filename,'.pro',temp_view_id);
   } else {
      _ini_set_value(filename,section_name,'COMPILE',"\1cmd: compile_wave %f");
   }
#endif
   activate_window(orig_view_id);
   _project_refresh();
   pvwave_init();
   int tfindex=0;
   _pro_MaybeBuildTagFile(tfindex);
   rc=0;
}
definit()
{
   gCheckedIfTagFileBuilt_pro=false;
}

// Search backwards and determine if we are inside
// braces
static boolean _inside_braces()
{
   typeless orig_pos;
   save_pos(orig_pos);
   typeless status=search('[{}]|^','@-rh');
   if (status) {
      restore_pos(orig_pos);
      return(false);
   }
   typeless nesting=0;
   for (;;) {
      if (status) {
         restore_pos(orig_pos);
         return(nesting);
      }
      if (match_length()==0) {
         if (!_linecont()) {
            restore_pos(orig_pos);
            return(nesting);
         }
         up();
         _end_line();
      } else {
         int cfg=_clex_find(0,'g');
         if (cfg!=CFG_STRING && cfg!=CFG_COMMENT) {
            if (get_text()=='{') {
               ++nesting;
            } else {
               --nesting;
            }
         }
      }
      status=repeat_search();
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
int _pro_get_expression_info(boolean PossibleOperator, VS_TAG_IDEXP_INFO &idexp_info,
                             VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   int cfg;
   if (PossibleOperator) {
      left();cfg=_clex_find(0,'g');right();
   } else {
      cfg=_clex_find(0,'g');
   }
   if (_in_comment() || cfg==CFG_STRING) {
      return(VSCODEHELPRC_CONTEXT_NOT_VALID);
   }
   idexp_info.errorArgs._makeempty();
   idexp_info.otherinfo="";
   idexp_info.prefixexp="";
   idexp_info.info_flags=VSAUTOCODEINFO_DO_LIST_MEMBERS;
   typeless orig_pos;
   save_pos(orig_pos);
   word_chars := _clex_identifier_chars();
   if (PossibleOperator) {
      left();
      _str ch=get_text();
      switch (ch) {
      case ',':
         idexp_info.info_flags=VSAUTOCODEINFO_PVWAVE_LASTID_FOLLOWED_BY_COMMA|VSAUTOCODEINFO_DO_FUNCTION_HELP;
      case '(':
         if (ch=='(') {
            idexp_info.info_flags=VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN|VSAUTOCODEINFO_DO_FUNCTION_HELP;
         }
         idexp_info.lastidstart_col=p_col;  // need this for function pointer case
         left();
         search('[~ \t]|^','-rh@');
         // maybe there was a function pointer expression
         if (pos('[~'word_chars']',get_text(),1,'r')) {
            restore_pos(orig_pos);
            //say("ID returns 5");
            return(1);
         }
         int end_col=p_col+1;
         search('[~'word_chars']\c|^\c','-rh@');
         idexp_info.lastid=_expand_tabsc(p_col,end_col-p_col);
         idexp_info.lastidstart_col=p_col;
         idexp_info.lastidstart_offset=(int)point('s');
         /*if (pos(' 'lastid' ',C_NOT_FUNCTION_WORDS)) {
            restore_pos(orig_pos);
            return(1);
         }
         */
         break;
      default:
         restore_pos(orig_pos);
         return(1);
      }
   } else {
      // IF we are not on an id character.
      _str ch=get_text();
      int done=0;
      // IF we are not on an id character.
      if (pos('[~'word_chars']',get_text(),1,'r')) {
         left();
         if (pos('[~'word_chars']',get_text(),1,'r')) {
            right();
            if (get_text()=='(') {
               idexp_info.info_flags|=VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN;
            } else if (get_text()==',') {
               idexp_info.info_flags|=VSAUTOCODEINFO_PVWAVE_LASTID_FOLLOWED_BY_COMMA;
            }
            idexp_info.prefixexp='';
            idexp_info.lastid="";
            idexp_info.lastidstart_col=p_col;
            idexp_info.lastidstart_offset=(int)point('s');
            done=1;
         }
      }
      if(!done) {
         search('[~'word_chars']|$','rh@');
         int info_flags=0, end_col=p_col;
         // Check if this is a function call
         search('[~ \t]|$','rh@');
         if (get_text()=='(') {
            info_flags|=VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN;
         } else if (get_text()==',') {
            info_flags|=VSAUTOCODEINFO_PVWAVE_LASTID_FOLLOWED_BY_COMMA;
         }
         p_col=end_col;

         left();
         search('[~'word_chars']\c|^\c','-rh@');
         idexp_info.lastid=_expand_tabsc(p_col,end_col-p_col);
         idexp_info.lastidstart_col=p_col;
         idexp_info.lastidstart_offset=(int)point('s');
      }
   }
   for (;;) {
      if (p_col==1) {
         if (!_linecont()) {
            idexp_info.info_flags|=VSAUTOCODEINFO_PVWAVE_IS_PROC;
            restore_pos(orig_pos);
            return(0);
         }
         up();
         _str line;
         nocomment_get_line(line,1);
         // Position cursor on past end of line (comment and $ is past EOL)
         p_col=text_col(line,length(line)+1,'I');
      }
      left();
      search('[~ \t]|^','-rh@');
      if (match_length()) {
         _str ch=get_text();
         if (ch=='.') {
            idexp_info.info_flags|=VSAUTOCODEINFO_PVWAVE_IS_PROC;
            restore_pos(orig_pos);
            return(0);
         }
         // Label, case expression, or struct definition
         if (ch==':') {
            if (_inside_braces()) {
               idexp_info.info_flags|=VSAUTOCODEINFO_PVWAVE_IS_FUNC;
            } else {
               idexp_info.info_flags|=VSAUTOCODEINFO_PVWAVE_IS_PROC;
            }
            restore_pos(orig_pos);
            return(0);
         }
         // labels will mess us here
         idexp_info.info_flags|=VSAUTOCODEINFO_PVWAVE_IS_FUNC;
         restore_pos(orig_pos);
         return(0);
      }
   }

   restore_pos(orig_pos);
   return(0);
}

void _pro_replace_context_tag(int relcol,
                 _str last_id, _str caption,
                 _str terminationKey, int info_flags)
{
   while (relcol-->0) left();
   _delete_text(length(last_id));

   _str paren="";
   parse caption with caption '(' +0 paren;
   if (terminationKey:==' ' &&
       (_GetCodehelpFlags() & VSCODEHELPFLAG_SPACE_INSERTS_SPACE) &&
       !(info_flags & VSAUTOCODEINFO_DO_SYNTAX_EXPANSION)) {
      caption=caption' ';
   }
   _insert_text(caption);

   // if we have an open paren, then insert open paren and go directly
   // into function help, unless name is already followed by a paren.
   // kind of language specific...
   if (terminationKey:=="" && paren!="" &&
       (_GetCodehelpFlags()& VSCODEHELPFLAG_INSERT_OPEN_PAREN)
       ) {
      if( !(info_flags&VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) &&
         (info_flags &VSAUTOCODEINFO_PVWAVE_IS_FUNC) ) {
         last_event('(');
         auto_functionhelp_key();
      } else if( !(info_flags&VSAUTOCODEINFO_PVWAVE_LASTID_FOLLOWED_BY_COMMA) &&
         (info_flags &VSAUTOCODEINFO_PVWAVE_IS_PROC) ) {
         last_event(',');
         auto_functionhelp_key();
      }
   }
}
int _pro_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                         _str lastid,int lastidstart_offset,
                         int info_flags,typeless otherinfo,
                         boolean find_parents,int max_matches,
                         boolean exact_match,boolean case_sensitive,
                         int filter_flags=VS_TAGFILTER_ANYTHING,
                         int context_flags=VS_TAGCONTEXT_ALLOW_locals,
                         VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   if (_chdebug) {
      isay(depth, "_pro_find_context_tags: lastid="lastid" prefixexp="prefixexp);
   }

   errorArgs._makeempty();
   // id followed by paren, then limit search to functions
   int isproc=(info_flags & VSAUTOCODEINFO_PVWAVE_IS_PROC);

   // set up for (possibly) incremental update
   status := 0;
   num_matches := 0;
   junk := null;

   // first time here, set up categories, otherwise, find them...
   getKeywords := false;
   if (false && ginFunctionHelp && !gFunctionHelp_pending ) {
      getKeywords = true;
   } else { // Not sure if we need this check
      int FunctionNameOffset=0;
      int FunctionNameStartOffset=0;
      int ArgumentStartOffset=0;
      int flags=0;
      VSAUTOCODE_ARG_INFO FunctionHelp_list[];
      boolean FunctionHelp_list_Changed=false;
      int FunctionHelp_cursor_x=0;
      _str FunctionHelp_HelpWord="";
      typeless FunctionHelp_errorArgs;

      save_pos(auto orig_pos);
      status=_pro_fcthelp_get_start(FunctionHelp_errorArgs,false,true,FunctionNameOffset,ArgumentStartOffset,flags);
      restore_pos(orig_pos);
      if (!status) {
         status=_pro_fcthelp_get(FunctionHelp_errorArgs,
                                 FunctionHelp_list,
                                 FunctionHelp_list_Changed,
                                 FunctionHelp_cursor_x,
                                 FunctionHelp_HelpWord,
                                 FunctionNameOffset,
                                 flags, null,
                                 visited, depth);
         restore_pos(orig_pos);
         if (status == 0) {
            getKeywords = true;
         }
      }
   }

   if (!(context_flags & VS_TAGCONTEXT_ONLY_inclass) &&
       !(context_flags & VS_TAGCONTEXT_NO_globals) &&
       !(gLastKeywordList._isempty()) && getKeywords) {
      for (i:=0;i<gLastKeywordList._length();++i) {
         word := gLastKeywordList[i];
         if (_CodeHelpDoesIdMatch(lastid, word, exact_match, case_sensitive)) {
            tag_tree_insert_tag(0,0,0,1,0,word,"param","",0,"",0,"");
            ++num_matches;
         }
      }
   }

   // update the symbols from current buffer, give case-sensitive matches preference
   int symbol_count=0;
   if ((context_flags & VS_TAGCONTEXT_ONLY_this_file) && 
       !(context_flags & VS_TAGCONTEXT_ONLY_locals) && 
       !(context_flags & VS_TAGCONTEXT_NO_globals)) {
      tag_list_context_globals(0, 0, lastid,
                               true, null,
                               filter_flags, context_flags,
                               num_matches, max_matches,
                               exact_match, case_sensitive,
                               visited, depth);
   }

   // update the globals, make sure that case-sensitive matches get preference
   if (!(context_flags & VS_TAGCONTEXT_ONLY_this_file) && 
       !(context_flags & VS_TAGCONTEXT_ONLY_locals) && 
       !(context_flags & VS_TAGCONTEXT_NO_globals)) {
      typeless tag_files = tags_filenamea(p_LangId);
      tag_list_context_globals(0, 0, lastid,
                               true, tag_files,
                               filter_flags, context_flags,
                               num_matches, max_matches,
                               exact_match, case_sensitive,
                               visited, depth);
   }

   // all done
   errorArgs[1] = lastid;
   return (num_matches > 0)? 0 : VSCODEHELPRC_NO_SYMBOLS_FOUND;
}
static int _prev_nonblank_char()
{
   for (;;) {
      if (p_col==1) {
         if (!_linecont()) {
            return(1);
         }
         up();
         _str line="";
         nocomment_get_line(line,1);
         // Position cursor on past end of line (comment and $ is past EOL)
         p_col=text_col(line,length(line)+1,'I');
      }
      left();
      search('[~ \t]|^','-rh@');
      if (match_length()) {
         return(0);
      }
   }
}

//////////////////////////////////////////////////////////////////////////////
// Skip over nested parameter sets (parents, <>, [], etc)
//
static int skip_nested(_str params,int j,_str start_ch,_str end_ch)
{
   int nesting=1;
   _str re='[\'start_ch'\'end_ch']';
   for (;;) {
      j=pos(re,params,j,'r');
      //messageNwait('re='re' j='j' end_ch='end_ch);
      if (!j) {
         return(length(params)+1);
      }
      _str ch=substr(params,j,1);
      if (ch==start_ch) {
         ++nesting;
         ++j;
         continue;
      }
      --nesting;
      //messageNwait('nesting='nesting);
      ++j;
      if (nesting<=0) {
         //messageNwait('j='j);
         return(j);
      }
   }
}
//############################################################################
//////////////////////////////////////////////////////////////////////////////
// Skip over the contents of a C style string
//
static int skip_string(_str params,int j,_str endch)
{
   for (;;) {
      j=pos(endch,params,j,'r');
      if (!j) {
         // String not terminated.
         return(length(params)+1);
      }
      _str ch=substr(params,j+1,1);
      // Two in a row?
      if (ch==endch) {
         j+=2;
         continue;
      }
      return(j+1);
   }
}
//////////////////////////////////////////////////////////////////////////////
// Get the next argument from the given string, pass find_first==1
// to get the first argument.
//
#define PRO_NEXTARG_CHARS1  '[,("'']'
static int gnext_arg_index;
_str _pro_next_arg(_str params,int &arg_pos,int find_first,_str ArgSep_re="")
{
   static boolean inOptionalArgument;
   boolean ispascal=false;

   if (find_first) {
      gnext_arg_index=1;
   }
   // skip leading spaces
   _str ch=substr(params,gnext_arg_index,1);
   while ((ch==' ' || ch=="\t") && gnext_arg_index <= length(params)) {
      gnext_arg_index++;
      ch=substr(params,gnext_arg_index,1);
   }
   // pull next argument off of list
   int j;
   j=gnext_arg_index;
   //say(ArgSep_re);
   //say('j='j' params='params);
   _str re="";
   if (ArgSep_re!='') {
      re=PRO_NEXTARG_CHARS1'|'ArgSep_re;
   } else {
      re=PRO_NEXTARG_CHARS1;
   }
   int sepLen=1;
outer_loop:
   for (;;) {
      //_message_box(params ' index=' j);
      j=pos(re,params,j,'ir');
      //say('j='j);
      if (!j) {
         j=length(params)+1;
         break;
      }
      ch=substr(params,j,1);
      switch (ch) {
      case ',':
         break outer_loop;
      /*case '[':
         if (inOptionalArgument) {
            inOptionalArgument=false;
            gnext_arg_index=j;
            j=skip_nested(params,j+1,ch,']');
            arg_pos = gnext_arg_index;
            result=substr(params,gnext_arg_index,j-gnext_arg_index);
            gnext_arg_index=j+1;
            return(strip(result));
         }
         k=pos('[~ \t]',params,j+1,'r');
         if (k && substr(params,k,1)==',') {
            inOptionalArgument=true;
            arg_pos = gnext_arg_index;
            result=substr(params,gnext_arg_index,j-gnext_arg_index);
            gnext_arg_index=j;
            return (strip(result));
         }
         j=skip_nested(params,j+1,ch,']');
         break;
      */case '(':
         j=skip_nested(params,j+1,ch,')');
         break;
      case '"':
      case "'":
         j=skip_string(params,j+1,ch);
         break;
      default:  // ArgSep_re
         sepLen=pos('');
         break outer_loop;
      }
   }
   if (j<gnext_arg_index) {
      return('');
   }
   // Skip leading [
   for (;substr(params,gnext_arg_index,1)=='[';++gnext_arg_index);
   arg_pos = gnext_arg_index;
   // Remove trailing ]
   int endj=j;
   for (;endj>1 && substr(params,endj-1,1)==']';--endj);
   _str result=substr(params,gnext_arg_index,endj-gnext_arg_index);
   gnext_arg_index=j+sepLen;
   result=strip(result);
   return(strip(result));
}
static void strip_function_keywords(_str &signature)
{
   _str keyword="";
   int starti=0;
   int end_j=0;
   int j=1;
   for (;;) {
      j=pos('[="'']',signature,j,'r');
      if (!j) {
         signature=strip(signature,'T',',');
         return;
      }
      _str ch=substr(signature,j,1);
      switch (ch) {
      case '=':
         starti=lastpos(',',signature,j);
         if (!starti) starti=0;
         end_j=pos(',',signature,j);
         if (!end_j) {
            parse substr(signature,starti+1) with keyword '=';
            gLastKeywordList[gLastKeywordList._length()]=keyword;
            signature=substr(signature,1,starti);
            signature=strip(signature,'T',',');
            return;
         } else {
            parse substr(signature,starti+1,end_j-starti-1) with keyword '=';
            gLastKeywordList[gLastKeywordList._length()]=keyword;
            signature=substr(signature,1,starti):+substr(signature,end_j+1);
         }
         j=starti+1;
         break;
      case '"':
      case "'":
         j=skip_string(signature,j+1,ch);
         break;
      }

   }
}
/*
   PARAMETERS
      FunctionHelp_list    (Input/Ouput)
                           Structure is initially empty.
                              FunctionHelp_list._isempty()==true
                           You may set argument lengths to 0.
                           See VSAUTOCODE_ARG_INFO structure in slick.sh.
      FunctionHelp_list_changed   (Output) Indicates whether the data in
                                  FunctionHelp_list has been changed.
                                  Also indicates whether current
                                  parameter being edited has changed.
      FunctionHelp_cursor_x  (Output) Indicates the cursor x
                             position in pixels relative to the
                             edit window where to display the
                             argument help.

      FunctionNameStartOffset,ArgumentEndOffset
                              (INPUT) The text between these two
                              end points needs to be parsed
                              to determine the new argument
                              help.
   RETURN
     Returns 0 if we want to continue with function argument
     help.  Otherwise a non-zero value is returned and a
     message is usually displayed.

   REMARKS
     If there is no help for the first function, a non-zero value
     is returned and message is usually displayed.

     If the end of the statement is found, a non-zero value is
     returned.  This happens when a user to the closing brace
     to the outer most function caller or does some weird
     paste of statements.

     If there is no help for a function and it is not the first
     function, FunctionHelp_list is filled in with a message
         FunctionHelp_list._makeempty();
         FunctionHelp_list[0].proctype=message;
         FunctionHelp_list[0].argstart[0]=1;
         FunctionHelp_list[0].arglength[0]=0;

  RETURN CODES
     1   Not a valid context
     (not implemented yet)
     10   Context expression too complex
     11   No help found for current function
     12   Unable to evaluate context expression
*/
static _str gLastContext_FunctionName;
static int gLastContext_FunctionOffset;
int _pro_fcthelp_get(_str (&errorArgs)[],
                     VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                     boolean &FunctionHelp_list_changed,
                     int &FunctionHelp_cursor_x,
                     _str &FunctionHelp_HelpWord,
                     int FunctionNameStartOffset,
                     int flags,
                     VS_TAG_BROWSE_INFO symbol_info=null,
                     VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   errorArgs._makeempty();
   //say("_pro_fcthelp_get");
   // avoid recalculating the expression when we don't have to
   static _str prev_prefixexp;
   static _str prev_otherinfo;
   static int  prev_info_flags;
   static int  prev_ParamNum;

   FunctionHelp_list_changed=0;
   if(FunctionHelp_list._isempty()) {
      FunctionHelp_list_changed=1;
      gLastContext_FunctionName="";
      gLastContext_FunctionOffset=-1;
      gLastKeywordList._makeempty();
   }
   _str cursor_offset=point('s');
   save_pos(auto p);
   int orig_left_edge=p_left_edge;
   goto_point(FunctionNameStartOffset);
   // enum, struct class
   _str search_string='[/=,(){[]|$';
   int status=search(search_string,'rh@');
   //boolean found_function_pointer=false;
   int ParamNum_stack[];
   _str ParamKeyword_stack[];
   int offset_stack[];  // offset of this function open parenthesis
   int stack_top=0;
   boolean DontCountFirstComma=true;
   ParamNum_stack[stack_top]=0;
   ParamKeyword_stack[stack_top]="";
   int nesting=0;
   for (;;) {
      if (status) {
         break;
      }
      if (cursor_offset<=point('s')) {
         break;
      }
      if (!match_length()) {
         if (_curlinecont()) {
            if(down()) break;
            _begin_line();
            status=search(search_string,'rh@');
            continue;
         }
         p_col=_text_colc(_line_length(1),'I')+1;
         if (cursor_offset<=point('s')) {
            break;
         }
         restore_pos(p);
         return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
      }
      _str cfg=_clex_find(0,'g');
      if (cfg==CFG_STRING || cfg==CFG_COMMENT) {
         status=repeat_search();
         continue;
      }
      _str ch=get_text();
      if (ch=='=') {
         save_pos(auto p2);
         status=_prev_nonblank_char();
         if (status) {
            restore_pos(p2);
            ++p_col;
            status=search(search_string,'rh@');
            continue;
         }
         ch=get_text();
         word_chars := _clex_identifier_chars();
         if (!pos('['word_chars']',ch,1,'r')) {
            //say('ch='ch' w='p_word_chars);stop();
            restore_pos(p2);
            ++p_col;
            status=search(search_string,'rh@');
            continue;
         }
         int end_col=p_col+1;
         search('[~'word_chars']\c|^\c','@rh');
         _str keyword=_expand_tabsc(p_col,end_col-p_col);
         restore_pos(p2);
         ++p_col;
         // Get the keyword to the left
         if (ParamNum_stack[stack_top]>0) {
            --ParamNum_stack[stack_top];
         }
         ParamKeyword_stack[stack_top]='='keyword;
         //say('keyword='keyword);stop();
         status=search(search_string,'rh@');
         continue;
      }
      if (ch=='/') {
         save_pos(auto p2);
         status=_prev_nonblank_char();
         if (status) {
            restore_pos(p2);
            ++p_col;
            status=search(search_string,'rh@');
            continue;
         }
         ch=get_text();
         restore_pos(p2);
         if (ch!=',' && ch!='(') {
            ++p_col;
            status=search(search_string,'rh@');
            continue;
         }
         if (ParamNum_stack[stack_top]>0) {
            --ParamNum_stack[stack_top];
         }
         ++p_col;
         int start_col=p_col;
         word_chars := _clex_identifier_chars();
         search('[~'word_chars']|$','@rhi');
         _str keyword=_expand_tabsc(start_col,p_col-start_col);
         ParamKeyword_stack[stack_top]='='keyword;
         status=search(search_string,'rh@');
         continue;
      }
      if (ch=='[' || ch=='{') {
         status=find_matching_paren(true);
         ++p_col;
         status=search(search_string,'rh@');
         continue;
      }
      if (ch==',') {
         if (DontCountFirstComma) {
            DontCountFirstComma=false;
            ++stack_top;
            ParamNum_stack[stack_top]=1;
            offset_stack[stack_top]=(int)point('s');
         } else {
            ++ParamNum_stack[stack_top];
         }
         ParamKeyword_stack[stack_top]="";
         status=repeat_search();
         continue;
      }
      if (ch==')') {
         DontCountFirstComma=false;
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
         DontCountFirstComma=false;
         // Determine if this is a new function
         ++stack_top;
         ParamNum_stack[stack_top]=1;
         ParamKeyword_stack[stack_top]="";
         offset_stack[stack_top]=(int)point('s');
         /*if (get_text(2)=='(*') {
            found_function_pointer = true;
         } */
         status=repeat_search();
         continue;
      }
      status=repeat_search();
   }
   VS_TAG_IDEXP_INFO idexp_info;
   tag_idexp_info_init(idexp_info);
   for (;;--stack_top) {
      if (stack_top<=0) {
         restore_pos(p);
         return(VSCODEHELPRC_NO_HELP_FOR_FUNCTION);
      }
      goto_point(offset_stack[stack_top]+1);
      status=_pro_get_expression_info(true,idexp_info,visited,depth);
      errorArgs[1] = idexp_info.lastid;

      if (_chdebug) {
         tag_idexp_info_dump(idexp_info,"_pro_fcthelp_get");
         say("_pro_fcthelp_get: status="status);
      }
      if (!status) {
         // get parameter number and cursor position
         int ParamNum=ParamNum_stack[stack_top];
         if (ParamNum<=0) ParamNum=1;
         set_scroll_pos(orig_left_edge,p_col);
         // check if anything has changed
         if (prev_prefixexp :== idexp_info.prefixexp &&
            gLastContext_FunctionName :== idexp_info.lastid &&
            gLastContext_FunctionOffset :== idexp_info.lastidstart_col &&
            prev_otherinfo :== idexp_info.otherinfo &&
            prev_info_flags == idexp_info.info_flags &&
            prev_ParamNum   == ParamNum) {
            if (!p_IsTempEditor) {
               FunctionHelp_cursor_x=(idexp_info.lastidstart_col-p_col)*p_font_width+p_cursor_x;
            }
            break;
         }
         // lastid is name of function or proc
         // (info_flags & VSAUTOCODEINFO_PVWAVE_IS_FUNC) indicates function
         // (info_flags & VSAUTOCODEINFO_PVWAVE_IS_PROC) indicates procedure

         // check if the symbol was on the kill list for this extension
         if (_check_killfcts(idexp_info.lastid, '', flags)) {
            continue;
         }

         tag_clear_matches();
         int num_matches=0;

         _UpdateContext(true);
         _UpdateLocals(true);
         typeless tag_files = tags_filenamea(p_LangId);
         tag_list_symbols_in_context(idexp_info.lastid, '', 
                                     0, 0, tag_files, '',
                                     num_matches, def_tag_max_function_help_protos,
                                     VS_TAGFILTER_ANYPROC, 
                                     VS_TAGCONTEXT_ALLOW_locals,
                                     true, p_EmbeddedCaseSensitive, visited, depth);
         //_message_box('lastid='lastid' num_matches='num_matches);

         int isproc=(idexp_info.info_flags & VSAUTOCODEINFO_PVWAVE_IS_PROC);
         // find matching symbols
         //say('lastid='lastid' num_matches='num_matches);
         _str match_list[];
         match_list._makeempty();
         // simplify the list, we don't care where the symbols came from
         int i;
         for (i=1; i<=num_matches; ++i) {
            _str tag_file,proc_name,type_name,file_name,class_name, signature, return_type;
            int line_no, tag_flags;
            tag_get_match(i,tag_file,proc_name,type_name,file_name,line_no,class_name,tag_flags,signature,return_type);
            if (_chdebug) {
               isay(depth, "_pro_fcthelp_get: proc_name="proc_name" class_name="class_name" type_name="type_name);
            }
            _str match_tag_name = idexp_info.lastid;
            if (isproc) {
               if (type_name:!='proc') {
                  continue;
               }
            } else {
               if (type_name:!='func') {
                  continue;
               }
            }
            match_list[match_list._length()] = proc_name "\t" signature "\t" ;
         }
         //_message_box('Nofmatches='match_list._length());

         // get rid of any duplicate entries
         match_list._sort();
         _aremove_duplicates(match_list, true);

         // translate functions into struct needed by function help
         if (match_list._length()>0) {
            FunctionHelp_list._makeempty();
            gLastKeywordList._makeempty();
            FunctionHelp_HelpWord = idexp_info.lastid;

            //say("FunctionHelp_cursor_x="FunctionHelp_cursor_x" lastid="lastid);
            for (i=0; i<match_list._length(); i++) {
               int k = FunctionHelp_list._length();
               if (k >= def_tag_max_function_help_protos) break;
               _str match_tag_name, signature;
               parse match_list[i] with match_tag_name "\t" signature "\t";
               int imatch=i+1;
#if STRIP_FUNCTION_KEYWORDS
               strip_function_keywords(signature);
#endif
               if (isproc) {
                  FunctionHelp_list[k].prototype= match_tag_name','signature;
               } else {
                  FunctionHelp_list[k].prototype= match_tag_name'('signature')';
               }
               int base_length=length(match_tag_name)+1;
               FunctionHelp_list[k].argstart[0]=0;
               FunctionHelp_list[k].arglength[0]=length(match_tag_name);
               FunctionHelp_list[k].ParamNum= -1;
               FunctionHelp_list[k].ParamName='';
               FunctionHelp_list[k].ParamType='';

               _str z_tag_file,z_proc_name,z_type_name,z_file_name;
               int z_line_no,z_tag_flags;
               _str z_class_name,z_signature,z_return_type;
               tag_get_match(imatch,z_tag_file,z_proc_name,z_type_name,
                             z_file_name,z_line_no,z_class_name,z_tag_flags,
                             z_signature,z_return_type);
               FunctionHelp_list[k].tagList[0].comment_flags=0;
               FunctionHelp_list[k].tagList[0].comments=null;
               FunctionHelp_list[k].tagList[0].filename=z_file_name;
               FunctionHelp_list[k].tagList[0].linenum=z_line_no;
               FunctionHelp_list[k].tagList[0].taginfo=tag_tree_compose_tag(z_proc_name,z_class_name,z_type_name,z_tag_flags,z_signature,z_return_type);

               //++base_length;
               // parse signature and map out argument ranges
               int  arg_pos  = 0;
               int ArgumentPosition=0;
               _str argument = _pro_next_arg(signature, arg_pos, 1);
               //say("_pro_fcthelp_get: signature="signature);
               while (argument != '') {
                  //say("_pro_fcthelp_get: argument="argument);
                  int j = FunctionHelp_list[k].argstart._length();
                  FunctionHelp_list[k].argstart[j]=base_length+arg_pos;
                  FunctionHelp_list[k].arglength[j]=length(argument);
                  if (pos('[''"]',argument,1,'r')) {
                     // Positional argument
                     ++ArgumentPosition;
                     if (ArgumentPosition==ParamNum) {
                        FunctionHelp_list[k].ParamNum=j;
                     }
                  } else {
                     if (pos('...',argument)) {
                        if (ParamNum>ArgumentPosition) {
                           FunctionHelp_list[k].ParamNum=j;
                        }
                     } else if (!pos('=',argument)) {
                        // Positional argument
                        ++ArgumentPosition;
                        //say('ArgPos='ArgumentPosition' ParamNum='ParamNum);
                        if (ArgumentPosition==ParamNum) {
                           FunctionHelp_list[k].ParamNum=j;
                        }
                     } else {
                        _str keyword;
                        parse argument with keyword'=';
                        //say("_pro_fcthelp_get: keyword="keyword);
                        gLastKeywordList[gLastKeywordList._length()]=keyword;
                     }
                  }
                  argument = _pro_next_arg(signature, arg_pos, 0);
               }
               //say('[k].ParamNum='FunctionHelp_list[k].ParamNum);
               /*if (ParamNum>=FunctionHelp_list[k].argstart._length() &&
                   pos('...',last_argument) && !pos('[''"]',last_argument,1,'r')) {
                  FunctionHelp_list[k].ParamNum= VSAUTOCODEARGFLAG_VAR_ARGS;
               } */
            }
            // Found some matches?
            if (FunctionHelp_list._length() > 0) {
               if (prev_ParamNum!=ParamNum) {
                  FunctionHelp_list_changed=1;
               }
               prev_prefixexp  = idexp_info.prefixexp;
               prev_otherinfo  = idexp_info.otherinfo;
               prev_info_flags = idexp_info.info_flags;
               prev_ParamNum   = ParamNum;
               if (!p_IsTempEditor) {
                  FunctionHelp_cursor_x=(idexp_info.lastidstart_col-p_col)*p_font_width+p_cursor_x;
               }
               break;
            }
         }
      }
   }
   if (idexp_info.lastid!=gLastContext_FunctionName || gLastContext_FunctionOffset!=idexp_info.lastidstart_offset) {
      FunctionHelp_list_changed=1;
      gLastContext_FunctionName=idexp_info.lastid;
      gLastContext_FunctionOffset=idexp_info.lastidstart_offset;
   }
   restore_pos(p);
   return(0);
}

/*
   PARAMETERS
      OperatorTyped     When true, user has just typed comma or
                        open paren.

                        Example
                           myfun(<Cursor Here>
                             OR
                           myproc ,

                        This should be false if cursorInsideArgumentList
                        is true.
      cursorInsideArgumentList
                        When true, user requested function help when
                        the cursor was inside an argument list.

                        Example
                          MessageBox(...,<Cursor Here>...)

                        Here we give help on MessageBox
      FunctionNameOffset  OUTPUT. Offset to start of function name.

      ArgumentStartOffset OUTPUT. Offset to start of first argument

  RETURN CODES
      0    Successful
      VSCODEHELPRC_CONTEXT_NOT_VALID
      VSCODEHELPRC_NOT_IN_ARGUMENT_LIST
      VSCODEHELPRC_NO_HELP_FOR_FUNCTION
*/
int _pro_fcthelp_get_start(_str (&errorArgs)[],
                           boolean OperatorTyped,
                         boolean cursorInsideArgumentList,
                         int &FunctionNameOffset,
                         int &ArgumentStartOffset,
                         int &flags
                         )
{
   errorArgs._makeempty();
   flags=0;
   VS_TAG_IDEXP_INFO idexp_info;
   tag_idexp_info_init(idexp_info);

   //if (cursorInsideArgumentList || OperatorTyped)
   typeless orig_pos;
   save_pos(orig_pos);
   int orig_col=p_col,orig_line=p_line;
   _str search_string='[,()]|^';
   int status=search(search_string,'-rh@');
   if (!status && p_line==orig_line && p_col==orig_col) {
      status=repeat_search();
   }
   ArgumentStartOffset= -1;
   word_chars := _clex_identifier_chars();
   for (;;) {
      if (status) break;
      if (!match_length()) {
         if (_linecont()) {
            if(up()) break;
            _end_line();
            status=search(search_string,'-rh@');
            continue;
         }
         break;
      }
      _str cfg=_clex_find(0,'g');
      if (cfg==CFG_STRING || cfg==CFG_COMMENT) {
         status=repeat_search();
         continue;
      }
      _str ch=get_text();
      //say("CCH="ch);
      if (ch=='(') {
         save_pos(auto p);
         if(p_col==1){up();_end_line();} else {left();}
         typeless p1,p2,p3,p4;
         save_search(p1,p2,p3,p4);
         _clex_skip_blanks('-');
         restore_search(p1,p2,p3,p4);
         ch=get_text();
         int junk;
         _str word=cur_word(junk);
         restore_pos(p);
         if (pos('['word_chars']',ch,1,'r')) {
            /*if (pos(' 'word' ',C_NOT_FUNCTION_WORDS)) {
               if (OperatorTyped && ArgumentStartOffset== -1) {
                  return(VSCODEHELPRC_CONTEXT_NOT_VALID);
               }
               break;
            }
            */

            ArgumentStartOffset=(int)point('s')+1;
         } else {
            /*
               OperatorTyped==true
                   Avoid giving help when have
                   myproc(....4+( <CursorHere>

            */
            if (OperatorTyped && ArgumentStartOffset== -1 ){
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
         }
      } else if (ch==')') {
         status=find_matching_paren(true);
         if (status) {
            restore_pos(orig_pos);
            return(1);
         }
         save_pos(auto p);
         if(p_col==1){up();_end_line();} else {left();}
         typeless p1,p2,p3,p4;
         save_search(p1,p2,p3,p4);
         _clex_skip_blanks('-');
         restore_search(p1,p2,p3,p4);
         int junk;
         _str word=cur_word(junk);
         /*if (pos(' 'word' ',' if while catch switch ')) {
            break;
         }
         */
         restore_pos(p);
      } else if (ch==',') {
         typeless p1,p2,p3,p4;
         save_search(p1,p2,p3,p4);
         right();
         struct VS_TAG_RETURN_TYPE visited:[];
         status=_pro_get_expression_info(true,idexp_info,visited);
         left();
         //_message_box('status='status);
         if (!status && (idexp_info.info_flags&VSAUTOCODEINFO_PVWAVE_IS_PROC)) {
            ArgumentStartOffset=(int)point('s')+1;
         }
         restore_search(p1,p2,p3,p4);
      } else  {
         break;
      }
      status=repeat_search();
   }
   if (ArgumentStartOffset<0) {
      return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
   }
   goto_point(ArgumentStartOffset);

   // Cursor is after , or (
   left();  // cursor to , or (
   left();  // cursor to before , or (
   search('[~ \t]|^','-rh@');  // Search for last char of ID
   if (pos('[~'word_chars']',get_text(),1,'r')) {
      return(VSCODEHELPRC_CONTEXT_NOT_VALID);
   }
   int end_col=p_col+1;
   search('[~'word_chars']\c|^\c','-rh@');
   idexp_info.lastid=_expand_tabsc(p_col,end_col-p_col);
   FunctionNameOffset=(int)point('s');
   /*if (pos(' 'lastid' ',C_NOT_FUNCTION_WORDS)) {
      return(VSCODEHELPRC_CONTEXT_NOT_VALID);
   }
   */
   return(0);
}


_str def_helpidx_filename;
int _pro_MaybeBuildTagFile(int &tfindex)
{
   // maybe we can recycle tag file(s)
   _str ext='pro';
   _str tagfilename='';
   if (ext_MaybeRecycleTagFile(tfindex,tagfilename,ext,ext)) {
      return(0);
   }
#if __VERSION__ >= 6
   if (gCheckedIfTagFileBuilt_pro) {
      return(1);
   }
   gCheckedIfTagFileBuilt_pro=true;
   if (check_wave_path()) {
      ext_BuildTagFile(tfindex,tagfilename,ext,"PV-WAVE Libraries",
                       true,"",ext_builtins_path(ext,ext));
      return(1);
   }
   _str vni_path=get_vni_path();
   _str std_libs=maybe_quote_filename(vni_path:+'*.pro');
   return ext_BuildTagFile(tfindex,tagfilename,ext,"PV-WAVE Libraries",
                           true,std_libs,ext_builtins_path(ext,ext));

#elif __VERSION__ >= 4
   tagFilesList := LanguageSettings.getTagFileList(ext);
   // IF the user does not have an extension specific tag file for Slick-C
   status=0;
   tagfilename=absolute(_tagfiles_path():+'pro.vtg');
   if (tagFilesList =='' || tag_read_db(tagfilename)==FILE_NOT_FOUND_RC) {
      if (gCheckedIfTagFileBuilt_pro) {
         return(1);
      }
      gCheckedIfTagFileBuilt_pro=true;
      if (check_wave_path()) return(1);
      // Tag the Slick-C macros
      tag_close_db(tagfilename);
      //status=tag_create_db(filename);
      //extra_file=get_env('VSROOT'):+'builtins.'ext;
      extra_file=ext_builtins_path(ext,ext);
      vni_path=get_vni_path();
      status=shell('maketags -t -n "PV-WAVE Libraries" -o 'maybe_quote_filename(tagfilename)' 'maybe_quote_filename(vni_path:+'*.pro'));
      if (!status && extra_file!='') {
         status=shell('maketags -r -o 'maybe_quote_filename(tagfilename)' 'maybe_quote_filename(extra_file));
      }                       

      LanguageSettings.setTagFileList(ext, tagfilename);
   }
   return(status);
#else
   return(0);
#endif
}
static int pvwave_init()
{
   //return(0);
   boolean file_exists=false;
   if (check_wave_path()) return(1);
   _str vni_path=get_vni_path();
   _str idxfilename="";
   _str wildcard="";
   _str filename="";
   if (machine()=='WINDOWS') {
#if __VERSION__>=4
      idxfilename=_replace_envvars(def_helpidx_filename);
#else
      idxfilename=def_helpidx_filename;
#endif
      file_exists=true;
      if (file_match('-p 'maybe_quote_filename(idxfilename),1)=="") {
         file_exists=false;
         def_helpidx_filename=_ConfigPath()'vslick.idx';
      }
      _nocheck _control _help_file_list,_add,_ok;
      wildcard=maybe_quote_filename(vni_path:+'wave\help\*.hlp');
      _str list[];
      filename=file_match(' -p 'wildcard,1);
      for (;;) {
         if (filename=="") {
            break;
         }
         list[list._length()]=filename;
         filename=file_match(wildcard,0);
      }
      if (file_exists) {
         int form_wid=show('-hidden _help_build_index_form');
         if (_iswindow_valid(form_wid)) {
            int i;
            for (i=0;i<list._length();++i) {
               form_wid._add.call_event(list[i],form_wid._add,LBUTTON_UP,'W');
            }
            form_wid._ok.call_event(form_wid._ok,LBUTTON_UP);
         }
         if (_iswindow_valid(form_wid)) {
            _message_box('Unable to index PV-WAVE help files');
            form_wid._delete_window();
         }
      } else {
         show('_help_build_index_form','',list,def_helpidx_filename);
      }
   }
   return(0);
}


static _str get_wave_path()
{
   return(def_wave_bin_path);
}
defeventtab _wave_path_form;
void ctlok.on_create()
{
   text1.p_text=def_wave_bin_path;
   label1.p_caption=label1.p_caption:+" (":+WAVE_EXE_NAME")";
}
void ctlok.lbutton_up()
{
   def_wave_bin_path=text1.p_text;
   if (last_char(def_wave_bin_path)!=FILESEP) {
      def_wave_bin_path=def_wave_bin_path:+FILESEP;
   }
   if (!wave_exe_found()) {
      int result=_message_box("Wave executable not found.\n\nDo you want to enter a different path?","",MB_YESNO);
      if (result==IDYES) {
         text1._set_focus();
         return;
      }
   }

   _config_modify_flags(CFGMODIFY_DEFVAR);
   p_active_form._delete_window();
}
void ctlbrowse.lbutton_up()
{
   _str result = _ChooseDirDialog('',p_prev.p_text);
   if( result=='' ) {
      return;
   }
   p_prev.p_text=result;
   p_prev._end_line();
   p_prev._set_focus();
}

static boolean wave_exe_found()
{
   return(file_match("-p "maybe_quote_filename(get_wave_path():+WAVE_EXE_NAME),1)!="");
}
// Returns true if wave exectuable not found
static boolean check_wave_path()
{
   if (!wave_exe_found()) {
      show('-modal _wave_path_form');
      return(!wave_exe_found());
   }
   return(false);
}
static _str get_vni_path()
{
   _str path=substr(def_wave_bin_path,1,length(def_wave_bin_path)-1);
   path=_strip_filename(path,'n');
#if !__UNIX__
   // strip bin\
   path=substr(path,1,length(path)-1);
   path=_strip_filename(path,'n');
#endif
   // Strip wave\
   path=substr(path,1,length(path)-1);
   path=_strip_filename(path,'n');
   return(path);
}
_command void compile_wave(_str filename="") name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   if (filename=="") {
      _message_box("No source file argument given");
      return;
   }
   if (check_wave_path()) return;
#if __UNIX__
   _str vni_path=get_vni_path();
   vni_path=substr(vni_path,1,length(vni_path)-1);  // Remove trailing backslash
   if (vni_path=="") return;

   _str temp_file=_temp_path()'waverun.sh';
   int temp_view_id=0;
   int orig_view_id=_create_temp_view(temp_view_id);
   p_UTF8=0;
   p_buf_name=temp_file;
   insert_line('#!/bin/sh');
   insert_line('');
   insert_line('RUN_FILE=$1');
   insert_line('VNI_DIR='vni_path);
   insert_line('COMPILE_OUTPUT=/tmp');
   insert_line('. $VNI_DIR/wave/bin/wvsetup.sh');
   insert_line('echo ".RUN" $RUN_FILE > ${COMPILE_OUTPUT}/waverun.pro');
   insert_line('echo "EXIT" >> ${COMPILE_OUTPUT}/waverun.pro');
   insert_line('wave ${COMPILE_OUTPUT}/waverun');
   insert_line('rm ${COMPILE_OUTPUT}/waverun.pro');
   insert_line('');
   insert_line('exit');
   int status=_save_file('+o');
   if (status) {
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
      _message_box(nls("Unable to write file '%s'"),temp_file);
      return;
   }
   _str cmdline=temp_file' 'filename;
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);
#if 1
   //_message_box('cmdline='cmdline);
   concur_command(cmdline);
   delete_file(temp_file);
#else
   dos('-e 'cmdline);
#endif
#else
   //set_env("VNI_DIR",vini_dir);
 /*
   @ECHO OFF
   SET VNI_DIR=C:\VNI
   SET WAVE_TMP=%VNI_DIR%\WAVE\TMP
   ECHO .RUN %1 > %WAVE_TMP%\waverun.pro
   ECHO EXIT >> %WAVE_TMP%\waverun.pro
   %VNI_DIR%\WAVE\BIN\BIN.I386NT\WAVE %WAVE_TMP%\waverun
   DEL %WAVE_TMP%\waverun.pro
   EXIT
*/
   _str temp_file=_temp_path()'waverun.pro';
   int temp_view_id=0;
   int orig_view_id=_create_temp_view(temp_view_id);
   p_UTF8=0;
   p_buf_name=temp_file;
   insert_line('.RUN 'filename);
   insert_line('EXIT');
   typeless status=_save_file('+o');
   if (status) {
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
      _message_box(nls("Unable to write file '%s'"),temp_file);
      return;
   }

   _str cmdline=def_wave_bin_path:+_strip_filename(WAVE_EXE_NAME,'E')' 'temp_file' >nul';
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);
   // IF we are running under windows 95
#if 1
   //reset_next_error();
   //_message_box('cmdline='cmdline);
   concur_command(cmdline);
#else
   dos('-e 'cmdline);
   //delete_file(temp_file);
#endif

#endif
}


_command pro_space() name_info(','VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   if ( command_state() || ! doExpandSpace(p_LangId) || p_SyntaxIndent<0 ||
      _in_comment() ||
      pro_expand_space() ) {
      if ( command_state() ) {
         call_root_key(' ');
      } else {
         keyin(' ');
      }
   } else if (_argument=='') {
      _undo('S');
   }
}

static SYNTAX_EXPANSION_INFO pro_space_words:[] = {
   'case'     => { "CASE ... OF ... ENDCASE" },
   'if'       => { "IF ... THEN BEGIN ... ENDIF" },
   'common'   => { "COMMON" },
   'pro'      => { "PRO ... END" },
   'function' => { "FUNCTION ... END" },
   'end'      => { "END" },
   'endelse'  => { "ENDELSE" },
   'endif'    => { "ENDIF" },
   'endfor'   => { "ENDFOR" },
   'endwhile' => { "ENDWHILE" },
   'endcase'  => { "ENDCASE" },
   'endrep'   => { "ENDREP" },
   'for'      => { "FOR ... DO BEGIN ... ENDFOR" },
   'while'    => { "WHILE ... DO BEGIN ... ENDWHILE" },
   'repeat'   => { "REPEAT BEGIN ... ENDREP UNTIL ..." },
};

/*
    Returns true if nothing is done.
*/
static boolean pro_expand_space()
{

   typeless status=0;
   _str orig_line="";
   get_line(orig_line);
   _str line=strip(orig_line,'T');
   _str orig_word=strip(line);
   if ( p_col!=text_col(_rawText(line))+1 ) {
      return(1);
   }
   _str aliasfilename='';
   _str word=min_abbrev2(orig_word,pro_space_words,name_info(p_index),aliasfilename);

   // can we expand an alias?
   if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return (expandResult != 0);
   }

   if ( word=='') return(1);

   set_surround_mode_start_line();
   line=substr(line,1,length(line)-length(orig_word)):+word;
   int width=text_col(_rawText(line),_rawLength(line)-_rawLength(word)+1,'i')-1;
   orig_word=word;
   word=lowcase(word);

   doNotify := true;
   if ( word=='if' ) {
      replace_line(_word_case(line:+'  then begin'));
      insert_line(indent_string(width)_word_case('endif'));
      set_surround_mode_end_line();
      up();_end_line();p_col-=11;
   } else if (word=='while') {
      replace_line(_word_case(line:+'  do begin'));
      insert_line(indent_string(width)_word_case('endwhile'));
      set_surround_mode_end_line();
      up();_end_line();p_col-=9;
   } else if (word=='repeat') {
      replace_line(_word_case(line:+' begin'));
      insert_line(indent_string(width)_word_case('endrep until '));
      up();_end_line();pro_enter();
      set_surround_mode_end_line(p_line+1);
   } else if (word=='pro' || word=='function') {
      replace_line(_word_case(line:+' '));
      insert_line(indent_string(width)_word_case('end'));
      up();_end_line();
   } else if (word=='for') {
      replace_line(_word_case(line:+'  do begin'));
      insert_line(indent_string(width)_word_case('endfor'));
      set_surround_mode_end_line();
      up();_end_line();p_col-=9;
   } else if (word=='case') {
      replace_line(_word_case(line:+'  of'));
      insert_line(indent_string(width)_word_case('endcase'));
      set_surround_mode_end_line();
      up();_end_line();p_col-=3;
   } else if (word=='common') {
      newLine := _word_case(line:+' ');
      replace_line(newLine);
      _end_line();

      doNotify = (newLine != orig_line);
   } else if (word=='end' || word=='endif' || word=='endelse' ||
              word=='endcase' ||word=='endfor' || word=='endwhile' ||
              word=='endrep') {
      replace_line(line);
      _str block_info="";
      col:=_pro_find_block_col(block_info,1);
      newLine := '';
      if (col) {
         newLine = indent_string(col-1)_word_case(orig_word)' ';
         replace_line(newLine);
         _end_line();
      } else {
         newLine = _word_case(line);
         replace_line(newLine);
         _end_line();++p_col;
      }

      doNotify = (newLine != orig_line);
   } else {
     status=1;
     doNotify = false;
   }

   if (!do_surround_mode_keys(false, NF_SYNTAX_EXPANSION) && doNotify) {
      // notify user that we did something unexpected
      notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
   }

   return(status);
}

int _pro_get_syntax_completions(var words, _str prefix="", int min_abbrev=0)
{
   return AutoCompleteGetSyntaxSpaceWords(words, pro_space_words, prefix, min_abbrev);
}

/*
    Returns true if nothing is done
*/
boolean _pro_expand_enter()
{
   save_pos(auto p);
   int orig_linenum=p_line;
   int orig_col=p_col;
   _str enter_cmd=name_on_key(ENTER);
   if (enter_cmd=='nosplit-insert-line') {
      _end_line();
   }
   int col=0;
   _str line="";
   get_line(line);
   _str lline=lowcase(line);
   if ((lline=='end' || lline=='endelse' ||
        lline=='endif' || lline=='endcase' || lline=='endfor' ||
        lline=='endwhile' || lline=='endrep')
        && p_col==_text_colc()+1
      ) {
      _str block_info="";
      col=_pro_find_block_col(block_info,1);
      if (col) {
         replace_line(indent_string(col-1)strip(line));_end_line();
         save_pos(p);
      }
   }

   int begin_col=pro_begin_stat_col(false /* No RestorePos */,
                              false /* Don't skip first begin statement marker */,
                              false /* Don't return first non-blank */,
                              true  /* Return 0 if no code before cursor. */,
                              false,
                              true
                              );
   if (!begin_col /*|| (p_line>orig_linenum)*/) {
      restore_pos(p);
      return(1);
   }
   restore_pos(p);
   boolean insert_line_cont=false;
   col=_pro_indent_col(0,insert_line_cont);
   if (insert_line_cont) {
      left();
      if (get_text():!=' ') {
         right();
         _insert_text(' ');
         //_clex_skip_blanks('-');++p_col;
      } else {
         right();
      }
      _insert_text('$');
   }
   indent_on_enter(0,col);
   return(0);
}
_command void pro_enter() name_info(','VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   generic_enter_handler(_pro_expand_enter);
}

static void nocomment_get_line(_str &line,int no_dollar_sign)
{
   p_col=1;
   search('[$;]|$','@rh');
   for (;;) {
      _str ch=get_text();
      int cfg=_clex_find(0,'g');
      if (ch=='$' && cfg!=CFG_STRING && cfg!=CFG_COMMENT) {
         line=_expand_tabsc(1,p_col-no_dollar_sign);
         break;
      }
      if (ch==';' && cfg==CFG_COMMENT) {
         line=_expand_tabsc(1,p_col-1);
         break;
      }
      if (!match_length()) {
         get_line(line);
         break;
      }
      repeat_search();
   }
}
int pro_proc_search(var proc_name, int find_first)
{
   int status=0;
   _str name="";
   _str type="";
   if ( find_first ) {
      if (proc_name!='') {
         parse proc_name with name '(' type ')';
         if (type=='proc') {
            status=search('pro[ \t]+\c'name, '@rihwxcs');
         } else if (type=='func') {
            status=search('function[ \t]+\c'name, '@rihwxcs');
         } else {
            status=search('(function|pro)[ \t]+\c'name, '@rihwxcs');
         }
      } else {
         word_chars := _clex_identifier_chars();
         status=search('(pro|function)[ \t]+\c['word_chars']#', '@rihwxcs');
      }
   } else {
      status=repeat_search();
   }
   _str line="";
   _str line2="";
   typeless p=0;
   typeless a1,a2,a3,a4;
   for (;;) {
      if ( status ) {
         return(status);
      }
      save_pos(p);
      save_search(a1,a2,a3,a4);
      nocomment_get_line(line,1);
      restore_search(a1,a2,a3,a4);
      parse line with type name','line;
      name=strip(name);
      type=lowcase(type);
      if (type=='function') {
         type='func';
      } else {
         type='proc';
      }

      save_search(a1,a2,a3,a4);
      while (_curlinecont()) {
         if(down()) break;
         nocomment_get_line(line2,1);
         line=line' ':+line2;
      }
      restore_search(a1,a2,a3,a4);
#if 0
      // Can't remove space in string literals
      {
         int i;
         i=1;
         _str result="";
         for (;;) {
            if (i>length(line)) {
               break;
            }
            int j=pos('[''"]',line,i,"r");
            if (!j) {
               j=length(line)+1;
            }
            result=result:+stranslate(substr(line,i,j-i),' ','[\t ]#','r');
            if (j>=length(line)) {
               break;
            }
            _str endch=substr(line,j,1);
            i=j;
            j=pos(endch,line,i+1);
            if (!j) {
               j=length(line)+1;
            }
            result=result:+substr(line,i,j-i+1);
            i=j+1;
         }
         line=result;
      }
      //line=stranslate(line,'','[\t ]','r');
#endif
      _str temp_proc_name=tag_tree_compose_tag(name,'',type,0,line);
      if (proc_name=='') {
         restore_pos(p);
         proc_name=temp_proc_name;
         return(0);
      }
      _str find_name="";
      _str find_type="";
      parse proc_name with find_name'('find_type')';
      if ((find_type:==type || find_type=="") && strieq(find_name,name)) {
         restore_pos(p);
         return(0);
      }
      _end_line();
      status=repeat_search();
   }
}

/*
    This functions make show_procs smarter by showing user
    all parameters and attributes of the function definition
    but not the code.
*/
void pro_find_lastprocparam()
{
   save_pos(auto p);
   while (_curlinecont()) {
      if(down()) break;
   }
   _end_line();
}

/*

*/
int _pro_find_block_col(_str &block_info /* currently just block word */,
                        typeless skipFirst="")
{
   boolean skip_first_hit = (skipFirst!='' && skipFirst);
   typeless orig_p2=0;
   typeless orig_pos;
   save_pos(orig_pos);
   int nesting;
   nesting=1;
   _str word="";
   typeless status=search('pro|function|begin|endif|endelse|case|endcase|endrep|endwhile|endfor|end','@-wihrxcs');
   //status=search('begin|endif','@-wirxcs');
   //status=search('xxx','@-wirxcs');
   for (;;) {
      if (status) {
         restore_pos(orig_pos);
         return(0);
      }
      if (skip_first_hit) {
         skip_first_hit=0;
         status=repeat_search();
         continue;
      }
      word=lowcase(get_match_text());
      //messageNwait('word='word' nesting='nesting);
      switch (word) {
      case 'case':
      case 'pro':
      case 'function':
         --nesting;
         break;
      case 'begin':
         /*
             look back for "do", if there, search backwards for
             "for" or "while"
             for i=1,200 do begin
             endfor
             while exp do begin
             endwhile
             if exp then begin
             endif
         */
         save_pos(orig_p2);
         if (p_col==1) {
            up();_end_line();
         } else {
            left();
         }
         typeless p1,p2,p3,p4;
         save_search(p1,p2,p3,p4);
         _clex_skip_blanks('-');
         restore_search(p1,p2,p3,p4);
         --nesting;
         int junk=0;
         word=lowcase(cur_word(junk));
         if (word=='do' || word=='then') {
            save_search(p1,p2,p3,p4);
            status=search('for|while|if','@-wihrxcs');
            restore_search(p1,p2,p3,p4);
            if (status) {
               restore_pos(orig_pos);
               return(0);
            }
            break;
         }
         restore_pos(orig_p2);
         break;
      case 'end':
      case 'endif':
      case 'endelse':
      case 'endcase':
      case 'endrep':
      case 'endwhile':
      case 'endfor':
         ++nesting;
         break;
      }
      //messageNwait('word='word' nesting='nesting);
      if (nesting<=0) {
         int junk;
         block_info=cur_word(junk);
         first_non_blank();
         int col=p_col;
         restore_pos(orig_pos);
         return(col);
      }
      status=repeat_search();
   }
}

   // IF we get fancy, we will want to pull some code from below.
/*


  DON't indent on BEGIN CLASS


  Block constructs
    [label:]EVENT LOOP [is]  page 98.
      PREREGISTER
         [statement_list]
      POSTREGISTER
         [statement_list]
      WHEN expression DO
         [statement_list]
    [EXCEPTION]
      WHEN expression DO
         [statement_list]
      ELSE [DO]
         [statement_list]
    END EVENT;

    EVENT CASE [IS]
      PREREGISTER
         [statement_list]
      POSTREGISTER
         [statement_list]
      WHEN expression DO
         [statement_list]
    [EXCEPTION]
      WHEN expression DO
         [statement_list]
      ELSE
         [statement_list]
    END EVENT;

    WHEN expression DO

    ELSE  -- part of exception or if statement

    IF expression THEN
    ELSEIF expression THEN
         [statement_list]
    ELSE
         [statement_list]
    [EXCEPTION]
      WHEN expression DO
         [statement_list]
      ELSE [DO]
         [statement_list]
    END IF;


    [label:]CASE expression IS
       WHEN expression DO
       ELSE [DO]


    [label:]WHILE expression DO
    [EXCEPTION]
      WHEN expression DO
         [statement_list]
      ELSE [DO]
         [statement_list]
    END WHILE;

    [label:]FOR expression IN expression [TO expression|CURSOR ...] DO
    [EXCEPTION]
      WHEN expression DO
         [statement_list]
      ELSE [DO]
         [statement_list]
    END FOR
    START TASK [object_reference.]method[(parameter_list)]
      [WHERE setting,setting,...]

    CLASS name [IS MAPPED] INHERITS [FROM] object_reference.]method
    HAS FILE filename;
    HAS PRIVATE
    HAS PUBLIC
      stuff
    HAS PROPERTY
    END CLASS

    INTERFACE name INHERITS [FROM] object_reference.]method
    HAS PUBLIC
      stuff
    HAS PROPERTY
    END INTERFACE;

    CURSOR name [(parameter_list)]
    BEGIN
       select_statement;
    END;

    BEGIN CLASS;
    END CLASS

    BEGIN [TOOL|C|DCE|OBB] project_name;
     [INCLUDES project_name;]
     [HAS PROPERTY {property;}
    END project_name;

    [label:] BEGIN [DEPENDENT|NESTED|INDEPENDENT] TRANSACTION]
    [EXCEPTION]
      WHEN expression DO
         [statement_list]
      ELSE [do]
         [statement_list]
    END TRANSACTION;


*/
/*

   Return beginning of statement column.  0 if not found.

*/
static int pro_begin_stat_col(boolean RestorePos,
                              boolean SkipFirstHit,
                              boolean ReturnFirstNonBlank,
                              boolean FailIfNoPrecedingText=false,
                              boolean AlreadyRecursed=false,
                              boolean FailWithMinus1_IfNoTextAfterCursor=false
                             )
{
   int orig_linenum=p_line;
   int orig_col=p_col;
   save_pos(auto p);
   boolean hit_top=false;
   if (_linecont()) {
      for (;;) {
         up();
         if (!_linecont()) {
            break;
         }
      }
      _begin_line();
   } else {
      _begin_line();
   }
   hit_top=p_line==1;
   int status=_clex_skip_blanks();
   if (status) {
      restore_pos(p);
      if (!hit_top) {
         if (!FailWithMinus1_IfNoTextAfterCursor) {
            return(p_col);
         }
         return(-1);
      }
      return(0);
   }
   if (ReturnFirstNonBlank) {
      first_non_blank();
   }
   int col=p_col;
   if (hit_top && FailIfNoPrecedingText && (p_line>orig_linenum || (p_line==orig_linenum)&& p_col>orig_col)) {
      return(0);
   }
   if (RestorePos) {
      restore_pos(p);
   }
   return(col);
#if 0
   orig_linenum=p_line;orig_col=p_col;
   save_pos(p);
   hit_top=false;
   for (;;) {
      _str line="";
      get_line(line);
      line=strip(line);
      if (last_char(line)=='$') {
         if (up()) {
            hit_top=true;
         }
         //SkipFirstHit=0;
         continue;
      }
      _end_line();
      status=_clex_skip_blanks();
      if (status) {
         restore_pos(p);
         if (!hit_top) {
            if (!FailWithMinus1_IfNoTextAfterCursor) {
               return(p_col);
            }
            return(-1);
         }
         return(0);
      }
      if (ReturnFirstNonBlank) {
         first_non_blank();
      }
      col=p_col;
      if (hit_top && FailIfNoPrecedingText && (p_line>orig_linenum || (p_line==orig_linenum)&& p_col>orig_col)) {
         return(0);
      }
      if (RestorePos) {
         restore_pos(p);
      }
      return(col);
   }
#endif

#if 0

   _str word="";
   int junk=0;
   orig_linenum=p_line;orig_col=p_col;
   //ReturnCurColIfCursorBetweenOpenBraceAndEOF=1;
   save_pos(p);
   status=search('[;]|then|do|else|begin|elseif|has|preregister|postregister|exception|is|includes','-RIh@xcs');
   int nesting=0;
   hit_top=false;
   for (;;) {
      if (status) {
         top();
         hit_top=true;
      } else {
         word=lowcase(get_match_text());
         if (word!=';' && !strieq(word,cur_word(junk))) {
            SkipFirstHit=0;
            status=repeat_search();
            continue;
         }
         /*switch (get_text()) {
         case '(':
            FailIfNoPrecedingText=false;
            if (nesting>0) {
               --nesting;
            }
            SkipFirstHit=false;
            status=repeat_search();
            continue;
         case ')':
            FailIfNoPrecedingText=false;
            ++nesting;
            SkipFirstHit=false;
            status=repeat_search();
            continue;
         }
         */
         if (SkipFirstHit || nesting) {
            FailIfNoPrecedingText=false;
            SkipFirstHit=false;
            status=repeat_search();
            continue;
         }
         p_col+=match_length();
      }
      status=_clex_skip_blanks();
      if (status) {
         restore_pos(p);
         /*
             Would could have an open brace followed by blanks and eof.
         */
         if (!hit_top) {
            if (!FailWithMinus1_IfNoTextAfterCursor) {
               return(p_col);
            }
            return(-1);
         }
         return(0);
      }
      /*
          We could have the following:

            class name:public name2 {

          recurse to look for "case" keyword

      */
      if (ReturnFirstNonBlank) {
         first_non_blank();
      }
      col=p_col;
      if (hit_top && FailIfNoPrecedingText && (p_line>orig_linenum || (p_line==orig_linenum)&& p_col>orig_col)) {
         return(0);
      }
      if (RestorePos) {
         restore_pos(p);
      }
      return(col);
   }
#endif
}
static int NoSyntaxIndentCase(int non_blank_col,int orig_linenum,int orig_col,typeless p,int syntax_indent)
{
   //_message_box("This case not handled yet");
   // SmartPaste(R) should set the non_blank_col
   if (non_blank_col) {
      //messageNwait("fall through case 1");
      restore_pos(p);
      return(non_blank_col);
   }
   restore_pos(p);
   int begin_stat_col=pro_begin_stat_col(false /* No RestorePos */,
                                   false /* Don't skip first begin statement marker */,
                                   true  /* Don't return first non-blank */
                                   );

   if (begin_stat_col && (p_line<orig_linenum ||
                          (p_line==orig_linenum && p_col<=orig_col)
                         )
      ) {
#if 0
      /*
          We could have code at the top of a file like the following:

             int myproc(int i)<ENTER>

             int myvar=<ENTER>
             class foo :<ENTER>
                public name2

      */
      //messageNwait("fall through case 2");
      restore_pos(p);
      return(begin_stat_col);
#endif
      /*
         Check if partial statement ends with close paren.  This
         could be a function declaration.

         Another to handle this is to to indent any way and then
         move the open brace to the correct colmun position when
         the users types it.
      */
      save_pos(auto p2);
      p_line=orig_linenum;p_col=orig_col;
      if (p_col==1) {
         up();_end_line();
      } else {
         left();
      }
      _clex_skip_blanks("-");
      _str ch=get_text();
      if (ch:==")") {
         restore_pos(p);
         return(begin_stat_col);
      }
      restore_pos(p2);
      /*
         Here we have something like
         int i;
            int k,<ENTER>
               <Cursor goes here>
               OR
         VOID<ENTER>
         <Cursor goes here>myproc()
      */
      int col=p_col;
      // Here we assume that functions start in column 1 and
      // variable declarations or statement continuations do not.
      // This seems to be a common solution.
      if (p_col==1 && ch!=',') {
         restore_pos(p);
         return(col);
      }
      int nextline_indent=syntax_indent;
      restore_pos(p);
      return(col+nextline_indent);
   }
   restore_pos(p);
   _str line="";
   get_line(line);
   line=expand_tabs(line);
   if (line=="") {
      restore_pos(p);
      return(p_col);
   }
   //messageNwait("fall through case 3");
   first_non_blank();
   int col=p_col;
   restore_pos(p);
   return(col);
}
static int HandlePartialStatement(int statdelim_linenum,
                                  int sameline_indent,
                                  int nextline_indent,
                                  int orig_linenum,int orig_col)
{
   _str orig_ch=get_text();
   _str orig_pos;
   save_pos(orig_pos);
   //linenum=p_line;col=p_col;

   /*
       Note that here we don't return first non-blank to handle the
       following case:

       for (;
            ;<ENTER>) {

       However, this does effect the following unusual case
           if (i<j) {abc;<ENTER>def;
           <end up here which is not correct>

       We won't worry about this case because it is unusual.
   */
   int begin_stat_col=pro_begin_stat_col(false /* No RestorePos */,
                                   false /* Don't skip first begin statement marker. */,
                                   false /* Don't return first non-blank */,
                                   false,
                                   false,
                                   true   // Fail if no text after cursor
                                   );
   if (begin_stat_col>0 && (p_line<orig_linenum || (p_line==orig_linenum && p_col<orig_col))
        /* && (linenum!=p_line || col!=p_col) */
      ) {
      // Now get the first non-blank column.
      begin_stat_col=pro_begin_stat_col(false /* No RestorePos */,
                                      false /* Don't skip first begin statement marker. */,
                                      true /* Return first non-blank */
                                      );
      /*
         Check if partial statement ends with close paren.  This
         could be a function declaration.

         Another to handle this is to to indent any way and then
         move the open brace to the correct colmun position when
         the users types it.
      */
      save_pos(auto p);
      p_line=orig_linenum;p_col=orig_col;
      if (p_col==1) {
         up();_end_line();
      } else {
         left();
      }
      _clex_skip_blanks("-");
      _str ch=get_text();
      if (ch:==")") {
         return(begin_stat_col);
      }
      restore_pos(p);
      /*
         IF semicolon is on same line as extra characters

         Example
            {b=<ENTER>
      */
      if (p_line==statdelim_linenum) {
         return(begin_stat_col+sameline_indent);
      }
      /*
         Here we have something like
         int i;
            int k,<ENTER>
               <Cursor goes here>
               OR
         VOID<ENTER>
         <Cursor goes here>myproc()
      */
      int col=p_col;
      // Here we assume that functions start in column 1 and
      // variable declarations or statement continuations do not.
      // This seems to be a common solution.
      if (p_col==1 && ch!=',') {
         return(col);
      }
      return(col+nextline_indent);
   }
   return(0);
}
static boolean _curlinecont()
{
   save_pos(auto p);
   typeless a1,a2,a3,a4;
   save_search(a1,a2,a3,a4);
   p_col=1;
   int status=search('\$|$','@rh');
   for (;;) {
      if (get_text()!='$') {
         restore_search(a1,a2,a3,a4);
         restore_pos(p);
         return(false);
      }
      int cfg=_clex_find(0,'g');
      if (cfg==CFG_COMMENT) {
         restore_search(a1,a2,a3,a4);
         restore_pos(p);
         return(false);
      }
      if (cfg!=CFG_STRING) {
         restore_search(a1,a2,a3,a4);
         restore_pos(p);
         return(true);
      }
      status=repeat_search();
   }
}
static boolean _linecont()
{
   save_pos(auto p);
   if(up()) return(false);
   typeless a1,a2,a3,a4;
   save_search(a1,a2,a3,a4);
   p_col=1;
   int status=search('\$|$','@rh');
   for (;;) {
      if (get_text()!='$') {
         restore_search(a1,a2,a3,a4);
         restore_pos(p);
         return(false);
      }
      int cfg=_clex_find(0,'g');
      if (cfg==CFG_COMMENT) {
         restore_search(a1,a2,a3,a4);
         restore_pos(p);
         return(false);
      }
      if (cfg!=CFG_STRING) {
         restore_search(a1,a2,a3,a4);
         restore_pos(p);
         return(true);
      }
      status=repeat_search();
   }
}
/*
   This code is just here incase we get fancy
*/
int _pro_indent_col(int non_blank_col,boolean &insert_line_cont)
{
   insert_line_cont=false;
   int orig_col=p_col;
   int orig_linenum=p_line;
   save_pos(auto p);
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   int syntax_indent=p_SyntaxIndent;
   // IF user does not want syntax indenting
   if ( syntax_indent<=0) {
      // Find non-blank-col
      return(NoSyntaxIndentCase(non_blank_col,orig_linenum,orig_col,p,0));
   }
   //style1=be_style & STYLE1_FLAG;
   //style2=be_style & STYLE2_FLAG;
   _str enter_cmd=name_on_key(ENTER);
   if (enter_cmd=='nosplit-insert-line') {
      _end_line();
   }
   int nesting=0;
   int OpenParenCol=0;
   if (p_col==1) {
      up();_end_line();
   } else {
      left();
   }

   int col=0;
   int cfg=0;
   _str ch="";
   typeless status=search('[()\[\]{}]|^','-@rh');
   for (;;) {
      if (status) {
         break;
      }
      //get_line(line);
      //pcol=_text_colc(p_col,'p');
      //parse line with line '[;$]','r';
      //ch=substr(line,pcol,1);
      ch=get_text();
      cfg=_clex_find(0,'g');
      if (ch!='' && cfg!=CFG_STRING && cfg!=CFG_COMMENT) {
         switch (ch) {
         case '(':
         case '[':
         case '{':
            if (!nesting && !OpenParenCol) {
               save_pos(auto p3);
               col=p_col;
               ++p_col;
               typeless a1,a2,a3,a4;
               save_search(a1,a2,a3,a4);
               for (;;) {
                  status=_clex_skip_blanks();
                  if (status) {
                     break;
                  }
                  if (get_text()=='$') {
                     if (down()) {
                        status=1;
                        break;
                     }
                     p_col=1;
                  } else {
                     break;
                  }
               }
               restore_search(a1,a2,a3,a4);
               //status=_clex_skip_blanks();
               if (!status && (p_line<orig_linenum ||
                               (p_line==orig_linenum && p_col<=orig_col)
                              )) {
                  col=p_col-1;
               }
               OpenParenCol=col;
               restore_pos(p3);
            }
            --nesting;
            break;
            //status=repeat_search();
            //continue;
         case ')':
         case ']':
         case '}':
            ++nesting;
            break;
            //status=repeat_search();
            //continue;
         }
      }
      if (p_col==1) {
         if (!_linecont()) {
            break;
         }
      }
      status=repeat_search();
   }

   int begin_stat_col=0;
   _str block_info="";
   _str line="";
   restore_pos(p);
   nocomment_get_line(line,0);
   restore_pos(p);
   //messageNwait('line='line' col='p_col);
   // IF we are splitting code or there is a pending open paren
   insert_line_cont=(expand_tabs(line,p_col)!="" &&
                     expand_tabs(line,1,p_col-1)!="") ||
                     (OpenParenCol && !_curlinecont());
   //messageNwait('lc='insert_line_cont' o='OpenParenCol);
   if (OpenParenCol) {
      col=OpenParenCol+1;
   } else {
      if (_linecont() || pos('$',line) || insert_line_cont) {
         //messageNwait('h1');
         begin_stat_col=pro_begin_stat_col(true /* RestorePos */,
                                    false /* Don't skip first begin statement marker */,
                                    true /* return first non-blank */
                                    );
         // This shouldn't fail
         if (begin_stat_col<=0) {
            col=NoSyntaxIndentCase(non_blank_col,orig_linenum,orig_col,p,0);
         } else {
            col=begin_stat_col+syntax_indent;
         }
      } else {
         //messageNwait('h2');
         col=_pro_find_block_col(block_info);
         if (col) {
            col+=syntax_indent;
         } else {
            col=NoSyntaxIndentCase(non_blank_col,orig_linenum,orig_col,p,0);
         }
      }

   }
   restore_pos(p);
   return(col);
#if 0
   // IF we are splitting the line
   if (_expand_tabsc(p_col)!="" && _expand_tabsc(1,p_col-1)!="") {
      // Splitting statement case
      // Find beginning of statement and indent
      begin_stat_col=pro_begin_stat_col(false /* No RestorePos */,
                                 false /* Don't skip first begin statement marker */,
                                 true /* return first non-blank */,
                                 true  /* Return 0 if no code before cursor. */,
                                 false,
                                 true
                                 );
      //messageNwait('begin_stat_col='begin_stat_col);
      if (!begin_stat_col) {
         return(NoSyntaxIndentCase(non_blank_col,orig_linenum,orig_col,p,0));
      }
      begin_stat_col+=syntax_indent;
      restore_pos(p);
      return(begin_stat_col);
   }
   save_pos(auto p2);
   search('^|\$[ \t]*$','@rh-');
   if (match_length()) {
      // Statement ends in $ and ENTER was pressed with cursor
      // after $
      // Indent from beginning of statement
      begin_stat_col=pro_begin_stat_col(false /* No RestorePos */,
                                 false /* Don't skip first begin statement marker */,
                                 true /* return first non-blank */,
                                 true  /* Return 0 if no code before cursor. */,
                                 false,
                                 true
                                 );
      if (!begin_stat_col) {
         return(NoSyntaxIndentCase(non_blank_col,orig_linenum,orig_col,p,0));
      }
      begin_stat_col+=syntax_indent;
      restore_pos(p);
      return(begin_stat_col);
   }
   restore_pos(p2);
   if (p_col==1) {
      up();_end_line();
   } else {
      left();
   }
   //messageNwait('h1');
   col=_pro_find_block_col(block_info);
   if (!col) {
      return(NoSyntaxIndentCase(non_blank_col,orig_linenum,orig_col,p,0));
   }
   col+=syntax_indent;
   restore_pos(p);
   return(col);
#endif


}
int pro_smartpaste(boolean char_cbtype,int first_col,int Noflines,boolean allow_col_1=false)
{
   typeless comment_col='';
   //If pasted stuff starts with comment and indent is different than code,
   // do nothing.
   get_line(auto first_line);
   int i=verify(first_line,' '\t);
   if ( i ) p_col=text_col(first_line,i,'I');
   if ( first_line!='' && _clex_find(0,'g')==CFG_COMMENT) {
      comment_col=p_col;
   }

   comment_col=p_col;
   // Look for first piece of code not in a comment
   typeless status=_clex_skip_blanks('m');
   // IF (no code found AND pasting comment) OR
   //   (code found AND pasting comment AND code col different than comment indent)
   if ((status && comment_col!='') || (!status && comment_col!='' && p_col!=comment_col)) {
      return(0);
   }

   _str block_info="";
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   int syntax_indent=p_SyntaxIndent;
   int junk=0;
   typeless enter_col=0;
   _str word=lowcase(cur_word(junk));
   if (!status && (word=='end' || word=='endif' ||
                   word=='endfor' || word=='endwhile' ||
                   word=='endcase' || word=='endelse' ||
                   word=='endrep')) {
      //messageNwait('it was an end');
      save_pos(auto p2);
      up();_end_line();
      enter_col=_pro_find_block_col(block_info);
      restore_pos(p2);
      if (!enter_col) {
         enter_col='';
      }
      _begin_select();get_line(first_line);up();
   } else {
      _begin_select();get_line(first_line);up();
      _end_line();
      enter_col=pro_enter_col();
      status=0;
   }
   //IF no code found/want to give up OR ... OR want to give up
   if (status || (enter_col==1 && !allow_col_1) || enter_col=='' ||
      (substr(first_line,1,1)!='' && (!char_cbtype ||first_col<=1))) {
      return(0);
   }
   return(enter_col);
}

static _str pro_enter_col()
{
   int enter_col=0;
   if ( command_state() || p_window_state:=='I' ||
      p_SyntaxIndent<0 || p_indent_style!=INDENT_SMART ||
      pro_enter_col2(enter_col) ) {
      return('');
   }
   return(enter_col);
}


static boolean pro_enter_col2(int &enter_col)
{
   boolean insert_line_cont=false;
   enter_col=_pro_indent_col(0,insert_line_cont);
   return(0);
}

defeventtab pro_keys;
def  'a'-'z','A'-'Z','_','0'-'9'= pro_maybe_case_word;
def  'BACKSPACE'= pro_maybe_case_backspace;
def ','=auto_functionhelp_key;
def '('=auto_functionhelp_key;
//def 'C- '=codehelp_complete;

//def ' '=sql_space;
//def ENTER=sql_enter;*/

//Returns 0 if the letter wasn't upcased, otherwise 1
_command void pro_maybe_case_word() name_info(','VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   _maybe_case_word(def_pro_autocase,gWord,gWordEndOffset);
}

_command void pro_maybe_case_backspace() name_info(','VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   _maybe_case_backspace(def_pro_autocase,gWord,gWordEndOffset);
}

_form _pro_extform {
   p_backcolor=0x80000005;
   p_border_style=BDS_DIALOG_BOX;
   p_caption='PV-WAVE Options';
   p_clip_controls=false;
   p_forecolor=0x80000008;
   p_height=2520;
   p_width=3150;
   p_x=8745;
   p_y=1155;
   _frame frame2 {
      p_backcolor=0x80000005;
      p_caption='Key&word case';
      p_clip_controls=true;
      p_forecolor=0x80000008;
      p_height=1800;
      p_tab_index=3;
      p_width=2820;
      p_x=180;
      p_y=150;
      _radio_button _lower {
         p_alignment=AL_LEFT;
         p_backcolor=0x80000005;
         p_caption='Lower case';
         p_forecolor=0x80000008;
         p_height=240;
         p_tab_index=1;
         p_tab_stop=true;
         p_value=1;
         p_width=2400;
         p_x=240;
         p_y=336;
      }
      _radio_button _upper {
         p_alignment=AL_LEFT;
         p_backcolor=0x80000005;
         p_caption='Upper case';
         p_forecolor=0x80000008;
         p_height=240;
         p_tab_index=2;
         p_tab_stop=true;
         p_value=0;
         p_width=2400;
         p_x=240;
         p_y=672;
      }
      _radio_button _capitalize {
         p_alignment=AL_LEFT;
         p_backcolor=0x80000005;
         p_caption='Capitalize first letter';
         p_forecolor=0x80000008;
         p_height=240;
         p_tab_index=3;
         p_tab_stop=true;
         p_value=0;
         p_width=2400;
         p_x=240;
         p_y=1008;
      }
      _check_box ctlautocase {
         p_alignment=AL_LEFT;
         p_backcolor=0x80000005;
         p_caption='&Auto case keywords';
         p_forecolor=0x80000008;
         p_height=360;
         p_style=PSCH_AUTO2STATE;
         p_tab_index=4;
         p_tab_stop=true;
         p_value=0;
         p_width=2400;
         p_x=240;
         p_y=1320;
      }
   }
   _command_button _ok {
      p_cancel=false;
      p_caption='OK';
      p_default=true;
      p_height=372;
      p_tab_index=7;
      p_tab_stop=true;
      p_width=900;
      p_x=180;
      p_y=2025;
   }
   _command_button  {
      p_cancel=true;
      p_caption='&Cancel';
      p_default=false;
      p_height=372;
      p_tab_index=8;
      p_tab_stop=true;
      p_width=900;
      p_x=1149;
      p_y=2025;
   }
   _command_button  {
      p_cancel=false;
      p_caption='&Help';
      p_default=false;
      p_height=372;
      p_help='PL/SQL Options dialog box';
      p_tab_index=9;
      p_tab_stop=true;
      p_width=900;
      p_x=2109;
      p_y=2025;
   }
}

defeventtab _pro_extform;
_ok.on_create()
{
   langID := "";
   parse p_active_form.p_name with '_' langID '_extform';
   scase := LanguageSettings.getKeywordCase(langID);
   switch (scase) {
   case 0:
      _lower.p_value = 1;
      break;
   case 1:
      _upper.p_value = 1;
      break;
   case 2:
      _capitalize.p_value = 1;
      break;
   }
   int acindex=find_index('def_'langID'_autocase',VAR_TYPE);
   ctlautocase.p_value=(int)_get_var(acindex);
}
_ok.lbutton_up()
{
   langID := "";
   parse p_active_form.p_name with '_' langID '_extform';

   int kw_case=0;
   if (_lower.p_value) kw_case = 0;
   else if(_upper.p_value) kw_case = 1;
   else kw_case = 2;
   LanguageSettings.setKeywordCase(langID, kw_case);

   int acindex=find_index('def_'langID'_autocase',VAR_TYPE);
   _set_var(acindex,(ctlautocase.p_value!=0));

   p_active_form._delete_window(0);
}

_form _wave_path_form {
   p_backcolor=0x80000005;
   p_border_style=BDS_DIALOG_BOX;
   p_caption='Wave Executable Directory';
   p_clip_controls=false;
   p_forecolor=0x80000008;
   p_height=2295;
   p_width=6060;
   p_x=1620;
   p_y=525;
   _label label1 {
      p_alignment=AL_LEFT;
      p_auto_size=false;
      p_backcolor=0x80000005;
      p_border_style=BDS_SUNKEN;
      p_caption="If you are NOT using PV-WAVE, press ESC to ignore this dialog.\r\rEnter the path to the wave executable";
      p_forecolor=0x80000008;
      p_height=945;
      p_tab_index=1;
      p_width=4500;
      p_word_wrap=true;
      p_x=240;
      p_y=240;
   }
   _text_box text1 {
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_FIXED_SINGLE;
      p_completion=FILE_ARG;
      p_forecolor=0x80000008;
      p_height=285;
      p_tab_index=2;
      p_tab_stop=true;
      p_width=4470;
      p_x=180;
      p_y=1245;
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
      p_y=1245;
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
      p_y=1845;
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
      p_y=1845;
   }
}
