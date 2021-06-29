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
#pragma option(metadata,"ex.e")

/*
$VerboseHistory: ex.sh$
*/
/* These are ex commands */

_str _set_match_pos;   // Position where the next set match should start


// Defaults values for SET options
const VI_DEFAULT_AUTOPRINT=    "0";
const VI_DEFAULT_INCSEARCH=    "0";
const VI_DEFAULT_HLSEARCH=     "1";
const VI_DEFAULT_ERRORBELLS=   0;
const VI_DEFAULT_LIST=         0;
const VI_DEFAULT_PARAGRAPHS=   "\\t\\12";
const VI_DEFAULT_PROMPT=       1;
const VI_DEFAULT_REPORT=       5;
const VI_DEFAULT_SECTIONS=     '\12\{';
const VI_DEFAULT_SHIFTWIDTH=   8;
const VI_DEFAULT_SHOWMATCH=    0;
const VI_DEFAULT_SHOWMODE=     1 ;
const VI_DEFAULT_WRAPSCAN=     0;
const VI_DEFAULT_WRITEANY=     0;


typeless
   def_vi_or_ex_autoprint
   ,def_vi_or_ex_edcompatible
   ,def_vi_or_ex_errorbells
   ,def_vi_or_ex_list
   ,def_vi_or_ex_number
   ,def_vi_or_ex_paragraphs
   ,def_vi_or_ex_prompt
   ,def_vi_or_ex_report
   ,def_vi_or_ex_scroll
   ,def_vi_or_ex_sections
   ,def_vi_or_ex_shell
   ,def_vi_or_ex_shiftwidth
   ,def_vi_or_ex_showmatch
   ,def_vi_or_ex_showmode
   ,def_vi_or_ex_tabstop
   ,def_vi_or_ex_tags
   ,def_vi_or_ex_writeany
   ,def_vi_or_ex_autoindent
   ,def_vi_or_ex_ignorecase
   ,def_vi_or_ex_listchars
   ,def_vi_or_ex_incsearch
   ,def_vi_or_ex_hlsearch;

_str _ex_print_view_id;

_str def_preplace;


// These commands must be posted in VI_REPEAT_INFO
const VI_CMDS_POSTED_INSERT= ' vi-insert-mode vi-begin-line-insert-mode vi-append-mode':+
                           ' vi-end-line-append-mode vi-newline-mode vi-above-newline-mode':+
                           ' vi-replace-line vi-first-col-insert-mode';

const EX_VISUAL_RANGE= "'<,'>";

