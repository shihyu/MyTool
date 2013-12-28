////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47140 $
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
#import "guiopen.e"
#import "listbox.e"
#import "picture.e"
#import "stdprocs.e"
#import "tbautohide.e"
#import "tbpanel.e"
#import "toolbar.e"
#endregion

#define DLGINFO_TIMER_HANDLE 0
#define DLGINFO_REGEX_FILE_NAME 1

static _str expressionType = 'U';
static _str regxFileFilter = "Regex files (*.regx),All Files (*.*)";
static int COLORINDEX_GROUPMATCH = 0;
static int MARKERTYPE_GROUPBOX = 0;
static int MARKERTYPE_WHOLEMATCH = 0;
static int picbmpID = 0;
static int allocatedPix = 0;
static boolean expressionDirty = false;
static boolean multilineMode = false;
static boolean caseSensitive = true;
static boolean restoreDestroyed = false;
static int editorHandle = 0;
static int expressionHandle = 0;

static _str lastExpression = '';
static _str lastTestCase = '';
static _str lastExpressionType = '';
static _str lastFilePath = '';

definit()
{
   expressionType = 'U';
   regxFileFilter = "Regex files (*.regx),All Files (*.*)";
   COLORINDEX_GROUPMATCH = 0;
   MARKERTYPE_GROUPBOX = 0;
   MARKERTYPE_WHOLEMATCH = 0;
   picbmpID = 0;
   allocatedPix = 0;
   expressionDirty = false;
   multilineMode = false;
   caseSensitive = true;
   restoreDestroyed = false;
   editorHandle = 0;
   expressionHandle = 0;
   lastExpression = '';
   lastTestCase = '';
   lastExpressionType = '';
   lastFilePath = '';
}

/*
Not saving enough space to warrent resetting these variables.
void _before_write_state_tbregex()
{
   lastExpression = '';
   lastTestCase = '';
   lastExpressionType = '';
   lastFilePath = '';
} */

void onRevaluatorTimer(typeless argument1)
{
   // Make sure at least .5 seconds has elapsed
   // since the last key press on the dialog
   long elapsed = _idle_time_elapsed();

   if((elapsed > 300) && (editorHandle > 0) && (expressionHandle > 0))
   {
      // Expensive (but right now necessary) check to make sure
      // we're not trying to talk to a window that's been destroyed
      if(!_iswindow_valid(editorHandle) || !editorHandle._isEditorCtl())
      {
         editorHandle = 0;
         expressionHandle = 0;
         return;
      }

      // See if either the edit control window or the expression
      // window has been modified since the last evaluation
      if(expressionDirty || editorHandle.p_modify)
      {
         ImmediateUpdate();
      }
   }
}

// Forces an immediate evaluation of the regular expression.
//  Called when the update timer is fired, or called directly
//  when a user loads a saved expression from disk.
static void ImmediateUpdate()
{
   if ((editorHandle > 0) && (expressionHandle > 0))
   {
      editorHandle.p_modify = false;
      expressionDirty = false;
      if (multilineMode)
      {
         highlightExpressionMatches(editorHandle, expressionHandle, true);
      }
      else
      {
         highlightExpressionMatches(editorHandle, expressionHandle, false);
      }
   }
}

// This method deals with the entire buffer, which is how we support "multiline mode"
// Multiline mode searches require the \om regex option to be part of the regex itself
// (which is a strange departure from most implementations)
static void highlightExpressionMatches(int editorWindow, int expressionWindow, boolean asMultiline)
{
   // Clear out any allocated pics for groups
   ClearAllPics(editorWindow);

   // Grab the regular expression text
   _str expressionToTest = expressionWindow.p_text;
   if((expressionToTest == null) || (length(expressionToTest) < 1))
   {
      return;
   }

   // Make sure the expression contains the \om specification
   // The user may have already specified it in the expression itself
   // If not, tack it on the front. We don't actually modify the user's
   // text in the expression window.
   if(asMultiline)
   {
      if(pos('\om', expressionToTest) == 0)
            expressionToTest = '\om' :+ expressionToTest;
   }

   // Save the current editor position info
   int oldLine = editorWindow.p_line;
   int oldCol = editorWindow.p_col;

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
   _str searchOpts = expressionType;
   // Set the case sensitivity option
   if(caseSensitive == false)
      searchOpts = searchOpts :+ "I";

   // Look for the first occurrence
   int found = editorWindow.search(expressionToTest, searchOpts);
   if(found == INVALID_REGULAR_EXPRESSION_RC)
   {
      // Set the expression text entry area to have a red foreground
      expressionWindow.p_forecolor = 0x000000FF;
      _str msg = get_message(INVALID_REGULAR_EXPRESSION_RC);
      message(msg);
   } else
   {
      // Reset the expression entry area to have the normal foreground
      expressionWindow.p_forecolor = 0x80000008;
   }
   // This multiline search treats the whole contents of the editor
   // as the test case (the "haystack", as it were).
   int totalMatches = 0;
   int totalZeroLenMatches = 0;
   while(found == 0)
   {
      totalMatches++;
      int matchLen = match_length();
      long currentPos = editorWindow._QROffset();

      // Bail out on zero-length matches
      if(matchLen == 0)
      {
         totalZeroLenMatches++;
         if(totalZeroLenMatches > 200)
         {
            ClearAllPics(editorWindow);
            message("Too many zero-length matches found");
            totalMatches = 0;
            found = -1;
            continue;
         }
      }
      int startPos = match_length('S');

      // Retrieve the matched text and create our HTML message for the PIC gutter area
      _str matchedText = editorWindow.get_text(matchLen, startPos);
      if(matchedText != null)
         _escape_html_chars(matchedText);
      _str msg = "Matched [<b>"matchedText"</b>]<br>&nbsp;&nbsp;<i>Start "startPos", Length "matchLen"</i><br>";

      // Since we're not doing line-by-line searching, keep track of the
      // line number where this match was found so we can set up the PIC
      editorWindow._GoToROffset(startPos);
      int lineIdx = editorWindow.p_line;

      // Grab the tagged groups
      int groupIdx = 0;
      for(;groupIdx <= 9; ++groupIdx)
      {
         int groupStart = match_length('S'groupIdx);
         int groupLen = match_length(groupIdx);
         if(groupStart >= 0 && groupLen > 0)
         {
            editorWindow._GoToROffset(groupStart);
            matchedText = editorWindow.get_text(groupLen);
            if(matchedText != null)
               _escape_html_chars(matchedText);

            long off = editorWindow._QROffset();
            // We just build up the message string using all of the group information
            // We'll then add the whole string to the "whole match" PIC message
            _str groupmsg = "&nbsp;Group "groupIdx": [<b>"matchedText"</b>]<br>&nbsp;&nbsp;<i>Start "groupStart", Length "groupLen"</i><br>";
            msg = msg :+ groupmsg;
            int picID = _StreamMarkerAdd(editorWindow.p_window_id, off, groupLen, true, picbmpID, MARKERTYPE_GROUPBOX, "");
            editorWindow._StreamMarkerSetStyleColor(picID, 0xff0000);
            editorWindow._StreamMarkerSetTextColor(picID, COLORINDEX_GROUPMATCH);
            allocatedPix++;
         }
      }

      // Add the "whole match" pic. This doesn't (yet) do any of its own drawing, just adds
      // the bitmap and HTML tooltip with the details
      int mainPicID = _StreamMarkerAdd(editorWindow.p_window_id, startPos, matchLen, true, picbmpID, MARKERTYPE_WHOLEMATCH, msg);
      editorWindow._StreamMarkerSetStyleColor(mainPicID, squiggleColor);
      allocatedPix++;

      editorWindow._GoToROffset(currentPos);
      found = editorWindow.repeat_search(searchOpts);
   }
   if(totalMatches > 0)
   {
      if(totalMatches == 1)
      {
         message("Matched "totalMatches" time");
      }
      else
      {
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
   if(allocatedPix > 0)
   {
      allocatedPix = 0;
      editorHandle._StreamMarkerRemoveAllType(MARKERTYPE_GROUPBOX);
      editorHandle._StreamMarkerRemoveAllType(MARKERTYPE_WHOLEMATCH);
   }
}

defeventtab _tbregex_form;

void _tbregex_form.on_load()
{
   initRevaluatorControls();
   call_event(p_window_id,ON_LOAD,'2');
}

void _tbregex_form.on_destroy()
{
   // Save off control state so that if the dialog
   // is shown again, we'll preserve the expression and
   // test cases
   restoreDestroyed = true;

   // Expression state
   lastExpression = ctltext_expression.p_text;
   lastExpressionType = expressionType;

   // Editor (test case) state and cleanup
   lastTestCase = ctledit_testcases.get_text(ctledit_testcases.p_buf_size, 0);

   // Clean up the allocated colors and PICs
   ClearAllPics(ctledit_testcases.p_window_id);
   // TODO: _FreeColor is causing the interpreter to stop running
   // So for now, we're going to leave this "hang"
   //ctledit_testcases._FreeColor(COLORINDEX_GROUPMATCH);

   // Clean up the timer
   int timerHandle = (int)_GetDialogInfo(DLGINFO_TIMER_HANDLE, ctledit_testcases.p_window_id);
   // Decrement the timer handle since it was incremented before
   // storing it as dialog info
   --timerHandle;
   if(timerHandle >= 0)
   {
      _SetDialogInfo(DLGINFO_TIMER_HANDLE, -1, ctledit_testcases.p_window_id);
      _kill_timer(timerHandle);
   }
   expressionHandle = 0;
   editorHandle = 0;
   call_event(p_window_id,ON_DESTROY,'2');
}

void _tbregex_form.on_resize()
{
   resizeRevaluatorControls();
}

static void initRevaluatorControls()
{
   // Default to Unix regular expressions
   ctlradio_unix.p_value = 1;
   _findre_type.p_text = RE_TYPE_UNIX_STRING;

   // Default to case sensitive
   ctlcheck_casesensitive.p_value = caseSensitive ? 1 : 0;

   // Default is single-line processing
   ctlcheck_multiline.p_value = multilineMode ? 1 : 0;
   expressionDirty = false;

   // Clear out information for current file name
   _SetDialogInfo(DLGINFO_REGEX_FILE_NAME, null, _control ctledit_testcases);
   p_active_form.p_caption = "Regex Evaluator";

   ClearAllPics(ctledit_testcases);

   // Reload the last testcase text and expression details. This is used to save the text
   // whenever the user changes the docked/floating position
   if (restoreDestroyed == true)
   {
      restoreDestroyed = false;

      if (lastExpression != '')
      {
         ctltext_expression.p_text = lastExpression;
         expressionDirty = true;
      }
      if (lastTestCase != '')
      {
         ctledit_testcases._insert_text(lastTestCase);
      }
      if (lastFilePath != null && lastFilePath != '')
      {
         _SetDialogInfo(DLGINFO_REGEX_FILE_NAME, lastFilePath, _control ctledit_testcases);
         _str caption = "Regex Evaluator : " :+ _strip_filename(lastFilePath, 'PE');
         p_active_form.p_caption = caption;
      }
      if (lastExpressionType != '')
      {
         switch (lastExpressionType)
         {
         case 'B':
            ctlradio_unix.p_value = 0;
            ctlradio_slickedit.p_value = 0;
            ctlradio_perl.p_value = 0;
            ctlradio_brief.p_value = 1;
            _findre_type.p_text = RE_TYPE_BRIEF_STRING;
            break;
         case 'L':
            ctlradio_unix.p_value = 0;
            ctlradio_slickedit.p_value = 0;
            ctlradio_brief.p_value = 0;
            ctlradio_perl.p_value = 1;
            _findre_type.p_text = RE_TYPE_PERL_STRING;
            break;
         case 'R':
            ctlradio_unix.p_value = 0;
            ctlradio_brief.p_value = 0;
            ctlradio_perl.p_value = 0;
            ctlradio_slickedit.p_value = 1;
            _findre_type.p_text = RE_TYPE_SLICKEDIT_STRING;
            break;
         case 'U':
            ctlradio_brief.p_value = 0;
            ctlradio_slickedit.p_value = 0;
            ctlradio_perl.p_value = 0;
            ctlradio_unix.p_value = 1;
            _findre_type.p_text = RE_TYPE_UNIX_STRING;
            break;
         }
      }
   }
   _tbpanelUpdateAllPanels(p_active_form.p_DockingArea);
   //p_active_form.refresh("W");
   //activate_window(p_active_form);
   if(expressionDirty)
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
      _set_minimum_size(ctlradio_unix.p_x + ctlradio_unix.p_width, 2000);
   }

   int buttonPadding = 10;
   int padding = 30;

   widthDiff := p_width - (2 * ctledit_testcases.p_x + ctledit_testcases.p_width);
   heightDiff := p_height - (ctlcheck_multiline.p_y + ctlcheck_multiline.p_height + (padding * 3));

   if(widthDiff)
   {
      int menuButtonWidth = _re_button.p_width;
      // Resize the editor control and expression entry width
      ctledit_testcases.p_width += widthDiff;
      ctltext_expression.p_width += widthDiff;

      // Reposition the save/open buttons to right-align with the editor control
      int editorRight = ctledit_testcases.p_x + ctledit_testcases.p_width;

      // All these toolbar button should be the same size
      int buttonWidth = ctlimgbtn_saveas.p_width;
      ctlimgbtn_saveas.p_x += widthDiff;
      ctlimgbtn_save.p_x += widthDiff;
      ctlimgbtn_open.p_x += widthDiff;
      ctlimgbtn_new.p_x += widthDiff;
   }

   if(heightDiff)
   {
      ctlcheck_casesensitive.p_y += heightDiff;
      ctlcheck_multiline.p_y += heightDiff;
      // Align the expression text just above the options checks
      ctltext_expression.p_y += heightDiff;
      // Align the expression type radio controls above the expression text
      ctllabel_regextype.p_y += heightDiff;
      ctlradio_unix.p_y += heightDiff;
      ctlradio_slickedit.p_y += heightDiff;
      ctlradio_brief.p_y += heightDiff;
      ctlradio_perl.p_y += heightDiff;

      // Now adjust the height of the test case edit control to fill
      // the remainder of the vertical space
      ctledit_testcases.p_height += heightDiff;
   }

   // Position the "flyout menu" button just to the right of the expression area
   _re_button.p_x += widthDiff;
   _re_button.p_y += heightDiff;
}

void ctledit_testcases.on_create()
{
   _tbregex_form_initial_alignment();

   // Set up color indices.
   // Group matches use a yellow background
   if(COLORINDEX_GROUPMATCH == 0)
      COLORINDEX_GROUPMATCH = _AllocColor();
   _default_color(COLORINDEX_GROUPMATCH, 0x80000008, 0x0000FFFF, 0);

   // Allocate a PIC for group-match boxes
   if(MARKERTYPE_GROUPBOX < 1)
   {
      MARKERTYPE_GROUPBOX = _MarkerTypeAlloc();
      _MarkerTypeSetFlags(MARKERTYPE_GROUPBOX, VSMARKERTYPEFLAG_DRAW_BOX|VSMARKERTYPEFLAG_DRAW_SQUIGGLY|VSMARKERTYPEFLAG_AUTO_REMOVE);
   }
   // Allocate a PIC for whole matches
   if(MARKERTYPE_WHOLEMATCH < 1)
   {
      MARKERTYPE_WHOLEMATCH = _MarkerTypeAlloc();
      _MarkerTypeSetFlags(MARKERTYPE_WHOLEMATCH, /*VSMARKERTYPEFLAG_DRAW_NONE|VSMARKERTYPEFLAG_AUTO_REMOVE |*/ VSMARKERTYPEFLAG_DRAW_SQUIGGLY);
   }
   // Cache the index of the bitmap we'll use for the line picture
   picbmpID = find_index('_execpt.ico',PICTURE_TYPE);

   // Get the callback function for the timer
   int idx = find_index("onRevaluatorTimer", PROC_TYPE);

   // Set up the timer, passing in the structure parameter
   int timerHandle = _set_timer(250, idx);

   // Cache the timer handle in the form so that
   // we can release it later.
   // We increment the timer handle value by one since a valid
   // timer can be 0. But we don't want to store a zero as
   // dialog info (since a 0 in the dialog info could mean it's not been set)
   _SetDialogInfo(DLGINFO_TIMER_HANDLE, (timerHandle + 1), p_window_id);

   editorHandle = p_window_id;
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _tbregex_form_initial_alignment()
{
   rightAlign := ctledit_testcases.p_x + ctledit_testcases.p_width;
   ctlimgbtn_saveas.p_x = rightAlign - ctlimgbtn_saveas.p_width;
   ctlimgbtn_save.p_x = ctlimgbtn_saveas.p_x - (ctlimgbtn_save.p_width + 15);
   ctlimgbtn_open.p_x = ctlimgbtn_save.p_x - (ctlimgbtn_open.p_width + 15);
   ctlimgbtn_new.p_x = ctlimgbtn_open.p_x - (ctlimgbtn_new.p_width + 15);

   changeY := (ctlimgbtn_new.p_y + ctlimgbtn_new.p_height + 30) - ctledit_testcases.p_y;
   ctledit_testcases.p_y += changeY;
   ctledit_testcases.p_height -= changeY;
   ctllabel_testcases.p_y += changeY;

   sizeBrowseButtonToTextBox(ctltext_expression.p_window_id, _re_button.p_window_id, 0, rightAlign);
}

void ctledit_testcases.'ESC'()
{
   // If the editor has a selection, deselect.
   if(_select_type()!=''){
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
   expressionDirty = true;
}

void ctltext_expression.on_create()
{
   expressionHandle = p_window_id;
   // Set the font face and size to match
   // what the user has set for code editing windows
   _str defEditFont = _default_font(CFG_WINDOW_TEXT);
   _str fname='';
   typeless fsize='';
   typeless fflags='';
   parse _default_font(CFG_WINDOW_TEXT) with fname','fsize','fflags','. ;
   p_font_name = fname;
   p_font_size = fsize;
}

void ctlradio_brief.lbutton_up()
{
   // Change the current expression type to Brief syntax
   expressionType = 'B';
   _findre_type.p_text = RE_TYPE_BRIEF_STRING;
   expressionDirty = true;
}

void ctlradio_slickedit.lbutton_up()
{
   // Change the current expression type to SlickEdit syntax
   expressionType = 'R';
   _findre_type.p_text = RE_TYPE_SLICKEDIT_STRING;
   expressionDirty = true;
}

void ctlradio_unix.lbutton_up()
{
   // Change the current expression type to Unix syntax
   expressionType = 'U';
   _findre_type.p_text = RE_TYPE_UNIX_STRING;
   expressionDirty = true;
}

void ctlradio_perl.lbutton_up()
{
   // Change the current expression type to Perl syntax
   expressionType = 'L';
   _findre_type.p_text = RE_TYPE_PERL_STRING;
   expressionDirty = true;
}

void ctlcheck_casesensitive.lbutton_up()
{
   caseSensitive = (p_value == 1);
   expressionDirty = true;
   ImmediateUpdate();
}

void ctlcheck_multiline.lbutton_up()
{
   multilineMode = (p_value == 1);
   expressionDirty = true;
   ImmediateUpdate();
}

// Button commands for loading and saving expressions
void ctlimgbtn_saveas.lbutton_up()
{
   _str savedFile = saveRegexFileAs();
   if(savedFile != null)
   {
      _SetDialogInfo(DLGINFO_REGEX_FILE_NAME, savedFile, ctledit_testcases);
      _str caption = "Regex Evaluator : " :+ _strip_filename(savedFile, 'PE');
      p_active_form.p_caption = caption;
      lastFilePath = savedFile;
      _tbpanelUpdateAllPanels(p_active_form.p_DockingArea);
   }
}

void ctlimgbtn_save.lbutton_up()
{
   // If the current document has a file name (dialog's REGEX_FILE_NAME property), save it.
   _str currentFileName = _GetDialogInfo(DLGINFO_REGEX_FILE_NAME, ctledit_testcases);
   if(currentFileName != null)
   {
      // Get the test case text out of the edit buffer
      _str testCases = ctledit_testcases.get_text(ctledit_testcases.p_buf_size, 0);
      saveRegexFile(currentFileName, ctltext_expression.p_text, testCases, expressionType);
      lastFilePath = currentFileName;
   } else
   {
      currentFileName = saveRegexFileAs();
      if(currentFileName != null && currentFileName != '')
      {
         lastFilePath = currentFileName;
         _SetDialogInfo(DLGINFO_REGEX_FILE_NAME, currentFileName, ctledit_testcases);
         _str caption = "Regex Evaluator : " :+ _strip_filename(currentFileName, 'PE');
         p_active_form.p_caption = caption;
         _tbpanelUpdateAllPanels(p_active_form.p_DockingArea);
      }
   }
}

void ctlimgbtn_open.lbutton_up()
{
   // Prompt for a .regx file.
   _str fileToOpen = _OpenDialog("-modal", "Open Regex file", "*.regx", regxFileFilter, OFN_FILEMUSTEXIST);
   if(fileToOpen != null && length(fileToOpen) > 0)
   {
      _str regularExpression = null;
      _str testCases = null;
      _str regexTypeCode = null;
      if(openRegexFile( fileToOpen, regularExpression, testCases, regexTypeCode))
      {
         // Clear out and populate the test case area
         ClearAllPics(ctledit_testcases.p_window_id);
         ctledit_testcases._lbclear();
         ctledit_testcases._insert_text(testCases);
         ctledit_testcases.top();
         ctledit_testcases.up();
         // Set the expression text
         ctltext_expression.p_text = regularExpression;
         // Toggle the correct expression type
         switch(regexTypeCode)
         {
         case "R":
            {
               ctlradio_slickedit.p_value = 1;
               break;
            }
         case "U":
            {
               ctlradio_unix.p_value = 1;
               break;
            }
         case "B":
            {
               ctlradio_brief.p_value = 1;
               break;
            }
         case "L":
            {
               ctlradio_perl.p_value = 1;
               break;
            }
         }
         // Set the dialog's REGEX_FILE_NAME property
         lastFilePath = fileToOpen;
         _SetDialogInfo(DLGINFO_REGEX_FILE_NAME, fileToOpen, ctledit_testcases);
         _str caption = "Regex Evaluator : " :+ _strip_filename(fileToOpen, 'PE');
         p_active_form.p_caption = caption;
         _tbpanelUpdateAllPanels(p_active_form.p_DockingArea);

         // TODO: Set controls for multiline/case-sensitive
         // Immediately update the controls
         ImmediateUpdate();
      }
   }
}

void ctlimgbtn_new.lbutton_up()
{
   // Clear the existing expression test cases, and set controls back
   // to default state
   clearRevaluatorControls();
   lastExpression = '';
   lastTestCase = '';
   lastExpressionType = '';
   lastFilePath = '';
   initRevaluatorControls();
}

static _str saveRegexFileAs()
{
   // Prompt for a file name and save the file
   _str fileToSaveAs = _OpenDialog("-modal", "Save Regex as...", "*.regx", regxFileFilter, OFN_SAVEAS);
   // Strip file options from front
   _str opts = '';
   _str filePathOnly = strip_options(fileToSaveAs, opts, true, false);
   if(filePathOnly != null && length(filePathOnly) > 0)
   {
      // Get the test case text out of the edit buffer
      _str testCases = ctledit_testcases.get_text(ctledit_testcases.p_buf_size, 0);
      saveRegexFile(filePathOnly, ctltext_expression.p_text, testCases, expressionType);
      return filePathOnly;
   }
   return null;
}

static boolean openRegexFile(_str filePath, _str& expression, _str& testCases, _str& typeCode)
{
   // Open and read the XML document
   boolean loadedOK = false;
   expression = "";
   testCases = "";
   typeCode = "R";
   int status = 0;
   int xml_handle = _xmlcfg_open(filePath, status, 0);
   if(xml_handle >= 0)
   {
      // Fetch the top-level <Regex> node
      int regexNode = _xmlcfg_find_child_with_name(xml_handle, TREE_ROOT_INDEX, "Regex");
      if(regexNode >=0)
      {
         // Get the expression type code attribute (R == SlickEdit, B == Brief, U == Unix)
         typeCode = _xmlcfg_get_attribute(xml_handle, regexNode, "TypeCode", "R");

         // Get the <Expression> node, and the contents of the child CDATA section
         int expressionNode = _xmlcfg_find_child_with_name(xml_handle, regexNode, "Expression");
         if(expressionNode > 0)
         {
            int expressionCDATANode = _xmlcfg_get_first_child(xml_handle, expressionNode, VSXMLCFG_NODE_CDATA | VSXMLCFG_NODE_PCDATA);
            if(expressionCDATANode > 0)
            {
               expression = _xmlcfg_get_value(xml_handle, expressionCDATANode);
               // Set the loadedOK flag. We only need the expression. The TestCase is optional
               loadedOK = true;
            }
         }

         // Get the <TestCase> node and the contents of the child CDATA section
         int testCaseNode = _xmlcfg_find_child_with_name(xml_handle, regexNode, "TestCase");
         if(testCaseNode > 0)
         {
            int testCaseCDATANode = _xmlcfg_get_first_child(xml_handle, testCaseNode, VSXMLCFG_NODE_CDATA | VSXMLCFG_NODE_PCDATA);
            if(testCaseCDATANode > 0)
            {
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
   if(expression == null || length(expression) == 0)
   {
      message("Cannot save empty expression");
      return;
   }

   // Save the expression and test cases in an XML document
   _str savePath = maybe_quote_filename(filePath);
   int xml_handle = _xmlcfg_create(savePath, VSENCODING_AUTOXML, VSXMLCFG_CREATE_IF_EXISTS_CLEAR);
   if(xml_handle >= 0)
   {
      // add the <?xml?> declaration
      int declNode = _xmlcfg_add(xml_handle, TREE_ROOT_INDEX, 'xml version="1.0" encoding="UTF-8"', VSXMLCFG_NODE_XML_DECLARATION, VSXMLCFG_ADD_AS_CHILD);

      // Create the Top-level <Regex> node, and set the TypeCode attribute
      int regexNode = _xmlcfg_add(xml_handle, TREE_ROOT_INDEX, "Regex", VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
      if(typeCode == null || length(typeCode) == 0)
         typeCode = "R";
      _xmlcfg_set_attribute(xml_handle, regexNode, "TypeCode", typeCode);

      // Create the <Expression> node with the expression text as a CDATA section
      int expressionNode = _xmlcfg_add(xml_handle, regexNode, "Expression", VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
      int expressionCDATANode = _xmlcfg_add(xml_handle, expressionNode, "", VSXMLCFG_NODE_CDATA, VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_set_value(xml_handle, expressionCDATANode, expression);

      // Create the <TestCase> node with the test case text (if any) as a CDATA section
      int testCaseNode = _xmlcfg_add(xml_handle, regexNode, "TestCase", VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
      int testCaseCDATANode = _xmlcfg_add(xml_handle, testCaseNode, "", VSXMLCFG_NODE_CDATA, VSXMLCFG_ADD_AS_CHILD);
      if(testCases != null && length(testCases) > 0)
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
_command activate_regex_evaluator()  name_info(','VSARG2_EDITORCTL)
{
   return activate_toolbar('_tbregex_form','ctltext_expression');
}


