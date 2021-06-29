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
#include "ex.sh"
#import "alias.e"
#import "bookmark.e"
#import "complete.e"
#import "config.e"
#import "dir.e"
#import "files.e"
#import "get.e"
#import "help.e"
#import "main.e"
#import "markfilt.e"
#import "menu.e"
#import "mfsearch.e"
#import "moveedge.e"
#import "os2cmds.e"
#import "pushtag.e"
#import "put.e"
#import "recmacro.e"
#import "restore.e"
#import "search.e"
#import "smartp.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tbfind.e"
#import "vi.e"
#import "vicmode.e"
#import "vivmode.e"
#import "window.e"
#import "sellist.e"
#import "math.e"
#import "tbclipbd.e"
#import "bufftabs.e"
#endregion

_str def_vi_bnext='b';

int def_preplace=1;


static const EX_CMDS= " ! = < > & ABBREVIATE BUFFER BDELETE BNEXT BPREVIOUS BUFFERS BUFDO CD COPY CLOSE DELETE EDIT FILE GLOBAL HELP JOIN K LIST":+
                " MOVE NEXT NORMAL NUMBER NOHLSEARCH PRINT PUT QUIT QALL READ REDO REGISTERS REWIND SUBSTITUTE":+
                " SET SG SHELL SBUFFER SPLIT T TAG UNDO UNABBREVIATE VGLOBAL VERSION VSPLIT WRITE WQ WQALL WALL X YANK Z ";

static const EX_ADDR_CMDS= " ! = < > COPY DELETE GLOBAL JOIN K LIST MOVE NUMBER PRINT PUT":+
                     " READ SG SUBSTITUTE T V WRITE WQ WQALL WALL YANK Z ";

static const EX_VARIANT_CMDS= " EDIT GLOBAL MAP NEXT QUIT QALL REWIND WRITE WQ ";

static const EX_NOT_SUPPORTED_CMDS= " ARGS MAP PRESERVE RECOVER UNMAP ";

static const EX_READONLY_CMDS= " ! = ABBREVIATE BDELETE CD EDIT FILE GLOBAL K LIST NEXT NOHLSEARCH NUMBER":+
                         " PRINT QUIT QALL SPLIT SET SHELL TAG UNDO UNABBREVIATE V VERSION":+
                         " VSPLIT YANK Z ";


// Constant for matching ex commands
static const EX_ARG= "ex:"TERMINATE_MATCH;

int _ex_match_pos;   // Position where the next command match should start


// These are ex SET options
static const SET_NAMES= " AUTOINDENT AUTOPRINT ERRORBELLS IGNORECASE":+
                  " LIST LISTCHARS NUMBER PARAGRAPHS PROMPT REPORT SCROLL SECTIONS SHELL":+
                  " SHIFTWIDTH SHOWMATCH SHOWMODE WRAPSCAN WRITEANY INCSEARCH HLSEARCH ";

static const SET_NOT_SUPPORTED_NAMES= " AUTOWRITE BEAUTIFY DIRECTORY EDCOMPATIBLE":+
                                " HARDTABS LISP MAGIC MESG OPTIMIZE REDRAW":+
                                " REMAP SLOWOPEN TABSTOP TAGLENGTH TAGS TERM TERSE TIMEOUT":+
                                " WARN WINDOW W300 W1200 W2400 W4800 W7200 W9600":+
                                " WRAPMARGIN ";

static const SET_TOGGLE_NAMES= " AUTOINDENT AUTOPRINT ERRORBELLS IGNORECASE LIST NUMBER PROMPT SHOWMATCH SHOWMODE WRAPSCAN WRITEANY":+
                         " INCSEARCH HLSEARCH ";

// These are abbreviations for the SET options
static const SET_ABBR_NAMES= " AI=AUTOINDENT AP=AUTOPRINT AW=AUTOWRITE BF=BEAUTIFY":+
                       " DIR=DIRECTORY EB=ERRORBELLS HT=HARDTABS IC=IGNORECASE LCS=LISTCHARS":+
                       " N=NUMBER OPT=OPTIMIZE PARA=PARAGRAPHS SH=SHELL SW=SHIFTWIDTH":+
                       " SM=SHOWMATCH TS=TABSTOP TL=TAGLENGTH TO=TIMEOUT":+
                       " WA=WRITEANY WM=WRAPMARGIN WS=WRAPSCAN IS=INCSEARCH HLS=HLSEARCH ";


// Constant for matching SET options
static const SET_ARG=  "set:"TERMINATE_MATCH;
static const SET2_ARG= "set2:"(TERMINATE_MATCH|NO_SORT_MATCH);


/**
 * By default this command handles ':' pressed.
 *
 * @return
 */
_command int ex_mode(_str sstay_in_ex='',_str initial_value='', bool select_initial_value=false) name_info(','VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   typeless key='';
   if ( command_state() ) {
      key=last_event();
      if ( length(key):==1 ) {
         keyin(key);
      }
      return(0);
   }

   _macro_delete_line();

   // This is set by the 'Q' command
   stay_in_ex := (sstay_in_ex!='' && sstay_in_ex);
   typeless report_threshold=__ex_set_report();
   if ( ! isinteger(report_threshold) ) {
      report_threshold=VI_DEFAULT_REPORT;
   }
   prompt := ": ";
   if ( stay_in_ex ) {
      if (def_vim_stay_in_ex_prmpt) {
         prompt='(Type "vi" to exit ex mode): ';
      }
      if ( ! __ex_set_prompt() ) {
         prompt='';
      }
   }
   if (select_active() && initial_value=='') {
      initial_value=EX_VISUAL_RANGE;
   }
   // Use this after we are finished for the REPORT option
   line := "";
   typeless status=0;
   Noflines := p_Noflines;
   // Save this in case a command (ie TAG) takes out of the current buffer
   int orig_buf_id=p_buf_id;
   for (;;) {
      #if 1
      // Old:
      //status=get_string(line,prompt);
      // RGH - 3/14/06
      // Need to turn off list_completions here to avoid completions coming up when in ex_mode
      orig_listcompletions := _cmdline.p_ListCompletions; 
      _cmdline.p_ListCompletions=false;
      status=get_string(line,prompt,'',initial_value,select_initial_value);
      _cmdline.p_ListCompletions = orig_listcompletions;
      #else
      // The third argument allows completion for the 'edit' ex command.
      // The bad side effect to this, however, is that '?' does not insert
      // a question mark for commands other than 'edit'. For these cases
      // the user must do a Ctrl+V, then '?'.
      status=get_string(line,prompt,'exarg*:'(FILE_CASE_MATCH));
      #endif
      if ( status ) {
         if ( ! stay_in_ex ) {
            // User aborted
            status=0;
            break;
         } else {
            // Clear the "Command cancelled" message
            clear_message();
         }
      } else if ( upcase(strip(line))=='VI' || upcase(strip(line))=='VIS' || upcase(strip(line))=='VISU' ||
                  upcase(strip(line))=='VISUA' || upcase(strip(line))=='VISUAL') {
         break;
      }
      _macro_call('ex_parse_and_execute',line);
      status=ex_parse_and_execute(line);
      if (select_active()) {
         deselect();
      }
      if (vi_get_vi_mode() == 'V') {
         vi_visual_toggle_off(0);
         vi_switch_mode('C',0);
      }
      if ( !stay_in_ex ) break;
   }
   // We do not want to clear a more important message!
   if ( !status && _isEditorCtl() &&orig_buf_id==p_buf_id ) {
      int diff=p_Noflines-Noflines;
      if ( diff>0 ) {
         if ( diff>=report_threshold ) {
            vi_message(diff' more lines');
         }
      } else if ( diff<0 ) {
         if ( -diff>=report_threshold ) {
            vi_message(-diff' fewer lines');
         }
      }
   }

   return(status);
}

/**
 * By default this handles 'Q' pressed.
 *
 * @return
 */
_command int ex_ex_mode () name_info(','VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   _macro('m',_macro());

   return(ex_mode('1'));
}

/**
 * By default this command handles '/' pressed.
 * Modified to handle repeat counts. - RH
 * 
 *
 * @return
 */
_command int ex_search_mode (...) name_info(','VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   // Repeat count
   count := 0;

   typeless key='';
   if ( command_state() ) {
      key=last_event();
      if ( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }

   _str cmdname=name_name(last_index('','C'));
   executed_from_key := name_name(last_index()):==translate(cmdname,'-','_');

   if (executed_from_key) {
      _macro_delete_line();
      vi_get_event('S');
   }

   if (def_vi_or_ex_incsearch) {
      i_search();
      return 0;
   }

   prmpt := "";
   _str arg1=arg(1);
   if ( arg1=='-' ) {
      // If it's a backward search then the count will come in as arg(3)
      if (isinteger(arg(3))) {
         count = arg(3);
      } else {
         count = 1;
      }
      prmpt='?';
   } else {
      // If it's a forward search then the count will come in as arg(1)
      if(isinteger(arg(1))){
         count = arg(1);
      } else {
         count = 1;
      }
      prmpt='/ ';
   }

   line := "";
   typeless status=0;
   if( arg(2)!='' ) {
      line=arg(2);
   } else {
      // no argument for the search...
      // if another function called ex_search_mode, and we are playing back a macro...
      if (!executed_from_key && (_macro('r'))) {
         line = vi_get_all_events();
      } else {
         status=get_string(line,prmpt);
      }
   }

   if ( status ) {
      // User aborted
      return(status);
   }

   // If the search was directly called from the keyboard, or we were called from 
   // a '?' command, directly record ex_search_mode for the macro
   if (executed_from_key || name_name(last_index()) :== 'ex-reverse-search-mode') {
      _macro_call('ex_search_mode',arg1,line);
   } else if (_macro('s')) {
      /*
      * We are recording a macro, and ex_search_mode was called from 
      * another function.  Append the search string to the macro. 
      */
      _macro_call('vi_get_event','',line);
   }

   // Start parsing at beginning of line
   start := 1;
   if ( arg1=='-' ) {
      line='?'line;
   } else {
      line='/'line;
   }
   search_re := "";
   search_options := "";
   status=ex_parse_search(line,start,search_re,search_options);
   search_options :+= '@';
   if ( status ) {
      vi_message('Error parsing search string');
      return(1);
   }
   _str old_context=vi_get_prev_context();
   vi_set_prev_context();
   if ( arg1=='-' ) {
      if ( ! pos('-',search_options) ) {
         search_options :+= '-';
      }
   }

   if( !pos('P',search_options,1,'i') && (_default_option('S') & WRAP_SEARCH) ) {
      search_options :+= 'P';   // We need to do this for ex-repeat-search
   }
   if( !pos('e|i',search_options,1,'ir') ) {
      search_options :+= _search_case();
   }

   typeless p=0;
   col := 0;
   int i;
   matched_all:=false;
   if( search_re:=='' ) {
      status=ex_repeat_search(arg1,'1');   // The second argument tells ex-repeat-search that it was called from ex-search-mode
   } else {
      p=point();col=p_col;
      // Can't support def_leave_selected and def_vi_always_highlight_all for multiple reasons.
      // Colors don't look right (big problem) and features don't work right (not too hard to fix).
      if (def_leave_selected) {
         if (def_vi_always_highlight_all) {
            clear_highlights();
            def_vi_always_highlight_all=false;
            _config_modify_flags(CFGMODIFY_DEFVAR);
         }
      }
      status=vi_search(search_re,search_options,matched_all);
      // repeat the search if necessary
      for (i = 0; i < count - 1; i++) {
         ex_repeat_search();
      }
      if( !matched_all && status && (old_search_flags&WRAP_SEARCH) ) {
         save_pos(p);
         if( arg1=='-' ) {
            bottom();
         } else {
            top();
         }
         status=vi_search(search_re,search_options);
         // repeat the search if necessary
         for (i = 0; i < count - 1; i++) {
            ex_repeat_search();
         }
         if( status ) {
            restore_pos(p);
         }
      } else if ( ! status && p==point() && col==p_col ) {   // In same place?
         status=ex_repeat_search();
      }
   }
   typeless msg='';
   if ( status ) {
      vi_set_prev_context(old_context);   // Set the previous context back on error
      if ( status==STRING_NOT_FOUND_RC ) {
         msg='Pattern not found';
      } else {
         msg=get_message(status);
      }
      vi_message(msg);
      return(1);
   }
   if (!(/*pos('M',upcase(old_search_flags)) && */select_active()) && def_persistent_select!='Y' && def_leave_selected && !matched_all) {
      _select_match();
   }

   return(0);
}

/**
 * By default this handles '?' pressed.
 * Modified to handle repeat count. -RH
 * 
 * @return
 */
_command int ex_reverse_search_mode(...) name_info(','VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   // Repeat count
   int count;

   // Determine whether or not we have a multiplier for the search
   if(isinteger(arg(1))){
      count = arg(1);
   } else {
      count = 1;
   }

   if ( command_state() ) {
      typeless key=last_event();
      if ( key:=='?' ) {
         maybe_list_matches();
      } else if ( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }

   _str cmdname=name_name(last_index('','C'));
   executed_from_key := name_name(last_index()):==translate(cmdname,'-','_');

   _macro('m',_macro());

   if (executed_from_key) {
      _macro_delete_line();
      vi_get_event('S');
   }

   return(ex_search_mode('-', '', count));
   //return(ex_search_mode('-'));
}

/**
 * By default this handles 'n' pressed.
 *
 * @return
 */
_command int ex_repeat_search (...) name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   if ( command_state() ) {
      typeless key=last_event();
      if ( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }

   _macro_delete_line();
   _macro_call('ex_repeat_search',arg(1),arg(2));

   int save_search_flags=old_search_flags;
   if( old_search_flags&REVERSE_SEARCH ) {
      // if 'N' OR '/'
      if( (arg(1)=='-' && arg(2)=='') || (arg(1)=='' && arg(2)!='') ) {
         old_search_flags &= (~REVERSE_SEARCH);
      }
   } else {
      // if 'N' OR '?'
      if( arg(1)=='-' ) {
         old_search_flags |= REVERSE_SEARCH;
      }
   }
   // do not restore the old wrapscan/nowrapscan setting...respect what is currently set
   doWrap := _default_option('S') & (WRAP_SEARCH|PROMPT_WRAP_SEARCH);
   old_search_flags = old_search_flags & ~(WRAP_SEARCH|PROMPT_WRAP_SEARCH); 
   if (doWrap) {
     old_search_flags = old_search_flags|doWrap; 
   }
   old_search_range = VSSEARCHRANGE_CURRENT_BUFFER;
   _str old_context=vi_get_prev_context();
   vi_set_prev_context();
   _mffindNoMore(1);
   _mfrefNoMore(1);
   //_str old_dps = def_persistent_select;
   //def_persistent_select = 'Y';

   typeless status=execute('find-next',"");

   //vi_visual_select();
   //def_persistent_select = old_dps;

   // Only set the old_search_flags back if we did NOT use '/' or '?'
   if( arg(2)=='' ) {
      old_search_flags=save_search_flags;
   }

   if( status ) {
      // Set the previous context on error
      vi_set_prev_context(old_context);
   }
   _undo('S');

   return(status);
}

/**
 * By default this handles 'N' pressed.
 *
 * @return
 */
_command int ex_reverse_repeat_search () name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   _macro('m',_macro());

   return(ex_repeat_search('-'));
}

// This function flags a line for commands like :global
static int ex_flag_line(...)
{
   unflag := (upcase(arg(1))=='U');
   status := 0;
   if( unflag ) {
      _lineflags(0,VIMARK_LF);
   } else {
      // Flag it
      _lineflags(VIMARK_LF);
   }

   return(status);
}

// This function finds a flagged line for commands like :global
static int ex_find_flagged_line()
{
   linenum := p_line;
   for(;;) {
      int flags=_lineflags();
      if( flags&VIMARK_LF ) {
         return(0);
      }
      int status=down();
      if( status ) {
         p_line=linenum;
         return(status);
      }
   }
}

int ex_client_height()
{
   wid := p_window_id;
   p_window_id=_mdi.p_child;
   int x,y,width,height;
   _get_max_window(x,y,width,height);
   height=height intdiv p_font_height;
   p_window_id=wid;

   return(height);
}

void ex_msg_ro()
{
   popup_message(nls('This command is not allowed in Read Only mode.'));
}

void ex_msg_editctl()
{
   popup_message(nls('This command is not allowed in an Edit Control.'));
}

/**
 * This function parses out the address, command, and parameter parts of
 * an ex command and then executes the command.
 *
 * @return
 */
typeless ex_parse_and_execute(_str line,bool delay_feedback=false,int &idx=0,_str &params='',int &begin_addr=0,int &end_addr=0,bool &variant_form_used=false)
{
   // This is important for any command that displays a list of modified lines
   len := length(line);
   start := 1;
   //int begin_addr=0;
   //int end_addr=0;
   //_str params='';
   // Indicates whether to use the variant form of the command parsed
   // bool variant_form_used=false;
   // Parse out the address
   // RGH - As of 12.0.2, ex_parse_address_range will notice if a
   // selection is active, and if so, parse the address range from
   // the selection.  When __ex_global calls ex_parse_and_execute,
   // we don't want to pay attention to the selections (in terms of
   // ranges)...so we use arg(2)_to let us know.
   typeless status=ex_parse_address_range(line,start,begin_addr,end_addr,delay_feedback);
   if ( status ) {
      return(status);
   }
   cmd := "";
   status=ex_parse_command(line,start,cmd);
   if ( status ) {
      return(status);
   }
   orig_cmd := "";
   if ( cmd!='' ) {
      // Save this so we can check against the list of unsupported commands
      orig_cmd=upcase(strip(cmd));
      // Find the first ex command name that matches
      cmd=ex_match(cmd,1);
      // Reset ex command matching
      ex_match('',2);
      if ( cmd=='' ) {
         if ( pos(' 'orig_cmd' ',EX_NOT_SUPPORTED_CMDS) ) {
            vi_message('"'orig_cmd'": Command not supported');
         } else {
            vi_message('Unknown command');
         }
         return(1);
      } else if ( _QReadOnly() && ! pos(' 'cmd' ',EX_READONLY_CMDS) ) {
         ex_msg_ro();
         return(1);
      }
   }
   use_variant_form := false;
   // Use the variant form of the command?
   if ( _SubstrChars(line,start,1)=='!' && pos(' 'cmd' ',EX_VARIANT_CMDS) ) {
      // Use the variant form of the command
      use_variant_form=true;
      // Set up to read after the '!'
      start++;
   }
   //int idx=0;
   proc_name := "";
   params=strip(_SubstrChars(line,start));
   if ( cmd=='' && params=='' ) {
      // We simply have an address (line number)
      //
      // Execute the ending address as you would on the SlickEdit command line
      execute(end_addr,"");
      return(0);
   } else {
      // It is a valid ex command
      if ( cmd:=='!' ) {
         proc_name='__ex_shell_execute';
      } else if ( cmd:=='=' ) {
         proc_name='__ex_show_address';
      } else if( cmd:=='<' ) {
         proc_name='__ex_shift_text_left';
      } else if( cmd:=='>' ) {
         proc_name='__ex_shift_text_right';
      } else if( cmd:=='&' ) {
         proc_name='ex_repeat_last_substitute';
      } else {
         proc_name='__ex_':+lowcase(cmd);
      }
      idx=find_index(proc_name,PROC_TYPE|COMMAND_TYPE);
      if ( ! idx ) {
         vi_message('Can''t find procedure: 'proc_name);
         return(1);
      }
      // Was there an address before the command name?
      if ( begin_addr!='' || end_addr!='' ) {
         if ( ! pos(' 'cmd' ',EX_ADDR_CMDS) ) {
            // It is not a valid address command
            vi_message('No address allowed on this command');
            return(1);
         }
      }
   }
   // We call the command index with all the possible arguments
   // even though it might not use all of them.
   //
   // Set this so commands like GLOBAL don't recurse
   last_index(idx);
   return(call_index(params,begin_addr,end_addr,use_variant_form,delay_feedback,idx));
}

// This function parses out the address range of an ex command.
static int ex_parse_address_range(_str line,int &start,int &begin_addr,int &end_addr, bool ignore_selection = false)
{
   delim := "";
   ch := "";
   msg := "";
   typeless a='';
   // Check for the '%' abbreviation
   tmp := strip(_SubstrChars(line,start,1),'L');
   if ( _SubstrChars(tmp,1,1)=='%' ) {
      // '%' is an abbreviation for '1,$'
      begin_addr=1;
      end_addr=p_Noflines;
      start++;
   } else {
      a=ex_parse_and_eval_address(line,start,msg);
      if ( (a<0 || a>p_Noflines) && a!='' ) {
         // Error
         if ( a<0 ) {
            vi_message(msg);
         } else {
            // a>p_Noflines
            vi_message('Not that many lines in buffer');
         }
         return(1);
      }
      begin_addr=a;
      ch=_SubstrChars(line,start,1);
      if ( ch!=',' && ch!=';' ) {
         // There is no ending address
         end_addr=begin_addr;
         // before we leave, check for selection
         if (!ignore_selection) {
            typeless sel_id = select_active();
            if (sel_id != 0) {
               ex_get_address_range_from_sel(begin_addr,end_addr,0);
            } 
         }
         // Vim supports putting : before command even though it was already typed.
         if (substr(line,start,1)==':') {
            ++start;
         }
         return(0);
      } else {
         // ch=',' or ch=';'
         delim=ch;
         if ( begin_addr=='' ) {
            // Default address
            begin_addr=ex_get_curlineno();
         }
      }
      if ( delim==';' ) {
         // Force the beginning address to set the current line before
         // evaluating the second address.
         p_line=begin_addr;
      }
      // Start looking for the ending address after the ',' or ';'
      start += length(ch);
      a=ex_parse_and_eval_address(line,start,msg);
      if ( (a<0 || a>p_Noflines) && a!='' ) {
         // Error
         if ( a<0 ) {
            vi_message(msg);
         } else {
            // a>p_Noflines
            vi_message('Not that many lines in buffer');
         }
         return(1);
      }
      end_addr=a;
      if ( end_addr=='' ) {
         // Default address
         end_addr=ex_get_curlineno();
      }
      // Vim supports putting : before command even though it was already typed.
      if (substr(line,start,1)==':') {
         ++start;
      }
   }

   return(0);
}

/**
 * Grab the begin/end address for an ex command from the active 
 * selection. 
 *  
 * @param begin_addr
 * @param end_addr
 * @param a 
 */
static void ex_get_address_range_from_sel(int &begin_addr, int &end_addr, int a){
   save_pos(auto p);
   offset := 0;
   if (isinteger(a)) {
      offset = (int)a;
   }
   begin_select();
   begin_addr = p_line;
   end_select();
   end_addr = p_line + offset;
   restore_pos(p);
}
// Some notes:
// -Implicit addresses are defined by the following symbols:
//    '.' = current line number
//    '$' = last line number in buffer
//    '/' = line number resulting from forward search
//    '?' = line number resulting from backward search
//
// -An implied addition is when two addresses (either
//  implicit or not) are separated by a space or tab;
//  the two addresses are added together.
static _str ex_parse_and_eval_address(_str line,int &start,_str &msg)
{
   // If this is non-zero, then do not evaluate implicit addresses
   parse_only := (arg(4)!='' && arg(4));
   typeless running_sum=0;
   // The pending result of successive +'s and -'s
   pending_adder := 0;
   // An implied addition is two addresses separated by spaces or tabs
   maybe_implied_add := 0;
   last_op := "";
   // Keeps track of whether an implicit address was used (i.e. '.','$')
   implicit_used := 0;
   // This is the default error message
   msg='Badly formed address';
   // Check to see if we need an implicit address to start us off
   tmp := strip(_SubstrChars(line,start,1),'L');
   if ( pos(_SubstrChars(tmp,1,1),'+-') ) {
      // Put in the implicit current line number ('.')
      running_sum=ex_get_curlineno();
      implicit_used=1;
   } else if ( substr(line,start)=='' ) {
      // An empty address
      return('');
   }
   ch := "";
   arg1 := "";
   delim := "";
   last_ch := "";
   search_re := "";
   search_options := "";
   linemarkflag := "";
   mark_name := "";
   typeless p,q;
   typeless num=0;
   typeless status=0;
   typeless old_prev_context='';
   buf_id := 0;
   len := length(line);
   int i=start;
   for (;;) {
      if ( i>len ) break;
      ch=_SubstrChars(line,i,1);
      if ( ch=='+' || ch=='-' ) {
         if ( ch=='+' ) {
            pending_adder++;
         } else { // ch='-'
            pending_adder--;
         }
         // There can only be an implied addition when
         // a space appears before an address.
         maybe_implied_add=0;
         ++i;
      } else if ( pos(ch,"0123456789.$/?'`") ) {
         if ( !isdigit(ch) ) {
            if ( implicit_used ) {
               // Error - can't use more than one implicit address!
               return(-1);
            } else {
               implicit_used=1;
            }
         }
         if ( pending_adder ) {
            if ( maybe_implied_add ) {
               running_sum += pending_adder;
            } else if ( last_op=='+' ) {
               running_sum += (pending_adder-1);
            } else if ( last_op=='-' ) {
               running_sum += (pending_adder+1);
            } else {
               // Error
               return(-1);
            }
         }
         // Now find the rest of the number OR expand the the implicit address
         if ( isdigit(ch) ) {
            num=ch;
            ++i;
            for (;;) {
               if ( i>len ) break;
               ch=_SubstrChars(line,i,1);
               if ( isdigit(ch) ) {
                  num :+= ch;
               } else {
                  break;
               }
               ++i;
            }
         } else if ( ch=='/' || ch=='?' ) {
            // Find the end of the search command
            delim=ch;   // Save the search delimiter
            ex_parse_search(line,i,search_re,search_options,false);
            if ( _SubstrChars(line,i,1)==delim && i<=len ) {
               // We found an implicit address
               implicit_used=1;
            }
            // Evaluate the search address?
            if ( !parse_only ) {
               // Do the search
               save_pos(p);
               if( _default_option('S') & WRAP_SEARCH ) {
                  // We need to do this for ex-repeat-search()
                  search_options :+= 'P';
               }

               arg1='';
               if( delim=='?' ) {
                  arg1='-';
               }
               // The real vi will not find the first match on the
               // current line.
               _end_line();
               if( search_re:=='' ) {
                  // arg(2)='1' so the search direction is reset
                  status=ex_repeat_search(arg1,'1');
               } else {
                  status=vi_search(search_re,search_options);
                  if( status && (old_search_flags&WRAP_SEARCH) ) {
                     save_pos(q);
                     if( arg1=='-' ) {
                        bottom();
                     } else {
                        top();
                     }
                     status=vi_search(search_re,search_options);
                     if( status ) {
                        restore_pos(q);
                     } else {
                        // Clear out the "String not found" message
                        clear_message();
                     }
                  }
               }
               if ( status ) {
                  restore_pos(p);
                  msg='Pattern not found';
                  return(-1);
               }
               // The resulting line number from the search
               num=p_line;
               // Go back to where we started
               restore_pos(p);
            } else {
               // Dummy value
               num=0;
            }
            if ( i<=len ) {
               // Set up to read the next character
               ++i;
            }
         } else if ( ch=="'" && substr(line,i+1,1)=='<') {
            if (!select_active()) {
               msg="'< Requires visible selection";
               return(-1);
            }
            save_pos(p);
            mark:=_duplicate_selection();_begin_select(mark);_free_selection(mark);
            num=p_line;
            restore_pos(p);
            i+=2;
         } else if ( ch=="'" && substr(line,i+1,1)=='>') {
            if (!select_active()) {
               msg="'< Requires visible selection";
               return(-1);
            }
            save_pos(p);
            mark:=_duplicate_selection();_end_select(mark);_free_selection(mark);
            num=p_line;
            restore_pos(p);
            i+=2;
         } else if ( ch=="'" || ch=="`" ) {
            linemarkflag= (ch=="'")?('1'):('');
            // Mark address
            ++i;
            if ( i>len ) {
               // Error - mark without a name
               msg="Marks are ' and ` and a-z";
               return(-1);
            }
            mark_name=_SubstrChars(line,i,1);
            if( mark_name=="'" || mark_name=="`" ) {
               if( (mark_name=="'" && linemarkflag=='') ||
                   (mark_name=="`" && linemarkflag!='')
                 ) {
                  // Mark name of "'" or "`" doesn't jibe
                  msg="Invalid mark name";
                  return(-1);
               }
               mark_name='';
            }
            // Increment past the mark name
            i+=length(mark_name);
            // Evaluate the mark address?
            if ( !parse_only ) {
               // Save this in case the mark is in another buffer
               buf_id=p_buf_id;
               save_pos(p);
               // Save this so we can restore it
               old_prev_context=vi_get_prev_context();
               status=vi_goto_mark(mark_name,linemarkflag);
               // Restore the old previous context
               vi_set_prev_context(old_prev_context);
               if ( status || buf_id!=p_buf_id ) {
                  if ( p_buf_id!=buf_id ) {
                     // Put the cursor back where it was
                     _undo();
                     load_files('-bp +bi 'buf_id);
                  }
                  msg='Undefined mark referenced';
                  // Error
                  return(-1);
               }
               // The resulting line number from the vi-goto-mark
               num=p_line;
               restore_pos(p);
            } else {
               // Dummy value
               num=0;
            }
         } else {
            // Evaluate the '.' or '$' address?
            if ( !parse_only ) {
               if ( ch=='.' ) {
                  num=ex_get_curlineno();
               } else {
                  // ch='$'
                  num=p_Noflines;
               }
            } else {
               // Dummy value
               num=0;
            }
            ++i;
         }
         if ( pending_adder || maybe_implied_add ) {
            // Now perform the operation:
            //   (running_sum) last_op (num)
            //
            //   OR
            //
            //   (running_sum)   +     (num)
            if ( maybe_implied_add ) {
               running_sum += num;
            } else if ( last_op=='+' ) {
               running_sum += num;
            } else if ( last_op=='-' ) {
               running_sum -= num;
            }
            // Reset these after the operation is done
            pending_adder=0;
            maybe_implied_add=0;
         } else {
            // No pending operation
            if ( last_op=='' ) {
               if ( !running_sum ) {
                  running_sum=num;
               } else {
                  running_sum += num;
               }
            } else {
               // Error
               return(-1);
            }
         }
      } else if ( ch:==' ' || ch:==\t ) {
         if ( running_sum ) {
            // Maybe an implied addition
            maybe_implied_add=1;
         }
         ++i;
      } else {
         // We have reached the end of the address
         break;
      }
      last_ch=ch;
      if ( ch!='' ) {
         last_op=ch;
      }
   }
   if ( parse_only ) {
      running_sum=substr(line,start,i-start);
   } else {
      if ( pending_adder ) {
         // We had a string of +'s and -'s to add
         running_sum += pending_adder;
      }
      if ( substr(line,start,i-start)=='' ) {
         // Implicit current line number
         running_sum='';
      }
   }
   start=i;

   return(running_sum);
}

// This function parses out the command part of an ex command.
static int ex_parse_command(_str line,int &start,_str &cmd)
{
   int i=start;
   len := length(line);
   cmd='';
   for (;;) {
      if ( i>len ) {
         break;
      }
      _str ch=_SubstrChars(line,i,1);
      if ( ch:==' ' && cmd=='' ) {
         i+=length(ch);
         continue;
      } else if ( ch:=='=' || ch:=='!' || ch:=='<' || ch:=='>' || ch:=='&') {
         if ( cmd=='' ) {
            cmd=ch;
            i+=length(ch);
         }
         break;
      } else if ( !isalpha(ch) ) {
         break;
      } else if (ch:=='k' && cmd=='') {
         cmd='k';
         ++i;
         break;
      }
      cmd :+= ch;
      i+=length(ch);
   }
   start=i;

   return(0);
}

// This function parses out the regular expression and assigns the search
// options according to the delimiter ( '/'=forward , '?'=backward ).
static int ex_parse_search(_str line,int &start,_str &search_re,_str &search_options,bool parse_options=true)
{
   // parse_options setting effect the following:
   //
   // Used to indicate whether we should parse options from search command.
   // This is useful in an EX command like this:
   //
   //   :1,/searchstring/s/this/that
   //
   // where the 's/this/that' part is incorrectly parsed as options.

   // Find the end of the search command
   //
   // At the end of the loop, this will hold the entire search expression
   search_expr := "";
   len := length(line);
   int i=start;
   _str delim=_SubstrChars(line,i,1);
   // Is this a valid delimiter?
   if( !pos(delim,'/?') ) {
      return(1);
   }
   ch := "";
   i+=length(delim);
   for(;;) {
      if( i>len ) break;
      ch=_SubstrChars(line,i,1);
      search_expr :+= ch;
      if( ch==delim ) {
         break;
      } else if ( ch=='\' ) {
         ch=_SubstrChars(line,i+1,1);
         // Get the skipped over char
         search_expr :+= ch;
         // Skip over the escaped character
         i+=1+length(ch);
      } else {
         i+=length(ch);
      }
   }
   start=i;
   // Set up the regular expression and search options
   search_options='';
   if( ch==delim && i<=len ) {
      // There was an ending delimiter
      //
      // Get the regular expression inside the delimiters
      search_re=substr(search_expr,1,length(search_expr)-1);
      if ( parse_options ) {
         // Options are everything after the last delim
         search_options=strip(substr(line,start+1));
         _maybe_strip(search_options, delim);
      }
   } else if( i>len ) {
      // There was no ending delimiter, so the whole thing is the regular expression
      search_re=search_expr;
   }
   // /\< and \> are special word boundary escape sequences for vim searching
   // \b will work in all supported regex flavors for this  
   search_re = stranslate(search_re,'\b','\<');
   search_re = stranslate(search_re,'\b','\>');
   // Set up the search options
   if( !pos('(n|r|b|u|l|&|\~)',search_options,1,'ri') ) {
      // Default regular expression type
      search_options :+= _vi_search_type();
   }
   // In Vim, upper case I means case sensitive search
   if (pos('I',search_options)) {
      search_options :+= 'e';
   } else if( !pos('(i|e)',search_options,1,'r') ) {
      // Default case-sensitivity
      search_options :+= _search_case();
   }
   if ( delim=='?' ) {
      // Reverse search
      search_options :+= '-';
   }

   return(0);
}

/**
 * This function is a match function for an ex command.
 *
 * @return
 */
_str ex_match(_str name,typeless find_first)
{
   if ( find_first ) {
      _ex_match_pos=1;
      if ( find_first==2 ) {
         return('');
      }
   }
   name=upcase(strip(name));
   p := pos('{ 'name'[~ \t]@ }',EX_CMDS,_ex_match_pos,'er');
   if ( p ) {
      // Next match occurs at the trailing space
      _ex_match_pos=p+pos('0')-1;
      return(strip(substr(EX_CMDS,pos('S0'),pos('0'))));
   }

   return('');
}

/**
 * This function is a match function for ex command arguments.
 *
 * @return
 */
_str exarg_match(_str name,bool find_first)
{
   lch := "";
   line := "";
   start := 0;
   _cmdline.get_command(line,start);
   typeless ex='', a='';
   parse line with ex a;
   ex=strip(ex,'T','!');
   if( _SubstrChars(a,1,1)=='!' ) {
      lch='!';
      a=substr(a,2);
   }
   typeless key=last_event();
   if( ex_match(ex,1)=='EDIT' ) {
      if( a=='' && key:==' ' ) {
         return(name);
      } else {
         return(lch:+f_match(a,find_first));
      }
   } else {
      if( find_first ) {
         return(name);
      } else {
         return('');
      }
   }
}

/**
 * This function returns the current line number within vi.
 *
 * @return
 */
int ex_get_curlineno()
{
   return(p_line);
}

// This function converts '#' and '%' to prev-buffer and
// current-buffer respectively.
static _str ex_process_shellcmd(_str cmd)
{
   if( cmd=='' ) {
      return('');
   }
   ch := "";
   newcmd := "";
   bufname := "";
   i := 1;
   len := length(cmd);
   thisbufid := 0;
   while( i<=len ) {
      ch=_SubstrChars(cmd,i,1);
      if( ch=='\' ) {
         newcmd :+= substr(cmd,i,2);
         // Skip over the escaped char
         i+=2;
         continue;
      } else if( ch=='#' ) {
         // Check for previous buffer name
         thisbufid=p_buf_id;
         _prev_buffer();
         if( p_buf_id==thisbufid || !_Nofbuffers() ) {
            // There is no previous buffer
            vi_message('No filename to substitute for #');
            return('');
         }
         bufname=p_buf_name;
         _next_buffer();   // Switch back
         newcmd :+= _maybe_quote_filename(bufname);
      } else if( ch=='%' ) {
         // Current buffer name
         if( _no_child_windows() ) {
            // There is no current buffer
            vi_message('No filename to substitute for %');
            return('');
         }
         bufname=_maybe_quote_filename(p_buf_name);
         newcmd :+= bufname;
      } else {
         newcmd :+= ch;
      }
      i+=length(ch);
   }

   return(newcmd);
}


int vi_ex_filter(int a1,int a2,_str cmd,bool position_on_last_line=false) {
   // Now mark the lines which will be used as input to the filter AND replaced with the output from the filter
   old_mark:=_duplicate_selection('');
   mark:=_alloc_selection();
   if ( mark<0 ) {
      vi_message(get_message(mark));
      return(mark);
   }
   p_line=a1;
   _select_line(mark,'P');
   p_line=a2;
   _select_line(mark,'P');
   _begin_select(mark);
   // Make a duplicate so we can cut it to the clipboard later
   mark2:=_duplicate_selection(mark);

   // Now make a temporary file to hold the input to the shell
   // and copy the marked lines into it.
   _str temp_in=mktemp(1,'in');
   if( temp_in=='' ) {
      _free_selection(mark);
      _free_selection(mark2);
      vi_message('Unable to make temp file');
      return(1);
   }
   // Do this in case the working directory changes
   temp_in=absolute(temp_in);

   encoding:=p_encoding;
   // Need this so can restore in the case of an editor control
   orig_wid:=_create_temp_view(auto temp_wid);
   p_buf_name=absolute(temp_in);
   p_encoding=encoding;
   _copy_to_cursor(mark2);
   _free_selection(mark2);
   status:=save('+o');
   _delete_temp_view(temp_wid);
   // Need this so can restore in the case of an editor control
   activate_window(orig_wid);

   if( status ) {
      _free_selection(mark);
      delete_file(temp_in);
      return(status);
   }

   // Now make a temporary file to hold the output from the shell
   _str temp_out=mktemp(1,'out');
   if ( temp_out=='' ) {
      _free_selection(mark);
      vi_message('Unable to make temp file');
      return(status);
   }
   // Do this in case the working directory changes
   temp_out=absolute(temp_out);

   _str cmdline=cmd' <'temp_in' >'temp_out;
   shell(cmdline,'QP');
   if ( file_match(temp_out,1)!=temp_out ) {
      _free_selection(mark);
      vi_message('Error opening results of shell command');
      return(1);
   } else {
      _macro('m',_macro('s'));
      _macro_call('vi_ex_filter',a1,a1,cmd,position_on_last_line);
      // Success
      _show_selection(mark);
      old_line := p_line;
      vi_cut(false,'');
      _show_selection(old_mark);
      _free_selection(mark);
      typeless old_line_insert=def_line_insert;
      if( p_line!=old_line ) {
         // The end of the mark was at the bottom of the buffer, so insert AFTER
         def_line_insert='A';
      } else {
         def_line_insert='B';
      }
      int orig_Noflines;
      if (position_on_last_line) {
         orig_Noflines=p_Noflines;
      }
      get(temp_out);
      if( def_line_insert=='A' ) {
         // Must move down so we are back where we started
         down();
      }
      if (position_on_last_line) {
         down(p_Noflines-orig_Noflines-1);
      }
      vi_begin_text();   // Move down onto the newly inserted text
      def_line_insert=old_line_insert;   // Quick, change it back

      // Now delete the temp files
      status=delete_file(temp_in);
      if ( status ) {
         vi_message('Error deleting temp file: 'temp_in);
         delete_file(temp_out);
         return(status);
      }
      status=delete_file(temp_out);
      if ( status ) {
         vi_message('Error deleting temp file: 'temp_out);
         return(status);
      }
   }
   return status;
}
/**
 * This function executes a command in a shell.
 * Note: If an address is given for this command, then the line(s)
 * specified by the address are replaced with the output from
 * 'params'.  Otherwise, 'params' is run inside a shell.
 * <P>
 * !
 *
 * @return
 */
_str __ex_shell_execute(...)
{
   ss := "";
   line := "";
   prmpt := "";
   typeless params=arg(1);
   typeless a1=arg(2);
   typeless a2=arg(3);
   /* arg(4) not used */
   /* arg(5) not used */
   typeless status=0;
   if ( params=='' ) {
      vi_message("Incomplete shell escape command - use 'shell' to get a shell");
      return(1);
   }

   i := 0;
   status=0;
   // Set up the range of lines to be replaced by the output of the shell
   if ( !isinteger(a1) && !isinteger(a2) ) {
      // Do NOT replace lines in the current buffer with output from the shell
      if( params=='!' ) {
         // User typed !!, so repeat the last :!command
         _cmdline._reset_retrieve();
         line='';
         prmpt=': ';
         ss='@'length(prmpt)prmpt;
         for(;;) {
            params=_cmdline.retrieve_skip('',ss:+line);
            if( params=='' ) break;
            params=substr(params,length(ss)+1);
            i=pos('!',params);
            if( i ) {
               params=substr(params,i+1);
               if( params=='!' ) continue;   // We found another !!
               break;
            }
         }
         if( params=='' ) {
            vi_message("No previous shell command to substitute for '!'");
            return(1);
         }
      }
      // Process for '#' and '%'
      params=ex_process_shellcmd(params);
      if( params=='' ) {
         // An error occurred processing command - no message because
         // ex_process_shellcmd took care of that.
         return(1);
      }
      status=shell('0 'params,'W');
   } else {
      if( _QReadOnly() ) {
         ex_msg_ro();
         return('');
      }
      if( params=='!' ) {
         // User typed <address>!!, so repeat the last :!command and
         // substitute the addressed lines with the result.
         line='';
         prmpt=': ';
         ss='@'length(prmpt)prmpt;
         for(;;) {
            params=_cmdline.retrieve_skip('',ss:+line);
            if( params=='' ) break;
            params=substr(params,length(ss)+1);
            i=pos('!',params);
            if( i ) {
               params=substr(params,i+1);
               if( params=='!' ) continue;   // We found another !!
               break;
            }
         }
         if( params=='' ) {
            vi_message("No previous shell command to substitute for '!'");
            return(1);
         }
      }

      params=ex_process_shellcmd(params);   // Process for '#' and '%'
      if( params=='' ) {
         // An error occurred processing command - no message because
         // ex_process_shellcmd took care of that.
         return(1);
      }

      if ( ! isinteger(a1) ) {
         a1=ex_get_curlineno();
      }
      if ( ! isinteger(a2) ) {
         a2=ex_get_curlineno();
      }
      status=vi_ex_filter(a1,a2,params);
   }

   return(status);
}

/**
 * This function displays evaluated address without changing current line.
 * Note:  If no address is given, then the number of lines is displayed ($).
 * <P>
 * =
 *
 * @return
 */
int __ex_show_address()
{
   typeless params=arg(1);
   typeless a1=arg(2);
   typeless a2=arg(3);
   /* arg(4) not used */
   /* arg(5) not used */
   if ( params!='' ) {
      vi_message('Extra characters');
      return(1);
   }
   if ( ! isinteger(a1) && ! isinteger(a2) ) {
      // Display the number of lines when no address is given
      vi_message(p_Noflines);
   } else {
      typeless l;
      if (select_active()) {
         l = a1;
      } else {
         l = a2;
      }
      if ( ! isinteger(l)) {
         l=ex_get_curlineno();
      }
      // Display the evaluated address
      vi_message(l);
   }

   return(0);
}

/**
 * This function assigns a value to an alias name so that in vi insert-mode,
 * when that alias name is entered, the alias name is automatically replaced
 * with the value assigned.
 *
 * @example
 *   ":abbr rainbow yellow green blue red" maps the alias name "rainbow"
 *   to the value "yellow green blue red".
 * @return
 */
int __ex_abbreviate()
{
   typeless params=arg(1);
   /* arg(2) not used */
   /* arg(3) not used */
   /* arg(4) not used */
   /* arg(5) not used */

   typeless val='';
   alias_name := "";
   parse params with alias_name val;
   typeless status=0;
   if ( alias_name=='' ) {
      match_idx := find_index('alias-match',PROC_TYPE);
      if ( ! match_idx ) {
         vi_message('Procedure not found: alias_match');
         return(1);
      }
      // We pass a match argument to list matches
      //
      // Throw away the result
      list_matches('','alias:'TERMINATE_MATCH,'Aliases');
   } else {
      if ( val=='' ) {
         vi_message('No right hand side');
         return(1);
      }
      status=alias(alias_name' 'val);
   }

   return(status);
}

void __ex_nohlsearch()
{
   clear_highlights();
}

/**
 * This function copies addressed text after a destination line number.
 *
 * @return
 */
int __ex_copy(...)
{
   typeless params=arg(1);
   typeless a1=arg(2);
   typeless a2=arg(3);
   /* arg(4) not used */
   // This is useful if we are inside GLOBAL
   delay_feedback := (arg(5)!='' && arg(5));
   // Non-zero means move the lines, otherwise copy them
   move_lines := (arg(6)!='' && arg(6));

   msg := "";
   start := 1;
   typeless dest=ex_parse_and_eval_address(params,start,msg);
   if ( dest=='' ) {
      vi_message('Copy requires a trailing address');
      return(1);
   }
   // What comes after the destination address
   params=upcase(strip(substr(params,start)));
   if ( params!='' ) {
      // Find the matching command
      params=upcase(ex_match(params,EX_ARG));
      if ( params!='LIST' && params!='PRINT' ) {;
         vi_message('Extra characters');
         return(1);
      }
   }
   if ( ! isinteger(a1) ) {
      a1=ex_get_curlineno();
   }
   if ( ! isinteger(a2) ) {
      a2=ex_get_curlineno();
   }
   typeless mark=_alloc_selection();
   if ( mark<0 ) {
      vi_message(get_message(mark));
      return(mark);
   }
   p_line=a1;
   _select_line(mark,'P');
   p_line=a2;
   _select_line(mark,'P');
   p_line=dest;
   if ( move_lines ) {
      smart_paste(mark,'M');
   } else {
      smart_paste(mark,'C');
   }
   _end_select(mark,true,false);
   
   // Put cursor on first non-blank character
   vi_begin_text();
   // Can free this because it was never shown
   _free_selection(mark);
   typeless status=0;
   if ( (params=='PRINT' || params=='LIST' || __ex_set_autoprint()) ) {
      if ( params=='LIST' ) {
         // List last line showing the end of the line
         status=__ex_print('','','','',delay_feedback,'1');
      } else {
         // Just list the last line
         status=__ex_print('','','','',delay_feedback);
      }
   }

   return(status);
}

/**
 * This function changes the current working directory.
 *
 * @return
 */
int __ex_cd()
{
   dir := "";
   typeless params=arg(1);
   /* arg(2) not used */
   /* arg(3) not used */
   /* arg(4) not used */

   if ( params=='' ) {
      if (_isUnix()) {
         dir=get_env('HOME');
         if ( dir=='' ) {
            vi_message('Environment variable HOME not set');
            return(1);
         }
      } else {
         dir=getcwd();
      }
   } else {
      dir=strip(params);
   }
   if ( isdirectory(dir) ) {
      typeless status=cd(dir);
      if ( status ) {
         vi_message(get_message(status));
         return(status);
      }
   } else {
      vi_message('"'dir'" is not a valid directory');
      return(1);
   }
   vi_message('Current directory is 'getcwd());

   return(0);
}

/**
 * This function deletes the addressed lines.
 *
 * @return
 */
int __ex_delete()
{
   // This can be a count relative to the ending address
   typeless params=strip(arg(1));
   typeless a1=arg(2);
   typeless a2=arg(3);
   /* arg(4) not used */
   typeless in_global=arg(5);

   if ( !isinteger(a1) && !isinteger(a2) ) {
      a1=ex_get_curlineno();
      a2=a1;
   } else {
      if ( !isinteger(a1) ) {
         a1=ex_get_curlineno();
      }
      if ( !isinteger(a2) ) {
         a2=ex_get_curlineno();
      }
   }
   if ( params!='' ) {
      if ( isinteger(params) ) {
         if ( params<=0 ) {
            vi_message('Positive count required');
            return(1);
         } else {
            // Make the beginning address the last address in the command prefix
            a1=a2;
            a2=a1+params-1;
            // Is the count out of range
            if ( a2>p_Noflines ) {
               a2=p_Noflines;
            }
         }
      } else {
         vi_message('Extra characters');
         return(1);
      }
   }
   // Don't want to create system clipboards (too slow) when in __ex_global 
   // command.
   if (isinteger(in_global) && in_global) {
      if (a1==a2) {
         _delete_line();
      } else {
         typeless mark=_alloc_selection();
         if ( mark<0 ) {
            vi_message(get_message(mark));
            return(mark);
         }
         p_line=a1;
         _select_line(mark,'P');
         p_line=a2;
         _select_line(mark,'P');
         _delete_selection();
      }
      return 0;
   }
   typeless mark=_alloc_selection();
   if ( mark<0 ) {
      vi_message(get_message(mark));
      return(mark);
   }
   p_line=a1;
   _select_line(mark,'P');
   p_line=a2;
   _select_line(mark,'P');
   typeless old_mark=_duplicate_selection('');
   _show_selection(mark);

   vi_cut(false,'','1');
   _show_selection(old_mark);

   return(0);
}

/**
 * This function edits a file.
 * <P>
 * <B>Note:</B> '#' expands out to the name of the previous file.
 *
 * @return
 */
int __ex_edit()
{
   if( !p_mdi_child ) {
      ex_msg_editctl();
      return(1);
   }

   typeless params=strip(arg(1),'L');   // This is of the form: [+command] file
   /* arg(2) not used */
   /* arg(3) not used */
   use_variant_form := (arg(4)!='' && arg(4));

   cmd := "";   // Default command
   if ( _SubstrChars(params,1,1)=='+' ) {
      // We might have an ex command
      //
      // Take what is after the '+'
      params=strip(substr(params,2));
      // This is a test to see whether the command appears in between
      // double-quotes (") and is an improvement over the real vi
      // because it allows for spaces in the command.
      if ( _SubstrChars(params,1,1)=='"' ) {
         parse params with '"' cmd '"' params;
      } else {
         parse params with cmd params;
      }
      cmd=strip(cmd);
      params=strip(params);
   }
   typeless oldparams=params;
   // Process for '#' and '%'
   params=ex_process_shellcmd(params);
   if( params=='' && oldparams!='' ) {
      // An error occurred processing command - no message because
      // ex_process_shellcmd took care of that.
      return(1);
   }
   if ( params=='' ) {
      return(__ex_rewind('','','',use_variant_form));
   }
   typeless status=edit(params,EDIT_DEFAULT_FLAGS|EDIT_SMARTOPEN);
   if ( status ) {
      vi_message(get_message(status));
      return(status);
   }
   if ( cmd!='' ) {
      // There was a command to execute on the file opened
      status=ex_parse_and_execute(cmd);
   } else {
      _str msg='"'p_buf_name'" ';
      Noflines := p_Noflines;
      if ( Noflines==1 ) {
         msg :+= Noflines' line';
      } else {
         msg :+= Noflines' lines';
      }
      vi_message(msg);
   }

   return(status);
}

/**
 * By default this handles the ':bufdo' command.
 * 
 * @return int
 */
_command int __ex_bufdo() name_info(','VSARG2_REQUIRES_EDITORCTL) {
   typeless params=strip(arg(1));
   editorctl := p_window_id;
   if (!_isEditorCtl()) {
      editorctl = _mdi.p_child;
   }
   typeless status = editorctl.for_each_buffer("ex_parse_and_execute "params);
   return(status);
}

/**
 * By default this handles 'C-^' pressed.
 *
 * @return
 */
_command int ex_prev_edit () name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   if( !p_mdi_child ) {
      ex_msg_editctl();
      return(1);
   }

   int status=ex_parse_and_execute('e #');

   return(status);
}

/**
 * This function changes the name of the current file OR displays the
 * the current filename if no arguments are given.
 *
 * @return
 */
int __ex_file()
{
   typeless params=arg(1);
   /* arg(2) not used */
   /* arg(3) not used */
   /* arg(4) not used */

   if ( params!='' ) {
      typeless status=name(params);
      if ( status ) {
         return(status);
      }
   }
   _str info='"'p_buf_name'" ';
   if ( p_modify ) {
      info :+= '[Modified] ';
   }
   info :+= 'line 'p_line' of 'p_Noflines;
   vi_message(info);

   return(0);
}

/**
 * This command does a per-line pattern match.
 *
 * @return
 */
int __ex_global(...)
{
   flag_status := 0;
   if ( p_buf_width ) {
      vi_message('GLOBAL not allowed in a binary file');
      return(1);
   } else if ( prev_index()==last_index() ) {
      last_index(0);
      prev_index(0);
      // Some lines might still be flagged - unflag them
      linenum := 0;
      linenum=p_line;
      top();
      for (;;) {
         _begin_line();
         flag_status=ex_find_flagged_line();
         if ( flag_status ) {
            break;
         }
         ex_flag_line('U');
      }
      p_line=linenum;
      vi_message('Global within global not allowed');
      return(1);
   }
   // Save this so we do not recurse
   this_idx := last_index();
   typeless params=arg(1);
   typeless a1=arg(2);
   typeless a2=arg(3);
   if ( !isinteger(a1) && !isinteger(a2) ) {
      a1=1;
      a2=p_Noflines;
   } else {
      if ( !isinteger(a1) ) {
         a1=p_line;
      }
      if ( !isinteger(a2) ) {
         a2=p_line;
      }
   }
   // Set up the step for the loop
   step := 1;
   if ( a1>a2 ) {
      temp:=a1;
      a1=a2;
      a2=temp;
   }
   use_variant_form := (arg(4)!='' && arg(4));

   // Clear the print view id
   _ex_print_view_id='';
   if ( params=='' ) {
      if ( old_search_string:=='' ) {
         vi_message('No previous regular expression');
         return(1);
      }
   }
   delim := "";
   search_string := "";
   cmd := "";
   parse arg(1) with  1 delim +1 search_string (delim) cmd;
   if ( search_string:!='' ) {
      old_search_string=search_string;
   }
   typeless search_flags=_vi_search_type():+'m(':+_search_case();

   // What action does GLOBAL take for matches?
   start := 1;
   typeless action=0;
   ex_parse_command(cmd,start,action);
   if (cmd=='' && action=='') {
      action='PRINT';
      cmd=' print';
   } else {
      action=ex_match(action,'1');
      ex_match('','2');   // Reset
   }

   // Check for special case of action being a simple SUBSTITUTE
   nofskipped := 0;
   typeless status=0;
   string := "";
   msg := "";
   if( !use_variant_form ) {
      // Have g/...
      if( action=="SUBSTITUTE" ) {
         // Have g/find-me/s...
         params=substr(cmd,start);
         parse params with 1 delim +1 string (delim) .;
         if( string=="" ) {
            // Have "g/find-me/s"
            // Convert to "s"  old_search_string is set to find-me and old_replace_string will be used.
            _SearchInitSkipped(0);
            status=ex_parse_and_execute(a1','a2:+cmd);
            nofskipped=_SearchQNofSkipped();
            if( nofskipped ) {
               msg="The following lines were skipped to prevent line truncation:\n\n"_SearchQSkipped();
               _message_box(msg,"",MB_OK|MB_ICONINFORMATION);
            }
            return(status);
         }
      }
   }

   // Now create the mark we use for verifying each line
   typeless old_mark=_duplicate_selection('');
   typeless mark=_alloc_selection();
   if ( mark<0 ) {
      vi_message(get_message(mark));
      return(mark);
   }
   _show_selection(mark);

   // Save this in case the command called for each match mucks with it
   _str save_search_string=old_search_string;
   // GLOBAL sets the previous context
   vi_set_prev_context();
   first_line_found := 0;
   last_line := 0;
   search_status := 0;

   // First pass - mark all the lines that match
   
   p_line=a1;
   _select_line(mark,'P');
   p_line=a2;
   _select_line(mark,'P');
   _begin_select(mark);
   
   if (use_variant_form) {
      _lineflags(VIMARK_LF,VIMARK_LF,mark);
   }
   for (;;) {
      // Note: There's a good reason for NOT calling repeat-search
      // here - we start a new search on each iteration.
      search_status=search(old_search_string,search_flags);
      // This is ~XOR
      if (!search_status) {
         last_line=p_line;
         if ( !first_line_found ) {
            first_line_found=last_line;
         }
         if (use_variant_form) {
            _lineflags(0,VIMARK_LF);
         } else {
            _lineflags(VIMARK_LF);
         }
      }
      if (search_status) break;
      if (down()) break;
      _begin_line();
   }
   if (use_variant_form) {
      first_line_found=a1;
      last_line=a2;
   }

   // Set this so we do not recurse
   prev_index(this_idx);

   // total_nofskipped will be >0 if we attempt to SUBSTITUTE outside
   // bounds of p_TruncateLength.
   total_nofskipped := 0;
   typeless total_skipped="";
   typeless mark_status='';
   save_line := 0;
   finish_linenum := -1;

   // Second pass - for each marked occurrence, execute the action
   if ( first_line_found ) {
      // Note: this mark is already showing
      _deselect(mark);
      p_line=last_line;
      _select_line(mark,'P');
      p_line=first_line_found;
      _select_line(mark,'P');
      // Need to bookmark next line we need to process
      next_line_markid:=_alloc_selection('B');
      status=0;
      NofSamples := 0L;
      have_rel_data := true; 
      idx := 0;
      if (action=='SUBSTITUTE') {
         idx=find_index('__ex_substitute',PROC_TYPE|COMMAND_TYPE);
      }
      int rel_begin_addr=(typeless)'';
      int rel_end_addr=(typeless)'';
      int begin_addr,end_addr;
      bool variant_form_used;
      for (;;) {
         if (_select_type(mark)=='') {
            // Last line of selection was deleted.
            break;
         }
         // Start searching from last bookmark
         _begin_select(next_line_markid);
         linenum := p_line;
         done := false;
         for(;;) {
            if (_end_select_compare(mark)>0) {
               p_line=linenum;
               done=true;
               break;
            }
            int flags=_lineflags();
            if( flags&VIMARK_LF ) {
               break;
            }
            if( down() ) {
               p_line=linenum;
               done=true;
               break;
            }
         }
         if (done) break;
         // Unflag the line
         _lineflags(0,VIMARK_LF);
         if (down()) {
            _deselect(mark);
         } else {
            // Bookmark next line we need to start searching from
            _deselect(next_line_markid);_select_line(next_line_markid);up();
         }
         if (NofSamples>=2 && have_rel_data) {
            last_index(idx);
            if (rel_begin_addr!='') {
               begin_addr=p_line+rel_begin_addr;
            }
            if (rel_end_addr!='') {
               end_addr=p_line+rel_end_addr;
            }
            if( action=="SUBSTITUTE" ) {
               _SearchInitSkipped(0);
               status=call_index(params,begin_addr,end_addr,use_variant_form,true,idx);
               total_nofskipped+=_SearchQNofSkipped();
               total_skipped=strip(total_skipped):+" ":+_SearchQSkipped();
            } else {
               status=call_index(params,begin_addr,end_addr,use_variant_form,true,idx);
            }
         } else {
            ++NofSamples;
            int idx2;
            _str params2;
            int begin_addr2,end_addr2;
            bool variant_form_used2;
            // Now execute the command on this occurrence
            orig_linenum:=p_line;
            if( action=="SUBSTITUTE" ) {
               // Count the lines that were skipped because p_TruncateLength was set
               _SearchInitSkipped(0);
               // The second argument tells any command being executed that
               // it is inside GLOBAL and to delay any listing of lines.
               status=ex_parse_and_execute(cmd,true,idx2,params2,begin_addr2,end_addr2,variant_form_used2);
               total_nofskipped+=_SearchQNofSkipped();
               total_skipped=strip(total_skipped):+" ":+_SearchQSkipped();
            } else {
               // The second argument tells any command being executed that it
               // is inside GLOBAL and to delay any listing of lines.
               status=ex_parse_and_execute(cmd,true,idx,params2,begin_addr2,end_addr2,variant_form_used2);
            }
            if (NofSamples<=2) {
               if (NofSamples<=1) {
                    params=params2;begin_addr=begin_addr2;end_addr=end_addr2;variant_form_used=variant_form_used2;
                    if (isinteger(begin_addr)) {
                       rel_begin_addr=begin_addr-orig_linenum;
                    }
                    if (isinteger(end_addr)) {
                       rel_end_addr=end_addr-orig_linenum;
                    }
               } else if(have_rel_data) {
                  if (rel_begin_addr!='') {
                     if (isinteger(begin_addr2)) {
                        rel_begin_addr2:=begin_addr2-orig_linenum;
                        if (rel_begin_addr2!=rel_begin_addr) {
                           have_rel_data=false;
                        }
                     } else {
                        have_rel_data=false;
                     }
                  } else {
                     if (begin_addr2!='') {
                        have_rel_data=false;
                     }
                  }
                  if (rel_end_addr!='') {
                     if (isinteger(end_addr2)) {
                        rel_end_addr2:=end_addr2-orig_linenum;
                        if (rel_end_addr2!=rel_end_addr) {
                           have_rel_data=false;
                        }
                     } else {
                        have_rel_data=false;
                     }
                  } else {
                     if (end_addr2!='') {
                        have_rel_data=false;
                     }
                  }
               }
            } 
         }

         // This is here just in case the command called
         // changed 'old_search_string'.
         old_search_string=save_search_string;

         if ( status ) {
            // Some lines might still be flagged - unflag them
            if (_select_type(mark)!='') {
               _lineflags(0,VIMARK_LF,mark);
            }
            break;
         }
         finish_linenum=p_line;
      }
      _free_selection(next_line_markid);
   }
   _show_selection(old_mark);
   _free_selection(mark);
   // Were there any matches?
   if ( finish_linenum>=0 ) {
      p_line=finish_linenum;
      // Put cursor at beginning of text
      vi_begin_text();
   } else {
      // This will force the message "String not found" if no lines match
      status=search_status;
   }

   if( total_nofskipped ) {
      msg="The following lines were skipped to prevent line truncation:\n\n"total_skipped;
      _message_box(msg,"",MB_OK|MB_ICONINFORMATION);
   }

   // Do not clear a serious error message ("String not found" does not count)
   if ( !status ) {
      clear_message();
      if ( isinteger(_ex_print_view_id) ) {
         // The eighth argument tells __ex_print to use the view id
         // '_ex_print_view_id' as the buffer for selection-list
         // instead of creating a new one.
         status=__ex_print('',1,p_Noflines,'','','','','1');
      }
   }

   return(status);
}

/**
 * This function performs a join of 2 or more lines.
 *
 * @return
 */
typeless __ex_join()
{
   typeless params=strip(arg(1));
   typeless a1=arg(2);
   typeless a2=arg(3);
   /* arg(4) not used */
   /* arg(5) not used */

   if ( !isinteger(a1) ) {
      a1=ex_get_curlineno();
   }
   if ( !isinteger(a2) ) {
      a2=ex_get_curlineno();
   }
   int count;
   if ( params!='' ) {
      if ( isinteger(params) ) {
         if ( params<1 ) {
            vi_message('join requires a positive count');
            return(1);
         } else {
            count=(int)params-1;
         }
      } else {
         vi_message('Extra characters');
         return(1);
      }
   } else {
      count=a2-a1+1;
      a2=a1;
   }
   int idx;
   idx=find_index('vi_visual_join',COMMAND_TYPE);
   if ( ! idx ) {
      vi_message('Can''t find command: vi-visual-join');
      return(1);
   }
   return(call_index(count,a2,idx));
}

/**
 * This function creates a mark at the current buffer location.
 *
 * @return
 */
int __ex_k()
{
   typeless params=strip(arg(1));   // This should be a single character mark-name
   if ( params=='' ) {
      vi_message('k requires following letter');
      return(1);
   } else {
      // '' when in command mode goes to next book mark which is convenient
      // but is different then gvim.
      if ( ! isalpha(params) /*&& params!="'" && params!="`"*/) {
         vi_message('Extra characters');
         return(1);
      }
   }
   /* arg(2) not used */
   typeless a2=arg(3);   // We are only interested in the ending address
   /* arg(4) not used */

   if ( !isinteger(a2) ) {
      a2=ex_get_curlineno();
   }
   p_line=a2;
   save_pos(auto p);
   vi_begin_text();
   int status=set_bookmark('-r 'params);
   restore_pos(p);

   return(status);
}

/**
 * This function lists a range of lines specified by the address given.
 * The only difference between this command and 'print' is that this
 * command marks the end of each line in the list with a '$'.
 *
 * @return
 */
int __ex_list()
{
   return(__ex_print(arg(1),arg(2),arg(3),arg(4),arg(5),'1'));   // Pass a '1' as the sixth argument to mark end of lines
}

/**
 * This function moves addressed text after a destination line number.
 *
 * @return
 */
int __ex_move()
{
   return(__ex_copy(arg(1),arg(2),arg(3),arg(4),arg(5),'1'));   // Pass a '1' as the sixth parameter to move instead of copy
}

/**
 * This function switches to the next buffer in the buffer list.
 *
 * @return
 */
int __ex_next()
{
   if( !p_mdi_child ) {
      ex_msg_editctl();
      return(1);
   }

   _str params=strip(arg(1));   // This is of the form:  [+command] [filelist]
   /* arg(2) not used */
   /* arg(3) not used */
   use_variant_form := (arg(4)!='' && arg(4));

   cmd := "";
   if ( _SubstrChars(params,1,1)=='+' ) {
      // We might have an ex command
      //
      // Take what is after the '+'
      params=strip(substr(params,2));
      /* This is a test to see whether the command appears in between
       * double-quotes (") and is an improvement over the real vi
       * because it allows for spaces in the command
       */
      if ( _SubstrChars(params,1,1)=='"' ) {
         parse params with '"' cmd '"' params;
      } else {
         parse params with cmd params;
      }
      cmd=strip(cmd);
      params=strip(params);
   }
   typeless buf_info='';
   typeless buf_id=0;
   typeless ModifyFlags=0;
   typeless buf_flags=0;
   typeless buf_name='';
   typeless select=0;
   typeless status=0;
   if ( params=='' ) {
      next_doc();
   } else {   // User gave a new file list to replace the current list
      buffers_modified := 0;
      buf_info=buf_match('',1,'V');
      for (;;) {
         if ( rc ) break;
         parse buf_info with buf_id ModifyFlags buf_flags buf_name;
         if ( (ModifyFlags &1) && ! (buf_flags&VSBUFFLAG_THROW_AWAY_CHANGES) ) {
            buffers_modified++;
         }
         buf_info=buf_match('',0,'V');
      }
      if ( buffers_modified && ! use_variant_form ) {
         select=nls_letter_prompt(nls('Replace file list with 'buffers_modified' buffers modified (~Y/~N/~W)?'));
         if ( select:==3 ) {
            status=save_all();
            if ( status ) {
               return(status);
            }
            select=1;
         }
         clear_message();
         if ( select!=1 ) {
            return(COMMAND_CANCELLED_RC);
         }
      }
      if ( _process_info() ) {   // Is a process running?
         if ( def_exit_process ) {
            exit_process();
         } else {
            vi_message('Please exit build window');
            return(1);
         }
      }

      // Now delete all the buffers to make way for the new file list
      //
      // close_buffer() works independent of "One-file-per-window" mode
      while (!close_buffer(false));
      // Now load the new file list AND force the first file in the list to be the first displayed
      old_start_on_first := def_start_on_first;
      def_start_on_first=true;
      status=edit(params);
      def_start_on_first=old_start_on_first;   // QUICK - change it back
      if ( status ) {
         vi_message('Error loading new file list.  'get_message(status));
         return(status);
      }
   }
   if ( cmd!='' ) {
      status=ex_parse_and_execute(cmd);
      if ( status ) {
         return(status);
      }
   }

   return(0);
}

/**
 * This function lists the addressed lines with preceding line numbers.
 *
 * @return
 */
int __ex_number()
{
   return(__ex_print(arg(1),arg(2),arg(3),arg(4),arg(5),'','1'));   // The seventh argument tells __ex_print to number the lines of the list
}

/**
 * This function prints a range of lines specified by the address given.
 *
 * @return
 */
int __ex_print(...)
{
   // This is a count of the lines to list
   typeless params=strip(arg(1));
   typeless a1=arg(2);
   typeless a2=arg(3);
   // arg(4); not used
   delay_feedback := (arg(5)!='' && arg(5));
   typeless show_tabs=__ex_set_list();
   show_end_of_lines := ((arg(6)!='' && arg(6)) || (isinteger(show_tabs) && show_tabs>=1 && show_tabs<=2));
   number_lines := (arg(7)!='' && arg(7));
   use_ex_print_view_id := (arg(8)!='' && arg(8));   // Use the view id '_ex_print_view_id'?

   // Allocate a mark
   typeless junk='';
   typeless mark=_alloc_selection();
   if ( mark<0 ) {
      vi_message(get_message(mark));
      return(mark);
   }

   typeless utf8='';
   typeless temp_view_id=0;
   typeless orig_view_id=0;
   line_number_width := 0;
   count := 0;
   if( !use_ex_print_view_id ) {
      orig_view_id=p_window_id;
      if ( ! isinteger(a1) && ! isinteger(a2) ) {
         a1=ex_get_curlineno();
         a2=a1;
      } else {
         if ( ! isinteger(a1) ) {
            a1=ex_get_curlineno();
         }
         if ( ! isinteger(a2) ) {
            a2=ex_get_curlineno();
         }
      }
      if ( params!='' ) {
         if ( isinteger(params) ) {
            if ( params<=0 ) {
               vi_message('Positive count required');
               return(1);
            } else {
               // Make the beginning address the last address in the command prefix
               a1=a2;
               a2=a1+params-1;
               if ( a2>p_Noflines ) {   // Is the count out of range
                  a2=p_Noflines;
               }
            }
         } else {
            vi_message('Extra characters');
            return(1);
         }
      }
      // Now mark the lines to list
      p_line=a1;
      _select_line(mark,'P');
      p_line=a2;
      _select_line(mark,'P');
      // Create the view for selection-list
      if( delay_feedback ) {
         // Put marked lines into view specified by '_ex_print_view_id'
         if( !isinteger(_ex_print_view_id) ) {
            // Create one
            if( _create_temp_view(temp_view_id)=='' ) {
               _free_selection(mark);
               vi_message('Unable to load temporary list.');
               return(1);
            }
            _ex_print_view_id=temp_view_id;
            // Show tabs and end of lines?
            if( show_end_of_lines ) {
               p_ShowSpecialChars|=SHOWSPECIALCHARS_TABS;
            }
            _delete_line();
         } else {
            p_window_id= (int)_ex_print_view_id;
            temp_view_id=_ex_print_view_id;
         }
      } else {
         if( _create_temp_view(temp_view_id)=='' ) {
            _free_selection(mark);
            vi_message('Unable to load temporary list.');
            return(1);
         }
         _delete_line();
         // Show tabs and end of lines?
         if( show_end_of_lines ) {
            p_ShowSpecialChars|=SHOWSPECIALCHARS_TABS;
         }
      }
      bottom();
      _get_selinfo(junk,junk,junk,mark,junk,utf8);
      p_UTF8=utf8;
      _copy_to_cursor(mark);
      if( show_end_of_lines || number_lines ) {
         if( number_lines ) {
            line_number_width=length(p_Noflines)+1;
         }
         // We do this instead of top() because we could be inserting into
         // this buffer more than once.
         _begin_select(mark);
         count=a1-1; 
         for(;;) {
            ++count;
            if ( number_lines ) {
               _begin_line();
               _insert_text(field(count,line_number_width));
            }
            if ( show_end_of_lines ) {
               _end_line();
               _insert_text('$');   // Put a '$' to mark the end of the line
            }
            if( down() ) break;
         }
      }
      _shift_selection_right(mark);
      // Can free this because it was never shown
      _free_selection(mark);
      if ( delay_feedback ) {
         // Go back to original view
         p_window_id=orig_view_id;
         return(0);
      }
   }
   if( use_ex_print_view_id ) {
      show("-modal _sellist_form","Hit return to continue",SL_VIEWID,_ex_print_view_id);
   } else {
      p_window_id=orig_view_id;
      show("-modal _sellist_form","Hit return to continue",SL_VIEWID,temp_view_id);
   }
   if ( use_ex_print_view_id ) {
      _ex_print_view_id='';   // MUST CLEAR THIS!
   }

   return(0);
}

/**
 * This function pastes line(s) from the clipboard.
 *
 * @return
 */
typeless __ex_put()
{
   deselect();
   typeless params=strip(arg(1));
   _str cb_name=params;
   _str text_to_paste=null;
   if (substr(params,1,1)=='=') {
      cb_name='';
      /*
          :put = (1 + 2) *4
          :put = \" some text \":
          Vim is a bit annoying the way it requires escapes.
            :put = \" so\\me \\"text \":

          Lets be more lenient with escapes in the middle. If get 
          complaints, we can make this more annoyting just like Vim.
      */
      params=strip(substr(params,2));
      if (substr(params,1,1)=='"') {
         params=substr(params,2);
         if (_last_char(params)=='"') {
            params=substr(params,1,length(params)-1);
         } else {
            vi_message('Invalid string. ex. :put ="text" or :put =\"text\"');
            return(1);
         }
      } else if (substr(params,1,2)=='\"') {
         params=substr(params,3);
         if (length(params)>=2 && substr(params,length(params)-1,2)=='\"') {
            params=substr(params,1,length(params)-2);
         } else {
            vi_message('Invalid string. ex. :put ="text" or :put =\"text\"');
            return(1);
         }
      } else {
         typeless result=0;
         typeless status=eval_exp(result,params,10);
         if (status!=0) {
            if (isinteger(status)) {
               message(get_message(status));
            } else {
               message(status);
            }
            return(1);
         }
         params=result;
      }
      text_to_paste=params;
   } else if (params=='_') {
      cb_name='';
      text_to_paste='';
   }
   /* arg(2) not used */
   typeless a2=arg(3);   // We are only interested in the last address
   /* arg(4) not used */
   /* arg(5) not used */
   if ( !isinteger(a2) ) {
      a2=ex_get_curlineno();
   }
   idx := find_index('vi-put-after-cursor',COMMAND_TYPE);
   if ( !idx ) {
      vi_message('Can''t find command: vi-put-after-cursor');
      return(1);
   }
   p_line=a2;
   count := 1;

   // Set the last index so that vi_repeat_info() knows to record the
   // clipboard name.
   last_index(idx);

   return(call_index(count,cb_name,true,text_to_paste,idx));
}

// 'A'  = quit All buffers on ':q!'
// 'AX' = quit All buffers and eXit on ':q!'
_str def_vi_quit_options='';


/**
 * This function quits all buffers.
 * 
 * @return 
 */
int __ex_qall(...){

   int i, status, num_bufs;

   typeless params=strip(arg(1));
   use_variant_form := (arg(4)!='' && arg(4));

   num_bufs = _Nofbuffers();

   // Doing it this way to make use of existing error checking, and because
   // close_all() always prompts for a save, which sometimes we don't want
   for (i = 0; i < num_bufs; i++) {
      status = __ex_quit(params, arg(2), arg(3), use_variant_form);
   }

   return(status);
}

/**
 * This function splits the current window horizontally and loads 
 * the specified file (if any) into a buffer.  If the specified file 
 * does not exist it is created.
 * 
 * <p>Same as :split ex command
 * 
 * @return 
 */
int __ex_buffer(...){
   if (arg(1)=='') {
      return 0;
   }
   int status;
   if (isinteger(arg(1))) {
      status=edit('+bi 'arg(1));
   } else {
      orig_def_edit_flags := def_edit_flags;
      def_edit_flags=EDITFLAG_BUFFERS;
      status=edit(arg(1),EDIT_SMARTOPEN);
      def_edit_flags=orig_def_edit_flags;
      if (status==NEW_FILE_RC) {
         quit();
      }
   }
   if (status) {
      message(nls("buffer %s does not exist",arg(1)));
   }
   return status;
}

static int do_vi_split(_str filename,bool split_horz=true, bool allow_buffer_id=false) {
   if (filename=='') {
      if (split_horz) {
         hsplit_window();
      } else {
         vsplit_window();
      }
      return 0;
   }
   if (allow_buffer_id) {
      if (isinteger(filename) && filename>0) {
         // Test if this buffer id is valid
         status:=_open_temp_view('',auto temp_wid,auto orig_wid,'+bi 'filename);
         if (status) {
            vi_message('Invalid buffer id');
            return status;
         }
         _delete_temp_view(temp_wid);
         activate_window(orig_wid);

         if (split_horz) {
            hsplit_window();
         } else {
            vsplit_window();
         }
         status=edit('-w +bi 'filename);
         return status;
      }
   }
   if(file_exists(arg(1))){
      if (split_horz) {
         hsplit_window();
      } else {
         vsplit_window();
      }
      status:=edit('-w '_maybe_quote_filename(arg(1)));
      _SetEditorLanguage();
      return status;
   }
   if (split_horz) {
      hsplit_window();
   } else {
      vsplit_window();
   }
   edit('-w +t ':+_maybe_quote_filename(arg(1)));
   _SetEditorLanguage();
   return 0;
}

/**
 * This function splits the current window horizontally and loads 
 * the specified file (if any) into a buffer.  If the specified file 
 * does not exist it is created.
 * 
 * <p>Same as :split ex command
 * 
 * @return 
 */
int __ex_sbuffer(...){
   return do_vi_split(arg(1),true,true);
}


/**
 * This function splits the current window horizontally and loads 
 * the specified file (if any) into a buffer.  If the specified file 
 * does not exist it is created.
 * 
 * @return 
 */
int __ex_split(...){
   do_vi_split(arg(1));
   return(0);
}

/**
 * This function splits the current window vertically and loads 
 * the specified file (if any) into a buffer.  If the specified file
 * does not exist it is created.
 * 
 * @return 
 */
int __ex_vsplit(...){
   do_vi_split(arg(1),false);
   return(0);
}

/**
 * This function switches to the next buffer/window
 *
 * @return
 */
int __ex_bnext(...)
{
   if( !p_mdi_child ) {
      ex_msg_editctl();
      return(1);
   }
   _str params=arg(1);
   if ( params!='' ) {
      vi_message('Extra characters');
      return(1);
   }
   if (def_one_file=='') {
      next_buffer();
   } else if(def_vi_bnext=='w'){
      next_window();
   } else if(def_vi_bnext=='t'){
      next_buff_tab();
   } else {
      // 'b'
      next_buffer();
   }
   return(0);
}
/**
 * This function switches to the previous buffer/window
 *
 * @return
 */
int __ex_bprevious(...)
{
   if( !p_mdi_child ) {
      ex_msg_editctl();
      return(1);
   }
   _str params=arg(1);
   if ( params!='' ) {
      vi_message('Extra characters');
      return(1);
   }
   if (def_one_file=='') {
      prev_buffer();
   } else if(def_vi_bnext=='w'){
      prev_window();
   } else if(def_vi_bnext=='t'){
      prev_buff_tab();
   } else {
      // 'b'
      prev_buffer();
   }
   return(0);
}
/**
 * This function list buffers
 *
 * @return
 */
int __ex_buffers(...)
{
   if( !p_mdi_child ) {
      ex_msg_editctl();
      return(1);
   }
   _str params=arg(1);
   if ( params!='' ) {
      vi_message('Extra characters');
      return(1);
   }
   list_buffers();
   return(0);
}
/**
 * This function list buffers
 *
 * @return
 */
int __ex_registers(...)
{
   if( !p_mdi_child ) {
      ex_msg_editctl();
      return(1);
   }
   _str params=arg(1);
   if ( params!='' ) {
      vi_message('Extra characters');
      return(1);
   }
   list_clipboards();
   return(0);
}
/**
 * This function quits the current buffer.
 *
 * @return
 */
int __ex_bdelete(...)
{
   if( !p_mdi_child ) {
      ex_msg_editctl();
      return(1);
   }
   _str params=arg(1);
   if ( params!='' ) {
      vi_message('Extra characters');
      return(1);
   }
   quit();
   return(0);
}
/**
 * This function quits the current buffer.
 *
 * @return
 */
int __ex_redo(...)
{
   _str params=arg(1);
   if ( params!='' ) {
      vi_message('Extra characters');
      return(1);
   }
   vi_redo();

   return(0);
}

/**
 * This function quits the current buffer.
 *
 * @return
 */
int __ex_normal(...)
{
   if( !p_mdi_child ) {
      ex_msg_editctl();
      return(1);
   }

   _str params=arg(1);
   if ( params=='' ) {
      vi_message('Argument required');
      return(1);
   }
   params=strip(params);
   if (substr(params,1,1)=="''" && _last_char(params)=="''") {
      _macro('KP',1,params);
   } else {
      _macro('KP',1,"'-"stranslate(params,"''","'")"'");
   }

   return(0);
}

/**
 * This function quits the current buffer.
 *
 * @return
 */
int __ex_close(...)
{
   if( !p_mdi_child ) {
      ex_msg_editctl();
      return(1);
   }

   _str params=arg(1);
   if ( params!='' ) {
      vi_message('Extra characters');
      return(1);
   }
   quit();

   return(0);
}

/**
 * This function quits the current buffer.
 *
 * @return
 */
int __ex_quit(...)
{
   if( !p_mdi_child ) {
      ex_msg_editctl();
      return(1);
   }

   _str params=arg(1);
   if ( params!='' ) {
      vi_message('Extra characters');
      return(1);
   }
   /* arg(2) not used */
   /* arg(3) not used */
   use_variant_form := (arg(4)!='' && arg(4));
   typeless status=0;

   if ( use_variant_form ) {
      if( pos('A',upcase(def_vi_quit_options)) ) {

         // Save the state of the editor
         status=save_window_config();
         if ( status ) {
            vi_message(get_message(status));
            return(status);
         }

         // Quit all the buffers
         while(1) {
            // Fake out close_buffer by turning the p_modify flag off
            p_modify=false;
            status=close_buffer(false);
            if( status ) break;
         }

         if( pos('X',upcase(def_vi_quit_options)) ) {   // Exit the editor?
            // Now setup to exit the editor
            status=save_all_forms(0);
            if (status) {
               return(status);
            }
            p_window_id=_mdi.p_child;
            if ( _process_info() ) {  // is a process running?
               if ( def_exit_process ) {
                  exit_process();
               } else {
                  vi_message(nls('Please exit build window.'));
                  return(1);
               }
            }
            exit_list();
            exit(0);   // Blow out of the editor
         }
      } else {
         // Fake out 'quit' by turning the p_modify flag off
         p_modify=false;
      }
   }
   if (def_one_file=='' && _HaveMoreThanOneWindow()) {
      close_window();
   } else {
      quit();
   }
   return(0);
}

/**
 * This function reads in a file.
 * Can handle filenames with spaces if enclosed in double-quotes ("").
 *
 * @return
 */
int __ex_read()
{
   buf_name := "";
   typeless params=strip(arg(1));   // This is of the form: [file]|[!command]
   if ( params=='' ) {
      // No filename means use the current filename
      buf_name=p_buf_name;
      if ( buf_name=='' || buf_name=='*' ) {
         vi_message('No file name');
         return(1);
      }
      params=buf_name;
   }
   /* arg(2) not used - only concerned with last address */
   typeless a2=arg(3);
   /* arg(4) not used */
   if ( ! isinteger(a2) ) {
      a2=ex_get_curlineno();
   }
   temp_name := "";
   filename := "";
   typeless status=0;
   // Set the current line
   p_line=a2;
   // Get the current number of lines for comparison after the operation
   old_Noflines := p_Noflines;
   // Check for a shell command or filename
   if ( _SubstrChars(params,1,1)=='!' ) {
      // Shell command
      params=substr(params,2);
      if ( params=='' ) {
         vi_message("Incomplete shell escape command - use 'shell' to get a shell");
         return(1);
      }
      // We are using __ex_shell_execute to read the output from the shell
      // command.  Because __ex_shell_execute replaces addressed lines and
      // inserts the output BEFORE the current line, we must insert a blank
      // line after the current line so that it will be replaced by the
      // shell output.
      insert_line('');
      a2=ex_get_curlineno();
      params=ex_process_shellcmd(params);   // Process for '#' and '%'
      if( params=='' ) {
         // An error occurred processing command - no message because
         // ex_process_shellcmd took care of that.
         return(1);
      }
      status=vi_ex_filter(a2,a2,params,true);
      if ( status ) {
         return(status);
      }
   } else {
      // Filename
      filename=parse_file(params);
      if ( params!='' ) {
         vi_message('Too many file names');
         return(1);
      }
      filename=file_match(filename' -P',1);
      if ( filename=='' ) {
         vi_message('No such file or directory');
         return(1);
      }
      typeless old_line_insert=def_line_insert;
      def_line_insert='A';
      // Now check if we are inserting the current buffer into itself.
      // We have to check this because 'get' won't work if this is the
      // case.
      buf_name=p_buf_name;
      if ( buf_name==filename ) {
         temp_name=mktemp();
         p_buf_name=temp_name;
      }
      status=get(filename);
      def_line_insert=old_line_insert;   // QUICK change it back
      if ( buf_name==filename ) {
         p_buf_name=buf_name;
      }
      if ( status ) {
         vi_message(get_message(status));
         return(status);
      }
      down();
      vi_begin_text();   // Move down onto the newly inserted text
   }
   vi_message('"'p_buf_name'" '(p_Noflines-old_Noflines)' lines');

   return(0);
}

/**
 * This function undoes all changes you have made to the current buffer.
 * <P>
 * <B>Note:</B> Unlike the real vi, we deal with multiple buffers, and so it is
 * almost meaningless for this command to rewind to the first buffer in
 * the list since we keep a looped list of buffers
 *
 * @return
 */
int __ex_rewind(...)
{
   if( !p_mdi_child ) {
      ex_msg_editctl();
      return(1);
   }
   typeless params=arg(1);   // This should be ''
   if ( params!='' ) {
      vi_message('Extra characters');
      return(1);
   }
   /* arg(2) not used */
   /* arg(3) not used */
   use_variant_form := (arg(4)!='' && arg(4));
   revert(use_variant_form);

   return(0);
}


definit()
{
   _ex_print_view_id='';

#if 0
   if ( __ex_set_autoindent()=='' ) {
      __ex_set_autoindent(AUTOINDENT_DEFAULT);
   }
#endif
   if ( __ex_set_autoprint()=='' ) {
      __ex_set_autoprint(VI_DEFAULT_AUTOPRINT);
   }
   if ( __ex_set_incsearch()=='' ) {
      __ex_set_incsearch(VI_DEFAULT_INCSEARCH);
   }
   if ( __ex_set_hlsearch()=='' ) {
      __ex_set_hlsearch(VI_DEFAULT_HLSEARCH);
   }
#if 0
   // Not supported
   if ( __ex_set_edcompatible()=='' ) {
      __ex_set_edcompatible(EDCOMPATIBLE_DEFAULT);
   }
#endif
   if ( __ex_set_errorbells()=='' ) {
      __ex_set_errorbells(VI_DEFAULT_ERRORBELLS);
   }
   if ( __ex_set_ignorecase()=='' ) {
      // Don't change the current global setting.
      // This messes up building the state file.
      if (_default_option('S')&IGNORECASE_SEARCH) {
         __ex_set_ignorecase(1);
      } else {
         __ex_set_ignorecase(0);
      }
   }
   if ( __ex_set_list()=='' ) {
      __ex_set_list(VI_DEFAULT_LIST);
   }
   if ( __ex_set_listchars()=='' ) {
      __ex_set_listchars(_default_option('Q'));
   }
#if 0
   if ( __ex_set_number()=='' ) {
      __ex_set_list(NUMBER_DEFAULT);
   }
#endif
   if ( __ex_set_paragraphs()=='' ) {
      __ex_set_paragraphs(VI_DEFAULT_PARAGRAPHS);
   }
   if ( __ex_set_prompt()=='' ) {
      __ex_set_prompt(VI_DEFAULT_PROMPT);
   }
   /*if ( __ex_set_readonly()=='' ) {
      __ex_set_readonly(READONLY_DEFAULT);
   }*/
   if ( __ex_set_report()=='' ) {
      __ex_set_report(VI_DEFAULT_REPORT);
   }
   // No point in setting scroll amount now. Let vi_scroll()
   // do it as needed.
   //if ( __ex_set_scroll()=='' ) {
   //   __ex_set_scroll(SCROLL_DEFAULT);
   //}
   if ( __ex_set_sections()=='' ) {
      __ex_set_sections(VI_DEFAULT_SECTIONS);
   }
   if ( __ex_set_shell()=='' ) {
      __ex_set_shell('');   // This must be set according to the OS
   }
   if ( __ex_set_shiftwidth()=='' ) {
      __ex_set_shiftwidth(VI_DEFAULT_SHIFTWIDTH);
   }
   if ( __ex_set_showmatch()=='' ) {
      __ex_set_showmatch(VI_DEFAULT_SHOWMATCH);
   }
   if ( __ex_set_showmode()=='' ) {
      __ex_set_showmode(VI_DEFAULT_SHOWMODE);
   }
#if 0
   // Not supported
   if ( __ex_set_tabstop()=='' ) {
      __ex_set_tabstop(TABSTOP_DEFAULT);
   }
#endif
#if 0
   // Not supported
   if ( __ex_set_tags()=='' ) {
      __ex_set_tags(TAGS_DEFAULT);
   }
#endif
#if 0
   // Not supported
   if ( __ex_set_wrapmargin()=='' ) {
      __ex_set_wrapmargin(WRAPMARGIN_DEFAULT);
   }
#endif
   if ( __ex_set_wrapscan()=='' ) {
      __ex_set_wrapscan(VI_DEFAULT_WRAPSCAN);
   }
   if ( __ex_set_writeany()=='' ) {
      __ex_set_writeany(VI_DEFAULT_WRITEANY);
   }

   rc=0;
}
static typeless __ex_set_option(typeless idx,...)
{
   info := "";
   val := strip(arg(2));
   if ( isinteger(idx) && idx ) {
      if ( val!='' ) {
         if( val=="''" || val=='""' ) {
            val='';
         }
         _set_var(idx,val);
         typeless status=rc;
         if ( status ) {
            clear_message();
            info='';
         } else {
            info=val;
            _config_modify_flags(CFGMODIFY_DEFVAR);
         }
      } else {
         // Return the current value
         info=_get_var(idx);
      }
   } else {
      info='';
   }

   return(info);
}


#if 1
typeless __ex_set_autoindent()
{
   def_vi_or_ex_autoindent=def_vi_or_ex_autoindent;
   if( _no_child_windows() ) return(0);

   typeless val=strip(arg(1));
   if( val=='' ) {
      // Return the current value
      val=(p_indent_style!=INDENT_NONE);
   } else {
      if( !isinteger(val) || !(val>=0 && val<=2) ) {
         vi_message('AUTOINDENT requires a value between 0 and 2');
         val='';
      } else {
         p_indent_style=val;
      }
   }

   //return(val);
   return(__ex_set_option(find_index('def-vi-or-ex-autoindent',VAR_TYPE),arg(1)));
}
#endif
typeless __ex_set_autoprint(...)
{
   def_vi_or_ex_autoprint=def_vi_or_ex_autoprint;
   return(__ex_set_option(find_index('def-vi-or-ex-autoprint',VAR_TYPE),arg(1)));
}
typeless __ex_set_edcompatible(...)
{
   def_vi_or_ex_edcompatible=def_vi_or_ex_edcompatible;
   return(__ex_set_option(find_index('def-vi-or-ex-edcompatible',VAR_TYPE),arg(1)));
}
typeless __ex_set_errorbells(...)
{
   def_vi_or_ex_errorbells=def_vi_or_ex_errorbells;
   return(__ex_set_option(find_index('def-vi-or-ex-errorbells',VAR_TYPE),arg(1)));
}
/*typeless __ex_set_readonly(...)
{
   def_vi_or_ex_readonly=def_vi_or_ex_readonly;
   typeless val=strip(arg(1));
   if(val){
      read_only_mode();
   } else {
      if (p_readonly_mode) {
         read_only_mode_toggle();
      }
   }
   return(__ex_set_option(find_index('def-vi-or-ex-readonly',VAR_TYPE),arg(1)));
}*/
typeless __ex_set_ignorecase(...)
{
   def_vi_or_ex_ignorecase=def_vi_or_ex_ignorecase;
   typeless val=strip(arg(1));
   if ( val=='' ) {
      // Return the current value
      if ( upcase(_search_case())=='I' ) {
         val=1;
      } else {
         val=0;
      }
   } else {
      if ( ! val ) {
         _search_case('E');
      } else {
         _search_case('I');
      }
   }
   return(__ex_set_option(find_index('def-vi-or-ex-ignorecase',VAR_TYPE),arg(1)));
   //return(val);
}
typeless __ex_set_list(...)
{
   def_vi_or_ex_list=def_vi_or_ex_list;
   first_buf_id := 0;
   typeless val=strip(arg(1));
   if ( val!='' ) {
      if ( isinteger(val) && val>=0 ) {
         wid := p_window_id;
         p_window_id=_mdi.p_child;
         first_buf_id=p_buf_id;
         for (;;) {
            if( val ) {
               p_ShowSpecialChars |= SHOWSPECIALCHARS_TABS|SHOWSPECIALCHARS_NLCHARS;
            } else {
               p_ShowSpecialChars &= ~(SHOWSPECIALCHARS_TABS|SHOWSPECIALCHARS_NLCHARS);
            }
            _next_buffer('H');   // 11/24/1997 - 'H' because might be an editor control
            for( ;p_buf_id!=first_buf_id && (p_buf_flags&VSBUFFLAG_HIDDEN); ) _next_buffer('H');
            if( p_buf_id==first_buf_id ) break;
         }
         p_window_id=wid;
      } else {
         // Invalid value - return the current value
         vi_message('LIST requires a value greater than or equal to 0');
         val='';
      }
   }

   return(__ex_set_option(find_index('def-vi-or-ex-list',VAR_TYPE),val));
}
typeless __ex_set_listchars(typeless val='')
{
   def_vi_or_ex_listchars=def_vi_or_ex_listchars;
   _str new_specials = _default_option('Q');
   if(val == ''){
      //we want to display the list of special characters that will be displayed
      // note: this is where it goes on startup
      val = def_vi_or_ex_listchars;
      if(val == ''){
         _str special_chars = _default_option('Q');
         // if there's nothing defined just define EOL
         val = 'eol:' :+ substr(special_chars,VSSPECIALCHAR_EOL+1,1);
      }
      return(val);
   } else {
      if(pos(',', val)){
         //if there are multiple things in their list
         _str cmds[];
         _str temp_val = val;
         _str temp;
         delim := ',';
         i := 0;
         int j;
         for (;;) {
            temp = _parse_line(temp_val, ',');
            if(temp == '') break;
            cmds[i] = temp;
            i++;
         }
         for (j = 0; j < i; j++) {
            if(ex_set_special_char(cmds[j], new_specials)){
               vi_message('Invalid argument: listchars=' val);
               val = def_vi_or_ex_listchars;
               return(val);
            }
         }
      } else {
         //should be just one character option being set 
         if(ex_set_special_char(val, new_specials)){
            vi_message('Invalid argument: listchars=' val);
            val = def_vi_or_ex_listchars;
            return(val);
         }
      }
      _default_option(VSOPTIONZ_SPECIAL_CHAR_XLAT_TAB, new_specials);
      return(__ex_set_option(find_index('def-vi-or-ex-listchars',VAR_TYPE),val));
   }
}
/**
 * Used to parse out what special character is being modified with the listchars option.
 * Currently only supporting eol and tab charactesr from this set option.
 * 
 * @param s             The current portion of the value entered for listchars.
 * @param new_specials  String of special characters
 * 
 * @return 0 if successful
 *         1 if malformed
 */
int ex_set_special_char(_str s, _str &new_specials){
   _str val;
   if (pos('eol:', s) == 1) {
      val = substr(s,5);
      if(length(val) != 1) {
         return(1);
      } else {
         new_specials = val :+ substr(new_specials, VSSPECIALCHAR_EOL+2);
      }
   } else if (pos('tab:', s) == 1) {
      val = substr(s,5);
      if(length(val) != 2) {
         return(1);
      } else {
         new_specials = substr(new_specials,1,2) :+ substr(s,5,1) :+ substr(new_specials, 4,1) :+ substr(s,6,1) :+ substr(new_specials,6,1); 
      }
   } else {
      return(1);
   }
   return(0);
}
typeless __ex_set_number()
{
   def_vi_or_ex_number=def_vi_or_ex_number;
   typeless val=strip(arg(1));
   if ( val=='' ) {
      // Return the current value
      val=(p_LCBufFlags&VSLCBUFFLAG_LINENUMBERS)?_default_option(VSOPTION_LINE_NUMBERS_LEN):0;
   } else {
      if ( !val ) {
         if ( p_LCBufFlags&(VSLCBUFFLAG_LINENUMBERS | VSLCBUFFLAG_LINENUMBERS_AUTO) ) {
            view_line_numbers_toggle();
         }
      } else if ( !(p_LCBufFlags&(VSLCBUFFLAG_LINENUMBERS | VSLCBUFFLAG_LINENUMBERS_AUTO)) ) {
         view_line_numbers_toggle();
      }
   }
   return(__ex_set_option(find_index('def-vi-or-ex-number',VAR_TYPE),arg(1)));
}
typeless __ex_set_paragraphs(...)
{
   def_vi_or_ex_paragraphs=def_vi_or_ex_paragraphs;
   return(__ex_set_option(find_index('def-vi-or-ex-paragraphs',VAR_TYPE),arg(1)));
}
typeless __ex_set_prompt(...)
{
   def_vi_or_ex_prompt=def_vi_or_ex_prompt;
   return(__ex_set_option(find_index('def-vi-or-ex-prompt',VAR_TYPE),arg(1)));
}
typeless __ex_set_report(...)
{
   def_vi_or_ex_report=def_vi_or_ex_report;
   return(__ex_set_option(find_index('def-vi-or-ex-report',VAR_TYPE),arg(1)));
}
typeless __ex_set_scroll(...)
{
   def_vi_or_ex_scroll=def_vi_or_ex_scroll;
   typeless val=strip(arg(1));
   if ( val=='' ) {
      // Return the current value
      val=def_vi_or_ex_scroll;
      if ( val=='' ) {
         // Return the default of 1/2 the mdi client height BUT do not set it
         val=ex_client_height() intdiv 2;
      }
      return(val);
   } else {
      if ( ! isinteger(val) || val<1 ) {
         vi_message('SCROLL requires a positive amount');
         val='';
         return(val);
      }
   }

   return(__ex_set_option(find_index('def-vi-or-ex-scroll',VAR_TYPE),val));
}
typeless __ex_set_sections(...)
{
   def_vi_or_ex_sections=def_vi_or_ex_sections;
   return(__ex_set_option(find_index('def-vi-or-ex-sections',VAR_TYPE),arg(1)));
}
typeless __ex_set_shell(...)
{
   def_vi_or_ex_shell=def_vi_or_ex_shell;
   typeless val=strip(arg(1));
   if ( val=='' ) {
      // Return the current value
      val=def_vi_or_ex_shell;
      if ( val=='' ) {
         if (_isUnix()) {
            val=get_env('SHELL');
         } else {
            val=get_env('COMSPEC');
         }
      }
      return(val);
   }

   return(__ex_set_option(find_index('def-vi-or-ex-shell',VAR_TYPE),val));
}
typeless __ex_set_shiftwidth(...)
{
   def_vi_or_ex_shiftwidth=def_vi_or_ex_shiftwidth;
   return(__ex_set_option(find_index('def-vi-or-ex-shiftwidth',VAR_TYPE),arg(1)));
}
typeless __ex_set_showmatch(...)
{
   def_vi_or_ex_showmatch=def_vi_or_ex_showmatch;
   return(__ex_set_option(find_index('def-vi-or-ex-showmatch',VAR_TYPE),arg(1)));
}
typeless __ex_set_showmode(...)
{
   def_vi_or_ex_showmode=def_vi_or_ex_showmode;
   return(__ex_set_option(find_index('def-vi-or-ex-showmode',VAR_TYPE),arg(1)));
}
typeless __ex_set_incsearch(...)
{
   def_vi_or_ex_incsearch=def_vi_or_ex_incsearch;
   if (strip(arg(1)) == "1") {
      def_search_incremental_highlight = 1;
   }
   return(__ex_set_option(find_index('def-vi-or-ex-incsearch',VAR_TYPE),arg(1)));
}
typeless __ex_set_hlsearch(...)
{
   def_vi_or_ex_hlsearch=def_vi_or_ex_hlsearch;
   if (strip(arg(1)) == "0") {
      def_vi_always_highlight_all = false;
      clear_highlights();
   } else if (isinteger(strip(arg(1)))) {
      def_vi_always_highlight_all = true;
   }
   return(__ex_set_option(find_index('def-vi-or-ex-hlsearch',VAR_TYPE),arg(1)));
}
#if 0
// Not supported
typeless __ex_set_tabstop(...)
   def_vi_or_ex_tabstop=def_vi_or_ex_tabstop;
   return(__ex_set_option(find_index('def-vi-or-ex-tabstop',VAR_TYPE),arg(1)));
}
#endif

#if 0
// Not supported
typeless __ex_set_tags()
{
   def_vi_or_ex_tags=def_vi_or_ex_tags;
   val=strip(arg(1));
   vslicktags_val=get_env('VSLICKTAGS');
   if ( val=='' ) {
      val=vslicktags_val;
      if ( val=='' ) {
         val=TAGS_DEFAULT;
      }
      return(val);
   } else {
      if ( val!="''" && val!='""' && ! pos(val,vslicktags_val,1,'i') ) {
         if ( last_char(val)!=PATHSEP ) {
            val :+= PATHSEP;
         }
         val :+= vslicktags_val;
      }
   }
   if( val=="''" || val=='""' ) {
      set_env('VSLICKTAGS','');
   } else {
      set_env('VSLICKTAGS',val);
   }

   return(__ex_set_option(find_index('def-vi-or-ex-tags',VAR_TYPE),val));
}
#endif
#if 0
// Not supported
typeless __ex_set_wrapmargin(...)
{
   val=arg(1);
   if ( val=='' ) {
      // Return the current value
      parse p_margins with . val .;   // 'val' contains the right margin
      wws=p_word_wrap_style&WORD_WRAP_WWS;
      if ( !wws ) {
         val=0;
      }
   } else {
      parse p_margins with left_margin right_margin para;   // 'val' contains the right margin
      if ( isinteger(val) && val>0 && val<=MAX_LINE ) {
         word_wrap('Y');
         p_margins=left_margin' 'val' 'para;
      } else if ( val==0 ) {
         word_wrap('N');
      } else {
         vi_message('WRAPMARGIN requires a value between 0 and 'MAX_LINE);
         wws=p_word_wrap_style&WORD_WRAP_WWS;
         if ( wws ) {
            val=right_margin;
         } else {
            val=0;
         }
      }
   }

   return(val);
}
#endif
typeless __ex_set_wrapscan(...)
{
   int flags;

   typeless val=strip(arg(1));
   if ( val=='' ) {
      // Return the current value
      val= 0!=(WRAP_SEARCH&_default_option('S'));
   } else {
      flags=_default_option('S');
      if ( !val ) {
         flags = flags & ~(WRAP_SEARCH);
      } else {
         flags |= WRAP_SEARCH;
      }
      _default_option('S',flags);
   }

   return(val);
}
typeless __ex_set_writeany(...)
{
   def_vi_or_ex_writeany=def_vi_or_ex_writeany;
   return(__ex_set_option(find_index('def-vi-or-ex-writeany',VAR_TYPE),arg(1)));
}

// This function is a match function for an ex set option.
typeless set_match(_str name,bool find_first)
{
   if ( find_first ) {
      _set_match_pos=1;
      if ( find_first==2 ) {
         return('');
      }
   }
   info := "";
   name=upcase(strip(name));
   p := pos(' 'name'={#0[~ \t]#} ',SET_ABBR_NAMES,1,'r');
   if( p ) {
      name=substr(SET_ABBR_NAMES,pos('S0'),pos('0'));
   }
   q := pos('{#0 'name'[~ \t]@ }',SET_NAMES,_set_match_pos,'er');
   if ( q ) {
      _set_match_pos=q+pos('0')-1;   // Next match occurs at the trailing space
      info=strip(substr(SET_NAMES,pos('S0'),pos('0')));
   } else if( p ) {   // Was it a valid abbreviation?
      info=name;
   }

   return(info);
}

// This function is a match function for an ex set option.
// This function formats the return value to display the current value
// as vi would display it if a 'set all' was issued from the ex command
// line.
//
// The format is as follows:
//   set option
//   set nooption
//   set option=value
typeless set2_match(_str name,bool find_first)
{
   if ( find_first ) {
      _set_match_pos=1;
      if ( find_first==2 ) {
         return('');
      }
   }
   name=upcase(strip(name));
   p := pos(' 'name'={#0[~ \t]#} ',SET_ABBR_NAMES,1,'r');
   if ( p ) {
      name=substr(SET_ABBR_NAMES,pos('S0'),pos('0'));
   }
   p=pos('{#0 'name'[~ \t]@ }',SET_NAMES,_set_match_pos,'er');
   if ( p ) {
      _set_match_pos=p+pos('0')-1;   // Next match occurs at the trailing space
      info := strip(substr(SET_NAMES,pos('S0'),pos('0')));
      proc_name := '--ex-set-':+lowcase(info);
      idx := find_index(proc_name,PROC_TYPE);
      if ( !idx ) {
         // Call _message_box() so the message does not get blasted by list_matches()
         _message_box('Can''t find procedure: 'proc_name);
         //vi_message('Can''t find procedure: 'proc_name);
         return('');
      }
      typeless val=call_index(idx);
      if ( pos(' 'info' ',SET_TOGGLE_NAMES) ) {
         if ( val==0 ) {
            info='NO':+info;
         }
      } else {
         info :+= '='val;
      }
      return(info);
   }

   return('');
}

/**
 * This function sets various options.
 *
 * @return
 */
typeless __ex_set(...)
{
   // This is of the form:
   //   set option
   //   set nooption
   //   set option=value
   typeless params=upcase(strip(arg(1)));
   /* arg(2) not used */
   /* arg(3) not used */
   /* arg(4) not used */

   lc := "";
   set_name := "";
   proc_name := "";
   typeless idx=0;
   typeless val='';
   typeless display_current_val=0;
   typeless is_toggle_name=0;
   if ( params=='' || params=='ALL' ) {
      _str selected = list_matches('',SET2_ARG);   // List names AND values
      initial_cmd := "set ";
      if(substr(selected,1,2) == 'NO'){
         initial_cmd :+= substr(selected,3);
      } else if (pos(selected,SET_TOGGLE_NAMES) ) {
         initial_cmd :+= 'NO' :+ selected;
      } else {
         if(pos('=',selected)){
            initial_cmd :+= selected;
         } else {
            initial_cmd :+= selected :+ '=';
         }
      }
      if (selected != '') {
         ex_mode('',initial_cmd);
      }
   } else {
      p := pos('=',params);
      if ( p && p<length(params) ) {
         // Use original argument to preserve case (e.g. for things like :set shell=/usr/bin/ksh)
         parse arg(1) with name '=' val;
         name=upcase(name);
      } else if ( _SubstrChars(params,1,2)=='NO' ) {
         name=substr(params,3);
         val=0;
      } else {
         // There is no value
         lc=_last_char(params);
         if ( lc=='?' || lc=='=' ) {
            // Display the current value
            display_current_val=1;
            params=substr(params,1,length(params)-1);
         }
         name=params;
         val='';   // Toggle ON or display current value
      }
      set_name=name;
      if ( set_name!='' ) {
         set_name=set_match(set_name,true);   // This takes care of aliases
      } else {
         vi_message(name":  No such option - 'set all' gives all option values");
         return(1);
      }

      if ( pos(' 'set_name' ',SET_NOT_SUPPORTED_NAMES) || pos(' 'name' ',SET_NOT_SUPPORTED_NAMES) ) {
         _message_box(name":  Option not supported - 'set all' gives all option values\n":+
                      "\n":+
                      "There are 2 possible reasons:\n":+
                      "\n":+
                      "\t1. Does not make sense to support the option.\n":+
                      "\n":+
                      "\t\t Example: TERM option for setting terminal type\n":+
                      "\n\n":+
                      "\t2. SlickEdit provides the option in a better format",
                      'Option not supported',MB_OK|MB_ICONINFORMATION);
         vi_message(name":  Option not supported - 'set all' gives all option values");
         return(1);
      } else if( set_name=='' ) {
         vi_message(name":  No such option - 'set all' gives all option values");
         return(1);
      }

      if ( pos(' 'set_name' ',SET_TOGGLE_NAMES) ) {
         is_toggle_name=1;
         if ( val=='' ) {   // Toggle ON or display current value?
            if ( !display_current_val ) {
               // Toggle ON
               val=1;
            }
         } else {
            if ( val!='0' ) {
               vi_message('Option 'set_name' is a toggle');
               return(1);
            }
         }
      }
      proc_name='--ex-set-':+lowcase(set_name);
      idx=find_index(proc_name,PROC_TYPE);
      if ( !idx ) {
         vi_message('Can''t find procedure: 'proc_name);
         return(1);
      }
      if ( val=='' ) {
         // Display the current value
         val=call_index(idx);
         if ( is_toggle_name ) {
            if ( !val ) {
               set_name='NO':+set_name;
            }
            vi_message(set_name);
         } else {
            vi_message(set_name'='call_index(idx));
         }
      } else {
         // Set the value
         call_index(val,idx);
      }
   }

   return(0);
}

// 'R' = process \e, \E, \l, \L, \u, \U, &, ~
//_str def_vi_substitute_options='';

/**
 * This handles 'substitute' on the ex command line.
 */
int __ex_substitute(...)
{
   typeless params=arg(1);
   typeless a1=arg(2);
   typeless a2=arg(3);
   /* arg(4) not used */
   delay_feedback := (arg(5)!='' && arg(5));
   repeat_last_substitute := (arg(6)!='' && arg(6));

   in_global := (prev_index()==find_index('__ex_global',PROC_TYPE));
   /*say('params='params);
   say('a1='a1' a2='a2);
   say('delay_feedback='delay_feedback);
   say('repeat_last_substitute='repeat_last_substitute);
   say('in_global='in_global);*/

   if ( repeat_last_substitute ) {
      params='';
   }
   print_cmd := "";   // If a 'P' or 'L' option is given then the name of the matching command is stored here
   if ( !isinteger(a1) && !isinteger(a2) ) {
      a1=ex_get_curlineno();
      a2=a1;
   } else {
      if ( !isinteger(a1) ) {
         a1=ex_get_curlineno();
      }
      if ( !isinteger(a2) ) {
         a2=ex_get_curlineno();
      }
   }
   len := 0;
   old_old_replace_string := "";
   search_string := "";
   search_flags := "";
   delim := "";
   ch := "";
   if ( params=='' ) {
      if ( old_search_string:=='' ) {
         vi_message('No previous substitute');
         return(1);
      } else {
         //search_flags=(old_search_flags &~(POSITIONONLASTCHAR_SEARCH|INCREMENTAL_SEARCH));
         if ( repeat_last_substitute ) {
            search_flags='*':+_vi_search_type():+'m(';
         }
      }
   } else {
      old_old_replace_string=old_replace_string;   /* Save this for the case
                                                    * of '~' in the replace
                                                    * string
                                                    */
      search_string='';   // At the end of the loop, this will hold the entire search expression
      len=length(params);
      i := 1;
      delim=_SubstrChars(params,i,1);

      // Get the search string
      i+=length(delim);
      for (;;) {
         if ( i>len ) break;
         ch=_SubstrChars(params,i,1);
         if ( ch==delim ) {
            break;
         }
         i+=length(ch);
         if ( ch=='\' ) {
            search_string :+= ch;
            // Get the skipped over char
            ch=_SubstrChars(params,i,1);
            search_string :+= ch;
            i+=length(ch);
         } else {
            search_string :+= ch;
         }
      }

      // Now get the replace string
      old_replace_string='';
      i+=length(delim);
      for (;;) {
         if ( i>len ) break;
         ch=_SubstrChars(params,i,1);
         if ( ch==delim ) {
            break;
         }
         if ( ch=='\' ) {
            // Get the skipped over char too
            ch=_SubstrChars(params,i,2);
            old_replace_string :+= ch;
         } else {
            old_replace_string :+= ch;
         }
         i+=length(ch);
      }

      // Now get the search flags
      search_flags=substr(params,i+length(delim));
      //messageNwait('search_string='search_string'  old_replace_string='old_replace_string'  search_flags='search_flags);
   }
   /*
      c  confirm
      *&  not same as Vim (means use previous flags). Wildcard regex
      g  Replace all occurence in line and not just the first occurence.
      i  ignore case
      I  Exact case
      e  Exact case. Extension
      p  Print line
      #  Not supported. Like 'p' and prepend the line number.
      *l  Not same as Vim (means like 'p' but print the text like :list). Perl regex.
      *n  Not same as Vim (Report number of matches only. Do not substitute). Plain text search (Non-regex search).
      *r  Not same as Vim (If search string is blank, use previous search string). SlickEdit regex.
      u   Perl regex. Extension
      ~   Vim regex. Extension
      w   Match words. Extension
      v   Preserve case. Case insensitive search. Preserve case replace. Extension
      m   Match occurrences within the selection. Extension

      Possible enhancements:

      Plan A: 
        *  Could implement Vim 'n' option to a search and replace preview
            // This does a search and replace preview
            replace_buffer_text("sdf","E>*","ZZZ",'0','1','0','0','0','0','1');

          upper case N could be used for plain text search.

          HOWEVER: This would differ slightly from / options (regex options are case insensitive).

        * Could add support for r and have R set SlickEdit regex.

          HOWEVER: This would differ slightly from / options (regex options are case insensitive).

     Plan B: (arguably a better plan even though it differs from Vim)

       * Add upper case P option which is a preview replace.
            replace_buffer_text("sdf","E>*","ZZZ",'0','1','0','0','0','0','1');
         Arguably the Vim 'n' option is a bit useless because you can simply perform the operation 
         and do an undo if there are too many changes performed.
         The vim 'r' option isn't that useful either because command retrieval is arguably
         better and a more natural way to reuse the previous search string since you can ACTUALLY
         see what you will be reusing.
   */

   noflines_index := pos(" :n",search_flags,1,'r'); 
   if (noflines_index > 0) {
      noflines := strip(substr(search_flags,noflines_index));
      if (isinteger(noflines)) {
         a1 = ex_get_curlineno();
         a2 = a1 + (int)noflines;
         search_flags = strip(substr(search_flags,1,noflines_index));
      }
   }

   // In Vim, upper case I means case sensitive search
   if (pos('I',search_flags)) {
      search_flags :+= 'e';
   } else if( !pos('i|e',search_flags,1,'r') ) {
      search_flags :+= _search_case();   // Use the default search-case sensitivity
   }
   re_type := upcase(_vi_search_type());
   ir:=pos('n|r|b|u|l|&|\~',search_flags,1,'ri');
   if ( !ir ) {
      search_flags :+= re_type;
   } else {
      re_type=upcase(substr(search_flags,ir,1));
   }
   if ( !pos('m',search_flags,1,'i') ) {
      search_flags :+= 'm(';
   }
   if ( pos('{p}',search_flags,1,'ri') ) {
      print_cmd=substr(search_flags,pos('S0'),pos('0'));   // Print current line after substitution
      search_flags=substr(search_flags,1,pos('S0')-1):+substr(search_flags,pos('S0')+1);
      print_cmd=ex_match(print_cmd,EX_ARG);   // Expand the option to an ex command name
      ex_match('','2');   // Reset
   }
   //messageNwait('search_flags='search_flags);

   if ( search_string:!='' ) {
      old_search_string=search_string;
   }

   // IF this is Vim syntax regex
   if( re_type:=='~') {
      _ex_process_replace_string(old_replace_string,old_old_replace_string);
#if 0
      if( pos('r',search_flags,1,'i') ) {
         old_search_string='{#0':+old_search_string:+'}';
      } else if( pos('b',search_flags,1,'i') ) {
         old_search_string='{@0':+old_search_string:+'}';
      } else if( pos('&',search_flags,1,'i') ) {
         // Wildcards don't support forcing a match group
      } else if( pos('~',search_flags,1,'i') ) {
         // For Vim RE, \0 always is whole matched string
         //old_search_string='{@0':+old_search_string:+'}';
      } else {
         old_search_string='(?0':+old_search_string:+')';
      }
#endif
   }

   // Set the step for the for() loop
   if ( a1>a2 ) {
      temp:=a1;
      a1=a2;
      a2=temp;
   }
   // Allocate the mark we will use for substituting
   typeless old_mark=_duplicate_selection('');
   typeless mark=_alloc_selection();
   if ( mark<0 ) {
      vi_message(get_message(mark));
      return(mark);
   }
   _show_selection(mark);
   // Check for the 'G' flag - means replace all occurrences of 'old_search_string' on the line
   replace_all := 0;   // Replace all occurrences on the line?
   if ( pos('{g}',search_flags,1,'ri') ) {
      // Replace all occurrences on a line
      replace_all=1;
      search_flags=substr(search_flags,1,pos('S0')-1):+substr(search_flags,pos('S0')+pos('0'));
   }
   // Check for the 'C' flag - means confirm on each replace
   confirm := 0;   // Confirm on each replace?
   if ( pos('{c}',search_flags,1,'ri') ) {
      // Confirm each replace
      confirm=1;
      search_flags=substr(search_flags,1,pos('S0')-1):+substr(search_flags,pos('S0')+pos('0'));
   }
   if( !confirm ) {
      // This is ignored by the search() builtin and is only here for clarity
      search_flags :+= '*';
   }

   // total_nofskipped will be >0 if we attempt to SUBSTITUTE outside bounds of p_TruncateLength
   total_nofskipped := 0;
   typeless total_skipped="";

   lines_matched := 0;
   last_line := 0;

   typeless p=0;
   typeless status=0;
   typeless result=0;
   nofskipped := 0;
   old_noflines := 0;
   case_insensitive := false;

   if (pos('i',search_flags,1,'ir')) {
      case_insensitive=true;
   }
   switch (re_type) {
   case 'U':
   case 'B':
   case 'L':
   case 'R':
   case '&':
   case '~':
   case '&':
   case 'N':
   case '':
      break;
   default:
      re_type='R';
   }
   sflags := 'M(@':+re_type;
   if (case_insensitive) {
      sflags :+= 'I';
   }
   if (pos('w',search_flags,1,'i')!=0) {
      sflags :+= 'W';
   }

   nofchanges := 0;
   nl_len:=length(p_newline);
   for (i:=a1;i<=a2;++i) {

      // Used at the end of the loop to determine whether the number of
      // lines in the buffer has increased.
      old_noflines=p_Noflines;

      p_line=i;
      // Be sure to start the search at the beginning of the line
      _begin_line();
      _deselect(mark);
      // Do not replace all occurrences on the line?
      _select_char(mark,'p');
      _end_line();
      if (nl_len==2 && get_text(2):=="\r\n") {
         right();right();
      } else {
         right();
      }
      _select_char(mark,'p');
      _begin_select();

      if ( !replace_all ) {
         //_select_line(mark,'P');
         //_begin_select();
         int status2;
         /*
            Since Vim supports match groups, I don't see why we try
            to forcefully use match group 1 here. Maybe users
            are taking advantage of this some how. Removed for now.

         if (supports_forced_match_group) {
            status2 = search('(?1('old_search_string'))',sflags);
         } else {
            status2 = search(old_search_string,sflags);
         } */
         status2 = search(old_search_string,sflags);
         if (!status2) {
            p = p_col; 
         } else {
            p = 0;
         }
         _deselect(mark);
         if ( p ) {
//          p_col=_text_colc(p,'I');
            // We do a block-mark because 'qreplace' doesn't like characer-marks
            _select_block(mark,'P');
            p_col=_text_colc(p+match_length()-1,'I');
            // Are we sitting at the beginning of tab?
            if( get_text():=="\t" ) {
               // Select the entire tab
               right();
               --p_col;
            }
            _select_block(mark,'P');
            // Must start searching at beginning of mark or will fail
            _begin_select(mark);
         } else {
            status=STRING_NOT_FOUND_RC;
            continue;
         }
      } else {
         //_select_line(mark,'P');
      }

      int old_nofchanges=nofchanges;
      if( !in_global ) {
         _SearchInitSkipped(0);
         status=search(old_search_string,search_flags'@');
         nofskipped=_SearchQNofSkipped();
         if( nofskipped ) {
            total_nofskipped+=nofskipped;
            total_skipped=strip(total_skipped):+" ":+_SearchQSkipped();
         }
         while( !status ) {
            if( confirm ) {
               if (replace_all) {
                  result=letter_prompt("replace with ":+old_replace_string:+" (y/n/a/q/l)?","ynaql");
               } else {
                  result=letter_prompt("replace with ":+old_replace_string:+" (y/n/a/q)?","ynaq");
               }
               if( result=='Q' || result:==ESC) {
                  // Break out.
                  // Setting status=1 causes the outer loop to be exited too.
                  status=1;
               } else if( result=='N' ) {
                  // Next occurrence.
                  if( replace_all ) {
                     status=repeat_search();
                     nofskipped=_SearchQNofSkipped();
                     if( nofskipped ) {
                        total_nofskipped+=nofskipped;
                        total_skipped=strip(total_skipped):+" ":+_SearchQSkipped();
                     }
                     if( status ) {
                        // If we are inside the loop then we found atleast 1
                        // match, so it is ok to set status=0. We do this so
                        // that the lines_matched variable is incremented and
                        // we don't end up getting a bogus "String not found"
                        // message at the end of the substitute.
                        status=0;
                        break;
                     }
                     continue;
                  }
                  // Setting status=STRING_NOT_FOUND_RC causes a search for
                  // next occurrence.
                  status=STRING_NOT_FOUND_RC;
               } else {
                  // Y or A or L
                  if( result=='A' ) {
                     confirm=0;
                  }
                  if( replace_all && result!='L') {
                     status=search_replace(old_replace_string,'R');
                     nofchanges++;
                     nofskipped=_SearchQNofSkipped();
                     if( nofskipped ) {
                        total_nofskipped+=nofskipped;
                        total_skipped=strip(total_skipped):+" ":+_SearchQSkipped();
                     }
                  } else {
                     status=search_replace(old_replace_string);
                     nofchanges++;
                     if (result=='L') {
                        // Break out.
                        // Setting status=1 causes the outer loop to be exited too.
                        status=1;
                     }
                     break;
                  }
               }
            } else {
               if( replace_all ) {
                  status=search_replace(old_replace_string,'R');
                  nofchanges++;
                  nofskipped=_SearchQNofSkipped();
                  if( nofskipped ) {
                     total_nofskipped+=nofskipped;
                     total_skipped=strip(total_skipped):+" ":+_SearchQSkipped();
                  }
               } else {
                  status=search_replace(old_replace_string);
                  nofchanges++;
                  break;
               }
            }
            if( status==STRING_NOT_FOUND_RC ) {
               // If we are inside the loop then we found atleast 1
               // match, so it is ok to set status=0. We do this so
               // that the lines_matched variable is incremented and
               // we don't end up getting a bogus "String not found"
               // message at the end of the substitute.
               status=0;
               break;
            }
         }
      } else {
         status=search(old_search_string,search_flags'@',old_replace_string, auto replaces);
         nofchanges += replaces;
      }
      /*
         This is exactly like Vim. I wonder if users would prefer to know the
         number of lines that we tried as apposed to how many lines were
         changed.
      */
      if (nofchanges!=old_nofchanges) {
         lines_matched++;
      }
      if ( !status ) {
         last_line=p_line;
      } else {
         if( status!=STRING_NOT_FOUND_RC ) {
            last_line=p_line;
            break;
         } else {
            clear_message();   // Clear the message so we don't see it during long searches
         }
      }

      // Check for an increased number of lines in the buffer.
      // This can happen if the substitute is inserting linebreaks
      // with the replace string.
      int diff=p_Noflines-old_noflines;
      a2+=diff;
      i+=diff;
   }
   // Do not forget to restore the previous mark
   _show_selection(old_mark);
   _free_selection(mark);
   if ( status ) {
      if ( status==STRING_NOT_FOUND_RC ) {
         if ( a1==a2 || !lines_matched ) {
            vi_message(get_message(status));
         } else {
            clear_message();
         }
         status=0;   // Not a serious error
      }
   } else {
      clear_message();
   }
   if (lines_matched > 0 && nofchanges > 0) {
      vi_message(nofchanges' substitutions on 'lines_matched' lines');
   }
   typeless dummy,old_search_flags;
   save_search(dummy,old_search_flags,dummy);
   if( last_line ) {
      p_line=last_line;
   }

   msg := "";
   if( total_nofskipped ) {
      msg="The following lines were skipped to prevent line truncation:\n\n":+total_skipped;
      _message_box(msg,"",MB_OK|MB_ICONINFORMATION);
   }

   if ( (print_cmd=='PRINT' || print_cmd=='LIST' || __ex_set_autoprint()) ) {
      if ( print_cmd=='LIST' ) {
         // Show end of line
         status=__ex_print('',a1,a2,'',delay_feedback,'1');
      } else {
         // Just print the line
         status=__ex_print('',a1,a2,'',delay_feedback);
      }
   }

   return(status);
}

/**
 * This handles 'sg' on the ex command line
 * <P>
 * Equivalent to :s//g
 *
 * @return
 */
int __ex_sg(...)
{
   return(__ex_substitute('//':+old_replace_string:+'/g',arg(2),arg(3),'','',''));
}

// Process the following options:
//
// ~        = replace with string of previous :substitute
// the rest of the options are built-in
static int _ex_process_replace_string(_str &rstr,_str prev_rstr) {
   _str result='';
   i := 1;
   len:=length(rstr);
   for (;;) {
      if ( i>len ) break;
      //say('i='i);
      j:=pos('~',rstr,i);
      if (j<=0) {
         j=len+1;
      }
      strappend(result,substr(rstr,i,j-i));
      //say('result='result);
      if (j>len) {
         break;
      }
      count:=0;
      i=j-1;
      while (i>0 && substr(rstr,i,1):=='\') {
         --i;
         ++count;
      }
      // IF even number of backslashes?
      if (!(count&1)) {
         //say('h1');
         strappend(result,prev_rstr);
         //say('h1 result='result);
      } else {
         //say('h2');
         strappend(result,'~');
      }
      i=j+1;
   }
   rstr=result;
   return(0);
}

/**
 * By default this handles '!' pressed.
 *
 * @return
 */
_command ex_repeat_last_substitute () name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   return(__ex_substitute('','','','','','1'));
}

/**
 * This function forks a shell.
 *
 * @return
 */
int __ex_shell()
{
   typeless params=arg(1);
   if ( params!='' ) {
      vi_message('Extra characters');
      return(1);
   }
   /* arg(2) not used */
   /* arg(3) not used */
   /* arg(4) not used */

   _str sh=__ex_set_shell();
   if ( sh=='' ) {
      // Run the default shell
      execute('dos',"");
   } else {
      old_shell := get_env("SHELL");
      set_env("SHELL",sh);
      // dos() command takes care of shelling with xterm, etc.
      execute('dos',"");
      set_env("SHELL",old_shell);
   }

   return(0);
}

/**
 * This function (as far as we can tell), behaves the same as :copy
 *
 * @return
 */
int __ex_t()
{
   return(__ex_copy(arg(1),arg(2),arg(3),arg(4),arg(5),'0'));
}

/**
 * This function puts cursor on the tag specified in 'params'.
 *
 * @return
 */
int __ex_tag()
{
   typeless params=arg(1);
   /* arg(2) not used */
   /* arg(3) not used */
   // This does nothing
   use_variant_form := (arg(4)!='' && arg(4));

   status := 0;
   if ( params=='' ) {
      status=pop_bookmark();
   } else {
      status=push_tag(params);
   }

   return(status);
}

/**
 * This function deletes an abbreviation (alias).
 *
 * @return
 */
int __ex_unabbreviate()
{
   typeless params=strip(arg(1));
   if ( params=='' ) {
      vi_message('No right hand side');
      return(1);
   }
   /* arg(2) not used */
   /* arg(3) not used */
   /* arg(4) not used */

   return(alias('-d 'params));
}

/**
 * This function undoes changes in the current buffer.
 *
 * @return
 */
typeless __ex_undo()
{
   typeless params=strip(arg(1));
   /* arg(2) not used */
   /* arg(3) not used */
   /* arg(4) not used */
   /* arg(5) not used */
   if ( params!='' ) {
      vi_message('Extra characters');
      return(1);
   }
   idx := find_index('undo',COMMAND_TYPE);
   if ( ! idx ) {
      vi_message('Can''t find command: undo');
      return(1);
   }
   typeless status=call_index(idx);

   return(status);
}

/**
 * This function is the equivalent of a ':g!'.
 *
 * @return
 */
int __ex_vglobal()
{
   // Set this so :global does not recurse
   last_index(find_index('--ex-global',PROC_TYPE));

   return(__ex_global(arg(1),arg(2),arg(3),'1'));
}

/**
 * This function gives the version of SlickEdit.
 *
 * @return
 */
int __ex_version()
{
   version();

   return(0);
}

/**
 * This command writes all modified buffers.
 * 
 * @return 
 */
int __ex_wall(...){

   if( !p_mdi_child ) {
      ex_msg_editctl();
      return(1);
   }

   int status = save_all();
   return(status);
}  

/**
 * This function writes a file out.
 *
 * @return
 */
int __ex_write(...)
{
   if( !p_mdi_child ) {
      ex_msg_editctl();
      return(1);
   }
   // This takes the form:
   //   filename
   //   >>filename
   //   !command       addressed lines become input to command
   typeless params=strip(arg(1));
   typeless arg4=strip(arg(4));
   append_to_file := 0;
   pipe_to_command := 0;
   using_bang := 0;
   if (arg4 != "" && isinteger(arg4)) {
      using_bang=(int)arg4;
   }
   if ( _SubstrChars(params,1,2)=='>>' ) {
      append_to_file=1;
      // Take what is after the '>>'
      params=strip(substr(params,3));
      if ( params=='' ) {
         vi_message('Missing filename');
         return(1);
      }
   } else if ( _SubstrChars(params,1,1)=='!' ) {
      pipe_to_command=1;
      // Take what is after the '!'
      params=strip(substr(params,2));
   }
   filename := "";
   typeless old_preplace=0;
   typeless status=0;
   typeless old_mark='';
   typeless mark='';
   typeless temp='';
   typeless a1=arg(2);
   typeless a2=arg(3);
   typeless writeany=__ex_set_writeany();
   use_variant_form := ((arg(4)!='' && arg(4)) || (writeany!='' && writeany));
   /* arg(5) not used */
   if ( !pipe_to_command && !append_to_file && params=='' &&
        !isinteger(a1) && ! isinteger(a2) ) {
      // Simply save the file
      if ( use_variant_form ) {
         old_preplace=def_preplace;
         def_preplace=0;
         status=save();
         def_preplace=old_preplace;   // QUICK - change it back!
      } else {
         status=save();
      }
   } else {
      if (select_active() && !using_bang && !append_to_file) {
         _str orig_params = params;
         _str fname = parse_file(orig_params);
         if (fname == "" || _file_eq(fname,p_buf_name)) {
            vi_message("Use ! to write partial buffer");
            return(1);
         }
      }
      // Get the address range
      if ( !isinteger(a1) && !isinteger(a2) ) {
         // The whole buffer
         a1=1;
         a2=p_Noflines;
      } else {
         if ( !isinteger(a1) ) {
            a1=ex_get_curlineno();
         }
         if ( !isinteger(a2) ) {
            a2=ex_get_curlineno();
         }
      }
      // Now mark the lines to save
      old_mark=_duplicate_selection('');
      mark=_alloc_selection();
      if ( mark<0 ) {
         vi_message(get_message(mark));
         return(mark);
      }
      _show_selection(mark);
      p_line=a1;
      _select_line(mark,'P');
      p_line=a2;
      _select_line(mark,'P');
      if ( pipe_to_command ) {
         temp=mktemp();
         if ( temp=='' ) {
            vi_message('Unable to create temporary file');
            return(1);
         }
         temp=absolute(temp);
         status=put(temp);
         if ( status ) {
            return(status);
         }
         params :+= '<'temp;
         status=__ex_shell_execute(params,'','');
         delete_file(temp);
      } else {
         filename=parse_file(params);
         if ( params!='' ) {
            vi_message('Too many file names');
            return(1);
         }
         if ( use_variant_form ) {
            old_preplace=def_preplace;
            // Turn off warnings
            def_preplace=0;
         }
         if ( append_to_file ) {
            status=append(filename);
         } else {
            if( filename=='' ) {
               // Use the current filename
               filename=p_buf_name;
            }
            status=put(filename,PAUSE_COMMAND);
            if( p_buf_name=='' && filename!='' ) {
               p_buf_name=filename;
               p_modify=false;
            }
         }
         if ( use_variant_form ) {
            def_preplace=old_preplace;
         }
      }
      _show_selection(old_mark);
      _free_selection(mark);
   }

   return(status);
}

/**
 * This function writes and quits all buffers.
 * 
 * @return 
 */
int __ex_wqall(...){

   int status, i, num_bufs;

   num_bufs = _Nofbuffers();

   // Do it this way...don't loop twice
   for (i = 0; i < num_bufs; i++) {
      if(__ex_write()) return(1);
      if(__ex_quit()) return(1);
   }

   return(0);
}

/**
 * This function works identically to '__ex_write' but also quits
 * the current buffer.
 *
 * @return
 */
int __ex_wq(...)
{
   if( !p_mdi_child ) {
      ex_msg_editctl();
      return(1);
   }

   typeless params=strip(arg(1));
   typeless a1=arg(2);
   typeless a2=arg(3);
   use_variant_form := (arg(4)!='' && arg(4));
   /* arg(5) not used */

   int status=__ex_write(params,a1,a2,use_variant_form);
   if ( !status ) {
      status=__ex_quit('','','',use_variant_form);
   }

   return(status);
}

/**
 * This function works identically to a 'wq'.
 *
 * @return
 */
int __ex_x()
{
   if( !p_mdi_child ) {
      ex_msg_editctl();
      return(1);
   }

   return(__ex_wq(arg(1),arg(2),arg(3),arg(4),arg(5)));
}

/**
 * This function copies line(s) to the clipboard.
 *
 * @return
 */
typeless __ex_yank()
{
   typeless params=strip(arg(1));
   typeless a1=arg(2);
   typeless a2=arg(3);
   /* arg(4) not used */
   /* arg(5) not used */
   if ( !isinteger(a1) && !isinteger(a2) ) {
      a1=ex_get_curlineno();
      a2=a1;
   } else {
      if ( !isinteger(a1) ) {
         a1=ex_get_curlineno();
      }
      if ( !isinteger(a2) ) {
         a2=ex_get_curlineno();
      }
   }
   rest := "";
   cb_name := "";
   typeless count='';
   if ( params!='' ) {
      #if 1
      parse params with cb_name rest;
      if( rest!='' ) {
         vi_message('Extra characters');
         return(1);
      }
      cb_name=params;
      #else
      parse params with first second;
      if ( second!='' ) {
         cb_name=first;
         count=second;
      } else {
         if ( isinteger(first) ) {
            count=first;
         }
      }
      if ( isinteger(count) ) {
         if ( count<=0 ) {
            vi_message('Positive count required');
            return(1);
         } else {
            // Make the beginning address the last address in the command prefix
            a1=a2;
            a2=a1+count-1;
            if ( a2>p_Noflines ) {   /* Is the count out of range */
               a2=p_Noflines;
            }
         }
      } else {
         vi_message('Extra characters');
         return(1);
      }
      #endif
   }

   // Now try finding vi-yank-line
   idx := find_index('vi-yank-line',COMMAND_TYPE);
   if ( !idx ) {
      vi_message('Can''t find command: vi-yank-line');
      return(1);
   }
   save_pos(auto p);
   // The yank will start from this address
   p_line=a1;
   count=a2-a1+1;
   // Set this so vi_repeat_info knows to record
   last_index(idx);
   typeless status=call_index(count,cb_name,idx);
   if ( !status ) {
      vi_message(count' lines');
   }
   restore_pos(p);

   return(status);
}

/**
 * This function displays the addressed lines.
 *
 * @return
 */
int __ex_z()
{
   typeless params=strip(arg(1));
   /* arg(2) not used */
   // Only interested in last address if there's no selection
   typeless a2=arg(3);
   /* arg(4) not used */
   /* arg(5) not used */

   if ( params=='' ) {
      params=p_char_height intdiv 2;
   }
   if ( !isinteger(a2) ) {
      a2=ex_get_curlineno()+1;
   }
   if ( a2>p_Noflines ) {
      vi_message('Not that many lines in buffer');
      return(1);
   }

   return(__ex_print(params,a2,a2,'','','','',''));
}


/**
 * This command is equivalent to a 'wq!' and handles 'ZZ' by default.
 *
 * @return
 */
_command int ex_zz() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if( command_state() ) {
      _str key=last_event();
      if( length(key):==1 ) {
         keyin(key);
      }
      return(0);
   }

   if( !p_mdi_child ) {
      ex_msg_editctl();
      return(1);
   }

   typeless status=0;
   typeless key1=last_event();
   typeless key2=get_event();
   if( key1:!=key2 ) {
      vi_message('Invalid key sequence');
      status=1;
   } else {
      // The '1' is so that __ex_wq uses the variant form
      status=__ex_wq('','','','1');
   }

   return(status);
}

// This function handles '<','>' pressed in ex mode.
static int ex_shift_text(typeless option,...)
{
   option=upcase(strip(option));
   typeless params=arg(2);
   typeless a1=arg(3);
   typeless a2=arg(4);
   if( !isinteger(a1) && !isinteger(a2) ) {
      a1=ex_get_curlineno();
      a2=a1;
   } else {
      if( !isinteger(a1) ) {
         a1=ex_get_curlineno();
      }
      if( !isinteger(a2) ) {
         a2=ex_get_curlineno();
      }
   }
   if( a2<a1 ) {
      // Backwards range, reverse it
      typeless temp=a1;
      a1=a2;
      a2=temp;
   }

   typeless count='';
   multiplier := 1;
   if ( params!='' ) {
      params=strip(params);
      if ( isinteger(params) ) {
         if ( params<1 ) {
            vi_message('< > requires a positive count');
            return(1);
         } else {
            // We only use the last address when we have a count
            a1=a2;
            count=params;
         }
      } else if( !verify(params,'<>') ) {
         // Multiplier for shiftwidth.
         // Example: ':1,2>>>>' will shift lines 1-2 over by shiftwidth*4
         // NOTE: The first '>' was already parsed out.
         multiplier=length(params)+1;
         // Total number of lines affected
         count=a2-a1+1;
      } else {
         vi_message('Extra characters');
         return(1);
      }
   } else {
      // Total number of lines affected
      count=a2-a1+1;
   }

   typeless t1,t2;
   int shiftwidth=p_SyntaxIndent;
   if( !isinteger(shiftwidth) || shiftwidth<1 ) {
      parse p_tabs with t1 t2 .;
      if( isinteger(t2) && isinteger(t1) && t2>t1 ) {
         shiftwidth=t2-t1;
      }
      if( !isinteger(shiftwidth) || shiftwidth<1 ) {
         shiftwidth=def_vi_or_ex_shiftwidth;
      }
   }
   if ( !isinteger(shiftwidth) || shiftwidth<1 ) {
      shiftwidth=VI_DEFAULT_SHIFTWIDTH;   // This is the real vi default value
   }

   // Now shift the text
   typeless lead_indent='';
   shift_amount := 0;
   dcount := 0;
   p_line=a1;
   // Start on the line above so the FOR loop works correctly
   up();
   int i;
   for (i=1; i<=count ; ++i) {
      down();
      if( !_line_length() ) continue;
      _first_non_blank();
      if ( option:=='-' ) {
         // Shifting left
         shift_amount=shiftwidth;
         if ( shiftwidth>(p_col-1) ) {
            shift_amount=p_col-1;
         }
         if ( p_col>1 ) {
            lead_indent=_expand_tabsc(1,p_col-multiplier*shift_amount-1,'S');
            dcount=p_col-1;
            _begin_line();
            // Strip leading spaces
            _delete_text(dcount,'C');
            _insert_text(lead_indent);
         }
      } else {
         // Shifting right
         if ( (_text_colc()+shiftwidth) > MAX_LINE ) {
            vi_message('This line cannot be shifted because it would exceed the line length limit!');
            return(1);
         }
         _first_non_blank();
         // The new indent
         lead_indent=indent_string(multiplier*shiftwidth+p_col-1);
         dcount=p_col-1;
         _begin_line();
         // Strip leading spaces
         _delete_text(dcount,'C');
         _insert_text(lead_indent);
      }
   }
   //up (count-1);
   _first_non_blank();

   return(0);
}


/**
 * This function shifts text left by shiftwidth.
 * <P>
 * <
 *
 * @return
 */
int __ex_shift_text_left(...)
{
   typeless params=arg(1);   // Don't care about params
   typeless a1=arg(2);
   typeless a2=arg(3);
   /* arg(4); not used */
   /* arg(5); not used */

   int status=ex_shift_text('-',params,a1,a2);

   return(status);
}

/**
 * This function shifts text right by shiftwidth.
 * <P>
 * >
 *
 * @return
 */
int __ex_shift_text_right(...)
{
   // Do not care about params
   typeless params=arg(1);
   typeless a1=arg(2);
   typeless a2=arg(3);
   /* arg(4); not used */
   /* arg(5); not used */

   int status=ex_shift_text('',params,a1,a2);

   return(status);
}

/**
 * This function emulates the Vim help command
 * 
 * <P>
 * 
 *
 * @return
 */
int __ex_help(...)
{
   // Do not care about params
   typeless params=arg(1);
   typeless a1=arg(2);
   typeless a2=arg(3);
   /* arg(4); not used */
   /* arg(5); not used */

   if (params=='') {
      help('Vim emulation keys');
      return(0);
   }
   name := 'vi-'strip(params);
   typeless result=h_match(name,1);
   h_match(name,2);
   if (result=='') {
       vi_message('help on 'params' not found');
       return(1);
   }
   help(result);

   return(0);
}

