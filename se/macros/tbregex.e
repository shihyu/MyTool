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
#include "search.sh"
#include "xml.sh"
#include "markers.sh"
#import "codehelp.e"
#import "eclipse.e"
#import "guiopen.e"
#import "listbox.e"
#import "picture.e"
#import "stdprocs.e"
#import "tbcontrols.e"
#import "toolbar.e"
#import "se/ui/toolwindow.e"
#endregion

static const DLGINFO_TIMER_HANDLE= 0;

static const TBREGEX_FORM= '_tbregex_form';

static bool EXPRESSION_DIRTY(...) {
   if (arg()) ctledit_testcases.p_user=arg(1);
   return ctledit_testcases.p_user;
}
static bool MULTILINE(...) {
   if (arg()) ctltext_expression.p_user=arg(1);
   return ctltext_expression.p_user;
}
static int ALLOCATEDPIX(...) {
   if (arg()) ctlradio_perl.p_user=arg(1);
   return ctlradio_perl.p_user;
}
static _str EXPRESSION_TYPE(...) {
   if (arg()) ctlimgbtn_new.p_user=arg(1);
   return ctlimgbtn_new.p_user;
}
static bool CASE_SENSITIVE(...) {
   if (arg()) ctlimgbtn_open.p_user=arg(1);
   return ctlimgbtn_open.p_user;
}
static _str LASTFILEPATH(...) {
   if (arg()) ctlLastFilePath.p_text=arg(1);
   return ctlLastFilePath.p_text;
}

static const REGXFILEFILTER= "Regex files (*.regx),All Files (*.*)";
static int COLORINDEX_GROUPMATCH = 0;
static int MARKERTYPE_GROUPBOX = 0;
static int MARKERTYPE_WHOLEMATCH = 0;
static int picbmpID = 0;


definit()
{
   COLORINDEX_GROUPMATCH = 0;
   MARKERTYPE_GROUPBOX = 0;
   MARKERTYPE_WHOLEMATCH = 0;
   picbmpID=0;
}

void onRevaluatorTimer(int form_wid)
{

   if (!_iswindow_valid(form_wid) || form_wid.p_name!=TBREGEX_FORM) {
      return;
   }
   // Make sure at least .5 seconds has elapsed
   // since the last key press on the dialog
   elapsed := _idle_time_elapsed();


   if (elapsed > 300) {
      _nocheck _control ctledit_testcases;
      int editorHandle=form_wid.ctledit_testcases;

      // See if either the edit control window or the expression
      // window has been modified since the last evaluation
      if (form_wid.EXPRESSION_DIRTY() || editorHandle.p_modify) {
         form_wid.ImmediateUpdate();
      }
   }
}

// Forces an immediate evaluation of the regular expression.
//  Called when the update timer is fired, or called directly
//  when a user loads a saved expression from disk.
static void ImmediateUpdate() {
   ctledit_testcases.p_modify = false;
   EXPRESSION_DIRTY(false);
   _nocheck _control ctltext_expression;
   highlightExpressionMatches(ctledit_testcases, ctltext_expression, MULTILINE());
}

// This method deals with the entire buffer, which is how we support "multiline mode"
// Multiline mode searches require the \om regex option to be part of the regex itself
// (which is a strange departure from most implementations)
static void highlightExpressionMatches(int editorWindow, int expressionWindow, bool asMultiline)
{
   // Clear out any allocated pics for groups
   ClearAllPics(editorWindow);

   // Grab the regular expression text
   expressionToTest := expressionWindow.p_text;
   if ((expressionToTest == null) || (length(expressionToTest) < 1)) {
      return;
   }

   // Make sure the expression contains the \om specification
   // The user may have already specified it in the expression itself
   // If not, tack it on the front. We don't actually modify the user's
   // text in the expression window.
   if (asMultiline) {
      if (pos('\om', expressionToTest) == 0)
         expressionToTest = '\om' :+ expressionToTest;
   }

   // Save the current editor position info
   oldLine := editorWindow.p_line;
   oldCol := editorWindow.p_col;

   // Set to the first line and column
   editorWindow.p_line = 1;
   editorWindow.p_col = 1;

   // Determine the current text color, so we can draw any
   // whole-match squiggles with a color that will show properly
   _str foreColor, c=_default_color(CFG_WINDOW_TEXT);
   parse c with foreColor . .;
   int squiggleColor = (int)foreColor;

   // We'll be kind and assume the expression will be valid
   // So set the expression entry text box foreground color back
   // to the default setting. It gets set to red if there is a syntax
   // error in the expression.
   expressionWindow.p_forecolor = 0x80000008;

   // Set the U, R, or B regex type option
   _str searchOpts = EXPRESSION_TYPE();
   // Set the case sensitivity option
   if (CASE_SENSITIVE() == false)
      searchOpts :+= "I";

   // Look for the first occurrence
   found := editorWindow.search(expressionToTest, searchOpts);
   if (found == INVALID_REGULAR_EXPRESSION_RC) {
      // Set the expression text entry area to have a red foreground
      expressionWindow.p_forecolor = 0x000000FF;
      _str msg = get_message(INVALID_REGULAR_EXPRESSION_RC);
      message(msg);
   } else {
      // Reset the expression entry area to have the normal foreground
      expressionWindow.p_forecolor = 0x80000008;
   }
   // This multiline search treats the whole contents of the editor
   // as the test case (the "haystack", as it were).
   totalMatches := 0;
   totalZeroLenMatches := 0;
   while (found == 0) {
      totalMatches++;
      matchLen := match_length();
      long currentPos = editorWindow._QROffset();

      // Bail out on zero-length matches
      if (matchLen == 0) {
         totalZeroLenMatches++;
         if (totalZeroLenMatches > 200) {
            ClearAllPics(editorWindow);
            message("Too many zero-length matches found");
            totalMatches = 0;
            found = -1;
            continue;
         }
      }
      startPos := match_length('S');

      // Retrieve the matched text and create our HTML message for the PIC gutter area
      matchedText := editorWindow.get_text(matchLen, startPos);
      if (matchedText != null)
         _escape_html_chars(matchedText);
      _str msg = "Matched [<b>"matchedText"</b>]<br>&nbsp;&nbsp;<i>Start "startPos", Length "matchLen"</i><br>";

      // Since we're not doing line-by-line searching, keep track of the
      // line number where this match was found so we can set up the PIC
      editorWindow._GoToROffset(startPos);
      lineIdx := editorWindow.p_line;

      // Grab the tagged groups
      groupIdx := 0;
      for (;groupIdx <= 9; ++groupIdx) {
         groupStart := match_length('S'groupIdx);
         groupLen := match_length(groupIdx);
         if (groupStart >= 0 && groupLen > 0) {
            editorWindow._GoToROffset(groupStart);
            matchedText = editorWindow.get_text(groupLen);
            if (matchedText != null)
               _escape_html_chars(matchedText);

            long off = editorWindow._QROffset();
            // We just build up the message string using all of the group information
            // We'll then add the whole string to the "whole match" PIC message
            _str groupmsg = "&nbsp;Group "groupIdx": [<b>"matchedText"</b>]<br>&nbsp;&nbsp;<i>Start "groupStart", Length "groupLen"</i><br>";
            msg :+= groupmsg;
            int picID = _StreamMarkerAdd(editorWindow, off, groupLen, true, picbmpID, MARKERTYPE_GROUPBOX, "");
            editorWindow._StreamMarkerSetStyleColor(picID, 0xff0000);
            editorWindow._StreamMarkerSetTextColor(picID, COLORINDEX_GROUPMATCH);
            ALLOCATEDPIX(ALLOCATEDPIX()+1);
         }
      }

      // Add the "whole match" pic. This doesn't (yet) do any of its own drawing, just adds
      // the bitmap and HTML tooltip with the details
      int mainPicID = _StreamMarkerAdd(editorWindow, startPos, matchLen, true, picbmpID, MARKERTYPE_WHOLEMATCH, msg);
      editorWindow._StreamMarkerSetStyleColor(mainPicID, squiggleColor);
      ALLOCATEDPIX(ALLOCATEDPIX()+1);

      editorWindow._GoToROffset(currentPos);
      found = editorWindow.repeat_search(searchOpts);
   }
   if (totalMatches > 0) {
      if (totalMatches == 1) {
         message("Matched "totalMatches" time");
      } else {
         message("Matched "totalMatches" times");
      }
   }

   // Reset the editor position
   editorWindow.p_line = oldLine;
   editorWindow.p_col = oldCol;
   editorWindow.refresh();
}


// Remove all the _LineMarker whole match and group match decorations from the editor control
static void ClearAllPics(int editorHandle)
{
   if (ALLOCATEDPIX() > 0) {
      ALLOCATEDPIX(0);
      editorHandle._StreamMarkerRemoveAllType(MARKERTYPE_GROUPBOX);
      editorHandle._StreamMarkerRemoveAllType(MARKERTYPE_WHOLEMATCH);
   }
}

defeventtab _tbregex_form;

void _tbregex_form.F7() {
   _retrieve_prev_form();
}
void _tbregex_form.F8() {
   _retrieve_next_form();
}
void _tbregex_form.on_load()
{
   initRegexEvaluatorControls();
   //call_event(p_window_id,ON_LOAD,'2');
}

void _tbregex_form.on_destroy()
{
   // Expression state
   _save_form_response(true);

   // Clean up the allocated colors and PICs
   ClearAllPics(ctledit_testcases);
   // TODO: _FreeColor is causing the interpreter to stop running
   // So for now, we're going to leave this "hang"
   //ctledit_testcases._FreeColor(COLORINDEX_GROUPMATCH);

   // Clean up the timer
   int timerHandle = (int)_GetDialogInfo(DLGINFO_TIMER_HANDLE, p_active_form);
   // Decrement the timer handle since it was incremented before
   // storing it as dialog info
   --timerHandle;
   if (timerHandle >= 0) {
      _SetDialogInfo(DLGINFO_TIMER_HANDLE, -1, p_active_form);
      _kill_timer(timerHandle);
   }
   //call_event(p_window_id,ON_DESTROY,'2');
}

void _tbregex_form.on_resize()
{
   resizeRevaluatorControls();
}

static void initRegexEvaluatorControls()
{
   // Default to Perl regular expressions
   ctlradio_perl.p_value = 1;
   EXPRESSION_DIRTY(true);
   EXPRESSION_TYPE('L');

   // Default to case sensitive
   ctlcheck_casesensitive.p_value = CASE_SENSITIVE() ? 1 : 0;

   // Default is single-line processing
   ctlcheck_multiline.p_value = MULTILINE() ? 1 : 0;
   EXPRESSION_DIRTY(false);

   ClearAllPics(ctledit_testcases);

   _retrieve_prev_form();
   // Reload the last testcase text and expression details. This is used to save the text
   // whenever the user changes the docked/floating position
   if (EXPRESSION_DIRTY())
      ImmediateUpdate();
}

static void clearRevaluatorControls()
{
   ctledit_testcases._lbclear();
   ctltext_expression.p_text = '';
}

static void resizeRevaluatorControls()
{
   // if the minimum width has not been set, it will return 0
   if (!_minimum_width()) {
      _set_minimum_size(ctlradio_perl.p_x_extent, 2000);
   }

   // RGH - 4/26/2006
   // For the plugin, first resize the SWT container then do the normal resize
   avail_x := avail_y := 0;
   if (isEclipsePlugin()) {
      regexOutputContainer := tw_find_form(TBREGEX_FORM);
      if(!regexOutputContainer) return;
      old_wid := p_window_id;
      // RGH - 4/26/2006
      // Set p_window_id here so we can find the right controls
      p_window_id = regexOutputContainer;
      eclipse_resizeContainer(regexOutputContainer);
      avail_x  = regexOutputContainer.p_parent.p_width;
      avail_y  = regexOutputContainer.p_parent.p_height;
      // When the regex pane is minimized in Eclipse, the resize causes 
      // weirdness...so don't do it
      if (avail_x == 0 && avail_y == 0) {
         return;
      }
   } else {
      // how much space do we have to work with?
      avail_x  = _dx2lx(p_active_form.p_xyscale_mode,p_active_form.p_client_width);
      avail_y  = _dy2ly(p_active_form.p_xyscale_mode,p_active_form.p_client_height);
   }

   padding_x := _dx2lx(SM_TWIP,4);
   padding_y := _dy2ly(SM_TWIP,4);

   // All these toolbar button should be the same size 
   // (allow them to be up to 33% larger than font height)
   ctllabel_testcases.p_auto_size=true;
   ctllabel_testcases.p_x = padding_x;
   ctllabel_testcases.p_y = padding_y;
   max_button_height := ctllabel_testcases.p_height + 2*padding_y;
   max_button_height += (max_button_height intdiv 3);

   space_x := _dx2lx(SM_TWIP, def_toolbar_pic_hspace);
   ctlimgbtn_saveas.resizeToolButton(max_button_height);
   ctlimgbtn_save.resizeToolButton(max_button_height);
   ctlimgbtn_open.resizeToolButton(max_button_height);
   ctlimgbtn_new.resizeToolButton(max_button_height);
   alignControlsHorizontal(avail_x - 4*(ctlimgbtn_new.p_width+space_x) - padding_x,
                           padding_y,
                           space_x,
                           ctlimgbtn_saveas.p_window_id,
                           ctlimgbtn_save.p_window_id,
                           ctlimgbtn_open.p_window_id,
                           ctlimgbtn_new.p_window_id);

   // adjust size of sample regular expression text
   ctllabel_testcases.p_y = ctlimgbtn_new.p_y_extent - ctllabel_testcases.p_height - padding_y;
   ctledit_testcases.p_y = max(ctlimgbtn_new.p_y_extent, ctllabel_testcases.p_y_extent) + padding_y;
   ctledit_testcases.p_y_extent = avail_y - padding_y - ctlcheck_casesensitive.p_height - padding_y - ctltext_expression.p_height - padding_y - ctlradio_slickedit.p_height - padding_y;
   ctledit_testcases.p_x = padding_x;
   ctledit_testcases.p_width = avail_x - 2*padding_x;

   // adjust positions of regular expression options
   ctllabel_regextype.p_auto_size = true;
   ctlradio_perl.p_auto_size = true;
   ctlradio_slickedit.p_auto_size = true;
   ctlradio_vim.p_auto_size = true;
   ctllabel_regextype.p_y = ctledit_testcases.p_y_extent + padding_y;
   ctlradio_perl.p_y = ctllabel_regextype.p_y;
   ctlradio_slickedit.p_y = ctllabel_regextype.p_y;
   ctlradio_vim.p_y = ctllabel_regextype.p_y;
   ctllabel_regextype.p_x = padding_x;
   ctlradio_perl.p_x = ctllabel_regextype.p_x_extent + 120 + padding_x;
   ctlradio_slickedit.p_x = ctlradio_perl.p_x_extent + 120 + padding_x;
   ctlradio_vim.p_x = ctlradio_slickedit.p_x_extent + 120 + padding_x;

   // adjust position and size of regular expression text box
   _re_button.p_height = ctltext_expression.p_height;
   ctltext_expression.p_x = padding_x;
   ctltext_expression.p_y = ctlradio_perl.p_y_extent + padding_y;
   sizeBrowseButtonToTextBox(ctltext_expression.p_window_id, 
                             _re_button.p_window_id, 0, 
                             avail_x - padding_x);

   // adjust the checkbox positions
   ctlcheck_multiline.p_auto_size=true;
   ctlcheck_casesensitive.p_auto_size=true;
   ctlcheck_multiline.p_y = ctltext_expression.p_y_extent + padding_y;
   ctlcheck_casesensitive.p_y = ctlcheck_multiline.p_y;
   ctlcheck_multiline.p_x = padding_x;
   ctlcheck_casesensitive.p_x = ctlcheck_multiline.p_x_extent + 120 + padding_x;

}

void ctledit_testcases.on_create()
{
   ctledit_testcases.p_UTF8=true;
   CASE_SENSITIVE(true);
   MULTILINE(false);
   ALLOCATEDPIX(0);
   _tbregex_form_initial_alignment();

   // Set up color indices.
   // Group matches use a yellow background
   if (COLORINDEX_GROUPMATCH == 0)
      COLORINDEX_GROUPMATCH = _AllocColor();
   _default_color(COLORINDEX_GROUPMATCH, 0x80000008, 0x0000FFFF, 0);

   // Allocate a PIC for group-match boxes
   if (MARKERTYPE_GROUPBOX < 1) {
      MARKERTYPE_GROUPBOX = _MarkerTypeAlloc();
      _MarkerTypeSetFlags(MARKERTYPE_GROUPBOX, VSMARKERTYPEFLAG_DRAW_BOX|VSMARKERTYPEFLAG_DRAW_SQUIGGLY|VSMARKERTYPEFLAG_AUTO_REMOVE);
   }
   // Allocate a PIC for whole matches
   if (MARKERTYPE_WHOLEMATCH < 1) {
      MARKERTYPE_WHOLEMATCH = _MarkerTypeAlloc();
      _MarkerTypeSetFlags(MARKERTYPE_WHOLEMATCH, /*VSMARKERTYPEFLAG_DRAW_NONE|VSMARKERTYPEFLAG_AUTO_REMOVE |*/ VSMARKERTYPEFLAG_DRAW_SQUIGGLY);
   }
   // Cache the index of the bitmap we'll use for the line picture
   picbmpID = find_index('_ed_exec.svg',PICTURE_TYPE);

   // Set up the timer, passing in the structure parameter
   int timerHandle = _set_timer(250, onRevaluatorTimer,p_active_form);

   // Cache the timer handle in the form so that
   // we can release it later.
   // We increment the timer handle value by one since a valid
   // timer can be 0. But we don't want to store a zero as
   // dialog info (since a 0 in the dialog info could mean it's not been set)
   _SetDialogInfo(DLGINFO_TIMER_HANDLE, (timerHandle + 1), p_active_form);
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _tbregex_form_initial_alignment()
{
   rightAlign := ctledit_testcases.p_x_extent;
   ctlimgbtn_saveas.p_x = rightAlign - ctlimgbtn_saveas.p_width;
   ctlimgbtn_save.p_x = ctlimgbtn_saveas.p_x - (ctlimgbtn_save.p_width + 15);
   ctlimgbtn_open.p_x = ctlimgbtn_save.p_x - (ctlimgbtn_open.p_width + 15);
   ctlimgbtn_new.p_x = ctlimgbtn_open.p_x - (ctlimgbtn_new.p_width + 15);

   changeY := (ctlimgbtn_new.p_y_extent + 30) - ctledit_testcases.p_y;
   ctledit_testcases.p_y += changeY;
   ctledit_testcases.p_height -= changeY;
   ctllabel_testcases.p_y += changeY;
}

void ctledit_testcases.'ESC'()
{
   // If the editor has a selection, deselect.
   if (_select_type()!='') {
      _deselect();
   } else {
      // Otherwise, let the ESC key through to the dialog, which may dismiss the dialog
      ctlradio_slickedit.call_event(ctlradio_slickedit, ESC);
   }  
}

void ctltext_expression.on_change()
{
   // Flag the text as dirty so that the timer proc
   // will know when to fire of an evaluation
   EXPRESSION_DIRTY(true);
}

void ctltext_expression.on_create()
{
   // Set the font face and size to match
   // what the user has set for code editing windows
   _str defEditFont = _default_font(CFG_WINDOW_TEXT);
   fname := "";
   typeless fsize='';
   typeless fflags='';
   parse _default_font(CFG_WINDOW_TEXT) with fname','fsize','fflags','. ;
   p_font_name = fname;
   p_font_size = fsize;
}

void ctlradio_perl.lbutton_up()
{
   // Change the current expression type to Brief syntax
   EXPRESSION_TYPE('L');
   EXPRESSION_DIRTY(true);
}

void ctlradio_slickedit.lbutton_up()
{
   // Change the current expression type to SlickEdit syntax
   EXPRESSION_TYPE('R');
   EXPRESSION_DIRTY(true);
}
void ctlradio_vim.lbutton_up()
{
   // Change the current expression type to SlickEdit syntax
   EXPRESSION_TYPE('~');
   EXPRESSION_DIRTY(true);
}

void ctlcheck_casesensitive.lbutton_up()
{
   CASE_SENSITIVE((p_value == 1));
   EXPRESSION_DIRTY(true);
   ImmediateUpdate();
}

void ctlcheck_multiline.lbutton_up()
{
   MULTILINE((p_value == 1));
   EXPRESSION_DIRTY(true);
   ImmediateUpdate();
}

// Button commands for loading and saving expressions
void ctlimgbtn_saveas.lbutton_up()
{
   _str savedFile = saveRegexFileAs(LASTFILEPATH());
   if (savedFile != null) {
      LASTFILEPATH(savedFile);
   }
}
void ctlLastFilePath.on_change() {
   caption := "Regex Evaluator";
   if (p_text!='') {
      caption :+= " : " :+ _strip_filename(p_text, 'P');
   }
   p_active_form.p_caption = caption;
}
void ctlimgbtn_save.lbutton_up()
{
   // If the current document has a file name (dialog's REGEX_FILE_NAME property), save it.
   _str currentFileName = LASTFILEPATH();
   if (currentFileName != null && currentFileName!='') {
      // Get the test case text out of the edit buffer
      testCases := ctledit_testcases.get_text(ctledit_testcases.p_buf_size, 0);
      saveRegexFile(currentFileName, ctltext_expression.p_text, testCases, EXPRESSION_TYPE());
      LASTFILEPATH(currentFileName);
   } else {
      currentFileName = saveRegexFileAs();
      if (currentFileName != null && currentFileName != '') {
         LASTFILEPATH(currentFileName);
      }
   }
}

void ctlimgbtn_open.lbutton_up()
{
   // Prompt for a .regx file.
   _str fileToOpen = _OpenDialog("-modal", "Open Regex file", "*.regx", REGXFILEFILTER, OFN_FILEMUSTEXIST,
                                 "","",_strip_filename(LASTFILEPATH(),'N')
                                 );
   if (fileToOpen != null && length(fileToOpen) > 0) {
      _str regularExpression = null;
      _str testCases = null;
      _str regexTypeCode = null;
      if (openRegexFile( fileToOpen, regularExpression, testCases, regexTypeCode)) {
         // Clear out and populate the test case area
         ClearAllPics(ctledit_testcases);
         ctledit_testcases._lbclear();
         ctledit_testcases._insert_text(testCases);
         ctledit_testcases.top();
         ctledit_testcases.up();
         // Set the expression text
         ctltext_expression.p_text = regularExpression;
         // Toggle the correct expression type
         switch (regexTypeCode) {
         case "R":
            ctlradio_slickedit.p_value = 1;
            break;
         case "U":
            ctlradio_perl.p_value = 1;
            break;
         case "B":
            ctlradio_perl.p_value = 1;
            break;
         case "L":
            ctlradio_perl.p_value = 1;
            break;
         case "~":
            ctlradio_vim.p_value = 1;
            break;
         }
         // Set the dialog's REGEX_FILE_NAME property
         LASTFILEPATH(fileToOpen);

         // TODO: Set controls for multiline/case-sensitive
         // Immediately update the controls
         ImmediateUpdate();
      }
   }
}

void ctlimgbtn_new.lbutton_up()
{
   // Clear the existing expression test case
   clearRevaluatorControls();
}

static _str saveRegexFileAs(_str lastFilePath='')
{
   // Prompt for a file name and save the file
   _str fileToSaveAs = _OpenDialog("-modal", "Save Regex as...", "*.regx", REGXFILEFILTER, OFN_SAVEAS,
                                   "regx",_strip_filename(lastFilePath,'P'),_strip_filename(lastFilePath,'N'));
   // Strip file options from front
   opts := "";
   _str filePathOnly = strip_options(fileToSaveAs, opts, true, false);
   if (filePathOnly != null && length(filePathOnly) > 0) {
      // Get the test case text out of the edit buffer
      testCases := ctledit_testcases.get_text(ctledit_testcases.p_buf_size, 0);
      saveRegexFile(filePathOnly, ctltext_expression.p_text, testCases, EXPRESSION_TYPE());
      return filePathOnly;
   }
   return null;
}

static bool openRegexFile(_str filePath, _str& expression, _str& testCases, _str& typeCode)
{
   // Open and read the XML document
   loadedOK := false;
   expression = "";
   testCases = "";
   typeCode = "R";
   status := 0;
   int xml_handle = _xmlcfg_open(filePath, status, 0);
   if (xml_handle >= 0) {
      // Fetch the top-level <Regex> node
      int regexNode = _xmlcfg_find_child_with_name(xml_handle, TREE_ROOT_INDEX, "Regex");
      if (regexNode >=0) {
         // Get the expression type code attribute (R == SlickEdit, B == Brief, U == Unix)
         typeCode = _xmlcfg_get_attribute(xml_handle, regexNode, "TypeCode", "R");

         // Get the <Expression> node, and the contents of the child CDATA section
         int expressionNode = _xmlcfg_find_child_with_name(xml_handle, regexNode, "Expression");
         if (expressionNode > 0) {
            int expressionCDATANode = _xmlcfg_get_first_child(xml_handle, expressionNode, VSXMLCFG_NODE_CDATA | VSXMLCFG_NODE_PCDATA);
            if (expressionCDATANode > 0) {
               expression = _xmlcfg_get_value(xml_handle, expressionCDATANode);
               // Set the loadedOK flag. We only need the expression. The TestCase is optional
               loadedOK = true;
            }
         }

         // Get the <TestCase> node and the contents of the child CDATA section
         int testCaseNode = _xmlcfg_find_child_with_name(xml_handle, regexNode, "TestCase");
         if (testCaseNode > 0) {
            int testCaseCDATANode = _xmlcfg_get_first_child(xml_handle, testCaseNode, VSXMLCFG_NODE_CDATA | VSXMLCFG_NODE_PCDATA);
            if (testCaseCDATANode > 0) {
               testCases = _xmlcfg_get_value(xml_handle, testCaseCDATANode);
            }
         }
      }
   }
   return loadedOK;
}

static void saveRegexFile(_str filePath, _str expression, _str testCases, _str typeCode)
{
   // Don't bother saving empty expressions. Empty test cases are OK.
   if (expression == null || length(expression) == 0) {
      message("Cannot save empty expression");
      return;
   }

   // Save the expression and test cases in an XML document
   savePath := _maybe_quote_filename(filePath);
   int xml_handle = _xmlcfg_create(savePath, VSENCODING_AUTOXML, VSXMLCFG_CREATE_IF_EXISTS_CLEAR);
   if (xml_handle >= 0) {
      // add the <?xml?> declaration
      int declNode = _xmlcfg_add(xml_handle, TREE_ROOT_INDEX, 'xml version="1.0" encoding="UTF-8"', VSXMLCFG_NODE_XML_DECLARATION, VSXMLCFG_ADD_AS_CHILD);

      // Create the Top-level <Regex> node, and set the TypeCode attribute
      int regexNode = _xmlcfg_add(xml_handle, TREE_ROOT_INDEX, "Regex", VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
      if (typeCode == null || length(typeCode) == 0)
         typeCode = "R";
      _xmlcfg_set_attribute(xml_handle, regexNode, "TypeCode", typeCode);

      // Create the <Expression> node with the expression text as a CDATA section
      int expressionNode = _xmlcfg_add(xml_handle, regexNode, "Expression", VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
      int expressionCDATANode = _xmlcfg_add(xml_handle, expressionNode, "", VSXMLCFG_NODE_CDATA, VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_set_value(xml_handle, expressionCDATANode, expression);

      // Create the <TestCase> node with the test case text (if any) as a CDATA section
      int testCaseNode = _xmlcfg_add(xml_handle, regexNode, "TestCase", VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
      int testCaseCDATANode = _xmlcfg_add(xml_handle, testCaseNode, "", VSXMLCFG_NODE_CDATA, VSXMLCFG_ADD_AS_CHILD);
      if (testCases != null && length(testCases) > 0)
         _xmlcfg_set_value(xml_handle, testCaseCDATANode, testCases);

      int ret = _xmlcfg_save(xml_handle, -1, VSXMLCFG_SAVE_ONE_LINE_IF_ONE_ATTR, null, VSENCODING_UTF8);
      _xmlcfg_close(xml_handle);
   }
}


/**
 * Shows the Regex Evaluator toolwindow
 *
 * @return
 */
_command activate_regex_evaluator()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   return activate_tool_window(TBREGEX_FORM, true, 'ctltext_expression', true);
}


