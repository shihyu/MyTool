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
#import "guiopen.e"
#import "listproc.e"
#import "main.e"
#import "picture.e"
#import "proctree.e"
#import "projconv.e"
#import "project.e"
#import "savecfg.e"
#import "cfg.e"
#import "saveload.e"
#import "sellist.e"
#import "seltree.e"
#import "setupext.e"
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
//    ctlhidesyscpp
//    ctl_macros_tree
//    ctl_divider
//    ctl_macro_edit
//    ctl_ok_btn
//    ctl_import_btn
//    ctl_new_btn
//    ctl_delete_btn
//    ctl_cancel_btn
//    ctl_help_btn
//


//////////////////////////////////////////////////////////////////////////////
// mildly complicated regular expression for identifiers and macros
//
static const CM_ID_REGEX=     '[$_a-zA-Z][_$a-zA-Z0-9]@';
static const CM_VARARG_REGEX= '(|\.\.\.|,\.\.\.)';
static const CM_MACRO_REGEX=  CM_ID_REGEX'(\((|('CM_ID_REGEX', *)*'CM_ID_REGEX')'CM_VARARG_REGEX'\)):0,1';


//////////////////////////////////////////////////////////////////////////////
// global variables
//
static int gi_pic_define;       // index of picture used for #defines
static int gi_pic_undef;        // index of picture used for #undefs
static int gi_ppedit_wid;       // window ID for c_ppedit_form
static int gi_curr_macro;       // index of current macro in tree
static bool gi_modify_flag;  // nonzero if the current macro is modified

/**
 * Picture index for user defined macro or user-modified macro definition. 
 *  
 * The key in this hash table is just the macro name, because we do not 
 * allow overloaded user macros. 
 *  
 * The value is is a picture index, one of the following: 
 * <ul> 
 *    <li>#define    i_pic_define </li>
 *    <li>#undef     i_pic_undef  </li>
 *    <li>#delete    0            </li>
 * </ul>
 */
static int gusercpp_hashtab:[];

/** 
 * Original tree index of define in syscpp.h 
 *  
 * For a macro with no arguments, the key is just the macro name. 
 * For a macro with arguments, the key is (n), where 'n' 
 * is the number of arguments. 
 * For a variadic marco, the key is (...)
 * 
 * @see cm_make_macro_key(macro_name,justName)
 */
static int gsyscpp_hashtab:[];


/////////////////////////////////////////////////////////////////////
// main entry point, command to display dialog for editing macros
//
_command ppedit(_str userFileName="")
{
   _macro_delete_line();
   langId := "c";
   if (_isEditorCtl()) {
      if (_LanguageInheritsFrom("verilog")) {
         langId = "verilog";
      } else if (_LanguageInheritsFrom("systemverilog")) {
         langId = "systemverilog";
      }
   }
   result := show('-xy -modal _c_ppedit_form', langId, userFileName);
   if (result == '') {
      return(COMMAND_CANCELLED_RC);
   }
}

// Return path to system C macro preprocessing configuration file
_str _c_sys_ppedit_path()
{
   return _getSysconfigMaybeFixPath("tagging":+FILESEP:+"preprocessing":+FILESEP:+SYSCPP_FILE, true);
}

// Return path to C macro preprocessing configuration file
_str _c_user_ppedit_path(bool mustExist=true)
{
   // look for local CPP definitions file
   path := _ConfigPath():+USERCPP_FILE;
   return (!mustExist || file_exists(path))? path : "";
}

// Return path to System Verilog macro preprocessing configuration file
_str _systemverilog_sys_ppedit_path()
{
   return _getSysconfigMaybeFixPath("tagging":+FILESEP:+"preprocessing":+FILESEP:+"systemverilog.svh", true);
}

// Return path to System Verilog user macro preprocessing configuration file
_str _systemverilog_user_ppedit_path(bool mustExist=true)
{
   // look for local CPP definitions file
   path := _ConfigPath():+"usersystemverilog.svh";
   return (!mustExist || file_exists(path))? path : "";
}

// Return path to Verilog macro preprocessing configuration file
_str _verilog_sys_ppedit_path()
{
   return _getSysconfigMaybeFixPath("tagging":+FILESEP:+"preprocessing":+FILESEP:+"verilog.v", true);
}

// Return path to Verilog user macro preprocessing configuration file
_str _verilog_user_ppedit_path(bool mustExist=true)
{
   // look for local CPP definitions file
   path := _ConfigPath():+"userverilog.v";
   return (!mustExist || file_exists(path))? path : "";
}

// Return path to language specific macro preprocessing configuration file
_str _lang_sys_ppedit_path(_str langId)
{
   index := _FindLanguageCallbackIndex("_%s_sys_ppedit_path", langId);
   if (index <= 0 || !index_callable(index)) {
      return "";
   }
   return call_index(index);
}

// Return path to language specific user macro preprocessing configuration file
_str _lang_user_ppedit_path(_str langId, bool mustExist=true)
{
   index := _FindLanguageCallbackIndex("_%s_user_ppedit_path", langId);
   if (index <= 0 || !index_callable(index)) return "";
   return call_index(mustExist, index);
}


//////////////////////////////////////////////////////////////////////////////
// Called when this module is loaded (before defload).  Used to
// initialize the timer variable and window IDs.
//
definit()
{
   // IF editor is initializing from invocation
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

   // load the picture for #define
   gi_pic_define = tag_get_bitmap_for_type(SE_TAG_TYPE_DEFINE);
   gi_pic_undef  = tag_get_bitmap_for_type(SE_TAG_TYPE_UNDEF);
}


/////////////////////////////////////////////////////////////////////
// update the incremental editor control containing the macro definition
//
static void cm_edit_macro_definition(int tx, _str macro_value)
{
   // parse it out line-by-line and insert into output buffer
   tx.delete_all();
   curr_line := "";
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
   line := "";
   macro_value := "";
   tx.get_line(macro_value);
   typeless status = tx.down();
   while (status != BOTTOM_OF_FILE_RC) {
      tx.get_line(line);
      //Just in case a user is putting in the continuation chars by hand.
      _maybe_strip(macro_value, '\');
      macro_value :+= "\n" line;
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
   p := pos('^'CM_ID_REGEX, arg1, 1, 'ir');
   n := pos('');
   macro_name := substr(arg1, p, n);
   foundIndex := t._TreeSearch(TREE_ROOT_INDEX, macro_name, 'PH');
   while (foundIndex > 0) {
      caption := t._TreeGetCaption(foundIndex);
      p = pos('^'CM_ID_REGEX, caption, 1, 'ir');
      n = pos('');
      found_name := substr(caption, p, n);
      if (found_name :== macro_name) {
         yesno := _message_box("Macro " :+ macro_name :+ " is already defined.\n\nDo you want to override the existing definition?",'',MB_YESNO|MB_ICONQUESTION);
         if (yesno != IDYES) {
            return 1;
         }
         nextIndex := t._TreeGetNextSiblingIndex(foundIndex);
         t._TreeDelete(foundIndex);
         foundIndex = nextIndex;
      } else {
         foundIndex = t._TreeGetNextSiblingIndex(foundIndex);
      }
      if (foundIndex > 0) {
         foundIndex = t._TreeSearch(foundIndex, macro_name, 'SPH');
      }
   }

   // success
   return 0;
}

static _str cm_get_pound_sign(_str langId="c")
{
   if (_LanguageInheritsFrom("c", langId) || _LanguageInheritsFrom("e", langId)) {
      return "#";
   }
   if (_LanguageInheritsFrom("verilog", langId) || _LanguageInheritsFrom("systemverilog", langId)) {
      return "`";
   }
   // default to C style #sign
   return "#";
}

// look up the given macro name in tag file to get initial value
static int cm_find_define(_str &macro_name, _str &macro_value, _str langId)
{
   // list of macro definitions
   macro_value="";
   _str define_list[];
   pound := cm_get_pound_sign(langId);

   // add in the original macro definition if it had args

   // extract tag name and arguments
   _str macro_args, tag_name, tag_type, tag_args;
   parse macro_name with macro_name '(' macro_args ')';

   if (macro_args != '') {
      define_list[define_list._length()] = pound"define "macro_name"("macro_args")";
   } else {
      define_list[define_list._length()] = pound"define "macro_name;
   }

   // for each language specific tag file in search path
   define_string := "";
   typeless tag_files=tags_filenamea(langId);
   i := 0;
   status := 0;
   _str tag_filename=next_tag_filea(tag_files,i,false,true);
   while (tag_filename != '') {
      // try to find the tag
      status = tag_find_equal(macro_name, false /*case sensitive*/);
      // check if we found the right macro name
      while (!status) {
         // check if tag_name is right case
         tag_get_detail(VS_TAGDETAIL_type, tag_type);
         if (tag_type :== 'define') {
            tag_get_detail(VS_TAGDETAIL_name, tag_name);
            tag_get_detail(VS_TAGDETAIL_arguments, tag_args);
            tag_get_detail(VS_TAGDETAIL_return, macro_value);
            if (tag_args != '') {
               define_string = pound"define "tag_name"("tag_args")\t"macro_value;
            } else {
               define_string = pound"define "tag_name"\t"macro_value;
            }
            define_list[define_list._length()] = define_string;
         }
         // next tag please
         status = tag_next_equal(false /*case sensitive*/);
      }
      // next tag file please...
      tag_reset_find_tag();
      tag_filename=next_tag_filea(tag_files,i,false,true);
   }

   // blow out of here if there was no match
   if (define_list._length() == 0) {
      macro_value='';
      if (macro_args != '') {
         macro_name :+= '(' macro_args ')';
      }
      return 1;
   }


   // sort the list and remove duplicate entries
   define_list._sort("",1);
   _aremove_duplicates(define_list,false);

   // make user choose their favorite macro definition
   define_string=define_list[0];
   if (define_list._length()>=2) {
      option := "-reinit";
      if (_find_formobj('_sellist_form')) {
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
   parse define_string with pound"define " macro_name "\t" macro_value;

   // that's all folks
   return 0;
}


// read one #define macro
int cm_load_macro(_str &macro_name, _str &macro_value,int &pic, _str langId)
{
   pound := cm_get_pound_sign(langId);

   // no more #define's found?
   typeless p1,p2,p3,p4;
   save_search(p1,p2,p3,p4);
   if (search('^ *(\'pound' *(define|undef|delete)|/[/*])','@rh')) {
      restore_search(p1,p2,p3,p4);
      return 0;
   }

   // get the contents of the line and remove "#define"
   macro_value='';
   line := "";
   get_line(line);

   // parse out comments
   typeless status=0;
   while (status!=BOTTOM_OF_FILE_RC && (line=='' || pos('^ */[/*]', line, 1, 'r'))) {
      if (pos('^ */[*]', line, 1, 'r')) {
         while (status!=BOTTOM_OF_FILE_RC && !pos('*/',line)) {
            macro_value :+= line "\n";
            status=down();
            get_line(line);
         }
         if (pos('*/',line)) {
            typeless junk;
            parse line with line "*/" junk;
            macro_value :+= line "*/\n";
            line=junk;
            if (strip(junk)=='') {
               status=down();
               get_line(line);
            }
         }
      } else {
         macro_value :+= line "\n";
         status=down();
         get_line(line);
      }
   }

   // parse out the #define statement
   if (pos('^ *\'pound' *{define|undef|delete} #', line, 1, 'r')) {
      word := substr(line,pos('S0'),pos('0'));
      if (word=='define') {
         pic=gi_pic_define;
      } else if (word=='undef') {
         pic=gi_pic_undef;
      } else {
         pic=0;
      }
      line = substr(line, pos('')+1);

      // pull out macro and arguments
      p := pos('^'CM_MACRO_REGEX, line, 1, 'ir');
      if (!p) {
         p = pos('^'CM_ID_REGEX, line, 1, 'ir');
      }
      if (p) {
         n := pos('');
         macro_name = substr(line, p, n);
         line = substr(line, n+1);
         line = strip(line, 'L');

         // read in the rest of the line
         p = pos(' @[\\]$', line, 1, 'r');
         while (p > 0) {
            macro_value :+= substr(line, 1, p-1) :+ "\n";
            down();
            get_line(line);
            p = pos(' @[\\]$', line, 1, 'r');
         }
         macro_value :+= line;

         // found something, macro_value and macro_name are set
         restore_search(p1,p2,p3,p4);
         return 1;
      }
   }

   // something went wrong
   restore_search(p1,p2,p3,p4);
   return 0;
}

static _str cm_make_macro_key(_str macro_name, _str &justName)
{
   // no arguments
   if (!pos('(', macro_name)) {
      justName = macro_name;
      return macro_name;
   }
   // get argument list
   parse macro_name with justName '(' auto argList ')';

   // empty argument list
   if (argList == "") {
      return justName :+ "(0)";
   }

   // variadic macro?
   elipses := pos('...', argList)? "..." : "";

   // count the arguments
   split(argList, ',', auto argArray);
   return justName:+"(":+argArray._length():+elipses:+")";
}

// Load the macro definitions file
static int cm_load_macro_definitions(int t, 
                                     _str filename,
                                     _str langId,
                                     bool isUserCPP,
                                     bool hideSyscpp=false)
{
   // open the file int temporary buffer for reading
   //say("cm_load_macro_definitions["__LINE__"]: loading file "filename" , langId="langId);
   mou_hour_glass(true);
   orig_view_id := p_window_id;
   macro_view_id := 0;
   int status=_open_temp_view(filename,macro_view_id,orig_view_id);
   if (status) {
      p_window_id=orig_view_id;
      mou_hour_glass(false);
      return status;
   }
#if 0
   inmem := true;
   status=_open_temp_view(filename,macro_view_id,orig_view_id,' +b ');
   if (status) {
      inmem=0;
      status=_open_temp_view(filename,macro_view_id,orig_view_id);
      if (status) {
         p_window_id=orig_view_id;
         mou_hour_glass(false);
         return status;
      }
   }
#endif


   //t._TreeDelete(TREE_ROOT_INDEX, 'c');  // clear the tree

   // read the file, this will be *real* fun...
   p_window_id=macro_view_id;
   top();up();

   i := 0;
   macro_name := "";
   macro_value := "";
   justName := "";
   pic := 0;
   if (isUserCPP) {
      for (;;) {
         // read one macro definition and insert into tree
         if (cm_load_macro(macro_name, macro_value, pic, langId)) {
            macro_key := cm_make_macro_key(macro_name, justName);
            if (pic) {
               // #undef or #define
               gusercpp_hashtab:[justName]=pic;
               i = t._TreeAddItem(TREE_ROOT_INDEX, macro_name, TREE_ADD_AS_CHILD, pic, pic, TREE_NODE_LEAF, TREENODE_BOLD, macro_value);
            } else {
               justName=macro_name;
               gusercpp_hashtab:[justName]=0;
            }
            pi := gsyscpp_hashtab._indexin(macro_key);
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
         if (cm_load_macro(macro_name, macro_value, pic, langId)) {
            macro_key := cm_make_macro_key(macro_name, justName);
            i = t._TreeAddItem(TREE_ROOT_INDEX, macro_name, TREE_ADD_AS_CHILD, pic, pic, TREE_NODE_LEAF, hideSyscpp? TREENODE_HIDDEN:0, macro_value);
            gsyscpp_hashtab:[macro_key]=i;
         }
         // next please
         if (down() == BOTTOM_OF_FILE_RC) break;
      }
   }

   _delete_temp_view(macro_view_id);
   p_window_id=orig_view_id;

   // that's all folks
   mou_hour_glass(false);
   return(0);
}

// write the given macro to the current buffer
int cm_save_macro(_str macro_name, _str macro_value, int pic, _str langId)
{
   // skip over leading blank lines
   line := "";
   rest := "";
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
   pound := cm_get_pound_sign(langId);
   curr_line := "";
   if (pic==gi_pic_define) {
      curr_line = pound"define "macro_name" "line;
   } else {
      curr_line = pound"undef "macro_name" "line;
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
static int cm_save_macro_definitions(int t, _str macrofilename, _str langId)
{
   typeless junk=0;
   macro_view_id := 0;
   orig_view_id := 0;
   get_window_id(orig_view_id);
   // look for local CPP definitions file
   filename := macrofilename;
   if (macrofilename._isempty() || macrofilename=='') {
      filename = _lang_user_ppedit_path(langId, false);
   }

   // open the file, might have to create new file
   mou_hour_glass(true);
   int status=_open_temp_view(filename,macro_view_id,junk);
   if (status) {
      orig_view_id=_create_temp_view(macro_view_id);
      p_buf_name=filename;
      p_UTF8=_load_option_UTF8(p_buf_name);
   }

   p_window_id=macro_view_id;

   // traverse tree control and write macro definitions
   macro_name := "";
   macro_value := "";
   justName := "";
   ShowChildren := 0;
   bm_index := 0;
   delete_all();
   index := t._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (index > 0) {
      // get information out of tree control
      macro_name  = t._TreeGetCaption(index);
      macro_value = t._TreeGetUserInfo(index);
      macro_key   := cm_make_macro_key(macro_name, justName);
      if (gusercpp_hashtab._indexin(justName)) {
         isSysCppMacro := gsyscpp_hashtab._indexin(macro_key);
         if (isSysCppMacro) {
            isSysCppMacro = (gsyscpp_hashtab:[macro_key] == index);
         }
         if (!isSysCppMacro) {
            t._TreeGetInfo(index,ShowChildren,bm_index);
            cm_save_macro(macro_name, macro_value, bm_index, langId);
         }
      }

      // next please...
      index = t._TreeGetNextSiblingIndex(index);
   }

   // Traverse the elements in hash table
   pound := cm_get_pound_sign(langId);
   foreach (justName => index in gusercpp_hashtab) {
      if (!index) {
         insert_line(pound"delete "justName);
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
   mou_hour_glass(false);
   return(status);
}

// update the macro currently being edited if needed
static void cm_update_macro_definition(int e, int t, int u)
{
   if (e.p_modify == true && gi_curr_macro > 0) {
      macro_value := cm_get_macro_definition(e);
      old_value := t._TreeGetUserInfo(gi_curr_macro);
      if (macro_value :!= old_value) {
         t._TreeSetUserInfo(gi_curr_macro, macro_value);
         gi_modify_flag = true;

         // if it's changed, add it to the userdef file
         macro_name := ctl_macros_tree._TreeGetCaption(gi_curr_macro);
         macro_key  := cm_make_macro_key(macro_name, auto justName);
         if (!u.p_value) {
            gusercpp_hashtab:[justName]=gi_pic_define;
         } else {
            gusercpp_hashtab:[justName]=gi_pic_undef;
         }
         if (gsyscpp_hashtab._indexin(macro_key)) {
            gsyscpp_hashtab._deleteel(macro_key);
         }
      }
      e.p_modify = false;
   }
}


#region Options Dialog Helper Functions

/////////////////////////////////////////////////////////////////////
// Events handled by the dialog editor
//
defeventtab _c_ppedit_form;

void _c_ppedit_form_init_for_options(_str options="")
{
   ctl_ok_btn.p_visible = false;
   ctl_cancel_btn.p_visible = false;
   ctl_help_btn.p_visible = false;
   ctl_delete_btn.p_x = ctl_new_btn.p_x;
   ctl_new_btn.p_x = ctl_import_btn.p_x;
   ctl_import_btn.p_x = ctl_ok_btn.p_x;
}

bool _c_ppedit_form_create_needs_lang_argument()
{
   return true;
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

bool _c_ppedit_form_is_modified()
{
   return gi_modify_flag;
}

void RetagCppBuffers(bool updateCurrentFile=true, _str langId="c")
{
   // Reset the modify flags for all "C/C++" buffers
   orig_window := p_window_id;
   activate_window(VSWID_HIDDEN);
   _safe_hidden_window();
   orig_buf_id := p_buf_id;
   for (;;) {
      if (_LanguageInheritsFrom(langId, p_LangId)) {
         p_ModifyFlags &= ~( MODIFYFLAG_TAGGED                 |
                             MODIFYFLAG_BGRETAG_THREADED       |
                             MODIFYFLAG_CONTEXT_THREADED       |
                             MODIFYFLAG_LOCALS_THREADED        |
                             MODIFYFLAG_CONTEXT_UPDATED        |
                             MODIFYFLAG_LOCALS_UPDATED         |
                             MODIFYFLAG_FCTHELP_UPDATED        |
                             MODIFYFLAG_CONTEXTWIN_UPDATED     |
                             MODIFYFLAG_XMLTREE_UPDATED        |
                             MODIFYFLAG_STATEMENTS_UPDATED     |
                             MODIFYFLAG_AUTO_COMPLETE_UPDATED 
                             );
         p_LastModified++;
         _UpdateContextAsync(true);
      }
      _next_buffer('hr');
      if (p_buf_id == orig_buf_id) {
         break;
      }
   }
   // Finally, update the current buffer, and the tool windows
   // viewing the tagging information for that buffer.
   activate_window(orig_window);
   if (_isEditorCtl() && updateCurrentFile) {
      _UpdateContext(true);
      _UpdateCurrentTag(true);
      _UpdateContextWindow(true);
      _UpdateClass(true);
   }
}

static void RefreshCPPColoring(_str langId="c")
{
   orig_window := p_window_id;
   activate_window(VSWID_HIDDEN);
   _safe_hidden_window();
   orig_buf_id := p_buf_id;
   for (;;) {
      if ( _LanguageInheritsFrom(langId) ) {
         orig_lexer := p_lexer_name;
         p_lexer_name=orig_lexer;
      }
      _next_buffer('hr');
      if (p_buf_id == orig_buf_id) {
         break;
      }
   }
   activate_window(orig_window);
}

/**
 * Format: 
 *    langid:defines 
 */
static _str gProjectLangIdDefines = "";

/**
 * Get #defines from project/configuration specific compile options.
 */
void _prjopen_c_ppedit()
{
   gProjectLangIdDefines = "";
   _wkspace_close_ppedit();

   projectLang := _ProjectGet_LanguageForProjectType(_ProjectHandle(), GetCurrentConfigName());
   if (projectLang == "") {
      return;
   }

   cppDefines := "";
   if (isEclipsePlugin()) {
      _eclipse_get_project_defines_string(cppDefines);
   } else {
      cppDefines = _ProjectGet_Defines(_ProjectHandle(), GetCurrentConfigName());
   }
   if (cppDefines == "") {
      return;
   }

   gProjectLangIdDefines = projectLang :+ ":" :+ cppDefines;
}

/**
 * Return preprocess defines for the current project / configuration, 
 * if the primary language for the project matches the  
 */
_str _project_defines_for_language(_str langId)
{
   if (!beginsWith(gProjectLangIdDefines, langId:+":")) {
      return "";
   }
   parse gProjectLangIdDefines with . ':' auto defines;
   return defines;
}

void _wkspace_close_ppedit()
{
   index := find_index('cpp_reset',COMMAND_TYPE|PROC_TYPE);
   if (index_callable(index)) {
      call_index(index);
      if (!_no_child_windows()) {
         _mdi.p_child.RetagCppBuffers(false);
         _mdi.p_child.RefreshCPPColoring();
      }
   }
}
void _workspace_opened_ppedit()
{
   _wkspace_close_ppedit();
}

static void reset_ppedit(_str langId)
{
   if (_LanguageInheritsFrom("c", langId)) {
      index := find_index('cpp_reset',COMMAND_TYPE|PROC_TYPE);
      if (index_callable(index)) {
         call_index(index);
      }
   } else if (_LanguageInheritsFrom("systemverilog", langId)) {
      index := find_index('systemverilog_reset',COMMAND_TYPE|PROC_TYPE);
      if (index_callable(index)) {
         call_index(index);
      }
   } else if (_LanguageInheritsFrom("verilog", langId)) {
      index := find_index('verilog_reset',COMMAND_TYPE|PROC_TYPE);
      if (index_callable(index)) {
         call_index(index);
      }
   }
}

bool _c_ppedit_form_apply()
{
   // update the macro currently being edited if needed
   _nocheck _control ctl_macro_edit;
   _nocheck _control ctl_macros_tree;
   _nocheck _control ctlundef;
   _nocheck _control ctlhidesyscpp;
   cm_update_macro_definition(ctl_macro_edit, ctl_macros_tree, ctlundef);
   langId := ctl_macro_edit.p_LangId;

   // save macros to file, if there were modifications
   if (gi_modify_flag) {
      filename := ctlhidesyscpp.p_user;
      reset_ppedit(langId);
      cm_save_macro_definitions(ctl_macros_tree, filename, langId);
      gi_modify_flag = false;
      if (!_no_child_windows()) {
         _mdi.p_child.RetagCppBuffers(true, langId);
      }
      status := IDNO;
      if (_haveContextTagging() && _workspace_filename != "") {
         status = _message_box("Do you want to retag your workspace?",'',
                               MB_YESNO|MB_ICONQUESTION);
      }
      if (status == IDYES) {
         mou_hour_glass(true);
         orig_wid := p_window_id;
         tag_files := project_tags_filenamea();
         useThread := _is_background_tagging_enabled(AUTOTAG_LANGUAGE_NO_THREADS);
         foreach (auto TagFilename in tag_files) {
            RetagFilesInTagFile(TagFilename, true, true, true, false, useThread);
         }
         p_window_id=orig_wid;
         clear_message();
         toolbarUpdateWorkspaceList();
         mou_hour_glass(false);
      }
      if (!_no_child_windows()) {
         _mdi.p_child.RefreshCPPColoring(langId);
      }
   }
   return true;
}
void _c_ppedit_form_cancel()
{
   gi_modify_flag=false;
}

_str _c_ppedit_form_export_settings(_str &file, _str &args, _str langId)
{
   error := '';

   ppeditFile := _lang_user_ppedit_path(langId);
   if (ppeditFile != '') {
      justPPEditFile := _strip_filename(ppeditFile, 'P');
      if (copy_file(ppeditFile, file :+ justPPEditFile)) error = 'Error copying 'ppeditFile'.';
      else file = justPPEditFile;
   }

   return error;

}

_str _c_ppedit_form_import_settings(_str &file, _str &args, _str langId)
{
   error := '';

   if (file_exists(file)) {
      ppeditFile := _lang_user_ppedit_path(langId, false);
      if (file_exists(ppeditFile)) {
         if (combinePreprocessingFiles(ppeditFile, file, langId)) {
            error = 'Error appending values in 'file'.';
         }
      } else if (copy_file(file, ppeditFile)) error = 'Error copying 'file'.';

   } else error :+= 'Error opening 'file'. ';

   return error;
}

/**
 * Combines two preprocessing files
 *
 * @param file1      first file
 * @param file2      second file, info in here will overwrite
 *                   any conflicting info found in file 1
 *
 * @return int       0 for success, nonzero error otherwise
 */
static int combinePreprocessingFiles(_str file1, _str file2, _str langId)
{
   // read file 1
   _str defs:[], undefs:[], deletes:[];
   status := cm_load_macro_definitions_in_tables(file1, langId, defs, undefs, deletes);
   if (status) return status;

   // now file 2 - any conflicts will be overwritten with file 2 info
   status = cm_load_macro_definitions_in_tables(file2, langId, defs, undefs, deletes, true);
   if (status) return status;

   // now write the new info to new file
   int macro_view_id;
   orig_view_id := _create_temp_view(macro_view_id);
   p_buf_name = file1;
   p_UTF8 = _load_option_UTF8(p_buf_name);
   p_window_id = macro_view_id;

   _str name, value;
   foreach (name => value in defs) {
      cm_save_macro(name, value, gi_pic_define, langId);
   }

   foreach (name => value in undefs) {
      if (value != null) cm_save_macro(name, value, gi_pic_undef, langId);
   }

   pound := cm_get_pound_sign(langId);
   foreach (name => . in deletes) {
      insert_line(pound"delete "name);
      insert_line("");
   }

   status = _save_config_file(file1);

   _delete_temp_view(macro_view_id);
   p_window_id=orig_view_id;

   return status;
}

/**
 * Load the macro definitions into a set of hashtables.
 *
 * @param filename      file to load
 * @param defs          table of defines, key is name, value is
 *                      value
 * @param undefs        table of undefs
 * @param deletes       table of items to delete
 * @param overwrite     whether to overwrite existing info in
 *                      tables
 *
 * @return int          0 for success, nonzero error otherwise
 */
static int cm_load_macro_definitions_in_tables(_str filename, 
                                               _str langId,
                                               _str (&defs):[], 
                                               _str (&undefs):[],
                                               _str (&deletes):[], 
                                               bool overwrite = false)
{
   // open the file int temporary buffer for reading
   orig_view_id := p_window_id;
   macro_view_id := 0;
   int status=_open_temp_view(filename,macro_view_id,orig_view_id);
   if (status) {
      p_window_id=orig_view_id;
      return status;
   }

   // read the file, this will be *real* fun...
   p_window_id=macro_view_id;
   top();up();

   macro_name := "";
   macro_value := "";
   justName := "";
   pic := 0;

   for (;;) {
      // read one macro definition and insert into table
      if (cm_load_macro(macro_name, macro_value, pic, langId)) {
         // remove from other tables, if necessary
         if (overwrite) {
            if (defs._indexin(macro_name)) defs._deleteel(macro_name);
            if (undefs._indexin(macro_name)) undefs._deleteel(macro_name);
            if (deletes._indexin(macro_name)) deletes._deleteel(macro_name);
         }

         // add it to the correct table
         if (pic == gi_pic_define) {
            defs:[macro_name] = macro_value;
         } else if (pic == gi_pic_undef) {
            undefs:[macro_name] = macro_value;
         } else {
            deletes:[macro_name] = macro_value;
         }
      }

      // next please
      if (down() == BOTTOM_OF_FILE_RC) break;
   }

   _delete_temp_view(macro_view_id);
   p_window_id=orig_view_id;

   return 0;
}

#endregion Options Dialog Helper Functions

// form just created, restore state, size, current selection
void ctl_ok_btn.on_create(_str langId="", _str userFileName="")
{
   gusercpp_hashtab._makeempty();
   gsyscpp_hashtab._makeempty();
   _nocheck _control ctl_macros_tree;

   // load macros for the given language ID
   gi_ppedit_wid=p_active_form;

   // look for local/global CPP definitions file
   hideSyscpp := (ctlhidesyscpp.p_value != 0);
   if (langId == "") langId = "c";

   filename := _lang_sys_ppedit_path(langId);
   if (filename!="") {
      cm_load_macro_definitions(ctl_macros_tree, filename, langId, false, hideSyscpp);
   }
   filename = _lang_user_ppedit_path(langId);
   if (filename!="") {
      cm_load_macro_definitions(ctl_macros_tree, filename, langId, (userFileName==""), hideSyscpp);
   }
   if (userFileName != "") {
      filename = userFileName;
      cm_load_macro_definitions(ctl_macros_tree, filename, langId, true);
   }
   if (filename=="") {
      filename = _lang_user_ppedit_path(langId, false);
   }

   // sort the items in the tree by macro name
   ctl_macros_tree._TreeSortCaption(TREE_ROOT_INDEX, 'I');

   pound := cm_get_pound_sign(langId);
   ctlhidesyscpp.p_user = filename;
   ctlhidesyscpp.p_caption = "Hide preconfigured "pound"defines";
   p_active_form.p_caption = p_active_form.p_caption ' - ' filename;
   gi_ppedit_wid = 0;
   gi_modify_flag = false;

   // restore position of divider bar
   typeless last_x = _moncfg_retrieve_value("_"langId"_ppedit_form.ctl_divider.p_x");
   if (!last_x._isempty() && isnumber(last_x)) {
      ctl_divider.p_x = last_x;
   }

   // set up color coding
   ctl_macro_edit._SetEditorLanguage(langId);
   ctl_macro_edit._set_language_form_lang_id(langId);

   // restore currently selected item
   typeless selected_item = _retrieve_value("_"langId"_ppedit_form.ctl_macros_tree.p_user");
   int currIndex;
   currIndex = 0;
   if (!selected_item._isempty()) {
      currIndex = ctl_macros_tree._TreeSearch(TREE_ROOT_INDEX, selected_item);
   }
   if (currIndex <= 0) {
      ctl_macros_tree._TreeTop();
      currIndex = ctl_macros_tree._TreeCurIndex();
   }
   if (currIndex > 0) {
      ctl_macros_tree._TreeSetCurIndex(currIndex);
      call_event(CHANGE_SELECTED,currIndex,ctl_macros_tree,ON_CHANGE,'w');
   }

   ctl_macro_name.p_y = ctlhidesyscpp.p_y + ((ctlhidesyscpp.p_height - ctl_macro_name.p_height) intdiv 2);
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
   currIndex := ctl_macros_tree._TreeCurIndex();
   selected_item := "";
   if (currIndex > 0) {
      selected_item = ctl_macros_tree._TreeGetCaption(currIndex);
   }

   // prompt if they want to save
   langId := ctl_macro_edit.p_LangId;
   if (gi_modify_flag && ctl_ok_btn.p_visible) {
      title := "";
      filename := "";
      parse p_caption with title ' - ' filename;
      int status = _message_box("Save changes to "filename"?",'',MB_YESNO);
      if (status == IDYES) {
         filename = ctlhidesyscpp.p_user;
         cm_save_macro_definitions(ctl_macros_tree, filename, langId);
      }
   }

   // save form settings
   _moncfg_append_retrieve(0, gi_ppedit_wid.ctl_divider.p_x, "_"langId"_ppedit_form.ctl_divider.p_x");
   _append_retrieve(0, selected_item, "_"langId"_ppedit_form.ctl_macros_tree.p_user");
   gi_ppedit_wid = -1;
   gusercpp_hashtab._makeempty();
   gsyscpp_hashtab._makeempty();
}

// handle horizontal resize bar
ctl_divider.lbutton_down()
{
   int button_width = ctl_ok_btn.p_width;
   int border_width = ctl_macros_tree.p_x;
   int member_width = ctl_macro_edit.p_x_extent;
   int divide_width = ctl_divider.p_width;
   _ul2_image_sizebar_handler(ctlhidesyscpp.p_x_extent, member_width);
}

// resize form
void _c_ppedit_form.on_resize()
{

   pad := ctl_macros_tree.p_x;
   heightDiff := p_height - (ctl_import_btn.p_y_extent + pad);

   ctl_macros_tree.p_height += heightDiff;
   ctl_macro_edit.p_height = ctl_divider.p_height = ctl_macros_tree.p_height;

   ctlundef.p_y += heightDiff;
   ctl_ok_btn.p_y += heightDiff;
   ctl_import_btn.p_y = ctl_new_btn.p_y = ctl_new_btn.p_y = ctl_delete_btn.p_y =
      ctl_cancel_btn.p_y = ctl_help_btn.p_y = ctl_ok_btn.p_y;

   ctl_macros_tree.p_x_extent = ctl_divider.p_x ;
   ctl_macro_name.p_x = ctl_macro_edit.p_x = ctl_divider.p_x_extent;
   ctl_macro_edit.p_width = p_width - (ctl_macro_edit.p_x + pad);


}

// apply all changes
void ctl_ok_btn.lbutton_up()
{
   orig_form := p_active_form;
   _c_ppedit_form_apply();
   // save form settings
   orig_form._delete_window(0);
}

// add a set of macros from a header file
void ctl_import_btn.lbutton_up()
{
   // select header file to import from
   langId := ctl_macro_edit.p_LangId;
   pound := cm_get_pound_sign(langId);
   headerFile := "";
   if (_LanguageInheritsFrom("systemverilog", langId)) {
      headerFile = _OpenDialog( "-modal",
                                "Import `defines from header file",  // Title
                                "*.svh;*.svi;*.sv",                  // Wild Cards
                                "*.svh;*.svi;*.sv,*.*",              // File Filters
                                OFN_FILEMUSTEXIST,                   // OFN flags
                                ".svh",                              // Default extension
                                "",                                  // Initial name
                                ""                                   // Initial directory
                               );
   } else if (_LanguageInheritsFrom("verilog", langId)) {
      headerFile = _OpenDialog( "-modal",
                                "Import `defines from header file",  // Title
                                "*.v",                               // Wild Cards
                                "*.v,*.*",                           // File Filters
                                OFN_FILEMUSTEXIST,                   // OFN flags
                                ".v",                                // Default extension
                                "",                                  // Initial name
                                ""                                   // Initial directory
                               );
   } else {
      headerFile = _OpenDialog( "-modal",
                                "Import #defines from header file",  // Title
                                "*.h;*.hpp;*.hxx;*.h++;*.hh",        // Wild Cards
                                "*.h;*.hpp;*.hxx,*.h++;*.hh,*.*",    // File Filters
                                OFN_FILEMUSTEXIST,                   // OFN flags
                                ".h",                                // Default extension
                                "",                                  // Initial name
                                ""                                   // Initial directory
                               );
   }
   if (headerFile == "") {
      return;
   }

   // open the file in a temp view
   header_view_id := 0;
   orig_view_id := 0;
   status := _open_temp_view(headerFile, header_view_id, orig_view_id, "+d", true, false, true);
   if (status < 0) {
      _message_box(nls("Could not open %s\n\n%s",headerFile,get_message(status)));
      return;
   }

   // update the context for this item
   header_view_id._UpdateStatements(true,true);

   // Collect all the #defines from the current context
   tag_lock_context();
   VS_TAG_BROWSE_INFO cm;
   VS_TAG_BROWSE_INFO cmList[];
   _str defineList[];
   _str keyList[];
   int picList[];
   bool selectList[];
   bool duplicateList:[];
   bool allDuplicates:[];
   n := tag_get_num_of_context();
   for (i:=1; i<=n; i++) {
      // get detailed symbol information
      tag_get_context_info(i, cm);
      have_duplicate := duplicateList._indexin(cm.member_name);
      if (!have_duplicate) {
         macro_name := cm.member_name;
         if (cm.arguments != "") {
            macro_name :+= "(";
            macro_name :+= cm.arguments;
            macro_name :+= ")";
         }
         macro_key := cm_make_macro_key(macro_name, auto justName);
         have_duplicate = gsyscpp_hashtab._indexin(macro_key);
      }
      if (!have_duplicate) {
         have_duplicate = gusercpp_hashtab._indexin(cm.member_name);
      }
      //say("symbol="cm.member_name" duplicate="have_duplicate);
      // Check for #define
      if (cm.type_name == "define") {
         caption := cm.member_name;
         if (cm.arguments != "") {
            caption :+= "(";
            caption :+= cm.arguments;
            caption :+= ")";
         }
         caption :+= "\t";
         caption :+= cm.return_type;
         if (allDuplicates._indexin(gi_pic_define:+caption)) continue;
         allDuplicates:[gi_pic_define:+caption] = true;
         duplicateList:[cm.member_name] = true;
         defineList[defineList._length()] = caption;
         selectList[selectList._length()] = !have_duplicate;
         keyList[keyList._length()] = cmList._length();
         picList[picList._length()] = gi_pic_define;
         cmList[cmList._length()] = cm;
      }
      // Convert #undef preprocessing symbol to "undef" symbol
      if (cm.type_name == "pp" && pos(pound"undef ",cm.member_name) == 1) {
         cm.type_name = "undef";
         cm.member_name = substr(cm.member_name,8);
      }
      // Check for a #undef symbol
      if (cm.type_name == "undef") {
         caption := cm.member_name;
         caption :+= "\t";
         if (allDuplicates._indexin(gi_pic_undef:+caption)) continue;
         allDuplicates:[gi_pic_undef:+caption] = true;
         duplicateList:[cm.member_name] = true;
         defineList[defineList._length()] = caption;
         selectList[selectList._length()] = !have_duplicate;
         keyList[keyList._length()] = cmList._length();
         picList[picList._length()] = gi_pic_undef;
         cmList[cmList._length()] = cm;
      }
   }
   tag_unlock_context();

   // Close the temp view, we don't need it any more
   _delete_temp_view(header_view_id);
   activate_window(orig_view_id);

   // Ask the user to select which items they want to import
   selectedKeys := select_tree(defineList, keyList, 
                               picList, picList, selectList, 
                               null, null, 
                               "Select "pound"define's to import",
                               SL_CHECKLIST|SL_INVERT|SL_SELECTALL|SL_COLWIDTH,
                               "Name,Value", 
                               (TREE_BUTTON_SORT|TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_PUSHBUTTON)',':+TREE_BUTTON_PUSHBUTTON,
                               true,
                               "C/C++ preprocessing",
                               "ppedit.ctl_import_btn");
   if (selectedKeys == "" || selectedKeys == COMMAND_CANCELLED_RC) {
      return;
   }

   // Now we can import the functions which were selected
   currIndex := 0;
   key := 0;
   foreach (key in selectedKeys) {

      // construct the macro name
      cm = cmList[key];
      macro_name := cm.member_name;
      if (cm.arguments != "") {
         macro_name :+= "(";
         macro_name :+= cm.arguments;
         macro_name :+= ")";
      }
      macro_value := cm.return_type;

      // add the new macro into the tree
      pic_index := picList[key];
      currIndex = ctl_macros_tree._TreeAddItem(TREE_ROOT_INDEX, macro_name, TREE_ADD_AS_CHILD|TREE_ADD_SORTED_CI, pic_index, pic_index, TREE_NODE_LEAF, TREENODE_BOLD, macro_value);
      gusercpp_hashtab:[cm.member_name] = pic_index;
   }

   // Set focus on the last new macro imported
   if (currIndex > 0) {
      ctl_macros_tree._TreeSetCurIndex(currIndex);
      call_event(CHANGE_SELECTED,currIndex,ctl_macros_tree,ON_CHANGE,'w');
      ctl_macro_edit._set_focus();
      gi_modify_flag = true;
   }
}

// add a new macro
void ctl_new_btn.lbutton_up()
{
   // update the macro currently being edited if needed
   _nocheck _control ctl_macro_edit;
   _nocheck _control ctl_macros_tree;
   _nocheck _control ctlundef;
   cm_update_macro_definition(ctl_macro_edit, ctl_macros_tree, ctlundef);
   langId := ctl_macro_edit.p_LangId;

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
   status := cm_find_define(macro_name, auto macro_value, langId);
   if (status) {
      return;
   }

   // update editor
   pound := cm_get_pound_sign(langId);
   ctl_macro_name.p_caption = pound"define " :+ macro_name;
   cm_edit_macro_definition(ctl_macro_edit, macro_value);
   ctlundef.p_enabled=true;

   // add the new macro into the tree
   justName := "";
   int currIndex = ctl_macros_tree._TreeAddItem(TREE_ROOT_INDEX, macro_name, TREE_ADD_AS_CHILD|TREE_ADD_SORTED_CI, gi_pic_define, gi_pic_define, TREE_NODE_LEAF, TREENODE_BOLD, macro_value);
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
   langId := ctl_macro_edit.p_LangId;
   pound := cm_get_pound_sign(langId);
   index := ctl_macros_tree._TreeCurIndex();
   if (index>0) {
      gi_modify_flag = true;
      _str macro_value=ctl_macros_tree._TreeGetUserInfo(index);
      macro_name := ctl_macros_tree._TreeGetCaption(index);
      ShowChildren := bm_index := 0;
      ctl_macros_tree._TreeGetInfo(index,ShowChildren,bm_index);
      justName := "";
      parse macro_name with justName '(';
      pic := 0;
      if (!p_value) {
         ctl_macro_name.p_caption=pound"define " :+ macro_name;
         pic=gi_pic_define;
      } else {
         ctl_macro_name.p_caption=pound"undef ":+justName;
         pic=gi_pic_undef;
      }
      ctl_macros_tree._TreeSetInfo(index,ShowChildren,pic,pic,TREENODE_BOLD);
      gusercpp_hashtab:[justName]=gi_pic_undef;
      gi_modify_flag = true;
   }

}

void ctlhidesyscpp.lbutton_up()
{
   // Temporarily  move to the bottom of the tree to prevent the
   // tree from redrawing like crazy while nodes are being hidden.
   ctl_macros_tree._TreeBottom();
   currentIndex := ctl_macros_tree._TreeCurIndex();

   show_children := bm1 := bm2 := moreFlags := 0;
   index := ctl_macros_tree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (index > 0) {

      macro_name := ctl_macros_tree._TreeGetCaption(index);
      justName := "";
      parse macro_name with justName '(';

      if (!gusercpp_hashtab._indexin(justName)) {
         ctl_macros_tree._TreeGetInfo(index, show_children, bm1, bm2, moreFlags);
         if (moreFlags & TREENODE_HIDDEN) {
            ctl_macros_tree._TreeSetInfo(index, show_children, bm1, bm2, moreFlags&~TREENODE_HIDDEN);
         } else {
            ctl_macros_tree._TreeSetInfo(index, show_children, bm1, bm2, moreFlags|TREENODE_HIDDEN);
         }
      }

      index=ctl_macros_tree._TreeGetNextSiblingIndex(index);
   }

   index = currentIndex;
   if (index <= 0) ctl_macros_tree._TreeTop();
   index = ctl_macros_tree._TreeCurIndex();
   ctl_macros_tree._TreeGetInfo(index, show_children, bm1, bm2, moreFlags);
   if (moreFlags & TREENODE_HIDDEN) ctl_macros_tree._TreeDown();
   index = ctl_macros_tree._TreeCurIndex();
   call_event(CHANGE_SELECTED,index,ctl_macros_tree,ON_CHANGE,'w');
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
   macro_name := ctl_macros_tree._TreeGetCaption(currIndex);
   macro_key  := cm_make_macro_key(macro_name, auto justName);
   if (gsyscpp_hashtab._indexin(macro_key)) {
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
   langId := ctl_macro_edit.p_LangId;
   pound := cm_get_pound_sign(langId);

   if (reason == CHANGE_LEAF_ENTER || reason == CHANGE_SELECTED) {
      ShowChildren := bm_index := moreFlags := 0;
      ctl_macros_tree._TreeGetInfo(index,ShowChildren,bm_index,bm_index,moreFlags);
      if (moreFlags & TREENODE_HIDDEN) index=0;
      if (index > 0) {
         macro_value=ctl_macros_tree._TreeGetUserInfo(index);
         macro_name =ctl_macros_tree._TreeGetCaption(index);
      } else {
         macro_value=macro_name='';
      }
      cm_update_macro_definition(ctl_macro_edit, ctl_macros_tree, ctlundef);
      if (macro_name == "") {
         ctlundef.p_enabled=false;
         if (ctlhidesyscpp.p_value != 0) {
            ctl_macro_name.p_caption="No "pound"define selected (preconfigured are hidden)";
         } else {
            ctl_macro_name.p_caption="No "pound"define selected";
         }
      } else if (bm_index==gi_pic_define) {
         ctl_macro_name.p_caption=pound"define " :+ macro_name;
         ctlundef.p_value=0;
         ctlundef.p_enabled=true;
      } else {
         name := "";
         parse macro_name with name '(';
         ctl_macro_name.p_caption=pound"undef ":+name;
         ctlundef.p_value=1;
         ctlundef.p_enabled=true;
      }
      cm_edit_macro_definition(ctl_macro_edit, macro_value);
      gi_curr_macro=index;

      if (reason==CHANGE_LEAF_ENTER) {
         ctl_macro_edit._set_focus();
      }
   }
}

