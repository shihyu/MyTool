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
#import "se/lang/api/LanguageSettings.e"
#import "c.e"
#import "cbrowser.e"
#import "codehelp.e"
#import "codehelputil.e"
#import "context.e"
#import "cutil.e"
#import "listproc.e"
#import "pmatch.e"
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#endregion

using se.lang.api.LanguageSettings;

/*
   Support Functions for various assembly languages including:

      Intel/Windows NASM or MASM
      Unix Assemblers for Intel, SPARC, MIPS, HP, or PPC
      System/390 Assembler

   This support is dynamically loaded.
*/

//////////////////////////////////////////////////////////////////////////
// configuration settings for IBM HLASM
//

_str def_asm390_macro_path = "";
_str def_asm390_macro_extensions = ". .asm .asm390 .inc .maclib .mlc .mac";


/**
 * Return the given identifier in the specified case, depending
 * on the settings for language case in the file extension options.
 * <DL compact style="marginleft:20pt">
 * <DT>&lt; 0<DD>preserve case
 * <DT>0<DD>lowercase
 * <DT>1<DD>UPPERCASE
 * <DT>other<DD>Capitalize
 * </DL>
 *
 * @param s       word to modify case of
 * @return        's' with case adjusted appropriately 
 *  
 * @deprecated Use {@link_word_case} instead
 */
_str _asm390_keyword_case(_str s, bool confirm=true, _str sample="")
{
   return _word_case(s, confirm, sample);
}

//////////////////////////////////////////////////////////////////////////
// Intel and Unix assembly proc-search functions
//
// System/390 uses vsasm390_list_tags() in asmparse.dll.
//

static const ASM_COMMON_LIST= " proc macro equ .equ db dw dd ds struc label":+ \
                        " .equ .ent .entry .ident .include":+ \
                        " .lab .label .macro .set .struct":+ \
                        " @equ @macro struct = ";
static const ASM_PP_LIST=" #define #include ENTRY":+ \
                        " .ent .entry .ident .include":+ \
                        " .lab .label .macro .set .struct":+ \
                        " .ascii .asciz .byte .double .float":+ \
                        " .hword .int .long .octa .quad .short":+ \
                        " .space .string .word .endstruct .endmacro ";

/**
 * @see asm_proc_search
 */
int s_proc_search(_str &proc_name, int find_first)
{
   return(asm_proc_search(proc_name,find_first));

}
/**
 * @see asm_proc_search
 */
int unixasm_proc_search(_str &proc_name, int find_first)
{
   return(asm_proc_search(proc_name,find_first));

}
/**
 * @see asm_proc_search
 */
int masm_proc_search(_str &proc_name, int find_first)
{
   return(asm_proc_search(proc_name,find_first));

}
/**
 * <p>Search for the next tag in Unix or Intel assembly code.</p>
 * 
 * <p>If <i>proc_name</i> is '', then this function searches for the first or next occurrence
 * of an identifier defined by PROC, MACRO, : (label), EQU, DB, DW, DD, or STRUC in the
 * current buffer.  Search always starts from cursor position.  The find_first parameter
 * indicates whether this is the first or next call.  <i>proc_name</i> is set to the identifier
 * with the identifier type concatenated in parentheses.  For example, for a PROC or label
 * with name xxx, <i>proc_name</i> would be set to "xxx(proc)" or "xxx(label)" respectively.</p>
 * 
 * <p>If <i>proc_name</i> is not '', then <i>proc_name</i> specifies the identifier name and type to be
 * found and is the format "name(type)".  Searching begins at the cursor position.
 * <i>find_first</i> must be non-zero if <i>proc_name</i> is not ''.  The cursor is placed on the
 * definition found, if one is found.</p>
 * 
 * @param proc_name  (reference) set to tag name, in the format:
 *                   <code>TAGNAME([CLASS:]TYPE)</code>
 *                   See tag_tree_compose_tag() for more details.
 * @param find_first find first match or next match?
 * 
 * @return 0 on success, non-zero on error, STRING_NOT_FOUND_RC
 *         if there are no more tags found.
 * @categories Search_Functions
 */
int asm_proc_search(_str &proc_name, int find_first)
{
   search_key := "";
   bool proc_was_null;
   list_key := "";
   dmm_search_type := "";
   if ( proc_name:=="" ) {
      proc_was_null=true;
      proc_name=_clex_identifier_re();
   } else {
      parse proc_name with proc_name "("dmm_search_type")";
      /* help out label containing $ */
      proc_name=stranslate(proc_name,'\$',"$");
      proc_was_null=false;
   }
   colon_label := '([ \t]@'proc_name'\:)';
   _str key_label  ='('proc_name'(\:|[ \t]@$))';
   _str equ_label  ='\"'proc_name'\"[ \t]*\@equ';
   if ( find_first ) {
      if ( proc_was_null ) {
         search_key='^('colon_label'|':+
                        equ_label:+'|':+
                        key_label:+'|':+
                       stranslate(strip(_escape_re_chars(ASM_PP_LIST)),'|',' ')'|':+
                         '[ \t]@'proc_name'[ \t]+':+
                           '(':+
                              stranslate(strip(_escape_re_chars(ASM_COMMON_LIST)),'|',' ') :+
                           ')':+
                           '([ \t]|$)':+
                     ')';
      } else {
         list_key='([ \t]@'proc_name'[ \t]+'dmm_search_type')';
         if ( dmm_search_type:=='label' ) {
            search_key= '^('key_label'|'list_key')';
         } else if ( pos(" "dmm_search_type" ",ASM_COMMON_LIST) ) {
            search_key='^'list_key;
         }
      }
      mark_option := (p_EmbeddedLexerName != "")? 'm':"";
      search(search_key,'@rih'mark_option);
   } else {
      repeat_search();
   }
   line := "";
   first_word := "";
   second_word := "";
   args := "";
   value := "";
   for (;;) {
      get_line(line);
      parse line with first_word second_word args;
      while (_last_char(line) == "\\") {
         if (down()) break;
         get_line(line);
         args = strip(substr(args, 1, length(args)-1)) :+ " " :+ strip(line);
      }
      parse args with args "//" . ;
      parse args with args "/*" . ;
      if (pos("(",first_word)) {
         parse first_word with first_word "(" second_word ")";
      }
      parse first_word with first_word ":";
      // watch for end struct or end macro
      if (line == "ends" || line == "endm" || line=="endmacro") {
         repeat_search();
         if (rc) break;
         continue;
      }
      //say("asm_proc_search: first_word="first_word "second_word="second_word);
      _str orig_second_word = second_word;
      second_word=lowcase(second_word);
      if ( second_word!="" && pos(" "second_word" ",ASM_COMMON_LIST) ) {
         type := "";
         switch (second_word) {
         // nasm assembler keywords
         case "proc":    type="proc";    break;
         case "macro":   type="define";  break;
         case "=":       type="const";   break;
         case "equ":     type="const";   break;
         case "db":      type="var";     args=""; break;
         case "dd":      type="var";     args=""; break;
         case "dw":      type="var";     args=""; break;
         case "dd":      type="var";     args=""; break;
         case "ds":      type="var";     args=""; break;
         case "struc":   type="struct";  args=""; break;
         case "struct":  type="struct";  args=""; break;
         case "label":   type="label";   args=""; break;
         // unix assembler keywords
         case ".struct": type="struct";  args=""; break;
         case ".set":
         case ".equ":
            type="const";
            if (first_word=="") {
               parse args with first_word "," . ;
            }
            break;
         case "@equ":
            type="const";
            first_word = strip(first_word,"B",'"');
            break;
         case ".ent":
         case ".entry":
            type="func";
            parse args with first_word .;
            parse args with first_word "," . ;
            args="";
            break;
         /*
         case ".ascii":
         case ".asciz":
         case ".byte":
         case ".double":
         case ".float":
         case ".hword":
         case ".int":
         case ".long":
         case ".octa":
         case ".quad":
         case ".short":
         case ".space":
         case ".string":
         case ".word":   type="var";     break;
         */
         case ".lab":
         case ".label":
         case ".ident":
            type="label";
            parse args with first_word . ;
            parse args with first_word "," . ;
            args="";
            break;
         case ".macro":
            type="define";
            parse args with first_word . ;
            parse args with first_word "," args ;
            break;
         case "@macro":
            type="define";
            parse args with '\(' args '\)';
            break;
         case ".include":
            type="include";
            first_word=args;
            args="";
            break;
         }
         tag_init_tag_browse_info(auto cm, first_word, "", type);
         cm.arguments = args;
         proc_name=tag_compose_tag_browse_info(cm);
         break;
      } else if ( first_word!="" && pos(" "first_word" ",ASM_PP_LIST) ) {
         type := "";
         switch (first_word) {
         // nasm assembler keywords
         case ".macro":   type="define";  break;
         case "#define":  
            type="define";  
            value = args;
            args = "";
            break;
         case "#include": type="include"; args=""; break;
         case ".include": type="include"; args=""; break;
         case ".lab":     type="label";   args=""; break;
         case ".label":   type="label";   args=""; break;
         case ".ident":   type="label";   args=""; break;
         case "ENTRY":    type="func";    break;
         case ".ent":     type="func";    break;     
         case ".entry":   type="func";    break;
         case ".struct":  type="struct";  args=""; break;
         case ".set":     type="const";   break;
         case ".ascii":
         case ".asciz":
         case ".byte":
         case ".double":
         case ".float":
         case ".hword":
         case ".int":
         case ".long":
         case ".octa":
         case ".quad":
         case ".short":
         case ".space":
         case ".string":
         case ".word":   
            type="var";     
            args="";
            break;
         case ".endstruct":
         case ".endmacro":
            repeat_search();
            if (rc) return(rc);
            continue;
         }
         if (pos("(", orig_second_word)) {
            parse orig_second_word with orig_second_word "(" args ")" .;
         }
         tag_init_tag_browse_info(auto cm, orig_second_word, "", type);
         cm.arguments = args;
         cm.return_type = value;
         proc_name=tag_compose_tag_browse_info(cm);
         break;
      } else if ( pos('^[ \t]@'key_label,line,'1','RI'):=='1' &&
                 !pos('^[0-9]*[ \t]*\:',line,1,'r') ) {
         //say("asm_proc_search: line="line);
         parse line with proc_name":";
         proc_name = strip(proc_name);
         proc_name :+= "(label)";
         break;
      } else {
         repeat_search();
         if (rc) {
            break;
         }
      }
   }
   return(rc);
}

/**
 * Map the extension ("s" on Unix, "asm" on Windows) used to determine 
 * the language mode for embedded assembly in C/C++ code to a 
 * a different language.
 * 
 * @param mode_name     Language mode name 
 */
_command void set_embedded_asm_language(_str mode_name="") 
              name_info(MODENAME_ARG','VSARG2_READ_ONLY)
{
   // convert given mode name to a language ID 
   lang := _Modename2LangId(mode_name);
   if (mode_name != "" && lang == "") {
      _message_box("Language mode name not found: "mode_name);
      return;
   }

   // _CreateExtension can also modify extension mappings
   if (_isUnix()) {
      _CreateExtension("s", lang);
   } else {
      _CreateExtension("asm", lang);
   }

   // update buffers that may have embedded assembly 
   if (!_no_child_windows()) {
      _safe_hidden_window();
      first_buf_id := p_buf_id;
      for (;;) {
         if (_LanguageInheritsFrom("c")) {
            _SetEditorLanguage(p_LangId);
            _UpdateContext(true);
         }
         _next_buffer("HN");
         if ( p_buf_id==first_buf_id ) break;
      }
   }
}

/**
 * Build a tag file for ASM390 if there isn't one already.
 * At this point, the only item in the tagfile is asm390.tagdoc.
 *
 * @param tfindex        Set to the index of the extension specific tag file
 *
 * @return 0 on success, nonzero on error
 */
int _asm390_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   return ext_MaybeBuildTagFile(tfindex, "asm390", "asm390", 
                                "Assembly Opcodes and Macros", 
                                "", false, withRefs, useThread, forceRebuild);
}


//////////////////////////////////////////////////////////////////////////
/**
 * keymap addendums for System/390 Assembler language to trigger
 * auto function help or auto code help
*/
defeventtab asm390_keys;
def " "=asm390_space;
def tab=cob_tab;
def s_tab=cob_backtab;

/**
 * Handler for SPACE key in Assembly language
 */
_command void asm390_space() name_info(","VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   //say("asm390_space: here");
   if ( command_state() || ! doExpandSpace(p_LangId) || p_SyntaxIndent<0 || _in_comment() ||
        ext_expand_space()) {
      if ( command_state() ) {
         call_root_key(" ");
      } else {
         keyin(" ");
         if (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_FUNCTION_HELP) {
            _do_function_help(OperatorTyped:true, DisplayImmediate:false);
         }
      }
   } else if (_argument=="") {
      _undo('S');
   }
}
bool _asm390_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return return_true_if_uses_syntax_indent_property;
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

int _asm390_get_expression_info(bool PossibleOperator, VS_TAG_IDEXP_INFO &idexp_info,
                                VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   tag_idexp_info_init(idexp_info);
   if (_in_comment()) {
      return(VSCODEHELPRC_CONTEXT_NOT_VALID);
   }
   idexp_info.errorArgs._makeempty();
   idexp_info.prefixexp="";
   idexp_info.lastid="";
   idexp_info.otherinfo="";
   idexp_info.info_flags=VSAUTOCODEINFO_DO_LIST_MEMBERS;
   save_pos(auto orig_pos);
   word_chars := _clex_identifier_chars();
   if (PossibleOperator) {
      left();
      ch := get_text();
      if (ch=="(") {
         idexp_info.info_flags=VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN|VSAUTOCODEINFO_DO_FUNCTION_HELP;
      } else if (ch=="&") {
         idexp_info.prefixexp="&";
      } else {
         idexp_info.info_flags=VSAUTOCODEINFO_DO_FUNCTION_HELP;
      }
      idexp_info.lastidstart_col=p_col;  // need this for function pointer case
      left();
      search('[~ \t]|^','-rh@');
      // maybe there was a function pointer expression
      if (pos('[~'word_chars']',get_text(),1,'r')) {
         restore_pos(orig_pos);
         return VSCODEHELPRC_CONTEXT_NOT_VALID;
      }
      int end_col=p_col+1;
      search('[~'word_chars']\c|^\c','-rh@');
      idexp_info.lastid=_expand_tabsc(p_col,end_col-p_col);
      idexp_info.lastidstart_col=p_col;
      idexp_info.lastidstart_offset=(int)point('s');
   } else {
      // IF we are not on an id character.
      ch := get_text();
      end_col := done := 0;
      // IF we are not on an id character.
      if (pos('[~'word_chars']',get_text(),1,'r')) {
         orig_col := p_col;
         if (p_col > 1) {
            left();
         }
         if (pos('[~'word_chars']',get_text(),1,'r')) {
            right();
            int first_col=p_col-orig_col;
            if (get_text()=="(") {
               idexp_info.info_flags|=VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN;
            }
            idexp_info.prefixexp="";
            idexp_info.lastid="";
            idexp_info.lastidstart_col=p_col-first_col;
            idexp_info.lastidstart_offset=(int)point('s');
            end_col=idexp_info.lastidstart_col;
            done=1;
         }
      }
      if(!done) {
         int old_TruncateLength=p_TruncateLength;p_TruncateLength=0;
         //search('[~'p_word_chars']|$','r@');
         _TruncSearchLine('[~'word_chars']|$','r');
         end_col=p_col;
         // Check if this is a function call
         //search('[~ \t]|$','r@');
         _TruncSearchLine('[~ \t]|$','r');
         if (get_text()=="(") {
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
   }
   restore_pos(orig_pos);

   // do not find opcode for 'otherinfo' if this is a followed by paren case
   if (PossibleOperator && (idexp_info.info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN)) {
      idexp_info.otherinfo=idexp_info.lastid;
      p_col=1;idexp_info.prefixexpstart_offset=(int)_QROffset();
      restore_pos(orig_pos);
      return(0);
   }

   // search backwards in case if we are on a continuation line
   _str line;
   do {
      if (up()) {
         // did not find opcode
         restore_pos(orig_pos);
         return VSCODEHELPRC_CONTEXT_NOT_VALID;
      }
      _end_line();
      line=_expand_tabsc();
   } while (substr(line,72,1)!=" " && !_in_comment());
   down();
   line=_expand_tabsc();

   // compute position of label and opcode in current line
   llen := length(line);
   label := "";
   if (substr(line,1,1)!=" ") {
      parse line with label line;
   }
   line = strip(line,'L');
   int op_col=llen-length(line)+1;
   if (line=="") {
      op_col=idexp_info.lastidstart_col;
   }

   // is the cursor in the opcode
   //say("_asm390_get_expression_info: op_col="op_col" lastidcol="lastidstart_col" llen="llen" length(line)="length(line)" line="line"=");
   if (line=="" || op_col>30) {
      // no operator on this line
      idexp_info.otherinfo="-";
   } else if (op_col==idexp_info.lastidstart_col) {
      // yes, do not set 'otherinfo'
   } else {
      // no, cursor is elsewhere
      p_col=op_col;
      _TruncSearchLine('[~'word_chars']|$','r');
      idexp_info.otherinfo=_expand_tabsc(op_col,p_col-op_col);
   }

   // get the prefix expression start offset
   p_col=1;
   idexp_info.prefixexpstart_offset=(int)_QROffset();

   // that's all folks
   restore_pos(orig_pos);
   return(0);
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

int _s_get_expression_info(bool PossibleOperator, VS_TAG_IDEXP_INFO &idexp_info,
                           VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _asm390_get_expression_info(PossibleOperator,idexp_info, visited, depth);
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

int _unixasm_get_expression_info(bool PossibleOperator, VS_TAG_IDEXP_INFO &idexp_info,
                                 VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _asm390_get_expression_info(PossibleOperator,idexp_info,visited,depth);
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

int _masm_get_expression_info(bool PossibleOperator, VS_TAG_IDEXP_INFO &idexp_info,
                              VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _asm390_get_expression_info(PossibleOperator,idexp_info,visited,depth);
}

bool _asm390_autocomplete_after_replace(AUTO_COMPLETE_INFO &word,
                                           VS_TAG_IDEXP_INFO &idexp_info, 
                                           _str terminationKey="")
{
   if (terminationKey:==" " && (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_MEMBERS)) {
      last_event(" ");
      _do_function_help(OperatorTyped:true, DisplayImmediate:false);
      return false;
   }
   return true;
}
bool _asm_autocomplete_after_replace(AUTO_COMPLETE_INFO &word,
                                        VS_TAG_IDEXP_INFO &idexp_info, 
                                        _str terminationKey="")
{
   return _asm390_autocomplete_after_replace(word, idexp_info, terminationKey);
}
bool _s_autocomplete_after_replace(AUTO_COMPLETE_INFO &word,
                                      VS_TAG_IDEXP_INFO &idexp_info, 
                                      _str terminationKey="")
{
   return _asm390_autocomplete_after_replace(word, idexp_info, terminationKey);
}
bool _unixasm_autocomplete_after_replace(AUTO_COMPLETE_INFO &word,
                                            VS_TAG_IDEXP_INFO &idexp_info, 
                                            _str terminationKey="")
{
   return _asm390_autocomplete_after_replace(word, idexp_info, terminationKey);
}
bool _masm_autocomplete_after_replace(AUTO_COMPLETE_INFO &word,
                                         VS_TAG_IDEXP_INFO &idexp_info, 
                                         _str terminationKey="")
{
   return _asm390_autocomplete_after_replace(word, idexp_info, terminationKey);
}

/**
 * OS/390 Assembler Language specific find tag function.
 *
 * @param errorArgs          List of argument for codehelp error messages
 * @param prefixexp          prefix expression, see {@link _c_get_expression_info}
 * @param lastid             identifier under cursor
 * @param lastidstart_offset start offset of identifier under cursor
 * @param info_flags         bitset of VSAUTOCODEINFO_
 * @param otherinfo          extension specific information
 * @param find_parents       find matches in parent classes
 * @param max_matches        maximum number of matches to find
 * @param exact_match        exact match or prefix match for lastid?
 * @param case_sensitive     case sensitive match?
 * @param filter_flags       bitset of VS_TAGFILTER_*
 * @param context_flags      bitset of VS_TAGCONTEXT_*
 * @param visited            hash table of prior results
 * @param depth              depth of recursive search
 *
 * @return 0 on sucess, nonzero on error
 */
int _asm390_find_context_tags(
              _str (&errorArgs)[],
              _str prefixexp,_str lastid,
              int lastidstart_offset,int info_flags,
              typeless otherinfo,
              bool find_parents, int max_matches,
              bool exact_match, bool case_sensitive,
              SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
              SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
              VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
              VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // try to match the symbol in the current context
   tag_return_type_init(prefix_rt);
   errorArgs._makeempty();
   num_matches := 0;
   tag_files := tag_find_context_tags_filenamea(p_LangId, context_flags);
   tag_clear_matches();

   // prefix expression contains '&', list macro parameters
   // set up for listing members
   if (prefixexp == "&" && (context_flags & SE_TAG_CONTEXT_ALLOW_LOCALS)) {
      tag_list_class_locals( 0, 0, tag_files, 
                             lastid, "", 
                             SE_TAG_FILTER_ANY_DATA,
                             SE_TAG_CONTEXT_ONLY_LOCALS,
                             num_matches, max_matches, 
                             exact_match, case_sensitive, 
                             null, visited, depth+1);
      errorArgs[1] = "&"lastid;
      return (num_matches <= 0)? VSCODEHELPRC_NO_SYMBOLS_FOUND:0;
   }

   // otherinfo is not set, so list opcodes only
   //say("_asm390_find_context_tags: prefixexp="prefixexp" lastid="lastid);
   if (otherinfo == "" && 
       !(context_flags & SE_TAG_CONTEXT_ONLY_LOCALS) &&
       !(context_flags & SE_TAG_CONTEXT_ONLY_THIS_CLASS) &&
       !(context_flags & SE_TAG_CONTEXT_ONLY_THIS_FILE) &&
       !(context_flags & SE_TAG_CONTEXT_ONLY_INCLASS) &&
       !(context_flags & SE_TAG_CONTEXT_NO_GLOBALS)) {

      tag_list_context_globals(0, 0, lastid, true ,tag_files,
                               SE_TAG_FILTER_PROTOTYPE|SE_TAG_FILTER_DEFINE,
                               SE_TAG_CONTEXT_ANYTHING,
                               num_matches, max_matches,
                               exact_match, case_sensitive,
                               visited, depth+1);
      if (num_matches > 0) {
         // change symbol type to "statement" instead of function
         VS_TAG_BROWSE_INFO allInstructions[];
         tag_get_all_matches(allInstructions);
         tag_clear_matches();
         n := allInstructions._length();
         for (i:=0; i<n; i++) {
            if (allInstructions[i].type_name == "procproto") {
               allInstructions[i].type_name = "statement";
            }
            tag_insert_match_info(allInstructions[i]);
         }
         errorArgs[1] = lastid;
         return 0;
      }

      tag_list_symbols_in_context(lastid, "", 0, 0, tag_files, "",
                                  num_matches, max_matches,
                                  filter_flags, context_flags,
                                  exact_match, case_sensitive, 
                                  visited, depth+1);

      // Return 0 indicating success if anything was found
      errorArgs[1] = lastid;
      return (num_matches <= 0)? VSCODEHELPRC_NO_SYMBOLS_FOUND:0;
   }

   if (_LanguageInheritsFrom("asm390")) {
       filter_flags &= ~(SE_TAG_FILTER_PROTOTYPE|SE_TAG_FILTER_CONSTANT);
   }

   tag_list_symbols_in_context(lastid, "", 0, 0, tag_files, "",
                               num_matches, max_matches,
                               filter_flags, context_flags,
                               exact_match, case_sensitive, visited, depth+1);

   if (num_matches==0 && otherinfo!=null && upcase(otherinfo)=="COPY") {
      tag_list_symbols_in_context(lastid, "", 0, 0, tag_files, "",
                                  num_matches, max_matches,
                                  filter_flags, context_flags|SE_TAG_CONTEXT_ALLOW_ANY_TAG_TYPE,
                                  exact_match, case_sensitive, visited, depth+1);
   }
   // Return 0 indicating success if anything was found
   errorArgs[1]=lastid;
   int status=(num_matches == 0)? VSCODEHELPRC_NO_SYMBOLS_FOUND:0;
   return(status);
}

/**
 * @see _asm390_find_context_tags
 */
int _s_find_context_tags(
              _str (&errorArgs)[],
              _str prefixexp,_str lastid,
              int lastidstart_offset,int info_flags,
              typeless otherinfo,
              bool find_parents, int max_matches,
              bool exact_match, bool case_sensitive,
              SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
              SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
              VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
              VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   return _asm390_find_context_tags(errorArgs,prefixexp,lastid,lastidstart_offset,
                                    info_flags,otherinfo,find_parents,
                                    max_matches,exact_match,case_sensitive,
                                    filter_flags,context_flags,
                                    visited,depth,prefix_rt);
}
/**
 * @see _asm390_find_context_tags
 */
int _unixasm_find_context_tags(
              _str (&errorArgs)[],
              _str prefixexp,_str lastid,
              int lastidstart_offset,int info_flags,
              typeless otherinfo,
              bool find_parents, int max_matches,
              bool exact_match, bool case_sensitive,
              SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
              SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
              VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
              VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   return _asm390_find_context_tags(errorArgs,prefixexp,lastid,lastidstart_offset,
                                    info_flags,otherinfo,find_parents,
                                    max_matches,exact_match,case_sensitive,
                                    filter_flags,context_flags,
                                    visited,depth,prefix_rt);
}
/**
 * @see _asm390_find_context_tags
 */
int _masm_find_context_tags(
              _str (&errorArgs)[],
              _str prefixexp,_str lastid,
              int lastidstart_offset,int info_flags,
              typeless otherinfo,
              bool find_parents, int max_matches,
              bool exact_match, bool case_sensitive,
              SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
              SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
              VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
              VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   return _asm390_find_context_tags(errorArgs,prefixexp,lastid,lastidstart_offset,
                                    info_flags,otherinfo,find_parents,
                                    max_matches,exact_match,case_sensitive,
                                    filter_flags,context_flags,
                                    visited,depth,prefix_rt);
}
/**
 * @see _asm390_find_context_tags
 */
int _asm_find_context_tags(
              _str (&errorArgs)[],
              _str prefixexp,_str lastid,
              int lastidstart_offset,int info_flags,
              typeless otherinfo,
              bool find_parents, int max_matches,
              bool exact_match, bool case_sensitive,
              SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
              SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
              VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
              VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   return _asm390_find_context_tags(errorArgs,prefixexp,lastid,lastidstart_offset,
                                    info_flags,otherinfo,find_parents,
                                    max_matches,exact_match,case_sensitive,
                                    filter_flags,context_flags,
                                    visited,depth,prefix_rt);
}

//////////////////////////////////////////////////////////////////////////
// used by _asm390_fcthelp_get
//
static _str gLastContext_FunctionName;
static int gLastContext_FunctionOffset;

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
int _asm390_fcthelp_get_start(_str (&errorArgs)[],
                              bool OperatorTyped,
                              bool cursorInsideArgumentList,
                              int &FunctionNameOffset,
                              int &ArgumentStartOffset,
                              int &flags,
                              int depth=0)
{
   if (_chdebug) {
      isay(depth, "_asm390_fcthelp_get_start");
   }
   errorArgs._makeempty();
   flags=0;
   typeless orig_pos;
   save_pos(orig_pos);

   if (_in_comment()) {
      return(VSCODEHELPRC_CONTEXT_NOT_VALID);
   }

   // search backwards in case if we are on a continuation line
   _str line;
   do {
      if (up()) {
         // did not find opcode
         restore_pos(orig_pos);
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      }
      _end_line();
      line=_expand_tabsc();
   } while (substr(line,72,1)!=" " && !_in_comment());
   down();
   line=_expand_tabsc();

   // compute position of label and opcode in current line
   llen := length(line);
   label := "";
   if (substr(line,1,1)!=" ") {
      parse line with label line;
   }
   line = strip(line,"L");
   int op_col=llen-length(line)+1;
   _begin_line();
   p_col=op_col;
   FunctionNameOffset=(int)_QROffset();
   _begin_line();
   ArgumentStartOffset=(int)_QROffset();

   restore_pos(orig_pos);
   if (_QROffset() < ArgumentStartOffset) {
      return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
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
 * The asm390 version of this function is used to provide help when
 * entering arguments to an assembly opcode, directive, or macro call.
 * For example:
 * <pre>
 * label  LH    R9,LEN
 *               \____ cursor here
 * </pre>
 * Function help will show the following prototype for the R9,LEN argument
 * of the LH opcode, and the documentation for the LH opcode will be
 * displayed below it.
 * <ul>
 * <hr>
 * label  LH   storage
 * <hr>
 * [documentation for LH
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
int _asm390_fcthelp_get(_str (&errorArgs)[],
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
   errorArgs._makeempty();
   //say("_asm390_fcthelp_get");
   // avoid recalculating the expression when we don't have to
   static _str prev_prefixexp;
   static _str prev_otherinfo;
   static int  prev_info_flags;
   static int  prev_ParamNum;

   FunctionHelp_list_changed=false;
   if(FunctionHelp_list._isempty()) {
      FunctionHelp_list_changed=true;
      gLastContext_FunctionName="";
      gLastContext_FunctionOffset=-1;
   }
   word_chars := _clex_identifier_chars();
   common := '[,()]|['word_chars']#';
   _str cursor_offset=point('s');
   save_pos(auto p);
   orig_left_edge := p_left_edge;
   // find end line
   goto_point(FunctionNameStartOffset);
   last_line := p_RLine;
   for (;;) {
      if (_expand_tabsc(72,1)==" ") {
         break;
      }
      if (down()) break;
      last_line++;
   }
   // struct class
   goto_point(FunctionNameStartOffset);
   int ParamNum_stack[];
   int offset_stack[];  // offset of this function open parenthesis
   stack_top := 0;
   _TruncSearchLine('[~'word_chars']|$','r');
   int FunctionNameEndOffset=(int)point('s');
   offset_stack[stack_top]=(int)point('s');
   ParamNum_stack[stack_top]=1;
   stack_top++;
   ParamNum_stack[stack_top]=1;
   _TruncSearchLine('[~ \t]|$','r');
   offset_stack[stack_top]=(int)point('s');
   if (cursor_offset<=FunctionNameEndOffset) {
      ParamNum_stack[stack_top]=0;
   }
   nesting := 0;
   status := search(common,'rih@xc');
   for (;;) {
      if (status) {
         break;
      }
      ch_len := match_length();
      ch := get_text(ch_len);
      //say("_asm390_fcthelp_get(): ch="ch);
      //say("_asm390_fcthelp_get(ch="ch"):"get_text(10)" top="stack_top);
      if (stack_top>0 && cursor_offset<=(int)point('s')+ch_len-1) {
         break;
      }
      //say("_asm390_fcthelp_get: last_line="last_line" p_line="p_RLine);
      if (p_RLine>last_line) {
         restore_pos(p);
         return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
      }
      // hit statement terminator or start of new expression
      if (ch==",") {
         // parameter seperator for parenthesized expressions
         if (stack_top) {
            ++ParamNum_stack[stack_top];
         } else {
            // lost here
            break;
         }

      } else if (ch==")") {
         // end of parenthesized expression
         if (stack_top > 0) {
            --stack_top;
         }
         if (stack_top<=0) {
            // The close paren has been entered for the outer most function
            restore_pos(p);
            return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
         }

      } else if (ch=="(") {
         // Determine if this is a new function
         ++stack_top;
         ParamNum_stack[stack_top]=1;
         offset_stack[stack_top]=(int)point('s');

      } else if (pos('^['word_chars']#$',ch,1,'r')==1) {
         // parameter to using message
         //say("_asm390_fcthelp_get(): cursor="cursor_offset" seek="(int)point('s')+(ch_len-1));
         if (cursor_offset>(int)point('s')+ch_len) {
            //++ParamNum_stack[stack_top];
         }
         p_col+=(ch_len-1);
      }
      status=repeat_search();
   }
   if (stack_top<=0) {
      restore_pos(p);
      return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
   }
   FunctionHelp_list_changed=false;
   if(FunctionHelp_list._isempty()) {
      FunctionHelp_list_changed=true;
      gLastContext_FunctionName="";
      gLastContext_FunctionOffset=-1;
   }
   //say("_asm390_fcthelp_get(): stack_top="stack_top);
   _UpdateContext(true);
   _UpdateLocals(true);
   tag_files := tags_filenamea(p_LangId);
   context_id := tag_get_current_context(auto cur_tag_name,auto cur_tag_flags,
                                         auto cur_type_name,auto cur_type_id,
                                         auto cur_class_name,auto cur_class_only,
                                         auto cur_package_name,
                                         visited, depth+1);

   VS_TAG_IDEXP_INFO idexp_info;
   tag_idexp_info_init(idexp_info);
   for (;;--stack_top) {
      if (stack_top<=0) {
         restore_pos(p);
         return(VSCODEHELPRC_NO_HELP_FOR_FUNCTION);
      }
      goto_point(offset_stack[stack_top]);
      has_parenthesis := (get_text()=="(");
      if (has_parenthesis) {
         goto_point(offset_stack[stack_top]+1);
      }
      //say("_asm390_fcthelp_get(): point="point('s')" ch="get_text(10));

      status=_asm390_get_expression_info(true,idexp_info,visited,depth+1);
      idexp_info.errorArgs[1] = (idexp_info.lastid!="")? idexp_info.lastid:idexp_info.otherinfo;
      if (_chdebug) {
         tag_idexp_info_dump(idexp_info,"_asm390_fcthelp_get",depth);
         isay(depth, "_asm390_fcthelp_get: status="status);
      }
      if (!status) {
         // get parameter number and cursor position
         int ParamNum=ParamNum_stack[stack_top];
         //say("_asm390_fcthelp_get(): paramNum="ParamNum);
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

         // find matching symbols
         tag_flags := 0;
         globals_only := false;
         _str match_list[];
         _str match_symbol = (idexp_info.otherinfo!="")? idexp_info.otherinfo:idexp_info.lastid;
         match_class := "";
         match_tag := "";
         match_flags := SE_TAG_FILTER_ANY_PROCEDURE|SE_TAG_FILTER_DEFINE;

         //say("_asm390_fcthelp_get: here, match_symbol="match_symbol" otherinfo="otherinfo);

         // find symbols matching the given class
         num_matches := 0;
         tag_clear_matches();

         // analyse prefix epxression to determine effective class
         context_flags := globals_only? SE_TAG_CONTEXT_ANYTHING:SE_TAG_CONTEXT_ALLOW_LOCALS;
         tag_list_symbols_in_context(match_symbol, match_class, 0, 0, tag_files, "",
                                     num_matches, def_tag_max_function_help_protos,
                                     match_flags, context_flags, 
                                     true, false, visited, depth+1);


         // remove duplicates from the list of matches
         int unique_indexes[]; unique_indexes._makeempty();
         _str duplicate_indexes[]; duplicate_indexes._makeempty();
         removeDuplicateFunctions(unique_indexes,duplicate_indexes);
         num_unique := unique_indexes._length();
         for (i:=0; i<num_unique; i++) {
            j := unique_indexes[i];
            tag_get_match_browse_info(j, auto cm);
            //say("_asm390_fcthelp_get(): proc_name="cm.member_name", sig="cm.arguments);
            // maybe kick out if already have match or more matches to check
            if (match_list._length()>0 || i+1<num_unique) {
               //if (file_eq(file_name,p_buf_name) && line_no:==p_line) {
               //   say("_asm390_fcthelp_get(): 2");
               //   continue;
               //}
               if (tag_tree_type_is_class(cm.type_name)) {
                  continue;
               }
               if (cm.arguments=="" && (tag_flags & SE_TAG_FLAG_EXTERN)) {
                  continue;
               }
               if (cm.type_name :== "define") {
                  if (cm.arguments == "") {
                     continue;
                  }
                  cm.return_type = " macro";
               }
            }
            match_list[match_list._length()] = cm.member_name "\t" cm.type_name "\t" cm.arguments "\t" cm.return_type "\t" j "\t" duplicate_indexes[i];
         }

         // get rid of any duplicate entries
         //say("_asm390_fcthelp_get(): num_matches="match_list._length());

         match_list._sort();
         _aremove_duplicates(match_list, false);

         //say("_asm390_fcthelp_get(): num_matches="match_list._length());
         // translate functions into struct needed by function help
         have_matching_params := false;
         if (match_list._length()>0) {
            FunctionHelp_list._makeempty();
            FunctionHelp_HelpWord = match_symbol;

            for (i=0; i<match_list._length(); i++) {
               k := FunctionHelp_list._length();
               //say("_asm390_fcthelp_get(): i="i" k="k);
               if (k >= def_tag_max_function_help_protos) break;
               parse match_list[i] with auto match_tag_name "\t" auto match_type_name "\t" auto signature "\t" auto return_type "\t" auto imatch "\t" auto duplist;
               //say("_asm390_fcthelp_get("match_tag_name","signature","return_type")");
               base_length := length(match_tag_name);
               dot_length := 0;
               prototype := match_tag_name;
               if (has_parenthesis) {
                  strappend(prototype,"("signature")");
                  base_length++;
               } else {
                  strappend(prototype," "signature);
                  base_length++;
               }

               tag_get_match_browse_info((int)imatch, auto cm);
               tag_autocode_arg_info_from_browse_info(FunctionHelp_list[k], cm, prototype);
               FunctionHelp_list[k].argstart[0]=1;
               FunctionHelp_list[k].arglength[0]=length(match_tag_name);
               FunctionHelp_list[k].ParamNum=ParamNum;
               foreach (auto z in duplist) {
                  if (z == imatch) continue;
                  tag_get_match_browse_info((int)z, cm);
                  tag_autocode_arg_info_add_browse_info_to_tag_list(FunctionHelp_list[k], cm);
               }

               // parse signature and map out argument ranges
               j := 1;
               arg_pos := 0;
               argument := cb_next_arg(signature, arg_pos, 1);
               while (argument != "") {
                  j = FunctionHelp_list[k].argstart._length();
                  FunctionHelp_list[k].argstart[j]=base_length+arg_pos;
                  FunctionHelp_list[k].arglength[j]=length(argument);
                  if (j==ParamNum) {
                     FunctionHelp_list[k].ParamName=argument;
                  }
                  argument = cb_next_arg(signature, arg_pos, 0);
               }
               if (return_type!="") {
                  j = FunctionHelp_list[k].argstart._length();
                  FunctionHelp_list[k].argstart[j]=1;
                  FunctionHelp_list[k].arglength[j]=length(return_type)+11;
               }
               if (ParamNum != 1 && j < ParamNum) {
                  if (have_matching_params) {
                     FunctionHelp_list._deleteel(k);
                  }
               } else {
                  if (!have_matching_params) {
                     VSAUTOCODE_ARG_INFO func_arg_info = FunctionHelp_list[k];
                     FunctionHelp_list._makeempty();
                     FunctionHelp_list[0] = func_arg_info;
                  }
                  have_matching_params = true;
               }
            }
            // Found some matches?
            if (FunctionHelp_list._length() > 0) {
               if (prev_ParamNum!=ParamNum) {
                  FunctionHelp_list_changed=true;
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
      FunctionHelp_list_changed=true;
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
 * The most important items formated by the assembly are:
 * <ul compact>
 * <li>macros  -- assembler macros are formatted as they are declared
 * <li>opcodes -- assembler opcodes are formatted with their signatures
 * <li>procs   -- formatted as procedures
 * </ul>
 * <p>
 * If the verbose flags is passed, the declaration is prefaced with
 * an optional label and also includes the parameter list for the function.
 *
 * @param lang   value of p_LangId (ignored)
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
_str _asm390_get_decl(_str lang,VS_TAG_BROWSE_INFO &info,int flags=0,
                      _str decl_indent_string="",_str access_indent_string="")
{
   tag_flags := info.flags;
   tag_name  := info.member_name;
   type_name := info.type_name;
   result := "";
   proto  := "";
   verbose    := (flags&VSCODEHELPDCLFLAG_VERBOSE);
   show_class := (flags&VSCODEHELPDCLFLAG_SHOW_CLASS);

   //say("_asm390_get_decl: type_name="type_name);
   switch (type_name) {
   case "proc":         // procedure or command
   case "proto":        // function prototype
   case "constr":       // class constructor
   case "destr":        // class destructor
   case "func":         // function
   case "procproto":    // Prototype for procedure
   case "subfunc":      // Nested function or cobol paragraph
   case "subproc":      // Nested procedure or cobol paragraph
      _str before_return=decl_indent_string;
      arguments := "";
      if (verbose) {
         before_return :+= "{label} ";
         arguments=info.arguments;
      }
      result=before_return:+tag_name" "arguments;
      return(result);

   case "define":       // preprocessor macro definition
      if (lang=="s") {
         return(decl_indent_string" ":+_word_case(".macro"):+" ":+tag_name:+" "info.arguments);
      } else {
         return(decl_indent_string" ":+_word_case("MACRO"):+" ":+tag_name:+" ":+info.arguments);
      }

   case "typedef":      // type definition
      return(decl_indent_string:+_word_case("type"):+" "tag_name" = "info.return_type:+info.arguments);

   case "gvar":         // global variable declaration
   case "var":          // member of a class / struct / package
   case "lvar":         // local variable declaration
   case "prop":         // property
   case "param":        // function or procedure parameter
   case "group":        // Container variable
      if (verbose) {
         return(decl_indent_string:+tag_name" "info.return_type);
      }
      return(decl_indent_string:+tag_name);

   case "label":        // label
      return(decl_indent_string:+_word_case("LABEL"):+" "tag_name":");

   case "import":       // package import or using
      return(decl_indent_string:+_word_case("IMPORT"):+" "tag_name":");

   case "friend":       // C++ friend relationship
      return(decl_indent_string:+_word_case("FRIEND")" "tag_name:+info.arguments);

   case "include":      // C++ include or Ada with (dependency)
      return(decl_indent_string:+_word_case("COPY")" "tag_name".");

   case "form":         // GUI Form or window
      return(decl_indent_string:+"_form "tag_name);
   case "menu":         // GUI Menu
      return(decl_indent_string:+"_menu "tag_name);
   case "control":      // GUI Control or Widget
      return(decl_indent_string:+"_control "tag_name);
   case "eventtab":     // GUI Event table
      return(decl_indent_string:+"defeventtab "tag_name);

   case "const":        // pascal constant
      proto="";
      strappend(proto,info.member_name);
      strappend(proto," "_word_case("EQU")" "info.return_type);
      return(proto);

   case "file:":        // COBOL File descriptor
   case "database":     // SQL/OO Database
   case "table":        // Database Table
   case "column":       // Database Column
   case "index":        // Database index
   case "view":         // Database view
   case "trigger":      // Database trigger
   case "cursor":       // Database result set cursor
      return(decl_indent_string:+_word_case(type_name)" "tag_name);

   default:
      proto=decl_indent_string;
      strappend(proto,info.member_name);
      if (info.return_type!="") {
         strappend(proto," "_word_case("IS")" "info.return_type);
      }
      return(proto);
   }
}
/**
 * @see _asm390_get_decl
 */
_str _asm_get_decl(_str lang, VS_TAG_BROWSE_INFO &info, int flags=0,
                   _str decl_indent_string="",
                   _str access_indent_string="")
{
   return _asm390_get_decl(lang,info,flags,decl_indent_string,access_indent_string);
}
/**
 * @see _asm390_get_decl
 */
_str _s_get_decl(_str lang, VS_TAG_BROWSE_INFO &info, int flags=0,
                 _str decl_indent_string="",
                 _str access_indent_string="")
{
   return _asm390_get_decl(lang,info,flags,decl_indent_string,access_indent_string);
}
/**
 * @see _asm390_get_decl
 */
_str _unixasm_get_decl(_str lang, VS_TAG_BROWSE_INFO &info, int flags=0,
                       _str decl_indent_string="",
                       _str access_indent_string="")
{
   return _asm390_get_decl(lang,info,flags,decl_indent_string,access_indent_string);
}
/**
 * @see _asm390_get_decl
 */
_str _masm_get_decl(_str lang, VS_TAG_BROWSE_INFO &info, int flags=0,
                    _str decl_indent_string="",
                    _str access_indent_string="")
{
   return _asm390_get_decl(lang,info,flags,decl_indent_string,access_indent_string);
}

//////////////////////////////////////////////////////////////////////////
// find matching words if they have C preprocessing in their assembly code
// 
int _asm_find_matching_word(bool quiet,int pmatch_max_diff_ksize=MAXINT,int pmatch_max_level=MAXINT)
{
   return(_c_find_matching_word(quiet,pmatch_max_diff_ksize,pmatch_max_level));
}
int _s_find_matching_word(bool quiet,int pmatch_max_diff_ksize=MAXINT,int pmatch_max_level=MAXINT)
{
   return(_c_find_matching_word(quiet,pmatch_max_diff_ksize,pmatch_max_level));
}
int _unixasm_find_matching_word(bool quiet,int pmatch_max_diff_ksize=MAXINT,int pmatch_max_level=MAXINT)
{
   return(_c_find_matching_word(quiet,pmatch_max_diff_ksize,pmatch_max_level));
}
int _masm_find_matching_word(bool quiet,int pmatch_max_diff_ksize=MAXINT,int pmatch_max_level=MAXINT)
{
   return(_c_find_matching_word(quiet,pmatch_max_diff_ksize,pmatch_max_level));
}

//////////////////////////////////////////////////////////////////////////
// get location of macros
//
static _str gasm390_macro_path;
/**
 * Get the configured location for ASM390 macros, which is the
 * composition of the environment variable VSLICKASM390PATH,
 * and the project include directory.  It is cached in the static
 * global variable 'gasm390_macro_path', above.
 */
_str get_asm390_macro_path()
{
   // get the project or default COBOL project compiler include paths
   _str asm390_macro_path=gasm390_macro_path;
   if (gasm390_macro_path==null) {
      if (_project_name!=""|| (_isEditorCtl() && _LanguageInheritsFrom("asm390"))) {
         asm390_macro_path=project_include_filepath();
         gasm390_macro_path=asm390_macro_path;
         //say("get_asm390_macro_path: project path="asm390_macro_path);
      } else {
         asm390_macro_path="";
         gasm390_macro_path=null;
      }
   }
   // check for the new VSLICKASM390PATH environment variable
   env_asm390_macro_path := get_env("VSLICKASM390PATH");
   if (env_asm390_macro_path!="") {
      _maybe_append(asm390_macro_path,PATHSEP);
      strappend(asm390_macro_path,env_asm390_macro_path);
   }
   // check the def var
   _str temp=def_asm390_macro_path;
   if (temp!="") {
      _maybe_append(asm390_macro_path,PATHSEP);
      strappend(asm390_macro_path,temp);
   }
   // remove duplicates from the path and that's all folks!
   //say("get_asm390_macro_path: path="asm390_macro_path);
   return(RemoveDupsFromPathList(asm390_macro_path,true));
}
/**
 * Get the configured list of file extensions that can contain 
 * ASM390 macros and copy books. 
 */
_str get_asm390_macro_extensions()
{
   return def_asm390_macro_extensions;
}

/**
 * If they switch projects, reset the macro include path
 */
void _prjopen_asm390()
{
   gasm390_macro_path=null;
}
/**
 * If they switch projects, reset the macro include path
 */
void _prjclose_asm390()
{
   gasm390_macro_path=null;
}
/**
 * If they switch projects, reset the macro include path
 */
void _prjupdate_asm390()
{
   gasm390_macro_path=null;
}
/**
 * If they switch projects, reset the macro include path
 */
void _prjupdatedirs_asm390()
{
   gasm390_macro_path=null;
}

/**
 * @see _asm390_find_context_tags
 */
int _npasm_find_context_tags(
              _str (&errorArgs)[],
              _str prefixexp,_str lastid,
              int lastidstart_offset,int info_flags,
              typeless otherinfo,
              bool find_parents, int max_matches,
              bool exact_match, bool case_sensitive,
              SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
              SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
              VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
              VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   return _asm390_find_context_tags(errorArgs,prefixexp,lastid,lastidstart_offset,
                                    info_flags,otherinfo,find_parents,
                                    max_matches,exact_match,case_sensitive,
                                    filter_flags,context_flags,
                                    visited,depth,prefix_rt);
}

/**
 * @see _asm390_get_decl
 */
_str _npasm_get_decl(_str lang, VS_TAG_BROWSE_INFO &info, int flags=0,
                     _str decl_indent_string="",
                     _str access_indent_string="")
{
   return _asm390_get_decl(lang,info,flags,decl_indent_string,access_indent_string);
}

int _npasm_get_expression_info(bool PossibleOperator, VS_TAG_IDEXP_INFO &idexp_info,
                               VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _asm390_get_expression_info(PossibleOperator,idexp_info,visited,depth);
}

/**
 * @see asm_proc_search
 */
int npasm_proc_search(_str &proc_name, int find_first)
{
   return(asm_proc_search(proc_name,find_first));

}

/**
 * @see _asm390_fcthelp_get
 */
int _npasm_fcthelp_get(_str (&errorArgs)[],
                       VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                       bool &FunctionHelp_list_changed,
                       int &FunctionHelp_cursor_x,
                       _str &FunctionHelp_HelpWord,
                       int FunctionNameStartOffset,
                       int flags,
                       VS_TAG_BROWSE_INFO symbol_info=null,
                       VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return(_asm390_fcthelp_get(errorArgs,
                              FunctionHelp_list,
                              FunctionHelp_list_changed,
                              FunctionHelp_cursor_x,
                              FunctionHelp_HelpWord,
                              FunctionNameStartOffset,
                              flags, symbol_info,
                              visited, depth));
}

/**
 * @see _asm390_fcthelp_get_start
 */
int _npasm_fcthelp_get_start(_str (&errorArgs)[],
                             bool OperatorTyped,
                             bool cursorInsideArgumentList,
                             int &FunctionNameOffset,
                             int &ArgumentStartOffset,
                             int &flags,
                             int depth=0)
{

   return(_asm390_fcthelp_get_start(errorArgs, OperatorTyped, cursorInsideArgumentList,
                                    FunctionNameOffset,ArgumentStartOffset,flags,
                                    depth));
}

/**
 * Builds a tagfile for NPASM based on npasm.tagdoc in the SlickEdit builtins directory.
 * 
 * @return 
 */
int _npasm_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   return(ext_MaybeBuildTagFile(tfindex,"npasm","npasm","NPASM Libraries", "", false, withRefs, useThread, forceRebuild));
}
