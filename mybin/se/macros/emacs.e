////////////////////////////////////////////////////////////////////////////////////
// $Revision: 48612 $
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
#import "c.e"
#import "clipbd.e"
#import "complete.e"
#import "dir.e"
#import "files.e"
#import "get.e"
#import "guiopen.e"
#import "markfilt.e"
#import "pmatch.e"
#import "main.e"
#import "math.e"
#import "proctree.e"
#import "pushtag.e"
#import "recmacro.e"
#import "search.e"
#import "seek.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "tbfind.e"
#import "util.e"
#import "window.e"
#endregion

/**
 * Used in EMACS emulation.  If the cursor is before the first non-blank 
 * character of the current line and the previous line is indented with more 
 * tabs and/or spaces than the current line, the current lines is indented to 
 * align with the previous line.  Otherwise, a tab character is inserted at the 
 * cursor position.  This command always inserts a tab character when the 
 * command line is active.
 * 
 * @see indent_region
 * @see indent_rigidly
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */
_command indent_previous() name_info(','VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   if ( command_state() || _on_line0() ) {
      return(move_text_tab());
   }
   int inon_blank_col=_first_non_blank_col();
   if ( inon_blank_col<p_col ) {
      return(move_text_tab());
   }
   up();
   int iprev_non_blank_col=0;
   _str prev_indent='';
   if ( p_buf_width && _on_line0() ) {
      iprev_non_blank_col=1;
      prev_indent='';
   } else {
      iprev_non_blank_col=_first_non_blank_col();
      save_pos(auto p);
      _begin_line();
      prev_indent=get_text(_text_colc(iprev_non_blank_col,'p')-1);
      restore_pos(p);
   }
   down();
   if ( iprev_non_blank_col<=p_col ) {
      return(move_text_tab());
   }
   _begin_line();
   _delete_text(inon_blank_col-1,'C');
   _insert_text(prev_indent);
}

/**
 * Used in EMACS emulation.
 * 
 * When called without an arguent, calls <b>page_down</b>
 * 
 * Moves the lines of the current buffer one line up. The cursor is moved one
 * screen row up if the cursor is not on the top row of the window.
 * 
 * @see emacs_scroll_down
 * @see scroll_up
 * @see scroll_down
 * @see scroll_left
 * @see scroll_right
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command emacs_scroll_up() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if ( _argument=='' ) {
      return(page_down());
   }
   if ( p_cursor_y==0 ) {
      down();
   }
   set_scroll_pos(p_left_edge,p_cursor_y-1);
}
/**
 * Used in EMACS emulation.
 * 
 * When called without an argument, calls <b>page_up</b>
 * 
 * Moves the lines of the current buffer one line down.  The cursor is 
 * moved one screen row down if the cursor is not on the bottom row of 
 * the window.
 * 
 * @see emacs_scroll_up
 * @see scroll_up
 * @see scroll_down
 * @see scroll_left
 * @see scroll_right
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command emacs_scroll_down() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if ( _argument=='' ) {
      return(page_up());
   }
   if ( p_cursor_y intdiv p_font_height==p_char_height-1 ) {
      up();
   }
   set_scroll_pos(p_left_edge,p_cursor_y+p_font_height);
}
/**
 * Used in EMACS emulation.  Toggles the buffer modified flag 
 * (<b>p_modify</b> property) which indicates whether the current buffer has 
 * been modified.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */
_command modify_toggle() name_info(','VSARG2_REQUIRES_MDI_EDITORCTL)
{
   p_modify= (!p_modify);
}

/**
 * Poke around matching blocks until we can find the left or right
 * boundary of the current word match. 
 * 
 * @param direction     like search options, 
 *                      '-' for backwards, '' for forward
 * @param origOffset    offset to start searching from
 * @param matchOffset   offset we expect find-matching-paren to go to
 * 
 * @return Returns the offset of the left or right boundary of the word match. 
 */
static long findMatchingWordBoundary(_str direction, long origOffset, long matchOffset)
{
   // go to the original offset
   _GoToROffset(origOffset);
   wordOffset := origOffset;
   origColor  := _clex_find(0, 'g');

   loop {
      // move the cursor by one character
      status := traverse_char(direction);
      if ( status ) break;

      // if we landed on a space, skip blanks
      if (pos(get_text(), " \t\n\r\v")) {
         status =_clex_skip_blanks(direction'hc');
         if ( status ) break;
      }

      // landed on an identifer character, jump to the beginning of word
      if ( isalnum(get_text()) ) {
         if ( direction=='-' ) {
            _begin_identifier();
         } else {
            _end_identifier();
         }
      }

      // do not try matching parens within a string or comment
      // unless we started in one 
      cfg := _clex_find(0, 'g');
      if ( cfg != origColor && (cfg==CFG_STRING || cfg==CFG_COMMENT)) continue;

      // find the match from this position
      save_pos(auto p1);
      status = _find_matching_paren(def_pmatch_max_diff,true);
      if ( status ) break;

      // check if it goes to the same place, otherwise stop
      if ( _QROffset() != matchOffset ) break;

      // ok, back to where we started and try again
      restore_pos(p1);
      wordOffset = _QROffset();
   }

   return wordOffset;
}

/**
 * Check if the symbol under the cursor is a language specific
 * match word, such as begin/end in Pascal, #if/#endif in C, or
 * HTML start and end tags.
 * 
 * @param direction  like search options, 
 *                   '-' for backwards, '' for forward
 * 
 * @return 'true' if the item under the cursor has a matching 
 *         pair, as defined by {@link find_matching_paren}. 
 */
static boolean isMatchingWord(_str direction, _str &matchWord,
                              long *wordStartOffset=null, long *wordEndOffset=null,
                              long *otherWordOffset=null, long *otherEndOffset=null)
{
   // save cursor position and search parameters
   origOffset := _QROffset();
   save_pos(auto p);
   save_search(auto s1,auto s2 ,auto s3,auto s4,auto s5);

   // use the paren matching function to test if we are on a start word 
   status := _find_matching_paren(def_pmatch_max_diff,true);
   if ( status ) {
      restore_pos(p);
      restore_search(s1,s2,s3,s4,s5);
      return false;
   }

   // get the offset we found the match at and check if it matches
   // the direction we are going.  If the direction doesn't match,
   // the do not consider it as a match 
   matchOffset := _QROffset();
   isMatchWord := ( matchOffset > origOffset && direction != '-' ) ||
                  ( matchOffset < origOffset && direction == '-' );
   if ( !isMatchWord ) {
      restore_pos(p);
      restore_search(s1,s2,s3,s4,s5);
      return false;
   }

   // the match could be a cycle including several things
   // for our purposes we only are interested in the lowest
   // and highest positions in the cycle.
   boolean parenStops:[];
   parenStops:[origOffset] = true;
   parenStops:[matchOffset] = true;
   lowestOffset  := (matchOffset < origOffset)? matchOffset : origOffset;
   highestOffset := (matchOffset > origOffset)? matchOffset : origOffset;
   for ( count := 0; count < def_pmatch_max_diff/100; ++count ) {
      // find another match
      status = _find_matching_paren(def_pmatch_max_diff,true);
      if ( status ) break;

      // check if we have already seen this match
      thisOffset := _QROffset();
      if ( parenStops._indexin(thisOffset) ) {
         break;
      }
      parenStops:[thisOffset] = true;

      // update highest and lowest offsets
      if ( thisOffset < lowestOffset ) {
         lowestOffset = thisOffset;
      }
      if ( thisOffset > highestOffset ) {
         highestOffset = thisOffset;
      }
   }

   // now we poke around and try to find the beginning of the match word
   restore_pos(p);
   origColor := _clex_find(0, 'g');
   if ( wordStartOffset != null ) {
      *wordStartOffset = findMatchingWordBoundary('-', origOffset, matchOffset);
   }

   // do the same technique to find the end of the match word
   if ( wordEndOffset != null ) {
      *wordEndOffset = findMatchingWordBoundary('', origOffset, matchOffset);
   }

   // check if the word boundaries encompass the entire match group
   // if so, do not consider it as a match group
   if ( wordStartOffset != null && wordEndOffset != null ) {
      if ( *wordStartOffset <= lowestOffset && highestOffset <= *wordEndOffset ) {
         isMatchWord = false;
      }
   }
   
   // determine the position to navigate to from here
   if ( otherWordOffset != null ) {
      *otherWordOffset = (direction=='-')? lowestOffset:highestOffset;
   }

   // get the matching word
   if ( wordEndOffset != null && wordStartOffset != null ) {
      matchWord = get_text((int)((*wordEndOffset)-(*wordStartOffset)+1), (int)(*wordStartOffset));
   } else {
      matchWord = _SymbolWord();
      if ( matchWord == '' ) {
         matchWord = get_text(1, (int)origOffset);
      }
   }

   // now find the end of the matching word
   if ( isMatchWord && otherWordOffset != null && otherEndOffset != null ) {
      // start from the the offset of the matching word and
      // calculate the offset we jump to coming back from the end offset
      _GoToROffset(*otherWordOffset);
      _find_matching_paren(def_pmatch_max_diff,true);
      *otherEndOffset = findMatchingWordBoundary('', *otherWordOffset, _QROffset());
   }

   // that's all, restore position and return result
   restore_pos(p);
   restore_search(s1,s2,s3,s4,s5);
   return isMatchWord;
}

/**
 * Moves forward or backward over the S-expression starting at the 
 * cursor position. 
 *  
 * @param direction  like search options, 
 *                   '-' for backwards, '' for forward
 *  
 * @return Returns 0 if successful, <0 on error.
 * 
 * @see next_sexp 
 * @see prev_sexp 
 */
static int do_next_prev_sexp(_str direction)
{
   // set up search excludes so we can traverse through
   // words in strings and comments if we started in them.
   comment_option := '';
   excludes := "Xcs";
   if ( _clex_find(0, 'g') == CFG_COMMENT ) {
      excludes = "Xs";
      comment_option='c';
   } else if ( _clex_find(0, 'g') == CFG_STRING ) {
      excludes = "Xc";
   }

   // save search options to restore later
   status := 0;
   save_search(auto s1,auto s2 ,auto s3,auto s4,auto s5);

   // brace block to allow for common finish/cleanup code
   do {
      // are we on an open or close paren, bracket, or brace?
      // also check for language specific word pairs and block matching
      ch := get_text();
      matchWord := '';
      long wordStartOffset=0, wordEndOffset=0, otherWordOffset=0, otherEndOffset=0;
      isStart := (ch:=='(' || ch:=='[' || ch:=='{');
      if ( !isStart ) {
         isStart = isMatchingWord('',matchWord,&wordStartOffset,&wordEndOffset,&otherWordOffset,&otherEndOffset);
      }
      isClose := (ch:==')' || ch:==']' || ch:=='}');
      if ( !isStart && !isClose ) {
         isClose =  isMatchingWord('-',matchWord,&wordStartOffset,&wordEndOffset,&otherWordOffset,&otherEndOffset);
      }
      if ( isStart || isClose ) {
         // conditions for skipping paren block:
         //    1) close char and direction is backward
         //    2) start char and direction is forward 
         if ( isClose == (direction=='-') ) {
            if ( matchWord != '' ) {
               if ( direction=='-' ) {
                  _GoToROffset(otherWordOffset);
               } else {
                  _GoToROffset(otherEndOffset);
               }
            } else {
               status = _find_matching_paren(def_pmatch_max_diff,true);
               if ( status < 0 ) break;
            }
            if ( isClose ) {
               break;
            }
         } else if ( isStart && direction == '-' &&  matchWord != '' ) {
            _GoToROffset(wordStartOffset);
         } else if ( isClose && direction != '-' &&  matchWord != '' ) {
            _GoToROffset(wordEndOffset);
         }
         status = traverse_char(direction);
         if ( status < 0 ) break;

      } else if ( ch:==';' || ch:==',' ) {
         // semicolon or comma delimeter, move past it and skip spaces
         status = traverse_char(direction);
         if ( status < 0 ) break;
         //status = search('[ \t\n\r,;\(\{\[\]\}\)]', '@'direction'rh'excludes);
         //if ( status < 0 ) break;
      } else if ( pos(ch, " \t\n\r\v") > 0 ) {
         // spaces, skip them (see below)
      } else {
         // any other character, search for a significant starting point
         status = search('\om[ \t\n\r,;\(\{\[\]\}\)]', '@'direction'rh'excludes);
         if ( status < 0 ) break;
      }

      // in case if our first moves landed on spaces, skip them now
      status = _clex_skip_blanks(direction'h'comment_option);
      if ( status < 0 ) break;
   
      // are we on an open or close paren, bracket, or brace?
      ch = get_text();
      matchWord = '';
      isStart = (ch:=='(' || ch:=='[' || ch:=='{');
      if ( !isStart ) {
         isStart = isMatchingWord('', matchWord,&wordStartOffset,null/*&wordEndOffset*/,&otherWordOffset,&otherEndOffset); 
      }
      isClose = (ch:==')' || ch:==']' || ch:=='}');
      if ( !isStart && !isClose ) {
         isClose =  isMatchingWord('-',matchWord,&wordStartOffset,null/*&wordEndOffset*/,&otherWordOffset,&otherEndOffset);
      }
      if ( isStart || isClose ) {
         // if direction is backward and we landed on a 
         // close paren, bracket, or brace, then skip to the open
         if ( isClose && direction=='-' ) {
            if ( matchWord != '' ) {
               if ( direction=='-' ) {
                  _GoToROffset(otherWordOffset);
               } else {
                  _GoToROffset(otherEndOffset);
               }
            } else {
               status = _find_matching_paren(def_pmatch_max_diff,true);
               if ( status < 0 ) break;
            }
         } else if ( isStart && direction=='-' && matchWord != '' ) {
            // move to the start of the match, if we have one
            _GoToROffset(wordStartOffset);
         }
      } else if ( ch:==';' || ch:==',' ) {
         // do nothing, always stop at these delimeters
      } else {
         // if direction is backward, then move to the start of the
         // previous item, the cursor is current at then end of it
         if ( direction=='-' ) {
            status = search('\om[ \t\n\r,;\(\{\[\]\}\)]', '@'direction'rh'excludes);
            if ( status < 0 ) break;
            status = traverse_char('');
            if ( status < 0 ) break;
         }
      }
   } while (false);

   // restore search options and we are done
   restore_search(s1,s2,s3,s4,s5);
   return status;
}

/**
 * Moves up into the parent S-expression starting from the cursor
 * position.  
 *  
 * @param direction  like search options, 
 *                   '-' for backwards, '' for forward
 *  
 * @return Returns 0 if successful, <0 on error.
 * 
 * @see forward_up_sexp
 * @see backward_up_sexp
 */
static int do_up_sexp(_str direction='')
{
   // set up search excludes so we can traverse through
   // words in strings and comments if we started in them.
   excludes := "Xcs";
   comment_option := '';
   if ( _clex_find(0, 'g') == CFG_COMMENT ) {
      excludes = "Xs";
      comment_option = 'c';
   } else if ( _clex_find(0, 'g') == CFG_STRING ) {
      excludes = "Xc";
   }

   // save search options to restore later
   status := 0;
   first_time := true;
   origOffset := _QROffset();
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);

   loop {
      // are we on an open or close paren, bracket, or brace?
      ch := get_text();
      
      matchWord := '';
      long wordStartOffset=0, wordEndOffset=0, otherWordOffset=0;
      isStart := (ch:=='(' || ch:=='[' || ch:=='{');
      if ( !isStart ) {
         isStart = isMatchingWord('', matchWord,&wordStartOffset,&wordEndOffset,&otherWordOffset); 
      }
      isClose := (ch:==')' || ch:==']' || ch:=='}');
      if ( !isStart && !isClose ) {
         isClose =  isMatchingWord('-',matchWord,&wordStartOffset,&wordEndOffset,&otherWordOffset);
      }

      if ( isStart || isClose ) {

         if ( direction != '-' && matchWord != '' ) {
            _GoToROffset(wordEndOffset);
         }

         // not first time here, termination conditions are:
         //    1) start char and direction is backward
         //    2) close char and direction is forward
         if ( !first_time && isStart == (direction=='-') ) {
            if ( matchWord == '' || ((otherWordOffset >= origOffset) == (direction=='-')) ) {
               if ( direction=='-' && matchWord != '' ) {
                  _GoToROffset(wordStartOffset);
               }
               break;
            }
         }
         // conditions for skipping paren block:
         //    1) close char and direction is backward
         //    2) start char and direction is forward 
         if ( isClose == (direction == '-') ) {
            if ( matchWord != '' ) {
               _GoToROffset(otherWordOffset);
            } else {
               status = _find_matching_paren(def_pmatch_max_diff,true);
               if ( status < 0 ) break;
            }
            // first time, then moving to the match is enough
            if ( first_time ) {
               break;
            }
         }

         // just move past the character and continue
         status = traverse_char(direction);
         if ( status < 0 ) break;
      } else {

         if ( isalnum(ch) ) {
            beforeSearchOffset := _QROffset();
            status = search("[^a-zA-Z_0-9]", direction"@rh");
            if ( status ) break;
            status = next_char();
            if ( status ) break;
            if ( _QROffset() == beforeSearchOffset ) {
               status = traverse_char(direction);
               if ( status ) break;
            }
         } else {
            // just move past the character and continue
            status = traverse_char(direction);
            if ( status ) break;
         }
      }

      // look for the next paren, bracket or brace
      first_time = false;
      status = search('[\(\{\[\]\}\)]|:w', '@'direction'rh'excludes);
      if ( status < 0 ) break;
   }

   // we did not find a match, so just to either to top or bottom of the
   if ( status ) {
      if ( direction == '-' ) {
         top();
         _begin_line();
      } else {
         bottom();
         _end_line();
      }
   }

   // restore search options and we are done
   restore_search(s1,s2,s3,s4,s5);
   return 0;
}

/**
 * Moves forward over the S-expression starting at the cursor position. 
 * <p> 
 * If the first significant character after the cursor is an opening
 * delimiter, move past the matching closing delimiter. If the character 
 * begins a symbol, string, or number, move over that to the next
 * group of characters.  Consider spaces, commas, and semicolons as
 * delimiters.  The balanced expression commands move across comments 
 * as if they were whitespace. 
 * </p>
 *  
 * @return Returns 0 if successful, <0 on error.
 * 
 * @see prev_sexp 
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command int next_sexp() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   return(do_next_prev_sexp(''));
}
/**
 * Moves backward over the S-expression starting at the cursor position.
 * <p> 
 * If the first significant character after the cursor is a closing
 * delimiter, move to the matching opening delimiter. If the character 
 * begins a symbol, string, or number, move over that to the previous
 * group of characters.  Consider spaces, commas, and semicolons as
 * delimiters.  The balanced expression commands move across comments 
 * as if they were whitespace. 
 * </p>
 *  
 * @return Returns 0 if successful, <0 on error.
 * 
 * @see next_sexp 
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command int prev_sexp() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   return(do_next_prev_sexp('-'));
}
/**
 * Moves forward and down into the next S-expression starting from 
 * the cursor position.  If the cursor is not on a open paren, 
 * bracket, or brace, it will behave just like {@link next_sexp}. 
 *  
 * @return Returns 0 if successful, <0 on error.
 * 
 * @see next_sexp 
 * @see prev_sexp 
 * @see backward_up_sexp 
 * @see backward_down_sexp 
 * @see forward_up_sexp 
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command int forward_down_sexp() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   comment_option := ( _clex_find(0, 'g') == CFG_COMMENT )? 'c':'';
   switch ( get_text() ) {
   case '(':
   case '[':
   case '{':
      next_char();
      return _clex_skip_blanks('h'comment_option);
   default:
      matchWord := '';
      long wordStartOffset=0, wordEndOffset=0;
      if (isMatchingWord('' ,matchWord,&wordStartOffset,&wordEndOffset) && matchWord!='') {
         _GoToROffset(wordEndOffset);
         next_char();
         return _clex_skip_blanks('h'comment_option);
      }

      return do_next_prev_sexp('');
   }
}

/**
 * Moves backward and down into the preceeding S-expression 
 * starting from the cursor position.  If the cursor is not on a 
 * close paren, bracket, or brace, it will behave just like {@link
 * prev_sexp}. 
 *  
 * @return Returns 0 if successful, <0 on error.
 * 
 * @see next_sexp 
 * @see prev_sexp 
 * @see backward_up_sexp 
 * @see forward_up_sexp 
 * @see forward_down_sexp 
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command int backward_down_sexp() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   switch ( get_text() ) {
   case ')':
   case ']':
   case '}':
      comment_option := ( _clex_find(0, 'g') == CFG_COMMENT )? 'c':'';
      prev_char();
      break;
   default:
      matchWord := '';
      origOffset := _QROffset();
      long wordStartOffset=0;
      if (isMatchingWord('-' ,matchWord,&wordStartOffset)) {
         _GoToROffset(wordStartOffset);
         prev_char();
      } else if (origOffset > 0) {
         prev_char();
         if (isMatchingWord('-' ,matchWord,&wordStartOffset) && wordStartOffset < origOffset) {
            _GoToROffset(wordStartOffset);
            return 0;
         }
         _GoToROffset(origOffset);
      }
      break;
   }
   return do_next_prev_sexp('-');
}

/**
 * Moves backwards up into the parent S-expression starting from the 
 * cursor position.  If no parent S-expression is found, it will 
 * move the cursor to the beginning of the file. 
 *  
 * @return Returns 0 if successful, <0 on error.
 * 
 * @see next_sexp 
 * @see prev_sexp 
 * @see forward_up_sexp 
 * @see backward_down_sexp 
 * @see forward_down_sexp 
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command int backward_up_sexp() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   return do_up_sexp('-');
}

/**
 * Moves forward up into the parent S-expression starting from the 
 * cursor position. Cursor position is unchanged if not found. 
 *  
 * @return Returns 0 if successful, <0 on error.
 * 
 * @see next_sexp 
 * @see prev_sexp 
 * @see backward_up_sexp 
 * @see backward_down_sexp 
 * @see forward_down_sexp 
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command int forward_up_sexp() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   return do_up_sexp('');
}

/**
 * Transpose the current S-expression with the next one. 
 *  
 * @return Returns 0 if successful, <0 on error. 
 * 
 * @see next_sexp 
 * @see prev_sexp 
 * @see cut_next_sexp 
 * @see cut_prev_sexp 
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command int transpose_sexp() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   // go to the next S-expression and map out where it starts and ends
   save_pos(auto p1);
   offset1 := _QROffset();
   status := next_sexp();
   if ( status < 0 ) return status;
   save_pos(auto p3);
   offset3 := _QROffset();
   _GoToROffset(offset3-1);
   if ( status < 0 ) return status;
   ch := get_text();
   if ( pos(ch, " \t\n\r\v")) {
      status = _clex_skip_blanks('-hc'); 
      if ( status < 0 ) return status;
      status = next_char();
      if ( status < 0 ) return status;
   } else {
      restore_pos(p3);
   }

   // and the next one
   save_pos(auto p2);
   offset2 := _QROffset();
   restore_pos(p3);
   status = next_sexp();
   if ( status < 0 ) return status;
   offset4 := _QROffset();
   save_pos(auto p4);

   _GoToROffset(offset4-1);
   ch = get_text();
   if ( pos(ch, " \t\n\r\v")) {
      status = _clex_skip_blanks('-hc'); 
      if ( status < 0 ) return status;
      status = next_char();
      if ( status < 0 ) return status;
   } else {
      restore_pos(p4);
   }
   offset4 = _QROffset();
   
   // now get each part, the first expression, the space between, 
   // and the next one
   restore_pos(p1);
   sexp1 := get_text_raw((int)(offset2-offset1));
   restore_pos(p2);
   space := get_text_raw((int)(offset3-offset2));
   restore_pos(p3);
   sexp2 := get_text_raw((int)(offset4-offset3));

   // out with the old, in with the new
   restore_pos(p1);
   _delete_text((int)(offset4-offset1));
   _insert_text_raw(sexp2:+space:+sexp1);
   return 0;
}

/**
 * Select the next S-expression.  If called repeatedly, extend 
 * the selection to the next S-expression. 
 * 
 * @return Returns 0 if successful, <0 on error. 
 * 
 * @see next_sexp 
 * @see prev_sexp 
 * @see select_prev_sexp
 * @see cut_next_sexp 
 * @see cut_prev_sexp 
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command int select_next_sexp() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if ( _select_type() != 'CHAR' ) {
      select_char();
   }

   status := next_sexp();
   if (status < 0) {
      _deselect();
   }

   return status;
}

/**
 * Select the next S-expression.  If called repeatedly, extend 
 * the selection to the next S-expression. 
 * 
 * @return Returns 0 if successful, <0 on error. 
 * 
 * @see next_sexp 
 * @see prev_sexp 
 * @see select_next_sexp
 * @see cut_next_sexp 
 * @see cut_prev_sexp 
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command int select_prev_sexp() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if ( _select_type() != 'CHAR' ) {
      select_char();
   }

   status := prev_sexp();
   if (status < 0) {
      _deselect();
   }

   return status;
}

/**
 * Delete the next S-expression and add it to the clipboard. 
 * If called repeatedly, append the deleted text to the 
 * clipboard.
 * 
 * @return Returns 0 if successful, <0 on error. 
 * 
 * @see next_sexp 
 * @see prev_sexp 
 * @see select_prev_sexp
 * @see select_next_sexp 
 * @see cut_prev_sexp 
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command int cut_next_sexp() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   save_last_index := last_index('','C');
   boolean doAppend = ( name_name(prev_index('','C'))=='cut-next-sexp' );

   status := select_next_sexp();
   if ( status < 0 ) {
      return status;
   }

   if ( doAppend ) {
      append_cut();
   } else {
      cut();
   }

   last_index(save_last_index,'C');
   return 0;
}

/**
 * Delete the previous S-expression and add it to the 
 * clipboard. If called repeatedly, prepend the deleted text
 * to the clipboard. 
 * 
 * @return Returns 0 if successful, <0 on error. 
 * 
 * @see next_sexp 
 * @see prev_sexp 
 * @see select_prev_sexp
 * @see select_next_sexp 
 * @see cut_prev_sexp 
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command int cut_prev_sexp() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   save_last_index := last_index('','C');
   boolean doAppend = ( name_name(prev_index('','C'))=='cut-prev-sexp' ||
                        name_name(prev_index('','C'))=='cut-next-sexp' );

   // to prepend to the clipboard, first we must paste the
   // previous clipboard contents 
   if ( doAppend ) {
      save_pos(auto p);
      paste();
      select_char();
      restore_pos(p);
   }

   // now we select the previous expression
   status := select_prev_sexp();

   // delete the clipboard we are replacing
   if ( doAppend ) {
      free_clipboard(1);
   }

   // cut to copy to clipboard
   cut();

   // done
   last_index(save_last_index,'C');
   return status;
}

/**
 * Used in EMACS emulation.  Searches for an open parenthesis character '(', 
 * '[', or '{' and places   the cursor after the matching close parenthesis.  
 * Cursor position is unchanged if matching close parenthesis is not found.  
 * Comment or string literals may cause this command to match parenthesis 
 * incorrectly.
 * 
 * @return Returns 0 if successful.  Common return value is 
 * TOO_MANY_MARKS_RC.  On error, message displayed.
 * 
 * @see prev_level
 * @see cut_level
 * @see cut_prev_level
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 * 
 */
_command next_level() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   return(next_level2(1));
}
static _str next_level2(_str direction,_str option='',boolean push=false)
{
   /* Search for '(','{' or '[' */
   typeless mark=_alloc_selection();
   if ( mark<0 ) {
      message(get_message(mark));
      return(mark);
   }
   int status;
   _select_char(mark,'N');
   if ( direction==1 ) {
      status=search('\(|\[|\{','rh');
   } else {
      typeless p=point();
      int col=p_col;
      status=search('\)|\]|\}','rh-');
      if ( p==point() && col==p_col ) {
         status=repeat_search();
      }
   }
   if ( ! status ) {
      int lindex=last_index('','C');
      status=_find_matching_paren(def_pmatch_max_diff,true);
      last_index(lindex,'C');
      if ( ! status ) {
         if ( direction==1 ) { p_col=p_col+1; };
      } else {
         _begin_select(mark);
      }
   }
   if ( status ) {
      clear_message();
      if ( direction==1 ) {
         bottom();
      } else {
         top();
      }
   }
   if ( upcase(option)=='D' ) { /* Delay and restore cursor? */
      refresh();
      delay(50,'k');
      _begin_select(mark);
   } else if ( upcase(option)=='K' ) { /* Delete the level. */
      _select_char(mark);
      _begin_select(mark);
      _str old_mark=_duplicate_selection('');
      _show_selection(mark);
      int lindex=last_index('','C');
      if ( direction==1 ) {
         cut(push);
      } else {
         backward_cut(push);
      }
      last_index(lindex,'C');
      _show_selection(old_mark);
   }
   _free_selection(mark);
   return(0);

}
/**
 * Used in EMACS emulation.  Searches for close parenthesis character 
 * ')', ']', or '}' and places   the cursor on the matching open parenthesis.  
 * Searching for close parenthesis starts at character before cursor.  
 * Cursor position is unchanged if matching open parenthesis is not 
 * found.  Comment or string literals may cause this command to match 
 * parenthesis incorrectly.
 * 
 * @return Returns 0 if successful.  Common return values is 
 * TOO_MANY_MARKS_RC.  On error, message displayed.
 * 
 * @see next_level
 * @see cut_level
 * @see cut_prev_level
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 * 
 */ 
_command prev_level() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   return(next_level2(''));
}


/**
 * Used in EMACS emulation.  Deletes text from character before cursor to start 
 * of the previous parenthesis level and copies it to the clipboard.  See 
 * <b>prev_level</b> command for information on how the start of previous 
 * parenthesis level is found.   If the start of the previous parenthesis level 
 * is not found, text from character before cursor to top of buffer is deleted 
 * and copied to the clipboard.  Invoking this command multiple times in succession 
 * creates one clipboard.
 * 
 * @return  Returns 0 if successful.  Common return values is TOO_MANY_MARKS_RC.  
 * On error, message displayed.
 * 
 * @see next_level
 * @see cut_level
 * @see prev_level
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command cut_prev_level() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   return(next_level2('','K',name_name(prev_index('','C'))!='cut-prev-level'));
}
/**
 * Used in EMACS emulation.  Deletes text from cursor to character before end of 
 * next parenthesis level and copies it to the clipboard.  See NEXT-LEVEL command 
 * for information on how the end of the next parenthesis level is found.   If 
 * the end of the next parenthesis level is not found, text from cursor to end 
 * of buffer is deleted and copied to the clipboard.  Invoking this command 
 * multiple times in succession creates one clipboard.
 * 
 * @return  Returns 0 if successful.  Common return value is TOO_MANY_MARKS_RC.  
 * On error, message displayed.
 * 
 * @see next_level
 * @see cut_prev_level
 * @see prev_level
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command cut_level() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   return(next_level2(1,'K',name_name(prev_index('','C'))!='cut-level'));
}


/**
 * Used in EMACS emulation.   Temporarily places cursor at the start of the 
 * previous parenthesis level until delay time expires.  See prev_level command 
 * for information on how the start of previous parenthesis level is found.  If 
 * the start of the previous parenthesis level is not found, the cursor does not 
 * move.
 * 
 * @see find_matching_paren
 * @see keyin_match_paren
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command find_delimiter() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   return(next_level2('','D'));

}
_str
   emacs_mark;

definit()
{
   if ( arg(1):=='L' ) {
      _free_selection(emacs_mark);
   }
   emacs_mark=_alloc_selection();
   if ( emacs_mark<0 ) {
      message(get_message((int)emacs_mark));
   }
   init_sbuffer();
   rc=0;
}

/**
 * Used in EMACS emulation.   Starts an inclusive block selection at the 
 * cursor position.  The highlighted text extends to where the cursor moves.  
 * Ctrl+G may be used to cancel the mark.
 * 
 * @see emacs_select_char
 * @see select_line
 * @see cut_region
 * @see copy_region
 * @see indent_region
 * @see tabify_region
 * @see untabify_region
 * @see exchange_point_and_mark
 * @see reflow_region
 * @see fill_selection
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 */
_command emacs_select_block() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   emacs_select_char('B');

}
static _str _emacs_mstyle()
{
   /* return(translate(def_select_style,'NN','NI')def_advanced_select) */
   return('C'def_advanced_select);

}

/**
 * Used in EMACS emulation.   Starts an non-inclusive character selection 
 * at the cursor position.  The highlighted text extends to where the 
 * cursor moves.  Ctrl+G may be used to cancel the mark.
 * 
 * @see emacs_select_block
 * @see select_line
 * @see cut_region
 * @see copy_region
 * @see indent_region
 * @see tabify_region
 * @see untabify_region
 * @see exchange_point_and_mark
 * @see reflow_region
 * @see fill_selection
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 */
_command emacs_select_char(...) name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   _cua_select=0;
   sticky_message(nls('Mark set.  Ctrl+G Cancels mark'));
   _deselect(emacs_mark);
   _deselect();
   _str mstyle=_emacs_mstyle();
   if ( upcase(arg(1))=='B' ) {
      _select_block('',mstyle);
      _select_block(emacs_mark);
   } else {
      _select_char('',mstyle);
      _select_char(emacs_mark);
   }

}

/**
 * Used in EMACS emulation.  Inserts the last clipboard created.
 * 
 * @see list_clipboards
 * @see paste
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command emacs_paste() name_info(','VSARG2_MARK|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_CLIPBOARD)
{
   _str old_mark=_duplicate_selection('');
   _free_selection(emacs_mark);
   emacs_mark=_duplicate_selection();
   _show_selection(emacs_mark);
   typeless unmark_paste=def_deselect_paste;
   def_deselect_paste=0;
   int status=paste();
   def_deselect_paste=unmark_paste;
   if ( ! def_deselect_paste ) {
      _str new_mark=_duplicate_selection();
      if ( new_mark!='' ) {
         _show_selection(new_mark);
         _free_selection(old_mark);
      } else {
         _show_selection(old_mark);
      }
   } else {
      _show_selection(old_mark);
   }
   return(status);

}


/**
 * Used in EMACS emulation.  Deletes the text in the highlighted area and 
 * copies it to the clipboard.  If no highlighted area exists, an invisible 
 * mark is used which contains the last highlighted text not deleted or the 
 * last text pasted by the <b>emacs_paste</b> command.
 * 
 * @see select_block
 * @see select_line
 * @see emacs_select_char
 * @see copy_region
 * @see indent_region
 * @see tabify_region
 * @see untabify_region
 * @see exchange_point_and_mark
 * @see reflow_region
 * @see fill_selection
 * @see emacs_select_block
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command cut_region() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   set_region();
   cut();
}

/**
 * Used in EMACS emulation.  Copies the text in the highlighted area 
 * to the clipboard and unhighlights the text.  If no highlighted area 
 * exists, an invisible region is used which contains the last highlighted 
 * text not deleted or the last text pasted by the <b>emacs_paste</b> command.
 * 
 * @see select_block
 * @see select_line
 * @see emacs_select_char
 * @see cut_region
 * @see indent_region
 * @see tabify_region
 * @see untabify_region
 * @see exchange_point_and_mark
 * @see reflow_region
 * @see fill_selection
 * @see emacs_select_block
 * 
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command copy_region() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   set_region();
   copy_to_clipboard();
   clear_message();
}
/**
 * Used in EMACS emulation.  Indents the highlighted text to the next tab 
 * stop.  Tab or space  characters are used depending on the 
 * <b>indent_with_tabs</b> style.  If no highlighted text exists, an invisible 
 * selection is used which contains the last highlighted text not deleted or the 
 * last text pasted by the <b>emacs_paste</b> command.
 * 
 * @see indent_with_tabs
 * @see select_block
 * @see select_line
 * @see emacs_select_char
 * @see cut_region
 * @see copy_region
 * @see tabify_region
 * @see untabify_region
 * @see exchange_point_and_mark
 * @see reflow_region
 * @see fill_selection
 * @see emacs_select_block
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 * 
 */
_command indent_region() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   set_region();
   indent_selection();
   select_it(_select_type(),'','C');

}
/**
 * <p>Used in EMACS emulation.  Without an argument, this command indents the 
 * highlighted text to the next tab stop.  Tab or space characters are used 
 * depending on the <b>indent_with_tabs</b> style.  If no highlighted text 
 * exists, an invisible selection is used which contains the last highlighted 
 * text not deleted or the last text pasted by the <b>emacs_paste</b> command.</p>
 * 
 * <p>With an argument, this command indents or unindents each line in the 
 * highlighted text by the number of characters specified by the argument.  For 
 * a positive argument, tab or space characters are used depending on the 
 * <b>indent_with_tabs</b> style.</p>
 * 
 * @see indent_with_tabs
 * @see select_block
 * @see select_line
 * @see emacs_select_char
 * @see cut_region
 * @see indent_region
 * @see tabify_region
 * @see untabify_region
 * @see exchange_point_and_mark
 * @see reflow_region
 * @see fill_selection
 * @see emacs_select_block
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 * 
 */
_command indent_rigidly() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   if ( _argument=='' ) {
      return(indent_region());
   }
   set_region();
   char_select2line();
   filter_selection('_indentr-filter','',true);
   _argument='';
   select_it(_select_type(),'','C');

}
_str _indentr_filter(_str s)
{
   if ( _argument<0 ) {
      int count=-_argument;
      if ( expand_tabs(s,1,count)=='' ) {
         return(expand_tabs(s,count+1,-1,'S'));
      }
      return(strip(s,'L'));
   }
   return(indent_string(_argument):+s);

}
int _leftcol;  /* Value set by filter_selection */

/**
 * Used in EMACS emulation.  Converts consecutive spaces in the 
 * highlighted text to the equivalent number of tab characters.  If no 
 * highlighted text exists, an invisible selection is used which contains 
 * the last highlighted text not deleted or the last text pasted by the 
 * <b>emacs_paste</b> command.
 * 
 * @see indent_with_tabs
 * @see select_block
 * @see select_line
 * @see emacs_select_char
 * @see cut_region
 * @see indent_region
 * @see copy_region
 * @see untabify_region
 * @see exchange_point_and_mark
 * @see reflow_region
 * @see fill_selection
 * @see emacs_select_block
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */ 
_command tabify_region() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   filter_selection('_tabify-filter','',true);
   select_it(_select_type(),'','C');

}
/**
 * Used in EMACS emulation.  Converts consecutive tab characters in 
 * the highlighted text to the equivalent number of space characters.  If 
 * no highlighted text exists, an invisible mark is used which contains the 
 * last highlighted text not deleted or the last text pasted by the 
 * emacs_paste command.
 * 
 * @see indent_with_tabs
 * @see select_block
 * @see select_line
 * @see emacs_select_char
 * @see cut_region
 * @see indent_region
 * @see copy_region
 * @see tabify_region
 * @see exchange_point_and_mark
 * @see reflow_region
 * @see fill_selection
 * @see emacs_select_block
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */ 
_command untabify_region() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   filter_selection('_untabify-filter','',true);
   select_it(_select_type(),'','C');

}

/**
 * Used in EMACS emulation.   Exchanges the cursor position with the pivot 
 * point or anchor of the selection.  If no highlighted text exists, an 
 * invisible mark is used which contains the last highlighted text not deleted 
 * or the last text pasted by the emacs_paste command.
 * 
 * @see indent_with_tabs
 * @see select_block
 * @see select_line
 * @see emacs_select_char
 * @see cut_region
 * @see indent_region
 * @see copy_region
 * @see untabify_region
 * @see exchange_point_and_mark
 * @see reflow_region
 * @see fill_selection
 * @see tabify_region
 * @see emacs_select_block
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command exchange_point_and_mark() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   set_region();
   int start_col,end_col,buf_id;
   _get_selinfo(start_col,end_col,buf_id);
   _str cc=_select_type('','P');
   _str type=_select_type();
   select_it(type,'')   /* Lock the active mark. */;
   if ( substr(cc,1,1)=='E' ) { _begin_select(); } else { _end_select(); }
   if ( substr(cc,2,1)=='E' ) { p_col=start_col; } else { p_col=end_col; }
   _deselect(emacs_mark);
   select_it(type,emacs_mark);
   if ( substr(cc,1,1)=='B' ) { _begin_select(); } else { _end_select(); }
   if ( substr(cc,2,1)=='B' ) { p_col=start_col; } else { p_col=end_col; }
   /*   select_char emacs_mark,'C' */
   select_it(type,emacs_mark,_emacs_mstyle());
   /* if substr(cc,1,1)='E' then _begin_select else _end_select endif */
   _str old_mark=_duplicate_selection('');
   _deselect();
   _show_selection(emacs_mark);
   emacs_mark=old_mark;

}
static void set_region()
{
   if ( _select_type()!='' ) {  /* Is there a visable mark? */
      int start_col,end_col,buf_id;
      _get_selinfo(start_col,end_col,buf_id);
      if ( buf_id==p_buf_id ) {
         return;
      }
      _deselect();
   }
   if ( _select_type(emacs_mark)=='' ) {  /* No invisable pasted mark */
      /* Set Mark to start at top of buffer */
      _select_char();
      top();_select_char(emacs_mark);
      _begin_select();_deselect();
   }
   _str old_mark=_duplicate_selection('');
   _show_selection(emacs_mark);
   /* Extend mark to cursor. */
   select_it(_select_type(),'');
   emacs_mark=old_mark;

}

/**
 * Places cursor at top left of window.
 * 
 * @see end_window
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * 
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command begin_window() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   p_cursor_x=0;p_cursor_y=0;

}

/** 
 * Places cursor at bottom right of window.
 * 
 * @see begin_window
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command end_window() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   _str old_scroll=_scroll_style();
   _scroll_style('S 0');
   int orig_left_edge=p_left_edge;
   p_cursor_x=p_client_width-1;
   if (p_left_edge!=orig_left_edge) {
      --p_col;
      set_scroll_pos(orig_left_edge,p_cursor_y);
   }
   p_cursor_y=p_client_height-1;
   _scroll_style(old_scroll);
}

/**
 * Used in EMACS emulation.  Deletes all space and tab characters to 
 * left and to right of cursor on the current line.
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command delete_space() name_info(','VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   init_command_op();
   int col=p_col;
   search('[ \t]#|?|$|^','@rh-');
   if ( match_length() && get_text(1,match_length('s'))=='' ) {
      _nrseek(match_length('s'));
      _delete_text(match_length());
   }
   p_col=col;
   retrieve_command_results();

}
/** 
 * Used in EMACS emulation.  Centers the text on the current 
 * line within the margins.
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command void center_within_margins() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   typeless lm,rm;
   parse p_margins with lm rm .;
   get_line(auto line);
   _str cline=center(strip(line),rm-lm+1);
   typeless i=verify(cline,' ');
   if ( ! i ) {
      i=1;
   }
   replace_line(indent_string(i-1):+strip(line));
}
static void char_select2line()
{
   if ( _select_type()=='CHAR' ) {
      /* Switch mark type to LINE */
      _select_type("","T","LINE");
   }

}
/**
 * Used in EMACS emulation.  Reflows the paragraphs within the 
 * highlighted text according to the left, right, and new-paragraph margin 
 * settings.  Paragraphs are assumed to be separated by at least one blank 
 * line or line containing just the characters tab, space, and form feed.  
 * 
 * @see margins
 * @see reflow_paragraph
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 * 
 */ 
_command reflow_region() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   typeless lm, rm;
   parse p_margins with lm rm . ;
   set_region();
   if ( _select_type()=='BLOCK' ) {
      message(nls('Block mark not supported'));
      return '';
   }
   char_select2line();
   _end_select();_end_line();
   _str old_mark=_duplicate_selection('');
   for (;;) {
      search(SKIP_PARAGRAPH_SEP_RE,'@rhm-');
      if ( rc ) {
         break;
      }
      right();
      _deselect(emacs_mark);
      _select_line(emacs_mark);
      prev_paragraph();
      if ( _begin_select_compare()<0 ) {  /* Before first line of mark? */
         _begin_select();
      }
      _select_line(emacs_mark);
      _show_selection(emacs_mark);
      execute('reflow-selection',"");
      emacs_mark=_duplicate_selection('');
      _show_selection(old_mark);
      search(PARAGRAPH_SEP_RE,'@rhm-');
      if ( rc ) {
         break;
      }
   }
   _deselect(emacs_mark);_deselect();
   clear_message();
}
/**
 * Used in EMACS emulation.   Writes the contents of the current buffer to a 
 * file you specify.  Prompts you for the file name using the <b>Explorer 
 * Standard Open dialog box</b> or <b>Standard Open dialog box</b>.
 * 
 * @return Returns 0 if successful.  Common return values are:
 * <ul>
 * <li>COMMAND_CANCELLED_RC</li>
 * <li>TOO_MANY_MARKS_RC</li>
 * <li>ACCESS_DENIED_RC</li>
 * <li>ERROR_OPENING_FILE_RC</li>
 * <li>INSUFFICIENT_DISK_SPACE_RC</li> 
 * <li>ERROR_CREATING_DIRECTORY_RC</li>
 * <li>ERROR_READING_FILE_RC</li>
 * <li>ERROR_WRITING_FILE_RC</li>
 * <li>DRIVE_NOT_READY_RC</li>
 * <li>PATH_NOT_FOUND_RC.  On error, message is displayed.</li>
 * </ul>
 * 
 * @see save_as
 * @see save
 * @see name
 * @see copy_to_file
 * 
 * @appliesTo Edit_Window
 *
 * @categories Editor_Control_Methods, File_Functions
 * 
 */
_command gui_copy_to_file() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   // Not sure if should support def_preplace option
   // If want to just or in OFN_NOOVERWRITEPROMPT
   int orig_wid=p_window_id;
   typeless result=_OpenDialog('-new -mdi -modal',
        'Copy File As',
        '',     // Initial wildcards
        //'*.c;*.h',
        def_file_types,
        OFN_SAVEAS|OFN_PREFIXFLAGS,
        '',      // Default extensions
        '',      // Initial filename
        '',      // Initial directory
        'gui_copy_to_file',      // Retrieve name
        'gui_copy_to_file'
        );
   p_window_id=orig_wid;
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }
   _macro('m',_macro('s'));
   _macro_call('save',result);
   return(save(result));
}

/**
 * Used in EMACS emulation.   Writes the contents of the current buffer 
 * to a file you specify.  Prompts you on the command line for a file name.
 * 
 * @return  Returns 0 if successful.  Common return values are 1 
 * COMMAND_CANCELLED_RC, TOO_MANY_MARKS_RC, ACCESS_DENIED_RC, 
 * ERROR_OPENING_FILE_RC, INSUFFICIENT_DISK_SPACE_RC, ERROR_CREATING_DIRECTORY_RC, 
 * ERROR_READING_FILE_RC, ERROR_WRITING_FILE_RC, DRIVE_NOT_READY_RC, 
 * and PATH_NOT_FOUND_RC.  On error, message is displayed.
 * 
 * @see save_as
 * @see save
 * @see name
 * @see gui_copy_to_file
 * 
 * 
 * @appliesTo  Edit_Window
 * 
 * @categories Editor_Control_Methods, File_Functions
 */
_command copy_to_file(_str line="") name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   typeless status=0;
   if (line=='') {
      _macro_delete_line();
      status=get_string(line,nls('Copy buffer to:')' ','-.copy-to-file',p_buf_name);
   }
   if ( status || line=='' ) {
      cancel();
      return COMMAND_CANCELLED_RC;
   }
   if (line=='') {
      _macro_call('save',line);
   }
   status=save(line);
   cursor_data();
   return(status);
}
/**
 * Used in EMACS emulation.  Loads a file from disk and replaces the contents 
 * of the current buffer with it.  Prompts you for the file to load using the 
 * <b>Explorer Standard Open dialog box</b> or <b>Standard Open dialog box</b>.
 * 
 * @see edit
 * @see visit_file
 * 
 * @appliesTo Edit_Window
 * 
 * @categories Edit_Window_Methods
 * 
 */
_command gui_visit_file() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   _macro_delete_line();
   typeless result=_OpenDialog('-new -mdi -modal',
        'Visit File',
        _last_wildcards,      // Initial wildcards
        def_file_types,			// file filters
        OFN_READONLY|OFN_EDIT,			// flags - read only, edit dialog
        '',      // Default extension
        '',      // Initial filename
        '',      // Initial directory
        'gui_visit_file',      // Retrieve name
        'gui_visit_file'       // Help item
        );
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }
   p_window_id=_mdi._edit_window();
   _macro('m',_macro('s'));
   _macro_call('visit_file',result);
   return(visit_file(result));
}
/**
 * Used in EMACS emulation.  Loads a file from disk and replaces the 
 * contents of the current buffer with it.  Prompts you for the file to load 
 * on the command line.
 * 
 * @see edit
 * @see gui_visit_file
 * 
 * @appliesTo Edit_Window
 * 
 * @categories Edit_Window_Methods
 * 
 */ 
_command visit_file(_str line="") name_info(FILE_ARG','VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   typeless status=0;
   if (line=='') {
      _macro_delete_line();
      status=get_string(line,nls('Visit file:')' ','-.edit',p_buf_name);
      if (status) return(COMMAND_CANCELLED_RC);
   }
   if (line=='') {
      cancel();
      return(COMMAND_CANCELLED_RC);
   }
   if ( ! status ) {
      if ( p_modify ) {
         int result=_message_box('Save file?','',MB_YESNOCANCEL|MB_ICONQUESTION);
         if (result==IDCANCEL) {
            cursor_data();
            return(COMMAND_CANCELLED_RC);
         }
         if ( result==IDYES) {
            status=save();
            if (status) {
               return(COMMAND_CANCELLED_RC);
            }
         }
      }
      if (line=='') {
         _macro_call('visit_file',line);
      }
      int orig_buf_id=p_buf_id;
      status=edit('-w +d 'line);
      if (!status ){
         int buf_id=p_buf_id;
         load_files('+bi 'orig_buf_id);
         _str buf_name=p_buf_name;
         _str docname=p_DocumentName;
         int buf_flags=p_buf_flags;
         _delete_buffer();
         //Since _delete_buffer() is too low level to update the proctree
         //we need to call _cbquit_proc_tree() to update the list.
         _cbquit_proc_tree(orig_buf_id,buf_name,docname,buf_flags);
         load_files('+bi 'buf_id);
      }
   }
   cursor_data();
   return(status);

}
/**
 * Used in EMACS emulation.  Prompts for a procedure tag name and places the 
 * cursor on the definition of the procedure name specified.
 * 
 * @see make_tags
 * @see gui_make_tags
 * @see push_tag
 * 
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 * 
 */
_command goto_tag() name_info(TAG_ARG','VSARG2_REQUIRES_MDI)
{
   _macro_delete_line();
   _str line;
   typeless status=get_string(line,nls('Find tag:')' ','-.goto_tag');
   if ( ! status && line!='') {
      status=push_tag(line);
      _macro_call('push_tag',line);
   }
   cursor_data();
   return(status);

}
/**
 * Used in EMACS emulation.  Displays the cursor seek position, buffer 
 * size, decimal character code at cursor, and hexadecimal character code 
 * at cursor.
 * 
 * @appliesTo Edit_Window
 * 
 * @categories Edit_Window_Methods
 * 
 */ 
_command show_point() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   // This is not a very useful function since it always outputs 
   // Utf-8 information which is already displayed in the status line.
   typeless chr_num=_UTF8Asc(get_text());
   sticky_message(nls('seek=%s buffer size=%s char is decimal=%s hex=%s',_QROffset(),p_RBufSize,chr_num,dec2hex(chr_num)));
}
/**
 * Used in EMACS emulation.  Displays the current directory and 
 * prompts for a directory to change to using the command line.
 * 
 * @see gui_cd
 * 
 * @categories File_Functions
 * 
 */ 
_command prompt_cd() name_info(FILE_ARG " "MORE_ARG',')
{
   message(nls('Current directory is %s',getcwd()));
   _str line;
   typeless status=get_string(line,nls('Change to directory:')' ','-.prompt-cd');
   if ( status || line=='' ) {
      return '';
   }
   cd(line);
   cursor_data();
}
/**
 * Used in EMACS emulation.  This command is identical to the dir 
 * command except that no arguments are accepted and this command 
 * always prompts for a directory on the command line.
 * 
 * @see fileman
 * 
 * @categories File_Functions
 * 
 */ 
_command prompt_dir()
{
   execute('dir <',"");
}
typeless old_search_flags;
_str
    old_search_string
    ,old_replace_string;


/**
 * <p>Used in EMACS emulation.</p>
 * 
 * <p>Starts a reverse regular expression search.  Prompts for the search 
 * string on the command line.  A long search may be stopped by 
 * pressing Ctrl+Alt+Shift.  For syntax of regular expressions see 
 * <b>Regular Expressions</b>.  The following keys take on a different 
 * definition while entering the regular expression argument.</p>
 * 
 * <dl>
 * <dt>Ctrl+R</dt><dd>Searches in reverse for next occurrence of search  
 * string.</dd>
 * <dt>Ctrl+S</dt><dd>Searches forward for next occurrence of search 
 * string.</dd>
 * <dt>Ctrl+T</dt><dd>Toggles regular expression pattern matching on/off.</dd>
 * <dt>Ctrl+W</dt><dd>Toggles word searching on/off.  </dd>
 * <dt>Ctrl+C</dt><dd>Toggles case sensitivity.</dd>
 * <dt>Ctrl+M</dt><dd>Toggles searching within mark.</dd>
 * <dt>Ctrl+Q</dt><dd>Quotes the next character typed.</dd>
 * <dt>Ctrl+O</dt><dd>Toggles incremental search mode.</dd>
 * </dl>
 * 
 * @see regex_search
 * @see replace_string
 * @see query_replace
 * @see reverse_i_search
 * @see find
 * @see replace
 * @see gui_find
 * @see gui_replace
 * @see find_next
 * @see find_prev
 * 
 * @appliesTo Edit_Window
 * 
 * @categories Edit_Window_Methods, Search_Functions
 * 
 */ 
_command reverse_regex_search() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if ( def_re_search==UNIXRE_SEARCH ) {
      qsearch('u-'_search_case());
   } else if ( def_re_search==BRIEFRE_SEARCH ) {
      qsearch('b-'_search_case());
   } else {
      qsearch('r-'_search_case());
   }

}
/**
 * <p>Used in EMACS emulation.<p>
 * 
 * @return Starts a regular expression search.  Prompts for the search string on the 
 * command line.  A long search may be stopped by pressing 
 * Ctrl+Alt+Shift.  For syntax of regular expressions see <b>Regular 
 * Expressions</b>.  The following keys take on a different definition 
 * while entering the regular expression argument.
 * 
 * <dl>
 * <dt>Ctrl+R</dt><dd>Searches in reverse for next occurrence of search  
 * string.</dd>
 * <dt>Ctrl+S</dt><dd>Searches forward for next occurrence of search 
 * string.</dd>
 * <dt>Ctrl+T</dt><dd>Toggles regular expression pattern matching on/off.</dd>
 * <dt>Ctrl+W</dt><dd>Toggles word searching on/off.</dd>
 * <dt>Ctrl+C</dt><dd>Toggles case sensitivity.</dd>
 * <dt>Ctrl+M</dt><dd>Toggles searching within mark.</dd>
 * <dt>Ctrl+Q</dt><dd>Quotes the next character typed.</dd>
 * <dt>Ctrl+O</dt><dd>Toggles incremental search mode.</dd>
 * </dl>
 * 
 * @see reverse_regex_search
 * @see replace_string
 * @see query_replace
 * @see reverse_i_search
 * @see find
 * @see replace
 * @see gui_find
 * @see gui_replace
 * @see find_next
 * @see find_prev
 * 
 * @appliesTo Edit_Window
 * 
 * @categories Edit_Window_Methods, Search_Functions
 * 
 */ 
_command regex_search() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if ( def_re_search==UNIXRE_SEARCH ) {
      qsearch('u>'_search_case());
   } else if ( def_re_search==BRIEFRE_SEARCH ) {
      qsearch('b>'_search_case());
   } else {
      qsearch('r>'_search_case());
   }

}
/**
 * <p>Used in EMACS emulation.</p>
 * 
 * <p>Performs a search and replace without prompting to replace each 
 * occurrence.  Prompts for the search and replace string arguments on 
 * the command line.  A long search may be stopped by pressing 
 * Ctrl+Alt+Shift.  For syntax of regular expressions see Regular 
 * Expressions.  The following keys take on a different definition while 
 * entering the regular expression argument.</p>
 * 
 * <dl> 
 * <dt>Ctrl+R</dt><dd>Searches in reverse for next occurrence of search  
 * string.</dd>
 * <dt>Ctrl+S</dt><dd>Searches forward for next occurrence of search 
 * string.</dd>
 * <dt>Ctrl+T</dt><dd>Toggles regular expression pattern matching on/off.</dd>
 * <dt>Ctrl+W</dt><dd>Toggles word searching on/off.</dd>
 * <dt>Ctrl+C</dt><dd>Toggles case sensitivity.</dd>
 * <dt>Ctrl+M</dt><dd>Toggles searching within mark.</dd>
 * <dt>Ctrl+Q</dt><dd>Quotes the next character typed.</dd>
 * <dt>Ctrl+O</dt><dd>Toggles incremental search mode.</dd>
 * </dl>
 * 
 * @see reverse_regex_search
 * @see regex_replace
 * @see query_replace
 * @see reverse_i_search
 * @see find
 * @see replace
 * @see gui_find
 * @see gui_replace
 * @see find_next
 * @see find_prev
 * 
 * @appliesTo Edit_Window
 * 
 * @categories Edit_Window_Methods, Search_Functions
 * 
 */ 
_command replace_string() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   return(replace_string2(nls('Replace string:')' ',GO_SEARCH));

}
/**
 * <p>Performs a regular expression search and replace.  Prompts for the 
 * search string and replace string on the command line.  A long search 
 * may be stopped by pressing Ctrl+Alt+Shift.  For syntax of regular 
 * expressions see <b>Regular Expressions</b>.  The following keys 
 * take on a different definition while entering the regular expression 
 * argument.</p>
 * 
 * <dl>
 * <dt>Ctrl+R</dt><dd>Searches in reverse for next occurrence of search  
 * string.</dd>
 * <dt>Ctrl+S</dt><dd>Searches forward for next occurrence of search 
 * string.</dd>
 * <dt>Ctrl+T</dt><dd>Toggles regular expression pattern matching on/off.</dd>
 * <dt>Ctrl+W</dt><dd>Toggles word searching on/off.</dd>
 * <dt>Ctrl+C</dt><dd>Toggles case sensitivity.</dd>
 * <dt>Ctrl+M</dt><dd>Toggles searching within mark.</dd>
 * <dt>Ctrl+Q</dt><dd>Quotes the next character typed.</dd>
 * <dt>Ctrl+O</dt><dd>Toggles incremental search mode.</dd>
 * </dl>
 * 
 * <p>You will be prompted with the message "Yes/No/Last/Go/Suspend?" 
 * for each occurrence of the search string.  Type the letter of the action 
 * you want to take.  The actions are:</p>
 * 
 * <dl>
 * <dt>Y or SPACE</dt><dd>Make change and continue searching.</dd>
 * <dt>N or BACKSPACE</dt><dd>No change and continue searching.</dd>
 * <dt>L or .</dt><dd>Make change and stop searching.</dd>
 * <dt>G or !</dt><dd>Make change and change the rest without 
 * prompting.</dd>
 * <dt>Q or ESC</dt><dd>Exits command.  By default, the cursor is 
 * NOT restored the to its original position.  If 
 * you want the cursor restored to its original 
 * position, invoke command "<b>set-var def-
 * restore-cursor 1</b>" and save the 
 * configuration.</dd>
 * <dt>S</dt><dd>Suspend change and replace.  Invoke the 
 * RESUME command to reinvoke the change 
 * and replace starting from the new cursor 
 * position.  Only one level of suspend is 
 * allowed.  Therefore, you must issue the 
 * RESUME command before you can use the 
 * suspend option in a new search and replace 
 * command.  This is an advanced option which 
 * allows you edit the area where the string that 
 * was found any way you like and then resume 
 * the command.</dd>
 * <dt>Ctrl+G</dt><dd>Exits command and restore cursor to its 
 * original position.</dd>
 * <dt>Ctrl+R</dt><dd>Searches in reverse for next occurrence of 
 * search string</dd>
 * <dt>Ctrl+S</dt><dd>Searches forward for next occurrence of 
 * search string</dd>
 * <dt>Ctrl+T</dt><dd>Toggles regular expression pattern matching 
 * on/off.</dd>
 * <dt>Ctrl+W</dt><dd>Toggles word searching on/off.</dd>
 * <dt>Ctrl+C</dt><dd>Toggles case sensitivity.</dd>
 * <dt>Ctrl+M</dt><dd>Toggles searching within mark.</dd>
 * <dt>F1 or ?</dt><dd>Displays help on <b>replace</b> command.</dd>
 * </dl>
 * 
 * @see reverse_regex_search
 * @see regex_search
 * @see replace_string
 * @see query_replace
 * @see reverse_i_search
 * @see find
 * @see replace
 * @see gui_find
 * @see gui_replace
 * @see find_next
 * @see find_prev
 * 
 * @appliesTo Edit_Window
 * 
 * @categories Edit_Window_Methods, Search_Functions
 * 
 */ 
_command regex_replace() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   return(replace_string2(nls('Query replace:')' ',GO_SEARCH|def_re_search));

}
/**
 * <p>For help on regular expression, see <b>Regular Expressions</b>.</p>
 * 
 * <p>Prompts for search string and replace string arguments and prompts 
 * whether to replace occurrences of search with replace string.  A long 
 * search may be stopped by pressing Ctrl+Alt+Shift.  The following 
 * keys take on a different definition while entering the search string 
 * argument.</p>
 * 
 * <dl> 
 * <dt>Ctrl+R</dt><dd>Searches in reverse for next occurrence of search 
 * string</dd>
 * <dt>Ctrl+S</dt><dd>Searches forward for next occurrence of search 
 * string</dd>
 * <dt>Ctrl+T</dt><dd>Toggles regular expression pattern matching on/off.</dd>
 * <dt>Ctrl+W</dt><dd>Toggles word searching on/off.</dd>
 * <dt>Ctrl+C</dt><dd>Toggles case sensitivity.</dd>
 * <dt>Ctrl+M</dt><dd>Toggles searching within selection.</dd>
 * <dt>Ctrl+Q</dt><dd>Quotes the next character typed.</dd>
 * <dt>Ctrl+O</dt><dd>Toggles incremental search mode.</dd>
 * </dl> 
 * 
 * <p>You will be prompted with the message "Yes/No/Last/Go/Suspend?" 
 * for each occurrence of the search string.  Type the letter of the action 
 * you want to take.  The actions are:</p>
 * 
 * <dl> 
 * <dt>Y or SPACE</dt><dd>Make change and continue searching.</dd>
 * <dt>N or BACKSPACE</dt><dd>No change and continue searching.</dd>
 * <dt>L or .</dt><dd>Make change and stop searching.</dd>
 * <dt>G or !</dt><dd>Make change and change the rest without 
 * prompting.</dd>
 * <dt>Q or ESC</dt><dd>Exits command.  By default, the cursor is 
 * NOT restored the to its original position.  If 
 * you want the cursor restored to its original 
 * position, invoke command "<b>set-var def-
 * restore-cursor 1</b>" and save the 
 * configuration.</dd>
 * <dt>S</dt><dd>Suspend change and replace.  Invoke the 
 * RESUME command to reinvoke the change 
 * and replace starting from the new cursor 
 * position.  Only one level of suspend is 
 * allowed.  Therefore, you must issue the 
 * RESUME command before you can use the 
 * suspend option in a new search and replace 
 * command.  This is an advanced option which 
 * allows you edit the area where the string that 
 * was found any way you like and then resume 
 * the command.</dd>
 * <dt>Ctrl+G</dt><dd>Exits command and restore cursor to its 
 * original position.</dd>
 * <dt>Ctrl+R</dt><dd>Searches in reverse for next occurrence of 
 * search string</dd>
 * <dt>Ctrl+S</dt><dd>Searches forward for next occurrence of 
 * search string</dd>
 * <dt>Ctrl+T</dt><dd>Toggles regular expression pattern matching 
 * on/off.</dd>
 * <dt>Ctrl+W</dt><dd>Toggles word searching on/off.</dd>
 * <dt>Ctrl+C</dt><dd>Toggles case sensitivity.</dd>
 * <dt>Ctrl+M</dt><dd>Toggles searching within mark.</dd>
 * <dt>F1 or ?</dt><dd>Displays help on <b>replace</b> command.</dd>
 * </dl>
 * 
 * @see reverse_regex_search
 * @see replace_string
 * @see reverse_i_search
 * @see find
 * @see replace
 * @see gui_find
 * @see gui_replace
 * @see find_next
 * @see find_prev
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions
 * 
 */ 
_command query_replace() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   return(replace_string2(nls('Query replace:')' ',_default_option('s')));

}
static _str replace_string2(_str prompt,int flags)
{
   if (!_default_option(VSOPTION_HAVECMDLINE)) {
      int status=gui_replace(make_search_options(flags));
      return(status);
   }
   old_search_flags = (old_search_flags &~(INCREMENTAL_SEARCH|RE_SEARCH|UNIXRE_SEARCH|BRIEFRE_SEARCH))|
                      POSITIONONLASTCHAR_SEARCH;
   if ( init_qreplace(init_search_flags(old_search_flags)|flags,
      prompt) ) {
      return(1);
   }
   int status=qreplace(old_search_string,old_replace_string,
           old_search_flags|flags);
   return(status);

}
/**
 * Used in EMACS emulation.  Displays the Tag Files dialogs which 
 * allows you to configure the tag files used by the <b>goto_tag</b>, 
 * <b>gui_push_tag</b>, <b>push_tag</b>, and <b>find_tag</b> 
 * commands.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 * 
 */ 
_command select_tag_file()
{
   gui_make_tags();
   //set_env(_SLICKTAGS,prompt(arg(1),'',get_env(_SLICKTAGS)));
}


/** 
 * Used in EMACS emulation.  
 * <p>
 * Without an argument this command deletes all but one blank line 
 * around or before the current line.  If there is only one blank line 
 * it is deleted.
 * <p>
 * With an argument this command changes the number of blank lines around 
 * or before the current line to the number specified.
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command delete_blank_lines() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   boolean line_blank= !_first_non_blank_col(0);
   if ( _on_line0() ) {
      return '';
   }
   int status;
   if (arg(1)=='B') {
      // Not sure if epsilon really does work this way.
      if (!line_blank) {
         up();
         line_blank= !_first_non_blank_col(0);
         if (!line_blank || _on_line0()) {
            down();
         }
      }
   } else {
      // This is the way GNU works
      if (!line_blank) {
         status=down();
         if (!status) {
            line_blank= !_first_non_blank_col(0);
            if (!line_blank) {
               up();
            }
         }
      }
   }

   int i,count;
   if ( !line_blank) {
      if ( _argument!='' && _argument>0 ) {
         up();
         for (i=1; i<=_argument ; ++i) {
            insert_line('');
         }
         up(_argument-1);
         _argument='';
      }
      return('');
   }
   count=0;
   status=search('^~([ \t]*$)','@rh-');
   if (status) {
      top();
   } else {
      down();
   }
   for (;;) {
      line_blank= !_first_non_blank_col(0);
      if ( !line_blank ) {
         up(count);
         break;
      }
      count=count+1;
      if ( down() ) {
         up(count-1);
         break;
      }
   }
   int del_count=0;
   if ( _argument=='' ) {
      del_count=count-1;
      if ( ! del_count ) {
         del_count=1;
      }
   } else {
      del_count=count-_argument;
   }
   for (i=1; i<=del_count ; ++i) {
      _delete_line();
   }
   int ins_count=0;
   if ( _argument!='' ) {
      ins_count=_argument-count;
      if ( ins_count>0 ) {
         up();
         for (i=1; i<=ins_count ; ++i) {
            insert_line('');
         }
         up(ins_count-1);
      }
   }
   _argument='';
}
static int sbuffer_view_id;

static void init_sbuffer()
{
   int window_group_view_id=_find_or_create_temp_view(sbuffer_view_id,'+futf8 +t','.emacs-sb',false,VSBUFFLAG_THROW_AWAY_CHANGES,true);
   activate_window(window_group_view_id);

}
void _cw_emacs()
{
   _prev_window( 'f');
   _str old_buffer_name;
   get_window_info(p_window_id,old_buffer_name);
   _next_window( 'f');
   int view_id;
   get_window_id(view_id);
   int window_id=p_window_id;
   activate_window(sbuffer_view_id);
   top();
   int status=search('^'window_id' ','@r');
   if ( status ) {
      clear_message();
      insert_line(window_id' 'old_buffer_name);
   } else {
      replace_line(window_id' 'old_buffer_name);
   }
   activate_window(view_id);

}
static void get_window_info(int window_id,_str &filename)
{
   int view_id;
   get_window_id(view_id);
   activate_window(sbuffer_view_id);
   top();up();
   int status=search('^'window_id' ','@r');
   if ( status ) {
      filename='';
   } else {
      get_line(auto line);
      parse line with . filename;
   }
   activate_window(view_id);
}

/**
 * Used in EMACS emulation.  Prompts for the name of a buffer to delete.  
 * If the current buffer is deleted, you are prompted for another buffer 
 * to switch to.
 * 
 * @see select_buffer
 * @see edit
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command emacs_quit() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   if ( last_buffer() ) {
      return(quit());
#if 0
      message nls("Can't quit last buffer")
      return(1)
#endif
   }
   _str doc_name=(p_DocumentName!="")?p_DocumentName:p_buf_name;
   boolean is_url=_isHTTPFile(doc_name)!=0;
   _str kill_buf_name;
   typeless status=get_string(kill_buf_name,nls('Kill buffer:')' ','-BUFFER;.emacs-quit',is_url?doc_name:relative(doc_name));
   if ( status ) {
      return(COMMAND_CANCELLED_RC);
   }
   kill_buf_name=strip(kill_buf_name);
   boolean killing_current=file_eq(doc_name,absolute(kill_buf_name)) ||
      file_eq(strip(doc_name),kill_buf_name);
   int wid=p_window_id;
   int buf_id=p_buf_id;
   if ( ! killing_current ) {
      _str attempt=absolute(kill_buf_name);
      if ( attempt=='' ) {
         return '';
      }
      status=edit('+b 'maybe_quote_filename(attempt));
      if ( status ) {
        clear_message();
        status=edit('+b 'maybe_quote_filename(kill_buf_name));
      }
      if ( status ) {
         p_window_id=wid;p_buf_id=buf_id;
         return(COMMAND_CANCELLED_RC);
      }
   }
   int kill_wid=p_window_id;
   int kill_buf_id=p_buf_id;
   boolean modify=p_modify;
   _str nls_chars='',yes,no,line;
   p_window_id=wid;p_buf_id=buf_id;
   if ( modify && substr(kill_buf_name,1,1)!='.' ) {
      for (;;) {
         message(nls('Buffer %s not saved.',relative(kill_buf_name)));
         nls_yes_no(nls_chars,yes,no);
         status=get_string(line,nls('Delete it [%s,%s]?',yes,no)' ','-BUFFER;.emacs-quit','n');
         if ( status ) {
            return(COMMAND_CANCELLED_RC);
         }
         line=upcase(line);
         if ( line==no ) {
            clear_message();
            return(COMMAND_CANCELLED_RC);
         }
         if ( line==yes ) {
            clear_message();
            break;
         }
      }
   }
   if ( killing_current ) {
      _str filename;
      get_default_sb(filename);
      message(nls('Killing current buffer'));
      _str buf_name;
      status=get_string(buf_name,nls('Switch To:')' ',
         '-BUFFER;.emacs-quit',filename);
      if ( status ) {
         return(COMMAND_CANCELLED_RC);
      }
      clear_message();
      if (  file_eq(buf_name,absolute(kill_buf_name)) ||
           file_eq(strip(buf_name),kill_buf_name) ) {
         return(1);
      }
      p_modify=0;
      quit();
      _str name,path;
      parse buf_name with name'<'path'>' ;
      if ( path!='' ) {
         buf_name=path:+name;
      }
      if (buf_name!='') {
         status=edit('+b 'maybe_quote_filename(buf_name));
         if (status) {
            message(nls("Buffer '%s' not found",buf_name));
         }
      }
   } else if ( kill_buf_name!='' ) {
      /* Quiting a buffer that is not active */
      p_window_id=kill_wid;p_buf_id=kill_buf_id;
      p_modify=0;
      quit();
      p_window_id=wid;p_buf_id=buf_id;
   }

}
/**
 * Used in EMACS emulation.  Prompts for the name of a buffer to 
 * switch to using the command line.  Each window has a default buffer 
 * name to switch which is set to the last buffer active in the window 
 * before the current buffer.
 * 
 * @see emacs_quit
 * @see edit
 * 
 * @appliesTo Edit_Window
 * 
 * @categories Edit_Window_Methods, Selection_Functions
 * 
 */ 
_command select_buffer(_str buffer_name="") name_info(EMACS_BUFFER_ARG','VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   _str filename;
   _str old_buffer_name;
   typeless swold_pos;
   int swold_buf_id;
   set_switch_buffer_args(old_buffer_name,swold_pos,swold_buf_id);
   if (buffer_name=='') {
      get_default_sb(filename);
      _str msg=nls('Buffer Name');
      if ( filename!='' ) {
         /* msg=msg' ['relative(filename)']' */
         filename=make_buf_match(filename);
      }
      buffer_name=prompt(buffer_name,msg,filename);
      if ( buffer_name=='' ) {
         return(0);
      }
   }
   _str name,path;
   parse buffer_name with name'<'path'>' ;
   if ( path!='' ) {
      buffer_name=path:+name;
   }
   _str attempt=absolute(strip(buffer_name));
   if ( attempt=='' ) {
      return '';
   }
   int status=edit('+b 'maybe_quote_filename(attempt));
   if ( status ) {
     clear_message();
     status=edit('+b 'maybe_quote_filename(buffer_name));
   } else {
      buffer_name=attempt;
   }
   if ( status ) {
      /* Create a new buffer */
      clear_message();
      status=edit('+t 'maybe_quote_filename(buffer_name));
   }
   switch_buffer(old_buffer_name,'',swold_pos,swold_buf_id);
}

/* Update the previous buffer information for current window */
void _switchbuf_emacs(_str old_buffer_name, _str options="")
{
   if ( p_DocumentName==old_buffer_name || p_buf_name==old_buffer_name || old_buffer_name=='' || options=='W') {
      return;
   }
   _str filename;
   get_window_info(p_window_id,filename)  /* Place sbuffer cursor */;
   int view_id;
   get_window_id(view_id);
   int window_id=p_window_id;
   activate_window(sbuffer_view_id);
   if ( _on_line0() ) {
      insert_line(window_id' 'old_buffer_name);
   } else {
      replace_line(window_id' 'old_buffer_name);
   }
   activate_window(view_id);
}
static void get_default_sb(var filename)
{
   get_window_info(p_window_id,filename);
   if ( file_eq(p_buf_name,absolute(filename)) || filename=='' ||
      buf_match(filename,1)=='' ) {
      filename='';
      _str old_buffer_name=p_buf_name;
      _prev_buffer();
      if ( p_buf_name!=old_buffer_name ) {
         filename=p_buf_name;
      }
      _next_buffer();
   }

}

/**
 * Used in EMACS emulation.  Same as <b>gui_find</b> command except that the 
 * search direction is initially backward and regular expressions are turned on.
 * 
 * @appliesTo Edit_Window
 * 
 * @categories Edit_Window_Methods, Search_Functions
 * 
 */
_command gui_find_backward_regex() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   if ( def_re_search==UNIXRE_SEARCH ) {
      return( gui_find('-u') );
   } else if ( def_re_search==BRIEFRE_SEARCH ) {
      return( gui_find('-b') );
   } else {
      return( gui_find('-r') );
   }
}
/**
 * Used in EMACS emulation.  Same as <b>gui_find</b> command except that regular expressions 
 * are turned on.
 * 
 * @appliesTo Edit_Window
 *
 * @categories Edit_Window_Methods, Search_Functions
 * 
 */
_command gui_find_regex() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   if ( def_re_search==UNIXRE_SEARCH ) {
      return( gui_find('u') );
   } else if ( def_re_search==BRIEFRE_SEARCH ) {
      return( gui_find('b') );
   } else {
      return( gui_find('r') );
   }
}
/**
 * 
 * Used in EMACS emulation.  Same as <b>gui_replace</b> command except 
 * that  regular expressions are turned on.
 * 
 * @appliesTo Edit_Window
 *
 * @categories Edit_Window_Methods, Search_Functions
 * 
 */
_command gui_replace_regex() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   if ( def_re_search==UNIXRE_SEARCH ) {
      return( gui_replace('u') );
   } else if ( def_re_search==BRIEFRE_SEARCH ) {
      return( gui_replace('b') );
   } else {
      return( gui_replace('r') );
   }
}
