////////////////////////////////////////////////////////////////////////////////////
// $Revision: 49009 $
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
#require "se/lang/api/LanguageSettings.e"
#import "codehelp.e"
#import "combobox.e"
#import "cutil.e"
#import "hex.e"
#import "ini.e"
#import "listproc.e"
#import "main.e"
#import "markfilt.e"
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "util.e"
#endregion

using namespace se.lang.api;

#define BOX_INI_FILENAME "box.ini"
#define SAVING_SETTINGS _ctl_extension.p_user

/**
 * If positive, then the Comment Block command under the Document window (box())
 * will use the Comment Wrap settings to determine how wide to make the comment.
 * Additionally, Comment Wrap must be enabled for block comments.  The comment
 * wrap setting will be ignored if they specify a width that is not wide enough 
 * for the selected text. 
 *
 * @default 1
 * @categories Configuration_Variables
 */
int def_CW_use_width_for_box = 1;

static  BlockCommentSettings_t _settings:[];
static  BlockCommentSettings_t _orig_settings:[];

//Define the triggers and styles for Doc Comment skeleton creation
#define DocCommentStyleLabel    'param'
#define DocCommentFlagDelimiter "\t"
_str def_default_doc_comment_flags = DocCommentFlagDelimiter:+DocCommentTrigger1:+DocCommentFlagDelimiter:+DocCommentStyle1:+DocCommentFlagDelimiter:+DocCommentTrigger2:+DocCommentFlagDelimiter:+DocCommentStyle2:+DocCommentFlagDelimiter:+DocCommentTrigger3:+DocCommentFlagDelimiter:+DocCommentStyle3:+DocCommentFlagDelimiter:+DocCommentTrigger4:+DocCommentFlagDelimiter:+DocCommentStyle2:+DocCommentFlagDelimiter;


/**
 * Copies the options found at Language > Comments from one language to another.
 * 
 * @param srcLang          language to copy settings FROM
 * @param destLang         language to copy settings TO
 * 
 * @return                 true if successful, false otherwise
 */
boolean _copy_language_comments_settings(_str srcLang, _str destLang)
{
   BlockCommentSettings_t settings;
   if (!getLangCommentSettings(srcLang, settings)) {

      saveCommentSettings(destLang, settings);

      return _CopyLanguageOption(srcLang, destLang, 'doccomment') &&
         _CopyLanguageOption(srcLang, destLang, 'commentediting');
   }

   return false;
}

void clearCommentSettings(_str langId)
{
   _settings._deleteel(langId);
   if (!_settings._length()) _settings._makeempty();

   _orig_settings._deleteel(langId);
   if (!_orig_settings._length()) _orig_settings._makeempty();
}

/**
 * Retrieves the BlockCommentSettings_t struct containing comment settings for 
 * the given language. 
 * 
 * @param langId                 language id (p_LangId)
 * @param langSettings           comment settings struct
 * 
 * @return                       0 if settings were retrieved successfully, 1 on 
 *                               error
 */
int getLangCommentSettings(_str langId, BlockCommentSettings_t &langSettings)
{
   langSettings.tlc='';
   langSettings.thside='';
   langSettings.trc='';
   langSettings.lvside='';
   langSettings.rvside='';
   langSettings.blc='';
   langSettings.bhside='';
   langSettings.brc='';
   langSettings.comment_left='';
   langSettings.comment_right='';
   langSettings.comment_col=0;
   langSettings.firstline_is_top=false;
   langSettings.lastline_is_bottom=false;
   langSettings.mode = LEFT_MARGIN;
   if (langId != '') {
      // IF we have already retrieved the comment settings for this language
      if (!_settings:[langId]._isempty()) {
         langSettings = _settings:[langId];
      } else if (!getCommentSettings(langId, _settings) ) {
         langSettings = _settings:[langId];
         _orig_settings:[langId] = langSettings;
      } else return 1;
   } else {
      return 1;
   }

   return 0;
}

/**
 * Converts selected text into box comment using the comment setup.
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * 
 * @categories Miscellaneous_Functions
 */
_command int box() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK|VSARG2_REQUIRES_AB_SELECTION)
{
   BlockCommentSettings_t s;

   if ( !select_active() ) {
      _message_box('No selection active');
      return(1);
   }

   int status=0;
   typeless orig_values;
   _str lang='';
   _str orig_lang='';
   int len = 0;

   typeless stype=_select_type();

   if ( arg()>1 ) {
      s.tlc=arg(1);
      s.trc=arg(2);
      s.blc=arg(3);
      s.brc=arg(4);
      s.bhside=arg(5);
      s.thside=arg(6);
      s.lvside=arg(7);
      s.rvside=arg(8);
      s.comment_col=0;   // Hardcode this
      s.firstline_is_top=false;
      s.lastline_is_bottom=false;
      s.mode = def_comment_line_mode;
   } else {
      parse arg(1) with lang .;
      if ( lang=='' ) {
         status=_EmbeddedStart(orig_values);
         lang=p_LangId;
         if ( status==1 ) _EmbeddedEnd(orig_values);
      }
      orig_lang=lang;
      if ( lang!='' ) {
         BlockCommentSettings_t temp:[];
         if ( getCommentSettings(lang,temp,'b') ) {
            _message_box('There are no comment block settings for 'orig_lang);
            return(1);
         }
         s=temp:[lang];
      } else {
         _message_box('There are no comment block settings for 'orig_lang);
         return(1);
      }
   }
   if (s.comment_col > 0) {
      return comment();
   }
   if (p_xlat) {
      s.tlc=_UTF8ToMultiByte(s.tlc);
      s.trc=_UTF8ToMultiByte(s.trc);
      s.blc=_UTF8ToMultiByte(s.blc);
      s.brc=_UTF8ToMultiByte(s.brc);
      s.bhside=_UTF8ToMultiByte(s.bhside);
      s.thside=_UTF8ToMultiByte(s.thside);
      s.lvside=_UTF8ToMultiByte(s.lvside);
      s.rvside=_UTF8ToMultiByte(s.rvside);
   }
   boolean firstline_is_top=s.firstline_is_top;
   boolean lastline_is_bottom=s.lastline_is_bottom;

   // Find the widest left-hand border so we can pad accordingly
   int lside_widest = length(s.lvside);
   if (firstline_is_top) {
      lside_widest = max(lside_widest, length(s.tlc));
   } 
   if (lastline_is_bottom) {
      lside_widest = max(lside_widest, length(s.blc));
   }

   // Find the widest right-hand border so we can pad accordingly
   int rside_widest = length(s.rvside);
   if (firstline_is_top) {
      rside_widest = max(rside_widest, length(s.trc));
   } 
   if (lastline_is_bottom) {
      rside_widest = max(rside_widest, length(s.brc));
   }

   int start_col=0;
   int end_col=0;
   int width=0;
   save_pos(auto p);
   int width2;
   if ( stype=='LINE' ) {
      width=longest_line_in_selection_raw()+1;
      width2 = width - 1;
      start_col=1;
      end_col=width;
   } else if ( stype=='BLOCK' ) {
      if ( s.comment_col>0 ) {
         // Override with a LINE selection.
         // It does not make sense to specify a block selection for
         // a language that has a comment column (e.g. COBOL).
         _select_type('','L','LINE');
         width=longest_line_in_selection_raw();
         width2 = width;
         start_col=1;end_col=width;
         stype='LINE';
      } else {
         int dummy=0;
         _get_selinfo(start_col,end_col,dummy);
         width=end_col-start_col+1;
         width2 = width;
      }
   } else {
      // stype=='CHAR'
      // Override with a LINE selection.
      _select_type('','L','LINE');
      width=longest_line_in_selection_raw();
      width2 = width;
      start_col=1;end_col=width;
      stype='LINE';
   }

   boolean indentToCode = false; 
   int leftmostcol=MAX_LINE;
   int leftmostcol2 = _leftmost_col_in_selection();
   int comment_col=0;
   if ( stype=='LINE' && s.comment_col>0 ) {
      leftmostcol=_leftmost_col_in_selection();
      if ( leftmostcol<s.comment_col ) {
         comment_col=s.comment_col;
      }
   } else if (stype == 'LINE' && s.mode == LEVEL_OF_INDENT) { // where to put commenting characters?
      leftmostcol=_leftmost_col_in_selection();
      indentToCode = true;
   }
   int noflines=count_lines_in_selection();

   _begin_select();

   if (stype=='LINE') {
      if (s.mode == LEFT_MARGIN) {
         leftmostcol2 = 1;
      }
      if (s.comment_col > 0 && s.comment_col < leftmostcol2) {
         leftmostcol2 = s.comment_col;
      }
      width = width2 + lside_widest + rside_widest + 2;

      //Get comment wrap width
      if (def_CW_use_width_for_box && _GetCommentWrapFlags(CW_ENABLE_COMMENT_WRAP) && _GetCommentWrapFlags(CW_ENABLE_BLOCK_WRAP)) {
         int cwWidth = width;
         while (true) {
            if (_GetCommentWrapFlags(CW_AUTO_OVERRIDE)) break;
            
            if (_GetCommentWrapFlags(CW_USE_FIXED_MARGINS)) {
               cwWidth = _GetCommentWrapFlags(CW_RIGHT_MARGIN);
               break;
            }
            if (_GetCommentWrapFlags(CW_USE_FIXED_WIDTH)) {
               cwWidth = _GetCommentWrapFlags(CW_FIXED_WIDTH_SIZE) + leftmostcol2 - 1;
               if (_GetCommentWrapFlags(CW_MAX_RIGHT)) {
                  if (cwWidth > _GetCommentWrapFlags(CW_MAX_RIGHT_COLUMN)) {
                     cwWidth = _GetCommentWrapFlags(CW_MAX_RIGHT_COLUMN);
                  }
               }
               break;
            }
            break;
         }
         if (cwWidth > width) {
            width = cwWidth;
         }
      }
      width = width - lside_widest - rside_widest - 2 - leftmostcol2 + 1;
   }

   // Test for special case of boxing a single line
   int single_line=0;
   save_pos(auto p2);   // So the scroll pos does not change
   if ( down() ) {
      single_line=1;
   } else {
      single_line= (_end_select_compare()>0 || noflines==1)?(1):(0);
      up();
   }
   restore_pos(p2);

   _str line='';
   _str before='';
   _str middle='';
   _str after='';
   _str new_line='';
   _str topside='';
   int down_count=0;
   int topsidelen=0;
   if ( firstline_is_top ) {
      if ( stype=='LINE' ) {
         get_line_raw(line);
         line = strip(line, 'T');
      } else {
         get_line_raw(line);
      }

      // if we're using level of indent mode, we want to push the comment marks up to code
      if (indentToCode) {
         before=expand_tabs(line,1,leftmostcol-1,'S');
         middle=expand_tabs(line,leftmostcol,width);
      } else {
         before=expand_tabs(line,1,start_col-1,'S');
         middle=expand_tabs(line,start_col,width);
      }

      after=expand_tabs(line,end_col+1,-1,'S');

      if ( comment_col ) {
         // It's a line selection, so can blast 'before'
         before=indent_string(comment_col-1);
         middle=substr(middle,leftmostcol);
      }

      topsidelen=length(middle);   /* Save this just in case we need to use it
                                    * later to re-select.
                                    */
      // Pad the left side to be as wide as the widest left border part
      len = length(s.tlc);
      if (len < lside_widest) {
         middle = substr("", 1, lside_widest-len) :+ middle;
      }

      // Pad the right side to be as wide as the widest right border part
      if ( single_line && lastline_is_bottom ) {
         len = length(s.brc);
         if ( len < rside_widest ) {
            after = after :+ substr("", 1, rside_widest-len);
         }
         new_line = before :+ s.tlc :+ middle :+ s.brc :+ after;
      } else {
         len = length(s.trc);
         if ( len < rside_widest ) {
            after = after :+ substr("", 1, rside_widest-len);
         }
         new_line = before :+ s.tlc :+ middle :+ s.trc :+ after;
      }

      replace_line_raw(new_line);
      if ( !single_line ) down();
   } else {
      topside='';
#if 1
      /* +length of longest left side of box
       * +length of longest right side of box
       * -length(tlc) for top-left-corner box chars
       * -length(trc) for top-right-corner box chars
       */
      topsidelen=width+lside_widest+rside_widest-length(s.tlc)-length(s.trc);
#else
      /* +length(lvside) for the left side of box
       * +length(rvside) for the right side of box
       * -length(tlc) for top-left-corner box chars
       * -length(trc) for top-right-corner box chars
       */
      topsidelen=width+length(s.lvside)+length(s.rvside)-length(s.tlc)-length(s.trc);
#endif
      if ( topsidelen<0 ) topsidelen=0;   // Just in case
      if ( s.thside!='' ) {
         topside=substr('',1,topsidelen,s.thside);
      }
      get_line_raw(line);
      if ( comment_col ) {
         // It's a line selection, so there is nothing before 'start_col'
         replace_line_raw(indent_string(comment_col-1):+s.tlc:+topside:+s.trc);
      } else if (indentToCode) {
         replace_line_raw(substr('',1,leftmostcol-1):+s.tlc:+topside:+s.trc);
      } else {
         replace_line_raw(substr('',1,start_col-1):+s.tlc:+topside:+s.trc);
      }
      insert_line_raw(line);
   }
   int i=0;
   if ( !(single_line && (firstline_is_top || lastline_is_bottom)) &&
        !(noflines==2 && firstline_is_top && lastline_is_bottom) ) {
      for ( ;; ) {
         if ( stype=='LINE' ) {
            get_line_raw(line);
            line = strip(line, 'T');
         } else {
            get_line_raw(line);
         }

         if (indentToCode) {
            before=expand_tabs(line,1,leftmostcol-1,'S');
            middle=expand_tabs(line,leftmostcol,width);
         } else {
            before=expand_tabs(line,1,start_col-1,'S');
            middle=expand_tabs(line,start_col,width);
         }

         after=expand_tabs(line,end_col+1,-1,'S');

         if ( comment_col ) {
            // It's a line selection, so can blast 'before'
            before=indent_string(comment_col-1);
            middle=substr(middle,leftmostcol);
         }

         // Pad the left/right side to be as wide as the widest left/right border part
         len = length(s.lvside);
         if (len < lside_widest ) {
            middle = substr("", 1, lside_widest-len) :+ middle;
         }
         len = length(s.rvside);
         if (len < rside_widest) {
            after = after :+ substr("", 1, rside_widest-len);
         }

         new_line = before :+ s.lvside :+ middle :+ s.rvside :+ after;
         replace_line_raw(new_line);
         ++i;
         status=down();
         if ( status ) break;
         if ( _end_select_compare()>0 ||
              (lastline_is_bottom && !_end_select_compare()) ) {
            break;
         }
      }
      if ( !status && !(lastline_is_bottom && !_end_select_compare()) ) {
         up();
      }
   }
   down_count+=i;

   _str bottomside='';
   int bottomsidelen=0;
   if ( lastline_is_bottom ) {
      if ( !(single_line && firstline_is_top) ) {
         get_line_raw(line);
         if ( stype=='LINE' ) {
            line=strip(line,'T');
         }

         if (indentToCode) {
            before=expand_tabs(line,1,leftmostcol-1,'S');
            middle=expand_tabs(line,leftmostcol,width);
         } else {
            before=expand_tabs(line,1,start_col-1,'S');
            middle=expand_tabs(line,start_col,width);
         }

         after=expand_tabs(line,end_col+1,-1,'S');
         if ( comment_col ) {
            // It's a line selection, so can blast 'before'
            before=indent_string(comment_col-1);
            middle=substr(middle,leftmostcol);
         }
         bottomsidelen=length(middle);   /* Save this just in case we need to use it
                                          * later to re-select.
                                          */

         // Pad the left/right side to be as wide as the widest left/right border part
         len = length(s.blc);
         if (len < lside_widest) {
            middle = substr("", 1, lside_widest-len) :+ middle;
         }
         len=length(s.brc);
         if ( len<rside_widest ) {
            after=after:+substr("",1,rside_widest-len);
         }

         new_line = before :+ s.blc :+ middle :+ s.brc :+ after;
         replace_line_raw(new_line);
         ++down_count;
      }
   } else {
      bottomside='';
#if 1
      /* +length of the longest left side of box
       * +length of the longest right side of box
       * -length(blc) for bottom-left-corner box chars
       * -length(brc) for bottom-right-corner box chars
       */
      bottomsidelen=width+lside_widest+rside_widest-length(s.blc)-length(s.brc);
#else
      /* +length(lvside) for the left side of box
       * +length(rvside) for the right side of box
       * -length(blc) for bottom-left-corner box chars
       * -length(brc) for bottom-right-corner box chars
       */
      bottomsidelen=width+length(s.lvside)+length(s.rvside)-length(s.blc)-length(s.brc);
#endif
      if ( bottomsidelen<0 ) bottomsidelen=0;   // Just in case
      if ( s.bhside!='' ) {
         bottomside=substr('',1,bottomsidelen,s.bhside);
      }
      if ( comment_col ) {
         // It's a line selection, so there is nothing before 'start_col'
         insert_line_raw(indent_string(comment_col-1):+s.blc:+bottomside:+s.brc);
      } else if (indentToCode) {
         insert_line_raw(substr('',1,leftmostcol-1):+s.blc:+bottomside:+s.brc);
      } else {
         insert_line_raw(substr('',1,start_col-1):+s.blc:+bottomside:+s.brc);
      }
      ++down_count;
   }

   // Now re-select the text inside the box
   _begin_select();_deselect();
   if ( stype=='LINE' ) {
      _select_line();
      down(down_count);
      _select_line();
      _begin_select();p_col=1;
   } else {
      _select_block();
      down(down_count);
      if ( single_line && firstline_is_top && lastline_is_bottom ) {
         p_col+=length(s.tlc)+topsidelen+length(s.brc)-1;
      } else {
         if ( lastline_is_bottom ) {
            p_col+=length(s.blc)+bottomsidelen+length(s.brc)-1;
         } else {
            p_col+=length(s.blc)+bottomsidelen+length(s.brc)-1;
         }
      }
      _select_block();
      _begin_select();
   }
   return(0);
}

_command int box_erase() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   BlockCommentSettings_t s;

   if ( !select_active() ) {
      _message_box('No selection active');
      return(1);
   }

   int status=0;
   _str lang='';
   _str orig_lang='';
   _str param='';
   typeless stype=_select_type();

   if ( arg()>1 ) {
      s.tlc=arg(1);
      s.trc=arg(2);
      s.blc=arg(3);
      s.brc=arg(4);
      s.bhside=arg(5);
      s.thside=arg(6);
      s.lvside=arg(7);
      s.rvside=arg(8);
      s.comment_col=0;
      s.firstline_is_top=false;
      s.lastline_is_bottom=false;
   } else {
      parse arg(1) with param .;
      lang=param;
      orig_lang=lang;
      if ( lang=='' ) {
         typeless orig_values;
         status=_EmbeddedStart(orig_values);
         lang=p_LangId;
         if ( status==1 ) _EmbeddedEnd(orig_values);
         orig_lang=lang;
      }
      if ( lang!='' ) {
         BlockCommentSettings_t temp:[];

         if ( getCommentSettings(lang,temp,'b') ) {
            _message_box('No comments setup for 'orig_lang);
            return(1);
         }
         s=temp:[lang];
      } else {
         _message_box('No comments setup for 'orig_lang);
         return(1);
      }
   }
   if (p_xlat) {
      s.tlc=_UTF8ToMultiByte(s.tlc);
      s.trc=_UTF8ToMultiByte(s.trc);
      s.blc=_UTF8ToMultiByte(s.blc);
      s.brc=_UTF8ToMultiByte(s.brc);
      s.bhside=_UTF8ToMultiByte(s.bhside);
      s.thside=_UTF8ToMultiByte(s.thside);
      s.lvside=_UTF8ToMultiByte(s.lvside);
      s.rvside=_UTF8ToMultiByte(s.rvside);
   }

   _undo('S');   // So we can quickly undo if a problem
   int start_col=0;
   int end_col=0;
   int width=0;
   save_pos(auto p);
   if ( stype=='LINE' ) {
      width=longest_line_in_selection_raw();
      start_col=1;
      end_col=width;
   } else if ( stype=='BLOCK' ) {
      int dummy=0;
      _get_selinfo(start_col,end_col,dummy);
      width=end_col-start_col+1;
   } else {
      // stype=='CHAR'
      _select_type('','L','LINE');
      width=longest_line_in_selection_raw();
      start_col=1;end_col=width;
      stype='LINE';
   }
   int noflines=count_lines_in_selection();

   _begin_select();

   // Test for special case of a single line
   int single_line=0;
   save_pos(auto p2);   // So the scroll pos does not change
   if ( down() ) {
      single_line=1;
   } else {
      if ( down() ) {
         single_line=1;
      } else {
         single_line= (_end_select_compare()>0 || noflines==1)?(1):(0);
         up();
      }
   }
   restore_pos(p2);

   _str line='';
   _str before='';
   _str middle='';
   _str after='';
   _str regex='';
   _str paddedLeft='';
   int midlen=0;
   int count=0;
   boolean firstline_is_top=s.firstline_is_top;
   boolean lastline_is_bottom=s.lastline_is_bottom;

   // Find the widest left-hand border so we can pad accordingly
   int lside_widest = length(s.lvside);
   if (firstline_is_top) {
      lside_widest = max(lside_widest, length(s.tlc));
   } 
   if (lastline_is_bottom) {
      lside_widest = max(lside_widest, length(s.blc));
   }

   //  a one line comment - like /* int x; */
   if ( single_line && firstline_is_top && lastline_is_bottom ) {
      get_line_raw(line);

      paddedLeft = substr(s.tlc, 1, lside_widest);

      if (extractBoxedLine(line, paddedLeft, '', s.brc)){
         replace_line_raw(line);
         ++count;
      } else status = 1;
   } else {
      // start by looking at the first line
      if ( firstline_is_top ) {
         get_line_raw(line);

         paddedLeft = substr(s.tlc, 1, lside_widest);

         if (extractBoxedLine(line, paddedLeft, '', s.trc)){
            replace_line_raw(line);
            ++count;
         } else status = 1;

         if (down()) status = 1;
      } else {
         // check the top line when first line is not top
         get_line_raw(line);

         if (extractBoxedLine(line, s.tlc, s.thside, s.trc)){
            if (line == '') {
               _delete_line();
            }
         } else {
            replace_line_raw(line);
            if (down()) status = 1;
         }
      }
   } // end extracting first line

   // now we look at the interior lines
   if (!status && !(single_line && firstline_is_top)) {
      
      paddedLeft = substr(s.lvside, 1, lside_widest);

      regex = generateBoxRegex(paddedLeft, '', s.rvside);

      for ( ;; ) {
         // break if we're on or beyond the last line
         if ( _end_select_compare()>=0 ) break;
         get_line_raw(line);

         if (extractBoxedLine(line, paddedLeft, '', s.rvside, regex)) {
            replace_line_raw(line);
            ++count;
         } else {
            // in case this is the last line, we're being generous and
            // allowing them to select past the end of the block comment
            break; 
         }

         // something is wrong if we reach the end of the file
         if (down()) status = 1;
      }
   }

   // take care of last line
   if (!status) {
      if (lastline_is_bottom) {
         if ( !(single_line && firstline_is_top) ) {
            get_line_raw(line);
   
            paddedLeft = substr(s.blc, 1, lside_widest);
   
            if (extractBoxedLine(line, paddedLeft, '', s.brc)){
               replace_line_raw(line);
               ++count;
            } else status = 1;
         }
      } else {
         // this line should be only comment chars, so if it's there, we just delete it
         get_line_raw(line);
   
         regex = generateBoxRegex(s.blc, s.bhside, s.brc);
         if (!pos('{#0'regex'}', expand_tabs(line), 1, p_rawpos'er')) status = 1;
         _delete_line();
      }
   }

   // check for errors and print message
   if (status) {
      _message_box('Bad comment');
      _undo();
      return(1);
   }

   // Now re-select the text that was inside the box
   _begin_select();
   _deselect();
   if ( stype=='LINE' ) {
      _select_line();
      if ( count ) down(count-1);
      _select_line();
      _begin_select();
      p_col=1;
   } else {
      // stype=='BLOCK'
      _select_block();
      if (count) down(count - 1);
      /* +width for width of block selection
       * -length(tlc) for length of top-left-corner box chars
       * -length(trc) for length of top-right-corner box chars
       */
      p_col += width - _rawLength(s.tlc) - _rawLength(s.trc) - 1;
      _select_block();
      _begin_select();
   }
   return(0);
}

/**
 * This method generates a regular expression meant to match a
 * line within a box comment.  Uses box comment settings to
 * create pattern.
 * 
 * left side cannot be empty, otherwise there are four possible 
 * combinations: 
 * 1.  lsc, mc, rsc -> lsc + mid + rsc 
 * 2.  lsc, mc, empty rsc -> lsc + mc + ($) 
 * 3.  lsc, empty mc, rsc -> lsc + (?@) + rsc 
 * 4.  lsc, empty mc, empty rsc -> lsc + (?@|$)
 * 
 * @param lsc    left side comment characters
 * @param mc     middle comment (for top or bottom horizontal sides)
 * @param rsc    right side comment characters
 * 
 * @return the regular expression that will match the pattern
 */
_str generateBoxRegex(_str lsc, _str mc = '', _str rsc = '')
{
   _str regex = _escape_re_chars(lsc);
   if (mc != '') {
      if (rsc != '') {     // mc and rsc
         regex = regex :+ '('_escape_re_chars(mc)')@' :+ _escape_re_chars(rsc);
      } else {             // mc, no rsc
         regex = regex :+ '('_escape_re_chars(mc)')@' :+ '$';
      }
   } else {
      if (rsc != '') {     // no mc, rsc
         regex = regex :+ '(?@)' :+ _escape_re_chars(rsc);
      } else {             // no mc or rsc
         regex = regex :+ '(?@|$)';
      }
   }
   return regex;
}

/**
 * Extracts a line within a boxed comment using settings for box
 * comment characters.
 * 
 * For the case where there is no middle comment (mc) specified,
 * the whole line will be returned (before lsc + between lsc and
 * rsc + after rsc).  If a middle comment is specified, it is
 * assumed that this line is either the top or bottom and part
 * of a border, therefore only outside sections of the line will
 * be returned (before lsc + after rsc).
 * 
 * @param line   the current line to be extracted - the 
 *               extracted line will be returned in this
 *               variable
 * @param lsc    left side comment characters
 * @param mc     middle comment characters (used with top and
 *               bottom horizontal sides)
 * @param rsc    right side comment characters
 * @param regex  regular expression pattern to match - if this
 *               parameter is empty, it will be generated
 * 
 * @return whether the string could be extracted (whether the 
 *         pattern matched the line)
 */
boolean extractBoxedLine(_str &line, _str lsc, _str mc = '', _str rsc = '', _str regex = '')
{
   if (regex == '') {
      regex = generateBoxRegex(lsc, mc, rsc);
   }

   // now that we have our regex, search for it
   if ( !pos('{#0'regex'}', expand_tabs(line), 1, p_rawpos'er') ) {
      return false;
   }

   _str before, middle, after;
   int midlen;

   before = expand_tabs(line, 1, pos('S0') - 1, 'S');

   // figure out length of middle segment
   if (mc == '') {
      midlen = pos('0') - length(lsc);
      if (rsc != '') {
         midlen = midlen - length(rsc);
      }
      middle = expand_tabs(line, pos('S0') + length(lsc), midlen);
   } else {
      // since there is a middle comment string, we know that the
      // middle is made up of comment characaters, and therefore not
      // important to us
      middle = '';
   }

   after = expand_tabs(line, pos('S0') + pos('0'), -1, 'S');

   line = strip(before :+ middle :+ after, 'T');
   return true;
}

_command void comment_setup(_str options='') name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK|VSARG2_NOEXIT_SCROLL|
                                                       VSARG2_ICON|VSARG2_READ_ONLY)
{
   _macro_delete_line();
   setupext('-3 'options);
}

/**
 * Get the selection type of current selection if any.  If there
 * is no selection, set the selection type to LINE.
 * 
 * @return typeless selection type
 */
static void _box_get_select_type(typeless& stype, boolean& is_selection)
{
   stype = _select_type();
   is_selection = true;
   if (!select_active()) {
      stype = 'LINE';
      is_selection = false;
   }
}

static int _end_line_col(...)
{
   typeless p;
   save_pos(p);

   if (p_hex_mode==HM_HEX_ON){
      _hex_end_line();
   } else {
      // ripped from end_line_text_toggle
      // save the original column and jump to the end of the line
      orig_col := p_col;

      // find the last nonblank column
      _begin_line();
      search(':b$|$','@rh');
      nonblank_col := p_col;

      // find the actual end of the line
      _TruncEndLine();

      // check if we can use the last non-blank column
      if (nonblank_col > orig_col && nonblank_col < p_col) {
         p_col = nonblank_col;
      }
   }

   int col=p_col;
   restore_pos(p);
   return (col);
}

/**
 * HS2. Toggles comments of current line or selection. If there
 * is no active selection, it comments the current line. If at 
 * least 1 uncommented line is contained in the selection, it's 
 * commented blank lines are omitted when doing commenting 
 * check. 
 * 
 * @return void 
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Functions
 */
_command void toggle_comment( boolean godown = false, boolean deselect = true ) name_info (','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   typeless orig_pos;
   _save_pos2(orig_pos);

   bottomline := p_line;
   multi_line := select_active();
   if ( multi_line ) {
      end_select ();
      bottomline = p_line;
      begin_select ();

      // move cursor down to next line for single line commenting only
      godown = false;
   }

   int commenting = -1;
   loop {
      // skip blank lines for commenting test
      first_non_blank ();
      if ( p_col < _end_line_col() ) {
         commenting = ( _clex_find ( 0, 'G' ) != CFG_COMMENT ) ? 1 : 0;
      } else {
         if ( !multi_line )   break;   // bail out on blanklines in single line mode #1
         else                 commenting = 0;
      }

      if ( commenting || (++p_line > bottomline) || (p_line == p_Noflines) ) break;
   }
   _restore_pos2 (orig_pos);

   // bail out on blanklines in single line mode #2
   if ( commenting < 0 ) {
      // this is only reached for single lines hence we just down()
      down ();
      return;
   }

   _save_pos2 (orig_pos);

   if ( commenting ) comment ();
   else              comment_erase ();
   _restore_pos2 (orig_pos);

   if ( select_active () && deselect ) _deselect ();
   if ( godown )                       down ();
}

/**
 * Converts selected lines or block into line comments using the
 * comment setup.  If there is no active selection, it comments 
 * the current line. 
 * 
 * @return int 0 on success, 1 on failure.
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Functions
 */
_command int comment() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   BlockCommentSettings_t s;

   int status=0;
   _str param='';
   _str lang='';
   _str orig_lang='';
   typeless stype;
   boolean is_selection = true;
   int origLine = p_line;
   int origCol = p_col;
   _box_get_select_type(stype, is_selection);

   // When the leading indent is tabs, overwriting can
   // cause some problems for the user if they remove
   // the tabs manually.
   boolean comment_overwrites = !p_indent_with_tabs;

   // get comment settings from arguments
   if ( arg()>1 ) {
      s.comment_left=arg(1);
      s.comment_right=arg(2);
      s.comment_col=0;   // Hardcode this
      s.mode = def_comment_line_mode;
   } else {                                  // get comment settings from language settings
      if (stype != 'BLOCK') {
         // hop to beginning of line to avoid being in the middle of an
         // embedded language statement and using wrong comment settings
         // sg - 7.31.07
         first_non_blank();
      }

      parse arg(1) with param .;
      lang=param;
      orig_lang=lang;
      if ( lang=='' ) {
         typeless orig_values;
         status=_EmbeddedStart(orig_values);
         lang=p_LangId;
         if ( status==1 ) _EmbeddedEnd(orig_values);
         orig_lang=lang;
      }
      if ( lang!='' ) {
         BlockCommentSettings_t temp:[];
         if ( getCommentSettings(lang,temp) ) {
            _message_box('There are no comment line settings for 'orig_lang);
            return(1);
         }
         s=temp:[lang];
      } else {
         _message_box('There are no comment line settings for 'orig_lang);
         return(1);
      }
   }

   if ( s.comment_left=='' && s.comment_right=='' ) {
      // Then try to get color coding line comment delimeters for this language
      _str commentChars[];
      if (_getLineCommentChars(commentChars) != 0) {
         _message_box('There are no comment line settings for 'orig_lang);
         return(1);
      }
      s.comment_left  = commentChars[0];
      s.comment_right = '';
   }

   // check for SBCS/DBCS data
   if (p_xlat) {
      s.comment_left=_UTF8ToMultiByte(s.comment_left);
      s.comment_right=_UTF8ToMultiByte(s.comment_right);
   }
   int width=0;
   int start_col=0;
   int end_col=0;
   save_pos(auto p);
   if (!is_selection) {          // select the line if nothing is selected
      select_line();
      stype = 'LINE';
   }

   if ( stype=='LINE' ) {
      width=longest_line_in_selection_raw();//+1;
      start_col=1;
      end_col=width;
   } else if ( stype=='BLOCK' ) {
      if ( s.comment_col>0 ) {
         // Override block selections for languages with a
         // comment col (e.g. COBOL).
         _select_type('','L','LINE');
         width=longest_line_in_selection_raw();
         start_col=1;
         end_col=width;
         stype='LINE';
      } else {
         int dummy=0;
         _get_selinfo(start_col,end_col,dummy);
         width=end_col-start_col+1;
      }
   } else {
      // stype=='CHAR'
      _select_type('','L','LINE');
      width=longest_line_in_selection_raw();
      start_col=1;
      end_col=width;
      stype='LINE';
   }

   int leftmostcol=_leftmost_col_in_selection();
   int comment_col=0;
   if ( stype=='LINE' && s.comment_col ) {
      comment_col=s.comment_col;
   }

   _begin_select();
   int i=0;
   _str line='';
   _str before='';
   _str middle='';
   _str after='';
   _str new_line='';
   int leftDelimIPos = 1;
   int origLeftMostCol = leftmostcol;

   boolean firstLine = true;

   int shift = 0;
   int cmtLength = 0;
   // see if selection needs to be shifted
   if (stype == 'LINE') {
      cmtLength = length(s.comment_left);
      shift = cmtLength - leftmostcol + 1;
      // adjust total line width (for right side comment vertical alignment)
      if (s.mode == LEVEL_OF_INDENT) {
         width += cmtLength;
      } else if (shift > 0) {
         width += shift;
      } else if (width == 0) {  // if no shift, then the left_margin indented line will not change widths
         width += cmtLength;
      }
   }
   for ( ;; ) {
      get_line_raw(line);

      if ( stype=='LINE' ) {             // strip trailing blanks on line selections
         line=strip(line,'T');
      }

      if ( s.mode == START_AT_COLUMN ) {
         // Line selection was forced
         before = expand_tabs(line, 1, comment_col - 1, 'S');
         middle = expand_tabs(line, comment_col + cmtLength, -1, 'S');
         new_line = before :+ s.comment_left :+ middle :+ s.comment_right;
         leftDelimIPos = comment_col;
      } else if ( stype == 'LINE' ) {
         if (s.mode == LEFT_MARGIN) {                         // left margin setting
            int substrStart = 1;
            if (shift <= 0) {     
               if (comment_overwrites) {                      // no shifting - margins are wide enough
                  substrStart = cmtLength + 1;                // add 1 b/c we want the starting column
               }
            } else {                                          // shifting required
               int nonBlank = pos('[~ \t]', expand_tabs(line), 1, p_rawpos'r');  // first non-blank column
               if (nonBlank == leftmostcol) {                 // left-most line
                  substrStart = nonBlank;
               } else {
                  substrStart = cmtLength + 1;
                  if (p_indent_with_tabs) {
                     // Preserve tabs...
                     line = indent_string(shift) :+ line;
                  } else {
                     line = indent_string(shift) :+ expand_tabs(line);
                  }
               }
            }
            if (comment_overwrites)
               new_line = s.comment_left :+ expand_tabs(line, substrStart, -1, 'S');
            else {
               // don't fiddle with the tabs, but deal with difference between physical and 
               // imaginary positions.
               phys_start := text_col(line, substrStart, 'P');
               new_line = s.comment_left :+ substr(line, phys_start);
            }
         } else {                                             // current level of indent setting
            if (firstLine) {             // find current level of indent for first line
               if (leftmostcol == MAX_LINE) {
                  int nonBlank = pos('[~ \t]', expand_tabs(line), 1, p_rawpos'r');
                  if (nonBlank) {
                     leftmostcol = nonBlank;
                  } else {
                     if (leftmostcol == MAX_LINE) {
                        leftmostcol = 1;
                     }
                  }
               }
               firstLine = false;
            }
            new_line = expand_tabs(line, 1, leftmostcol - 1, 'S') :+ s.comment_left :+ expand_tabs(line, leftmostcol, -1, 'S');
            leftDelimIPos = leftmostcol;
         }
         // if there is an ending line comment, make them all line up vertically in the selection
         if (s.comment_right != "") {
            new_line = pad_end_with_tabs(new_line, width) :+ s.comment_right;
         }
      } else {                // block comment
         before=expand_tabs(line,1,start_col-1,'S');
         middle=expand_tabs(line,start_col,width);
         after=expand_tabs(line,end_col+1,-1,'S');
         new_line=before:+s.comment_left:+middle:+s.comment_right:+after;
         new_line=strip(new_line,'T');
         leftDelimIPos = start_col;
      }
      replace_line_raw(new_line);
      ++i;
      status=down();
      if ( status ) break;
      if ( _end_select_compare()>0 ) break;
   }
   if ( !status ) {
      up();
   }

   _begin_select();_deselect();
   if ( stype=='LINE' ) {
      _select_line();
      if ( i ) down(i-1);
      _select_line();
      _begin_select();p_col=1;
   } else {
      _select_block();
      if ( i ) down(i-1);
      /* +width for width of block selection
       * +length(comment_left) for length of left-side comment chars
       * +length(comment_right) for length of right-side comment chars
       * //+2 for the space on either side of boxed line
       * //The above +2 no longer needed, should be factored in
       * //as part of the lenghts of the left and right comment
       * //chars. Width also needs to be -1.
       */
      p_col+=width+length(s.comment_left)+length(s.comment_right) - 1 /*+2*/;
      _select_block();
      _begin_select();
   }

   if (!is_selection) {
      deselect();
   }
   p_line = origLine;
   if (origCol >= leftDelimIPos) {
      if (s.mode == LEFT_MARGIN) {
         int shift2 = (s.comment_left._length() - origLeftMostCol + 1);
         if (shift2 < 0) shift = 0;
         p_col = origCol + shift;
      } else {
         p_col = origCol + s.comment_left._length();
      }
   }
   else p_col = origCol;
   return(0);
}

/**
 * Uncomments currently selected lines or block using the
 * comment setup.  If there is no active selection, it
 * uncomments the current line.
 * 
 * @return int 0 on success, 1 on failure.
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Functions
 */
_command int comment_erase() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   BlockCommentSettings_t s;

   _str param='';
   _str lang='';
   _str orig_lang='';
   int status=0;

   typeless stype;
   boolean is_selection = true;
   _box_get_select_type(stype, is_selection);

   if ( arg()>1 ) {
      s.comment_left=arg(1);
      s.comment_right=arg(2);
   } else {
      parse arg(1) with param .;
      lang=param;
      orig_lang=lang;
      if ( lang=='' ) {
         typeless orig_values;
         status=_EmbeddedStart(orig_values);
         lang=p_LangId;
         if ( status==1 ) _EmbeddedEnd(orig_values);
         orig_lang=lang;
      }
      if ( lang!='' ) {
         BlockCommentSettings_t temp:[];

         if ( getCommentSettings(lang,temp) ) {
            _message_box('There is currently no comment setup information for 'orig_lang);
            return(1);
         }
         s=temp:[lang];
      } else {
         _message_box('There is currently no comment setup information for 'orig_lang);
         return(1);
      }
   }
   if ( s.comment_left=='' && s.comment_right=='' ) {
      // Then try to get color coding line comment delimeters for this language
      _str commentChars[];
      if (_getLineCommentChars(commentChars) != 0) {
         _message_box('There are no comment line settings for 'orig_lang);
         return(1);
      }
      s.comment_left  = commentChars[0];
      s.comment_right = '';
   }
   if (p_xlat) {
      s.comment_left=_UTF8ToMultiByte(s.comment_left);
      s.comment_right=_UTF8ToMultiByte(s.comment_right);
   }

   _undo('S');   // So we can quickly undo if a problem
   int width=0;
   int start_col=0;
   int end_col=0;
   save_pos(auto p);
   if (!is_selection) {
      select_line();
   }

   if ( stype=='LINE' ) {
      width=longest_line_in_selection_raw();
      start_col=1;
      end_col=width;
   } else if ( stype=='BLOCK' ) {
      int dummy=0;
      _get_selinfo(start_col,end_col,dummy);
      width=end_col - start_col + 1;
   } else {
      // stype=='CHAR'
      _select_type('','L','LINE');
      width=longest_line_in_selection_raw();
      start_col=1;end_col=width;
      stype='LINE';
   }

   _begin_select();

   _str line='';
   _str before='';
   _str middle='';
   _str after='';
   _str indent='';
   _str cmtLeft = '';
   _str cmtRight = '';
   int midlen = 0;
   int size_left_comment = 0;
   int leftmostcol = 0;
   int nonblank_col=0;
   int lcPos = 0;
   int rcPos = 0;
   int i=0;
   status=0;
   boolean first_line_erase = true;    // keep track of first line we erase
   boolean first_line_indent = true;   // keep track of first line we reindent (in case of blank lines)
   boolean add_back_spaces = false;    // whether to add back spaces to replace comment chars
   int adj = 0;
   for ( ;; ) {
      get_line_raw(line);

      // find comment characters in lines
      _str ss =_escape_re_chars(s.comment_left):+'(?@|$)';
      if ( s.comment_right!="" ) {
         ss=ss:+_escape_re_chars(s.comment_right);
      }
      // line commenting with either LEFT_MARGIN OR LEVEL_INDENT modes
      if ( s.comment_col == 0 && stype == 'LINE' ) {
         
         // special case for first line - must determine which commenting style we are using.
         if (first_line_erase) {
            // make sure we're in a comment
            first_non_blank();
            if (!_in_comment()) {
               status = 1;
               break;
            }

            cmtLeft = s.comment_left;
            cmtRight = s.comment_right;
            lcPos = IsCommentWellFormed(line, cmtLeft, cmtRight);

            if (!lcPos) {
               status = 1;
               break;
            }
            size_left_comment = length(cmtLeft);
               
            // decide if we need to add back spaces that were deleted in
            // uncommenting
            if (s.mode == LEFT_MARGIN
                && !p_indent_with_tabs) {                                                 // We don't delete leading spaces in tab mode.
               // find the leftmost non-comment and subtract, this will be the
               // leftmost column after we erase the comments
               leftmostcol=_leftmost_col_in_selection_after_start(lcPos + size_left_comment);
               leftmostcol -= size_left_comment;
               if (leftmostcol > 1 || !(size_left_comment % p_SyntaxIndent)) {
                  add_back_spaces = true;
               }
            }
            
            first_line_erase = false;
         } else {
            // make sure this is a well-formed comment - has comment characters in same column on every line
            // this case should be caught in IsCommentWellFormed -
            if (!strieq(cmtLeft, expand_tabs(line, lcPos, size_left_comment, 'S'))) {
               // allow blank lines
               nonblank_col = pos('[~ \t]', expand_tabs(line), 1, p_rawpos'er');
               if (nonblank_col) {
                  status = 1;
                  break;
               }
            }
         }

         before = imaginary_substr(line, 1, lcPos - 1, 'W');

         // add the spaces back if they were deleted
         if (add_back_spaces || s.comment_col > 0) {

            // take a substring up to and including the left comment
            _str begin = imaginary_substr(line, 1, lcPos + size_left_comment - 1, 'W');
            _str last = imaginary_substr(line, lcPos + size_left_comment, -1);

            // we can carelessly just toss spaces in because we're going to fix indent later
            line = begin :+ imaginary_substr('', 1, size_left_comment, 'W') :+ last;
         }

         // check for right comment
         rcPos = 0;
         if (cmtRight != "") {
            ss = _escape_re_chars(cmtRight);
            rcPos = lastpos('{#0'ss'}', expand_tabs(line), '', p_rawpos'er');
         }
         
         // there is a right comment, but not for long!
         if (rcPos) {
            midlen = rcPos - (lcPos + size_left_comment);
            middle = imaginary_substr(line, lcPos + size_left_comment, midlen, 'B');
            after = imaginary_substr(line, rcPos + length(cmtRight));
         } else {
            // no right comment, just take rest of line
            middle = imaginary_substr(line, lcPos + size_left_comment);
            after = "";
         }

         line = before :+ middle :+ after;
         line = strip(line, 'T');
         replace_line_raw(line);

         // if this is the first non-blank line in the selection, reindent it and save the adjustment
         if (first_line_indent) {

            // check for a blank line - we don't want to reindent based on a blank line
            nonblank_col = pos('[~ \t]', expand_tabs(line), 1, p_rawpos'er'); 
            if (nonblank_col) {

               // if the first character is another comment, do not reindent
               first_non_blank();
               // what is the current level of indent for this line?
               int ind = find_new_column();
               if (ind > 0) {
                  adj = ind - nonblank_col;
               }  // else 
                  // if there is no callback for indent_col, we assume the comments were made in 
                  // SlickEdit and adjust according to the indent level
                  // note that this method does not account for shifting.
                  // no adjustment for level of indent mode
                  // adjustment for left margin is handled by adding back spaces previously
               first_line_indent = false;      
            }
         }
        
         // adjust all lines as according to first line
         // If tab indent is active, then no spaces were added or 
         // removed, so don't bother with the reindent.
         if (!p_indent_with_tabs) {
            line = ReindentLine(line, adj);
         }
         replace_line_raw(line);

      } else {             // we have a comment col or a block comment in this case
         lcPos = pos('{#0'ss'}', expand_tabs(line), 1, p_rawpos'er'); 
         if (!lcPos) {
            status = 1;
            break;
         }

         size_left_comment = length(s.comment_left);
         before = expand_tabs(line, 1, pos('S0') - 1, 'S');

         // add back the space for the comment character
         if (s.comment_col > 0 && lcPos > 0) {
            before :+= indent_string(size_left_comment);
         }

         // check for right comment
         if (s.comment_right != "") {
            ss = _escape_re_chars(s.comment_right);
            rcPos = lastpos('{#0'ss'}', expand_tabs(line), '', p_rawpos'er');
         }
         
         // there is a right comment, but not for long!
         if (rcPos) {
            midlen = rcPos - (lcPos + size_left_comment);
            middle = imaginary_substr(line, lcPos + size_left_comment, midlen, 'B');
            after = imaginary_substr(line, rcPos + length(s.comment_right));
         } else {
            // no right comment, just take rest of line
            middle = imaginary_substr(line, lcPos + size_left_comment);
            after = "";
         }

         line = before :+ middle :+ after;
         line = strip(line, 'T');

         // preserve tabs
         nonblank_col = pos('[~ \t]', line, 1, p_rawpos'er');
         if (nonblank_col > 1 && s.comment_col <= 0) {
            line = substr(line, nonblank_col);
            // add back size_left_comment so that we don't move the code any
            // (only if not in BLOCK mode, since BLOCK inserts, not
            // overwrites)
            if (stype == 'BLOCK') {
               indent = indent_string(nonblank_col - 1);
            } else {
               indent = indent_string(nonblank_col - 1 + size_left_comment);
            }
            line = indent :+ line;
         }

         replace_line_raw(line);
      }

      ++i;
      if ( _end_select_compare()>=0 ) break;
      status=down();
      if ( status ) break;
   }
   if ( status ) {
      _message_box('Cannot remove comment characters.  Unrecognized or inconsistent commenting approach has been found.');
      _undo();
      if (!is_selection) {
         deselect();
      }
      return(1);
   }

   _begin_select();_deselect();
   if ( stype=='LINE' ) {
      _select_line();
      if ( i ) down(i-1);
      _select_line();
      _begin_select();
      p_col=1;
   } else {
      // stype=='BLOCK'
      _select_block();
      if ( i ) down(i-1);
      /* +width for width of block selection
       * -length(comment_left) for length of left-side comment chars
       * -length(comment_right) for length of right-side comment chars
       * -2 for the space on either side of boxed line
       */
      p_col+=width-length(s.comment_left)-length(s.comment_right)-2-1;_select_block();
      _begin_select();
   }

   if (!is_selection) {
      deselect();
   }
   return(0);
}


/**
 * Finds the indent level for the current line.
 * 
 * @return the indent level.
 */
static int find_new_column()
{
   int result_col = 0;

   // get the current line, so we save it (we don't want to change the 
   // line at this point)
   get_line_raw(auto line);

   oldIndentStyle := p_indent_style;
   p_indent_style = INDENT_SMART;

   // do we have smart tab info?
   NoSmartTab := _IsSmartTabEnabled(VSSMARTTAB_ALWAYS_REINDENT);

   // yup!  use it to reindent line and find new p_col
   if( NoSmartTab ) {
      save_pos(auto p);
      first_non_blank();
      result_col=p_col;
      restore_pos(p);
   }

   // put the original line back
   replace_line_raw(line);

   p_indent_style = oldIndentStyle;

   return( result_col );
}

/**
 * This method takes a substring of a string using the imaginary 
 * position (obtained from using pos with expand_tabs). 
 * Translates the position or width parameters into their 
 * physical position equivalents according to the string and tab 
 * settings. 
 *  
 * @param string  string to be drawn from
 * @param start   starting index
 * @param width   length of substring
 * @param options specify 'S' to translate the starting index, 'W' for the width, and 'B' for both
 * @param pad     pad character to be put at end of string if it is less than width
 * 
 * @return the new substring
 */
_str imaginary_substr(_str string, int start = 1, int width = -1, _str options = 'S', _str pad = ' ')
{
   options = upcase(options);
   int oldStart = start;
   if (options == 'S' || options == 'B') {
      start = text_col(string, start, 'P');
   }
   if (options == 'W' || options == 'B') {
      if (width != -1) {
         width = text_col(string, oldStart + width, 'P') - start;
      }
   }
   return substr(string, start, width, pad);
}

/** 
 * Pad end of a line to length width by adding tabs or spaces 
 * according to user settings. 
 * 
 * @param line   string to be padded
 * @param width  desired length of string
 * 
 * @return padded string
 */
_str pad_end_with_tabs(_str line, int width)
{
   if ( ! p_indent_with_tabs ) {
      return(substr(line, 1, width));
   }
   return(expand_tabs(substr(line, 1, width, \t), 1, width, 'S'));
}

/**
 * Inserts or removes spaces from the beginning of the given 
 * line according to the adjustment. 
 *  
 * @param line   the line to be reindented
 * @param adj    amount to adjust current line.  a positive
 *               adjustment means add spaces to the beginning,
 *               while a negative adjustment means deleting
 *               spaces.
 * 
 * @return the adjusted line
 */
_str ReindentLine(_str line, int adj)
{
   _str before = '';
   _str after = '';

   int nonblank_col = pos('[~ \t]', expand_tabs(line), 1, p_rawpos'er');
   // if this is a blank line, we do nothing
   if (nonblank_col) {
      // make sure we aren't trying to run off beginning of line by checking abs(adj)
      if (adj >= 0 || nonblank_col > abs(adj)) {

         before = indent_string(nonblank_col + adj - 1);
         after = expand_tabs(line, nonblank_col, -1, 'S');

         line = before :+ after;
      } 
   }

   return line;
}


/**
 * Used to keep track of commenting info when trying to nail 
 * down which comment style was used. 
 */
struct LineCommentInfo {
   _str cmtLeft;
   _str cmtRight;
   _str regEx;
   int lcPos;
};

/**
 * This method checks for all valid commenting styles as
 * specified by current lexer.  Will select the most outer 
 * commenting style in case of multiples. 
 * 
 * @param line     line to be searched for comments
 * @param cmtLeft  left size comment
 * @param cmtRight right side comment
 * 
 * @return position of left comment string, 0 if nothing found
 */
int IsCommentWellFormed(_str line, _str &cmtLeft, _str &cmtRight)
{
   _str comments[] = null;
   LineCommentInfo commentsFound[] = null;
   LineCommentInfo nfo = null;
   _str ss = '';
   _str defRegex = '';
   _str nextLine = '';
   int lcPos = 0;
   int i;

   // add default settings to search array
   ss = cmtLeft;
   defRegex = _escape_re_chars(cmtLeft) :+ '(?@|$)';
   if (cmtRight != "") {
      ss = ss :+ 'delim' cmtRight;
      defRegex = defRegex :+ _escape_re_chars(cmtRight);
   }

   // retrieve all single-line and multi-line comments for this language
   GetAllComments(comments, ss);

   for (i = 0; i < comments._length(); ++i) {
      _str tempCmtLeft = '';
      _str tempCmtRight = '';

      // split beginning and ending comment delimiters
      parse comments[i] with tempCmtLeft 'delim' tempCmtRight;

      // create regex for searching
      ss = _escape_re_chars(tempCmtLeft) :+ '(?@|$)';
      if (tempCmtRight != "") {
         ss = ss :+ _escape_re_chars(tempCmtRight);
      }

      // look for it!
      int tempPos = pos('{#0'ss'}', expand_tabs(line), 1, p_rawpos'er');
      if (tempPos) {
         nfo = null;

         nfo.cmtLeft = tempCmtLeft;
         nfo.cmtRight = tempCmtRight;
         nfo.lcPos = tempPos;
         nfo.regEx = ss;
         commentsFound[commentsFound._length()] = nfo;
      }
   }

   // now check and see if we found multiples - if so, check all lines in 
   // selection to see which ones persist all the way down
   if (commentsFound._length() > 1) {
      nfo = PickBestStyleFromMultiple(commentsFound, defRegex);
   }

   // we have a winner
   if (nfo != null) {
      lcPos = nfo.lcPos;
      cmtLeft = nfo.cmtLeft;
      cmtRight = nfo.cmtRight;
   }

   return lcPos;
}


/**
 * Picks the "best" commenting style from an array of styles.
 * Checks the entire selection to see which ones persist
 * throughout, then selects the default one.  If the default
 * does not persist throughout the selection, picks the
 * outermost.
 * 
 * @param commentsFound
 *                 array of commenting styles to check
 * @param defRegex regular expression of default settings
 * 
 * @return the selected comment info struct that holds the comment style deemed best.
 */
LineCommentInfo PickBestStyleFromMultiple(LineCommentInfo (&commentsFound)[], _str defRegex)
{
   LineCommentInfo nfo = null;
   _str nextLine = '';

   // check to see if this is a one liner - no need to go through selection loop if so
   boolean oneLine = (count_lines_in_selection() == 1);

   int i = 0;
   if (!oneLine) {
      save_pos(auto p);
      while (commentsFound._length() > 0 && !down()) {
         if (_end_select_compare() > 0) {
            break;
         }
   
         // see if this line has the same commenting style at the same positions - if not, remove the style
         get_line_raw(nextLine);
         for (i = 0; i < commentsFound._length(); ++i) {
            if (pos('{#0'commentsFound[i].regEx'}', expand_tabs(nextLine), commentsFound[i].lcPos, p_rawpos'er') 
                != commentsFound[i].lcPos) {
               commentsFound._deleteel(i);
               --i;
            }
         }
      }
      restore_pos(p);
   }

   // didn't find any
   if (commentsFound._length() == 0) return null;

   // still found multiples!  use one set in options first, then one with most exterior position
   if (commentsFound._length() > 1) {
      int lcPos = MAX_LINE;
      for (i = 0; i < commentsFound._length(); ++i) {
         // check and see if this is the one set in the comment settings
         if (commentsFound[i].regEx == defRegex) {
            nfo.lcPos = lcPos = commentsFound[i].lcPos;
            nfo.cmtRight = commentsFound[i].cmtRight;
            nfo.cmtLeft = commentsFound[i].cmtLeft;

            // this is our automatic winner
            break;
         }
         if (commentsFound[i].lcPos < lcPos) {
            nfo.lcPos = lcPos = commentsFound[i].lcPos;
            nfo.cmtRight = commentsFound[i].cmtRight;
            nfo.cmtLeft = commentsFound[i].cmtLeft;
         }
      }
   } else {     // found one, so it must be it.
      nfo.lcPos = commentsFound[0].lcPos;
      nfo.cmtRight = commentsFound[0].cmtRight;
      nfo.cmtLeft = commentsFound[0].cmtLeft;
   }

   return nfo;
}

/**
 * Retrieves an array of commenting styles.  Modified from 
 * GetAllComments in diffmf.e. 
 *  
 * @param Comments  array in which to place commenting styles, one per element.  Multi-lined
 *                  comments are space delimited (left_comment' 'right_comment).
 * @param FieldName Specify type of comment:  "linecomment" or "mlcomment"
 */
void GetComments(_str (&Comments)[], _str FieldName, _str lexerName)
{
   _str SystemFile='';
   _str UserFile='';
   parse LEXER_FILE_LIST with SystemFile (PATHSEP) UserFile;

   _ini_get_all_values(UserFile, lexerName, FieldName, Comments);

   if (Comments._length()) {
      return;
   }

   Comments = null;
   _ini_get_all_values(SystemFile, lexerName, FieldName, Comments);
}


/**
 * Gets a combined array of all commenting styles, including 
 * single line and multi-line.  Includes the default style 
 * specified in comment settings.  Removes duplicates. 
 * 
 * @param comments array to place commenting styles in
 * @param defaultStyle
 *                 the default style (set in comment settings)
 */
void GetAllComments(_str (&comments)[], _str defaultStyle = '', _str lexerName = '')
{
   int i;
   _str allComments[] = null;
   comments = null;

   if (defaultStyle != '') comments[0] = defaultStyle;

   if (lexerName == '') lexerName = p_lexer_name;

   // first check for line comments
   GetComments(allComments, "linecomment", lexerName);

   // add to total array, provided that nothing matches default style
   for (i = 0; i < allComments._length(); ++i) {
      if (allComments[i] != defaultStyle) {
         comments[comments._length()] = stranslate(allComments[i], 'delim', ' ');
      }
   }

   // now check for multi-line comments
   GetComments(allComments, "mlcomment", lexerName);

   // combine arrays, no duplicates
   for (i = 0; i < allComments._length(); ++i) {
      if (allComments[i] != defaultStyle) {
         comments[comments._length()] = stranslate(allComments[i], 'delim', ' ');
      }
   }
}

/*
 * \s=space
 * \e=empty
 */
static _str _xlat_ini2chars(_str str)
{
   _str new_str=str;
   if (new_str :== '\e') {
      new_str = '';
   }
   new_str=stranslate(new_str,' ','\s');

   return(new_str);
}

static _str _xlat_chars2ini(_str str)
{
   _str new_str=str;
   new_str=stranslate(new_str,'\s',' ');
   if ( new_str=='' ) {
      new_str='\e';
   } else {
      new_str=stranslate(new_str,'\s',' ');
   }

   return(new_str);
}

static void _box_parse_settings(_str line,
                                _str &tlc,_str &trc,
                                _str &blc,_str &brc,
                                _str &bhside,_str &thside,
                                _str &lvside,_str &rvside)
{
   tlc=eq_name2value('tlc',line,true);
   trc=eq_name2value('trc',line,true);
   blc=eq_name2value('blc',line,true);
   brc=eq_name2value('brc',line,true);
   bhside=eq_name2value('bhside',line,true);
   thside=eq_name2value('thside',line,true);
   lvside=eq_name2value('lvside',line,true);
   rvside=eq_name2value('rvside',line,true);

   return;
}

static void _comment_parse_settings(_str line,
                                    _str &comment_left,_str &comment_right)
{
   comment_left=eq_name2value('left',line,true);
   comment_right=eq_name2value('right',line,true);

   return;
}

int getCommentSettings(_str lang,BlockCommentSettings_t (&p):[],_str getOption='')
{
   _str user_ini_filename='';
   _str system_ini_filename='';
   _str line='';
   _str tlc='';
   _str trc='';
   _str blc='';
   _str brc='';
   _str bhside='';
   _str thside='';
   _str lvside='';
   _str rvside='';
   _str comment_left='';
   _str comment_right='';
   int boxchars_status=0;
   int nonboxchars_status=0;
   int comment_col_status=0;
   COMMENT_LINE_MODE mode = def_comment_line_mode;
   typeless status=1;
   if ( lang!='' ) {
      user_ini_filename=usercfg_path_search(VSCFGFILE_USER_BOX);
      // Check the user settings first
      int temp_wid=0,orig_wid=0;
      int status2=_open_temp_view(user_ini_filename,temp_wid,orig_wid);
      if (!status2) activate_window(orig_wid);
      if (status2) {
         temp_wid=0;
      }
      boxchars_status=_ini_get_value(user_ini_filename,lang,'boxchars',line);
      if ( !boxchars_status ) {
         _box_parse_settings(line,tlc,trc,blc,brc,bhside,thside,lvside,rvside);
         p:[lang].tlc=_xlat_ini2chars(tlc);
         p:[lang].trc=_xlat_ini2chars(trc);
         p:[lang].blc=_xlat_ini2chars(blc);
         p:[lang].brc=_xlat_ini2chars(brc);
         p:[lang].bhside=_xlat_ini2chars(bhside);
         p:[lang].thside=_xlat_ini2chars(thside);
         p:[lang].lvside=_xlat_ini2chars(lvside);
         p:[lang].rvside=_xlat_ini2chars(rvside);
         status=_ini_get_value(user_ini_filename,lang,'firstline_is_top',line);
         if ( !status ) {
            p:[lang].firstline_is_top=(line!=0);
         } else {
            p:[lang].firstline_is_top=false;
         }
         status=_ini_get_value(user_ini_filename,lang,'lastline_is_bottom',line);
         if ( !status ) {
            p:[lang].lastline_is_bottom=(line!=0);
         } else {
            p:[lang].lastline_is_bottom=false;
         }
      } else {
         p:[lang].tlc='';
         p:[lang].trc='';
         p:[lang].blc='';
         p:[lang].brc='';
         p:[lang].bhside='';
         p:[lang].thside='';
         p:[lang].lvside='';
         p:[lang].rvside='';
         p:[lang].firstline_is_top=false;
         p:[lang].lastline_is_bottom=false;
      }
      nonboxchars_status=_ini_get_value(user_ini_filename,lang,'nonboxchars',line);
      if ( !nonboxchars_status ) {
         _comment_parse_settings(line,comment_left,comment_right);
         p:[lang].comment_left=_xlat_ini2chars(comment_left);
         p:[lang].comment_right=_xlat_ini2chars(comment_right);
      } else {
         p:[lang].comment_left='';
         p:[lang].comment_right='';
      }
      comment_col_status=_ini_get_value(user_ini_filename,lang,'comment_col',line);
      if ( !comment_col_status ) {
         p:[lang].comment_col=(int)line;
      } else {
         p:[lang].comment_col=0;
      }
      status=_ini_get_value(user_ini_filename,lang,'line_comment_mode',line);
      if ( !status ) {
         p:[lang].mode = (COMMENT_LINE_MODE)line;
      } else {
         p:[lang].mode=def_comment_line_mode;
      }
      //say('getOption='getOption);
      //say('boxchars_status='boxchars_status);
      //say('nonboxchars_status='nonboxchars_status);
      getOption=upcase(getOption);
      if ((getOption=='B' || getOption=='L') && (!boxchars_status || !nonboxchars_status)) {
         if (getOption=='B' && !boxchars_status) {
            if (temp_wid) _delete_temp_view(temp_wid);
            return(0);
         }
         if (getOption=='L' && !nonboxchars_status) {
            if (temp_wid) _delete_temp_view(temp_wid);
            return(0);
         }
         if (temp_wid) _delete_temp_view(temp_wid);
         return(1);
      }
      if (!boxchars_status || !nonboxchars_status) {
         if (temp_wid) _delete_temp_view(temp_wid);
         return(0);
      }
      if (temp_wid) _delete_temp_view(temp_wid);

      system_ini_filename=get_env('VSROOT'):+BOX_INI_FILENAME;
      status2=_open_temp_view(system_ini_filename,temp_wid,orig_wid);
      if (!status2) activate_window(orig_wid);
      if (status2) {
         activate_window(orig_wid);
         temp_wid=0;
      }
      // Now check the global settings
      status=_ini_get_value(system_ini_filename,lang,'boxchars',line);
      if ( !status ) {
         _box_parse_settings(line,tlc,trc,blc,brc,bhside,thside,lvside,rvside);
         p:[lang].tlc=_xlat_ini2chars(tlc);
         p:[lang].trc=_xlat_ini2chars(trc);
         p:[lang].blc=_xlat_ini2chars(blc);
         p:[lang].brc=_xlat_ini2chars(brc);
         p:[lang].bhside=_xlat_ini2chars(bhside);
         p:[lang].thside=_xlat_ini2chars(thside);
         p:[lang].lvside=_xlat_ini2chars(lvside);
         p:[lang].rvside=_xlat_ini2chars(rvside);
         status=_ini_get_value(system_ini_filename,lang,'nonboxchars',line);
         if ( !status ) {
            _comment_parse_settings(line,comment_left,comment_right);
            p:[lang].comment_left=_xlat_ini2chars(comment_left);
            p:[lang].comment_right=_xlat_ini2chars(comment_right);
         } else {
            p:[lang].comment_left='';
            p:[lang].comment_right='';
         }
         status=_ini_get_value(system_ini_filename,lang,'comment_col',line);
         if ( !status ) {
            p:[lang].comment_col=(int)line;
         } else {
            p:[lang].comment_col=0;
         }
         status=_ini_get_value(system_ini_filename,lang,'line_comment_mode',line);
         if ( !status ) {
            p:[lang].mode=(COMMENT_LINE_MODE)line;
         } else {
            p:[lang].mode=def_comment_line_mode;
         }
         status=_ini_get_value(system_ini_filename,lang,'firstline_is_top',line);
         if ( !status ) {
            p:[lang].firstline_is_top=(line!=0);
         } else {
            p:[lang].firstline_is_top=false;
         }
         status=_ini_get_value(system_ini_filename,lang,'lastline_is_bottom',line);
         if ( !status ) {
            p:[lang].lastline_is_bottom=(line!=0);
         } else {
            p:[lang].lastline_is_bottom=false;
         }
         status=0;
      }
      if (status) {
         if (getOption=='') {
            // Might have some value
            if (temp_wid) _delete_temp_view(temp_wid);
            return(0);
         }
         p._deleteel(lang);
      }
      if (temp_wid) _delete_temp_view(temp_wid);
   }

   return(status);
}

int saveCommentSettingsForLang(_str lang)
{
   if (_settings._indexin(lang)) {
      BlockCommentSettings_t p = _settings:[lang];
      return saveCommentSettings(lang, p);
   }

   return 0;
}

int saveCommentSettings(_str lang, BlockCommentSettings_t &p)
{
   origWid := p_window_id;

   temp_wid := 0;
   _create_temp_view(temp_wid);

   // add stuff to the buffer based on the comment settings
   _str line='';

   if (p.tlc!='' || p.trc!='' || p.blc!='' || p.brc!='' ||
       p.bhside!='' || p.thside!='' || p.lvside!='' || p.rvside!='') {
      line='tlc='_xlat_chars2ini(p.tlc):+
           ' trc='_xlat_chars2ini(p.trc):+
           ' blc='_xlat_chars2ini(p.blc):+
           ' brc='_xlat_chars2ini(p.brc):+
           ' bhside='_xlat_chars2ini(p.bhside):+
           ' thside='_xlat_chars2ini(p.thside):+
           ' lvside='_xlat_chars2ini(p.lvside):+
           ' rvside='_xlat_chars2ini(p.rvside);

      insert_line('boxchars='line);
      insert_line('firstline_is_top='(p.firstline_is_top ? 1 : 0));
      insert_line('lastline_is_bottom='(p.lastline_is_bottom ? 1 : 0));
   } 

   // line comments
   if (p.comment_left!='' || p.comment_right!='') {
      line='left='_xlat_chars2ini(p.comment_left):+
           ' right='_xlat_chars2ini(p.comment_right);
      insert_line('nonboxchars='line);
   } 

   if (p.comment_col && p.mode == START_AT_COLUMN) {
      insert_line('comment_col='p.comment_col);
   } 

   insert_line('line_comment_mode='(int)p.mode);

   user_ini_filename := usercfg_init_write(VSCFGFILE_USER_BOX);
   status := _ini_put_section(user_ini_filename, lang, temp_wid);

   p_window_id = origWid;

   if (!status) {
      _orig_settings:[lang] = _settings:[lang] = p;
   }

   return status;
}

enum CommentSettings {
   CS_TLC,
   CS_TRC,
   CS_BLC,
   CS_BRC,
   CS_BOTTOM_SIDE,
   CS_TOP_SIDE,
   CS_LEFT_SIDE,
   CS_RIGHT_SIDE,
   CS_LINE_LEFT,
   CS_LINE_RIGHT,
   CS_FIRST_LINE_IS_TOP,
   CS_LAST_LINE_IS_BOTTOM,
   CS_LINE_COMMENT_MODE,
   CS_LINE_COMMENT_COL,
};

/**
 * Gets/sets a comment block setting.
 * 
 * @param langID              language this setting applies to
 * @param option              one of the CommentSettings enum, the particular 
 *                            setting desired
 * @param value               value to set, null to just return the current 
 *                            value
 * 
 * @return                    current value
 */
typeless _lang_block_comment_setting(_str langID, int option, typeless value)
{
   BlockCommentSettings_t p;
   if (_settings:[langID]._isempty()) {
      if (!getCommentSettings(langID,_settings)) {
         p=_settings:[langID];
//       _orig_settings:[langID]=p;
      }
   } 
   
   if (value == null) {
      switch (option) {
      case CS_TLC:
         value = _settings:[langID].tlc;
         break;
      case CS_TRC:
         value = _settings:[langID].trc;
         break;
      case CS_BLC:
         value = _settings:[langID].blc;
         break;
      case CS_BRC:
         value = _settings:[langID].brc;
         break;
      case CS_BOTTOM_SIDE:
         value = _settings:[langID].bhside;
         break;
      case CS_TOP_SIDE:
         value = _settings:[langID].thside;
         break;
      case CS_LEFT_SIDE:
         value = _settings:[langID].lvside;
         break;
      case CS_RIGHT_SIDE:
         value = _settings:[langID].rvside;
         break;
      case CS_LINE_LEFT:
         value = _settings:[langID].comment_left;
         break;
      case CS_LINE_RIGHT:
         value = _settings:[langID].comment_right;
         break;
      case CS_FIRST_LINE_IS_TOP:
         value = _settings:[langID].firstline_is_top;
         break;
      case CS_LAST_LINE_IS_BOTTOM:
         value = _settings:[langID].lastline_is_bottom;
         break;
      case CS_LINE_COMMENT_MODE:
         value = _settings:[langID].mode;
         break;
      case CS_LINE_COMMENT_COL:
         value = _settings:[langID].comment_col;
         break;
      }
   } else {
      switch (option) {
      case CS_TLC:
         _settings:[langID].tlc = value;
         break;
      case CS_TRC:
         _settings:[langID].trc = value;
         break;
      case CS_BLC:
         _settings:[langID].blc = value;
         break;
      case CS_BRC:
         _settings:[langID].brc = value;
         break;
      case CS_BOTTOM_SIDE:
         _settings:[langID].bhside = value;
         break;
      case CS_TOP_SIDE:
         _settings:[langID].thside = value;
         break;
      case CS_LEFT_SIDE:
         _settings:[langID].lvside = value;
         break;
      case CS_RIGHT_SIDE:
         _settings:[langID].rvside = value;
         break;
      case CS_LINE_LEFT:
         _settings:[langID].comment_left = value;
         break;
      case CS_LINE_RIGHT:
         _settings:[langID].comment_right = value;
         break;
      case CS_FIRST_LINE_IS_TOP:
         _settings:[langID].firstline_is_top = value;
         break;
      case CS_LAST_LINE_IS_BOTTOM:
         _settings:[langID].lastline_is_bottom = value;
         break;
      case CS_LINE_COMMENT_MODE:
         _settings:[langID].mode = value;
         break;
      case CS_LINE_COMMENT_COL:
         _settings:[langID].comment_col = value;
         break;
      }
   }
   
   return value;
}

#define DBASE_FIELD_WIDTH 13

static void dbase_say_box(_str tlc,_str trc,_str blc,_str brc,_str hside,_str vside)
{
   int first_col=0;
   int last_col=0;
   int buf_id=0;
   _get_selinfo(first_col,last_col,buf_id);
   _begin_select();
   int width=last_col-first_col-1;
   if ( width<0 ) {
      width=0;
   }
   int cursor_y=p_cursor_y;
   int count=count_lines_in_selection();
   _begin_select();
   if ( def_line_insert=='B' ) {
      up();
   }
   _str top_side=substr('',1,width,hside);
   insert_line(substr('@ 'first_col','cursor_y+1,1,DBASE_FIELD_WIDTH)' SAY "':+
                      tlc:+top_side:+trc'"');
   int i;
   for( i=1;i<=(count-2) ;++i ) {
      insert_line(substr('@ ROW()+1,'cursor_y+1,1,DBASE_FIELD_WIDTH)' SAY "':+
                  vside:+substr('',1,width):+vside'"');
   }
   insert_line(substr('@ ROW()+1,'cursor_y+1,1,DBASE_FIELD_WIDTH)' SAY "':+
                      blc:+top_side:+brc'"');
   _deselect();
}

static int _leftmost_col_in_selection(_str markid='')
{
   if ( !select_active() ) {
      _message_box('No selection active');
      return(MAX_LINE);
   }
   save_pos(auto p);
   int end_col=0;
   int throw_out_last_line=0;
   if ( _select_type()=='CHAR' ) {
      typeless dummy;
      _get_selinfo(dummy,end_col,dummy);
      if ( end_col==1 ) {
         // Throw out the last line of the character selection
         throw_out_last_line=1;
      }
   }
   int status=_begin_select(markid);
   if ( status ) return(MAX_LINE);
   int leftmostcol=_first_non_blank_col(MAX_LINE);
   for ( ;; ) {
      if ( down() ||
           _end_select_compare(markid)>0 ||
           (throw_out_last_line && !_end_select_compare(markid)) ) {
         break;
      }
      int col=_first_non_blank_col(MAX_LINE);
      if ( col<leftmostcol ) {
         leftmostcol=col;
      }
   }
   restore_pos(p);
   return(leftmostcol);
}

/** 
 * Finds the leftmost column in a selection, checking columns 
 * only after the designated start column.  Note that this will 
 * search for the first NONBLANK column.  So if a blank line is 
 * found, that line is essentially thrown out. 
 * 
 * @param start
 * @param markid
 * 
 * @return int
 */
static int _leftmost_col_in_selection_after_start(int start = 1, _str markid='')
{
   if ( !select_active() ) {
      _message_box('No selection active');
      return(MAX_LINE);
   }
   save_pos(auto p);
   int end_col=0;
   int throw_out_last_line=0;
   if ( _select_type()=='CHAR' ) {
      typeless dummy;
      _get_selinfo(dummy,end_col,dummy);
      if ( end_col==1 ) {
         // Throw out the last line of the character selection
         throw_out_last_line=1;
      }
   }
   int status=_begin_select(markid);
   if ( status ) return(MAX_LINE);

   int leftmostcol = pos('[~ \t]', _expand_tabsc(), start, p_rawpos'er');
   if (leftmostcol == 0) {
      leftmostcol = MAX_LINE;
   }

   for ( ;; ) {
      if ( down() ||
           _end_select_compare(markid)>0 ||
           (throw_out_last_line && !_end_select_compare(markid)) ) {
         break;
      }
      int col = pos('[~ \t]', _expand_tabsc(), start, p_rawpos'er');
      if ( col > 0 && col < leftmostcol ) {
         leftmostcol=col;
      }
   }
   restore_pos(p);
   return(leftmostcol);
}

/**
 * This setting is the default for all languages for the
 * comment editing feature for automatically inserting an
 * asterisk on a new line when extending a JavaDoc comment.
 * This setting corresponds to the language specific flag:
 * VS_COMMENT_EDITING_FLAG_AUTO_JAVADOC_ASTERISK.
 * <p>
 * 
 * @default 1
 * @categories Configuration_Variables
 */
boolean def_auto_javadoc=true;
/**
 * This setting is the default for all languages for the
 * comment editing feature for joining line comments.
 * This setting corresponds to the language specific flag:
 * VS_COMMENT_EDITING_FLAG_JOIN_COMMENTS.
 * <p>
 * 
 * @default 1
 * @categories Configuration_Variables
 */
boolean def_auto_linecomment=true;
/**
 * This setting is the default for all languages for the
 * comment editing feature for splitting and extending line
 * comments. This setting corresponds to the language specific
 * flag: VS_COMMENT_EDITING_FLAG_SPLIT_LINE_COMMENTS.
 * <p>
 * 
 * @default 1
 * @categories Configuration_Variables
 */
boolean def_extend_linecomment=true;
/**
 * This setting is the default for all languages for the
 * comment editing feature for automatically generating JavaDoc
 * comments.  This setting corresponds to the language specific
 * flag: VS_COMMENT_EDITING_FLAG_AUTO_JAVADOC_COMMENT.
 * <p>
 * The comment is generated when the user hits ENTER after
 * typing &#47;** on a line directly above a function, class
 * or variable.
 * <p>
 * 
 * @default 1
 * @categories Configuration_Variables
 */
boolean def_auto_javadoc_comment=true;
/**
 * This setting is the default for all languages for the comment editing feature 
 * for automatically generating doc comments.  This setting corresponds to the 
 * language specific flag: VS_COMMENT_EDITING_FLAG_AUTO_DOXYGEN_COMMENT. 
 * <p>
 * The comment is generated when the user hits ENTER after
 * typing &#47;*! on a line directly above a function, class or variable. 
 * <p> 
 * 
 * @default 1
 * @categories Configuration_Variables
 */
boolean def_auto_doc_comment=true;
/**
 * This setting is the default for all languages for the
 * comment editing feature for automatically generating XMLDoc
 * comments.  This setting corresponds to the language specific
 * flag: VS_COMMENT_EDITING_FLAG_AUTO_XMLDOC_COMMENT.
 * <p>
 * The comment is generated when the user hits ENTER after
 * typing /// on a line directly above a function, class or
 * variable.
 * <p>
 * 
 * @default 1
 * @categories Configuration_Variables
 */
boolean def_auto_xmldoc_comment=true;
/**
 * This setting is the default for all languages for the
 * comment editing feature for joining line comments.
 * This setting corresponds to the language specific flag:
 * VS_COMMENT_EDITING_FLAG_JOIN_COMMENTS.
 * <p>
 * 
 * @default 1
 * @categories Configuration_Variables
 */
boolean def_join_comments=true;
/**
 * This setting is the default for all languages for the
 * comment editing feature for splitting string constants.
 * This setting corresponds to the language specific flag:
 * VS_COMMENT_EDITING_FLAG_SPLIT_STRINGS.
 * <p>
 * 
 * @default 1
 * @categories Configuration_Variables
 */
boolean def_auto_string=true;

/**
 * @return 
 * Return the bitset of flags containing the language specific 
 * comment editing settings.
 * 
 * @param mask    Mask for checking specific flags. 
 *                Bitset of VS_COMMENT_EDITING_FLAG_* 
 * @param lang    Language to get flags for
 *  
 * @deprecated Use {@link _GetCommentEditingFlags()} 
 */
int _ext_comment_editing_flags(int mask=0, _str lang='')
{
   return _GetCommentEditingFlags(mask,lang);
}
/**
 * @return 
 * Return the bitset of flags containing the language specific 
 * comment editing settings.
 * 
 * @param mask    Mask for checking specific flags. 
 *                Bitset of VS_COMMENT_EDITING_FLAG_* 
 * @param lang    Language to get flags for
 *  
 * @categories Miscellaneous_Functions
 */
int _GetCommentEditingFlags(int mask=0, _str lang='')
{
   if (lang=='' && _isEditorCtl()) {
      lang = p_LangId;
   }

   flags := LanguageSettings.getCommentEditingFlags(lang);
   if (!mask) return flags;
   return flags & mask;
}

static _str parseDocCommentFlags(_str flags, _str mask){
   _str returnVal = '';
   parse flags with . (DocCommentFlagDelimiter:+mask:+DocCommentFlagDelimiter) returnVal DocCommentFlagDelimiter .;
   return returnVal;
}

static void setDocCommentFlags(_str &flags, _str mask, _str newValue){
   _str pre = '', post = '', oldValue = '';
   parse flags with pre (DocCommentFlagDelimiter:+mask:+DocCommentFlagDelimiter) oldValue DocCommentFlagDelimiter post;
   flags = pre :+DocCommentFlagDelimiter:+ mask :+DocCommentFlagDelimiter:+ newValue :+DocCommentFlagDelimiter:+ post;
}


/**
 * @return 
 * Return a string of representing the types of documentation comments 
 * supported by the given language. 
 * 
 * @param mask    Type of documention comment, on of DocComment*
 * @param lang    Language to get options for
 *  
 * @deprecated Use {@link _GetDocCommentFlags()} 
 */
_str _ext_doc_comment_flags(_str mask = DocCommentStyle1, _str lang = '')
{
   return _GetDocCommentFlags(mask,lang);
}
/**
 * @return 
 * Return a string of representing the types of documentation comments 
 * supported by the given language. 
 * 
 * @param mask    Type of documention comment, on of DocComment*
 * @param lang    Language to get options for
 *  
 * @categories Miscellaneous_Functions 
 * @since 13.0 
 */
_str _GetDocCommentFlags(_str mask = DocCommentStyle1, _str lang = '')
{
   _str flags = LanguageSettings.getDocCommentFlags(lang);
   _str returnVal = parseDocCommentFlags(flags, mask);
   if (returnVal == '') {
      returnVal = DocCommentStyle1;
   }
   return returnVal;
}

static _str convertStyleToLabel(_str expandStyleSetting) {
   if (length(expandStyleSetting) > 1) {
      expandStyleSetting = substr(expandStyleSetting, 1, 1) :+ DocCommentStyleLabel :+ substr(expandStyleSetting, 2, 1);
   } else {
      expandStyleSetting = substr(expandStyleSetting, 1, 1) :+ DocCommentStyleLabel;
   }
   return expandStyleSetting;
}

static _str convertLabelToStyle(_str expandStyleSetting) {
   if (DocCommentStyleLabel == '') {
      return expandStyleSetting;
   }
   _str stylePre, stylePost;
   parse expandStyleSetting with stylePre DocCommentStyleLabel stylePost;

   return stylePre :+ stylePost;
}

/**
 * Copies the settings found on [Language] > Comments from one language to 
 * another. 
 * 
 * @param srcLang          language to copy settings FROM
 * @param destLang         language to copy settings TO
 * 
 * @return                 true if successful, false otherwise
 */
boolean _copy_language_comment_settings(_str srcLang, _str destLang)
{
   flags := LanguageSettings.getCommentEditingFlags(srcLang);
   LanguageSettings.setCommentEditingFlags(destLang, flags);

   dcFlags := LanguageSettings.getDocCommentFlags(srcLang);
   LanguageSettings.setDocCommentFlags(destLang, dcFlags);

   // get thLe comment settings (the left side of the form)
   BlockCommentSettings_t tempSettings:[];
   getCommentSettings(srcLang, tempSettings);
   if (saveCommentSettings(destLang,tempSettings:[srcLang])) {
      return false;
   }

   return true;
}

