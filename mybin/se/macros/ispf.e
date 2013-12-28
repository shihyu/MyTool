////////////////////////////////////////////////////////////////////////////////////
// $Revision: 42589 $
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
#include "vsevents.sh"
#import "cua.e"
#import "diff.e"
#import "dir.e"
#import "files.e"
#import "hex.e"
#import "ispflc.e"
#import "main.e"
#import "put.e"
#import "recmacro.e"
#import "search.e"
#import "sellist.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "util.e"
#import "vi.e"
#import "window.e"
#import "eclipse.e"
#endregion
/*
   How do you shift text right or left in ISPF.

    Shift-home
    ESC
    F12, Command name?(RETRIEVE)
    F2,command name (SPLITF)?
    Are the Cut/copy/paste commands in ISPF
           Shift+F1-F3
    Is there a Delete command on Shift+f4
    S-F4  Delete

   Docs
Home      Places cursor on the ocmmand line.
Ctrl+Del  Cut to end line.
Tab   Moves cursor to next tab stop.  If there
      is a selection, the selected text is indented.
      If you want the tab key to indent text, use
      the key bindings dialog and bind the TAB
      key to the move_text_tab command.
Shift+Tab
      Moves cursor to previous tab stop.  If there
      is a selection, the selected text is unindented.
      If you want the backtab key to indent text, use
      the key bindings dialog and bind the TAB
      key to the move_text_backtab command.

F7    Page up.
F8    Page down.
F9    Next Document.
F10   Scroll page left.
F11   Scroll page right.
F12   Retrieve previous command
S-F12 Retrive next command

UNSUPPORTED FEATURES

* Cursor-up or down does not place cursor
  on the command line.
* After pressing ENTER on the command line
  the cursor is placed in the edit window.


*/


// flags for def_ispf_flags

enum ISPFFlags {
   VSISPF_RIGHT_CONTROL_IS_ENTER = 0x1,
   VSISPF_CURSOR_TO_LC_ON_ENTER  = 0x2,
}

//static _str gispf_search_string;
//static _str gispf_replace_string;
//static int gispf_search_string_len;
//static _str gispf_search_options;

static int gispf_start_col;  // 0 indicates null
static int gispf_end_col;
static _str gispf_start_label;  // '' indicates null
static _str gispf_end_label;

definit()
{
   //gispf_search_string='';
   //gispf_search_string_len=0;
   //gispf_replace_string='';
   //gispf_search_options=;
   gispf_start_col= 0;
   gispf_start_label='';

}
_command void ispf_prefix_area() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if (command_state() || def_keys!='ispf-keys' ||
       p_line_numbers_len<=0 || !(p_LCBufFlags & VSLCBUFFLAG_READWRITE) ) {
      begin_line();
      return;
   }
   // Place cursor in prefix area
   p_LCHasCursor=true;
   p_LCCol=1;
}
/**
 * Places the focus on the command line in ISPF emulation.  If already on 
 * the command line, place the cursor at the beginning of the line.
 * 
 * @see help:HOME Key Configurations
 * @see help:ISPF Emulation Options
 * 
 * @categories ISPF_Emulation_Commands
 */
_command void ispf_home() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if (isEclipsePlugin()) {
      cmdline_toggle();
   } else{
      if (command_state()){
         begin_line();
         return;
      }
      cursor_command();
   }
}
/**
 * Does command line retrieval and places the cursor on the command 
 * line, getting the next command line from the list.  If the BACK 
 * option is given, it will get the previous item from the command 
 * line history.
 * 
 * 
 * <p>Syntax:<pre>
 *    RETRIEVE [BACK]
 * </pre>
 * 
 * @see retrieve_next
 * @see retrieve_prev
 * 
 * @categories ISPF_Emulation_Commands
 */
_command void ispf_retrieve(_str back_arg="") name_info(','VSARG2_MARK|VSARG2_ICON|VSARG2_CMDLINE|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   if (isEclipsePlugin()) {
     eclipse_show_disabled_msg("ispf_retrieve");
     return;
   }
   if (upcase(back_arg)=='BACK') {
      ispf_retrieve_back();
      return;
   }
   if (!command_state()) {
      cursor_command();
   }
   retrieve_prev();
}
/**
 * This command is identical to the "ispf_retrieve back" command.
 * 
 * @categories ISPF_Emulation_Commands
 */
_command void ispf_retrieve_back() name_info(','VSARG2_MARK|VSARG2_ICON|VSARG2_CMDLINE|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   if (isEclipsePlugin()) {
     eclipse_show_disabled_msg("ispf_retrieve_back");
     return;
   }
   if (!command_state()) {
      cursor_command();
   }
   retrieve_next();
}
_command void ispf_cursor_up() name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_CMDLINE)
{
   if (!command_state()) {
      cursor_up();
      return;
   }
   cursor_data();
   bottom_of_window();
}
/**
 * Moves cursor up to the previous page of text.
 * 
 * @see ispf_down
 * @see page_up
 * 
 * @categories ISPF_Emulation_Commands
 */
_command void ispf_up() name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   page_up();
}
/**
 * Moves cursor to next page of text.
 * 
 * @see ispf_top
 * @see bottom_of_buffer 
 * 
 * @categories ISPF_Emulation_Commands
 */
_command void ispf_down() name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   page_down();
}
/**
 * Switches to the next window if One File per Window is on.  Otherwise, switches to the next buffer.
 * 
 * @see next_doc
 * 
 * @appliesTo Edit_Window
 * 
 * @categories ISPF_Primary_Commands
 * 
 */
_command void ispf_swap() name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   next_doc();
}
/**
 * Browse a data set or member.  If the member is a
 * wildcard or directory, this command will generate
 * a list of files to browse in fileman mode.  Otherwise
 * the given file or PDS member is opened for viewing
 * and/or editing.
 * 
 * @param filename Filename or path which may contains wildcards.
 * 
 * @see edit
 * @see ispf_end
 * @see ispf_cancel
 * 
 * @categories ISPF_Primary_Commands
 */
_command void ispf_browse,ispf_b(_str filename='') name_info(FILE_ARG','VSARG2_CMDLINE|VSARG2_REQUIRES_MDI)
{
   if (filename=='') return;
   if (isdirectory(filename) || iswildcard(filename)) {
      dir(maybe_quote_filename(filename));
   } else {
      edit('"-*read_only_mode 1" 'maybe_quote_filename(filename));
   }
}
/*
_command void ispf_edit(_str arglist="") name_info(FILE_ARG','VSARG2_CMDLINE|VSARG2_REQUIRES_MDI)
{
   edit(arglist);
}
*/
static int ispf_parse_copy_move(_str cmdline, _str &fileName, _str &insert_style,
                                int &lineNum, int &startLine, int &endLine)
{
   // get the data set member (file name) to copy
   _str word;
   word=parse_file(cmdline,false);
   //parse strip(cmdline) with word cmdline;
   fileName=prompt(strip(word),nls('Insert file'));
   parse strip(cmdline) with word cmdline;
   if (!file_exists(fileName)) {
      message(nls('File "%s" not found',fileName));
      return 2;
   }

   // parse the rest of the command arguments
   if (upcase(word)=='BEFORE' || upcase(word)=='AFTER') {
      insert_style=upcase(substr(word,1,1));
      parse strip(cmdline) with word cmdline;
      if (isinteger(word)) {
         lineNum = (int) word;
         if (lineNum < 0 || lineNum > p_Noflines) {
            _message_box(nls("Line number out of range %s..%s",1,p_Noflines));
            return 2;
         }
      } else if (word!='') {
         lineNum = _LCFindLabel(strip(word),true);
         if (lineNum < 0) {
            return 2;
         }
      }
      parse strip(cmdline) with word cmdline;
   }

   if (word!='') {
      if (isinteger(word)) {
         startLine= (int) word;
         parse strip(cmdline) with word cmdline;
      }
      if (isinteger(word)) {
         endLine= (int) word;
         parse strip(cmdline) with word cmdline;
      }
   }

   // display usage box if we hit something unrecognized
   if (fileName=='' || word!='' || cmdline!='') {
      _message_box("Usage: COPY file_name [BEFORE|AFTER label] [start end]");
      return 1;
   }

   // didn't find line number, search line prefix area
   if (lineNum<0) {
      int i,n=_LCQNofLineCommands();
      for (i=0; i<n; ++i) {
         _str lc_str, lc_arg; int lc_val;
         _str line_command = upcase(_LCQDataAtIndex(i));
         if (line_command=='A' || line_command=='B') {
            if (lineNum >= 0) {
               message("Destination conflict, multiple A or B line commands");
               return 2;
            }
            lineNum=_LCQLineNumberAtIndex(i);
            insert_style=line_command;
         }
      }
   }

   // All good
   return 0;
}
/**
 * The copy command copies the contents of a file or PDS member into the data being edited.  In 
 * addition to the file being copied, you can specify the following on the command line:
 * 
 * <p>Syntax:<pre>
 *    COPY [<i>member</i>] [AFTER <i>label</i> ] [BEFORE <i>label</i> ] [<i>line_range</i>]
 * </pre>
 * 
 * Arguments:
 * <dl compact style="margin-left:20pt">
 * <dt>AFTER <i>label</i></dt><dd>The destination for the data being copied.  The label may be either an ISPF label or a line number.  The data will be inserted after the specified line.
 * <dt>BEFORE <i>label</i><dd>The destination for the data being copied.  The label may be either an ISPF label or a line number.  The data will be inserted after the specified line.
 * <dt><i>line_range</i><dd>Two numbers, specifying the starting and ending lines to copy out of the given file.
 * </dl>
 * 
 * If neither AFTER nor BEFORE is specified, the default location to insert the data is after the current line (cursor position).  However, if there is an A or B line command in the prefix area, the data will be inserted at that point.
 * 
 * @return Returns 0 if successful.  Common return codes are FILE_NOT_FOUND_RC, PATH_NOT_FOUND_RC,
 *         TOO_MANY_SELECTIONS_RC, and TOO_MANY_FILES_RC.  On error, a message is displayed.
 * 
 * @see ispf_move
 * @see help:ISPF Line Command A
 * @see help:ISPF Line Command B
 * @see help:ISPF Line Labels
 * 
 * @categories ISPF_Primary_Commands
 */
_command int ispf_copy(_str arglist="") name_info(FILE_ARG','VSARG2_CMDLINE|VSARG2_REQUIRES_MDI)
{
   // parse arguments
   _str fileName='';
   _str insert_style=def_line_insert;
   int lineNum=-1;
   int startLine=0;
   int endLine=0;
   if (ispf_parse_copy_move(arglist,fileName,insert_style,lineNum,startLine,endLine)) {
      return 2;
   }

   // OK, now we can try get the file contents
   save_pos(auto p);
   if (lineNum >= 0) {
      p_line=lineNum;
   }
   _str orig_line_insert=def_line_insert;
   def_line_insert='A';
   int status= get(fileName,'',insert_style,startLine,endLine);
   def_line_insert=orig_line_insert;
   restore_pos(p);
   return status;
}
/**
 * The MOVE command moves the contents of a file or PDS member into the data being edited.  In 
 * addition to the file being copied, you can specify the following on the command line:
 * 
 * <p>Syntax:<pre>
 *    MOVE [<i>member</i>] [AFTER <i>label</i> ] [BEFORE <i>label</i> ]
 * </pre>
 * 
 * Arguments:
 * <dl compact style="margin-left:20pt">
 * <dt>AFTER <i>label</i></dt><dd>The destination for the data being copied.  The label may be either an ISPF label or a line number.  The data will be inserted after the specified line.
 * <dt>BEFORE <i>label</i><dd>The destination for the data being copied.  The label may be either an ISPF label or a line number.  The data will be inserted after the specified line.
 * </dl>
 * 
 * If neither AFTER nor BEFORE is specified, the default location to insert the data is 
 * after the current line (cursor position).  However, if there is an A or B line
 * command in the prefix area, the data will be inserted at that point.
 * 
 * <p>This command is very similar to the {@link ispf_copy} command, except that instead 
 * of copying the data, this command will copy the data and then remove the 
 * file the data is copied from, which is NOT undoable, thus this needs to 
 * be used with care
 * 
 * @return Returns 0 if successful.  Common return codes are FILE_NOT_FOUND_RC, PATH_NOT_FOUND_RC,
 *         TOO_MANY_SELECTIONS_RC, and TOO_MANY_FILES_RC.  On error, a message is displayed.
 * 
 * @see ispf_copy
 * @see help:ISPF Line Command A
 * @see help:ISPF Line Command B
 * @see help:ISPF Line Labels
 * 
 * @categories ISPF_Primary_Commands
 */
_command int ispf_move(_str arglist="") name_info(FILE_ARG','VSARG2_CMDLINE|VSARG2_REQUIRES_MDI)
{
   // parse arguments
   _str fileName='';
   _str insert_style=def_line_insert;
   int lineNum=-1;
   int startLine=0;
   int endLine=0;
   if (ispf_parse_copy_move(arglist,fileName,insert_style,lineNum,startLine,endLine)) {
      return 2;
   }

   // OK, now we can try get the file contents
   save_pos(auto p);
   if (lineNum >= 0) {
      p_line=lineNum;
   }
   _str orig_line_insert=def_line_insert;
   def_line_insert='A';
   int status= get(fileName,'',insert_style,startLine,endLine);
   def_line_insert=orig_line_insert;
   restore_pos(p);

   // if everything's going well, then ask if they want to delete the member
   if (!status) {
      int result=_message_box(nls("Delete file %s?",fileName),"",MB_YESNOCANCEL);
      if (result==IDYES) {
         status=delete_file(fileName);
      }
   }
   return status;
}
/**
 * The compare command compares the file you are editing with another file or
 * PDS member.  The differences are displayed using SlickEdit's difference
 * editor.  This differs from the usual ISPF compare command, but is more powerful.
 * Subsequently, this version of the command does not support the optional <b>exclude</b>,
 * <b>next</b>, <b>save</b>, or <b>sysin</b> parameters found in ISPF.
 * 
 * @param filename Filename to compare current buffer with.  If no
 *                 filename is specified, the current buffer is compared
 *                 to the file on disk.
 * 
 * @see diff
 * 
 * @categories ISPF_Primary_Commands
 */
_command void ispf_compare(_str filename='') name_info(FILE_ARG','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   // not supporting other ISPF options, EXCLUDE, SAVE, SYSIN, NEXT
   _str path = (filename!='')? filename:p_buf_name;
   diff(maybe_quote_filename(p_buf_name)" "maybe_quote_filename(path));
}

/**
 * Toggles display of the document in line hexadecimal mode.  The standard ISPF hex options 
 * of VERT and DATA are not supported.   When no argument is specified, line hexadecimal mode 
 * is toggled.
 * 
 * <p>Syntax:<pre>
 *    HEX [ON | OFF]
 * </pre>
 * 
 * @see hex
 * @see linehex
 * 
 * @categories ISPF_Primary_Commands
 * 
 */
_command void ispf_hex(_str arglist="") name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   boolean vert_mode=false;
   boolean horz_mode=false;
   boolean toggle_hex=false;
   _str word,cmdline=upcase(arglist);
   boolean show_usage=false;
   if (cmdline=='') toggle_hex=true;
   while (cmdline!='') {
      parse strip(cmdline) with word cmdline;
      if (word=='ON') {
         // turn on hex mode
         if (!p_hex_mode) {
            toggle_hex=true;
         }
      } else if (word=='OFF') {
         // turn off hex mode
         if (p_hex_mode) {
            toggle_hex=true;
         }
      } else if (word=='VERT') {
         // turn on ISPF hex mode, vertical orientation
         if (!p_hex_mode) {
            toggle_hex=true;
         }
         vert_mode=true;
      } else if (word=='DATA') {
         // turn on ISPF hex mode, vertical orientation
         if (!p_hex_mode) {
            toggle_hex=true;
         }
         horz_mode=true;
      } else {
         show_usage=true;
         break;
      }
   }
   if (show_usage) {
      _message_box("Usage: HEX ON | OFF");
      return;
   }
   if (toggle_hex) {
      linehex();
   }
   if (vert_mode || horz_mode) {
      message(nls("ISPF style hex modes are not supported."));
   }
}
/**
 * This command is used to specify the use of color coding in the editor.  Normally,
 * color coding is automatically configured when the file is opened.  The standard ISPF
 * hilite options for SEARCH, PAREN, and LOGIC coloring are not supported.
 * 
 * <p>Syntax:<pre>
 *    HILITE [ ON | OFF | DEFAULT | OTHER | ASM | BOOK | C | COBOL | DB2 | DTL | 
 *             HTML | JAVA | JCL | PANEL | PASCAL | PLI | REXX | SKEL | IDL] 
 *           [RESET] [FIND] [CURSOR] [DISABLED]
 * </pre>
 * Arguments:
 * <dl compact style="margin-left:20pt">
 * <dt>ON<dd style="margin-left:80pt">Turns on program color coding.
 * <dt>OFF or DISABLE<dd style="margin-left:80pt"> Turns off program color coding.
 * <dt>DEFAULT or OTHER<dd style="margin-left:80pt">  Select fundamental mode color coding
 * <dt>RESET<dd style="margin-left:80pt">Reset options, turns color coding on.
 * <dt>ASM<dd style="margin-left:80pt">System/390 Assembler Language
 * <dt>BOOK<dd style="margin-left:80pt">BookMaster (not supported)
 * <dt>C<dd style="margin-left:80pt">C or C++
 * <dt>COBOL<dd style="margin-left:80pt">COBOL
 * <dt>DB2<dd style="margin-left:80pt">DB2 sql
 * <dt>DTL<dd style="margin-left:80pt">Dialog Tag Language (not supported)
 * <dt>HTML<dd style="margin-left:80pt">Hypertext Markup Language
 * <dt>JAVA<dd style="margin-left:80pt">Java
 * <dt>JCL<dd style="margin-left:80pt">MVS Job Control Language
 * <dt>PANEL<dd style="margin-left:80pt">ISPF Panel Language (not supported)
 * <dt>PASCAL<dd style="margin-left:80pt">Pascal
 * <dt>PLI<dd style="margin-left:80pt">or pl1   PL/I
 * <dt>REXX<dd style="margin-left:80pt">Rexx
 * <dt>SKEL<dd style="margin-left:80pt">ISPF Skeleton Language (not supported)
 * <dt>IDL<dd style="margin-left:80pt">Interface Definition Language
 * <dt>FIND<dd style="margin-left:80pt">Toggles highlighting of text when you do a find, this does not work exactly like ISPF, it simply toggles the SlickEdit "Leave Selected" option (see configuration options, "Search Tab").
 * <dt>CURSOR<dd style="margin-left:80pt">Toggles highlighting of the line containing the cursor.  This also does not function exactly like ISPF, instead it simply toggles the "Draw Box around current line" option (see configuration options, "General Tab").
 * </dl>
 * 
 * @see select_mode
 * 
 * @categories ISPF_Primary_Commands
 */
_command void ispf_hilite(_str arglist="") name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   // parse through the arguments
   _str word="";
   _str langMode='';
   _str cmdline=arglist;
   boolean show_usage=(cmdline=='');
   while (cmdline!='') {
      parse strip(cmdline) with word cmdline;
      switch (upcase(strip(word))) {
      case 'AUTO':
      case 'NOLOGIC':
      case 'ON':
         _SetEditorLanguage();
         break;
      case 'RESET':
         _SetEditorLanguage();
         if (def_leave_selected=='0') {
            def_leave_selected=1;
            _config_modify_flags(CFGMODIFY_DEFVAR);
         }
         if (_default_option('u')=='0') {
            _default_option('u',1);
            _config_modify_flags(CFGMODIFY_OPTION);
         }
         break;
      case 'OFF':
         langMode="Plain Text";
         break;
      case 'DIS':
      case 'DISABLED':
         langMode="Plain Text";
         if (def_leave_selected!='0') {
            def_leave_selected=0;
            _config_modify_flags(CFGMODIFY_DEFVAR);
         }
         if (_default_option('u')!='0') {
            _default_option('u',0);
            _config_modify_flags(CFGMODIFY_OPTION);
         }
         break;
      case 'FIND':
         def_leave_selected=(def_leave_selected=='0')? 1:0;
         _config_modify_flags(CFGMODIFY_DEFVAR);
         break;
      case 'CURSOR':
         _default_option('u',(_default_option('u')=='0')? 1:0);
         _config_modify_flags(CFGMODIFY_OPTION);
         break;
      case 'SEARCH':    // not supported
      case 'PAREN':     // not supported
      case 'LOGIC':     // not supported
      case 'IFLOGIC':   // not supported
      case 'DOLOGIC':   // not supported
         break;
      case 'DEFAULT':    langMode="Plain Text";       break;
      case 'OTHER':      langMode="PL1";              break;
      case 'ASM':        langMode="OS/390 Assembler"; break;
      case 'BOOK':       langMode="Plain Text";       break; // not supported
      case 'C':          langMode="C/C++";            break;
      case 'C++':        langMode="C/C++";            break;
      case 'COBOL':      langMode="COBOL";            break;
      case 'DB2':        langMode="DB2";              break;
      case 'DTL':        langMode="Plain Text";       break; // not supported
      case 'HTML':       langMode="HTML";             break;
      case 'IDL':        langMode="IDL";              break;
      case 'JAVA':       langMode="Java";             break;
      case 'JCL':        langMode="JCL";              break;
      case 'PANEL':      langMode="Plain Text";       break; // not supported
      case 'PASCAL':     langMode="Pascal";           break;
      case 'PERL':       langMode="Perl";             break;
      case 'PLI':        langMode="PL/I";             break;
      case 'REXX':       langMode="REXX";             break;
      case 'SAS':        langMode="SAS";              break;
      case 'SKEL':       langMode="Plain Text";       break; // not supported
      default:
         show_usage=true;
         break;
      }
   }
   if (show_usage) {
      _message_box("Usage: HILITE [ON | OFF | AUTO | RESET | DISABLED |\n":+
                   "\tFIND | CURSOR | DEFAULT | OTHER |\n":+
                   "\tASM | BOOK | C | C++ | COBOL | DB2 | DTL | HTML | IDL |\n":+
                   "\tJAVA | JCL | PANEL | PASCAL | PLI | REXX | SKEL]");
      return;
   }
   if (langMode!='') {
      check_and_load_mode_support(langMode);
      _SetEditorLanguage(_Modename2LangId(langMode));
   }
}
/**
 * This command closes the current file or PDS member without saving any data.  This
 * is useful if you make changes that you do not want to save and are unable to undo.
 * 
 * @see ispf_end
 * @categories ISPF_Primary_Commands
 */
_command void ispf_cancel,ispf_can() name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   if (p_modify) {
      p_modify=0;
   }
   quit();
}
static void ispf_create_replace(_str cmdline,_str cmd_name,_str prompt_str)
{
   // parse arguments
   int status=0;
   int startLine=-1;
   int endLine=-1;
   _str word;
   parse strip(cmdline) with word cmdline;
   _str fileName=prompt(strip(word),prompt_str);
   boolean show_usage=(fileName=='');
   if (cmdline!='') {
      parse strip(cmdline) with word cmdline;
      status=ispf_parse_range(word,cmdline,startLine,endLine);
      if (status < 0) {
         return;
      }
   }
   if (show_usage) {
      _message_box(nls("Usage: %s file_name [range]",cmd_name));
      return;
   }
   // no label range given, look for 'C' or 'M' line commands
   boolean isCopy=true;
   if (cmdline!='' && startLine<0) {
      if (ispf_find_move_copy(startLine,endLine,isCopy) < 0) {
         startLine=-1;
         endLine=-1;
         isCopy=true;
      }
   }
   // allocate a selection
   int current_mark_id=_duplicate_selection('');
   int mark_id=_alloc_selection();
   if (mark_id<0){
      message(get_message(mark_id));
      return;
   }
   // select the block of lines
   typeless p;
   _save_pos2(p);
   if (startLine<0) {
      top();_begin_line();
   } else {
      p_line=startLine;
   }
   _select_line(mark_id,'C');
   if (endLine < 0) {
      bottom();_end_line();
   } else {
      p_line=endLine;
   }
   _show_selection(mark_id);
   put(fileName);
   if (!isCopy) {
      _delete_selection(mark_id);
   }
   _show_selection(current_mark_id);
   _free_selection(mark_id);
   _restore_pos2(p);
}
/**
 * 
 * The CREATE command is used to create a new file or PDS 
 * member from the data you are editing, thus functioning 
 * as a save-as function.  If the given file path does not 
 * exist, it will be created.
 * 
 * <p>Syntax:<pre>
 *    CREATE <i>filename</i>
 * </pre>
 * 
 * @see ispf_browse
 * @see ispf_end
 * @see ispf_cancel
 * @see ispf_return
 * 
 * @categories ISPF_Primary_Commands
 */
_command void ispf_create(_str filename="") name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   ispf_create_replace(filename,"CREATE",nls("Create file"));
}
/**
 * The REPLACE command is used to save to contents of the current buffer to an 
 * existing file or PDS member, thus functioning as a save-as function.
 * 
 * <p>Syntax:<pre>
 *    REPLACE [<i>member</i>]
 * </pre>
 * @see ispf_browse
 * @see ispf_end
 * @see ispf_cancel
 * @see ispf_create
 * 
 * @categories ISPF_Primary_Commands
 */
_command void ispf_replace(_str member="") name_info(FILE_ARG','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   ispf_create_replace(member,"REPLACE",nls("Replace file"));
}
/**
 * Controls ISPF emulations autosave functionality.
 * 
 * @default true
 * @categories Configuration_Variables
 * 
 * @see ispf_autosave 
 * @see ispf_end
 */
boolean def_ispf_autosave=true;
/**
 * Turn on or off prompting to save changes when you issue an {@link ispf_end}
 * command.  If autosave is turned on, you will not be prompted,
 * otherwise, you will be prompted.  This only effects the ISPF
 * command {@link ispf_end}, and does not effect the built-in {@link quit}()
 * command.  The ISPF emulation does not support the NOPROMPT option.
 * 
 * @param cmdline Syntax of </i>cmdline</i>:
 * 
 * <pre>
 *    <b>on</b>| <b>off</b>|<b>prompt</b>
 * </pre>
 * 
 * @see ispf_number
 * @see ispf_renumber
 * @see ispf_nonumber
 * @see help:ISPF Emulation Options
 * 
 * @categories ISPF_Primary_Commands
 */
_command void ispf_autosave(_str cmdline='') name_info(','VSARG2_MARK|VSARG2_READ_ONLY)
{
   // parse through the arguments
   _str word="";
   boolean show_usage=(cmdline=='');
   while (cmdline!='') {
      parse strip(cmdline) with word cmdline;
      switch (upcase(strip(word))) {
      case 'ON':
         if (!def_ispf_autosave) {
            def_ispf_autosave=true;
            _config_modify_flags(CFGMODIFY_DEFVAR);
         }
         break;
      case 'OFF':
      case 'PROMPT':
      case 'NOPROMPT':
         if (def_ispf_autosave) {
            def_ispf_autosave=false;
            _config_modify_flags(CFGMODIFY_DEFVAR);
         }
         if (upcase(word)=='NOPROMPT') {
            _message_box(nls("For your protection, AUTOSAVE NOPROMPT is not supported."));
         }
         break;
      default:
         show_usage=true;
         break;
      }
   }
   if (show_usage) {
      _message_box("Usage: AUTOSAVE [ON|OFF]");
      return;
   }
}
/**
 * 
 * The <b>end</b> command closes the current file.  If "END command saves the file" option 
 * is on (see {@link help:ISPF Emulation Options}), 
 * modifications will be saved automatically, otherwise, you 
 * will be prompted if you want to save modifications. 
 * 
 * @see ispf_autosave
 * @see ispf_browse
 * @see ispf_cancel
 * @see ispf_return
 * 
 * @categories ISPF_Primary_Commands
 */
_command void ispf_end() name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   if (_isdiffed(p_buf_id)) {
      _message_box(nls("You cannot close this file because it is being diffed."));
      return;
   }
   if (def_ispf_autosave && _need_to_save() && p_modify) {
      save();
   }
   quit();
}
/**
 * This command is identical to the {@link ispf_end} command.
 * 
 * @categories ISPF_Primary_Commands
 */
_command void ispf_return() name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   ispf_end();
}
void _on_lckey()
{
   _str key=last_event();                /* Key that was actually pressed. */
   _str keymsg=last_index('','p');    /* Prefix key(s) message */
   int kt_index=last_index('','k');
   int command_index=eventtab_index(kt_index,kt_index,event2index(key));
   typeless flags=name_info_arg2(command_index);
   if (!isinteger(flags)) flags=0;
   if (p_scroll_left_edge>=0 && !(flags&VSARG2_NOEXIT_SCROLL) && (name_type(command_index) & COMMAND_TYPE)) {
      // Exit scroll mode.
      p_scroll_left_edge=(-1);
      //sticky_message("flags="flags" cmd="name_name(command_index));
      //_beep();
   }
   if (keymsg:!='' || vsIsOnEvent(event2index(key))) {
      call_key(key,keymsg,'e');
      return;
   }
   if (command_state()) {
      if ((flags & (VSARG2_CMDLINE|VSARG2_TEXT_BOX)) ||
          (length(key)==1 && !command_index)) {
         call_key(key,keymsg,'e');
      }
      return;
   }
   if(_LCDoKey(key)) {
      return;
   }
   if (_QReadOnly()||
        (_select_type()!='' && def_persistent_select=='D' &&
        !(def_keys=='vi-keys' && vi_get_vi_mode()=='C'))
      ) {
      call_key(key,keymsg,'e');
      return;
   }
   call_key(key,keymsg,'e');
}
void _LCDel()
{
   if (_LCQFlags()&(VSLCFLAG_ERROR|VSLCFLAG_CHANGE)) {
      _LCSetFlags(0,VSLCFLAG_ERROR|VSLCFLAG_CHANGE);
      return;
   }
   _str LineCommand=_LCQData();
   _LCSetData(strip(substr(LineCommand,1,p_LCCol-1):+substr(LineCommand,p_LCCol+1),'T'));
}
void _LCBackspace()
{
   if (_LCQFlags()&(VSLCFLAG_ERROR|VSLCFLAG_CHANGE)) {
      _LCSetFlags(0,VSLCFLAG_ERROR|VSLCFLAG_CHANGE);
      return;
   }
   if (p_LCCol<=1) {
      return;
   }
   --p_LCCol;
   _LCDel();
}
void _LCTab()
{
   _begin_line();
   p_LCHasCursor=false;
}
void _LCS_Tab()
{
   if (p_LCCol<=1) {
      up();
      p_LCHasCursor=false;
   } else {
      p_LCCol=1;
   }
}
void _LCS_Enter()
{
   _begin_line();
   p_LCHasCursor=false;
   ispf_split_line('nosplit-insert-line');
}
void _LCKeyin(_str s)
{
   if (p_LCCol>p_line_numbers_len) {
      _begin_line();
      p_LCHasCursor=false;
      return;
   }
   if (_LCQFlags()&(VSLCFLAG_ERROR|VSLCFLAG_CHANGE)) {
      _LCSetFlags(0,VSLCFLAG_ERROR|VSLCFLAG_CHANGE);
      return;
   }
   _str LineCommand=strip(_LCQData(),'T');
   if (_insert_state()) {
      LineCommand=substr(LineCommand,1,p_LCCol-1):+s:+substr(LineCommand,p_LCCol);
   } else {
      LineCommand=substr(LineCommand,1,p_LCCol-1):+s:+substr(LineCommand,p_LCCol+length(s));
   }
   if (length(LineCommand)>p_line_numbers_len) {
      LineCommand=substr(LineCommand,1,p_line_numbers_len);
   }
   _LCSetData(strip(LineCommand,'T'));
   p_LCCol+=length(s);
   if (p_LCCol>p_line_numbers_len) {
      _begin_line();
      p_LCHasCursor=false;
      return;
   }
}
/**
 * Moves cursor to the top of the buffer.
 * 
 * @see ispf_bottom
 * @see top_of_buffer
 * 
 * @categories ISPF_Emulation_Commands
 */
_command void ispf_top() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   top_of_buffer();
}
/**
 * Moves cursor to the end of the buffer.
 * 
 * @see ispf_top
 * @see bottom_of_buffer
 * 
 * @categories ISPF_Emulation_Commands
 */
_command void ispf_bottom,ispf_bot() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   bottom_of_buffer();
}
/**
 * The sort command sorts lines of data in a specified order.
 * 
 * 
 * <p>Syntax:<pre>
 *    SORT [ line_range ] [X] [NX] <i>sort_field_1</i> ... <i>sort_field_n</i>
 * </pre>
 * 
 * Arguments:
 * <dl compact style="margin-left:20pt">
 * <dt><i>line_range</i><dd style="margin-left:70pt">Two numbers or labels, specifying the starting and ending range of lines to sort, inclusive.
 * <dt>X<dd style="margin-left:70pt">Look for matches only in  lines.
 * <dt>NX<dd style="margin-left:70pt">Do not report matches in excluded lines.
 * <dt><i>sort_field_i</i><dd style="margin-left:70pt">Field specifications for sorting data.  See below.
 * </dl>
 * 
 * <p>Sort supports up to 100 sort fields.  Each one can have the following options:
 * 
 * <dl compact style="margin-left:20pt">
 * <dt>A<dd>Sort data in ascending (non-decreasing) order.
 * <dt>D<dd>Sort data in descending (non-decreasing) order.
 * <dt>I<dd>Case insensitive sort.   This option has no effect if the -F or -N 
 * options are specified.
 * <dt>E<dd>Case sensitive sort (default).   This option has no effect if the 
 * -F or -N options are specified.
 * <dt>-F<dd>Sort data as file names (case sensitive on Unix).
 * <dt>-N<dd>Sort data as integers.
 * <dt><i>col1</i><dd>Starting physical column boundary for this field.
 * <dt><i>col2</i><dd>Ending physical column boundary for the field.
 * </dl>
 * 
 * @return Returns 0 if successful.  Common return codes are 1 (you tried to 
 * sort the build window), NOT_ENOUGH_MEMORY_RC, 
 * TOO_MANY_SELECTIONS_RC, and INVALID_SELECTION_HANDLE_RC.  On 
 * error, a message is displayed.
 * 
 * @see sort_buffer
 * 
 * @categories ISPF_Primary_Commands
 */
_command int ispf_sort(_str arglist="") name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   return(sort_buffer(arglist));
}
