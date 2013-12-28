////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47103 $
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
#import "autocomplete.e"
#import "bind.e"
#import "codehelp.e"
#import "context.e"
#import "listbox.e"
#import "markfilt.e"
#import "seek.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "util.e"
#import "dlgeditv.e"
#endregion

struct Match {
   _str word;
   int line_to_goto; //used for partial searching to restore the search position (roughly)
   typeless lineoffset;
   int col; //imaginary column position of the match
};

struct FuncExtent {
   typeless line_begin;
   typeless line_end;
};

static FuncExtent extent;
static boolean gWordHits:[]; //hash table to store the already tried matches
static Match gback_matches[]; //array containing the possible matches before the cursor
static Match gforward_matches[]; //array containing the possible matches after the cursor
static Match gprefix;
static _str glast_inserted_match;  //contains the text that was inserted during the last complete-prev/next (for skipping matches)
static int gline_prefix_is_on=0;  //used to setup initial line in selection list
#define COMPLETE_REVERSE_AT_CURSOR 0x1
#define COMPLETE_CHECK_SCOPE 0x2
#define COMPLETE_ALLOW_DUP_MATCHES 0x4
#define COMPLETE_LOOK_FOR_ANYTHING 0x8

/**
 * Word completion options.  Bitset of the following flags (COMPLETE_*)
 * <ul>
 * <li><b>COMPLETE_REVERSE_AT_CURSOR</b> Indicates that the 
 * "duplicate locations" cache should be cleared after changing
 * directon. Don't confuse this cache with the "duplicates 
 * words" cache which the COMPLETE_ALLOW_DUP_MATCHES uses.
 * <li><b>COMPLETE_CHECK_SCOPE</b> -- Indicates whether matches 
 * was found outside of scope of function.
 * <li><b>COMPLETE_ALLOW_DUP_MATCHES</b> -- Indicates that once 
 * a particular word is found that any subsequent matches should
 * be skipped. After change directions (i.e.  say do a 
 * complete_prev,complete_prev, and then a complete_next), the 
 * "duplicate words" cache is cleared. 
 * <li><b>COMPLETE_LOOK_FOR_ANYTHING</b> -- When off, applies 
 * some heuristics. By default (no COMPLETE_LOOK_FOR_ANYTHING flag),
 * matches found in comments or strings are skipped if the
 * cursor was not in a comment or string and the match is "far" 
 * away from the cursor (2 lines- second number from 
 * def_complete_vars).
 * </ul>
 * 
 * @default COMPLETE_REVERSE_AT_CURSOR|COMPLETE_ALLOW_DUP_MATCHES
 * @categories Configuration_Variables
 * 
 * @see complete_next
 * @see complete_prev
 * @see complete_more
 */
int def_complete_flags=COMPLETE_REVERSE_AT_CURSOR|COMPLETE_ALLOW_DUP_MATCHES;

/**
 * If we're in a comment or string, check everywhere.
 * If not, just look for variables (not color coded).
 * <p>
 * First value is on/off, second value is allow any match (color coded or not)
 * within [value] lines from the cursor position (of the 
 * prefix).  The first value is redundant with the 
 * COMPLETE_LOOK_FOR_ANYTHING flag.  This could be cleaned up.
 * 
 * @default "1 2" 
 * @categories Configuration_Variables
 * 
 * @see complete_next
 * @see complete_prev
 * @see complete_more
 */
_str def_complete_vars="1 2";

static _str complete_cur_word(int &word1_pos)
{
   boolean moved=0;
   if (p_col>1) {
      left();  //so get the proper color if the string isn't terminated
      moved=1;
   }
   _str cur_char=get_text(-1);
   _str cur_byte=get_text();
   if (moved) {
      right();
   }
   _str last_match='';
   int old_col=p_col;
   word_chars := _extra_word_chars:+p_word_chars;
   if (!(pos('[\od'word_chars']',cur_char,1,'R') || (!p_UTF8 && _dbcsIsLeadByte(cur_byte)))) { //if current character isn't a wordchar, don't use cur_word
      //not a word char
      last_match='';
      word1_pos=p_col;
   } else {
#if 0
      last_match=cur_word(word1_pos,'',1);
      word1_pos=_text_colc(word1_pos,"I");
      messageNwait('word1pos='word1_pos);
#else
      left();
      int status=search('([~\od'word_chars"]|^)\\c","@ir-");
      int start_col=p_col;
      last_match=_expand_tabsc(start_col,old_col-start_col);
      p_col=old_col;
      word1_pos=start_col; //already imaginary
      //messageNwait('last_match='last_match' w1p='word1_pos);
#endif
   }
   return(last_match);
}
static void complete_get_extent(FuncExtent &extent)
{
   if (def_complete_flags & COMPLETE_CHECK_SCOPE) {
      typeless junk;
      save_pos(junk);
      int status=select_proc('',-1,1);
      if (!status) {
         begin_select();
         extent.line_begin=point();
         end_select();
         extent.line_end=point();
         deselect();
      } else {
         extent.line_begin=0;
         extent.line_end=0;
      }
      restore_pos(junk);
   } else {
      extent.line_begin=0;
      extent.line_end=0;
   }
}
static boolean complete_get_look_for_anything(int color, _str word='')
{
   boolean look_for_anything;
   if (def_complete_flags&COMPLETE_LOOK_FOR_ANYTHING || color==CFG_COMMENT || color==CFG_STRING) {
      look_for_anything=1;
   } else {
      _str ext=_get_extension(p_buf_name);
      if (p_lexer_name=="") {
         look_for_anything=1;
      } else {
         look_for_anything=(file_eq("."ext,_macro_ext) && substr(word,1,2)=="p_");
      }
   }
   return look_for_anything;
}
static int complete_nextprev(Match (&matches)[],boolean doNext,_str exactWord='')
{
   static int index,more_matches;
   static boolean look_for_anything;

   int old_last_index=last_index('','C');
   int old_prev_index=prev_index('','C');

   _str next,prev;
   if (doNext) {
      next='next';
      prev='prev';
   } else {
      next='prev';
      prev='next';
   }
   _str last_match='';
   boolean reverse_at_cursor=false;
   int howlong=matches._length(); //we'll use it several times

   // Initialize gprefix if this is first time in here
   if (gprefix==null) {
      int word1_pos=0;
      gprefix.word=complete_cur_word(word1_pos);
      gprefix.line_to_goto=(int)point('L');
      gprefix.lineoffset=point();
      gprefix.col=p_col;
   }

   // IF we are going in the same direction.
   int color=0;
   int word1_pos=0;
   boolean replacing=false;
   boolean moved=false;
   _str prev_cmd = name_name(prev_index('','C'));
   if ( pos('complete-'next, prev_cmd) == 1 ) { 
      last_match=complete_cur_word(word1_pos);
      replacing=1;
      ++index;
      if (index >= howlong && more_matches) { //check if there are any more matches to be gotten
         //we're out of matches, need to get another one
         more_matches=find_dynamic_completions(gprefix,last_match,1,doNext,0,look_for_anything,0,
                                               gback_matches,gforward_matches,gWordHits);
      } else {
         return(0);
#if 0    //this code will allow you to wrap around when you reach the end of the matches
         //we've wrapped around and we want to set index back to 0
         if (index > howlong) {
            //messageNwait('setting index to 0 wrapped around');
            index=0;
         }
#endif
      }
   } else {
      boolean doExactMatch= exactWord!='';
      // IF we reversed direction
      if ( pos('complete-'prev, prev_cmd) == 1 ) { //other one was used
#if 0
         if (def_complete_flags & COMPLETE_REVERSE_BLASTS_WORD_HIT_TABLE) {
            //messageNwait("complete_nextprev: got here h2");
            gWordHits._makeempty();
         }
#endif
         last_match=complete_cur_word(word1_pos);
         //messageNwait('word1pos='word1_pos);
         //don't want to mess with gprefix
         replacing=1;

         if (def_complete_flags & COMPLETE_REVERSE_AT_CURSOR) {
            //so we will not init and restore the line of the last match in the opposite direction
            //messageNwait('setting reverse at cursor');
            reverse_at_cursor=true;
            gWordHits._makeempty(); //blow away the hash table so we find things we've already seen
         } else {
            //init
            reverse_at_cursor=false;
         }

         // may need to find more completions if they reversed before getting to the end
         more_matches=find_dynamic_completions(gprefix,last_match,1,doNext,0,look_for_anything,reverse_at_cursor,
                                               gback_matches,gforward_matches,gWordHits,doExactMatch);
         index=0;
      } else {
         _undo('S'); //so we can back out with one step

         // set up the scope of the completion search extent
         complete_get_extent(extent);

         // get the current word for completion
         gprefix.word=complete_cur_word(word1_pos);
         gprefix.line_to_goto=(int)point('L');
         gprefix.lineoffset=point();
         gprefix.col=p_col;
         moved=0;
         if (p_col>1) {
            left();  //so get the proper color if the string isn't terminated
            moved=1;
         }
         color=_clex_find(0,"g");
         if (moved) {
            right();
         }
         look_for_anything = complete_get_look_for_anything(color,gprefix.word);
         //clobber hash table
         gWordHits._makeempty();

         //I don't think this is usefull anymore
         if (gprefix.word=='') { //this allows it to work if there is no gprefix
            word1_pos=p_col;
         } else {
            if (word1_pos + _rawLength(gprefix.word) != p_col) {
               gprefix.word='';word1_pos=p_col;
            }
         }
         replacing=0;
         if (exactWord!='') {
            gprefix.word=exactWord;
            word1_pos=p_col-_rawLength(exactWord);
         }
         more_matches=find_dynamic_completions(gprefix,'',1,doNext,1,look_for_anything,reverse_at_cursor,
                                               gback_matches,gforward_matches,gWordHits,doExactMatch);
         index=0;
      }
   }
   //figure out what word to use
   howlong=matches._length(); //it might have changed since the init stuff
   //messageNwait('howlong='howlong' index='index' mm='more_matches);
   int index_for_display=0;
   _str word='';
   if (index <= howlong && more_matches) {
      word=matches[index].word;
      index_for_display=index;
   } else {
      if (index == howlong) {
         _beep();
         message("No more expansions for '"gprefix.word"' found.");
         word=gprefix.word;
         index_for_display=-1;
      } else {
         //message("wrapping around index="index);
         //index=0;
         word=matches[index].word;
         index_for_display=index;
      }
      if (last_match!='') {
         replacing=1;
      }
   }
   //replace the word with new word
   _str line='';
   get_line_raw(line);
   word1_pos=_text_colc(word1_pos,'P'); //convert word1_pos from imaginary to physical for this
   _str begin_of_line=substr(line,1,word1_pos-1);
   //begin_of_line=expand_tabs(line,1,word1_pos-1);

   _str end_of_line='';
   if (replacing) {
      end_of_line=substr(line,word1_pos+_rawLength(last_match));  //get rest of line
      //end_of_line=expand_tabs(line,word1_pos+length(last_match));  //get rest of line
   } else {
      end_of_line=substr(line,word1_pos+_rawLength(gprefix.word));  //get rest of line
      //end_of_line=expand_tabs(line,word1_pos+length(gprefix));  //get rest of line
   }
   _str raw_word=word;
   if (exactWord != '') {
      word = raw_word = exactWord;
      //end_of_line='';
   }
   if (!p_UTF8) {
      raw_word=_UTF8ToMultiByte(word);
   }
   if (!p_UTF8) {
      line=begin_of_line:+raw_word:+end_of_line;
   } else {
      line=begin_of_line:+word:+end_of_line;
   }
   //messageNwait('begin_of_line='begin_of_line' endline='end_of_line' word='word);
   replace_line_raw(line);
   //convert word1_pos from physical to imaginary for this
   word1_pos=_text_colc(word1_pos,'I');
   p_col=word1_pos+length(raw_word); //set cursor position to end of the new word

   // adjust column if we are reverse searching and find a match on the same line as the current word
   int adjust = 0;
   if (index_for_display>=0) {
      if (point('L') == matches[index].line_to_goto && p_col < matches[index].col && !doNext ) {
         adjust = _rawLength(last_match)-length(raw_word);
      }
   }

   //at this point index_for_display should be set to the index we need, or -1 for none
   if (index_for_display>=0) {
      if (p_EmbeddedCaseSensitive?word==gprefix.word:strieq(word,gprefix.word)) { //found the same thing, go left so we display properly
         show_what_would_be_grabbed(matches[index],matches[index].col-1-adjust,1,0);
      } else {
         show_what_would_be_grabbed(matches[index],matches[index].col-adjust,1,0);
      }
   }

   //reset indexes
   last_index(old_last_index,'C');
   prev_index(old_prev_index,'C');

   glast_inserted_match=word; //so we can skip if we need to
   return(1);
}

//default keybinding C-S-,
/**
 * Retrieves previous word or variable which is a prefix match of the word
 * at the cursor.  If the macro variable "def_complete_vars" is 1 and the
 * word prefix at the cursor is NOT color coded as a string or comment,
 * only variables are retrieved.  However, the integer macro variable
 * "def_complete_var_range" overrides restricting searching to variables
 * for a specified number of lines before and after the cursor.  A value
 * of 1 indicates to include all words on the current line.
 *
 * @see complete_next
 * @see complete_list
 * @see complete_next_match
 * @see complete_prev_match
 * @see complete_more
 *
 * @categories Completion_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command void complete_prev(_str exactWord='') name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOUNDOS)
{
   if (command_state()) {
      message("The complete word commands cannot be used on the command line.");
      return;
   }
   complete_nextprev(gback_matches,false,exactWord);
}

//default keybinding C-S-.
/**
 * Retrieves next word or variable which is a prefix match of the word
 * at the cursor.  If the macro variable "def_complete_vars" is 1 and
 * the word prefix at the cursor is NOT color coded as a string or comment,
 * only variables are retrieved.  However, the integer macro variable
 * "def_complete_var_range" overrides restricting searching to variables
 * for a specified number of lines before and after the cursor.  A value
 * of 1 indicates to include all words on the current line.
 *
 * @see complete_prev
 * @see complete_list
 * @see complete_next_match
 * @see complete_prev_match
 * @see complete_more
 *
 * @categories Completion_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command void complete_next(_str exactMatch='') name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOUNDOS)
{
   if (command_state()) {
      message("The complete word commands cannot be used on the command line.");
      return;
   }
   complete_nextprev(gforward_matches,true,exactMatch);
}

static void completion_list_callback(int sl_event,_str &result,_str info)
{
   static int orig_line;

   switch (sl_event) {
   case SL_ONINIT:
      _sellist.p_line=gline_prefix_is_on+1; //lb is origin 1
      _sellist._lbselect_line();
      orig_line=gline_prefix_is_on+1;
      gline_prefix_is_on=0;
      break;
   case SL_ONSELECT:
      if (_sellist.p_line < orig_line) {
         gline_prefix_is_on=_sellist.p_line * -1; //changing the value to reflect the array entry of the selected match
      } else {
         if (_sellist.p_line==orig_line) {
            gline_prefix_is_on=0;
         } else {
            gline_prefix_is_on=_sellist.p_line-orig_line; //changing the value to reflect the array entry of the selected match
         }
      }
      break;
   default:
      break;
   }

}

//default keybinding none


/**
 * Displays a list or words or variables which are a prefix match of the 
 * word at the cursor.  If the macro variable "def_complete_vars" is 1 and 
 * the word prefix at the cursor is NOT color coded as a string or comment, 
 * only variables are retrieved.  However, the integer macro variable 
 * "def_complete_var_range" overrides restricting searching to variables 
 * for a specified number of lines before and after the cursor.  A value 
 * of 1 indicates to include all words on the current line.
 * 
 * @see complete_prev
 * @see complete_next
 * @see complete_next_match
 * @see complete_prev_match
 * @see complete_more
 * 
 * @categories Completion_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command complete_list() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOUNDOS)
{
   static int index,more_matches,was_on;
   _str whole_list[];


   if (command_state()) {
      message("The complete word commands cannot be used on the command line.");
      return('');
   }
   //turn off allowing dup matches because it doesn't make sense here
   if (def_complete_flags&COMPLETE_ALLOW_DUP_MATCHES) {
      was_on=1;
      def_complete_flags=def_complete_flags ^ COMPLETE_ALLOW_DUP_MATCHES;
   }

   int old_last_index=last_index('','C');
   int old_prev_index=prev_index('','C');

   _undo('S'); //so we can back out with one step

   // set up the scope of the completion search extent
   complete_get_extent(extent);

   int word1_pos=0;
   gprefix.word=complete_cur_word(word1_pos);
   gprefix.line_to_goto=(int)point('L');
   gprefix.lineoffset=point();
   gprefix.col=p_col;
   int color=_clex_find(0,"g");
   boolean look_for_anything = complete_get_look_for_anything(color,gprefix.word);

   //clobber hash table
   gWordHits._makeempty();
#if 0
   if (gprefix.word=='') { //this allows it to work if there is no gprefix
      word1_pos=p_col;
   } else {
      if (word1_pos + length(gprefix.word) != p_col) {
         gprefix.word='';word1_pos=p_col;
      }
   }
#endif
   boolean replacing=0;
   more_matches=find_dynamic_completions(gprefix,'',0,0,1,look_for_anything,0,  //full_search,forward,init, match anything?
                                         gback_matches,gforward_matches,gWordHits); 
   index=0;

   //build list of forward and backward matches
   int i,j=0;
   for (i=gback_matches._length()-1;i>=0;i--) {  //back to front
      whole_list[j]=gback_matches[i].word;
      ++j;
   }
   //put gprefix in the list
   whole_list[j]=gprefix.word;
   gline_prefix_is_on=j;
   ++j;
   for (i=0;i<=gforward_matches._length()-1;i++) {
      whole_list[j]=gforward_matches[i].word;
      ++j;
   }

   //messageNwait('old_last_index='name_name(old_last_index)' old_prev_index='name_name(old_prev_index));
   _str word=show('-modal _sellist_form',
            'Pick A Completion',
            0,// flags
            whole_list,// input_data
            "",// buttons
            //'?This is a help message', // help item
            'complete_list', // help item
            '',   // font
            completion_list_callback,   // Call back function
            '',   // Item separator for list_data
            '',   // Retrieve form name
            '',   // Combo box. Completion property value.

            '',   // minimum list width
            '' // Combo Box initial value
           );

   if (word=='') {
      word=gprefix.word;
   }
   word1_pos=_text_colc(word1_pos,'P'); //convert word1_pos from imaginary to physical for this
   _str line='';
   get_line_raw(line);
   _str begin_of_line=substr(line,1,word1_pos-1);
   _str end_of_line=substr(line,word1_pos+_rawLength(gprefix.word));  //get rest of line
   line=begin_of_line:+_rawText(word):+end_of_line;
   //messageNwait('begin_of_line='begin_of_line' endline='end_of_line' word='word);
   replace_line_raw(line);
   //convert word1_pos from physical to imaginary for this
   word1_pos=_text_colc(word1_pos,'I');
   p_col=word1_pos+_rawLength(word); //set cursor position to end of the new word

   //at this point, gline_prefix_is_on should be set to the index into the array where we found the match
   int idx=gline_prefix_is_on;
   Match match;
   if (idx < 0) {
      //backward
      idx*=-1;
      idx=gback_matches._length()-idx;  //since the backward matches are in reverse order of the listbox
      match=gback_matches[idx];

   } else {
      if (idx==0) {  //so we don't blow up when the person chooses the prefix
         prev_index(old_prev_index,'C');
         last_index(old_last_index,'C');
         //turn it back on
         if (was_on) {
            def_complete_flags=def_complete_flags | COMPLETE_ALLOW_DUP_MATCHES;
         }
         return('');
      }
      idx-=1;
      match=gforward_matches[idx];
   }

   show_what_would_be_grabbed(match,match.col,1,0);

   //reset the indexes
   prev_index(old_prev_index,'C');
   last_index(old_last_index,'C');

   glast_inserted_match=word; //so we can skip if we need to

   //turn it back on
   if (was_on) {
      def_complete_flags=def_complete_flags | COMPLETE_ALLOW_DUP_MATCHES;
   }
}

void _autocomplete_more(_str insertWord,_str prefix,int &removeStartCol,int &removeLen,boolean onlyInsertWord)
{
   p_col -= length(prefix);
   _delete_text(length(prefix));
   _insert_text(insertWord);
   if (onlyInsertWord) return;
   prev_index(0,'C');
   complete_more();
}
void _autocomplete_prev(_str insertWord,_str prefix,int &removeStartCol,int &removeLen,boolean onlyInsertWord,struct VS_TAG_BROWSE_INFO symbol)
{
   int rawlen=_rawLength(prefix);
   p_col -= rawlen;
   _str line;
   _delete_text(rawlen);
   _insert_text(insertWord);
   if (onlyInsertWord) return;
   prev_index(0,'C');
   complete_prev(insertWord);
}
void _autocomplete_next(_str insertWord,_str prefix,int &removeStartCol,int &removeLen,boolean onlyInsertWord,struct VS_TAG_BROWSE_INFO symbol)
{
   p_col -= length(prefix);
   _delete_text(length(prefix));
   _insert_text(insertWord);
   if (onlyInsertWord) return;
   prev_index(0,'C');
   complete_next(insertWord);
}

static void goto_completion(Match match)
{
   if (match.line_to_goto > 0) {
      p_line = match.line_to_goto;
   } else if (gprefix!=null && gprefix.word && gprefix.lineoffset < match.lineoffset) {
      goto_point(match.lineoffset + length(match.word) - length(gprefix.word));
   } else {
      goto_point(match.lineoffset);
   }
   if (match.col > 0) {
      p_col = match.col;
   }
}

int find_complete_list_completions(var words, int max_matches, _str prefixexp="", boolean forceUpdate=false)
{
   // get the word under the cursor
   int word1_pos=0;
   _str orig_word = complete_cur_word(word1_pos);
   if (!forceUpdate && orig_word == '') {
      return STRING_NOT_FOUND_RC;
   }

   if (prefixexp != "") {
      orig_word = prefixexp:+orig_word;
   }
   // set up match prefix
   Match prefix;
   prefix.word=orig_word;
   prefix.line_to_goto=(int)point('L');
   prefix.lineoffset=point();
   prefix.col=p_col;
   int color=_clex_find(0,"g");
   boolean look_for_anything = complete_get_look_for_anything(color,orig_word);

   //clobber hash table
   Match back_matches[];     // matches found in reverse direction
   Match forward_matches[];  // matches found in forward direction
   boolean word_matches:[];  // hash table to store the already tried matches
   find_dynamic_completions(prefix,'',false,false,1,look_for_anything,0, //partial_search,forward,init, match anything?
                            back_matches,forward_matches,word_matches,false,max_matches/2+1); 

   // make sure we do not add the same word twice
   int i=0;
   boolean found_matches:[];
   found_matches._makeempty();

   // save the cursor position to restore later
   int col=0;
   _str line='';
   save_pos(auto p);

   // get picture indexes for complete-prev and complete-next
   if (!_pic_complete_prev) {
      _pic_complete_prev = load_picture(-1,'_complete_prev.ico');
      if (_pic_complete_prev >= 0) {
         set_name_info(_pic_complete_prev, 'Word completion on earlier line in file');
      }
   }
   if (!_pic_complete_next) {
      _pic_complete_next = load_picture(-1,'_complete_next.ico');
      if (_pic_complete_next >= 0) {
         set_name_info(_pic_complete_next, 'Word completion on subsequent line in file');
      }
   }

   // backward matches
   int num_words=0;
   for (i=0; i<=back_matches._length()-1; i++) {

      // already saw this match?
      if (found_matches._indexin(back_matches[i].word)) {
         continue;
      }
      found_matches:[back_matches[i].word]=true;

      // get the rest of the line, use it as a comment
      goto_completion(back_matches[i]);
      get_line_raw(line);
      col=_text_colc(back_matches[i].col-_rawLength(orig_word),'P');  //convert to physical
      line = substr(line,col);
      _escape_html_chars(line);

      // Same word?
      if (back_matches[i].word == orig_word) {
         AutoCompleteFoundExactMatch();
         continue;
      }

      // Too many matches?
      if (++num_words > max_matches) {
         break;
      }

      int lineno = (int)point('L');

      // set up browse information in order to show preview
      VS_TAG_BROWSE_INFO cm;
      tag_browse_info_init(cm);
      cm.file_name=p_buf_name;
      cm.line_no=lineno;
      cm.column_no=p_col;

      // trim the prefix expression off of the word match if necessary
      found_word := back_matches[i].word;
      if (pos(prefixexp,found_word) == 1) {
         found_word = substr(found_word,length(prefixexp)+1);
      }

      // Add the result to auto complete
      AutoCompleteAddResult(words, 
                            AUTO_COMPLETE_WORD_COMPLETION_PRIORITY,
                            found_word, 
                            _autocomplete_prev,
                            line:+"<hr>":+AutoCompleteParagraphTag():+
                            ((lineno > 0) ? 'Word found on line ':+lineno:+' in current file' : 'Word found in current file'),
                            cm,
                            true,
                            _pic_complete_prev);
   }

   // forward matches
   for (i=0; i<=forward_matches._length()-1; i++) {

      // already saw this match?
      if (found_matches._indexin(forward_matches[i].word)) {
         continue;
      }
      found_matches:[forward_matches[i].word]=true;

      // get the rest of the line, use it as a comment
      goto_completion(forward_matches[i]);
      get_line_raw(line);
      col=_text_colc(forward_matches[i].col-_rawLength(orig_word),'P');  //convert to physical
      line = substr(line,col);
      _escape_html_chars(line);

      // Same word?
      if (forward_matches[i].word == orig_word) {
         AutoCompleteFoundExactMatch();
         continue;
      }

      // Too many matches?
      if (++num_words > max_matches) {
         break;
      }

      int lineno = (int)point('L');

      // set up browse information in order to show preview
      VS_TAG_BROWSE_INFO cm;
      tag_browse_info_init(cm);
      cm.file_name=p_buf_name;
      cm.line_no==lineno;
      cm.column_no=p_col;

      // trim the prefix expression off of the word match if necessary
      found_word := forward_matches[i].word;
      if (pos(prefixexp,found_word) == 1) {
         found_word = substr(found_word,length(prefixexp)+1);
      }

      // Add the result to auto complete
      AutoCompleteAddResult(words, 
                            AUTO_COMPLETE_WORD_COMPLETION_PRIORITY,
                            found_word, 
                            _autocomplete_next,
                            line:+"<hr>":+AutoCompleteParagraphTag():+
                            ((lineno > 0)? 'Word found on line ':+lineno:+' in current file' : 'Word found in current file'),
                            cm,
                            true,
                            _pic_complete_next);
   }

   // that's all folks
   restore_pos(p);
   return 0;
}

//before means add before line with gprefix
static add_to_list(_str word,int before,_str prefix,boolean sameline,int orig_line_length,
                   Match (&back_matches)[], Match (&forward_matches)[])
{
   int where=0;
   if (before) {
      where=back_matches._length();
      back_matches[where].word=word;
      back_matches[where].line_to_goto=(int)point('L');
      back_matches[where].lineoffset=point();
      back_matches[where].col=p_col;
      //messageNwait('adding word='word' bm.word='back_matches[where].word' index='where' line='back_matches[where].line_to_goto);
   } else {
      where=forward_matches._length();
      forward_matches[where].word=word;
      //messageNwait(nls('got here set forward_matches'));
      forward_matches[where].line_to_goto=(int)point('L');
      forward_matches[where].lineoffset=point();
      //forward_matches[where].col=p_col;

      if (sameline) {                  //not good enough.  need to know the difference between orig line and line after replace
         int current_line_length=_text_colc(1);
         int line_difference=current_line_length - orig_line_length;
         forward_matches[where].col=p_col-line_difference+(_rawLength(word)-_rawLength(prefix)); //adjust for the prefix being added in
      } else {
         forward_matches[where].col=p_col;
      }
      //messageNwait('adding word='word' fm.word='forward_matches[where].word' index='where' line='forward_matches[where].line_to_goto);
   }
}

int def_word_completion_kmax=100; //+ or -100k
/**
 * Find completions for the given match prefix within the current buffer.
 * 
 * @param prefix              match prefix to search based on
 * @param last_match          the last word match we displayed
 * @param partial_search      just add the next match rather than filling whole list
 * @param forward             search forward (reverse search if 0)
 * @param init                initialize arrays?
 * @param look_for_anything   limit the search to non color coded items (variables)
 *                            if the search is started outside of a comment or string.
 *                            If starting inside a comment or string, anything can be matched.
 * @param reverse_at_cursor   tells us not to init, and restores the line position of
 *                            the last match in the opposite direction, then initialize
 * @param back_matches        list of matches found in reverse search
 * @param forward_matches     list of matches found in forward search
 * @param word_matches        hash table to store the already tried matches
 * 
 * @return 0 if it found all matches, 1 if it finds a partial list
 */
static int find_dynamic_completions(Match prefix, _str last_match,
                                    boolean partial_search, boolean forward,
                                    int init, boolean look_for_anything,
                                    boolean reverse_at_cursor,
                                    Match (&back_matches)[],
                                    Match (&forward_matches)[],
                                    boolean (&word_matches):[],
                                    boolean doExactMatch=false,
                                    int limit=1000)
{
   static int pre_search_col,orig_line_length;
   static typeless pre_search_line;
   typeless restrict_to_vars='';
   typeless lines_ok='';
   parse def_complete_vars with restrict_to_vars lines_ok;

   if (p_lexer_name=="") {
      restrict_to_vars=0;
   }

   // so we don't nuke partial searches unless we're starting over
   if (init && !reverse_at_cursor) {  
      //messageNwait('blowing away the arrays');
      back_matches._makeempty();
      forward_matches._makeempty();
   }

   if (!partial_search) { //if we're looking for everything, don't look for prefix
      word_matches:[prefix.word]=1; //so we don't match the prefix alone
   }
   typeless junk;
   if (prefix.word!='' && !partial_search) { //so if prefix is '', we will find the first word back
      word_matches:[cur_word(junk,'',1)]=1; //so we won't stop on the prefix if it's butt up against other chars
   }
   _str re='';
   word_chars := _extra_word_chars:+p_word_chars;
   if (doExactMatch) {
      re='(^|[~\od'word_chars']+){#00'_escape_re_chars(prefix.word)'\c([~\od'word_chars']|$)#}';  //minimal match of 1 or more !word_chars followed by prefix+rest
   } else {
      if (prefix.word!='' && prefix.word!=null) {
                                                                //the | nothing below allows you to match the prefix, but not the same one
         re='(^|[~\od'word_chars']+){#00'_escape_re_chars(prefix.word)'\c([\od'word_chars']|)#}';  //minimal match of 1 or more !word_chars followed by prefix+rest
                                                // ^ place the cursor so we can check color coding
      } else {
         //if prefix is '', don't allow nothing to match as in the one above
         re='(^|[~\od'word_chars']+){#00\c[\od'word_chars']#}';
      }
   }

   typeless p;
   _save_pos2(p);
   if (init) {
      /*
         only do this if initing.  This won't allow something to be counted as a word
         if the prefix is butt up against it on the right.
      */
      pre_search_col=p_col;  //fixes problem with prefix '' and on same line
      pre_search_line=point();
      orig_line_length=_text_colc(1);
   }
   _str searchInSelection='';
   _str markid='';
   _str orig_markid='';
   // if we are filling a list of possible prefix matches
   if (!partial_search) {
      searchInSelection='m';
      orig_markid=_duplicate_selection('');
      markid=_alloc_selection();
      long start_seek=_nrseek();
      long value=start_seek-(def_word_completion_kmax*1024);
      if (value<0) value=0;
      _nrseek(value);
      _select_line(markid);
      _nrseek(start_seek+(def_word_completion_kmax*1024));
      _select_line(markid);
      _show_selection(markid);

      _restore_pos2(p);
      _save_pos2(p);
   }

   //searching backwards for last match
   //messageNwait('about to search backward');
   typeless status=0;
   boolean ok_to_go=false;
   _str word='';
   _str case_opt='';
   int back_idx=0;
   int forward_idx=0;
   if ((partial_search && !forward) || !partial_search) {  //only do it if full search or partial backward
      //messageNwait('in backward');
      if (!init || reverse_at_cursor) {

         back_idx=back_matches._length()-1;
         forward_idx=forward_matches._length()-1;

         if (reverse_at_cursor) {
            //messageNwait('reversing at cursor');
            //restore line of last match in opposite direction
            if (forward) {
               if (back_idx >=0) {
                  goto_completion(back_matches[back_idx]);
                  //messageNwait('line should be set to last backward match end of line');
               }
            } else {
               if (forward_idx >= 0) {
                  //put us on the line where the last match was found
                  if (forward_idx > 0 && last_match!=gprefix.word) --forward_idx;
                  goto_completion(forward_matches[forward_idx]);
                  //messageNwait('line should be set to last forward match  end of line -1 line');
               }
            }
            //init the match arrays
            back_matches._makeempty();
            forward_matches._makeempty();
         } else {
            if (back_idx >=0) {
               goto_completion(back_matches[back_idx]);
            }
         }
      }
      //messageNwait('beginning backward search re='re);

      word='';
      case_opt=(p_EmbeddedCaseSensitive)?'':'i';
      status=search(re,searchInSelection'R@-<'case_opt);
      //messageNwait('status='status);
      if (point()==pre_search_line && p_col==pre_search_col) {
         status=repeat_search(); //get us off of the same thing
         //messageNwait('after');
      }
      for (;;) {
         if (status) {
            //messageNwait('breaking backward, not found');
            break;
         }
         word=get_match_text(0);
         //word2=cur_word(junk);
         if (word_matches:[word]==1 && !(def_complete_flags&COMPLETE_ALLOW_DUP_MATCHES)) {
            //messageNwait('skipping 'word);
         } else {
            ok_to_go=1;
            //messageNwait('presc='pre_search_col' col='p_col' pline='p_line' pre_search_line='pre_search_line);
            if (restrict_to_vars) {
               //if it's not color coded and we're not looking for anything
               if (_clex_find(COMMENT_CLEXFLAG|STRING_CLEXFLAG,"T") && !look_for_anything) {
                  ok_to_go=0;
                  //messageNwait('ditched color coding');
               }
               if (abs(prefix.line_to_goto - (int)point('L')) < lines_ok) { //if we're within the limit any match is allowed
                  ok_to_go=1;
                  //messageNwait('ok whthin range');
               }
            }
            if (p_col == pre_search_col && point() == pre_search_line) {   //so we don't pick up a match to the right on a '' prefix
               ok_to_go=0;
               //messageNwait('ditched col stuff');
            }

            //If we're allowing duplicate matches, turn off the hit and don't allow the word to be added
            if (ok_to_go && word_matches:[word]==1 && (def_complete_flags&COMPLETE_ALLOW_DUP_MATCHES)) {
               //messageNwait('got to my case');
               ok_to_go=0;
               word_matches:[word]=0;
            }
            if (ok_to_go) {
               word_matches:[word]=1; //so we won't match it again
               //add word to the list
               if (back_matches._length() > limit) {
                  break;
               }
               add_to_list(word,1,prefix.word,(point()==pre_search_line),orig_line_length,back_matches,forward_matches);

               //if we're partial searching, we're done, restore pos and return yes to more matches
               if (partial_search) {
                  _restore_pos2(p);
                  return(1);
               }
            }
         }
         status=repeat_search();
      }

   }
   //searching forwards for matches
   _restore_pos2(p); //get back to where we started
   _save_pos2(p); //so we can go back
   if ((partial_search && forward) || !partial_search) {  //only do it if full search or partial forward
      if (!init || reverse_at_cursor) {

         back_idx=back_matches._length()-1;
         forward_idx=forward_matches._length()-1;

         if (reverse_at_cursor) {
            //messageNwait('reversing at cursor forward');
            //restore line of last match in opposite direction
            if (forward) {
               if (back_idx >= 0) {
                  goto_completion(back_matches[back_idx]);
                  if (last_match == gprefix.word) {
                     if (p_col > 1) {
                        p_col--;
                        p_col--;
                     } else {
                        up();
                        _end_line();
                     }
                  }
                  //_end_line();
                  //messageNwait('line should be set to last backward match end of line');
               }
            } else {
               if (forward_idx >= 0) {
                  goto_completion(forward_matches[forward_idx]);
                  p_col=forward_matches[forward_idx].col-2;  //the -2 is so we will find the last match again
                  if (last_match == gprefix.word) {
                     down();
                     _begin_line();
                  }
                  //_begin_line();
                  //messageNwait('line should be set to last forward match begin of line +1');
               }
            }
            //init the match arrays
            back_matches._makeempty();
            forward_matches._makeempty();
         } else {
            if (forward_idx >=0) {
               goto_completion(forward_matches[forward_idx]);
               if (!(def_complete_flags&COMPLETE_ALLOW_DUP_MATCHES)) {
                  p_col=forward_matches[forward_idx].col-2;   //the -2 is so we will find the last match again
               }else{
                  p_col=forward_matches[forward_idx].col; //Dan took off the -2
               }
               //_begin_line();
            }
         }
      }
      //messageNwait('beginning forward search line should be adjusted already');
      //messageNwait('about to search forward re='re">");
      word='';
      case_opt=(p_EmbeddedCaseSensitive)?'':'i';
      status=search(re,searchInSelection'R@<'case_opt);
      //messageNwait("status="status);
      for (;;) {
         if (status) {
            break;
         }
         word=get_match_text(0);
         //say('word='word' re='re);
         if (word_matches:[word]==1 && !(def_complete_flags&COMPLETE_ALLOW_DUP_MATCHES)) {
            //messageNwait('skipping 'word);
         } else {
            ok_to_go=1;
            if (restrict_to_vars) {
               if (_clex_find(COMMENT_CLEXFLAG|STRING_CLEXFLAG,"T") && !look_for_anything) { //if it's not color coded
                  ok_to_go=0;
               }
               if (abs(prefix.line_to_goto - (int)point('L')) < lines_ok) { //if we're within the limit any match is allowed
                  ok_to_go=1;
               }
            }
            if (p_col == pre_search_col && point() == pre_search_line) {   //so we don't pick up a match to the right on a '' prefix
               ok_to_go=0;
            }
     //Dan took this out because it seemed to cause every other one to
     //be skipped if def_complete_flags&COMPLETE_ALLOW_DUP_MATCHES
#if 0
            //If we're allowing duplicate matches, turn off the hit and don't allow the word to be added
            if (ok_to_go && word_matches:[word]==1 && (def_complete_flags&COMPLETE_ALLOW_DUP_MATCHES)) {
               //messageNwait('got to my case');
               ok_to_go=0;
               word_matches:[word]=0;
            }
#endif

            if (ok_to_go) {
               word_matches:[word]=1; //so we won't match it again
               //add word to the list

               if (forward_matches._length() > limit) {
                  break;
               }
               add_to_list(word,0,prefix.word,(point()==pre_search_line),orig_line_length,back_matches,forward_matches);

               //if we're partial searching, we're done, restore pos and return yes to more matches
               if (partial_search) {
                  _restore_pos2(p);
                  return(1);
               }
            }
         }
         status=repeat_search();
      }
   }
   _restore_pos2(p);
   if (markid!='') {
      _show_selection(orig_markid);
      _free_selection(markid);
   }
   return(0); //no more matches to be had
}

boolean CompleteWordActive()
{
   if( !select_active() ) {
      return false;
   }
   if (command_state()) {
      return false;
   }
   switch (name_name(prev_index('','C'))) {
   case 'complete-next':
   case 'complete-next-match':
   case 'complete-next-no-dup':
   case 'complete-prev':
   case 'complete-prev-match':
   case 'complete-prev-no-dup':
   case 'complete-list':
   case 'complete-more':
      return true;
   default:
      return false;
   }
}

//default keybinding C-S-space
/**
 * Inserts the text up to and including the next word which follows the
 * last match found by the <b>complete_next</b>, <b>complete_prev</b>,
 * <b>complete_next_match</b>, or <b>complete_prev_match</b> command.
 *
 * @see complete_next
 * @see complete_list
 * @see complete_next_match
 * @see complete_prev_match
 * @see complete_prev
 *
 * @categories Completion_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command complete_more() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   static int col_after_last_grab,last_grab_forward,last_grab_index;
   int shift_selection_up;

   if (command_state()) {
      message("The complete word commands cannot be used on the command line.");
      return('');
   }

   //save indexes
   int old_last_index=last_index('','C');
   int old_prev_index=prev_index('','C');

   shift_selection_up=0; //used if we're completing on the same line as the prefix

   int index=0;
   Match match;
   match.col=0;
   match.line_to_goto=0;
   match.lineoffset=0;
   match.word="";
   word_chars := _extra_word_chars:+p_word_chars;
   _str re='{#00[~\od'word_chars']+([\od'word_chars']#|$)}';
   typeless p;
   _save_pos2(p);
   switch (name_name(prev_index('','C'))) {
   case 'complete-next':
   case 'complete-next-match':
   case 'complete-next-no-dup':
      //restore cursor from the last forward match and search forward
      index=gforward_matches._length()-1;
      if (index<0) {
         //no matches exist, need to bail out
         message("No matches to complete.");
         //restore index
         last_index(old_prev_index,'C');
         return('');

      }
      //set us to the position of the last match
      match=gforward_matches[index];
      last_grab_forward=1;
      last_grab_index=index;
      break;
   case 'complete-prev':
   case 'complete-prev-match':
   case 'complete-prev-no-dup':
      //restore cursor from the last backward match and search forward
      index=gback_matches._length()-1;
      if (index<0) {
         //no matches exist, need to bail out
         message("No matches to complete.");
         //change index so we don't blow up
         last_index(old_prev_index,'C');
         return('');

      }
      //set us to the position of the last match
      match=gback_matches[index];
      last_grab_forward=0;
      last_grab_index=index;
      break;
   case 'complete-list':
      //will need to store what index the choice was made from (use -# for backward)
      //use those values for the col positions etc.
      index=gline_prefix_is_on; //this should be set to the index into the array
      if (gline_prefix_is_on < 0) {
         //backward
         index*=-1;
         index=gback_matches._length()-index;  //since the backward matches are in reverse order of the listbox
         if (index<0) {
            //no matches exist, need to bail out
            message("No matches to complete.");
            //restore index
            last_index(old_prev_index,'C');
            return('');

         }
         match=gback_matches[index];
         last_grab_forward=0;

      } else {
         //messageNwait('using forward');
         index-=1;
         if (index<0) {
            //no matches exist, need to bail out
            message("No matches to complete.");
            //restore index
            last_index(old_prev_index,'C');
            return('');

         }
         match=gforward_matches[index];
         last_grab_forward=1;
      }
      last_grab_index=index;
      break;
   case 'complete-more':
      index=last_grab_index;

      if (last_grab_forward) {
         //index=gforward_matches._length()-1;
         //set us to the position of the last match
         match=gforward_matches[index];
      } else {
         //index=gback_matches._length()-1;
         //set us to the position of the last match
         match=gback_matches[index];
      }
      match.col = col_after_last_grab;
      break;
   default:
      if (!p_mdi_child) {
         p_window_id=p_active_form;
         _on_edit_form();
         return '';
      }
      //if they do this alone, just complete for them and grab more
      complete_prev();
      if (gback_matches._length() > 0) { //it will be 0 if nothing was found
         complete_more();
      } else {
         //restore index that caused us to default
         last_index(old_prev_index,'C');
      }
      return('');
      break;
   }

   boolean same_line=(match.line_to_goto==point('L'));  //if we're completing on the same line, we need to take that into consideration.

   goto_completion(match);
   //messageNwait('at the position of the last match');
   typeless status=search(re,'@R>'); //we don't care where the cursor will go
   //messageNwait('after search, status='status);
   col_after_last_grab=p_col; //so we can get the next one after this
   //messageNwait('setting col_After here re='re);
   if (point('L') != match.line_to_goto || status) { //if we went past the end of the line
      _beep();
      deselect();
      if (status==0) {
         goto_completion(match);
         end_line();
      }
      message("You've reached the end of the line for that match.");
      col_after_last_grab=p_col; //this makes sure we won't start matching things again.
      _restore_pos2(p);
      last_index(old_last_index,'C');
      prev_index(old_prev_index,'C');
      return('');
   }

   _str word=get_match_text(0);
   //messageNwait('word='word);

   boolean bail_out=0;
   if (same_line && p_col >= gprefix.col && !last_grab_forward) {  //only do this if we were completing backward and same line etc.
      //we're on the same line and we've completed past the prefix
      int endpos;
      endpos=pos(gback_matches[gback_matches._length()-1].word,word);
      //parse word with word gprefix.word .
      word=substr(word,1,endpos-1);
      bail_out=1;
   }
   word=strip(word,'T'); //strip trailing blanks

   _restore_pos2(p);

   _str line='';
   get_line_raw(line);
   int col=_text_colc(p_col,'P');  //convert to physical
   _str begin_of_line=substr(line,1,col-1);

   _str end_of_line=substr(line,col);  //get rest of line
   line=begin_of_line:+_rawText(word):+end_of_line;
   //messageNwait('begin_of_line='begin_of_line' endline='end_of_line' word='word);
   replace_line_raw(line);
   //set cursor position to end of the new word
   p_col=text_col(begin_of_line:+_rawText(word))+1; 

   if (same_line) {
      if (p_col > col_after_last_grab) {   //probably should stay in
         //don't need to mess with it
      } else {
         //messageNwait('adding to colaftergrab');
         shift_selection_up=length(expand_tabs(_rawText(word)));
         col_after_last_grab+=shift_selection_up;
      }
   }

   typeless p2;
   if (bail_out) {
      _save_pos2(p2);
      end_line();
      col_after_last_grab=p_col; //this makes sure we won't start matching things again.
      _restore_pos2(p2);

      _beep();
      deselect();
      message("No more matches for this line without repeating.");
      last_index(old_last_index,'C');
      prev_index(old_prev_index,'C');
      return('');
   }
   show_what_would_be_grabbed(match,col_after_last_grab-1,0,shift_selection_up);

   //restore indexes
   last_index(old_last_index,'C');
   prev_index(old_prev_index,'C');
}

static void show_what_would_be_grabbed(Match match,int match_col,int init,int shift_selection_up) //init used in complete-prev/next (only select word)
{
   //save indexes
   int old_last_index=last_index('','C');
   int old_prev_index=prev_index('','C');

   _str begin_of_line='';
   _str end_of_line='';

   word_chars := _extra_word_chars:+p_word_chars;
   _str re='{#00[~\od'word_chars']+([\od'word_chars']#|$)}';
   re=re'|{#00([~\od'word_chars']+|^)([\od'word_chars']#)}';
   typeless p;
   _save_pos2(p);
   goto_completion(match);
   p_col=match_col;

   typeless status=0;
   typeless pp;
   if (init) {
      //messageNwait('init');
      _save_pos2(pp);
      _deselect();
      search('([~\od'word_chars"]|^)","R->@"); //search for start of word
      _select_char("","EN");
      //find the end of the match
      status=search('[~\od'word_chars"]|$","R>@"); //search for end of word
      if (status) {
         //no nonword chars, so go to end of line
         _end_line();
      } else {
         if (match_length()) {
            left();
         }
      }
      _select_char("","EN");
      _restore_pos2(pp);
   }

   search('[~\od'word_chars"]|^","R->@"); //this gets us to the beginning of the matched word
   match_col=p_col;
   typeless begin_pos;
   save_pos(begin_pos);
   search(re,'R>@'); //we don't care where the cursor will go

   if (point('L') != match.line_to_goto) { //if we went past the end of the line
      //selecting to the end of the line
      restore_pos(begin_pos);_end_line();
      //up();_end_line();
      _select_char("","EN");
      //do nothing, no matches available
      _restore_pos2(p);
      //restore indexes
      last_index(old_last_index,'C');
      prev_index(old_prev_index,'C');
      return;
   }
   _str word=get_match_text(0);
   _str line='';
   get_line(line);
   int where_stop=p_col-length(word);
   int where_starts=0;
   begin_of_line=_expand_tabsc(match_col,where_stop - match_col);
   end_of_line=_expand_tabsc(p_col,-1);
   if (!init) {
      _save_pos2(pp);
      if (shift_selection_up) {
         //we're going on the same line and need to move the start of the selection forward
         begin_select();
         where_starts=p_col+shift_selection_up;
         p_col=where_starts;
         deselect();
         _select_char("","EN"); //restart the selection

      }
      p_col=where_stop;
      _select_char("","EN"); //extend the selection
      _restore_pos2(pp);
   }
   _restore_pos2(p);

   _str msg='';
   if (def_complete_flags & COMPLETE_CHECK_SCOPE) {
      if ((match.lineoffset > extent.line_end || match.lineoffset < extent.line_begin) && extent.line_end!=0) {
         //outside current function
         //_beep();
         msg='*** Outside current proc ***';
      } else {
         msg='';
      }

   } else {
      msg='';
   }
   _str key=where_is('complete-more',1);
   parse key with 'is bound to' key . ;
   //messageNwait('begin_line='begin_of_line' end_of_line='end_of_line' word='word);
   if (key!='') {
      message(msg'  Press 'key' for more:     'word'    'end_of_line);
   } else {
      message('You can bind complete_more to a key and grab more words from the matched line.');
   }
   //restore indexes
   last_index(old_last_index,'C');
   prev_index(old_prev_index,'C');
}


//default keybinding C-up

static int complete_nextprev_match(Match (&matches)[],boolean doNext)
{
   exactWord := complete_cur_word(auto start_col);
   if (exactWord=="") {
      _beep();
      message("This command must be used after a word completion command.");
      return STRING_NOT_FOUND_RC;
   }
   return complete_nextprev(gforward_matches,true,exactWord);
}

/**
 * Searches up the file for another occurrence of the text found by the last 
 * <b>complete_next</b>, <b>complete_prev</b>, <b>complete_next_match</b>, 
 * complete_prev_match command.
 * 
 * @see complete_prev
 * @see complete_list
 * @see complete_next
 * @see complete_next_match
 * @see complete_more
 * 
 * @categories Completion_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command complete_prev_match() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   static Match last_match;

   if (command_state()) {
      message("The complete word commands cannot be used on the command line.");
      return('');
   }

   // they haven't done complete_prev yet, then do it for them
   if (glast_inserted_match == null) {
      return complete_nextprev_match(gback_matches,false);
   }

   //messageNwait('after command check');

   //save indexes
   int old_last_index=last_index('','C');
   int old_prev_index=prev_index('','C');

   typeless p;
   _save_pos2(p);
   word_chars := _extra_word_chars:+p_word_chars;
   _str re='(^|[~\od'word_chars']){#00'_escape_re_chars(glast_inserted_match)'\c}([~\od'word_chars']|$)';
   //messageNwait('last index='name_name(prev_index('','C')));

   int index=0;
   int index2=0;
   typeless status=0;
   _str last_command=name_name(prev_index('','C'));
   switch (last_command) {
   case 'complete-prev':
   case 'complete-prev-no-dup':
      //set line and col stuff
      index=gback_matches._length()-1;
      if (index<0) {
         //no matches exist, need to bail out
         message("No matches to skip.");
         return('');

      }
      last_match=gback_matches[index];
      goto_completion(last_match);
      //messageNwait('already set the last line+col');
      search('[\od'word_chars'][~\od'word_chars']','R-<@');
      if (gback_matches[index].word==gprefix.word) {
         //if the prefix is the same as the match, we need to search again
         //so we won't find the one that was already highlighted the first time
         repeat_search();
      }
      //messageNwait('searched back for the start');
      break;
   case 'complete-list':
      _restore_pos2(p);
      complete_prev();       //just call complete_prev rather than trying to figure out which array to use
      last_index(old_last_index,'C');
      prev_index(old_prev_index,'C');
      return('');
      break;
 //this will work, but might mess up if I let people wrap around
   case 'complete-next':
   case 'complete-next-match':
   case 'complete-next-no-dup':
      //add new entry to matches, and switch
      index=gback_matches._length();
      index2=gforward_matches._length()-1;
      if (index2<0) {
         //no matches exist, need to bail out
         message("No matches to skip.");
         return('');

      }
      gback_matches[index]=gforward_matches[index2];
      last_match=gback_matches[index];
      goto_completion(last_match);
      status=search(glast_inserted_match,'R-<@');  //try to find the beginning of the match
      if (p_col==1) {
         up();
         _end_line();
      }

      break;
   case 'complete-prev-match':
      //set to last used line and col
      index=gback_matches._length()-1;
      if (index<0) {
         //no matches exist, need to bail out
         message("No matches to skip.");
         return('');
      }
      last_match=gback_matches[index];
      goto_completion(last_match);
      //messageNwait('lines, cols set up');
      status=search('(^|[~\od'word_chars'])'_escape_re_chars(glast_inserted_match),'R-<@');  //try to find the beginning of the match
      if (p_col==1) {
         up();
         _end_line();
      }
      //messageNwait('searched back for the start need to be on another line by this point');
      break;

   default:
      return complete_nextprev_match(gback_matches,false);
   }

   status=search(re,'R-<@');
   if (p_col==last_match.col && point('L')==last_match.line_to_goto) {
      //_beep();
      status=repeat_search();
   }
   if (status) {
      //no more matches found
      message("No more matches.");
      _restore_pos2(p);
      return('');
   }
   //messageNwait('after searching');
   //reset the back match array with line and col
   gback_matches[gback_matches._length()-1].line_to_goto=(int)point('L');
   gback_matches[gback_matches._length()-1].lineoffset=point();
   gback_matches[gback_matches._length()-1].col=p_col;
   show_what_would_be_grabbed(gback_matches[gback_matches._length()-1], p_col-1,1,0); //the -1 is so we catch the char after the match

   _restore_pos2(p);
   last_index(old_last_index,'C');
   prev_index(old_prev_index,'C');
}

//default keybinding C-down


/**
 * Searches down the file for another occurrence of the text found by 
 * the last <b>complete_next</b>, <b>complete_prev</b>, complete_next_
 * match, <b>complete_prev_match</b> command.
 * 
 * @see complete_prev
 * @see complete_list
 * @see complete_next
 * @see complete_prev_match
 * @see complete_more
 * 
 * @categories Completion_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command complete_next_match() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   static Match last_match;

   if (command_state()) {
      message("The complete word commands cannot be used on the command line.");
      return('');
   }

   // they haven't done complete_next yet, then do it for them
   if (glast_inserted_match == null) {
      return complete_nextprev_match(gforward_matches,true);
   }

   //save indexes
   int old_last_index=last_index('','C');
   int old_prev_index=prev_index('','C');

   int index=0;
   int index2=0;
   typeless status=0;
   typeless p;
   _save_pos2(p);
   //re='[~'p_word_chars']{#0'glast_inserted_match'\c}[~'p_word_chars']';
   word_chars := _extra_word_chars:+p_word_chars;
   _str re='(^|[~\od'word_chars']){#00'_escape_re_chars(glast_inserted_match)'\c}([~\od'word_chars']|$)';
   //messageNwait('last index='name_name(prev_index('','C')));
   _str last_command=name_name(prev_index('','C'));
   //messageNwait('lc='last_command);
   switch (last_command) {
   case 'complete-next':
   case 'complete-next-no-dup':
      //set line and col stuff
      index=gforward_matches._length()-1;
      if (index<0) {
         //no matches exist, need to bail out
         message("No matches to skip.");
         return('');

      }
      last_match=gforward_matches[index];
      goto_completion(last_match);
      search('[\od'word_chars'][~\od'word_chars']','R<@');
      //messageNwait('searched forward for the end');
      break;

   case 'complete-list':
      message("Not allowed.  Use complete-prev or complete-next before skipping.");
      _restore_pos2(p);
      complete_next();
      /*
      when going forward, the list prefix isn't picked up, so no need to use next match (as long as it was a prefix, not the same thing)
      messageNwait('list was last, calling complete-next-match');
      complete_next_match();
      */
      last_index(old_last_index,'C');
      prev_index(old_prev_index,'C');
      return('');
      break;
  //this will work, but might mess up if I let people wrap around
   case 'complete-prev':
   case 'complete-prev-match':
   case 'complete-prev-no-dup':
      //for testing, add new entry to matches, and switch
      index=gforward_matches._length();
      index2=gback_matches._length()-1;
      if (index2<0) {
         //no matches exist, need to bail out
         message("No matches to skip.");
         return('');

      }

      gforward_matches[index]=gback_matches[index2];
      last_match=gforward_matches[index];
      goto_completion(last_match);
      break;
   case 'complete-next-match':
      //set to last used line and col
      index=gforward_matches._length()-1;
      if (index<0) {
         //no matches exist, need to bail out
         message("No matches to skip.");
         return('');

      }
      last_match=gforward_matches[index];
      goto_completion(last_match);
      //messageNwait('before search');
      //search forward for beginning of next match
      search('(^|[~\od'word_chars']'_escape_re_chars(glast_inserted_match),'R<@');  //try to find the beginning of the match
      //messageNwait('after search');
      break;

   default:
      return complete_nextprev_match(gforward_matches,true);
   }

   status=search(re,'R<@');
   if (status) {
      //no more matches found
      message("No more matches.");
      _restore_pos2(p);
      return('');
   }
   //messageNwait('after searching');
   //reset the back match array with line and col
   gforward_matches[gforward_matches._length()-1].line_to_goto=(int)point('L');
   gforward_matches[gforward_matches._length()-1].lineoffset=point();
   gforward_matches[gforward_matches._length()-1].col=p_col;
   show_what_would_be_grabbed(gforward_matches[gforward_matches._length()-1],p_col-1,1,0); //the -1 is so we catch the char after the match
   _restore_pos2(p);
   last_index(old_last_index,'C');
   prev_index(old_prev_index,'C');

}
void _before_write_state_clean_up()
{
   //clean up everything so we don't save it in the statefile
   gWordHits._makeempty();
   gback_matches._makeempty();
   gforward_matches._makeempty();
   gprefix._makeempty();
   glast_inserted_match._makeempty();
   gline_prefix_is_on=0;
}

/**
 * Retrieves previous word or variable which is a prefix match of the word at 
 * the cursor but skips duplicates- otherwise, this is the same as complete-prev
 *
 * @see complete_prev
 * @see complete_next
 * @see complete_next_no_dup
 * @see complete_list
 * @see complete_next_match
 * @see complete_prev_match
 * @see complete_more
 *
 * @categories Completion_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command complete_prev_no_dup()  name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOUNDOS)
{
   int dup_was_on = 0;
   if (def_complete_flags&COMPLETE_ALLOW_DUP_MATCHES) {
      dup_was_on=1;
      def_complete_flags=def_complete_flags ^ COMPLETE_ALLOW_DUP_MATCHES;
   }
   complete_nextprev(gback_matches,false);
   //turn it back on
   if (dup_was_on) {
      def_complete_flags=def_complete_flags | COMPLETE_ALLOW_DUP_MATCHES;
   }
}

/**
 * Retrieves next word or variable which is a prefix match of the word at the 
 * cursor but skips duplicates  - otherwise, this is the same as complete-next
 *
 * @see complete_prev
 * @see complete_next
 * @see complete_prev_no_dup
 * @see complete_list
 * @see complete_next_match
 * @see complete_prev_match
 * @see complete_more
 * @categories Completion_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command complete_next_no_dup()  name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOUNDOS)
{
   int dup_was_on = 0;
   if (def_complete_flags&COMPLETE_ALLOW_DUP_MATCHES) {
      dup_was_on=1;
      def_complete_flags=def_complete_flags ^ COMPLETE_ALLOW_DUP_MATCHES;
   }
   complete_nextprev(gforward_matches,true);
   //turn it back on
   if (dup_was_on) {
      def_complete_flags=def_complete_flags | COMPLETE_ALLOW_DUP_MATCHES;
   }
}

