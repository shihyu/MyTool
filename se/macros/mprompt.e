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
#import "complete.e"
#import "guicd.e"
#import "guiopen.e"
#import "listbox.e"
#import "main.e"
#import "math.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tbopen.e"
#endregion

_control _ok;
_control _help;
_control _cancel;

defeventtab _textbox_browse_file;

void ctlbrowse.lbutton_up()
{
   typeless result=_OpenDialog('-modal',
                      '',                   // Dialog Box Title
                      '',                   // Initial Wild Cards
                      def_file_types,       // File Type List
                      OFN_FILEMUSTEXIST     // Flags
                      );
   if (result!='') {
      p_prev.p_text=result;
      p_prev._set_focus();
   }
}

void ctlbrowsenq.lbutton_up()
{
   typeless result=_OpenDialog('-modal',
                      '',                   // Dialog Box Title
                      '',                   // Initial Wild Cards
                      def_file_types,       // File Type List
                      OFN_FILEMUSTEXIST     // Flags
                      );
   if (result!='') {
      p_prev.p_text=strip(result,'B','"');
      p_prev._set_focus();
   }
}


void ctlbrowsedir.lbutton_up()
{
   _str orig_dir=getcwd();
   orig_val := _use_cd_tbopen();
   _use_cd_tbopen(0);
   _str result = _ChooseDirDialog('',p_prev.p_text);
   _use_cd_tbopen((int)orig_val);
   if (result!='') {
      p_prev.p_text=result;
      p_prev._set_focus();
      chdir(orig_dir,1);
   }
}

//defeventtab _textbox_browse_directory;


defeventtab _textbox_text1;
_textbox_text1.' '()
{
   if (p_completion!='') {
      if (p_completion==COMMAND_ARG) {
         maybe_complete();
      } else {
         maybe_complete(p_completion);
      }
      return('');
   }
   keyin(' ');
}
_textbox_text1.'?'()
{
   if (p_completion!='' && def_qmark_complete) {
      if (p_completion==COMMAND_ARG) {
         // Need this so multiple completion args work.
         // Auto ENTER does not seem to work yet.
         maybe_list_matches();
      } else {
         maybe_list_matches(p_completion,'',false,true);
      }
      return('');
   }
   keyin('?');
}
#if 1
void _textbox_text1.on_drop_down(int reason)
{
   if (p_user=='') {
      _retrieve_list();
      p_user=1; // Indicate that retrieve list has been done
   }
}
#endif

defeventtab _textbox_form;

/**
 * Displays one or more text boxes, combo boxes, or check boxes on a modal dialog.
 * <p>
 * If the TB_VIEWID_OUTPUT flag is given, the return value is a view 
 * id containing the response to each text box on separates lines.
 * <p>
 * If the TB_QUERY_COMPAT flag is specified the format of the 
 * buffer is compatible with the output of the QUERY command of 
 * Visual SlickEdit.  The view and buffer should be deleted with 
 * the <b>_delete_temp_view</b> function. 
 * <p>
 * If the TB_VIEWID_OUTPUT flag is not given, the return value is the index
 * of the button pressed (e.g. for buttons in order OK, Cancel -- 1=OK, 2=Cancel), 
 * and the _param1.._paramN global variables are set to the responses to 
 * text1..textN respectively.
 * <p>
 * The limit on the number of prompts/values is 9.
 * 
 * @param FormCaption
 *                 Title of dialog box.
 * 
 * @param Flags    A combinations of the following flags defined in "slick.sh":
 *                 
 *                 <dl compact>
 *                 <dt>TB_RETRIEVE
 *                   <dd style="margin-left:120pt">Create combo boxes instead of text boxes.
 *                   Fill in combo box list with previous response to combo box.  Be sure
 *                   to specify the retrieve_name argument.
 *                 <dt>TB_RETRIEVE_INIT
 *                   <dd style="margin-left:120pt">Same as TB_RETRIEVE.  In addition, combo box
 *                   text is initialized to the previous responses unless the prompt string
 *                   specifies an initial value.
 *                 <dt>TB_VIEWID_INPUT
 *                   <dd style="margin-left:120pt">prompt1 is a view id and no arguments follow prompt1.
 *                   The input view has Name:[Initial_Value] pairs, one-per-line.
 *                 <dt>TB_VIEWID_OUTPUT
 *                   <dd style="margin-left:120pt">The return value will be a view id containing the responses.
 *                   The output view has the Value of each item, one-per-line. IMPORTANT: The value of the button
 *                   pressed (e.g. OK, Cancel, etc.) is not included in the output view. If you are including custom
 *                   buttons, and you need to know which button was pressed by the user, then do NOT use the
 *                   TB_VIEWID_OUTPUT flag -- use _param1.._paramN global variables instead and check the return result
 *                   for which button was pressed (1=first button, 2=second button, etc.).
 *                 <dt>TB_QUERY_COMPAT
 *                   <dd style="margin-left:120pt">The return value will be a view id containing
 *                   the responses in the format of the QUERY.
 *                 </dl>
 * 
 * @param TextBoxWidth
 *                 Specifies width of the text box in twips. 1440 twips is 1 inch on the display.
 *                 Specify 0 for the default text box width.
 * 
 * @param HelpItem Specifies help displayed when F1 is pressed or the help
 *                 button is pressed.  If the help_item starts with a '?'
 *                 character, the characters that follow are displayed in a
 *                 message box.  The help string may also specify a unique
 *                 help index item listed in
 *                 "slickeditindex.xml".
 *                 In addition, you may specify a unique keyword
 *                 for any .chm or .qhc help file by specifying a
 *                 string in the format: <i>HelpIndexItem</i>:<i>help_filename</i>.
 *                 Specify "" for no help.
 * 
 * @param ButtonNCaptionList
 *                 ButtonNCaptionList in the following format:
 *                 
 *                 <blockquote>
 *                 <code>
 *                 <i>ButtonList</i>[\t<i>Caption1</i>[\n<i>Caption2</i>[\n<i>CaptionN</i>]]]
 *                 </code>
 *                 </blockquote>
 *                 
 *                 Where <i>ButtonList</i> is in the format:
 *                 
 *                 <blockquote>
 *                 <code>
 *                 <<i>Caption</i>[:<i>controlName</i>]>[,...]
 *                 </code>
 *                 </blockquote>
 *                 
 *                 Note: <br>
 *                 If you supply a button list, it is up to you to make your own cancel and
 *                 help buttons.  If you have a button with the control name '_cancel', it will
 *                 automatically be set up as the cancel button.  A button with the control name
 *                 '_help' will automatically be set up as the help button.
 *                 <p>
 *                 If the caption starts with "-html ", it will be
 *                 rendered as sunken HTML text.
 *                 <p>
 *                 The same _ok.lbutton_up function will run for all the buttons when they are
 *                 pressed, unless the control name is specified as _help or _cancel.
 *                 <p>
 *                 Specify "" for default OK, Cancel, Help buttons, and no captions.
 *                 Default to "".
 * 
 * @param RetrieveName
 *                 Specify the name of the command that called this function or a name for what is being prompted for.
 *                 Defaults to "".
 * 
 * @param prompt1  You may specify 1 or more prompt string arguments.
 *                 <p>
 *                 The prompt string argument are strings in the following format:
 *                 <blockquote>
 *                 <code>
 *                 <i>options</i> <i>label</i>[: <i>initial_value</i>]
 *                 </code>
 *                 </blockquote>
 *                 <i>options</i> may containing one of the following switches
 *                 <dl style="margin-left:20pt">
 *                 <dt>-r  <i>n1</i>,<i>n2</i>
 *                   <dd>Value in text must be a valid floating pointer number in range <i>n1</i>..<i>n2</i>.
 *                 <dt>-e <i>callback_name</i> [:<i>arg2</i>]
 *                   <dd>Name of global function to call to check input.  First argument to call back
 *                   function is the text in the text box.  Second argument is <i>arg2</i> if specified.
 *                 <dt>-e1 <i>callback_name</i>[:<i>arg2</i>]
 *                   <dd>Name of global function to call to check values in ALL text boxes.  First argument
 *                   is "".  Second argument is <i>arg2</i> if specified.  The text boxes have the control
 *                   names (p_name) text1..textN and are numbered from top to bottom.
 *                 <dt>-checkbox
 *                   <dd>Prompt is a check box instead of a text box.
 *                 </dl>
 * 
 *                 <i>label</i> is the caption to appear to the left of the text box.<br>
 *                 <i>initial_value</i> is the initial value to appear in the text box. <br>
 *                 If -checkbox option is used to create a checkbox, then valid initial values are: <br>
 *                 0 (not checked), 1 (checked). Default initial value is 0. This style of checkbox
 *                 corresponds to a PSCH_AUTO2STATE style.<br>
 *                 If -checkbox3 or -checkbox3a option is used, then valid initial values are: <br>
 *                 0 (not checked), 1 (checked), 2 (grayed). Default initial value is 0. This style of checkbox
 *                 corresponds to a PSCH_AUTO3STATEA style where values cycle through: 0, 2, 1.<br>
 *                 If checkbox3b option is used, then valid initial values are: <br>
 *                 0 (not checked), 1 (checked), 2 (grayed). Default initial value is 0. This style of checkbox
 *                 corresponds to a PSCH_AUTO3STATEB style where values cycle through: 0, 1, 2.<br>
 * 
 * @param promptN  Specify 1 or more prompt arguments.  See prompt1.
 * 
 * @example
 * <pre>
 *  int textBoxForm( <i>title</i> ,<i>flags</i>
 *                   ,<i>text_box_width</i> , <i>help_item</i> [,
 *                   [,<i>retrieve_name</i>
 *                   [,<i>prompt1</i> [,<i>prompt2</i>, ... <i>promptN</i> ]]]] )
 * 
 * @example
 * <pre>
 *    // Display dialog with left, right, paragraph margin settings
 *    parse p_margins with left_ma right_ma new_para_ma
 *    _str new_para_ma = strip(new_para_ma)
 *    int result = textBoxDialog("Margins",     // Form caption
 *                               0,             // Flags
 *                               0,             // Use default textbox width
 *                               "gui_margins", // Help item
 *                               "",            // Buttons and captions
 *                               "gui_margins", // Retrieve Name
 *                               "-E1 _check_margins Left Margin:"left_ma,
 *                               "Right Margin:"right_ma,
 *                               "New Paragraph Margin:"new_para_ma);
 *    if (result!=COMMAND_CANCELLED_RC) {
 *       p_margins=_param1' '_param2' '_param3
 *    }
 * </pre>
 * 
 * @example
 * <pre>
 *    // Display dialog that confirms to remove a file from current project
 *    // and provides a check box to also delete from disk which is initially
 *    // unchecked.
 *    int result = textBoxDialog("Confirm Remove", // Form caption
 *                               0,                // Flags
 *                               0,                // Use default textbox width
 *                               "",               // Help item
 *                               "Yes,No,Cancel:_cancel\tRemove file from project?",
 *                               "",               // Retrieve Name
 *                               "-CHECKBOX Delete permanently from disk:":+0)
 *    if (result==COMMAND_CANCELLED_RC) {
 *       // User clicked "Cancel" or hit ESC
 *    } else if ( result==1 ) {
 *       // User clicked "Yes"
 *       // _param1 stores value of check box (0=unchecked, 1=checked)
 *    } else if ( result==2 ) {
 *       // User clicked "No"
 *    }
 * </pre>
 * 
 * @return COMMAND_CANCELLED_RC if the dialog box is cancelled.
 * INVALID_ARGUMENT_RC if more than the maximum number of prompts.
 * If ButtonNCaptionList!="", then return value is the number
 * of the button that was pressed. Button numbers start at 1.
 * 
 * @categories Forms
 */
int textBoxDialog(_str FormCaption, int Flags, int TextBoxWidth, _str HelpItem,
                  _str ButtonNCaptionList="", _str RetrieveName="",
                  _str prompt1="", _str promptN="", ...) // prompt1 .. promptN
{
   result := "";
   width := "";
   if( TextBoxWidth>0 ) {
      width=TextBoxWidth;
   }
   switch( arg() ) {
   case 7:
      result = show("-modal _textbox_form",
                    FormCaption,Flags,width,HelpItem,ButtonNCaptionList,RetrieveName,
                    arg(7));
      break;
   case 8:
      result = show("-modal _textbox_form",
                    FormCaption,Flags,width,HelpItem,ButtonNCaptionList,RetrieveName,
                    arg(7),arg(8));
      break;
   case 9:
      result = show("-modal _textbox_form",
                    FormCaption,Flags,width,HelpItem,ButtonNCaptionList,RetrieveName,
                    arg(7),arg(8),arg(9));
      break;
   case 10:
      result = show("-modal _textbox_form",
                    FormCaption,Flags,width,HelpItem,ButtonNCaptionList,RetrieveName,
                    arg(7),arg(8),arg(9),arg(10));
      break;
   case 11:
      result = show("-modal _textbox_form",
                    FormCaption,Flags,width,HelpItem,ButtonNCaptionList,RetrieveName,
                    arg(7),arg(8),arg(9),arg(10),arg(11));
      break;
   case 12:
      result = show("-modal _textbox_form",
                    FormCaption,Flags,width,HelpItem,ButtonNCaptionList,RetrieveName,
                    arg(7),arg(8),arg(9),arg(10),arg(11),arg(12));
      break;
   case 13:
      result = show("-modal _textbox_form",
                    FormCaption,Flags,width,HelpItem,ButtonNCaptionList,RetrieveName,
                    arg(7),arg(8),arg(9),arg(10),arg(11),arg(12),arg(13));
      break;
   case 14:
      result = show("-modal _textbox_form",
                    FormCaption,Flags,width,HelpItem,ButtonNCaptionList,RetrieveName,
                    arg(7),arg(8),arg(9),arg(10),arg(11),arg(12),arg(13),arg(14));
      break;
   case 15:
      result = show("-modal _textbox_form",
                    FormCaption,Flags,width,HelpItem,ButtonNCaptionList,RetrieveName,
                    arg(7),arg(8),arg(9),arg(10),arg(11),arg(12),arg(13),arg(14),arg(15));
      break;
   default:
      _message_box("Too many prompt arguments.","", MB_OK|MB_ICONEXCLAMATION);
      return INVALID_ARGUMENT_RC;
   }
   if( result=="" ) {
      return COMMAND_CANCELLED_RC;
   }
   return ( (int)result );
}

static const AFTER_LABEL_PAD=     90;
static const BOX_DEFAULT_WIDTH=   3500;

static _str parse_option(_str &prompt, _str &p1, _str &p2)
{
   prompt=strip(prompt,'L');
   ch := substr(prompt, 1, 1);
   if (ch != '-') {
      return('');
   }
   option := upcase(parse_file(prompt));

   // Need to strip off the leading dash
   check_data := "";
   option=substr(option,2);
   switch (option){
   case 'R':
      parse prompt with  p1','p2 prompt;
      return(upcase(option));
   case 'C':
      parse prompt with  p1 (_chr(0)) prompt;
      return(upcase(option));
   case 'I':
      parse prompt with  p1','p2 prompt;
      return(upcase(option));
   case 'E':
      parse prompt with  check_data prompt;
      parse check_data with p1':'p2;
      return(upcase(option));
   case 'E1':
      parse prompt with  check_data prompt;
      parse check_data with p1':'p2;
      return(upcase(option));
   case 'BF':
      return(upcase(option));
   case 'BFNQ':
      return(upcase(option));
   case 'BD':
      return(upcase(option));
   case 'BNDF':
      return(upcase(option));
   case 'CHECKBOX':
      return(upcase(option));
   case 'CHECKBOX3':
   case 'CHECKBOX3A':
   case 'CHECKBOX3B':
      return(upcase(option));
   case 'PASSWORD':
      return(upcase(option));
   }
   return '';
}

static bool in_irange(int p1, int p2, typeless num)
{
   if ((num > p1 && num > p2) || (num < p1 && num < p2) || !isinteger(num)) {
      _message_box('Field Should be in the range 'p1'...'p2'.');
      return false;
   }
   return true;
}
static bool in_range(int p1, int p2, typeless num)
{
   if ((num > p1 && num > p2) || (num < p1 && num < p2) || !isnumber(num)) {
      _message_box('Field Should be in the range 'p1'...'p2'.');
      return false;
   }
   return true;
}

static int get_width_from_buffer(int buf_view_id)
{
   longest := 0;
   view_id := 0;
   get_window_id(view_id);
   activate_window(buf_view_id);

   line := "";
   prompt := "";
   init_val := "";
   top();up();
   for (;;) {
      down();
      if(rc) break;
      get_line(line);
      parse line with prompt':'init_val;
      prompt :+= ':';
      if (view_id._text_width(prompt) > longest) {
         longest=view_id._text_width(prompt);
      }
   }
   activate_window(view_id);
   return(longest);
}

/*_command void textbox_browse()
{
   if (p_active_form!=_textbox_form) {
      _message_box(nls("This command may only be called from the textbox form"));
      return;
   }
   say('1 p_window_id='p_window_id' p_tab_index='p_tab_index);
   result=_OpenDialog('-modal',
                      '',                   // Dialog Box Title
                      '',                   // Initial Wild Cards
                      def_file_types,       // File Type List
                      OFN_FILEMUSTEXIST     // Flags
                      );
   say('2 p_window_id='p_window_id);
   if (result!='') {
      _message_box(nls("textbox_browse: p_prev.p_object=%s",p_prev.p_object));
      say('3 p_window_id='p_window_id);
      p_prev.p_text=result;
   }
}*/

static const FIRST_DATA_ARG_INDEX= 7;

/**
 * Displays one or more text boxes or combo boxes.
 * <p>
 * If the TB_VIEWID_OUTPUT flag is given, the return value is a view 
 * id containing the response to each text box on separates lines.
 * <p>
 * If the TB_QUERY_COMPAT flag is specified the format of the 
 * buffer is compatible with the output of the QUERY command of 
 * Visual SlickEdit.  The view and buffer should be deleted with 
 * the <b>_delete_temp_view</b> function. 
 * <p>
 * If the TB_VIEWID_OUTPUT flag is not given, the return value is the index
 * of the button pressed (e.g. for buttons in order OK, Cancel -- 1=OK, 2=Cancel), 
 * and the _param1.._paramN global variables are set to the responses to 
 * text1..textN respectively.
 * <p>
 * The limit on the number of prompts/values is 9.
 * 
 * @param FormCaption
 *                 Title of dialog box.
 * 
 * @param Flags    A combinations of the following flags defined in "slick.sh":
 *                 
 *                 <dl compact>
 *                 <dt>TB_RETRIEVE
 *                   <dd style="margin-left:120pt">Create combo boxes instead of text boxes.
 *                   Fill in combo box list with previous response to combo box.  Be sure
 *                   to specify the retrieve_name argument.
 *                 <dt>TB_RETRIEVE_INIT
 *                   <dd style="margin-left:120pt">Same as TB_RETRIEVE.  In addition, combo box
 *                   text is initialized to the previous responses unless the prompt string
 *                   specifies an initial value.
 *                 <dt>TB_VIEWID_INPUT
 *                   <dd style="margin-left:120pt">prompt1 is a view id and no arguments follow prompt1.
 *                   The input view has Name:[Initial_Value] pairs, one-per-line.
 *                 <dt>TB_VIEWID_OUTPUT
 *                   <dd style="margin-left:120pt">The return value will be a view id containing the responses.
 *                   The output view has the Value of each item, one-per-line. IMPORTANT: The value of the button
 *                   pressed (e.g. OK, Cancel, etc.) is not included in the output view. If you are including custom
 *                   buttons, and you need to know which button was pressed by the user, then do NOT use the
 *                   TB_VIEWID_OUTUT flag -- use _param1.._paramN global variables instead and check the return result
 *                   for which button was pressed (1=first button, 2=second button, etc.).
 *                 <dt>TB_QUERY_COMPAT
 *                   <dd style="margin-left:120pt">The return value will be a view id containing
 *                   the responses in the format of the QUERY.
 *                 </dl>
 *                 Set to 0 for no flags.
 * 
 * @param TextBoxWidth
 *                 Specifies width of the text box in twips. 1440 twips is 1 inch on the display.
 *                 Set to "" for the default text box width.
 * 
 * @param HelpItem Specifies help displayed when F1 is pressed or the help
 *                 button is pressed.  If the help_item starts with a '?'
 *                 character, the characters that follow are displayed in a
 *                 message box.  The help string may also specify a unique
 *                 help index item listed in
 *                 "slickeditindex.xml".
 *                 In addition, you may specify a unique keyword
 *                 for any .chm or .qhc help file by specifying a
 *                 string in the format: <i>HelpIndexItem</i>:<i>help_filename</i>.
 *                 Specify "" for no help.
 * 
 * @param ButtonNCaptionList
 *                 ButtonNCaptionList in the following format:
 *                 
 *                 <blockquote>
 *                 <code>
 *                 <i>ButtonList</i>[\t<i>Caption1</i>[\n<i>Caption2</i>[\n<i>CaptionN</i>]]]
 *                 </code>
 *                 </blockquote>
 *                 
 *                 Where <i>ButtonList</i> is in the format:
 *                 
 *                 <blockquote>
 *                 <code>
 *                 <<i>Caption</i>[:<i>controlName</i>]>[,...]
 *                 </code>
 *                 </blockquote>
 *                 
 *                 Note: <br>
 *                 If you supply a button list, it is up to you to make your own cancel and
 *                 help buttons.  If you have a button with the control name '_cancel', it will
 *                 automatically be set up as the cancel button.  A button with the control name
 *                 '_help' will automatically be set up as the help button.
 *                 <p>
 *                 If the caption starts with "-html ", it will be
 *                 rendered as sunken HTML text.
 *                 <p>
 *                 The same _ok.lbutton_up function will run for all the buttons when they are
 *                 pressed, unless the control name is specified as _help or _cancel.
 *                 <p>
 *                 Specify "" for default OK, Cancel, Help buttons, and no captions.
 *                 Defaults to "".
 * 
 * @param RetrieveName
 *                 Specify the name of the command that called this function or a name for what is being prompted for.
 *                 Defaults to "".
 * 
 * @param prompt1  You may specify 1 or more prompt string arguments.
 *                 <p>
 *                 The prompt string argument are strings in the following format:
 *                 <blockquote>
 *                 <code>
 *                 <i>options</i> <i>label</i>[: <i>initial_value</i>]
 *                 </code>
 *                 </blockquote>
 *                 <i>options</i> may containing one of the following switches
 *                 <dl style="margin-left:20pt">
 *                 <dt>-r  <i>n1</i>,<i>n2</i>
 *                   <dd>Value in text must be a valid floating pointer number in range <i>n1</i>..<i>n2</i>.
 *                 <dt>-e <i>callback_name</i> [:<i>arg2</i>]
 *                   <dd>Name of global function to call to check input.  First argument to call back
 *                   function is the text in the text box.  Second argument is <i>arg2</i> if specified.
 *                 <dt>-e1 <i>callback_name</i>[:<i>arg2</i>]
 *                   <dd>Name of global function to call to check values in ALL text boxes.  First argument
 *                   is "".  Second argument is <i>arg2</i> if specified.  The text boxes have the control
 *                   names (p_name) text1..textN and are numbered from top to bottom.
 *                 <dt>-checkbox
 *                   <dd>Prompt is a check box instead of a text box.
 *                 </dl>
 * 
 *                 <i>label</i> is the caption to appear to the left of the text box.<br>
 *                 <i>initial_value</i> is the initial value to appear in the text box. <br>
 *                 If -checkbox option is used to create a checkbox, then valid initial values are: <br>
 *                 0 (not checked), 1 (checked). Default initial value is 0. This style of checkbox
 *                 corresponds to a PSCH_AUTO2STATE style.<br>
 *                 If -checkbox3 or -checkbox3a option is used, then valid initial values are: <br>
 *                 0 (not checked), 1 (checked), 2 (grayed). Default initial value is 0. This style of checkbox
 *                 corresponds to a PSCH_AUTO3STATEA style where values cycle through: 0, 2, 1.<br>
 *                 If checkbox3b option is used, then valid initial values are: <br>
 *                 0 (not checked), 1 (checked), 2 (grayed). Default initial value is 0. This style of checkbox
 *                 corresponds to a PSCH_AUTO3STATEB style where values cycle through: 0, 1, 2.<br>
 * 
 * @param promptN  Specify 1 or more prompt arguments.  See prompt1.
 * 
 * @example
 * <pre>
 *  _str show("_textbox_form", <i>title</i> ,<i>flags</i>
 *            ,<i>text_box_width</i> , <i>help_item</i> [, <i>ButtonNCaptionList</i> 
 *            [,<i>retrieve_name</i>
 *            [,<i>prompt1</i> [,<i>prompt2</i>, ... <i>promptN</i> ]]]] )
 * 
 * @example
 * <pre>
 *    parse p_margins with left_ma right_ma new_para_ma
 *    new_para_ma=strip(new_para_ma)
 *    result = show("-modal _textbox_form",
 *                  "Margins",     // Form caption
 *                  0,             // Flags
 *                  "",            // Use default textbox width
 *                  'gui_margins', // Help item
 *                  "",            // Buttons and captions
 *                  "gui_margins", // Retrieve name
 *                  "-E1 _check_margins Left Margin:"left_ma,
 *                  "Right Margin:"right_ma,
 *                  "New Paragraph Margin:"new_para_ma);
 *    if (result=="") {
 *       return(COMMAND_CANCELLED_RC);
 *    }
 *    p_margins=_param1' '_param2' '_param3
 * </pre>
 * 
 * @return "" if the dialog box is cancelled. If ButtonNCaptionList!="", then return value is the number
 * of the button that was pressed. Button numbers start at 1.
 * 
 * @categories Forms
 */
void _ok.on_create(_str FormCaption, int Flags, _str TextBoxWidth, _str HelpItem,
                   _str ButtonNCaptionList="", _str RetrieveName="",
                   _str prompt1="", _str promptN="") // prompt1 .. promptN
{
   if( _help.p_user!="" ) {
      return;
   }
   _help.p_user=1;
   CaptionWID := 0;

   num_prompts := 0;
   // Max label width for a text box
   label_width := 0;
   // Max caption width for a check box
   checkbox_width := 0;
   //p_active_form.p_visible = true;

   x := 180;
   y := 180;
   label_and_box_x_pad := 180;
   next_tab_stop := 0;
   num_boxes := 0;
   box_height := 0;
   int widenWIDs[];
   int shiftWIDs[];

   p_active_form.p_caption  = FormCaption;  // Form caption
   _cancel.p_user           = Flags;        // Flags
   typeless tb_width        = TextBoxWidth; // Default text box width
   typeless help            = HelpItem;     // Help item.
   p_active_form.p_name     = RetrieveName; // Retrieve name

   wid := 0;
   typeless retrieve_init   = _cancel.p_user & TB_RETRIEVE_INIT;
   typeless retrieve        = _cancel.p_user & TB_RETRIEVE;
   typeless buffer_input =  (_cancel.p_user & TB_VIEWID_INPUT);
   form_wid := p_active_form;
   int x_border_width = p_active_form.p_width - _dx2lx(form_wid.p_xyscale_mode,form_wid.p_client_width);
   int y_border_width = (p_active_form.p_height - _dy2ly(form_wid.p_xyscale_mode,form_wid.p_client_height));
   FirstBox := 0;
   if (help=='') {
      _help.p_visible=false;
   } else {
      _help.p_help=help;
   }
   FirstCaption := "";
   ControlName := "";
   CurCaption := "";
   CaptionList := "";
   _str ButtonList=ButtonNCaptionList;
   if (ButtonList!='') {
      parse ButtonList with ButtonList "\t" CaptionList;
      if (ButtonList!='') {
         _help.p_visible=_cancel.p_visible=false;
      }
      x=_ok.p_x;
      y=180;
      for (;;) {
         parse CaptionList with CurCaption "\n" CaptionList;
         if (CurCaption=='') break;
         if (pos("-html ", CurCaption)==1) {
            CurCaption = substr(CurCaption, 6);
            wid=_create_window(OI_MINIHTML,
                               form_wid,
                               CurCaption,//Prompt
                               x,y,//X and Y parameters
                               0, 0,//width and height
                               CW_CHILD);
            wid.p_eventtab2=defeventtab _ul2_minihtm;
            wid.p_border_style=BDS_NONE;
            wid._minihtml_UseDialogFont();
            wid.p_backcolor = 0x80000022;
            wid.p_text = CurCaption;
            if (tb_width > 0) {
               wid.p_width = tb_width-wid.p_x*2;
            } else {
               wid.p_width = p_active_form.p_width-wid.p_x*2;
            }
            wid.p_height= _dy2ly(SM_TWIP,_screen_height() intdiv 2) - y;
            wid._minihtml_ShrinkToFit(p_active_form.p_width-wid.p_x*2);
            widenWIDs :+= wid;
            y+=wid.p_height;
            FirstBox=wid.p_y_extent;
            if (!CaptionWID) {
               CaptionWID=wid;
            }
         } else {
            wid=_create_window(OI_LABEL,
                               form_wid,
                               CurCaption,//Prompt
                               x,y,//X and Y parameters
                               0, 0,//width and height
                               CW_CHILD);
            if (wid) {
               widenWIDs :+= wid;
               wid.p_width=wid._text_width(CurCaption);
               wid.p_height=wid._text_height();
               y+=wid.p_height+180;
               FirstBox=wid.p_y_extent+180;
               if (!CaptionWID) {
                  CaptionWID=wid;
               }else{
                  //We want to set CaptionWID to the window id of the widest
                  //caption.
                  if (CaptionWID.p_width > wid.p_width) {
                     CaptionWID=wid;
                  }
               }
            }
         }
      }
   }

   temp_view_id := 0;
   first_arg := 0;
   i := 0;
   view_id := 0;
   current_line := "";
   complete_option := "";
   option := "";
   p1 := p2 := "";
   completion := "";
   tlabel := "";
   init_value := "";
   prompt := "";
   minimum_form_width := 0;
   height := 0;
   ul2_index := 0;
   ul1_index := 0;
   have_init_val := false;

   if( arg(FIRST_DATA_ARG_INDEX) != "" ) {
      first_arg=FIRST_DATA_ARG_INDEX;
      temp_view_id=arg(first_arg);

      if( (TextBoxWidth == "") || (TextBoxWidth == 0) ) {
         tb_width = BOX_DEFAULT_WIDTH;
      }

      if( !buffer_input ) {
         for( i=first_arg; i <= arg() && arg(i)!=''; i++ ) {
            current_line=arg(i);
            complete_option=current_line;
            checkbox := false;
            for( ;; ) {
               option = parse_option( current_line,
                                      p1,
                                      p2);
               if( option=="") {
                  break;
               }

               if( option=='C' ) {
                  completion=p1;
               } else if( option=="CHECKBOX" || option=="CHECKBOX3" || option=="CHECKBOX3A" || option=="CHECKBOX3B") {
                  checkbox=true;
               }
            }

            // Oh, the kludginess!
            // For the case of a minihtml (-html) caption, _text_width() will not retrieve
            // a correct text width to base estimates off, so we create a temporary label
            // control to use for estimating text width.
            orig_wid := p_window_id;
            int temp_label_wid = _create_window(OI_LABEL,form_wid,"xyz",0,0,0,0,CW_CHILD);

            // Labels for text boxes are right-aligned, while check boxes are left-aligned.
            // We cannot count the width of the check box captions when finding the max width
            // of a text box label since that would cause the labels for text boxes to be
            // pushed to the right to accomodate the check box label. Conversely, we cannot
            // count the text box label widths when finding the max width of a check box
            // caption.
            if( checkbox ) {
               // The actual check box part of the control is not counted when
               // estimating a max width for check box captions, so we must add
               // it in ourselves. +255 is a standard height for a check box which
               // we will also use for the width of the check box part of the control
               // since it is (roughly) square.
               // Add a little for padding between the label and the checkbox
               parse current_line with tlabel':'init_value;
               tWidth := temp_label_wid._text_width(tlabel)+255 + 90;
               if( tWidth > checkbox_width ) {
                  checkbox_width=tWidth;
               }
            } else {
               parse current_line with tlabel':'init_value;
               tlabel :+= ':';
               if( temp_label_wid._text_width(tlabel) > label_width ) {
                  label_width=temp_label_wid._text_width(tlabel);
               }
            }

            // Clean up the temporary label control
            temp_label_wid._delete_window();
            p_window_id = orig_wid;
         }
      } else {
         // TODO: get_width_from_buffer() does not support any options.
         label_width = get_width_from_buffer(temp_view_id);
         get_window_id(view_id);
         activate_window(temp_view_id);
         top();
         activate_window(view_id);
      }

      int maybe_width;
      // Do not count labels and text boxes at all if there are none
      if( label_width>0 ) {
         maybe_width=label_and_box_x_pad +
                     max(label_width + AFTER_LABEL_PAD + tb_width,checkbox_width) +
                     label_and_box_x_pad +
                     x_border_width;
      } else {
         // Only check boxes
         maybe_width=label_and_box_x_pad +
                     checkbox_width +
                     label_and_box_x_pad +
                     x_border_width;
      }
      minimum_form_width=_help.p_x_extent+_ok.p_x+x_border_width;
      if( maybe_width < minimum_form_width ) {
         // "Shrinkwrap" the form around the controls
         p_active_form.p_width = minimum_form_width;
         //label_and_box_x_pad = (p_active_form.p_width - (max(label_width + tb_width + AFTER_LABEL_PAD,checkbox_width))) intdiv 2;
      } else {
         p_active_form.p_width = maybe_width;
      }
      height=_text_height();
      form_wid=p_active_form;
      ul2_index=find_index((retrieve)?'_ul2_combobx':'_ul2_textbox',EVENTTAB_TYPE);
      ul1_index=find_index('_textbox_text1',EVENTTAB_TYPE);
      i = first_arg;

      if( buffer_input ) {
         activate_window(temp_view_id);
         get_line(current_line);
         activate_window(view_id);
      }

      for( ;; ) {

         if( !buffer_input ){
            current_line=arg(i);
         }

         completion = "";
         complete_option = current_line;
         have_browse_button := false;
         browse_button_eventtab := 0;
         checkbox := false;
         int checkbox_style = PSCH_AUTO2STATE;
         password := false;
         for( ;; ) {
            option = parse_option(current_line,p1,p2);
            if( option=="" ) {
               break;
            }
            if( strieq(option,'BF') ) {
               browse_button_eventtab=defeventtab _textbox_browse_file.ctlbrowse;
               have_browse_button=true;
               if (completion == "") completion = FILE_ARG;
            } else if( strieq(option,'BFNQ') ) {
               browse_button_eventtab=defeventtab _textbox_browse_file.ctlbrowsenq;
               have_browse_button=true;
               if (completion == "") completion = FILE_ARG;
            } else if( strieq(option,'BD') || strieq(option,'BNDF') ) {
               browse_button_eventtab=defeventtab _textbox_browse_file.ctlbrowsedir;
               have_browse_button=true;
               if (completion == "") completion = DIR_ARG;
            } else if( strieq(option,'CHECKBOX') ) {
               checkbox=true;
               checkbox_style=PSCH_AUTO2STATE;
            } else if( strieq(option,'CHECKBOX3') || strieq(option,'CHECKBOX3A') ) {
               checkbox=true;
               checkbox_style=PSCH_AUTO3STATEA;
            } else if( strieq(option,'CHECKBOX3B') ) {
               checkbox=true;
               checkbox_style=PSCH_AUTO3STATEB;
            } else if( strieq(option,'PASSWORD') ) {
               password = true;
            }
            if( option=='C' ) {
               completion=p1;
            }
         }
         parse current_line with prompt':'init_value;
         have_init_val=(init_value != '');
         if( !checkbox && lastpos(':', prompt) == 0 ) {
            prompt :+= ':';
         }

         // Text/combo box label, check box
         old_wid := p_window_id;
         if( checkbox ) {
            // +255 is a standard height for a check box
            box_height = 255;
            wid = _create_window(OI_CHECK_BOX,
                                 form_wid, // Parent
                                 "",       // Title
                                 label_and_box_x_pad,FirstBox+(num_boxes * (box_height+180)) + 180, // x,y
                                 checkbox_width,box_height,
                                 CW_CHILD|CW_LEFT_JUSTIFY);
            wid.p_caption=prompt;
            wid.p_alignment=AL_LEFT;
            orig_width:=wid.p_width;
            wid.p_auto_size=true;  // Good idea to auto height just in case
            wid.p_auto_size=false;
            wid.p_width=orig_width;
            wid.p_visible=true;
            // We keep track of the number of input fields (check/text/combo boxes) by depending
            // on the fact that a label is paired with an input field. Since a check box does not
            // have a corresponding label, we must artifically add 1 to the tab index so that
            // the ok.lbutton_up() code can correctly figure out which wid belongs to the checkbox.
            next_tab_stop += 2;
            wid.p_tab_index=next_tab_stop;
            wid.p_tab_stop=true;
            wid.p_name='check'(num_boxes+1);
            wid.p_style=checkbox_style;
            wid.p_value=0;
            if( have_init_val ) {
               switch( init_value ) {
               case '0':
                  wid.p_value=0;
                  break;
               case '1':
                  wid.p_value=1;
                  break;
               case '2':
                  if( checkbox_style==PSCH_AUTO3STATEA || checkbox_style==PSCH_AUTO3STATEB ) {
                     wid.p_value=2;
                  }
                  break;
               }
            }

         } else {
            if( retrieve ) {
               // Combo box label
               box_height=285;
               wid = _create_window(OI_LABEL,
                                    form_wid, // Parent
                                    "",       // Title
                                    label_and_box_x_pad,FirstBox+(num_boxes * (box_height+180)) + 180, // x,y
                                    label_width,box_height,
                                    CW_CHILD);
            } else {
               // Text box label
               box_height=255;
               wid = _create_window(OI_LABEL,
                                    form_wid, // Parent
                                    "",       // Title
                                    label_and_box_x_pad,FirstBox+(num_boxes * (box_height+180)) + 180, // x,y
                                    label_width,box_height,
                                    CW_CHILD);
            }

            wid.p_caption=prompt;
            wid.p_alignment=AL_RIGHT;
            orig_width:=wid.p_width;
            wid.p_auto_size=true;  // Must auto height so we can center text/combo box and label
            wid.p_auto_size=false;
            wid.p_width=orig_width;
            wid.p_visible=true;
            wid.p_tab_index= ++next_tab_stop;
            wid.p_tab_stop=false;
            //wid.p_auto_size=true;
         }
         p_window_id = old_wid;

         // Text/combo box
         if( !checkbox ) {
            old_wid=p_window_id;
            // The label that was just created for this combo/text box
            int label_wid = wid;
            if( retrieve ) {
               // Combo box
               box_height=285;
               wid=_create_window(OI_COMBO_BOX,
                                  form_wid, // Parent
                                  "",       // Title
                                  label_wid.p_x_extent + AFTER_LABEL_PAD, // x
                                  FirstBox+(num_boxes * (box_height+180)) + 180,              // y
                                  tb_width,box_height,
                                  CW_CHILD);
               widenWIDs :+= wid;
            } else {
               // Text box
               box_height=255;
               wid=_create_window(OI_TEXT_BOX,
                                  form_wid, // Parent
                                  "",       // Title
                                  label_wid.p_x_extent + AFTER_LABEL_PAD, // x
                                  FirstBox+(num_boxes * (box_height+180)) + 180,              // y
                                  tb_width,box_height,
                                  CW_CHILD);
               wid.p_Password = password;
               widenWIDs :+= wid;
            }
            wid.p_completion=completion;
            wid.p_validate_info = complete_option;
            if(retrieve_init && have_init_val){
               wid.p_text = init_value;
               wid._set_sel(length(init_value)+1);
            } else if(!retrieve_init){
               wid.p_text = init_value;
               wid._set_sel(length(init_value)+1);
            } else {
               wid.p_text = '';
            }
            wid.p_tab_index = ++next_tab_stop;
            wid.p_tab_stop = true;

            orig_width:=wid.p_width;
            wid.p_auto_size=true;  // Good idea to auto height just in case
            wid.p_auto_size=false;
            wid.p_width=orig_width;
            wid.p_name='text'(num_boxes+1);
            wid.p_eventtab2=ul2_index;
            wid.p_eventtab=ul1_index;
            temp_label_wid:=wid.p_prev;
            if (temp_label_wid.p_object==OI_LABEL) {
               // Center the label text to the text box or combo box.
               diff_y:=(wid.p_height-temp_label_wid.p_height) intdiv 2;
               if (diff_y>=0) {
                  temp_label_wid.p_y+=diff_y;
               }
            }

            if (have_browse_button) {
               // Note: Use the last box_height to estimate a vertical y-position
               // for the Browse button. It will be perfect if all the same controls
               // are used (e.g. all textboxes, all comboboxes), but slightly off
               // if a combination of controls are used.
               browse_button_height := 345;
               int wid2=_create_window(OI_COMMAND_BUTTON, form_wid, '',
                                   wid.p_x,
                                   FirstBox + (num_boxes * (box_height+180)) + 180,//X and Y parameters
                                   200, browse_button_height,//width and height
                                   CW_CHILD);
               if (wid2) {
                  shiftWIDs :+= wid2;
                  wid2.p_caption='...';
                  wid2.p_width=wid2._text_width(wid2.p_caption)+200;
                  wid.p_width-=wid2.p_width;
                  wid2.p_x=wid.p_x_extent + AFTER_LABEL_PAD;
                  wid2.p_tab_index = ++next_tab_stop;
                  wid2.p_tab_stop = true;
                  wid2.p_height=wid.p_height - _twips_per_pixel_y();
                  wid2.p_eventtab=browse_button_eventtab;
               }
            }
            label_wid.p_y=wid.p_y;
            label_wid.p_y += (wid.p_height - height) intdiv 2;
            p_window_id = old_wid;
         }

         _ok.p_user = _ok.p_user' 'i - first_arg + 1'='wid;
         ++i;
         ++num_boxes;
         if( buffer_input ) {
            activate_window(temp_view_id);
            if( down() ){
              activate_window(view_id);
              break;
            }
            get_line(current_line);
            activate_window(view_id);
         } else {
            if( i>arg() || arg(i)=="" ) {
               break;
            }
         }
      } // BIG FOR LOOP

      _ok.p_tab_index = wid.p_tab_index+1;
      _cancel.p_tab_index = _ok.p_tab_index+1;
      _help.p_tab_index = _cancel.p_tab_index+1;
      _ok.p_y = FirstBox + (num_boxes * (box_height+180)) + 180;
      _help.p_y = _ok.p_y;
      _cancel.p_y = _ok.p_y;

   } else {

      _ok.p_tab_index = 1;
      _cancel.p_tab_index = _ok.p_tab_index+1;
      _help.p_tab_index = _cancel.p_tab_index+1;
      _ok.p_y = FirstBox + (num_boxes * (box_height+180)) + 180;
      _help.p_y = _ok.p_y;
      _cancel.p_y = _ok.p_y;
   }

   if( ButtonList!="" ) {
      parse ButtonList with ButtonList "\t" CaptionList;
      if (ButtonList!='') {
         parse ButtonList with FirstCaption ',' ButtonList;
         _ok.p_caption=FirstCaption;

         SpaceBetweenButtons := 180;//_cancel.p_x-(_ok.p_x_extent);
         _ok.p_width=max(1125,_ok._text_width(_ok.p_caption)+200);

         int LastWID;
         if (_help.p_visible) {
            LastWID=_help;
         }else if (_cancel.p_visible) {
            LastWID=_cancel;
         }else if (_ok.p_visible) {
            LastWID=_ok;
         }
         int LastTab=LastWID.p_tab_index;
         int NextX=LastWID.p_x_extent+SpaceBetweenButtons;
         newwid := 0;
         ButtonCount := 1;
         for (;;) {
            parse ButtonList with CurCaption ',' ButtonList;
            if (CurCaption=='') break;
            ++ButtonCount;
            parse CurCaption with CurCaption ':' ControlName;
            newwid=_create_window(OI_COMMAND_BUTTON,p_active_form,CurCaption,
                                  NextX,_ok.p_y,/*_ok.p_width*/max(1125,_ok._text_width(CurCaption)+200),_ok.p_height,CW_CHILD);
            if (newwid) {
               //newwid.p_width=max(_ok.p_width,newwid._text_width(CurCaption)+200);
               NextX=newwid.p_x_extent+SpaceBetweenButtons;
               newwid.p_tab_index=++LastTab;
               newwid.p_user=ButtonCount;
               newwid.p_name='__'ControlName;
               //I put on the underscores so that the control name cannot conflict w/
               //existing controls
               if (newwid.p_name=='___cancel') {
                  newwid.p_cancel=true;
               }else if (newwid.p_name=='___help') {
                  newwid.p_help=help;
               }else{
                  newwid.p_eventtab=defeventtab _textbox_form._ok;
               }
            }
            if (newwid.p_x_extent > p_active_form.p_width) {
               p_active_form.p_width=newwid.p_x_extent+_ok.p_x/*SpaceBetweenButtons*/;
            }
            if (TextBoxWidth=='') {
               //Caller does not care about text box width
               typeless list=_ok.p_user;
               for (i=1;;++i) {
                  wid=eq_name2value(i,list);
                  if (wid == 0 || wid == '') break;
                  // The check boxes are already as wide as they need to be.
                  // If we sized them to stop at the end of the last button,
                  // then we could end up with clipped captions.
                  if( wid.p_object != OI_CHECK_BOX ) {
                     browse_button_width := 0;
                     if (wid.p_next.p_object==OI_COMMAND_BUTTON && wid.p_next.p_caption=='...') {
                        browse_button_width=wid.p_next.p_width;
                     }
                     wid.p_width=max(BOX_DEFAULT_WIDTH-browse_button_width ,(newwid.p_x_extent)-wid.p_x);
                  }
               }
            }
         }
      }
   }

   p_active_form.p_height = _ok.p_y_extent + y_border_width +180;
   if (buffer_input) {
      get_window_id(view_id);
      activate_window(temp_view_id);
      _delete_buffer();
      _delete_window();
      activate_window(view_id);
   }
   if( (_cancel.p_user & TB_RETRIEVE_INIT) &&
       (_cancel.p_user & TB_RETRIEVE_INIT)!=TB_RETRIEVE ) {

      _retrieve_prev_form();
   }
   if( CaptionWID ) {
      int clientwidth=_dx2lx(CaptionWID.p_xyscale_mode,form_wid.p_client_width);
      if( CaptionWID.p_x_extent>clientwidth ) {
         delta_x := (CaptionWID.p_x+CaptionWID.p_x_extent+CaptionWID._text_width(' '))-clientwidth;
         p_active_form.p_width += delta_x;
         if (delta_x > 0) {
            foreach (wid in widenWIDs) {
               if (wid!=CaptionWID) {
                  wid.p_width += delta_x;
               }
            }
            foreach (wid in shiftWIDs) {
               wid.p_x += delta_x;
            }
         }
      }
   }
}

_ok.lbutton_up()
{

   typeless list = _ok.p_user;
   i := 1;

   //Check to be sure that information is valid before closing window
   typeless status=0;
   typeless result=0;
   v_info := "";
   complete_option := "";
   option := "";
   typeless p1="", p2="";
   wid := 0;
   len := 0;

   done:=false;
   for (;;) {
      wid = eq_name2value(i, list);

      if (wid == 0 || wid == '') {
         break;
      }

      if( wid.p_object!=OI_CHECK_BOX ) {
         v_info = wid.p_validate_info;
         complete_option=v_info;
         for (;;) {
            option = parse_option(v_info,
                                  p1,
                                  p2);
            if (option=='' || option!='C') {
               break;
            }
         }

         switch (option) {
         case 'R' :
            status=eval_exp(result,wid.p_text,10);
            if (status) {
               _message_box('Invalid Slick-C'VSREGISTEREDTM' expression');
            }
            if(status || !in_range(p1, p2, result)){
               p_window_id = wid;
               if(length(p_text) == 0) {
                  len =2;
               } else {
                  len = length(p_text);
               }
               _set_sel(1, len+1);_set_focus();
               return('');
            }
            break;
         case 'I' :
            status=eval_exp(result,wid.p_text,10);
            if (status) {
               _message_box('Invalid Slick-C'VSREGISTEREDTM' expression');
            }
            if(status || !in_irange(p1, p2, result)){
               p_window_id = wid;
               if(length(p_text) == 0) {
                  len =2;
               } else {
                  len = length(p_text);
               }
               _set_sel(1, len+1);_set_focus();
               return('');
            }
            break;
         case 'E' :
         case 'E1':
            index := find_index(p1, PROC_TYPE|COMMAND_TYPE);
            if (_isfunptr(p1)) {
               status=(*p1)(wid.p_text, p2);
            }else{
               if(index == 0){
                  _message_box('Could Not Find Procedure 'p1);
                  return('');
               }
               status = call_index(wid.p_text, p2, index);
            }
            if (status) {
               if (option!='E1') {
                  p_window_id = wid;
               }
               if(length(p_text) == 0) {
                  len =2;
               } else {
                  len = length(p_text);
               }
               _set_sel(1, len+1);_set_focus();
               return('');
            }
            if (option=='E1') {
               done=true;
            }
            break;
         case 'BD':
            dir_name := _maybe_unquote_filename(wid.p_text);
            if (!file_exists(dir_name)) {
               _message_box("Directory not found: "dir_name);
               if (length(wid.p_text) == 0) {
                  len =2;
               } else {
                  len = length(wid.p_text);
               }
               wid._set_sel(1, len+1);
               wid._set_focus();
               return('');
            }
            is_dir := isdirectory(dir_name);
            if( is_dir=="" || is_dir=="0" ) {
               _message_box("Not a Directory: "dir_name);
               if (length(wid.p_text) == 0) {
                  len =2;
               } else {
                  len = length(wid.p_text);
               }
               wid._set_sel(1, len+1);
               wid._set_focus();
               return('');
            }
            break;
         case 'BF':
         case 'BFNQ':
            file_name := _maybe_unquote_filename(wid.p_text);
            if (!file_exists(file_name)) {
               _message_box("File not found: "file_name);
               if(length(wid.p_text) == 0) {
                  len =2;
               } else {
                  len = length(wid.p_text);
               }
               wid._set_sel(1, len+1);wid._set_focus();
               return('');
            }
            break;
         }
      }
      if( done ) {
         break;
      }
      ++i;
   }
   if (_cancel.p_user & TB_RETRIEVE){
      _save_form_response();
   }

   int num_boxes = (_ok.p_tab_index - 1) intdiv 2;
   typeless flags=_cancel.p_user;
   view_id := 0;
   temp_view_id := 0;

   if(flags & TB_VIEWID_OUTPUT){
      view_id = _create_temp_view(temp_view_id);
      if (view_id == '') {
         return(NOT_ENOUGH_MEMORY_RC);
      }
      if(flags & TB_QUERY_COMPAT){
         for (i = 1; i <= num_boxes; ++i) {
            insert_line('');
         }
      }
      for (i = 1; i <= num_boxes; ++i) {
         wid = eq_name2value(i, list);
         if( wid.p_object==OI_CHECK_BOX ) {
            result=wid.p_value;
         } else {

            v_info = wid.p_validate_info;

            complete_option=v_info;
            option = parse_option(v_info,
                                  p1,
                                  p2);
            result=wid.p_text;
            switch (option) {
            case 'I' :
            case 'R' :
               eval_exp(result,wid.p_text,10);
               break;
            }
         }
         insert_line(result);
      }
      activate_window(view_id);
      p_active_form._delete_window(temp_view_id);
      return(temp_view_id);
   }
   for( i=1; i <= num_boxes; ++i ) {
      wid = eq_name2value(i, list);
      if( wid.p_object==OI_CHECK_BOX ) {
         result=wid.p_value;
      } else {
         v_info = wid.p_validate_info;
         complete_option=v_info;
         option = parse_option(v_info,
                               p1,
                               p2);
         result=wid.p_text;
         switch (option) {
         case 'R':
         case 'I':
            eval_exp(result,wid.p_text,10);
            break;
         }
      }
      switch (i) {
      case 1:
         _param1=result;
         break;
      case 2:
         _param2=result;
         break;
      case 3:
         _param3=result;
         break;
      case 4:
         _param4=result;
         break;
      case 5:
         _param5=result;
         break;
      case 6:
         _param6=result;
         break;
      case 7:
         _param7=result;
         break;
      case 8:
         _param8=result;
         break;
      case 9:
         _param9=result;
         break;
      case 10:
         _param10=result;
         break;
      case 11:
         _param11=result;
         break;
      }
   }
   int rv;
   if (p_window_id==_ok) {
      rv=1;
   }else{
      rv=p_user;
   }
   p_active_form._delete_window(rv);
}

defeventtab _editorctl_form;
/*
  arg(2)  return format  Only I option supported.

    I= ini line, L= lines, F=file arg(3) has filename B= buffer arg(3) has buffer name

*/
_ok.on_create(_str caption="",
              typeless flags="",
              _str input="",
              typeless reserved="",
              _str help="",
              int max_Noflines=0,
              int max_filesize=0,
              _str font="",
              _str margins="")
{
   p_active_form.p_caption=caption;

   if (flags=='') {
      flags=EDC_OUTPUTINI|EDC_INPUTINI;
   }
   if (flags & EDC_INPUTINI) {
      input=_ini_xlat_multiline(input);
   }
   if (help=='') {
      _help.p_visible=false;
   } else {
      _help.p_help=help;
   }
   line := "";
   _ok.p_user=flags' 'max_Noflines'. 'max_filesize;
   p_window_id=_control list1;
   _delete_line();
   input=input;
   for (;;) {
      if (input=='') break;
      line=_parse_line(input);
      insert_line(line);
   }
   if (!p_Noflines) {
      insert_line('');
   }
   name := "";
   typeless size=0;
   top();
   p_word_wrap_style &= (~WORD_WRAP_WWS);
   if (font!='') {
      parse font with name','size','flags;
      if (name!='') list1.p_font_name=name;
      if (size!='') list1.p_font_size=size;
      if (flags!='')  list1._font_flags2props(flags);
   }
   if (margins!='') {
      p_word_wrap_style|=WORD_WRAP_WWS;
      list1.p_margins=margins;
      typeless lm, rm;
      parse margins with lm rm . ;
      int text_width=_text_width(substr('x',1,rm));
      int client_width=_dx2lx(SM_TWIP,list1.p_client_width);
      int old_width=list1.p_width;
      // This code needs to account for the width of the scroll bars.
      // Need _get_system_metrics function
      list1.p_width=old_width+text_width-client_width+500+(old_width-client_width);
      p_active_form.p_width+=list1.p_width-old_width;
   }
}
void _ok.lbutton_up()
{
   typeless flags=0;
   typeless max_Noflines=0;
   typeless max_filesize=0;
   parse _ok.p_user with flags max_Noflines'.' max_filesize ;
   if (isinteger(max_Noflines) && list1.p_Noflines>max_Noflines) {
      _message_box(nls("Too many lines in list. Only %s lines are allowed",max_Noflines));
      return;
   }
   int size=list1.p_buf_size;
   text := "";
   typeless p=0;
   if (flags & EDC_OUTPUTINI) {
      list1.save_pos(p);
      list1.top();
      text=list1.get_text(list1.p_buf_size);
      text=stranslate(text,'\\','\');
      text=stranslate(text,'\n',list1.p_newline);
      size=length(text);
      list1.restore_pos(p);
   } else if(flags & EDC_OUTPUTSTRING){
      list1.save_pos(p);
      list1.top();
      text=list1.get_text(list1.p_buf_size);
      size=length(text);
      list1.restore_pos(p);
   }
   if (isinteger(max_filesize) && size>max_filesize) {
      _message_box(nls("Text too large. Only %s bytes are allowed",max_filesize));
      return;
   }
   _param1=text;
   p_active_form._delete_window(0);
}
_str _ini_xlat_multiline(_str line)
{
   ch := "";
   int i=1, j=0;
   result := "";
   for (;;) {
      j=pos('\',line,i);
      if (!j) {
         result :+= substr(line,i);
         return(result);
      }
      result :+= substr(line,i,j-i);
      ch=substr(line,j+1,1);
      switch (ch) {
      case 'n':
         result :+= _chr(13);
         break;
      default:
         result :+= ch;
      }
      i=j+2;
   }
}

defeventtab _rb_form;

/**
 * Have to use this because there is no metric to measure the distance from the 
 * left side of a radio button to the left side of the text.
 */
static const RB_EXTRA_WIDTH= 500;
/*
   FormCaption is the caption for the dialog

   Flags
         RBFORM_CHECKBOXES

   HelpItem is the p_help property for ctlhelp button.  If this is left blank,
   the button is hidden

   Specify captions 1 per argument after HelpItem

   Dialog sizes itself

   Returns:
      '' if cancelled,
      1 for first button on,
      2 for second button on, etc

      if RBFORM_CHECKBOXES is set, it is a set of flags 0x1 is or'd in if the
      first cb is on, 0x2 is or'd in if the second cb is on etc.
*/
void ctlok.on_create(_str FormCaption,_str Captions[],int Flags=0,int DefaultRB=1,_str HelpItem='',_str RetrieveName='',_str CheckBoxCaption="")
{
   if (RetrieveName!='') {
      p_active_form.p_name=RetrieveName;
   }
   p_active_form.p_caption=FormCaption;
   if (HelpItem!='') {
      ctlhelp.p_help=HelpItem;
   }else{
      ctlhelp.p_visible=false;
   }
   i := 0;
   FirstCaptionIndex := 4;
   int x=ctlok.p_x;
   y := 100;
   FirstRB := 0;
   Widest := 0;
   TabIndex := 1;
   wid := 0;
   int type=OI_RADIO_BUTTON;
   if (Flags&RBFORM_CHECKBOXES) {
      type=OI_CHECK_BOX;
   }
   ctlok.p_user=Flags;
   //for (i=FirstCaptionIndex;i<=arg();++i) {
   for (i=0;i<Captions._length();++i) {
      _str CurCaption=Captions[i];
      ch := "";
      if (substr(CurCaption,1,1)==_chr(1)) {
         ch=_chr(1);
         CurCaption=substr(CurCaption,2);
      }
      wid=_create_window(type,p_active_form,CurCaption,x,y,0,0,CW_CHILD);
      if (!FirstRB) FirstRB=wid;
      if (wid) {
         wid.p_name='ctl'type:+i;
         wid.p_width=_text_width(CurCaption)+RB_EXTRA_WIDTH;//Leave something for width of button
         if (wid.p_width>Widest) {
            Widest=wid.p_width;
         }
         wid.p_height=wid._text_height();
         if (_isUnix()) {
            // Adjust width and height so that controls on UNIX don't
            // get clipped.
            wid.p_height += 120;
            wid.p_width += 300;
         }
         y+=wid.p_height+100;
         wid.p_tab_index=TabIndex;
         if (ch!='') {
            wid.p_enabled=false;
         }
         if (wid.p_enabled && wid.p_tab_index==DefaultRB && !(Flags&RBFORM_CHECKBOXES)) {
            if (RetrieveName=='') wid.p_value=1;
         }
         ++TabIndex;
         if (type==OI_CHECK_BOX && (DefaultRB & (TwoToPower(i))) ) {
            if (RetrieveName=='') wid.p_value=1;
         }
      }
   }
   int diff_x=p_active_form.p_width-_dx2lx(SM_TWIP,p_active_form.p_client_width);
   int diff_y=p_active_form.p_height-_dy2ly(SM_TWIP,p_active_form.p_client_height);
   ctlok.p_tab_index=TabIndex;
   ctlok.p_next.p_tab_index=TabIndex+1;
   ctlhelp.p_tab_index=TabIndex+2;
   if (Widest>p_active_form.p_width) {
      p_active_form.p_width=Widest+x+diff_x+RB_EXTRA_WIDTH;
   }
   if (wid) {
      ctlok.p_y=ctlok.p_next.p_y=ctlhelp.p_y=wid.p_y_extent+200;
      _ctl_dont_prompt.p_y = ctlok.p_y_extent+90;
   }

   cb_height := 0;
   if (CheckBoxCaption != "") {
      if (isinteger(CheckBoxCaption)) {
         CheckBoxCaption = get_message((int)CheckBoxCaption);
      }
      _ctl_dont_prompt.p_caption = CheckBoxCaption;
      cb_height = _ctl_dont_prompt.p_height + 120;
   } else {
      _ctl_dont_prompt.p_visible = false;
      _ctl_dont_prompt.p_enabled = false;
   }

   p_active_form.p_height=ctlok.p_y_extent+diff_y+cb_height+100;
   if (RetrieveName!='') {
      _retrieve_prev_form();
   }
}

static int TwoToPower(int Power)
{
   result := 0;
   if (!Power) {
      return(1);
   }else if (Power==1) {
      return(2);
   }else{
      i := 0;
      result=2;
      for (i=1;i<Power;++i) {
         result*=2;
      }
   }
   return(result);
}

int ctlok.lbutton_up()
{
   typeless Flags=ctlok.p_user;
   int wid=p_active_form.p_child;
   int origwid=wid;
   rv := 0;
   cur := 0;
   if (Flags&RBFORM_CHECKBOXES) {
      for (cur=0;;) {
         if (wid.p_object==OI_CHECK_BOX) {
            if (wid.p_value) {
               rv|=(pow(2,cur));
            }
            ++cur;
         }
         wid=wid.p_next;
         if (wid==origwid) break;
      }
   }else{
      for (;;) {
         if (wid.p_object==OI_RADIO_BUTTON && wid.p_value) {
            break;
         }
         wid=wid.p_next;
         if (wid==origwid) break;
      }
      rv=wid.p_tab_index;
   }

   _param1 = 0;
   if (_ctl_dont_prompt.p_visible && _ctl_dont_prompt.p_enabled) {
      _param1 = _ctl_dont_prompt.p_value;
   }

   _save_form_response();
   p_active_form._delete_window(rv);
   return(rv);
}

/**
 * Display a generic dialog box with a list of radio buttons where the user 
 * is allowed to select one of the options.
 * 
 * @param DialogCaption    Dialog caption
 * @param Captions         Array of captions to select from
 * @param InitialOn        Index of caption to use as default (1 is first)
 * @param RetrieveName     Dialog input retrieval key
 * @param CheckBoxCaption  Caption for optional checkbox.  Useful for adding 
 *                         a checkbox to the dialog to indicate that you
 *                         do not want to be prompted again for this. 
 * 
 * @return Returns the index of the item selected (1 is first).
 *         Returns &lt;= 0 if the user cancels (COMMAND_CANCELLED_RC).
 *         The value of the check box is returned in '_param1'.
 *  
 * @categories Forms
 */
int RadioButtons(_str DialogCaption,_str Captions[],int InitialOn=1,_str RetrieveName='',_str CheckBoxCaption="")
{
   typeless result=show('-modal _rb_form',DialogCaption,Captions,0,InitialOn,'',RetrieveName,CheckBoxCaption);
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }
   return(result);
}

/**
 * Display a generic dialog box with a list of check boxes where the user 
 * is allowed to select one or more of the options.
 * 
 * @param DialogCaption    Dialog caption
 * @param Captions         Array of captions to select from
 * @param InitialOn        Index of caption to use as default (1 is first)
 * @param RetrieveName     Dialog input retrieval key
 * @param CheckBoxCaption  Caption for optional checkbox.  Useful for adding 
 *                         a checkbox to the dialog to indicate that you
 *                         do not want to be prompted again for this. 
 * 
 * @return Returns a bitset of the indexes of the items selected.
 *         Returns &lt;= 0 if the user cancels (COMMAND_CANCELLED_RC).
 *         The value of the optional check box is returned in '_param1'.
 *  
 * @categories Forms
 */
int CheckBoxes(_str DialogCaption,_str Captions[],int BoxOnFlags=0,_str RetrieveName='',_str CheckBoxCaption="")
{
   typeless result=show('-modal _rb_form',DialogCaption,Captions,RBFORM_CHECKBOXES,BoxOnFlags,'',RetrieveName,CheckBoxCaption);
   if (result=='') {
      return(0);
   }
   return(result);
}

enum_flags ComboBoxFormFlags {
   COMBOFORM_ALLOW_EDIT,
};

defeventtab _combobox_form;

static _str COMBOBOX_FORM_RETRIEVE_NAME(...) {
   if (arg()) _ctl_ok.p_user=arg(1);
   return _ctl_ok.p_user;
}

/**
 * Displays a generic form with a single combo box control.
 * 
 * @param formTitle        title text for form
 * @param label            any text or prompt for the combo box 
 * @param items            array of items in the combo box 
 * @param flags            a combo of the following flags 
 *                 <dl compact>
 *                 <dt>COMBOFORM_ALLOW_EDIT
 *                   <dd style="margin-left:120pt">Allow the
 *                   user to edit the textbox portion of the
 *                   combo box.  The default is to allow no
 *                   editing.
 *                 </dl>
 * 
 * @param defaultItem      default item to be initially 
 *                         selected, must be included in the
 *                         items array
 * @param help             help item for form 
 * @param retrieveName     for saving/retrieving the last combo 
 *                         value picked
 * 
 * @return int             IDOK if user picked a value, 
 *                         IDCANCEL if form was cancelled
 *  
 * @categories Forms
 */
int comboBoxDialog(_str formTitle, _str label, _str (&items)[], int flags = 0, _str defaultItem = '', _str help = '', _str retrieveName = '')
{
   return show('-modal _combobox_form', formTitle, label, items, flags, defaultItem, help, retrieveName);
}

_ctl_ok.on_create(_str formTitle, _str label, _str (&items)[], int flags = 0, _str defaultItem = '', _str help = '', _str retrieveName = '')
{
   p_active_form.p_caption = formTitle;

   // workaround because auto-size does not work consistently
   _ctl_label.p_auto_size = false;
   _ctl_label.p_width = _ctl_combo.p_width;
   num_lines := _ctl_label._text_width(label) intdiv _ctl_combo.p_width;
   _ctl_label.p_height = (num_lines+1) * _ctl_label._text_height();
   _ctl_label.p_caption = label;

   // do we need a help button?
   if (help != '') {
      _ctl_help.p_help = help;
   } else {
      _ctl_help.p_visible = false;

      // move the other buttons over
      _ctl_ok.p_x  = _ctl_cancel.p_x;
      _ctl_cancel.p_x = _ctl_help.p_x;
   }

   // fill in the combo box
   for (i := 0; i < items._length(); i++) {
      _ctl_combo._lbadd_item(items[i]);
   }

   // select the default item if there is one
   COMBOBOX_FORM_RETRIEVE_NAME('');
   if (defaultItem != '') {
      _ctl_combo._lbfind_and_select_item(defaultItem, '', true);
   } else if (retrieveName != '') {
      COMBOBOX_FORM_RETRIEVE_NAME('_combobox_form.'retrieveName);
      _ctl_combo.p_text = _ctl_combo._retrieve_value(COMBOBOX_FORM_RETRIEVE_NAME());
   } 

   if (flags & COMBOFORM_ALLOW_EDIT) {
      _ctl_combo.p_style = PSCBO_EDIT;
   } 

   // move stuff up based on the label's size - it autosized after we set the text
   heightDiff := _ctl_combo.p_y - (2 * _ctl_label.p_y + _ctl_label.p_height);
   _ctl_combo.p_y -= heightDiff;
   _ctl_ok.p_y -= heightDiff;
   _ctl_cancel.p_y = _ctl_help.p_y = _ctl_ok.p_y;
   p_active_form.p_height -= heightDiff;
}

_ctl_ok.lbutton_up()
{
   // return the current value
   _param1 = _ctl_combo.p_text;

   if (COMBOBOX_FORM_RETRIEVE_NAME() != '') {
      _ctl_combo._append_retrieve(_ctl_combo, _ctl_combo.p_text, COMBOBOX_FORM_RETRIEVE_NAME());
   }

   p_active_form._delete_window(IDOK);
}

defeventtab _checkbox_form;

static _str RETRIEVE_NAME(...) {
   if (arg()) _checkbox.p_user=arg(1);
   return _checkbox.p_user;
}

/**
 * Displays a generic form with a label and a single checkbox 
 * control.  This can be useful for asking a question that has a 
 * related setting that can be set with a checkbox (for example, 
 * a "Never prompt again" checkbox). 
 * 
 * @param formTitle        title text for form
 * @param label            any text for a label message 
 * @param checkBoxLabel    label for the checkbox 
 * @param buttons          MB_OK, MB_OKCANCEL, MB_YESNO, 
 *                         MB_YESNOCANCEL
 * @param defaultValue     default checkbox value (0 or 1) 
 * @param retrieveName     a retrieve name to be used to 
 *                         remember the last checkbox value.  If
 *                         a retrieved value is found, it
 *                         overrides the defaultValue
 * @param help             help item for form
 * 
 * @return int             IDOK, IDCANCEL, IDYES, IDNO
 *  
 * @categories Forms
 */
int checkBoxDialog(_str formTitle, _str label, _str checkBoxLabel, int buttons, int defaultValue, _str retrieveName = '', _str help = '')
{
   return show('-modal _checkbox_form', formTitle, label, checkBoxLabel, buttons, defaultValue, retrieveName, help);
}


_message.on_create(_str formTitle, _str label, _str checkBoxLabel, int buttons, int defaultValue, _str retrieveName = '', _str help = '')
{
   // set up the new labels
   p_active_form.p_caption = formTitle;
   _checkbox.p_caption = checkBoxLabel;

   _message.p_caption = label;

   textWidth := _message._text_width(label);
   maxLabelWidth := p_active_form.p_width - (2 * _message.p_x);
   if (textWidth > maxLabelWidth || pos("\n",label)) {
      
      a := split2array(label, "\n");
      lineHeight := _message.p_height;
      lines := (textWidth intdiv maxLabelWidth) + a._length();
      _message.p_height = lineHeight * lines;

      // since we've embiggened the message, we need to move stuff down
      diff := _message.p_height - lineHeight;
      p_active_form.p_height += diff;
      _checkbox.p_y += diff;
   }

   // figure out which buttons we need
   // hide the ones we don't
   // put the result for that button in the p_user
   _cancel.p_user = IDCANCEL;
   switch (buttons) {
   case MB_OK:
      _cancel.p_visible = _no.p_visible = false;
      _yes.p_caption = 'OK';
      _yes.p_x = _cancel.p_x;
      _yes.p_user = IDOK;
      break;
   case MB_OKCANCEL:
      _no.p_visible = false;
      _yes.p_caption = 'OK';
      _yes.p_x = _no.p_x;
      _yes.p_user = IDOK;
      break;
   case MB_YESNO:
      _cancel.p_visible = false;
      _yes.p_x = _no.p_x;
      _no.p_x = _cancel.p_x;
      _yes.p_user = IDYES;
      _no.p_user = IDNO;
      break;
   case MB_YESNOCANCEL:
      _yes.p_user = IDYES;
      _no.p_user = IDNO;
      break;
   }


   // set the checkbox caption, hide if blank
   RETRIEVE_NAME('');
   _checkbox.p_caption = checkBoxLabel;
   if (_checkbox.p_caption == "") {
      // hide the checkbox...shouldn't you be using _message_box?
      _checkbox.p_visible = false;
   } else {
      // maybe retrieve the old value - it overrules the default
      if (retrieveName != '') {
         RETRIEVE_NAME('_checkbox_form.'retrieveName);
         retrievedValue := _retrieve_value(RETRIEVE_NAME());
         if (retrievedValue != '') {
            defaultValue = (int)retrievedValue;
         }
      }

      // set the value, finally
      _checkbox.p_value = defaultValue;
   }
}

void _checkbox_form.on_resize()
{
   // keep the buttons in the corner
   padding := _message.p_x;

   xDiff := p_width - (_cancel.p_x_extent + padding);
   _cancel.p_x += xDiff;
   _no.p_x += xDiff;
   _yes.p_x += xDiff;

   yDiff := p_height - (_cancel.p_y_extent + padding);
   _cancel.p_y += yDiff;
   _no.p_y = _yes.p_y = _cancel.p_y;
}

// this is the event handler for both yes and no buttons
_yes.lbutton_up()
{
   if (_checkbox.p_visible) {
      // save the checkbox value in _param1
      _param1 = _checkbox.p_value;

      if (RETRIEVE_NAME() != '') {
         _checkbox._append_retrieve(_checkbox, _param1, RETRIEVE_NAME());
      }
   }

   p_active_form._delete_window(p_user);
}

defeventtab _checked_tree_form;

/**
 * Displays a generic form with a label and a tree with checked
 * items.  This can be useful for turning a list of values off
 * and on.  Takes a hash table of caption/checked values to add
 * to the tree.  For each item in the table, the key is the
 * caption and the value is a 0/1 check state.
 *
 * The resulting table with be stored in _param1 if IDOK is
 * returned.
 *
 * @param formTitle        title text for form
 * @param label            any text for a label message
 * @param table            tree captions and initial checked
 *                         values
 * @param help             help item for form
 *
 * @return int             IDOK, IDCANCEL
 *
 * @categories Forms
 */
int checkedTreeDialog(_str formTitle, _str label, int (&table):[], _str help = '')
{
   return show('-modal _checked_tree_form', formTitle, label, table, help);
}

_message.on_create(_str formTitle, _str label, int (&table):[], _str retrieveName = '', _str help = '')
{
   // set up the new labels
   p_active_form.p_caption = formTitle;
   p_active_form.p_help = help;
   _message.p_caption = label;

   // load the table contents into the tree
   int index, checked;
   caption := '';
   foreach (caption => checked in table) {
      index = _tree._TreeAddItem(0, caption, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
      _tree._TreeSetCheckState(index, checked);
   }
}

void _checkbox_form.on_resize()
{
   // keep the buttons in the corner
   padding := _message.p_x;

   xDiff := p_width - (_cancel.p_x_extent + padding);
   _cancel.p_x += xDiff;
   _ok.p_x += xDiff;

   yDiff := p_height - (_cancel.p_y_extent + padding);
   _cancel.p_y += yDiff;
   _ok.p_y = _cancel.p_y;
   _tree.p_height += yDiff;
}

_ok.lbutton_up()
{
   // make our table
   _str table:[];
   _str caption;
   int checked;

   item := _tree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (item > 0) {
      // get the caption and check state
      caption = _tree._TreeGetCaption(item);
      checked = _tree._TreeGetCheckState(item);

      table:[caption] = checked;

      item = _tree._TreeGetNextSiblingIndex(item);
   }

   _param1 = table;

   p_active_form._delete_window(IDOK);
}
