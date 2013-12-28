////////////////////////////////////////////////////////////////////////////////////
// $Revision: 45613 $
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
#import "clipbd.e"
#import "eclipse.e"
#import "listproc.e"
#import "main.e"
#import "reflow.e"
#import "search.e"
#import "seldisp.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tbclipbd.e"
#import "util.e"
#import "vc.e"
#require "se/lang/api/LanguageSettings.e"
#endregion

using se.lang.api.LanguageSettings;

#define ISPF_FILL_CHAR ' '
#define ISPF_TAB_POSN_CHAR '*'
#define ISPF_LBND_POSN_CHAR '<'
#define ISPF_RBND_POSN_CHAR '>'
#define ISPF_LABEL_PREFIX   '.'
#define ISPF_RULER_LINE   "----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8----|----9----|----0----|----1----|----2----|----3----"
#define ISPF_MAX_LINE      132
#define ISPF_EXCLUDE_SINGLE "---------- %s LINE NOT DISPLAYED ----------"
#define ISPF_EXCLUDE_PLURAL "---------- %s LINES NOT DISPLAYED ----------"
#define ISPF_EXCLUDE_RE     "^---------- {[0-9]+} LINE[A-Z ]* ----------"

/**
 * Structure containing all information about line commands
 * this information is gathered during the first pass through
 * the file for prefix commands, then used in the second pass
 * in order to process each command.
 */
struct ISPF_LC_INFO {

   int mc_start_line;          // first line of CC or MM selection
   int mc_end_line;            // last line of CC or MM selection
   boolean mc_is_copy;         // true if above is a CC, false for MM
   boolean mc_was_used;        // true after found A, B, or O command
   boolean z_selection;        // do we already have a 'z' selection?

   int pending_lc:[];          // list of pending line commands
   _str pending_args:[];       // list of pending line arguments

   int label_line_map:[];      // associates labels to line numbers
   _str line_insert_mask;      // line insertion mask

   int cursor_position;        // position to place cursor after everything
};

#define ISPF_LC_COLOR_PASS     1    // parse and color prefix area
#define ISPF_LC_EDIT_PASS      2    // Perform processing commands
#define ISPF_LC_UPDATE_PASS    3    // Update informational comamnds, dg BNDS

/**
 * Parse the given line prefix command and find base command
 * and optional number argument.
 *
 * @param lc_raw 'raw' line command text
 * @param line_flags line prefix area flags for this line
 * @param lc_str (reference) base line command, stripped and upcase
 * @param lc_arg (reference) line commaand argument
 * @param lc_val (reference) integer value of LC argument
 */
static void ispf_parse_lc(_str lc_raw, int line_flags, _str &lc_str, _str &lc_arg, int &lc_val)
{
   if (lc_raw=='') {
      if (line_flags & VSLCFLAG_BOUNDS) lc_raw='BNDS';
      if (line_flags & VSLCFLAG_COLS)   lc_raw='COLS';
      if (line_flags & VSLCFLAG_MASK)   lc_raw='MASK';
      if (line_flags & VSLCFLAG_TABS)   lc_raw='TABS';
   }
   if (substr(strip(lc_raw),1,1)==ISPF_LABEL_PREFIX) {
      lc_str = ISPF_LABEL_PREFIX;
      lc_arg = strip(lc_raw);
   } else if (pos("[0-9]#",lc_raw,1,'r')) {
      lc_arg = substr(lc_raw,pos('S'),pos(''));
      lc_str = substr(lc_raw,1,pos('S')-1):+substr(lc_raw,pos('S')+pos(''));
   } else if (substr(lc_raw,1,1)=='<' && isalpha(substr(lc_raw,1,2))) {
      lc_str = substr(lc_raw,2);
   } else {
      lc_str = lc_raw;
      lc_arg = '';
   }
   lc_str = upcase(strip(lc_str));
   lc_val = isinteger(lc_arg)? (int)lc_arg : 0;
}

/**
 * Find the corresponding move or copy block start and end lines
 *
 * @param startLine      beginning line of move or copy line commands
 * @param endLine        ending line of move or copy line commands
 * @param isCopy         is this a copy command (true) or a move (false)
 *
 * @return 0 on success, <0 on error.
 */
int ispf_find_move_copy(int &startLine, int &endLine, boolean &isCopy)
{
   // already know where the move/copy statement is
   if (startLine>0 && endLine>0) {
      return(0);
   }

   // initialize move/copy information in lcinfo
   startLine=0;
   endLine=0;
   isCopy=false;

   // search from start of line commands
   _str pending_command='';
   int pending_line=0;
   int i=0;
   for (i=0; i<_LCQNofLineCommands(); ++i) {
      // query this line command item
      _str lc_str, lc_arg; int lc_val;
      _str line_command = _LCQDataAtIndex(i);
      int  line_number  = _LCQLineNumberAtIndex(i);
      ispf_parse_lc(line_command, 0, lc_str, lc_arg, lc_val);

      switch (lc_str) {
      // commands operating on the next 'n' lines
      case 'C':     // copy
      case 'M':     // move
         if (startLine > 0) {
            // this is an error
            return(0);
         }
         if (pending_command!='') {
            // this is an error
            return(-1);
         }
         startLine = endLine = line_number;
         if (lc_arg!='' && isinteger(lc_arg)) {
            if (lc_val<=0) {
               return(-1);
            }
            endLine += lc_val-1;
         }
         isCopy    = (substr(lc_str,1,1):=='C');
         break;
      // block commands
      case 'CC':   // copy
      case 'MM':   // move
         if (startLine > 0) {
            // this is an error
            return(0);
         }
         if (pending_command=='') {
            pending_line=line_number;
            pending_command=lc_str;
         } else if (pending_command!=lc_str) {
            // this is an error
            return(-1);
         } else {
            startLine=pending_line;
            endLine   = line_number;
            isCopy    = (substr(lc_str,1,1):=='C');
            break;
         }
         break;
      default:
         break;
      }
   }
   // didn't find any move/copy commands?
   if (startLine<=0 || endLine<=0) {
      // this is also an error
      return(-1);
   }

   // that's all folks
   return(0);
}

/**
 * Find the MASK line
 *
 * @param lcinfo         line command information
 * @param i              start point, default is zero
 *
 * @return nothing
 */
static void ispf_find_mask(ISPF_LC_INFO &lcinfo, int i=0)
{
   // already found
   if (!lcinfo.pending_lc._indexin("MASK")) {
      return;
   }
   // search through rest of line commands
   for (; i<_LCQNofLineCommands(); ++i) {
      _str lc_str, lc_arg; int lc_val;
      _str line_command = _LCQDataAtIndex(i);
      int  line_number  = _LCQLineNumberAtIndex(i);
      if (line_command=="MASK") {
         p_line=line_number;
         if (_lineflags() & NOSAVE_LF) {
            lcinfo.pending_lc._deleteel("MASK");
            get_line(lcinfo.line_insert_mask);
            return;
         }
      }
   }
   // not found
}

/**
 * Insert or modify the ISPF no-save line for excluded lines
 *
 * @param n              number of lines to display as excluded
 * @param replace        replace the line (default inserts new line)
 */
void ispf_insert_exclude(int n, boolean replace=false)
{
   int orig_modify_flags=p_ModifyFlags;
   _str msg = (n>1)? ISPF_EXCLUDE_PLURAL:ISPF_EXCLUDE_SINGLE;
   if (replace) {
      replace_line(nls(msg,n));
   } else {
      nomod_insert_line(nls(msg,n));
      _LCSetData(' ');
      _lineflags(NOSAVE_LF,NOSAVE_LF);
      _lineflags(0,HIDDEN_LF);
   }
   p_ModifyFlags=orig_modify_flags;
}

/**
 * Is the current line the marker for an excluded line?
 *
 * @return the number of lines excluded, 0 if not an exclude line
 */
int ispf_is_excluded_line()
{
   if (_lineflags() & NOSAVE_LF) {
      _str line;get_line(line);
      if (pos(ISPF_EXCLUDE_RE,line,1,'re')) {
         return (int) (substr(line,pos('S0'),pos('0')));
      }
   }
   return 0;
}

/**
 * Create a tab line of at least 'line_length' characters
 *
 * @param tabs_setting
 *               from the 'tabs' command
 * @param line_length
 *               number of characters to expand tabs out to
 * @return string with tab positions marked with asterisks
 */
static _str tab_positions(_str tabs_setting, int line_length=ISPF_MAX_LINE)
{
   // first parse through the tabs settings
   int tab_incr=0;
   _str tab_result='';
   while (tabs_setting != '') {
      typeless posn="";
      parse tabs_setting with posn tabs_setting;
      tab_incr=((int)posn)-length(tab_result);
      if (tab_incr > 0) {
         strappend(tab_result,substr('',1,tab_incr-1,ISPF_FILL_CHAR):+ISPF_TAB_POSN_CHAR);
      }
   }
   // now fill in the rest of line with last increment
   while (tab_incr>0 && length(tab_result)<line_length) {
      strappend(tab_result,substr('',1,tab_incr-1,ISPF_FILL_CHAR):+ISPF_TAB_POSN_CHAR);
   }
   // that's all
   return tab_result;
}

/**
 * Parse the tab settings out of the given line
 *
 * @param tab_line       from the 'tabs' line
 *
 * @return tab settings string, appropriate for 'p_tabs' property
 */
static _str tab_settings(_str tab_line)
{
   // get the first tab position in the line
   int start_pos=pos(ISPF_TAB_POSN_CHAR,tab_line,1);
   int last_pos=start_pos;
   int last_incr=0;
   if (start_pos <= 0) {
      return '';
   }
   // get the rest of the tab positions
   _str tab_string=start_pos;
   _str tab_settings=tab_string;
   for (;;) {
      start_pos=pos(ISPF_TAB_POSN_CHAR,tab_line,start_pos+1);
      if (start_pos <= 0) {
         break;
      }
      strappend(tab_string,' ':+start_pos);
      if (start_pos-last_pos != last_incr) {
         tab_settings=tab_string;
      }
      last_incr=start_pos-last_pos;
      last_pos =start_pos;

   }
   // that's all folks
   return tab_settings;
}

boolean g_continuous_insert = false;
/**
 * Process a return in continuous insert mode
 *
 * @param null_return  is this a null return? If so it turns off continuous insert
 * 
 * @param lcinfo line comment information structure
 * @return whether the return was processed
 */
boolean ispf_process_return(boolean nullReturn)
{
   // Ends continuous insert
   if(g_continuous_insert && nullReturn) {
      g_continuous_insert = false;
      // delete the blank line that was just inserted.
      ispf_delete_lines(p_line, p_line);
   }

   if(!g_continuous_insert) {
      return false;
   }

   int line_number = p_line; 

   // insert the first line and set cursor position
   if (p_LCHasCursor) {
      _begin_line();
      p_LCHasCursor=false;
   }
   // insert the first line and set cursor position
   _end_line();
   ispf_split_line();
   int orig_col=p_col;
   _str line_mask='';
   replace_line(line_mask);

   p_line=line_number+1;
   p_col=orig_col;

   return true;
}

/**
 * Process the line comment information
 *
 * @param pass_number
 *               what processing should we perform?
 *               <LI> ISPF_LC_COLOR_PASS   --  parse and color prefix area
 *               <LI> ISPF_LC_EDIT_PASS    --  Perform processing commands
 *               <LI> ISPF_LC_UPDATE_PASS  --  Update informational comamnds, dg BNDS
 * @param lcinfo line comment information structure
 * @return int
 */
int ispf_process_lc(int pass_number, struct ISPF_LC_INFO &lcinfo)
{
   // initialize line command information, unless doing edit pass
   lcinfo.label_line_map._makeempty();
   lcinfo.pending_lc._makeempty();
   lcinfo.line_insert_mask='';
   lcinfo.mc_start_line=0;
   lcinfo.mc_end_line=0;
   lcinfo.mc_is_copy=false;
   lcinfo.mc_was_used=false;
   lcinfo.z_selection=false;
   lcinfo.pending_lc:["MASK"]=0;

   // have the bounds settings been changed
   boolean lc_bounds_modified=false;

   // turn the word wrap style off again, if a TE turned it on
   static boolean cancel_word_wrap;
   if (pass_number==ISPF_LC_EDIT_PASS && cancel_word_wrap) {
      p_word_wrap_style &= ~WORD_WRAP_WWS;
   }

   // process each line command, in order
   int  cur_col=p_col;
   _str cur_line='';
   int i,j;
   for (i=0; i<_LCQNofLineCommands(); ++i) {
      // query this line command item
      boolean calculate_i = false;
      _str lc_str, lc_arg; int lc_val;
      _str line_command = _LCQDataAtIndex(i);
      int  line_number  = _LCQLineNumberAtIndex(i);
      int  line_flags   = _LCQFlagsAtIndex(i);
      ispf_parse_lc(line_command, line_flags, lc_str, lc_arg, lc_val);
      if (pass_number==ISPF_LC_EDIT_PASS && isinteger(lc_arg) && lc_val<=0) {
         _message_box(nls("Line command repeat count can not be zero."));
         return 1;
      }

      // translate commands from XEDIT style commands to ISPF style commands
      if (def_ispf_xedit) {
         switch (lc_str) {
         case '/':  lc_str = "R";  break;
         case '"':  lc_str = "R";  break;
         case 'F':  lc_str = "A";  break;
         case 'A':  lc_str = 'I';  break;
         case 'P':  lc_str = 'B';  break;
         case 'L':  lc_str = 'LC'; break;
         case 'U':  lc_str = 'UC'; break;
         }
      }

      // handle block commands using common code
      int lc_start_line=0;
      int lc_end_line=0;
      boolean lc_do_block=false;
      boolean lc_remove_command=true;
      boolean lc_remove_start=false;
      switch (lc_str) {
      // commands operating on the next 'n' lines
      case 'C':     // copy
      case 'M':     // move
      case 'D':     // delete
      case 'MD':    // make data line
      case 'O':     // overlay
      case 'UC':    // uppercase
      case 'LC':    // lowercase
      case 'R':     // repeat
      case 'X':     // exclude
      case 'Z':     // create selection
         lc_start_line = lc_end_line = line_number;
         if (lc_arg!='' && isinteger(lc_arg) && lc_str!='R') {
            lc_end_line += lc_val-1;
         }
         lc_do_block = true;
         break;
      // block commands
      case '((':   // right shift
      case '))':   // left shift
      case '<<':   // right shift
      case '>>':   // left shift
      case 'CC':   // copy
      case 'MM':   // move
      case 'DD':   // delete
      case 'MDD':  // make data lines
      case 'MDMD': // make data lines
      case 'OO':   // overlay
      case 'RR':   // repeat
      case 'UCC':  // uppercase
      case 'UCUC': // uppercase
      case 'LCC':  // lowercase
      case 'LCLC': // lowercase
      case 'XX':   // exclude
      case 'ZZ':   // make selection
         if (lc_str:=="LCLC") lc_str="LCC";
         if (lc_str:=="UCUC") lc_str="UCC";
         if (lc_str:=="MDMD") lc_str="MDD";
         if (!lcinfo.pending_lc._indexin(lc_str)) {
            lcinfo.pending_lc:[lc_str]=line_number;
            lcinfo.pending_args:[lc_str]=lc_val;
            lc_remove_command=false;
         } else {
            if ((int) lcinfo.pending_args:[lc_str] != 0 || lc_val <= 0) {
               lc_val = (int) lcinfo.pending_args:[lc_str];
            }
            lc_start_line = lcinfo.pending_lc:[lc_str];
            lc_end_line = line_number;
            lcinfo.pending_lc._deleteel(lc_str);
            lcinfo.pending_args._deleteel(lc_str);
            lc_do_block=true;
            lc_remove_start=true;
         }
         break;
      default:
         break;
      }

      // process the line command
      switch (lc_str) {
      // Set ISPF or XEDIT style line label
      case ISPF_LABEL_PREFIX:
         lc_remove_command=false;
         if (upcase(substr(lc_arg,2,1))=='z') {
            // this is an error
            break;
         }
         if (lcinfo.label_line_map._indexin(lc_arg)) {
            // this is also an error
            break;
         }
         lcinfo.label_line_map:[lc_arg] = line_number;
         break;

      // Shift columns left or right two positions or specified number
      case '(':
      case ')':
      case '<':
      case '>':
         lc_start_line = line_number;
         lc_end_line = line_number;
         lc_do_block = true;
         // drop through
      case '((':
      case '))':
      case '<<':
      case '>>':
         if (lc_val<=0 && p_indent_style==INDENT_SMART) lc_val=p_SyntaxIndent;
         if (lc_val<=0) lc_val=2;
         if (lc_do_block && pass_number==ISPF_LC_EDIT_PASS) {
            if (_QReadOnly()) {
               _readonly_error(0);
               return 1;
            }
            ispf_shift_lines(lc_start_line, lc_end_line, lc_val,
                             (substr(lc_str,1,1):=='('||substr(lc_str,1,1):=='<'),
                             (substr(lc_str,1,1):=='<'||substr(lc_str,1,1):=='>'));
         }
         break;

      // Identifies the line after/before which copied or moved lines
      // are to be inserted.
      case 'A':
      case 'B':
         if (lc_val <= 0) lc_val=1;
         if (ispf_find_move_copy(lcinfo.mc_start_line,lcinfo.mc_end_line,lcinfo.mc_is_copy) < 0) {
            // error condition
            lc_remove_command=false;
            break;
         }
         // make sure that they are not trying to move block inside same block
         if (lcinfo.mc_is_copy == false &&
             line_number >= lcinfo.mc_start_line &&
             line_number <= lcinfo.mc_end_line) {
            // this is an error
            lc_remove_command=false;
            break;
         }
         // move the lines around
         if (pass_number==ISPF_LC_EDIT_PASS) {
            if (_QReadOnly()) {
               _readonly_error(0);
               return 1;
            }
            p_line=line_number;
            _LCSetData('');
            --i;
            lc_remove_command=false;
            ispf_copy_lines(lcinfo.mc_start_line,lcinfo.mc_end_line,
                            line_number,lc_val,lc_str/*A or B*/);
         }
         lcinfo.mc_was_used=true;
         if (lcinfo.mc_start_line > line_number) {
            lcinfo.mc_start_line=0;
            lcinfo.mc_end_line=0;
         } else if (lcinfo.mc_end_line > line_number) {
            lcinfo.pending_args:['CC']=0;
            lcinfo.pending_lc:['CC']=lcinfo.mc_start_line;
            lcinfo.mc_end_line=0;
            lcinfo.mc_start_line=0;
         }
         break;

      // Displays the column boundary definition line
      case 'BOUNDS':
      case 'BNDS':
         if (isEclipsePlugin()) {
           eclipse_show_disabled_msg("BNDS");
           return 1;
         }
         lc_remove_command=false;
         if (pass_number==ISPF_LC_EDIT_PASS) {
            p_line=line_number;
            cur_line=_expand_tabsc();
            // get the current right and left boundary settings
            if (_lineflags() & NOSAVE_LF) {
               if (!lc_bounds_modified) {
                  int lt_pos=pos(ISPF_LBND_POSN_CHAR,cur_line);
                  int gt_pos=pos(ISPF_RBND_POSN_CHAR,cur_line);
                  if (gt_pos>0 && !lt_pos) {
                     lt_pos=gt_pos;
                  }
                  if (lt_pos<=0 && gt_pos<=0) {
                     bounds := LanguageSettings.getBounds(p_LangId);
                     typeless lbound="";
                     typeless rbound="";
                     parse bounds with . 'BNDS='lbound rbound',';
                     if (isinteger(lbound)) lt_pos=lbound;
                     if (isinteger(rbound)) gt_pos=rbound;
                  }
                  if (lt_pos>0 && lt_pos!=p_BoundsStart) {
                     lc_bounds_modified=true;
                     p_BoundsStart=lt_pos;
                  }
                  if (gt_pos>0 && gt_pos>=lt_pos && gt_pos!=p_BoundsEnd) {
                     lc_bounds_modified=true;
                     p_BoundsEnd=gt_pos;
                  }
                  if (lc_bounds_modified) {
                     ispf_adjust_lc_bounds();
                  } else if (lt_pos<=0 || gt_pos<=0) {
                     replace_line(bounds_positions(p_BoundsStart,p_BoundsEnd));
                  }
               }
            } else {
               _LCSetData('');
               nomod_insert_line(bounds_positions(p_BoundsStart,p_BoundsEnd));
               _LCSetFlags(VSLCFLAG_BOUNDS,VSLCFLAG_BOUNDS);
               _lineflags(NOSAVE_LF,NOSAVE_LF);
            }
         }
         break;
      // Specified block of lines to be copied or moved
      case 'C':
      case 'M':
      case 'CC':
      case 'MM':
         lc_remove_command=false;
         if (lcinfo.mc_start_line > 0) {
            // this is an error
            break;
         }
         if (lc_do_block) {
            lcinfo.mc_start_line = lc_start_line;
            lcinfo.mc_end_line   = lc_end_line;
            if (lcinfo.pending_lc._indexin("MM") || lcinfo.pending_lc._indexin("CC")) {
               // this is an error
               break;
            }
            lcinfo.mc_is_copy = (substr(lc_str,1,1):=='C');
         }
         break;

      // Displays a column position identification line
      case 'COLS':
      case 'SCALE':
         lc_remove_command=false;
         if (pass_number==ISPF_LC_EDIT_PASS) {
            p_line=line_number;
            cur_line=_expand_tabsc();
            // get the current right and left boundary settings
            int lt_bound=8;
            int gt_bound=72;
            if (_lineflags() & NOSAVE_LF) {
               if (cur_line=='') {
                  nomod_delete_line();
                  --i;
               }
            } else {
               _LCSetData('');
               nomod_insert_line(ISPF_RULER_LINE);
               _LCSetFlags(VSLCFLAG_COLS,VSLCFLAG_COLS);
               _lineflags(NOSAVE_LF,NOSAVE_LF);
            }
         }
         break;

      // Deletes one or more lines
      case 'D':
      case 'DD':
         if (lc_do_block && pass_number==ISPF_LC_EDIT_PASS) {
            if (ispf_delete_lines(lc_start_line, lc_end_line)) {
               return 1;
            }
            calculate_i=true;
            lc_remove_command=false;
            if (lc_start_line < lcinfo.mc_end_line) {
               lcinfo.mc_start_line=0;
               lcinfo.mc_end_line=0;
            }
         }
         break;

      // Redisplays one or more lines at the beginning/end of
      // a block of excluded lines
      case 'F':
      case 'L':
      case 'S':
      case 'FF':
      case 'LL':
      case 'SS':
         p_line = line_number;
         if (!(_lineflags() & NOSAVE_LF)) {
            // this is an error
            lc_remove_command=false;
            break;
         }
         if (pass_number==ISPF_LC_EDIT_PASS && !_isdiffed(p_buf_id)) {
            for (i=line_number+1; i<=p_Noflines; ++i) {
               p_line=i;
               if (!(_lineflags() & HIDDEN_LF)) {
                  break;
               }
            }
            lc_start_line=line_number;
            lc_end_line=i-1;
            int counted_lines=i-line_number-1;
            if (lc_val <= 0) lc_val=1;
            if (lc_val > counted_lines || length(lc_str)==2) {
               lc_val=counted_lines;
            }
            ispf_expose_lines(lc_start_line, lc_end_line, lc_val, lc_str);
         }
         break;
      // Inserts one or more blank data entry lines
      case 'I':
      case 'TE':
         ispf_find_mask(lcinfo,i+1);
         if (pass_number==ISPF_LC_EDIT_PASS) {
            if (_QReadOnly()) {
               _readonly_error(0);
               return 1;
            }
            p_line=line_number;
            _LCSetData('');
            --i;
            lc_remove_command=false;
            if (lc_val <= 0) {
               g_continuous_insert=true;
               lc_val=1;
            }
            // insert the first line and set cursor position
            p_line=line_number;
            if (p_LCHasCursor) {
               _begin_line();
               p_LCHasCursor=false;
            }
            // insert the first line and set cursor position
            _end_line();
            ispf_split_line();
            int orig_col=p_col;
            _str line_mask=(lc_str=='TE')? '':lcinfo.line_insert_mask;
            replace_line(line_mask);
            // insert the rest of the lines
            for (j=1; j<lc_val; ++j) {
               p_line=line_number;
               insert_line(line_mask);
            }
            p_line=line_number+1;
            p_col=orig_col;
            _save_pos2(lcinfo.cursor_position);
            if (lc_str=='TE') {
               if (!(p_word_wrap_style&WORD_WRAP_WWS)) {
                  p_word_wrap_style|=WORD_WRAP_WWS;
                  cancel_word_wrap=true;
                  message(nls('Word wrap has been turned ON'));
               }
            }
         }
         break;

      // Displays the contents of the mask when used with the insert,
      // text entry, and text split line commands
      case 'MASK':
         ispf_find_mask(lcinfo,i+1);
         p_line=line_number;
         if (!(_lineflags() & NOSAVE_LF)) {
            nomod_insert_line(lcinfo.line_insert_mask);
            _LCSetFlags(VSLCFLAG_MASK,VSLCFLAG_MASK);
            _lineflags(NOSAVE_LF,NOSAVE_LF);
         } else {
            get_line(lcinfo.line_insert_mask);
            lc_remove_command=false;
            lcinfo.pending_lc._deleteel("MASK");
         }
         break;

      // Converts one or more MSG, NOTE, COLS or other information lines
      // to data so that they can be saved as part of your data set
      case 'MD':
      case 'MDD':
      case 'MDMD':
         if (lc_do_block && pass_number==ISPF_LC_EDIT_PASS) {
            if (_QReadOnly()) {
               _readonly_error(0);
               return 1;
            }
            ispf_make_data_lines(lc_start_line, lc_end_line);
         }
         break;

      // Identifies the lines over which data is to be moved or copied
      case 'O':
      case 'OO':
         if (ispf_find_move_copy(lcinfo.mc_start_line,lcinfo.mc_end_line,lcinfo.mc_is_copy) < 0) {
            // error condition
            lc_remove_command=false;
            break;
         }
         if (lc_do_block && pass_number==ISPF_LC_EDIT_PASS) {
            if (_QReadOnly()) {
               _readonly_error(0);
               return 1;
            }
            ispf_overlay_lines(lcinfo.mc_start_line, lcinfo.mc_end_line,
                               lc_start_line, lc_end_line);
         }
         lcinfo.mc_was_used=true;
         break;

      // Repeats one or more lines
      case 'R':
      case 'RR':
         if (lc_val <= 0) lc_val=1;
         if (lc_do_block && pass_number==ISPF_LC_EDIT_PASS) {
            if (_QReadOnly()) {
               _readonly_error(0);
               return 1;
            }
            ispf_copy_lines(lc_start_line,lc_end_line,line_number,lc_val,'A');
         }
         break;

      // Displays the tab definition line
      case 'TABS':
      case 'TABL':
         lc_remove_command=false;
         if (pass_number==ISPF_LC_EDIT_PASS) {
            p_line=line_number;
            // get the current tabs setting
            if (_lineflags() & NOSAVE_LF) {
               cur_line=_expand_tabsc();
               _str ispf_tabs=tab_settings(cur_line);
               if (ispf_tabs!='') {
                  if (ispf_tabs!=p_tabs) {
                     p_tabs=ispf_tabs;
                  }
               } else {
                  nomod_delete_line();
                  --i;
               }
            } else {
               _LCSetData('');
               nomod_insert_line(tab_positions(p_tabs));
               _LCSetFlags(VSLCFLAG_TABS,VSLCFLAG_TABS);
               _lineflags(NOSAVE_LF,NOSAVE_LF);
            }
         }
         break;

      // Reflows paragraphs according to margin boundaries
      case 'TF':
         if (pass_number==ISPF_LC_EDIT_PASS) {
            if (_QReadOnly()) {
               _readonly_error(0);
               return 1;
            }
            _str orig_margins=p_margins;
            typeless lm="", rm="", nm="";
            parse p_margins with lm rm nm;
            if (p_BoundsStart > 0) lm=p_BoundsStart;
            if (lc_val <= 0) lc_val=p_BoundsEnd;
            if (lc_val <= 0) lc_val=p_TruncateLength;
            if (lc_val <= 0) lc_val=rm;
            p_margins=lm' 'lc_val' 'nm;
            p_line=line_number;
            reflow_paragraph();
            p_margins=orig_margins;
         }
         break;

      // Joins line with previous line
      case 'TJ':
         if (pass_number==ISPF_LC_EDIT_PASS) {
            if (_QReadOnly()) {
               _readonly_error(0);
               return 1;
            }
            p_line=line_number;
            join_line();
         }
         break;

      // Splits line at current column position
      case 'TS':
         if (pass_number==ISPF_LC_EDIT_PASS) {
            if (_QReadOnly()) {
               _readonly_error(0);
               return 1;
            }
            p_line=line_number;
            p_col=cur_col;
            _LCSetData("");
            ispf_split_line();
         }
         break;

      // Converts all lowercase alphabetic characters in one or more
      // lines to uppercase or lowercase
      case 'UC':
      case 'LC':
      case 'UCC':
      case 'UCUC':
      case 'LCC':
      case 'LCLC':
         if (lc_do_block && pass_number==ISPF_LC_EDIT_PASS) {
            if (_QReadOnly()) {
               _readonly_error(0);
               return 1;
            }
            ispf_case_lines(lc_start_line, lc_end_line,(substr(lc_str,1,1):=='U'));
         }
         break;

      // Excludes one or more lines from a panel
      case 'X':
      case 'XX':
         if (lc_do_block && pass_number==ISPF_LC_EDIT_PASS && !_isdiffed(p_buf_id)) {
            if (lc_remove_start) {
               p_line=lc_start_line;
               _LCSetData('');
               i--;
            }
            p_line=line_number;
            _LCSetData('');
            --i;
            lc_remove_command=false;
            ispf_exclude_lines(lc_start_line, lc_end_line);
         }
         break;

      // Creates a line selection for the marked lines
      case 'Z':
      case 'ZZ':
         if (lcinfo.z_selection) {
            // this is an error
            break;
         }
         if (lc_do_block && pass_number==ISPF_LC_EDIT_PASS) {
            lcinfo.z_selection=true;
            ispf_select_lines(lc_start_line, lc_end_line);
         }
         break;

      // Various informational lines
      case '-----':
      case '- - -':
      case ' ':
      case '':
      case 'ERR>':
      case 'NOTE>':
      case 'MSG>':
      case 'PROF>':
         lc_remove_command=false;
         break;

      // unrecognized command, this is an error
      default:
         lc_remove_command=false;
         message(nls("Unrecognized line prefix command on line %s.",line_number));
         return 1;
      }

      // remove line command
      if (lc_remove_command && pass_number==ISPF_LC_EDIT_PASS) {
         if (lc_remove_start) {
            p_line=lc_start_line;
            _LCSetData('');
            i--;
         }
         p_line=line_number;
         _LCSetData('');
         --i;
      }
      // lines are deleted
      if (calculate_i) {
         for (j=0; j<_LCQNofLineCommands(); ++j) {
            if (_LCQLineNumberAtIndex(j) >= lc_start_line) {
               i=j-1;
               break;
            }
         }
      }
   }

   // remove contents of move block
   if (pass_number==ISPF_LC_EDIT_PASS) {
      if (lcinfo.mc_start_line>0 && lcinfo.mc_end_line>0) {
         if (lcinfo.mc_was_used) {
            if (_QReadOnly()) {
               _readonly_error(0);
               return 1;
            }
            if (lcinfo.mc_is_copy==false) {
              ispf_delete_lines(lcinfo.mc_start_line, lcinfo.mc_end_line);
            } else {
               p_line=lcinfo.mc_start_line;
               _LCSetData('');
               p_line=lcinfo.mc_end_line;
               _LCSetData('');
            }
         } else {
            ispf_select_lines(lcinfo.mc_start_line,lcinfo.mc_end_line);
         }
      }
   }

   // we should report any pending commands here and color code prefix area

   // that's all folks
   return 0;
}


/**
 * Copy block of lines beginning at start_line and ending at end_line
 * after the destination line.
 *
 * @param start_line line to start copying from
 * @param end_line line to stop copying at
 * @param dest_line destination line for copy operation (insert after)
 * @param num_times number of times to copy the block of lines
 * @param line_insert_style
 *                   insert before 'B' or after 'A' (default)
 * @return 0 on success, <0 on error
 */
static int ispf_copy_lines(int start_line, int end_line, int dest_line,
                           int num_times, _str line_insert_style='A')
{
   //say("ispf_copy_lines: start="start_line" end="end_line" dest="dest_line" num="num_times);
   // allocate a selection
   int mark_id=_alloc_selection();
   if (mark_id<0){
      message(get_message(mark_id));
      return(mark_id);
   }
   // select the block of lines
   p_line=start_line;
   _select_line(mark_id,'C');
   p_line=end_line;
   _show_selection(mark_id);
   lock_selection('q');
   // and paste the selection here...
   p_line=dest_line;
   _str orig_line_insert=def_line_insert;
   def_line_insert=line_insert_style;
   int i;
   for (i=0; i<num_times; ++i) {
      copy_to_cursor(mark_id);
   }
   def_line_insert=orig_line_insert;
   _free_selection(mark_id);
   return(0);
}

/**
 * Merge the source line into the destination line as an overlay.
 * Whitespace in the destination line is overlayed with the contents
 * of the corresponding character in the source line.
 *
 * @param src_line       source line
 * @param dst_line       destination line
 *
 * @return merged line
 */
static _str ispf_merge_line(_str src_line, _str dst_line)
{
   int k=1;
   for (;;++k) {
      if (k>length(src_line)) {
         break;
      }
      if (k>length(dst_line)) {
         dst_line=dst_line:+' ';
      }
      if (substr(dst_line,k,1)==' ') {
         dst_line=substr(dst_line,1,k-1):+substr(src_line,k,1):+substr(dst_line,k+1);
      }
   }
   return dst_line;
}

/**
 * Copy block of lines beginning at start_line and ending at end_line
 * after the destination line.
 *
 * @param src_start_line line to start copying from
 * @param src_end_line   line to quit copying from
 * @param dst_start_line destination line for overlay
 * @param dst_end_line   final destination line for overlay
 *
 * @return 0 on success, <0 on error
 */
static int ispf_overlay_lines(int src_start_line, int src_end_line,
                              int dst_start_line, int dst_end_line)
{
   //say("ispf_overlay_lines: src=("src_start_line","src_end_line") dst=("dst_start_line","dst_end_line")");
   _str lines[]; lines._makeempty();
   int i=src_start_line;
   int j=dst_start_line;
   for (;;) {
      if (i>src_end_line) {
         i=src_start_line;
      }
      if (j>dst_end_line) {
         break;
      }
      p_line=i++;
      _str src_line=_expand_tabsc();
      if (_lineflags() & NOSAVE_LF) {
         continue;
      }
      p_line=j++;
      _str cur_line=_expand_tabsc();
      if (_lineflags() & NOSAVE_LF) {
         --i;
         continue;
      }
      _str dst_line = ispf_merge_line(src_line,cur_line);
      if (cur_line :!= dst_line) {
         replace_line(dst_line);
      }
   }
   return(0);
}

/**
 * Remove lines starting at start_line and ending at end_line
 *
 * @param start_line     first line to delete
 * @param end_line       last line to delete
 *
 * @return 0 on success, <0 on error.
 */
static int ispf_delete_lines(int start_line, int end_line)
{
   //say("ispf_delete_lines: ("start_line","end_line")");
   // allocate a selection
   int mark_id=_alloc_selection();
   if (mark_id<0){
      message(get_message(mark_id));
      return(mark_id);
   }
   // select the block of lines
   p_line=start_line;
   int real_line=p_RLine;
   boolean is_no_save=(_lineflags() & NOSAVE_LF)? true:false;
   _select_line(mark_id,'C');
   p_line=end_line;
   int count=ispf_is_excluded_line();
   if (count > 0) {
      p_line+=count;
   } else if (_lineflags() & HIDDEN_LF) {
      int last_line=p_line;
      while (_lineflags() & HIDDEN_LF) {
         p_line++;
         if (last_line<=p_line) {
            break;
         }
         last_line=p_line;
      }
   }
   if (is_no_save && p_RLine!=real_line) {
      is_no_save=false;
   }
   if (!is_no_save && _QReadOnly()) {
      _readonly_error(0);
      return 1;
   }
   // delete the selection
   int orig_modify_flags=p_ModifyFlags;
   _show_selection(mark_id);
   _delete_selection(mark_id);
   if (is_no_save) {
      p_ModifyFlags=orig_modify_flags;
   }
   return(0);
}

/**
 * Make data lines out of no-save lines
 *
 * @param start_line     first line to delete
 * @param end_line       last line to delete
 *
 * @return 0 on success, <0 on error.
 */
static int ispf_make_data_lines(int start_line, int end_line)
{
   int i;
   for (i=start_line; i<=end_line; ++i) {
      p_line=i;
      if (_lineflags() & NOSAVE_LF) {
         _lineflags(0,NOSAVE_LF);
         _LCSetFlags(0,-1);
         _LCSetData('');
      }
   }
   return(0);
}

/**
 * Exclude (make invisible) lines starting at start_line and ending at end_line
 *
 * @param start_line     first line to delete
 * @param end_line       last line to delete
 *
 * @return 0 on success, <0 on error.
 */
static int ispf_exclude_lines(int start_line, int end_line)
{
   //say("ispf_exclude_lines: start="start_line" end="end_line);

   // start line and number of lines for each exclusion
   int exclude_start[]; exclude_start._makeempty();
   int exclude_lines[]; exclude_lines._makeempty();

   // extend start of exclude if preceeding item is exclude block
   _str line;
   while (start_line > 1) {
      //say("ispf_exclude_lines: start+line="start_line);
      p_line=start_line-1;
      if (_lineflags() & HIDDEN_LF) {
         --start_line;
         continue;
      }
      if (ispf_is_excluded_line()) {
         --start_line;
         continue;
      }
      break;
   }

   // extend end of exclude block if following items is exclude block
   //say("ispf_exclude_lines: start="start_line" end="end_line);
   while (end_line<=p_Noflines) {
      p_line=end_line+1;
      if (_lineflags() & HIDDEN_LF) {
         ++end_line;
         continue;
      }
      if (ispf_is_excluded_line()) {
         ++end_line;
         continue;
      }
      break;
   }

   //say("ispf_exclude_lines: start="start_line" end="end_line);
   int i,n=0;
   for (i=start_line; i<=end_line; ++i) {
      p_line=i;
      //delete_line();
      if (_lineflags() & NOSAVE_LF) {
         if (ispf_is_excluded_line()) {
            nomod_delete_line();
            --end_line;
            --i;
         } else if (n>0) {
            exclude_start[exclude_start._length()]=start_line;
            exclude_lines[exclude_lines._length()]=n;
            n=0;
            start_line=i;
         }
         continue;
      }

      _lineflags(HIDDEN_LF,HIDDEN_LF);
      ++n;
   }
   if (n>0) {
      exclude_start[exclude_start._length()]=start_line-1;
      exclude_lines[exclude_lines._length()]=n;
   }

   for (i=exclude_lines._length()-1; i>=0; --i) {
      n=exclude_lines[i];
      if (n > 0) {
         p_line = exclude_start[i];
         ispf_insert_exclude(n);
      }
   }

   // that's all folks
   return(0);
}

/**
 * Remove lines starting at start_line and ending at end_line
 *
 * @param start_line first line to unhide
 * @param end_line last line to unhide
 * @param num_items number of items to find
 * @param lc_str line command used
 * @return 0 on success, <0 on error.
 */
static int ispf_expose_lines(int start_line, int end_line, int num_items, _str lc_str)
{
   //say("ispf_expose_lines("start_line","end_line","num_items","lc_str")");
   // start line and number of lines for each exclusion
   int exclude_start[]; exclude_start._makeempty();
   int exclude_lines[]; exclude_lines._makeempty();

   // find the minimum indent in this block of lines
   _str cur_line;
   int i,min_indent=MAXINT;
   if (substr(lc_str,1,1)=='S') {
      for (i=start_line; i<=end_line; ++i) {
         p_line=i;
         if (_lineflags() & NOSAVE_LF) {
            continue;
         }
         if (!(_lineflags() & HIDDEN_LF)) {
            break;
         }
         cur_line=_expand_tabsc();
         if (cur_line=='') {
            continue;
         }
         int p = pos('[^ ]',cur_line,1,'r');
         if (p<min_indent) {
            min_indent=p;
         }
      }
   }
   // unhide the lines that need to be exposed
   int first_hidden=start_line-1;
   int num_hidden=0;
   int num_unhidden=0;
   int dir=(substr(lc_str,1,1)=='L')? -1:1;
   for (i=((dir>0)?start_line:end_line); i>=start_line && i<=end_line; i+=dir) {
      p_line=i;
      get_line(cur_line);
      // watch out for hidden lines and no-save lines
      if (_lineflags() & NOSAVE_LF) {
         if (ispf_is_excluded_line()) {
            nomod_delete_line();
            --end_line;
            --i;
         }
         continue;
      }
      if (!(_lineflags() & HIDDEN_LF)) {
         continue;
      }

      // does this line match the desired indent level
      if (substr(lc_str,1,1)=='S') {
         cur_line = _expand_tabsc();
         int p = pos('[^ ]',cur_line,1,'r');
         if ((cur_line==''&&num_hidden>0) || p>min_indent) {
            num_hidden++;
            continue;
         }
      }

      // keep track of number of lines not hidden
      if (num_unhidden >= num_items) {
         num_hidden++;
         continue;
      }

      // restart counter for number of lines hidden
      if (num_hidden > 0) {
         exclude_start[exclude_start._length()]=first_hidden;
         exclude_lines[exclude_lines._length()]=num_hidden;
         num_hidden=0;
      }

      // expose the line and check for termination condition
      _lineflags(0,HIDDEN_LF);
      if (_lineflags() & PLUSBITMAP_LF) {
         _lineflags(0,PLUSBITMAP_LF);
         _lineflags(MINUSBITMAP_LF,MINUSBITMAP_LF);
      }
      num_unhidden++;
      if (dir>0) {
         first_hidden=i;
      }
   }
   //say("ispf_expose_lines: num_hidden="num_hidden);
   if (num_hidden > 0) {
      exclude_start[exclude_start._length()]=first_hidden;
      exclude_lines[exclude_lines._length()]=num_hidden;
   }

   // put in the exclude lines messages
   for (i=exclude_lines._length()-1; i>=0; --i) {
      int n=exclude_lines[i];
      if (n > 0) {
         p_line = exclude_start[i];
         ispf_insert_exclude(n);
      }
   }

   // that's all folks
   return(0);
}

/**
 * Change the case of lines starting at start_line and ending at end_line
 *
 * @param start_line     first line to delete
 * @param end_line       last line to delete
 * @param upcase_option  make lines upper case (false=lower case)
 *
 * @return 0 on success, <0 on error.
 */
static int ispf_case_lines(int start_line, int end_line, boolean upcase_option)
{
   _str cur_line, new_line;
   int i=0;
   for (i=start_line; i<=end_line; ++i) {
      p_line=i;
      if (_lineflags() & NOSAVE_LF) {
         continue;
      }
      get_line(cur_line);
      if (upcase_option) {
         new_line=upcase(cur_line);
      } else {
         new_line=lowcase(cur_line);
      }
      if (new_line:!=cur_line) {
         replace_line(new_line);
      }
   }
   return(0);
}

/**
 * Shift a block of lines left or right.
 *
 * @param start_line first line to indent
 * @param end_line last line to indent
 * @param num_cols number of columns to indent
 * @param left_shift shift the lines left (true) or right (false)
 * @param smart_shift
 *                   shift code, or just text shift
 * @return 0 on success, <0 on error.
 */
static int ispf_shift_lines(int start_line, int end_line, int num_cols,
                            boolean left_shift, boolean smart_shift)
{
   // allocate a selection
   typeless mark_id= _alloc_selection();
   if (mark_id<0){
      message(get_message(mark_id));
      return(mark_id);
   }
   // select the block of lines
   int orig_trunc=p_TruncateLength;
   p_line=start_line;
   if (p_BoundsStart>0 && p_BoundsEnd>0) {
      p_col=p_BoundsStart;
      p_TruncateLength=p_BoundsEnd;
      _select_block(mark_id,'C');
   } else {
      _select_line(mark_id,'C');
   }
   p_line=end_line;
   if (p_BoundsEnd>0) {
      p_col=p_BoundsEnd;
   }
   _show_selection(mark_id);
   // perform the shift operation
   if (left_shift) {
      shift_selection_left(num_cols);
   } else {
      shift_selection_right(num_cols);
   }
   p_TruncateLength=orig_trunc;
   // free the selection
   _free_selection(mark_id);
   return(0);
}

/**
 * Lock a selection on a block of lines
 *
 * @param start_line     first line to indent
 * @param end_line       last line to indent
 *
 * @return 0 on success, <0 on error.
 */
static int ispf_select_lines(int start_line, int end_line)
{
   // allocate a selection
   typeless mark_id= _alloc_selection();
   if (mark_id<0){
      message(get_message(mark_id));
      return(mark_id);
   }
   // select the block of lines
   p_line=start_line;
   _select_line(mark_id,'C');
   p_line=end_line;
   // display the selection
   _show_selection(mark_id);
   lock_selection('q');
   return(0);
}

/**
 * Process ISPF Line Comments, usually bound to ENTER or CTRL/ENTER key
 * or RIGHT CTRL key.
 * 
 * @return 0 on success, <0 on error
 * 
 * @see ispf_enter
 * @see ispf_locate
 * @see ispf_reset
 * @see help:ISPF Line Commands
 * 
 * @categories ISPF_Primary_Commands
 */
_command int ispf_do_lc(_str column_number="") name_info(','VSARG2_READ_ONLY|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   if (!_isEditorCtl()) {
      return(-1);
   }
   struct ISPF_LC_INFO lcinfo;
   _save_pos2(lcinfo.cursor_position);
   if (column_number!="" && isinteger(column_number)) {
      p_col=(int)column_number;
   }
   int status = ispf_process_lc(ISPF_LC_EDIT_PASS,lcinfo);
   _restore_pos2(lcinfo.cursor_position);
   return(status);
}

/**
 * Create the bounds line for the given settings
 *
 * @param start_col left edit boundary column
 * @param end_col right edit boundary column
 * @return string containing bounds line
 */
static _str bounds_positions(int start_col, int end_col)
{
   if (start_col==end_col && start_col>0) {
      return(substr('',1,start_col-1):+ISPF_RBND_POSN_CHAR);
   }
   _str result = substr('',1,start_col-1):+ISPF_LBND_POSN_CHAR;
   if (end_col > start_col) {
      strappend(result,substr('',1,end_col-start_col-1):+ISPF_RBND_POSN_CHAR);
   }
   return result;
}
static void nomod_insert_line(_str line)
{
   int ModifyFlags=p_ModifyFlags;
   insert_line(line);
   p_ModifyFlags=ModifyFlags;
}
static void nomod_delete_line()
{
   int ModifyFlags=p_ModifyFlags;
   _delete_line();
   p_ModifyFlags=ModifyFlags;
}
/**
  Adjust the boundaries displayed for each bounds command
*/
void ispf_adjust_lc_bounds()
{
   typeless p;
   _save_pos2(p);
   int i,n=_LCQNofLineCommands();
   for (i=0;i<n;++i) {
      if (_LCQFlagsAtIndex(i) & VSLCFLAG_BOUNDS) {
         p_line=_LCQLineNumberAtIndex(i);
         replace_line(bounds_positions(p_BoundsStart,p_BoundsEnd));
      }
   }
   _restore_pos2(p);
}

/**
  Update the line comments coloring and information table
*/
static struct ISPF_LC_INFO glcinfo;
/**
 * Update the line command area, primary purpose of this
 * function is to color code incomplete commands and mark
 * selections.
 */
void _UpdateLC()
{
   // cache name of last buffer updated
   static _str last_buf_name;

   // outside of current context
   if (last_buf_name!=p_buf_name || !(p_ModifyFlags&MODIFYFLAG_LC_UPDATED)) {
      ispf_process_lc(ISPF_LC_COLOR_PASS,glcinfo);
      p_ModifyFlags |= MODIFYFLAG_LC_UPDATED;
      last_buf_name = p_buf_name;
   }
}

#if 0
/**
 * Return the line number that the given label is located on
 *
 * @param label_name     name of label to search prefix area for
 */
int _GetLCLabelLine(_str label_name)
{
   _UpdateLC();
   if (glcinfo.label_line_map._indexin(label_name)) {
      return glcinfo.label_line_map:[label_name];
   }
   return 0;
}

/**
 * Return the bounds settings for the current buffer
 *
 * @param right_bounds   Right boundary setting
 * @param left_bounds    Left boundary setting
 */
void _GetLCBounds(int &left_bounds,int &right_bounds)
{
   _UpdateLC();
   left_bounds  = p_BoundsStart;
   right_bounds = p_BoundsEnd;
}
#endif

/**
 * Parse label or line number from command line.
 *
 * @param word           label or line number to parse
 * @param displayError   display error message if label or line not found
 *
 * @return <0 on error, otherwise line number found.
 */
int ispf_parse_label(_str word, boolean displayError=true)
{
   // is it a label
   if (substr(word,1,1)==ISPF_LABEL_PREFIX) {
      return _LCFindLabel(word,displayError);
   }
   // maybe a line number
   if (isinteger(word)) {
      int line_number = (int) word;
      if (line_number < 0 || line_number > p_Noflines) {
         if (displayError) {
            _message_box(nls("Line number %d out of range %s..%s",line_number,1,p_Noflines));
         }
         return -2;
      }
      return line_number;
   }
   // not a label or line number, report error
   if (displayError) {
      _message_box(nls("Expecting ISPF label or line number"));
   }
   return -1;
}

/**
 * Parse label range (or line number range) from command line.
 * The results are placed in startLine and endLine, and the
 * current word being parsed and command line are updated so
 * we can continue parsing after the label range.
 *
 * @param word           (reference) first word of command line
 * @param cmdline        (reference) rest of command line to parse
 * @param startLine      (reference) start line of label range
 * @param endLine        (reference) ending line of label range
 * @param displayError   display error message if label or line not found
 *
 * @return 0 on success, <0 on error.
 */
int ispf_parse_range(_str &word,_str &cmdline,
                     int &startLine,int &endLine,
                     boolean displayError=true)
{
   // maybe a line number
   // get the first label or line number
   int line_number=ispf_parse_label(word,displayError);
   if (line_number < 0) {
      return line_number;
   }
   startLine = line_number;

   // get the next word on the command line
   parse strip(cmdline) with word cmdline;

   // get the second label or line number
   line_number=ispf_parse_label(word,displayError);
   if (line_number < 0) {
      return line_number;
   }
   endLine = line_number;

   // check that the range is in the right order and fix it if not
   if (startLine > endLine) {
      int temp=startLine;
      startLine = endLine;
      endLine=temp;
   }

   // that's all folks
   return 0;
}

/**
 * Deletes lines in the given line range, or the entire buffer.
 * 
 * <p>Sytnax:<pre>
 *    DELETE [ ALL| X| NX ] [ <i>line_range</i> ]
 * </pre>
 * 
 * 
 * <dl compact style="margin-left:20pt">
 * <dt><i>line_range</i><dd style="margin-left:90pt">Two numbers or labels, specifying the starting and ending lines to delete.
 * <dt>ALL<dd style="margin-left:90pt">Delete all lines in the range, excluded or not excluded.  If no line range is given, all implies the entire buffer.
 * <dt>X<dd style="margin-left:90pt">Only delete excluded lines.
 * <dt>NX<dd style="margin-left:90pt">Only delete displayed lines.
 * </dl>
 * 
 * @see delete_line
 * @see help:ISPF Line Command Delete
 * 
 * @categories ISPF_Primary_Commands
 */
_command void ispf_delete,ispf_del(_str cmdline="") name_info(','VSARG2_REQUIRES_MDI_EDITORCTL)
{
   boolean delete_excluded=false;
   boolean delete_non_excl=false;
   int startLine=-1;
   int endLine=-1;

   if (cmdline=='') {
      startLine=p_line;
      endLine=p_line;//+ispf_is_excluded_line();
      delete_excluded=true;
      delete_non_excl=true;
   }
   while (cmdline!='') {
      _str word="";
      cmdline=strip(cmdline);
      parse cmdline with word cmdline;
      switch (upcase(strip(word))) {
      case 'X':
      case 'EX':
         delete_excluded=true;
         delete_non_excl=false;
         if (startLine<0 && endLine>=0) {
            startLine=1;
         }
         break;
      case 'N':
      case 'NX':
         delete_non_excl=true;
         delete_excluded=false;
         if (startLine<0 && endLine>=0) {
            startLine=1;
         }
         break;
      case 'A':
      case 'ALL':
         if (startLine<0) {
            endLine=p_Noflines;
         }
         delete_excluded=true;
         delete_non_excl=true;
         break;
      default:
         // it is a label or line number
         int status=ispf_parse_range(word,cmdline,startLine,endLine);
         if (status < 0) {
            return;
         }
         if (delete_excluded==false && delete_non_excl==false) {
            delete_excluded=true;
            delete_non_excl=true;
         }
      }
   }
   // check that the start and end lines are valid
   //say("ispf_delete: start="startLine" end="endLine" ex="delete_excluded" nx="delete_non_excl);
   if (startLine<0 || endLine<0 || endLine>p_Noflines || startLine>p_Noflines ||
       (delete_excluded==false && delete_non_excl==false)) {
      message("Usage: DELETE [ALL] [start_label end_label] [X | NX]");
      return;
   }
   // swap begin/end if they are out of order
   if (startLine > endLine) {
      int temp=startLine;
      startLine=endLine;
      endLine=temp;
   }
   // delete the lines
   int deleted_hidden=0;
   if (startLine==0) ++startLine;
   int i;
   for (i=endLine; i>=startLine; --i) {
      p_line=i;
      if (i>0 && p_line!=i) {
         break;
      }
      if (!delete_excluded && (_lineflags()&(HIDDEN_LF|NOSAVE_LF))) {
         continue;
      }
      if (!delete_non_excl && !(_lineflags()&(HIDDEN_LF|NOSAVE_LF))) {
         continue;
      }
      if ((_lineflags()&NOSAVE_LF) && (deleted_hidden > 0)) {
         int n=ispf_is_excluded_line();
         if (n <= 0) {
            continue;
         }
         n -= deleted_hidden;
         if (n > 0) {
            ispf_insert_exclude(n,true);
            continue;
         }
      }
      if (_lineflags() & HIDDEN_LF) {
         deleted_hidden++;
      } else {
         deleted_hidden=0;
      }
      if (_lineflags() & NOSAVE_LF) {
         nomod_delete_line();
      } else {
         _delete_line();
      }
   }
   if (deleted_hidden > 0) {
      for (i=startLine-1; i>0; --i) {
         p_line=i;
         if (!(_lineflags() & (HIDDEN_LF|NOSAVE_LF))) {
            break;
         }
         if (_lineflags() & NOSAVE_LF) {
            int n=ispf_is_excluded_line();
            if (n <= 0) {
               continue;
            }
            n -= deleted_hidden;
            if (n > 0) {
               ispf_insert_exclude(n,true);
               continue;
            }
            break;
         }
      }
   }
}

/**
 * Reverse excluded lines for visible lines.  All excluded lines
 * become visible and all visisble lines become excluded.
 * This command does not effect no-save lines.
 * 
 * @see ispf_exclude
 * @see ispf_find
 * @see help:ISPF Line Command Exclude
 * @see help:ISPF Line Command First
 * 
 * @categories ISPF_Primary_Commands
 */
_command void ispf_flip(_str cmdline="") name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   if (_isdiffed(p_buf_id)) {
      return;
   }
   // get first label or line number
   int startLine=-1;
   int endLine=-1;
   _str word="";
   parse strip(cmdline) with word cmdline;

   // get the start line number
   if (word=='') {
      startLine=1;
      endLine=p_Noflines;
   } else {
      startLine = ispf_parse_label(word);
      if (startLine < 0) {
         return;
      }
   }

   // get ending label or line number
   parse strip(cmdline) with word cmdline;
   if (word!='') {
      endLine = ispf_parse_label(word);
      if (endLine < 0) {
         return;
      }
   }

   // complain if there is a problem with the arguments
   if (cmdline!='' || startLine<0 || endLine<0) {
      _message_box("Usage: FLIP [start end]");
   }

   // count the hidden lines after the block to flip
   int i,numHidden=0;
   for (i=endLine+1; i<=p_Noflines; ++i) {
      p_line=i;
      if (p_line!=i) {
         break;
      }
      if (_lineflags() & HIDDEN_LF) {
         ++numHidden;
      }
   }

   // toggle the hidden and un-hidden lines
   for (i=endLine; i>=startLine; --i) {
      p_line=i;
      if (p_line!=i) {
         break;
      }
      // no save line, have to insert this line
      if (_lineflags() & NOSAVE_LF) {
         boolean is_excl = (ispf_is_excluded_line() > 0);
         if (numHidden > 0) {
            ispf_insert_exclude(numHidden,is_excl);
            numHidden=0;
         } else if (is_excl) {
            nomod_delete_line();
         }
         continue;
      }
      // line is hidden, then unhide it, that's all
      if (_lineflags() & HIDDEN_LF) {
         _lineflags(0,HIDDEN_LF);
         if (numHidden > 0) {
            ispf_insert_exclude(numHidden);
            numHidden=0;
         }
         continue;
      }
      // line is not hidden, then hide it and increment count
      _lineflags(HIDDEN_LF,HIDDEN_LF);
      ++numHidden;
   }

   // adjust the hidden line counts before the block to flip
   for (i=startLine-1; i>0; --i) {
      p_line=i;
      if (p_line!=i) {
         break;
      }
      if (!(_lineflags() & HIDDEN_LF)) {
         if (_lineflags() & NOSAVE_LF) {
            boolean is_excl = (ispf_is_excluded_line() > 0);
            if (numHidden > 0) {
               ispf_insert_exclude(numHidden,is_excl);
               numHidden=0;
            } else if (is_excl) {
               nomod_delete_line();
            }
         }
         break;
      }
      ++numHidden;
   }

   // insert the final exclude no-save line
   if (numHidden>0) {
      p_line=startLine-1;
      ispf_insert_exclude(numHidden);
   }
}
#if 0
/**
 * Turn automatic renumbering on save on/off.
 */
_command void ispf_autonum(_str cmdline="") name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   // parse through the arguments
   int orig_renumber_flags=def_renumber_flags;
   boolean show_usage=(cmdline=='');
   while (cmdline!='') {
      parse strip(cmdline) with word cmdline;
      switch (upcase(strip(word))) {
      case 'ON':
         def_renumber_flags|=VSRENUMBER_AUTO;
         break;
      case 'OFF':
         def_renumber_flags&=~VSRENUMBER_AUTO;
         break;
      default:
         show_usage=true;
         break;
      }
   }
   if (show_usage) {
      def_renumber_flags=orig_renumber_flags;
      _message_box("Usage: AUTONUM [ON|OFF]");
      return;
   }
   if (def_renumber_flags != orig_renumber_flags) {
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
}
#endif
/**
 * Turns off numbering mode.  This command is  to "NUMBER OFF".
 * 
 * @see ispf_number
 * 
 * @categories ISPF_Primary_Commands
 */
_command void ispf_nonumber() name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   ispf_number("OFF");
}
/**
 * parse line numbering options and renumber lines if needed
 *
 * @param renumber_flags original settings for numbering flags
 *
 * @return the new flags, <0 on error or if usage is shown
 */
static int parse_number_options(_str cmdline, int renumber_flags, boolean off_cmds=true)
{
   // parse through the arguments
   boolean saw_std_or_cobol=false;
   boolean show_usage=(cmdline=='');
   while (cmdline!='') {
      _str word="";
      parse strip(cmdline) with word cmdline;
      switch (upcase(strip(word))) {
      case 'ON':
         if (!saw_std_or_cobol) {
            renumber_flags&=~VSRENUMBER_COBOL;
            renumber_flags&=~VSRENUMBER_STD;
            if (_LanguageInheritsFrom('cob')) {
               renumber_flags|=VSRENUMBER_COBOL;
            } else {
               renumber_flags|=VSRENUMBER_STD;
            }
         }
         break;
      case 'OFF':
         if (!off_cmds) {
            show_usage=true;
         }
         renumber_flags=0;
         break;
      case 'STD':
      case 'STANDARD':
         renumber_flags|=VSRENUMBER_STD;
         if (!saw_std_or_cobol) {
            renumber_flags&=~VSRENUMBER_COBOL;
            saw_std_or_cobol=true;
         }
         break;
      case 'NOSTD':
      case 'NOSTANDARD':
         if (!off_cmds) {
            show_usage=true;
         }
         renumber_flags&=~VSRENUMBER_STD;
         break;
      case 'COB':
      case 'COBOL':
         renumber_flags|=VSRENUMBER_COBOL;
         if (!saw_std_or_cobol) {
            renumber_flags&=~VSRENUMBER_STD;
            saw_std_or_cobol=true;
         }
         break;
      case 'NOCOB':
      case 'NOCOBOL':
         if (!off_cmds) {
            show_usage=true;
         }
         renumber_flags&=~VSRENUMBER_COBOL;
         break;
      case 'DISPLAY':  // not supported
      case 'DISP':     // not supported
         break;
      default:
         show_usage=true;
         break;
      }
   }
   if (show_usage) {
      return -1;
   }
   return renumber_flags;
}
/**
 * The number command controls line numbering mode and lets you immediately 
 * renumber the line numbers in a file.  Unlike ISPF, this command does effect 
 * how lines are inserted.  However the number command can still be used to 
 * renumber the entire buffer on demand.
 * 
 * <p>Syntax:<pre>
 *    NUMBER [ ON | OFF ] [ STD | NOSTD ] [ COBOL | NOCOBOL ]
 * </pre>
 * 
 * Arguments:
 * <dl compact style="margin-left:20pt">
 * <dt>ON<dd style="margin-left:80pt">Turn on line numbering mode and renumber buffer.  Unless 
 *   also specified, this implies that the standard sequence columns will be numbered, or if in 
 *   COBOL mode, the cobol sequence numbers will be renumbered.
 * <dt>OFF<dd style="margin-left:80pt">Turn off line numbering mode.
 * <dt>STD or STANDARD<dd style="margin-left:80pt">Line numbers are in the standard sequence 
 *    columns (73-80).
 * <dt>NOSTD<dd style="margin-left:80pt">Do not number the standard sequence columns.
 * <dt>COB<dd style="margin-left:80pt">or cobol Line numbers are as in COBOL, columns 1-6.
 * <dt>NOCOBOL<dd style="margin-left:80pt">Do not number the COBOL line numbers.
 * </dl>
 * 
 * Note:  Make sure that the line number columns (1-6 for COBOL or 73-80) do not 
 * have data in them before renumbering the file.  Otherwise, data may be
 * overwritten with line numbers.  Normally, this is detectable and you will 
 * be warned that data was overwritten, but if the data was numeric, you will 
 * not be warned.
 * 
 * @see ispf_nonumber
 * @see ispf_renumber
 * @see ispf_unnumber
 * 
 * @categories ISPF_Primary_Commands
 */
_command void ispf_number,ispf_num(_str arglist="") name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   // parse through the arguments
   int renumber_flags=numbering_options();
   int orig_renumber_flags=renumber_flags;
   renumber_flags = parse_number_options(arglist,renumber_flags);
   if (renumber_flags < 0) {
      _message_box("Usage: NUMBER [ON|OFF] [STD|NOSTD] [COBOL|NOCOBOL]");
      return;
   }
   if (renumber_flags != orig_renumber_flags) {
      numbering_options(renumber_flags,VSRENUMBER_ALL);
   }
   if (renumber_flags & VSRENUMBER_STD) {
      renumber_lines(73,80,'0');
   }
   if (renumber_flags & VSRENUMBER_COBOL) {
      renumber_lines(1,6,'0');
   }
}
/**
 * The renumber command immediately updates the line numbers in a file.
 * 
 * <p>Syntax:<pre>
 *    RENUMBER [ ON ] [ STD ] [ COBOL ]
 * </pre>
 * 
 * <dl compact style="margin-left:20pt">
 * <dt>ON<dd style="margin-left:95pt">Renumber lines as configured for the current file type.
 * <dt>STD or STANDARD<dd style="margin-left:95pt">Line numbers are in the standard sequence columns (73-80).
 * <dt>COB or COBOL<dd style="margin-left:95pt">Line numbers are as in COBOL, columns 1-6.
 * </dl>
 * 
 * Note:  Make sure that the line number columns (1-6 for COBOL or 73-80) do not have data in them before renumbering the file.  Otherwise, data may be overwritten with line numbers.  Normally, this is detectable and you will be warned that data was overwritten, but if the data was numeric, you will not be warned.
 * 
 * @see ispf_nonumber
 * @see ispf_number
 * @see ispf_unnumber
 * 
 * @categories ISPF_Primary_Commands
 */
_command void ispf_renumber,ispf_renum(_str arglist="") name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   if (arglist=='') {
      renumber();
      return;
   }
   int renumber_flags = parse_number_options(arglist,0,false);
   if (renumber_flags < 0) {
      _message_box("Usage: RENUMBER [ON] [STD] [COBOL]");
      return;
   }
   if (renumber_flags & VSRENUMBER_STD) {
      renumber_lines(73,80,'0');
   }
   if (renumber_flags & VSRENUMBER_COBOL) {
      renumber_lines(1,6,'0');
   }
}

/**
 * The unnumber command immediately blanks out the line numbers in a file.
 * 
 * 
 * <p>Syntax:<pre>
 *    UNNUMBER  [ STD ] [ COBOL ]
 * </pre>
 * 
 * Arguments:
 * <dl compact style="margin-left:20pt">
 * <dt>STD or STANDARD<dd style="margin-left:90pt">Line numbers are in the standard sequence columns (73-80).
 * <dt>COB or COBOL<dd style="margin-left:90pt">Line numbers are as in COBOL, columns 1-6.
 * </dl>
 * 
 * Note:  Make sure that the line number columns (1-6 for COBOL or 73-80) do not 
 * have data in them before unnumbering the buffer.  Otherwise, data may be 
 * overwritten with line numbers.  Normally, this is detectable and you will 
 * be warned that data was overwritten, but if the data was numeric, you may 
 * not be warned.
 * 
 * @see ispf_nonumber
 * @see ispf_number
 * @see ispf_renumber
 * 
 * @categories ISPF_Primary_Commands
 */
_command void ispf_unnum,ispf_unnumber(_str arglist="") name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   int renumber_flags = parse_number_options(arglist,0,false);
   if (renumber_flags < 0) {
      _message_box("Usage: UNNUMBER [STD] [COBOL]");
      return;
   }
   if (renumber_flags & VSRENUMBER_STD) {
      renumber_lines(73,80,'0',true);
   }
   if (renumber_flags & VSRENUMBER_COBOL) {
      renumber_lines(1,6,'0',true);
   }
}
/**
 * Cut lines out of the current buffer and place them in the specified clipboard.
 * 
 * <p>Sytnax:<pre>
 *    CUT [ <i>line_range</i> ] [DEFAULT | <i>clipboardname</i> ] [REPLACE] [DISPLAY]
 * </pre>
 * 
 * <dl compact style="margin-left:20pt">
 * <dt><i>line_range</i><dd style="margin-left:90pt">Two numbers or labels, specifying the starting and ending lines to cut to the clipboard.
 * <dt><i>clipboardname</i><dd style="margin-left:90pt">Place the result on the named clipboard.
 * <dt>DEFAULT<dd style="margin-left:90pt">Place the result on the default clipboard.
 * <dt>REPLACE<dd style="margin-left:90pt">Replace the contents of the given clipboard or append to the end of the clipboard.
 * <dt>DISPLAY<dd style="margin-left:90pt">Display list of clipboards.
 * </dl>
 *        
 * @categories ISPF_Primary_Commands
 * @see ispf_paste
 * @see list_clipboards
 * @see cut
 */
_command void ispf_cut(_str arglist="") name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   // parse through the arguments
   int startLine=-1;
   int endLine=-1;
   boolean copy_option=false;
   boolean replace_clipboard=false;
   _str clipboard_name='';
   _str cmdline=strip(arglist);
   boolean show_usage=false;
   while (cmdline!='') {
      _str word="";
      parse strip(cmdline) with word cmdline;
      switch (upcase(strip(word))) {
      case 'DISPLAY':
         list_clipboards();
         return;
      case 'REPLACE':
         replace_clipboard=true;
         break;
      case 'APPEND':
         replace_clipboard=false;
         break;
      case 'DEFAULT':
         clipboard_name='';
         break;
      default:
         if (startLine<0 && (substr(word,1,1)==ISPF_LABEL_PREFIX || isinteger(word))) {
            // it is a label or line number
            if (ispf_parse_range(word,cmdline,startLine,endLine) < 0) {
               return;
            }
         } else if (clipboard_name=='') {
            // not a label or line number, must be named clipboard
            clipboard_name=word;
         } else {
            show_usage=true;
         }
      }
   }

   // no label range given, look for 'C' or 'M' line commands
   if (startLine<0) {
      boolean isCopy=false;
      if (ispf_find_move_copy(startLine,endLine,isCopy) < 0) {
         show_usage=true;
      } else if (isCopy) {
         copy_option=true;
      }
   }

   if (show_usage) {
      _message_box("Usage: CUT [range] [DEFAULT] [REPLACE | APPEND] [DISPLAY]");
      return;
   }

   // allocate a selection
   int mark_id=_alloc_selection();
   if (mark_id<0){
      message(get_message(mark_id));
      return;
   }
   // select the block of lines
   if (startLine==0) startLine=1;
   typeless p;
   _save_pos2(p);
   p_line=startLine;
   _select_line(mark_id,'C');
   p_line=endLine;
   _show_selection(mark_id);

   // and cut them to the clipboard
   cut(replace_clipboard,copy_option,clipboard_name);
   _restore_pos2(p);
}
/**
 * The paste command copies lines from the clipboard to the specified position 
 * in the buffer, or the current line.
 * 
 * <p>Syntax:<pre>
 *    PASTE [ <i>clipboardname</i> ] [ AFTER <i>label</i> ] [BEFORE <i>label</i> ] [KEEP]
 * </pre>
 * 
 * Arguments:
 * <dl compact style="margin-left:20pt">
 * <dt>AFTER <i>label</i><dd style="margin-left:80pt">The destination for the data being pasted.  The label may be either an ISPF label or a line number.  The data will be inserted after the specified line.
 * <dt>BEFORE <i>label</i><dd style="margin-left:80pt">The destination for the data being pasted.  The label may be either an ISPF label or a line number.  The data will be inserted after the specified line.
 * <dt>KEEP<dd style="margin-left:80pt">Do not clear out the clipboard after doing a paste operation.
 * </dl>
 * 
 * <p>If neither AFTER nor BEFORE is specified, the default location to insert the 
 * data is after the current line (cursor position).  However, if there is an A or 
 * B line command in the prefix area, the data will be inserted at that point.
 * 
 * @see ispf_cut
 * @see list_clipboards
 * @see paste
 * @see help:ISPF Line Command A
 * 
 * @categories ISPF_Primary_Commands
 */
_command void ispf_paste(_str arglist="") name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   // parse through the arguments
   int pasteLine=-1;
   _str insert_style='A';
   boolean keep_clipboard=false;
   _str clipboard_name='';
   _str cmdline=strip(arglist);
   boolean show_usage=false;
   while (cmdline!='') {
      _str word="";
      parse strip(cmdline) with word cmdline;
      switch (upcase(strip(word))) {
      case 'KEEP':
         keep_clipboard=true;
         break;
      case 'BEFORE':
         insert_style='B';
         // drop through
      case 'AFTER':
         parse strip(cmdline) with word cmdline;
         pasteLine = ispf_parse_label(word);
         if (pasteLine<0) {
            return;
         }
         break;
      case 'DEFAULT':
         clipboard_name='';
         break;
      default:
         clipboard_name=word;
         break;
      }
   }

   if (pasteLine<0) {
      pasteLine=p_line;
   }
   if (show_usage || pasteLine<0) {
      _message_box("Usage: PASTE [clipboardname] [AFTER label] [BEFORE label] [KEEP]");
      return;
   }

   // paste the clipboard at the specified line
   typeless p;
   _save_pos2(p);
   p_line=pasteLine;
   _str orig_line_insert=def_line_insert;
   def_line_insert=insert_style;
   paste(clipboard_name);
   def_line_insert=orig_line_insert;

   // remove the clipboard contents
   if (!keep_clipboard) {
      // need to have a function for clearing out clipboard contents
      // this is not exactly right, since it leaves an extra blank line
      typeless status=push_clipboard_itype('LINE',clipboard_name);
      if ( ! status ) {
         append_clipboard_text('');
      }
   }
   _restore_pos2(p);
}
/**
 * The preserve command controls enabling or disabling the saving of trailing blanks 
 * in the editor.  Turning on this option is identical to turning off the file save 
 * option "Strip trailing spaces" in the global or
 * language-specific file options.
 * 
 * @categories ISPF_Primary_Commands
 */
_command void ispf_preserve(_str arglist="") name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   // parse through the arguments
   _str prefix="";
   _str suffix="";
   _str cmdline=upcase(strip(arglist));
   if (cmdline=='OFF' && pos('-S',def_save_options)) {
      parse def_save_options with prefix "-S" suffix;
      def_save_options=prefix"+S"suffix;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   } else if (cmdline=='ON' && pos('+S',def_save_options)) {
      parse def_save_options with prefix "+S" suffix;
      def_save_options=prefix"-S"suffix;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   } else {
      _message_box("Usage: PRESERVE [ON | OFF]");
      return;
   }
}
/**
 * This command is used to set or reset the left and right 
 * edit boundaries in ISPF emulation.  The <i>left_col</i> and 
 * <i>right_col</i> must be integers, or an asterisk may be used 
 * in either one's place to specify the current setting.  
 * <i>right_col</i> defaults to <i>left_col</i> if not specified.
 * 
 * @param cmdline Synax of </i>cmdline</i>:
 * 
 * <pre>
 *    <i>left_col</i> [<i>right_col</i>]
 * </pre>
 * 
 * @see ispf_change
 * @see ispf_find
 * @see ispf_exclude
 * @see help:ISPF Line Commands
 * 
 * @categories ISPF_Primary_Commands
 */
_command void ispf_bounds,ispf_bnds(_str cmdline='') name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   if (isEclipsePlugin()) {
     eclipse_show_disabled_msg("ispf_bnds");
     return;
   }
   _str cmdname="";
   if (cmdline=='') {
      if (def_keys=='ispf-keys') {
         cmdname='bounds';
      } else {
         cmdname='ispf-bounds';
      }
      if (p_BoundsStart>0) {
         command_put(cmdname' 'p_BoundsStart' 'p_BoundsEnd);
      } else {
         command_put(cmdname' ');
      }
      return;
   }
   if (cmdline=='0') {
      p_BoundsStart=0;
      p_BoundsEnd=0;
      ispf_adjust_lc_bounds();
      return;

   }
   typeless boundsStart="";
   typeless boundsEnd="";
   parse cmdline with boundsStart boundsEnd .;
   if (boundsStart=='*') boundsStart=p_BoundsStart;
   if (boundsEnd=='*') boundsEnd=p_BoundsEnd;
   if (boundsEnd=='') boundsEnd=boundsStart;
   if (!isinteger(boundsStart) || !isinteger(boundsEnd) ||
       boundsStart<=0 || boundsEnd<=0 ||
       boundsStart>boundsEnd) {
      _message_box(get_message(INVALID_ARGUMENT_RC));
      return;
   }
   p_BoundsStart=boundsStart;
   p_BoundsEnd=boundsEnd;
   ispf_adjust_lc_bounds();
}
/**
 * Resets the line prefix area for specific types of lines or all lines in the 
 * buffer.
 * 
 * <p>Syntax:<pre>
 *    RESET [ ALL | CHANGE | COMMAND | ERROR | EXCLUDED | 
 *            FIND | LABEL | SPECIAL ] [ <i>line_range</i> ]
 * </pre>
 * 
 * <dl compact style="margin-left:20pt">
 * <dt>ALL<dd style="margin-left:95pt">Reset all line prefixes.  This is the default.
 * <dt>CHANGE<dd style="margin-left:95pt">Search for lines with a change flag (==CHG>).
 * <dt>COMMAND<dd style="margin-left:95pt">Search for lines containing an edit line command.
 * <dt>ERROR<dd style="margin-left:95pt">Search for lines with an error flag (==ERR>).
 * <dt>EXCLUDED<dd style="margin-left:95pt">Search only for excluded lines.
 * <dt>LABEL<dd style="margin-left:95pt">Search for lines with a label.
 * <dt>SPECIAL<dd style="margin-left:95pt">Search for lines with special non-data lines, (e.g. =COLS>)
 * <dt><i>line_range</i><dd style="margin-left:95pt"> Two numbers or labels, specifying the start and end
 * </dl>
 * 
 * @see ispf_do_lc
 * @see ispf_locate
 * @see help:ISPF Line Commands
 * 
 * @categories ISPF_Primary_Commands
 */
_command void ispf_reset,ispf_res(_str cmdline="") name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   // parse through the arguments
   boolean reset_change=false;
   boolean reset_command=false;
   boolean reset_error=false;
   boolean reset_excluded=false;
   boolean reset_find=false;
   boolean reset_label=false;
   boolean reset_special=false;
   boolean reset_seldisp=false;
   int startLine=-1;
   int endLine=-1;

   boolean show_usage=false;
   boolean category_found=false;
   while (cmdline!='') {
      _str word="";
      parse strip(cmdline) with word cmdline;
      switch (upcase(strip(word))) {
      case 'ALL':
         category_found=true;
         reset_change=true;
         reset_command=true;
         reset_error=true;
         reset_excluded=true;
         reset_find=true;
         reset_label=true;
         reset_special=true;
         reset_seldisp=true;
         break;
      case 'CHG':
      case 'CHANGE':
         category_found=true;
         reset_change=true;
         break;
      case 'COM':
      case 'CMD':
      case 'COMM':
      case 'COMMAND':
         category_found=true;
         reset_command=true;
         break;
      case 'ERR':
      case 'ERROR':
         category_found=true;
         reset_error=true;
         break;
      case 'EX':
      case 'EXCL':
      case 'EXCLUDE':
      case 'EXCLUDED':
         category_found=true;
         reset_excluded=true;
         break;
      case 'SELDISP':
         category_found=true;
         reset_seldisp=true;
         break;
      case 'FIND':
         category_found=true;
         reset_find=true;
         break;
      case 'LAB':
      case 'LABEL':
      case 'LABELS':
         category_found=true;
         reset_label=true;
         break;
      case 'SPECIAL':
         category_found=true;
         reset_special=true;
         break;
      default:
         if (ispf_parse_range(word,cmdline,startLine,endLine) < 0) {
            show_usage=true;
            break;
         }
         break;
      }
   }
   if (!category_found) {
      reset_change=true;
      reset_command=true;
      reset_error=true;
      reset_excluded=true;
      reset_special=true;
   }
   if (show_usage) {
      _message_box("Usage: RESET [ALL] [CHANGE] [COMMAND] [ERROR] [FIND]\n":+
                   "\t[EXCLUDED] [SELDISP] [LABEL] [SPECIAL] [range]");
      return;
   }

   // don't do this in diff mode
   if (_isdiffed(p_buf_id)) {
      return;
   }

   // save/restore buffer position
   if (startLine < 0) {
      startLine=1;
      endLine=p_Noflines;
   }
   int old_ModifyFlags=p_ModifyFlags;
   typeless p;
   _save_pos2(p);

   // turn off highlighting of search results
   if (reset_find && def_leave_selected) {
      def_leave_selected=0;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }

   // reset selective display, this is done for whole buffer
   if (reset_seldisp && (p_Nofhidden || p_NofSelDispBitmaps)) {
      top();
      up();
      for (;;) {
         int num_excluded=ispf_is_excluded_line();
         if (num_excluded>0) {
            down(num_excluded);
         } else {
            _lineflags(0,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF|LEVEL_LF);
         }
         if ( down()) break;
      }
   }

   // reset no-save lines, such as cols, bnds, or exclude lines
   int i=0;
   if (reset_excluded && p_NofNoSave) {
      int num_exposed=0;
      for (i=endLine; i>=startLine; --i) {
         p_line=i;
         int num_excluded=ispf_is_excluded_line();
         if (num_excluded > 0) {
            if (i+num_excluded > endLine) {
               num_excluded=endLine-i;
            }
            ispf_expose_lines(i,i+num_excluded,num_excluded,'F');
            num_exposed=0;
         } else if (_lineflags() & HIDDEN_LF) {
            _lineflags(0,HIDDEN_LF);
            ++num_exposed;
         }
      }
      for (i=endLine; i>=startLine; --i) {
         p_line=i;
         if (_lineflags() & PLUSBITMAP_LF) {
            plusminus();
            plusminus();
         }
      }
      for (i=startLine-1; i>0; --i) {
         p_line=i;
         if (ispf_is_excluded_line()) {
            ispf_insert_exclude(startLine-i,true);
            break;
         } else if (!(_lineflags() & HIDDEN_LF)) {
            break;
         }
      }
      for (i=endLine+1;;++i) {
         p_line=i;
         if (p_line!=i) break;
         if (!(_lineflags() & HIDDEN_LF)) {
            p_line=i;
            if (i > endLine+1) {
               --p_line;
               ispf_insert_exclude(i-endLine);
            }
            break;
         }
      }
   }

   // search through rest of line commands
   for (i=0; i<_LCQNofLineCommands(); ++i) {
      _str lc_str, lc_arg; int lc_val;
      _str line_command = strip(_LCQDataAtIndex(i));
      int  line_number  = _LCQLineNumberAtIndex(i);
      int  line_flags   = _LCQFlagsAtIndex(i);
      p_line=line_number;

      if (line_number>=startLine && line_number<=endLine) {

         // remove the <CHG flag
         if (reset_change && (line_flags & VSLCFLAG_CHANGE)) {
            _LCSetFlagsAtIndex(i,0,VSLCFLAG_CHANGE);
            --i;
            continue;
         }
         // reset the line command contents
         if (reset_command && line_command:!='') {
            _LCSetDataAtIndex(i,'');
            --i;
            continue;
         }
         // remove the <ERR flag
         if (reset_error && (line_flags & VSLCFLAG_ERROR)) {
            _LCSetFlagsAtIndex(i,0,VSLCFLAG_ERROR);
            --i;
            continue;
         }
         // blow away labels
         if (reset_label && substr(line_command,1,1)==ISPF_LABEL_PREFIX) {
            _LCSetDataAtIndex(i,'');
            --i;
            continue;
         }
         // blow away any other items
         if (reset_special && (line_flags&(VSLCFLAG_BOUNDS|VSLCFLAG_COLS|VSLCFLAG_MASK|VSLCFLAG_TABS))) {
            if (_lineflags() & NOSAVE_LF) {
               nomod_delete_line();
               --endLine;
               --i;
            } else {
               _LCSetFlagsAtIndex(i,0,VSLCFLAG_BOUNDS|VSLCFLAG_COLS|VSLCFLAG_MASK|VSLCFLAG_TABS);
            }
         }
      }
   }

   // restore buffer position
   _restore_pos2(p);
   p_ModifyFlags=old_ModifyFlags;
}
