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
#include "treeview.sh"
#import "annotations.e"
#import "beautifier.e"
#import "bookmark.e"
#import "cformat.e"
#import "cutil.e"
#import "debug.e" 
#import "files.e"
#import "help.e"
#import "ini.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "markfilt.e"
#import "math.e"
#import "saveload.e"
#import "seldisp.e"
#import "setupext.e"
#import "stdcmds.e"
#import "stdprocs.e"
#endregion


static int findBeginContext(int mark, int &sl, int &el, bool quiet=false)
{
   int old_sl=sl;
   int old_el=el;
   msg := "";

   _begin_select(mark);

   while( p_line>1 ) {
      // Goto to beginning of line so not fooled by start of comment
      _begin_line();
      if( _in_comment(true) ) {
         // If we are in the middle of a multi-line comment,
         // then skip to beginning of it
         if( p_line==1 ) {
            // Should never get here
            // There is no way we will find the beginning of this comment
            if( !quiet ) {
               msg="Cannot find beginning of context:\n\n":+
                   "\tCannot find beginning of comment at line 1";
               _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            }
            sl=0;
            el=0;
            return 1;
         }
         up();
         while( p_line && _clex_find(0,'G')==CFG_COMMENT ) {
            up();
         }
         if( _clex_find(0,'G')==CFG_COMMENT ) {
            // We are at the top of file
            if( !quiet ) {
               msg="Cannot find beginning of context:\n\n":+
                   "\tCannot find beginning of comment at line 1";
               _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            }
            sl=0;
            el=0;
            return 1;
         }
         _end_line();
         // Check to see if we are ON the multiline comment
         if( _clex_find(0,'G')!=CFG_COMMENT ) {
            down();   // Move back onto the first line of the comment
         }
      } else {
         break;
      }
   }
   sl=p_line;
   if( sl!=old_sl ) {
      // Reset the selection
      _deselect(mark);
      p_line=sl;
      _select_line(mark);
      p_line=el;
      _select_line(mark);
   }

   _begin_select(mark);

   // Beginning of context is top-of-file
   top();

   return 0;
}

static int findEndContext(int mark, int &sl, int &el, bool quiet=false)
{
   int old_sl=sl;
   int old_el=el;
   msg := "";

   _end_select(mark);
   // Goto end of line so not fooled by start of comment
   _end_line();

   while( p_line<p_Noflines ) {
      if( _in_comment(true) ) {
         // If we are in the middle of a multi-line comment,
         // then skip to end of it
         if( down() ) {
            // Should never get here
            // There is no way that this multi-line comment has an end
            if( !quiet ) {
               msg="Cannot find end of context:\n\n":+
                   "\tCannot find end of comment at line ":+p_line;
               _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            }
            sl=0;
            el=0;
            return 1;
         }
         _begin_line();
         while( _clex_find(0,'G')==CFG_COMMENT ) {
            if( down() ) break;   // Comment might extend to bottom of file
            _begin_line();
         }
         if( _clex_find(0,'G')==CFG_COMMENT ) {
            // We are at the bottom of file
            if( !quiet ) {
               msg="Cannot find end of context:\n\n":+
                   "\tCannot find end of comment at line ":+p_line;
               _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            }
            sl=0;
            el=0;
            return 1;
         }
         up();   // Move back onto the last line of the comment
         // Will get infinite loop if we don't move outside the comment
         _end_line();
      } else {
         break;
      }
   }
   el=p_line;
   if( el!=old_el ) {
      // Reset the selection
      _deselect(mark);
      p_line=sl;
      _select_line(mark);
      p_line=el;
      _select_line(mark);
   }

   // End of context is bottom-of-file
   bottom();

   return 0;
}

static int createContextView(_str mlc_startstr,_str mlc_endstr,
                             int &temp_view_id,
                             int &context_mark,
                             int &soc_linenum,   // StartOfContext line number
                             bool &last_line_was_bare,
                             bool quiet=false)
{
   last_line_was_bare=false;
   save_pos(auto p);
   old_linenum := p_line;
   typeless orig_mark=_duplicate_selection("");
   context_mark=_duplicate_selection();
   typeless mark=_alloc_selection();
   if( mark<0 ) {
      _free_selection(context_mark);
      return mark;
   }
   start_col := 0;
   end_col := 0;
   dummy := 0;
   startmark_linenum := 0;
   typeless stype=_select_type();
   if( stype!='LINE' ) {
      // Change the duplicated selection into a LINE selection
      if( stype=='CHAR' ) {
         _get_selinfo(start_col,end_col,dummy);
         if( end_col==1 ) {
            // Throw out the last line of the selection
            _deselect(context_mark);
            _begin_select();
            startmark_linenum=p_line;
            _select_line(context_mark);
            _end_select();
            // Check to be sure it's not a case of a character-selection of 1 char on the same line
            if( p_line!=startmark_linenum ) {
               up();
            }
            _select_line(context_mark);
         } else {
            _select_type(context_mark,'T','LINE');
         }
      } else {
         _select_type(context_mark,'T','LINE');
      }
   }

   // Define the line boundaries of the selection
   _begin_select(context_mark);
   sl := p_line;   // start line
   _end_select(context_mark);
   el := p_line;   // end line
   int orig_sl=sl;
   int orig_el=el;

   // Find the top context
   if( findBeginContext(context_mark,sl,el,quiet) ) {
      if( !sl || !el ) {
         // Probably in the middle of a comment that
         // extended to the bottom of file, so could
         // do nothing.
         _free_selection(context_mark);
         _free_selection(mark);
         restore_pos(p);
         return 1;
      }
      top();
   }
   tl := p_line;   // Top line
   soc_linenum=sl;
   int diff=old_linenum-tl;
   _select_line(mark);
   _begin_select(context_mark);
   _first_non_blank();
   int start_indent=p_col-1;

   // Find the bottom context
   if( findEndContext(context_mark,sl,el,quiet) ) {
      if( !sl || !el ) {
         _free_selection(context_mark);
         _free_selection(mark);
         restore_pos(p);
         return 1;
      }
      bottom();
   }
   _select_line(mark);
   _end_select(context_mark);

   // Check to see if last line was bare of newline
   last_line_was_bare= (_line_length()==_line_length(true));

   // Create a temporary view to hold the code selection and move it there
   arg2 := "+td";   // DOS \r\n linebreak
   if( length(p_newline)==1 ) {
      if( substr(p_newline,1,1)=='\r' ) {
         arg2="+tm";   // Macintosh \r linebreak
      } else {
         arg2="+tu";   // UNIX \n linebreak
      }
   }
   int orig_view_id=_create_temp_view(temp_view_id,arg2);
   if( orig_view_id=='' ) return 1;

   // Set the encoding of the temp view to the same thing as the original buffer
   typeless junk;
   typeless utf8;
   typeless encoding;
   _get_selinfo(junk,junk,junk,mark,junk,utf8,encoding);
   p_UTF8=utf8;
   p_encoding=encoding;

   _copy_to_cursor(mark);
   _free_selection(mark);       // Can free this because it was never shown
   top();up();
   insert_line(mlc_startstr:+' ADA-SUSPEND-WRITE ':+mlc_endstr);
   down();
   p_line=sl-tl+1;   // +1 to compensate for the previously inserted line at the top
   insert_line(mlc_startstr:+' ADA-RESUME-WRITE ':+mlc_endstr);
   p_line=el-tl+1+2;   // +2 to compensate for the 2 previously inserted lines
   insert_line(mlc_startstr:+' ADA-SUSPEND-WRITE ':+mlc_endstr);
   top();
   // +2 to adjust for the ADA-SUSPEND-WRITE and ADA-RESUME-WRITE above
   p_line += diff+2;
   p_window_id=orig_view_id;

   return 0;
}

static void deleteContextSelection(int context_mark)
{
   // If we were on the last line, then beautified text will get inserted too
   // early in the buffer
   _end_select();
   last_line_was_empty := 0;
   if( down() ) {
      // We are on the last line of the file
      last_line_was_empty=1;
   } else {
      up();
   }

   _begin_select(context_mark);
   _begin_line();

   // Now delete the originally selected lines
   _delete_selection(context_mark);
   // Can free this because it was never shown
   _free_selection(context_mark);
   if( !last_line_was_empty ) up();

   return;
}

int _OnUpdate_ada_beautify_selection(CMDUI cmdui,int target_wid,_str command)
{
   return (_OnUpdate_ada_beautify(cmdui,target_wid,command));
}

_command int ada_format_selection,ada_beautify_selection(int ibeautifier=-1,bool quiet=false
             ) name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBeautifiers()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Beautify");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   if (new_beautifier_supported_language(p_LangId)) {
      if (select_active()) {
         return new_beautify_selection();
      } else {
         beautify_current_buffer();
         return 0;
      }
   }

   if( !select_active() ) {
      return (ada_format(0,0,ibeautifier,quiet));
   }

   if( p_Nofhidden ) {
      show_all();
   }

   editorctl_wid := p_window_id;
   if( !_isEditorCtl() ) {
      editorctl_wid=0;
   }

   // Do the current buffer
   msg := "";
   status := 0;
   typeless sync_lang_options=1;

   // Ada only has line comments, so fake this up
   mlc_startstr := "--";
   mlc_endstr := "";

   save_pos(auto p);
   orig_view_id := p_window_id;
   old_left_edge := p_left_edge;
   old_cursor_y := p_cursor_y;

   _begin_select();
   tom_linenum := p_line;
   restore_pos(p);

   // Find the context
   temp_view_id := 0;
   context_mark := 0;
   soc_linenum := 0;
   last_line_was_bare := false; 
   if( createContextView(mlc_startstr,mlc_endstr,temp_view_id,context_mark,soc_linenum,last_line_was_bare,quiet) ) {
      if( !quiet ) {
         _message_box('Failed to derive context for selection');
      }
      return 1;
   }

   typeless old_mark=0, mark=0;
   start_indent := 0;
   new_linenum := 0;
   error_linenum := 0;

   // Do this before calling ada_format() so do not end up somewhere funky
   restore_pos(p);
   status=ada_format(temp_view_id,start_indent,ibeautifier,quiet);
   if( !status ) {
      p_window_id=orig_view_id;
      old_mark=_duplicate_selection("");
      mark=_alloc_selection();
      if( mark<0 ) {
         _delete_temp_view(temp_view_id);
         msg=get_message(mark);
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         return mark;
      }

      // Delete the selection and position cursor so we are sure
      // we start inserting beautified text at the correct place
      deleteContextSelection(context_mark);

      // Get the beautified text from the temp view
      p_window_id=temp_view_id;
      new_linenum=p_line;
      top();
      _select_line(mark);
      bottom();
      _select_line(mark);
      p_window_id=orig_view_id;
      _copy_to_cursor(mark);
      _end_select(mark);
      _free_selection(mark);
      // Check to see if we need to strip off the last newline
      if( last_line_was_bare ) {
         _end_line();
         _delete_text(-2);
      }
      new_linenum += soc_linenum-1;
      p_line=new_linenum;
      set_scroll_pos(old_left_edge,old_cursor_y);
      // HERE - Need to account for extended selection because started/ended
      // in the middle of a comment.  Need to do an adjustment.
   } else {
      if( status==2 ) {
         // There was an error, so transform the error line number
         // from the temp view into the correct line number
         error_linenum=p_line;
         p_window_id=orig_view_id;
         _deselect();
         // -2 to correct for the
         // ADA-SUSPEND-WRITE and ADA-RESUME-WRITE directives
         // in the temp view.
         error_linenum += soc_linenum-1-2;
         if( error_linenum>0 ) {
            p_line=error_linenum;
         }
         set_scroll_pos(old_left_edge,old_cursor_y);
         msg=vsadaformat_iserror();
         if( isinteger(msg) ) {
            // Got one of the *_RC constants in rc.sh
            msg=get_message((int)msg);
         } else {
            parse msg with . ':' msg;
            msg=error_linenum:+':':+msg;
         }
         if( !quiet ) {
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         }
      }
   }

   // Cleanup
   _delete_temp_view(temp_view_id);

   return status;
}
static void _ada_convert_adjacent_option(int ibeautifier,_str (&options):[],_str name,_str option_name) {
   typeless apply;
   value:=_beautifier_get_property(ibeautifier,name,null,apply);
   if (value==null || !apply || !isinteger(value)) {
      options:[option_name]=-1;
      return;
   }
   options:[option_name]=value;
}
static void _ada_convert_bool_option(int ibeautifier,_str (&options):[],_str name,_str option_name,bool not_value=false) {
   typeless apply;
   value:=_beautifier_get_property(ibeautifier,name,null,apply);
   if (value==null || !apply || !isinteger(value)) {
      return;
   }
   if (not_value) {
      options:[option_name]=value?0:1;
   } else {
      options:[option_name]=value?1:0;
   }
}
static void _ada_convert_int_option(int ibeautifier,_str (&options):[],_str name,_str option_name) {
   typeless apply;
   value:=_beautifier_get_property(ibeautifier,name,null,apply);
   if (name==VSCFGP_BEAUTIFIER_WC_KEYWORD && !apply) {
      value= -1;
   }
   if (!isinteger(value)) {
      return;
   }
   options:[option_name]=value;
}
static void _ada_convert_pad_option(int ibeautifier,_str (&options):[],_str name,_str option_word) {
   typeless apply;
   typeless value=_beautifier_get_property(ibeautifier,name,null,apply);
   if (value==null || !apply || !isinteger(value)) {
      options:['PadBefore':+option_word]=-1;
      options:['PadAfter':+option_word]=-1;
      return;
   }
   options:['PadBefore':+option_word]=(value&1)?1:0;
   options:['PadAfter':+option_word]=(value&2)?1:0;
}

static void _ada_convert_options_to_hashtab(int ibeautifier,_str (&options):[]) {

   _ada_convert_adjacent_option(ibeautifier,options,VSCFGP_BEAUTIFIER_BL_BETWEEN_ADJACENT_FOR_USE,'BLAdjacentAspectClause');
   _ada_convert_adjacent_option(ibeautifier,options,VSCFGP_BEAUTIFIER_BL_BETWEEN_ADJACENT_FUNS,'BLAdjacentSubprogramBody');
   _ada_convert_adjacent_option(ibeautifier,options,VSCFGP_BEAUTIFIER_BL_BETWEEN_ADJACENT_FUN_PROTOTYPES,'BLAdjacentSubprogramDecl');
   _ada_convert_adjacent_option(ibeautifier,options,VSCFGP_BEAUTIFIER_BL_BETWEEN_ADJACENT_TYPE_DECLS,'BLAdjacentTypeDecl');
   _ada_convert_adjacent_option(ibeautifier,options,VSCFGP_BEAUTIFIER_BL_AFTER_FOR_USE,'BLAfterAspectClause');
   _ada_convert_adjacent_option(ibeautifier,options,VSCFGP_BEAUTIFIER_BL_AFTER_BEGIN,'BLAfterBegin');
   _ada_convert_adjacent_option(ibeautifier,options,VSCFGP_BEAUTIFIER_BL_AFTER_IF,'BLAfterIf');
   _ada_convert_adjacent_option(ibeautifier,options,VSCFGP_BEAUTIFIER_BL_AFTER_LOOP,'BLAfterLoop');
   _ada_convert_adjacent_option(ibeautifier,options,VSCFGP_BEAUTIFIER_BL_AFTER_NESTED_LIST_ITEM,'BLAfterNestedParenListItem');
   _ada_convert_adjacent_option(ibeautifier,options,VSCFGP_BEAUTIFIER_BL_AFTER_RETURN,'BLAfterReturn');
   _ada_convert_adjacent_option(ibeautifier,options,VSCFGP_BEAUTIFIER_BL_AFTER_FUNS,'BLAfterSubprogramBody');
   _ada_convert_adjacent_option(ibeautifier,options,VSCFGP_BEAUTIFIER_BL_AFTER_FUN_PROTOTYPES,'BLAfterSubprogramDecl');
   _ada_convert_adjacent_option(ibeautifier,options,VSCFGP_BEAUTIFIER_BL_AFTER_SUBUNIT_HEADER,'BLAfterSubunitHeader');
   _ada_convert_adjacent_option(ibeautifier,options,VSCFGP_BEAUTIFIER_BL_AFTER_TYPE_DECLS,'BLAfterTypeDecl');
   _ada_convert_adjacent_option(ibeautifier,options,VSCFGP_BEAUTIFIER_BL_BEFORE_FOR_USE,'BLBeforeAspectClause');
   _ada_convert_adjacent_option(ibeautifier,options,VSCFGP_BEAUTIFIER_BL_BEFORE_END,'BLBeforeBegin');
   _ada_convert_adjacent_option(ibeautifier,options,VSCFGP_BEAUTIFIER_BL_BEFORE_END_IF,'BLBeforeIf');
   _ada_convert_adjacent_option(ibeautifier,options,VSCFGP_BEAUTIFIER_BL_BEFORE_END_LOOP,'BLBeforeLoop');
   _ada_convert_adjacent_option(ibeautifier,options,VSCFGP_BEAUTIFIER_BL_BEFORE_NESTED_LIST_ITEM,'BLBeforeNestedParenListItem');
   _ada_convert_adjacent_option(ibeautifier,options,VSCFGP_BEAUTIFIER_BL_BEFORE_RETURN,'BLBeforeReturn');
   _ada_convert_adjacent_option(ibeautifier,options,VSCFGP_BEAUTIFIER_BL_BEFORE_FUNS,'BLBeforeSubprogramBody');
   _ada_convert_adjacent_option(ibeautifier,options,VSCFGP_BEAUTIFIER_BL_BEFORE_FUN_PROTOTYPES,'BLBeforeSubprogramDecl');
   _ada_convert_adjacent_option(ibeautifier,options,VSCFGP_BEAUTIFIER_BL_BEFORE_TYPE_DECLS,'BLBeforeTypeDecl');
   _ada_convert_int_option(ibeautifier,options,VSCFGP_BEAUTIFIER_INDENT_WIDTH_COMMENT_AFTER_TYPE_DECL,'CommentAfterTypeDeclIndent');
   _ada_convert_int_option(ibeautifier,options,VSCFGP_BEAUTIFIER_INDENT_WIDTH_CONTINUATION,'ContinuationIndent');
   _ada_convert_bool_option(ibeautifier,options,VSCFGP_BEAUTIFIER_REQUIRE_NEW_LINE_AFTER_LOGICAL_OPERATOR_IN_IF,'IfBreakOnLogicalOps');
   _ada_convert_int_option(ibeautifier,options,VSCFGP_BEAUTIFIER_INDENT_WIDTH_IF_EXPR_CONTINUATION,'IfLogicalOpAddContinuationIndent');
   _ada_convert_int_option(ibeautifier,options,VSCFGP_BEAUTIFIER_INDENT_WIDTH_IF_EXPR_CONTINUATION_MULTIPLE_LOGICAL_OPS,'IfLogicalOpLogicalOpAddContinuationIndent');
   _ada_convert_int_option(ibeautifier,options,VSCFGP_BEAUTIFIER_INDENT_WIDTH_IF_EXPR_CONTINUATION_MULTIPLE_LOGICAL_OPS,'IfLogicalOpLogicalOpAddContinuationIndent');
   _ada_convert_int_option(ibeautifier,options,VSCFGP_BEAUTIFIER_SYNTAX_INDENT,'IndentPerLevel');
   _ada_convert_bool_option(ibeautifier,options,VSCFGP_BEAUTIFIER_INDENT_WITH_TABS,'IndentWithTabs');
   _ada_convert_bool_option(ibeautifier,options,VSCFGP_BEAUTIFIER_MAX_LINE_LEN,'MaxLineLength');
   _ada_convert_bool_option(ibeautifier,options,VSCFGP_BEAUTIFIER_LEAVE_TYPE_DECL_TRAILING_COMMENT,'NoTrailingTypeDeclComments',true);
   _ada_convert_bool_option(ibeautifier,options,VSCFGP_BEAUTIFIER_LEAVE_MULTIPLE_DECL,'OneDeclPerLine',true);
   _ada_convert_bool_option(ibeautifier,options,VSCFGP_BEAUTIFIER_LEAVE_MULTIPLE_ENUM,'OneEnumPerLine',true);
   _ada_convert_bool_option(ibeautifier,options,VSCFGP_BEAUTIFIER_LEAVE_MULTIPLE_FUN_DECL_PARAMS,'OneParameterPerLine',true);
   _ada_convert_bool_option(ibeautifier,options,VSCFGP_BEAUTIFIER_LEAVE_MULTIPLE_STMT,'OneStatementPerLine',true);
   _ada_convert_bool_option(ibeautifier,options,VSCFGP_BEAUTIFIER_WRAP_OPERATORS_BEGIN_NEXT_LINE,'OperatorBias');
   _ada_convert_int_option(ibeautifier,options,VSCFGP_BEAUTIFIER_ORIGINAL_TAB_SIZE,'OrigTabSize');
   _ada_convert_pad_option(ibeautifier,options,VSCFGP_BEAUTIFIER_SPSTYLE_OP_BINARY,'BinaryOps');
   _ada_convert_pad_option(ibeautifier,options,VSCFGP_BEAUTIFIER_SPSTYLE_COMMA,'Comma');
   _ada_convert_pad_option(ibeautifier,options,VSCFGP_BEAUTIFIER_SPSTYLE_LPAREN,'LeftParen');
   _ada_convert_pad_option(ibeautifier,options,VSCFGP_BEAUTIFIER_SPSTYLE_RPAREN,'RightParen');
   _ada_convert_pad_option(ibeautifier,options,VSCFGP_BEAUTIFIER_SPSTYLE_SEMICOLON,'Semicolon');
   _ada_convert_int_option(ibeautifier,options,VSCFGP_BEAUTIFIER_WC_KEYWORD,'ReservedWordCase');
   _ada_convert_int_option(ibeautifier,options,VSCFGP_BEAUTIFIER_TAB_SIZE,'TabSize');
   _ada_convert_int_option(ibeautifier,options,VSCFGP_BEAUTIFIER_TRAILING_COMMENT_STYLE3,'TrailingComment');
   _ada_convert_int_option(ibeautifier,options,VSCFGP_BEAUTIFIER_TRAILING_COMMENT_COL,'TrailingCommentCol');
   _ada_convert_int_option(ibeautifier,options,VSCFGP_BEAUTIFIER_INDENT_WIDTH_TRAILING_COMMENT,'TrailingCommentIndent');
   _ada_convert_bool_option(ibeautifier,options,VSCFGP_BEAUTIFIER_ALIGN_ADJACENT_COMMENTS,'VAlignAdjacentComments');
   _ada_convert_bool_option(ibeautifier,options,VSCFGP_BEAUTIFIER_ALIGN_ON_ASSIGNMENT_OP,'VAlignAssignment');
   _ada_convert_bool_option(ibeautifier,options,VSCFGP_BEAUTIFIER_ALIGN_FUN_PARAMS_ON_COLON,'VAlignDeclColon');
   _ada_convert_bool_option(ibeautifier,options,VSCFGP_BEAUTIFIER_ALIGN_FUN_PARAMS_ON_IN_OUT,'VAlignDeclInOut');
   /*foreach (auto i => auto v in options) {
      say('i='i' v='v);
   } */
}

static const AFDEBUG_WINDOW= 0;
static const AFDEBUG_FILE=  0;

static const AFDEBUGFLAG_WINDOW= 0x1;
static const AFDEBUGFLAG_FILE=   0x2;
static const AFDEBUGFLAG_ALL=    0x3;

int _format_ada(int ibeautifier,
                _str lang,
                _str orig_encoding,
                _str infilename,
                _str in_wid,
                _str outfilename,
                int  start_indent,
                int  start_linenum)
{
   _str options:[];
   _ada_convert_options_to_hashtab(ibeautifier,options);
   vse_flags := 0;
   if( AFDEBUG_WINDOW || AFDEBUG_FILE ) {
      if( AFDEBUG_WINDOW ) {
         vse_flags|=AFDEBUGFLAG_WINDOW;
      }
      if( AFDEBUG_FILE ) {
         vse_flags|=AFDEBUGFLAG_FILE;
      }
   }

   int status=vsada_format(orig_encoding,
                       infilename,
                       (int)in_wid,
                       outfilename,
                       start_indent,
                       start_linenum,
                       options,
                       vse_flags);

   return 0;
}
