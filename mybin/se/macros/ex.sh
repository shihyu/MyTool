////////////////////////////////////////////////////////////////////////////////////
// $Revision: 49127 $
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
#ifndef EX_SH
#define EX_SH

/*
$VerboseHistory: ex.sh$
*/
/* These are ex commands */
#define EX_CMDS " ! = < > & ABBREVIATE COPY CD DELETE EDIT FILE GLOBAL JOIN K LIST":+\
                " MOVE NEXT NUMBER PRINT PUT QUIT QALL READ REWIND SUBSTITUTE":+\
                " SET SG SHELL SPLIT T TAG UNDO UNABBREVIATE V VERSION VSPLIT WRITE WQ WQALL WALL X YANK Z BUFDO NOH":+\
                " NOHLSEARCH "

#define EX_ADDR_CMDS " ! = < > COPY DELETE GLOBAL JOIN K LIST MOVE NUMBER PRINT PUT":+\
                     " READ SG SUBSTITUTE T V WRITE WQ WQALL WALL YANK Z "

#define EX_VARIANT_CMDS " EDIT GLOBAL MAP NEXT QUIT QALL REWIND WRITE WQ "

#define EX_NOT_SUPPORTED_CMDS " ARGS MAP PRESERVE RECOVER UNMAP "

#define EX_READONLY_CMDS " ! = ABBREVIATE CD EDIT FILE GLOBAL K LIST NEXT NUMBER":+\
                         " PRINT QUIT QALL SET SHELL TAG UNDO UNABBREVIATE V VERSION":+\
                         " YANK Z "


// Constant for matching ex commands
#define EX_ARG "ex:"TERMINATE_MATCH

int _ex_match_pos;   // Position where the next command match should start


// These are ex SET options
#define SET_NAMES " AUTOINDENT AUTOPRINT ERRORBELLS IGNORECASE":+\
                  " LIST LISTCHARS NUMBER PARAGRAPHS PROMPT REPORT SCROLL SECTIONS SHELL":+\
                  " SHIFTWIDTH SHOWMATCH SHOWMODE WRAPSCAN WRITEANY INCSEARCH HLSEARCH "

#define SET_NOT_SUPPORTED_NAMES " AUTOWRITE BEAUTIFY DIRECTORY EDCOMPATIBLE":+\
                                " HARDTABS LISP MAGIC MESG OPTIMIZE REDRAW":+\
                                " REMAP SLOWOPEN TABSTOP TAGLENGTH TAGS TERM TERSE TIMEOUT":+\
                                " WARN WINDOW W300 W1200 W2400 W4800 W7200 W9600":+\
                                " WRAPMARGIN "

#define SET_TOGGLE_NAMES " AUTOINDENT AUTOPRINT ERRORBELLS IGNORECASE LIST NUMBER PROMPT SHOWMATCH SHOWMODE WRAPSCAN WRITEANY":+\
                         " INCSEARCH HLSEARCH "

// These are abbreviations for the SET options
#define SET_ABBR_NAMES " AI=AUTOINDENT AP=AUTOPRINT AW=AUTOWRITE BF=BEAUTIFY":+\
                       " DIR=DIRECTORY EB=ERRORBELLS HT=HARDTABS IC=IGNORECASE LCS=LISTCHARS":+\
                       " N=NUMBER OPT=OPTIMIZE PARA=PARAGRAPHS SH=SHELL SW=SHIFTWIDTH":+\
                       " SM=SHOWMATCH TS=TABSTOP TL=TAGLENGTH TO=TIMEOUT":+\
                       " WA=WRITEANY WM=WRAPMARGIN WS=WRAPSCAN IS=INCSEARCH HLS=HLSEARCH "


// Constant for matching SET options
#define SET_ARG  "set:"TERMINATE_MATCH
#define SET2_ARG "set2:"(TERMINATE_MATCH|NO_SORT_MATCH)

_str _set_match_pos;   // Position where the next set match should start


// Defaults values for SET options
#define AUTOINDENT_DEFAULT   ""         // Not used
#define AUTOPRINT_DEFAULT    "0"
#define INCSEARCH_DEFAULT    "0"
#define HLSEARCH_DEFAULT     "1"
#define AUTOWRITE_DEFAULT    ""         // Not used
#define BEAUTIFY_DEFAULT     ""         // Not used
#define DIRECTORY_DEFAULT    ""         // Not used
#define EDCOMPATIBLE_DEFAULT ""         // Not used - yet
#define ERRORBELLS_DEFAULT   0
#define HARDTABS_DEFAULT     ""         // Not used
#define IGNORECASE_DEFAULT   0
#define LISP_DEFAULT         ""         // Not used
#define LIST_DEFAULT         0
#define LISTCHARS_DEFAULT    ""
#define MAGIC_DEFAULT        ""         // Not used
#define MESG_DEFAULT         ""         // Not used
#define NUMBER_DEFAULT       0
#define OPTIMIZE_DEFAULT     ""         // Not used
#define PARAGRAPHS_DEFAULT   "\\t\\12"
#define PROMPT_DEFAULT       1
#define REDRAW_DEFAULT       ""         // Not used
#define REMAP_DEFAULT        ""         // Not used
#define REPORT_DEFAULT       5
#define SCROLL_DEFAULT       ""         // This is set by a DEFINIT
#define SECTIONS_DEFAULT     '\12\{'
#define SHELL_DEFAULT        ""         // Determined by another mechanism
#define SHIFTWIDTH_DEFAULT   8
#define SHOWMATCH_DEFAULT    0
#define SHOWMODE_DEFAULT     1 
#define SLOWOPEN_DEFAULT     ""         // Not used
#define TABSTOP_DEFAULT      ""         // Not used
#define TAGLENGTH_DEFAULT    ""         // Not used
#define TAGS_DEFAULT         "tags.slk"
#define TERM_DEFAULT         ""         // Not used
#define TERSE_DEFAULT        ""         // Not used
#define TIMEOUT_DEFAULT      ""         // Not used
#define WARN_DEFAULT         ""         // Not used
#define W300_DEFAULT         ""         // Not used
#define W1200_DEFAULT        ""         // Not used
#define W2400_DEFAULT        ""         // Not used
#define W4800_DEFAULT        ""         // Not used
#define W7200_DEFAULT        ""         // Not used
#define W9600_DEFAULT        ""         // Not used
#define WRAPSCAN_DEFAULT     0
#define WRAPMARGIN_DEFAULT   ""         // Not used
#define WRITEANY_DEFAULT     0


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

#define USE_OLD_LINE_FLAGS 0

#define VI_CB0 '0'

#define VI_DEFAULT_CB_NAME "1"   /* When no clipboard name or "0" is given, then "1" is used */


#define INTRALINE_CMDS ' vi-cursor-right vi-cursor-left vi-begin-next-line':+\
                       ' vi-next-line vi-prev-line vi-begin-prev-line vi-begin-line':+\
                       ' vi-begin-text vi-end-line vi-goto-line vi-goto-col vi-next-word':+\
                       ' vi-next-word2 vi-prev-word vi-prev-word2 vi-end-word':+\
                       ' vi-end-word2 vi-prev-sentence vi-next-sentence vi-visual-select-up':+\
                       ' vi-maybe-text-motion vi-goto-percent vi-open-bracket-cmd vi-closed-bracket-cmd '

#define INTRALINE_CMDS2 ' vi-prev-paragraph vi-next-paragraph vi-prev-section':+\
                        ' vi-next-section vi-find-matching-paren vi-top-of-window':+\
                        ' vi-middle-of-window vi-bottom-of-window vi-prev-line-context':+\
                        ' vi-prev-context vi-to-mark-col vi-to-mark-line vi-visual-select-left' :+\
                        ' vi-visual-select-right vi-visual-select-down vi-visual-begin-select vi-visual-next-word':+\
                        ' vi-visual-prev-word vi-visual-prev-word2 vi-visual-next-word2 vi-visual-end-word':+\
                        ' vi-visual-end-word2 '

#define INTRALINE_CMDS3 ' vi-visual-next-paragraph vi-visual-prev-paragraph vi-visual-next-sentence':+\
                        ' vi-visual-prev-sentence vi-visual-a-cmd vi-visual-i-cmd vi-visual-maybe-text-motion '

/* The line command constants are used primarily by VI-SHIFT-TEXT-LEFT and
 * VI-SHIFT-TEXT-RIGHT to determine which commands are valid to use in
 * delimiting the lines to shift.
 */
#define LINE_CMDS ' vi-begin-next-line vi-next-line vi-prev-line vi-begin-prev-line':+\
                  ' vi-goto-line vi-next-word vi-next-word2 vi-prev-word vi-prev-word2':+\
                  ' vi-end-word vi-end-word2 vi-prev-sentence vi-next-sentence'

#define LINE_CMDS2 ' vi-prev-paragraph vi-next-paragraph vi-prev-section vi-next-section':+\
                   ' vi-find-matching-paren vi-top-of-window vi-middle-of-window':+\
                   ' vi-bottom-of-window vi-to-mark-line '

#define MODIFICATION_CMDS ' vi-change-line-or-to-cursor vi-change-to-end vi-join-line':+\
                          ' vi-replace-char vi-replace-line vi-substitute-char':+\
                          ' vi-substitute-line vi-shift-text-left vi-shift-text-right':+\
                          ' vi-toggle-case-char vi-filter vi-visual-replace vi-visual-change':+\
                          ' vi-visual-upcase vi-visual-downcase vi-visual-toggle-case vi-visual-join':+\
                          ' vi-visual-maybe-join-nospaces vi-visual-shift-left vi-visual-shift-right vi-format'

#define DELETE_CMDS ' vi-forward-delete-char vi-backward-delete-char vi-visual-delete '

#define CB_CMDS ' vi-put-after-cursor vi-put-before-cursor vi-yank-to-cursor vi-yank-line vi-visual-yank':+\
                ' vi-visual-put '

#define SEARCH_CMDS ' vi-char-search-forward vi-char-search-backward vi-char-search-forward2':+\
                    ' vi-char-search-backward2 vi-repeat-char-search vi-reverse-repeat-char-search':+\
                    ' vi-to-mark-line vi-to-mark-col ex-search-mode ex-reverse-search-mode vi-visual-search':+\
                    ' vi-visual-reverse-search vi_quick_search vi_quick_reverse_search '

#define DOUBLE_CMDS ' vi-delete vi-change-line-or-to-cursor vi-shift-text-left vi-shift-text-right':+\
                    ' vi-yank-to-cursor '

#define SCROLL_CMDS ' vi-scroll-window-down vi-scroll-window-up '

/* These are used for repeating the last insert/delete/modification in
 * such commands as:  Ctrl+@, '.', and giving a repeat count to one of
 * the text insertion commands (a, A, i, I, o, O).
 */
#define PLAYBACK_CMDS ' vi-insert-mode vi-begin-line-insert-mode vi-append-mode vi-end-line-append-mode':+\
                      ' vi-newline-mode vi-above-newline-mode vi-delete vi-change-line-or-to-cursor':+\
                      ' vi-change-to-end vi-delete-to-end vi-replace-char vi-replace-line vi-substitute-char':+\
                      ' vi-substitute-line vi-join-line vi-shift-text-left vi-shift-text-right':+\
                      ' vi-forward-delete-char vi-backward-delete-char vi-yank-to-cursor vi-yank-line':+\
                      ' vi-toggle-case-char vi-put-after-cursor vi-put-before-cursor vi-filter ':+\
                      ' vi-first-col-insert-mode '

#define INSERT_CMDS ' vi-insert-mode vi-begin-line-insert-mode vi-append-mode vi-end-line-append-mode':+\
                    ' vi-newline-mode vi-above-newline-mode vi-change-line-or-to-cursor vi-change-to-end':+\
                    ' vi-replace-char vi-replace-line vi-substitute-char vi-substitute-line '

// These commands must be posted in VI_REPEAT_INFO
#define POSTED_INSERT_CMDS ' vi-insert-mode vi-begin-line-insert-mode vi-append-mode':+\
                           ' vi-end-line-append-mode vi-newline-mode vi-above-newline-mode':+\
                           ' vi-replace-line vi-first-col-insert-mode'

#define EX_VISUAL_RANGE "'<,'>"

#endif
