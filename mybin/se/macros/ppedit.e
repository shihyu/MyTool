////////////////////////////////////////////////////////////////////////////////////
// $Revision: 46648 $
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
#import "context.e"
#import "cutil.e"
#import "files.e"
#import "listproc.e"
#import "main.e"
#import "picture.e"
#import "proctree.e"
#import "savecfg.e"
#import "saveload.e"
#import "sellist.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "tags.e"
#import "tbclass.e"
#import "wkspace.e"
#endregion

/////////////////////////////////////////////////////////////////////
// This module implements the ppedit editor dialog box which is
// used for editing the values of C proprocessor macros to be
// expanded inline by the C language tagging engine.
//
// Controls on '_c_ppedit_form'
//
//    ctl_macro_name
//    ctl_macros_tree
//    ctl_divider
//    ctl_macro_edit
//    ctl_ok_btn
//    ctl_new_btn
//    ctl_delete_btn
//    ctl_cancel_btn
//    ctl_help_btn
//


//////////////////////////////////////////////////////////////////////////////
// mildly complicated regular expression for identifiers and macros
//
#define CM_ID_REGEX     '[$_a-zA-Z][_$a-zA-Z0-9]@'
#define CM_VARARG_REGEX '(|\.\.\.|,\.\.\.)'
#define CM_MACRO_REGEX  CM_ID_REGEX'(\((|('CM_ID_REGEX', *)*'CM_ID_REGEX')'CM_VARARG_REGEX'\)):0,1'


//////////////////////////////////////////////////////////////////////////////
// global variables
//
static int gi_pic_define;       // index of picture used for #defines
static int gi_pic_undef;        // index of picture used for #undefs
static int gi_ppedit_wid;       // window ID for c_ppedit_form
static int gi_curr_macro;       // index of current macro in tree
static boolean gi_modify_flag;  // nonzero if the current macro is modified
/*
    picture id
    gi_pic_define  #define
    gi_pic_undef   #undef
    0              #delete
*/
static int gusercpp_hashtab:[];


/*
    Original tree index of define in syscpp.h
*/
static int gsyscpp_hashtab:[];


/////////////////////////////////////////////////////////////////////
// main entry point, command to display dialog for editing macros
//
_command ppedit()
{
   _macro_delete_line();
   typeless result = show('-xy _c_ppedit_form');
   if (result == '') {
      return(COMMAND_CANCELLED_RC);
   }
}

// Return path to system C macro preprocessing configuration file
_str _c_sys_ppedit_path(...)
{
   // look for system CPP definitions file
   return get_env('VSROOT'):+SYSCPP_FILE;
}

// Return path to C macro preprocessing configuration file
_str _c_user_ppedit_path(...)
{
   // look for local CPP definitions file
   _str path = _ConfigPath():+USERCPP_FILE;
   return file_exists(path)? path : '';
}
//////////////////////////////////////////////////////////////////////////////
// Called when this module is loaded (before defload).  Used to
// initialize the timer variable and window IDs.
//
definit()
{
   // IF editor is initalizing from invocation
   if (arg(1)!='L') {
      gi_ppedit_wid = 0;
      gi_modify_flag = false;
      gi_curr_macro  = 0;
   }
}

//////////////////////////////////////////////////////////////////////////////
// Called when this module is loaded (after definit).  Used to
// correctly initialize the window IDs (if those forms are available),
// and loads the array of pictures used for different tag types.
//
defload()
{
   gi_ppedit_wid = 0;
   gi_modify_flag = false;
   gi_curr_macro  = 0;

   // try to find the macro editor form
   int gi_ppedit_form = _find_formobj("_c_ppedit_form","n");

   // load the picture for #define
   int status = _update_picture(-1,"_clsdef0.ico");
   if (status < 0) {
      _message_box(nls('Unable to load picture "_clsdef0.ico"')'. 'get_message(status));
   } else {
      gi_pic_define = status;
   }
   status = _update_picture(-1,"_clsund0.ico");
   if (status < 0) {
      _message_box(nls('Unable to load picture "_clsund0.ico"')'. 'get_message(status));
   } else {
      gi_pic_undef = status;
   }
}


/////////////////////////////////////////////////////////////////////
// update the incremental editor control containing the macro definition
//
static void cm_edit_macro_definition(int tx, _str macro_value)
{
   // parse it out line-by-line and insert into output buffer
   tx.delete_all();
   _str curr_line="";
   while (macro_value != '') {
      parse macro_value with curr_line "\n" macro_value;
      tx.insert_line(curr_line);
   }

   // position cursor
   tx.top();
   do { tx._lineflags(0, MODIFY_LF); } while (!down);
   tx.top();
   tx.begin_line();
   tx.p_modify = false;

   tx.refresh();
}

// get the (possibly edited) macro value from the editor control
static _str cm_get_macro_definition(int tx)
{
   // parse it out line-by-line and insert into output buffer
   typeless p;
   tx.save_pos(p);
   tx.top();
   _str line="";
   _str macro_value="";
   tx.get_line(macro_value);
   typeless status = tx.down();
   while (status != BOTTOM_OF_FILE_RC) {
      tx.get_line(line);
      if (last_char(macro_value):=='\') {
         //Just in case a user is putting in the continuation chars by hand.
         macro_value=substr(macro_value,1,length(macro_value)-1);
      }
      macro_value = macro_value "\n" line;
      status = tx.down();
   }

   // position cursor
   tx.restore_pos(p);
   return macro_value;
}

// validate input in new macro box, for different macro forms
//    id
//    id()
//    id(a)
//    id(a1,a2,...,an)
int cm_valid_macro_name(_str arg1, int t)
{
   // not valid syntaticly?
   if (!pos('^'CM_MACRO_REGEX'$', arg1, 1, 'ir')) {
      _message_box("Invalid macro name: " :+ arg1 :+
                   "\nMacros must be of the form identifier[(a1,a2,...an)]");
      return 1;
   }

   // if t isn't valid, we are done with our checks
   if (t < 0) {
      return 0;
   }

   // is this macro already in the tree
   int p = pos('^'CM_ID_REGEX, arg1, 1, 'ir');
   int n = pos('');
   _str macro_name = substr(arg1, p, n);
   int foundIndex = t._TreeSearch(TREE_ROOT_INDEX, macro_name, 'P');
   while (foundIndex > 0) {
      _str caption = t._TreeGetCaption(foundIndex);
      p = pos('^'CM_ID_REGEX, caption, 1, 'ir');
      n = pos('');
      _str found_name = substr(caption, p, n);
      if (found_name :== macro_name) {
         _message_box("Macro " :+ macro_name :+ " is already defined.");
         return 1;
      }
      foundIndex = t._TreeGetNextSiblingIndex(foundIndex);
      if (foundIndex > 0) {
         foundIndex = t._TreeSearch(foundIndex, macro_name, 'SP');
      }
   }

   // success
   return 0;
}

// look up the given macro name in tag file to get initial value
static int cm_find_define(_str &macro_name, _str &macro_value)
{
   macro_value="";
   // list of macro definitions
   _str define_list[];


   // add in the original macro definition if it had args

   // extract tag name and arguments
   _str macro_args, tag_name, tag_type, tag_args;
   parse macro_name with macro_name '(' macro_args ')';

   if (macro_args != '') {
      define_list[define_list._length()] = "#define "macro_name"("macro_args")";
   } else {
      define_list[define_list._length()] = "#define "macro_name;
   }

   // for each 'C' tag file in search path
   _str define_string = "";
   typeless tag_files=tags_filenamea('c');
   int i=0;
   int status=0;
   _str tag_filename=next_tag_filea(tag_files,i,false,true);
   while (tag_filename != '') {
      // try to find the tag
      status = tag_find_equal(macro_name, 0 /*case sensitive*/);
      // check if we found the right macro name
      while (!status) {
         // check if tag_name is right case
         tag_get_detail(VS_TAGDETAIL_type, tag_type);
         if (tag_type :== 'define') {
            tag_get_detail(VS_TAGDETAIL_name, tag_name);
            tag_get_detail(VS_TAGDETAIL_arguments, tag_args);
            tag_get_detail(VS_TAGDETAIL_return, macro_value);
            if (tag_args != '') {
               define_string = "#define "tag_name"("tag_args")\t"macro_value;
            } else {
               define_string = "#define "tag_name"\t"macro_value;
            }
            define_list[define_list._length()] = define_string;
         }
         // next tag please
         status = tag_next_equal(0 /*case sensitive*/);
      }
      // next tag file please...
      tag_reset_find_tag();
      tag_filename=next_tag_filea(tag_files,i,false,true);
   }

   // blow out of here if there was no match
   if (define_list._length() == 0) {
      macro_value='';
      if (macro_args != '') {
         macro_name = macro_name '(' macro_args ')';
      }
      return 1;
   }


   // sort the list and remove duplicate entries
   define_list._sort("",1);
   _aremove_duplicates(define_list,0);

   // make user choose their favorite macro definition
   define_string=define_list[0];
   if (define_list._length()>=2) {
      _str option='-reinit';
      if (_find_object('_sellist_form')) {
         option='-new';
      }
      define_string=show('_sellist_form -mdi -modal 'option,
                         nls('Select a Macro Definition'),
                         SL_SELECTCLINE,
                         define_list,
                         '',
                         '',  // help item name
                         '',  // font
                         ''   // Call back function
                         );
      if (define_string=="") {
         return(1);
         /*macro_value='';
         if (macro_args != '') {
            macro_name = macro_name '(' macro_args ')'
         }
         return(0);*/
      }
   }

   // break up the string
   parse define_string with "#define " macro_name "\t" macro_value;

   // that's all folks
   return 0;
}


// read one #define macro
int cm_load_macro(_str &macro_name, _str &macro_value,int &pic)
{
   // no more #define's found?
   typeless p1,p2,p3,p4;
   save_search(p1,p2,p3,p4);
   if (search('^ *(\# *(define|undef|delete)|/[/*])','@rh')) {
      restore_search(p1,p2,p3,p4);
      return 0;
   }

   // get the contents of the line and remove "#define"
   macro_value='';
   _str line="";
   get_line(line);

   // parse out comments
   typeless status=0;
   while (status!=BOTTOM_OF_FILE_RC && (line=='' || pos('^ */[/*]', line, 1, 'r'))) {
      if (pos('^ */[*]', line, 1, 'r')) {
         while (status!=BOTTOM_OF_FILE_RC && !pos('*/',line)) {
            macro_value=macro_value :+ line "\n";
            status=down();
            get_line(line);
         }
         if (pos('*/',line)) {
            typeless junk;
            parse line with line "*/" junk;
            macro_value=macro_value :+ line "*/\n";
            line=junk;
            if (strip(junk)=='') {
               status=down();
               get_line(line);
            }
         }
      } else {
         macro_value=macro_value :+ line "\n";
         status=down();
         get_line(line);
      }
   }

   // parse out the #define statement
   if (pos('^ *\# *{define|undef|delete} #', line, 1, 'r')) {
      _str word= substr(line,pos('S0'),pos('0'));
      if (word=='define') {
         pic=gi_pic_define;
      } else if (word=='undef') {
         pic=gi_pic_undef;
      } else {
         pic=0;
      }
      line = substr(line, pos('')+1);

      // pull out macro and arguments
      int p = pos('^'CM_MACRO_REGEX, line, 1, 'ir');
      if (!p) {
         p = pos('^'CM_ID_REGEX, line, 1, 'ir');
      }
      if (p) {
         int n = pos('');
         macro_name = substr(line, p, n);
         line = substr(line, n+1);
         line = strip(line, 'L');

         // read in the rest of the line
         p = pos(' @[\\]$', line, 1, 'r');
         while (p > 0) {
            macro_value = macro_value :+ substr(line, 1, p-1) :+ "\n";
            down();
            get_line(line);
            p = pos(' @[\\]$', line, 1, 'r');
         }
         macro_value = macro_value :+ line;

         // found something, macro_value and macro_name are set
         restore_search(p1,p2,p3,p4);
         return 1;
      }
   }

   // something went wrong
   restore_search(p1,p2,p3,p4);
   return 0;
}

// Load the macro definitions file
static int cm_load_macro_definitions(int t, _str filename,boolean isUserCPP)
{
   // open the file int temporary buffer for reading
   mou_hour_glass(1);
   int orig_view_id=p_window_id;
   int macro_view_id=0;
   int status=_open_temp_view(filename,macro_view_id,orig_view_id);
   if (status) {
      p_window_id=orig_view_id;
      mou_hour_glass(0);
      return status;
   }
#if 0
   boolean inmem=1;
   status=_open_temp_view(filename,macro_view_id,orig_view_id,' +b ');
   if (status) {
      inmem=0;
      status=_open_temp_view(filename,macro_view_id,orig_view_id);
      if (status) {
         p_window_id=orig_view_id;
         mou_hour_glass(0);
         return status;
      }
   }
#endif


   //t._TreeDelete(TREE_ROOT_INDEX, 'c');  // clear the tree

   // read the file, this will be *real* fun...
   p_window_id=macro_view_id;
   top();up();

   int i=0;
   _str macro_name="";
   _str macro_value="";
   _str justName="";
   int pic=0;
   if (isUserCPP) {
      for (;;) {
         // read one macro definition and insert into tree
         if (cm_load_macro(macro_name, macro_value,pic)) {
            if (pic) {
               // #undef or #define
               parse macro_name with justName'(';
               gusercpp_hashtab:[justName]=pic;
               i = t._TreeAddItem(TREE_ROOT_INDEX, macro_name, TREE_ADD_AS_CHILD, pic, pic, TREE_NODE_LEAF, 0, macro_value);
            } else {
               justName=macro_name;
               gusercpp_hashtab:[justName]=0;
            }
            int *pi;
            pi=gsyscpp_hashtab._indexin(justName);
            if (pi) {
               t._TreeDelete(*pi);
            }
         }

         // next please
         if (down() == BOTTOM_OF_FILE_RC) break;
      }
   } else {
      for (;;) {
         // read one macro definition and insert into tree
         if (cm_load_macro(macro_name, macro_value,pic)) {
            parse macro_name with justName'(';
            i = t._TreeAddItem(TREE_ROOT_INDEX, macro_name, TREE_ADD_AS_CHILD, pic, pic, TREE_NODE_LEAF, 0, macro_value);
            gsyscpp_hashtab:[justName]=i;
         }
         // next please
         if (down() == BOTTOM_OF_FILE_RC) break;
      }
   }

   _delete_temp_view(macro_view_id);
   p_window_id=orig_view_id;

   // that's all folks
   mou_hour_glass(0);
   return(0);
}

// write the given macro to the current buffer
int cm_save_macro(_str macro_name, _str macro_value,int pic)
{
   // skip over leading blank lines
   _str line="";
   _str rest="";
   parse macro_value with line "\n" macro_value;
   while (line == '' && macro_value != '') {
      parse macro_value with line "\n" macro_value;
   }

   // collect leading comments
   while ((macro_value != '' && line=='') || pos("^ */[/*]", line, 1, 'r')) {
      if (pos('^ */[*]', line, 1, 'r')) {
         while (!pos('*/', line)) {
            insert_line(line);
            if (macro_value=='') break;
            parse macro_value with line "\n" macro_value;
         }
         parse line with line "*/" rest;
         insert_line(line"*/");
         line = rest;
         if (strip(line) == '') {
            parse macro_value with line "\n" macro_value;
         }
      } else {
         insert_line(line);
         parse macro_value with line "\n" macro_value;
      }
   }

   // parse #define line-by-line and insert into output buffer
   _str curr_line="";
   if (pic==gi_pic_define) {
      curr_line = "#define "macro_name" "line;
   } else {
      curr_line = "#undef "macro_name" "line;
   }
   while (macro_value != '') {
      insert_line(curr_line" \\");
      parse macro_value with curr_line "\n" macro_value;
   }
   insert_line(curr_line);
   insert_line('');
   return 0;
}

// Save the macro definitions file
static int cm_save_macro_definitions(int t, _str macrofilename)
{
   typeless junk=0;
   int macro_view_id=0;
   int orig_view_id=0;
   get_window_id(orig_view_id);
   // look for local CPP definitions file
   if (macrofilename._isempty() || macrofilename=='') {
      macrofilename=USERCPP_FILE;
   }
   _str filename= _ConfigPath():+ macrofilename;

   // open the file, might have to create new file
   mou_hour_glass(1);
   int status=_open_temp_view(filename,macro_view_id,junk);
   if (status) {
      orig_view_id=_create_temp_view(macro_view_id);
      p_buf_name=filename;
      p_UTF8=_load_option_UTF8(p_buf_name);
   }

   p_window_id=macro_view_id;

   // traverse tree control and write macro definitions
   _str macro_name = "";
   _str macro_value = "";
   _str justName = "";
   int ShowChildren=0;
   int bm_index=0;
   delete_all();
   int index = t._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (index > 0) {
      // get information out of tree control
      macro_name  = t._TreeGetCaption(index);
      macro_value = t._TreeGetUserInfo(index);
      parse macro_name with justName'(';
      if (gusercpp_hashtab._indexin(justName)) {
         t._TreeGetInfo(index,ShowChildren,bm_index);
         cm_save_macro(macro_name, macro_value,bm_index);
      }

      // next please...
      index = t._TreeGetNextSiblingIndex(index);
   }

   // Traverse the elements in hash table
   typeless i;
   for (i._makeempty();;) {
      boolean *p;
      p=&gusercpp_hashtab._nextel(i);
      if (i._isempty()) break;
      // IF this is an #undef
      if (!*p) {
         insert_line("#delete "i);
         insert_line("");
      }
   }

   // save the file, it will go in the users local search path
   status=_save_config_file(filename);
   if (status) {
      _message_box(nls("Could not save file %s.\n\n%s",filename,get_message(status)));
      return(status);
   }
   _delete_temp_view(macro_view_id);
   p_window_id=orig_view_id;

   _actapp_cparse();
   mou_hour_glass(0);
   return(status);
}

// update the macro currently being edited if needed
static void cm_update_macro_definition(int e, int t, int u)
{
   if (e.p_modify == true && gi_curr_macro > 0) {
      _str macro_value = cm_get_macro_definition(e);
      _str old_value = t._TreeGetUserInfo(gi_curr_macro);
      if (macro_value :!= old_value) {
         t._TreeSetUserInfo(gi_curr_macro, macro_value);
         gi_modify_flag = true;

         // if it's changed, add it to the userdef file
         _str macro_name =ctl_macros_tree._TreeGetCaption(gi_curr_macro);
         _str justName="";
         parse macro_name with justName '(';
         if (!u.p_value) gusercpp_hashtab:[justName]=gi_pic_define;
         else gusercpp_hashtab:[justName]=gi_pic_undef;
      }
      e.p_modify = false;
   }
}


/////////////////////////////////////////////////////////////////////
// Events handled by the dialog editor
//
defeventtab _c_ppedit_form;

#region Options Dialog Helper Functions

void  _c_ppedit_form_init_for_options()
{
   ctl_ok_btn.p_visible = false;
   ctl_cancel_btn.p_visible = false;
   ctl_help_btn.p_visible = false;
   ctl_delete_btn.p_x = ctl_new_btn.p_x;
   ctl_new_btn.p_x = ctl_ok_btn.p_x;
}

int _c_ppedit_form_save_state()
{
   _nocheck _control ctl_macro_edit;
   _nocheck _control ctl_macros_tree;
   _nocheck _control ctlundef;
   cm_update_macro_definition(ctl_macro_edit, ctl_macros_tree, ctlundef);

   // everything is cool
   return 0;
}

boolean _c_ppedit_form_is_modified()
{
   return gi_modify_flag;
}

void RetagCppBuffers()
{
   // Reset the modify flags for all "C/C++" buffers
   orig_window := p_window_id;
   activate_window(VSWID_HIDDEN);
   _safe_hidden_window();
   orig_buf_id := p_buf_id;
   for (;;) {
      if (_LanguageInheritsFrom('c',p_LangId)) {
         p_ModifyFlags &= ~( MODIFYFLAG_TAGGED                 |
                             MODIFYFLAG_BGRETAG_THREADED          |
                             MODIFYFLAG_CONTEXT_THREADED         |
                             MODIFYFLAG_LOCALS_THREADED        |
                             MODIFYFLAG_PROCTREE_UPDATED       |
                             MODIFYFLAG_CONTEXT_UPDATED        |
                             MODIFYFLAG_LOCALS_UPDATED         |
                             MODIFYFLAG_FCTHELP_UPDATED        |
                             MODIFYFLAG_TAGWIN_UPDATED         |
                             MODIFYFLAG_CONTEXTWIN_UPDATED     |
                             MODIFYFLAG_PROCTREE_SELECTED      |
                             MODIFYFLAG_XMLTREE_UPDATED        |
                             MODIFYFLAG_STATEMENTS_UPDATED     |
                             MODIFYFLAG_AUTO_COMPLETE_UPDATED  |
                             MODIFYFLAG_CLASS_UPDATED          |
                             MODIFYFLAG_CLASS_SELECTED );
      }
      _next_buffer('hr');
      if (p_buf_id == orig_buf_id) {
         break;
      }
   }
   // Finally, update the current buffer, and the tool windows
   // viewing the tagging information for that buffer.
   activate_window(orig_window);
   _UpdateContext(true);
   _UpdateCurrentTag(true);
   _UpdateContextWindow(true);
   _UpdateClass(true);
}

static void RefreshCPPColoring()
{
   orig_view_id := p_window_id;
   first_buf_id := p_buf_id;
   for (;;) {
     _next_buffer('HNR');    /* Must include hidden buffers, because */
                             /* active buffer could be a hidden buffer */
     int buf_id=p_buf_id;
     if ( _LanguageInheritsFrom('c') ) {
        orig_lexer := p_lexer_name;
        p_lexer_name=orig_lexer;
     }
     if ( buf_id== first_buf_id ) {
       break;
     }
   }
   activate_window(orig_view_id);
}

boolean _c_ppedit_form_apply()
{
   // update the macro currently being edited if needed
   _nocheck _control ctl_macro_edit;
   _nocheck _control ctl_macros_tree;
   _nocheck _control ctlundef;
   cm_update_macro_definition(ctl_macro_edit, ctl_macros_tree, ctlundef);

   // save macros to file, if there were modifications
   if (gi_modify_flag) {
      cm_save_macro_definitions(ctl_macros_tree, '');
      gi_modify_flag = false;
      if (!_no_child_windows()) {
         _mdi.p_child.RetagCppBuffers();
      }
      int status = _message_box("Do you want to retag your workspace?",'',
                                MB_YESNO|MB_ICONQUESTION);
      if (status == IDYES) {
         mou_hour_glass(1);
         int orig_wid=p_window_id;
         _str TagFilename = project_tags_filename();
         useThread := _is_background_tagging_enabled(AUTOTAG_LANGUAGE_NO_THREADS);
         RetagFilesInTagFile(TagFilename, true, true, true, false, useThread);
         p_window_id=orig_wid;
         clear_message();
         toolbarUpdateWorkspaceList();
         mou_hour_glass(0);
      }
      if (!_no_child_windows()) {
         _mdi.p_child.RefreshCPPColoring();
      }
   }
   return true;
}
void _c_ppedit_form_cancel()
{
   gi_modify_flag=false;
}

_str _c_ppedit_form_export_settings(_str &file)
{
   error := '';

   ppeditFile := _c_user_ppedit_path();
   if (ppeditFile != '') {
      justPPEditFile := _strip_filename(ppeditFile, 'P');
      if (copy_file(ppeditFile, file :+ justPPEditFile)) error = 'Error copying 'ppeditFile'.';
      else file = justPPEditFile;
   }

   return error;

}

_str _c_ppedit_form_import_settings(_str file)
{
   error := '';

   if (file_exists(file)) {
      ppeditFile := _ConfigPath() :+ USERCPP_FILE;
      if (file_exists(ppeditFile)) {
         if (append_file_contents(file, ppeditFile)) error = 'Error appending values in 'file'.';
      } else if (copy_file(file, ppeditFile)) error = 'Error copying 'file'.';

   } else error :+= 'Error opening 'file'. ';

   return error;
}

#endregion Options Dialog Helper Functions

// form just created, restore state, size, current selection
void ctl_ok_btn.on_create()
{
   gusercpp_hashtab._makeempty();
   gsyscpp_hashtab._makeempty();
   _nocheck _control ctl_macros_tree;

   // load macros from the given file
   gi_ppedit_wid=p_active_form;
   // look for local/global CPP definitions file

   _str filename=_c_sys_ppedit_path();
   if (filename!="") {
      cm_load_macro_definitions(ctl_macros_tree, filename,false);
   }
   filename=_c_user_ppedit_path();
   if (filename!="") {
      cm_load_macro_definitions(ctl_macros_tree, filename,true);
   }
   if (filename=="") {
      filename= _ConfigPath():+USERCPP_FILE;
   }

   // sort the items in the tree by macro name
   ctl_macros_tree._TreeSortCaption(TREE_ROOT_INDEX, 'I');

   p_active_form.p_caption = p_active_form.p_caption ' - ' filename;
   gi_ppedit_wid = 0;
   gi_modify_flag = false;

   // restore position of divider bar
   typeless last_x = _retrieve_value("_c_ppedit_form.ctl_divider.p_x");
   if (!last_x._isempty() && isnumber(last_x)) {
      ctl_divider.p_x = last_x;
   }

   // set up color coding
   ctl_macro_edit._SetEditorLanguage('c');

   // restore currently selected item
   typeless selected_item = _retrieve_value("_c_ppedit_form.ctl_macros_tree.p_user");
   int currIndex;
   currIndex = 0;
   if (!selected_item._isempty()) {
      currIndex = ctl_macros_tree._TreeSearch(TREE_ROOT_INDEX, selected_item);
   }
   if (currIndex <= 0) {
      currIndex = ctl_macros_tree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   }
   if (currIndex > 0) {
      ctl_macros_tree._TreeSetCurIndex(currIndex);
      call_event(CHANGE_SELECTED,currIndex,ctl_macros_tree,ON_CHANGE,'w');
   }
}

// form is destroyed, save state, size, current selection
void _c_ppedit_form.on_destroy()
{
   // update the macro currently being edited if needed
   _nocheck _control ctl_macros_tree;
   _nocheck _control ctl_macro_edit;
   _nocheck _control ctlundef;
   gi_ppedit_wid = p_active_form;
   cm_update_macro_definition(ctl_macro_edit, ctl_macros_tree, ctlundef);

   // get currently selected item
   int currIndex = ctl_macros_tree._TreeCurIndex();
   _str selected_item = '';
   if (currIndex > 0) {
      selected_item = ctl_macros_tree._TreeGetCaption(currIndex);
   }

   // prompt if they want to save
   if (gi_modify_flag && ctl_ok_btn.p_visible) {
      _str title = "";
      _str filename = "";
      parse p_caption with title ' - ' filename;
      int status = _message_box("Save changes to "filename"?",'',MB_YESNO);
      if (status == IDYES) {
         cm_save_macro_definitions(ctl_macros_tree, '');
      }
   }

   // save form settings
   _append_retrieve(0, gi_ppedit_wid.ctl_divider.p_x, "_c_ppedit_form.ctl_divider.p_x");
   _append_retrieve(0, selected_item, "_c_ppedit_form.ctl_macros_tree.p_user");
   gi_ppedit_wid = -1;
   gusercpp_hashtab._makeempty();
   gsyscpp_hashtab._makeempty();
}

// handle horizontal resize bar
ctl_divider.lbutton_down()
{
   int button_width = ctl_ok_btn.p_width;
   int border_width = ctl_macros_tree.p_x;
   int member_width = ctl_macro_edit.p_x + ctl_macro_edit.p_width;
   int divide_width = ctl_divider.p_width;
   _ul2_image_sizebar_handler((button_width+border_width)*2, member_width);
}

// resize form
void _c_ppedit_form.on_resize()
{
   embeddedInOptions := !ctl_ok_btn.p_visible;

   ctl_macros_tree.p_visible=ctl_macro_edit.p_visible=ctlundef.p_visible=ctl_ok_btn.p_visible=ctl_new_btn.p_visible=ctl_delete_btn.p_visible=ctl_cancel_btn.p_visible=ctl_help_btn.p_visible=false;
   //ctlundef.p_visible=ctl_ok_btn.p_visible=ctl_new_btn.p_visible=ctl_delete_btn.p_visible=ctl_cancel_btn.p_visible=ctl_help_btn.p_visible=false;
   // narrow and wide border widths
   int nborder_x = ctl_macros_tree.p_x;
   int nborder_y = ctl_macros_tree.p_y;
   int wborder_x = 2*nborder_x;
   int wborder_y = 2*nborder_y;
   int tborder_x = nborder_x / 2;

   // width/height of OK, Cancel, Help buttons (all are the same)
   int button_width  = ctl_ok_btn.p_width;
   int button_height = ctl_ok_btn.p_height;

   // force size of dialog to remain reasonable
   // if the minimum width has not been set, it will return 0
   if (!embeddedInOptions && !_minimum_width()) {
      _set_minimum_size(button_width*5 + wborder_x*6, button_height*7);
   }

   // available space and border usage
   int avail_x, avail_y, border_x, border_y, div_width;
   avail_x   = _dx2lx(SM_TWIP,p_active_form.p_client_width);
   avail_y   = _dy2ly(SM_TWIP,p_active_form.p_client_height);
   div_width = ctl_divider.p_x;

   // move the macro name and label controls
   ctl_macro_name.p_width   = avail_x - ctl_macros_tree.p_width - 2*wborder_x - nborder_x - tborder_x;
   ctl_macro_name.p_x       = div_width + ctl_divider.p_width + tborder_x + wborder_x;
   ctl_macros_tree.p_width  = div_width - nborder_x;
   ctl_macros_tree.p_height = avail_y - button_height - ctl_macros_tree.p_y- ctlundef.p_height-150;

   // adjust position and size of macro editor panel
   ctl_macro_edit.p_height  = ctl_macros_tree.p_height-(ctl_macro_edit.p_y - ctl_macro_name.p_y);
   ctl_macro_edit.p_width   = avail_x - ctl_macros_tree.p_width - wborder_x - nborder_x - tborder_x;
   ctl_macro_edit.p_x       = div_width + ctl_divider.p_width + tborder_x;
   ctl_divider.p_height     = ctl_macros_tree.p_height;

   // redistribute buttons
   //ctl_ok_btn.p_x     = wborder_x;
   //ctl_help_btn.p_x   = avail_x - wborder_x - button_width;
   //ctl_delete_btn.p_x = (ctl_ok_btn.p_x + ctl_help_btn.p_x) / 2;
   //ctl_new_btn.p_x    = (ctl_ok_btn.p_x + ctl_delete_btn.p_x) / 2;
   //ctl_cancel_btn.p_x = (ctl_delete_btn.p_x + ctl_help_btn.p_x) / 2;

   ctlundef.p_y=ctl_macros_tree.p_y+ctl_macros_tree.p_height+50;
   int button_y=ctlundef.p_y+ctlundef.p_height+50;
   ctl_ok_btn.p_y = button_y;
   ctl_new_btn.p_y = button_y;
   ctl_delete_btn.p_y = button_y;
   ctl_cancel_btn.p_y = button_y;
   ctl_help_btn.p_y = button_y;

   ctl_macros_tree.p_visible=ctl_macro_edit.p_visible=ctlundef.p_visible=ctl_new_btn.p_visible=ctl_delete_btn.p_visible=true;
   if (!embeddedInOptions) {
      ctl_ok_btn.p_visible=ctl_cancel_btn.p_visible=ctl_help_btn.p_visible=true;
   }
   //ctlundef.p_visible=ctl_ok_btn.p_visible=ctl_new_btn.p_visible=ctl_delete_btn.p_visible=ctl_cancel_btn.p_visible=ctl_help_btn.p_visible=true;
}

// apply all changes
void ctl_ok_btn.lbutton_up()
{
   int orig_form = p_active_form;
   _c_ppedit_form_apply();
   // save form settings
   orig_form._delete_window(0);
}

// add a new macro
void ctl_new_btn.lbutton_up()
{
   // update the macro currently being edited if needed
   _nocheck _control ctl_macro_edit;
   _nocheck _control ctl_macros_tree;
   _nocheck _control ctlundef;
   cm_update_macro_definition(ctl_macro_edit, ctl_macros_tree, ctlundef);

   // prompt for macro name
   typeless result=show('-modal _textbox_form',
               'Enter Macro Name',
               0,//Flags,
               '',//Tb width
               '',//help item
               '',//Buttons and captions
               '',//retrieve name
               '-e cm_valid_macro_name:'ctl_macros_tree' -c 'TAG_ARG:+_chr(0)' Macro Name:');
   if (result=='') {
      return;
   }

   // try to find the macro value by looking in the tag database
   macro_name := strip(_param1);
   if (pos("\\(define\\)$", macro_name, 1, 'r') > 0) {
      macro_name = substr(macro_name, 1,  length(macro_name)-8);
   }
   typeless status=cm_find_define(macro_name, auto macro_value);
   if (status) {
      return;
   }

   // update editor
   ctl_macro_name.p_caption = "#define " :+ macro_name;
   cm_edit_macro_definition(ctl_macro_edit, macro_value);

   // add the new macro into the tree
   _str justName = "";
   int currIndex = ctl_macros_tree._TreeAddItem(TREE_ROOT_INDEX, macro_name, TREE_ADD_AS_CHILD|TREE_ADD_SORTED_CI, gi_pic_define, gi_pic_define, TREE_NODE_LEAF, 0, macro_value);
   parse macro_name with justName'(';
   gusercpp_hashtab:[justName]=gi_pic_define;

   ctl_macros_tree._TreeSetCurIndex(currIndex);
   call_event(CHANGE_SELECTED,currIndex,ctl_macros_tree,ON_CHANGE,'w');
   gi_modify_flag = true;

   // they will want to edit this
   ctl_macro_edit._set_focus();
}

void ctlundef.lbutton_up()
{
   int index=ctl_macros_tree._TreeCurIndex();
   if (index>0) {
      gi_modify_flag = true;
      _str macro_value=ctl_macros_tree._TreeGetUserInfo(index);
      _str macro_name =ctl_macros_tree._TreeGetCaption(index);
      int ShowChildren=0, bm_index=0;
      ctl_macros_tree._TreeGetInfo(index,ShowChildren,bm_index);
      _str justName="";
      parse macro_name with justName '(';
      int pic=0;
      if (!p_value) {
         ctl_macro_name.p_caption="#define " :+ macro_name;
         pic=gi_pic_define;
      } else {
         ctl_macro_name.p_caption="#undef ":+justName;
         pic=gi_pic_undef;
      }
      ctl_macros_tree._TreeSetInfo(index,ShowChildren,pic,pic);
      gusercpp_hashtab:[justName]=gi_pic_undef;
   }

}

// delete a macro
void ctl_delete_btn.lbutton_up()
{
   _nocheck _control ctl_macros_tree;
   int currIndex;
   currIndex = ctl_macros_tree._TreeCurIndex();
   if (currIndex <= 0) {
      return;
   }

   // delete current node and update tree position
   gi_curr_macro = 0;
   _str justName = "";
   _str macro_name=ctl_macros_tree._TreeGetCaption(currIndex);
   parse macro_name with justName'(';
   if (gsyscpp_hashtab._indexin(justName)) {
      gusercpp_hashtab:[justName]=0;
   } else {
      gusercpp_hashtab._deleteel(justName);
   }

   /*
      It would be nice if we checked
   */

   ctl_macros_tree._TreeDelete(currIndex);
   gi_modify_flag = true;
   gi_curr_macro = ctl_macros_tree._TreeCurIndex();
   ctl_macros_tree._set_focus();
   call_event(CHANGE_SELECTED,gi_curr_macro,ctl_macros_tree,ON_CHANGE,'W');
}

// select a macro from list
void ctl_macros_tree.on_change(int reason, int index)
{
   // update the macro currently being edited if needed
   _nocheck _control ctl_macro_edit;
   _nocheck _control ctl_macros_tree;
   _str macro_value, macro_name;

   if (reason == CHANGE_LEAF_ENTER || reason == CHANGE_SELECTED) {
      if (index > 0) {
         macro_value=ctl_macros_tree._TreeGetUserInfo(index);
         macro_name =ctl_macros_tree._TreeGetCaption(index);
      } else {
         macro_value=macro_name='';
      }
      cm_update_macro_definition(ctl_macro_edit, ctl_macros_tree, ctlundef);
      int ShowChildren=0, bm_index=0;
      ctl_macros_tree._TreeGetInfo(index,ShowChildren,bm_index);
      if (bm_index==gi_pic_define) {
         ctl_macro_name.p_caption="#define " :+ macro_name;
         ctlundef.p_value=0;
      } else {
         _str name="";
         parse macro_name with name '(';
         ctl_macro_name.p_caption="#undef ":+name;
         ctlundef.p_value=1;
      }
      cm_edit_macro_definition(ctl_macro_edit, macro_value);
      gi_curr_macro=index;

      if (reason==CHANGE_LEAF_ENTER) {
         ctl_macro_edit._set_focus();
      }
   }
}

