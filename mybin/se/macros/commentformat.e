////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50310 $
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
#import "alias.e"
#import "box.e"
#import "ccode.e"
#import "clipbd.e"
#import "codehelp.e"
#import "cutil.e"
#import "html.e"
#import "listproc.e"
#import "main.e"
#import "markfilt.e"
#import "mprompt.e"
#import "notifications.e"
#import "search.e"
#import "seldisp.e"
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "util.e"
#import "xmlwrap.e"
#require "se/lang/api/LanguageSettings.e"
#require "se/ui/TextChange.e"
#endregion
         
using se.lang.api.LanguageSettings;
using se.ui.TextChangeNotify;

/*                                                                             
 * Comment wrap
 *
 * Author: David O'Brien
 *
 * Comment wrap provides automatic wrapping of comments to keep the width of 
 * each line as uniform as possible.
 * 
 * This feature reacts to six keyboard events; Enter, Backspace, Delete,
 * Home, paste, and other key strokes.  The entry points for these
 * events are.
 * 
 * 1. commentwrap_Enter()
 * 2. commentwrap_Backspace()
 * 3. commentwrap_Delete()
 * 4. commentwrap_Home()
 * 5. commentwrap_doeditkey()
 * 6. commentwrap_Paste()
 *
 */

#define XMLDOC_PREFIX '///'
#define JAVADOC_PREFIX '/**'
#define JAVADOC_END_PREFIX ' */'
#define JAVADOC_LEFT_ASTERISK ' * '
#define JAVADOC_LEFT_NO_ASTERISK '   '
#define DOXYGEN_PREFIX1 '/*!'
#define DOXYGEN_PREFIX2 '//!'

//Block comment type flags
#define  CW_NOTCOMMENT              0x0000
#define  CW_FULLBLOCKCOMMENT        0x0001
#define  CW_LINECOMMENT             0x0002
#define  CW_JAVADOCCOMMENT          0x0004
#define  CW_XMLDOCCOMMENT           0x0008
#define  CW_DOXYGENDOCCOMMENT       0x0010
#define  CW_LINECOMMENTBLOCK        0x0020
#define  CW_FUNDAMENTALMODE         0x0040
#define  CW_TRAILINGCOMMENT         0x0080

//Reflow to next line result flags
#define  CW_REFLOWED                0x0000
#define  CW_NONEEDTOREFLOW          0x0001
#define  CW_CANNOTREFLOW            0x0002

#define  CW_DEFAULTDOCCOMMENTALIASFILE 'doccomment.als.xml'
#define  CW_DOCCOMMENTALIASFILESUFFIX '_'CW_DEFAULTDOCCOMMENTALIASFILE

/**
 * If positive, then Comment Wrap for line comments will stop on
 * the first Enter keystroke. 
 *
 * @default 0
 * @categories Configuration_Variables
 */
int def_CW_EnterEndsLineComments = 0;
/**
 * If positive, then Comment Wrap for line comments will stop on
 * the second consecutive Enter keystroke. 
 *
 * @default 1
 * @categories Configuration_Variables
 */
int def_CW_DoubleEnterEndsLineComments = 1;

//Stores current language
static _str CW_p_LangId = '';
//Stores current comment type
static int CW_commentType = CW_NOTCOMMENT;
//Store the actual delimiters for the comment
static _str CW_commentTLCstr = '';
static _str CW_commentBRCstr = '';
//Stores column of the left border of comment,
static int CW_commentBorderLeftCol = 1;
//Stores column of the margin(first place to put content) for comment
static int CW_commentMarginLeftCol = 1;
//Stores column of the margin(first place to put content) for comment start line
static int CW_commentMarginLeftColStart = 1;
//Stores column of the margin(first place to put content) for comment end line
static int CW_commentMarginLeftColEnd = 1;
//Width calculated by auto width calculation.
static int CW_analyzedWidth = 0;
//Width calculated by the presence of a right border
static int CW_RBanalyzedWidth = 0;
//Stores the left border of a line comment
static _str CW_lineCommentLeft = '';
//Stores whether this is a new comment.  Used in conjunction with auto width override
static int CW_lineCommentHitEnterLastLine = 0;
//Stores whether this is a new comment.  Used in conjunction with auto width override
static boolean CW_inNewComment = false;
static boolean CW_inJavadocScriptTag = false;

// True if the comment was started by the noxious double comment.
// ie:  /*******************//**[CR].....
static boolean CW_isDoxygenCommentPair = false;

//Store comment start position
static _str CW_startPos = 0;
//Store comment end position
static typeless CW_endPos = 0;
//Use to cache current line.
static _str CW_currentLine = '';
//Store calculated settings of the current comment
static BlockCommentSettings_t CW_commentSettings = {'/* ', '', '', ' */', '', '', '', '', '//', '', 1, false, false};
static int CW_numberOfLinesInComment = 1;
static int CW_trailingCommentCol = 0;
#define CW_CANNOT_FORMAT_MESSAGE 'Unable to wrap this comment.'
#define CW_CANNOT_FORMAT_MESSAGE_SKELETON 'Maximum right column extended to fit this comment block.'
#define CW_CANNOT_FORMAT_MESSAGE2 'Unable to wrap this comment within specified width.'
#define CW_BORDER_ERROR_MESSAGE 'Unable to wrap comments when typing in border area.'

#define CW_OUTOFCOMMENT 0
#define CW_INCOMMENTFIRSTTIME 1
#define CW_INCOMMENT 2
//Stores the state of the current comment
static int CW_commentState = CW_OUTOFCOMMENT;

//Paragraph start type flags
#define  CW_NOTPARA       0x0000
#define  CW_STARTLINE     0x0001
#define  CW_PREVBLANK     0x0002
#define  CW_BULLET        0x0003
#define  CW_NUMBER        0x0004
#define  CW_JDBLOCKTAG    0x0005
#define  CW_JDHTMLTAG     0x0006
#define  CW_INDENT        0x0007
#define  CW_DOXYGENTAG    0x0008

static _str CW_javadocBlockTags = "^(?4(@serialField(\\:b\\:v){,2})|(@param(\\:b\\:v)?)|(@throws(\\:b\\:v)?)|(@exception(\\:b\\:v)?)|@author|@example|@version|@see|@return|@since|@serial|@serialData|@deprecated|@link|@appliesTo|@categories)";
static _str CW_javadocBlockTags2 = "^(?4(@serialField(\\:b\\:v){,2})|(@param(\\:b\\:v)?)|(@throws(\\:b\\:v)?)|(@exception(\\:b\\:v)?)|@author|@example|@version|@see|@return|@since|@serial|@serialData|@deprecated|@link|@appliesTo|@categories)[ \\t]*";
static _str CW_docCommentTags = "^(?4([@\\\\]\\:v))[ \\t]*";
static _str CW_commentBulletTags = "^(\\*{1,3}|-{1,3})\\)?[ \\t]*";
static _str CW_commentNumberTags = "^\\:i[\\.\\)]?[ \\t]*";
#define CW_NAME_REGEX "[\\p{IsXMLNameStartChar}][\\p{IsXMLNameChar}]*([:][\\p{IsXMLNameStartChar}][\\p{IsXMLNameChar}]*):0,1"
#define CW_STARTOFSTARTORENDTAGREGEX '(<|</){#0['CW_NAME_REGEX'}(\n|:b|>)'

void _before_write_state_clear_cw_hash_table() 
{
   _ClearCommentWrapFlags();
}

definit()
{
   if ( arg(1):!='L' ) {
      /* Editor initialization case. */
      _ClearCommentWrapFlags();
      CW_clearCommentState();
   } else {
      // Module loaded with load command or loaded due to building state file.
   }
}

/**
 * Determines if comment wrap can handle this type of comment
 * 
 * @param commentType Comment type to check
 * 
 * @return boolean  True if this is a comment type that comment wrap
 *                  can currently handle.
 */
static boolean CW_isAcceptableCommentType(int commentType) {
   return (/*(commentType == CW_FUNDAMENTALMODE) ||*/ (commentType == CW_JAVADOCCOMMENT) || (commentType == CW_FULLBLOCKCOMMENT) || (commentType == CW_LINECOMMENTBLOCK) ||
           (commentType == CW_TRAILINGCOMMENT)
           //|| (commentType == CW_DOXYGENDOCCOMMENT)
           );
}

/**
 * When a new Javadoc is created, set the comment wrap flag for 
 * new comment.  This is to prevent auto override from kicking 
 * in.
 */
void commentwrap_SetNewJavadocState() {
   TextChangeNotify.enableTextChange(false);
   if (CW_updateCommentState() == CW_JAVADOCCOMMENT) {
      CW_inNewComment = true;
   } else {
      //This should never happen
      CW_clearCommentState();
   }
   TextChangeNotify.enableTextChange(true);
}

/**
 * Get at most the first word of the current line from the given 
 * column.  Will include all white space before first word and 
 * after first word up to start of second word.
 * 
 * @param fromCol    Column from which to pull first word
 * @param expandTabs If true, expand tabs to spaces before 
 *                   extracting word
 * 
 * @return _str      First word from column, including 
 *                   surrounding white space.
 */
static _str CW_getWordFromColumn(int fromCol = -1, boolean expandTabs = false) {
   _str line, returnWord;
   if (fromCol < 1) {
      fromCol = p_col;
   }
   if (expandTabs) {
      line = _expand_tabsc();
      returnWord = substr(line, fromCol);
   } else {
      get_line_raw(returnWord);
      returnWord = substr(line, text_col(line, fromCol, 'P'));
   }
   int verifyCol = verify(returnWord, " \t");
   if (!verifyCol) {
      return(returnWord);
   }
   verifyCol = verify(returnWord, " \t", 'M', verifyCol);
   if (!verifyCol) {
      return(returnWord);
   }
   verifyCol = verify(returnWord, " \t", '', verifyCol);
   if (!verifyCol) {
      return(returnWord);
   }
   return(substr(returnWord, 1, verifyCol - 1));
}

/**
 * Get at most the last word of the current line. Will
 * include all white space before last word and none after
 * last word.
 * 
 * @param endCol     (output only) Column that starts the 
 *                   last word
 * @param expandTabs If true, expand tabs to spaces before 
 *                   extracting word
 * 
 * @return _str      Last word of line, including leading
 *                   white space.
 */
static _str CW_getLastWord(int& endCol, boolean expandTabs = false) {
   _str line, returnWord;
   if (expandTabs) {
      line = _expand_tabsc();
   } else {
      get_line_raw(line);
   }
   returnWord = strip(line, 'T');
   
   if (returnWord == '') {
      endCol = 0;
      return ('');
   }

   int status = lastpos("[^ \t][ \t]", returnWord, "", 'U');

   if (!status) {
      endCol = 0;
      return (returnWord);
   }
   status++;
   endCol = text_col(returnWord, length(returnWord), 'I');
   return (substr(returnWord, status));
}
//Get the content of the current line from the given column
_str CW_getLineFromColumn(int fromCol = -1, boolean expandTabs = false) {
   _str line;
   if (fromCol < 1) {
      fromCol = p_col;
   }
   if (expandTabs) {
      line = _expand_tabsc();
      return(substr(line, fromCol));
   } else {
      get_line_raw(line);
   }
   return(substr(line, text_col(line, fromCol, 'P')));
}
//Get the content of the current line up to, but not including, the given column
_str CW_getLineToColumn(int fromCol = -1, boolean expandTabs = false) {
   _str line;
   if (fromCol < 1) {
      fromCol = p_col;
   }
   if (expandTabs) {
      line = _expand_tabsc();
      return(substr(line, 1, fromCol - 1));
   } else {
      get_line_raw(line);
   }
   return(substr(line, 1, text_col(line, fromCol, 'P') - 1));
}
/**
 * Save the current language type.  Need for embedded 
 * languages so that we do not have to continually recheck 
 * if in an embedded language. 
 */
_str CW_saveCurrentLang() {
   CW_p_LangId = p_LangId;
   // Handle embedded language
   typeless orig_values;
   int embedded_status = _EmbeddedStart(orig_values);
   if (embedded_status == 1) {
      CW_p_LangId = p_LangId;
      _EmbeddedEnd(orig_values);
   }
   return CW_p_LangId;
}

/**
 * Check if we should try to wrap comment.
 * 
 * @return int   0 if we should try to wrap comment
 *               1 if not in a comment block we can handle
 *               2 if comment wrap not enabled
 */
static int checkCommentWrapStatus(boolean inDoEditKey = false, boolean forceOn = false) {
   if (command_state() || !_isEditorCtl()) {
      return (1);
   }

   if (!_GetCommentWrapFlags(CW_ENABLE_COMMENT_WRAP, CW_p_LangId) && !forceOn) {
      CW_clearCommentState();
      return (2);
   }
   CW_commentType = CW_updateCommentState(inDoEditKey, forceOn);
   //saySettings(CW_commentType);
   if (!CW_isAcceptableCommentType(CW_commentType)) {
      CW_clearCommentState();
      return (1);
   }
   if (CW_commentType == CW_JAVADOCCOMMENT && !_GetCommentWrapFlags(CW_ENABLE_DOCCOMMENT_WRAP, CW_p_LangId) && !forceOn) {
      CW_clearCommentState();
      return (2);
   }
   if (CW_commentType == CW_FULLBLOCKCOMMENT && !_GetCommentWrapFlags(CW_ENABLE_BLOCK_WRAP, CW_p_LangId) && !forceOn) {
      CW_clearCommentState();
      return (2);
   }
   if (CW_commentType == CW_LINECOMMENTBLOCK && !_GetCommentWrapFlags(CW_ENABLE_LINEBLOCK_WRAP, CW_p_LangId) && !forceOn) {
      CW_clearCommentState();
      return (2);
   }
   if (CW_commentType == CW_TRAILINGCOMMENT && !_GetCommentWrapFlags(CW_ENABLE_LINEBLOCK_WRAP, CW_p_LangId) && !forceOn) {
      CW_clearCommentState();
      return (2);
   }
   return (0);
}

/**
 * Called to just return the content, if any, of the current line if in 
 * a comment.  Currently this function is to be used only by the detect 
 * treat URLs in comments as links feature.  It's use in other contexts 
 * may have side effects for comment wrapping. 
 * 
 * @param [out] content   String variable to hold the content of the 
 *                        current comment line's content
 * 
 * @return boolean  Return non-zero on error, or not in comment.
 */
int CW_getCommentLineContent(_str& content) {
   if (command_state() || !_isEditorCtl())
      return (1);

   int startCol = p_col;
   _str origLine; get_line_raw(origLine);
   typeless startPos = 0, endPos = 0;
   int commentType = CW_inBlockComment(startPos, endPos, true);
   if (commentType == CW_NOTCOMMENT) {
      content = '';
      return 1;
   }
   if (!CW_analyzeBlockComment(startPos, endPos, commentType)) {
      CW_clearCommentState();
      return (1);
   }
   typeless startLine, endLine;
   parse startPos with startLine .;
   parse endPos with endLine .;

   if (commentType != CW_LINECOMMENT && p_line == endLine) {
      restore_pos(endPos);
      _delete_end_line();
   }
   if (commentType == CW_LINECOMMENT || p_line == startLine) {
      p_col = 1;
      _delete_text(CW_commentBorderLeftCol - 1, 'C');
   }

   int currentRMC = 0;
   int nextLMC = 0, nextRMC = 0;
   int CafterBulletCol = 1, NafterBulletCol = 1;

   //Examine current line
   CW_extractBCLineText(content, startLine, endLine, currentRMC, CafterBulletCol);
   p_col = CW_commentBorderLeftCol;
   replace_line_raw(origLine);
   p_col = startCol;
   return (0);
}


/**
 * Function used to handle when the ENTER key is pressed in comments
 * 
 * @return boolean  True if comment wrap handled the ENTER keystroke
 */
boolean commentwrap_Enter(boolean extendLeadingBorderCase = false) {  
   boolean calledFromNosplitInsertLine = false;
   //say(name_on_key(ENTER));
   if (name_on_key(ENTER)=='nosplit-insert-line') {
      calledFromNosplitInsertLine = true;
   }
   if (calledFromNosplitInsertLine) {
      //nosplit_insert_line();
      return false;
   }
   CW_saveCurrentLang();

   // see if we need to create a new block comment skeleton
   if (!calledFromNosplitInsertLine && CW_maybeCreateNewDefault()) {
      return (true);
   }

   // maybe create a new javadoc skeleton
   if (!calledFromNosplitInsertLine && CW_maybeCreateNewJavadocDefault()) {
      return (true);
   }
   if (XW_isSupportedLanguage2()) {
      boolean status = XW_Enter();
      maybeOpenHiddenLines(p_line, p_col);
      return (status);
   }
   //messageNwait('Enter');
   int returnVal = checkCommentWrapStatus(false, extendLeadingBorderCase);
   if (!returnVal && !calledFromNosplitInsertLine) {
      boolean returnValBool = CW_doEnter(extendLeadingBorderCase);
      maybeOpenHiddenLines(p_line, p_col);
      return (returnValBool);
   }
   if (!returnVal && calledFromNosplitInsertLine) {
      typeless p; save_pos(p);
      typeless endLine;
      parse CW_endPos with endLine .;
      //if on bottom line with no content on last line, do nothing
      if (p_line == endLine && !CW_commentSettings.lastline_is_bottom) {
         end_line();
         split_insert_line();
         return (true);
      }
      if (false && p_line == endLine && CW_commentSettings.lastline_is_bottom) {
         end_line();
         split_insert_line();
         return (true);
      }
      end_line();
      boolean returnValBool = CW_doEnter(extendLeadingBorderCase);
      maybeOpenHiddenLines(p_line, p_col);
      return (returnValBool);
   }

   return (false);
}

/**
 * Called by wordwrap_rubout() to handle comment wrap on Backspace keystroke.
 * 
 * @param skip     Pass in false to bypass comment state check, currently not
 *                 being used.
 * 
 * @return boolean  Return true if comment wrap handled the keystroke.
 */
boolean commentwrap_Backspace(boolean skip = false) {
   if (XW_isSupportedLanguage2()) {
      boolean status = XW_doBackspace();
      maybeOpenHiddenLines(p_line, p_col);
      return (status);
   }
   CW_saveCurrentLang();
   int returnVal = checkCommentWrapStatus();
   if (!returnVal) {
      boolean status = CW_doBackspace();
      maybeOpenHiddenLines(p_line, p_col);

      return (status);
   }
   return (false);
}

/**
 * Called by wordwrap_delete_char() to handle comment wrap on Delete keystroke.
 * 
 * @param skip    Pass is false to bypass comment state check, currently not
 *                being used.
 * 
 * @return boolean   Return true is comment wrap handled the keystroke.
 */
boolean commentwrap_Delete(boolean skip = false) {

   if (XW_isSupportedLanguage2()) {
      boolean status = XW_doDelete();
      maybeOpenHiddenLines(p_line, p_col);
      return (status);
   }
   CW_saveCurrentLang();
   int returnVal = checkCommentWrapStatus();
   if (!returnVal) {
      boolean status = CW_doDelete();
      maybeOpenHiddenLines(p_line, p_col);

      return (status);
   }
   return (false);
}

/**
 * Called by begin_line_text_toggle() to handle comment wrap on Home keystroke.
 * 
 * Moves the cursor to first column of real content in a comment block.  The
 * return to begin_line_text_toggle() will handle whether to toggle to column 1.
 * 
 * @param skip    Pass in false to bypass comment state check, currently
 *                not being used.
 * 
 * @return boolean   Return true is comment wrap handled the keystroke by moving
 *         cursor to start of real content.
 */
boolean commentwrap_Home(boolean skip = false) {
   CW_saveCurrentLang();
   if (!commentwrap_isSupportedLanguage()) {
      return false;
   }
   //We always want to handle Home key by comment wrap so temporarily turn on.
   boolean  returnVal = false;
   if (!checkCommentWrapStatus(false, true)) {
      returnVal = CW_doHome();
   }
   return (returnVal);
}

static int currentContentLMargin() {
   typeless startLine, endLine;
   parse CW_startPos with startLine .;
   parse CW_endPos with endLine .;
   if (p_line == startLine) {
      return CW_commentMarginLeftColStart;
   }
   if (p_line == endLine) {
      return CW_commentMarginLeftColEnd;
   }
   return CW_commentMarginLeftCol;
}
//used by commentwrap_Paste() and commentwrap_Cut() function to prevent cycle 
//of commentwrap_Paste() and paste() (and commentwrap_Cut() and cut()) calling 
//each other.  This is not elegant but was used to keep changes in paste() and 
//cut() functions to a minimum. 
static boolean inCommentwrap_CutOrPaste = false;
boolean commentwrap_DeleteSelection(boolean skip = false, _str markid="") {
   int returnVal = checkCommentWrapStatus();
   CW_commentType = CW_updateCommentState();
   if (!returnVal && CW_commentType == CW_TRAILINGCOMMENT && _LanguageInheritsFrom('pl1', p_LangId) &&
       count_lines_in_selection() == 1) {
      typeless pt = point();
      inCommentwrap_CutOrPaste = true;
      _str content, comment;
      int commentCol = CW_preCorrectTrailingComment(content, comment);
      int deleteStat = _delete_selection();
      inCommentwrap_CutOrPaste = false;
      if (!deleteStat) {
         if (point() == pt && p_col >= currentContentLMargin() && !checkCommentWrapStatus()) {
            if (commentCol >= 0) {
               // comment2 is unused. When restoring the trailing line comment below we use
               // comment from above, b/c if the line is truncated, the paste could have pushed
               // part of the comment past the line truncation column 
               int commentCol2 = CW_preCorrectTrailingComment(content, auto comment2);
               if (commentCol2 >= 0) {
                  CW_CorrectTrailingComment(content, comment, commentCol);
               }
            } else {
               // what?
               //CW_doPasteReflow();
            }
         }
         return true;
      }
      CW_clearCommentState();
      _delete_selection(markid);
   } else {
      _delete_selection(markid);
   }
   return false;
}
/**
 * Called by paste() to try a paste and then comment wrap if in a comment.
 * Will only wrap simple pastes that leave the cursor on the same line 
 * to the right of the left border. 
 * 
 * @return boolean   Return true if comment wrap handled the paste.
 */
boolean commentwrap_Paste(_str name='',boolean isClipboard=true) {
   if (inCommentwrap_CutOrPaste) {
      return false;
   }
   CW_saveCurrentLang();
   int returnVal = checkCommentWrapStatus();
   if (!returnVal) {
      typeless pt = point();
      inCommentwrap_CutOrPaste = true;
      _str content, comment;
      int commentCol = -1;
      if (CW_commentType == CW_TRAILINGCOMMENT) {
         commentCol = CW_preCorrectTrailingComment(content, comment);
      }
      int pasteStat;
      pasteStat = paste(name, isClipboard);
      inCommentwrap_CutOrPaste = false;
      if (!pasteStat) {
         if (point() == pt && p_col >= currentContentLMargin() && !checkCommentWrapStatus()) {
            if (CW_commentType == CW_TRAILINGCOMMENT && commentCol >= 0) {
               // comment2 is unused. When restoring the trailing line comment below we use
               // comment from above, b/c if the line is truncated, the paste could have pushed
               // part of the comment past the line truncation column 
               int commentCol2 = CW_preCorrectTrailingComment(content, auto comment2);
               if (commentCol2 >= 0) {
                  CW_CorrectTrailingComment(content, comment, commentCol);
               }
            } else {
               CW_doPasteReflow();
            }
         }
         return (true);
      }
      CW_clearCommentState();
      return true;
   }
   return (false);
}
/**
 * Called by cut() to try a cut and then a comment wrap if in a comment.
 * Will only wrap simple cuts that leave the cursor on the same line 
 * to the right of the left border. 
 * 
 * @return boolean   Return true if comment wrap handled the paste.
 */
boolean commentwrap_Cut(boolean push=true,boolean doCopy=false,_str name='') {
   if (inCommentwrap_CutOrPaste) {
      return false;
   }
   if ( !select_active() ) {
      return false;
   }
   CW_saveCurrentLang();
   int returnVal = checkCommentWrapStatus();
   if (!returnVal) {
      int pl = p_line;
      int pc = p_col;
      inCommentwrap_CutOrPaste = true;
      _str content, comment;
      int commentCol = -1;
      if (CW_commentType == CW_TRAILINGCOMMENT) {
         commentCol = CW_preCorrectTrailingComment(content, comment);
      }
      int pasteStat;
      pasteStat = cut(push, doCopy, name);
      inCommentwrap_CutOrPaste = false;
      if (!pasteStat) {
         if (p_line == pl && p_col >= currentContentLMargin() && !checkCommentWrapStatus()) {
            if (CW_commentType == CW_TRAILINGCOMMENT && commentCol >= 0) {
               int commentCol2 = CW_preCorrectTrailingComment(content, comment);
               if (commentCol2 >= 0) {
                  CW_CorrectTrailingComment(content, comment, commentCol);
               }
            } else {
               CW_doPasteReflow();
            }
         }
         return (true);
      }
      CW_clearCommentState();
      return true;
   }
   return (false);
}
/**
 * Handles comment wrapping after a valid paste that can be reflowed.
 */
static void CW_doPasteReflow() {
   typeless startLine, endLine;
   parse CW_startPos with startLine .;
   parse CW_endPos with endLine .;
   CW_lineCommentHitEnterLastLine = 0;

   int absRightMargin = CW_getRightMargin();

   if (absRightMargin == 0) {
      //Try to analyze again to catch case when we had no multi-line
      //paragraphs and this keystroke now makes a multi-line paragraph.
      CW_analyzeWidth(CW_commentType, startLine, endLine);
      absRightMargin = CW_getRightMargin();
      //If still can't tell then
      if (absRightMargin == 0) {
      //Do nothing.  Either can't determine right margin or content can not fit.
      return;
      }
   }
   CW_maybeMergeAndReflow(startLine, endLine, p_line);
}

/**
 * Function called on key entries other than Delete, ENTER, Backspace.  Used to
 * decide whether the current keystroke will need to trigger a later call to
 * wrap
 * 
 * @return int   0 on success. 1 when not in a type of block comment comment 
 *               wrap understands.  2 when comment wrap is not on.
 */
int commentwrap_doeditkey() {
   if (XW_isSupportedLanguage2()) {
      if (ST_doSymbolTranslation()) {
         ST_nag();
      }
      return XW_doeditkey();
   }
   CW_saveCurrentLang();
   int returnVal = checkCommentWrapStatus(true);
   if (!returnVal) {
      CW_doCommentKey();
   } 
   return (returnVal);
}             

static void CW_makeLeadIn(int startLine, int endLine, int LMC, _str bullet) {
   _begin_line(); _delete_end_line(); 
   p_col = CW_commentBorderLeftCol;
   _insert_text_raw(CW_thisLineStartBorder(startLine,endLine));    
   if (p_col < LMC) {
      p_col = LMC;
   }                  
   _insert_text_raw(bullet);        
}

/**
 * - Handles what to do when Enter is pressed within a block comemnt. There
 * are two major cases.  First, when a new line needs to be inserted, and 
 * when a new line is not needed. 
 *  
 * @param extendLeadingBorderCase   True if comment wrap is off 
 *                                  and extend leading border is
 *                                  on.  When true, no wrapping
 *                                  of text is done.
 */
static boolean CW_doEnter(boolean extendLeadingBorderCase = false) {
   int lineCommentHitEnterLastLine = CW_lineCommentHitEnterLastLine;
   CW_lineCommentHitEnterLastLine = 0;

   if (CW_inJavadocScriptTag) { 
      //Do normal editting when in a Javadoc script tag. 
      return (false);
   }
   boolean addLeadIn = true;
   boolean addBlankLine = true;

   typeless startLine, endLine;
   parse CW_startPos with startLine .;
   parse CW_endPos with endLine .;
   int origLine = p_line, origCol = p_col;

   int absoluteRightMargin = CW_getRightMargin();

   //If I'm on the top or bottom line when there is no content,
   //then assume we've switched to having content
   if (p_line == startLine && !CW_commentSettings.firstline_is_top) {
      CW_commentSettings.firstline_is_top = true;
   }
   //if (p_line == endLine && !CW_commentSettings.lastline_is_bottom && endLine > startLine && strip(CW_commentSettings.blc) == "" && strip(CW_commentSettings.bhside) == "") {
   if (false && p_line == endLine && !CW_commentSettings.lastline_is_bottom && endLine > startLine) {
      _str thisLine; get_line_raw(thisLine);
      insert_line_raw(thisLine);
      endLine++;
      p_line = origLine;
      p_col = 1; _delete_end_line();
      CW_fixBorders2(startLine, endLine, absoluteRightMargin, "", CW_commentMarginLeftCol);
      p_col = origCol; p_line = origLine + 1;
      return (true);
   }
   if (p_line == endLine && !CW_commentSettings.lastline_is_bottom) {
      CW_commentSettings.lastline_is_bottom = true;
   }
   //Get hanging indent and leading bullets
   _str leadIn = '';
   int leadInCol = 1;
   if (addLeadIn) {
      leadInCol = CW_getParaLeadIn(startLine, endLine, leadIn);
   } else {
      leadIn = '';
      if (p_line == endLine) {
         leadInCol = CW_commentMarginLeftColEnd;
      } else {
         leadInCol = CW_commentMarginLeftCol;
      }
   }

   int currentLMC = 0;
   int currentRMC = 0;
   int bulletOffset = 0;
   _str content;
   currentLMC = CW_extractBCLineText(content, startLine, endLine, currentRMC, bulletOffset);
   //Two cases:  When we don't insert a line, and when we do.
   //We insert when at endLine, or next line is a para start or blank line
   boolean needNewLine, enterOnLastLine;
   needNewLine = enterOnLastLine = (p_line == endLine);
   if (p_line != endLine) {
      CW_down(); //not at end of line, so this should always work
      needNewLine = false;
      if(CW_isParaStart(CW_commentType, startLine, endLine)) {
         needNewLine = true;
      }
      if (CW_isBCBlankLine(startLine, endLine)) {
         needNewLine = true;
      }
      p_line = origLine; p_col = origCol;
   }
   needNewLine = needNewLine || extendLeadingBorderCase;
   if (needNewLine || (p_col <= currentLMC)) {
      int new_col, new_line;
      insert_line_raw('');
      endLine++;
      if (enterOnLastLine && CW_commentType == CW_LINECOMMENTBLOCK && (origCol > currentRMC)) {
         p_col = CW_commentBorderLeftCol;
         if (def_CW_EnterEndsLineComments != 0) {
            return true;
         }
         if (def_CW_DoubleEnterEndsLineComments != 0 && lineCommentHitEnterLastLine == p_line - 1) {
            if (p_line > 1) {
               up();
               p_col = 1;
               _delete_end_line();
               down();
               p_col = CW_commentBorderLeftCol;
            }
            return true;
         }
         _undo('S');
         p_col = 1;
         CW_lineCommentHitEnterLastLine = p_line;
      }
      CW_makeLeadIn(startLine, endLine, leadInCol, leadIn);

      new_col = p_col;
      new_line = p_line;
      p_line = origLine; p_col = origCol;
      //Three cases for the content, Before, In, and After the real content
      if (p_col > currentRMC) {//after
         CW_fixBorders2(startLine, endLine, absoluteRightMargin, content, currentLMC); 
         p_line = new_line; p_col = new_col;     
         CW_fixBorders2(startLine, endLine, absoluteRightMargin, '', new_col, true);   

      } else if (p_col <= currentLMC) {//before
         _str temp = CW_getLineFromColumn(currentLMC);
         _begin_line(); _delete_end_line();
         //Cursor will not be on this line
         CW_fixBorders2(startLine, endLine, absoluteRightMargin, '', 0, false); 
         p_line = new_line; p_col = new_col;
         _insert_text_raw(temp);
         p_col = new_col;
         return (true);
      } else {//in
         _str endStuff = strip(CW_getLineFromColumn(), 'L');
         _delete_end_line();
         //OK can not be endline
         CW_fixBorders(startLine, endLine, absoluteRightMargin, true); 
         p_line = new_line; p_col = new_col;
         _insert_text_raw(endStuff);
         p_col = new_col;
      }
   } else {   
      //No new line
      CW_down();
      int currentLMC2 = 0;
      int currentRMC2 = 0;
      int bulletOffset2 = 0;
      _str content2;
      int tempCol;
      currentLMC2 = CW_extractBCLineText(content2, startLine, endLine, currentRMC2, bulletOffset2);
      p_line = origLine; p_col = origCol;
      if (p_col > currentRMC) {
         if (addBlankLine) {
            insert_line_raw('');
            endLine++;       
            CW_makeLeadIn(startLine, endLine, leadInCol, leadIn);  
            CW_fixBorders2(startLine, endLine, absoluteRightMargin, '', p_col, true);
         } else {
            CW_down(); 
            CW_makeLeadIn(startLine, endLine, leadInCol, leadIn);
            tempCol = p_col;
            _insert_text_raw(content2);
            p_col = tempCol;
         }
      } else if (p_col <= currentLMC) { //Should never hit this case any more
         //Enter before start of content
         _begin_line(); _delete_end_line();  
         CW_fixBorders2(startLine, endLine, absoluteRightMargin, '', 0, false); 
         CW_down(); //can not be on last line, so should always work
         CW_makeLeadIn(startLine, endLine, leadInCol, leadIn);
         tempCol = p_col;
         strappend(content, ' ');
         strappend(content, content2);
         _insert_text_raw(content);
         p_col = tempCol;
      } else {
         //Enter in middle of line
         content = substr(' ', 1, currentLMC - 1, ' ') :+ content;
         _str endStuff = strip(substr(content, text_col(content, p_col, 'P')));
         _delete_end_line();
         //OK can not be endline
         CW_fixBorders(startLine, endLine, absoluteRightMargin, true);
         CW_down(); //can not be on last line, so should always work
         CW_makeLeadIn(startLine, endLine, leadInCol, leadIn);
         tempCol = p_col;
         strappend(endStuff, ' ');
         strappend(endStuff, content2);
         _insert_text_raw(endStuff);
         p_col = tempCol;

      }
   }
   if (!extendLeadingBorderCase) {
      //This call will join short lines, and reflow if necessary.
      CW_maybeMergeAndReflow(startLine, endLine, p_line, true);
   }
   return (true);
}

/**
 * Processes the Backspace key for comment wrap
 * 
 * @return boolean  True if able to handle the situation.  False, no special
 *                  handling needed, let backspace work as normal.  Also
 *                  return false for cases in which the comment wrap behavior is
 *                  not well-defined.
 */
static boolean CW_doBackspace() {
   if (CW_commentType == CW_TRAILINGCOMMENT) {
      _str content, comment;
      int commentCol = CW_preCorrectTrailingComment(content, comment);
      _rubout();
      if (commentCol < 0) return false;
      int commentCol2 = CW_preCorrectTrailingComment(content, comment);
      if (commentCol2 < 0) return false;
      CW_CorrectTrailingComment(content, comment, commentCol);
      return true;
   }

   typeless startLine, endLine;
   parse CW_startPos with startLine .;
   parse CW_endPos with endLine .;
   int currentLMC = 0;
   int currentRMC = 0;
   int CafterBulletCol = 0;
   _str currentLine;
   boolean reanalyze = false;

   boolean skipMergeUp = false, prevBlank = false;
   int lineCommentHitEnterLastLine = CW_lineCommentHitEnterLastLine;
   CW_lineCommentHitEnterLastLine = 0;

   if (CW_inJavadocScriptTag) {
      //Do normal editting when in a Javadoc script tag. 
      return (false);
   }

   if (startLine == endLine) {
      //Do nothing on one line comment, let wordwrap_rubout() handle it. 
      return (false);
   }

   if (p_line == endLine) {
      //Case of deleting on last line when there should be no content
      //Let user do this.  May harm comment appearence.
      if (!CW_commentSettings.lastline_is_bottom && p_col > CW_commentMarginLeftColEnd) {
         return (false);
      }
      if (!CW_commentSettings.lastline_is_bottom && p_col <= CW_commentMarginLeftColEnd) {
         //Safe.  Can not be start line
         up();
         //Maintain no content on last line.  Move cursor to end of previous line's content
         currentLMC = CW_extractBCLineText(currentLine, startLine, endLine, currentRMC, CafterBulletCol);
         int leftMargin = (p_line == startLine ? CW_commentMarginLeftColStart : CW_commentMarginLeftCol);
         p_col = currentRMC + 1;
         if (p_col < leftMargin) {
            p_col = leftMargin;
         }
         return (true);
      }
      currentLMC = CW_extractBCLineText(currentLine, startLine, endLine, currentRMC, CafterBulletCol);
      if (CW_commentType == CW_LINECOMMENTBLOCK && (p_col > currentRMC) && currentLine == '' && lineCommentHitEnterLastLine == p_line) {
         CW_lineCommentHitEnterLastLine = p_line;
         return (false);
      }
      //If not blank, butbackspacing beyond content, do nothing.
      if (currentLMC > 0 && p_col > currentRMC + 1) {
         return (false);
      }
   }
   if (p_line == startLine) {
      //If no content, let wordwrap_rubout() handle it.
      if (!CW_commentSettings.firstline_is_top) {
         return (false);
      }
      //If backspacing left of the margin.  Behavior is undefined, so do nothing 
      if (p_col <= CW_commentMarginLeftColStart) {
         return (false);
      }
   } 

   if (p_col <= CW_commentBorderLeftCol && CW_commentBorderLeftCol > 1) {
      //if in the space to the left of the border, do nothing.  This is not well defined.
      message(CW_BORDER_ERROR_MESSAGE);
      return (false);
   } 

   currentLMC = CW_extractBCLineText(currentLine, startLine, endLine, currentRMC, CafterBulletCol);
   //Handle cases when just before the content on a line that does not start a paragraph or
   //when backspacing into the left border.
   int isParaStart = CW_isParaStart(CW_commentType, startLine, endLine);
   //Fix special case of second line of a hanging indent paragraph.
   //If is a paragraph because of different indent, check if
   //previous line is start of para and content is more to the
   //left than this line.  Thus, a hanging indent.
   if ((isParaStart == CW_INDENT) && (p_line != 1)) {
      p_line--;
      _str dummyStr; int dummyInt1, dummyInt2;
      int prevContentStart = CW_extractBCLineText(dummyStr, startLine, endLine, dummyInt1, dummyInt2);
      if (prevContentStart < currentLMC && CW_isParaStart(CW_commentType, startLine, endLine)) {
         isParaStart = CW_NOTPARA;
      }
      p_line++;
   }
   
   //if ((p_col <= CW_commentMarginLeftColEnd && p_line == endLine) || (p_col <= CW_commentMarginLeftCol && startLine < p_line && p_line < endLine)) {
   if ( ((p_col == CW_commentMarginLeftColEnd && p_line == endLine) || (p_col == CW_commentMarginLeftCol && startLine < p_line && p_line < endLine)) ||
      ((p_col == currentLMC && p_line == endLine) || (p_col == currentLMC && startLine < p_line && p_line < endLine) && !isParaStart) ) {
      up();
      //2 cases:  First is previous line is blank
      // Insert current content at same position on previous line
      prevBlank = CW_isBCBlankLine(startLine, endLine);
      if (prevBlank) {
         skipMergeUp = true;
         down();
         currentLMC = CW_extractBCLineText(currentLine, startLine, endLine, currentRMC, CafterBulletCol);
         //if I'm also coming from a blank line, put cursor at start of line when we move up
         if (currentLMC == 0) {
            currentLMC = (p_line == endLine) ? CW_commentMarginLeftColEnd : CW_commentMarginLeftCol;
            _begin_line();_delete_text(currentLMC - 1, 'C');
         } else {
            //delete up to the current content
            if (CW_isParaStart(CW_commentType,startLine,endLine) == (5)) {
               CafterBulletCol = 1;
            }
            _begin_line();_delete_text(currentLMC+CafterBulletCol-2, 'C');
         }
         up();
         p_col = currentLMC;
         _delete_end_line();
         join_line();    endLine--;
      }
      //previous line is not blank.
      //Insert current content after previous content
      else {                    
         //previous line
         int currentLMC2 = CW_extractBCLineText(currentLine, startLine, endLine, currentRMC, CafterBulletCol);
         int insertCol = currentRMC + 1;
         down();
         //start line
         currentLMC = CW_extractBCLineText(currentLine, startLine, endLine, currentRMC, CafterBulletCol);
         boolean currentLineBlank = (currentLMC == 0);
         if (currentLineBlank) {
            //delete through the left border
            currentLMC = (p_line == endLine) ? CW_commentMarginLeftColEnd : CW_commentMarginLeftCol;
            _begin_line();_delete_text(currentLMC - 1, 'C');
         } else {
            //delete up to the current content
            _begin_line();_delete_text(currentLMC+CafterBulletCol-2, 'C');
         }
         up(); p_col = insertCol;
         _delete_end_line();
         p_col = insertCol;
         join_line();    endLine--;
         p_col = insertCol;
         if (currentLineBlank) {
            //If I moved up from a blank line, just fix borders and finish
            CW_fixBorders(startLine, endLine, CW_getRightMargin(), true, (p_line == endLine ? 0 : 1));
            return (true);
         }
      }

   } else if ((p_col <= CW_commentMarginLeftColEnd && p_line == endLine) || (p_col <= CW_commentMarginLeftCol && startLine < p_line && p_line < endLine)){
      message(CW_BORDER_ERROR_MESSAGE);
      _rubout();
      reanalyze = true;
   } else {
      //just in the middle of line content
      _rubout();
   }
   if (reanalyze) {
      //CW_analyzeBlockComment(CW_startPos, CW_endPos, CW_commentType);
      CW_clearCommentState();
      return (true);
   }
   CW_maybeMergeAndReflow(startLine, endLine, p_line, skipMergeUp);
   return (true);
}

/**
 * Processes the Delete key for comment wrap
 * 
 * @return boolean  True if able to handle the situation.  False, no special 
 *                  handling needed, let delete work as normal.  Also return
 *                  false for cases in which the comment wrap behavior is not
 *                  well-defined.
 */
static boolean CW_doDelete() {

   if (CW_commentType == CW_TRAILINGCOMMENT) {
      _str content, comment;
      int commentCol = CW_preCorrectTrailingComment(content, comment);
      maybe_delete_tab();
      if (commentCol < 0) return false;
      int commentCol2 = CW_preCorrectTrailingComment(content, comment);
      if (commentCol2 < 0) return false;
      CW_CorrectTrailingComment(content, comment, commentCol);
      return true;
   }

   typeless startLine, endLine;
   parse CW_startPos with startLine .;
   parse CW_endPos with endLine .;
   int currentLMC = 0;
   int currentRMC = 0;
   int CafterBulletCol = 0;
   _str currentLine;
   int nextLMC = 0;
   int nextRMC = 0;
   int NafterBulletCol = 0;
   _str nextLine;
   int origLine = p_line; int origCol = p_col;
   CW_lineCommentHitEnterLastLine = 0;

   if ((p_col < CW_commentMarginLeftColEnd && p_line == endLine) || (p_col < CW_commentMarginLeftColStart && p_line == startLine) || (p_col < CW_commentMarginLeftCol && startLine < p_line && p_line < endLine)) {
      message(CW_BORDER_ERROR_MESSAGE);
      CW_clearCommentState();
      return (false);
   }

   if (startLine == endLine) {
      //Do nothing on one line comment, let wordwrap_delete_char() handle it. 
      return (false);
   }

   if (p_line == endLine) {
      //Case of deleting on last line when there should be no content
      //Let user do this.  May harm comment appearence.
      //if (!CW_commentSettings.lastline_is_bottom && p_col > 1) {
      if (!CW_commentSettings.lastline_is_bottom) {
         return (false);
      }
      if (CW_commentSettings.lastline_is_bottom) {
         return (false);
         //maybe_delete_tab();
      }
   }
   if (p_line == startLine) {
      //If no content, let linewrap_delete_char() handle it.
      //DOB 
      if (!CW_commentSettings.firstline_is_top) {
         return (false);
      }
      //If deleting left of the margin.  Behavior is undefined, so do nothing 
      if (p_col <= CW_commentMarginLeftColStart) {
         return (false);
      }
      //maybe_delete_tab();
   }
   currentLMC = CW_extractBCLineText(currentLine, startLine, endLine, currentRMC, CafterBulletCol);
   //Handle cases when after content on a line other than the endLine
   if ((p_col > currentRMC && p_line != endLine)) {
         CW_down(); //can not be on last line, so should always work
         nextLMC = CW_extractBCLineText(nextLine, startLine, endLine, nextRMC, NafterBulletCol);
         if (nextLMC == 0) {
            _begin_line();
            _delete_end_line();
         } else {
            _begin_line();
            if (CW_commentType == CW_JAVADOCCOMMENT && pos(CW_javadocBlockTags, nextLine, 1, 'U')) {
               NafterBulletCol = 1;
            }
            _delete_text(nextLMC - 2 + NafterBulletCol, 'C');
         }
         p_line = origLine; p_col = origCol;
         int absRightMargin = CW_getRightMargin();
         int lastRightCol = absRightMargin - length(CW_thisLineEndBorder(startLine, endLine));
         //if (p_col > lastRightCol) {
         //   p_col = lastRightCol + 1;
         //}
         _delete_end_line();
         join_line();    
         endLine--;  
         CW_fixBorders(startLine,endLine,absRightMargin, true, 1); 
         //Deleted a blank line, do no more reflowing
         if (nextLMC == 0) {
            return (true);
         }
   } else {
      maybe_delete_tab();
   }
   CW_maybeMergeAndReflow(startLine, endLine, p_line, (currentLMC == 0));
   return (true);
}

/**
 * Processes the Home key for comment wrap
 * 
 * @return boolean  True if able to handle the situation.  False, no special
 *                  handling needed, let Home work as normal.  Also return
 *                  false for cases in which the comment wrap behavior is not
 *                  well-defined.
 */
static boolean CW_doHome() {

   typeless startLine, endLine;
   parse CW_startPos with startLine .;
   parse CW_endPos with endLine .;
   _str leftBorder = CW_thisLineStartBorder(startLine, endLine);
   //if there is no left border characters, do nothing and fall back to standard Home key action.
   if (leftBorder == '') {
      return false;
   }

   int currentCol = p_col;
   first_non_blank();
   int firstCol = p_col;

   int currentRMC = 0;
   int afterBulletCol = 0;
   _str currentLine;
   CW_lineCommentHitEnterLastLine = 0;
   int currentLMC = CW_extractBCLineText(currentLine, startLine, endLine, currentRMC, afterBulletCol);
   if (currentLMC == 0) {
      if (p_line == startLine) {
         currentLMC = CW_commentMarginLeftColStart;
      } else if (p_line == endLine) {
         currentLMC = CW_commentMarginLeftColEnd;
      } else {
         currentLMC = CW_commentMarginLeftCol;
      }
   }

   //Check for unusual values
   if (currentLMC <= firstCol || firstCol <= 1 || currentLMC <= 1) {
      return (false);
   }
   
   if (currentCol == 1 || currentLMC < currentCol) {
      p_col = currentLMC;
   } else if (firstCol < currentCol && currentCol <= currentLMC) {
      p_col = firstCol;
   } else {
      p_col = 1;
   }
   return (true);
}

/**
 * Handles comment wrapping on all key presses other than Enter, Backspace, and 
 * Delete.
 * 
 */
static void CW_doCommentKey() {
   if (CW_commentType == CW_TRAILINGCOMMENT) {
      _str content, comment;
      int commentCol = CW_preCorrectTrailingComment(content, comment, true);
      if (commentCol < 0) return;
      int commentCol2 = CW_preCorrectTrailingComment(content, comment, false);
      if (commentCol2 < 0) return;
      CW_CorrectTrailingComment(content, comment, commentCol);
      return;
   }
   typeless startLine, endLine;
   parse CW_startPos with startLine .;
   parse CW_endPos with endLine .;
   CW_lineCommentHitEnterLastLine = 0;

   if ((p_col < CW_commentMarginLeftColEnd && p_line == endLine) || (p_col < CW_commentMarginLeftColStart && p_line == startLine) || (p_col < CW_commentMarginLeftCol && startLine < p_line && p_line < endLine)) {
      message(CW_BORDER_ERROR_MESSAGE);
      CW_clearCommentState();
      return;
   }

   int absRightMargin = CW_getRightMargin();

   if (absRightMargin == 0) {
      //Try to analyze again to catch case when we had no multi-line
      //paragraphs and this keystroke now makes a multi-line paragraph.
      CW_analyzeWidth(CW_commentType, startLine, endLine);
      absRightMargin = CW_getRightMargin();
      //If still can't tell then
      if (absRightMargin == 0) {
      //Do nothing.  Either can't determine right margin or content can not fit.
      return;
      }
   }
   int reflowLine = p_line;

   //get the key pressed
   boolean hitSpace = CW_lastEventHitSpace(auto key);
   if (CW_commentState == CW_INCOMMENTFIRSTTIME && key == get_text_left() && p_col <= CW_commentMarginLeftCol) {
      return;
   }

   if (hitSpace && reflowLine != startLine && CW_inLineFirstWord(startLine, endLine) && !CW_isParaStart(CW_commentType, startLine, endLine, reflowLine)) {
      CW_maybeMergeAndReflow(startLine, endLine, reflowLine - 1 );
   }
   for (; CW_REFLOWED == CW_maybeReflowToNext(reflowLine, startLine, endLine, absRightMargin); incrementRealLineCounter(reflowLine)) {
   }
}

static int CW_splitLineAtTrailingComment(_str& content, _str& comment) {
   save_pos(auto p);
   int OriginalLine = p_line;
   int OriginalCol  = p_col;
   _clex_find(COMMENT_CLEXFLAG);
   if (!(p_line == OriginalLine && p_col > OriginalCol)) {
      restore_pos(p);
      return (-1);
   }
   int commentCol = p_col;
   comment = strip(CW_getLineFromColumn());
   content = strip(CW_getLineToColumn(), 'T');
   restore_pos(p);
   return commentCol;
}

static int CW_preCorrectTrailingComment(_str& content, _str& comment, boolean inDoEditKey = false) {
   _str cursorChar;
   // this block is whats shifting the comment left
   if (inDoEditKey) {
      left(); 
      cursorChar = get_text_raw();
      _delete_text(1);
   }
   int commentCol = CW_splitLineAtTrailingComment(content, comment);
   if (inDoEditKey) {
      _insert_text_raw(cursorChar);
   }
   return commentCol;
}

static void CW_CorrectTrailingComment(_str content, _str comment, int commentCol) {
   _save_pos2(auto p);
   if (commentCol > -1) {
      replace_line_raw(content);
      _restore_pos2(p);
      _save_pos2(auto p2);
      end_line();
      if (commentCol > p_col) {
         p_col = commentCol;
      }
      _insert_text_raw(comment);
      _restore_pos2(p2);
      return;
   }
}

/**
 * Author: David A. O'Brien
 * Date:   11/26/2007
 * 
 * @param boolean& hitSpace 
 * 
 * @return _str 
 */
boolean CW_lastEventHitSpace(_str& key) {
   key = last_event(null, true);
   return ((key == ' ') || (key:==name2event('TAB')));
}
boolean CW_lastEventHitTab(_str& key) {
   key = last_event(null, true);
   return (key:==name2event('TAB'));
}

/**
 * Move to start of previous paragraph and return any bullets or leading es be
 * fore the real content.
 * 
 * @param startLine  Line number of start of comment
 * @param endLine    Line number of end of comment
 * 
 * @return _str
 */
static int CW_getParaLeadIn(int startLine, int endLine, _str& bullet) {

   typeless p2; _save_pos2(p2);
   int returnVal = 0;
   int currentLMC = 0; int currentRMC = 0; int bulletOffset = 0;
   _str content = '';
   _str temp = CW_thisLineStartBorder(startLine, endLine);
   //Create a default value
   returnVal = CW_extractBCLineText(content, startLine, endLine, currentRMC, bulletOffset);
   bullet = '';
   if (bulletOffset - 1 > 0) {
      bullet = substr(content' ', 1, bulletOffset - 1);
   }

   while (p_line >= startLine) {
      if (p_line == startLine || CW_isParaStart(CW_commentType, startLine, endLine)) {
         currentLMC = CW_extractBCLineText(content, startLine, endLine, currentRMC, bulletOffset);
         //Be carefull and handle case of blank line.  Break and use the default.
         if (strip(content) == '') {
            break;
         }
         returnVal = currentLMC;
         if (_GetCommentWrapFlags(CW_MATCH_PREV_PARA, CW_p_LangId) && (!pos(CW_javadocBlockTags2, content, 1, 'U'))) {
            bullet = substr(content' ', 1, bulletOffset - 1);
         } else if (_GetCommentWrapFlags(CW_MATCH_PREV_PARA, CW_p_LangId) && (!pos(CW_docCommentTags, content, 1, 'U'))) {
            bullet = substr(content' ', 1, bulletOffset - 1);
         } else {
            bullet = '';
         }
         break;
      }
      p_line--;
   }
   _restore_pos2(p2);
   return (returnVal);
}

void CW_clearCommentState() {
   CW_commentState = CW_OUTOFCOMMENT;
   CW_startPos = 0;
   CW_endPos = 0;
   CW_commentType = CW_NOTCOMMENT;
   CW_analyzedWidth = 0;
   CW_RBanalyzedWidth = 0;
   CW_commentBorderLeftCol = 1;
   CW_commentMarginLeftCol = 1;
   CW_commentMarginLeftColStart = 1;
   CW_commentMarginLeftColEnd = 1;
   CW_trailingCommentCol = 0;
   CW_inNewComment = false;
   CW_inJavadocScriptTag = false;
   CW_isDoxygenCommentPair = false;
   CW_lineCommentLeft = '';
   //CW_lineCommentHitEnterLastLine = false;
   return;
}

/**
 * Gets called when active buffer is switched. Used to clear 
 * current comment state so active settings like right-margin 
 * are not inappropriately picked up in an unrelated 
 * comment/file. 
 *
 * @param old_buf_name  Name of buffer switched from.
 * @param flag   flag = 'Q' if file is being closed
 *               flag = 'W' if focus is being indicated
 */
void _switchbuf_commentwrap(_str old_buf_name, _str flag)
{
   if( flag == 'W' ) {
      // Just switching focus
      return;
   }
   CW_clearCommentState();
}

boolean commentwrap_isSupportedLanguage2(_str lang = CW_p_LangId) {
   if (_LanguageInheritsFrom('c', lang) ||
       //_LanguageInheritsFrom('xml', lang) ||
       file_eq('xml', lang) ||
       file_eq('html', lang) ||
       ('phpscript' == lang) ||
       //file_eq('xsd', lang) ||
       //file_eq('xhtml', lang) ||
       _LanguageInheritsFrom('pl1', lang) ||
       _LanguageInheritsFrom('java', lang) ||
       _LanguageInheritsFrom('e', lang) ||
       _LanguageInheritsFrom('js', lang) ||
       //_LanguageInheritsFrom('fundamental', lang) ||
       _LanguageInheritsFrom('cs', lang)) {
      return (true);
   }
   return (false);
}

/**
 * Returns true if lang is supported by comment wrap 
 * feature. 
 * 
 * @param lang 
 * 
 * @return (boolean) 
 */
boolean commentwrap_isSupportedLanguage(_str lang = CW_p_LangId) 
{
   if (command_state() || !_isEditorCtl()) {
      //return (false);
   }

// // Handle embedded language
// typeless orig_values;
// int embedded_status = _EmbeddedStart(orig_values, '');
// if (embedded_status == 1) {
//    boolean returnValue = commentwrap_isSupportedLanguage2();
//    _EmbeddedEnd(orig_values);
//    return returnValue; // Processing done for this key
// }
   return commentwrap_isSupportedLanguage2(lang);
}

static boolean posEqual(_str aPos, _str bPos){
   _str aline, acol, bline, bcol;
   parse aPos with aline acol .;
   parse bPos with bline bcol .;
   return ((aline' 'acol) == (bline' 'bcol));
}

/**
 * 
 * @param inDoEditKey
 * 
 * @return int
 */
static int CW_updateCommentState(boolean inDoEditKey = false, boolean forceOn = false) {
   if (command_state() || !_isEditorCtl()) {
      return (CW_NOTCOMMENT);
   }

   typeless startPos = 0, endPos = 0;

   CW_isDoxygenCommentPair = false;

   _str cursorChar;
   int commentType = CW_inBlockComment(startPos, endPos);
   if (commentType == CW_TRAILINGCOMMENT) {
      return (commentType);
   }

   if (!CW_isAcceptableCommentType(commentType)) {
      CW_clearCommentState();
      return (CW_NOTCOMMENT);
   }

   if ((commentType == CW_JAVADOCCOMMENT || commentType == CW_XMLDOCCOMMENT || commentType == CW_DOXYGENDOCCOMMENT) && !_GetCommentWrapFlags(CW_ENABLE_DOCCOMMENT_WRAP, CW_p_LangId) && !forceOn) {
      CW_clearCommentState();
      return (CW_NOTCOMMENT);
   }
   if (commentType == CW_FULLBLOCKCOMMENT && !_GetCommentWrapFlags(CW_ENABLE_BLOCK_WRAP, CW_p_LangId) && !forceOn) {
      CW_clearCommentState();
      return (CW_NOTCOMMENT);
   }

   if (commentType == CW_LINECOMMENTBLOCK && !_GetCommentWrapFlags(CW_ENABLE_LINEBLOCK_WRAP, CW_p_LangId) && !forceOn) {
      CW_clearCommentState();
      return (CW_NOTCOMMENT);
   }

   if (CW_commentState == CW_INCOMMENTFIRSTTIME) {
      //Do any processing needed on second time in comment
      CW_commentState = CW_INCOMMENT;
   }
   boolean equalPositions = posEqual(startPos, CW_startPos);
   if ((commentType != CW_commentType) || (CW_commentState == CW_OUTOFCOMMENT) || ((CW_commentState == CW_INCOMMENT) && (!equalPositions))) {
      //First action in this comment
      if ((CW_commentState == CW_INCOMMENT) && (!equalPositions)) {
         CW_clearCommentState();
      }
      if (!CW_analyzeBlockComment(startPos, endPos, commentType, inDoEditKey)) {
         CW_clearCommentState();
         return (CW_NOTCOMMENT);
      }
      //Save state to avoid analyzing each time.
      CW_commentState = CW_INCOMMENTFIRSTTIME;

   } else if (CW_commentState == CW_INCOMMENT) {
      //Continuing in the same comment
      //some actions may force us to reanalyze the comment.
      //When typing on start or end line, may need to recalc start end sequences
      typeless startLine, endLine;
      parse startPos with startLine .;
      parse endPos with endLine .;
      //if ((p_line == startLine) || (p_line == endLine))_CW_analyzeStartAndEndSeq(startPos, endPos);
      //When typing on start or end line, may need to recalc start end sequences
      if ((p_line == startLine) || (p_line == endLine)) {
         //_CW_clearCommentState();
         //CW_analyzeBlockComment(startPos, endPos, commentType, inDoEditKey);
      }
   }
   //save more state
   CW_startPos = startPos;
   CW_endPos = endPos;
   CW_commentType = commentType;
   return (commentType);
}

/**
 * Checks to see if we are in the first word of the content of the current
 * comment line. 
 * 
 * @param startLine     Line number of start of comment
 * @param endLine       Line number of end of comment
 * @param testFromCol   start looking from this column
 * 
 * @return boolean   True if cursor is positioned before the
 *         second whitespace delimited word in the current line.
 */
static boolean CW_inLineFirstWord(int startLine, int endLine, int testFromCol = 0) {

   int currentLMC = 0; int currentRMC = 0; int afterBulletCol = 0;
   _str currentLine = '';
   currentLMC = CW_extractBCLineText(currentLine, startLine, endLine, currentRMC, afterBulletCol);
   if (!currentLMC) {
      return (false);
   }
   boolean returnVal = false;
   if (!testFromCol) {
      testFromCol = currentLMC + afterBulletCol - 1;      
      // move to start of real content
   }
   int secondWordStart = verify(CW_currentLine, " \t", "M", text_col(CW_currentLine, testFromCol, 'P'));
   if (!secondWordStart) {
      //Content is all just one word
      secondWordStart = text_col(CW_currentLine, length(CW_currentLine), 'I');
   } else {
      secondWordStart = verify(CW_currentLine, " \t", "", secondWordStart);
      if (!secondWordStart) {
         //No second word to move up to
         secondWordStart = text_col(CW_currentLine, length(CW_currentLine), 'I');
      } else {
         secondWordStart = text_col(CW_currentLine, secondWordStart, 'I');
      }
   }
   
   returnVal = (secondWordStart >= p_col);
   return (returnVal);
}

/**
 * Will try to merge next line of comment into current comment line if first 
 * word of next line will fit on current line.   Then it will reflow the 
 * paragraph to insure that the merge did not make any lines too long.
 * 
 * @param startLine  Line number of start of comment
 * @param endLine    Line number of end of comemnt
 */
static void CW_maybeMergeAndReflow(int startLine, int &endLine, int fromLine = -1, boolean skipMergeWithPrevious = false) {

   typeless p; save_pos(p);
   if (fromLine == -1) {
      fromLine = p_line;
   }
   //Check that fromLine is not imaginary
   p_line = fromLine;
   if (_lineflags() & NOSAVE_LF) {
      restore_pos(p);
      return;
   }
   restore_pos(p);

   int absRightMargin = CW_getRightMargin();
   if (absRightMargin == 0 || CW_inJavadocScriptTag) {
      //Do nothing.  Either can't determine right margin or content can not fit
      //or shouldn't wrap when in script tag.
      return;
   }
   int mergeLine = fromLine;
   int reflowLine = fromLine;
   if (!skipMergeWithPrevious && p_line == fromLine && CW_inLineFirstWord(startLine, endLine) && !CW_isParaStart(CW_commentType, startLine, endLine, fromLine)) {
      decrementRealLineCounter(mergeLine);
   }
   int mergeUpAgain = 1; //Initialize to 1 so we try to merge up at least the first time
   for (;mergeUpAgain > 0; incrementRealLineCounter(mergeLine)) {
      for (mergeUpAgain = 0; CW_maybeMerge(mergeLine, startLine, endLine); mergeUpAgain++) {
         }
   }
   if (reflowLine <= endLine) 
      for (;CW_REFLOWED == CW_maybeReflowToNext(reflowLine, startLine, endLine, absRightMargin); incrementRealLineCounter(reflowLine)) {
            }

}

/**
 * Given a line number, increments it to the next real line.
 * 
 * @param counter [in out] int holding line number to increment to the next real
 *                line number.
 */
void incrementRealLineCounter(int& counter) {
   typeless p; save_pos(p);
   p_line = counter;
   CW_down(); //should be safe to call, counter is never last line of file
   counter = p_line;
   restore_pos(p);
}
/**
 * Given a line number, decrements it to the next real line.
 * 
 * @param counter [in out] int holding line number to decrement to the next real
 *                line number.
 */
/*static*/ void decrementRealLineCounter(int& counter) {
   typeless p; save_pos(p);
   p_line = counter;
   CW_up();
   counter = p_line;
   restore_pos(p);
}
 
/**
 * Will try to merge next line of comment into current comment line if first 
 * word of next line will fit on current line.
 * 
 * @param fromLine   Line number of line that may get text from following line
 * @param startLine  Line number of start of comment
 * @param endLine    Line number of end of comemnt
 * @return boolean   True if some content was moved up from next line
 */
static boolean CW_maybeMerge(int fromLine, int startLine, int &endLine, int spacesAtEnd = 1) {
   typeless p; save_pos(p);
   int origLine = p_line, origCol = p_col;
   int origRLine = p_RLine;
   p_line = fromLine;
   int fromRLine = p_RLine;
   p_line = origLine;
   //May need to fix cursor position in two cases
   //When cursor starts on line from which we pull text, or
   //when after that line and a line is deleted, the cursor moves up a line
   boolean needToFixCursor = (p_RLine == fromRLine + 1);
   boolean needToFixCursor2 = (p_RLine > fromRLine + 1);
   if ((fromLine >= endLine) || (CW_inJavadocScriptTag)) {
      //At end of comment, no next line.
      return(false);
   }

   boolean watchCursor = (p_RLine == fromRLine);

   int absRightMargin = CW_getRightMargin();
   if (absRightMargin == 0) {
      //Do nothing.  Either can't determine right margin or content can not fit.
      return(false);
   }

   int rightMostContentCol = absRightMargin - length(CW_thisLineEndBorder(startLine,endLine));
   int currentLMC = 0, nextLMC = 0;
   int nextRMC, RMC1 = 0;
   int CafterBulletCol = 0;
   _str currentLine, nextLine;

   //Move to line that may be appended from below
   p_line = fromLine;
   //Check that this is not an imaginary line

   currentLMC = CW_extractBCLineText(currentLine, startLine, endLine, RMC1, CafterBulletCol);
   int remainingOpenColumns = rightMostContentCol - RMC1 + spacesAtEnd;
   if (watchCursor && p_col - 2 > RMC1) {
      RMC1 = p_col - 2;
   }
   if ((remainingOpenColumns < 1) || CW_down()) {
      restore_pos(p);
      return(false);
   }

   if (CW_isBCBlankLine(startLine,endLine)) {
      //Do nothing if next is a blank line
      restore_pos(p);
      return(false);
   }
   if (CW_isParaStart(CW_commentType, startLine, endLine)) {
      //Do nothing if next line is a paragraph start
      restore_pos(p);
      return(false);
   }
   nextLMC = CW_extractBCLineText(nextLine, startLine, endLine, nextRMC, CafterBulletCol);
   int nextLMCP1, pcolP;

   nextLMCP1 = text_col(CW_currentLine, nextLMC, 'P');
   pcolP = text_col(CW_currentLine, origCol, 'P');

   p_line = fromLine;
   _str pulledText = substr(' ', 1, RMC1 + spacesAtEnd) :+ nextLine;
   if (length(pulledText) <= rightMostContentCol) {
      pulledText = substr(pulledText, 1, rightMostContentCol + 1);
   }
   int searchStart = text_col(pulledText, rightMostContentCol, 'P');
   //Find end of word
   int status = lastpos("[^ \t][ \t]", pulledText, searchStart, 'U');
   if (status <= RMC1 + spacesAtEnd) {    //No word from next line will fit
      p_line = origLine; p_col = origCol;    
      return(false);
   }
   status -= RMC1 + spacesAtEnd;
   pulledText = substr(nextLine, 1, status);
   //We can pull something up
   //Add pulled text to current line

   p_line = fromLine;
   int insertLocation = RMC1+ spacesAtEnd + 1;
   p_col = insertLocation - spacesAtEnd; _delete_end_line();
   _insert_text_raw(substr('', 1, spacesAtEnd, ' ') :+ pulledText);

   CW_down(); //safe, can not be on last line
   //Two cases, part of the next line or entire next line.
   boolean pulledUpWholeLine = (pulledText == nextLine);
   if (pulledUpWholeLine) { //entire line pulled up.
      if (p_line == endLine) {
      }
      _delete_line(); endLine--;
      p_line = fromLine;         
      if (needToFixCursor2) {
         decrementRealLineCounter(origLine);
      }
      if (needToFixCursor) {
         decrementRealLineCounter(origLine);
         p_line = origLine;
         _str tempLine;get_line_raw(tempLine);
         origCol = text_col(tempLine, text_col(tempLine, insertLocation, 'P') + pcolP - nextLMCP1, 'I');
      }

   } else {   //Part of line pulled up
      _str nextLine2 = ' ';
      int nextLMCP = 0, cursorP = 0, cursorPOffset = 0;;
      if (needToFixCursor) {
         //Cursor is on line from which we are pulling text, save physical location of key points
         get_line_raw(nextLine2);
         nextLMCP = text_col(nextLine2, nextLMC, 'P');
         cursorP = text_col(nextLine2, origCol, 'P');
         cursorPOffset = cursorP - nextLMCP + 1;
      }
      int secondWordColP = verify(nextLine, " \t", '', length(pulledText) + 1);
      if (!secondWordColP) {
         //Should not happen.  Log an error
      }
      //nextLine = strip(substr(nextLine, length(pulledText) + 1), 'L');
      nextLine = substr(nextLine, secondWordColP);
      //Have to be very careful of how to adjust the cursor location in case
      //user is exanding with tabs.
      _str tempLine = substr('', 1, nextLMC - 1) :+ nextLine;
      int yankCol = text_col(tempLine, nextLMC + secondWordColP - 1, 'I');

      //Pull out what is moved to next line, leaving trailing border intact.
      p_col = nextLMC;
      _delete_text(yankCol - nextLMC, 'C');

      if (needToFixCursor) {
         _str newLine; get_line_raw(newLine);
         int newLMCP = text_col(newLine, nextLMC, 'P');
         //Two cases, cursor after pulled portion and cursor in pulled portion 
         if (cursorPOffset >= secondWordColP) {
            //cursor after pulled portion
            origCol = text_col(newLine, newLMCP + (cursorPOffset - secondWordColP), 'I');
         } else if (cursorP >= nextLMCP) {
            decrementRealLineCounter(origLine);
            p_line = origLine;
            get_line_raw(newLine);
            int insertCursorP = text_col(newLine, insertLocation, 'P') + (cursorP - nextLMCP);
            origCol = text_col(newLine, insertCursorP, 'I');
         }
      }
   }
   //OrigLine and OrigCol now have been adjusted to new cursor location.

   p_line = fromLine; p_col = origCol;
   CW_fixBorders(startLine,endLine,absRightMargin, (p_line == origLine), pulledUpWholeLine ? 1 : 0);  
   //in case above call has to move the cursor to fix the borders
   if (p_line == origLine) {
      origCol = p_col;
   }
   if (!pulledUpWholeLine) {
      p_line = fromLine; CW_down(); p_col = origCol;
      CW_fixBorders(startLine,endLine,absRightMargin, (p_line == origLine));
   }
   //Reset to original.  Original values have been updated in case cursor must move
   p_line = origLine; p_col = origCol;
   //To cover the case where pulling up the whole content from end line may now be too long
   if (pulledUpWholeLine && fromLine == endLine) {
      int statusReflow = CW_maybeReflowToNext(fromLine, startLine, endLine, absRightMargin);
      if (statusReflow == CW_REFLOWED) return false;
   }

   // we did something, so let's tell the user about it
   CW_commentwrap_nag();

   return(true);
}

void maybeOpenHiddenLines(int origLine, int origCol) {
   //Need to check if we are on a hidden line.  If so, show the hidden lines
   if (_lineflags() & HIDDEN_LF) {
      int flags = _lineflags();
      int show_level = flags & LEVEL_LF;
      while (true) {
         flags = _lineflags();
         int level = flags&LEVEL_LF;
         if (level < show_level) {
            if (flags & PLUSBITMAP_LF) {
               plusminus();
            }
            break;
         }
         if ( up() ) break;
      }
      p_line = origLine; p_col = origCol;
   }
}

/**
 * 
 * @param returnStr      Stripped content of the current comment line
 * @param startLine      start line of comment
 * @param endLine        end line of comment
 * @param rightMostCol   screen column of last content text
 * @param bulletOffset   If a bullet appears on the line,
 *                       This is the offset in string coords
 *                       to content after the bullet
 * @param skipGetLine    If true, skip reloading the line 
 *                       contents and use cached value in
 *                       CW_currentLine.
 * 
 * @return int           Screen column of the first character of 
 *                       content.  0 if no content
 */
static int CW_extractBCLineText(_str &returnStr, int startLine, int endLine, int &rightMostCol, int &bulletOffset, boolean skipGetLine = false) {
   if (CW_commentType == CW_JAVADOCCOMMENT) {
      return CW_extractJavadocText(returnStr, startLine, endLine, rightMostCol, bulletOffset, skipGetLine);
   }
   rightMostCol = 1;
   if ((startLine == p_line) && (endLine == p_line)) {
      return CW_extractBCLineText3(returnStr, CW_commentSettings.tlc, CW_commentSettings.brc, rightMostCol, bulletOffset, skipGetLine);
   }
   if (startLine == p_line) {
      return CW_extractBCLineText3(returnStr, CW_commentSettings.tlc, CW_commentSettings.trc, rightMostCol, bulletOffset, skipGetLine);
   }
   if (endLine == p_line) {
      return CW_extractBCLineText3(returnStr, CW_commentSettings.blc, CW_commentSettings.brc, rightMostCol, bulletOffset, skipGetLine);
   }
   return CW_extractBCLineText3(returnStr, CW_commentSettings.lvside, CW_commentSettings.rvside, rightMostCol, bulletOffset, skipGetLine);
}


static int CW_extractJavadocText(_str &returnStr, int startLine, int endLine, int &rightMostCol, int &bulletOffset, boolean skipGetLine = false) {
   rightMostCol = 0;
   bulletOffset = 1;
   if ((startLine == p_line) && (endLine == p_line)) {
      return CW_extractBCLineText3(returnStr, CW_commentSettings.tlc, CW_commentSettings.brc, rightMostCol, bulletOffset, skipGetLine);
   }
   if (startLine == p_line) {
      return CW_extractBCLineText3(returnStr, CW_commentSettings.tlc, CW_commentSettings.trc, rightMostCol, bulletOffset, skipGetLine);
   }
   _str line; get_line_raw(line);
    CW_currentLine = line = strip(line, 'T');
   if ((endLine == p_line) && (length(line) > 1) && (substr(line, length(line) - 1) :== '*/')){
      line = strip(substr(line, 1, length(line) - 2), 'T');
   }
   int fullLen = length(line);
   rightMostCol = text_col(line, fullLen, 'I');
   returnStr = strip(strip(strip(line), 'L', '*'));
   if (returnStr == '') {
      rightMostCol = 0; return(0);
   }
   int returnVal =  text_col(line, fullLen - length(returnStr) + 1, 'I');
   //Move past bullet here
   bulletOffset = 1;
   //Bullet search
   if (pos(CW_commentBulletTags, returnStr, 1, 'U')) {
      bulletOffset += pos('');
      return (returnVal);
   }
   if (_GetCommentWrapFlags(CW_JAVADOC_AUTO_INDENT, CW_p_LangId)) {
      if (pos(CW_javadocBlockTags2, returnStr, 1, 'U')) {
         bulletOffset += pos('');
         return(returnVal);
      }
      if (pos(CW_docCommentTags, returnStr, 1, 'U')) {
         bulletOffset += pos('');
         return(returnVal);
      }
   }
   return (returnVal);
}

/**
 * 
 * @param returnStr      Stripped content of the current comment line.
 * @param startLine      start line of comment
 * @param endLine        end line of comment
 * @param rightMostCol   screen content of last content text
 * @param bulletOffset   If a bullet appears on the line,
 *                       This is the offset in string coords
 *                       to content after the bullet
 * @param skipGetLine    If true, skip reloading the line 
 *                       contents and use cached value in
 *                       CW_currentLine.
 * 
 * @return int           Screen column of the first character of 
 *                       content
 * 
 * @return int Return 0 if there is no content (e.g. a blank line with only borders).
 */
static int CW_extractBCLineText3(_str &returnStr, _str head, _str tail, int &rightMostCol, int &bulletOffset, boolean skipGetLine = false) {
   int returnVal = 1;
   returnStr = '';
   _str line; 
   if (skipGetLine) {
      line = CW_currentLine;
   } else {
      //cache the read in line
      get_line_raw(line); CW_currentLine = line = strip(line, 'T');
   }
   head = strip(head);
   tail = strip(tail);
   int lengthTail = length(tail);
   int lengthHead = length(head);
   int lengthLine = length(line);
   //If end matches tail string, strip off
   if (lengthLine >= lengthTail && lengthTail > 0) {
      _str tailEnd = substr(line, lengthLine - lengthTail + 1);
      if (tailEnd :== tail) {
         line = strip(substr(line, 1, lengthLine - lengthTail), 'T');
      }
   }
   //Case of no content after removing tail string
   if (!length(line)) {
      returnVal = 0; rightMostCol = 0;
      returnStr = '';
      return (returnVal);
   }
   rightMostCol = text_col(line, length(line), 'I');

   //index of first non blank
   int contentCol = verify(line, " \t");
   //Do we match the lead in string (left border)
   //If so, move contentCol marker past lead-in string
   if (substr(line, contentCol, lengthHead) :== head) {
      contentCol += lengthHead;
   }
   //Move again to next non-blank.  Start on the real content
   contentCol = verify(line' ', " \t", '', contentCol);
   if (!contentCol) {
      returnVal = 0;
      returnStr = '';
      return (returnVal);
   }

   returnVal = text_col(line, contentCol, 'I');
   returnStr = substr(line, contentCol);

   //Move past bullet here
   bulletOffset = 1;
   //Bullet search
   if (pos(CW_commentBulletTags, returnStr, 1, 'U')) {
      bulletOffset += pos('');
      return (returnVal);
   }

   //Numbered paragraph search
/*
    if (pos(CW_commentNumberTags, returnStr, 1, 'U')) {
       _str numBullet = substr(returnStr, pos('S'), pos(''));
       numBullet = CW_processNumberBullet(numBullet);
       bulletOffset += length(numBullet);
       return (returnVal);
    }
*/

   if (CW_commentType == CW_JAVADOCCOMMENT && _GetCommentWrapFlags(CW_JAVADOC_AUTO_INDENT, CW_p_LangId)) {
      if (pos(CW_javadocBlockTags2, returnStr, 1, 'U')) {
         bulletOffset += pos('');
         return(returnVal);
      }
      if (pos(CW_docCommentTags, returnStr, 1, 'U')) {
         bulletOffset += pos('');
         return(returnVal);
      }
   }


   return(returnVal);
}
/**
 * 
 * @param returnStr      Stripped content of the current comment line.
 * @param startLine      start line of comment
 * @param endLine        end line of comment
 * @param rightMostCol   screen content of last content text
 * @param bulletOffset   If a bullet appears on the line,
 *                       This is the offset in string coords
 *                       to content after the bullet
 * @param skipGetLine    If true, skip reloading the line 
 *                       contents and use cached value in
 *                       CW_currentLine.
 * 
 * @return int           Screen column of the first character of 
 *                       content
 * 
 * @return int Return 0 if there is no content (e.g. a blank line with only borders).
 */
static int CW_extractBCLineText1(_str &returnStr, _str head, _str tail, int &rightMostCol, int &bulletOffset, boolean skipGetLine = false) {
   int returnVal = 1;
   returnStr = '';
   _str line; 
   if (skipGetLine) {
      line = CW_currentLine;
   } else {
      //cache the read in line
      get_line_raw(line); CW_currentLine = line = strip(line, 'T');
   }
   head = strip(head);
   tail = strip(tail);
   int lengthTail = length(tail);
   int lengthHead = length(head);
   int lengthLine = length(line);
   //If end matches tail string, strip off
   if (lengthLine >= lengthTail && lengthTail > 0) {
      _str tailEnd = substr(line, lengthLine - lengthTail + 1);
      if (tailEnd :== tail) {
         line = strip(substr(line, 1, lengthLine - lengthTail), 'T');
      }
   }
   //Case of no content after removing tail string
   if (!length(line)) {
      returnVal = 0; rightMostCol = 0;
      returnStr = '';
      return (returnVal);
   }
   rightMostCol = text_col(line, length(line), 'I');

   //index of first non blank
   int contentCol = verify(line, " \t");
   //Do we match the lead in string (left border)
   //If so, move contentCol marker past lead-in string
   if (substr(line, contentCol, lengthHead) :== head) {
      contentCol += lengthHead;
   }
   //Move again to next non-blank.  Start on the real content
   contentCol = verify(line' ', " \t", '', contentCol);
   if (!contentCol) {
      returnVal = 0;
      returnStr = '';
      return (returnVal);
   }

   returnVal = text_col(line, contentCol, 'I');
   returnStr = substr(line, contentCol);

   //Move past bullet here
   bulletOffset = 1;
   //Bullet search
   if (pos(CW_commentBulletTags, returnStr, 1, 'U')) {
      bulletOffset += pos('');
      return (returnVal);
   }

   //Numbered paragraph search
/*
    if (pos(CW_commentNumberTags, returnStr, 1, 'U')) {
       _str numBullet = substr(returnStr, pos('S'), pos(''));
       numBullet = CW_processNumberBullet(numBullet);
       bulletOffset += length(numBullet);
       return (returnVal);
    }
*/

   if (CW_commentType == CW_JAVADOCCOMMENT && _GetCommentWrapFlags(CW_JAVADOC_AUTO_INDENT, CW_p_LangId)) {
      if (pos(CW_javadocBlockTags2, returnStr, 1, 'U')) {
         bulletOffset += pos('');
         return(returnVal);
      }
   }


   return(returnVal);
}

static _str CW_processNumberBullet(_str inputNumBullet) {
   return (inputNumBullet);
}

/**
 * Get right hand border setting for specified line in current block comment.
 * 
 * @param startLine  Line number of start of comment
 * @param endLine    Line number of end of comment
 * @param thisLine   Line number of line to retrieve RHS border sequence
 * 
 * @return _str
 */
static _str CW_thisLineEndBorder(int startLine, int endLine, int thisLine = p_line) {
   if (thisLine == endLine) {
      return CW_commentSettings.brc;
   }
   if (thisLine == startLine) {
      return CW_commentSettings.trc;
   }
   if (startLine < thisLine && thisLine < endLine) {
      return CW_commentSettings.rvside;
   }
   return '';
}
/**
 * Get left hand border setting for specified line in current block comment.
 * 
 * @param startLine  Line number of start of comment
 * @param endLine    Line number of end of comment
 * @param thisLine   Line number of line to retrieve LHS border sequence
 * 
 * @return _str
 */
static _str CW_thisLineStartBorder(int startLine, int endLine, int thisLine = p_line) {
   if (thisLine == startLine) {
      return CW_commentSettings.tlc;
   }
   if (thisLine == endLine) {
      return CW_commentSettings.blc;
   }
   if (startLine < thisLine && thisLine < endLine) {
      return CW_commentSettings.lvside;
   }
   return '';
}

   //Heavy weight process to fix the borders
static void CW_fixBorders(int startLine, int endLine, int absoluteRight, boolean useCursor = true, int endLineIncrement = 0) {

   //Heavy weight process to fix the borders
   _str currentLine = '';
   int currentLMC = 0;
   int currentRMC = 0;
   int CafterBulletCol = 0;
   int originalCol = p_col;
   //Examine current line
   currentLMC = CW_extractBCLineText(currentLine, startLine, endLine + endLineIncrement, currentRMC, CafterBulletCol);
   //On a blank line, insert nothing at the current cursor position.
   if (currentLMC == 0) {
      currentLMC = p_col;
   }
   if (p_line == endLine) {
      CW_fixBorders2(startLine, endLine, absoluteRight, currentLine, currentLMC, useCursor);
      return;
   }
   //Can now do this and just use CW_fixBorders2
   CW_fixBorders2(startLine, endLine, absoluteRight, currentLine, currentLMC, useCursor);
   return;
}


/**
 * Lighter weight process to fix the borders.  If content is too long,
 * any right border will still be drawn at end of content.
 * 
 * @param startLine
 * @param endLine
 * @param absoluteRight
 * @param currentLine       content that should be in the line
 * @param currentLMC        start column for the content
 * @param endLineIncrement  Unused.
 */
static void CW_fixBorders2(int startLine, int endLine, int absoluteRight, _str currentLine, int currentLMC, boolean useCursor = true) {

   //Lighter weight process to fix the borders
   _str leftBorder = CW_thisLineStartBorder(startLine, endLine);
   _str rightBorder = CW_thisLineEndBorder(startLine, endLine);
   //Blank line, no content.  So set to current cursor position so that
   //cursor will be preserved properly

   //This section attempts to prevent the final '*/' from being pushed out to the 
   //right margin when it shouldn't
   if (p_line == endLine &&  (CW_commentSettings.rvside == '' || (true && startLine == endLine))) {

      if (CW_commentType == CW_JAVADOCCOMMENT && p_line != startLine && !useCursor && currentLine == '') {
         leftBorder = '';
      }
      int reducedAbsoluteRight = 0;
      _str line; get_line_raw(line);
      line = strip(_expand_tabsc(), 'T');
      int LRM = length(line);
      if ((length(line) >= length(rightBorder)) && substr(line, length(line) - length(rightBorder) + 1) :== rightBorder) {
         reducedAbsoluteRight = LRM;
      } else {
         if (LRM == 0 || (CW_commentType == CW_JAVADOCCOMMENT &&  strip(strip(line), 'L', '*') == '')) {
            reducedAbsoluteRight = CW_commentBorderLeftCol + length(rightBorder) - 1;
         } else
            reducedAbsoluteRight = LRM + length(rightBorder);
      }
      if (p_col + length(rightBorder) - 1 > reducedAbsoluteRight && useCursor) {
         reducedAbsoluteRight = p_col + length(rightBorder) - 1;
      }
      if (reducedAbsoluteRight < absoluteRight) {
         absoluteRight = reducedAbsoluteRight;
      }
   }

   int origCol = p_col;
   if (currentLMC == 0) {
      currentLMC = CW_commentBorderLeftCol;
   }
   //Content may shift if the left borders are different lengths
   int contentShift = CW_commentBorderLeftCol + length(leftBorder) - currentLMC;
   //Never shift the content left
   if (true || contentShift < 0) {
      contentShift = 0;
   }
   replace_line(indent_string(CW_commentBorderLeftCol));
   p_col = CW_commentBorderLeftCol;
   if ((p_line == endLine && currentLine :== '' && CW_commentType == CW_JAVADOCCOMMENT) && absoluteRight == CW_commentBorderLeftCol + length(rightBorder) - 1) {
      
   } else {
      _insert_text_raw(leftBorder);
   }
   p_col = currentLMC + contentShift;
   _insert_text_raw(strip(currentLine, 'T'));
   int rightBorderStartCol = absoluteRight - length(rightBorder) + 1;
   if (p_col > rightBorderStartCol) {
      rightBorderStartCol = p_col;
   }
   p_col = rightBorderStartCol; _insert_text_raw(rightBorder);
   if (useCursor) {
      p_col = origCol + contentShift;
   }
}

/**
 *  Will reflow a comment line if too long for current settings.
 * 
 *  If current line is too long a portion of it will be cut and 
 *  moved to the next line.  If the next line is a paragraph 
 *  start or a blank line, a new line will be insertedfirst.
 * 
 * This will only reflow one line.  If the next line is also too 
 * long, function will need to be called again.  Perserves
 * cursor location.
 * 
 * @param lineNumber    Number of line to check
 * @param startLine     start line of comment
 * @param endLine       end line od comment
 * @param absoluteRight Right most edge of comment, including 
 *                      any border
 * 
 * @return int  CW_REFLOWED if any wrapping was performed.
 *         CW_NONEEDTOREFLOW if no need to reflow.
 *         CW_CANNOTREFLOW if unable to reflow.
 */
static int CW_maybeReflowToNext(int lineNumber, int startLine, int &endLine, int absoluteRight) {

   _str currentLine = '', nextLine = '';
   int currentLMC = 0, currentRMC = 0;
   int nextLMC = 0, nextRMC = 0;
   int CafterBulletCol = 1, NafterBulletCol = 1;

   int origLine = p_line; int origRLine = p_RLine; int origCol = p_col;
   typeless p; save_pos(p);
   p_line = lineNumber;

   //Examine current line
   currentLMC = CW_extractBCLineText(currentLine, startLine, endLine, currentRMC, CafterBulletCol);
   //Store current line without left or right border.
   _str CW_currentLine2 = substr('', 1, currentLMC - 1);
   strappend(CW_currentLine2, currentLine);

   //Do we really need to wrap?
   _str thisLineEndBorder = CW_thisLineEndBorder(startLine, endLine);
   int lastPossibleContentCol = absoluteRight - length(thisLineEndBorder);
   if (lastPossibleContentCol <= CW_commentBorderLeftCol + length(CW_thisLineStartBorder(startLine,endLine))) {
      message(CW_CANNOT_FORMAT_MESSAGE);
      restore_pos(p);
      return(CW_CANNOTREFLOW);
   }
   boolean spacedOffEnd = false;
   if ((origLine == lineNumber) && (currentRMC <= lastPossibleContentCol) && (origCol > lastPossibleContentCol + 1)) {
      spacedOffEnd = true;
   }
   if ((currentRMC <= lastPossibleContentCol && !spacedOffEnd) || (CW_inJavadocScriptTag)) {
      if (length(thisLineEndBorder) == 0 && (!CW_inJavadocScriptTag)) {
         //Just trim any extra trailing spaces that go past right border
         p_col = lastPossibleContentCol + 1;
         _delete_end_line();
      } else {
         //No, just fix right border
         CW_fixBorders2(startLine, endLine, absoluteRight, currentLine, (currentLMC == 0 ? p_col : currentLMC), p_line == origLine);
      }
      restore_pos(p);
      return(CW_NONEEDTOREFLOW);
   }

   // Search for place to break the current line.
   int physHardRight = text_col(CW_currentLine2, absoluteRight - length(CW_thisLineEndBorder(startLine, endLine)), 'P');
   int physBreakCol = lastpos('[^ \t][ \t]', CW_currentLine2, physHardRight, 'U');
   //By searching backwards for the end of a word, this should prevent finding case
   //of trying to push the entire line down.  If searching for start of word, could
   //try to push whole line if it consisted of just one long word.
   if (!physBreakCol) {
      //Couldn't find a good break point that would be within the right margin
      //so still try to break this line somewhere.
      int i, pBC = 0;
      for (i = physHardRight; i < length(CW_currentLine2); i++) {
         pBC = lastpos('[^ \t][ \t]', CW_currentLine2, i, 'U');
         if (pBC) {
            physBreakCol = pBC;
            message(CW_CANNOT_FORMAT_MESSAGE2);
            break;
         }
      }
      if (pBC == 0) {
         message(CW_CANNOT_FORMAT_MESSAGE);
         restore_pos(p);
         return (CW_CANNOTREFLOW);
      }
   }
   physBreakCol++;
   //_str wrapPortion = substr(CW_currentLine2, physBreakCol);
   //Find start of the next word.  That is what should be pushed to next line
   int physBreakCol2 = verify(CW_currentLine2, " \t", "", physBreakCol);
   if (!physBreakCol2 && !spacedOffEnd) {
      //This should not happen because there must have been content to trigger the reflow
      message(CW_CANNOT_FORMAT_MESSAGE);
      restore_pos(p);
      return (CW_CANNOTREFLOW);
   }
   if (spacedOffEnd) {
      physBreakCol2 = text_col(CW_currentLine2, origCol, 'P') - 1;
   }

   _str wrapPortion = substr(CW_currentLine2, physBreakCol2);

   //Get imaginary position to cut the line string
   int cutColI = text_col(CW_currentLine2, physBreakCol2, 'I');

   //Delete text that will be wrapped
   p_col = cutColI;
   _delete_end_line();

   //Check if we need to insert a line.  This happens at end of paragraph
   boolean isEndPara = (p_line == endLine);
   isEndPara = isEndPara || ((p_line + 1 == endLine) && !CW_commentSettings.lastline_is_bottom);
   if (!isEndPara) {
      //Safe to move down since we are not at end line of comment
      //Move down and examine line
      CW_down();
      nextLMC = CW_extractBCLineText(nextLine, startLine, endLine, nextRMC, NafterBulletCol);
      //Check blank line
      isEndPara = isEndPara || (nextLMC == 0);
      //Check found bullet
      isEndPara = isEndPara || (NafterBulletCol > 1);
      //Check different indent
      boolean differentIndent = (currentLMC + CafterBulletCol - 1 != nextLMC);
      if (differentIndent) {
         //Only accept a different indent as start of new paragraph if does not
         //immediately follow the start of a paragraph.  This should allow hanging
         //indents.
         CW_up();
         differentIndent = !CW_isParaStart(CW_commentType, startLine, endLine);
         CW_down();
         //Don't allow indent to break paragraph if typing whitespace at start of content
         if (currentLMC == origCol) {
            differentIndent = false;
         }
      }
      isEndPara = isEndPara || (differentIndent);
      //Check for other paragraph starting tags.
      if (!isEndPara) {
         //skip checking indent, since we've taken care of that above
         isEndPara = isEndPara || CW_isParaStart(CW_commentType, startLine, endLine, p_line, true);
      }
      CW_up();
   }
   if (isEndPara) {
      endLine++;
   }

   if (isEndPara) { 
      //Need to add a new line
      nextLMC = currentLMC + CafterBulletCol - 1;
      if (!CW_down()) up();
      insert_line(indent_string(currentLMC + CafterBulletCol - 2));
      //p_col = currentLMC + CafterBulletCol - 1;
      _insert_text_raw(wrapPortion);
   } else {
      //Wrap to front of content on the next line
      CW_down();
      p_col = nextLMC;
      //wrap portion may be nothing when we've spaced past the right border, so
      //strip the leading whitespace of (wrapPortion' ')
      wrapPortion = strip(wrapPortion' ', 'L');
      _insert_text_raw(wrapPortion);
   }
   //Fix the location of the cursor to proper place
   if (spacedOffEnd) {
      p_col = nextLMC;
   }
   else if ((origRLine == p_RLine - 1) && (cutColI <= origCol)) {
      //Case that cursor was in portion that was moved to next line
      p_col = nextLMC - (cutColI - origCol);
   }
   else if (origLine == p_line) {
      //Case that cursor was originally on line that received the text from previous line
      p_line = origLine;
      p_col = origCol + length(wrapPortion);
   }
   else {
      //Case that cursor started on line unaffected by wrap.
      p_line = origLine; p_col = origCol;
   }
   //Save adjusted end location 03/22/06
   origLine = p_line; origCol = p_col;

   //Fix right border on lineNumber line
   p_line = lineNumber; p_col = origCol;
   CW_fixBorders(startLine, endLine, absoluteRight, (p_line == origLine), isEndPara ? -1 : 0);
   //Heavy weight fix of wrap destination line border characters
   p_line = lineNumber + 1; p_col = origCol;
   CW_fixBorders(startLine, endLine, absoluteRight, (p_line == origLine), isEndPara ? -1 : 0);

   p_line = origLine; p_col = origCol;

   // we did something, so let's tell the user about it
   CW_commentwrap_nag();

   return (CW_REFLOWED);
}



/**
 * Read comment settings from the Comment Settings Tab extensions box
 * 
 * @param commentSettings Structure in which to store the 
 *                        settings
 * 
 * @return boolean  True if able to retieve and store the 
 *                  settings.
 */
static boolean CW_getCommentSettings(BlockCommentSettings_t &commentSettings) {
   BlockCommentSettings_t settings:[];
   _str lang = CW_p_LangId;
   if (getCommentSettings( lang, settings, 'b')) {
      message('No comments setup for this file.');
      return (false);
   }

   commentSettings = settings:[lang];
   if (p_xlat) {
      commentSettings.tlc=_UTF8ToMultiByte(commentSettings.tlc);
      commentSettings.trc=_UTF8ToMultiByte(commentSettings.trc);
      commentSettings.blc=_UTF8ToMultiByte(commentSettings.blc);
      commentSettings.brc=_UTF8ToMultiByte(commentSettings.brc);
      commentSettings.bhside=_UTF8ToMultiByte(commentSettings.bhside);
      commentSettings.thside=_UTF8ToMultiByte(commentSettings.thside);
      commentSettings.lvside=_UTF8ToMultiByte(commentSettings.lvside);
      commentSettings.rvside=_UTF8ToMultiByte(commentSettings.rvside);
      commentSettings.comment_left=_UTF8ToMultiByte(commentSettings.comment_left);
      commentSettings.comment_right=_UTF8ToMultiByte(commentSettings.comment_right);
   }
   commentSettings.bhside=strip(substr(strip(commentSettings.bhside), 1, 1));
   commentSettings.thside=strip(substr(strip(commentSettings.thside), 1, 1));
   commentSettings.comment_left=strip(commentSettings.comment_left);
   commentSettings.comment_right=strip(commentSettings.comment_right);

   //Correct case of end string being stored in LCL box instead
   if (commentSettings.brc == '' && commentSettings.blc != '') {
      commentSettings.brc = commentSettings.blc;
      commentSettings.blc = '';
   }
   //Correct case of both bottom corners being empty
   if (commentSettings.brc == '' && commentSettings.blc == '') {
      commentSettings.brc = CW_commentBRCstr;
   }
   //Correct case of TLC being empty
   if (commentSettings.tlc == '') {
      commentSettings.tlc = CW_commentTLCstr;
   }

   if (commentSettings.firstline_is_top) {
      commentSettings.thside = '';
   }
   if (commentSettings.lastline_is_bottom) {
      commentSettings.bhside = '';
   }

   //Check that beginning and end sequence really match what color
   //coding sequence is used to delimit this block comment.
   if (CW_commentTLCstr != substr(strip(commentSettings.tlc), 1, length(CW_commentTLCstr))) {
      //say(CW_commentTLCstr);
      //commentSettings.tlc = CW_commentTLCstr :+ commentSettings.tlc;
   }
   if (length(strip(commentSettings.brc)) >= length(CW_commentBRCstr) && CW_commentBRCstr != substr(strip(commentSettings.brc), length(strip(commentSettings.brc)) - length(CW_commentBRCstr) + 1, length(CW_commentBRCstr))) {
      commentSettings.brc = commentSettings.brc :+ CW_commentBRCstr;
   }

   //Pad right borders to same width if they are not just blanks
   int rBorderWidthTop = length(strip(CW_commentSettings.trc, 'T'));
   int rBorderWidthMiddle = length(strip(CW_commentSettings.rvside, 'T'));
   int rBorderWidthBottom = length(strip(CW_commentSettings.brc, 'T'));
   int rBorderWidth = (rBorderWidthTop > rBorderWidthMiddle) ? rBorderWidthTop : rBorderWidthMiddle;
   rBorderWidth = (rBorderWidth > rBorderWidthBottom) ? rBorderWidth : rBorderWidthBottom;
   if (rBorderWidthTop) CW_commentSettings.trc = substr(CW_commentSettings.trc, 1, rBorderWidth);
   if (rBorderWidthMiddle) CW_commentSettings.rvside = substr(CW_commentSettings.rvside, 1, rBorderWidth);
   if (rBorderWidthBottom) CW_commentSettings.brc = substr(CW_commentSettings.brc, 1, rBorderWidth);

   //Clear any inner borders that are just blanks
   if (strip(CW_commentSettings.thside) == '') {
      CW_commentSettings.thside = '';
   }
//    if (strip(CW_commentSettings.trc) == '') {
//       CW_commentSettings.trc = '';
//    }
//    if (strip(CW_commentSettings.lvside) == '') {
//       CW_commentSettings.lvside = '';
//    }
//    if (strip(CW_commentSettings.rvside) == '') {
//       CW_commentSettings.rvside = '';
//    }
//    if (strip(CW_commentSettings.blc) == '') {
//       CW_commentSettings.blc = '';
//    }
   if (strip(CW_commentSettings.bhside) == '') {
      CW_commentSettings.bhside = '';
   }

   return (true);
}
static boolean CW_moveBLCtoLeft() {
   BlockCommentSettings_t settings:[];
   BlockCommentSettings_t commentSettings;
   _str lang = CW_p_LangId;
   if (getCommentSettings( lang, settings, 'b')) {
      message('No comments setup for this file.');
      return (true);
   }

   commentSettings = settings:[lang];
   if (p_xlat) {
      commentSettings.tlc=_UTF8ToMultiByte(commentSettings.tlc);
      commentSettings.trc=_UTF8ToMultiByte(commentSettings.trc);
      commentSettings.blc=_UTF8ToMultiByte(commentSettings.blc);
      commentSettings.brc=_UTF8ToMultiByte(commentSettings.brc);
      commentSettings.bhside=_UTF8ToMultiByte(commentSettings.bhside);
      commentSettings.thside=_UTF8ToMultiByte(commentSettings.thside);
      commentSettings.lvside=_UTF8ToMultiByte(commentSettings.lvside);
      commentSettings.rvside=_UTF8ToMultiByte(commentSettings.rvside);
      commentSettings.comment_left=_UTF8ToMultiByte(commentSettings.comment_left);
      commentSettings.comment_right=_UTF8ToMultiByte(commentSettings.comment_right);
   }
   //Check for case of end string being stored in LCL box instead
   return (commentSettings.brc == '' && commentSettings.blc != '');
}

/**
 * Create a block comment skeleton based on the comment settings.
 * 
 * @return boolean  True if created skeleton.
 */
static boolean CW_maybeCreateNewDefault() {
   //Check special case of ENTER in middle of '/**/' sequence
   //Add the skeleton comment
   if (get_text(2) != '*/') {
      return (false);
   }
   _str line; get_line(line);
   line = strip(line);
   if (line != '/**/') {
      return (false);
   }

   //Check we aren't in a nested comment
   int tempPCol = p_col;
   _begin_line();
   boolean inComment = _in_comment(true);
   p_col = tempPCol;
   if (inComment) {
      return (false);
   }

   CW_clearCommentState();
   CW_updateCommentState();
   CW_inNewComment = true;

   //Get the comment setttings for extension from extension settings
   CW_getCommentSettings(CW_commentSettings);

   //Check that TLC and BRC settings make sense, correct if needed
   if ('/*' != substr(strip(CW_commentSettings.tlc), 1, 2)) {
      CW_commentSettings.tlc = '/*' :+ CW_commentSettings.tlc;
   }

   if (length(strip(CW_commentSettings.brc)) < 2 || '*/' != substr(strip(CW_commentSettings.brc), length(strip(CW_commentSettings.brc)) - 1, 2)) {
      CW_commentSettings.brc = strip(CW_commentSettings.brc, 'T', '*') :+ '*/';
   }
   //Set the left border column
   //CW_commentBorderLeftCol = p_col - length(strip(CW_commentSettings.tlc, 'T'));
   CW_commentBorderLeftCol = p_col - length('/*');
   if (CW_commentBorderLeftCol < 1) {
      CW_commentBorderLeftCol = 1;
   }
   //Calculate the margin
   int marginIndent = length(CW_commentSettings.lvside);
   if (CW_commentSettings.firstline_is_top && length(CW_commentSettings.tlc) > length(CW_commentSettings.lvside)) {
      marginIndent = length(CW_commentSettings.tlc);
   }
   if (CW_commentSettings.lastline_is_bottom && length(CW_commentSettings.blc) > length(CW_commentSettings.lvside) && length(CW_commentSettings.blc) > length(CW_commentSettings.tlc)) {
      marginIndent = length(CW_commentSettings.blc);
   }
   CW_commentSettings.lvside = substr(CW_commentSettings.lvside, 1, marginIndent, ' ');
   if (CW_commentSettings.firstline_is_top) CW_commentSettings.tlc = substr(CW_commentSettings.tlc, 1, marginIndent, ' ');
   if (CW_commentSettings.lastline_is_bottom) CW_commentSettings.blc = substr(CW_commentSettings.blc, 1, marginIndent, ' ');
   CW_commentMarginLeftCol = CW_commentBorderLeftCol + marginIndent;
   int rightBordersWidth       = length(CW_commentSettings.rvside);
   int rightBordersWidthTop    = length(CW_commentSettings.trc);
   int rightBordersWidthBottom = length(CW_commentSettings.brc);

   int rightMar = CW_getRightMargin(true);
   //Do special case of unknown right margin
   if (rightMar == 0) {
      if (strip(CW_commentSettings.trc) != '' || strip(CW_commentSettings.rvside) != '' || strip(CW_commentSettings.bhside) != '') {
         //message('Unknown right margin.  Can not create full comment border.');
         rightMar = _GetCommentWrapFlags(CW_MAX_RIGHT_COLUMN_DYN);
      } else {
         p_col = CW_commentBorderLeftCol;
         _delete_end_line();
         _insert_text_raw(CW_commentSettings.tlc);
         insert_line_raw('');
         p_col = CW_commentBorderLeftCol;
         if (strip(CW_commentSettings.blc) == '') {
            CW_commentSettings.blc = '';
         }
         _insert_text_raw(strip(CW_commentSettings.blc :+ CW_commentSettings.brc, 'T'));
         p_col = CW_commentBorderLeftCol + marginIndent;
         if (!CW_commentSettings.lastline_is_bottom) {
            p_line--;
            insert_line_raw('');
            p_col = CW_commentBorderLeftCol;
            _insert_text_raw(CW_commentSettings.lvside);
         }
         CW_inNewComment = true;

         // we did something, so let's tell the user about it
         CW_commentwrap_nag();

         return (true);
      }
   }
   //else draw complete border
   int commentWidth = rightMar - CW_commentBorderLeftCol + 1;
   if (commentWidth < (marginIndent + rightBordersWidth + 1)) {
      message(CW_CANNOT_FORMAT_MESSAGE_SKELETON);
      commentWidth = (marginIndent + rightBordersWidth + 1);
      int fixedWidthSize = _GetCommentWrapFlags(CW_FIXED_WIDTH_SIZE);
      if (fixedWidthSize > commentWidth) {
         commentWidth = fixedWidthSize;
      }
   }
   p_col = CW_commentBorderLeftCol;
   _delete_end_line();
   _str topLine = substr(CW_commentSettings.tlc, 1, commentWidth - rightBordersWidthTop, CW_commentSettings.thside != '' ? CW_commentSettings.thside : ' ') :+ CW_commentSettings.trc;
   _insert_text_raw(strip(topLine, 'T'));
   insert_line_raw(indent_string(CW_commentBorderLeftCol - 1));
   p_col = CW_commentBorderLeftCol;
   if (!CW_commentSettings.lastline_is_bottom) {//3 lines
      if (CW_commentSettings.blc == '' && CW_commentSettings.bhside == '') {
         _insert_text_raw(strip(CW_commentSettings.brc, 'T'));
      } else {
         if (false && CW_commentSettings.rvside == '') {
            p_col = CW_commentBorderLeftCol;
            if (strip(CW_commentSettings.blc) == '') {
               CW_commentSettings.blc = '';
            }
            _insert_text_raw(strip(CW_commentSettings.blc :+ CW_commentSettings.brc, 'T'));
         } else {
            _insert_text_raw(strip(substr(CW_commentSettings.blc, 1, commentWidth - rightBordersWidthBottom, CW_commentSettings.bhside != '' ? CW_commentSettings.bhside : ' ') :+ CW_commentSettings.brc, 'T'));
         }
      }
      up();
      insert_line_raw(indent_string(CW_commentBorderLeftCol - 1));
      p_col = CW_commentBorderLeftCol;
      _insert_text_raw(strip(substr(CW_commentSettings.lvside, 1, commentWidth - rightBordersWidth, ' ') :+ CW_commentSettings.rvside, 'T'));
   } else {//2 lines
      if (CW_commentSettings.rvside == '') {
         p_col = CW_commentBorderLeftCol;
         if (strip(CW_commentSettings.blc) == '') {
            CW_commentSettings.blc = '';
         }
         _insert_text_raw(strip(CW_commentSettings.blc :+ CW_commentSettings.brc, 'T'));
      } else {
         _insert_text_raw(strip(substr(CW_commentSettings.blc, 1, commentWidth - rightBordersWidth, CW_commentSettings.bhside != '' ? CW_commentSettings.bhside : ' ') :+ CW_commentSettings.brc, 'T'));
      }
      p_col = CW_commentBorderLeftCol + length(CW_commentSettings.blc);
      CW_inNewComment = true;

      // we did something, so let's tell the user about it
      CW_commentwrap_nag();

      return(true);
   }
   p_col = CW_commentBorderLeftCol + marginIndent;
   CW_inNewComment = true;

   // we did something, so let's tell the user about it
   CW_commentwrap_nag();
   return(true);
}
static boolean CW_maybeCreateNewJavadocDefault() {
   //Check special case of ENTER in middle of '/**/' sequence
   //Add the skeleton comment
   if (get_text(2) != '*/') {
      return (false);
   }
   _str line; get_line(line);
   line = strip(line);
   if (line != '/***/') {
      return (false);
   }

   //Check we aren't in a nested comment
   int tempPCol = p_col;
   _begin_line();
   boolean inComment = _in_comment(true);
   p_col = tempPCol;
   if (inComment) {
      return (false);
   }

   CW_clearCommentState();
   CW_updateCommentState(false, true);
   CW_inNewComment = true;

   p_col = CW_commentBorderLeftCol;
   _delete_end_line();
   _insert_text_raw('/**');
   insert_line_raw('');
   p_col = CW_commentBorderLeftCol;
   _insert_text_raw(' * ');
   int tempCol = p_col;
   insert_line_raw('');
   p_col = CW_commentBorderLeftCol;
   _insert_text_raw(' */');
   up(); p_col = tempCol;
   CW_inNewComment = true;

   // we did something, so let's tell the user about it
   CW_commentwrap_nag();

   return(true);
}

static _str CW_getStrippedJavadocContent(int startLine, int endLine, int testLine = 0) {
   if (testLine < 1) {
      testLine = p_line;
   }
   if (testLine < startLine || testLine > endLine) {
      return ('');
   }
   typeless p; save_pos(p);
   //Move to test line
   p_line = testLine;
   _str returnContent = '';
   _str line; get_line_raw(line);

   if (p_line == startLine && p_line == endLine) {
      parse line with '/**'returnContent'*/';
      returnContent = strip(returnContent, 'L', '*');
      returnContent = strip(returnContent);
   } else
   if (p_line == startLine) {
      parse line with '/**'returnContent;
      returnContent = strip(returnContent, 'L', '*');
      returnContent = strip(returnContent);
   } else {
      if (p_line == endLine) {
         parse line with returnContent'*/';
         line = strip(returnContent);
      } else {
         line = strip(line);
      }
      if (line == '' || line == '*') {
         returnContent = '';
      } else {
         returnContent = strip(line, 'L', '*');
      }
   }
   restore_pos(p);
   return strip(returnContent);
}

/**
 * Determines whether a line in a comment is the start of a paragraph.
 * 
 * @param commentType   Current comment type
 * @param startLine     Line number of start of comment
 * @param endLine       Line number of end of comment
 * @param testLine      Line number of line to test
 * 
 * @return boolean      CW_NOTPARA if line begins a paragrah
 */
static int CW_isParaStart(int commentType, int startLine, int endLine, int testLine = 0, boolean skipIndentTest = false) {
   switch (commentType) {
   case (CW_JAVADOCCOMMENT):
      return (CW_isJavadocParaStart(startLine, endLine, testLine, skipIndentTest));
      break;
   case (CW_FULLBLOCKCOMMENT):
   case (CW_LINECOMMENTBLOCK):
   case (CW_XMLDOCCOMMENT):      
      return (CW_isBCParaStart(startLine, endLine, testLine, skipIndentTest));
      break;
   }
   return(CW_NOTPARA);
}

/**
 * Determines if the cursor inside a document comment on a line with no text other
 * than the astericks at the start of a line which are ingnored. 
 *  
 * @param line contents of the current line
 * 
 * @return boolean True if cursor on blank line of a document comment
 */
boolean onDocCommentBlankLine(_str line) {
   int startCol = p_col;
   if (line == '') {
      return true;
   }

   _str lineStrip = strip(line, 'L');
   first_non_blank();
   int firstNonBlank = p_col;
   p_col = startCol;
   if (_in_comment(true)) {
      //Fast check of common case
      if (line=='*' && p_col==_text_colc()+1 ) {
         return true;
      }
      if (pos('^\**', lineStrip, 1, 'R')) {
         if (p_col < firstNonBlank + pos('')) {
            return false;
         }
      }
   } else {
      if (pos('^(///|//!)', lineStrip, 1, 'R')) {
         if (p_col < firstNonBlank + pos('')) {
            return false;
         }
      }
   }
   return true;
}

static boolean CW_startsWithStandAloneHTMLTag(_str &line)
{
   if (substr(line,1,1)!='<') {
      return(false);
   }
   if (!_html_tags_loaded()) {
      // This should not happen
      return(false);
   }
   _str tag;
   if (substr(line,2,1)=='/') {
      int i=pos('[ \t>]',line,3,'r');
      if (!i) return(false);
      tag=substr(line,3,i-3);
      // Standalong means line-break after start tag and line break before end tag.
      return(_html_get_attr_val(tag,'standalone'));
   }
   int i=pos('[ \t>]',line,2,'r');
   if (!i) return(false);
   tag=substr(line,2,i-2);
   // Number of line breaks before start tag
   return(_html_get_attr_val(tag,'noflines_before'));
}

/**
 * 
 * @param startLine
 * @param endLine
 * @param testLine
 * @param skipIndentTest
 * 
 * @return int
 */
static int CW_isJavadocParaStart(int startLine, int endLine, int testLine = 0, boolean skipIndentTest = false) {
   if (testLine < 1) {
      testLine = p_line;
   }
   typeless p; save_pos(p);
   boolean returnVal;

   //Would be a paragraph start if not a blank line, and one of the
   //following, the first line in comment, starts with a tag, previous line is
   //blank, or has different indent than the previous line (except when previous
   //line is indented more and is the start of a paragraph).

   _str currentLineContent = '';
   _str previousLineContent = '';

   currentLineContent = CW_getStrippedJavadocContent(startLine, endLine, testLine);
   //blank line can not be a paragraph start
   if (currentLineContent == '') {
      return (CW_NOTPARA);
   }
   //We know we have content on testLine.  If testLine is start of comment,
   //must be paragraph start.
   if (testLine == startLine) {
      return (CW_STARTLINE);
   }
   //We are not on startLine, so see if previous line is blank.  If so, start of paragraph
   previousLineContent = CW_getStrippedJavadocContent(startLine, endLine, testLine - 1);
   if (previousLineContent == '' || (testLine - 1 == startLine && !CW_commentSettings.firstline_is_top)) {
      return (CW_PREVBLANK);
   }
   //Now search for delimiters
   //Javadoc block tags
   if (pos(CW_javadocBlockTags, currentLineContent, 1, 'U')) {
      return (CW_JDBLOCKTAG);
   }

   //Javadoc HTML tags
   if (CW_startsWithStandAloneHTMLTag(currentLineContent)) {
      return (CW_JDHTMLTAG);
   }

   //Check for doc comment tags 
   if (pos(CW_docCommentTags, currentLineContent, 1, 'U')) {
      return (CW_DOXYGENTAG);
   }

   //Check for doc comment tags 
   if (pos(CW_STARTOFSTARTORENDTAGREGEX, currentLineContent, 1, 'R')) {
      return (CW_DOXYGENTAG);
   }

   //Bullet search
   if (pos(CW_commentBulletTags, currentLineContent, 1, 'U')) {
      return (CW_BULLET);
   }

   //Numbered paragraph search
/*
    if (pos(CW_commentNumberTags, currentLineContent, 1, 'U')) {
       return (CW_NUMBER);
    }
*/

  if (!skipIndentTest) {
     //Need to integrate this into the call to CW_getStrippedJavadocContent, instead
     _str content = '';
     int lmc, rmc, boffset;
     p_line = testLine - 1;
     lmc = CW_extractBCLineText(currentLineContent, startLine, endLine, rmc, boffset);
     int afterBulletCol1 = text_col(CW_currentLine, (text_col(CW_currentLine, lmc, 'P') + boffset - 1), 'I');
     p_line = testLine;
     lmc = CW_extractBCLineText(currentLineContent, startLine, endLine, rmc, boffset);
     int afterBulletCol2 = text_col(CW_currentLine, (text_col(CW_currentLine, lmc, 'P') + boffset - 1), 'I');
     if (afterBulletCol1 != afterBulletCol2) {
        return (CW_INDENT);
     }
  }

   return (CW_NOTPARA);
}

static int CW_isBCParaStart(int startLine, int endLine, int testLine = 0, boolean skipIndentTest = false) {
   if (testLine < 1) {
      testLine = p_line;
   }
   typeless p; save_pos(p);
   boolean returnVal;

   p_line = testLine;

   //Would be a paragraph start if not a blank line, and one of the
   //following, the first line in comment, starts with a tag, previous line is
   //blank, or has different indent than the previous line (except when previous
   //line is indented more and is the start of a paragraph).

   _str currentLineContent = '';
   _str previousLineContent = '';

   int lmc, rmc, boffset;
   lmc = CW_extractBCLineText(currentLineContent, startLine, endLine, rmc, boffset);
   //blank line can not be a paragraph start
   if (currentLineContent == '' || (p_line == startLine && !CW_commentSettings.firstline_is_top)) {
      restore_pos(p);
      return (CW_NOTPARA);
   }
   
   int afterBulletCol = text_col(CW_currentLine, (text_col(CW_currentLine, lmc, 'P') + boffset - 1), 'I');

   //We know we have content on testLine.  If testLine is start of comment,
   //must be paragraph start.
   if (testLine == startLine) {
      restore_pos(p);
      return (CW_STARTLINE);
   }

   _str fullCurrentLine = CW_currentLine;
   CW_up();
   //We are not on startLine, so see if previous line is blank.  If so, start of paragraph
   lmc = CW_extractBCLineText(previousLineContent, startLine, endLine, rmc, boffset);
   restore_pos(p);
   if (previousLineContent == '' || (p_line == startLine && !CW_commentSettings.firstline_is_top)) {
      return (CW_PREVBLANK);
   }

   //Check for doc comment tags 
   if (pos(CW_STARTOFSTARTORENDTAGREGEX, currentLineContent, 1, 'R')) {
      if (_inDocComment()) {
         return (CW_DOXYGENTAG);
      }
   }

   //Check for doc comment tags 
   if (pos(CW_docCommentTags, currentLineContent, 1, 'U')) {
      if (_inDocComment()) {
         return (CW_DOXYGENTAG);
      }
   }

   //Now search for delimiters
   //Bullet search
   if (pos(CW_commentBulletTags, currentLineContent, 1, 'U')) {
      return (CW_BULLET);
   }

   //Numbered paragraph search
/*
    if (pos(CW_commentNumberTags, currentLineContent, 1, 'U')) {
       return (CW_NUMBER);
    }
*/

   if (!skipIndentTest) {
      int afterBulletCol2 = text_col(CW_currentLine, (text_col(CW_currentLine, lmc, 'P') + boffset - 1), 'I');
      if (afterBulletCol != afterBulletCol2) {
         return (CW_INDENT);
      }
   }
   return (CW_NOTPARA);
}

/**
 * Moves cursor one line up. If line is not in view, line is center scrolled or
 * smooth scrolled into view.  Is careful skip imaginary lines
 *
 * @return Returns 0 if successful.  Otherwise TOP_OF_FILE_RC is returned.
 *
 */
int CW_up() {
   int count=0;
   for (;; count++) {
      int status = up();
      if (status == TOP_OF_FILE_RC) {
         down(count);
         return status;
      }
      //We moved up successfully. Now check if we landed on an imaginary line.
      //If so, move up again
      if (!(_lineflags() & NOSAVE_LF)) {
         return 0;
      }
   }
}

/**
 * Moves cursor one line down. If line is not in view, line is center
 * scrolled or smooth scrolled into view.  Is careful skip imaginary lines
 *
 * @return Returns 0 if successful.  Otherwise TOP_OF_FILE_RC is returned.
 *
 */
int CW_down() {
   int count=0;
   for (;; count++) {
      int status = down();
      if (status == BOTTOM_OF_FILE_RC) {
         up(count);
         return status;
      }
      //We moved down successfully. Now check if we landed on an imaginary line.
      //If so, move down again
      if (!(_lineflags() & NOSAVE_LF)) {
         return 0;
      }
   }
}

/**
 * Tests if current comment line has any content.
 * 
 * @param startLine   First line number of comment block
 * @param endLine     Last line number of comment block
 * @param testLine    Line number to test
 * 
 * @return boolean    True if comment line has no content
 */
static boolean CW_isBCBlankLine(int startLine, int endLine, int testLine = 0) {
   if (testLine < 1) {
      testLine = p_line;
   }
   typeless p; save_pos(p);
   boolean returnVal = false;
   p_line = testLine;
   _str currentLineContent = '';

   if (((p_line == startLine) && (!CW_commentSettings.firstline_is_top)) || ((p_line == endLine) && (!CW_commentSettings.lastline_is_bottom))) {
      returnVal = true;
      restore_pos(p);
      return (returnVal);
   }

   int lmc, rmc, boffset;
   lmc = CW_extractBCLineText(currentLineContent, startLine, endLine, rmc, boffset);
   if (strip(currentLineContent) == '') {
      returnVal = true;
   }
   restore_pos(p);
   return (returnVal);
}


//struct to hold the sets of block comment delimiters for an extension.
typedef struct {
   _str startChars[];
   _str endChars[];
   boolean nesting[];
} CW_blockCommentDelimiters_t;

//struct to hold the sets of line comment delimiters for an extension.
typedef struct {
   _str startChars[];
   _str endChars[];
} CW_lineCommentDelimiters_t;

static CW_blockCommentDelimiters_t CW_blockCommentDelimiters:[];
static CW_lineCommentDelimiters_t CW_lineCommentDelimiters:[];

static _str CW_p_lexer_name() {
   _str lexer = get_unsaved_lexer_name_for_langId(CW_p_LangId);
   if (lexer == '' || lexer == null) {
      // we haven't been messing with the color coding, so we can just look 
      // at the saved lexer name
      lexer = LanguageSettings.getLexerName(CW_p_LangId);
   }
   return lexer;
}

int CW_getBlockCommentDelimiters(_str (&startChars)[], _str (&endChars)[], boolean (&nesting)[], _str lexer_name = CW_p_lexer_name()) {
   if (lexer_name == '') {
      return 1;
   }
   if (!CW_blockCommentDelimiters._indexin(lexer_name)) {
      CW_blockCommentDelimiters_t newDelimiters;
      _getBlockCommentChars(newDelimiters.startChars, newDelimiters.endChars, newDelimiters.nesting, lexer_name);
      CW_blockCommentDelimiters:[lexer_name] = newDelimiters;
   }
   startChars = CW_blockCommentDelimiters:[lexer_name].startChars;
   endChars = CW_blockCommentDelimiters:[lexer_name].endChars;
   nesting = CW_blockCommentDelimiters:[lexer_name].nesting;
   return (0);
}
 
int CW_getLineCommentDelimiters(_str (&startChars)[], _str lexer_name = CW_p_lexer_name()) {
   if (!CW_lineCommentDelimiters._indexin(lexer_name)) {
      CW_lineCommentDelimiters_t newDelimiters;
      _getLineCommentChars(newDelimiters.startChars, lexer_name);
      CW_lineCommentDelimiters:[lexer_name] = newDelimiters;
   }
   startChars = CW_lineCommentDelimiters:[lexer_name].startChars;
   return (0);
}

/**
 * Variation of the _inJavadoc() functions that is returns true when content is 
 * next to the start sequence
 * 
 * @return boolean   True when in a javaDoc
 */
static boolean CW_inJavadoc()
{
   if (_clex_find(0,'g')!=CFG_COMMENT) {
      return(0);
   }
   save_pos(auto p);
   int status=_clex_find(COMMENT_CLEXFLAG,'n-');
   if (status) {
      top();
   }
   _clex_find(COMMENT_CLEXFLAG);
   boolean returnVal = false;
   get_line(auto text);
   text=substr(text,text_col(text,p_col,'P'),5);
   text=stranslate(text,"","\n");
   text=stranslate(text,"","\r");
   text = strip(text, 'T');
   if (substr(text, 1, length(JAVADOC_PREFIX)) :== JAVADOC_PREFIX) {
      auto stext = strip(substr(text, 1, 4), 'T');

      if (stext :== JAVADOC_PREFIX || text :== '/***/') {
         returnVal = true;
      } else if (stext :== (JAVADOC_PREFIX :+ '*')) {
         // Handle unfortunate Doxygen case where there are
         // two block comments jammed together in order to 
         // have a line of asterisks as a border and still be 
         // recognized as a doc comment.
         // ie: /*************//**[CR] ....
         returnVal = maybe_find_doxygen_comment_start(auto not_used);
      } else if (length(text) >= 4 && !isalnum(substr(text, 4, 1))) {
         returnVal = false;
      } else {
         returnVal = true;
      }
   }
   restore_pos(p);
   return(returnVal);
}

/***/
boolean _inDocComment()
{
   if (_clex_find(0,'g')!=CFG_COMMENT) {
      return(0);
   }
   save_pos(auto p);
   int status=_clex_find(COMMENT_CLEXFLAG,'n-');
   if (status) {
      top();
   }
   _clex_find(COMMENT_CLEXFLAG);
   boolean returnVal = false;
   get_line(auto text);
   text=substr(text,text_col(text,p_col,'P'),5);
   text=stranslate(text,"","\n");
   text=stranslate(text,"","\r");
   text = strip(text, 'T');
   if (substr(text, 1, length(JAVADOC_PREFIX)) :== JAVADOC_PREFIX) {
      if (strip(substr(text, 1, 4), 'T') :== JAVADOC_PREFIX || text :== '/***/') {
         returnVal = true;
      } else 
      if (length(text) >= 4 && !isalnum(substr(text, 4, 1))) {
         restore_pos(p);
         return false;
      }
      else returnVal = true;
   }
   if (substr(text, 1, length(DOXYGEN_PREFIX1)) :== DOXYGEN_PREFIX1) {
      if (strip(substr(text, 1, 4), 'T') :== DOXYGEN_PREFIX1 || text :== '/*!*/') {
         returnVal = true;
      } else 
      if (length(text) >= 4 && !isalnum(substr(text, 4, 1))) {
         restore_pos(p);
         return false;
      }
      else returnVal = true;
   }
   restore_pos(p);
   if (!returnVal) {
      first_non_blank();
      if (!_in_comment(true)) {
         if (get_text(3) :== XMLDOC_PREFIX || get_text(3) :== DOXYGEN_PREFIX2) {
            returnVal = true;
         }
      }
      restore_pos(p);
   }

   return(returnVal);
}

/**
 * Return the column number of the start of the line comment.  Line 
 * comment must be the first thing on the line. 
 * 
 * @param lineNumber  Line number to check.
 * 
 * @param noBlank     If true, do not allow blank line comments.
 * 
 * @return int  Column number of start of line comment.  Zero if not a line
 *         comment or zero if the line comment is not the first thing on the
 *         line.
 */
static int CW_lineCommentStartCol(_str lineCommentDelim, int lineNumber = p_line, boolean noBlank = false) {
   typeless OriginalPos;
   save_pos(OriginalPos);
   p_line = lineNumber;

   //if (_beginLineComment()) {
   //   restore_pos(OriginalPos);
   //   return 0;
   //}

   first_non_blank();
   int col_beginLineComment = p_col;
   if (lineCommentDelim == get_text(lineCommentDelim._length())) {
      if (noBlank) {
         _str line; get_line(line);
         if (strip(line) == strip(lineCommentDelim)) {
            restore_pos(OriginalPos);
            return 0;
         }
      }
      restore_pos(OriginalPos);
      return col_beginLineComment;
   }
   restore_pos(OriginalPos);
   return 0;
}

/**
 * Calculates the start and end of a block of line comments.  
 *  
 * @param startPos
 * @param endPos
 * 
 * @return int
 */
static int CW_inLineCommentBlock(typeless &startPos = 0, typeless &endPos = 0, boolean fromCW_getCommentLineContent = false) {
   //Save position so we can later return to original state
   typeless OriginalPos;
   save_pos(OriginalPos);
   int origLine = p_line;

   //Get possible line comment delimiters
   _str lineCommentDelims[];
   if (_getLineCommentChars(lineCommentDelims)) return CW_NOTCOMMENT;
   //Move to start of line comment
   if (_beginLineComment()) {
      restore_pos(OriginalPos);
      return CW_NOTCOMMENT;
   }
   //Is this the first thing on the line?
   int startLineCommentCol = p_col;
   if (!fromCW_getCommentLineContent) {
      first_non_blank();
      if (startLineCommentCol != p_col) {
         restore_pos(OriginalPos);
         return CW_NOTCOMMENT;
      }
   }

   //Which line comment delimiter starts this line comment
   int i;
   _str lineCommentDelim = '';
   for (i = 0; i < lineCommentDelims._length(); i++) {
      if (lineCommentDelims[i] == get_text(lineCommentDelims[i]._length())) {
         lineCommentDelim = lineCommentDelims[i];
         break;
      }
   }
   if (lineCommentDelim == '') {
      restore_pos(OriginalPos);
      return CW_NOTCOMMENT;
   }

   int startCol = CW_lineCommentStartCol(lineCommentDelim);
   if (fromCW_getCommentLineContent) {
      startCol = startLineCommentCol;
   }
   if (!startCol) {
      restore_pos(OriginalPos);
      return CW_NOTCOMMENT;
   }

   //Check for special doc comment line comment delimiters
   if (lineCommentDelim == '//') {
      p_col = startCol;
      CW_lineCommentLeft = get_text(4);
      if ((CW_lineCommentLeft != '/// ') && (CW_lineCommentLeft != '//! ') && (CW_lineCommentLeft != '//!\t') && (CW_lineCommentLeft != '//!\t')) {
         CW_lineCommentLeft = get_text(3);
         if ((CW_lineCommentLeft != '///') && (CW_lineCommentLeft != '//!')) {
            CW_lineCommentLeft = '//';
         }
      }
   } else {
      CW_lineCommentLeft = lineCommentDelim;
      //Add a space
      strappend(CW_lineCommentLeft, ' ');
   }
   //messageNwait('|'CW_lineCommentLeft'|');
   int topline = p_line;
   int bottomline = p_line;

   int numberOfLinesToSearchUp = 2;
   if (_GetCommentWrapFlags(CW_USE_FIRST_PARA) || _GetCommentWrapFlags(CW_AUTO_OVERRIDE, CW_p_LangId)) {
      numberOfLinesToSearchUp = def_cw_analyze_lines_max;
   }
   //find start of line comment block
   while(p_line > 0 && (CW_lineCommentStartCol(lineCommentDelim) == startCol) && (origLine - topline + 1 <= numberOfLinesToSearchUp)) {//put test for blank here
      p_col = startCol;
      CW_lineCommentLeft = CW_longestMatch(CW_lineCommentLeft, get_text(length(CW_lineCommentLeft)));
      topline = p_line;
      p_line--;
   }
   p_line = topline; p_col = startCol;
   save_pos(startPos);
   restore_pos(OriginalPos);

   //find end of line comment block    
   while(!down() && CW_lineCommentStartCol(lineCommentDelim, p_line, true)==startCol && (bottomline - origLine + 1 < def_cw_analyze_lines_max)) {//put test for blank here
      p_col = startCol;
      CW_lineCommentLeft = CW_longestMatch(CW_lineCommentLeft, get_text(length(CW_lineCommentLeft)));
      bottomline = p_line;
   }
   p_line = bottomline; end_line();
   save_pos(endPos);
   restore_pos(OriginalPos);
   if (((bottomline - topline + 1 < (int)_GetCommentWrapFlags(CW_LINE_COMMENT_MIN, CW_p_LangId)) && (CW_lineCommentLeft != '//!')) 
       && !fromCW_getCommentLineContent) {
      return CW_NOTCOMMENT;
   }
   return CW_LINECOMMENTBLOCK;
}

/**
 * Returns a value indicating the type of block comment the cursor is in.
 * Differentiates between block comments that match the language
 * extensions definitions and those that do not.
 * 
 * @param startPos   (out) Set to position of start of comment
 * @param endPos     (out) Set to position of end of comment
 * 
 * @return int  Value identifing the type of block comment we are in.
 *                  
 *                  <UL>
 *                  <LI>CW_FULLBLOCKCOMMENT      
 *                  <LI>CW_LINECOMMENT           
 *                  <LI>CW_JAVADOCCOMMENT        
 *                  <LI>CW_XMLDOCCOMMENT         
 *                  <LI>CW_DOXYGENDOCCOMMENT     
 *                  <LI>CW_NOTCOMMENT       
 *                  </UL>
 */
static int CW_inBlockComment(typeless &startPos = 0, typeless &endPos = 0, boolean fromCW_getCommentLineContent = false) {
   _str lang = CW_p_LangId;
   if ((!fromCW_getCommentLineContent) && !commentwrap_isSupportedLanguage(lang)) {
      return (CW_NOTCOMMENT);
   }

   //Save position so we can later return to original state
   typeless OriginalPos;
   save_pos(OriginalPos);
   int OriginalLine = p_line;
   int OriginalCol = p_col;

   if (false && CW_p_LangId == 'fundamental') {
      top();
      save_pos(startPos);
      bottom();
      save_pos(endPos);
      restore_pos(OriginalPos);
      return (CW_FUNDAMENTALMODE);
   }

   int returnVal = CW_NOTCOMMENT;
   returnVal = CW_FULLBLOCKCOMMENT;
   boolean inComment = _in_comment(false);
   if (!inComment) {
      //Check for CW_TRAILINGCOMMENT
      if (p_LangId == 'pl1') {
         _clex_find(COMMENT_CLEXFLAG);
         if (!(p_line == OriginalLine && p_col > OriginalCol)) {
            restore_pos(OriginalPos);
            return (CW_NOTCOMMENT);
         }
         CW_trailingCommentCol = p_col;
         _str leftChar = get_text_left();
         restore_pos(OriginalPos);
         if (!isspace(leftChar)) {
            return (CW_NOTCOMMENT);
         } else {
            return (CW_TRAILINGCOMMENT);
         }
      }
      return (CW_NOTCOMMENT);
   }
   boolean inCommentFull = _in_comment(true);
   if (!inCommentFull) {
      //if in a comment but not a block comment or Javadoc comment, then must be a line comment
      return (CW_inLineCommentBlock(startPos, endPos, fromCW_getCommentLineContent));
   }
   // Problem with _inJavadoc(), Use new function
   if (CW_inJavadoc()) {   
      returnVal = (CW_JAVADOCCOMMENT);
   }
   else if (commentwrap_inXMLDoc(startPos, endPos)) {
      returnVal = (CW_XMLDOCCOMMENT);
      return(returnVal);
   }

   _str commentTLCstr[];
   _str commentBRCstr[];
   boolean commentNesting[];

   CW_getBlockCommentDelimiters(commentTLCstr, commentBRCstr, commentNesting);
   if ((commentTLCstr._length() == 0) || (commentBRCstr._length() == 0)) {
      return (CW_NOTCOMMENT);
   }

   int i;
   boolean foundMarkers = false;

   if (returnVal == CW_JAVADOCCOMMENT) {
      for (i = 0; i < commentTLCstr._length(); i++) {
         if (commentTLCstr[i] != '/*' || commentBRCstr[i] != '*/') {
            continue;
         }
         foundMarkers = CW_inBlockCommentJ(startPos, endPos, OriginalPos, OriginalLine, OriginalCol, JAVADOC_PREFIX, strip(JAVADOC_END_PREFIX), commentNesting[i]);
         if (foundMarkers) {
            CW_commentTLCstr = JAVADOC_PREFIX;
            CW_commentBRCstr = strip(JAVADOC_END_PREFIX);
         }
      }
   } else {
      for (i = 0; i < commentTLCstr._length(); i++) {
         foundMarkers = CW_inBlockComment3(startPos, endPos, OriginalPos, OriginalLine, OriginalCol, commentTLCstr[i], commentBRCstr[i], commentNesting[i]);
         if (foundMarkers) {
            CW_commentTLCstr = commentTLCstr[i];
            CW_commentBRCstr = commentBRCstr[i];
            break;
         }
      }
   }
   if (!foundMarkers) {
      restore_pos(OriginalPos);
      return (CW_NOTCOMMENT);
   }

   //Check that there is no content on line before start sequence
   //and no content on line after the end sequence.
   if (!fromCW_getCommentLineContent) {
      restore_pos(startPos);
      if (!CW_isDoxygenCommentPair // There's stuff on the line before us for sure in this case.
          && (strip(CW_getLineToColumn()) != '' || (OriginalLine == p_line && p_col < OriginalCol && OriginalCol < p_col + length(CW_commentTLCstr)))) {
         restore_pos(OriginalPos);
         return (CW_NOTCOMMENT);
      }
      restore_pos(endPos);
      if (strip(CW_getLineFromColumn()) != '' || (OriginalLine == p_line && p_col > OriginalCol && OriginalCol > p_col - length(CW_commentBRCstr))) {
         restore_pos(OriginalPos);
         return (CW_NOTCOMMENT);
      }
   }
   
   CW_inJavadocScriptTag = false;
   //Confirm that we are still in a Javadoc
   if (returnVal == CW_JAVADOCCOMMENT) {         
      restore_pos(startPos);
      if (get_text(length(JAVADOC_PREFIX)) != JAVADOC_PREFIX) {
         returnVal = CW_FULLBLOCKCOMMENT;
      } else {
         restore_pos(startPos);
         long startOffset = _QROffset();
         //Check for script tag
         restore_pos(OriginalPos);
         if (!search('<pre>|</pre>', '-U@HCCC<')) {
            if (get_text(5)  == '<pre>' && (startOffset < _QROffset())) {
               CW_inJavadocScriptTag = true;
            }
         }
         restore_pos(OriginalPos);
         if (!search('<xmp>|</xmp>', '-U@HCCC<')) {
            if (get_text(5)  == '<xmp>' && (startOffset < _QROffset())) {
               CW_inJavadocScriptTag = true;
            }
         }                             
         restore_pos(OriginalPos);
         if (!search('<script>|</script>', '-U@HCCC<')) {
            if (get_text(8)  == '<script>' && (startOffset < _QROffset())) {
               CW_inJavadocScriptTag = true;
            }
         }
         restore_pos(startPos);
         CW_commentSettings.tlc = CW_commentTLCstr = JAVADOC_PREFIX;
         //Also check end. Add leading space if possible
         restore_pos(endPos);
         p_col -= 3;
         if (p_col > 0) {
            if (get_text(length(JAVADOC_END_PREFIX)) == JAVADOC_END_PREFIX) {
               CW_commentSettings.brc = CW_commentBRCstr = JAVADOC_END_PREFIX;
            }
         }
      }
   }
   
   restore_pos(OriginalPos);
   return (returnVal);
}


static boolean CW_inBlockComment3(typeless &startPos, typeless &endPos, typeless OriginalPos, int OriginalLine, int OriginalCol, _str commentTLCstr, _str commentBRCstr, boolean nesting = false) {
   //move backwards until out of comment
   int status=_clex_find(COMMENT_CLEXFLAG,'n-');
   //if unable to move out of top of comment, then doc must start with
   //a comment, so just move to top of buffer
   if (status) {
      top();
   }
   //Now move forward to start of comment section
   _clex_find(COMMENT_CLEXFLAG);

   int lenghtTlc = length(commentTLCstr);
   if (search(_escape_re_chars(commentTLCstr), 'U@HCCC<')) {
      //message('Can not find start of comment.');
      restore_pos(OriginalPos);
      return (false);
   }

   _str commentMarkersRegexS = '(?0' :+ _escape_re_chars(commentTLCstr) :+ ')';
   _str commentMarkersRegexE = '(?0' :+ _escape_re_chars(commentBRCstr) :+ ')';
   _str commentMarkersRegex = '(?0' :+ _escape_re_chars(commentTLCstr) :+ '|' :+ _escape_re_chars(commentBRCstr) :+ ')';
   int count = 0; 
   if (false && nesting) {
      restore_pos(OriginalPos);

      //Search through comment from start to find the end accounting for nested and/or
      //consecutive block comments.  

      if (search(commentMarkersRegexS, '-U@HCCC<')) {
         restore_pos(OriginalPos);
         return(false);
      }
      save_pos(startPos); 
      while (!search(commentMarkersRegex, '-U@HCCC<')) {
         if (get_text(match_length('0'),match_length('S0')) == commentTLCstr) {
            save_pos(startPos); 
         } else {
            break;
         }
         if (p_col > 1) {
            p_col--;
         } else {
            if (p_line == 1) {
               break;
            } else {
               p_line--;
               end_line();
            }
         }
      }
      restore_pos(OriginalPos);
      if (search(commentMarkersRegexE, 'U@HCCC>')) {
         restore_pos(OriginalPos);
         return(false);
      }
      save_pos(endPos); 
      while (!search(commentMarkersRegex, 'U@HCCC>')) {
         if (get_text(match_length('0'),match_length('S0')) == commentBRCstr) {
            save_pos(endPos); 
         } else {
            break;
         }
      }
      restore_pos(OriginalPos);
      return(true);
   } else {
      //Starting at opening comment start sequence.
      save_pos(startPos); 
      //while(true) {
      while((p_line < OriginalLine) || ((p_line == OriginalLine) && (p_col < OriginalCol))) {
         if (search(commentMarkersRegexE, 'U@HCCC>'))
            //Requires that comments be closed, so return false.
            return (false);
         if (p_line > OriginalLine || (p_line == OriginalLine && p_col > OriginalCol)) {
            save_pos(endPos);
            return (true);
         } else {
            if (search(commentMarkersRegexS, 'U@HCCC<'))
               return (false);
            save_pos(startPos); 
         }
      }
   }
   return (false);
}

// For doxygen comments like this: /*********//**[CR]....
// Finds the true start to the comment.  Assumes _QROffset() is 
// at the start of the first comment.
static boolean maybe_find_doxygen_comment_start(typeless &startPos)
{
   // Did this with a search first time - was noticably slow.
   // This implicitly limits the doxygen comment pair to one line.
   get_line(auto line);
   auto start_index = _text_colc(p_col, 'P');
   auto second_start = pos('//\*\*', line, start_index+1, 'U');

   if (second_start == 0) {
      return false;
   }

   save_pos(auto p);
   p_col = _text_colc(second_start, 'I');
   save_pos(startPos);
   restore_pos(p);

   return true;
}

static boolean CW_inBlockCommentJ(typeless &startPos, typeless &endPos, typeless OriginalPos, int OriginalLine, int OriginalCol, _str commentTLCstr, _str commentBRCstr, boolean nesting = false) {
   //move backwards until out of comment
   int status=_clex_find(COMMENT_CLEXFLAG,'n-');
   //if unable to move out of top of comment, then doc must start with
   //a comment, so just move to top of buffer
   if (status) {
      top();
   }
   //Now move forward to start of comment section
   _clex_find(COMMENT_CLEXFLAG);

   CW_isDoxygenCommentPair = maybe_find_doxygen_comment_start(startPos);

   int lenghtTlc = length(commentTLCstr);
   if (search(_escape_re_chars(commentTLCstr), 'U@HCCC<')) {
      //message('Can not find start of comment.');
      restore_pos(OriginalPos);
      return (false);
   }

   _str commentMarkersRegexS = '(?0' :+ _escape_re_chars(commentTLCstr) :+ ')';
   _str commentMarkersRegexE = '(?0' :+ _escape_re_chars(commentBRCstr) :+ ')';
   _str commentMarkersRegex = '(?0' :+ _escape_re_chars(commentTLCstr) :+ '|' :+ _escape_re_chars(commentBRCstr) :+ ')';
   _str commentMarkersRegexJE = '(?0' :+ _escape_re_chars("/*") :+ '|' :+ _escape_re_chars(commentTLCstr) :+ '|' :+ _escape_re_chars(commentBRCstr) :+ ')';

   if (nesting) {
      restore_pos(OriginalPos);

      //Search through comment from start to find the end accounting for nested and/or
      //consecutive block comments.  
      int count = 0;

      if (search(commentMarkersRegexS, '-U@HCCC<')) {
         restore_pos(OriginalPos);
         return(false);
      }
      save_pos(startPos); 
      while (!search(commentMarkersRegex, '-U@HCCC<')) {
         if (get_text(match_length('0'),match_length('S0')) == commentTLCstr) {
            save_pos(startPos); 
         } else {
            break;
         }
         if (p_col > 1) {
            p_col--;
         } else {
            if (p_line == 1) {
               break;
            } else {
               p_line--;
               end_line();
            }
         }
      }
      restore_pos(OriginalPos);
      if (search(commentMarkersRegexE, 'U@HCCC>')) {
         restore_pos(OriginalPos);
         return(false);
      }
      save_pos(endPos); 
      while (!search(commentMarkersRegexJE, 'U@HCCC>')) {
         if (get_text(match_length('0'),match_length('S0')) == commentBRCstr) {
            save_pos(endPos); 
         } else {
            break;
         }
      }
      restore_pos(OriginalPos);
      return(true);
   } else {
      save_pos(startPos); 
      while(true) {
         if (search(commentMarkersRegexE, 'U@HCCC>')) {
            return (false);
         }
         if (p_line > OriginalLine || (p_line == OriginalLine && p_col > OriginalCol)) {
            save_pos(endPos);    
            return (true);
         } else {
            if (search(commentMarkersRegexS, 'U@HCCC<'))
               return (false);
            if (p_line > OriginalLine || (p_line == OriginalLine && p_col > OriginalCol)) {
               return (false);
            }
            save_pos(startPos);  
         }
      }
   }
   return (false);
}

/**
 * 
 * 
 * @return boolean
 */
static boolean CW_inXMLDocLine() {
   int XMLDocPrefixLength = length(XMLDOC_PREFIX);
   get_line(auto line);
   return (substr(strip(line, 'L'), 1, XMLDocPrefixLength) == XMLDOC_PREFIX);
}

/**
 * Determine if within an XMLDoc and set the start and end positions.
 * 
 * @return boolean True if inside of and XMLDoc.
 */
boolean commentwrap_inXMLDoc(typeless &startPos = 0, typeless &endPos = 0) {
   //An XMLDoc must be a series of single-line comments
   if (!_in_comment() || _in_comment(true)) {
      return (false);
   }
   if (!CW_inXMLDocLine()) {
      return (false);
   }
   //Save position so we can later return to original state
   typeless p; save_pos(p);

   int XMLDocStartLine, XMLDocEndLine;

   while (CW_inXMLDocLine()) {
      XMLDocStartLine = p_line;
      if (up()) {
         break;
      }
   }
   p_line = XMLDocStartLine;
   first_non_blank();
   save_pos(startPos);

   restore_pos(p);
   while (CW_inXMLDocLine()) {
      XMLDocEndLine = p_line;
      if (down()) {
         break;
      }
   }
   p_line = XMLDocEndLine;
   end_line();
   save_pos(endPos);

   restore_pos(p);
   return(true);
}
/**
 * Determine right most margin for current comment based on the comment state 
 * variables and the comment wrap settings for the current extension type.
 * 
 * @param ignoreOverride   If true, ignore the 'Use automatic width on existing
 *                         comments' setting on the Comment wrap tab
 * 
 * @return int  Right most column, including any borders, for current block
 *              comment.
 */
static int CW_getRightMargin(boolean ignoreOverride = false) {

   boolean fallBackToFixed = true;

   if (CW_RBanalyzedWidth) {
      //If a right border was found, use that value
      return (CW_RBanalyzedWidth);
   }
   if (CW_inNewComment) {
      //Then we want to ignore the automatic override
      ignoreOverride = true;
   }
   if (_GetCommentWrapFlags(CW_AUTO_OVERRIDE, CW_p_LangId) && !ignoreOverride) {
      //If we have an analyzed width, use it
      int rMargin = CW_analyzedWidth;
      if (!fallBackToFixed) {
         if (_GetCommentWrapFlags(CW_MAX_RIGHT_DYN, CW_p_LangId) && (rMargin == 0 || rMargin > _GetCommentWrapFlags(CW_MAX_RIGHT_COLUMN_DYN, CW_p_LangId))) {
            //return(_GetCommentWrapFlags(CW_MAX_RIGHT_COLUMN_DYN));
            rMargin = (_GetCommentWrapFlags(CW_MAX_RIGHT_COLUMN_DYN, CW_p_LangId));
         }
         if (rMargin < CW_commentBorderLeftCol) {
            message('Unable to wrap this comment with current settings.');
            return(0);
         }
         return(rMargin);
      } else {
         if (rMargin > 0) {
            return (rMargin);
         }
      }
   }

   if (_GetCommentWrapFlags(CW_USE_FIXED_MARGINS, CW_p_LangId)) {
      int rMargin = _GetCommentWrapFlags(CW_RIGHT_MARGIN, CW_p_LangId);
      if (rMargin < CW_commentBorderLeftCol) {
         message('Unable to wrap this comment with current settings.');
         return(0);
      }
      return (rMargin);
   }
   if (_GetCommentWrapFlags(CW_USE_FIXED_WIDTH, CW_p_LangId)) {
      int widthSize = _GetCommentWrapFlags(CW_FIXED_WIDTH_SIZE, CW_p_LangId);
      int rMargin = CW_commentBorderLeftCol + widthSize - 1;
      if (_GetCommentWrapFlags(CW_MAX_RIGHT, CW_p_LangId)) {
         if (rMargin > _GetCommentWrapFlags(CW_MAX_RIGHT_COLUMN, CW_p_LangId)) {
            rMargin = _GetCommentWrapFlags(CW_MAX_RIGHT_COLUMN, CW_p_LangId);
         }
      }
      if (rMargin < CW_commentBorderLeftCol) {
         message('Unable to wrap this comment with current settings.');
         return(0);
      }
      return (rMargin);
   }
   if (_GetCommentWrapFlags(CW_USE_FIRST_PARA, CW_p_LangId)) {
      int returnVal = CW_analyzedWidth;
      if (_GetCommentWrapFlags(CW_MAX_RIGHT_DYN, CW_p_LangId) && (returnVal == 0 || returnVal > _GetCommentWrapFlags(CW_MAX_RIGHT_COLUMN_DYN, CW_p_LangId))) {
         return (_GetCommentWrapFlags(CW_MAX_RIGHT_COLUMN_DYN, CW_p_LangId));
      }
      return (CW_analyzedWidth);
   }
   return (0);

}

/**
 * Stores the comment borders settings for the given comment type into the given 
 * BlockCommentSettings_t variable.
 * 
 * @param commentSettings  Struct in which to store the settings
 * @param commentType      Comment type settings to store
 * 
 * @return boolean
 */
static boolean CW_storeCommentSettings(BlockCommentSettings_t &commentSettings, int commentType) {
   switch (commentType) {
   case (CW_JAVADOCCOMMENT):
      //Set comment settings to Javadoc style
      commentSettings.firstline_is_top = commentSettings.lastline_is_bottom = false;
      commentSettings.tlc =    JAVADOC_PREFIX;
      commentSettings.brc = JAVADOC_END_PREFIX;
      commentSettings.lvside = commentSettings.blc = _GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_AUTO_JAVADOC_ASTERISK) ? JAVADOC_LEFT_ASTERISK : JAVADOC_LEFT_NO_ASTERISK;
      commentSettings.bhside = commentSettings.thside = commentSettings.rvside = commentSettings.trc = "";
      break;
   case (CW_FULLBLOCKCOMMENT):
      CW_getCommentSettings(commentSettings);
      break;
   case (CW_XMLDOCCOMMENT):
   case (CW_LINECOMMENTBLOCK):
      //Set comment settings
      if (CW_lineCommentLeft == '') {
         typeless dummy1, dummy2;
         //This will recalculate the left border of a line comment.
         CW_inLineCommentBlock(dummy1, dummy2);
      }
      commentSettings.firstline_is_top = commentSettings.lastline_is_bottom = true;
      commentSettings.tlc = commentSettings.lvside = commentSettings.blc = CW_lineCommentLeft;
      commentSettings.brc = commentSettings.bhside = commentSettings.thside = commentSettings.rvside = commentSettings.trc = "";
      break;
   case (CW_FUNDAMENTALMODE):
      //Set comment settings to XMLdoc style
      commentSettings.firstline_is_top = commentSettings.lastline_is_bottom = true;
      commentSettings.tlc = commentSettings.lvside = commentSettings.blc = "";
      commentSettings.brc = commentSettings.bhside = commentSettings.thside = commentSettings.rvside = commentSettings.trc = "";
      break;
   default:
      return (false);
      break;
   }
   return (true);
}

/**
 * Checks to see if the cursor is on a space or tab
 * 
 * @return boolean True if on space or tab.
 */
static boolean CW_cursorOnWhitespace() {
   return ((get_text_raw() != ' ') && (get_text_raw() != "\t"));
}

/**
 * Checks that what is stored in CW_commentSettings for TLC and BRC is valid to
 * delineate the comment block.
 * 
 * If CW_commentSettings.tlc is not found at start of comment, 
 * set CW_commentSettings.tlc to what was found in the code, 
 * CW_commentTLCstr.  Same for end sequence.
 * 
 * @param startPos Start position of the comment
 * @param endPos   End position of the comment
 */
static void CW_analyzeStartAndEndSeq(typeless startPos, typeless endPos) {
   typeless p; save_pos(p);
   //Check starting string
   restore_pos(startPos);
   _str line; get_line_raw(line);
   int pysCol = text_col(line, p_col, 'P');
   //Could just use get_text() instead.
   if (substr(line, pysCol, length(strip(CW_commentSettings.tlc, 'L'))) != strip(CW_commentSettings.tlc, 'L')) {
      CW_commentSettings.tlc = CW_commentTLCstr;
   }
   //Check ending string
   restore_pos(endPos);
   get_line_raw(line);
   _str endSeq = strip(CW_commentSettings.brc, 'T');
   int endSearchStartCol = text_col(line' ', p_col, 'P') - length(endSeq);
   if (endSearchStartCol < 1) {
      CW_commentSettings.brc = CW_commentBRCstr;
   } else if (substr(line, endSearchStartCol, length(endSeq)) != endSeq) {
      CW_commentSettings.brc = CW_commentBRCstr;
   }
   restore_pos(p);
   return;
}

/**
 * Try to analyze the width of block comment when using automatic width 
 * determination for comment wrap.
 * 
 * @param commentType   Type of comment to analyze
 * @param startLine     Line number of first line of comment
 * @param endLine       Line number of last liine of comment
 */
static void CW_analyzeWidth(int commentType, int startLine, int endLine) {
   int origLine = p_line;
   boolean isBlank;
   boolean allBlank = false;
   typeless p; save_pos(p);
   //Adding a quick test for no content.
   if (!CW_analyzedWidth && (_GetCommentWrapFlags(CW_USE_FIRST_PARA, CW_p_LangId) || _GetCommentWrapFlags(CW_AUTO_OVERRIDE, CW_p_LangId))) {
      boolean isMultiLine = false;
      p_line = startLine;
      _str dummyStr; int rightMostCol = 1; int afterBulletCol = 1, prevRMC;
      allBlank = true;
      while (p_line <= endLine) {
         prevRMC = rightMostCol;
         CW_extractBCLineText(dummyStr, startLine, endLine, rightMostCol, afterBulletCol);
         //Adding a quick hack to test for no content.  This would mean a new comment 02/22/06
         isBlank = CW_isBCBlankLine(startLine, endLine);
         allBlank = (allBlank && isBlank);
         if ((!isBlank) && (!CW_isParaStart(commentType, startLine, endLine))) {
            isMultiLine = true;
            if (rightMostCol > CW_analyzedWidth) {
               CW_analyzedWidth = rightMostCol;
            }
            if (prevRMC > CW_analyzedWidth) {
               CW_analyzedWidth = prevRMC;
            }
         } 
         if (down(1)) {
            break;
         }
      }
      if (!isMultiLine) {
         CW_analyzedWidth = 0;
      }
   }
   restore_pos(p);
   //If all blank lines, then no content, so assume this is a new comment
   if (allBlank) {
      CW_inNewComment = true;
   }

   return;
}

/**
 * If the comment is a doxygen comment pair, 
 * adjusts the start column to the start of the first comment in 
 * the pair. 
 */
static void doxygen_comment_pair_update_start_col(typeless startPos, int& startCol)
{
   if (CW_isDoxygenCommentPair) {
      save_pos(auto p);
      restore_pos(startPos);
      first_non_blank();
      startCol = p_col;
      restore_pos(p);
   }
}

/**
 * Analyzes a block comment to determine it's borders and width
 * 
 * Must set borders for comment, comment border left column, left margin 
 * columns for the start line, end line, and inner lines.
 * 
 * @param startPos      Start position of the comment
 * @param endPos        End position of the comment
 * @param commentType   Type of the comment to analyze
 * 
 * @return boolean      True if analysis was able to complete
 */
static boolean CW_analyzeBlockComment(typeless startPos, typeless endPos, int commentType, boolean inDoEditKey = false) {
   //say('Analyze');
   if (!CW_isAcceptableCommentType(commentType)) {
      return (false);
   }

   if (commentType == CW_FUNDAMENTALMODE) {
      return CW_analyzeFundamentalMode(startPos, endPos, commentType, inDoEditKey);
   }

   if (commentType == CW_LINECOMMENTBLOCK) {
      return CW_analyzeLineCommentBlock(startPos, endPos, commentType, inDoEditKey);
   }

   typeless startLine, startCol, endLine, endCol;
   parse startPos with startLine startCol .;
   parse endPos with endLine endCol .;
   endCol--;
   CW_numberOfLinesInComment = endLine - startLine + 1;

   doxygen_comment_pair_update_start_col(startPos, startCol);

   //CW_analyzedWidth = 0;
   typeless p; save_pos(p);
   int origLine = p_line;
   if (!CW_storeCommentSettings(CW_commentSettings, commentType)) {
      //When unable to read the comment settings, can not analyze, so return false
      return (false);
   }

   if (commentType == CW_JAVADOCCOMMENT) {
      //Add any special cases for Javadoc here
   }
   if (commentType == CW_XMLDOCCOMMENT) {
      //Add any special cases for XMLdoc here
   }

   //Briefly remove the new character so we can analyze the comment in the state it was before the last key stroke
   _str cursorChar;
   if (inDoEditKey) {
      left(); cursorChar = get_text_raw();
      save_pos(p);
      _delete_text(1);
   }

   //Check that our start and end sequences make sense with what is
   //actually denoting the comment
   CW_analyzeStartAndEndSeq(startPos, endPos);
   //CW_commentSettings.tlc and CW_commentSettings.brc now match what is found in the buffer.

   //Set left border column.  Check for leading spaces in ext settings.
   CW_commentBorderLeftCol = startCol + 1 - verify(CW_commentSettings.tlc, ' ');
   //int imaginaryBorderLeftCol = CW_commentBorderLeftCol;
   if (CW_commentBorderLeftCol < 1) {
      CW_commentSettings.tlc = substr(CW_commentSettings.tlc, (2 - CW_commentBorderLeftCol));
      CW_commentBorderLeftCol = 1;
   }
   CW_commentMarginLeftColStart = startCol + length(strip(CW_commentSettings.tlc, 'L'));
   CW_commentMarginLeftCol = CW_commentBorderLeftCol + length(CW_commentSettings.lvside);
   CW_commentMarginLeftColEnd = CW_commentBorderLeftCol + length(CW_commentSettings.blc);

   _str line;
   int startRMC = 0, endRMC = 0, middleRMC = 0, lastCol = 0, lastColS = 0;
   if (startLine != endLine) {
      if (commentType == CW_FULLBLOCKCOMMENT) {
         CW_analyzeBCStartLine(startLine, endLine, lastColS, CW_commentSettings);
         CW_analyzeBCEndLine(startLine, endLine, CW_commentSettings);
         //CW_analyzeBCMiddleLine(startLine, endLine);
         _str lvside = CW_analyzeBCMiddleLinesLeft(startLine, endLine);
         _str rvside = CW_analyzeBCMiddleLinesRight(startLine, endLine, lastCol);
         //If the right side match column is found at left in area where the left
         //border was found, then set right border to nothing.
         if (lastCol <= CW_commentBorderLeftCol + length(lvside)) {
            rvside = "";
         }
         //Check that we haven't found the same thing for right and left side
         CW_commentSettings.rvside = rvside;
         //say(lastColS' 'lastCol' 'endCol);
         // Try to reconcile the leading and trailing spaces on the border characters
         //Only do this when there is a middle line.
         CW_RBanalyzedWidth = lastColS;
         if (lastCol > CW_RBanalyzedWidth) {
            CW_RBanalyzedWidth = lastCol;
         }
         if (endCol > CW_RBanalyzedWidth && CW_RBanalyzedWidth != 0) {
            CW_RBanalyzedWidth = endCol;
         }
         if (lastColS) {
            CW_commentSettings.trc = strip(CW_commentSettings.trc, 'T');
            if (CW_RBanalyzedWidth > lastColS) {
               strappend(CW_commentSettings.trc, substr('', 1, CW_RBanalyzedWidth - lastColS));
            }
         }
         if (lastCol) {
            CW_commentSettings.rvside = strip(CW_commentSettings.rvside, 'T');
            if (CW_RBanalyzedWidth > lastCol) {
               strappend(CW_commentSettings.rvside, substr('', 1, CW_RBanalyzedWidth - lastCol));
            }
         }
         //Remove extra trailing spaces from left border when not specified
         if (CW_commentSettings.lvside :!= lvside && lvside :!= strip(lvside, 'T')) {
            lvside = field(strip(lvside, 'T'), length(CW_commentSettings.tlc));
         }
         CW_commentSettings.lvside = lvside;
      }
      if (commentType == CW_JAVADOCCOMMENT) {
         CW_analyzeJavadoc(startLine, endLine);
      }

      CW_commentMarginLeftCol = CW_commentBorderLeftCol + length(CW_commentSettings.lvside);
      CW_commentMarginLeftColEnd = CW_commentBorderLeftCol + length(CW_commentSettings.blc);

      //Try to dynamically determine width
      restore_pos(p);
      CW_analyzeWidth(commentType, startLine, endLine);

   } else {
      //Case of one-line block comment.  Assume that content can exist on first
      //and last lines.  Leave all other border settings unchanged from user 
      //settings except for special case below.
      CW_commentSettings.firstline_is_top = CW_commentSettings.lastline_is_bottom = true;
      get_line(line); line = strip(line);
      if (CW_commentSettings.tlc != substr(line, 1, CW_commentSettings.tlc._length())) {
         CW_commentSettings.tlc = '/*';
      }
      if (CW_commentSettings.brc != substr(line, line._length() - CW_commentSettings.brc._length() + 1, CW_commentSettings.brc._length())) {
         CW_commentSettings.brc = '*/';
      }
      CW_analyzeWidth(commentType, startLine, endLine);
   }

   restore_pos(p);
   if (inDoEditKey) {
      _insert_text_raw(cursorChar);
   }            
   //saySettings(commentType);
   return(true);
}

/**
 * Analyzes a fundamental mode document to determine it's borders and
 * width.
 * 
 * Must set borders for comment, comment border left column, left margin 
 * columns for the start line, end line, and inner lines.
 * 
 * @param startPos      Start position of the comment
 * @param endPos        End position of the comment
 * @param commentType   Type of the comment to analyze
 * 
 * @return boolean      True if analysis was able to complete
 */
static boolean CW_analyzeFundamentalMode(typeless startPos, typeless endPos, int commentType, boolean inDoEditKey = false) {
   typeless startLine, startCol, endLine, endCol;
   parse startPos with startLine startCol .;
   parse endPos with endLine endCol .;
   endCol--;
   CW_numberOfLinesInComment = endLine - startLine + 1;

   //CW_analyzedWidth = 0;
   typeless p; save_pos(p);
   int origLine = p_line;
   if (!CW_storeCommentSettings(CW_commentSettings, commentType)) {
      //When unable to read the comment settings, can not analyze, so return false
      return (false);
   }

   //Briefly remove the new character so we can analyze the comment in the state it was before the last key stroke
   _str cursorChar;
   if (inDoEditKey) {
      left(); cursorChar = get_text_raw();
      _delete_text(1);
      save_pos(p);
   }

   //Set left border column and margin columns.
   CW_commentBorderLeftCol = startCol;
   CW_commentMarginLeftColStart = CW_commentBorderLeftCol;// + length(CW_commentSettings.tlc);
   CW_commentMarginLeftCol = CW_commentBorderLeftCol;// + length(CW_commentSettings.lvside);
   CW_commentMarginLeftColEnd = CW_commentBorderLeftCol;// + length(CW_commentSettings.blc);

   CW_analyzeWidth(commentType, startLine, endLine);

   restore_pos(p);
   if (inDoEditKey) {
      _insert_text_raw(cursorChar);
   }            
   //saySettings(commentType);
   //say('StartLine 'startLine' EndLine 'endLine);
   return(true);
}

/**
 * Analyzes a line comment block to determine it's borders and width
 * 
 * Must set borders for comment, comment border left column, left margin 
 * columns for the start line, end line, and inner lines.
 * 
 * @param startPos      Start position of the comment
 * @param endPos        End position of the comment
 * @param commentType   Type of the comment to analyze
 * 
 * @return boolean      True if analysis was able to complete
 */
static boolean CW_analyzeLineCommentBlock(typeless startPos, typeless endPos, int commentType, boolean inDoEditKey = false) {
   typeless startLine, startCol, endLine, endCol;
   parse startPos with startLine startCol .;
   parse endPos with endLine endCol .;
   endCol--;
   CW_numberOfLinesInComment = endLine - startLine + 1;

   //CW_analyzedWidth = 0;
   typeless p; save_pos(p);
   int origLine = p_line;
   if (!CW_storeCommentSettings(CW_commentSettings, commentType)) {
      //When unable to read the comment settings, can not analyze, so return false
      return (false);
   }

   //Briefly remove the new character so we can analyze the comment in the state it was before the last key stroke
   _str cursorChar;
   if (inDoEditKey) {
      left(); cursorChar = get_text_raw();
      _delete_text(1);
      save_pos(p);
   }

   //Set left border column and margin columns.
   CW_commentBorderLeftCol = startCol;
   CW_commentMarginLeftColStart = CW_commentBorderLeftCol + length(CW_commentSettings.tlc);
   CW_commentMarginLeftCol = CW_commentBorderLeftCol + length(CW_commentSettings.lvside);
   CW_commentMarginLeftColEnd = CW_commentBorderLeftCol + length(CW_commentSettings.blc);

   CW_analyzeWidth(commentType, startLine, endLine);

   restore_pos(p);
   if (inDoEditKey) {
      _insert_text_raw(cursorChar);
   }            
   //saySettings(commentType);
   return(true);
}

/**
 * Analyzes Javadoc structure to check and help handle oddly formatted Javadoc 
 * comments.
 * 
 * @param startLine  Line number of start of comment
 * @param endLine    Line number of end of comment
 */
static void CW_analyzeJavadoc (int startLine, int endLine) {

   p_line = startLine;
   first_non_blank(); 
   CW_commentBorderLeftCol = p_col;
   CW_commentMarginLeftColStart = CW_commentBorderLeftCol + 4;//DOB or should this be 3
   if (strip(CW_getLineFromColumn()) != _rawText('/**')) {
      CW_commentSettings.firstline_is_top = true;
      p_col += 3;
      if (get_text(1) != " " && get_text(1) != "\t") {
         CW_commentMarginLeftColStart = CW_commentBorderLeftCol + 3;
      }
   }
   p_line = endLine;
   _str line; get_line_raw(line);
   if (strip(line) != _rawText('*/')) {
      CW_commentSettings.lastline_is_bottom = true;
      line = strip(line, 'T');
      if ((length(line) > 2) && (substr(line, length(line)-2, 3) == _rawText(' */'))) {
         CW_commentSettings.brc = _rawText(' */');
      }
      else CW_commentSettings.brc = _rawText('*/');
   } else {
      first_non_blank();
      if (p_col > CW_commentBorderLeftCol) {
         CW_commentSettings.brc = _rawText(' */');
      }
      else CW_commentSettings.brc = _rawText('*/');
   }

   if (startLine + 1 < endLine){
      int minStarCol = -1;
      int minContentCol = -1;
      int contCol;
      _str lvside = '';
      boolean noSpaceAfterStar = false;
      int totalLeftStars = 0;
      // To determine the number of stars on the left on inner lines, take the
      // average number found on the inner lines with stars.
      for (p_line = startLine + 1; p_line < endLine; ){
         line = _expand_tabsc();
         first_non_blank();
         if (get_text() == '*' && (minStarCol == -1 || p_col < minStarCol)) {
            minStarCol = p_col;
         }
         contCol = verify(line, " *");
         if (contCol && (minContentCol == -1 || contCol < minContentCol)) {
            minContentCol = contCol;
         }
         if (pos("^\\*#", strip(line, 'L')' ', 1, 'R')) {
            totalLeftStars += pos('');
         }
         if (down()) break;
      }
      if (startLine + 1 < endLine) {
         //A simple average should work in most cases to pick a reasonable number of
         //stars to preserve while allowing a little variation.
         totalLeftStars = (int)round(((double)totalLeftStars)/((double)(endLine - (startLine + 1))), 0);
      }
      if (minStarCol < CW_commentBorderLeftCol) {
         minStarCol = CW_commentBorderLeftCol;
      }
      if (minStarCol + totalLeftStars > minContentCol) {
         minContentCol = minStarCol + totalLeftStars;
      }
      if (totalLeftStars) {
         CW_commentSettings.lvside = substr('', 1, minStarCol - CW_commentBorderLeftCol) :+ substr('', 1, totalLeftStars, '*');
         if (minContentCol > minStarCol + totalLeftStars) {
            strappend(CW_commentSettings.lvside, ' ');
         }
      } else {
         CW_commentSettings.lvside = substr('', 1, (minContentCol - CW_commentBorderLeftCol > 3)?3:(minContentCol - CW_commentBorderLeftCol) );
      }
      CW_commentSettings.blc = CW_commentSettings.lvside;
      CW_commentMarginLeftCol = CW_commentMarginLeftColEnd = CW_commentBorderLeftCol + length(CW_commentSettings.lvside);

   }

}
/**
 * 
 * @param startLine
 * @param endLine
 * 
 * @return boolean  Return true if there is a border on start line
 */
static boolean CW_analyzeBCStartLine (int startLine, int endLine, int& lastCol, BlockCommentSettings_t& commentSettings) {
   //Goto start line
   //Analyze the first line of the comment
   p_line = startLine;
   //Do analysis of start line
   _str line; get_line(line);
   int startRMC = text_col(strip(line, 'T'), length(strip(line, 'T')), 'I');
   line = strip(line,'L');
   //Remove start sequence
   line = substr(line, length(strip(CW_commentSettings.tlc, 'L')) + 1);
   line = strip(line,'T');
   _str tempTRC = strip(CW_commentSettings.trc, 'T');
   //Try to match to settings for top right corner.
   if (length(line) >= length(tempTRC)) {
      if (substr(line, length(line) - length(tempTRC) + 1) :== tempTRC) {
         line = substr(line, 1, length(line) - length(tempTRC));
      } else {
         CW_commentSettings.trc = '';
      }
   } else {
      CW_commentSettings.trc = '';
   }
   //Stripped off identifiable TLC and TRC of top line.
   //Is the remainder content or border?
   if (strip(line) == '') {
      CW_commentSettings.thside = '';
      CW_commentSettings.firstline_is_top = false;
   } else {
      //Are there blanks in start line content.  If so, then it's content, not border
      if (!verify(line, " \t", 'M') && !isalnum(last_char(line))) {
         //No blanks or tab, assume a top border
         CW_commentSettings.firstline_is_top = false;
         HborderSplit(line, CW_commentSettings.tlc, CW_commentSettings.thside, CW_commentSettings.trc);
         if (CW_commentSettings.trc != '') lastCol = startRMC;
         return (true);
      } else {
         //found a blank or tab, so it is content
         CW_commentSettings.firstline_is_top = true;
         CW_commentSettings.thside = '';
      }
   }
   if (CW_commentSettings.trc != '') lastCol = startRMC;
   return (false);
}

static void HborderSplit(_str content, _str& LHS, _str& middle, _str& RHS) {
   int contentLen = length(content);
   if (!contentLen) {
      return;
   }
   if (contentLen == 1) {
      middle = content;
      return;
   }
   middle = substr(content, contentLen / 2, 1);
   int i;
   for (i = 1; substr(content, i, 1) != middle; i++) {
   }
   strappend(LHS, substr(content, 1, i - 1));
   for (i = contentLen / 2 + 1; substr(content, i, 1) == middle; i++) {
   }
   if (i <= contentLen) {
      RHS = substr(content, i) :+ RHS;
   }
}

/**
 * Tries to indentify the case where a single identifier 
 * starting with an non-alphanumeric char (most likely _ or -). 
 * This is a helper for CW_analyzeBCEndLine. 
 * 
 * @param line line starting with the canidate
 * 
 * @return bool True if it looks like it could be an identifier. 
 *         (opposed to some punctuation that could be a comment
 *         border).
 */
static boolean looks_like_identifier(_str line)
{
   int s = pos('^[-_.:0-9]+[a-zA-Z_-0-9]+', line, 1, 'U');

   return s > 0;
}

/**
 * 
 * @param startLine
 * @param endLine
 * 
 * @return boolean   Return true if end line has a border.
 */
static boolean CW_analyzeBCEndLine (int startLine, int endLine, BlockCommentSettings_t& commentSettings) {
   p_line = endLine;
   //Do analysis of end line
   _str line; get_line(line);line = strip(line, 'T');
   //Remove end sequence
   line = strip(substr(line, 1, length(line) - length(strip(CW_commentSettings.brc, 'T'))));
   line = strip(line,'L');
   _str tempBLC = strip(CW_commentSettings.blc, 'L');
   if (substr(line, 1, length(tempBLC)) :== tempBLC) {
      line = substr(line, length(tempBLC) + 1);
   } else {
      CW_commentSettings.blc = '';
   }
   if (strip(line) == '') {
      CW_commentSettings.bhside = '';
      CW_commentSettings.lastline_is_bottom = false;
   } else {
      //Are there blanks in end line content.  If so, then it's content, not border
      if (!verify(line, " \t", 'M') && !isalnum(substr(strip(line, 'L'), 1, 1))
          && !looks_like_identifier(line)) {
         //No blanks or tab, assume a bottom border
         CW_commentSettings.lastline_is_bottom = false;
         HborderSplit(line, CW_commentSettings.blc, CW_commentSettings.bhside, CW_commentSettings.brc);
         return (true);
      } else {
         //found a blank or tab, so it is content
         CW_commentSettings.lastline_is_bottom = true;
         CW_commentSettings.bhside = '';
      }
   }
   return (false);
}

static _str CW_longestMatch(_str s1, _str s2) {
   int i;
   int len = length(s1);
   int len2 = length(s2);
   if (len == 0 || len2 == 0) {
      return ('');
   }
   if (len2 < len) {
      if (substr(s1, 1, len2) :== s2) {
         return (s2);
      }
      len = len2;
   } else {
      if (substr(s2, 1, len) :== s1) {
         return (s1);
      }
   }
   int matchLen = 0;
   for(i = 1; i <= len; i++) {
       if(substr(s1, 1, i) :!= substr(s2, 1, i)) {
          matchLen = i - 1;
          break;
       }
   }
   if (matchLen) {
      return (substr(s1, 1, matchLen));
   }
   return ('');
}

static _str CW_longestMatchR(_str s1, _str s2) {
   int i;
   int len = 0;
   int len1 = length(s1);
   int len2 = length(s2);
   if (len1 == 0 || len2 == 0) {
      return ('');
   }
   if (len2 < len1) {
      if (substr(s1, len1 - len2 + 1, len2) :== s2) {
         return (s2);
      }
      len = len2;
   } else {
      if (substr(s2, len2 - len1 + 1, len1) :== s1) {
         return (s1);
      }
      len = len1;
   }
   int matchLen = 0;
   for(i = 1; i <= len; i++) {
       if(substr(s1, len1 - i + 1, i) :!= substr(s2, len2 - i + 1, i)) {
          matchLen = i - 1;
          break;
       }
   }
   if (matchLen) {
      return (substr(s1, len1 - matchLen + 1, matchLen));
   }
   return ('');
}

static int CW_justSpaces(_str input) {
   if (input == '' && length(input)) {
      return (length(input));
   }
   return (0);
}

/**
 * Finds the left border of a block comment.
 * Looks for the longest match at start of all lines.
 * 
 * @param startLine
 * @param endLine
 * 
 * @return _str
 */
static _str CW_analyzeBCMiddleLinesLeft (int startLine, int endLine) {

   if (startLine + 1 >= endLine) {
      return (CW_commentSettings.lvside);
   }
   _str match, current, s1, returnVal = '';

   p_line = startLine + 1;
   s1 = CW_getWordFromColumn(CW_commentBorderLeftCol, true);
   if (startLine + 2 == endLine) {
      //If just one line of inner content
      if (CW_isBorderChar(s1, CW_commentSettings.lvside, true)) {
         returnVal = s1;
      } else {
         returnVal = '';
      }
   } else {
      match = s1;
      for (p_line = startLine + 2;p_line < endLine && match :!= ''; down()) {
         current = CW_getWordFromColumn(CW_commentBorderLeftCol, true);
         match = CW_longestMatch(match, current);
      }
      if (CW_isBorderChar(match, CW_commentSettings.lvside, true)) {
         returnVal = match;
      } else {
         returnVal = '';
      }
   }
   if (CW_commentSettings.lastline_is_bottom) {
      p_line = endLine;
      current = CW_getWordFromColumn(CW_commentBorderLeftCol, true);
      if (strip(returnVal, 'T') :== strip(current, 'T')) {
         CW_commentSettings.blc = current;
      }
   }
   return (returnVal);
}

/**
 * Finds the right border of a block comment. Looks for the longest match at end
 * of all middle lines.
 * 
 * @param startLine
 * @param endLine
 * 
 * @return _str
 */
static _str CW_analyzeBCMiddleLinesRight (int startLine, int endLine, int& endCol) {

   if (startLine + 1 >= endLine) {
      return (CW_commentSettings.rvside);
   }
   _str match, current, s1;

   p_line = startLine + 1;
   s1 = CW_getLastWord(endCol, true);
   if (startLine + 2 == endLine) {
      //If just one line of inner content
      if (CW_isBorderChar(s1, CW_commentSettings.rvside, false)) {
         return (s1);
      }
      endCol = 0;
      return ('');
   }

   int tempEndCol = 0;
   match = s1;
   for (p_line = startLine + 2;p_line < endLine /*&& match :!= ''*/; down()) {
      current = CW_getLastWord(tempEndCol, true);
      match = CW_longestMatchR(match, current);
      if (tempEndCol > endCol) {
         endCol = tempEndCol;
      }
   }
   if (match != '' && CW_isBorderChar(match, CW_commentSettings.rvside, false)) {
      return (match);
   }
   endCol = 0;
   return ('');
}

static void CW_analyzeBCMiddleLine (int startLine, int endLine) {
   if (endLine > startLine + 1) {

   }
   if (startLine + 1 < endLine) {
      _str fword, lword;
      int fcol, lcol;
      p_line = startLine + 1;
      _str line; get_line(line);strip(line, 'T');
      //determine left side border
      if (CW_commentSettings.lvside == '' && length(CW_commentSettings.lvside) > 0) {
         //Case of left border just being blanks
         if (line != '') {
            //if non-blank line, then check if enough space before content
            first_non_blank(); 
            int leadblanks = p_col - CW_commentBorderLeftCol;
            if (length(CW_commentSettings.lvside) > leadblanks) {
               CW_commentSettings.lvside = substr(' ', 1, leadblanks);
            }
         } //else keep lvside as blanks
      } else {
         //Check middle lines
         //if line starts with settings for lvside, use that, else try to determine
         first_non_blank();
         fcol = p_col;
         _str frontStrippedLvside = strip(CW_commentSettings.lvside, 'L');
         if (get_text(length(frontStrippedLvside)) != frontStrippedLvside) {
            CW_firstWordAndCol(line, fword, fcol);
            if (CW_isBorderChar(fword, CW_commentSettings.lvside, true) && fcol) {
               first_non_blank(); 
               if (p_col >= CW_commentBorderLeftCol && p_col < CW_commentBorderLeftCol + length(CW_commentSettings.tlc)) {
                  CW_commentSettings.lvside = substr(' ', 1, p_col - CW_commentBorderLeftCol) :+ fword;
               }
            } else CW_commentSettings.lvside = '';
         }
      }
      //determine right border
      CW_last_word_and_col(line, lword, lcol);
      if (CW_isBorderChar(lword, CW_commentSettings.rvside, false) && lcol && (lcol > fcol)) {
         CW_commentSettings.rvside = lword;
         CW_analyzedWidth =  CW_RBanalyzedWidth = lcol + length(lword) - 1;
      } else {
         CW_commentSettings.rvside = '';
         CW_RBanalyzedWidth = 0;
      }
   }
}

/**
 * Determines if a word resembles a comment left or right border.
 * 
 * @param word          String to check if it resembles a border sequence
 * @param matchBorder   If <i>word</i> matches this known border type sequence,
 *                      return true.
 * 
 * @return boolean      Return true if word matches <i>matchBorder</i> or if word 
 *                      resembles a border sequence.
 */
static boolean CW_isBorderChar(_str& word, _str matchBorder, boolean leftBorder) {
   if (leftBorder) {
      if ((length(matchBorder) && length(matchBorder) <= length(word) && substr(word, 1, length(matchBorder)) :== matchBorder) ||
          (length(matchBorder) == 0 && word == '')) {
         word = matchBorder;
         return(true);
      }
   }
   else {
      matchBorder = strip(matchBorder, 'T');
      if ((length(matchBorder) && length(matchBorder) <= length(word) && substr(word, length(word) - length(matchBorder) + 1) :== matchBorder) ||
          (length(matchBorder) == 0 && word == '')) {
         word = matchBorder;
         return(true);
      } else {
         //leave at most one space at start of border, if dynamically found and is a right border
         if (length(word) && substr(word, 1, 1) :== ' ') {
            word = ' ' :+ strip(word, 'L');
         }
      }
   }
   _str word2 = strip(word);
   if (length(word2) > 5) {
      return (false);
   }
   return (!isalnum(substr(word2, 1, 1)) && !isalnum(substr(word2, 2, 1)) && !isalnum(substr(word2, 3, 1)) && !isalnum(substr(word2, 4, 1)) && !isalnum(substr(word2, 5, 1)));
}

/**
 * For the given string representing a line of text, grabs the last space or tab 
 * separated word and also returns editor column of first character of last word
 * 
 * @param line       The line of text from which to pull the first word
 * @param firstWord  Reference: Receives text of first word
 * @param firstCol   Reference: Receives imaginary column number of start of 
 *                   word
 */
static void CW_last_word_and_col(_str line, _str &lastWord, int &lastCol) {
   lastCol = lastpos("([ \t][^ \t])", line, '', 'U');
   if ( ! lastCol ) {
      lastCol = 0;
      lastWord = '';
      return;
   }
   lastWord = strip(substr(line, lastCol + 1));
   lastCol = text_col(line, lastCol + 1, 'I');
   return;
}

/**
 * For the given string representing a line of text, grabs the first space or 
 * tab separated word and also returns editor column of first character of first
 * word.
 * 
 * @param line       The line of text from which to pull the first word
 * @param firstWord  Reference: Receives text of first word
 * @param firstCol   Reference: Receives imaginary column number of start of 
 *                   word
 */
static void CW_firstWordAndCol(_str line, _str &firstWord, int &firstCol) {
   firstCol = pos("([^ \t][ \t])|([^ \t]$)", line, '', 'U');
   if ( ! firstCol ) {
      firstCol = 0;
      firstWord = '';
      return;
   }
   firstWord = strip(substr(line, 1, firstCol));
   firstCol = text_col(line, firstCol, 'I') - length(firstWord) + 1;
   return;
}

static void saySettings(int commentType, BlockCommentSettings_t CB = CW_commentSettings) {
   if (commentType == CW_NOTCOMMENT) {
      return;
   }
   if (commentType == CW_JAVADOCCOMMENT) {
      say('J 'CW_commentBorderLeftCol' 'CW_commentMarginLeftColStart' 'CW_commentMarginLeftCol' 'CW_commentMarginLeftColEnd);
   } else if (commentType == CW_LINECOMMENTBLOCK) {
      say('L 'CW_commentBorderLeftCol' 'CW_commentMarginLeftColStart' 'CW_commentMarginLeftCol' 'CW_commentMarginLeftColEnd);
   } else
   say('B 'CW_commentBorderLeftCol' 'CW_commentMarginLeftColStart' 'CW_commentMarginLeftCol' 'CW_commentMarginLeftColEnd);
   //say(startLine' 'startCol' 'endLine' 'endCol);
   say('|'CB.tlc'|'CB.thside'|'CB.trc'|');
   _str t = CB.firstline_is_top ? ' Y ' : ' N ';
   _str b = CB.lastline_is_bottom ? ' Y ' : ' N ';
   say('|'CB.lvside'|'t b'|'CB.rvside'|');
   say('|'CB.blc'|'CB.bhside'|'CB.brc'|');
   say('---------------------------------------');
}

defeventtab _reflow_comment_form;
void _ctl_RC_selection.lbutton_up()
{
   RC_adjustControls();
}
void _ctl_RC_current_para.lbutton_up()
{
   RC_adjustControls();
}
void _ctl_RC_entire.lbutton_up()
{
   RC_adjustControls();
}
void _ctl_RC_use_fixed_width.lbutton_up() {
   RC_adjustWidthControls();
}
void _ctl_RC_use_first_para.lbutton_up() {
   RC_adjustWidthControls();
}
void _ctl_RC_use_fixed_margins.lbutton_up() {
   RC_adjustWidthControls();
}
static void RC_adjustWidthControls() {
   boolean enabled = false;
   _ctl_RC_fixed_width_size.p_enabled     = enabled;
   _ctl_RC_fixed_width_spin.p_enabled     = enabled;
   _ctl_RC_max_right_column.p_enabled     = enabled;
   _ctl_RC_max_right_size.p_enabled       = enabled;
   _ctl_RC_max_right_spin.p_enabled       = enabled;
   _ctl_RC_max_right_column_dyn.p_enabled = enabled;
   _ctl_RC_max_right_size_dyn.p_enabled   = enabled;
   _ctl_RC_max_right_spin_dyn.p_enabled   = enabled;
   _ctl_RC_right_margin_label.p_enabled   = enabled;
   _ctl_RC_right_margin.p_enabled         = enabled;
   _ctl_RC_right_margin_spin.p_enabled    = enabled;

   enabled = true;
   if (_ctl_RC_use_fixed_width.p_enabled && _ctl_RC_use_fixed_width.p_value) {
      _ctl_RC_fixed_width_size.p_enabled     = enabled;
      _ctl_RC_fixed_width_spin.p_enabled     = enabled;
      _ctl_RC_max_right_column.p_enabled     = enabled;
      _ctl_RC_max_right_size.p_enabled       = enabled;
      _ctl_RC_max_right_spin.p_enabled       = enabled;

   } else if (_ctl_RC_use_fixed_margins.p_enabled && _ctl_RC_use_fixed_margins.p_value) {
      _ctl_RC_right_margin_label.p_enabled   = enabled;
      _ctl_RC_right_margin.p_enabled         = enabled;
      _ctl_RC_right_margin_spin.p_enabled    = enabled;

   } else if (_ctl_RC_use_first_para.p_enabled && _ctl_RC_use_first_para.p_value) {
      _ctl_RC_max_right_column_dyn.p_enabled = enabled;
      _ctl_RC_max_right_size_dyn.p_enabled   = enabled;
      _ctl_RC_max_right_spin_dyn.p_enabled   = enabled;
   }
}

static boolean enableMatchBox = false;
static void RC_adjustControls() {
   _ctl_RC_match_settings.p_enabled = (enableMatchBox) && (_ctl_RC_entire.p_value ? 1 : 0);
}
void _reflow_comment_form.on_create()
{
   _ctl_RC_use_first_para.p_value = 1;
   _ctl_RC_use_fixed_width.p_value = 0;
   _ctl_RC_use_fixed_margins.p_value = 0;
   _ctl_RC_entire.p_value = 0;
   _ctl_RC_current_para.p_value = 1;
   _ctl_RC_selection.p_value = 0;
}

//Temporary variables used in loading settings into the _reflow_comment_for
//dialog box.
static _str RC_fixed_width_size     = 64;
static _str RC_right_margin         = 80;
static int  RC_max_right_column     = 1;
static _str RC_max_right_size       = 80;
static int  RC_max_right_column_dyn = 1;
static _str RC_max_right_size_dyn   = 80;
static int  RC_use_fixed_width      = 1;
static int  RC_use_first_para       = 0;
static int  RC_use_fixed_margins    = 0;
static int  RC_use_auto_override    = 0;
static int  RC_wrap_block_comment   = 0;
static int  RC_wrap_javadoc         = 0;
void _reflow_comment_form.on_load()
{
//    _ctl_RC_fixed_width_size.p_text      = RC_fixed_width_size;
//    _ctl_RC_right_margin.p_text          = RC_right_margin;
//    _ctl_RC_max_right_column.p_value     = RC_max_right_column;
//    _ctl_RC_max_right_size.p_text        = RC_max_right_size;
//    _ctl_RC_max_right_column_dyn.p_value = RC_max_right_column_dyn;
//    _ctl_RC_max_right_size_dyn.p_text    = RC_max_right_size_dyn;
//    _ctl_RC_use_fixed_width.p_value      = RC_use_fixed_width;
//    _ctl_RC_use_first_para.p_value       = RC_use_first_para;
//    _ctl_RC_use_fixed_margins.p_value    = RC_use_fixed_margins;

   RC_adjustControls();
   RC_adjustWidthControls();
}
void _ctl_CR_reflow_ok.lbutton_up() {

   _str result = '';
   if (_ctl_RC_entire.p_value) {
      result = 'E ';
      if (_ctl_RC_match_settings.p_value && _ctl_RC_match_settings.p_enabled) {
         result = 'M ';
      }
   }
   if (_ctl_RC_current_para.p_value) {
      result = 'P ';
   }
   if (_ctl_RC_selection.p_value) {
      result = 'S ';
   }
   if (_ctl_RC_use_fixed_width.p_value) {
      strappend(result, 'W ');
      int rightMargin = (int)_ctl_RC_fixed_width_size.p_text;
      strappend(result, rightMargin' ');
      if (_ctl_RC_max_right_column.p_value) {
         strappend(result, (int)_ctl_RC_max_right_size .p_text);
      }
   }
   if (_ctl_RC_use_first_para.p_value) {
      strappend(result, 'A ');
      if (_ctl_RC_max_right_column_dyn.p_value) {
         strappend(result, (int)_ctl_RC_max_right_size_dyn .p_text);
      }
   }
   if (_ctl_RC_use_fixed_margins.p_value) {
      strappend(result, 'R ');
      strappend(result, (int)_ctl_RC_right_margin.p_text);
   }

   _save_form_response();
   p_active_form._delete_window(result);
}
void _ctl_CR_reflow_ok.on_create() {
   _retrieve_prev_form();
}

static void RC_storeWrapWidthSettings() {
   RC_fixed_width_size     = _GetCommentWrapFlags(CW_FIXED_WIDTH_SIZE, CW_p_LangId);
   RC_right_margin         = _GetCommentWrapFlags(CW_RIGHT_MARGIN, CW_p_LangId);
   RC_max_right_column     = _GetCommentWrapFlags(CW_MAX_RIGHT, CW_p_LangId) ? 1 : 0;
   RC_max_right_size       = _GetCommentWrapFlags(CW_MAX_RIGHT_COLUMN, CW_p_LangId);
   RC_max_right_column_dyn = _GetCommentWrapFlags(CW_MAX_RIGHT_DYN, CW_p_LangId) ? 1 : 0;
   RC_max_right_size_dyn   = _GetCommentWrapFlags(CW_MAX_RIGHT_COLUMN_DYN, CW_p_LangId);
   RC_use_first_para       = _GetCommentWrapFlags(CW_USE_FIRST_PARA, CW_p_LangId) ? 1 : 0;
   RC_use_fixed_width      = _GetCommentWrapFlags(CW_USE_FIXED_WIDTH, CW_p_LangId) ? 1 : 0;
   RC_use_fixed_margins    = _GetCommentWrapFlags(CW_USE_FIXED_MARGINS, CW_p_LangId) ? 1 : 0;
   RC_use_auto_override    = _GetCommentWrapFlags(CW_AUTO_OVERRIDE, CW_p_LangId) ? 1 : 0;
   RC_wrap_block_comment   = _GetCommentWrapFlags(CW_ENABLE_BLOCK_WRAP, CW_p_LangId) ? 1 : 0;
   RC_wrap_javadoc         = _GetCommentWrapFlags(CW_ENABLE_DOCCOMMENT_WRAP, CW_p_LangId) ? 1 : 0;
}
static void RC_restoreWrapWidthSettings() {
   _SetCommentWrapFlags(CW_FIXED_WIDTH_SIZE, RC_fixed_width_size, CW_p_LangId);
   _SetCommentWrapFlags(CW_RIGHT_MARGIN, RC_right_margin, CW_p_LangId);
   _SetCommentWrapFlags(CW_MAX_RIGHT, RC_max_right_column, CW_p_LangId);
   _SetCommentWrapFlags(CW_MAX_RIGHT_COLUMN, RC_max_right_size, CW_p_LangId);
   _SetCommentWrapFlags(CW_MAX_RIGHT_DYN, RC_max_right_column_dyn, CW_p_LangId);
   _SetCommentWrapFlags(CW_MAX_RIGHT_COLUMN_DYN, RC_max_right_size_dyn, CW_p_LangId);
   _SetCommentWrapFlags(CW_USE_FIRST_PARA, RC_use_first_para, CW_p_LangId);
   _SetCommentWrapFlags(CW_USE_FIXED_WIDTH, RC_use_fixed_width, CW_p_LangId);
   _SetCommentWrapFlags(CW_USE_FIXED_MARGINS, RC_use_fixed_margins, CW_p_LangId);
   _SetCommentWrapFlags(CW_AUTO_OVERRIDE, RC_use_auto_override, CW_p_LangId);
   _SetCommentWrapFlags(CW_ENABLE_BLOCK_WRAP, RC_wrap_block_comment, CW_p_LangId);
   _SetCommentWrapFlags(CW_ENABLE_DOCCOMMENT_WRAP, RC_wrap_javadoc, CW_p_LangId);
}

/**
 * Runs the dialog box which is used to set comment reflow options and 
 * perform reflow block comment.
 * 
 * @see help:reflow comment dialog box
 * 
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */
_command typeless gui_reflow_comment() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{    
//    int was_recording=_macro();
//    _macro_delete_line();

   typeless startPos = 0, endPos = 0;
//    CW_commentType = CW_inBlockComment(startPos, endPos);
//    if (!CW_isAcceptableCommentType(CW_commentType)) {
//       return (1);
//    }

   enableMatchBox = CW_FULLBLOCKCOMMENT == CW_inBlockComment(startPos, endPos);
   RC_storeWrapWidthSettings();
   typeless result=show('-modal _reflow_comment_form',_QROffset());
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }
//    _macro('m',was_recording);
//    _macro_call('reflow_comment', result);
   _str arg1 = '', arg2 = '', arg3 = '', arg4 = '';
   parse result with arg1 arg2 arg3 arg4;
   reflow_comment(arg1, arg2, arg3, arg4);
   return(result);
}

/**
 * Reflows entire comment, single comment paragraph, or selection within a block 
 * comment.
 * 
 * @return int Zero on success
 */
_command int reflow_comment(_str A='P', _str B='A', _str C='', _str D='') name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   if (!_in_comment()) {
      message('Not within a comment');
      return (1);
   }

   _str reflowType = '';
   if (arg(1) == '') {
      return (1);
      reflowType = 'P';
   } //else reflowType = arg(1);

   if (!((arg(1) == 'E') || (arg(1) == 'M') || (arg(1) == 'P') || (arg(1) == 'S'))) {
      message('Invalid arguements');
      return (1);
   }
   if (arg(2) == '' || (arg(3) == '' && arg(2) == 'W') || (arg(3) == '' && arg(2) == 'R')) {
      message('Invalid arguements');
      return (1);
   }

   RC_storeWrapWidthSettings();
   _SetCommentWrapFlags(CW_AUTO_OVERRIDE, 0, CW_p_LangId);
   _SetCommentWrapFlags(CW_ENABLE_BLOCK_WRAP, 1, CW_p_LangId);
   _SetCommentWrapFlags(CW_ENABLE_DOCCOMMENT_WRAP, 1, CW_p_LangId);

   switch (arg(2)) {
   case 'W': 
      _SetCommentWrapFlags(CW_USE_FIXED_WIDTH, 1, CW_p_LangId);
      _SetCommentWrapFlags(CW_USE_FIRST_PARA, 0, CW_p_LangId);
      _SetCommentWrapFlags(CW_USE_FIXED_MARGINS, 0, CW_p_LangId);
      _SetCommentWrapFlags(CW_FIXED_WIDTH_SIZE, arg(3), CW_p_LangId);
      _SetCommentWrapFlags(CW_MAX_RIGHT, 0, CW_p_LangId);
      if (arg(4) != '') {
         _SetCommentWrapFlags(CW_MAX_RIGHT, 1, CW_p_LangId);
         _SetCommentWrapFlags(CW_MAX_RIGHT_COLUMN, arg(4), CW_p_LangId);
      }
      break;
   case 'A': 
      _SetCommentWrapFlags(CW_USE_FIXED_WIDTH, 0, CW_p_LangId);
      _SetCommentWrapFlags(CW_USE_FIRST_PARA, 1, CW_p_LangId);
      _SetCommentWrapFlags(CW_USE_FIXED_MARGINS, 0, CW_p_LangId);
      _SetCommentWrapFlags(CW_MAX_RIGHT_DYN, 0, CW_p_LangId);
      if (arg(3) != '') {
         _SetCommentWrapFlags(CW_MAX_RIGHT_DYN, 1, CW_p_LangId);
         _SetCommentWrapFlags(CW_MAX_RIGHT_COLUMN_DYN, arg(3), CW_p_LangId);
      }
      break;
   case 'R': 
      _SetCommentWrapFlags(CW_USE_FIXED_WIDTH, 0, CW_p_LangId);
      _SetCommentWrapFlags(CW_USE_FIRST_PARA, 0, CW_p_LangId);
      _SetCommentWrapFlags(CW_USE_FIXED_MARGINS, 1, CW_p_LangId);
      _SetCommentWrapFlags(CW_RIGHT_MARGIN, arg(3), CW_p_LangId);
      break;
   }

   if (arg(1) == 'E') {
      RC_entire();
   }
   if (arg(1) == 'M') {
      RC_entire(true);
   }
   if (arg(1) == 'P') {
      RC_paragraph();
   }
   if (arg(1) == 'S') {
      if( !select_active() ) {
         _message_box('No selection active');
         RC_restoreWrapWidthSettings();
         return(1);
      }
      RC_selection();
   }

   RC_restoreWrapWidthSettings();
   return(0);
}

/**
 * Reflows the currently selected section of comment.
 * 
 * @return int
 */
static int RC_selection() {

   int returnVal = checkCommentWrapStatus();
   if (!returnVal) {
      typeless startLine, endLine;
      parse CW_startPos with startLine .;
      parse CW_endPos with endLine .;
      int firstLine = 0, lastLine = 0;

      if (_begin_select()) {
         return(1);
      }
      firstLine = p_line;
      if (_end_select()) {
         return(1);
      }
      lastLine = p_line;
      _deselect();

      int lineNum, preEndLine;
      for (lineNum = firstLine; lineNum <= lastLine; lineNum++) {
         //lastLine may change.  Will change as endLine changes so
         //track endLine changes and apply to lastLine
         preEndLine = endLine;
         while(CW_maybeMerge(lineNum, startLine, endLine)){};
         CW_maybeReflowToNext(lineNum, startLine, endLine, CW_getRightMargin());
         lastLine += (endLine - preEndLine);
      }

      p_line = lastLine;
      _str currentLine = ' ';
      int currentRMC = 0;
      int CafterBulletCol = 1;
      CW_extractBCLineText(currentLine, startLine, endLine, currentRMC, CafterBulletCol);
      p_col = currentRMC + 1;
   }
   //Success
   return(0);
}

/**
 * Reflows current comment paragraph
 * 
 * @return int
 */
static int RC_paragraph() {

   int returnVal = checkCommentWrapStatus();
   if (!returnVal) {
      typeless startLine, endLine;
      parse CW_startPos with startLine .;
      parse CW_endPos with endLine .;
      int firstLine = 0, lastLine = 0;
      if (CW_findParaStartAndEnd(firstLine, lastLine)) {
         return (1);
      }
      int lineNum, preEndLine;
      for (lineNum = firstLine; lineNum <= lastLine; lineNum++) {
         //lastLine may change.  Will change as endLine changes so
         //track endLine changes and apply to lastLine
         preEndLine = endLine;
         while(CW_maybeMerge(lineNum, startLine, endLine)){};
         CW_maybeReflowToNext(lineNum, startLine, endLine, CW_getRightMargin());
         lastLine += (endLine - preEndLine);
      }
   }
   //Success
   return(0);
}

static CW_copyCommentSettings(BlockCommentSettings_t& A, BlockCommentSettings_t B) {
   A.tlc = B.tlc;
   A.thside = B.thside;
   A.trc = B.trc;
   A.lvside = B.lvside;
   A.rvside = B.rvside;
   A.blc = B.blc;
   A.bhside = B.bhside;
   A.brc = B.brc;
   A.firstline_is_top = B.firstline_is_top;
   A.lastline_is_bottom = B.lastline_is_bottom;
}

/**
 * Reflow the entire block or Javadoc comment
 * 
 * @param match
 * 
 * @return int
 */
static int RC_entire(boolean match = false) {

   BlockCommentSettings_t localCleanSetting, onScreenSettings, dummySettings;
   int returnVal = checkCommentWrapStatus();
   int dummy;
   if (!returnVal) {
      //Set this value to 0, so a current border width will not override
      //the user choices for the reflow.
      CW_RBanalyzedWidth = 0;
      int commentWidth = CW_getRightMargin();
      typeless startLine, startCol, endLine;
      parse CW_startPos with startLine startCol .;
      parse CW_endPos with endLine .;
      if (match) {
         //get a clean copy of the proper comment border settings
         if (!CW_storeCommentSettings(localCleanSetting, CW_commentType)) {
            //When unable to read the comment settings, can not analyze, so return failure
            return (1);
         }
         CW_copyCommentSettings(onScreenSettings, CW_commentSettings);
         int lineNumber = startLine;
         int currentLMC = 0;
         int currentRMC = 0;
         int bulletOffset = 0;
         _str content;
         int pline = p_line, pcol = p_col;
         for (; lineNumber <= endLine; lineNumber++) {
            //Go through the comment and read the contents with the old setting.
            //then replace with the new settings.  Keep care of the cursor position
            if (lineNumber == startLine && CW_analyzeBCStartLine(startLine, endLine, dummy, dummySettings)) {
               //do nothing now if startLine is a border
            }
            if (lineNumber == endLine && CW_analyzeBCEndLine(startLine, endLine, dummySettings)) {
               //do nothing now if endLine is a border
            }
            p_line = lineNumber; p_col = pcol;
            CW_copyCommentSettings(CW_commentSettings, onScreenSettings);
            currentLMC = CW_extractBCLineText(content, startLine, endLine, currentRMC, bulletOffset);
            CW_copyCommentSettings(CW_commentSettings, localCleanSetting);
            CW_fixBorders2(startLine, endLine, commentWidth, content, currentLMC);
            if (lineNumber == pline) {
               pcol = p_col;
            }
         }
         p_line = pline; p_col = pcol;
      }

      int firstLine = 0, lastLine = 0;
      int lineNum, status;
      //cycle through and rewrap each line
      for (lineNum = startLine; lineNum <= endLine; lineNum++) {
         if (lineNum == startLine) {
            typeless p; save_pos(p);
            boolean wasBorder = CW_analyzeBCStartLine(startLine, endLine, dummy, dummySettings);
            restore_pos(p);
            if (wasBorder) {
               continue;
            }
         }
         if (lineNum == endLine) {
            typeless p; save_pos(p);
            boolean wasBorder = CW_analyzeBCEndLine(startLine, endLine, dummySettings);
            restore_pos(p);
            if (wasBorder) {
               break;
            }
         }

         status = CW_maybeReflowToNext(lineNum, startLine, endLine, CW_getRightMargin());
         if (status == CW_NONEEDTOREFLOW) while(CW_maybeMerge(lineNum, startLine, endLine)){
         }
         
      }

      int pcol = p_col, pline = p_line;
      if (CW_analyzeBCStartLine(startLine, endLine, dummy, dummySettings)) {
         //if end line is a border
         p_line = startLine; p_col = startCol;
         p_col = CW_commentBorderLeftCol;
         _delete_end_line();
         _insert_text_raw(substr(CW_commentSettings.tlc, 1, CW_getRightMargin() + 1 - length(CW_commentSettings.trc) - CW_commentBorderLeftCol, CW_commentSettings.thside != '' ? CW_commentSettings.thside : ' ') :+ CW_commentSettings.trc);
      }
      if (CW_analyzeBCEndLine(startLine, endLine, dummySettings)) {
         //If end line is a border
         p_line = endLine;
         p_col = CW_commentBorderLeftCol;
         _delete_end_line();
         //_insert_text_raw(substr(CW_commentSettings.blc, 1, commentWidth - length(CW_commentSettings.brc), CW_commentSettings.bhside != '' ? CW_commentSettings.bhside : ' ') :+ CW_commentSettings.brc);
         _insert_text_raw(substr(CW_commentSettings.blc, 1, CW_getRightMargin() + 1 - length(CW_commentSettings.brc) - CW_commentBorderLeftCol, CW_commentSettings.bhside != '' ? CW_commentSettings.bhside : ' ') :+ CW_commentSettings.brc);
      } else {
         //Clean up non-border endline
         p_line = endLine;
         _str line; get_line(line);
         if (strip(line) == strip(CW_commentSettings.brc)) {
            _begin_line(); _delete_end_line();
            p_col = CW_commentBorderLeftCol;
            if (p_line == pline && pcol > p_col) {
               p_col = pcol;
            }
            _insert_text_raw(CW_commentSettings.brc);
         }
      }
      p_col = pcol; p_line = pline;
      CW_clearCommentState();
   }
   //Success
   return(0);
}
/** 
 * X
 * 
 * @param lang 
 * 
 * @return  
 */
_str getCWaliasFile(_str lang = p_LangId, boolean createNew = true) 
{
   if (_create_config_path()) {
      message('Unable to find config path.');
      return '';
   }
   _str filename = _ConfigPath() :+ lang :+ CW_DOCCOMMENTALIASFILESUFFIX;
   if (!file_exists(filename) && createNew) {
      //Copy a default one over
      _str defaultfilename = get_env('VSROOT');
      _maybe_append_filesep(defaultfilename);
      defaultfilename = defaultfilename :+ 'sysconfig' :+ FILESEP :+ 'aliases' :+ FILESEP :+ '$8' :+ CW_DEFAULTDOCCOMMENTALIASFILE;
      if (file_exists(defaultfilename)) {
         int copyStat = copy_file(defaultfilename, filename);
         if(copyStat) {
            //message('Unable to find existing doc comment alias file for extension 'lang'.');
         }
      } else {
         //message('Unable to find existing doc comment alias file for extension 'lang'.');
      }
   }

   return filename;
}

/**
 * Finds the start and end line numbers of the current paragraph in a block
 * comment.
 * 
 * @param firstLine (Output only) Line number of first line of paragraph
 * @param lastLine  (Output only) Line number of last line of paragraph
 * 
 * @return int  0 on success. 1 if called when cursor not within valid 
 *         content, such as when on a blank line.
 */
static int CW_findParaStartAndEnd(int &firstLine, int &lastLine) {
   typeless startLine, endLine;
   parse CW_startPos with startLine .;
   parse CW_endPos with endLine .;
   //Check for valid content
   if (CW_isBCBlankLine(startLine, endLine) || (p_line == startLine && !CW_commentSettings.firstline_is_top) || (p_line == endLine && !CW_commentSettings.lastline_is_bottom)) {
      return (1);
   }

   int origLine = p_line, origCol = p_col;
   //Move up to start of paragraph
   for ( ; !CW_isParaStart(CW_commentType, startLine, endLine); up()) {
   }
   firstLine = p_line;

   p_line = origLine;

   //Move down to end of paragraph
   CW_moveToParaEnd(startLine, endLine);
   lastLine = p_line;

   p_line = origLine; p_col = origCol;
   return (0);
}

/**
 * Moves cursor to the last line of the current paragraph.
 * 
 * Helper function for CW_findParaStartAndEnd() function above.
 * 
 * @param startLine  Line number of start of comment
 * @param endLine    Line number of end of comment
 */
static void CW_moveToParaEnd(int startLine, int endLine) {
   int paraEndLine = p_line;
   if (p_line == endLine) {
      paraEndLine = endLine;
   }

   while (p_line < endLine) {
      down();
      if (CW_isBCBlankLine(startLine, endLine) || CW_isParaStart(CW_commentType, startLine, endLine)) {
         paraEndLine = p_line - 1;
         break;
      }
      if (p_line == endLine) {
         paraEndLine = endLine;
         break;
      }
   }
   p_line = paraEndLine;
   return;
}

void CW_commentwrap_nag()
{
   notifyUserOfFeatureUse(NF_COMMENT_WRAP, p_buf_name, p_line);
}

boolean def_nag_doccomment_expansion = true;
void CW_doccomment_nag() {
   // warn user about doc comment expansion
   notifyUserOfFeatureUse(NF_DOC_COMMENT_EXPANSION, p_buf_name, p_line);
}

