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
#include "treeview.sh"
#import "adaptiveformatting.e"
#import "alias.e"
#import "autocomplete.e"
#import "c.e"
#import "cutil.e"
#import "notifications.e"
#import "pmatch.e"
#import "se/lang/api/LanguageSettings.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "tags.e"
#import "setupext.e"
#import "alllanguages.e"
#import "picture.e"
#import "mprompt.e"
#import "treeview.e"
#import "help.e"
#import "compile.e"
#import "diff.e"
#import "complete.e"
#import "main.e"
#import "projutil.e"
#import "dir.e"
#import "wkspace.e"
#import "env.e"
#endregion

using se.lang.api.LanguageSettings;
_command void clojure_enter() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   generic_enter_handler(_clojure_expand_enter);
}

bool _clojure_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}


static bool _clojure_expand_enter()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;
   //indent_case := (int)p_indent_case_from_switch;
   
   //be_style := LanguageSettings.getBeginEndStyle(p_LangId);
   //expand := LanguageSettings.getSyntaxExpansion(p_LangId);

   col:=clojure_indent_col(0);
   indent_on_enter(0,col);

   return(false);

}
static int NoSyntaxIndentCase(int non_blank_col,int orig_linenum,int orig_col,typeless p,int syntax_indent)
{
   //_message_box("This case not handled yet");
   // SmartPaste(R) should set the non_blank_col
   if (non_blank_col) {
      //messageNwait("fall through case 1");
      restore_pos(p);
      return(non_blank_col);
   }
   save_pos(auto p2);
   restore_pos(p);
   _first_non_blank();
   // If there is any code before the cursor?
   status:=_clex_skip_blanks('-hq');
   if (status || p_line==0) {
      // Only comments at or before the cursor
   } else {
      // There's code at or before the original cursor location
      restore_pos(p);
      return(1);
   }
   _str ch;
#if 0
   restore_pos(p);
   // See if current line has code
   first_non_blank();
   ch:=get_text();
   if (ch:!=';' && ch:!=' ' && ch:!="\t" && ch:!="\r" && ch:!="\n") {
      // There's code at the cursor location
      restore_pos(p);
      return 1;
   }
#endif

   restore_pos(p2);
   // put cursor on first non-blank character before the cursor
   for (;;) {
      _begin_line();
      _first_non_blank();
      if (p_col!=1) {
         if (p_line==orig_linenum && orig_col<=p_col) {
            status=up();
            if (status) {
               restore_pos(p);
               return 1;
            }
            continue;
         }
         break;
      }
      ch=get_text();
      if (ch:==' ' || ch:=="\t" || p_col>_line_length()) {
         status=up();
         if (status) {
            restore_pos(p);
            return 1;
         }
         continue;
      }
      break;
   }
   /*if (p_line<orig_linenum || (p_line==orig_linenum && orig_col<=p_col)) {
      restore_pos(p);
      return 1;
   } */
   col := p_col;
   restore_pos(p);
   return(col);
}
static int clojure_indent_col(int non_blank_col)
{
   orig_col := p_col;
   orig_linenum := p_line;
   int col=orig_col;

   save_pos(auto p);
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   int syntax_indent=p_SyntaxIndent;
   if ( syntax_indent<=0) {
      // Find non-blank-col
      return(NoSyntaxIndentCase(non_blank_col,orig_linenum,orig_col,p,0));
   }
   be_style := p_begin_end_style;


   // locals
   cfg := 0;
   ch := "";
   line := "";

   _str enter_cmd=name_on_key(ENTER);
   if (enter_cmd=='nosplit-insert-line') {
      _end_line();
   }

   if (p_col==1) {
      up();_end_line();
   } else {
      left();
   }
   typeless ss1,ss2,ss3,ss4, ss5;

   //search_text := '[{;}()\[\]]';
   search_text := '[{;}:()\[\]]';

   status := search(search_text,"@rh-xcs");
   searchCount := 0;

   for (;;) {
      searchCount++;
      if (status) {
         return(NoSyntaxIndentCase(non_blank_col,orig_linenum,orig_col,p,syntax_indent));
      }

      /*cfg=_clex_find(0,'g');
      if (cfg==CFG_COMMENT || cfg==CFG_STRING) {
         status=repeat_search();
         continue;
      } */
      ch=get_text();
      //messageNwait('ch='ch);
      switch (ch) {
      case ']':
      case '}':
      case ')':
         save_search(ss1,ss2,ss3,ss4, ss5);
         status = find_matching_paren(true);
         restore_search(ss1,ss2,ss3,ss4,ss5);
         if (status) {
            return(NoSyntaxIndentCase(non_blank_col,orig_linenum,orig_col,p,syntax_indent));
         }
         if (p_col==1) {
            restore_pos(p);
            return 1;
            //up();_end_line();
         } else { 
            left();
         }
         status =search(search_text,"@rh-xcs");
         continue;
      case '[':
      case '{':
         col= p_col+1;
         restore_pos(p);
         return col;
      case '(':
         {
            col=p_col;
            paren_linenum:=p_line;
            //save_pos(p3);
            /*
               Cases
                  1        (function-name param1 <enter>param2)
                     want  (function-name param1
                                          param2)
                  1        (function-name <enter>param1 param2)
                     want  (function-name
                                param1 param2)
             
            */
            right();

            save_search(ss1,ss2,ss3,ss4, ss5);
            // Search for start of function name
            status=search('[^ \t]','rh@');
            // If definitely didn't find function name
            if (status) {
               restore_search(ss1,ss2,ss3,ss4,ss5);
               restore_pos(p);
               return col+1;   // start of ( +1
            }
            //  IF function name is on next line
            if (p_line!=paren_linenum) {
               restore_search(ss1,ss2,ss3,ss4,ss5);
               restore_pos(p);
               return col+syntax_indent;   // start of ( syntax_indent
            }
            ch=get_text();
            if (pos(ch,'()[]{}#"\,;')) {
               restore_search(ss1,ss2,ss3,ss4,ss5);
               restore_pos(p);
               return col+syntax_indent;   // start of ( syntax_indent
            }
            function_name_linenum:=p_line;
            cfg=_clex_find(0,'g');
            // Now skip the function name
            status=search('{[^ \t,;\\)]@}([ \t,;)\\]|$)','rh@');
            // IF hit end of file OR hit end of line
            if (status) {
               restore_search(ss1,ss2,ss3,ss4,ss5);
               restore_pos(p);
               return col+syntax_indent;
            }
            fun_name:=get_text(match_length('0'),match_length('S0'));
            p_col+=length(fun_name);
            lp:=lastpos('/',fun_name);
            if (lp) {
               fun_name=substr(fun_name,lp+1);
            }
            bool use_continuation_indent=LanguageSettings.getUseContinuationIndentOnFunctionParameters(p_LangId)!=0;
            _str option;
            temp:=' 'LanguageSettings.getUseContinuationIndentOnFunctionParametersList(p_LangId)' ';
            temp=translate(temp,'  ',"\r\n");
            parse temp with (' 'fun_name' ') option .;
            if (option!='') {
               use_continuation_indent=option=='1';
            }
            // IF cursor was within function name
            if (orig_linenum==p_line && orig_col<p_col) {
               restore_search(ss1,ss2,ss3,ss4,ss5);
               restore_pos(p);
               return col+syntax_indent;
            }
            ch=get_text();
            if (match_length() && (ch:==' ' || ch:=="\t" || ch:==',')) {
               // Skip space/tab/comma after function name
               right();
               // Find start of second parameter
               status=search('[^ \t]|$','rh@');
               // If no first parameter
               if (status) {
                  restore_search(ss1,ss2,ss3,ss4,ss5);
                  restore_pos(p);
                  return col+syntax_indent;
               }
            }

            if (p_col>_text_colc()) {
               // Pretent there's a comment after function name to
               // make use of same code path below
               ch=';';
            } else {
               ch=get_text();
               // IF no parameters specified
               if (ch==')') {
                  restore_search(ss1,ss2,ss3,ss4,ss5);
                  restore_pos(p);
                  return col+syntax_indent;
               }
            }
            // IF have comment after function name on same line or first parameter not on same line as function name
            if (ch==';') {
               for (;;) {
                  status=down();
                  // IF no text after function name
                  if (status) {
                     restore_search(ss1,ss2,ss3,ss4,ss5);
                     restore_pos(p);
                     return col+syntax_indent;   // start of ( syntax_indent
                  }
                  // skip blank lines
                  get_line(auto line2);
                  if (line2!='') break;
               }
               _begin_line();
               _first_non_blank();
               ch=get_text();
               // No first function parameter
               if (ch==')') {
                  restore_search(ss1,ss2,ss3,ss4,ss5);
                  restore_pos(p);
                  return col+syntax_indent;
               }
               // No first function parameter
               if (ch=='' || ch:=="\n" || ch:=="\r") {
                  restore_search(ss1,ss2,ss3,ss4,ss5);
                  restore_pos(p);
                  return col+syntax_indent;
               }
               if (use_continuation_indent || orig_linenum<p_line || (orig_linenum==p_line && orig_col<=p_col)) {
                  restore_search(ss1,ss2,ss3,ss4,ss5);
                  restore_pos(p);
                  return col+syntax_indent;
               }
               // Align parameters with first non-blank parameter
               restore_search(ss1,ss2,ss3,ss4,ss5);
               col=p_col;
               restore_pos(p);
               return col;
            }
            // At start of first parameter
            if (use_continuation_indent) {
               restore_search(ss1,ss2,ss3,ss4,ss5);
               restore_pos(p);
               return col+syntax_indent;
            }
            // IF first parameter is on same line as function name
            if (p_line==function_name_linenum) {
               if (orig_linenum<p_line || (orig_linenum==p_line && orig_col<=p_col)) {
                  restore_search(ss1,ss2,ss3,ss4,ss5);
                  restore_pos(p);
                  return col+syntax_indent;
               }
               // Align parameters with first non-blank parameter
               restore_search(ss1,ss2,ss3,ss4,ss5);
               col=p_col;
               restore_pos(p);
               return col;
            }

            restore_search(ss1,ss2,ss3,ss4,ss5);
            restore_pos(p);
            return col+syntax_indent;   // start of ( syntax_indent
         }
         continue;
      default:
      }
      status=repeat_search();
   }

}
static int clojure_enter_col2(var enter_col,bool pasting_open_block=false) {
   enter_col=clojure_indent_col(enter_col/*,pasting_open_block*/);
   return 0;
}
static clojure_enter_col(typeless pasting_open_block=false)
{
   typeless enter_col=0;
   if ( command_state() || p_window_state:=='I' ||
      p_SyntaxIndent<0 || p_indent_style!=INDENT_SMART ||
      clojure_enter_col2(enter_col/*,pasting_open_block*/) ) {
      return('');
   }
   return(enter_col);
}

int clojure_smartpaste(bool char_cbtype,int first_col,int Noflines,bool allow_col_1=true)
{
   typeless comment_col='';
   //If pasted stuff starts with comment and indent is different than code,
   // do nothing.
   // Find first non-blank line
   first_line := "";
   save_pos(auto p4);
   i := j := 0;
   for (j=1;j<=Noflines;++j) {
      get_line(first_line);
      i=verify(first_line,' '\t);
      if ( i ) {
         p_col=text_col(first_line,i,'I');
      }
      if (i) {
         break;
      }
      if(down()) {
         break;
      }
   }
   comment_col=p_col;
   if (j>1) {
      restore_pos(p4);
   }

   // Look for first piece of code not in a comment
   typeless status=_clex_skip_blanks('m');
   /*
      The first part of the if expression was commented out because it messed
      up smarttab for the case below:
      foo() {
         if(i<j) {
            while(i<j) {
      <Cursor in column 1>
            }
         }
      }

   */

   // IF //(no code found /*AND pasting comment */AND comment does not start in column 1) OR
   //   (code found AND pasting comment AND code col different than comment indent)
   //  OR  first non-blank code of pasted stuff is preprocessing
   //  OR first non-blank pasted line starts with non-blank AND
   //     (not pasting character selection OR copied text from column 1)
   if ( // (status /*&& comment_col!='' */&& comment_col<=1)
        (!status && comment_col!='' && p_col!=comment_col)
       //|| (!status && get_text()=='#')
       //|| (substr(first_line,1,1)!='' && (!char_cbtype ||first_col<=1))
       ) {
      return(0);
   }
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE | AFF_INDENT_CASE);
   int syntax_indent=p_SyntaxIndent;
   //indent_case:=beaut_case_indent();

   typeless enter_col=0;
   col := 0;

   //say("smartpaste cur_word="cur_word(word_start));
   
   /*if (!status && get_text()=='}') {
      // IF pasting stuff contains code AND first char of code }
      ++p_col;
      enter_col=c_endbrace_col();
      if (!enter_col) {
         enter_col='';
      }
      _begin_select();up();
   } else*/ 
   {
      /*  Need to know if we are pasting an open brace. */
      pasting_open_block := false;
      // The new c_enter_col always wants to know if we are
      // pasting and open brace.
      /*if (!status && get_text()=='{' /*&& (be_style & STYLE1_FLAG)*/) {
         pasting_open_block=true;
      } */
      _begin_select();up();
      _end_line();
      enter_col=clojure_enter_col(pasting_open_block);
      status=0;
   }
   //IF no code found/want to give up OR ... OR want to give up
   if (status || enter_col=='' || (enter_col==1 && !allow_col_1)) {
      return(0);
   }
   return(enter_col);
}

defeventtab _clojure_extform;

static void enableDisableButtons()
{
   int selected[];
   ctlUseContOnParametersTree._TreeGetSelectionIndices(selected);
   numSelected := selected._length();

   if (numSelected == 0) {
      ctlremove_function.p_enabled = false;
   } else if (numSelected >=1) {
      ctlremove_function.p_enabled = true;
   }
}
void ctladd_function.lbutton_up() {
   result:=textBoxDialog("Add Function", 0, 0, "", "Add,Cancel:_cancel", "", "Function name:",'-CHECKBOX Use continuation indent:1');
   if (result==COMMAND_CANCELLED_RC) {
      return;
   }
   fun_name:=_param1;
   option:=_param2;
   caption:=fun_name"\t"option;
   index:=ctlUseContOnParametersTree._TreeAddItem(TREE_ROOT_INDEX,caption,TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF, 0);
   ctlUseContOnParametersTree._TreeSetSwitchState(index,1,option==1?true:false);
   ctlUseContOnParametersTree._TreeSortCol(0,'I');
   index=ctlUseContOnParametersTree._TreeSearch(TREE_ROOT_INDEX,caption);
   if (index>=0) {
      ctlUseContOnParametersTree._TreeSetCurIndex(index);
   }
   enableDisableButtons();
   
}
void ctlremove_function.lbutton_up()
{
   // figure out which tree we want
   treeWid := _control ctlUseContOnParametersTree;

   // get a whole list of selected stuff
   int selected[];
   treeWid._TreeGetSelectionIndices(selected);

   if (selected._length() == 0) return;

   // figure out what to select after we get rid of stuff
   newSelection := -1;
   if (selected._length() == 1) {
      newSelection = treeWid._TreeGetNextSiblingIndex(selected[0]);
      if (newSelection < 0) {
         newSelection = treeWid._TreeGetPrevSiblingIndex(selected[0]);
      }
   }

   for (i := 0; i < selected._length(); i++) {
      // get the index and rip it out
      treeWid._TreeDelete(selected[i]);
   }

   // if we haven't set up something to select, just pick the top thing
   if (newSelection < 0) {
      newSelection = treeWid._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   }
   treeWid._TreeDeselectAll();

   if (newSelection > 0) {
      treeWid._TreeSelectLine(newSelection);
   } 

   //ADVANCED_FILE_TYPES_MODIFIED(true);
   enableDisableButtons();
}
void _clojure_extform.on_resize() {

   int y=p_active_form.p_height;
   if (y>ctlUseContOnParametersTree.p_y) {
      ctlUseContOnParametersTree.p_height=y-ctlUseContOnParametersTree.p_y;
   }
   int x=p_active_form.p_width;
   if (x>ctlUseContOnParametersTree.p_x*2) {
      ctlUseContOnParametersTree.p_width=x-ctlUseContOnParametersTree.p_x-ctlUseContOnParametersTree.p_x;
      colSlice := p_active_form.p_width intdiv 2;
      ctlUseContOnParametersTree._TreeSetColButtonInfo(0, colSlice, 0, 0, 'Function Name');
      //ctlUseContOnParametersTree._TreeSetColEditStyle(0,TREE_EDIT_TEXTBOX);
      ctlUseContOnParametersTree._TreeSetColButtonInfo(1, colSlice, 0, 0, 'Use Continuation Indent');
      ctlUseContOnParametersTree._TreeSetColEditStyle(1,TREE_EDIT_BUTTON);
   }
   alignUpDownListButtons(ctlUseContOnParametersTree.p_window_id, 
                          ctlUseContOnParametersTree.p_x_extent + 30,
                          ctladd_function.p_window_id, 
                          ctlremove_function.p_window_id);
}
_str _clojure_extform_get_value(_str controlName, _str langId)
{
   _str value = null;

   switch (controlName) {
   case 'ctlUseContOnParametersTree':
      value=LanguageSettings.getUseContinuationIndentOnFunctionParametersList(langId);
      break;
   default:
      value = _language_formatting_form_get_value(controlName, langId);
   }

   return value;
}
bool _clojure_extform_apply()
{
   _language_form_apply(_clojure_extform_apply_control);

   return true;
}
_str _clojure_extform_apply_control(_str controlName, _str langId, _str value)
{
   updateString := '';

   switch (controlName) {
   case 'ctlUseContOnParametersTree':
      LanguageSettings.setUseContinuationIndentOnFunctionParametersList(langId,value);
      break;
   default:
      updateString = _language_formatting_form_apply_control(controlName, langId, value);
   }

   return value;
}
void _clojure_extform_init_for_options(_str langId) {

   _language_form_init_for_options(langId, _clojure_extform_get_value,
                                   _language_formatting_form_is_lang_included);
   enableDisableButtons();
}

/**
 * Set to the path to 'cargo' executable. 
 *
 * @default ""
 * @categories Configuration_Variables
 */
_str def_lein_exe_path;
int _new_clojure_proj(bool inDialog,_str packageName,_str projectName,_str Path, bool add_to_workspace, bool ExecutableName,_str Dependency,bool ShowProperties=false,bool runInitMacros=true)
{
   _nocheck _control ctlProjectNewDir,_new_prjname;
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build system");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   _str filename=path_search('lein',"PATH",'P');
   // IF lein isn't installed and in the PATH
   if (filename=='') {
      _message_box("'lein' executable not found. Please install rust and make sure lein is in your path");
      return(1);
   }
   if (_DebugMaybeTerminate()) {
      return(1);
   }
   msg := "";
   if (projectName=='') {
      msg="You must specify a project name";
      if (inDialog) {
         _new_prjname._text_box_error(msg);
      } else {
         _message_box(msg);
      }
      return(1);
   }
   if (_isWindows()) {
         // pretty much all the characters are allowed on UNIX
      if (iswildcard(projectName)) {
         msg="Invalid filename";
         if (inDialog) {
            _new_prjname._text_box_error(msg);
         } else {
            _message_box(msg);
         }
         return(1);
      }
   }
   if (Path=='') {
      msg="You must specify a project directory";
      if (inDialog) {
         ctlProjectNewDir._text_box_error(msg);
      } else {
         _message_box(msg);
      }
      return(1);
   }
   if (_strip_filename(projectName,'n')!='') {
      msg='Project name must not contain a path';
      if (inDialog) {
         _new_prjname._text_box_error(msg);
      } else {
         _message_box(msg);
      }
      return(1);
   }
   if (pos('[a-zA-Z_$][a-zA-Z_$0-9]@',projectName,1,'r')!=1 || pos('')!=length(projectName)) {
       msg='Project name must be valid identifier';
       if (inDialog) {
          _new_prjname._text_box_error(msg);
       } else {
          _message_box(msg);
       }
       return(1);
   }

   Path=strip(Path,'B','"');
   _maybe_append_filesep(Path);

   // handle special unix paths like "~/"
   if (def_unix_expansion) {
      Path = _unix_expansion(Path);
   }

   Path=absolute(Path);

   ProjectPath := Path:+projectName;
   _maybe_append_filesep(ProjectPath);
   project_already_exists:=false;
   if (isdirectory(ProjectPath)) {
       if (isdirectory(ProjectPath"/src")) {
          // Looks like an existing project created by lein
          filename=file_match("+t "_maybe_quote_filename(ProjectPath"/src/*.clj"),1);
          file_match('',2);
          if (filename!='') {
             project_already_exists=true;
          }
       }
       if (!project_already_exists) {
          _message_box(nls("Directory %s already exists.", ProjectPath), "", MB_OK);
          return 1;
       } else if (file_exists(ProjectPath:+projectName:+WORKSPACE_FILE_EXT)) {
          _message_box(nls("Workspace %s already exists.", ProjectPath:+projectName:+WORKSPACE_FILE_EXT), "", MB_OK);
          return 1;
       }
   }


   createdDirectory := false;
   // Only show project properties if directory does not exist.
   // Moving thing code fixes bug when adding project to workspace.
   status := 0;
   if (!isdirectory(Path)) {
      createdDirectory=true;
      status=_mkdir_chdir(Path);
      if (status) {
         return(status);
      }
   } else {
      cd(Path);
      ShowProperties=true;
   }
   if (!project_already_exists) {
      // run lein to create the lein project files
      status=shell('lein new app 'projectName,'q');
      if (!isdirectory(ProjectPath)) {
          _message_box(nls("Failed to create directory %s.", ProjectPath), "", MB_OK);
          return 1;
      }
   }
   if (inDialog) {
      p_active_form._delete_window(0);
   }

   status=workspace_new_project(false,
                         "Clojure - Lein",
                         projectName,
                         ProjectPath,
                         false,
                         projectName,
                         '',
                         false,
                         false
                         );
   if (!status) {
      workspace_refresh();
   }

   //result:=workspace_open(cargo_toml);

   return status;
   //return setup_rust_proj(configName);
}
static _str guessLeinCompilerExePath()
{
   if( def_lein_exe_path != "" ) {
      // No guessing necessary
      return def_lein_exe_path;
   }
   /*filename := _HomePath()'/.lein/bin/lein'EXTENSION_EXE;
   if (file_exists(filename)) {
       return absolute(filename);
   } */
   if (_isUnix()) {
      filename:= "/usr/local/bin/lein"EXTENSION_EXE;
      if (file_exists(filename)) {
          return absolute(filename);
      }
   }
   return '';
}
static int _lein_set_environment2() {
    _str lein_filename=_orig_path_search('lein');
    if (lein_filename!="") {
        //if (!quiet) {
        //   _message_box('Rust is already setup.  rustc is already in your PATH.');
        //}
        _restore_origenv(true);
        return(0);
    }

    leinExePath := "";
    if( def_lein_exe_path != "" && path_search(def_lein_exe_path,'PATH','P')!='') {
       _restore_origenv(false);
       // Use def_lein_exe_path
       leinExePath = def_lein_exe_path;
    } else {
       _restore_origenv(true);

       for (;;) {
           // Prompt user for interpreter
           int status = _mdi.textBoxDialog("Lein Executable",
                                           0,
                                           0,
                                           "",
                                           "OK,Cancel:_cancel\tSpecify the path and name to 'lein"EXTENSION_EXE"'",  // Button List
                                           "",
                                           "-bf Lein Executable:":+guessLeinCompilerExePath());
           if( status < 0 ) {
              // Probably COMMAND_CANCELLED_RC
              return status;
           }
           if (file_exists(_param1)) {
              break;
           }
           _message_box('lein executable not found. Please correct the path or cancel');
       }

       // Save the values entered and mark the configuration as modified
       def_lein_exe_path = _param1;
       _config_modify_flags(CFGMODIFY_DEFVAR);
       leinExePath = def_lein_exe_path;
    }

    // Make sure we got a path
    if( leinExePath == "" ) {
       return COMMAND_CANCELLED_RC;
    }

    // Set the environment
    //set_env('SLICKEDIT_LEIN_EXE',leinExePath);
    leinDir := _strip_filename(leinExePath,'N');
    _maybe_strip_filesep(leinDir);
    // PATH
    _str path = _replace_envvars("%PATH%");
    _maybe_prepend(path,PATHSEP);
    path = leinDir:+path;
    set("PATH="path);

    // Success
    return 0;
}
int _clojure_set_environment(int projectHandle=-1, _str config="", _str target="",
                            bool quiet=false, _str& error_hint=null)
{
    return _lein_set_environment2();
}

