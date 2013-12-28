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
#include "color.sh"
#import "complete.e"
#import "files.e"
#import "guicd.e"
#import "guifind.e"
#import "html.e"
#import "listbox.e"
#import "main.e"
#import "makefile.e"
#import "markfilt.e"
#import "optionsxml.e"
#import "picture.e"
#import "recmacro.e"
#import "seek.e"
#import "sellist.e"
#import "spell.e"
#import "stdcmds.e"
#import "stdprocs.e"
#endregion


_control _label1

static int insideKeyWordLastTime;
static int gSuppressDoneMsg;
static int gspCancelled;
static int multifile;

static int insideScriptSection;  // flag: 1 if spell checking HTML inside SCRIPT section
static int scriptStartLine, scriptStartCol, scriptEndLine, scriptEndCol;
static int lastHTMLSeekPos;
static int firstHTMLcheck;
static int fromHTMLCursorLine, fromHTMLCursorCol;
static int gLastHTMLSeekPos = 0;

/**
 * Displays Spell Options dialog box.
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
_command spell_options() name_info(','VSARG2_EDITORCTL)
{
   _macro_delete_line();
   config ('Spell Check');
   return(0);
}


#define    SPELL_IGNORE_ONCE 1
#define    SPELL_IGNORE_ALL 2
#define    SPELL_CHANGE_ONCE 3
#define    SPELL_CHANGE_ALL 4
#define    SPELL_DELETE_ONCE 5
#define    SPELL_ADD1 6
#define    SPELL_ADD2 7

static int gcol;            // Current column counter
static _str gspell_status,   // Status of last spell-check
                grestore_cursor, // Restore cursor value
                gcur_selection,  // Active mark
                gold_selection,  // Mark id of selected area
                gin_selected,    // Selected area flag
                gword,           // Current misspelled gword
                greplace_word,   // Current replace gword
                glast_op;        // The last operation

static _str gin_source,          // Source file flag
                gsource_proc_index,  // Procedure index for finding next comment/string
                gsource_mark_id;     // Mark id for marking comments/strings
                //source_info;        // Comment/String information for current extension

int _leftcol,_width;

static int fgs_orig_width;
static int fgs_orig_col;
static spell_filter_get_string(var str,typeless gin_source)
{
   if (!gin_source) {
      return(filter_get_string(str));
   }
   int col=p_col;
   typeless status=filter_get_string(str);
   if (!status) {
      fgs_orig_width=_width;
      fgs_orig_col=col;
   }
   return(status);
}
defeventtab _spell_form;

// Assumes the history was cleared before creation, so don't check
// for replacement words
_word_not_found.on_create()
{
   // Multifile spell checking:
   _skip.p_enabled = false;
   if (multifile) {
      _skip.p_enabled = true;
   }

   // Set the cursor to off
   grestore_cursor=_default_option('C');
   _default_option('C',0);   // Turn cursor off for spell check session

   gword="";
   greplace_word="";
   gin_selected=0;
   gin_source=0;
   gspCancelled = 0;

   p_user= arg(1);   // Save the window id of the buffer to be spell-checked

   _search_form_xy(p_active_form,p_user);   // Position the form correctly on the screen

   p_user._undo('S');   // Start a new level of undo
   int in_source_status=0;
   if( arg(2)=='2' ) {
      // User specified spell checking within a source file for comments and strings
      gin_source=1;
      gsource_proc_index=arg(3);
      gsource_mark_id=arg(4);
      in_source_status=call_index(p_user,gsource_mark_id,1,gsource_proc_index);   // Mark the next comment/string
   }
   if( upcase(arg(2))=='M' || (gin_source && !in_source_status) ) {
      // User specified a selected area
      if( p_user.select_active() ) {
         gin_selected=1;
         p_user.filter_init();   // Initialize selection filtering
         //p_user.begin_selection();   // Go to beginning of selected area
         _str mark_status=save_selection(gold_selection);
         if ( mark_status ) {
            clear_message();   /* Not serious error */
         }
         _str str;
         p_user.spell_filter_get_string(str,gin_source);
         gcol=_leftcol;
      } else {
         p_active_form._delete_window('');
         _message_box("Text not selected!",'',MB_OK|MB_ICONEXCLAMATION);
         return('');
      }
   } else {
      gcol=p_user.p_col;
      gold_selection=_duplicate_selection();
   }

   _spell_clear('R');   // Clear the previous gword (used to detect double words)
   gcur_selection=_duplicate_selection('');   // Get the active mark

   _undo_last.p_enabled=0;   // Nothing to undo initially

   typeless status;
   if (in_source_status) {
      status=SPELL_NO_MORE_WORDS_RC;
   } else {
      status=spell_form_update(p_active_form);
   }
   if( status ) spell_exit(status);
}

_word_not_found.on_destroy()
{
   gcur_selection=_duplicate_selection('');
   _deselect(gcur_selection);

   _default_option('C',grestore_cursor);   // Restore cursor to original state

   /* Check to see if we need to restore a selected area */
   if( gin_selected ) {
      p_user.restore_selection(gold_selection);   // Restore the old selected area
   } else {
      _show_selection(gold_selection);
      _free_selection(gcur_selection);
   }

   _spell_clear('H');   // Clear the history after each spell-checking session
   _spell_clear('R');   // Clear the previous gword (used to detect double words)
   _spell_save();       // Save the user dictionaries
}
_word_not_found.on_change()
{
   if( p_text!=gword ) p_text=gword;
}

void _suglist.on_change(int reason)
{
   if( p_text=="(No Suggestions)" ) p_text="";

   if( p_text=="" ) {
      /* No suggestion in the suggestion box means the user may want
       * to delete the misspelled gword.
       */
      if (_change_or_delete.p_caption!="&Delete") {
         _change_or_delete.p_caption="&Delete";
      }
      _change_or_delete.p_enabled=1;
      _change_or_delete_all.p_enabled=0;
      _ignore.p_default=1;
   } else {
      if (_change_or_delete.p_caption!="&Change") {
         _change_or_delete.p_caption="&Change";
      }
      if( p_text==_word_not_found.p_text ) {
         /* The gword in the suggestion box is exactly the same as the
          * original misspelled gword.
          */
         _change_or_delete.p_enabled=0;
         _change_or_delete_all.p_enabled=0;
         _ignore.p_default=1;
      } else {
         _change_or_delete.p_enabled=1;
         _change_or_delete_all.p_enabled=1;
         _change_or_delete.p_default=1;
      }
   }
}

#if 0
_suglist.enter()
{
   if( p_text!="" ) _change_or_delete.call_event(_change_or_delete,LBUTTON_UP);
}
#endif

_ignore.lbutton_up()
{
   _word_not_found.p_user._undo('S');

   glast_op=SPELL_IGNORE_ONCE:+' ':+_word_not_found.p_text;
   if( gin_selected ) {
      // Add additional mark information
      glast_op=glast_op:+' ':+_leftcol:+' ':+_width;
   }

   _undo_last.p_enabled=1;   // Enable undo

   typeless status=spell_form_update(p_active_form);
   if( status ) spell_exit(status);
}

_ignore_all.lbutton_up()
{
   _word_not_found.p_user._undo('S');
   _spell_add_hist(_word_not_found.p_text);

   glast_op=SPELL_IGNORE_ALL:+' ':+_word_not_found.p_text;
   if( gin_selected ) {
      // Add additional mark information to 'glast_op'
      glast_op=glast_op:+' ':+_leftcol:+' ':+_width;
   }

   _undo_last.p_enabled=1;   // Enable undo

   typeless status=spell_form_update(p_active_form);   // Find the next misspelled gword and refresh form
   if( status ) spell_exit(status);
}

_change_or_delete.lbutton_up()
{
   if( p_caption=="&Change" ) {

      // Save undo information in 'glast_op'
      glast_op=SPELL_CHANGE_ONCE:+' ':+gword;
      if( gin_selected ) {
         glast_op=glast_op:+' ':+_leftcol:+' ':+_width;
      }

      greplace_word= _suglist.p_text;

      // Now spell-check the replacement gword the user chose
      typeless dummy1,dummy2;
      _str replace_word2;
      typeless status=_spell_check(dummy1,replace_word2,dummy2,greplace_word);

      // If there was a nonzero status returned then pop up a message box with options.
      _str msg='';
      int msg_box_style=MB_YESNOCANCEL|MB_ICONQUESTION;
      switch( status ) {
      case SPELL_NO_MORE_WORDS_RC:
         break;
      case SPELL_WORD_NOT_FOUND_RC:
         msg="The word [":+greplace_word:+"] was not found in the main, common, or user dictionaries.\n\nDo you still want to use it?";
         break;
      case SPELL_CAPITALIZATION_RC:
         msg="The word [":+greplace_word:+"] may not be capitalized properly.\n\nDo you still want to use it?";
         break;
      case SPELL_REPLACE_WORD_RC:
         msg="The word [":+greplace_word:+"] has a replacement [":+replace_word2:+"].\n\nDo you want to use the replacement?";
         break;
      case SPELL_REPEATED_WORD_RC:
         msg="The word [":+greplace_word:+"] is a repeated word.\n\nDo you still want to use it?";
         break;
      default:
         msg_box_style=MB_OK|MB_ICONEXCLAMATION;
         msg=get_message(status);
      }
      if( status==SPELL_NO_MORE_WORDS_RC ) {
         _word_not_found.p_user._undo('S');
         spell_replace_word(_word_not_found.p_user);
      } else {
         int status2=_message_box(msg,'',msg_box_style);
         if( status2==IDYES ) {
            if( status==SPELL_REPLACE_WORD_RC ) greplace_word=replace_word2;
            _word_not_found.p_user._undo('S');
            spell_replace_word(_word_not_found.p_user);
         } else if( status2==IDNO ) {
            if( status==SPELL_REPLACE_WORD_RC ) {
               _word_not_found.p_user._undo('S');
               spell_replace_word(_word_not_found.p_user);
            } else {
               return('');
            }
         } else if( status==IDOK || status2==IDCANCEL ) {
            return('');
         }
      }
   } else {
      glast_op=SPELL_DELETE_ONCE:+' ':+gword;
      if( gin_selected ) {
         glast_op=glast_op:+' ':+_leftcol:+' ':+_width;
      }
      _word_not_found.p_user._undo('S');
      spell_delete_word(_word_not_found.p_user);
   }

   _undo_last.p_enabled=1;   // Enable undo

   typeless status=spell_form_update(p_active_form);
   if( status ) spell_exit(status);
}

_change_or_delete_all.lbutton_up()
{
   // Save undo information in 'glast_op'
   glast_op=SPELL_CHANGE_ALL:+' ':+gword;
   if( gin_selected ) {
      glast_op=glast_op:+' ':+_leftcol:+' ':+_width;
   }

   greplace_word= _suglist.p_text;

   // Now spell-check the replacement gword the user chose
   typeless dummy1,dummy2;
   _str replace_word2;
   typeless status=_spell_check(dummy1,replace_word2,dummy2,greplace_word);

   // If there was a nonzero status returned then pop up a message box with options.
   _str msg='';
   int msg_box_style=MB_YESNOCANCEL|MB_ICONQUESTION;
   switch( status ) {
   case SPELL_NO_MORE_WORDS_RC:
      break;
   case SPELL_WORD_NOT_FOUND_RC:
      msg="The word [":+greplace_word:+"] was not found in the main, common, or user dictionaries.\n\nDo you still want to use it?";
      break;
   case SPELL_CAPITALIZATION_RC:
      msg="The word [":+greplace_word:+"] may not be capitalized properly.\n\nDo you still want to use it?";
      break;
   case SPELL_REPLACE_WORD_RC:
      msg="The word [":+greplace_word:+"] has a replacement [":+replace_word2:+"].\n\nDo you want to use the replacement?";
      break;
   case SPELL_REPEATED_WORD_RC:
      msg="The word [":+greplace_word:+"] is a repeated word.\n\nDo you still want to use it?";
      break;
   default:
      msg_box_style=MB_OK|MB_ICONEXCLAMATION;
      msg=get_message(status);
   }
   if( status==SPELL_NO_MORE_WORDS_RC ) {
      _spell_add_hist(gword,greplace_word);
      _word_not_found.p_user._undo('S');
      spell_replace_word(_word_not_found.p_user);
   } else {
      int status2=_message_box(msg,'',msg_box_style);
      if( status2==IDYES ) {
         if( status==SPELL_REPLACE_WORD_RC ) greplace_word=replace_word2;
         _spell_add_hist(gword,greplace_word);
         _word_not_found.p_user._undo('S');
         spell_replace_word(_word_not_found.p_user);
      } else if( status2==IDNO ) {
         if( status==SPELL_REPLACE_WORD_RC ) {
            _spell_add_hist(gword,greplace_word);
            _word_not_found.p_user._undo('S');
            spell_replace_word(_word_not_found.p_user);
         } else {
            return('');
         }
      } else if( status2==IDOK || status2==IDCANCEL ) {
         return('');
      }
   }

   _undo_last.p_enabled=1;   // Enable undo

   status=spell_form_update(p_active_form);
   if( status ) spell_exit(status);
}

_add_to_user1.lbutton_up()
{
   // Save undo information in 'glast_op'
   glast_op=SPELL_ADD1:+' ':+gword;
   if( gin_selected ) {
      glast_op=glast_op:+' ':+_leftcol:+' ':+_width;
   }

   _spell_add(_word_not_found.p_text,1);

   _word_not_found.p_user._undo('S');

   _undo_last.p_enabled=1;   // Enable undo

   typeless status=spell_form_update(p_active_form);
   if( status ) spell_exit(status);
}


_add_to_user2.lbutton_up()
{
   // Save undo information in 'glast_op'
   glast_op=SPELL_ADD2:+' ':+gword;
   if( gin_selected ) {
      glast_op=glast_op:+' ':+_leftcol:+' ':+_width;
   }

   _spell_add(_word_not_found.p_text,2);

   _word_not_found.p_user._undo('S');

   _undo_last.p_enabled=1;   // Enable undo

   typeless status=spell_form_update(p_active_form);
   if( status ) spell_exit(status);
}

_options.lbutton_up()
{
   optionsWid := config('Spell Check', 'N', '', true);
   _modal_wait(optionsWid);
}

_undo_last.lbutton_up()
{
   typeless last_operation, last_word, last_leftcol, last_width;
   if( gin_selected ) {
      parse glast_op with last_operation last_word last_leftcol last_width ;
      _leftcol=last_leftcol;   // Did we change lines because of an undo?
      _width=last_width;
   } else {
      parse glast_op with last_operation last_word;
   }
   if( last_operation==SPELL_IGNORE_ALL || last_operation==SPELL_CHANGE_ALL ) {
      _spell_delete(last_word,'H');
   } else if( last_operation==SPELL_ADD1 ) {
      _spell_delete(last_word,'1');
   } else if( last_operation==SPELL_ADD2 ) {
      _spell_delete(last_word,'2');
   }

   _word_not_found.p_user._undo();
   gword="";
   gcol=_word_not_found.p_user.p_col;

   p_enabled=0;   // Disable the 'Undo last' button - only one undo allowed per operation
   typeless status=spell_form_update(p_active_form);
   if( status ) spell_exit(status);
}
_skip.lbutton_up()
{
   p_active_form._delete_window(0);
}
_cancel.lbutton_up()
{
   gspCancelled = 1;
   p_active_form._delete_window(0);
}

static spell_form_update(int form_wid)
{
   p_window_id=_word_not_found.p_user;   // Switch to buffer we are spell-checking

   int status;
   int start_col;
   int save_col;
   int width;
   int line_height;
   int len;
   _str str;
   _str line;

   while( 1 ) {
      if( gin_selected ) {
         start_col=gcol+_rawLength(gword);
         width=_width-(start_col-_leftcol);
         if( width>0 ) {
            gspell_status=_spell_check_area(gword,greplace_word,gcol,start_col,width);
         } else {
            gspell_status=SPELL_NO_MORE_WORDS_RC;
         }
      } else {
         p_col=gcol+_rawLength(gword);
         gspell_status=_spell_check(gword,greplace_word,gcol);
      }
      //messageNwait('gspell_status='gspell_status'='get_message(gspell_status)' gcol='gcol' p_col='p_col);
      if( gspell_status==SPELL_REPLACE_WORD_RC ) {
         /* A replacement gword was found for 'gword' */
         spell_replace_word(p_window_id);
         gword=greplace_word;  // Do this so we can move past the newly replaced gword
         continue;
      } else {
         /* Either 'SPELL_REPEATED_WORD_RC' or 'SPELL_WORD_NOT_FOUND_RC' or error */
         if( gspell_status==SPELL_REPEATED_WORD_RC ||
             gspell_status==SPELL_WORD_NOT_FOUND_RC ||
             gspell_status==SPELL_CAPITALIZATION_RC ) {
            /* Set the first caption to indicate a repeated gword occurrence or a misspelled gword */
            if( gspell_status==SPELL_REPEATED_WORD_RC ) {
               form_wid._label1.p_caption="Repeated word:";
               #if 1
               /*form_wid._change_or_delete_all.p_caption="D&elete All";*/
               form_wid._ignore_all.p_enabled=0;
               form_wid._add_to_user1.p_enabled=0;
               form_wid._add_to_user2.p_enabled=0;
               #endif
            } else if( gspell_status==SPELL_CAPITALIZATION_RC ) {
               form_wid._label1.p_caption="Capitalization:";
               #if 1
               /*form_wid._change_or_delete_all.p_caption="C&hange All";*/
               form_wid._ignore_all.p_enabled=1;
               form_wid._add_to_user1.p_enabled=1;
               form_wid._add_to_user2.p_enabled=1;
               #endif
            } else {
               form_wid._label1.p_caption="Word not found:";
               #if 1
               /*form_wid._change_or_delete_all.p_caption="C&hange All";*/
               form_wid._ignore_all.p_enabled=1;
               form_wid._add_to_user1.p_enabled=1;
               form_wid._add_to_user2.p_enabled=1;
               #endif
            }

            // Adjust column counter for a selected area
            //???if( gin_selected ) p_col=gcol;

            /* Scroll the gword into view */
            save_col=p_col;
            p_col=0;
            line_height=_text_height();
            set_scroll_pos(0,3*line_height);   // set_scroll_pos(0,p_cursor_y);
            p_col=save_col+_rawLength(gword);
            _refresh_scroll();
            p_col=save_col;

            /* Mark the gword */
            gcur_selection=_duplicate_selection('');
            _deselect(gcur_selection);
            len=_rawLength(gword);
            _select_char(gcur_selection);
            p_col+=len;
            _select_char(gcur_selection);
            p_col-=len;   // Put at beginning of gword so undo works correctly
            _show_selection(gcur_selection);
            break;

         } else if( gin_selected && gspell_status==SPELL_NO_MORE_WORDS_RC ) {
            /* Get the next line portion of selected area */
            gcur_selection=_duplicate_selection('');
            _show_selection(gold_selection);
            //messageNwait('a1 _width='_width);
            status=spell_filter_get_string(str,gin_source);
            _show_selection(gcur_selection);

            if( gin_source && status ) {
               // Goto the next comment or string in source file
               _show_selection(gold_selection);
               _end_select(gsource_mark_id);
               //messageNwait('_width='_width' fgsw='fgs_orig_width' fgsc='fgs_orig_col);
               p_col=fgs_orig_col+fgs_orig_width-fgs_orig_width+_width;
               //messageNwait('after fgs adjust');
               status=call_index(p_window_id,gsource_mark_id,0,gsource_proc_index);
               if( !status ) {
                  filter_init();   // Initialize selection filtering
                  //p_user.begin_selection();   // Go to beginning of selected area
                  spell_filter_get_string(str,gin_source);
                  _show_selection(gcur_selection);
               }
            }
            if( status ) {
               // At end of selected area or no more comment and strings to check in source file
               p_window_id=form_wid;
               return(SPELL_NO_MORE_WORDS_RC);
            }
            gword="";
            gcol=_leftcol;
            continue;
         } else {
            /* No more misspelled words or ERROR! */
            p_window_id=form_wid;
            return(gspell_status);
         }

      }
   }

   p_window_id=form_wid;   // Switch back to form

   // Refresh the '_word_not_found' text box
   _word_not_found.p_text= gword;

   // Refresh the '_suglist' combo box
   _suglist._lbclear();
   if( gspell_status!=SPELL_REPEATED_WORD_RC ) {
      _suglist._spell_insert_suglist(gword);
      _suglist.top();
      line=_suglist._lbget_text();
      if( line=="" ) {
         _suglist._lbadd_item("(No Suggestions)");
         _change_or_delete.p_enabled=0;
         _change_or_delete_all.p_enabled=0;
      }
      _suglist.p_text=line;
      _suglist._set_sel(1,length(_suglist.p_text)+1);
      _ignore.p_default=1;
   } else {
      _suglist._lbadd_item("(No Suggestions)");
      _change_or_delete_all.p_enabled=0;
      _suglist.p_text="";
      _suglist._set_sel(1);
   }
   p_window_id=form_wid._suglist;   // Give the 'Change to:' box focus
   _set_focus();
   return(0);
}

static spell_replace_word(int buf_wid)
{
   _str before,after,line;
   int width;
   gcur_selection=_duplicate_selection('');
   int len=buf_wid._rawLength(gword);
   int replace_len=buf_wid._rawLength(greplace_word);
   //buf_wid.get_line(line);
   if( gin_selected ) {
      before=buf_wid._expand_tabsc(_leftcol,gcol-_leftcol,'S');

      width=_width-(gcol+len-_leftcol);   // Width from end of gword to end of mark
      //messageNwait('gcol='gcol' _leftcol='_leftcol' wordlen='len);
      //messageNwait('i='(gcol+len)' width='width);
      after=buf_wid._expand_tabsc(gcol+len,width,'S');
      //messageNwait('before=<'before'> after=<'after'> greplace_word=<'greplace_word'>');
      /* Put the revised line portion of selected area */
      _show_selection(gold_selection);
      filter_put_string(before:+greplace_word:+after);
      _show_selection(gcur_selection);

      if( len>replace_len) {   // Adjust the global '_width' for this selected line
         _width-=(len-replace_len);
      } else if( len<replace_len ) {
         _width+=(replace_len-len);
#if 0
         buf_wid._get_selinfo(dummy1,last_col,dummy2,gold_selection);
         if( !_select_type(gold_selection,'I') ) --last_col;
         select_width=last_col-_leftcol+1;
         if( _width>select_width ) _width=select_width;   // Can't go outside the mark!
#endif
      }
   } else {
      before=buf_wid._expand_tabsc(1,gcol-1,'S');
      after=buf_wid._expand_tabsc(gcol+len,-1,'S');
      line=before:+greplace_word:+after;
      buf_wid.replace_line(line);

      // Now handle the case of spell checking within comments and quoted strings
      if( gin_source ) {
         if( len>replace_len ) {   // Adjust the global '_width' for this comment or string
            _width-=(len-replace_len);
         } else if( len<replace_len ) {
            _width+=(replace_len-len);
         }
      }
   }
   gword=greplace_word;   // This forces us past the newly replaced gword
}

static spell_delete_word(int buf_wid)
{
   gcur_selection=_duplicate_selection('');
   int len=buf_wid._rawLength(gword);
   _str before,after,line;
   buf_wid.get_line_raw(line);
   int first_nonblank_col,last_nonblank_col;
   int white_space_len;
   int width;
   int indent_col=buf_wid.text_col(line,pos('[~ \t]',line,1,'r'),'I');  // Imaginary indent column
   if( gin_selected ) {
      before=buf_wid.expand_tabs(line,_leftcol,gcol-_leftcol,'S');
      last_nonblank_col=lastpos('[~  \t]',before,'','r');
      white_space_len=length(before)-last_nonblank_col;   // This is the white space before the deleted gword which is also deleted
      //last_nonblank_col=buf_wid.text_col(before,last_nonblank_col,'I');
      before=substr(before,1,last_nonblank_col);

      width=_width-(gcol+len-_leftcol);   // Width from end of gword to end of mark
      after=buf_wid.expand_tabs(line,gcol+len,width,'S');

      /* Put the revised line portion of selected area */
      line=before:+after;
      _show_selection(gold_selection);
      if (_UTF8() && !buf_wid.p_UTF8) {
         filter_put_string(_MultiByteToUTF8(before:+after));
      } else {
         filter_put_string(before:+after);
      }
      _show_selection(gcur_selection);

      _width-=(len+white_space_len);   // Adjust the global '_width' for this selected line
   } else {
      if( gcol==indent_col ) {
         before=buf_wid.indent_string(indent_col-1);
         after=buf_wid.expand_tabs(line,gcol+len,-1,'S');
         first_nonblank_col=pos('[~ \t]',after,1,'r');
         white_space_len=first_nonblank_col-1;
         if (after!='') {
            after=substr(after,first_nonblank_col);
         }
      } else {
         after=buf_wid.expand_tabs(line,gcol+len,-1,'S');
         before=buf_wid.expand_tabs(line,1,gcol-1,'S');
         last_nonblank_col=lastpos('[~  \t]',before,'','r');
         white_space_len=length(before)-last_nonblank_col;   // This is the white space before the deleted gword which is also deleted
         //last_nonblank_col=buf_wid.text_col(before,last_nonblank_col,'I');
         before=substr(before,1,last_nonblank_col);
         gcol-=white_space_len;   // Update the starting column
      }

      line=before:+after;
      buf_wid.replace_line_raw(line);

      // Now handle the case of spell checking within comments and quoted strings
      if( gin_source ) {
         _width-=(len+white_space_len);   // Adjust the global '_width' for the comment or string
      }
   }
   gword="";   // This forces us to start back at beginning column of deleted gword.
}

static spell_exit(typeless exit_status)
{
   if( exit_status==SPELL_NO_MORE_WORDS_RC ) {
      int window_id = p_active_form._word_not_found.p_user;
      p_active_form._delete_window(SPELL_NO_MORE_WORDS_RC);
      // The buffer that we were spell checking is now active
      p_window_id = window_id;
      if( gin_selected && !gin_source ) {
         _end_select();
         _str mark=_duplicate_selection('');
         if( _select_type(mark)=='LINE' ) end_line();
      }
      if (!gSuppressDoneMsg) {
         _message_box('Spell Check Done','',MB_OK|MB_ICONEXCLAMATION);
      }
   } else if( exit_status && exit_status!='' ) {
      p_active_form._delete_window(exit_status);
      _message_box(get_message(exit_status),'',MB_OK|MB_ICONEXCLAMATION);
   }

   return(exit_status);
}

int _OnUpdate_spell_check_selection(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl() || target_wid._QReadOnly() ) {
      return(MF_GRAYED);
   }
   return(MF_ENABLED);
}
_command void spell_check_selection() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_AB_SELECTION|VSARG2_MARK)
{
   spell_check('m');
}
int _OnUpdate_spell_check(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl() || target_wid._QReadOnly() ) {
      return(MF_GRAYED);
   }
   return(MF_ENABLED);
}
/**
 * Starts spell checking from the cursor position in the current buffer.  If 
 * the 'M' option is given, then spell checking is performed within the 
 * visible selection and from the beginning of that selection.
 * 
 * @see spell_check_source
 * @see spell_check_word
 * @see spell_check_files
 * 
 * @appliesTo Editor_Control, Edit_Window
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */ 
_command void spell_check(...) name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   multifile = 0;
   int wid=p_window_id;
   _str a1=arg(1);
   if (upcase(a1)=='M' && _select_type()=="") {
      a1="";
   }
   if( a1=='' ) {
      if (upcase(p_lexer_name)=="HTML" || upcase(p_lexer_name)=="CFML" || upcase(substr(p_lexer_name,1,3))=="XML") {
         spell_check_source(p_lexer_name);
         return;
      }
      /* We are spell-checking from the cursor, but we must start
       * at the beginning of the current gword at the cursor
       */
      _str old_word_chars=p_word_chars;
      p_word_chars="A-Za-z'";
      int start_col;
      gword=cur_word(start_col);
#if 0
      if (gword=='') {
         if (!gSuppressDoneMsg) {
            _message_box('Spell Check Done','',MB_OK|MB_ICONEXCLAMATION);
         }
         p_word_chars=old_word_chars;   // QUICK!!! change'm back
         return;
      }
#endif
      p_word_chars=old_word_chars;   // QUICK!!! change'm back
      if (gword!='') {
         start_col=_text_colc(start_col,'I');
         p_col=start_col;
      }
   }
   typeless status=show('-modal -nocenter _spell_form',wid,a1);
}

/**
 * Spell checks the word at the cursor position.
 * 
 * @see spell_check
 * @see spell_check_source
 * @see spell_check_files
 * 
 * @appliesTo Editor_Control, Edit_Window
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */ 
_command void spell_check_word() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   multifile = 0;
   int wid=p_window_id;

   _str old_mark;
   save_selection(old_mark);
   _str mark=_duplicate_selection('');_deselect(mark);

   _str old_word_chars=p_word_chars;
   p_word_chars="A-Za-z'";
   int start_col;
   gword=cur_word(start_col);
   if (!isinteger(start_col) || start_col <= 0) {
      return;
   }
   start_col=_text_colc(start_col,'I');
   p_word_chars=old_word_chars;   // QUICK!!! change'm back

   int len=_rawLength(gword);

   p_col=start_col;
   _select_char(mark);
   p_col+=len;
   _select_char(mark);
   p_col-=len;   // Put cursor at beginning of gword so undo works properly
   _show_selection(mark);
   typeless status=show('-modal -nocenter _spell_form',wid,'M');
   end_select();   // Put cursor just after gword checked
   _deselect(mark);

   restore_selection(old_mark);
}


/*
   Search for next comment or string in buf_wid.  Returns 0 if successful.
*/
static typeless snc_adjust;
int select_next_comment_or_string(int buf_wid,typeless mark_id,boolean find_first /* seek pos */)
{
   _spell_clear('r');  // Clear repeat gword
   int orig_wid=p_window_id;
   p_window_id=buf_wid;
//   if (_select_type(mark_id)!='') {
//      _end_select(mark_id)
//   }
   // Need to adjust seek position after find string?
   if (!find_first && isinteger(snc_adjust)) {
      _nrseek(_nrseek()+snc_adjust);
   }
   //messageNwait('find');
   int status=_clex_find(COMMENT_CLEXFLAG|STRING_CLEXFLAG);
   if (status) {
      p_window_id=orig_wid;
      return(1);
   }
   snc_adjust='';
   _deselect(mark_id);
   int color=_clex_find(0,'g');
   if (color==CFG_STRING) {
      _str string_ch=get_text();
      _select_char(mark_id);
      ++p_col;
      int linenum=p_line;
      status=_clex_find(STRING_CLEXFLAG,'n');
      if (status) bottom();
      if (linenum!=p_line) {
         p_line=linenum;
         _end_line();
      }
      if (get_text(1,_nrseek()-1):==string_ch) {
         _nrseek(_nrseek()-1);
         snc_adjust=1;
      }
      _select_char(mark_id);
   } else {
      _select_char(mark_id);
      status=_clex_find(COMMENT_CLEXFLAG,'n');
      if (p_col==1) {
         // Need this for adjusting column
         up();_end_line();
      }
      if (status) bottom();
      _select_char(mark_id);
      _str info='';
   }
   _show_selection(mark_id);
   //messageNwait('marked');
   p_window_id=orig_wid;
   return(0);
}

// Desc:  Select the text string. Quotes are not included in the selection.
//        If the attr text string is not enclosed in quotes (" or '), we take
//        the first word or text up to the >.
// Retn:  0 for OK, 1 for error.
static int selectString(typeless mark_id, int selectText, var attrText)
{
   _str ch;
   int startSeek, endSeek;

   // Search for the = before the attr text and skip over it:
   _str result = search("=","rhi@XC");
   startSeek = _nrseek() + 1; _nrseek(startSeek);

   // Locate the start of the attr text:
   // The string quote may be " or ' ...
   int savepos;
   savepos = _nrseek();
   result = search("[\"\'>]","rhi@XC");
   ch = get_text();
   if (result) {
      if (selectText) _deselect(mark_id);
      return(1);
   }
   if (ch == ">") {
      // We may have a attr text without enclosing quotes...
      // If we do, get the text up to a blank space or >
      _nrseek(savepos);
      result = search("[ \t>]","rhi@XC");
      int currentpos;
      currentpos = _nrseek();
      if (currentpos > savepos) {
         _nrseek(savepos);
         if (selectText) {
             _select_char(mark_id);
             _nrseek(currentpos);
             _select_char(mark_id);
         } else {
            attrText = get_text(currentpos - savepos);
         }
         return(0);
      }
      if (selectText) _deselect(mark_id);
      return(1);
   }

   // Select the start of the text string:
   startSeek = _nrseek() + 1; _nrseek(startSeek);
   if (selectText) {
      _select_char(mark_id);
   }

   // Search for the end of the text string by locating the matching quote:
   _str searchString;
   searchString = "[" :+ ch :+ ">]";
   result=search(searchString,"rhi@XC");
   if (result || (get_text() == ">")) {
      if (selectText) _deselect(mark_id);
      return(1);
   }

   // Select to the end of the text string:
   endSeek = _nrseek();
   if (selectText) {
      _select_char(mark_id);
   } else {
      _nrseek(startSeek);
      attrText = get_text(endSeek - startSeek);
   }
   return(0);
}

// Desc:  Search and select text inside ALT of keyword.
// Retn:  1 for found and selected some attr text, 2 found some text, 0 for did nothing.
static int searchForAttrText(typeless mark_id, var tag, var attrText)
{
   // Get the tag:
   tag = "";
   _str text = lowcase(get_text(6));
   _str result,ch;

   // We currently check the following tags and attributes:
   //    <IMG ALT="attr_text">
   //    <META CONTENT="attr_text">
   if (pos("img",text,1,"I") == 1) {
      tag = "IMG";
      result=search("(ALT:b*=)|>","rhi@XC");
      if (result) return(0);
      ch = get_text();
      if (ch == ">") return(0);

      // Select the attr text:
      if (selectString(mark_id, 1, attrText)) {
         return(0);
      }
      return(1);
   } else if (pos("meta",text,1,"I") == 1) {
      tag = "META";

      // Make sure META's NAME is one that makes sense to spell check:
      result=search("(NAME:b*=)|>","rhi@XC");
      if (result) return(0);
      ch = get_text();
      if (ch == ">") return(0);
      if (selectString(mark_id, 0, text)) {
         return(0);
      }
      text = lowcase(text);
      if ((text != "keywords") && (text != "description") && (text != "abstract")) {
         return(0);
      }

      // Search for the CONTENT attr text:
      result=search("(CONTENT:b*=)|>","rhi@XC");
      if (result) return(0);
      ch = get_text();
      if (ch == ">") return(0);

      // Select the attr text:
      if (selectString(mark_id, 1, attrText)) {
         return(0);
      }
      return(1);
   } else if (pos("script",text,1,"I") == 1) {
      tag = "SCRIPT";
      result=search("(LANGUAGE:b*=)|>","rhi@XC");
      if (result) return(0);
      ch = get_text();
      if (ch == ">") return(0);

      // Select the attr text:
      if (selectString(mark_id, 0, attrText)) {
         return(0);
      }
      return(2);
   }
   return(0);
}

// Desc:  Check to see if specified line and column is inside the specified
//        code block.
// Retn:  1 for yes, 0 for no.
static int isWithinSection(int line, int col,
                           int startLine, int startCol, int endLine, int endCol)
{
   if (line < startLine) {
      return(0);
   }
   if ((line == startLine) && (col < startCol)) {
      return(0);
   }
   if (line > endLine) {
      return(0);
   }
   if ((line == endLine) && (col > endCol)) {
      return(0);
   }
   return(1);
}

// Desc:  Check to see if the specified text block has reached or gone past the
//        specified line and column.
// Retn:  1 for yes, 0 for no.
static int isSectionReachedLine(int line, int col, int endLine, int endCol)
{
   if (endLine < line) {
      return(0);
   }
   if ((line == endLine) && (endCol <= col)) {
      return(0);
   }
   return(1);
}
static void initHTMLSpellChecking(int fromLine, int fromCol)
{
   firstHTMLcheck = 1;
   insideScriptSection = 0;
   lastHTMLSeekPos = 0;
   fromHTMLCursorLine = fromLine;
   fromHTMLCursorCol = fromCol;
}
static int isWithinScriptSection()
{
   return(isWithinSection(p_line,p_col,
                          scriptStartLine,scriptStartCol,scriptEndLine,scriptEndCol));
}

// Desc:  Selects the next HTML text block to spell check.
// Retn:  0 for text block selected, 1 for end of spell checking for this buffer
int select_next_HTML_text(int buf_wid,typeless mark_id,boolean find_first /* seek pos */)
{
   _spell_clear('r');  // Clear repeat gword
   int orig_wid=p_window_id;
   p_window_id=buf_wid;

   // Special case first time:
   // If we are spell checking from the current cursor, we fake a spell
   // check from the beginning of the file until we reach the desired
   // start line.
   int skipUntilFirstLine;
   skipUntilFirstLine = 0;
   if (firstHTMLcheck) {
      firstHTMLcheck = 0;
      if (fromHTMLCursorLine) {
         // Move to the beginning of the file to start the fake check:
         _nrseek(0);
         skipUntilFirstLine = 1;
      }
   }

   // Restore last seek pos:
   // This is needed because the spell checking mechanism
   if (lastHTMLSeekPos) {
      _nrseek(lastHTMLSeekPos);
   }

   // Fake all spell checking until we reach the desired start line:
   //messageNwait("select_next_HTML_text h1");
   typeless status;
   typeless result;
   typeless tag;
   typeless seekpos;
   while (1) {

      // Deselect the last selection:
      int selectionStarted = 0;
      _deselect(mark_id);

      // If inside a tag last time, skip to the end of the tag:
      // We run into this situation whenevener the tag attr text is checked.
      if (insideKeyWordLastTime) {
         insideKeyWordLastTime = 0;
         result=search(">","rhi@XC");
         if (result) {
            p_window_id=orig_wid;
            return(1);
         }
      }

      // Normal search for text block to spell check:
      int done;
      done = 0;
      //messageNwait("select_next_HTML_text h2");
      while (!done) {
         // If inside a script section, spell check comments and strings:
         if (insideScriptSection) {
            if (!isWithinScriptSection()) {
               insideScriptSection = 0;
               //messageNwait("LEAVING SCRIPT");
            } else {
               //messageNwait("Inside script");
               result = _clex_find(STRING_CLEXFLAG|COMMENT_CLEXFLAG);
               if (result || !isWithinScriptSection()) {
                  // Found nothing! Get out of script section...
                  p_line = scriptEndLine;
                  p_col = scriptEndCol + 1;
                  insideScriptSection = 0;
                  //messageNwait("Leaving script 1");
                  continue;
               }
               int savepos;
               savepos = _nrseek();
               //messageNwait("found color="_clex_find(0,"G"));

               // Locate the end of the comment or string:
               result = _clex_find(STRING_CLEXFLAG|COMMENT_CLEXFLAG,"N");
               if (result || !isWithinScriptSection()) {
                  // Can't find the end of comment or string! Get out of script section...
                  p_line = scriptEndLine;
                  p_col = scriptEndCol + 1;
                  insideScriptSection = 0;
                  //messageNwait("Leaving script 2");
                  continue;
               }
               int currentpos;
               currentpos = _nrseek();

               // Select the comment or string for spell checking:
               _nrseek(savepos);
               _select_char(mark_id);
               _nrseek(currentpos);
               _select_char(mark_id);
               //messageNwait("SCRIPT comment/string");
               break;
            }
         }

         // Next word...
         int color=_clex_find(0,'g');
         _str ch=get_text();
         //messageNwait("select_next_HTML_text ch="ch);
         switch (color) {
         case CFG_KEYWORD:  // Special case certain tags...
            //messageNwait("CFG_KEYWORD");
            if (selectionStarted) {
               done = 1;
               break;
            }

            // Search and select text for ALT inside keyword:
            _str attrText;
            result = searchForAttrText(mark_id, tag, attrText);
            if (result == 1) {  // selected some attr text...  Just need to spell check it
               insideKeyWordLastTime = 1;
               done = 1;
               //messageNwait("Attr text");
               break;
            } else if (result == 2) {  // Special tags that need to be further processed...
               int savepos;
               savepos = _nrseek();
               if ((tag == "SCRIPT") /*&& (pos("java",attrText,1,"I") == 1)*/) {  // does not matter what language, we just check comments and strings
                  result = htool_selecttag2(scriptStartLine, scriptStartCol,
                                            scriptEndLine, scriptEndCol);
                  if (!result) {  // Mark the script section:
                     insideScriptSection = 1;
                  }
               }
               _nrseek(savepos);

               // Fall thru and skip to the end of the tag...
            }

            // Skip over keyword:
            result=search(">","rhi@XCS");
            if (result) {
               p_window_id=orig_wid;
               return(1);
            }
            seekpos = _nrseek(); result = _nrseek( seekpos + 1 );
            if (result) {
               done = 1;
               bottom();
            }
            break;

         case CFG_COMMENT:  // Skip over comment
            //messageNwait("CFG_COMMENT");
            if (selectionStarted) {
               done = 1;
               break;
            }
            status=_clex_find(COMMENT_CLEXFLAG,'N');
            if (status==STRING_NOT_FOUND_RC) {
               p_window_id=orig_wid;
               return(1);
            }
            break;

         default:  // Text in between tags...
            //messageNwait("default");
            // Break out of endless loop...
            if (_nrseek() == gLastHTMLSeekPos) {
               result = search(">","rhi@XCS");
               if (result) {
                  seekpos = _nrseek(); result = _nrseek(seekpos+1);
                  if (result=="") {
                     bottom();
                     p_window_id=orig_wid;
                     return(1);
                  }
                  break;
               }
               ch=get_text();
            }
            gLastHTMLSeekPos = _nrseek();
            if (pos(ch, "\n\r<>")) {
               seekpos = _nrseek();
               result = _nrseek(seekpos+1);
               if (result=="") {
                  bottom();
                  p_window_id=orig_wid;
                  return(1);
               }
               break;
            }
            if (!selectionStarted) {
               _select_char(mark_id);
               selectionStarted = 1;
            }

            // Locate the end of the text to spell check:
            color = _clex_find(OTHER_CLEXFLAG, "N");
            if (color) {
               bottom();
               p_window_id=orig_wid;
               return(1);
            }
            done = 1;
            break;
         }  // switch on color

      }  // normal search for text block

      // Complete the selection:
      // (The selection may be just a block of space...)
      if (selectionStarted) {
         _select_char(mark_id);
         _show_selection(mark_id);
         //messageNwait("Regular text");
      }

      // No need to do any special skips, done!
      if (!skipUntilFirstLine) {
         //messageNwait("select_next_HTML_text break1");
         break;
      }

      // If the selection encompasses the desired start line,
      // break out of fake spell checking.  Otherwise, continue with
      // the fake spell checking.
      if (isSectionReachedLine(fromHTMLCursorLine,fromHTMLCursorCol,p_line,p_col)) {
         //messageNwait("select_next_HTML_text break2");
         break;  // get out of fake check
      }

   }  // fake check

   lastHTMLSeekPos = _nrseek();
   p_window_id=orig_wid;
   return(0);
}
int _OnUpdate_spell_check_source(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl() || target_wid._QReadOnly() ) {
      return(MF_GRAYED);
   }
   if (p_lexer_name=='') {
      return(MF_GRAYED);
   }
   return(MF_ENABLED);
}
/**
 * Starts spell checking from the cursor position comments and strings in 
 * the current buffer.  The p_lexer_name property must be set to a section 
 * name defined in "vslick.vlx" or user defined ".vlx" file.
 * 
 * @see spell_check
 * @see spell_check_word
 * @see spell_check_files
 * 
 * @appliesTo Editor_Control, Edit_Window
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */ 
_command void spell_check_source(...) name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   multifile = 0;
   int wid=p_window_id;

   if (p_lexer_name=='') {
      _message_box("This extension has no lexer.  See Color Coding for information on defining a lexer");
      return;
   }
   _str proc_name='select_next_comment_or_string';
   if (upcase(p_lexer_name)=="HTML" || upcase(p_lexer_name)=="CFML" || upcase(substr(p_lexer_name,1,3))=="XML") {
      if (arg() > 0 && (upcase(arg(1))=="HTML" || upcase(arg(1))=="CFML" || upcase(substr(arg(1),1,3))=="XML")) {
         initHTMLSpellChecking(p_line,p_col);
         proc_name='select_next_HTML_text';
      }
   }
   int index=find_index(proc_name,PROC_TYPE);
   if( index=='' || !index || !index_callable(index) ) {
      _message_box("Can't find proc '":+proc_name:+"'",'',MB_OK|MB_ICONEXCLAMATION);
      return;
   }
   _str old_mark;
   save_selection(old_mark);
   _str mark_id=_duplicate_selection('');_deselect(mark_id);
   typeless status=show('-modal -nocenter _spell_form',wid,2,index,mark_id);

   _deselect(mark_id);
   restore_selection(old_mark);
   clear_message();
}

// Desc:  Check to see if this is a valid source file.
// Retn:  1 for yes, 0 for no.
static int spIsValidSourceFile( _str filename )
{
   _str ext = _get_extension(filename);
   if ( ext == "" ) return( 0 );
   ext = upcase(ext);
   if ( ext == "HTML" || ext == "HTM" || ext == "CFM" || ext == "CFML" ||
            ext == "C" || ext == "CPP" || ext == "CC" || ext == "H" ||
            ext == "HH" || ext == "E" ||
            ext == "JAV" || ext == "JAVA" || ext=="CS" ) {
      return( 1 );
   }
   return( 0 );
#if 0
   if (p_lexer_name=='') return(0);
   if (p_lexer_name=="HTML" || p_lexer_name=="C" ||
       p_lexer_name=="cpp" || p_lexer_name=="Java" || p_lexer_name=="CSharp") {
      return( 1 );
   }
   return( 0 );
#endif
}

static int spCheckSourceInBuffer()
{
   int wid=p_window_id;

   if (p_lexer_name=='') {
      spell_check();
      clear_message();
      if (gspCancelled) return( 1 );
      return( 0 );
   }
   _str proc_name;
   if (p_lexer_name=="HTML") {
      initHTMLSpellChecking(0,0);
      proc_name='select_next_HTML_text';
   } else {
      proc_name='select_next_comment_or_string';
   }
   int index=find_index(proc_name,PROC_TYPE);
   if( index=='' || !index || !index_callable(index) ) {
      _message_box("Can't find proc '":+proc_name:+"'",'',MB_OK|MB_ICONEXCLAMATION);
      return( -1 );
   }
   _str old_mark;
   save_selection(old_mark);
   _str mark_id=_duplicate_selection('');_deselect(mark_id);
   typeless status=show('-modal -nocenter _spell_form',wid,2,index,mark_id);

   _deselect(mark_id);
   restore_selection(old_mark);
   clear_message();
   if (gspCancelled) return( 1 );
   return( 0 );
}

// Desc:  Check to see if the specified buffer is the editor's buffer list.
static boolean isFileInBufList(_str bufname)
{
   return(buf_match(bufname,1,'hx')!='');
}

defeventtab _mfspellcheck_form;

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _mfspellcheck_form_initial_alignment()
{
   sizeBrowseButtonToTextBox(_files.p_window_id, _browsedir2.p_window_id, 0, _bufList.p_x + _bufList.p_width);
}

void _browsedir2.lbutton_up()
{
   _str result = _ChooseDirDialog();
   if( result=='' ) {
      return;
   }
   _str line=_files.p_text;
   if( line!='' ) {
      _str lastch=substr(strip(line,'T'),length(line),1);
      if( lastch==FILESEP ) {
         #if __UNIX__
         line=strip(line,'T'):+'* ':+result;
         #else
         line=strip(line,'T'):+'*.* ':+result;
         #endif
      } else {
         line=strip(line,'T'):+' ':+result;
      }
   } else {
      line=result;
   }
   _files.p_text=line;
   _files._end_line();
   _files._set_focus();
}
static void add_project_files()
{
   if (_project_name=='') {
      return;
   }
   int orig_view_id=p_window_id;
   //status=_ini_get_section(_project_name,"FILES",temp_view_id);
   //11:43am 8/18/1997
   //Dan changed for makefile support
   int temp_view_id;
   int status=GetProjectFiles(_project_name,temp_view_id);
   if (status) {
      p_window_id=orig_view_id;
      return;
   }
   _str line;
   p_window_id=temp_view_id;
   _str mark_id=_alloc_selection();
   top();_select_line(mark_id);
   bottom();_select_line(mark_id);
   _shift_selection_right(mark_id);
   _deselect(mark_id);
   p_col=1;p_line=1;
   p_line=0;
   while (!down()) {
      get_line(line);
      replace_line('>'substr(line,2));
   }
   top();_select_line(mark_id);
   bottom();_select_line(mark_id);
   p_window_id=orig_view_id;
   bottom();
   _copy_to_cursor(mark_id);
   _free_selection(mark_id);
   _delete_temp_view(temp_view_id);
}
static void spFillInBufferList()
{
   p_window_id=_control _bufList;
   _str name=buf_match('',1);
   for (;;) {
      if (rc) break;
      if (name!='' && name!='.process' ) {
         _lbadd_item(name);
      }
      name=buf_match('',0);
   }
}
static void spUpdateNofSelected()
{
   _nofselected.p_caption=_bufList.p_Nofselected' of '_bufList.p_Noflines' selected';
}
static _str spGetFileList(var files,var atbuflist,... /* include_project_files */)
{
   // Check the files
   typeless include_project_files=0;
   if (arg()>=3) {
      include_project_files=arg(3);
   }

   int orig_wid=p_window_id;
   typeless result=_unix_expansion(_files.p_text);
   if (result!='' && (_incSubDir.p_value) && (_incSubDir.p_enabled)) {
      result= '+t 'result;
   }
   _str tree_option='';
   _str line=result;
   int Noffiles=0;
   int one_file_found=0;
   _str first_file_not_found='';
   for (;;) {
      _str word = parse_file(line);
      if (word=='') break;
      _str ch=substr(word,1,1);
      if (ch=='-' || ch=='+') {
         _str option=upcase(substr(word,2));
         switch (option) {
         case 'T':
            tree_option='+t';
            break;
         default:
            _message_box('Invalid switch');
            return(1);
         }
      } else {
         ++Noffiles;
         if (file_match('-pd 'tree_option' 'word,1)!='') {
             one_file_found=1;
         } else if (!iswildcard(word)) {
            _message_box(nls('File "%s" not found',word));
            return(1);
         } else {
            if (Noffiles==1) {
               first_file_not_found=word;
            }
         }
      }
   }
   if (!one_file_found && first_file_not_found!='') {
      _message_box(nls('File "%s" not found',first_file_not_found));
      return(1);
   }
   files=result;
   if (include_project_files) {
      _bufList.add_project_files();
   }
   atbuflist=_bufList._lbmulti_select_result();

   return(0);
}
_str _ok.lbutton_up()
{
   int fid = p_active_form;
   typeless status = spGetFileList( _param3, _param4, _incProjFiles.p_value );
   if (status) return("");
   if (_param3=='' && _param4=='') {
      _message_box('No files selected');
      p_window_id=_control _files;
      _set_focus();
      _set_sel(1,length(p_text)+1);
      return("");
   }
   _save_form_response();
   fid._delete_window(0);
   return( 0 );
}
void _ok.on_create()
{
   _retrieve_prev_form();
   spFillInBufferList();
   spUpdateNofSelected();

   _mfspellcheck_form_initial_alignment();
}
_str _cancel.lbutton_up()
{
   p_active_form._delete_window(0);
   _param3 = "";
   _param4 = "";
   return("");
}
void _bufList.on_change(int reason)
{
   if (reason!=CHANGE_SELECTED) return;
   spUpdateNofSelected();
}
static void spSpellCheckFiles(_str fileMatch, _str inFileList)
{
   int inList, found;
   _str filelist[];

   // Build file list:
   int i;
   i = 0;
   for (;;) {
      _str word = parse_file(inFileList);
      if (word=='') break;
      filelist[i] = strip(word,'B','"');
      i++;
   }
   int filecount = filelist._length();
   if ( fileMatch != "" ) {
      _str recurse;
      recurse = "";
      for (;;) {
         _str filespec=parse_file(fileMatch);
         if (filespec=='') {
            break;
         }
         if (filespec == "+t") {
            recurse = "+t ";
            filespec=parse_file(fileMatch);
            if (filespec=='') {
               break;
            }
         }
         _str file = file_match('-p -d 'recurse:+filespec, 1);
         for (;;) {
            if ( file == "" ) break;

            // Check and skip over duplicate:
            file = absolute(file);
            found = 0;
            int j;
            for (j=0; j<filecount; j++) {
               if ( file == filelist[j] ) {
                  found = 1;
                  break;
               }
            }
            if (!found) {
               filelist[i] = strip(file,'B','"');   // Add to file list:
               i++;
            }
            file = file_match('-p -d 'recurse:+filespec, 0);
         }
      }
   }
   filecount = filelist._length();

#if 0
   for (i=0;i<filecount;++i) {
      say( i" "absolute(filelist[i]) );
   }
#endif

   // Check files:
   int suddenStop = 0;
   gSuppressDoneMsg = 1;
   multifile = 1;
   for (i=0;i<filecount;++i) {
      inList = 0;
      if ( isFileInBufList(filelist[i]) ) inList = 1;
      //say( "filename "filelist[i]" inlist="inList );
      //if ( !spIsValidSourceFile( filelist[i]) ) continue;

      // To allow us to find buffer with invalid file names like "Directory of ..." buffer
      // look for the buffer first.
      _str path=filelist[i];
      typeless buf_id, buf_flags, buf_name;
      parse buf_match(path,1,'hvx') with buf_id . buf_flags buf_name;
      boolean file_already_loaded= buf_id!='';

      int edit_status;
      if (file_already_loaded) {
         edit_status=edit('+bi 'buf_id);
      } else {
         edit_status=edit(maybe_quote_filename(path));
      }

      //edit( maybe_quote_filename(filelist[i]) );
      top();
      if ( i != (filecount-1) ) gSuppressDoneMsg = 1;
      int status = spCheckSourceInBuffer();
      if ( status == -1 ) {
         suddenStop = 1;
         if ( !file_already_loaded ) quit();
         break;
      } else if ( status == 1 ) {
         suddenStop = 1;
         if ( !file_already_loaded ) quit();
         break;
      } else if ( status == 2 ) {
         _message_box( "Skipping over non-source file "filelist[i] );
      }
      if ( !file_already_loaded ) quit();
   }
   gSuppressDoneMsg = 0;
   if (!suddenStop) {
      _message_box("Spell check done.");
   }
}
/**
 * Displays dialog for spell checks multiple source files. This command 
 * always does a language sensitive spell check.  For HTML, markup that 
 * is not literal text is ignored.  For source languages where color coding 
 * is provided, only comments and strings are spell checked.
 * 
 * @see spell_check
 * @see spell_check_source
 * @see spell_check_files
 * 
 * @appliesTo Editor_Control, Edit_Window
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */ 
_command void spell_check_files()  name_info(','VSARG2_EDITORCTL)
{
   typeless result=show('-modal _mfspellcheck_form',arg(1),p_window_id);
   if (result) return;
   if (_param3=="" && _param4=="") return;
   //say( "files="_param3 );
   //say( "atbuflist="_param4 );
   spSpellCheckFiles( _param3, _param4 );
}
