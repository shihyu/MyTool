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
#include "xmlwrap.sh"
#include "xml.sh"
#include "eclipse.sh"
#import "se/lang/api/LanguageSettings.e"
#import "se/tags/TaggingGuard.e"
#import "alias.e"
#import "adaptiveformatting.e"
#import "autobracket.e"
#import "beautifier.e"
#import "clipbd.e"
#import "codehelp.e"
#import "commentformat.e"
#import "context.e"
#import "csymbols.e"
#import "cutil.e"
#import "env.e"
#import "fileman.e"
#import "files.e"
#import "hformat.e"
#import "html.e"
#import "listproc.e"
#import "main.e"
#import "markfilt.e"
#import "mprompt.e"
#import "notifications.e"
#import "pmatch.e"
#import "recmacro.e"
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "util.e"
#import "xml.e"
#import "xmlwrapgui.e"
#import "cfg.e"
#endregion

using se.lang.api.LanguageSettings;


static const XWDebug=  false;
extern int wrap_markup_range(int wid, int startOffset, int endOffset, long (&positions)[]);

static const XW_RECURSE_LEVEL= 100;

const  XW_FOUND_NO_TAG=        0x0000;
const  XW_FOUND_S_TAG=     0x0001;
const  XW_FOUND_E_TAG=     0x0002;
const  XW_FOUND_EMPTY_TAG=     0x0003;

static const XW_ATTRIB_NAME_REGEX= "[\\p{IsXMLNameStartChar}][\\p{IsXMLNameChar}]*";
//#define XW_NAME_REGEX "[\\p{IsXMLNameStartChar}][\\p{IsXMLNameChar}]*(:[\\p{IsXMLNameChar}]*)*"
static const XW_NAME_REGEX= "[\\p{IsXMLNameStartChar}][\\p{IsXMLNameChar}]*([:][\\p{IsXMLNameStartChar}][\\p{IsXMLNameChar}]*):0,1";
static const XW_WHITESPACE= '[ \t\10\13]';
static const XW_ATTRIBUTE_CHAR_DATA_SINGLE_QUOTE= "[~\']";
static const XW_ATTRIBUTE_CHAR_DATA_DOUBLE_QUOTE= '[~\"]';

static const XW_ATTRIBUTE_REGEX= XW_ATTRIB_NAME_REGEX"("XW_WHITESPACE"*="XW_WHITESPACE"*)(\'"XW_ATTRIBUTE_CHAR_DATA_SINGLE_QUOTE"*\'|\""XW_ATTRIBUTE_CHAR_DATA_DOUBLE_QUOTE"*\")";


bool XW_isXMLTagLanguage(_str lang = p_LangId)
{
   return (XW_isSupportedLanguage_XML(lang) && _FindLanguageCallbackIndex("vs%s_list_tags"));
}

bool XW_isHTMLTagLanguage(_str lang = p_LangId)
{
   return (XW_isSupportedLanguage_HTML(lang) && _FindLanguageCallbackIndex("vs%s_list_tags"));
}

bool XW_isSupportedLanguage(_str lang = p_LangId)
{
   if (XW_isSupportedLanguage_XML(lang) || XW_isSupportedLanguage_HTML(lang)) {
      return (true);
   }
   return (false);
}

bool XW_isSupportedLanguage_XML(_str lang = p_LangId)
{
   if (_LanguageInheritsFrom('xml', lang) ||
       _LanguageInheritsFrom('xsd', lang) ||
       _LanguageInheritsFrom('docbook', lang) ||
       _LanguageInheritsFrom('vpj', lang) ||
       _LanguageInheritsFrom('xhtml', lang)) {
      return (true);
   }
   return (false);
}
bool XW_isSupportedLanguage_HTML(_str lang = p_LangId)
{
   if (_LanguageInheritsFrom('html', lang) && !_LanguageInheritsFrom('tld',lang)) {
      return (true);
   }
   return (false);
}

bool XW_isSupportedLanguage2(_str lang = p_LangId)
{
   if (command_state() || !_isEditorCtl())
      return (XW_isSupportedLanguage(lang));

   returnVal := false;
   // Handle embedded language
   typeless orig_values;
   int embedded_status = _EmbeddedStart(orig_values);
   if (embedded_status == 1) {
      if (XW_isSupportedLanguage(p_LangId) && !_in_comment()) {
         returnVal = true;
      }
      _EmbeddedEnd(orig_values);
   } else if (embedded_status != 2) {
      if (XW_isSupportedLanguage(lang) && !_in_comment()) {
         returnVal = true;
      }
   }
   return returnVal;
}

/**
 * Create a SlickEdit regex that will search for a specific xml attribute 
 * name/value pair. (e.g.  id = 'myElement')
 * 
 * @param attributeName  Name of attribute to search for
 * @param attributeValue Value of attribute to find.  If not given, find any 
 *                       name/value pair that matches just the name.
 * 
 * @return _str The regex to use in a search() call.
 */
_str XW_namedAttributeRegex(_str attributeName, _str attributeValue = '') {
   if (attributeValue :== '') {
      return attributeName :+ "("XW_WHITESPACE"*="XW_WHITESPACE"*)(\'{#0"XW_ATTRIBUTE_CHAR_DATA_SINGLE_QUOTE"*}\'|\"{#0"XW_ATTRIBUTE_CHAR_DATA_DOUBLE_QUOTE"*}\")";
   } else return attributeName :+ "("XW_WHITESPACE"*="XW_WHITESPACE"*)(\'{#0" :+ _escape_re_chars(attributeValue) :+ "*}\'|\"{#0" :+ _escape_re_chars(attributeValue) :+ "*}\")";
}

/**
 * If cursor is on a character in reference string, move back one text position.
 * 
 * @param reference String holding characters that cause cursor to be moved back.
 */
static bool maybeMoveBackCursor(_str reference= "") {
   if (verify(get_text(), reference))
      return true;
   if (p_col == 1) {
      if (up())
         return false;
      _end_line();
   } else
      left();
   return true;
}

/**
 * Gets language of current buffer, or returns default of 'xml' if no open 
 * buffers found 
 * 
 * @return Language of current buffer or default of 'xml'
 */
_str xw_p_LangId() 
{
   if (!_isEditorCtl(false)) {
      return 'xml';
   }
   if (_ConcurProcessName()!=null) {
      return 'process';
   }
   return p_LangId;
}
_str xw_p_buf_name() 
{
   if (!_isEditorCtl(false)) {
      return 'xml';
   }
   return p_buf_name;
}

static _str namedFullStartTagRegex(_str name) {
   return ('\om{#0<{#3'name'}('XW_WHITESPACE'*'XW_ATTRIBUTE_REGEX')*'XW_WHITESPACE'*>}');
}
static _str namedFullEndTagRegex(_str name) {
   return ('\om{#1</{#3'name'}'XW_WHITESPACE'*>}');
}
static _str namedFullStartOrEndTagRegex(_str name) {
   return (namedFullStartTagRegex(name)'|'namedFullEndTagRegex(name));
}
static const JUST_START_REGEX= '{#0<{#3'XW_NAME_REGEX'}}';
static const FULLSTARTTAGREGEX= '{#0<{#3'XW_NAME_REGEX'}('XW_WHITESPACE'*'XW_ATTRIBUTE_REGEX')*'XW_WHITESPACE'*>}';
static _str fullStartTagRegex = FULLSTARTTAGREGEX;
static _str fullStartTagRegexOM = '\om'FULLSTARTTAGREGEX;
static const FULLENDTAGREGEX= '{#1</{#3'XW_NAME_REGEX'}'XW_WHITESPACE'*>}';
static _str fullEndTagRegex = FULLENDTAGREGEX;
static _str fullEndTagRegexOM = '\om'FULLENDTAGREGEX;
static const FULLEMPTYTAGREGEX= '{#2<{#3'XW_NAME_REGEX'}('XW_WHITESPACE'*'XW_ATTRIBUTE_REGEX')*'XW_WHITESPACE'*/>}';
static _str fullEmptyTagRegex = FULLEMPTYTAGREGEX;
static _str fullEmptyTagRegexOM = '\om'FULLEMPTYTAGREGEX;
/**
 * Use only when not inside a tag
 * 
 * @return int XW_FOUND_NO_TAG No tag, XW_FOUND_S_TAG, XW_FOUND_E_TAG, XW_FOUND_EMPTY_TAG
 */
int XW_FindTag(_str &name) {
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
   //long orig_offset = _QROffset();
   int returnVal = XW_FOUND_NO_TAG;
   pc := p_col;int pl = p_line;
   
   status := search(fullStartTagRegexOM'|'fullEndTagRegexOM'|'fullEmptyTagRegexOM,'@-RHXCS');
   
   if (status /*|| match_length('2') != 0*/) {
      //found neither or found end
      //XWsay("XW_FindTag() found no tag "pl" "pc);
      returnVal = XW_FOUND_NO_TAG;
      name = "";
   } else {
      if (match_length('2') != 0) {
         //found neither or found end
         //XWsay("found empty  ");
         returnVal = XW_FOUND_EMPTY_TAG;
      } 
   
      if (match_length('0') != 0) {
         returnVal = XW_FOUND_S_TAG;
         //XWsay("found start  ");
         //XWsay("found start "get_match_text('0')"|"get_match_text('1'));
      }
      if (match_length('1') != 0) {
         returnVal = XW_FOUND_E_TAG;
         //XWsay("found end");
         //XWsay("found 1 "get_match_text('1')"|"get_match_text('0'));
      }
      name = get_text(match_length('3'),match_length('S3'));
      //XWmessage(name);
   }

   restore_search(s1,s2,s3,s4,s5);
   //_GoToROffset(orig_offset);
   return returnVal;
}

//Assuming not in a tag body
int XW_FindParentBlockTag2(_str &name, int &level) {
   //XWsay('XW_FindParentBlockTag2()');
   maybeMoveBackCursor(XW_TAG_OPEN_BRACKET);
   if (level > XW_RECURSE_LEVEL) {
      //XWsay('Hit recursion limit');
      return XW_FOUND_NO_TAG;
   }
   int status1 = XW_FindTag(name);
   if (status1 == XW_FOUND_S_TAG || status1 == XW_FOUND_NO_TAG) {
      return status1;
   } 
   // tagging for these languages is not strictly XML outlining,
   // so we need to use old-style tag matching
   if (XW_isHTMLTagLanguage(p_LangId)) {
      if (status1 == XW_FOUND_E_TAG) {
         right();
         int status_fmp = _find_matching_paren(0x7fffffff, true);
         if (status_fmp != 0) {
            //messageNwait('No matching');
            return XW_FOUND_NO_TAG;
         }
         level++;
         return XW_FindParentBlockTag2(name, level);
      } else if (status1 == XW_FOUND_EMPTY_TAG) {
         //_GoToROffset(_QROffset()-1);
         level++;
         return XW_FindParentBlockTag2(name, level);
      }
      //Should not reach this point.
      return XW_FOUND_S_TAG;
   } else if (!XW_isXMLTagLanguage(p_LangId)) {
      return(XW_FOUND_NO_TAG);
   }
   if (p_buf_size>def_update_context_max_ksize*1024) {
      return(XW_FOUND_NO_TAG);
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContext(true);

   XWsay('_UpdateContext(true)  called');
   int context_id = tag_current_context();
   if (context_id <=0) {
      XWsay('No context.');
      return(XW_FOUND_NO_TAG);
   }
   parent_context := 0;
   tag_get_detail2(VS_TAGDETAIL_context_outer,context_id,parent_context);
   if (!parent_context) {
      return(XW_FOUND_NO_TAG);
   }
   start_seekpos := 0;
   tag_get_detail2(VS_TAGDETAIL_context_start_seekpos,parent_context,start_seekpos);
   tag_get_detail2(VS_TAGDETAIL_context_name,parent_context,name);
   _GoToROffset(start_seekpos);
   return(XW_FOUND_S_TAG);
}

/**
 * 
 * 
 * @author David A. O'Brien (9/29/2009)
 * 
 * @return int 
 */
_command int XW_promote() {
   return XW_sectadjust(-1, _QROffset());
}
_command int XW_demote() {
   return XW_sectadjust(1, _QROffset());
}
_command int XW_sectadjust(int delta = 1, long startOffset = 0) {
   //Maybe handle special case of cursor starting on an '<'

   orig_offset := _QROffset();
   save_pos(auto startPos);
   _GoToROffset(startOffset);
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
   status := search('\om{#0<sect{#1[12345]}}','@-RHXCS');
   if (status) {
      //nothing found
      restore_search(s1,s2,s3,s4,s5);
      restore_pos(startPos);
      return 1;
   }
   //found start version
   _str sectnum = get_text(match_length('1'), match_length('S1'));
   //Check that we are in proper range
   int sectnumint = delta + (int)sectnum;
   if (!((1 <= sectnumint) && (sectnumint <= 5))) {
      restore_search(s1,s2,s3,s4,s5);
      restore_pos(startPos);
      return 1;
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   //get context of surrounding section tag
   _UpdateContext(true);
   context_id := tag_current_context();
   if (context_id <=0) {
      restore_search(s1,s2,s3,s4,s5);
      restore_pos(startPos);
      return 1;
   }

   //Find end of close tag
   start_seekpos := _QROffset();
   end_seekpos := 0L;
   tag_get_detail2(VS_TAGDETAIL_context_end_seekpos, context_id, end_seekpos);
   if (!end_seekpos) {
      //Do nothing if not in a closed section context
      restore_search(s1,s2,s3,s4,s5);
      restore_pos(startPos);
      return 1;
   }

   //If starting offset is greater than end of close tag, need to search for next enclosing tag
   if (orig_offset >= end_seekpos) { 
      //start another search from start_seekpos
      _GoToROffset(start_seekpos);
      maybeMoveBackCursor(XW_TAG_OPEN_BRACKET);
      nextSearchStartOffest := _QROffset();
      restore_search(s1,s2,s3,s4,s5);
      restore_pos(startPos);
      return XW_sectadjust(delta, nextSearchStartOffest);
   }

   //Found our surrounding sect tag
   if ((start_seekpos <= orig_offset) && (orig_offset < end_seekpos))  {
      _GoToROffset(start_seekpos);
      select_char();
      _GoToROffset(end_seekpos);
      lock_selection('q');
      _GoToROffset(start_seekpos);
      //Update start and end tag names to ('sect'sectnumint)
      while (!search('{(role[ \t\10\13]*=[ \t\10\13]*[\"\'']SectionHeading)|(<(/:0,1)sect)}{[1-5]}', '@>*MRHXCS')) {
         _str part1 = get_text(match_length('1'), match_length('S1'));
         sectnumint = delta + (int)part1;
         if (!((1 <= sectnumint) && (sectnumint <= 5))) {
            //Skip this tag.
            continue;
            //Or perhaps change it and give a warning
         }
         search_replace('#0'sectnumint);
      }
      deselect();
   }
   
   restore_search(s1,s2,s3,s4,s5);
   restore_pos(startPos);
   return 0;
}

static bool shouldDoWrapping(_str lang,_str buf_name)
{
   return (beautify_on_edit(lang)) && markup_line_wrapping_length(lang,buf_name) != -1;
}

/**
 * Author: David A. O'Brien
 * Date:   12/3/2007
 * 
 * Initial entry point into xml wrap for all keystrokes other than Home, 
 * Backspace, Delete, and Enter. 
 *  
 * @return int   Return 0 or return 2 if xml/html formatting is not on.
 */
int XW_doeditkey() {
   //XWsay("XW_doeditkey");
   wrapOn := shouldDoWrapping(xw_p_LangId(),xw_p_buf_name());
   correlationOn := startEndCorrelationOn();

   if (!wrapOn && !correlationOn){
      //XWclearState();
      return 2;
   }

   _str key=last_event();
   if (key == '>' || key == '<') {
      wasInComment := false;
      if (!_in_comment(false) && key == '>') {
         //Check if this may be closing a comment
         left(); _delete_text(1, 'C');
         wasInComment = _in_comment(false);
         _insert_text('>');
      }
      //XWclearState();
      if (wasInComment) return 2;
   }

   XW_doeditkeyOutTag();
   return 0;
}

static bool startEndCorrelationOn() {
   //temporarily turn off
   return false;

   if (!XW_isSupportedLanguage2()) {
      return false;
   }
   return LanguageSettings.getAutoCorrelateStartEndTags(p_LangId);
}

static void skipOutOfEmbeddedSection(bool forward)
{
   if (p_EmbeddedLexerName == '') {
      return;
   }

   if (forward) {
      _clex_find(0, 'S');
   } else {
      _clex_find(0, '-S');
   }
}

static long scanForwardForRestOfParagraph(int startCol)
{
   // Look forward for content in the same "paragraph".
   maxLines := 100;
   old_line := p_line;
   p_line += 1;
   while (p_line > old_line && maxLines > 0) {
      if (XW_isBlankLine()) {
         p_line = old_line;
         break;
      }

      _first_non_blank();
      if (p_col < startCol) {
         p_line = old_line;
         break;
      }

      if (get_text() == '<' && get_text(2) != '</') {
         p_line = old_line;
         break;
      }

      old_line = p_line;
      p_line += 1;
      maxLines -= 1;
   }
   _end_line();
   return _QROffset();
}

static bool insideTag()
{
   maxLines := 10;
   lastline := p_line;
   balance  := 0;
   save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
   save_pos(auto ppp);

   cursor_left();
   status := search('[<>]', '<-UXCCS');
   while (balance <= 0 && status == 0 && p_line >= (lastline - maxLines) && 
          _QROffset() != 0) {
      switch (get_text()) {
      case '>':
         balance -= 1;
         break; 

      case '<':
         balance += 1;
         break;
      }

      if (p_col > 1) {
         p_col--;
      } else {
         if (p_line > 1) {
            p_line--;
            _end_line();
         } else {
            _GoToROffset(0);
         }
      }
      status = search('[<>]', '<-UXCCS');
   }

   restore_search(s1, s2, s3, s4, s5);
   restore_pos(ppp);

   return balance > 0;
}

static bool XW_doeditkeyOutTag(bool alwaysCheck=false) {
   cursorPos := _QROffset();
   // Don't do anything in the middle of typing a tag.
   _GoToROffset(cursorPos);
   if (insideTag()) {
      return false;
   }

   save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
   sr := search('[a-zA-Z0-9_]#>', '@-HXCS>');
   if (sr == 0) {
      restore_search(s1, s2, s3, s4, s5);
      _GoToROffset(cursorPos);
      return false;
   }

   _insert_text('@');
   wrapLen := markup_line_wrapping_length(xw_p_LangId(),xw_p_buf_name());
   _first_non_blank();
   startCol := p_col;
   p_col = 1;
   selstart := _QROffset();

   status := search('<[a-zA-Z:0-9]#', '@-RHXCS>');

   if (status == 0) {
      p_col=1;
      selstart = _QROffset();
   }

   _GoToROffset(cursorPos);
   _end_line();
   selend := _QROffset();
   endCol := p_col;

   if (!alwaysCheck &&
       (endCol < wrapLen ||
       (selend-selstart) < 5)) {
      _GoToROffset(cursorPos);
      _delete_char();
      restore_search(s1, s2, s3, s4, s5);
      return false;
   }

   // Extend to whole paragraph. And do not cut embedded sections in half.
   selend = scanForwardForRestOfParagraph(startCol);
   skipOutOfEmbeddedSection(true);
   selend = _QROffset();

   _GoToROffset(selstart);
   skipOutOfEmbeddedSection(false);
   selstart = _QROffset();

   long markers[];

   _GoToROffset(cursorPos);

   status = wrap_markup_range(p_window_id, (int)selstart, (int)selend, markers);
   if (status < 0) {
      _GoToROffset(cursorPos);
      _delete_char();
      restore_search(s1, s2, s3, s4, s5);
      return false;
   }

   if (get_text() == '@') {
      _delete_char();
   }
   restore_search(s1, s2, s3, s4, s5);
   return true;
}

static bool XW_isBlankLine() {
   _str line;
   get_line_raw(line);
   return (strip(line) == "");
}

bool XW_doDelete(bool alreadyDeleted = false) {
   //XWmessageNwait('Do delete');
   if (!shouldDoWrapping(xw_p_LangId(),xw_p_buf_name())) {
      return false;
   }

   if (XW_isBlankLine()) {
      return false;
   }

   ch := get_text();
   loc := _QROffset();

   if (ch == '<' || ch == '>') {
      return false;
   }

   if (!alreadyDeleted) {
      _delete_char();
   }
   status := XW_doeditkeyOutTag(true);

   if (!status && !alreadyDeleted) {
      _GoToROffset(loc);
      _insert_text(ch);
      _GoToROffset(loc);
   }
   return status;
}

bool XW_Enter() {  
      returnValBool := XW_doEnter();
      maybeOpenHiddenLines(p_line, p_col);
      return (returnValBool);
}

/**
 * Handles Enter key stroke for XML/HTML content wrapping.
 * 
 * @return bool
 */
bool XW_doEnter() {  
   if (!beautify_on_edit(xw_p_LangId())) {
      return false;
   }

   if (p_col == 1) {
      return false;
   }

   if (get_text(2) != '</') {
      return false;
   }

   cpos := _QROffset();
   origcpos := cpos;

   left();
   if (get_text() != '>') {
      right();
      return false;
   }

   save_search(auto s1, auto s2, auto s3, auto s4, auto s5);

   status := search('{#0<{#3[a-zA-Z:0-9]#}}', '@-RHXCS>');
   p1Line := p_line;

   if (status || (p_line != p1Line)) {
      restore_search(s1,s2,s3,s4,s5);
      _GoToROffset(cpos);
      return false;
   }
   goto_point(match_length('S'));

   stagpos := _QROffset();
   stagcol := p_col;

   if (stagcol != _first_non_blank_col()) {
      restore_search(s1,s2,s3,s4,s5);
      _GoToROffset(cpos);
      return false;
   }

   tagName := strip(get_match_text('3'), 'B');

   _GoToROffset(cpos);
   right(); right();

   closeTagName := cur_word(auto scol);


   _GoToROffset(cpos);
   if (tagName != closeTagName) {
      restore_search(s1,s2,s3,s4,s5);
      return false;
   }

   // Indent things over so the paragraph wrapping can get
   // its head around this.

   if (!_macro('S')) {
      _undo('S');
   }
   istr := indent_string(stagcol);
   _insert_text(p_newline :+ istr);
   cpos = _QROffset();
   _insert_text(p_newline :+ istr);
   restore_search(s1,s2,s3,s4,s5);
   _GoToROffset(cpos);
   rv := XW_doeditkeyOutTag(true);

   if (!rv) {
      if (!_macro('S')) {
         undo();
         _GoToROffset(origcpos);
      }
   }

   return rv;
}

bool XW_doBackspace() {
// if (p_col == 1) {
//    return false;
// }
//
// if (_first_non_blank_col() >= p_col) {
//    return false;
// }
//
// left();
// if (XW_doDelete()) {
//    return true;
// } else {
//    right();
//    return false;
// }
   return false;
}
 
//used by XW_Paste() and XW_Cut() function to prevent cycle of XW_Paste() and 
//paste() (and XW_Cut() and cut()) calling each other.  This is not elegant but 
//was used to keep changes in paste() and cut() function to a minimum. 
static bool inXW_CutOrPaste = false;
/**
 * Called by paste to try a paste and then xml/html wrap on remaining content. 
 * Will only wrap simple pastes that leave the cursor on the same line as the
 * start position. 
 * 
 * @return bool      Return true if xml/html wrap handled the paste.
 */
bool XW_Paste(_str name='',bool isClipboard=true,int temp_view_clipboard=0) {
   // Handled by standard beautify-on-paste option.
   return (false);
}

/**
 * Called by cut() to try a cut and then xml/html wrap. Will only wrap simple 
 * cuts. 
 * 
 * @return bool      Return true if xml/html wrap handled the cut.
 */
bool XW_Cut(bool push=true,bool doCopy=false,_str name='') {
   return (false);
}

/**
 * Counts number of consecutive blanks starting from startLine line
 * going up.
 * 
 * @return int Number of blank lines including current line.
 */
static int countBlankLinesUp(int startLine) {
   if (startLine < 1) {
      return 0;
   }
   returnVal := 0;
   _str p;
   save_pos(p);
   p_line = startLine;
   while (XW_isBlankLine()) {
      returnVal++;
      if (up()) break;
   }
   restore_pos(p);
   return returnVal;
}
/**
 * Counts number of consecutive blanks starting from current line
 * going down.
 * 
 * @return int Number of blank lines including current line.
 */
static int countBlankLinesDown(int startLine) {
   returnVal := 0;
   _str p;
   save_pos(p);
   while (XW_isBlankLine()) {
      returnVal++;
      if (down()) break;
   }
   restore_pos(p);
   return returnVal;
}

void XW_xmlwrap_nag()
{
   notifyUserOfFeatureUse(NF_HTML_XML_FORMATTING, p_buf_name, p_line);
}

/**
 * Handle '>' for xml/html formatting.
 * 
 * @return (int) Positive if handled by xml/html formatting.
 */
int XW_gt() {
   if (!beautify_on_edit(xw_p_LangId())) {
      return 0;
   }

   if (!_macro('S')) {
      _undo('S');
   }

   //Turn off the auto completion box
   XW_TerminateCodeHelp();
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);

   cpos := _QROffset();
   p1Line := p_line;
   emptyTag := false;

   left(); left();
   if (get_text() == '/') {
      emptyTag = true;
   }
   _GoToROffset(cpos);
   status := search('{#0<{#3[a-zA-Z:0-9]#}}', '@-RHXCS>');
   if (status || (p_line != p1Line)) {
      //XWmessage("Unable to match > symbol");
      restore_search(s1,s2,s3,s4,s5);
      _GoToROffset(cpos);
      return 0;
   }
   goto_point(match_length('S'));

   stagpos := _QROffset();
   tagName := strip(get_match_text('3'), 'B');

   long selstart = -1;
   long selend   = -1;
   xMarksSpot := false;
   shouldSurround := false;

   if (emptyTag) {
      selstart = stagpos;
      selend = cpos;
      _GoToROffset(cpos);
   } else if (markup_is_inline_tag(xw_p_LangId(), tagName,xw_p_buf_name())) {
      if (markup_end_tag_required(xw_p_LangId(), tagName,xw_p_buf_name())) {
         _GoToROffset(cpos);
         _insert_text_raw('</'tagName'>');
         selstart = stagpos;
         selend   = _QROffset();
         _GoToROffset(cpos);
      } else {
         selstart = stagpos;
         selend = cpos;
         _GoToROffset(cpos);
         _insert_text('@');
         _GoToROffset(cpos);
         xMarksSpot=true;
      }
   } else {
      _GoToROffset(cpos);
      _insert_text(p_newline);
      spos:=_QROffset();
      _insert_text('@'p_newline'</'tagName'>');
      selstart = stagpos;
      selend   = _QROffset();
      _GoToROffset(spos);
      xMarksSpot = true;
      shouldSurround = true;
   }


   //say("tagName="tagName", emptyTag="emptyTag", cpos="cpos", start="selstart", end="selend);

   long markers[];

   // If we don't do this next bit, than a inline tag inserted inside of a paragraph can 
   // damage the wrapping to the point that further typing can't fix it, without the user 
   // manually re-joining lines.
   savedCursor := _QROffset();
   _GoToROffset(selend);
   selend = scanForwardForRestOfParagraph(_first_non_blank_col());
   skipOutOfEmbeddedSection(true);
   selend = _QROffset();

   _GoToROffset(selstart);
   skipOutOfEmbeddedSection(false);
   selstart = _QROffset();
   _GoToROffset(savedCursor);

   markers[0] = selstart;
   status = new_beautify_range(selstart, selend, markers, true, false, false);
   if (status < 0) {
      if (!_macro('S')) {
         undo();
         _GoToROffset(cpos);
         return 0;
      }
   }

   if (xMarksSpot) {
      if (get_text() == '@') {
         delete_char();
      } else {
         // Whoops.
         if (!_macro('S')) {
            undo();
            _GoToROffset(cpos);
            return 0;
         }
      }
   }

   if (shouldSurround) {
      newpos := _QROffset();
      _GoToROffset(markers[0]);
      set_surround_mode_start_line(p_line);

      _GoToROffset(newpos);
      set_surround_mode_end_line(p_line+1);
      do_surround_mode_keys(true);
   }

   restore_search(s1,s2,s3,s4,s5);
   return 1;
}

/**
 * Scans the named files and returns an array holding the names of all 
 * the unique tags found.
 * 
 * @param bufName  Name of buffer to scan for tags
 * @param tagNames (out) Array holding the names of all the tags found 
 *                 in the buffer.
 */
static void findAllTagsInFile(_str bufName, _str (&tagNames)[]) 
{
   find_buffer(bufName);
   tagNames._makeempty();
   bool tagNameHash:[];
   sticky_message("Scanning buffer for tags");
   tag_name := "";
   int i;
   tagNameHash._makeempty();

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContext(true);

   tagNum := tag_get_num_of_context();
   for (i = 1; i <= tagNum; i++) {
      tag_get_detail2(VS_TAGDETAIL_context_type,i,tag_name);
      if (tag_name == 'taguse') {
         tag_get_detail2(VS_TAGDETAIL_context_name,i,tag_name);
         if (tag_name != '' && !tagNameHash._indexin(tag_name)) {
            tagNameHash:[tag_name] = true;
            tagNames[tagNames._length()] = tag_name;
         }
         tag_name = '';
      }
   }
   clear_message();
}

void XWsay(_str the_message) {
   if (XWDebug) {
      say(the_message);
   }
}
void XWmessage(_str the_message) {
   if (XWDebug) {
      message(the_message);
   }
}
void XWmessageNwait(_str the_message) {
   if (XWDebug) {
      messageNwait(the_message);
   }
}

/**********************************************************************
* This section includes the routines for automatic symbol translation *  
* for XML based languages.                                            * 
***********************************************************************/
static bool ST_symTransOn(_str lang) {
   if (!XW_isSupportedLanguage2(lang)) {
      return false;
   }
   
   return LanguageSettings.getAutoSymbolTranslation(lang);
}


/**
 * Expand any automatic symbol translations
 * 
 * @param _str lang 
 * 
 * @return int 1 if there was an expansion, otherwise 0.
 */
int ST_doSymbolTranslation(_str lang = p_LangId) {
   if(!ST_symTransOn(lang)) {
      return 0;
   }
   if (p_col > 2) {
      count:=6;
      if (p_col-1<count) {
         count=p_col-1;
      }
      _str text = _expand_tabsc(p_col-count,count);
      aliasName:=_plugin_find_longest_property(vsCfgPackage_for_Lang(lang),VSCFGPROFILE_SYMBOLTRANS_ALIASES,text,false);
      if (!aliasName._isempty()) {
         possibleAliasLength := 2;
         p_col -= possibleAliasLength;
         _delete_text(possibleAliasLength);
         AutoBracketCancel(); AutoBracketDeleteText();
         if (expand_alias(aliasName, '', getSymbolTransaliasFile(p_LangId))) {
            return 0;
         }
         return 1;
      }
   }
   return 0;
}

bool def_nag_symbolTranslation = true;
void ST_nag() {
   notifyUserOfFeatureUse(NF_AUTO_SYMBOL_TRANSLATION, p_buf_name, p_line);
}

