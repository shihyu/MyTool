////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47785 $
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
#include "color.sh"
#import "adaptiveformatting.e"
#import "beautifier.e"
#import "c.e"
#import "clipbd.e"
#import "listproc.e"
#import "markfilt.e"
#import "notifications.e"
#import "pascal.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "util.e"
#import "vi.e"
#require "se/lang/api/LanguageSettings.e"
#endregion

using se.lang.api.LanguageSettings;

/*
   SmartPaste(R)
*/

#define MAX_PASTE 400       /* Don't adjust paste of more than 400 lines. */
#define MAX_PASTE_BYTES (400*32)   /* Don't adjust paste of more than 400*32 bytes. */

_str _skip_pp;

int smart_paste(_str markid='',_str copymove_option='', _str cbname='',
                boolean isClipboard=true,_str cbtype='')
{
   // first line of block of lines pasted in
   typeless orig_line = point();

   // support embedded modes
   embedded_status := _EmbeddedStart(auto orig_values);

   // paste the text
   int status = smart_paste2(markid, copymove_option, cbname, isClipboard);

   // check if the block pasted is dynamic surround worthy
   if (cbtype == 'line' && !status) {
      save_pos(auto p);
      last_line := point('L');
      goto_point(orig_line);
      if (def_line_insert == 'A') down();
      dynamic_surround(true, last_line);
      restore_pos(p);
   }

   // ok, now break out of embedded mode
   if (embedded_status == 1) {
      _EmbeddedEnd(orig_values);
   }
   return(status);
}
static int smart_paste2(_str markid='',_str copymove_option='',_str cbname='',boolean isClipboard=true)
{
   _str etab_name="";
   if( def_keys=='vi-keys' ) {
      if( upcase(vi_get_vi_mode())=='C' ) {
         etab_name=vi_name_on_key('','IK');
      } else {
         etab_name=name_name(p_mode_eventtab);
      }
   } else {
      etab_name=name_name(p_mode_eventtab);
   }

   //etab_name=name_name(p_mode_eventtab)
   _str lang="";
   typeless status=0;
   int smartpaste_index=0;
   int index=0;
// typeless expand="";
// parse name_info(_edit_window().p_index) with . expand .;
   int syntax_indent=p_SyntaxIndent;
   if (copymove_option!='') {
      if (_select_type(markid)=='') {
         message(get_message(TEXT_NOT_SELECTED_RC));
         return(TEXT_NOT_SELECTED_RC);
      }
      if (p_hex_mode || syntax_indent<=0 || p_indent_style!=INDENT_SMART ||
           copy_too_large(markid)>MAX_PASTE ||
          _select_type(markid)=='BLOCK' ||
          (_select_type(markid)=='CHAR' &&
            (!SupportCharSelection(markid) || !pasting_at_blanks())
          ) ||
          _smart_in_comment()) {
         lock_selection(1);
         if (upcase(copymove_option)=='M') {
            status=_move_to_cursor(markid);
         } else {
            status=_copy_to_cursor(markid);
         }
         return(status);
      }
      int start_col=0, end_col=0, junk=0;
      _get_selinfo(start_col,end_col,junk,markid);
      lang=p_LangId;
      smartpaste_index = _FindLanguageCallbackIndex('%s_smartpaste',lang);
      smartPasteOn := LanguageSettings.getSmartPaste(lang) && !beautify_paste_expansion(lang);
      if (smartpaste_index && smartPasteOn) {
         return(ext_smartpaste(smartpaste_index,markid,copymove_option,0,cbname,start_col,lang,isClipboard));
      }
      if (upcase(copymove_option)=='M') {
         status=_move_to_cursor(markid);
      } else {
         status=_copy_to_cursor(markid);
      }
      return(status);
   }
   int temp_view_id=_cvtsysclipboard(cbname,isClipboard);
   if (p_hex_mode==HM_HEX_ON || syntax_indent<=0 || p_indent_style!=INDENT_SMART ||
       !_isclipboard_internal(1,isClipboard) || clipboard_iNoflines(temp_view_id)>MAX_PASTE ||
       clipboard_size(temp_view_id)>MAX_PASTE_BYTES ||
       clipboard_itype(temp_view_id)=='BLOCK' ||
       (clipboard_itype(temp_view_id)=='CHAR' &&
          (!SupportCharSelection2(temp_view_id) || !pasting_at_blanks())
          //(clipboard_iNoflines(temp_view_id)==1 || !pasting_at_blanks())
        ) ||
       _smart_in_comment()) {
      return(paste2(def_persistent_select,temp_view_id,cbname,isClipboard));
   }
   lang=p_LangId;
   smartpaste_index = _FindLanguageCallbackIndex('%s_smartpaste',lang);
   smartPasteOn := LanguageSettings.getSmartPaste(lang) && !beautify_paste_expansion(lang);
   if (smartpaste_index && smartPasteOn) {
      return(ext_smartpaste(smartpaste_index,markid,copymove_option,temp_view_id,cbname,clipboard_col(temp_view_id),lang,isClipboard));
   }
   return(paste2(def_persistent_select,temp_view_id,cbname,isClipboard));
}
static int copy_too_large(typeless markid)
{
   int orig_buf_id=p_buf_id;
   int start_col=0, end_col=0, buf_id=0;
   _get_selinfo(start_col,end_col,buf_id,markid);
   p_buf_id=buf_id;
   typeless orig_pos;
   save_pos(orig_pos);
   _begin_select(markid);
   typeless bpoint=point();
   _end_select(markid);
   typeless epoint=point();
   restore_pos(orig_pos);
   p_buf_id=orig_buf_id;
   parse epoint with epoint .;
   parse bpoint with bpoint .;
   if (epoint-bpoint>MAX_PASTE_BYTES) {
      return(1);
   }
   return(0);
}

static boolean SupportCharSelection(typeless markid)
{
   int orig_buf_id=p_buf_id;
   int start_col=0, end_col=0, buf_id=0;
   _get_selinfo(start_col,end_col,buf_id,markid);
   p_buf_id=buf_id;
   typeless orig_pos;
   save_pos(orig_pos);
   _end_select(markid);
   typeless begin_pos;
   save_pos(begin_pos);
   typeless beginendcmp=_begin_select_compare(markid)+_end_select_compare(markid);
   end_col+=(_select_type(markid,'i'))?0:-1;
   boolean support=0;
   // IF start and end selection are on the same line
   if (beginendcmp==0) {
      // Require the EOL character to be selected
      int len=_text_colc(0,'L');
      if (end_col>len) {
         support=1;
      }
   } else {
      // Require that only leading blanks be selected on last line
      if (_expand_tabsc(1,end_col,'s')==' ') {
         support=1;
      }
   }
   restore_pos(orig_pos);
   p_buf_id=orig_buf_id;
   return(support);
}
static boolean SupportCharSelection2(int temp_view_id)
{
   int orig_view_id=0;
   get_window_id(orig_view_id);
   int Noflines=clipboard_iNoflines(temp_view_id);
   activate_window(temp_view_id);
   if (Noflines<=1) {
      activate_window(orig_view_id);
      return(0);
   }
   int orig_pos;
   save_pos(orig_pos);
   down(Noflines);
   boolean support=0;
   // Require that last line be all blanks
   if (_line_length()<20000 && _expand_tabsc(1,-1,'s')=='') {
      support=1;
   }
   restore_pos(orig_pos);
   activate_window(orig_view_id);
   return(support);
}
static boolean pasting_at_blanks()
{
   get_line(auto line);
   if (line=="") {
      return(1);
   }
   save_pos(auto p);
   int orig_col=p_col;
   _begin_line();//_refresh_scroll();
   first_non_blank();
   boolean all_blanks=(orig_col<=p_col);
   restore_pos(p);
   return(all_blanks);
}

int e_smartpaste(boolean char_cbtype,int first_col,int Noflines,boolean allow_col_1=false)
{
   return(c_smartpaste(char_cbtype,first_col,Noflines,allow_col_1));
}
int awk_smartpaste(boolean char_cbtype,int first_col,int Noflines,boolean allow_col_1=false)
{
   return(c_smartpaste(char_cbtype,first_col,Noflines,allow_col_1));
}
int perl_smartpaste(boolean char_cbtype,int first_col,int Noflines,boolean allow_col_1=false)
{
   return(c_smartpaste(char_cbtype,first_col,Noflines,allow_col_1));
}
int ruby_smartpaste(boolean char_cbtype,int first_col,int Noflines,boolean allow_col_1=false)
{
   typeless comment_col='';
   //If pasted stuff starts with comment and indent is different than code,
   // do nothing.
   // Find first non-blank line
   save_pos(auto p4);
   _str first_line="";
   int i=0, j=0;
   for (j=1;j<=Noflines;++j) {
      get_line(first_line);
      i=verify(first_line,' '\t);
      if ( i ) {
         p_col=text_col(first_line,i,'I');
      }
      if (i) {
         break;
      }
      if(down()) {
         break;
      }
   }



   comment_col=p_col;
   if (j>1) {
      restore_pos(p4);
   }

   // Look for first piece of code not in a comment
   typeless status=_clex_skip_blanks('m');
   /*
      The first part of the if expression was commented out because it messed
      up smarttab for the case below:
      foo() {
         if(i<j) {
            while(i<j) {
      <Cursor in column 1>
            }
         }
      }

   */

   // IF //(no code found /*AND pasting comment */AND comment does not start in column 1) OR
   //   (code found AND pasting comment AND code col different than comment indent)
   //  OR  first non-blank code of pasted stuff is preprocessing
   //  OR first non-blank pasted line starts with non-blank AND
   //     (not pasting character selection OR copied text from column 1)
   if ( // (status /*&& comment_col!='' */&& comment_col<=1)
        (!status && comment_col!='' && p_col!=comment_col))
   {
      return(0);
   }

   int col=0;
   typeless enter_col=0;
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE | AFF_INDENT_CASE);
   indent_case := p_indent_case_from_switch;
   int syntax_indent=p_SyntaxIndent;

   typeless junk=0;
   if (!status && (cur_word(junk)=='case' || cur_word(junk)=='default')) {
      // IF pasting stuff contains code AND first word of code is case or default
      /* Indent case based on indent of switch. */
      col=_c_last_switch_col();
      if ( col ) {
         // indent_case=='' means we are editting a Slick-C file.
         if ((indent_case && indent_case!='') || (p_begin_end_style == BES_BEGIN_END_STYLE_3)) {
            enter_col=col+syntax_indent;
         } else {
            enter_col=col;
         }
         _begin_select();up();
      } else {
         status=1;
      }
#if 0
      if (i)
         {
         }

      else
         else


      else
         {

         }

      {

      } else ++i;
      do
         {

         }
      while (  );


#endif
   } else if (!status && get_text()=='}') {
      // IF pasting stuff contains code AND first char of code }
      ++p_col;
      enter_col=c_endbrace_col();
      if (!enter_col) {
         enter_col='';
      }
      _begin_select();up();
   } else {
      /*  Need to know if we are pasting an open brace. */
      boolean pasting_open_block=false;
      // The new c_enter_col always wants to know if we are
      // pasting and open brace.
      if (!status && get_text()=='{' /*&& (be_style & STYLE1_FLAG)*/) {
         pasting_open_block=true;
      }
      _begin_select();up();
      _end_line();
      _skip_pp=1;
      enter_col=c_enter_col(pasting_open_block);
      _skip_pp='';
      status=0;
   }
   //IF no code found/want to give up OR ... OR want to give up
   if (status || enter_col=='' || (enter_col==1 && !allow_col_1)) {
      return(0);
   }
   return(enter_col);
}
// Need pl_smartpaste so that init_smartpaste_option() works correctly
int pl_smartpaste(boolean char_cbtype,int first_col,int Noflines,boolean allow_col_1=false)
{
   return(perl_smartpaste(char_cbtype,first_col,Noflines,allow_col_1));
}
int tcl_smartpaste(boolean char_cbtype,int first_col,int Noflines,boolean allow_col_1=false)
{
   return(c_smartpaste(char_cbtype,first_col,Noflines,allow_col_1));
}
int phpscript_smartpaste(boolean char_cbtype,int first_col,int Noflines,boolean allow_col_1=false)
{
   return(c_smartpaste(char_cbtype,first_col,Noflines,allow_col_1));
}
int cfscript_smartpaste(boolean char_cbtype,int first_col,int Noflines,boolean allow_col_1=false)
{
   return(c_smartpaste(char_cbtype,first_col,Noflines,allow_col_1));
}
int js_smartpaste(boolean char_cbtype,int first_col,int Noflines,boolean allow_col_1=false)
{
   return(c_smartpaste(char_cbtype,first_col,Noflines,allow_col_1));
}
int java_smartpaste(boolean char_cbtype,int first_col,int Noflines,boolean allow_col_1=false)
{
   return(c_smartpaste(char_cbtype,first_col,Noflines,allow_col_1));
}
int cs_smartpaste(boolean char_cbtype,int first_col,int Noflines,boolean allow_col_1=false)
{
   return(c_smartpaste(char_cbtype,first_col,Noflines,allow_col_1));
}
int idl_smartpaste(boolean char_cbtype,int first_col,int Noflines,boolean allow_col_1=false)
{
   return(c_smartpaste(char_cbtype,first_col,Noflines,allow_col_1));
}
int tagdoc_smartpaste(boolean char_cbtype,int first_col,int Noflines,boolean allow_col_1=false)
{
   return(c_smartpaste(char_cbtype,first_col,Noflines,allow_col_1));
}
int c_smartpaste(boolean char_cbtype,int first_col,int Noflines,boolean allow_col_1=false)
{
   typeless comment_col='';
   //If pasted stuff starts with comment and indent is different than code,
   // do nothing.
   // Find first non-blank line
   _str first_line="";
   save_pos(auto p4);
   int i=0, j=0;
   for (j=1;j<=Noflines;++j) {
      get_line(first_line);
      i=verify(first_line,' '\t);
      if ( i ) {
         p_col=text_col(first_line,i,'I');
      }
      if (i) {
         break;
      }
      if(down()) {
         break;
      }
   }
   comment_col=p_col;
   if (j>1) {
      restore_pos(p4);
   }

   // Look for first piece of code not in a comment
   typeless status=_clex_skip_blanks('m');
   /*
      The first part of the if expression was commented out because it messed
      up smarttab for the case below:
      foo() {
         if(i<j) {
            while(i<j) {
      <Cursor in column 1>
            }
         }
      }

   */

   // IF //(no code found /*AND pasting comment */AND comment does not start in column 1) OR
   //   (code found AND pasting comment AND code col different than comment indent)
   //  OR  first non-blank code of pasted stuff is preprocessing
   //  OR first non-blank pasted line starts with non-blank AND
   //     (not pasting character selection OR copied text from column 1)
   if ( // (status /*&& comment_col!='' */&& comment_col<=1)
        (!status && comment_col!='' && p_col!=comment_col)
       || (!status && get_text()=='#')
       || (substr(first_line,1,1)!='' && (!char_cbtype ||first_col<=1))
       ) {
      return(0);
   }
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE | AFF_INDENT_CASE);
   int syntax_indent=p_SyntaxIndent;
   indent_case:=beaut_case_indent(p_LangId);

   typeless enter_col=0;
   int col=0;

   //say("smartpaste cur_word="cur_word(word_start));
   cword := _c_get_wordplus();
   
   if (!status && _c_is_member_access_kw(cword)) {
      _str kw = '';

      col = _c_last_struct_col(kw);
      ma_indent := beaut_member_access_indent(p_LangId);
      enter_col = col + ma_indent;
      if (beaut_style_for_keyword(p_LangId, kw, auto found) == BES_BEGIN_END_STYLE_3) {
         enter_col += p_SyntaxIndent;
      }
      _begin_select(); up();
   } else if (!status && (cword=='case' || cword=='default:')) {
      // IF pasting stuff contains code AND first word of code is case or default
      /* Indent case based on indent of switch. */
      col=_c_last_switch_col();
      if ( col ) {
         // indent_case=='' means we are editting a Slick-C file.
         if (indent_case && indent_case!='') {
            col = col + indent_case;
         }
         if (beaut_style_for_keyword(p_LangId, 'switch', auto jfound) == BES_BEGIN_END_STYLE_3) {
            col = col + p_SyntaxIndent;
         }
         enter_col = col;
         _begin_select();up();
      } else {
         status=1;
      }
#if 0
      if (i)
         {
         }

      else
         else


      else
         {

         }

      {

      } else ++i;
      do
         {

         }
      while (  );


#endif
   } else if (!status && get_text()=='}') {
      // IF pasting stuff contains code AND first char of code }
      ++p_col;
      enter_col=c_endbrace_col();
      if (!enter_col) {
         enter_col='';
      }
      _begin_select();up();
   } else {
      /*  Need to know if we are pasting an open brace. */
      boolean pasting_open_block=false;
      // The new c_enter_col always wants to know if we are
      // pasting and open brace.
      if (!status && get_text()=='{' /*&& (be_style & STYLE1_FLAG)*/) {
         pasting_open_block=true;
      }
      _begin_select();up();
      _end_line();
      _skip_pp=1;
      enter_col=c_enter_col(pasting_open_block);
      _skip_pp='';
      status=0;
   }
   //IF no code found/want to give up OR ... OR want to give up
   if (status || enter_col=='' || (enter_col==1 && !allow_col_1)) {
      return(0);
   }
   return(enter_col);
}

static c_enter_col(typeless pasting_open_block)
{
   typeless enter_col=0;
   if ( command_state() || p_window_state:=='I' ||
      p_SyntaxIndent<0 || p_indent_style!=INDENT_SMART ||
      c_enter_col2(enter_col,pasting_open_block) ) {
      return('');
   }
   return(enter_col);
}


static _str c_enter_col2(var enter_col,typeless pasting_open_block)
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_INDENT_CASE | AFF_BEGIN_END_STYLE);
   syntax_indent := p_SyntaxIndent;
   indent_case := (int)p_indent_case_from_switch;
   be_style := p_begin_end_style;
   expand := LanguageSettings.getSyntaxExpansion(p_LangId);

   enter_col='';
   typeless status=0;
   typeless Noflines=0;
   typeless cur_line=0;
   _str first_word='';
   _str last_word="";
   _str rest="";
   typeless non_blank_col=0;
   typeless semi=0;
   typeless prev_semi=0;
   status=c_get_info(Noflines,cur_line,first_word,last_word,rest,
              non_blank_col,semi,prev_semi,1);
   if (status) return(1);
   //say("Noflines="Noflines", cur_line="cur_line", first_word="first_word", last_word="last_word", rest="rest);
   _str line="";
   parse cur_line with line '/*' ;  /* Strip comment on current line. */
   parse line with line '//'     ;  /* Strip comment on current line. */

   //if (last_char(strip(line))==',') return(0); //Give up if the previous line ended in comma
   if ( ! Noflines ) {
      if ( expand && first_word=='main' && rest=='' ) {
         return(1);
      } else if ( (first_word=='case' || first_word=='default')) {
         enter_col=non_blank_col+syntax_indent;
         return(0);
      } else if ( first_word=='switch' && last_word=='{' ) {
         if ((indent_case && indent_case!='') || (be_style == BES_BEGIN_END_STYLE_3)) {
            enter_col=non_blank_col+syntax_indent;
            return(0);
         }
         enter_col=non_blank_col;
         return(0);
     } else if (expand && first_word=='extern' && last_word=='{' && pos('"C"',cur_line,1,'i')) {
        return(0);
     } else {
        status=1;
     }
   } else {
     status=1;
   }
   if ( status ) {  /* try some more? Indenting only. */
      status=0;
      _end_line();
      if (p_col<non_blank_col+1) {
         p_col=non_blank_col+1;
      }
      enter_col=c_indent_col(non_blank_col, pasting_open_block);
   }
   return(status);

}

/* Check if the first character of next line is in multi line comment. */
boolean _smart_in_comment(boolean checkNextLine=true)
{
   int cfg, flags;
   if (checkNextLine) {
      save_pos(auto p);
      typeless status=down();
      if (status) {
         return(0);
      }
      _begin_line();
      cfg=_clex_find(0,'g');  // Refresh line flags for multi-line comments
      flags=_lineflags();
      restore_pos(p);
   } else {
      cfg=_clex_find(0,'g');  // Refresh line flags for multi-line comments
      flags=_lineflags();
   }
   // Need to cheat for XML, DTD, and HTML since _clex_InComment returns true when inside tag and attributes
   if ((_LanguageInheritsFrom('xml') || _LanguageInheritsFrom('dtd') || _LanguageInheritsFrom('html')) &&
       !(flags & EMBEDDEDLANGUAGEMASK_LF) &&
       _clex_InComment(flags) &&
       cfg!=CFG_COMMENT
       ) {
      //_message_box('xml _smart_in_comment case');
      return(0);
   }
   // If we are in a multi line comment or string from the previous line.
   //    or embedded language
   if (//(flags & COMMENTINFOMASK_LF) ||
       (_clex_InComment(flags) || _clex_InString(flags)) ||
       ((flags & EMBEDDEDLANGUAGEMASK_LF) && p_embedded!=VSEMBEDDED_ONLY)
      ) {
      return(1);
   }
   return(0);
}

int pas_smartpaste(boolean char_cbtype,int first_col,int Noflines)
{
   typeless comment_col='';
   //If pasted stuff starts with comment and indent is different than code,
   // do nothing.
   _str first_line="";
   get_line(first_line);
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

   //messageNwait('got to the beginning of reformatting');
   int col=0;
   typeless enter_col=0;
   typeless junk=0;
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_INDENT_CASE | AFF_BEGIN_END_STYLE);
   int syntax_indent=p_SyntaxIndent;
   indent_case := (int)p_indent_case_from_switch;
   be_style := p_begin_end_style;
   _str myline="";
   get_line(myline);
   _str temp="";
   parse myline with temp '\(\*|\{|//','r';
   //messageNwait("pas_smart_paste2: status="status" myline="temp);
   if (!status && (lastpos('\:([ \t]*begin|)[ \t]*$',temp,length(temp),'ri') && substr(myline,1,1)=="")) {
      /* Indent constant based on indent of case. */
      int temp_col=p_col;
      _begin_line();  //set up so last case col will NOT see the begin on the end of the line
      col=_pas_last_case_col();
      p_col=temp_col;
      if ( col ) {
         // indent_case=='' means we are editting a Slick-C file.
         if ((indent_case && indent_case!='')) {
            enter_col=col+syntax_indent;
         } else {
            enter_col=col;
         }
         _begin_select();get_line(first_line);up();
      } else {
         status=1;
      }
   //first word of paste selection is an end
   } else if (!status && lowcase(cur_word(junk))=='end') {
      //messageNwait('it was an end');
      ++p_col;
      enter_col=pas_endbrace_col(be_style);
      if (!enter_col) {
         enter_col='';
      }
      _begin_select();get_line(first_line);up();
   } else if (!status && (lowcase(cur_word(junk))=='var' || lowcase(cur_word(junk))=='type'  ||
      lowcase(cur_word(junk))=='const')) {
      enter_col=_pas_last_prog_col()+syntax_indent;
      _begin_select();get_line(first_line);up();
   } else {
      //messageNwait('inside other');
      typeless pasting_open_block='';
      _begin_select();get_line(first_line);up();
      _end_line();
      _skip_pp=1;
      enter_col=pas_enter_col(pasting_open_block);
      _skip_pp='';
      status=0;
   }
   //IF no code found/want to give up OR ... OR want to give up OR
   //   first_line of pasted stuff is preprocessing
   if (status || enter_col==1 || enter_col=='' || pos('^[ \t]*\#',first_line,1,'r') ||
      (substr(first_line,1,1)!='' && (!char_cbtype ||first_col<=1))) {
      return(0);
   }
   return(enter_col);
}

static pas_enter_col(typeless pasting_open_block)
{
   typeless enter_col=0;
   if ( command_state() || p_window_state:=='I' ||
      p_SyntaxIndent<0 || p_indent_style!=INDENT_SMART ||
      pas_enter_col2(enter_col,pasting_open_block) ) {
      return('');
   }
   return(enter_col);
}


static typeless pas_enter_col2(var enter_col, typeless pasting_open_block)
{
   //messageNwait('entercol2');
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_INDENT_CASE);
   syntax_indent := p_SyntaxIndent;
   indent_case := p_indent_case_from_switch;
   expand := LanguageSettings.getSyntaxExpansion(p_LangId);

   enter_col='';
   typeless status=0;
   int Noflines=0;
   int color=0;
   typeless cur_line=0;
   _str first_word="";
   _str last_word="";
   _str rest="";
   typeless non_blank_col=0;
   typeless semi=0;
   typeless prev_semi=0;
   status=pascal_get_info(Noflines,cur_line,first_word,last_word,rest,
              non_blank_col,semi,prev_semi,true);

   if (status) return(1);
   typeless junk=0;
   _str lfirst_word=lowcase(first_word);  //account for mixed case keywords
   _str llast_word=lowcase(last_word);
   _str line="";
   _str keyword="";
   parse cur_line with line '(*' ;  /* Strip comment on current line. */
   parse line with line '{'      ;  /* Strip comment on current line. */
   //For now give up if the previous line ended in comma
   if (last_char(strip(line))==',') {
      return(0);
   }
   if ( expand && ! Noflines ) {
      if ( lfirst_word=='program' && rest=='' ) {
         return(1);
      } else if (lastpos('[~:]*\:[ \t]*(begin)' ,cur_line,1,'ri')) {
         //messageNwait('got into begin line');
         _str myline=strip(cur_line);
         _str stuff="";
         parse myline with stuff 'begin','i' +0 junk;
         enter_col=non_blank_col+syntax_indent+length(stuff);
         return(0);
      } else if ( lfirst_word=='case' && llast_word=='of' ) {
         /* This code probably won't matter because */
         if ((indent_case && indent_case!='')) {
            enter_col=non_blank_col+syntax_indent;
            return(0);
         }
         enter_col=non_blank_col;
         return(0);
      } else if (lfirst_word=='var' || lfirst_word=='type' || lfirst_word=='const') { //might want to add label
         enter_col=non_blank_col+syntax_indent;

      } else if (llast_word=='end' || lfirst_word=='end') {
         typeless p;
         _save_pos2(p);
         int level=0;
         //messageNwait('got to end place');

         //loop around looking for keywords that match the end.  Get the col of the match
         status=search('begin|end|case|for|if|while','@rhi-');
         int go=0;
         if (status) {
            go=0;
         } else go=1;

         while (go) {
            keyword='';
            color=_clex_find(0,'g');
            if (color==CFG_KEYWORD) {
               keyword=get_match_text();
               switch (lowcase(keyword)) {
               case 'end':
                  --level;
                  break;
               case 'begin':
                  ++level;
                  break;
               case 'case':
                  ++level;
                  break;
               default:
                  break;
               }
            }
            //messageNwait('keyword: 'keyword' level:'level);
            if (level==0&&(status||keyword=='for'||keyword=='if'||keyword=='while'||keyword=='case')) {
               go=0;  //break out of loop
            } else {
                 status=repeat_search();
                 if (status) {
                    go=0;
                 } else go=1;
            }

         }
         //messageNwait('done...keyword:'keyword);
         enter_col=text_col('',p_col,'P');
         //messageNwait('col:'enter_col);
         _restore_pos2(p);


     } else {
        status=1;
     }
   } else {
     status=1;
   }
   if ( status ) {  /* try some more? Indenting only. */
      status=0;
      _end_line();
      if (p_col<non_blank_col+1) {
         p_col=non_blank_col+1;
      }
      enter_col=pas_indent_col(non_blank_col, pasting_open_block);
   }
   return(status);

}

static int ext_smartpaste(int smartpaste_index,typeless markid,_str copymove_option,
                          int temp_view_id,typeless reserved,
                          int first_col,_str ext,boolean isClipboard)
{
   if (markid!='') {
      typeless cur_markid=_duplicate_selection('');
      _show_selection(markid);
      int status=ext_smartpaste2(smartpaste_index,copymove_option,temp_view_id,reserved,first_col,ext,isClipboard);
      _show_selection(cur_markid);
      return(status);
   }
   return(ext_smartpaste2(smartpaste_index,copymove_option,temp_view_id,reserved,first_col,ext,isClipboard));
}

void _do_default_smartpaste_reindent(int first_col, int enter_col,int Noflines,boolean char_cbtype,int dest_col)
{
   _str line="";
   save_pos(auto p4);
   int i;
   // find the first non blank line
   for (i=1;i<=Noflines;++i) {
      get_line(line);
      if (line!='') {
         break;
      }
      down();
   }

   if (i<=Noflines) {
      // is this a character selection?
      if (char_cbtype) {
         // If we are pasting a character selection with a tab at the 
         // beginning, we do not want to create the following situation:
         // 
         //            ^<spc><spc>\t
         // 
         // Convert the leading tabs of the pasted text to spaces so that 
         // indentation is done correctly with space, it will be converted to
         // tabs later
         get_line(line);
         // determine the physical position of where our paste started
         int physical_col = _text_colc(dest_col, 'P');

         // get the rest of the line
         _str pasted_line = substr(line, physical_col, -1);

         // does what we pasted start with spaces or tabs?
         if (pos("^[ \t]#", pasted_line, 1, 'r')) {
            // how many spaces was it?
            int lead_len = pos('');

            // this is what was sitting here at the beginning of the line before we pasted anything
            _str orig_line = substr(line, 1, physical_col - 1);
            // now let's put the line together, with expanded leading tabs in the pasted part
            // first, the original part, plus the leading spaces of the pasted part - we have to have 
            // the beginning part in case the tabs are funky
            line = orig_line :+ substr(pasted_line, 1, lead_len);
            // now the original part plus the expanded tabs
            line = orig_line :+ expand_tabs(line, physical_col);
            // finally, add the rest of the pasted line
            line :+= substr(pasted_line, lead_len + 1);

            replace_line(line);
         }
      }

      first_non_blank();
      int adjust_col=enter_col - p_col;
      boolean need_additional_adjust= (i==1);
      restore_pos(p4);
      if (adjust_col || char_cbtype) {
         int second_adjust_col=adjust_col;
         if (char_cbtype && need_additional_adjust) {
            //A first_col less than 1 makes no sense here, so use 1 (dobrien 06/27/07)
            //Fixes Smart paste problem in Linux
            second_adjust_col= adjust_col + dest_col - (first_col < 1 ? 1 : first_col);
         }
         for (i=1;i<=Noflines;++i) {
            get_line(line);
            line=reindent_line(line, (i>1) ? (second_adjust_col) : (adjust_col));
            if (line=='') line='';
            replace_line(line);
            down();
         }
      } else {
         down(Noflines-i+1);
      }
   }

   if (char_cbtype && dest_col>1) {
      get_line(line);
      line=reindent_line(line,dest_col-1);
      if (line=='') line='';
      replace_line(line);
      /*first_non_blank();
      NofLeadingBlankCols=p_col+paste_col;*/
   }
}

static int ext_smartpaste2(int smartpaste_index,_str copymove_option,int temp_view_id,
                           typeless reserved,int first_col,_str ext,boolean isClipboard)
{
   int dest_col=p_col;
   typeless old_deselect_paste=def_deselect_paste;
   typeless char_cbtype=false;
   typeless status=0;
   int Noflines=0;
   if (copymove_option!='') {
      char_cbtype=_select_type()=='CHAR';
      Noflines=count_lines_in_selection();
      if (upcase(copymove_option)=='M') {
         status=_move_to_cursor();
      } else {
         status=_copy_to_cursor();
      }
      if (status) {
         return(status);
      }
   } else {
      char_cbtype=clipboard_itype(temp_view_id)=='CHAR';
      Noflines=clipboard_iNoflines(temp_view_id);
      def_deselect_paste=0;
      status=paste2(def_persistent_select,temp_view_id,reserved,isClipboard);
      if (status) {
         if (old_deselect_paste!=def_deselect_paste) {
            deselect();def_deselect_paste=old_deselect_paste;
         }
         return(status);
      }
   }

   // character selection?
   if (char_cbtype) --Noflines;

   // Save position by line number.
   typeless p;
   _save_pos2(p);
   _begin_select();_begin_line();

   // figure out where we would be if we hit enter right now
   typeless enter_col=call_index(char_cbtype,first_col,Noflines,smartpaste_index);

   //IF no code found/want to give up OR ... OR want to give up OR
   //   first_line of pasted stuff is preprocessing
   if (!enter_col) {
      if (old_deselect_paste!=def_deselect_paste) {
         deselect();def_deselect_paste=old_deselect_paste;
      }
      _restore_pos2(p);
      return(0);
   }
   int Nofcols=0;
   if (char_cbtype) {
      // Remove leading blanks inserted into last line
      save_pos(auto p2);
      _end_select();
      Nofcols=p_col+(_select_type('','i')?0:-1);
      if (Nofcols) {
         _begin_line();_delete_text(Nofcols,'C');
      }
      restore_pos(p2);
   }
   down();

   index := _FindLanguageCallbackIndex('%s_smartpaste_reindent',ext);
   if (index) {
      call_index(first_col,enter_col,Noflines,char_cbtype,dest_col,index);
   } else {
      _do_default_smartpaste_reindent(first_col,enter_col,Noflines,char_cbtype,dest_col);
   }
   if (old_deselect_paste!=def_deselect_paste) {
      deselect();
      def_deselect_paste=old_deselect_paste;
   }
   _restore_pos2(p);

   // let the user know that we've done something neat
   notifyUserOfFeatureUse(NF_SMART_PASTE, p_buf_name, p_line);

   return(status);

}
