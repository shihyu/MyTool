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

/*

   The SlickEdit commands cursor_error(), next_error(), and prev_error()
   all support the regular expressions defined in the profile
   "misc.errorparsing".
   
 
Adding support for Your Compiler's Error Messages
 
   Use the Build>Configure Error Parsing menu item to add new
   error parsing regular expressions.  The error parsing regular
   expressions support multi-line compiler output. See Python in
   the "default" category for an example.
 
   Some of the error parsing expressions may match lines that you
   do not want recognized as errors. To eliminate these "false
   positive" matches, define a new expression in the Exclusions
   category. The default configuration file contains an expression
   to match the "Total Time" build output line that is generated
   by SlickEdit's internal build system, vsbuild. Any new
   exclusion expressions you write should be very strict to
   prevent real error lines from being skipped. You do not have to
   define match groups in the exclusion expressions since they
   will not be used to extract file name and line number
   information.

 
Common Problems and Solutions
 
  *  If messages which are NOT compiler errors are being flagged
     as valid compiler errors, add to the Exclusions category of
     regular expressions (Build>Configure Error Parsing>Exclusions).
 
  *  If your compiler error messages are not handled properly,
     one solution is to write a script (Perl,Python,Ruby, etc.)
     which converts your compilers output into a format
     SlickEdit understands (ex "compiler|perl myscript.pl").
     There are alternate solutions listed below which also work.
     Most of them require using Slick-C.
 
  *  If your compiler errors are being found by one of our
     existing regular expressions but the information is being
     parsed incorrectly, either 1) Specify a new regular
     expression which is before the problematic regular
     expression 2) Remove the problematic regular expression and
     specify a new one or 3) Write a
     _get_error_info_<uniqueName> which will gets called to
     parse the entire output. _error_filename has the current
     buffer name at the time the error is searched. See
     _get_error_info_microfocus or _get_error_info_vhdl for
     examples.
 
  *  If your compiler outputs multi-line errors, first try
     defining a multi-line regular expression. For each
     new-line, use the regular expression (\R) to match
     any kind of new-line sequence. If you still can't get the
     compiler error message to work, you'll need to write a
     macro. Add a regular expression which matches part of your
     compilers error output (usually the first line). Then set
     the "macro" attribute in the "attrs" element for your
     regular expression and write a macro function which takes
     arguments like the following:
 
  bool parseErrorOutput_<MyCompiler>(
         _str &filename,_str &linenum, _str &col, _str &err_msg
         )
     Return true if a valid match is found.
 
     DO NOT name your function _get_error_info_<microfocus>
     since these callbacks are intended to solve a different
     problem.
 
  *  If the filename is missing from the compile error output
     completely, you need to write a macro callback which either
     1) Uses the current buffer name (_error_filename) or 2)
     searchings backward for something like the compile line
     which specifies the filename. Set the "macro" attribute in the 
     "attrs" element for your regular expression and
     write a macro function which takes
 
  bool parseErrorOutput_<MyCompiler>(
         _str &filename,_str &linenum, _str &col, _str &err_msg
         )
     Return true if a valid match is found.
 
     DO NOT name your function _get_error_info_<microfocus>
     since these callbacks are intended to solve a different
     problem.


*/
#pragma option(pedantic,on)
#region Imports
#include "eclipse.sh"
#include "refactor.sh"
#include "slick.sh"
#include "xml.sh"
#include "color.sh"
#include "markers.sh"
#include "errorre.sh"
#require "se/messages/Message.e"
#import "se/messages/MessageBrowser.e"
#import "se/messages/MessageCollection.e"
#import "se/search/SearchResults.e"
#import "files.e"
#import "guicd.e"
#import "help.e"
#import "ini.e"
#import "last.e"
#import "listproc.e"
#import "main.e"
#import "mfsearch.e"
#import "moveedge.e"
#import "projconv.e"
#import "project.e"
#import "projutil.e"
#import "pushtag.e"
#import "seldisp.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "tagrefs.e"
#import "tbsearch.e"
#import "wkspace.e"
#import "xml.e"
#import "context.e"
#import "slickc.e"
#import "tbcmds.e"
#import "errorcfgdlg.e"
#import "cfg.e"
#endregion

 _str compile_rc;         /* Used for DOS to keep $errors.tmp file loaded. */
 _str _no_filename_index;
 _str _error_found;      /* Set by next when error message found. */

 _str _error_search;      /* Index to search for error function.  Set by init_error() */
 _str _error_parse;       /* Index to parse error function.  Set by init_error() */
 bool _error_init_done;     /* Set to 1 to indicate that init_error() has been called at least once */
 _str _error_filename;    // Error filename set by init_error(). New in V13

/*********************Windows only **************************/
// Microfocus cobol
static _str _microfocus_re='^\*[ \t]+{#1:i}-[a-z]\*\*{#0}';
/***************************************************************************/

int _pic_error_marker = 0;
int _pic_warning_marker = 0;
static int gpictype_error = 0;
static int gerror_scroll_mark_type = 0;


static const C_INCLUDE= '^[ \t]*(\#include|include|\#line)[ \t]#({#1:i}[ \t]#|)(<{#0[~>]#}>|"{#0[~"]#}")';
static const M_INCLUDE= '^[ \t]*(\#include|\#import|include|\#line)[ \t]#({#1:i}[ \t]#|)(<{#0[~>]#}>|"{#0[~"]#}")';
static const E_INCLUDE= '^[ \t]*(\#include|\#import|\#require|include)[ \t]#(''{#0[~'']#}''|"{#0[~"]#}")';
static const PAS_INCLUDE= '^[ \t]*\{(\$i|\(\*\$i)[ \t]#{#0[~} \t]#}';

static const BUILD_MESSAGE_TYPE= "Build Error";

////////////////////////////////////////////////////////////////////////////////
// New code for error parsing regular expressions. Now they are
// loaded from a configuration file
////////////////////////////////////////////////////////////////////////////////
//
struct COLLECTION_ITEM {
   _str regex;
   _str macro;
   _str sev;
};
static COLLECTION_ITEM gAllExpressions[];   // holds all the "global" error parsing expressions
static COLLECTION_ITEM gLangExpressions[];   // holds the language-specific parsing expressions
static COLLECTION_ITEM gExclusionExpressions[]; // holds expressions that are "false positive", meaning
                                     // that we don't actually want these guys to match an
                                     // error line.
static _str gLastLangId = "";

int def_max_error_markers = 1000;

/** 
 * If a build error message matches this regular expression, 
 * it will be categorized as an "Error" in the message list. 
 *  
 * @default "error"
 * @categories Configuration_Variables
 */ 
_str def_build_errors_re="error";

/**
 * If a build error message matches this regular expression, 
 * it will be categorized as a "Warning" in the message list.
 *  
 * @default "warning"
 * @categories Configuration_Variables
 */
_str def_build_warnings_re="warning";

/**
 * If a build is generating excessive errors, the number of 
 * messages generated can be capped by setting the limit to a 
 * value greater than 0. 
 *  
 * @default 1000
 * @categories Configuration_Variables
 */
int def_build_messages_limit = 1000;

_str GetErrorFilename()
{
   if (_isUnix()) {
      _str userName;
      _userName(userName);
      COMPILE_ERROR_FILE=_temp_path():+"vserr.":+userName;
   } else {
      COMPILE_ERROR_FILE=_temp_path():+"vserr.":+getpid();
   }
   return(COMPILE_ERROR_FILE);
}
void _exit_errfile()
{
   if (_file_eq(COMPILE_ERROR_FILE,_temp_path():+"vserr.":+getpid())) {
      delete_file(COMPILE_ERROR_FILE);
   }
   gAllExpressions._makeempty();
   gLangExpressions._makeempty();
   gExclusionExpressions._makeempty();
}

defload()
{
   _errorre_config_changed();

   // load the margin bitmap for errors
   _pic_error_marker = _update_picture(0, "_ed_error.svg");
   _pic_warning_marker = _update_picture(0, "_ed_warning.svg");

   load_include_re(C_INCLUDE,"c");
   load_include_re(C_INCLUDE,"ansic");
   load_include_re(C_INCLUDE,"java");
   load_include_re(C_INCLUDE,"rul");
   load_include_re(C_INCLUDE,"vera");
   load_include_re(C_INCLUDE,"ch");
   load_include_re(C_INCLUDE,"as");
   load_include_re(C_INCLUDE,"idl");
   load_include_re(C_INCLUDE,"masm");
   //load_include_re(C_INCLUDE,"s");
   load_include_re(C_INCLUDE,"imakefile");
   load_include_re(C_INCLUDE,"rc");
   load_include_re(C_INCLUDE,"lex");
   load_include_re(C_INCLUDE,"yacc");
   load_include_re(C_INCLUDE,"antlr");
   load_include_re(M_INCLUDE,"m");
   load_include_re(PAS_INCLUDE,"pas");
   load_include_re(E_INCLUDE,"e");
   init_error();
   rc=0;
}
static void load_include_re(_str value, _str ext)
{
   _LangSetProperty(ext,VSLANGPROPNAME_INCLUDE_RE,value);
}
int _activate_error_file(var mark,int &temp_view_id,bool &is_process_mark,_str &top_mark)
{
   top_mark='';
   is_process_mark=false;
   if ( _error_file=="" ) {
      _error_file=absolute(COMPILE_ERROR_FILE);
      //_error_file=absolute(GetErrorFilename())
   }
   status := 0;
   filename := "";
   orig_view_id := 0;
   int load_rc=_open_temp_view(_error_file,temp_view_id,orig_view_id,"+b");
   if ( load_rc ) {
      if (def_err) {
         // Check if an error file exists with .err extension.
         filename=_strip_filename(p_buf_name,'E')".err";
         load_rc=_open_temp_view(filename,temp_view_id,orig_view_id,"+l");
         if (_error_mark!="") {
            _deselect(_error_mark);
         }
      }
      if (!load_rc) {
         _error_file=filename;
         mark=_error_mark;
      } else {
         status=1;
         while (_process_error_file_stack._length()) {
            status=_open_temp_view(_process_error_file_stack[_process_error_file_stack._length()-1],temp_view_id,orig_view_id,"+b");
            if (!status) {
               break;
            }
            _process_error_file_stack._deleteel(_process_error_file_stack._length());
         }
         if (status) {
            // insert a view of the .process file.
            status=_open_temp_view(".process",temp_view_id,orig_view_id,"+b");
            if ( status ) {
               if ( status==FILE_NOT_FOUND_RC ) {
                  //message nls("No error message files")
                  status=STRING_NOT_FOUND_RC;
               } else {
                  message(get_message(status));
               }
               return(status);
            }
         }
         if (_process_mark._indexin(p_buf_name)) {
            mark=_process_mark:[p_buf_name];
         } else {
            mark='';
         }
         top_mark='';
         if (_top_process_mark._indexin(p_buf_name)) {
            top_mark=_top_process_mark:[p_buf_name];
         }
         if (top_mark=="") {
            top_mark=_alloc_selection('B');
            if ( top_mark<0 ) {
               message(get_message((int)top_mark));
               top_mark="";
               return(1);
            }
            top();
            _select_char(top_mark);
            _select_type(top_mark,'A',0 /* don't adjust column for backward compatibility*/ );

            _top_process_mark:[p_buf_name]=top_mark;
         }
         is_process_mark=true;
      }
   } else {
      mark=_error_mark;
   }
   if ( mark=="" ) {
      mark=_alloc_selection('b');
      if ( mark<0 ) {
         message(get_message(mark));
         return(1);
      }
      top();
      if (load_rc) {
         _SetNextErrorMark(mark);
      } else {
         _select_char(mark);
         _select_type(mark,'A',0 /* don't adjust column for backward compatibility*/ );
      }
   } else {
      if ( _select_type(mark)=="" ) {     /* mark deleted? */
         top();  /* Assume previous process was exited. */
                 /* Start from beginning of buffer */
         if (load_rc) {
            _SetNextErrorMark(mark);
         } else {
            _select_char(mark);
            _select_type(mark,'A',0 /* don't adjust column for backward compatibility*/ );
         }
      }
      _begin_select(mark);
   }
   if ( is_process_mark) {
      _process_mark:[p_buf_name]=mark;
   } else {
      _error_mark=mark;
   }
   return(0);

}

static _str GetVslickErrorPath()
{
   VSErrorPath := "";
   typeless filepos;
   save_pos(filepos);
   status := 0;
   for (;;) {
      if (_isUnix()) {
         status=search('VSLICKERRORPATH=','h@r<-');
      } else {
         status=search('VSLICKERRORPATH="?@"','h@r<-');
      }
      if (status) {
         break;
      }
      MaybeEcho := "";
      typeless seekpos=_QROffset();
      if (seekpos-5>=0) {
         MaybeEcho=get_text(5,seekpos-5);
      }
      if (MaybeEcho!="echo ") {
         break;
      }
      left();
   }
   //Found the real thing
   if (!status) {
      get_line(auto line);
      int p;
      if (_isUnix()) {
         p=pos('{VSLICKERRORPATH=?@}',line,1,'r');
      } else {
         p=pos('{VSLICKERRORPATH="?@"}',line,1,'r');
      }
      if (p) {
         if (_isUnix()) {
            p=pos("=",line);
            if (p) {
               VSErrorPath=substr(line,p+1);
            }
         } else {
            line=substr(line,pos('S0'),pos('0'));
            p=pos('"',line);
            lp := lastpos('"',line);
            if (p && lp && lp>p) {
               VSErrorPath=substr(line,p,lp-p+1);
               VSErrorPath=strip(VSErrorPath,'B','"');
            }
         }
      }
   }
   restore_pos(filepos);
   return(VSErrorPath);
}

definit()
{
   _error_init_done= false;
   gpictype_error = 0;
   gerror_scroll_mark_type = 0;
   _errorre_config_changed();
}

static int _error_marker_get_picture()
{
   if (!_pic_error_marker) {
      _pic_error_marker = _update_picture(-1, "_ed_error.svg");
   }
   return _pic_error_marker;
}

static int _warning_marker_get_picture()
{
   if (!_pic_warning_marker) {
      _pic_warning_marker = _update_picture(-1, "_ed_warning.svg");
   }
   return _pic_warning_marker;
}

static int _error_marker_get_pic_type()
{
   if (!gpictype_error) {
      gpictype_error = _MarkerTypeAlloc();
   }
   return gpictype_error;
}

static int _error_scroll_marker_get_type()
{
   if (!gerror_scroll_mark_type) {
      gerror_scroll_mark_type = _ScrollMarkupAllocType();
      _ScrollMarkupSetTypeColor(gerror_scroll_mark_type,CFG_ERROR);
   }
   return gerror_scroll_mark_type;
}

static const TEST_ESC_COUNT= 10;

_command void set_error_markers(_str options="")
{
   setErrorMarkers := false;
   setErrorScrollMarkers := false;

   if ( options=="" ) {
      // Support calling the "old way"
      setErrorMarkers = true;
   } else {
      for ( ;; ) {
         cur := lowcase(parse_file(options));
         if ( cur=="" ) break;
         if ( cur=="-m" ) {
            setErrorMarkers = true;
         } else if ( cur=="-s" ) {
            setErrorScrollMarkers = true;
         }
      }
   }
   if ( !setErrorMarkers && !setErrorScrollMarkers ) {
      return;
   }

   int orig_view_id;
   get_window_id(orig_view_id);  /* HERE - Need this for WorkFrame support so we can
                                  *        get back to the original view after
                                  *        "No more errors".
                                  */
  /* is there a errors temp file? */
   typeless mark="";
   temp_view_id := 0;
   typeless status = _activate_error_file(mark, temp_view_id,auto is_process_mark,auto top_mark);
   if (status) {
      return;
   }

   // We could still set the scroll markup if one of these returns 0, but even
   // if we are not adding the picture markup, these should return something 
   // valid.
   int error_bmp = _error_marker_get_picture();
   if (!error_bmp) {
      return;
   }
   warning_bmp := _warning_marker_get_picture();
   if (!warning_bmp) {
      return;
   }

   int error_pic_type = _error_marker_get_pic_type();
   if (!error_pic_type) {
      return;
   }
   // We could still set the pictures if one of this returns 0, but even
   // if we are not adding the scroll markup, this should return something 
   // valid.
   int error_scroll_markup_type = _error_scroll_marker_get_type();
   if (!error_scroll_markup_type) {
      return;
   }

   message("Setting error markers...");
   if ( setErrorMarkers ) _LineMarkerRemoveAllType(error_pic_type);
   if ( setErrorScrollMarkers ) _ScrollMarkupRemoveAllType(error_scroll_markup_type);
   se.messages.MessageCollection* mCollection = get_messageCollection();
   mCollection->removeMessages(BUILD_MESSAGE_TYPE);
   messageCount := 0;
   typeless p; save_pos(p); //save pos in error file

   _str filenameMap:[];
   add_include_path := "";
   if (_ini_get_value(_project_name, "COMPILER."GetCurrentConfigName(), "includedirs", add_include_path) != 0){
      add_include_path = "";
   }

   msgType := "";
   markerHandle := -1;
   mCollection->startBatch();

   line := 0;
   col := 0;
   err_msg := "";
   filename := "";
   last_filename := "";
   found_filename := "";
   source_view_id := 0;
   file_already_loaded := false;
   int check_esc_count = TEST_ESC_COUNT;
   err_count := 0;
   int buildLine;
   for (;;) {
      if (--check_esc_count < 0) {
         if( _IsKeyPending(false)) {
            break;
#if 0 //9:42am 11/17/2010
            int orig_def_actapp=def_actapp;
            def_actapp=0;
            int result1=_message_box("Would you like to cancel setting error markers?","",MB_YESNOCANCEL);
            def_actapp=orig_def_actapp;
            if (result1!=IDNO) {
               break;
            }
#endif
         }
         check_esc_count = TEST_ESC_COUNT;
      }
      activate_window(temp_view_id);
      rc := call_index("", _error_search);
      if (rc) {
         break;
      }
      _end_line();
      buildLine = p_line;
      matchText := get_match_text();
      vid := '';
      alt := '';
      severity := 'Error';

      call_index(filename, line, col, err_msg, vid, alt, severity,
                 _error_parse);
      if ( filename != "" ) {

         status = 0;
         filename=strip(filename,'B','"');

         // the wrong file was being returned in the following example
         // where the full path to the file is not provided:
         //
         //    projectdir/
         //       main.c
         //       subdir1/main.c
         //       subdir2/main.c   <-- error in this file
         //
         //    main.c
         //    main.c(8) : error C2065: 'project3' : undeclared identifier
         //
         // by determining the absolute path to the file before
         // doing the file_exists, the problem is avoided
         //
         // 
         _str VslickErrorPath=GetVslickErrorPath();
         absoluteFilename := absolute(filename, VslickErrorPath);

         hashtableKey :=  filename"\1"VslickErrorPath;
         if (filenameMap._indexin(hashtableKey)) {
            // have we already seen a file with this filename?
            if (filenameMap:[hashtableKey] == FILE_NOT_FOUND_RC) {
               status = FILE_NOT_FOUND_RC;
            } else {
               filename = filenameMap:[hashtableKey];
            }
         } else {
            bool found_it;

            status= common_find_error_file(found_it,absoluteFilename,filename,VslickErrorPath,add_include_path,false);
            if (!found_it) {
               status = FILE_NOT_FOUND_RC;
               filenameMap:[hashtableKey] = FILE_NOT_FOUND_RC;
            } else {
               filenameMap:[hashtableKey] = filename;
            }
         }

         if (!status && (filename != last_filename)) {
            if (source_view_id) {
               _delete_temp_view(source_view_id, !file_already_loaded);
               source_view_id = 0;
               file_already_loaded = false;
            }
            if (iswildcard(filename) && !file_exists(filename)) {
               status=FILE_NOT_FOUND_RC;
            } else if (file_exists(filename)) {
               int junk;
               status = _open_temp_view(_maybe_quote_filename(filename), source_view_id, junk,"", file_already_loaded);
               if (status==NEW_FILE_RC) {
                  // This should never happen but just in case
                  status=0;
               }
            } else {
               // Did not really create a new file.
               // It is an error code we check for below
               status=NEW_FILE_RC;
            }
            last_filename = (!status) ? filename : "";
         } else {
            status = (last_filename != "") ? 0 : FILE_NOT_FOUND_RC;
         }
         if (!status) {
            activate_window(source_view_id);
            if ( line!="" ) {
               GoToErrorLine(line);
            }
            // drop pic here
            auto pic = (pos("error", severity, 1, 'i') > 0) ? error_bmp : warning_bmp;
            if ( setErrorMarkers ) {
               markerHandle = _LineMarkerAdd(p_window_id, p_line, false, 0, pic,
                                             error_pic_type, err_msg);
            }
            if ( setErrorScrollMarkers ) {
               _ScrollMarkupAdd(p_window_id, p_line, error_scroll_markup_type);
            }

            if (messageCount < def_build_messages_limit) {

               se.messages.Message tmpMsg;
               tmpMsg.m_creator = BUILD_MESSAGE_TYPE;
               tmpMsg.m_type = getMessageType(err_msg, matchText);
               tmpMsg.m_description = err_msg;
               tmpMsg.m_sourceFile = filename;
               tmpMsg.m_lineNumber = line;
               tmpMsg.m_colNumber = col;
               tmpMsg.m_date = "";
               if ( setErrorMarkers ) {
                  tmpMsg.m_markerPic = pic;
               }
               tmpMsg.m_lmarkerID = markerHandle;
               tmpMsg.m_attributes:["build window line"] = buildLine;

               se.messages.MenuItem tmpMenuItem;
               tmpMenuItem.m_menuText = "Go to Build Output";
               tmpMenuItem.m_callback = "goToBuildOutput";
               tmpMsg.m_menuItems[0] = tmpMenuItem;

               mCollection->newMessage(tmpMsg);

               ++messageCount;
            }
         }
      }

      err_count++;
      if ((def_max_error_markers > 0) && (err_count > def_max_error_markers)) {
         break;
      }
   }
   mCollection->endBatch();
   mCollection->notifyObservers();
   activate_window(temp_view_id);
   restore_pos(p);
   activate_window(orig_view_id);
   // clean up temp files
   if (source_view_id) {
      _delete_temp_view(source_view_id, !file_already_loaded);
   }
   _delete_temp_view(temp_view_id, false);
   clear_message();
}

_command void clear_all_error_markers()
{
   int _pictype = _error_marker_get_pic_type();
   if (_pictype) {
      _LineMarkerRemoveAllType(_pictype);
      se.messages.MessageCollection* mCollection = get_messageCollection();
      mCollection->removeMessages(BUILD_MESSAGE_TYPE);
   }

   int scrollMarkerType = _error_scroll_marker_get_type();
   if ( scrollMarkerType ) {
      _ScrollMarkupRemoveAllType(scrollMarkerType);
   }
}

int def_quit_error_file=0;        /* HERE - Added this for WorkFrame support so
                                   *        that COMPILE_ERROR_FILE would not be
                                   *        quit by default when there are no more
                                   *        errors.
                                   */
// For empty extensions
_str def_next_error_try_ext_list;

static int common_find_error_file(bool &found_it,_str absoluteFilename, _str &filename,_str VslickErrorPath, _str add_include_path='',bool allow_prompting=true) {
   found_filename := "";
   found_it = false;
   static _str last_dir;
   try_ext_list:=def_next_error_try_ext_list;
   _str try_ext='';
   for (;;) {
      if(file_exists(absoluteFilename:+try_ext)) {
         // file found so use this filename for the rest of the function
         filename = absoluteFilename:+try_ext;
         found_it=true;
      } else {
         // file not found so search for it
         if (VslickErrorPath!="") {
            found_filename=include_search(filename:+try_ext,VslickErrorPath);
            if (found_filename!="") {
               filename=found_filename;
               found_it=true;
            }
         }

         // if not found, search for file in the current project and workspace
         if (!found_it) {
            if (allow_prompting) {
               found_filename=_ProjectWorkspaceFindFile(filename:+try_ext);
            } else {
               found_filename=_ProjectWorkspaceFindFile(filename:+try_ext, true, false, true);
            }
            if (found_filename==COMMAND_CANCELLED_RC) {
               return COMMAND_CANCELLED_RC;
            }
            if (found_filename!="") {
               filename = parse_file(found_filename, false);
               found_it=true;
            }
         }

         // if still not found, try prompting for path
         if (!found_it) {
            if (allow_prompting && last_dir!="" && file_exists(last_dir:+filename:+try_ext)) {
               filename=last_dir:+filename:+try_ext;
               found_it=true;
            }
         }
      }
      if (found_it) {
         break;
      }

      if (get_extension(filename)=='') {
         try_ext=parse_file(try_ext_list,false);
         if (try_ext=='') {
            break;
         }
         continue;
      }
      break;
   }

   if (!found_it && allow_prompting) {
      found_dir := _strip_filename(filename,"N");
      just_filename := _strip_filename(filename,"P");
      found_filename = _ChooseDirDialog("Find File",found_dir,just_filename);
      if (found_filename=="") {
         return(COMMAND_CANCELLED_RC);
      }
      filename=found_filename:+just_filename;
      last_dir=found_filename;
   }
   return 0;
}
/**
 * <p>The <b>next_error</b> command ("Build", "Next error") places the cursor
 * on the line and column of the file referred to by the next error message.</p>
 *
 * <p>For more information, see help on <b>project_build</b>.</p>
 *
 * @param resetMessages    If set to 'R', reset error messages search
 * @param unusedArg2       unused
 * @param displayMessages  Display error messages on the message bar?
 * @param lookingBackwards If set to '-', search backwards for errors
 *
 * @see start_process
 * @see stop_process
 * @see cursor_error
 * @see exit_process
 * @see set_next_error
 * @see reset_next_error
 * @see clear_pbuffer
 *
 * @appliesTo Edit_Window
 *
 * @categories Miscellaneous_Functions
 *
 */
_command int next_error(_str resetMessages="",
                        _str unusedArg2="",
                        _str displayMessages="",
                        _str lookingBackwards="") name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI|VSARG2_AUTO_DESELECT)
{
   if (isEclipsePlugin()) {
      return _eclipse_next_error(p_window_id);
   }
   if (_mfXMLOutputIsActive && _LanguageInheritsFrom("xml") || p_name == "ctloutput") {
      if (xmlMoveToError(true)) {
         message("No more errors");
         _beep();
      }
      return 0;
   }
   if (p_active_form.p_modal) {
      return(1);
   }
   typeless status=0;
   if (_mffindActive(2)) {
      status=_mffindNext();
      if (status==NO_MORE_FILES_RC) {
         message("No more occurrences");
         _beep();
      } else if(status){
         _beep();
      }
      return(status);
   }
   if (_mfrefActive(2)) {
      status=next_ref(false,true);
      if (status==NO_MORE_FILES_RC) {
         message("No more occurrences");
         _beep();
      } else if(status){
         _beep();
      }
      return(status);
   }
   if ( !_error_init_done ) {
      init_error();
   }

   // mark which buffers were open before we navigate to the next error
   _mdi.p_child.mark_already_open_destinations();
   orig_buf_id := 0;
   orig_window_id := 0;
   if (!_no_child_windows() && _mdi.p_child.pop_destination()) {
      orig_window_id = _mdi.p_child;
      orig_buf_id = _mdi.p_child.p_buf_id;
   }

/*#if __UNIX__
   if (resetMessages=="" && _sbhas_errors()) {
      return(sbnext_error());
   }
#endif*/
   p_window_id=_mdi.p_child;
   old_buffer_name := "";
   typeless swold_pos;
   swold_buf_id := 0;
   set_switch_buffer_args(old_buffer_name,swold_pos,swold_buf_id);
   /* Preserve column position for the case where the error message */
   /* does not display a column and the active buffer contains the error. */
   old_col := p_col;
   int old_buf_id=p_buf_id;

   orig_view_id := 0;
   get_window_id(orig_view_id);  /* HERE - Need this for WorkFrame support so we can
                               *        get back to the original view after
                               *        "No more errors".
                               */

   /* is there a errors temp file? */
   typeless mark;
   temp_view_id := 0;
   status=_activate_error_file(mark,temp_view_id,auto is_process_mark,auto top_mark);
   if ( status ) {
      if (upcase(resetMessages)!="R") {
         // no message files
         if (status==STRING_NOT_FOUND_RC) {
            _message_box(nls("No error message files"));
         }
      }
      status=1;
      return(status);
   }
   looking_backwards := lookingBackwards!="";
   //if arg(4) is non-null, we are looking backwards.  arg(2) is unused,
   //but I was worried that it might be reserved.
   if ( upcase(resetMessages)=="R" ) {  /* reset messages? */
      if (top_mark!='') {
         goto_read_point();
         _deselect(top_mark);clear_message();_select_char(top_mark);
         _select_type(top_mark,'A',0 /* don't adjust column for backward compatibility*/ );
         clear_all_error_markers();
      }
      rc=1;
   } else {
      message(nls("Searching..."));
      if (looking_backwards) {
         _begin_line();
         //Since the mark is always at the end of the line, If we are looking
         //backwards we always go to the beginning of the line first so that
         //we don't find the line that we are on.
      }
      rc=call_index(lookingBackwards,_error_search);
   }
   filename := "";
   line := 0;
   col := 0;
   err_msg := "";
   if ( ! rc ) {
      compile_rc=0;
      _end_line();
      if (is_process_mark) {
         _SetNextErrorMark(mark,upcase(resetMessages)=="R");
      } else {
         //_SetNextErrorMark(_error_mark);
         _deselect(mark);_select_char(mark); //Always put mark at end of the line.
         _select_type(mark,'A',0 /* don't adjust column for backward compatibility*/ );
      }
      call_index(filename,line,col,err_msg,_error_parse);
      err_msg=stranslate(err_msg,"\n","\r\n");
      err_msg=stranslate(err_msg,' ','[\r\n]( @)','r');
      if ( filename!="" ) {
         filename=strip(filename,'B','"');

         // the wrong file was being returned in the following example
         // where the full path to the file is not provided:
         //
         //    projectdir/
         //       main.c
         //       subdir1/main.c
         //       subdir2/main.c   <-- error in this file
         //
         //    main.c
         //    main.c(8) : error C2065: 'project3' : undeclared identifier
         //
         // by determining the absolute path to the file before
         // doing the file_exists, the problem is avoided
         //
         _str VslickErrorPath=GetVslickErrorPath();
         absoluteFilename := absolute(filename, VslickErrorPath);
         bool found_it;
         status=common_find_error_file(found_it,absoluteFilename,filename,VslickErrorPath);
         if (status) {
            return status;
         }

         activate_window(orig_view_id);
         if (iswildcard(filename) && !file_exists(filename)) {
            status=FILE_NOT_FOUND_RC;
         } else if(file_exists(filename)){
            status=edit(_maybe_quote_filename(filename));
            if (status==NEW_FILE_RC) {
               // This should never happen but just in case
               status=0;
            }
         } else {
            // Did not really create a new file.
            // It is an error code we check for below
            status=NEW_FILE_RC;
         }
         if ( ! status ) {
            switch_buffer(old_buffer_name,"",swold_pos,swold_buf_id);
         }
         if ( status ) {
            if ( status==NEW_FILE_RC ) {
               err_msg=nls("File '%s' not found",filename);
            } else {
               err_msg=nls("Error loading file '%s'",filename)".  "get_message(status);
            }
            if ( status ) {
               if (upcase(resetMessages)!="R") {
                  _message_box(err_msg);
               }
               _delete_temp_view(temp_view_id,false);
               activate_window(orig_view_id);

               return(1);
            }
         }
      }
      source_view_id := 0;
      get_window_id(source_view_id);
      _delete_temp_view(temp_view_id,false);
      if (source_view_id!=temp_view_id) {
         activate_window(source_view_id);
      }

      typeless old_scroll_style=_scroll_style();
      _scroll_style('c');
      _error_found=1;
      if ( line!="" ) {
         GoToErrorLine(line);
      }
      _scroll_style(old_scroll_style);
      if ( col!="" ) {
         p_col=_text_colc(col,'I');
      } else if ( p_buf_id==old_buf_id ) {
         p_col=old_col;
      }
      if (_no_child_windows() && upcase(resetMessages)!='R') {
         VSWID_STATUS._set_focus();
         sticky_message(err_msg);
         //_message_box(err_msg);
      } else {
         sticky_message(err_msg);
      }
      /* sticky_message "filename="filename" line="line" col="col */
   } else {
      status=STRING_NOT_FOUND_RC;
      _str message_text=nls("No more errors");
      if ( _file_eq(p_buf_name,_error_file) ) {
         status=2;  // Indicate that there were no more errors in error file
         p_modify=false;
         if ( compile_rc ) {
            activate_window(orig_view_id);
            typeless result=edit(_maybe_quote_filename(_error_file));
            if (!result) {
               bottom();
            }
         } else if( def_quit_error_file ) {
            _str buf_name=p_buf_name;
            int buf_id=p_buf_id;
            _delete_temp_view(temp_view_id);
            activate_window(orig_view_id);
            if (def_one_file!="") {
               // Delete all mdi windows which are displaying this buffer.
               count := 0;
               wid := window_match(buf_name,1,'xn');
               for (;;) {
                  if (!wid) break;
                  if (wid.p_mdi_child) ++count;
                  wid=window_match(buf_name,0,'xn');
               }
               if (count>=1) {
                  wid=window_match(buf_name,1,'xn');
                  while (count--) {
                     // If deleting last window
                     if (wid.p_mdi_child) {
                        if (!count) {
                           // Delete the window and the buffer
                           wid.close_window("",false);
                        } else {
                           // Delete the window and not the buffer.
                           wid._delete_window();
                        }
                     }
                     wid=window_match(buf_name,0,'xn');
                  }
               } else {
                  status=edit(" +bp +bi "buf_id);
                  quit();
               }
            } else {
               status=edit(" +bp +bi "buf_id);
               quit();
               /*orig_wid=p_window_id;
               close_buffer(false);
               if (orig_wid==p_window_id) {
                  _delete_view();
               } */
            }
            if (_error_file=="") {
               //_error_file=COMPILE_ERROR_FILE;
               _error_file=GetErrorFilename();//GetErrorFilename sets COMPILE_ERROR_FILE
            }
            message_text :+= ". "nls("%s file quit",_error_file);
            if ( displayMessages ) { /* Display message? */
               if (_no_child_windows() && upcase(resetMessages)!="R") {
                  //_message_box(message_text);
                  VSWID_STATUS._set_focus();
                  sticky_message(message_text);
               } else {
                  sticky_message(message_text);
               }
            }
            compile_rc=0;
            return(status);
         } else {
            #if 1   /* HERE - Added this for WorkFrame support so we could
                     *        keep the error file open.
                     */
            /* If we are at the *first* or *last* error, then put _error_mark at
             * top/bottom, so we can correctly do a prev_error() later.
             */
            if( lookingBackwards=="" ) {  /* Just did a next_error()? */
               bottom();
            } else {   /* Just did a prev_error()? */
               top();
            }
            if (is_process_mark) {
               _SetNextErrorMark(mark,upcase(resetMessages)=="R");
            } else {
               _deselect(mark);_select_char(mark);
               _select_type(mark,'A',0 /* don't adjust column for backward compatibility*/ );
            }
            _delete_temp_view(temp_view_id,false);
            activate_window(orig_view_id); /* HERE - Need this for WorkFrame support
                                          *        so we can get back to the original
                                          *        view when "No more errors".
                                          */
            if ( displayMessages ) { /* Display message? */
               if (_no_child_windows() && upcase(resetMessages)!="R") {
                  //_message_box(message_text);
                  VSWID_STATUS._set_focus();
                  sticky_message(message_text);
               } else {
                  sticky_message(message_text);
               }
            }
            return(status);
            #endif
         }
         compile_rc=0;
      }
      activate_window(temp_view_id);
      //_deselect mark;goto_read_point();p_col=1;_select_char mark
      if (resetMessages=="R"||!looking_backwards) {
         goto_read_point();// Only go to bottom if Reseting errors
      }
      if (!looking_backwards) {
         p_col=1;//Go beginning of line in case the process is halfway through
                 //writing a line
      }
      if (is_process_mark) {
         _SetNextErrorMark(mark,upcase(resetMessages)=="R");
      } else {
         _deselect(mark);_select_char(mark);
         _select_type(mark,'A',0 /* don't adjust column for backward compatibility*/ );
      }
      _delete_temp_view(temp_view_id,false);
      activate_window(orig_view_id);
      if ( displayMessages ) {
         if (_no_child_windows() && upcase(resetMessages)!="R") {
            //_message_box(message_text);
            VSWID_STATUS._set_focus();
            sticky_message(message_text);
         } else {
            sticky_message(message_text);
         }
      }
   }
   if (!status) {
      // if we navigated somewhere successfully, push the destination
      // so that we can automatically close it when we are done.
      _mdi.p_child.push_destination(orig_window_id, orig_buf_id);
   }
   return(status);
}

/**
 * <p>The <b>prev_error</b> command ("Build", "Previous error") places
 * the cursor on the line and column of the file referred to by the previous
 * error message.</p>
 *
 * <p>For more information, see help on <b>project_build</b>.</p>
 *
 * @see start_process
 * @see stop_process
 * @see cursor_error
 * @see exit_process
 * @see set_next_error
 * @see reset_next_error
 * @see clear_pbuffer
 *
 * @appliesTo Edit_Window
 *
 * @categories Miscellaneous_Functions
 *
 */
_command int prev_error() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI|VSARG2_AUTO_DESELECT)
{
   if (isEclipsePlugin()) {
      return _eclipse_prev_error(p_window_id);
   }
   if (_mfXMLOutputIsActive && _LanguageInheritsFrom("xml") || p_name == "ctloutput") {
      if (xmlMoveToError(false)) {
         message("No more errors");
         _beep();
      }
      return 0;
   }

   if (p_active_form.p_modal) {
      return(1);
   }
   typeless status=0;
   if (_mffindActive(2)) {
      status=_mffindPrev();
      if (status==NO_MORE_FILES_RC) {
         message("No more occurrences");
         _beep();
      } else if(status){
         _beep();
      }
      return(status);
   }
   if (_mfrefActive(2)) {
      status=prev_ref(false,true);
      if (status==NO_MORE_FILES_RC) {
         message("No more occurrences");
         _beep();
      } else if(status){
         _beep();
      }
      return(status);
   }
/*#if __UNIX__
   if (_sbhas_errors()) {
      return(sbprev_error());
   }
#endif*/
   return(next_error("","","","-"));
   /* arg(4) means to actually look for the previous error. */
   /* arg(1) and arg(3) are already used.  arg(2) doesn't seem to be, */
   /* but I didn't want to take it over now, and be wrong later. */
}

/**
 * Places the cursor on the "read point" of the build window.
 * Process output is inserted before the "read point."  If the read point is not
 * found, the cursor is placed on the first line of the process buffer and the
 * column position is left unchanged.  The build window must be
 * active before calling this function.
 *
 * @categories CursorMovement_Functions
 *
 */
void goto_read_point()
{
   bottom();
   if ( ! _process_info('b') ) {
      return;
   }
   for (;;) {
     if ( _process_info('c') ) {
        p_col=_process_info('c');
        break;
     }
     up();
     if ( rc ) {
        break;
     }
   }
}
int _process_get_read_point_linenum(int &col=0) {
   save_pos(auto p);
   goto_read_point();
   if (_process_info('c')) {
      col=_process_info('c');
   } else {
      col=1;
   }
   linenum:=p_line;
   restore_pos(p);
   return linenum;
}

static bool _is_grep_goto()
{
   if (p_LangId == "grep" || p_name == "ctloutput") {
      _str filename;
      int linenum,col;
      int status=_mffindGetDest(filename,linenum,col,true);
      if (status) {
         return(false);
      }
      return(true);
   }
   return(false);
}
static bool _is_cursor_error()
{
   return( p_mdi_child ||
           (_process_info("B") || _file_eq(_strip_filename(p_buf_name,"P"),COMPILE_ERROR_FILE)) ||
           p_active_form.p_name == "_tbshell_form" ||
           p_active_form.p_name == "_terminal_form" ||
              p_active_form.p_name == "_tboutputwin_form"
         );
}
int _OnUpdate_cursor_error(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }
   if (!_is_grep_goto() && !_is_cursor_error()) {
      return(MF_GRAYED);
   }
   return(MF_ENABLED);
}

/**
 * This command is typically invoked when the build window
 * (created by the <b>start_process</b> command) is active, to process
 * compiler error messages from within the editor.  However, it can also
 * be used to edit a filename such as an include filename at the cursor.
 * The current line is assumed to contain a filename and possibly a line
 * and column number.  The cursor is placed on the line and column of file
 * specified by the current line.  Otherwise the filename at or before the
 * cursor is loaded for editing.  The search strategy for include files
 * is as follows:
 * <OL>
 * <LI>Current directory.
 * <LI>Same directory as current buffer.
 * <LI>Include directories specified by current project.
 * </OL>
 * @return  Returns 0 if successful. Common return values are TOO_MANY_FILES_RC,
 * TOO_MANY_SELECTIONS_RC, and FILE_NOT_FOUND_RC.  On error, message is displayed.
 *
 * @see next_error
 *
 * @appliesTo  Edit_Window
 * @categories Miscellaneous_Functions
 */
_command cursor_error() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_MDI)
{
   return(cursor_error2());
}
_command cursor_error2() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_MDI)
{
   if(!isVisualStudioPlugin()) {
      if (_is_grep_goto()) {
         return(grep_goto());
      }
      if (!_is_cursor_error()) {
         return("");
      }
   }

   status := 0;
   filename := "";
   found_filename := "";
   err_msg := "";

   // Try custom goto include code
   tag_init_tag_browse_info(auto cm);
   status=tag_get_current_include_info(cm);
   if (!status) {
      status=_resolve_include_file(cm.file_name);
      if (status) return(status);
      push := !((p_buf_flags & VSBUFFLAG_HIDDEN) || beginsWith(p_buf_name,".process"));
      if (push && def_search_result_push_bookmark) {
         push_bookmark();
      }
      status=tag_edit_symbol(cm);
      if (!status && push) {
         push_destination();
      }
      return(status);
   }
   text := "";
   save_pos(auto p2);
   begin_line();
   text=get_text(4096);
   restore_pos(p2);

   info := "";
   orig_view_id := 0;
   get_window_id(orig_view_id);
   status=0;
   // We might be on compiler error message
   if ( !_error_init_done ) {
      init_error();
   }
   int temp_view_id;
   int orig_view_id2=_create_temp_view(temp_view_id);
   if ( orig_view_id2=="") return(1);
      //insert_line(text);p_col=1;
   _insert_text(text);top();
   status=call_index(_error_search);
   // We need to support multi-line errors (e.g. Python), so requiring
   // that the match be all on one line is no longer workable.
   //if (!status && p_line!=1) status=STRING_NOT_FOUND_RC;
   _delete_temp_view();
   activate_window(orig_view_id2);
   if (!status) {
         // Error search the real buffer
      typeless p3;
      save_pos(p3);
      begin_line();
      _str top_mark='';
      if (_top_process_mark._indexin(p_buf_name)) {
         top_mark=_top_process_mark:[p_buf_name];
      }
      if (!_process_info('b') || top_mark=="" || _select_type(top_mark)=="") {
         status=call_index(_error_search);
      } else {
         // Make sure when past_top_error() is called that it succeeds.
         _str orig_top_process_mark=_top_process_mark:[p_buf_name];

         new_top_mark:=_alloc_selection('B');
         up(20);
         if (_on_line0()) top();
         _select_char(new_top_mark);
         _select_type(new_top_mark,'A',0 /* don't adjust column for backward compatibility*/ );
         _top_process_mark:[p_buf_name]=new_top_mark;
         restore_pos(p3);_begin_line();

         status=call_index(_error_search);

         if (orig_top_process_mark==null) {
            _top_process_mark._deleteel(p_buf_name);
         } else {
            _top_process_mark:[p_buf_name]=orig_top_process_mark;
         }
         _free_selection(new_top_mark);
      }
      restore_pos(p3);
   }
   if (status) {
      clear_message();
         //We might need to add support file:// here too.
      http_extra := 'http\:/|ttp\:/|tp\:/|p\:/|\:/|/|';
      search(':q|('http_extra'\:|):p|^','rh-');   /* Search for Filename */
      filename=get_match_text();
         //messageNwait("filename="filename);
      filename=strip(filename,'B',"'");    /* Strip quotes if any */
      filename=_maybe_quote_filename(filename);
      activate_window(orig_view_id);
      status=0;
      if (filename!="") {
         status=_resolve_include_file(filename);
         if (!status) {
            tag_init_tag_browse_info(cm);
            cm.file_name=filename;
            cm.line_no= -1;
            push := !((p_buf_flags & VSBUFFLAG_HIDDEN) || beginsWith(p_buf_name,".process"));
            if (push && def_search_result_push_bookmark) {
               push_bookmark();
            }
            status=tag_edit_symbol(cm);
            if (!status && push) {
               push_destination();
            }
            return(status);
         }
      }
      return(FILE_NOT_FOUND_RC);
   }
   line := "";
   col := 0;
   call_index(filename,line,col,err_msg,_error_parse);
   err_msg=stranslate(err_msg,"\n","\r\n");
   err_msg=stranslate(err_msg,' ','[\r\n]( @)','r');
   status=0;
   if ( filename!="" ) {
      filename=strip(filename,'B','"');
      activate_window(orig_view_id);
      set_next_error(true,true);


      _str VslickErrorPath=GetVslickErrorPath();
      absoluteFilename := filename; //absolute(filename, VslickErrorPath); This maybe should be uncommented
      bool found_it;
      status=common_find_error_file(found_it,absoluteFilename,filename,VslickErrorPath);
      if (status) {
         return status;
      }      // give up and curl up in the corner and cry
      if (!found_it) {
         sticky_message(nls("File '%s' not found",filename));
      } else {
         status=edit(_maybe_quote_filename(filename));
      }
      if ( ! status ) {
         #if 1   /* HERE - 5/30/1995 - uniconize the file if necessary */
         if(upcase(p_window_state)=='I' ) {
            p_window_state='N';
         }
         #endif
         typeless old_scroll_style=_scroll_style();
         _scroll_style('c');
         if ( line!="" ) {
            GoToErrorLine((typeless)line);
         }
         if (!p_IsTempEditor && (_lineflags() & HIDDEN_LF)) {
            expand_line_level();
         }
         _scroll_style(old_scroll_style);
         if ( col!="" ) {
            p_col=_text_colc(col,'I');
         }
      }
   }
   if ( ! status ) {
      sticky_message(err_msg);
   }
   if (!status) {
      int mdi_wid=_MDICurrent();
      if (mdi_wid) {
         mdi_wid._set_foreground_window();
      }
   }
   return(status);

}
void GoToErrorLine(int LineNumber)
{
   if (MessageBrowserMaybeMapLocation(p_buf_name, auto newLineNumber, auto newColumn, LineNumber)) {
      p_RLine = newLineNumber;
      if (!p_IsTempEditor && (_lineflags() & HIDDEN_LF)) {
         expand_line_level();
      }
      return;
   }

   if (!gerror_info._indexin(p_buf_name)) {
      if (p_buf_size<def_use_old_line_numbers_ksize*1024) {
         _SetAllOldLineNumbers();
         gerror_info:[p_buf_name]=1;
      }
   }
   if (!gerror_info._indexin(p_buf_name)) {
      p_RLine=LineNumber;
   } else {
      _GoToOldLineNumber(LineNumber);
   }
   if (!p_IsTempEditor && (_lineflags() & HIDDEN_LF)) {
      expand_line_level();
   }
}

/**
 * Finds the last SlickEdit interpreter run time error.  The module
 * with the error is loaded and the cursor is placed on the line causing the
 * error.  By default, only errors that cause a dialog box with the title
 * "Slick-C&reg; Error" can be found.  However, if you want mild errors displayed,
 * which occur in some built-in functions, turn on the weak errors option (see
 * <b>_default_option</b> function for more information).
 *
 * @categories Miscellaneous_Functions
 */
_command void find_error() name_info(','VSARG2_REQUIRES_MDI|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveProMacros()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Slick-C Debugging");
      return;
   }
   typeless pcode_offset="";
   filename := "";
   parse error_pos() with pcode_offset filename;
   filename=_strip_filename(filename,'E');
   _str sourcefilename= slick_path_search(filename:+_macro_ext);
   if (_isWindows()) {
      if ( sourcefilename=="" ) {  /* Might be .cmd file. */
         sourcefilename= slick_path_search(filename".cmd");
      }
   }
   if ( sourcefilename=="" ) {
      message(nls("Can't find error"));
      return;
   }
   st("-f "pcode_offset " "_maybe_quote_filename(sourcefilename));
}
/**
 * Sets the <b>next_error</b> commands start search position to the
 * cursor.  This command is no longer very useful since the
 * <b>cursor_error</b> command also sets the start search position.
 *
 * @param beQuiet       do not display message box on error
 * @param gotoEndOfLine jump to end of line containing message
 *
 * @see reset_next_error
 * @see cursor_error
 * @see next_error
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command int set_next_error(_str beQuiet="", _str gotoEndOfLine="") name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   doEndLine := gotoEndOfLine!="" && gotoEndOfLine;
   quiet := beQuiet!="";
   typeless mark;
   bool is_process_mark=false;
   _str top_mark='';
   if ( beginsWith(p_buf_name,".process") ) {
      if (_process_mark._indexin(p_buf_name)) {
         mark=_process_mark:[p_buf_name];
      } else {
         mark='';
      }
      top_mark='';
      if (_top_process_mark._indexin(p_buf_name)) {
         top_mark=_top_process_mark:[p_buf_name];
      }
      is_process_mark=true;
      if (p_buf_name=='.process') {
         _process_error_file_stack._makeempty();
      } else {
         _push_next_error_terminal();
         return 0;
      }
   } else if ( _file_eq(p_buf_name,_error_file) ) {
      mark=_error_mark;
   } else if ( _file_eq(_strip_filename(p_buf_name,'P'),COMPILE_ERROR_FILE) &&
      (_error_mark=="" || _select_type(_error_mark)=="") ) {
      _error_file=p_buf_name;
      mark=_error_mark;
   } else {
      if (quiet) {
         return(1);
      }
      _message_box(nls("Build tab or %s must be active",COMPILE_ERROR_FILE));
      return(1);
   }
   if ( mark == "" ) {
      mark = _alloc_selection('b');
      if ( beginsWith(p_buf_name,".process") ) {
         _process_mark:[p_buf_name]=mark;
      } else {
         _error_mark=mark;
      }
   }
   typeless p;
   if (doEndLine) {
      save_pos(p);
      _end_line();
   }
   if (is_process_mark) {
      _SetNextErrorMark(mark);
   } else {
      _deselect(_error_mark);
      _select_char(_error_mark);
      _select_type(_error_mark,'A',0 /* don't adjust column for backward compatibility*/ );
   }
   if (doEndLine) {
      restore_pos(p);
   }
   //_deselect(mark);_select_char(mark);
   if (past_top_error(top_mark)) {
      _deselect(top_mark);clear_message();_select_char(top_mark);
      _select_type(top_mark,'A',0 /* don't adjust column for backward compatibility*/ );
   }
   //_error_mark=mark;   /* HERE - Added this bug-fix with WorkFrame support */
   return(0);
}
/**
 * Sets the <b>next_error</b> command's start search position to the end
 * of the build window (".process").
 *
 * @see set_next_error
 *
 * @categories Miscellaneous_Functions
 *
 */
_command void reset_next_error(_str reset_build_errors="", _str unused2="", _str notused_displayMessages="") name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   tag_close_bsc();
   _mffindNoMore(2);
   _mfrefNoMore(2);
   init_error();
   if (reset_build_errors=='') {
      _process_error_file_stack._makeempty();
      gerror_info._makeempty();
   /*#if __UNIX__
      _sbreset_next_error();
   #endif*/
      p_window_id.next_error("R","",0);
   }
}
void _push_next_error_terminal(bool set_top_mark=false) {
   for (i:=0;i<_process_error_file_stack._length();++i) {
      if (_process_error_file_stack[i]==p_buf_name) {
         _process_error_file_stack._deleteel(i);
         break;
      }
   }
   _process_error_file_stack[_process_error_file_stack._length()]=p_buf_name;
   if (!_process_mark._indexin(p_buf_name)) {
      markid:=_alloc_selection('b');
      _process_mark:[p_buf_name]=markid;
   }
   _str markid=_process_mark:[p_buf_name];

   if (!_top_process_mark._indexin(p_buf_name)) {
      top_markid:=_alloc_selection('b');
      _top_process_mark:[p_buf_name]=top_markid;
   }
   save_pos(auto p);
   if (set_top_mark) {
      goto_read_point();
      _str top_mark=_top_process_mark:[p_buf_name];
      _deselect(top_mark);clear_message();_select_char(top_mark);
      _select_type(top_mark,'A',0);
   } else {
      _end_line();
   }
   _SetNextErrorMark(markid,true);
   restore_pos(p);
}
/**
 * Searches for <i>filename</i> in include directories specified by the
 * <i>include_dirs</i> parameter.  If the <i>include_dirs</i> parameter contains
 * an '=' character, it is assumed to be an environment variable.
 * <i>include_dirs</i> defaults to INCLUDE=' if not specified.
 *
 * @return If successful, a complete file specification for filename is
 * returned.  Otherwise '' is returned.
 *
 * @categories File_Functions
 *
 */
_str include_search(_str filename, _str multi_path="",_str multi_path2="")
{
   if ( multi_path=="" ) {
      multi_path="INCLUDE=";
   }
   if ( pos("=",multi_path) ) {
      multi_path=get_env(stranslate(multi_path,"","="));
   }
   path := "";
   match := "";
   for (;;) {
      if ( multi_path=="" ) {
         //return("");
         break;
      }
      parse multi_path with path (PARSE_PATHSEP_RE),"r" multi_path;
      if ( _last_char(path):!=FILESEP && _last_char(path):!=FILESEP2 ) {
         path :+= FILESEP;
      }
      match=file_match2(path:+filename,1,"-p");
      if ( match!="" ) {
         return(match);
      }
   }

   if (multi_path2=="") {
      int status=_ini_get_value(_project_name,"COMPILER."GetCurrentConfigName(),"includedirs",multi_path2);
   }
   for (;;) {
      if ( multi_path2=="" ) {
         return("");
      }
      parse multi_path2 with path (PARSE_PATHSEP_RE),"r" multi_path2;
      if ( _last_char(path):!=FILESEP && _last_char(path):!=FILESEP2 ) {
         path :+= FILESEP;
      }
      match=file_match2(path:+filename,1,"-p");
      if ( match!="" ) {
         return(match);
      }
   }

}
/**
 * Adds a new regular expression to <i>pattern</i> by ORing them.
 * This procedure assumes that <i>error_re</i> starts with a '^'
 * character.   Typically used for adding compiler error message
 * recognition.
 *
 * @see parse_error_re
 *
 * @categories Search_Functions
 *
 */
void or_re(_str &pattern,_str error_re)
{
   if ( error_re=="" ) {
      return;
   }
   regexWithoutStart := strip(error_re,"L","^");
   if (pattern=="") {
      pattern= "("regexWithoutStart")";
      return;
   }
   pattern :+= "|("regexWithoutStart")";
}

bool _get_error_info_pvwave_pro(_str &filename,_str &linenum, _str &col, _str &err_msg )
{
   line := "";
   get_line(line);
   if (filename=="" || linenum=="" ||
       substr(line,1,6):!="  At: ") {
      return(false);
   }
   up();
   get_line(err_msg);
   down();
   return(true);
}
#if 1 /*!__UNIX__*/
bool _get_error_info_microfocus(_str &filename,_str &linenum, _str &col, _str &err_msg )
{
   if (!_isWindows()) {
      return false;
   }
   line := "";
   get_line(line);
   if (/*filename!="*" || */linenum=="" ||
       !pos(_microfocus_re,line,1,"ri")) {
      return(false);
   }
   if(down()) return(false);
   get_line(line);
   parse line with . err_msg;
   if (down()) return(false);
   get_line(line);
   parse line with linenum .;
   if (!isinteger(linenum)) {
      return(false);
   }
   // Search backward for filename
   save_pos(auto p);
   status := search('[~a-z]cobol[ \t]*{:p}','@rih-');
   if (status) {
      return(false);
   }
   filename=get_match_text(0);
   restore_pos(p);
   return(true);
}
#endif
/*
   filename must be initialized and may be ""
   linenum must be initialized and may be ""
   col must be initialized and may be ""
   err_msg must be initialized and may be ""
*/
void call_list_get_error_info(_str view_id,_str &filename,_str &line, _str &col, _str &err_msg,_str matched_string)
{
   prefix_name := "_get_error_info_";
   orig_view_id := 0;
   get_window_id(orig_view_id);
   idx_list := "";
   typeless index=name_match(prefix_name,1,PROC_TYPE);
   for (;;) {
      if ( ! index ) { break; }
      if ( index_callable(index) ) {
         idx_list :+= " ":+index;
         //call_index(arg(2),arg(3),arg(4),arg(5),index)
      }
      index=name_match(prefix_name,0,PROC_TYPE);
   }
   if (view_id!="") {
      activate_window((int)view_id);
   }
   typeless p;
   while( idx_list!="" ) {
      parse idx_list with index idx_list;
      save_pos(p);
      typeless found_match=call_index(filename,line,col,err_msg,matched_string,index);
      restore_pos(p);
      if (found_match) {
         break;
      }
   }
   activate_window(orig_view_id);
}

/* This function returns 1 if the error found is above the top limit in the file
   Otherwise, returns 0 */
static bool past_top_error(_str top_markid)
{
   if (!_process_info('b') || top_markid=="" || _select_type(top_markid)=="") {
      return(false);
   }
   return _begin_select_compare(top_markid)<0;
#if 0
   linenum := p_line;
   int buf_id=p_buf_id;
   save_pos(auto p);
   _begin_select(_top_process_mark);
   linenum2 := p_line;
   p_buf_id=buf_id;restore_pos(p);
   result := (linenum<linenum2);
   return(linenum<linenum2);
#endif
}

/**
 * Initializes regular expression and procedure index variables used for
 * searching and parsing error messages.  Initializes variables used by the
 * SEARCH_FOR_ERROR() and PARSE_ERROR() functions.  See comment at the top of
 * "error.e" for details.
 *
 * @categories Miscellaneous_Functions
 *
 */
void init_error()
{
   init_error_re();


/*
   // Original code follows
   _error_search= find_index("search-for-error",PROC_TYPE);
   _error_parse= find_index("parse-error",PROC_TYPE);
   _error_re=def_error_re;
   _error_re2=def_error_re2;
   if (_isEditorCtl()){
      lang=p_LangId;
   } else {
      lang="fundamental";
   }
   index=find_index(lang"-init-error",PROC_TYPE|COMMAND_TYPE);
   if ( index ) {
      call_index(index);
      return;
   }
   // ~Original code
*/
}
   /* as assembler error message support */
   /* Assembler: xxx.s  */
   /* aline 12 : message */
bool _get_error_info_as(_str &filename,_str &line,_str &col, _str &err_msg)
{
   if (_isWindows()) return false;
   if ( filename!="aline" && filename!=(_chr(13)"line") ) {
      return(false);
   }
   typeless p=point();
   typeless ln=point('L');
   typeless cl=p_col;
   left_edge := p_left_edge;
   cursor_y := p_cursor_y;
   search('^Assembler\: ','@rih-');
   if ( rc ) {
      filename="";
   } else {
      get_line(auto cur_line);
      parse cur_line with . filename;
      goto_point(p,ln);p_col=cl;set_scroll_pos(left_edge,cursor_y);
   }
   return(filename!="");
}

bool _get_error_info_cc_rs6000(_str &filename,_str &line,_str &col, _str &err_msg)
{
   if (_isWindows()) return false;
   /* RS6000 cc compiler does not provide source filename. */
   /* search backwards for cc line to get filename. */
   if ( filename!="" || line=="" ) {
      return(false);
   }
   typeless p=point();
   typeless ln=point('L');
   cl := p_col;
   left_edge := p_left_edge;
   cursor_y := p_cursor_y;
   int status=search('^?*[ \t]+{(cc|xlf)[ \t]?*$}','@rih-');
   if (status ) {
      filename="";
   } else {
      get_line(auto cur_line);
      cur_line=get_match_text(0);
      parse cur_line with . cur_line;
      for (;;) {
         parse cur_line with filename cur_line;
         if ( substr(filename,1,1)!="-" ) {
            break;
         }
         if ( filename=="" ) {
            break;
         }
      }
      goto_point(p,ln);p_col=cl;set_scroll_pos(left_edge,cursor_y);
   }
   return(filename!="");
}

void _errorre_config_changed() {
   gAllExpressions._makeempty();
   gLangExpressions._makeempty();
   gExclusionExpressions._makeempty();
   gLastLangId="";
}


////////////////////////////////////////////////////////////////////////////////
// New code for error parsing regular expressions. Now they are
// loaded from a configuration file
////////////////////////////////////////////////////////////////////////////////

/**
 * Displays the configuration dialog for Error Parsing regular expressions
 */
_command void configure_error_regex()
{
   _str retval = show("-modal _error_re_form");
}
/**
 * Initializes error parsing regular expressions, loaded from 
 * the "misc.errorparsing" profile
 */
void init_error_re()
{
   _error_filename="";
   if (_isEditorCtl()) {
      _error_filename=p_buf_name;
   }
   _error_search= find_index("search_for_error_re",PROC_TYPE);
   _error_parse= find_index("parse_error_re",PROC_TYPE);

   lang := "fundamental";
   if (_isEditorCtl()) {
      lang = p_LangId;
   }

   ERRORRE_FOLDER_INFO folder_array[];
   if (gAllExpressions._isempty() || !_error_init_done || gLastLangId!=lang) {
      _errorre_load_error_parsing_table(folder_array);
   }

   // Reload the hashtable by reading the configuration file
   if (gAllExpressions._isempty() || !_error_init_done) {
      loadExclusionExpressions(folder_array);
      loadDefaultErrorExpressions(folder_array);
   }
   _error_init_done=true;

   if (gLastLangId != lang) {
      // Set up expressions per extension
      gLastLangId = lang;
      gLangExpressions._makeempty();
      loadLanguageSpecificErrorExpressions(folder_array,lang);

      // Also see if there is a custom initialization
      // method for this extension
      extensionIndex := find_index(lang"-init-error",PROC_TYPE|COMMAND_TYPE);
      if ( extensionIndex ) {
         call_index(extensionIndex);
      }
   }
}

/**
 * Search for error lines using regular expressions read from 
 * the "misc.errorparsing" profile
 *
 * @return The same status code as calling search()
 * @see search
 */
int search_for_error_re(_str direction="")
{
   _str directionops = (direction=="")? ">" : "<-";

   if (pos("-",directionops)) {
      up();_end_line();
   }

   save_pos(auto p);

   pattern := "";
   typeless hashIndex;
   hashIndex._makeempty();

   // Walk the list of extension-specific expressions, if set,
   // and or them together
   for (hashIndex._makeempty(); ;) {
      gLangExpressions._nextel(hashIndex);
      if (hashIndex._isempty()) {
         break;
      }
      or_re(pattern, gLangExpressions[hashIndex].regex);
   }

   // Walk the global expressions, and or them together
   for (hashIndex._makeempty(); ;) {
      gAllExpressions._nextel(hashIndex);
      if (hashIndex._isempty()) {
         break;
      }
      //_message_box("re="gAllExpressions[hashIndex].regex);
      or_re(pattern, gAllExpressions[hashIndex].regex);
   }

   if (pattern:== "") {
      return (STRING_NOT_FOUND_RC);
   }

   /* I tweeked this stuff a little.  Basically, if you're looking for the
      previous error, you want to search backwards, and use the < option rather
      than the > option */
   searchOpts :=  directionops :+ '@rih';
   int status = search('^('pattern')', searchOpts);
   keepLooking := true;
   _str top_mark='';
   if (_top_process_mark._indexin(p_buf_name)) {
      top_mark=_top_process_mark:[p_buf_name];
   }
   while((!status) && (keepLooking)) {
      keepLooking = false;
      if (past_top_error(top_mark)) {
         /* If we went above the top, return string not found, because we found
            an old error */
         status=STRING_NOT_FOUND_RC;
         restore_pos(p);
      } else {
         // We matched an expression. But now we want to make sure it's not
         // one of our false-positives
         matchStart := match_length('S');
         matchLen := match_length("");
         matchedLine := get_text(matchLen, matchStart);
         for (hashIndex._makeempty(); ;) {
            gExclusionExpressions._nextel(hashIndex);
            if (hashIndex._isempty()) {
               break;
            } else {
               // See if the line matches this false-positive expression
               if (pos(gExclusionExpressions[hashIndex].regex, matchedLine, 1, 'ri') > 0) {
                  status=repeat_search(searchOpts);
                  keepLooking = true;
                  break;
               }
            }
         }
      }
   }

   if(status == STRING_NOT_FOUND_RC)
   {
      restore_pos(p);
   }

   return(status);
}

static _str guess_error_severity(_str emsg)
{
   rv := "Error";

   if (pos("warning", emsg, 1, 'i')) {
      rv = "Warning";
   }

   return rv;
}

static const IN_FILE_FROM= "In file included from ";
/**
 * Parse error lines using regular expressions read from 
 * the "misc.errorparsing" profile
 *
 * @param filename Output parameter for the file containing the error
 * @param line Output parameter for the line number in filename
 * @param col Output parameter for the column position on line in filename
 * @param err_msg Output parameter for the error message 
 *  
 * @categories Miscellaneous_Functions
 */
void parse_error_re(_str &filename,_str &line,_str &col,_str &err_msg,
                    typeless view_id="", _str alt_word="", 
                    _str& severity = null)
{   
   /* arg(6) HERE - 5/18/95 - added for IBM WorkFrame support */
   temp := "";
   if ( alt_word!="" ) {
      temp=alt_word;
   } else {
      // Tim Roche for Lahey Fortran
      temp=get_match_text();
      //get_line(temp);
   }
   // Compilers which work with files with spaces:
   //
   //  javac, jikes, and Visual C++
   //
   // There may be some more, but only these have been tested.
   //

   typeless hashIndex;
   expressionThatMatched := "";
   expressionSev := "";
   macroToCall := "";
   hashIndex._makeempty();
   status := 0;

   // Walk the list of extension-specific expressions, if set
   for (hashIndex._makeempty(); status < 1;) {
      gLangExpressions._nextel(hashIndex);
      if (hashIndex._isempty()) {
         break;
      }
      status = pos(gLangExpressions[hashIndex].regex, temp, 1, 'ri');
      if (status) {
         expressionThatMatched = gLangExpressions[hashIndex].regex;
         macroToCall= gLangExpressions[hashIndex].macro;
         expressionSev = gLangExpressions[hashIndex].sev;
      }
   }

   // Walk the global expressions
   if (expressionThatMatched == "" && status < 1) {
      for (hashIndex._makeempty();;) {
         gAllExpressions._nextel(hashIndex);
         if (hashIndex._isempty()) {
            break;
         }
         status = pos(gAllExpressions[hashIndex].regex, temp, 1, 'ri');
         if (status) {
            expressionThatMatched = gAllExpressions[hashIndex].regex;
            macroToCall = gAllExpressions[hashIndex].macro;
            expressionSev = gAllExpressions[hashIndex].sev;
            break;
         }
      }
   }


   filename=substr(temp,pos('S0'),pos('0'));
   //say('b4 filename='filename);
   line=substr(temp,pos('S1'),pos('1'));
   col=substr(temp,pos('S2'),pos('2'));
   err_msg=substr(temp,pos('S3'),pos('3'));
   default_start1 := pos('s1');
   default_start2 := pos('s2');

   if (expressionSev == ERRORRE_SEVERITY_AUTO) {
      expressionSev = guess_error_severity(temp);
   }
   if (severity != null) {
      severity = expressionSev;
   }
   /*
      g++ outputs

In file included from file1.h:1:
             and
      from junk.cpp:1:

      Here we go to the include line.  I would prefer to skip it but
      it's hard to change next_error to do this.
   */
   if (strieq(substr(filename,1,length(IN_FILE_FROM)),IN_FILE_FROM)) {
      filename=substr(filename,length(IN_FILE_FROM)+1);
      err_msg="In file including from "filename;
   } else if (strieq(substr(strip(filename),1,length("from ")),"from ") ) {
      filename=substr(strip(filename),length("from ")+1);
      err_msg="In file including from "filename;
   }
   // Try looking for a line with a single ^ in it
   // which indicates the error column.
   //
   // Example:
   //   E:\guibuilder\parser\JUSymbolInfo.java:176: cannot resolve symbol
   //   symbol  : variable initializer
   //   location: class com.slickedit.javaparser.JUSymbolInfo
   //      result.initializer   = initializer;
   //            ^
   //
   if (col=="") {
      typeless before_carot_search;
      save_pos(before_carot_search);
      int i;
      for (i=0; i<5; ++i) {
         if (down()) break;
         carot_line := "";
         get_line(carot_line);
         if (strip(carot_line)=="^") {
            col=length(strip(carot_line,'T'));
            up();
            col=_text_colc((int)col,'P');
            down();
            break;
         }
      }
      restore_pos(before_carot_search);
   }
   //say("line="line" col="col);

   // check for ant syntax
   //    [compiler] Compiling 1 source file to OUTDIRPATH
   //    [compiler] ABSFILENAME
   //
   // NOTE: for now, assume that a filename starting with '[' is
   //       ant syntax.  our project dont currently support filenames
   //       that start with '[' anyway
   filename = strip(filename);
   if (_first_char(filename) == "[") {
      // trim off the '[compiler]' part
      closeBracket := pos("]", filename);
      if (closeBracket > 0) {
         filename = substr(filename, closeBracket + 1);
         filename = strip(filename);
      }
   }


   //say("filename="filename);
   /* Clipper compiler error message support */
   /* compiling ...prg  */
   /* line 12: message */
   /* 123 error */
   if ( filename=="line" || filename==(_chr(13)"line") ) {
      if ( _no_filename_index != 0 ) {
         call_index(filename,view_id,_no_filename_index);
      }
      if ( filename=="" ) {
         line="";
         col="";
         err_msg=nls("Could not find name of buffer that was compiled");
      }
   }
   regexSpecificMacroWorked := false;
   if (macroToCall!="") {
      index := find_index(macroToCall,PROC_TYPE);
      if (index_callable(index)) {
         regexSpecificMacroWorked=call_index(filename,line,col,err_msg,temp,index);
      }
   }
   if (!regexSpecificMacroWorked) {
      call_list_get_error_info(view_id,filename,line,col,err_msg,temp);
   }
   //say("h2 line="line" col="col);

   if ( err_msg=="" && line!="" ) {
      int start=default_start1;
      if ( pos('2') ) {
         start=default_start2;
      }
      parse substr(temp,start) with ":" err_msg;
   } else if ( substr(err_msg,1,1)==":" ) {
      err_msg=substr(err_msg,2);
   }
   if (substr(filename,1,1)!='"') {
      filename=_maybe_quote_filename(filename);
   }
}

void _convert_errorre_xml(_str errorre_xml_file="") {
   do_recycle := false;
   if (errorre_xml_file=="") {
      errorre_xml_file = _ConfigPath() :+ "ErrorRE.xml";
      do_recycle=true;
   }
   if (!file_exists(errorre_xml_file)) {
      return;
   }
   // Convert to the new .cfg.xml languages settings
   module := "convert_errorre_xml.ex";
   filename := _macro_path_search(_strip_filename(substr(module,1,length(module)-1), "P"));
   //_message_box("filename="filename);
   if (filename=="") {
      module="convert_errorre_xml.e";
      filename = _macro_path_search(_strip_filename(substr(module,1,length(module)), "P"));
      //_message_box("h2 filename="filename);
      if (filename=="") {
         filename="convert_errorre_xml";
      }
   }
   shell(_maybe_quote_filename(filename)" "_maybe_quote_filename(errorre_xml_file));
   if (do_recycle) {
      recycle_file(_ConfigPath():+"ErrorRE.xml");
   }
}
void _errorre_load_error_parsing_table(ERRORRE_FOLDER_INFO (&folder_array)[],int optionLevel=0,int (&folder_hash_position):[]=null,int (&re_hash_position):[]=null) {
   folder_hash_position._makeempty();
   re_hash_position._makeempty();
   folder_array._makeempty();
   handle:=_plugin_get_profile(VSCFGPACKAGE_MISC,VSCFGPROFILE_ERRORPARSING,optionLevel);
   if (handle<0) {
      return;
   }
   int folder_to_index:[];

   profileNode:=_xmlcfg_set_path(handle,"/profile");

   // Sort all the properties by position.
   // That way, all arrays are ordered by position.
   _xmlcfg_sort_on_attribute(handle,profileNode,"attrs/@position",'n');
   int property_node;
   // Load folders first
   property_node=_xmlcfg_get_first_child(handle,profileNode,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
   while (property_node>=0) {
      name:=_xmlcfg_get_attribute(handle,property_node,VSXMLCFG_PROPERTY_NAME);
      i := 1;
      folder_name:=_pos_parse_wordsep(i,name,VSXMLCFG_PROPERTY_SEPARATOR,VSSTRWF_NONE,VSXMLCFG_PROPERTY_ESCAPECHAR);
      re_name:=_pos_parse_wordsep(i,name,VSXMLCFG_PROPERTY_SEPARATOR,VSSTRWF_NONE,VSXMLCFG_PROPERTY_ESCAPECHAR);
      int *pfolder_index=folder_to_index._indexin(lowcase(folder_name));
      ERRORRE_FOLDER_INFO *pfolder_info;
      if (re_name!=null && re_name!="") {
      } else {
         if (!pfolder_index) {
            folder_to_index:[lowcase(folder_name)]=folder_array._length();
            pfolder_info=&folder_array[folder_array._length()];
            pfolder_info->m_name=folder_name;
            //pfolder_info->m_position= -1;
            pfolder_info->m_enabled=true;
            pfolder_info->m_errorre_array._makeempty();
         } else {
            pfolder_info=&folder_array[*pfolder_index];
         }
         pfolder_info->m_name=folder_name;
         attrs_node:=_xmlcfg_find_child_with_name(handle,property_node,VSXMLCFG_ATTRS);
         if (attrs_node>=0) {
            pfolder_info->m_enabled=_xmlcfg_get_attribute(handle,attrs_node,"enabled")?true:false;
            position:=_xmlcfg_get_attribute(handle,attrs_node,"position");
            if (isinteger(position)) {
               folder_hash_position:[lowcase(folder_name)]=position;
            }
            //if (isinteger(position)) pfolder_info->m_position=(int)position;
         }
      }
      
      property_node=_xmlcfg_get_next_sibling(handle,property_node,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
   }

   // Now add regex entries
   property_node=_xmlcfg_get_first_child(handle,profileNode,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
   while (property_node>=0) {
      name:=_xmlcfg_get_attribute(handle,property_node,VSXMLCFG_PROPERTY_NAME);
      i := 1;
      folder_name:=_pos_parse_wordsep(i,name,VSXMLCFG_PROPERTY_SEPARATOR,VSSTRWF_NONE,VSXMLCFG_PROPERTY_ESCAPECHAR);
      re_name:=_pos_parse_wordsep(i,name,VSXMLCFG_PROPERTY_SEPARATOR,VSSTRWF_NONE,VSXMLCFG_PROPERTY_ESCAPECHAR);
      int *pfolder_index=folder_to_index._indexin(lowcase(folder_name));
      ERRORRE_FOLDER_INFO *pfolder_info;
      if (!pfolder_index) {
         folder_to_index:[lowcase(folder_name)]=folder_array._length();
         pfolder_info=&folder_array[folder_array._length()];
         pfolder_info->m_name=folder_name;
         //pfolder_info->m_position= -1;
         pfolder_info->m_enabled=true;
         pfolder_info->m_errorre_array._makeempty();
      } else {
         pfolder_info=&folder_array[*pfolder_index];
      }
      if (re_name!=null && re_name!="") {
         ERRORRE_INFO info;
         //info.m_position=-1;
         info.m_enabled=true;
         info.m_name=re_name;
         info.m_re="";
         info.m_test_case="";
         info.m_severity="";
         attrs_node:=_xmlcfg_find_child_with_name(handle,property_node,VSXMLCFG_ATTRS);
         if (attrs_node>=0) {
            info.m_enabled=_xmlcfg_get_attribute(handle,attrs_node,"enabled")?true:false;
            position:=_xmlcfg_get_attribute(handle,attrs_node,"position");
            if (isinteger(position)) {
               re_hash_position:[lowcase(folder_name"\t"info.m_name)]=position;
            }
            info.m_macro=_xmlcfg_get_attribute(handle,attrs_node,"macro");
            info.m_severity = _xmlcfg_get_attribute(handle, attrs_node, 
                                                    "severity", 
                                                    ERRORRE_SEVERITY_AUTO);
         }
         re_node:=_xmlcfg_find_child_with_name(handle,property_node,"re");
         if (re_node>=0) {
            info.m_re=_xmlcfg_get_text(handle,re_node);
         }
         test_case_node:=_xmlcfg_find_child_with_name(handle,property_node,"test_case");
         if (test_case_node>=0) {
            info.m_test_case=_xmlcfg_get_text(handle,test_case_node);
         }
         pfolder_info->m_errorre_array[pfolder_info->m_errorre_array._length()]=info;
      } else {
      }
      
      property_node=_xmlcfg_get_next_sibling(handle,property_node,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
   }

   _xmlcfg_close(handle);
}

static void _errorre_add_folder_property(int handle,int profile_node,ERRORRE_FOLDER_INFO &info,int &last_position,int (&hash_position):[]) {
   _plugin_next_position(lowcase(info.m_name),last_position,hash_position);
   /*
     <p n="category">
         <attrs position="1" enabled="1">
     </p>
   */
   property_node:=_xmlcfg_add(handle,profile_node,"p",VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   name:=_plugin_escape_property(info.m_name);
   _xmlcfg_set_attribute(handle,property_node,VSXMLCFG_PROPERTY_NAME,name);
   attrs_node:=_xmlcfg_add(handle,property_node,VSXMLCFG_ATTRS,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_set_attribute(handle,attrs_node,"position",last_position);
   _xmlcfg_set_attribute(handle,attrs_node,"enabled",info.m_enabled);
   //value:=last_position:+VSXMLCFG_PROPERTY_SEPARATOR:+info.m_enabled;
   //_xmlcfg_set_attribute(handle,node,VSXMLCFG_PROPERTY_VALUE,value);
}
static void _errorre_add_property(int handle,int profile_node,_str folder_name,ERRORRE_INFO &info,int &last_position,int (&hash_position):[]) {
   _plugin_next_position(lowcase(folder_name"\t"info.m_name),last_position,hash_position);
   /*
  <p n="category,def1">
      <attrs position="1" enabled="1">
      <re>
          <![CDATA[^  File \"{#0[^"]+}\", line {#1:i}?*(\n|\r\n|\r)?*(\n|\r\n|\r)( *?\^(\n|\r\n|\r)|){#3[^ ]+\: ?*}$]]>
      </re>
      <test_case>
      </test_case>
  </p>
   
   */
   property_node:=_xmlcfg_add(handle,profile_node,"p",VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   name:=_plugin_escape_property(folder_name):+VSXMLCFG_PROPERTY_SEPARATOR:+_plugin_escape_property(info.m_name);
   _xmlcfg_set_attribute(handle,property_node,VSXMLCFG_PROPERTY_NAME,name);
   attrs_node:=_xmlcfg_add(handle,property_node,VSXMLCFG_ATTRS,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_set_attribute(handle,attrs_node,"position",last_position);
   _xmlcfg_set_attribute(handle,attrs_node,"enabled",info.m_enabled);
   if (info.m_macro!="") {
      _xmlcfg_set_attribute(handle,attrs_node,"macro",info.m_macro);
   }
   // System settings does not set severity property if its <Auto>
   if (strieq(info.m_severity,'<Auto>')) {
      _xmlcfg_delete_attribute(handle, attrs_node, "severity");
   } else {
      _xmlcfg_set_attribute(handle, attrs_node, "severity", info.m_severity);
   }

   re_node:=_xmlcfg_add(handle,property_node,"re",VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add_child_text(handle,re_node,info.m_re);
   if (info.m_test_case!="") {
      test_case_node:=_xmlcfg_add(handle,property_node,"test_case",VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_add_child_text(handle,test_case_node,info.m_test_case);
   }
}
void _errorre_save_error_parsing_table(ERRORRE_FOLDER_INFO (&folder_array)[]) {

   // Hash the built-in profile's position information if there is any.
   _errorre_load_error_parsing_table(auto junk,1,auto folder_hash_position,auto re_hash_position);

   int handle=_xmlcfg_create_profile(auto profile_node,VSCFGPACKAGE_MISC,VSCFGPROFILE_ERRORPARSING,
                                     VSCFGPROFILE_ERRORPARSING_VERSION);


   last_position := 0;
   for (i:=0;i<folder_array._length();++i) {
      _str folder_name=folder_array[i].m_name;
      _errorre_add_folder_property(handle,profile_node,folder_array[i],last_position,folder_hash_position);
      re_last_position := 0;
      int len=folder_array[i].m_errorre_array._length();
      for (j:=0;j<len;++j) {
         _errorre_add_property(handle,profile_node,folder_name,folder_array[i].m_errorre_array[j],re_last_position,re_hash_position);
      }

   }

   _plugin_set_profile(handle);
   _xmlcfg_close(handle);
   _errorre_config_changed();
}

/**
 * Looks for and loads extension-specific error parsing expressions
 *
 * @param xml_handle    Handle to the XML configuration DOM
 * @param lang          Language to find an expression set for
 *
 * @see findExtensionSpecificSet
 */
static void loadLanguageSpecificErrorExpressions(ERRORRE_FOLDER_INFO (&folder_array)[], _str lang)
{
   _str langRE = "^(Extension|langid) " :+ lang :+ "$";
   for (i:=0;i<folder_array._length();++i) {
      _str folder_name =folder_array[i].m_name;
      if (folder_array[i].m_enabled && pos(langRE, folder_name, 1, "ir") == 1) {
         readExpressionsByPriority(folder_array[i].m_errorre_array, gLangExpressions);
      }
   }
}

/**
 * Loads the default (global) error-parsing regular expressions
 * from the "misc.errorparsing" profile. These are
 * expressions for all extensions.
 *
 * @param xml_handle Handle to the XML configuration DOM
 *
 */
static void loadDefaultErrorExpressions(ERRORRE_FOLDER_INFO (&folder_array)[])
{
   for (i:=0;i<folder_array._length();++i) {
      // Skip this node if the name attribute starts with "Extension"
      // or "Exclu" (for Exclude, Exclusions)
      _str folder_name =folder_array[i].m_name;
      if (folder_array[i].m_enabled && pos("^(Extension|langid)", folder_name, 1, "ir") == 0 && pos("^Exclu", folder_name, 1, "ir") == 0) {
         readExpressionsByPriority(folder_array[i].m_errorre_array, gAllExpressions);
      }
   }
}

/**
 * Loads the "false positive" error-parsing regular expressions
 * from the "misc.errorparsing" profile. These are
 * expressions that we don't want to be read as real error line.
 *
 * @param xml_handle Handle to the XML configuration DOM
 *
 */
static void loadExclusionExpressions(ERRORRE_FOLDER_INFO (&folder_array)[])
{
   // Find all Exclu?*,properties
   for (i:=0;i<folder_array._length();++i) {
      _str folder_name =folder_array[i].m_name;
      if (folder_array[i].m_enabled && pos("^Exclu", folder_name, 1, "ir")) {
         readExpressionsByPriority(folder_array[i].m_errorre_array, gExclusionExpressions);
      }
   }
   
}

/**
 * Read all the error parsing expressions in this category
 *
 * @param xml_handle Handle to the error config XML DOM
 * @param nodeIndex  Node index of the category (Tool node)
 */
static void readExpressionsByPriority(ERRORRE_INFO (&errorre_array)[], COLLECTION_ITEM (&collection)[])
{
   for (i:=0;i<errorre_array._length();++i) {
      cacheExpressionDetails(errorre_array[i], collection);
   }
}

static void cacheExpressionDetails(ERRORRE_INFO &info, COLLECTION_ITEM (&collection)[])
{
   // TODO: Instead of display, just populate the global array?
   _str reName =info.m_name;
   _str enabled =info.m_enabled;
   //say("Found expression "reName" . Enabled == "enabled);

   // If this node has the Enabled="0" attribute, then skip it
   if (enabled) {
      COLLECTION_ITEM it;

      it.regex = info.m_re;
      it.macro = info.m_macro;
      it.sev = info.m_severity;
      collection :+= it;
   }
}

void _wkspace_close_clear_errors()
{
   clear_all_error_markers();
}

_command void goToBuildOutput (se.messages.Message* inMsg=null) name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "The Build tool window");
      return;
   }
   if (inMsg == null) {
      return;
   }

   int orig_view_id;
   int temp_view_id;
   typeless status;
   typeless mark = "";

   status = _activate_error_file(mark, temp_view_id,auto is_process_mark,auto top_mark);

   p_line = inMsg->m_attributes:["build window line"];
   _SetNextErrorMark(_process_mark:[p_buf_name]);

   activate_build();
}

static _str getMessageType(_str errMsg, _str matchText)
{
   // first, we check the error message
   if (pos(def_build_errors_re, errMsg, 1, 'IR') > 0) {
      return "Error";
   }
   if (pos(def_build_warnings_re, errMsg, 1, 'IR') > 0) {
      return "Warning";
   }

   // no?  well, check the entire match then
   if (pos(def_build_errors_re, matchText, 1, 'IR') > 0) {
      return "Error";
   }
   if (pos(def_build_warnings_re, matchText, 1, 'IR') > 0) {
      return "Warning";
   }

   // nothing
   return "(Info)";
}
